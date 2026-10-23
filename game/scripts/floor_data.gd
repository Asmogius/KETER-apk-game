## A floor from the Companion's Sandbox, as exported (content/floors.json).
## Tiles are axial "q,r" keys; a tile may carry a colour (c, 0-5) whose
## meaning is in colorLabels, and a spawn level (lvl). Walls sit on the edge
## between two tiles ("q,r|q,r"). Marks put a symbol on a tile.
class_name FloorData
extends RefCounted

## The Sandbox's six colours, by index.
const RAINBOW: Array[Color] = [Color("#c8624d"), Color("#e88a36"), Color("#f8c53a"), Color("#42a459"), Color("#4572e3"), Color("#9052bc")]

var name := ""
var district := ""
var tiles := {}           # Vector2i -> Dictionary (the tile's own fields)
var walls := []           # [Vector2i, Vector2i, int colour id]
var marks := {}           # Vector2i -> symbol definition id
var sym_defs := {}        # id -> Dictionary {text, desc, ...}
var color_labels := {}    # int -> String
var hazards := {}         # Vector2i -> {text, keyword, damage, when}: tiles that bite
var raw := {}


static func from_dict(d: Dictionary) -> FloorData:
	var f := FloorData.new()
	f.raw = d
	f.name = str(d.get("name", "Untitled floor"))
	f.district = str(d.get("district", ""))
	for pair in d.get("hexes", []):
		if pair is Array and pair.size() >= 2:
			var t = pair[1]
			f.tiles[Hex.parse(str(pair[0]))] = t if t is Dictionary else {}
	for pair in d.get("walls", []):
		if pair is Array and pair.size() >= 1:
			var ends := str(pair[0]).split("|")
			if ends.size() == 2:
				f.walls.append([Hex.parse(ends[0]), Hex.parse(ends[1]), int(pair[1]) if pair.size() > 1 and pair[1] != null else -1])
	for pair in d.get("marks", []):
		if pair is Array and pair.size() >= 2:
			f.marks[Hex.parse(str(pair[0]))] = int(pair[1])
	for s in d.get("symDefs", []):
		if s is Dictionary and s.has("id"):
			f.sym_defs[int(s["id"])] = s
	# A hazard is a symbol carrying an effect; marks say where those symbols sit.
	var haz := {}
	for sd in d.get("symDefs", []):
		if sd is Dictionary and sd.get("hazard") is Dictionary and (Rules.truthy(sd["hazard"].get("keyword")) or Rules.truthy(sd["hazard"].get("damage"))):
			var dm = Rules.num(sd["hazard"].get("damage"), 0)
			haz[int(sd["id"])] = {"text": sd.get("text"), "keyword": sd["hazard"]["keyword"] if Rules.truthy(sd["hazard"].get("keyword")) else "",
				"damage": dm if Rules.truthy(dm) else 0, "when": sd["hazard"]["when"] if Rules.truthy(sd["hazard"].get("when")) else "both", "desc": str(sd.get("desc", ""))}
	for pair in d.get("marks", []):
		if pair is Array and pair.size() >= 2 and haz.has(int(pair[1])):
			f.hazards[Hex.parse(str(pair[0]))] = haz[int(pair[1])]
	var labels = d.get("colorLabels", {})
	if labels is Dictionary:
		for k in labels:
			f.color_labels[int(k)] = str(labels[k])
	return f


## A copy this fight can change (a Barricade put down) without changing the
## floor itself. Tiles are copied one level down, so a changed tile is a new one.
func copy() -> FloorData:
	var f := FloorData.new()
	f.raw = raw
	f.name = name
	f.district = district
	f.tiles = tiles.duplicate()
	f.walls = walls.duplicate()
	f.marks = marks.duplicate()
	f.sym_defs = sym_defs
	f.color_labels = color_labels.duplicate()
	f.hazards = hazards.duplicate()
	return f


## Revision 16.3: the colour a Barricade paints its tile: the one this floor
## already calls Full (or Half) Cover, else a new one so called.
func cover_colour(which: String) -> int:
	var want := "cover-full" if which == "Full" else "cover-half"
	var keys: Array = color_labels.keys()
	keys.sort()
	for k in keys:
		if label_kind(str(color_labels[k])) == want:
			return int(k)
	var k2 := 5 if which == "Full" else 1
	while color_labels.has(k2):
		k2 += 1
	color_labels[k2] = which + " Cover Barricade"
	return k2


## What a colour's label means (simTileKind): "spawn-ally", "cover-full", ... or "".
static func label_kind(label: String) -> String:
	var t := label.to_lower()
	if Keywords._re("player\\s*spawn").search(t): return "spawn-ally"
	if Keywords._re("enemy\\s*spawn").search(t): return "spawn-enemy"
	if Keywords._re("full\\s*cover").search(t): return "cover-full"
	if Keywords._re("half\\s*cover").search(t): return "cover-half"
	if "heal" in t: return "healing"
	if "loot" in t: return "loot"
	return ""


func has_tile(h: Vector2i) -> bool:
	return tiles.has(h)


## A tile's colour index, or -1 for a plain tile.
func colour_of(h: Vector2i) -> int:
	var t = tiles.get(h, {})
	if t is Dictionary and t.get("c") != null:
		return int(t["c"])
	return -1


## What a tile's colour means here ("Player Spawn Tile"), or "".
func label_of(h: Vector2i) -> String:
	var c := colour_of(h)
	return color_labels.get(c, "") if c >= 0 else ""


## The tiles whose colour this floor calls a player spawn.
func player_spawns() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for h in tiles:
		if label_of(h).to_lower().begins_with("player spawn"):
			out.append(h)
	out.sort_custom(func(a, b): return a.x < b.x or (a.x == b.x and a.y < b.y))
	return out


## Where a Hero starts: a player spawn tile, else the tile nearest the middle.
func start_tile() -> Vector2i:
	var s := player_spawns()
	if not s.is_empty():
		return s[0]
	var best := Vector2i.ZERO
	var bd := 1 << 30
	for h in tiles:
		var dd := Hex.distance(h, Vector2i.ZERO)
		if dd < bd:
			bd = dd
			best = h
	return best


## The rectangle the floor covers, for hexes of this size.
func bounds(size: float) -> Rect2:
	if tiles.is_empty():
		return Rect2()
	var r := Rect2(Hex.to_pixel(tiles.keys()[0], size), Vector2.ZERO)
	for h in tiles:
		var c := Hex.to_pixel(h, size)
		r = r.expand(c + Vector2(Hex.SQ3 * size / 2.0, size)).expand(c - Vector2(Hex.SQ3 * size / 2.0, size))
	return r
