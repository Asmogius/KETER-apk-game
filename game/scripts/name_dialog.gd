## A box asking for a name: a line to type in, OK and Cancel. The phone's
## keyboard comes up when the line is tapped.
class_name NameDialog
extends Control

signal named(text: String)
signal cancelled

var edit: LineEdit
var ok_btn: Button


func _init(title: String, start := "", hint := "") -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	# near the top, so the phone's keyboard doesn't cover it
	var holder := MarginContainer.new()
	holder.set_anchors_preset(Control.PRESET_TOP_WIDE)
	holder.add_theme_constant_override("margin_top", 60)
	holder.add_theme_constant_override("margin_left", 300)
	holder.add_theme_constant_override("margin_right", 300)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	var panel := PanelContainer.new()
	set_meta("box", panel)               # (0.12) what pops open and shut
	panel.add_theme_stylebox_override("panel", UI.box(Color("#171819", 0.99), UI.CYAN, 2, 8, 26))
	holder.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)
	col.add_child(UI.label(title, 26, UI.CYAN))
	if hint != "":
		col.add_child(UI.label(hint, 17, UI.PALE, true))
	edit = LineEdit.new()
	edit.text = start
	edit.max_length = 40
	edit.custom_minimum_size = Vector2(0, 60)
	edit.add_theme_font_size_override("font_size", Look.fs(24))
	edit.select_all_on_focus = true
	edit.text_submitted.connect(func(_t): _done())
	col.add_child(edit)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 14)
	col.add_child(row)
	row.add_child(UI.button("Cancel", func(): cancelled.emit()))
	ok_btn = UI.button("OK", _done)
	row.add_child(ok_btn)


func _ready() -> void:
	Motion.pop_in(get_meta("box"))
	edit.grab_focus()


func _done() -> void:
	var t := edit.text.strip_edges()
	if t != "":
		named.emit(t)
