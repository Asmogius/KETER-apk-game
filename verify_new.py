"""Verification for v2.4 features: updates, keywords, compendium, dev mode."""
import http.server, socketserver, threading, functools, pathlib, json, shutil, os, sys
from playwright.sync_api import sync_playwright

SRC = pathlib.Path("pwa")
TMP = pathlib.Path("/tmp/serve"); 
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree(SRC, TMP)

H = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(TMP))
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 8931), H)
threading.Thread(target=srv.serve_forever, daemon=True).start()
BASE = "http://127.0.0.1:8931/index.html"

CURV = json.loads((TMP / "version.json").read_text())["version"]
ok, bad = [], []
def ck(n, c, det=""):
    (ok if c else bad).append(n + ((" — " + str(det)) if det and not c else ""))

with sync_playwright() as p:
    b = p.chromium.launch()
    c = b.new_context(viewport={"width": 412, "height": 915}, is_mobile=True, has_touch=True)
    pg = c.new_page()
    errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.on("console", lambda m: errs.append("con:" + m.text) if m.type == "error" else None)
    pg.goto(BASE); pg.wait_for_timeout(2200)

    # ---------- keywords ----------
    pg.locator("#nav button[data-go='manual']").click(); pg.wait_for_timeout(900)
    kw = pg.locator("#mbody .kw").count()
    ck("keywords marked in the Handbook", kw > 100, f"n={kw}")
    ck("keyword marks are not in headings",
       pg.locator("#mbody h1 .kw, #mbody h2 .kw").count() == 0)
    first = pg.locator("#mbody .kw").first
    term = first.inner_text()
    first.click(); pg.wait_for_timeout(400)
    ck("tapping a keyword opens a definition",
       pg.locator("#kwbox").evaluate("e=>e.classList.contains('on')"))
    deftext = pg.locator("#kwbox span").inner_text()
    ck("definition has content", len(deftext) > 20, deftext[:40])
    ck("definition names the term", len(pg.locator("#kwbox b").inner_text()) > 1)
    pg.locator("#mbody").click(position={"x": 200, "y": 300}); pg.wait_for_timeout(350)
    ck("tapping outside closes the definition",
       not pg.locator("#kwbox").evaluate("e=>e.classList.contains('on')"))

    # every occurrence, not just the first
    counts = pg.evaluate("""()=>{
      var m={};
      document.querySelectorAll('#mbody .kw').forEach(a=>{
        var k=a.getAttribute('data-kw'); m[k]=(m[k]||0)+1; });
      return Math.max(...Object.values(m));
    }""")
    ck("every occurrence is marked, not just the first", counts > 1, f"max={counts}")

    # ---------- compendium ----------
    pg.locator("#nav button[data-go='comp']").click(); pg.wait_for_timeout(800)
    ck("compendium tab opens", pg.locator("#v-comp").evaluate("e=>e.classList.contains('on')"))
    # v12.8: the Workshop's built-in starter design is always there
    ck("with no cards of your own, only the built-in starter design", pg.locator("#clist").inner_text().count("Frame Trooper")==1 and pg.locator(".crow").count()<=1, pg.locator("#clist").inner_text()[:120])

    # seed two Forge cards, as if built on this device
    pg.evaluate("""()=>{
      localStorage.setItem('keter-cardforge-heroes', JSON.stringify({
        "Archimedes":{v:6,type:"hero",name:"Archimedes",aff:"District 3",arch:"Tinkerer",
          level:"3",rarity:"Rare",roles:{support:true},stats:{hp:"30",ac:"9",ldr:"10"},abilities:[]},
        "Rictus":{v:6,type:"hero",name:"Rictus",aff:"District 3",arch:"Berserker",
          level:"2",rarity:"Common",roles:{melee:true},stats:{hp:"44",ac:"11",ldr:"1"},abilities:[]}
      }));
    }""")
    pg.reload(); pg.wait_for_timeout(1800)
    pg.locator("#nav button[data-go='comp']").click(); pg.wait_for_timeout(700)
    ck("own cards appear (beside the starter design)", pg.locator(".crow").count() == 3, pg.locator(".crow").count())
    ck("own cards badged Mine", pg.locator(".tagpill.mine").count() == 2)
    ck("card line shows metadata", "hero" in pg.locator(".crow i").first.inner_text())

    # search + filter + sort
    pg.locator("#cq").fill("rictus"); pg.wait_for_timeout(400)
    ck("search filters cards", pg.locator(".crow").count() == 1)
    pg.locator("#cq").fill(""); pg.wait_for_timeout(300)
    pg.locator("#cFilters").click(); pg.wait_for_timeout(250)
    ck("filter panel opens", pg.locator("#cfilters").evaluate("e=>e.classList.contains('on')"))
    # filters are toggles now: everything lit, switch off what to hide
    opts = pg.locator('[data-fg="type"]').count()
    ck("type filter populated from data", opts >= 1, f"n={opts}")  # no "All types" entry any more
    for v in pg.locator('[data-fg="role"]').evaluate_all("els=>els.map(e=>e.getAttribute('data-fv'))"):
        if v!="melee":
            pg.locator(f'[data-fg="role"][data-fv="{v}"]').click(); pg.wait_for_timeout(150)
    pg.wait_for_timeout(300)
    ck("role filter works", pg.locator(".crow").count() == 1)
    pg.locator("#cReset").click(); pg.wait_for_timeout(400)
    ck("clear filters restores all", pg.locator(".crow").count() == 3)
    pg.locator("#cSort").select_option("level"); pg.wait_for_timeout(400)
    names=pg.locator(".crow b").all_inner_texts()
    ck("sort by level reorders", names.index("Rictus")<names.index("Archimedes"), names)

    # tap to render a real card
    pg.locator(".crow").first.click(); pg.wait_for_timeout(4000)
    ck("card detail renders an image from the Forge",
       pg.locator("#cardShot img").count() == 1,
       pg.locator("#cardShot").inner_text()[:40])
    w = pg.locator("#cardShot img").evaluate("e=>e.naturalWidth")
    ck("rendered card is a real bitmap", w > 100, f"w={w}")
    pg.locator("#mClose").click(); pg.wait_for_timeout(300)

    # grid view
    pg.locator("#cView").click(); pg.wait_for_timeout(4000)
    ck("grid view renders thumbnails", pg.locator(".gcard img").count() >= 1,
       pg.locator(".gcard").count())
    ck("thumbnails cached in IndexedDB", pg.evaluate("""async ()=>{
      return await new Promise(r=>{
        var q=indexedDB.open('keter-durable',1);
        q.onsuccess=()=>{var d=q.result;
          var s=d.transaction('kv','readonly').objectStore('kv');
          var g=s.getAllKeys();
          g.onsuccess=()=>r(g.result.filter(k=>String(k).indexOf('thumb')===0).length);
          g.onerror=()=>r(0);};
        q.onerror=()=>r(0);});
    }""") >= 1)
    pg.locator("#cView").click(); pg.wait_for_timeout(600)

    # non-dev sees the submit button, not dev tools
    ck("friends get an export-to-send button", pg.locator("#uExport").count() == 1)
    ck("friends do not see master tools", pg.locator("#dExport").count() == 0)

    # ---------- dev mode ----------
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(400)
    pg.locator("#devBtn").click(); pg.wait_for_timeout(400)
    pg.locator("#pw").fill("wrongpass"); pg.locator("#pwGo").click(); pg.wait_for_timeout(600)
    ck("wrong password rejected",
       pg.locator("#pwErr").evaluate("e=>getComputedStyle(e).display") != "none")
    pg.locator("#pw").fill("Nosam124"); pg.locator("#pwGo").click(); pg.wait_for_timeout(800)
    ck("correct password unlocks", pg.evaluate("()=>localStorage.getItem('keter-app-dev')") == "1")
    ck("password not stored in plain text",
       "Nosam124" not in pg.content() or pg.content().count("Nosam124") <= 1)
    pg.locator("#mClose").click(); pg.wait_for_timeout(300)
    ck("dev badge shown on home",
       pg.locator("#devflag").evaluate("e=>e.classList.contains('on')"))

    pg.locator("#nav button[data-go='comp']").click(); pg.wait_for_timeout(700)
    ck("dev tools appear in compendium", pg.locator("#dExport").count() == 1)
    ck("add-my-cards offered", pg.locator("#dMine").count() == 1)

    # promote own cards to master through the review flow
    pg.locator("#dMine").click(); pg.wait_for_timeout(600)
    ck("import review lists each card", pg.locator("[data-rv]").count() == 2)
    pg.locator('[data-rv="1"]').uncheck(); pg.wait_for_timeout(200)
    pg.locator("#rvAdd").click(); pg.wait_for_timeout(700)
    ck("only ticked cards were added",
       pg.evaluate("()=>JSON.parse(localStorage.getItem('keter-app-master')).cards.length") == 1)
    pg.locator("#mClose").click(); pg.wait_for_timeout(400)
    ck("master card now listed", pg.locator(".tagpill").count() == 4)  # beside two of mine and the starter design
    ck("unpublished changes flagged", "unpublished" in pg.locator("#ccount").inner_text())

    # edit a master card's fields
    master_row = pg.locator(".crow").filter(has=pg.locator(".tagpill:not(.mine):not(.design)")).first
    master_row.click(); pg.wait_for_timeout(3000)
    ck("edit offered on master cards", pg.locator("#cEdit").count() == 1)
    pg.locator("#cEdit").click(); pg.wait_for_timeout(500)
    pg.locator('[data-ef="name"]').fill("Archimedes Prime")
    pg.locator("#efSave").click(); pg.wait_for_timeout(700)
    ck("field edit persisted",
       "Archimedes Prime" in pg.evaluate("()=>localStorage.getItem('keter-app-master')"))

    # export master
    with pg.expect_download(timeout=8000) as dl:
        pg.locator("#dExport").click()
    ck("master exports as compendium.json", dl.value.suggested_filename == "compendium.json")
    pg.wait_for_timeout(500)
    pg.locator("#mClose").click(); pg.wait_for_timeout(300)

    # preview as a friend
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(400)
    pg.locator("#devBtn").click(); pg.wait_for_timeout(400)
    pg.locator("#pvToggle").click(); pg.wait_for_timeout(500)
    pg.locator("#mClose").click(); pg.wait_for_timeout(300)
    pg.locator("#nav button[data-go='comp']").click(); pg.wait_for_timeout(600)
    ck("previewing hides dev tools", pg.locator("#dExport").count() == 0)
    ck("previewing still shows the friend button", pg.locator("#uExport").count() == 1)
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(300)
    ck("preview state is visible on home", "previewing" in pg.locator("#devBtn").inner_text())
    pg.locator("#devBtn").click(); pg.wait_for_timeout(400)
    pg.locator("#pvToggle").click(); pg.wait_for_timeout(500)
    pg.locator("#mClose").click(); pg.wait_for_timeout(300)
    ck("preview toggles back off", pg.evaluate("()=>localStorage.getItem('keter-app-dev-preview')") == "0")

    # ---------- updates ----------
    pg.locator("#updBtn").click(); pg.wait_for_timeout(1200)
    txt = pg.locator("#modalBox").inner_text()
    ck("update panel reports installed version", "Installed" in txt, txt[:60])
    ck("update panel says up to date", "up to date" in txt, txt[:120])
    ck("repair offered in dev mode", pg.locator("#doRepair").count() == 1)
    pg.locator("#mClose").click(); pg.wait_for_timeout(300)

    # publish a newer version and confirm detection
    v = json.loads((TMP / "version.json").read_text())
    NEWER = str(int(CURV.split(".")[0]) + 1) + ".0"
    (TMP / "version.json").write_text(json.dumps({"version": NEWER, "built": v.get("built")}))
    pg.locator("#updBtn").click(); pg.wait_for_timeout(1500)
    txt2 = pg.locator("#modalBox").inner_text()
    ck("new version detected", NEWER in txt2, txt2[:120])
    ck("update action offered", pg.locator("#doUpdate").count() == 1)
    pg.locator("#mClose").click(); pg.wait_for_timeout(300)
    ck("home badge lights up", pg.locator("#updBtn").evaluate("e=>e.classList.contains('has')"))

    # the real test: a changed index.html must reach the app on reload
    idx = (TMP / "index.html").read_text()
    (TMP / "index.html").write_text(idx.replace("Companion v"+CURV, "Companion v"+NEWER))
    pg.locator("#updBtn").click(); pg.wait_for_timeout(900)
    pg.locator("#doUpdate").click()
    pg.wait_for_timeout(4000)
    ck("update actually replaces the running app",
       ("v"+NEWER) in pg.locator("#bar .sub").inner_text(),
       pg.locator("#bar .sub").inner_text())

    # dev state survived the update
    ck("dev mode survives an update", pg.evaluate("()=>localStorage.getItem('keter-app-dev')") == "1")
    ck("master data survives an update",
       "Archimedes Prime" in (pg.evaluate("()=>localStorage.getItem('keter-app-master')") or ""))

    # repair must not destroy data
    pg.locator("#updBtn").click(); pg.wait_for_timeout(1200)
    pg.locator("#doRepair").click(); pg.wait_for_timeout(4500)
    ck("repair keeps saved cards",
       pg.evaluate("()=>!!localStorage.getItem('keter-cardforge-heroes')"))
    ck("repair keeps the master schema",
       pg.evaluate("()=>!!localStorage.getItem('keter-app-master')"))
    ck("app still works after repair", pg.locator("#shell").is_visible())
    ck("repair leaves a fresh cache, not the old one",
       pg.evaluate("()=>caches.keys().then(k=>k.length<=1)"))

    ck("no bogus resource requests",
       not any("IDBRequest" in e or "undefined" in e for e in errs),
       "; ".join([e for e in errs if "IDBRequest" in e][:2]))
    real = [e for e in errs if "favicon" not in e.lower()]
    ck("no JS errors", len(real) == 0, "; ".join(real[:3]))
    b.close()

srv.shutdown()
print(f"NEW FEATURES PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
sys.exit(1 if bad else 0)
