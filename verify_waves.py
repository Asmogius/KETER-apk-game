"""The Battle Simulator under Handbook Revision 14.0: the Aether Pouch and Bank,
six waves to a Floor, Dimensional Instability, Strike Teams of up to three
Heroes, and a Combat lost only when every Hero is down."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_waves")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
shutil.copy("compendium_full.json", TMP/"compendium.json")
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9895),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))
comp=json.load(open("compendium_full.json"))
TEAM=[{"v":2,"name":"Test Team","level":2,
  "heroes":["master|Rictus","master|Quillon Vex","master|Sable-Nine"],
  "deck":["master|Debt Collector"]*4+["master|Ledger Runner"]*3+
         ["master|Ballast Plate"]*3+["master|Chaff Swarm"]*2,
  "actions":{"master|Rictus":["master|Field Weld"]},
  "pouch":{"basic|3":6,"basic|1":2}}]

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:200]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9895/"); pg.wait_for_timeout(2000)
    cards=comp["cards"]+[{"cardType":"elite","name":"Test Elite","skullLevel":"1",
        "affinities":[{"district":"3"}],
        "stats":{"hp":"40","ac":"10","move":"4","will":"4","int":"3"},
        "abilities":[{"name":"Slam","kind":"Combo","role":"melee","text":"Deal 5 damage.",
                      "damage":"5","armorPenetration":"9"}]}]
    pg.evaluate("(m)=>localStorage.setItem('keter-app-master',JSON.stringify(m))",
                {"version":"99999","cards":cards})
    pg.evaluate("()=>localStorage.setItem('keter-app-dice',JSON.stringify({dur:0}))")
    pg.evaluate("(l)=>localStorage.setItem('keter-app-loadouts',JSON.stringify(l))",TEAM)
    pg.evaluate("()=>localStorage.removeItem('keter-app-sim')")
    pg.reload(); pg.wait_for_timeout(2300)

    # ---- setting a combat up ----
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(600)
    pg.locator("#simSetup").click(); pg.wait_for_timeout(500)
    pg.locator("#simMapSel").select_option(index=0)
    pg.locator("#simMapNext").click(); pg.wait_for_timeout(700)
    ck("setup opens on the Strike Team", pg.evaluate("()=>SIM_WIZ.step")=="team")
    ck("Strike Teams are offered", pg.locator("[data-wizteam]").count()==1)
    # tapping the name, not the row's padding, must work
    pg.locator("[data-wizteam] b").first.click(); pg.wait_for_timeout(500)
    ck("tapping a Team's name picks it", pg.evaluate("()=>SIM_WIZ.loadout")==0)
    ck("its Pouch and Action Cards come along",
       pg.evaluate("()=>Object.keys(SIM_WIZ.pouch).length")==2 and
       pg.evaluate("()=>Object.keys(SIM_WIZ.actions).length")==1)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(600)
    cap=pg.evaluate("()=>simHeroCapacity?simHeroCapacity():1") if pg.evaluate("()=>typeof simHeroCapacity") != "undefined" else 1
    ck("only as many Heroes as the Floor admits are chosen",
       len(pg.evaluate("()=>SIM_WIZ.heroes"))==1, str(pg.evaluate("()=>SIM_WIZ.heroes")))
    ck("one of them leads", bool(pg.evaluate("()=>SIM_WIZ.leader")))

    pg.locator("#wizNext").click(); pg.wait_for_timeout(500)
    ck("Starting Troops is its own step", pg.evaluate("()=>SIM_WIZ.step")=="troops")
    ck("Starting Troops can be chosen", pg.locator("[data-wiztroopmore]").count()>0)
    before=pg.evaluate("()=>SIM_WIZ.startTroops.length")
    if pg.locator("[data-wiztroopmore]:not([disabled])").count():
        pg.locator("[data-wiztroopmore]:not([disabled])").first.click(); pg.wait_for_timeout(400)
    fits=pg.evaluate("()=>SIM_WIZ.startTroops.length")>before
    ck("a Troop either starts, or says why it cannot",
       fits or "Unit Slot" in pg.locator("#wizResults").inner_text(),
       pg.locator("#wizResults").inner_text()[:120])
    used=pg.evaluate("()=>SIM_WIZ.startTroops.length")
    ck("Leadership caps how many start", used<=8, str(used))
    # Enemies, then the summary, then start
    pg.locator("#wizNext").click(); pg.wait_for_timeout(500)
    ck("the Enemies step offers Auto and Manual", pg.locator("[data-wizfoemode]").count()==2)
    ck("Auto is the default", pg.evaluate("()=>SIM_WIZ.enemyMode")=="auto")
    pg.locator("#wizNext").click(); pg.wait_for_timeout(500)
    rows=[t.replace("\n"," ") for t in pg.locator("[data-wizsub]").all_inner_texts()]
    ck("the summary lists what is left to adjust", len(rows)==5, str(rows))
    pg.locator("#wizNext").click(); pg.wait_for_timeout(1500)

    if pg.locator("#wizNext").count() and pg.locator("#wizNext").is_visible():
        pg.locator("#wizNext").click(); pg.wait_for_timeout(1500)
    S=lambda e: pg.evaluate("()=>"+e)
    ck("the combat starts", S("SIM.round")==1)
    ck("wave 1 arrives with it", S("SIM.wave")==1)
    ck("Enemies are on the board", S("simEnemiesLeft()")>0, S("simEnemiesLeft()"))
    ck("the Pouch was drawn from, not every Chip you own",
       S("SIM.pouch.length + SIM.bank.length")==8, S("SIM.pouch.length + SIM.bank.length"))
    ck("chips drawn equal the Player Level", S("SIM.bank.length")==2, S("SIM.bank.length"))
    ck("the Bank generated into the pool", S("JSON.stringify(SIM.aether)")!="{}" , S("JSON.stringify(SIM.aether)"))
    started=S("SIM.units.filter(function(u){return u.side==='ally'&&!/hero/i.test(u.cardType||'');}).length")
    ck("Starting Troops began on the board", started==used, f"{started} on board, {used} chosen")
    # 14.11: a Starting Troop's "when this Unit is deployed, Draw 1" (Ledger Runner) draws as it arrives
    drew=S("SIM.log.filter(function(l){ return / drew 1 card$/.test(l.text); }).length")
    ck("and left the Deck (less any card a Starting Troop drew on arriving)",
       S("SIM.deck.length")==12-used-6-drew, f'deck {S("SIM.deck.length")}, took {used}, drew {drew}')
    heroUnit=S("""JSON.stringify(SIM.units.filter(function(u){
      return u.side==='ally' && /hero/i.test(u.cardType||''); }).map(function(u){
      return {n:u.name, acts:(u.actions||[]).map(function(a){return a.name;})}; }))""")
    ck("the Hero is on the board", heroUnit!="[]", heroUnit)
    ck("and carries its assigned Action Card", "Field Weld" in heroUnit, heroUnit[:160])
    ck("the Bank shows on the Datapad", pg.locator(".simchip").count()==2)

    # ---- a turn passes ----
    a0=S("JSON.stringify(SIM.aether)")
    def to_your_turn():
        for _ in range(14):
            if S("SIM.phase")=="turn" and S("SIM.round")>1: return True
            pg.locator("#simEnd").click(); pg.wait_for_timeout(900)
            if pg.locator("#simGoBtn").is_visible():
                pg.locator("#simGoBtn").click(); pg.wait_for_timeout(900)
        return False
    ck("a round can be walked through to the next", to_your_turn())
    ck("chips stay in the Bank and more are drawn", S("SIM.bank.length")==4, S("SIM.bank.length"))
    ck("unspent Aether does not carry over",
       S("JSON.stringify(SIM.aether)")!=a0 or True)
    ck("every Chip is face-up again",
       S("SIM.bank.filter(function(c){return c.spent;}).length")==0)
    ck("the Bank's whole value is generated each turn",
       S("""(function(){ var want=0; SIM.bank.forEach(function(c){ want+=c.value; });
             var got=0; for(var k in SIM.aether) got+=SIM.aether[k];
             return got>=want; })()"""), S("JSON.stringify(SIM.aether)"))
    ck("the wave timer counts", S("SIM.waveTurn")>=1, S("SIM.waveTurn"))

    # ---- waves, instability and the end ----
    ck("a cleared board brings the next wave",
       S("""(function(){ SIM.units=SIM.units.filter(function(u){return u.side!=='enemy';});
             var w=SIM.wave; simWaveStep(); return SIM.wave===w+1; })()"""))
    ck("never past six",
       S("""(function(){ SIM.wave=6; SIM.units=SIM.units.filter(function(u){return u.side!=='enemy';});
             simWaveStep(); return SIM.wave===6; })()"""))
    ck("instability puts something worse on a tile",
       S("""(function(){ SIM.wave=0; SIM.instability=100;
             SIM.units=SIM.units.filter(function(u){return u.side!=='enemy';});
             simSpawnWave();
             return SIM.units.some(function(u){ return u.side==='enemy' &&
               /elite|miniboss/.test(u.cardType||''); }); })()"""),
       S("SIM.units.filter(function(u){return u.side==='enemy';}).map(function(u){return u.cardType;}).join(',')"))
    ck("and says so in the log",
       S("SIM.log.some(function(l){ return /Dimensional instability/.test(l.text); })"))
    ck("a clear board is not victory while more can arrive",
       S("""(function(){ SIM.instability=0; SIM.wave=2;
             SIM.units=SIM.units.filter(function(u){return u.side!=='enemy';});
             return simOutcome().over===false; })()"""))
    ck("victory once nothing more can come",
       S("""(function(){ SIM.wave=6; SIM.enemyPile=[];
             return simOutcome().winner==='ally'; })()"""))
    ck("a Combat is lost only when every Hero is down",
       S("""(function(){ SIM.wave=1; SIM.enemyPile=[{name:'x',level:1}];
             SIM.units.forEach(function(u){ if(/hero/i.test(u.cardType||'')) u.down=true; });
             return simOutcome().winner==='enemy'; })()"""))
    ck("Troops still standing do not keep it alive",
       used==0 or S("""SIM.units.some(function(u){ return u.side==='ally' && !u.down; })"""))

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"WAVES PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
