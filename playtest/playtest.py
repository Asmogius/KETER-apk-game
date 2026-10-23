"""A play-tester for the Battle Simulator. Plays whole debug combats through the
Simulator's own controls, mixes in unusual moves, and checks the state after
every action. Usage: playtest.py FLOOR SEED [ROUNDS]"""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json, random
from playwright.sync_api import sync_playwright
FLOOR=sys.argv[1]; SEED=int(sys.argv[2]); ROUNDS=int(sys.argv[3]) if len(sys.argv)>3 else 6
ODD=int(sys.argv[4]) if len(sys.argv)>4 else 2
PORT=9700+SEED%200
rng=random.Random(SEED)
TMP=pathlib.Path(f"/tmp/pt_{SEED}")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",PORT),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()

INVARIANTS = r"""()=>{
  var P=[], R=window.KETER_RULES, keys={'waves':1,'gen':1,'chips':1,'draw':1,'recharge':1,'turn':1,'enemy':1};
  if(!SIM.map) return ['no map'];
  if(!keys[SIM.phase]) P.push('bad phase '+SIM.phase);
  var seen={};
  SIM.units.forEach(function(u){
    ['hp','hpMax','nrg','ms','ac'].forEach(function(f){ if(u[f]!==undefined && (typeof u[f]!=='number'||isNaN(u[f]))) P.push(u.name+' has '+f+'='+u[f]); });
    if(u.nrg<0) P.push(u.name+' has negative Energy '+u.nrg);
    if(u.hp<0) P.push(u.name+' has negative Health '+u.hp);
    if(!u.down && u.hp<=0) P.push(u.name+' is at '+u.hp+' Health but not down');
    (u.statuses||[]).forEach(function(s){ if(s.n!==null&&s.n!==undefined&&(typeof s.n!=='number'||isNaN(s.n)||s.n<0)) P.push(u.name+' status '+s.name+' n='+s.n); });
    if(u.down) return;
    if(!u.pos){ P.push(u.name+' alive with no position'); return; }
    var k=R.hexKey(u.pos.q,u.pos.r);
    if(!SIM.map.hexes[k]) P.push(u.name+' stands off the floor at '+k);
    if(seen[k]) P.push(u.name+' and '+seen[k]+' share tile '+k);
    seen[k]=u.name;
  });
  Object.keys(SIM.aether||{}).forEach(function(k){ var v=SIM.aether[k]; if(typeof v!=='number'||isNaN(v)||v<0) P.push('Aether '+k+'='+v); });
  if(SIM.enemyQueue) SIM.enemyQueue.forEach(function(id){ var u=SIM.units.filter(function(x){return x.id===id;})[0];
    if(!u) P.push('Enemy queue holds a Unit that does not exist'); });
  if(SIM.halted) P.push('HALT: '+SIM.halted);
  return P;
}"""

issues=[]; errs=[]; actions=[]; ATTEMPTS=[]
def note(kind, detail):
    issues.append({"kind":kind,"detail":detail,"round":ROUND[0],"after":actions[-3:]})
ROUND=[0]

with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True).new_page()
    pg.on("pageerror",lambda e:errs.append(str(e)[:300]))
    pg.on("console",lambda m:errs.append("console: "+m.text[:300]) if m.type=="error" else None)
    pg.goto(f"http://127.0.0.1:{PORT}/"); pg.wait_for_timeout(2000)
    pg.evaluate("()=>{ localStorage.setItem('keter-app-simdebug','1'); localStorage.setItem('keter-app-dice',JSON.stringify({dur:0})); localStorage.removeItem('keter-app-sim'); }")
    pg.reload(); pg.wait_for_timeout(2000)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(500)
    pg.evaluate(f"()=>simDebugStart('TEST \u00b7 {FLOOR}')"); pg.wait_for_timeout(1500)

    def check(label):
        n0=len(errs)
        try: probs=pg.evaluate(INVARIANTS)
        except Exception as e: probs=['invariant check threw: '+str(e)[:160]]
        for pr in probs:
            key=pr.split(' at ')[0][:60]
            if not any(i["detail"].startswith(key) for i in issues): note("state", pr)
        if pg.evaluate("()=>!!SIM.halted"):
            pg.evaluate("()=>{ SIM.halted=null; SIM.haltShown=false; document.getElementById('modal').classList.remove('on'); }")
    def act(label, js, arg=None, wait=120):
        actions.append(label)
        n0=len(errs)
        try:
            r = pg.evaluate(js, arg) if arg is not None else pg.evaluate(js)
        except Exception as e:
            note("threw", label+": "+str(e)[:240]); r=None
        pg.wait_for_timeout(wait)
        for e in errs[n0:]: note("js error", label+": "+e)
        check(label)
        return r
    def settle(limit=60):
        for _ in range(limit):
            if not pg.evaluate("()=>!!SIM.busy"): return True
            pg.wait_for_timeout(100)
        note("stuck", "SIM.busy stayed true for "+str(limit/10)+"s"); return False
    def close_modal():
        pg.evaluate("()=>{ var m=document.getElementById('modal'); if(m) m.classList.remove('on'); }")

    ALLY_TURN = r"""(pick)=>{
      var R=window.KETER_RULES, out={};
      var allies=SIM.units.filter(function(u){return u.side==='ally'&&!u.down&&u.pos;});
      return allies.map(function(u){ return u.id; });
    }"""
    def unit_turn(uid):
        choice=rng.random()
        if ODD==0:
            # play it like a person: close in on the nearest Enemy, keeping off hazards,
            # and stop once something is in reach
            act("advance "+uid, """(uid)=>{ var R=window.KETER_RULES, u=SIM.units.filter(function(x){return x.id===uid;})[0]; if(!u||u.down) return;
              var foes=SIM.units.filter(function(f){return f.side==='enemy'&&!f.down&&f.pos;}); if(!foes.length) return 'no foes';
              var inReach=(u.actions||[]).some(function(a){ return a.tag!=='Passive'&&a.tag!=='Aura'&&foes.some(function(f){ try{return simCanReach(u,a,f);}catch(e){return false;} }); });
              if(inReach) return 'already in reach';
              simSelect(u); var r=(SIM.reach||[]).filter(function(t){ return !(SIM.map.hazards||{})[R.hexKey(t.q,t.r)]; }); if(!r.length) return 'no safe reach';
              var near=function(t){ return Math.min.apply(null,foes.map(function(f){ return R.hexDistance(t,f.pos); })); };
              r.sort(function(a,b){ return near(a)-near(b); }); var t=r[0]; return simMoveTo(u,t.q,t.r); }""", uid)
        elif choice<0.45:
            act("move "+uid, """(uid)=>{ var u=SIM.units.filter(function(x){return x.id===uid;})[0]; if(!u||u.down) return;
              simSelect(u); var r=SIM.reach||[]; if(!r.length) return 'no reach';
              var t=r[Math.floor(Math.random()*r.length)]; return simMoveTo(u,t.q,t.r); }""", uid)
        if rng.random()<0.85:
            r=act("attack "+uid, """(uid)=>{ var u=SIM.units.filter(function(x){return x.id===uid;})[0]; if(!u||u.down) return 'none';
              var acts=(u.actions||[]).filter(function(a){ return a.tag!=='Passive'&&a.tag!=='Aura'; });
              for(var i=0;i<acts.length;i++){ var a=acts[Math.floor(Math.random()*acts.length)];
                var role=String(a.role||'').toLowerCase();
                var pool=SIM.units.filter(function(f){ return !f.down&&f.pos&&(role==='support'?(f.side===u.side&&f!==u):f.side!==u.side); });
                var ok=pool.filter(function(f){ return R_ok(u,a,f); });
                if(ok.length&&window.KETER_RULES.canAfford(u,a)){ var t=ok[Math.floor(Math.random()*ok.length)];
                  simConfirmAttack(u,t,a); return a.name+' -> '+t.name; } }
              return 'nothing in reach';
              function R_ok(u,a,f){ try{ return simCanReach(u,a,f); }catch(e){ return false; } } }""", uid, wait=250)
            ATTEMPTS.append(str(r))
            settle()
        if rng.random()<0.15:
            act("hold fire "+uid, """(uid)=>{ var u=SIM.units.filter(function(x){return x.id===uid;})[0]; if(!u) return;
              var h=simHoldable(u); if(h.length){ simHoldFire(u,h[0].name); return 'held '+h[0].name; } return 'cannot hold'; }""", uid)
    def play_card():
        r=act("play a card", """()=>{ if(!SIM.hand.length) return 'empty hand';
          var playable=SIM.hand.map(function(c,i){return i;}).filter(function(i){ return simCanPlay(SIM.hand[i]); });
          if(!playable.length) return 'nothing affordable';
          var i=playable[Math.floor(Math.random()*playable.length)], name=SIM.hand[i].name;
          simPlayCard(i); return name; }""", wait=300)
        # resolve whatever it asked for
        if pg.evaluate("()=>!!SIM.pick"):
            act("choose a target for "+str(r), """()=>{ var pk=SIM.pick, ks=Object.keys(pk.valid);
              var k=ks[Math.floor(Math.random()*ks.length)]; var t=SIM.units.filter(function(u){return u.id===pk.valid[k];})[0];
              SIM.pick=null; pk.done(t); return t&&t.name; }""", wait=300)
        if pg.evaluate("()=>!!SIM.aim"):
            act("aim "+str(r), """()=>{ var ks=Object.keys(SIM.map.hexes); var a=window.KETER_RULES.hexParse(ks[Math.floor(Math.random()*ks.length)]);
              SIM.aim.at=a; simConfirmAim(); return a; }""", wait=300)
        if pg.evaluate("()=>document.getElementById('modal').classList.contains('on')"):
            note("dialog", "playing "+str(r)+" left a dialog open: "+pg.evaluate("()=>document.getElementById('modalBox').innerText.slice(0,120)"))
            close_modal()
        settle()
    def end_round():
        act("end turn", "()=>{ simNextPhase(); return SIM.phase; }", wait=300)
        if pg.locator("#simGoBtn").is_visible():
            act("confirm end turn", "()=>{ document.getElementById('simGoBtn').click(); return SIM.phase; }", wait=300)
        for step in range(40):
            settle()
            ph=pg.evaluate("()=>SIM.phase")
            if pg.evaluate("()=>!!SIM.over"): return "over"
            if ph is None:
                note("lost", "the fight vanished (no phase, not over) after: "+" | ".join(actions[-8:])+
                     " | page: "+str(pg.evaluate("()=>[].slice.call(document.querySelectorAll('.view.on')).map(function(v){return v.id;}).join(',')"))+
                     " | map: "+str(pg.evaluate("()=>!!SIM.map"))+" units: "+str(pg.evaluate("()=>SIM.units.length")))
                return "stuck"
            if ph=="turn": return "turn"
            act("next ("+ph+")", "()=>{ simNextPhase(true); return SIM.phase; }", wait=200)
        note("stuck","the round did not come back to Your turn in 40 steps; phase "+pg.evaluate("()=>SIM.phase"))
        return "stuck"

    WEIRD=[
     ("undo right after ending the turn", "()=>{ simNextPhase(true); simUndoPhase(); return SIM.phase; }"),
     ("force a 20 then a 1", "()=>{ SIM_FORCE.push(20); SIM_FORCE.push(1); return SIM_FORCE.length; }"),
     ("drop a Hero to 0 Health", "()=>{ var h=SIM.units.filter(function(u){return u.side==='ally'&&/hero/i.test(u.cardType||'')&&!u.down;}); if(h.length<2) return 'kept'; h[0].hp=0; simCheckDowns(); renderSim(); return h[0].name; }"),
     ("put a Sapper next to Enemies and kill it", "()=>{ var e=SIM.units.filter(function(u){return u.side==='enemy'&&!u.down;})[0]; if(!e) return; var R=window.KETER_RULES, spot=null; [[1,0],[0,1],[-1,1],[-1,0],[0,-1],[1,-1]].some(function(d){ var q=e.pos.q+d[0], r=e.pos.r+d[1]; if(SIM.map.hexes[R.hexKey(q,r)]&&!simUnitAt(q,r)){ spot={q:q,r:r}; return true; } return false; }); if(!spot) return 'no room'; SIM_DBG.place={card:'Test Sapper',side:'ally'}; simDebugTap(spot); var u=SIM.units[SIM.units.length-1]; R.hit(u,u.hp); simCheckDowns(); renderSim(); return 'sapper down beside '+e.name; }"),
     ("kill the leader while others stand", "()=>{ var l=SIM.units.filter(function(u){return u.id===SIM.leader;})[0]; if(!l||l.down) return; var others=SIM.units.filter(function(u){return u.side==='ally'&&!u.down&&u!==l&&/hero/i.test(u.cardType||'');}); if(!others.length) return 'only hero'; window.KETER_RULES.hit(l,l.hp); simCheckDowns(); renderSim(); return {over:!!SIM.over}; }"),
     ("act while Stunned", "()=>{ var u=SIM.units.filter(function(x){return x.side==='ally'&&!x.down;})[0]; var e=SIM.units.filter(function(x){return x.side==='enemy'&&!x.down;})[0]; if(!u||!e) return; window.KETER_RULES.addStatus(u,'Stunned',1,'t'); var hp=e.hp, n=u.nrg; simAttack(u,e); return {acted:e.hp!==hp||u.nrg!==n}; }"),
     ("try to move while Rooted", "()=>{ var u=SIM.units.filter(function(x){return x.side==='ally'&&!x.down;})[0]; if(!u) return; window.KETER_RULES.addStatus(u,'Rooted',1,'t'); simSelect(u); return {reach:(SIM.reach||[]).length}; }"),
     ("play a card during the Enemy turn", "()=>{ var ph=SIM.phase; SIM.phase='enemy'; var n=SIM.hand.length, p0=!!SIM.pick, a0=!!SIM.aim; if(n) simPlayCard(0); var played=SIM.hand.length!==n||(!p0&&!!SIM.pick)||(!a0&&!!SIM.aim); if(!p0) SIM.pick=null; if(!a0) SIM.aim=null; SIM.phase=ph; return {played:played}; }"),
     ("Mortar-strike your own team", "()=>{ var a=SIM.units.filter(function(x){return x.side==='ally'&&!x.down;})[0]; if(!a) return; var c=simAllCards().filter(function(x){return x.name==='Test Mortar Strike';})[0]; SIM.hand.push(simHandCardOf(c)); SIM.aether.generic=(SIM.aether.generic||0)+5; simPlayCard(SIM.hand.length-1); if(SIM.aim){ SIM.aim.at={q:a.pos.q,r:a.pos.r}; simConfirmAim(); } return a.name; }"),
     ("strip Equipment from a Unit that has none", "()=>{ var a=SIM.units.filter(function(x){return x.side==='ally'&&!x.down&&!(x.equipment||[]).length;})[0]; if(!a) return; simRunText('[[target ally]] gains [[remove Equipment]].',{actor:a,target:a,fromHand:true,sourceCard:'Test Strip'}); return 'ok'; }"),
     ("call reinforcements with no room", "()=>{ var o=SIM.units.filter(function(x){return x.side==='enemy'&&!x.down;})[0]; if(!o) return; var R=window.KETER_RULES; [[1,0],[0,1],[-1,1],[-1,0],[0,-1],[1,-1]].forEach(function(d){ var q=o.pos.q+d[0], r=o.pos.r+d[1]; if(SIM.map.hexes[R.hexKey(q,r)]&&!simUnitAt(q,r)){ SIM_DBG.place={card:'Test Grunt',side:'enemy'}; simDebugTap({q:q,r:r}); } }); simRunText('[[Deploy 1 Test Grunt]] [[adjacent]].',{actor:o,sourceCard:'Call Reinforcement'}); return 'ok'; }"),
     ("reload the page mid-fight", "RELOAD"),
     ("switch debug off mid-fight", "()=>{ simSetDebug(false); SIM.tab='debug'; renderSim(); var t=SIM.tab; simSetDebug(true); renderSim(); return t; }"),
     ("play every card in hand", None),
     ("zoom in and out during the Enemy turn", "()=>{ simZoomAt(2.5); simZoomAt(0.5); simZoomFit(); return SIM_VIEW.size; }"),
     ("tap the hand while a target is being chosen", "()=>{ SIM_UI.handOpen=!SIM_UI.handOpen; renderSim(); SIM_UI.handOpen=true; renderSim(); return 'ok'; }"),
     ("give a flood of Aether", "()=>{ SIM.aether.generic=(SIM.aether.generic||0)+30; SIM.aether.d3=(SIM.aether.d3||0)+30; renderSim(); return 'ok'; }"),
     ("stack statuses on an Enemy", "()=>{ var e=SIM.units.filter(function(u){return u.side==='enemy'&&!u.down;})[0]; if(!e) return; var R=window.KETER_RULES; ['Poisoned','Bleed','Sundered','Weakened','Rooted','Stunned','Marked','Pinned','Drained','Slowed'].forEach(function(s){ R.addStatus(e,s,3,'test'); R.addStatus(e,s,2,'test'); }); renderSim(); return e.name; }"),
     ("spend every lit chip", "()=>{ var n=0; (SIM.bank||[]).forEach(function(c,i){ if(!c.spent){ try{ simSpendChip(i); n++; }catch(e){ throw e; } } }); return n; }"),
     ("select an Enemy and pick an Action", "()=>{ var e=SIM.units.filter(function(u){return u.side==='enemy'&&!u.down;})[0]; if(!e) return; simSelect(e); return simDockMode(); }"),
     ("move a Unit onto a hazard or wall edge freely", "()=>{ var u=SIM.units.filter(function(x){return x.side==='ally'&&!x.down;})[0]; var ks=Object.keys(SIM.map.hexes).filter(function(k){ var a=window.KETER_RULES.hexParse(k); return !simUnitAt(a.q,a.r); }); var a=window.KETER_RULES.hexParse(ks[ks.length>>1]); SIM_DBG.move=true; simSelect(u); simDebugTap(a); SIM_DBG.move=false; return JSON.stringify(u.pos); }"),
     ("end the turn twice at once", "()=>{ simNextPhase(true); simNextPhase(true); return SIM.phase; }"),
    ]
    for rd in range(1,ROUNDS+1):
        ROUND[0]=rd
        if pg.evaluate("()=>!!SIM.over"): break
        if pg.evaluate("()=>SIM.phase")!="turn":
            if end_round()!="turn": break
        for uid in pg.evaluate(ALLY_TURN, 1):
            unit_turn(uid)
            if pg.evaluate("()=>!!SIM.over"): break
        for _ in range(rng.randint(0,3)): play_card()
        for name,js in rng.sample(WEIRD, ODD):
            if pg.evaluate("()=>!!SIM.over"): break
            if js is None:
                for _ in range(8): play_card()
            elif js=="RELOAD":
                before=pg.evaluate("()=>JSON.stringify({r:SIM.round,p:SIM.phase,n:SIM.units.length,h:SIM.hand.length})")
                actions.append("WEIRD: reload"); pg.reload(); pg.wait_for_timeout(2200)
                if pg.locator('.lt[data-page="battle"]').is_visible():
                    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(800)
                after=pg.evaluate("()=>SIM.map?JSON.stringify({r:SIM.round,p:SIM.phase,n:SIM.units.length,h:SIM.hand.length}):'no fight'")
                if after!=before: note("reload", "the fight changed across a reload: "+before+" -> "+after)
                check("after reload")
            else:
                r=act("WEIRD: "+name, js, wait=400); settle()
                if isinstance(r,dict) and (r.get("acted") or r.get("played") or (r.get("reach") or 0)>0):
                    note("rule", name+" was allowed: "+json.dumps(r))
        if pg.evaluate("()=>!!SIM.over"): break
        res=end_round()
        if res in ("over","stuck"): break
    summary=pg.evaluate("""()=>({round:SIM.round, over:!!SIM.over, outcome:SIM.over?(SIM.result||'ended'):'running',
      allies:SIM.units.filter(function(u){return u.side==='ally'&&!u.down;}).length,
      foes:SIM.units.filter(function(u){return u.side==='enemy'&&!u.down;}).length, wave:SIM.wave,
      log:SIM.log.slice(-6).map(function(l){return l.text;}),
      fulllog:SIM.log.map(function(l){return l.text;})})""")
    b.close()
srv.shutdown()
print(json.dumps({"floor":FLOOR,"seed":SEED,"actions":len(actions),"summary":summary,"issues":issues,"weird":[a for a in actions if a.startswith("WEIRD")], "attempts":ATTEMPTS}, indent=1))
