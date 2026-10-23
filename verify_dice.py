"""The Dice page and dice in a fight: d20s and d6s, several at once with a
total, a tumble of a length you set, a quiet mark on a 20 or a 1, and the
tumble in the top-right of the board for both sides' rolls \u2014 except in
auto-battle, which stays instant."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_dice")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9967),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))
comp=json.load(open("compendium_full.json"))
TEAM=[{"v":2,"name":"T","level":2,"heroes":["master|Quillon Vex"],"deck":["master|Aether Bolt"]*10,"actions":{},"pouch":{"basic|3":6}}]
with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.goto("http://127.0.0.1:9967/"); pg.wait_for_timeout(1900)
    pg.evaluate("(m)=>localStorage.setItem('keter-app-master',JSON.stringify(m))",{"version":"99999","cards":comp["cards"]})
    pg.evaluate("(l)=>localStorage.setItem('keter-app-loadouts',JSON.stringify(l))",TEAM)
    pg.evaluate("()=>{ localStorage.removeItem('keter-app-dice'); localStorage.removeItem('keter-app-sim'); }")
    pg.reload(); pg.wait_for_timeout(2200)

    # ---- the page ----
    ck("the Dice tile is built, not a placeholder",
       pg.locator('[data-page="dice"]').evaluate("e=>!e.classList.contains('wip')"))
    pg.locator('[data-page="dice"]').click(); pg.wait_for_timeout(500)
    ck("it opens the Dice page", pg.locator("#v-dice.on").count()==1)
    ck("d20 is chosen first, and shows it", pg.locator('[data-dicedie="d20"].on').count()==1)
    ck("the tumble lasts two seconds by default", pg.evaluate("()=>diceSettings().dur")==2000)
    for _ in range(12): pg.locator("#diceMore").click()
    ck("up to ten at once", pg.locator("#diceN").inner_text()=="10")
    for _ in range(12): pg.locator("#diceLess").click()
    ck("and never fewer than one", pg.locator("#diceN").inner_text()=="1")
    for _ in range(2): pg.locator("#diceMore").click()
    pg.locator("#diceRoll").click(); pg.wait_for_timeout(500)
    ck("rolling tumbles the dice", pg.locator("#diceTray .die.tumbling").count()==3)
    ck("and holds the button until they land", pg.locator("#diceRoll").is_disabled())
    pg.wait_for_timeout(2300)
    ck("they settle", pg.locator("#diceTray .die.settled").count()==3 and
       pg.locator("#diceTray .die.tumbling").count()==0)
    faces=[int(x) for x in pg.locator("#diceTray .dienum").evaluate_all("els=>els.map(e=>e.textContent)")]
    ck("each lands on a d20 face", len(faces)==3 and all(1<=f<=20 for f in faces), faces)
    ck("and the total is their sum", pg.locator("#diceTotal").inner_text()=="Total "+str(sum(faces)),
       pg.locator("#diceTotal").inner_text())
    ck("the button is back", not pg.locator("#diceRoll").is_disabled())
    pg.locator('[data-dicedie="d6"]').click(); pg.wait_for_timeout(200)
    pg.evaluate("()=>{ diceSaveSettings({dur:0}); }")
    pg.locator("#diceLess").click(); pg.locator("#diceLess").click()
    pg.locator("#diceRoll").click(); pg.wait_for_timeout(200)
    ck("a length of nothing rolls instantly", pg.locator("#diceTray .die.settled").count()==1 and
       pg.locator("#diceTray .die.tumbling").count()==0)
    ck("a single die shows no total", pg.locator("#diceTotal").inner_text()=="")
    pips=pg.locator("#diceTray .diepip").count()
    ck("a d6 lands with one to six pips", 1<=pips<=6, pips)
    pg.evaluate("()=>diceSaveSettings({dur:2000})")

    # ---- the quiet mark on a 20 or a 1 ----
    r=pg.evaluate("""()=>{ var h=document.createElement('div'); document.body.appendChild(h);
      var out={}; diceTumble(h,{die:'d20',values:[20,1,10],dur:0});
      out.d20=[].map.call(h.querySelectorAll('.die'),function(e){return (e.classList.contains('top')?'top':'')+(e.classList.contains('low')?'low':'');});
      diceTumble(h,{die:'d6',values:[6,1,3],dur:0});
      out.d6=[].map.call(h.querySelectorAll('.die'),function(e){return (e.classList.contains('top')?'top':'')+(e.classList.contains('low')?'low':'');});
      h.remove(); return out; }""")
    ck("a 20 and a 1 are marked, anything else is not", r["d20"]==["top","low",""], r["d20"])
    ck("on a d6 it is a 6 and a 1", r["d6"]==["top","low",""], r["d6"])
    ck("the setting is kept", pg.evaluate("()=>JSON.parse(localStorage.getItem('keter-app-dice')).dur")==2000)

    # ---- in a fight ----
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(400)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(500)
    pg.locator("#simSetup").click(); pg.wait_for_timeout(400)
    pg.locator("#simMapSel").select_option(index=0); pg.locator("#simMapNext").click(); pg.wait_for_timeout(600)
    pg.locator("[data-wizteam] b").first.click(); pg.wait_for_timeout(400)
    for _ in range(4): pg.locator("#wizNext").click(); pg.wait_for_timeout(450)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(2000)
    pg.evaluate("""()=>{ var h=SIM.units.filter(function(u){return u.side==='ally'&&/hero/i.test(u.cardType||'');})[0];
      var f=SIM.units.filter(function(u){return u.side==='enemy';})[0]; h.pos={q:0,r:0}; f.pos={q:1,r:-2}; h.nrg=4;
      var a=h.actions.filter(function(x){return x.tag!=='Passive';})[0];
      window._logN=SIM.log.length; simConfirmAttack(h,f,a); }""")
    pg.wait_for_timeout(700)
    ck("your attack's roll tumbles on the board", pg.locator("#simDiceLayer").count()==1)
    ck("saying who rolls, for what, and what is needed",
       "rolls to" in pg.locator(".simdicelabel").inner_text() and "needs" in pg.locator(".simdicelabel").inner_text(),
       pg.locator(".simdicelabel").inner_text())
    box=pg.locator(".simdicebox").bounding_box(); board=pg.locator("#simboard").bounding_box()
    ck("in the top-right corner", box["x"]+box["width"]>board["x"]+board["width"]-30 and box["y"]<board["y"]+40, str(box))
    ck("narrow enough to leave most of the fight in view", box["width"]<board["width"]*0.45, box["width"])
    ck("the zoom buttons step aside meanwhile",
       pg.evaluate("()=>document.getElementById('simZoomBar').style.visibility")=="hidden")
    pg.wait_for_timeout(6500)
    ck("then it clears", pg.locator("#simDiceLayer").count()==0)
    ck("and the zoom buttons come back",
       pg.evaluate("()=>document.getElementById('simZoomBar').style.visibility")=="")
    lines=pg.evaluate("()=>SIM.log.slice(window._logN).map(function(l){return l.text;})")
    ck("the attack is logged once, not twice", len(lines)==len(set(lines)) and len(lines)>=1, lines)

    r=pg.evaluate("""()=>new Promise(function(res){
      var e=SIM.units.filter(function(u){return u.side==='enemy';})[0];
      SIM.autoRunning=false; var shown=false;
      simGetRoll({die:'d20',needed:10,label:e.name+' rolls to hit'},function(v){ res({enemy:shown, v:v}); });
      shown=!!document.getElementById('simDiceLayer');
    })""")
    ck("an Enemy's roll tumbles too", r["enemy"] is True)
    r=pg.evaluate("""()=>{ SIM.autoRunning=true; var got=null, shown=false;
      simGetRoll({die:'d20',needed:10,label:'x'},function(v){ got=v; });
      shown=!!document.getElementById('simDiceLayer'); SIM.autoRunning=false;
      return {got:got, shown:shown}; }""")
    ck("auto-battle rolls instantly, with no tumble", r["got"] is not None and r["shown"] is False, r)

    # ---- Manual dice can roll here ----
    pg.wait_for_timeout(3500)
    pg.evaluate("""()=>{ SIM.diceMode='manual'; window._manualV=null;
      simGetRoll({die:'d20',needed:11,label:'Test'},function(v){ window._manualV=v; }); }""")
    pg.wait_for_timeout(400)
    ck("Manual dice offer to roll here", pg.locator("#simRollAuto").inner_text()=="Roll it here")
    pg.locator("#simRollAuto").click(); pg.wait_for_timeout(500)
    ck("which tumbles on the board", pg.locator("#simDiceLayer").count()==1)
    pg.wait_for_timeout(3500)
    ck("and fills the answer in", 1<=(pg.evaluate("()=>window._manualV") or 0)<=20, pg.evaluate("()=>window._manualV"))
    pg.evaluate("()=>{ SIM.diceMode='auto'; }")

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"DICE PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
