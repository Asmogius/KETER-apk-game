"""Simulator interface: layout, the ticker, tabs, inspection and card sheets."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_simui")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
shutil.copy("compendium_full.json", TMP/"compendium.json")
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9911),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))
comp=json.load(open("compendium_full.json"))

def start(pg, foes=2):
    pg.locator("#simSetup").click(); pg.wait_for_timeout(600)
    pg.locator("#simMapSel").select_option(index=0)
    pg.locator("#simMapNext").click(); pg.wait_for_timeout(600)
    # Handbook 14.0 setup: Strike Team, then who enters, then the Enemies
    pg.locator("[data-wizteam] b").first.click(); pg.wait_for_timeout(450)
    # Heroes, then Starting Troops, then the Enemies
    pg.locator("#wizNext").click(); pg.wait_for_timeout(450)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(450)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(450)
    pg.locator('[data-wizfoemode="manual"]').click(); pg.wait_for_timeout(350)
    for _ in range(foes):
        pg.locator('[data-wizfoemore]').first.click(); pg.wait_for_timeout(180)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(500)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(1300)

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:200]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9911/"); pg.wait_for_timeout(2100)
    pg.evaluate("(m)=>localStorage.setItem('keter-app-master',JSON.stringify(m))",
                {"version":"99999","cards":comp["cards"]})
    pg.evaluate("()=>localStorage.setItem('keter-app-dice',JSON.stringify({dur:0}))")
    pg.evaluate("()=>{localStorage.removeItem('keter-app-loadouts');"
                "localStorage.removeItem('keter-app-sim');}")
    pg.reload(); pg.wait_for_timeout(2300)
    pg.locator('.lt[data-page="deck"]').click(); pg.wait_for_timeout(700)
    pg.evaluate("""()=>{ var d=["Debt Collector","Debt Collector","Ledger Runner","Chaff Swarm","Whisper Coil","Whisper Coil","Call the Note","Call the Note","Ledger Call","Recall","Whisper Coil","Hold the Line","HALO targeting System","Ballast Plate","Tighten Ranks"].map(function(n){return "master|"+n;}); var lo=JSON.parse(localStorage.getItem("keter-app-loadouts")||"[]"); lo.push({v:2,name:"Collections",level:1,heroes:["master|Quillon Vex"],deck:d,actions:{},pouch:{"basic|3":6}}); localStorage.setItem("keter-app-loadouts",JSON.stringify(lo)); }"""); pg.wait_for_timeout(200)
    pg.evaluate("()=>{var m=document.getElementById('modal'); if(m) m.classList.remove('on');}")
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(400)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(800)

    # ---- the top bar ----
    shown = pg.evaluate("""()=>[].slice.call(document.querySelectorAll('#simtop button'))
      .filter(function(b){return b.getBoundingClientRect().width>0 &&
                                 !b.classList.contains('pghelp');})
      .map(function(b){return b.id;})""")
    ck("before a combat, only setup and settings are offered",
       shown==["simSetup","simGear"], str(shown))
    start(pg)
    shown = pg.evaluate("""()=>[].slice.call(document.querySelectorAll('#simtop button'))
      .filter(function(b){return b.getBoundingClientRect().width>0 &&
                                 !b.classList.contains('pghelp');})
      .map(function(b){return b.id;})""")
    ck("during a combat, setup is put away",
       "simSetup" not in shown, str(shown))
    ck("and the turn controls are there",
       set(shown)=={"simUndo","simEnd","simAuto","simGear"}, str(shown))
    wrapped = pg.evaluate("""()=>[].slice.call(document.querySelectorAll('#simtop button'))
      .filter(function(b){return b.getBoundingClientRect().height>44;})
      .map(function(b){return b.id;})""")
    ck("no button label wraps onto two lines", wrapped==[], str(wrapped))
    w = pg.evaluate("""()=>Math.round(document.getElementById('simEnd')
      .getBoundingClientRect().width)""")
    ck("buttons are wide enough to tap", w>=90, str(w))

    # ---- the ticker ----
    ck("the ticker is showing",
       pg.evaluate("()=>document.getElementById('simticker').classList.contains('on')"))
    ck("and carries the last thing that happened",
       len(pg.evaluate("()=>document.getElementById('simticker').textContent"))>4,
       pg.evaluate("()=>document.getElementById('simticker').textContent"))

    # ---- the hand is on the board, as cards ----
    # a selected Unit shows its actions instead, so deselect first
    pg.evaluate("()=>{ simSelect(null); SIM_UI.handOpen=true; renderSim(); }"); pg.wait_for_timeout(300)
    r = pg.evaluate("""()=>{
      var fan=document.querySelector('#simdock .fan'); if(!fan) return null;
      var cards=[].slice.call(fan.querySelectorAll('[data-fan]'));
      var vw=window.innerWidth, vh=window.innerHeight;
      return {cards:cards.length,
              onScreen:cards.every(function(c){ var r=c.getBoundingClientRect();
                return r.top<vh && r.bottom>0 && r.left>=0 && r.right<=vw; })};
    }""")
    ck("the hand shows as cards on the board", r and r["cards"]>0, str(r))
    ck("and every card is fully within the screen's width", r and r["onScreen"] is True, str(r))

    # ---- the piles fit on one line ----
    ck("the Bank is shown on its own", pg.locator(".simbank").count()==1)
    ck("the piles are one line", pg.locator(".simpiles").count()==1)
    ck("and it names all four",
       all(w in pg.locator(".simpiles").inner_text() for w in
           ["Deck","Hand","Discard","Pouch"]),
       pg.locator(".simpiles").inner_text())

    # ---- tabs ----
    ck("there are two tabs", pg.locator("[data-simtab]").count()==2)
    ck("the fight is showing first", pg.evaluate("()=>SIM.tab")=="fight")
    pg.locator('[data-simtab="log"]').click(); pg.wait_for_timeout(500)
    ck("the log tab opens", pg.evaluate("()=>SIM.tab")=="log")
    ck("and it has entries", pg.locator(".simlog div").count()>0,
       pg.locator(".simlog div").count())
    ck("newest first",
       "Drew" in pg.locator(".simlog div").first.inner_text() or
       "generated" in pg.locator(".simlog div").first.inner_text(),
       pg.locator(".simlog div").first.inner_text()[:50])
    pg.locator('[data-simtab="fight"]').click(); pg.wait_for_timeout(400)
    ck("and back again", pg.evaluate("()=>SIM.tab")=="fight")
    pg.locator("#simticker").click(); pg.wait_for_timeout(500)
    ck("tapping the ticker opens the log", pg.evaluate("()=>SIM.tab")=="log")
    pg.locator('[data-simtab="fight"]').click(); pg.wait_for_timeout(400)

    # ---- inspecting a Unit ----
    pg.evaluate("()=>{ simSelect(SIM.units.filter(function(u){return u.side==='ally';})[0]); }")
    pg.wait_for_timeout(500)
    ck("a selected Unit opens up", pg.locator(".cbdetail").count()==1)
    d = pg.locator(".cbdetail").inner_text()
    ck("its stats are there", "AC" in d and "MS" in d and "NRG" in d, d[:80])
    ck("and its Actions, with what they do",
       pg.locator(".sdact").count()>=1 and "dmg" in d, d[:140])
    pg.evaluate("()=>{ simSelect(null); }")
    pg.wait_for_timeout(400)
    ck("deselecting closes it", pg.locator(".cbdetail").count()==0)

    # ---- a card is read before it is played ----
    pg.evaluate("()=>{ simSelect(null); SIM_UI.handOpen=true; SIM.aether={generic:99,d3:99}; SIM_UI.raised=null; renderSim(); }")
    pg.wait_for_timeout(300)
    hand_before = pg.evaluate("()=>SIM.hand.length")
    pi = pg.evaluate("""()=>{ for(var i=0;i<SIM.hand.length;i++){ var t=SIM.hand[i].type;
        /* 14.11: Recall is a Recover now, and with no Troop's card in the Discard Pile it cannot be played */
        var rec=(SIM.hand[i].effects||[]).some(function(e){ return /\[\[Recover\]\]/.test(e.text||''); });
        if(t!=='equipment' && t!=='troop' && !rec) return i; } return 0; }""")
    pg.locator(f'[data-fan="{pi}"]').click(position={"x":16,"y":70}); pg.wait_for_timeout(400)
    ck("tapping a card raises it rather than playing it",
       pg.evaluate("()=>SIM.hand.length")==hand_before and
       pg.locator(f'[data-fan="{pi}"]').evaluate("e=>e.classList.contains('up')"))
    ck("the raised card says a second tap plays it", "Tap again" in pg.locator(".fcue").inner_text())
    # each card is overlapped by the one to its right, so its left edge shows
    nx=(pi+1)%hand_before
    pg.locator(f'[data-fan="{nx}"]').click(position={"x":16,"y":70}); pg.wait_for_timeout(300)
    ck("tapping another card raises that one instead",
       pg.evaluate(f"()=>SIM_UI.raised==={nx}"), pg.evaluate("()=>SIM_UI.raised"))
    lf=pg.evaluate("()=>SIM.log.length")
    pg.evaluate(f"()=>{{ SIM_UI.raised={pi}; SIM_UI.lastDock=null; renderSim(); }}"); pg.wait_for_timeout(300)
    pg.locator(f'[data-fan="{pi}"]').click(); pg.wait_for_timeout(700)
    if pg.evaluate("()=>!!SIM.pick"):
        pg.evaluate("""()=>{ var pk=SIM.pick, k=Object.keys(pk.valid)[0];
          var t=SIM.units.filter(function(u){return u.id===pk.valid[k];})[0]; SIM.pick=null; pk.done(t); }""")
        pg.wait_for_timeout(500)
    if pg.evaluate("()=>!!SIM.aim"):
        pg.evaluate("()=>{ SIM.aim.at={q:0,r:0}; simConfirmAim(); }"); pg.wait_for_timeout(500)
    # 14.11: a card that Draws puts cards back in the hand, so count what was drawn too
    drawn=pg.evaluate("(lf)=>SIM.log.slice(lf).reduce(function(n,l){ var m=/: drew (\\d+) card/.exec(l.text); return n+(m?+m[1]:0); },0)", lf)
    ck("a second tap plays it",
       pg.evaluate("()=>SIM.hand.length")-drawn<hand_before, [pg.evaluate("()=>SIM.hand.length"), drawn])

    # a card you cannot pay for says so, and a second tap does not play it
    pg.evaluate("()=>{ SIM.aether={}; SIM_UI.raised=null; renderSim(); }")
    pg.wait_for_timeout(300)
    idx = pg.evaluate("""()=>{
      for(var i=0;i<SIM.hand.length;i++) if(!simCanPlay(SIM.hand[i])) return i;
      return -1; }""")
    if idx>=0:
        n=pg.evaluate("()=>SIM.hand.length")
        pg.evaluate(f"()=>{{ SIM_UI.raised={idx}; SIM_UI.lastDock=null; renderSim(); }}"); pg.wait_for_timeout(300)
        ck("an unaffordable card explains itself",
           "Needs" in pg.locator(".fcue").inner_text(), pg.locator(".fcue").inner_text())
        pg.locator(f'[data-fan="{idx}"]').click(); pg.wait_for_timeout(300)
        ck("and offers no way to play it", pg.evaluate("()=>SIM.hand.length")==n)
        pg.evaluate("()=>{ SIM_UI.raised=null; renderSim(); }")

    # ---- board labels ----
    ck("Unit labels are three characters", pg.evaluate("""()=>{
      var n=SIM.units[0].name;
      return n.replace(/[^A-Za-z0-9]/g,'').slice(0,3).length===3;
    }"""))

    # ---- starting over asks first ----
    pg.evaluate("()=>{ SIM.aether={generic:99,d3:99}; renderSim(); }")
    pg.locator("#simGear").click(); pg.wait_for_timeout(600)
    ck("Settings offers a new combat", pg.locator("#simNewCombat").count()==1)
    pg.locator("#simNewCombat").click(); pg.wait_for_timeout(500)
    ck("which asks before throwing the fight away",
       pg.locator("#simNewYes").count()==1 and pg.locator("#simNewNo").count()==1)
    units_before = pg.evaluate("()=>SIM.units.length")
    pg.locator("#simNewNo").click(); pg.wait_for_timeout(500)
    ck("declining keeps the combat",
       pg.evaluate("()=>SIM.units.length")==units_before)
    pg.evaluate("()=>{var m=document.getElementById('modal'); if(m) m.classList.remove('on');}")

    # ---- the acting Unit is marked during the Enemy phase ----
    pg.evaluate("""()=>{
      var h=SIM.units.filter(function(u){return u.side==='ally';})[0];
      var e=SIM.units.filter(function(u){return u.side==='enemy';})[0];
      e.pos={q:h.pos.q+1,r:h.pos.r};
    }""")
    # sample repeatedly rather than at one moment: a Unit that cannot reach
    # anything finishes in a few hundred milliseconds
    # Ending a turn with movement left asks first now, so answer it, then watch
    # the Enemy phase: each Enemy acts on its own tap and stays marked after.
    pg.locator("#simEnd").click(); pg.wait_for_timeout(600)
    if pg.locator("#simGoBtn").is_visible():
        pg.locator("#simGoBtn").click()
    pg.wait_for_timeout(2500)
    ck("the acting Unit is marked while it acts",
       bool(pg.evaluate("()=>SIM.acting")), pg.evaluate("()=>SIM.acting"))
    for _ in range(8):
        if pg.evaluate("()=>SIM.phase")!="enemy": break
        pg.locator("#simEnd").click(); pg.wait_for_timeout(900)
    ck("and the mark is cleared once the Enemies are done",
       pg.evaluate("()=>!SIM.acting") is True, pg.evaluate("()=>SIM.acting"))
    ck("the result is still on screen, not flashed away",
       len(pg.evaluate("()=>document.getElementById('simticker').textContent"))>4,
       pg.evaluate("()=>document.getElementById('simticker').textContent"))

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"SIM UI PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
