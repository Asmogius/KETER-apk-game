## (Lab) The Card Forge in KETER Lab (forge_screen.gd): a card is a Lab build
## (lab_systems.gd), as the Companion's Forge makes it with the Lab switch on.
## A unit is a role, a size and a rarity (an Enemy a Skull Level) and up to
## two abilities from the library at a tier; every other card is one item
## from its type's menu. Its stats, numbers and text come out of the build and
## can't be typed; name, District, archetypes, Aether cost and lore stay
## yours. A card made before is Legacy until Convert gives it the nearest
## build. The form's rows come from here: [["head", text], ["row", text,
## chips], ["rich", text, chips]], a chip [label, act, colour, on], every act
## ["lab", ...], which act() carries out.
class_name ForgeLab
extends RefCounted

const KINDS := [["attack", "Attacks"], ["support", "Support"], ["passive", "Passives"], ["aura", "Auras"]]


## Whether the Forge builds this kind of card the Lab way here.
static func on(t: String) -> bool:
	return LabSet.active() and (LabSystems.UNIT.has(t) or t == "action" or LabSystems.MENU_TYPES.has(t))


static func build(card: Dictionary) -> Variant:
	return card.get("lab") if card.get("lab") is Dictionary else null




## What the build compiles to goes into the card.
static func apply(card: Dictionary) -> Dictionary:
	var b = build(card)
	if b == null:
		return {}
	var r := LabSystems.compile(Rules.ints(b))
	var cc = r.get("card")
	if cc is Dictionary:
		for k in ["cardType", "rarity", "skullLevel", "combatRoles", "stats", "entries"]:
			if cc.has(k):
				card[k] = cc[k].duplicate(true) if (cc[k] is Dictionary or cc[k] is Array) else cc[k]
	return r


## The cost a build suggests: a Troop's for its points, a menu or Action card's for its tier; null for none.
static func suggested(card: Dictionary) -> Variant:
	var b = build(card)
	if b == null:
		return null
	var r := LabSystems.compile(Rules.ints(b))
	if str(b.get("type")) == "troop" and r.get("points") != null:
		return LabSystems.suggested_aether(r["points"])
	return r.get("cost")


static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1) if s != "" else s


static func _tiers(n: int, cur, act: Array) -> Array:
	var out := []
	for t in range(1, n + 1):
		out.append([LabSystems.ROMAN[t], act + [t], UI.CYAN, int(Rules.num(cur, 1)) == t])
	return out


## The Lab build's rows. open: the ability slot whose choices are showing (-1 none).
static func rows(card: Dictionary, open: int) -> Array:
	var out := []
	var b = build(card)
	if b == null:
		out.append(["head", "Legacy card"])
		out.append(["row", "Made before the Lab, it plays as it is; here it can't be changed the old way. Convert gives it the nearest Lab build, to change and keep.",
			[["Convert to a Lab build", ["lab", "convert"], UI.CYAN, false]]])
		return out
	var d := LabSystems.data()
	var type := str(b.get("type", ""))
	var r := LabSystems.compile(Rules.ints(b))
	out.append(["head", "Lab build"])
	if LabSystems.UNIT.has(type):
		var foe: bool = LabSystems.ENEMYISH.has(type)
		out.append(["row", "Role", (d["roles"] as Array).map(func(x): return [str(d["roleName"][x]), ["lab", "role", x], UI.CYAN, str(b.get("role")) == x])])
		var sizes: Array = (d["enemySize"] as Dictionary).keys() if foe else d["sizes"]
		if foe or type == "troop":
			out.append(["row", "Size", sizes.map(func(x): return [_cap(str(x)) + (" (Legendary+)" if x == "colossal" else ""), ["lab", "size", x], UI.CYAN, str(b.get("size", "standard")) == x])])
		if foe:
			var sk := int(Rules.num(b.get("skull"), 1))
			out.append(["row", "Skull Level", [["−", ["lab", "skull", -1], UI.CYAN, false], [str(sk), null, UI.TEXT, false], ["+", ["lab", "skull", 1], UI.CYAN, false]]])
		else:
			out.append(["row", "Rarity", (d["rarities"] as Array).map(func(x): return [_cap(str(x)), ["lab", "rarity", x], Color(DockScreen.rarity_colour((d["rarities"] as Array).find(x))), str(b.get("rarity", "common")) == x])])
		var tr := [["None", ["lab", "trade", -1], UI.CYAN, b.get("trade") == null]]
		var i := 0
		for t in d["trades"]:
			for pair in [[t[0], t[1], t[2], t[3]], [t[2], t[3], t[0], t[1]]]:
				var on: bool = b.get("trade") is Array and str(b["trade"][0]) == str(pair[0]) and int(Rules.num(b["trade"][1], 0)) == int(Rules.num(pair[1], 0)) and str(b["trade"][2]) == str(pair[2])
				tr.append(["−%d %s +%d %s" % [int(Rules.num(pair[1], 0)), str(pair[0]).to_upper(), int(Rules.num(pair[3], 0)), str(pair[2]).to_upper()], ["lab", "trade", i], UI.CYAN, on])
				i += 1
		out.append(["row", "Trade", tr])
		var cp := LabSystems.caps(b)
		var ab: Array = b.get("abilities", []) if b.get("abilities") is Array else []
		out.append(["head", "Abilities (%d of %d · tier %s at most)" % [ab.size(), int(cp["abilities"]), LabSystems.ROMAN[int(cp["tier"])]]])
		for k in ab.size():
			var x: Array = ab[k]
			if str(x[0]) == "SIG":
				out.append_array(_sig_rows(x[1] if x[1] is Dictionary else {}, k, true))
				continue
			var a = LabSystems.ability(x[0])
			var chips := [[(str(x[0]) + " · " + str(a["name"])) if a != null else str(x[0]), ["lab", "open", k], UI.CYAN, open == k]]
			chips.append_array(_tiers(mini(3, (a["tiers"] as Array).size()) if a != null else 1, x[1], ["lab", "tier", k]))
			chips.append(["Remove", ["lab", "del", k], UI.SOFT_RED, false])
			out.append(["row", "Ability %d%s" % [k + 1, (": " + str(a["does"])) if a != null else ""], chips])
			if open == k:
				out.append_array(_choices(b, ["lab", "pick", k], str(x[0])))
		if ab.size() < int(cp["abilities"]):
			var add := [["+ Add an ability", ["lab", "add"], UI.CYAN, false]]
			if cp["signature"] and not ab.any(func(x): return str(x[0]) == "SIG"):
				add.append(["+ Add a signature ability", ["lab", "addsig"], UI.GOLD, false])
			out.append(["row", "", add])
		var tokened := ab.any(func(x): return str(x[0]) != "SIG" and LabSystems.ability(x[0]) != null and str(LabSystems.ability(x[0])["tiers"][0]["text"]).contains("{token}"))
		if tokened:
			out.append(["row", "Token it brings", (d["tokens"] as Array).map(func(t): return [str(t), ["lab", "token", t], UI.CYAN, str(b.get("token", "Scuttlebot")) == t])])
	elif type == "action":
		out.append(["row", "Rarity", (d["rarities"] as Array).map(func(x): return [_cap(str(x)), ["lab", "rarity", x], Color(DockScreen.rarity_colour((d["rarities"] as Array).find(x))), str(b.get("rarity", "common")) == x])])
		var x: Array = b.get("ability") if b.get("ability") is Array else ["A1", 1]
		if str(x[0]) == "SIG":
			out.append(["row", "Ability", [["Signature", ["lab", "open", 0], UI.GOLD, open == 0]]])
			if open == 0:
				out.append_array(_choices(b, ["lab", "apick"], "SIG"))
			out.append_array(_sig_rows(x[1] if x[1] is Dictionary else {}, -1, false))
		else:
			var a = LabSystems.ability(x[0])
			var chips := [[(str(x[0]) + " · " + str(a["name"])) if a != null else str(x[0]), ["lab", "open", 0], UI.CYAN, open == 0]]
			chips.append_array(_tiers(mini(3, (a["tiers"] as Array).size()) if a != null else 1, x[1], ["lab", "atier"]))
			out.append(["row", "Ability" + ((": " + str(a["does"])) if a != null else ""), chips])
			if open == 0:
				out.append_array(_choices(b, ["lab", "apick"], str(x[0])))
			if a != null and str(a["tiers"][0]["text"]).contains("{token}"):
				out.append(["row", "Token it brings", (d["tokens"] as Array).map(func(t): return [str(t), ["lab", "token", t], UI.CYAN, str(b.get("token", "Scuttlebot")) == t])])
	else:
		out.append(["row", "Rarity", (d["rarities"] as Array).map(func(x): return [_cap(str(x)), ["lab", "rarity", x], Color(DockScreen.rarity_colour((d["rarities"] as Array).find(x))), str(b.get("rarity", "common")) == x])])
		var items: Array = d["menus"].get(type, [])
		var rr := LabSystems.rarity_rank(b.get("rarity", "common"))
		out.append(["row", "Card", items.map(func(m): return [str(m["id"]) + " · " + str(m["name"]), ["lab", "menu", m["id"]] if (m.get("min") == null or rr >= LabSystems.rarity_rank(m["min"]) or str(m["id"]) == str(b.get("menu"))) else null,
			UI.CYAN if (m.get("min") == null or rr >= LabSystems.rarity_rank(m["min"])) else UI.PALE, str(m["id"]) == str(b.get("menu"))])])
		var m = LabSystems.menu_item(type, b.get("menu"))
		out.append(["row", "Tier", _tiers((m["tiers"] as Array).size() if m != null else 1, b.get("tier", 1), ["lab", "mtier"])])
		if type == "equipment":
			var trg := [["None", ["lab", "trig", ""], UI.CYAN, not Rules.truthy(b.get("trigger"))]]
			for t in d["equipTriggers"]:
				trg.append([str(t["id"]) + " · " + str(t["name"]), ["lab", "trig", t["id"]], UI.CYAN, str(b.get("trigger", "")) == str(t["id"])])
			out.append(["row", "Trigger (Rare and rarer)", trg])
	# what it is worth, what it costs, what it breaks
	if r.get("points") != null:
		var tg = r.get("target")
		var words := "%d points" % int(r["points"])
		if tg != null:
			var gap := int(r["points"]) - int(tg)
			words += " · %s target %d · %s" % [_cap(str(b.get("rarity", "common"))), int(tg), "on target" if absi(gap) <= 4 else (("%d over" % gap) if gap > 0 else ("%d under" % -gap))]
		out.append(["row", words, []])
	var sug = suggested(card)
	if sug != null:
		var ac: Dictionary = card.get("aetherCost") if card.get("aetherCost") is Dictionary else {}
		var now := int(Rules.num(ac.get("generic"), 0)) + int(Rules.num(ac.get("affinity"), 0)) + int(Rules.num(ac.get("affinity2"), 0))
		out.append(["row", "Suggested cost: %d Aether (it costs %d)" % [int(sug), now], [] if now == int(sug) else [["Use it", ["lab", "cost"], UI.CYAN, false]]])
	for p in r.get("problems", []):
		out.append(["row", "Breaks a rule: " + str(p), []])
	if (r.get("problems", []) as Array).is_empty():
		out.append(["row", "The build keeps every rule.", []])
	return out


## The library's abilities for a slot, by kind; those the build can't take are shown, and can't be chosen.
static func _choices(b: Dictionary, act: Array, cur: String) -> Array:
	var d := LabSystems.data()
	var out := []
	var type := str(b.get("type", ""))
	var foe: bool = LabSystems.ENEMYISH.has(type)
	var role := str(b.get("role", ""))
	var rr := LabSystems.rarity_rank(b.get("rarity", "common"))
	for kd in KINDS:
		var chips := []
		for a in d["library"]:
			if str(a["kind"]) != kd[0]:
				continue
			var shut: bool = (type != "action" and not (a["roles"] as Array).has(role)) or (a.get("min") != null and (foe or rr < LabSystems.rarity_rank(a["min"])))
			chips.append([str(a["id"]) + " · " + str(a["name"]), null if shut else act + [a["id"]], UI.PALE if shut else UI.CYAN, str(a["id"]) == cur])
		out.append(["row", "  " + str(kd[1]), chips])
	if type == "action" and LabSystems.caps(b)["signature"]:
		out.append(["row", "  Its own", [["Signature", act + ["SIG"], UI.GOLD, cur == "SIG"]]])
	return out


## A signature ability's rows (k: its slot on a unit; -1 an Action card's).
static func _sig_rows(sg: Dictionary, k: int, removable: bool) -> Array:
	var out := []
	var chips := [[str(sg.get("name", "Signature")), ["lab", "sname", k], UI.GOLD, true]]
	for kd in KINDS:
		chips.append([str(kd[1]).trim_suffix("s"), ["lab", "skind", k, kd[0]], UI.CYAN, str(sg.get("kind", "passive")) == kd[0]])
	if removable:
		chips.append(["Remove", ["lab", "del", k], UI.SOFT_RED, false])
	out.append(["row", "Signature", chips])
	out.append(["rich", "  " + (str(sg.get("text", "")) if str(sg.get("text", "")) != "" else "No text yet."), [["Write it", ["lab", "stext", k], UI.CYAN, false]]])
	out.append(["row", "  Its points (set by hand)", [["−", ["lab", "spts", k, -1], UI.CYAN, false], [str(int(Rules.num(sg.get("points"), 0))), null, UI.TEXT, false], ["+", ["lab", "spts", k, 1], UI.CYAN, false]]])
	return out


## The signature a slot holds (k -1: an Action card's).
static func sig_of(card: Dictionary, k: int) -> Dictionary:
	var b: Dictionary = build(card)
	var x: Array = b["ability"] if k < 0 else b["abilities"][k]
	if not (x[1] is Dictionary):
		x[1] = {"name": "Signature", "kind": "passive", "text": "", "points": 0}
	return x[1]


## Carries out a tap on one of the Lab rows. Returns the slot to show open next.
static func act(card: Dictionary, what: Array, open: int) -> int:
	var op := str(what[1])
	if op == "convert":
		card["lab"] = LabSystems.guess(Rules.ints(card))
		apply(card)
		return -1
	var b = build(card)
	if b == null:
		return -1
	var type := str(b.get("type", ""))
	var keep_open := -1
	match op:
		"role":
			b["role"] = what[2]
		"size":
			b["size"] = what[2]
		"rarity":
			b["rarity"] = what[2]
		"skull":
			b["skull"] = clampi(int(Rules.num(b.get("skull"), 1)) + int(what[2]), 1, 6)
		"trade":
			var i := int(what[2])
			if i < 0:
				b.erase("trade")
			else:
				var t: Array = LabSystems.data()["trades"][i / 2]
				b["trade"] = [t[0], t[1], t[2], t[3]] if i % 2 == 0 else [t[2], t[3], t[0], t[1]]
		"open":
			keep_open = -1 if open == int(what[2]) else int(what[2])
		"pick":
			var k := int(what[2])
			b["abilities"][k] = [what[3], mini(int(Rules.num(b["abilities"][k][1], 1)) if not (b["abilities"][k][1] is Dictionary) else 1, int(LabSystems.caps(b)["tier"]))]
		"tier":
			b["abilities"][int(what[2])][1] = int(what[3])
		"del":
			b["abilities"].remove_at(int(what[2]))
		"add":
			var first := ""
			for a in LabSystems.data()["library"]:
				var taken: bool = (b["abilities"] as Array).any(func(x): return str(x[0]) == str(a["id"]))
				if (a["roles"] as Array).has(str(b.get("role"))) and a.get("min") == null and not taken:
					first = str(a["id"])
					break
			if first != "":
				b["abilities"].append([first, 1])
				keep_open = (b["abilities"] as Array).size() - 1
		"addsig":
			b["abilities"].append(["SIG", {"name": str(card.get("name", "Signature")), "kind": "passive", "text": "", "points": 0}])
		"token":
			b["token"] = what[2]
		"apick":
			if str(what[2]) == "SIG":
				b["ability"] = ["SIG", {"name": str(card.get("name", "Signature")), "kind": "support", "text": "", "points": 0}]
			else:
				var was: Array = b.get("ability") if b.get("ability") is Array else ["A1", 1]
				b["ability"] = [what[2], mini(int(Rules.num(was[1], 1)) if not (was[1] is Dictionary) else 1, LabSystems.tier_cap(b.get("rarity")))]
		"atier":
			b["ability"][1] = int(what[2])
		"menu":
			b["menu"] = what[2]
		"mtier":
			b["tier"] = int(what[2])
		"trig":
			if str(what[2]) == "":
				b.erase("trigger")
			else:
				b["trigger"] = what[2]
		"skind":
			sig_of(card, int(what[2]))["kind"] = what[3]
		"spts":
			var sg := sig_of(card, int(what[2]))
			sg["points"] = maxi(0, int(Rules.num(sg.get("points"), 0)) + int(what[3]))
		"cost":
			var n = suggested(card)
			if n != null:
				var ac: Dictionary = card.get("aetherCost") if card.get("aetherCost") is Dictionary else {}
				var aff := mini(maxi(0, int(Rules.num(ac.get("affinity"), 0))), int(n))
				card["aetherCost"] = {"generic": int(n) - aff, "affinity": aff, "affinity2": 0}
			return open
	apply(card)
	return keep_open
