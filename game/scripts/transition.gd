## Screen transitions (0.19): as one screen gives way to another, a still of
## the old one is held over the new and taken away a piece at a time, so the
## new screen shows through. Between the menus (Home, the Strike Teams, a
## fight's setup, the dock, the Workshop, the map) the old screen goes in a
## hex wipe: hexagons sweep across from the left, each edged in cyan as it
## goes. Into a fight and out of one, it breaks up in a pixel dissolve: blocks
## of the old screen vanish in a scattered order.
##
## It takes nothing from the rules and holds nothing up: the new screen is
## there, and answers taps, from the start. Faster at Fast; none at Instant.
class_name Transition
extends CanvasLayer

const HEX := "hex"
const PIXELS := "pixels"
const TIME := {"hex": 0.5, "pixels": 0.42}
const HEX_R := 44.0              # a hexagon of the wipe, centre to corner, in screen pixels
const BLOCK := 16.0              # a block of the dissolve, in screen pixels

var style := ""
var t := 0.0
var length := 0.0
var still: Texture2D = null      # the old screen
var cells: Array = []            # {pts: PackedVector2Array (hex) or rect: Rect2 (block), at: when it goes, 0 to 1}
var played: Array = []           # each style played, in order (for the tests)
var view: Control
var _frame := -1


func _init() -> void:
	layer = 90
	view = Control.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.draw.connect(_draw_view)
	add_child(view)
	set_process(false)


## The screenshots' switch: off unless a shot asks for its transitions.
static var enabled := true


## Whether a transition plays at all now.
static func plays() -> bool:
	return enabled and Motion.moving()


## The screen about to change: holds a still of it and takes it away in this
## style. A second call in the same frame (one screen opening another as it
## opens) keeps the first still and plays the later style.
func play(how: String) -> void:
	played.append(how)
	if not plays() or not is_inside_tree():
		return
	var f := Engine.get_process_frames()
	if f != _frame or still == null:
		still = _grab()
		if still == null:
			return
	_frame = f
	style = how
	t = 0.0
	length = TIME.get(how, 0.4) * Motion.k()
	_cells(Vector2(still.get_size()))
	view.visible = true
	set_process(true)
	view.queue_redraw()


## A still of the screen as it is. (Without a screen to read, as when the tests
## run headless, a dark one the size of the window.)
func _grab() -> Texture2D:
	var img: Image = null
	if DisplayServer.get_name() != "headless":
		img = get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		var vs := get_viewport().get_visible_rect().size
		img = Image.create(maxi(1, int(vs.x)), maxi(1, int(vs.y)), false, Image.FORMAT_RGB8)
		img.fill(Color("#0e0c0c"))
	return ImageTexture.create_from_image(img)


func playing() -> bool:
	return style != "" and still != null


func _cells(sz: Vector2) -> void:
	cells = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 19
	if style == HEX:
		var w := sqrt(3.0) * HEX_R
		var row := 0
		var y := 0.0
		while y < sz.y + HEX_R * 2.0:
			var x := (w / 2.0) if row % 2 else 0.0
			while x < sz.x + w:
				var pts := PackedVector2Array()
				for i in 6:
					var a := deg_to_rad(60.0 * i - 30.0)
					pts.append(Vector2(x, y) + Vector2(cos(a), sin(a)) * (HEX_R + 1.0))
				# a wave from the left, a little ragged
				cells.append({"pts": pts, "c": Vector2(x, y), "at": clampf(x / sz.x * 0.8 + rng.randf() * 0.15, 0.0, 0.95)})
				x += w
			y += HEX_R * 1.5
			row += 1
	else:
		var y2 := 0.0
		while y2 < sz.y:
			var x2 := 0.0
			while x2 < sz.x:
				cells.append({"rect": Rect2(x2, y2, BLOCK, BLOCK), "at": rng.randf() * 0.92})
				x2 += BLOCK
			y2 += BLOCK


func _process(delta: float) -> void:
	t += delta
	if length <= 0.0 or t >= length:
		_end()
		return
	view.queue_redraw()


func _end() -> void:
	style = ""
	still = null
	cells = []
	set_process(false)
	view.queue_redraw()


## Where it is, 0 to 1.
func progress() -> float:
	return clampf(t / length, 0.0, 1.0) if length > 0.0 else 1.0


func _draw_view() -> void:
	if still == null:
		return
	var p := progress()
	var sz := Vector2(still.get_size())
	var scale := view.size / sz if sz.x > 0.0 else Vector2.ONE
	if style == HEX:
		for c in cells:
			var left: float = (c["at"] + 0.08) - p        # how long before it has gone
			if left <= 0.0:
				continue
			var pts: PackedVector2Array = c["pts"]
			var k := clampf(left / 0.08, 0.0, 1.0)        # it shrinks into its middle as it goes
			if k < 0.08:
				continue
			var shown := PackedVector2Array()
			var uvs := PackedVector2Array()
			for q in pts:
				var r: Vector2 = c["c"] + (q - c["c"]) * k
				shown.append(r * scale)
				uvs.append(r / sz)
			view.draw_colored_polygon(shown, Color.WHITE, uvs, still)
			if k < 1.0:
				var loop := shown.duplicate()
				loop.append(shown[0])
				view.draw_polyline(loop, Color("#73efe8"), 2.0)
	else:
		for c in cells:
			if p >= c["at"]:
				continue
			var r2: Rect2 = c["rect"]
			var dark: bool = p >= c["at"] - 0.06            # a block about to go darkens first
			view.draw_texture_rect_region(still, Rect2(r2.position * scale, r2.size * scale), r2, Color(0.35, 0.35, 0.4) if dark else Color.WHITE)
