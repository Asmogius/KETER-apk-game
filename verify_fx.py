"""Attack effects and Burst: a pixel projectile for ranged attacks coloured by
side, floating text for damage (red), Miss and -0 HP (white), healing and buffs
(green), debuffs (red), queued one after another for two seconds each; and Burst
for players (one payment, a target chosen each time, no leaving it midway),
Enemies (choosing afresh each attack) and held reactions (the whole Burst)."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_fx")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9993),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d not in ("",None) and not c else ""))
LIB=r"""()=>{ window.T={ R:window.KETER_RULES,
  clear:function(){ SIM.burst=null; SIM.pendingAct=null; SIM.units=[]; SIM.selected=null; SIM.phase='turn'; SIM.over=false;
    SIM.aether={generic:50,d3:50}; SIM_FORCE.length=0; SIM.log=[]; SIM_FX.queues={}; SIM_FX.shots=[]; },
  put:function(name,side,q,r){ SIM_DBG.place={card:name,side:side}; simDebugTap({q:q,r:r}); var u=SIM.units[SIM.units.length-1]; u.nrg=Math.max(u.nrg,6); u.hp=u.hpMax=Math.max(u.hpMax,60); return u; },
  act:function(u,name){ return (u.actions||[]).filter(function(a){return a.name===name;})[0]; },
  q:function(u){ var q=SIM_FX.queues[u.id]; return q?q.items.map(function(i){return i.text+'|'+i.colour;}):[]; }
}; return true; }"""
with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},device_scale_factor=2).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.goto("http://127.0.0.1:9993/"); pg.wait_for_timeout(2000)
    pg.evaluate("()=>{ localStorage.setItem('keter-app-simdebug','1'); localStorage.setItem('keter-app-dice',JSON.stringify({dur:0})); localStorage.removeItem('keter-app-sim'); }")
    pg.reload(); pg.wait_for_timeout(2200)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(500)
    pg.evaluate("()=>simDebugStart('TEST \u00b7 Hazards and Cover')"); pg.wait_for_timeout(1500)
    pg.evaluate(LIB); E=pg.evaluate
    RED,WHITE,GREEN="#ff4a52","#f4f6f8","#6dff3a"

    # ---- a ranged hit: projectile, then -X HP in red, then the debuff in red ----
    r=E("""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,3), g=T.put('Test Grunt','enemy',0,-1);
      SIM_FORCE.push(20); SIM_FORCE.push(20); simConfirmAttack(w,g,T.act(w,'Pinning Volley'));
      return {shots:SIM_FX.shots.length, colour:SIM_FX.shots[0]&&SIM_FX.shots[0].colour, early:T.q(g), held:SIM_FX.queues[g.id].held, gid:g.id}; }""")
    ck("a ranged attack fires a projectile", r["shots"]==1)
    ck("cyan for your side", r["colour"]=="#22f0ff", r["colour"])
    ck("its text waits for the projectile to land", r["held"] is True)
    pg.wait_for_timeout(700)
    q=E(f"()=>T.q(SIM.units.filter(function(u){{return u.id==='{r['gid']}';}})[0])")
    # the attack's own 4, then the card's extra damage 2, then the status
    ck("then the attack's damage floats first, in red", q and q[0]=="-4 HP|"+RED, q)
    ck("then the card's extra damage", len(q)>1 and q[1]=="-2 HP|"+RED, q)
    ck("and the status it caused after them, as a debuff in red", len(q)>2 and q[2]=="Pinned|"+RED, q)
    pg.wait_for_timeout(2100)
    q2=E(f"()=>T.q(SIM.units.filter(function(u){{return u.id==='{r['gid']}';}})[0])")
    ck("each text lasts two seconds, then the next shows", q2 and q2[0]=="-2 HP|"+RED, q2)

    # ---- a miss and a glancing hit, in white ----
    r=E("""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,3), g=T.put('Test Grunt','enemy',0,-1);
      SIM_FORCE.push(1); simConfirmAttack(w,g,T.act(w,'Pinning Volley')); window._g=g; return true; }""")
    pg.wait_for_timeout(700)
    ck("a miss floats Miss in white", E("()=>T.q(window._g)[0]")=="Miss|"+WHITE, E("()=>T.q(window._g)"))
    E("""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,3), g=T.put('Test Grunt','enemy',0,-1); g.ac=40;
      SIM_FORCE.push(20); SIM_FORCE.push(1); simConfirmAttack(w,g,T.act(w,'Pinning Volley')); window._g=g; }""")
    pg.wait_for_timeout(700)
    ck("a hit that doesn't penetrate floats -0 HP in white", E("()=>T.q(window._g)[0]")=="-0 HP|"+WHITE, E("()=>T.q(window._g)"))

    # ---- melee: no projectile ----
    r=E("""()=>{ T.clear(); var s=T.put('Test Striker','ally',0,2), g=T.put('Test Grunt','enemy',0,1);
      SIM_FORCE.push(20); SIM_FORCE.push(20); simConfirmAttack(s,g,T.act(s,'Shoulder Check')); return {shots:SIM_FX.shots.length, q:T.q(g)}; }""")
    ck("a melee attack has no projectile, and floats at once", r["shots"]==0 and r["q"] and r["q"][0].endswith(RED), r)

    # ---- healing and buffs in green ----
    r=E("""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,2), s=T.put('Test Striker','ally',1,2); s.hp=s.hpMax-10;
      simRunText('[[target ally]] gains [[heal 5]].',{actor:w,target:s,sourceCard:'T'});
      simRunText('[[target ally]] gains [[Evasive 2]] for [[turns 2]].',{actor:w,target:s,sourceCard:'T'});
      return T.q(s); }""")
    ck("healing floats in green", r and r[0]=="+5 HP|"+GREEN, r)
    ck("a buff floats in green", len(r)>1 and r[1]=="Evasive 2|"+GREEN, r)

    # ---- an Enemy's projectile is red ----
    r=E("""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,3), n=T.put('Test Gunner','enemy',0,-2);
      SIM_FORCE.push(20); SIM_FORCE.push(20); simConfirmAttack(n,w,T.act(n,'Long Shot')); return SIM_FX.shots[0]&&SIM_FX.shots[0].colour; }""")
    ck("an Enemy's projectile is red", r=="#ff2a3c", r)

    # ---- the player's Burst ----
    r=E("""()=>{ T.clear(); var w=T.put('Test Drone','ally',0,3), a=T.put('Test Grunt','enemy',-1,0), b2=T.put('Test Grunt','enemy',1,-1);
      for(var i=0;i<12;i++) SIM_FORCE.push(20); var n0=w.nrg; window._w=w; window._a=a; window._b=b2;
      simConfirmAttack(w,a,T.act(w,'Rapid Fire')); return {paid:n0-w.nrg, live:simBurstLive(), lit:Object.keys(SIM.targets||{}).length}; }""")
    ck("Burst pays its Energy once, up front", r["paid"]==2, r)
    ck("with two targets in reach, it waits for your choice", r["live"] and r["lit"]==2, r)
    E("()=>{ SIM.phase='draw'; }"); E("()=>{ SIM.phase='turn'; }")
    n=E("()=>SIM.units.filter(function(u){return u.side==='ally';}).length")
    E("()=>{ simNextPhase(); }")
    ck("the turn can't end mid-Burst", E("()=>SIM.phase")=="turn" and E("()=>simBurstLive()"))
    E("()=>{ var c=simAllCards().filter(function(x){return x.name==='Test Snare';})[0]; SIM.hand.push(simHandCardOf(c)); simPlayCard(SIM.hand.length-1); }")
    ck("nor can a card be played", E("()=>SIM.hand.length")>=1 and E("()=>simBurstLive()"))
    E("()=>{ var b=window._b; SIM.pendingAct=SIM.pendingAct; simConfirmAttack(window._w,b,T.act(window._w,'Rapid Fire'),SIM.burst.left-1); }")
    pg.wait_for_timeout(300)
    ck("choosing a target continues the Burst", E("()=>SIM.burst?SIM.burst.left:0")==1 or E("()=>simBurstLive()"))
    E("()=>{ simConfirmAttack(window._w,window._a,T.act(window._w,'Rapid Fire'),SIM.burst.left-1); }")
    pg.wait_for_timeout(300)
    r=E("()=>({live:simBurstLive(), used:SIM.log.filter(function(l){return / used Rapid Fire /.test(l.text);}).length, nrg:window._w.nrg})")
    ck("after three attacks the Burst ends", not r["live"] and r["used"]==3, r)

    # ---- an Enemy's Burst chooses afresh each time ----
    r=E("""()=>new Promise(function(res){ T.clear(); SIM.phase='enemy'; SIM.autoRunning=false;
      var w=T.put('Test Warden','ally',0,3), s=T.put('Test Striker','ally',1,2), h=T.put('Test Hacker','enemy',0,0);
      h.comboAt=0; for(var i=0;i<12;i++) SIM_FORCE.push(20);
      simOneEnemy(h,function(){ var used=SIM.log.filter(function(l){ return /Test Hacker used Spike/.test(l.text); }).length;
        res({used:used, energy:h.nrg}); }); }).then(function(x){ SIM.phase='turn'; return x; })""")
    ck("an Enemy's Burst makes all its attacks", r["used"]==2, r)

    # ---- a held Burst fires in full at the Enemy that triggered it ----
    r=E("""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,3), g=T.put('Test Juggernaut','enemy',0,-2); g.hp=g.hpMax=300;
      w.holding={name:'Burst Watch', action:{name:'Burst Watch', role:'ranged', rng:'6', hit:'2', pen:'8', dmg:'2', cost:'0', text:'[[Suppressive Fire]]. [[Burst 3]].'}};
      for(var i=0;i<12;i++) SIM_FORCE.push(20); var hp=g.hp; simReactTo(g);
      return {shots:SIM.log.filter(function(l){ return /reacts with Burst Watch/.test(l.text); }).length, lost:hp-g.hp}; }""")
    ck("a held Burst fires every attack at the Enemy that moved", r["shots"]==3 and r["lost"]>0, r)

    # ---- v13.2: an Enemy still out of reach after its move does not attack ----
    r=E("""()=>new Promise(function(res){ T.clear(); SIM.phase='enemy'; SIM.autoRunning=false;
      var w=T.put('Test Warden','ally',-3,6), g=T.put('Test Grunt','enemy',0,-6); var hp=w.hp, from=T.R.hexDistance(g.pos,w.pos);
      for(var i=0;i<8;i++) SIM_FORCE.push(20);
      simOneEnemy(g,function(){ res({moved:from-T.R.hexDistance(g.pos,w.pos), now:T.R.hexDistance(g.pos,w.pos), lost:hp-w.hp,
        used:SIM.log.filter(function(l){ return /Test Grunt used/.test(l.text); }).length,
        said:SIM.log.filter(function(l){ return l.text==='Test Grunt has nothing in reach'; }).length}); }); }).then(function(x){ SIM.phase='turn'; SIM_FORCE.length=0; return x; })""")
    ck("an Enemy far off closes in", r["moved"]>0 and r["now"]>1, r)
    ck("and, still out of reach, makes no attack", r["used"]==0 and r["lost"]==0, r)
    ck("and says it has nothing in reach", r["said"]==1, r)

    # ---- v13.2: an Enemy brought down by a held shot as it moves does not attack ----
    r=E("""()=>new Promise(function(res){ T.clear(); SIM.phase='enemy'; SIM.autoRunning=false;
      var w=T.put('Test Warden','ally',0,5), g=T.put('Test Gunner','enemy',0,-3); g.hp=1; var hp=w.hp;
      w.holding={name:'Watch', action:{name:'Watch', role:'ranged', rng:'7', hit:'2', pen:'12', dmg:'9', cost:'0', text:'[[Suppressive Fire]].'}};
      for(var i=0;i<8;i++) SIM_FORCE.push(20);
      simOneEnemy(g,function(){ res({down:!!g.down, lost:hp-w.hp,
        reacted:SIM.log.filter(function(l){ return /reacts with Watch/.test(l.text); }).length,
        used:SIM.log.filter(function(l){ return /Test Gunner used/.test(l.text); }).length}); }); }).then(function(x){ SIM.phase='turn'; SIM_FORCE.length=0; return x; })""")
    ck("a held shot brings down an Enemy as it moves into reach", r["reacted"]==1 and r["down"], r)
    ck("and it does not go on to attack", r["used"]==0 and r["lost"]==0, r)

    # ---- nothing can leave a stale Burst behind ----
    ck("a Burst whose Unit is gone no longer blocks anything",
       E("()=>{ SIM.burst={unit:'nobody',action:'x',left:2}; SIM.pendingAct={unit:'nobody',name:'x',burst:true}; return simBurstLive(); }") is False)

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"FX PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
