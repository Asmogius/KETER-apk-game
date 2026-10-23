## The bar behind a fight's bottom line (0.11): a dark pixel frame just as tall
## as the lines it holds, so what it says reads over the board, and nothing
## when there is nothing to say.
class_name InfoBack
extends Control

var of: Label = null                   # the line it sits behind
var box: PixelBox
var _was := ""


func _init(label: Label) -> void:
	of = label
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	box = Look.frame(Color("#0e0c0c", 0.82), Color("#282c3c"), 1, 1, Vector2.ZERO)
	box.bevel = false


## Where it is drawn: around the lines the label shows, full width; or nothing.
func area() -> Rect2:
	if of == null or not of.is_visible_in_tree() or of.text.strip_edges() == "":
		return Rect2()
	var n := maxi(1, of.get_line_count())
	var lh := of.get_line_height()
	var h := n * lh + (n - 1) * of.get_theme_constant("line_spacing") + 10
	var at := of.position + Vector2(-8, of.size.y - h - 2)
	return Rect2(at.floor(), Vector2(of.size.x + 16, h + 6).floor())


func _process(_delta: float) -> void:
	var k := str(area()) + of.text if of != null else ""
	if k != _was:
		_was = k
		queue_redraw()


func _draw() -> void:
	var r := area()
	if r.size.x > 0.0:
		draw_style_box(box, r)
