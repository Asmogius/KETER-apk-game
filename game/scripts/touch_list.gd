## A list you scroll by dragging and pick from by tapping, made for a phone:
## a drag never counts as a tap, however it ends. Each row is a Control; a tap
## reports which row, and where on it, so a row can hold its own buttons
## (a minus and a plus, say) without them fighting the scrolling.
class_name TouchList
extends Control

signal row_tapped(index: int, at: Vector2)

const TAP_MOVE := 14.0
const TAP_TIME := 450

var box: VBoxContainer
var scroll := 0.0
var _press := {}           # touch index (or -1 for the mouse) -> {at, start, moved}


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	resized.connect(_layout)
	box.resized.connect(_layout)


func clear() -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	scroll = 0.0
	_layout()


func add_row(row: Control) -> void:
	_ignore(row)
	box.add_child(row)


## For rows that were filled in after they were added: they don't take the
## touch either.
func settle() -> void:
	for r in box.get_children():
		if r is Control:
			_ignore(r)


func rows() -> Array[Node]:
	return box.get_children()


## Rows never take the touch themselves; the list decides what it was.
func _ignore(c: Control) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k in c.get_children():
		if k is Control:
			_ignore(k)


func max_scroll() -> float:
	return maxf(0.0, box.size.y - size.y)


func scroll_by(dy: float) -> void:
	scroll += dy
	_layout()


func _layout() -> void:
	# sized now, not at the next frame, so a list rebuilt under the finger
	# keeps its place
	box.size = Vector2(size.x, box.get_combined_minimum_size().y)
	scroll = clampf(scroll, 0.0, max_scroll())
	box.position = Vector2(0, -scroll)


## Which row is under a point (in the list's own coordinates), and where on it.
func row_at(p: Vector2) -> Array:
	var i := 0
	for r in box.get_children():
		if r is Control and r.visible:
			var rect := Rect2(box.position + r.position, r.size)
			if rect.has_point(p):
				return [i, p - rect.position]
		i += 1
	return [-1, Vector2.ZERO]


func tap(p: Vector2) -> void:
	var hit := row_at(p)
	if hit[0] >= 0:
		row_tapped.emit(hit[0], hit[1])


func _gui_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		_touch(e.index, e.position, e.pressed)
		accept_event()
	elif e is InputEventScreenDrag:
		if _press.has(e.index):
			_press[e.index]["moved"] += e.relative.length()
		scroll_by(-e.relative.y)
		accept_event()
	elif e is InputEventMouseButton and e.device != InputEvent.DEVICE_ID_EMULATION:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			scroll_by(-60)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			scroll_by(60)
		elif e.button_index == MOUSE_BUTTON_LEFT:
			_touch(-1, e.position, e.pressed)
		accept_event()
	elif e is InputEventMouseMotion and e.device != InputEvent.DEVICE_ID_EMULATION and _press.has(-1):
		_press[-1]["moved"] += e.relative.length()
		scroll_by(-e.relative.y)
		accept_event()


func _touch(index: int, p: Vector2, pressed: bool) -> void:
	if pressed:
		_press[index] = {"at": Time.get_ticks_msec(), "moved": 0.0}
	else:
		var pr = _press.get(index)
		_press.erase(index)
		if pr != null and pr["moved"] < TAP_MOVE and Time.get_ticks_msec() - pr["at"] < TAP_TIME:
			tap(p)
