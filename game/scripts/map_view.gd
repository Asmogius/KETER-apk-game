## The World Map, drawn (0.15): every tile on its District's ground, in hex
## pixels, darker the farther out; thin dark edges between the tiles, a light
## line along each District's border and light dashes at each rise in Skull
## Level; collapsed structure as rubble; a few of each District's things
## standing on its empty tiles; ground the Strike Team hasn't seen yet dimmed
## under faint scanlines; what a tile holds, once known, as an icon on a plate;
## the dock as the Hangar, lit; and the team itself, its leader standing on a
## lit base, with the way to the tile you chose as a line of dots.
##
## Where the export carries map art from the Pixel Studio (a District's
## ground, its things, an icon, the Hangar, rubble), it takes the place of the
## game's own.
class_name MapView
extends Node2D

signal tile_tapped(key: String)

const S := 3.0                   # (0.15) screen pixels to a hex pixel's corner at the usual zoom
const SIZE := 43.07              # a hex, centre to corner: the ground's hexagon at that zoom
const DOCK_COLOUR := Color("#dceaee")
const BLOCKED := Color("#14121d")
const INK := Color("#0e0c0c")
const TEAM := Color("#73efe8")
const STEP_TIME := 0.14          # seconds a step takes to show
const ART_SCALE := 2.0           # what stands on the map: at twice its pixels, as in a fight
const UNKNOWN := 0.55            # how bright ground not yet seen is
const PROP_SHARE := 5            # one empty tile in this many has something standing on it
const APRON := Vector2(32, 18)   # where the leader stands at the dock: before the Hangar, right of its door

var world: World = null
var selected := ""
var route: Array = []            # the way to the selected tile, both ends included
var team_at := ""                # where the Strike Team stands, or "" with none out
var token: Texture2D = null      # the team's marker: its first standing Hero
var token_hex := false           # (0.15) whether that token is hex pixels (fitted to a token's width)
var marker: Marker
var _marker_from := Vector2.ZERO
var _marker_to := Vector2.ZERO
var _tween: Tween = null
var _scan: ImageTexture = null
var _drawn_zoom := 1.0           # (0.15) the zoom it was last drawn at: lines and icons keep their size on the screen


## The team's marker, the chosen tile and the way to it: drawn apart from the
## tiles, so a step redraws only this. Its base pulses, slowly.
class Marker extends Node2D:
	var view: MapView
	var at := Vector2.ZERO
	var pulse := 0.0

	func _process(delta: float) -> void:
		if view != null and view.team_at != "" and is_visible_in_tree():
			pulse = fmod(pulse + delta / 1.6, 1.0)
			queue_redraw()

	func _draw() -> void:
		if view == null or view.world == null:
			return
		var s := MapView.SIZE
		# the way there: dots, dark-rimmed
		if view.route.size() > 1:
			for i in range(1, view.route.size()):
				var a := view.centre_of(view.route[i - 1])
				var b := view.centre_of(view.route[i])
				for f in [0.25, 0.5, 0.75]:
					var p: Vector2 = a.lerp(b, f)
					draw_circle(p, 4.0, MapView.INK)
					draw_circle(p, 2.5, MapView.TEAM)
		if view.selected != "":
			var pts := Hex.corners(view.centre_of(view.selected), s - 2.0)
			pts.append(pts[0])
			draw_polyline(pts, Color("#f1f2ff"), 3.0)
		if view.team_at != "":
			# a lit base, a ring going out from it, and the leader standing on it (at the
			# dock, on the Hangar's apron, beside its door, so the Hangar still shows)
			var o := at + (APRON if view.team_at == view.world.dock() else Vector2.ZERO)
			var k := 1.0 + pulse * 0.5
			_ellipse(o + Vector2(0, 2), Vector2(26, 9) * k, Color(MapView.TEAM, 0.55 * (1.0 - pulse)), 2.0, false)
			_ellipse(o + Vector2(0, 4), Vector2(25, 9), Color("#14121d", 0.86), 0.0, true)
			_ellipse(o + Vector2(0, 4), Vector2(25, 9), MapView.TEAM, 3.0, false)
			if view.token != null:
				# as a fight stands it: a 48 token at the map's pixel scale, a smaller one at whole steps
				var raw := view.token.get_size()
				var kk := 48.0 / maxf(1.0, raw.x) if view.token_hex else maxf(1.0, floorf(48.0 / maxf(raw.x, raw.y)))
				var ts := raw * kk * MapView.ART_SCALE
				var feet := o + Vector2(0, 10.0)
				draw_texture_rect(view.token, Rect2(feet - Vector2(ts.x / 2.0, ts.y - 2.0 * kk * MapView.ART_SCALE), ts), false)
			else:
				draw_circle(o, s * 0.4, MapView.TEAM)
				draw_circle(o, s * 0.16, MapView.INK)

	func _ellipse(c: Vector2, r: Vector2, col: Color, width: float, filled: bool) -> void:
		var pts := PackedVector2Array()
		for i in 33:
			var a := TAU * i / 32.0
			pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
		if filled:
			draw_colored_polygon(pts, col)
		else:
			draw_polyline(pts, col, width)


func _init() -> void:
	marker = Marker.new()
	marker.view = self
	add_child(marker)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## (0.15) Drawn again when the zoom changes: its lines stay thin, and what
## tiles hold stays big enough to read.
func _process(_delta: float) -> void:
	if world != null and is_visible_in_tree() and absf(_zoom() - _drawn_zoom) > 0.02:
		queue_redraw()


## Puts a map up. data: the export, whose map art (if any) Art has read.
func show_world(w: World, _data: KeterExport = null) -> void:
	world = w
	selected = ""
	route = []
	refresh()


## Everything is drawn again: something has been seen, cleared or chosen.
func refresh() -> void:
	queue_redraw()
	marker.queue_redraw()


func centre_of(k) -> Vector2:
	return Hex.to_pixel(World.parse(k), SIZE)


## The tile under a point of the map, or "" outside it.
func key_at(local: Vector2) -> String:
	if world == null:
		return ""
	var h := Hex.from_pixel(local, SIZE)
	if maxi(maxi(absi(h.x), absi(h.y)), absi(h.x + h.y)) > world.radius():
		return ""
	return World.key(h.x, h.y)


func tap(local: Vector2) -> void:
	var k := key_at(local)
	if k != "":
		tile_tapped.emit(k)


## The whole map, for fitting it on the screen.
func bounds() -> Rect2:
	var r := (world.radius() if world != null else 18) + 1
	var w := Hex.SQ3 * SIZE * (2 * r + 1)
	var h := 1.5 * SIZE * (2 * r) + 2 * SIZE
	return Rect2(-w / 2.0, -h / 2.0, w, h)


# ---------------------------------------------------------------- the team's marker
## Where the team stands, at once.
func place_team(k: String) -> void:
	team_at = k
	if _tween != null:
		_tween.kill()
		_tween = null
	if k != "":
		marker.at = centre_of(k)
	marker.queue_redraw()


## One step, shown: the marker slides to the next tile. Await `stepped`.
signal stepped
func step_team(k: String, time := STEP_TIME) -> void:
	team_at = k
	_marker_from = marker.at
	_marker_to = centre_of(k)
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_slide, 0.0, 1.0, maxf(0.01, time))
	_tween.tween_callback(func(): stepped.emit())


func _slide(t: float) -> void:
	marker.at = _marker_from.lerp(_marker_to, t)
	marker.queue_redraw()


# ---------------------------------------------------------------- drawing
## The same picture for the same tile, every time (assets.js's pickFrom).
static func pick_from(list: Array, tile_key: String) -> Variant:
	if list.is_empty():
		return null
	var h := 0
	for i in tile_key.length():
		h = (h * 31 + tile_key.unicode_at(i)) & 0xFFFFFFFF
	return list[h % list.size()]


## (0.15) A tile's ground: its picture clipped to the tile's hexagon. f: how
## bright (darker farther out, and where nobody has looked).
func _ground(tile: Dictionary, c: Vector2, f: float) -> void:
	var tex: Texture2D = tile["texture"]
	var col := Color(f, f, f)
	if tile.get("rect", false):
		# a picture of yours that isn't a hexagon of hex pixels: over the tile, as it is
		var w := Hex.SQ3 * SIZE * 1.02
		var h := 2.0 * SIZE * 1.02
		draw_texture_rect(tex, Rect2(c.x - w / 2.0, c.y - h / 2.0, w, h), false, col)
		return
	var pts := Hex.corners(c, SIZE)
	# where the hexagon's corners fall in the picture: its middle, CLIP corner-lengths out
	var sr := (Hex.SQ3 * float(int(tile.get("side", 9)) - 1) + 0.5) * float(tile["s"])
	var uvs := PackedVector2Array()
	var atlas := tex
	var region := Rect2(Vector2.ZERO, tex.get_size())
	if tex is AtlasTexture:
		atlas = (tex as AtlasTexture).atlas
		region = (tex as AtlasTexture).region
	var full := atlas.get_size()
	var mid: Vector2 = tile["mid"]
	for i in 6:
		var a := deg_to_rad(60.0 * i - 30.0)
		var p := region.position + mid + Vector2(cos(a), sin(a)) * sr
		uvs.append(p / full)
	draw_polygon(pts, PackedColorArray([col, col, col, col, col, col]), uvs, atlas)


## Faint scanlines over a tile (what the team hasn't seen yet).
func _scanlines(c: Vector2) -> void:
	if _scan == null:
		var img := Image.create(1, 3, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		img.set_pixel(0, 0, Color(0, 0, 0, 0.32))
		_scan = ImageTexture.create_from_image(img)
	var pts := Hex.corners(c, SIZE)
	var uvs := PackedVector2Array()
	for p in pts:
		uvs.append(Vector2(p.x, p.y / 3.0))
	draw_polygon(pts, PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]), uvs, _scan)


## How far in the map is drawn: 1 at the usual zoom.
func _zoom() -> float:
	return maxf(0.05, get_global_transform_with_canvas().get_scale().x) if is_inside_tree() else 1.0


func _draw() -> void:
	if world == null:
		return
	var s := SIZE
	var r := world.radius()
	var dock := world.dock()
	var z := _zoom()
	_drawn_zoom = z
	var far := z < 0.45                       # the whole map: lighter lines, lighter shade
	var dim := UNKNOWN if not far else 0.7
	var skulls := {}
	var districts := {}
	var stand := []                           # what stands on tiles, drawn after the ground, back to front
	var known_any := world.known_count() > 0
	var rubble := Art.rubble()
	var grounds := {}
	var things := {}
	# the ground
	for q in range(-r, r + 1):
		for rr in range(maxi(-r, -q - r), mini(r, -q + r) + 1):
			var k := World.key(q, rr)
			var c := Hex.to_pixel(Vector2i(q, rr), s)
			var t = world.tile(k)
			if t == null:
				var rub = pick_from(rubble, k)
				if rub != null:
					_ground(rub, c, 0.8)
				else:
					draw_colored_polygon(Hex.corners(c, s), BLOCKED)
				continue
			var sk := world.skull_of(k)
			skulls[k] = sk
			var d := world.district_of(k)
			districts[k] = d
			if not grounds.has(d):
				grounds[d] = Art.map_ground(d)
			var seen: bool = k == dock or world.known(k) or not known_any
			var f := (1.0 - 0.07 * (sk - 1)) * (1.0 if seen else dim)
			var g = pick_from(grounds[d], k)
			if g != null:
				_ground(g, c, f)
			else:
				var col := Color(World.DCOL.get(d, World.DCOL[""]))
				draw_colored_polygon(Hex.corners(c, s), Color(col.r * f, col.g * f, col.b * f))
			if not seen:
				_scanlines(c)
			# a District's things, on one empty tile in five
			if k != dock and world.content_at(k) == null and d != "" and _hash(k + "p") % PROP_SHARE == 0:
				if not things.has(d):
					things[d] = Art.map_props(d)
				var pr = pick_from(things[d], k)
				if pr != null and pr["texture"] != null:
					stand.append({"y": c.y, "prop": pr, "c": c, "f": (1.0 if seen else dim)})
	# thin dark edges round every tile (fainter when the whole map is in view)
	var edge := Color(INK.r, INK.g, INK.b, 0.25 if far else 0.6)
	for k in skulls:
		var pts := Hex.corners(centre_of(k), s)
		pts.append(pts[0])
		draw_polyline(pts, edge, -1.0)
	# each District's border, a light line; each rise in Skull Level, light dashes
	var border := Color(0.945, 0.95, 1.0, 0.45)
	var rise := Color(1.0, 0.94, 0.54, 0.45 if far else 0.6)
	var lw := (1.0 if far else 2.0) / z
	for k in skulls:
		var a := World.parse(k)
		for i in 6:
			var n := World.key(a.x + Hex.DIRS[i].x, a.y + Hex.DIRS[i].y)
			if not skulls.has(n):
				continue
			var e := Hex.shared_edge(a, a + Hex.DIRS[i], s)
			if e.size() != 2:
				continue
			if str(n) > str(k) and districts[k] != districts[n] and districts[k] != "" and districts[n] != "":
				draw_line(e[0], e[1], border, lw)
			if skulls[n] > skulls[k]:
				for f in [0.12, 0.44, 0.76]:
					draw_line(e[0].lerp(e[1], f), e[0].lerp(e[1], f + 0.16), rise, lw)
	# what tiles hold, where known, on plates; the dock, the Hangar; things standing
	for k in skulls:
		var is_dock: bool = k == dock
		var c := centre_of(k)
		if is_dock:
			var hg := Art.hangar()
			if not hg.is_empty():
				stand.append({"y": c.y + 0.5, "hangar": hg, "c": c})
			else:
				_glyph("dock", c, INK)
			continue
		var content = world.content_at(k)
		if content == null or not world.known(k):
			continue
		# (0.38) a District Core wears the Unique POI's star
		var kind := "unique" if content.get("unique") is Dictionary or Rules.truthy(content.get("core")) else str(content["kind"])
		stand.append({"y": c.y + 0.25, "icon": kind, "c": c, "cleared": world.is_cleared(k)})
	stand.sort_custom(func(a, b): return a["y"] < b["y"])
	for e in stand:
		var c: Vector2 = e["c"]
		if e.has("prop"):
			var pr: Dictionary = e["prop"]
			var tex: Texture2D = pr["texture"]
			var ts := tex.get_size() * ART_SCALE
			var foot: Vector2 = pr["foot"] * ART_SCALE
			draw_texture_rect(tex, Rect2(c + Vector2(0, 10) - foot, ts), false, Color(e["f"], e["f"], e["f"]))
		elif e.has("hangar"):
			var hg: Dictionary = e["hangar"]
			var tex: Texture2D = hg["texture"]
			if hg.get("rect", false):
				var w := Hex.SQ3 * s
				draw_texture_rect(tex, Rect2(c.x - w / 2.0, c.y - s, w, 2.0 * s), false)
			else:
				var ts := tex.get_size() * ART_SCALE
				draw_texture_rect(tex, Rect2(c + Vector2(0, 20) - hg["foot"] * ART_SCALE, ts), false)
		else:
			_icon(e["icon"], c, 0.3 if e["cleared"] else 1.0, maxf(1.0, 0.5 / z))


## (0.15) What a tile holds: its icon, on a dark plate in its colour.
func _icon(kind: String, c: Vector2, alpha: float, k := 1.0) -> void:
	var ic := Art.map_icon(kind)
	if ic.is_empty() or ic["texture"] == null:
		_glyph(kind, c, Color(INK.r, INK.g, INK.b, alpha))
		return
	var tex: Texture2D = ic["texture"]
	if ic.get("rect", false):
		var w := Hex.SQ3 * SIZE
		draw_texture_rect(tex, Rect2(c.x - w / 2.0, c.y - SIZE, w, 2.0 * SIZE), false, Color(1, 1, 1, alpha))
		return
	# (k: larger when the map is far off, so it can still be read)
	var pts := Hex.corners(c, 20.0 * k)
	draw_colored_polygon(pts, Color("#14121d", 0.92 * alpha))
	pts.append(pts[0])
	var rim: Color = ic["plate"]
	draw_polyline(pts, Color(rim, alpha), 2.0 * k)
	var ts := tex.get_size() * ART_SCALE * k
	draw_texture_rect(tex, Rect2(c - ts / 2.0, ts), false, Color(1, 1, 1, alpha))


static func _hash(s: String) -> int:
	var h := 0
	for i in s.length():
		h = (h * 31 + s.unicode_at(i)) & 0xFFFFFFFF
	return h


## A shape for what a tile holds, where there is no picture for it: a house for
## the dock, a diamond for a POI, a star for a Unique POI, a box for a Cache,
## "!" for an Ambush and "?" for an Event.
func _glyph(kind: String, c: Vector2, ink: Color) -> void:
	var s := SIZE
	match kind:
		"dock":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.5), c + Vector2(s * 0.5, -s * 0.05), c + Vector2(s * 0.34, -s * 0.05), c + Vector2(s * 0.34, s * 0.42),
				c + Vector2(-s * 0.34, s * 0.42), c + Vector2(-s * 0.34, -s * 0.05), c + Vector2(-s * 0.5, -s * 0.05)]), ink)
		"poi":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.5), c + Vector2(s * 0.42, 0), c + Vector2(0, s * 0.5), c + Vector2(-s * 0.42, 0)]), ink)
		"unique":
			var pts := PackedVector2Array()
			for i in 10:
				var a := -PI / 2.0 + i * PI / 5.0
				pts.append(c + Vector2(cos(a), sin(a)) * s * (0.52 if i % 2 == 0 else 0.22))
			draw_colored_polygon(pts, ink)
		"cache":
			draw_rect(Rect2(c - Vector2(s * 0.34, s * 0.3), Vector2(s * 0.68, s * 0.6)), ink, false, s * 0.12)
			draw_line(c + Vector2(-s * 0.34, -s * 0.06), c + Vector2(s * 0.34, -s * 0.06), ink, s * 0.1)
		"ambush", "event":
			var font := Look.font()
			var size := Look.fs(s * 1.05)
			var word := "!" if kind == "ambush" else "?"
			var w := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			draw_string(font, c + Vector2(-w / 2.0, s * 0.36), word, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ink)
