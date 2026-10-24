#!/usr/bin/env node
/* Generates the cases that prove the game's dock is the Companion's: dock.js
   run exactly as it is, with progress.js, loot.js, workshop.js and the rest
   it leans on, and a stand-in for the browser's storage.

   Each case starts from a dock as a player might have it: a stockpile, a
   reach, upgrades, what it holds (Consumables, Prototypes, pre-built copies),
   blueprints and chassis owned and named, the Districts fought in and the
   Enemies met, tables changed in Dev Mode or not, pre-built Troops, and now
   and then a Strike Team out. Then a run of what a player does there:
   restocking, buying and selling components, lots, blueprints, chassis,
   Consumables, Prototypes and pre-built copies; recruiting Heroes (v14.14);
   Reclaiming; upgrades; a deployment coming home (reach, bounties paid) or
   wiped out (insurance, and the recruited Heroes who went out lost);
   and the effects the rest of the game asks for. After each, what it said,
   and the dock, its stockpile and what it holds, compared.

   Also the dock's tables, read from what Dev Mode may have saved.

     node make_dock_cases.js <the export's content folder>

   Writes game/tests/fixtures/dock_cases.json; the game's tests/dock_diff.gd
   replays every case and compares. Deterministic: the same sources and
   export give the same cases. */
"use strict";
const fs = require("fs"), path = require("path"), vm = require("vm");
const ROOT = __dirname, DIR = process.argv[2];
if(!DIR){ console.error("usage: node make_dock_cases.js <content folder>"); process.exit(2); }
const load = n => JSON.parse(fs.readFileSync(path.join(DIR, n + ".json"), "utf8"));
const cards = load("cards").cards, world = load("world_map"), pools = load("pools").pools, chassis = load("chassis").chassis, tables = load("tables");

const store = {};
const sb = { Math, JSON, String, Object, Array, parseInt, parseFloat, isNaN, isFinite, Date, Number, RegExp, console,
  localStorage: { getItem: k => (k in store ? store[k] : null), setItem: (k, v) => { store[k] = String(v); }, removeItem: k => { delete store[k]; } } };
sb.window = sb;
vm.createContext(sb);
const chassisById = {}; chassis.forEach(c => { chassisById[c.id] = c; });
function resetStore(){
  Object.keys(store).forEach(k => delete store[k]);
  store["keter-app-world"] = JSON.stringify(world.map);
  store["keter-app-world-tables"] = JSON.stringify(world.tables);
  store["keter-app-pools"] = JSON.stringify(pools);
  store["keter-app-chassis"] = JSON.stringify(chassisById);
  if(tables.loot) store["keter-app-loot"] = JSON.stringify(tables.loot);
  if(tables.workshop) store["keter-app-workshop"] = JSON.stringify(tables.workshop);
}
resetStore();
["keywords.js", "scoring.js", "loot.js", "progress.js", "chassis.js", "skins.js", "workshop.js", "world.js", "deploy.js", "dock.js"].forEach(f => vm.runInContext(fs.readFileSync(path.join(ROOT, f), "utf8"), sb));
const W = sb.KETER_WORLD, D = sb.KETER_DEPLOY, P = sb.KETER_PROG, L = sb.KETER_LOOT, K = sb.KETER_KW, WS = sb.KETER_WORKSHOP, DK = sb.KETER_DOCK;
/* (v14.9) the cards that can be found as loot: the export's own */
P.useCards(() => cards);
const baseCards = cards.filter(c => c._src !== "design" && c._src !== "prebuilt");
sb.KETER_ALLCARDS = () => baseCards.concat(WS.cards());
if(K.registerArchetypes) cards.forEach(c => K.registerArchetypes(c.archetypes));
const clone = o => JSON.parse(JSON.stringify(o === undefined ? null : o));

let seedA = 20261009;
function rnd(){ seedA = (seedA + 0x6D2B79F5) >>> 0; let t = seedA; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }
const ri = (a, b) => a + Math.floor(rnd() * (b - a + 1)), pick = a => a[Math.floor(rnd() * a.length)], chance = p => rnd() < p;

const cases = [];
const add = (fn, args, result) => cases.push({ fn, args: clone(args), result: clone(result) });
const tally = {};
const count = (k, n) => { tally[k] = (tally[k] || 0) + (n === undefined ? 1 : n); };

/* ---- the dock's tables, from what Dev Mode may have saved ---- */
const itemNames = baseCards.filter(c => c.cardType === "consumable" || c.cardType === "prototype").map(c => c.name);
/* (v14.19) the cards a deployment must hold or craft */
const limitedNames = baseCards.filter(c => DK.isLimited(c)).map(c => c.name);
const heroNames = baseCards.filter(c => c.cardType === "hero").map(c => c.name);
const weird = [null, "", "abc", "12", -3, 0, 2.5, 7, "1e1", true, [], {}];
function someTables(){
  if(chance(0.35)) return null;
  const m = {};
  if(chance(0.3)) m.price = chance(0.8) ? [ri(1, 9), ri(10, 20), ri(30, 50), ri(80, 120), ri(200, 300), ri(500, 700)] : [5, "x", null, 40, -2];
  ["sell", "bpFirst", "bpLater", "chassis", "preMult", "lots", "lotMax", "bpOffers", "chOffers", "itemsOnOffer", "preOnOffer", "reclaimUp", "reclaimSwap"].forEach(k => {
    if(chance(0.25)) m[k] = chance(0.75) ? pick({ sell: [0.25, 0.5, 0.75], bpFirst: [100, 150, 200], bpLater: [1, 1.25, 2], chassis: [200, 300], preMult: [1, 1.5, 2],
      lots: [0, 2, 3, 5], lotMax: [1, 3, 5], bpOffers: [0, 1, 2, 3], chOffers: [0, 1, 2], itemsOnOffer: [1, 3, 5], preOnOffer: [0, 2, 3], reclaimUp: [2, 3, 4, 2.6], reclaimSwap: [1, 2, 3, 0.4] }[k]) : pick(weird);
  });
  if(chance(0.3)) m.bounty = { shards: { enemy: ri(5, 30), boss: chance(0.5) ? "x" : 200 }, n: chance(0.5) ? { elite: ri(1, 4) } : null };
  /* (v14.14) recruiting */
  if(chance(0.2)) m.heroPrice = chance(0.8) ? [ri(10, 50), ri(50, 100), ri(100, 200), 300, ri(400, 700), 1200] : [40, "x", null, -5, 600];
  if(chance(0.2)) m.heroOnOffer = chance(0.8) ? pick([0, 1, 2, 3, 5, 9]) : pick(weird);
  if(chance(0.2)) m.free = chance(0.8) ? heroNames.filter(() => chance(0.4)) : pick([[], ["Nobody", 3, null, ""], "Dock Hand"]);
  /* (v14.19) crafting and the starter stash */
  if(chance(0.25)) m.craft = chance(0.8) ? { shards: chance(0.7) ? [ri(5, 30), ri(30, 60), 100, 250, 500, ri(900, 1500)] : [5, "x", null, -3, 2.5, 7], parts: chance(0.6) ? [1, 2, 2, 3, 3, 4] : [1, "2", 2.7, null, -1, 3], noParts: pick([1, 1.5, 2, 3, "2", "x", 0, null]) } : pick([null, "x", [], {}]);
  if(chance(0.2)) { m.starterStash = {}; for(let n = ri(0, 5); n > 0; n--) m.starterStash[chance(0.9) ? pick(limitedNames) : "Nobody"] = pick([1, 2, 3, "2", 0, -1, "x", null]); if(chance(0.1)) m.starterStash = pick([[], "x", null]); }
  if(chance(0.2)) m.rareOffer = pick([0, 1, 2, 3, 5, "3", "x", -2, 2.6, null]);
  if(chance(0.6)){ m.items = []; for(let n = ri(0, 6); n > 0; n--) m.items.push(chance(0.9) ? { name: pick(itemNames), price: chance(0.8) ? ri(5, 60) : pick(weird) } : pick([null, {}, { price: 3 }])); }
  if(chance(0.25)) m.effect = { starter: [5, 7, 12], scanner: chance(0.5) ? [2, 2, 5] : [1, "x"], insurance: [15, 25, "40"] };
  if(chance(0.25)) m.cost = { exchange: [[100, "troop", 0, 5], [300, "nope", 1, 2], "bad"], scanner: [[50, "aether", "2", "3"], [60, "aether", 9, -1], [70, "equipment", 2, 1]] };
  return m;
}
for(let i = 0; i < 200; i++){
  const m = someTables(); resetStore();
  if(m) store[DK.TAB_KEY] = JSON.stringify(m);
  add("tables", [m], DK.tables());
}

/* ---- dock runs ---- */
const foes = baseCards.filter(c => P.isFoe(c)).map(c => c.name);
const poolish = Object.keys(pools).reduce((a, d) => a.concat(pools[d].items || []), []);
const allItems = P.allItems();
const sentences = ["[[target enemy]] takes [[damage 2]].", "[[target enemy]] takes [[damage 2]] with [[Burst 2]].", "[[this Unit]] gains [[heal 1]].",
  "[[target enemy]] takes [[damage 3]] with [[Pierce]].", "[[target ally]] gains [[heal 2]].", "[[target enemy]] gains [[Marked]] for [[turns 2]]."];
function somePrebuilts(){
  const out = {};
  for(let n = ri(0, 5); n > 0; n--){
    const ch = pick(chassis), id = "ds_pre" + n + "_" + ri(1, 99), sub = (ch.subtypes || [])[0] || "Melee";
    const ab = [{ name: "Shot", kind: "action", role: sub, energy: pick([1, 1, 2]), range: pick([3, 4, 5]), hit: pick([5, 6, 7]), ap: pick([3, 4]), text: pick(sentences) }];
    if(chance(0.4)) ab.push({ name: "", kind: "passive", role: "", text: pick(sentences) });
    out[id] = { id, name: pick(["Lancer", "Hornet", "Bastion", "Wisp", "Rook"]) + " Mk " + n, chassis: ch.id, notes: "", prebuilt: true, order: ri(0, 6), abilities: ab };
  }
  return out;
}
function someProg(){
  const s = { bp: {}, ch: {}, named: {}, seen: { enemy: {}, district: {}, comp: {} }, all: chance(0.08) };
  for(let n = ri(0, 6); n > 0; n--){ const o = P.parseItem(pick(chance(0.8) ? poolish : allItems)); if(!o) continue; if(o.kind === "bp") s.bp[o.name] = ri(1, 3); else s.ch[o.id] = true; }
  for(let n = ri(0, 2); n > 0; n--){ const o = P.parseItem(pick(poolish)); if(o) s.named[o.kind === "bp" ? "bp:" + o.name : "ch:" + o.id] = 1; }
  ["1", "2", "3", "4", "5", "6"].forEach(d => { if(chance(0.45)) s.seen.district[d] = 1; });
  if(chance(0.05)) s.seen.district[""] = 1;
  foes.forEach(f => { if(chance(0.5)) s.seen.enemy[f] = 1; });
  return s;
}
function someStock(){ const b = L.bag(); b.shards = pick([0, 10, 60, 150, 400, 1200, 5000]); L.TYPES.forEach(ty => { for(let r = 0; r < 6; r++) b.parts[ty.id][r] = chance(0.5) ? pick([0, 1, 2, 3, 6, 10, 30]) : 0; }); return b; }
function someDock(){
  const s = { v: 1, reach: pick([0, 0, 1, 2, 3, 4, 5, 6]), upgrades: { exchange: ri(0, 3), starter: ri(0, 3), insurance: ri(0, 3), scanner: ri(0, 3) }, stock: null, bounties: [], rot: { pre: ri(0, 4), items: ri(0, 4) }, restocks: ri(0, 5), log: [] };
  if(chance(0.1)) s.upgrades.exchange = "2";
  if(chance(0.05)) delete s.rot;
  /* (v14.14) Heroes recruited, or a dock from before recruiting */
  if(chance(0.8)){ s.heroes = {}; heroNames.forEach(n => { if(chance(0.25)) s.heroes[n] = 1; }); }
  if(chance(0.04)) s.heroes = pick([[], "x", null]);
  /* (v14.19) a stash begun already, now and then with rare cards still on offer */
  if(chance(0.3)) s.stash = { v: 1, offer: chance(0.5) ? DK.rares().filter(() => chance(0.2)).slice(0, 3) : [], picked: null, old: false };
  return s;
}
function someInv(pre){
  const v = { cards: {}, pre: {} };
  for(let n = ri(0, 4); n > 0; n--) v.cards[pick(itemNames)] = ri(1, 4);
  for(let n = ri(0, 3); n > 0; n--) v.cards[pick(limitedNames)] = ri(1, 3);
  Object.keys(pre).forEach(id => { if(chance(0.3)) v.pre[id] = ri(1, 3); });
  return v;
}
/* what a case looks like after each step: no dates */
function snap(){
  const s = DK.state(), st = s.stock ? Object.assign({}, s.stock) : null;
  if(st) delete st.made;
  return { dock: { reach: s.reach, upgrades: s.upgrades, stock: st, bounties: s.bounties, rot: s.rot, restocks: s.restocks, log: s.log.map(l => l.text), heroes: s.heroes, stash: s.stash || null },
    inv: DK.inv(), stock: L.stock(), prog: (function(){ const p = P.state(); return { bp: p.bp, ch: p.ch, named: p.named }; })() };
}
const types = L.TYPES.map(t => t.id);
function someOp(){
  const st = DK.state().stock || { lots: [], bps: [], chs: [], items: [], pre: [] };
  const lotsNow = st.lots || [];
  const r = rnd();
  if(r < 0.07) return ["restock"];
  if(rnd() < 0.12) return ["recruit", chance(0.8) && (st.heroes || []).length ? pick(st.heroes) : pick(heroNames.concat(["Nobody"]))];
  if(rnd() < 0.02) return ["oldStock"];
  /* (v14.19) crafting, the stash beginning, a rare picked */
  if(rnd() < 0.10) return ["craft", chance(0.85) ? pick(limitedNames) : pick(itemNames.concat(heroNames, ["Nobody"])), pick([1, 1, 2, 3, "2", 0, -1, "x"])];
  if(rnd() < 0.04){ const needs = []; for(let n = ri(0, 3); n > 0; n--){ const nd = {}; for(let k = ri(0, 4); k > 0; k--) nd[pick(limitedNames)] = pick([1, 2, 3, "2", 0]); needs.push(nd); } return ["beginStash", chance(0.5), needs]; }
  if(rnd() < 0.05){ const s = DK.state(); const off = (s.stash && s.stash.offer) || []; return ["pickRare", chance(0.8) && off.length ? pick(off) : pick(limitedNames.concat(["Nobody"]))]; }
  if(r < 0.10) return ["stock"];
  if(r < 0.12) return ["seeStock"];
  if(r < 0.24){ const common = chance(0.4) || !lotsNow.length; if(common) return ["buyParts", pick(types), 0, pick([1, 1, 2, 5, 40, "3", 0])];
    const li = ri(0, lotsNow.length - 1), lot = lotsNow[li]; return ["buyParts", chance(0.85) ? lot.type : pick(types), chance(0.9) ? lot.rarity : ri(1, 5), pick([1, 1, 2, 3, 9]), chance(0.9) ? li : ri(-1, 6)]; }
  if(r < 0.30) return ["sellParts", pick(types), ri(0, 5), pick([1, 1, 2, 4, 50])];
  if(r < 0.38) return ["buyItem", chance(0.85) && (st.bps.length + st.chs.length) ? pick(st.bps.concat(st.chs)) : pick(poolish)];
  if(r < 0.47) return ["buyCard", chance(0.85) && st.items.length ? pick(st.items) : pick(itemNames), pick([1, 1, 2, 3])];
  if(r < 0.53) return ["sellCard", chance(0.7) && Object.keys(DK.inv().cards).length ? pick(Object.keys(DK.inv().cards)) : pick(itemNames), pick([1, 1, 2, 5])];
  if(r < 0.60) return ["buyPre", chance(0.85) && st.pre.length ? pick(st.pre) : "ds_nope", pick([1, 1, 2, 3])];
  if(r < 0.68) return ["combine", pick(types), ri(0, 4), pick([1, 1, 2, 5])];
  if(r < 0.74) return ["swap", pick(types), pick(types), ri(0, 3), pick([1, 1, 2, 4])];
  if(r < 0.82) return ["upgrade", pick(["exchange", "starter", "insurance", "scanner"])];
  if(r < 0.90){
    const result = pick(["home", "home", "wipe", "abandoned"]);
    const kills = []; for(let n = ri(0, 5); n > 0; n--) kills.push(chance(0.85) ? { name: chance(0.6) && DK.state().bounties.length ? pick(DK.state().bounties).name : pick(foes), skull: ri(1, 6) } : { name: pick(foes), skull: "3" });
    const haul = L.bag(); haul.shards = ri(0, 400); L.TYPES.forEach(ty => { haul.parts[ty.id][ri(0, 3)] = ri(0, 12); });
    const heroes = chance(0.85) ? heroNames.filter(() => chance(0.3)) : null;
    return ["ended", { result, maxSkull: ri(0, 6), kills, haul: chance(0.9) ? haul : null, explored: chance(0.6), heroes }];
  }
  if(r < 0.95) return ["claim", [{ name: chance(0.7) && DK.state().bounties.length ? pick(DK.state().bounties).name : pick(foes), skull: ri(1, 6) }]];
  return ["effects"];
}
function doOp(op){
  switch(op[0]){
    case "restock": return DK.restock();
    case "stock": return DK.stock();
    case "seeStock": DK.seeStock(); return null;
    case "buyParts": return DK.buyParts(op[1], op[2], op[3], op[4]);
    case "sellParts": return DK.sellParts(op[1], op[2], op[3]);
    case "buyItem": return DK.buyItem(op[1]);
    case "buyCard": return DK.buyCard(op[1], op[2]);
    case "sellCard": return DK.sellCard(op[1], op[2]);
    case "buyPre": return DK.buyPre(op[1], op[2]);
    case "combine": return DK.combine(op[1], op[2], op[3]);
    case "swap": return DK.swap(op[1], op[2], op[3], op[4]);
    case "upgrade": return DK.upgrade(op[1]);
    case "ended": return DK.deploymentEnded(op[1]);
    case "recruit": return DK.recruit(op[1]);
    case "craft": return DK.craft(op[1], op[2]);
    case "beginStash": return DK.beginStash(op[1], op[2]);
    case "pickRare": return DK.pickRare(op[1]);
    /* a stock laid out before recruiting: its Heroes come the next time it is looked at */
    case "oldStock": { const s = DK.state(); if(s.stock){ delete s.stock.heroes; delete s.stock.hired; DK._save(s); } return null; }
    case "claim": return DK.claim(op[1]);
    case "effects": {
      const st = DK.state().stock || { bps: [], chs: [], pre: [], items: [] };
      return { starterFree: DK.starterFree(), scanRange: DK.scanRange(), insurance: DK.insurance(), reachRarity: DK.reachRarity(),
        levels: DK.UPGRADES.map(u => DK.level(u.id)), effects: DK.UPGRADES.map(u => DK.effect(u.id)), next: DK.UPGRADES.map(u => DK.nextCost(u.id)),
        bpPrices: st.bps.concat(st.chs).concat(["bp:Burst:2", "bp:Burst:3", "ch:ch_test_verdant", "nope"]).map(it => DK.bpPrice(it)),
        preCosts: WS.prebuilts().map(d => DK.preCost(d)), itemPrices: itemNames.map(n => DK.itemPrice(n)),
        heroPrices: heroNames.concat(["Nobody"]).map(n => DK.heroPrice(n)), owns: heroNames.map(n => DK.owns(n)),
        unowned: DK.unowned(heroNames.concat(["Nobody"])), recruitable: DK.recruitable().map(c => c.name), owned: DK.ownedHeroes(),
        craftCosts: limitedNames.concat(itemNames.slice(0, 3), ["Nobody"]).map(n => DK.craftCost(n)), rares: DK.rares(),
        bountyPay: ["enemy", "elite", "miniboss", "boss", "nope"].map(k => { const sk = pick([0, 1, 3, 6, 7, "2", null]); return { kind: k, skull: sk, pay: DK.bountyPay(k, sk) }; }), closed: DK.closed() };
    }
  }
  return null;
}
for(let ci = 0; ci < 400; ci++){
  resetStore();
  const sd = ri(1, 1e9), m = someTables(), prog = someProg(), stock0 = someStock(), dock0 = someDock(), pre = somePrebuilts(), inv0 = someInv(pre), out = chance(0.12);
  if(m) store[DK.TAB_KEY] = JSON.stringify(m);
  store[P.PROG_KEY] = JSON.stringify(prog);
  store[DK.KEY] = JSON.stringify(dock0);
  store[DK.INV_KEY] = JSON.stringify(inv0);
  store["keter-app-designs"] = JSON.stringify(pre);
  L.setStock(stock0); L.seed(sd);
  if(out) store[D.KEY] = JSON.stringify({ active: true });
  const preCards = WS.prebuiltCards();
  const steps = [];
  for(let n = ri(4, 22); n > 0; n--){
    const op = someOp(); let res;
    try{ res = doOp(op); }catch(e){ res = { threw: String(e) }; count("threw"); }
    if(res && res.ok === false) count("refused: " + op[0]); else count(op[0]);
    const sn = snap();
    if(op[0] === "ended" && res && res.bounties && res.bounties.length) count("bounties paid", res.bounties.length);
    if(op[0] === "ended" && res && res.insured) count("insured");
    if(op[0] === "ended" && res && res.lostHeroes) count("Heroes lost");
    steps.push({ op, out: clone(res), snap: sn });
  }
  add("dock", [sd, m, prog, stock0, dock0, inv0, preCards, out], steps);
}

const outFile = path.join(ROOT, "game", "tests", "fixtures", "dock_cases.json");
fs.writeFileSync(outFile, JSON.stringify({ made: "dock.js, with progress.js, workshop.js, loot.js and keywords.js", cases }));
const counts = {}; cases.forEach(c => counts[c.fn] = (counts[c.fn] || 0) + 1);
console.log(JSON.stringify({ file: outFile, cases: cases.length, counts, seen: tally }));
