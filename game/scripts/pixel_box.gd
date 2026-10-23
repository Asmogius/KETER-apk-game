## A frame for panels, rows, chips, tabs and buttons, drawn in pixels (0.11):
## a fill and an outline on a 2-pixel grid, the corners cut in steps, a light
## line under the top edge and a dark one over the bottom.
##
## It answers to what the game used to set on its flat boxes (bg_color,
## border_color, set_border_width_all, set_corner_radius_all and the content
## margins), so every screen can wear it.
class_name PixelBox
extends StyleBox

const PX := 2.0                        # one pixel of the frame, on the screen

var bg_color := Color("#171819")
var border_color := Color("#2c3b39")
var border := 0                        # in frame pixels; 0 draws no outline (as a flat box starts)
var notch := 0                         # how many steps each corner is cut by
var bevel := true                      # the light top and dark bottom lines
var shadow := false                    # a dark pixel offset under it
var only_left := false                 # a side panel, or a row with a stripe: its left edge only
var only_top := false                  # a tray along the bottom: its top edge only
var side_px := 2.0                     # how thick that one edge is, in screen pixels
## (as on a flat box: one edge only, this thick)
var border_width_left: int:
	set(v):
		only_left = v > 0
		side_px = maxf(PX, round(v / PX) * PX)
	get:
		return int(side_px) if only_left else 0
var border_width_top: int:
	set(v):
		only_top = v > 0
		side_px = maxf(PX, round(v / PX) * PX)
	get:
		return int(side_px) if only_top else 0


## (as on a flat box: 1 is a thin edge, 2 or more a heavy one)
func set_border_width_all(w: int) -> void:
	border = 0 if w <= 0 else (1 if w <= 1 else 2)


## (as on a flat box: a rounder corner is cut deeper)
func set_corner_radius_all(r: int) -> void:
	notch = 0 if r <= 0 else (1 if r <= 3 else (2 if r <= 8 else 3))


## The stepped shape: rows of rects, each corner cut by n steps of PX.
static func _shape(ci: RID, r: Rect2, n: int, c: Color) -> void:
	if c.a <= 0.0 or r.size.x <= 0.0 or r.size.y <= 0.0:
		return
	var steps := mini(n, int(floor(minf(r.size.x, r.size.y) / (2.0 * PX))))
	var cut := steps * PX
	for k in steps:
		var inset := (steps - k) * PX
		RenderingServer.canvas_item_add_rect(ci, Rect2(r.position.x + inset, r.position.y + k * PX, r.size.x - 2.0 * inset, PX), c)
		RenderingServer.canvas_item_add_rect(ci, Rect2(r.position.x + inset, r.end.y - (k + 1) * PX, r.size.x - 2.0 * inset, PX), c)
	RenderingServer.canvas_item_add_rect(ci, Rect2(r.position.x, r.position.y + cut, r.size.x, r.size.y - 2.0 * cut), c)


func _draw(ci: RID, rect: Rect2) -> void:
	var r := Rect2(rect.position.round(), rect.size.round())
	if only_left:
		_shape(ci, r, notch, bg_color)
		RenderingServer.canvas_item_add_rect(ci, Rect2(r.position.x, r.position.y + notch * PX, side_px, r.size.y - 2.0 * notch * PX), border_color)
		return
	if only_top:
		RenderingServer.canvas_item_add_rect(ci, r, bg_color)
		RenderingServer.canvas_item_add_rect(ci, Rect2(r.position, Vector2(r.size.x, side_px)), border_color)
		RenderingServer.canvas_item_add_rect(ci, Rect2(r.position.x, r.position.y + side_px, r.size.x, PX), bg_color.lightened(0.1))
		return
	if shadow:
		_shape(ci, Rect2(r.position + Vector2(PX, PX), r.size), notch, Color(0, 0, 0, 0.55 * bg_color.a))
	var b := border * PX
	if border > 0:
		_shape(ci, r, notch, border_color)
	var inner := r.grow(-b)
	_shape(ci, inner, maxi(0, notch - border), bg_color)
	if bevel and inner.size.y > 4.0 * PX and bg_color.a > 0.0:
		var cut := maxi(0, notch - border) * PX
		RenderingServer.canvas_item_add_rect(ci, Rect2(inner.position.x + cut, inner.position.y, inner.size.x - 2.0 * cut, PX), bg_color.lightened(0.12))
		RenderingServer.canvas_item_add_rect(ci, Rect2(inner.position.x + cut, inner.end.y - PX, inner.size.x - 2.0 * cut, PX), bg_color.darkened(0.35))


func copy() -> PixelBox:
	var o := PixelBox.new()
	o.bg_color = bg_color
	o.border_color = border_color
	o.border = border
	o.notch = notch
	o.bevel = bevel
	o.shadow = shadow
	o.only_left = only_left
	o.only_top = only_top
	o.side_px = side_px
	o.content_margin_left = content_margin_left
	o.content_margin_right = content_margin_right
	o.content_margin_top = content_margin_top
	o.content_margin_bottom = content_margin_bottom
	return o
