/* ==========================================================================
   KETER loot (v12.6) — the video game's economy, not the board game's.

   Components: three part types (Troop, Equipment, Aether) in six rarities,
   Common to Mythic — eighteen kinds that stack, each with a name you can
   change. Aether shards are the currency; every drop includes some.

   The generator: a source (an Enemy, an Elite, a Mini-Boss, a Boss, a Loot
   Tile, a Locked Chest) and a Skull Level decide the shards, how many
   components, their type and their rarity. Skull N can drop up to the Nth
   rarity, weighted low; a tougher source rolls one Skull higher.

   A floor can carry its own reward — exact items, rolled ones, or both —
   given when it is cleared. Won loot goes into the stockpile on this device.

   Everything numeric is a table you can change on the Loot page; this file
   holds the starting values.
   ========================================================================== */
(function(){
  "use strict";
  var RARITIES=[
    {id:"common",    label:"Common",    color:"#6b7d86", lite:"#a8bac2"},
    {id:"uncommon",  label:"Uncommon",  color:"#38914c", lite:"#6fd189"},
    {id:"rare",      label:"Rare",      color:"#2563c4", lite:"#6ba6f5"},
    {id:"epic",      label:"Epic",      color:"#7b3fc4", lite:"#b98ef0"},
    {id:"legendary", label:"Legendary", color:"#c07a12", lite:"#f0bd57"},
    {id:"mythic",    label:"Mythic",    color:"#c02f52", lite:"#f2789a"}];
  var TYPES=[
    {id:"troop",     label:"Troop parts",     short:"Troop"},
    {id:"equipment", label:"Equipment parts", short:"Equipment"},
    {id:"aether",    label:"Aether parts",    short:"Aether"}];
  var SALVAGE=[
    {id:"mixed",     label:"Mixed"},
    {id:"troop",     label:"Troop"},
    {id:"equipment", label:"Equipment"},
    {id:"aether",    label:"Aether"}];
  var SOURCE_ORDER=["enemy","elite","miniboss","boss","lootTile","chest"];

  var DEFAULTS={
    v:1,
    names:{
      troop:    ["Scrap servos","Actuator packs","Myomer bundles","Neural harness","Synthetic spine","Aetherborn heart"],
      equipment:["Machined fittings","Alloy plating","Focusing coils","Plasma cells","Phase lattice","Singularity core"],
      aether:   ["Inert Aetherite","Charged filaments","Resonant crystals","Aetherite prisms","Void glass","Rift seed"]},
    /* the share of components of each rarity, by Skull Level (rows 1 to 6) */
    weights:[
      [100, 0, 0, 0, 0, 0],
      [ 60,40, 0, 0, 0, 0],
      [ 40,35,25, 0, 0, 0],
      [ 28,30,26,16, 0, 0],
      [ 20,25,25,19,11, 0],
      [ 15,20,23,20,15, 7]],
    /* shards: this many per Skull Level, give or take `spread` per cent.
       parts: how many components, from min to max (a chest: the number on
       its tile). bonus: rolls as if this many Skull Levels higher. top: this
       many of them come at the highest rarity it can reach. skull: whose
       Skull Level — the Unit's own, or the POI's. bp (v12.7): the chance, in
       per cent, of a blueprint or chassis from the pools as well. card (v14.9):
       the chance, in per cent, of a Consumable or a Prototype of the District. */
    sources:{
      enemy:   {label:"Enemy",        shards:4,  min:2, max:2, bonus:0, top:0, bp:4,  card:0,   skull:"own"},
      elite:   {label:"Elite",        shards:8,  min:4, max:4, bonus:1, top:0, bp:12, card:40,  skull:"own"},
      miniboss:{label:"Mini-Boss",    shards:16, min:6, max:6, bonus:1, top:0, bp:30, card:75,  skull:"own"},
      boss:    {label:"Boss",         shards:32, min:10,max:10,bonus:0, top:2, bp:70, card:100, skull:"poi"},
      lootTile:{label:"Loot Tile",    shards:6,  min:2, max:4, bonus:0, top:0, bp:16, card:0,   skull:"poi"},
      chest:   {label:"Locked Chest", shards:6,  min:0, max:0, bonus:0, top:0, bp:30, card:25,  skull:"poi", fromTile:true}},
    spread:50,
    chestDefault:4
  };

  /* ---- randomness: Math.random, or a seeded stream for the checks ---- */
  var RNG=Math.random;
  function mulberry(seed){ var a=seed>>>0; return function(){ a=(a+0x6D2B79F5)>>>0; var t=a; t=Math.imul(t^(t>>>15),t|1); t^=t+Math.imul(t^(t>>>7),t|61); return ((t^(t>>>14))>>>0)/4294967296; }; }
  function seed(n){ RNG=(n==null)?Math.random:mulberry(n); }
  function rnd(){ return RNG(); }
  function between(a,b){ a=Math.floor(a); b=Math.floor(b); if(b<a){ var t=a; a=b; b=t; } return a+Math.floor(rnd()*(b-a+1)); }

  /* ---- the tables: the defaults, with your changes over them ---- */
  var TABLE_KEY="keter-app-loot";
  function clone(o){ return JSON.parse(JSON.stringify(o)); }
  function tables(){
    var t=clone(DEFAULTS), mine=null;
    try{ mine=JSON.parse(localStorage.getItem(TABLE_KEY)||"null"); }catch(e){}
    if(mine && typeof mine==="object"){
      if(mine.names) TYPES.forEach(function(ty){ (mine.names[ty.id]||[]).forEach(function(n,i){ if(i<6 && n && String(n).trim()) t.names[ty.id][i]=String(n).trim(); }); });
      if(Array.isArray(mine.weights)) mine.weights.forEach(function(row,s){ if(s<6 && Array.isArray(row)) row.forEach(function(w,r){ if(r<6){ var v=+w; if(isFinite(v) && v>=0) t.weights[s][r]=v; } }); });
      if(mine.sources) Object.keys(t.sources).forEach(function(k){ var m=mine.sources[k]; if(!m) return;
        ["shards","min","max","bonus","top","bp","card"].forEach(function(f){ var v=+m[f]; if(m[f]!==undefined && isFinite(v) && v>=0) t.sources[k][f]=v; }); });
      if(isFinite(+mine.spread) && mine.spread!==undefined) t.spread=Math.max(0,Math.min(100,+mine.spread));
    }
    return t;
  }
  /* only what differs from the defaults is kept, so later defaults still reach you */
  function saveTables(t){
    var d=DEFAULTS, out={names:{}, weights:null, sources:{}};
    TYPES.forEach(function(ty){ var any=false, row=t.names[ty.id].map(function(n,i){ if(n!==d.names[ty.id][i]){ any=true; return n; } return ""; }); if(any) out.names[ty.id]=row; });
    if(JSON.stringify(t.weights)!==JSON.stringify(d.weights)) out.weights=t.weights;
    Object.keys(d.sources).forEach(function(k){ var o={}, any=false;
      ["shards","min","max","bonus","top","bp","card"].forEach(function(f){ if(t.sources[k][f]!==d.sources[k][f]){ o[f]=t.sources[k][f]; any=true; } });
      if(any) out.sources[k]=o; });
    if(t.spread!==d.spread) out.spread=t.spread;
    try{ localStorage.setItem(TABLE_KEY,JSON.stringify(out)); return true; }catch(e){ return false; }
  }
  function resetTables(){ try{ localStorage.removeItem(TABLE_KEY); }catch(e){} }

  /* ---- a bag of loot: shards, and a count of each of the eighteen ---- */
  function bag(){ return {shards:0, parts:{troop:[0,0,0,0,0,0], equipment:[0,0,0,0,0,0], aether:[0,0,0,0,0,0]}}; }
  function norm(b){
    var o=bag(); if(!b) return o;
    o.shards=Math.max(0,Math.floor(+b.shards||0));
    TYPES.forEach(function(ty){ var r=(b.parts||{})[ty.id]||[]; for(var i=0;i<6;i++) o.parts[ty.id][i]=Math.max(0,Math.floor(+r[i]||0)); });
    return o;
  }
  function add(a,b){ var o=norm(a); b=norm(b); o.shards+=b.shards; TYPES.forEach(function(ty){ for(var i=0;i<6;i++) o.parts[ty.id][i]+=b.parts[ty.id][i]; }); return o; }
  function count(b){ var n=0; b=norm(b); TYPES.forEach(function(ty){ b.parts[ty.id].forEach(function(v){ n+=v; }); }); return n; }
  function isEmpty(b){ b=norm(b); return !b.shards && !count(b); }
  function nameOf(type, rarity, t){ t=t||tables(); var row=t.names[type]; return (row&&row[rarity])||(RARITIES[rarity].label+" "+type+" parts"); }
  /* what is in a bag, rarest first */
  function lines(b, t){
    t=t||tables(); b=norm(b); var out=[];
    for(var r=5;r>=0;r--) TYPES.forEach(function(ty){ var n=b.parts[ty.id][r]; if(n) out.push({type:ty.id, rarity:r, n:n, name:nameOf(ty.id,r,t), rarityLabel:RARITIES[r].label, color:RARITIES[r].lite}); });
    return out;
  }
  function text(b, t){
    b=norm(b); var bits=[];
    if(b.shards) bits.push(b.shards+" shard"+(b.shards===1?"":"s"));
    lines(b,t).forEach(function(l){ bits.push(l.n+" × "+l.name); });
    return bits.join(", ")||"nothing";
  }

  /* ---- rolling ---- */
  function clampSkull(s){ s=parseInt(s,10); return (s>=1&&s<=6)?s:1; }
  /* one rarity, as if at this Skull Level */
  function rollRarity(skull, t){
    t=t||tables(); var row=t.weights[clampSkull(Math.min(6,skull))-1], tot=0, i;
    for(i=0;i<6;i++) tot+=Math.max(0,row[i]||0);
    if(tot<=0) return 0;
    var x=rnd()*tot;
    for(i=0;i<6;i++){ x-=Math.max(0,row[i]||0); if(x<0) return i; }
    return 5;
  }
  /* the rarest a Skull Level can give */
  function topRarity(skull, t){ t=t||tables(); var row=t.weights[clampSkull(Math.min(6,skull))-1]; for(var i=5;i>=0;i--) if((row[i]||0)>0) return i; return 0; }
  function pickType(salvage){
    var s=String(salvage||"mixed").toLowerCase();
    if(s==="troop"||s==="equipment"||s==="aether") return s;
    return TYPES[Math.floor(rnd()*3)].id;
  }
  /* o: {source, skull (the Unit's own), poiSkull, salvage, x (a chest's number)} */
  function roll(o, t){
    o=o||{}; t=t||tables();
    var src=t.sources[o.source]||t.sources.enemy, out=bag();
    var skull=clampSkull(src.skull==="poi" ? (o.poiSkull||o.skull) : (o.skull||o.poiSkull));
    var at=Math.min(6, skull+(src.bonus||0));
    var base=(src.shards||0)*skull, sp=(t.spread||0)/100;
    out.shards=base>0 ? Math.max(1, Math.round(base*(1+(rnd()*2-1)*sp))) : 0;
    var n=src.fromTile ? Math.max(0, parseInt(o.x,10)||t.chestDefault||0) : between(src.min||0, src.max||0);
    for(var i=0;i<n;i++){
      var r=i<(src.top||0) ? topRarity(at,t) : rollRarity(at,t);
      out.parts[pickType(src.fromTile||o.source==="lootTile" ? "mixed" : o.salvage)][r]++;
    }
    return out;
  }
  /* A floor's own reward: {shards, lines:[{kind:"exact", n, type, rarity} |
     {kind:"roll", n, type ("any" or a part type), bonus}]} */
  function rollReward(rw, poiSkull, t){
    t=t||tables(); var out=bag(); if(!rw) return out;
    out.shards=Math.max(0,Math.floor(+rw.shards||0));
    (rw.lines||[]).forEach(function(l){
      if(l.kind==="item") return;   /* a blueprint or chassis: the progress engine rolls those */
      var n=Math.max(0,Math.min(99,parseInt(l.n,10)||0));
      if(l.kind==="exact"){
        var ty=TYPES.some(function(x){ return x.id===l.type; })?l.type:"troop", r=Math.max(0,Math.min(5,parseInt(l.rarity,10)||0));
        out.parts[ty][r]+=n;
      } else {
        var at=Math.min(6, clampSkull(poiSkull)+Math.max(0,parseInt(l.bonus,10)||0));
        for(var i=0;i<n;i++) out.parts[pickType(l.type==="any"?"mixed":l.type)][rollRarity(at,t)]++;
      }
    });
    return out;
  }
  function rewardText(rw, t){
    t=t||tables(); if(!rw) return ""; var bits=[];
    if(+rw.shards) bits.push((+rw.shards)+" shards");
    (rw.lines||[]).forEach(function(l){
      if(l.kind==="item"){ if(l.item) bits.push((window.KETER_PROG?window.KETER_PROG.itemName(l.item,window.KETER_PROG.dev()):l.item)+" ("+(+l.chance||0)+"%)"); return; }
      var n=parseInt(l.n,10)||0; if(!n) return;
      if(l.kind==="exact") bits.push(n+" × "+nameOf(l.type,Math.max(0,Math.min(5,parseInt(l.rarity,10)||0)),t));
      else bits.push(n+" rolled "+(l.type==="any"?"component":(TYPES.filter(function(x){ return x.id===l.type; })[0]||TYPES[0]).short+" part")+(n===1?"":"s")+((parseInt(l.bonus,10)||0)?" (+"+parseInt(l.bonus,10)+" rarity)":""));
    });
    return bits.join(", ");
  }
  /* which source a Unit's card type drops as */
  function sourceFor(cardType){ var c=String(cardType||"").toLowerCase(); return c==="elite"?"elite":c==="miniboss"?"miniboss":c==="boss"?"boss":"enemy"; }
  /* a map's Skull Level: the one set on it, or the highest of its Enemy Spawn Tiles */
  function poiSkull(map){
    if(!map) return 1;
    var s=parseInt(map.level,10); if(s>=1&&s<=6) return s;
    var best=0, labels=map.colorLabels||{}, hexes=map.hexes||{};
    var each=function(k,t){ t=t||{}; var lab=String(labels[t.c]||""); if(/enemy/i.test(lab)&&/spawn/i.test(lab)){ var l=parseInt(t.lvl,10); if(l>best) best=l; } };
    if(Array.isArray(hexes)) hexes.forEach(function(p){ each(p[0],p[1]); }); else Object.keys(hexes).forEach(function(k){ each(k,hexes[k]); });
    return best>=1&&best<=6 ? best : 1;
  }

  /* ---- many rolls at once, for the Loot page ---- */
  function simulate(o, n, t){
    t=t||tables(); n=Math.max(1,Math.min(100000,n||1000));
    var st={n:n, shards:0, minShards:1e9, maxShards:0, parts:0, byRarity:[0,0,0,0,0,0], byType:{troop:0,equipment:0,aether:0}, empty:0};
    for(var i=0;i<n;i++){
      var b=o.reward ? rollReward(o.reward, o.poiSkull, t) : roll(o,t);
      st.shards+=b.shards; if(b.shards<st.minShards) st.minShards=b.shards; if(b.shards>st.maxShards) st.maxShards=b.shards;
      var c=0; TYPES.forEach(function(ty){ b.parts[ty.id].forEach(function(v,r){ st.byRarity[r]+=v; st.byType[ty.id]+=v; c+=v; }); });
      st.parts+=c; if(!c) st.empty++;
    }
    st.avgShards=st.shards/n; st.avgParts=st.parts/n;
    return st;
  }

  /* ---- the stockpile, on this device ---- */
  var STOCK_KEY="keter-app-stockpile", HIST_KEY="keter-app-stockpile-log";
  function stock(){ try{ return norm(JSON.parse(localStorage.getItem(STOCK_KEY)||"null")); }catch(e){ return bag(); } }
  function setStock(b){ try{ localStorage.setItem(STOCK_KEY,JSON.stringify(norm(b))); return true; }catch(e){ return false; } }
  function history(){ try{ return JSON.parse(localStorage.getItem(HIST_KEY)||"[]")||[]; }catch(e){ return []; } }
  /* adds to the stockpile and remembers where it came from (the last 30) */
  function addToStock(b, why){
    if(isEmpty(b)) return false;
    var ok=setStock(add(stock(), b));
    var h=history(); h.unshift({t:new Date().toISOString(), why:String(why||""), bag:norm(b)}); h=h.slice(0,30);
    try{ localStorage.setItem(HIST_KEY,JSON.stringify(h)); }catch(e){}
    return ok;
  }
  function resetStock(){ try{ localStorage.removeItem(STOCK_KEY); localStorage.removeItem(HIST_KEY); }catch(e){} }

  window.KETER_LOOT={RARITIES:RARITIES, TYPES:TYPES, SALVAGE:SALVAGE, SOURCE_ORDER:SOURCE_ORDER, DEFAULTS:DEFAULTS,
    tables:tables, saveTables:saveTables, resetTables:resetTables, TABLE_KEY:TABLE_KEY,
    bag:bag, norm:norm, add:add, count:count, isEmpty:isEmpty, lines:lines, text:text, nameOf:nameOf,
    roll:roll, rollRarity:rollRarity, topRarity:topRarity, rollReward:rollReward, rewardText:rewardText,
    sourceFor:sourceFor, poiSkull:poiSkull, simulate:simulate, seed:seed, rnd:rnd,
    stock:stock, setStock:setStock, addToStock:addToStock, resetStock:resetStock, history:history,
    STOCK_KEY:STOCK_KEY};
})();
