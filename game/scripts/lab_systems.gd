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
