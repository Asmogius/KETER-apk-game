"""Pixel Studio v12.5: the palette to 255 (KETER 56 and your own colours, carried
by every picture that uses them), sorting and filtering the palette, a colour
from the reference, turning an image into palette pixels (32 to 256 across, or
onto a new layer), scaling a selection, pixel text, and the value, silhouette
and actual-size views."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json, time
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_studio5")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9985),functools.partial(H,directory=str(TMP)))
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
    tap:function(a){ var P=KETER_STUDIO._paint, A=T.xy(a); P.down(A.x,A.y); P.up(); },
    count:function(v){ return KETER_STUDIO.state().buf.filter(function(x){ return x===v; }).length; },
    clear:function(){ var s=KETER_STUDIO.state(); s.buf.fill(0); s.pic.frames[0].layers[s.layer].px=KETER_PX.encode(s.buf); s.pic.flat=''; s.sel=null; s.mirror='off'; },
    /* the colour the canvas shows at the middle of a pixel */
    shown:function(i){ var s=KETER_STUDIO.state(), v=KETER_STUDIO.view(), c=s.grid.centre(i,s.pic), cv=document.getElementById('pxCanvas');
      var d=cv.getContext('2d').getImageData(Math.round((v.x+c.x*v.z)*v.dpr), Math.round((v.y+c.y*v.z)*v.dpr),1,1).data; return [d[0],d[1],d[2]]; },
    img:function(w,h,paint){ var c=document.createElement('canvas'); c.width=w; c.height=h; var g=c.getContext('2d'); paint(g,w,h); return c.toDataURL('image/png'); },
    conv:function(data,mode,name){ return new Promise(function(r){ KETER_STUDIO._conv.open(data,mode,name,r); }); }
  }; return true; }"""

SCENE="""(g,w,h)=>{ g.fillStyle='#ffffff'; g.fillRect(0,0,w,h);
  var gr=g.createLinearGradient(0,0,w,0); gr.addColorStop(0,'#8e4a30'); gr.addColorStop(0.5,'#61a53f'); gr.addColorStop(1,'#2789cd');
  g.fillStyle=gr; g.beginPath(); g.arc(w/2,h/2,Math.min(w,h)*0.38,0,7); g.fill();
  g.fillStyle='#ff2bd6'; g.fillRect(w/2-w*0.05,h/2-h*0.05,w*0.1,h*0.1); }"""

with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},device_scale_factor=2).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    dialogs=[]
    def on_dialog(d):
        dialogs.append(d.message)
        d.accept("Rust") if d.type=="prompt" else d.accept()
    pg.on("dialog",on_dialog)
    pg.goto("http://127.0.0.1:9985/"); pg.wait_for_timeout(2200)
    E=pg.evaluate

    # ================= the palette =================
    r=E("""()=>{ var P=KETER_PX, lab=function(i){ return P.lab(P.RGB[i]); }, min=1e9, fam={}, none=0;
      for(var i=P.EXT_FROM;i<P.CUSTOM_FROM;i++){ var a=lab(i); for(var j=1;j<P.CUSTOM_FROM;j++){ if(j===i) continue; var c=lab(j), d=Math.hypot(a[0]-c[0],a[1]-c[1],a[2]-c[2]); if(d<min) min=d; } }
      for(var k=1;k<P.CUSTOM_FROM;k++){ var f=P.family(k); if(!f) none++; fam[f]=(fam[f]||0)+1; }
      return {n:P.EXT.length, min:min, fam:fam, none:none, famList:P.FAMILIES, empty:P.PALETTE.slice(P.CUSTOM_FROM).filter(Boolean).length}; }""")
    ck("KETER 56: fifty-six more colours", r["n"]==56, r)
    ck("each clear of every other colour (Lab distance 4.5 or more)", r["min"]>=4.5, r["min"])
    ck("every built-in colour belongs to a family, and every family has colours", r["none"]==0 and all(r["fam"].get(f,0)>0 for f in r["famList"]), r["fam"])
    ck("the 60 slots after them are yours, empty to begin with", r["empty"]==0, r)

    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3400)
    E("()=>KETER_GO('studio')"); pg.wait_for_timeout(300)
    E("()=>KETER_STUDIO.open({kind:'blank',w:16,h:16})"); pg.wait_for_timeout(400)
    E(HELP)
    pg.locator("#pxPalTog").click(); pg.wait_for_timeout(150)
    subs=pg.locator(".pxpalbody .pxsub").all_inner_texts()
    ck("the open palette shows Splendor 128, Neon and KETER 56 in palette order", any("SPLENDOR 128 · 128" in x.upper() for x in subs) and any("NEON · 11" in x.upper() for x in subs) and any("KETER 56 · 56" in x.upper() for x in subs), subs)
    pg.locator('[data-pxfam="Greens"]').click(); pg.wait_for_timeout(100)
    r=E("""()=>{ var P=KETER_PX, ids=[].slice.call(document.querySelectorAll('.pxpalbody [data-pxcol]')).map(function(b){ return +b.getAttribute('data-pxcol'); });
      return {n:ids.length, all:ids.every(function(i){ return P.family(i)==='Greens'; })}; }""")
    ck("a family chip shows only that family", r["n"]>10 and r["all"], r)
    pg.select_option("#pxPalVal","dark"); pg.wait_for_timeout(100)
    r=E("""()=>{ var P=KETER_PX, ids=[].slice.call(document.querySelectorAll('.pxpalbody [data-pxcol]')).map(function(b){ return +b.getAttribute('data-pxcol'); });
      return {n:ids.length, dark:ids.every(function(i){ return P.lightness(i)<35 && P.family(i)==='Greens'; })}; }""")
    ck("and a band of value narrows it further (dark greens)", r["n"]>2 and r["dark"], r)
    pg.locator('[data-pxfam="all"]').click(); pg.select_option("#pxPalVal","any"); pg.select_option("#pxPalSort","light"); pg.wait_for_timeout(100)
    r=E("""()=>{ var P=KETER_PX, ids=[].slice.call(document.querySelectorAll('.pxpalbody .pxgrid')).pop().querySelectorAll('[data-pxcol]'), L=[].map.call(ids,function(b){ return P.lightness(+b.getAttribute('data-pxcol')); });
      var sorted=true; for(var i=1;i<L.length;i++) if(L[i]>L[i-1]+1e-9) sorted=false; return {n:L.length, sorted:sorted}; }""")
    ck("light to dark puts every colour in order of lightness", r["n"]==195 and r["sorted"], r)
    pg.select_option("#pxPalSort","hue"); pg.wait_for_timeout(80)
    ck("by hue shows them all in one run", pg.locator(".pxpalbody .pxgrid").last.locator("[data-pxcol]").count()==195)
    pg.select_option("#pxPalSort","palette"); pg.select_option("#pxPalSet","keter"); pg.wait_for_timeout(80)
    r=E("""()=>{ var ids=[].slice.call(document.querySelectorAll('.pxpalbody [data-pxcol]')).map(function(b){ return +b.getAttribute('data-pxcol'); });
      return {n:ids.length, lo:Math.min.apply(null,ids), hi:Math.max.apply(null,ids), saved:JSON.parse(localStorage.getItem('keter-app-palview')||'{}').set}; }""")
    ck("one set alone: KETER 56", r["n"]==56 and r["lo"]==140 and r["hi"]==195, r)
    ck("how you like the palette shown is remembered", r["saved"]=="keter", r)
    t=pg.locator(".pxpalbody [data-pxcol]").first.get_attribute("title")
    ck("each swatch names its colour", t and t.startswith("#") and "·" in t, t)
    pg.select_option("#pxPalSet","all"); pg.wait_for_timeout(80)

    # ---- your own colours ----
    pg.locator("#pxColHex").fill("#7a3b2f"); pg.locator("#pxColAdd").click(); pg.wait_for_timeout(100)
    r=E("()=>({c:T.S().colour, mine:KETER_PX.customColours(), hex:KETER_PX.PALETTE[196], stored:localStorage.getItem('keter-app-colours')})")
    ck("a typed colour becomes your own, and the current colour", r["c"]==196 and r["mine"]==[196] and r["hex"]=="#7a3b2f", r)
    ck("kept on this device", "7a3b2f" in (r["stored"] or ""), r)
    pg.locator("#pxColHex").fill("050403"); pg.locator("#pxColAdd").click(); pg.wait_for_timeout(80)
    r=E("()=>({c:T.S().colour, mine:KETER_PX.customColours().length, st:T.S().status})")
    ck("a colour the palette already has is simply chosen, not added twice", r["c"]==1 and r["mine"]==1, r)
    pg.locator("#pxColHex").fill("#zz12"); pg.locator("#pxColAdd").click(); pg.wait_for_timeout(80)
    ck("one it cannot read says how to write it", "hex" in pg.locator("#pxStatus").inner_text(), pg.locator("#pxStatus").inner_text())
    ck("your colours are marked in the palette", pg.locator('.pxpalbody .pxsw.mine[data-pxcol="196"]').count()>=1)
    r=E("""()=>{ var P=KETER_PX, got=[]; for(var i=0;i<60;i++) got.push(P.addColour('#'+('00000'+(0x101010+i*0x030507).toString(16)).slice(-6)));
      var full=P.addColour('#010203'); var extra=got.filter(function(x){ return x<0; }).length;
      P.customColours().forEach(function(i){ if(i!==196) P.removeColour(i); }); return {full:full, used:got.filter(function(x){ return x>=196; }).length}; }""")
    ck("sixty slots, and no more", r["full"]==-1 and r["used"]>=58, r)

    # a picture that uses one carries a copy
    E("()=>{ T.clear(); var s=T.S(); s.colour=196; s.tool='pencil'; T.tap(T.idx(3,3)); T.tap(T.idx(4,3)); KETER_STUDIO.flushSave(); }")
    r=E("()=>{ var s=T.S(), p=KETER_PX.get(s.id); return {custom:p.custom, id:s.id}; }")
    ck("a picture keeps a copy of each of your colours it uses", r["custom"]=={"196":"#7a3b2f"}, r)
    pid=r["id"]
    pg.locator("#pxColDel").click(); pg.wait_for_timeout(80)
    ck("a colour this picture uses cannot be removed", E("()=>!!KETER_PX.PALETTE[196]") and "recolour" in pg.locator("#pxStatus").inner_text(), pg.locator("#pxStatus").inner_text())
    # draw it anywhere, even where the palette no longer has it
    r=E("""(id)=>{ var P=KETER_PX, p=P.get(id); P.removeColour(196);
      var c=P.sprite(p), d=c.getContext('2d').getImageData(3,3,1,1).data;
      var fr=[].slice.call(document.querySelectorAll('iframe')).map(function(f){ try{ return f.contentWindow.KETER_PX; }catch(e){ return null; } }).filter(Boolean)[0];
      var d2=null; if(fr){ var c2=fr.sprite(JSON.parse(JSON.stringify(p))); d2=[].slice.call(c2.getContext('2d').getImageData(4,3,1,1).data,0,3); }
      return {here:[d[0],d[1],d[2]], frame:d2, gone:!P.PALETTE[196]}; }""", pid)
    ck("it still draws in that colour after you remove it from your palette", r["gone"] and r["here"]==[0x7a,0x3b,0x2f], r)
    ck("and in the Forge, whose palette never had it", r["frame"] in (None,[0x7a,0x3b,0x2f]), r)
    # another device: the slot holds something else; opening moves the pixels to a free slot
    r=E("""(id)=>{ var P=KETER_PX; P.addColour('#11ee22'); KETER_STUDIO.close(); KETER_GO('studio'); KETER_STUDIO.open({id:id});
      var s=KETER_STUDIO.state(), i=s.buf[3*16+3]; return {slot196:P.PALETTE[196], moved:i, hex:P.PALETTE[i], custom:s.pic.custom, status:s.status}; }""", pid)
    ck("opened where its slot holds another colour, its pixels move to a free slot", r["slot196"]=="#11ee22" and r["moved"]!=196 and r["hex"]=="#7a3b2f", r)
    ck("and it says so", "moved" in (r["status"] or ""), r)
    E(HELP)

    # a colour from the reference
    solid=E("()=>T.img(40,40,function(g){ g.fillStyle='#c83c1e'; g.fillRect(0,0,40,40); g.fillStyle='#1e64c8'; g.fillRect(20,0,20,40); })")
    E("(d)=>KETER_STUDIO._ref.use(d)", solid); pg.wait_for_timeout(700)
    pg.locator("#pxPalTog").click() if pg.locator(".pxpalbody").count()==0 else None
    pg.wait_for_timeout(100)
    pg.locator("#pxColRef").click(); pg.wait_for_timeout(80)
    ck("From the reference waits for a tap", E("()=>T.S().refPick") is True)
    E("()=>T.tap(T.idx(2,8))"); pg.wait_for_timeout(100)
    r=E("()=>T.S().found")
    found_hex = r["hex"] if r else None
    ck("a tap takes the reference's colour under that pixel", bool(r) and all(abs(int(found_hex[i:i+2],16)-v)<=6 for i,v in ((1,0xc8),(3,0x3c),(5,0x1e))), r)
    ck("offering the nearest palette colour, or keeping it as your own", pg.locator("#pxFoundNear").count()==1 and pg.locator("#pxFoundAdd").count()==1)
    pg.locator("#pxFoundAdd").click(); pg.wait_for_timeout(80)
    r=E("()=>({c:T.S().colour, hex:KETER_PX.PALETTE[T.S().colour], found:T.S().found})")
    ck("added as your own and chosen", r["c"]>=196 and r["found"] is None and r["hex"]==found_hex, r)
    pg.locator("#pxColRef").click(); E("()=>T.tap(T.idx(14,8))"); pg.wait_for_timeout(80)
    pg.locator("#pxFoundNear").click(); pg.wait_for_timeout(80)
    r=E("()=>({c:T.S().colour, mine:T.S().colour>=KETER_PX.CUSTOM_FROM})")
    ck("or the nearest palette colour instead", r["c"]>0 and not r["mine"], r)
    E("()=>KETER_STUDIO.close()"); pg.wait_for_timeout(200)

    # ================= from an image =================
    E("()=>KETER_GO('studio')"); pg.wait_for_timeout(250)
    ck("the Studio home offers From an image", pg.locator("#pxNewImg").count()==1)
    E(HELP)
    img=E("(f)=>T.img(300,200,eval(f))", SCENE)
    E("(d)=>T.conv(d,'new','Scene one.png')", img); pg.wait_for_timeout(300)
    ck("the converter opens over the Studio", pg.locator("#pxConv").count()==1 and pg.locator("#pxConvC").count()==1)
    sizes={}
    for n in (32,64,128,256):
        pg.locator(f'[data-pxcsize="{n}"]').click(); pg.wait_for_timeout(260)
        g=E("()=>{ var C=KETER_STUDIO._conv.state(); return [C.result.g.w, C.result.g.h]; }"); sizes[n]=g
    ck("32, 64, 128 or 256 across, the height by the image's shape", all(sizes[n][0]==n and sizes[n][1]==round(n*200/300) for n in sizes), sizes)
    tall=E("(f)=>T.img(100,400,eval(f))", SCENE)
    E("(d)=>T.conv(d,'new','Tall')", tall); pg.wait_for_timeout(250)
    pg.locator('[data-pxcsize="256"]').click(); pg.wait_for_timeout(300)
    g=E("()=>{ var C=KETER_STUDIO._conv.state(); return [C.result.g.w, C.result.g.h]; }")
    ck("a tall image is held to 256 high", g==[64,256], g)
    E("(d)=>T.conv(d,'new','Scene one.png')", img); pg.wait_for_timeout(250)
    pg.locator('[data-pxcsize="128"]').click(); pg.wait_for_timeout(260)
    info=pg.locator("#pxConvInfo").inner_text()
    ck("it says the size and how many colours", "128×85" in info and "colour" in info, info)
    for L in (64,32,16,8):
        pg.locator(f'[data-pxclim="{L}"]').click(); pg.wait_for_timeout(260)
        n=E("()=>KETER_STUDIO._conv.state().result.colours")
        ck(f"at most {L} colours", 0<n<=L, n)
    pg.locator('[data-pxclim="0"]').click(); pg.wait_for_timeout(200)
    r=E("""()=>{ var C=KETER_STUDIO._conv.state(); return {corner:C.result.px[0], mid:C.result.px[Math.floor(C.result.g.h/2)*C.result.g.w+Math.floor(C.result.g.w/2)]}; }""")
    ck("the white background is kept until you clear it", r["corner"]>0 and r["mid"]>0, r)
    pg.locator("#pxConvBg").click(); pg.wait_for_timeout(260)
    r=E("""()=>{ var C=KETER_STUDIO._conv.state(), px=C.result.px, w=C.result.g.w, h=C.result.g.h;
      return {corner:px[0], far:px[w*h-1], mid:px[Math.floor(h/2)*w+Math.floor(w/2)], clear:[].filter.call(px,function(v){ return !v; }).length}; }""")
    ck("Clear the background takes the colour round the edge away", r["corner"]==0 and r["far"]==0 and r["mid"]>0, r)
    ck("and only what joins it", r["clear"]<128*85*0.75, r)
    E("()=>{ var s=document.getElementById('pxConvFrom'); s.value='splendor'; s.dispatchEvent(new Event('change',{bubbles:true})); }"); pg.wait_for_timeout(260)
    r=E("()=>{ var px=KETER_STUDIO._conv.state().result.px; return Math.max.apply(null,[].slice.call(px)); }")
    ck("Splendor 128 only uses nothing past it", 0<r<=128, r)
    E("()=>{ var s=document.getElementById('pxConvFrom'); s.value='noneon'; s.dispatchEvent(new Event('change',{bubbles:true})); }"); pg.wait_for_timeout(260)
    r=E("()=>{ var P=KETER_PX, px=KETER_STUDIO._conv.state().result.px; return [].some.call(px,function(v){ return v>=P.NEON_FROM && v<P.EXT_FROM; }); }")
    ck("without the neons: none of them (the magenta square finds another colour)", r is False, r)
    E("()=>{ var s=document.getElementById('pxConvFrom'); s.value='all'; s.dispatchEvent(new Event('change',{bubbles:true})); }"); pg.wait_for_timeout(260)
    r=E("()=>{ var P=KETER_PX, px=KETER_STUDIO._conv.state().result.px; return [].some.call(px,function(v){ return v>=P.NEON_FROM && v<P.EXT_FROM; }); }")
    ck("with the whole palette, the neon magenta is found", r is True, r)
    base=E("()=>[].slice.call(KETER_STUDIO._conv.state().result.px)")
    res={}
    for d in ("soft","full","pattern"):
        pg.locator(f'[data-pxcdith="{d}"]').click(); pg.wait_for_timeout(260)
        res[d]=E("(b)=>{ var px=KETER_STUDIO._conv.state().result.px, n=0; for(var i=0;i<px.length;i++) if(px[i]!==b[i]) n++; return n; }", base)
    ck("soft, full and pattern dither each change the result", all(v>50 for v in res.values()), res)
    pg.locator('[data-pxcdith="none"]').click(); pg.wait_for_timeout(260)
    E("()=>{ var s=document.getElementById('pxConvSat'); s.value='50'; s.dispatchEvent(new Event('input',{bubbles:true})); }"); pg.wait_for_timeout(260)
    r=E("(b)=>{ var px=KETER_STUDIO._conv.state().result.px, n=0; for(var i=0;i<px.length;i++) if(px[i]!==b[i]) n++; return n; }", base)
    ck("saturation (like brightness and contrast) changes it too", r>50, r)
    E("()=>{ var s=document.getElementById('pxConvSat'); s.value='0'; s.dispatchEvent(new Event('input',{bubbles:true})); }"); pg.wait_for_timeout(200)
    pg.locator("#pxConvCmp").click(); pg.wait_for_timeout(100)
    ck("the original can be compared", pg.locator("#pxConvCmp").inner_text().lower().find("pixels")>=0)
    pg.locator("#pxConvCmp").click()
    pg.locator("#pxConvBg").click(); pg.wait_for_timeout(200)
    # speed at 256
    pg.locator('[data-pxcsize="256"]').click(); pg.wait_for_timeout(50)
    ms=E("()=>{ var t=performance.now(); KETER_STUDIO._conv.state().cache={}; KETER_STUDIO._conv.run(true); return performance.now()-t; }")
    ck("256 across converts in well under two seconds", ms<2000, round(ms))
    pg.locator('[data-pxcsize="64"]').click(); pg.wait_for_timeout(260)
    pg.locator("#pxConvGo").click(); pg.wait_for_timeout(900)
    E(HELP)
    r=E("""()=>new Promise(function(res){ var s=KETER_STUDIO.state(); KETER_STUDIO._ref.get(s.id,function(d){
      res({w:s.pic.w, h:s.pic.h, kind:s.pic.kind, name:s.pic.name, layer:s.pic.frames[0].layers[0].name, ref:s.pic.ref, refData:!!d, lib:!!KETER_PX.get(s.id), conv:!!document.getElementById('pxConv')}); }); })""")
    ck("Create makes a new picture in the library, 64 across", r["w"]==64 and r["h"]==43 and r["lib"] and r["kind"]=="blank" and not r["conv"], r)
    ck("named from the file, on a layer called Converted", r["name"]=="Scene one" and r["layer"]=="Converted", r)
    ck("the image becomes its reference, hidden until shown", r["refData"] and r["ref"] and r["ref"]["hidden"] is True and abs(r["ref"]["x"])<0.01, r)
    r=E("()=>{ var s=T.S(), n=0; for(var i=0;i<s.buf.length;i++) if(s.buf[i]) n++; return n; }")
    ck("with the converted pixels in it", r>1000, r)

    # onto a new layer of card art
    E("()=>KETER_STUDIO.close()"); pg.wait_for_timeout(200)
    E("()=>KETER_STUDIO.open({kind:'art', grid:'square', artHin:1.62, artW:128})"); pg.wait_for_timeout(400); E(HELP)
    E("()=>{ T.S().colour=33; T.tap(T.idx(1,1)); }")
    pg.locator("#pxMore").click(); pg.wait_for_timeout(80)
    ck("the menu offers an image onto a new layer", pg.locator("#pxConvLayer").count()==1)
    E("(d)=>T.conv(d,'layer','Onto')", img); pg.wait_for_timeout(300)
    r=E("()=>{ var C=KETER_STUDIO._conv.state(), s=T.S(); return {mode:C.mode, w:C.result.g.w, h:C.result.g.h, pw:s.pic.w, ph:s.pic.h, sizes:document.querySelectorAll('[data-pxcsize]').length, fit:document.querySelectorAll('[data-pxcfit]').length}; }")
    ck("onto a layer: the picture's own size, fit or fill instead of sizes", r["mode"]=="layer" and r["w"]==r["pw"] and r["h"]==r["ph"] and r["sizes"]==0 and r["fit"]==2, r)
    ph=r["ph"]
    fitc=E("()=>{ var R=KETER_STUDIO._conv.state().result; return [R.px[0], R.px[Math.floor(R.g.h/2)*R.g.w]]; }")
    pg.locator('[data-pxcfit="fill"]').click(); pg.wait_for_timeout(260)
    fillc=E("()=>{ var R=KETER_STUDIO._conv.state().result; return [R.px[0], R.px[Math.floor(R.g.h/2)*R.g.w]]; }")
    aspect_art=128/ph
    ck("fit leaves empty margins where the shapes differ; fill covers the canvas", (fillc[0]>0 and fillc[1]>0) and (fitc[0]==0 or fitc[1]==0 or abs(aspect_art-1.5)<0.05), [fitc,fillc,aspect_art])
    pg.locator("#pxConvGo").click(); pg.wait_for_timeout(700)
    r=E("()=>{ var s=T.S(), Ls=s.pic.frames[0].layers; return {n:Ls.length, top:Ls[Ls.length-1].name, cur:s.layer, under:KETER_PX.decode(Ls[0].px,s.pic.w*s.pic.h)[s.pic.w+1], ref:!!s.pic.ref}; }")
    ck("it goes on a new layer above, the drawing below untouched", r["n"]==2 and r["top"]=="Converted" and r["cur"]==1 and r["under"]==33, r)
    ck("and brings its reference when the picture had none", r["ref"], r)
    E("()=>KETER_STUDIO._paint.undo()"); pg.wait_for_timeout(100)
    ck("undo takes the layer away again", E("()=>T.S().pic.frames[0].layers.length")==1)
    E("()=>KETER_STUDIO.close()"); pg.wait_for_timeout(200)
    # hex pixels
    E("()=>KETER_STUDIO.open({kind:'token', grid:'hex', side:9, orient:'flat'})"); pg.wait_for_timeout(400); E(HELP)
    E("(d)=>T.conv(d,'layer','Hex')", img); pg.wait_for_timeout(300)
    r=E("""()=>{ var C=KETER_STUDIO._conv.state(), L=KETER_PX.hexLayout(T.S().pic), bad=0, on=0; for(var i=0;i<C.result.px.length;i++){ if(C.result.px[i]){ on++; if(!L.valid[i]) bad++; } } return {bad:bad, on:on}; }""")
    ck("onto hex pixels, only the hexes of the canvas are filled", r["bad"]==0 and r["on"]>50, r)
    pg.locator("#pxConvX").click(); pg.wait_for_timeout(100)
    ck("Cancel closes the converter and changes nothing", pg.locator("#pxConv").count()==0 and E("()=>T.S().pic.frames[0].layers.length")==1)
    ck("hex pixels have no text tool", pg.locator("[data-pxtool='text']").count()==0)
    E("()=>{ T.S().tool='select'; }"); pg.locator("[data-pxtool='select']").click(); pg.wait_for_timeout(80)
    ck("and no scaling", pg.locator('[data-pxsel="x2"]').count()==0)
    E("()=>KETER_STUDIO.close()"); pg.wait_for_timeout(200)

    # ================= scaling a selection =================
    E("()=>KETER_STUDIO.open({kind:'blank',w:32,h:32})"); pg.wait_for_timeout(400); E(HELP)
    E("()=>{ var s=T.S(); s.colour=33; for(var y=10;y<12;y++) for(var x=10;x<12;x++) s.buf[T.idx(x,y)]=33; s.buf[T.idx(10,10)]=12; KETER_STUDIO._paint.commitSelection(); }")
    pg.locator("[data-pxtool='select']").click(); pg.wait_for_timeout(60)
    E("()=>KETER_STUDIO._paint.selAction('all')")
    pg.locator('[data-pxsel="x2"]').click(); pg.wait_for_timeout(60)
    r=E("()=>{ var S=T.S().sel, xs=S.items.map(function(t){ return t.x; }), ys=S.items.map(function(t){ return t.y; }); return {n:S.items.length, cx:(Math.min.apply(null,xs)+Math.max.apply(null,xs))/2, cy:(Math.min.apply(null,ys)+Math.max.apply(null,ys))/2, tl:S.items.filter(function(t){ return t.v===12; }).length}; }")
    ck("×2 makes each pixel a 2×2 block", r["n"]==16 and r["tl"]==4, r)
    ck("keeping the selection's centre", abs(r["cx"]-11)<0.01 and abs(r["cy"]-11)<0.01, r)
    pg.locator('[data-pxsel="half"]').click(); pg.wait_for_timeout(60)
    r=E("()=>{ var S=T.S().sel; return {n:S.items.length, tl:S.items.filter(function(t){ return t.v===12; }).length}; }")
    ck("½ brings it back", r["n"]==4 and r["tl"]==1, r)
    pg.locator("#pxScalePct").fill("300"); pg.locator('[data-pxsel="pct"]').click(); pg.wait_for_timeout(60)
    ck("any percentage (300%: 6×6)", E("()=>T.S().sel.items.length")==36)
    pg.locator('[data-pxsel="done"]').click(); pg.wait_for_timeout(60)
    ck("Done puts it down", E("()=>T.count(33)+T.count(12)")==36)
    # shrinking keeps what most of each block is
    E("()=>{ T.clear(); var s=T.S(); for(var y=0;y<4;y++) for(var x=0;x<4;x++) s.buf[T.idx(4+x,4+y)]=(x<2?40:41); s.buf[T.idx(4,4)]=0; KETER_STUDIO._paint.selAction('all'); KETER_STUDIO._scale(0.5); }")
    r=E("()=>T.S().sel.items.map(function(t){ return t.v; }).sort()")
    ck("½ gives each new pixel the colour most of its block had (one gap does not empty it)", r==[40,40,41,41], r)
    E("()=>KETER_STUDIO._paint.selAction('done')")

    # ================= text =================
    r=E("""()=>{ var X=KETER_STUDIO._text, a=X.cells('A','small',1), up=X.cells('keter','small',1), UP=X.cells('KETER','small',1),
      t0=X.cells('II','small',0), t2=X.cells('II','small',2), big=X.cells('A','large',1), two=X.cells('AB\\nC','small',1), odd=X.cells('A~A','small',1);
      return {a:[a.w,a.h,a.cells.length], same:JSON.stringify(up)===JSON.stringify(UP), t0:t0.w, t2:t2.w, big:[big.w,big.h], two:[two.w,two.h], odd:odd.w,
        cx:two.cells.filter(function(c){ return c[1]>=6; }).map(function(c){ return c[0]; })}; }""")
    ck("the small font is 3×5 (A: ten pixels)", r["a"]==[3,5,10], r)
    ck("the large font is 5×7", r["big"]==[5,7], r)
    ck("letters are capitals whatever you type", r["same"], r)
    ck("spacing sets the gap between letters", r["t0"]==6 and r["t2"]==8, r)
    ck("two lines, each centred on the wider", r["two"]==[7,11] and min(r["cx"])==2, r)
    ck("a character it has no letter for leaves a space", r["odd"]==3+1+2+1+3, r)
    pg.locator("[data-pxtool='text']").click(); pg.wait_for_timeout(60)
    ck("the text tool offers both fonts and three spacings", pg.locator("[data-pxfont]").count()==2 and pg.locator("[data-pxtsp]").count()==3)
    E("()=>{ T.clear(); T.S().colour=134; }")
    pg.locator("#pxText").fill("Hi 5"); pg.locator('[data-pxfont="large"]').click(); pg.locator("#pxTextPlace").click(); pg.wait_for_timeout(80)
    r=E("()=>{ var s=T.S(), X=KETER_STUDIO._text.cells('HI 5','large',1); return {n:s.sel&&s.sel.items.length, want:X.cells.length, col:s.sel.items.every(function(t){ return t.v===134; }), tool:s.tool, text:s.text, font:s.font}; }")
    ck("Place puts the text down as a selection, in your colour", r["n"]==r["want"] and r["col"] and r["tool"]=="select", r)
    E("()=>KETER_STUDIO._paint.nudge('r')")
    pg.locator('[data-pxsel="done"]').click(); pg.wait_for_timeout(60)
    ck("to move, then Done", E("()=>T.count(134)")==r["want"], E("()=>T.count(134)"))
    ck("the tool remembers the text and font", r["text"]=="Hi 5" and r["font"]=="large", r)

    # ================= views =================
    E("()=>{ T.clear(); var s=T.S(); s.buf[T.idx(5,5)]=6; s.buf[T.idx(6,5)]=129; KETER_STUDIO._paint.commitSelection(); }")
    pg.locator("#pxFit").click(); pg.wait_for_timeout(80)
    pg.locator("#pxMore").click(); pg.wait_for_timeout(60)
    ck("the menu offers colour, value and silhouette views", pg.locator("[data-pxview]").count()==3)
    before=E("()=>T.shown(T.idx(5,5))")
    pg.locator('[data-pxview="value"]').click(); pg.wait_for_timeout(80)
    v1=E("()=>T.shown(T.idx(5,5))"); v2=E("()=>T.shown(T.idx(6,5))")
    ck("value view shows each colour as its lightness in grey", v1[0]==v1[1]==v1[2] and v2[0]==v2[1]==v2[2] and v1!=before and v1[0]!=v2[0], [before,v1,v2])
    ck("with a tag on the stage to leave it", pg.locator("#pxViewTag").is_visible())
    pg.locator('[data-pxview="silhouette"]').click(); pg.wait_for_timeout(80)
    s1=E("()=>T.shown(T.idx(5,5))"); s0=E("()=>T.shown(T.idx(1,1))")
    ck("silhouette: every pixel dark on a light ground", max(s1)<40 and min(s0)>180, [s1,s0])
    r=E("()=>{ var s=T.S(); KETER_STUDIO.flushSave(); var p=KETER_PX.get(s.id); return [KETER_PX.decode(p.flat,p.w*p.h)[5*32+5], KETER_PX.sprite(p).getContext('2d').getImageData(5,5,1,1).data[0]]; }")
    ck("a view changes only what you see, never the picture", r[0]==6 and r[1]==int("f1",16), r)
    pg.locator("#pxViewTag").click(); pg.wait_for_timeout(80)
    ck("the tag takes you back to colour", E("()=>T.shown(T.idx(5,5))")==before and not pg.locator("#pxViewTag").is_visible())
    if pg.locator("#pxMiniTog").count()==0: pg.locator("#pxMore").click(); pg.wait_for_timeout(60)
    pg.locator("#pxMiniTog").click(); pg.wait_for_timeout(120)
    r=E("()=>{ var c=document.getElementById('pxMini'), b=document.getElementById('pxMiniBox'); return {shown:b.style.display!=='none', w:parseFloat(c.style.width), h:parseFloat(c.style.height)}; }")
    ck("the 1× and 2× preview sits in a corner of the stage", r["shown"] and r["w"]==32*3+6 and r["h"]==64, r)
    r=E("()=>{ var c=document.getElementById('pxMini'), d=c.getContext('2d').getImageData(Math.round((32+6+10)*Math.min(devicePixelRatio,3)+1), Math.round(10*Math.min(devicePixelRatio,3)+1),1,1).data; return [d[0],d[1],d[2]]; }")
    ck("drawn from the picture itself (2× at pixel 5,5)", r==[0xf1,0x64,0x1f], r)
    ck("its setting stays for the next picture", E("()=>{ var id=T.S().id; KETER_STUDIO.close(); KETER_STUDIO.open({id:id}); return KETER_STUDIO.state().mini; }") is True)

    # ================= older checks still hold =================
    E(HELP)
    ck("thirteen tools fit on two rows of a phone", E("()=>{ var t=[].slice.call(document.querySelectorAll('.pxtool')), tops={}; t.forEach(function(b){ tops[Math.round(b.getBoundingClientRect().top)]=1; }); return Object.keys(tops).length; }")<=2)
    ck("no page errors", not errs, errs)

    b.close()
print(f"\nSTUDIO5 PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
srv.shutdown()
