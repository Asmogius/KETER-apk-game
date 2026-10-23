## The POI Sandbox's model of a floor (0.29), as the Companion's Sandbox has it
## (poi_v19.html): a hexagon of a radius, the tiles placed on it (each may carry
## a colour, 0-5, whose meaning is in colorLabels, and a spawn level), walls on
## the edges between tiles in black or a colour, and symbols stamped on tiles
## (a symbol may be a hazard). The game's POI Sandbox (poi_screen.gd) edits one
## of these, and a floor it saves is a level in the Companion's own shape (v 6).
##
## A floor being edited is a Dictionary: name, district, poiType, level,
## floorSize, notes, rewards, radius, chunk, hexes {Vector2i: {c, lvl}},
## marks {Vector2i: symbol id}, walls {"q,r|q,r": colour id}, symDefs,
## nextDef, colorLabels {int: text}, wallLabels {int: text}, and keep (what
## else the level carried, kept as it came).
class_name PoiModel
extends RefCounted

const NAMES := ["Red", "Orange", "Yellow", "Green", "Blue", "Violet"]
## The walls' colours: black, then the six.
const EDGES := [-1, 0, 1, 2, 3, 4, 5]
const MAX_SYMBOLS := 20
const DISTRICTS := ["", "1 · Threshold Dynamics", "2 · Halcyon Cognition", "3 · Vantage Robotics", "4 · Lazarus Computing",
	"5 · Verdant Biogenics", "6 · Meridian Entropics", "Neutral"]
const POI_TYPES := ["", "Black Lab", "Lab", "Security Armory", "Bunker", "Overrun Hideout", "Unique POI", "Ambush", "Boss", "Chunk", "World Map"]
const SIZES := ["", "Small", "Medium", "Large"]
const CHUNK_ROLES := [["start", "Start"], ["enemy", "Enemy"], ["loot", "Loot"], ["exit", "Exit"], ["filler", "Filler"]]
const CHUNK_SIDES := ["N", "NE", "SE", "S", "SW", "NW"]
## The tile types of the POI rules (KETER_DEFAULTS): colours, wall meanings, and symbols.
const DEFAULT_COLOURS := {0: "Enemy Spawn Tile", 1: "Half Cover Barricade", 2: "Loot Tile", 3: "Player Spawn Tile", 4: "Healing Station", 5: "Full Cover Barricade"}
const DEFAULT_WALLS := {-1: "Solid wall", 0: "Locked Door", 3: "Emergency Exit", 4: "Door / passage"}
const DEFAULT_SYMBOLS := [["HV", "Hive — spawns 1 Swarm monster per turn until disabled"],
	["KY", "Key Tile — opens one Locked Chest or Locked Door, consumed on use"],
	["LC", "Locked Chest — always rewards loot"],
	["CS", "Captive Survivor — rewards top Unit Card of the Roster Deck"],
	["EX", "Emergency Exit — leave the POI early, keeping loot found"]]
## What a level carries that this model reads; the rest is kept as it came.
const READ := ["v", "name", "district", "poiType", "level", "floorSize", "battlefieldSize", "notes", "rewards", "radius", "chunk",
	"hexes", "marks", "walls", "symDefs", "nextDef", "colorLabels", "wallLabels", "saved", "lastEditedBy"]


# ---------------------------------------------------------------- in and out
## A level (as saved) to a floor to edit.
static func from_level(d: Dictionary) -> Dictionary:
	var st := {"name": _s(d.get("name")), "district": _s(d.get("district")), "poiType": _s(d.get("poiType")), "level": _s(d.get("level")),
		"floorSize": _s(d.get("floorSize")), "notes": _s(d.get("notes")), "rewards": _s(d.get("rewards")),
		"radius": clampi(int(Rules.num(d.get("radius"), 8)) if Rules.truthy(d.get("radius")) else 8, 5, 20),
		"chunk": chunk_norm(d["chunk"]) if d.get("chunk") is Dictionary else null,
		"hexes": {}, "marks": {}, "walls": {}, "symDefs": [], "nextDef": 1, "colorLabels": {}, "wallLabels": {}, "keep": {}}
	for pair in d.get("hexes", []) if d.get("hexes") is Array else []:
		if pair is Array and pair.size() >= 1:
			var t = pair[1] if pair.size() > 1 else {}
			st["hexes"][Hex.parse(str(pair[0]))] = (t as Dictionary).duplicate(true) if t is Dictionary else {}
	for pair in d.get("marks", []) if d.get("marks") is Array else []:
		if pair is Array and pair.size() >= 2:
			st["marks"][Hex.parse(str(pair[0]))] = int(pair[1])
	for w in d.get("walls", []) if d.get("walls") is Array else []:
		if w is Array and w.size() >= 1:
			st["walls"][str(w[0])] = int(w[1]) if w.size() > 1 and w[1] != null else -1
		elif w is String:
			st["walls"][w] = -1
	var top := 0
	for sd in d.get("symDefs", []) if d.get("symDefs") is Array else []:
		if sd is Dictionary and sd.has("id"):
			var e: Dictionary = sd.duplicate(true)
			e["id"] = int(sd["id"])
			st["symDefs"].append(e)
			top = maxi(top, int(e["id"]))
	st["nextDef"] = maxi(int(Rules.num(d.get("nextDef"), 1)) if Rules.truthy(d.get("nextDef")) else 1, top + 1)
	for i in 6:
		st["colorLabels"][i] = ""
	for i in EDGES:
		st["wallLabels"][i] = ""
	if d.get("colorLabels") is Dictionary:
		for k in d["colorLabels"]:
			st["colorLabels"][int(k)] = _s(d["colorLabels"][k])
	if d.get("wallLabels") is Dictionary:
		for k in d["wallLabels"]:
			st["wallLabels"][int(k)] = _s(d["wallLabels"][k])
	for k in d:
		if not READ.has(str(k)) and not str(k).begins_with("_"):
			st["keep"][k] = d[k]
	return st


## A floor as it is saved: the Companion's level (v 6).
static func to_level(st: Dictionary) -> Dictionary:
	var d: Dictionary = (st.get("keep", {}) as Dictionary).duplicate(true)
	d["v"] = 6
	for k in ["name", "district", "poiType", "level", "floorSize", "notes", "rewards"]:
		d[k] = str(st.get(k, ""))
	d["battlefieldSize"] = size_of(st)
	d["radius"] = int(st["radius"])
	if str(st.get("poiType", "")) == "Chunk":
		d["chunk"] = chunk_norm(st["chunk"] if st.get("chunk") is Dictionary else {})
	else:
		d.erase("chunk")
	var hx := []
	for h in _sorted(st["hexes"].keys()):
		hx.append([Hex.key(h), (st["hexes"][h] as Dictionary).duplicate(true)])
	d["hexes"] = hx
	var mk := []
	for h in _sorted(st["marks"].keys()):
		mk.append([Hex.key(h), int(st["marks"][h])])
	d["marks"] = mk
	var wk: Array = st["walls"].keys()
	wk.sort()
	d["walls"] = wk.map(func(k): return [k, int(st["walls"][k])])
	d["symDefs"] = (st["symDefs"] as Array).duplicate(true)
	d["nextDef"] = int(st["nextDef"])
	var cl := {}
	for k in st["colorLabels"]:
		cl[str(k)] = str(st["colorLabels"][k])
	d["colorLabels"] = cl
	var wl := {}
	for k in st["wallLabels"]:
		wl[str(k)] = str(st["wallLabels"][k])
	d["wallLabels"] = wl
	d["lastEditedBy"] = "Sandbox"
	if not d.has("createdBy"):
		d["createdBy"] = "Sandbox"
	d["saved"] = Time.get_datetime_string_from_system(true) + "Z"
	return d


## A new floor: an empty hexagon of radius 8, with the KETER defaults.
static func blank(name := "New floor") -> Dictionary:
	var st := from_level({"name": name, "radius": 8})
	apply_defaults(st, true)
	return st


static func chunk_norm(c) -> Dictionary:
	var cd: Dictionary = c if c is Dictionary else {}
	var sides: Array = cd["sides"] if cd.get("sides") is Array else []
	var role := str(cd.get("role", ""))
	var roles: Array = CHUNK_ROLES.map(func(r): return r[0])
	var out_sides := []
	for i in 6:
		out_sides.append(not (i < sides.size() and (sides[i] == false or (sides[i] is float and sides[i] == 0.0) or (sides[i] is int and sides[i] == 0))))
	return {"role": role if roles.has(role) else "filler", "sides": out_sides,
		"skullMin": clampi(int(Rules.num(cd.get("skullMin"), 1)) if Rules.truthy(cd.get("skullMin")) else 1, 1, 6),
		"skullMax": clampi(int(Rules.num(cd.get("skullMax"), 6)) if Rules.truthy(cd.get("skullMax")) else 6, 1, 6)}


## The KETER defaults: every colour, wall and symbol the POI rules name. With
## force, they replace what is there; without, they only fill what is blank.
static func apply_defaults(st: Dictionary, force := false) -> void:
	for k in DEFAULT_COLOURS:
		if force or str(st["colorLabels"].get(k, "")) == "":
			st["colorLabels"][k] = DEFAULT_COLOURS[k]
	for k in DEFAULT_WALLS:
		if force or str(st["wallLabels"].get(k, "")) == "":
			st["wallLabels"][k] = DEFAULT_WALLS[k]
	for sy in DEFAULT_SYMBOLS:
		var has = null
		for d in st["symDefs"]:
			if str(d.get("text", "")) == sy[0]:
				has = d
		if has != null:
			if force or str(has.get("desc", "")) == "":
				has["desc"] = sy[1]
			continue
		if st["symDefs"].size() >= MAX_SYMBOLS:
			continue
		st["symDefs"].append({"id": int(st["nextDef"]), "text": sy[0], "desc": sy[1]})
		st["nextDef"] = int(st["nextDef"]) + 1


static func _s(v) -> String:
	return "" if v == null else str(v)


static func _sorted(hs: Array) -> Array:
	var o := hs.duplicate()
	o.sort_custom(func(a, b): return a.y < b.y or (a.y == b.y and a.x < b.x))
	return o


# ---------------------------------------------------------------- the map
static func in_map(st: Dictionary, h: Vector2i) -> bool:
	return Hex.distance(h, Vector2i.ZERO) <= int(st["radius"])


## Every tile of the hexagon.
static func cells(st: Dictionary) -> Array:
	var n := int(st["radius"])
	var out := []
	for r in range(-n, n + 1):
		for q in range(-n, n + 1):
			if absi(q + r) <= n:
				out.append(Vector2i(q, r))
	return out


## The edge between two tiles, as the Companion keys it.
static func wall_key(a: Vector2i, b: Vector2i) -> String:
	var ka := Hex.key(a)
	var kb := Hex.key(b)
	return ka + "|" + kb if ka < kb else kb + "|" + ka


static func wall_ends(k: String) -> Array:
	var p := k.split("|")
	return [Hex.parse(p[0]), Hex.parse(p[1])] if p.size() == 2 else []


## Grows or shrinks the hexagon; shrinking drops what falls outside it.
static func set_radius(st: Dictionary, n: int) -> int:
	st["radius"] = clampi(n, 5, 20)
	var lost := 0
	for h in st["hexes"].keys():
		if not in_map(st, h):
			st["hexes"].erase(h)
			lost += 1
	for h in st["marks"].keys():
		if not in_map(st, h):
			st["marks"].erase(h)
	for k in st["walls"].keys():
		var e := wall_ends(k)
		if e.is_empty() or not (in_map(st, e[0]) or in_map(st, e[1])):
			st["walls"].erase(k)
	return lost


# ---------------------------------------------------------------- the tools
## Places a plain tile (one already there is left as it is).
static func place(st: Dictionary, h: Vector2i) -> bool:
	if not in_map(st, h) or st["hexes"].has(h):
		return false
	st["hexes"][h] = {}
	return true


## Removes a tile, with its symbol and its walls.
static func erase(st: Dictionary, h: Vector2i) -> bool:
	var did: bool = st["hexes"].has(h) or st["marks"].has(h)
	st["hexes"].erase(h)
	st["marks"].erase(h)
	for n in Hex.neighbours(h):
		var k := wall_key(h, n)
		if st["walls"].has(k):
			st["walls"].erase(k)
			did = true
	return did


## Paints a tile a colour (0-5), placing it if it isn't there; -1 makes it plain.
static func paint(st: Dictionary, h: Vector2i, c: int) -> bool:
	if not in_map(st, h):
		return false
	if not st["hexes"].has(h):
		st["hexes"][h] = {}
	var t: Dictionary = st["hexes"][h]
	if c < 0:
		var had := t.has("c")
		t.erase("c")
		t.erase("lvl")
		return had
	if t.get("c") != null and int(t["c"]) == c:
		return false
	t["c"] = c
	if not is_enemy_spawn(st, h):
		t.erase("lvl")
	return true


## Stamps a symbol on a tile (or, with on false, takes it off).
static func mark(st: Dictionary, h: Vector2i, id: int, on := true) -> bool:
	if not in_map(st, h):
		return false
	if not on:
		if st["marks"].get(h, -999) == id:
			st["marks"].erase(h)
			return true
		return false
	if st["marks"].get(h, -999) == id:
		return false
	if not st["hexes"].has(h):
		st["hexes"][h] = {}
	st["marks"][h] = id
	return true


## A wall in a colour on the edge between two tiles (or, with on false, none).
static func wall(st: Dictionary, a: Vector2i, b: Vector2i, c: int, on := true) -> bool:
	if Hex.distance(a, b) != 1 or not (in_map(st, a) or in_map(st, b)):
		return false
	var k := wall_key(a, b)
	if not on:
		if st["walls"].has(k):
			st["walls"].erase(k)
			return true
		return false
	if st["walls"].get(k, -999) == c:
		return false
	st["walls"][k] = c
	return true


static func is_enemy_spawn(st: Dictionary, h: Vector2i) -> bool:
	var t = st["hexes"].get(h)
	if not (t is Dictionary) or t.get("c") == null:
		return false
	return FloorData.label_kind(str(st["colorLabels"].get(int(t["c"]), ""))) == "spawn-enemy"


static func is_world_map(st: Dictionary) -> bool:
	return str(st.get("poiType", "")) == "World Map"


## The Spawn level tool: an Enemy Spawn tile's Skull Level a step up, 6 back to 1
## (on a World Map any tile's, and a seventh tap clears it). Returns the new
## level, 0 when cleared, or -1 when the tile can't carry one.
static func step_level(st: Dictionary, h: Vector2i) -> int:
	var wm := is_world_map(st)
	if not st["hexes"].has(h) or not (wm or is_enemy_spawn(st, h)):
		return -1
	var t: Dictionary = st["hexes"][h]
	var lv := int(Rules.num(t.get("lvl"), 0)) if Rules.truthy(t.get("lvl")) else 0
	if wm and lv >= 6:
		t.erase("lvl")
		return 0
	lv = 1 if lv >= 6 else lv + 1
	t["lvl"] = lv
	return lv


## Places every tile of the hexagon.
static func fill_all(st: Dictionary) -> int:
	var n := 0
	for h in cells(st):
		if place(st, h):
			n += 1
	return n


# ---------------------------------------------------------------- shapes and mirroring
## The tiles on a straight run from a to b.
static func line(a: Vector2i, b: Vector2i) -> Array:
	var n := Hex.distance(a, b)
	if n == 0:
		return [a]
	var out := []
	for i in n + 1:
		var t := float(i) / n
		out.append(Hex.round_cube(lerpf(a.x + 1e-6, b.x + 1e-6, t), lerpf(a.y + 2e-6, b.y + 2e-6, t)))
	return out


## The tiles of a hexagon about c out to d: all of it, or its outline only.
static func hex_shape(c: Vector2i, d: Vector2i, fill := true) -> Array:
	var n := Hex.distance(c, d)
	var out := []
	for r in range(-n, n + 1):
		for q in range(-n, n + 1):
			var h := Vector2i(q, r)
			var k := Hex.distance(h, Vector2i.ZERO)
			if k <= n and (fill or k == n):
				out.append(c + h)
	return out


## A tile's reflection in a mirror line through the pivot, at one of three
## angles (the three ways a hex grid folds onto itself through a tile).
static func reflect(h: Vector2i, pivot: Vector2i, axis: int) -> Vector2i:
	var d := h - pivot
	var s := -d.x - d.y
	match axis % 3:
		0:
			return pivot + Vector2i(d.y, d.x)
		1:
			return pivot + Vector2i(s, d.y)
		_:
			return pivot + Vector2i(d.x, s)


## A tile and its reflection (one, if it lies on the line); just the tile without a mirror.
static func images(h: Vector2i, mirror) -> Array:
	if not (mirror is Dictionary):
		return [h]
	var m := reflect(h, mirror["pivot"], int(mirror["axis"]))
	return [h] if m == h else [h, m]


# ---------------------------------------------------------------- symbols
static func sym(st: Dictionary, id: int) -> Dictionary:
	for d in st["symDefs"]:
		if int(d["id"]) == id:
			return d
	return {}


## A new symbol (up to three characters). Returns its id, or -1.
static func add_sym(st: Dictionary, text: String, desc := "") -> int:
	text = text.strip_edges().substr(0, 3)
	if text == "" or st["symDefs"].size() >= MAX_SYMBOLS:
		return -1
	var id := int(st["nextDef"])
	st["symDefs"].append({"id": id, "text": text, "desc": desc})
	st["nextDef"] = id + 1
	return id


## Removes a symbol, and every tile it was stamped on loses it. Returns how many.
static func remove_sym(st: Dictionary, id: int) -> int:
	var n := 0
	for h in st["marks"].keys():
		if int(st["marks"][h]) == id:
			st["marks"].erase(h)
			n += 1
	st["symDefs"] = (st["symDefs"] as Array).filter(func(d): return int(d["id"]) != id)
	return n


static func is_hazard(d: Dictionary) -> bool:
	return d.get("hazard") is Dictionary and (Rules.truthy(d["hazard"].get("keyword")) or Rules.truthy(d["hazard"].get("damage")))


## "2 damage and Poisoned", or "".
static func hazard_line(d: Dictionary) -> String:
	if not is_hazard(d):
		return ""
	var bits := []
	if Rules.truthy(d["hazard"].get("damage")):
		bits.append("%d damage" % int(d["hazard"]["damage"]))
	if Rules.truthy(d["hazard"].get("keyword")):
		bits.append(str(d["hazard"]["keyword"]))
	return " and ".join(bits)


## Sets what a symbol does as a hazard; nothing (0 damage, no keyword) makes it a plain symbol.
static func set_hazard(d: Dictionary, damage: int, keyword: String) -> void:
	if damage <= 0 and keyword == "":
		d.erase("hazard")
	else:
		d["hazard"] = {"keyword": keyword, "damage": maxi(0, damage), "when": "both"}


## A symbol's text as shown: a drawn pictogram ("@fire") by its name.
static func sym_text(d: Dictionary) -> String:
	var t := str(d.get("text", ""))
	return t.substr(1) if t.begins_with("@") else t


# ---------------------------------------------------------------- what it adds up to
## The size the floor takes: the one chosen, else the one its tile count suggests.
static func size_of(st: Dictionary) -> String:
	if str(st.get("floorSize", "")) != "":
		return str(st["floorSize"])
	var n: int = st["hexes"].size()
	if n == 0:
		return ""
	return "Small" if n < 100 else ("Medium" if n <= 250 else "Large")


## How many Heroes a floor of this size admits.
static func heroes_of(size: String) -> int:
	return {"Small": 1, "Medium": 2, "Large": 3}.get(size, 1)


static func tiles_of(st: Dictionary, kind: String) -> Array:
	var out := []
	for h in st["hexes"]:
		var t: Dictionary = st["hexes"][h]
		if t.get("c") != null and FloorData.label_kind(str(st["colorLabels"].get(int(t["c"]), ""))) == kind:
			out.append(h)
	return out


## The tiles a Unit can walk to from the player spawns, walls in the way.
static func reachable(st: Dictionary) -> Dictionary:
	var starts := tiles_of(st, "spawn-ally")
	var seen := {}
	for h in starts:
		seen[h] = true
	var queue := starts.duplicate()
	var head := 0
	while head < queue.size():
		var h: Vector2i = queue[head]
		head += 1
		for n in Hex.neighbours(h):
			if seen.has(n) or not st["hexes"].has(n) or st["walls"].has(wall_key(h, n)):
				continue
			seen[n] = true
			queue.append(n)
	return seen


## What the Sandbox flags about a floor: [level, text] with level "red"
## (unplayable, or a name it can't be kept by), "amber" or "grey".
static func pings(st: Dictionary, other_names: Array = []) -> Array:
	var out := []
	var nm := str(st.get("name", "")).strip_edges()
	if nm == "":
		out.append(["red", "It needs a name."])
	elif other_names.has(nm):
		out.append(["red", "Another floor is called %s." % nm])
	if st["hexes"].is_empty():
		out.append(["red", "It has no tiles: place some."])
		return out
	var t := str(st.get("poiType", ""))
	if t == "World Map":
		out.append(["grey", "A World Map level: the World Map's, not a floor to fight on."])
		return out
	var players := tiles_of(st, "spawn-ally").size()
	var enemies := tiles_of(st, "spawn-enemy").size()
	if t == "Chunk":
		var outside := 0
		for h in st["hexes"]:
			if Hex.distance(h, Vector2i.ZERO) > 3:
				outside += 1
		if outside > 0:
			out.append(["amber", "%d tile%s lie outside the chunk's radius-3 hexagon and are left out." % [outside, "" if outside == 1 else "s"]])
		out.append(["grey", "A chunk: a piece of a battlefield the World Map grows, not a floor to fight on."])
		return out
	if players == 0:
		out.append(["red", "No Player Spawn tile: no Hero has anywhere to start."])
	elif players < heroes_of(size_of(st)):
		out.append(["amber", "%s admits %d Heroes but has %d Player Spawn tile%s." % [size_of(st), heroes_of(size_of(st)), players, "" if players == 1 else "s"]])
	if enemies == 0:
		out.append(["amber", "No Enemy Spawn tile: no wave has anywhere to arrive."])
	if players > 0:
		var r := reachable(st).size()
		var n: int = st["hexes"].size()
		if r < n:
			out.append(["amber", "%d of %d tiles can't be reached from the player spawns." % [n - r, n]])
	if str(st.get("level", "")) == "":
		out.append(["grey", "No Skull Level: it takes its Enemy Spawn tiles' lowest."])
	if str(st.get("district", "")) == "":
		out.append(["grey", "No District."])
	return out


static func blocking(st: Dictionary, other_names: Array = []) -> Array:
	var out := []
	var nm := str(st.get("name", "")).strip_edges()
	if nm == "":
		out.append("It needs a name.")
	elif other_names.has(nm):
		out.append("Another floor is called %s." % nm)
	if st["hexes"].is_empty():
		out.append("It has no tiles.")
	return out


## One line: tiles, size, spawns, what can be reached.
static func readout(st: Dictionary) -> String:
	var n: int = st["hexes"].size()
	var bits := ["%d tile%s" % [n, "" if n == 1 else "s"]]
	var sz := size_of(st)
	if sz != "":
		bits.append(sz + ("" if str(st.get("floorSize", "")) != "" else " (auto)"))
	bits.append("%d player / %d enemy spawn%s" % [tiles_of(st, "spawn-ally").size(), tiles_of(st, "spawn-enemy").size(), ""])
	bits.append("%d wall%s" % [st["walls"].size(), "" if st["walls"].size() == 1 else "s"])
	if tiles_of(st, "spawn-ally").size() > 0 and n > 0:
		bits.append("%d%% reachable" % int(round(100.0 * reachable(st).size() / n)))
	return " · ".join(bits)


# ---------------------------------------------------------------- undo
## What undo keeps: the map and its symbols (the floor's details are not undone).
static func snap(st: Dictionary) -> Dictionary:
	return {"hexes": st["hexes"].duplicate(true), "marks": st["marks"].duplicate(), "walls": st["walls"].duplicate(),
		"symDefs": (st["symDefs"] as Array).duplicate(true), "nextDef": st["nextDef"], "radius": st["radius"]}


static func unsnap(st: Dictionary, s: Dictionary) -> void:
	for k in s:
		st[k] = s[k].duplicate(true) if (s[k] is Dictionary or s[k] is Array) else s[k]
