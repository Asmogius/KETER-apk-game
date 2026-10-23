#!/usr/bin/env node
/* Generates the cases that prove the game's Workshop is the Companion's:
   what an ability is worth (scoring.js), whether a design fits its chassis
   (chassis.js), a design's power, its fit check, what a copy costs and how
   many the stockpile could pay for, a design as a Troop card (workshop.js),
   which blueprint levels a design needs and which are missing, research
   (progress.js), the look a design wears (skins.js), and the keyword builder
   itself (builder.js): hundreds of walks through it, tap by tap, comparing
   after every tap what it offers, how the sentence reads, what is wrong with
   it, and what Insert gives.

   Every module is run here exactly as it is, with a stand-in for the
   browser's storage and, for the builder, a page that is only what the
   builder touches: its taps arrive as click events, and what it draws is read
   back out of its HTML.

   Writes game/tests/fixtures/workshop_cases.json; the game's
   tests/workshop_diff.gd replays every case and compares.

     node make_workshop_cases.js <the export's content folder>

   Deterministic: the same sources and export give the same cases. */
"use strict";
const fs = require("fs"), path = require("path"), vm = require("vm");
const ROOT = __dirname, DIR = process.argv[2];
if(!DIR){ console.error("usage: node make_workshop_cases.js <content folder>"); process.exit(2); }
const load = (n, d) => { const f = path.join(DIR, n + ".json"); return fs.existsSync(f) ? JSON.parse(fs.readFileSync(f, "utf8")) : d; };
const cards = load("cards").cards, chassis = load("chassis").chassis, pools = load("pools").pools, tables = load("tables"),
  skinsIn = (load("skins", { skins: [] }).skins) || [], manifest = load("manifest", { files: [] });
const pictures = {}; (manifest.files || []).forEach(f => { if(f && f.picture) pictures[f.picture] = 1; });

/* ---- the Companion's modules, with storage that is only a table ---- */
const store = {};
const sb = { Math, JSON, String, Object, Array, parseInt, parseFloat, isNaN, isFinite, Date, Number, RegExp, console,
  localStorage: { getItem: k => (k in store ? store[k] : null), setItem: (k, v) => { store[k] = String(v); }, removeItem: k => { delete store[k]; } } };
sb.window = sb;

/* ---- the builder's page ---- */
let HOST = null;
const byId = {};
const unesc = s => String(s).replace(/&quot;/g, "\"").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&");
const strip = s => unesc(String(s).replace(/<[^>]*>/g, ""));
function element(tag){
  const el = { tag, className: "", id: "", _html: "", listeners: {}, removed: false, textContent: "",
    addEventListener(type, fn){ this.listeners[type] = fn; },
    remove(){ this.removed = true; },
    querySelector(){ return { disabled: false }; } };
  Object.defineProperty(el, "innerHTML", { get(){ return this._html; }, set(v){ this._html = v; drawn(v); } });
  return el;
}
/* what the page would hold after a draw: the number box, the card list, the tick */
function drawn(html){
  delete byId.kbNum; delete byId.kbCard; delete byId.kbAdj;
  let m = /<input id="kbNum" inputmode="numeric" value="([^"]*)">/.exec(html);
  if(m) byId.kbNum = { value: unesc(m[1]), focus(){}, select(){} };
  m = /<select class="kb-sel" id="kbCard">(.*?)<\/select>/.exec(html);
  if(m){ const o = /<option>(.*?)<\/option>/.exec(m[1]); byId.kbCard = { value: o ? unesc(o[1]) : "" }; }
  m = /<input type="checkbox" id="kbAdj"( checked)?>/.exec(html);
  if(m) byId.kbAdj = { checked: !!m[1] };
}
sb.document = { getElementById: id => byId[id] || null, createElement: element,
  head: { appendChild(e){ if(e.id) byId[e.id] = e; } }, body: { appendChild(e){ HOST = e; } } };
vm.createContext(sb);

const chassisById = {}; chassis.forEach(c => { chassisById[c.id] = c; });
function resetStore(){
  Object.keys(store).forEach(k => delete store[k]);
  store["keter-app-pools"] = JSON.stringify(pools);
  store["keter-app-chassis"] = JSON.stringify(chassisById);
  if(tables.loot) store["keter-app-loot"] = JSON.stringify(tables.loot);
  if(tables.workshop) store["keter-app-workshop"] = JSON.stringify(tables.workshop);
  store["keter-app-skins"] = JSON.stringify({ v: 1, skins: skinsIn, gone: ["sk_std_bipedal", "sk_std_quadcopter", "sk_std_quadruped", "sk_std_hexapod", "sk_std_octopod"].filter(id => !skinsIn.some(k => k.id === id)), migrated: {} });
}
resetStore();
["keywords.js", "scoring.js", "loot.js", "progress.js", "chassis.js", "skins.js", "workshop.js", "builder.js"].forEach(f => vm.runInContext(fs.readFileSync(path.join(ROOT, f), "utf8"), sb));
const K = sb.KETER_KW, S = sb.KETER_SCORE, L = sb.KETER_LOOT, P = sb.KETER_PROG, CH = sb.KETER_CHASSIS, SK = sb.KETER_SKINS, W = sb.KETER_WORKSHOP, B = sb.KETER_BUILDER;
sb.KETER_PX = { has: id => !!pictures[id], get: id => (pictures[id] ? { id } : null) };
if(K.registerArchetypes) cards.forEach(c => K.registerArchetypes(c.archetypes));
const clone = o => JSON.parse(JSON.stringify(o === undefined ? null : o));

/* ---- chance for the script itself ---- */
let seedA = 20261009;
function rnd(){ seedA = (seedA + 0x6D2B79F5) >>> 0; let t = seedA; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }
const ri = (a, b) => a + Math.floor(rnd() * (b - a + 1)), pick = a => a[Math.floor(rnd() * a.length)], chance = p => rnd() < p;
function weighted(list){ let total = 0; list.forEach(x => { total += x.w; }); let r = rnd() * total; for(const x of list){ r -= x.w; if(r < 0) return x; } return list[list.length - 1]; }
/* long words are compared by what they hash to (FNV-1a, as world.js does it) */
function hash(s){ let h = 2166136261; s = String(s); for(let i = 0; i < s.length; i++){ h ^= s.charCodeAt(i); h = Math.imul(h, 16777619); } return h >>> 0; }

const cases = [];
const add = (fn, args, result) => cases.push({ fn, args: clone(args), result: clone(result) });
const tally = {};
const count = (k, n) => { tally[k] = (tally[k] || 0) + (n === undefined ? 1 : n); };

/* =====================================================================
   the builder, walked
   ===================================================================== */
function scrape(){
  const html = HOST._html, part = (re) => { const m = re.exec(html); return m ? m[1] : null; };
  const sent = part(/<div class="kb-sent" id="kbSent">(.*?)<\/div><div class="kb-pow"/);
  const pow = part(/<div class="kb-pow" id="kbPow">(.*?)<\/div><div class="kb-step">/) || "";
  const body = part(/<div class="kb-b" id="kbBody">([\s\S]*?)<\/div><div class="kb-f">/) || "";
  const foot = part(/<div class="kb-f">([\s\S]*)<\/div><\/div>$/) || "";
  const items = [];
  const re = new RegExp([
    '<p class="kb-note">(.*?)</p>',                                                                                     /* 1 */
    '<label class="kb-note"[^>]*><input type="checkbox" id="kbAdj"(?: checked)?> (.*?)</label>',                         /* 2 */
    '<div class="kb-g">(.*?)</div>',                                                                                    /* 3 */
    '<button class="kb-o( on)?" data-kb="([^"]*)"[^>]*><b style="color:([^"]*)">(.*?)</b>(?:<i>(.*?)</i>)?</button>',     /* 4-8 */
    '<button class="kb-chip on" data-kbdrop="(\\d+)" style="color:([^"]*)">(.*?)<s>✕</s></button>',                  /* 9-11 */
    '<button class="kb-chip" data-kb="([^"]*)" style="color:([^"]*)">(.*?)</button>',                                    /* 12-14 */
    '<div class="kb-num"><button data-kbstep="-1">−</button><input id="kbNum" inputmode="numeric" value="([^"]*)"><button data-kbstep="1">\\+</button></div>', /* 15 */
    '<select class="kb-sel" id="kbCard">(.*?)</select>',                                                                 /* 16 */
    '<button class="kb-btn( pri)?" data-kb="(pv:[^"]*)">(.*?)</button>',                                                 /* 17-19 */
    '<div class="kb-rv"><span>(.*?)</span><div>(.*?)</div><button class="kb-btn" data-kbedit="([^"]*)">Change</button></div>', /* 20-22 */
    '<div class="kb-bad">✗ (.*?)</div>'                                                                             /* 23 */
  ].join("|"), "g");
  let m;
  while((m = re.exec(body))){
    if(m[1] !== undefined) items.push({ t: "note", text: hash(unesc(m[1])) });
    else if(m[2] !== undefined) items.push({ t: "check", text: unesc(m[2]), on: !!(byId.kbAdj && byId.kbAdj.checked) });
    else if(m[3] !== undefined) items.push({ t: "group", text: unesc(m[3]) });
    else if(m[5] !== undefined) items.push({ t: "opt", key: unesc(m[5]), label: unesc(m[7]), desc: hash(unesc(m[8] || "")), on: !!m[4], colour: m[6] });
    else if(m[9] !== undefined) items.push({ t: "drop", i: +m[9], label: unesc(m[11]), colour: m[10] });
    else if(m[12] !== undefined) items.push({ t: "chip", key: unesc(m[12]), label: unesc(m[14]), colour: m[13] });
    else if(m[15] !== undefined) items.push({ t: "num", value: byId.kbNum ? String(byId.kbNum.value) : unesc(m[15]) });
    else if(m[16] !== undefined){ const opts = []; const o = /<option>(.*?)<\/option>/g; let x; while((x = o.exec(m[16]))) opts.push(unesc(x[1])); items.push({ t: "select", options: opts, value: byId.kbCard ? byId.kbCard.value : null }); }
    else if(m[18] !== undefined) items.push({ t: "button", key: m[18], label: unesc(m[19]), primary: !!m[17] });
    else if(m[20] !== undefined) items.push({ t: "row", label: unesc(m[20]), shown: strip(m[21]), dim: m[21].indexOf('<i style="color:#6d838d">') === 0, step: m[22] });
    else if(m[23] !== undefined) items.push({ t: "bad", lines: m[23].split("<br>✗ ").map(unesc) });
  }
  const btn = (key) => { const x = new RegExp('<button class="kb-btn[^"]*" data-kb="' + key + '"( disabled)?>(.*?)</button>').exec(foot); return x ? { enabled: !x[1], label: unesc(x[2]) } : null; };
  const back = btn("back"), skip = btn("skip"), next = btn("next"), ins = btn("insert");
  return { head: strip(part(/<div class="kb-h"><b>(.*?)<\/b>/) || ""),
    sentence: sent && sent.indexOf("<i>Your effect will appear here") === 0 ? "" : strip(sent || ""),
    power: (pow.match(/<span>.*?<\/span>/g) || []).map(strip),
    step: strip(part(/<div class="kb-step">(.*?)<\/div>/) || ""), title: strip(part(/<div class="kb-t">(.*?)<\/div>/) || ""),
    body: items, back: !!(back && back.enabled), skip: !!skip, next: next ? next.enabled : null, insert: ins ? { enabled: ins.enabled, label: ins.label } : null };
}
function tap(attrs){ HOST.listeners.click({ target: { closest(){ return { getAttribute: n => (n in attrs ? attrs[n] : null) }; } } }); }
const built = { action: [], passive: [] };
function walk(opts, most){
  let done = null, cancelled = false; HOST = null;
  const o = Object.assign({}, clone(opts), { onDone: t => { done = t; }, onCancel: () => { cancelled = true; } });
  if(opts.variable === undefined) delete o.variable;
  B.open(o);
  const ops = [], out = [{ snap: scrape() }];
  for(let n = 0; n < most && done === null && !cancelled; n++){
    const s = scrape(), acts = [];
    const inParam = s.body.some(x => x.t === "num" || x.t === "button") || s.body.some(x => x.t === "opt" && x.key.indexOf("pv:") === 0);
    s.body.forEach(x => {
      if(x.t === "opt") acts.push({ w: x.key === "none" ? 2 : 3, op: ["kb", x.key] });
      else if(x.t === "chip") acts.push({ w: 2, op: ["kb", x.key] });
      else if(x.t === "drop") acts.push({ w: 0.5, op: ["drop", x.i] });
      else if(x.t === "num"){ acts.push({ w: 2.2, op: ["step", 1] }); acts.push({ w: 1.6, op: ["step", -1] }); }
      else if(x.t === "select") x.options.forEach(c => acts.push({ w: 0.8 / x.options.length, op: ["card", c] }));
      else if(x.t === "check") acts.push({ w: 0.5, op: ["adj", !x.on] });
      else if(x.t === "button") acts.push({ w: x.key === "pv:ok" ? 4 : 1.5, op: ["kb", x.key] });
      else if(x.t === "row") acts.push({ w: 0.45, op: ["edit", x.step] });
    });
    if(s.back) acts.push({ w: 0.6, op: ["kb", "back"] });
    if(s.skip) acts.push({ w: 2, op: ["kb", "skip"] });
    if(s.next) acts.push({ w: 3, op: ["kb", "next"] });
    if(s.insert && s.insert.enabled) acts.push({ w: 7, op: ["kb", "insert"] });
    acts.push({ w: 0.04, op: ["kb", "x"] });
    const a = weighted(acts).op;
    if(a[0] === "kb") tap({ "data-kb": a[1] });
    else if(a[0] === "step") tap({ "data-kbstep": String(a[1]) });
    else if(a[0] === "drop") tap({ "data-kbdrop": String(a[1]) });
    else if(a[0] === "edit") tap({ "data-kbedit": a[1] });
    else if(a[0] === "card") byId.kbCard.value = a[1];
    else if(a[0] === "adj") byId.kbAdj.checked = a[1];
    ops.push(a); count("taps");
    out.push(done !== null || cancelled ? { done, cancelled } : { snap: scrape() });
    if(inParam && a[1] === "pv:ok") count("numbers given");
  }
  if(done !== null){ count("inserted"); built[opts.kind === "passive" ? "passive" : "action"].push(done); }
  else if(cancelled) count("closed"); else count("left open");
  return { ops, out };
}
const troopNames = cards.filter(c => c.cardType === "troop").map(c => c.name).slice(0, 6);
const cardTexts = [];
cards.forEach(c => (c.entries || c.abilities || (c._raw && c._raw.abilities) || []).forEach(e => { if(e && e.text) K.sentences(e.text).forEach(t => cardTexts.push({ text: t, kind: K.kindOf(e.kind || e.tag) })); }));
function progOwning(){ const s = { bp: {}, ch: {}, named: {}, all: chance(0.15) }; P.catalog().forEach(b => { if(chance(0.45)) s.bp[b.name] = ri(1, b.levels); }); chassis.forEach(c => { if(chance(0.5)) s.ch[c.id] = true; }); return s; }
const setProg = s => { store[P.PROG_KEY] = JSON.stringify(Object.assign({ seen: { enemy: {}, district: {}, comp: {} } }, clone(s))); };
/* what the Workshop page hands the builder: the chassis's keywords you can use now */
const allowedFor = ch => (ch.allowed || []).filter(k => !P.isBlueprint(k) || P.owned(k) >= 1);
for(let i = 0; i < 520; i++){
  const passive = chance(0.4), ch = pick(chassis), st = progOwning(); setProg(st);
  const opts = { kind: passive ? "passive" : "action", cardType: chance(0.82) ? "troop" : pick(["equipment", "hero", "command"]),
    role: passive ? "" : pick(["melee", "ranged", "support", "cyber", "ranged", ""]), others: chance(0.25) && built.action.length ? pick(built.action) : "",
    cards: chance(0.6) ? troopNames.slice(0, ri(1, troopNames.length)) : [] };
  const how = rnd();
  opts.allowed = how < 0.3 ? null : how < 0.75 ? allowedFor(ch) : (ch.allowed || []).slice();
  if(chance(0.3)) opts.variable = chance(0.5);
  if(chance(0.16)){
    const pool = cardTexts.filter(t => t.kind === opts.kind).map(t => t.text).concat(built[opts.kind]);
    if(pool.length) opts.sentence = pick(pool);
  }
  const r = walk(opts, ri(6, 46));
  add("builder", [opts, r.ops], r.out); count("walks"); count(opts.kind + " walks"); if(opts.sentence) count("reopened");
}
/* a sentence read back into the steps, and built again */
cardTexts.slice(0, 400).concat(built.action.slice(0, 80).map(t => ({ text: t, kind: "action" })), built.passive.slice(0, 80).map(t => ({ text: t, kind: "passive" }))).forEach(t => {
  const st = B.fromSentence(t.text, { kind: t.kind });
  add("fromSentence", [t.text, t.kind], { when: st.when, check: st.check, target: st.target, effects: st.effects, mods: st.mods, dur: st.dur, adjacent: !!st.adjacent, ownWords: !!st.ownWords, built: B.build(st) });
});

/* =====================================================================
   what text is worth
   ===================================================================== */
const texts = cardTexts.map(t => t.text).concat(built.action, built.passive, ["", "Looks menacing.", "[[Burst 3]]", "[[target enemy]] is hit with [[AoE 2]] and [[Pierce]].", "[[this Unit]] gains [[+X AC]] for [[turns X]].",
  "[[Sacrifice]]", "[[this Unit]] is spent as a [[Sacrifice]] with [[Burst 2]].", "[[Deploy 2 Test Drone]] [[adjacent]]", "[[target enemy]] takes [[damage -3]].", "[[Chain 0]]", "[[Aura 2]] [[all allies within 2]] gain [[+1 AC]].",
  "[[Nonsense 4]] and [[damage]].", "[[Suppressive Fire]] [[Overclock]] [[Chain 3]]", "[[target Sniper enemy]] takes [[damage 2]]."]);
texts.forEach(t => { [false, true].forEach(att => add("score", [t, att], S.keywordDetail(t, { attack: att }))); });
for(let i = 0; i < 300; i++){
  const e = { text: pick(texts), role: pick(["melee", "ranged", "cyber", "support", "", "Ranged", "passive"]) };
  if(chance(0.2)) e.power = pick([0, 3, "7", "", null, 12.6, "x"]);
  add("abilityPower", [e], S.abilityPower(e));
}

/* =====================================================================
   blueprints: levels, needs, what is missing, research
   ===================================================================== */
add("catalog", [], P.catalog());
const kwNames = K.allKeywords().map(k => k.name);
for(let i = 0; i < 400; i++){ const n = pick(kwNames.concat(["Nope", ""])), v = pick(["1", "2", "3", "4", "5", "9", "+2", "-3", "X", "", null, "2 Test Drone", "0", 3]); add("levelFor", [n, v], P.levelFor(n, v)); }
function someAbilities(ch, loose){
  const out = [], n = ri(0, loose ? 5 : Math.max(1, +ch.abilityCap || 1));
  for(let i = 0; i < n; i++){
    const passive = chance(0.3);
    const texts2 = passive ? built.passive : built.action;
    let text = chance(0.1) ? "" : chance(0.12) ? pick(texts) : (texts2.length ? pick(texts2) : pick(texts));
    if(chance(0.25) && texts2.length) text = (text + " " + pick(texts2)).trim();
    if(passive) out.push({ name: chance(0.5) ? "Passive " + i : "", kind: "passive", role: "", text });
    else out.push({ name: chance(0.6) ? "Action " + i : "", kind: "action", role: chance(0.85) && (ch.subtypes || []).length ? pick(ch.subtypes) : pick(W.ROLES),
      energy: pick([0, 1, 1, 2, 2, 3, 4, 6, "2"]), range: pick([1, 3, 4, 4, 5, 6, 7, 9]), hit: pick([4, 6, 6, 7, 8, 9, 11]), ap: pick([0, 2, 4, 4, 5, 6, 8]), text });
    /* v13.9: what it fires (one the game doesn't know, now and then, which both leave out) */
    if(!passive && chance(0.6)){ out[out.length - 1].projectile = pick(["bolt", "shell", "beam", "spray", "spray", "laser"]); count("projectile"); }
  }
  return out;
}
for(let i = 0; i < 300; i++){ const st = progOwning(), abs = someAbilities(pick(chassis), true); setProg(st); add("needs", [st, abs], { needs: P.needs(abs), missing: P.missing(abs) }); }
for(let i = 0; i < 200; i++){ const n = pick(kwNames), lv = ri(1, 4); add("researchPrice", [n, lv], P.researchPrice(n, lv)); }
for(let i = 0; i < 260; i++){
  const st = progOwning(); st.all = chance(0.08); const stock = L.bag(); stock.shards = pick([0, 30, 59, 60, 119, 120, 200, 500]);
  const names = []; for(let n = ri(1, 5); n > 0; n--) names.push(chance(0.75) && Object.keys(st.bp).length ? pick(Object.keys(st.bp)) : pick(kwNames.concat(["Nope"])));
  setProg(st); L.setStock(stock);
  const got = names.map(n => P.research(n));
  const after = P.state();
  add("research", [st, stock.shards, names], { got, bp: after.bp, shards: L.stock().shards });
  got.forEach(g => count(g.ok ? "researched" : "research refused"));
}
for(let i = 0; i < 200; i++){ const st = progOwning(); st.all = chance(0.5); setProg(st); const n = pick(kwNames), id = pick(chassis).id;
  add("owned", [st, n, id], { owned: P.owned(n), has: P.hasChassis(id), knownBp: P.knownBp(n), knownCh: P.knownCh(id), bpItem: P.eligible("bp:" + n + ":1", []), chItem: P.eligible("ch:" + id, []), grant: P.grant("ch:" + id), after: P.state().ch }); }

/* =====================================================================
   designs: power, the fit check, what a copy costs, the card
   ===================================================================== */
const tableSets = [tables.workshop || null, null,
  { rate: 0.35, energyBase: 3, energyStep: 0.5, numbers: { range: { base: 3, per: 1 }, hit: { base: 5, per: 0.5 }, ap: { base: 2, per: 0.25 } }, research: { Burst: [0, 40, 90], Slowed: [0, "", 75] }, caps: { Burst: [2, 4, 6], Slowed: [1, 1, 2] },
    require: { Burst: { 1: { 1: 1 }, 2: { 1: 2, 2: 1 }, 3: { 2: 2, 3: 1 } }, AoE: { 1: { 1: 1 }, 2: { 2: 1 }, 3: { 4: 1 } }, Pierce: { 1: { 3: 2 } }, Slowed: { 2: { 1: "3" } } } },
  { rate: 1, energyBase: 0, energyStep: 0, numbers: { range: { base: 4, per: 0 } }, require: { Marked: { 1: { 5: 1, 1: 0 } } } }];
function setTables(t){ if(t) store[W.WS_KEY] = JSON.stringify(t); else delete store[W.WS_KEY]; }
function someDesign(){
  const ch = chance(0.04) ? null : pick(chassis), loose = chance(0.2);
  const d = { id: "ds_" + ri(1000, 99999).toString(36), name: pick(["Lancer", "Wall", "Pack Mule", "Needle", "Mirror", ""]) + (chance(0.3) ? " " + ri(2, 9) : ""), chassis: ch ? ch.id : "ch_missing",
    abilities: ch ? someAbilities(ch, loose) : [{ name: "", kind: "action", role: "Ranged", energy: 1, range: 4, hit: 6, ap: 4, text: "[[target enemy]] takes [[damage 1]]." }], notes: "" };
  if(chance(0.08)) d.prebuilt = true;
  if(chance(0.3)){ const opts = SK.optionsFor(d); if(opts.length){ const k = pick(opts).skin; d.skin = { skin: k.id, variant: chance(0.85) ? pick(k.variants).id : "v_gone" }; } else d.skin = { skin: "sk_gone", variant: "v1" }; }
  return d;
}
for(let i = 0; i < 900; i++){
  const ti = ri(0, tableSets.length - 1), st = progOwning(), d = i === 0 ? clone(W.STARTER) : someDesign(), stock = L.bag();
  for(let r = 0; r < 6; r++) stock.parts.troop[r] = pick([0, 0, 1, 3, 8, 20, 60]);
  setTables(tableSets[ti]); setProg(st); L.setStock(stock);
  const ch = W.chassisOf(d), chk = W.check(d), cost = W.cost(d);
  add("design", [ti, st, d, stock.parts.troop], { abilityPowers: (d.abilities || []).map(a => W.abilityPower(a, ch)), power: W.power(d),
    check: { ok: chk.ok, reasons: chk.reasons, power: chk.power, cap: chk.cap, abilities: chk.abilities === undefined ? null : chk.abilities, abilityCap: chk.abilityCap === undefined ? null : chk.abilityCap, missing: chk.missing || null },
    cost, affordable: W.affordable(d), card: W.toCard(d), fields: (d.abilities || []).map(a => W.fieldsFor(a)), attacks: (d.abilities || []).map(a => !!W.isAttack(a)) });
  count(chk.ok ? "designs that fit" : "designs that don't");
}
add("tables", [], tableSets.map(t => { setTables(t); return W.tables(); }));
setTables(tables.workshop || null);
tableSets.forEach((t, ti) => { setTables(t); chassis.forEach(c => { add("blank", [ti, c.id], { design: W.blank(c.id), action: W.blankAbility(c, "action"), passive: W.blankAbility(c, "passive"), max: { range: W.maxOf(c, "range"), hit: W.maxOf(c, "hit"), ap: W.maxOf(c, "ap") }, best: W.bestHit(c) }); }); });
setTables(tables.workshop || null);
add("starter", [], { design: W.STARTER, card: W.toCard(W.STARTER), check: (() => { setProg({ bp: {}, ch: {}, named: {}, all: false }); const c = W.check(W.STARTER); return { ok: c.ok, reasons: c.reasons, power: c.power, cap: c.cap }; })(), cost: W.cost(W.STARTER) });
/* the chassis's own check, on designs it is handed as they are */
for(let i = 0; i < 300; i++){
  const ch = pick(chassis), abs = someAbilities(ch, chance(0.4)).map(a => { const o = { text: a.text, role: a.kind === "passive" ? "" : String(a.role || "").toLowerCase() }; if(chance(0.3)) o.power = ri(0, 30); return o; });
  add("chassisCheck", [ch.id, abs], CH.check(ch, { abilities: abs }));
}
chassis.forEach(c => { [progOwning(), progOwning(), { bp: {}, ch: {}, named: {}, all: false }, { bp: {}, ch: {}, named: {}, all: true }].forEach(st => { setProg(st); add("allowedFor", [st, c.id], allowedFor(c)); }); add("districtOf", [c.id], CH.districtOf(c)); });
texts.slice(0, 300).forEach(t => add("keywordsIn", [t], CH.keywordsIn(t)));

/* =====================================================================
   the look a design wears
   ===================================================================== */
const plans = SK.BODY_PLANS;
function someSkins(){
  const list = clone(skinsIn);
  for(let n = ri(0, 7); n > 0; n--){
    const bp = pick(plans), vs = [];
    for(let v = ri(1, 3); v > 0; v--) vs.push({ id: "v" + (vs.length + 1), name: "Variant " + (vs.length + 1), art: chance(0.6) ? pick(Object.keys(pictures).concat(["px_none"])) : null, token: chance(0.6) ? pick(Object.keys(pictures).concat(["px_none"])) : null });
    list.push({ id: "sk_r" + list.length, name: pick(["Dune", "Carbon", "Hazard", "Parade", "Rust"]) + " " + list.length, owner: { kind: chance(0.9) ? "body" : pick(["hero", "enemy"]), key: bp }, roles: W.ROLES.filter(() => chance(0.3)), order: 10 + list.length, variants: vs });
  }
  return list;
}
for(let i = 0; i < 400; i++){
  const list = someSkins(); store[SK.KEY] = JSON.stringify({ v: 1, skins: list, gone: plans.map(p => "sk_std_" + p.toLowerCase()), migrated: {} });
  const d = someDesign();
  if(chance(0.5)){ const mine = list.filter(k => k.owner.kind === "body"); if(mine.length){ const k = pick(mine); d.skin = { skin: k.id, variant: chance(0.8) ? pick(k.variants).id : "v_gone" }; } }
  add("look", [list, d], { plan: SK.bodyPlanOf(d), roles: SK.rolesOf(d), options: SK.optionsFor(d).map(o => ({ skin: o.skin.id, fits: o.fits })), look: SK.lookOf(d), pics: SK.picsOfDesign(d) });
}
resetStore();

const out = path.join(ROOT, "game", "tests", "fixtures", "workshop_cases.json");
fs.writeFileSync(out, JSON.stringify({ made: "scoring.js, chassis.js, workshop.js, progress.js, skins.js, builder.js and keywords.js", chassis: chassis.length, tables: tableSets, pictures: Object.keys(pictures), cases }));
const counts = {}; cases.forEach(c => counts[c.fn] = (counts[c.fn] || 0) + 1);
console.log(JSON.stringify({ file: out, cases: cases.length, counts, seen: tally }));
