"""Multi-mirror: one line, a cross, or six slices."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_mm")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9341),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""):
    (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:170]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:170]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9341/"); pg.wait_for_timeout(1900)
    pg.locator("#nav button[data-go='poi']").click(); pg.wait_for_timeout(3400)
    D="document.querySelector('#v-poi iframe').contentDocument"
    W="document.querySelector('#v-poi iframe').contentWindow.KETER_POI"

    ck("a symmetry button exists", pg.evaluate(f"()=>!!{D}.getElementById('qMirrorMode')"))
    ck("it is hidden until there is an axis",
       pg.evaluate(f"()=>{D}.getElementById('qMirrorMode').style.display")=="none")

    def images(mode, tile=(1,2)):
        return pg.evaluate(f"""()=>{{
          var w={W};
          w.S.mirror={{on:true,pivot:{{q:0,r:0}},axis:0,mode:'{mode}'}};
          return w.mirrorImages({tile[0]},{tile[1]}).length;
        }}""")
    ck("single gives one reflection", images('single')==1, images('single'))
    ck("cross gives three reflections, four images", images('cross')==3, images('cross'))
    ck("six gives five reflections, six images", images('six')==5, images('six'))

    ck("cross draws two planes",
       pg.evaluate(f"""()=>{{var w={W};
         w.S.mirror={{on:true,pivot:{{q:0,r:0}},axis:0,mode:'cross'}};
         return w.mirrorPlanes().length;}}""")==2)
    perp = pg.evaluate(f"""()=>{{var w={W};
      w.S.mirror={{on:true,pivot:{{q:0,r:0}},axis:0,mode:'cross'}};
      var a=w.mirrorPlanes();
      return Math.abs(Math.cos(a[0]-a[1]));}}""")
    ck("the cross planes are perpendicular", perp < 0.001, str(perp))

    # every image must be a real lattice tile, equidistant from the pivot
    geo = pg.evaluate(f"""()=>{{
      var w={W};
      w.S.mirror={{on:true,pivot:{{q:0,r:0}},axis:0,mode:'six'}};
      var C=w.center(0,0), P=w.center(1,2);
      var d0=Math.hypot(P.x-C.x,P.y-C.y);
      var worst=0, whole=true;
      w.mirrorImages(1,2).forEach(function(t){{
        if(t.q!==Math.round(t.q)||t.r!==Math.round(t.r)) whole=false;
        var R=w.center(t.q,t.r);
        worst=Math.max(worst, Math.abs(Math.hypot(R.x-C.x,R.y-C.y)-d0));
      }});
      return {{worst:+worst.toFixed(6), whole:whole}};
    }}""")
    ck("every image lands on a whole tile", geo["whole"] is True, str(geo))
    ck("every image is the same distance from the pivot",
       geo["worst"] < 0.0001, str(geo))

    # painting propagates to all of them
    painted = pg.evaluate(f"""()=>{{
      var w={W};
      w.S.hexes.clear();
      w.S.mirror={{on:true,pivot:{{q:0,r:0}},axis:0,mode:'six'}};
      w.applyCell({{q:1,r:2}},'place');
      return w.S.hexes.size;
    }}""")
    ck("placing one tile places all six", painted==6, str(painted))

    cross_paint = pg.evaluate(f"""()=>{{
      var w={W};
      w.S.hexes.clear();
      w.S.mirror={{on:true,pivot:{{q:0,r:0}},axis:0,mode:'cross'}};
      w.applyCell({{q:1,r:2}},'place');
      return w.S.hexes.size;
    }}""")
    ck("cross places four", cross_paint==4, str(cross_paint))

    erased = pg.evaluate(f"""()=>{{
      var w={W};
      w.applyCell({{q:1,r:2}},'erase');
      return w.S.hexes.size;
    }}""")
    ck("erasing removes all of them too", erased==0, str(erased))

    # a tile on the pivot is its own image in every mode
    pivot = pg.evaluate(f"""()=>{{
      var w={W}, out={{}};
      ['single','cross','six'].forEach(function(m){{
        w.S.hexes.clear();
        w.S.mirror={{on:true,pivot:{{q:0,r:0}},axis:0,mode:m}};
        w.applyCell({{q:0,r:0}},'place');
        out[m]=w.S.hexes.size;
      }});
      return out;
    }}""")
    ck("the pivot tile is placed once in every mode",
       pivot=={"single":1,"cross":1,"six":1}, str(pivot))

    # the control cycles and resets
    cyc = pg.evaluate(f"""()=>{{
      var d={D}, w={W}, out=[];
      w.S.mirror={{on:true,pivot:{{q:0,r:0}},axis:0,mode:'single'}}; w.syncMirrorBtn();
      for(var i=0;i<4;i++){{
        d.getElementById('qMirrorMode').click();
        out.push(w.S.mirror.mode);
      }}
      d.getElementById('qMirror').click();
      out.push('off:'+w.S.mirror.mode);
      return out;
    }}""")
    ck("the button cycles the three modes",
       cyc[:4]==["cross","six","single","cross"], str(cyc))
    ck("turning mirror off resets the mode", cyc[4]=="off:single", str(cyc))

    ck("no JS errors", len([e for e in errs if 'favicon' not in e.lower()])==0,
       "; ".join(errs[:3]))
    b.close()
srv.shutdown()
print(f"MULTI-MIRROR PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
