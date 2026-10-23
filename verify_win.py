"""Windows desktop verification: hosted, downloaded file, wide and narrow windows."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright

TMP = pathlib.Path("/tmp/serve_win")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP)
H = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(TMP))
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 8971), H); threading.Thread(target=srv.serve_forever, daemon=True).start()

WIN_UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
          "(KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0")

ok, bad = [], []
def ck(n, c, det=""):
    (ok if c else bad).append(n + ((" — " + str(det)) if det and not c else ""))

SEED = """()=>localStorage.setItem('keter-cardforge-heroes',JSON.stringify({
 "Archimedes":{v:6,type:"hero",name:"Archimedes",aff:"District 3",level:"3",
   roles:{support:true},stats:{hp:"30",ldr:"6"},abilities:[]}}))"""

with sync_playwright() as p:
    b = p.chromium.launch()

    # ---------- 1366x768, the commonest Windows laptop ----------
    c = b.new_context(viewport={"width": 1366, "height": 768}, user_agent=WIN_UA,
                      is_mobile=False, has_touch=False, device_scale_factor=1)
    pg = c.new_page(); errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.on("console", lambda m: errs.append("con:" + m.text) if m.type == "error" else None)
    pg.goto("http://127.0.0.1:8971/index.html"); pg.wait_for_timeout(2000)

    ck("[1366] app loads", pg.locator("#shell").is_visible())
    ck("[1366] no horizontal overflow",
       pg.evaluate("()=>document.documentElement.scrollWidth-document.documentElement.clientWidth") <= 0)
    navw = pg.locator("#nav button").first.evaluate("e=>Math.round(e.getBoundingClientRect().width)")
    ck("[1366] nav tabs are a sane width, not stretched", 100 <= navw <= 180, f"{navw}px")

    # guides column should not run the full monitor width
    pg.locator("#nav button[data-go='manual']").click(); pg.wait_for_timeout(900)
    mw = pg.locator("#mbody").evaluate("e=>Math.round(e.getBoundingClientRect().width)")
    ck("[1366] guide text column is readable, not full width", mw <= 900, f"{mw}px")

    # Escape closes layers
    pg.locator("#mbody .kw").first.click(); pg.wait_for_timeout(350)
    ck("[1366] keyword popup opened", pg.locator("#kwbox").evaluate("e=>e.classList.contains('on')"))
    pg.keyboard.press("Escape"); pg.wait_for_timeout(300)
    ck("[1366] Escape closes the keyword popup",
       not pg.locator("#kwbox").evaluate("e=>e.classList.contains('on')"))
    pg.locator("#tocBtn").click(); pg.wait_for_timeout(300)
    pg.keyboard.press("Escape"); pg.wait_for_timeout(300)
    ck("[1366] Escape closes the contents drawer",
       not pg.locator("#toc").evaluate("e=>e.classList.contains('on')"))
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(400)
    pg.locator("#aboutBtn").click(); pg.wait_for_timeout(300)
    pg.keyboard.press("Escape"); pg.wait_for_timeout(300)
    ck("[1366] Escape closes a dialog",
       not pg.locator("#modal").evaluate("e=>e.classList.contains('on')"))

    # focus ring exists for keyboard users
    ck("[1366] focus ring defined",
       "focus-visible" in pg.content())

    # desktop layout inside the tools: panel open, no phone patch
    pg.locator("#nav button[data-go='poi']").click(); pg.wait_for_timeout(2600)
    pr = pg.frame_locator("#v-poi iframe")
    pos = pr.locator("aside").first.evaluate("e=>getComputedStyle(e).position")
    ck("[1366] sandbox panel is a sidebar, not an overlay", pos != "absolute", pos)
    ck("[1366] sandbox panel is open on desktop",
       not pr.locator("aside").first.evaluate("e=>e.classList.contains('collapsed')"))
    ck("[1366] no HUD on desktop",
       pr.locator("#keter-hud").count() == 0 or
       pr.locator("#keter-hud").evaluate("e=>getComputedStyle(e).display") == "none")
    hd = pr.locator("header").evaluate("e=>Math.round(e.scrollWidth-e.clientWidth)")
    ck("[1366] desktop header shows every control", hd <= 2, f"{hd}px")

    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(2600)
    fr = pg.frame_locator("#v-forge iframe")
    fin = fr.locator("input").first.evaluate("e=>getComputedStyle(e).fontSize")
    ck("[1366] desktop keeps its compact input size, not the 16px phone rule",
       fin != "16px", fin)

    # ---------- resize across the breakpoint both ways ----------
    pg.set_viewport_size({"width": 420, "height": 900}); pg.wait_for_timeout(1500)
    ck("[resize->narrow] HUD appears", fr.locator("#keter-hud").count() == 1)
    ck("[resize->narrow] panel collapses",
       fr.locator("aside").first.evaluate("e=>e.classList.contains('collapsed')"))
    pg.set_viewport_size({"width": 1366, "height": 768}); pg.wait_for_timeout(1500)
    ck("[resize->wide] HUD hidden again",
       fr.locator("#keter-hud").evaluate("e=>getComputedStyle(e).display") == "none")
    ck("[resize->wide] controls are back in the header",
       fr.locator("header #pdfBtn").count() == 1)
    ck("[resize->wide] panel reopens",
       not fr.locator("aside").first.evaluate("e=>e.classList.contains('collapsed')"))
    ck("[resize->wide] rail inline style cleared",
       fr.locator(".rail").evaluate("e=>e.style.display") in ("", None))

    # ---------- 1920x1080 ----------
    pg.set_viewport_size({"width": 1920, "height": 1080}); pg.wait_for_timeout(800)
    pg.evaluate(SEED); pg.reload(); pg.wait_for_timeout(2000)
    pg.locator("#nav button[data-go='comp']").click(); pg.wait_for_timeout(800)
    rw = pg.locator(".crow").first.evaluate("e=>Math.round(e.getBoundingClientRect().width)")
    ck("[1920] card rows are not full-monitor width", rw <= 960, f"{rw}px")
    pg.locator("#cView").click(); pg.wait_for_timeout(3500)
    gw = pg.locator(".gcard").first.evaluate("e=>Math.round(e.getBoundingClientRect().width)")
    ck("[1920] grid tiles are card-sized, not postage stamps", gw >= 170, f"{gw}px")
    ck("[1920] thumbnails still render", pg.locator(".gcard img").count() >= 1)

    # print stylesheet
    pg.locator("#nav button[data-go='manual']").click(); pg.wait_for_timeout(800)
    pg.emulate_media(media="print"); pg.wait_for_timeout(400)
    ck("[print] navigation hidden",
       pg.locator("#nav").evaluate("e=>getComputedStyle(e).display") == "none")
    ck("[print] header hidden",
       pg.locator("#bar").evaluate("e=>getComputedStyle(e).display") == "none")
    ck("[print] guide body still visible",
       pg.locator("#mbody").evaluate("e=>getComputedStyle(e).display") != "none")
    ck("[print] guide text is dark on white",
       pg.locator("#mbody").evaluate("e=>getComputedStyle(e).color") == "rgb(0, 0, 0)")
    pg.emulate_media(media="screen"); pg.wait_for_timeout(300)

    real = [e for e in errs if "favicon" not in e.lower()]
    ck("[1366] no JS errors", len(real) == 0, "; ".join(real[:2]))
    c.close()

    # ---------- the downloaded single file, opened from disk ----------
    c2 = b.new_context(viewport={"width": 1366, "height": 768}, user_agent=WIN_UA)
    pg2 = c2.new_page(); e2 = []
    pg2.on("pageerror", lambda e: e2.append(str(e)))
    # (the built Companion, as one file opened from disk, as a download is: not a delivered copy, whose name changes)
    one = pathlib.Path("/tmp/serve_win_file"); shutil.rmtree(one, ignore_errors=True); one.mkdir()
    shutil.copy("pwa/index.html", one / "KETER_Companion.html")
    pg2.goto((one / "KETER_Companion.html").as_uri())
    pg2.wait_for_timeout(1800)
    ck("[file] standalone file loads", pg2.locator("#shell").is_visible())
    ck("[file] localStorage available from disk",
       pg2.evaluate("()=>{try{localStorage.setItem('k','1');return localStorage.getItem('k')==='1'}catch(e){return false}}"))
    pg2.locator("#nav button[data-go='manual']").click(); pg2.wait_for_timeout(900)
    ck("[file] guides work offline from disk", pg2.locator("#mbody .kw").count() > 100)
    pg2.locator("#nav button[data-go='home']").click(); pg2.wait_for_timeout(400)
    pg2.locator("#updBtn").click(); pg2.wait_for_timeout(900)
    ck("[file] update check explains it is the standalone copy",
       "standalone file copy" in pg2.locator("#modalBox").inner_text(),
       pg2.locator("#modalBox").inner_text()[:80])
    pg2.locator("#mClose").click(); pg2.wait_for_timeout(300)
    pg2.locator("#nav button[data-go='forge']").click(); pg2.wait_for_timeout(2600)
    ck("[file] tools mount from disk",
       pg2.frame_locator("#v-forge iframe").locator("#card").count() == 1)
    ck("[file] no JS errors", len([x for x in e2 if "favicon" not in x.lower()]) == 0,
       "; ".join(e2[:2]))
    c2.close()
    b.close()

srv.shutdown()
print(f"WINDOWS PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
sys.exit(1 if bad else 0)
