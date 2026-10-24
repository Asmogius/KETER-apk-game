## A box in the middle of the screen with a title, a few lines and buttons:
## the end of a battle, or "end the round with Units still able to act?".
## It covers the board while it's up, so nothing behind it takes a tap.
class_name Dialog
extends Control

signal chosen(index: int)

## (0.32) What the phone's Back button picks: the first button that turns away
## ("Cancel", "Keep it", "Stay", "Close" ...); none, and it waits for a choice.
const SAFE := ["cancel", "keep it", "keep mine", "keep editing", "keep drawing", "stay", "stay on the map", "go back", "not now", "close", "ok"]

var title_label: Label
var text_label: Label
var buttons: Array[Button] = []
var box: PanelContainer
var stats: HFlowContainer = null       # (0.11) amounts as icons and numbers, under the text


func safe_index() -> int:
	for i in buttons.size():
		if SAFE.has(buttons[i].text.strip_edges().to_lower()):
			return i
	return -1


func _init(title: String, text: String, labels: Array, accent := Color("#73efe8")) -> void:
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
	box = PanelContainer.new()
	set_meta("box", box)               # (0.12) what pops open and shut
	var sb := PixelBox.new()
	sb.bg_color = Color("#171819", 0.98)
	sb.border_color = accent
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(20)
	sb.shadow = true
	sb.content_margin_left = 28; sb.content_margin_right = 28; sb.content_margin_top = 22; sb.content_margin_bottom = 22
	box.add_theme_stylebox_override("panel", sb)
	box.theme = Look.fight_theme()
	centre.add_child(box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	box.add_child(col)
	title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Look.size_to(title_label, 34)
	title_label.add_theme_color_override("font_color", accent)
	col.add_child(title_label)
	text_label = Label.new()
	text_label.text = text
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(560, 0)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Look.size_to(text_label, 19)
	col.add_child(text_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	col.add_child(row)
	for i in labels.size():
		var b := Button.new()
		b.text = labels[i]
		b.custom_minimum_size = Vector2(180, 60)
		var k := i
		b.pressed.connect(func(): chosen.emit(k))
		row.add_child(b)
		buttons.append(b)


## (0.11) A row of amounts under the text, each an icon and its number, with a
## few words over it: [[icon, text, colour], ...].
func add_stats(items: Array, caption := "") -> HFlowContainer:
	var col := text_label.get_parent()
	var at := text_label.get_index() + 1
	if caption != "":
		var c := Look.read(caption, UI.DIM)
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(c)
		col.move_child(c, at)
		at += 1
	stats = UI.stats_row(items, 24)
	stats.alignment = FlowContainer.ALIGNMENT_CENTER
	col.add_child(stats)
	col.move_child(stats, at)
	return stats


## (0.15) The title as a picture (Victory and Defeat, in neon), its words kept
## for the tests and for anyone reading the box's text.
var title_art: TextureRect = null


func set_title_art(tex: Texture2D, px := 2.0) -> void:
	if tex == null:
		return
	title_art = TextureRect.new()
	title_art.texture = tex
	title_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	title_art.custom_minimum_size = tex.get_size() * px
	title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var col := title_label.get_parent()
	col.add_child(title_art)
	col.move_child(title_art, title_label.get_index())
	title_label.visible = false


## (0.15) A short strip under the title: a few facts as chips, each its colour:
## [[text, colour], ...] (rounds, Units standing, Enemies down).
var strip: HBoxContainer = null


func add_strip(items: Array) -> HBoxContainer:
	strip = HBoxContainer.new()
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 10)
	for it in items:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UI.box(Color("#0e0c0c"), Color(it[1]).darkened(0.2), 1, 2, 10))
		var l := Look.read(str(it[0]), Color(it[1]))
		p.add_child(l)
		strip.add_child(p)
	var col := text_label.get_parent()
	col.add_child(strip)
	col.move_child(strip, text_label.get_index())
	return strip


## (0.15) What dropped, as tiles that come in one by one: each its picture, its
## count and its name. items: [[icon id, count text, colour], ...] (as UI.bag_items).
var loot_tiles: Array = []


func add_loot(items: Array, caption := "") -> HFlowContainer:
	var col := text_label.get_parent()
	var at := text_label.get_index() + 1
	if caption != "":
		var c := Look.read(caption, UI.DIM)
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(c)
		col.move_child(c, at)
		at += 1
	var flow := HFlowContainer.new()
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	col.add_child(flow)
	col.move_child(flow, at)
	for i in items.size():
		var it: Array = items[i]
		var tile := PanelContainer.new()
		tile.set_meta("icon", str(it[0]))
		tile.set_meta("count", str(it[1]))
		tile.add_theme_stylebox_override("panel", UI.box(UI.PANEL, Color(it[2]).darkened(0.35), 1, 4, 10))
		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 2)
		tile.add_child(v)
		var h := HBoxContainer.new()
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_theme_constant_override("separation", 6)
		v.add_child(h)
		h.add_child(UI.icon(str(it[0]), 48))
		var n := Look.title(str(it[1]), Color(it[2]))
		n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(n)
		var nm := Look.read(str(Art.ICONS.get(str(it[0]), str(it[0]))), UI.DIM)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nm)
		flow.add_child(tile)
		loot_tiles.append(tile)
		# one by one: each drops in a moment after the one before
		if not Motion.still and Motion.speed != "instant":
			tile.modulate.a = 0.0
			var tw := tile.create_tween()
			tw.tween_interval(0.25 + 0.14 * i * Motion.k())
			tw.tween_property(tile, "modulate:a", 1.0, 0.12 * Motion.k())
	stats = flow
	return flow


## (0.12) It pops open.
func _ready() -> void:
	Motion.pop_in(get_meta("box"))
