## Loot (the Companion's loot.js): what an Enemy drops when it goes down, what
## a Loot Tile or a Locked Chest holds, and a floor's own reward.
##
## Components are three part types (Troop, Equipment, Aether) in six rarities,
## Common to Mythic: eighteen kinds that stack. Aether shards are the
## currency; every drop includes some. A source (an Enemy, an Elite, a
## Mini-Boss, a Boss, a Loot Tile, a Locked Chest) and a Skull Level decide the
## shards, how many components, their type and their rarity. Skull N can drop
## up to the Nth rarity, weighted low; a tougher source rolls one Skull higher.
##
## The numbers are tables you set on the Companion's Loot page; they come
## across in the export. A deployment's loot is kept at the dock, where the
## Workshop and the Exchange spend it; a practice fight's is only shown.
##
## Proved to roll what loot.js rolls, seed for seed (tests/sim_diff.gd).
class_name Loot
extends RefCounted

const RARITIES := [
	{"id": "common", "label": "Common", "colour": "#a8bac2"},
	{"id": "uncommon", "label": "Uncommon", "colour": "#6fd189"},
	{"id": "rare", "label": "Rare", "colour": "#6ba6f5"},
	{"id": "epic", "label": "Epic", "colour": "#b98ef0"},
	{"id": "legendary", "label": "Legendary", "colour": "#f0bd57"},
	{"id": "mythic", "label": "Mythic", "colour": "#f2789a"}]
const TYPES := [
	{"id": "troop", "label": "Troop parts", "short": "Troop"},
	{"id": "equipment", "label": "Equipment parts", "short": "Equipment"},
	{"id": "aether", "label": "Aether parts", "short": "Aether"}]
## The tables as loot.js ships them: an export without any uses these.
const DEFAULTS := {
	"v": 1,
	"names": {
		"troop": ["Scrap servos", "Actuator packs", "Myomer bundles", "Neural harness", "Synthetic spine", "Aetherborn heart"],
		"equipment": ["Machined fittings", "Alloy plating", "Focusing coils", "Plasma cells", "Phase lattice", "Singularity core"],
		"aether": ["Inert Aetherite", "Charged filaments", "Resonant crystals", "Aetherite prisms", "Void glass", "Rift seed"]},
	"weights": [
		[100, 0, 0, 0, 0, 0],
		[60, 40, 0, 0, 0, 0],
		[40, 35, 25, 0, 0, 0],
		[28, 30, 26, 16, 0, 0],
		[20, 25, 25, 19, 11, 0],
		[15, 20, 23, 20, 15, 7]],
	"sources": {
		"enemy": {"label": "Enemy", "shards": 4, "min": 2, "max": 2, "bonus": 0, "top": 0, "bp": 4, "card": 0, "skull": "own"},
		"elite": {"label": "Elite", "shards": 8, "min": 4, "max": 4, "bonus": 1, "top": 0, "bp": 12, "card": 40, "skull": "own"},
		"miniboss": {"label": "Mini-Boss", "shards": 16, "min": 6, "max": 6, "bonus": 1, "top": 0, "bp": 30, "card": 75, "skull": "own"},
		"boss": {"label": "Boss", "shards": 32, "min": 10, "max": 10, "bonus": 0, "top": 2, "bp": 70, "card": 100, "skull": "poi"},
		"lootTile": {"label": "Loot Tile", "shards": 6, "min": 2, "max": 4, "bonus": 0, "top": 0, "bp": 16, "card": 0, "skull": "poi"},
		"chest": {"label": "Locked Chest", "shards": 6, "min": 0, "max": 0, "bonus": 0, "top": 0, "bp": 30, "card": 25, "skull": "poi", "fromTile": true}},
	"spread": 50,
	"chestDefault": 4}

var tables: Dictionary
var _a := 0                   # the seeded stream, as loot.js keeps it
var _seeded := false
var _rng := RandomNumberGenerator.new()


## t: the tables out of the export (null for the defaults). seed: a number for
## rolls that can be made again, or null for chance.
func _init(t = null, seed = null) -> void:
	tables = t if (t is Dictionary and t.get("sources") is Dictionary and t.get("weights") is Array and t.get("names") is Dictionary) else DEFAULTS.duplicate(true)
	if seed != null:
		seed_with(seed)
	else:
		_rng.randomize()


# ---------------------------------------------------------------- chance
## 32-bit multiplication, as JavaScript's Math.imul does it.
static func _imul(a: int, b: int) -> int:
	var lo := (a & 0xFFFF) * b
	var hi := ((a >> 16) & 0xFFFF) * b
	return (lo + ((hi & 0xFFFF) << 16)) & 0xFFFFFFFF


func seed_with(n) -> void:
	_a = int(n) & 0xFFFFFFFF
	_seeded = true


## Where the stream stands, so that taking a move back takes its loot back too.
func state() -> Array:
	return [_a, _seeded, _rng.state]


func restore(s: Array) -> void:
	_a = s[0]
	_seeded = s[1]
	_rng.state = s[2]


## The next number from 0 up to 1. Seeded, it is loot.js's own stream.
func rnd() -> float:
	if not _seeded:
		return _rng.randf()
	_a = (_a + 0x6D2B79F5) & 0xFFFFFFFF
	var t := _a
	t = _imul(t ^ (t >> 15), t | 1)
	t = (t ^ ((t + _imul(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF
	return float((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0


func between(a, b) -> int:
	var lo := int(floor(float(a)))
	var hi := int(floor(float(b)))
	if hi < lo:
		var t := lo
		lo = hi
		hi = t
	return lo + int(floor(rnd() * (hi - lo + 1)))


# ---------------------------------------------------------------- a bag of loot
## Shards, and a count of each of the eighteen.
static func bag() -> Dictionary:
	return {"shards": 0, "parts": {"troop": [0, 0, 0, 0, 0, 0], "equipment": [0, 0, 0, 0, 0, 0], "aether": [0, 0, 0, 0, 0, 0]}}


static func _whole(v) -> int:
	if v is int:
		return maxi(0, v)
	if v is float:
		return 0 if (is_nan(v) or is_inf(v)) else maxi(0, int(floor(v)))
	if v is String and v.strip_edges().is_valid_float():
		return maxi(0, int(floor(v.strip_edges().to_float())))
	return 0


static func norm(b) -> Dictionary:
	var o := bag()
	if not (b is Dictionary):
		return o
	o["shards"] = _whole(b.get("shards"))
	var parts: Dictionary = b["parts"] if b.get("parts") is Dictionary else {}
	for ty in TYPES:
		var r: Array = parts[ty["id"]] if parts.get(ty["id"]) is Array else []
		for i in 6:
			o["parts"][ty["id"]][i] = _whole(r[i]) if i < r.size() else 0
	return o


static func add(a, b) -> Dictionary:
	var o := norm(a)
	var n := norm(b)
	o["shards"] += n["shards"]
	for ty in TYPES:
		for i in 6:
			o["parts"][ty["id"]][i] += n["parts"][ty["id"]][i]
	return o


static func count(b) -> int:
	var n := 0
	var o := norm(b)
	for ty in TYPES:
		for v in o["parts"][ty["id"]]:
			n += v
	return n


static func is_empty(b) -> bool:
	var o := norm(b)
	return o["shards"] == 0 and count(o) == 0


func name_of(type: String, rarity: int) -> String:
	var row = tables["names"].get(type)
	if row is Array and rarity < row.size() and Rules.truthy(row[rarity]):
		return str(row[rarity])
	return RARITIES[rarity]["label"] + " " + type + " parts"


## What is in a bag, rarest first.
func lines(b) -> Array:
	var o := norm(b)
	var out := []
	for r in range(5, -1, -1):
		for ty in TYPES:
			var n: int = o["parts"][ty["id"]][r]
			if n > 0:
				out.append({"type": ty["id"], "rarity": r, "n": n, "name": name_of(ty["id"], r), "rarityLabel": RARITIES[r]["label"], "color": RARITIES[r]["colour"]})
	return out


## A bag in words: "6 shards, 2 × Scrap servos", or "nothing".
func text(b) -> String:
	var o := norm(b)
	var bits := []
	if o["shards"] > 0:
		bits.append("%d shard%s" % [o["shards"], "" if o["shards"] == 1 else "s"])
	for l in lines(o):
		bits.append("%d × %s" % [l["n"], l["name"]])
	return ", ".join(bits) if not bits.is_empty() else "nothing"


# ---------------------------------------------------------------- rolling
static func clamp_skull(s) -> int:
	var v = Rules.num(s, 0)
	var n: int = int(v) if Rules.truthy(v) else 0
	return n if (n >= 1 and n <= 6) else 1


func _row(skull: int) -> Array:
	return tables["weights"][clamp_skull(mini(6, skull)) - 1]


static func _w(v) -> float:
	return maxf(0.0, float(v)) if (v is int or v is float) and Rules.truthy(v) else 0.0


## One rarity, as if at this Skull Level.
func roll_rarity(skull: int) -> int:
	var row := _row(skull)
	var tot := 0.0
	for i in 6:
		tot += _w(row[i] if i < row.size() else 0)
	if tot <= 0:
		return 0
	var x := rnd() * tot
	for i in 6:
		x -= _w(row[i] if i < row.size() else 0)
		if x < 0:
			return i
	return 5


## The rarest a Skull Level can give.
func top_rarity(skull: int) -> int:
	var row := _row(skull)
	for i in range(5, -1, -1):
		if i < row.size() and _w(row[i]) > 0:
			return i
	return 0


func pick_type(salvage) -> String:
	var s := str(salvage if Rules.truthy(salvage) else "mixed").to_lower()
	if s == "troop" or s == "equipment" or s == "aether":
		return s
	return TYPES[int(floor(rnd() * 3))]["id"]


static func _n(v) -> float:
	return float(v) if (v is int or v is float) and Rules.truthy(v) else 0.0


## o: {source, skull (the Unit's own), poiSkull, salvage, x (a chest's number)}
func roll(o: Dictionary) -> Dictionary:
	var src: Dictionary = tables["sources"][o["source"]] if tables["sources"].get(o.get("source")) is Dictionary else tables["sources"]["enemy"]
	var out := bag()
	var own = o["skull"] if Rules.truthy(o.get("skull")) else o.get("poiSkull")
	var poi = o["poiSkull"] if Rules.truthy(o.get("poiSkull")) else o.get("skull")
	var skull := clamp_skull(poi if src.get("skull") == "poi" else own)
	var at := mini(6, skull + int(_n(src.get("bonus"))))
	var base := _n(src.get("shards")) * skull
	var sp := _n(tables.get("spread")) / 100.0
	out["shards"] = maxi(1, int(floor(base * (1 + (rnd() * 2 - 1) * sp) + 0.5))) if base > 0 else 0
	var n := 0
	if Rules.truthy(src.get("fromTile")):
		var xv = Rules.num(o.get("x"), 0)
		var x: int = int(xv) if Rules.truthy(xv) else 0
		n = maxi(0, x if x != 0 else int(_n(tables.get("chestDefault"))))
	else:
		n = between(_n(src.get("min")), _n(src.get("max")))
	for i in n:
		var r := top_rarity(at) if float(i) < _n(src.get("top")) else roll_rarity(at)
		out["parts"][pick_type("mixed" if (Rules.truthy(src.get("fromTile")) or o.get("source") == "lootTile") else o.get("salvage"))][r] += 1
	return out


## A floor's own reward: {shards, lines: [{kind: "exact", n, type, rarity} or
## {kind: "roll", n, type ("any" or a part type), bonus}]}. A line of kind
## "item" is a blueprint or a chassis, which wait for the Workshop.
func roll_reward(rw, poi_skull) -> Dictionary:
	var out := bag()
	if not (rw is Dictionary):
		return out
	out["shards"] = _whole(rw.get("shards"))
	for l in (rw["lines"] if rw.get("lines") is Array else []):
		if not (l is Dictionary) or l.get("kind") == "item":
			continue
		var nv = Rules.num(l.get("n"), 0)
		var n: int = clampi(int(nv) if Rules.truthy(nv) else 0, 0, 99)
		if l.get("kind") == "exact":
			var ty: String = str(l["type"]) if TYPES.any(func(x): return x["id"] == l.get("type")) else "troop"
			var rv = Rules.num(l.get("rarity"), 0)
			out["parts"][ty][clampi(int(rv) if Rules.truthy(rv) else 0, 0, 5)] += n
		else:
			var bv = Rules.num(l.get("bonus"), 0)
			var at := mini(6, clamp_skull(poi_skull) + maxi(0, int(bv) if Rules.truthy(bv) else 0))
			for i in n:
				var ty2 := pick_type("mixed" if l.get("type") == "any" else l.get("type"))
				out["parts"][ty2][roll_rarity(at)] += 1
	return out


## A floor's reward in words, before it is rolled: "20 shards, 2 rolled components".
func reward_text(rw) -> String:
	if not (rw is Dictionary):
		return ""
	var bits := []
	# as loot.js words it: the number as it was written, whatever it is
	var sv = rw.get("shards")
	if sv is String and sv.strip_edges().is_valid_float():
		sv = sv.strip_edges().to_float()
	if (sv is int or sv is float) and Rules.truthy(sv):
		bits.append((str(int(sv)) if float(sv) == floor(float(sv)) else str(sv)) + " shards")
	for l in (rw["lines"] if rw.get("lines") is Array else []):
		if not (l is Dictionary) or l.get("kind") == "item":
			continue
		var nv = Rules.num(l.get("n"), 0)
		var n: int = int(nv) if Rules.truthy(nv) else 0
		if n == 0:
			continue
		if l.get("kind") == "exact":
			var rv = Rules.num(l.get("rarity"), 0)
			bits.append("%d × %s" % [n, name_of(str(l.get("type")), clampi(int(rv) if Rules.truthy(rv) else 0, 0, 5))])
		else:
			var short := "component"
			if l.get("type") != "any":
				var found := TYPES.filter(func(x): return x["id"] == l.get("type"))
				short = (found[0] if not found.is_empty() else TYPES[0])["short"] + " part"
			var bv = Rules.num(l.get("bonus"), 0)
			var bonus: int = int(bv) if Rules.truthy(bv) else 0
			bits.append("%d rolled %s%s%s" % [n, short, "" if n == 1 else "s", (" (+%d rarity)" % bonus) if bonus != 0 else ""])
	return ", ".join(bits)


## Which source a Unit's card type drops as.
static func source_for(card_type) -> String:
	var c := str(card_type if card_type != null else "").to_lower()
	return c if (c == "elite" or c == "miniboss" or c == "boss") else "enemy"


## A floor's Skull Level: the one set on it, or the highest of its Enemy Spawn
## Tiles. (poiSkull)
static func poi_skull(f: FloorData) -> int:
	if f == null:
		return 1
	var sv = Rules.num(f.raw.get("level"), 0)
	var s: int = int(sv) if Rules.truthy(sv) else 0
	if s >= 1 and s <= 6:
		return s
	var best := 0
	for h in f.tiles:
		var t: Dictionary = f.tiles[h] if f.tiles[h] is Dictionary else {}
		var lab := f.label_of(h).to_lower()
		if lab.contains("enemy") and lab.contains("spawn"):
			var lv = Rules.num(t.get("lvl"), 0)
			var l: int = int(lv) if Rules.truthy(lv) else 0
			if l > best:
				best = l
	return best if (best >= 1 and best <= 6) else 1
