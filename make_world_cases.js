#!/usr/bin/env node
/* Generates the cases that prove the game's World Map is the Companion's:
   the map itself (Districts, Skull Levels, what a tile holds, the chance of
   an ambush, the way from one tile to another and its risk), the floors a
   fight is drawn from, Events, blueprints and chassis (what can drop, what
   a drop is called, what a roll gives), and whole deployments walked step by
   step: ambushes sprung, POIs entered and fought floor by floor, Caches
   opened, Events chosen, fights won, lost, retried and escaped, wipes, and
   coming home, across several deployments so that cleared tiles come back.

   world.js, deploy.js, progress.js, loot.js and keywords.js are run here
   exactly as they are, with a stand-in for the browser's storage.
   Writes game/tests/fixtures/world_cases.json; the game's
   tests/world_diff.gd replays every case and compares.

     node make_world_cases.js <the export's content folder>

   Deterministic: the same sources and export give the same cases.

   Since 0.9 the game leaves the dock as the Companion does: a Strike Team's
   Troops must be Workshop designs that fit, and their copies are paid for in
   Troop parts. So a deployment begins here with deploy.js's own plan() and
   start(), on designs made for the case.

   Since 0.10 the dock is here too (dock.js): what is packed must be owned at
   the dock, pre-built copies bought there go out with the team, the
   scanner and the Starter bay change what a team sees and what is free, and
   a deployment's end extends your reach, pays bounties, insures a wiped
   haul and restocks the Exchange. */
"use strict";
const fs = require("fs"), path = require("path"), vm = require("vm");
const ROOT = __dirname, DIR = process.argv[2];
if(!DIR){ console.error("usage: node make_world_cases.js <content folder>"); process.exit(2); }
const load = n => JSON.parse(fs.readFileSync(path.join(DIR, n + ".json"), "utf8"));
const cards = load("cards").cards, floors = load("floors").floors, world = load("world_map"), pools = load("pools").pools,
  chassis = load("chassis").chassis, tables = load("tables");

/* ---- the Companion's modules, with storage that is only a table ---- */
const store = {};
const sb = { Math, JSON, String, Object, Array, parseInt, parseFloat, isNaN, isFinite, Date, Number, RegExp, console,
  localStorage: { getItem: k => (k in store ? store[k] : null), setItem: (k, v) => { store[k] = String(v); }, removeItem: k => { delete store[k]; } } };
sb.window = sb;
vm.createContext(sb);
const levels = {}; floors.forEach(f => { levels[f.name] = f; });
const chassisById = {}; chassis.forEach(c => { chassisById[c.id] = c; });
function resetStore(){
  Object.keys(store).forEach(k => delete store[k]);
  store["keter-app-world"] = JSON.stringify(world.map);
  store["keter-app-world-tables"] = JSON.stringify(world.tables);
  store["keter-app-world-events"] = JSON.stringify(world.events);
  store["keter-app-world-unique"] = JSON.stringify(world.uniques);
  store["keter-hexmap-levels"] = JSON.stringify(levels);
  store["keter-app-pools"] = JSON.stringify(pools);
  store["keter-app-chassis"] = JSON.stringify(chassisById);
  if(tables.loot) store["keter-app-loot"] = JSON.stringify(tables.loot);
  if(tables.workshop) store["keter-app-workshop"] = JSON.stringify(tables.workshop);
}
resetStore();
["keywords.js", "scoring.js", "loot.js", "progress.js", "chassis.js", "skins.js", "workshop.js", "chunkgen.js", "world.js", "deploy.js", "dock.js"].forEach(f => vm.runInContext(fs.readFileSync(path.join(ROOT, f), "utf8"), sb));
const W = sb.KETER_WORLD, D = sb.KETER_DEPLOY, P = sb.KETER_PROG, L = sb.KETER_LOOT, K = sb.KETER_KW, WS = sb.KETER_WORKSHOP, DK = sb.KETER_DOCK;
/* (v14.9) the cards that can be found as loot: the export's own */
P.useCards(() => cards);
/* the export's cards, less the Companion's own designs: the designs are the case's */
const baseCards = cards.filter(c => c._src !== "design" && c._src !== "prebuilt");
sb.KETER_ALLCARDS = () => baseCards.concat(WS.cards());
/* every Archetype a card carries is a keyword too, as in the app */
if(K.registerArchetypes) cards.forEach(c => K.registerArchetypes(c.archetypes));
const clone = o => JSON.parse(JSON.stringify(o === undefined ? null : o));
function fresh(){ resetStore(); W._flush(); }

/* ---- chance for the script itself, apart from the stream the modules roll with ---- */
let seedA = 20260808;
function rnd(){ seedA = (seedA + 0x6D2B79F5) >>> 0; let t = seedA; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }
const ri = (a, b) => a + Math.floor(rnd() * (b - a + 1)), pick = a => a[Math.floor(rnd() * a.length)], chance = p => rnd() < p;

const cases = [];
const add = (fn, args, result) => cases.push({ fn, args: clone(args), result: clone(result) });
const M = W.map(), keys = Object.keys(M.tiles), R = M.radius;
const contentOf = k => { const c = W.contentAt(k); return c ? { kind: c.kind, name: c.name, type: c.type || null, unique: c.unique ? c.unique.id : null } : null; };

/* ---- the text hash everything fixed about a tile comes from ---- */
["", "a", "0,0", "-18,0:393679197", "3,-2:880088:0", "KETER", "The quick brown fox", "12,5:880088:7", "ev", "-1,2:880088"].forEach(s => add("hash", [s], W.hashStr(s)));
for(let i = 0; i < 30; i++){ const s = pick(keys) + ":" + ri(0, 1e9) + (chance(0.5) ? ":" + ri(0, 9) : ""); add("hash", [s], W.hashStr(s)); }

/* ---- every tile, and some places that are not tiles ---- */
const some = keys.slice();
for(let q = -R - 1; q <= R + 1; q += 3) for(let r = -R - 1; r <= R + 1; r += 4) if(!M.tiles[W.key(q, r)]) some.push(W.key(q, r));
some.forEach(k => add("tile", [k], { open: W.isOpen(k), skull: W.skullOf(k), district: W.districtOf(k), ambush: W.ambushChance(k), content: contentOf(k),
  poiType: W.isOpen(k) ? W.poiTypeOf(k) : null, neighbours: W.neighbours(k), dist: W.dist(k, M.dock) }));
add("mapFacts", [], { dock: M.dock, radius: M.radius, tiles: keys.length, exists: true });

/* ---- ways across it ---- */
for(let i = 0; i < 160; i++){
  const a = pick(keys), b = chance(0.1) ? pick(some) : pick(keys), p = W.path(a, b);
  add("path", [a, b], { path: p, risk: p ? W.pathRisk(p) : null });
}

/* ---- the floors a fight is drawn from ---- */
add("floors", [], W.floors().map(f => ({ key: f.key, name: f.name, district: f.district, skull: f.skull, type: f.type, size: f.size, test: f.test, tiles: f.tiles })));
add("floorCount", [], [1, 2, 3, 4, 5, 6, 0, 9].map(s => W.floorCount(s)));
for(let i = 0; i < 260; i++){
  const sd = ri(1, 1e9), d = pick(["1", "2", "3", "4", "5", "6", ""]), sk = ri(1, 6), n = ri(1, 4), amb = chance(0.4);
  L.seed(sd);
  add("draw", [sd, d, sk, n, amb], W.drawFloors(d, sk, n, { ambush: amb }));
}

/* ---- Events: which one a tile holds, and after it has come back ---- */
keys.filter(k => M.tiles[k].c === "event").forEach(k => {
  [0, 1, 4].forEach(c => {
    fresh(); const st = W.state(); if(c) st.cleared[k] = c; W.saveState(st);
    const ev = W.eventFor(k); add("event", [k, c], ev ? ev.id : null);
  });
});
fresh();

/* ---- blueprints and chassis ---- */
const kwNames = K.allKeywords().map(k => k.name).concat(["Nope", "", "damage", "target enemy"]);
kwNames.forEach(n => add("blueprint", [n], P.blueprintOf(n)));
const allItems = P.allItems().concat(["bp:Nope:1", "ch:nope", "bp:Burst:4", "bp:Burst:0", "garbage", "bp:damage:1", "bp:Test Drone"]);
const poolish = Object.keys(pools).reduce((a, d) => a.concat(pools[d].items || []), []).concat(["bp:Rooted:1", "bp:Drained:1", "bp:Drained:2", "bp:Evasive:1", "bp:Sundered:1", "ch:ch_test_threshold", "ch:ch_test_verdant"]);
function randomProg(){
  const s = { bp: {}, ch: {}, named: {} };
  for(let n = ri(0, 6); n > 0; n--){ const o = P.parseItem(pick(chance(0.7) ? poolish : allItems)); if(!o) continue;
    if(o.kind === "bp") s.bp[o.name] = ri(1, 3); else s.ch[o.id] = true; }
  for(let n = ri(0, 3); n > 0; n--){ const o = P.parseItem(pick(poolish)); if(o) s.named[o.kind === "bp" ? "bp:" + o.name : "ch:" + o.id] = 1; }
  return s;
}
const setProg = s => { store[P.PROG_KEY] = JSON.stringify(Object.assign({ seen: { enemy: {}, district: {}, comp: {} }, all: false }, clone(s))); };
const progNow = () => { const s = P.state(); return { bp: s.bp, ch: s.ch, named: s.named }; };
/* (0.22) cards found as loot are items too: some the export has, one it hasn't */
const withCards = allItems.concat(["cd:Field Dressing", "cd:Ration Pack", "cd:Ledger Core", "cd:Grav-Boot Charge", "cd:Nothing Of The Sort"]);
const somePending = () => { const out = []; for(let n = ri(0, 3); n > 0; n--) out.push(pick(chance(0.8) ? poolish : withCards)); return out; };
for(let i = 0; i < 500; i++){
  const st = randomProg(), it = pick(chance(0.6) ? poolish : withCards), pend = somePending(); setProg(st);
  add("eligible", [st, it, pend], P.eligible(it, pend));
}
for(let i = 0; i < 300; i++){
  const st = randomProg(), it = pick(chance(0.7) ? poolish : withCards), reveal = chance(0.4); setProg(st);
  add("itemName", [st, it, reveal], P.itemName(it, reveal));
}
for(let i = 0; i < 120; i++){
  const st = randomProg(), seq = []; for(let n = ri(1, 6); n > 0; n--) seq.push(pick(chance(0.8) ? poolish : withCards)); setProg(st);
  const got = seq.map(it => P.grant(it));
  add("grant", [st, seq], { got, after: progNow() });
}
const dropCards = cards.filter(c => c.setDrops || c.lootPool).map(c => ({ setDrops: c.setDrops || [], lootPool: c.lootPool || [] }))
  .concat([{}, { setDrops: [{ item: "bp:Burst:1", chance: 100 }, { item: "bp:Burst:2", chance: 100 }, { item: "", chance: 100 }, null, { item: "ch:ch_test_verdant", chance: 55.5 }] },
    { lootPool: ["bp:Pierce:1", "bp:Pierce:1", "ch:nope"] }]);
for(let i = 0; i < 700; i++){
  const st = randomProg(), sd = ri(1, 1e9), o = { chance: pick([0, 2, 8, 15, 35, 50, 100, 100, 12.5, "40"]), district: pick(["3", "3", "3", "1", ""]), card: pick(dropCards) }, pend = somePending();
  /* (0.22) and now and then a card's chance, at a Skull Level */
  if(chance(0.4)){ o.cardChance = pick([0, 10, 25, 50, 100, 100, "30", 12.5]); o.skull = pick([1, 2, 3, 4, 5, 6, 6, "3", 0, undefined]); }
  setProg(st); L.seed(sd);
  add("rollItems", [st, sd, o, pend], P.rollItems(o, pend));
}
for(let i = 0; i < 300; i++){
  const st = randomProg(), sd = ri(1, 1e9), lines = []; for(let n = ri(0, 5); n > 0; n--) lines.push(chance(0.75) ? { kind: "item", item: pick(chance(0.8) ? poolish : allItems), chance: pick([0, 30, 50, 100, 100]) } : { kind: "roll", n: 2, type: "any", bonus: 0 });
  const pend = somePending(); setProg(st); L.seed(sd);
  add("rollRewardItems", [st, sd, { shards: 3, lines }, pend], P.rollRewardItems({ shards: 3, lines }, pend));
}

/* (0.22) the cards a District can turn up, at each Skull Level */
["3", "1", "", "5", "any"].forEach(d => [1, 2, 3, 4, 5, 6, 0, "4", undefined].forEach(sk => add("cardPool", [d, sk], P.cardPool(d, sk))));

/* ---- whole deployments ---- */
const heroNames = cards.filter(c => c.cardType === "hero").map(c => c.name);
const consNames = cards.filter(c => c.cardType === "consumable").map(c => c.name);
const foeNames = cards.filter(c => /^(enemy|elite|miniboss)$/.test(c.cardType)).map(c => c.name);
const contentTiles = keys.filter(k => W.contentAt(k) && k !== M.dock);
function randomBag(most){ const b = L.bag(); b.shards = ri(0, most); for(let n = ri(0, 4); n > 0; n--) b.parts[pick(["troop", "equipment", "aether"])][ri(0, 5)] += ri(1, 3); return b; }
function snap(){
  const s = JSON.parse(store[D.KEY] || "null"), ws = W.state(), hist = D.history();
  const names = refs => refs.map(r => String(r).split("|").slice(1).join("|"));
  return {
    dep: s ? { active: !!s.active, n: s.n, pos: s.pos, steps: s.steps, fights: s.fights, maxSkull: s.maxSkull || 0, haul: L.norm(s.haul), items: s.items,
      activity: s.activity ? { kind: s.activity.kind, tile: s.activity.tile, district: s.activity.district, skull: s.activity.skull, floors: s.activity.floors, index: s.activity.index,
        name: s.activity.name, type: s.activity.type, unique: s.activity.unique, tileAmbush: !!s.activity.tileAmbush, fromEvent: !!s.activity.fromEvent } : null,
      heroesOut: names(s.heroesOut), cons: s.pack.cons, kills: s.kills, log: (s.log || []).map(l => l.text), result: s.result || null } : null,
    world: { known: Object.keys(ws.known).length, knownHash: W.hashStr(Object.keys(ws.known).sort().join(";")), stood: W.hashStr(Object.keys(ws.stood).sort().join(";")), cleared: ws.cleared, completed: ws.completed },
    prog: progNow(), stock: L.stock(),
    out: s ? { copies: byName(s.copies), lost: byName(s.lost), paid: s.paid || null, pre: byName(s.pre), pack: s.pack || null } : null,
    dock: (function(){ const k = DK.state(), st = k.stock ? Object.assign({}, k.stock) : null; if(st) delete st.made;
      return { reach: k.reach, restocks: k.restocks, stock: st, bounties: k.bounties, log: k.log.map(l => l.text), heroes: k.heroes }; })(), inv: DK.inv(),
    history: hist.map(h => ({ n: h.n, result: h.result, team: h.team, steps: h.steps, fights: h.fights, haul: L.norm(h.haul), items: h.items, out: h.out }))
  };
}
/* a design's id, read as its name (the game keys what is lost by name) */
let DESIGNS = {};
function byName(m){ const out = {}; Object.keys(m || {}).forEach(id => { const d = WS.get(id); out[d ? d.name : id] = m[id]; }); return out; }
/* designs for a case: the starter and a few of the case's own, some of which may not fit */
const sentences = ["[[target enemy]] takes [[damage 1]].", "[[target enemy]] takes [[damage 2]].", "[[target enemy]] takes [[damage 1]] with [[Burst 2]].", "[[target ally]] gains [[heal 2]].",
  "[[target enemy]] gains [[Slowed 1]].", "[[target enemy]] takes [[damage 3]] with [[AoE 1]].", "[[this Unit]] gains [[+1 AC]] for [[turns 2]].", "[[target enemy]] takes [[damage 1]] with [[Pierce]]."];
function someDesigns(){
  const out = {}, names = ["Lancer", "Wall", "Needle", "Mule", "Spark"];
  for(let n = ri(0, 3); n > 0; n--){
    const ch = pick(chassis), id = "ds_case" + n, sub = (ch.subtypes || [])[0] || "Melee";
    out[id] = { id, name: names[n] + " " + ri(1, 9), chassis: ch.id, notes: "",
      abilities: [{ name: "Shot", kind: "action", role: sub, energy: pick([1, 1, 2]), range: pick([3, 4, 5]), hit: pick([5, 6, 7]), ap: pick([3, 4]), text: pick(sentences) }] };
  }
  return out;
}
/* what the Companion's Deck Builder keeps, from the game's way of keeping a team */
function loadout(team){
  const ref = n => { if(WS.cards().some(c => c.name === n)) return "design|" + n; const c = baseCards.filter(x => x.name === n)[0]; return (c ? (c._src || "master") : "master") + "|" + n; };
  const deck = []; Object.keys(team.deck).forEach(n => { for(let i = 0; i < team.deck[n]; i++) deck.push(ref(n)); });
  return { name: team.name, level: team.level, created: null, heroes: team.heroes.map(ref), deck, actions: {}, pouch: {} };
}
const planOut = p => ({ ok: !!p.ok, fits: !!p.fits, afford: !!p.afford, reasons: p.reasons, heroes: p.heroes || [], lines: (p.lines || []).map(l => ({ name: l.name, copies: l.copies, free: l.free, each: l.each, cost: l.cost, starter: !!l.starter })),
  parts: p.parts, other: p.other || 0, busy: !!p.busy });
/* leaving the dock: deploy.js's own start(), with what is packed */
function leave(team, pack){
  store[D.LOAD_KEY || "keter-app-loadouts"] = JSON.stringify([loadout(team)]);
  const p = D.plan(0, pack);
  const r = D.start(0, pack);
  if(r.ok && Object.keys(pack).length) count("packed");
  if(r.ok && (r.state.preLines || []).length) count("pre-built copies out", r.state.preLines.reduce((a, l) => a + l.copies, 0));
  return { plan: planOut(p), ok: !!r.ok };
}
function fightResult(s){
  const a = s.activity, standing = D.heroRefs(s).map(r => String(r).split("|").slice(1).join("|"));
  let winner = pick(["ally", "ally", "ally", "ally", "ally", "ally", "ally", "enemy", "enemy", "draw", "escape", "stalemate"]);
  if(winner === "escape" && a.kind !== "poi") winner = "ally";
  const lost = winner !== "ally" && winner !== "escape";
  const down = standing.filter(() => chance(lost ? 0.55 : 0.12));
  const items = []; for(let n = pick([0, 0, 0, 1, 1, 2, 3]); n > 0; n--) items.push(pick(chance(0.85) ? poolish : allItems));
  const cons = Object.keys(s.pack.cons || {}).filter(() => chance(0.3)); if(chance(0.1)) cons.push("Not packed");
  const kills = []; for(let n = ri(0, 3); n > 0; n--) kills.push(chance(0.8) ? { name: pick(foeNames), skull: ri(1, 4) } : { name: pick(foeNames) });
  /* Troops that fell: copies of the designs brought (more than are left, now and then), a Forge Troop, nobody */
  const troops = []; const deckNames = Object.keys(s.lo ? s.lo.deck.reduce((m, r) => { m[String(r).split("|").slice(1).join("|")] = 1; return m; }, {}) : {}).concat((s.preLines || []).map(l => l.name));
  for(let n = pick([0, 0, 1, 1, 2, 3]); n > 0; n--) troops.push(chance(0.85) && deckNames.length ? pick(deckNames) : pick(["Test Drone", "Nobody", "Test Rally"]));
  return { winner, haul: randomBag(14), reward: chance(0.5) ? randomBag(20) : L.bag(), items, heroesDown: chance(0.08) ? down.concat(["Nobody"]) : down, troopsLost: troops, consUsed: cons, kills };
}
const fightOut = o => o ? { next: o.next, kind: o.kind || null, name: o.name || null, gained: o.gained ? L.norm(o.gained) : null, items: o.items || null, escaped: !!o.escaped, floor: o.floor || null, count: o.count || null,
  poiDone: !!o.poiDone, final: o.final ? { bag: L.norm(o.final.bag), items: o.final.items } : null, reserves: o.reserves ? o.reserves : null,
  lostHaul: o.lostHaul ? L.norm(o.lostHaul) : null, lostItems: o.lostItems || null, dock: o.next === "wipe" ? dockOut(o.dock) : null } : null;
const stepOut = r => ({ moved: !!r.moved, why: r.why || null, pos: r.pos || null, home: !!r.home, content: r.content ? { kind: r.content.kind, name: r.content.name } : null, ambush: !!r.ambush, tileAmbush: !!r.tileAmbush });
const specOut = sp => sp ? { floor: sp.floor, district: sp.district, skull: sp.skull, kind: sp.kind, index: sp.index, count: sp.count, name: sp.name, type: sp.type, tile: sp.tile, n: sp.n, pending: sp.pending } : null;
const tally = {};
const count = (k, n) => { tally[k] = (tally[k] || 0) + (n === undefined ? 1 : n); };

const forgeTroops = baseCards.filter(c => c.cardType === "troop").map(c => c.name);
const deckOthers = baseCards.filter(c => /^(equipment|command|aether)$/.test(c.cardType)).map(c => c.name);
function someStock(){ const b = L.bag(); for(let r = 0; r < 6; r++) b.parts.troop[r] = chance(0.75) ? pick([0, 4, 12, 40, 120]) : 0; b.shards = ri(0, 30); return b; }
function someTeam(trip){
  const team = { name: pick(["Vanguard", "Second Wave", "Night Shift"]) + " " + (trip + 1), level: ri(1, 3), heroes: [], consumables: {}, deck: {} };
  for(let n = ri(1, 3); n > 0; n--){ const h = pick(heroNames); if(team.heroes.indexOf(h) < 0) team.heroes.push(h); }
  for(let n = ri(0, 3); n > 0; n--) team.consumables[pick(consNames)] = ri(1, 2);
  const mine = WS.list().map(d => d.name);
  for(let n = ri(0, 3); n > 0; n--){ const d = pick(mine); team.deck[d] = ri(1, 5); }
  for(let n = ri(0, 4); n > 0; n--) team.deck[pick(deckOthers)] = ri(1, 2);
  if(chance(0.1)) team.deck[pick(forgeTroops)] = ri(1, 2);
  if(chance(0.04)) team.deck["No Such Card"] = 1;
  if(chance(0.04)) team.heroes = [];
  return team;
}
/* the plan for leaving, on its own: many teams, designs and stockpiles */
for(let i = 0; i < 300; i++){
  fresh(); DESIGNS = someDesigns(); store["keter-app-designs"] = JSON.stringify(DESIGNS);
  const prog0 = chance(0.6) ? randomProg() : { bp: {}, ch: {}, named: {} }, stock0 = chance(0.45) ? L.bag() : someStock(), team = someTeam(0);
  if(i % 4 === 0){
    /* a team that fits, with copies past the starter's free ones: whether the stockpile can pay */
    Object.keys(team.deck).forEach(n => { if(n === "No Such Card" || forgeTroops.indexOf(n) >= 0 || WS.list().some(d => d.name === n)) delete team.deck[n]; });
    team.deck["Frame Trooper"] = ri(5, 9);
    if(!team.heroes.length) team.heroes = [pick(heroNames)];
  }
  setProg(prog0); L.setStock(stock0);
  /* (v14.14) the Heroes recruited: most of them, now and then not one of the team's */
  const dock0 = { heroes: {} }; heroNames.forEach(n => { if(chance(0.92)) dock0.heroes[n] = 1; });
  store[DK.KEY] = JSON.stringify(dock0);
  store["keter-app-loadouts"] = JSON.stringify([loadout(team)]);
  const p = D.plan(0);
  add("plan", [DESIGNS, prog0, stock0, team, dock0], planOut(p)); count(p.ok ? "plans that can go" : p.fits ? "plans short of parts" : "plans refused");
}
const itemNames = baseCards.filter(c => c.cardType === "consumable" || c.cardType === "prototype").map(c => c.name);
function somePre(){
  const out = {};
  for(let n = ri(0, 2); n > 0; n--){
    const ch = pick(chassis), id = "ds_pre" + n, sub = (ch.subtypes || [])[0] || "Melee";
    out[id] = { id, name: ["Hornet", "Bastion"][n - 1] + " Mk " + ri(1, 9), chassis: ch.id, notes: "", prebuilt: true, order: n,
      abilities: [{ name: "Shot", kind: "action", role: sub, energy: 1, range: 4, hit: 6, ap: 4, text: pick(sentences) }] };
  }
  return out;
}
function someDock(){
  const k = { v: 1, reach: pick([0, 0, 1, 2, 3]), upgrades: { exchange: ri(0, 1), starter: pick([0, 0, 1, 2, 3]), insurance: pick([0, 0, 1, 3]), scanner: pick([0, 0, 0, 1, 3]) }, stock: null,
    bounties: [], rot: { pre: 0, items: 0 }, restocks: 0, log: [], heroes: {} };
  if(chance(0.5)) for(let n = ri(1, 3); n > 0; n--) k.bounties.push({ name: pick(foeNames), kind: "enemy", district: "", claimed: false });
  /* (v14.14) every Hero recruited: a wipe loses the team's, and a later trip with them is refused */
  heroNames.forEach(n => { k.heroes[n] = 1; });
  return k;
}
function someInv(pre){
  const v = { cards: {}, pre: {} };
  for(let n = ri(0, 5); n > 0; n--) v.cards[pick(chance(0.7) ? consNames : itemNames)] = ri(1, 3);
  Object.keys(pre).forEach(id => { if(chance(0.6)) v.pre[id] = ri(1, 3); });
  return v;
}
/* what a team packs: what it asks for, as far as the dock holds it; now and then more than that */
function packFor(team){
  const v = DK.inv(), out = {};
  Object.keys(team.consumables).forEach(n => { const k = Math.min(team.consumables[n], v.cards[n] || 0); if(k > 0) out[n] = k; });
  if(chance(0.25)){ const n = pick(itemNames); out[n] = (v.cards[n] || 0) + (chance(0.5) ? 1 : 0); }
  Object.keys(out).forEach(n => { if(!out[n]) delete out[n]; });
  return out;
}
for(let ci = 0; ci < 150; ci++){
  fresh();
  const PRE = somePre();
  DESIGNS = Object.assign(someDesigns(), PRE); store["keter-app-designs"] = JSON.stringify(DESIGNS);
  const sd = ri(1, 1e9), prog0 = chance(0.5) ? randomProg() : { bp: {}, ch: {}, named: {} }, stock0 = someStock();
  prog0.all = chance(0.4);
  prog0.seen = { enemy: {}, district: {}, comp: {} };
  ["1", "2", "3", "4", "5", "6"].forEach(d => { if(chance(0.5)) prog0.seen.district[d] = 1; });
  foeNames.forEach(f => { if(chance(0.6)) prog0.seen.enemy[f] = 1; });
  const dock0 = someDock(), inv0 = someInv(PRE);
  store[DK.KEY] = JSON.stringify(dock0); store[DK.INV_KEY] = JSON.stringify(inv0);
  const preCards = WS.prebuiltCards();
  setProg(prog0); L.seed(sd); L.setStock(stock0);
  const steps = [], visited = {};
  const run = (op, out) => { steps.push({ op, out: clone(out), snap: snap() }); };
  const trips = ri(1, 4);
  for(let trip = 0; trip < trips; trip++){
    const team = someTeam(trip);
    if(trip > 0 && chance(0.4)){
      /* between deployments: something bought at the dock */
      const v = DK.inv(), give = { cards: {}, pre: {} };
      if(chance(0.6)) give.cards[pick(itemNames)] = ri(1, 2);
      const ids = Object.keys(PRE); if(ids.length && chance(0.5)) give.pre[pick(ids)] = ri(1, 2);
      Object.keys(give.cards).forEach(n => { v.cards[n] = (v.cards[n] || 0) + give.cards[n]; });
      Object.keys(give.pre).forEach(id => { v.pre[id] = (v.pre[id] || 0) + give.pre[id]; });
      DK._saveInv(v); run(["give", give], null);
    }
    const pack = packFor(team);
    let left = leave(team, pack); run(["start", team, pack], left);
    if(!left.ok){
      count("teams that couldn't leave");
      /* then as a player would: the starter's free copies for Troops, a Hero if it had none */
      const field = clone(team);
      Object.keys(field.deck).forEach(n => { if(n === "No Such Card" || forgeTroops.indexOf(n) >= 0 || WS.list().some(d => d.name === n)) delete field.deck[n]; });
      field.deck["Frame Trooper"] = ri(1, 4);
      if(!field.heroes.length) field.heroes = [pick(heroNames)];
      const fpack = packFor(field);
      left = leave(field, fpack); run(["start", field, fpack], left);
      if(!left.ok){ count("field copies that couldn't leave either"); continue; }
      count("field copies that left");
    }
    count("deployments");
    let goal = null, budget = ri(8, 60);
    while(budget-- > 0){
      const s = D.cur(); if(!s) break;
      if(s.activity){
        const res = fightResult(s), lost0 = JSON.stringify(s.lost), out = D.fightOver(res);
        if(JSON.stringify(D.cur() ? D.cur().lost : D.last().lost) !== lost0) count("copies lost");
        run(["fight", res], fightOut(out)); count("fight: " + out.next + (out.escaped ? " (escaped)" : out.poiDone ? " (POI cleared)" : ""));
        continue;
      }
      const here = s.pos, c = W.available(here) ? W.contentAt(here) : null, roll = rnd();
      if(roll < 0.04){
        /* things that can't be done, asked anyway */
        const what = pick(["farstep", "blockedstep", "cache", "choose", "home", "enter", "badchoice"]);
        if(what === "farstep"){ const far = pick(keys); run(["step", far], stepOut(D.stepTo(far))); }
        else if(what === "blockedstep"){ const nb = W.neighbours(here).filter(n => !W.isOpen(n)); if(nb.length){ const k = pick(nb); run(["step", k], stepOut(D.stepTo(k))); } }
        else if(what === "cache"){ const r = D.openCache(here); run(["cache", here], r ? { bag: L.norm(r.bag), items: r.items } : null); if(r) count("cache"); }
        else if(what === "choose" || what === "badchoice"){ const i = what === "badchoice" ? 7 : 0, o = D.choose(here, i); run(["choose", here, i], chooseOut(o)); if(o) count("event"); }
        else if(what === "home"){ const h = D.home(); run(["home"], homeOut(h)); if(h && h.ok){ count("home"); break; } }
        else { const sp = D.enterPOI(here); run(["enter", here], specOut(sp)); if(sp) count("POI entered" + (c && c.kind === "poi" ? "" : " (where there was none)")); }
        continue;
      }
      if(c && c.kind === "poi" && chance(0.85)){ const sp = D.enterPOI(here); run(["enter", here], specOut(sp)); count("POI entered" + (c.unique ? " (Unique)" : "")); continue; }
      if(c && c.kind === "cache" && chance(0.9)){ const r = D.openCache(here); run(["cache", here], r ? { bag: L.norm(r.bag), items: r.items } : null); count("cache"); continue; }
      if(c && c.kind === "event" && chance(0.9)){ const ev = D.eventAt(here), i = ri(0, ev.choices.length - 1), o = D.choose(here, i); run(["choose", here, i], chooseOut(o)); count("event" + (o.check ? (o.won ? " (check won)" : " (check failed)") : " (no check)") + (o.fight ? " into a fight" : "")); continue; }
      if(here === M.dock && s.steps > 0 && chance(0.6)){ const h = D.home(); run(["home"], homeOut(h)); count("home"); break; }
      /* somewhere to go: something not yet seen to, or home */
      if(!goal || goal === here || !W.path(here, goal)){
        const near = contentTiles.filter(k => !visited[k] && W.available(k) && W.dist(k, here) <= 9);
        goal = (s.steps > budget || !near.length || chance(0.12)) ? M.dock : pick(near);
        if(goal === here) goal = pick(W.neighbours(here).filter(n => W.isOpen(n)));
      }
      const p = W.path(here, goal), next = p[1], r = D.stepTo(next);
      run(["step", next], stepOut(r)); count("step");
      visited[next] = 1;
      if(r.ambush){
        const sp = D.ambush(r.pos, { tileAmbush: !!r.tileAmbush });
        run(["ambush", r.pos, !!r.tileAmbush], specOut(sp)); count(r.tileAmbush ? "ambush on its tile" : "ambush on the way");
        goal = null;
      }
    }
    const s2 = D.cur();
    if(s2){
      /* still out: give up, or stay out and end the case here */
      if(chance(0.5) && !s2.activity){ const w = D.wipe(); run(["wipe"], { ok: w.ok, lostHaul: L.norm(w.lostHaul), lostItems: w.lostItems, n: w.n, dock: dockOut(w.dock), lostPack: w.lostPack || null }); count("given up"); }
      else break;
    }
  }
  add("deployment", [sd, prog0, steps.map(st => st.op), DESIGNS, stock0, dock0, inv0, preCards], steps.map(st => ({ out: st.out, snap: st.snap })));
}
function chooseOut(o){ return o ? { event: o.event.id, label: o.choice.label, check: o.check, roll: o.roll, won: !!o.won, text: o.text, got: L.norm(o.got), items: o.items, lost: o.lost ? L.norm(o.lost) : null, fight: !!o.fight, spec: specOut(o.spec) } : null; }
function homeOut(h){ return h ? { ok: !!h.ok, why: h.why || null, haul: h.haul ? L.norm(h.haul) : null, items: h.items || null, n: h.n || null, dock: dockOut(h.dock) } : null; }
function dockOut(o){
  if(o){ if((o.bounties || []).length) count("bounties paid", o.bounties.length); if(o.insured) count("insured"); if(o.restocked) count("restocked"); if(o.reach != null) count("reach extended"); if(o.lostHeroes) count("Heroes lost"); }
  return o ? { reach: o.reach == null ? null : o.reach, bounties: (o.bounties || []).map(b => ({ name: b.name, bag: L.norm(b.bag) })), insured: o.insured ? L.norm(o.insured) : null, restocked: !!o.restocked, lostHeroes: o.lostHeroes || null } : null; }

const out = path.join(ROOT, "game", "tests", "fixtures", "world_cases.json");
fs.writeFileSync(out, JSON.stringify({ made: "world.js, deploy.js, dock.js, progress.js, loot.js and keywords.js", map: M.name, tiles: keys.length, floors: floors.length, cases }));
const counts = {}; cases.forEach(c => counts[c.fn] = (counts[c.fn] || 0) + 1);
console.log(JSON.stringify({ file: out, cases: cases.length, counts, deployments: tally }));
