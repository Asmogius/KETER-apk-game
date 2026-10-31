## KETER Lab: the simpler card systems (chosen 31 Oct 2026). (lab.js)
##
## A Lab card is built, not written. A unit is a role, a size and a rarity (an
## Enemy a role, a size, a Skull Level and a grade) and up to two abilities
## from the library at a tier; every other card is one item from its type's
## menu at a tier. compile() turns a build into an ordinary card (its stats,
## its entries and their keyword text), so the rules play it as they play any
## card. check() says what a build breaks; points() and target() hold it
## against its rarity.
##
## The tables and the library are res://data/lab_systems.json, made by
## lab/make_lab_systems.py from lab/spec_data.py; the Companion reads the same
## (lab_data.js) and compiles the same way. tests/lab_diff.gd holds the two to
## the same answers.
class_name LabSystems
extends RefCounted

const PATH := "res://data/lab_systems.json"
const ROMAN := ["", "I", "II", "III"]
const ENEMYISH := ["enemy", "elite", "miniboss"]
const UNIT := ["hero", "troop", "enemy", "elite", "miniboss"]
const MENU_TYPES := ["command", "aether", "equipment", "sphere", "consumable", "prototype"]

static var _d = null


static func data() -> Dictionary:
	if _d == null:
		_d = {}
		if FileAccess.file_exists(PATH):
			var x = JSON.parse_string(FileAccess.get_file_as_string(PATH))
			if x is Dictionary:
				_d = Rules.ints(x)
	return _d


static func version() -> String:
	return str(data().get("version", ""))


static func half_up(x) -> int:
	return int(floor(float(x) + 0.5))


static func ability(id) -> Variant:
	for a in data().get("library", []):
		if a["id"] == str(id):
			return a
	return null


static func menu_item(type: String, id) -> Variant:
	for m in data().get("menus", {}).get(type, []):
		if m["id"] == str(id):
			return m
	return null


static func trigger(id) -> Variant:
	for t in data().get("equipTriggers", []):
		if t["id"] == str(id):
			return t
	return null


static func grade_of(b: Dictionary) -> String:
	if b.get("grade") != null and str(b["grade"]) != "":
		return str(b["grade"])
	return str(b["type"]) if b.get("type") in ["elite", "miniboss"] else "enemy"


static func rarity_rank(r) -> int:
	var i: int = data().get("rarities", []).find(str(r if r != null and str(r) != "" else "common"))
	return maxi(i, 0)


static func tier_cap(r) -> int:
	var x = data().get("rarity", {}).get(str(r if r != null and str(r) != "" else "common"))
	return int(x["tier"]) if x is Dictionary else 1


static func _clamp_tier(t, n: int) -> int:
	return mini(maxi(1, int(floor(Rules.num(t, 1)))) if Rules.truthy(t) else 1, n)


static func _rar(b: Dictionary) -> String:
	return str(b["rarity"]) if b.get("rarity") != null and str(b["rarity"]) != "" else "common"


## A unit's stat line, from the tables.
static func line(type: String, role: String, size = null, rarity = null, skull = null, grade = "enemy", trade = null) -> Dictionary:
	var d := data()
	var s := {}
	var sz := str(size) if size != null and str(size) != "" else "standard"
	var rr := str(rarity) if rarity != null and str(rarity) != "" else "common"
	if type == "hero":
		var b: Dictionary = d["hero"][role]
		var r: Dictionary = d["heroRarity"][rr]
		s = {"hp": b["hp"] + r["hp"], "ac": b["ac"] + r["ac"], "ms": b["ms"], "nrg": b["nrg"], "dmg": b["dmg"], "rng": b["rng"], "hit": b["hit"],
			"ap": b["ap"] + r["ap"], "ldr": b["ldr"] + r["ldr"], "slots": b["slots"] + r["slots"]}
	elif type == "troop":
		var b: Dictionary = d["troop"][role]
		var z: Dictionary = d["size"][sz]
		var r: Dictionary = d["rarity"][rr]
		s = {"hp": half_up(b["hp"] * z["hp"]) + r["hp"], "ac": b["ac"] + z["ac"] + r["ac"], "ms": maxi(0, b["ms"] + z["ms"] + r["ms"]), "nrg": maxi(1, b["nrg"] + z["nrg"]),
			"dmg": maxi(1, b["dmg"] + z["dmg"]), "rng": b["rng"], "hit": b["hit"], "ap": b["ap"] + z["ap"] + r["ap"], "uslot": z["slots"]}
	else:
		var i := clampi(int(Rules.num(skull, 1)) if Rules.truthy(skull) else 1, 1, 6) - 1
		var b: Dictionary = d["enemy"][role]
		var z: Dictionary = d["enemySize"][sz]
		var g: Dictionary = d["grade"][str(grade)]
		s = {"hp": half_up(b["hp"][i] * z["hp"] * g["hp"]), "ac": b["ac"][i] + z["ac"] + g["ac"], "ms": maxi(1, b["ms"][i] + z["ms"]),
			"dmg": maxi(1, b["dmg"][i] + z["dmg"] + g["dmg"]), "rng": b["rng"][i], "hit": b["hit"][i], "ap": b["ap"][i] + g["ap"]}
	if trade is Array and trade.size() == 4:
		# (a stat the line hasn't, Energy on an Enemy, is left alone, as lab.js leaves it unshown)
		if s.has(str(trade[0])):
			s[str(trade[0])] -= int(Rules.num(trade[1], 0))
		if s.has(str(trade[2])):
			s[str(trade[2])] += int(Rules.num(trade[3], 0))
	return s


# ---------------------------------------------------------------- what things are worth
static func rarity_price(bonus: Dictionary) -> int:
	var t := 0
	var p: Dictionary = data().get("statPrice", {})
	for k in p:
		if bonus.get(k) != null:
			t += int(p[k]) * int(bonus[k])
	return t


static func target(type: String, rarity, size = null) -> Variant:
	var d := data()
	var rr := str(rarity) if rarity != null and str(rarity) != "" else "common"
	var r = d.get("rarity", {}).get(rr)
	if not (r is Dictionary):
		return null
	var sz := str(size) if size != null and str(size) != "" else "standard"
	var base: int = 30 + rarity_price(d["heroRarity"][rr]) if type == "hero" else int(d["size"][sz]["price"]) + rarity_price(r)
	return base + int(r["abilities"]) * int(d["tierPrice"][str(r["tier"])])


static func suggested_aether(points) -> int:
	return maxi(0, half_up(float(points) / 8.0))


# ---------------------------------------------------------------- one entry
static func _basic_entry(type: String, role: String, ln: Dictionary) -> Dictionary:
	var atk: String = data()["roleAttack"][role]
	var e := {"name": "Strike" if atk == "melee" else "Shot", "kind": "Combo" if ENEMYISH.has(type) else "Active", "role": atk,
		"damage": str(ln["dmg"]), "armorPenetration": str(ln["ap"]), "text": ""}
	if atk == "ranged":
		e["attackRange"] = str(ln["rng"])
		e["toHit"] = str(ln["hit"])
	if not ENEMYISH.has(type):
		e["energyCost"] = "1"
	return e


static func _ability_entry(type: String, role: String, ln: Dictionary, id, tier, token) -> Dictionary:
	var a = ability(id)
	if a == null:
		return {"entry": null, "points": 0}
	var n: int = a["tiers"].size()
	var ti := _clamp_tier(tier, n)
	var t: Dictionary = a["tiers"][ti - 1]
	var e := {"name": str(a["name"]) + ("" if n == 1 else " " + ROMAN[ti]), "lab": [str(a["id"]), ti],
		"text": str(t["text"]).replace("{token}", str(token) if token != null and str(token) != "" else "Scuttlebot")}
	var kw := "Combo" if ENEMYISH.has(type) else "Active"
	if a["kind"] == "attack":
		var atk: String = data()["roleAttack"][role]
		e["kind"] = kw
		e["role"] = atk
		e["damage"] = str(maxi(1, ln["dmg"] + int(t.get("dmg", 0))))
		e["armorPenetration"] = str(ln["ap"])
		e["energyCost"] = str(t["e"])
		if atk == "ranged":
			e["attackRange"] = str(ln["rng"] + int(t.get("rng", 0)))
			e["toHit"] = str(maxi(2, ln["hit"] + int(t.get("hit", 0))))
	elif a["kind"] == "support":
		e["kind"] = kw
		e["role"] = "support"
		e["energyCost"] = str(t["e"])
	else:
		e["kind"] = "Aura" if a["kind"] == "aura" else "Passive"
	if ENEMYISH.has(type):
		e.erase("energyCost")
	return {"entry": e, "points": int(t.get("p", 0))}


## A Legendary or Mythic card's own ability (Q3): written in the core keywords, priced by hand.
static func _signature_entry(type: String, role: String, ln: Dictionary, sig) -> Dictionary:
	var s: Dictionary = sig if sig is Dictionary else {}
	var e := {"name": str(s.get("name", "Signature")) if Rules.truthy(s.get("name")) else "Signature", "lab": ["SIG", 0], "text": str(s.get("text", "")) if s.get("text") != null else "", "signature": true}
	var k := str(s["kind"]) if Rules.truthy(s.get("kind")) else "passive"
	var kw := "Combo" if ENEMYISH.has(type) else "Active"
	if k == "attack":
		var atk: String = str(s["role"]) if Rules.truthy(s.get("role")) else data()["roleAttack"][role]
		e["kind"] = kw
		e["role"] = atk
		e["damage"] = str(ln["dmg"] + int(Rules.num(s.get("dmg"), 0)))
		e["armorPenetration"] = str(ln["ap"])
		e["energyCost"] = str(int(Rules.num(s["e"], 0)) if s.get("e") != null else 2)
		if atk == "ranged":
			e["attackRange"] = str(ln["rng"] + int(Rules.num(s.get("rng"), 0)))
			e["toHit"] = str(maxi(2, ln["hit"] + int(Rules.num(s.get("hit"), 0))))
	elif k == "support":
		e["kind"] = kw
		e["role"] = "support"
		e["energyCost"] = str(int(Rules.num(s["e"], 0)) if s.get("e") != null else 2)
	else:
		e["kind"] = "Aura" if k == "aura" else "Passive"
	if ENEMYISH.has(type):
		e.erase("energyCost")
	return {"entry": e, "points": int(floor(Rules.num(s.get("points"), 0)))}


# ---------------------------------------------------------------- a whole card
## Whether the tables have a line for this build at all; a build that doesn't makes no card, only its problems.
static func _sane(b: Dictionary) -> bool:
	var d := data()
	var size := str(b["size"]) if Rules.truthy(b.get("size")) else "standard"
	var role := str(b.get("role"))
	if not d.get("roleAttack", {}).has(role):
		return false
	if b.get("type") == "hero":
		return d["hero"].has(role) and d["heroRarity"].has(_rar(b))
	if b.get("type") == "troop":
		return d["troop"].has(role) and d["size"].has(size) and d["rarity"].has(_rar(b))
	return d["enemy"].has(role) and d["enemySize"].has(size) and d["grade"].has(grade_of(b))


static func compile_unit(b: Dictionary) -> Dictionary:
	if not _sane(b):
		return {"card": null, "points": null, "target": null, "problems": check(b)}
	var d := data()
	var type := str(b["type"])
	var role := str(b["role"])
	var size := str(b["size"]) if Rules.truthy(b.get("size")) else "standard"
	var ln := line(type, role, size, b.get("rarity"), b.get("skull"), grade_of(b), b.get("trade"))
	var atk: String = d["roleAttack"][role]
	var entries := [_basic_entry(type, role, ln)]
	var pts := 0
	for x in b.get("abilities", []):
		var r := _signature_entry(type, role, ln, x[1]) if str(x[0]) == "SIG" else _ability_entry(type, role, ln, x[0], x[1], b.get("token"))
		if r["entry"] != null:
			entries.append(r["entry"])
			pts += int(r["points"])
	var stats := {"hp": str(ln["hp"]), "ac": str(ln["ac"]), "move": str(ln["ms"]), "int": str(ln["ac"])}
	if type == "troop":
		stats["nrg"] = str(ln["nrg"])
		stats["uslot"] = str(ln["uslot"])
		pts += int(d["size"][size]["price"]) + rarity_price(d["rarity"][_rar(b)])
	elif type == "hero":
		stats["apT"] = str(ln["nrg"])
		stats["ldr"] = str(ln["ldr"])
		stats["slots"] = str(ln["slots"])
		pts += 30 + rarity_price(d["heroRarity"][_rar(b)])
	else:
		pts += 10 + 8 * (int(Rules.num(b.get("skull"), 1)) if Rules.truthy(b.get("skull")) else 1)
	var enemy := ENEMYISH.has(type)
	var card := {"cardType": type, "rarity": null if enemy else _rar(b), "skullLevel": (int(Rules.num(b.get("skull"), 1)) if Rules.truthy(b.get("skull")) else 1) if enemy else null,
		"combatRoles": ["support" if role == "support" else atk], "stats": stats, "entries": entries, "lab": norm(b)}
	return {"card": card, "points": pts, "target": null if enemy else target(type, _rar(b), size), "problems": check(b)}


## An Action card's attack uses a Common Hero's line for its kind of attack (melee: a Brute's; ranged: a Shooter's).
static func _action_role(a: Dictionary) -> String:
	if a["roles"].has("brute"):
		return "brute"
	if a["roles"].has("shooter"):
		return "shooter"
	return str(a["roles"][0])


static func compile_other(b: Dictionary) -> Dictionary:
	var type := str(b["type"])
	var entry = null
	var cost = null
	if type == "action":
		var x: Array = b.get("ability", []) if b.get("ability") is Array else []
		if x.size() > 0 and str(x[0]) == "SIG":
			var sg = x[1] if x.size() > 1 else {}
			var role := "shooter" if (sg is Dictionary and sg.get("role") == "ranged") else "brute"
			entry = _signature_entry("hero", role, line("hero", role, null, "common"), sg)["entry"]
			cost = 3
		elif x.size() > 0:
			var a = ability(x[0])
			if a != null:
				var role := _action_role(a)
				entry = _ability_entry("hero", role, line("hero", role, null, "common"), x[0], x[1] if x.size() > 1 else 1, b.get("token"))["entry"]
				cost = _clamp_tier(x[1] if x.size() > 1 else 1, a["tiers"].size())
	elif MENU_TYPES.has(type):
		var m = menu_item(type, b.get("menu"))
		if m != null:
			var ti := _clamp_tier(b.get("tier"), m["tiers"].size())
			var t: Dictionary = m["tiers"][ti - 1]
			var txt := str(t["text"])
			var tr = trigger(b["trigger"]) if type == "equipment" and Rules.truthy(b.get("trigger")) else null
			if tr != null:
				txt += " " + str(tr["text"])
			entry = {"name": "", "kind": m["kind"], "lab": [str(m["id"]), ti], "text": txt}
			if t.get("cost") != null:
				cost = int(t["cost"]) + (1 if tr != null else 0)
	var card := {"cardType": type, "rarity": _rar(b), "stats": {}, "entries": [entry] if entry != null else [], "lab": norm(b)}
	return {"card": card, "points": null, "target": null, "cost": cost, "problems": check(b)}


static func compile(b: Dictionary) -> Dictionary:
	return compile_unit(b) if UNIT.has(str(b.get("type"))) else compile_other(b)


## The build as it is kept on the card: only what a build is.
static func norm(b: Dictionary) -> Dictionary:
	var o := {"type": b.get("type")}
	for k in ["role", "size", "rarity", "skull", "grade", "trade", "abilities", "token", "ability", "menu", "tier", "trigger"]:
		if b.get(k) != null and not (b[k] is String and b[k] == ""):
			o[k] = b[k].duplicate(true) if (b[k] is Array or b[k] is Dictionary) else b[k]
	return o


# ---------------------------------------------------------------- the rules a build keeps
static func _tv(v) -> int:
	var t := int(Rules.num(v, 0))
	return t if t != 0 else 1


static func _cap_word(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)


static func check(b: Dictionary) -> Array:
	var d := data()
	var out := []
	var type := str(b.get("type"))
	if UNIT.has(type):
		if not d.get("roleAttack", {}).has(str(b.get("role"))):
			return ["no role"]
		var abil: Array = b.get("abilities", []) if b.get("abilities") is Array else []
		var cap_n := 0
		var cap_t := 1
		var enemy := ENEMYISH.has(type)
		if not enemy:
			var r = d["rarity"].get(_rar(b))
			if not (r is Dictionary):
				return ["no such rarity"]
			var sz := str(b["size"]) if Rules.truthy(b.get("size")) else "standard"
			if type == "troop" and not d["size"].has(sz):
				return ["no such size"]
			if type == "troop" and sz == "colossal" and rarity_rank(b.get("rarity")) < rarity_rank("legendary"):
				out.append("Colossal is for Legendary and Mythic Troops")
			cap_n = int(r["abilities"])
			cap_t = int(r["tier"])
		else:
			var i := clampi(int(Rules.num(b.get("skull"), 1)) if Rules.truthy(b.get("skull")) else 1, 1, 6) - 1
			var g = d["grade"].get(grade_of(b))
			if not (g is Dictionary):
				return ["no such grade"]
			if not d["enemySize"].has(str(b["size"]) if Rules.truthy(b.get("size")) else "standard"):
				return ["no such size"]
			cap_n = int(d["enemyAbilities"][i]) + int(g["abilities"])
			cap_t = mini(3, int(d["enemyTier"][i]) + int(g["tier"]))
		if abil.size() > cap_n:
			out.append("%d abilities, %d allowed" % [abil.size(), cap_n])
		var sigs := abil.filter(func(x): return str(x[0]) == "SIG")
		if not sigs.is_empty() and not ((type == "hero" or type == "troop") and Rules.truthy(d["rarity"].get(_rar(b), {}).get("signature"))):
			out.append("a signature ability is for Legendary and Mythic cards")
		if sigs.size() > 1:
			out.append("more than one signature ability")
		var seen := {}
		for x in abil:
			if str(x[0]) == "SIG":
				continue
			var a = ability(x[0])
			if a == null:
				out.append("no ability " + str(x[0]))
				continue
			if seen.has(a["id"]):
				out.append(str(a["name"]) + " twice")
			seen[a["id"]] = true
			if _tv(x[1]) > cap_t:
				out.append("%s %s over the tier cap (%s)" % [a["name"], ROMAN[mini(3, _tv(x[1]))], ROMAN[cap_t]])
			if not a["roles"].has(str(b["role"])):
				out.append("%s isn't open to a %s" % [a["name"], d["roleName"][str(b["role"])]])
			if a.get("min") != null and (true if enemy else rarity_rank(b.get("rarity")) < rarity_rank(a["min"])):
				out.append("%s is for %s and rarer cards" % [a["name"], _cap_word(str(a["min"]))])
		var passive := abil.filter(func(x): return (["passive", "aura"].has(str(x[1].get("kind", "passive")) if x[1] is Dictionary and Rules.truthy(x[1].get("kind")) else "passive")) if str(x[0]) == "SIG" else (ability(x[0]) != null and ["passive", "aura"].has(ability(x[0])["kind"])))
		if passive.size() > (2 if grade_of(b) == "miniboss" and enemy else 1):
			out.append("more than one Passive or Aura")
		var tr = b.get("trade")
		if tr != null:
			var ok := false
			for t in d.get("trades", []):
				if tr is Array and tr.size() == 4 and ((str(t[0]) == str(tr[0]) and int(t[1]) == int(Rules.num(tr[1], 0)) and str(t[2]) == str(tr[2]) and int(t[3]) == int(Rules.num(tr[3], 0)))
						or (str(t[2]) == str(tr[0]) and int(t[3]) == int(Rules.num(tr[1], 0)) and str(t[0]) == str(tr[2]) and int(t[1]) == int(Rules.num(tr[3], 0)))):
					ok = true
			if not ok:
				out.append("not one of the trades")
		if Rules.truthy(b.get("token")) and not d.get("tokens", []).has(str(b["token"])):
			out.append("no token " + str(b["token"]))
		return out
	if type == "action":
		var x: Array = b.get("ability", []) if b.get("ability") is Array else []
		if x.size() > 0 and str(x[0]) == "SIG":
			if not Rules.truthy(d["rarity"].get(_rar(b), {}).get("signature")):
				out.append("a signature ability is for Legendary and Mythic cards")
			return out
		var a = ability(x[0]) if x.size() > 0 else null
		if a == null:
			return ["no ability " + (str(x[0]) if x.size() > 0 else "undefined")]
		var tv := _tv(x[1] if x.size() > 1 else null)
		if tv > tier_cap(b.get("rarity")):
			out.append("%s %s over the tier cap (%s)" % [a["name"], ROMAN[mini(3, tv)], ROMAN[tier_cap(b.get("rarity"))]])
		if a.get("min") != null and rarity_rank(b.get("rarity")) < rarity_rank(a["min"]):
			out.append("%s is for %s and rarer cards" % [a["name"], _cap_word(str(a["min"]))])
		return out
	if MENU_TYPES.has(type):
		var m = menu_item(type, b.get("menu"))
		if m == null:
			return ["no %s %s" % [type, str(b.get("menu")) if b.get("menu") != null else "undefined"]]
		var cap := mini(tier_cap(b.get("rarity")), m["tiers"].size())
		if _tv(b.get("tier")) > cap:
			out.append("%s %s over the tier cap (%s)" % [m["name"], ROMAN[mini(3, _tv(b.get("tier")))], ROMAN[cap]])
		if m.get("min") != null and rarity_rank(b.get("rarity")) < rarity_rank(m["min"]):
			out.append("%s is for %s and rarer cards" % [m["name"], _cap_word(str(m["min"]))])
		if Rules.truthy(b.get("trigger")):
			if type != "equipment":
				out.append("only Equipment takes a trigger")
			elif trigger(b["trigger"]) == null:
				out.append("no trigger " + str(b["trigger"]))
			elif rarity_rank(b.get("rarity")) < rarity_rank("rare"):
				out.append("a trigger is for Rare and rarer Equipment")
		return out
	return ["no Lab build for a " + type]


static func points(b: Dictionary) -> Variant:
	return compile(b)["points"]


# ---------------------------------------------------------------- the Forge's help (lab.js's defaultBuild, caps, guess)
## A new card's build, keeping what it can of the one before.
static func default_build(type: String, prev = null) -> Variant:
	var d := data()
	var p: Dictionary = prev if prev is Dictionary else {}
	var rarity: String = str(p.get("rarity")) if d["rarities"].has(str(p.get("rarity", ""))) else "common"
	if UNIT.has(type):
		var b := {"type": type, "role": str(p.get("role")) if d["roles"].has(str(p.get("role", ""))) else "brute", "abilities": []}
		if ENEMYISH.has(type):
			b["size"] = str(p.get("size")) if d["enemySize"].has(str(p.get("size", ""))) else "standard"
			b["skull"] = clampi(int(floor(Rules.num(p.get("skull"), 1))) if Rules.truthy(p.get("skull")) else 1, 1, 6)
		else:
			b["rarity"] = rarity
			if type == "troop":
				b["size"] = str(p.get("size")) if (d["size"].has(str(p.get("size", ""))) and str(p.get("size")) != "colossal") else "standard"
		return b
	if type == "action":
		return {"type": type, "rarity": rarity, "ability": ["A1", 1]}
	if MENU_TYPES.has(type):
		var l: Array = d["menus"].get(type, [])
		return {"type": type, "rarity": rarity, "menu": str(l[0]["id"]) if l.size() > 0 else "", "tier": 1}
	return null


## What a build may hold: how many abilities, the highest tier, whether a signature, how many Passives or Auras.
static func caps(b: Dictionary) -> Dictionary:
	var d := data()
	var type := str(b.get("type", ""))
	if type == "hero" or type == "troop":
		var r: Dictionary = d["rarity"].get(_rar(b), d["rarity"]["common"])
		return {"abilities": int(r["abilities"]), "tier": int(r["tier"]), "signature": Rules.truthy(r.get("signature")), "passives": 1}
	if ENEMYISH.has(type):
		var i := clampi(int(Rules.num(b.get("skull"), 1)) if Rules.truthy(b.get("skull")) else 1, 1, 6) - 1
		var g: Dictionary = d["grade"].get(grade_of(b), d["grade"]["enemy"])
		return {"abilities": int(d["enemyAbilities"][i]) + int(g["abilities"]), "tier": mini(3, int(d["enemyTier"][i]) + int(g["tier"])), "signature": false, "passives": 2 if grade_of(b) == "miniboss" else 1}
	return {"abilities": 1, "tier": tier_cap(b.get("rarity")), "signature": Rules.truthy(d["rarity"].get(_rar(b), {}).get("signature")), "passives": 1}


const STOP := ["target", "all ", "turns", "this Unit", "attached Unit", "that Unit", "an ally", "an enemy", "when", "if", "while", "the round begins", "adjacent", "persistent", "within", "the target", "is ", "has ", "kills", "takes", "deals", "moves", "Troop", "Hero"]


static func _is_number_word(w: String) -> bool:
	var s := w
	if s.begins_with("+") or s.begins_with("-") or s.begins_with("−"):
		s = s.substr(1)
	if s == "":
		return false
	for ch in s:
		if not (ch >= "0" and ch <= "9"):
			return false
	return true


## The words in a card's text, without their numbers.
static func stems(text: String) -> Array:
	var out := []
	var parts := text.split("[[")
	for i in range(1, parts.size()):
		var tok: String = parts[i].split("]]")[0]
		var keep := []
		for w in tok.split(" "):
			if w == "" or w == "X" or _is_number_word(w):
				continue
			keep.append(w)
		var s := " ".join(keep)
		var stop := false
		for k in STOP:
			if s.begins_with(k):
				stop = true
				break
		if s != "" and not stop and not out.has(s):
			out.append(s)
	return out


## One entry of a card made before, as the library ability nearest to it ("" for a plain attack).
static func nearest_ability(e: Dictionary, melee: bool) -> String:
	var t := str(e.get("text", "")) if e.get("text") != null else ""
	var kind := str(e.get("kind", "")) if e.get("kind") != null else ""
	var role := str(e.get("role", "")) if e.get("role") != null else ""
	if kind == "Aura":
		if t.contains("[[DMG +"): return "U2"
		if t.contains("[[Aim +"): return "U3"
		if t.contains("[[MS +"): return "U4"
		if t.contains("[[Range +"): return "U5"
		return "U1"
	if kind == "Passive":
		if t.contains("[[gain Aether"): return "P16" if t.contains("kills an enemy") else "P15"
		if t.contains("[[Deploy "): return "P14"
		if t.contains("kills an enemy"): return "P10"
		if t.contains("is attacked"): return "P11"
		if t.contains("is Incapacitated"): return "P12"
		if t.contains("below half HP"): return "P9"
		if t.contains("the round begins"): return "P13"
		if t.contains("[[Hardened"): return "P2"
		if t.contains("[[Evasive") or t.contains("[[Flying"): return "P3"
		if t.contains("[[Leap "): return "P4"
		if t.contains("[[MS +"): return "P5"
		if t.contains("[[Aim +"): return "P6"
		if t.contains("[[AC +"): return "P7"
		if t.contains("[[Range +"): return "P8"
		return "P1"
	var dmg := str(e.get("damage", "")) if e.get("damage") != null else ""
	var bdmg := str(e.get("baseDamage", "")) if e.get("baseDamage") != null else ""
	# an attack: a Unit's hit with damage, or anything aimed at an Enemy that doesn't heal
	var attack := ((role == "melee" or role == "ranged" or role == "cyber") and (dmg != "" or bdmg != "")) or ((t.contains("[[target enemy]]") or t.contains("[[all enemies")) and not t.contains("[[heal "))
	if not attack:
		if t.contains("[[heal "): return "S6" if t.contains("[[remove ") else "S1"
		if t.contains("[[remove "): return "S6"
		if t.contains("[[Deploy "): return "S7"
		if t.contains("[[Barricade"): return "S8"
		if t.contains("[[Leap "): return "S9"
		if t.contains("[[Dash "): return "S5"
		if t.contains("[[NRG +"): return "S4"
		if t.contains("[[AC +") or t.contains("[[Hardened"): return "S3"
		return "S2"
	if t.contains("[[Burst "): return "A2" if melee else "A12"
	if t.contains("[[Lunge ") or t.contains("[[Charge "): return "A3"
	if t.contains("[[Push "): return "A4"
	if t.contains("[[Stunned"): return "A5"
	if t.contains("[[Rooted"): return "A7"
	if t.contains("[[Slowed"): return "A6"
	if t.contains("[[Poisoned") or t.contains("[[Bleed"): return "A8"
	if t.contains("[[Weakened") or t.contains("[[Drained"): return "A9"
	if t.contains("[[Marked") or t.contains("[[Pinned"): return "A10"
	if t.contains("[[AoE ") or t.contains("[[Line ") or t.contains("[[Cone ") or t.contains("[[Chain "): return "A2" if melee else "A11"
	if t.contains("[[Pierce"): return "A13"
	if t.contains("[[Execute") or t.contains("below half HP"): return "A14"
	if t.contains("[[this Unit]] takes [[damage"): return "A15"
	return ""


static func _num0(v) -> int:
	var s := (str(v) if v != null else "").strip_edges()
	if s.is_valid_int():
		return int(s)
	# leading digits ("5(X)")
	var n := ""
	var start := 0
	if s.begins_with("-") or s.begins_with("+"):
		n = s.substr(0, 1)
		start = 1
	for i in range(start, s.length()):
		var ch := s[i]
		if ch >= "0" and ch <= "9":
			n += ch
		else:
			break
	return int(n) if n.trim_prefix("-").trim_prefix("+") != "" else 0


## The Lab build nearest to a card made before (Convert).
static func guess(card: Dictionary) -> Variant:
	var d := data()
	var type := str(card.get("cardType", ""))
	var rarity: String = str(card.get("rarity")) if d["rarities"].has(str(card.get("rarity", ""))) else "common"
	var entries: Array = card.get("entries") if card.get("entries") is Array else []
	var texts := []
	for e in entries:
		texts.append(str(e.get("text", "")) if e is Dictionary and e.get("text") != null else "")
	var text := " ".join(texts)
	if MENU_TYPES.has(type):
		var l: Array = d["menus"].get(type, [])
		var best = null
		var best_n := -1
		var mine := stems(text)
		for m in l:
			if m.get("min") != null and rarity_rank(rarity) < rarity_rank(m["min"]):
				continue
			var n := 0
			for s in stems(str(m["tiers"][0]["text"])):
				if mine.has(s):
					n += 1
			if n > best_n:
				best_n = n
				best = m
		var b := {"type": type, "rarity": rarity, "menu": str(best["id"]) if best != null else (str(l[0]["id"]) if l.size() > 0 else ""),
			"tier": maxi(1, mini(tier_cap(rarity), best["tiers"].size() if best != null else 1))}
		if type == "equipment" and rarity_rank(rarity) >= rarity_rank("rare") and text.contains("[[when]]"):
			var tb = null
			var tn := 0
			for tr in d["equipTriggers"]:
				var n := 0
				for s in stems(str(tr["text"])):
					if mine.has(s):
						n += 1
				if n > tn:
					tn = n
					tb = tr
			if tb != null:
				b["trigger"] = str(tb["id"])
		return b
	if type == "action":
		var e0: Dictionary = entries[0] if entries.size() > 0 and entries[0] is Dictionary else {}
		var r0 := str(e0.get("role", "")) if e0.get("role") != null else ""
		var id := nearest_ability(e0, r0 != "ranged")
		if id == "":
			id = "A13" if r0 == "ranged" else "A1"
		var a = ability(id)
		if a != null and a.get("min") != null and rarity_rank(rarity) < rarity_rank(a["min"]):
			id = "A1"
			a = ability(id)
		return {"type": type, "rarity": rarity, "ability": [id, maxi(1, mini(tier_cap(rarity), a["tiers"].size() if a != null else 1))]}
	if not UNIT.has(type):
		return null
	var roles: Array = card.get("combatRoles") if card.get("combatRoles") is Array else []
	var arch: Array = card.get("archetypes") if card.get("archetypes") is Array else []
	var st: Dictionary = card.get("stats") if card.get("stats") is Dictionary else {}
	var attacks := 0
	for e in entries:
		if e is Dictionary:
			var r := str(e.get("role", "")) if e.get("role") != null else ""
			var dm := str(e.get("damage", "")) if e.get("damage") != null else ""
			if (r == "melee" or r == "ranged" or r == "cyber") and dm != "":
				attacks += 1
	var role := "brute"
	if roles.has("support") and not roles.has("melee") and not roles.has("ranged") and not roles.has("cyber"):
		role = "support"
	elif roles.has("ranged") or roles.has("cyber"):
		role = "support" if (roles.has("support") and attacks == 0) else "shooter"
	elif roles.has("melee"):
		role = "skirmisher" if (_num0(st.get("move")) >= 5 or arch.has("Assassin") or arch.has("Light Infantry") or arch.has("Swarm") or arch.has("Chaff")) else "brute"
	var b := {"type": type, "role": role, "abilities": []}
	var hp := _num0(st.get("hp"))
	if ENEMYISH.has(type):
		b["skull"] = clampi(_num0(card.get("skullLevel")) if _num0(card.get("skullLevel")) != 0 else 1, 1, 6)
		var base: float = float(d["enemy"][role]["hp"][int(b["skull"]) - 1]) * float(d["grade"].get(grade_of(b), d["grade"]["enemy"])["hp"])
		var ratio: float = float(hp) / base if base > 0 else 1.0
		b["size"] = "heavy" if ratio >= 1.25 else ("light" if ratio <= 0.6 else "standard")
	else:
		b["rarity"] = rarity
		if type == "troop":
			if hp >= 45 and rarity_rank(rarity) >= rarity_rank("legendary"):
				b["size"] = "colossal"
			elif hp >= 30:
				b["size"] = "heavy"
			elif hp <= 15 or arch.has("Swarm") or arch.has("Chaff") or arch.has("Drone"):
				b["size"] = "light"
			else:
				b["size"] = "standard"
	var cp := caps(b)
	var seen := {}
	var passives := 0
	var plain := 0
	var melee: bool = str(d["roleAttack"][role]) == "melee"
	for e in entries:
		if not (e is Dictionary) or b["abilities"].size() >= int(cp["abilities"]):
			continue
		var id := nearest_ability(e, melee)
		if id == "":
			plain += 1
			if plain < 2:
				continue
			id = "A1" if melee else "A13"
		var a = ability(id)
		if a == null or seen.has(id) or not a["roles"].has(role):
			continue
		if a.get("min") != null and (ENEMYISH.has(type) or rarity_rank(rarity) < rarity_rank(a["min"])):
			continue
		var pas: bool = str(a["kind"]) == "passive" or str(a["kind"]) == "aura"
		if pas and passives >= int(cp["passives"]):
			continue
		seen[id] = true
		if pas:
			passives += 1
		b["abilities"].append([id, maxi(1, mini(int(cp["tier"]), a["tiers"].size()))])
	# the token a Summon or Escort brings, as its text named it
	var at := text.find("[[Deploy ")
	if at >= 0:
		var rest := text.substr(at + 9)
		var end := rest.find("]]")
		if end > 0:
			var inner := rest.substr(0, end)
			var sp := inner.find(" ")
			if sp > 0 and _is_number_word(inner.substr(0, sp)) and not inner.begins_with("+") and not inner.begins_with("-") and not inner.begins_with("\u2212"):
				var tok := inner.substr(sp + 1)
				var takes := false
				for x in b["abilities"]:
					if str(x[0]) == "S7" or str(x[0]) == "P14":
						takes = true
				if d["tokens"].has(tok) and takes:
					b["token"] = tok
	return b
