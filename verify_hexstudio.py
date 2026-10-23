"""Hex mode: the experimental Hex Studio, hex geometry, the tools and every
symmetry on hex pixels, hex card art holding its art box, a hexagon token
filling its board tile, and hex pictures exported as PDFs."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_hex")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
comp=json.load(open("compendium_full.json"))
for x in comp["cards"]:
    if x["name"]=="Test Warden": x["pixelToken"]="px_hex_tok"
json.dump(comp,open(TMP/"compendium.json","w"))
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9981),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))
with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},device_scale_factor=2,accept_downloads=True).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.goto("http://127.0.0.1:9981/"); pg.wait_for_timeout(2200)

    # ---- geometry ----
    r=pg.evaluate("""()=>{ var P=KETER_PX, out=[];
      [6,9,12].forEach(function(n){ ['pointy','flat'].forEach(function(o){ var p=P.blankHexagon(n,o), L=P.hexLayout(p), c=0, found=true;
        for(var i=0;i<L.valid.length;i++){ if(!L.valid[i]) continue; c++; if(P.hexCellAt(p,L.cx[i],L.cy[i])!==i) found=false; }
        out.push({n:n,o:o,cells:c,want:3*n*n-3*n+1,found:found}); }); });
      return out; }""")
    ck("hexagon canvases have exactly the right number of hexes", all(x["cells"]==x["want"] for x in r), r)
    ck("and tapping any hex finds that hex, in both orientations", all(x["found"] for x in r))
    r=pg.evaluate("""()=>{ var P=KETER_PX, out=true; [0.9,1.62].forEach(function(h){ ['pointy','flat'].forEach(function(o){ [32,40,48].forEach(function(n){
        var a=P.blankHexArt(n,h,o), B=P.hexLayout(a).bounds; if(B.h/B.w>h/2.27+1e-6 || a.w!==n) out=false; }); }); }); return out; }""")
    ck("hex card art is as wide as chosen and never taller than its art box", r)

    # ---- the Hex Studio ----
    ck("the Hex Studio has its own tile", pg.locator('.lt[data-page="hexstudio"]').count()==1)
    pg.locator('.lt[data-page="hexstudio"]').click(); pg.wait_for_timeout(500)
    ck("it opens the studio in hex mode", "HEX STUDIO" in pg.locator("#v-studio.on .pxh").inner_text().upper())
    pg.locator("#pxNewTok").click(); pg.wait_for_timeout(300)
    ck("its new tokens are hex only", pg.locator("[data-pxside]").count()==3 and pg.locator("[data-pxsize]").count()==0)
    ck("with pointy-top or flat-top pixels", pg.locator("[data-pxorient]").count()==2)
    pg.locator('[data-pxorient="flat"]').click(); pg.wait_for_timeout(100)
    pg.locator('[data-pxside="6"]').click(); pg.wait_for_timeout(700)
    s=pg.evaluate("()=>{var s=KETER_STUDIO.state(); return {grid:s.grid.name, orient:s.pic.orient, shape:s.pic.shape, side:s.pic.side};}")
    ck("choosing one opens a hexagon canvas of that size and orientation", s=={"grid":"hex","orient":"flat","shape":"hexagon","side":6}, s)

    def tap_offset(dx,dy,col):
        pg.locator("#pxCanvas").scroll_into_view_if_needed()
        box=pg.locator("#pxCanvas").bounding_box()
        pt=pg.evaluate("""(a)=>{ var s=KETER_STUDIO.state(), v=KETER_STUDIO.view(), c=s.grid.symCentre, L=s.grid.layout, best=-1, bd=1e9;
          for(var i=0;i<L.valid.length;i++){ if(!L.valid[i]) continue; var d=Math.hypot(L.cx[i]-c.x-a[0], L.cy[i]-c.y-a[1]); if(d<bd){bd=d;best=i;} }
          return {x:v.x+L.cx[best]*v.z, y:v.y+L.cy[best]*v.z}; }""", [dx,dy])
        pg.mouse.click(box["x"]+pt["x"], box["y"]+pt["y"]); pg.wait_for_timeout(150)
    count=lambda v: pg.evaluate(f"()=>KETER_STUDIO.state().buf.filter(function(x){{return x==={v};}}).length")
    clear=lambda: pg.evaluate("()=>{var s=KETER_STUDIO.state(); s.buf.fill(0); s.pic.frames[0].layers[0].px=KETER_PX.encode(s.buf); s.mirror='off';}")
    pg.locator("#pxPalTog").click(); pg.locator('.pxgrid [data-pxcol="134"]').click()
    tap_offset(3,0,134); ck("a tap paints one hex", count(134)==1)
    modes=[]
    for want,label in (("lr",2),("tb",2),("both",4),("k3",3),("k6",6)):
        clear(); pg.evaluate(f"()=>{{KETER_STUDIO.state().mirror='{want}';}}")
        tap_offset(3,1.2,134); modes.append((want,count(134),label))
    for m,got,want in modes:
        ck(f"symmetry '{m}' paints {want} hexes", got==want, got)
    # the reflecting kaleidoscope: twelve copies, or six on a mirror line
    ck("symmetry includes a Kaleidoscope mode", "kal" in pg.evaluate("()=>KETER_STUDIO.state().grid.modes"))
    clear(); pg.evaluate("()=>{KETER_STUDIO.state().mirror='kal';}")
    tap_offset(4.5,0.866,134)
    ck("a kaleidoscope tap off the mirror lines paints twelve hexes", count(134)==12, count(134))
    r=pg.evaluate("""()=>{ var s=KETER_STUDIO.state(), L=s.grid.layout, c=s.grid.symCentre, pts=[];
      s.buf.forEach(function(v,i){ if(v) pts.push([Math.round((L.cx[i]-c.x)*100), Math.round((L.cy[i]-c.y)*100)]); });
      var has=function(x,y){ return pts.some(function(p){ return Math.abs(p[0]-x)<3 && Math.abs(p[1]-y)<3; }); };
      return pts.every(function(p){ return has(-p[0],p[1]) && has(p[0],-p[1]); }); }""")
    ck("and the pattern mirrors onto itself", r)
    clear(); pg.evaluate("()=>{KETER_STUDIO.state().mirror='kal';}")
    tap_offset(3,1.732,134)
    ck("a tap on a mirror line paints six, as its reflection is itself", count(134)==6, count(134))
    clear()
    pg.evaluate("()=>{ var s=KETER_STUDIO.state(), L=s.grid.layout, a=-1,b2=-1;"
                "for(var i=0;i<L.valid.length;i++){ if(L.valid[i]){ if(a<0) a=i; b2=i; } }"
                "var line=s.grid.line(a,b2); line.forEach(function(k){ s.buf[k]=134; }); window._line=line; }")
    r=pg.evaluate("""()=>{ var s=KETER_STUDIO.state(), l=window._line, joined=true;
      for(var k=1;k<l.length;k++) if(s.grid.neighbours(l[k-1]).indexOf(l[k])<0) joined=false; return {n:l.length, joined:joined}; }""")
    ck("a line across the canvas is an unbroken chain of neighbouring hexes", r["joined"] and r["n"]>5, r)
    clear(); pg.locator('.pxgrid [data-pxcol="37"]').click(); pg.locator('[data-pxtool="fill"]').click()
    tap_offset(0,0,37)
    ck("fill covers the whole hexagon, and nothing outside it", count(37)==91, count(37))
    pg.locator("#pxUndo").click(); pg.wait_for_timeout(150)
    ck("undo works on hex pictures", count(37)==0)
    pg.locator("#pxRedo").click(); pg.wait_for_timeout(900)
    pg.evaluate("()=>KETER_STUDIO.flushSave()")
    ck("a hex picture saves into the library", pg.evaluate("()=>{var p=KETER_PX.get(KETER_STUDIO.state().id); return !!p && p.grid==='hex' && p.shape==='hexagon';}"))

    # ---- PDF ----
    txt=pg.evaluate("()=>KETER_STUDIO.pdfText()")
    ck("a hex PDF draws each hex as a six-sided shape", txt.count(" h f")==91, txt.count(" h f"))
    ck("and is captioned by hexes per side", "6 hex pixels per side" in txt)

    # ---- the board: a hexagon token fills its tile's hexagon ----
    pg.evaluate("""()=>{ var s=KETER_STUDIO.state(); var p=JSON.parse(JSON.stringify(s.pic)); p.frames[0].layers[0].px=KETER_PX.encode(new Uint8Array(p.w*p.h).fill(134)); KETER_PX.put(p,'px_hex_tok'); }""")
    pg.evaluate("()=>{ localStorage.setItem('keter-app-simdebug','1'); localStorage.removeItem('keter-app-sim'); }")
    pg.reload(); pg.wait_for_timeout(2200)
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(300)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(500)
    pg.evaluate("()=>simDebugStart('TEST \u00b7 Sight Lines')"); pg.wait_for_timeout(2500)
    r=pg.evaluate("""()=>{ SIM_UI.handOpen=false; renderSim(); simDraw();
      var w=SIM.units.filter(function(u){return u.name==='Test Warden';})[0], cv=document.getElementById('simcanvas'), d=SIM_VIEW.dpr, s=SIM_VIEW.size;
      var cx=(SIM_VIEW.ox+s*Math.sqrt(3)*(w.pos.q+w.pos.r/2)), cy=(SIM_VIEW.oy+s*1.5*w.pos.r), g=cv.getContext('2d');
      var at=function(dx,dy){ var p=g.getImageData(Math.round((cx+dx)*d),Math.round((cy+dy)*d),1,1).data; return [p[0],p[1],p[2]]; };
      return {centre:at(0,0), nearEdge:at(0,-s*0.6), tok:!!simTokenFor(w)}; }""")
    ck("a hexagon token is found for its card", r["tok"])
    # colour 134 is electric cyan; the edge of a hex blends very slightly
    near=lambda a,b: sum(abs(x-y) for x,y in zip(a,b))<60
    ck("and fills the Unit's hexagon, to near its edge", near(r["centre"],[34,240,255]) and near(r["nearEdge"],[34,240,255]), r)

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"HEX STUDIO PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
