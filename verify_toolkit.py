"""The shared tool code, and help mode in the shell."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_toolkit")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
shutil.copy("compendium_full.json", TMP/"compendium.json")
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9961),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))
comp=json.load(open("compendium_full.json"))

SHARED=["download","keterUser","stampAuthor","confirmBox","promptBox",
        "safeFile","setStatus","flash","buildHelpBoxes"]

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:200]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9961/"); pg.wait_for_timeout(2200)

    # ---- one source, injected into both tools ----
    for tool,view,default in (("forge","v-forge","KETER_card"),
                              ("poi","v-poi","KETER_map")):
        pg.locator(f"#nav button[data-go='{tool}']").click(); pg.wait_for_timeout(3200)
        W=f"document.querySelector('#{view} iframe').contentWindow"
        r = pg.evaluate(f"""()=>{{
          var w={W};
          return {{
            cfg: w.KETER_TOOL ? w.KETER_TOOL.defaultFile : null,
            missing: {json.dumps(SHARED)}.filter(function(n){{
              return typeof w[n]!=='function'; }}),
            named: w.safeFile('My Card'),
            fallback: w.safeFile(''),
            hasFlashHook: !!(w.KETER_TOOL && typeof w.KETER_TOOL.onFlash==='function')
          }};
        }}""")
        ck(f"{tool} has every shared function", r["missing"]==[], str(r["missing"]))
        ck(f"{tool} keeps its own file default", r["fallback"]==default, str(r))
        ck(f"{tool} still sanitises a given name",
           r["named"]=="My_Card", str(r["named"]))
        ck(f"{tool} declares how it redraws", r["hasFlashHook"] is True)

        # the help overlay still works in the tool
        D=f"document.querySelector('#{view} iframe').contentDocument"
        pg.evaluate(f"()=>{{var h={D}.getElementById('hud-help'); if(h) h.click();}}")
        pg.wait_for_timeout(1000)
        n=pg.evaluate(f"()=>{D}.querySelectorAll('.help-box').length")
        ck(f"{tool} help mode still draws boxes", n>5, str(n))
        pg.evaluate(f"()=>{{var h={D}.getElementById('hud-help'); if(h) h.click();}}")
        pg.wait_for_timeout(400)

    # the five that only share a name are left alone
    r = pg.evaluate("""()=>{
      var f=document.querySelector('#v-forge iframe').contentWindow;
      var p=document.querySelector('#v-poi iframe').contentWindow;
      return ['computePings','computeChecklist','renderSlots','renderDocks','snapshot']
        .map(function(n){
          return {n:n, differ: (typeof f[n]==='function' && typeof p[n]==='function')
            ? String(f[n])!==String(p[n]) : null};
        });
    }""")
    for row in r:
        if row["differ"] is not None:
            ck(f"{row['n']} is left as two different functions", row["differ"] is True)

    # ---- help mode in the shell ----
    pg.evaluate("(m)=>localStorage.setItem('keter-app-master',JSON.stringify(m))",
                {"version":"99999","cards":comp["cards"]})
    pg.evaluate("()=>localStorage.setItem('keter-app-dice',JSON.stringify({dur:0}))")
    pg.evaluate("()=>localStorage.removeItem('keter-app-loadouts')")
    pg.reload(); pg.wait_for_timeout(2300)
    ck("the shell has a help layer", pg.locator("#helpLayer").count()==1)
    ck("there is no floating help button any more",
       pg.locator("#helpBtn").count()==0)
    ck("the first-run tip is gone", pg.locator("#nudge").count()==0)

    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(500)
    pg.locator('.lt[data-page="deck"]').click(); pg.wait_for_timeout(800)
    ck("the Deck Builder has a ? in its own header",
       pg.locator("#v-deck .pghelp").is_visible())
    pg.locator("#v-deck .pghelp").click(); pg.wait_for_timeout(700)
    ck("help mode turns on",
       pg.evaluate("()=>document.getElementById('helpLayer').classList.contains('on')"))
    ck("and boxes the labelled controls", pg.locator(".help-box").count()>=2,
       pg.locator(".help-box").count())
    pg.locator(".help-box").first.click(); pg.wait_for_timeout(500)
    pop = pg.evaluate("""()=>{var h=document.getElementById('helpPop');
      return h.style.display!=='none' ? h.innerText : '';}""")
    ck("tapping a box explains that control", len(pop)>20, pop[:60])
    ck("the explanation has a heading and a body",
       pg.locator("#helpPop h4").count()==1 and pg.locator("#helpPop p").count()==1)
    pg.locator(".help-box").first.click(); pg.wait_for_timeout(400)
    ck("tapping the same control again closes it",
       pg.evaluate("()=>document.getElementById('helpPop').style.display")=="none")
    pg.locator("#helpExit").click(); pg.wait_for_timeout(400)
    ck("Done leaves help mode",
       not pg.evaluate("()=>document.getElementById('helpLayer').classList.contains('on')"))
    ck("and the boxes are cleared", pg.locator(".help-box").count()==0)

    # it follows you to the Simulator, and covers more once a fight is on
    pg.evaluate("""()=>{ var d=["Debt Collector","Debt Collector","Ledger Runner","Chaff Swarm","Whisper Coil","Whisper Coil","Call the Note","Call the Note","Ledger Call","Recall","Whisper Coil","Hold the Line","HALO targeting System","Ballast Plate","Tighten Ranks"].map(function(n){return "master|"+n;}); var lo=JSON.parse(localStorage.getItem("keter-app-loadouts")||"[]"); lo.push({v:2,name:"Collections",level:1,heroes:["master|Quillon Vex"],deck:d,actions:{},pouch:{"basic|3":6}}); localStorage.setItem("keter-app-loadouts",JSON.stringify(lo)); }"""); pg.wait_for_timeout(200)
    pg.evaluate("()=>{var m=document.getElementById('modal'); if(m) m.classList.remove('on');}")
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(400)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(700)
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
    pg.locator('[data-wizfoemore]').first.click(); pg.wait_for_timeout(200)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(500)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(1200)
    pg.locator("#v-battle .pghelp").click(); pg.wait_for_timeout(700)
    ck("the Simulator's controls are labelled", pg.locator(".help-box").count()>=5,
       pg.locator(".help-box").count())

    # leaving the page drops help rather than leaving stale boxes
    ck("help is still on before changing page",
       pg.evaluate("()=>document.getElementById('helpLayer').classList.contains('on')"))
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(600)
    ck("changing page leaves help mode",
       not pg.evaluate("()=>document.getElementById('helpLayer').classList.contains('on')"))

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"TOOLKIT PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
