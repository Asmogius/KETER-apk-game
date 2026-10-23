"""The bug report must make a silent bug visible."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright
TMP = pathlib.Path("/tmp/serve_bug")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP)
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 9321),
        functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(TMP)))
threading.Thread(target=srv.serve_forever, daemon=True).start()
ok, bad = [], []
def ck(n,c,d=""):
    (ok if c else bad).append(n + ((" — "+str(d)) if d and not c else ""))

with sync_playwright() as p:
    b = p.chromium.launch()
    c = b.new_context(viewport={"width":412,"height":915}, is_mobile=True, has_touch=True)
    pg = c.new_page(); errs=[]
    pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.goto("http://127.0.0.1:9321/"); pg.wait_for_timeout(2000)

    ck("a report button exists", pg.locator("#bugBtn").count()==1)

    # do things, the way a user would before noticing something is wrong
    pg.locator("#nav button[data-go='manual']").click(); pg.wait_for_timeout(900)
    pg.locator("#nav button[data-go='poi']").click(); pg.wait_for_timeout(3200)
    pg.evaluate("""()=>{
      var d=document.querySelector('#v-poi iframe').contentDocument;
      d.getElementById('keter-scrim').classList.remove('on');
      d.querySelector('[data-tool="paint"]').click();
      d.querySelector('[data-shape="hex"]').click();
    }""")
    pg.wait_for_timeout(700)
    # something throws inside the tool
    pg.evaluate("""()=>{
      var w=document.querySelector('#v-poi iframe').contentWindow;
      w.dispatchEvent(new ErrorEvent('error',{message:'simulated tool failure',
        filename:'poi.html', lineno:1234}));
    }""")
    pg.wait_for_timeout(500)
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(600)
    pg.locator("#bugBtn").click(); pg.wait_for_timeout(900)

    txt = pg.locator("#bugText").input_value()
    ck("the report opens", len(txt) > 200, str(len(txt)))

    # --- the snapshot ---
    ver = pg.evaluate("()=>fetch('version.json').then(function(r){return r.json();}).then(function(j){return j.version;})")
    ck("it names the app version, matching version.json",
       ("app: "+str(ver)) in txt, f"expected app: {ver} in {txt[:120]}")
    ck("it names the page", "page: home" in txt, txt[:200])
    ck("it reports the screen", "screen:" in txt)
    ck("it reports storage use", "storage:" in txt)
    ck("it reports card counts", "my cards:" in txt)

    # --- the tool state, which is what diagnoses silent bugs ---
    ck("it reports the Sandbox tool and shape",
       "tool=paint" in txt and "shape=hex" in txt, 
       [l for l in txt.split("\n") if "sandbox" in l][:1])
    ck("it reports mirror state", "mirror=" in txt,
       [l for l in txt.split("\n") if "sandbox" in l][:1])
    # the Forge was never opened in this run, so it has nothing to report;
    # close the report, open the Forge, and check the line appears
    pg.locator("#mClose").click(); pg.wait_for_timeout(400)
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3200)
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(500)
    pg.locator("#bugBtn").click(); pg.wait_for_timeout(800)
    txt2 = pg.locator("#bugText").input_value()
    ck("it reports the Forge's current card once the Forge has been opened",
       "forge card:" in txt2, [l for l in txt2.split("\n") if "forge" in l][:1])
    pg.locator("#mClose").click(); pg.wait_for_timeout(300)
    pg.locator("#bugBtn").click(); pg.wait_for_timeout(700)
    txt = pg.locator("#bugText").input_value()

    # --- the action history ---
    ck("it lists actions in order", "last" in txt and "actions" in txt)
    ck("it recorded navigation",
       "data-go" in txt or "go=poi" in txt or "SANDBOX" in txt.upper(), txt[-700:])
    ck("it recorded the tool choice inside the Sandbox",
       "tool=paint" in txt, txt[-700:])
    ck("it recorded the shape choice", "shape=hex" in txt, txt[-700:])
    ck("actions are timestamped relative to the start",
       "+0.0s" in txt or "+0." in txt, txt[-300:])

    # --- errors from inside a tool reach the shell's log ---
    ck("an error inside a tool is captured",
       "simulated tool failure" in txt, txt[:600])
    ck("it is labelled as coming from the tool",
       "[sandbox]" in txt, [l for l in txt.split("\n") if "simulated" in l][:1])
    ck("errors are counted", "errors captured:" in txt)

    # --- the buffer is capped ---
    capped = pg.evaluate("""()=>{
      for(var i=0;i<400;i++) logEvent('test','filler '+i);
      return LOG.length;
    }""")
    ck("the log is capped by count", capped==200, str(capped))
    ck("the oldest entries are dropped",
       pg.evaluate("()=>LOG[0].text")!="filler 0",
       pg.evaluate("()=>LOG[0].text"))

    # --- and it can be taken away ---
    ck("a download button is offered", pg.locator("#bugSave").count()==1)
    with pg.expect_download(timeout=8000) as dl:
        pg.locator("#bugSave").click()
    ck("the report downloads", dl.value.suggested_filename.startswith("KETER_bug_"),
       dl.value.suggested_filename)
    ck("nothing is sent anywhere", "no network calls" in txt or
       "not sent" in pg.locator("#modalBox").inner_text().lower() or
       "Nothing is sent" in pg.locator("#modalBox").inner_text())

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:2]))
    b.close()
srv.shutdown()
print(f"BUG REPORT PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
sys.exit(1 if bad else 0)
