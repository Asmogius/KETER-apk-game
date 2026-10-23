/* ==========================================================================
   KETER Pixel Studio. Draws pictures for cards (art) and the board (tokens)
   in the KETER palette, saving into the picture library as you go.

   The canvas knows nothing about squares: everything that depends on the
   grid's shape goes through GRID, so hex pixels can be added as a second
   grid without changing the tools.
   ========================================================================== */
(function(){
  "use strict";
  var PX=function(){ return window.KETER_PX; };
  var ST=null, HOST=null, VIEW=null, HOMEMODE="square";
  var TOKEN_TILE_IN=1.25;   /* a board tile, flat side to flat side */
  var ART_W_IN=2.270;       /* the card art box's width */

  function esc(s){ return String(s==null?"":s).replace(/[&<>"]/g,function(c){ return {"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;"}[c]; }); }
  function $(id){ return document.getElementById(id); }

  /* ---- the grid: squares for now ---- */
  var SQUARE={
    name:"square", modes:["off","lr","tb","both"],
    valid:function(){ return true; },
    bounds:function(pic){ return {minx:0,miny:0,maxx:pic.w,maxy:pic.h,w:pic.w,h:pic.h}; },
    centre:function(i,pic){ return {x:i%pic.w+0.5, y:((i/pic.w)|0)+0.5}; },
    cellAt:function(ax,ay,w,h){ var x=Math.floor(ax), y=Math.floor(ay); return (x<0||y<0||x>=w||y>=h)?-1:y*w+x; },
    neighbours:function(i,w,h){ var x=i%w, y=(i/w)|0, out=[];
      if(x>0) out.push(i-1); if(x<w-1) out.push(i+1); if(y>0) out.push(i-w); if(y<h-1) out.push(i+w); return out; },
    mirror:function(i,w,h,mode){ var x=i%w, y=(i/w)|0, out=[i];
      if(mode==="lr"||mode==="both") out.push(y*w+(w-1-x));
      if(mode==="tb"||mode==="both") out.push((h-1-y)*w+x);
      if(mode==="both") out.push((h-1-y)*w+(w-1-x));
      return out; },
    line:function(a,b,w){ var x0=a%w,y0=(a/w)|0,x1=b%w,y1=(b/w)|0, out=[];
      var dx=Math.abs(x1-x0), dy=-Math.abs(y1-y0), sx=x0<x1?1:-1, sy=y0<y1?1:-1, err=dx+dy;
      for(var n=0;n<512;n++){ out.push(y0*w+x0); if(x0===x1&&y0===y1) break;
        var e2=2*err; if(e2>=dy){ err+=dy; x0+=sx; } if(e2<=dx){ err+=dx; y0+=sy; } }
      return out; }
  };
  var DIRS=[[1,0],[1,-1],[0,-1],[-1,0],[-1,1],[0,1]];
  /* Hex pixels behind the same interface. Symmetry works geometrically: a
     cell's centre is reflected or turned about the canvas centre and the hex
     under the result is painted, so every mode works for both orientations
     and both canvas shapes. Three-way and six-way turn about the centre. */
  function hexGrid(pic){
    var P=PX(), L=P.hexLayout(pic), w=pic.w, h=pic.h;
    var axial=function(i){ return P.axialOf(i%w,(i/w)|0,L.orient); };
    var idx=function(q,r){ var o=P.offsetOf(q,r,L.orient); if(o.col<0||o.row<0||o.col>=w||o.row>=h) return -1; var j=o.row*w+o.col; return L.valid[j]?j:-1; };
    var B=L.bounds, c0;
    if(L.centre){ var cc=P.offsetOf(L.centre.q,L.centre.r,L.orient), ci=cc.row*w+cc.col; c0={x:L.cx[ci], y:L.cy[ci]}; }
    else c0={x:(B.minx+B.maxx)/2, y:(B.miny+B.maxy)/2};
    return {
      name:"hex", modes:["off","lr","tb","both","k3","k6","kal"], layout:L,
      valid:function(i){ return !!L.valid[i]; },
      bounds:function(){ return B; },
      centre:function(i){ return {x:L.cx[i], y:L.cy[i]}; },
      cellAt:function(ux,uy){ return P.hexCellAt(pic,ux,uy); },
      neighbours:function(i){ var a=axial(i), out=[]; DIRS.forEach(function(d){ var j=idx(a.q+d[0],a.r+d[1]); if(j>=0) out.push(j); }); return out; },
      line:function(a,b){
        var A=axial(a), Bb=axial(b), dq=Bb.q-A.q, dr=Bb.r-A.r, N=(Math.abs(dq)+Math.abs(dr)+Math.abs(dq+dr))/2, out=[];
        for(var k=0;k<=N;k++){
          var t=N?k/N:0, q=A.q+dq*t+1e-6, r=A.r+dr*t+1e-6, sx=-q-r;
          var rq=Math.round(q), rr=Math.round(r), rs=Math.round(sx);
          var eq=Math.abs(rq-q), er=Math.abs(rr-r), es=Math.abs(rs-sx);
          if(eq>er&&eq>es) rq=-rr-rs; else if(er>es) rr=-rq-rs;
          var j=idx(rq,rr); if(j>=0 && out.indexOf(j)<0) out.push(j);
        }
        return out;
      },
      mirror:function(i,ww,hh,mode){
        var x=L.cx[i]-c0.x, y=L.cy[i]-c0.y, pts=[[x,y]];
        if(mode==="lr"||mode==="both") pts.push([-x,y]);
        if(mode==="tb"||mode==="both") pts.push([x,-y]);
        if(mode==="both") pts.push([-x,-y]);
        if(mode==="k3"||mode==="k6"||mode==="kal"){
          var step=mode==="k3"?120:60;
          for(var a=step;a<360;a+=step){ var rad=a*Math.PI/180, co=Math.cos(rad), si=Math.sin(rad); pts.push([x*co-y*si, x*si+y*co]); }
        }
        /* the kaleidoscope: each of the six turns reflected as well, so a
           stroke is repeated twelve times, mirrored across six lines */
        if(mode==="kal"){
          for(var a2=0;a2<360;a2+=60){ var r2=a2*Math.PI/180, c2=Math.cos(r2), s2=Math.sin(r2); pts.push([-x*c2-y*s2, -x*s2+y*c2]); }
        }
        var out=[];
        pts.forEach(function(pt){ var j=P.hexCellAt(pic,pt[0]+c0.x,pt[1]+c0.y); if(j>=0 && out.indexOf(j)<0) out.push(j); });
        return out;
      },
      symCentre:c0
    };
  }
  function gridFor(pic){ return PX().isHex(pic)?hexGrid(pic):SQUARE; }
  /* v14.3: the frame being drawn on (a picture of one frame has only this one) */
  function FR(){ return ST.pic.frames[ST.frame||0]||FR(); }
  var GRIDS={square:SQUARE};

  /* ---- opening ---- */
  function open(opts){
    opts=opts||{};
    var P=PX(), pic=null, id=opts.id||null;
    if(!id && opts.card){ var had=P.pictureFor(opts.card.schema||opts.card, opts.kind); if(had){ pic=had; id=had.id; } }
    if(id && !pic) pic=P.get(id);
    if(!pic && !opts.size && !opts.side && !opts.across && !opts.w && !(opts.kind==="art" && opts.grid==="square")){ ST={choosing:true, opts:opts, orient:(ST&&ST.orient)||"pointy"}; show(); return; }
    if(!pic){
      var nm=(opts.card?opts.card.name+(opts.kind==="token"?" token":" art"):(opts.kind==="token"?"Token":"Card art"));
      if(opts.kind==="blank"){
        /* a free canvas, for any graphic: square pixels up to 256 each way,
           hex pixels up to 128 (v12.4) */
        var cap=opts.grid==="hex"?(P.BLANK_HEX_MAX||128):(P.BLANK_MAX||128);
        var bw=Math.max(1,Math.min(cap,opts.w||32)), bh=Math.max(1,Math.min(cap,opts.h||32));
        if(opts.grid==="hex" && opts.side) pic=P.blankHexagon(Math.min(64,opts.side), opts.orient, "Untitled");
        else { pic=P.blank(bw,bh,"Untitled"); if(opts.grid==="hex"){ pic.grid="hex"; pic.shape="rect"; pic.orient=opts.orient||"pointy"; } }
      }
      else if(opts.grid==="hex" && opts.kind==="token") pic=P.blankHexagon(opts.side||9, opts.orient, nm);
      else if(opts.grid==="hex") pic=P.blankHexArt(opts.across||40, opts.artHin||1.62, opts.orient, nm);
      else if(opts.kind==="token") pic=P.blank(opts.size||48, opts.size||48, nm);
      else { var sz=P.artSizeFor(opts.artHin||1.62, ART_W_IN, opts.artW||128); pic=P.blank(sz.w, sz.h, (opts.card?opts.card.name+" art":"Card art")); }
      pic.kind=opts.kind||"art"; pic.grid=pic.grid||"square";
    }
    pic.kind=pic.kind||opts.kind||(pic.w===pic.h&&pic.w<=48?"token":"art");
    /* v12.5: a picture's own colours come back into the palette */
    var adopted=P.adopt?P.adopt(pic):{moved:0,lost:0};
    var startCol=ST&&ST.colour||33; if(!P.PALETTE[startCol]) startCol=33;
    ST={pic:pic, id:id, kind:pic.kind, card:opts.card||null, from:opts.from||null,
        grid:gridFor(pic), layer:0, tool:"pencil", colour:startCol,
        recent:(ST&&ST.recent)||[], mirror:"off", cursor:false, showGrid:true, preview:false,
        shapeFill:false, ditherMode:"two", hexPattern:"third", colour2:0, pickTarget:1, sel:null, selRect:null,
        clip:(ST&&ST.clip)||null, showLayers:false,
        /* v12.4: brush size and shape, dither pattern, how Select picks,
           a layer shown alone, and the reference picture */
        size:(ST&&ST.size)||1, brushShape:(ST&&ST.brushShape)||"square", ditherPat:(ST&&ST.ditherPat)||"50",
        selMode:"box", solo:null, refPanel:false, refMove:false, refImg:null,
        undo:[], redo:[], saved:!!id, status:id?"Saved":"New",
        /* v12.5: taking a colour from the reference, what view the canvas shows, the actual-size preview, text */
        refPick:false, found:null, view:"colour", mini:MINI_ON,
        /* v14.3: frames: the one being drawn on, the one before seen faintly under it, playing them */
        frame:0, onion:true, playing:false, playAt:0, showFrames:(pic.frames||[]).length>1,
        font:(ST&&ST.font)||"small", tspace:(ST&&ST.tspace!=null)?ST.tspace:1, text:(ST&&ST.text)||""};
    if(adopted.moved) ST.status=adopted.moved+" of this picture’s own colours moved to free slots";
    if(adopted.lost) ST.status="No room for "+adopted.lost+" of this picture’s colours — the nearest palette colours stand in";
    ST.buf=P.decode(pic.frames[0].layers[ST.layer].px, pic.w*pic.h);
    VIEW=null;
    show();
    if(id && pic.ref) loadRef(id);
  }
  function show(){
    if(window.KETER_GO && (!HOST || HOST.id!=="v-studio" || !HOST.classList.contains("on"))){ window.KETER_GO(HOMEMODE==="hex"?"hexstudio":"studio"); return; }
    render(HOST||$("v-studio"));
  }
  function close(){
    var from=ST&&ST.from;
    /* a selection still floating is put down, not lost */
    if(ST && ST.sel) commitSelection();
    if(ST && ST.playing){ ST.playing=false; clearTimeout(playTimer); playTimer=null; }
    flushSave();
    ST=null; VIEW=null;
    /* the Forge redraws its card so the new art shows at once */
    forgeBridges().forEach(function(B){ try{ if(B.redraw) B.redraw(); }catch(e){} });
    if(from && window.KETER_GO) window.KETER_GO(from); else render(HOST);
  }

  /* ---- the home screen: the library, and starting something new ---- */
  function renderHome(){
    var P=PX(), pics=P.list().sort(function(a,b){ return String(b.saved||"").localeCompare(String(a.saved||"")); });
    var head='<h2 class="pxh">'+(HOMEMODE==="hex"?"Hex Studio <span class=\"pxexp\">experimental</span>":"Pixel Studio")+'</h2>'+
      '<div class="seg pxseg pxstabs">'+[["library","Library"],["skins","Skins"],["assets","Assets"]].map(function(x){ return '<button class="'+(STAB===x[0]?"on":"")+'" data-pxstab="'+x[0]+'">'+x[1]+'</button>'; }).join("")+'</div>';
    if(STAB!=="library" && window.KETER_STUDIO_TABS){ HOST.innerHTML='<div class="pxs">'+head+'<div id="pxTab"></div></div>'; window.KETER_STUDIO_TABS.render($("pxTab"), STAB); return; }
    HOST.innerHTML='<div class="pxs">'+head+
      '<p class="pxnote">'+(HOMEMODE==="hex"?"Draw with hexagonal pixels \u2014 as card art, or as tokens that fill a board tile.":"Draw card art and board tokens in the KETER palette.")+' Everything saves as you draw.</p>'+
      '<div class="pxrow"><button class="ghost primary" id="pxNewArt">Art for a card\u2026</button>'+
      '<button class="ghost" id="pxNewTok">New token</button>'+
      '<button class="ghost" id="pxNewBlank">Blank canvas</button>'+
      '<button class="ghost" id="pxNewImg">From an image\u2026</button></div>'+
      '<div id="pxPick"></div>'+
      '<p class="pxsub">Library \u00b7 '+pics.length+' \u00b7 '+storageLine()+'</p>'+
      (pics.length?'<div class="pxlib">'+pics.map(function(p){
        return '<div class="pxitem"><canvas data-pxthumb="'+esc(p.id)+'" width="72" height="72"></canvas>'+
          '<b>'+esc(p.name||"Untitled")+'</b><i>'+p.w+'\u00d7'+p.h+' \u00b7 '+esc(p.kind==="blank"?"graphic":(p.kind||""))+(p.grid==="hex"?" \u00b7 hex":"")+'</i>'+
          '<div class="pxrow"><button class="ghost" data-pxopen="'+esc(p.id)+'">Open</button>'+
          '<button class="ghost" data-pxcopy="'+esc(p.id)+'">Copy</button>'+
          '<button class="ghost" data-pxdel="'+esc(p.id)+'">Delete</button></div></div>';
      }).join("")+'</div>':'<p class="pxnote">Nothing drawn yet.</p>')+'</div>';
    [].slice.call(HOST.querySelectorAll("[data-pxthumb]")).forEach(function(c){
      var p=P.get(c.getAttribute("data-pxthumb")); if(!p) return;
      var g=c.getContext("2d"); g.fillStyle="#0e1418"; g.fillRect(0,0,72,72);
      P.draw(g,p,4,4,64,64,1,{minFill:0.5});
    });
  }
  /* v12.4: a 256 x 256 picture takes a real share of the space a browser gives
     each site, so the library says how much it is using */
  function mb(n){ return n>=1e6?(n/1e6).toFixed(1)+" MB":Math.max(1,Math.round(n/1e3))+" KB"; }
  function storageLine(){
    var P=PX(); if(!P.libBytes) return "";
    return 'pictures '+mb(P.libBytes())+' \u00b7 the whole app '+mb(P.storeBytes())+' of about 5 MB';
  }
  function renderCardPicker(q){
    var host=$("pxPick"); if(!host) return;
    var all=(window.KETER_ALLCARDS?window.KETER_ALLCARDS():[]);
    q=String(q||"").toLowerCase();
    var hits=q?all.filter(function(c){ return String(c.name||"").toLowerCase().indexOf(q)>=0; }).slice(0,12):[];
    host.innerHTML='<div class="pxpick"><input id="pxPickQ" placeholder="Which card? Type a name" value="'+esc(q)+'">'+
      hits.map(function(c,i){ return '<div class="pxhit" data-pxcard="'+i+'"><b>'+esc(c.name)+'</b><i>'+esc(c.id||"")+' \u00b7 '+esc(c.cardType||"")+'</i></div>'; }).join("")+
      '</div>';
    host._hits=hits;
    var inp=$("pxPickQ"); if(inp){ inp.focus(); inp.setSelectionRange(inp.value.length,inp.value.length); }
  }
  function artBoxFor(schema){
    /* ask the Forge's own layout how tall this card's art box is */
    var B=forgeBridges()[0];
    if(!B || !B.renderCard) return 1.62;
    try{ var cv=document.createElement("canvas"); cv.width=250; cv.height=350;
      B.renderCard(cv.getContext("2d"), B.fromSchema(schema), 100, {}); return B.lastLayout().artH||1.62; }catch(e){ return 1.62; }
  }

  /* ---- the editor ---- */
  function renderEditor(){
    var P=PX(), pic=ST.pic;
    HOST.innerHTML='<div class="pxe">'+
      '<div class="pxtop"><button class="ghost" id="pxBack" aria-label="Back">\u2190</button>'+
      '<input id="pxName" value="'+esc(pic.name||"")+'" aria-label="Picture name">'+
      '<button class="ghost" id="pxUndo" aria-label="Undo">\u21b6</button>'+
      '<button class="ghost" id="pxRedo" aria-label="Redo">\u21b7</button>'+
      '<button class="ghost" id="pxMore" aria-label="More">\u22ef</button></div>'+
      '<div class="pxmeta"><span>'+pic.w+'\u00d7'+pic.h+' \u00b7 '+(ST.kind==="token"?"token":ST.kind==="blank"?"graphic":"card art")+(ST.card?' \u00b7 '+esc(ST.card.name):'')+'</span>'+
      '<span id="pxCount"></span><span id="pxStatus"></span></div>'+
      '<div class="pxstage" id="pxStage"><canvas id="pxCanvas"></canvas><canvas id="pxOver" class="pxover"></canvas>'+
        '<div class="pxzoom"><button class="ghost" id="pxZoomOut">\u2212</button><button class="ghost" id="pxFit">Fit</button><button class="ghost" id="pxZoomIn">+</button></div>'+
        /* v12.5: the picture at one and two screen points a pixel, and which view is on */
        '<div class="pxmini" id="pxMiniBox" style="display:none"><canvas id="pxMini"></canvas></div>'+
        '<button class="pxviewtag" id="pxViewTag" style="display:none"></button></div>'+
      '<div id="pxFrames"></div>'+
      '<div class="pxtools" id="pxTools"></div>'+
      '<div class="pxopts" id="pxRef" style="display:none"></div>'+
      '<div class="pxopts" id="pxOpts"></div>'+
      '<div class="pxpal" id="pxPal"></div>'+
      '<div id="pxLayers"></div>'+
      '<div id="pxPrev"></div>'+
      '<div id="pxMenu"></div></div>';
    renderTools(); renderOpts(); renderRef(); renderPalette(); fitView(); drawCanvas(); updateMeta(); wireCanvas(); renderLayers(); renderFrames();
    if(ST.preview) renderPreview();
  }
  var TOOLS=[["pencil","\u270e","Pencil"],["eraser","\u232b","Eraser"],["fill","\u25a7","Fill"],["pick","\u25c9","Pick colour"],
             ["line","\u2571","Line"],["rect","\u25ad","Rectangle"],["circle","\u25ef","Circle"],["dither","\u2592","Dither"],["select","\u2b1a","Select"],
             ["text","A","Text"]];
  var MIRROR_LABEL={off:"Mirror off", lr:"Mirror \u2194", tb:"Mirror \u2195", both:"Mirror \u2194\u2195", k3:"Three-way", k6:"Six-way", kal:"Kaleidoscope"};
  function renderTools(){
    $("pxTools").innerHTML=TOOLS.filter(function(t){ return !(t[0]==="text" && ST.grid.name==="hex"); }).map(function(t){
      return '<button class="pxtool'+(ST.tool===t[0]?" on":"")+'" data-pxtool="'+t[0]+'" aria-label="'+t[2]+'"><span>'+t[1]+'</span><i>'+t[2]+'</i></button>';
    }).join("")+
    '<button class="pxtool'+(ST.mirror!=="off"?" on":"")+'" id="pxMirror"><span>\u2016</span><i>'+MIRROR_LABEL[ST.mirror]+'</i></button>'+
    '<button class="pxtool'+(ST.cursor?" on":"")+'" id="pxCursor"><span>\u2316</span><i>'+(ST.cursor?"Cursor":"Direct")+'</i></button>'+
    '<button class="pxtool'+(ST.refPanel||(ST.pic.ref&&!ST.pic.ref.hidden&&ST.refImg)?" on":"")+'" id="pxRefTog"><span>\u29c9</span><i>Reference</i></button>';
  }
  /* v12.4: the brush size and shape, shared by pencil, eraser, line and dither */
  function brushBar(){
    var hex=ST.grid.name==="hex";
    return '<div class="seg pxseg pxbrush">'+BRUSH_SIZES.map(function(n){
        return '<button class="'+((ST.size||1)===n?"on":"")+'" data-pxbrush="'+n+'" aria-label="Brush size '+n+'">'+n+'</button>'; }).join("")+'</div>'+
      (hex?"":'<div class="seg pxseg"><button class="'+(ST.brushShape!=="round"?"on":"")+'" data-pxshape="square">\u25a0 Square</button>'+
        '<button class="'+(ST.brushShape==="round"?"on":"")+'" data-pxshape="round">\u25cf Round</button></div>');
  }
  var NUDGE='<span class="pxnudge"><button class="ghost" data-pxsel="nudge-l" aria-label="Nudge left">\u2190</button>'+
    '<button class="ghost" data-pxsel="nudge-u" aria-label="Nudge up">\u2191</button><button class="ghost" data-pxsel="nudge-d" aria-label="Nudge down">\u2193</button>'+
    '<button class="ghost" data-pxsel="nudge-r" aria-label="Nudge right">\u2192</button></span>';
  function renderOpts(){
    var o=$("pxOpts"); if(!o||!ST) return;
    var hex=ST.grid.name==="hex", h="";
    if(ST.sel || (ST.tool==="select")){
      var on=!!ST.sel;
      h='<div class="seg pxseg"><button class="'+(ST.selMode==="box"?"on":"")+'" data-pxselmode="box">Box</button>'+
        '<button class="'+(ST.selMode==="wand"?"on":"")+'" data-pxselmode="wand">Joined colour</button>'+
        '<button class="'+(ST.selMode==="colour"?"on":"")+'" data-pxselmode="colour">Colour on layer</button></div>'+
        '<button class="ghost" data-pxsel="all">All</button>'+NUDGE+
        '<button class="ghost" data-pxsel="fliph"'+(on?"":" disabled")+'>Flip \u2194</button>'+
        '<button class="ghost" data-pxsel="flipv"'+(on?"":" disabled")+'>Flip \u2195</button>'+
        (hex?"":'<button class="ghost" data-pxsel="rotate"'+(on?"":" disabled")+'>Turn \u21bb</button>')+
        /* v12.5: scaling, square pixels only */
        (hex?"":'<button class="ghost" data-pxsel="x2"'+(on?"":" disabled")+' title="Twice the size">\u00d72</button>'+
          '<button class="ghost" data-pxsel="half"'+(on?"":" disabled")+' title="Half the size">\u00bd</button>'+
          '<input type="number" id="pxScalePct" class="pxnum pxpct" min="10" max="800" step="5" value="'+(ST.scalePct||150)+'" aria-label="Scale by percent">'+
          '<button class="ghost" data-pxsel="pct"'+(on?"":" disabled")+'>Scale %</button>')+
        '<button class="ghost" data-pxsel="copy"'+(on?"":" disabled")+'>Copy</button>'+
        '<button class="ghost" data-pxsel="paste"'+(ST.clip?"":" disabled")+'>Paste</button>'+
        '<button class="ghost" data-pxsel="delete"'+(on?"":" disabled")+'>Delete</button>'+
        '<button class="ghost primary" data-pxsel="done"'+(on?"":" disabled")+'>Done</button>'+
        (on?"":'<span class="pxhint">'+(ST.selMode==="box"?"Drag across the picture to select.":"Tap a pixel to select its colour.")+' Drag inside a selection to move it; the arrows nudge it a pixel, or the whole layer when nothing is selected.</span>');
    } else if(ST.tool==="text"){
      var fb=function(k,l){ return '<button class="'+(ST.font===k?"on":"")+'" data-pxfont="'+k+'">'+l+'</button>'; };
      var sb=function(k,l){ return '<button class="'+(ST.tspace===k?"on":"")+'" data-pxtsp="'+k+'">'+l+'</button>'; };
      h='<textarea id="pxText" class="pxtextin" rows="2" placeholder="Type here" aria-label="Text">'+esc(ST.text||"")+'</textarea>'+
        '<div class="seg pxseg">'+fb("small","Small 3\u00d75")+fb("large","Large 5\u00d77")+'</div>'+
        '<div class="seg pxseg">'+sb(0,"Tight")+sb(1,"Normal")+sb(2,"Wide")+'</div>'+
        '<button class="ghost primary" id="pxTextPlace">Place</button>'+
        '<span class="pxhint">Placed as a selection in your colour: drag it into place, then Done. Capitals, numbers and . , ! ? : ; - + = / \' " ( ) % * # &amp;</span>';
    } else if(ST.tool==="line"||ST.tool==="rect"||ST.tool==="circle"){
      h=ST.tool==="line"?brushBar()+'<span class="pxhint">Drag from one end to the other; the brush size sets its width.</span>':
        '<div class="seg pxseg"><button class="'+(ST.shapeFill?"":"on")+'" data-pxfill="0">Outline</button><button class="'+(ST.shapeFill?"on":"")+'" data-pxfill="1">Filled</button></div>';
    } else if(ST.tool==="pencil"||ST.tool==="eraser"){
      h=brushBar();
    } else if(ST.tool==="dither"){
      var P0=ST.ditherPat||"50", pat=function(k,l){ return '<button class="'+(P0===k?"on":"")+'" data-pxdp="'+k+'">'+l+'</button>'; };
      h='<div class="seg pxseg"><button class="'+(ST.ditherMode==="two"?"on":"")+'" data-pxdm="two">Two colours</button>'+
        '<button class="'+(ST.ditherMode==="over"?"on":"")+'" data-pxdm="over">Over what\u2019s there</button></div>'+
        (hex?'<div class="seg pxseg"><button class="'+(ST.hexPattern==="third"?"on":"")+'" data-pxhp="third">\u2153</button>'+
             '<button class="'+(ST.hexPattern==="rows"?"on":"")+'" data-pxhp="rows">\u00bd rows</button>'+
             '<button class="'+(ST.hexPattern==="twothirds"?"on":"")+'" data-pxhp="twothirds">\u2154</button></div>'
            :'<div class="seg pxseg">'+pat("25","25%")+pat("50","50%")+pat("75","75%")+pat("hatch","Hatch")+pat("grad","Gradient")+'</div>')+
        (!hex&&P0==="grad"?'<span class="pxhint">Drag across an area: it fades from the second colour at the start to your colour at the end, over the joined pixels you start on.</span>':brushBar());
    }
    o.innerHTML=h; o.style.display=h?"":"none";
  }
  /* v12.4: swatch groups you name and keep, shared by every picture */
  var SWATCH_KEY="keter-app-swatches";
  function swatchGroups(){ try{ return JSON.parse(localStorage.getItem(SWATCH_KEY)||"[]")||[]; }catch(e){ return []; } }
  function saveSwatchGroups(g){ try{ localStorage.setItem(SWATCH_KEY,JSON.stringify(g)); }catch(e){} }
  /* v12.5: how the open palette is shown — which set, which colour family,
     which band of value, in what order. Remembered on this device. */
  var PALVIEW_KEY="keter-app-palview";
  function palView(){
    var d={set:"all", fam:"all", val:"any", sort:"palette"};
    try{ var o=JSON.parse(localStorage.getItem(PALVIEW_KEY)||"{}")||{}; Object.keys(d).forEach(function(k){ if(o[k]) d[k]=o[k]; }); }catch(e){}
    return d;
  }
  function savePalView(v){ try{ localStorage.setItem(PALVIEW_KEY,JSON.stringify(v)); }catch(e){} }
  var SET_LABEL={all:"All colours", splendor:"Splendor 128", neon:"Neon 11", keter:"KETER 56", mine:"My colours", picture:"In this picture", groups:"Swatch groups"};
  var VAL_LABEL={any:"Any value", dark:"Dark", mid:"Mid", light:"Light"};
  var SORT_LABEL={palette:"Palette order", hue:"By hue", light:"Light to dark"};
  var FAM_DOT={Reds:"#b9451d",Oranges:"#f1641f",Earth:"#8c5b3e",Yellows:"#f8c53a",Greens:"#61a53f",Teals:"#42bfe8",Blues:"#4572e3",Purples:"#7864c6",Pinks:"#d480bb",Greys:"#807b7a"};
  function inBand(i,val){ if(val==="any") return true; var L=PX().lightness(i); return val==="dark"?L<35:val==="mid"?(L>=35&&L<=70):L>70; }
  function setColours(set){
    var P=PX(), out=[], i;
    if(set==="picture") return (ST.usedCols||[]).slice();
    if(set==="mine") return P.customColours();
    var from=set==="splendor"?1:set==="neon"?P.NEON_FROM:set==="keter"?P.EXT_FROM:1;
    var to=set==="splendor"?P.NEON_FROM-1:set==="neon"?P.EXT_FROM-1:set==="keter"?P.CUSTOM_FROM-1:P.PAL_MAX;
    for(i=from;i<=to;i++) if(P.PALETTE[i]) out.push(i);
    return out;
  }
  function filtered(list,V){ var P=PX(); return list.filter(function(i){ return (V.fam==="all"||P.family(i)===V.fam) && inBand(i,V.val); }); }
  function swTitle(i){
    var P=PX(), n=P.nameOf?P.nameOf(i):"", set=P.setOf?P.setOf(i):"";
    return (P.PALETTE[i]||"")+(n?" · "+n:"")+(set==="mine"?" · my colour":"");
  }
  /* anything using this colour right now, on any layer */
  function picUses(i){
    var Ls=FR().layers, n=ST.pic.w*ST.pic.h;
    for(var j=0;j<Ls.length;j++){ var px=j===ST.layer?ST.buf:PX().decode(Ls[j].px,n); for(var k=0;k<n;k++) if(px[k]===i) return true; }
    return false;
  }
  function renderPalette(){
    var P=PX(), pal=P.PALETTE;
    var sw=function(i){ return '<button class="pxsw'+(ST.colour===i?" on":"")+(i>=P.CUSTOM_FROM?" mine":"")+'" data-pxcol="'+i+'" style="background:'+pal[i]+'" title="'+esc(swTitle(i))+'" aria-label="colour '+i+' '+esc(swTitle(i))+'"></button>'; };
    var grid=function(list){ return '<div class="pxgrid">'+list.map(sw).join("")+'</div>'; };
    /* the ramp: the nearest darker and lighter palette colours of a like hue */
    var R=P.ramp?P.ramp(ST.colour,3):{darker:[],lighter:[]};
    var ramp='<div class="pxramp"><span class="pxlbl">Ramp</span>'+R.darker.slice().reverse().map(sw).join("")+
      '<span class="pxrampmid">'+sw(ST.colour)+'</span>'+R.lighter.map(sw).join("")+
      /* v12.5: the current colour by name, for a phone that shows no tooltips */
      '<span class="pxcurhex">'+esc(swTitle(ST.colour))+'</span></div>';
    var groups=swatchGroups(), V=palView(), body="";
    if(ST.palOpen){
      var opt=function(map,cur){ return Object.keys(map).map(function(k){ return '<option value="'+k+'"'+(k===cur?" selected":"")+'>'+map[k]+'</option>'; }).join(""); };
      body='<div class="pxpalbar"><select id="pxPalSet" aria-label="Which colours">'+opt(SET_LABEL,V.set)+'</select>'+
        '<select id="pxPalSort" aria-label="Order">'+opt(SORT_LABEL,V.sort)+'</select>'+
        '<select id="pxPalVal" aria-label="Value">'+opt(VAL_LABEL,V.val)+'</select></div>'+
        '<div class="pxfams"><button class="pxfam'+(V.fam==="all"?" on":"")+'" data-pxfam="all">All</button>'+
        P.FAMILIES.map(function(f){ return '<button class="pxfam'+(V.fam===f?" on":"")+'" data-pxfam="'+f+'"><i style="background:'+FAM_DOT[f]+'"></i>'+f+'</button>'; }).join("")+'</div>';
      var plain=V.fam==="all" && V.val==="any" && V.sort==="palette";
      var sec=function(title,list){ var f=filtered(list,V); return f.length?'<p class="pxsub">'+title+' · '+f.length+'</p>'+grid(P.sortColours(f,V.sort)):""; };
      if(V.set==="groups" || (V.set==="all" && plain)){
        if(V.set==="all" && (ST.usedCols||[]).length) body+='<p class="pxsub">In this picture</p>'+grid(ST.usedCols.slice(0,32));
        body+='<p class="pxsub">Your swatch groups</p>'+
        (groups.length?groups.map(function(g,gi){
          return '<div class="pxgroup"><div class="pxrow"><b>'+esc(g.name||"Group")+'</b>'+
            '<button class="ghost pxic" data-pxgadd="'+gi+'" title="Add the current colour">+</button>'+
            '<button class="ghost pxic" data-pxgrem="'+gi+'" title="Take the current colour out">−</button>'+
            '<button class="ghost pxic" data-pxgdel="'+gi+'" title="Delete this group">✕</button></div>'+
            grid((g.cols||[]).filter(function(i){ return !!pal[i]; }))+'</div>'; }).join(""):'<p class="pxnote">None yet. Keep the colours of a material together — Gunmetal, Rust, Verdant — and reuse them in any picture.</p>')+
        '<div class="pxrow"><button class="ghost" data-pxgnew="pic">New group from this picture</button><button class="ghost" data-pxgnew="empty">New empty group</button></div>';
      }
      if(V.set==="all"){
        if(V.sort==="palette") body+=sec("Splendor 128",setColours("splendor"))+sec("Neon",setColours("neon"))+sec("KETER 56",setColours("keter"))+sec("My colours",setColours("mine"));
        else body+=sec(SORT_LABEL[V.sort],setColours("all"));
      } else if(V.set!=="groups") body+=sec(SET_LABEL[V.set],setColours(V.set));
      if(body.indexOf('data-pxcol')<0 && V.set!=="groups") body+='<p class="pxnote">No colours match. Try another family or value.</p>';
      if(V.set==="all"||V.set==="mine") body+=mineBlock();
    }
    $("pxPal").innerHTML=
      '<div class="pxcur"><span class="pxbig'+(ST.pickTarget!==2?" tgt":"")+'" id="pxBig1" style="background:'+pal[ST.colour]+'" title="'+esc(swTitle(ST.colour))+'"></span>'+
      (ST.tool==="dither"&&ST.ditherMode==="two"?'<span class="pxbig pxbig2'+(ST.pickTarget===2?" tgt":"")+'" id="pxBig2" title="Second colour" style="background:'+(ST.colour2?pal[ST.colour2]:"transparent")+'">'+(ST.colour2?"":"∅")+'</span>':"")+
      '<div class="pxrecent">'+ST.recent.filter(function(i){ return !!pal[i]; }).map(sw).join("")+'</div>'+
      '<button class="ghost" id="pxPalTog">'+(ST.palOpen?"Hide colours":"All colours")+'</button></div>'+foundBlock()+ramp+
      /* the open palette scrolls inside its own panel, so choosing a colour never
         scrolls the canvas off the screen */
      (ST.palOpen?'<div class="pxpalbody">'+body+'</div>':"");
  }
  /* your own colours: typed, chosen, or taken from the reference */
  function mineBlock(){
    var P=PX(), n=P.customColours().length, room=P.customRoom(), cur=ST.colour>=P.CUSTOM_FROM;
    return '<div class="pxmine"><p class="pxsub">Add my own colour · '+n+' of '+room+' used</p>'+
      '<div class="pxrow pxcustom"><input type="color" id="pxColPick" value="'+(P.PALETTE[ST.colour]||"#7a3b2e")+'" aria-label="Choose a colour">'+
      '<input id="pxColHex" placeholder="#7a3b2e" maxlength="7" class="pxhexin" aria-label="Colour as hex">'+
      '<button class="ghost primary" id="pxColAdd"'+(n>=room?" disabled":"")+'>Add</button>'+
      '<button class="ghost'+(ST.refPick?" primary":"")+'" id="pxColRef"'+(ST.refImg?"":" disabled title=\"Load a reference picture first\"")+'>'+(ST.refPick?"Tap the reference…":"From the reference")+'</button>'+
      (cur?'<button class="ghost" id="pxColDel">Remove the current colour</button>':'')+'</div>'+
      '<p class="pxnote">Your colours are kept on this device, and every picture that uses one carries a copy, so it looks the same anywhere.</p></div>';
  }
  /* a colour taken from the reference: use the nearest palette colour, or keep it as your own */
  function foundBlock(){
    var F=ST.found; if(!F) return "";
    var P=PX();
    return '<div class="pxfound"><span class="pxlbl">From the reference</span><span class="pxbig" style="background:'+F.hex+'" title="'+F.hex+'"></span>'+
      '<span class="pxlbl">nearest</span><span class="pxbig" style="background:'+P.PALETTE[F.near]+'" title="'+esc(swTitle(F.near))+'"></span>'+
      '<button class="ghost" id="pxFoundNear">Use nearest</button>'+
      '<button class="ghost primary" id="pxFoundAdd"'+(P.customColours().length>=P.customRoom()?" disabled":"")+'>Add as my colour</button>'+
      '<button class="ghost pxic" id="pxFoundX" aria-label="Dismiss">✕</button></div>';
  }
  function chooseColour(i){
    if(ST.pickTarget===2){ ST.colour2=i; ST.pickTarget=1; }
    else { ST.colour=i; if(ST.tool==="eraser"||ST.tool==="pick") ST.tool="pencil"; }
    renderTools(); renderPalette();
  }
  function addMine(hex){
    var P=PX(), h=P.normHex(hex);
    if(!h){ ST.status="Type a colour as six hex digits, like #7a3b2e"; updateMeta(); return; }
    var had=P.indexOfHex(h), i=P.addColour(h);
    if(i<0){ ST.status="All "+P.customRoom()+" of your colour slots are used — remove one first"; updateMeta(); return; }
    ST.status=had>0?"That colour is already in the palette":"Added to your colours"; updateMeta();
    chooseColour(i);
  }
  /* the reference's colour under a pixel: the average of what that pixel covers */
  function sampleRef(ux,uy){
    var R=ST.pic.ref, img=ST.refImg; if(!R||!img) return null;
    if(!ST.refData || ST.refData.img!==img){
      var c=document.createElement("canvas"); c.width=img.width; c.height=img.height;
      var g=c.getContext("2d"); g.drawImage(img,0,0);
      try{ ST.refData={img:img, d:g.getImageData(0,0,c.width,c.height).data, w:c.width, h:c.height}; }catch(e){ return null; }
    }
    var D=ST.refData, px=Math.floor(ux), py=Math.floor(uy);
    if(ST.grid.name==="hex"){ px=ux-0.5; py=uy-0.5; }
    var x0=Math.floor((px-R.x)/R.s), y0=Math.floor((py-R.y)/R.s), x1=Math.ceil((px+1-R.x)/R.s), y1=Math.ceil((py+1-R.y)/R.s);
    x0=Math.max(0,x0); y0=Math.max(0,y0); x1=Math.min(D.w,Math.max(x1,x0+1)); y1=Math.min(D.h,Math.max(y1,y0+1));
    if(x0>=D.w||y0>=D.h||x1<=0||y1<=0) return null;
    var r=0,gg=0,b=0,n=0, stepX=Math.max(1,Math.floor((x1-x0)/16)), stepY=Math.max(1,Math.floor((y1-y0)/16));
    for(var y=y0;y<y1;y+=stepY) for(var x=x0;x<x1;x+=stepX){ var o=(y*D.w+x)*4; if(D.d[o+3]<128) continue; r+=D.d[o]; gg+=D.d[o+1]; b+=D.d[o+2]; n++; }
    if(!n) return null;
    var hx=function(v){ return ("0"+Math.round(v/n).toString(16)).slice(-2); };
    return "#"+hx(r)+hx(gg)+hx(b);
  }
  var MODE_LABEL={view:"Opacity only while drawing", snap:"Blend, snapped to the palette", dither:"Blend as dither"};
  function renderLayers(){
    var host=$("pxLayers"); if(!host||!ST) return;
    var Ls=FR().layers;
    if(!ST.showLayers){ host.innerHTML='<button class="ghost pxlaytog" id="pxLayTog">Layers \u00b7 '+Ls.length+' \u25b4</button>'; return; }
    var rows=Ls.map(function(L,i){ return i; }).reverse().map(function(i){
      var L=Ls[i], on=i===ST.layer;
      return '<div class="pxlay'+(on?" on":"")+'" data-pxlay="'+i+'">'+
        '<button class="ghost pxic" data-pxvis="'+i+'" aria-label="Show or hide">'+(L.visible?"\u25c9":"\u25cb")+'</button>'+
        '<span class="pxlname">'+esc(L.name||("Layer "+(i+1)))+(L.opacity<100?' <i>'+L.opacity+'%</i>':'')+
          (L.alphaLock?' <i title="Alpha lock">\u03b1</i>':'')+(ST.solo===i?' <i>solo</i>':'')+'</span>'+
        '<button class="ghost pxic" data-pxlock="'+i+'" aria-label="Lock">'+(L.locked?"\u{1F512}":"\u{1F513}")+'</button>'+
        '<button class="ghost pxic" data-pxup="'+i+'" aria-label="Move up"'+(i===Ls.length-1?" disabled":"")+'>\u25b2</button>'+
        '<button class="ghost pxic" data-pxdown="'+i+'" aria-label="Move down"'+(i===0?" disabled":"")+'>\u25bc</button></div>'+
        (on?'<div class="pxlayx">'+
          '<label>Opacity <input type="range" min="0" max="100" step="5" value="'+(L.opacity==null?100:L.opacity)+'" id="pxOpac"> <b id="pxOpacV">'+(L.opacity==null?100:L.opacity)+'%</b></label>'+
          '<select id="pxMode">'+["view","snap","dither"].map(function(m){ return '<option value="'+m+'"'+((L.mode||"view")===m?" selected":"")+'>'+MODE_LABEL[m]+'</option>'; }).join("")+'</select>'+
          '<div class="pxrow"><button class="ghost" id="pxLayRen">Rename</button><button class="ghost" id="pxLayDup">Duplicate</button>'+
          '<button class="ghost" id="pxLayDel"'+(Ls.length<2?" disabled":"")+'>Delete</button></div>'+
          /* v12.4 */
          '<div class="pxrow"><button class="ghost'+(L.alphaLock?" primary":"")+'" id="pxLayAlpha" title="Paint only where this layer already has pixels">Alpha lock '+(L.alphaLock?"on":"off")+'</button>'+
          '<button class="ghost'+(ST.solo===i?" primary":"")+'" id="pxLaySolo" title="See this layer alone">'+(ST.solo===i?"Show all":"Solo")+'</button>'+
          '<button class="ghost" id="pxLayMerge"'+(i<1?" disabled":"")+' title="Merge into the layer below">Merge down</button></div></div>':"");
    }).join("");
    host.innerHTML='<div class="pxlays"><div class="pxrow" style="align-items:center;"><button class="ghost pxlaytog" id="pxLayTog">Layers \u25be</button>'+
      '<button class="ghost primary" id="pxLayAdd">+ Layer</button></div>'+rows+'</div>';
  }
  /* Changes to the layers themselves are undoable too: the whole set is
     remembered before each change. (A first draft cleared the history instead,
     which made deleting a layer by mistake permanent.) */
  /* (v14.3: every frame, and which one is being drawn on: adding, copying,
     moving and deleting frames are undone the same way) */
  function layersNow(){ commitLayer(); return {frames:JSON.stringify(ST.pic.frames), frame:ST.frame||0, layer:ST.layer, w:ST.pic.w, h:ST.pic.h, ref:ST.pic.ref?JSON.stringify(ST.pic.ref):null}; }
  function pushLayersUndo(){ ST.undo.push(layersNow()); if(ST.undo.length>100) ST.undo.shift(); ST.redo=[]; }
  function restoreLayers(u){
    /* v12.4: doubling the pixels changes the picture's size, so the size comes back too */
    if(u.w && (u.w!==ST.pic.w || u.h!==ST.pic.h)){ ST.pic.w=u.w; ST.pic.h=u.h; ST.checker=null; VIEW=null; if($("pxCanvas")) fitView(); }
    if(u.ref!==undefined) ST.pic.ref=u.ref?JSON.parse(u.ref):ST.pic.ref;
    ST.solo=null;
    ST.pic.frames=JSON.parse(u.frames);
    ST.frame=Math.max(0,Math.min(u.frame||0, ST.pic.frames.length-1));
    ST.layer=Math.min(u.layer, FR().layers.length-1);
    ST.buf=PX().decode(FR().layers[ST.layer].px, ST.pic.w*ST.pic.h);
    ST.pic.flat="";
  }
  function layerChanged(){ ST.pic.flat=""; renderLayers(); drawCanvas(); updateMeta(); scheduleSave(); }
  function updateMeta(){
    var P=PX(), flat=P.flatten(ST.pic,ST.frame||0), used={};
    for(var i=0;i<flat.length;i++) if(flat[i]) used[flat[i]]=(used[flat[i]]||0)+1;
    var n=Object.keys(used).length;
    /* the picture's own colours, most used first, for the palette */
    ST.usedCols=Object.keys(used).map(Number).sort(function(a,b){ return used[b]-used[a]; });
    if($("pxCount")) $("pxCount").textContent=n+" colour"+(n===1?"":"s");
    if($("pxStatus")) $("pxStatus").textContent=ST.status||"";
  }

  /* ---- what the canvas shows (v12.5): the colours, their values as greys, or
     every pixel one dark shape on a light ground — the checks a pixel
     artist makes for contrast and for a readable outline ---- */
  var VIEW_LABEL={colour:"Colour", value:"Value", silhouette:"Silhouette"}, MINI_ON=false;
  function viewTable(){
    if(!ST || !ST.view || ST.view==="colour") return null;
    var P=PX(), key=ST.view+":"+(P.gen?P.gen():0);
    if(ST.vt && ST.vt.id===key) return ST.vt;
    var rgb=[], css=[];
    for(var i=0;i<=P.PAL_MAX;i++){
      var c=P.RGB[i]; if(!c){ rgb.push(null); css.push(null); continue; }
      var v=ST.view==="value"?Math.round(Math.max(0,Math.min(100,P.lab(c)[0]))*2.55):20;
      rgb.push([v,v,v]); css.push("rgb("+v+","+v+","+v+")");
    }
    return (ST.vt={id:key, rgb:rgb, css:css});
  }
  function viewCss(v){ var t=viewTable(); return t?t.css[v]:PX().PALETTE[v]; }
  function tones(){ return ST.view==="silhouette"?["#c9d0d6","#d8dee3","#d0d7dc"]:["#1c252c","#232e36","#1f2930"]; }
  /* the picture at one and two screen points a pixel, in a corner of the stage */
  function drawMini(){
    var box=$("pxMiniBox"), c=$("pxMini"); if(!box||!c) return;
    var tag=$("pxViewTag");
    if(tag){ var vv=ST.view&&ST.view!=="colour"; tag.style.display=vv?"":"none"; if(vv) tag.textContent=VIEW_LABEL[ST.view]+" view \u00b7 tap for colour"; }
    if(!ST.mini){ box.style.display="none"; return; }
    var P=PX(), pic=ST.pic, dpr=Math.min(window.devicePixelRatio||1,3), hex=ST.grid.name==="hex";
    var Ls=FR().layers.map(function(L,i){ return i===ST.layer?{visible:L.visible,opacity:L.opacity,mode:L.mode,px:P.encode(ST.buf)}:L; });
    var tmp={w:pic.w,h:pic.h,grid:pic.grid,orient:pic.orient,shape:pic.shape,side:pic.side,frames:[{layers:Ls}]};
    var flat=P.flatten(tmp,0); tmp.flat=P.encode(flat);
    var B=ST.grid.bounds(pic), w1=hex?Math.round(pic.w*1.5):pic.w, h1=Math.round(w1*B.h/B.w), stageW=(VIEW&&VIEW.w)||300;
    var two=w1*3+6<=stageW*0.6, W=two?w1*3+6:w1, H=two?h1*2:h1;
    c.width=Math.round(W*dpr); c.height=Math.round(H*dpr); c.style.width=W+"px"; c.style.height=H+"px";
    var g=c.getContext("2d"); g.setTransform(dpr,0,0,dpr,0,0); g.clearRect(0,0,W,H);
    var vt=viewTable(), put=function(x,y,k){
      if(hex){ P.draw(g,tmp,x,y,w1*k,h1*k,dpr); return; }
      g.imageSmoothingEnabled=false; g.drawImage(P.sprite(tmp,vt||undefined),x,y,w1*k,h1*k); };
    if(ST.view==="silhouette"){ g.fillStyle="#d8dee3"; g.fillRect(0,0,W,H); }
    put(0,two?h1/2:0,1); if(two) put(w1+6,0,2);
    box.style.display="";
  }

  /* ---- view: whole-number zoom, so pixels stay square ---- */
  function fitView(){
    var st=$("pxStage"), cv=$("pxCanvas"); if(!st||!cv) return;
    var dpr=Math.min(window.devicePixelRatio||1,3), w=st.clientWidth, h=st.clientHeight;
    cv.width=Math.round(w*dpr); cv.height=Math.round(h*dpr); cv.style.width=w+"px"; cv.style.height=h+"px";
    var ov=$("pxOver"); if(ov){ ov.width=cv.width; ov.height=cv.height; ov.style.width=w+"px"; ov.style.height=h+"px"; }
    if(!VIEW){
      var B=ST.grid.bounds(ST.pic);
      var z=Math.max(1,Math.floor(Math.min(w/B.w, h/B.h)*0.92));
      VIEW={z:z, x:Math.round((w-B.w*z)/2-B.minx*z), y:Math.round((h-B.h*z)/2-B.miny*z)};
    }
    VIEW.dpr=dpr; VIEW.w=w; VIEW.h=h;
  }
  function zoomAt(z, px, py){
    z=Math.max(1,Math.min(64,Math.round(z)));
    if(px===undefined){ px=VIEW.w/2; py=VIEW.h/2; }
    var ax=(px-VIEW.x)/VIEW.z, ay=(py-VIEW.y)/VIEW.z;
    VIEW.z=z; VIEW.x=Math.round(px-ax*z); VIEW.y=Math.round(py-ay*z);
    drawCanvas();
  }
  function drawCanvas(){
    var cv=$("pxCanvas"); if(!cv||!VIEW) return;
    var P=PX(), g=cv.getContext("2d"), pic=ST.pic, z=VIEW.z;
    g.setTransform(VIEW.dpr,0,0,VIEW.dpr,0,0);
    g.fillStyle="#0a0f13"; g.fillRect(0,0,VIEW.w,VIEW.h);
    if(ST.grid.name==="hex"){ drawHexCanvas(g); return; }
    /* transparency shows as a quiet checker, one square per pixel, drawn once
       at one dot per pixel and scaled up rather than 16,000 squares a frame */
    var light=ST.view==="silhouette";
    if(!ST.checker || ST.checker.width!==pic.w || ST.checker.height!==pic.h || !!ST.checker.light!==light){
      var ck=document.createElement("canvas"); ck.width=pic.w; ck.height=pic.h; ck.light=light;
      var cg=ck.getContext("2d"), cd=cg.createImageData(pic.w,pic.h);
      var A=light?[0xc9,0xd0,0xd6]:[0x1c,0x25,0x2c], Bq=light?[0xd8,0xde,0xe3]:[0x23,0x2e,0x36];
      for(var y=0;y<pic.h;y++) for(var x=0;x<pic.w;x++){ var o=(y*pic.w+x)*4, dk=(x+y)&1;
        cd.data[o]=dk?A[0]:Bq[0]; cd.data[o+1]=dk?A[1]:Bq[1]; cd.data[o+2]=dk?A[2]:Bq[2]; cd.data[o+3]=255; }
      cg.putImageData(cd,0,0); ST.checker=ck;
    }
    g.imageSmoothingEnabled=false; g.drawImage(ST.checker, VIEW.x, VIEW.y, pic.w*z, pic.h*z);
    if(refVisible() && !ST.pic.ref.above) drawRef(g);
    g.imageSmoothingEnabled=false;
    var vt=viewTable();
    canvasViews().forEach(function(Lv){
      g.globalAlpha=Lv.alpha;
      g.drawImage(P.sprite({w:pic.w,h:pic.h,flat:P.encode(Lv.px),custom:pic.custom},vt||undefined), VIEW.x, VIEW.y, pic.w*z, pic.h*z);
    });
    g.globalAlpha=1;
    if(refVisible() && ST.pic.ref.above) drawRef(g);
    drawOverlays(g);
    if(ST.showGrid && z>=6){
      g.strokeStyle="rgba(255,255,255,0.07)"; g.lineWidth=1/VIEW.dpr; g.beginPath();
      for(var gx=0;gx<=pic.w;gx++){ g.moveTo(VIEW.x+gx*z+0.5/VIEW.dpr, VIEW.y); g.lineTo(VIEW.x+gx*z+0.5/VIEW.dpr, VIEW.y+pic.h*z); }
      for(var gy=0;gy<=pic.h;gy++){ g.moveTo(VIEW.x, VIEW.y+gy*z+0.5/VIEW.dpr); g.lineTo(VIEW.x+pic.w*z, VIEW.y+gy*z+0.5/VIEW.dpr); }
      g.stroke();
    }
    g.strokeStyle="rgba(87,216,227,0.35)"; g.lineWidth=1; g.strokeRect(VIEW.x-0.5, VIEW.y-0.5, pic.w*z+1, pic.h*z+1);
    if(ST.mirror!=="off"){
      g.strokeStyle="rgba(255,122,26,0.7)"; g.setLineDash([4,4]); g.beginPath();
      if(ST.mirror==="lr"||ST.mirror==="both"){ g.moveTo(VIEW.x+pic.w*z/2, VIEW.y); g.lineTo(VIEW.x+pic.w*z/2, VIEW.y+pic.h*z); }
      if(ST.mirror==="tb"||ST.mirror==="both"){ g.moveTo(VIEW.x, VIEW.y+pic.h*z/2); g.lineTo(VIEW.x+pic.w*z, VIEW.y+pic.h*z/2); }
      g.stroke(); g.setLineDash([]);
    }
    afterFullDraw();
  }
  /* After a full redraw, remember what the canvas shows. During a stroke only
     the pixels that differ from it are repainted: a full redraw every step took
     about 30ms on a 128x128 hex canvas on a desktop, several times that on a
     phone. The full redraw comes once, when the finger lifts. */
  function afterFullDraw(){ ST.shown=ST.buf.slice(); ST.shownLayer=ST.layer; ST.lbufs=null; drawMini(); }
  /* ---- frames (v14.3) ----
     A picture can have several frames, each with its own layers, played in
     order at its speed (fps): the game's effects are drawn so. The strip
     under the canvas shows them all: tap one to draw on it; add a blank one,
     copy this one, move it earlier or later, delete it. The frame before is
     seen faintly under the one being drawn on (onion skin). Play shows them
     in turn on the canvas; a tap on the canvas stops it. */
  function onionShown(){ return !!(ST && ST.onion && !ST.playing && (ST.frame||0)>0 && PX().frameCount(ST.pic)>1); }
  function canvasViews(){
    var P=PX();
    if(ST.playing) return [{px:P.flatten(ST.pic, ST.playAt||0), alpha:1}];
    var out=onionShown()?[{px:P.flatten(ST.pic, ST.frame-1), alpha:0.28}]:[];
    return out.concat(layerViews());
  }
  function switchFrame(i){
    var n=PX().frameCount(ST.pic); i=Math.max(0,Math.min(n-1,i|0));
    if(ST.sel) commitSelection();
    commitLayer(); ST.frame=i; ST.solo=null;
    ST.layer=Math.min(ST.layer, FR().layers.length-1);
    ST.buf=PX().decode(FR().layers[ST.layer].px, ST.pic.w*ST.pic.h);
    ST.shown=null;
  }
  function frameChanged(){ ST.pic.flat=""; ST.showFrames=true; renderFrames(); renderLayers(); drawCanvas(); updateMeta(); scheduleSave(); }
  function addFrame(copy){
    if(ST.playing) stopPlaying();
    pushLayersUndo();
    var P=PX(), fr=copy?JSON.parse(JSON.stringify(FR())):P.emptyFrameLike(ST.pic, ST.frame||0);
    ST.pic.frames.splice((ST.frame||0)+1, 0, fr);
    if(!ST.pic.fps) ST.pic.fps=12;
    switchFrame((ST.frame||0)+1); ST.status=copy?"Frame copied":"Frame added"; frameChanged();
  }
  function deleteFrame(){
    if(PX().frameCount(ST.pic)<2) return;
    if(ST.playing) stopPlaying();
    if(ST.sel) commitSelection();
    pushLayersUndo();
    ST.pic.frames.splice(ST.frame||0, 1);
    ST.frame=Math.max(0,(ST.frame||0)-1);
    ST.layer=Math.min(ST.layer, FR().layers.length-1);
    ST.buf=PX().decode(FR().layers[ST.layer].px, ST.pic.w*ST.pic.h); ST.shown=null;
    ST.status="Frame deleted"; frameChanged();
  }
  function moveFrame(d){
    var n=PX().frameCount(ST.pic), from=ST.frame||0, to=from+d;
    if(to<0||to>=n) return;
    if(ST.playing) stopPlaying();
    pushLayersUndo();
    var f=ST.pic.frames.splice(from,1)[0]; ST.pic.frames.splice(to,0,f); ST.frame=to;
    ST.status="Frame moved"; frameChanged();
  }
  var playTimer=null;
  function startPlaying(){
    if(PX().frameCount(ST.pic)<2) return;
    if(ST.sel) commitSelection();
    commitLayer(); ST.playing=true; ST.playAt=ST.frame||0;
    var tick=function(){
      if(!ST || !ST.playing){ playTimer=null; return; }
      ST.playAt=(ST.playAt+1)%PX().frameCount(ST.pic); drawCanvas(); markPlaying();
      playTimer=setTimeout(tick, 1000/Math.max(1,Math.min(60,ST.pic.fps||12)));
    };
    clearTimeout(playTimer); playTimer=setTimeout(tick, 1000/Math.max(1,Math.min(60,ST.pic.fps||12)));
    renderFrames(); drawCanvas();
  }
  function stopPlaying(){ if(!ST) return; ST.playing=false; clearTimeout(playTimer); playTimer=null; renderFrames(); drawCanvas(); }
  function markPlaying(){ [].slice.call(document.querySelectorAll("[data-pxfr]")).forEach(function(b){ b.classList.toggle("play", +b.getAttribute("data-pxfr")===ST.playAt); }); }
  function renderFrames(){
    var host=$("pxFrames"); if(!host||!ST) return;
    var P=PX(), n=P.frameCount(ST.pic), cur=ST.frame||0;
    if(!ST.showFrames && n<2){ host.innerHTML='<button class="ghost pxlaytog" id="pxFrTog">Frames · 1 ▴</button>'; return; }
    commitLayer();
    var th=Math.max(24,Math.min(56,Math.round(48*ST.pic.h/Math.max(ST.pic.w,ST.pic.h)))), tw=Math.max(24,Math.round(th*ST.pic.w/ST.pic.h));
    var cells=[]; for(var i=0;i<n;i++) cells.push('<button class="pxfr'+(i===cur?" on":"")+(ST.playing&&i===ST.playAt?" play":"")+'" data-pxfr="'+i+'" aria-label="Frame '+(i+1)+'">'+
      '<canvas data-pxfrc="'+i+'" width="'+tw+'" height="'+th+'"></canvas><i>'+(i+1)+'</i></button>');
    host.innerHTML='<div class="pxframes"><div class="pxrow" style="align-items:center;">'+
      '<button class="ghost pxlaytog" id="pxFrTog">Frames · '+n+' ▾</button>'+
      '<button class="ghost'+(ST.playing?" primary":"")+'" id="pxFrPlay"'+(n<2?" disabled":"")+'>'+(ST.playing?"■ Stop":"▶ Play")+'</button>'+
      '<label class="pxfps">Speed <input type="number" id="pxFps" class="pxnum" min="1" max="60" step="1" value="'+(ST.pic.fps||12)+'" aria-label="Frames a second"> a second</label>'+
      '<button class="ghost'+(ST.onion?" primary":"")+'" id="pxOnion" title="See the frame before, faintly, under this one">Onion skin '+(ST.onion?"on":"off")+'</button></div>'+
      '<div class="pxfrstrip">'+cells.join("")+'</div>'+
      '<div class="pxrow"><button class="ghost primary" id="pxFrAdd">+ Frame</button><button class="ghost" id="pxFrCopy">Copy frame</button>'+
      '<button class="ghost" id="pxFrLeft"'+(cur<1?" disabled":"")+'>◀ Earlier</button><button class="ghost" id="pxFrRight"'+(cur>=n-1?" disabled":"")+'>Later ▶</button>'+
      '<button class="ghost" id="pxFrDel"'+(n<2?" disabled":"")+'>Delete frame</button></div></div>';
    [].slice.call(host.querySelectorAll("canvas[data-pxfrc]")).forEach(function(c){
      var i=+c.getAttribute("data-pxfrc"), g=c.getContext("2d");
      g.fillStyle="#0e1418"; g.fillRect(0,0,c.width,c.height); g.imageSmoothingEnabled=false;
      if(P.isHex(ST.pic)){ var t=JSON.parse(JSON.stringify(ST.pic)); t.frames=[ST.pic.frames[i]]; t.flat=""; P.draw(g,t,1,1,c.width-2,c.height-2,1,{minFill:0.5}); return; }
      g.drawImage(P.frameSprite(ST.pic,i), 1, 1, c.width-2, c.height-2);
    });
    var on=host.querySelector(".pxfr.on"); if(on && on.scrollIntoView){ try{ on.scrollIntoView({block:"nearest", inline:"nearest"}); }catch(e){} }
  }
  function canPartial(){
    if(!ST.shown || ST.shownLayer!==ST.layer || ST.shown.length!==ST.buf.length) return false;
    /* (v14.3: the frame before, seen under this one, is drawn whole) */
    if(ST.playing || onionShown()) return false;
    if(ST.sel || ST.selRect) return false;
    if(refVisible() && ST.grid.name==="hex") return false;
    var Ls=FR().layers;
    for(var j=0;j<Ls.length;j++){
      var L=Ls[j]; if(!L.visible) continue;
      var op=Math.max(0,Math.min(100,+L.opacity||0))/100;
      if(op<0.999 && (L.mode||"view")!=="dither") return false;
    }
    return true;
  }
  function layerBuf(j){
    if(j===ST.layer) return ST.buf;
    ST.lbufs=ST.lbufs||{};
    if(!ST.lbufs[j]) ST.lbufs[j]=PX().decode(FR().layers[j].px, ST.pic.w*ST.pic.h);
    return ST.lbufs[j];
  }
  /* what one pixel shows, layer by layer, exactly as the full redraw would */
  function shownAt(i){
    var Ls=FR().layers, out=0, w=ST.pic.w, x=i%w, y=(i/w)|0;
    for(var j=0;j<Ls.length;j++){
      var L=Ls[j]; if(!L.visible) continue;
      if(ST.solo!=null && ST.solo!==j) continue;
      var v=layerBuf(j)[i]; if(!v) continue;
      var op=Math.max(0,Math.min(100,+L.opacity||0))/100;
      if(op>=0.999 || op>=0.75 || (op>=0.25 && ((x+y)&1)===0)) out=v;
    }
    return out;
  }
  function partialDraw(){
    var cv=$("pxCanvas"); if(!cv||!VIEW) return;
    var P=PX(), g=cv.getContext("2d"), pic=ST.pic, z=VIEW.z, G=ST.grid, hex=G.name==="hex";
    var tn=tones(), L=hex?G.layout:null;
    g.setTransform(VIEW.dpr,0,0,VIEW.dpr,0,0);
    for(var i=0;i<ST.buf.length;i++){
      if(ST.buf[i]===ST.shown[i]) continue;
      ST.shown[i]=ST.buf[i];
      var v=shownAt(i), c=G.centre(i,pic), sx=VIEW.x+c.x*z, sy=VIEW.y+c.y*z;
      if(hex){
        if(!L.valid[i]) continue;
        var a=P.axialOf(i%pic.w,(i/pic.w)|0,L.orient);
        g.fillStyle=v?viewCss(v):tn[(((a.q-a.r)%3)+3)%3];
        P.hexPath(g,sx,sy,z*1.02,L.orient); g.fill();
        if(ST.showGrid && z>=8){ P.hexPath(g,sx,sy,z,L.orient); g.strokeStyle="rgba(255,255,255,0.07)"; g.lineWidth=1/VIEW.dpr; g.stroke(); }
      } else {
        var x0=VIEW.x+(i%pic.w)*z, y0=VIEW.y+((i/pic.w)|0)*z, cxx=i%pic.w, cyy=(i/pic.w)|0;
        g.fillStyle=((cxx+cyy)&1)?tn[0]:tn[1]; g.fillRect(x0,y0,z,z);
        /* the reference shows through where it lies under an empty pixel, and over everything when on top */
        if(refVisible() && !ST.pic.ref.above && !v) drawRefCell(g,cxx,cyy,x0,y0,z);
        if(v){ g.fillStyle=viewCss(v); g.fillRect(x0,y0,z,z); }
        if(refVisible() && ST.pic.ref.above) drawRefCell(g,cxx,cyy,x0,y0,z);
        if(ST.showGrid && z>=6){ g.strokeStyle="rgba(255,255,255,0.07)"; g.lineWidth=1/VIEW.dpr; g.strokeRect(x0+0.5/VIEW.dpr,y0+0.5/VIEW.dpr,z,z); }
      }
    }
  }
  function liveEdit(){ if(canPartial()) partialDraw(); else { commitLayer(); drawCanvas(); } }
  /* the cursor crosshair and the pixel it will paint, on a layer of its own */
  function drawCursor(){
    var ov=$("pxOver"); if(!ov||!VIEW) return;
    var g=ov.getContext("2d"); g.setTransform(VIEW.dpr,0,0,VIEW.dpr,0,0); g.clearRect(0,0,VIEW.w,VIEW.h);
    if(!ST.cursorAt) return;
    var P=PX(), G=ST.grid, cell=cellFromScreen(ST.cursorAt.x,ST.cursorAt.y), z=VIEW.z;
    if(cell>=0){
      /* v12.4: every pixel the brush will paint */
      var cells=(ST.tool==="pencil"||ST.tool==="eraser"||ST.tool==="dither"||ST.tool==="line")?footprint(cell):[cell];
      g.strokeStyle="#22f0ff"; g.lineWidth=1.5;
      cells.forEach(function(k){ var c=G.centre(k,ST.pic), x=VIEW.x+c.x*z, y=VIEW.y+c.y*z;
        if(G.name==="hex"){ P.hexPath(g,x,y,z,G.layout.orient); g.stroke(); } else g.strokeRect(x-z/2+0.5,y-z/2+0.5,z-1,z-1); });
    }
    drawCrosshair(g,ST.cursorAt);
  }
  function cellFromScreen(sx,sy){ return ST.grid.cellAt((sx-VIEW.x)/VIEW.z, (sy-VIEW.y)/VIEW.z, ST.pic.w, ST.pic.h); }
  /* the hex canvas: every hex drawn as itself; transparent ones in three quiet
     tones, the hex grid's own checkerboard */
  function drawHexCanvas(g){
    var P=PX(), pic=ST.pic, G=ST.grid, L=G.layout, z=VIEW.z, n=pic.w*pic.h;
    var tn=tones();
    for(var i=0;i<n;i++){
      if(!L.valid[i]) continue;
      var x=VIEW.x+L.cx[i]*z, y=VIEW.y+L.cy[i]*z, a=P.axialOf(i%pic.w,(i/pic.w)|0,L.orient);
      g.fillStyle=tn[(((a.q-a.r)%3)+3)%3];
      P.hexPath(g,x,y,z*1.02,L.orient); g.fill();
    }
    if(refVisible() && !ST.pic.ref.above) drawRef(g);
    canvasViews().forEach(function(Lv){
      g.globalAlpha=Lv.alpha;
      for(var j=0;j<n;j++){
        if(!Lv.px[j]||!L.valid[j]) continue;
        g.fillStyle=viewCss(Lv.px[j]); P.hexPath(g,VIEW.x+L.cx[j]*z,VIEW.y+L.cy[j]*z,z*1.02,L.orient); g.fill();
      }
    });
    g.globalAlpha=1;
    if(refVisible() && ST.pic.ref.above) drawRef(g);
    if(ST.showGrid && z>=8){
      g.strokeStyle="rgba(255,255,255,0.07)"; g.lineWidth=1/VIEW.dpr;
      for(var k=0;k<n;k++){ if(!L.valid[k]) continue; P.hexPath(g,VIEW.x+L.cx[k]*z,VIEW.y+L.cy[k]*z,z,L.orient); g.stroke(); }
    }
    drawOverlays(g);
    if(ST.mirror!=="off"){
      var c=G.symCentre, cx=VIEW.x+c.x*z, cy=VIEW.y+c.y*z, B=G.bounds(), rad=Math.max(B.w,B.h)*z;
      g.strokeStyle="rgba(255,122,26,0.7)"; g.setLineDash([4,4]); g.beginPath();
      var spokes=ST.mirror==="k3"?[90,210,330]:ST.mirror==="k6"?[90,150,210,270,330,30]:
        ST.mirror==="kal"?[0,30,60,90,120,150,180,210,240,270,300,330]:[];
      if(ST.mirror==="lr"||ST.mirror==="both"){ g.moveTo(cx,cy-rad); g.lineTo(cx,cy+rad); }
      if(ST.mirror==="tb"||ST.mirror==="both"){ g.moveTo(cx-rad,cy); g.lineTo(cx+rad,cy); }
      spokes.forEach(function(d){ var r=d*Math.PI/180; g.moveTo(cx,cy); g.lineTo(cx+rad*Math.cos(r),cy-rad*Math.sin(r)); });
      g.stroke(); g.setLineDash([]);
    }
    afterFullDraw();
  }
  function drawCrosshair(g,c){
    g.strokeStyle="#ffffff"; g.lineWidth=1.5; g.beginPath();
    g.moveTo(c.x-10,c.y); g.lineTo(c.x-3,c.y); g.moveTo(c.x+3,c.y); g.lineTo(c.x+10,c.y);
    g.moveTo(c.x,c.y-10); g.lineTo(c.x,c.y-3); g.moveTo(c.x,c.y+3); g.lineTo(c.x,c.y+10); g.stroke();
  }

  /* ---- painting ----
     Undo entries remember which layer they belong to, so undoing after
     switching layers restores the right one. */
  function commitLayer(){
    FR().layers[ST.layer].px=PX().encode(ST.buf);
    ST.pic.flat="";
  }
  function layerLocked(){
    var L=FR().layers[ST.layer];
    if(L.locked){ ST.status="This layer is locked"; updateMeta(); return true; }
    if(!L.visible){ ST.status="This layer is hidden"; updateMeta(); return true; }
    return false;
  }
  /* v12.4: alpha lock — a layer so marked can be recoloured only where it
     already has pixels, and nothing on it can be erased */
  function alphaLocked(){ var L=FR().layers[ST.layer]; return !!(L&&L.alphaLock); }
  function canSet(k,v){ return !alphaLocked() || (ST.buf[k] && v); }
  function setCell(i,v){
    if(i<0) return;
    var al=alphaLocked();
    ST.grid.mirror(i,ST.pic.w,ST.pic.h,ST.mirror).forEach(function(k){
      if(k>=0&&k<ST.buf.length&&ST.grid.valid(k)){ if(al && !(ST.buf[k] && v)) return; ST.buf[k]=v; } });
  }
  /* v12.4: the brush. Size 1 is one pixel; larger sizes paint a square or a
     round block of pixels (on hex pixels, rings around the one under the
     finger). Always whole pixels, never soft. */
  var BRUSH_SIZES=[1,2,3,4,6,8];
  function footprint(i){
    var n=ST.size||1; if(n<=1 || i<0) return [i];
    var pic=ST.pic, G=ST.grid;
    if(G.name==="hex"){
      var R=Math.floor(n/2), out=[i], seen={}, ring=[i]; seen[i]=1;
      for(var r=0;r<R;r++){ var nx=[];
        ring.forEach(function(c){ G.neighbours(c,pic.w,pic.h).forEach(function(k){ if(!seen[k]){ seen[k]=1; out.push(k); nx.push(k); } }); });
        ring=nx; }
      return out;
    }
    var w=pic.w, h=pic.h, x=i%w, y=(i/w)|0, lo=-Math.floor((n-1)/2), hi=Math.ceil((n-1)/2), c=(lo+hi)/2;
    var round=ST.brushShape==="round" && n>2, r=(n/2-0.3), r2=r*r, res=[];
    for(var dy=lo;dy<=hi;dy++) for(var dx=lo;dx<=hi;dx++){
      if(round){ var ex=dx-c, ey=dy-c; if(ex*ex+ey*ey>r2) continue; }
      var xx=x+dx, yy=y+dy; if(xx<0||yy<0||xx>=w||yy>=h) continue;
      res.push(yy*w+xx);
    }
    return res;
  }
  function widen(cells){
    if((ST.size||1)<=1) return cells;
    var seen={}, out=[];
    cells.forEach(function(c){ footprint(c).forEach(function(k){ if(!seen[k]){ seen[k]=1; out.push(k); } }); });
    return out;
  }
  /* The dither patterns (v12.4): ordered, from a 4 x 4 Bayer matrix, so every
     coverage is an even spread and neighbouring strokes line up — the
     pattern belongs to the canvas, not to the stroke. */
  var BAYER=[0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5];
  function bayerAt(x,y){ return BAYER[(y&3)*4+(x&3)]; }
  /* the dither brush decides pixel by pixel: in the pattern, the colour; out
     of it, the second colour, or nothing at all */
  function inPattern(k){
    var pic=ST.pic, x=k%pic.w, y=(k/pic.w)|0;
    if(ST.grid.name!=="hex"){
      var p=ST.ditherPat||"50", b=bayerAt(x,y);
      if(p==="25") return b<4;
      if(p==="75") return b<12;
      if(p==="hatch") return ((x+y)&3)===0;
      return b<8;
    }
    var a=PX().axialOf(x,y,pic.orient||"pointy"), cls=(((a.q-a.r)%3)+3)%3;
    if(ST.hexPattern==="rows") return (((pic.orient==="flat")?x:y)&1)===0;
    if(ST.hexPattern==="twothirds") return cls!==0;
    return cls===0;
  }
  function paint(i){
    if(i<0) return;
    footprint(i).forEach(paintOne);
  }
  function paintOne(i){
    if(i<0) return;
    if(ST.tool==="eraser"){ setCell(i,0); return; }
    if(ST.tool==="dither"){
      ST.grid.mirror(i,ST.pic.w,ST.pic.h,ST.mirror).forEach(function(k){
        if(k<0||k>=ST.buf.length||!ST.grid.valid(k)) return;
        if(inPattern(k)){ if(canSet(k,ST.colour)) ST.buf[k]=ST.colour; }
        else if(ST.ditherMode==="two"){ var v2=ST.colour2||0; if(canSet(k,v2)) ST.buf[k]=v2; }
      });
      return;
    }
    setCell(i,ST.colour);
  }
  /* the pixels joined to this one that share its colour, on the working layer */
  function regionOf(start, buf){
    var from=buf[start], w=ST.pic.w, h=ST.pic.h, stack=[start], seen=new Uint8Array(buf.length), out=[];
    while(stack.length){
      var i=stack.pop(); if(seen[i]) continue; seen[i]=1;
      if(buf[i]!==from || !ST.grid.valid(i)) continue;
      out.push(i);
      ST.grid.neighbours(i,w,h).forEach(function(n){ if(!seen[n]) stack.push(n); });
    }
    return out;
  }
  /* The dither gradient (v12.4): drag across an area and it fades from the
     second colour (or what is there) at the start to the chosen colour at
     the end, in the ordered pattern. It fills the area you start in —
     the joined pixels of that colour, as Fill would. */
  function applyGradient(g, endCell){
    var G=ST.grid, pic=ST.pic, A=G.centre(g.start,pic), B=G.centre(endCell<0?g.start:endCell,pic);
    var dx=B.x-A.x, dy=B.y-A.y, L2=dx*dx+dy*dy;
    ST.buf=g.base.slice();
    g.region.forEach(function(k){
      var c=G.centre(k,pic), t=L2?Math.max(0,Math.min(1,((c.x-A.x)*dx+(c.y-A.y)*dy)/L2)):1;
      var on=bayerAt(k%pic.w,(k/pic.w)|0) < t*16;
      if(on){ if(canSet(k,ST.colour)) ST.buf[k]=ST.colour; }
      else if(ST.ditherMode==="two"){ var v2=ST.colour2||0; if(canSet(k,v2)) ST.buf[k]=v2; }
    });
  }
  function pushUndo(){ ST.undo.push({frame:ST.frame||0, layer:ST.layer, buf:ST.buf.slice()}); if(ST.undo.length>100) ST.undo.shift(); ST.redo=[]; }
  function useColour(i){
    ST.recent=[i].concat(ST.recent.filter(function(x){ return x!==i; })).slice(0,10);
  }
  function flood(start, v){
    var from=ST.buf[start]; if(from===v) return;
    var w=ST.pic.w, h=ST.pic.h, stack=[start], seen=new Uint8Array(ST.buf.length);
    while(stack.length){
      var i=stack.pop(); if(seen[i]) continue; seen[i]=1;
      if(ST.buf[i]!==from) continue;
      setCell(i,v);
      ST.grid.neighbours(i,w,h).forEach(function(n){ if(!seen[n]) stack.push(n); });
    }
  }
  function pickAt(i){
    if(i<0) return;
    var flat=PX().flatten(ST.pic,0), v=flat[i];
    if(v){ ST.colour=v; useColour(v); }
    ST.tool="pencil"; renderTools(); renderPalette();
  }

  /* ---- shapes: worked out from cell centres, so squares and hexes alike ---- */
  function shapeCells(a,b,kind){
    var G=ST.grid, pic=ST.pic, n=pic.w*pic.h;
    if(kind==="line") return G.line(a,b,pic.w,pic.h);
    var A=G.centre(a,pic), B=G.centre(b,pic);
    var minx=Math.min(A.x,B.x), maxx=Math.max(A.x,B.x), miny=Math.min(A.y,B.y), maxy=Math.max(A.y,B.y);
    var pad=G.name==="hex"?0.9:0.5, e=0.01, mark=new Uint8Array(n);
    var cx=(minx+maxx)/2, cy=(miny+maxy)/2, rx=(maxx-minx)/2+pad, ry=(maxy-miny)/2+pad;
    for(var i=0;i<n;i++){
      if(!G.valid(i)) continue;
      var c=G.centre(i,pic);
      if(kind==="rect") mark[i]=(c.x>=minx-e&&c.x<=maxx+e&&c.y>=miny-e&&c.y<=maxy+e)?1:0;
      else { var dx=(c.x-cx)/rx, dy=(c.y-cy)/ry; mark[i]=(dx*dx+dy*dy<=1)?1:0; }
    }
    var out=[];
    for(var j=0;j<n;j++){
      if(!mark[j]) continue;
      if(ST.shapeFill){ out.push(j); continue; }
      var nb=G.neighbours(j,pic.w,pic.h), full=G.name==="hex"?6:4;
      if(nb.length<full || nb.some(function(k){ return !mark[k]; })) out.push(j);
    }
    return out;
  }

  /* ---- selection: lifted pixels float until Done, and move as a block ---- */
  function selItemsAt(cells){
    var G=ST.grid, pic=ST.pic, items=[];
    cells.forEach(function(i){ var v=ST.buf[i]; if(v){ var c=G.centre(i,pic); items.push({x:c.x,y:c.y,v:v}); ST.buf[i]=0; } });
    return items;
  }
  function selBounds(items){
    var b={minx:1e9,miny:1e9,maxx:-1e9,maxy:-1e9};
    items.forEach(function(t){ b.minx=Math.min(b.minx,t.x); b.maxx=Math.max(b.maxx,t.x); b.miny=Math.min(b.miny,t.y); b.maxy=Math.max(b.maxy,t.y); });
    return b;
  }
  /* back onto the grid: every position to the hex or square it lies in */
  function snapItems(items){
    var G=ST.grid, pic=ST.pic;
    return items.map(function(t){ var k=G.cellAt(t.x,t.y,pic.w,pic.h); if(k<0) return null; var c=G.centre(k,pic); return {x:c.x,y:c.y,v:t.v}; }).filter(Boolean);
  }
  /* lift these cells into a floating selection (v12.4: by colour, or all) */
  function liftCells(cells){
    if(!cells.length){ ST.status="Nothing to select"; updateMeta(); return; }
    pushUndo();
    var items=selItemsAt(cells);
    ST.sel=items.length?{items:items, dx:0, dy:0}:null;
    if(!items.length) ST.undo.pop();
    commitLayer(); drawCanvas(); renderOpts();
    ST.status="Selected "+items.length+" pixel"+(items.length===1?"":"s"); updateMeta();
  }
  /* Nudge (v12.4): one pixel at a time. With nothing selected, the whole
     layer moves. On hex pixels it steps to the neighbour lying most nearly
     that way. */
  function nudge(dir){
    var G=ST.grid, pic=ST.pic, whole=false;
    if(!ST.sel){
      if(layerLocked()) return;
      var cells=[]; for(var k=0;k<ST.buf.length;k++) if(ST.buf[k]) cells.push(k);
      if(!cells.length) return;
      pushUndo(); ST.sel={items:selItemsAt(cells), dx:0, dy:0}; whole=true;
    }
    var S=ST.sel, a=S.items[0]; if(!a) return;
    var want={l:[-1,0],r:[1,0],u:[0,-1],d:[0,1]}[dir];
    if(G.name!=="hex"){ S.dx+=want[0]; S.dy+=want[1]; }
    else {
      var at=G.cellAt(a.x+S.dx,a.y+S.dy,pic.w,pic.h); if(at<0) return;
      var c0=G.centre(at,pic), best=null, bd=-1e9;
      G.neighbours(at,pic.w,pic.h).forEach(function(n){ var c=G.centre(n,pic), ox=c.x-c0.x, oy=c.y-c0.y, L=Math.hypot(ox,oy)||1, d=(ox*want[0]+oy*want[1])/L; if(d>bd){ bd=d; best=c; } });
      if(best && bd>0.4){ S.dx+=best.x-c0.x; S.dy+=best.y-c0.y; }
    }
    if(whole){ commitSelection(); ST.status="Layer moved"; updateMeta(); }
    else drawCanvas();
  }
  function commitSelection(){
    var S=ST.sel; if(!S) return;
    var G=ST.grid, pic=ST.pic;
    S.items.forEach(function(t){ var k=G.cellAt(t.x+S.dx,t.y+S.dy,pic.w,pic.h); if(k>=0&&G.valid(k)) ST.buf[k]=t.v; });
    ST.sel=null; afterEdit(); renderOpts();
  }
  function selAction(a){
    var S=ST.sel;
    if(a==="all"){
      if(S) commitSelection();
      var all=[]; for(var k=0;k<ST.buf.length;k++) if(ST.buf[k]) all.push(k);
      liftCells(all); return;
    }
    if(/^nudge-/.test(a)){ nudge(a.slice(6)); return; }
    if(a==="paste"){
      if(!ST.clip) return;
      if(S) commitSelection();
      pushUndo(); ST.sel={items:ST.clip.map(function(t){ return {x:t.x,y:t.y,v:t.v}; }), dx:0, dy:0};
      drawCanvas(); renderOpts(); return;
    }
    if(!S) return;
    var b=selBounds(S.items), cx=(b.minx+b.maxx)/2, cy=(b.miny+b.maxy)/2;
    if(a==="fliph") S.items=snapItems(S.items.map(function(t){ return {x:2*cx-t.x,y:t.y,v:t.v}; }));
    if(a==="flipv") S.items=snapItems(S.items.map(function(t){ return {x:t.x,y:2*cy-t.y,v:t.v}; }));
    if(a==="rotate" && ST.grid.name!=="hex") S.items=snapItems(S.items.map(function(t){ return {x:cx-(t.y-cy),y:cy+(t.x-cx),v:t.v}; }));
    if(a==="x2"||a==="half"||a==="pct"){
      var f=a==="x2"?2:a==="half"?0.5:Math.max(10,Math.min(800,parseFloat(($("pxScalePct")||{}).value)||100))/100;
      if(a==="pct") ST.scalePct=Math.round(f*100);
      scaleSel(f); return;
    }
    if(a==="copy"){ ST.clip=S.items.map(function(t){ return {x:t.x+S.dx,y:t.y+S.dy,v:t.v}; }); ST.status="Copied "+ST.clip.length+" pixels"; updateMeta(); }
    if(a==="delete"){ ST.sel=null; afterEdit(); renderOpts(); return; }
    if(a==="done"){ commitSelection(); return; }
    drawCanvas(); renderOpts();
  }
  /* Scaling a selection (v12.5), square pixels only. Larger: each pixel becomes
     a block. Smaller: each new pixel takes the colour most of its block has,
     or stays empty if most of it was. It keeps its centre. */
  function scaleSel(f){
    var S=ST.sel; if(!S || !S.items.length || ST.grid.name==="hex") return;
    var x0=1e9,y0=1e9,x1=-1e9,y1=-1e9;
    S.items.forEach(function(t){ var x=Math.floor(t.x), y=Math.floor(t.y); if(x<x0)x0=x; if(y<y0)y0=y; if(x>x1)x1=x; if(y>y1)y1=y; });
    var w0=x1-x0+1, h0=y1-y0+1, W=Math.max(1,Math.round(w0*f)), H=Math.max(1,Math.round(h0*f));
    if(W*H>1048576){ ST.status="That would be too large"; updateMeta(); return; }
    var src=new Uint8Array(w0*h0); S.items.forEach(function(t){ src[(Math.floor(t.y)-y0)*w0+(Math.floor(t.x)-x0)]=t.v; });
    var nx=Math.round(x0+(w0-W)/2), ny=Math.round(y0+(h0-H)/2), items=[];
    for(var ty=0;ty<H;ty++) for(var tx=0;tx<W;tx++){
      var v=0;
      if(f>=1) v=src[Math.min(h0-1,Math.floor(ty*h0/H))*w0+Math.min(w0-1,Math.floor(tx*w0/W))];
      else {
        var sx0=Math.floor(tx*w0/W), sx1=Math.max(sx0+1,Math.floor((tx+1)*w0/W)), sy0=Math.floor(ty*h0/H), sy1=Math.max(sy0+1,Math.floor((ty+1)*h0/H));
        var cnt={}, tot=0, best=0, bn=0;
        for(var yy=sy0;yy<sy1&&yy<h0;yy++) for(var xx=sx0;xx<sx1&&xx<w0;xx++){ var q=src[yy*w0+xx]; tot++; cnt[q]=(cnt[q]||0)+1; }
        Object.keys(cnt).forEach(function(k){ if(+k && cnt[k]>bn){ bn=cnt[k]; best=+k; } });
        v=(bn*2>=tot || bn>=(cnt[0]||0))?best:0;
      }
      if(v) items.push({x:nx+tx+0.5, y:ny+ty+0.5, v:v});
    }
    S.items=items;
    ST.status="Scaled to "+W+"\u00d7"+H; updateMeta(); drawCanvas(); renderOpts();
  }
  /* ---- text (v12.5): two small pixel fonts, placed as a selection ---- */
  var FONTS={
    small:{h:5, sp:2, g:{
      A:".#.|#.#|###|#.#|#.#", B:"##.|#.#|##.|#.#|##.", C:".##|#..|#..|#..|.##", D:"##.|#.#|#.#|#.#|##.", E:"###|#..|##.|#..|###",
      F:"###|#..|##.|#..|#..", G:".##|#..|#.#|#.#|.##", H:"#.#|#.#|###|#.#|#.#", I:"###|.#.|.#.|.#.|###", J:"..#|..#|..#|#.#|.#.",
      K:"#.#|##.|#..|##.|#.#", L:"#..|#..|#..|#..|###", M:"#.#|###|###|#.#|#.#", N:"##.|#.#|#.#|#.#|#.#", O:".#.|#.#|#.#|#.#|.#.",
      P:"##.|#.#|##.|#..|#..", Q:".#.|#.#|#.#|##.|.##", R:"##.|#.#|##.|#.#|#.#", S:".##|#..|.#.|..#|##.", T:"###|.#.|.#.|.#.|.#.",
      U:"#.#|#.#|#.#|#.#|###", V:"#.#|#.#|#.#|#.#|.#.", W:"#.#|#.#|###|###|#.#", X:"#.#|#.#|.#.|#.#|#.#", Y:"#.#|#.#|.#.|.#.|.#.",
      Z:"###|..#|.#.|#..|###", "0":"###|#.#|#.#|#.#|###", "1":".#.|##.|.#.|.#.|###", "2":"##.|..#|.#.|#..|###", "3":"##.|..#|.#.|..#|##.",
      "4":"#.#|#.#|###|..#|..#", "5":"###|#..|##.|..#|##.", "6":".##|#..|###|#.#|###", "7":"###|..#|.#.|.#.|.#.", "8":"###|#.#|###|#.#|###",
      "9":"###|#.#|###|..#|##.", ".":".|.|.|.|#", ",":".|.|.|#|#", "!":"#|#|#|.|#", "?":"##.|..#|.#.|...|.#.", ":":".|#|.|#|.", ";":".|#|.|#|#",
      "-":"...|...|###|...|...", "+":"...|.#.|###|.#.|...", "=":"...|###|...|###|...", "/":"..#|..#|.#.|#..|#..", "'":"#|#|.|.|.", "\"":"#.#|#.#|...|...|...",
      "(":".#|#.|#.|#.|.#", ")":"#.|.#|.#|.#|#.", "%":"#.#|..#|.#.|#..|#.#", "*":"#.#|.#.|#.#|...|...", "#":"#.#|###|#.#|###|#.#", "&":".#.|#.#|.#.|#.#|.##"}},
    large:{h:7, sp:3, g:{
      A:".###.|#...#|#...#|#####|#...#|#...#|#...#", B:"####.|#...#|#...#|####.|#...#|#...#|####.", C:".###.|#...#|#....|#....|#....|#...#|.###.",
      D:"###..|#..#.|#...#|#...#|#...#|#..#.|###..", E:"#####|#....|#....|####.|#....|#....|#####", F:"#####|#....|#....|####.|#....|#....|#....",
      G:".###.|#...#|#....|#.###|#...#|#...#|.####", H:"#...#|#...#|#...#|#####|#...#|#...#|#...#", I:".###.|..#..|..#..|..#..|..#..|..#..|.###.",
      J:"..###|...#.|...#.|...#.|...#.|#..#.|.##..", K:"#...#|#..#.|#.#..|##...|#.#..|#..#.|#...#", L:"#....|#....|#....|#....|#....|#....|#####",
      M:"#...#|##.##|#.#.#|#.#.#|#...#|#...#|#...#", N:"#...#|#...#|##..#|#.#.#|#..##|#...#|#...#", O:".###.|#...#|#...#|#...#|#...#|#...#|.###.",
      P:"####.|#...#|#...#|####.|#....|#....|#....", Q:".###.|#...#|#...#|#...#|#.#.#|#..#.|.##.#", R:"####.|#...#|#...#|####.|#.#..|#..#.|#...#",
      S:".####|#....|#....|.###.|....#|....#|####.", T:"#####|..#..|..#..|..#..|..#..|..#..|..#..", U:"#...#|#...#|#...#|#...#|#...#|#...#|.###.",
      V:"#...#|#...#|#...#|#...#|#...#|.#.#.|..#..", W:"#...#|#...#|#...#|#.#.#|#.#.#|#.#.#|.#.#.", X:"#...#|#...#|.#.#.|..#..|.#.#.|#...#|#...#",
      Y:"#...#|#...#|.#.#.|..#..|..#..|..#..|..#..", Z:"#####|....#|...#.|..#..|.#...|#....|#####",
      "0":".###.|#...#|#..##|#.#.#|##..#|#...#|.###.", "1":"..#..|.##..|..#..|..#..|..#..|..#..|.###.", "2":".###.|#...#|....#|...#.|..#..|.#...|#####",
      "3":"#####|...#.|..#..|...#.|....#|#...#|.###.", "4":"...#.|..##.|.#.#.|#..#.|#####|...#.|...#.", "5":"#####|#....|####.|....#|....#|#...#|.###.",
      "6":"..##.|.#...|#....|####.|#...#|#...#|.###.", "7":"#####|....#|...#.|..#..|.#...|.#...|.#...", "8":".###.|#...#|#...#|.###.|#...#|#...#|.###.",
      "9":".###.|#...#|#...#|.####|....#|...#.|.##..", ".":"..|..|..|..|..|##|##", ",":"..|..|..|..|##|.#|#.", "!":"#|#|#|#|#|.|#",
      "?":".###.|#...#|....#|...#.|..#..|.....|..#..", ":":"..|##|##|..|##|##|..", ";":"..|##|##|..|##|.#|#.",
      "-":".....|.....|.....|#####|.....|.....|.....", "+":".....|..#..|..#..|#####|..#..|..#..|.....", "=":".....|.....|#####|.....|#####|.....|.....",
      "/":"....#|....#|...#.|..#..|.#...|#....|#....", "'":"##|.#|#.|..|..|..|..", "\"":"#.#|#.#|#.#|...|...|...|...",
      "(":"..#|.#.|#..|#..|#..|.#.|..#", ")":"#..|.#.|..#|..#|..#|.#.|#..", "%":"##...|##..#|...#.|..#..|.#...|#..##|...##",
      "*":".....|..#..|#.#.#|.###.|#.#.#|..#..|.....", "#":".#.#.|.#.#.|#####|.#.#.|#####|.#.#.|.#.#.", "&":".##..|#..#.|#.#..|.#...|#.#.#|#..#.|.##.#"}}
  };
  /* the pixels of some text: lines centred on the widest */
  function textCells(str, font, spacing){
    var F=FONTS[font]||FONTS.small, sp=spacing==null?1:spacing, lines=String(str||"").toUpperCase().split(/\r?\n/), rows=[], W=0;
    lines.forEach(function(line){
      var cells=[], x=0, first=true;
      for(var k=0;k<line.length;k++){
        var ch=line[k], g=F.g[ch];
        if(!first) x+=sp; first=false;
        if(!g){ x+=F.sp; continue; }
        var rr=g.split("|");
        rr.forEach(function(r,y){ for(var c=0;c<r.length;c++) if(r[c]==="#") cells.push([x+c,y]); });
        x+=rr[0].length;
      }
      rows.push({w:x, cells:cells}); if(x>W) W=x;
    });
    var out=[], lh=F.h+Math.max(1,sp);
    rows.forEach(function(r,li){ var ox=Math.floor((W-r.w)/2); r.cells.forEach(function(c){ out.push([c[0]+ox, c[1]+li*lh]); }); });
    return {w:W, h:rows.length?rows.length*lh-Math.max(1,sp):0, cells:out};
  }
  function placeText(){
    var T=textCells(ST.text, ST.font, ST.tspace);
    if(!T.cells.length){ ST.status="Type something first"; updateMeta(); return; }
    if(layerLocked()) return;
    if(ST.sel) commitSelection();
    pushUndo();
    var ox=Math.floor((ST.pic.w-T.w)/2), oy=Math.floor((ST.pic.h-T.h)/2);
    ST.sel={items:T.cells.map(function(c){ return {x:ox+c[0]+0.5, y:oy+c[1]+0.5, v:ST.colour}; }), dx:0, dy:0};
    useColour(ST.colour);
    ST.tool="select"; ST.selMode="box";
    ST.status="Text "+T.w+"\u00d7"+T.h+" \u2014 drag it into place, then Done"+(T.w>ST.pic.w?" (wider than the picture)":"");
    renderTools(); renderOpts(); drawCanvas(); updateMeta();
  }
  function insideSel(ux,uy){
    var S=ST.sel; if(!S||!S.items.length) return false;
    var b=selBounds(S.items), pad=ST.grid.name==="hex"?1:0.5;
    return ux>=b.minx+S.dx-pad&&ux<=b.maxx+S.dx+pad&&uy>=b.miny+S.dy-pad&&uy<=b.maxy+S.dy+pad;
  }

  var stroke=null;
  function shapeFor(a,b,kind){ var cells=shapeCells(a,b,kind); return kind==="line"?widen(cells):cells; }
  function toolDown(sx,sy){
    var i=cellFromScreen(sx,sy), ux=(sx-VIEW.x)/VIEW.z, uy=(sy-VIEW.y)/VIEW.z;
    stroke={last:i, first:i, start:{x:sx,y:sy}, moved:false, at:Date.now()};
    /* v12.5: taking a colour from the reference */
    if(ST.refPick){
      stroke=null; ST.refPick=false;
      var hx=sampleRef(ux,uy);
      if(hx){ var c=[parseInt(hx.substr(1,2),16),parseInt(hx.substr(3,2),16),parseInt(hx.substr(5,2),16)]; ST.found={hex:hx, near:PX().nearest(c[0],c[1],c[2])}; ST.status="Found "+hx; }
      else ST.status="No reference picture there";
      updateMeta(); renderPalette(); return;
    }
    /* v12.4: moving the reference picture, when that is switched on */
    if(ST.refMove && ST.pic.ref){ stroke.refDrag={ux:ux, uy:uy, x0:ST.pic.ref.x, y0:ST.pic.ref.y}; return; }
    if(ST.tool==="pick"){ pickAt(i); stroke=null; return; }
    if(ST.tool==="select"){
      if(ST.sel && insideSel(ux,uy)){ stroke.moving={dx:ST.sel.dx, dy:ST.sel.dy, ux:ux, uy:uy}; return; }
      if(ST.sel) commitSelection();
      /* v12.4: select by colour — the joined patch, or all of it on the layer */
      if(ST.selMode!=="box"){
        stroke=null;
        if(i<0) return;
        var v=ST.buf[i];
        if(!v){ ST.status="That pixel is empty on this layer"; updateMeta(); return; }
        var cells=ST.selMode==="wand"?regionOf(i,ST.buf):(function(){ var o=[]; for(var k=0;k<ST.buf.length;k++) if(ST.buf[k]===v) o.push(k); return o; })();
        liftCells(cells); return;
      }
      stroke.selecting=true; ST.selRect={a:i,b:i}; drawCanvas(); return;
    }
    if(i<0) return;
    if(layerLocked()){ stroke=null; return; }
    if(ST.tool==="eraser" && alphaLocked()){ ST.status="Alpha lock is on: this layer can be recoloured, not erased"; updateMeta(); stroke=null; return; }
    if(ST.tool==="fill"){ pushUndo(); flood(i,ST.colour); useColour(ST.colour); afterEdit(); stroke=null; return; }
    if(ST.tool==="dither" && ST.ditherPat==="grad" && ST.grid.name!=="hex"){
      pushUndo(); stroke.grad={start:i, base:ST.buf.slice(), region:regionOf(i,ST.buf)}; useColour(ST.colour);
      applyGradient(stroke.grad,i); liveEdit(); return;
    }
    if(ST.tool==="line"||ST.tool==="rect"||ST.tool==="circle"){
      pushUndo(); stroke.shape=ST.tool; stroke.base=ST.buf.slice(); useColour(ST.colour);
      shapeFor(i,i,stroke.shape).forEach(function(k){ setCell(k,ST.colour); }); liveEdit(); return;
    }
    pushUndo(); stroke.painted=true;
    paint(i);
    if(ST.tool!=="eraser") useColour(ST.colour);
    liveEdit();
  }
  function toolMove(sx,sy){
    if(!stroke) return;
    if(Math.abs(sx-stroke.start.x)+Math.abs(sy-stroke.start.y)>6) stroke.moved=true;
    var i=cellFromScreen(sx,sy), ux=(sx-VIEW.x)/VIEW.z, uy=(sy-VIEW.y)/VIEW.z;
    if(stroke.refDrag){ var R=ST.pic.ref; R.x=stroke.refDrag.x0+(ux-stroke.refDrag.ux); R.y=stroke.refDrag.y0+(uy-stroke.refDrag.uy); drawCanvas(); return; }
    if(stroke.grad){ if(i>=0){ applyGradient(stroke.grad,i); stroke.last=i; liveEdit(); } return; }
    if(stroke.moving){
      /* the block moves by whole cells, so it lands on the grid unchanged */
      var S=ST.sel, a=S.items[0]; if(!a) return;
      var k=ST.grid.cellAt(a.x+stroke.moving.dx+(ux-stroke.moving.ux), a.y+stroke.moving.dy+(uy-stroke.moving.uy), ST.pic.w, ST.pic.h);
      if(k>=0){ var c=ST.grid.centre(k,ST.pic); S.dx=c.x-a.x; S.dy=c.y-a.y; drawCanvas(); }
      return;
    }
    if(stroke.selecting){ if(i>=0){ ST.selRect.b=i; drawCanvas(); } return; }
    if(stroke.shape){
      if(i<0) return;
      ST.buf=stroke.base.slice();
      shapeFor(stroke.first,i,stroke.shape).forEach(function(k){ setCell(k,ST.colour); });
      stroke.last=i; liveEdit(); return;
    }
    if(i<0 || i===stroke.last || !stroke.painted) { if(i>=0) stroke.last=i; return; }
    (stroke.last>=0?ST.grid.line(stroke.last,i,ST.pic.w,ST.pic.h):[i]).forEach(paint);
    stroke.last=i; liveEdit();
  }
  function toolUp(){
    if(stroke && stroke.refDrag){ stroke=null; scheduleSave(); return; }
    if(stroke && stroke.grad){ commitLayer(); afterEdit(); stroke=null; return; }
    if(stroke && stroke.selecting && ST.selRect){
      var r=ST.selRect; ST.selRect=null;
      if(r.a>=0 && r.b>=0){
        pushUndo();
        var was=ST.shapeFill; ST.shapeFill=true; var cells=shapeCells(r.a,r.b,"rect"); ST.shapeFill=was;
        var items=selItemsAt(cells);
        ST.sel=items.length?{items:items, dx:0, dy:0}:null;
        if(!items.length) ST.undo.pop();
        commitLayer(); drawCanvas(); renderOpts();
      }
    } else if(stroke && (stroke.painted||stroke.shape)){ commitLayer(); afterEdit(); }
    stroke=null;
  }
  /* a long press picks the colour under it, whatever the tool */
  function longPress(sx,sy){
    if(!stroke || stroke.moved || stroke.selecting || stroke.moving || stroke.refDrag || stroke.grad) return;
    if((stroke.painted||stroke.shape) && ST.undo.length){ var u=ST.undo.pop(); ST.buf=u.buf; commitLayer(); }
    pickAt(cellFromScreen(sx,sy)); stroke=null; drawCanvas(); updateMeta();
  }
  function afterEdit(during){
    commitLayer(); drawCanvas();
    if(!during){ updateMeta(); renderPaletteCur(); scheduleSave(); }
  }
  /* the recent colours follow what you draw with, palette open or not */
  function renderPaletteCur(){ renderPalette(); }
  function switchLayer(i){
    commitLayer(); ST.layer=i;
    ST.buf=PX().decode(FR().layers[i].px, ST.pic.w*ST.pic.h);
  }
  function undo(){
    if(ST.sel){ ST.sel=null; renderOpts(); }
    if(!ST.undo.length) return;
    var u=ST.undo.pop();
    if(u.frames){ ST.redo.push(layersNow()); restoreLayers(u); afterEdit(); renderLayers(); renderFrames(); return; }
    if((u.frame||0)!==(ST.frame||0)) switchFrame(u.frame||0);
    if(u.layer!==ST.layer) switchLayer(u.layer);
    ST.redo.push({frame:ST.frame||0, layer:ST.layer, buf:ST.buf.slice()}); ST.buf=u.buf; afterEdit(); renderLayers(); renderFrames();
  }
  function redo(){
    if(!ST.redo.length) return;
    var u=ST.redo.pop();
    if(u.frames){ ST.undo.push(layersNow()); restoreLayers(u); afterEdit(); renderLayers(); renderFrames(); return; }
    if((u.frame||0)!==(ST.frame||0)) switchFrame(u.frame||0);
    if(u.layer!==ST.layer) switchLayer(u.layer);
    ST.undo.push({frame:ST.frame||0, layer:ST.layer, buf:ST.buf.slice()}); ST.buf=u.buf; afterEdit(); renderLayers(); renderFrames();
  }

  /* ---- what the canvas shows: every visible layer in turn, at its opacity
     while you work. The saved picture follows each layer's mode. ---- */
  function layerViews(){
    var P=PX(), pic=ST.pic, n=pic.w*pic.h, out=[];
    FR().layers.forEach(function(L,li){
      if(!L.visible) return;
      if(ST.solo!=null && ST.solo!==li) return;
      var px=(li===ST.layer)?ST.buf:P.decode(L.px,n), op=Math.max(0,Math.min(100,+L.opacity||0))/100, mode=L.mode||"view";
      if(mode==="dither" && op<0.999){
        var t={w:pic.w,h:pic.h,grid:pic.grid,orient:pic.orient,shape:pic.shape,side:pic.side,
               frames:[{layers:[{visible:true,opacity:L.opacity,mode:"dither",px:P.encode(px)}]}]};
        px=P.flatten(t,0); op=1;
      }
      out.push({px:px, alpha:op});
    });
    return out;
  }
  function drawOverlays(g){
    var P=PX(), G=ST.grid, pic=ST.pic, z=VIEW.z;
    var cellShape=function(k,fill){
      var c=G.centre(k,pic), x=VIEW.x+c.x*z, y=VIEW.y+c.y*z;
      if(G.name==="hex"){ P.hexPath(g,x,y,z*(fill?1.02:1),G.layout.orient); }
      else { g.beginPath(); g.rect(x-z/2,y-z/2,z,z); }
    };
    if(ST.selRect){
      var was=ST.shapeFill; ST.shapeFill=true; var cells=shapeCells(ST.selRect.a,ST.selRect.b,"rect"); ST.shapeFill=was;
      g.fillStyle="rgba(34,240,255,0.14)"; cells.forEach(function(k){ cellShape(k,true); g.fill(); });
    }
    if(ST.sel){
      var S=ST.sel;
      S.items.forEach(function(t){
        var k=G.cellAt(t.x+S.dx,t.y+S.dy,pic.w,pic.h); if(k<0) return;
        g.fillStyle=viewCss(t.v); cellShape(k,true); g.fill();
      });
      if(S.items.length){
        var b=selBounds(S.items), pad=(G.name==="hex"?1:0.5)*z;
        g.strokeStyle="#22f0ff"; g.setLineDash([5,4]); g.lineWidth=1.5;
        g.strokeRect(VIEW.x+(b.minx+S.dx)*z-pad, VIEW.y+(b.miny+S.dy)*z-pad, (b.maxx-b.minx)*z+2*pad, (b.maxy-b.miny)*z+2*pad);
        g.setLineDash([]);
      }
    }
  }

  /* ---- the reference picture (v12.4) ----
     A picture to draw from, shown under or over your pixels and never part of
     them: it is never exported, and never counts as a colour. It is kept with
     the drawing, in the browser's larger database rather than the picture
     library, scaled down to 1024 pixels on its longest side on the way in. */
  var REFDB=null;
  function refDb(cb){
    if(REFDB) return cb(REFDB);
    if(!window.indexedDB) return cb(null);
    try{
      var rq=indexedDB.open("keter-refs",1);
      rq.onupgradeneeded=function(){ rq.result.createObjectStore("refs"); };
      rq.onsuccess=function(){ REFDB=rq.result; cb(REFDB); };
      rq.onerror=function(){ cb(null); };
    }catch(e){ cb(null); }
  }
  function refPut(id,data,cb){ refDb(function(db){ if(!db) return cb&&cb(false); var tx=db.transaction("refs","readwrite"); tx.objectStore("refs").put(data,id); tx.oncomplete=function(){ cb&&cb(true); }; tx.onerror=function(){ cb&&cb(false); }; }); }
  function refGet(id,cb){ refDb(function(db){ if(!db) return cb(null); var rq=db.transaction("refs","readonly").objectStore("refs").get(id); rq.onsuccess=function(){ cb(rq.result||null); }; rq.onerror=function(){ cb(null); }; }); }
  function refDel(id){ refDb(function(db){ if(!db) return; db.transaction("refs","readwrite").objectStore("refs").delete(id); }); }
  function refCopy(from,to){ refGet(from,function(d){ if(d) refPut(to,d); }); }
  function refVisible(){ return !!(ST && ST.refImg && ST.pic.ref && !ST.pic.ref.hidden); }
  function loadRef(id){
    refGet(id,function(data){
      if(!data || !ST || ST.id!==id) return;
      var img=new Image(); img.onload=function(){ if(!ST||ST.id!==id) return; ST.refImg=img; renderTools(); renderRef(); drawCanvas(); }; img.src=data;
    });
  }
  /* from a file, or (for the checks) a data URL */
  function useRefData(data){
    var img=new Image();
    img.onload=function(){
      var M=1024, k=Math.min(1,M/Math.max(img.width,img.height));
      var c=document.createElement("canvas"); c.width=Math.max(1,Math.round(img.width*k)); c.height=Math.max(1,Math.round(img.height*k));
      c.getContext("2d").drawImage(img,0,0,c.width,c.height);
      var small=c.toDataURL("image/jpeg",0.9);
      flushSave(); if(!ST || !ST.id) return;
      var B=ST.grid.bounds(ST.pic), sc=Math.min(B.w/c.width, B.h/c.height);
      ST.pic.ref={x:B.minx+(B.w-c.width*sc)/2, y:B.miny+(B.h-c.height*sc)/2, s:sc, fit:sc, op:ST.pic.ref?ST.pic.ref.op:50, above:false, hidden:false};
      var id=ST.id;
      refPut(id, small, function(ok){
        if(!ok){ ST.status="The reference could not be kept on this device"; updateMeta(); }
        var im=new Image(); im.onload=function(){ if(!ST||ST.id!==id) return; ST.refImg=im; ST.refPanel=true; renderTools(); renderRef(); drawCanvas(); scheduleSave(); }; im.src=small;
      });
    };
    img.src=data;
  }
  function pickRefFile(){
    var inp=document.createElement("input"); inp.type="file"; inp.accept="image/*";
    inp.onchange=function(){ var f=inp.files&&inp.files[0]; if(!f) return; var rd=new FileReader(); rd.onload=function(){ useRefData(rd.result); }; rd.readAsDataURL(f); };
    inp.click();
  }
  function renderRef(){
    var host=$("pxRef"); if(!host||!ST) return;
    if(!ST.refPanel){ host.style.display="none"; host.innerHTML=""; return; }
    var R=ST.pic.ref, has=!!(R&&ST.refImg);
    host.style.display="";
    host.innerHTML=has?
      '<button class="ghost'+(R.hidden?"":" primary")+'" id="pxRefShow">'+(R.hidden?"Show":"Hide")+'</button>'+
      '<div class="seg pxseg"><button class="'+(R.above?"":"on")+'" data-pxrefpos="below">Under the art</button><button class="'+(R.above?"on":"")+'" data-pxrefpos="above">Over the art</button></div>'+
      '<button class="ghost'+(ST.refMove?" primary":"")+'" id="pxRefMove">'+(ST.refMove?"Moving \u2014 drag it":"Move")+'</button>'+
      '<button class="ghost" id="pxRefFit">Fit</button>'+
      '<label class="pxrange">Opacity <input type="range" id="pxRefOp" min="10" max="100" step="5" value="'+(R.op||50)+'"></label>'+
      '<label class="pxrange">Size <input type="range" id="pxRefSize" min="10" max="400" step="5" value="'+Math.round(100*R.s/(R.fit||R.s||1))+'"></label>'+
      '<button class="ghost" id="pxRefLoad">Replace</button><button class="ghost" id="pxRefDel">Remove</button>'+
      '<span class="pxhint">A picture to draw from. It is never exported and never part of your pixels.</span>'
      : '<button class="ghost primary" id="pxRefLoad">Load a reference picture\u2026</button>'+
        '<span class="pxhint">Draw from a photo, a sketch or concept art, shown under or over your pixels. It is kept with this drawing and never exported.</span>';
  }
  function drawRef(g){
    if(!refVisible()) return;
    var R=ST.pic.ref, img=ST.refImg, z=VIEW.z, B=ST.grid.bounds(ST.pic);
    g.save();
    g.beginPath(); g.rect(VIEW.x+B.minx*z, VIEW.y+B.miny*z, B.w*z, B.h*z); g.clip();
    g.globalAlpha=Math.max(0.05,Math.min(1,(R.op||50)/100)); g.imageSmoothingEnabled=true;
    g.drawImage(img, VIEW.x+R.x*z, VIEW.y+R.y*z, img.width*R.s*z, img.height*R.s*z);
    g.restore();
  }
  /* one square pixel's worth of the reference, for the quick redraw while painting */
  function drawRefCell(g, cx, cy, x0, y0, z){
    var R=ST.pic.ref, img=ST.refImg;
    var ax0=Math.max(cx,R.x), ay0=Math.max(cy,R.y), ax1=Math.min(cx+1,R.x+img.width*R.s), ay1=Math.min(cy+1,R.y+img.height*R.s);
    if(ax1<=ax0 || ay1<=ay0) return;
    g.save(); g.globalAlpha=Math.max(0.05,Math.min(1,(R.op||50)/100)); g.imageSmoothingEnabled=true;
    g.drawImage(img, (ax0-R.x)/R.s, (ay0-R.y)/R.s, (ax1-ax0)/R.s, (ay1-ay0)/R.s, x0+(ax0-cx)*z, y0+(ay0-cy)*z, (ax1-ax0)*z, (ay1-ay0)*z);
    g.restore();
  }

  /* ---- saving: automatic, into the library, and linked to the card ---- */
  var saveTimer=null;
  function scheduleSave(){ ST.status="Saving\u2026"; updateMeta(); clearTimeout(saveTimer); saveTimer=setTimeout(flushSave,500); }
  function flushSave(){
    clearTimeout(saveTimer); saveTimer=null;
    if(!ST || !ST.pic || ST.choosing) return;
    var P=PX(), first=!ST.id;
    commitLayer();
    /* edited now, so a release will never replace it (v12.4) */
    if(ST.pic.shipped && P.mark && P.mark(ST.pic)!==ST.pic.shipped) delete ST.pic.shipped;
    var id=P.put(ST.pic, ST.id||undefined);
    if(!id){ ST.status="Could not save \u2014 storage is full"; updateMeta(); return; }
    ST.id=id;
    if(first && ST.card) P.link(ST.card.schema||ST.card, ST.kind, id);
    ST.status="Saved"; updateMeta();
    if(ST.preview) renderPreview();
  }

  /* ---- preview: on the real card, and on a hex at board size ---- */
  function forgeBridges(){
    return [].slice.call(document.querySelectorAll("iframe")).map(function(f){
      try{ return f.contentWindow&&f.contentWindow.KETER_BRIDGE; }catch(e){ return null; } })
      .filter(function(B){ return B&&B.renderCard; });
  }
  function hexTile(g, cx, cy, size, pic){
    var path=function(r){ g.beginPath(); for(var k=0;k<6;k++){ var a=Math.PI/180*(60*k-30), x=cx+r*Math.cos(a), y=cy+r*Math.sin(a); if(k) g.lineTo(x,y); else g.moveTo(x,y); } g.closePath(); };
    path(size); g.fillStyle="#111d24"; g.fill(); g.strokeStyle="#2c3438"; g.lineWidth=1; g.stroke();
    var lw=Math.max(2,size*0.08), inner=size*0.84-lw/2;
    path(inner); g.fillStyle="rgba(8,12,16,0.55)"; g.fill(); g.strokeStyle="#22f0ff"; g.lineWidth=lw; g.stroke();
    if(PX().isHex(pic) && pic.shape==="hexagon"){ var hs=(inner-lw/2)*1.9; PX().draw(g, pic, cx-hs/2, cy-hs/2, hs, hs, 1); return; }
    var side=(inner-lw/2)*1.268;
    PX().draw(g, pic, cx-side/2, cy-side/2, side, side, Math.min(window.devicePixelRatio||1,3), {overhang:0.12, minFill:0.75});
  }
  function renderPreview(){
    var host=$("pxPrev"); if(!host||!ST) return;
    var P=PX(); P.refreshFlat(ST.pic);
    if(ST.kind==="token"){
      host.innerHTML='<p class="pxsub">On the board</p><canvas id="pxPrevC" width="300" height="90"></canvas>';
      var c=$("pxPrevC"), dpr=Math.min(window.devicePixelRatio||1,3); c.width=300*dpr; c.height=90*dpr; c.style.width="300px"; c.style.height="90px";
      var g=c.getContext("2d"); g.setTransform(dpr,0,0,dpr,0,0); g.fillStyle="#0a0f13"; g.fillRect(0,0,300,90);
      hexTile(g,40,45,22,ST.pic); hexTile(g,120,45,30,ST.pic); hexTile(g,220,45,40,ST.pic);
      return;
    }
    var B=forgeBridges()[0];
    if(!B || !ST.card || !ST.card.schema){
      host.innerHTML='<p class="pxsub">Preview</p><p class="pxnote">'+(ST.card?"Open the Forge once so cards can be drawn here.":"Link this picture to a card to preview it on the card.")+'</p>';
      return;
    }
    host.innerHTML='<p class="pxsub">On the card</p><canvas id="pxPrevC"></canvas>';
    var dpi=110, cv=$("pxPrevC"); cv.width=Math.round(2.5*dpi); cv.height=Math.round(3.5*dpi);
    var sch=JSON.parse(JSON.stringify(ST.card.schema)); sch.pixelArt=ST.id;
    try{ B.renderCard(cv.getContext("2d"), B.fromSchema(sch), dpi, {}); }catch(e){ host.innerHTML+='<p class="pxnote">The card could not be drawn.</p>'; }
  }

  /* ---- export: one picture at its true print size, as vector pixels ----
     Each run of same-coloured pixels is a filled rectangle, so the PDF is crisp
     at any printer resolution and small. Card art is printed 2.27 inches wide,
     as on the card; a token at the size it fills on a 1.25-inch board tile,
     inside that tile's outline to cut along. */
  function pdfBytes(pic){
    var P=PX(), w=pic.w, h=pic.h, flat=P.decode(P.refreshFlat(pic), w*h), T=P.tableFor?P.tableFor(pic):P.RGB;
    var PW=612, PH=792, kind=pic.kind||"art", cell, x0, top, hex=P.isHex(pic), HL=hex?P.hexLayout(pic):null;
    var R=TOKEN_TILE_IN/Math.sqrt(3)*72, innerR=R*0.84;
    var bw=hex?HL.bounds.w:w, bh=hex?HL.bounds.h:h;
    if(kind==="token") cell=hex&&pic.shape==="hexagon" ? (2*innerR*0.95)/Math.max(bw,bh) : (innerR*1.268)/w;
    else if(kind==="blank") cell=Math.min((ST&&ST.pdfW)||2, 7.5)*72/bw;
    else cell=ART_W_IN*72/bw;
    var drawW=bw*cell, drawH=bh*cell; x0=(PW-drawW)/2; top=PH-144;
    var f=function(n){ return (Math.round(n*1000)/1000).toString(); };
    var out=[];
    if(kind==="token"){
      var cx=PW/2, cy=top-drawH/2; out.push("0.55 0.6 0.65 RG 0.5 w");
      for(var k=0;k<=6;k++){ var a=Math.PI/180*(60*k-30); out.push(f(cx+R*Math.cos(a))+" "+f(cy+R*Math.sin(a))+(k?" l":" m")); }
      out.push("S");
    } else {
      out.push("0.55 0.6 0.65 RG 0.4 w "+f(x0)+" "+f(top-drawH)+" "+f(drawW)+" "+f(drawH)+" re S");
    }
    if(hex){
      /* each hex a filled six-sided path, a hair oversized so no seams show */
      for(var hi=0;hi<flat.length;hi++){
        if(!flat[hi]||!HL.valid[hi]) continue;
        var rgbh=T[flat[hi]]; if(!rgbh) continue; var hx=x0+(HL.cx[hi]-HL.bounds.minx)*cell, hy=top-(HL.cy[hi]-HL.bounds.miny)*cell, rr=cell*1.02;
        var path=[];
        for(var kk=0;kk<6;kk++){ var an=Math.PI/180*(60*kk-(HL.orient==="flat"?0:30)); path.push(f(hx+rr*Math.cos(an))+" "+f(hy-rr*Math.sin(an))+(kk?" l":" m")); }
        out.push(f(rgbh[0]/255)+" "+f(rgbh[1]/255)+" "+f(rgbh[2]/255)+" rg "+path.join(" ")+" h f");
      }
    }
    for(var y=0;!hex && y<h;y++){
      var x=0;
      while(x<w){
        var v=flat[y*w+x], run=1;
        while(x+run<w && flat[y*w+x+run]===v) run++;
        if(v && T[v]){ var rgb=T[v];
          out.push(f(rgb[0]/255)+" "+f(rgb[1]/255)+" "+f(rgb[2]/255)+" rg "+
            f(x0+x*cell)+" "+f(top-(y+1)*cell-0.01)+" "+f(run*cell+0.02)+" "+f(cell+0.02)+" re f"); }
        x+=run;
      }
    }
    var inW=(drawW/72).toFixed(2), inH=(drawH/72).toFixed(2);
    var cap=(pic.name||"Untitled")+"  -  "+(hex?(pic.shape==="hexagon"?(pic.side+" hex pixels per side"):(w+" hex pixels across")):(w+" x "+h+" pixels"))+", "+(kind==="token"?("for a "+TOKEN_TILE_IN+" in board tile"):(inW+" x "+inH+" in"));
    cap=cap.replace(/[\\()]/g,function(c){ return "\\"+c; }).replace(/[^\x20-\x7e]/g,"-");
    out.push("BT /F1 9 Tf 0.3 0.33 0.36 rg "+f(72)+" "+f(top-drawH-(kind==="token"?60:28))+" Td ("+cap+") Tj ET");
    var content=out.join("\n");
    var objs=["<< /Type /Catalog /Pages 2 0 R >>",
      "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
      "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 "+PW+" "+PH+"] /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>",
      "<< /Length "+content.length+" >>\nstream\n"+content+"\nendstream",
      "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"];
    var pdf="%PDF-1.4\n", offs=[];
    objs.forEach(function(o,i){ offs.push(pdf.length); pdf+=(i+1)+" 0 obj\n"+o+"\nendobj\n"; });
    var xref=pdf.length;
    pdf+="xref\n0 "+(objs.length+1)+"\n0000000000 65535 f \n"+offs.map(function(o){ return ("0000000000"+o).slice(-10)+" 00000 n \n"; }).join("");
    pdf+="trailer\n<< /Size "+(objs.length+1)+" /Root 1 0 R >>\nstartxref\n"+xref+"\n%%EOF\n";
    return pdf;
  }
  /* PNG: square pixels scaled by a whole number, crisp; hex pixels drawn about
     that many screen pixels across. Transparency is kept either way. */
  function pngCanvas(pic, k){
    var P=PX(), c=document.createElement("canvas"), g;
    if(P.isHex(pic)){
      /* built pixel by pixel: each takes the exact palette colour of the hex it
         falls in, or stays fully transparent. Drawn as smoothed shapes, the
         seams between hexes came out a shade off, which other software treats
         as a different colour. */
      var B=P.hexLayout(pic).bounds, unit=(pic.orient==="flat")?k/2:k/Math.sqrt(3);
      c.width=Math.max(1,Math.ceil(B.w*unit)); c.height=Math.max(1,Math.ceil(B.h*unit));
      g=c.getContext("2d");
      var img=g.createImageData(c.width,c.height), flat=P.decode(P.refreshFlat(pic), pic.w*pic.h), T=P.tableFor?P.tableFor(pic):P.RGB;
      for(var y=0;y<c.height;y++) for(var x=0;x<c.width;x++){
        var cell=P.hexCellAt(pic, B.minx+(x+0.5)/unit, B.miny+(y+0.5)/unit);
        if(cell<0 || !flat[cell]) continue;
        var rgb=T[flat[cell]], o=(y*c.width+x)*4; if(!rgb) continue;
        img.data[o]=rgb[0]; img.data[o+1]=rgb[1]; img.data[o+2]=rgb[2]; img.data[o+3]=255;
      }
      g.putImageData(img,0,0);
    } else if(P.frameCount(pic)>1){
      /* v14.3: its frames side by side, first to last */
      c=P.stripCanvas(pic,k);
    } else {
      c.width=pic.w*k; c.height=pic.h*k; g=c.getContext("2d");
      g.imageSmoothingEnabled=false; P.refreshFlat(pic); g.drawImage(P.sprite(pic),0,0,c.width,c.height);
    }
    return c;
  }
  function exportPng(k){
    flushSave();
    var nf=PX().isHex(ST.pic)?1:PX().frameCount(ST.pic), c=pngCanvas(ST.pic,k), name=(String(ST.pic.name||"KETER picture").replace(/[^\w\- ]+/g,"").trim()||"KETER picture")+" "+k+"x"+(nf>1?" "+nf+" frames":"")+".png";
    c.toBlob(function(blob){
      var a=document.createElement("a"); a.href=URL.createObjectURL(blob); a.download=name;
      document.body.appendChild(a); a.click(); setTimeout(function(){ URL.revokeObjectURL(a.href); a.remove(); },1500);
    },"image/png");
  }
  function exportPdf(){
    flushSave();
    var text=pdfBytes(ST.pic), bytes=new Uint8Array(text.length);
    for(var i=0;i<text.length;i++) bytes[i]=text.charCodeAt(i)&255;
    var blob=new Blob([bytes],{type:"application/pdf"}), a=document.createElement("a");
    a.href=URL.createObjectURL(blob);
    a.download=(String(ST.pic.name||"KETER picture").replace(/[^\w\- ]+/g,"").trim()||"KETER picture")+".pdf";
    document.body.appendChild(a); a.click(); setTimeout(function(){ URL.revokeObjectURL(a.href); a.remove(); },1500);
  }

  /* ---- the menu ---- */
  function renderMenu(){
    var m=$("pxMenu"); if(!m) return;
    if(!ST.menu){ m.innerHTML=""; return; }
    m.innerHTML='<div class="pxmenu">'+
      '<button class="ghost" id="pxPrevTog">'+(ST.preview?"Hide preview":"Preview")+'</button>'+
      '<p class="pxsub">Export as PNG \u2014 each pixel becomes'+(PX().frameCount(ST.pic)>1&&!PX().isHex(ST.pic)?' (its '+PX().frameCount(ST.pic)+' frames side by side)':'')+'</p><div class="pxrow">'+
        [1,2,4,8,16].map(function(k){ return '<button class="ghost" data-pxpng="'+k+'">'+k+'\u00d7</button>'; }).join("")+'</div>'+
      (ST.kind==="blank"?
        '<p class="pxsub">Export as PDF \u2014 print width</p><div class="pxrow pxcustom"><input type="number" id="pxPdfW" min="0.25" max="7.5" step="0.25" value="'+(ST.pdfW||2)+'" class="pxnum"><span>inches</span>'+
        '<button class="ghost" id="pxPdf">Export as PDF</button></div>':
        '<button class="ghost" id="pxPdf">Export as PDF</button>')+
      '<button class="ghost" id="pxGridTog">'+(ST.showGrid?"Hide grid":"Show grid")+'</button>'+
      /* v12.5 */
      '<p class="pxsub">View</p><div class="seg pxseg">'+["colour","value","silhouette"].map(function(v){ return '<button class="'+((ST.view||"colour")===v?"on":"")+'" data-pxview="'+v+'">'+VIEW_LABEL[v]+'</button>'; }).join("")+'</div>'+
      '<button class="ghost'+(ST.mini?" primary":"")+'" id="pxMiniTog">'+(ST.mini?"Hide the 1\u00d7 and 2\u00d7 preview":"Show at 1\u00d7 and 2\u00d7")+'</button>'+
      '<button class="ghost" id="pxConvLayer">An image onto a new layer\u2026</button>'+
      (canDouble()?'<button class="ghost" id="pxDouble">Double the pixels \u00b7 '+ST.pic.w+'\u00d7'+ST.pic.h+' \u2192 '+(ST.pic.w*2)+'\u00d7'+(ST.pic.h*2)+'</button>':'')+
      '<button class="ghost" id="pxClear">Clear the picture</button></div>';
  }

  /* v12.4: every pixel becomes a 2 x 2 block: card art from 64 to 128 across,
     a blank canvas up to 256. The picture looks the same; the room is for detail. */
  function canDouble(){
    if(!ST || ST.grid.name==="hex") return false;
    var P=PX(), pic=ST.pic;
    if(ST.kind==="art") return pic.w*2<=128;
    if(ST.kind==="blank") return pic.w*2<=(P.BLANK_MAX||128) && pic.h*2<=(P.BLANK_MAX||128);
    return false;
  }
  function doublePixels(){
    if(!canDouble()) return;
    if(ST.sel) commitSelection();
    pushLayersUndo();
    var d=PX().doubled(ST.pic);
    ST.pic.w=d.w; ST.pic.h=d.h; ST.pic.frames=d.frames; if(d.ref) ST.pic.ref=d.ref; ST.pic.flat="";
    ST.buf=PX().decode(FR().layers[ST.layer].px, ST.pic.w*ST.pic.h);
    ST.checker=null; ST.solo=null; VIEW=null;
    renderEditor(); ST.status="Doubled to "+ST.pic.w+"\u00d7"+ST.pic.h; scheduleSave();
  }

  /* ---- from an image (v12.5) ----
     Any picture file becomes palette pixels: 32, 64, 128 or 256 across, or
     onto a new layer of the picture you are drawing, at its size. The image
     comes along as the drawing's reference, hidden until you show it. */
  var CONV=null, convTimer=null;
  /* v13.0: the home screen's tabs: the library, skins, and every asset */
  var STAB="library";
  function convPick(mode){
    var inp=document.createElement("input"); inp.type="file"; inp.accept="image/*";
    inp.onchange=function(){ var f=inp.files&&inp.files[0]; if(!f) return; var rd=new FileReader(); rd.onload=function(){ convOpen(rd.result, mode, f.name); }; rd.readAsDataURL(f); };
    inp.click();
  }
  function convOpen(data, mode, fname, done){
    var img=new Image();
    img.onload=function(){
      var last=CONV&&CONV.keep||{};
      CONV={img:img, data:data, mode:(mode==="layer"&&ST&&!ST.choosing)?"layer":"new",
        name:(String(fname||"").replace(/\.[a-z0-9]+$/i,"").trim()||"Converted"),
        size:last.size||128, fit:last.fit||"fit", limit:last.limit||0, from:last.from||"all", dither:last.dither||"none",
        bg:!!last.bg, bri:0, con:0, sat:0, compare:false, cache:{}, result:null};
      renderConv(); convRun(true); if(done) done();
    };
    img.onerror=function(){ alert("That file could not be read as a picture."); };
    img.src=data;
  }
  function convClose(){ CONV=null; var el=$("pxConv"); if(el) el.remove(); }
  /* the size of the result, and where the image lies on it */
  function convGeom(){
    var P=PX(), iw=CONV.img.width, ih=CONV.img.height, g;
    if(CONV.mode==="layer"){
      var pic=ST.pic, hex=ST.grid.name==="hex", B=ST.grid.bounds(pic);
      var sc=(CONV.fit==="fill"?Math.max:Math.min)(B.w/iw, B.h/ih);
      g={w:pic.w, h:pic.h, hex:hex, pic:pic, B:B, sc:sc, ox:B.minx+(B.w-iw*sc)/2, oy:B.miny+(B.h-ih*sc)/2};
    } else {
      var cap=P.BLANK_MAX||256, W=CONV.size, H=Math.max(1,Math.round(W*ih/iw));
      if(H>cap){ H=cap; W=Math.max(1,Math.round(H*iw/ih)); }
      var s2=Math.min(W/iw, H/ih);
      g={w:W, h:H, hex:false, B:{minx:0,miny:0,w:W,h:H}, sc:s2, ox:(W-iw*s2)/2, oy:(H-ih*s2)/2};
    }
    return g;
  }
  /* the image averaged down to one colour a pixel (four samples each way per
     square pixel; for hex pixels, the disc each hex covers) */
  function convSample(g){
    var key=g.w+"x"+g.h+":"+CONV.mode+":"+CONV.fit;
    if(CONV.cache[key]) return CONV.cache[key];
    var n=g.w*g.h, out=new Uint8ClampedArray(n*4), img=CONV.img;
    if(!g.hex){
      var k=4, c=document.createElement("canvas"); c.width=g.w*k; c.height=g.h*k;
      var cx=c.getContext("2d"); cx.imageSmoothingEnabled=true; cx.imageSmoothingQuality="high";
      cx.drawImage(img, g.ox*k, g.oy*k, img.width*g.sc*k, img.height*g.sc*k);
      var d=cx.getImageData(0,0,c.width,c.height).data;
      for(var y=0;y<g.h;y++) for(var x=0;x<g.w;x++){
        var r=0,gg=0,b=0,a=0;
        for(var sy=0;sy<k;sy++) for(var sx=0;sx<k;sx++){ var o=((y*k+sy)*c.width+(x*k+sx))*4, al=d[o+3]; r+=d[o]*al; gg+=d[o+1]*al; b+=d[o+2]*al; a+=al; }
        var t=(y*g.w+x)*4; if(a){ out[t]=r/a; out[t+1]=gg/a; out[t+2]=b/a; } out[t+3]=a/(k*k);
      }
    } else {
      var P=PX(), L=P.hexLayout(g.pic), u=6, B=g.B, c2=document.createElement("canvas");
      c2.width=Math.max(1,Math.ceil(B.w*u)); c2.height=Math.max(1,Math.ceil(B.h*u));
      var c2x=c2.getContext("2d"); c2x.imageSmoothingEnabled=true; c2x.imageSmoothingQuality="high";
      c2x.drawImage(img, (g.ox-B.minx)*u, (g.oy-B.miny)*u, img.width*g.sc*u, img.height*g.sc*u);
      var d2=c2x.getImageData(0,0,c2.width,c2.height).data, rad=0.85*u, R2=rad*rad;
      for(var i=0;i<n;i++){
        if(!L.valid[i]) continue;
        var px=(L.cx[i]-B.minx)*u, py=(L.cy[i]-B.miny)*u, r2=0,g2=0,b2=0,a2=0,m=0;
        for(var yy=Math.floor(py-rad);yy<=Math.ceil(py+rad);yy++) for(var xx=Math.floor(px-rad);xx<=Math.ceil(px+rad);xx++){
          if(xx<0||yy<0||xx>=c2.width||yy>=c2.height) continue;
          var ddx=xx+0.5-px, ddy=yy+0.5-py; if(ddx*ddx+ddy*ddy>R2) continue;
          var o2=(yy*c2.width+xx)*4, al2=d2[o2+3]; r2+=d2[o2]*al2; g2+=d2[o2+1]*al2; b2+=d2[o2+2]*al2; a2+=al2; m++;
        }
        var t2=i*4; if(a2){ out[t2]=r2/a2; out[t2+1]=g2/a2; out[t2+2]=b2/a2; } out[t2+3]=m?a2/m:0;
      }
    }
    return (CONV.cache[key]=out);
  }
  var CONV_FROM={all:"The whole palette", noneon:"Without the neons", splendor:"Splendor 128 only", splkt:"Splendor and KETER 56", mine:"My colours only"};
  function convAllowed(){
    var P=PX(), f=CONV.from, a=[];
    if(/^group:/.test(f)){ var gp=swatchGroups()[+f.slice(6)]; return gp?(gp.cols||[]).filter(function(i){ return !!P.PALETTE[i]; }):null; }
    for(var i=1;i<=P.PAL_MAX;i++){
      if(!P.PALETTE[i]) continue;
      var set=P.setOf(i);
      if(f==="noneon" && set==="neon") continue;
      if(f==="splendor" && set!=="splendor") continue;
      if(f==="splkt" && set!=="splendor" && set!=="keter") continue;
      if(f==="mine" && set!=="mine") continue;
      a.push(i);
    }
    return a;
  }
  function convRun(now){
    clearTimeout(convTimer);
    if(!now){ convTimer=setTimeout(function(){ convRun(true); },120); return; }
    if(!CONV) return;
    var P=PX(), g=convGeom(), rgba=convSample(g), allowed=convAllowed();
    if(allowed && !allowed.length){ allowed=null; }
    var opts={allowed:allowed||undefined, limit:CONV.limit, dither:CONV.dither, bg:CONV.bg, bri:CONV.bri, con:CONV.con, sat:CONV.sat};
    if(g.hex){ var G=gridFor(g.pic); opts.valid=function(i){ return G.valid(i); }; opts.neighbours=function(i){ return G.neighbours(i,g.w,g.h); }; }
    var idx=P.convert(rgba, g.w, g.h, opts), used={};
    for(var i=0;i<idx.length;i++) if(idx[i]) used[idx[i]]=1;
    CONV.result={g:g, px:idx, colours:Object.keys(used).length};
    CONV.keep={size:CONV.size, fit:CONV.fit, limit:CONV.limit, from:CONV.from, dither:CONV.dither, bg:CONV.bg};
    convDraw();
  }
  function convPic(){
    var R=CONV.result, g=R.g, P=PX();
    var pic=g.pic?{w:g.w,h:g.h,grid:g.pic.grid,orient:g.pic.orient,shape:g.pic.shape,side:g.pic.side}:{w:g.w,h:g.h,grid:"square"};
    pic.frames=[{layers:[{name:"Converted",visible:true,locked:false,opacity:100,mode:"view",px:P.encode(R.px)}]}];
    pic.flat=P.encode(R.px);
    return pic;
  }
  function convDraw(){
    var c=$("pxConvC"); if(!c||!CONV||!CONV.result) return;
    var P=PX(), dpr=Math.min(window.devicePixelRatio||1,3), box=c.parentNode, W=Math.max(200,(box.clientWidth||320)-2), H=Math.round(Math.min(360,W*0.8));
    c.width=Math.round(W*dpr); c.height=Math.round(H*dpr); c.style.width=W+"px"; c.style.height=H+"px";
    var g=c.getContext("2d"); g.setTransform(dpr,0,0,dpr,0,0); g.fillStyle="#0a0f13"; g.fillRect(0,0,W,H);
    var pic=convPic(), at=null;
    /* the checkerboard behind transparent pixels, then the result, drawn crisp */
    if(CONV.compare){
      var img=CONV.img, s=Math.min(W/img.width,H/img.height); g.imageSmoothingEnabled=true;
      g.drawImage(img,(W-img.width*s)/2,(H-img.height*s)/2,img.width*s,img.height*s);
    } else {
      at=P.draw(g,pic,8,8,W-16,H-16,dpr);
      if(at && !P.isHex(pic)){
        g.save(); g.globalCompositeOperation="destination-over";
        var cs=Math.max(4,Math.round(at.w/pic.w)); for(var yy=0;yy*cs<at.h;yy++) for(var xx=0;xx*cs<at.w;xx++){ g.fillStyle=((xx+yy)&1)?"#1c252c":"#232e36"; g.fillRect(at.x+xx*cs,at.y+yy*cs,Math.min(cs,at.w-xx*cs),Math.min(cs,at.h-yy*cs)); }
        g.restore();
      }
    }
    var info=$("pxConvInfo"); if(info) info.textContent=CONV.result.g.w+"×"+CONV.result.g.h+" · "+CONV.result.colours+" colour"+(CONV.result.colours===1?"":"s");
  }
  function renderConv(){
    if(!CONV) return;
    var host=HOST||$("v-studio"); if(!host) return;
    var el=$("pxConv"); if(!el){ el=document.createElement("div"); el.id="pxConv"; el.className="pxconv"; host.appendChild(el); }
    var segb=function(attr,val,cur,label){ return '<button class="'+(String(cur)===String(val)?"on":"")+'" '+attr+'="'+val+'">'+label+'</button>'; };
    var groups=swatchGroups(), layer=CONV.mode==="layer";
    var fromOpts=Object.keys(CONV_FROM).map(function(k){ return '<option value="'+k+'"'+(CONV.from===k?" selected":"")+'>'+CONV_FROM[k]+'</option>'; }).join("")+
      groups.map(function(gp,gi){ return '<option value="group:'+gi+'"'+(CONV.from==="group:"+gi?" selected":"")+'>Group: '+esc(gp.name||"Group")+'</option>'; }).join("");
    el.innerHTML='<div class="pxconvin">'+
      '<div class="pxconvhead"><b>'+(layer?"An image onto a new layer":"From an image")+'</b><button class="ghost" id="pxConvX">Cancel</button></div>'+
      '<div class="pxconvprev"><canvas id="pxConvC"></canvas></div>'+
      '<div class="pxrow" style="align-items:center;"><button class="ghost'+(CONV.compare?" primary":"")+'" id="pxConvCmp">'+(CONV.compare?"Show the pixels":"Show the original")+'</button><span class="pxconvinfo" id="pxConvInfo"></span></div>'+
      (layer?'<p class="pxsub">Onto this picture · '+ST.pic.w+'×'+ST.pic.h+'</p><div class="seg pxseg">'+segb("data-pxcfit","fit",CONV.fit,"Fit the whole image")+segb("data-pxcfit","fill",CONV.fit,"Fill the canvas")+'</div>'
        :'<p class="pxsub">Pixels across</p><div class="seg pxseg">'+[32,64,128,256].map(function(n){ return segb("data-pxcsize",n,CONV.size,n); }).join("")+'</div>')+
      '<p class="pxsub">How many colours</p><div class="seg pxseg">'+[[0,"All"],[64,"64"],[32,"32"],[16,"16"],[8,"8"]].map(function(o){ return segb("data-pxclim",o[0],CONV.limit,o[1]); }).join("")+'</div>'+
      '<p class="pxsub">Colours from</p><select id="pxConvFrom">'+fromOpts+'</select>'+
      '<p class="pxsub">Dither</p><div class="seg pxseg">'+[["none","Off"],["soft","Soft"],["full","Full"],["pattern","Pattern"]].map(function(o){ return segb("data-pxcdith",o[0],CONV.dither,o[1]); }).join("")+'</div>'+
      '<div class="pxrow"><button class="ghost'+(CONV.bg?" primary":"")+'" id="pxConvBg">Clear the background: '+(CONV.bg?"on":"off")+'</button></div>'+
      '<label class="pxrange">Brightness <input type="range" id="pxConvBri" min="-50" max="50" step="5" value="'+CONV.bri+'"></label>'+
      '<label class="pxrange">Contrast <input type="range" id="pxConvCon" min="-50" max="50" step="5" value="'+CONV.con+'"></label>'+
      '<label class="pxrange">Saturation <input type="range" id="pxConvSat" min="-50" max="50" step="5" value="'+CONV.sat+'"></label>'+
      '<button class="ghost primary" id="pxConvGo">'+(layer?"Put it on a new layer":"Create the picture")+'</button>'+
      '<p class="pxnote">The image is kept with the drawing as its reference, hidden until you show it — never exported. Clearing the background removes the colour around the edge and whatever joins it.</p></div>';
  }
  function convClick(t){
    var id=t.id;
    if(id==="pxConvX"){ convClose(); return; }
    if(id==="pxConvCmp"){ CONV.compare=!CONV.compare; renderConv(); convDraw(); return; }
    if(id==="pxConvBg"){ CONV.bg=!CONV.bg; renderConv(); convRun(); return; }
    if(id==="pxConvGo"){ convCreate(); return; }
    var a;
    if((a=t.getAttribute("data-pxcsize"))){ CONV.size=+a; }
    else if((a=t.getAttribute("data-pxcfit"))){ CONV.fit=a; }
    else if((a=t.getAttribute("data-pxclim"))!==null){ CONV.limit=+a; }
    else if((a=t.getAttribute("data-pxcdith"))){ CONV.dither=a; }
    else return;
    renderConv(); convRun();
  }
  /* the image, scaled down to at most 1024 on its longest side, for the reference */
  function convRefData(){
    var img=CONV.img, M=1024, k=Math.min(1,M/Math.max(img.width,img.height));
    var c=document.createElement("canvas"); c.width=Math.max(1,Math.round(img.width*k)); c.height=Math.max(1,Math.round(img.height*k));
    c.getContext("2d").drawImage(img,0,0,c.width,c.height);
    return {data:c.toDataURL("image/jpeg",0.9), w:c.width, h:c.height};
  }
  function convCreate(){
    if(!CONV || !CONV.result) return;
    convRun(true);
    var P=PX(), R=CONV.result, g=R.g, ref=convRefData(), s=g.sc*CONV.img.width/ref.w;
    var refPos={x:g.ox, y:g.oy, s:s, fit:s, op:50, above:false, hidden:true};
    if(CONV.mode==="layer"){
      var Ls=FR().layers;
      if(ST.sel) commitSelection();
      pushLayersUndo(); ST.solo=null;
      Ls.splice(ST.layer+1,0,{name:"Converted", visible:true, locked:false, opacity:100, mode:"view", px:P.encode(R.px)});
      switchLayer(ST.layer+1);
      var needRef=!ST.pic.ref; if(needRef) ST.pic.ref=refPos;
      convClose(); layerChanged(); flushSave();
      if(needRef && ST.id){ var sid=ST.id; refPut(sid, ref.data, function(){ var im=new Image(); im.onload=function(){ if(ST&&ST.id===sid){ ST.refImg=im; renderTools(); renderRef(); renderPalette(); } }; im.src=ref.data; }); }
      ST.status="Converted onto a new layer"; updateMeta();
      return;
    }
    var pic=P.blank(g.w, g.h, CONV.name); pic.kind="blank"; pic.grid="square";
    pic.frames[0].layers[0].name="Converted"; pic.frames[0].layers[0].px=P.encode(R.px); pic.ref=refPos;
    var id=P.put(pic);
    if(!id){ alert("There is no room left on this device for a new picture."); return; }
    var from=(ST&&ST.from)||(HOMEMODE==="hex"?"hexstudio":"studio");
    convClose();
    refPut(id, ref.data, function(){ ST=null; open({id:id, from:from}); });
  }

  /* ---- touch and mouse ---- */
  function wireCanvas(){
    var cv=$("pxCanvas"); if(!cv || cv._wired) return; cv._wired=true;
    var pts={}, pinch=null, lp=null;
    var pos=function(e){ var r=cv.getBoundingClientRect(); return {x:e.clientX-r.left, y:e.clientY-r.top}; };
    var aim=function(p){ return ST.cursor?{x:p.x, y:p.y-56}:p; };
    cv.addEventListener("pointerdown",function(e){
      cv.setPointerCapture(e.pointerId); pts[e.pointerId]=pos(e);
      var ids=Object.keys(pts);
      if(ids.length===2){
        if(stroke&&stroke.painted&&ST.undo.length){ var u0=ST.undo.pop(); if(u0&&u0.buf) ST.buf=u0.buf; commitLayer(); drawCanvas(); }
        stroke=null; clearTimeout(lp); ST.cursorAt=null;
        var a=pts[ids[0]], b=pts[ids[1]];
        pinch={d:Math.hypot(a.x-b.x,a.y-b.y), z:VIEW.z, mx:(a.x+b.x)/2, my:(a.y+b.y)/2, vx:VIEW.x, vy:VIEW.y};
        return;
      }
      var p=aim(pts[e.pointerId]);
      if(ST.playing){ stopPlaying(); delete pts[e.pointerId]; return; }
      if(ST.cursor) ST.cursorAt=p;
      toolDown(p.x,p.y);
      clearTimeout(lp); lp=setTimeout(function(){ longPress(p.x,p.y); },500);
    });
    cv.addEventListener("pointermove",function(e){
      if(!pts[e.pointerId]) return;
      pts[e.pointerId]=pos(e);
      var ids=Object.keys(pts);
      if(pinch && ids.length===2){
        var a=pts[ids[0]], b=pts[ids[1]], d=Math.hypot(a.x-b.x,a.y-b.y), mx=(a.x+b.x)/2, my=(a.y+b.y)/2;
        var z=Math.max(1,Math.min(64,Math.round(pinch.z*d/pinch.d)));
        var ax=(pinch.mx-pinch.vx)/pinch.z, ay=(pinch.my-pinch.vy)/pinch.z;
        VIEW.z=z; VIEW.x=Math.round(mx-ax*z); VIEW.y=Math.round(my-ay*z);
        drawCanvas(); return;
      }
      var p=aim(pts[e.pointerId]);
      if(stroke && Math.abs(p.x-stroke.start.x)+Math.abs(p.y-stroke.start.y)>6) clearTimeout(lp);
      if(ST.cursor){ ST.cursorAt=p; }
      toolMove(p.x,p.y);
      if(ST.cursor) drawCursor();
    });
    var up=function(e){
      delete pts[e.pointerId]; clearTimeout(lp);
      if(pinch){ if(Object.keys(pts).length<2) pinch=null; return; }
      toolUp(); ST.cursorAt=null; drawCanvas(); drawCursor();
    };
    cv.addEventListener("pointerup",up); cv.addEventListener("pointercancel",up);
    cv.addEventListener("wheel",function(e){ e.preventDefault(); var p=pos(e); zoomAt(VIEW.z*(e.deltaY<0?1.25:0.8)+(e.deltaY<0?1:-1)*0.01, p.x, p.y); },{passive:false});
  }
  document.addEventListener("click",function(e){
    if(!HOST || !HOST.contains(e.target)) return;
    /* the colour swatches are tappable too: the second dither colour ignored
       taps, so the next palette choice changed the main colour instead */
    var t=e.target.closest?e.target.closest("button,[data-pxcard],.pxbig,[data-pxlay]"):null; if(!t) return;
    var id=t.id, P=PX();
    /* v12.5: the converter sits over whatever is on screen */
    if(CONV && t.closest("#pxConv")){ convClick(t); return; }
    if(ST && ST.choosing){
      var o=ST.opts, sz=t.getAttribute("data-pxsize"), side=t.getAttribute("data-pxside"), acr=t.getAttribute("data-pxacross"),
          ori=t.getAttribute("data-pxorient"), start=t.getAttribute("data-pxstart");
      if(ori){ ST.orient=ori; renderChooser(); return; }
      var wh=t.getAttribute("data-pxwh"), hwh=t.getAttribute("data-pxhexwh"), cu=t.getAttribute("data-pxcustom");
      var clampN=function(v,cap){ return Math.max(1,Math.min(cap||128,parseInt(v,10)||1)); };
      if(wh){ var d=wh.split("x"); o.w=+d[0]; o.h=+d[1]; o.grid="square"; ST=null; open(o); return; }
      if(hwh){ var e2=hwh.split("x"); o.w=+e2[0]; o.h=+e2[1]; o.grid="hex"; o.orient=ST.orient||"pointy"; ST=null; open(o); return; }
      if(cu==="square"){ var sqc=P.BLANK_MAX||128; o.w=clampN(($("pxSqW")||{}).value,sqc); o.h=clampN(($("pxSqH")||{}).value,sqc); o.grid="square"; ST=null; open(o); return; }
      if(cu==="hex"){ o.w=clampN(($("pxHxW")||{}).value); o.h=clampN(($("pxHxH")||{}).value); o.grid="hex"; o.orient=ST.orient||"pointy"; ST=null; open(o); return; }
      if(sz){ o.size=+sz; o.grid="square"; ST=null; open(o); return; }
      var aw=t.getAttribute("data-pxartw"); if(aw){ o.artW=+aw; o.grid="square"; ST=null; open(o); return; }
      if(start){ o.grid="square"; ST=null; open(o); return; }
      if(side||acr){ o.grid="hex"; o.orient=ST.orient||"pointy"; if(side) o.side=+side; if(acr) o.across=+acr; ST=null; open(o); return; }
      if(id==="pxBack"){ close(); return; }
      return;
    }
    if(!ST){
      var stab=t.getAttribute("data-pxstab"); if(stab){ STAB=stab; renderHome(); return; }
      if(STAB!=="library") return;
      if(id==="pxNewTok"){ open({kind:"token", from:(HOMEMODE==="hex"?"hexstudio":"studio")}); return; }
      if(id==="pxNewArt"){ renderCardPicker(""); return; }
      if(id==="pxNewBlank"){ open({kind:"blank", from:(HOMEMODE==="hex"?"hexstudio":"studio")}); return; }
      if(id==="pxNewImg"){ convPick("new"); return; }
      var cardEl=t.getAttribute("data-pxcard");
      if(cardEl!==null){ var c=$("pxPick")._hits[+cardEl]; if(c){ ST=null; open({kind:"art", card:{key:c.id||c.name, name:c.name, schema:c}, artHin:artBoxFor(c), from:(HOMEMODE==="hex"?"hexstudio":"studio")}); } return; }
      var o=t.getAttribute("data-pxopen"); if(o){ open({id:o}); return; }
      var cp=t.getAttribute("data-pxcopy"); if(cp){ var nid=P.copy(cp); if(nid) refCopy(cp,nid); renderHome(); return; }
      var dl=t.getAttribute("data-pxdel"); if(dl){ if(confirm("Delete this picture? Cards using it will lose their art.")){ P.remove(dl); refDel(dl); renderHome(); } return; }
      return;
    }
    var tool=t.getAttribute("data-pxtool");
    if(tool){ if(ST.sel && tool!=="select") commitSelection(); ST.tool=tool; ST.pickTarget=1; renderTools(); renderOpts(); renderPalette(); return; }
    var col=t.getAttribute("data-pxcol");
    if(col){ chooseColour(+col); return; }
    /* v12.5: the palette's families, your own colours, a colour from the reference */
    var fam=t.getAttribute("data-pxfam"); if(fam){ var V=palView(); V.fam=fam; savePalView(V); renderPalette(); return; }
    if(id==="pxColAdd"){ var hv=($("pxColHex")||{}).value; addMine(hv&&hv.trim()?hv:($("pxColPick")||{}).value); return; }
    if(id==="pxColRef"){ if(!ST.refImg) return; ST.refPick=!ST.refPick; ST.status=ST.refPick?"Tap the picture where the reference has the colour you want":""; updateMeta(); renderPalette(); return; }
    if(id==="pxColDel"){
      var ci=ST.colour; if(ci<P.CUSTOM_FROM) return;
      if(picUses(ci)){ ST.status="This picture uses that colour — recolour those pixels first"; updateMeta(); return; }
      if(!confirm("Remove "+P.PALETTE[ci]+" from your colours? Pictures that use it keep their own copy.")) return;
      P.removeColour(ci); ST.colour=33; ST.recent=ST.recent.filter(function(x){ return x!==ci; }); ST.status="Removed"; updateMeta(); renderPalette(); return;
    }
    if(id==="pxFoundNear"){ var fn=ST.found&&ST.found.near; ST.found=null; if(fn) chooseColour(fn); else renderPalette(); return; }
    if(id==="pxFoundAdd"){ var fh=ST.found&&ST.found.hex; ST.found=null; if(fh) addMine(fh); else renderPalette(); return; }
    if(id==="pxFoundX"){ ST.found=null; renderPalette(); return; }
    var sa=t.getAttribute("data-pxsel"); if(sa){ selAction(sa); return; }
    /* v12.4 */
    var bs=t.getAttribute("data-pxbrush"); if(bs){ ST.size=+bs; renderOpts(); return; }
    var bsh=t.getAttribute("data-pxshape"); if(bsh){ ST.brushShape=bsh; renderOpts(); return; }
    var dp=t.getAttribute("data-pxdp"); if(dp){ ST.ditherPat=dp; renderOpts(); return; }
    var sm=t.getAttribute("data-pxselmode"); if(sm){ if(ST.sel) commitSelection(); ST.selMode=sm; renderOpts(); return; }
    var ga=t.getAttribute("data-pxgadd"), gr=t.getAttribute("data-pxgrem"), gd=t.getAttribute("data-pxgdel"), gn=t.getAttribute("data-pxgnew");
    if(ga!==null||gr!==null||gd!==null){
      var G2=swatchGroups(), gi=+(ga!==null?ga:gr!==null?gr:gd), grp=G2[gi]; if(!grp) return;
      if(gd!==null){ if(confirm("Delete the swatch group \u201c"+(grp.name||"Group")+"\u201d?")) G2.splice(gi,1); }
      else { grp.cols=grp.cols||[]; var at=grp.cols.indexOf(ST.colour);
        if(ga!==null && at<0) grp.cols.push(ST.colour); if(gr!==null && at>=0) grp.cols.splice(at,1); }
      saveSwatchGroups(G2); renderPalette(); return;
    }
    if(gn){
      var nmG=prompt("Name the swatch group (a material, say: Gunmetal, Rust, Bone)","");
      if(nmG===null) return;
      var G3=swatchGroups(); G3.push({name:String(nmG).trim()||("Group "+(G3.length+1)), cols:gn==="pic"?(ST.usedCols||[]).slice(0,24):[ST.colour]});
      saveSwatchGroups(G3); renderPalette(); return;
    }
    if(id==="pxRefTog"){ ST.refPanel=!ST.refPanel; if(!ST.refPanel) ST.refMove=false; renderTools(); renderRef(); return; }
    if(id==="pxRefLoad"){ pickRefFile(); return; }
    if(id==="pxRefShow"){ if(ST.pic.ref){ ST.pic.ref.hidden=!ST.pic.ref.hidden; renderRef(); renderTools(); drawCanvas(); scheduleSave(); } return; }
    if(id==="pxRefMove"){ ST.refMove=!ST.refMove; renderRef(); return; }
    if(id==="pxRefFit"){ var Rf=ST.pic.ref; if(Rf&&ST.refImg){ var Bf=ST.grid.bounds(ST.pic); Rf.s=Rf.fit=Math.min(Bf.w/ST.refImg.width,Bf.h/ST.refImg.height);
      Rf.x=Bf.minx+(Bf.w-ST.refImg.width*Rf.s)/2; Rf.y=Bf.miny+(Bf.h-ST.refImg.height*Rf.s)/2; renderRef(); drawCanvas(); scheduleSave(); } return; }
    if(id==="pxRefDel"){ if(confirm("Remove the reference picture from this drawing?")){ if(ST.id) refDel(ST.id); ST.pic.ref=null; ST.refImg=null; ST.refMove=false; renderRef(); renderTools(); drawCanvas(); scheduleSave(); } return; }
    var rp=t.getAttribute("data-pxrefpos"); if(rp&&ST.pic.ref){ ST.pic.ref.above=rp==="above"; renderRef(); drawCanvas(); scheduleSave(); return; }
    if(id==="pxDouble"){ ST.menu=false; renderMenu(); doublePixels(); return; }
    /* v12.5: views, the small preview, an image onto a layer, text */
    var vw=t.getAttribute("data-pxview"); if(vw){ ST.view=vw; ST.checker=null; renderMenu(); drawCanvas(); return; }
    if(id==="pxViewTag"){ ST.view="colour"; ST.checker=null; renderMenu(); drawCanvas(); return; }
    if(id==="pxMiniTog"){ ST.mini=MINI_ON=!ST.mini; renderMenu(); drawMini(); return; }
    if(id==="pxConvLayer"){ ST.menu=false; renderMenu(); if(ST.sel) commitSelection(); convPick("layer"); return; }
    var fnt=t.getAttribute("data-pxfont"); if(fnt){ ST.font=fnt; renderOpts(); return; }
    var tsp=t.getAttribute("data-pxtsp"); if(tsp!==null){ ST.tspace=+tsp; renderOpts(); return; }
    if(id==="pxTextPlace"){ var ta=$("pxText"); if(ta) ST.text=ta.value; placeText(); return; }
    var fl=t.getAttribute("data-pxfill"); if(fl!==null){ ST.shapeFill=fl==="1"; renderOpts(); return; }
    var dm=t.getAttribute("data-pxdm"); if(dm){ ST.ditherMode=dm; renderOpts(); renderPalette(); return; }
    var hp=t.getAttribute("data-pxhp"); if(hp){ ST.hexPattern=hp; renderOpts(); return; }
    if(id==="pxBig2"){ ST.pickTarget=ST.pickTarget===2?1:2; if(ST.pickTarget===2 && !ST.palOpen) ST.palOpen=true; renderPalette(); return; }
    if(id==="pxBig1"){ ST.pickTarget=1; renderPalette(); return; }
    /* v14.3: frames */
    if(id==="pxFrTog"){ ST.showFrames=!ST.showFrames; renderFrames(); return; }
    var frb=t.getAttribute("data-pxfr"); if(frb!==null){ if(ST.playing) stopPlaying(); switchFrame(+frb); renderFrames(); renderLayers(); drawCanvas(); updateMeta(); return; }
    if(id==="pxFrAdd"){ addFrame(false); return; }
    if(id==="pxFrCopy"){ addFrame(true); return; }
    if(id==="pxFrDel"){ deleteFrame(); return; }
    if(id==="pxFrLeft"){ moveFrame(-1); return; }
    if(id==="pxFrRight"){ moveFrame(1); return; }
    if(id==="pxFrPlay"){ if(ST.playing) stopPlaying(); else startPlaying(); return; }
    if(id==="pxOnion"){ ST.onion=!ST.onion; renderFrames(); drawCanvas(); return; }
    var Ls=FR().layers;
    if(id==="pxLayTog"){ ST.showLayers=!ST.showLayers; renderLayers(); return; }
    if(id==="pxLayAdd"){ pushLayersUndo(); ST.solo=null; var nL={name:"Layer "+(Ls.length+1), visible:true, locked:false, opacity:100, mode:"view", px:PX().encode(new Uint8Array(ST.pic.w*ST.pic.h))};
      Ls.splice(ST.layer+1,0,nL); switchLayer(ST.layer+1); layerChanged(); return; }
    var sel=t.getAttribute("data-pxlay"); if(sel!==null && !t.closest("[data-pxvis],[data-pxlock],[data-pxup],[data-pxdown]")){ switchLayer(+sel); renderLayers(); updateMeta(); return; }
    var vis=t.getAttribute("data-pxvis"); if(vis!==null){ pushLayersUndo(); Ls[+vis].visible=!Ls[+vis].visible; layerChanged(); return; }
    var lk=t.getAttribute("data-pxlock"); if(lk!==null){ pushLayersUndo(); Ls[+lk].locked=!Ls[+lk].locked; renderLayers(); scheduleSave(); return; }
    var up=t.getAttribute("data-pxup"), dn=t.getAttribute("data-pxdown");
    if(up!==null||dn!==null){ var from=+(up!==null?up:dn), to=from+(up!==null?1:-1);
      if(to<0||to>=Ls.length) return; pushLayersUndo(); ST.solo=null; Ls=FR().layers; var tmp=Ls[from]; Ls[from]=Ls[to]; Ls[to]=tmp;
      if(ST.layer===from) ST.layer=to; else if(ST.layer===to) ST.layer=from; layerChanged(); return; }
    if(id==="pxLayDup"){ pushLayersUndo(); var c=JSON.parse(JSON.stringify(Ls[ST.layer])); c.name=(c.name||"Layer")+" copy"; Ls.splice(ST.layer+1,0,c); switchLayer(ST.layer+1); layerChanged(); return; }
    if(id==="pxLayDel"){ if(Ls.length<2) return; pushLayersUndo(); ST.solo=null; Ls.splice(ST.layer,1); ST.layer=Math.max(0,ST.layer-1);
      ST.buf=PX().decode(Ls[ST.layer].px,ST.pic.w*ST.pic.h); layerChanged(); return; }
    if(id==="pxLayRen"){ var nm=prompt("Layer name",Ls[ST.layer].name||""); if(nm!==null){ pushLayersUndo(); Ls[ST.layer].name=nm; renderLayers(); scheduleSave(); } return; }
    /* v12.4: alpha lock, solo and merge down */
    if(id==="pxLayAlpha"){ pushLayersUndo(); Ls[ST.layer].alphaLock=!Ls[ST.layer].alphaLock; renderLayers(); scheduleSave(); return; }
    if(id==="pxLaySolo"){ ST.solo=(ST.solo===ST.layer)?null:ST.layer; renderLayers(); drawCanvas(); return; }
    if(id==="pxLayMerge"){
      if(ST.layer<1) return;
      pushLayersUndo(); Ls=FR().layers;
      var up2=Ls[ST.layer], dn2=Ls[ST.layer-1], pic2=ST.pic;
      var tmp={w:pic2.w,h:pic2.h,grid:pic2.grid,orient:pic2.orient,shape:pic2.shape,side:pic2.side,
        frames:[{layers:[{visible:true,opacity:100,mode:"view",px:dn2.px},{visible:true,opacity:up2.opacity,mode:up2.mode,px:up2.px}]}]};
      dn2.px=PX().encode(PX().flatten(tmp,0));
      Ls.splice(ST.layer,1); ST.layer=ST.layer-1; ST.solo=null;
      ST.buf=PX().decode(Ls[ST.layer].px,ST.pic.w*ST.pic.h); layerChanged(); ST.status="Merged down"; updateMeta(); return;
    }
    if(id==="pxBack"){ close(); return; }
    if(id==="pxUndo"){ undo(); return; }
    if(id==="pxRedo"){ redo(); return; }
    if(id==="pxMirror"){ var ms=ST.grid.modes, mi=ms.indexOf(ST.mirror); ST.mirror=ms[(mi+1)%ms.length]; renderTools(); drawCanvas(); return; }
    if(id==="pxCursor"){ ST.cursor=!ST.cursor; renderTools(); return; }
    if(id==="pxPalTog"){ ST.palOpen=!ST.palOpen; renderPalette(); return; }
    if(id==="pxZoomIn"){ zoomAt(VIEW.z+Math.max(1,Math.round(VIEW.z*0.25))); return; }
    if(id==="pxZoomOut"){ zoomAt(VIEW.z-Math.max(1,Math.round(VIEW.z*0.2))); return; }
    if(id==="pxFit"){ VIEW=null; fitView(); drawCanvas(); return; }
    if(id==="pxMore"){ ST.menu=!ST.menu; renderMenu(); return; }
    if(id==="pxPrevTog"){ ST.preview=!ST.preview; ST.menu=false; renderMenu(); if(ST.preview){ flushSave(); renderPreview(); } else $("pxPrev").innerHTML=""; return; }
    if(id==="pxPdf"){ if($("pxPdfW")) ST.pdfW=Math.max(0.25,Math.min(7.5,parseFloat($("pxPdfW").value)||2)); ST.menu=false; renderMenu(); exportPdf(); return; }
    var png=t.getAttribute("data-pxpng"); if(png){ ST.menu=false; renderMenu(); exportPng(+png); return; }
    if(id==="pxGridTog"){ ST.showGrid=!ST.showGrid; ST.menu=false; renderMenu(); drawCanvas(); return; }
    if(id==="pxClear"){ ST.menu=false; renderMenu(); pushUndo(); ST.buf.fill(0); afterEdit(); return; }
  });
  document.addEventListener("input",function(e){
    if(e.target && e.target.id==="pxOpac" && ST){ if(!ST.opacDrag){ pushLayersUndo(); ST.opacDrag=true; } var L=FR().layers[ST.layer]; L.opacity=+e.target.value;
      if($("pxOpacV")) $("pxOpacV").textContent=L.opacity+"%"; ST.pic.flat=""; drawCanvas(); scheduleSave(); }
    if(e.target && e.target.id==="pxPickQ"){ var v=e.target.value; renderCardPicker(v); }
    if(e.target && e.target.id==="pxColPick" && $("pxColHex")) $("pxColHex").value=e.target.value;
    if(e.target && e.target.id==="pxText" && ST) ST.text=e.target.value;
    var cs={pxConvBri:"bri", pxConvCon:"con", pxConvSat:"sat"}[e.target&&e.target.id];
    if(cs && CONV){ CONV[cs]=+e.target.value; convRun(); }
    if(e.target && e.target.id==="pxName" && ST){ ST.pic.name=e.target.value; scheduleSave(); }
    if(e.target && e.target.id==="pxRefOp" && ST && ST.pic.ref){ ST.pic.ref.op=+e.target.value; drawCanvas(); scheduleSave(); }
    if(e.target && e.target.id==="pxRefSize" && ST && ST.pic.ref && ST.refImg){
      /* resized about its centre, so it stays where you put it */
      var Rs=ST.pic.ref, cxr=Rs.x+ST.refImg.width*Rs.s/2, cyr=Rs.y+ST.refImg.height*Rs.s/2;
      Rs.s=(Rs.fit||Rs.s)*(+e.target.value)/100; Rs.x=cxr-ST.refImg.width*Rs.s/2; Rs.y=cyr-ST.refImg.height*Rs.s/2; drawCanvas(); scheduleSave(); }
  });
  document.addEventListener("change",function(e){
    /* v14.3: how many frames a second */
    if(e.target && e.target.id==="pxFps" && ST){ var f=Math.max(1,Math.min(60,parseInt(e.target.value,10)||12)); ST.pic.fps=f; e.target.value=f; scheduleSave(); return; }
    if(e.target && e.target.id==="pxMode" && ST){ pushLayersUndo(); FR().layers[ST.layer].mode=e.target.value; ST.pic.flat=""; drawCanvas(); updateMeta(); scheduleSave(); }
    if(e.target && e.target.id==="pxOpac" && ST){ ST.opacDrag=false; renderLayers(); }
    /* v12.5 */
    if(e.target && e.target.id==="pxConvFrom" && CONV){ CONV.from=e.target.value; convRun(); }
    var pv={pxPalSet:"set", pxPalSort:"sort", pxPalVal:"val"}[e.target&&e.target.id];
    if(pv && ST){ var V=palView(); V[pv]=e.target.value; savePalView(V); renderPalette(); }
  });
  window.addEventListener("resize",function(){ if(ST && !ST.choosing && $("pxCanvas")){ fitView(); drawCanvas(); } if(CONV) convDraw(); });
  /* v12.4: the arrow keys nudge a selection, or the whole layer with the Select tool */
  document.addEventListener("keydown",function(e){
    if(!ST || ST.choosing || CONV || !$("pxCanvas") || !HOST || !HOST.classList.contains("on")) return;
    var tg=e.target&&e.target.tagName; if(tg==="INPUT"||tg==="TEXTAREA"||tg==="SELECT") return;
    var dir={ArrowLeft:"l",ArrowRight:"r",ArrowUp:"u",ArrowDown:"d"}[e.key];
    if(!dir || !(ST.sel || ST.tool==="select")) return;
    e.preventDefault(); nudge(dir);
  });

  var BLANK_SQ=[[16,16],[32,32],[64,64],[128,128],[256,256],[64,32],[128,64],[256,144]], BLANK_HEX=[[16,16],[32,32],[64,64]], BLANK_SIDES=[6,12,24,48];
  function renderBlankChooser(){
    var hexOnly=HOMEMODE==="hex", orient=ST.orient||"pointy";
    var num=function(id,v,mx){ return '<input type="number" id="'+id+'" min="1" max="'+(mx||128)+'" value="'+v+'" inputmode="numeric" class="pxnum">'; };
    HOST.innerHTML='<div class="pxs"><h2 class="pxh">Blank canvas</h2>'+
      '<p class="pxnote">For any graphic, not tied to a card \u2014 a loading screen, a logo, a scene. Square pixels up to 256 each way; hex pixels up to 128.</p>'+
      (hexOnly?"":'<p class="pxsub">Square pixels</p><div class="pxrow">'+
        BLANK_SQ.map(function(d){ return '<button class="ghost primary" data-pxwh="'+d[0]+'x'+d[1]+'">'+d[0]+'\u00d7'+d[1]+'</button>'; }).join("")+'</div>'+
        '<div class="pxrow pxcustom">'+num("pxSqW",48,256)+'<span>\u00d7</span>'+num("pxSqH",48,256)+'<button class="ghost" data-pxcustom="square">Create</button></div>')+
      '<p class="pxsub">Hex pixels</p>'+
      '<div class="seg" style="max-width:260px;"><button class="'+(orient==="pointy"?"on":"")+'" data-pxorient="pointy">Pointy-top</button>'+
      '<button class="'+(orient==="flat"?"on":"")+'" data-pxorient="flat">Flat-top</button></div>'+
      '<p class="pxnote">A rectangle, columns by rows:</p><div class="pxrow">'+
        BLANK_HEX.map(function(d){ return '<button class="ghost primary" data-pxhexwh="'+d[0]+'x'+d[1]+'">'+d[0]+'\u00d7'+d[1]+'</button>'; }).join("")+'</div>'+
      '<div class="pxrow pxcustom">'+num("pxHxW",40)+'<span>\u00d7</span>'+num("pxHxH",30)+'<button class="ghost" data-pxcustom="hex">Create</button></div>'+
      '<p class="pxnote">A hexagon, pixels per side:</p><div class="pxrow">'+
        BLANK_SIDES.map(function(n){ return '<button class="ghost primary" data-pxside="'+n+'">'+n+'</button>'; }).join("")+'</div>'+
      '<button class="ghost" id="pxBack">Cancel</button></div>';
  }
  function renderChooser(){
    if(ST.opts && ST.opts.kind==="blank"){ renderBlankChooser(); return; }
    var P=PX(), o=ST.opts, art=o.kind==="art", hexOnly=HOMEMODE==="hex", orient=ST.orient||"pointy";
    /* v12.4: card art is 128 or 64 across, begun square and trimmed at the
       bottom to this card's art box */
    var sq=art ? (P.ART_WIDTHS||[64]).map(function(wd){ return '<button class="ghost'+(wd===128?" primary":"")+'" data-pxartw="'+wd+'">'+wd+' across</button>'; }).join("")
      : P.TOKEN_SIZES.map(function(s){ return '<button class="ghost primary" data-pxsize="'+s+'">'+s+'\u00d7'+s+'</button>'; }).join("");
    var hx=art ? P.HEX_ACROSS.map(function(n){ return '<button class="ghost primary" data-pxacross="'+n+'">'+n+' across</button>'; }).join("")
      : P.HEX_SIDES.map(function(n){ return '<button class="ghost primary" data-pxside="'+n+'">'+n+' per side</button>'; }).join("");
    HOST.innerHTML='<div class="pxs"><h2 class="pxh">'+(art?"Art for "+esc(o.card?o.card.name:"a card"):"New token")+'</h2>'+
      (hexOnly?"":'<p class="pxsub">Square pixels</p><div class="pxrow">'+sq+'</div>'+
        (art?'<p class="pxnote">Begun as a square, with the bottom trimmed so the canvas is exactly the shape of this card\u2019s art box. On the card it is drawn crisp, as large as fits.</p>':''))+
      '<p class="pxsub">Hex pixels'+(art?" \u00b7 a rectangle filling the art box":" \u00b7 a hexagon filling a board tile")+'</p>'+
      '<div class="seg" style="max-width:260px;"><button class="'+(orient==="pointy"?"on":"")+'" data-pxorient="pointy">Pointy-top</button>'+
      '<button class="'+(orient==="flat"?"on":"")+'" data-pxorient="flat">Flat-top</button></div>'+
      '<div class="pxrow">'+hx+'</div>'+
      '<p class="pxnote">'+(art?"Sized to this card\u2019s art box as it is now.":
        "Flat-top pixels build a pointy-top hexagon \u2014 the board\u2019s own shape \u2014 so the token lines up with its tile. Pointy-top pixels build a flat-top hexagon.")+'</p>'+
      '<button class="ghost" id="pxBack">Cancel</button></div>';
  }
  function render(host, opts){
    HOST=host||HOST||$("v-studio"); if(!HOST) return;
    if(opts && opts.mode) HOMEMODE=opts.mode;
    if(!ST) renderHome(); else if(ST.choosing) renderChooser(); else renderEditor();
  }
  /* v13.0: for the Skins and Assets tabs */
  function tab(name){ if(name) STAB=name; if(!ST) show(); return STAB; }
  function fromImage(id){ ST=null; open({id:id, from:(HOMEMODE==="hex"?"hexstudio":"studio")}); if(ST && !ST.choosing) convPick("layer"); }
  function drawCard(card, kind){ ST=null; open({kind:kind, card:{key:card.id||card.name, name:card.name, schema:card}, artHin:kind==="art"?artBoxFor(card):undefined, from:(HOMEMODE==="hex"?"hexstudio":"studio")}); }
  function cardFromImage(card, kind){
    var P=PX(), pic;
    if(kind==="art"){ var sz=P.artSizeFor(artBoxFor(card), ART_W_IN, 128); pic=P.blank(sz.w, sz.h, card.name+" art"); }
    else pic=P.blank(48, 48, card.name+" token");
    pic.kind=kind; pic.grid="square";
    var id=P.put(pic); if(!id) return null; P.link(card, kind, id); fromImage(id); return id;
  }
  window.KETER_STUDIO={open:open, render:render, close:close, tab:tab, fromImage:fromImage, drawCard:drawCard, cardFromImage:cardFromImage, state:function(){ return ST; }, view:function(){ return VIEW; },
    pdfText:function(pic){ return pdfBytes(pic||(ST&&ST.pic)); }, pngCanvas:pngCanvas, flushSave:flushSave, grids:GRIDS,
    _paint:{down:toolDown, move:toolMove, up:toolUp, longPress:longPress, cell:cellFromScreen, undo:undo, redo:redo,
            shapeCells:shapeCells, selAction:selAction, commitSelection:commitSelection, switchLayer:switchLayer,
            footprint:footprint, nudge:nudge, doublePixels:doublePixels, canDouble:canDouble, regionOf:regionOf, scaleSel:scaleSel},
    _ref:{use:useRefData, get:refGet, visible:function(){ return refVisible(); }, db:refDb}, swatches:swatchGroups,
    /* v12.5 */
    _conv:{open:convOpen, run:convRun, create:convCreate, state:function(){ return CONV; }, close:convClose, allowed:function(){ return convAllowed(); }},
    _text:{cells:textCells, place:placeText, fonts:FONTS}, _scale:function(f){ scaleSel(f); },
    _palette:{view:palView, setView:function(v){ savePalView(v); if(ST&&!ST.choosing) renderPalette(); }, sample:sampleRef, add:addMine},
    _view:{table:viewTable, mini:drawMini},
    /* v14.3 */
    _frames:{switchTo:function(i){ switchFrame(i); renderFrames(); renderLayers(); drawCanvas(); updateMeta(); }, add:addFrame, del:deleteFrame, move:moveFrame,
             play:startPlaying, stop:stopPlaying, views:function(){ return canvasViews(); }, onion:function(){ return onionShown(); }, render:renderFrames}};
})();
