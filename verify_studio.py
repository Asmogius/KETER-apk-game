"""The Pixel Studio, stage two: reaching it from Home and from a card in the
Forge, drawing with real strokes, mirror, fill, the colour picker and long
press, undo and redo, whole-number zoom, the two drawing modes, saving into the
library linked to its card, previews, and export as a PDF at true size."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json, io
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_studio")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9971),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))
with sync_playwright() as p:
    b=p.chromium.launch()
    ctx=b.new_context(viewport={"width":412,"height":915},device_scale_factor=2,accept_downloads=True); pg=ctx.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.goto("http://127.0.0.1:9971/"); pg.wait_for_timeout(2200)

    # ---- from Home ----
    ck("the studio has a tile on Home", pg.locator('.lt[data-page="studio"]').count()==1)
    pg.locator('.lt[data-page="studio"]').click(); pg.wait_for_timeout(600)
    ck("it opens the studio", pg.locator("#v-studio.on .pxh").count()==1)
    pg.locator("#pxNewTok").click(); pg.wait_for_timeout(300)
    # (v14.1: 16, 24, 32 and 48 square, 48 being the size the game draws every Unit at)
    ck("a new token asks for its size, square or hex", pg.locator("[data-pxsize]").count()==4 and pg.locator('[data-pxsize="48"]').count()==1 and pg.locator("[data-pxside]").count()==3)
    pg.locator('[data-pxsize="24"]').click(); pg.wait_for_timeout(600)
    S="()=>KETER_STUDIO.state()"
    ck("and opens a canvas of that size", pg.evaluate("()=>{var s=KETER_STUDIO.state(); return s.pic.w===24&&s.pic.h===24&&s.kind==='token';}"))
    v=pg.evaluate("()=>{var v=KETER_STUDIO.view(); return {z:v.z,x:v.x,y:v.y};}")
    ck("the canvas zooms by whole numbers", isinstance(v["z"],int) and v["z"]>=1, v)
    # measured afresh each time: opening the palette can scroll the page
    def at(cx,cy):
        pg.locator("#pxCanvas").scroll_into_view_if_needed(); pg.wait_for_timeout(80)
        bx=pg.locator("#pxCanvas").bounding_box(); vv=pg.evaluate("()=>{var v=KETER_STUDIO.view(); return {z:v.z,x:v.x,y:v.y};}")
        return (bx["x"]+vv["x"]+(cx+0.5)*vv["z"], bx["y"]+vv["y"]+(cy+0.5)*vv["z"])
    cnt=lambda col:pg.evaluate(f"()=>KETER_STUDIO.state().buf.filter(function(x){{return x==={col};}}).length")

    # ---- drawing ----
    pg.locator("#pxPalTog").click(); pg.locator('.pxgrid [data-pxcol="134"]').last.click()
    x0,y0=at(2,3); x1,y1=at(9,3)
    pg.mouse.move(x0,y0); pg.mouse.down()
    for k in range(1,5): pg.mouse.move(x0+(x1-x0)*k/4, y0)
    pg.mouse.up(); pg.wait_for_timeout(200)
    ck("a fast stroke leaves no gaps", cnt(134)==8, cnt(134))
    pg.locator("#pxMirror").click(); pg.wait_for_timeout(100)
    x0,y0=at(1,10); pg.mouse.click(x0,y0); pg.wait_for_timeout(200)
    ck("mirror paints the opposite pixel too",
       pg.evaluate("()=>{var s=KETER_STUDIO.state(); return s.buf[10*24+1]===134 && s.buf[10*24+22]===134;}"))
    pg.locator("#pxMirror").click(); pg.locator("#pxMirror").click(); pg.locator("#pxMirror").click(); pg.wait_for_timeout(100)
    ck("mirror cycles back to off", pg.evaluate("()=>KETER_STUDIO.state().mirror")=="off")
    pg.locator('.pxgrid [data-pxcol="37"]').last.click(); pg.locator('[data-pxtool="fill"]').click()
    fx,fy=at(20,20); pg.mouse.click(fx,fy); pg.wait_for_timeout(300)
    ck("fill covers the open area and stops at other colours", cnt(37)==24*24-cnt(134), (cnt(37),cnt(134)))
    pg.locator("#pxUndo").click(); pg.wait_for_timeout(150)
    ck("undo takes a whole action back", cnt(37)==0)
    pg.locator("#pxRedo").click(); pg.wait_for_timeout(150)
    ck("redo restores it", cnt(37)>0)
    pg.locator('[data-pxtool="pick"]').click(); px_,py_=at(3,3); pg.mouse.click(px_,py_); pg.wait_for_timeout(150)
    ck("the colour picker takes a colour off the canvas and returns to the pencil",
       pg.evaluate("()=>{var s=KETER_STUDIO.state(); return s.colour===134 && s.tool==='pencil';}"))
    pg.locator('.pxgrid [data-pxcol="5"]').last.click()
    lx,ly=at(12,12); pg.mouse.move(lx,ly); pg.mouse.down(); pg.wait_for_timeout(700); pg.mouse.up(); pg.wait_for_timeout(150)
    ck("a long press picks the colour under it, leaving the picture as it was",
       pg.evaluate("()=>{var s=KETER_STUDIO.state(); return s.colour===37 && s.buf[12*24+12]===37;}"))
    ck("recently used colours are kept to hand", pg.locator(".pxrecent .pxsw").count()>=2)
    ck("the colour count is shown", "colour" in pg.locator("#pxCount").inner_text())
    pg.locator("#pxCursor").click(); pg.wait_for_timeout(100)
    pg.locator('[data-pxtool="pencil"]').click(); pg.locator('.pxgrid [data-pxcol="134"]').last.click()
    cx,cy=at(5,15); pg.mouse.click(cx,cy+56); pg.wait_for_timeout(150)
    ck("in cursor mode the pixel is placed above the finger, not under it",
       pg.evaluate("()=>KETER_STUDIO.state().buf[15*24+5]")==134)
    pg.locator("#pxZoomIn").click(); pg.wait_for_timeout(100)
    ck("zooming in stays whole-number", pg.evaluate("()=>{var z=KETER_STUDIO.view().z; return z>%d && Math.round(z)===z;}"%v["z"]))

    # ---- saving ----
    pg.wait_for_timeout(800)
    r=pg.evaluate("()=>{var s=KETER_STUDIO.state(); var saved=KETER_PX.get(s.id); return {status:s.status, same:!!saved && saved.frames[0].layers[0].px===s.pic.frames[0].layers[0].px};}")
    ck("it saves itself into the library", r["status"]=="Saved" and r["same"], r)
    pg.locator("#pxName").fill("Scout"); pg.wait_for_timeout(800)
    ck("the name is saved too", pg.evaluate("()=>KETER_PX.get(KETER_STUDIO.state().id).name")=="Scout")
    pg.locator("#pxMore").click(); pg.locator("#pxPrevTog").click(); pg.wait_for_timeout(500)
    ck("a token previews on board hexes", pg.locator("#pxPrevC").count()==1)
    pg.locator("#pxBack").click(); pg.wait_for_timeout(500)
    ck("the library lists it", "Scout" in pg.locator(".pxlib").inner_text())
    n0=pg.evaluate("()=>KETER_PX.list().length")
    pg.locator("[data-pxcopy]").first.click(); pg.wait_for_timeout(300)
    ck("copying makes a separate picture", pg.evaluate("()=>KETER_PX.list().length")==n0+1)

    # ---- from a card in the Forge ----
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3500)
    F=pg.frame_locator('#v-forge iframe')
    F.locator("#fName").fill("Studio Suite Card"); pg.wait_for_timeout(400)
    F.locator("#pxArtBtn").click(); pg.wait_for_timeout(1200)
    # v12.4: square-pixel card art is 128 or 64 across
    ck("Draw art asks for square or hex pixels", pg.locator('[data-pxartw]').count()==2 and pg.locator("[data-pxacross]").count()==3)
    pg.locator('[data-pxartw="64"]').click(); pg.wait_for_timeout(900)
    r=pg.evaluate("()=>{var s=KETER_STUDIO.state(); return s&&{w:s.pic.w,h:s.pic.h,kind:s.kind,from:s.from,card:s.card&&s.card.name};}")
    ck("Draw art in the Forge opens the studio for that card", r and r["kind"]=="art" and r["card"]=="Studio Suite Card", r)
    ck("at 64 pixels wide, as tall as the card's art box", r and r["w"]==64 and 20<=r["h"]<=47, r)
    pg.evaluate("()=>{var s=KETER_STUDIO.state(); for(var i=0;i<s.buf.length;i++) s.buf[i]=134; s.pic.frames[0].layers[0].px=KETER_PX.encode(s.buf); KETER_STUDIO.flushSave();}")
    pg.locator("#pxMore").click(); pg.locator("#pxPrevTog").click(); pg.wait_for_timeout(1000)
    ck("card art previews on the real card", pg.locator("#pxPrevC").count()==1)
    with pg.expect_download() as dl:
        pg.locator("#pxMore").click(); pg.locator("#pxPdf").click()
    path="/tmp/verify_studio.pdf"; dl.value.save_as(path)
    try:
        import pypdf
        rd=pypdf.PdfReader(path); page=rd.pages[0]; c=page.get_contents().get_data().decode()
        ck("Export as PDF gives one letter page", len(rd.pages)==1 and round(float(page.mediabox.width))==612)
        ck("with the picture as vector pixels", c.count(" re f")>=1)
        ck("captioned with its true size", "2.27" in page.extract_text(), page.extract_text()[:80])
    except ImportError:
        ck("a PDF was exported", open(path,"rb").read(5)==b"%PDF-")
    pg.locator("#pxBack").click(); pg.wait_for_timeout(1500)
    ck("Back returns to the Forge", pg.locator("#v-forge.on").count()==1)
    ck("and the art is linked to the card", "art" in (pg.evaluate("()=>KETER_PX.links()['Studio Suite Card']") or {}))

    # ---- a token PDF prints for a 1.25-inch tile ----
    txt=pg.evaluate("()=>{var p=KETER_PX.blank(32,32,'T'); p.kind='token'; return KETER_STUDIO.pdfText(p);}")
    ck("a token's PDF is sized for a 1.25-inch board tile", "1.25 in board tile" in txt)

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"STUDIO PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
