#!/usr/bin/env node
/* Generates the cases that prove the game's battle code is the Companion's
   Battle Simulator: the keyword reader on every card's text; aiming (reach,
   sight, Cover); what an Action can do now and who it can be aimed at; the
   start of a fight; your moves and attacks, with everything the Action's text
   does and a Burst run to its end; holding fire; whole Enemy phases with the
   round turning over; whole fights begun from a Strike Team (the Deck
   shuffled, the Pouch filled, the Enemy pile dealt) and carried through
   rounds of waves, Aether, Chips and cards; cards played from the hand
   (Troops, Equipment, Commands, Aether cards), Consumables used, Chips spent
   for their effects, a carried Action paid for in Aether, and what reaches
   the Discard Pile and when; and the Deck Builder's checks.
   All on the export's own floors, with Units made from its own cards.

   The simulator's functions are taken out of shell.html exactly as they are,
   effect engine included, and run here with the board, the dice, the rules
   (rules.js) and the keyword library (keywords.js). Only what draws, animates,
   saves or belongs to playing cards and loot is stood in for.
   Writes game/tests/fixtures/sim_cases.json; the game's tests/sim_diff.gd
   replays every case and compares.

     node make_sim_cases.js cards.json floors.json      (both from an export)

   Deterministic: the same shell.html, rules.js, keywords.js and export give
   the same cases. */
"use strict";
const fs = require("fs"), path = require("path"), vm = require("vm");
const ROOT = __dirname;

/* ---- rules.js and keywords.js, as the Companion loads them ---- */
const buildPy = fs.readFileSync(path.join(ROOT, "build.py"), "utf8");
const behSrc = buildPy.match(/window\.KETER_BEHAVIORS=""" \+ r'''(\[[\s\S]*?\])'''/)[1];
const sb = { Math, JSON, String, Object, Array, parseInt, isNaN, console };
sb.window = sb;
vm.createContext(sb);
vm.runInContext("var KETER_BEHAVIORS=" + behSrc + ";", sb);
vm.runInContext(fs.readFileSync(path.join(ROOT, "rules.js"), "utf8"), sb);
vm.runInContext(fs.readFileSync(path.join(ROOT, "keywords.js"), "utf8"), sb);
/* loot.js too (game 0.7): what drops in a fight is rolled from a stream of its own, seeded for each fight */
Object.assign(sb, { parseFloat, isFinite, Date, Number });
vm.runInContext(fs.readFileSync(path.join(ROOT, "loot.js"), "utf8"), sb);
/* progress.js too (game 0.8): the blueprints and chassis a fight turns up are rolled from that same stream.
   It keeps what you own in the browser's storage; here that is only a table, filled from the export. */
const store = {};
sb.localStorage = { getItem: k => (k in store ? store[k] : null), setItem: (k, v) => { store[k] = String(v); }, removeItem: k => { delete store[k]; } };
sb.RegExp = RegExp;
const CONTENT = path.dirname(process.argv[2] || ".");
const readContent = n => { try { return JSON.parse(fs.readFileSync(path.join(CONTENT, n + ".json"), "utf8")); } catch(e){ return null; } };
const poolsIn = readContent("pools"), chassisIn = readContent("chassis"), tablesIn = readContent("tables");
if(poolsIn && poolsIn.pools) store["keter-app-pools"] = JSON.stringify(poolsIn.pools);
if(chassisIn && chassisIn.chassis){ const byId = {}; chassisIn.chassis.forEach(c => { byId[c.id] = c; }); store["keter-app-chassis"] = JSON.stringify(byId); }
if(tablesIn && tablesIn.workshop) sb.KETER_WORKSHOP = { tables: () => tablesIn.workshop };
vm.runInContext(fs.readFileSync(path.join(ROOT, "progress.js"), "utf8"), sb);
/* what you own, for one case: a blueprint's levels, a chassis, a name learned */
const setProg = st => { if(st) store["keter-app-progress"] = JSON.stringify(Object.assign({ seen: { enemy: {}, district: {}, comp: {} }, all: false }, JSON.parse(JSON.stringify(st)))); else delete store["keter-app-progress"]; };

/* ---- the simulator's own functions, out of shell.html ---- */
const shell = fs.readFileSync(path.join(ROOT, "shell.html"), "utf8");
function grab(name){
  const at = shell.indexOf("\nfunction " + name + "(");
  if(at < 0) throw new Error("not in shell.html: " + name);
  const eol = shell.indexOf("\n", at + 1), line = shell.slice(at + 1, eol);
  /* a function written on one line ends where its line does */
  if(/\}\s*$/.test(line) && (line.match(/\{/g) || []).length === (line.match(/\}/g) || []).length) return line;
  const end = shell.indexOf("\n}\n", at + 1);
  return shell.slice(at + 1, end + 2);
}
function grabText(from, to){
  const a = shell.indexOf(from); if(a < 0) throw new Error("not in shell.html: " + from);
  const b = shell.indexOf(to, a); if(b < 0) throw new Error("not in shell.html after it: " + to);
  return shell.slice(a, b + to.length);
}
const TAKEN = [
  /* the board */ "simCentre", "simTileKind", "simKindAt", "simUnitAt", "simSpawnTiles", "simCoverFor", "simSees", "simAimed", "simCanReach", "simWallFor",
  /* choosing */ "simActionState", "simOdds", "simPickAction", "simActionNarrow", "simMarkTargets", "simSay",
  /* attacking */ "simApplyAttack", "simConfirmAttack", "simBurstLive", "simBurstOf", "simBurstPool", "simBurstContinue", "simMoveTo",
  /* the Enemies */ "simEnemyAction", "simHurtsOwnSide", "simStepToward", "simStepAway", "simOneEnemy", "simWhyTarget", "simApplyEnemyAttack",
  /* the round */ "simEnemiesLeft", "simOutcome", "simRunPhase", "simEndOfRound", "simHalf", "simTurnEndTick",
  /* waves */ "simEnemySpawnTiles", "simRevealFor", "simInstabilityPick", "simSpawnWave", "simNothingMoreComing", "simWaveStep", "simFoePool", "simEnemyWant",
  /* Aether, Chips and cards */ "simAetherLabel", "simPhaseGenerate", "simPhaseChips", "simPhaseDraw", "simDrawPhase", "simCardCost", "simCostLabel",
  /* a Strike Team's fight */ "simRefCard", "simWizDeckCards", "simWizFinish", "simPlace",
  /* the Deck Builder's checks */ "normaliseLoadout", "loHeroes", "loDeckCards", "actionSlotsOf", "aetherCostOf", "pouchMinimum", "chipByKey", "pouchEntries", "pouchCount",
  "chipDistrictOf", "assignedActionCards", "refKey", "resolveRef", "districtOf", "ldrOf", "pingsForLoadout",
  /* holding fire */ "simHoldable", "simHoldFire", "simReactTo", "simLapseHolds",
  /* hazards */ "simHazardAt", "simHazardHit", "simHazardEndOfTurn",
  /* the effect engine */ "simEmit", "simUnitById", "simLeader", "simLeaderUnit", "simPassiveSources", "simFlushEvents", "kwPlain", "simLogEffect", "simEffectHalt",
  "simSentences", "simEnemiesOf", "simAlliesOf", "simDist", "simNarrowOK", "simResolveTargets", "simSubjectPool", "simWhenMatches", "simStateOf", "simCheck",
  "simLineStep", "simPush", "simApplyKeyword", "simRunText", "simHaltOnce", "simRunSentence", "simApplySentence", "simApplyContinuous", "simRoundPassives",
  "simCheckDowns", "simRunTrigger", "simBuff",
  /* cards */ "simUnitSpec",
  /* playing them (13.3) */ "simCanAct", "simCanPlay", "simPlayCard", "simPayAndDiscard", "simCardNeeds", "simBeginAim", "simConfirmAim", "simResolveCard",
  "simRecoverable", "simWithRecover", "simCardText", "simPlayPlain", "simPlayTroop", "simPlayEquipment", "simAttachEquipment", "simUseConsumable", "simSpendChip",
  "simBeginPick", "simDiscardOf", "simAetherOK", "simAetherWords", "simPayAether",
  /* variable costs (13.4) */ "simSlotX", "simCardVar", "simMaxX", "simXNote", "simXFill", "simAskX", "simAskXDraw", "simPlayCardGo", "simCostOf",
  "simActionAether", "simActionSetX", "simActionAetherWords", "aetherCostLeast",
  /* Auto (13.4) */ "simAutoAllies", "simAutoOne",
  /* loot in a fight (game 0.7) */ "simLootOn", "simPoiSkull", "simAddLoot", "simSalvage", "simFindLoot", "simSettleLoot",
  /* blueprints and chassis, and a deployment's fights (game 0.8) */ "simFindItems", "simDepCtx", "simDeployFinish",
  /* the movement keywords (Revision 16.1, game 0.21) */ "simKwNum", "simMeleeRole", "simLungeOf", "simChargeOf", "simLeapOf", "simMoveSteps", "simMoveLeft",
  "simReach", "simCoverScore", "simLungeSpot", "simDoLunge", "simCharged", "simDashAway", "simAfterAttacks",
  /* self-targeted Actions (Revision 16.2, game 0.22) */ "simSelfOnly", "simUseOnSelf",
  /* Revision 16.3's keywords, and Actions aimed at tiles (game 0.23) */ "simShapeTiles", "simAetherDistrict", "simCoverColour", "simTileAction", "simTileReach", "simUseOnTile"];
const vars = [shell.match(/var SIM_COVER=\{[^}]*\};/)[0], shell.match(/var SIM_EV=\{[^}]*\};/)[0], shell.match(/var SIM_INSTANT=\{[^}]*\};/)[0],
  shell.match(/var SIM_BUFFS=\{[^}]*\};/)[0], grabText("var BASIC_CHIPS=", "});"),
  /* written indented in shell.html, so it is taken by its first and last lines */
  grabText("function simHandCardOf(c){", "effects:fx, _raw:c._raw};\n  }")].join("\n");
/* how the rules tell the simulator about damage and statuses */
const hooks = grabText("(function(){\n  var RR=window.KETER_RULES; if(!RR || !RR.hooks) return;", "\n})();");
const stubs = `
var R = window.KETER_RULES, SIM = {units:[], log:[]}, DICE = null, CARDS = [], WAVES_PER_FLOOR = 6;
var SIM_WIZ = {}, SIM_DEP = null, LOADOUT = null;
/* a deployment's fight tells the deployment how it went; here that is only kept, to be compared */
var KETER_DEPLOY = { fightOver: function(res){ SIM._depRes = res; return {next:"map"}; } };
function simDeployResultHTML(){ return ""; }
function simFoeCards(){ return CARDS; }
function allCards(){ return CARDS; }
function simLoadoutList(){ return [LOADOUT]; }
function simUndoClear(){} function simFit(){} function say(){}
var SIM_UI = {};
function simPhaseDef(){ return {name: SIM.phase}; }
function esc(s){ return String(s); }
function simSelect(){}
function $(){ return {classList:{remove:function(){}, add:function(){}}}; }
function setTimeout(f){ f(); }
function simDice(){ return DICE; }
function simAllCards(){ return CARDS; }
function simFloat(u, text, kind){ if(u) SIM.floats.push({unit:u.id, text:text, kind:kind}); }
function simLogEnemy(t){ SIM.log.push({text:t}); }
function isDev(){ return false; }
function simGetRoll(){ throw new Error("manual roll asked for"); }
function simDraw(){} function renderSim(){} function simSave(){} function simSelect(){} function simSnapshot(){} function simPhaseSnapshot(){}
function simFxHold(){} function simFxRelease(){} function simShot(){} function simHitText(){}
`;
let taken = TAKEN.map(grab).join("\n");
function patch(from, to, what){ if(taken.indexOf(from) < 0) throw new Error("the simulator has changed: " + what + " no longer applies"); taken = taken.replace(from, to); }
/* The game found two mistakes in the simulator's Enemy turn (an Enemy brought
   down mid-move by a held shot went on to attack; one still out of reach
   after its move attacked from wherever it stood). Companion 13.2 fixed both
   at the source, so nothing is patched here any more: this only makes sure
   the fixes are still there. */
["if(enemy.down){ simDraw(); renderSim(); return setTimeout(next, 380); }", "simLogEnemy(enemy.name+\" has nothing in reach\");"].forEach(function(must){
  if(taken.indexOf(must) < 0) throw new Error("the simulator has changed: its Enemy turn has lost a 13.2 fix (" + must + ")");
});
/* Not a fix, only so two runs agree: a Unit put down by Deploy is given a
   counted id here ("d1"), where the Companion gives it a random one. */
patch("nu.pos=spot; SIM.units.push(nu); placed++;", "nu.pos=spot; nu.id=\"d\"+(++SIM.deployed); if(SIM.countIds) SIM.idCount[nu.side]--; SIM.units.push(nu); placed++;", "the Deploy id");
/* A rule the game has had since 0.2: a spawn tile's Enemies come from the
   floor's own District at the tile's level (the simulator's rule on a
   deployment), where a free fight in the simulator takes any District. */
patch("var pool=SIM.deploy ? simFoePool(+lv, SIM.deploy.district) :", "var pool=true ? simFoePool(+lv, String((SIM.map&&SIM.map.district)||\"\")) :", "the floor's District");
vm.runInContext(stubs + vars + "\n" + taken + "\n" + hooks, sb);
const R = sb.KETER_RULES;
/* Units made as a fight is set up are numbered as the game numbers them (a1,
   a2... e1, e2...), where the Companion gives each a random id. */
vm.runInContext("(function(){ var make=R.unitFromCard; R.unitFromCard=function(spec, side){ var u=make(spec, side);" +
  " if(SIM.countIds){ SIM.idCount[u.side]=(SIM.idCount[u.side]||0)+1; u.id=(u.side===\"ally\"?\"a\":\"e\")+SIM.idCount[u.side]; } return u; }; })();", sb);

/* ---- a seeded generator for the cases themselves ---- */
let seed = 20261001;
function rnd(){ seed |= 0; seed = seed + 0x6D2B79F5 | 0; let t = Math.imul(seed ^ seed >>> 15, 1 | seed); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }
const ri = (a, b) => a + Math.floor(rnd() * (b - a + 1));
const pick = (l) => l[Math.floor(rnd() * l.length)];
const chance = (p) => rnd() < p;
const clone = (o) => JSON.parse(JSON.stringify(o === undefined ? null : o));

const cards = JSON.parse(fs.readFileSync(process.argv[2], "utf8")).cards || [];
/* (v14.9) the cards that can be found as loot: the export's own */
sb.KETER_PROG.useCards(() => cards);
/* (v14.7) a battlefield chunk is a piece of a floor, never fought on alone */
const floors = (JSON.parse(fs.readFileSync(process.argv[3], "utf8")).floors || []).filter(f => (f.hexes || []).length && !(f.chunk && typeof f.chunk === "object"));
const cases = [], fights = [];
function add(fn, args, result, after){ cases.push({ fn, args: clone(args), result: clone(result), after: after === undefined ? undefined : clone(after) }); }

/* ---- cards as the simulator reads them ---- */
cards.forEach(c => add("unitSpec", [c], sb.simUnitSpec(c, "ally")));

/* ---- the keyword reader, on every card's text ----
   The simulator registers every Archetype a card carries as a narrowing word. */
const K = sb.KETER_KW;
cards.forEach(c => { if(c.archetypes && c.archetypes.length) K.registerArchetypes(c.archetypes); });
const texts = [];
cards.forEach(c => (c.entries || c.abilities || []).forEach(a => { if(a && a.text) texts.push(String(a.text)); }));
["[[if damaged]] [[target enemy]] gains [[Bleed]].", "[[closer than 3]] deal [[damage 2]].", "[[further than]] 4 heals.",
 "[[when deployed]] [[Deploy 2 Aether Battery]] [[adjacent]].", "[[+10 HP]] [[persistent]]", "[[Modify AC +2]]", "[[Splash 2]] and [[Nonsense 3]]",
 "[[all allies within 2]] [[District 3]] [[Sniper]] gain [[Evasive 2]] [[turns 2]]. [[when]] [[an enemy]] [[ends its move within 2]] [[Push 1]]!",
 "[[when]] [[this Unit]] [[gains Bleed]] [[heal 2]]. [[while]] [[this Unit]] [[is below half HP]] [[DMG +2]] [[persistent]]",
 "[[if]] [[the target]] [[has Marked]] [[damage]] 3 [[target enemy]] or [[Ranged]], [[Melee]].", "[[while]] [[takes damage]]", "[[the round begins]] [[if]]",
 "No keywords at all.", "", "[[turns 3]] for [[turns 2]] [[within 3]] [[target ally]] [[Healer]] and [[Support]]",
 /* variable costs (13.4): X as a keyword's number, and where it is only a letter */
 "[[target enemy]] takes [[damage X]].", "[[Deploy X Aether Battery]]. [[Deploy 2 Model X]]. [[deploy x Test Drone]] [[Deploy X]]", "[[this Unit]] gains [[HP +X]] for [[turns X]].",
 "[[+X HP]] to [[this Unit]]. [[-X AC]] [[AC -X]] [[X AC]]", "[[AoE X]]. [[all enemies within X]] take [[damage 2]]. [[ Slowed  X ]] [[Burst X]] [[Chain X]]",
 "X marks the spot [[damage 3]] X. [[damage x]] [[damage XX]] [[target enemy]] [[within X]]", "[[when]] [[an enemy]] [[ends its move within X]], [[that Unit]] takes [[damage X]]."].forEach(t => texts.push(t));
const seenT = {};
/* Handbook 15.9: how often the end of your turn had something to tick */
const late = { given: 0, ticked: 0, lines: 0 };
function lateTick(){ const n = SIM.log.length; sb.simTurnEndTick(); if(SIM.log.length > n){ late.ticked++; late.lines += SIM.log.length - n; } }
texts.forEach(t => {
  if(seenT[t]) return; seenT[t] = 1;
  add("kwParse", [t], K.parse(t));
  add("kwX", [t], { uses: K.usesX(t), one: K.fillX(t, 1), four: K.fillX(t, 4), none: K.fillX(t, 0), odd: K.fillX(t, "2") });
  add("kwRender", [t], K.render(t));
  add("kwSentences", [t], K.sentences(t));
  K.sentences(t).forEach(sent => {
    const an = K.analyse(sent);
    add("kwAnalyse", [sent], an);
    add("kwProblems", [sent, "action"], K.problems(an, { kind: "action" }));
    add("kwProblems", [sent, "passive"], K.problems(an, { kind: "passive" }));
    if(K.usesX(sent)) add("kwProblems", [sent, "action", false], K.problems(an, { kind: "action", variable: false }));
  });
});
["Rooted", "rooted 3", "Deploy 2 Aether Battery", "+10 HP", "-2 AC", "AC +2", "Modify AC +2", "Splash", "unknown 4", "target enemy",
 "all units within 2", "  Bleed  ", "District 3", "Sniper", "gains Marked", "turns"].forEach(tk => add("kwResolve", [tk], K.resolve(tk)));

function mapOf(f){
  f = clone(f);    /* (0.23) a Barricade changes a fight's floor: each fight has its own */
  const hexes = {}, walls = {};
  (f.hexes || []).forEach(p => { hexes[p[0]] = p[1] || {}; });
  (f.walls || []).forEach(p => { walls[p[0]] = p[1]; });
  /* hazards, exactly as simLoadFloor reads them: a symbol carrying an effect, and where its marks sit */
  const hazards = {}, hazAt = {};
  (f.symDefs || []).forEach(d => { if(d && d.hazard && (d.hazard.keyword || d.hazard.damage))
    hazards[d.id] = { text: d.text, keyword: d.hazard.keyword || "", damage: parseInt(d.hazard.damage, 10) || 0, when: d.hazard.when || "both" }; });
  (f.marks || []).forEach(pair => { if(hazards[pair[1]]) hazAt[pair[0]] = hazards[pair[1]]; });
  /* Locked Chests and the floor's own reward, exactly as simLoadFloor reads them */
  const chests = {};
  (f.marks || []).forEach(pair => { const d = (f.symDefs || []).filter(x => x && x.id === pair[1])[0];
    const m = d && /^LC(\d*)$/i.exec(String(d.text || "").trim()); if(m) chests[pair[0]] = parseInt(m[1], 10) || 0; });
  return { name: f.name, hexes, walls, colorLabels: f.colorLabels || {}, hazards: hazAt, district: f.district || "", level: f.level || "", loot: f.loot || null, chests };
}
const act = (name, role, o, text) => Object.assign({ name, tag: "Active", cost: 0, role, text }, o);
const CRAFTED = [
  act("Sweep", "melee", { dmg: "3", pen: "12" }, "[[Burst 3]] [[target enemy]] takes [[Push 1]]."),
  act("Volley", "ranged", { rng: "6", hit: "2", pen: "12", dmg: "2" }, "[[Burst 2]]. [[target enemy]] gains [[Marked]] [[turns 2]]."),
  act("Lance", "ranged", { rng: "6", hit: "2", pen: "14", dmg: "4" }, "[[Pierce]]."),
  act("Blast", "ranged", { rng: "5", hit: "2", pen: "14", dmg: "3" }, "[[AoE 1]]. [[all enemies within 1]] gain [[Slowed 2]] [[turns 2]]."),
  act("Arc", "aether", { rng: "4", dmg: "3" }, "[[Chain 2]]."),
  act("Call", "support", {}, "[[Deploy 1 Test Drone]] [[adjacent]]."),
  act("Summon", "melee", { dmg: "0", pen: "14" }, "[[Deploy 2 Test Drone]]. [[Deploy 1 Nobody Home]]. [[Deploy]]."),
  act("Offer", "support", {}, "[[target ally]] [[Sacrifice]]. [[this Unit]] [[heal 6]]."),
  act("Cleanse", "support", {}, "[[target ally]] [[remove Poisoned]]. [[target ally]] [[remove equipment]]. [[target ally]] [[heal 4]]."),
  act("Lift", "support", {}, "[[target ally]] gains [[Flying]]."),
  act("Dig in", "melee", { dmg: "1", pen: "14" }, "[[this Unit]] counts as behind [[Half Cover]] [[turns 2]]. [[target enemy]] counts as behind [[Full Cover]]."),
  act("Brace", "melee", { dmg: "1", pen: "14" }, "[[this Unit]] [[+2 AC]] [[turns 2]]. [[this Unit]] [[HP +5]] [[persistent]]. [[this Unit]] [[-1 MS]]. [[this Unit]] [[NRG]] [[turns 2]]."),
  act("Hex", "cyber", { rng: "5", hit: "2", pen: "12", dmg: "1" }, "[[if]] [[the target]] [[takes damage]] [[target enemy]] gains [[Stunned]]. [[if]] [[the target]] [[has Marked]] [[damage 3]]. [[if]] [[this Unit]] [[kills an enemy]] [[this Unit]] [[NRG +2]] [[turns 1]]. [[if]] [[the target]] [[is within 2]] [[target enemy]] gains [[Poisoned 2]] [[turns 3]]."),
  act("Broken", "melee", { dmg: "1", pen: "14" }, "[[Splash 2]]. [[Nonsense]] here. [[damage]]. Plain words. [[when]] [[this Unit]] [[moves]] [[damage 1]]. [[target enemy]] [[Overclock]]."),
  act("Shove", "melee", { dmg: "1", pen: "14" }, "[[target enemy]] takes [[Push 3]]."),
  act("Storm", "ranged", { rng: "5", hit: "1", pen: "14", dmg: "2" }, "[[all units within 2]] take [[damage 1]]. [[all allies within 2]] [[heal 2]]. [[target tile]] [[Rooted]]. [[adjacent]] [[Weakened 1]] [[persistent]]."),
  act("Snipe", "ranged", { rng: "7", hit: "3", pen: "10", dmg: "3" }, "[[target enemy]] [[Ranged]] [[District 3]] takes [[Bleed]] [[turns 2]]."),
  act("Cover fire", "ranged", { rng: "5", hit: "3", pen: "10", dmg: "3" }, "[[Suppressive Fire]]. [[Burst 2]]. [[target enemy]] gains [[Pinned]]."),
  act("Drain", "melee", { dmg: "2", pen: "14" }, "[[if]] [[this Unit]] [[deals damage]] [[target enemy]] gains [[Drained 1]] [[turns 2]]. [[if]] [[the target]] [[is Incapacitated]] [[this Unit]] [[heal 3]]. [[if]] [[this Unit]] [[is at full HP]] [[this Unit]] [[+1 AP]] [[turns 2]]."),
  act("Rally", "support", {}, "[[all allies within 2]] [[Support]] [[Melee]] [[+1 DMG]] [[turns 2]]. [[target ally]] [[within 3]] gains [[Evasive 1]] [[turns 2]]. [[that Unit]] [[heal 1]]."),
  /* 14.0 (Handbook 16.0): Execute, and the locks given twice, too long and by an always-on Passive */
  act("Cull", "melee", { dmg: "4", pen: "14" }, "[[target enemy]] takes [[damage 2]] and faces an [[Execute]]."),
  act("Daze", "ranged", { rng: "5", hit: "2", pen: "12", dmg: "1" }, "[[target enemy]] gains [[Stunned]] for [[turns 2]]. [[target enemy]] gains [[Rooted]]. [[target enemy]] gains [[Marked]] for [[turns 5]]."),
  act("Misfire", "support", {}, "[[target ally]] faces an [[Execute]]."),
];
const pas = (name, text, tag) => ({ name, tag: tag || "Passive", cost: 0, role: "", text });
const PASSIVES = [
  pas("Flinch", "[[when]] [[this Unit]] [[takes damage]] [[this Unit]] gains [[Evasive 2]] [[turns 1]]."),
  pas("Thorns", "[[when]] [[an enemy]] [[attacks]] [[that Unit]] takes [[damage 1]]."),
  pas("Avenge", "[[when]] [[an ally]] [[is Incapacitated]] [[this Unit]] [[DMG +2]] [[turns 2]]."),
  pas("Feast", "[[when]] [[this Unit]] [[kills an enemy]] [[this Unit]] [[heal 3]]."),
  pas("Snare", "[[when]] [[an enemy]] [[ends its move within 2]] [[that Unit]] gains [[Slowed 1]] [[turns 2]]."),
  pas("Banner", "[[when]] [[this Unit]] [[is deployed]] [[all allies within 2]] count as behind [[Half Cover]] [[turns 2]]."),
  pas("Mend", "[[when]] [[the round begins]] [[this Unit]] [[heal 2]]."),
  pas("Salt", "[[when]] [[any Unit]] [[gains Bleed]] [[that Unit]] takes [[damage 1]]."),
  pas("Stomp", "[[when]] [[this Unit]] [[moves]] [[all enemies within 1]] take [[damage 1]]."),
  pas("Scent", "[[when]] [[an enemy]] [[takes damage]] [[if]] [[that Unit]] [[is below half HP]] [[that Unit]] gains [[Marked]]."),
  pas("Burst apart", "[[when]] [[this Unit]] [[is Incapacitated]] [[all units within 1]] take [[damage 2]]."),
  pas("Spare", "[[when]] [[this Unit]] [[is Incapacitated]] [[Deploy 1 Test Drone]]."),
  pas("Parry", "[[when]] [[this Unit]] [[is attacked]] [[that Unit]] gains [[Weakened 1]] [[turns 1]]. [[when]] [[this Unit]] [[deals damage]] [[that Unit]] takes [[Push 1]]."),
  pas("Pulse", "[[when]] [[the round begins]] [[all enemies within 3]] gain [[Stunned]]."),
  pas("Lockdown", "[[all enemies within 2]] gain [[Pinned]]."),
  pas("Fury", "[[while]] [[this Unit]] [[is below half HP]] [[this Unit]] [[+2 DMG]]. [[this Unit]] [[+3 HP]]. [[this Unit]] [[+1 NRG]]."),
  pas("Wings", "[[this Unit]] gains [[Flying]]. [[while]] [[an enemy]] [[is within 1]] [[this Unit]] [[-1 AC]]."),
  pas("Ward", "[[Aura 2]] [[all allies within 2]] [[+1 AC]].", "Aura"),
  pas("Dread", "[[Aura 1]] [[all enemies within 1]] gain [[Weakened 1]].", "Aura"),
  pas("Shelter", "[[Aura 2]] [[all allies within 2]] count as behind [[Half Cover]].", "Aura"),
  pas("Seep", "[[all enemies within 1]] take [[damage 1]]. [[this Unit]] [[heal 1]]."),
  pas("Muddle", "[[if]] [[this Unit]] [[is below half HP]] [[this Unit]] [[heal 2]]. [[Splash 1]] [[damage 1]]. Just words."),
  pas("Far sight", "[[while]] [[an enemy]] [[is further than 3]] [[this Unit]] [[+2 Range]]. [[while]] [[this Unit]] [[has Marked]] [[this Unit]] [[+2 INT]]."),
];
const fighters = cards.filter(c => /^(hero|troop)$/.test(c.cardType)), foes = cards.filter(c => /^(enemy|elite|miniboss)$/.test(c.cardType));
const BEH = R.behaviors().filter(b => b.side === "enemy");
function makeUnit(card, side, id){
  const u = R.unitFromCard(sb.simUnitSpec(card, side), side);
  u.id = id;
  if(chance(0.4)) u.hp = ri(1, u.hpMax);
  if(chance(0.35)) u.nrg = ri(0, u.nrgMax + 2);
  if(chance(0.25)) R.addStatus(u, pick(["Marked", "Rooted", "Stunned", "Half Cover", "Full Cover", "Pinned"]), null, pick(["enemy", "rule", "player"]), ri(1, 2));
  if(chance(0.25)) R.addStatus(u, pick(["Slowed", "Evasive", "Sundered", "Weakened", "Bleed", "Poisoned"]), ri(1, 3), pick(["enemy", "player"]), ri(1, 3));
  if(chance(0.1)) u.flying = true;
  if(chance(0.1)) u.evasive = ri(1, 2);
  if(chance(0.15)) u.mods = [{ stat: pick(["AC", "MS", "DMG", "INT", "RANGE", "AP"]), amt: ri(-2, 3), dur: "turns", n: ri(1, 2) }];
  /* Actions and Passives written to use every keyword the engine carries out,
     and a few it must refuse, so no branch of it goes untried */
  if(chance(0.4)){ const n = ri(1, 3); for(let i = 0; i < n; i++){ const a = clone(pick(CRAFTED)); a.cost = pick([0, 0, 1]); if(side === "enemy" && chance(0.6)) a.tag = "Combo"; if(chance(0.5)) u.actions.unshift(a); else u.actions.push(a); } }
  if(chance(0.35)){ const n = ri(1, 2); for(let i = 0; i < n; i++) u.actions.push(clone(pick(PASSIVES))); }
  if(side === "enemy"){
    if(chance(0.5)){ u.behaviors = []; const n = ri(1, 2); for(let i = 0; i < n; i++){ const b = pick(BEH), o = { k: b.k }; if(b.param && chance(0.7)) o.x = b.param === "tiles" ? ri(1, 3) : ri(3, 25); u.behaviors.push(o); } }
    if(chance(0.4)) u.comboAt = ri(0, 3);
  }
  return u;
}
/* a fight on a real floor: sometimes the sides start apart, more often in a
   knot around one tile, so that blows, areas, pushes and Auras all find someone */
function fight(f){
  const map = mapOf(f), keys = Object.keys(map.hexes);
  const sorted = keys.slice().sort((a, b) => { const A = R.hexParse(a), B = R.hexParse(b); return (A.r - B.r) || (A.q - B.q); });
  const used = {}, units = [];
  const knot = chance(0.65), hub = R.hexParse(pick(keys)), spread = chance(0.5) ? 0.5 : 1;
  const hz = Object.keys(map.hazards);
  const near = keys.filter(k => R.hexDistance(R.hexParse(k), hub) <= 3);
  function place(u, low){
    for(let tries = 0; tries < 60; tries++){
      let k;
      if(hz.length && chance(0.12)) k = pick(hz);
      else if(knot) k = pick(near);
      else {
        const span = Math.max(1, Math.floor(sorted.length * spread * (0.3 + rnd() * 0.7)));
        k = low ? sorted[sorted.length - 1 - Math.floor(rnd() * span)] : sorted[Math.floor(rnd() * span)];
      }
      if(k && !used[k]){ used[k] = 1; u.pos = R.hexParse(k); return true; }
    }
    return false;
  }
  const na = ri(1, 4), ne = ri(1, 4);
  for(let i = 0; i < na; i++){ const u = makeUnit(i === 0 ? pick(fighters.filter(c => c.cardType === "hero")) : pick(fighters), "ally", "a" + i); if(place(u, true)) units.push(u); }
  for(let i = 0; i < ne; i++){ const u = makeUnit(pick(foes), "enemy", "e" + i); if(place(u, false)) units.push(u); }
  if(chance(0.1) && units.length > 2) pick(units).down = true;
  return { map, units };
}
const SIM = sb.SIM, WAVES = 6;
vm.runInContext("CARDS = window.CARDS_IN;", Object.assign(sb, { CARDS_IN: cards }));
function load(st, sd){
  SIM.map = st.map; SIM.units = st.units; SIM.log = []; SIM.floats = []; SIM._wallSegs = null; SIM._wallSegsFor = null; SIM.autoRunning = true;
  SIM.protos = []; SIM.leader = null; SIM.discard = []; SIM.bank = []; SIM.haltedPassives = {}; SIM.halted = null; SIM.deployed = 0;
  SIM.pendingAct = null; SIM.burst = null; SIM.targets = null; SIM.odds = null; SIM.reach = []; SIM.phase = "turn"; SIM.over = false;
  SIM.wave = WAVES; SIM.waveTurn = 0; SIM.enemyPile = []; SIM.instability = 0; SIM.countIds = false; SIM.aether = {}; SIM.hand = []; SIM.deck = []; SIM.pouch = [];
  vm.runInContext("SIM_EV.queue=[]; SIM_EV.busy=false; SIM_EV.origin=[]; SIM_EV.dealer=null;", sb);
  if(sd !== undefined){ sb.DICE_IN = R.makeDice(sd); vm.runInContext("DICE = window.DICE_IN;", sb); }
  /* loot rolls from its own stream: the fight's seed, or 0 where a case has none */
  SIM.loot = null; SIM.looted = {}; SIM.lootResult = null; SIM.found = []; SIM.deploy = null; SIM.deployResult = null; SIM._depRes = null;
  vm.runInContext("SIM_DEP = null;", sb);
  setProg(null);
  sb.KETER_LOOT.seed(sd === undefined ? 0 : sd);
}
/* what a Strike Team's fight may be given: blueprints and chassis already owned, and a deployment to be part of */
const ITEMS = ((poolsIn && poolsIn.pools && poolsIn.pools["3"] && poolsIn.pools["3"].items) || []).concat(["bp:Rooted:1", "bp:Drained:1", "bp:Drained:2", "bp:Evasive:1", "bp:Sundered:1", "bp:Marked:1", "ch:ch_test_threshold", "ch:ch_test_verdant"]);
function someProg(){
  const st = { bp: {}, ch: {}, named: {} };
  for(let n = ri(0, 5); n > 0; n--){ const o = sb.KETER_PROG.parseItem(pick(ITEMS)); if(!o) continue; if(o.kind === "bp") st.bp[o.name] = ri(1, 2); else st.ch[o.id] = true; }
  if(chance(0.3)){ const o = sb.KETER_PROG.parseItem(pick(ITEMS)); if(o) st.named[o.kind === "bp" ? "bp:" + o.name : "ch:" + o.id] = 1; }
  return st;
}
function someDeploy(){ const pend = []; for(let n = pick([0, 0, 1, 2]); n > 0; n--) pend.push(pick(ITEMS)); return { skull: ri(1, 6), kind: pick(["poi", "ambush"]), pending: pend }; }
/* after load(): the case's own progress, and its deployment if it has one (the floor then takes the tile's District) */
function dress(setup){
  setProg(setup.prog || null);
  if(setup.deploy){ sb.DEP_IN = { district: String(SIM.map.district || ""), skull: setup.deploy.skull, kind: setup.deploy.kind, pending: setup.deploy.pending.slice() }; vm.runInContext("SIM_DEP = window.DEP_IN;", sb); }
}
/* what has dropped and been found: the lines the log carries, the haul, and the tiles emptied */
const lootOf = () => ({ lines: SIM.log.filter(l => l.loot).map(l => l.text), haul: sb.KETER_LOOT.norm(SIM.loot), looted: Object.keys(SIM.looted || {}).sort() });
/* Loot Tiles and Locked Chests not yet emptied */
const lootSpots = () => Object.keys(SIM.map.hexes).filter(k => !(SIM.looted || {})[k] &&
  ((SIM.map.chests || {})[k] !== undefined || sb.simTileKind((SIM.map.colorLabels || {})[(SIM.map.hexes[k] || {}).c]) === "loot"));
/* what a case came to: the log (less the Chips line, which belongs to cards),
   what rose off the Units, any card problem, and every Unit */
const told = () => ({ log: SIM.log.filter(l => !l.loot).map(l => l.text).filter(t => !/^Recharge: /.test(t)), floats: SIM.floats, halted: SIM.log.filter(l => l.halt).map(l => l.text), loot: lootOf() });
const unit = (st, id) => st.units.filter(u => u.id === id)[0];

const allyBeh = (R.behaviors() || []).filter(b => b.side === "ally");
for(let i = 0; i < 520; i++){
  const f = floors[i % floors.length], st0 = fight(f), raw = clone(st0.units);
  fights.push({ floor: f.name, units: raw });
  const f0 = fights.length - 1;   /* each case names its fight, rather than carrying it */

  /* the fight begins: what is always on is worked out, your Units are deployed, each Enemy arrives */
  load(st0);
  sb.simApplyContinuous();
  SIM.units.forEach(u => { if(u.side === "ally" && u.pos) sb.simEmit("is deployed", u); });
  sb.simFlushEvents();
  SIM.units.slice().forEach(u => { if(u.side === "enemy" && u.pos && !u.down){ sb.simHazardHit(u, "arrives on"); sb.simRunTrigger(u, "deployed"); } });
  add("startFight", [f0], told(), st0.units);

  /* everything after starts from there */
  const start = clone(st0.units);
  fights.push({ floor: f.name, units: start });
  const fi = fights.length - 1;
  const fresh = (sd) => { const st = { map: st0.map, units: clone(start) }; load(st, sd); return st; };

  let st = fresh();
  const live = st.units.filter(u => !u.down && u.pos);
  /* Cover, reach, what each Action can do, and who it can be aimed at */
  for(let j = 0; j < 4 && live.length > 1; j++){
    const a = pick(live), b = pick(live.filter(u => u !== a));
    add("coverFor", [fi, b.id, a.id], sb.simCoverFor(b, a));
    (a.actions || []).forEach((act, ai) => {
      add("canReach", [fi, a.id, ai, b.id], sb.simCanReach(a, act, b));
      if(act.tag === "Passive" || act.tag === "Aura") return;
      add("actionState", [fi, a.id, ai], sb.simActionState(a, act));
      SIM.pendingAct = null; SIM.targets = null; SIM.log = [];
      /* the simulator picks an Action by its name, so of two with one name (these made-up Units can have that) only the first can be asked about */
      if((a.actions || []).findIndex(x => x.name === act.name) === ai){
        /* (0.22, Revision 16.2) one used on its own Unit at once has nothing to aim at */
        if(sb.simSelfOnly(act) || sb.simTileAction(act)) add("targets", [fi, a.id, ai], []);   /* (0.23) nor one aimed at a tile */
        else { sb.simPickAction(a, act.name); add("targets", [fi, a.id, ai], Object.keys(SIM.targets || {}).map(k => SIM.targets[k]).sort()); }
      }
      add("hurtsOwnSide", [fi, a.id, ai, b.id], sb.simHurtsOwnSide(a, act, b));
    });
    add("holdable", [fi, a.id], sb.simHoldable(a).map(x => x.name));
  }
  /* (0.21, Revision 16.1) the movement keywords: the tiles in reach with a Leap, where a Lunge
     would end and whether it reaches, the damage a Charge adds, and an Enemy's Dash away */
  for(let j = 0; j < 3 && live.length > 1; j++){
    const a = pick(live), b = pick(live.filter(u => u !== a));
    const steps = ri(0, 6), lp = pick([0, 0, 1, 2, 3, 5]), keep = a.leap;
    a.leap = lp;
    add("reachTiles", [fi, a.id, steps, lp], sb.simReach(a, steps));
    if(keep === undefined) delete a.leap; else a.leap = keep;
    const ln = ri(1, 4), cg = ri(0, 3), trav = ri(0, 4);
    const act = { name: "Lunge test", role: pick(["melee", "melee", "", "ranged"]), text: "[[Lunge " + ln + "]]." + (cg ? " [[Charge " + cg + "]]." : ""), dmg: String(ri(1, 6)), rng: "3", hit: "8", pen: "4" };
    add("lungeSpot", [fi, a.id, act, b.id], sb.simLungeSpot(a, act, b));
    add("canReachLunge", [fi, a.id, act, b.id], [sb.simCanReach(a, act, b), sb.simCanReach(a, act, b, true)]);
    const keepT = a.travel; a.travel = trav;
    add("charged", [fi, a.id, act, b.id, trav], { act: sb.simCharged(a, act), dmg: sb.simOdds(a, act, b).dmg });
    if(keepT === undefined) delete a.travel; else a.travel = keepT;
    const s2 = fresh(), a2 = unit(s2, a.id), b2 = unit(s2, b.id), dn = ri(1, 3), from = chance(0.7) ? b.id : null;
    const said = sb.simDashAway(a2, from ? b2 : null, dn);
    add("dashAway", [fi, a.id, from, dn], { said: said, told: told() }, s2.units);
    load(st);      /* back to this fight as it stands, for the next */
  }

  /* one of your Units moves */
  st = fresh();
  const movers = st.units.filter(u => u.side === "ally" && !u.down && u.pos);
  if(movers.length){
    const me = pick(movers), eff = R.effective(me);
    /* (0.21) as far as it may move: a Dash on top, and Leap's jumps among the tiles */
    const tiles = sb.simReach(me, sb.simMoveLeft(me));
    if(tiles.length){
      const hzt = tiles.filter(t => SIM.map.hazards[R.hexKey(t.q, t.r)]);
      const t = (hzt.length && chance(0.5)) ? pick(hzt) : pick(tiles);
      SIM.reach = tiles;
      sb.simMoveTo(me, t.q, t.r);
      add("playerMove", [fi, me.id, t.q, t.r], told(), st.units);
    }
  }

  /* one of your Units uses an Action, with the dice from a seed; a Burst runs to its end */
  const tried = {};
  for(let k = 0; k < 3; k++){
    st = fresh();
    const opts = [];
    st.units.filter(u => u.side === "ally" && !u.down && u.pos).forEach(me => (me.actions || []).forEach((a, ai) => {
      if(a.tag === "Passive" || a.tag === "Aura" || !sb.simActionState(me, a).ok || sb.simSelfOnly(a) || sb.simTileAction(a)) return;
      SIM.pendingAct = null; SIM.targets = null;
      sb.simPickAction(me, a.name);
      Object.keys(SIM.targets || {}).forEach(key => { const tk = me.id + "|" + ai + "|" + SIM.targets[key]; if(!tried[tk]) opts.push([me.id, ai, SIM.targets[key], tk]); });
    }));
    if(!opts.length) break;
    /* the Actions that do most are tried first: a Burst, an area, a Push */
    const rich = opts.filter(o => /Burst|AoE|Chain|Pierce|Line|Cone|Hardened|Aim|Push|Deploy|heal/.test(unit(st, o[0]).actions[o[1]].text || ""));
    const o = (rich.length && chance(0.7)) ? pick(rich) : pick(opts), sd = ri(1, 1e6);
    tried[o[3]] = 1;
    st = fresh(sd);
    sb.simConfirmAttack(unit(st, o[0]), unit(st, o[2]), unit(st, o[0]).actions[o[1]]);
    add("playerAttack", [fi, o[0], o[1], o[2], sd], told(), st.units);
  }

  /* (0.22, Revision 16.2) one of your Units uses an Action on itself, at once */
  st = fresh();
  const selves = [];
  st.units.filter(u => u.side === "ally" && !u.down && u.pos).forEach(me => (me.actions || []).forEach((a, ai) => {
    if(a.tag !== "Passive" && a.tag !== "Aura" && sb.simSelfOnly(a) && sb.simActionState(me, a).ok) selves.push([me.id, ai]); }));
  if(selves.length){
    const o = pick(selves), sd = ri(1, 1e6);
    st = fresh(sd);
    sb.simUseOnSelf(unit(st, o[0]), unit(st, o[0]).actions[o[1]]);
    add("selfUse", [fi, o[0], o[1], sd], told(), st.units);
  }

  /* (0.23) one of your Units uses an Action aimed at a tile: a Barricade put down, on an empty tile or not */
  st = fresh();
  const spots = [];
  st.units.filter(u => u.side === "ally" && !u.down && u.pos).forEach(me => (me.actions || []).forEach((a, ai) => {
    if(a.tag !== "Passive" && a.tag !== "Aura" && sb.simTileAction(a) && sb.simActionState(me, a).ok)
      Object.keys(sb.simTileReach(me, a)).forEach(k => spots.push([me.id, ai, k])); }));
  if(spots.length){
    const o = pick(spots), sd = ri(1, 1e6), q = +o[2].split(",")[0], r = +o[2].split(",")[1];
    st = fresh(sd);
    SIM.map = clone(st0.map);          /* the floor a Barricade changes is this case's own */
    sb.simUseOnTile(unit(st, o[0]), unit(st, o[0]).actions[o[1]], { q: q, r: r });
    add("tileUse", [fi, o[0], o[1], q, r, sd], Object.assign(told(), { tile: sb.simKindAt(q, r) || "" }), st.units);
    SIM.map = st0.map;
  }

  /* Auto: your Units take their turns by the Behavior keywords they are given, as the Enemies do by theirs.
     Some are hurt first, so a Medic has someone to tend. */
  for(let k = 0; k < 2; k++){
    const sd3 = ri(1, 1e6);
    st = fresh(sd3);
    const given = [], hurt = [];
    st.units.filter(u => u.side === "ally" && !u.down && u.pos).forEach(u => {
      if(chance(0.75)){ const bs = []; for(let n = ri(1, 3); n > 0; n--){ const d = pick(allyBeh); if(!bs.some(b => b.k === d.k)) bs.push(d.param ? { k: d.k, x: pick([d.pdef, 1, 3, 6, 40]) } : { k: d.k }); }
        u.behaviors = bs; given.push([u.id, clone(bs)]); }
      if(chance(0.35)){ u.hp = Math.max(1, Math.floor(u.hpMax / pick([2, 3, 10]))); hurt.push([u.id, u.hp]); }
    });
    sb.simAutoAllies(function(){});
    add("autoTurn", [fi, sd3, given, hurt], told(), st.units);
  }

  /* some of your Units hold fire; then the Enemy phase, one Enemy after another, and the round turns over */
  const sd2 = ri(1, 1e6);
  st = fresh(sd2);
  const holds = [];
  st.units.filter(u => u.side === "ally" && !u.down && u.pos).forEach(u => {
    const h = sb.simHoldable(u);
    if(h.length && chance(0.7)){ const a = pick(h); sb.simHoldFire(u, a.name); holds.push([u.id, a.name]); }
  });
  /* Handbook 15.9: Statuses and timed changes that arrived in either half of
     the round. Those from the Enemies' half tick as your turn ends; the rest
     at the Recharge. */
  const had = [];
  st.units.filter(u => !u.down && u.pos).forEach(u => {
    if(!chance(0.45)) return;
    const late = chance(0.5);
    SIM.phase = late ? "enemy" : "turn";
    if(chance(0.75)){
      const nm = pick(["Poisoned", "Burning", "Bleed", "Slowed", "Weakened", "Stunned", "Rooted", "Exposed"]), n = pick([null, 1, 2, 3]), turns = pick([null, 1, 1, 2]);
      R.addStatus(u, nm, n, null, turns);
      had.push([u.id, "status", nm, n, turns, late]);
    }else{
      const mod = { stat: pick(["AC", "MS", "DMG", "AP"]), amt: pick([-2, -1, 1, 2, 3]), dur: "turns", n: pick([1, 1, 2]), source: "test" };
      if(late) mod.late = true;
      u.mods = u.mods || []; u.mods.push(mod);
      had.push([u.id, "mod", clone(mod)]);
    }
  });
  SIM.phase = "turn";
  let over = sb.simOutcome();
  if(!over.over){
    SIM.phase = "enemy";
    lateTick();
    over = sb.simOutcome();
    const queue = st.units.filter(u => u.side === "enemy" && !u.down).map(u => u.id);
    for(const id of (over.over ? [] : queue)){
      const e = unit(st, id);
      if(!e || e.down) continue;
      sb.simOneEnemy(e, function(){});
      over = sb.simOutcome();
      if(over.over) break;
    }
    if(!over.over){
      sb.simEndOfRound();
      SIM.phase = "recharge";
      sb.simRunPhase("recharge");
      over = sb.simOutcome();
    }
  }
  if(had.some(h => h[h.length - 1] === true || (h[1] === "mod" && h[2].late))) late.given++;
  add("enemyPhase", [fi, sd2, holds, had], Object.assign(told(), { outcome: over }), st.units);
}

/* ---- cards as a Deck and a hand hold them, and what they cost ---- */
cards.forEach(c => { const h = sb.simHandCardOf(c); add("handCard", [c.name], h); add("costLabel", [c.name], sb.simCostLabel(h)); });
/* variable costs (13.4): what a card costs at an X, how it reads, and the least it can cost */
cards.forEach(c => { const h = sb.simHandCardOf(c);
  add("cardCost", [c.name], { variable: sb.simCardVar(h), one: sb.simCardCost(h, 1), three: sb.simCardCost(h, 3), asIs: sb.simCardCost(h), label: sb.simCostLabel(h), at2: sb.simCostLabel(h, 2), least: sb.aetherCostLeast(c) }); });
[{ name: "Old", cardType: "command", hasVariableCost: true, aetherCost: { generic: 0, affinity: 1, affinity2: 0 }, affinities: [{ district: "3" }], entries: [] },
 { name: "Old2", cardType: "command", hasVariableCost: true, aetherCost: { generic: 2, affinity: 0, affinity2: 0 }, affinities: [{ district: "2" }], entries: [] },
 { name: "Old3", cardType: "command", hasVariableCost: true, aetherCost: { generic: 2, affinity: 1, affinity2: 0 }, affinities: [], entries: [] },
 { name: "Mine", cardType: "troop", aetherCost: { generic: 0, affinity: 1 }, _raw: { aeGen: "xx", aeAff: "1", stats: { hp: "3(X)", ac: "9" } }, affinities: [{ district: "2" }], entries: [] },
 { name: "Mine2", cardType: "aether", aetherCost: { generic: 1, affinity: 0 }, _raw: { aeGen: "1", aeAff: " XXX " }, affinities: [{ district: "6" }], entries: [] },
 { name: "Second", cardType: "command", hasVariableCost: true, aetherCost: { generic: 0, affinity: 0, affinity2: "X" }, affinities: [{ district: "1" }, { district: "2" }], entries: [] },
 { name: "None", cardType: "command", affinities: [], entries: [] }].forEach(c => {
  const h = sb.simHandCardOf(c);
  add("costOf", [c], { cost: h.cost, variable: sb.simCardVar(h), one: sb.simCardCost(h, 1), four: sb.simCardCost(h, 4), label: sb.simCostLabel(h), at3: sb.simCostLabel(h, 3), least: sb.aetherCostLeast(c), spec: sb.simUnitSpec(c, "ally") }); });
/* a Unit from a variable-cost card, at each X: its stats, and its text with X in place */
cards.filter(c => /^(troop|hero|enemy)$/.test(c.cardType)).forEach(c => { [null, 1, 3].forEach(x => {
  const spec = sb.simUnitSpec(c, "ally"); if(x !== null) spec.x = x;
  const u = sb.simXFill(R.unitFromCard(spec, "ally")); u.id = "u";
  add("unitX", [c.name, x], u); }); });
[["5(X)", 3], [" 4 ( x ) ", 2], ["7", 5], ["5(X)", null], ["X", 4], ["(X)", 2], ["2(XX)", 2], [12, 3], ["0(X)", 3]].forEach(pair => {
  const spec = { name: "S", cardType: "troop", stats: { hp: pair[0], nrg: pair[0], ac: pair[0], int: pair[0], move: pair[0] } }; if(pair[1] !== null) spec.x = pair[1];
  const u = R.unitFromCard(spec, "ally"); u.id = "u";
  add("statX", [pair[0], pair[1]], u); });
[{}, { generic: 2 }, { d3: 1, generic: 0 }, { d3: 2, d1: 1, generic: 3 }, { d10: 1, d2: 4 }, { generic: 0, d6: 0 }].forEach(p => add("aetherLabel", [p], sb.simAetherLabel(p)));

/* ---- what a card needs settled before it is played: a target, an area, a Troop's card to Recover ---- */
const hasRecover = (t) => K.parse(String(t || "")).some(p => p.type === "kw" && p.kw && p.kw.name === "Recover");
cards.forEach(c => { const h = sb.simHandCardOf(c); const need = sb.simCardNeeds(h);
  add("cardNeeds", [c.name], { need: need || "", radius: h._aimRadius || 0, narrow: h._aimNarrow || [], recover: hasRecover(sb.simCardText(h)) }); });
["[[Recover]] a Troop.", "[[target ally]] gains [[heal 2]]. [[Recover]].", "[[target tile]]: [[all units within 2]] take [[damage 1]]. [[AoE 3]].",
 "[[target enemy]] [[Sniper]] [[District 3]] takes [[damage 2]].", "[[all allies within 3]] [[heal 1]]. [[target enemy]] takes [[damage 1]]. [[target ally]] [[Melee]] [[heal 1]].", "Plain words.", ""].forEach(t => {
  const h = { name: "x", effects: [{ text: t }] }; const need = sb.simCardNeeds(h);
  add("textNeeds", [t], { need: need || "", radius: h._aimRadius || 0, narrow: h._aimNarrow || [], recover: hasRecover(t) }); });

/* ---- a Strike Team's fight, from the setup wizard's last step through rounds
   of waves, Aether, Chips and cards. Before a round, some Units may be brought
   down (the board cleared, a Hero lost), so that waves come early and the
   draw shrinks. ---- */
const ref = (c) => (c._src || "master") + "|" + c.name;
const ofType = (t) => cards.filter(c => c.cardType === t);
const heroCards = ofType("hero"), deckable = cards.filter(c => /^(troop|equipment|command|aether)$/.test(c.cardType));
const chipKeys = [1, 2, 3, 4, 5, 6].map(d => "basic|" + d).concat(ofType("sphere").map(ref));
const spawnCount = (f, word) => (f.hexes || []).filter(p => new RegExp(word + "\\s*spawn", "i").test(String((f.colorLabels || {})[(p[1] || {}).c] || ""))).length;
/* a Unit's own card, and the Equipment cards on it, are told by name */
const byName = (u) => { if(u.card) u.card = u.card.name; if(u.equipCards) u.equipCards = u.equipCards.map(c => c.name); return u; };
function teamSnapshot(){
  /* a fight that is over settles its loot, once: what dropped, and, won, the floor's own reward */
  const done = sb.simOutcome();
  if(done.over && SIM.deploy){ if(!SIM.deployResult) sb.simDeployFinish({ over: true, winner: done.winner }); }
  else if(done.over && !SIM.lootResult) sb.simSettleLoot(done.winner === "ally");
  const sp = SIM.lootResult, dr = SIM._depRes;
  return { loot: lootOf(), found: (SIM.found || []).slice(), spoils: sp ? { won: !!sp.won, haul: sp.haul, reward: sp.reward, total: sp.total, items: sp.items || [] } : null,
    dep: dr ? clone({ winner: dr.winner, haul: dr.haul, reward: dr.reward, items: dr.items, heroesDown: dr.heroesDown, troopsLost: dr.troopsLost, kills: dr.kills, consUsed: dr.consUsed }) : null,
    log: SIM.log.filter(l => !l.loot).map(l => l.text), floats: clone(SIM.floats), halted: SIM.log.filter(l => l.halt).map(l => l.text), units: clone(SIM.units).map(byName),
    discard: SIM.discard.map(c => c.name + "|" + c.type), cons: (SIM.cons || []).map(c => [c.name, !!c.used]),
    aether: clone(SIM.aether), bank: SIM.bank.map(c => [c.name, c.value, c.district || null, !!c.spent]), pouch: SIM.pouch.map(c => c.name),
    hand: SIM.hand.map(c => c.name), deck: SIM.deck.map(c => c.name), pile: SIM.enemyPile.map(c => c.name + "|" + c.level),
    wave: SIM.wave, waveTurn: SIM.waveTurn, round: SIM.round, leader: SIM.leader, protos: clone(SIM.protos), level: SIM.playerLevel, outcome: sb.simOutcome() };
}
/* the Enemies take their turn and the round turns over, unless the fight is done */
function turnOver(){
  let over = sb.simOutcome();
  if(over.over) return;
  /* Handbook 15.9: your turn ends, and what arrived in the Enemies' half ticks */
  SIM.phase = "enemy";
  lateTick();
  over = sb.simOutcome();
  if(over.over) return;
  const queue = SIM.units.filter(u => u.side === "enemy" && !u.down).map(u => u.id);
  for(const id of queue){
    const e = SIM.units.filter(u => u.id === id)[0];
    if(!e || e.down) continue;
    sb.simOneEnemy(e, function(){});
    over = sb.simOutcome();
    if(over.over) return;
  }
  sb.simEndOfRound();
  SIM.round++;
  ["waves", "gen", "chips", "draw", "recharge", "turn"].forEach(k => { SIM.phase = k; sb.simRunPhase(k); });
}
for(let i = 0; i < 220; i++){
  const f = floors[i % floors.length], room = spawnCount(f, "player");
  if(room < 1) continue;
  const nh = Math.min(room, ri(1, 3)), hs = [];
  while(hs.length < nh){ const h = pick(heroCards); if(hs.indexOf(h) < 0) hs.push(h); }
  const deck = [];
  for(let k = ri(0, 26); k > 0; k--) deck.push(pick(deckable));
  const troopsIn = deck.filter(c => c.cardType === "troop"), starters = [];
  for(let k = Math.min(room - nh, ri(0, 3)); k > 0 && troopsIn.length; k--) starters.push(pick(troopsIn).name);
  if(chance(0.1)) starters.push("Nobody Home");
  const actions = {};
  hs.forEach(h => { if(chance(0.5)){ actions[ref(h)] = []; for(let k = ri(1, 2); k > 0; k--) actions[ref(h)].push(ref(pick(ofType("action")))); } });
  const pouch = [];
  for(let k = ri(0, 5); k > 0; k--){ const key = pick(chipKeys); if(!pouch.some(p => p[0] === key)) pouch.push([key, ri(0, 4)]); }
  if(chance(0.1)) pouch.push(["master|No Such Chip", 2]);
  const protos = [];
  for(let k = ri(0, 2); k > 0; k--){ const pc = pick(ofType("prototype")).name; if(protos.indexOf(pc) < 0) protos.push(pc); }
  if(chance(0.1)) protos.push("No Such Prototype");
  const leader = chance(0.5) ? ref(pick(hs)) : null;
  const setup = { floor: f.name, heroes: hs.map(c => c.name), leader: leader ? leader.split("|").slice(1).join("|") : null,
    actions: {}, startTroops: starters, deck: deck.map(c => c.name), pouch, level: pick([1, 1, 2, 3, 4, 6, "2", 9, null]), protos, waveTimer: pick([3, 3, 1, 2, 5]),
    /* Dimensional Instability (13.4): the chance, and now and then a District with no Elite or Mini-Boss to send, or none at all */
    instability: pick([0, 0, 0, 9, 15, 40, 100]) };
  if(chance(0.2)) setup.district = pick(["5", "1", ""]);
  /* game 0.8: what is owned already, and now and then a deployment's fight (the tile's Skull Level sets the Enemies) */
  if(chance(0.6)) setup.prog = someProg();
  if(chance(0.35)) setup.deploy = someDeploy();
  Object.keys(actions).forEach(k => { setup.actions[k.split("|").slice(1).join("|")] = actions[k].map(r => r.split("|").slice(1).join("|")); });
  /* some fights are swept: the board cleared every round, so all six waves come and the fight is won */
  const sd = ri(1, 1e6), sweep = chance(0.15), rounds = sweep ? 7 : ri(1, 5), script = [];
  for(let k = 0; k < rounds; k++) script.push({ clear: sweep || chance(0.3), loseHero: !sweep && chance(0.12), loseAll: !sweep && chance(0.03) });

  /* the wizard's last step, exactly as the Companion runs it */
  load({ map: Object.assign(mapOf(f), setup.district !== undefined ? { district: setup.district } : {}), units: [] }, sd);
  dress(setup);
  SIM.wave = 0; SIM.countIds = true; SIM.idCount = {}; SIM.round = 1;
  sb.LOADOUT_IN = { level: setup.level, deck: deck.map(ref) };
  sb.WIZ_IN = { loadout: 0, heroes: hs.map(ref), actions, leader, startTroops: starters.slice(), waveTimer: setup.waveTimer, instability: setup.instability,
    pouch: pouch.reduce((o, p) => { o[p[0]] = p[1]; return o; }, {}), enemyMode: "auto", foes: {}, protos: protos.slice(), cons: {} };
  vm.runInContext("LOADOUT = window.LOADOUT_IN; SIM_WIZ = window.WIZ_IN;", sb);
  sb.simWizFinish();
  SIM.autoRunning = true;
  const shots = [teamSnapshot()];
  script.forEach(step => {
    const felled = [];
    const fell = (u) => { u.hp = 0; felled.push(u.id); };
    if(step.clear) SIM.units.filter(u => u.side === "enemy" && !u.down).forEach(fell);
    if(step.loseHero){ const up = SIM.units.filter(u => u.side === "ally" && !u.down && /hero/i.test(u.cardType || "")); if(up.length) fell(pick(up)); }
    if(step.loseAll) SIM.units.filter(u => u.side === "ally" && !u.down).forEach(fell);
    step.felled = felled; delete step.clear; delete step.loseHero; delete step.loseAll;
    if(felled.length) sb.simCheckDowns();
    turnOver();
    shots.push(teamSnapshot());
  });
  SIM.countIds = false;
  add("teamFight", [setup, sd, script], shots);
}

/* ---- a Strike Team's fight with its cards played: Troops onto spawn tiles,
   Equipment onto Units, Commands and Aether cards at whoever or wherever they
   need, Consumables, Chips spent for their effects, a carried Action paid
   for in Aether; Units brought down so their cards reach the Discard Pile;
   rounds turning over between. After each step everything is recorded. ---- */
const consCards = ofType("consumable"), keyworded = (c) => (c.entries || c.abilities || []).some(a => /\[\[/.test(String(a.text || "")));
const playable = deckable.filter(keyworded), unitById = (id) => SIM.units.filter(u => u.id === id)[0];
/* whatever was asked for is answered: which Troop's card, then who, or where */
function settle(op, key){
  if(sb._simX){ const w = sb._simX; sb._simX = null; const x = ri(1, w.max); op.x = x; w.then(x); }
  if(sb._simRecover){ const w = sb._simRecover; sb._simRecover = null; const c = pick(w.pool); op.recover = SIM.discard.indexOf(c); w.then(c); }
  if(SIM.pick){ const pk = SIM.pick; SIM.pick = null; const ids = Object.keys(pk.valid).map(k => pk.valid[k]); const id = pick(ids); op[key] = id; pk.done(unitById(id)); }
  else if(SIM.aim){ const t = R.hexParse(pick(Object.keys(SIM.map.hexes))); SIM.aim.at = { q: t.q, r: t.r }; op.tile = [t.q, t.r]; sb.simConfirmAim(); }
}
const quiet = () => { sb._simRecover = null; sb._simAimRun = null; sb._simX = null; SIM.pick = null; SIM.aim = null; };
/* What the simulator says to the Player as a card is chosen ("Tap a lit Unit
   for...", "...needs an Enemy to target, and there is none") is its ticker's
   business, not the fight's: the game says the same on its own screen. While
   a card, a Consumable or a Chip is being played here, those lines are left
   out of the log; what the play does is all still there. */
vm.runInContext("var simSayAloud=simSay; simSay=function(t){ if(SIM.hush) return; simSayAloud(t); };", sb);
const hushed = (fn) => { SIM.hush = true; try { fn(); } finally { SIM.hush = false; } };
for(let i = 0; i < 300; i++){
  const f = floors[i % floors.length], room = spawnCount(f, "player");
  if(room < 1) continue;
  const nh = Math.min(room, ri(1, 3)), hs = [];
  while(hs.length < nh){ const h = pick(heroCards); if(hs.indexOf(h) < 0) hs.push(h); }
  /* mostly cards the simulator can carry out, some it can't */
  const deck = [];
  for(let k = ri(12, 30); k > 0; k--) deck.push(chance(0.75) ? pick(playable) : pick(deckable));
  /* so that a card aimed at a tile, and cards with a variable cost, are played often enough to mean something */
  ["Test Mortar Strike", "Test Barrage", "Test Swarm", "Test Capacitor", "Test Drone Bank"].forEach(n => { const c = cards.filter(x => x.name === n)[0]; if(c && chance(0.45)) deck.push(c); });
  const troopsIn = deck.filter(c => c.cardType === "troop"), starters = [];
  for(let k = Math.min(room - nh, ri(0, 2)); k > 0 && troopsIn.length; k--) starters.push(pick(troopsIn).name);
  const actions = {};
  hs.forEach(h => { if(chance(0.7)){ actions[ref(h)] = []; for(let k = ri(1, 2); k > 0; k--) actions[ref(h)].push(ref(pick(ofType("action")))); } });
  /* a carried Action card with a variable cost, often enough to be used */
  const overcharge = cards.filter(x => x.name === "Test Overcharge")[0];
  if(overcharge && chance(0.45)){ const h = ref(pick(hs)); actions[h] = actions[h] || []; if(actions[h].indexOf(ref(overcharge)) < 0) actions[h].push(ref(overcharge)); }
  const pouch = [];
  for(let k = ri(1, 5); k > 0; k--){ const key = pick(chipKeys); if(!pouch.some(p => p[0] === key)) pouch.push([key, ri(1, 4)]); }
  const cons = {};
  for(let k = ri(0, 4); k > 0; k--) cons[pick(consCards).name] = ri(1, 2);
  if(chance(0.7)) cons["Test Repair Kit"] = ri(1, 3);
  const protos = [];
  if(chance(0.4)) protos.push(pick(ofType("prototype")).name);
  const leader = chance(0.5) ? ref(pick(hs)) : null;
  const setup = { floor: f.name, heroes: hs.map(c => c.name), leader: leader ? leader.split("|").slice(1).join("|") : null,
    actions: {}, startTroops: starters, deck: deck.map(c => c.name), pouch, level: pick([1, 2, 3, 4]), protos, waveTimer: pick([3, 2, 5]),
    cons: Object.keys(cons).map(k => [k, cons[k]]), instability: pick([0, 0, 15, 60]) };
  if(chance(0.15)) setup.district = pick(["5", ""]);
  if(chance(0.5)) setup.prog = someProg();
  if(chance(0.3)) setup.deploy = someDeploy();
  Object.keys(actions).forEach(k => { setup.actions[k.split("|").slice(1).join("|")] = actions[k].map(r => r.split("|").slice(1).join("|")); });
  const sd = ri(1, 1e6);
  load({ map: Object.assign(mapOf(f), setup.district !== undefined ? { district: setup.district } : {}), units: [] }, sd);
  dress(setup);
  SIM.wave = 0; SIM.countIds = true; SIM.idCount = {}; SIM.round = 1; SIM.cons = [];
  sb.LOADOUT_IN = { level: setup.level, deck: deck.map(ref) };
  sb.WIZ_IN = { loadout: 0, heroes: hs.map(ref), actions, leader, startTroops: starters.slice(), waveTimer: setup.waveTimer, instability: setup.instability,
    pouch: pouch.reduce((o, p) => { o[p[0]] = p[1]; return o; }, {}), enemyMode: "auto", foes: {}, protos: protos.slice(), cons };
  vm.runInContext("LOADOUT = window.LOADOUT_IN; SIM_WIZ = window.WIZ_IN;", sb);
  sb.simWizFinish();
  SIM.autoRunning = true;
  const shots = [teamSnapshot()], script = [];
  let autoed = false;   /* after Auto, the game's Units have had their turn: nobody walks again until the round turns */
  for(let k = ri(5, 14); k > 0 && !sb.simOutcome().over; k--){
    quiet();
    const roll = rnd();
    let op = null;
    const walkers = autoed ? [] : SIM.units.filter(u => u.side === "ally" && !u.down && u.pos && !u.moved);
    if(walkers.length && chance(lootSpots().length ? 0.3 : 0.08)){
      /* one of yours walks. On a floor with Loot Tiles or Locked Chests it is set down beside one first, more often than not, and walks onto it */
      const me = pick(walkers), free = (h) => !!SIM.map.hexes[R.hexKey(h.q, h.r)] && !sb.simUnitAt(h.q, h.r);
      const spots = lootSpots().map(k2 => R.hexParse(k2)).filter(free);
      if(spots.length && chance(0.7)){
        const sp = pick(spots), beside = R.hexNeighbours(sp.q, sp.r).filter(free);
        if(beside.length){ const h = pick(beside); me.pos = { q: h.q, r: h.r }; script.push({ op: "place", unit: me.id, q: h.q, r: h.r }); shots.push(teamSnapshot()); }
      }
      /* (0.21) as far as it may move: a Dash on top, and Leap's jumps among the tiles */
      const tiles = sb.simReach(me, sb.simMoveLeft(me));
      if(tiles.length){
        const want = tiles.filter(t => spots.some(h => h.q === t.q && h.r === t.r));
        const t = (want.length && chance(0.8)) ? pick(want) : pick(tiles);
        SIM.reach = tiles;
        sb.simMoveTo(me, t.q, t.r);
        op = { op: "move", unit: me.id, q: t.q, r: t.r };
      }
    }else if(roll < 0.14){
      /* the Bank is filled, or emptied, so that paying is tried both ways */
      op = { op: "aether", pool: pick([{ generic: 12, d3: 12 }, { generic: 30, d1: 9, d2: 9, d3: 9, d4: 9, d5: 9, d6: 9 }, {}, { generic: 1 }, { d3: 2 }, { generic: 3, d3: 1 }]) };
      SIM.aether = clone(op.pool);
    }else if(roll < 0.52 && SIM.hand.length){
      /* a card aimed at a tile, or one with a variable cost, is reached for first now and then */
      const keen = SIM.hand.map((c, n) => n).filter(n => /^Test (Mortar Strike|Barrage|Swarm|Capacitor|Drone Bank)$/.test(SIM.hand[n].name));
      const idx = (keen.length && chance(0.35)) ? pick(keen) : ri(0, SIM.hand.length - 1), card = SIM.hand[idx], had = SIM.hand.length, n0 = SIM.units.length;
      const allies = SIM.units.filter(u => u.side === "ally" && !u.down);
      op = { op: "hand", i: idx, name: card.name, type: card.type === "troop" ? "troop" : card.type === "equipment" ? "equipment" : "plain" };
      hushed(() => { sb.simPlayCard(idx); settle(op, card.type === "equipment" ? "unit" : "target"); });
      /* (0.23) refused is still in the hand: a card that Recovers or Draws (or a Troop whose arrival Draws) leaves the hand as long as it was, or longer */
      op.refused = SIM.hand.indexOf(card) >= 0;
      if(!op.refused && card.type === "equipment" && op.unit === undefined && allies.length === 1) op.unit = allies[0].id;
      if(!op.refused && card.type === "troop"){ const u = SIM.units[n0]; op.tile = [u.pos.q, u.pos.r]; }
    }else if(roll < 0.64 && (SIM.cons || []).length){
      /* with a Troop's card in the Discard Pile, a Repair Kit is reached for more often than not */
      const kits = SIM.cons.map((c, n) => n).filter(n => !SIM.cons[n].used && hasRecover(SIM.cons[n].text));
      const idx = (kits.length && sb.simRecoverable().length && chance(0.7)) ? pick(kits) : ri(0, SIM.cons.length - 1), was = SIM.cons[idx].used;
      op = { op: "cons", i: idx, name: SIM.cons[idx].name };
      hushed(() => { sb.simUseConsumable(idx); settle(op, "target"); });
      op.refused = SIM.cons[idx].used === was;
    }else if(roll < 0.72 && SIM.bank.some(c => (c.text || "").trim())){
      const withText = SIM.bank.map((c, n) => n).filter(n => (SIM.bank[n].text || "").trim()), idx = pick(withText), was = SIM.bank[idx].spent;
      op = { op: "chip", i: idx, name: SIM.bank[idx].name };
      hushed(() => { sb.simSpendChip(idx); settle(op, "target"); });
      op.refused = SIM.bank[idx].spent === was;
    }else if(roll < 0.82){
      /* someone goes down: an Enemy, or one of yours (a Troop's card then reaches the Discard Pile) */
      const up = SIM.units.filter(u => !u.down && u.pos && !(u.side === "ally" && /hero/i.test(u.cardType || "") && chance(0.8)));
      const mine = up.filter(x => x.side === "ally");
      if(up.length){ const u = (mine.length && chance(0.6)) ? pick(mine) : pick(up); u.hp = 0; op = { op: "fell", ids: [u.id] }; sb.simCheckDowns(); }
    }else if(roll < 0.91){
      /* a Hero uses an Action: one it carries, if it has one, which may cost Aether */
      const heroesUp = SIM.units.filter(u => u.side === "ally" && !u.down && u.pos && /hero/i.test(u.cardType || ""));
      if(heroesUp.length){
        const u = pick(heroesUp), acts = (u.actions || []).filter(a => a.tag !== "Passive" && a.tag !== "Aura" && sb.simBurstOf(a) <= 1);
        const paid = acts.filter(a => a.aether), vary = acts.filter(a => a.aetherX);
        const a = (vary.length && chance(0.6)) ? pick(vary) : (paid.length && chance(0.8) ? pick(paid) : pick(acts));
        /* now and then the Bank is topped up first, so a carried Action card can be paid for at more than X = 1 */
        if(a && a.aetherX && chance(0.6)){ SIM.aether = { generic: 4, d3: ri(1, 6) }; script.push({ op: "aether", pool: clone(SIM.aether) }); shots.push(teamSnapshot()); }
        /* and an Enemy is set down close by, so there is something in reach to use it on */
        if(a && chance(0.5)){
          const foe = SIM.units.filter(t => t.side === "enemy" && !t.down && t.pos), near = Object.keys(SIM.map.hexes).map(k => R.hexParse(k))
            .filter(h => { const d = R.hexDistance(u.pos, h); return d >= 1 && d <= 2 && !sb.simUnitAt(h.q, h.r); });
          if(foe.length && near.length){ const e = pick(foe), h = pick(near); e.pos = { q: h.q, r: h.r }; script.push({ op: "place", unit: e.id, q: h.q, r: h.r }); shots.push(teamSnapshot()); }
        }
        if(a){
          const state = sb.simActionState(u, a);
          /* (0.21) which of its Actions, where two carry one name (a Hero assigned the same Action card twice) */
          op = { op: "act", unit: u.id, action: a.name, index: u.actions.indexOf(a), state };
          if(state.ok && sb.simSelfOnly(a)){
            /* (0.22) on itself, at once */
            op.self = true; SIM.pendingAct = null; SIM.burst = null;
            if(a.aetherX){ op.x = ri(1, Math.max(1, sb.simMaxX({ cost: a.aetherX, district: a.aether.district }))); sb.simActionSetX(a, op.x); }
            sb.simUseOnSelf(u, a);
          }else if(state.ok){
            const role = String(a.role || "").toLowerCase();
            const pool = SIM.units.filter(t => !t.down && t.pos && (role === "support" ? (t.side === u.side && t !== u) : t.side !== u.side) && sb.simCanReach(u, a, t));
            if(pool.length){ const t = pick(pool); op.target = t.id; SIM.pendingAct = null; SIM.burst = null;
              /* a carried Action card with a variable cost is used for an X the Bank can pay */
              if(a.aetherX){ op.x = ri(1, Math.max(1, sb.simMaxX({ cost: a.aetherX, district: a.aether.district }))); sb.simActionSetX(a, op.x); }
              sb.simConfirmAttack(u, t, a); }
          }
        }
      }
    }else if(roll < 0.95){
      /* Auto: your Units take their turns by themselves; a carried Action card pays its Aether, or isn't used */
      /* now and then one of them is stood on a Loot Tile or a Locked Chest first and told to hold its tile: Auto finds what is there */
      const open = lootSpots().map(k2 => R.hexParse(k2)).filter(h => !sb.simUnitAt(h.q, h.r)), mine = SIM.units.filter(u => u.side === "ally" && !u.down && u.pos);
      let stood = null;
      if(open.length && mine.length && chance(0.6)){
        const h = pick(open); stood = pick(mine);
        stood.pos = { q: h.q, r: h.r }; script.push({ op: "place", unit: stood.id, q: h.q, r: h.r }); shots.push(teamSnapshot());
      }
      const given = [];
      SIM.units.filter(u => u.side === "ally" && !u.down && u.pos).forEach(u => {
        if(u === stood){ u.behaviors = [{ k: "steadfast" }]; given.push([u.id, clone(u.behaviors)]); return; }
        if(chance(0.6)){ const bs = []; for(let n = ri(1, 2); n > 0; n--){ const d = pick(allyBeh); if(!bs.some(b => b.k === d.k)) bs.push(d.param ? { k: d.k, x: d.pdef } : { k: d.k }); }
          u.behaviors = bs; given.push([u.id, clone(bs)]); } });
      op = { op: "auto", beh: given };
      sb.simAutoAllies(function(){});
      autoed = true;
    }else if(roll < 0.97){
      /* not your turn: nothing can be played, used or spent */
      const was = SIM.phase; SIM.phase = "draw";
      op = { op: "wrongturn", hand: SIM.hand.length ? ri(0, SIM.hand.length - 1) : -1, cons: (SIM.cons || []).length ? ri(0, SIM.cons.length - 1) : -1 };
      hushed(() => { if(op.hand >= 0) sb.simPlayCard(op.hand); if(op.cons >= 0) sb.simUseConsumable(op.cons); });
      quiet(); SIM.phase = was;
    }else{
      op = { op: "round" };
      turnOver();
      autoed = false;
    }
    if(!op) continue;
    script.push(op);
    shots.push(teamSnapshot());
  }
  SIM.countIds = false; quiet();
  add("teamPlay", [setup, sd, script], shots);
}

/* ---- the Deck Builder's checks, on Strike Teams of every shape ---- */
for(let i = 0; i < 400; i++){
  const hs = [], deck = [], actions = {}, pouch = [];
  for(let k = pick([0, 1, 1, 2, 2, 3, 3, 4]); k > 0; k--){ const h = pick(heroCards); if(hs.indexOf(h) < 0) hs.push(h); }
  for(let k = pick([0, 3, 9, 10, 14, 25, 40, 60, 61, 70]); k > 0; k--) deck.push(chance(0.04) ? pick(ofType("action")) : pick(deckable));
  hs.forEach(h => { if(chance(0.6)){ actions[ref(h)] = []; for(let k = ri(0, 4); k > 0; k--) actions[ref(h)].push(ref(pick(ofType("action")))); } });
  for(let k = ri(0, 6); k > 0; k--){ const key = pick(chipKeys); if(!pouch.some(p => p[0] === key)) pouch.push([key, pick([0, 1, 1, 2, 3, 6])]); }
  const lo = { name: "Team " + i, level: ri(1, 6), heroes: hs.map(ref), deck: deck.map(ref), actions, pouch: pouch.reduce((o, p) => { o[p[0]] = p[1]; return o; }, {}) };
  if(chance(0.08)) lo.heroes.push("master|Nobody");
  if(chance(0.08)) lo.deck.push("master|No Such Card");
  const names = (r) => r.split("|").slice(1).join("|");
  const team = { name: lo.name, level: lo.level, heroes: lo.heroes.map(names), deck: lo.deck.map(names), actions: {}, pouch };
  Object.keys(actions).forEach(k => { team.actions[names(k)] = actions[k].map(names); });
  add("teamPings", [team], sb.pingsForLoadout(lo));
}

/* ---- loot (for game 0.7): loot.js itself, run as it is, seed for seed ---- */
const lb = { Math, JSON, parseInt, parseFloat, isFinite, isNaN, String, Array, Object, Date, Number };
lb.window = lb; vm.createContext(lb); vm.runInContext(fs.readFileSync(path.join(ROOT, "loot.js"), "utf8"), lb);
const L = lb.KETER_LOOT;
/* the tables as shipped, and two sets changed the way the Loot page lets you change them */
const T0 = clone(L.tables()), T1 = clone(T0), T2 = clone(T0);
T1.weights = [[10, 5, 0, 0, 0, 1], [0, 0, 0, 0, 0, 0], [1, 1, 1, 1, 1, 1], [0, 50, 0, 50, 0, 0], [5, 0, 0, 0, 0, 95], [0, 0, 0, 0, 0, 7]];
T1.spread = 100; T1.sources.enemy.max = 4; T1.sources.enemy.bonus = 2; T1.sources.boss.top = 2; T1.sources.lootTile.shards = 0; T1.sources.elite.min = 3; T1.sources.elite.max = 1;
T1.names.troop[0] = "Bent rods"; T1.names.aether[5] = "Rift pearl";
T2.spread = 0; T2.sources.miniboss.shards = 1.5; T2.sources.chest.shards = 0.4;
const lootTables = [T0, T1, T2];
lootTables.forEach((t, ti) => {
  for(let i = 0; i < 300; i++){
    const sd = ri(1, 2e9), o = { source: pick(["enemy", "enemy", "elite", "miniboss", "boss", "lootTile", "chest", "nonsense", undefined]) };
    if(chance(0.8)) o.skull = pick([0, 1, 2, 3, 4, 5, 6, 7, "3", null]);
    if(chance(0.7)) o.poiSkull = pick([1, 2, 3, 4, 5, 6, 9, 0]);
    if(chance(0.6)) o.salvage = pick(["mixed", "troop", "equipment", "aether", "Troop", "", null]);
    if(o.source === "chest" && chance(0.7)) o.x = pick([0, 1, 2, 5, "4", -2]);
    L.seed(sd);
    const n = ri(1, 4), bags = [];
    for(let k = 0; k < n; k++) bags.push(L.roll(o, t));
    add("lootRoll", [ti, sd, o, n], bags);
  }
  for(let i = 0; i < 80; i++){
    const sd = ri(1, 2e9), rw = { shards: pick([0, 5, 20, "12", null, 3.7, -4]), lines: [] };
    for(let k = ri(0, 4); k > 0; k--){
      const kind = pick(["exact", "roll", "roll", "item"]);
      rw.lines.push(kind === "exact" ? { kind, n: pick([0, 1, 3, "2", 120]), type: pick(["troop", "equipment", "aether", "nonsense"]), rarity: pick([0, 1, 3, 5, 9, "2", -1]) }
        : kind === "roll" ? { kind, n: pick([0, 1, 2, 5]), type: pick(["any", "troop", "equipment", "aether"]), bonus: pick([0, 0, 1, 3, "2", undefined]) }
        : { kind, item: "bp:Test", chance: 50 });
    }
    const poi = pick([1, 2, 3, 4, 5, 6, 0, 8, "4"]);
    L.seed(sd);
    const bag = L.rollReward(rw, poi, t);
    /* in words, without its blueprints and chassis: those wait for the Workshop, and the game leaves them out */
    add("lootReward", [ti, sd, rw, poi], { bag, said: L.rewardText(Object.assign({}, rw, { lines: rw.lines.filter(l => l.kind !== "item") }), t) });
    add("lootText", [ti, bag], { text: L.text(bag, t), lines: L.lines(bag, t).map(l => ({ type: l.type, rarity: l.rarity, n: l.n, name: l.name, rarityLabel: l.rarityLabel })), empty: L.isEmpty(bag), count: L.count(bag) });
  }
});
[null, {}, { shards: "7", parts: { troop: [1, "2", -3, 4.9] } }, { shards: 0, parts: { aether: [0, 0, 0, 0, 0, 2], equipment: [1] } }].forEach(b => {
  add("lootText", [0, b], { text: L.text(b, T0), lines: L.lines(b, T0).map(l => ({ type: l.type, rarity: l.rarity, n: l.n, name: l.name, rarityLabel: l.rarityLabel })), empty: L.isEmpty(b), count: L.count(b) });
  add("lootAdd", [b, { shards: 2, parts: { troop: [1, 1, 1, 1, 1, 1] } }], L.add(b, { shards: 2, parts: { troop: [1, 1, 1, 1, 1, 1] } })); });
["enemy", "elite", "miniboss", "boss", "Elite", "MiniBoss", "troop", "", null].forEach(ct => add("lootSource", [ct], L.sourceFor(ct)));
/* a floor's Skull Level: the one set on it, or the highest of its Enemy Spawn Tiles */
floors.forEach(f => { [undefined, "", "4", 9, 2].forEach(lv => {
  add("lootPoiSkull", [f.name, lv === undefined ? null : lv, lv === undefined], L.poiSkull({ level: lv === undefined ? f.level : lv, colorLabels: f.colorLabels || {}, hexes: f.hexes || [] })); }); });

const out = path.join(ROOT, "game", "tests", "fixtures", "sim_cases.json");
fs.writeFileSync(out, JSON.stringify({ made: "shell.html Battle Simulator, " + TAKEN.length + " functions, keywords.js and loot.js", cards: cards.length, floors: floors.length, archetypes: K.archetypes(), lootTables, fights, cases }));
const counts = {}; cases.forEach(c => counts[c.fn] = (counts[c.fn] || 0) + 1);
const seen = { turnEndTicks: late.ticked, turnEndLines: late.lines, lateGiven: late.given }; cases.forEach(c => { if(c.fn === "playerAttack" || c.fn === "enemyPhase"){ const by = {}; (c.result.log || []).forEach(l => { const m = /^(.+?) used (.+?) on /.exec(l); if(m){ const k = m[1] + "|" + m[2]; by[k] = (by[k] || 0) + 1; } }); if(Object.keys(by).some(k => by[k] > 1)) seen.bursts = (seen.bursts || 0) + 1; } if(c.result && c.result.log) c.result.log.forEach(l => { [["Burst", /Burst/], ["AoE", /^AoE/], ["Chain", /^Chain/], ["Pierce", /^Pierce/], ["push", /pushed|hit .*: \d+ damage to/], ["deploys", / deploys /], ["status", / gains? .* for \d+ turn/], ["heals", / heals /], ["hazard", /(moves onto|backs onto|ends its turn on|arrives on|is pushed onto) /], ["reacts", / reacts with /], ["holds", / holds fire /], ["stats", /: [+-]\d+ (HP|AC|MS|DMG|INT|Range|AP|NRG) \(/], ["not met", /not met$/], ["sacrificed", /Sacrificed/], ["cleared", /cleared of|was not /], ["cover", /counts as behind/], ["plain", /^Not carried out/], ["stunned", /is Stunned and loses its turn$/]].forEach(p => { if(p[1].test(l)) seen[p[0]] = (seen[p[0]] || 0) + 1; }); }); if(c.result && c.result.halted && c.result.halted.length) seen.halted = (seen.halted || 0) + c.result.halted.length; });
/* what the played-card fights came to: each kind of step, and how many were refused */
const plays = {};
cases.forEach(c => { if(c.fn !== "teamPlay") return; c.args[2].forEach(op => { const k = op.op + (op.type ? ":" + op.type : "") + (op.refused ? " refused" : ""); plays[k] = (plays[k] || 0) + 1;
  if(op.recover !== undefined) plays["a Troop's card chosen to Recover"] = (plays["a Troop's card chosen to Recover"] || 0) + 1;
  if(op.tile && op.op !== "hand") plays["aimed at a tile"] = (plays["aimed at a tile"] || 0) + 1;
  if(op.op === "hand" && op.type === "plain" && op.tile) plays["a card aimed at a tile"] = (plays["a card aimed at a tile"] || 0) + 1;
  if(op.op === "act" && op.state && !op.state.ok && /Aether/.test(op.state.why || "")) plays["an Action the Bank couldn't pay for"] = (plays["an Action the Bank couldn't pay for"] || 0) + 1;
  if(op.op === "act" && op.target) plays["an Action used"] = (plays["an Action used"] || 0) + 1; });
  const last = c.result[c.result.length - 1]; if(last.discard.some(d => /\|troop$/.test(d))) plays["fights ending with a Troop's card in the Discard Pile"] = (plays["fights ending with a Troop's card in the Discard Pile"] || 0) + 1;
  if(c.result.some(sh => sh.log.some(l => /returns to your hand from the Discard Pile/.test(l)))) plays["fights with a Recover"] = (plays["fights with a Recover"] || 0) + 1;
  c.args[2].forEach(op => { if(op.x !== undefined){ const k = op.op === "act" ? "a carried Action used for X" : (op.refused ? "a card with X refused" : "a card played for X"); plays[k] = (plays[k] || 0) + 1; } }); });
/* Dimensional Instability, across both kinds of Strike Team fight */
cases.forEach(c => { if(c.fn !== "teamPlay" && c.fn !== "teamFight") return;
  const lines = {}; c.result.forEach(sh => sh.log.forEach(l => { lines[l] = 1; }));
  const all = c.result[c.result.length - 1].log;
  if(all.some(l => /^Dimensional instability: /.test(l))) plays["fights where Instability sent an Elite or a Mini-Boss"] = (plays["fights where Instability sent an Elite or a Mini-Boss"] || 0) + 1;
  if(all.some(l => /^Dimensional instability stirs, but /.test(l))) plays["fights where Instability had nothing to send"] = (plays["fights where Instability had nothing to send"] || 0) + 1; });
/* loot in fights (game 0.7): what dropped, what was found and how, and the floor rewards paid */
cases.forEach(c => { if(c.fn !== "teamFight" && c.fn !== "teamPlay") return; const shots2 = c.result, last = shots2[shots2.length - 1], lines = (last.loot || {}).lines || [];
  const bump = (k, n) => { if(n) plays[k] = (plays[k] || 0) + n; };
  bump("loot: an Enemy's drop", lines.filter(l => / drops: /.test(l)).length);
  bump("loot: a Loot Tile found", lines.filter(l => / finds: /.test(l)).length);
  bump("loot: a Locked Chest opened", lines.filter(l => / opens a Locked Chest: /.test(l)).length);
  bump("items: a blueprint left behind", lines.filter(l => / leaves a blueprint/.test(l)).length);
  bump("items: a chassis left behind", lines.filter(l => / leaves a chassis/.test(l)).length);
  bump("items: one whose name is known already", lines.filter(l => / leaves a (blueprint|chassis): /.test(l)).length);
  if(last.spoils && (last.spoils.items || []).length > (last.found || []).length) bump("items: from a floor's own reward", 1);
  if(c.args[0].deploy) bump("a deployment's fight", 1);
  if(last.dep){ bump("a deployment's fight settled: " + last.dep.winner, 1); if((last.dep.items || []).length) bump("a deployment's fight that found a blueprint or a chassis", 1); }
  if(last.spoils){ bump("loot: fights settled", 1); if(last.spoils.won && last.spoils.reward.shards > 0) bump("loot: a floor's reward paid", 1); if(!last.spoils.won) bump("loot: fights lost with a haul settled", 1); }
  if(c.fn === "teamPlay") c.args[2].forEach((op, n) => { if(op.op !== "auto" && op.op !== "move") return;
    if(shots2[n + 1].loot.looted.length > shots2[n].loot.looted.length) bump(op.op === "auto" ? "loot: found by a Unit on Auto" : "loot: found by a Unit that walked", 1); }); });
cases.forEach(c => { if(c.fn !== "autoTurn") return; const log = c.result.log || [];
  if(log.some(l => / \(Medic\)$/.test(l))) plays["Auto: a Medic tended someone"] = (plays["Auto: a Medic tended someone"] || 0) + 1;
  if(log.some(l => / holds back/.test(l))) plays["Auto: a Unit held back"] = (plays["Auto: a Unit held back"] || 0) + 1;
  if(log.some(l => / used .+ on .+ \(/.test(l) && !/\(Medic\)$/.test(l))) plays["Auto: an attack"] = (plays["Auto: an attack"] || 0) + 1;
  if(log.some(l => / cannot reach /.test(l))) plays["Auto: out of reach"] = (plays["Auto: out of reach"] || 0) + 1; });
console.log(JSON.stringify({ file: out, cases: cases.length, counts, seen, plays }));
