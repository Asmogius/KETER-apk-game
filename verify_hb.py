"""Handbook editor verification."""
import http.server, socketserver, threading, functools, pathlib, shutil, json, sys
from playwright.sync_api import sync_playwright

TMP = pathlib.Path("/tmp/serve_hb")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP)
H = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(TMP))
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 8951), H); threading.Thread(target=srv.serve_forever, daemon=True).start()

ok, bad = [], []
import json as _json
APP_VER = _json.load(open('pwa/version.json'))['version']
def ck(n, c, det=""):
    (ok if c else bad).append(n + ((" — " + str(det)) if det and not c else ""))

with sync_playwright() as p:
    b = p.chromium.launch()
    c = b.new_context(viewport={"width": 412, "height": 915}, is_mobile=True, has_touch=True)
    pg = c.new_page(); errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.on("console", lambda m: errs.append("con:" + m.text) if m.type == "error" else None)
    pg.goto("http://127.0.0.1:8951/index.html"); pg.wait_for_timeout(2000)

    # friends see no editing at all
    pg.locator("#nav button[data-go='manual']").click(); pg.wait_for_timeout(900)
    ck("no edit handles without Dev Mode", pg.locator(".edpen").count() == 0)
    ck("no handbook dev bar for friends", pg.locator("#hbExport").count() == 0)
    base_kw = pg.locator("#mbody .kw").count()
    ck("guides still render normally", base_kw > 100, base_kw)

    # unlock dev mode
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(400)
    pg.locator("#devBtn").click(); pg.wait_for_timeout(400)
    pg.locator("#pw").fill("Nosam124"); pg.locator("#pwGo").click(); pg.wait_for_timeout(800)
    pg.locator("#mClose").click(); pg.wait_for_timeout(300)
    pg.locator("#nav button[data-go='manual']").click(); pg.wait_for_timeout(1000)

    pens = pg.locator(".edpen").count()
    ck("edit handles appear in Dev Mode", pens > 40, f"n={pens}")
    ck("handbook dev bar appears", pg.locator("#hbExport").count() == 1)
    ck("dev bar reports no edits yet", "No edits yet" in pg.locator("#hbdev").inner_text())

    # open the editor on a known section
    target = pg.locator('.edpen[data-sec="hb-unit-slots"]')
    ck("unit slots section has a handle", target.count() == 1)
    target.click(); pg.wait_for_timeout(600)
    ck("editor opens", pg.locator("#edWrap").evaluate("e=>e.classList.contains('on')"))
    src = pg.locator("#edArea").input_value()
    ck("editor seeded with real markdown source",
       src.startswith("## Unit Slots") and "Leadership" in src, src[:60])
    ck("editor font is 16px so iOS will not zoom",
       pg.locator("#edArea").evaluate("e=>getComputedStyle(e).fontSize") == "16px")
    ck("revert hidden on an unedited section",
       pg.locator("#edRevert").evaluate("e=>getComputedStyle(e).display") == "none")

    # edit it, including a table and bold, then save
    NEW = ("## Unit Slots\n\nEdited for the test. **Leadership** sets Unit Slots at a 1:1 ratio.\n\n"
           "| Stat | Meaning |\n| --- | --- |\n| LDR | Unit Slots available |\n| WIL | Overwhelmed threshold |\n\n"
           "- First bullet\n- Second bullet\n")
    pg.locator("#edArea").fill(NEW)
    pg.locator("#edSave").click(); pg.wait_for_timeout(1200)
    ck("editor closes on save", not pg.locator("#edWrap").evaluate("e=>e.classList.contains('on')"))
    body = pg.locator("#mbody").inner_text()
    ck("edited text is in the document", "Edited for the test" in body)
    ck("markdown table rendered",
       pg.locator("#mbody table").count() > 0 and
       "Overwhelmed threshold" in pg.locator("#mbody").inner_text())
    ck("markdown bold rendered", pg.locator("#mbody strong").count() > 0)
    ck("markdown list rendered", "First bullet" in body)
    ck("heading kept its id", pg.locator("#hb-unit-slots").count() == 1)
    ck("edited section marked", pg.locator("#mbody .secedited").count() >= 1)
    ck("dev bar counts the edit", "1 edited section" in pg.locator("#hbdev").inner_text())
    ck("unpublished state flagged", "unpublished" in pg.locator("#hbdev").inner_text())
    ck("keywords re-marked inside edited text",
       pg.locator('#hb-unit-slots').count() == 1 and pg.locator("#mbody .kw").count() > 100,
       pg.locator("#mbody .kw").count())

    # the original text is gone, not duplicated
    ck("original section replaced, not appended",
       body.count("Edited for the test") == 1 and
       "Each Troop occupies a number of Unit Slots" not in body)

    # persistence across reload
    pg.reload(); pg.wait_for_timeout(2000)
    pg.locator("#nav button[data-go='manual']").click(); pg.wait_for_timeout(1000)
    ck("edit survives reload", "Edited for the test" in pg.locator("#mbody").inner_text())

    # contents list still works and jumps
    pg.locator("#tocBtn").click(); pg.wait_for_timeout(400)
    ck("contents still populated", pg.locator("#toc a").count() > 40)
    pg.locator("#tocBtn").click(); pg.wait_for_timeout(300)

    # search reaches edited text
    pg.locator("#q").fill("Edited for the test"); pg.wait_for_timeout(700)
    pg.locator("#q").fill(""); pg.wait_for_timeout(500)

    # revert
    pg.locator('.edpen[data-sec="hb-unit-slots"]').click(); pg.wait_for_timeout(600)
    ck("revert offered on an edited section",
       pg.locator("#edRevert").evaluate("e=>getComputedStyle(e).display") != "none")
    pg.locator("#edRevert").click(); pg.wait_for_timeout(1000)
    ck("revert restores the original",
       "Each Troop occupies a number of Unit Slots" in pg.locator("#mbody").inner_text())
    ck("edit count back to zero", "No edits yet" in pg.locator("#hbdev").inner_text())

    # glossary edit drives the keyword popups
    pg.locator('.edpen[data-sec="hb-13-glossary"]').click(); pg.wait_for_timeout(700)
    gsrc = pg.locator("#edArea").input_value()
    ck("glossary source loaded", "| **Term** |" in gsrc or "Abomination" in gsrc, gsrc[:60])
    pg.locator("#edArea").fill(gsrc.replace(
        "| **Abomination** |", "| **Abomination** | REDEFINED FOR TEST. |\n| **ZZZOldRow** |", 1))
    pg.locator("#edSave").click(); pg.wait_for_timeout(1500)
    hit = pg.evaluate("""()=>{
      var a=[...document.querySelectorAll('#mbody .kw')]
        .find(x=>x.getAttribute('data-kw')==='abomination');
      if(!a) return 'no keyword';
      a.click();
      return document.querySelector('#kwbox span').textContent;
    }""")
    ck("editing the glossary changes the definition popup",
       "REDEFINED FOR TEST" in str(hit), str(hit)[:70])
    pg.locator('.edpen[data-sec="hb-13-glossary"]').click(); pg.wait_for_timeout(600)
    pg.locator("#edRevert").click(); pg.wait_for_timeout(1200)

    # export
    pg.locator('.edpen[data-sec="hb-unit-slots"]').click(); pg.wait_for_timeout(500)
    pg.locator("#edArea").fill("## Unit Slots\n\nSecond edit for export.\n")
    pg.locator("#edSave").click(); pg.wait_for_timeout(1000)
    with pg.expect_download(timeout=8000) as dl:
        pg.locator("#hbExport").click()
    ck("exports as handbook.json", dl.value.suggested_filename == "handbook.json")
    path = dl.value.path()
    payload = json.loads(pathlib.Path(path).read_text())
    ck("export contains the edit",
       "Second edit for export" in json.dumps(payload["edits"]))
    ck("export bumps its version", str(payload["version"]) == "1", payload.get("version"))
    pg.wait_for_timeout(400); pg.locator("#mClose").click(); pg.wait_for_timeout(300)
    ck("unpublished flag cleared after export",
       "unpublished" not in pg.locator("#hbdev").inner_text())

    # a published overlay reaches a fresh device
    (TMP / "handbook.json").write_text(json.dumps({
        "schema": "keter.handbook/1", "version": "7",
        "edits": {"hb": {"hb-unit-slots": {"md": "## Unit Slots\n\nPUBLISHED OVERLAY TEXT.\n"}}}
    }))
    c2 = b.new_context(viewport={"width": 412, "height": 915}, is_mobile=True, has_touch=True)
    pg2 = c2.new_page()
    pg2.goto("http://127.0.0.1:8951/index.html"); pg2.wait_for_timeout(2200)
    pg2.locator("#nav button[data-go='manual']").click(); pg2.wait_for_timeout(1000)
    ck("published overlay reaches a fresh install",
       "PUBLISHED OVERLAY TEXT" in pg2.locator("#mbody").inner_text())
    ck("fresh install still has no edit handles", pg2.locator(".edpen").count() == 0)
    c2.close()

    # ---- every built page that needs a guide has one ----
    pg.locator("#nav button[data-go='manual']").click(); pg.wait_for_timeout(900)
    titles = pg.locator("#docSel option").all_inner_texts()
    for want in ["Player Handbook","Card Forge Guide","POI Sandbox Guide",
                 "Combat Datapad Guide","Battle Simulator Guide",
                 "Deck Builder Guide"]:
        ck(f"{want} is offered", want in titles, str(titles))

    for i2, t in enumerate(titles):
        pg.locator("#docSel").select_option(str(i2)); pg.wait_for_timeout(600)
        body = pg.locator("#mbody").inner_text()
        ck(f"{t} has content", len(body) > 2000, f"{len(body)} chars")
        ck(f"{t} is sectioned", pg.locator("#mbody h2").count() >= 5,
           pg.locator("#mbody h2").count())

    # the two guides describing overlapping tools each say which is which
    pg.locator("#docSel").select_option(str(titles.index("Combat Datapad Guide")))
    pg.wait_for_timeout(600)
    dp = pg.locator("#mbody").inner_text()
    ck("the Datapad guide distinguishes itself from the Simulator",
       "Simulator" in dp, dp[:120])
    ck("and it covers Consumables", "Consumable" in dp)
    pg.locator("#docSel").select_option(str(titles.index("Battle Simulator Guide")))
    pg.wait_for_timeout(600)
    sg = pg.locator("#mbody").inner_text()
    ck("the Simulator guide distinguishes itself from the Datapad",
       "Datapad" in sg, sg[:120])
    for topic in ["Undo","Auto","Aether","Cover","Manual"]:
        ck(f"the Simulator guide covers {topic}", topic in sg)

    # ---- What's New and the Change Log are in order ----
    # they had fallen into three disordered blocks, with the newest entry
    # landing mid-file and one dropped entirely
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(500)
    pg.locator("#aboutBtn").click(); pg.wait_for_timeout(700)

    pg.locator('[data-ab="whatsnew"]').click(); pg.wait_for_timeout(700)
    heads = pg.locator("#abbody h2").all_inner_texts()
    ck("What's New has entries", len(heads) > 10, str(len(heads)))
    def vkey(h):
        import re as _re
        m=_re.match(r'V([\d.]+)', h.strip().upper())
        return tuple(int(x) for x in m.group(1).split(".")) if m else None
    keys=[vkey(h) for h in heads]
    keys=[k for k in keys if k]
    ck("and they run newest first", keys == sorted(keys, reverse=True),
       str(heads[:4]))
    ck("the newest entry matches the build",
       heads[0].strip().upper().startswith("V" + APP_VER.upper().lstrip("V")),
       f"{heads[0]} vs {APP_VER}")
    ck("no editing marker leaks into the page",
       "NEWEST ENTRY" not in pg.locator("#abbody").inner_text())

    pg.locator('[data-ab="changelog"]').click(); pg.wait_for_timeout(700)
    revs = pg.locator("#abbody h2").all_inner_texts()
    ck("the Change Log has revisions", len(revs) >= 3, str(revs))
    import re as _re2
    rk=[tuple(int(x) for x in _re2.match(r'REVISION ([\d.]+)', r.strip().upper()).group(1).split("."))
        for r in revs if _re2.match(r'REVISION ([\d.]+)', r.strip().upper())]
    ck("every section is a labelled revision", len(rk) == len(revs), str(revs))
    ck("and they run newest first", rk == sorted(rk, reverse=True), str(revs))

    real = [e for e in errs if "favicon" not in e.lower()]
    ck("no JS errors", len(real) == 0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"HANDBOOK PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
sys.exit(1 if bad else 0)
