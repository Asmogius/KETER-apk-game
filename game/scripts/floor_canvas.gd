## The POI Sandbox's map (0.29): a floor being edited (poi_model.gd), drawn
## on the hexagon it may fill, for a thumb. One finger draws with the tool in
## hand; two pinch and pan it (a mouse: the wheel zooms, the right button
## pans). Move turns one finger into panning too. Drawn small and still, it is
## a floor's picture in the list.
class_name FloorCanvas
extends Control

## A stroke with the tool: "begin", "move", "end", or "cancel" (a second
## finger came down: what the stroke did is to be undone).
signal stroke(phase: String, at: Vector2)

const BASE := 26.0
const ZOOM_MIN := 0.25
const ZOOM_MAX := 4.0
const GROUND := Color("#0d1216")
const GRID := Color("#24303a")
const TILE := Color("#3a454d")
const TILE_EDGE := Color("#566570")
const PALE_WALL := Color("#e3e9ec")
const PREVIEW := Color("#73efe8")
const HAZARD := Color("#ff2a3c")

var st := {}                   # the floor (PoiModel's)
var still := false             # a picture only: no grid, no touch
var pan_only := false          # Move: one finger pans
var zoom := 1.0
var origin := Vector2.ZERO     # where the centre tile sits, in the canvas
var preview: Array = []        # tiles a shape would change
var preview_edges: Array = []  # [a, b] edges a wall stroke would change
var mirror = null              # {pivot, axis}, or null
var ruler: Array = []          # [from, to] while measuring
var _font: Font
var _touches := {}
var _pinch := 0.0
var _stroking := -2            # the finger drawing (-1 the mouse), or -2
var _panning := false
var _fitted := false


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = Look.font()
	resized.connect(func():
		if not _fitted or still:
			fit())


func show_floor(s: Dictionary, refit := true) -> void:
	st = s
	if refit:
		_fitted = false
		fit()
	queue_redraw()


func size_px() -> float:
	return BASE * zoom


## The whole hexagon (a picture: its tiles) in view.
func fit() -> void:
	if st.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return
	var hs: Array = st["hexes"].keys() if still and not st["hexes"].is_empty() else PoiModel.cells(st)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for h in hs:
		var p := Hex.to_pixel(h, BASE)
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	var span := hi - lo + Vector2(BASE * 2.0, BASE * 2.2)
	zoom = clampf(minf(size.x / span.x, size.y / span.y) * 0.96, ZOOM_MIN if not still else 0.02, ZOOM_MAX)
	origin = size / 2.0 - (lo + hi) / 2.0 * zoom
	_fitted = true
	queue_redraw()


func at(h: Vector2i) -> Vector2:
	return origin + Hex.to_pixel(h, size_px())


func hex_at(p: Vector2) -> Vector2i:
	return Hex.from_pixel(p - origin, size_px())


## The edge nearest a point: [the tile it is in, the one across that edge].
func edge_at(p: Vector2) -> Array:
	var a := hex_at(p)
	var v := p - at(a)
	var ang := fposmod(rad_to_deg(v.angle()), 360.0)
	var i := int(round(ang / 60.0)) % 6
	return [a, a + Hex.DIRS[i]]


func zoom_at(f: float, p: Vector2) -> void:
	var z := clampf(zoom * f, ZOOM_MIN, ZOOM_MAX)
	origin = p - (p - origin) * (z / zoom)
	zoom = z
	queue_redraw()


func pan(by: Vector2) -> void:
	origin += by
	queue_redraw()


# ---------------------------------------------------------------- touch
func _gui_input(e: InputEvent) -> void:
	if still:
		return
	if e is InputEventScreenTouch:
		if e.pressed:
			_touches[e.index] = e.position
			if _touches.size() == 1:
				if pan_only:
					_panning = true
				else:
					_stroking = e.index
					stroke.emit("begin", e.position)
			elif _touches.size() == 2:
				if _stroking != -2:
					_stroking = -2
					stroke.emit("cancel", e.position)
				_panning = false
				_pinch = _two_distance()
		else:
			_touches.erase(e.index)
			if e.index == _stroking:
				_stroking = -2
				stroke.emit("end", e.position)
			if _touches.is_empty():
				_panning = false
			elif _touches.size() == 2:
				_pinch = _two_distance()
		accept_event()
	elif e is InputEventScreenDrag:
		var prev: Vector2 = _touches.get(e.index, e.position)
		_touches[e.index] = e.position
		if _touches.size() >= 2:
			var d := _two_distance()
			var mid := _two_mid()
			if _pinch > 0.0:
				zoom_at(d / _pinch, mid)
			pan((e.position - prev) / 2.0)
			_pinch = d
		elif e.index == _stroking:
			stroke.emit("move", e.position)
		elif _panning:
			pan(e.relative)
		accept_event()
	elif e is InputEventMouseButton and e.device != InputEvent.DEVICE_ID_EMULATION:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			zoom_at(1.12, e.position)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			zoom_at(1.0 / 1.12, e.position)
		elif e.button_index == MOUSE_BUTTON_RIGHT or e.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = e.pressed
		elif e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				if pan_only:
					_panning = true
				else:
					_stroking = -1
					stroke.emit("begin", e.position)
			else:
				_panning = false
				if _stroking == -1:
					_stroking = -2
					stroke.emit("end", e.position)
		accept_event()
	elif e is InputEventMouseMotion and e.device != InputEvent.DEVICE_ID_EMULATION:
		if _stroking == -1:
			stroke.emit("move", e.position)
		elif _panning:
			pan(e.relative)
		accept_event()
	elif e is InputEventMagnifyGesture:
		zoom_at(e.factor, e.position)
		accept_event()


func _two_distance() -> float:
	var v := _touches.values()
	return (v[0] as Vector2).distance_to(v[1]) if v.size() >= 2 else 0.0


func _two_mid() -> Vector2:
	var v := _touches.values()
	return ((v[0] as Vector2) + (v[1] as Vector2)) / 2.0 if v.size() >= 2 else Vector2.ZERO


# ---------------------------------------------------------------- drawing
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), GROUND)
	if st.is_empty():
		return
	var s := size_px()
	var view := Rect2(Vector2(-s * 2, -s * 2), size + Vector2(s * 4, s * 4))
	if not still:
		for h in PoiModel.cells(st):
			var c := at(h)
			if view.has_point(c) and not st["hexes"].has(h):
				_outline(Hex.corners(c, s * 0.97), GRID, 1.0)
	var labels: Dictionary = st["colorLabels"]
	var hazards := {}
	for d in st["symDefs"]:
		if PoiModel.is_hazard(d):
			hazards[int(d["id"])] = true
	for h in st["hexes"]:
		var c := at(h)
		if not view.has_point(c):
			continue
		var pts := Hex.corners(c, s * (1.0 if still else 0.97))
		var t: Dictionary = st["hexes"][h]
		var fill := TILE
		if t.get("c") != null and int(t["c"]) >= 0 and int(t["c"]) < 6:
			fill = FloorData.RAINBOW[int(t["c"])]
		draw_colored_polygon(pts, fill)
		if not still:
			_outline(pts, TILE_EDGE if t.get("c") == null else fill.lightened(0.35), 1.0)
		if hazards.has(int(st["marks"].get(h, -999))):
			draw_colored_polygon(Hex.corners(c, s * 0.62), Color(HAZARD, 0.55))
		if not still and Rules.truthy(t.get("lvl")) and s >= 12.0:
			_text(c + Vector2(0, s * 0.62), str(t["lvl"]), Color("#ffffff"), maxi(10, int(s * 0.5)))
	if not still and s >= 10.0:
		for h in st["marks"]:
			var d := PoiModel.sym(st, int(st["marks"][h]))
			if d.is_empty():
				continue
			_plate(at(h), PoiModel.sym_text(d), maxi(10, int(s * 0.62)), hazards.has(int(d["id"])))
	for k in st["walls"]:
		var e := PoiModel.wall_ends(k)
		if e.is_empty():
			continue
		var pts := Hex.shared_edge(e[0], e[1], s)
		if pts.size() < 2:
			continue
		var cid := int(st["walls"][k])
		var col := PALE_WALL if cid < 0 or cid > 5 else FloorData.RAINBOW[cid]
		draw_line(pts[0] + origin, pts[1] + origin, Color("#05080a"), maxf(2.0, s * 0.30))
		draw_line(pts[0] + origin, pts[1] + origin, col, maxf(1.5, s * 0.18))
	if still:
		return
	for h in preview:
		_outline(Hex.corners(at(h), s * 0.86), PREVIEW, 2.0)
	for ed in preview_edges:
		var pts := Hex.shared_edge(ed[0], ed[1], s)
		if pts.size() == 2:
			draw_line(pts[0] + origin, pts[1] + origin, PREVIEW, maxf(2.0, s * 0.2))
	if mirror is Dictionary:
		var p := at(mirror["pivot"])
		var dirs := [Vector2i(1, 1), Vector2i(1, -2), Vector2i(-2, 1)]
		var dv := Hex.to_pixel(dirs[int(mirror["axis"]) % 3], s).normalized()
		var reach := size.length()
		var a := p - dv * reach
		var steps := int(reach * 2.0 / 18.0)
		for i in steps:
			if i % 2 == 0:
				draw_line(a + dv * (i * 18.0), a + dv * ((i + 1) * 18.0), Color("#f8c53a", 0.85), 2.0)
		draw_circle(p, maxf(4.0, s * 0.22), Color("#f8c53a"))
	if ruler.size() == 2:
		var a2 := at(ruler[0])
		var b2 := at(ruler[1])
		draw_line(a2, b2, Color("#f8c53a"), 3.0)
		draw_circle(a2, 5.0, Color("#f8c53a"))
		draw_circle(b2, 5.0, Color("#f8c53a"))
		_plate(b2 + Vector2(0, -s * 1.1), "%d tiles" % Hex.distance(ruler[0], ruler[1]), Look.SMALL, false)


func _outline(pts: PackedVector2Array, col: Color, w: float) -> void:
	var loop := pts.duplicate()
	loop.append(pts[0])
	draw_polyline(loop, col, w)


func _text(c: Vector2, t: String, col: Color, fs: int) -> void:
	var w := _font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(_font, c + Vector2(-w / 2.0, fs * 0.35), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _plate(c: Vector2, t: String, fs: int, bad: bool) -> void:
	var w := _font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var r := Rect2(c + Vector2(-w / 2.0 - 4.0, -fs * 0.55), Vector2(w + 8.0, fs * 1.1))
	draw_rect(r, Color("#0e0c0c", 0.85))
	draw_rect(r, HAZARD if bad else Color("#465456"), false, 1.0)
	draw_string(_font, Vector2(r.position.x + 4.0, c.y + fs * 0.32), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#f1f2ff"))
