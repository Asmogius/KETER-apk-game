"""Pixel Studio, stage three: lines, rectangles and circles (outline or filled),
the dither brush (two colours, or over what is there; checkerboard on squares,
thirds and rows on hexes), selections (move, flip, turn, copy, paste, delete),
and the layer panel — with every layer change undoable."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_studio3")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9983),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d not in ("",None) and not c else ""))

HELP=r"""()=>{
  window.T={
    S:function(){ return KETER_STUDIO.state(); },
    xy:function(i){ var s=KETER_STUDIO.state(), v=KETER_STUDIO.view(), c=s.grid.centre(i,s.pic); return {x:v.x+c.x*v.z, y:v.y+c.y*v.z}; },
    idx:function(x,y){ return y*KETER_STUDIO.state().pic.w+x; },
    drag:function(a,b,steps){ var P=KETER_STUDIO._paint, A=T.xy(a), B=T.xy(b); steps=steps||6;
      P.down(A.x,A.y); for(var k=1;k<=steps;k++) P.move(A.x+(B.x-A.x)*k/steps, A.y+(B.y-A.y)*k/steps); P.up(); },
    tap:function(a){ var P=KETER_STUDIO._paint, A=T.xy(a); P.down(A.x,A.y); P.up(); },
    count:function(v){ return KETER_STUDIO.state().buf.filter(function(x){ return x===v; }).length; },
    cells:function(v){ var out=[]; KETER_STUDIO.state().buf.forEach(function(x,i){ if(x===v) out.push(i); }); return out; },
    flat:function(){ var s=KETER_STUDIO.state(); return KETER_PX.flatten(s.pic,0); },
    clear:function(){ var s=KETER_STUDIO.state(); s.buf.fill(0); s.pic.frames[0].layers[s.layer].px=KETER_PX.encode(s.buf); s.pic.flat=''; s.sel=null; s.mirror='off'; }
  }; return true; }"""

with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},device_scale_factor=2).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("dialog",lambda d:d.accept("Renamed"))
    pg.goto("http://127.0.0.1:9983/"); pg.wait_for_timeout(2200)
    pg.locator('.lt[data-page="studio"]').click(); pg.wait_for_timeout(500)
    pg.locator("#pxNewTok").click(); pg.locator('[data-pxsize="32"]').click(); pg.wait_for_timeout(700)
    pg.evaluate(HELP)
    tool=lambda t: (pg.locator(f'[data-pxtool="{t}"]').click(), pg.wait_for_timeout(100))
    E=pg.evaluate
    ck("the tool bar has every stage-three tool", all(pg.locator(f'[data-pxtool="{t}"]').count()==1 for t in ("line","rect","circle","dither","select")))
    E("()=>{ T.S().colour=134; }")

    # ---- lines ----
    tool("line"); E("()=>T.drag(T.idx(2,2),T.idx(12,6))")
    r=E("()=>({n:T.count(134), a:T.S().buf[T.idx(2,2)], b:T.S().buf[T.idx(12,6)]})")
    ck("a line joins its two ends", r["a"]==134 and r["b"]==134, r)
    ck("with one pixel per step along its length", r["n"]==11, r)
    ck("and dragging redraws it rather than leaving a trail", E("()=>{ T.clear(); T.drag(T.idx(2,2),T.idx(20,2),10); return T.count(134); }")==19)

    # ---- rectangles and circles ----
    tool("rect")
    ck("rectangles offer outline or filled", pg.locator('[data-pxfill]').count()==2)
    E("()=>{ T.clear(); T.drag(T.idx(1,1),T.idx(6,4)); }")
    ck("an outline rectangle is just its edge", E("()=>T.count(134)")==16, E("()=>T.count(134)"))
    pg.locator('[data-pxfill="1"]').click(); pg.wait_for_timeout(80)
    E("()=>{ T.clear(); T.drag(T.idx(1,1),T.idx(6,4)); }")
    ck("a filled rectangle is solid", E("()=>T.count(134)")==24, E("()=>T.count(134)"))
    tool("circle")
    filled=E("()=>{ T.clear(); T.drag(T.idx(4,4),T.idx(20,20)); return T.cells(134); }")
    pg.locator('[data-pxfill="0"]').click(); pg.wait_for_timeout(80)
    outline=E("()=>{ T.clear(); T.drag(T.idx(4,4),T.idx(20,20)); return T.cells(134); }")
    ck("a filled circle is solid and round", len(filled)>150 and E("()=>{ T.clear(); T.drag(T.idx(4,4),T.idx(20,20)); return T.S().buf[T.idx(4,4)]; }")==0, len(filled))
    ck("its outline is the edge of the same circle", 0<len(outline)<len(filled) and set(outline)<=set(filled), (len(outline),len(filled)))
    ck("undo takes a whole shape back", E("()=>{ KETER_STUDIO._paint.undo(); return T.count(134); }")==0)

    # ---- dither ----
    tool("dither")
    ck("dither offers two colours or over what's there", pg.locator('[data-pxdm]').count()==2)
    # v12.4: the patterns are named by coverage; 50% is the checkerboard
    ck("on square pixels it is a checkerboard", pg.locator('[data-pxdp="50"].on').count()==1)
    E("()=>{ T.clear(); var s=T.S(); s.ditherMode='two'; s.colour=134; s.colour2=5; }")
    E("()=>T.drag(T.idx(0,10),T.idx(9,10),9)")
    r=E("()=>{ var s=T.S(), row=[]; for(var x=0;x<10;x++) row.push(s.buf[T.idx(x,10)]); return row; }")
    ck("two-colour dither alternates the two colours", r==[134,5]*5 or r==[5,134]*5, r)
    E("()=>{ T.clear(); var s=T.S(); for(var x=0;x<10;x++) s.buf[T.idx(x,12)]=40; s.ditherMode='over'; s.colour=134; }")
    E("()=>T.drag(T.idx(0,12),T.idx(9,12),9)")
    r=E("()=>{ var s=T.S(), row=[]; for(var x=0;x<10;x++) row.push(s.buf[T.idx(x,12)]); return row; }")
    ck("dither over what's there leaves every other pixel as it was", sorted(set(r))==[40,134] and r.count(134)==5, r)

    # ---- selections ----
    tool("select")
    E("()=>{ T.clear(); var s=T.S(); for(var y=2;y<5;y++) for(var x=2;x<6;x++) s.buf[T.idx(x,y)]=134; s.buf[T.idx(2,2)]=5; s.pic.frames[0].layers[s.layer].px=KETER_PX.encode(s.buf); }")
    E("()=>T.drag(T.idx(1,1),T.idx(7,6))")
    ck("dragging selects", E("()=>!!T.S().sel && T.S().sel.items.length>0"))
    ck("the selection offers flip, turn, copy, paste, delete and done",
       all(pg.locator(f'[data-pxsel="{a}"]').count()==1 for a in ("fliph","flipv","rotate","copy","paste","delete","done")))
    E("()=>T.drag(T.idx(3,3),T.idx(13,3),8)")
    pg.locator('[data-pxsel="done"]').click(); pg.wait_for_timeout(100)
    r=E("()=>({moved:T.S().buf[T.idx(12,2)], left:T.S().buf[T.idx(2,2)], block:T.count(134)+T.count(5)})")
    ck("dragging inside moves it by whole pixels, leaving the old spot empty", r["moved"]==5 and r["left"]==0 and r["block"]==12, r)
    E("()=>T.drag(T.idx(11,1),T.idx(16,5))"); pg.locator('[data-pxsel="fliph"]').click(); pg.locator('[data-pxsel="done"]').click(); pg.wait_for_timeout(100)
    ck("flip mirrors the block in place", E("()=>T.S().buf[T.idx(15,2)]")==5 and E("()=>T.S().buf[T.idx(12,2)]")==134)
    E("()=>T.drag(T.idx(11,1),T.idx(16,5))"); pg.locator('[data-pxsel="rotate"]').click(); pg.locator('[data-pxsel="done"]').click(); pg.wait_for_timeout(100)
    ck("a quarter-turn keeps every pixel", E("()=>T.count(134)+T.count(5)")==12)
    E("()=>T.drag(T.idx(10,0),T.idx(18,7))"); pg.locator('[data-pxsel="copy"]').click(); pg.wait_for_timeout(80)
    pg.locator('[data-pxsel="done"]').click(); pg.locator('[data-pxsel="paste"]').click(); pg.wait_for_timeout(80)
    E("()=>{ var s=T.S(), a=s.sel.items[0]; T.drag(T.S().grid.cellAt(a.x,a.y,32,32), T.S().grid.cellAt(a.x,a.y+10,32,32),6); }")
    pg.locator('[data-pxsel="done"]').click(); pg.wait_for_timeout(100)
    ck("copy and paste make a second copy", E("()=>T.count(134)+T.count(5)")==24, E("()=>T.count(134)+T.count(5)"))
    E("()=>T.drag(T.idx(0,11),T.idx(31,31))")   # the pasted copy sits on rows 12 to 15
    pg.locator('[data-pxsel="delete"]').click(); pg.wait_for_timeout(100)
    ck("delete clears the selection", E("()=>T.count(134)+T.count(5)")==12)
    ck("and undo brings it back", E("()=>{ KETER_STUDIO._paint.undo(); return T.count(134)+T.count(5); }")==24)

    # ---- layers ----
    pg.locator("#pxLayTog").click(); pg.wait_for_timeout(100)
    Ls="()=>T.S().pic.frames[0].layers"
    pg.locator("#pxLayAdd").click(); pg.wait_for_timeout(100)
    ck("a layer can be added, and becomes the one drawn on", E(f"({Ls})().length")==2 and E("()=>T.S().layer")==1)
    tool("pencil"); E("()=>{ T.S().colour=10; T.tap(T.idx(0,0)); }")
    ck("drawing goes onto the new layer", E("()=>T.flat()[0]")==10 and E("()=>KETER_PX.decode(T.S().pic.frames[0].layers[0].px,1024)[0]")==0)
    pg.locator('[data-pxvis="1"]').click(); pg.wait_for_timeout(80)
    ck("hiding a layer takes it out of the picture", E("()=>T.flat()[0]")==0)
    pg.locator('[data-pxvis="1"]').click(); pg.locator('[data-pxlock="1"]').click(); pg.wait_for_timeout(80)
    E("()=>{ T.S().colour=11; T.tap(T.idx(1,0)); }")
    ck("a locked layer refuses to be drawn on", E("()=>T.flat()[1]")==0)
    pg.locator('[data-pxlock="1"]').click(); pg.wait_for_timeout(80)
    E("()=>{ var s=T.S(); for(var x=0;x<8;x++) s.buf[T.idx(x,20)]=140; s.pic.frames[0].layers[1].px=KETER_PX.encode(s.buf); s.pic.flat=''; }")
    pg.locator("#pxMode").select_option("dither"); pg.wait_for_timeout(80)
    pg.locator("#pxOpac").fill("50"); pg.locator("#pxOpac").dispatch_event("change"); pg.wait_for_timeout(100)
    r=E("()=>{ var f=T.flat(), row=[]; for(var x=0;x<8;x++) row.push(f[T.idx(x,20)]); return row; }")
    ck("half opacity in dither mode saves as a checkerboard", r.count(140)==4, r)
    n_undo=E("()=>T.S().undo.length")
    pg.locator('[data-pxdown="1"]').click(); pg.wait_for_timeout(80)
    ck("a layer can be moved down", E(f"({Ls})()[0].name")=="Layer 2")
    pg.locator("#pxLayDup").click(); pg.wait_for_timeout(80)
    ck("duplicated", E(f"({Ls})().length")==3)
    pg.locator("#pxLayRen").click(); pg.wait_for_timeout(80)
    ck("renamed", "Renamed" in E(f"({Ls})().map(function(l){{return l.name;}}).join(',')"))
    pg.locator("#pxLayDel").click(); pg.wait_for_timeout(80)
    ck("and deleted", E(f"({Ls})().length")==2)
    ck("layer changes keep the undo history", E("()=>T.S().undo.length")>n_undo)
    E("()=>KETER_STUDIO._paint.undo()")
    ck("undo brings a deleted layer back", E(f"({Ls})().length")==3)
    for _ in range(3): E("()=>KETER_STUDIO._paint.undo()")   # the rename, the duplicate, then the move
    ck("and puts a moved layer back where it was", E(f"({Ls})()[1].name")=="Layer 2")
    E("()=>KETER_STUDIO._paint.redo()")
    ck("redo moves it again", E(f"({Ls})()[0].name")=="Layer 2")

    # ---- the same tools on hex pixels ----
    pg.locator("#pxBack").click(); pg.wait_for_timeout(400)
    pg.locator("#pxNewTok").click(); pg.locator('[data-pxorient="flat"]').click(); pg.locator('[data-pxside="9"]').click(); pg.wait_for_timeout(700)
    pg.evaluate(HELP); E("()=>{ T.S().colour=134; }")
    tool("select"); ck("on hex pixels there is no quarter-turn", pg.locator('[data-pxsel="rotate"]').count()==0)
    tool("rect"); pg.locator('[data-pxfill="1"]').click()
    r=E("""()=>{ var s=T.S(), L=s.grid.layout, v=[]; for(var i=0;i<L.valid.length;i++) if(L.valid[i]) v.push(i);
       T.drag(v[20],v[160]); var c=T.cells(134), joined=true;
       c.forEach(function(k){ if(c.length>1 && !s.grid.neighbours(k).some(function(n){ return c.indexOf(n)>=0; })) joined=false; });
       return {n:c.length, joined:joined}; }""")
    ck("a filled rectangle on hexes is one solid block", r["n"]>10 and r["joined"], r)
    tool("dither")
    ck("hex dither offers a third, half rows, and two-thirds", pg.locator('[data-pxhp]').count()==3)
    shares={}
    for pat in ("third","rows","twothirds"):
        pg.locator(f'[data-pxhp="{pat}"]').click()
        shares[pat]=E("""()=>{ T.clear(); var s=T.S(); s.ditherMode='over'; s.colour=134;
          var L=s.grid.layout, n=0; for(var i=0;i<L.valid.length;i++){ if(!L.valid[i]) continue; n++; T.tap(i); }
          return T.count(134)/n; }""")
    ck("a third covers about a third", 0.28<shares["third"]<0.39, shares)
    ck("half rows cover about half", 0.42<shares["rows"]<0.58, shares)
    ck("two-thirds covers about two-thirds", 0.61<shares["twothirds"]<0.72, shares)

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"STUDIO 3 PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
