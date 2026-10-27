## Motion and feedback (0.12): how fast a fight plays (Normal, Fast or
## Instant), whether big hits shake the screen, and whether there is sound;
## kept between sessions. And what is drawn over the board as things happen:
## each shot as its kind (a bolt, a shell, a beam, a spray of pellets), and
## (0.16) the fight's drawn effects, frame by frame, each in its own colours:
## a muzzle flash as a shot leaves, an impact where damage lands, an explosion
## on every tile a blast catches (and where a shell comes down), a heal rising
## from whoever is mended, and a shield as an attack glances off armour. They
## take the place of 0.12's sparks and rings; yours play if you drew them.
##
## None of it changes the rules: a fight is decided the instant a tap is made,
## and this only shows it. At Instant nothing moves, and the pauses between
## beats are short.
class_name Motion
extends Node2D

const SPEEDS := ["normal", "fast", "instant"]
const SPEED_NAMES := {"normal": "Normal", "fast": "Fast", "instant": "Instant"}
const FILE := "user://settings.json"
## What each kind of shot looks like (the Companion's Projectile choice).
const KINDS := ["bolt", "shell", "beam", "spray"]

## Where the settings are kept (the tests point this somewhere of their own).
static var path := FILE
static var speed := "normal"
static var shake := true
static var sound := true
static var buzz := true          # (0.33) the phone vibrates on a hit to one of yours
static var dev := false          # (0.36) Developer: the dock's testing buttons show
static var music := "low"       # (0.39) Off, Low or High
static var coached := false      # (0.39) the first deployment fight's field guide has been read, or skipped
## (0.18) How much atmosphere a fight has: off, subtle or full (Atmos).
static var atmos := "subtle"
## The tests' switch: nothing moves and every pause is as 0.11 had it, so what
## they look at is where it was. (The tests of 0.12's own motion turn it off.)
static var still := false
## The screenshots' switch: shots and cards stop this far along their way
## (0 to 1) and stay there, to be seen in the air. Below 0, they don't.
static var freeze_at := -1.0
static var _read := false


# ---------------------------------------------------------------- the settings
static func settings() -> void:
	if _read:
		return
	_read = true
	if not FileAccess.file_exists(path):
		return
	var j := JSON.new()
	var d = j.data if j.parse(FileAccess.get_file_as_string(path)) == OK else null
	if d is Dictionary:
		speed = str(d.get("speed", "normal")) if SPEEDS.has(d.get("speed")) else "normal"
		shake = d.get("shake", true) != false
		sound = d.get("sound", true) != false
		buzz = d.get("buzz", true) != false
		dev = d.get("dev", false) == true
		coached = d.get("coached", false) == true
		music = str(d.get("music", "low")) if ["off", "low", "high"].has(d.get("music")) else "low"
		atmos = str(d.get("atmos", "subtle")) if ["off", "subtle", "full"].has(d.get("atmos")) else "subtle"


static func save() -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify({"game": "KETER", "kind": "settings", "speed": speed, "shake": shake, "sound": sound, "buzz": buzz, "atmos": atmos, "dev": dev, "coached": coached, "music": music}, "\t"))
	f.close()
	return true


## Back to how a new game starts (the tests).
static func reset() -> void:
	speed = "normal"
	shake = true
	sound = true
	buzz = true
	dev = false
	coached = false
	music = "low"
	atmos = "subtle"
	_read = true
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func set_speed(s: String) -> void:
	if SPEEDS.has(s):
		speed = s
		save()


## The next speed along: Normal, Fast, Instant, Normal again.
static func next_speed() -> String:
	set_speed(SPEEDS[(SPEEDS.find(speed) + 1) % SPEEDS.size()])
	return speed


static func set_shake(on: bool) -> void:
	shake = on
	save()


static func set_buzz(on: bool) -> void:
	buzz = on
	save()


## (0.33) A short vibration, if the phone has one and Vibration is on.
static func vibrate(ms: int) -> void:
	if buzz and not still and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


## (0.39) The music: Off, Low or High.
static func set_music(level: String) -> void:
	if ["off", "low", "high"].has(level):
		music = level
		save()
		if Music.host != null and is_instance_valid(Music.host):
			Music.host._apply_level()


## (0.39) The field guide is read: not shown again.
static func set_coached(on: bool) -> void:
	coached = on
	save()


## (0.36) Developer: the dock's Testing row (restock, reach, reset), as the Companion's Dev Mode has it.
static func set_dev(on: bool) -> void:
	dev = on
	save()


static func set_sound(on: bool) -> void:
	sound = on
	save()


## (0.18) Off, Subtle or Full.
static func set_atmos(level: String) -> void:
	if ["off", "subtle", "full"].has(level):
		atmos = level
		save()


## Whether things move at all.
static func moving() -> bool:
	return not still and speed != "instant"


## How long a movement takes, against Normal: 0 when nothing moves.
static func k() -> float:
	if not moving():
		return 0.0
	return 1.0 if speed == "normal" else 0.45


## How long a pause between beats is, against Normal.
static func wait_k() -> float:
	if still:
		return 1.0
	return {"normal": 1.0, "fast": 0.45, "instant": 0.12}[speed]


## What a Unit's Action fires: its own if it is one the game knows, else a bolt.
static func kind_of(action) -> String:
	var p = action.get("proj") if action is Dictionary else null
	if not Rules.truthy(p) and action is Dictionary:
		p = action.get("projectile")
	return str(p) if KINDS.has(p) else "bolt"


## The colour of a shot: yours in cyan, the Enemies' in orange; Aether in its
## blue, Cyber in violet.
static func colour_of(side: String, role: String) -> Color:
	match role:
		"aether":
			return Color("#8aa1f6")
		"cyber":
			return Color("#c23bff")
	return Color("#73efe8") if side == "ally" else Color("#ff7a1a")


# ---------------------------------------------------------------- boxes
## A box pops open: it grows to its size from a little smaller, and fades in.
static func pop_in(box: Control) -> void:
	if not moving() or box == null or not box.is_inside_tree():
		return
	box.modulate.a = 0.0
	await box.get_tree().process_frame
	if not is_instance_valid(box):
		return
	box.pivot_offset = box.size / 2.0
	box.scale = Vector2(0.88, 0.88)
	var tw := box.create_tween().set_parallel()
	tw.tween_property(box, "scale", Vector2.ONE, 0.18 * k()).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(box, "modulate:a", 1.0, 0.12 * k())


## A box shuts: whatever was waiting on it is let go at once, so a second tap
## does nothing, and it shrinks and fades, then is gone. host: the whole of
## it, shade and all; box: the panel in the middle.
static func pop_out(host: Node, box: Control = null) -> void:
	if host == null or not is_instance_valid(host):
		return
	if not moving() or box == null or not host.is_inside_tree() or not (host is CanvasItem):
		host.queue_free()
		return
	var sc = host.get_script()
	if sc != null:
		for sg in sc.get_script_signal_list():
			for c in host.get_signal_connection_list(sg["name"]):
				host.disconnect(sg["name"], c["callable"])
	if host is Control:
		host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.pivot_offset = box.size / 2.0
	var tw := host.create_tween().set_parallel()
	tw.tween_property(box, "scale", Vector2(0.9, 0.9), 0.12 * k()).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(host, "modulate:a", 0.0, 0.12 * k())
	tw.chain().tween_callback(host.queue_free)


# ---------------------------------------------------------------- on the board
## (0.16) Where on a Unit a shot, a hit and a heal are, from the middle of its
## tile (world units): its middle, where shots leave from and land, and a hit,
## a flash and a shield play; its feet, where a heal rises from.
const BODY := Vector2(0, -32)
const FEET := Vector2(0, 14)

var shots: Array = []          # what is in the air: {kind, from, to, t, colour, hit, seed}
var beams: Array = []          # {from, to, colour, age, life}
var plays: Array = []          # (0.16) the drawn effects playing: {name, at, t, fx}
var fired := []                # every shot made, as {kind, hit} (the tests read it)
var played := []               # (0.16) every effect begun, as {name, at, delay} (the tests read it)


func _ready() -> void:
	z_index = 5
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Fires a shot of a kind from one point to another, and returns when it gets
## there. One that misses flies past the target and off. hit: whether it hit.
## (0.16) A muzzle flash goes off as it leaves; a shell comes down in an explosion.
func fire(kind: String, from: Vector2, to: Vector2, colour: Color, hit := true) -> void:
	fired.append({"kind": kind, "hit": hit})
	var dir := (to - from).normalized() if to != from else Vector2.RIGHT
	play("flash", from + dir * 22.0)
	if not moving():
		if kind == "shell":
			play("explosion", to if hit else to + dir * Board.SIZE * 1.4 + dir.orthogonal() * Board.SIZE * 0.55)
		return
	var end := to
	if not hit:
		# past the target, and a little to one side
		end = to + dir * Board.SIZE * 1.4 + dir.orthogonal() * Board.SIZE * 0.55
	Sound.play(kind)
	match kind:
		"beam":
			beams.append({"from": from, "to": end, "colour": colour, "age": 0.0, "life": 0.32 * k() + 0.04})
			queue_redraw()
			await _after(0.09)
			while freeze_at >= 0.0:
				await get_tree().process_frame
		"spray":
			var group := []
			for i in 6:
				var a := (i - 2.5) * 0.09 + randf_range(-0.03, 0.03)
				var e := from + (end - from).rotated(a) * randf_range(0.92, 1.06)
				var s := {"kind": "spray", "from": from, "to": e, "t": -i * 0.05, "colour": colour, "hit": hit}
				shots.append(s)
				group.append(s)
			await _fly(group, 0.22)
		"shell":
			var s := {"kind": "shell", "from": from, "to": end, "t": 0.0, "colour": colour, "hit": hit}
			shots.append(s)
			await _fly([s], 0.48)
			play("explosion", end)
			Sound.play("blast")
		_:
			var s := {"kind": "bolt", "from": from, "to": end, "t": 0.0, "colour": colour, "hit": hit}
			shots.append(s)
			await _fly([s], clampf(from.distance_to(end) / 1500.0, 0.1, 0.32))


## Moves shots along until they have all arrived.
func _fly(list: Array, seconds: float) -> void:
	var dur := maxf(0.01, seconds * k())
	var left := true
	while left:
		await get_tree().process_frame
		var dt := get_process_delta_time() / dur
		left = false
		for s in list:
			s["t"] = minf(1.0, float(s["t"]) + dt)
			if freeze_at >= 0.0 and s["t"] >= freeze_at:
				s["t"] = freeze_at
			if s["t"] < 1.0:
				left = true
		queue_redraw()
	for s in list:
		shots.erase(s)
	queue_redraw()


func _after(seconds: float) -> void:
	if seconds * k() > 0.0:
		await get_tree().create_timer(seconds * k()).timeout


## (0.16) One of the fight's drawn effects plays at a point on the board: its
## frames one after another at its own speed (faster at Fast), then it is gone.
## Nothing plays at Instant. name: flash, impact, explosion, heal or shield;
## delay: seconds before it begins, at Normal speed.
func play(name: String, at: Vector2, delay := 0.0) -> void:
	played.append({"name": name, "at": at, "delay": delay})
	if played.size() > 400:
		played = played.slice(-200)          # (kept short: a long session plays thousands)
	if not moving():
		return
	var fx := Art.fx(name)
	if fx.is_empty() or (fx.get("frames", []) as Array).is_empty():
		return
	plays.append({"name": name, "at": at, "t": -maxf(0.0, delay), "fx": fx})
	queue_redraw()


## An area lands: every tile it catches explodes, the middle first and the
## rest a ring at a time. from_ring: the first ring to explode (1 when a shell
## has come down in the middle already). on: which tiles there are (the
## floor's), so nothing explodes off the edge of the board; all, if not given.
func area(centre: Vector2i, radius: int, from_ring := 0, on := Callable()) -> void:
	for q in range(-radius, radius + 1):
		for r in range(-radius, radius + 1):
			var h := centre + Vector2i(q, r)
			var d := Hex.distance(centre, h)
			if d <= radius and d >= from_ring and (not on.is_valid() or on.call(h)):
				play("explosion", Board.at(h), d * 0.07)
	if moving():
		Sound.play("blast")


## (0.16) Which frame an effect is showing (-1 before it begins, its count once done).
static func frame_of(p: Dictionary) -> int:
	var t: float = p["t"]
	if t < 0.0:
		return -1
	return int(floor(t * float(p["fx"]["fps"]) + 0.000001))


func busy() -> bool:
	return not (shots.is_empty() and beams.is_empty() and plays.is_empty())


func clear() -> void:
	shots.clear()
	beams.clear()
	plays.clear()
	queue_redraw()


func _process(delta: float) -> void:
	if beams.is_empty() and plays.is_empty():
		return
	for b in beams:
		b["age"] += delta if freeze_at < 0.0 else 0.0
	beams = beams.filter(func(b): return b["age"] < b["life"])
	# (0.16) the effects step on at their own speed, faster at Fast; a
	# screenshot can hold each this far through (freeze_at)
	var step := delta / maxf(0.05, k())
	for p in plays:
		var n: int = (p["fx"]["frames"] as Array).size()
		var t: float = p["t"] + step
		if freeze_at >= 0.0 and t >= 0.0:
			t = minf(t, (minf(freeze_at, 0.999) * n) / float(p["fx"]["fps"]))
		p["t"] = t
	plays = plays.filter(func(p): return frame_of(p) < (p["fx"]["frames"] as Array).size())
	queue_redraw()


## A square of pixels, on the board's grid of four units (a fight's pixels
## are bigger than a screen's: the board is seen from afar).
func _px(at: Vector2, s: float, c: Color) -> void:
	s *= 1.6
	var p := (at / 4.0).floor() * 4.0
	draw_rect(Rect2(p - Vector2(s, s) / 2.0, Vector2(s, s)), c)


func _draw() -> void:
	for b in beams:
		var f: float = b["age"] / b["life"]
		var flick := 1.0 if int(b["age"] * 30.0) % 2 == 0 else 0.7
		var c: Color = b["colour"]
		c.a = (1.0 - f) * flick
		draw_line(b["from"], b["to"], Color(c, c.a * 0.45), 22.0)
		draw_line(b["from"], b["to"], c, 10.0)
		draw_line(b["from"], b["to"], Color(1, 1, 1, c.a), 4.0)
	# (0.16) the drawn effects, each frame at the board's pixel size, its
	# anchor over its point and its pixels on the board's grid
	for p in plays:
		var i := frame_of(p)
		var frames: Array = p["fx"]["frames"]
		if i < 0 or i >= frames.size():
			continue
		var sz: Vector2 = p["fx"]["size"] * Board.PIXEL
		var top: Vector2 = ((p["at"] - p["fx"]["anchor"] * Board.PIXEL) / Board.PIXEL).round() * Board.PIXEL
		draw_texture_rect(frames[i], Rect2(top, sz), false)
	for s in shots:
		var t: float = s["t"]
		if t < 0.0:
			continue
		var a: Vector2 = s["from"]
		var e: Vector2 = s["to"]
		var c: Color = s["colour"]
		match s["kind"]:
			"shell":
				var lift := sin(t * PI) * a.distance_to(e) * 0.35
				var p := a.lerp(e, t) - Vector2(0, lift)
				for i in 6:
					var tt := maxf(0.0, t - (i + 1) * 0.035)
					var q := a.lerp(e, tt) - Vector2(0, sin(tt * PI) * a.distance_to(e) * 0.35)
					_px(q, 10.0 - i, Color(Color("#f8c53a") if i < 2 else Color("#e88a36"), 0.85 - i * 0.12))
				_px(p, 18.0, Color("#0e0c0c"))
				_px(p, 14.0, Color("#6a7178"))
				_px(p - Vector2(3, 3), 6.0, Color("#b3ada2"))
			"spray":
				var p2 := a.lerp(e, t)
				var d2 := (e - a).normalized()
				_px(p2 - d2 * 6.0, 4.0, Color(c, 0.5))
				_px(p2, 8.0, Color("#0e0c0c"))
				_px(p2, 6.0, c)
			_:
				var p3 := a.lerp(e, t)
				var d := (e - a).normalized()
				for i in range(7, -1, -1):
					_px(p3 - d * i * 5.0, 12.0 if i == 0 else (8.0 if i < 3 else 6.0), Color("#f1f2ff") if i == 0 else Color(c, 1.0 - i * 0.11))
