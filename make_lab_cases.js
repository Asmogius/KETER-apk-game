#!/usr/bin/env node
/* Generates the cases that prove the game builds a Lab card as the Companion
   does (lab.js, run here exactly as it is, on lab_data.js): heroes, Troops,
   Enemies, Elites and Mini-Bosses of every role, size, rarity and Skull
   Level, with library abilities at every tier, signature abilities, trades
   and tokens; Action cards; and every menu item of the other types, with
   Equipment's triggers. A share are broken on purpose (tiers over the cap,
   abilities a role can't take, too many, a signature below Legendary, trades
   that aren't, ids that don't exist), so the checks are compared too. Writes
   game/tests/fixtures/lab_cases.json; the game's tests/lab_diff.gd builds each
   again and compares.

     node make_lab_cases.js  */
"use strict";
const fs = require("fs"), path = require("path"), vm = require("vm");
const ROOT = __dirname;
const sb = { Math, JSON, String, Object, Array, parseInt, isNaN, console, localStorage: { getItem: () => null, setItem(){}, removeItem(){} } };
sb.window = sb;
vm.createContext(sb);
vm.runInContext(fs.readFileSync(path.join(ROOT, "lab_data.js"), "utf8"), sb);
vm.runInContext(fs.readFileSync(path.join(ROOT, "lab.js"), "utf8"), sb);
const L = sb.KETER_LAB, D = sb.KETER_LAB_DATA;
const clone = o => JSON.parse(JSON.stringify(o === undefined ? null : o));

let seedA = 20261031;
function rnd(){ seedA = (seedA + 0x6D2B79F5) >>> 0; let t = seedA; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }
const pick = a => a[Math.floor(rnd() * a.length)];
const chance = p => rnd() < p;
const ri = (a, b) => a + Math.floor(rnd() * (b - a + 1));

const ids = D.library.map(a => a.id);
const sig = () => ({ name: pick(["Spin-Up", "Ledger Tithe", "Overwatch", "Doom.exe"]), kind: pick(["passive", "attack", "support", "aura"]),
  role: chance(0.2) ? pick(["melee", "ranged"]) : undefined, text: "[[this Unit]] gains [[DMG +" + ri(1, 3) + "]].", points: ri(3, 12),
  dmg: chance(0.5) ? ri(-2, 4) : undefined, rng: chance(0.3) ? ri(0, 3) : undefined, hit: chance(0.3) ? ri(-2, 1) : undefined, e: chance(0.5) ? ri(0, 3) : undefined });
function abilities(n, role, broken){
  const out = [], pool = broken ? ids.concat(["Z9"]) : ids.filter(id => D.library.find(a => a.id === id).roles.indexOf(role) >= 0);
  for(let i = 0; i < n; i++) out.push([pick(pool), broken ? ri(0, 4) : ri(1, 3)]);
  return out;
}
function trade(broken){
  if(!broken){ const t = pick(D.trades); return chance(0.5) ? t.slice() : [t[2], t[3], t[0], t[1]]; }
  return pick([["hp", 9, "ms", 1], ["ac", 1, "hp", 2], [], ["hp", 4, "ms"]]);
}

const cases = [];
const add = b => cases.push({ build: clone(b), result: clone(L.compile(b)) });

/* units */
for(let i = 0; i < 900; i++){
  const type = pick(["hero", "troop", "troop", "enemy", "enemy", "elite", "miniboss"]), broken = chance(0.25);
  const b = { type, role: broken && chance(0.1) ? "sniper" : pick(D.roles) };
  if(type === "hero" || type === "troop"){
    b.rarity = broken && chance(0.1) ? "rarest" : pick(D.rarities);
    if(type === "troop") b.size = broken && chance(0.1) ? "huge" : pick(D.sizes);
  } else {
    b.skull = ri(1, 6); b.size = pick(Object.keys(D.enemySize));
    if(chance(0.15)) b.grade = pick(["enemy", "elite", "miniboss"]);
  }
  b.abilities = abilities(ri(0, broken ? 4 : 2), b.role, broken);
  if((type === "hero" || type === "troop") && chance(0.25) && b.abilities.length) b.abilities[0] = ["SIG", sig()];
  if(chance(0.3)) b.trade = trade(broken);
  if(chance(0.3)) b.token = broken && chance(0.3) ? "Gremlin" : pick(D.tokens);
  add(b);
}
/* Action cards */
for(let i = 0; i < 200; i++){
  const broken = chance(0.2), b = { type: "action", rarity: pick(D.rarities) };
  b.ability = chance(0.08) ? ["SIG", sig()] : [broken && chance(0.3) ? "Z9" : pick(ids), broken ? ri(0, 4) : ri(1, 3)];
  if(chance(0.2)) b.token = pick(D.tokens);
  add(b);
}
/* every menu item, at every tier and rarity it might be asked for */
Object.keys(D.menus).forEach(type => D.menus[type].forEach(m => {
  for(let t = 1; t <= 3; t++){
    const b = { type, menu: m.id, tier: t, rarity: pick(D.rarities) };
    if(type === "equipment" && chance(0.5)) b.trigger = pick(D.equipTriggers).id;
    add(b);
  }
}));
for(let i = 0; i < 40; i++){
  const type = pick(Object.keys(D.menus)), b = { type, menu: chance(0.2) ? "X1" : pick(D.menus[type]).id, tier: ri(0, 4), rarity: pick(D.rarities) };
  if(chance(0.4)) b.trigger = chance(0.2) ? "QT9" : pick(D.equipTriggers).id;
  add(b);
}
add({ type: "boss", role: "brute" });

const out = path.join(ROOT, "game", "tests", "fixtures", "lab_cases.json");
fs.writeFileSync(out, JSON.stringify({ version: D.version, cases }));
const broken = cases.filter(c => c.result.problems.length).length;
console.log("lab cases: " + cases.length + " (" + broken + " with problems), systems " + D.version);
