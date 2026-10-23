## The Card Forge's model of a card (0.26), as the Companion's Forge has it
## (forge_v3.html: TYPES, DISTRICTS, ARCHETYPES, ROLES, RARITY): each kind of
## card, the numbers it carries and their ranges, the kinds of ability it may
## have, and whether it costs Aether, has a rarity, a Skull Level or Combat
## Roles. The game's Forge (forge_screen.gd) builds its form from this, and a
## card it saves is in the Companion's own shape (keter.compendium/1).
class_name ForgeModel
extends RefCounted

## (the symbols are data the Companion keeps with an affinity, never drawn by the game: Meridian's and
## Neutral's, which no font of the game's has, are made from their code points in district_sym)
const DISTRICTS := [
	{"id": "", "sym": "", "name": "None"},
	{"id": "1", "sym": "£", "name": "1 · Threshold Dynamics"},
	{"id": "2", "sym": "¢", "name": "2 · Halcyon Cognition"},
	{"id": "3", "sym": "€", "name": "3 · Vantage Robotics"},
	{"id": "4", "sym": "¥", "name": "4 · Lazarus Computing"},
	{"id": "5", "sym": "§", "name": "5 · Verdant Biogenics"},
	{"id": "6", "sym": 0x2206, "name": "6 · Meridian Entropics"},
	{"id": "any", "sym": "°", "name": "Any affinity"},
	{"id": "neu", "sym": 0x2713, "name": "Neutral"}]
const ARCHETYPES := ["Juggernaut", "Spawner", "Assassin", "Sniper", "Commando", "Kamikaze", "Shield-Bearer",
	"Healer", "Fighter", "Transport", "Gunfighter", "Door Kicker", "Veteran Tactician", "Disabler", "Berserker",
	"Devourer", "Tinkerer", "Light Infantry", "Heavy Infantry", "Drone", "O.B.O.L.™ Bot", "Battle Buddy™ Bot",
	"Swarm", "General", "Necromancer", "Abomination", "Chaff", "Mechanical"]
const ROLES := ["melee", "ranged", "support", "cyber"]
const EROLES := ["", "melee", "ranged", "support", "cyber", "aether"]
const PROJECTILES := ["bolt", "shell", "beam", "spray"]
const ORIGINS := ["", "Human", "Cyborg", "Mechanical", "Mutant", "Aetheric"]
const RARITIES := ["", "common", "uncommon", "rare", "epic", "legendary", "mythic"]
const TYPE_ORDER := ["hero", "troop", "enemy", "elite", "miniboss", "boss", "action", "aether", "equipment", "command", "consumable", "prototype", "sphere"]
const UNIT_TYPES := ["hero", "troop", "enemy", "elite", "miniboss", "boss"]
const FOE_TYPES := ["enemy", "elite", "miniboss", "boss"]

## Each kind: label, the tags its abilities may have, how many (cap), whether
## they cost Energy, whether the card costs Aether, has archetypes, and its numbers.
const TYPES := {
	"hero": {"label": "Hero", "tags": ["Active", "Passive", "Aura"], "energy": true, "stats": [
		["hp", "Health", 15, 60, "30"], ["ac", "Armor Class", 5, 16, "9"], ["slots", "Action Slots", 1, 10, "3"], ["apT", "Energy a turn", 0, 6, "3"],
		["move", "Movement", 1, 6, "3"], ["ldr", "Leadership", 1, 30, "6"], ["int", "Integrity", 1, 20, "12"]]},
	"troop": {"label": "Troop", "tags": ["Active", "Passive", "Aura"], "energy": true, "aether": true, "token": true, "stats": [
		["hp", "Health", 15, 60, "22"], ["nrg", "Energy", 3, 6, "3"], ["ac", "Armor Class", 5, 16, "8"], ["int", "Integrity", 1, 20, "8"],
		["move", "Movement", 1, 6, "4"], ["uslot", "Unit Slots", 1, 5, "1"]]},
	"enemy": {"label": "Enemy", "tags": ["Combo", "Special", "Passive", "Aura"], "skulls": true, "stats": [
		["hp", "Health", 10, 50, "18"], ["ac", "Armor Class", 3, 18, "7"], ["move", "Movement", 0, 6, "4"], ["int", "Integrity", 1, 20, "7"]]},
	"elite": {"label": "Elite", "tags": ["Combo", "Special", "Passive", "Aura"], "skulls": true, "stats": [
		["hp", "Health", 30, 70, "36"], ["ac", "Armor Class", 6, 18, "10"], ["move", "Movement", 1, 6, "4"], ["int", "Integrity", 1, 20, "10"]]},
	"miniboss": {"label": "Mini-Boss", "tags": ["Combo", "Special", "Passive", "Aura"], "skulls": true, "stats": [
		["hp", "Health", 10, 90, "45"], ["ac", "Armor Class", 3, 18, "11"], ["move", "Movement", 0, 6, "4"], ["int", "Integrity", 1, 20, "11"]]},
	"boss": {"label": "Boss", "tags": ["Combo", "Special", "Passive", "Aura"], "skulls": true, "stats": [
		["hp", "Health", 10, 200, "90"], ["ac", "Armor Class", 3, 18, "14"], ["move", "Movement", 0, 6, "4"], ["int", "Integrity", 1, 20, "14"]]},
	"action": {"label": "Action", "tags": ["Active", "Passive", "Aura"], "cap": 2, "energy": true, "aether": true, "no_arch": true, "stats": []},
	"aether": {"label": "Aether", "tags": ["Active"], "cap": 1, "aether": true, "no_arch": true, "no_name": true, "stats": []},
	"equipment": {"label": "Equipment", "tags": ["Active", "Passive", "Aura"], "cap": 4, "energy": true, "aether": true, "no_arch": true, "mods": true, "stats": [
		["hp", "Health", -20, 20, ""], ["ac", "Armor Class", -8, 8, ""], ["nrg", "Energy", -3, 3, ""], ["ms", "Movement", -4, 4, ""],
		["int", "Integrity", -4, 4, ""], ["ldr", "Leadership", -4, 4, ""]]},
	"command": {"label": "Command", "tags": ["Active"], "cap": 1, "aether": true, "no_arch": true, "no_name": true, "stats": []},
	"consumable": {"label": "Consumable", "tags": ["Active"], "cap": 1, "no_arch": true, "no_name": true, "stats": []},
	"prototype": {"label": "Prototype", "tags": ["Passive", "Active", "Aura"], "cap": 2, "no_arch": true, "stats": []},
	"sphere": {"label": "Aether Chip", "tags": ["Passive", "Active", "Aura"], "cap": 2, "no_arch": true, "chip": true, "stats": []}}


static func type_def(t: String) -> Dictionary:
	return TYPES.get(t, TYPES["hero"])


static func label(t: String) -> String:
	return str(type_def(t)["label"])


static func is_unit(t: String) -> bool:
	return UNIT_TYPES.has(t)


static func is_foe(t: String) -> bool:
	return FOE_TYPES.has(t)


## Foes carry no rarity: they are not loot.
static func has_rarity(t: String) -> bool:
	return not is_foe(t)


static func district_name(id: String) -> String:
	for d in DISTRICTS:
		if d["id"] == id:
			return d["name"]
	return id


static func district_sym(id: String) -> String:
	for d in DISTRICTS:
		if d["id"] == id:
			return String.chr(d["sym"]) if d["sym"] is int else str(d["sym"])
	return ""


## A new card of a kind, as the Companion's Forge starts one.
static func blank(t: String, name := "New card") -> Dictionary:
	var d := type_def(t)
	var stats := {}
	for s in d["stats"]:
		stats[s[0]] = s[4]
	if stats.has("ac") and stats.has("int") and is_unit(t):
		stats["int"] = stats["ac"]
	var c := {"cardType": t, "name": name, "createdBy": "Sandbox", "lastEditedBy": "Sandbox", "affinities": [], "archetypes": [],
		"level": 1, "stats": stats, "entries": [], "lore": null, "loreEnabled": false}
	if has_rarity(t):
		c["rarity"] = "common"
	if is_foe(t):
		c["skullLevel"] = 1
		c["salvage"] = "mixed"
	if is_unit(t):
		c["combatRoles"] = ["melee"]
		c["origin"] = null
	if d.get("aether", false):
		c["aetherCost"] = {"generic": 1, "affinity": 0, "affinity2": 0}
	if d.get("token", false):
		c["token"] = false
	if d.get("chip", false):
		c["aetherValue"] = "1"
	c["entries"].append(blank_entry(t))
	return c


## A new ability for a kind of card: its first tag, a name, and the numbers its role wants.
static func blank_entry(t: String, tag := "") -> Dictionary:
	var d := type_def(t)
	var k: String = tag if tag != "" else str(d["tags"][0])
	var e := {"name": "" if d.get("no_name", false) else "New ability", "kind": k, "text": ""}
	if d.get("energy", false) and k == "Active":
		e["energyCost"] = "1"
	if is_unit(t) and (k == "Active" or k == "Combo"):
		e["role"] = "melee"
		e["damage"] = "4"
	if k == "Aura":
		e["auraRadius"] = "1"
		e["role"] = "support"
	return e


## The numbers an ability's role and tag carry: [key, label, low, high].
static func entry_numbers(t: String, e: Dictionary) -> Array:
	var out := []
	var k := str(e.get("kind", ""))
	var role := str(e.get("role", "") if e.get("role") != null else "")
	if type_def(t).get("energy", false) and k == "Active":
		out.append(["energyCost", "Energy", 0, 6])
	if k == "Aura":
		out.append(["auraRadius", "Aura radius", 1, 6])
		return out
	if k == "Passive":
		return out
	if role in ["melee", "ranged", "cyber", "aether"] or str(e.get("damage", "") if e.get("damage") != null else "") != "":
		out.append(["damage", "Damage", 0, 40])
	if role == "ranged" or role == "cyber":
		out.append(["attackRange", "Range", 1, 10])
		out.append(["toHit", "To-hit", 2, 20])
	if role in ["melee", "ranged"]:
		out.append(["armorPenetration", "Armor pierce", 0, 10])
	return out


## The kind of ability (for the keyword builder): an action, a passive, an aura.
static func builder_tag(e: Dictionary) -> String:
	var k := str(e.get("kind", "Active"))
	return "Active" if k == "Combo" or k == "Special" else k


## What would stop a card being kept: [] when nothing does.
static func problems(c: Dictionary, others: Array = [], key := "") -> Array:
	var out := []
	var nm := str(c.get("name", "")).strip_edges()
	if nm == "":
		out.append("It needs a name.")
	for o in others:
		if o is Dictionary and str(o.get("name", "")) == nm and Sandbox.key_of(o) != key and str(o.get("cardType", "")) == str(c.get("cardType", "")):
			out.append("Another %s is called %s." % [label(str(c.get("cardType", ""))).to_lower(), nm])
			break
	var t := str(c.get("cardType", ""))
	if is_unit(t) and (c.get("combatRoles", []) as Array).is_empty():
		out.append("A Unit needs at least one Combat Role.")
	var cap := int(type_def(t).get("cap", 99))
	if (c.get("entries", []) as Array).size() > cap:
		out.append("A %s holds at most %d abilit%s." % [label(t), cap, "y" if cap == 1 else "ies"])
	return out


## What the keyword checks say of its abilities' text: kept anyway, as the Companion keeps it.
static func warnings(c: Dictionary) -> Array:
	var out := []
	for e in c.get("entries", []):
		for sent in Keywords.sentences(str(e.get("text", ""))):
			for p in Keywords.problems(Keywords.analyse(sent), {"kind": Keywords.kind_of(builder_tag(e))}):
				out.append("%s: %s." % [str(e.get("name", "")) if str(e.get("name", "")) != "" else "Its ability", str(p)])
	return out
