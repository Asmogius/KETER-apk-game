## The Companion's rules suite (verify_rules.py), translated check for check,
## run against the game's rules.gd:
##   godot --headless --path . --script res://tests/rules_tests.gd
## Each check keeps its original wording so the two suites can be read side by
## side. The generated comparison (rules_diff.gd) covers the rest.
extends SceneTree

var ok := 0
var bad := 0
var failed := []
var part_ok := 0
var part_bad := 0


## A die that always shows the same face, for attacks with a known outcome.
class Fixed:
	extends Rules.Dice
	var v := 1

	func _init(value: int) -> void:
		v = value
		seeded = true

	func raw(_sides: int) -> int:
		return v


func ck(name: String, cond: bool, detail = "") -> void:
	if cond:
		ok += 1
		part_ok += 1
	else:
		bad += 1
		part_bad += 1
		failed.append(name + "  — " + JSON.stringify(_plain(detail)).left(300))


func part(title: String) -> void:
	print("%s PASS %d  FAIL %d" % [title, part_ok, part_bad])
	for f in failed:
		print("  x " + f)
	failed.clear()
	part_ok = 0
	part_bad = 0


func _plain(v):
	if v is Array:
		return v.map(func(x): return _plain(x))
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = _plain(v[k])
		return d
	if v is Object:
		return str(v)
	return v


## Equal as JSON would be: numbers by value, null and missing alike.
func same(a, b) -> bool:
	if a == null or b == null:
		return a == null and b == null
	if (a is int or a is float) and (b is int or b is float):
		return absf(float(a) - float(b)) < 1e-9
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for i in a.size():
			if not same(a[i], b[i]):
				return false
		return true
	if a is Dictionary and b is Dictionary:
		var keys := {}
		for k in a: keys[k] = true
		for k in b: keys[k] = true
		for k in keys:
			if not same(a.get(k), b.get(k)):
				return false
		return true
	if (a is String or a is StringName) and (b is String or b is StringName):
		return str(a) == str(b)
	if typeof(a) != typeof(b):
		return false
	return a == b


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_resolver()
	part("RESOLVER")
	_attacks()
	part("ATTACKS")
	_round_loop()
	part("ROUND LOOP")
	_dice()
	part("DICE")
	_aether()
	part("AETHER")
	print("\nRULES TESTS PASS %d  FAIL %d" % [ok, bad])
	quit(1 if bad > 0 else 0)


func _kinds(events: Array) -> Array:
	return events.map(func(e): return e["type"])


func _has_type(events: Array, t: String) -> bool:
	return events.any(func(e): return e["type"] == t)


# ================================================================ part one
func _resolver() -> void:
	ck("the resolver loads", Rules.VERSION != "")
	var inst: Object = Rules.new()
	ck("it needs no interface", not (inst is Node) and not (inst is CanvasItem))
	var all := Rules.behaviors()
	var enemy := all.filter(func(b): return b["side"] == "enemy").size()
	var ally := all.filter(func(b): return b["side"] == "ally").size()
	ck("it shares the behaviour table", all.size() == 21, all.size())
	ck("both sides are in it", enemy == 9 and ally == 12, [enemy, ally])

	# ---------- health ----------
	var u := Rules.make_unit({"name": "T", "hpMax": 20, "will": 3})
	var ev := Rules.hit(u, 7)
	ck("one hit of 7 removes 7", u["hp"] == 13, u)
	ck("and counts as one instance", u["hits"] == 1, u)
	ck("it reports what happened", _kinds(ev).has("hit"), ev)

	u = Rules.make_unit({"hpMax": 20, "ac": 12})
	for i in 9:
		Rules.hit(u, 1)
	ck("instances are still counted", u["hits"] == 9, u)
	ck("but however many hits land, no status follows", u["statuses"].size() == 0, u)
	ck("no Unit carries Will or a Mechanical flag", u.get("will") == null and u.get("mech") == null, u)
	ck("and Integrity starts equal to Armor Class", u["integrity"] == 12, u)

	u = Rules.make_unit({"hpMax": 20, "hp": 20})
	var h: Dictionary = Rules.heal(u, 8)[0]
	var hp_after = u["hp"]
	var g: Dictionary = Rules.gain(u, 6)[0]
	ck("healing stops at the printed figure", u["hp"] == 26 and h["amount"] == 0 and hp_after == 20, [h, u])
	ck("it reports the waste", h["wasted"] == 8, h)
	ck("gaining Health goes above it", g["over"] == 6, g)

	u = Rules.make_unit({"hpMax": 10})
	ev = Rules.hit(u, 999)
	ck("Health never goes below zero", u["hp"] == 0, u)
	ck("going down is reported", Rules.truthy(u["down"]) and _has_type(ev, "down"), ev)

	# ---------- statuses ----------
	u = Rules.make_unit({"ms": 5, "ac": 11})
	var before := Rules.effective(u)
	Rules.add_status(u, "Marked", null, null, 2)
	var marked := Rules.effective(u)
	u["mods"] = [{"stat": "INT", "amt": 3, "dur": "turns", "n": 2}, {"stat": "WIL", "amt": 1, "dur": "turns", "n": 2}]
	var raised := Rules.effective(u)
	ck("an unaffected Unit keeps its Movement Speed", before["ms"] == 5, before)
	ck("its Integrity is its Armor Class", before["integrity"] == 11, before)
	ck("Ranged Attacks against a Marked Unit always hit", marked.get("alwaysHit") == true, marked)
	ck("an INT change raises Integrity, and an old WIL change reads as INT", raised["integrity"] == 15, raised)

	# ---------- turns ----------
	var hero := Rules.make_unit({"name": "H", "cardType": "hero", "nrgMax": 4, "nrg": 1})
	var troop := Rules.make_unit({"name": "T", "cardType": "troop", "nrgMax": 4, "nrg": 1})
	Rules.hit(troop, 1)
	Rules.add_status(hero, "Marked", 2)
	Rules.add_status(hero, "Forever", null, null, 999)
	Rules.end_turn([hero, troop])
	Rules.recharge_tick([hero, troop])
	var m = Rules.status_of(hero, "Marked")
	var after_one := {"hero": hero["nrg"], "troop": troop["nrg"], "hits": troop["hits"], "marked": m["turns"] if m != null else null}
	Rules.end_turn([hero, troop])
	Rules.recharge_tick([hero, troop])
	ck("a Hero carries unspent Energy over", after_one["hero"] == 5, after_one)
	ck("a Troop resets instead", after_one["troop"] == 4, after_one)
	ck("damage instances clear", after_one["hits"] == 0, after_one)
	ck("a timed status counts down", after_one["marked"] == 1, after_one)
	ck("and expires on schedule", not Rules.has_status(hero, "Marked"))
	ck("an open-ended status stays", Rules.has_status(hero, "Forever"))

	# ---------- actions ----------
	var fx := [Rules.action_effect({"dmg": "8", "text": "Deal 8 damage."}),
		Rules.action_effect({"text": "Heals 5."}),
		Rules.action_effect({"text": "Target gains +6 HP."}),
		Rules.action_effect({"text": "Push the target 1 tile."})]
	ck("damage is read off the card", fx[0]["damage"] == 8, fx[0])
	ck("healing is read from the text", fx[1]["heal"] == 5, fx[1])
	ck("a Health gain is separate", fx[2]["gain"] == 6, fx[2])
	ck("an Action with no numbers yields none", not fx[3].values().any(func(v): return Rules.truthy(v)), fx[3])

	var a := Rules.make_unit({"name": "A", "nrg": 4, "ms": 4})
	var t := Rules.make_unit({"name": "T", "hpMax": 30, "hp": 30, "will": 9})
	Rules.use_action(a, {"name": "Hit", "tag": "Active", "cost": 2, "dmg": "8"}, t)
	ck("using an Action spends its Energy", a["nrg"] == 2, a)
	ck("damage lands on the target", t["hp"] == 22, t)
	ck("the target remembers who attacked it", t.get("lastAttackedBy") == a["id"], t)

	# ---------- outcome ----------
	var al := Rules.make_unit({"side": "ally"})
	var en := Rules.make_unit({"side": "enemy"})
	var mid := Rules.outcome([al, en])
	en["down"] = true
	var won := Rules.outcome([al, en])
	al["down"] = true
	var both := Rules.outcome([al, en])
	ck("a fight in progress is not over", mid["over"] == false, mid)
	ck("all Enemies down is a win", won["winner"] == "ally", won)
	ck("all Player Units down is a loss", both["winner"] == "draw" or Rules.truthy(both["over"]), both)

	# ---------- behaviour, which is what a simulator needs most ----------
	var team := _team()
	var r := {
		"none": Rules.choose_target(_foe([]), team, {})["name"],
		"cunning": Rules.choose_target(_foe(["cunning"]), team, {})["name"],
		"sadistic": Rules.choose_target(_foe(["sadistic"]), team, {})["name"],
		"opportunistic": Rules.choose_target(_foe(["opportunistic"]), team, {})["name"],
		"brutish": Rules.choose_target(_foe(["brutish"]), team, {})["name"],
	}
	ck("with no keyword it uses the default", ["Hero", "Tough", "Hurt"].has(r["none"]), r)
	ck("Cunning takes the Hero, ignoring Troops", r["cunning"] == "Hero", r)
	ck("Sadistic takes the lowest Health", r["sadistic"] == "Hurt", r)
	ck("Opportunistic takes the lowest Armor", r["opportunistic"] == "Hurt", r)
	ck("Brutish takes the highest Armor", r["brutish"] == "Tough", r)

	team = _team()
	var v := _foe(["vindictive"])
	var b4: String = Rules.choose_target(v, team, {})["name"]
	team[1]["id"] = "t"
	v["lastAttackedBy"] = "t"
	var aft: String = Rules.choose_target(v, team, {})["name"]
	ck("Vindictive uses the default until attacked", ["Hero", "Tough", "Hurt"].has(b4), b4)
	ck("then takes whoever attacked it", aft == "Tough", aft)

	team = _team()
	var rv := _foe(["ravenous"])
	var quiet: String = Rules.choose_target(rv, team, {})["name"]
	team[0]["attackedThisRound"] = true
	var piled: String = Rules.choose_target(rv, team, {})["name"]
	ck("Ravenous does nothing on its own", ["Hero", "Tough", "Hurt"].has(quiet), quiet)
	ck("then piles onto who was already attacked", piled == "Hero", piled)

	team = _team()
	var me := _foe(["methodical"])
	Rules.add_status(team[0], "Rooted", null, "enemy", 2)
	Rules.add_status(team[1], "Blessed", 2, "player")
	var picked: String = Rules.choose_target(me, team, {})["name"]
	ck("Methodical skips the Enemy-afflicted but not the player-buffed", ["Tough", "Hurt"].has(picked), picked)

	team = _team()
	var mix := _foe(["brutish", "vindictive"])
	var mb: String = Rules.choose_target(mix, team, {})["name"]
	mix["lastAttackedBy"] = "w"
	var ma: String = Rules.choose_target(mix, team, {})["name"]
	ck("an unconditional keyword applies while nothing else fires", mb == "Tough", mb)
	ck("a conditional keyword outranks it once it fires", ma == "Hurt", ma)

	# movement
	var mv := {
		"plain": Rules.move_plan(_mover([], 20), {"nearestEnemyDistance": 1}),
		"farOff": Rules.move_plan(_mover([{"k": "cautious", "x": 2}], 20), {"nearestEnemyDistance": 5}),
		"crowded": Rules.move_plan(_mover([{"k": "cautious", "x": 2}], 20), {"nearestEnemyDistance": 1}),
		"healthy": Rules.move_plan(_mover([{"k": "cowardly", "x": 5}], 20), {"nearestEnemyDistance": 1}),
		"broken": Rules.move_plan(_mover([{"k": "cowardly", "x": 5}], 4), {"nearestEnemyDistance": 1}),
	}
	ck("a plain Enemy closes", mv["plain"]["move"] == "toward", mv["plain"])
	ck("Cautious holds when nothing is near", mv["farOff"]["move"] == "toward", mv["farOff"])
	ck("Cautious backs off when crowded", mv["crowded"]["move"] == "away", mv["crowded"])
	ck("and still acts", mv["crowded"]["act"] == true, mv["crowded"])
	ck("Cowardly does nothing while healthy", mv["healthy"]["move"] == "toward", mv["healthy"])
	ck("Cowardly flees once broken", mv["broken"]["move"] == "away", mv["broken"])
	ck("and takes no Action", mv["broken"]["act"] == false, mv["broken"])

	# ---------- reading a card ----------
	var hc := Rules.unit_from_card({"name": "R", "cardType": "hero", "subtype": "cyborg",
		"stats": {"hp": "40", "ac": "9", "apT": "4", "move": "4"},
		"entries": [{"name": "G", "kind": "Active", "text": "Deal 8 damage.", "damage": "8", "energyCost": "2"}]})
	var tc := Rules.unit_from_card({"name": "T", "cardType": "troop", "stats": {"hp": "24", "nrg": "4", "will": "4", "move": "2"}})
	ck("a Hero's Energy comes from +NRG", hc["nrgMax"] == 4, hc["nrgMax"])
	ck("an old subtype on a card changes nothing", hc.get("mech") == null and hc.get("will") == null, hc)
	ck("a card with no Integrity takes it from Armor Class", hc["integrity"] == 9, hc["integrity"])
	ck("a Hero carries Energy over", hc["carries"] == true)
	ck("a Troop does not", tc["carries"] == false)
	ck("Actions come across with their numbers", hc["actions"][0]["dmg"] == "8" and hc["actions"][0]["cost"] == 2, hc["actions"])


func _team() -> Array:
	return [
		Rules.make_unit({"id": "h", "name": "Hero", "cardType": "hero", "side": "ally", "hpMax": 30, "hp": 30, "ac": 14}),
		Rules.make_unit({"id": "t", "name": "Tough", "cardType": "troop", "side": "ally", "hpMax": 20, "hp": 20, "ac": 16}),
		Rules.make_unit({"id": "w", "name": "Hurt", "cardType": "troop", "side": "ally", "hpMax": 20, "hp": 4, "ac": 9}),
	]


func _foe(keys: Array) -> Dictionary:
	return Rules.make_unit({"side": "enemy", "behaviors": keys.map(func(k): return {"k": k} if k is String else k)})


func _mover(bs: Array, hp: int) -> Dictionary:
	return Rules.make_unit({"side": "enemy", "hpMax": 20, "hp": hp, "behaviors": bs})


# ================================================================ part two
func _tgt(ac: int, extra := {}) -> Dictionary:
	var spec := {"id": "t", "name": "T", "hpMax": 40, "hp": 40, "ac": ac, "will": 9}
	spec.merge(extra, true)
	return Rules.make_unit(spec)


func _atk() -> Dictionary:
	return Rules.make_unit({"id": "a", "name": "A", "nrg": 9})


func _attacks() -> void:
	# ---- the dice ----
	var da := Rules.make_dice(12345)
	var db := Rules.make_dice(12345)
	var dc := Rules.make_dice()
	var ra := []
	var rb := []
	for i in 12:
		ra.append(da.d20())
		rb.append(db.d20())
	var lo := 99
	var hi := 0
	for j in 400:
		var v := dc.d20()
		lo = mini(lo, v)
		hi = maxi(hi, v)
	ck("the same seed gives the same rolls", ra == rb, [ra, rb])
	ck("a d20 stays within 1 and 20", lo >= 1 and hi <= 20, [lo, hi])
	ck("and reaches both ends", lo == 1 and hi == 20, [lo, hi])
	ck("an unseeded die is marked as such", dc.seeded == false)

	var atk := _atk()
	# ---- Melee always hits, but must still Penetrate ----
	var sw := {"name": "Swing", "role": "melee", "dmg": "6", "pen": "0"}
	var pass_ := Rules.resolve_attack(atk, sw, _tgt(10), {"dice": Fixed.new(12)})
	var fail := Rules.resolve_attack(atk, sw, _tgt(18), {"dice": Fixed.new(12)})
	ck("a Melee attack always hits", pass_["hit"] == true and fail["hit"] == true, fail)
	ck("it Penetrates when the roll meets Armor Class", pass_["penetrated"] == true and pass_["damage"] == 6, pass_)
	ck("and deals nothing when it does not", fail["penetrated"] == false and fail["damage"] == 0, fail)
	ck("the reason is reported", str(fail["reason"] if fail["reason"] != null else "").contains("Penetrate"), fail)

	# ---- Armor Penetration is added to the roll ----
	var bare := {"name": "Shot", "role": "melee", "dmg": "5", "pen": "0"}
	var ap := {"name": "Shot", "role": "melee", "dmg": "5", "pen": "4"}
	var without := Rules.resolve_attack(atk, bare, _tgt(15), {"dice": Fixed.new(12)})
	var with_ := Rules.resolve_attack(atk, ap, _tgt(15), {"dice": Fixed.new(12)})
	ck("without Penetration a 12 fails Armor Class 15", without["penetrated"] == false, without)
	ck("Armor Penetration is added directly to the roll", with_["penetrated"] == true and with_["penetrationTotal"] == 16, with_)

	# ---- Ranged needs both rolls ----
	var sh := {"name": "Shot", "role": "ranged", "dmg": "7", "hit": "11", "pen": "0", "rng": "6"}
	var both_pass := Rules.resolve_attack(atk, sh, _tgt(10), {"dice": Fixed.new(14), "distance": 3})
	var missed := Rules.resolve_attack(atk, sh, _tgt(10), {"dice": Fixed.new(6), "distance": 3})
	var no_pen := Rules.resolve_attack(atk, sh, _tgt(19), {"dice": Fixed.new(14), "distance": 3})
	var too_far := Rules.resolve_attack(atk, sh, _tgt(10), {"dice": Fixed.new(14), "distance": 9})
	ck("a Ranged attack that hits and Penetrates deals damage", both_pass["damage"] == 7, both_pass)
	ck("it takes two rolls", both_pass["rolls"].has("accuracy") and both_pass["rolls"].has("penetration"), both_pass["rolls"])
	ck("a roll below To-Hit misses", missed["hit"] == false and missed["damage"] == 0, missed)
	ck("a miss is not tested for Penetration", not missed["rolls"].has("penetration"), missed["rolls"])
	ck("hitting without Penetrating deals nothing", no_pen["hit"] == true and no_pen["damage"] == 0, no_pen)
	ck("beyond Attack Range it cannot be attacked", too_far["inRange"] == false and too_far["damage"] == 0, too_far)

	# ---- Cover and Evasive raise the To-Hit requirement ----
	var s2 := {"name": "Shot", "role": "ranged", "dmg": "5", "hit": "11", "pen": "9", "rng": "8"}
	var open_ := Rules.resolve_attack(atk, s2, _tgt(5), {"dice": Fixed.new(12), "distance": 2})
	var half := Rules.resolve_attack(atk, s2, _tgt(5), {"dice": Fixed.new(12), "distance": 2, "cover": 2})
	var full := Rules.resolve_attack(atk, s2, _tgt(5), {"dice": Fixed.new(12), "distance": 2, "cover": 4})
	var evasive := Rules.resolve_attack(atk, s2, _tgt(5), {"dice": Fixed.new(12), "distance": 2, "evasive": 3})
	ck("in the open a 12 beats To-Hit 11", open_["hit"] == true, open_)
	ck("Half Cover raises it to 13 and the same roll misses", half["hit"] == false and half["needed"] == 13, half)
	ck("Full Cover raises it to 15", full["needed"] == 15, full)
	ck("Evasive adds to it as well", evasive["needed"] == 14, evasive)

	# ---- Aether and Support ----
	var aeth := Rules.resolve_attack(atk, {"name": "Lance", "role": "aether", "dmg": "6"}, _tgt(20), {"dice": Fixed.new(1), "distance": 4})
	var supp := Rules.resolve_attack(atk, {"name": "Patch", "role": "support", "text": "Heals 5."}, _tgt(20), {"dice": Fixed.new(1)})
	ck("an Aether attack always hits and Penetrates", Rules.truthy(aeth["hit"]) and Rules.truthy(aeth["penetrated"]), aeth)
	ck("even against Armor Class 20 on a roll of 1", aeth["damage"] == 6, aeth)
	ck("its damage is marked as Aether Damage", aeth.get("aetherDamage") == true, aeth)
	ck("a Support Action always hits", supp["hit"] == true, supp)

	# ---- a Marked target is always hit ----
	var mt := _tgt(5)
	Rules.add_status(mt, "Marked", null, null, 2)
	var mr := Rules.resolve_attack(atk, {"name": "Shot", "role": "ranged", "dmg": "5", "hit": "19", "pen": "9", "rng": "8"}, mt, {"dice": Fixed.new(2), "distance": 2})
	ck("a Ranged attack on a Marked target always hits", mr["hit"] == true, mr)
	ck("and skips the accuracy roll", not mr["rolls"].has("accuracy"), mr["rolls"])

	# ---- a Cyber attack must penetrate Integrity, not Armor Class ----
	var cy := Rules.resolve_attack(atk, {"name": "Spike", "role": "cyber", "dmg": "6", "hit": "2", "pen": "2", "rng": "6"}, _tgt(5, {"integrity": 19}), {"dice": Fixed.new(15), "distance": 2})
	var cs := Rules.resolve_attack(atk, {"name": "Shot", "role": "ranged", "dmg": "6", "hit": "2", "pen": "2", "rng": "6"}, _tgt(5, {"integrity": 19}), {"dice": Fixed.new(15), "distance": 2})
	ck("a Cyber attack of 17 fails against Integrity 19", cy["penetrated"] == false and str(cy["reason"]).contains("Integrity"), cy)
	ck("while the same roll as a shot beats Armor Class 5", cs["penetrated"] == true, cs)

	# ---- applying it ----
	var t := _tgt(5)
	var ev := Rules.attack(atk, {"name": "Swing", "role": "melee", "dmg": "6", "pen": "9", "cost": 2}, t, {"dice": Fixed.new(15)})
	ck("applying an attack removes Health", t["hp"] == 34, t)
	ck("it spends the Energy", atk["nrg"] == 7, atk)
	ck("the target remembers the attacker", t.get("lastAttackedBy") == "a", t)
	ck("and is marked as attacked this round", t.get("attackedThisRound") == true, t)
	ck("it reports an attack and a hit", _kinds(ev).has("attack") and _kinds(ev).has("hit"), _kinds(ev))

	# ---- an out-of-range attack costs nothing ----
	var atk2 := _atk()
	var t2 := _tgt(5)
	Rules.attack(atk2, {"name": "Shot", "role": "ranged", "dmg": "6", "hit": "5", "pen": "9", "rng": "2", "cost": 3}, t2, {"dice": Fixed.new(20), "distance": 8})
	ck("an attack beyond range spends no Energy and deals nothing", t2["hp"] == 40 and atk2["nrg"] == 9, [t2["hp"], atk2["nrg"]])


# ================================================================ part three
func _hero(hp := 40, dmg := 8) -> Dictionary:
	return Rules.unit_from_card({"name": "Hero", "cardType": "hero",
		"stats": {"hp": str(hp), "ac": "9", "apT": "4", "move": "4"},
		"entries": [{"name": "Grinder", "kind": "Active", "role": "melee", "text": "Deal x damage.",
			"damage": str(dmg), "energyCost": "2", "armorPenetration": "9"}]}, "ally")


func _efoe(name: String, hp := 12, beh := [], dmg := 3) -> Dictionary:
	return Rules.unit_from_card({"name": name, "cardType": "enemy",
		"stats": {"hp": str(hp), "ac": "10", "will": "2", "move": "3"},
		"behaviors": beh,
		"entries": [{"name": "Bite", "kind": "Combo", "role": "melee", "text": "Deal y damage.",
			"damage": str(dmg), "energyCost": "1", "armorPenetration": "9"}]}, "enemy")


func _pair() -> Array:
	return [Rules.unit_from_card({"name": "H", "cardType": "hero", "stats": {"hp": "30", "ac": "13", "apT": "4"},
			"entries": [{"name": "A", "kind": "Active", "role": "melee", "damage": "5", "energyCost": "1", "armorPenetration": "0"}]}, "ally"),
		Rules.unit_from_card({"name": "E", "cardType": "enemy", "stats": {"hp": "26", "ac": "13", "will": "9"},
			"entries": [{"name": "B", "kind": "Combo", "role": "melee", "damage": "4", "energyCost": "1", "armorPenetration": "0"}]}, "enemy")]


func _round_loop() -> void:
	# ---- a fight resolves ----
	var out := Rules.run_combat([_hero(), _efoe("D1"), _efoe("D2")], {"dice": Rules.make_dice(7)})
	var kinds := {}
	for e in out["log"]:
		kinds[e["type"]] = kinds.get(e["type"], 0) + 1
	ck("a fight runs to a conclusion", ["ally", "enemy", "draw"].has(out["winner"]), out["winner"])
	ck("it takes a sensible number of rounds", out["rounds"] >= 1 and out["rounds"] <= 50, out["rounds"])
	ck("rounds are recorded", kinds.get("round", 0) == out["rounds"], kinds)
	ck("both sides attack", kinds.get("attack", 0) > 2, kinds)
	ck("turns end", kinds.get("turn", 0) == out["rounds"], kinds)

	# ---- reproducible ----
	var fa := Rules.run_combat(_pair(), {"dice": Rules.make_dice(99), "maxRounds": 40})
	var fb := Rules.run_combat(_pair(), {"dice": Rules.make_dice(99), "maxRounds": 40})
	var differs := false
	for s in range(1, 40):
		var fc := Rules.run_combat(_pair(), {"dice": Rules.make_dice(s), "maxRounds": 40})
		if fc["rounds"] != fa["rounds"] or fc["winner"] != fa["winner"]:
			differs = true
			break
	ck("the same seed gives the same fight", fa["winner"] == fb["winner"] and fa["rounds"] == fb["rounds"] and fa["log"].size() == fb["log"].size())
	ck("a different seed gives a different one", differs)

	# ---- victory conditions, as you defined them ----
	var easy := Rules.run_combat([_hero(80, 30), _efoe("D1", 5)], {"dice": Rules.make_dice(3)})
	var hard := Rules.run_combat([_hero(6, 1), _efoe("D1", 90, [], 40)], {"dice": Rules.make_dice(3)})
	ck("all Enemies down is a Player win", easy["winner"] == "ally", easy["winner"])
	ck("all Player Units down is a loss", hard["winner"] == "enemy", hard["winner"])

	# ---- a stalemate reports itself rather than hanging ----
	var sa := Rules.unit_from_card({"name": "H", "cardType": "hero", "stats": {"hp": "30", "ac": "20", "apT": "4"},
		"entries": [{"name": "Tap", "kind": "Active", "role": "melee", "damage": "0", "energyCost": "0"}]}, "ally")
	var se := Rules.unit_from_card({"name": "E", "cardType": "enemy", "stats": {"hp": "30", "ac": "20", "will": "9"},
		"entries": [{"name": "Tap", "kind": "Combo", "role": "melee", "damage": "0", "energyCost": "0"}]}, "enemy")
	var st := Rules.run_combat([sa, se], {"dice": Rules.make_dice(11), "maxRounds": 12})
	ck("a fight nobody can win stops and says so", st["winner"] == "stalemate" and st["rounds"] == 12, [st["winner"], st["rounds"]])

	# ---- Enemies act only after every Player Unit ----
	var o2 := Rules.run_combat([_hero(), _efoe("D1")], {"dice": Rules.make_dice(21)})
	var sides_of := {}
	for u in o2["units"]:
		sides_of[u["id"]] = u["side"]
	var sides := []
	for e in o2["log"]:
		if e["type"] == "turn":
			break
		if e["type"] == "attack":
			sides.append(sides_of[e["unit"]])
	var first_enemy := sides.find("enemy")
	var last_ally := sides.rfind("ally")
	ck("Enemies act only after the Player side", first_enemy == -1 or last_ally == -1 or first_enemy > last_ally, sides)

	# ---- behaviour drives targeting in a real fight ----
	var hh := Rules.unit_from_card({"name": "Hero", "cardType": "hero", "stats": {"hp": "40", "ac": "14", "apT": "4"},
		"entries": [{"name": "X", "kind": "Active", "role": "melee", "damage": "1", "energyCost": "0", "armorPenetration": "9"}]}, "ally")
	var tt := Rules.unit_from_card({"name": "Troop", "cardType": "troop", "stats": {"hp": "40", "ac": "9", "nrg": "4", "will": "9"},
		"entries": [{"name": "X", "kind": "Active", "role": "melee", "damage": "1", "energyCost": "0", "armorPenetration": "9"}]}, "ally")
	var hunter := _efoe("Hunter", 40, [{"key": "cunning"}], 3)
	var o3 := Rules.run_combat([hh, tt, hunter], {"dice": Rules.make_dice(31), "maxRounds": 3})
	var hits := {}
	for e in o3["log"]:
		if e["type"] == "attack" and e["unit"] == hunter["id"]:
			hits[e["target"]] = hits.get(e["target"], 0) + 1
	ck("a Cunning Enemy attacks the Hero past a Troop", hits.get(hh["id"], 0) > 0 and hits.get(tt["id"], 0) == 0, hits)

	# ---- a Cowardly Enemy stops attacking once broken ----
	var craven := _efoe("Craven", 30, [{"key": "cowardly", "value": 25}], 3)
	var o4 := Rules.run_combat([_hero(200, 1), craven], {"dice": Rules.make_dice(13), "maxRounds": 6})
	var skipped: int = o4["log"].filter(func(e): return e["type"] == "skip").size()
	ck("a Cowardly Enemy below its threshold takes no Action", skipped > 0, skipped)

	# ---- Combos run in order ----
	var seq := Rules.unit_from_card({"name": "Seq", "cardType": "enemy", "stats": {"hp": "40", "ac": "5", "will": "9"},
		"entries": [{"name": "One", "kind": "Combo", "role": "melee", "damage": "1", "energyCost": "0", "armorPenetration": "9"},
			{"name": "Two", "kind": "Combo", "role": "melee", "damage": "1", "energyCost": "0", "armorPenetration": "9"},
			{"name": "Three", "kind": "Combo", "role": "melee", "damage": "1", "energyCost": "0", "armorPenetration": "9"}]}, "enemy")
	var wall := Rules.unit_from_card({"name": "H", "cardType": "hero", "stats": {"hp": "500", "ac": "30", "apT": "4"},
		"entries": [{"name": "Poke", "kind": "Active", "role": "melee", "damage": "0", "energyCost": "0"}]}, "ally")
	var o5 := Rules.run_combat([wall, seq], {"dice": Rules.make_dice(8), "maxRounds": 5})
	var names := []
	for e in o5["log"]:
		if e["type"] == "attack" and e["unit"] == seq["id"]:
			names.append(e["name"])
	ck("a Combo runs in its printed order", names.slice(0, 3) == ["One", "Two", "Three"], names.slice(0, 4))
	ck("and wraps back to the start", names.size() > 3 and names[3] == "One", names.slice(0, 5))

	# ---- a Player Unit picks something it can afford ----
	var pu := Rules.make_unit({"nrg": 1, "actions": [
		{"name": "Cheap", "tag": "Active", "role": "melee", "cost": 1, "dmg": "3"},
		{"name": "Dear", "tag": "Active", "role": "melee", "cost": 5, "dmg": "20"},
		{"name": "Aura", "tag": "Aura", "role": "support", "cost": 0, "dmg": "99"}]})
	var pick = Rules.best_action(pu, Rules.make_unit({"hpMax": 30, "hp": 30}), {})
	ck("it never picks an Action it cannot pay for", pick != null and pick["name"] == "Cheap", pick)


# ================================================================ part four
func _dice() -> void:
	var d := Rules.make_dice()
	var out := {}
	for k in ["d20", "d6"]:
		var lo := 999
		var hi := 0
		var seen := {}
		for i in 600:
			var v := d.roll(k)
			seen[v] = 1
			lo = mini(lo, v)
			hi = maxi(hi, v)
		out[k] = {"lo": lo, "hi": hi, "distinct": seen.size()}
	var faces := {}
	for j in 300:
		faces[d.coin()["face"]] = 1
	var fk := faces.keys()
	fk.sort()
	ck("a d20 covers 1 to 20", out["d20"]["lo"] == 1 and out["d20"]["hi"] == 20 and out["d20"]["distinct"] == 20, out["d20"])
	ck("a d6 covers 1 to 6", out["d6"]["lo"] == 1 and out["d6"]["hi"] == 6 and out["d6"]["distinct"] == 6, out["d6"])
	ck("a coin gives heads and tails", fk == ["heads", "tails"], fk)

	var a := Rules.make_dice(4242)
	var b := Rules.make_dice(4242)
	var x := []
	var y := []
	for i in 10:
		x.append_array([a.roll("d20"), a.roll("d6"), a.coin()["value"]])
		y.append_array([b.roll("d20"), b.roll("d6"), b.coin()["value"]])
	ck("every kind is reproducible from a seed", x == y)
	var fs := [Rules.face_of("coin", 1), Rules.face_of("coin", 2), Rules.face_of("d20", 17)]
	ck("a roll reads back as a face", fs == ["heads", "tails", "17"], fs)

	var atk := _atk()
	var ranged := {"name": "Shot", "role": "ranged", "dmg": "7", "hit": "11", "pen": "0", "rng": "6"}
	var melee := {"name": "Swing", "role": "melee", "dmg": "6", "pen": "0"}

	# ---- auto mode resolves in one call ----
	var res := Rules.resolve_attack(atk, ranged, _tgt(10), {"dice": Rules.make_dice(5), "distance": 2})
	ck("Auto resolves without stopping", res["pending"] == null, res)
	ck("it rolls for accuracy itself", res["rolls"].has("accuracy"), res)
	ck("and rolls for Penetration only if it hit", res["rolls"].has("penetration") == (res["hit"] == true), res)

	# ---- manual mode asks, then resumes ----
	var t := _tgt(10)
	var first := Rules.resolve_attack(atk, ranged, t, {"manual": true, "distance": 2})
	var second := Rules.resolve_attack(atk, ranged, t, {"manual": true, "distance": 2, "rolls": {"accuracy": 14}})
	var third := Rules.resolve_attack(atk, ranged, t, {"manual": true, "distance": 2, "rolls": {"accuracy": 14, "penetration": 12}})
	ck("Manual asks for the accuracy roll first", first["pending"] == "accuracy" and first["die"] == "d20", first)
	ck("it says what the player needs to beat", first["needed"] == 11, first)
	ck("nothing is decided while it waits", first["hit"] == null and first["damage"] == 0, first)
	ck("given the roll it asks for Penetration next", second["pending"] == "penetration", second)
	ck("and reports the Armor Class to beat", second["needed"] == 10, second)
	ck("given both it settles", third["pending"] == null and third["damage"] == 7, third)

	# ---- a manual miss never asks for the second roll ----
	var ms := Rules.resolve_attack(atk, ranged, _tgt(10), {"manual": true, "distance": 2, "rolls": {"accuracy": 4}})
	ck("a miss is settled without a Penetration roll", ms["pending"] == null and ms["hit"] == false and not ms["rolls"].has("penetration"), ms)

	# ---- Melee asks for one roll, Aether for none ----
	var rm := Rules.resolve_attack(atk, melee, _tgt(10), {"manual": true})
	var rae := Rules.resolve_attack(atk, {"name": "L", "role": "aether", "dmg": "6"}, _tgt(20), {"manual": true})
	var rsu := Rules.resolve_attack(atk, {"name": "P", "role": "support", "text": "Heals 4."}, _tgt(20), {"manual": true})
	ck("Melee asks only for Penetration", rm["pending"] == "penetration", rm)
	ck("Aether asks for nothing and lands", rae["pending"] == null and rae["damage"] == 6, rae)
	ck("Support asks for nothing", rsu["pending"] == null, rsu)

	# ---- what to pick up, before rolling ----
	var over := _tgt(10)
	Rules.add_status(over, "Marked", null, null, 2)
	var fr := Rules.rolls_for(ranged, _tgt(10))
	var fm := Rules.rolls_for(melee, _tgt(10))
	var fa := Rules.rolls_for({"name": "L", "role": "aether"}, _tgt(10))
	var fc := Rules.rolls_for({"name": "C", "role": "cyber"}, _tgt(10))
	var fo := Rules.rolls_for(ranged, over)
	ck("a Ranged attack needs two d20s", fr.map(func(z): return z["die"]) == ["d20", "d20"], fr)
	ck("Melee needs one", fm.size() == 1, fm)
	ck("Aether needs none", fa.size() == 0, fa)
	ck("a Cyber attack needs two d20s, like Ranged", fc.size() == 2, fc)
	ck("a Marked target needs only Penetration", fo.size() == 1 and fo[0]["what"] == "penetration", fo)

	# ---- switching mode mid-attack is allowed ----
	var t3 := _tgt(10)
	var asked := Rules.resolve_attack(atk, ranged, t3, {"manual": true, "distance": 2})
	var done := Rules.resolve_attack(atk, ranged, t3, {"dice": Rules.make_dice(9), "distance": 2, "rolls": {"accuracy": asked["needed"]}})
	ck("a roll already made survives switching to Auto", done["rolls"].get("accuracy") == asked["needed"] and done["pending"] == null, done)
	ck("and the rest is rolled automatically", done["hit"] == true, done)


# ================================================================ part five
func _ahero(name: String, affs: Array) -> Dictionary:
	return Rules.unit_from_card({"name": name, "cardType": "hero", "affinities": affs, "stats": {"hp": "40", "apT": "4"}}, "ally")


func _atroop(name: String, affs: Array) -> Dictionary:
	return Rules.unit_from_card({"name": name, "cardType": "troop", "affinities": affs, "stats": {"hp": "20", "nrg": "4"}}, "ally")


func _aether() -> void:
	var four := Rules.aether_from_hero(_ahero("R", [{"district": "3", "level": 4}]))
	var three := Rules.aether_from_hero(_ahero("Y", [{"district": "3", "level": 3}]))
	var zero := Rules.aether_from_hero(_ahero("M", [{"district": "3", "level": 0}]))
	var none := Rules.aether_from_hero(_ahero("N", []))
	ck("Affinity Level 4 in District 3 gives 4 District 3 Aether", same(four, {"d3": 4}), four)
	ck("Level 3 gives 3", same(three, {"d3": 3}), three)
	ck("Level 0 gives nothing", same(zero, {}), zero)
	ck("no Affinity gives nothing", same(none, {}), none)
	var two := Rules.aether_from_hero(_ahero("Two", [{"district": "3", "level": 2}, {"district": "1", "level": 1}]))
	ck("two Affinities generate for both", same(two, {"d3": 2, "d1": 1}), two)

	var h := _ahero("H", [{"district": "3", "level": 4}])
	var t := _atroop("T", [{"district": "3", "level": 5}])
	var dead := _ahero("D", [{"district": "3", "level": 6}])
	dead["down"] = true
	var foe := Rules.unit_from_card({"name": "F", "cardType": "hero", "affinities": [{"district": "2", "level": 5}], "stats": {"hp": "20"}}, "enemy")
	var all := Rules.aether_income([h, t, dead, foe], "ally")
	var troop_alone := Rules.aether_income([t], "ally")
	var down_alone := Rules.aether_income([dead], "ally")
	ck("a Troop generates nothing however high its Affinity", same(troop_alone, {}), troop_alone)
	ck("a downed Hero generates nothing", same(down_alone, {}), down_alone)
	ck("only your own side counts, and only Heroes", same(all, {"d3": 4}), all)
	var sev := Rules.aether_income([_ahero("A", [{"district": "3", "level": 4}]), _ahero("B", [{"district": "3", "level": 3}])], "ally")
	ck("several Heroes add together", same(sev, {"d3": 7}), sev)

	# ---- paying with it ----
	var pool := func(): return {"d3": 4, "generic": 2}
	ck("District Aether pays its own District", Rules.aether_can_pay(pool.call(), {"district": "3", "affinity": 3, "generic": 0}))
	ck("but not more than you hold", not Rules.aether_can_pay(pool.call(), {"district": "3", "affinity": 5, "generic": 0}))
	ck("and not another District", not Rules.aether_can_pay(pool.call(), {"district": "1", "affinity": 1, "generic": 0}))
	ck("anything pays a generic cost", Rules.aether_can_pay(pool.call(), {"generic": 5}))
	ck("but not beyond the total", not Rules.aether_can_pay(pool.call(), {"generic": 7}))
	ck("the total counts every kind", Rules.aether_total(pool.call()) == 6)

	var p: Dictionary = pool.call()
	var paid := Rules.aether_pay(p, {"district": "3", "affinity": 2, "generic": 2})
	ck("paying takes it out of the pool", paid and Rules.aether_total(p) == 2, p)

	var p2 := {"d3": 1}
	var before = Rules.aether_total(p2)
	var paid2 := Rules.aether_pay(p2, {"district": "3", "affinity": 3})
	ck("a cost you cannot meet takes nothing", not paid2 and Rules.aether_total(p2) == before, p2)

	# ---- where the game parts from rules.js on purpose ----
	var p3 := {"d3": 2}
	Rules.aether_pay(p3, {"district": "5", "affinity": 0, "generic": 1})
	ck("paying a District cost of 0 leaves a plain 0, never Not-a-Number", same(p3, {"d3": 1, "d5": 0}) and Rules.aether_total(p3) == 1, p3)
