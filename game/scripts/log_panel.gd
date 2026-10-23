## The battle log: everything that has happened, round by round, newest at the
## bottom. Opened from the top bar's Log button; drag to scroll. Under the
## title: what has dropped and been found so far.
class_name LogPanel
extends PanelContainer

signal closed

const DIM := Color("#88a3bc")
const LOOT := Color("#efdd91")
var list: TouchList
var haul: Label
var count := 0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := PixelBox.new()
	sb.bg_color = Color("#171819", 1.0)
	sb.border_color = Color("#2c3b39")
	sb.border_width_left = 2
	sb.content_margin_left = 16; sb.content_margin_right = 14; sb.content_margin_top = 12; sb.content_margin_bottom = 12
	add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	var t := Label.new()
	t.text = "Battle log"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Look.size_to(t, 24)
	t.add_theme_color_override("font_color", Color("#73efe8"))
	head.add_child(t)
	var x := Button.new()
	x.text = "×"
	Look.size_to(x, 34)
	x.custom_minimum_size = Vector2(56, 56)
	x.pressed.connect(func(): closed.emit())
	head.add_child(x)
	haul = Label.new()
	haul.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	haul.custom_minimum_size = Vector2(UnitPanel.WIDTH + 30, 0)
	Look.size_to(haul, 16)
	haul.add_theme_color_override("font_color", LOOT)
	haul.visible = false
	col.add_child(haul)
	list = TouchList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.box.add_theme_constant_override("separation", 4)
	col.add_child(list)


## Shows the log, scrolled to the newest line. What cards did is white; the
## game's own news (how it ended) gold; text a card carries that isn't
## keywords, and so wasn't carried out, grey; a card problem red; loot pale
## yellow. loot_line: what has dropped so far, for under the title.
func show_log(entries: Array, loot_line := "") -> void:
	visible = true
	haul.text = loot_line
	haul.visible = loot_line != ""
	list.clear()
	var round := -1
	for e in entries:
		var text := str(e["text"])
		if e["kind"] == "note" and text.begins_with("Round "):
			round = e["round"]
			_line(text.to_upper(), DIM, 14)
			continue
		if e["round"] != round:
			round = e["round"]
			_line("ROUND %d" % round, DIM, 14)
		var col := Color("#e6e7f0")
		if e.get("halt", false):
			col = Color("#dd8877")
			text = "Card problem: " + text
		elif e.get("plain", false):
			col = DIM
		elif e["kind"] == "loot":
			col = LOOT
		elif e["kind"] != "act":
			col = Color("#d6a851")
		_line(text, col, 17)
	count = entries.size()
	if entries.is_empty():
		_line("Nothing has happened yet.", DIM, 17)
	list.scroll_by(1e9)


func _line(t: String, col: Color, fs: int) -> void:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(UnitPanel.WIDTH + 30, 0)
	Look.size_to(l, fs)
	l.add_theme_color_override("font_color", col)
	list.add_row(l)
