## How one of your Units fights on Auto: the twelve Behavior keywords a Player
## Unit may carry, each with what it does. Tap one to put it on or take it
## off; up to three, and the order you put them on is the order they count in.
## Wary and Prudent take a number: the minus and the plus beside it. Done
## hands back the choice. It covers the screen while it's up.
class_name BehaviorSheet
extends Control

signal done(list: Array)

var unit_name := ""
var picked: Array = []
var list: TouchList
var summary: Label
var note_label: Label
var done_btn: Button
var _rows: Array = []          # {k, row, minus, plus}


func _init(name: String, chosen: Array) -> void:
	unit_name = name
	picked = Behaviors.clean(chosen)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 90)
	m.add_theme_constant_override("margin_top", 30)
	m.add_theme_constant_override("margin_bottom", 30)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(m)
	var panel := PanelContainer.new()
	set_meta("box", panel)               # (0.12) what pops open and shut
	panel.add_theme_stylebox_override("panel", UI.box(Color("#171819", 0.99), UI.CYAN, 2, 10, 22))
	m.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	col.add_child(UI.label("How %s fights on Auto" % name, 26, UI.TEXT, true))
	summary = UI.label("", 17, UI.GOLD, true)
	col.add_child(summary)
	list = TouchList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.box.add_theme_constant_override("separation", 6)
	list.row_tapped.connect(_on_row)
	col.add_child(list)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	col.add_child(foot)
	note_label = UI.label("", 16, UI.PALE, true)
	note_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(note_label)
	done_btn = UI.button("Done", func(): done.emit(picked), 170)
	foot.add_child(done_btn)
	_fill()


## What is chosen, in a line: "1 Decisive, then 2 Wary 2", and anything the
## rules have to say about it.
func summary_text() -> String:
	var t := "Tap a keyword to put it on or take it off. Up to three; where two apply at once, the one put on first wins."
	if picked.is_empty():
		return t + "  None chosen: it attacks the closest Enemy."
	var said := "Chosen: " + Behaviors.words(picked) + "."
	for p in Behaviors.problems(picked):
		said += "  " + p
	return said


func _fill() -> void:
	var keep := list.scroll
	list.clear()
	_rows = []
	for d in Behaviors.choices():
		_add_row(d)
	list.scroll_by(keep)
	summary.text = summary_text()
	note_label.text = "The game remembers this for every %s." % unit_name


func _add_row(d: Dictionary) -> void:
	var at := -1
	for i in picked.size():
		if picked[i]["k"] == d["k"]:
			at = i
	var on := at >= 0
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 66)
	var sb := PixelBox.new()
	sb.bg_color = Color("#282c3c") if on else Color("#171819")
	sb.border_color = UI.CYAN if on else UI.LINE
	sb.set_border_width_all(3 if on else 1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12; sb.content_margin_right = 12; sb.content_margin_top = 6; sb.content_margin_bottom = 6
	row.add_theme_stylebox_override("panel", sb)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	row.add_child(hb)
	var badge := UI.label(str(at + 1) if on else "", 24, UI.CYAN)
	badge.custom_minimum_size = Vector2(26, 0)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(badge)
	var txt := VBoxContainer.new()
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	txt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	txt.add_theme_constant_override("separation", 1)
	hb.add_child(txt)
	var b := {"k": d["k"]}
	if d.has("param"):
		b["x"] = int(picked[at]["x"]) if on else int(d["pdef"])
	var kind: String = {"target": "who it attacks", "move": "where it goes", "support": "what else it does"}.get(d["cat"], "")
	txt.add_child(UI.label(str(d["name"]) + ((" " + str(b["x"])) if d.has("param") else "") + "   ·   " + kind + ("" if d["cond"] else ", always"), 19, UI.TEXT if on else UI.PALE))
	var what := UI.label(Behaviors.text_of(b), 15, UI.DIM, true)
	what.custom_minimum_size = Vector2(560, 0)
	txt.add_child(what)
	var entry := {"k": d["k"], "row": row}
	if d.has("param") and on:
		var minus := _count_box("−")
		var plus := _count_box("+")
		hb.add_child(minus)
		hb.add_child(plus)
		entry["minus"] = minus
		entry["plus"] = plus
	_rows.append(entry)
	list.add_row(row)


func _count_box(sign_text: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(64, 54)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb := PixelBox.new()
	sb.bg_color = Color("#2c3438")
	sb.set_corner_radius_all(6)
	p.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = sign_text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", Look.fs(28))
	p.add_child(l)
	return p


func _hit(entry: Dictionary, key: String, at: Vector2) -> bool:
	var c: Control = entry.get(key)
	if c == null:
		return false
	var row: Control = entry["row"]
	return Rect2(c.global_position - row.global_position, c.size).grow(6).has_point(at)


func _on_row(i: int, at: Vector2) -> void:
	if i < 0 or i >= _rows.size():
		return
	var e: Dictionary = _rows[i]
	if _hit(e, "minus", at):
		step(e["k"], -1)
	elif _hit(e, "plus", at):
		step(e["k"], 1)
	else:
		toggle(e["k"])


## Puts a keyword on or takes it off.
func toggle(k: String) -> void:
	var r := Behaviors.toggle(picked, k)
	picked = r["list"]
	_fill()
	if r["note"] != "":
		note_label.text = r["note"]


## Changes the number on Wary or Prudent.
func step(k: String, by: int) -> void:
	picked = Behaviors.step(picked, k, by)
	_fill()


## (0.12) It pops open.
func _ready() -> void:
	Motion.pop_in(get_meta("box"))
