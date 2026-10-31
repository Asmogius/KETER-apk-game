#!/usr/bin/env node
/* KETER Lab: the Lab card set, the master cards rebuilt the Lab way.

   Every real master card is given a build (lab.js): a unit a role, a size and
   a rarity (an Enemy a role, a size and a Skull Level) and up to two abilities
   from the library; every other card one item from its type's menu. Cards
   that did the same job as another are merged into it (the survivor keeps its
   name; the others are retired), the attacks and Actions that were on
   Equipment become Action cards of their own (Q2), every Legendary and Mythic
   card has a signature ability (Q3), and the Skull Levels that had one Enemy
   or none are filled. The test set's cards are left as they are: they are for
   checking the rules.

   The set keeps builds, not cards: KETER Lab (scripts/lab_set.gd) and the
   Companion with the Lab switch on (lab_set.js) compile each build as they
   load it, so a change to the tables (lab/spec_data.py) reaches every card.
   What a build doesn't say comes from the master card it was made from (its
   District, archetypes, loot, art and lore); a new card says it here.

   Run from the repository: node lab/make_lab_set.js
   Writes game/data/lab_set.json and lab_set.js, and prints the set against
   its rarity targets. It fails on any build the checks refuse, or any text
   the keyword reader can't read. */
"use strict";
const fs = require("fs"), path = require("path"), vm = require("vm");
const ROOT = path.resolve(__dirname, "..");
const sb = { Math, JSON, String, Object, Array, parseInt, isNaN, console, RegExp, localStorage: { getItem: () => null, setItem(){}, removeItem(){} } };
sb.window = sb;
vm.createContext(sb);
["lab_data.js", "lab.js", "keywords.js"].forEach(f => vm.runInContext(fs.readFileSync(path.join(ROOT, f), "utf8"), sb));
const L = sb.KETER_LAB, D = sb.KETER_LAB_DATA, KW = sb.KETER_KW;
const MASTER = JSON.parse(fs.readFileSync(path.join(ROOT, "compendium_full.json"), "utf8")).cards;
const byName = {}; MASTER.forEach(c => { byName[c.name] = c; });

const SET_VERSION = "S1";

/* ---------------------------------------------------------------- the builds
   hero(role, rarity, abilities), troop(role, size, rarity, abilities),
   foe(type, role, size, skull, abilities), menu(type, rarity, id, tier, trigger),
   action(rarity, [id, tier]). A signature ability: ["SIG", {name, kind, text, points, e, dmg, rng, hit}]. */
const hero = (role, rarity, abilities) => ({ type: "hero", role, rarity, abilities });
const troop = (role, size, rarity, abilities) => ({ type: "troop", role, size, rarity, abilities });
const foe = (type, role, size, skull, abilities) => ({ type, role, size, skull, abilities });
const menu = (type, rarity, id, tier, trigger) => Object.assign({ type, rarity, menu: id, tier }, trigger ? { trigger } : {});
const action = (rarity, ability) => ({ type: "action", rarity, ability });

const CARDS = [
  /* ---- Heroes ---- */
  { name: "Dock Hand", build: hero("brute", "common", [["A4", 1]]), why: "A Brute with a Shove." },
  { name: "Hangar Rifleman", build: hero("shooter", "common", [["A13", 1]]), why: "A Shooter with a longer, surer shot." },
  { name: "Field Medic", build: hero("support", "common", [["S1", 1]]), why: "A Support who heals." },
  { name: "\"Mincer\" Cleaner Bot", build: hero("brute", "rare", [["A2", 2], ["P9", 2]]), why: "Grinding Drum's flurry and Overdrive Teeth's fury; Mince's Bleed goes (it folds into Poisoned)." },
  { name: "Volt-Warden Ryska", build: hero("shooter", "rare", [["A13", 2], ["U3", 1]]), why: "Arc Lance becomes Snipe; Grid Discipline is the Spotter Aura. Leadership comes from the table now (8 was the highest of any Hero)." },
  { name: "Quillon Vex", build: hero("shooter", "epic", [["A10", 3], ["P6", 3]]), why: "Mark of Debt and Light Step, as they were." },
  { name: "Ilsa Varn, Jump-Frame Pilot", build: hero("skirmisher", "epic", [["A3", 3], ["S9", 3]]), why: "Hammerfall's lunge and Jump Jets; Shoulder Thrusters and Gyro-Stabilised go (the limit is three entries)." },
  { name: "Rictus", build: hero("brute", "legendary", [["A1", 3], ["SIG", { name: "Spin-Up", kind: "passive", points: 9,
      text: "[[when]] [[the round begins]], [[this Unit]] gains [[DMG +2]] for [[turns 3]]. [[when]] [[the round begins]], [[this Unit]] gains [[MS +1]] for [[turns 3]]." }]]),
    why: "Grinder becomes Heavy Blow III; Spin-Up stays, as Rictus's signature." },
  { name: "Sable-Nine, Ledger Adept", build: hero("support", "legendary", [["P15", 1], ["SIG", { name: "Foreclose", kind: "attack", points: 6, e: 2, dmg: 2, rng: 1,
      text: "[[target enemy]] gains [[Weakened 1]] for [[turns 1]]." }]]),
    why: "Ledger is the Reactor (Aether every round); Foreclose, her signature, saps what it hits." },
  { name: "Dross, the Forge-Blind", build: hero("brute", "legendary", [["P2", 3], ["SIG", { name: "Bellows", kind: "support", points: 7, e: 3,
      text: "[[this Unit]] gains [[HP +6]] [[persistent]]." }]]),
    why: "Slag Armor is Plated III; Bellows stays, as his signature." },

  /* ---- Troops ---- */
  { name: "Aetherium Golem", build: troop("shooter", "colossal", "mythic", [["SIG", { name: "Aether Eruption", kind: "attack", points: 10, e: 3, dmg: 1,
      text: "[[AoE 1]]. [[target enemy]] gains [[Slowed 2]] for [[turns 1]]." }], ["A7", 3]]),
    why: "The only Mythic: a Colossal Shooter. Aether eruption is its signature and Crystalline prison is Snare III; Pummel goes." },
  { name: "Augmented Weapons Specialist", build: troop("shooter", "standard", "uncommon", [["A12", 1], ["A10", 1]]), why: "Suppressive Fire's Pinned folds into Mark; Exploit weakpoint's burst is Rapid Fire." },
  { name: "BRICK Security Bot", build: troop("brute", "heavy", "common", [["U1", 1]]), why: "A heavy wall with the Guard Aura (Evasive for its neighbours becomes AC); Haymaker's 15 damage goes." },
  { name: "CERBERUS Barriage Bot", build: troop("shooter", "heavy", "legendary", [["A11", 3], ["SIG", { name: "Deploy Bipod", kind: "support", points: 6, e: 2,
      text: "[[this Unit]] gains [[Aim +2]] for [[turns 2]]. [[this Unit]] gains [[Range +1]] for [[turns 2]]." }]]),
    why: "Armageddon is Volley III; Deploy bipod is its signature; Quickshot goes." },
  { name: "CERBERUS Blitz Bot", build: troop("skirmisher", "heavy", "legendary", [["A5", 3], ["SIG", { name: "Blitz", kind: "support", points: 6, e: 1,
      text: "[[this Unit]] gains [[Dash 4]]. [[this Unit]] gains [[DMG +2]] for [[turns 1]]." }]]),
    why: "Stunning swipe is Stagger III; Pounce and Bite by Bite become Blitz, its signature." },
  { name: "CERBERUS Breacher Bot", build: Object.assign(troop("shooter", "heavy", "epic", [["A11", 2], ["A12", 2]]), { trade: ["rng", 1, "hp", 3] }),
    why: "Slag spray and Clear the room: Volley and Rapid Fire at close range (it trades a tile of range for Health)." },
  { name: "CERBERUS Overlord Bot", build: troop("support", "heavy", "legendary", [["U1", 3], ["SIG", { name: "Energy Transfer", kind: "support", points: 6, e: 1,
      text: "[[target ally]] gains [[NRG +1]] for [[turns 1]]. [[target ally]] gains [[AC +1]] for [[turns 1]]." }]]),
    why: "Battle presence is the Guard Aura; Energy transfer is its signature; Reenforce and Zap go." },
  { name: "Cyber Savant", build: troop("support", "standard", "rare", [["S4", 2], ["P1", 2]]), why: "Cyber folds into Ranged; Sense Steel's Draw goes, and it gives Energy instead." },
  { name: "Defensive Platform Specialist", build: Object.assign(troop("support", "standard", "rare", [["S7", 2], ["U5", 1]]), { token: "Sentry Turret" }),
    why: "Deploy Sentry is Summon II; its double Aura is the Reach Aura; Potshot goes." },
  { name: "Entry Denial Bot", build: troop("shooter", "standard", "uncommon", [["A7", 1], ["A6", 1]]), why: "A Disabler: Sonic Discharge's Push (melee-only now) becomes Snare, and it slows." },
  { name: "FALCON Drone", build: troop("support", "light", "common", [["A10", 1]]), why: "A light spotter: Ping's Mark. Flying folds into Evasive, which it loses." },
  { name: "Foundry Sentinel", build: troop("brute", "standard", "uncommon", [["A4", 1], ["P1", 1]]), why: "Rivet Slam's Push, and a little more Health." },
  { name: "ONYX Assassin", build: troop("skirmisher", "standard", "rare", [["A3", 2], ["P3", 2]]), why: "Monofilament Blade's lunge and Cape's Evasive, as they were." },
  { name: "ONYX Blademaster", build: troop("skirmisher", "standard", "rare", [["A2", 2], ["P11", 2]]), why: "Whirlwind and Riposte, as they were." },
  { name: "ONYX Breacher", build: Object.assign(troop("shooter", "standard", "rare", [["A11", 2], ["A6", 2]]), { trade: ["rng", 1, "hp", 3] }),
    why: "Breaching Charge is Volley; the shotgun's Push (melee-only now) slows instead; close range, more Health." },
  { name: "ONYX Brute", build: troop("brute", "standard", "rare", [["A4", 2], ["A5", 2]]), why: "Power Fist's Push and Haymaker's Stun, as they were." },
  { name: "ONYX Guardian", build: troop("brute", "standard", "rare", [["A4", 2], ["U1", 2]]), why: "Shield Bash and Shield Wall, as they were." },
  { name: "ONYX Sharpshooter", build: troop("shooter", "standard", "rare", [["A13", 2], ["P3", 2]]), why: "Long Shot and Ghillie Cloak, as they were." },
  { name: "ONYX Stitcher", build: troop("support", "standard", "rare", [["S1", 2], ["S6", 2]]), why: "Field Stitch and Dermal Patch, as they were." },
  { name: "ONYX Wraith", build: troop("skirmisher", "standard", "rare", [["S9", 2], ["A14", 2]]), why: "Phase Step and Shadow Blade's Execute, as they were." },
  { name: "Scrap Caddy", build: troop("brute", "light", "common", [["U4", 1]]), why: "A Transport: its Aura hurries its neighbours along instead of shielding Heroes." },
  { name: "Scrap rat", build: troop("shooter", "light", "uncommon", [["P16", 1], ["A12", 1]]), why: "Shiny! is the Scavenger; Pipeshot sprays." },
  { name: "Scrapheap Brawler", build: troop("skirmisher", "standard", "uncommon", [["A2", 1], ["A1", 1]]), why: "Bigger Bonk's flurry and Bonk's extra hit." },
  { name: "Scuttle Overseer", build: Object.assign(troop("support", "standard", "epic", [["P14", 2], ["A12", 3]]), { token: "Scuttlebot" }),
    why: "Arrives with Scuttlebots; Static Lash's chain is Rapid Fire. Battlefield construct goes (the Brood mother keeps a Summon)." },
  { name: "Scuttle Swarm", build: troop("skirmisher", "light", "rare", [["A6", 2], ["S1", 2]]), why: "Ankle shredder and Proliferate. The Lab has no variable (X) cost, so it is one swarm at one price." },
  { name: "Scuttle brood mother", build: Object.assign(troop("brute", "heavy", "epic", [["P14", 3], ["S7", 2]]), { token: "Scuttlebot" }), why: "Arrives with Scuttlebots and lays more; Slashing mandibles is its basic attack." },
  { name: "SecurMax Civilian Guard Bot", build: troop("brute", "standard", "uncommon", [["S3", 1], ["P7", 1]]), why: "Brace, and Shoulder to Shoulder's AC kept always on." },
  { name: "Unmanned Arial Gun Platform", build: troop("shooter", "light", "common", [["A12", 1]]), why: "Strafing run's burst; its Dash goes." },
  { name: "Ledger Runner", build: troop("shooter", "light", "common", [["P5", 1]]), why: "A fast light Shooter. Its Draw on arriving goes (Draw is for Commands now)." },
  { name: "Slag Hauler", build: troop("brute", "heavy", "common", [["P1", 1]]), why: "It had no ability: a heavy Brute, a little tougher." },
  { name: "Arc Technician", build: troop("support", "standard", "uncommon", [["S1", 1], ["S4", 1]]), why: "Patch Through heals; it gives Energy too." },
  { name: "Debt Collector", build: troop("skirmisher", "standard", "uncommon", [["A14", 1], ["A3", 1]]), why: "Call In collects on the hurt: Finisher, and a Pounce to reach them." },
  { name: "Chaff Swarm", build: troop("skirmisher", "light", "common", [["P3", 1]]), why: "Light and hard to hit, as it was." },

  /* ---- Enemies, by Skull Level (S2 had ten and S3 and S4 one each: some move, and three are new) ---- */
  { name: "\"Binder\" Cleaner Bot", build: foe("enemy", "shooter", "standard", 1, [["A7", 1]]), why: "Foam Gun's Root." },
  { name: "Exo Worker Husk", build: foe("enemy", "brute", "standard", 1, [["A6", 1]]), why: "Grab's Slowed. (Also the Stitcher's and the Command Center's token.)" },
  { name: "Vaccinator", build: foe("enemy", "brute", "standard", 1, [["A8", 1]]), why: "Moves to Skull 1: the booster shot poisons." },
  { name: "Laz Welder Husk", build: foe("enemy", "shooter", "standard", 1, [["A10", 1]]), why: "Moves to Skull 1. Arc Weld's Sundered folds into Mark." },
  { name: "\"Purifier\" Cleaner Bot", build: Object.assign(foe("enemy", "shooter", "standard", 2, [["A8", 1]]), { trade: ["rng", 1, "hp", 3] }), why: "Sterilise poisons, at close range." },
  { name: "\"Stitcher\" Cleaner Bot", build: foe("enemy", "support", "standard", 2, [["S1", 1]]), why: "Suture heals; Reassemble and Needle go (one ability at Skull 2)." },
  { name: "Centibot", build: foe("enemy", "skirmisher", "standard", 2, [["A7", 1]]), why: "Coil's Root; Static Antenna's Drained goes." },
  { name: "Chrome Junkie", build: foe("enemy", "shooter", "standard", 2, [["A11", 1]]), why: "Energy Blast's AoE." },
  { name: "Skitterling", build: foe("enemy", "skirmisher", "standard", 2, [["A3", 1]]), why: "Weld Claw's lunge." },
  { name: "\"Hunter\" Cleaner Bot", build: foe("enemy", "shooter", "standard", 3, [["A13", 2], ["A6", 2]]), why: "Moves to Skull 3: Sensor Tag's long shot and Harpoon's Slowed." },
  { name: "Exo Husk", build: foe("enemy", "brute", "standard", 3, [["A1", 2], ["A7", 2]]), why: "Moves to Skull 3: Drill Baby Drill's big hit and Vice Grip's Root." },
  { name: "Chrome Fiend", build: foe("enemy", "shooter", "standard", 3, [["A12", 2], ["P5", 2]]), why: "Missile Barrage's burst; Fire and move is Fleet." },
  { name: "Long Range Vaccinator", build: foe("enemy", "shooter", "standard", 3, [["A8", 2], ["P8", 2]]), why: "Moves to Skull 3: The Jab poisons from far off." },
  { name: "Skitter Stalker", build: foe("elite", "skirmisher", "standard", 3, [["A3", 3], ["A8", 2]]), why: "Pounce, and Rend's Bleed as Poisoned." },
  { name: "Arachnabot", build: foe("enemy", "skirmisher", "standard", 4, [["A3", 2], ["A7", 2]]), why: "Pounce and Entangling Spray's Root; Lethal injection goes." },
  { name: "Chrome Reaver", id: "D3-E17", art: "Chrome Fiend", meta: { affinities: [{ district: "3", symbol: "€", level: 0 }], archetypes: ["Fighter"], mechanical: false },
    build: foe("enemy", "skirmisher", "standard", 4, [["A2", 2], ["P3", 2]]), why: "New, for Skull 4: a fast, hard-to-hit Chrome blade." },
  { name: "Husk Breaker", id: "D3-E18", art: "Exo Husk", meta: { affinities: [{ district: "3", symbol: "€", level: 0 }], archetypes: ["Heavy Infantry"], mechanical: false },
    build: foe("enemy", "brute", "heavy", 4, [["A1", 2], ["A5", 2]]), why: "New, for Skull 4: a heavy Husk that stuns." },
  { name: "Brood Matriarch", build: foe("miniboss", "skirmisher", "standard", 4, [["A3", 3], ["A2", 2], ["U4", 1]]), why: "Gantry Drop, Scything Legs and Brood Call; Brood Panic and Gantry Legs go." },
  { name: "Construction Titan", build: foe("enemy", "brute", "heavy", 5, [["A4", 3], ["A2", 2]]), why: "Wrecking Swing's Push and Stomp's sweep." },
  { name: "Titan Command Center", build: Object.assign(foe("enemy", "support", "heavy", 5, [["S7", 3], ["U2", 2]]), { token: "Exo Worker Husk" }), why: "Launch Bay and Command Uplink; Point Defence is its basic shot." },
  { name: "Centibot Siegeframe", id: "D3-E19", art: "Centibot", meta: { affinities: [{ district: "3", symbol: "€", level: 0 }], archetypes: ["Disabler"], mechanical: false },
    build: foe("enemy", "shooter", "heavy", 5, [["A11", 3], ["A7", 2]]), why: "New, for Skull 5: a heavy Centibot that shells and roots." },
  { name: "Decimation Titan", build: foe("enemy", "shooter", "heavy", 6, [["A12", 3], ["A11", 3]]), why: "Gatling Sweep and Missile Salvo, as they were." },
  { name: "Earthshaker Titan", build: foe("enemy", "brute", "heavy", 6, [["A5", 3], ["A6", 3]]), why: "Hammer Fists' Stun and Quake's Slowed." },
  { name: "Starkiller Titan", build: foe("enemy", "shooter", "heavy", 6, [["A13", 3], ["A9", 3]]), why: "Rail Cannon pierces; Core Vent weakens." },

  /* ---- Action cards (one library ability, given to the Hero it is attached to) ---- */
  { name: "Falconer Drone Pack", build: Object.assign(action("rare", ["P14", 1]), { token: "FALCON Drone Token" }), why: "Arrives with a FALCON Drone, as it did." },
  { name: "Integrated Targeting System 2", build: action("uncommon", ["P8", 1]), why: "Range +1, as it was." },
  { name: "Integrated Targeting System V2", build: action("epic", ["P8", 3]), why: "Range +2, as it was." },
  { name: "Kickstart", build: action("rare", ["S2", 2]), why: "An ally hits harder; its Move goes." },
  { name: "Overclock Surge", build: action("rare", ["S4", 2]), why: "Energy for an ally; its Drained goes." },
  { name: "Subdermal Armor Plating 2", build: action("common", ["P7", 1]), why: "AC +1, as it was." },
  { name: "Subdermal Armor Plating V2", build: action("rare", ["P7", 2]), why: "AC +2, as it was." },
  { name: "Overpressure", build: action("uncommon", ["A15", 1]), why: "A big hit that hurts its user, as it was." },
  { name: "Field Weld", build: action("common", ["S1", 1]), why: "Heals, as it did." },
  { name: "Vault Strike", build: action("rare", ["A3", 2]), why: "The lunge, as it was." },
  { name: "Skitter Step", build: action("uncommon", ["S5", 1]), why: "Extra tiles, as it was." },
  { name: "Burning Heart", build: action("uncommon", ["P9", 1]), why: "Was an Aether card (a Hero's Health for a turn): a Berserker's Action card now, harder hits when hurt." },
  { name: "Lay Waste", id: "D3-A18", was: "Personal mounted cluster ordinance", build: action("rare", ["A11", 2]),
    why: "Equipment carries no attacks (Q2): the cluster ordnance's attack is an Action card of its own, and the Equipment goes." },
  { name: "Doom.exe", id: "D3-A19", art: "MONTU Battle Suit", meta: { affinities: [{ district: "3", symbol: "€", level: 0 }] }, build: action("epic", ["A15", 3]),
    why: "MONTU Battle Suit's attack, an Action card of its own (Q2)." },
  { name: "Rend Asunder", id: "D3-A20", art: "Ripper Combat Suit", meta: { affinities: [{ district: "3", symbol: "€", level: 0 }] }, build: action("rare", ["A8", 2]),
    why: "Ripper Combat Suit's attack, an Action card of its own (Q2); its Bleed is Poisoned." },
  { name: "Exorunner Leap", id: "D3-A21", art: "Courrier exorunners", meta: { affinities: [{ district: "3", symbol: "€", level: 0 }] }, build: action("uncommon", ["S9", 1]),
    why: "Courrier exorunners' Action, an Action card of its own (Q2)." },
  { name: "Identify Molecular Flaw", id: "D3-A22", art: "HALO targeting System", meta: { affinities: [{ district: "3", symbol: "€", level: 0 }] }, build: action("rare", ["A10", 2]),
    why: "HALO targeting System's Action, an Action card of its own (Q2): a mark every shot finds." },

  /* ---- Equipment (one stat bump; from Rare, one trigger) ---- */
  { name: "Aetherium Reactive Plating", build: menu("equipment", "rare", "Q2", 2, "QT1"), why: "AC +2 and Reactive, exactly as it was." },
  { name: "Counterweight Fist", build: menu("equipment", "uncommon", "Q3", 1), merges: ["Superheated Blades"], why: "DMG +1. Superheated Blades did the same and folds into it." },
  { name: "Courrier exorunners", build: menu("equipment", "uncommon", "Q4", 1), merges: ["Vantage Servo Harness"], why: "MS +1; its Leap is an Action card now (Exorunner Leap). Vantage Servo Harness did the same and folds into it." },
  { name: "Dragonskin lining", build: menu("equipment", "rare", "Q2", 2), why: "AC +2 (it gave Troops +2 and Heroes +1)." },
  { name: "HALO targeting System", build: menu("equipment", "rare", "Q5", 2), why: "Range +1; its Action is a card now (Identify Molecular Flaw)." },
  { name: "MONTU Battle Suit", build: menu("equipment", "legendary", "Q1", 3, "QT2"), why: "Health, and the Spool trigger; Doom.exe is an Action card now and Brawlzall goes." },
  { name: "Redline Governor", build: menu("equipment", "epic", "Q3", 3, "QT4"), why: "DMG +3 and the Launch trigger; Purge goes." },
  { name: "Ripper Combat Suit", build: menu("equipment", "epic", "Q4", 3), why: "Battlefield Mobility is Servos III; Rend Asunder is an Action card now." },
  { name: "Ballast Plate", build: menu("equipment", "common", "Q1", 1), why: "Health, without the lost Move." },
  { name: "Dead Man's Grip", build: menu("equipment", "rare", "Q1", 2, "QT3"), why: "Health, and the Dead Man's Switch trigger." },
  { name: "Spool Governor", build: menu("equipment", "epic", "Q3", 2, "QT2"), merges: ["Overdrive Governor"], why: "DMG +2 and the Spool trigger. Overdrive Governor (a Prototype) did the same and folds into it." },
  { name: "Whisper Coil", build: menu("equipment", "uncommon", "Q6", 1), why: "Aim +1, as it was." },
  { name: "Debt Ledger", build: menu("equipment", "rare", "Q2", 1, "QT5"), why: "Aether every round is for Prototypes and the Reactor now: AC +1, and Aether for a kill." },
  { name: "Leaper Greaves", build: menu("equipment", "uncommon", "Q7", 1), why: "Leap 2, as it was." },
  { name: "Momentum Plating", build: menu("equipment", "rare", "Q8", 2), why: "Evasive, always on." },

  /* ---- Commands ---- */
  { name: "Hold the Line", build: menu("command", "uncommon", "C2", 1), merges: ["Tighten Ranks"], why: "Everyone's AC +1 for a turn. Tighten Ranks did the same and folds into it." },
  { name: "Reroute Power", build: menu("command", "uncommon", "C8", 1), why: "Rerouted power: Energy for every Troop." },
  { name: "Redline overdrive", build: menu("command", "uncommon", "C1", 1), why: "Every ally hits harder; its Move and Drained go." },
  { name: "Call the Note", build: menu("command", "rare", "C1", 2), why: "DMG +2 for everyone, as it was." },
  { name: "Recall", build: menu("command", "common", "C6", 1), why: "Recover, as it was." },
  { name: "Ledger Call", build: menu("command", "uncommon", "C5", 1), merges: ["Liquidate", "Datamine"], why: "Draw 2. Liquidate (Draw 3 for 1) and Datamine (an Aether card) did the same and fold into it." },
  { name: "Flank Them", build: menu("command", "common", "C3", 1), merges: ["Kinetic Surge"], why: "Everyone moves 2 more. Kinetic Surge (an Aether card) did the same and folds into it." },
  { name: "Pin the Runner", build: menu("command", "uncommon", "C7", 1), why: "Roots one Enemy, as it did." },
  { name: "Frenzy Protocol", build: menu("command", "rare", "C8", 2), why: "Was an Aether card; an order to every Troop is a Command." },

  /* ---- Aether cards ---- */
  { name: "Aether Bolt", build: menu("aether", "uncommon", "E1", 1), why: "Damage 3, as it was." },
  { name: "Aether Discharge", build: menu("aether", "uncommon", "E2", 1), why: "A blast; it now strikes friend and foe, for less." },
  { name: "Aether Lance", build: menu("aether", "rare", "E3", 2), why: "Damage 6 that pierces, as it was." },
  { name: "Deploy FCB", build: menu("aether", "epic", "E4", 3), why: "Full cover; Epic now (Full cover is tier III)." },
  { name: "Deploy HCB", build: menu("aether", "uncommon", "E4", 1), why: "Half cover, as it was." },
  { name: "Deploy Sentry", build: menu("aether", "uncommon", "E5", 1), why: "A Sentry Turret, as it was." },
  { name: "Deploy ordinance drone swarm", build: menu("aether", "rare", "E2", 2), merges: ["Overrun"], why: "A blast. Overrun did the same and folds into it." },
  { name: "Emergency Overdrive", build: menu("aether", "rare", "E8", 2), why: "NRG +3 for a Troop, as it was." },
  { name: "Scavenge Parts", build: menu("aether", "uncommon", "E6", 1), merges: ["Salvage Aether Core", "Salvage Hard Drive", "Alchemical Chip"],
    why: "A Troop spent for Aether; the Recover goes (Commands and Consumables have it). The two Salvage cards and Alchemical Chip did the same and fold into it." },
  { name: "Gravity Well", build: menu("aether", "rare", "E7", 2), why: "Slows everything near a tile, as it did." },

  /* ---- Chips ---- */
  { name: "Ballast Chip", build: menu("sphere", "common", "K1", 1), merges: ["Bolstering Chip", "Static Veil"], why: "AC +1 for a turn. Bolstering Chip and Static Veil (an Aether card) did the same and fold into it." },
  { name: "Bastion Chip", build: menu("sphere", "epic", "K1", 3), why: "AC +2 for a turn, as it was; Epic now (AC +2 is tier III)." },
  { name: "Barbed Chip", build: menu("sphere", "rare", "K2", 2), why: "DMG +1, as it was." },
  { name: "Surge Chip", build: menu("sphere", "uncommon", "K3", 1), merges: ["Invigorating Chip"], why: "NRG +1. Invigorating Chip did the same and folds into it." },
  { name: "Quiet Chip", build: menu("sphere", "uncommon", "K4", 1), why: "Evasive for a turn (2, from 4)." },
  { name: "Spring Chip", build: menu("sphere", "uncommon", "K5", 1), why: "Dash 1, as it was." },
  { name: "Gyro Chip", build: menu("sphere", "rare", "K6", 2), why: "Leap for a turn." },
  { name: "Mending Chip", build: menu("sphere", "rare", "K7", 2), why: "Heals 4 (from 5)." },
  { name: "Sparking chip", build: menu("sphere", "rare", "K8", 2), why: "Damage 2 (from 1)." },
  { name: "Ledger Chip", build: menu("sphere", "rare", "K9", 1), why: "Aether, as it was." },
  { name: "Dampening Chip", build: menu("sphere", "epic", "K10", 1), why: "Hardened for a turn, as it was." },

  /* ---- Consumables ---- */
  { name: "Field Dressing", build: menu("consumable", "common", "N1", 1), merges: ["Repair Kit"], why: "Heals 6. Repair Kit did the same and folds into it." },
  { name: "Medical Supplies", build: menu("consumable", "uncommon", "N7", 1), why: "Recover, as it was." },
  { name: "Smoke Canister", build: menu("consumable", "uncommon", "N5", 1), why: "Evasive 2, as it was." },
  { name: "Adrenal Shot", build: menu("consumable", "common", "N10", 1), why: "NRG +2, as it was." },
  { name: "Breach Charge", build: menu("consumable", "rare", "N6", 2), why: "Damage 6, as it was." },
  { name: "Signal Flare", build: menu("consumable", "common", "N9", 1), why: "Aim +1 for everyone, as it was." },
  { name: "Coolant Flush", build: menu("consumable", "uncommon", "N2", 1), why: "Clears Poisoned (Bleed folds into it) and Slowed, and heals a little." },
  { name: "Ration Pack", build: menu("consumable", "common", "N8", 1), why: "HP +4 for the fight, as it was." },
  { name: "Grapple Line", build: menu("consumable", "uncommon", "N3", 1), merges: ["Adrenal Overdrive"], why: "Dash 3. Adrenal Overdrive did the same (and a little damage) and folds into it." },
  { name: "Grav-Boot Charge", build: menu("consumable", "common", "N4", 1), why: "Leap 3, as it was." },

  /* ---- Prototypes ---- */
  { name: "Ledger Core", build: menu("prototype", "rare", "R5", 1), why: "Aether every round, as it was." },
  { name: "Harmonic Damper", build: menu("prototype", "epic", "R4", 1), why: "Hardened for everyone, as it was; Epic now." },
  { name: "Field Triage", build: menu("prototype", "uncommon", "R3", 1), why: "Heals everyone a little each round." },
  { name: "Targeting Mesh", build: menu("prototype", "uncommon", "R1", 1), why: "Aim +1 for everyone, as it was." },
  { name: "Reinforced Frames", build: menu("prototype", "common", "R2", 1), why: "HP +2 for every Troop, as it was." },
  { name: "Scavenger Protocol", build: menu("prototype", "uncommon", "R6", 1), why: "A card when a Troop falls, as it was." },
  { name: "Kinetic Recycler", build: menu("prototype", "rare", "R7", 2), why: "Dash after a kill (2, from 1)." },
  { name: "Gantry Mapper", build: menu("prototype", "uncommon", "R8", 1), why: "Leap 2 for everyone." },
];

/* Left as they are: the tokens other cards bring (a token isn't built), and Aether battery's own. */
const KEPT = ["Scuttlebot", "Sentry Turret", "FALCON Drone Token", "Aether Battery"];
/* Retired without a merge: its job has no place in one card any more. */
const RETIRED_ALONE = { "Aether battery": "Deploy X batteries for X: the Lab has no variable cost, and Aether every round is for Prototypes and the Reactor." };

/* ---------------------------------------------------------------- make the set */
function fail(msg){ console.error("make_lab_set: " + msg); process.exitCode = 1; }
function costOf(total, was){
  // the typed cost: the suggested total, with as much of it Affinity as the card had
  const a = was && was.aetherCost && typeof was.aetherCost === "object" ? (parseInt(was.aetherCost.affinity, 10) || 0) : 0;
  const aff = Math.min(Math.max(0, a), total);
  return { generic: total - aff, affinity: aff, affinity2: 0 };
}
function textProblems(card){
  const out = [];
  (card.entries || []).forEach(e => {
    KW.sentences(e.text || "").forEach(s => {
      const an = KW.analyse(s);
      an.bad.forEach(p => out.push((e.name || card.name) + ": unknown keyword " + (p.name || p.raw || "?")));
      KW.problems(an, { kind: KW.kindOf(e.kind) }).forEach(p => out.push((e.name || card.name) + ": " + p));
    });
  });
  return out;
}

const seen = {}, out = [], retired = [], report = [];
const real = MASTER.filter(c => !c.testCard);
CARDS.forEach(x => {
  if(seen[x.name]) fail("twice: " + x.name);
  seen[x.name] = 1;
  const wasName = x.was || x.name, was = byName[wasName];
  if(!was && !x.meta) fail("no master card " + wasName + " (and no meta for a new card)");
  const r = L.compile(x.build);
  if(!r.card) fail(x.name + ": no card (" + r.problems.join("; ") + ")");
  if(r.problems.length) fail(x.name + ": " + r.problems.join("; "));
  const tp = r.card ? textProblems(r.card) : [];
  if(tp.length) fail(x.name + ": " + tp.join("; "));
  (x.merges || []).forEach(m => { if(!byName[m]) fail(x.name + " merges " + m + ", which isn't a master card"); retired.push(m); });
  const e = { name: x.name, build: L.norm(x.build) };
  if(x.id) e.id = x.id; else if(was && was.id) e.id = was.id;
  if(x.was) e.was = x.was;
  if(x.art) e.art = x.art;
  if(x.meta) e.meta = x.meta;
  if(x.merges) e.merges = x.merges;
  const type = x.build.type;
  // the typed cost (Q6): a Troop the suggested Aether for its points; a menu card its tier's; an Action card its tier
  if(type === "troop") e.aetherCost = costOf(L.suggestedAether(r.points), was);
  else if(r.cost != null) e.aetherCost = costOf(r.cost, was);
  e.change = x.meta ? "new" : (x.was ? "split" : (x.merges ? "merged" : ((was && String(was.cardType) !== type) ? "retyped" : "rebuilt")));
  e.why = x.why;
  out.push(e);
  report.push({ name: x.name, type, rarity: x.build.rarity || null, skull: x.build.skull || null, points: r.points, target: r.target,
    cost: e.aetherCost ? e.aetherCost.generic + e.aetherCost.affinity : null, change: e.change,
    was: was ? { type: was.cardType, entries: (was.entries || []).length } : null, entries: r.card ? r.card.entries.length : 0 });
});
Object.keys(RETIRED_ALONE).forEach(n => { if(!byName[n]) fail("retires " + n + ", which isn't a master card"); retired.push(n); });
// every real master card is accounted for: built, merged, split, kept, or retired
const covered = {};
out.forEach(e => { covered[e.was || e.name] = 1; });
retired.forEach(n => { covered[n] = 1; });
KEPT.forEach(n => { covered[n] = 1; });
real.forEach(c => { if(!covered[c.name]) fail("no Lab build for " + c.name); });
retired.forEach(n => { if(seen[n]) fail(n + " is both retired and built"); });

const set = { format: 1, version: SET_VERSION, systems: D.version, name: "KETER Lab set",
  note: "Built by lab/make_lab_set.js. Each card is a build; the apps compile it with the Lab systems (lab_systems.json).",
  cards: out, retired: retired.map(n => ({ name: n, into: (out.find(e => (e.merges || []).indexOf(n) >= 0) || {}).name || null,
    why: RETIRED_ALONE[n] || null })), kept: KEPT };
if(process.exitCode){ console.error("make_lab_set: not written"); process.exit(1); }
fs.writeFileSync(path.join(ROOT, "game", "data", "lab_set.json"), JSON.stringify(set, null, 1) + "\n");
fs.writeFileSync(path.join(ROOT, "lab_set.js"), "/* Generated by lab/make_lab_set.js: the KETER Lab card set, for lab.js. Don't edit by hand. */\nwindow.KETER_LAB_SET=" + JSON.stringify(set) + ";\n");
if(process.argv.indexOf("--report") >= 0) fs.writeFileSync(process.argv[process.argv.indexOf("--report") + 1], JSON.stringify(report, null, 1));

const counts = {};
out.forEach(e => { counts[e.change] = (counts[e.change] || 0) + 1; });
console.log("lab set %s (systems %s): %d cards (%s), %d retired, %d kept as they are, %d test cards untouched",
  SET_VERSION, D.version, out.length, Object.keys(counts).map(k => counts[k] + " " + k).join(", "), retired.length, KEPT.length, MASTER.length - real.length);
report.filter(r => r.target != null).forEach(r => {
  const gap = r.points - r.target;
  if(Math.abs(gap) > 4) console.log("  %s (%s %s): %d points, target %d (%s%d)", r.name, r.rarity, r.type, r.points, r.target, gap > 0 ? "+" : "", gap);
});
