## Battlefield chunks (0.20): a POI's battlefield grown from premade hexagons
## of tiles, as the Companion grows it (chunkgen.js); the tests hold the two to
## the same answer for every case.
##
## A chunk is a Sandbox floor of radius 3 (37 tiles) with chunk = {role, sides,
## skullMin, skullMax}: role is start, enemy, loot, exit or filler; sides says
## which of its six sides are open, in the order N, NE, SE, S, SW, NW. Chunks
## sit on a lattice of hexagons (the six neighbours of the one in the middle
## are at SIDE_VEC), each turned by sixths and maybe mirrored, twelve layouts
## from one chunk. An open side joins only an open side; where two chunks meet
## otherwise, a wall runs along the whole join.
##
## A battlefield grows from a Start chunk: fillers on from the last one placed
## (or, now and then, any), Enemy chunks on the farthest, Loot and an Exit on
## an Enemy chunk. Small is 3 chunks, medium 5, large 7. Every enemy pad, Loot
## Tile and symbol must be reachable from your pads; if not, it grows again.
class_name ChunkGen
extends RefCounted

const R := 3
static var SEP := char(1)   # between the parts of a symbol's key, as chunkgen.js has it
const SIDE_VEC: Array[Vector2i] = [Vector2i(4, -7), Vector2i(7, -3), Vector2i(3, 4), Vector2i(-4, 7), Vector2i(-7, 3), Vector2i(-3, -4)]
const MIRROR_SIDE := [4, 3, 2, 1, 0, 5]
const COUNT := {"small": 3, "medium": 5, "large": 7}
const PLAN := {3: ["start", "filler", "enemy"], 5: ["start", "filler", "enemy", "filler", "loot"], 7: ["start", "filler", "filler", "enemy", "enemy", "loot", "exit"]}
const LABELS := {0: "Enemy Spawn Tile", 1: "Half Cover Barricade", 2: "Loot Tile", 3: "Player Spawn Tile", 4: "Healing Station", 5: "Full Cover Barricade"}
const TRIES := 8
const ROLES := ["start", "enemy", "loot", "exit", "filler"]


## The World Map's random numbers (mulberry32), seeded.
class Rng extends RefCounted:
	var a := 0

	func _init(s: int) -> void:
		a = s & 0xFFFFFFFF

	func next() -> float:
		a = (a + 0x6D2B79F5) & 0xFFFFFFFF
		var t := a
		t = Loot._imul(t ^ (t >> 15), t | 1)
		t = (t ^ ((t + Loot._imul(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF
		return float((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0


static func key(q: int, r: int) -> String:
	return "%d,%d" % [q, r]


static func parse(k) -> Vector2i:
	var p := str(k).split(",")
	return Vector2i(int(p[0]) if p.size() > 0 else 0, int(p[1]) if p.size() > 1 else 0)


static func wk(a: String, b: String) -> String:
	return (a + "|" + b) if a < b else (b + "|" + a)


## A tile of a chunk, placed: mirrored (q, r to r, q), turned clockwise by sixths, then moved.
static func place(p: Vector2i, rot: int, mir: bool, at: Vector2i) -> Vector2i:
	var q := p.x
	var r := p.y
	if mir:
		var t := q
		q = r
		r = t
	for i in rot:
		var nq := -r
		var nr := q + r
		q = nq
		r = nr
	return Vector2i(q + at.x, r + at.y)


static func world_side(i: int, rot: int, mir: bool) -> int:
	return ((MIRROR_SIDE[i] if mir else i) + rot) % 6


static func is_chunk(lv) -> bool:
	return lv is Dictionary and lv.get("chunk") is Dictionary and lv.get("hexes") is Array and not lv["hexes"].is_empty()


static func _district(v) -> String:
	var s := str(v if v != null else "").strip_edges()
	return s.substr(0, 1) if s != "" and s.substr(0, 1).is_valid_int() else ""


## A whole number as JavaScript's parseInt(v, 10) || d reads it.
static func _num(v, d: int) -> int:
	if v is float or v is int:
		return int(v) if int(v) != 0 else d
	var s := str(v if v != null else "").strip_edges()
	var m := RegEx.create_from_string("^[+-]?\\d+").search(s)
	return int(m.get_string()) if m != null and int(m.get_string()) != 0 else d


static func fits(lv: Dictionary, district: String, skull: int) -> bool:
	var c: Dictionary = lv["chunk"]
	var d := _district(lv.get("district"))
	var lo := _num(c.get("skullMin"), 1)
	var hi := _num(c.get("skullMax"), 6)
	return (d == district or d == "") and skull >= lo and skull <= hi


## The chunks that can make a battlefield here, by role, each list sorted by name.
static func pools(chunks: Array, district: String, skull: int) -> Dictionary:
	var out := {"start": [], "enemy": [], "loot": [], "exit": [], "filler": []}
	var ok := chunks.filter(func(lv): return is_chunk(lv) and fits(lv, district, skull))
	ok.sort_custom(func(a, b): return str(a.get("name", "")) < str(b.get("name", "")))
	for lv in ok:
		var r := str(lv["chunk"].get("role", "filler"))
		if out.has(r):
			out[r].append(lv)
	return out


## Whether there is enough to grow one here: a Start and an Enemy chunk.
static func can(chunks: Array, district: String, skull: int) -> bool:
	var p := pools(chunks, district, skull)
	return not p["start"].is_empty() and not p["enemy"].is_empty()


static func sides_of(lv: Dictionary) -> Array:
	var s = lv["chunk"].get("sides", [])
	var out := []
	for i in 6:
		var v = s[i] if s is Array and i < s.size() else true
		out.append(not (v == false or (v is float and v == 0.0) or (v is int and v == 0)))
	return out


static func _free(p: Dictionary, used: Dictionary) -> Array:
	var out := []
	for k in 6:
		var at: Vector2i = p["at"] + SIDE_VEC[k]
		if p["open"][k] and not used.has(key(at.x, at.y)):
			out.append(k)
	return out


static func _put(placed: Array, used: Dictionary, lv: Dictionary, at: Vector2i, rot: int, mir: bool, hops: int, role: String) -> Dictionary:
	var s := sides_of(lv)
	var open := [false, false, false, false, false, false]
	for i in 6:
		open[world_side(i, rot, mir)] = s[i]
	var p := {"lv": lv, "at": at, "rot": rot, "mir": mir, "open": open, "hops": hops, "role": role}
	placed.append(p)
	used[key(at.x, at.y)] = p
	return p


## One try at growing it: the placed chunks, or [] if it couldn't.
static func grow(P: Dictionary, n: int, rng: Rng) -> Array:
	var plan: Array = PLAN[n]
	var placed := []
	var used := {}
	var start_pool: Array = P["start"]
	var start: Dictionary = start_pool[int(rng.next() * start_pool.size())]
	var rot0 := int(rng.next() * 6)
	var mir0 := rng.next() < 0.5
	_put(placed, used, start, Vector2i.ZERO, rot0, mir0, 0, "start")
	for step in range(1, plan.size()):
		var role: String = plan[step]
		var pool: Array = P[role] if not P[role].is_empty() else (P["filler"] if not P["filler"].is_empty() else P["enemy"])
		var open := placed.filter(func(p): return not _free(p, used).is_empty())
		if open.is_empty():
			return []
		var parent: Dictionary
		if role == "enemy":
			parent = open[0]
			for p in open:
				if p["hops"] > parent["hops"]:
					parent = p
		elif role == "loot" or role == "exit":
			var foes := open.filter(func(p): return p["role"] == "enemy")
			parent = foes[foes.size() - 1] if not foes.is_empty() else open[0]
			if foes.is_empty():
				for p in open:
					if p["hops"] > parent["hops"]:
						parent = p
		else:
			if rng.next() < 0.65:
				parent = open[open.size() - 1]
			else:
				parent = open[int(rng.next() * open.size())]
		var fr := _free(parent, used)
		var k: int = fr[int(rng.next() * fr.size())]
		var at: Vector2i = parent["at"] + SIDE_VEC[k]
		var back := (k + 3) % 6
		var c0 := int(rng.next() * pool.size())
		var t0 := int(rng.next() * 12)
		var done := false
		for ci in pool.size():
			if done:
				break
			var lv: Dictionary = pool[(c0 + ci) % pool.size()]
			var s := sides_of(lv)
			for ti in 12:
				if done:
					break
				var t := (t0 + ti) % 12
				var rot := t % 6
				var mir := t >= 6
				for i in 6:
					if s[i] and world_side(i, rot, mir) == back:
						_put(placed, used, lv, at, rot, mir, int(parent["hops"]) + 1, role)
						done = true
						break
		if not done:
			return []
	return placed


static func _within(a: Vector2i, c: Vector2i) -> bool:
	return maxi(maxi(absi(a.x - c.x), absi(a.y - c.y)), absi(a.x - c.x + a.y - c.y)) <= R


## The placed chunks as one Sandbox floor.
static func assemble(placed: Array, district: String, skull: int, size: String, name: String) -> Dictionary:
	var hexes := []
	var tiles := {}
	var walls := {}
	var marks := []
	var defs := []
	var def_of := {}
	for p in placed:
		var lv: Dictionary = p["lv"]
		var labels = lv.get("colorLabels", {})
		var ids := {}
		for d in lv.get("symDefs", []):
			if not (d is Dictionary):
				continue
			var hz = d.get("hazard")
			var dk := str(d.get("text", "")) + SEP + str(d.get("desc", "")) + SEP + (JSON.stringify(hz) if hz != null else "null")
			if not def_of.has(dk):
				var nd := {"id": defs.size() + 1, "text": d.get("text"), "desc": d.get("desc")}
				if hz != null:
					nd["hazard"] = hz.duplicate(true) if hz is Dictionary else hz
				defs.append(nd)
				def_of[dk] = nd["id"]
			ids[int(d.get("id", 0))] = def_of[dk]
		for pair in lv.get("hexes", []):
			var a := parse(pair[0])
			if not _within(a, Vector2i.ZERO):
				continue
			var w := place(a, p["rot"], p["mir"], p["at"])
			var k := key(w.x, w.y)
			var src = pair[1] if pair.size() > 1 and pair[1] is Dictionary else {}
			var t := {}
			var c := _colour(src.get("c"), labels)
			if c >= 0:
				t["c"] = c
			if c == 0:
				t["lvl"] = skull
			if not tiles.has(k):
				tiles[k] = t
				hexes.append([k, t])
		for m in lv.get("marks", []):
			var a2 := parse(m[0])
			if not _within(a2, Vector2i.ZERO):
				continue
			var w2 := place(a2, p["rot"], p["mir"], p["at"])
			if ids.has(int(m[1])):
				marks.append([key(w2.x, w2.y), ids[int(m[1])]])
		for wp in lv.get("walls", []):
			var e := str(wp[0]).split("|")
			if e.size() != 2:
				continue
			if not _within(parse(e[0]), Vector2i.ZERO) and not _within(parse(e[1]), Vector2i.ZERO):
				continue
			var wa := place(parse(e[0]), p["rot"], p["mir"], p["at"])
			var wb := place(parse(e[1]), p["rot"], p["mir"], p["at"])
			walls[wk(key(wa.x, wa.y), key(wb.x, wb.y))] = -1
	# where two chunks meet and the sides aren't both open: a wall all along the join
	var at := {}
	for p in placed:
		at[key(p["at"].x, p["at"].y)] = p
	for p in placed:
		for k in 3:
			var nb: Vector2i = p["at"] + SIDE_VEC[k]
			var q = at.get(key(nb.x, nb.y))
			if q == null or (p["open"][k] and q["open"][(k + 3) % 6]):
				continue
			for tk in tiles:
				var a3 := parse(tk)
				if not _within(a3, p["at"]):
					continue
				for d in Hex.DIRS:
					var b := a3 + d
					var bk := key(b.x, b.y)
					if tiles.has(bk) and _within(b, q["at"]):
						walls[wk(tk, bk)] = -1
	var wkeys := walls.keys()
	wkeys.sort()
	var wl := wkeys.map(func(x): return [x, -1])
	var labs := {}
	for c2 in LABELS:
		labs[str(c2)] = LABELS[c2]
	var names := placed.map(func(x): return str(x["lv"].get("name", "")))
	return {"v": 6, "name": name, "district": district, "poiType": "Generated", "level": str(skull), "floorSize": "", "battlefieldSize": size,
		"notes": "Grown from chunks: " + ", ".join(names) + ".", "rewards": "", "sizeKey": "one", "radius": R, "labels": true, "ink": false,
		"hexes": hexes, "marks": marks, "walls": wl, "symDefs": defs, "nextDef": defs.size() + 1, "colorLabels": labs,
		"wallLabels": {"-1": "Solid wall"}, "stamps": {},
		"generated": {"chunks": placed.map(func(x): return [str(x["lv"].get("name", "")), x["at"].x, x["at"].y, x["rot"], 1 if x["mir"] else 0, x["role"]])}}


## A chunk's colour as one of the six the battlefield knows (by its label), or -1.
static func _colour(c, labels) -> int:
	if c == null or not (labels is Dictionary):
		return -1
	var ci := int(c) if (c is int or c is float) else (int(str(c)) if str(c).is_valid_int() else -9999)
	var lab := str(labels.get(str(ci), labels.get(ci, ""))).to_lower()
	for j in 6:
		if str(LABELS[j]).to_lower() == lab:
			return j
	return -1


## Whether every enemy pad, Loot Tile and symbol can be walked to from your pads.
static func connected(lv: Dictionary) -> bool:
	var tiles := {}
	var walls := {}
	var start := []
	var need := []
	var foes := false
	for p in lv["hexes"]:
		tiles[p[0]] = p[1]
		var c = p[1].get("c")
		if c == 3:
			start.append(p[0])
		if c == 0 or c == 2:
			need.append(p[0])
		if c == 0:
			foes = true
	for m in lv["marks"]:
		need.append(m[0])
	for w in lv["walls"]:
		walls[w[0]] = true
	if start.is_empty() or not foes:
		return false
	var seen := {}
	var todo := start.duplicate()
	for k in start:
		seen[k] = true
	while not todo.is_empty():
		var k: String = todo.pop_back()
		var a := parse(k)
		for d in Hex.DIRS:
			var b := key(a.x + d.x, a.y + d.y)
			if tiles.has(b) and not seen.has(b) and not walls.has(wk(k, b)):
				seen[b] = true
				todo.append(b)
	return need.all(func(k): return seen.has(k))


## A battlefield for a District and Skull Level, of a size (small, medium or
## large), from a seed: the same seed, the same battlefield. {} when there
## aren't chunks enough.
static func generate(chunks: Array, district: String, skull: int, size: String, seed: int, name := "") -> Dictionary:
	if not COUNT.has(size):
		size = "medium"
	var P := pools(chunks, district, skull)
	if P["start"].is_empty() or P["enemy"].is_empty():
		return {}
	var rng := Rng.new(seed)
	for t in TRIES:
		var placed := grow(P, COUNT[size], rng)
		if placed.is_empty():
			continue
		var lv := assemble(placed, district, skull, size, name if name != "" else default_name(district, skull))
		if connected(lv):
			return lv
	return {}


static func default_name(district: String, skull: int) -> String:
	return "Generated · D%s · Skull %d" % [district if district != "" else "-", skull]


## A generated floor's key: everything it is made from, so it can be made again anywhere.
static func gen_key(district: String, skull: int, size: String, seed: int) -> String:
	return "gen|%s|%d|%s|%d" % [district, skull, size, seed & 0xFFFFFFFF]


static func is_gen_key(k) -> bool:
	return str(k).begins_with("gen|")


static func from_key(chunks: Array, k) -> Dictionary:
	var p := str(k).split("|")
	if p.size() != 5 or p[0] != "gen":
		return {}
	var sk := _num(p[2], 1)
	return generate(chunks, p[1], sk, p[3], int(p[4]) & 0xFFFFFFFF, default_name(p[1], sk))
