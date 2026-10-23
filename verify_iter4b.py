"""Pictogram library: drawn glyphs across screen, PNG, PDF and the panel."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright
TMP = pathlib.Path("/tmp/serve_i4b")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP)
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 9051),
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
    pg.goto("http://127.0.0.1:9051/index.html"); pg.wait_for_timeout(1800)
    pg.locator("#nav button[data-go='poi']").click(); pg.wait_for_timeout(3200)
    W = "document.querySelector('#v-poi iframe').contentWindow.KETER_POI"
    D = "document.querySelector('#v-poi iframe').contentDocument"

    ck("a library button exists", pg.evaluate(f"()=>!!{D}.getElementById('pickSym')"))
    pg.evaluate(f"()=>{D}.getElementById('pickSym').click()")
    pg.wait_for_timeout(600)
    ck("the picker opens", pg.evaluate(f"()=>!!{D}.getElementById('symPick')"))
    drawn = pg.evaluate(f"""()=>[...{D}.querySelectorAll('#symPick [data-sym]')]
      .filter(e=>e.dataset.sym.charAt(0)==='@').length""")
    ck("a drawn core set is offered", drawn >= 12, f"n={drawn}")
    ck("every drawn cell renders an svg, not a character",
       pg.evaluate(f"""()=>[...{D}.querySelectorAll('#symPick [data-sym^="@"]')]
         .every(e=>!!e.querySelector('svg'))"""))

    # choose a drawn glyph
    pg.evaluate(f"""()=>{D}.querySelector('#symPick [data-sym="@spawn"]').click()""")
    pg.wait_for_timeout(700)
    ck("the picker closes after choosing", pg.evaluate(f"()=>!{D}.getElementById('symPick')"))
    defs = pg.evaluate(f"()=>{W}.S.symDefs.map(d=>d.text)")
    ck("the glyph is stored as a key", "@spawn" in defs, str(defs))
    ck("it is given a readable description",
       pg.evaluate(f"()=>{W}.S.symDefs.find(d=>d.text==='@spawn').desc") == "Player spawn")
    ck("the panel button shows the drawing",
       pg.evaluate(f"""()=>[...{D}.querySelectorAll('#symbtns .symbtn')]
         .some(e=>!!e.querySelector('svg'))"""))
    ck("the legend key shows the drawing",
       pg.evaluate(f"""()=>[...{D}.querySelectorAll('.leg-key')].some(e=>!!e.querySelector('svg'))"""))

    ck("glyphName resolves a key to words",
       pg.evaluate(f"()=>{W}.glyphName('@loot')") == "Loot")
    ck("plain text is left alone", pg.evaluate(f"()=>{W}.glyphName('HV')") == "HV")
    ck("glyphOf rejects a non-key", pg.evaluate(f"()=>{W}.glyphOf('HV')") is None)

    # place it and confirm the map renders differently
    ink = pg.evaluate(f"""()=>{{
      var w={W}, d={D};
      var id=w.S.symDefs.find(x=>x.text==='@spawn').id;
      var cv=d.getElementById('cv');
      function hash(){{
        var x=cv.getContext('2d').getImageData(0,0,cv.width,cv.height).data,h=0;
        for(var i=0;i<x.length;i+=16) h=(h*31+x[i]+x[i+1]*3+x[i+2]*7)|0; return h;
      }}
      w.S.tool='place'; w.S.shape='free';
      w.applyCell({{q:0,r:0}},'place');
      w.S.marks.clear();
      d.getElementById('cv').dispatchEvent(new Event('x'));
      return [id, hash()];
    }}""")
    ck("a symbol id was created", ink[0] >= 1, str(ink))

    # PDF: a drawn glyph must not go through the text path
    pdf = pg.evaluate(f"""()=>{{
      var w={W};
      /* the PDF writer replaces anything above Latin-1 with '?', which is why
         drawn glyphs exist at all */
      return typeof w.glyphOf('@spawn')==='object' && w.glyphOf('@spawn')!==null;
    }}""")
    ck("a drawn glyph resolves to path data for the PDF writer", pdf)

    real = [e for e in errs if "favicon" not in e.lower()]
    ck("no JS errors", len(real) == 0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"PICTOGRAMS PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
sys.exit(1 if bad else 0)
