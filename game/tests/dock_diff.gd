## The proof that the game's dock is the Companion's: cases made by running
## dock.js as it is (make_dock_cases.js, in the Companion's sources), each
## replayed here and compared: its tables as Dev Mode may have saved them,
## and runs of what a player does at the dock (restocking; buying and selling
## components, lots, blueprints, chassis, Consumables, Prototypes and
## pre-built copies; recruiting Heroes; Reclaiming; upgrades; deployments
## coming home or wiped out), after each step what it said and how the dock, its stockpile and
## what it holds then stand, roll for roll.
##   godot --headless --path . --script res://tests/dock_diff.gd
extends SceneTree

const CASES := "res://tests/fixtures/dock_cases.json"
const EXPORT := "res://tests/fixtures/export.zip"
var by_fn := {}
var shown := {}
var x: KeterExport
var roster: Roster
var floors: Array[FloorData] = []
var loot_tables = null
var steps := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(CASES))
	if not (data is Dictionary):
		print("FAIL no cases at " + CASES)
		print("\nDOCK MATCH 0  DIFFER 1")
		quit(1)
		return
	data = Rules.ints(data)
	x = KeterExport.new()
	x.open(EXPORT)
	floors = x.floors()
	roster = Roster.new(x)
	loot_tables = roster.loot_tables()
	for c in Rules.ints(x.cards()):
		Keywords.register_archetypes(c.get("archetypes"))
	for c in data["cases"]:
		match c["fn"]:
			"tables":
				var t := Dock.read_tables(c["args"][0])
				_tally("tables", same(t, c["result"]), t, c["result"])
			"dock":
				_dock(c)
	var ok := 0
	var bad := 0
	var names := by_fn.keys()
	names.sort()
	for fn in names:
		ok += by_fn[fn][0]
		bad += by_fn[fn][1]
		print(("PASS " if by_fn[fn][1] == 0 else "FAIL ") + "%s: %d of %d match" % [fn, by_fn[fn][0], by_fn[fn][0] + by_fn[fn][1]])
	print("(from %s; %d steps at the dock)" % [data.get("made", "?"), steps])
	print("\nDOCK MATCH %d  DIFFER %d" % [ok, bad])
	quit(1 if bad > 0 else 0)


func _tally(fn: String, good: bool, got, want) -> void:
	if not by_fn.has(fn):
		by_fn[fn] = [0, 0]
	by_fn[fn][0 if good else 1] += 1
	if not good and shown.get(fn, 0) < 3:
		shown[fn] = shown.get(fn, 0) + 1
		print("DIFF %s\n   game: %s\n   comp: %s" % [fn, JSON.stringify(got).left(700), JSON.stringify(want).left(700)])
		var at := []
		_where(got, want, "", at)
		for w in at.slice(0, 6):
			print("   differs at " + w)


## Missing and null alike; numbers within a hair.
func same(a, b) -> bool:
	if a == null or b == null:
		return a == null and b == null
	if (a is int or a is float) and (b is int or b is float):
		return absf(float(a) - float(b)) < 1e-6
	if a is bool or b is bool:
		return a is bool and b is bool and a == b
	if (a is String or a is StringName) and (b is String or b is StringName):
		return str(a) == str(b)
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
	return false


func _where(a, b, path: String, out: Array) -> void:
	if out.size() >= 6 or same(a, b):
		return
	if a is Array and b is Array and a.size() == b.size():
		for i in a.size():
			_where(a[i], b[i], path + "[" + str(i) + "]", out)
		return
	if a is Dictionary and b is Dictionary:
		var keys := {}
		for k in a: keys[k] = true
		for k in b: keys[k] = true
		for k in keys:
			_where(a.get(k), b.get(k), path + "." + str(k), out)
		return
	out.append("%s: game %s, comp %s" % [path, JSON.stringify(a).left(200), JSON.stringify(b).left(200)])


## A stock as compared: its date left out.
static func _undated(v) -> Variant:
	if v is Dictionary:
		var o: Dictionary = v.duplicate(true)
		o.erase("made")
		return o
	return v


func _snap(dk: Dock, dep: Deployment, p: Progress) -> Dictionary:
	var s: Dictionary = dk.state
	return {"dock": {"reach": s["reach"], "upgrades": s["upgrades"], "stock": _undated(s["stock"]), "bounties": s["bounties"], "rot": s["rot"], "restocks": s["restocks"],
		"log": s["log"].map(func(l): return l["text"]), "heroes": s["heroes"]}, "inv": dk.inv, "stock": Loot.norm(dep.stock), "prog": {"bp": p.state["bp"], "ch": p.state["ch"], "named": p.state["named"]}}


func _effects(dk: Dock, ws: Workshop) -> Dictionary:
	var st = dk.state["stock"] if dk.state["stock"] is Dictionary else {"bps": [], "chs": [], "pre": [], "items": []}
	var nexts := []
	var levels := []
	var effs := []
	for u in Dock.UPGRADES:
		levels.append(dk.level(u["id"]))
		effs.append(dk.effect(u["id"]))
		nexts.append(dk.next_cost(u["id"]))
	return {"starterFree": dk.starter_free(), "scanRange": dk.scan_range(), "insurance": dk.insurance(), "reachRarity": dk.reach_rarity(),
		"levels": levels, "effects": effs, "next": nexts,
		"bpPrices": (st["bps"] + st["chs"] + ["bp:Burst:2", "bp:Burst:3", "ch:ch_test_verdant", "nope"]).map(func(it): return dk.bp_price(it)),
		"preCosts": ws.prebuilts().map(func(d): return dk.pre_cost(d)), "itemPrices": _item_names().map(func(n): return dk.item_price(n)),
		"closed": dk.closed(),
		"heroPrices": (_hero_names() + ["Nobody"]).map(func(n): return dk.hero_price(n)), "owns": _hero_names().map(func(n): return dk.owns(n)),
		"unowned": dk.unowned(_hero_names() + ["Nobody"]), "recruitable": dk.recruitable().map(func(h): return h["name"]), "owned": dk.owned_heroes()}


var _heroes_cache := []
func _hero_names() -> Array:
	if _heroes_cache.is_empty():
		for c in roster.from_export:
			if c.get("_src") != "design" and c.get("_src") != "prebuilt" and c.get("cardType") == "hero":
				_heroes_cache.append(str(c["name"]))
	return _heroes_cache


var _items_cache := []
func _item_names() -> Array:
	if _items_cache.is_empty():
		for c in roster.from_export:
			if c.get("_src") != "design" and c.get("_src") != "prebuilt" and (c.get("cardType") == "consumable" or c.get("cardType") == "prototype"):
				_items_cache.append(str(c["name"]))
	return _items_cache


func _dock(c: Dictionary) -> void:
	var a: Array = c["args"]
	var loot := Loot.new(loot_tables, null)
	loot.seed_with(a[0])
	var world := World.new(loot, x.content("world_map"), floors)
	var p := Progress.new(loot, x.content("pools"), x.content("chassis"), x.content("tables"))
	p.state = Progress.tidy(a[2].duplicate(true))
	var dep := Deployment.new(world, p, loot, roster)
	dep.stock = Loot.norm(a[3])
	if Rules.truthy(a[7]):
		dep.s = {"active": true}
	var ws := Workshop.new(p, x.content("tables"), null)
	ws.set_prebuilts(a[6])
	dep.workshop = ws
	var dk := Dock.new(dep, {"dock": a[1]})
	dk.workshop = ws
	dk.fallback_items = false
	dk.state = Dock.tidy(a[4])
	dk.inv = Dock.tidy_inv(a[5])
	dep.dock = dk
	p.card_source = func(): return roster.from_export      # (0.22)
	# (0.22) a card found reaches the dock: held weakly, or the two keep each other alive
	var dk_ref: WeakRef = weakref(dk)
	p.card_sink = func(nm):
		var d = dk_ref.get_ref()
		if d != null:
			d.add_card(str(nm), 1)
	var want: Array = c["result"]
	var good := true
	for i in want.size():
		var op: Array = want[i]["op"]
		var out = null
		steps += 1
		match op[0]:
			"restock": out = dk.restock()
			"stock": out = dk.stock()
			"seeStock": dk.see_stock()
			"buyParts": out = dk.buy_parts(op[1], op[2], op[3], op[4] if op.size() > 4 else null)
			"sellParts": out = dk.sell_parts(op[1], op[2], op[3])
			"buyItem": out = dk.buy_item(op[1])
			"buyCard": out = dk.buy_card(op[1], op[2])
			"sellCard": out = dk.sell_card(op[1], op[2])
			"buyPre": out = dk.buy_pre(op[1], op[2])
			"combine": out = dk.combine(op[1], op[2], op[3])
			"swap": out = dk.swap(op[1], op[2], op[3], op[4])
			"upgrade": out = dk.upgrade(op[1])
			"ended": out = dk.deployment_ended(op[1])
			"recruit": out = dk.recruit(op[1])
			"oldStock":
				if dk.state["stock"] is Dictionary:
					dk.state["stock"].erase("heroes")
					dk.state["stock"].erase("hired")
			"claim": out = dk.claim(op[1])
			"effects":
				out = _effects(dk, ws)
				# (the bounty pay, asked at the Skull Levels the case asked it at)
				var asked: Array = want[i]["out"].get("bountyPay", []) if want[i]["out"] is Dictionary else []
				out["bountyPay"] = asked.map(func(q): return {"kind": q["kind"], "skull": q["skull"], "pay": dk.bounty_pay(str(q["kind"]), q["skull"])})
		var got := {"out": _undated(out), "snap": _snap(dk, dep, p)}
		var exp := {"out": _undated(want[i]["out"]), "snap": want[i]["snap"]}
		if not same(got, exp):
			good = false
			if shown.get("dock", 0) < 3:
				print("   (case seed %s, step %d of %d: %s)" % [str(a[0]), i, want.size(), JSON.stringify(op).left(300)])
				_tally("dock", false, got, exp)
				return
			break
	_tally("dock", good, null, null)
