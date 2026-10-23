"""Pixel Studio v14.3: frames. A picture of several frames, each with its
layers, played at its speed: the strip under the canvas (tap a frame to draw on
it; add, copy, move, delete), onion skin, Play, the speed, undo; PNGs with the
frames side by side. And game 0.16's slots: the fight's five effects, each the
game's own picture of several frames at its speed, the turn strip's and End
turn's icons, and Export for Godot carrying a picture's frames, how many and
how fast."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json, base64, io
from playwright.sync_api import sync_playwright
from PIL import Image
TMP=pathlib.Path("/tmp/serve_frames")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9763),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""):
    (ok if c else bad).append(n+((" — "+str(d)[:260]) if not c else ""))
    print(("PASS " if c else "FAIL ")+n+("" if c else "  — "+str(d)[:260]))

HELP=r"""()=>{
  window.T={
    S:function(){ return KETER_STUDIO.state(); },
    xy:function(i){ var s=KETER_STUDIO.state(), v=KETER_STUDIO.view(), c=s.grid.centre(i,s.pic); return {x:v.x+c.x*v.z, y:v.y+c.y*v.z}; },
    tap:function(i,col){ var s=KETER_STUDIO.state(); s.tool='pencil'; s.size=1; s.mirror='off'; if(col) s.colour=col; var P=KETER_STUDIO._paint, A=T.xy(i); P.down(A.x,A.y); P.up(); },
    has:function(v){ return KETER_STUDIO.state().buf.indexOf(v)>=0; },
    frameHas:function(f,v){ var s=KETER_STUDIO.state(), P=KETER_PX; return Array.prototype.indexOf.call(P.flatten(s.pic,f),v)>=0; },
    shown:function(i){ var s=KETER_STUDIO.state(), v=KETER_STUDIO.view(), c=s.grid.centre(i,s.pic), cv=document.getElementById('pxCanvas');
      var d=cv.getContext('2d').getImageData(Math.round((v.x+c.x*v.z)*v.dpr), Math.round((v.y+c.y*v.z)*v.dpr),1,1).data; return [d[0],d[1],d[2]]; },
    click:function(sel){ var b=document.querySelector(sel); if(!b) return false; b.click(); return true; },
    rgb:function(i){ return KETER_PX.RGB[i]; }
  }; return true; }"""

with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},device_scale_factor=2).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("dialog",lambda d:d.accept())
    pg.goto("http://127.0.0.1:9763/"); pg.wait_for_timeout(2200)
    E=pg.evaluate
    E(HELP)

    # ================= the pixel library =================
    r=E("""()=>{ var P=KETER_PX, pic=P.blankFrames(8,6,3,'x',10);
      pic.frames[0].layers[0].name='Ink'; pic.frames[0].layers.push({name:'Glow',visible:true,locked:false,opacity:60,mode:'snap',px:P.encode(new Uint8Array(48))});
      var like=P.emptyFrameLike(pic,0);
      return {n:P.frameCount(pic), fps:pic.fps, empty:pic.frames.every(function(f){ return Array.prototype.every.call(P.decode(f.layers[0].px,48),function(v){ return !v; }); }),
        like:like.layers.map(function(L){ return [L.name,L.opacity,L.mode]; }), one:P.frameCount(P.blank(4,4,'y'))}; }""")
    ck("library: a blank picture of three frames at 10 a second, each empty", r["n"]==3 and r["fps"]==10 and r["empty"], r)
    ck("library: a new frame is like another, its layers named and set the same, empty", r["like"]==[["Ink",100,"view"],["Glow",60,"snap"]] and r["one"]==1, r)
    r=E("""()=>{ var P=KETER_PX, pic=P.blank(4,4,'m');
      var old=function(p){ var t=JSON.stringify([p.w,p.h,p.frames]), h=5381; for(var i=0;i<t.length;i++) h=((h*33)^t.charCodeAt(i))>>>0; return h.toString(36); };
      var a=P.mark(pic), same=a===old(pic); pic.fps=12; var b=P.mark(pic); pic.fps=14; var c=P.mark(pic);
      return {same:same, b:a!==b, c:b!==c}; }""")
    ck("library: a picture's fingerprint is what it was unless it has a speed; with one, the speed counts", r["same"] and r["b"] and r["c"], r)
    r=E("""()=>{ var P=KETER_PX, pic=P.blankFrames(4,2,3,'s',8), cols=[33,10,45];
      for(var f=0;f<3;f++){ var px=new Uint8Array(8); px[f]=cols[f]; pic.frames[f].layers[0].px=P.encode(px); }
      var c=P.stripCanvas(pic,1), g=c.getContext('2d'), out=[];
      for(var f2=0;f2<3;f2++){ var d=g.getImageData(f2*4+f2,0,1,1).data; out.push([d[0],d[1],d[2],d[3]]); }
      var s1=P.frameSprite(pic,1).getContext('2d').getImageData(1,0,1,1).data;
      return {w:c.width, h:c.height, px:out, want:cols.map(function(i){ return P.RGB[i]; }), s1:[s1[0],s1[1],s1[2],s1[3]], c2:P.stripCanvas(pic,2).width}; }""")
    ck("library: a picture's frames side by side, first to last, each its own pixels", r["w"]==12 and r["h"]==2 and r["c2"]==24 and all(r["px"][i][:3]==r["want"][i] and r["px"][i][3]==255 for i in range(3)), r)
    ck("library: one frame drawn as the first is", r["s1"][:3]==r["want"][1] and r["s1"][3]==255, r["s1"])

    # ================= the Studio: a blank canvas =================
    E("()=>{ KETER_STUDIO.open({kind:'blank', w:16, h:16, grid:'square', from:'studio'}); }"); pg.wait_for_timeout(400)
    r=E("()=>{ var b=document.getElementById('pxFrTog'); return {txt:b?b.textContent:null, strip:!!document.querySelector('.pxfrstrip'), f:T.S().frame}; }")
    ck("studio: a picture of one frame has Frames, folded away", r["txt"] and r["txt"].startswith("Frames · 1") and not r["strip"] and r["f"]==0, r)
    E("()=>T.click('#pxFrTog')"); pg.wait_for_timeout(100)
    r=E("()=>({thumbs:document.querySelectorAll('[data-pxfr]').length, play:document.getElementById('pxFrPlay').disabled, del:document.getElementById('pxFrDel').disabled, fps:document.getElementById('pxFps').value, onion:document.getElementById('pxOnion').textContent})")
    ck("studio: open, the strip shows its one frame; Play and Delete wait for a second", r["thumbs"]==1 and r["play"] and r["del"] and r["fps"]=="12" and "on" in r["onion"], r)
    A,B,C=33,10,45
    E("(c)=>T.tap(5*16+5,c)", A); pg.wait_for_timeout(50)
    E("()=>T.click('#pxFrAdd')"); pg.wait_for_timeout(150)
    r=E("(a)=>({n:KETER_PX.frameCount(T.S().pic), f:T.S().frame, hasA:T.has(a), layers:T.S().pic.frames[1].layers.length, fps:T.S().pic.fps, thumbs:document.querySelectorAll('[data-pxfr]').length, on:document.querySelector('.pxfr.on').getAttribute('data-pxfr')})", A)
    ck("studio: + Frame adds a blank frame after this one, with its layers, and goes to it", r["n"]==2 and r["f"]==1 and not r["hasA"] and r["layers"]==1 and r["fps"]==12 and r["thumbs"]==2 and r["on"]=="1", r)
    E("(c)=>T.tap(5*16+9,c)", B); pg.wait_for_timeout(50)
    r=E("(a)=>({views:KETER_STUDIO._frames.views().map(function(v){ return v.alpha; }), onion:KETER_STUDIO._frames.onion(), at:T.shown(5*16+5), full:T.rgb(a), empty:T.shown(2*16+2)})", A)
    blend=r["at"]!=r["full"] and r["at"]!=r["empty"]
    ck("studio: onion skin: the frame before shows faintly under this one", r["onion"] and r["views"][0]<0.5 and len(r["views"])==2 and blend, r)
    E("()=>T.click('#pxOnion')"); pg.wait_for_timeout(80)
    r=E("()=>({onion:KETER_STUDIO._frames.onion(), at:T.shown(5*16+5), empty:T.shown(5*16+7)})")
    ck("studio: Onion skin off: it doesn't", not r["onion"] and r["at"]==r["empty"], r)
    E("()=>T.click('#pxOnion')")
    E("()=>T.click('[data-pxfr=\"0\"]')"); pg.wait_for_timeout(80)
    r=E("(ab)=>({f:T.S().frame, a:T.has(ab[0]), b:T.has(ab[1]), onion:KETER_STUDIO._frames.onion(), f1b:T.frameHas(1,ab[1])})", [A,B])
    ck("studio: tap a frame to draw on it: each keeps its own pixels", r["f"]==0 and r["a"] and not r["b"] and r["f1b"] and not r["onion"], r)
    E("()=>T.click('#pxFrCopy')"); pg.wait_for_timeout(100)
    r=E("(a)=>({n:KETER_PX.frameCount(T.S().pic), f:T.S().frame, a:T.has(a), order:[0,1,2].map(function(i){ return [T.frameHas(i,33),T.frameHas(i,10)]; })})", A)
    ck("studio: Copy frame copies this one after it, and goes to the copy", r["n"]==3 and r["f"]==1 and r["a"] and r["order"]==[[True,False],[True,False],[False,True]], r)
    E("()=>T.click('#pxFrRight')"); pg.wait_for_timeout(80)
    r=E("()=>({f:T.S().frame, order:[0,1,2].map(function(i){ return [T.frameHas(i,33),T.frameHas(i,10)]; }), right:document.getElementById('pxFrRight').disabled})")
    ck("studio: Later moves it along the strip", r["f"]==2 and r["order"]==[[True,False],[False,True],[True,False]] and r["right"], r)
    E("()=>T.click('#pxFrLeft')"); pg.wait_for_timeout(80)
    r=E("()=>({f:T.S().frame, order:[0,1,2].map(function(i){ return [T.frameHas(i,33),T.frameHas(i,10)]; })})")
    ck("studio: Earlier moves it back", r["f"]==1 and r["order"]==[[True,False],[True,False],[False,True]], r)
    E("()=>T.click('#pxFrDel')"); pg.wait_for_timeout(80)
    r=E("()=>({n:KETER_PX.frameCount(T.S().pic), f:T.S().frame, order:[0,1].map(function(i){ return [T.frameHas(i,33),T.frameHas(i,10)]; })})")
    ck("studio: Delete frame takes it out, and goes to the one before", r["n"]==2 and r["f"]==0 and r["order"]==[[True,False],[False,True]], r)
    E("()=>KETER_STUDIO._paint.undo()"); pg.wait_for_timeout(80)
    r=E("()=>({n:KETER_PX.frameCount(T.S().pic), f:T.S().frame})")
    ck("studio: Undo brings the frame back", r["n"]==3 and r["f"]==1, r)
    E("()=>KETER_STUDIO._paint.redo()"); pg.wait_for_timeout(80)
    r=E("()=>({n:KETER_PX.frameCount(T.S().pic), f:T.S().frame})")
    ck("studio: and Redo takes it out again", r["n"]==2 and r["f"]==0, r)
    # pixel undo knows its frame
    E("()=>T.click('[data-pxfr=\"1\"]')"); pg.wait_for_timeout(50)
    E("(c)=>T.tap(9*16+9,c)", C); pg.wait_for_timeout(50)
    E("()=>T.click('[data-pxfr=\"0\"]')"); pg.wait_for_timeout(50)
    E("()=>KETER_STUDIO._paint.undo()"); pg.wait_for_timeout(80)
    r=E("(c)=>({f:T.S().frame, c:T.has(c), f1c:T.frameHas(1,c), f1b:T.frameHas(1,10)})", C)
    ck("studio: Undo of a stroke goes back to its frame, and takes it back there", r["f"]==1 and not r["c"] and not r["f1c"] and r["f1b"], r)
    # the speed
    E("()=>{ var i=document.getElementById('pxFps'); i.value='8'; i.dispatchEvent(new Event('change',{bubbles:true})); KETER_STUDIO.flushSave(); }")
    r=E("()=>{ var s=T.S(), saved=KETER_PX.get(s.id); return {fps:s.pic.fps, saved:saved&&saved.fps, frames:saved&&saved.frames.length}; }")
    ck("studio: the speed is the picture's, saved with it, with its frames", r["fps"]==8 and r["saved"]==8 and r["frames"]==2, r)
    # play
    E("()=>T.click('#pxFrPlay')"); pg.wait_for_timeout(60)
    seen=set()
    for i in range(10):
        seen.add(E("()=>T.S().playAt")); pg.wait_for_timeout(70)
    r=E("()=>({playing:T.S().playing, views:KETER_STUDIO._frames.views().length, label:document.getElementById('pxFrPlay').textContent})")
    ck("studio: Play runs the frames in turn on the canvas, at its speed", r["playing"] and seen=={0,1} and r["views"]==1 and "Stop" in r["label"], [r, seen])
    box=E("()=>{ var R=document.getElementById('pxCanvas').getBoundingClientRect(); return [R.left,R.top]; }")
    before=E("()=>KETER_PX.encode(KETER_PX.flatten(T.S().pic,0))+KETER_PX.encode(KETER_PX.flatten(T.S().pic,1))")
    pg.mouse.click(box[0]+20, box[1]+20)
    pg.wait_for_timeout(80)
    after=E("()=>KETER_PX.encode(KETER_PX.flatten(T.S().pic,0))+KETER_PX.encode(KETER_PX.flatten(T.S().pic,1))")
    r=E("()=>({playing:T.S().playing, n:KETER_PX.frameCount(T.S().pic), label:document.getElementById('pxFrPlay').textContent})")
    ck("studio: a tap on the canvas stops it (and draws nothing)", not r["playing"] and "Play" in r["label"] and before==after, r)
    # PNG
    r=E("()=>{ var c=KETER_STUDIO.pngCanvas(T.S().pic,2); return [c.width,c.height]; }")
    ck("studio: Export as PNG: the frames side by side", r==[64,32], r)
    r=E("()=>{ KETER_STUDIO.flushSave(); var s=T.S(), saved=KETER_PX.get(s.id); return {flat0:saved.flat===KETER_PX.encode(KETER_PX.flatten(saved,0)), n:saved.frames.length}; }")
    ck("studio: everywhere a picture shows as one, it shows its first frame", r["flat0"] and r["n"]==2, r)
    E("()=>KETER_STUDIO.close()"); pg.wait_for_timeout(200)

    # ================= game 0.16's slots =================
    r=E("""()=>{ var A=KETER_ASSETS, P=KETER_PX, fx=A.slots().filter(function(s){ return s.group==='effects'; });
      return fx.map(function(s){ var pic=A.pics(s.id)[0]; return [s.id, s.w, s.h, s.frames, s.fps, pic?P.frameCount(pic):0, pic?pic.fps:0, pic?[pic.w,pic.h]:null, !!(pic&&A.gamesOwn(pic))]; }); }""")
    want=[["fight.fx.flash",24,24,4,20],["fight.fx.impact",32,32,5,16],["fight.fx.explosion",48,48,8,14],["fight.fx.heal",32,48,6,12],["fight.fx.shield",48,48,6,14],
          ["fight.fx.ember",8,8,4,8],["fight.fx.spark",12,12,3,16],["fight.fx.ash",8,8,3,4],["fight.fx.dust",6,6,2,3]]
    good=len(r)==9 and all(r[i][:5]==want[i] and r[i][5]==want[i][3] and r[i][6]==want[i][4] and r[i][7]==[want[i][1],want[i][2]] and r[i][8] for i in range(9))
    ck("slots: Effects: the five, and (v14.5) the atmosphere's four motes, each with the game's own picture, its frames and its speed", good, r)
    r=E("""()=>{ var A=KETER_ASSETS, P=KETER_PX; return ['act_move','act_attack','act_end'].map(function(k){ var s=A.slot('ui.icon.'+k), pic=A.pics('ui.icon.'+k)[0]; return [!!s, s&&s.group, pic?[pic.w,pic.h]:null, !!(pic&&A.gamesOwn(pic))]; })
      .concat([[A.slot('ui.status.overwatch').what]]); }""")
    ck("slots: the turn strip's Move and Attack, and End turn, each with the game's icon", all(x[0] and x[1]=="ui" and x[2]==[16,16] and x[3] for x in r[:3]), r)
    ck("slots: Holding fire's icon says it is on Hold fire in the turn strip too", "turn strip" in r[3][0], r[3])
    r=E("""()=>{ var A=KETER_ASSETS, P=KETER_PX, pic=A.blankFor(A.slot('fight.fx.explosion')); return [P.frameCount(pic), pic.fps, pic.w, pic.h, pic.slot]; }""")
    ck("slots: a new picture for an effect starts with the game's count of frames and speed", r==[8,14,48,48,"fight.fx.explosion"], r)
    # the export: nothing of the game's own, until one is drawn on
    r=E("()=>KETER_ASSETS.build().manifest.files.filter(function(f){ return /^fight\\/effects\\//.test(f.file); }).length")
    ck("export: the game's own effects stay out", r==0, r)
    r=E("""()=>{ var A=KETER_ASSETS, P=KETER_PX, id=A.ids('fight.fx.impact')[0], pic=P.get(id), n=pic.w*pic.h;
      var px=P.decode(pic.frames[2].layers[0].px,n); px[0]=45; pic.frames[2].layers[0].px=P.encode(px); pic.fps=10; P.put(pic,id);
      var r=A.build(), m=r.manifest.files.filter(function(f){ return f.file==='fight/effects/impact.png'; })[0];
      var c=A.pngCanvas(P.get(id)); return {m:m, w:c.width, h:c.height, own:A.gamesOwn(P.get(id))}; }""")
    m=r["m"] or {}
    ck("export: one drawn on goes, its frames side by side, saying how many and how fast", m.get("frames")==5 and m.get("fps")==10 and m.get("w")==32 and m.get("h")==32 and r["w"]==160 and r["h"]==32 and not r["own"] and m.get("owner",{}).get("slot")=="fight.fx.impact", r)
    # the PNG in the zip really is the strip
    b64=E("""()=>{ var r=KETER_ASSETS.build(); var u=r.bytes, s=''; for(var i=0;i<u.length;i++) s+=String.fromCharCode(u[i]); return btoa(s); }""")
    import zipfile
    z=zipfile.ZipFile(io.BytesIO(base64.b64decode(b64)))
    im=Image.open(io.BytesIO(z.read("fight/effects/impact.png"))).convert("RGBA")
    ck("export: the zip's PNG is 5 frames of 32 by 32, side by side, the drawn-on pixel in the third", im.size==(160,32) and im.getpixel((64,0))[3]==255, [im.size, im.getpixel((64,0))])
    # the Assets tab
    E("()=>{ KETER_STUDIO.tab('assets'); KETER_STUDIO.render(document.getElementById('v-studio')); }")
    pg.wait_for_timeout(200)
    E("()=>{ var b=document.querySelector('[data-asf=\"effects\"]'); if(b) b.click(); }"); pg.wait_for_timeout(200)
    r=E("()=>{ var rows=[].slice.call(document.querySelectorAll('.asslot')); return {seg:!!document.querySelector('[data-asf=\"effects\"].on'), rows:rows.map(function(x){ return x.querySelector('i').textContent; }), note:(document.querySelector('#pxTab .pxnote:nth-of-type(3)')||{}).textContent||''}; }")
    ck("assets tab: Effects, a row for each (v14.5: the motes too), saying its frames and speed", r["seg"] and len(r["rows"])==9 and all("frames at" in x for x in r["rows"]) and "5 frames at 10 a second" in " ".join(r["rows"]), r["rows"])
    E("()=>{ var b=document.querySelector('[data-asf=\"ui\"]'); if(b) b.click(); }"); pg.wait_for_timeout(150)
    r=E("()=>[].slice.call(document.querySelectorAll('.asslot b')).map(function(x){ return x.textContent; })")
    ck("assets tab: Game look lists the Move, Attack and End turn icons", all(n in r for n in ["Move icon","Attack icon","End turn icon"]), [n for n in r if "icon" in n][-12:])

    ck("no page errors", not errs, errs)
    b.close()
srv.shutdown()
print("\nPASS %d  FAIL %d" % (len(ok), len(bad)))
for x in bad: print("  ✗", x)
sys.exit(1 if bad else 0)
