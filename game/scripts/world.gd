## The World Map. (The Companion's world.js, less its map maker and editors.)
##
## The colony as a hex map: the dock at the centre, six District wedges around
## it, Skull Level rising with distance from the dock. About one tile in seven
## is collapsed structure, but every open tile can be reached.
##
## Tiles hold POIs (a run of floors), Ambushes (a fight sprung on stepping
## there), Caches (loot, no fight) and Events (a short situation with a
## choice). The layout, Districts and Skull rings always show; what a tile
## holds shows once the Strike Team has stood next to it, and stays known. A
## cleared tile comes back after a few deployments.
##
## The map, its tables, its Events and its Unique POIs come in the export
## (content/world_map.json). What you have seen and cleared is the game's own.
##
## Proved to answer as world.js answers (tests/world_diff.gd).
class_name World
extends RefCounted

## The six neighbours, in world.js's order (the order a path is searched in).
const DIRS := [[1, 0], [1, -1], [0, -1], [-1, 0], [-1, 1], [0, 1]]
const DISTRICT_NAMES := {"1": "Threshold Dynamics", "2": "Halcyon Cognition", "3": "Vantage Robotics", "4": "Lazarus Computing", "5": "Verdant Biogenics", "6": "Meridian Entropics"}
const DCOL := {"1": "#a98ef0", "2": "#ef7fbe", "3": "#f0a457", "4": "#ef8175", "5": "#6fd189", "6": "#56c6da", "": "#9fb3bd"}
const KIND_LABEL := {"poi": "POI", "ambush": "Ambush", "cache": "Cache", "event": "Event", "dock": "The dock", "unique": "Unique POI"}
const POI_TYPES := ["Lab", "Security Armory", "Bunker", "Overrun Hideout"]
const DEFAULTS := {"v": 1, "radius": 18, "ringsPerSkull": 3, "blocked": 15,
	"density": {"poi": 5, "ambush": 4, "cache": 5, "event": 4},
	"ambushStep": 5, "floorsBySkull": [1, 1, 2, 2, 3, 3], "respawn": 3, "starterFree": 4,
	"cache": {"shards": 3, "n": 2, "bonus": 0, "bp": 15, "card": 20},
	"poi": {"shards": 10, "n": 3, "bonus": 1, "bp": 35, "card": 30}}

var map := {}                 # {seed, radius, name, dock, tiles: {"q,r": {d, c, s, t}}}
var tables := {}
var events: Array = []
var uniques: Array = []
var floors: Array = []        # [{key, name, district, skull, type, size, test, tiles}], in the export's order
var chunks: Array = []        # (0.20) the battlefield chunks among the export's floors, as the Sandbox saves them
## What you know of it: {known, stood, cleared: {tile: deployment number}, completed}.
## It is the Campaign's to save; this class only reads and changes it.
var state := {"known": {}, "stood": {}, "cleared": {}, "completed": 0}
var loot: Loot                # the stream every roll comes from


## content: content/world_map.json out of the export. floor_list: its floors.
func _init(stream: Loot, content = null, floor_list: Array = []) -> void:
	loot = stream if stream != null else Loot.new()
	var c: Dictionary = Rules.ints(content) if content is Dictionary else {}
	map = c["map"] if c.get("map") is Dictionary else {}
	if not (map.get("tiles") is Dictionary):
		map["tiles"] = {}
	if not Rules.truthy(map.get("dock")):
		map["dock"] = "0,0"
	tables = DEFAULTS.duplicate(true)
	if c.get("tables") is Dictionary:
		_merge(tables, c["tables"])
	events = c["events"] if c.get("events") is Array else []
	uniques = c["uniques"] if c.get("uniques") is Array else []
	for f in floor_list:
		var raw: Dictionary = f.raw if f is FloorData else (f if f is Dictionary else {})
		if raw.is_empty() or str(raw.get("poiType") if raw.get("poiType") != null else "") == "World Map":
			continue
		if not (raw.get("hexes") is Array) or raw["hexes"].is_empty():
			continue
		if ChunkGen.is_chunk(raw):
			chunks.append(raw)
			continue
		var name := str(raw["name"]) if Rules.truthy(raw.get("name")) else "Untitled floor"
		var size = raw.get("battlefieldSize") if Rules.truthy(raw.get("battlefieldSize")) else raw.get("floorSize")
		floors.append({"key": name, "name": name, "district": district_num(raw.get("district")), "skull": floor_skull(raw),
			"type": str(raw["poiType"]) if Rules.truthy(raw.get("poiType")) else "", "size": str(size if Rules.truthy(size) else "").to_lower(),
			"test": Rules.truthy(raw.get("testMap")), "tiles": raw["hexes"].size()})


static func _merge(into: Dictionary, from: Dictionary) -> void:
	for k in from:
		if into.get(k) is Dictionary and from[k] is Dictionary:
			_merge(into[k], from[k])
		else:
			into[k] = from[k]


func exists() -> bool:
	return not map["tiles"].is_empty()


static func blank_state() -> Dictionary:
	return {"known": {}, "stood": {}, "cleared": {}, "completed": 0}


static func tidy(s) -> Dictionary:
	var out := blank_state()
	if s is Dictionary:
		for k in ["known", "stood", "cleared"]:
			if s.get(k) is Dictionary:
				out[k] = s[k]
		var n = Rules.num(s.get("completed"), 0)
		out["completed"] = int(n) if Rules.truthy(n) else 0
	return out


## What tells one map from another: a new export with a different map starts
## exploration again.
func identity() -> String:
	return "%s|%s|%d" % [str(map.get("seed")), str(map.get("name")), map["tiles"].size()]


# ---------------------------------------------------------------- hex geometry
static func key(q: int, r: int) -> String:
	return "%d,%d" % [q, r]


static func parse(k) -> Vector2i:
	return Hex.parse(str(k))


static func dist(a, b) -> int:
	return Hex.distance(parse(a) if a is String else a, parse(b) if b is String else b)


static func neighbours(k) -> Array:
	var a := parse(k)
	var out := []
	for d in DIRS:
		out.append(key(a.x + d[0], a.y + d[1]))
	return out


## A number as JavaScript's unary plus reads one, with 0 for anything that isn't.
static func number(v) -> float:
	if v is int:
		return float(v)
	if v is float:
		return 0.0 if is_nan(v) else v
	if v is bool:
		return 1.0 if v else 0.0
	if v is String or v is StringName:
		var t := str(v).strip_edges()
		return t.to_float() if t.is_valid_float() else 0.0
	return 0.0


## FNV-1a over the text, as world.js does it.
static func hash_str(s) -> int:
	var h := 2166136261
	var t := str(s)
	for i in t.length():
		h = Loot._imul(h ^ t.unicode_at(i), 16777619)
	return h & 0xFFFFFFFF


# ---------------------------------------------------------------- the map
func tile(k) -> Variant:
	return map["tiles"].get(str(k))


func is_open(k) -> bool:
	return map["tiles"].has(str(k))


func dock() -> String:
	return str(map["dock"])


func radius() -> int:
	var r = Rules.num(map.get("radius"), 18)
	return int(r) if Rules.truthy(r) else 18


func rings_per_skull() -> int:
	var r = Rules.num(tables.get("ringsPerSkull"), 3)
	return maxi(1, int(round(float(r))) if Rules.truthy(r) else 3)


func skull_of(k) -> int:
	var t = tile(k)
	if t == null:
		return 0
	var s = Rules.num(t.get("s"), 0)
	if Rules.truthy(s) and s >= 1 and s <= 6:
		return int(s)
	var d := dist(str(k), dock())
	if d == 0:
		return 1
	return clampi(int(ceil(float(d) / rings_per_skull())), 1, 6)


func district_of(k) -> String:
	var t = tile(k)
	return str(t["d"]) if t != null and Rules.truthy(t.get("d")) else ""


## The chance, in per cent, that stepping onto a tile springs an ambush.
func ambush_chance(k) -> int:
	if not is_open(k) or str(k) == dock():
		return 0
	var st = Rules.num(tables.get("ambushStep"), 0)
	return mini(100, int(st if Rules.truthy(st) else 0) * skull_of(k))


func poi_type_of(k) -> String:
	var t = tile(k)
	if t != null and Rules.truthy(t.get("t")):
		return str(t["t"])
	return POI_TYPES[hash_str(str(k) + ":" + str(map.get("seed"))) % POI_TYPES.size()]


static func district_name(d) -> String:
	var s := str(d if d != null else "")
	return ("District %s · %s" % [s, DISTRICT_NAMES.get(s, "")]) if s != "" else "No District"


# ---------------------------------------------------------------- what you know of it
## Standing on a tile shows what it and its neighbours hold, for good.
func stand(k, reach := 1) -> void:
	state["stood"][str(k)] = 1
	state["known"][str(k)] = 1
	if reach <= 1:
		for n in neighbours(k):
			if is_open(n):
				state["known"][n] = 1
		return
	var a := parse(k)
	for dq in range(-reach, reach + 1):
		for dr in range(maxi(-reach, -dq - reach), mini(reach, -dq + reach) + 1):
			var n := key(a.x + dq, a.y + dr)
			if is_open(n):
				state["known"][n] = 1


func known(k) -> bool:
	return state["known"].has(str(k))


func known_count() -> int:
	return state["known"].size()


# ---------------------------------------------------------------- what a tile holds
func unique_at(k) -> Variant:
	for u in uniques:
		if u is Dictionary and u.get("tile") == str(k):
			return u
	return null


## {kind, name, type, unique} or null: a POI, an Ambush, a Cache, an Event, or the dock.
func content_at(k) -> Variant:
	var t = tile(k)
	if t == null:
		return null
	var u = unique_at(k)
	if u != null:
		return {"kind": "poi", "unique": u, "type": u["type"] if Rules.truthy(u.get("type")) else "Unique POI", "name": u["name"] if Rules.truthy(u.get("name")) else "Unique POI"}
	if not Rules.truthy(t.get("c")):
		return null
	if t["c"] == "poi":
		return {"kind": "poi", "type": poi_type_of(k), "name": poi_type_of(k)}
	return {"kind": t["c"], "name": KIND_LABEL.get(t["c"], t["c"])}


func respawn() -> int:
	var r = Rules.num(tables.get("respawn"), 0)
	return int(r) if Rules.truthy(r) else 0


## Cleared in deployment N, it comes back once N + respawn deployments have ended.
func is_cleared(k) -> bool:
	var c = Rules.num(state["cleared"].get(str(k)), 0)
	if not Rules.truthy(c):
		return false
	return int(state["completed"]) < int(c) + respawn()


func clear(k, deployment_no := 0) -> void:
	state["cleared"][str(k)] = deployment_no if deployment_no > 0 else int(state["completed"]) + 1


func available(k) -> bool:
	var c = content_at(k)
	return c != null and c["kind"] != "dock" and not is_cleared(k)


## How many more deployments must end before a cleared tile holds something again.
func back_in(k) -> int:
	var c = Rules.num(state["cleared"].get(str(k)), 0)
	if not Rules.truthy(c):
		return 0
	return maxi(0, int(c) + respawn() - int(state["completed"]))


func end_deployment() -> int:
	state["completed"] = int(state["completed"]) + 1
	return state["completed"]


# ---------------------------------------------------------------- the way there
## The shortest way over open tiles, both ends included, or [] for none.
func path(from, to) -> Array:
	var a := str(from)
	var b := str(to)
	if not is_open(b):
		return []
	if a == b:
		return [a]
	var prev := {a: null}
	var q := [a]
	var at := 0
	while at < q.size():
		var k: String = q[at]
		at += 1
		if k == b:
			break
		for n in neighbours(k):
			if not prev.has(n) and is_open(n):
				prev[n] = k
				q.append(n)
	if not prev.has(b):
		return []
	var p := []
	var c = b
	while c != null:
		p.push_front(c)
		c = prev[c]
	return p


## The chance, in per cent, of at least one ambush along a path, not counting its start.
func path_risk(p: Array) -> int:
	var none := 1.0
	for i in range(1, p.size()):
		none *= 1.0 - ambush_chance(p[i]) / 100.0
	return int(Rules.js_round(100.0 * (1.0 - none)))


# ---------------------------------------------------------------- floors for fights
static func district_num(v) -> String:
	var m := Keywords._re("^\\s*(\\d)").search(str(v if v != null else ""))
	return m.get_string(1) if m != null else ""


## A floor's Skull Level: the one set on it, or the lowest of its Enemy Spawn Tiles.
static func floor_skull(raw: Dictionary) -> int:
	var base = Rules.num(raw.get("level"), 0)
	if Rules.truthy(base) and int(base) >= 1 and int(base) <= 6:
		return int(base)
	var labels: Dictionary = raw["colorLabels"] if raw.get("colorLabels") is Dictionary else {}
	var lo := 0
	for p in (raw["hexes"] if raw.get("hexes") is Array else []):
		var v: Dictionary = p[1] if p is Array and p.size() > 1 and p[1] is Dictionary else {}
		if v.get("c") == null:
			continue
		var c = v["c"]
		var lab := str(labels.get(str(int(c) if (c is float or c is int) else c), "")).to_lower()
		if lab.contains("enemy") and lab.contains("spawn"):
			var lv = Rules.num(v.get("lvl"), 0)
			var l: int = int(lv) if Rules.truthy(lv) else 1
			if lo == 0 or l < lo:
				lo = l
	return lo if lo > 0 else 1


## The best matches first: the same District, then none set, then any; the
## nearest Skull Level; your own floors before the test floors. Returns floor
## keys (names), as many as asked for, going round again if there are fewer.
func draw_floors(district, skull: int, count: int, ambush := false, tile = "") -> Array:
	var grown = grown_floors(district, skull, count, ambush, str(tile))
	if grown != null:
		return grown
	var pick := floors.filter(func(f): return not str(f["type"]).to_lower().contains("boss"))
	if pick.is_empty():
		pick = floors
	if pick.is_empty():
		return []
	var want := str(district if district != null else "")
	var ranked := []
	for f in pick:
		var ds := 0 if f["district"] == want else (1 if f["district"] == "" else 2)
		var ks: int = absi(int(f["skull"]) - skull)
		var ts := 0.5 if f["test"] else 0.0
		var is_ambush: bool = str(f["type"]).to_lower().contains("ambush")
		var ty := 0.0
		if ambush:
			ty = -1.0 if is_ambush else (-0.5 if f["size"] == "small" else 0.0)
		else:
			ty = 1.0 if is_ambush else 0.0
		var s: float = ds * 10 + ks + ts + ty + loot.rnd() * 0.3
		# kept in order as it goes: the lowest score first, an equal one after
		var at := ranked.size()
		while at > 0 and ranked[at - 1]["s"] > s:
			at -= 1
		ranked.insert(at, {"f": f, "s": s})
	var out := []
	for i in count:
		out.append(ranked[i % ranked.size()]["f"]["key"])
	return out


## (0.20) A POI's floors, grown from chunks where the District has them: a
## medium battlefield for each (the last one large from Skull 4), an ambush a
## small one. The same POI grows the same until it is cleared. A POI of more
## than one floor ends on a hand-made Boss floor when one fits its District and
## Skull. null when the District has too few chunks (whole floors are drawn).
func grown_floors(district, skull: int, count: int, ambush: bool, tile: String) -> Variant:
	var d := str(district if district != null else "")
	if not ChunkGen.can(chunks, d, skull):
		return null
	var base: int
	if ambush:
		base = int(loot.rnd() * 4294967296.0) & 0xFFFFFFFF
	else:
		var c = Rules.num(state["cleared"].get(tile), 0)
		base = hash_str(tile + ":" + str(map.get("seed")) + ":" + str(int(c) if Rules.truthy(c) else 0))
	var out := []
	for i in count:
		var size := "small" if ambush else ("large" if i == count - 1 and skull >= 4 else "medium")
		var seed := (base + i * 7919) & 0xFFFFFFFF
		if ChunkGen.generate(chunks, d, skull, size, seed).is_empty():
			return null
		out.append(ChunkGen.gen_key(d, skull, size, seed))
	if not ambush and count > 1:
		var boss := floors.filter(func(f): return str(f["type"]).to_lower().contains("boss") and f["district"] == d and absi(int(f["skull"]) - skull) <= 1)
		boss.sort_custom(func(a, b): return str(a["key"]) < str(b["key"]))
		if not boss.is_empty():
			out[count - 1] = boss[hash_str(str(base) + ":boss") % boss.size()]["key"]
	return out


## (0.20) A fight's floor as the Sandbox saves one: a generated one grown again from its key.
func level(k) -> Dictionary:
	if ChunkGen.is_gen_key(k):
		return ChunkGen.from_key(chunks, k)
	return {}


func floor_count(skull: int) -> int:
	var list = tables.get("floorsBySkull")
	var v = Rules.num(list[clampi(skull, 1, 6) - 1], 0) if list is Array and list.size() >= 6 else 0
	return int(v) if Rules.truthy(v) else 1


func floor_named(k) -> Variant:
	# (0.20) a generated one stands for itself while its chunks are here
	if ChunkGen.is_gen_key(k):
		var p := str(k).split("|")
		return {"key": str(k), "name": ChunkGen.default_name(p[1] if p.size() > 1 else "", ChunkGen._num(p[2] if p.size() > 2 else "", 1)), "generated": true} if not level(k).is_empty() else null
	for f in floors:
		if f["key"] == str(k):
			return f
	return null


# ---------------------------------------------------------------- Events
## The Event on a tile: the same one until the tile is cleared and comes back.
func event_for(k) -> Variant:
	if events.is_empty():
		return null
	var c = Rules.num(state["cleared"].get(str(k)), 0)
	return events[hash_str(str(k) + ":" + str(map.get("seed")) + ":" + str(int(c) if Rules.truthy(c) else 0)) % events.size()]
