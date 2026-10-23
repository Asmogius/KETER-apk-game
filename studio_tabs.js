/* ===========================================================================
   The Pixel Studio's Skins and Assets tabs (v13.0).

   Skins: every skin, by body plan, Hero and Enemy, with its colour variants.
   Dev Mode draws them (Draw, From an image), tags body-plan skins with roles,
   makes variants with the recolour tool, and deletes. Players see them all
   but change nothing: they choose in the Workshop and on a Hero's card.

   Assets: every graphic the game uses — skins, card art, the World Map's art
   and your own slots — marked drawn or missing, and Export for Godot.
   =========================================================================== */
(function(){
  "use strict";
  var PX=function(){ return window.KETER_PX; }, SK=function(){ return window.KETER_SKINS; }, AS=function(){ return window.KETER_ASSETS; }, ST=function(){ return window.KETER_STUDIO; };
  var HOST=null, TAB="skins", OWN="body", EDIT=null, RC=null, QH="", QE="", AF="skins", MISSING=false, QC="", MSG="";
  var NEW_KEY="keter-app-skin-new";
  function esc(s){ return String(s==null?"":s).replace(/[&<>"]/g,function(c){ return {"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;"}[c]; }); }
  function dev(){ try{ return window.KETER_PROG ? window.KETER_PROG.dev() : localStorage.getItem("keter-app-dev")==="1"; }catch(e){ return false; } }
  function cards(){ try{ return window.KETER_ALLCARDS?window.KETER_ALLCARDS():[]; }catch(e){ return []; } }
  function uniq(list){ var s={}; return list.filter(function(c){ if(!c||s[c.name]) return false; s[c.name]=1; return true; }); }
  function heroes(){ return uniq(cards().filter(function(c){ return /^hero$/i.test(c.cardType||""); })).sort(function(a,b){ return a.name.localeCompare(b.name); }); }
  function enemies(){ return uniq(cards().filter(function(c){ return /^(enemy|elite|miniboss|boss)$/i.test(c.cardType||""); })).sort(function(a,b){ return a.name.localeCompare(b.name); }); }
  /* v14.1: a new skin's token is 48 by 48, the size the game draws every Unit at */
  function newSizes(){ var o={art:128, token:"48"}; try{ Object.assign(o, JSON.parse(localStorage.getItem(NEW_KEY)||"{}")); }catch(e){} return o; }

  function render(host, tab){ HOST=host||HOST; if(tab) TAB=tab; if(!HOST) return; draw(); }
  function draw(){
    if(!HOST || !document.body.contains(HOST)){ var h=document.getElementById("pxTab"); if(!h) return; HOST=h; }
    HOST.innerHTML=(MSG?'<p class="wsmsg">'+MSG+'</p>':'')+(TAB==="skins"?skinsHTML():assetsHTML());
    thumbs();
  }
  /* every thumbnail: data-pxt="picture id" on a canvas */
  function thumbs(){
    var P=PX(); if(!HOST) return;
    [].slice.call(HOST.querySelectorAll("canvas[data-pxt]")).forEach(function(c){
      var g=c.getContext("2d"), pic=P.get(c.getAttribute("data-pxt")), map=c.getAttribute("data-map");
      g.fillStyle="#0e1418"; g.fillRect(0,0,c.width,c.height); if(!pic) return;
      if(map){ pic=mapped(pic, JSON.parse(map)); }
      /* v14.3: a picture of several frames shows the one in the middle (its first is often only a spark) */
      var nf=P.frameCount?P.frameCount(pic):1;
      if(nf>1 && !P.isHex(pic)){ var mid=Math.floor(nf/2), s=Math.max(1,Math.floor(Math.min((c.width-4)/pic.w,(c.height-4)/pic.h))), w=pic.w*s, h=pic.h*s;
        g.imageSmoothingEnabled=false; g.drawImage(P.frameSprite(pic,mid),Math.round((c.width-w)/2),Math.round((c.height-h)/2),w,h); return; }
      P.draw(g,pic,2,2,c.width-4,c.height-4,1,{minFill:0.5});
    });
  }
  /* a picture with colours swapped, for the recolour preview (not saved) */
  function mapped(pic, m){
    var P=PX(), c=JSON.parse(JSON.stringify(pic)), n=c.w*c.h, a=P.decode(c.flat||P.refreshFlat(c), n);
    for(var i=0;i<n;i++){ var t=m[a[i]]; if(t!==undefined) a[i]=+t; }
    c.flat=P.encode(a); c.id=(pic.id||"x")+":rc"; c.saved=JSON.stringify(m); return c;
  }
  function thumb(id, w, h, map){ return id&&PX().get(id) ? '<canvas data-pxt="'+esc(id)+'" width="'+w+'" height="'+h+'"'+(map?' data-map="'+esc(JSON.stringify(map))+'"':'')+'></canvas>' : '<span class="skmiss" style="width:'+w+'px;height:'+h+'px;">none</span>'; }

  /* ================= Skins ================= */
  function skinsHTML(){
    var S=SK(); if(!S) return '<p class="pxnote">Skins aren’t loaded.</p>';
    var seg=function(k,l){ return '<button class="'+(OWN===k?"on":"")+'" data-sko="'+k+'">'+l+'</button>'; };
    var h='<p class="pxnote">A skin is a card art and a board token that go together, in one or more colour variants. '+(dev()?'You draw them here; players choose, in the Workshop for a design and on a Hero’s card.':'Choose a design’s skin in the Workshop, and a Hero’s on its card in the Compendium. Only Dev Mode can draw them.')+'</p>';
    if(RC) return h+recolourHTML();
    if(dev()){ var ns=newSizes();
      h+='<div class="pxrow skset"><span>New skins:</span><select id="skNewArt" class="ltsel"><option value="128"'+(ns.art==128?" selected":"")+'>art 128 across</option><option value="64"'+(ns.art==64?" selected":"")+'>art 64 across</option></select>'+
        '<select id="skNewTok" class="ltsel"><option value="48"'+(ns.token==="48"?" selected":"")+'>token 48×48</option><option value="hex"'+(ns.token==="hex"?" selected":"")+'>token hex, 9 per side</option><option value="32"'+(ns.token==="32"?" selected":"")+'>token 32×32</option><option value="24"'+(ns.token==="24"?" selected":"")+'>token 24×24</option><option value="16"'+(ns.token==="16"?" selected":"")+'>token 16×16</option></select></div>'; }
    h+='<div class="seg pxseg">'+seg("body","Body plans")+seg("hero","Heroes")+seg("enemy","Enemies")+'</div>';
    if(OWN==="body"){
      h+=S.BODY_PLANS.map(function(bp){ var list=S.forOwner("body",bp);
        return '<p class="pxsub">'+esc(bp)+' · '+list.length+' skin'+(list.length===1?'':'s')+'</p><div class="sklist">'+list.map(skinHTML).join("")+'</div>'+
          (dev()?'<div class="pxrow"><button class="ghost" data-sknew="body|'+esc(bp)+'">New '+esc(bp)+' skin</button></div>':''); }).join("");
      if(dev() && S.state().gone.length) h+='<div class="pxrow"><button class="ghost" id="skRestore">Bring back the stand-ins</button></div>';
    } else if(OWN==="hero"){
      var hs=heroes().filter(function(c){ return !QH || c.name.toLowerCase().indexOf(QH.toLowerCase())>=0; });
      h+='<input id="skQH" class="skq" placeholder="Find a Hero" value="'+esc(QH)+'">'+hs.map(function(c){ var list=S.forOwner("hero",c.name), own=S.picFor&&PX().pictureFor(c,"art");
        return '<p class="pxsub">'+esc(c.name)+' · '+list.length+' skin'+(list.length===1?'':'s')+'</p><div class="sklist"><div class="skcard skown"><div class="skvars"><div class="skvar">'+thumb(own&&own.id,64,44)+thumb((PX().pictureFor(c,"token")||{}).id,52,52)+'<i>The card’s own</i></div></div></div>'+list.map(skinHTML).join("")+'</div>'+
          (dev()?'<div class="pxrow"><button class="ghost" data-sknew="hero|'+esc(c.name)+'">New skin for '+esc(c.name)+'</button></div>':''); }).join("");
    } else {
      var S2=S, with_=enemies().filter(function(c){ return S2.forOwner("enemy",c.name).length; });
      var hits=QE?enemies().filter(function(c){ return c.name.toLowerCase().indexOf(QE.toLowerCase())>=0; }).slice(0,12):[];
      var shown=uniq(with_.concat(hits));
      h+='<p class="pxnote">An Enemy wears a random look each time it spawns: its card’s own token or one of these.</p><input id="skQE" class="skq" placeholder="Find an Enemy" value="'+esc(QE)+'">'+
        (shown.length?shown.map(function(c){ var list=S.forOwner("enemy",c.name);
          return '<p class="pxsub">'+esc(c.name)+' · '+esc(c.cardType)+' · '+list.length+' skin'+(list.length===1?'':'s')+'</p><div class="sklist">'+list.map(skinHTML).join("")+'</div>'+
            (dev()?'<div class="pxrow"><button class="ghost" data-sknew="enemy|'+esc(c.name)+'">New skin for '+esc(c.name)+'</button></div>':''); }).join(""):'<p class="pxnote">No Enemy has a skin yet. Find one to '+(dev()?'give it one.':'see it.')+'</p>');
    }
    return h;
  }
  function skinHTML(k){
    var S=SK(), open=EDIT===k.id && dev();
    var h='<div class="skcard'+(open?" on":"")+'"><div class="sktop"><b>'+esc(k.name)+'</b>'+(k.builtin?'<i class="sktag">stand-in</i>':'')+
      (k.roles||[]).map(function(r){ return '<i class="sktag">'+esc(r)+'</i>'; }).join("")+
      (dev()?'<button class="ghost" data-skedit="'+esc(k.id)+'">'+(open?"Done":"Edit")+'</button>':'')+'</div>';
    h+='<div class="skvars">'+k.variants.map(function(v){
      return '<div class="skvar">'+thumb(v.art,64,44)+thumb(v.token,52,52)+'<i>'+esc(v.name)+'</i>'+
        (open?'<div class="skbtns"><button class="ghost" data-skdraw="'+esc(k.id+"|"+v.id+"|art")+'">Draw art</button><button class="ghost" data-skimg="'+esc(k.id+"|"+v.id+"|art")+'">Art from an image</button>'+
          '<button class="ghost" data-skdraw="'+esc(k.id+"|"+v.id+"|token")+'">Draw token</button><button class="ghost" data-skimg="'+esc(k.id+"|"+v.id+"|token")+'">Token from an image</button>'+
          '<button class="ghost" data-skvar="'+esc(k.id+"|"+v.id)+'">Make a variant</button>'+
          (k.variants.length>1?'<button class="ghost" data-skrc="'+esc(k.id+"|"+v.id)+'">Recolour</button><button class="ghost" data-skvdel="'+esc(k.id+"|"+v.id)+'">Delete variant</button>':'')+
          '<input class="skvname" data-skvname="'+esc(k.id+"|"+v.id)+'" value="'+esc(v.name)+'" aria-label="Variant name"></div>':'')+'</div>';
    }).join("")+'</div>';
    if(open){
      h+='<div class="skedit"><label class="chf"><span>Name</span><input data-skname="'+esc(k.id)+'" value="'+esc(k.name)+'"></label>';
      if(k.owner.kind==="body") h+='<p class="pxnote">Roles it suits (offered first to designs with them):</p><div class="chchips">'+S.ROLES.map(function(r){ var on=(k.roles||[]).indexOf(r)>=0;
        return '<button class="ghost chchip'+(on?" on":"")+'" data-skrole="'+esc(k.id+"|"+r)+'">'+esc(r)+'</button>'; }).join("")+'</div>';
      h+='<div class="pxrow"><button class="ghost" data-skup="'+esc(k.id)+'">Move up</button><button class="ghost" data-skdel="'+esc(k.id)+'">Delete skin</button></div></div>';
    }
    return h+'</div>';
  }
  /* the recolour tool: tap a colour it uses, then the colour to swap in */
  function recolourHTML(){
    var S=SK(), P=PX(), k=S.get(RC.skin), v=S.variantOf(k,RC.variant); if(!v){ RC=null; return ""; }
    var used=S.colours(RC.skin, RC.variant), sw=function(c,attr,on,extra){ return '<button class="skcol'+(on?" on":"")+'" '+attr+' style="background:'+(P.PALETTE[c]||"transparent")+'" title="'+esc(P.nameOf?P.nameOf(c):c)+'">'+(extra||"")+'</button>'; };
    var h='<div class="skrc"><p class="pxsub">Recolour '+esc(k.name)+' · '+esc(v.name)+'</p>'+
      '<div class="skrcprev">'+thumb(v.art,128,86,RC.map)+thumb(v.token,64,64,RC.map)+'</div>'+
      '<p class="pxnote">Tap a colour it uses, then the colour to put in its place. Every layer of its art and token changes together.</p>'+
      '<div class="skrow">'+used.map(function(u){ var to=RC.map[u.c]; return '<span class="skpair">'+sw(u.c,'data-skfrom="'+u.c+'"',RC.sel===u.c)+(to!==undefined?'→'+sw(to,'data-skfrom="'+u.c+'"',false):'')+'</span>'; }).join("")+'</div>';
    if(RC.sel!=null){ var pal=[]; for(var i=1;i<=P.PAL_MAX;i++) if(P.PALETTE[i]) pal.push(i);
      h+='<p class="pxnote">Swap in:</p><div class="skpal">'+pal.map(function(c){ return sw(c,'data-skto="'+c+'"',RC.map[RC.sel]===c); }).join("")+'</div>'; }
    return h+'<div class="pxrow"><button class="ghost primary" id="skRcGo">Apply</button><button class="ghost" id="skRcReset">Start over</button><button class="ghost" id="skRcX">Cancel</button></div></div>';
  }
  /* a blank art or token for a skin variant, sized by the New skins settings */
  function blankFor(k, v, kind){
    var P=PX(), ns=newSizes(), pic;
    if(kind==="art"){ var sz=P.artSizeFor(1.52, 2.27, +ns.art===64?64:128); pic=P.blank(sz.w, sz.h, k.name+" · "+v.name+" art"); pic.kind="art"; pic.grid="square"; }
    else if(ns.token==="hex"){ pic=P.blankHexagon(9,"flat",k.name+" · "+v.name+" token"); pic.kind="token"; }
    else { var n=+ns.token||32; pic=P.blank(n,n,k.name+" · "+v.name+" token"); pic.kind="token"; pic.grid="square"; }
    var id=P.put(pic); if(id) SK().setPic(k.id, v.id, kind, id); return id;
  }
  function ensurePic(ref){
    var p=ref.split("|"), S=SK(), k=S.get(p[0]), v=S.variantOf(k,p[1]); if(!v) return null;
    return (v[p[2]] && PX().get(v[p[2]])) ? v[p[2]] : blankFor(k, v, p[2]);
  }

  /* ================= Assets ================= */
  function assetsHTML(){
    var A=AS(); if(!A) return '<p class="pxnote">Assets aren’t loaded.</p>';
    var all=A.entries(), drawn=all.filter(function(e){ return e.pic; }).length;
    var seg=function(k,l){ var n=all.filter(function(e){ return grp(e)===k; }), d=n.filter(function(e){ return e.pic; }).length; return '<button class="'+(AF===k?"on":"")+'" data-asf="'+k+'">'+l+' <i>'+d+'/'+n.length+'</i></button>'; };
    var h='<p class="pxnote">Every graphic the game uses, drawn or still missing: '+drawn+' of '+all.length+' drawn.'+(dev()?'':' Only Dev Mode can draw them.')+'</p>'+
      '<div class="pxrow"><button class="ghost primary" id="asExport">Export for Godot</button></div>'+
      '<p class="pxnote">One zip for the game: a PNG of every drawn graphic at its true size, in folders by kind; the content (cards, floors, the world map, chassis, pools, tables and skins) in content/; and manifest.json saying what each file is. Hex pictures are drawn 4 pixels to a hex’s half-width. Drop the zip into the game’s folder as it is.</p>'+
      '<div class="seg pxseg">'+seg("skins","Skins")+seg("cards","Cards")+seg("map","World Map")+seg("ui","Game look")+seg("fight","The fight")+seg("district","District fights")+seg("effects","Effects")+seg("custom","Your slots")+'</div>'+
      '<label class="wldchk"><input type="checkbox" id="asMiss"'+(MISSING?" checked":"")+'> Missing only</label>';
    if(AF==="skins") h+=skinRowsHTML();
    else if(AF==="cards") h+=cardRowsHTML();
    else h+=slotRowsHTML(AF);
    return h;
  }
  function grp(e){ return e.group; }
  function skinRowsHTML(){
    var S=SK(), rows=[];
    S.all().forEach(function(k){ k.variants.forEach(function(v){ var miss=!(v.art&&PX().get(v.art))||!(v.token&&PX().get(v.token)); if(MISSING && !miss) return;
      rows.push('<div class="asrow"><span><b>'+esc(k.name)+(k.variants.length>1?' · '+esc(v.name):'')+'</b><i>'+esc(S.KIND_LABEL[k.owner.kind])+': '+esc(k.owner.key)+'</i></span>'+
        '<span class="asth">'+thumb(v.art,64,44)+thumb(v.token,52,52)+'</span>'+
        (dev()?'<span class="asbtns"><button class="ghost" data-skdraw="'+esc(k.id+"|"+v.id+"|art")+'">Art</button><button class="ghost" data-skimg="'+esc(k.id+"|"+v.id+"|art")+'">Art from an image</button>'+
          '<button class="ghost" data-skdraw="'+esc(k.id+"|"+v.id+"|token")+'">Token</button><button class="ghost" data-skimg="'+esc(k.id+"|"+v.id+"|token")+'">Token from an image</button></span>':'')+'</div>'); }); });
    return rows.length?'<div class="aslist">'+rows.join("")+'</div>':'<p class="pxnote">Nothing missing.</p>';
  }
  function cardRowsHTML(){
    var A=AS(), P=PX(), list=A.cardList().filter(function(c){ return !QC || c.name.toLowerCase().indexOf(QC.toLowerCase())>=0; }), rows=[];
    list.forEach(function(c){
      var kinds=A.isUnit(c)?["art","token"]:["art"], pics=kinds.map(function(kd){ return P.pictureFor(c,kd)||(c._raw?P.pictureFor(c._raw,kd):null); });
      if(MISSING && pics.every(Boolean)) return;
      var i=cards().indexOf(c);
      rows.push('<div class="asrow"><span><b>'+esc(c.name)+'</b><i>'+esc(c.cardType||"")+' · '+esc(c._src==="test"?"test card":c._src==="mine"?"your card":"master")+'</i></span>'+
        '<span class="asth">'+thumb(pics[0]&&pics[0].id,64,44)+(kinds.length>1?thumb(pics[1]&&pics[1].id,52,52):'')+'</span>'+
        (dev()?'<span class="asbtns">'+kinds.map(function(kd){ return '<button class="ghost" data-ascard="'+esc(c.name+"|"+(c._src||"")+"|"+kd)+'">'+(kd==="art"?"Art":"Token")+'</button><button class="ghost" data-ascardimg="'+esc(c.name+"|"+(c._src||"")+"|"+kd)+'">'+(kd==="art"?"Art":"Token")+' from an image</button>'; }).join("")+'</span>':'')+'</div>');
    });
    return '<input id="asQC" class="skq" placeholder="Find a card" value="'+esc(QC)+'">'+(rows.length?'<div class="aslist">'+rows.slice(0,80).join("")+'</div>'+(rows.length>80?'<p class="pxnote">'+(rows.length-80)+' more: narrow it with a name.</p>':''):'<p class="pxnote">Nothing here.</p>');
  }
  function slotRowsHTML(group){
    var A=AS(), rows=A.slots().filter(function(s){ return s.group===group; }).map(function(sl){
      var ids=A.ids(sl.id); if(MISSING && ids.length) return "";
      var size=sl.kind==="hex"?"hex pixels, "+sl.side+" per side":sl.w+"×"+sl.h;
      /* v14.3: an effect: how many frames, and how fast (what the slot starts with; the picture may differ) */
      if(sl.frames){ var p0=ids.length?PX().get(ids[0]):null, nf=p0&&PX().frameCount?PX().frameCount(p0):sl.frames;
        size+=" · "+nf+" frame"+(nf===1?"":"s")+" at "+((p0&&p0.fps)||sl.fps||12)+" a second"; }
      return '<div class="asrow asslot"><span><b>'+esc(sl.name)+'</b><i>'+esc(size)+(sl.multi?' · several, scattered at random':'')+(sl.what?' · '+esc(sl.what):'')+'</i></span>'+
        '<span class="asth">'+(ids.length?ids.map(function(id){ return '<span class="aspic">'+thumb(id,48,48)+(dev()?'<button class="ghost" data-asopen="'+esc(id)+'">Open</button><button class="ghost" data-asrm="'+esc(sl.id+"|"+id)+'">Remove</button>':'')+'</span>'; }).join(""):'<span class="skmiss" style="width:48px;height:48px;">none</span>')+'</span>'+
        (dev()?'<span class="asbtns"><button class="ghost" data-asnew="'+esc(sl.id)+'">'+(ids.length?(sl.multi?"Draw another":"Draw it again"):"Draw")+'</button><button class="ghost" data-asimg="'+esc(sl.id)+'">From an image</button>'+
          (group==="custom"?'<button class="ghost" data-ascdel="'+esc(sl.id)+'">Delete slot</button>':'')+'</span>':'')+'</div>';
    }).join("");
    var h=rows?'<div class="aslist">'+rows+'</div>':'<p class="pxnote">'+(group==="custom"?'No slots of your own yet.':'Nothing missing.')+'</p>';
    if(group==="map") h='<p class="pxnote">The World Map as the game draws it. Ground and collapsed tiles are hex pixels that fill a map tile, several to a slot, scattered at random. A District’s things (square, 32 by 32) stand on one empty tile in five; what a tile holds is a 16 by 16 icon on a plate in its colour; the dock is the Hangar, 64 by 64, standing on its tile: each drawn on the map at twice its size, its foot near the bottom. The game’s own are in their slots: draw over one and the game uses yours. In a slot of several, once one is yours the export carries them all, and the game uses that slot’s.</p>'+h;
    if(group==="ui") h='<p class="pxnote">The game’s own look: Home’s title picture, the backdrops behind the dock and the other screens, the floor under a fight, the icons it shows amounts with, each Status’s icon and its mark on the board, the Aether gems, the fight bar’s and the roles’ icons, the turn strip’s and End turn’s icons, a picture for each kind of card that has no art of its own, QM-7 (the dock’s keeper) and its blink, Victory and Defeat, the gear and each District’s emblem. The game draws each of these itself; one drawn here is used in its place, at whole multiples of its pixels (a backdrop, 256 by 144, fills the screen at five times). The game’s own are in their slots already: open one to draw over it.</p>'+h;
    if(group==="fight") h='<p class="pxnote">A fight, as the game draws it: each tile’s deck plate, the spawn pads and the hazards, cover, crates, Locked Chests, the Emergency Exit and the Healing Station, and the four stand-ins for a Unit with no token. Square pixels, drawn on the board at twice their size. The game’s own are in their slots: draw over one and the game uses yours. Export for Godot carries only those you have drawn on.</p>'+h;
    if(group==="effects") h='<p class="pxnote">The fight’s effects, each drawn frame by frame and played at its speed: the muzzle flash as a shot leaves, the impact where damage lands, the explosion on every tile a blast catches (and where a shell comes down), the heal rising from whoever is mended and the shield as an attack glances off armour. Square pixels, drawn on the board at twice their size, in their own colours (the shot keeps its side’s). Open one to see its frames in the strip under the canvas: add, copy, move or delete them, set how many a second, and play them. The game’s own are in their slots: draw over one and the game plays yours, its frames side by side in the export.</p>'+h;
    if(group==="district") h='<p class="pxnote">Each District’s fights: five floor plates (every tile wears one, the first most often, the last seldom) and its own Half and Full Cover. Square pixels, drawn on the board at twice their size. Hazards, spawn pads, crates, chests, Exits and Healing Stations are the same in every District (under The fight), and a floor in no District keeps the grey deck. The game’s own are in their slots: draw over one and the game uses yours.</p>'+h;
    if(group==="custom" && dev()) h+='<div class="wldform"><b>Add a slot</b><input id="asCName" placeholder="Name, e.g. Loading screen 1">'+
      '<select id="asCKind" class="ltsel"><option value="square">Square pixels</option><option value="hex">Hex pixels (a hexagon)</option></select>'+
      '<div class="pxrow"><label class="chf"><span>Width</span><input id="asCW" type="number" min="1" max="256" value="256"></label><label class="chf"><span>Height</span><input id="asCH" type="number" min="1" max="256" value="256"></label><label class="chf"><span>Hex side</span><input id="asCS" type="number" min="2" max="32" value="9"></label></div>'+
      '<button class="ghost primary" id="asCAdd">Add the slot</button></div>';
    return h;
  }
  function cardByKey(s){ var p=s.split("|"); return {card:cards().filter(function(c){ return c.name===p[0] && (c._src||"")===p[1]; })[0]||null, kind:p[2]}; }

  /* ================= taps ================= */
  document.addEventListener("click",function(e){
    if(!HOST || !HOST.contains(e.target)) return;
    var t=e.target.closest?e.target.closest("button"):null; if(!t) return;
    var a, S=SK(), A=AS(), id=t.id; MSG="";
    if((a=t.getAttribute("data-sko"))){ OWN=a; EDIT=null; draw(); return; }
    if((a=t.getAttribute("data-asf"))){ AF=a; draw(); return; }
    if(id==="asExport"){ var r=A.download(); MSG="Exported "+r.count+" graphic"+(r.count===1?"":"s")+", "+r.content+" kinds of content and a manifest."; draw(); return; }
    if(!dev()) return;
    if((a=t.getAttribute("data-sknew"))){ var p=a.split("|"), k=S.add({kind:p[0], key:p.slice(1).join("|")}, p[0]==="body"?p[1]+" skin":p.slice(1).join("|")+" skin"); EDIT=k.id; draw(); return; }
    if((a=t.getAttribute("data-skedit"))){ EDIT=EDIT===a?null:a; draw(); return; }
    if((a=t.getAttribute("data-skdraw"))){ var pid=ensurePic(a); if(pid) ST().open({id:pid, from:"studio"}); return; }
    if((a=t.getAttribute("data-skimg"))){ var pid2=ensurePic(a); if(pid2) ST().fromImage(pid2); return; }
    if((a=t.getAttribute("data-skvar"))){ var q=a.split("|"), v=S.addVariant(q[0],q[1]); if(v){ RC={skin:q[0], variant:v.id, map:{}, sel:null}; } draw(); return; }
    if((a=t.getAttribute("data-skrc"))){ var q2=a.split("|"); RC={skin:q2[0], variant:q2[1], map:{}, sel:null}; draw(); return; }
    if((a=t.getAttribute("data-skvdel"))){ var q3=a.split("|"); if(confirm("Delete this variant? Designs wearing it go back to the skin’s first variant.")){ S.removeVariant(q3[0],q3[1]); } draw(); return; }
    if((a=t.getAttribute("data-skrole"))){ var q4=a.split("|"); S.update(q4[0],function(k){ var i=k.roles.indexOf(q4[1]); if(i>=0) k.roles.splice(i,1); else k.roles.push(q4[1]); }); draw(); return; }
    if((a=t.getAttribute("data-skup"))){ var kk=S.get(a), sib=S.forOwner(kk.owner.kind,kk.owner.key), i=sib.map(function(x){ return x.id; }).indexOf(a);
      if(i>0){ sib.splice(i-1,0,sib.splice(i,1)[0]); sib.forEach(function(x,j){ S.update(x.id,function(y){ y.order=j; }); }); } draw(); return; }
    if((a=t.getAttribute("data-skdel"))){ var k2=S.get(a); if(confirm("Delete the skin “"+(k2?k2.name:"")+"”? Anything wearing it goes back to the first skin on offer. Its pictures stay in the library.")){ S.remove(a); EDIT=null; } draw(); return; }
    if(id==="skRestore"){ S.restoreBuiltins(); draw(); return; }
    if((a=t.getAttribute("data-skfrom"))!==null && RC){ RC.sel=+a; draw(); return; }
    if((a=t.getAttribute("data-skto"))!==null && RC && RC.sel!=null){ if(+a===RC.sel) delete RC.map[RC.sel]; else RC.map[RC.sel]=+a; draw(); return; }
    if(id==="skRcGo" && RC){ var n=S.recolour(RC.skin, RC.variant, RC.map); MSG=n?"Recoloured. Open its art or token to touch it up.":"Nothing to change."; EDIT=RC.skin; RC=null; draw(); return; }
    if(id==="skRcReset" && RC){ RC.map={}; RC.sel=null; draw(); return; }
    if(id==="skRcX"){ RC=null; draw(); return; }
    /* assets */
    if((a=t.getAttribute("data-ascard"))){ var ck=cardByKey(a); if(ck.card) ST().drawCard(ck.card, ck.kind); return; }
    if((a=t.getAttribute("data-ascardimg"))){ var ck2=cardByKey(a); if(ck2.card) ST().cardFromImage(ck2.card, ck2.kind); return; }
    if((a=t.getAttribute("data-asnew"))){ var np=A.newPicture(a); if(np) ST().open({id:np, from:"studio"}); return; }
    if((a=t.getAttribute("data-asimg"))){ var np2=A.newPicture(a); if(np2) ST().fromImage(np2); return; }
    if((a=t.getAttribute("data-asopen"))){ ST().open({id:a, from:"studio"}); return; }
    if((a=t.getAttribute("data-asrm"))){ var r2=a.split("|"); if(confirm("Take this picture out of the slot? It stays in the library.")){ A.detach(r2[0], r2[1], false); } draw(); return; }
    if((a=t.getAttribute("data-ascdel"))){ if(confirm("Delete this slot? Its pictures stay in the library.")){ A.removeCustom(a); } draw(); return; }
    if(id==="asCAdd"){ var g=function(x){ var el=document.getElementById(x); return el?el.value:""; };
      A.addCustom({name:g("asCName"), kind:g("asCKind"), w:g("asCW"), h:g("asCH"), side:g("asCS")}); MSG="Slot added."; draw(); return; }
  });
  document.addEventListener("change",function(e){
    if(!HOST || !HOST.contains(e.target)) return;
    var el=e.target, a, S=SK();
    if(el.id==="asMiss"){ MISSING=el.checked; draw(); return; }
    if(!dev()) return;
    if(el.id==="skNewArt"||el.id==="skNewTok"){ var ns=newSizes(); if(el.id==="skNewArt") ns.art=+el.value; else ns.token=el.value; try{ localStorage.setItem(NEW_KEY,JSON.stringify(ns)); }catch(x){} return; }
    if((a=el.getAttribute("data-skname"))){ S.update(a,function(k){ k.name=el.value.trim()||k.name; }); draw(); return; }
    if((a=el.getAttribute("data-skvname"))){ var p=a.split("|"); S.update(p[0],function(k){ var v=S.variantOf(k,p[1]); if(v) v.name=el.value.trim()||v.name; }); draw(); return; }
  });
  document.addEventListener("input",function(e){
    if(!HOST || !HOST.contains(e.target)) return;
    var el=e.target, pos=el.selectionStart;
    if(el.id==="skQH"||el.id==="skQE"||el.id==="asQC"){ if(el.id==="skQH") QH=el.value; else if(el.id==="skQE") QE=el.value; else QC=el.value;
      var keep=el.id; draw(); var n=document.getElementById(keep); if(n){ n.focus(); try{ n.setSelectionRange(pos,pos); }catch(x){} } }
  });
  window.KETER_STUDIO_TABS={render:render, state:function(){ return {tab:TAB, own:OWN, edit:EDIT, rc:RC, af:AF, msg:MSG}; }, _rc:function(o){ RC=o; draw(); }};
})();
