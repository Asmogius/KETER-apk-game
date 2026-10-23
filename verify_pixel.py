"""Pixel art, stage one: the palette, storage, layers, the library, art on cards
(holding the art box at its height), tokens on the board, and the fix for cards
whose abilities were stored under a name the renderer never read."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_pixel")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
comp=json.load(open("compendium_full.json"))
for x in comp["cards"]:
    if x["name"]=="Test Warden": x["pixelToken"]="px_t_tok"; x["pixelArt"]="px_t_art"
    # the test cards ship with tokens now; this one is left without, to check the label
    if x["name"]=="Test Striker": x.pop("pixelToken",None)
json.dump(comp,open(TMP/"compendium.json","w"))
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9957),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))

# ---- the card data ----
raw=json.load(open("compendium_full.json"))["cards"]
ck("no card stores its abilities under the old name", not any(x.get("abilities") for x in raw))
ck("the cards that did still have their abilities",
   all(x.get("entries") for x in raw if x["name"] in ("Quillon Vex","Ledger Runner","Slag Hauler")))

SEED=r"""()=>{
  var P=window.KETER_PX, t=new Uint8Array(32*32), a=new Uint8Array(64*30);
  for(var y=8;y<24;y++) for(var x=8;x<24;x++) t[y*32+x]=P.NEON_FROM+5;
  for(var i=0;i<a.length;i++) a[i]=P.NEON_FROM+2;
  var tok=P.blank(32,32); tok.frames[0].layers[0].px=P.encode(t);
  var art=P.blank(64,30); art.frames[0].layers[0].px=P.encode(a);
  P.put(tok,'px_t_tok'); P.put(art,'px_t_art'); return true; }"""

with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},device_scale_factor=3,is_mobile=True,has_touch=True).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.goto("http://127.0.0.1:9957/"); pg.wait_for_timeout(2200)

    # ---- palette and storage ----
    r=pg.evaluate("""()=>{ var P=window.KETER_PX; return {n:P.PALETTE.length-1, zero:P.PALETTE[0], first:P.PALETTE[1],
      neons:P.NEON.length, neonFrom:P.NEON_FROM, lastNeon:P.PALETTE[P.EXT_FROM-1], ext:P.EXT.length, extFrom:P.EXT_FROM,
      custom:P.CUSTOM_FROM, built:P.PALETTE.slice(1,P.CUSTOM_FROM).filter(Boolean).length}; }""")
    ck("the palette has 255 slots (v12.5)", r["n"]==255, r)
    ck("colour zero is transparent", r["zero"] is None)
    ck("it begins with Splendor 128", r["first"]=="#050403")
    ck("then the eleven neons", r["neons"]==11 and r["neonFrom"]==129 and r["lastNeon"]=="#f0ff2a", r)
    ck("then KETER 56, and the rest are your own", r["ext"]==56 and r["extFrom"]==140 and r["custom"]==196 and r["built"]==195, r)
    r=pg.evaluate("""()=>{ var P=window.KETER_PX, a=new Uint8Array(64*45);
      for(var i=0;i<a.length;i++) a[i]=(i*7)%140; var e=P.encode(a), d=P.decode(e,a.length), same=true;
      for(var k=0;k<a.length;k++) if(a[k]!==d[k]){ same=false; break; }
      var flatArt=new Uint8Array(64*45).fill(40); return {same:same, busy:e.length, flat:P.encode(flatArt).length}; }""")
    ck("pictures are stored exactly", r["same"])
    ck("a plain picture takes very little room", r["flat"]<100, r)
    ck("even a busy one stays small", r["busy"]<12000, r)

    # ---- layers ----
    r=pg.evaluate("""()=>{ var P=window.KETER_PX, pic=P.blank(4,1);
      pic.frames[0].layers[0].px=P.encode(new Uint8Array([9,9,9,9]));
      pic.frames[0].layers.push({name:'top',visible:true,opacity:50,mode:'dither',px:P.encode(new Uint8Array([130,130,130,130]))});
      var out={dither:Array.from(P.flatten(pic))};
      pic.frames[0].layers[1].mode='snap'; out.snap=Array.from(P.flatten(pic));
      pic.frames[0].layers[1].mode='view'; out.view=Array.from(P.flatten(pic));
      pic.frames[0].layers[1].visible=false; out.hidden=Array.from(P.flatten(pic));
      return out; }""")
    ck("dither opacity makes a checkerboard", r["dither"]==[130,9,130,9], r["dither"])
    ck("snap opacity stays inside the palette", all(0<v<=195 for v in r["snap"]), r["snap"])
    ck("view opacity leaves the layer whole", r["view"]==[130]*4)
    ck("a hidden layer is left out", r["hidden"]==[9]*4)

    # ---- the library ----
    r=pg.evaluate("""()=>{ var P=window.KETER_PX, a=P.blank(2,2), id=P.put(a), c=P.copy(id);
      var cp=P.get(c); cp.name='changed'; P.put(cp,c);
      return {differs:id!==c, original:P.get(id).name, copy:P.get(c).name}; }""")
    ck("reusing a picture copies it by default", r["differs"])
    ck("so editing the copy leaves the original alone", r["original"]!="changed" and r["copy"]=="changed", r)

    # ---- the art canvas matches the box ----
    r=pg.evaluate("()=>[window.KETER_PX.artSizeFor(1.62), window.KETER_PX.artSizeFor(0.81)]")
    ck("art is 64 pixels wide, as tall as the art box", r[0]["w"]==64 and r[0]["h"]==45 and r[1]["h"]==22, r)

    # ---- tokens: crisp, and filling their hexagon ----
    r=pg.evaluate("""()=>{ var P=window.KETER_PX, ctx={drawImage:function(){}}, pic=P.blank(32,32), out=[];
      [[20.9,3],[20.9,2],[30,3],[14,2]].forEach(function(c){ var d=P.draw(ctx,pic,0,0,c[0],c[0],c[1],{overhang:0.12,minFill:0.75});
        out.push({fill:d.w/c[0], crisp:Number.isInteger(d.scale)}); });
      var art=P.draw(ctx,P.blank(64,46),0,0,340,244,1), print=P.draw(ctx,P.blank(64,46),0,0,681,489,1);
      return {tok:out, artW:art.w, artInt:Number.isInteger(art.scale), printW:print.w}; }""")
    ck("a 32-pixel token never drops to a third of its space", all(t["fill"]>=0.75 for t in r["tok"]), r["tok"])
    ck("card art on screen scales by whole numbers and never overhangs", r["artInt"] and r["artW"]<=340, r)
    ck("card art in print fills its box", abs(r["printW"]-681)<2, r)

    pg.evaluate(SEED); pg.reload(); pg.wait_for_timeout(2200)

    # ---- the Forge: art drawn, the box held at its height, abilities read from either name ----
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3500)
    fr=[f for f in pg.frames if f!=pg.main_frame and f.evaluate("()=>!!(window.KETER_BRIDGE&&window.KETER_BRIDGE.renderCard)")][0]
    r=fr.evaluate("""(cards)=>{
      var B=window.KETER_BRIDGE, renderCard=B.renderCard, fromSchema=B.fromSchema;
      var w=cards.filter(function(c){return c.name==='Test Warden';})[0], plain=JSON.parse(JSON.stringify(w));
      delete plain.pixelArt;
      var cv=document.createElement('canvas'), dpi=150;
      cv.width=Math.round(2.5*dpi); cv.height=Math.round(3.5*dpi);
      var ctx=cv.getContext('2d');
      renderCard(ctx, fromSchema(plain), dpi); var free=B.lastLayout().artH;
      renderCard(ctx, fromSchema(w), dpi); var held=B.lastLayout().artH;
      var want=window.KETER_PX.artHeightIn(window.KETER_PX.get('px_t_art'),2.270);
      var px=ctx.getImageData(Math.round(1.25*dpi), Math.round((0.577+held/2)*dpi), 1, 1).data;
      var q=cards.filter(function(c){return c.name==='Quillon Vex';})[0], legacy=JSON.parse(JSON.stringify(q));
      legacy.abilities=legacy.entries; delete legacy.entries;
      return {free:free, held:held, want:want, px:[px[0],px[1],px[2]],
              quillon:fromSchema(q).abilities.length, legacy:fromSchema(legacy).abilities.length}; }""", comp["cards"])
    ck("with pixel art, the art box holds the art's height", abs(r["held"]-r["want"])<0.001, r)
    ck("which differs from where the text alone would put it", abs(r["held"]-r["free"])>0.01, r)
    ck("the art is drawn in the box", r["px"]==[255,122,26], r["px"])
    ck("Quillon Vex reaches the Forge with its abilities", r["quillon"]>=2, r)
    ck("a card saved the old way still keeps its abilities in the Forge", r["legacy"]==r["quillon"], r)

    # ---- the board ----
    pg.evaluate("()=>{ localStorage.setItem('keter-app-simdebug','1'); localStorage.removeItem('keter-app-sim'); }")
    pg.reload(); pg.wait_for_timeout(2200)
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(500)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(600)
    pg.evaluate("()=>simDebugStart('TEST \u00b7 Sight Lines')"); pg.wait_for_timeout(2500)
    r=pg.evaluate("""()=>{ var w=SIM.units.filter(function(u){return u.name==='Test Warden';})[0],
      s=SIM.units.filter(function(u){return u.name==='Test Striker';})[0];
      return {warden:!!simTokenFor(w), striker:!!simTokenFor(s)}; }""")
    ck("a Unit whose card has a token shows it", r["warden"])
    ck("a Unit without one keeps its label", not r["striker"])
    r=pg.evaluate("""()=>{ SIM_UI.handOpen=false; renderSim(); simDraw();
      var w=SIM.units.filter(function(u){return u.name==='Test Warden';})[0], cv=document.getElementById('simcanvas');
      var d=SIM_VIEW.dpr, cx=(SIM_VIEW.ox+SIM_VIEW.size*Math.sqrt(3)*(w.pos.q+w.pos.r/2))*d, cy=(SIM_VIEW.oy+SIM_VIEW.size*1.5*w.pos.r)*d;
      var px=cv.getContext('2d').getImageData(Math.round(cx),Math.round(cy),1,1).data; return [px[0],px[1],px[2]]; }""")
    ck("the token is drawn in the Unit's hexagon", r==[34,240,255], r)

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"PIXEL PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
