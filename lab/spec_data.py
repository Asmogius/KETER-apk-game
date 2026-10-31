"""KETER Lab card systems, draft 1: the data the review page shows and the build will read.

Every number on a Lab card comes from here: a stat line from the tables, abilities from the
library at a tier, non-unit cards from their type's menu. compile_unit() turns a build into an
ordinary card (stats, entries, keyword text), so the engine plays it unchanged."""
import math

RARITIES = ["common", "uncommon", "rare", "epic", "legendary", "mythic"]
ROLES = ["brute", "skirmisher", "shooter", "support"]
ROLE_NAME = {"brute": "Brute", "skirmisher": "Skirmisher", "shooter": "Shooter", "support": "Support"}
ROLE_DOES = {"brute": "melee, holds the line: most Health, slow", "skirmisher": "melee, fast and hard to pin down, fragile",
             "shooter": "ranged damage", "support": "heals and orders; a weak ranged attack"}
ROLE_ATTACK = {"brute": "melee", "skirmisher": "melee", "shooter": "ranged", "support": "ranged"}

# ---------------------------------------------------------------- S · the stat tables
# Troops, Standard size, Common. Attack: damage, range, to-hit (d20 to reach, lower is better), armour piercing.
TROOP = {
    "brute":      {"hp": 26, "ac": 11, "ms": 3, "nrg": 3, "dmg": 7, "rng": 1, "hit": None, "ap": 3},
    "skirmisher": {"hp": 16, "ac": 12, "ms": 5, "nrg": 3, "dmg": 6, "rng": 1, "hit": None, "ap": 4},
    "shooter":    {"hp": 18, "ac": 11, "ms": 3, "nrg": 3, "dmg": 6, "rng": 4, "hit": 11, "ap": 2},
    "support":    {"hp": 18, "ac": 11, "ms": 3, "nrg": 4, "dmg": 3, "rng": 3, "hit": 11, "ap": 1},
}
SIZES = ["light", "standard", "heavy", "colossal"]
SIZE = {   # hp multiplier and the steps added to the Standard line; slots taken; Aether a copy costs before abilities
    "light":    {"hp": 0.6, "ac": -1, "ms": 1, "nrg": -1, "dmg": -2, "ap": 0, "slots": 1, "base": 1, "price": 12, "note": "swarms, drones, tokens"},
    "standard": {"hp": 1.0, "ac": 0, "ms": 0, "nrg": 0, "dmg": 0, "ap": 0, "slots": 1, "base": 2, "price": 20, "note": "the ordinary Troop"},
    "heavy":    {"hp": 1.5, "ac": 2, "ms": -1, "nrg": 0, "dmg": 3, "ap": 1, "slots": 2, "base": 4, "price": 30, "note": "bots and walkers"},
    "colossal": {"hp": 2.0, "ac": 3, "ms": -1, "nrg": 0, "dmg": 5, "ap": 2, "slots": 3, "base": 6, "price": 42, "note": "Legendary and Mythic only"},
}
# Rarity: a little more of everything (Q1), and how far the abilities may go
RARITY = {
    "common":    {"hp": 0, "ac": 0, "ap": 0, "tier": 1, "abilities": 1, "price": 0},
    "uncommon":  {"hp": 2, "ac": 0, "ap": 0, "tier": 2, "abilities": 2, "price": 2},
    "rare":      {"hp": 4, "ac": 1, "ap": 1, "tier": 2, "abilities": 2, "price": 5},
    "epic":      {"hp": 6, "ac": 1, "ap": 1, "tier": 3, "abilities": 2, "price": 8},
    "legendary": {"hp": 8, "ac": 2, "ap": 2, "tier": 3, "abilities": 2, "price": 11},
    "mythic":    {"hp": 10, "ac": 2, "ap": 2, "tier": 3, "abilities": 2, "price": 13},
}
# One trade a card, either way
TRADES = [("hp", 4, "ms", 1), ("hp", 3, "ac", 1), ("hp", 3, "rng", 1), ("hp", 4, "nrg", 1)]

# Heroes, Common. Energy is their own (apT); Leadership the Troops that start beside them; slots the Action cards they carry.
HERO = {
    "brute":      {"hp": 36, "ac": 11, "ms": 3, "nrg": 4, "dmg": 8, "rng": 1, "hit": None, "ap": 4, "ldr": 2, "slots": 1},
    "skirmisher": {"hp": 28, "ac": 13, "ms": 5, "nrg": 4, "dmg": 7, "rng": 1, "hit": None, "ap": 6, "ldr": 2, "slots": 1},
    "shooter":    {"hp": 26, "ac": 12, "ms": 3, "nrg": 4, "dmg": 6, "rng": 5, "hit": 10, "ap": 3, "ldr": 2, "slots": 1},
    "support":    {"hp": 24, "ac": 11, "ms": 3, "nrg": 4, "dmg": 3, "rng": 3, "hit": 9, "ap": 2, "ldr": 3, "slots": 1},
}
HERO_RARITY = {
    "common":    {"hp": 0, "ac": 0, "ap": 0, "ldr": 0, "slots": 0},
    "uncommon":  {"hp": 3, "ac": 0, "ap": 0, "ldr": 0, "slots": 0},
    "rare":      {"hp": 6, "ac": 1, "ap": 1, "ldr": 0, "slots": 1},
    "epic":      {"hp": 9, "ac": 1, "ap": 1, "ldr": 1, "slots": 1},
    "legendary": {"hp": 12, "ac": 2, "ap": 2, "ldr": 1, "slots": 1},
}

# Enemies by Skull Level 1-6, Standard size. Enemies have no rarity.
ENEMY = {
    "brute":      {"hp": [18, 26, 34, 42, 52, 62], "ac": [6, 8, 10, 11, 12, 13], "ms": [3] * 6, "dmg": [5, 6, 8, 9, 11, 12], "rng": [1] * 6, "hit": [None] * 6, "ap": [1, 2, 3, 4, 5, 6]},
    "skirmisher": {"hp": [12, 18, 24, 30, 36, 42], "ac": [8, 10, 12, 13, 14, 15], "ms": [5] * 6, "dmg": [4, 5, 6, 8, 9, 10], "rng": [1] * 6, "hit": [None] * 6, "ap": [2, 3, 4, 5, 6, 7]},
    "shooter":    {"hp": [14, 20, 26, 32, 40, 48], "ac": [6, 8, 10, 11, 12, 13], "ms": [3] * 6, "dmg": [4, 5, 7, 8, 10, 11], "rng": [4, 4, 5, 5, 6, 6], "hit": [9, 9, 8, 8, 7, 7], "ap": [1, 2, 3, 4, 5, 6]},
    "support":    {"hp": [14, 20, 26, 32, 40, 48], "ac": [6, 8, 10, 11, 12, 13], "ms": [3] * 6, "dmg": [2, 3, 4, 5, 6, 7], "rng": [3] * 6, "hit": [9, 9, 9, 8, 8, 8], "ap": [1, 1, 2, 2, 3, 3]},
}
ENEMY_SIZE = {"light": {"hp": 0.5, "ac": 0, "ms": 1, "dmg": -1, "note": "swarms and husks"},
              "standard": {"hp": 1.0, "ac": 0, "ms": 0, "dmg": 0, "note": "the ordinary Enemy"},
              "heavy": {"hp": 1.4, "ac": 1, "ms": -1, "dmg": 2, "note": "Titans"}}
ENEMY_TIER = [1, 1, 2, 2, 3, 3]          # the highest ability tier at Skull 1..6
ENEMY_ABILITIES = [1, 1, 2, 2, 2, 2]     # how many library abilities at Skull 1..6
GRADE = {"enemy": {"hp": 1, "ac": 0, "dmg": 0, "ap": 0, "abilities": 0, "tier": 0, "note": "drawn from the Enemy Card Piles"},
         "elite": {"hp": 2, "ac": 1, "dmg": 2, "ap": 1, "abilities": 0, "tier": 1, "note": "through Dimensional Instability"},
         "miniboss": {"hp": 3, "ac": 2, "dmg": 3, "ap": 2, "abilities": 1, "tier": 1, "note": "through Instability; one ability may be an Aura"}}

# ---------------------------------------------------------------- A · the ability library
# kind: attack (a second attack, the basic line changed), support (an Action on an ally or a tile),
# passive, aura. roles: the unit roles that may take it. tiers: three dicts (or one), each with
# the numbers that tier uses, its Energy (e) and its price (p). text(t) gives the keyword text.
A = []


def ab(id, name, kind, roles, does, tiers, text, line=None):
    A.append({"id": id, "name": name, "kind": kind, "roles": roles, "does": does, "tiers": tiers, "text": text, "line": line or (lambda t: {})})


MELEE, RANGED, ANY_ATTACK = ["brute", "skirmisher"], ["shooter", "support"], ["brute", "skirmisher", "shooter", "support"]
ALL = ["brute", "skirmisher", "shooter", "support"]

# attacks
ab("A1", "Heavy Blow", "attack", MELEE, "A harder hit.",
   [{"dmg": 3, "e": 2, "p": 3}, {"dmg": 5, "e": 2, "p": 5}, {"dmg": 7, "e": 3, "p": 8}],
   lambda t: "", lambda t: {"dmg": t["dmg"]})
ab("A2", "Cleave", "attack", MELEE, "Several blows for one payment of Energy.",
   [{"n": 2, "dmg": -2, "e": 2, "p": 4}, {"n": 2, "dmg": -1, "e": 2, "p": 6}, {"n": 3, "dmg": -1, "e": 3, "p": 9}],
   lambda t: "[[Burst %d]]." % t["n"], lambda t: {"dmg": t["dmg"]})
ab("A3", "Pounce", "attack", MELEE, "Closes the distance before it strikes.",
   [{"n": 2, "dmg": 0, "e": 2, "p": 3}, {"n": 3, "dmg": 1, "e": 2, "p": 5}, {"n": 4, "dmg": 2, "e": 2, "p": 7}],
   lambda t: "[[Lunge %d]]." % t["n"], lambda t: {"dmg": t["dmg"]})
ab("A4", "Shove", "attack", MELEE, "Knocks the target back.",
   [{"n": 1, "dmg": -2, "e": 1, "p": 2}, {"n": 2, "dmg": 0, "e": 2, "p": 4}, {"n": 2, "dmg": 2, "e": 2, "p": 6}],
   lambda t: "[[target enemy]] takes [[Push %d]]." % t["n"], lambda t: {"dmg": t["dmg"]})
ab("A5", "Stagger", "attack", MELEE, "Stuns the target for a turn.",
   [{"dmg": -2, "e": 3, "p": 5}, {"dmg": 0, "e": 3, "p": 7}, {"dmg": 2, "e": 2, "p": 9}],
   lambda t: "[[target enemy]] gains [[Stunned]] for [[turns 1]].", lambda t: {"dmg": t["dmg"]})
ab("A6", "Hamstring", "attack", ANY_ATTACK, "Slows the target.",
   [{"n": 1, "d": 1, "e": 1, "p": 2}, {"n": 2, "d": 1, "e": 2, "p": 4}, {"n": 2, "d": 2, "e": 2, "p": 6}],
   lambda t: "[[target enemy]] gains [[Slowed %d]] for [[turns %d]]." % (t["n"], t["d"]))
ab("A7", "Snare", "attack", ANY_ATTACK, "Roots the target for a turn.",
   [{"dmg": -2, "e": 2, "p": 4}, {"dmg": 0, "e": 2, "p": 6}, {"dmg": 2, "e": 2, "p": 8}],
   lambda t: "[[target enemy]] gains [[Rooted]] for [[turns 1]].", lambda t: {"dmg": t["dmg"]})
ab("A8", "Venom", "attack", ANY_ATTACK, "Poisons the target for two turns (Bleed folds into this).",
   [{"n": 2, "e": 2, "p": 3}, {"n": 3, "e": 2, "p": 5}, {"n": 4, "e": 2, "p": 7}],
   lambda t: "[[target enemy]] gains [[Poisoned %d]] for [[turns 2]]." % t["n"])
ab("A9", "Sap", "attack", RANGED, "Weakens the target's attacks.",
   [{"n": 1, "d": 1, "e": 1, "p": 2}, {"n": 2, "d": 1, "e": 2, "p": 4}, {"n": 2, "d": 2, "e": 2, "p": 6}],
   lambda t: "[[target enemy]] gains [[Weakened %d]] for [[turns %d]]." % (t["n"], t["d"]))
ab("A10", "Mark", "attack", RANGED, "Ranged attacks on the target always hit (Pinned folds into this).",
   [{"d": 1, "dmg": -3, "e": 1, "p": 3}, {"d": 1, "dmg": -2, "e": 1, "p": 4}, {"d": 2, "dmg": 0, "e": 1, "p": 6}],
   lambda t: "[[target enemy]] gains [[Marked]] for [[turns %d]]." % t["d"], lambda t: {"dmg": t["dmg"]})
ab("A11", "Volley", "attack", RANGED, "Hits everything around the target (Line and Cone fold into this).",
   [{"n": 1, "dmg": -2, "e": 3, "p": 5}, {"n": 1, "dmg": 0, "e": 3, "p": 7}, {"n": 2, "dmg": 0, "e": 3, "p": 10}],
   lambda t: "[[AoE %d]]." % t["n"], lambda t: {"dmg": t["dmg"]})
ab("A12", "Rapid Fire", "attack", RANGED, "Several shots for one payment of Energy.",
   [{"n": 2, "dmg": -2, "e": 2, "p": 4}, {"n": 2, "dmg": -1, "e": 2, "p": 6}, {"n": 3, "dmg": -1, "e": 3, "p": 9}],
   lambda t: "[[Burst %d]]." % t["n"], lambda t: {"dmg": t["dmg"]})
ab("A13", "Snipe", "attack", RANGED, "Longer and surer; at III the shot carries on to the Unit behind.",
   [{"rng": 2, "hit": -1, "e": 2, "p": 3}, {"rng": 3, "hit": -2, "e": 2, "p": 5}, {"rng": 4, "hit": -2, "pierce": True, "e": 2, "p": 8}],
   lambda t: "[[Pierce]]." if t.get("pierce") else "", lambda t: {"rng": t["rng"], "hit": t["hit"]})
ab("A14", "Finisher", "attack", MELEE, "Extra damage to a target below half its Health (Execute folds into this).",
   [{"n": 3, "e": 2, "p": 3}, {"n": 5, "e": 2, "p": 5}, {"n": 7, "e": 2, "p": 7}],
   lambda t: "[[if]] [[the target]] [[is below half HP]], [[target enemy]] takes [[damage %d]]." % t["n"])
ab("A15", "Overcharge", "attack", ANY_ATTACK, "Much more damage, at a cost to itself.",
   [{"dmg": 4, "self": 2, "e": 2, "p": 3}, {"dmg": 6, "self": 3, "e": 2, "p": 5}, {"dmg": 8, "self": 3, "e": 3, "p": 7}],
   lambda t: "[[this Unit]] takes [[damage %d]]." % t["self"], lambda t: {"dmg": t["dmg"]})

# support actions
ab("S1", "Mend", "support", ALL, "Heals an ally.",
   [{"n": 4, "e": 1, "p": 3}, {"n": 6, "e": 1, "p": 5}, {"n": 8, "e": 2, "p": 7}],
   lambda t: "[[target ally]] gains [[heal %d]]." % t["n"])
ab("S2", "Rally", "support", ALL, "An ally hits harder.",
   [{"n": 1, "d": 1, "e": 1, "p": 2}, {"n": 2, "d": 1, "e": 1, "p": 4}, {"n": 3, "d": 2, "e": 2, "p": 7}],
   lambda t: "[[target ally]] gains [[DMG +%d]] for [[turns %d]]." % (t["n"], t["d"]))
ab("S3", "Brace", "support", ALL, "An ally is harder to penetrate; at III it also shrugs off damage.",
   [{"n": 1, "e": 1, "p": 2}, {"n": 2, "e": 1, "p": 4}, {"n": 2, "hard": 1, "e": 1, "p": 6}],
   lambda t: "[[target ally]] gains [[AC +%d]] for [[turns 1]]." % t["n"] + (" [[target ally]] gains [[Hardened %d]] for [[turns 1]]." % t["hard"] if t.get("hard") else ""))
ab("S4", "Boost", "support", ALL, "An ally gets more Energy (Drained folds into NRG -).",
   [{"n": 1, "e": 1, "p": 3}, {"n": 1, "e": 0, "p": 5}, {"n": 2, "e": 1, "p": 7}],
   lambda t: "[[target ally]] gains [[NRG +%d]] for [[turns 1]]." % t["n"])
ab("S5", "Reposition", "support", ALL, "An ally moves extra tiles.",
   [{"n": 2, "e": 1, "p": 2}, {"n": 3, "e": 1, "p": 3}, {"n": 4, "e": 1, "p": 5}],
   lambda t: "[[target ally]] gains [[Dash %d]]." % t["n"])
ab("S6", "Cleanse", "support", ALL, "Clears Poisoned and Slowed; heals at II; everyone near at III.",
   [{"e": 1, "p": 2}, {"heal": 3, "e": 1, "p": 4}, {"heal": 3, "area": 1, "e": 2, "p": 6}],
   lambda t: (lambda who: "%s gain[s] [[remove Poisoned]]. %s gain[s] [[remove Slowed]]." % (who, who) + (" %s gain[s] [[heal %d]]." % (who, t["heal"]) if t.get("heal") else ""))("[[all allies within 1]]" if t.get("area") else "[[target ally]]").replace("gain[s]", "gain" if t.get("area") else "gains"))
ab("S7", "Summon", "support", ALL, "Deploys tokens beside it (the token is chosen for the card).",
   [{"n": 1, "e": 3, "p": 5}, {"n": 1, "e": 2, "p": 6}, {"n": 2, "e": 3, "p": 9}],
   lambda t: "[[Deploy %d {token}]] [[adjacent]]." % t["n"])
ab("S8", "Fortify", "support", ALL, "Puts down cover.",
   [{"cover": "Half", "e": 2, "p": 3}, {"cover": "Half", "e": 1, "p": 4}, {"cover": "Full", "e": 2, "p": 6}],
   lambda t: "[[Barricade %s]] on [[target tile]]." % t["cover"])
ab("S9", "Leap Jets", "support", ALL, "Jumps over Units and walls this turn; harder to hit at II and III.",
   [{"n": 3, "ev": 0, "e": 1, "p": 2}, {"n": 4, "ev": 1, "e": 1, "p": 3}, {"n": 5, "ev": 2, "e": 1, "p": 5}],
   lambda t: "[[this Unit]] gains [[Leap %d]] for [[turns 1]]." % t["n"] + (" [[this Unit]] gains [[Evasive %d]] for [[turns 1]]." % t["ev"] if t["ev"] else ""))

# passives (always on, or on a trigger)
ab("P1", "Tough", "passive", ALL, "More Health.", [{"n": 4, "p": 2}, {"n": 8, "p": 4}, {"n": 12, "p": 6}],
   lambda t: "[[this Unit]] gains [[HP +%d]]." % t["n"])
ab("P2", "Plated", "passive", ALL, "Every hit on it deals less (Sundered and Hardened fold into AC and this).",
   [{"n": 1, "p": 4}, {"n": 1, "ac": 1, "p": 6}, {"n": 2, "ac": 1, "p": 9}],
   lambda t: "[[this Unit]] gains [[Hardened %d]]." % t["n"] + (" [[this Unit]] gains [[AC +%d]]." % t["ac"] if t.get("ac") else ""))
ab("P3", "Elusive", "passive", ALL, "Ranged attacks need more to hit it (Flying folds into this and Agile).",
   [{"n": 1, "p": 2}, {"n": 2, "p": 4}, {"n": 3, "p": 6}], lambda t: "[[this Unit]] gains [[Evasive %d]]." % t["n"])
ab("P4", "Agile", "passive", ALL, "Jumps over Units, cover and walls when it moves.",
   [{"n": 2, "p": 2}, {"n": 3, "p": 3}, {"n": 4, "p": 4}], lambda t: "[[this Unit]] gains [[Leap %d]]." % t["n"])
ab("P5", "Fleet", "passive", ALL, "More Movement.", [{"n": 1, "p": 2}, {"n": 2, "p": 4}, {"n": 3, "p": 6}],
   lambda t: "[[this Unit]] gains [[MS +%d]]." % t["n"])
ab("P6", "Marksman", "passive", ["shooter", "support"], "Its ranged attacks need less to hit.",
   [{"n": 1, "p": 2}, {"n": 2, "p": 4}, {"n": 3, "p": 6}], lambda t: "[[this Unit]] gains [[Aim +%d]]." % t["n"])
ab("P7", "Armored", "passive", ALL, "Higher Armor Class.", [{"n": 1, "p": 3}, {"n": 2, "p": 5}, {"n": 3, "p": 8}],
   lambda t: "[[this Unit]] gains [[AC +%d]]." % t["n"])
ab("P8", "Long Barrel", "passive", ["shooter", "support"], "Longer range.", [{"n": 1, "p": 2}, {"n": 1, "p": 3}, {"n": 2, "p": 5}],
   lambda t: "[[this Unit]] gains [[Range +%d]]." % t["n"])
ab("P9", "Berserk", "passive", ALL, "Hits harder once below half Health.", [{"n": 2, "p": 2}, {"n": 3, "p": 3}, {"n": 4, "p": 5}],
   lambda t: "[[while]] [[this Unit]] [[is below half HP]], [[this Unit]] gains [[DMG +%d]]." % t["n"])
ab("P10", "Momentum", "passive", ALL, "Moves on after a kill.", [{"n": 2, "p": 2}, {"n": 3, "p": 3}, {"n": 4, "p": 4}],
   lambda t: "[[when]] [[this Unit]] [[kills an enemy]], [[this Unit]] gains [[Dash %d]]." % t["n"])
ab("P11", "Payback", "passive", ALL, "Whoever attacks it takes damage.", [{"n": 2, "p": 3}, {"n": 3, "p": 5}, {"n": 4, "p": 7}],
   lambda t: "[[when]] [[this Unit]] [[is attacked]], [[target enemy]] takes [[damage %d]]." % t["n"])
ab("P12", "Last Stand", "passive", ALL, "Going down hurts the Enemies beside it.", [{"n": 3, "p": 2}, {"n": 5, "p": 4}, {"n": 7, "p": 6}],
   lambda t: "[[when]] [[this Unit]] [[is Incapacitated]], [[all enemies within 1]] take [[damage %d]]." % t["n"])
ab("P13", "Warm-up", "passive", ALL, "Hits harder each round, for a while.", [{"n": 1, "d": 1, "p": 2}, {"n": 1, "d": 2, "p": 4}, {"n": 2, "d": 2, "p": 6}],
   lambda t: "[[when]] [[the round begins]], [[this Unit]] gains [[DMG +%d]] for [[turns %d]]." % (t["n"], t["d"]))
ab("P14", "Escort", "passive", ALL, "Arrives with tokens (the token is chosen for the card).", [{"n": 1, "p": 4}, {"n": 2, "p": 7}, {"n": 3, "p": 10}],
   lambda t: "[[when]] [[this Unit]] [[is deployed]], [[Deploy %d {token}]] [[adjacent]]." % t["n"])
ab("P15", "Reactor", "passive", ALL, "Makes Aether every round. One tier; Epic and rarer.", [{"p": 10}],
   lambda t: "[[when]] [[the round begins]], [[gain Aether 1]].")
ab("P16", "Scavenger", "passive", ALL, "Makes Aether from kills. One tier.", [{"p": 4}],
   lambda t: "[[when]] [[this Unit]] [[kills an enemy]], [[gain Aether 1]].")

# auras
ab("U1", "Guard Aura", "aura", ALL, "Allies beside it are harder to penetrate.",
   [{"r": 1, "n": 1, "p": 5}, {"r": 1, "n": 2, "p": 7}, {"r": 2, "n": 2, "p": 10}],
   lambda t: "[[Aura %d]]: [[all allies within %d]] gain [[AC +%d]]." % (t["r"], t["r"], t["n"]))
ab("U2", "War Aura", "aura", ALL, "Allies near it hit harder.",
   [{"r": 1, "n": 1, "p": 5}, {"r": 2, "n": 1, "p": 7}, {"r": 2, "n": 2, "p": 10}],
   lambda t: "[[Aura %d]]: [[all allies within %d]] gain [[DMG +%d]]." % (t["r"], t["r"], t["n"]))
ab("U3", "Spotter Aura", "aura", ALL, "Allies near it shoot surer.",
   [{"r": 2, "n": 1, "p": 4}, {"r": 2, "n": 2, "p": 6}, {"r": 3, "n": 2, "p": 8}],
   lambda t: "[[Aura %d]]: [[all allies within %d]] gain [[Aim +%d]]." % (t["r"], t["r"], t["n"]))
ab("U4", "Haste Aura", "aura", ALL, "Allies near it move further.",
   [{"r": 2, "n": 1, "p": 3}, {"r": 2, "n": 1, "p": 5}, {"r": 3, "n": 2, "p": 7}],
   lambda t: "[[Aura %d]]: [[all allies within %d]] gain [[MS +%d]]." % (t["r"], t["r"], t["n"]))
ab("U5", "Reach Aura", "aura", ALL, "Allies near it shoot further.",
   [{"r": 1, "n": 1, "p": 3}, {"r": 2, "n": 1, "p": 5}, {"r": 2, "n": 2, "p": 7}],
   lambda t: "[[Aura %d]]: [[all allies within %d]] gain [[Range +%d]]." % (t["r"], t["r"], t["n"]))

BY_ID = {a["id"]: a for a in A}
TOKENS = ["Scuttlebot", "Sentry Turret", "FALCON Drone Token", "Exo Worker Husk", "Aether Battery"]

# ---------------------------------------------------------------- M · menus for the other card types
# each item: id, name, what it does at tiers I-III (plain), the keyword text, suggested Aether by tier
M = {}


def menu(type_, id, name, tiers, text, cost=None, note=""):
    M.setdefault(type_, []).append({"id": id, "name": name, "tiers": tiers, "text": text, "cost": cost, "note": note})


# Commands: an order to the whole team, for a turn
menu("command", "C1", "Rally Cry", [{"n": 1, "d": 1}, {"n": 2, "d": 1}, {"n": 2, "d": 2}], lambda t: "[[all allies]] gain [[DMG +%d]] for [[turns %d]]." % (t["n"], t["d"]), [2, 3, 4])
menu("command", "C2", "Brace", [{"n": 1}, {"n": 2}, {"n": 2, "hard": 1}], lambda t: "[[all allies]] gain [[AC +%d]] for [[turns 1]]." % t["n"] + (" [[all allies]] gain [[Hardened 1]] for [[turns 1]]." if t.get("hard") else ""), [2, 3, 4])
menu("command", "C3", "Advance", [{"n": 2}, {"n": 3}, {"n": 4}], lambda t: "[[all allies]] gain [[Dash %d]]." % t["n"], [1, 2, 3])
menu("command", "C4", "Focus Fire", [{"d": 1}, {"d": 2}, {"d": 2, "weak": 1}], lambda t: "[[target enemy]] gains [[Marked]] for [[turns %d]]." % t["d"] + (" [[target enemy]] gains [[Weakened 1]] for [[turns 2]]." if t.get("weak") else ""), [1, 2, 3])
menu("command", "C5", "Requisition", [{"n": 2}, {"n": 3}, {"n": 4}], lambda t: "[[Draw %d]]." % t["n"], [2, 3, 4])
menu("command", "C6", "Recall", [{"draw": 0}, {"draw": 1}, {"draw": 2}], lambda t: "[[Recover]] a Troop's card from the Discard Pile." + (" [[Draw %d]]." % t["draw"] if t["draw"] else ""), [1, 2, 3])
menu("command", "C7", "Lockdown", [{"s": "Rooted"}, {"s": "Stunned"}, {"s": "Rooted", "area": 1}], lambda t: ("[[all enemies within 1]] of [[target tile]] gain" if t.get("area") else "[[target enemy]] gains") + " [[%s]] for [[turns 1]]." % t["s"], [2, 3, 4])
menu("command", "C8", "Overdrive", [{"x": 0}, {"x": 1}, {"x": 2}], lambda t: "[[all allies]] [[Troop]] gain [[NRG +1]] for [[turns 1]]." + (" [[all allies]] [[Troop]] gain [[MS +1]] for [[turns 1]]." if t["x"] >= 1 else "") + (" [[all allies]] [[Troop]] gain [[DMG +1]] for [[turns 1]]." if t["x"] >= 2 else ""), [2, 3, 4])
# Aether cards: direct power on the board
menu("aether", "E1", "Bolt", [{"n": 3}, {"n": 5}, {"n": 7}], lambda t: "[[target enemy]] takes [[damage %d]]." % t["n"], [2, 3, 4])
menu("aether", "E2", "Blast", [{"n": 3}, {"n": 4}, {"n": 5}], lambda t: "[[all units within 1]] of [[target tile]] take [[damage %d]]." % t["n"], [3, 4, 5], "friend or foe")
menu("aether", "E3", "Lance", [{"n": 4}, {"n": 6}, {"n": 8}], lambda t: "[[target enemy]] takes [[damage %d]]. [[Pierce]]." % t["n"], [3, 4, 5])
menu("aether", "E4", "Barrier", [{"c": "Half"}, {"c": "Half"}, {"c": "Full"}], lambda t: "[[Barricade %s]] on [[target tile]]." % t["c"], [3, 2, 4])
menu("aether", "E5", "Sentry", [{"n": 1}, {"n": 1}, {"n": 2}], lambda t: "[[Deploy %d Sentry Turret]] [[adjacent]]." % t["n"], [3, 2, 4])
menu("aether", "E6", "Salvage", [{"n": 1}, {"n": 2}, {"n": 2, "rec": 1}], lambda t: "[[target ally]] [[Troop]] is spent as a [[Sacrifice]]. [[gain Aether %d]]." % t["n"] + (" [[Recover]] a Troop's card from the Discard Pile." if t.get("rec") else ""), [1, 1, 2], "Sacrifice stays only here")
menu("aether", "E7", "Gravity Well", [{"r": 1, "n": 1, "d": 1}, {"r": 2, "n": 2, "d": 1}, {"r": 2, "n": 2, "d": 2}], lambda t: "[[all enemies within %d]] of [[target tile]] gain [[Slowed %d]] for [[turns %d]]." % (t["r"], t["n"], t["d"]), [2, 3, 4])
menu("aether", "E8", "Surge", [{"n": 2}, {"n": 3}, {"n": 3, "all": 1}], lambda t: ("[[all allies]] [[Troop]] gain" if t.get("all") else "[[target ally]] [[Troop]] gains") + " [[NRG +%d]] for [[turns 1]]." % (1 if t.get("all") else t["n"]), [2, 3, 4])
# Equipment: one stat bump; at Rare and rarer, one trigger may be added
menu("equipment", "Q1", "Hardplate", [{"n": 6}, {"n": 10}, {"n": 15}], lambda t: "[[attached Unit]] gains [[HP +%d]]." % t["n"], [2, 3, 4])
menu("equipment", "Q2", "Armour", [{"n": 1}, {"n": 2}, {"n": 3}], lambda t: "[[attached Unit]] gains [[AC +%d]]." % t["n"], [2, 3, 4])
menu("equipment", "Q3", "Weapon Mod", [{"n": 1}, {"n": 2}, {"n": 3}], lambda t: "[[attached Unit]] gains [[DMG +%d]]." % t["n"], [2, 3, 4])
menu("equipment", "Q4", "Servos", [{"n": 1}, {"n": 1}, {"n": 2}], lambda t: "[[attached Unit]] gains [[MS +%d]]." % t["n"], [2, 2, 3])
menu("equipment", "Q5", "Optics", [{"n": 1}, {"n": 1}, {"n": 2}], lambda t: "[[attached Unit]] gains [[Range +%d]]." % t["n"], [2, 2, 3])
menu("equipment", "Q6", "Targeting", [{"n": 1}, {"n": 2}, {"n": 3}], lambda t: "[[attached Unit]] gains [[Aim +%d]]." % t["n"], [2, 3, 4])
menu("equipment", "Q7", "Jump Gear", [{"n": 2}, {"n": 3}, {"n": 4}], lambda t: "[[attached Unit]] gains [[Leap %d]]." % t["n"], [1, 2, 3])
menu("equipment", "Q8", "Cloak", [{"n": 1}, {"n": 2}, {"n": 3}], lambda t: "[[attached Unit]] gains [[Evasive %d]]." % t["n"], [2, 3, 4])
EQUIP_TRIGGERS = [
    ("QT1", "Reactive", "[[when]] [[attached Unit]] [[is attacked]], [[target enemy]] gains [[Weakened 1]] for [[turns 1]]."),
    ("QT2", "Spool", "[[when]] [[the round begins]], [[attached Unit]] gains [[DMG +1]] for [[turns 1]]."),
    ("QT3", "Dead Man's Switch", "[[when]] [[attached Unit]] [[is Incapacitated]], [[all enemies within 1]] take [[damage 5]]."),
    ("QT4", "Launch", "[[when]] [[attached Unit]] [[is deployed]], [[attached Unit]] gains [[Dash 3]]."),
    ("QT5", "Ledger", "[[when]] [[attached Unit]] [[kills an enemy]], [[gain Aether 1]]."),
]
# Chips: a small one-turn nudge, played from the Pouch (their Aether is unchanged)
for i, (nm, kw, ns, who) in enumerate([("Ballast", "AC +%d", [1, 1, 2], "ally"), ("Barbed", "DMG +%d", [1, 1, 2], "ally"), ("Surge", "NRG +%d", [1, 1, 2], "ally"),
                                       ("Quiet", "Evasive %d", [2, 3, 4], "ally"), ("Spring", "Dash %d", [1, 2, 3], "ally"), ("Gyro", "Leap %d", [2, 3, 4], "ally"),
                                       ("Mending", "heal %d", [3, 4, 5], "ally"), ("Sparking", "damage %d", [1, 2, 3], "enemy")]):
    menu("sphere", "K%d" % (i + 1), nm + " Chip", [{"n": x} for x in ns],
         (lambda kw, who: lambda t: ("[[target ally]] gains [[" + kw % t["n"] + "]]" + ("" if kw.startswith(("heal", "Dash")) else " for [[turns 1]]") + ".") if who == "ally" else "[[target enemy]] takes [[" + kw % t["n"] + "]].")(kw, who))
menu("sphere", "K9", "Ledger Chip", [{"n": 1}], lambda t: "[[gain Aether 1]].", None, "Rare and rarer")
menu("sphere", "K10", "Dampening Chip", [{"n": 1}], lambda t: "[[target ally]] gains [[Hardened 1]] for [[turns 1]].", None, "Epic")
# Consumables: one use, packed for a deployment
menu("consumable", "N1", "Dressing", [{"n": 6}, {"n": 8}, {"n": 10}], lambda t: "[[target ally]] gains [[heal %d]]." % t["n"])
menu("consumable", "N2", "Cleanse Kit", [{"n": 2}, {"n": 4}, {"n": 6}], lambda t: "[[target ally]] gains [[remove Poisoned]]. [[target ally]] gains [[remove Slowed]]. [[target ally]] gains [[heal %d]]." % t["n"])
menu("consumable", "N3", "Grapple", [{"n": 3}, {"n": 4}, {"n": 5}], lambda t: "[[target ally]] gains [[Dash %d]]." % t["n"])
menu("consumable", "N4", "Grav-Boots", [{"n": 3}, {"n": 4}, {"n": 5}], lambda t: "[[target ally]] gains [[Leap %d]] for [[turns 1]]." % t["n"])
menu("consumable", "N5", "Smoke", [{"n": 2}, {"n": 3}, {"n": 4}], lambda t: "[[target ally]] gains [[Evasive %d]] for [[turns 1]]." % t["n"])
menu("consumable", "N6", "Charge", [{"n": 4}, {"n": 6}, {"n": 8}], lambda t: "[[target enemy]] takes [[damage %d]]." % t["n"])
menu("consumable", "N7", "Med Supplies", [{"n": 1}], lambda t: "[[Recover]] a Troop's card from the Discard Pile.")
menu("consumable", "N8", "Ration", [{"n": 4}, {"n": 6}, {"n": 8}], lambda t: "[[target ally]] gains [[HP +%d]] [[persistent]]." % t["n"])
menu("consumable", "N9", "Flare", [{"n": 1}, {"n": 1}, {"n": 2}], lambda t: "[[all allies]] gain [[Aim +%d]] for [[turns 1]]." % t["n"])
menu("consumable", "N10", "Adrenal", [{"n": 2}, {"n": 2}, {"n": 3}], lambda t: "[[target ally]] gains [[NRG +%d]] for [[turns 1]]." % t["n"])
# Prototypes: one standing rule for the whole fight
menu("prototype", "R1", "Targeting Mesh", [{"n": 1}, {"n": 1}, {"n": 2}], lambda t: "[[all allies]] gain [[Aim +%d]]." % t["n"])
menu("prototype", "R2", "Reinforced Frames", [{"n": 2}, {"n": 4}, {"n": 6}], lambda t: "[[all allies]] [[Troop]] gain [[HP +%d]]." % t["n"])
menu("prototype", "R3", "Field Triage", [{"n": 1}, {"n": 1}, {"n": 2}], lambda t: "[[when]] [[the round begins]], [[all allies]] gain [[heal %d]]." % t["n"])
menu("prototype", "R4", "Harmonic Damper", [{"n": 1}], lambda t: "[[all allies]] gain [[Hardened 1]].", None, "Epic")
menu("prototype", "R5", "Ledger Core", [{"n": 1}], lambda t: "[[when]] [[the round begins]], [[gain Aether 1]].", None, "Rare and rarer")
menu("prototype", "R6", "Scavenger Protocol", [{"n": 1}], lambda t: "[[when]] [[an ally]] [[Troop]] [[is Incapacitated]], [[Draw 1]].")
menu("prototype", "R7", "Kinetic Recycler", [{"n": 1}, {"n": 2}, {"n": 2}], lambda t: "[[when]] [[an ally]] [[kills an enemy]], [[that Unit]] gains [[Dash %d]]." % t["n"])
menu("prototype", "R8", "Gantry Mapper", [{"n": 2}, {"n": 3}, {"n": 3}], lambda t: "[[all allies]] gain [[Leap %d]]." % t["n"])

# ---------------------------------------------------------------- K · the core keywords
CORE = {
    "Statuses": ["Rooted", "Stunned", "Slowed", "Marked", "Poisoned", "Weakened", "Evasive", "Hardened"],
    "Modifiers": ["AoE", "Burst", "Lunge", "Pierce", "Aura"],
    "Effects": ["damage", "heal", "Push", "Dash", "Leap", "Deploy", "Draw", "gain Aether", "Recover", "Barricade", "remove", "Sacrifice"],
    "Triggers": ["is deployed", "the round begins", "is attacked", "kills an enemy", "is Incapacitated", "is below half HP"],
    "Stats": ["HP", "AC", "MS", "DMG", "Range", "NRG", "Aim"],
}
FIXED_WORDS = "when, if, while · turns, persistent · target enemy, target ally, this Unit, attached Unit, the target, that Unit, an ally, adjacent, all allies, all enemies, all allies/enemies/units within, target tile · Troop, Hero"
FOLDS = [
    ("Bleed", "Poisoned", "Venom"), ("Pinned", "Marked", "Mark"), ("Sundered", "AC − for a duration", "an Enemy's AC from the table"),
    ("Drained", "NRG − for a duration", "costs stated as Energy"), ("Line, Cone, Chain", "AoE", "Volley, Blast"), ("Charge", "Lunge's tiers add damage", "Pounce"),
    ("Execute", "a Finisher's bonus damage", "Finisher"), ("Flying", "Leap and Evasive", "Agile, Elusive"), ("INT (Integrity)", "follows AC", "the stat tables"),
    ("AP as a buff", "set by the tables and rarity", "the stat tables"), ("Suppressive Fire, Overclock", "dropped", "Overclock never had rules in a fight"),
    ("Conditions: takes damage, deals damage, attacks, moves, ends its move within, gains, is at full HP, has, is within, is further than", "the six triggers", "the library's passives"),
]


# ---------------------------------------------------------------- compile: a build to an ordinary card
def _num(v):
    return None if v is None else int(v)


def unit_line(card_type, role, size, rarity=None, skull=None, grade="enemy", trade=None):
    """The stat line of a unit build, from the tables."""
    if card_type == "hero":
        b, r = HERO[role], HERO_RARITY[rarity]
        s = {"hp": b["hp"] + r["hp"], "ac": b["ac"] + r["ac"], "ms": b["ms"], "nrg": b["nrg"], "dmg": b["dmg"], "rng": b["rng"], "hit": b["hit"],
             "ap": b["ap"] + r["ap"], "ldr": b["ldr"] + r["ldr"], "slots": b["slots"] + r["slots"]}
    elif card_type == "troop":
        b, z, r = TROOP[role], SIZE[size], RARITY[rarity]
        s = {"hp": int(round(b["hp"] * z["hp"])) + r["hp"], "ac": b["ac"] + z["ac"] + r["ac"], "ms": max(0, b["ms"] + z["ms"]), "nrg": max(1, b["nrg"] + z["nrg"]),
             "dmg": max(1, b["dmg"] + z["dmg"]), "rng": b["rng"], "hit": b["hit"], "ap": b["ap"] + z["ap"] + r["ap"], "uslot": z["slots"]}
    else:
        b, z, g, i = ENEMY[role], ENEMY_SIZE[size], GRADE[grade], skull - 1
        s = {"hp": int(round(b["hp"][i] * z["hp"] * g["hp"])), "ac": b["ac"][i] + z["ac"] + g["ac"], "ms": max(1, b["ms"][i] + z["ms"]),
             "dmg": max(1, b["dmg"][i] + z["dmg"] + g["dmg"]), "rng": b["rng"][i], "hit": b["hit"][i], "ap": b["ap"][i] + g["ap"]}
    if trade:
        give, gn, take, tn = trade
        s[give] -= gn
        s[take] += tn
    return s


def ability_entry(card_type, role, line, aid, tier, token=None):
    a = BY_ID[aid]
    t = a["tiers"][min(tier, len(a["tiers"])) - 1]
    text = a["text"](t).replace("{token}", token or "Scuttlebot")
    kind_word = "Combo" if card_type in ("enemy", "elite", "miniboss") else "Active"
    e = {"name": a["name"] + ("" if len(a["tiers"]) == 1 else " " + "I" * tier if tier < 4 else ""), "lab": [aid, tier], "text": text}
    if a["kind"] == "attack":
        d = a["line"](t)
        atk = ROLE_ATTACK[role]
        e.update({"kind": kind_word, "role": atk, "damage": str(max(1, line["dmg"] + d.get("dmg", 0))), "armorPenetration": str(line["ap"]), "energyCost": str(t["e"])})
        if atk == "ranged":
            e.update({"attackRange": str(line["rng"] + d.get("rng", 0)), "toHit": str(max(2, line["hit"] + d.get("hit", 0)))})
    elif a["kind"] == "support":
        e.update({"kind": kind_word, "role": "support", "energyCost": str(t["e"])})
    elif a["kind"] == "aura":
        e.update({"kind": "Aura"})
    else:
        e.update({"kind": "Passive"})
    if card_type in ("enemy", "elite", "miniboss"):
        e.pop("energyCost", None)
    return e, t.get("p", 0)


def compile_unit(b):
    """b: {type, name, role, size, rarity | skull, grade, trade, abilities: [[id, tier]], token}. Returns (card, price, problems)."""
    ct = b["type"]
    line = unit_line(ct, b["role"], b.get("size", "standard"), b.get("rarity"), b.get("skull"), b.get("grade", "enemy" if ct == "enemy" else ct), b.get("trade"))
    atk = ROLE_ATTACK[b["role"]]
    basic = {"name": "Strike" if atk == "melee" else "Shot", "kind": "Combo" if ct in ("enemy", "elite", "miniboss") else "Active", "role": atk,
             "damage": str(line["dmg"]), "armorPenetration": str(line["ap"]), "text": ""}
    if atk == "ranged":
        basic.update({"attackRange": str(line["rng"]), "toHit": str(line["hit"])})
    if ct not in ("enemy", "elite", "miniboss"):
        basic["energyCost"] = "1"
    entries = [basic]
    price = 0
    for aid, tier in b.get("abilities", []):
        e, p = ability_entry(ct, b["role"], line, aid, tier, b.get("token"))
        entries.append(e)
        price += p
    stats = {"hp": str(line["hp"]), "ac": str(line["ac"]), "move": str(line["ms"]), "int": str(line["ac"])}
    if ct == "troop":
        stats.update({"nrg": str(line["nrg"]), "uslot": str(line["uslot"])})
        price += SIZE[b.get("size", "standard")]["price"] + RARITY[b["rarity"]]["price"]
    elif ct == "hero":
        stats.update({"apT": str(line["nrg"]), "ldr": str(line["ldr"]), "slots": str(line["slots"])})
        price += 30 + RARITY[b["rarity"]]["price"]
    else:
        price += 10 + 8 * b["skull"]
    card = {"cardType": ct, "name": b["name"], "rarity": b.get("rarity"), "skullLevel": b.get("skull"), "combatRoles": [atk if b["role"] != "support" else "support"],
            "stats": stats, "entries": entries, "lab": {"role": b["role"], "size": b.get("size", "standard"), "trade": b.get("trade"), "abilities": b.get("abilities", [])}}
    problems = check(b)
    return card, price, problems


def check(b):
    """What a build breaks of the rules: tiers over its rarity or Skull Level, too many abilities, two passives."""
    out = []
    ct = b["type"]
    abil = b.get("abilities", [])
    if ct in ("hero", "troop"):
        r = RARITY[b["rarity"]]
        cap_n, cap_t = r["abilities"], r["tier"]
    else:
        i = b["skull"] - 1
        g = GRADE[b.get("grade", "enemy")]
        cap_n, cap_t = ENEMY_ABILITIES[i] + g["abilities"], min(3, ENEMY_TIER[i] + g["tier"])
    if len(abil) > cap_n:
        out.append("%d abilities, %d allowed" % (len(abil), cap_n))
    for aid, tier in abil:
        a = BY_ID[aid]
        if tier > cap_t:
            out.append("%s %s over the tier cap (%s)" % (a["name"], "I" * tier, "I" * cap_t))
        if b["role"] not in a["roles"]:
            out.append("%s isn't open to a %s" % (a["name"], ROLE_NAME[b["role"]]))
    passive = [aid for aid, _ in abil if BY_ID[aid]["kind"] in ("passive", "aura")]
    if len(passive) > (2 if b.get("grade") == "miniboss" else 1):
        out.append("more than one Passive or Aura")
    return out


def suggested_aether(price):
    return max(0, int(round(price / 8.0)))


def plain(text):
    return text.replace("[[", "").replace("]]", "")
