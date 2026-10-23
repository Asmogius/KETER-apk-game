## Victory or Defeat (0.19): the end of a fight as a short scene before its
## tally. The board dims; the sign powers on like a failing neon tube,
## stuttering before it holds. Victory comes on whole, in gold, and your
## Units still standing line up under it. Defeat sputters and never quite
## catches: its right half stays dim, flickering, and your fallen lie under
## it, greyed. About two seconds; a tap anywhere skips it. Then the tally.
class_name NeonScene
extends Control

signal done

const LENGTH := 2.1                     # seconds, at Normal
const SIGN_SCALE := 4.0
const TOKEN_SCALE := 2.0
## when the tube flickers as it powers on: [time, lit] pairs, then it holds
const POWER := [[0.30, true], [0.36, false], [0.46, true], [0.50, false], [0.58, true], [0.61, false], [0.68, true]]

var won := true
var sign: Texture2D
var tokens: Array = []                  # Texture2D: yours standing (a win) or fallen (a loss)
var colour := Color("#f8c53a")
var t := 0.0
var length := LENGTH
var finished := false


func _init(win: bool, sign_tex: Texture2D, unit_tokens: Array) -> void:
	won = win
	sign = sign_tex
	tokens = unit_tokens.filter(func(x): return x != null).slice(0, 8)
	colour = Color("#f8c53a") if win else Color("#ff2a3c")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	length = LENGTH * maxf(0.45, Motion.k())


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if t >= length:
		finish()


## Over: the tally comes.
func finish() -> void:
	if finished:
		return
	finished = true
	set_process(false)
	done.emit()
	queue_free()


func _gui_input(e: InputEvent) -> void:
	if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
		accept_event()
		finish()


## Whether the tube is lit at a moment (by the powering-on pattern; a loss's
## dead half flickers on its own, faster, and mostly stays dark).
func lit(at: float) -> bool:
	var on := false
	var k := length / LENGTH
	for p in POWER:
		if at >= float(p[0]) * k:
			on = p[1]
	return on


func dead_half(at: float) -> float:
	var k := length / LENGTH
	if at < 0.68 * k:
		return 1.0 if lit(at) else 0.0
	# after it catches, the right half of Defeat sputters: mostly dim, now and then lit
	return 1.0 if fmod(at * 7.3, 1.0) < 0.18 else 0.28


func _draw() -> void:
	var vs := size
	var k := length / LENGTH
	# the board dims
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.02, 0.02, 0.04, 0.6 * clampf(t / (0.3 * k), 0.0, 1.0)))
	if sign == null:
		return
	var ss := sign.get_size() * SIGN_SCALE
	var at := Vector2((vs.x - ss.x) / 2.0, vs.y * 0.3 - ss.y / 2.0).round()
	var on := lit(t)
	if on or won or t >= 0.68 * k:
		var whole := 1.0 if on else 0.0
		var right := whole if won else dead_half(t)
		var half := sign.get_size().x / 2.0
		# the glow behind it, in its colour
		for d in [Vector2(-4, 0), Vector2(4, 0), Vector2(0, -4), Vector2(0, 4)]:
			if whole > 0.0:
				draw_texture_rect_region(sign, Rect2(at + d, Vector2(half * SIGN_SCALE, ss.y)), Rect2(0, 0, half, sign.get_size().y), Color(colour, 0.22))
			if right > 0.5:
				draw_texture_rect_region(sign, Rect2(at + d + Vector2(half * SIGN_SCALE, 0), Vector2(half * SIGN_SCALE, ss.y)), Rect2(half, 0, half, sign.get_size().y), Color(colour, 0.22))
		draw_texture_rect_region(sign, Rect2(at, Vector2(half * SIGN_SCALE, ss.y)), Rect2(0, 0, half, sign.get_size().y), Color(1, 1, 1, whole))
		draw_texture_rect_region(sign, Rect2(at + Vector2(half * SIGN_SCALE, 0), Vector2(half * SIGN_SCALE, ss.y)), Rect2(half, 0, half, sign.get_size().y),
			Color(right, right, right, maxf(right, 0.25 if whole > 0.0 else 0.0)))
	# yours, under it, as it holds
	if tokens.is_empty() or t < 0.75 * k:
		return
	var rise := clampf((t - 0.75 * k) / (0.3 * k), 0.0, 1.0)
	var tw := 48.0 * TOKEN_SCALE
	var gap := 12.0
	var row := tokens.size() * tw + (tokens.size() - 1) * gap
	var x := (vs.x - row) / 2.0
	var y := at.y + ss.y + 40.0 + (1.0 - rise) * 20.0
	for tex in tokens:
		var tex2: Texture2D = tex
		var ts := tex2.get_size()
		# at twice its pixels, or smaller (a whole fraction) to fit its place
		var fit := minf(TOKEN_SCALE, tw / maxf(ts.x, ts.y))
		if fit < TOKEN_SCALE:
			fit = 1.0 / ceilf(maxf(ts.x, ts.y) / tw) if maxf(ts.x, ts.y) > tw else 1.0
		var sz := ts * fit
		var r := Rect2(Vector2(x + (tw - sz.x) / 2.0, y + (tw - sz.y)), sz).abs()
		draw_texture_rect(tex2, r, false, Color(1, 1, 1, rise) if won else Color(0.45, 0.45, 0.5, rise * 0.85))
		x += tw + gap
