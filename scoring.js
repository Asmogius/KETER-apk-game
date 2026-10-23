/* ===========================================================================
   Card power scoring.

   Not a rule, a second opinion. Every value here was fitted to cards that were
   already made by hand: across 25 complete Troops, Aether cost predicts stats
   with an R-squared of 0.74, so the curve below is the one already in use
   rather than one imposed on it.

   What a card costs buys it a budget. What it carries spends that budget. The
   gap is the useful part, because it says what to change: "12 over, drop 6
   Health or charge 3 more".

   Effect text is scored by hand, because it cannot honestly be parsed. The
   anchors exist so that judgement is made against known cards instead of in a
   vacuum.
   =========================================================================== */
(function(root){
"use strict";

function n(v){ var x=parseInt(String(v==null?"":v),10); return isNaN(x)?0:x; }

/* ---- what a card carries ------------------------------------------------ */
var STAT_POINTS = {hp:1, ac:1, nrg:3, move:1, int:1, ldr:2};   /* Integrity replaced Will and Security */

/* Anchored against real cards, so scoring is a comparison rather than a guess. */
var EFFECT_ANCHORS = [
  {pts:2,  example:"Heals 4",                       note:"small, one target"},
  {pts:4,  example:"Deal 5 damage",                 note:"an ordinary damaging Action"},
  {pts:6,  example:"Every Enemy within 2 gains Rooted",      note:"several targets, no damage"},
  {pts:8,  example:"Deal 8 damage, take 3 yourself",note:"large, with a real cost"},
  {pts:12, example:"The first time each round a Unit would go down, it stays at 1 Health",
                                                    note:"persistent, changes a rule"}
];
var KEYWORD_POINTS = {target:2, move:2, support:3, perParam:1};

function statPoints(stats){
  var t=0, s=stats||{};
  for(var k in STAT_POINTS) t += n(s[k]) * STAT_POINTS[k];
  return t;
}
function behaviorPoints(behaviors, table){
  var t=0;
  (behaviors||[]).forEach(function(b){
    var d=(table||[]).filter(function(x){ return x.k===(b.k||b.key); })[0];
    if(!d) return;
    t += KEYWORD_POINTS[d.cat] || 2;
    if(d.param) t += KEYWORD_POINTS.perParam * n(b.x===undefined?b.value:b.x);
  });
  return t;
}
/* An effect's keywords are machine-readable, so its score is worked out from
   them. Crafting (the video game) needs that score to be honest, because a copy
   costs in step with it:

   - Everything but a Modifier adds into a base value: a keyword's weight, times
     its number where it has one.
   - An attack counts for 4 of its own (the anchor, "an ordinary damaging
     Action"), and a Modifier with nothing else to act on is modifying the
     attack.
   - Modifiers MULTIPLY that base rather than add to it: Burst 3 makes three
     attacks, so it triples what it bursts. Several multiply together.

   The multipliers are starting values, to be recalibrated by simulated fights.
   Text carrying no keywords returns null; the caller counts it as 4. */
var ATTACK_BASE=4;
var MODIFIER_MULT={
  "burst":            function(n){ return Math.max(1,n); },        /* n attacks in all */
  "aoe":              function(n){ return 1+Math.max(0,n); },      /* more Units in reach */
  "chain":            function(n){ return 1.5+0.1*Math.max(0,n); },/* one more hit, farther with reach */
  "pierce":           function(){ return 1.4; },                   /* the Unit behind, when there is one */
  "suppressive fire": function(){ return 1.3; },                   /* a reaction shot as well */
  "overclock":        function(){ return 1.0; },   /* carries no rules yet (the Simulator), so it costs nothing */
  "aura":             function(n){ return 1+0.5*Math.max(0,n); },  /* everyone within reach, continuously */
  /* Revision 16.3: a line reaches a Unit or two more, a cone about what AoE 1 does */
  "line":             function(n){ return 1+0.25*Math.max(0,n); },
  "cone":             function(n){ return 1+0.5*Math.max(0,n); }
};
/* Handbook 16.0: an area Target makes its sentence's effects cost
   (1 + 0.5 x radius) times as much: x1.5 at 1, x2 at 2, x2.5 at 3. */
var AREA_TARGETS={"all enemies within":1, "all allies within":1, "all units within":1};
/* Revision 16.3: a whole side, wherever it stands, counts like an area of 4 tiles (x3) */
var WHOLE_SIDE={"all enemies":4, "all allies":4};
/* Revision 16.1: Lunge and Charge add to an attack rather than multiply it:
   a tile of reach, or a point of damage, at the keyword's weight */
var ADDING_MODIFIERS={"lunge":1, "charge":1};
function areaFactor(r){ return 1+0.5*Math.max(0,r); }
function keywordDetail(text, opts){
  var K=(typeof window!=="undefined") && window.KETER_KW;
  if(!K) return null;
  var isKw=function(p){ return p.type==="kw" && p.kw; };
  if(!K.parse(text||"").filter(isKw).length && !(opts&&opts.attack)) return null;
  var base=(opts&&opts.attack)?ATTACK_BASE:0, mult=1, mods=[];
  (K.sentences ? K.sentences(text||"") : [text||""]).forEach(function(sent){
    var sum=0, area=1;
    K.parse(sent).filter(isKw).forEach(function(p){
      var num=parseInt(String(p.n||"").replace(/[^0-9-]/g,""),10);
      if(p.kw.cat==="modifier" && !ADDING_MODIFIERS[String(p.kw.name).toLowerCase()]){
        var f=MODIFIER_MULT[String(p.kw.name).toLowerCase()];
        var m=f?f(isNaN(num)?1:Math.abs(num)):1;
        mult*=m; mods.push({name:p.kw.name, x:m});
        return;
      }
      if(AREA_TARGETS[p.kw.name]){ area=Math.max(area, areaFactor(isNaN(num)?1:Math.abs(num))); return; }
      if(WHOLE_SIDE[p.kw.name]){ area=Math.max(area, areaFactor(WHOLE_SIDE[p.kw.name])); return; }
      var w=(p.kw.weight===undefined||p.kw.weight===null)?1:p.kw.weight;
      sum += (p.kw.num && !isNaN(num)) ? w*Math.abs(num) : w;
    });
    if(area!==1) mods.push({name:"area", x:area});
    base += sum*area;
  });
  if(!base && mult!==1) base=ATTACK_BASE;
  return {base:base, mult:mult, mods:mods, points:Math.round(base*mult)};
}
function keywordPoints(text, opts){
  var d=keywordDetail(text, opts);
  return d?d.points:null;
}
/* one ability's power: its keywords, or 4 when it has none */
function abilityPower(entry){
  var e=entry||{}, role=String(e.role||"").toLowerCase();
  if(e.power!==undefined && e.power!==null && e.power!=="") return n(e.power);
  var kw=keywordPoints(e.text||"", {attack: role==="melee"||role==="ranged"||role==="cyber"});
  return kw===null ? 4 : kw;
}
function effectPoints(entries){
  var t=0;
  (entries||[]).forEach(function(e){
    var txt=e.text||"";
    if(!txt.trim() && !(e.name||"").trim()) return;
    if(e.power!==undefined && e.power!==null && e.power!==""){ t+=n(e.power); return; }
    var kw=keywordPoints(txt);
    t += (kw===null) ? 4 : kw;
  });
  return t;
}

/* ---- what a card costs -------------------------------------------------- */
/* Most types are priced in Aether. The ones that are not have to be anchored
   on whatever they do cost you: an Enemy on its Skull Level, everything else
   on Rarity, which is the only dial those cards have. */
var RARITY_STEP = {common:0, uncommon:1, rare:2, epic:3, legendary:4};

function budgetFor(card){
  var t=String(card.cardType||card.type||"").toLowerCase();
  /* A Forge card carries its cost as aeGen/aeAff, a schema card as
     aetherCost. Reading only one of them is the same mistake that once left
     Master cards with no Actions, so read both. */
  var a=card.aetherCost||{};
  var aether = n(a.generic)+n(a.affinity)+n(a.affinity2)
             + n(card.aeGen)+n(card.aeAff)+n(card.aeAff2);
  var st=card.stats||{};
  var slots=n(st.uslot)||n(st.slots)||1;

  if(/troop|action|command|equipment|aether/.test(t) && aether>0)
    return {base: 33 + 3.9*(aether + 1.5*(slots-1)),
            from: aether+" Aether"+(slots>1?" and "+slots+" Unit Slots":""),
            firm: true};

  if(/enemy|elite|boss/.test(t)){
    var sk=n(card.skullLevel)||n(card.level)||1;
    /* fitted on only six Enemies that carry both a Skull Level and stats, so
       this one is a starting point rather than a measurement */
    return {base: 11 + 12*sk, from:"Skull Level "+sk, firm:false};
  }
  var step=RARITY_STEP[String(card.rarity||"common").toLowerCase()]||0;
  return {base: 30 + 12*step, from:(card.rarity||"common")+", no Aether cost",
          firm:false};
}

function scoreCard(card, behaviorTable){
  var entries = card.abilities || card.entries || [];
  var spend = statPoints(card.stats) +
              behaviorPoints(card.behaviors, behaviorTable) +
              effectPoints(entries);
  var b = budgetFor(card);
  var gap = Math.round(spend - b.base);
  var band = Math.abs(gap) <= 6 ? "on"
           : gap > 18 ? "well over" : gap > 6 ? "over"
           : gap < -18 ? "well under" : "under";
  return {points: Math.round(spend), budget: Math.round(b.base),
          gap: gap, band: band, from: b.from, firm: b.firm,
          /* An effect is only unscored when neither its keywords nor a
             hand-entered Power can speak for it. */
          unscored: entries.filter(function(e){
            if(!(e.text||"").trim()) return false;
            if(e.power!==undefined && e.power!==null && e.power!=="") return false;
            return keywordPoints(e.text)===null;
          }).length};
}

root.KETER_SCORE = {
  scoreCard: scoreCard, budgetFor: budgetFor, statPoints: statPoints,
  effectPoints: effectPoints, behaviorPoints: behaviorPoints,
  keywordPoints: keywordPoints, keywordDetail: keywordDetail, abilityPower: abilityPower,
  MODIFIER_MULT: MODIFIER_MULT, ADDING_MODIFIERS: ADDING_MODIFIERS, ATTACK_BASE: ATTACK_BASE, AREA_TARGETS: AREA_TARGETS, areaFactor: areaFactor,
  STAT_POINTS: STAT_POINTS, EFFECT_ANCHORS: EFFECT_ANCHORS,
  KEYWORD_POINTS: KEYWORD_POINTS
};
})(typeof window!=="undefined" ? window : this);
