"""The movement keywords (Revision 16.1, Companion 14.8): Lunge, Charge, Dash
and Leap in the library and the power score, and carried out by the Battle
Simulator: a Lunge reaching a target 3 tiles off and walking to it, Charge's
damage in the odds and in the Log, a Dash on the action bar, an Enemy's Dash
away, and a Leap across a gap among the lit tiles."""
import http.server, socketserver, threading, functools, pathlib, shutil, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_movekw")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9872),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""):
    (ok if c else bad).append(n+((" — "+str(d)[:260]) if not c else ""))
    print(("PASS " if c else "FAIL ")+n+("" if c else "  — "+str(d)[:260]))
# a floor with a gap the whole way down its middle (no tiles at q = 0)
hexes=[[f"{q},{r}",{}] for q in range(-4,5) for r in range(-4,5) if abs(q+r)<=4 and q!=0]
GAP={"v":6,"name":"Gap Test","radius":4,"hexes":hexes,"walls":[],"marks":[],"symDefs":[],"colorLabels":{}}
SETUP="""(spec)=>{
  var all=JSON.parse(localStorage.getItem('keter-hexmap-levels')||'{}'); all['Gap Test']=window.GAP_IN; localStorage.setItem('keter-hexmap-levels',JSON.stringify(all));
  SIM.map=simLoadFloor('Gap Test');
  SIM.units=spec.map(function(s){ var c=simAllCards().filter(function(x){ return x.name===s[0]; })[0];
    var u=KETER_RULES.unitFromCard(simUnitSpec(c,s[1]),s[1]); u.id=s[2]; u.pos={q:s[3],r:s[4]}; return u; });
  SIM.round=1; SIM.phase='turn'; SIM.log=[]; SIM.over=false; SIM.autoRunning=true;
  SIM.hand=[]; SIM.deck=[]; SIM.discard=[]; SIM.aether={}; SIM.pendingAct=null; SIM.burst=null;
  simApplyContinuous(); renderSim(); return SIM.units.length; }"""
U="function(id){ return SIM.units.filter(function(u){ return u.id===id; })[0]; }"
with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915}).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("dialog",lambda d:d.accept())
    pg.goto("http://127.0.0.1:9872/"); pg.wait_for_timeout(2000)
    pg.evaluate("()=>localStorage.setItem('keter-app-dice',JSON.stringify({dur:0}))")
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(500)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(900)
    E=pg.evaluate
    E("(g)=>{ window.GAP_IN=g; }", GAP)
    r=E("""()=>{ var K=KETER_KW, S=KETER_SCORE; return {cats:['Lunge','Charge','Dash','Leap'].map(function(n){ var k=K.byName(n); return k?k.cat:null; }),
      text:K.render('[[Lunge 2]]. [[Charge 2]]. [[this Unit]] gains [[Dash 2]]. [[this Unit]] gains [[Leap 3]].'),
      pts:[S.keywordPoints('[[Lunge 2]]. [[Charge 2]].',{attack:true}), S.keywordPoints('[[Burst 2]].',{attack:true}), S.keywordPoints('[[this Unit]] gains [[Dash 2]].')],
      passive:K.problems(K.analyse('[[Charge 2]].'),{kind:'passive'})}; }""")
    ck("the library has the four: Lunge and Charge Modifiers, Dash and Leap Effects", r["cats"]==["modifier","modifier","effect","effect"], r)
    ck("they read as cards print them", r["text"]=="Lunge 2 tiles. Charge 2. This Unit gains Dash 2 tiles. This Unit gains Leap 3 tiles.", r["text"])
    ck("Lunge and Charge add to an attack's power, where Burst multiplies it; Dash is 1 a tile", r["pts"]==[8,8,2], r["pts"])
    ck("Charge in a Passive is flagged", r["passive"]==["Charge is made with an attack: put it on a Melee Action"], r["passive"])
    ck("the two new test cards are in the library", E("()=>['Test Skirmisher','Test Skitter'].every(function(n){ return simAllCards().some(function(c){ return c.name===n; }); })"))

    # ---- Lunge and Charge ----
    E(SETUP, [["Test Skirmisher","ally","a1",-2,-1],["Test Grunt","enemy","e1",-2,2],["Test Grunt","enemy","e2",-3,4]])
    r=E("""()=>{ var U="""+U+""", sk=U('a1'); simSelect(sk); simPickAction(sk,'Pounce');
      var t=Object.keys(SIM.targets||{}).map(function(k){ return SIM.targets[k]; }).sort(), o=SIM.odds['-2,2'];
      sk.travel=1; var o2=simOdds(sk, sk.actions.filter(function(a){ return a.name==='Pounce'; })[0], U('e1')); sk.travel=0;
      return {t:t, dmg:o?o.dmg:null, dmg2:o2.dmg}; }""")
    ck("Pounce (Lunge 2) lights the Enemy 3 tiles off, not the one 4 off", r["t"]==["e1"], r)
    ck("its odds show 3 damage, and 5 once the Lunge would bring the Skirmisher's travel to 3 (Charge 2)", r["dmg"]==3 and r["dmg2"]==5, r)
    r=E("""()=>{ var U="""+U+""", sk=U('a1'), g=U('e1'); SIM.log=[]; simConfirmAttack(sk, g, sk.actions.filter(function(a){ return a.name==='Pounce'; })[0]);
      return {pos:sk.pos, d:KETER_RULES.hexDistance(sk.pos,g.pos), travel:sk.travel, log:SIM.log.map(function(l){ return l.text; })}; }""")
    ck("used, it walks 2 tiles to stand beside the Grunt, free, then strikes; the Log says it lunged", r["d"]==1 and r["travel"]==2 and r["log"][0]=="Test Skirmisher lunges 2 tiles at Test Grunt", r)
    hits=E("""()=>{ var U="""+U+""", sk=U('a1'), g=U('e1'), a=sk.actions.filter(function(x){ return x.name==='Pounce'; })[0], n=0, bad=0;
      for(var i=0;i<12;i++){ sk.travel=3; sk.nrg=3; g.hp=18; g.statuses=[]; g.mods=[]; SIM.log=[]; simConfirmAttack(sk,g,a);
        var l=SIM.log.map(function(x){ return x.text; }).join(' | '); if(/: \\d+ damage/.test(l)){ n++; if(!/: 5 damage \\(Charge \\+2\\)/.test(l)) bad++; } }
      return {n:n, bad:bad}; }""")
    ck("having moved 3 tiles, each blow that lands deals 5 and the Log says (Charge +2)", hits["n"]>0 and hits["bad"]==0, hits)

    # ---- Dash ----
    E(SETUP, [["Test Skirmisher","ally","a1",-4,0],["Test Grunt","enemy","e1",3,0]])
    r=E("""()=>{ var U="""+U+""", sk=U('a1'); simRunText('[[this Unit]] gains [[Dash 2]].',{actor:sk, sourceCard:'Test'});
      simSelect(sk); var bar=simActionBarHTML(sk); return {bar:/Move <b>6<\\/b>\\/6/.test(bar), reach:Math.max.apply(null,SIM.reach.map(function(t){ return t.cost; })), dash:sk.dash}; }""")
    ck("Dash 2 shows on the action bar as Move 6/6, and the lit tiles reach 6 away", r["bar"] and r["reach"]==6 and r["dash"]==2, r)
    r=E("""()=>{ simTurnEndTick(); var U="""+U+"""; return U('a1').dash; }""")
    ck("what isn't used is gone when the turn ends", r==0, r)
    E(SETUP, [["Test Warden","ally","a1",1,0],["Test Skitter","enemy","e1",2,0]])
    r=E("""()=>{ var U="""+U+""", sx=U('e1'), w=U('a1'); SIM.log=[]; simRunText('[[this Unit]] gains [[Dash 2]].',{actor:sx, target:w, sourceCard:'Rake'});
      return {d:KETER_RULES.hexDistance(sx.pos,w.pos), log:SIM.log.map(function(l){ return l.text; })}; }""")
    ck("an Enemy Dashes at once, away from the Unit it struck", r["d"]==3 and any(t.startswith("Test Skitter Dashes 2 tiles away") for t in r["log"]), r)

    # ---- Leap ----
    E(SETUP, [["Test Warden","ally","a1",-1,0],["Test Grunt","enemy","e1",4,-4]])
    r=E("""()=>{ var U="""+U+""", w=U('a1'); simSelect(w); var before=SIM.reach.filter(function(t){ return t.q>0; }).length;
      simRunText('[[this Unit]] gains [[Leap 3]] for [[turns 2]].',{actor:w, sourceCard:'Spring'}); simSelect(w);
      var jumps=SIM.reach.filter(function(t){ return t.q>0; });
      SIM.log=[]; var moved=simMoveTo(w,2,0);
      return {before:before, jumps:jumps.length, allLeap:jumps.every(function(t){ return t.leap && t.cost<=3; }), moved:moved, pos:w.pos, log:SIM.log.map(function(l){ return l.text; })}; }""")
    ck("without Leap the gap stops a walk; with Leap 3, the tiles across it within 3 are lit", r["before"]==0 and r["jumps"]>3 and r["allLeap"], r)
    ck("and the Warden jumps there; the Log says it leaped", r["moved"] and r["pos"]=={"q":2,"r":0} and "Test Warden leaped 3 tiles" in r["log"], r)
    E(SETUP, [["Test Warden","ally","a1",-4,1],["Test Skitter","enemy","e1",1,0]])
    r=E("""()=>{ var U="""+U+""", sx=U('e1'); SIM.log=[]; SIM.phase='enemy'; simOneEnemy(sx, function(){}); return {q:sx.pos.q, log:SIM.log.map(function(l){ return l.text; })}; }""")
    ck("the Test Skitter leaps the gap, claws the Warden and skitters off a tile", r["q"]<0 and any(t.startswith("Test Skitter used Claw on Test Warden") for t in r["log"]) and r["log"][-1].startswith("Test Skitter Dashes 1 tile away"), r)
    ck("no page errors", not errs, errs[:3])
    b.close()
srv.shutdown()
print(f"\nPASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
