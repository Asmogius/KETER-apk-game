## The proof that the game's World Map is the Companion's: cases made by
## running world.js, deploy.js and progress.js as they are
## (make_world_cases.js, in the Companion's sources) on the export's own map,
## floors, pools and chassis, each replayed here and compared: every tile,
## ways across the map and their risk, the floors a fight is drawn from,
## Events, what can drop and what a drop is called, and whole deployments
## walked step by step, roll for roll, from the dock and back to it.
##   godot --headless --path . --script res://tests/world_diff.gd
extends SceneTree

const CASES := "res://tests/fixtures/world_cases.json"
const EXPORT := "res://tests/fixtures/export.zip"
var by_fn := {}
var shown := {}
var x: KeterExport
var roster: Roster
var floors: Array[FloorData] = []
var loot_tables = null


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(CASES))
	if not (data is Dictionary):
		print("FAIL no cases at " + CASES)
		print("\nWORLD MATCH 0  DIFFER 1")
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
		_case(c)
	var ok := 0
	var bad := 0
	var names := by_fn.keys()
	names.sort()
	for fn in names:
		ok += by_fn[fn][0]
		bad += by_fn[fn][1]
		print(("PASS " if by_fn[fn][1] == 0 else "FAIL ") + "%s: %d of %d match" % [fn, by_fn[fn][0], by_fn[fn][0] + by_fn[fn][1]])
	print("(from %s; %s, %d tiles, %d floors)" % [data.get("made", "?"), data.get("map", "?"), data.get("tiles", 0), data.get("floors", 0)])
	print("\nWORLD MATCH %d  DIFFER %d" % [ok, bad])
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


# ---------------------------------------------------------------- what is compared
func _world(seed = null) -> World:
	return World.new(Loot.new(loot_tables, seed), x.content("world_map"), floors)


func _progress(state, stream: Loot = null) -> Progress:
	var p := Progress.new(stream if stream != null else Loot.new(loot_tables, 0), x.content("pools"), x.content("chassis"), x.content("tables"))
	p.state = Progress.tidy(state.duplicate(true) if state is Dictionary else null)
	p.card_source = func(): return roster.from_export      # (0.22) the cards that can be found
	p.card_sink = func(_nm): pass                           # and where one goes (the dock, when there is one)
	return p


func _content(c) -> Variant:
	if c == null:
		return null
	return {"kind": c["kind"], "name": c["name"], "type": c.get("type"), "unique": c["unique"].get("id") if c.get("unique") is Dictionary else null}


func _keys_hash(d: Dictionary) -> int:
	var ks: Array = d.keys().map(func(k): return str(k))
	ks.sort()
	return World.hash_str(";".join(ks))


func _snap(dep: Deployment) -> Dictionary:
	var s = dep.s
	var w := dep.world
	var d = null
	if s is Dictionary:
		var a = s.get("activity")
		d = {"active": Rules.truthy(s.get("active")), "n": s["n"], "pos": s["pos"], "steps": s["steps"], "fights": s["fights"], "maxSkull": s.get("maxSkull", 0), "haul": Loot.norm(s["haul"]), "items": s["items"],
			"activity": {"kind": a["kind"], "tile": a["tile"], "district": a["district"], "skull": a["skull"], "floors": a["floors"], "index": a["index"], "name": a["name"], "type": a["type"],
				"unique": a.get("unique"), "tileAmbush": Rules.truthy(a.get("tileAmbush")), "fromEvent": Rules.truthy(a.get("fromEvent"))} if a is Dictionary else null,
			"heroesOut": s["heroesOut"], "cons": s["pack"]["cons"], "kills": s["kills"], "log": s["log"].map(func(l): return l["text"]), "result": s.get("result")}
	var named := func(m) -> Dictionary:
		var o := {}
		for id in (m if m is Dictionary else {}):
			var dz = dep.workshop.get_design(id) if dep.workshop != null else null
			o[str(dz["name"]) if dz != null else str(id)] = m[id]
		return o
	var k: Dictionary = dep.dock.state if dep.dock != null else Dock.blank()
	var kst = k["stock"].duplicate(true) if k["stock"] is Dictionary else null
	if kst is Dictionary:
		kst.erase("made")
	return {"dep": d,
		"out": {"copies": named.call(s.get("copies", {})), "lost": s["lost"], "paid": s.get("paid"), "pre": named.call(s.get("pre", {})), "pack": s.get("pack"), "cards": s.get("cards", {})} if s is Dictionary else null,
		"dock": {"reach": k["reach"], "restocks": k["restocks"], "stock": kst, "bounties": k["bounties"], "log": k["log"].map(func(l): return l["text"]), "heroes": k["heroes"]},
		"inv": dep.dock.inv if dep.dock != null else {"cards": {}, "pre": {}},
		"world": {"known": w.state["known"].size(), "knownHash": _keys_hash(w.state["known"]), "stood": _keys_hash(w.state["stood"]), "cleared": w.state["cleared"], "completed": w.state["completed"]},
		"prog": {"bp": dep.progress.state["bp"], "ch": dep.progress.state["ch"], "named": dep.progress.state["named"]}, "stock": Loot.norm(dep.stock),
		"history": dep.history.map(func(h): return {"n": h["n"], "result": h["result"], "team": h["team"], "steps": h["steps"], "fights": h["fights"], "haul": Loot.norm(h["haul"]), "items": h["items"], "out": h["out"]})}


func _spec(sp) -> Variant:
	if sp == null:
		return null
	return {"floor": sp["floor"], "district": sp["district"], "skull": sp["skull"], "kind": sp["kind"], "index": sp["index"], "count": sp["count"], "name": sp["name"], "type": sp["type"], "tile": sp["tile"], "n": sp["n"], "pending": sp["pending"]}


func _case(c: Dictionary) -> void:
	var fn: String = c["fn"]
	var A: Array = c["args"]
	var want = c["result"]
	match fn:
		"hash":
			_check(fn, World.hash_str(A[0]), want)
		"mapFacts":
			var w := _world()
			_check(fn, {"dock": w.dock(), "radius": w.radius(), "tiles": w.map["tiles"].size(), "exists": w.exists()}, want)
		"tile":
			var w := _world()
			var k: String = A[0]
			_check(fn, {"open": w.is_open(k), "skull": w.skull_of(k), "district": w.district_of(k), "ambush": w.ambush_chance(k), "content": _content(w.content_at(k)),
				"poiType": w.poi_type_of(k) if w.is_open(k) else null, "neighbours": World.neighbours(k), "dist": World.dist(k, w.dock())}, want)
		"path":
			var w := _world()
			var p := w.path(A[0], A[1])
			# world.js says null for "no way", and so for a tile that isn't one
			_check(fn, {"path": p if not p.is_empty() else null, "risk": w.path_risk(p) if not p.is_empty() else null}, want)
		"floors":
			_check(fn, _world().floors, want)
		"floorCount":
			var w := _world()
			_check(fn, [1, 2, 3, 4, 5, 6, 0, 9].map(func(s): return w.floor_count(s)), want)
		"cores":
			# (0.41) the Cores at other Core Skull Levels
			var w := _world()
			w.tables["coreSkulls"] = A[0]
			_check(fn, w.cores(), want)
		"draw":
			var w := _world(A[0])
			_check(fn, w.draw_floors(A[1], A[2], A[3], A[4]), want)
		"event":
			var w := _world()
			if Rules.truthy(A[1]):
				w.state["cleared"][A[0]] = A[1]
			var ev = w.event_for(A[0])
			_check(fn, ev.get("id") if ev is Dictionary else null, want)
		"blueprint":
			_check(fn, _progress(null).blueprint_of(A[0]), want)
		"eligible":
			_check(fn, _progress(A[0]).eligible(A[1], A[2]), want)
		"itemName":
			_check(fn, _progress(A[0]).item_name(A[1], A[2]), want)
		"grant":
			var p := _progress(A[0])
			var got: Array = A[1].map(func(it): return p.grant(it))
			_check(fn, {"got": got, "after": {"bp": p.state["bp"], "ch": p.state["ch"], "named": p.state["named"]}}, want)
		"rollItems":
			var p := _progress(A[0], Loot.new(loot_tables, A[1]))
			_check(fn, p.roll_items(A[2], A[3]), want)
		"cardPool":
			_check(fn, _progress(null).card_pool(A[0], A[1]), want)
		"rollRewardItems":
			var p := _progress(A[0], Loot.new(loot_tables, A[1]))
			_check(fn, p.roll_reward_items(A[2], A[3]), want)
		"deployment":
			_deployment(A, want)
		"plan":
			var dep := _dep(Loot.new(loot_tables, 1), A[1], A[0], A[2], A[4] if A.size() > 4 else null, A[5] if A.size() > 5 else null, [])
			_check(fn, _plan(dep, _team(A[3])), want)
		_:
			_tally("unknown:" + fn, false, null, null)


func _check(fn: String, got, want) -> void:
	_tally(fn, same(got, want), got, want)


## A whole case: one to four deployments, one after another, on one map.
## A deployment with the case's designs, over a stream and a progress.
func _dep(stream: Loot, state, designs, stock0, dock0 = null, inv0 = null, pre_cards = []) -> Deployment:
	var w := World.new(stream, x.content("world_map"), floors)
	var p := _progress(state, stream)
	var dep := Deployment.new(w, p, stream, roster)
	var ws := Workshop.new(p, x.content("tables"), Skins.new(x.content("skins"), p.chassis))
	for id in (designs if designs is Dictionary else {}):
		ws.designs[str(id)] = designs[id].duplicate(true)
	ws.is_out = dep.locked_design
	dep.workshop = ws
	ws.set_prebuilts(pre_cards if pre_cards is Array else [])
	roster.set_designs(ws.cards() + (pre_cards if pre_cards is Array else []))
	if stock0 is Dictionary:
		dep.stock = Loot.norm(stock0)
	# 0.10: the dock, as the case has it (dock.js's own Exchange list: none ticked, none carried)
	var dk := Dock.new(dep, x.content("tables"))
	dk.workshop = ws
	dk.fallback_items = false
	dk.state = Dock.tidy(dock0)
	dk.inv = Dock.tidy_inv(inv0)
	dep.dock = dk
	# (0.22) a card found reaches the dock: held weakly, or the two keep each other alive
	var dk_ref: WeakRef = weakref(dk)
	p.card_sink = func(nm):
		var d = dk_ref.get_ref()
		if d != null:
			d.add_card(str(nm), 1)
	_keep.append(dk)
	return dep


var _keep := []       # (the docks of the cases: the deployment holds its dock weakly the other way)


func _dock_out(o) -> Variant:
	if not (o is Dictionary):
		return null
	return {"reach": o.get("reach"), "bounties": (o.get("bounties", []) as Array).map(func(b): return {"name": b["name"], "bag": Loot.norm(b["bag"])}),
		"insured": Loot.norm(o["insured"]) if o.get("insured") != null else null, "restocked": Rules.truthy(o.get("restocked")), "lostHeroes": o.get("lostHeroes")}


func _team(o: Dictionary) -> Dictionary:
	var t: Dictionary = StrikeTeams.blank(o["name"])
	t["level"] = o["level"]
	t["heroes"] = o["heroes"].duplicate()
	t["consumables"] = o["consumables"].duplicate()
	t["deck"] = o.get("deck", {}).duplicate()
	t["actions"] = (o["actions"] as Dictionary).duplicate(true) if o.get("actions") is Dictionary else {}
	t["pouch"] = (o["pouch"] as Dictionary).duplicate() if o.get("pouch") is Dictionary else {}
	return t


func _plan(dep: Deployment, t: Dictionary, pack = null) -> Dictionary:
	var p := dep.plan(t, pack)
	return {"ok": p["ok"], "fits": p["fits"], "afford": p["afford"], "reasons": p["reasons"], "heroes": p["heroes"],
		"lines": p["lines"].map(func(l): return {"name": l["name"], "copies": l["copies"], "free": l["free"], "each": l["each"], "cost": l["cost"], "starter": l["starter"]}),
		"parts": p["parts"], "other": p["other"], "busy": p["busy"], "need": p["need"], "craft": p["craft"], "craftShards": p["craftShards"], "craftParts": p["craftParts"]}


func _deployment(A: Array, want: Array) -> void:
	var stream := Loot.new(loot_tables, A[0])
	var dep := _dep(stream, A[1], A[3] if A.size() > 3 else null, A[4] if A.size() > 4 else null, A[5] if A.size() > 5 else null, A[6] if A.size() > 6 else null, A[7] if A.size() > 7 else [])
	var got := []
	for op in A[2]:
		var out = null
		match op[0]:
			"start":
				var t := _team(op[1])
				var pack = op[2] if op.size() > 2 else null
				var pl := _plan(dep, t, pack)
				var r := dep.start(t, pack)
				out = {"plan": pl, "ok": r["ok"]}
			"give":
				for nm in op[1].get("cards", {}):
					dep.dock.add_card(str(nm), int(op[1]["cards"][nm]))
				for id in op[1].get("pre", {}):
					dep.dock.inv["pre"][str(id)] = int(dep.dock.inv["pre"].get(str(id), 0)) + int(op[1]["pre"][id])
			"step":
				var r := dep.step_to(op[1])
				out = {"moved": r["moved"], "why": r.get("why"), "pos": r.get("pos"), "home": Rules.truthy(r.get("home")),
					"content": {"kind": r["content"]["kind"], "name": r["content"]["name"]} if r.get("content") is Dictionary else null,
					"ambush": Rules.truthy(r.get("ambush")), "tileAmbush": Rules.truthy(r.get("tileAmbush"))}
			"ambush":
				out = _spec(dep.ambush(op[1], {"tileAmbush": op[2]}))
			"enter":
				out = _spec(dep.enter_poi(op[1]))
			"fight":
				var o := dep.fight_over(op[1])
				var wiped: bool = o.get("next") == "wipe"
				out = {"next": o.get("next"), "kind": null if wiped else o.get("kind"), "name": null if wiped else o.get("name"), "gained": Loot.norm(o["gained"]) if o.get("gained") != null else null, "items": o.get("items"),
					"escaped": Rules.truthy(o.get("escaped")), "floor": o.get("floor"), "count": o.get("count"), "poiDone": Rules.truthy(o.get("poiDone")),
					"final": {"bag": Loot.norm(o["final"]["bag"]), "items": o["final"]["items"]} if o.get("final") is Dictionary else null, "reserves": o.get("reserves"),
					"lostHaul": Loot.norm(o["lostHaul"]) if o.get("lostHaul") != null else null, "lostItems": o.get("lostItems"), "dock": _dock_out(o.get("dock")) if wiped else null}
			"cache":
				var r = dep.open_cache(op[1])
				out = {"bag": Loot.norm(r["bag"]), "items": r["items"]} if r is Dictionary else null
			"choose":
				var o = dep.choose(op[1], op[2])
				out = {"event": o["event"].get("id"), "label": o["choice"].get("label"), "check": o["check"], "roll": o["roll"], "won": o["won"], "text": o["text"], "got": Loot.norm(o["got"]), "items": o["items"],
					"lost": Loot.norm(o["lost"]) if o["lost"] != null else null, "fight": o["fight"], "spec": _spec(o.get("spec"))} if o is Dictionary else null
			"home":
				var h := dep.home()
				out = {"ok": h["ok"], "why": h.get("why"), "haul": Loot.norm(h["haul"]) if h.get("haul") != null else null, "items": h.get("items"), "n": h.get("n"), "dock": _dock_out(h.get("dock"))}
			"withdraw":
				var r := dep.withdraw()
				out = {"ok": r["ok"], "kind": r.get("kind"), "name": r.get("name")}
			"wipe":
				var wi := dep.wipe()
				out = {"ok": wi["ok"], "lostHaul": Loot.norm(wi["lostHaul"]), "lostItems": wi["lostItems"], "n": wi["n"], "dock": _dock_out(wi.get("dock")), "lostPack": wi.get("lostPack"), "lostCards": wi.get("lostCards", {})}
		got.append({"out": out, "snap": _snap(dep)}.duplicate(true))      # as things stood then, not as they end
	# told step by step, so a difference is found where it starts
	var good := got.size() == want.size()
	var first := -1
	for i in mini(got.size(), want.size()):
		if not same(got[i], want[i]):
			good = false
			first = i
			break
	if good:
		_tally("deployment", true, null, null)
	else:
		_tally("deployment", false, {"step": first, "op": A[2][first] if first >= 0 else null, "got": got[first] if first >= 0 else got.size()}, {"step": first, "op": A[2][first] if first >= 0 else null, "got": want[first] if first >= 0 else want.size()})
