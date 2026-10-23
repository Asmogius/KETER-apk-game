/* ===========================================================================
   Chassis (the video game's crafting). A chassis is designed by hand. It sets a
   Troop's stats, a power cap, a cap on abilities (Actions and Passives alike),
   and which keywords a design on it may use. Most belong to a District, giving
   each its own play style; a few general ones belong to none.

   check(chassis, design) says whether a design fits, and if not, why.
   =========================================================================== */
(function(){
  "use strict";
  var STORE="keter-app-chassis";
  /* the Districts, as the Forge names and colours them */
  var DISTRICTS=[
    {id:"",  name:"General",            color:"#5d7078", lite:"#d6e3e8"},
    {id:"1", name:"Threshold Dynamics", color:"#6a49cc", lite:"#a98ef0"},
    {id:"2", name:"Halcyon Cognition",  color:"#c23a8d", lite:"#ef7fbe"},
    {id:"3", name:"Vantage Robotics",   color:"#d1751c", lite:"#f0a457"},
    {id:"4", name:"Lazarus Computing",  color:"#bb3d30", lite:"#ef8175"},
    {id:"5", name:"Verdant Biogenics",  color:"#38914c", lite:"#6fd189"},
    {id:"6", name:"Meridian Entropics", color:"#1f8da3", lite:"#56c6da"}
  ];
  /* a Troop's stats; Integrity (INT) is every Unit's armour against Cyber */
  var STATS=[["hp","HP"],["ac","AC"],["move","MS"],["dmg","DMG"],["nrg","NRG"],["int","INT"]];
  /* subtypes are Combat Roles now: one or two of these */
  var SUBTYPES=["Melee","Ranged","Support","Cyber"];
  function num(v,d){ var x=parseFloat(v); return isNaN(x)?(d||0):x; }
  function all(){ try{ return JSON.parse(localStorage.getItem(STORE)||"{}")||{}; }catch(e){ return {}; } }
  function save(m){ try{ localStorage.setItem(STORE,JSON.stringify(m)); return true; }catch(e){ return false; } }
  function list(){ var m=all(); return Object.keys(m).map(function(k){ return upgrade(m[k]); }).sort(function(a,b){ return String(a.name).localeCompare(String(b.name)); }); }
  function get(id){ return upgrade(all()[id]||null); }
  function put(ch){ var m=all(); if(!ch.id) ch.id="ch_"+Date.now().toString(36)+Math.random().toString(36).slice(2,6); ch.saved=Date.now(); m[ch.id]=ch; return save(m)?ch.id:null; }
  function remove(id){ var m=all(); delete m[id]; return save(m); }
  function blank(){
    return {id:null, name:"New chassis", district:"", bodyPlan:"Bipedal", subtypes:["Melee"],
      powerCap:20, abilityCap:2, cost:{troop:4},
      /* v12.7: the most range and AP any attack of a design on it may have (14.0: and
         the best, lowest, to-hit), and what a design costs in Aether to deploy */
      maxRange:6, bestHit:4, maxAP:6, aether:{generic:1, affinity:0},
      stats:{hp:12, ac:10, move:4, dmg:3, nrg:3, int:10}, allowed:[], notes:""};
  }
  /* any shipped chassis that are missing join the library; edited ones are left alone */
  function install(shipped){
    var m=all(), n=0;
    Object.keys(shipped||{}).forEach(function(id){
      /* a shipped chassis nobody has edited is refreshed with each release */
      var mine=m[id], untouched=mine && (mine.test || mine.shipped) && !mine.saved;
      if(!mine || (untouched && JSON.stringify(mine)!==JSON.stringify(shipped[id]))){ m[id]=JSON.parse(JSON.stringify(shipped[id])); n++; }
    });
    if(n) save(m); return n;
  }
  /* every Archetype is allowed or not as one: "Archetype" */
  function keywordsIn(text){
    var K=window.KETER_KW; if(!K) return [];
    var out=[];
    K.parse(text||"").forEach(function(p){
      if(p.type!=="kw" || !p.kw) return;
      var nm=p.kw.archetype ? "Archetype" : p.kw.name;
      if(out.indexOf(nm)<0) out.push(nm);
    });
    return out;
  }
  /* the chips a chassis offers: the library, plus one for every Archetype */
  function chipList(){
    var K=window.KETER_KW; if(!K) return [];
    return K.KEYWORDS.map(function(k){ return {name:k.name, cat:k.cat}; }).concat([{name:"Archetype", cat:"target"}]);
  }
  /* Revision 15.6: the one-piece Conditions became grammar pieces */
  var LEGACY_ALLOWED={"if damaged":["if","the target","takes damage"], "when deployed":["when","this Unit","is deployed"],
    "when Incapacitated":["when","this Unit","is Incapacitated"], "if this Unit kills an Enemy":["if","this Unit","kills an enemy"],
    "further than":["if","the target","is further than"], "closer than":["if","the target","is within"]};
  function abilityPower(ab){ return window.KETER_SCORE ? window.KETER_SCORE.abilityPower(ab) : 4; }
  function designPower(design){ return (design&&design.abilities||[]).reduce(function(t,a){ return t+abilityPower(a); },0); }
  function check(ch, design){
    var abilities=(design&&design.abilities)||[], allowed={}, forbidden=[], reasons=[];
    (ch.allowed||[]).forEach(function(k){ allowed[String(k).toLowerCase()]=1; });
    abilities.forEach(function(a){ keywordsIn(a.text).forEach(function(k){ if(!allowed[k.toLowerCase()] && forbidden.indexOf(k)<0) forbidden.push(k); }); });
    var power=designPower(design), cap=num(ch.powerCap), acap=num(ch.abilityCap);
    if(power>cap) reasons.push("power "+power+" is over this chassis's cap of "+cap);
    if(abilities.length>acap) reasons.push(abilities.length+" abilities, where this chassis holds "+acap);
    if(forbidden.length) reasons.push("this chassis cannot use "+forbidden.join(", "));
    /* its subtypes decide which kinds of Actions it may have; Passives have none */
    var subs=(ch.subtypes||[]).map(function(x){ return String(x).toLowerCase(); }), wrongKind=[];
    abilities.forEach(function(a,i){ var r=String(a.role||"").toLowerCase();
      if(r && r!=="passive" && subs.length && subs.indexOf(r)<0) wrongKind.push("ability "+(i+1)+" is "+r.charAt(0).toUpperCase()+r.slice(1)); });
    if(wrongKind.length) reasons.push(wrongKind.join(", ")+", which this chassis's subtypes ("+(ch.subtypes||[]).join(" and ")+") do not allow");
    return {ok:!reasons.length, power:power, cap:cap, abilities:abilities.length, abilityCap:acap, forbidden:forbidden, wrongKind:wrongKind, reasons:reasons};
  }
  function districtOf(ch){ return DISTRICTS.filter(function(d){ return d.id===String(ch&&ch.district||""); })[0]||DISTRICTS[0]; }
  /* an older chassis kept one role and Security; read it as subtypes and Integrity */
  function upgrade(ch){
    if(!ch) return ch;
    if(!Array.isArray(ch.subtypes)) ch.subtypes = ch.role ? [ch.role] : [];
    delete ch.role;
    ch.subtypes=ch.subtypes.slice(0,2);
    ch.stats=ch.stats||{};
    if(ch.stats.int===undefined){ ch.stats.int = ch.stats.sec!==undefined ? ch.stats.sec : (ch.stats.ac||10); }
    delete ch.stats.sec;
    /* v12.7: attack maximums and an Aether cost, for chassis made before them */
    if(ch.maxRange==null) ch.maxRange=6; if(ch.maxAP==null) ch.maxAP=6;
    /* 14.0: a lower to-hit is better, so the most a to-hit could be became the
       best it can be: 12 minus the old number, so the ranking holds (8 is 4) */
    if(ch.bestHit==null) ch.bestHit = ch.maxHit!=null ? Math.min(20, Math.max(1, 12-num(ch.maxHit,8))) : 4;
    delete ch.maxHit;
    if(!ch.aether || typeof ch.aether!=="object") ch.aether={generic:1, affinity:0};
    /* keywords retired since the chassis was made drop out; WIL became INT */
    var K=window.KETER_KW;
    if(K && Array.isArray(ch.allowed)){
      var grown=[];
      ch.allowed.forEach(function(k){ (LEGACY_ALLOWED[k]||[k==="WIL"?"INT":k]).forEach(function(x){ grown.push(x); }); });
      ch.allowed=grown.filter(function(k,i,a){ return (k==="Archetype" || !!K.byName(k)) && a.indexOf(k)===i; });
    }
    return ch;
  }
  window.KETER_CHASSIS={DISTRICTS:DISTRICTS, STATS:STATS, SUBTYPES:SUBTYPES, upgrade:upgrade, STORE:STORE, list:list, get:get, put:put, remove:remove,
    blank:blank, install:install, keywordsIn:keywordsIn, chipList:chipList, abilityPower:abilityPower, designPower:designPower,
    check:check, districtOf:districtOf};
})();
