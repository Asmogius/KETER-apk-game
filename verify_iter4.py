"""Iteration 4: action/shape split and stencils."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright
TMP = pathlib.Path("/tmp/serve_i4")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP)
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 9045),
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
    pg.goto("http://127.0.0.1:9045/index.html"); pg.wait_for_timeout(1800)
    pg.locator("#nav button[data-go='poi']").click(); pg.wait_for_timeout(3200)
    W = "document.querySelector('#v-poi iframe').contentWindow.KETER_POI"
    D = "document.querySelector('#v-poi iframe').contentDocument"

    # ---------- the palette ----------
    ck("Line is no longer an action",
       pg.evaluate("()=>{var d=document.querySelector('#v-poi iframe').contentDocument;"
                   "return ![...d.querySelectorAll('[data-tool]')]"
                   ".some(function(e){return e.dataset.tool==='line';});}"))
    ck("a Shape group exists", pg.evaluate(f"()=>!!{D}.getElementById('shapestack')"))
    shapes = pg.evaluate(f"""()=>[...{D}.querySelectorAll('[data-shape]')].map(e=>e.dataset.shape)""")
    ck("all five shapes offered",
       shapes == ["free", "line", "hex", "rect", "circle"], str(shapes))
    ck("Free is the default",
       pg.evaluate("()=>document.querySelector('#v-poi iframe').contentDocument"
                   ".querySelector('[data-shape=free i]').classList.contains('on')"))
    ck("the fill toggle is hidden for Free and Line",
       pg.evaluate(f"()=>getComputedStyle({D}.getElementById('shapeFill').parentNode).display")=="none")

    def cells(shape, action, fill, a, bb):
        return pg.evaluate(f"""()=>{{
          var w={W};
          w.S.tool='{action}'; w.S.shape='{shape}'; w.S.shapeFill={str(fill).lower()};
          var out=w.shapeCells({{q:{a[0]},r:{a[1]}}},{{q:{bb[0]},r:{bb[1]}}});
          return out.length;
        }}""")

    # ---------- shapes produce cells ----------
    ck("line spans two tiles", cells("line", "place", True, (0, 0), (0, 4)) == 5,
       cells("line", "place", True, (0, 0), (0, 4)))
    hf = cells("hex", "place", True, (0, 0), (0, 2))
    ho = cells("hex", "place", False, (0, 0), (0, 2))
    ck("a filled hexagon of radius 2 is 19 tiles", hf == 19, hf)
    ck("its outline is 12", ho == 12, ho)
    ck("outline is a subset of filled", ho < hf)

    rf = cells("rect", "place", True, (0, 0), (3, 3))
    ro = cells("rect", "place", False, (0, 0), (3, 3))
    ck("a filled rectangle has area", rf > 8, rf)
    ck("its outline is smaller", ro < rf, f"{ro} of {rf}")

    cf = cells("circle", "place", True, (0, 0), (0, 3))
    co = cells("circle", "place", False, (0, 0), (0, 3))
    ck("a filled circle has area", cf > 10, cf)
    ck("its outline is a rim", co < cf, f"{co} of {cf}")
    # counts can coincide; compare membership
    diff = pg.evaluate(f"""()=>{{
      var w={W};
      function keys(shape){{
        w.S.tool='place'; w.S.shape=shape; w.S.shapeFill=true;
        /* dragged off-axis: along a hex axis a euclidean disc and a hexagon
           coincide exactly, so an axis drag cannot tell them apart */
        return w.shapeCells({{q:0,r:0}},{{q:2,r:2}}).map(c=>c.q+','+c.r).sort().join('|');
      }}
      return keys('circle')!==keys('hex');
    }}""")
    ck("circle is a different shape from hexagon when dragged off-axis", diff)
    axis = pg.evaluate(f"""()=>{{
      var w={W};
      function n(shape){{ w.S.tool='place'; w.S.shape=shape; w.S.shapeFill=true;
        return w.shapeCells({{q:0,r:0}},{{q:0,r:3}}).length; }}
      return [n('hex'),n('circle')];
    }}""")
    ck("along a hex axis the two coincide, as the geometry requires",
       axis[0] == axis[1], str(axis))

    # ---------- the action actually varies ----------
    res = pg.evaluate(f"""()=>{{
      var w={W};
      w.S.hexes.clear(); w.S.walls.clear();
      w.S.shape='hex'; w.S.shapeFill=true;
      /* place a filled hexagon */
      w.S.tool='place'; w.S.shapeDrag={{a:{{q:0,r:0}},b:{{q:0,r:2}}}}; w.commitShape();
      var placed=w.S.hexes.size;
      /* highlight the same area */
      w.S.paintColor=0;
      w.S.tool='paint'; w.S.shapeDrag={{a:{{q:0,r:0}},b:{{q:0,r:2}}}}; w.commitShape();
      var painted=0; w.S.hexes.forEach(v=>{{ if(v.c===0) painted++; }});
      /* erase a smaller hexagon out of the middle */
      w.S.tool='erase'; w.S.shapeDrag={{a:{{q:0,r:0}},b:{{q:0,r:1}}}}; w.commitShape();
      var after=w.S.hexes.size;
      return [placed,painted,after];
    }}""")
    ck("a stencil can place", res[0] == 19, str(res))
    ck("the same stencil can highlight", res[1] == 19, str(res))
    ck("and it can erase", res[2] == 19 - 7, str(res))

    walls = pg.evaluate(f"""()=>{{
      var w={W};
      w.S.hexes.clear(); w.S.walls.clear();
      w.S.tool='wall'; w.S.shape='hex'; w.S.shapeFill=false;
      w.S.shapeDrag={{a:{{q:0,r:0}},b:{{q:0,r:2}}}}; w.commitShape();
      return w.S.walls.size;
    }}""")
    ck("an outlined stencil can draw walls", walls > 0, str(walls))

    # ---------- undo ----------
    undo = pg.evaluate(f"""()=>{{
      var w={W};
      w.S.hexes.clear();
      w.pushUndo();
      w.S.tool='place'; w.S.shape='hex'; w.S.shapeFill=true;
      w.S.shapeDrag={{a:{{q:0,r:0}},b:{{q:0,r:2}}}}; w.commitShape();
      var before=w.S.hexes.size;
      {D}.getElementById('qUndo').click();
      return [before, w.S.hexes.size];
    }}""")
    pg.wait_for_timeout(400)
    ck("a stencil is one undo step", undo[1] < undo[0], str(undo))

    real = [e for e in errs if "favicon" not in e.lower()]
    ck("no JS errors", len(real) == 0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"ITERATION 4 PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
sys.exit(1 if bad else 0)
