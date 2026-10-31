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

/* ---- the Forge's help: a new card's build, what a build may hold, and the nearest build to a card made before ---- */
function defaultBuild(type, prev){
  var d=D(); prev=(prev&&typeof prev==="object")?prev:{};
  var rarity=(d.rarities||[]).indexOf(prev.rarity)>=0 ? prev.rarity : "common";
  if(UNIT[type]){
    var b={type:type, role:(d.roles||[]).indexOf(prev.role)>=0 ? prev.role : "brute", abilities:[]};
    if(ENEMYISH[type]){ b.size=(d.enemySize||{})[prev.size] ? prev.size : "standard"; b.skull=Math.max(1, Math.min(6, Math.floor(+prev.skull||1))); }
    else { b.rarity=rarity; if(type==="troop") b.size=((d.size||{})[prev.size] && prev.size!=="colossal") ? prev.size : "standard"; }
    return b;
  }
  if(type==="action") return {type:type, rarity:rarity, ability:["A1",1]};
  if(MENU_OF[type]){ var l=(d.menus||{})[type]||[]; return {type:type, rarity:rarity, menu:l.length?l[0].id:"", tier:1}; }
  return null;
}
/* What a build may hold: how many abilities, the highest tier, whether a signature, how many Passives or Auras. */
function caps(b){
  var d=D(), type=b.type;
  if(type==="hero"||type==="troop"){ var r=d.rarity[b.rarity||"common"]||d.rarity.common; return {abilities:r.abilities, tier:r.tier, signature:!!r.signature, passives:1}; }
  if(ENEMYISH[type]){
    var i=Math.max(1,Math.min(6,+b.skull||1))-1, g=d.grade[gradeOf(b)]||d.grade.enemy;
    return {abilities:d.enemyAbilities[i]+g.abilities, tier:Math.min(3, d.enemyTier[i]+g.tier), signature:false, passives:gradeOf(b)==="miniboss"?2:1};
  }
  return {abilities:1, tier:tierCap(b.rarity), signature:!!((d.rarity[b.rarity||"common"]||{}).signature), passives:1};
}

/* The words in a card's text, without their numbers: "[[AC +1]]" is "AC", "[[Deploy 1 Sentry Turret]]" "Deploy Sentry Turret". */
var STOP=["target","all ","turns","this Unit","attached Unit","that Unit","an ally","an enemy","when","if","while","the round begins","adjacent","persistent","within","the target","is ","has ","kills","takes","deals","moves","Troop","Hero"];
function stems(text){
  var out=[], parts=String(text||"").split("[[");
  for(var i=1;i<parts.length;i++){
    var tok=parts[i].split("]]")[0], ws=tok.split(" "), keep=[];
    for(var j=0;j<ws.length;j++){ var w=ws[j]; if(w==="" || w==="X" || /^[+\-−]?[0-9]+$/.test(w)) continue; keep.push(w); }
    var s=keep.join(" ");
    var stop=false; for(var k=0;k<STOP.length;k++) if(s.indexOf(STOP[k])===0){ stop=true; break; }
    if(s!=="" && !stop && out.indexOf(s)<0) out.push(s);
  }
  return out;
}
function has(t, w){ return String(t).indexOf(w)>=0; }
/* One entry of a card made before, as the library ability nearest to it ("" for none: a plain attack). */
function nearestAbility(e, melee){
  var t=e.text==null?"":String(e.text), kind=e.kind==null?"":String(e.kind), role=e.role==null?"":String(e.role);
  if(kind==="Aura"){
    if(has(t,"[[DMG +")) return "U2"; if(has(t,"[[Aim +")) return "U3"; if(has(t,"[[MS +")) return "U4"; if(has(t,"[[Range +")) return "U5"; return "U1";
  }
  if(kind==="Passive"){
    if(has(t,"[[gain Aether")) return has(t,"kills an enemy") ? "P16" : "P15";
    if(has(t,"[[Deploy ")) return "P14";
    if(has(t,"kills an enemy")) return "P10";
    if(has(t,"is attacked")) return "P11";
    if(has(t,"is Incapacitated")) return "P12";
    if(has(t,"below half HP")) return "P9";
    if(has(t,"the round begins")) return "P13";
    if(has(t,"[[Hardened")) return "P2";
    if(has(t,"[[Evasive")||has(t,"[[Flying")) return "P3";
    if(has(t,"[[Leap ")) return "P4";
    if(has(t,"[[MS +")) return "P5";
    if(has(t,"[[Aim +")) return "P6";
    if(has(t,"[[AC +")) return "P7";
    if(has(t,"[[Range +")) return "P8";
    return "P1";
  }
  var dmg=e.damage==null?"":String(e.damage), bdmg=e.baseDamage==null?"":String(e.baseDamage);
  /* an attack: a Unit's hit with damage, or anything aimed at an Enemy that doesn't heal */
  var attack=((role==="melee"||role==="ranged"||role==="cyber") && (dmg!=="" || bdmg!=="")) || ((has(t,"[[target enemy]]")||has(t,"[[all enemies")) && !has(t,"[[heal "));
  if(!attack){
    if(has(t,"[[heal ")) return has(t,"[[remove ") ? "S6" : "S1";
    if(has(t,"[[remove ")) return "S6";
    if(has(t,"[[Deploy ")) return "S7";
    if(has(t,"[[Barricade")) return "S8";
    if(has(t,"[[Leap ")) return "S9";
    if(has(t,"[[Dash ")) return "S5";
    if(has(t,"[[NRG +")) return "S4";
    if(has(t,"[[AC +")||has(t,"[[Hardened")) return "S3";
    return "S2";
  }
  if(has(t,"[[Burst ")) return melee ? "A2" : "A12";
  if(has(t,"[[Lunge ")||has(t,"[[Charge ")) return "A3";
  if(has(t,"[[Push ")) return "A4";
  if(has(t,"[[Stunned")) return "A5";
  if(has(t,"[[Rooted")) return "A7";
  if(has(t,"[[Slowed")) return "A6";
  if(has(t,"[[Poisoned")||has(t,"[[Bleed")) return "A8";
  if(has(t,"[[Weakened")||has(t,"[[Drained")) return "A9";
  if(has(t,"[[Marked")||has(t,"[[Pinned")) return "A10";
  if(has(t,"[[AoE ")||has(t,"[[Line ")||has(t,"[[Cone ")||has(t,"[[Chain ")) return melee ? "A2" : "A11";
  if(has(t,"[[Pierce")) return "A13";
  if(has(t,"[[Execute")||has(t,"below half HP")) return "A14";
  if(has(t,"[[this Unit]] takes [[damage")) return "A15";
  return "";
}
function num0(v){ var n=parseInt(String(v==null?"":v),10); return isNaN(n)?0:n; }
/* The Lab build nearest to a card made before (Convert): its role and size from its roles, archetypes and
   numbers, its rarity or Skull Level as they are, and its entries as the library abilities nearest them. */
function guess(card){
  var d=D(), type=String(card.cardType||"");
  var rarity=(d.rarities||[]).indexOf(card.rarity)>=0 ? card.rarity : "common";
  var text=(card.entries||[]).map(function(e){ return (e&&e.text!=null)?String(e.text):""; }).join(" ");
  if(MENU_OF[type]){
    var l=d.menus[type]||[], best=null, bestN=-1, mine=stems(text);
    l.forEach(function(m){
      if(m.min && rarityRank(rarity)<rarityRank(m.min)) return;
      var n=0, theirs=stems(m.tiers[0].text); theirs.forEach(function(s){ if(mine.indexOf(s)>=0) n++; });
      if(n>bestN){ bestN=n; best=m; }
    });
    var b={type:type, rarity:rarity, menu:best?best.id:(l.length?l[0].id:""), tier:Math.max(1, Math.min(tierCap(rarity), best?best.tiers.length:1))};
    if(type==="equipment" && rarityRank(rarity)>=rarityRank("rare") && has(text,"[[when]]")){
      var tb=null, tn=0;
      (d.equipTriggers||[]).forEach(function(tr){ var n=0, ts=stems(tr.text); ts.forEach(function(s){ if(mine.indexOf(s)>=0) n++; }); if(n>tn){ tn=n; tb=tr; } });
      if(tb) b.trigger=tb.id;
    }
    return b;
  }
  if(type==="action"){
    var e0=(card.entries||[])[0]||{}, r0=e0.role==null?"":String(e0.role), id=nearestAbility(e0, r0!=="ranged") || (r0==="ranged" ? "A13" : "A1");
    var a=ability(id);
    if(a && a.min && rarityRank(rarity)<rarityRank(a.min)) { id="A1"; a=ability(id); }
    return {type:type, rarity:rarity, ability:[id, Math.max(1, Math.min(tierCap(rarity), a?a.tiers.length:1))]};
  }
  if(!UNIT[type]) return null;
  var roles=card.combatRoles||[], arch=card.archetypes||[], st=card.stats||{};
  var isR=function(r){ return roles.indexOf(r)>=0; }, isA=function(x){ return arch.indexOf(x)>=0; };
  var attacks=(card.entries||[]).filter(function(e){ var r=e.role==null?"":String(e.role); return (r==="melee"||r==="ranged"||r==="cyber") && e.damage!=null && String(e.damage)!==""; });
  var role;
  if(isR("support") && !isR("melee") && !isR("ranged") && !isR("cyber")) role="support";
  else if(isR("ranged")||isR("cyber")) role=(isR("support") && !attacks.length) ? "support" : "shooter";
  else if(isR("melee")) role=(num0(st.move)>=5 || isA("Assassin") || isA("Light Infantry") || isA("Swarm") || isA("Chaff")) ? "skirmisher" : "brute";
  else role="brute";
  var b={type:type, role:role, abilities:[]}, hp=num0(st.hp);
  if(ENEMYISH[type]){
    b.skull=Math.max(1, Math.min(6, num0(card.skullLevel)||1));
    var base=d.enemy[role].hp[b.skull-1]*(d.grade[gradeOf(b)]||d.grade.enemy).hp, ratio=base>0 ? hp/base : 1;
    b.size=ratio>=1.25 ? "heavy" : (ratio<=0.6 ? "light" : "standard");
  } else {
    b.rarity=rarity;
    if(type==="troop"){
      if(hp>=45 && rarityRank(rarity)>=rarityRank("legendary")) b.size="colossal";
      else if(hp>=30) b.size="heavy";
      else if(hp<=15 || isA("Swarm") || isA("Chaff") || isA("Drone")) b.size="light";
      else b.size="standard";
    }
  }
  var cp=caps(b), seen={}, passives=0, plain=0, melee=d.roleAttack[role]==="melee";
  (card.entries||[]).forEach(function(e){
    if(b.abilities.length>=cp.abilities) return;
    var id=nearestAbility(e, melee);
    if(id===""){ plain++; if(plain<2) return; id=melee ? "A1" : "A13"; }
    var a=ability(id);
    if(!a || seen[id] || a.roles.indexOf(role)<0) return;
    if(a.min && (ENEMYISH[type] || rarityRank(rarity)<rarityRank(a.min))) return;
    var pas=(a.kind==="passive"||a.kind==="aura");
    if(pas && passives>=cp.passives) return;
    seen[id]=1; if(pas) passives++;
    b.abilities.push([id, Math.max(1, Math.min(cp.tier, a.tiers.length))]);
  });
  /* the token a Summon or Escort brings, as its text named it */
  var at=text.indexOf("[[Deploy ");
  if(at>=0){
    var rest=text.slice(at+9), end=rest.indexOf("]]");
    if(end>0){
      var inner=rest.slice(0,end), sp=inner.indexOf(" ");
      if(sp>0 && /^[0-9]+$/.test(inner.slice(0,sp))){
        var tk=inner.slice(sp+1);
        if((d.tokens||[]).indexOf(tk)>=0 && b.abilities.some(function(x){ return x[0]==="S7"||x[0]==="P14"; })) b.token=tk;
      }
    }
  }
  return b;
}

/* ---- the Workshop's modules (Phase 3) ----
   A Lab design is a chassis plus modules: {chassis, lab:1, modules:[[id, tier]], token, mk}. Its
   chassis is a line of the Troop table (its role, size and rarity: the chassis's own "lab" line, or
   read from what it was made with); a module is a library ability at a tier, open when its level
   (the best of the keyword blueprints that open it, or what was researched of it) reaches the tier.
   The apps pass what the player owns: kw, the level of each keyword blueprint; mods, each module's
   researched level. */
function MD(){ return D().modules||{}; }
function chassisLine(ch){
  var d=D(); ch=ch||{};
  var own=ch.lab||{};
  if(own && d.troop[own.role] && d.size[own.size] && d.rarity[own.rarity]) return {role:own.role, size:own.size, rarity:own.rarity};
  var subs=(ch.subtypes||[]).map(function(x){ return String(x).toLowerCase(); }), st=ch.stats||{};
  var role;
  if(subs.indexOf("support")>=0 && subs.indexOf("melee")<0 && subs.indexOf("ranged")<0 && subs.indexOf("cyber")<0) role="support";
  else if(subs.indexOf("ranged")>=0 || subs.indexOf("cyber")>=0) role="shooter";
  else role=num0(st.move)>=5 ? "skirmisher" : "brute";
  var hp=num0(st.hp), base=d.troop[role].hp, ratio=base>0 ? hp/base : 1;
  var size=ratio>=1.25 ? "heavy" : (ratio<=0.6 ? "light" : "standard");
  var cap=num0(ch.powerCap), rarity="common", rs=MD().chassisRarity||[];
  for(var i=0;i<rs.length;i++){ if(cap<=rs[i][0]){ rarity=rs[i][1]; break; } }
  if(size==="colossal" && rarityRank(rarity)<rarityRank("legendary")) size="heavy";
  return {role:role, size:size, rarity:rarity};
}
function isFreeModule(id, tier){ return (MD().free||[]).some(function(f){ return f[0]===id && (+tier||1)<=f[1]; }); }
function moduleLevel(id, kw, mods){
  var lv=Math.max(0, Math.min(3, Math.floor(+((mods||{})[id])||0)));
  ((MD().keywords||{})[id]||[]).forEach(function(k){ var o=Math.max(0, Math.min(3, Math.floor(+((kw||{})[k])||0))); if(o>lv) lv=o; });
  (MD().free||[]).forEach(function(f){ if(f[0]===id && f[1]>lv) lv=f[1]; });
  return lv;
}
function moduleOpen(id, tier, kw, mods){ return moduleLevel(id, kw, mods)>=Math.max(1, Math.floor(+tier||1)); }
/* researching a module's next tier: from level 1, for the research prices */
function moduleResearch(id, kw, mods, shards, prices){
  var a=ability(id); if(!a) return {ok:false, why:"No such module"};
  var have=moduleLevel(id, kw, mods), next=have+1, top=Math.min(3, a.tiers.length);
  if(have<1) return {ok:false, why:"Its first tier has to be found (a blueprint that opens it)"};
  if(next>top) return {ok:false, why:"Already at its highest tier"};
  var price=Math.max(0, Math.floor(+((prices||[0,60,120])[next-1])||0));
  if((+shards||0)<price) return {ok:false, why:"Needs "+price+" shards; you have "+(+shards||0), price:price};
  return {ok:true, level:next, price:price};
}
function designBuild(d, ch){
  var ln=chassisLine(ch), b={type:"troop", role:ln.role, size:ln.size, rarity:ln.rarity, abilities:JSON.parse(JSON.stringify((d&&d.modules)||[]))};
  if(d && d.token) b.token=d.token;
  return b;
}
function designPoints(d){
  var p=0; ((d&&d.modules)||[]).forEach(function(m){ var a=ability(m[0]); if(!a) return; var t=a.tiers[clampTier(m[1], a.tiers.length)-1]; p+=t.p||0; });
  return p;
}
/* what a design breaks: the build's rules, and the modules not open yet */
function designCheck(d, ch, kw, mods){
  if(!ch) return ["its chassis is missing"];
  var out=check(designBuild(d, ch));
  ((d&&d.modules)||[]).forEach(function(m){
    var a=ability(m[0]); if(!a) return;
    var t=Math.max(1, Math.floor(+m[1]||1)), lv=moduleLevel(m[0], kw, mods);
    if(lv<t) out.push(a.name+" "+ROMAN[Math.min(3,t)]+" isn't open yet"+(lv?" (you have tier "+ROMAN[lv]+")":" (no blueprint for it found)"));
  });
  return out;
}
/* what a copy costs, in Troop parts by rarity */
function designCost(d, ch){
  var c=MD().cost||{perPoint:0.5, tier2:1, tier3:1}, p=designPoints(d), base=Math.max(0, Math.floor(+((ch&&ch.cost&&ch.cost.troop)||0)));
  var parts=[base+Math.ceil(p*(+c.perPoint||0)),0,0,0,0,0], lines=[{label:"Chassis "+base+" + "+p+" points × "+c.perPoint, parts:[parts[0],0,0,0,0,0]}];
  ((d&&d.modules)||[]).forEach(function(m){
    var a=ability(m[0]); if(!a) return; var t=clampTier(m[1], a.tiers.length);
    if(t===2 && c.tier2){ parts[1]+=c.tier2; lines.push({label:a.name+" II", parts:[0,c.tier2,0,0,0,0]}); }
    if(t===3 && c.tier3){ parts[2]+=c.tier3; lines.push({label:a.name+" III", parts:[0,0,c.tier3,0,0,0]}); }
  });
  return {parts:parts, points:p, lines:lines};
}
/* the design as a Troop card: the build's stats and entries, Mk II and III on top */
var DMK=[{hp:0,ac:0,move:0},{hp:3,ac:1,move:0},{hp:6,ac:2,move:1}];
function designCard(d, ch){
  ch=ch||{}; var r=compile(designBuild(d, ch)), cc=r.card||{stats:{}, entries:[], combatRoles:[]};
  var mk=Math.max(1, Math.min(3, Math.floor(+(d&&d.mk)||1))), up=DMK[mk-1], st=JSON.parse(JSON.stringify(cc.stats||{}));
  if(st.hp!=null) st.hp=String(num0(st.hp)+up.hp);
  if(st.ac!=null){ st.ac=String(num0(st.ac)+up.ac); st["int"]=st.ac; }
  if(st.move!=null) st.move=String(num0(st.move)+up.move);
  var dist=String(ch.district||"");
  var card={id:"WS-"+String((d&&d.id)||"").slice(3).toUpperCase(), cardType:"troop", name:(d&&d.name)||"Untitled design",
    affinities:dist?[{district:dist, level:0}]:[], archetypes:[], rarity:cc.rarity||null, level:1, stats:st,
    aetherCost:{generic:num0(ch.aether&&ch.aether.generic)||0, affinity:num0(ch.aether&&ch.aether.affinity)||0, affinity2:0},
    combatRoles:cc.combatRoles||[], entries:cc.entries||[], design:(d&&d.id)||null, chassis:ch.id||(d&&d.chassis)||null, chassisName:ch.name||"", lab:cc.lab||null};
  if(mk>1) card.mk=mk;
  return card;
}
/* a design made before the Lab, as the nearest modules (Convert) */
function designGuess(d, ch){
  var ln=chassisLine(ch), b={type:"troop", role:ln.role, size:ln.size, rarity:ln.rarity, abilities:[]};
  var cp=caps(b), seen={}, passives=0, melee=D().roleAttack[ln.role]==="melee", plain=0;
  ((d&&d.abilities)||[]).forEach(function(a){
    if(b.abilities.length>=cp.abilities) return;
    var pas=a.kind==="passive", role=pas?"":String(a.role||"").toLowerCase(), att=!pas && (role==="melee"||role==="ranged"||role==="cyber");
    var id=nearestAbility({kind:pas?"Passive":"Active", role:role, damage:att?"1":null, text:a.text||""}, melee);
    if(id===""){ plain++; if(plain<2) return; id=melee?"A1":"A13"; }
    var ab=ability(id);
    if(!ab || seen[id] || ab.roles.indexOf(ln.role)<0 || (ab.min && rarityRank(ln.rarity)<rarityRank(ab.min))) return;
    var isP=(ab.kind==="passive"||ab.kind==="aura"); if(isP && passives>=cp.passives) return;
    seen[id]=1; if(isP) passives++;
    b.abilities.push([id, 1]);
  });
  return b.abilities;
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
  set:SET, setVersion:setVersion, applySet:applySet, setCard:setCard, retired:retiredNames,
  defaultBuild:defaultBuild, caps:caps, guess:guess, stems:stems, nearestAbility:nearestAbility,
  chassisLine:chassisLine, isFreeModule:isFreeModule, moduleLevel:moduleLevel, moduleOpen:moduleOpen, moduleResearch:moduleResearch,
  designBuild:designBuild, designPoints:designPoints, designCheck:designCheck, designCost:designCost, designCard:designCard, designGuess:designGuess
};
})(typeof window!=="undefined" ? window : this);
