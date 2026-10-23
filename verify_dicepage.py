"""The Dice Simulator is reachable from its tile and rolls. It was finished long
before it could be reached: the tile list still marked it "not built yet", so
the tile opened a placeholder."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_dicepage")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9967),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))
with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.goto("http://127.0.0.1:9967/"); pg.wait_for_timeout(2200)
    ck("the Dice tile is not marked as unbuilt",
       not pg.locator('.lt[data-page="dice"]').evaluate("e=>e.classList.contains('wip')"))
    pg.locator('.lt[data-page="dice"]').click(); pg.wait_for_timeout(900)
    ck("tapping it opens the Dice page", pg.locator("#v-dice").is_visible())
    ck("not the placeholder", not pg.locator("#stubBody").is_visible())
    ck("it offers a d20 and a d6", pg.locator("[data-dicedie]").count()==2)
    pg.evaluate("()=>{ localStorage.setItem('keter-app-dice', JSON.stringify({dur:0})); }")
    pg.locator('[data-dicedie="d6"]').click(); pg.wait_for_timeout(200)
    for _ in range(2): pg.locator("#diceMore").click(); pg.wait_for_timeout(100)
    pg.locator("#diceRoll").click(); pg.wait_for_timeout(600)
    ck("several dice roll at once", pg.locator(".die.settled").count()==3, pg.locator(".die.settled").count())
    ck("with their total", "Total" in pg.locator("#v-dice").inner_text())
    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"DICE PAGE PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
