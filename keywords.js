/* ===========================================================================
   The keyword library — Handbook Revision 16.3.

   A card's effect text is plain English with the words that carry rules meaning
   coloured by category. Everything else is flavour the rules ignore.

   Seven categories, each a fixed colour:
     condition (violet) · target (cyan) · effect (amber) · status (crimson)
     · duration (pink) · modifier (green) · stats (blue)

   Every keyword says what its own number means, because they differ: Poisoned's
   number is damage that decays, Rooted's is turns, Slowed's is Movement lost.
   `num` says which, and `numLabel` is what the picker asks for. A keyword with
   no number takes none.

   `weight` is what the effect is worth to the power score, per point of its
   number where it has one. These are provisional: they were set from the
   anchors already in scoring.js rather than fitted to play, and want revisiting
   once fights have been run.
   =========================================================================== */
(function(root){
"use strict";

var CATEGORIES=[
  {k:"condition", label:"Condition", colour:"#b07be0",
   hint:"When the effect applies at all."},
  {k:"target",    label:"Target",    colour:"#57d8e3",
   hint:"Who or what it happens to."},
  {k:"effect",    label:"Effect",    colour:"#e0b34d",
   hint:"What happens."},
  {k:"status",    label:"Status",    colour:"#d94f5c",
   hint:"A named state applied to a Unit."},
  {k:"duration",  label:"Duration",  colour:"#e07bc8",
   hint:"How long it lasts."},
  /* Revision 15.4 */
  {k:"modifier",  label:"Modifier",  colour:"#7bd88f",
   hint:"Changes how an Action works."},
  {k:"stats",     label:"Stats",     colour:"#6f9dff",
   hint:"Raises or lowers a stat, for as long as its Duration."}
];

var KEYWORDS=[
  /* ---- statuses ---- */
  {name:"Rooted", cat:"status", num:null, numLabel:null,
   weight:3, desc:"Cannot move. It lasts as long as its Duration \u2014 1 turn if none is given, 2 at most \u2014 then ends. A second dose does nothing while it lasts. When it ends, the Unit cannot be Rooted again until the same point of the next round. An always-on Passive cannot give it."},
  {name:"Stunned", cat:"status", num:null, numLabel:null,
   weight:2, desc:"Cannot act or move at all. It lasts as long as its Duration \u2014 1 turn if none is given, 2 at most \u2014 then ends. A second dose does nothing while it lasts. When it ends, the Unit cannot be Stunned again until the same point of the next round. An always-on Passive cannot Stun."},
  {name:"Slowed", cat:"status", num:"amount", numLabel:"Movement lost",
   weight:2, desc:"Movement Speed reduced by the number. It lasts as long as its Duration \u2014 1 turn if none is given \u2014 at full strength, then ends. A second dose adds its strength and its turns."},
  {name:"Marked", cat:"status", num:null, numLabel:null,
   weight:3, desc:"Ranged attacks against this Unit always hit. It lasts as long as its Duration \u2014 1 turn if none is given, 2 at most \u2014 then ends. A second dose does nothing while it lasts. When it ends, the Unit cannot be Marked again until the same point of the next round. An always-on Passive cannot give it."},
  {name:"Pinned", cat:"status", num:null, numLabel:null,
   weight:2, desc:"Suppressive Fire reaction shots against this Unit always hit. It lasts as long as its Duration \u2014 1 turn if none is given, 2 at most \u2014 then ends. A second dose does nothing while it lasts. When it ends, the Unit cannot be Pinned again until the same point of the next round. An always-on Passive cannot give it."},
  {name:"Poisoned", cat:"status", num:"amount", numLabel:"Damage each turn",
   weight:3, desc:"Deals the number in damage at each Recharge. It lasts as long as its Duration \u2014 1 turn if none is given \u2014 at full strength, then ends. A second dose adds its strength and its turns."},
  {name:"Bleed", cat:"status", num:null, numLabel:null,
   weight:3, desc:"Deals 10% of the Unit's remaining Health at each Recharge (at least 1). It lasts as long as its Duration \u2014 1 turn if none is given \u2014 at full strength, then ends. A second dose adds its strength and its turns."},
  {name:"Weakened", cat:"status", num:"amount", numLabel:"Damage lost",
   weight:2, desc:"Deals the number less damage. It lasts as long as its Duration \u2014 1 turn if none is given \u2014 at full strength, then ends. A second dose adds its strength and its turns."},
  {name:"Sundered", cat:"status", num:"amount", numLabel:"Armor lost",
   weight:2, desc:"Armor Class reduced by the number. It lasts as long as its Duration \u2014 1 turn if none is given \u2014 at full strength, then ends. A second dose adds its strength and its turns."},
  {name:"Drained", cat:"status", num:"amount", numLabel:"Energy lost",
   weight:2, desc:"Generates the number less Energy at each refill. It lasts as long as its Duration \u2014 1 turn if none is given \u2014 at full strength, then ends. A second dose adds its strength and its turns."},

  /* The Handbook's own statuses, which predate this library and are referenced
     throughout it. They were nearly lost when the library was rebuilt from the
     cards' vocabulary alone. */
  {name:"Evasive", cat:"status", num:"amount", numLabel:"To-Hit added",
   weight:3, desc:"Adds its number to the To-Hit threshold of Ranged Attacks against this Unit. It lasts as long as its Duration \u2014 1 turn if none is given \u2014 at full strength, then ends. A second dose adds its strength and its turns."},
  /* Revision 16.3 */
  {name:"Hardened", cat:"status", num:"amount", numLabel:"Damage stopped",
   weight:3, desc:"Each hit on this Unit deals the number less damage, never below 1. It lasts as long as its Duration \u2014 1 turn if none is given \u2014 at full strength, then ends. A second dose adds its strength and its turns."},
  {name:"Overclock", cat:"modifier", num:null, weight:3,
   desc:"A Vantage Robotics mechanic: spend now for a stronger effect, at a cost paid afterwards. It has no rules in a fight yet, so it does nothing there and costs nothing."},
  {name:"Aura", cat:"modifier", num:"amount", numLabel:"Radius", weight:3,
   desc:"A Passive that affects only Units within its radius."},
  {name:"Half Cover", cat:"target", num:null, weight:0,
   desc:"A Unit adjacent to a Half Cover Barricade gains +2 To-Hit against Ranged Attacks from the opposite side."},
  {name:"Full Cover", cat:"target", num:null, weight:0,
   desc:"A Unit adjacent to a Full Cover Barricade gains +4 To-Hit against Ranged Attacks from the opposite side."},

  /* ---- effects ---- */
  {name:"damage",   cat:"effect", num:"amount", numLabel:"Damage",
   weight:1, desc:"Deals the number in damage."},
  {name:"heal",     cat:"effect", num:"amount", numLabel:"Health restored",
   weight:1, desc:"Restores the number in Health, never above the Unit's maximum."},
  /* ---- Stats (Revision 15.4): one keyword per stat, replacing Modify. Each
     must carry a Duration. Written +10 HP or -2 AC. ---- */
  {name:"HP", cat:"stats", num:"signed", numLabel:"Amount (+ or \u2212)", weight:2,
   desc:"Raises maximum Health by the amount, and current Health with it; lowers both when negative. It must carry a Duration."},
  {name:"AC", cat:"stats", num:"signed", numLabel:"Amount (+ or \u2212)", weight:2,
   desc:"Raises or lowers Armor Class by the amount. It must carry a Duration."},
  {name:"MS", cat:"stats", num:"signed", numLabel:"Amount (+ or \u2212)", weight:2,
   desc:"Raises or lowers Movement Speed by the amount. It must carry a Duration."},
  {name:"DMG", cat:"stats", num:"signed", numLabel:"Amount (+ or \u2212)", weight:2,
   desc:"Raises or lowers the damage this Unit deals by the amount. It must carry a Duration."},
  {name:"INT", cat:"stats", num:"signed", numLabel:"Amount (+ or \u2212)", weight:2,
   desc:"Raises or lowers Integrity, armour against Cyber, by the amount. It must carry a Duration."},
  {name:"Range", cat:"stats", num:"signed", numLabel:"Amount (+ or \u2212)", weight:2,
   desc:"Raises or lowers the reach of ranged Actions by the amount. It must carry a Duration."},
  {name:"AP", cat:"stats", num:"signed", numLabel:"Amount (+ or \u2212)", weight:2,
   desc:"Raises or lowers Armor Penetration by the amount. It must carry a Duration."},
  /* Revision 16.3: the mirror of Evasive */
  {name:"Aim", cat:"stats", num:"signed", numLabel:"Amount (+ or \u2212)", weight:2,
   desc:"The Unit's ranged attacks need that much less to hit (more, when it is negative): the mirror of Evasive. It must carry a Duration."},
  {name:"NRG", cat:"stats", num:"signed", numLabel:"Amount (+ or \u2212)", weight:2,
   desc:"Raises or lowers Energy by the amount. It must carry a Duration."},
  {name:"Burst", cat:"modifier", num:"amount", numLabel:"Attacks in all", weight:4,
   desc:"The Action is made the number of times in all, for one payment of its Energy. Each attack rolls and applies its effects separately; the next target is chosen each time, and it continues automatically when only one is in reach. It runs to the end while a target remains."},
  {name:"Push",     cat:"effect", num:"amount", numLabel:"Tiles",
   weight:2, desc:"Moves the target that many tiles straight away from the attacker. Blocked, it stops and takes 1 damage per tile it could not move."},
  {name:"Pierce",   cat:"modifier", num:null,     numLabel:null,
   weight:4, desc:"The attack carries on through to the Unit directly behind the target."},
  {name:"Chain",    cat:"modifier", num:"amount", numLabel:"Tiles",
   weight:4, desc:"The attack jumps to the nearest other Enemy within that many tiles, for the same damage."},
  {name:"AoE",      cat:"modifier", num:"amount", numLabel:"Tiles",
   weight:5, desc:"Hits everything within that many tiles of the target, friend or foe, for full damage."},
  {name:"Deploy",   cat:"effect", num:"card",   numLabel:"How many, and what",
   weight:4, desc:"Puts a Unit or token on a friendly Spawn Tile, or beside the deploying Unit if the card says adjacent."},
  {name:"Sacrifice",cat:"effect", num:null,     numLabel:null,
   weight:0,desc:"Removes a friendly Unit as a cost. It counts as Incapacitated, so anything triggering on a Unit going down still triggers. It never touches an Enemy."},
  /* Handbook 16.0 */
  {name:"Execute",  cat:"effect", num:null,     numLabel:null,
   weight:6, desc:"Removes an Enemy below half its Health outright. An Elite, a Mini-Boss or a Boss is never Executed, nor is an Enemy at half its Health or more: they are untouched."},
  {name:"Suppressive Fire", cat:"modifier", num:null, numLabel:null,
   weight:4, desc:"Hold fire: pay the Action's Energy now, and shoot the first Enemy that moves within range and line of sight during the Enemy turn."},
  {name:"Flying",   cat:"effect", num:null,     numLabel:null,
   weight:5, desc:"Ignores terrain and walls when moving, and cannot be hit by melee attacks."},
  /* Revision 16.1: the movement keywords. Lunge and Charge belong on a Melee
     Action; Dash and Leap are given to a Unit, like Flying. */
  {name:"Lunge",    cat:"modifier", num:"amount", numLabel:"Tiles",
   weight:1, desc:"On a Melee Action: before it attacks, the Unit may move up to that many tiles to reach its target, so the target may be that many tiles further off. The move costs no Movement and no Energy, walks round walls and Units, and ends beside the target (off a hazard if it can, then the shortest way, then the tile beside the most Cover). It counts toward Charge."},
  {name:"Charge",   cat:"modifier", num:"amount", numLabel:"Damage added",
   weight:1, desc:"On a Melee Action: the attack deals that much more damage if the Unit has moved 3 tiles or more this turn before it lands. Walking, a Lunge, a Leap and a Dash count; being Pushed does not."},
  /* Revision 16.3: shapes of area, beside AoE */
  {name:"Line",     cat:"modifier", num:"amount", numLabel:"Tiles",
   weight:4, desc:"Hits every Unit on the tiles running straight from the attacker through the target, that many tiles long, friend or foe, for full damage."},
  {name:"Cone",     cat:"modifier", num:"amount", numLabel:"Tiles",
   weight:4, desc:"Hits every Unit in the wedge widening from the attacker toward the target, that many tiles deep, friend or foe, for full damage."},
  {name:"Dash",     cat:"effect", num:"amount", numLabel:"Tiles",
   weight:1, desc:"The Unit may move that many tiles more this turn, before or after it acts. It is not a Stat, so Slowed does not cut it; Rooted and Stunned still stop it. An Enemy Dashes at once, away from the Unit it attacked."},
  {name:"Leap",     cat:"effect", num:"amount", numLabel:"Tiles",
   weight:1, desc:"The Unit may jump to any empty tile within that many tiles that its Movement can pay for, over Units, Cover, walls, gaps and hazards: only the tile it lands on counts. With a Duration it lasts that long; without one, for the rest of the fight."},
  {name:"remove",   cat:"effect", num:"what",   numLabel:"What to take off",
   weight:3, desc:"Takes a piece of Equipment or a Status off the target, chosen by whoever plays it. A removed Equipment Card goes to the Discard Pile."},
  /* Revision 15.7: the Repair Kit's effect, which no keyword could express */
  {name:"Recover",  cat:"effect", num:null,     numLabel:null,
   weight:4, desc:"Returns a Troop's card from the Discard Pile to your hand, chosen by whoever plays it. The Troop is played again at its normal cost."},
  /* Revision 16.3 */
  {name:"Draw",     cat:"effect", num:"amount", numLabel:"Cards",
   weight:2, desc:"Draws that many cards from your Deck into your hand. On an Enemy's card it does nothing."},
  {name:"gain Aether", cat:"effect", num:"amount", numLabel:"Aether",
   weight:2, desc:"Gains that much Aether of the card's own District, or Neutral Aether if the card has none. On an Enemy's card it does nothing."},
  {name:"Barricade", cat:"effect", num:"cover", numLabel:"Half or Full",
   weight:3, desc:"Puts a Half or Full Cover Barricade on the target tile, which must be empty. It stays for the rest of the fight."},

  /* ---- targets ---- */
  {name:"target enemy",      cat:"target", num:null, weight:0,
   desc:"One Enemy within the Action's range and line of sight."},
  {name:"target ally",       cat:"target", num:null, weight:0,
   desc:"One friendly Unit within range and line of sight."},
  {name:"target tile",       cat:"target", num:null, weight:0,
   desc:"A tile within range and line of sight, whoever is standing on it."},
  {name:"this Unit",         cat:"target", role:"both", num:null, weight:0,
   desc:"The Unit using the Action, or the Unit whose card this is."},
  {name:"attached Unit",     cat:"target", role:"both", equipmentOnly:true, num:null, weight:0,
   desc:"The Unit this card is attached to."},
  {name:"all enemies within",cat:"target", num:"amount", numLabel:"Tiles", weight:1,
   desc:"Every Enemy within that many tiles of the target."},
  {name:"all allies within", cat:"target", num:"amount", numLabel:"Tiles", weight:1,
   desc:"Every friendly Unit within that many tiles of the target."},
  {name:"all units within",  cat:"target", num:"amount", numLabel:"Tiles", weight:1,
   desc:"Everything within that many tiles of the target, friend or foe."},
  /* Revision 16.3: a whole side, wherever it stands */
  {name:"all allies",        cat:"target", num:null, weight:1,
   desc:"Every friendly Unit on the Battlefield, the one using it included."},
  {name:"all enemies",       cat:"target", num:null, weight:1,
   desc:"Every Enemy on the Battlefield."},
  {name:"adjacent",          cat:"target", num:null, weight:0,
   desc:"Next to the target. On Deploy, places the new Unit beside the deploying one."},

  /* ---- targets that a Condition is about (Revision 15.6) ----
     A Condition names who it is about with a Target word, and narrows it the
     same way a Target is narrowed. "that Unit" points back at whoever the
     Condition was about, so an effect can land on them. */
  {name:"the target",        cat:"target", role:"subject", actionOnly:true, num:null, weight:0,
   desc:"The Unit the Action was used on. Used in an Action's Condition."},
  {name:"an ally",           cat:"target", role:"subject", quant:"ally", num:null, weight:0,
   desc:"Any one friendly Unit other than this one. Used in a Condition."},
  {name:"an enemy",          cat:"target", role:"subject", quant:"enemy", num:null, weight:0,
   desc:"Any one Enemy. Used in a Condition."},
  {name:"any Unit",          cat:"target", role:"subject", quant:"any", num:null, weight:0,
   desc:"Any Unit at all, this one included. Used in a Condition."},
  {name:"that Unit",         cat:"target", role:"both", num:null, weight:0,
   desc:"The Unit the Condition is about: the one that took the damage, moved or was deployed."},

  /* ---- narrowing (Revision 15.6) ----
     Written after a Target, these narrow it: target Sniper ally, all District 3
     allies within 2 tiles. Two of the same kind mean either will do; two of
     different kinds mean both must match. Every Archetype, custom ones included,
     is a narrowing word too; they are added from the Archetype list. */
  {name:"Melee",   cat:"target", narrow:"subtype", num:null, weight:0, desc:"Narrows a Target to Units with the Melee subtype."},
  {name:"Ranged",  cat:"target", narrow:"subtype", num:null, weight:0, desc:"Narrows a Target to Units with the Ranged subtype."},
  {name:"Support", cat:"target", narrow:"subtype", num:null, weight:0, desc:"Narrows a Target to Units with the Support subtype."},
  {name:"Cyber",   cat:"target", narrow:"subtype", num:null, weight:0, desc:"Narrows a Target to Units with the Cyber subtype."},
  /* Revision 16.3: the two kinds of your Units. Every Troop is a mechanical robot, so Troop is how a card names Mechanical Units */
  {name:"Troop",   cat:"target", narrow:"cardtype", num:null, weight:0, desc:"Narrows a Target to Troops (every Troop is a mechanical robot)."},
  {name:"Hero",    cat:"target", narrow:"cardtype", num:null, weight:0, desc:"Narrows a Target to Heroes."},
  {name:"District",cat:"target", narrow:"district", num:"district", numLabel:"District", weight:0,
   desc:"Narrows a Target to Units of that District."},
  {name:"within",  cat:"target", narrow:"distance", num:"amount", numLabel:"Tiles", weight:0,
   desc:"Narrows a Target to Units that many tiles or fewer from this Unit."},

  /* ---- conditions (Revision 15.6): grammar pieces ----
     A Condition is built from a connector, who it is about, and an event or a
     state: when + this Unit + takes damage. "when" waits for an event and fires
     each time it happens; "if" checks at the moment the effect resolves; "while"
     keeps the effect on for as long as a state holds. Conditions are not scored
     yet. */
  {name:"when",  cat:"condition", role:"connector", num:null, weight:0,
   desc:"Waits for an event, and the effect happens each time it does. Passives only."},
  {name:"if",    cat:"condition", role:"connector", num:null, weight:0,
   desc:"Checks something as the effect resolves; if it is not so, the effect does not happen."},
  {name:"while", cat:"condition", role:"connector", num:null, weight:0,
   desc:"The effect is on for as long as a state holds, and off the moment it does not. Passives only."},
  /* events: what happens */
  {name:"takes damage",   cat:"condition", role:"event", actionIf:true, num:null, weight:0,
   desc:"Loses at least 1 Health to an attack or an effect."},
  {name:"deals damage",   cat:"condition", role:"event", actionIf:true, num:null, weight:0,
   desc:"Its own attack or effect takes at least 1 Health from another Unit. Damage from a Status or a hazard does not count."},
  {name:"kills an enemy", cat:"condition", role:"event", actionIf:true, num:null, weight:0,
   desc:"Its own attack or effect Incapacitates an Enemy. Damage from a Status or a hazard does not count."},
  {name:"is deployed",    cat:"condition", role:"event", num:null, weight:0,
   desc:"Arrives on the Battlefield: at the start of the fight, or when it is played or Deployed."},
  {name:"is Incapacitated", cat:"condition", role:"event", actionIf:true, num:null, weight:0,
   desc:"Is reduced to 0 Health or Sacrificed."},
  {name:"attacks",        cat:"condition", role:"event", num:null, weight:0,
   desc:"Makes an attack, whether or not it hits."},
  {name:"is attacked",    cat:"condition", role:"event", num:null, weight:0,
   desc:"Is the target of an attack, whether or not it hits."},
  {name:"moves",          cat:"condition", role:"event", num:null, weight:0,
   desc:"Finishes a move of its own. Being pushed does not count."},
  {name:"ends its move within", cat:"condition", role:"event", noSelf:true, num:"amount", numLabel:"Tiles", weight:0,
   desc:"Finishes a move of its own that many tiles or fewer from this Unit."},
  {name:"gains",          cat:"condition", role:"event", num:"status", numLabel:"Status", weight:0,
   desc:"Is given the named Status."},
  {name:"the round begins", cat:"condition", role:"event", noSubject:true, num:null, weight:0,
   desc:"The Recharge Phase of every round, as Statuses tick."},
  /* states: what is true */
  {name:"is below half HP", cat:"condition", role:"state", num:null, weight:0,
   desc:"Has less than half of its maximum Health."},
  {name:"is at full HP",  cat:"condition", role:"state", num:null, weight:0,
   desc:"Has all of its maximum Health."},
  {name:"has",            cat:"condition", role:"state", num:"status", numLabel:"Status", weight:0,
   desc:"Carries the named Status."},
  {name:"is within",      cat:"condition", role:"state", noSelf:true, num:"amount", numLabel:"Tiles", weight:0,
   desc:"Stands that many tiles or fewer from this Unit."},
  {name:"is further than", cat:"condition", role:"state", noSelf:true, num:"amount", numLabel:"Tiles", weight:0,
   desc:"Stands more than that many tiles from this Unit."},

  /* ---- duration ---- */
  {name:"turns",      cat:"duration", num:"amount", numLabel:"Turns", weight:1,
   desc:"How long the effect lasts, from 2 to 10 turns."},
  {name:"persistent", cat:"duration", num:null, weight:3,
   desc:"Lasts until something removes it."},
  {name:"while attached", cat:"duration", num:null, weight:2,
   desc:"Lasts as long as the card granting it stays on the Unit, so a bonus from Equipment ends when that Equipment is removed."}
];

/* Withdrawn in Revision 15.0. A card still using one is flagged in the Forge
   rather than quietly rewritten. */
/* Modify gave way to the Stats keywords in Revision 15.4 */
/* the unit rework retired the Human/Cyborg/Mechanical distinction, Overwhelmed and
   Compromised; WIL became INT with Integrity */
var RETIRED=["SPOOL","Splash","if this penetrates","when combat begins","Modify","Human","Cyborg","Mechanical","Overwhelmed","Compromised","WIL"];

var STATS=["HP","AC","MS","NRG","INT","DMG","Range","AP","Aim"];

/* Revision 15.6: the old one-piece Conditions became grammar. Text still using
   them is rewritten as it is read, so an older card works and the Forge saves
   it in the new form. */
var LEGACY=[
  [/\[\[\s*if damaged\s*\]\]/gi, function(){ return "[[if]] [[the target]] [[takes damage]]"; }],
  [/\[\[\s*when deployed\s*\]\]/gi, function(){ return "[[when]] [[this Unit]] [[is deployed]]"; }],
  [/\[\[\s*when Incapacitated\s*\]\]/gi, function(){ return "[[when]] [[this Unit]] [[is Incapacitated]]"; }],
  [/\[\[\s*if this Unit kills an Enemy\s*\]\]/gi, function(){ return "[[if]] [[this Unit]] [[kills an enemy]]"; }],
  [/\[\[\s*further than(?:\s+(\d+))?\s*\]\](?:\s*(\d+))?/gi, function(m,a,b){
    return "[[if]] [[the target]] [[is further than "+(a||b||"1")+"]]"; }],
  /* closer than N is within N - 1: fewer than N tiles away */
  [/\[\[\s*closer than(?:\s+(\d+))?\s*\]\](?:\s*(\d+))?/gi, function(m,a,b){
    return "[[if]] [[the target]] [[is within "+Math.max(0,(parseInt(a||b,10)||1)-1)+"]]"; }]
];
var LEGACY_NAMES=["if damaged","when deployed","when Incapacitated","if this Unit kills an Enemy","further than","closer than"];
function migrateText(text){
  var s=String(text==null?"":text);
  if(s.indexOf("[[")<0) return s;
  LEGACY.forEach(function(l){ s=s.replace(l[0], l[1]); });
  return s;
}

/* ---- Archetypes are narrowing words (Revision 15.6) ----
   The built-in list is the Handbook's; a custom Archetype made in the Forge
   is stored on this device and joins automatically, as does any Archetype a
   card carries. The origins retired in the unit rework stay retired. */
var ARCHETYPES=['Juggernaut','Spawner','Assassin','Sniper','Commando','Kamikaze','Shield-Bearer',
  'Healer','Fighter','Transport','Gunfighter','Door Kicker','Veteran Tactician','Disabler','Berserker',
  'Devourer','Tinkerer','Light Infantry','Heavy Infantry','Drone',
  'O.B.O.L.™ Bot','Battle Buddy™ Bot',
  'Swarm','General','Necromancer','Abomination','Chaff'];
var EXTRA_ARCH=[];
function registerArchetypes(list){
  (list||[]).forEach(function(a){ a=String(a||"").trim(); if(a && EXTRA_ARCH.indexOf(a)<0) EXTRA_ARCH.push(a); });
}
function customArchetypes(){
  try{
    var raw=(typeof localStorage!=="undefined") ? localStorage.getItem("keter-custom-archetypes") : null;
    return (JSON.parse(raw||"[]")||[]).map(function(c){ return c&&c.name?c.name:c; }).filter(Boolean);
  }catch(e){ return []; }
}
function archetypes(){
  var seen={}, out=[];
  ARCHETYPES.concat(customArchetypes(), EXTRA_ARCH).forEach(function(a){
    a=String(a||"").trim(); var low=a.toLowerCase();
    if(!a || seen[low]) return;
    if(RETIRED.some(function(r){ return r.toLowerCase()===low; })) return;
    if(KEYWORDS.some(function(k){ return k.name.toLowerCase()===low; })) return;
    seen[low]=1; out.push(a);
  });
  return out;
}
var _allCache={key:null, list:KEYWORDS};
function allKeywords(){
  var arch=archetypes(), key=arch.join("|");
  if(_allCache.key!==key){
    _allCache={key:key, list:KEYWORDS.concat(arch.map(function(a){
      return {name:a, cat:"target", narrow:"archetype", num:null, weight:0, archetype:true,
              desc:"Narrows a Target to "+a+" Units. "+a+" is an Archetype."};
    }))};
  }
  return _allCache.list;
}

function byName(n){
  var want=String(n||"").trim().toLowerCase(), all=allKeywords();
  for(var i=0;i<all.length;i++)
    if(all[i].name.toLowerCase()===want) return all[i];
  return null;
}
function isRetired(n){
  var want=String(n||"").trim().toLowerCase();
  return RETIRED.some(function(r){ return r.toLowerCase()===want; });
}
function category(k){
  for(var i=0;i<CATEGORIES.length;i++) if(CATEGORIES[i].k===k) return CATEGORIES[i];
  return null;
}
function colourOf(name){
  var kw=byName(name); if(!kw) return null;
  var c=category(kw.cat); return c?c.colour:null;
}
/* A marked keyword in stored text reads [[Name]] or [[Name N]]; the brackets
   are the marker in the data and never print on the card. */
/* The number is optional, and the whitespace before it only counts as part of
   the token when a number actually follows — written greedily it swallowed the
   space after a keyword and ran the next word into it. */
var TOKEN=/\[\[([^\]]+)\]\](?:\s*(\d+))?/g;
/* A token is a keyword followed by its parameter, and the parameter's shape
   depends on the keyword: a number (Rooted 3), a stat and amount (Modify AC +2),
   a count and a card (Deploy 2 Aether Battery), or a thing to take off (remove
   Rooted). So the keyword is found by name — the longest one that starts the
   token — and the rest is its parameter. Splitting on a trailing number, as
   this first did, read "Deploy 2 Aether Battery" as a keyword nobody had heard
   of. */
function resolve(token){
  var raw=String(token||"").trim(), low=raw.toLowerCase();
  var best=null;
  allKeywords().forEach(function(k){
    var n=k.name.toLowerCase();
    if((low===n || low.indexOf(n+" ")===0) && (!best || n.length>best.name.length)) best=k;
  });
  if(best) return {kw:best, name:best.name, param:raw.slice(best.name.length).trim()||null,
                   retired:false};
  var ret=null;
  RETIRED.forEach(function(r){
    var n=r.toLowerCase();
    if(low===n || low.indexOf(n+" ")===0) ret=r;
  });
  if(ret) return {kw:null, name:ret, param:raw.slice(ret.length).trim()||null, retired:true};
  /* a Stats keyword may be written number first: +10 HP */
  var sm=raw.match(/^([+-](?:\d+|X))\s+(.+)$/);
  if(sm){ var sk=byName(sm[2]); if(sk && sk.cat==="stats") return {kw:sk, name:sk.name, param:sm[1], retired:false}; }
  var m=raw.match(/^(.*?)\s+([+-]?\d+)$/);
  return {kw:null, name:m?m[1]:raw, param:m?m[2]:null, retired:false};
}
function parse(text){
  var out=[], last=0, m, src=migrateText(text);
  TOKEN.lastIndex=0;
  while((m=TOKEN.exec(src))){
    if(m.index>last) out.push({type:"text", text:src.slice(last,m.index)});
    var r=resolve(m[1]);
    var n=(m[2]!==undefined && m[2]!==null) ? m[2] : r.param;
    out.push({type:"kw", name:r.name, n:(n===undefined?null:n), kw:r.kw, retired:r.retired});
    last=m.index+m[0].length;
  }
  if(last<src.length) out.push({type:"text", text:src.slice(last)});
  return out;
}
function isDistance(kw){ return !!kw && (kw.numLabel==="Tiles" || kw.numLabel==="Radius"); }
function plural(n, one){ return n+" "+one+(String(n)==="1"?"":"s"); }
/* How a keyword reads on a card. Stats put their amount first (+2 AC); every
   distance says tiles (Revision 15.6); a Duration of turns reads "for 2 turns",
   unless the words before it already say "for". */
function label(p, before){
  if(!p || p.type==="text") return p?p.text:"";
  var kw=p.kw, n=(p.n===null||p.n===undefined)?"":String(p.n).trim();
  if(kw && kw.cat==="stats" && n){
    var v=n; if(/^(\d|X$)/.test(v)) v="+"+v;
    return v+" "+p.name;
  }
  if(kw && kw.name==="turns" && n){
    var hasFor=/\bfor\s*$/i.test(String(before||""));
    return (hasFor?"":"for ")+plural(n,"turn");
  }
  if(kw && isDistance(kw) && /^(\d+|X)$/.test(n)) return p.name+" "+plural(n,"tile");
  /* Revision 16.3: Barricade Full reads "Full Cover Barricade" */
  if(kw && kw.name==="Barricade") return (n?n.charAt(0).toUpperCase()+n.slice(1).toLowerCase()+" Cover ":"")+"Barricade";
  return p.name+(n?" "+n:"");
}

/* ---- reading a sentence (Revision 15.6) --------------------------------
   One sentence is one effect. analyse() sorts its keywords into the grammar:
   an optional [when] clause, an optional [if]/[while] check, who it happens
   to (each with its narrowing words), and what it does. It does not judge;
   problems() does, for the kind of ability the sentence belongs to. */
function sentences(text){
  return String(text||"").split(/(?<=[.!?])\s+/).map(function(t){ return t.trim(); }).filter(Boolean);
}
function analyse(sent){
  var out={when:null, check:null, targets:[], effects:[], mods:[], durations:[], covers:[],
           bad:[], stray:[], all:[]};
  var clause=null, lastTarget=null;
  parse(sent).forEach(function(p){
    if(p.type!=="kw") return;
    out.all.push(p);
    if(!p.kw){ out.bad.push(p); return; }
    var k=p.kw;
    if(k.role==="connector"){
      if(clause) out.stray.push(clause.connector);   /* a connector with nothing after it */
      clause={connector:p, subject:null, narrow:[], event:null};
      return;
    }
    if(clause){
      if(k.cat==="target" && (k.narrow)){ clause.narrow.push(p); return; }
      if(k.cat==="target" && !clause.subject && (k.role==="subject"||k.role==="both")){ clause.subject=p; return; }
      if(k.role==="event"||k.role==="state"){
        clause.event=p;
        var c={connector:clause.connector.kw.name, subject:clause.subject, narrow:clause.narrow, event:p};
        if(c.connector==="when" && !out.when) out.when=c;
        else if(!out.check && c.connector!=="when") out.check=c;
        else out.stray.push(p);
        clause=null; lastTarget=null; return;
      }
    }
    if(k.role==="event"||k.role==="state"){ out.stray.push(p); return; }
    if(k.cat==="target"){
      if(k.narrow){ if(lastTarget) lastTarget.narrow.push(p); else out.stray.push(p); return; }
      if(k.name==="Half Cover"||k.name==="Full Cover"){ out.covers.push(p); return; }
      lastTarget={part:p, narrow:[]}; out.targets.push(lastTarget); return;
    }
    if(k.cat==="modifier"){ out.mods.push(p); return; }
    if(k.cat==="duration"){ out.durations.push(p); return; }
    if(k.cat==="condition"){ out.stray.push(p); return; }
    out.effects.push(p);
  });
  if(clause) out.stray.push(clause.connector);
  return out;
}
/* The kind of ability decides what grammar it may use: an Action checks with
   [if]; a Passive reacts with [when] (and may check with [if] as well), or
   stays on [while] something holds, or is simply always on. */
function kindOf(tag){
  var t=String(tag||"").toLowerCase();
  return (t==="passive"||t==="aura") ? "passive" : "action";
}
function isContinuous(an){ return !an.when; }
function problems(an, ctx){
  ctx=ctx||{}; var kind=ctx.kind||"action", out=[];
  var nm=function(p){ return p?(p.kw?p.kw.name:p.name):""; };
  an.stray.forEach(function(p){
    var k=p.kw||{};
    if(k.role==="connector") out.push("“"+k.name+"” has no event or state after it");
    else if(k.role==="event"||k.role==="state") out.push("“"+k.name+"” needs a connector before it (when, if or while)");
    else if(k.narrow) out.push("“"+label(p)+"” narrows nothing: put it after a Target");
    else out.push("“"+nm(p)+"” is out of place");
  });
  if(kind==="action"){
    if(an.when) out.push("an Action cannot use “when” — that is for Passives. Use “if”");
    if(an.check && an.check.connector==="while") out.push("an Action cannot use “while” — that is for Passives");
  }else{
    if(an.check && an.check.connector==="if" && !an.when)
      out.push("in a Passive, “if” follows a “when”; for something that stays true, use “while”");
    if(an.when && an.check && an.check.connector==="while")
      out.push("“when” and “while” cannot share an effect; check with “if”");
  }
  [an.when, an.check].forEach(function(c){
    if(!c) return;
    var ev=c.event.kw, conn=c.connector, subj=c.subject?c.subject.kw:null;
    if(conn==="when" && ev.role!=="event") out.push("“when” waits for an event, and “"+ev.name+"” is a state; use “while” or “if”");
    if(conn==="while" && ev.role!=="state") out.push("“while” needs a state, and “"+ev.name+"” is an event; use “when”");
    if(conn==="if" && ev.role==="event" && !(kind==="action" && ev.actionIf))
      out.push("“if” checks a state, and “"+ev.name+"” is an event"+(kind==="action"?" an Action cannot check":"; use “when”"));
    if(ev.noSubject && subj) out.push("“"+ev.name+"” is about no one, so it takes no Target before it");
    if(!ev.noSubject && !subj) out.push("“"+ev.name+"” needs to say who: this Unit, an ally, an enemy…");
    if(subj && ev.noSelf && (subj.name==="this Unit"||subj.name==="attached Unit"))
      out.push("“"+ev.name+"” is measured from this Unit, so it needs someone else before it");
    if(subj && subj.name==="the target" && kind!=="action") out.push("“the target” is for Actions; in a Passive, use “that Unit” or an ally/enemy");
    if(subj && subj.name==="that Unit" && !(conn!=="when" && an.when && an.when.subject))
      out.push("“that Unit” points back at a “when” that names someone");
    if((ev.num==="status") && !byName(String(c.event.n||"")))
      out.push("“"+ev.name+"” needs a Status to name");
  });
  /* Revision 15.8: X stands for a number only on a card whose Aether cost has an X */
  if(ctx.variable===false && an.all.some(isXPart))
    out.push("X needs a variable cost: put X in this card's Aether cost, or write a number");
  an.targets.forEach(function(t){
    var k=t.part.kw;
    if(k.role==="subject") out.push("“"+k.name+"” belongs in a Condition; who the effect happens to is a Target such as target enemy or that Unit");
    if(k.name==="that Unit" && !((an.when&&an.when.subject)||(an.check&&an.check.subject)))
      out.push("“that Unit” points back at a Condition that names someone");
  });
  /* Handbook 16.0: an always-on Passive (no "when") cannot keep anyone locked */
  an.effects.forEach(function(p){
    var lk=["Stunned","Rooted","Pinned","Marked"].indexOf(p.kw.name)>=0;
    if(lk && kind==="passive" && !an.when)
      out.push(p.kw.name==="Stunned" ? "an always-on Passive cannot Stun: give it a “when”" : "an always-on Passive cannot keep anyone "+p.kw.name+": give it a “when”");
    /* and a lock lasts 2 turns at most */
    if(lk) an.durations.forEach(function(d){
      var dn=d.kw?d.kw.name:"", t=parseInt(String(d.n||"").replace(/[^0-9-]/g,""),10);
      if(dn==="persistent" || dn==="while attached" || (dn==="turns" && !isNaN(t) && t>2)) out.push(p.kw.name+" lasts 2 turns at most: use turns 1 or 2");
    });
  });
  /* Revision 16.1: Lunge and Charge are made with an attack */
  an.mods.forEach(function(p){
    if((p.kw.name==="Lunge"||p.kw.name==="Charge") && kind==="passive")
      out.push(p.kw.name+" is made with an attack: put it on a Melee Action");
  });
  /* Revision 16.3: Line and Cone are shapes an attack makes; a Barricade is Half or Full, on a tile */
  an.mods.forEach(function(p){
    if((p.kw.name==="Line"||p.kw.name==="Cone") && kind==="passive")
      out.push(p.kw.name+" is a shape an attack makes: put it on an Action");
  });
  an.effects.forEach(function(p){
    if(p.kw.name!=="Barricade") return;
    if(!/^(Half|Full)$/i.test(String(p.n||"").trim())) out.push("Barricade needs Half or Full");
    if(!an.targets.some(function(t){ return t.part.kw.name==="target tile"; })) out.push("Barricade goes on a tile: use target tile");
  });
  /* Execute removes an Enemy: aimed at anyone else it would do nothing */
  if(an.effects.some(function(p){ return p.kw.name==="Execute"; }) && !(an.targets.length && an.targets.every(function(t){ return t.part.kw.name==="target enemy"||t.part.kw.name==="all enemies within"||t.part.kw.name==="all enemies"||t.part.kw.role==="narrow"||t.part.kw.narrow; })))
    out.push("Execute removes an Enemy: use target enemy or all enemies within");
  /* Sacrifice removes a friendly Unit as a cost; it is not a way to kill Enemies */
  if(an.effects.some(function(p){ return p.kw.name==="Sacrifice"; }) && an.targets.some(function(t){ return t.part.kw.name==="target enemy"||t.part.kw.name==="all enemies within"||t.part.kw.name==="all enemies"; }))
    out.push("Sacrifice removes a friendly Unit: use this Unit, target ally or all allies within");
  return out;
}

/* ---- variable costs (Revision 15.8) --------------------------------------
   A card whose Aether cost holds an X may write X wherever a keyword takes a
   number: [[damage X]], [[HP +X]], [[turns X]], [[Deploy X Aether Battery]].
   X is chosen as the card is played, at least 1, and from then on the text
   reads with that number. Only a keyword's own number counts: a Deploy of a
   card called "Model X" is left alone. */
function xSpot(inner){
  var raw=String(inner||"").trim(), m;
  if((m=raw.match(/^(deploy\s+)X(\s+.+)$/i))) return {pre:m[1], post:m[2]};
  if(/^deploy(\s|$)/i.test(raw)) return null;
  if((m=raw.match(/^(.*\S\s+[+-]?)X$/))) return {pre:m[1], post:""};
  if((m=raw.match(/^([+-])X(\s+.+)$/))) return {pre:m[1], post:m[2]};
  return null;
}
function isXPart(p){
  if(!p || p.type!=="kw" || p.n===null || p.n===undefined) return false;
  var n=String(p.n).trim();
  return /^[+-]?X$/.test(n) || (!!p.kw && p.kw.num==="card" && /^X\s/.test(n));
}
function usesX(text){
  var hit=false;
  String(text||"").replace(/\[\[([^\]]+)\]\]/g, function(all, inner){ if(xSpot(inner)) hit=true; return all; });
  return hit;
}
function fillX(text, x){
  var n=String(Math.max(1, parseInt(x,10)||1));
  return String(text||"").replace(/\[\[([^\]]+)\]\]/g, function(all, inner){
    var sp=xSpot(inner);
    return sp ? "[["+sp.pre+n+sp.post+"]]" : all;
  });
}

/* ---- how it prints (Revision 15.6) --------------------------------------
   Narrowing words are written after the Target they narrow, and print inside
   it: [[all allies within 2]] [[District 3]] reads "all District 3 allies
   within 2 tiles". A sentence that opens with a keyword opens with a capital. */
var NOUN={"target enemy":["target","enemy"], "target ally":["target","ally"],
  "an ally":["a","ally"], "an enemy":["a","enemy"], "any Unit":["any","Unit"],
  "all enemies within":["all","enemies"], "all allies within":["all","allies"], "all units within":["all","units"],
  "all enemies":["all","enemies"], "all allies":["all","allies"]};
function article(word){ return /^[aeiou]/i.test(word) ? "an" : "a"; }
function phrase(p, narrow){
  var g={district:[], subtype:[], archetype:[], distance:[]};
  narrow.forEach(function(q){ (g[q.kw.narrow]||g.archetype).push(q); });
  var adj=[g.district.map(function(q){ return "District "+(q.n||"?"); }),
           g.subtype.map(function(q){ return q.kw.name; }),
           g.archetype.map(function(q){ return q.kw.name; })]
    .filter(function(a){ return a.length; }).map(function(a){ return a.join(" or "); }).join(" ");
  var within=g.distance.length ? " within "+plural(g.distance[0].n||"1","tile") : "";
  var shape=NOUN[p.kw.name], n=(p.n===null||p.n===undefined)?"":String(p.n).trim();
  if(!shape) return label(p)+(adj?" ("+adj+")":"")+within;
  var lead=shape[0]==="a" ? (adj?article(adj):"an") : shape[0];
  var tail=/within$/.test(p.kw.name) ? " within "+plural(n||"1","tile") : "";
  return lead+(adj?" "+adj:"")+" "+shape[1]+tail+within;
}
function displayRuns(text){
  var parts=parse(text), runs=[], i, j;
  for(i=0;i<parts.length;i++){
    var p=parts[i];
    if(p.type==="text"){ runs.push({t:p.text, kw:false}); continue; }
    var cat=p.kw?category(p.kw.cat):null;
    var run={t:null, kw:true, cat:p.kw?p.kw.cat:null, colour:cat?cat.colour:(p.retired?"#8a8f94":null),
             retired:!!p.retired, unknown:!p.kw && !p.retired, part:p};
    if(p.kw && p.kw.cat==="target" && !p.kw.narrow){
      var narrow=[], last=i;
      for(j=i+1;j<parts.length;j++){
        var q=parts[j];
        if(q.type==="text"){
          var nx=parts[j+1];
          if(/^[\s,]*(?:(?:or|and)\s*)?$/i.test(q.text) && nx && nx.type==="kw" && nx.kw && nx.kw.narrow) continue;
          break;
        }
        if(q.kw && q.kw.narrow){ narrow.push(q); last=j; continue; }
        break;
      }
      if(narrow.length){ run.t=phrase(p, narrow); runs.push(run); i=last; continue; }
    }
    var before=runs.length && !runs[runs.length-1].kw ? runs[runs.length-1].t : "";
    run.t=label(p, before);
    runs.push(run);
  }
  /* a capital where a sentence opens on a keyword */
  var atStart=true;
  runs.forEach(function(r){
    if(!r.kw){ if(/\S/.test(r.t)) atStart=/[.!?]\s*$/.test(r.t); return; }
    if(atStart && r.t) r.t=r.t.charAt(0).toUpperCase()+r.t.slice(1);
    atStart=false;
  });
  return runs;
}
function render(text){
  return displayRuns(text).map(function(r){ return r.t; }).join("");
}

root.KETER_KW = {
  CATEGORIES:CATEGORIES, KEYWORDS:KEYWORDS, RETIRED:RETIRED, STATS:STATS, LEGACY_NAMES:LEGACY_NAMES,
  ARCHETYPES:ARCHETYPES, archetypes:archetypes, registerArchetypes:registerArchetypes, allKeywords:allKeywords,
  byName:byName, isRetired:isRetired, category:category, colourOf:colourOf,
  parse:parse, render:render, resolve:resolve, label:label, migrateText:migrateText,
  sentences:sentences, analyse:analyse, problems:problems, kindOf:kindOf, isContinuous:isContinuous,
  displayRuns:displayRuns, phrase:phrase, usesX:usesX, fillX:fillX
};
})(typeof window!=="undefined" ? window : this);
