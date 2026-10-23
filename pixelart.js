/* ==========================================================================
   KETER pixel art: the palette, how pictures are stored, and how they are
   drawn. Shared by the app and the Forge, so a card's art and a board token
   are drawn by the same code everywhere.

   Palette: AAP-Splendor128 by Adigun A. Polack, plus eleven neons for the
   glow Splendor leaves soft, plus KETER 56 (v12.5), plus up to 60 colours of
   your own. Colour 0 is transparent; 255 is the most one byte can hold.

   A picture: {v, w, h, frames:[{layers:[{name, visible, locked, opacity,
   mode, px}]}], flat}. px and flat are run-length encoded palette indices.
   v14.3: a picture may have several frames, each with its layers, and fps,
   how many of them a second it plays at (the game's effects are drawn so);
   flat is the first frame, as everything that shows one picture shows it.
   ========================================================================== */
(function(){
  var SPLENDOR=("050403 0e0c0c 2d1b1e 612721 b9451d f1641f fca570 ffe0b7 ffffff fff089 f8c53a e88a36 b05b2c 673931 271f1b 4c3d2e 855f39 d39741 f8f644 d5dc1d adb834 7f8e44 586335 333c24 181c19 293f21 477238 61a53f 8fd032 c4f129 d0ffea 97edca 59cf93 42a459 3d6f43 27412d 14121d 1b2447 2b4e95 2789cd 42bfe8 73efe8 f1f2ff c9d4fd 8aa1f6 4572e3 494182 7864c6 9c8bdb ceaaed fad6ff eeb59c d480bb 9052bc 171516 373334 695b59 b28b78 e2b27e f6d896 fcf7be ecebe7 cbc6c1 a69e9a 807b7a 595757 323232 4f342f 8c5b3e c68556 d6a851 b47538 724b2c 452a1b 61683a 939446 c6b858 efdd91 b5e7cb 86c69a 5d9b79 486859 2c3b39 171819 2c3438 465456 64878c 8ac4c3 afe9df dceaee b8ccd8 88a3bc 5e718e 485262 282c3c 464762 696682 9a97b9 c5c7dd e6e7f0 eee6ea e3cddf bfa5c9 87738f 564f5b 322f35 36282b 654956 966888 c090a9 d4b8b8 eae0dd f1ebdb ddcebf bda499 886e6a 594d4d 33272a b29476 e1bf89 f8e398 ffe9e3 fdc9c9 f6a2a8 e27285 b25266 64364b 2a1e23").split(" ");
  var NEON=[["8a3dff","UV violet"],["ff2bd6","neon magenta"],["ff7a1a","neon orange"],["ff2a3c","laser red"],
            ["6dff3a","acid green"],["22f0ff","electric cyan"],["3dffc8","Aether mint"],["2f7bff","electric blue"],
            ["ff3d7f","hot pink"],["c23bff","plasma purple"],["f0ff2a","neon yellow"]];
  /* v12.5: fifty-six more, filling what Splendor leaves thin for KETER —
     grime greys, drab greens, dusk violets, steel, Mars dust, rust and oil,
     skin, bone, blood and toxic — each chosen to sit clear of every colour
     already there. The rest of the 255 are your own colours. */
  var EXT=[["3e4246","grime grey"],["6e6a64","grime grey"],["6a7178","grime grey"],["7e858c","grime grey"],["b3ada2","grime grey"],["122616","drab green"],["3c4a3a","drab green"],["4e5e48","drab green"],["65735a","drab green"],["7f8a6e","drab green"],["6e9f60","drab green"],["9eb280","drab green"],["3a2f3e","dusk violet"],["4e4054","dusk violet"],["654370","dusk violet"],["66566c","dusk violet"],["89609f","dusk violet"],["a180b2","dusk violet"],["406977","steel blue"],["5a6da6","steel blue"],["5a8ca6","steel blue"],["733a28","Mars dust"],["7a4a36","Mars dust"],["8e4a30","Mars dust"],["a65d3c","Mars dust"],["ad7a5e","Mars dust"],["bf7652","Mars dust"],["c98d68","Mars dust"],["caa184","Mars dust"],["d8b89a","Mars dust"],["43360c","rust and oil"],["635017","rust and oil"],["983a1b","rust and oil"],["804d17","rust and oil"],["806517","rust and oil"],["8a5a48","skin"],["9c5e44","skin"],["c8624d","skin"],["dd8877","skin"],["f0cbae","skin"],["bfae8c","bone"],["d4c6a8","bone"],["d0cb95","bone"],["e8dcc4","bone"],["37060b","blood"],["7e0e0e","blood"],["801c35","blood"],["9f2d35","blood"],["b81418","blood"],["b81439","blood"],["40740b","toxic"],["6b6f11","toxic"],["6f8707","toxic"],["6aa208","toxic"],["a2c113","toxic"],["8ce50c","toxic"]];
  var NEON_FROM=1+SPLENDOR.length, EXT_FROM=NEON_FROM+NEON.length, CUSTOM_FROM=EXT_FROM+EXT.length, PAL_MAX=255, ART_W_IN=2.270;
  /* one byte per pixel: 255 colours and transparent. Every slot exists from
     the start, so a colour's number never changes; your own are null until set. */
  var PALETTE=[null].concat(SPLENDOR.map(function(h){ return "#"+h; }), NEON.map(function(n){ return "#"+n[0]; }), EXT.map(function(n){ return "#"+n[0]; }));
  while(PALETTE.length<=PAL_MAX) PALETTE.push(null);
  function hexRgb(h){ return [parseInt(h.substr(1,2),16),parseInt(h.substr(3,2),16),parseInt(h.substr(5,2),16)]; }
  var RGB=PALETTE.map(function(h){ return h?hexRgb(h):null; });
  /* v14.1: and 48, the size the game draws every Unit at */
  var ART_W=64, TOKEN_SIZES=[16,24,32,48];
  /* v12.4: card art is 64 or 128 pixels across; a blank canvas of square
     pixels goes up to 256 each way (hex pixels stay at 128, being far slower
     to draw) */
  var ART_WIDTHS=[128,64], BLANK_MAX=256, BLANK_HEX_MAX=128;

  /* ---- storage: runs of (count, colour), as base64 ---- */
  function encode(arr){
    var bytes=[], i=0, n=arr.length;
    while(i<n){
      var v=arr[i], run=1;
      while(i+run<n && arr[i+run]===v && run<255) run++;
      bytes.push(run, v); i+=run;
    }
    var s="";
    for(var k=0;k<bytes.length;k+=8192) s+=String.fromCharCode.apply(null, bytes.slice(k,k+8192));
    return btoa(s);
  }
  function decode(str, n){
    var out=new Uint8Array(n);
    if(!str) return out;
    var b=atob(str), o=0;
    for(var i=0;i+1<b.length && o<n;i+=2){
      var run=b.charCodeAt(i), v=b.charCodeAt(i+1);
      for(var r=0;r<run && o<n;r++) out[o++]=v;
    }
    return out;
  }
  function blank(w,h,name){
    return {v:1, w:w, h:h, name:name||"", frames:[{layers:[
      {name:"Layer 1", visible:true, locked:false, opacity:100, mode:"view", px:encode(new Uint8Array(w*h))}]}], flat:""};
  }
  /* ---- frames (v14.3) ---- */
  function frameCount(pic){ return Math.max(1,((pic&&pic.frames)||[]).length); }
  /* a frame like another, its layers named and set the same, with nothing on them */
  function emptyFrameLike(pic, i){
    var src=(pic.frames||[])[i||0]||{layers:[]}, n=pic.w*pic.h, none=encode(new Uint8Array(n));
    var layers=(src.layers||[]).map(function(L){ return {name:L.name, visible:L.visible!==false, locked:false, opacity:L.opacity==null?100:L.opacity, mode:L.mode||"view", px:none}; });
    if(!layers.length) layers=[{name:"Layer 1", visible:true, locked:false, opacity:100, mode:"view", px:none}];
    return {layers:layers};
  }
  /* a blank picture of n frames, playing at fps */
  function blankFrames(w,h,n,name,fps){
    var pic=blank(w,h,name);
    for(var i=1;i<Math.max(1,n||1);i++) pic.frames.push(emptyFrameLike(pic,0));
    if(fps) pic.fps=fps;
    return pic;
  }
  /* one frame, drawn as sprite() draws the first */
  function frameSprite(pic, i, view){
    if(!i || frameCount(pic)<2) return sprite(pic, view);
    return sprite({w:pic.w, h:pic.h, custom:pic.custom, flat:encode(flatten(pic,Math.min(i,frameCount(pic)-1)))}, view);
  }
  /* every frame side by side, each pixel k across: a picture's frames as a
     PNG carries them (the game cuts them apart again) */
  function stripCanvas(pic, k){
    k=k||1; var n=frameCount(pic), c=document.createElement("canvas"); c.width=pic.w*n*k; c.height=pic.h*k;
    var g=c.getContext("2d"); g.imageSmoothingEnabled=false;
    for(var i=0;i<n;i++) g.drawImage(frameSprite(pic,i), i*pic.w*k, 0, pic.w*k, pic.h*k);
    return c;
  }

  /* ---- colour ---- */
  var nearCache={};
  function nearest(r,g,b){
    var key=(r<<16)|(g<<8)|b;
    if(nearCache[key]!==undefined) return nearCache[key];
    var best=1, bd=1e9;
    for(var i=1;i<RGB.length;i++){
      var c=RGB[i]; if(!c) continue;
      var dr=c[0]-r, dg=c[1]-g, db=c[2]-b;
      var d=dr*dr*0.3+dg*dg*0.59+db*db*0.11;
      if(d<bd){ bd=d; best=i; }
    }
    return (nearCache[key]=best);
  }

  /* ---- your own colours (v12.5) ----
     Kept on this device, in the slots after KETER 56. Every picture that uses
     one carries a copy of it, so it looks the same on any device, and brings it
     back to the palette when it is opened in the Studio. */
  var COL_KEY="keter-app-colours", GEN=0;
  function paletteChanged(){ nearCache={}; labCache=null; GEN++; }
  function saveCustom(){
    var o={}; for(var i=CUSTOM_FROM;i<=PAL_MAX;i++) if(PALETTE[i]) o[i]=PALETTE[i];
    try{ localStorage.setItem(COL_KEY,JSON.stringify(o)); return true; }catch(e){ return false; }
  }
  function setSlot(i,hex){ PALETTE[i]=hex||null; RGB[i]=hex?hexRgb(hex):null; }
  function loadCustom(){
    var o={}; try{ o=JSON.parse(localStorage.getItem(COL_KEY)||"{}")||{}; }catch(e){}
    for(var i=CUSTOM_FROM;i<=PAL_MAX;i++){ var h=normHex(o[i]); setSlot(i,h); }
    paletteChanged();
  }
  function normHex(h){
    h=String(h==null?"":h).trim().replace(/^#/,"").toLowerCase();
    if(/^[0-9a-f]{3}$/.test(h)) h=h[0]+h[0]+h[1]+h[1]+h[2]+h[2];
    return /^[0-9a-f]{6}$/.test(h)?"#"+h:null;
  }
  function indexOfHex(hex){ for(var i=1;i<=PAL_MAX;i++) if(PALETTE[i]===hex) return i; return -1; }
  function freeSlot(){ for(var i=CUSTOM_FROM;i<=PAL_MAX;i++) if(!PALETTE[i]) return i; return -1; }
  /* a colour already in the palette is that colour; otherwise the next free
     slot. -1 when all are taken or the colour cannot be read. */
  function addColour(hex){
    hex=normHex(hex); if(!hex) return -1;
    var at=indexOfHex(hex); if(at>0) return at;
    var i=freeSlot(); if(i<0) return -1;
    setSlot(i,hex); paletteChanged(); saveCustom(); return i;
  }
  function removeColour(i){ if(i<CUSTOM_FROM||i>PAL_MAX) return false; setSlot(i,null); paletteChanged(); saveCustom(); return true; }
  function customColours(){ var o=[]; for(var i=CUSTOM_FROM;i<=PAL_MAX;i++) if(PALETTE[i]) o.push(i); return o; }
  function customRoom(){ return PAL_MAX-CUSTOM_FROM+1; }
  /* which set a colour belongs to */
  function setOf(i){ return i<1?"":i<NEON_FROM?"splendor":i<EXT_FROM?"neon":i<CUSTOM_FROM?"keter":"mine"; }
  function nameOf(i){
    if(i>=NEON_FROM && i<EXT_FROM) return NEON[i-NEON_FROM][1];
    if(i>=EXT_FROM && i<CUSTOM_FROM) return EXT[i-EXT_FROM][1];
    return "";
  }
  /* each layer's pixels, as numbers */
  function eachLayer(pic, fn){ var n=pic.w*pic.h; (pic.frames||[]).forEach(function(fr){ (fr.layers||[]).forEach(function(L){ fn(L,n); }); }); }
  /* the picture keeps a copy of every one of your colours it uses */
  function embed(pic){
    var used={};
    eachLayer(pic,function(L,n){ var px=decode(L.px,n); for(var i=0;i<n;i++) if(px[i]>=CUSTOM_FROM) used[px[i]]=1; });
    var keep={}, any=false, had=pic.custom||{};
    /* the picture's own copy wins: a picture from another device keeps its
       colour even before the Studio has brought it into this palette */
    Object.keys(used).forEach(function(k){ var h=normHex(had[k])||PALETTE[k]; if(h){ keep[k]=h; any=true; } });
    if(any) pic.custom=keep; else delete pic.custom;
    return pic;
  }
  /* Opening a picture from elsewhere: its colours come back to the palette.
     One whose slot here holds a different colour moves to a free slot (or to
     the same colour, if you have it), and its pixels move with it. */
  function adopt(pic){
    var C=pic&&pic.custom; if(!C) return {moved:0, lost:0};
    var map={}, moved=0, lost=0, changed=false;
    Object.keys(C).forEach(function(k){
      var i=+k, hex=normHex(C[k]); if(!hex || i<CUSTOM_FROM || i>PAL_MAX) return;
      if(PALETTE[i]===hex) return;
      if(!PALETTE[i]){ setSlot(i,hex); changed=true; return; }
      var j=indexOfHex(hex);
      if(j<0){ j=freeSlot(); if(j>=0){ setSlot(j,hex); changed=true; } }
      if(j<0){ var c=hexRgb(hex); j=nearestBuiltin(c[0],c[1],c[2]); lost++; } else moved++;
      map[i]=j;
    });
    if(changed){ paletteChanged(); saveCustom(); }
    if(Object.keys(map).length){
      eachLayer(pic,function(L,n){ var px=decode(L.px,n), any=false;
        for(var q=0;q<n;q++){ var m=map[px[q]]; if(m!==undefined){ px[q]=m; any=true; } }
        if(any) L.px=encode(px); });
      pic.flat="";
    }
    embed(pic);
    return {moved:moved, lost:lost};
  }
  function nearestBuiltin(r,g,b){
    var best=1, bd=1e9;
    for(var i=1;i<CUSTOM_FROM;i++){ var c=RGB[i], dr=c[0]-r, dg=c[1]-g, db=c[2]-b, d=dr*dr*0.3+dg*dg*0.59+db*db*0.11; if(d<bd){ bd=d; best=i; } }
    return best;
  }
  /* the colours to draw a picture with: the palette, with the picture's own
     copies of your colours wherever it has them */
  function tableFor(pic){
    var C=pic&&pic.custom; if(!C) return RGB;
    var t=RGB.slice(); Object.keys(C).forEach(function(k){ var h=normHex(C[k]); if(h) t[+k]=hexRgb(h); });
    return t;
  }
  function cssFor(pic){
    var C=pic&&pic.custom; if(!C) return PALETTE;
    var t=PALETTE.slice(); Object.keys(C).forEach(function(k){ var h=normHex(C[k]); if(h) t[+k]=h; });
    return t;
  }
  function tableKey(pic){ return GEN+(pic&&pic.custom?JSON.stringify(pic.custom):""); }

  /* ---- colour families, for sorting and filtering the palette (v12.5) ---- */
  var FAMILIES=["Reds","Oranges","Earth","Yellows","Greens","Teals","Blues","Purples","Pinks","Greys"];
  function lch(i){
    if(!labCache) labCache=RGB.map(function(c){ return c?lab(c):null; });
    var L=labCache[i]; if(!L) return null;
    var C=Math.sqrt(L[1]*L[1]+L[2]*L[2]), H=(Math.atan2(L[2],L[1])*180/Math.PI+360)%360;
    return {L:L[0], C:C, H:H};
  }
  function family(i){
    var c=lch(i); if(!c) return "";
    if(c.C<8 || (c.L<12 && c.C<14)) return "Greys";
    if((c.H>=345 || c.H<42) && c.L<25 && c.C>=14) return "Reds";
    if(c.H>=20 && c.H<95 && c.C<42 && c.L<82 && !(c.H>=70 && c.C>30)) return "Earth";
    if(c.H>=345 || c.H<42) return c.L>75 ? "Pinks" : "Reds";
    if(c.H<72) return "Oranges";
    if(c.H<110) return "Yellows";
    if(c.H<175) return "Greens";
    if(c.H<235) return "Teals";
    if(c.H<295) return "Blues";
    if(c.H<325) return "Purples";
    return "Pinks";
  }
  /* palette order, by hue (greys last, dark to light), or by lightness */
  function sortColours(list, how){
    var a=list.slice();
    if(how==="hue") a.sort(function(x,y){ var p=lch(x), q=lch(y), gp=p.C<8, gq=q.C<8;
      if(gp!==gq) return gp?1:-1; if(gp) return p.L-q.L;
      var hp=Math.floor(((p.H+15)%360)/20), hq=Math.floor(((q.H+15)%360)/20);
      return hp!==hq ? hp-hq : p.L-q.L; });
    else if(how==="light") a.sort(function(x,y){ return lch(y).L-lch(x).L; });
    return a;
  }
  function lightness(i){ var c=lch(i); return c?c.L:0; }

  /* ---- flattening: each layer's opacity works by its own mode ----
     view   : opacity is only for seeing while you work; the layer saves whole
     snap   : really blended, each result snapped to the nearest palette colour
     dither : translucency as a checkerboard of the layer's own pixels        */
  function flatten(pic, frameIdx){
    var w=pic.w, h=pic.h, n=w*h, out=new Uint8Array(n);
    var fr=(pic.frames||[])[frameIdx||0]; if(!fr) return out;
    var T=tableFor(pic);
    fr.layers.forEach(function(L){
      if(!L.visible) return;
      var px=decode(L.px,n), op=Math.max(0,Math.min(100,+L.opacity||0))/100, mode=L.mode||"view";
      for(var i=0;i<n;i++){
        var v=px[i]; if(!v) continue;
        if(mode==="view" || op>=0.999){ out[i]=v; continue; }
        if(mode==="dither"){
          var x=i%w, y=(i/w)|0, show;
          if(op>=0.75) show=true;
          else if(op<0.25) show=false;
          else if(isHex(pic)){
            /* a hex grid has no checkerboard: one or two hexes in every three */
            var a=axialOf(x,y,pic.orient||"pointy"), cls=(((a.q-a.r)%3)+3)%3;
            show = op>=0.5 ? cls!==0 : cls===0;
          } else show=((x+y)&1)===0;
          if(show) out[i]=v;
          continue;
        }
        /* snap: over nothing, it either shows or it does not */
        var under=out[i];
        if(!under){ if(op>=0.5) out[i]=v; continue; }
        var a=T[v], b=T[under]; if(!a||!b){ out[i]=v; continue; }
        out[i]=nearest(Math.round(a[0]*op+b[0]*(1-op)), Math.round(a[1]*op+b[1]*(1-op)), Math.round(a[2]*op+b[2]*(1-op)));
      }
    });
    return out;
  }
  function refreshFlat(pic){ pic.flat=encode(flatten(pic,0)); return pic.flat; }

  /* ---- hex pixels ----
     A hex picture is still a w x h array of palette colours, laid out in offset
     rows (pointy-top) or offset columns (flat-top). A hexagon-shaped canvas
     marks the cells outside the hexagon as void. Positions are worked out here
     once, with a hex of circumradius 1, so the studio, cards, the board and PDFs
     all agree on where every hex sits. */
  var SQ3=Math.sqrt(3), hexCache={};
  function isHex(pic){ return !!pic && pic.grid==="hex"; }
  function axialOf(col,row,orient){
    return orient==="flat" ? {q:col, r:row-((col-(col&1))/2)} : {q:col-((row-(row&1))/2), r:row};
  }
  function offsetOf(q,r,orient){
    return orient==="flat" ? {col:q, row:r+((q-(q&1))/2)} : {col:q+((r-(r&1))/2), row:r};
  }
  function hexLayout(pic){
    var key=pic.w+"x"+pic.h+":"+(pic.orient||"pointy")+":"+(pic.shape||"rect")+":"+(pic.side||0);
    if(hexCache[key]) return hexCache[key];
    var w=pic.w, h=pic.h, n=w*h, orient=pic.orient||"pointy";
    var cx=new Float32Array(n), cy=new Float32Array(n), valid=new Uint8Array(n);
    var centre=null;
    if(pic.shape==="hexagon"){ var R=(pic.side||6)-1; centre=axialOf(R,R,orient); centre.R=R; }
    var minx=1e9,miny=1e9,maxx=-1e9,maxy=-1e9;
    var ex=orient==="flat"?1:SQ3/2, ey=orient==="flat"?SQ3/2:1;
    for(var row=0;row<h;row++) for(var col=0;col<w;col++){
      var i=row*w+col, a=axialOf(col,row,orient);
      var x=orient==="flat"?1.5*a.q:SQ3*(a.q+a.r/2), y=orient==="flat"?SQ3*(a.r+a.q/2):1.5*a.r;
      cx[i]=x; cy[i]=y;
      var ok=true;
      if(centre){ var dq=a.q-centre.q, dr=a.r-centre.r; ok=(Math.abs(dq)+Math.abs(dr)+Math.abs(dq+dr))/2<=centre.R; }
      valid[i]=ok?1:0;
      if(ok){ minx=Math.min(minx,x-ex); maxx=Math.max(maxx,x+ex); miny=Math.min(miny,y-ey); maxy=Math.max(maxy,y+ey); }
    }
    return (hexCache[key]={cx:cx, cy:cy, valid:valid, orient:orient, centre:centre,
      bounds:{minx:minx, miny:miny, maxx:maxx, maxy:maxy, w:maxx-minx, h:maxy-miny}});
  }
  /* the cell under a point, in the layout's own units; -1 if none */
  function hexCellAt(pic, x, y){
    var L=hexLayout(pic), o=L.orient, q, r;
    if(o==="flat"){ q=2/3*x; r=-1/3*x+SQ3/3*y; } else { q=SQ3/3*x-1/3*y; r=2/3*y; }
    var s=-q-r, rq=Math.round(q), rr=Math.round(r), rs=Math.round(s);
    var dq=Math.abs(rq-q), dr=Math.abs(rr-r), ds=Math.abs(rs-s);
    if(dq>dr&&dq>ds) rq=-rr-rs; else if(dr>ds) rr=-rq-rs;
    var off=offsetOf(rq,rr,o);
    if(off.col<0||off.row<0||off.col>=pic.w||off.row>=pic.h) return -1;
    var i=off.row*pic.w+off.col;
    return L.valid[i]?i:-1;
  }
  function hexPath(ctx, x, y, rad, orient){
    ctx.beginPath();
    for(var k=0;k<6;k++){
      var a=Math.PI/180*(60*k-(orient==="flat"?0:30));
      var px=x+rad*Math.cos(a), py=y+rad*Math.sin(a);
      if(k) ctx.lineTo(px,py); else ctx.moveTo(px,py);
    }
    ctx.closePath();
  }
  /* draw a hex picture scaled to fit a box (or, with opts.fillWidth, to fill
     its width \u2014 card art, clipped by the art box). Hexes overlap by a hair so
     no seams show between them. */
  function drawHexPic(ctx, pic, x, y, w, h, opts){
    opts=opts||{};
    var L=hexLayout(pic), B=L.bounds, flat=decode(pic.flat||refreshFlat(pic), pic.w*pic.h);
    var s=opts.fillWidth ? w/B.w : Math.min(w/B.w, h/B.h);
    var ox=x+(w-B.w*s)/2-B.minx*s, oy=y+(h-B.h*s)/2-B.miny*s, css=cssFor(pic);
    for(var i=0;i<flat.length;i++){
      if(!flat[i] || !L.valid[i] || !css[flat[i]]) continue;
      ctx.fillStyle=css[flat[i]];
      hexPath(ctx, ox+L.cx[i]*s, oy+L.cy[i]*s, s*1.03, L.orient); ctx.fill();
    }
    return {x:ox+B.minx*s, y:oy+B.miny*s, w:B.w*s, h:B.h*s, scale:s};
  }
  /* sizes offered when starting a hex picture */
  var HEX_SIDES=[6,9,12], HEX_ACROSS=[32,40,48];
  function blankHexagon(side, orient, name){
    var n=2*side;
    var pic=blank(n, n-1, name); pic.grid="hex"; pic.shape="hexagon"; pic.side=side; pic.orient=orient||"pointy";
    return pic;
  }
  function blankHexArt(across, artHin, orient, name){
    var o=orient||"pointy", ratio=(artHin||1.62)/ART_W_IN;
    var cols, rows;
    if(o==="flat"){ cols=across; var s=1/(1.5*cols+0.5); rows=Math.max(2,Math.round(ratio/(SQ3*s))); }
    else { cols=across; var s2=1/(SQ3*(cols+0.5)); rows=Math.max(2,Math.round((ratio-0.5*s2*2)/(1.5*s2))+1); }
    var pic=blank(cols, rows, name); pic.grid="hex"; pic.shape="rect"; pic.orient=o;
    /* never taller than the art box: that would push the box taller once the
       art holds it */
    while(pic.h>2){
      var B=hexLayout(pic).bounds;
      if(B.h/B.w<=ratio+1e-6) break;
      pic=blank(cols, pic.h-1, name); pic.grid="hex"; pic.shape="rect"; pic.orient=o;
    }
    return pic;
  }

  /* ---- drawing ---- */
  var canvasCache={}, canvasOrder=[];
  /* view (v12.5): an optional {id, rgb} table that replaces the colours —
     the Studio's value and silhouette views */
  function sprite(pic, view){
    var flat=pic.flat||refreshFlat(pic), key=pic.w+"x"+pic.h+":"+tableKey(pic)+(view?":"+view.id:"")+":"+flat;
    if(canvasCache[key]) return canvasCache[key];
    var c=document.createElement("canvas"); c.width=pic.w; c.height=pic.h;
    var g=c.getContext("2d"), img=g.createImageData(pic.w,pic.h), px=decode(flat,pic.w*pic.h), T=view?view.rgb:tableFor(pic);
    for(var i=0;i<px.length;i++){
      var rgb=T[px[i]]; if(!rgb) continue;
      img.data[i*4]=rgb[0]; img.data[i*4+1]=rgb[1]; img.data[i*4+2]=rgb[2]; img.data[i*4+3]=255;
    }
    g.putImageData(img,0,0);
    /* kept to the most recent few: every stroke makes a new picture, and an
       unbounded cache grew for as long as you drew */
    canvasOrder.push(key);
    if(canvasOrder.length>48) delete canvasCache[canvasOrder.shift()];
    return (canvasCache[key]=c);
  }
  /* Draw into a box. Pixels stay square and crisp: on screen they are scaled by
     whole numbers and centred; once each is six or more dots wide (as in
     print) the picture fills the box exactly, since a one-dot difference
     between columns is then invisible. deviceScale is how many device pixels
     one unit of the context is, so whole-number scaling is judged in real
     pixels. Returns where it drew. */
  /* opts.overhang lets a whole-number size run slightly past the box (a token's
     transparent margin absorbs it); opts.minFill is the smallest share of the
     box a whole-number size may leave filled before an in-between size is
     used instead \u2014 a little soft, rather than a third of the size. */
  /* v12.4: below one dot per pixel — a 128-pixel picture on a card in the
     hand — pixel art cannot stay crisp, and scaling it the crisp way drops
     whole rows and columns of it. There it is averaged down instead, so the
     detail blends rather than vanishes. */
  function draw(ctx, pic, x, y, w, h, deviceScale, opts){
    if(!pic || !pic.w) return null;
    opts=opts||{};
    if(isHex(pic)) return drawHexPic(ctx, pic, x, y, w, h, opts);
    var ds=deviceScale||1, exact=Math.min(w/pic.w, h/pic.h)*ds, s=exact;
    if(exact<1){
      var tw=Math.max(1,Math.round(pic.w*exact)), th=Math.max(1,Math.round(pic.h*exact));
      var dw0=tw/ds, dh0=th/ds, dx0=x+(w-dw0)/2, dy0=y+(h-dh0)/2;
      var was0=ctx.imageSmoothingEnabled;
      ctx.imageSmoothingEnabled=false;
      ctx.drawImage(shrunk(pic, tw, th), dx0, dy0, dw0, dh0);
      ctx.imageSmoothingEnabled=was0;
      return {x:dx0, y:dy0, w:dw0, h:dh0, scale:exact, smooth:true};
    }
    /* opts.exactFrom: from this many dots per pixel the box is filled exactly
       (a card's art box uses 4: a one-dot difference between 4- and 5-dot
       columns cannot be seen, and a whole number there left a margin) */
    if(s<(opts.exactFrom||6)){
      s=Math.max(1,Math.floor(exact*(1+(opts.overhang||0))));
      if(opts.minFill && s/exact<opts.minFill) s=exact;
    }
    var dw=pic.w*s/ds, dh=pic.h*s/ds;
    var dx=x+(w-dw)/2, dy=y+(h-dh)/2;
    var was=ctx.imageSmoothingEnabled;
    ctx.imageSmoothingEnabled=false;
    ctx.drawImage(sprite(pic), dx, dy, dw, dh);
    ctx.imageSmoothingEnabled=was;
    return {x:dx, y:dy, w:dw, h:dh, scale:s};
  }
  /* averaged down to tw x th: every target dot is the mean of the pixels that
     fall in it, transparency included */
  var shrinkCache={}, shrinkOrder=[];
  function shrunk(pic, tw, th){
    var flat=pic.flat||refreshFlat(pic), key=tw+"x"+th+":"+pic.w+"x"+pic.h+":"+tableKey(pic)+":"+flat;
    if(shrinkCache[key]) return shrinkCache[key];
    var n=tw*th, acc=new Float32Array(n*4), cnt=new Float32Array(n), px=decode(flat,pic.w*pic.h), T=tableFor(pic);
    for(var y=0;y<pic.h;y++){
      var ty=Math.min(th-1,Math.floor(y*th/pic.h));
      for(var x=0;x<pic.w;x++){
        var tx=Math.min(tw-1,Math.floor(x*tw/pic.w)), t=ty*tw+tx, v=px[y*pic.w+x];
        cnt[t]++;
        var rgb=T[v]; if(!rgb) continue;
        acc[t*4]+=rgb[0]; acc[t*4+1]+=rgb[1]; acc[t*4+2]+=rgb[2]; acc[t*4+3]+=1;
      }
    }
    var c=document.createElement("canvas"); c.width=tw; c.height=th;
    var g=c.getContext("2d"), img=g.createImageData(tw,th);
    for(var i=0;i<n;i++){
      var a=acc[i*4+3]; if(!a) continue;
      img.data[i*4]=Math.round(acc[i*4]/a); img.data[i*4+1]=Math.round(acc[i*4+1]/a);
      img.data[i*4+2]=Math.round(acc[i*4+2]/a); img.data[i*4+3]=Math.round(255*a/(cnt[i]||1));
    }
    g.putImageData(img,0,0);
    shrinkOrder.push(key);
    if(shrinkOrder.length>48) delete shrinkCache[shrinkOrder.shift()];
    return (shrinkCache[key]=c);
  }
  /* v12.4: every pixel becomes a 2 x 2 block, in every layer — the picture
     looks the same, with room for finer detail. Square pixels only. */
  function doubled(pic){
    if(isHex(pic)) return null;
    var w=pic.w, h=pic.h, W=w*2, H=h*2, c=JSON.parse(JSON.stringify(pic));
    c.w=W; c.h=H; c.flat="";
    (c.frames||[]).forEach(function(fr){ fr.layers.forEach(function(L){
      var src=decode(L.px,w*h), out=new Uint8Array(W*H);
      for(var y=0;y<H;y++) for(var x=0;x<W;x++) out[y*W+x]=src[(y>>1)*w+(x>>1)];
      L.px=encode(out);
    }); });
    if(c.ref){ c.ref.x*=2; c.ref.y*=2; c.ref.s*=2; }
    return c;
  }

  /* ---- colour ramps (v12.4) ----
     For a colour, the nearest darker and lighter palette colours of a similar
     hue, stepping down and up in value: what a shading ramp is built from. */
  function lab(rgb){
    var f=function(c){ c/=255; return c<=0.04045?c/12.92:Math.pow((c+0.055)/1.055,2.4); };
    var r=f(rgb[0]), g=f(rgb[1]), b=f(rgb[2]);
    var X=(r*0.4124+g*0.3576+b*0.1805)/0.95047, Y=r*0.2126+g*0.7152+b*0.0722, Z=(r*0.0193+g*0.1192+b*0.9505)/1.08883;
    var p=function(t){ return t>0.008856?Math.cbrt(t):7.787*t+16/116; };
    var fx=p(X), fy=p(Y), fz=p(Z);
    return [116*fy-16, 500*(fx-fy), 200*(fy-fz)];
  }
  var labCache=null;
  function ramp(i, steps){
    steps=steps||3;
    if(!labCache) labCache=RGB.map(function(c){ return c?lab(c):null; });
    var out={darker:[], lighter:[]};
    if(!labCache[i]) return out;
    ["darker","lighter"].forEach(function(dir){
      var cur=labCache[i], used={}; used[i]=1;
      for(var s=0;s<steps;s++){
        var best=-1, bc=1e9;
        for(var j=1;j<labCache.length;j++){
          var L=labCache[j]; if(!L || used[j]) continue;
          var dL=dir==="darker" ? cur[0]-L[0] : L[0]-cur[0];
          if(dL<4) continue;
          var cost=Math.sqrt((L[1]-cur[1])*(L[1]-cur[1])+(L[2]-cur[2])*(L[2]-cur[2]))+0.45*Math.abs(dL-12);
          if(cost<bc){ bc=cost; best=j; }
        }
        if(best<0) break;
        used[best]=1; out[dir].push(best); cur=labCache[best];
      }
    });
    return out;
  }
  /* ---- turning an image into palette pixels (v12.5) ----
     rgba: the image already resized to w x h (four numbers a pixel). Returns
     one palette colour a pixel, 0 where it is transparent.
       allowed   the palette colours it may use (default: all of them)
       limit     at most this many of them (0: no limit) — the image is
                 snapped to the palette, then the colours whose loss costs
                 least are merged away until few enough remain
       dither    "none", "soft" or "full" (error diffusion), or "pattern" (ordered)
       bg        clear the background: the colour around the edge, flooded inward
       bri, con, sat   brightness, contrast, saturation, -50 to 50
       neighbours, valid   for hex pixels; squares by default                    */
  var BAYER4=[0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5];
  function convert(rgba, w, h, o){
    o=o||{};
    var n=w*h, R=new Float32Array(n), G=new Float32Array(n), B=new Float32Array(n), on=new Uint8Array(n), out=new Uint8Array(n);
    var valid=o.valid||function(){ return true; };
    var nb=o.neighbours||function(i){ var x=i%w, y=(i/w)|0, r=[]; if(x>0) r.push(i-1); if(x<w-1) r.push(i+1); if(y>0) r.push(i-w); if(y<h-1) r.push(i+w); return r; };
    var bri=(+o.bri||0)*1.28, con=1+(+o.con||0)/60, sat=1+(+o.sat||0)/50;
    var cl=function(v){ return v<0?0:v>255?255:v; };
    for(var i=0;i<n;i++){
      if(rgba[i*4+3]<128 || !valid(i)) continue;
      var r=rgba[i*4]+bri, g=rgba[i*4+1]+bri, b=rgba[i*4+2]+bri;
      r=(r-128)*con+128; g=(g-128)*con+128; b=(b-128)*con+128;
      var l=0.299*r+0.587*g+0.114*b;
      R[i]=cl(l+(r-l)*sat); G[i]=cl(l+(g-l)*sat); B[i]=cl(l+(b-l)*sat); on[i]=1;
    }
    /* the background: the commonest colour along the edge, and everything
       joined to it that is close to it */
    if(o.bg){
      var edge=[], counts={}, best=null, bc=0;
      for(var e=0;e<n;e++){ var ex=e%w, ey=(e/w)|0; if(!on[e]) continue;
        var atEdge=ex===0||ey===0||ex===w-1||ey===h-1||nb(e).length<(o.valid?6:4)||nb(e).some(function(k){ return !on[k] && !valid(k); });
        if(!atEdge) continue; edge.push(e);
        var key=((R[e]>>4)<<8)|((G[e]>>4)<<4)|(B[e]>>4); counts[key]=(counts[key]||0)+1; if(counts[key]>bc){ bc=counts[key]; best=key; } }
      if(best!==null){
        var sr=0,sg=0,sb=0,sn=0;
        edge.forEach(function(k){ if((((R[k]>>4)<<8)|((G[k]>>4)<<4)|(B[k]>>4))===best){ sr+=R[k]; sg+=G[k]; sb+=B[k]; sn++; } });
        sr/=sn; sg/=sn; sb/=sn;
        var tol=o.tol||44, t2=tol*tol, near=function(k){ var dr=R[k]-sr, dg=G[k]-sg, db=B[k]-sb; return dr*dr+dg*dg+db*db<=t2; };
        var stack=edge.filter(near), seen=new Uint8Array(n);
        while(stack.length){ var q=stack.pop(); if(seen[q]) continue; seen[q]=1; if(!on[q] || !near(q)) continue; on[q]=0;
          nb(q).forEach(function(k){ if(!seen[k]) stack.push(k); }); }
      }
    }
    /* which colours */
    var allowed=(o.allowed||(function(){ var a=[]; for(var k=1;k<=PAL_MAX;k++) if(RGB[k]) a.push(k); return a; })()).filter(function(k){ return !!RGB[k]; });
    if(!allowed.length) return out;
    var labOf=function(r,g,b){ return lab([r,g,b]); };
    var nearestIn=function(list, L){ var bi=list[0], bd=1e9; for(var j=0;j<list.length;j++){ var c=LB[list[j]]||(LB[list[j]]=lab(RGB[list[j]])); var d0=c[0]-L[0], d1=c[1]-L[1], d2=c[2]-L[2], d=d0*d0+d1*d1+d2*d2; if(d<bd){ bd=d; bi=list[j]; } } return bi; };
    var LB={}, use=allowed, limit=+o.limit||0;
    var direct=null;
    if(limit && limit<allowed.length){
      /* if the image, snapped straight to the palette, already fits the
         limit, those are the colours */
      var seenC={}, cnt=0, dc=new Int16Array(262144).fill(-1);
      for(var d0=0;d0<n;d0++){ if(!on[d0]) continue;
        var kk=((R[d0]>>2)<<12)|((G[d0]>>2)<<6)|(B[d0]>>2), vv=dc[kk]; if(vv<0) vv=dc[kk]=nearestIn(allowed, labOf(R[d0],G[d0],B[d0]));
        if(!seenC[vv]){ seenC[vv]=0; cnt++; } seenC[vv]++; }
      if(cnt<=limit) direct=Object.keys(seenC).map(Number);
    }
    if(direct) use=direct;
    else if(limit && limit<allowed.length){
      /* Too many: take colours away one at a time, always the one that costs
         least — few pixels, and a near neighbour to hand them to. A small
         accent far from everything else (an eye, a light) survives; a shade
         between two others goes first. Its pixels join the neighbour. */
      var cols=Object.keys(seenC).map(Number), cw={}, LBc={};
      cols.forEach(function(c){ cw[c]=seenC[c]; LBc[c]=LB[c]||(LB[c]=lab(RGB[c])); });
      var dist=function(x,y){ var p=LBc[x], q=LBc[y], d0=p[0]-q[0], d1=p[1]-q[1], d2=p[2]-q[2]; return Math.sqrt(d0*d0+d1*d1+d2*d2); };
      var nn={}, nd={};
      var refresh=function(c){ var bj=-1, bd=1e9; for(var j=0;j<cols.length;j++){ var o2=cols[j]; if(o2===c) continue; var d=dist(c,o2); if(d<bd){ bd=d; bj=o2; } } nn[c]=bj; nd[c]=bd; };
      cols.forEach(refresh);
      while(cols.length>limit){
        var worst=-1, wc=1e18;
        /* the error it adds, squared, as the whole picture's error is counted */
        for(var m=0;m<cols.length;m++){ var c=cols[m], cost=cw[c]*nd[c]*nd[c]; if(cost<wc){ wc=cost; worst=m; } }
        var gone=cols[worst], to=nn[gone];
        cols.splice(worst,1); cw[to]+=cw[gone];
        cols.forEach(function(c){ if(nn[c]===gone) refresh(c); });
      }
      use=cols;
    }
    /* each pixel to its nearest chosen colour, remembered by colour */
    var cache=new Int16Array(262144).fill(-1);
    var nearest=function(r,g,b){ r=cl(r); g=cl(g); b=cl(b); var key=((r>>2)<<12)|((g>>2)<<6)|(b>>2); var v=cache[key]; if(v>=0) return v; return (cache[key]=nearestIn(use, labOf(r,g,b))); };
    var mode=o.dither||"none", strength=mode==="full"?1:mode==="soft"?0.5:0;
    if(strength){
      for(var y=0;y<h;y++){
        var ltr=(y&1)===0;
        for(var xi=0;xi<w;xi++){
          var x=ltr?xi:w-1-xi, k=y*w+x; if(!on[k]) continue;
          var c=nearest(R[k],G[k],B[k]); out[k]=c;
          var er=(R[k]-RGB[c][0])*strength, eg=(G[k]-RGB[c][1])*strength, eb=(B[k]-RGB[c][2])*strength, dx=ltr?1:-1;
          var spread=function(xx,yy,f){ if(xx<0||xx>=w||yy>=h) return; var j=yy*w+xx; if(!on[j]) return; R[j]+=er*f; G[j]+=eg*f; B[j]+=eb*f; };
          spread(x+dx,y,7/16); spread(x-dx,y+1,3/16); spread(x,y+1,5/16); spread(x+dx,y+1,1/16);
        }
      }
    } else {
      for(var k2=0;k2<n;k2++){
        if(!on[k2]) continue;
        var t=0;
        if(mode==="pattern"){ var bx2=k2%w, by2=(k2/w)|0; t=((BAYER4[(by2&3)*4+(bx2&3)]+0.5)/16-0.5)*(o.spread||36); }
        out[k2]=nearest(R[k2]+t,G[k2]+t,B[k2]+t);
      }
    }
    return out;
  }

  /* how much of this device's storage the picture library is using */
  /* a picture's fingerprint: its size and every layer. A shipped picture keeps
     the fingerprint it came with, so a release can tell one you never edited. */
  function mark(p){
    /* (v14.3: and how fast its frames play, for one that has a speed; a picture
       without one keeps the fingerprint it always had) */
    var t=JSON.stringify([p.w,p.h,p.frames])+(p.fps?"|"+p.fps:""), h=5381;
    for(var i=0;i<t.length;i++) h=((h*33)^t.charCodeAt(i))>>>0;
    return h.toString(36);
  }
  /* browsers allow each site about five million characters; counted the same way */
  function libBytes(){ try{ return (localStorage.getItem("keter-app-pixels")||"").length; }catch(e){ return 0; } }
  function storeBytes(){
    var t=0; try{ for(var i=0;i<localStorage.length;i++){ var k=localStorage.key(i); t+=k.length+(localStorage.getItem(k)||"").length; } }catch(e){}
    return t;
  }

  /* ---- the library: pictures by id; cards point at them ---- */
  var LIB_KEY="keter-app-pixels";
  /* v13.0: parsed once per change, not on every look-up (the World Map asks
     for its art hundreds of times a frame); what leaves here is a copy */
  var LIBMEMO={raw:null, val:null};
  function lib(){ try{ var raw=localStorage.getItem(LIB_KEY)||"{}"; if(LIBMEMO.raw!==raw) LIBMEMO={raw:raw, val:JSON.parse(raw)||{}}; return LIBMEMO.val; }catch(e){ return {}; } }
  function saveLib(L){ try{ var raw=JSON.stringify(L); localStorage.setItem(LIB_KEY,raw); LIBMEMO={raw:raw, val:L}; return true; }catch(e){ LIBMEMO={raw:null, val:null}; return false; } }
  function dup(p){ return p?JSON.parse(JSON.stringify(p)):p; }
  function newId(){ return "px_"+Date.now().toString(36)+Math.random().toString(36).slice(2,7); }
  function get(id){ if(!id) return null; return dup(lib()[id]||null); }
  function has(id){ return !!(id && lib()[id]); }
  function put(pic, id){
    var L=lib(); id=id||newId(); refreshFlat(pic); embed(pic); pic.id=id; pic.saved=new Date().toISOString();
    var was=L[id]; L[id]=dup(pic); if(saveLib(L)) return id;
    if(was) L[id]=was; else delete L[id]; return null;
  }
  /* reuse copies by default, so editing one card's picture never changes another's */
  function copy(id){ var p=get(id); if(!p) return null; var c=JSON.parse(JSON.stringify(p)); delete c.id; return put(c); }
  function remove(id){ var L=lib(), was=L[id]; delete L[id]; if(!saveLib(L) && was) L[id]=was; }
  /* v14.1: several pictures in one write, as [[id, picture], ...] (the game's
     own art goes in at start-up: one write, not a hundred). All or none:
     the number put, or 0 when there is no room. */
  function putMany(list){
    var L=lib(), now=new Date().toISOString(), was={};
    list.forEach(function(x){ var pic=x[1], id=x[0]; refreshFlat(pic); embed(pic); pic.id=id; pic.saved=now; was[id]=L[id]; L[id]=dup(pic); });
    if(saveLib(L)) return list.length;
    Object.keys(was).forEach(function(id){ if(was[id]) L[id]=was[id]; else delete L[id]; }); return 0;
  }
  function list(){ var L=lib(); return Object.keys(L).map(function(k){ return dup(L[k]); }); }

  /* the art canvas for a card is the width of the art box at 64 pixels, and
     as many pixels tall as the box is when the art is begun */
  /* v12.4: 64 or 128 across; begun as a square, the bottom trimmed off to
     the art box's own shape */
  function artSizeFor(artHin, artWin, width){
    var W=(width===128||width===64)?width:ART_W;
    /* rounded down: rounded to nearest, the canvas could come out a hair taller
       than the box it was measured from, and once the art held the box at that
       height, text that only just fitted overflowed */
    return {w:W, h:Math.max(1, Math.min(W, Math.floor(artHin/(artWin||2.270)*W+1e-9)))};
  }
  function artHeightIn(pic, artWin){
    if(isHex(pic)){ var B=hexLayout(pic).bounds; return B.h/B.w*(artWin||2.270); }
    return pic.h*(artWin||2.270)/pic.w;
  }

  /* ---- which picture belongs to which card ----
     Kept apart from the card data, by the card's number and its name, so any
     card \u2014 master cards included \u2014 can have art without its data being
     edited, and no card edit can lose a picture. */
  var LINK_KEY="keter-app-pixellinks";
  function links(){ try{ return JSON.parse(localStorage.getItem(LINK_KEY)||"{}")||{}; }catch(e){ return {}; } }
  function keysOf(card){
    if(!card) return [];
    return [card.id, card.num, card.cardNumber, card.name].filter(function(k,i,a){ return k && a.indexOf(k)===i; }).map(String);
  }
  function link(card, kind, id){
    var L=links();
    keysOf(card).forEach(function(k){ L[k]=L[k]||{}; if(id) L[k][kind]=id; else delete L[k][kind]; });
    try{ localStorage.setItem(LINK_KEY,JSON.stringify(L)); return true; }catch(e){ return false; }
  }
  /* a picture set on the card itself wins; otherwise the link */
  function pictureFor(card, kind){
    if(!card) return null;
    var own=kind==="art"?card.pixelArt:card.pixelToken;
    if(own){ var p=get(own); if(p) return p; }
    var L=links(), ks=keysOf(card);
    for(var i=0;i<ks.length;i++){ var e=L[ks[i]]; if(e&&e[kind]){ var q=get(e[kind]); if(q) return q; } }
    return null;
  }

  window.KETER_PX={isHex:isHex, hexLayout:hexLayout, hexCellAt:hexCellAt, hexPath:hexPath, axialOf:axialOf, offsetOf:offsetOf,
    HEX_SIDES:HEX_SIDES, HEX_ACROSS:HEX_ACROSS, blankHexagon:blankHexagon, blankHexArt:blankHexArt,
    link:link, pictureFor:pictureFor, links:links, LINK_KEY:LINK_KEY,PALETTE:PALETTE, RGB:RGB, NEON:NEON, NEON_FROM:NEON_FROM, ART_W:ART_W, TOKEN_SIZES:TOKEN_SIZES,
    encode:encode, decode:decode, blank:blank, nearest:nearest, flatten:flatten, refreshFlat:refreshFlat,
    sprite:sprite, draw:draw, get:get, has:has, put:put, putMany:putMany, copy:copy, remove:remove, list:list, newId:newId,
    artSizeFor:artSizeFor, artHeightIn:artHeightIn, LIB_KEY:LIB_KEY,
    ART_WIDTHS:ART_WIDTHS, BLANK_MAX:BLANK_MAX, BLANK_HEX_MAX:BLANK_HEX_MAX, shrunk:shrunk, doubled:doubled, ramp:ramp, libBytes:libBytes, storeBytes:storeBytes, mark:mark,
    /* v12.5 */
    EXT:EXT, EXT_FROM:EXT_FROM, CUSTOM_FROM:CUSTOM_FROM, PAL_MAX:PAL_MAX, COL_KEY:COL_KEY, addColour:addColour, removeColour:removeColour,
    customColours:customColours, customRoom:customRoom, loadCustom:loadCustom, normHex:normHex, indexOfHex:indexOfHex, embed:embed, adopt:adopt,
    tableFor:tableFor, cssFor:cssFor, setOf:setOf, nameOf:nameOf, FAMILIES:FAMILIES, family:family, sortColours:sortColours, lightness:lightness,
    lab:lab, lch:lch, gen:function(){ return GEN; }, convert:convert,
    /* v14.3 */
    frameCount:frameCount, emptyFrameLike:emptyFrameLike, blankFrames:blankFrames, frameSprite:frameSprite, stripCanvas:stripCanvas};
  loadCustom();
})();
