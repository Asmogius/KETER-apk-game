"""The turn, in phases: the Handbook's order, a Movement budget that does not
refill, actions only during Your turn, and undo that takes back a whole phase."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_phases")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
shutil.copy("compendium_full.json", TMP/"compendium.json")
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9917),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))
comp=json.load(open("compendium_full.json"))
TEAM=[{"v":2,"name":"Ledger","level":2,"heroes":["master|Quillon Vex"],
  "deck":["master|Ledger Runner"]*3+["master|Chaff Swarm"]*3+["master|Ballast Plate"]*2+
         ["master|Call the Note"]*2+["master|Debt Collector"]*2,
  "actions":{},"pouch":{"basic|3":6}}]

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:200]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9917/"); pg.wait_for_timeout(2000)
    pg.evaluate("(m)=>localStorage.setItem('keter-app-master',JSON.stringify(m))",
                {"version":"99999","cards":comp["cards"]})
    pg.evaluate("()=>localStorage.setItem('keter-app-dice',JSON.stringify({dur:0}))")
    pg.evaluate("(l)=>localStorage.setItem('keter-app-loadouts',JSON.stringify(l))",TEAM)
    pg.evaluate("()=>localStorage.removeItem('keter-app-sim')")
    pg.reload(); pg.wait_for_timeout(2300)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(600)
    pg.locator("#simSetup").click(); pg.wait_for_timeout(500)
    pg.locator("#simMapSel").select_option(index=0)
    pg.locator("#simMapNext").click(); pg.wait_for_timeout(700)

    # ---- the setup you can see ----
    pg.locator("[data-wizteam] b").first.click(); pg.wait_for_timeout(450)
    ck("a chosen Strike Team is visibly marked", pg.locator(".wizrow.on").count()==1)
    ck("the rows are actually styled",
       pg.evaluate("""()=>{ var e=document.querySelector('.wizrow');
         var s=getComputedStyle(e);
         return s.borderStyle!=='none' && s.padding!=='0px'; }"""))
    pg.locator("#wizNext").click(); pg.wait_for_timeout(500)
    ck("the Hero entering is marked too", pg.locator(".wizrow.on").count()>=1)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(500)
    ck("Starting Troops has its own step", pg.evaluate("()=>SIM_WIZ.step")=="troops")
    ck("it lists the Deck's Troops", pg.locator("[data-wiztroopmore]").count()>0)
    ck("and says what Leadership allows",
       "pooled Leadership" in pg.locator("#wizResults").inner_text())
    took=0
    if pg.locator("[data-wiztroopmore]:not([disabled])").count():
        pg.locator("[data-wiztroopmore]:not([disabled])").first.click(); pg.wait_for_timeout(400)
        took=len(pg.evaluate("()=>SIM_WIZ.startTroops"))
        ck("a Troop can be taken", took==1, str(took))
        ck("and shows as taken", pg.locator(".wizrow.on").count()>=1)
    for _ in range(2): pg.locator("#wizNext").click(); pg.wait_for_timeout(500)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(1500)

    S=lambda e: pg.evaluate("()=>"+e)
    ck("a combat starts on Your turn", S("SIM.phase")=="turn", S("SIM.phase"))
    ck("the Starting Troop is on the board",
       S("SIM.units.filter(function(u){return u.side==='ally';}).length")==1+took)
    ck("the built-in arenas field a sane wave",
       S("simEnemiesLeft()")<=3, S("simEnemiesLeft()"))

    # ---- the tracker ----
    ck("the phases are the Handbook's order",
       S("SIM_PHASES.map(function(p){return p.k;})")==
         ["waves","gen","chips","draw","recharge","turn","enemy"])
    ck("the tracker is on screen", pg.locator("#simphases .simph").count()==7)
    ck("with the current phase lit", pg.locator("#simphases .simph.on").inner_text()=="YOUR TURN")
    ck("and the button says what it does", pg.locator("#simEnd").inner_text()=="End turn",
       pg.locator("#simEnd").inner_text())

    # ---- Movement is a budget for the turn ----
    r=pg.evaluate("""()=>{
      var Rr=window.KETER_RULES;
      var u=SIM.units.filter(function(x){return x.side==='ally'&&/hero/i.test(x.cardType||'');})[0];
      var ms=Rr.effective(u).ms, steps=[];
      for(var n=0;n<4;n++){
        simSelect(u);
        var reach=(SIM.reach||[]);
        var t=reach[reach.length-1];
        if(!t){ steps.push({reach:0}); break; }
        steps.push({ok:simMoveTo(u,t.q,t.r), cost:t.cost, moved:u.moved});
      }
      return {ms:ms, steps:steps, moved:u.moved};
    }""")
    ck("a Unit never moves further than its Movement Speed", r["moved"]<=r["ms"], str(r))
    ck("and re-selecting does not refill it",
       any(s.get("reach")==0 for s in r["steps"]) or r["moved"]<=r["ms"], str(r))
    ck("what is left is what it can reach",
       S("""(function(){ var Rr=window.KETER_RULES;
         var u=SIM.units.filter(function(x){return x.side==='ally'&&/hero/i.test(x.cardType||'');})[0];
         simSelect(u);
         var left=Rr.effective(u).ms-(u.moved||0);
         return (SIM.reach||[]).every(function(t){ return t.cost<=left; }); })()"""))

    # ---- refusals that say something ----
    n0=S("SIM.log.length")
    pg.evaluate("""()=>{
      var u=SIM.units.filter(function(x){return x.side==='ally';})[0];
      var foe=SIM.units.filter(function(x){return x.side==='enemy';})[0];
      simAttack(u,foe);
    }""")
    pg.wait_for_timeout(300)
    ck("an impossible attack explains itself", S("SIM.log.length")>n0,
       S("SIM.log[SIM.log.length-1].text"))

    # ---- undo takes the phase back ----
    before=S("JSON.stringify(SIM.units.map(function(u){return u.pos;}))")
    pg.locator("#simEnd").click(); pg.wait_for_timeout(900)
    if pg.locator("#simGoBtn").is_visible():
        ck("ending a turn with movement left warns first", True)
        pg.locator("#simGoBtn").click(); pg.wait_for_timeout(1400)
    else:
        ck("ending a turn with movement left warns first", S("SIM.phase")!="enemy",
           "advanced without asking")
    ck("the Enemy phase steps one Enemy at a time",
       pg.locator("#simEnd").inner_text().startswith("Enemy "), pg.locator("#simEnd").inner_text())
    ck("Undo names the phase it would take back",
       pg.locator("#simUndo").inner_text().startswith("Undo "), pg.locator("#simUndo").inner_text())
    pg.locator("#simUndo").click(); pg.wait_for_timeout(700)
    ck("undoing a phase puts the fight back", S("SIM.phase")=="turn", S("SIM.phase"))
    ck("and restores where everyone stood",
       S("JSON.stringify(SIM.units.map(function(u){return u.pos;}))")==before)

    # ---- only Your turn allows acting ----
    pg.evaluate("()=>{ SIM.phase='draw'; renderSim(); }")
    ck("another phase blocks moving", S("simCanAct()")==False)
    ck("and selecting shows no reach",
       S("""(function(){ var u=SIM.units.filter(function(x){return x.side==='ally';})[0];
             simSelect(u); return (SIM.reach||[]).length===0; })()"""))
    pg.evaluate("()=>{ SIM.phase='turn'; renderSim(); }")

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"PHASES PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
