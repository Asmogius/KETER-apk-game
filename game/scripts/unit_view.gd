## One Unit on the board. (0.14) It stands on its tile: its 48 by 48 token at
## the board's pixel scale, a shadow under its feet, a ring round them in its
## side's colour (cyan for yours, red for Enemies), its Health as pips under
## the ring, each status a small mark by its head, a gold sight at its other
## side while it holds fire. A Unit with no token of its own stands in as a
## dark shape of its kind. Dimmed once it has moved this round.
##
## What it draws (Health, statuses, holding) is what it was last shown, not
## the Unit as it is this instant: an Enemy's whole turn is worked out at once
## and then played back a beat at a time, each beat showing how things stood.
class_name UnitView
extends Node2D

signal walked

const ALLY := Color("#73efe8")
const ALLY_SEL := Color("#dceaee")
const ENEMY := Color("#ff2a3c")
const ENEMY_SEL := Color("#fdc9c9")
const STEP_TIME := 0.16
## (0.14) where its feet stand, from the tile's centre (world units)
const FOOT := Vector2(0, 14)
const PX := 2.0
## Each status its own shade, as in the simulator.
const STATUS_DOT := {"rooted": "#b08a5a", "stunned": "#f2e46d", "slowed": "#8fb6d9", "marked": "#ff8c42",
	"pinned": "#c77dff", "poisoned": "#7bd88f", "bleed": "#d94f5c", "weakened": "#a0a0a0",
	"sundered": "#8a6a50", "drained": "#5a7bd9", "evasive": "#e0e0e0",
	"half cover": "#6fd0c0", "full cover": "#3fb0a0"}
const FLASH_SHADER := "shader_type canvas_item;\nuniform float flash = 0.0;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV) * COLOR;\n\tCOLOR = vec4(mix(c.rgb, vec3(1.0), flash), c.a);\n}\n"

static var _flash_shader: Shader = null

var unit: Dictionary
var shown := {}                # hp, hpMax, statuses, holding, down: what is drawn
var look: Dictionary
var size := 48.0
var selected := false
var dim := false
var acting := false            # an Enemy taking its turn, ringed in gold
var targeted := false          # one you could aim at now
var caught := false            # in the blast of the area Action being previewed
var step_time := STEP_TIME
var token: Sprite2D
var front: Node2D              # (0.14) the near half of the ring, over the token's feet
var standing_in := ""          # (0.14) the stand-in's kind, when it has no token
var gone := false               # faded away, down
var _font: Font
var _tween: Tween
var _fade: Tween
## (0.12) how high it is off the board, mid-hop
var lift := 0.0:
	set(v):
		lift = v
		if token != null:
			token.position = Vector2(0, -v)
		queue_redraw()
		if front != null:
			front.queue_redraw()
## (0.14) how white it is, as it is struck (0 to 1)
var flash := 0.0:
	set(v):
		flash = v
		if token != null and token.material != null:
			(token.material as ShaderMaterial).set_shader_parameter("flash", v)
var bits: Array = []            # (0.12) the pieces it crumbles into as it goes down


func setup(u: Dictionary, lk: Dictionary, hex_size: float) -> void:
	unit = u
	look = lk
	size = hex_size
	_font = Look.font()
	token = Sprite2D.new()
	token.centered = false
	token.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _flash_shader == null:
		_flash_shader = Shader.new()
		_flash_shader.code = FLASH_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _flash_shader
	token.material = mat
	add_child(token)
	var tex: Texture2D = lk.get("texture")
	if tex == null:
		standing_in = stand_in_kind(u)
		tex = Art.standin(standing_in)
	token.texture = tex
	_fit_token()
	front = Node2D.new()
	front.draw.connect(_draw_front)
	add_child(front)
	position = Board.at(Battle.tile_of(u))
	show_state(u)


## A Unit with no token stands in as one of four shapes: drone, beast, ranged or melee.
static func stand_in_kind(u: Dictionary) -> String:
	var words := (str(u.get("name", "")) + " " + str(u.get("cardType", ""))).to_lower()
	if "drone" in words or "copter" in words:
		return "drone"
	if "hound" in words or "dog" in words or "spider" in words or "beast" in words or "crawl" in words:
		return "beast"
	for a in (u.get("actions") if u.get("actions") is Array else []):
		if a is Dictionary and str(a.get("role", "")).to_lower() == "ranged":
			return "ranged"
	return "melee"


## Takes what to draw from a Unit as it is now, or as it stood after a beat.
func show_state(d: Dictionary) -> void:
	shown = {"hp": d.get("hp"), "hpMax": d.get("hpMax"), "statuses": (d.get("statuses") if d.get("statuses") != null else []).duplicate(true),
		"holding": d.get("holding") != null, "down": Rules.truthy(d.get("down")),
		"guards": (d["guards"].keys() if d.get("guards") is Dictionary else [])}
	refresh()


## The colour of a status's dot (and of its name in the side panel).
static func status_colour(name: String) -> Color:
	return Color(STATUS_DOT.get(name.to_lower(), "#d94f5c"))


## (0.14) Stands the token on its feet, at a whole number of the board's pixels
## for each of its own (a 48 token at 1, a 24 at 2, a 16 at 3). A picture of
## hex pixels is fitted to the token's width.
func _fit_token() -> void:
	var tex: Texture2D = token.texture
	if tex == null:
		return
	var ts := tex.get_size()
	var k := 1.0
	if look.get("hexagon", false):
		k = 48.0 / maxf(1.0, ts.x)
	else:
		k = maxf(1.0, floorf(48.0 / maxf(ts.x, ts.y)))
	var s := PX * k
	token.scale = Vector2(s, s)
	var foot := Vector2(ts.x / 2.0, ts.y - (2.0 if ts.y >= 40.0 else 1.0))
	token.offset = (FOOT / s - foot).round()


## A Unit that has moved is dimmed: its token and its ring, not its Health
## or its status marks, which should read just as well.
func refresh() -> void:
	if gone:
		return
	modulate = Color.WHITE
	token.modulate = Color(0.55, 0.55, 0.6, 0.95) if dim else Color.WHITE
	queue_redraw()
	if front != null:
		front.queue_redraw()


func _side_colour() -> Color:
	var ally: bool = unit.get("side") == "ally"
	var col := (ALLY_SEL if selected else ALLY) if ally else (ENEMY_SEL if selected else ENEMY)
	return col.darkened(0.5) if dim else col


func _ring_colour() -> Variant:
	if acting:
		return Color("#d6a851")
	if caught:
		return Color("#e88a36")
	if targeted:
		return Color("#efdd91")
	return null


## The art pixels of an ellipse's edge (or its inside), centred on 0, 0.
static func _ellipse(rx: int, ry: int, filled := false) -> Array:
	var out := []
	for y in range(-ry, ry + 1):
		var w := int(round(rx * sqrt(maxf(0.0, 1.0 - float(y * y) / float(ry * ry)))))
		if filled:
			for x in range(-w, w + 1):
				out.append(Vector2i(x, y))
		else:
			var prev := int(round(rx * sqrt(maxf(0.0, 1.0 - float((absi(y) + 1) * (absi(y) + 1)) / float(ry * ry))))) if absi(y) < ry else -1
			for x in range(-w, w + 1):
				if absi(x) > prev or absi(y) == ry:
					out.append(Vector2i(x, y))
	return out


func _px(p: Vector2i, origin: Vector2, c: Color) -> void:
	draw_rect(Rect2(origin + Vector2(p) * PX, Vector2(PX, PX)), c)


func _ring(on: Node2D, back: bool, rx: int, ry: int, c: Color) -> void:
	for p in _ellipse(rx, ry):
		if (p.y < 0) == back:
			on.draw_rect(Rect2(FOOT + Vector2(p) * PX - Vector2(PX, PX) / 2.0, Vector2(PX, PX)), c)


func _draw() -> void:
	# (0.12) pieces of it, falling as it goes down
	for b in bits:
		var c: Color = b["c"]
		c.a = clampf(1.0 - b["age"] / 0.6, 0.0, 1.0)
		draw_rect(Rect2(b["p"], Vector2(b["s"], b["s"])), c)
	if gone and not bits.is_empty():
		return
	# its shadow, under its feet (shrinking as it hops)
	var sh := clampf(1.0 - lift / 40.0, 0.4, 1.0)
	for p in _ellipse(int(round(13 * sh)), maxi(2, int(round(4 * sh))), true):
		draw_rect(Rect2(FOOT + Vector2(p) * PX - Vector2(PX, PX) / 2.0, Vector2(PX, PX)), Color(0, 0, 0, 0.42))
	# the far half of its ring, behind its feet
	var rc = _ring_colour()
	if rc != null:
		_ring(self, true, 17, 6, rc)
	_ring(self, true, 15, 5, _side_colour())
	if selected:
		_ring(self, true, 14, 4, _side_colour())


## The near half of the ring, then Health, statuses and the marks at its sides.
func _draw_front() -> void:
	if gone:
		return
	var on := front
	var rc = _ring_colour()
	if rc != null:
		_ring(on, false, 17, 6, rc)
	_ring(on, false, 15, 5, _side_colour())
	if selected:
		_ring(on, false, 14, 4, _side_colour())
	var lift_off := Vector2(0, -lift)
	# Health: pips under the ring, in its side's colour (amber when low)
	var hp_max := maxf(1.0, float(Rules.num(shown.get("hpMax"), 1)))
	var hp_now := float(Rules.num(shown.get("hp"), 0))
	var n := 8
	var lit := int(ceil(clampf(hp_now / hp_max, 0.0, 1.0) * n))
	var col := UnitView.ENEMY if unit.get("side") != "ally" else UnitView.ALLY
	if hp_now / hp_max <= 0.25:
		col = Color("#f8c53a")
	var pw := n * 3 - 1
	var y0 := FOOT.y + 7.0 * PX
	on.draw_rect(Rect2(Vector2(-pw / 2.0 - 1.0, y0 / PX - 1.0) * PX, Vector2(pw + 2.0, 4.0) * PX), Color("#0e0c0c"))
	for i in n:
		var c := col if i < lit else Color("#3e4246")
		on.draw_rect(Rect2(Vector2(-pw / 2.0 + i * 3.0, y0 / PX) * PX, Vector2(2.0, 2.0) * PX), c)
	if hp_now > hp_max:
		on.draw_rect(Rect2(Vector2(pw / 2.0 + 1.0, y0 / PX) * PX, Vector2(2.0, 2.0) * PX), Color("#59cf93"))
	# statuses: a small mark each, down its right side; then (0.13) each it is
	# guarded against, faded: just out of a Stun, a Root, a Pin or a Mark, it
	# can't have it again yet
	var sts: Array = shown.get("statuses", [])
	var grd: Array = shown.get("guards", [])
	var k := 0
	for s in sts:
		_mark(on, Art.status_mark(str(s.get("name", ""))), k, 1.0, str(s.get("name", "")))
		k += 1
	for g in grd:
		_mark(on, Art.status_mark(str(g)), k, 0.45, str(g))
		k += 1
	# 0.10: an Enemy the Bounty Board wants: a gold diamond at its other side
	if Rules.truthy(unit.get("bounty")):
		var bc := FOOT + Vector2(-17, -36) * PX + lift_off
		for p in [Vector2i(0, -2), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)]:
			on.draw_rect(Rect2(bc + Vector2(p) * PX, Vector2(PX, PX)), Color("#d6a851").darkened(0.45) if dim else Color("#d6a851"))
	# holding fire: a gold sight at its other side
	if shown.get("holding", false):
		var ow := Art.status_mark("overwatch")
		if ow != null:
			on.draw_set_transform(FOOT + Vector2(-22, -30) * PX + lift_off, 0.0, Vector2(PX, PX))
			on.draw_texture(ow, Vector2.ZERO)
			on.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A status's mark, the k-th down its right side.
func _mark(on: Node2D, tex: Texture2D, k: int, alpha: float, name: String) -> void:
	var at := FOOT + Vector2(13, -38 + k * 9) * PX + Vector2(0, -lift)
	if k >= 5:
		return
	if tex == null:
		on.draw_rect(Rect2(at + Vector2(PX, PX), Vector2(6, 6) * PX), Color(status_colour(name), alpha))
		return
	on.draw_set_transform(at, 0.0, Vector2(PX, PX))
	on.draw_texture(tex, Vector2.ZERO, Color(1, 1, 1, alpha))
	on.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Walks a path one tile at a time; emits walked when it arrives. (0.12) It
## hops from tile to tile; at Instant it is simply there.
func walk(path: Array[Vector2i]) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if path.is_empty():
		walked.emit()
		return
	if not Motion.still and not Motion.moving():
		position = Board.at(path[path.size() - 1])
		lift = 0.0
		walked.emit.call_deferred()
		return
	_tween = create_tween()
	var hop := not Motion.still
	var st := step_time * (1.15 * Motion.k() if hop else 1.0)
	for t in path:
		_tween.tween_property(self, "position", Board.at(t), st).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if hop:
			_tween.parallel().tween_method(func(x: float): lift = round(sin(x * PI) * size * 0.28 / PX) * PX, 0.0, 1.0, st)
			_tween.tween_callback(func(): Sound.play("step"))
	_tween.finished.connect(func():
		lift = 0.0
		walked.emit())


## (0.12) Lunges at a point and steps back: a blow struck. Returns at the
## moment the blow lands, and the step back plays on.
func lunge(at: Vector2) -> void:
	if not Motion.moving():
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var home := Board.at(Battle.tile_of(unit)) if unit.get("pos") is Dictionary else position
	var reach := home + (at - home) * 0.42
	Sound.play("melee")
	_tween = create_tween()
	_tween.tween_property(self, "position", reach, 0.11 * Motion.k()).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "position", home, 0.16 * Motion.k()).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.11 * Motion.k()).timeout


## (0.12) Struck: it flashes white and shakes where it stands. big: a heavy blow.
func struck(big := false) -> void:
	if not Motion.moving():
		return
	var g := create_tween()
	flash = 0.9
	g.tween_property(self, "flash", 0.0, 0.22 * Motion.k() + 0.04)
	if is_walking():
		return
	var home := position
	if unit.get("pos") is Dictionary:
		home = Board.at(Battle.tile_of(unit))
	_tween = create_tween()
	var amp := size * (0.16 if big else 0.09)
	for i in 5:
		var off := Vector2(amp * (1.0 - i / 5.0) * (1 if i % 2 == 0 else -1), randf_range(-amp, amp) * 0.4).round()
		_tween.tween_property(self, "position", home + off, 0.035 * Motion.k() + 0.005)
	_tween.tween_property(self, "position", home, 0.03 * Motion.k() + 0.005)


func _process(delta: float) -> void:
	if bits.is_empty():
		return
	for b in bits:
		b["age"] += delta
		b["v"] += Vector2(0, 520.0) * delta
		b["p"] += b["v"] * delta
	bits = bits.filter(func(b): return b["age"] < 0.6)
	queue_redraw()


## Slides straight back to a tile (an undone move).
func slide_to(t: Vector2i) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position", Board.at(t), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Fades away: the Unit is down. (0.12) It flashes, crumbles into pieces that
## fall, and is gone.
func fade_out() -> void:
	gone = true
	if _fade != null and _fade.is_valid():
		_fade.kill()
	_fade = create_tween()
	if front != null:
		front.queue_redraw()
	if Motion.moving():
		Sound.play("down")
		var col := ALLY if unit.get("side") == "ally" else ENEMY
		for i in 14:
			bits.append({"p": Vector2(randf_range(-size * 0.5, size * 0.5), randf_range(-size * 0.9, 0.0) + FOOT.y).snapped(Vector2(PX, PX)),
				"v": Vector2(randf_range(-90, 90), randf_range(-200, -40)), "c": [col, Color("#e6e7f0"), Color("#282c3c")][i % 3], "s": [4.0, 6.0][i % 2], "age": -0.12 * Motion.k()})
		token.visible = true
		flash = 1.0
		var sc := token.scale
		_fade.tween_property(token, "scale", Vector2(sc.x * 1.2, sc.y * 0.2), 0.18 * Motion.k())
		_fade.parallel().tween_property(self, "flash", 0.0, 0.18 * Motion.k())
		_fade.tween_property(self, "modulate:a", 0.0, 0.4 * Motion.k() + 0.05)
		_fade.tween_callback(func():
			visible = false
			_fit_token())
		return
	_fade.tween_property(self, "modulate:a", 0.0, 0.55)
	_fade.tween_callback(func(): visible = false)


## Back on its feet (a move that brought it down was taken back).
func come_back() -> void:
	gone = false
	if _fade != null and _fade.is_valid():
		_fade.kill()
	bits.clear()
	flash = 0.0
	visible = true
	_fit_token()
	refresh()


## A Unit put down by a Deploy grows into place.
func pop_in() -> void:
	scale = Vector2(0.2, 0.2)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func is_walking() -> bool:
	return _tween != null and _tween.is_valid() and _tween.is_running()
