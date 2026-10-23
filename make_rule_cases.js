#!/usr/bin/env node
/* Generates the cases that prove the game's rules.gd is the Companion's rules.js.

   Runs rules.js (the frozen original) on thousands of generated inputs and
   writes each input with the answer it gave to game/tests/fixtures/rule_cases.json.
   The game's test (tests/rules_diff.gd) runs rules.gd on the same inputs and
   compares every answer, event and changed Unit.

     node make_rule_cases.js [cards.json from an export]

   Deterministic: the same rules.js and cards give the same cases. */
"use strict";
const fs = require("fs"), path = require("path"), vm = require("vm");
const ROOT = __dirname;

/* ---- rules.js as the Companion loads it, with the behaviour table ---- */
const buildPy = fs.readFileSync(path.join(ROOT, "build.py"), "utf8");
const behSrc = buildPy.match(/window\.KETER_BEHAVIORS=""" \+ r'''(\[[\s\S]*?\])'''/)[1];
const sandbox = { Math, JSON, String, Object, Array, parseInt, isNaN };
sandbox.window = sandbox;
vm.createContext(sandbox);
vm.runInContext("var KETER_BEHAVIORS=" + behSrc + ";", sandbox);
vm.runInContext(fs.readFileSync(path.join(ROOT, "rules.js"), "utf8"), sandbox);
const R = sandbox.KETER_RULES;

/* ---- a seeded generator for the cases themselves ---- */
let seed = 20260930;
function rnd(){ seed |= 0; seed = seed + 0x6D2B79F5 | 0; let t = Math.imul(seed ^ seed >>> 15, 1 | seed); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }
const ri = (a, b) => a + Math.floor(rnd() * (b - a + 1));
const pick = (l) => l[Math.floor(rnd() * l.length)];
const chance = (p) => rnd() < p;
const clone = (o) => JSON.parse(JSON.stringify(o === undefined ? null : o));

const cases = [];
function add(fn, args, result, after){ cases.push({ fn, args: clone(args), result: clone(result), after: after === undefined ? undefined : clone(after) }); }

/* ---- the Companion's cards, if an export was given ---- */
let cards = [];
const cardsFile = process.argv[2];
if(cardsFile && fs.existsSync(cardsFile)) cards = JSON.parse(fs.readFileSync(cardsFile, "utf8")).cards || [];

/* ================================================================ parseInt */
const numVals = [0, 1, -3, 3.7, -3.7, "12", "12abc", " 5", "-4", "+6", "", "abc", null, true, false, "3.9", "0x10", "  -  2", 7.0, "007"];
numVals.forEach(v => { const n = parseInt(v, 10); add("num", [v, 99], isNaN(n) ? 99 : n); });

/* ================================================================ hex */
for(let i = 0; i < 300; i++){
  const a = { q: ri(-12, 12), r: ri(-12, 12) }, b = { q: ri(-12, 12), r: ri(-12, 12) };
  add("hexDistance", [a, b], R.hexDistance(a, b));
  add("hexLine", [a, b], R.hexLine(a, b));
}
for(let i = 0; i < 40; i++){ const q = ri(-9, 9), r = ri(-9, 9); add("hexNeighbours", [q, r], R.hexNeighbours(q, r)); }
["3,-2", "-4,6", "0,0", "12,-7"].forEach(k => add("hexParse", [k], R.hexParse(k)));

/* a random floor: tiles within a radius with some removed, walls on edges, standing Units */
function randomFloor(){
  const rad = ri(3, 7), tiles = {}, walls = {}, blocked = {};
  for(let q = -rad; q <= rad; q++) for(let r = Math.max(-rad, -q - rad); r <= Math.min(rad, -q + rad); r++) if(!chance(0.12)) tiles[q + "," + r] = 1;
  const keys = Object.keys(tiles);
  const nw = ri(0, 14);
  for(let i = 0; i < nw; i++){
    const a = R.hexParse(pick(keys)), d = pick([[1, 0], [0, 1], [-1, 1], [-1, 0], [0, -1], [1, -1]]);
    walls[a.q + "," + a.r + "|" + (a.q + d[0]) + "," + (a.r + d[1])] = -1;
  }
  const nb = ri(0, 6);
  for(let i = 0; i < nb; i++) blocked[pick(keys)] = 1;
  return { tiles, walls, blocked };
}
/* the callbacks, from the floor's data (the game builds the same ones) */
function wallFn(walls){ return function(a, b){ return !!(walls[a.q + "," + a.r + "|" + b.q + "," + b.r] !== undefined || walls[b.q + "," + b.r + "|" + a.q + "," + a.r] !== undefined); }; }
for(let i = 0; i < 160; i++){
  const f = randomFloor(), keys = Object.keys(f.tiles), from = R.hexParse(pick(keys)), steps = ri(0, 7);
  const out = R.reachable(from, steps, {
    passable: (n) => !!f.tiles[n.q + "," + n.r],
    blocked: (n) => !!f.blocked[n.q + "," + n.r],
    wall: wallFn(f.walls)
  });
  add("reachable", [from, steps, f], out);
}
for(let i = 0; i < 120; i++){
  const f = randomFloor(), keys = Object.keys(f.tiles);
  for(let j = 0; j < 6; j++){
    const a = R.hexParse(pick(keys)), b = R.hexParse(pick(keys));
    add("lineOfSight", [a, b, f.walls], R.lineOfSight(a, b, f.walls));
  }
  add("wallSegments", [f.walls], R.wallSegments(f.walls));
}

/* ================================================================ units */
function fixIds(u, id){ u.id = id; return u; }
cards.forEach((c, i) => {
  add("unitFromCard", [c, null, "c" + i], fixIds(R.unitFromCard(c, null), "c" + i));
  if(i % 3 === 0) add("unitFromCard", [c, "enemy", "d" + i], fixIds(R.unitFromCard(c, "enemy"), "d" + i));
  add("chipValue", [c], R.chipValue(c));
  (c.entries || c.abilities || []).forEach(a => { const u = R.unitFromCard({ name: "x", entries: [a] }, "ally"); if(u.actions[0]) add("actionEffect", [u.actions[0]], R.actionEffect(u.actions[0])); });
});
[{ aetherValue: 4 }, { aetherValue: "12" }, { aetherValue: " " , level: 3, rarity: "Rare" }, { level: 9, rarity: "mythic" }, { level: 0 }, {}, { aetherValue: -2 }, { level: "4", rarity: "EPIC" }].forEach(c => add("chipValue", [c], R.chipValue(c)));
const texts = ["Deal 4 damage.", "deals 3 damage to the target", "7 damage", "Heals for 5", "heal 2 and deal 1 damage", "Restores 6 Health", "Gains +3 HP", "gain 4 health", "The target takes [[damage 2]].", "Nothing here", ""];
texts.forEach(t => { add("actionEffect", [{ text: t }], R.actionEffect({ text: t })); add("actionEffect", [{ text: t, dmg: "5" }], R.actionEffect({ text: t, dmg: "5" })); add("actionEffect", [{ text: t, dmg: 0 }], R.actionEffect({ text: t, dmg: 0 })); });

function randomSpec(id, side){
  const s = { id, side, name: (side === "ally" ? "A" : "E") + id, hpMax: ri(4, 30), ac: ri(6, 18), ms: ri(0, 6), nrgMax: ri(0, 6), cardType: side === "ally" ? pick(["hero", "troop", "troop"]) : pick(["enemy", "enemy", "elite", "boss", "miniboss"]) };
  if(chance(0.3)) s.hp = ri(1, s.hpMax);
  if(chance(0.3)) s.integrity = ri(5, 18);
  if(chance(0.3)) s.roles = pick([["Melee"], ["Ranged", "Cyber"], ["Support", "Melee", "Ranged"]]);
  if(chance(0.2)) s.carries = chance(0.5);
  if(chance(0.3)) s.affinities = [{ district: pick(["3", "5", ""]), level: ri(0, 3) }];
  const beh = R.behaviors().filter(b => b.side === (side === "ally" ? "ally" : "enemy"));
  if(chance(0.7)){ s.behaviors = []; const n = ri(1, 3); for(let i = 0; i < n; i++){ const b = pick(beh), o = { k: b.k }; if(b.pdef !== undefined && chance(0.5)) o.x = ri(1, 12); s.behaviors.push(o); } }
  s.actions = [];
  const na = ri(1, 3);
  for(let i = 0; i < na; i++) s.actions.push(randomAction(i));
  return s;
}
function randomAction(i){
  const a = { name: "Act" + i, tag: pick(["Active", "Active", "Active", "Combo", "Passive", "Special"]), cost: ri(0, 3), role: pick(["melee", "ranged", "ranged", "cyber", "support", "aether", "", "Ranged"]), text: pick(texts) };
  if(chance(0.8)) a.dmg = String(ri(0, 8));
  if(chance(0.6)) a.rng = String(ri(1, 6));
  if(chance(0.7)) a.hit = String(ri(4, 16));
  if(chance(0.5)) a.pen = String(ri(0, 5));
  return a;
}
for(let i = 0; i < 60; i++){ const s = randomSpec("m" + i, pick(["ally", "enemy"])); add("makeUnit", [s], R.makeUnit(s)); }

/* ================================================================ statuses: see the end */
const STATUSES = ["Rooted", "Stunned", "Marked", "Pinned", "Bleed", "Slowed", "Drained", "Evasive", "Poisoned", "Weakened", "Sundered", "Half Cover", "poisoned", "Overclocked"];

/* ================================================================ health */
for(let i = 0; i < 40; i++){
  const u = R.makeUnit(randomSpec("h" + i, "ally")), before = clone(u), a = ri(-2, 40), op = pick(["hit", "heal", "gain"]);
  const ev = R[op](u, a);
  add(op, [before, a], ev, u);
}

/* ================================================================ aether */
for(let i = 0; i < 80; i++){
  const pool = {}; ["generic", "d3", "d5", "d1"].forEach(k => { if(chance(0.6)) pool[k] = ri(0, 5); });
  const cost = { generic: ri(0, 4), affinity: ri(0, 3) }; if(chance(0.7)) cost.district = pick(["3", "5", "1"]);
  add("aetherCanPay", [clone(pool), cost], R.aetherCanPay(clone(pool), cost));
  const p2 = clone(pool), ok = R.aetherPay(p2, cost);
  add("aetherPay", [clone(pool), cost], ok, p2);
  add("aetherTotal", [pool], R.aetherTotal(pool));
  const g = { generic: ri(0, 2), d3: ri(0, 2) };
  add("aetherAdd", [clone(pool), g], R.aetherAdd(clone(pool), g));
}
for(let i = 0; i < 30; i++){
  const us = []; for(let j = 0; j < ri(1, 5); j++){ const u = R.makeUnit(randomSpec("x" + j, pick(["ally", "enemy"]))); if(chance(0.2)) u.down = true; us.push(u); }
  add("aetherFromHero", [us[0]], R.aetherFromHero(us[0]));
  add("aetherIncome", [us, "ally"], R.aetherIncome(us, "ally"));
}

/* ================================================================ dice */
[1, 7, 42, 20260930, -5, 123456789, 0].forEach(sd => {
  const d = R.makeDice(sd), rolls = [];
  for(let i = 0; i < 60; i++){ const k = pick(["d20", "d6", "coin", "zz"]); rolls.push([k, d.roll(k)]); }
  add("dice", [sd, rolls.map(x => x[0])], rolls.map(x => x[1]));
});

/* ================================================================ attacks */
function withStatuses(u){
  if(chance(0.25)) R.addStatus(u, pick(["Marked", "Pinned"]), null, pick(["enemy", "rule", undefined]));
  if(chance(0.25)) R.addStatus(u, pick(["Evasive", "Sundered", "Weakened"]), ri(1, 3));
  if(chance(0.15)) u.flying = true;
  if(chance(0.2)) u.mods = [{ stat: pick(["AC", "DMG", "INT", "RANGE", "AP"]), amt: ri(-2, 3), dur: "turns", n: 2 }];
  return u;
}
for(let i = 0; i < 400; i++){
  const at = withStatuses(R.makeUnit(randomSpec("a" + i, "ally"))), tg = withStatuses(R.makeUnit(randomSpec("t" + i, "enemy"))), act = randomAction(0);
  const ctx = {};
  if(chance(0.8)) ctx.distance = ri(0, 8);
  if(chance(0.3)) ctx.cover = ri(0, 4);
  if(chance(0.2)) ctx.evasive = ri(0, 2);
  if(chance(0.1)) ctx.reaction = true;
  const mode = pick(["rolls", "rolls", "dice", "manual", "partial"]);
  if(mode === "rolls") ctx.rolls = { accuracy: ri(1, 20), penetration: ri(1, 20) };
  if(mode === "partial"){ ctx.rolls = { accuracy: ri(1, 20) }; ctx.manual = true; }
  if(mode === "manual") ctx.manual = true;
  const seedv = ri(1, 1e6);
  const c1 = Object.assign({}, ctx); if(mode === "dice") c1.dice = R.makeDice(seedv);
  add("resolveAttack", [clone(at), act, clone(tg), ctx, mode === "dice" ? seedv : null], R.resolveAttack(clone(at), act, clone(tg), c1));
  add("rollsFor", [act, clone(tg)], R.rollsFor(act, tg));
  if(i % 2 === 0){
    const a2 = clone(at), t2 = clone(tg), c2 = Object.assign({}, ctx); if(mode === "dice") c2.dice = R.makeDice(seedv);
    const ev = R.attack(a2, act, t2, c2);
    add("attack", [clone(at), act, clone(tg), ctx, mode === "dice" ? seedv : null], ev, [a2, t2]);
    const useT = chance(0.9), a3 = clone(at), t3 = clone(tg), ev2 = R.useAction(a3, act, useT ? t3 : null);
    add("useAction", [clone(at), act, useT ? clone(tg) : null], ev2, [a3, t3]);
    add("canAfford", [at, act], R.canAfford(at, act));
  }
}

/* ================================================================ behaviour */
function team(n, side, pre){ const l = []; for(let i = 0; i < n; i++){ const u = R.makeUnit(randomSpec(pre + i, side)); if(chance(0.15)) u.down = true; if(chance(0.3)) u.attackedThisRound = true; if(chance(0.3)) R.addStatus(u, pick(["Marked", "Slowed"]), 1, pick(["enemy", "rule", "player"])); u.pos = { q: ri(-5, 5), r: ri(-5, 5) }; l.push(u); } return l; }
for(let i = 0; i < 200; i++){
  const allies = team(ri(1, 5), "ally", "p" + i + "_"), foes = team(ri(1, 4), "enemy", "f" + i + "_"), me = foes[0];
  if(chance(0.4)) me.lastAttackedBy = pick(allies).id;
  const dfn = (u) => R.hexDistance(me.pos, u.pos);
  add("chooseTarget", [clone(me), clone(allies), "pos"], (R.chooseTarget(me, allies, { distance: dfn }) || { id: null }).id);
  const near = ri(0, 6);
  add("movePlan", [clone(me), near], R.movePlan(me, { nearestEnemyDistance: near }));
  add("bestAction", [clone(me), clone(allies[0]), "pos"], R.bestAction(me, allies[0], { distance: (a, b) => R.hexDistance(a.pos, b.pos) }));
  add("supportPlan", [clone(allies[0]), clone(allies)], (function(p){ return p ? { action: p.action, target: p.target.id, why: p.why } : null; })(R.supportPlan(allies[0], allies)));
  add("escortTarget", [clone(allies[0]), clone(allies)], (R.escortTarget(allies[0], allies) || { id: null }).id);
  add("outcome", [clone(allies.concat(foes))], R.outcome(allies.concat(foes)));
  const cu = clone(me); cu.actions = [randomAction(0), randomAction(1), randomAction(2)]; cu.actions.forEach(a => a.tag = pick(["Combo", "Combo", "Special", "Active"])); cu.comboAt = ri(-3, 5); if(chance(0.3)) cu.overrideNext = "Act" + ri(0, 2);
  add("nextComboAction", [cu], R.nextComboAction(cu));
  const us = clone(allies.concat(foes)), ev = R.endTurn(us);
  add("endTurn", [clone(allies.concat(foes))], ev, us);
}

/* ================================================================ whole turns and fights */
for(let i = 0; i < 120; i++){
  const allies = team(ri(1, 4), "ally", "P" + i + "_"), foes = team(ri(1, 4), "enemy", "F" + i + "_");
  allies.concat(foes).forEach(u => { u.down = false; u.hp = u.hpMax; });
  const covers = {}; foes.concat(allies).forEach(u => { if(chance(0.3)) covers[u.id] = ri(1, 3); });
  const sd = ri(1, 1e6), maps = chance(0.7);
  const ctxOf = () => { const c = { dice: R.makeDice(sd), coverFor: (t) => covers[t.id] || 0, maxRounds: ri(3, 30) }; if(maps) c.distance = (a, b) => R.hexDistance(a.pos, b.pos); return c; };
  const units = clone(allies.concat(foes));
  const ctx = ctxOf(), cap = ctx.maxRounds;
  const res = R.runCombat(units, ctx);
  add("runCombat", [clone(allies.concat(foes)), { seed: sd, covers, maps, maxRounds: cap }], { winner: res.winner, rounds: res.rounds, log: res.log, survivors: res.survivors }, res.units);
  if(i % 3 === 0){
    const us2 = clone(allies.concat(foes)), st = { units: us2 }, c2 = ctxOf();
    const e = foes[0], ev = R.enemyTurn(us2.filter(u => u.id === e.id)[0], st, c2);
    add("enemyTurn", [clone(allies.concat(foes)), e.id, { seed: sd, covers, maps }], ev, us2);
  }
}

/* the statusScript cases: run again from a known start, so the start is what's recorded */
const scripted = [];
for(let i = 0; i < 240; i++){
  seed = 5000 + i;
  const u0 = R.makeUnit(randomSpec("s" + i, "ally"));
  if(chance(0.4)) u0.mods = [{ stat: pick(["AC", "MS", "DMG", "INT", "RANGE", "AP", "HP", "NRG"]), amt: ri(-3, 4), dur: pick(["turns", "passive", "persistent"]), n: ri(1, 3) }];
  /* Handbook 15.9: some arrive in the Enemies' half of the round and tick as the Player's turn ends */
  if(u0.mods && chance(0.4)) u0.mods[0].late = true;
  let halfNow = "ally";
  R.hooks.half = () => halfNow;
  if(chance(0.2)) u0.flying = true;
  const start = clone(u0), u = clone(u0), steps = [], evs = [];
  const n = ri(1, 7);
  for(let j = 0; j < n; j++){
    const op = pick(["add", "add", "add", "drop", "tick", "tickLate", "half", "eff"]);
    if(op === "add"){ const s = [pick(STATUSES), pick([null, "", ri(0, 4), String(ri(1, 3))]), pick([null, "enemy", "rule", "aura:x", "passive:y"]), pick([null, ri(1, 3)])];
      steps.push(["add"].concat(s)); evs.push(R.addStatus(u, s[0], s[1], s[2], s[3])); }
    else if(op === "drop"){ const nm = pick(STATUSES); steps.push(["drop", nm]); evs.push(R.dropStatus(u, nm)); }
    else if(op === "tick"){ steps.push(["tick"]); evs.push(R.rechargeTick([u])); }
    else if(op === "tickLate"){ steps.push(["tickLate"]); evs.push(R.turnEndTick([u])); }
    else if(op === "half"){ halfNow = pick(["ally", "enemy"]); steps.push(["half", halfNow]); evs.push(halfNow); }
    else { steps.push(["eff"]); evs.push(R.effective(u)); }
  }
  steps.push(["n", "Slowed"]); evs.push(R.statusN(u, "Slowed"));
  steps.push(["turns", "Poisoned"]); evs.push(R.statusTurns(u, "Poisoned"));
  steps.push(["has", "poisoned"]); evs.push(R.hasStatus(u, "poisoned"));
  scripted.push({ fn: "statusScript", args: clone([start, steps]), result: clone(evs), after: clone(u) });
  delete R.hooks.half;
}
const final = cases.concat(scripted);
const out = path.join(ROOT, "game", "tests", "fixtures", "rule_cases.json");
fs.writeFileSync(out, JSON.stringify({ made: "rules.js " + (R.version || ""), cards: cards.length, cases: final }));
const counts = {}; final.forEach(c => counts[c.fn] = (counts[c.fn] || 0) + 1);
console.log(JSON.stringify({ file: out, cases: final.length, kinds: Object.keys(counts).length, counts }));
