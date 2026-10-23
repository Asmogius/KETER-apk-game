## A screen's backdrop (0.11): the game's picture, or yours, filling the
## screen in pixels, and dimmed so that what sits on it can be read.
class_name Backdrop
extends Control

var kind := "menu"                     # "title", "dock" or "menu"
var dim := 0.66                        # how much darker than the picture it is
var _serial := -1


func _init(k := "menu", how_dim := 0.66) -> void:
	kind = k
	dim = how_dim
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED or what == NOTIFICATION_RESIZED:
		queue_redraw()


func _process(_delta: float) -> void:
	# a new export's pictures: drawn again
	if _serial != Art.serial and is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	_serial = Art.serial
	draw_rect(Rect2(Vector2.ZERO, size), UI.BG)
	var tex := Art.backdrop(kind)
	if tex == null:
		return
	# whole multiples of the picture's pixels, enough to cover the screen, centred
	var ts := tex.get_size()
	var k := maxf(ceil(size.x / ts.x), ceil(size.y / ts.y))
	var at := ((size - ts * k) / 2.0).floor()
	draw_texture_rect(tex, Rect2(at, ts * k), false)
	if dim > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(UI.BG, dim))
