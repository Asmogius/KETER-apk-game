/* ===========================================================================
   KETER Lab: the simpler card systems (chosen 31 Oct 2026).

   A Lab card is built, not written. A unit is a role, a size and a rarity (an
   Enemy a role, a size, a Skull Level and a grade) and up to two abilities
   from the library at a tier; every other card is one item from its type's
   menu at a tier. compile() turns a build into an ordinary card: its stats,
   its entries and their keyword text, so the rules and the game play it as
   they play any card. check() says what a build breaks, and points() and
   target() hold it against its rarity.

   The tables and the library are KETER_LAB_DATA (lab_data.js, made by
   lab/make_lab_systems.py from lab/spec_data.py). The game reads the same file
   and compiles the same way (scripts/lab_systems.gd); make_lab_cases.js holds
   the two to the same answers.

   The Lab switch (Dev settings) turns the Lab Forge and Workshop on. It is the
   same Companion and the same saved cards either way.
   =========================================================================== */
(function(root){
"use strict";

var KEY="keter-app-lab";
function D(){ return root.KETER_LAB_DATA || {}; }
function on(){ try{ return localStorage.getItem(KEY)==="1"; }catch(e){ return false; } }
function setOn(v){ try{ if(v) localStorage.setItem(KEY,"1"); else localStorage.removeItem(KEY); }catch(e){} }

function halfUp(x){ return Math.floor(x+0.5); }
var ROMAN=["","I","II","III"];
var ENEMYISH={enemy:1, elite:1, miniboss:1};
var UNIT={hero:1, troop:1, enemy:1, elite:1, miniboss:1};
var MENU_OF={command:"command", aether:"aether", equipment:"equipment", sphere:"sphere", consumable:"consumable", prototype:"prototype"};

function ability(id){ var l=D().library||[]; for(var i=0;i<l.length;i++) if(l[i].id===id) return l[i]; return null; }
function menuItem(type, id){ var l=(D().menus||{})[type]||[]; for(var i=0;i<l.length;i++) if(l[i].id===id) return l[i]; return null; }
function trigger(id){ var l=D().equipTriggers||[]; for(var i=0;i<l.length;i++) if(l[i].id===id) return l[i]; return null; }
function gradeOf(b){ return b.grade || (b.type==="elite"||b.type==="miniboss" ? b.type : "enemy"); }
function rarityRank(r){ var i=(D().rarities||[]).indexOf(String(r||"common")); return i<0?0:i; }
function tierCap(r){ var x=(D().rarity||{})[r||"common"]; return x?x.tier:1; }
function clampTier(t, n){ t=Math.max(1, Math.floor(+t||1)); return Math.min(t, n); }

/* ---- a unit's stat line, from the tables ---- */
function line(type, role, size, rarity, skull, grade, trade){
  var d=D(), s, b, r, z, g;
  if(type==="hero"){
    b=d.hero[role]; r=d.heroRarity[rarity||"common"];
    s={hp:b.hp+r.hp, ac:b.ac+r.ac, ms:b.ms, nrg:b.nrg, dmg:b.dmg, rng:b.rng, hit:b.hit, ap:b.ap+r.ap, ldr:b.ldr+r.ldr, slots:b.slots+r.slots};
  } else if(type==="troop"){
    b=d.troop[role]; z=d.size[size||"standard"]; r=d.rarity[rarity||"common"];
    s={hp:halfUp(b.hp*z.hp)+r.hp, ac:b.ac+z.ac+r.ac, ms:Math.max(0,b.ms+z.ms+r.ms), nrg:Math.max(1,b.nrg+z.nrg),
       dmg:Math.max(1,b.dmg+z.dmg), rng:b.rng, hit:b.hit, ap:b.ap+z.ap+r.ap, uslot:z.slots};
  } else {
    var i=Math.max(1,Math.min(6,+skull||1))-1;
    b=d.enemy[role]; z=d.enemySize[size||"standard"]; g=d.grade[grade||"enemy"];
    s={hp:halfUp(b.hp[i]*z.hp*g.hp), ac:b.ac[i]+z.ac+g.ac, ms:Math.max(1,b.ms[i]+z.ms), dmg:Math.max(1,b.dmg[i]+z.dmg+g.dmg),
       rng:b.rng[i], hit:b.hit[i], ap:b.ap[i]+g.ap};
  }
  if(trade && trade.length===4){ s[trade[0]]-=+trade[1]; s[trade[2]]+=+trade[3]; }
  return s;
}

/* ---- what things are worth ---- */
function rarityPrice(bonus){ var p=D().statPrice||{}, t=0; Object.keys(p).forEach(function(k){ if(bonus[k]!=null) t+=p[k]*bonus[k]; }); return t; }
function target(type, rarity, size){
  var d=D(), r=d.rarity[rarity||"common"]; if(!r) return null;
  var base=type==="hero" ? 30+rarityPrice(d.heroRarity[rarity||"common"]) : d.size[size||"standard"].price+rarityPrice(r);
  return base + r.abilities*d.tierPrice[String(r.tier)];
}
function suggestedAether(points){ return Math.max(0, halfUp(points/8)); }

/* ---- one entry ---- */
function basicEntry(type, role, ln){
  var atk=D().roleAttack[role], e={name:atk==="melee"?"Strike":"Shot", kind:ENEMYISH[type]?"Combo":"Active", role:atk,
    damage:String(ln.dmg), armorPenetration:String(ln.ap), text:""};
  if(atk==="ranged"){ e.attackRange=String(ln.rng); e.toHit=String(ln.hit); }
  if(!ENEMYISH[type]) e.energyCost="1";
  return e;
}
function abilityEntry(type, role, ln, id, tier, token){
  var a=ability(id); if(!a) return {entry:null, points:0};
  var n=a.tiers.length, ti=clampTier(tier, n), t=a.tiers[ti-1];
  var e={name:a.name+(n===1?"":" "+ROMAN[ti]), lab:[id, ti], text:String(t.text).replace("{token}", token||"Scuttlebot")};
  var kw=ENEMYISH[type]?"Combo":"Active";
  if(a.kind==="attack"){
    var atk=D().roleAttack[role];
    e.kind=kw; e.role=atk; e.damage=String(Math.max(1, ln.dmg+(t.dmg||0))); e.armorPenetration=String(ln.ap); e.energyCost=String(t.e);
    if(atk==="ranged"){ e.attackRange=String(ln.rng+(t.rng||0)); e.toHit=String(Math.max(2, ln.hit+(t.hit||0))); }
  } else if(a.kind==="support"){ e.kind=kw; e.role="support"; e.energyCost=String(t.e); }
  else e.kind=a.kind==="aura"?"Aura":"Passive";
  if(ENEMYISH[type]) delete e.energyCost;
  return {entry:e, points:t.p||0};
}
/* A Legendary or Mythic card's own ability (Q3): written in the core keywords, priced by hand. */
function signatureEntry(type, role, ln, sig){
  sig=sig||{};
  var e={name:String(sig.name||"Signature"), lab:["SIG",0], text:String(sig.text||""), signature:true}, k=sig.kind||"passive", kw=ENEMYISH[type]?"Combo":"Active";
  if(k==="attack"){
    var atk=sig.role||D().roleAttack[role];
    e.kind=kw; e.role=atk; e.damage=String(ln.dmg+(+sig.dmg||0)); e.armorPenetration=String(ln.ap); e.energyCost=String(sig.e!=null?sig.e:2);
    if(atk==="ranged"){ e.attackRange=String(ln.rng+(+sig.rng||0)); e.toHit=String(Math.max(2, ln.hit+(+sig.hit||0))); }
  } else if(k==="support"){ e.kind=kw; e.role="support"; e.energyCost=String(sig.e!=null?sig.e:2); }
  else e.kind=k==="aura"?"Aura":"Passive";
  if(ENEMYISH[type]) delete e.energyCost;
  return {entry:e, points:Math.floor(+sig.points||0)};
}

/* ---- a whole card ---- */
/* Whether the tables have a line for this build at all; a build that doesn't makes no card, only its problems. */
function sane(b){
  var d=D(), size=b.size||"standard", r=b.rarity||"common";
  if(!d.roleAttack || !d.roleAttack[b.role]) return false;
  if(b.type==="hero") return !!(d.hero[b.role] && d.heroRarity[r]);
  if(b.type==="troop") return !!(d.troop[b.role] && d.size[size] && d.rarity[r]);
  return !!(d.enemy[b.role] && d.enemySize[size] && d.grade[gradeOf(b)]);
}
function compileUnit(b){
  if(!sane(b)) return {card:null, points:null, target:null, problems:check(b)};
  var d=D(), type=b.type, role=b.role, size=b.size||"standard", grade=gradeOf(b);
  var ln=line(type, role, size, b.rarity, b.skull, grade, b.trade);
  var atk=d.roleAttack[role], entries=[basicEntry(type, role, ln)], points=0;
  (b.abilities||[]).forEach(function(x){
    var r=x[0]==="SIG" ? signatureEntry(type, role, ln, x[1]) : abilityEntry(type, role, ln, x[0], x[1], b.token);
    if(r.entry){ entries.push(r.entry); points+=r.points; }
  });
  var stats={hp:String(ln.hp), ac:String(ln.ac), move:String(ln.ms), "int":String(ln.ac)};
  if(type==="troop"){ stats.nrg=String(ln.nrg); stats.uslot=String(ln.uslot); points+=d.size[size].price+rarityPrice(d.rarity[b.rarity||"common"]); }
  else if(type==="hero"){ stats.apT=String(ln.nrg); stats.ldr=String(ln.ldr); stats.slots=String(ln.slots); points+=30+rarityPrice(d.heroRarity[b.rarity||"common"]); }
  else points+=10+8*(+b.skull||1);
  var card={cardType:type, rarity:ENEMYISH[type]?null:(b.rarity||"common"), skullLevel:ENEMYISH[type]?(+b.skull||1):null,
    combatRoles:[role==="support"?"support":atk], stats:stats, entries:entries, lab:norm(b)};
  return {card:card, points:points, target:ENEMYISH[type]?null:target(type, b.rarity||"common", size), problems:check(b)};
}

/* An Action card's attack uses a Common Hero's line for its kind of attack (melee: a Brute's; ranged: a Shooter's). */
function actionRole(a){ return a.roles.indexOf("brute")>=0 ? "brute" : (a.roles.indexOf("shooter")>=0 ? "shooter" : a.roles[0]); }

function compileOther(b){
  var d=D(), type=b.type, entry=null, cost=null;
  if(type==="action"){
    var x=b.ability||[], role;
    if(x[0]==="SIG"){ role=(x[1]&&x[1].role==="ranged")?"shooter":"brute"; entry=signatureEntry("hero", role, line("hero", role, null, "common"), x[1]).entry; cost=3; }
    else {
      var a=ability(x[0]);
      if(a){ role=actionRole(a); var r=abilityEntry("hero", role, line("hero", role, null, "common"), x[0], x[1], b.token); entry=r.entry; cost=clampTier(x[1], a.tiers.length); }
    }
  } else if(MENU_OF[type]){
    var m=menuItem(type, b.menu);
    if(m){
      var ti=clampTier(b.tier, m.tiers.length), t=m.tiers[ti-1], txt=t.text;
      var tr=type==="equipment" && b.trigger ? trigger(b.trigger) : null;
      if(tr) txt+=" "+tr.text;
      entry={name:"", kind:m.kind, lab:[m.id, ti], text:txt};
      if(t.cost!=null) cost=t.cost+(tr?1:0);
    }
  }
  var card={cardType:type, rarity:b.rarity||"common", stats:{}, entries:entry?[entry]:[], lab:norm(b)};
  return {card:card, points:null, target:null, cost:cost, problems:check(b)};
}

function compile(b){ return UNIT[b.type] ? compileUnit(b) : compileOther(b); }

/* The build as it is kept on the card: only what a build is. */
function norm(b){
  var o={type:b.type};
  ["role","size","rarity","skull","grade","trade","abilities","token","ability","menu","tier","trigger"].forEach(function(k){ if(b[k]!=null && b[k]!=="") o[k]=JSON.parse(JSON.stringify(b[k])); });
  return o;
}

/* ---- the rules a build keeps ---- */
function check(b){
  var d=D(), out=[], type=b.type;
  if(UNIT[type]){
    if(!d.roleAttack || !d.roleAttack[b.role]) return ["no role"];
    var abil=b.abilities||[], capN, capT;
    if(type==="hero"||type==="troop"){
      var r=d.rarity[b.rarity||"common"]; if(!r) return ["no such rarity"];
      if(type==="troop" && !d.size[b.size||"standard"]) return ["no such size"];
      if(type==="troop" && (b.size==="colossal") && rarityRank(b.rarity)<rarityRank("legendary")) out.push("Colossal is for Legendary and Mythic Troops");
      capN=r.abilities; capT=r.tier;
    } else {
      var i=Math.max(1,Math.min(6,+b.skull||1))-1, g=d.grade[gradeOf(b)];
      if(!g) return ["no such grade"];
      if(!d.enemySize[b.size||"standard"]) return ["no such size"];
      capN=d.enemyAbilities[i]+g.abilities; capT=Math.min(3, d.enemyTier[i]+g.tier);
    }
    if(abil.length>capN) out.push(abil.length+" abilities, "+capN+" allowed");
    var sigs=abil.filter(function(x){ return x[0]==="SIG"; });
    if(sigs.length && !((type==="hero"||type==="troop") && (d.rarity[b.rarity||"common"]||{}).signature)) out.push("a signature ability is for Legendary and Mythic cards");
    if(sigs.length>1) out.push("more than one signature ability");
    var seen={};
    abil.forEach(function(x){
      if(x[0]==="SIG") return;
      var a=ability(x[0]);
      if(!a){ out.push("no ability "+x[0]); return; }
      if(seen[a.id]) out.push(a.name+" twice"); seen[a.id]=1;
      if((+x[1]||1)>capT) out.push(a.name+" "+ROMAN[Math.min(3,+x[1]||1)]+" over the tier cap ("+ROMAN[capT]+")");
      if(a.roles.indexOf(b.role)<0) out.push(a.name+" isn't open to a "+d.roleName[b.role]);
      if(a.min && (ENEMYISH[type] ? true : rarityRank(b.rarity)<rarityRank(a.min))) out.push(a.name+" is for "+a.min[0].toUpperCase()+a.min.slice(1)+" and rarer cards");
    });
    var passive=abil.filter(function(x){ return x[0]==="SIG" ? ["passive","aura"].indexOf((x[1]||{}).kind||"passive")>=0 : (ability(x[0])&&["passive","aura"].indexOf(ability(x[0]).kind)>=0); });
    if(passive.length>(gradeOf(b)==="miniboss" && ENEMYISH[type]?2:1)) out.push("more than one Passive or Aura");
    if(b.trade){
      var ok=(d.trades||[]).some(function(t){ return (t[0]===b.trade[0]&&+t[1]===+b.trade[1]&&t[2]===b.trade[2]&&+t[3]===+b.trade[3]) || (t[2]===b.trade[0]&&+t[3]===+b.trade[1]&&t[0]===b.trade[2]&&+t[1]===+b.trade[3]); });
      if(!ok) out.push("not one of the trades");
    }
    if((b.token) && (d.tokens||[]).indexOf(b.token)<0) out.push("no token "+b.token);
    return out;
  }
  if(type==="action"){
    var x=b.ability||[];
    if(x[0]==="SIG"){ if(!(d.rarity[b.rarity||"common"]||{}).signature) out.push("a signature ability is for Legendary and Mythic cards"); return out; }
    var a=ability(x[0]); if(!a) return ["no ability "+x[0]];
    if((+x[1]||1)>tierCap(b.rarity)) out.push(a.name+" "+ROMAN[Math.min(3,+x[1]||1)]+" over the tier cap ("+ROMAN[tierCap(b.rarity)]+")");
    if(a.min && rarityRank(b.rarity)<rarityRank(a.min)) out.push(a.name+" is for "+a.min[0].toUpperCase()+a.min.slice(1)+" and rarer cards");
    return out;
  }
  if(MENU_OF[type]){
    var m=menuItem(type, b.menu); if(!m) return ["no "+type+" "+b.menu];
    if((+b.tier||1)>Math.min(tierCap(b.rarity), m.tiers.length)) out.push(m.name+" "+ROMAN[Math.min(3,+b.tier||1)]+" over the tier cap ("+ROMAN[Math.min(tierCap(b.rarity), m.tiers.length)]+")");
    if(m.min && rarityRank(b.rarity)<rarityRank(m.min)) out.push(m.name+" is for "+m.min[0].toUpperCase()+m.min.slice(1)+" and rarer cards");
    if(b.trigger){
      if(type!=="equipment") out.push("only Equipment takes a trigger");
      else if(!trigger(b.trigger)) out.push("no trigger "+b.trigger);
      else if(rarityRank(b.rarity)<rarityRank("rare")) out.push("a trigger is for Rare and rarer Equipment");
    }
    return out;
  }
  return ["no Lab build for a "+type];
}

/* ---- the Lab card set (lab_set.js, made by lab/make_lab_set.js) ----
   With the switch on, the master cards are the Lab set: a build for each, laid
   over the master card of its name (or the one it "was"), which keeps what the
   build doesn't decide (District, archetypes, loot, lore, pictures). New cards
   bring their own "meta" and show the pictures of the card they name ("art");
   retired cards are left out; the test set's, the tokens and everything that
   isn't a master card stay as they are. The game does the same (scripts/lab_set.gd). */
function SET(){ return root.KETER_LAB_SET || null; }
function setVersion(){ var s=SET(); return s ? String(s.version||"") : ""; }
function retiredNames(){
  var out={}, s=SET(); ((s&&s.retired)||[]).forEach(function(r){ var n=(r&&typeof r==="object")?String(r.name||""):String(r); out[n]=r; });
  return out;
}
function clone(o){ return JSON.parse(JSON.stringify(o)); }
function setCard(lc, was){
  var e=was ? clone(was) : {};
  if(lc.meta && typeof lc.meta==="object") Object.keys(lc.meta).forEach(function(k){ e[k]=clone(lc.meta[k]); });
  var r=compile(clone(lc.build||{})), cc=r.card;
  if(cc) ["cardType","rarity","skullLevel","combatRoles","stats","entries","lab"].forEach(function(k){ if(Object.prototype.hasOwnProperty.call(cc,k)) e[k]=cc[k]; });
  delete e.abilities;
  e.name=String(lc.name||"");
  if(lc.id) e.id=String(lc.id);
  e.aetherCost=(lc.aetherCost && typeof lc.aetherCost==="object") ? clone(lc.aetherCost) : null;
  e.hasVariableCost=null;
  e._src="master";
  e._lab=String(lc.change||"rebuilt");
  var art=String(lc.art||"");
  if(!art && was) art=String(was._artName||was.name||"");
  if(art && art!==e.name) e._artName=art;
  return e;
}
function applySet(cards){
  var s=SET(); if(!s || !Array.isArray(s.cards)) return cards;
  var by={}, gone=retiredNames(), out=[], placed={};
  s.cards.forEach(function(lc){ if(lc && typeof lc==="object") by[String(lc.was!=null?lc.was:(lc.name||""))]=lc; });
  (cards||[]).forEach(function(c){
    if(!c || typeof c!=="object") return;
    if(String(c._src!=null?c._src:"master")!=="master"){ out.push(c); return; }
    var nm=String(c.name!=null?c.name:"");
    if(Object.prototype.hasOwnProperty.call(gone,nm)) return;
    var lc=Object.prototype.hasOwnProperty.call(by,nm) ? by[nm] : null;
    if(!lc || placed[String(lc.name||"")]){ out.push(c); return; }
    placed[String(lc.name||"")]=1;
    out.push(setCard(lc, c));
  });
  s.cards.forEach(function(lc){ if(lc && typeof lc==="object" && !placed[String(lc.name||"")]){ placed[String(lc.name||"")]=1; out.push(setCard(lc, null)); } });
  return out;
}

/* ---- what the Forge and the Workshop offer ---- */
function abilitiesFor(role, type, rarity){
  return (D().library||[]).filter(function(a){ return a.roles.indexOf(role)>=0; });
}
function points(b){ return compile(b).points; }

root.KETER_LAB = {
  KEY:KEY, data:D, on:on, setOn:setOn, version:function(){ return D().version||""; },
  line:line, compile:compile, compileUnit:compileUnit, compileOther:compileOther, check:check, norm:norm,
  target:target, points:points, suggestedAether:suggestedAether, rarityPrice:rarityPrice, tierCap:tierCap,
  ability:ability, menuItem:menuItem, trigger:trigger, abilitiesFor:abilitiesFor, halfUp:halfUp, ROMAN:ROMAN,
  set:SET, setVersion:setVersion, applySet:applySet, setCard:setCard, retired:retiredNames
};
})(typeof window!=="undefined" ? window : this);
