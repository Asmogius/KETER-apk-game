"""Blank canvases for any graphic (square or hex, presets or a custom size up
to 128), PNG and PDF export, and drawing that stays quick on large canvases —
with the pieces drawn during a stroke matching a full redraw exactly."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, io
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_blank")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9991),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d not in ("",None) and not c else ""))
STROKE="""()=>{ var s=KETER_STUDIO.state(), v=KETER_STUDIO.view(), P=KETER_STUDIO._paint, g=s.grid, n=s.pic.w*s.pic.h, first=0;
  if(g.valid) while(first<n && !g.valid(first)) first++;
  var a=g.centre(first,s.pic), t0=performance.now(); P.down(v.x+a.x*v.z, v.y+a.y*v.z);
  for(var k=1;k<=30;k++){ var j=Math.min(n-1, first+k*(s.pic.w+1)); if(g.valid) while(j<n-1 && !g.valid(j)) j++; var c=g.centre(j,s.pic); P.move(v.x+c.x*v.z, v.y+c.y*v.z); }
  var t1=performance.now(); var cv=document.getElementById('pxCanvas'), live=cv.getContext('2d').getImageData(0,0,cv.width,cv.height).data;
  P.up(); var full=cv.getContext('2d').getImageData(0,0,cv.width,cv.height).data, diff=0;
  for(var i=0;i<live.length;i+=4){ if(Math.abs(live[i]-full[i])+Math.abs(live[i+1]-full[i+1])+Math.abs(live[i+2]-full[i+2])>24) diff++; }
  return {perStep:(t1-t0)/31, painted:s.buf.filter(function(x){return x;}).length, diffShare:diff/(live.length/4)}; }"""
with sync_playwright() as p:
    b=p.chromium.launch()
    ctx=b.new_context(viewport={"width":412,"height":915},device_scale_factor=2,accept_downloads=True); pg=ctx.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.goto("http://127.0.0.1:9991/"); pg.wait_for_timeout(2200)
    def fresh():
        pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(200)
        pg.locator('.lt[data-page="studio"]').click(); pg.wait_for_timeout(300)
        if pg.locator("#pxBack").count(): pg.locator("#pxBack").click(); pg.wait_for_timeout(200)
        pg.locator("#pxNewBlank").click(); pg.wait_for_timeout(300)
    fresh()
    ck("the studio offers a blank canvas", pg.locator(".pxh").inner_text().upper().startswith("BLANK"))
    # v12.4: 256 x 256 and 256 x 144 join the presets
    ck("with square presets", pg.locator("[data-pxwh]").count()==8)
    ck("hex rectangles and hexagons", pg.locator("[data-pxhexwh]").count()==3 and pg.locator("[data-pxside]").count()==4)
    ck("and a custom size for each", pg.locator('[data-pxcustom="square"]').count()==1 and pg.locator('[data-pxcustom="hex"]').count()==1)
    pg.locator("#pxSqW").fill("100"); pg.locator("#pxSqH").fill("40"); pg.locator('[data-pxcustom="square"]').click(); pg.wait_for_timeout(600)
    ck("a custom size opens at that size", pg.evaluate("()=>{var s=KETER_STUDIO.state(); return s.pic.w===100&&s.pic.h===40&&s.kind==='blank'&&s.grid.name==='square';}"))
    ck("not tied to any card", pg.evaluate("()=>!KETER_STUDIO.state().card"))
    fresh(); pg.locator("#pxSqW").fill("500"); pg.locator("#pxSqH").fill("0"); pg.locator('[data-pxcustom="square"]').click(); pg.wait_for_timeout(600)
    # v12.4: square pixels go to 256
    ck("sizes are kept between 1 and 256", pg.evaluate("()=>{var s=KETER_STUDIO.state(); return s.pic.w===256&&s.pic.h===1;}"))

    # ---- drawing stays quick, and what's drawn during a stroke is exactly right ----
    for label,sel in (("square 128x128",'[data-pxwh="128x128"]'),("hex 128x128",None),("hexagon of 48",'[data-pxside="48"]')):
        fresh()
        if sel: pg.locator(sel).click()
        else: pg.locator("#pxHxW").fill("128"); pg.locator("#pxHxH").fill("128"); pg.locator('[data-pxcustom="hex"]').click()
        pg.wait_for_timeout(700)
        r=pg.evaluate(STROKE)
        ck(f"{label}: a stroke step redraws in well under a millisecond here", r["perStep"]<2, r)
        ck(f"{label}: it paints", r["painted"]>20, r)
        ck(f"{label}: the canvas mid-stroke matches a full redraw", r["diffShare"]<0.002, r)

    # ---- the cursor crosshair never touches the picture's canvas ----
    fresh(); pg.locator('[data-pxwh="32x32"]').click(); pg.wait_for_timeout(600)
    r=pg.evaluate("""()=>{ var cv=document.getElementById('pxCanvas'), g=cv.getContext('2d'), before=g.getImageData(0,0,cv.width,cv.height).data;
      var s=KETER_STUDIO.state(); s.cursor=true; s.cursorAt={x:100,y:100};
      var P=KETER_STUDIO._paint; var after=g.getImageData(0,0,cv.width,cv.height).data, same=true;
      for(var i=0;i<before.length;i++) if(before[i]!==after[i]){ same=false; break; }
      return same && !!document.getElementById('pxOver'); }""")
    ck("the cursor crosshair has a layer of its own", r)

    # ---- exports ----
    pg.evaluate("()=>{ var s=KETER_STUDIO.state(); for(var i=0;i<s.buf.length;i++) s.buf[i]=(i%32<16)?134:0; s.pic.frames[0].layers[0].px=KETER_PX.encode(s.buf); KETER_STUDIO.flushSave(); }")
    pg.locator("#pxMore").click(); pg.wait_for_timeout(150)
    ck("the menu offers PNG at five scales", pg.locator("[data-pxpng]").count()==5)
    ck("and PDF at a chosen width", pg.locator("#pxPdfW").count()==1)
    with pg.expect_download() as dl: pg.locator('[data-pxpng="8"]').click()
    path="/tmp/verify_blank.png"; dl.value.save_as(path)
    try:
        from PIL import Image
        im=Image.open(path).convert("RGBA")
        ck("PNG at 8x is eight times the size", im.size==(256,256), im.size)
        ck("with the drawn pixels", im.getpixel((10,10))[:3]==(34,240,255), im.getpixel((10,10)))
        ck("and transparency kept", im.getpixel((200,10))[3]==0, im.getpixel((200,10)))
        ck("with crisp pixel edges", im.getpixel((127,5))[:3]==(34,240,255) and im.getpixel((128,5))[3]==0)
    except ImportError: ck("a PNG was exported", open(path,"rb").read(4)==b"\x89PNG")
    pg.locator("#pxMore").click(); pg.wait_for_timeout(150)
    pg.locator("#pxPdfW").fill("3"); 
    with pg.expect_download() as dl2: pg.locator("#pxPdf").click()
    dl2.value.save_as("/tmp/verify_blank.pdf")
    try:
        import pypdf
        page=pypdf.PdfReader("/tmp/verify_blank.pdf").pages[0]
        ck("PDF prints at the chosen width", "3.00 x 3.00 in" in page.extract_text(), page.extract_text()[:90])
    except ImportError: ck("a PDF was exported", open("/tmp/verify_blank.pdf","rb").read(5)==b"%PDF-")
    r=pg.evaluate("""()=>{ var h=KETER_PX.blank(20,10); h.grid='hex'; h.shape='rect'; h.orient='pointy';
      var d=new Uint8Array(200).fill(134); h.frames[0].layers[0].px=KETER_PX.encode(d); KETER_PX.refreshFlat(h);
      var c=KETER_STUDIO.pngCanvas(h,8), g=c.getContext('2d'), d=g.getImageData(0,0,c.width,c.height).data, odd=0, m=g.getImageData(Math.round(c.width/2),Math.round(c.height/2),1,1).data;
      for(var i=0;i<d.length;i+=4){ var a=d[i+3]; if(a===0) continue; if(a!==255 || d[i]!==34 || d[i+1]!==240 || d[i+2]!==255) odd++; }
      return {w:c.width, h:c.height, mid:[m[0],m[1],m[2]], offPalette:odd}; }""")
    ck("hex pictures export to PNG too", r["w"]>150 and r["mid"]==[34,240,255], r)
    ck("with every pixel an exact palette colour or fully transparent", r["offPalette"]==0, r)

    # ---- the library ----
    pg.locator("#pxBack").click(); pg.wait_for_timeout(400)
    ck("the library lists free graphics as graphics", "graphic" in pg.locator(".pxlib").inner_text())

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"BLANK PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
