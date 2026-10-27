/* ===========================================================================
   The World Map page (v12.8): the colony map, deploying, walking, and what
   happens on each tile. Dev Mode adds the map tools: a new map, editing it in
   the Sandbox, Unique POIs, the Events, and the world's tables.
   =========================================================================== */
(function(){
  "use strict";
  var W=function(){ return window.KETER_WORLD; }, D=function(){ return window.KETER_DEPLOY; };
  var L=function(){ return window.KETER_LOOT; }, P=function(){ return window.KETER_PROG; };
  var HOST=null, VIEW={size:0, cx:0, cy:0, w:0, h:0, ready:false}, SEL=null, MODE="map", PICK=null, PACK={};
  var K=function(){ return window.KETER_DOCK; };
  var WALK=null, NOTE="", EVOUT=null, PLACING=null, UQEDIT=null, EVEDIT=null, SHOWLOG=false, PTR={}, DRAG=null;
  var SQ3=Math.sqrt(3);
  function esc(s){ return String(s==null?"":s).replace(/[&<>"]/g,function(c){ return {"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;"}[c]; }); }
  function $(id){ return document.getElementById(id); }
  function dev(){ return !!(P() && P().dev()); }
  function cur(){ return D()?D().cur():null; }
  function dName(d){ return d ? "District "+d+" · "+(W().DISTRICT_NAMES[d]||"") : "No District"; }
  function plural(n,w,ws){ return n+" "+(n===1?w:(ws||w+"s")); }
  function bagText(b){ var t=L().text(L().norm(b)); return t||"nothing"; }

  /* ---- the page ---- */
  function render(host){
    HOST=host||HOST||$("v-world"); if(!HOST) return;
    HOST.innerHTML='<div class="lts wld">'+
      '<h2 class="pxh">World Map</h2>'+
      '<div id="wldStatus"></div>'+
      '<div id="wldDeploy"></div>'+
      '<div id="wldMapBox" class="wldmap"><canvas id="wldCv"></canvas>'+
        '<div class="wldzoom"><button class="ghost" data-wlz="in" aria-label="Zoom in">+</button><button class="ghost" data-wlz="out" aria-label="Zoom out">−</button>'+
        '<button class="ghost" data-wlz="fit">Fit</button><button class="ghost" data-wlz="team">Team</button></div></div>'+
      '<div id="wldPanel" class="wldpanel"></div>'+
      '<div id="wldLegend" class="wldlegend"></div>'+
      '<div id="wldDev"></div></div>';
    VIEW.ready=false;
    var s=cur(); if(s && !SEL) SEL=s.pos;
    refresh();
  }
  function refresh(){
    if(!HOST || !$("wldStatus")) return;
    $("wldStatus").innerHTML=statusHTML();
    $("wldDeploy").innerHTML=MODE==="deploy"?deployHTML():"";
    $("wldMapBox").style.display=MODE==="deploy"?"none":"";
    $("wldPanel").style.display=MODE==="deploy"?"none":"";
    $("wldPanel").innerHTML=panelHTML();
    $("wldLegend").innerHTML=legendHTML();
    $("wldDev").innerHTML=dev()?devHTML():"";
    if(MODE!=="deploy"){ sizeCanvas(); paint(); }
  }

  /* ---- the deployment, or the dock ---- */
  function statusHTML(){
    var s=cur(), st=W().state();
    if(!s){
      var last=D().last(), dc=W().districtsCleared?W().districtsCleared().length:0, h='<div class="wldstat"><p><b>At the dock.</b> '+plural(st.completed,"deployment")+' so far.</p>'+
        /* (v14.23) how far the campaign has come */
        '<p class="wldgoal">'+(dc>=6?'The colony is safe: every District cleared.':dc+' of 6 Districts cleared. Beat a District\'s Core (★, at its far edge) to clear it.')+'</p>';
      if(last && last.result==="wipe") h+='<p class="wldbad">Deployment '+last.n+' was wiped out: its haul was lost.</p>';
      else if(last && last.result==="home") h+='<p class="wldok">Deployment '+last.n+' came home.</p>';
      var wait=K()?K().waiting():{}, nw=Object.keys(wait).reduce(function(a,id){ return a+(wait[id]||0); },0);
      if(nw) h+='<p>'+plural(nw,"pre-built copy","pre-built copies")+' waiting to join the next deployment.</p>';
      return h+(MODE==="deploy"?'':'<div class="pxrow"><button class="ghost primary" id="wlDeploy">Deploy</button>'+(K()?'<button class="ghost" data-page="dock">Dock</button>':'')+'</div>')+'</div>';
    }
    var X=L(), haul=X.norm(s.haul), heroes=D().heroRefs(s), all=heroes.length+s.heroesOut.length;
    var copies=(s.lines||[]).concat(s.preLines||[]).map(function(l){ return esc(l.name)+' '+D().copiesLeft(l.id)+'/'+l.copies; }).join(" · ");
    var pk=s.pack||{}, packed=Object.keys(pk.protos||{}).map(function(n){ return esc(n)+(pk.protos[n]>1?' ×'+pk.protos[n]:''); })
      .concat(Object.keys(pk.cons||{}).map(function(n){ return esc(n)+' ×'+pk.cons[n]; })).join(" · ");
    return '<div class="wldstat wldout"><p><b>Deployment '+s.n+'</b> · '+esc(s.lo.name)+' · '+plural(s.steps,"step")+', '+plural(s.fights,"fight")+'</p>'+
      '<p>Heroes standing: '+heroes.length+' of '+all+(s.heroesOut.length?' <span class="wldbad">('+s.heroesOut.length+' sitting out)</span>':'')+'</p>'+
      (copies?'<p>Copies left: '+copies+'</p>':'')+
      (packed?'<p>Packed: '+packed+'</p>':'')+
      '<p>Haul: '+haul.shards+' shards · '+X.count(haul)+' parts'+(s.items.length?' · '+plural(s.items.length,"find"):'')+' <span class="wldnote">— yours once you reach the dock</span></p>'+
      '<div class="pxrow"><button class="ghost" id="wlLog">'+(SHOWLOG?"Hide the log":"Log")+'</button></div>'+
      (SHOWLOG?'<ul class="wldlog">'+(s.log||[]).map(function(l){ return '<li>'+esc(l.text)+'</li>'; }).join("")+'</ul>':'')+'</div>';
  }

  /* ---- choosing a Strike Team and paying for it ---- */
  function deployHTML(){
    var los=D().loadouts();
    if(!los.length) return '<div class="wldbox"><p>No Strike Teams yet. Build one in the Deck Builder: Heroes, a Deck with your designs as its Troops, and an Aether Pouch.</p>'+
      '<div class="pxrow"><button class="ghost" data-go="deck">Open the Deck Builder</button><button class="ghost" id="wlDepBack">Back</button></div></div>';
    var h='<div class="wldbox"><p class="pxsub">Choose a Strike Team</p><div class="wslist">'+los.map(function(l){
      return '<button class="wsch'+(PICK===l.index?' on':'')+'" data-wlpick="'+l.index+'"><b>'+esc(l.name)+'</b><i>'+plural(l.heroes.length,"Hero","Heroes")+' · '+plural(l.deck.length,"card")+'</i></button>';
    }).join("")+'</div>';
    if(PICK!==null){
      var p=D().plan(PICK, PACK), R=L().RARITIES, st=L().stock(), cost=function(parts){ var b=[]; parts.forEach(function(n,r){ if(n) b.push('<span style="color:'+R[r].lite+'">'+n+' '+R[r].label+'</span>'); }); return b.join(" · ")||"nothing"; };
      h+='<p class="pxsub">'+esc(p.loadout?p.loadout.name:"")+'</p>'+
        '<p>Heroes: '+(p.heroes.length?esc(p.heroes.join(", ")):"none")+'</p>'+
        (p.lines.length?'<table class="wscost"><tr><td><b>Troop copies</b></td><td></td></tr>'+p.lines.map(function(l){
          return '<tr><td>'+esc(l.name)+' ×'+l.copies+(l.free?' <i class="wldok">('+l.free+' free)</i>':'')+'</td><td>'+cost(l.cost)+'</td></tr>'; }).join("")+
          '<tr class="wstot"><td>In all</td><td>'+cost(p.parts)+'</td></tr></table>':'<p class="wldnote">No Troops in its Deck.</p>')+
        '<p class="wldnote">'+plural(p.other,"other card")+' come along free. You have '+cost(st.parts.troop)+' in Troop parts. Copies are spent whatever happens.</p>'+
        (p.pre&&p.pre.length?'<p class="pxsub">Pre-built copies</p><p>'+p.pre.map(function(x){ return esc(x.name)+' ×'+x.copies; }).join(" · ")+'</p><p class="wldnote">Bought at the dock. They go on top of the Deck and are gone when this deployment ends.</p>':'')+
        stashHTML(p)+packHTML()+
        (p.reasons.length?'<ul class="wldwhy">'+p.reasons.map(function(r){ return '<li>'+esc(r)+'</li>'; }).join("")+'</ul>':'')+
        (!p.afford&&p.fits?'<p class="wldbad">'+(p.craft&&p.craft.length&&st.shards<p.craftShards?'Not enough shards to craft the cards the stash lacks.':'Not enough Troop parts for these copies, or parts to craft its cards.')+'</p>':'')+
        '<div class="pxrow"><button class="ghost primary" id="wlGo"'+(p.ok?'':' disabled')+'>Pay and deploy</button></div>';
    }
    return h+'<div class="pxrow"><button class="ghost" id="wlDepBack">Back</button></div></div>';
  }

  /* (v14.19) the cards it takes from the stash, and what is crafted for it as it leaves */
  function stashHTML(p){
    var need=p.need||{}, names=Object.keys(need).sort(); if(!names.length || !K()) return '';
    var cr={}; (p.craft||[]).forEach(function(c){ cr[c.name]=c; });
    return '<p class="pxsub">From the stash</p><p class="wldnote">These go out with the team and come home with it; a wipe loses them. What the stash lacks is crafted as it leaves.</p><div class="wldpack">'+names.map(function(n){
      var c=cr[n];
      return '<div class="dkrow"><span><b>'+esc(n)+' ×'+need[n]+'</b><i>held '+K().owned(n)+(c?' · '+c.n+' crafted: '+esc(K().craftText(c.shards, c.type, c.rarity, c.parts)):'')+'</i></span></div>';
    }).join("")+'</div>'+(p.craft&&p.craft.length?'<p class="wldnote">Crafting costs '+p.craftShards+' shards in all.</p>':'');
  }
  /* what to take along: Consumables and Prototypes kept at the dock */
  function packHTML(){
    if(!K()) return '';
    var v=K().inv().cards, names=Object.keys(v).filter(function(n){ var k=K().itemKind(n); return v[n]>0 && (k==="consumable" || k==="prototype"); }).sort();
    Object.keys(PACK).forEach(function(n){ if(!(v[n]>0)) delete PACK[n]; else if(PACK[n]>v[n]) PACK[n]=v[n]; });
    var h='<p class="pxsub">Pack</p>';
    if(!names.length) return h+'<p class="wldnote">Nothing kept at the dock to pack. Consumables and Prototypes are bought at the Exchange.</p>';
    return h+'<p class="wldnote">Every packed Prototype joins each fight, and each fight’s setup lets you choose from the packed Consumables. A Consumable used is gone. Prototypes, and anything unused, come home unless the team is wiped out.</p><div class="wldpack">'+names.map(function(n){
      var k=K().itemKind(n)==="prototype"?"Prototype":"Consumable", on=PACK[n]||0;
      return '<div class="dkrow"><span><b>'+esc(n)+'</b><i>'+k+' · '+on+' of '+v[n]+' packed</i></span>'+
        '<button class="ghost" data-wlpack="'+esc(n)+'" data-d="-1"'+(on?'':' disabled')+' aria-label="One fewer">−</button><button class="ghost" data-wlpack="'+esc(n)+'" data-d="1"'+(on<v[n]?'':' disabled')+' aria-label="One more">+</button></div>';
    }).join("")+'</div>';
  }

  /* ---- the tile panel ---- */
  function panelHTML(){
    var s=cur(), h=NOTE?'<div class="wldnote2">'+NOTE+'</div>':'';
    if(PLACING) return h+'<div class="wldbox"><p>Tap a tile to place <b>'+esc((W().uniques().filter(function(u){ return u.id===PLACING; })[0]||{}).name||"it")+'</b>.</p><div class="pxrow"><button class="ghost" id="wlPlaceX">Cancel</button></div></div>';
    if(s && s.activity){
      var a=s.activity, inFight=fightRunning();
      return h+'<div class="wldbox"><p><b>'+esc(a.kind==="poi"?a.name:"Ambush")+'</b>'+(a.kind==="poi"?' · floor '+(a.index+1)+' of '+a.floors.length:'')+' · Skull '+a.skull+'</p>'+
        '<p class="wldnote">'+(inFight?"The fight is under way in the Battle Simulator.":"The next fight is waiting.")+'</p>'+
        '<div class="pxrow"><button class="ghost primary" id="wlFight">'+(inFight?"Back to the fight":"Fight")+'</button></div></div>';
    }
    if(!SEL) return h+'<p class="wldnote">Tap a tile to see it.'+(s?' Tap one further off to walk there.':' Deploy to set out from the dock.')+'</p>';
    var k=SEL, open=W().isOpen(k);
    if(!open) return h+'<div class="wldbox"><p><b>Collapsed structure</b></p><p class="wldnote">Nothing gets through here.</p></div>';
    var t=W().tile(k), sk=W().skullOf(k), c=W().contentAt(k), kn=W().known(k), dock=k===W().map().dock;
    var line=dock?"The dock":(!kn?"Unknown — stand next to it to see":(c?c.name+(c.kind==="poi"&&c.type&&c.name!==c.type?" ("+c.type+")":""):"Empty"));
    if(kn && c && !dock && W().isCleared(k)){ var b=Math.max(0,W().backIn(k)-(s?1:0)); line+=' · cleared, back after '+(b?plural(b,"more deployment"):"this deployment"); }
    h+='<div class="wldbox"><p><b style="color:'+(W().DCOL[t.d]||"#ccc")+'">'+esc(dName(t.d))+'</b> · Skull '+sk+(t.s?' (set)':'')+'</p><p>'+esc(line)+'</p>';
    if(!dock) h+='<p class="wldnote">Stepping here: '+W().ambushChance(k)+'% chance of an ambush.</p>';
    if(s){
      if(k===s.pos) h+=hereHTML(k);
      else if(!WALK){
        var p=W().path(s.pos,k);
        h+=p?'<p class="wldnote">'+plural(p.length-1,"step")+' away · '+W().pathRisk(p)+'% chance of at least one ambush on the way.</p><div class="pxrow"><button class="ghost primary" id="wlWalk">Walk here</button></div>'
            :'<p class="wldbad">There is no way through to here.</p>';
      }
    }
    if(WALK) h+='<div class="pxrow"><button class="ghost" id="wlStop">Stop</button></div>';
    return h+'</div>';
  }
  /* what the team can do where it stands */
  function hereHTML(k){
    var c=W().contentAt(k), dock=k===W().map().dock, s=cur();
    if(dock) return '<p>The Strike Team is at the dock.</p><div class="pxrow"><button class="ghost primary" id="wlHome">Come home</button></div><p class="wldnote">Coming home banks the haul into your stockpile and the Workshop, and ends the deployment.</p>';
    if(EVOUT && EVOUT.tile===k) return evOutHTML(EVOUT);
    if(!c || !W().available(k)) return '<p class="wldnote">The Strike Team is here.</p>';
    if(c.kind==="poi"){
      var n=c.core?3:c.unique?(c.unique.floors||[]).length||W().floorCount(W().skullOf(k)):W().floorCount(W().skullOf(k));
      /* (v14.23) a District Core */
      return (c.core?'<p class="wldok"><b>The heart of District '+esc(c.core)+'.</b> Beat it to clear the District for good: 5 merits, and Dimensional Instability rises.</p>':'')+
        '<p>'+esc(c.name)+': '+plural(n,"floor")+', fought in order, with a reward at the end. Once inside, the only way out early is an Emergency Exit.</p><div class="pxrow"><button class="ghost primary" id="wlEnter">Enter</button></div>';
    }
    if(c.kind==="cache") return '<p>A cache, unguarded.</p><div class="pxrow"><button class="ghost primary" id="wlCache">Open it</button></div>';
    if(c.kind==="event"){
      var ev=D().eventAt(k); if(!ev) return "";
      return '<p><b>'+esc(ev.title)+'</b></p><p>'+esc(ev.text)+'</p><div class="wldchoices">'+ev.choices.map(function(ch,i){
        return '<button class="ghost" data-wlev="'+i+'">'+esc(ch.label)+(+ch.check?' <i>(d20, '+ch.check+' or more)</i>':'')+'</button>'; }).join("")+'</div>';
    }
    return "";
  }
  function evOutHTML(o){
    var h='<p><b>'+esc(o.event.title)+'</b> — '+esc(o.choice.label)+'</p>';
    if(o.check) h+='<p class="'+(o.won?"wldok":"wldbad")+'">Rolled '+o.roll+' (needed '+o.check+').</p>';
    if(o.text) h+='<p>'+esc(o.text)+'</p>';
    if(!L().isEmpty(o.got)) h+='<p>Into the haul: '+esc(bagText(o.got))+'.</p>';
    if(o.items.length) h+='<p>Found: '+o.items.map(function(it){ return esc(P().itemName(it)); }).join(", ")+'.</p>';
    if(o.lost && !L().isEmpty(o.lost)) h+='<p class="wldbad">Lost from the haul: '+esc(bagText(o.lost))+'.</p>';
    if(o.fight && o.spec) h+='<div class="pxrow"><button class="ghost primary" id="wlFight">Fight</button></div>';
    return h;
  }
  /* what the dock did when the team came home */
  function dockNote(o){
    if(!o) return '';
    var h='';
    (o.bounties||[]).forEach(function(b){ h+='<br>Bounty on '+esc(b.name)+' paid: '+esc(bagText(b.bag))+'.'; });
    if(o.reach) h+='<br>Reach extended to Skull Level '+o.reach+': the Exchange can carry rarer parts.';
    if(o.restocked) h+='<br>New ground was revealed, so the Exchange has restocked.';
    return h+(h?' <button class="ghost" data-page="dock">Open the Dock</button>':'');
  }
  function fightRunning(){
    try{ var o=JSON.parse(localStorage.getItem("keter-app-sim")||"null"); return !!(o && o.deploy && !o.over && o.units && o.units.length); }catch(e){ return false; }
  }

  function legendHTML(){
    var ic=[["⌂","The dock"],["◆","POI"],["★","Unique POI"],["!","Ambush"],["▣","Cache"],["?","Event"],["◉","Your team"]];
    return '<div class="wldleg">'+ic.map(function(x){ return '<span><b>'+x[0]+'</b> '+x[1]+'</span>'; }).join("")+'</div>'+
      '<p class="wldnote">Colours are Districts, darker the farther out; a light line marks each rise in Skull Level. What a tile holds shows once your team has stood next to it. Zoomed in, drawn map art takes the place of colours and symbols wherever it exists, and your team is its first standing Hero.</p>';
  }

  /* ---- the canvas ---- */
  function sizeCanvas(){
    var cv=$("wldCv"); if(!cv) return;
    var box=$("wldMapBox"), w=Math.max(260, box.clientWidth||360), h=Math.round(Math.min(Math.max(300, window.innerHeight*0.56), w*1.15));
    var dpr=Math.min(window.devicePixelRatio||1, 3);
    if(cv.width!==Math.round(w*dpr) || cv.height!==Math.round(h*dpr)){ cv.width=Math.round(w*dpr); cv.height=Math.round(h*dpr); cv.style.width=w+"px"; cv.style.height=h+"px"; }
    var fresh=!VIEW.ready || VIEW.w!==w || VIEW.h!==h;
    VIEW.w=w; VIEW.h=h; VIEW.dpr=dpr;
    if(fresh){ VIEW.ready=true; var s=cur(); if(s) centreOn(s.pos, 16); else fit(); }
  }
  function fit(){ var R=W().map().radius; VIEW.size=Math.min(VIEW.w/(SQ3*(2*R+1.2)), VIEW.h/(3*R+2.4)); VIEW.cx=VIEW.w/2; VIEW.cy=VIEW.h/2; }
  function centreOn(k, size){ var a=W().parse(k); if(size) VIEW.size=size; VIEW.cx=VIEW.w/2-SQ3*VIEW.size*(a.q+a.r/2); VIEW.cy=VIEW.h/2-1.5*VIEW.size*a.r; }
  function centre(k){ var a=W().parse(k); return {x:VIEW.cx+SQ3*VIEW.size*(a.q+a.r/2), y:VIEW.cy+1.5*VIEW.size*a.r}; }
  function hexAt(px,py){
    var x=(px-VIEW.cx)/VIEW.size, y=(py-VIEW.cy)/VIEW.size, q=SQ3/3*x-y/3, r=2/3*y, s=-q-r;
    var rq=Math.round(q), rr=Math.round(r), rs=Math.round(s), dq=Math.abs(rq-q), dr=Math.abs(rr-r), ds=Math.abs(rs-s);
    if(dq>dr&&dq>ds) rq=-rr-rs; else if(dr>ds) rr=-rq-rs;
    return W().key(rq,rr);
  }
  /* the same hash as the game's (and pickFrom's), for "one empty tile in five" */
  function worldHash(str){ var h=0; for(var i=0;i<str.length;i++) h=(h*31+str.charCodeAt(i))>>>0; return h; }
  function hexPath(g,x,y,r){ g.beginPath(); for(var i=0;i<6;i++){ var a=Math.PI/180*(60*i-30); if(i) g.lineTo(x+r*Math.cos(a),y+r*Math.sin(a)); else g.moveTo(x+r*Math.cos(a),y+r*Math.sin(a)); } g.closePath(); }
  function shade(hex, f){ var n=parseInt(hex.slice(1),16), r=(n>>16)&255, gg=(n>>8)&255, b=n&255; return "rgb("+Math.round(r*f)+","+Math.round(gg*f)+","+Math.round(b*f)+")"; }
  function paint(){
    var cv=$("wldCv"); if(!cv) return; var g=cv.getContext("2d"), m=W().map(), R=m.radius, s=VIEW.size, st=cur();
    g.setTransform(VIEW.dpr,0,0,VIEW.dpr,0,0); g.fillStyle="#05080b"; g.fillRect(0,0,VIEW.w,VIEW.h);
    var keys=W().allKeys(R), pad=s*1.2, SK={};
    /* v13.0: drawn map art, where there is some and the tiles are big enough to show it */
    var A=window.KETER_ASSETS, art=!!A && s>=7, H=16; while(H<2*s*(VIEW.dpr||1) && H<256) H*=2;
    var SLOTP={}, pick=function(slot,k){ if(!SLOTP[slot]) SLOTP[slot]=A.pics(slot); return A.pickFrom(SLOTP[slot],k); };
    var tileArt=function(pic, p, dark, edge){
      g.save(); hexPath(g,p.x,p.y,s*1.01); g.clip();
      g.drawImage(A.tileSprite(pic,H), p.x-SQ3*s/2*1.02, p.y-s*1.02, SQ3*s*1.02, 2*s*1.02);
      if(dark>0){ g.fillStyle="rgba(0,0,0,"+dark+")"; g.fill(); }
      if(edge){ g.globalAlpha=0.55; g.strokeStyle=edge; g.lineWidth=Math.max(1,s*0.14); g.stroke(); }
      g.restore();
    };
    keys.forEach(function(k){
      var p=centre(k); if(p.x<-pad||p.y<-pad||p.x>VIEW.w+pad||p.y>VIEW.h+pad) return;
      var t=m.tiles[k];
      if(!t){ var rub=art?pick("map.collapsed",k):null; if(rub) tileArt(rub,p,0.35,null); else { hexPath(g,p.x,p.y,s*0.98); g.fillStyle="#0c1216"; g.fill(); } return; }
      var sk=SK[k]=W().skullOf(k), col=W().DCOL[t.d]||W().DCOL[""];
      var gr=art?pick("map.ground."+(t.d||"none"),k):null;
      if(gr) tileArt(gr,p,0.1*(sk-1),col);
      else { hexPath(g,p.x,p.y,s*(s>9?0.95:1.01)); g.fillStyle=k===m.dock?"#dfe8ec":shade(col, 0.95-0.1*(sk-1)); g.fill(); }
    });
    /* each rise in Skull Level */
    g.strokeStyle="rgba(255,255,255,.6)"; g.lineWidth=Math.max(1,s*0.13); g.beginPath();
    keys.forEach(function(k){
      if(!(k in SK)) return; var a=W().parse(k), p=centre(k);
      for(var i=0;i<6;i++){ var d=[[1,0],[0,1],[-1,1],[-1,0],[0,-1],[1,-1]][i], n=W().key(a.q+d[0],a.r+d[1]);
        if(!m.tiles[n] || W().skullOf(n)===SK[k]) continue;
        var ang=[0,60,120,180,240,300][i], a1=Math.PI/180*(ang-30), a2=Math.PI/180*(ang+30);
        g.moveTo(p.x+s*Math.cos(a1),p.y+s*Math.sin(a1)); g.lineTo(p.x+s*Math.cos(a2),p.y+s*Math.sin(a2)); }
    });
    g.stroke();
    /* what tiles hold, where known; (v14.2) and what stands on them, as game 0.15
       stands it: a District's things on one empty tile in five, the Hangar on the
       dock's, an icon on a plate in its colour; back to front */
    if(s>=6){
      g.textAlign="center"; g.textBaseline="middle"; g.font="700 "+Math.round(s*0.95)+"px sans-serif";
      var PXL=window.KETER_PX, K=s/43.07, stand=[], THINGS={};
      var sq=function(pic){ return pic && PXL && !PXL.isHex(pic) ? PXL.sprite(pic) : null; };
      keys.forEach(function(k){
        if(!(k in SK)) return; var c=W().contentAt(k), dock=k===m.dock, p=centre(k), t=m.tiles[k];
        if(art && !dock && !c && t && t.d && worldHash(k+"p")%5===0){
          if(!THINGS[t.d]) THINGS[t.d]=A.pics("map.prop."+t.d);
          var th=A.pickFrom(THINGS[t.d],k); if(th && sq(th)) stand.push({y:p.y, thing:th, p:p});
        }
        if(!c && !dock) return;
        if(!dock && !W().known(k)) return;
        stand.push({y:p.y+(dock?0.5:0.25), k:k, c:c, dock:dock, p:p});
      });
      stand.sort(function(a,b){ return a.y-b.y; });
      g.imageSmoothingEnabled=false;
      stand.forEach(function(e){
        var p=e.p;
        if(e.thing){ var sp=sq(e.thing); g.drawImage(sp, p.x-e.thing.w/2*2*K, p.y+(10-(e.thing.h-4)*2)*K, e.thing.w*2*K, e.thing.h*2*K); return; }
        var c=e.c, dock=e.dock, kind=dock?"dock":(c.unique||c.core)?"unique":c.kind;
        var gl=dock?"⌂":(c.unique||c.core)?"★":{poi:"◆",ambush:"!",cache:"▣",event:"?"}[c.kind]||"";
        g.globalAlpha=(!dock && W().isCleared(e.k))?0.3:1;
        var icon=art?pick("map.icon."+kind,e.k):null, sp2=sq(icon);
        if(icon && !sp2) g.drawImage(A.tileSprite(icon,H), p.x-SQ3*s/2, p.y-s, SQ3*s, 2*s);
        else if(sp2 && dock) g.drawImage(sp2, p.x-icon.w/2*2*K, p.y+(20-(icon.h-12)*2)*K, icon.w*2*K, icon.h*2*K);
        else if(sp2){
          var k2=Math.max(1, 0.5/K);         /* larger with the whole map in view, as the game's */
          hexPath(g,p.x,p.y,20*K*k2); g.fillStyle="rgba(20,18,29,0.92)"; g.fill();
          g.lineWidth=Math.max(1,2*K*k2); g.strokeStyle=(A.PLATE&&A.PLATE[kind])||"#88a3bc"; g.stroke();
          g.drawImage(sp2, p.x-icon.w*K*k2, p.y-icon.h*K*k2, icon.w*2*K*k2, icon.h*2*K*k2);
        }
        else { g.fillStyle="#061015"; g.fillText(gl,p.x,p.y+s*0.04); }
        g.globalAlpha=1;
      });
      g.imageSmoothingEnabled=true;
    }
    /* the way to the chosen tile */
    if(st && SEL && SEL!==st.pos && !st.activity){
      var path=W().path(st.pos,SEL);
      if(path && path.length>1){ g.setLineDash([Math.max(2,s*0.35),Math.max(2,s*0.3)]); g.strokeStyle="#ffffff"; g.lineWidth=Math.max(1.5,s*0.16); g.beginPath();
        path.forEach(function(k,i){ var p=centre(k); if(i) g.lineTo(p.x,p.y); else g.moveTo(p.x,p.y); }); g.stroke(); g.setLineDash([]); }
    }
    if(SEL){ var ps=centre(SEL); hexPath(g,ps.x,ps.y,s*0.98); g.strokeStyle="#ffffff"; g.lineWidth=Math.max(1.5,s*0.18); g.stroke(); }
    if(st){ var pt=centre(st.pos), tok=s>=8?teamToken(st):null;
      if(tok){
        /* v13.0: the team is its first standing Hero, in its skin */
        var rr=Math.max(6,s*0.82); g.save(); g.beginPath(); g.arc(pt.x,pt.y,rr,0,Math.PI*2); g.fillStyle="#0b1a20"; g.fill(); g.clip();
        window.KETER_PX.draw(g,tok,pt.x-rr*0.92,pt.y-rr*0.92,rr*1.84,rr*1.84,VIEW.dpr||1,{minFill:0.5}); g.restore();
        g.beginPath(); g.arc(pt.x,pt.y,rr,0,Math.PI*2); g.lineWidth=Math.max(1.5,s*0.14); g.strokeStyle="#57d8e3"; g.stroke();
      } else {
        g.beginPath(); g.arc(pt.x,pt.y,Math.max(4,s*0.55),0,Math.PI*2); g.fillStyle="#57d8e3"; g.fill(); g.lineWidth=Math.max(1.5,s*0.14); g.strokeStyle="#05080b"; g.stroke();
        g.beginPath(); g.arc(pt.x,pt.y,Math.max(1.5,s*0.2),0,Math.PI*2); g.fillStyle="#05080b"; g.fill(); }
    }
  }
  /* the Strike Team's marker: its first standing Hero's token (remembered a moment, since the picture library is large) */
  var TEAMTOK={key:null, pic:null, at:0};
  function teamToken(st){
    var ref=(D().heroRefs(st)||[])[0]; if(!ref || !window.KETER_PX) return null;
    var S=window.KETER_SKINS, look=S?JSON.stringify(S.heroLook(String(ref).split("|").slice(1).join("|"))):"";
    var key=ref+"|"+look; if(TEAMTOK.key===key && Date.now()-TEAMTOK.at<3000) return TEAMTOK.pic;
    var card=D().resolve(ref), pic=card?(S?S.picFor(card,"token"):window.KETER_PX.pictureFor(card,"token")):null;
    TEAMTOK={key:key, pic:pic, at:Date.now()}; return pic;
  }

  /* ---- pan, pinch, tap ---- */
  function zoomAt(f, x, y){ var ns=Math.max(3, Math.min(60, VIEW.size*f)); f=ns/VIEW.size; VIEW.cx=x-(x-VIEW.cx)*f; VIEW.cy=y-(y-VIEW.cy)*f; VIEW.size=ns; paint(); }
  function local(e){ var r=$("wldCv").getBoundingClientRect(); return {x:e.clientX-r.left, y:e.clientY-r.top}; }
  document.addEventListener("pointerdown",function(e){
    if(!e.target || e.target.id!=="wldCv") return;
    try{ e.target.setPointerCapture(e.pointerId); }catch(x){}
    PTR[e.pointerId]=local(e);
    var ids=Object.keys(PTR);
    if(ids.length===1) DRAG={start:local(e), cx:VIEW.cx, cy:VIEW.cy, moved:false};
    else if(ids.length===2){ var a=PTR[ids[0]], b=PTR[ids[1]]; DRAG={pinch:Math.hypot(a.x-b.x,a.y-b.y), size:VIEW.size, moved:true}; }
  });
  document.addEventListener("pointermove",function(e){
    if(!PTR[e.pointerId] || !DRAG) return;
    PTR[e.pointerId]=local(e); var ids=Object.keys(PTR);
    if(ids.length>=2 && DRAG.pinch){ var a=PTR[ids[0]], b=PTR[ids[1]], d=Math.hypot(a.x-b.x,a.y-b.y); zoomAt(DRAG.size*d/DRAG.pinch/VIEW.size,(a.x+b.x)/2,(a.y+b.y)/2); return; }
    if(ids.length===1 && DRAG.start){ var p=PTR[ids[0]], dx=p.x-DRAG.start.x, dy=p.y-DRAG.start.y;
      if(Math.abs(dx)+Math.abs(dy)>6) DRAG.moved=true;
      if(DRAG.moved){ VIEW.cx=DRAG.cx+dx; VIEW.cy=DRAG.cy+dy; paint(); } }
  });
  function up(e){
    if(!PTR[e.pointerId]) return;
    var p=PTR[e.pointerId]; delete PTR[e.pointerId];
    if(DRAG && !DRAG.moved && !Object.keys(PTR).length) tap(hexAt(p.x,p.y));
    if(!Object.keys(PTR).length) DRAG=null;
  }
  document.addEventListener("pointerup",up); document.addEventListener("pointercancel",up);
  document.addEventListener("wheel",function(e){ if(!e.target||e.target.id!=="wldCv") return; e.preventDefault(); var p=local(e); zoomAt(e.deltaY<0?1.15:1/1.15,p.x,p.y); },{passive:false});
  function tap(k){
    var a=W().parse(k); if(Math.max(Math.abs(a.q),Math.abs(a.r),Math.abs(a.q+a.r))>W().map().radius) return;
    if(PLACING){ var u=W().uniques(); u.forEach(function(x){ if(x.id===PLACING) x.tile=k; }); W().saveUniques(u); PLACING=null; NOTE="Placed on "+k+"."; SEL=k; refresh(); return; }
    SEL=k; if(EVOUT && EVOUT.tile!==k) EVOUT=null; NOTE=""; $("wldPanel").innerHTML=panelHTML(); paint();
  }

  /* ---- walking ---- */
  function walk(to){
    var s=cur(); if(!s) return; var p=W().path(s.pos,to); if(!p||p.length<2) return;
    WALK={steps:p.slice(1), i:0}; NOTE=""; EVOUT=null; refresh(); setTimeout(tick, 140);
  }
  function tick(){
    if(!WALK) return; var next=WALK.steps[WALK.i++], r=D().stepTo(next);
    if(!r.moved){ WALK=null; NOTE=esc(r.why||"Can't go on"); refresh(); return; }
    var p=centre(r.pos); if(p.x<VIEW.w*0.15||p.x>VIEW.w*0.85||p.y<VIEW.h*0.15||p.y>VIEW.h*0.85) centreOn(r.pos);
    if(r.ambush){
      WALK=null; SEL=r.pos; var spec=D().ambush(r.pos,{tileAmbush:!!r.tileAmbush});
      NOTE='<b class="wldbad">Ambush!</b> '+(r.tileAmbush?"Something was waiting here.":"Enemies close in on the way.")+(spec?"":" (No floor to fight on: add floors in the Sandbox.)");
      refresh(); return;
    }
    if(r.content || WALK.i>=WALK.steps.length){ WALK=null; SEL=r.pos; refresh(); return; }
    SEL=WALK.steps[WALK.steps.length-1];
    $("wldStatus").innerHTML=statusHTML(); paint();
    setTimeout(tick, 140);
  }
  function fight(){
    var s=cur(); if(!s||!s.activity) return;
    if(fightRunning()){ window.KETER_GO("battle"); return; }
    if(window.simDeployFight) window.simDeployFight(D().spec());
  }

  /* ---- Dev Mode: the map, Unique POIs, Events and tables ---- */
  function devHTML(){
    var m=W().map(), sb=W().sandboxMaps(), s=cur();
    var h='<div class="wsdev wlddev"><p class="pxsub">Dev Mode · the world</p>'+
      '<details class="wldsec"><summary>The map</summary>'+
        '<p class="wldnote">'+esc(m.name)+' · '+(m.source==="generated"?"generated, seed "+m.seed:"from the Sandbox level “"+esc(String(m.source).replace(/^sandbox:/,""))+"”")+' · '+Object.keys(m.tiles).length+' open tiles.</p>'+
        (W().sandboxNewer()?'<p class="wldok">The Sandbox copy has been saved since. <button class="ghost" id="wlReload">Use the new version</button></p>':'')+
        '<div class="pxrow"><input id="wlSeed" class="ltin" type="number" placeholder="seed (blank: random)"><button class="ghost" id="wlNew">Generate a new map</button></div>'+
        '<div class="pxrow"><button class="ghost" id="wlEdit">Edit in the Sandbox</button></div>'+
        (sb.length?'<div class="pxrow"><select id="wlSbSel" class="ltsel">'+sb.map(function(x){ return '<option value="'+esc(x.key)+'">'+esc(x.name)+' · '+x.tiles+' tiles</option>'; }).join("")+'</select><button class="ghost" id="wlUse">Use this map</button></div>':'')+
        '<div class="pxrow"><button class="ghost" id="wlForget">Forget what has been explored</button>'+(s?'<button class="ghost" id="wlAbandon">Abandon the deployment</button>':'')+'</div>'+
      '</details>'+
      '<details class="wldsec"'+(UQEDIT?' open':'')+'><summary>Unique POIs ('+W().uniques().length+')</summary>'+uniquesHTML()+'</details>'+
      '<details class="wldsec"'+(EVEDIT!==null?' open':'')+'><summary>Events ('+W().events().length+')</summary>'+eventsHTML()+'</details>'+
      '<details class="wldsec"><summary>Tables</summary>'+tablesHTML()+'</details></div>';
    return h;
  }
  function numIn(attr,val,step){ return '<input type="number" class="ltin" '+attr+' value="'+esc(val)+'" step="'+(step||"1")+'" min="0">'; }
  function uniquesHTML(){
    var us=W().uniques(), fl=W().floors();
    var h=us.map(function(u){ return '<div class="wldrow"><b>'+esc(u.name||"Unique POI")+'</b><i>'+(u.tile?"on "+esc(u.tile)+" · "+esc(dName(W().districtOf(u.tile)))+" · Skull "+W().skullOf(u.tile):"not placed")+' · '+plural((u.floors||[]).length,"floor")+'</i>'+
      '<div class="pxrow"><button class="ghost" data-uqedit="'+esc(u.id)+'">Edit</button><button class="ghost" data-uqplace="'+esc(u.id)+'">Place on the map</button><button class="ghost" data-uqdel="'+esc(u.id)+'">Delete</button></div></div>'; }).join("");
    h+='<div class="pxrow"><button class="ghost" id="uqNew">New Unique POI</button></div>';
    var u=us.filter(function(x){ return x.id===UQEDIT; })[0];
    if(u){
      var rw=u.reward||{}, items=rw.items||[], all=P().allItems();
      h+='<div class="wldform"><label class="chf"><span>Name</span><input data-uq="name" value="'+esc(u.name||"")+'"></label>'+
        '<label class="chf"><span>Type</span><input data-uq="type" value="'+esc(u.type||"")+'" placeholder="Unique POI"></label>'+
        '<p class="pxsub">Floors, in order</p>'+(u.floors||[]).map(function(f,i){ return '<div class="wldrow wldmini"><span>'+(i+1)+'. '+esc(f)+'</span><button class="ghost" data-uqup="'+i+'">↑</button><button class="ghost" data-uqrm="'+i+'">✕</button></div>'; }).join("")+
        '<div class="pxrow"><select id="uqFloor" class="ltsel">'+fl.map(function(f){ return '<option value="'+esc(f.key)+'">'+esc(f.name)+' · D'+(f.district||"-")+' · Skull '+f.skull+'</option>'; }).join("")+'</select><button class="ghost" id="uqAddFloor">Add</button></div>'+
        '<p class="pxsub">Its reward</p><div class="chgrid">'+
          '<label class="chf"><span>Shards</span>'+numIn('data-uqr="shards"',rw.shards||0)+'</label>'+
          '<label class="chf"><span>Rolled parts</span>'+numIn('data-uqr="n"',rw.n==null?3:rw.n)+'</label>'+
          '<label class="chf"><span>Rarer by</span>'+numIn('data-uqr="bonus"',rw.bonus==null?1:rw.bonus)+'</label>'+
          '<label class="chf"><span>Blueprint %</span>'+numIn('data-uqr="bp"',rw.bp==null?35:rw.bp)+'</label></div>'+
        items.map(function(x,i){ return '<div class="wldrow wldmini"><span>'+esc(P().itemName(x.item,true))+'</span>'+numIn('data-uqich="'+i+'"',x.chance)+'<span>%</span><button class="ghost" data-uqirm="'+i+'">✕</button></div>'; }).join("")+
        '<div class="pxrow"><select id="uqItem" class="ltsel">'+all.map(function(it){ return '<option value="'+esc(it)+'">'+(/^ch:/.test(it)?"Chassis: ":"Blueprint: ")+esc(P().itemName(it,true))+'</option>'; }).join("")+'</select><button class="ghost" id="uqAddItem">Add a set drop</button></div>'+
        '<div class="pxrow"><button class="ghost" id="uqDone">Done</button></div></div>';
    }
    return h;
  }
  function eventsHTML(){
    var ev=W().events(), h=ev.map(function(e,i){ return '<div class="wldrow"><b>'+esc(e.title)+'</b><i>'+plural((e.choices||[]).length,"choice")+'</i><div class="pxrow"><button class="ghost" data-evedit="'+i+'">Edit</button><button class="ghost" data-evdel="'+i+'">Delete</button></div></div>'; }).join("");
    h+='<div class="pxrow"><button class="ghost" id="evNew">Add an event</button><button class="ghost" id="evReset">Back to the eight drafts</button></div>';
    var e=EVEDIT!==null?ev[EVEDIT]:null;
    if(e){
      var outForm=function(ci,side,o){ o=o||{};
        return '<div class="wldout"><p class="pxsub">'+(side==="win"?"If it goes well (or there is no check)":"If the check fails")+'</p>'+
          '<label class="chf"><span>What happens</span><input data-evo="'+ci+':'+side+':text" value="'+esc(o.text||"")+'"></label><div class="chgrid">'+
          '<label class="chf"><span>Shards per Skull</span>'+numIn('data-evo="'+ci+':'+side+':shards"',o.shards||0)+'</label>'+
          '<label class="chf"><span>Rolled parts</span>'+numIn('data-evo="'+ci+':'+side+':n"',o.n||0)+'</label>'+
          '<label class="chf"><span>Of type</span><select data-evo="'+ci+':'+side+':type">'+["any","troop","equipment","aether"].map(function(t){ return '<option'+((o.type||"any")===t?" selected":"")+'>'+t+'</option>'; }).join("")+'</select></label>'+
          '<label class="chf"><span>Rarer by</span>'+numIn('data-evo="'+ci+':'+side+':bonus"',o.bonus||0)+'</label>'+
          '<label class="chf"><span>Blueprint %</span>'+numIn('data-evo="'+ci+':'+side+':bp"',o.bp||0)+'</label>'+
          '<label class="chf"><span>Lose % of haul</span>'+numIn('data-evo="'+ci+':'+side+':lose"',o.lose||0)+'</label></div>'+
          '<label class="wldchk"><input type="checkbox" data-evo="'+ci+':'+side+':fight"'+(o.fight?" checked":"")+'> Then a fight</label></div>'; };
      h+='<div class="wldform"><label class="chf"><span>Title</span><input data-ev="title" value="'+esc(e.title||"")+'"></label>'+
        '<label class="chf"><span>What the team finds</span><textarea data-ev="text" rows="3" class="wstext">'+esc(e.text||"")+'</textarea></label>'+
        (e.choices||[]).map(function(c,ci){ return '<div class="wldchoice"><div class="pxrow"><label class="chf" style="flex:1"><span>Choice '+(ci+1)+'</span><input data-evc="'+ci+':label" value="'+esc(c.label||"")+'"></label>'+
          '<label class="chf"><span>d20 check (0: none)</span>'+numIn('data-evc="'+ci+':check"',c.check||0)+'</label><button class="ghost" data-evcrm="'+ci+'">✕</button></div>'+
          outForm(ci,"win",c.win)+(+c.check?outForm(ci,"fail",c.fail):'')+'</div>'; }).join("")+
        '<div class="pxrow"><button class="ghost" id="evAddChoice">Add a choice</button><button class="ghost" id="evDone">Done</button></div></div>';
    }
    return h;
  }
  function tablesHTML(){
    var t=W().tables(), n=function(path,val,step){ return numIn('data-wt="'+path+'"',val,step); };
    return '<p class="wldnote">Size, blocked tiles and how many of each content apply to the next map generated.</p><div class="chgrid">'+
      '<label class="chf"><span>Rings</span>'+n("radius",t.radius)+'</label><label class="chf"><span>Rings per Skull Level</span>'+n("ringsPerSkull",t.ringsPerSkull)+'</label>'+
      '<label class="chf"><span>Blocked %</span>'+n("blocked",t.blocked)+'</label>'+
      W().KINDS.map(function(k){ return '<label class="chf"><span>'+W().KIND_LABEL[k]+' tiles %</span>'+n("density."+k,t.density[k],"0.5")+'</label>'; }).join("")+
      '<label class="chf"><span>Ambush % per Skull, each step</span>'+n("ambushStep",t.ambushStep,"0.5")+'</label>'+
      '<label class="chf"><span>Back after (deployments)</span>'+n("respawn",t.respawn)+'</label>'+
      '<label class="chf"><span>Free starter copies</span>'+n("starterFree",t.starterFree)+'</label></div>'+
      '<p class="pxsub">Floors in a POI, Skull 1 to 6</p><div class="chgrid">'+t.floorsBySkull.map(function(v,i){ return '<label class="chf"><span>Skull '+(i+1)+'</span>'+n("floorsBySkull."+i,v)+'</label>'; }).join("")+'</div>'+
      '<p class="pxsub">A cache</p><div class="chgrid"><label class="chf"><span>Shards per Skull</span>'+n("cache.shards",t.cache.shards)+'</label><label class="chf"><span>Rolled parts</span>'+n("cache.n",t.cache.n)+'</label>'+
        '<label class="chf"><span>Rarer by</span>'+n("cache.bonus",t.cache.bonus)+'</label><label class="chf"><span>Blueprint %</span>'+n("cache.bp",t.cache.bp)+'</label><label class="chf"><span>Card %</span>'+n("cache.card",t.cache.card||0)+'</label></div>'+
      '<p class="pxsub">A POI’s final reward</p><div class="chgrid"><label class="chf"><span>Shards per Skull</span>'+n("poi.shards",t.poi.shards)+'</label><label class="chf"><span>Rolled parts</span>'+n("poi.n",t.poi.n)+'</label>'+
        '<label class="chf"><span>Rarer by</span>'+n("poi.bonus",t.poi.bonus)+'</label><label class="chf"><span>Blueprint %</span>'+n("poi.bp",t.poi.bp)+'</label><label class="chf"><span>Card %</span>'+n("poi.card",t.poi.card||0)+'</label></div>'+
      '<div class="pxrow"><button class="ghost" id="wlTabReset">Reset the world’s tables</button></div>';
  }
  function openInSandbox(){
    var name=W().saveToSandbox("World Map"); if(!name) return;
    window.KETER_GO("poi"); var tries=0;
    (function again(){
      var f=document.querySelector("#v-poi iframe"), w=f&&f.contentWindow;
      if(w && w.KETER_POI && w.KETER_POI.loadLevel){ try{ w.KETER_POI.loadLevel(name); if(w.KETER_POI.renderSlots) w.KETER_POI.renderSlots(); }catch(e){} return; }
      if(++tries<60) setTimeout(again,250);
    })();
  }
  function saveUq(fn){ var us=W().uniques(); us.forEach(function(u){ if(u.id===UQEDIT) fn(u); }); W().saveUniques(us); }
  function saveEv(fn){ var ev=W().events(); if(EVEDIT!==null && ev[EVEDIT]) fn(ev[EVEDIT]); W().saveEvents(ev); }

  /* ---- taps ---- */
  document.addEventListener("click",function(e){
    if(!HOST || !HOST.contains(e.target)) return;
    var t=e.target.closest?e.target.closest("button"):null; if(!t) return;
    var id=t.id, a, s=cur();
    if((a=t.getAttribute("data-wlz"))){
      if(a==="in") zoomAt(1.3,VIEW.w/2,VIEW.h/2); else if(a==="out") zoomAt(1/1.3,VIEW.w/2,VIEW.h/2);
      else if(a==="fit"){ fit(); paint(); } else if(a==="team"){ centreOn(s?s.pos:W().map().dock, Math.max(VIEW.size,14)); paint(); }
      return;
    }
    if(id==="wlDeploy"){ MODE="deploy"; PICK=null; PACK={}; refresh(); return; }
    if((a=t.getAttribute("data-wlpack"))){ PACK[a]=Math.max(0,(PACK[a]||0)+(+t.getAttribute("data-d"))); if(!PACK[a]) delete PACK[a]; refresh(); return; }
    if(id==="wlDepBack"){ MODE="map"; refresh(); return; }
    if((a=t.getAttribute("data-wlpick"))!==null){ PICK=+a; refresh(); return; }
    if(id==="wlGo"){ var r=D().start(PICK, PACK); if(r.ok){ PACK={}; MODE="map"; SEL=r.state.pos; VIEW.ready=false; NOTE="Out of the dock. Tap a tile to walk there."; } refresh(); return; }
    if(id==="wlLog"){ SHOWLOG=!SHOWLOG; refresh(); return; }
    if(id==="wlWalk"){ walk(SEL); return; }
    if(id==="wlStop"){ WALK=null; refresh(); return; }
    if(id==="wlFight"){ fight(); return; }
    if(id==="wlEnter"){ var sp=D().enterPOI(s.pos); if(sp) fight(); else { NOTE="No floor to fight on: add floors in the Sandbox."; refresh(); } return; }
    if(id==="wlCache"){ var c=D().openCache(s.pos); if(c) NOTE='The cache holds '+esc(bagText(c.bag))+(c.items.length?'; and '+c.items.map(function(it){ return esc(P().itemName(it)); }).join(", "):'')+'. Into the haul.'; refresh(); return; }
    if((a=t.getAttribute("data-wlev"))!==null){ var o=D().choose(s.pos,+a); if(o){ o.tile=s.pos; EVOUT=o; } refresh(); return; }
    if(id==="wlHome"){
      var hm=D().home();
      if(hm&&hm.ok){ SEL=null; EVOUT=null; NOTE='<b class="wldok">Home.</b> Banked: '+esc(bagText(hm.haul))+(hm.items.length?'; '+hm.items.map(function(it){ return esc(P().itemName(it)); }).join(", ")+' now in the Workshop':'')+'.'+dockNote(hm.dock); VIEW.ready=false; }
      else if(hm) NOTE=esc(hm.why);
      refresh(); return;
    }
    if(id==="wlPlaceX"){ PLACING=null; refresh(); return; }
    /* Dev Mode */
    if(id==="wlNew"){ if(confirm("Generate a new map? It replaces this one and forgets what has been explored."+(s?" The deployment out now is abandoned.":""))){ if(s) D().abandon(); var sd=$("wlSeed")&&$("wlSeed").value; W().newMap(sd===""?null:+sd); SEL=null; VIEW.ready=false; refresh(); } return; }
    if(id==="wlEdit"){ openInSandbox(); return; }
    if(id==="wlUse"){ var key=$("wlSbSel").value; if(confirm("Use “"+key+"” as the world map?")){ if(!W().useSandbox(key)) alert("That level could not be read as a world map."); VIEW.ready=false; refresh(); } return; }
    if(id==="wlReload"){ W().useSandbox(String(W().map().source).replace(/^sandbox:/,"")); VIEW.ready=false; refresh(); return; }
    if(id==="wlForget"){ if(confirm("Forget what has been explored and cleared?")){ W().resetState(); refresh(); } return; }
    if(id==="wlAbandon"){ if(confirm("Abandon the deployment? Nothing is banked; copies and anything packed stay spent.")){ D().abandon(); SEL=null; refresh(); } return; }
    if(id==="uqNew"){ var us=W().uniques(), nu={id:"uq_"+Date.now().toString(36), name:"Unique POI", type:"Unique POI", tile:null, floors:[], reward:{shards:40, n:3, bonus:1, bp:35, items:[]}}; us.push(nu); W().saveUniques(us); UQEDIT=nu.id; refresh(); return; }
    if((a=t.getAttribute("data-uqedit"))){ UQEDIT=a; refresh(); return; }
    if((a=t.getAttribute("data-uqplace"))){ PLACING=a; MODE="map"; refresh(); var mb=$("wldMapBox"); if(mb&&mb.scrollIntoView) mb.scrollIntoView({block:"center"}); return; }
    if((a=t.getAttribute("data-uqdel"))){ if(confirm("Delete this Unique POI?")){ W().saveUniques(W().uniques().filter(function(u){ return u.id!==a; })); if(UQEDIT===a) UQEDIT=null; refresh(); } return; }
    if(id==="uqDone"){ UQEDIT=null; refresh(); return; }
    if(id==="uqAddFloor"){ var fk=$("uqFloor").value; saveUq(function(u){ u.floors=(u.floors||[]).concat([fk]); }); refresh(); return; }
    if((a=t.getAttribute("data-uqup"))!==null){ saveUq(function(u){ var i=+a; if(i>0){ var x=u.floors[i]; u.floors[i]=u.floors[i-1]; u.floors[i-1]=x; } }); refresh(); return; }
    if((a=t.getAttribute("data-uqrm"))!==null){ saveUq(function(u){ u.floors.splice(+a,1); }); refresh(); return; }
    if(id==="uqAddItem"){ var it=$("uqItem").value; saveUq(function(u){ u.reward=u.reward||{}; u.reward.items=(u.reward.items||[]).concat([{item:it, chance:50}]); }); refresh(); return; }
    if((a=t.getAttribute("data-uqirm"))!==null){ saveUq(function(u){ u.reward.items.splice(+a,1); }); refresh(); return; }
    if((a=t.getAttribute("data-evedit"))!==null){ EVEDIT=+a; refresh(); return; }
    if((a=t.getAttribute("data-evdel"))!==null){ if(confirm("Delete this event?")){ var ev=W().events(); ev.splice(+a,1); W().saveEvents(ev); EVEDIT=null; refresh(); } return; }
    if(id==="evNew"){ var ev2=W().events(); ev2.push({id:"ev_"+Date.now().toString(36), title:"New event", text:"", choices:[{label:"Go on", check:0, win:{text:""}},{label:"Leave it", check:0, win:{text:""}}]}); W().saveEvents(ev2); EVEDIT=ev2.length-1; refresh(); return; }
    if(id==="evReset"){ if(confirm("Put the eight drafted events back, and remove any you added?")){ W().resetEvents(); EVEDIT=null; refresh(); } return; }
    if(id==="evAddChoice"){ saveEv(function(e){ e.choices=(e.choices||[]).concat([{label:"Another way", check:0, win:{text:""}}]); }); refresh(); return; }
    if((a=t.getAttribute("data-evcrm"))!==null){ saveEv(function(e){ e.choices.splice(+a,1); }); refresh(); return; }
    if(id==="evDone"){ EVEDIT=null; refresh(); return; }
    if(id==="wlTabReset"){ if(confirm("Put the world’s tables back to their starting values?")){ W().resetTables(); refresh(); } return; }
  });
  document.addEventListener("change",function(e){
    if(!HOST || !HOST.contains(e.target)) return;
    var el=e.target, a;
    if((a=el.getAttribute("data-wt"))){
      var t=W().tables(), p=a.split("."), v=Math.max(0,parseFloat(el.value)||0);
      if(p.length===1) t[p[0]]=v; else if(p[0]==="floorsBySkull") t.floorsBySkull[+p[1]]=Math.max(1,Math.round(v)); else t[p[0]][p[1]]=v;
      W().saveTables(t); paint(); return;
    }
    if((a=el.getAttribute("data-uq"))){ saveUq(function(u){ u[a]=el.value; }); return; }
    if((a=el.getAttribute("data-uqr"))){ saveUq(function(u){ u.reward=u.reward||{}; u.reward[a]=Math.max(0,parseFloat(el.value)||0); }); return; }
    if((a=el.getAttribute("data-uqich"))!==null){ saveUq(function(u){ u.reward.items[+a].chance=Math.max(0,Math.min(100,parseInt(el.value,10)||0)); }); return; }
    if((a=el.getAttribute("data-ev"))){ saveEv(function(ev){ ev[a]=el.value; }); return; }
    if((a=el.getAttribute("data-evc"))){ var q=a.split(":"); saveEv(function(ev){ var c=ev.choices[+q[0]]; if(q[1]==="check"){ c.check=Math.max(0,Math.min(20,parseInt(el.value,10)||0)); if(c.check&&!c.fail) c.fail={text:""}; } else c[q[1]]=el.value; }); if(a.split(":")[1]==="check") refresh(); return; }
    if((a=el.getAttribute("data-evo"))){ var r=a.split(":"); saveEv(function(ev){ var c=ev.choices[+r[0]]; c[r[1]]=c[r[1]]||{};
      c[r[1]][r[2]] = r[2]==="fight" ? !!el.checked : (r[2]==="text"||r[2]==="type") ? el.value : Math.max(0,parseFloat(el.value)||0); }); return; }
  });
  window.addEventListener("resize",function(){ if(HOST && $("wldCv") && HOST.classList.contains("on")){ VIEW.ready=false; sizeCanvas(); paint(); } });

  window.KETER_WORLD_UI={render:render, refresh:refresh, _teamToken:function(){ var st=cur(); return st?teamToken(st):null; }, _tap:tap, _walk:walk, _sel:function(k){ SEL=k; refresh(); }, state:function(){ return {sel:SEL, mode:MODE, walking:!!WALK, note:NOTE, view:VIEW}; },
    _mode:function(m){ MODE=m; refresh(); }, _pick:function(i){ PICK=i; refresh(); }, _pack:function(o){ PACK=o||{}; refresh(); }, _paint:function(){ paint(); }};
})();
