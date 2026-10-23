## The fight's atmosphere (0.18): what keeps a still board alive. Hazards,
## spawn pads, Emergency Exits and Healing Stations glow, breathing slowly in
## their colours; the deck's lights flicker now and then; and motes drift over
## the board: in Vantage Robotics (District 3) embers rising off the hot metal,
## ash falling, sparks spitting from its hazards and a little dust; anywhere
## else, dust.
##
## None of it touches the rules, and none of it is ever big enough to hide a
## Unit or a number. How much of it there is is a setting (Options:
## Atmosphere, Off, Subtle or Full; Subtle to begin with). The motes are the
## game's drawings (ember, spark and dust, in fx.png), or yours: the Companion's
## Effects slots hold them (ember, spark, ash, dust), and a mote of yours
## drifts in their place.
class_name Atmos
extends Node2D

const LEVELS := ["off", "subtle", "full"]
## the motes, as the art and the Companion's Effects slots name them
const MOTES := ["ember", "spark", "ash", "dust"]
const LEVEL_NAMES := {"off": "Off", "subtle": "Subtle", "full": "Full"}
## how much of each there is, by level
const MOST := {"subtle": 24, "full": 64}               # motes on the board at once, at most
const GLOW := {"subtle": [0.07, 0.16], "full": [0.14, 0.32]}   # a glow's alpha at its dimmest and brightest
const DIM := {"subtle": 0.07, "full": 0.15}            # how far a flicker dims the lights
const RINGS := 5                                       # a glow's steps, from the tile's edge in to its middle
const SPARKS := {"subtle": [2.2, 5.0], "full": [0.7, 2.2]}     # seconds between bursts of sparks
## each glow's colour
const PAD_YOURS := Color("#73efe8")
const PAD_THEIRS := Color("#ff2a3c")
const EXIT := Color("#59cf93")
const HEALING := Color("#97edca")
const HAZARD_GLOW := {"hazard_acid": Color("#8fd032"), "hazard_sparks": Color("#73efe8"), "hazard_razor": Color("#f8c53a"),
	"hazard_sludge": Color("#6e9f60"), "hazard_fire": Color("#ff7a1a")}

## The screenshots' switch: run even while the tests hold everything still.
static var allow_still := false

var board: Board
var rng := RandomNumberGenerator.new()
var glows: Array = []         # {at: Vector2, colour: Color, phase: float, hazard: bool}
var motes: Array = []         # {kind, p: Vector2, v: Vector2, age, life, frame0, flip, sway}
var t := 0.0
var veil := 0.0               # how far the lights are dimmed just now (0 to 1 of DIM)
var _flicker := 0.0           # seconds of the flicker left
var _next_flicker := 3.0
var _next_sparks := 1.0
var _emit := 0.0              # motes owed
var layer: MoteLayer          # the motes and the flicker, over the Units


func _init() -> void:
	z_index = 1               # over the floor, under the Units
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m
	layer = MoteLayer.new()
	layer.atmos = self
	layer.z_index = 2         # (relative: over the Units' layer)
	add_child(layer)


static func level() -> String:
	return Motion.atmos if LEVELS.has(Motion.atmos) else "subtle"


## Whether it runs: not at Off, and not while the tests hold the world still.
static func running() -> bool:
	return level() != "off" and (not Motion.still or allow_still)


## A new floor: its glows found, the motes cleared, and the air filled as if
## the fight had been going a while (so a fight never opens on an empty board).
func reset(b: Board) -> void:
	board = b
	glows.clear()
	motes.clear()
	t = 0.0
	veil = 0.0
	_flicker = 0.0
	var f := b.floor_data
	rng.seed = hash(f.name if f != null else "") & 0x7fffffff
	_next_flicker = rng.randf_range(2.0, 6.0)
	_next_sparks = rng.randf_range(0.5, 2.0)
	if f != null:
		for h in f.tiles:
			var kind := Board.tile_kind(f, h)
			var c := Board.at(h)
			if kind == "spawn-ally":
				glows.append({"at": c, "colour": PAD_YOURS, "phase": rng.randf() * TAU, "hazard": false})
			elif kind == "spawn-enemy":
				glows.append({"at": c, "colour": PAD_THEIRS, "phase": rng.randf() * TAU, "hazard": false})
			elif kind == "healing":
				glows.append({"at": c, "colour": HEALING, "phase": rng.randf() * TAU, "hazard": false})
			if Board.symbol_kind(f, h) == "exit":
				glows.append({"at": c, "colour": EXIT, "phase": rng.randf() * TAU, "hazard": false})
		for h in f.hazards:
			glows.append({"at": Board.at(h), "colour": HAZARD_GLOW.get(Board.hazard_art(f.hazards[h]), Color("#f8c53a")), "phase": rng.randf() * TAU, "hazard": true})
	visible = running()
	if running():
		for i in 60:
			step(1.0 / 15.0)
	queue_redraw()
	layer.queue_redraw()


func _process(delta: float) -> void:
	var on := running()
	if visible != on:
		visible = on
	if not on:
		return
	step(delta)
	queue_redraw()
	layer.queue_redraw()


## Time passing: motes move, new ones come, the lights flicker.
func step(delta: float) -> void:
	if board == null or board.floor_data == null:
		return
	var lv := level()
	if lv == "off":
		motes.clear()
		return
	t += delta
	var area := board.extent()
	if area.size == Vector2.ZERO:
		return
	var vantage := board.district() == "3"
	# the motes already in the air
	var keep := []
	for m in motes:
		m["age"] += delta
		if m["age"] >= m["life"]:
			continue
		if m["kind"] == "spark":
			m["v"].y += 260.0 * delta
		var sway: float = m["sway"] * sin(m["age"] * 2.2 + m["frame0"])
		m["p"] += (m["v"] + Vector2(sway, 0.0)) * delta
		keep.append(m)
	motes = keep
	# new ones, up to the level's count
	var most: int = MOST[lv]
	_emit += delta * most / 4.0
	while _emit >= 1.0:
		_emit -= 1.0
		if motes.size() >= most:
			continue
		var p := Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
		var roll := rng.randf()
		if vantage and roll >= 0.44 and roll < 0.88:
			motes.append({"kind": "ash", "p": p - Vector2(0, 60), "v": Vector2(rng.randf_range(-8, 8), rng.randf_range(6, 16)), "age": 0.0,
				"life": rng.randf_range(5.0, 8.0), "frame0": rng.randf() * 8.0, "flip": rng.randf() < 0.5, "sway": rng.randf_range(6, 14)})
		elif vantage and roll < 0.44:
			motes.append({"kind": "ember", "p": p, "v": Vector2(rng.randf_range(-6, 6), rng.randf_range(-30, -14)), "age": 0.0,
				"life": rng.randf_range(2.5, 5.0), "frame0": rng.randf() * 8.0, "flip": false, "sway": rng.randf_range(4, 12)})
		else:
			motes.append({"kind": "dust", "p": p, "v": Vector2(rng.randf_range(4, 12), rng.randf_range(-3, 3)), "age": 0.0,
				"life": rng.randf_range(5.0, 9.0), "frame0": rng.randf() * 8.0, "flip": false, "sway": rng.randf_range(1, 4)})
	# in Vantage, sparks spit from its hazards (or, with none, off the deck)
	if vantage:
		_next_sparks -= delta
		if _next_sparks <= 0.0:
			var gap: Array = SPARKS[lv]
			_next_sparks = rng.randf_range(gap[0], gap[1])
			var from := Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
			var hz := glows.filter(func(g): return g["hazard"])
			if not hz.is_empty():
				from = hz[rng.randi() % hz.size()]["at"]
			from += Vector2(0, -16)
			for i in rng.randi_range(3, 6):
				var vx := rng.randf_range(-70, 70)
				motes.append({"kind": "spark", "p": from, "v": Vector2(vx, rng.randf_range(-110, -40)), "age": 0.0,
					"life": rng.randf_range(0.45, 0.85), "frame0": 0.0, "flip": vx < 0.0, "sway": 0.0})
	# the lights: steady, then now and then a stutter
	_next_flicker -= delta
	if _next_flicker <= 0.0:
		_flicker = rng.randf_range(0.25, 0.6)
		_next_flicker = rng.randf_range(3.0, 8.0)
	if _flicker > 0.0:
		_flicker -= delta
		veil = 1.0 if fmod(t * 23.0, 1.0) < 0.45 else 0.3
	else:
		veil = maxf(0.0, veil - delta * 6.0)


## A glow's strength now (0 to 1), breathing slowly.
func breath(g: Dictionary) -> float:
	return 0.5 + 0.5 * sin(t * (1.6 if g["hazard"] else 1.1) + float(g["phase"]))


func _draw() -> void:
	if board == null or glows.is_empty():
		return
	var lv := level()
	if lv == "off":
		return
	var span: Array = GLOW[lv]
	for g in glows:
		var a: float = lerpf(span[0], span[1], breath(g))
		var c: Color = g["colour"]
		# soft: hexagons one inside another, each adding a little, so the light
		# is strongest in the middle and fades toward the tile's edge
		for i in RINGS:
			var k := 1.0 - float(i) / RINGS
			draw_colored_polygon(Board.corners(g["at"], 0.95 * k), Color(c, a / RINGS * 1.6))


## A mote's picture now: its frames looped at its speed.
func frame_for(m: Dictionary, fx: Dictionary) -> Texture2D:
	var frames: Array = fx.get("frames", [])
	if frames.is_empty():
		return null
	if m["kind"] == "spark":
		return frames[mini(frames.size() - 1, int(m["age"] / m["life"] * frames.size()))]
	return frames[int(m["age"] * float(fx["fps"]) + m["frame0"]) % frames.size()]


## The motes, and the lights' flicker, drawn over the Units.
class MoteLayer extends Node2D:
	var atmos: Atmos

	func _ready() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _draw() -> void:
		if atmos == null or atmos.board == null:
			return
		var lv := Atmos.level()
		if lv == "off":
			return
		if atmos.veil > 0.0:
			draw_rect(atmos.board.extent().grow(640.0), Color(0.03, 0.02, 0.05, atmos.veil * float(Atmos.DIM[lv])))
		var px := Board.PIXEL
		var looks := {}
		for m in atmos.motes:
			var k: String = m["kind"]
			if not looks.has(k):
				looks[k] = Art.fx(k)
			var fx: Dictionary = looks[k]
			var tex := atmos.frame_for(m, fx)
			if tex == null:
				continue
			var life: float = m["life"]
			var age: float = m["age"]
			# in over the first quarter second, out over the last part of its life
			var a := minf(1.0, age / 0.25) * minf(1.0, (life - age) / (0.35 if k == "spark" else 1.2))
			if k == "dust":
				a *= 0.7
			var sz: Vector2 = fx["size"] * px
			var at: Vector2 = (m["p"] - fx["anchor"] * px).snapped(Vector2(px, px))
			var r := Rect2(at, sz)
			if m["flip"]:
				r = Rect2(at + Vector2(sz.x, 0), Vector2(-sz.x, sz.y))
			draw_texture_rect(tex, r, false, Color(1, 1, 1, a))
