## What floats over the board at screen size, whatever the zoom: the odds on
## each target ("65% · 6"), the dice readout by a target after an attack, and
## the numbers that rise off a Unit when it's hit or healed. Everything is
## pinned to a place on the board and follows it as the board pans.
class_name Overlay
extends Control

const GOOD := Color("#59cf93")
const FAIR := Color("#d6a851")
const POOR := Color("#c8624d")
const BG := Color(8 / 255.0, 14 / 255.0, 18 / 255.0, 0.94)

var to_screen: Callable          # board point -> screen point
var tags: Array = []             # {at, text, colour, below}: over a Unit, or under it if asked
var avoid: Array = []            # where Units stand (board points): a tag keeps off the others
var floats: Array = []           # {at, text, colour, age}
var readout := {}                # {at, lines: [[text, colour]], age, life}
var right_margin := 0.0          # the side panel's width, kept clear
var _font: Font

const FLOAT_LIFE := 1.1


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_font = Look.font()


## A tag's colour by its chance: green from two in three, amber from one in three.
static func odds_colour(p: float) -> Color:
	return GOOD if p >= 0.66 else (FAIR if p >= 0.33 else POOR)


func set_tags(list: Array, units: Array = []) -> void:
	tags = list
	avoid = units
	queue_redraw()


func clear_tags() -> void:
	tags = []
	avoid = []
	queue_redraw()


## A number or a word rises off a place on the board. With a delay it waits
## its turn, so several off one Unit read one after another.
func float_text(at: Vector2, text: String, colour: Color, delay := 0.0, big := false) -> void:
	floats.append({"at": at, "text": text, "colour": colour, "age": -delay, "big": big})
	queue_redraw()


## (0.12) A card flies across the screen from one point to another, and lands
## with a flash. Returns as it lands.
var flights: Array = []          # {from, to, t, colour, name}
var flashes: Array = []          # {at, age, colour}

func fly_card(from: Vector2, to: Vector2, colour: Color, name: String, seconds: float) -> void:
	var f := {"from": from, "to": to, "t": 0.0, "colour": colour, "name": name}
	flights.append(f)
	var dur := maxf(0.01, seconds)
	while f["t"] < 1.0:
		await get_tree().process_frame
		f["t"] = minf(1.0, f["t"] + get_process_delta_time() / dur)
		if Motion.freeze_at >= 0.0 and f["t"] >= Motion.freeze_at:
			f["t"] = Motion.freeze_at
		queue_redraw()
	flights.erase(f)
	flashes.append({"at": to, "age": 0.0, "colour": colour})
	queue_redraw()


func clear_floats() -> void:
	floats = []
	queue_redraw()


func show_readout(at: Vector2, lines: Array, life := 2.6) -> void:
	readout = {"at": at, "lines": lines, "age": 0.0, "life": life}
	queue_redraw()


func clear_readout() -> void:
	readout = {}
	queue_redraw()


func busy() -> bool:
	return not floats.is_empty() or not readout.is_empty()


func _process(delta: float) -> void:
	for f in flashes:
		f["age"] += delta
	flashes = flashes.filter(func(f): return f["age"] < 0.3)
	if floats.is_empty() and readout.is_empty() and tags.is_empty() and flashes.is_empty() and flights.is_empty():
		return
	for f in floats:
		f["age"] += delta
	floats = floats.filter(func(f): return f["age"] < FLOAT_LIFE)
	if not readout.is_empty():
		readout["age"] += delta
		if readout["age"] >= readout["life"]:
			readout = {}
	queue_redraw()


func _screen(at: Vector2) -> Vector2:
	return to_screen.call(at) if to_screen.is_valid() else at


func _draw() -> void:
	_draw_tags()
	for f in floats:
		if f["age"] < 0.0:
			continue
		var k: float = f["age"] / FLOAT_LIFE
		var p := _screen(f["at"]) - Vector2(0, 30 + 46 * k)
		var c: Color = f["colour"]
		c.a = 1.0 - k * k
		var fs := Look.TITLE
		if f.get("big", false):
			# (0.12) a blow's damage pops up big, then settles
			fs = Look.HUGE if f["age"] < 0.14 else Look.TITLE
		var w := _font.get_string_size(f["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string_outline(_font, p - Vector2(w / 2, 0), f["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0, 0, 0, c.a))
		draw_string(_font, p - Vector2(w / 2, 0), f["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)
	if not readout.is_empty():
		_readout()
	_draw_flights()


## (0.12) Cards in the air, and where they landed.
func _draw_flights() -> void:
	for f in flights:
		var t: float = f["t"]
		var e := t * t * (3.0 - 2.0 * t)
		var p: Vector2 = f["from"].lerp(f["to"], e) - Vector2(0, sin(t * PI) * 90.0)
		var s := 1.0 - 0.35 * t
		var w := 56.0 * s
		var h := 76.0 * s
		var r := Rect2(p - Vector2(w, h) / 2.0, Vector2(w, h))
		draw_rect(r.grow(2), Color("#0e0c0c"))
		draw_rect(r, Color("#171819"))
		draw_rect(Rect2(r.position, Vector2(w, h * 0.22)), f["colour"])
		draw_rect(r, f["colour"], false, 2.0)
		draw_rect(Rect2(r.position + Vector2(w * 0.2, h * 0.36), Vector2(w * 0.6, h * 0.36)), Color(f["colour"], 0.35))
	for f in flashes:
		var k: float = f["age"] / 0.3
		var c: Color = f["colour"]
		c.a = 1.0 - k
		var rr := 20.0 + 70.0 * k
		draw_rect(Rect2(f["at"] - Vector2(rr, rr), Vector2(rr, rr) * 2.0), c, false, 4.0)
		draw_rect(Rect2(f["at"] - Vector2(rr, rr) * 0.6, Vector2(rr, rr) * 1.2), Color(1, 1, 1, c.a * 0.6), false, 2.0)


## Each tag sits just over its Unit (or just under, if asked), clear of the
## Unit whatever the zoom. Where that would cover another Unit or another tag
## (targets standing close together), it takes whichever side covers less.
func _draw_tags() -> void:
	if tags.is_empty():
		return
	var fs := Look.SMALL
	var zoom: float = (_screen(Vector2(1, 0)) - _screen(Vector2.ZERO)).length()
	var body := Board.SIZE * 0.72 * zoom              # a Unit's hexagon, on screen
	var up := -(Board.SIZE * 0.90 * zoom + 17.0)
	var down := Board.SIZE * 1.15 * zoom + 17.0       # past its Health bar and status dots
	var placed: Array[Rect2] = []
	for t in tags:
		var p := _screen(t["at"])
		var w := _font.get_string_size(t["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 14
		var h := 26.0
		var first: float = down if t.get("below", false) else up
		var chosen := Rect2()
		var least := INF
		for dy in [first, down if first == up else up]:
			var r := Rect2(p.x - w / 2, p.y + dy - h / 2, w, h)
			var covered := 0.0
			for o in placed:
				covered += r.intersection(o).get_area()
			for a in avoid:
				if (a as Vector2).distance_to(t["at"]) < 1.0:
					continue
				var c := _screen(a)
				covered += r.intersection(Rect2(c.x - body, c.y - body, body * 2, body * 2)).get_area()
			if covered < least:
				least = covered
				chosen = r
		placed.append(chosen)
		draw_rect(chosen, BG)
		draw_rect(chosen, t["colour"], false, 1.5)
		draw_string(_font, Vector2(chosen.position.x + 7, chosen.position.y + 19), t["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, t["colour"])


func _readout() -> void:
	var fs := Look.SMALL
	var lines: Array = readout["lines"]
	var w := 0.0
	for l in lines:
		w = maxf(w, _font.get_string_size(l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	w += 24
	var h := 12.0 + 24.0 * lines.size()
	var p := _screen(readout["at"])
	var r := Rect2(p.x - w / 2, p.y - 70 - h, w, h)
	# kept on the screen
	var vp := get_viewport_rect().size
	r.position.x = clampf(r.position.x, 8, vp.x - right_margin - w - 8)
	if r.position.y < 80:
		r.position.y = p.y + 60
	r.position.y = clampf(r.position.y, 80, vp.y - h - 56)
	var fade := clampf((readout["life"] - readout["age"]) / 0.4, 0.0, 1.0)
	draw_rect(r, Color(BG, BG.a * fade))
	draw_rect(r, Color(FAIR, fade), false, 1.5)
	for i in lines.size():
		var c: Color = lines[i][1]
		c.a *= fade
		draw_string(_font, Vector2(r.position.x + 12, r.position.y + 26 + 24 * i), lines[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)
