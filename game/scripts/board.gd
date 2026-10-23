## The board: a floor's tiles, walls and symbols, the Units standing on it,
## and, while you are moving one, the tiles it can reach and the way it goes.
##
## (0.14) Drawn flat, as things: every tile a plate of the deck, cover as
## sandbags, blocks, barriers and stacked containers, a hazard as the acid,
## cables, wire, sludge or fire it is, spawn pads lit in their side's colour,
## loot as crates, Locked Chests, Emergency Exits and Healing Stations as
## themselves, walls standing on the tiles' edges. (0.18) And its atmosphere
## (Atmos): glows, a flicker of the lights, motes drifting. The floor sits on the art's
## pixel grid: one art pixel is 2 world units, a column of tiles 42 art pixels
## and a row 36, so every piece lands on whole pixels. Units, props and walls
## stand in one layer, the nearer drawn over the farther.
class_name Board
extends Node2D

signal tile_tapped(tile: Vector2i)
signal off_board_tapped

const SIZE := 48.0            # centre to corner (top and bottom), in world units
const PIXEL := 2.0            # (0.11) one art pixel, in world units
const COL := 84.0             # (0.14) a column of tiles: 42 art pixels
const ROW := 72.0             # (0.14) a row: 36 art pixels
const PLAIN := Color("#2c3438")
const EDGE := Color("#14121d")
const FLOOR_TINT := Color(0.5, 0.52, 0.58)
const GROUND_TINT := Color(0.62, 0.62, 0.66, 0.5)
const REACH_ALLY := Color("#73efe8")
const REACH_ENEMY := Color("#ff2a3c")
const PATH := Color("#d6a851")
const HAZARD := Color("#f8c53a")
const BLAST := Color("#e88a36")
## the deck's plates, plain ones most often
const FLOORS := ["floor_bolts", "floor_seam", "floor_bolts", "floor_grate", "floor_seam", "floor_bolts", "floor_vent", "floor_seam", "floor_bolts", "floor_trench", "floor_seam", "floor_bolts"]
## (0.15) A District's five plates, the quiet first one most often.
const D_FLOORS := [0, 1, 0, 2, 0, 1, 3, 0, 1, 2, 0, 4]
const WALL_H := 24.0          # (0.14) how tall a wall stands, in world units
const WALL_T := 6.0           # how thick it is

var floor_data: FloorData = null
var reach := {}               # Vector2i -> steps, lit while choosing where to go
var reach_colour := REACH_ALLY
var path: Array[Vector2i] = []
var path_from := Vector2i.ZERO
var blast := {}               # Vector2i -> true: the area an Action being previewed would cover
var loot_tiles := {}          # Vector2i -> true: Loot Tiles, which say so
var searched := {}            # Vector2i -> true: Loot Tiles and Locked Chests already emptied
var units_layer: Node2D       # (0.14) Units, props and walls, sorted so the nearer stands in front
var views := {}               # unit id -> UnitView
var props := {}               # (0.14) Vector2i -> Sprite2D: what stands on a tile
var wall_pieces: Array = []   # (0.14) the walls, as pieces in the sorted layer
var atmos: Atmos              # (0.18) the glows, the flicker and the drifting motes
var _font: Font


# ---------------------------------------------------------------- the grid (0.14)
## The centre of a tile, on the art's pixel grid.
static func at(h: Vector2i) -> Vector2:
	return Vector2(COL * (h.x + h.y / 2.0), ROW * h.y)


## The tile under a point.
static func hex_at(p: Vector2) -> Vector2i:
	var r := p.y / ROW
	var q := p.x / COL - r / 2.0
	return Hex.round_cube(q, r)


## A tile's six corners, from the upper right, clockwise (as Hex.corners), k of the way out.
static func corners(c: Vector2, k := 1.0) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(42, -24) * k, c + Vector2(42, 24) * k, c + Vector2(0, 48) * k,
		c + Vector2(-42, 24) * k, c + Vector2(-42, -24) * k, c + Vector2(0, -48) * k])


## The edge two neighbouring tiles share, as its two ends.
static func shared_edge(a: Vector2i, b: Vector2i) -> PackedVector2Array:
	var i := Hex.DIRS.find(b - a)
	if i < 0:
		return PackedVector2Array()
	var c := corners(at(a))
	return PackedVector2Array([c[i], c[(i + 1) % 6]])


## What a tile is for, by the meaning of its colour (Battle.kind_at reads the same).
static func tile_kind(f: FloorData, h: Vector2i) -> String:
	if f == null:
		return ""
	var t := f.label_of(h).to_lower()
	if Keywords._re("player\\s*spawn").search(t): return "spawn-ally"
	if Keywords._re("enemy\\s*spawn").search(t): return "spawn-enemy"
	if Keywords._re("full\\s*cover").search(t): return "cover-full"
	if Keywords._re("half\\s*cover").search(t): return "cover-half"
	if "heal" in t: return "healing"
	if "loot" in t: return "loot"
	return ""


## A symbol on a tile: "chest" (its text starts LC), "exit" (EX), or its text.
static func symbol_kind(f: FloorData, h: Vector2i) -> String:
	if f == null or not f.marks.has(h) or f.hazards.has(h):
		return ""
	var d = f.sym_defs.get(f.marks[h])
	var t := str(d.get("text") if d is Dictionary and d.get("text") != null else "").strip_edges().to_upper()
	if t.begins_with("LC"):
		return "chest"
	if t == "EX":
		return "exit"
	return t


## Which picture a hazard wears, by what it does.
static func hazard_art(hz: Dictionary) -> String:
	var k := str(hz.get("keyword", "")).to_lower()
	if "poison" in k:
		return "hazard_acid"
	if "stun" in k or "drain" in k:
		return "hazard_sparks"
	if "bleed" in k or "sunder" in k:
		return "hazard_razor"
	if "slow" in k or "root" in k or "pin" in k:
		return "hazard_sludge"
	return "hazard_fire"


## A rectangle on the art's pixel grid.
static func snap_rect(r: Rect2) -> Rect2:
	return Rect2(r.position.snapped(Vector2(PIXEL, PIXEL)), r.size.snapped(Vector2(PIXEL, PIXEL)))


static func _hash(h: Vector2i) -> int:
	return absi(h.x * 73856093 ^ h.y * 19349663)


func _ready() -> void:
	_font = Look.font()
	units_layer = Node2D.new()
	units_layer.z_index = 2
	units_layer.y_sort_enabled = true
	add_child(units_layer)
	atmos = Atmos.new()
	add_child(atmos)


## Which tiles are Loot Tiles (they are captioned), for a new floor.
## Revision 16.3: the fight changed its floor (a Barricade put down, or taken
## back by Undo): what stands on it is drawn again.
var _floor_rev := 0
func sync_floor(f: FloorData, rev: int) -> void:
	if f == floor_data and rev == _floor_rev:
		return
	floor_data = f
	_floor_rev = rev
	_build_things()
	_dim_props()
	queue_redraw()


func set_loot_tiles(tiles: Dictionary) -> void:
	loot_tiles = tiles
	searched = {}
	_dim_props()
	queue_redraw()


## Which Loot Tiles and Locked Chests have been emptied: they are dimmed.
func set_searched(found: Dictionary) -> void:
	if found.size() == searched.size() and found.keys().all(func(k): return searched.has(k)):
		return
	searched = found.duplicate()
	_dim_props()
	queue_redraw()


func show_floor(f: FloorData) -> void:
	floor_data = f
	_floor_rev = 0
	clear_marks()
	clear_units()
	_build_things()
	if atmos != null:
		atmos.reset(self)
	queue_redraw()


func clear_units() -> void:
	for v in views.values():
		v.queue_free()
	views.clear()


# ---------------------------------------------------------------- what stands on the floor (0.14)
func _build_things() -> void:
	for n in props.values():
		n.queue_free()
	props.clear()
	for w in wall_pieces:
		w.queue_free()
	wall_pieces.clear()
	if floor_data == null:
		return
	for h in floor_data.tiles:
		var name := ""
		match tile_kind(floor_data, h):
			"cover-half":
				name = "half_cover_a" if _hash(h) % 2 == 0 else "half_cover_b"
			"cover-full":
				name = "full_cover_a" if _hash(h) % 2 == 0 else "full_cover_b"
			"loot":
				name = "crate"
			"healing":
				name = "healing_station"
		match symbol_kind(floor_data, h):
			"chest":
				name = "locked_chest"
			"exit":
				name = "emergency_exit"
		if name != "":
			_add_prop(h, name)
	for w in floor_data.walls:
		var e := shared_edge(w[0], w[1])
		if e.size() == 2:
			var piece := WallPiece.new(e[0], e[1])
			units_layer.add_child(piece)
			wall_pieces.append(piece)


## A prop on a tile. Cover stands at the tile's front, so a Unit on it is
## seen behind it; an Exit is a hatch in the floor, under whoever stands on it.
func _add_prop(h: Vector2i, name: String) -> void:
	var a := piece_for(name)
	if a.is_empty() or a.get("texture") == null:
		return
	var s := Sprite2D.new()
	s.texture = a["texture"]
	s.centered = false
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2(PIXEL, PIXEL)
	var ground := 14.0                       # where it stands, below the tile's centre
	var key := 16.0                          # where it sorts: in front of a Unit on the tile
	if name == "emergency_exit":
		ground = 8.0
		key = -40.0
	elif name in ["crate", "locked_chest", "healing_station"]:
		ground = 10.0
		key = -2.0                           # a Unit on it stands in front of it
	s.position = at(h) + Vector2(0, key)
	var foot: Vector2 = a["foot"]
	s.offset = Vector2(0, ground - key) / PIXEL - foot
	s.set_meta("prop", name)
	units_layer.add_child(s)
	props[h] = s


func _dim_props() -> void:
	for h in props:
		var s: Sprite2D = props[h]
		s.modulate = Color(0.45, 0.45, 0.5) if searched.has(h) else Color.WHITE


## A view for every Unit in the battle, where it stands.
func show_units(b: Battle) -> void:
	clear_units()
	sync(b, [], false)
	mark_units(b)


func _add_view(u: Dictionary, b: Battle) -> UnitView:
	var v := UnitView.new()
	units_layer.add_child(v)
	v.setup(u, b.looks.get(u["id"], {}), SIZE)
	views[u["id"]] = v
	return v


## Brings every view up to date with the battle: Health, statuses and who is
## holding fire; a Unit that was pushed slides to where it now stands; one put
## down by a Deploy appears; one that went down fades away (once), and comes
## back if the move that did it is taken back. With state (the Units as they
## stood after a beat of an Enemy's turn) it shows that instead of this instant.
func sync(b: Battle, state: Array = [], arriving := true) -> void:
	var list: Array = state if not state.is_empty() else b.units
	var seen := {}
	for d in list:
		var id: String = d["id"]
		seen[id] = true
		if not (d.get("pos") is Dictionary):
			continue
		var v: UnitView = views.get(id)
		if v == null:
			var live = b.unit_by_id(id)
			if live == null:
				continue
			v = _add_view(live, b)
			v.position = at(Battle.tile_of(d))
			v.show_state(d)
			if arriving:
				v.pop_in()
		var down := Rules.truthy(d.get("down"))
		if down and not v.gone:
			v.show_state(d)
			v.fade_out()
		elif not down and v.gone:
			v.come_back()
		if not down:
			v.show_state(d)
		var want := at(Battle.tile_of(d))
		if not v.is_walking() and v.position.distance_to(want) > 0.5:
			if v.gone:
				v.position = want
			else:
				v.slide_to(Battle.tile_of(d))
	# a Unit the battle no longer has (its Deploy was taken back) leaves the board
	if state.is_empty():
		for id in views.keys():
			if not seen.has(id):
				views[id].queue_free()
				views.erase(id)


## Marks every Unit: who is selected, who has moved, who is aimed at, who is
## acting, who an area would catch. (No change to what each shows.)
func mark_units(b: Battle, selected_id: String = "", targets: Dictionary = {}, acting_id: String = "", caught: Dictionary = {}) -> void:
	for id in views:
		var v: UnitView = views[id]
		v.dim = b.has_moved(v.unit) and v.unit["side"] == "ally"
		v.selected = id == selected_id
		v.targeted = targets.has(id)
		v.acting = id == acting_id
		v.caught = caught.has(id)
		v.refresh()


## Brings every Unit up to date with the battle and marks them.
func refresh_units(b: Battle, selected_id: String = "", targets: Dictionary = {}, acting_id: String = "", caught: Dictionary = {}) -> void:
	sync(b)
	mark_units(b, selected_id, targets, acting_id, caught)


func view_of(id: String) -> UnitView:
	return views.get(id)


## Lights the tiles a Unit can reach, in its side's colour.
func set_reach(tiles: Array, side: String) -> void:
	reach.clear()
	for t in tiles:
		reach[Vector2i(t["q"], t["r"])] = t["cost"]
	reach_colour = REACH_ALLY if side == "ally" else REACH_ENEMY
	queue_redraw()


func set_path(from: Vector2i, steps: Array[Vector2i]) -> void:
	path_from = from
	path = steps
	queue_redraw()


func clear_marks() -> void:
	reach.clear()
	path = []
	blast.clear()
	aim_tiles = {}
	queue_redraw()


## Lights the tiles within a distance of a tile: where a blast would fall.
func set_blast(centre: Vector2i, radius: int) -> void:
	blast.clear()
	if floor_data != null:
		for h in floor_data.tiles:
			if Hex.distance(h, centre) <= radius:
				blast[h] = true
	queue_redraw()


## Revision 16.3: lights these tiles as well: the tiles a Line or a Cone covers.
func add_blast(tiles: Array) -> void:
	for h in tiles:
		if floor_data != null and floor_data.has_tile(h):
			blast[h] = true
	queue_redraw()


## 0.23: the tiles an Action aimed at a tile can go to, lit faintly while it is aimed.
var aim_tiles := {}
func set_aim_tiles(tiles: Dictionary) -> void:
	aim_tiles = tiles
	queue_redraw()


func clear_blast() -> void:
	if not blast.is_empty():
		blast.clear()
		queue_redraw()


## The tile under a point in the board's own coordinates, if the floor has one.
func tile_at(local_point: Vector2) -> Variant:
	if floor_data == null:
		return null
	var h := hex_at(local_point)
	return h if floor_data.has_tile(h) else null


func tap(local_point: Vector2) -> void:
	var h = tile_at(local_point)
	if h == null:
		off_board_tapped.emit()
		return
	tile_tapped.emit(h)


## The District's ground under this floor's tiles (0.11): what you have drawn
## for it on the World Map, or nothing. (0.15: only where the District has no
## floor of its own to fight on: each of the six has.)
func ground_of() -> Array:
	if floor_data == null or floor_data.district == "" or not Art.district_board(floor_data.district, "floor_0").is_empty():
		return []
	return Art.ground.get(floor_data.district, [])


## (0.15) The District this fight is in ("" for none).
func district() -> String:
	return floor_data.district if floor_data != null else ""


## (0.15) A piece of the board, as this fight's District has it: its own floor
## plates and cover where it has them, the grey deck's otherwise.
func piece_for(name: String) -> Dictionary:
	var d := district()
	if d != "":
		var own := {}
		if name.begins_with("half_cover"):
			own = Art.district_board(d, "half_cover")
		elif name.begins_with("full_cover"):
			own = Art.district_board(d, "full_cover")
		if not own.is_empty() and own.get("texture") != null:
			return own
	return Art.board(name)


## (0.15) The plate under a tile: the District's, or the grey deck's.
func plate_for(h: Vector2i) -> Texture2D:
	var d := district()
	if d != "":
		var own := Art.district_board(d, "floor_%d" % D_FLOORS[_hash(h) % D_FLOORS.size()])
		if not own.is_empty() and own.get("texture") != null:
			return own["texture"]
	return Art.board(FLOORS[_hash(h) % FLOORS.size()]).get("texture")


## The floor's extent, tile edges included, in world units.
func extent() -> Rect2:
	if floor_data == null or floor_data.tiles.is_empty():
		return Rect2()
	var r := Rect2(at(floor_data.tiles.keys()[0]), Vector2.ZERO)
	for h in floor_data.tiles:
		var c := at(h)
		r = r.expand(c + Vector2(42, 48)).expand(c - Vector2(42, 48))
	return r


# ---------------------------------------------------------------- drawing
## A pixel-wide line along a tile's edge (1 art pixel = 2 world units).
func _outline(pts: PackedVector2Array, c: Color, w := PIXEL) -> void:
	var loop := pts.duplicate()
	loop.append(pts[0])
	draw_polyline(loop, c, w, false)


func _sprite(tex: Texture2D, top_left: Vector2, tint := Color.WHITE) -> void:
	if tex == null:
		return
	draw_set_transform(top_left, 0.0, Vector2(PIXEL, PIXEL))
	draw_texture(tex, Vector2.ZERO, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw() -> void:
	if floor_data == null:
		return
	var f := floor_data
	var ext := extent()
	# the deck plate the floor sits on, darker the farther from it, and its rim
	var plate := snap_rect(Rect2(ext.position - Vector2(48, 56), ext.size + Vector2(96, 112)))
	var far := plate.grow(640.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(PIXEL, PIXEL))
	draw_texture_rect(Art.floor_tile(), Rect2((far.position / PIXEL).floor(), (far.size / PIXEL).ceil()), true, Color(0.22, 0.23, 0.27))
	draw_texture_rect(Art.floor_tile(), Rect2((plate.position / PIXEL).floor(), (plate.size / PIXEL).ceil()), true, FLOOR_TINT)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(plate, Color("#0e0c0c"), false, PIXEL * 2.0)
	draw_rect(plate.grow(-PIXEL * 2.0), Color("#3e4246"), false, PIXEL)
	var x := plate.position.x + 16.0
	while x < plate.end.x - 8.0:
		draw_rect(Rect2(Vector2(x, plate.position.y + 6.0), Vector2(PIXEL, PIXEL)), Color("#6a7178"))
		draw_rect(Rect2(Vector2(x, plate.end.y - 8.0), Vector2(PIXEL, PIXEL)), Color("#6a7178"))
		x += 48.0
	# a railing along the far edge
	var rail_y := plate.position.y - 20.0
	draw_rect(Rect2(plate.position.x, rail_y, plate.size.x, PIXEL * 2.0), Color("#465456"))
	draw_rect(Rect2(plate.position.x, rail_y + PIXEL * 2.0, plate.size.x, PIXEL), Color("#14121d"))
	x = plate.position.x
	while x <= plate.end.x:
		draw_rect(Rect2(x, rail_y, PIXEL * 2.0, 20.0), Color("#465456"))
		draw_rect(Rect2(x + PIXEL * 2.0, rail_y, PIXEL, 20.0), Color("#14121d"))
		x += 64.0
	# each tile: a plate of the District's floor, or the grey deck's (your District's ground
	# faintly over it, where you drew one and the District has no floor of its own)
	var ground := ground_of()
	for h in f.tiles:
		var c := at(h)
		var tl := c - Vector2(42, 48)
		_sprite(plate_for(h), tl)
		if not ground.is_empty():
			draw_texture_rect(MapView.pick_from(ground, "%d,%d" % [h.x, h.y]), Rect2(tl, Vector2(84, 96)), false, GROUND_TINT)
		# a tile painted a colour that means nothing here keeps a wash of it
		var kind := tile_kind(f, h)
		var ci := f.colour_of(h)
		if kind == "" and ci >= 0 and ci < FloorData.RAINBOW.size():
			draw_colored_polygon(corners(c, 0.9), Color(FloorData.RAINBOW[ci], 0.18))
		if kind == "spawn-ally" or kind == "spawn-enemy":
			_sprite(Art.board("pad_yours" if kind == "spawn-ally" else "pad_theirs").get("texture"), tl)
		var lvl = f.tiles[h].get("lvl") if f.tiles[h] is Dictionary else null
		if kind == "spawn-enemy" and lvl != null and str(lvl) != "":
			# the Skull Level, on a small plate at the pad's foot
			var lt: String = str(int(lvl)) if (lvl is float or lvl is int) else str(lvl)
			var bp := c + Vector2(-16, 22)
			draw_rect(Rect2(bp, Vector2(32, 18)), Color("#0e0c0c"))
			draw_rect(Rect2(bp + Vector2(PIXEL, PIXEL), Vector2(28, 14)), Color("#36282b"))
			draw_set_transform(bp + Vector2(2, 1), 0.0, Vector2(1, 1))
			draw_texture_rect(Art.icon("skull"), Rect2(Vector2.ZERO, Vector2(16, 16)), false)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_string(_font, bp + Vector2(18, 15), lt, HORIZONTAL_ALIGNMENT_LEFT, -1, Look.SMALL, Color("#e8dcc4"))
	# hazards: the thing that bites, and its mark
	for h in f.hazards:
		var c2 := at(h)
		_sprite(Art.board(hazard_art(f.hazards[h])).get("texture"), c2 - Vector2(42, 48))
		var kw := str(f.hazards[h].get("keyword", "")).get_slice(" ", 0)
		var mk := Art.status_mark(kw) if kw != "" else null
		if mk != null:
			_sprite(mk, c2 + Vector2(18, -40))
	# other symbols keep their words, on a small dark plate
	for h in f.marks:
		var sk := symbol_kind(f, h)
		if sk == "" or sk == "chest" or sk == "exit":
			continue
		var c3 := at(h)
		var tw := _font.get_string_size(sk, HORIZONTAL_ALIGNMENT_LEFT, -1, Look.TITLE).x
		var r := snap_rect(Rect2(c3 + Vector2(-tw / 2.0 - 8.0, -22.0), Vector2(tw + 16.0, 40.0)))
		draw_rect(r, Color("#0e0c0c", 0.85))
		draw_rect(r, Color("#465456"), false, PIXEL)
		draw_string(_font, Vector2(r.position.x + 8.0, r.position.y + 30.0), sk, HORIZONTAL_ALIGNMENT_LEFT, -1, Look.TITLE, Color("#f1f2ff"))
	# where the Unit being moved can go (amber where the tile would bite)
	for h in reach:
		var lit := HAZARD if f.hazards.has(h) else reach_colour
		var rp := corners(at(h), 0.86)
		draw_colored_polygon(rp, Color(lit, 0.22))
		_outline(rp, Color(lit, 0.9))
	# where an Action aimed at a tile can go (0.23)
	for h in aim_tiles:
		if blast.has(h):
			continue
		var ap := corners(at(h), 0.86)
		draw_colored_polygon(ap, Color(BLAST, 0.10))
		_outline(ap, Color(BLAST, 0.55))
	# where a previewed blast would fall
	for h in blast:
		var bp2 := corners(at(h), 0.86)
		draw_colored_polygon(bp2, Color(BLAST, 0.28))
		_outline(bp2, Color(BLAST, 0.95))
	# the way it goes: a dot on each step, a ring where it ends
	if not path.is_empty():
		var pts := [at(path_from)]
		for h in path:
			pts.append(at(h))
		for i in range(1, pts.size()):
			var a: Vector2 = pts[i - 1]
			var b: Vector2 = pts[i]
			for k in range(1, 4):
				var p: Vector2 = a.lerp(b, k / 4.0).snapped(Vector2(PIXEL, PIXEL))
				draw_rect(Rect2(p - Vector2(PIXEL, PIXEL), Vector2(PIXEL * 2.0, PIXEL * 2.0)), Color("#0e0c0c"))
				draw_rect(Rect2(p - Vector2(PIXEL, PIXEL) * 0.5, Vector2(PIXEL, PIXEL)), PATH)
		var end: Vector2 = pts[pts.size() - 1]
		_outline(corners(end, 0.6), Color("#0e0c0c"), PIXEL * 2.0)
		_outline(corners(end, 0.6), PATH)


## (0.14) A wall standing on a tile edge: its face, its lit top, and where it
## meets the floor. It sorts with the Units by its middle.
class WallPiece extends Node2D:
	var a: Vector2
	var b: Vector2

	func _init(p: Vector2, q: Vector2) -> void:
		var mid := (p + q) / 2.0
		position = mid
		a = p - mid
		b = q - mid
		set_meta("wall", true)

	func _draw() -> void:
		var h := Board.WALL_H
		var t := Board.WALL_T
		var d := Vector2(0, -h)
		if absf(a.x - b.x) < 1.0:
			# an edge that runs straight back: the wall seen end-on, a pillar
			var top := minf(a.y, b.y) - h
			var r := Board.snap_rect(Rect2(Vector2(a.x - t / 2.0, top), Vector2(t, maxf(a.y, b.y) - top + 2.0)))
			draw_rect(r, Color("#282c3c"))
			draw_rect(Rect2(r.position, Vector2(r.size.x, t)), Color("#5e718e"))
			draw_rect(Rect2(r.position, Vector2(r.size.x, Board.PIXEL)), Color("#b8ccd8"))
			draw_rect(Rect2(r.position.x + r.size.x - Board.PIXEL, r.position.y + t, Board.PIXEL, r.size.y - t), Color("#1b2447"))
			return
		# the face, in panels, then the top
		draw_colored_polygon(PackedVector2Array([a + Vector2(0, 2), b + Vector2(0, 2), b + d, a + d]), Color("#282c3c"))
		var k := 4.0
		while k < h:
			draw_line(a + Vector2(0, -k), b + Vector2(0, -k), Color("#1b2447"), Board.PIXEL)
			k += 8.0
		draw_colored_polygon(PackedVector2Array([a + d, b + d, b + d + Vector2(0, -t), a + d + Vector2(0, -t)]), Color("#5e718e"))
		draw_line(a + d + Vector2(0, -t), b + d + Vector2(0, -t), Color("#b8ccd8"), Board.PIXEL)
		draw_line(a + Vector2(0, 2), b + Vector2(0, 2), Color("#0e0c0c"), Board.PIXEL)
