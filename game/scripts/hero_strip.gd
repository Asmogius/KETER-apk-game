## (0.39) Your Heroes at a glance: down the left of a fight, each with its
## Health as a bar and its Energy. Tap one to select it.
class_name HeroStrip
extends VBoxContainer

signal tapped(id: String)

const W := 190.0


func _init() -> void:
	add_theme_constant_override("separation", 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_heroes(b: Battle, selected_id := "") -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	if b == null:
		return
	for u in b.side_units("ally"):
		if not str(u.get("cardType", "")).to_lower().contains("hero"):
			continue
		add_child(_row(u, str(u["id"]) == selected_id))


func _row(u: Dictionary, on: bool) -> Control:
	var down := Rules.truthy(u.get("down"))
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(W, 0)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.add_theme_stylebox_override("panel", UI.box(Color("#171819", 0.9), UI.CYAN if on else UI.LINE, 2 if on else 1, 6, 8))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	var nm := UI.label(str(u.get("name", "")), 15, UI.DIM if down else UI.TEXT)
	nm.clip_text = true
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(nm)
	var hp := int(Rules.num(u.get("hp"), 0))
	var top := maxi(1, int(Rules.num(u.get("hpMax"), hp)))
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(W - 20, 8)
	bar.max_value = top
	bar.value = 0 if down else hp
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = UI.SOFT_RED if hp * 3 <= top else UI.GREEN
	bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("#2a2d30")
	bar.add_theme_stylebox_override("background", bg)
	v.add_child(bar)
	var line := UI.label("Down" if down else "Health %d/%d  ·  Energy %d" % [hp, top, int(Rules.num(u.get("nrg"), 0))], 13, UI.SOFT_RED if down else UI.PALE)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(line)
	var id := str(u["id"])
	p.gui_input.connect(func(e):
		if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or (e is InputEventScreenTouch and e.pressed):
			tapped.emit(id))
	p.set_meta("unit", id)
	return p
