"""iPhone-shaped verification. Chromium with iOS metrics and UA — this catches
layout, viewport and code-path problems, but NOT WebKit engine differences."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright

TMP = pathlib.Path("/tmp/serve_ios")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP)
H = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(TMP))
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 8961), H); threading.Thread(target=srv.serve_forever, daemon=True).start()

IOS_UA = ("Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 "
          "(KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1")

ok, bad = [], []
def ck(n, c, det=""):
    (ok if c else bad).append(n + ((" — " + str(det)) if det and not c else ""))

# iPhone 13/14 logical viewport, and a small one for iPhone SE
for label, w, h in [("iPhone 14", 390, 844), ("iPhone SE", 375, 667)]:
    with sync_playwright() as p:
        b = p.chromium.launch()
        c = b.new_context(viewport={"width": w, "height": h}, device_scale_factor=3,
                          is_mobile=True, has_touch=True, user_agent=IOS_UA)
        pg = c.new_page(); errs = []
        pg.on("pageerror", lambda e: errs.append(str(e)))
        pg.on("console", lambda m: errs.append("con:" + m.text) if m.type == "error" else None)
        pg.goto("http://127.0.0.1:8961/index.html"); pg.wait_for_timeout(2200)

        ck(f"[{label}] app loads", pg.locator("#shell").is_visible())
        ck(f"[{label}] no horizontal overflow",
           pg.evaluate("()=>document.documentElement.scrollWidth-document.documentElement.clientWidth") <= 0)

        # bottom nav must be fully on screen, not under a toolbar
        nav = pg.locator("#nav").evaluate("e=>{var r=e.getBoundingClientRect();return [Math.round(r.bottom), innerHeight]}")
        ck(f"[{label}] bottom nav sits inside the viewport", nav[0] <= nav[1] + 1, f"{nav}")
        ck(f"[{label}] all 6 tabs visible",
           pg.evaluate("()=>[...document.querySelectorAll('#nav button')].every(b=>b.getBoundingClientRect().width>30)"))

        # search field must not be a native iOS pill
        pg.locator("#nav button[data-go='manual']").click(); pg.wait_for_timeout(900)
        app = pg.locator("#q").evaluate("e=>getComputedStyle(e).webkitAppearance || getComputedStyle(e).appearance")
        ck(f"[{label}] search input keeps the app styling", app == "none", app)
        ck(f"[{label}] search input is 16px", pg.locator("#q").evaluate("e=>getComputedStyle(e).fontSize") == "16px")

        # keywords and definitions
        ck(f"[{label}] keywords marked", pg.locator("#mbody .kw").count() > 100)
        pg.locator("#mbody .kw").first.click(); pg.wait_for_timeout(400)
        kb = pg.locator("#kwbox").evaluate("e=>{var r=e.getBoundingClientRect();return [r.top>=0, r.bottom<=innerHeight+1, r.left>=0, r.right<=innerWidth+1]}")
        ck(f"[{label}] definition popup fully on screen", all(kb), str(kb))
        pg.locator("#mbody").click(position={"x": 200, "y": 250}); pg.wait_for_timeout(300)

        # compendium grid placeholder must have real height without aspect-ratio
        pg.evaluate("""()=>localStorage.setItem('keter-cardforge-heroes',JSON.stringify({
          "A":{v:6,type:"hero",name:"A",aff:"District 3",level:"1",stats:{hp:"30"},abilities:[]}}))""")
        pg.reload(); pg.wait_for_timeout(2000)
        pg.locator("#nav button[data-go='comp']").click(); pg.wait_for_timeout(700)
        pg.locator("#cView").click(); pg.wait_for_timeout(1200)
        ph = pg.evaluate("""()=>{var e=document.querySelector('.gcard .ph, .gcard img');
          return e?Math.round(e.getBoundingClientRect().height):0;}""")
        ck(f"[{label}] card grid tiles have height", ph > 60, f"h={ph}px")
        pg.wait_for_timeout(3500)
        ck(f"[{label}] grid thumbnails render", pg.locator(".gcard img").count() >= 1)

        # visiting Cards before Forge must not leave the Forge unfitted
        pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3000)
        fr = pg.frame_locator("#v-forge iframe")
        cw = fr.locator("#card").evaluate("e=>{var r=e.getBoundingClientRect();return [Math.round(r.width), Math.round(innerWidth)]}")
        ck(f"[{label}] card preview fits after visiting Cards first",
           cw[0] <= cw[1] - 10, f"card={cw[0]} vw={cw[1]}")
        ck(f"[{label}] tool exposes the fit hook",
           pg.evaluate("()=>typeof document.querySelector('#v-forge iframe').contentWindow.keterFit") == "function")

        pg.locator("#nav button[data-go='poi']").click(); pg.wait_for_timeout(3000)
        pr = pg.frame_locator("#v-poi iframe")
        zoom = pr.locator("#zoomTag").inner_text()
        ck(f"[{label}] sandbox auto-fitted", zoom != "100%", zoom)
        hh = pr.locator("header").evaluate("e=>Math.round(e.scrollWidth-e.clientWidth)")
        ck(f"[{label}] sandbox header does not scroll", hh <= 2, f"{hh}px")
        dk = pr.locator(".dock").first.evaluate("e=>{var r=e.getBoundingClientRect();return [Math.round(r.left), innerWidth]}")
        ck(f"[{label}] dock tab reachable", dk[0] < dk[1] - 40, str(dk))

        # export path must not rely on the download attribute
        pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(500)
        pg.evaluate("""()=>{window.__opened=null;
          window.open=function(u){window.__opened=String(u).slice(0,40);return {};};}""")
        pg.locator("#expAll").click(); pg.wait_for_timeout(900)
        opened = pg.evaluate("()=>window.__opened")
        ck(f"[{label}] export falls back instead of failing silently",
           opened is not None and opened.startswith("data:application/json"), str(opened))
        ck(f"[{label}] export explains what to do",
           "Save to Files" in pg.locator("#modalBox").inner_text())
        pg.locator("#mClose").click(); pg.wait_for_timeout(300)

        real = [e for e in errs if "favicon" not in e.lower()]
        ck(f"[{label}] no JS errors", len(real) == 0, "; ".join(real[:2]))
        b.close()

srv.shutdown()
print(f"IOS PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
sys.exit(1 if bad else 0)
