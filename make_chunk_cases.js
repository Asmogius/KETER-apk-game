#!/usr/bin/env node
/* Generates the cases that prove the game grows a battlefield from chunks as
   the Companion does (chunkgen.js, run here exactly as it is): every size and
   Skull Level from many seeds, from the export's chunks; and from chunks made
   awkward on purpose (tiles drawn outside the hexagon, walls on a chunk's edge,
   colours under labels of their own, sides all walled, a District with no
   Enemy chunk). Writes game/tests/fixtures/chunk_cases.json; the game's
   tests/chunk_diff.gd grows each again and compares.

     node make_chunk_cases.js <the export's content folder>  */
"use strict";
const fs = require("fs"), path = require("path"), vm = require("vm");
const ROOT = __dirname, DIR = process.argv[2];
if(!DIR){ console.error("usage: node make_chunk_cases.js <content folder>"); process.exit(2); }
const floors = JSON.parse(fs.readFileSync(path.join(DIR, "floors.json"), "utf8")).floors;
const sb = { Math, JSON, String, Object, Array, parseInt, isNaN, console }; sb.window = sb;
vm.createContext(sb);
vm.runInContext(fs.readFileSync(path.join(ROOT, "chunkgen.js"), "utf8"), sb);
const G = sb.KETER_CHUNKGEN;
const clone = o => JSON.parse(JSON.stringify(o === undefined ? null : o));
const chunks = floors.filter(f => G.isChunk(f));
if(chunks.length < 4){ console.error("the export has too few chunks (" + chunks.length + ")"); process.exit(1); }

/* the awkward ones: copies of the export's own, changed */
const odd = clone(chunks).map((c, i) => { c.name = "Odd " + i + " " + c.name; c.district = "5"; return c; });
odd.forEach((c, i) => {
  if(i % 4 === 0) c.hexes.push(["4,0", {c: 1}], ["0,4", {}]);                       // drawn outside the hexagon
  if(i % 4 === 1) c.walls.push(["3,-3|4,-4", -1], ["0,3|0,4", -1], ["-3,0|-4,0", -1]); // walls on its edge
  if(i % 4 === 2){ const lab = {}; Object.keys(c.colorLabels).forEach(k => { lab[k] = String(c.colorLabels[k]).toUpperCase(); }); c.colorLabels = lab; }
  if(i % 5 === 3) c.chunk.sides = [false, false, true, false, false, false];
  if(i % 3 === 0) c.chunk.skullMin = 3;
});
const noFoes = clone(chunks).filter(c => c.chunk.role !== "enemy").map(c => { c.name = "Lone " + c.name; c.district = "6"; return c; });
const sets = { exported: chunks, odd: chunks.concat(odd), lone: noFoes };

let seedA = 20261021;
function rnd(){ seedA = (seedA + 0x6D2B79F5) >>> 0; let t = seedA; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }
const cases = [];
const sizes = ["small", "medium", "large"];
for(let i = 0; i < 120; i++){
  const seed = Math.floor(rnd() * 4294967296) >>> 0, size = sizes[i % 3], skull = 1 + (i % 6);
  cases.push({ set: "exported", args: ["3", skull, size, seed], result: clone(G.generate(chunks, "3", skull, size, seed)) });
}
for(let i = 0; i < 60; i++){
  const seed = Math.floor(rnd() * 4294967296) >>> 0, size = sizes[i % 3], skull = 1 + (i % 6);
  cases.push({ set: "odd", args: ["5", skull, size, seed], result: clone(G.generate(sets.odd, "5", skull, size, seed)) });
}
for(let i = 0; i < 6; i++){
  const seed = Math.floor(rnd() * 4294967296) >>> 0;
  cases.push({ set: "lone", args: ["6", 2, "medium", seed], result: clone(G.generate(noFoes, "6", 2, "medium", seed)) });
  cases.push({ set: "exported", args: ["", 2, "medium", seed], result: clone(G.generate(chunks, "", 2, "medium", seed)) });
}
/* and from a key */
for(let i = 0; i < 12; i++){
  const seed = Math.floor(rnd() * 4294967296) >>> 0, k = G.genKey("3", 1 + (i % 6), sizes[i % 3], seed);
  cases.push({ set: "exported", key: k, result: clone(G.fromKey(chunks, k)) });
}
const out = path.join(ROOT, "game", "tests", "fixtures", "chunk_cases.json");
fs.writeFileSync(out, JSON.stringify({ sets, cases }));
const made = cases.filter(c => c.result).length;
console.log("chunk cases: " + cases.length + " (" + made + " grown, " + (cases.length - made) + " not), from " + chunks.length + " chunks");
