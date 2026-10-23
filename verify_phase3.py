"""Phase 3: navigation, launcher, placeholders, HUD."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright
TMP = pathlib.Path("/tmp/serve_p3")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP)
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 8995),
        functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(TMP)))
threading.Thread(target=srv.serve_forever, daemon=True).start()
ok, bad = [], []
def ck(n, c, det=""):
    (ok if c else bad).append(n + ((" — " + str(det)) if det and not c else ""))

with sync_playwright() as p:
    b = p.chromium.launch()
    c = b.new_context(viewport={"width": 412, "height": 915}, is_mobile=True, has_touch=True)
    pg = c.new_page(); errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.on("console", lambda m: errs.append("con:" + m.text) if m.type == "error" else None)
    pg.goto("http://127.0.0.1:8995/index.html"); pg.wait_for_timeout(2000)

    # ---- navigation ----
    ck("nav is five tabs", pg.locator("#nav button").count() == 5,
       pg.locator("#nav button").count())
    labels = " ".join(pg.locator("#nav button").all_inner_texts()).upper()
    for want in ["HOME", "GUIDES", "CARDS", "FORGE", "SANDBOX"]:
        ck(f"tab present: {want}", want in labels, labels)
    ck("no horizontal overflow at 412px",
       pg.evaluate("()=>document.documentElement.scrollWidth-document.documentElement.clientWidth") <= 0)
    w = pg.locator("#nav button").first.evaluate("e=>Math.round(e.getBoundingClientRect().width)")
    ck("tabs are a usable width", w >= 70, f"{w}px")

    # ---- launcher ----
    tiles = pg.locator(".lt").count()
    ck("launcher lists every page", tiles == 25, f"n={tiles}")  # the Pixel and Hex Studios and Chassis made it 21; the Workshop and the Codex 23; the World Map 24; the Dock 25
    ck("built pages are not marked WIP",
       pg.locator('.lt[data-page="deck"]').evaluate("e=>!e.classList.contains('wip')"))
    ck("unbuilt pages are marked WIP",
       pg.locator('.lt[data-page="poigen"]').evaluate("e=>e.classList.contains('wip')"))
    ck("Deck Builder is reachable from Home",
       pg.locator('.lt[data-page="deck"]').count() == 1)

    # ---- placeholders ----
    ck("the Battle Simulator is a real page now",
       pg.locator('.lt[data-page="battle"]').count() == 1)
    # This used the Dice Simulator as its example of an unbuilt tool, and so
    # kept that finished page hidden behind a placeholder. The POI Generator
    # genuinely is unbuilt; the Dice Simulator must open as a page.
    ck("the Dice Simulator is a real page, not a placeholder",
       not pg.locator('.lt[data-page="dice"]').evaluate("e=>e.classList.contains('wip')"))
    pg.locator('.lt[data-page="poigen"]').click(); pg.wait_for_timeout(600)
    txt = pg.locator("#stubBody").evaluate("e=>e.innerText")
    ck("placeholder opens", pg.locator("#v-stub").evaluate("e=>e.classList.contains('on')"))
    ck("placeholder names itself",
       "POI GENERATOR" in pg.locator("#stubBody h2").inner_text().upper(),
       pg.locator("#stubBody h2").inner_text())
    ck("placeholder says it is not built", "Not built yet" in txt)
    ck("placeholder explains what it is waiting on", len(txt) > 60, txt[-120:])
    ck("placeholder is deep-linkable", "#/poigen" in pg.url, pg.url)

    # real page from the launcher
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(400)
    pg.locator('.lt[data-page="deck"]').click(); pg.wait_for_timeout(700)
    ck("Deck Builder opens as a real page",
       pg.locator("#v-deck").evaluate("e=>e.classList.contains('on')"))

    # ---- #9 header only on Home ----
    ck("app header hidden off Home",
       pg.locator("#bar").evaluate("e=>getComputedStyle(e).display") == "none")
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(500)
    ck("app header shown on Home",
       pg.locator("#bar").evaluate("e=>getComputedStyle(e).display") != "none")

    # ---- HUD in the Sandbox ----
    pg.locator("#nav button[data-go='poi']").click(); pg.wait_for_timeout(3200)
    pr = pg.frame_locator("#v-poi iframe")
    ck("#6 HUD exists", pr.locator("#keter-hud").count() == 1)
    n = pr.locator(".hudb").count()
    # Pan, Pings and Tasks left the HUD because each already existed elsewhere.
    # Help came back in v9.4: the corner copy it duplicated was removed, so the
    # rule this protected — one of each, never two — still holds.
    ck("#6 Sandbox HUD holds only what is unique to it", n == 5, f"n={n}")
    for bid in ["panel", "undo", "redo", "help", "more"]:
        ck(f"#6 HUD button: {bid}", pr.locator("#hud-" + bid).count() == 1)
    for bid in ["pan", "pings", "tasks"]:
        ck(f"#6 no duplicate in the HUD: {bid}", pr.locator("#hud-" + bid).count() == 0)
    ck("#6 no second Help anywhere in the tool",
       pr.locator("#keter-helpdock").count() == 0)
    ck("#14 tool name removed from the header",
       pr.locator("header .brand h1").evaluate("e=>getComputedStyle(e).display") == "none")
    ck("#8 title still present and tappable",
       "renamable" in pr.locator("#nameTag").get_attribute("class"))
    hud_r = pr.locator("#keter-hud").evaluate("e=>{var r=e.getBoundingClientRect();return [Math.round(r.right), innerWidth]}")
    ck("#6 HUD fits the screen", hud_r[0] <= hud_r[1] + 1, str(hud_r))

    # panel toggle works both ways from one button
    pg.evaluate("()=>document.querySelector('#v-poi iframe').contentDocument.getElementById('keter-scrim').classList.remove('on')")
    pg.evaluate("()=>document.querySelector('#v-poi iframe').contentDocument.getElementById('hud-panel').click()")
    pg.wait_for_timeout(600)
    st1 = pr.locator("aside").first.evaluate("e=>e.classList.contains('collapsed')")
    pg.evaluate("()=>document.querySelector('#v-poi iframe').contentDocument.getElementById('hud-panel').click()")
    pg.wait_for_timeout(600)
    st2 = pr.locator("aside").first.evaluate("e=>e.classList.contains('collapsed')")
    ck("#5 one button opens and closes the panel", st1 != st2, f"{st1} then {st2}")

    # #13 the panel animates
    ck("#13 panel has a slide transition",
       "transform" in pr.locator("aside").first.evaluate("e=>getComputedStyle(e).transition"),
       pr.locator("aside").first.evaluate("e=>getComputedStyle(e).transition"))

    # docks reachable from the HUD
    pg.evaluate("()=>document.querySelector('#v-poi iframe').contentDocument.getElementById('tabPings').click()")
    pg.wait_for_timeout(600)
    ck("#6 HUD opens the Pings dock",
       pr.locator("#dockPings").evaluate("e=>e.classList.contains('open')"))
    ck("#6 the dock carries its own count", pr.locator("#dockPings .badge").count() >= 1)

    # help mode from the HUD
    pg.evaluate("()=>document.querySelector('#v-poi iframe').contentDocument.getElementById('hud-help').click()")
    pg.wait_for_timeout(700)
    ck("#6 HUD turns on Help mode",
       pr.locator("#helpLayer").evaluate("e=>getComputedStyle(e).display") != "none")
    pg.evaluate("()=>document.querySelector('#v-poi iframe').contentDocument.getElementById('hud-help').click()")
    pg.wait_for_timeout(500)

    # overflow sheet from the HUD
    pg.evaluate("()=>document.querySelector('#v-poi iframe').contentDocument.getElementById('hud-more').click()")
    pg.wait_for_timeout(500)
    ck("#6 HUD opens the overflow sheet",
       pr.locator("#keter-sheet").evaluate("e=>getComputedStyle(e).display") == "block")
    ck("export still reachable", pr.locator("#keter-sheet .ks-body #pdfBtn").count() == 1)
    pr.locator("#keter-sheet .ks-close").click(); pg.wait_for_timeout(300)

    # ---- HUD in the Forge ----
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3200)
    fr = pg.frame_locator("#v-forge iframe")
    ck("#6 Forge has a HUD", fr.locator("#keter-hud").count() == 1)
    ck("#6 Forge HUD has no pan button", fr.locator("#hud-pan").count() == 0)
    # Pings, Tasks and Help left the HUD: the docks and the pinned Help button
    # are the single copies of each
    ck("#6 Forge HUD keeps panel and more",
       all(fr.locator("#hud-" + x).count() == 1 for x in ["panel", "more"]))
    ck("#6 no duplicate HUD copies",
       all(fr.locator("#hud-" + x).count() == 0 for x in ["pings", "tasks"]))
    ck("#6 exactly one Help in the Forge",
       fr.locator("#hud-help").count() == 1 and fr.locator("#keter-helpdock").count() == 0)
    ck("#14 Forge name removed",
       fr.locator("header .brand h1").evaluate("e=>getComputedStyle(e).display") == "none")

    real = [e for e in errs if "favicon" not in e.lower()]
    ck("no JS errors", len(real) == 0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"PHASE 3 PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
sys.exit(1 if bad else 0)
