## The Pixel Studio's canvas (0.30): a picture at a whole number of screen
## pixels to its pixels, on a checkerboard where it is transparent, with a
## grid once close enough to use it. One finger draws with the tool in hand;
## two pinch and pan (a mouse: the wheel zooms, the right button pans).
class_name PixelCanvas
extends Control

## A stroke with the tool: "begin", "move", "end", or "cancel" (a second
## finger came down: what the stroke did is to be undone).
signal stroke(phase: String, at: Vector2)

const ZOOM_MAX := 40
const GROUND := Color("#0d1216")
const CHECK_A := Color("#3a3f47")
const CHECK_B := Color("#2b2f35")
const GRID := Color(1, 1, 1, 0.10)
const PREVIEW := Color("#73efe8")

var w := 0
var h := 0
var zoom := 4                  # screen pixels to a picture's pixel
var origin := Vector2.ZERO     # where the picture's corner sits
var tex: ImageTexture = null
var img: Image = null
var preview: Array = []        # pixels a shape would change
var mirror := ""               # "", "x", "y", "xy": its axes drawn
var _touches := {}
var _pinch := 0.0
var _pinch_zoom := 0.0
var _stroking := -2
var _panning := false
var _fitted := false


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(func():
		if not _fitted:
			fit())


## Shows these pixels (refit: and puts the picture in view).
func show_pixels(width: int, height: int, px: PackedByteArray, custom: Dictionary, refit := false) -> void:
	var same := width == w and height == h and img != null
	w = width
	h = height
	img = PixelModel.to_image(w, h, px, custom)
	if same and tex != null:
		tex.update(img)
	else:
		tex = ImageTexture.create_from_image(img)
	if refit or not same:
		_fitted = false
		fit()
	queue_redraw()


## Sets one pixel on the shown picture (faster than showing it all again).
func set_px(x: int, y: int, c: Color) -> void:
	if img != null and x >= 0 and y >= 0 and x < w and y < h:
		img.set_pixel(x, y, c)


func flush() -> void:
	if tex != null and img != null:
		tex.update(img)
	queue_redraw()


func fit() -> void:
	if w <= 0 or size.x <= 0.0 or size.y <= 0.0:
		return
	zoom = clampi(int(floor(minf((size.x - 16.0) / w, (size.y - 16.0) / h))), 1, ZOOM_MAX)
	origin = ((size - Vector2(w, h) * zoom) / 2.0).floor()
	_fitted = true
	queue_redraw()


func px_at(p: Vector2) -> Vector2i:
	var q := (p - origin) / float(zoom)
	return Vector2i(int(floor(q.x)), int(floor(q.y)))


func at(v: Vector2i) -> Vector2:
	return origin + (Vector2(v) + Vector2(0.5, 0.5)) * zoom


func zoom_to(z: int, about: Vector2) -> void:
	z = clampi(z, 1, ZOOM_MAX)
	if z == zoom:
		return
	origin = (about - (about - origin) * (float(z) / zoom)).floor()
	zoom = z
	queue_redraw()


func pan(by: Vector2) -> void:
	origin += by
	queue_redraw()


# ---------------------------------------------------------------- touch
func _gui_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed:
			_touches[e.index] = e.position
			if _touches.size() == 1:
				_stroking = e.index
				stroke.emit("begin", e.position)
			elif _touches.size() == 2:
				if _stroking != -2:
					_stroking = -2
					stroke.emit("cancel", e.position)
				_pinch = _two_distance()
				_pinch_zoom = zoom
		else:
			_touches.erase(e.index)
			if e.index == _stroking:
				_stroking = -2
				stroke.emit("end", e.position)
			if _touches.size() == 2:
				_pinch = _two_distance()
				_pinch_zoom = zoom
		accept_event()
	elif e is InputEventScreenDrag:
		var prev: Vector2 = _touches.get(e.index, e.position)
		_touches[e.index] = e.position
		if _touches.size() >= 2:
			if _pinch > 0.0:
				zoom_to(int(round(_pinch_zoom * _two_distance() / _pinch)), _two_mid())
			pan((e.position - prev) / 2.0)
		elif e.index == _stroking:
			stroke.emit("move", e.position)
		accept_event()
	elif e is InputEventMouseButton and e.device != InputEvent.DEVICE_ID_EMULATION:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			zoom_to(zoom + maxi(1, zoom / 4), e.position)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			zoom_to(zoom - maxi(1, zoom / 4), e.position)
		elif e.button_index == MOUSE_BUTTON_RIGHT or e.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = e.pressed
		elif e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_stroking = -1
				stroke.emit("begin", e.position)
			elif _stroking == -1:
				_stroking = -2
				stroke.emit("end", e.position)
		accept_event()
	elif e is InputEventMouseMotion and e.device != InputEvent.DEVICE_ID_EMULATION:
		if _stroking == -1:
			stroke.emit("move", e.position)
		elif _panning:
			pan(e.relative)
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
	if tex == null:
		return
	var r := Rect2(origin, Vector2(w, h) * zoom)
	# the checkerboard, in squares of 4 of the picture's pixels (or 8 screen pixels)
	var sq := maxf(8.0, zoom * 4.0)
	var vis := r.intersection(Rect2(Vector2.ZERO, size))
	if vis.size.x > 0 and vis.size.y > 0:
		var x0 := int(floor((vis.position.x - r.position.x) / sq))
		var y0 := int(floor((vis.position.y - r.position.y) / sq))
		var x1 := int(ceil((vis.end.x - r.position.x) / sq))
		var y1 := int(ceil((vis.end.y - r.position.y) / sq))
		for yy in range(y0, y1):
			for xx in range(x0, x1):
				var cell := Rect2(r.position + Vector2(xx, yy) * sq, Vector2(sq, sq)).intersection(r)
				if cell.size.x > 0 and cell.size.y > 0:
					draw_rect(cell, CHECK_A if (xx + yy) % 2 == 0 else CHECK_B)
	draw_texture_rect(tex, r, false)
	if zoom >= 8:
		var x_from := maxi(0, int(floor(-origin.x / zoom)))
		var x_to := mini(w, int(ceil((size.x - origin.x) / zoom)))
		var y_from := maxi(0, int(floor(-origin.y / zoom)))
		var y_to := mini(h, int(ceil((size.y - origin.y) / zoom)))
		for x in range(x_from, x_to + 1):
			draw_line(origin + Vector2(x * zoom, y_from * zoom), origin + Vector2(x * zoom, y_to * zoom), GRID, 1.0)
		for y in range(y_from, y_to + 1):
			draw_line(origin + Vector2(x_from * zoom, y * zoom), origin + Vector2(x_to * zoom, y * zoom), GRID, 1.0)
	draw_rect(r, Color("#5e718e"), false, 1.0)
	for p in preview:
		draw_rect(Rect2(origin + Vector2(p) * zoom, Vector2(zoom, zoom)), Color(PREVIEW, 0.55))
	if "x" in mirror:
		draw_line(origin + Vector2(w * zoom / 2.0, 0), origin + Vector2(w * zoom / 2.0, h * zoom), Color("#e88a36"), 2.0)
	if "y" in mirror:
		draw_line(origin + Vector2(0, h * zoom / 2.0), origin + Vector2(w * zoom, h * zoom / 2.0), Color("#e88a36"), 2.0)
