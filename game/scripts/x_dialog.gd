## Choosing X: a box in the middle of the screen with a number, a minus and a
## plus, and what that X would cost. For a carried Action card with a variable
## cost, which asks for its X each time it is used (Handbook 15.8, Variable
## Costs). It covers the board while it's up.
class_name XDialog
extends Control

signal chosen(x: int)        # the X picked, or 0 if it was put away

var value := 1
var hi := 1
var words: Callable          # func(x) -> what to say under the number
var title_label: Label
var value_label: Label
var text_label: Label
var minus_btn: Button
var plus_btn: Button
var ok_btn: Button
var cancel_btn: Button


func _init(title: String, most: int, say: Callable, ok_label := "Use it", accent := Color("#8aa1f6")) -> void:
	hi = maxi(1, most)
	words = say
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	var box := PanelContainer.new()
	set_meta("box", box)               # (0.12) what pops open and shut
	box.add_theme_stylebox_override("panel", UI.box(Color("#171819", 0.98), accent, 2, 8, 28))
	centre.add_child(box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	box.add_child(col)
	title_label = UI.label(title, 30, accent)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	col.add_child(row)
	minus_btn = UI.button("−", func(): step(-1), 90)
	row.add_child(minus_btn)
	value_label = UI.label("", 40, UI.GOLD)
	value_label.custom_minimum_size = Vector2(150, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(value_label)
	plus_btn = UI.button("+", func(): step(1), 90)
	row.add_child(plus_btn)
	text_label = UI.label("", 19, UI.TEXT, true)
	text_label.custom_minimum_size = Vector2(600, 0)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(text_label)
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_theme_constant_override("separation", 14)
	col.add_child(foot)
	cancel_btn = UI.button("Put it away", func(): chosen.emit(0), 180)
	foot.add_child(cancel_btn)
	ok_btn = UI.button(ok_label, func(): chosen.emit(value), 180)
	foot.add_child(ok_btn)
	_show()


func step(by: int) -> void:
	value = clampi(value + by, 1, hi)
	_show()


func _show() -> void:
	value_label.text = "X = %d" % value
	text_label.text = str(words.call(value)) if words.is_valid() else ""
	minus_btn.disabled = value <= 1
	plus_btn.disabled = value >= hi


## (0.12) It pops open.
func _ready() -> void:
	Motion.pop_in(get_meta("box"))
