/* ===========================================================================
   KETER world (v12.8) — the video game's world map.

   The colony as a hex map: the dock at the centre, six District wedges around
   it, Skull Level rising with distance from the dock (a new level every three
   rings: 1 beside it, 6 at the border). About one tile in seven is blocked by
   collapsed structure, but every open tile can be reached from the dock.

   Tiles hold POIs (a run of floors), Ambushes (a fight sprung on stepping
   there), Caches (loot, no fight) and Events (a short situation with a
   choice). The layout, Districts and Skull rings always show; what a tile
   holds shows once the Strike Team has stood next to it, and stays known.
   A cleared POI or Cache comes back after a few deployments.

   The map is generated, and can be repainted in the POI Sandbox as a World Map
   level: Districts are tile colours (read by their labels), blocked tiles are
   tiles erased, a tile's Skull Level overrides the one its ring gives, and
   contents are symbols (DK the dock, PO, AM, CA, EV). Unique POIs, with a
   floor list you set, are placed from the World Map page in Dev Mode.
   =========================================================================== */
(function(){
  "use strict";
  var MAP_KEY="keter-app-world", STATE_KEY="keter-app-world-state", TAB_KEY="keter-app-world-tables",
      EV_KEY="keter-app-world-events", UQ_KEY="keter-app-world-unique", LEVELS_KEY="keter-hexmap-levels";
  var DIRS=[[1,0],[1,-1],[0,-1],[-1,0],[-1,1],[0,1]];
  var DISTRICT_NAMES={"1":"Threshold Dynamics","2":"Halcyon Cognition","3":"Vantage Robotics","4":"Lazarus Computing","5":"Verdant Biogenics","6":"Meridian Entropics"};
  var DCOL={"1":"#a98ef0","2":"#ef7fbe","3":"#f0a457","4":"#ef8175","5":"#6fd189","6":"#56c6da","":"#9fb3bd"};
  var KINDS=["poi","ambush","cache","event"];
  var KIND_LABEL={poi:"POI", ambush:"Ambush", cache:"Cache", event:"Event", dock:"The dock", unique:"Unique POI"};
  var POI_TYPES=["Lab","Security Armory","Bunker","Overrun Hideout"];
  /* the Sandbox's six highlight colours stand for the Districts, by label */
  var COL_OF_D={"4":0,"3":1,"2":2,"5":3,"6":4,"1":5};
  var SYMS=[{id:1,text:"DK",kind:"dock",desc:"The dock — deployments start and end here"},
            {id:2,text:"PO",kind:"poi",desc:"POI — a run of floors, drawn by District and Skull Level"},
            {id:3,text:"AM",kind:"ambush",desc:"Ambush — a fight sprung on stepping here"},
            {id:4,text:"CA",kind:"cache",desc:"Cache — loot with no fight"},
            {id:5,text:"EV",kind:"event",desc:"Event — a choice, sometimes a d20 check"}];
  var DEFAULTS={v:1, radius:18, ringsPerSkull:3, blocked:15,
    density:{poi:5, ambush:4, cache:5, event:4},
    ambushStep:5, floorsBySkull:[1,1,2,2,3,3], respawn:3, starterFree:4,
    cache:{shards:6, n:4, bonus:0, bp:30, card:35},
    poi:{shards:20, n:6, bonus:1, bp:60, card:50}};

  function clone(o){ return JSON.parse(JSON.stringify(o)); }
  /* The map is drawn a thousand tiles at a time, each asking for the tables,
     the state and the Unique POIs; parsing them once per change, not once per
     question, keeps panning smooth. A read hands back the parsed value while
     the stored text is unchanged. */
  var MEMO={};
  function read(k,d){
    try{
      var raw=localStorage.getItem(k);
      if(MEMO[k] && MEMO[k].raw===raw) return MEMO[k].v==null?d:MEMO[k].v;
      var v=JSON.parse(raw||"null"); MEMO[k]={raw:raw, v:v}; return v==null?d:v;
    }catch(e){ return d; }
  }
  function write(k,v){ try{ var raw=JSON.stringify(v); localStorage.setItem(k,raw); MEMO[k]={raw:raw, v:JSON.parse(raw)}; return true; }catch(e){ return false; } }
  function num(v,d){ var x=parseFloat(v); return isNaN(x)?d:x; }
  function rnd(){ var L=window.KETER_LOOT; return L&&L.rnd?L.rnd():Math.random(); }
  function mulberry(a){ a=a>>>0; return function(){ a=(a+0x6D2B79F5)>>>0; var t=a; t=Math.imul(t^(t>>>15),t|1); t^=t+Math.imul(t^(t>>>7),t|61); return ((t^(t>>>14))>>>0)/4294967296; }; }
  function hashStr(s){ var h=2166136261; s=String(s); for(var i=0;i<s.length;i++){ h^=s.charCodeAt(i); h=Math.imul(h,16777619); } return h>>>0; }

  /* ---- hex geometry (axial, pointy-top) ---- */
  function key(q,r){ return q+","+r; }
  function parse(k){ var a=String(k).split(","); return {q:+a[0], r:+a[1]}; }
  function dist(a,b){ if(typeof a==="string") a=parse(a); if(typeof b==="string") b=parse(b); var dq=a.q-b.q, dr=a.r-b.r; return (Math.abs(dq)+Math.abs(dr)+Math.abs(dq+dr))/2; }
  function neighbours(k){ var a=parse(k); return DIRS.map(function(d){ return key(a.q+d[0],a.r+d[1]); }); }
  function inRadius(q,r,R){ return Math.max(Math.abs(q),Math.abs(r),Math.abs(q+r))<=R; }
  function allKeys(R){ var out=[]; for(var q=-R;q<=R;q++) for(var r=Math.max(-R,-q-R);r<=Math.min(R,-q+R);r++) out.push(key(q,r)); return out; }

  /* ---- tables: your changes only, so later defaults still arrive ---- */
  var TCACHE=null, TRAW=undefined;
  function tables(){
    var raw=null; try{ raw=localStorage.getItem(TAB_KEY); }catch(e){}
    if(TCACHE && raw===TRAW) return clone(TCACHE);
    TRAW=raw; TCACHE=tablesFresh(); return clone(TCACHE);
  }
  /* the ring a tile is on decides its Skull Level: read without a copy */
  function ringsPerSkull(){ tables(); return TCACHE.ringsPerSkull; }
  function tablesFresh(){
    var t=clone(DEFAULTS), m=read(TAB_KEY,null);
    if(m && typeof m==="object"){
      ["radius","ringsPerSkull","blocked","ambushStep","respawn","starterFree"].forEach(function(k){ if(isFinite(+m[k])&&m[k]!=="") t[k]=Math.max(0,+m[k]); });
      if(m.density) KINDS.forEach(function(k){ if(isFinite(+m.density[k])) t.density[k]=Math.max(0,+m.density[k]); });
      if(Array.isArray(m.floorsBySkull)&&m.floorsBySkull.length===6) t.floorsBySkull=m.floorsBySkull.map(function(v,i){ var x=parseInt(v,10); return x>0?Math.min(9,x):DEFAULTS.floorsBySkull[i]; });
      ["cache","poi"].forEach(function(s){ if(m[s]) ["shards","n","bonus","bp","card"].forEach(function(k){ if(isFinite(+m[s][k])) t[s][k]=Math.max(0,+m[s][k]); }); });
    }
    t.radius=Math.max(3,Math.min(20,Math.round(t.radius))); t.ringsPerSkull=Math.max(1,Math.round(t.ringsPerSkull));
    t.blocked=Math.min(40,t.blocked);
    return t;
  }
  function saveTables(t){
    var d={}, D=DEFAULTS;
    ["radius","ringsPerSkull","blocked","ambushStep","respawn","starterFree"].forEach(function(k){ if(+t[k]!==D[k]) d[k]=+t[k]; });
    KINDS.forEach(function(k){ if(+t.density[k]!==D.density[k]){ d.density=d.density||{}; d.density[k]=+t.density[k]; } });
    if(JSON.stringify(t.floorsBySkull.map(Number))!==JSON.stringify(D.floorsBySkull)) d.floorsBySkull=t.floorsBySkull.map(Number);
    ["cache","poi"].forEach(function(s){ ["shards","n","bonus","bp","card"].forEach(function(k){ if(+t[s][k]!==D[s][k]){ d[s]=d[s]||{}; d[s][k]=+t[s][k]; } }); });
    return write(TAB_KEY,d);
  }
  function resetTables(){ try{ localStorage.removeItem(TAB_KEY); }catch(e){} }

  /* ---- generating a map ---- */
  function generate(seed){
    seed=(seed==null?(Date.now()%2147483647):seed)>>>0;
    var T=tables(), R=T.radius, rng=mulberry(seed||1), keys=allKeys(R), tiles={}, dock="0,0";
    var ph=[rng()*6.283, rng()*6.283];
    /* six wedges from the dock, their borders wavering a little */
    keys.forEach(function(k){
      var a=parse(k), x=Math.sqrt(3)*(a.q+a.r/2), y=1.5*a.r, d=dist(a,{q:0,r:0});
      var ang=Math.atan2(y,x), wob=0.16*Math.sin(3*ang+ph[0]+d*0.35)+0.09*Math.sin(5*ang+ph[1]+d*0.6);
      var sec=Math.floor((((ang+wob+Math.PI/2)%(2*Math.PI))+2*Math.PI)%(2*Math.PI)/(Math.PI/3))%6;
      tiles[k]={d:d===0?"":String(sec+1), c:"", s:0};
    });
    tiles[dock].c="dock";
    /* collapsed sections: small blobs, never beside the dock */
    var target=Math.round(T.blocked/100*(keys.length-7)), blocked={}, nb=0, guard=0;
    var far=keys.filter(function(k){ return dist(k,dock)>=2; });
    while(nb<target && guard++<target*20){
      var start=far[Math.floor(rng()*far.length)]; if(blocked[start]) continue;
      var size=1+Math.floor(rng()*4), blob=[start];
      while(blob.length<size){ var from=blob[Math.floor(rng()*blob.length)], n=neighbours(from)[Math.floor(rng()*6)]; if(tiles[n]&&dist(n,dock)>=2&&blob.indexOf(n)<0) blob.push(n); else if(rng()<0.3) break; }
      blob.forEach(function(k){ if(!blocked[k]&&nb<target){ blocked[k]=1; nb++; } });
    }
    Object.keys(blocked).forEach(function(k){ delete tiles[k]; });
    /* every open tile reachable: carve a way through where a pocket is sealed */
    var tries=0;
    while(tries++<200){
      var seen=reach(tiles,dock), lost=Object.keys(tiles).filter(function(k){ return !seen[k]; });
      if(!lost.length) break;
      var path=bfsAny(lost[0], function(k){ return !!seen[k]; }, function(k){ var a=parse(k); return inRadius(a.q,a.r,R); });
      if(!path) { delete tiles[lost[0]]; continue; }
      path.forEach(function(k){ if(!tiles[k]){ var a=parse(k); tiles[k]={d:wedgeOf(a,ph), c:"", s:0}; } });
    }
    /* contents, on open tiles at least two steps out */
    var el=Object.keys(tiles).filter(function(k){ return dist(k,dock)>=2; });
    for(var i=el.length-1;i>0;i--){ var j=Math.floor(rng()*(i+1)), t=el[i]; el[i]=el[j]; el[j]=t; }
    var at=0;
    KINDS.forEach(function(kind){
      var n=Math.round(T.density[kind]/100*el.length);
      for(var m=0;m<n && at<el.length;m++){ var k2=el[at++]; tiles[k2].c=kind; if(kind==="poi") tiles[k2].t=POI_TYPES[Math.floor(rng()*POI_TYPES.length)]; }
    });
    return {v:1, seed:seed, radius:R, name:"KETER · map "+seed, source:"generated", dock:dock, tiles:tiles, made:new Date().toISOString()};
  }
  function wedgeOf(a, ph){
    var x=Math.sqrt(3)*(a.q+a.r/2), y=1.5*a.r, d=dist(a,{q:0,r:0}), ang=Math.atan2(y,x);
    var wob=0.16*Math.sin(3*ang+ph[0]+d*0.35)+0.09*Math.sin(5*ang+ph[1]+d*0.6);
    return d===0?"":String((Math.floor((((ang+wob+Math.PI/2)%(2*Math.PI))+2*Math.PI)%(2*Math.PI)/(Math.PI/3))%6)+1);
  }
  function reach(tiles, from){
    var seen={}, q=[from]; if(!tiles[from]) return seen; seen[from]=1;
    while(q.length){ var k=q.shift(); neighbours(k).forEach(function(n){ if(tiles[n]&&!seen[n]){ seen[n]=1; q.push(n); } }); }
    return seen;
  }
  /* shortest way from one tile to the nearest that passes `done`, over tiles `ok` allows */
  function bfsAny(from, done, ok){
    var prev={}, q=[from]; prev[from]=null;
    while(q.length){
      var k=q.shift();
      if(k!==from && done(k)){ var p=[], c=k; while(c!=null){ p.unshift(c); c=prev[c]; } return p; }
      neighbours(k).forEach(function(n){ if(!(n in prev) && ok(n)){ prev[n]=k; q.push(n); } });
    }
    return null;
  }

  /* ---- the live map ---- */
  var CACHE=null;
  function map(){
    if(CACHE) return CACHE;
    var m=read(MAP_KEY,null);
    if(!m || !m.tiles){ m=generate(); write(MAP_KEY,m); }
    CACHE=m; return m;
  }
  function setMap(m, keepState){ CACHE=null; write(MAP_KEY,m); CACHE=m; if(!keepState) resetState(); return m; }
  function newMap(seed){ return setMap(generate(seed), false); }
  function tile(k){ return map().tiles[k]||null; }
  function isOpen(k){ return !!map().tiles[k]; }
  function skullOf(k){
    var t=tile(k), m=map(); if(!t) return 0;
    if(t.s>=1&&t.s<=6) return t.s;
    var d=dist(k,m.dock); if(d===0) return 1;
    return Math.max(1,Math.min(6,Math.ceil(d/ringsPerSkull())));
  }
  function districtOf(k){ var t=tile(k); return t?String(t.d||""):""; }
  function ambushChance(k){ if(!isOpen(k)||k===map().dock) return 0; tables(); return Math.min(100, TCACHE.ambushStep*skullOf(k)); }
  function poiTypeOf(k){ var t=tile(k); return (t&&t.t) || POI_TYPES[hashStr(k+":"+map().seed)%POI_TYPES.length]; }

  /* ---- the player's knowledge of it ---- */
  function blankState(){ return {v:1, known:{}, stood:{}, cleared:{}, completed:0}; }
  function state(){ var s=read(STATE_KEY,null); s=s?clone(s):blankState(); s.known=s.known||{}; s.stood=s.stood||{}; s.cleared=s.cleared||{}; s.completed=+s.completed||0; return s; }
  /* for reading only: no copy */
  function peek(){ var s=read(STATE_KEY,null)||blankState(); return {known:s.known||{}, cleared:s.cleared||{}, completed:+s.completed||0}; }
  function saveState(s){ return write(STATE_KEY,s); }
  function resetState(){ try{ localStorage.removeItem(STATE_KEY); }catch(e){} }
  /* standing on a tile shows what it and its neighbours hold, for good */
  /* v12.9: the dock's Long-range scanner sees further than the next tile */
  function stand(k, range){
    var s=state(); s.stood[k]=1; s.known[k]=1;
    range=Math.max(1, range || (window.KETER_DOCK ? window.KETER_DOCK.scanRange() : 1));
    if(range<=1) neighbours(k).forEach(function(n){ if(isOpen(n)) s.known[n]=1; });
    else { var a=parse(k); for(var dq=-range;dq<=range;dq++) for(var dr=Math.max(-range,-dq-range);dr<=Math.min(range,-dq+range);dr++){ var n=key(a.q+dq,a.r+dr); if(isOpen(n)) s.known[n]=1; } }
    saveState(s); return s;
  }
  function knownCount(){ return Object.keys(peek().known).length; }
  function known(k){ if(dev()) return true; return !!peek().known[k]; }
  function dev(){ try{ return !!(window.KETER_PROG && window.KETER_PROG.dev()); }catch(e){ return false; } }

  /* ---- what a tile holds ---- */
  function uniques(){ var u=read(UQ_KEY,[]); return Array.isArray(u)?clone(u):[]; }
  function uniqueList(){ var u=read(UQ_KEY,[]); return Array.isArray(u)?u:[]; }
  function saveUniques(u){ return write(UQ_KEY,u); }
  function uniqueAt(k){ var l=uniqueList(); for(var i=0;i<l.length;i++) if(l[i]&&l[i].tile===k) return l[i]; return null; }
  function contentAt(k){
    var t=tile(k); if(!t) return null;
    var u=uniqueAt(k);
    if(u) return {kind:"poi", unique:u, type:u.type||"Unique POI", name:u.name||"Unique POI"};
    if(!t.c) return null;
    if(t.c==="poi") return {kind:"poi", type:poiTypeOf(k), name:poiTypeOf(k)};
    return {kind:t.c, name:KIND_LABEL[t.c]||t.c};
  }
  /* cleared in deployment N comes back once N + respawn deployments have ended */
  function isCleared(k){
    var s=peek(), c=s.cleared[k]; if(!c) return false;
    tables(); return s.completed < c + TCACHE.respawn;
  }
  function clear(k, deploymentNo){ var s=state(); s.cleared[k]=deploymentNo||(s.completed+1); saveState(s); }
  function available(k){ var c=contentAt(k); return !!c && c.kind!=="dock" && !isCleared(k); }
  function backIn(k){ var s=peek(), c=s.cleared[k]; if(!c) return 0; return Math.max(0, c+tables().respawn-s.completed); }
  function endDeployment(){ var s=state(); s.completed++; saveState(s); return s.completed; }

  /* ---- the way there: shortest over open tiles ---- */
  function path(from, to){
    if(!isOpen(to)) return null; if(from===to) return [from];
    var prev={}, q=[from]; prev[from]=null;
    while(q.length){
      var k=q.shift(); if(k===to) break;
      neighbours(k).forEach(function(n){ if(!(n in prev) && isOpen(n)){ prev[n]=k; q.push(n); } });
    }
    if(!(to in prev)) return null;
    var p=[], c=to; while(c!=null){ p.unshift(c); c=prev[c]; } return p;
  }
  /* the chance of at least one ambush along a path, not counting its start */
  function pathRisk(p){ var none=1; (p||[]).slice(1).forEach(function(k){ none*=1-ambushChance(k)/100; }); return Math.round(100*(1-none)); }

  /* ---- floors for fights ---- */
  function districtNum(v){ var m=/^\s*(\d)/.exec(String(v||"")); return m?m[1]:""; }
  function floorSkull(lv){
    var base=parseInt(lv.level,10); if(base>=1&&base<=6) return base;
    var labels=lv.colorLabels||{}, lo=0;
    (lv.hexes||[]).forEach(function(p){ var v=p[1]||{}, lab=String(labels[v.c]||""); if(/enemy/i.test(lab)&&/spawn/i.test(lab)){ var l=parseInt(v.lvl,10)||1; if(!lo||l<lo) lo=l; } });
    return lo||1;
  }
  function floors(){
    var all=read(LEVELS_KEY,{})||{};
    return Object.keys(all).filter(function(k){ var l=all[k]; return l && String(l.poiType||"")!=="World Map" && !(l.chunk && typeof l.chunk==="object") && (l.hexes||[]).length; })
      .map(function(k){ var l=all[k]; return {key:k, name:l.name||k, district:districtNum(l.district), skull:floorSkull(l), type:String(l.poiType||""),
        size:String(l.battlefieldSize||l.floorSize||"").toLowerCase(), test:!!l.testMap, tiles:(l.hexes||[]).length}; });
  }
  /* the best matches first: same District, then none set, then any; nearest
     Skull Level; your own floors before the test floors */
  /* (v14.7) the chunks in the floor library, which battlefields are grown from */
  function chunks(){
    var all=read(LEVELS_KEY,{})||{};
    return Object.keys(all).map(function(k){ return all[k]; }).filter(function(l){ return l && l.chunk && typeof l.chunk==="object" && (l.hexes||[]).length; });
  }
  /* (v14.7) a fight's floor, as the Sandbox saves one: a generated one made again from its key */
  function level(k){
    var G=window.KETER_CHUNKGEN;
    if(G && G.isGenKey(k)) return G.fromKey(chunks(), k);
    var all=read(LEVELS_KEY,{})||{}; return all[k]||null;
  }
  /* (v14.7) a POI's floors, grown from chunks where the District has them: a
     medium battlefield for each (the last one large from Skull 4), an ambush a
     small one. The same POI grows the same until it is cleared. A POI of more
     than one floor ends on a hand-made Boss floor when one fits its District
     and Skull. Unique POIs keep their own floors (deploy.js). */
  function grownFloors(district, skull, count, opts){
    var G=window.KETER_CHUNKGEN, ch=chunks(), d=String(district||"");
    if(!G || !G.can(ch, d, skull)) return null;
    var base=opts.ambush ? Math.floor(rnd()*4294967296)>>>0 : hashStr(String(opts.tile||"")+":"+map().seed+":"+(peek().cleared[opts.tile]||0));
    var out=[];
    for(var i=0;i<count;i++){
      var size=opts.ambush?"small":((i===count-1 && skull>=4)?"large":"medium"), seed=(base+i*7919)>>>0;
      if(!G.generate(ch, d, skull, size, seed)) return null;
      out.push(G.genKey(d, skull, size, seed));
    }
    if(!opts.ambush && count>1){
      var boss=floors().filter(function(f){ return /boss/i.test(f.type) && f.district===d && Math.abs(f.skull-skull)<=1; })
        .sort(function(a,b){ return a.key<b.key?-1:(a.key>b.key?1:0); });
      if(boss.length) out[count-1]=boss[hashStr(base+":boss")%boss.length].key;
    }
    return out;
  }
  function drawFloors(district, skull, count, opts){
    opts=opts||{};
    var grown=grownFloors(district, skull, count, opts); if(grown) return grown;
    var fl=floors().filter(function(f){ return !/boss/i.test(f.type); }); if(!fl.length) fl=floors(); if(!fl.length) return [];
    var score=function(f){
      var ds=f.district===String(district||"")?0:(f.district===""?1:2);
      var ks=Math.abs(f.skull-skull), ts=f.test?0.5:0;
      var ty=opts.ambush ? (/ambush/i.test(f.type)?-1:(f.size==="small"?-0.5:0)) : (/ambush/i.test(f.type)?1:0);
      return ds*10+ks+ts+ty;
    };
    var ranked=fl.map(function(f){ return {f:f, s:score(f)+rnd()*0.3}; }).sort(function(a,b){ return a.s-b.s; }).map(function(x){ return x.f; });
    var out=[]; for(var i=0;i<count;i++) out.push(ranked[i%ranked.length].key);
    return out;
  }
  function floorCount(skull){ var t=tables(); return t.floorsBySkull[Math.max(1,Math.min(6,skull))-1]||1; }

  /* ---- the Sandbox: a map as a World Map level, and back ---- */
  function toLevel(m, name){
    m=m||map(); var hexes=[], marks=[];
    Object.keys(m.tiles).forEach(function(k){
      var t=m.tiles[k], v={c:(t.d&&COL_OF_D[t.d]!==undefined)?COL_OF_D[t.d]:null};
      if(t.s>=1&&t.s<=6) v.lvl=t.s;
      hexes.push([k,v]);
      var sy=SYMS.filter(function(x){ return x.kind===t.c; })[0];
      if(sy) marks.push([k,sy.id]);
    });
    var labels={}; Object.keys(COL_OF_D).forEach(function(d){ labels[COL_OF_D[d]]="District "+d+" · "+DISTRICT_NAMES[d]; });
    return {v:6, name:name||m.name||"World Map", district:"", poiType:"World Map", level:"", floorSize:"", battlefieldSize:"",
      notes:"The video game's world map (v12.8). Colours are Districts; an erased tile is blocked; a tile's Skull Level (the Spawn level tool) overrides its ring; DK is the dock, PO a POI, AM an Ambush, CA a Cache, EV an Event.",
      rewards:"", sizeKey:"one", radius:m.radius||18, labels:false, ink:false, hexes:hexes, marks:marks, walls:[],
      symDefs:SYMS.map(function(s){ return {id:s.id, text:s.text, desc:s.desc}; }), nextDef:SYMS.length+1,
      colorLabels:labels, wallLabels:{}, saved:new Date().toISOString(), worldSeed:m.seed};
  }
  function saveToSandbox(name){
    var all=read(LEVELS_KEY,{})||{}, lv=toLevel(map(), name); all[lv.name]=lv;
    if(!write(LEVELS_KEY,all)) return null;
    var m=map(); m.source="sandbox:"+lv.name; m.sourceSaved=lv.saved; setMap(m,true);
    return lv.name;
  }
  function fromLevel(lv){
    var labels=lv.colorLabels||{}, dOf={};
    Object.keys(labels).forEach(function(c){ var m=/district\s*(\d)/i.exec(String(labels[c]||"")); if(m) dOf[c]=m[1]; });
    var sym={}; (lv.symDefs||[]).forEach(function(d){ var s=SYMS.filter(function(x){ return x.text===String(d.text||"").trim().toUpperCase(); })[0]; if(s) sym[d.id]=s.kind; });
    var tiles={}, dock=null;
    (lv.hexes||[]).forEach(function(p){ var v=p[1]||{}, l=parseInt(v.lvl,10); tiles[p[0]]={d:(v.c!==null&&v.c!==undefined&&dOf[v.c])||"", c:"", s:(l>=1&&l<=6)?l:0}; });
    (lv.marks||[]).forEach(function(p){ var k=p[0], kind=sym[p[1]]; if(!kind||!tiles[k]) return; if(kind==="dock"){ if(!dock) dock=k; } else tiles[k].c=kind; });
    if(!dock) dock=tiles["0,0"]?"0,0":Object.keys(tiles)[0];
    if(!dock) return null;
    tiles[dock].c="dock"; tiles[dock].d="";
    var seed=lv.worldSeed||hashStr(lv.name||"");
    return {v:1, seed:seed, radius:Math.max(3,Math.min(20,lv.radius||18)), name:lv.name||"World Map", source:"sandbox:"+(lv.name||""), sourceSaved:lv.saved||"", dock:dock, tiles:tiles, made:new Date().toISOString()};
  }
  function sandboxMaps(){
    var all=read(LEVELS_KEY,{})||{};
    return Object.keys(all).filter(function(k){ return all[k] && String(all[k].poiType||"")==="World Map"; })
      .map(function(k){ return {key:k, name:all[k].name||k, saved:all[k].saved||"", tiles:(all[k].hexes||[]).length}; });
  }
  /* using an edited map keeps what the player has found when it is the same map */
  function useSandbox(key){
    var all=read(LEVELS_KEY,{})||{}, lv=all[key]; if(!lv) return null;
    var m=fromLevel(lv); if(!m) return null;
    var same=String(map().source||"")==="sandbox:"+key || (lv.worldSeed && lv.worldSeed===map().seed);
    setMap(m, same); return m;
  }
  function sandboxNewer(){
    var m=map(), src=/^sandbox:(.+)$/.exec(String(m.source||"")); if(!src) return false;
    var lv=(read(LEVELS_KEY,{})||{})[src[1]]; return !!lv && String(lv.saved||"")>String(m.sourceSaved||"");
  }

  /* ---- Events: eight to start, yours to rewrite ---- */
  var DEFAULT_EVENTS=[
    {id:"ev_hatch", title:"Sealed maintenance hatch", text:"A hatch welded shut from the inside. Something behind it ticks, slow and even, like a clock nobody wound.",
      choices:[{label:"Cut it open", check:10, win:{text:"A dead technician's cache: tools, fittings and a few shards.", shards:2, n:2, type:"any"}, fail:{text:"The ticking stops. Something was waiting.", fight:true}},
               {label:"Leave it sealed", check:0, win:{text:"You leave the ticking behind."}}]},
    {id:"ev_signal", title:"A survivor's signal", text:"A distress call loops on an old Security frequency. The voice gives a location two corridors over, then starts again, word for word.",
      choices:[{label:"Follow the signal", check:12, win:{text:"A survivor's stash. The survivor is long gone, but not the notes.", shards:3, bp:25}, fail:{text:"The voice was a lure.", fight:true}},
               {label:"Switch it off", check:0, win:{text:"Silence. Better that way."}}]},
    {id:"ev_bloom", title:"Aether bloom", text:"Raw Aetherite has crystallised across the corridor, humming at a pitch you feel in your teeth.",
      choices:[{label:"Harvest it", check:11, win:{text:"The crystals come away clean.", n:2, type:"aether", bonus:1}, fail:{text:"The bloom flares. Some of what you carry is scorched.", lose:15}},
               {label:"Go around", check:0, win:{text:"You give it a wide berth."}}]},
    {id:"ev_checkpoint", title:"Abandoned checkpoint", text:"A Security checkpoint, its turrets dark. The lockers behind the desk are still shut.",
      choices:[{label:"Search the lockers", check:8, win:{text:"Spare plating and a sidearm's worth of parts.", n:2, type:"equipment"}, fail:{text:"The turrets wake.", fight:true}},
               {label:"Walk past", check:0, win:{text:"The turrets stay dark."}}]},
    {id:"ev_scav", title:"Scav marker", text:"Scav graffiti on the bulkhead: a circle, three lines, an arrow. Someone's stash.",
      choices:[{label:"Dig it up", check:9, win:{text:"The stash is still there.", shards:4}, fail:{text:"Someone got here first. Only an empty crate."}},
               {label:"Leave it for them", check:0, win:{text:"You leave the mark alone."}}]},
    {id:"ev_terminal", title:"Whispering terminal", text:"A Lazarus terminal wakes as you pass. Its screen scrolls a script you can't read, and the speaker says your name.",
      choices:[{label:"Read it", check:13, win:{text:"Among the noise, a schematic.", bp:50}, fail:{text:"The screen goes white. When your eyes clear, some of the haul is gone, and something is coming.", lose:20, fight:true}},
               {label:"Smash it", check:0, win:{text:"Glass and silence."}}]},
    {id:"ev_drone", title:"Pinned research drone", text:"Rubble has pinned a Vantage research drone, still twitching. Its chassis looks salvageable.",
      choices:[{label:"Salvage the drone", check:10, win:{text:"Its actuators come free.", n:3, type:"troop"}, fail:{text:"Its distress beacon was still on.", fight:true}},
               {label:"Move on", check:0, win:{text:"It twitches as you go."}}]},
    {id:"ev_tear", title:"Dimensional tear", text:"The air folds. Beyond it, the same corridor, but wrong: the lights are the colour of a bruise.",
      choices:[{label:"Step through", check:14, win:{text:"You come back with things that should not exist here.", n:2, type:"any", bonus:2, bp:30}, fail:{text:"Something follows you back, and the tear takes its toll.", lose:20, fight:true}},
               {label:"Back away", check:0, win:{text:"The fold smooths over."}}]}
  ];
  function events(){ var e=read(EV_KEY,null); return Array.isArray(e)&&e.length?clone(e):clone(DEFAULT_EVENTS); }
  function saveEvents(e){ return write(EV_KEY,e); }
  function resetEvents(){ try{ localStorage.removeItem(EV_KEY); }catch(e){} }
  /* the event on a tile: fixed for that tile until it is cleared and comes back */
  function eventFor(k){
    var e=events(); if(!e.length) return null;
    var s=state(); return e[hashStr(k+":"+map().seed+":"+(s.cleared[k]||0))%e.length];
  }

  window.KETER_WORLD={MAP_KEY:MAP_KEY, STATE_KEY:STATE_KEY, TAB_KEY:TAB_KEY, EV_KEY:EV_KEY, UQ_KEY:UQ_KEY,
    DEFAULTS:DEFAULTS, KINDS:KINDS, KIND_LABEL:KIND_LABEL, POI_TYPES:POI_TYPES, DISTRICT_NAMES:DISTRICT_NAMES, DCOL:DCOL, SYMS:SYMS, COL_OF_D:COL_OF_D,
    key:key, parse:parse, dist:dist, neighbours:neighbours, allKeys:allKeys, mulberry:mulberry, hashStr:hashStr,
    tables:tables, saveTables:saveTables, resetTables:resetTables,
    generate:generate, map:map, setMap:setMap, newMap:newMap, tile:tile, isOpen:isOpen, skullOf:skullOf, districtOf:districtOf,
    ambushChance:ambushChance, poiTypeOf:poiTypeOf, reach:reach,
    state:state, saveState:saveState, resetState:resetState, stand:stand, known:known, knownCount:knownCount,
    uniques:uniques, saveUniques:saveUniques, uniqueAt:uniqueAt, contentAt:contentAt, isCleared:isCleared, clear:clear, available:available, backIn:backIn, endDeployment:endDeployment,
    path:path, pathRisk:pathRisk, floors:floors, chunks:chunks, level:level, drawFloors:drawFloors, floorCount:floorCount, floorSkull:floorSkull, districtNum:districtNum,
    toLevel:toLevel, saveToSandbox:saveToSandbox, fromLevel:fromLevel, sandboxMaps:sandboxMaps, useSandbox:useSandbox, sandboxNewer:sandboxNewer,
    DEFAULT_EVENTS:DEFAULT_EVENTS, events:events, saveEvents:saveEvents, resetEvents:resetEvents, eventFor:eventFor,
    _flush:function(){ CACHE=null; }};
})();
