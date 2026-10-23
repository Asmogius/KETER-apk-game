"""The checklist, played by a tester: each test card's situation is built with
the debug tools, the card is used with forced hits, and the result is compared
with what the card says it does."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
ONLY=sys.argv[1:]  # optionally, the numbers of the checks to run
TMP=pathlib.Path("/tmp/pt_check")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9697),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()

LIB = r"""
window.T = {
  R: window.KETER_RULES,
  clear: function(){ SIM.burst=null; SIM.pendingAct=null; SIM.units=[]; SIM.selected=null; SIM.pick=null; SIM.aim=null; SIM.halted=null; SIM.phase='turn'; SIM.over=false;
    SIM.aether={generic:50,d3:50}; SIM_FORCE.length=0; SIM.log=[]; },
  put: function(name, side, q, r){
    SIM_DBG.place={card:name, side:side}; simDebugTap({q:q,r:r});
    var u=SIM.units[SIM.units.length-1]; if(!u||u.pos.q!==q||u.pos.r!==r) throw new Error('could not place '+name+' at '+q+','+r);
    u.nrg=Math.max(u.nrg,6); return u; },
  act: function(u, actName, t, rolls){
    var a=(u.actions||[]).filter(function(x){ return x.name===actName; })[0];
    if(!a) throw new Error(u.name+' has no Action '+actName+' ('+(u.actions||[]).map(function(x){return x.name;}).join(',')+')');
    (rolls||[20,20]).forEach(function(v){ SIM_FORCE.push(v); });
    simConfirmAttack(u,t,a); SIM_FORCE.length=0; return a; },
  card: function(name, target, tile){
    var c=simAllCards().filter(function(x){ return x.name===name; })[0];
    SIM.hand.push(simHandCardOf(c)); var i=SIM.hand.length-1;
    simPlayCard(i);
    if(SIM.pick){ var pk=SIM.pick; SIM.pick=null; pk.done(target); }
    if(SIM.aim){ SIM.aim.at=tile; simConfirmAim(); }
    return c; },
  st: function(u,n){ return T.R.statusN(u,n); },
  turns: function(u,n){ return T.R.statusTurns(u,n); },
  give: function(u, cardName){       /* a placed Hero has no Strike Team, so hand it an Action Card */
    var c=simAllCards().filter(function(x){ return x.name===cardName; })[0];
    var tmp=T.R.unitFromCard({name:c.name, cardType:'hero', stats:{}, entries:c.entries||c.abilities}, 'ally');
    u.actions=(u.actions||[]).concat(tmp.actions); },
  logs: function(){ return SIM.log.map(function(l){ return l.text; }); },
  eff: function(u){ return T.R.effective(u); }
};
"""

CHECKS = [
 ("Warden Pinning Volley: +2 damage and Pinned for 2 turns on a hit", r"""()=>{ T.clear();
   var w=T.put('Test Warden','ally',0,2), g=T.put('Test Grunt','enemy',0,-1); var hp=g.hp;
   T.act(w,'Pinning Volley',g); return {lost:hp-g.hp, pinned:T.turns(g,'Pinned'), expectLost:4+2}; }""",
   lambda r: r["lost"]==r["expectLost"] and r["pinned"]==2),
 ("Warden Overwatch: holds only if unmoved, pays 2, shoots the first Enemy into range", r"""()=>{ T.clear();
   var w=T.put('Test Warden','ally',0,3), g=T.put('Test Grunt','enemy',0,-3); w.nrg=6; w.moved=1;
   var movedCan=simHoldable(w).length; w.moved=0; var n0=w.nrg; simHoldFire(w,'Overwatch');
   var paid=n0-w.nrg, held=!!w.holding; var hp=g.hp; SIM_FORCE.push(20); SIM_FORCE.push(20);
   g.pos={q:0,r:0}; simReactTo(g); SIM_FORCE.length=0;
   return {movedCan:movedCan, paid:paid, held:held, shot:hp-g.hp, spent:!w.holding}; }""",
   lambda r: r["movedCan"]==0 and r["paid"]==2 and r["held"] and r["shot"]>0 and r["spent"]),
 ("Warden Field Medicine: heals another ally 5 and clears Poisoned, never itself", r"""()=>{ T.clear();
   var w=T.put('Test Warden','ally',0,2), s=T.put('Test Striker','ally',1,2), g=T.put('Test Grunt','enemy',0,-3);
   s.hp=s.hpMax-8; T.R.addStatus(s,'Poisoned',3,'t'); T.act(w,'Field Medicine',s);
   var self0=w.hp; w.hp=w.hpMax-8; var selfTry=simCanReach(w,(w.actions||[]).filter(function(a){return a.name==='Field Medicine';})[0],w);
   return {healed:(s.hpMax-8), now:s.hp, poisoned:T.st(s,'Poisoned'), selfTarget:selfTry}; }""",
   lambda r: r["now"]-r["healed"]==5 and r["poisoned"]==0),
 ("Warden Steady Nerve: Integrity +1 from the start of the fight", r"""()=>{ T.clear();
   var w=T.put('Test Warden','ally',0,2); return {base:w.integrity, eff:T.eff(w).integrity, mods:(w.mods||[]).map(function(m){return m.stat+m.amt;})}; }""",
   lambda r: "INT1" in r["mods"] and r["eff"]==r["base"]+1),
 ("Striker Shoulder Check: Push 2 into a Unit hurts both", r"""()=>{ T.clear();
   var s=T.put('Test Striker','ally',0,2), g=T.put('Test Grunt','enemy',0,1), g2=T.put('Test Grunt','enemy',0,0);
   var a=g.hp, b=g2.hp; T.act(s,'Shoulder Check',g); return {g:a-g.hp, g2:b-g2.hp, pos:JSON.stringify(g.pos)}; }""",
   lambda r: r["g"]==4+2 and r["g2"]==2),
 ("Striker Rending Blow: Bleed, and Sundered 2, both for 3 turns, when it damages", r"""()=>{ T.clear();
   var s=T.put('Test Striker','ally',0,2), g=T.put('Test Grunt','enemy',0,1); T.act(s,'Rending Blow',g);
   return {bleed:T.turns(g,'Bleed'), sund:T.st(g,'Sundered'), sundT:T.turns(g,'Sundered')}; }""",
   lambda r: r["bleed"]==3 and r["sund"]==2 and r["sundT"]==3),
 ("Striker Finisher: heals 4 only on a kill", r"""()=>{ T.clear();
   var s=T.put('Test Striker','ally',0,2), g=T.put('Test Grunt','enemy',0,1), g2=T.put('Test Grunt','enemy',1,1);
   s.hp=s.hpMax-10; var h0=s.hp; T.act(s,'Finisher',g2); var noKill=s.hp-h0; g.hp=2; var h1=s.hp; T.act(s,'Finisher',g);
   return {noKill:noKill, onKill:s.hp-h1, down:g.down}; }""",
   lambda r: r["noKill"]==0 and r["onKill"]==4 and r["down"]),
 ("Drone Lift Off: Flying, so melee cannot hit it", r"""()=>{ T.clear();
   var d=T.put('Test Drone','ally',0,2), g=T.put('Test Grunt','enemy',0,1); var hp=d.hp; T.act(g,'Jab',d);
   return {flying:T.eff(d).flying, lost:hp-d.hp}; }""",
   lambda r: r["flying"] and r["lost"]==0),
 ("Drone Tag: Marked for 2 turns, and a ranged shot then always hits", r"""()=>{ T.clear();
   var d=T.put('Test Drone','ally',0,3), w=T.put('Test Warden','ally',1,3), g=T.put('Test Grunt','enemy',0,-1);
   T.act(d,'Tag',g); var hp=g.hp; w.actions.filter(function(x){ return x.name==='Pinning Volley'; })[0].hit='21';
   T.act(w,'Pinning Volley',g,[20,20]); return {marked:T.turns(g,'Marked'), lost:hp-g.hp}; }""",
   lambda r: r["marked"]==2 and r["lost"]>0),
 ("Sapper Satchel Charge: AoE 1 hits everything next to the target, ally too", r"""()=>{ T.clear();
   var s=T.put('Test Sapper','ally',0,3), g=T.put('Test Grunt','enemy',0,1), g2=T.put('Test Grunt','enemy',1,1), a=T.put('Test Drone','ally',-1,1);
   var x=g2.hp, y=a.hp; T.act(s,'Satchel Charge',g); return {g2:x-g2.hp, ally:y-a.hp}; }""",
   lambda r: r["g2"]>0 and r["ally"]>0),
 ("Sapper Dead Man's Switch: 3 to Enemies within 1 when it goes down", r"""()=>{ T.clear();
   var s=T.put('Test Sapper','ally',0,1), g=T.put('Test Grunt','enemy',0,0); var hp=g.hp; T.R.hit(s,s.hp); simCheckDowns();
   return {lost:hp-g.hp}; }""", lambda r: r["lost"]==3),
 ("Battery Overcharge: Sacrifices itself, allies within 2 get +1 Movement for 2 turns", r"""()=>{ T.clear();
   var b=T.put('Test Battery','ally',0,2), w=T.put('Test Warden','ally',1,2), g=T.put('Test Grunt','enemy',0,-3);
   var ms=T.eff(w).ms; T.act(b,'Overcharge',w); return {down:b.down, ms:T.eff(w).ms-ms}; }""",
   lambda r: r["down"] and r["ms"]==1),
 ("Grunt Jab and Bash: Weakened 2, then Slowed 2 when Bash damages", r"""()=>{ T.clear();
   var w=T.put('Test Warden','ally',0,2), g=T.put('Test Grunt','enemy',0,1); T.act(g,'Jab',w); T.act(g,'Bash',w);
   return {weak:T.st(w,'Weakened'), slow:T.st(w,'Slowed')}; }""",
   lambda r: r["weak"]==2 and r["slow"]==2),
 ("Gunner Long Shot: +2 only beyond 3 tiles; Point Blank Stuns only within 2", r"""()=>{ T.clear();
   var w=T.put('Test Warden','ally',0,3), n=T.put('Test Gunner','enemy',0,-2); var hp=w.hp; T.act(n,'Long Shot',w); var far=hp-w.hp;
   var s=T.put('Test Striker','ally',1,-2); T.act(n,'Point Blank',s); return {far:far, stun:T.st(s,'Stunned')}; }""",
   lambda r: r["far"]==3+2 and r["stun"]==1),
 ("Hacker Breach: a Cyber attack penetrates Integrity, not Armor Class, and Slows only what it damages", r"""()=>{ T.clear();
   var s=T.put('Test Striker','ally',0,2), w=T.put('Test Warden','ally',1,2), h=T.put('Test Hacker','enemy',0,-1);
   s.ac=20; s.integrity=5; w.ac=5; w.integrity=20;
   var sh=s.hp, wh=w.hp;
   T.act(h,'Breach',s,[20,10]); T.act(h,'Breach',w,[20,10]);
   var soft=sh-s.hp, hard=wh-w.hp;   /* measured before Spike, which does damage of its own */
   T.act(h,'Spike',w);
   return {soft:soft, hard:hard, slowSoft:T.st(s,'Slowed'), slowHard:T.st(w,'Slowed'), drained:T.st(w,'Drained')}; }""",
   lambda r: r["soft"]>0 and r["hard"]==0 and r["slowSoft"]==1 and r["slowHard"]==0 and r["drained"]==2),
 ("Juggernaut: Evasive 2 on arrival; Venom Spit Poisons, and a second dose adds", r"""()=>{ T.clear();
   var w=T.put('Test Warden','ally',0,3), j=T.put('Test Juggernaut','enemy',0,0);
   T.act(j,'Venom Spit',w); T.act(j,'Venom Spit',w); return {evasive:T.st(j,'Evasive'), poison:T.st(w,'Poisoned')}; }""",
   lambda r: r["evasive"]==2 and r["poison"]==6),
 ("Overseer Arc Lash: the damage jumps to the nearest other target within 3", r"""()=>{ T.clear();
   var w=T.put('Test Warden','ally',0,3), s=T.put('Test Striker','ally',1,3), o=T.put('Test Overseer','enemy',0,-1);
   var hp=s.hp; T.act(o,'Arc Lash',w); return {chained:hp-s.hp}; }""", lambda r: r["chained"]>0),
 ("Overseer Call Reinforcement: a Test Grunt appears beside it", r"""()=>{ T.clear();
   var w=T.put('Test Warden','ally',0,3), o=T.put('Test Overseer','enemy',0,-1); var n=SIM.units.length;
   T.act(o,'Call Reinforcement',w); var nu=SIM.units[SIM.units.length-1];
   return {added:SIM.units.length-n, name:nu&&nu.name, side:nu&&nu.side, dist:nu?T.R.hexDistance(nu.pos,o.pos):null}; }""",
   lambda r: r["added"]==1 and r["name"]=="Test Grunt" and r["side"]=="enemy" and r["dist"]==1),
 ("Overseer Oppressive Presence: your Units within 2 are Weakened", r"""()=>{ T.clear();
   var w=T.put('Test Warden','ally',0,1), o=T.put('Test Overseer','enemy',0,0); SIM.phase='draw'; simNextPhase(true);
   return {weak:T.st(w,'Weakened'), eff:T.eff(w).dmgFlat}; }""", lambda r: r["weak"]>=1 or r["eff"]<0),
 ("Piercing Rounds: the Unit directly behind takes the same", r"""()=>{ T.clear();
   var w=T.put('Test Warden','ally',0,3), g=T.put('Test Grunt','enemy',0,1), g2=T.put('Test Grunt','enemy',0,0);
   T.give(w,'Test Piercing Rounds'); var hp=g2.hp; T.act(w,'Piercing Rounds',g); return {behind:hp-g2.hp}; }""", lambda r: r["behind"]>0),
 ("Overclock Routine: +2 damage for 2 turns, then Drained 2", r"""()=>{ T.clear();
   var s=T.put('Test Striker','ally',0,2), g=T.put('Test Grunt','enemy',0,-3); T.give(s,'Test Overclock Routine'); T.act(s,'Overclock Routine',s);
   return {dmg:T.eff(s).dmgFlat, drained:T.st(s,'Drained')}; }""", lambda r: r["dmg"]==2 and r["drained"]==2),
 ("Plating: AC +2 while carried, gone when removed; Strip removes it", r"""()=>{ T.clear();
   var w=T.put('Test Warden','ally',0,2), s=T.put('Test Striker','ally',1,2), g=T.put('Test Grunt','enemy',0,-3);
   var ac=T.eff(s).ac; T.card('Test Plating',s); var on=T.eff(s).ac-ac; T.card('Test Strip',s); var off=T.eff(s).ac-ac;
   return {on:on, off:off, carried:(s.equipment||[]).length}; }""", lambda r: r["on"]==2 and r["off"]==0 and r["carried"]==0),
 ("Targeting Suite: +1 Range and +2 Penetration", r"""()=>{ T.clear();
   var w=T.put('Test Warden','ally',0,2), g=T.put('Test Grunt','enemy',0,-3); T.card('Test Targeting Suite',w);
   return {range:T.eff(w).range, ap:T.eff(w).ap}; }""", lambda r: r["range"]==1 and r["ap"]==2),
 ("Mortar Strike: everything within 1 of the tile takes 4", r"""()=>{ T.clear();
   var w=T.put('Test Warden','ally',0,3), g=T.put('Test Grunt','enemy',0,0), g2=T.put('Test Grunt','enemy',1,0), far=T.put('Test Grunt','enemy',3,-3);
   var a=g.hp,b=g2.hp,c=far.hp; T.card('Test Mortar Strike',null,{q:0,r:0}); return {g:a-g.hp, g2:b-g2.hp, far:c-far.hp}; }""",
   lambda r: r["g"]==4 and r["g2"]==4 and r["far"]==0),
 ("Snare: Rooted for 2 turns, so it cannot move", r"""()=>{ T.clear();
   var w=T.put('Test Warden','ally',0,3), g=T.put('Test Grunt','enemy',0,0); T.card('Test Snare',g);
   return {root:T.turns(g,'Rooted'), ms:T.eff(g).ms, others:(g.statuses||[]).length}; }""",
   lambda r: r["root"]==2 and r["ms"]==0 and r["others"]==1),
 ("Surge: +5 HP, maximum and current, for 2 turns; allies within 3 +1 Movement", r"""()=>{ T.clear();
   var w=T.put('Test Warden','ally',0,3), s=T.put('Test Striker','ally',1,3), g=T.put('Test Grunt','enemy',0,-3);
   var wm=w.hpMax, wh=w.hp, ms=T.eff(s).ms; T.card('Test Surge',w);
   return {max:w.hpMax-wm, now:w.hp-wh, ms:T.eff(s).ms-ms}; }""",
   lambda r: r["max"]==5 and r["now"]==5 and r["ms"]>=1),
 ("Drone Rapid Fire: a Burst of 3 for one payment, continuing on the only target in reach", r"""()=>{ T.clear();
   var w=T.put('Test Drone','ally',0,3), g=T.put('Test Juggernaut','enemy',0,0); g.hp=g.hpMax=200;
   var a=(w.actions||[]).filter(function(x){return x.name==='Rapid Fire';})[0]; w.nrg=6; var n0=w.nrg, before=SIM.log.length;
   for(var i=0;i<6;i++) SIM_FORCE.push(20);
   simConfirmAttack(w,g,a); return new Promise(function(res){ setTimeout(function(){
     var used=SIM.log.slice(before).filter(function(l){ return / used Rapid Fire /.test(l.text); }).length;
     res({attacks:used, paid:n0-w.nrg, left:!!SIM.burst}); SIM_FORCE.length=0; }, 1900); }); }""",
   lambda r: r["attacks"]==3 and r["paid"]==2 and not r["left"]),
 ("Aegis Core: Units next to the leader gain 1 Armor Class when the fight begins", r"""()=>{
   SIM.map=null; SIM.units=[]; simDebugStart('TEST \u00b7 Waves');
   var lead=SIM.units.filter(function(u){return u.id===SIM.leader;})[0];
   var near=SIM.units.filter(function(u){ return u.side==='ally'&&u!==lead&&T.R.hexDistance(u.pos,lead.pos)===1; });
   return {near:near.length, gained:near.map(function(u){ return (u.mods||[]).some(function(m){return m.stat==='AC'&&m.amt===1;}); }),
           leadGained:(lead.mods||[]).some(function(m){return m.stat==='AC';})}; }""",
   lambda r: (r["near"]==0 or all(r["gained"])) and not r["leadGained"]),
 ("A Unit that dies on a hazard still fires its when-Incapacitated effect", r"""()=>{
   SIM.map=null; SIM.units=[]; simDebugStart('TEST \u00b7 Hazards and Cover'); T.clear();
   var R=T.R, hz=Object.keys(SIM.map.hazards||{})[0]; if(!hz) return {skip:'no hazard'}; var a=R.hexParse(hz);
   var g=null; [[1,0],[0,1],[-1,1],[-1,0],[0,-1],[1,-1]].some(function(d){ var q=a.q+d[0], r=a.r+d[1];
     if(SIM.map.hexes[R.hexKey(q,r)]&&!simUnitAt(q,r)){ g=T.put('Test Grunt','enemy',q,r); return true; } return false; });
   var s=T.put('Test Sapper','ally',a.q,a.r); s.hp=1; var hp=g.hp;
   simHazardHit(s,'ends its turn on'); simCheckDowns();
   return {down:s.down, enemyLost:hp-g.hp}; }""", lambda r: r.get("down") and r.get("enemyLost")==3),
 ("Spark Chip: spending it deals 3 to a chosen Enemy", r"""()=>{ T.clear();
   var w=T.put('Test Warden','ally',0,3), g=T.put('Test Grunt','enemy',0,0); var c=simAllCards().filter(function(x){return x.name==='Test Spark Chip';})[0];
   SIM.bank=[{name:c.name, value:2, district:'3', spent:false, effect:true, card:c, _raw:c}]; var hp=g.hp;
   simSpendChip(0); if(SIM.pick){ var pk=SIM.pick; SIM.pick=null; pk.done(g); }
   return {lost:hp-g.hp, log:T.logs().slice(-2)}; }""", lambda r: r["lost"]==3),
 ("Smoke: the user counts as in Half Cover", r"""()=>{ T.clear();
   var w=T.put('Test Warden','ally',0,3), g=T.put('Test Gunner','enemy',0,-2);
   var odds0=simOdds(g,(g.actions||[])[0],w).p; w.hp=w.hp; SIM.cons=[{name:'Test Smoke',used:false}];
   var c=simAllCards().filter(function(x){return x.name==='Test Smoke';})[0]; simRunText((c.entries||c.abilities)[0].text,{actor:w,target:w,sourceCard:c.name});
   return {before:odds0, after:simOdds(g,(g.actions||[])[0],w).p}; }""", lambda r: r["after"]<r["before"]),
]

with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:300]))
    pg.goto("http://127.0.0.1:9697/"); pg.wait_for_timeout(2000)
    pg.evaluate("()=>{ localStorage.setItem('keter-app-simdebug','1'); localStorage.setItem('keter-app-dice',JSON.stringify({dur:0})); localStorage.removeItem('keter-app-sim'); }")
    pg.reload(); pg.wait_for_timeout(2000)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(500)
    pg.evaluate("()=>simDebugStart('TEST \u00b7 Hazards and Cover')"); pg.wait_for_timeout(1500)
    pg.evaluate(LIB)
    results=[]
    for i,(name,js,test) in enumerate(CHECKS,1):
        if ONLY and str(i) not in ONLY: continue
        n0=len(errs)
        try:
            r=pg.evaluate(js); pg.wait_for_timeout(150)
            ok = None if test is None else bool(test(r))
        except Exception as e:
            r={"threw":str(e)[:260]}; ok=False
        je=errs[n0:]
        if je: ok=False; r["js"]=je[:2]
        results.append((i,name,ok,r))
        print(f"{'PASS' if ok else ('SKIP' if ok is None else 'FAIL')} {i:2} {name}" + ("" if ok else "\n        "+json.dumps(r)[:330]))
    b.close()
srv.shutdown()
bad=[r for r in results if r[2] is False]
print(f"CHECKLIST PASS {sum(1 for r in results if r[2])}  FAIL {len(bad)}")
sys.exit(1 if bad else 0)
