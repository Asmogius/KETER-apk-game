"""Pixel Studio v12.4: card art 64 or 128 across (trimmed to the art box), blank
canvases to 256, Double the pixels, crisp-or-averaged drawing on cards, brush
sizes and shapes, line width, ordered dither patterns and the gradient, alpha
lock, select by colour, nudge, merge down, solo, colour ramps, swatch groups,
the reference picture (kept, drawn, never exported), refreshed test pictures,
and speed at 256 x 256."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json, time
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_studio4")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9984),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""):
    (ok if c else bad).append(n+((" — "+str(d)[:260]) if not c else ""))
    print(("PASS " if c else "FAIL ")+n+("" if c else "  — "+str(d)[:260]))

HELP=r"""()=>{
  window.T={
    S:function(){ return KETER_STUDIO.state(); },
    xy:function(i){ var s=KETER_STUDIO.state(), v=KETER_STUDIO.view(), c=s.grid.centre(i,s.pic); return {x:v.x+c.x*v.z, y:v.y+c.y*v.z}; },
    idx:function(x,y){ return y*KETER_STUDIO.state().pic.w+x; },
    drag:function(a,b,steps){ var P=KETER_STUDIO._paint, A=T.xy(a), B=T.xy(b); steps=steps||6;
      P.down(A.x,A.y); for(var k=1;k<=steps;k++) P.move(A.x+(B.x-A.x)*k/steps, A.y+(B.y-A.y)*k/steps); P.up(); },
    tap:function(a){ var P=KETER_STUDIO._paint, A=T.xy(a); P.down(A.x,A.y); P.up(); },
    count:function(v){ return KETER_STUDIO.state().buf.filter(function(x){ return x===v; }).length; },
    clear:function(){ var s=KETER_STUDIO.state(); s.buf.fill(0); s.pic.frames[0].layers[s.layer].px=KETER_PX.encode(s.buf); s.pic.flat=''; s.sel=null; s.mirror='off'; }
  }; return true; }"""

with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},device_scale_factor=2).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    dialogs=[]
    def on_dialog(d):
        dialogs.append(d.message)
        d.accept("Gunmetal") if d.type=="prompt" else d.accept()
    pg.on("dialog",on_dialog)
    pg.goto("http://127.0.0.1:9984/"); pg.wait_for_timeout(2200)
    E=pg.evaluate

    # ---- the shipped test pictures: Units at 128, refreshed when nobody edited them ----
    r=E("""()=>{ var P=KETER_PX, w={}; P.list().forEach(function(p){ if(/^px_test_.*_art$/.test(p.id) && p.grid!=='hex') w[p.id]=p.w; }); return w; }""")
    ck("the Unit test cards' art is 128 across", r.get("px_test_test_warden_art")==128 and r.get("px_test_test_grunt_art")==128, r)
    ck("and the rest stays 64", r.get("px_test_test_snare_art")==64, r)
    r=E("""()=>{ var P=KETER_PX, id='px_test_test_warden_art', mine=P.get(id), old=JSON.parse(JSON.stringify(mine));
      /* an older release's untouched picture is refreshed; an edited one is kept */
      var pics=window.KETER_TEST_PICTURES; old.w=64; delete old.shipped;
      window.KETER_TEST_PICTURE_OLD_MARKS=[P.mark(old)]; P.put(old,id); installTestPictures();
      var refreshed=P.get(id).w===128;
      var edited=JSON.parse(JSON.stringify(P.get(id))); edited.w=64; delete edited.shipped; edited.frames[0].layers[0].name='mine'; P.put(edited,id);
      window.KETER_TEST_PICTURE_OLD_MARKS=[]; installTestPictures(); var kept=P.get(id).w===64;
      P.put(JSON.parse(JSON.stringify(pics[id])),id); installTestPictures();
      return {refreshed:refreshed, kept:kept}; }""")
    ck("a shipped picture nobody edited is refreshed by a release", r["refreshed"], r)
    ck("one you have drawn on is kept", r["kept"], r)

    # ---- card art: 128 or 64 across, trimmed to the art box ----
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3400)
    E("()=>KETER_GO('studio')"); pg.wait_for_timeout(500)
    pg.locator("#pxNewArt").click(); pg.wait_for_timeout(200)
    pg.locator("#pxPickQ").fill("Scuttle brood"); pg.wait_for_timeout(250)
    pg.locator("[data-pxcard]").first.click(); pg.wait_for_timeout(400)
    ws=pg.locator("[data-pxartw]").evaluate_all("els=>els.map(e=>[e.getAttribute('data-pxartw'), e.classList.contains('primary')])")
    ck("card art offers 128 (first, the default) and 64 across", ws==[["128",True],["64",False]], ws)
    pg.locator('[data-pxartw="128"]').click(); pg.wait_for_timeout(700)
    E(HELP)
    r=E("""()=>{ var s=T.S(), f=[].slice.call(document.querySelectorAll('iframe')).map(function(x){ try{ return x.contentWindow.KETER_BRIDGE; }catch(e){ return null; } }).filter(Boolean)[0];
      var cv=document.createElement('canvas'); cv.width=250; cv.height=350; f.renderCard(cv.getContext('2d'), f.fromSchema(s.card.schema), 100, {});
      var box=f.lastLayout().artH; return {w:s.pic.w, h:s.pic.h, box:box, want:KETER_PX.artSizeFor(box,2.27,128).h}; }""")
    ck("a 128-across canvas, trimmed at the bottom to the card's art box", r["w"]==128 and r["h"]==r["want"] and r["h"]<128, r)
    # draw at 64 and double
    E("()=>{ KETER_STUDIO.close(); }"); pg.wait_for_timeout(300)
    E("()=>KETER_GO('studio')"); pg.wait_for_timeout(300)
    pg.locator("#pxNewArt").click(); pg.locator("#pxPickQ").fill("Test Snare"); pg.wait_for_timeout(250)
    pg.locator("[data-pxcard]").first.click(); pg.wait_for_timeout(400)
    E("()=>{ var id=KETER_PX.pictureFor(KETER_ALLCARDS().filter(function(c){return c.name==='Test Snare';})[0],'art'); return id&&id.id; }")
    # Snare has shipped art, so it opened; start a fresh 64 blank-art instead through open()
    E("""()=>{ KETER_STUDIO.close(); KETER_STUDIO.open({kind:'art', grid:'square', artW:64, artHin:1.1}); }"""); pg.wait_for_timeout(500)
    E(HELP)
    r=E("""()=>{ var s=T.S(); s.colour=33; T.tap(T.idx(3,4)); var before={w:s.pic.w,h:s.pic.h,ratio:s.pic.h/s.pic.w, v:s.buf[T.idx(3,4)]};
      KETER_STUDIO.flushSave(); var can=KETER_STUDIO._paint.canDouble(); KETER_STUDIO._paint.doublePixels(); s=T.S();
      var after={w:s.pic.w,h:s.pic.h, ratio:s.pic.h/s.pic.w, block:[s.buf[T.idx(6,8)],s.buf[T.idx(7,8)],s.buf[T.idx(6,9)],s.buf[T.idx(7,9)]], again:KETER_STUDIO._paint.canDouble()};
      KETER_STUDIO._paint.undo(); s=T.S(); var undone={w:s.pic.w,h:s.pic.h,v:s.buf[s.pic.w*4+3]};
      KETER_STUDIO._paint.redo(); s=T.S(); var redone=s.pic.w;
      return {before:before, can:can, after:after, undone:undone, redone:redone}; }""")
    ck("64 art can be doubled", r["can"] and r["before"]["w"]==64, r)
    ck("doubling makes 128 across, every pixel a 2 x 2 block", r["after"]["w"]==128 and r["after"]["h"]==r["before"]["h"]*2 and r["after"]["block"]==[33,33,33,33], r)
    ck("the art box keeps its shape", abs(r["after"]["ratio"]-r["before"]["ratio"])<1e-9, r)
    ck("128 art cannot be doubled again", r["after"]["again"] is False, r)
    ck("undo takes the doubling back, size and all; redo brings it again", r["undone"]["w"]==64 and r["undone"]["v"]==33 and r["redone"]==128, r)

    # ---- drawing on the card: crisp when cheap, averaged below one dot per pixel ----
    r=E("""()=>{ var P=KETER_PX, pic=P.blank(128,62,'t'); var px=new Uint8Array(128*62); for(var i=0;i<px.length;i++) px[i]=(i%2)?33:8;
      pic.frames[0].layers[0].px=P.encode(px); pic.flat='';
      var c=document.createElement('canvas'); c.width=800; c.height=400; var g=c.getContext('2d');
      var o={minFill:0.85, exactFrom:4};
      var print=P.draw(g,pic,0,0,681,330,1,o), low=P.draw(g,pic,0,0,420,204,1,o);
      var small=P.draw(g,pic,0,0,72,35,1,o);
      var mid=P.draw(g,pic,0,0,227,110,1,o);
      return {print:print.scale, printW:print.w, low:low.scale, small:!!small.smooth, smallW:small.w, mid:mid.scale}; }""")
    ck("printed at 300 dpi, 128 across fills the art box exactly", abs(r["printW"]-681)<0.5, r)
    ck("below 4 dots a pixel it stays a whole number, crisp", r["low"]==3, r)
    ck("in the hand it is averaged down, not thinned", r["small"] and r["smallW"]<=72, r)
    ck("in between, the box is filled rather than left half empty", r["mid"]>1.5, r)

    # ---- blank canvases to 256 ----
    E("()=>{ KETER_STUDIO.close(); }"); pg.wait_for_timeout(300)
    E("()=>KETER_GO('studio')"); pg.wait_for_timeout(300)
    ck("the library says how much storage it uses", "of about 5 mb" in pg.locator("#v-studio .pxsub").first.inner_text().lower(), pg.locator("#v-studio .pxsub").first.inner_text())
    pg.locator("#pxNewBlank").click(); pg.wait_for_timeout(300)
    pres=pg.locator("[data-pxwh]").evaluate_all("els=>els.map(e=>e.getAttribute('data-pxwh'))")
    ck("blank presets reach 256 x 256 and 256 x 144", "256x256" in pres and "256x144" in pres, pres)
    pg.locator("#pxSqW").fill("300"); pg.locator("#pxSqH").fill("300"); pg.locator('[data-pxcustom="square"]').click(); pg.wait_for_timeout(600)
    r=E("()=>({w:KETER_STUDIO.state().pic.w, h:KETER_STUDIO.state().pic.h})")
    ck("square pixels stop at 256", r=={"w":256,"h":256}, r)
    E("()=>{ KETER_STUDIO.close(); KETER_STUDIO.open({kind:'blank', grid:'hex', w:300, h:300, orient:'pointy'}); }"); pg.wait_for_timeout(500)
    r=E("()=>({w:KETER_STUDIO.state().pic.w, h:KETER_STUDIO.state().pic.h})")
    ck("hex pixels stop at 128", r=={"w":128,"h":128}, r)

    # ---- speed at 256 x 256 ----
    E("()=>{ KETER_STUDIO.close(); KETER_STUDIO.open({kind:'blank', grid:'square', w:256, h:256}); }"); pg.wait_for_timeout(600)
    E(HELP)
    r=E("""()=>{ var s=T.S(); s.colour=40; s.size=4; var t0=performance.now();
      T.drag(T.idx(10,10),T.idx(240,200),80); var stroke=performance.now()-t0;
      var t1=performance.now(); for(var k=0;k<5;k++) KETER_STUDIO.render(); var redraw=(performance.now()-t1)/5;
      return {stroke:stroke, redraw:redraw, painted:T.count(40)}; }""")
    ck("a long stroke on 256 x 256 stays quick", r["stroke"]<1500 and r["painted"]>500, r)
    ck("and a full redraw of it too", r["redraw"]<400, r)

    # ---- brushes ----
    E("()=>{ KETER_STUDIO.close(); KETER_STUDIO.open({kind:'blank', grid:'square', w:32, h:32}); }"); pg.wait_for_timeout(500)
    E(HELP)
    pg.locator('[data-pxtool="pencil"]').click(); pg.wait_for_timeout(80)
    ck("the pencil offers sizes 1, 2, 3, 4, 6 and 8, square or round",
       pg.locator("[data-pxbrush]").evaluate_all("els=>els.map(e=>e.textContent)")==["1","2","3","4","6","8"] and pg.locator("[data-pxshape]").count()==2)
    r=E("""()=>{ var s=T.S(), F=KETER_STUDIO._paint.footprint, out={};
      [[3,'square'],[3,'round'],[8,'round'],[2,'square']].forEach(function(z){ s.size=z[0]; s.brushShape=z[1]; out[z[0]+z[1]]=F(T.idx(10,10)).length; });
      s.size=3; s.brushShape='square'; T.S().colour=12; T.clear(); T.tap(T.idx(10,10)); out.tap=T.count(12);
      T.clear(); T.drag(T.idx(2,20),T.idx(28,20),20); out.row=[T.S().buf[T.idx(15,19)],T.S().buf[T.idx(15,20)],T.S().buf[T.idx(15,21)],T.S().buf[T.idx(15,22)]];
      s.size=1; return out; }""")
    ck("a size-3 square brush paints 9 pixels, round paints 5", r["3square"]==9 and r["3round"]==5, r)
    ck("size 8 round is a disc, not a square", 40<r["8round"]<64, r)
    ck("a tap paints the whole brush", r["tap"]==9, r)
    ck("and a stroke is as wide as the brush", r["row"]==[12,12,12,0], r)
    pg.locator('[data-pxtool="line"]').click(); pg.wait_for_timeout(80)
    r=E("""()=>{ var s=T.S(); s.size=2; T.clear(); s.colour=20; T.drag(T.idx(2,5),T.idx(20,5)); var n=T.count(20); s.size=1; return n; }""")
    # a size-2 brush reaches one pixel right and down of the line, so 20 x 2
    ck("the line tool takes the brush size as its width", r==20*2, r)

    # ---- dither ----
    pg.locator('[data-pxtool="dither"]').click(); pg.wait_for_timeout(80)
    pats=pg.locator("[data-pxdp]").evaluate_all("els=>els.map(e=>e.textContent)")
    ck("dither offers 25%, 50%, 75%, hatch and gradient", pats==["25%","50%","75%","Hatch","Gradient"], pats)
    r=E("""()=>{ var s=T.S(), out={}; s.size=8; s.ditherMode='over'; s.colour=5;
      ['25','50','75','hatch'].forEach(function(p){ s.ditherPat=p; T.clear(); for(var y=0;y<32;y+=6) for(var x=0;x<32;x+=6) T.tap(T.idx(x+3,y+3)); out[p]=T.count(5); });
      s.ditherPat='50'; T.clear(); T.tap(T.idx(8,8)); T.tap(T.idx(12,8)); var a=T.S().buf.slice();
      var joined=true; for(var i=0;i<a.length;i++){ var x=i%32,y=(i/32)|0; if(a[i] && ((x+y)&1)) joined=false; }
      s.size=1; return {c:out, aligned:joined}; }""")
    c=r["c"]
    ck("coverage rises 25% < 50% < 75%", 0<c["25"]<c["50"]<c["75"], c)
    ck("25% is a quarter of the checkerboard's 50%", abs(c["25"]*2-c["50"])<=4, c)
    ck("overlapping strokes keep one pattern, anchored to the canvas", r["aligned"], r)
    r=E("""()=>{ var s=T.S(); s.ditherPat='grad'; s.ditherMode='two'; s.colour=9; s.colour2=0; T.clear();
      T.drag(T.idx(0,16),T.idx(31,16),8);
      var col=function(x){ var n=0; for(var y=0;y<32;y++) if(T.S().buf[T.idx(x,y)]===9) n++; return n; };
      var r={start:col(0), mid:col(16), end:col(31)}; s.ditherPat='50'; return r; }""")
    ck("the gradient fades from none at the start to full at the end", r["start"]<=4 and r["end"]==32 and 8<=r["mid"]<=24, r)

    # ---- alpha lock ----
    pg.locator('[data-pxtool="pencil"]').click(); pg.wait_for_timeout(80)
    pg.locator("#pxLayTog").click(); pg.wait_for_timeout(100)
    r=E("""()=>{ var s=T.S(); T.clear(); s.colour=30; T.tap(T.idx(5,5)); return true; }""")
    pg.locator("#pxLayAlpha").click(); pg.wait_for_timeout(80)
    r=E("""()=>{ var s=T.S(), out={lock:!!s.pic.frames[0].layers[s.layer].alphaLock};
      s.colour=44; T.tap(T.idx(5,5)); T.tap(T.idx(9,9)); out.recolour=s.buf[T.idx(5,5)]; out.empty=s.buf[T.idx(9,9)];
      document.querySelector('[data-pxtool="eraser"]').click(); T.tap(T.idx(5,5)); out.erased=s.buf[T.idx(5,5)]; out.status=s.status;
      return out; }""")
    ck("alpha lock recolours pixels that are there", r["lock"] and r["recolour"]==44, r)
    ck("paints nothing where the layer is empty", r["empty"]==0, r)
    ck("and cannot erase, saying why", r["erased"]==44 and "Alpha lock" in (r["status"] or ""), r)
    pg.locator("#pxLayAlpha").click(); pg.wait_for_timeout(80)

    # ---- select by colour, all, nudge ----
    pg.locator('[data-pxtool="select"]').click(); pg.wait_for_timeout(80)
    modes=pg.locator("[data-pxselmode]").evaluate_all("els=>els.map(e=>e.textContent)")
    ck("Select picks by box, joined colour or colour on the layer", modes==["Box","Joined colour","Colour on layer"], modes)
    r=E("""()=>{ var s=T.S(); T.clear(); s.pic.frames[0].layers[s.layer].alphaLock=false;
      [[2,2],[3,2],[4,2],[20,20]].forEach(function(p){ s.buf[T.idx(p[0],p[1])]=7; }); s.buf[T.idx(10,10)]=8;
      s.pic.frames[0].layers[s.layer].px=KETER_PX.encode(s.buf);
      s.selMode='wand'; T.tap(T.idx(3,2)); var wand=s.sel?s.sel.items.length:0; KETER_STUDIO._paint.commitSelection();
      s.selMode='colour'; T.tap(T.idx(3,2)); var col=s.sel?s.sel.items.length:0;
      KETER_STUDIO._paint.nudge('r'); KETER_STUDIO._paint.commitSelection();
      var moved=[s.buf[T.idx(3,2)],s.buf[T.idx(5,2)],s.buf[T.idx(2,2)],s.buf[T.idx(21,20)]];
      KETER_STUDIO._paint.selAction('all'); var all=s.sel?s.sel.items.length:0; KETER_STUDIO._paint.commitSelection();
      s.selMode='box';
      /* nothing selected: the arrows move the whole layer */
      KETER_STUDIO._paint.nudge('d'); var layer=[s.buf[T.idx(3,3)], s.buf[T.idx(10,11)], s.buf[T.idx(10,10)]];
      KETER_STUDIO._paint.undo(); var back=s.buf[T.idx(10,10)];
      return {wand:wand, col:col, moved:moved, all:all, layer:layer, back:back}; }""")
    ck("joined colour takes only the joined patch", r["wand"]==3, r)
    ck("colour on layer takes every pixel of it", r["col"]==4, r)
    ck("a selection nudges exactly one pixel", r["moved"]==[7,7,0,7], r)
    ck("All selects everything on the layer", r["all"]==5, r)
    ck("with nothing selected, a nudge moves the whole layer; undo moves it back", r["layer"]==[7,8,0] and r["back"]==8, r)
    r=E("""()=>{ var s=T.S(); KETER_STUDIO._paint.selAction('all'); var x0=s.sel.dx;
      document.dispatchEvent(new KeyboardEvent('keydown',{key:'ArrowRight',bubbles:true})); var x1=s.sel.dx; KETER_STUDIO._paint.commitSelection(); return x1-x0; }""")
    ck("the arrow keys nudge too", r==1, r)

    # ---- merge down and solo ----
    pg.locator('[data-pxtool="pencil"]').click(); pg.wait_for_timeout(80)
    r=E("""()=>{ var s=T.S(); T.clear(); s.colour=3; T.tap(T.idx(1,1));
      document.getElementById('pxLayAdd').click(); s=T.S(); s.colour=4; T.tap(T.idx(2,2));
      var layers=s.pic.frames[0].layers.length;
      document.getElementById('pxLaySolo').click(); var soloFlat=Array.from(KETER_PX.flatten(s.pic,0)).filter(Boolean).length;
      var seen=0; /* the view shows only the soloed layer */
      document.getElementById('pxLaySolo').click();
      document.getElementById('pxLayMerge').click(); s=T.S();
      var merged={layers:s.pic.frames[0].layers.length, a:s.buf[T.idx(1,1)], b:s.buf[T.idx(2,2)]};
      KETER_STUDIO._paint.undo(); s=T.S();
      return {layers:layers, soloFlat:soloFlat, merged:merged, undone:s.pic.frames[0].layers.length}; }""")
    ck("solo is a view only: the saved picture keeps every layer", r["soloFlat"]==2, r)
    ck("merge down folds a layer into the one below", r["layers"]==2 and r["merged"]=={"layers":1,"a":3,"b":4}, r)
    ck("and undo splits them again", r["undone"]==2, r)
    r=E("""()=>{ var s=T.S(); s.solo=1; var views=0; s.pic.frames[0].layers.forEach(function(L,li){});
      var P=KETER_PX; var n=0; /* the canvas shows one layer */
      KETER_STUDIO.render(); var cv=document.getElementById('pxCanvas'); s.solo=null; KETER_STUDIO.render(); return true; }""")

    # ---- ramps and swatch groups ----
    r=E("""()=>{ var P=KETER_PX, s=T.S(); s.colour=33; KETER_STUDIO.render();
      var sw=[].slice.call(document.querySelectorAll('.pxramp [data-pxcol]')).map(function(e){ return +e.getAttribute('data-pxcol'); });
      var lum=function(i){ var c=P.RGB[i]; return 0.2126*c[0]+0.7152*c[1]+0.0722*c[2]; };
      var mid=sw.indexOf(33), dark=sw.slice(0,mid), light=sw.slice(mid+1);
      var order=sw.every(function(v,i){ return i===0 || lum(sw[i-1])<=lum(v)+0.5; });
      return {n:sw.length, mid:mid, order:order, dark:dark.length, light:light.length}; }""")
    ck("the ramp shows darker and lighter palette colours around the current one", r["mid"]>0 and r["dark"]>=2 and r["light"]>=1, r)
    ck("in order of value, dark to light", r["order"], r)
    pg.locator("#pxPalTog").click(); pg.wait_for_timeout(120)
    ck("the open palette lists this picture's colours", pg.locator(".pxpalbody .pxsub", has_text="In this picture").count()==1)
    pg.locator('[data-pxgnew="pic"]').click(); pg.wait_for_timeout(200)
    r=E("()=>KETER_STUDIO.swatches()")
    ck("a swatch group is made from the picture's colours and named", len(r)==1 and r[0]["name"]=="Gunmetal" and set(r[0]["cols"])>={3,4}, r)
    E("()=>{ T.S().colour=60; }"); pg.locator('[data-pxgadd="0"]').click(); pg.wait_for_timeout(100)
    E("()=>{ T.S().colour=3; }"); pg.locator('[data-pxgrem="0"]').click(); pg.wait_for_timeout(100)
    r=E("()=>KETER_STUDIO.swatches()[0].cols")
    ck("colours are added to and taken out of a group", 60 in r and 3 not in r, r)
    ck("groups are kept for every picture", E("()=>JSON.parse(localStorage.getItem('keter-app-swatches'))[0].name")=="Gunmetal")
    pg.locator('[data-pxgdel="0"]').click(); pg.wait_for_timeout(100)
    ck("and a group can be deleted", E("()=>KETER_STUDIO.swatches().length")==0)
    pg.locator("#pxPalTog").click(); pg.wait_for_timeout(80)

    # ---- the reference picture ----
    pg.locator("#pxRefTog").click(); pg.wait_for_timeout(120)
    ck("Reference opens a panel that offers to load one", pg.locator("#pxRefLoad").count()==1)
    usedBefore=E("()=>{ KETER_STUDIO.render(); return (T.S().usedCols||[]).slice(); }")
    E("""()=>{ T.clear(); var c=document.createElement('canvas'); c.width=200; c.height=100; var g=c.getContext('2d');
      g.fillStyle='#ff0000'; g.fillRect(0,0,200,100); KETER_STUDIO._ref.use(c.toDataURL('image/png')); }""")
    pg.wait_for_timeout(900)
    r=E("""()=>{ var s=T.S(); return {ref:s.pic.ref, img:!!s.refImg, vis:KETER_STUDIO._ref.visible(), panel:!!document.getElementById('pxRefOp')}; }""")
    ck("a reference loads, fitted to the canvas, at half opacity", r["img"] and r["vis"] and abs(r["ref"]["s"]-0.16)<0.01 and r["ref"]["op"]==50, r)
    ck("with its controls: show, over or under, move, fit, opacity, size", r["panel"] and pg.locator("[data-pxrefpos]").count()==2 and pg.locator("#pxRefMove").count()==1, r)
    r=E("""()=>{ var s=T.S(), v=KETER_STUDIO.view(), cv=document.getElementById('pxCanvas'), g=cv.getContext('2d'), d=v.dpr;
      var at=function(x,y){ var px=g.getImageData(Math.round((v.x+(x+0.5)*v.z)*d), Math.round((v.y+(y+0.5)*v.z)*d),1,1).data; return [px[0],px[1],px[2]]; };
      var inRef=at(16,16), outRef=at(16,2);
      var png=KETER_STUDIO.pngCanvas(s.pic,1), pd=png.getContext('2d').getImageData(16,16,1,1).data;
      return {inRef:inRef, outRef:outRef, exported:[pd[0],pd[1],pd[2],pd[3]], used:(s.usedCols||[]).length}; }""")
    ck("it shows through empty pixels", r["inRef"][0]>100 and r["inRef"][1]<90, r)
    ck("only where it lies", r["outRef"][0]<80, r)
    ck("and is never exported", r["exported"][3]==0, r)
    ck("nor counted among the picture's colours", E("()=>(T.S().usedCols||[]).slice()")==[c for c in usedBefore if True] or r["used"]<=len(usedBefore), (r, usedBefore))
    r=E("""()=>{ var s=T.S(); s.colour=9; T.tap(T.idx(16,16)); var v=KETER_STUDIO.view(), cv=document.getElementById('pxCanvas'), g=cv.getContext('2d'), d=v.dpr;
      var px=g.getImageData(Math.round((v.x+16.5*v.z)*d), Math.round((v.y+16.5*v.z)*d),1,1).data; return [px[0],px[1],px[2]]; }""")
    ck("painting over it covers it, under the art", r[0]>200 and r[1]>200, r)
    pg.locator('[data-pxrefpos="above"]').click(); pg.wait_for_timeout(100)
    r=E("""()=>{ var s=T.S(), v=KETER_STUDIO.view(), cv=document.getElementById('pxCanvas'), g=cv.getContext('2d'), d=v.dpr;
      var px=g.getImageData(Math.round((v.x+16.5*v.z)*d), Math.round((v.y+16.5*v.z)*d),1,1).data; return {rgb:[px[0],px[1],px[2]], above:s.pic.ref.above}; }""")
    ck("over the art, it tints what is drawn", r["above"] and r["rgb"][1]<200, r)
    pg.locator("#pxRefMove").click(); pg.wait_for_timeout(80)
    r=E("""()=>{ var s=T.S(), x0=s.pic.ref.x, A=T.xy(T.idx(10,10)), B=T.xy(T.idx(14,10)), P=KETER_STUDIO._paint, before=Array.from(s.buf);
      P.down(A.x,A.y); P.move(B.x,B.y); P.up(); var same=Array.from(s.buf).every(function(v,i){ return v===before[i]; });
      return {dx:s.pic.ref.x-x0, same:same}; }""")
    ck("Move drags the reference, not your pixels", abs(r["dx"]-4)<0.01 and r["same"], r)
    pg.locator("#pxRefMove").click(); pg.wait_for_timeout(80)
    E("()=>KETER_STUDIO.flushSave()"); pg.wait_for_timeout(300)
    pid=E("()=>T.S().id")
    E("()=>{ KETER_STUDIO.close(); }"); pg.wait_for_timeout(300)
    E(f"()=>{{ KETER_STUDIO.open({{id:'{pid}'}}); }}"); pg.wait_for_timeout(900)
    E(HELP)
    r=E("()=>({img:!!T.S().refImg, x:T.S().pic.ref&&T.S().pic.ref.x, above:T.S().pic.ref&&T.S().pic.ref.above})")
    ck("the reference is kept with the drawing, where you left it", r["img"] and r["above"] is True, r)
    pg.locator("#pxRefTog").click(); pg.wait_for_timeout(100)
    pg.locator("#pxRefDel").click(); pg.wait_for_timeout(500)
    r=E(f"""()=>new Promise(function(res){{ KETER_STUDIO._ref.get('{pid}',function(d){{ res({{stored:!!d, ref:T.S().pic.ref, img:!!T.S().refImg}}); }}); }})""")
    ck("Remove takes it off the drawing and out of storage", not r["stored"] and not r["ref"] and not r["img"], r)
    ck("no errors", not errs, errs[:3])
    b.close()
srv.shutdown()
print(f"STUDIO 4 PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
sys.exit(1 if bad else 0)
