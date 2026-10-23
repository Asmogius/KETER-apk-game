## The Look board (0.14): every piece of the game's look on one screen, to
## check on a phone at a glance. The type at its sizes, the buttons and frames
## of the UI kit, every icon, status mark and Aether gem, a card at the sizes it
## is printed, a row of Unit tokens, and the board's props and tiles. (0.15)
## And the World Map's pieces, each District's fight, and the menus' own:
## QM-7, and Victory and Defeat. (0.16) And the fight's effects, each playing
## over and over beside its frames. (0.17) And every card's own picture, for
## the cards that are not Units. (0.18) And the atmosphere's motes. (0.19) And
## the card back. Opened from Options; Close puts it away.
class_name LookBoard
extends Control

signal closed

var list: TouchList


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = Look.fight_theme()
	var bg := ColorRect.new()
	bg.color = UI.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 16)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(m)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	col.add_child(head)
	var t := Look.title("Look board", UI.TEXT, Look.TITLE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(130, 52)
	close.pressed.connect(func(): closed.emit())
	head.add_child(close)
	list = TouchList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.box.add_theme_constant_override("separation", 14)
	col.add_child(list)
	_fill()


func _heading(t: String) -> void:
	list.add_row(Look.title(t.to_upper(), UI.DIM, Look.SMALL))


func _row(kids: Array, sep := 12) -> void:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", sep)
	f.add_theme_constant_override("v_separation", 8)
	f.custom_minimum_size = Vector2(1200, 0)
	for k in kids:
		f.add_child(k)
	list.add_row(f)


func _pic(tex: Texture2D, k := 2.0, caption := "") -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var r := TextureRect.new()
	r.texture = tex
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var s := tex.get_size() if tex != null else Vector2(16, 16)
	r.custom_minimum_size = s * k
	v.add_child(r)
	if caption != "":
		v.add_child(Look.title(caption, UI.DIM, Look.SMALL))
	return v


func _fill() -> void:
	_heading("Type")
	_row([Look.title("Jersey 10 at 56", UI.GOLD, Look.HUGE), Look.title("Jersey 10 at 37: titles and numbers", UI.TEXT, Look.TITLE)])
	_row([Look.read("VT323 at 25: everything you read in a fight and on a card.", UI.PALE), Look.title("Jersey 10 at 19: a card's small print", UI.DIM, Look.SMALL)])
	_heading("Buttons")
	var kit := []
	for v in [["End turn", "MainButton"], ["Undo", ""], ["Give up", "DangerButton"]]:
		var b := Button.new()
		b.text = v[0]
		b.theme_type_variation = v[1]
		b.custom_minimum_size = Vector2(150, 52)
		if v[0] == "End turn":
			# (0.16) with its hourglass, as in a fight
			b.icon = Art.icon2("act_end")
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 32)
			b.add_theme_constant_override("h_separation", 8)
			b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		kit.append(b)
	var off := Button.new()
	off.text = "Can't now"
	off.disabled = true
	off.custom_minimum_size = Vector2(150, 52)
	kit.append(off)
	for ic in ["bar_auto", "bar_log", "bar_fit", "bar_leave", "bar_undo"]:
		var b2 := Button.new()
		b2.theme_type_variation = "IconButton"
		b2.icon = Art.icon2(ic)
		b2.expand_icon = true
		b2.add_theme_constant_override("icon_max_width", 32)
		b2.custom_minimum_size = Vector2(56, 52)
		b2.tooltip_text = ic
		kit.append(b2)
	var lit := Button.new()
	lit.theme_type_variation = "IconButton"
	lit.toggle_mode = true
	lit.button_pressed = true
	lit.icon = Art.icon2("bar_auto")
	lit.expand_icon = true
	lit.add_theme_constant_override("icon_max_width", 32)
	lit.custom_minimum_size = Vector2(56, 52)
	kit.append(lit)
	_row(kit)
	_heading("Frames")
	var frames := []
	for f in [["Panel", ""], ["Inset", "Inset"], ["Tooltip", "Tooltip"]]:
		var p := PanelContainer.new()
		p.theme_type_variation = f[1]
		p.custom_minimum_size = Vector2(220, 70)
		p.add_child(Look.read(f[0], UI.PALE))
		frames.append(p)
	_row(frames)
	_heading("Icons")
	var icons := []
	for k in ["shards", "part_troop", "part_equipment", "part_aether", "hp", "ac", "ms", "nrg", "aether", "skull"]:
		icons.append(_pic(Art.icon(k), 2.0))
	for k in Art.manifest().get("icons", {}).keys():
		icons.append(_pic(Art.piece("icons", k), 2.0))
	_row(icons, 8)
	_heading("Status marks and Aether gems")
	var marks := []
	for k in Art.manifest().get("marks", {}).keys():
		marks.append(_pic(Art.piece("marks", k), 2.0))
	_row(marks, 10)
	_heading("A card, at its two sizes")
	var c := {"name": "Arc Lance", "cardType": "action", "affinities": [{"district": "3"}], "entries": [{"name": "Arc Lance", "kind": "Active", "role": "ranged", "damage": "4", "attackRange": "4", "toHit": "8", "text": "[[target enemy]] takes [[damage 4]] and gains [[Stunned]] for [[turns 1]]."}]}
	var small := CardTile.new(c, null)
	var large := CardFace.Face.new(c, null)
	_row([small, large])
	_heading("Tokens")
	var toks := []
	var keys: Array = Art.manifest().get("tokens", {}).keys()
	for i in mini(keys.size(), 12):
		toks.append(_pic(Art.piece("tokens", keys[i]), 2.0))
	_row(toks, 6)
	_heading("The board")
	var board := []
	for k in Art.manifest().get("board", {}).keys():
		board.append(_pic(Art.piece("board", k), 2.0))
	_row(board, 6)
	# (0.15) the World Map, each District's fight, the menus
	_heading("The World Map")
	var ground := []
	for d in ["1", "2", "3", "4", "5", "6", ""]:
		var g := Art.map_ground(d)
		if not g.is_empty():
			ground.append(_pic(g[0]["texture"], 1.0, ("District " + d) if d != "" else "No District"))
	var rb := Art.rubble()
	if not rb.is_empty():
		ground.append(_pic(rb[0]["texture"], 1.0, "Collapsed"))
	_row(ground, 10)
	var things := []
	var hg := Art.hangar()
	if not hg.is_empty():
		things.append(_pic(hg["texture"], 2.0, "The Hangar"))
	for d in ["1", "2", "3", "4", "5", "6"]:
		for p in Art.map_props(d):
			things.append(_pic(p["texture"], 2.0))
	_row(things, 6)
	var icons2 := []
	for k in ["poi", "unique", "ambush", "cache", "event"]:
		var ic := Art.map_icon(k)
		if not ic.is_empty():
			icons2.append(_pic(ic["texture"], 2.0, k.capitalize()))
	for d in ["1", "2", "3", "4", "5", "6"]:
		icons2.append(_pic(Art.icon2("district_" + d), 2.0, "D" + d))
	_row(icons2, 12)
	_heading("Each District's fight")
	var dist := []
	for d in ["1", "2", "3", "4", "5", "6"]:
		for n in ["floor_0", "half_cover", "full_cover"]:
			var e := Art.district_board(d, n)
			if not e.is_empty():
				dist.append(_pic(e["texture"], 1.0 if n == "floor_0" else 1.0, ("D" + d) if n == "floor_0" else ""))
	_row(dist, 6)
	_heading("The menus")
	_row([_pic(Art.menu_piece("qm7"), 2.0, "QM-7"), _pic(Art.menu_piece("qm7_blink"), 2.0, "blinking"), _pic(Art.menu_piece("victory"), 2.0), _pic(Art.menu_piece("defeat"), 2.0)], 16)
	# (0.16) the fight's effects: each playing, then its frames
	_heading("The fight's effects")
	for name in Art.FX:
		var f := Art.fx(name)
		if f.is_empty() or (f["frames"] as Array).is_empty():
			continue
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		var loop := FxLoop.new(f)
		loop.set_meta("fx", name)
		v.add_child(loop)
		v.add_child(Look.title(name.capitalize() + ("  (yours)" if f.get("mine", false) else ""), UI.DIM, Look.SMALL))
		var row := [v]
		for i in (f["frames"] as Array).size():
			row.append(_pic(f["frames"][i], 2.0, str(i + 1)))
		_row(row, 6)
	# (0.18) the atmosphere's motes, each looping, then its frames
	_heading("The fight's atmosphere")
	for name in Atmos.MOTES:
		var f := Art.fx(name)
		if f.is_empty() or (f["frames"] as Array).is_empty():
			continue
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		var loop := FxLoop.new(f)
		loop.set_meta("mote", name)
		v.add_child(loop)
		v.add_child(Look.title(name.capitalize() + ("  (yours)" if f.get("mine", false) else ""), UI.DIM, Look.SMALL))
		var row := [v]
		for i in (f["frames"] as Array).size():
			row.append(_pic(f["frames"][i], 4.0, str(i + 1)))
		_row(row, 6)
	# (0.19) the card back, as the hand is dealt
	_heading("Card back")
	var back := _pic(Art.card_back(), 2.0, "the KETER emblem")
	back.set_meta("cardback", true)
	_row([back], 12)
	# (0.17) each card that is not a Unit: its own picture, at its pixels
	_heading("Card art")
	var arts: Dictionary = Art.manifest().get("cardart", {})
	var art_keys := arts.keys()
	art_keys.sort()
	var pics := []
	for k in art_keys:
		var tex := Art.piece("cardart", k)
		if tex != null:
			var p := _pic(tex, 1.0)
			p.set_meta("cardart", k)
			pics.append(p)
	_row(pics, 4)


## (0.16) An effect playing over and over at its own speed, at twice its
## pixels, with a pause between.
class FxLoop extends Control:
	var fx: Dictionary
	var t := 0.0

	func _init(f: Dictionary) -> void:
		fx = f
		custom_minimum_size = f["size"] * 2.0
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var frames: Array = fx["frames"]
		if frames.is_empty():
			return
		var fps := float(fx["fps"])
		var i := int(fmod(t, frames.size() / fps + 0.4) * fps)
		if i < frames.size():
			draw_texture_rect(frames[i], Rect2(Vector2.ZERO, fx["size"] * 2.0), false)
