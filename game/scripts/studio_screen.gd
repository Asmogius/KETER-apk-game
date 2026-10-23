## The Sandbox's Pixel Studio (0.30), the Companion's studio made over for a
## thumb. Every card's art and token (as the export has drawn them, or as you
## have since), and your own pictures; and for one, its canvas, drawn with a
## finger in the KETER palette.
##
## The tools: Pencil, Eraser, Fill, Pick (a colour off the picture), Line,
## Rectangle and Ellipse (outlined or filled); a brush of 1 to 6 pixels,
## square or round; mirroring left and right, top and bottom, or both. Two
## fingers pinch and pan; Undo and Redo. Pictures drawn in hex pixels stay the
## Companion's to draw.
##
## Save keeps it in the Sandbox (sandbox.gd), and the card wears it at once,
## everywhere the game shows it. Reset puts the export's picture back; Delete
## takes the picture away. A blank canvas is a picture of yours that no card
## wears. Export writes your pictures for the Companion with the cards.
class_name StudioScreen
extends Control

signal closed
signal changed                 # the Sandbox's pictures have changed: the game reads them again
signal tool_requested(k: String)

const VIEWS := [["art", "Card art"], ["token", "Tokens"], ["mine", "Your pictures"]]
const TOOLS := [["pencil", "Pencil"], ["eraser", "Eraser"], ["fill", "Fill"], ["pick", "Pick"], ["line", "Line"], ["rect", "Rectangle"], ["ellipse", "Ellipse"]]
const BRUSHES := [1, 2, 3, 4, 6]
const MIRRORS := [["", "Off"], ["x", "Left-right"], ["y", "Top-bottom"], ["xy", "Both"]]
const UNDO_MAX := 40
const PAGE := 40

var roster: Roster = null
var mode := "list"
var view := "art"
var query := ""
var page := 0
var target := {}               # {kind: "card", key, what, card} or {kind: "canvas"}
var pid := ""                  # the picture of yours being drawn ("" while it is new)
var pic_name := ""
var w := 0
var h := 0
var px := PackedByteArray()
var custom := {}
var dirty := false
var tool := "pencil"
var filled := false
var brush_size := 1
var round_tip := false
var mirror := ""
var colour := 1
var undo: Array = []
var redo: Array = []
var dialog: Control = null

var title: Label
var tools := {}
var tool_row: HBoxContainer
var sub: HFlowContainer
var search: LineEdit
var hint: Label
var body: HBoxContainer
var list: TouchList
var canvas: PixelCanvas
var form: TouchList
var note: Label
var back_btn: Button
var export_btn: Button
var new_btn: Button
var undo_btn: Button
var redo_btn: Button
var fit_btn: Button
var save_btn: Button
var delete_btn: Button
var reset_btn: Button
var _shown: Array = []         # the list's rows: {card, what} or {id} each (or null)
var _rows: Array = []
var _stroke := {}


func _init() -> void:
	var col := UI.page(self, "menu", 0.78)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	col.add_child(head)
	title = UI.label("Sandbox · Pixel Studio", 30, UI.CYAN)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	head.add_child(title)
	tool_row = HBoxContainer.new()
	tool_row.add_theme_constant_override("separation", 8)
	head.add_child(tool_row)
	for t in ForgeScreen.TOOLS:
		var k: String = t[0]
		var b := UI.button(t[1], func(): _tool(k), 150)
		b.toggle_mode = true
		b.button_pressed = k == "studio"
		tool_row.add_child(b)
		tools[k] = b
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	col.add_child(bar)
	sub = HFlowContainer.new()
	sub.add_theme_constant_override("h_separation", 6)
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(sub)
	search = LineEdit.new()
	search.placeholder_text = "Find a card"
	search.custom_minimum_size = Vector2(300, 0)
	search.add_theme_font_override("font", Look.font())
	search.add_theme_font_size_override("font_size", 20)
	search.text_changed.connect(func(t):
		query = t.strip_edges().to_lower()
		page = 0
		if mode == "list":
			_fill_list())
	bar.add_child(search)
	hint = UI.label("", 16, UI.PALE, true)
	col.add_child(hint)
	body = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	col.add_child(body)
	list = TouchList.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.row_tapped.connect(_on_list_row)
	body.add_child(list)
	canvas = PixelCanvas.new()
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.stroke.connect(_on_stroke)
	body.add_child(canvas)
	form = TouchList.new()
	form.custom_minimum_size = Vector2(470, 0)
	form.size_flags_vertical = Control.SIZE_EXPAND_FILL
	form.row_tapped.connect(_on_form_row)
	body.add_child(form)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	col.add_child(foot)
	back_btn = UI.button("Home", _back, 120)
	foot.add_child(back_btn)
	note = UI.label("", 17, UI.GOLD, true)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	foot.add_child(note)
	export_btn = UI.button("Export", export_all, 140)
	foot.add_child(export_btn)
	new_btn = UI.button("Blank canvas", ask_new, 200)
	new_btn.theme_type_variation = "MainButton"
	foot.add_child(new_btn)
	undo_btn = UI.button("Undo", do_undo, 100)
	foot.add_child(undo_btn)
	redo_btn = UI.button("Redo", do_redo, 100)
	foot.add_child(redo_btn)
	fit_btn = UI.button("Fit", func(): canvas.fit(), 80)
	foot.add_child(fit_btn)
	reset_btn = UI.button("Reset", ask_reset, 110)
	foot.add_child(reset_btn)
	delete_btn = UI.button("Delete", ask_delete, 110)
	foot.add_child(delete_btn)
	save_btn = UI.button("Save", save_picture, 130)
	save_btn.theme_type_variation = "MainButton"
	foot.add_child(save_btn)


func open(r: Roster) -> void:
	roster = r
	_close_dialog()
	show_list()


func _tool(k: String) -> void:
	for t in tools:
		tools[t].set_pressed_no_signal(t == "studio")
	if k != "studio" and dialog == null:
		tool_requested.emit(k)


func say(t: String, bad := false) -> void:
	note.text = t
	note.add_theme_color_override("font_color", UI.SOFT_RED if bad else UI.GOLD)


func _back() -> void:
	if dialog != null:
		return
	if mode == "edit":
		if dirty:
			_ask("Leave without saving?", "What you have drawn isn't kept.", ["Keep drawing", "Leave"], func(k):
				if k == 1:
					show_list())
			return
		show_list()
	else:
		closed.emit()


# ---------------------------------------------------------------- the list
## The cards that may have a picture of this kind: units for tokens, every card for art.
func cards_for(what: String) -> Array:
	if roster == null:
		return []
	var cs: Array = roster.cards.filter(func(c): return not ["workshop", "design", "prebuilt"].has(str(c.get("_src", ""))))
	if what == "token":
		cs = cs.filter(func(c): return ForgeModel.is_unit(str(c.get("cardType", ""))))
	if query != "":
		cs = cs.filter(func(c): return query in str(c.get("name", "")).to_lower())
	return cs


## What a card wears now: {texture, source: "yours" | "export" | "none" | "removed", hex}.
func wearing(card: Dictionary, what: String) -> Dictionary:
	var k := Sandbox.key_of(card)
	var lk = Sandbox.link_of(k, what)
	if lk is String and lk != "":
		return {"texture": Sandbox.picture_texture(lk), "source": "yours", "id": lk}
	if lk is String:
		return {"texture": null, "source": "removed"}
	var f := export_file(card, what)
	if f.is_empty():
		return {"texture": null, "source": "none"}
	return {"texture": roster.data.texture(str(f.get("file", ""))), "source": "export", "hex": str(f.get("grid", "")) == "hex"}


## The export's picture of a card: its manifest entry, or {}.
func export_file(card: Dictionary, what: String) -> Dictionary:
	if roster == null:
		return {}
	var f := roster.data.card_file(str(card.get("_artName", card.get("name", ""))), what)
	var own = card.get("pixelArt" if what == "art" else "pixelToken")
	if f.is_empty() and Rules.truthy(own):
		f = roster.data.picture_file(own)
	return f


func show_list() -> void:
	mode = "list"
	target = {}
	pid = ""
	dirty = false
	undo = []
	redo = []
	title.text = "Sandbox · Pixel Studio"
	tool_row.visible = true
	back_btn.text = "Home"
	list.visible = true
	canvas.visible = false
	form.visible = false
	search.visible = view != "mine"
	for b in [save_btn, delete_btn, reset_btn, undo_btn, redo_btn, fit_btn]:
		b.visible = false
	export_btn.visible = true
	new_btn.visible = true
	for c in sub.get_children():
		c.queue_free()
	for v in VIEWS:
		var vv: String = v[0]
		var b := UI.button(v[1], func():
			view = vv
			page = 0
			show_list(), 0)
		b.toggle_mode = true
		b.button_pressed = view == vv
		sub.add_child(b)
	_fill_list()


func _fill_list() -> void:
	var keep := list.scroll
	list.clear()
	_shown = []
	if view == "mine":
		var ids: Array = Sandbox.pictures().keys()
		ids.sort()
		hint.text = "%d picture%s of yours. A card's picture you drew is here with the card wearing it; a blank canvas is here on its own. Tap one to draw on it." % [ids.size(), "" if ids.size() == 1 else "s"]
		var sizes := PanelContainer.new()
		sizes.add_theme_stylebox_override("panel", UI.box(UI.PANEL, UI.LINE, 1, 6, 8))
		var sv := VBoxContainer.new()
		sizes.add_child(sv)
		sv.add_child(UI.label("A blank canvas, in pixels (a Unit's token is 48 by 48; card art is 128 across):", 15, UI.PALE, true))
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 6)
		for bs in PixelModel.BLANK_SIZES:
			flow.add_child(UI.chip("%d by %d" % [bs[0], bs[1]], UI.CYAN, ["new", bs[0], bs[1]], false, 15))
		sv.add_child(flow)
		list.add_row(sizes)
		_shown.append({"sizes": true})
		for id in ids:
			var p := Sandbox.picture(id)
			var wr := Sandbox.wearer(id)
			var on := ""
			if not wr.is_empty():
				on = "%s of %s" % ["Art" if wr[1] == "art" else "Token", wr[0].get_slice("|", 1)]
			list.add_row(_row_of(Sandbox.picture_texture(id), str(p.get("name", "")) if str(p.get("name", "")) != "" else id, "%d by %d%s" % [int(p["w"]), int(p["h"]), (" · " + on) if on != "" else " · a blank canvas", ], "Yours"))
			_shown.append({"id": id})
		if ids.is_empty():
			list.add_row(UI.label("No pictures of yours yet. Draw on a card's art or token, or start a blank canvas.", 16, UI.DIM, true))
			_shown.append(null)
	else:
		var cs := cards_for(view)
		var pages := maxi(1, int(ceil(cs.size() / float(PAGE))))
		page = clampi(page, 0, pages - 1)
		hint.text = "%d card%s. Tap one to draw its %s. Hex-pixel pictures stay the Companion's to draw.%s" % [cs.size(), "" if cs.size() == 1 else "s", "art" if view == "art" else "token (the board draws Units at 48 pixels)",
			(" Page %d of %d." % [page + 1, pages]) if pages > 1 else ""]
		if page > 0:
			list.add_row(UI.label("Earlier cards", 18, UI.CYAN))
			_shown.append({"page": -1})
		for c in cs.slice(page * PAGE, (page + 1) * PAGE):
			var wr := wearing(c, view)
			var mark: String = {"yours": "Yours", "removed": "None", "none": "", "export": "Hex" if wr.get("hex", false) else ""}[wr["source"]]
			list.add_row(_row_of(wr.get("texture"), str(c.get("name", "")), "%s%s" % [UI.type_name(c), {"none": " · no picture yet", "removed": " · its picture taken away", "yours": " · drawn here", "export": ""}[wr["source"]]], mark))
			_shown.append({"card": c, "what": view})
		if page < pages - 1:
			list.add_row(UI.label("More cards", 18, UI.CYAN))
			_shown.append({"page": 1})
	list.settle()
	list.scroll_by(keep)


func _row_of(tex: Texture2D, name: String, line: String, mark: String) -> Control:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 76)
	row.add_theme_stylebox_override("panel", UI.box(UI.PANEL, UI.LINE, 1, 6, 8))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	row.add_child(hb)
	var pic := TextureRect.new()
	pic.custom_minimum_size = Vector2(96, 60)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.texture = tex
	hb.add_child(pic)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(v)
	v.add_child(UI.label(name, 19, UI.TEXT))
	v.add_child(UI.label(line, 15, UI.DIM))
	if mark != "":
		hb.add_child(UI.tag(mark, UI.GOLD))
	return row


func _on_list_row(i: int, at: Vector2) -> void:
	if dialog != null or i < 0 or i >= _shown.size() or _shown[i] == null:
		return
	var s: Dictionary = _shown[i]
	if s.has("sizes"):
		var what = UI.act_at(list.rows()[i], at)
		if what is Array and what[0] == "new":
			new_canvas(int(what[1]), int(what[2]))
		return
	if s.has("page"):
		page += int(s["page"])
		list.scroll = 0.0
		_fill_list()
		return
	if s.has("id"):
		edit_picture(str(s["id"]))
	else:
		edit_card(s["card"], str(s["what"]))


# ---------------------------------------------------------------- one picture
## Draws a card's art or token: yours if you have drawn it, else the export's, else a blank one.
func edit_card(card: Dictionary, what: String) -> void:
	var k := Sandbox.key_of(card)
	var wr := wearing(card, what)
	if wr["source"] == "export" and wr.get("hex", false):
		say("%s's %s is drawn in hex pixels: draw it in the Companion's Pixel Studio." % [str(card.get("name", "")), what], true)
		return
	var t := {"kind": "card", "key": k, "what": what, "card": card}
	if wr["source"] == "yours":
		var p := Sandbox.picture(str(wr["id"]))
		_open(t, str(wr["id"]), int(p["w"]), int(p["h"]), PixelModel.pixels(p), PixelModel.customs(p), str(p.get("name", "")))
		return
	if wr["source"] == "export" and wr["texture"] != null:
		var got := PixelModel.from_image(wr["texture"].get_image())
		_open(t, "", got["w"], got["h"], got["px"], got["custom"], "%s %s" % [str(card.get("name", "")), what])
		say("The export's picture: save it to keep your changes.")
		return
	var sz: Vector2i = Vector2i(128, 90) if what == "art" else Vector2i(48, 48)
	var px0 := PackedByteArray()
	px0.resize(sz.x * sz.y)
	_open(t, "", sz.x, sz.y, px0, {}, "%s %s" % [str(card.get("name", "")), what])
	dirty = true
	say("A new %s, %d by %d: draw it, and save it to keep it." % ["art" if what == "art" else "token", sz.x, sz.y])


func edit_picture(id: String) -> void:
	var p := Sandbox.picture(id)
	if p.is_empty():
		return
	var wr := Sandbox.wearer(id)
	var t := {"kind": "canvas"}
	if not wr.is_empty():
		var cs: Array = roster.cards.filter(func(c): return Sandbox.key_of(c) == wr[0]) if roster != null else []
		t = {"kind": "card", "key": wr[0], "what": wr[1], "card": cs[0] if not cs.is_empty() else {"name": wr[0].get_slice("|", 1)}}
	_open(t, id, int(p["w"]), int(p["h"]), PixelModel.pixels(p), PixelModel.customs(p), str(p.get("name", "")))


func new_canvas(cw: int, ch: int) -> void:
	var px0 := PackedByteArray()
	px0.resize(cw * ch)
	_open({"kind": "canvas"}, "", cw, ch, px0, {}, "Canvas %d by %d" % [cw, ch])
	dirty = true
	say("A blank canvas, %d by %d: save it to keep it." % [cw, ch])


## Blank canvas: Your pictures, with the sizes to start one at its head.
func ask_new() -> void:
	view = "mine"
	show_list()
	say("Pick a size for the blank canvas, at the top of the list.")


func _open(t: Dictionary, id: String, pw: int, ph: int, pixels: PackedByteArray, cust: Dictionary, nm: String) -> void:
	mode = "edit"
	target = t
	pid = id
	pic_name = nm
	w = pw
	h = ph
	px = pixels
	custom = cust
	dirty = false
	undo = []
	redo = []
	tool_row.visible = false
	search.visible = false
	back_btn.text = "Back"
	list.visible = false
	canvas.visible = true
	form.visible = true
	export_btn.visible = false
	new_btn.visible = false
	for b in [save_btn, undo_btn, redo_btn, fit_btn]:
		b.visible = true
	for x in sub.get_children():
		x.queue_free()
	_buttons()
	say("")
	canvas.show_pixels(w, h, px, custom, true)
	refresh()


func _buttons() -> void:
	var on_card: bool = target.get("kind") == "card"
	var has_export := on_card and not export_file(target["card"], target["what"]).is_empty()
	reset_btn.visible = on_card and Sandbox.link_of(target["key"], target["what"]) != null
	reset_btn.text = "Reset"
	delete_btn.visible = pid != "" or (on_card and (has_export or Sandbox.link_of(target["key"], target["what"]) != null) and Sandbox.link_of(target["key"], target["what"]) != "")


func refresh() -> void:
	var keep := form.scroll
	var what := ""
	if target.get("kind") == "card":
		what = "%s · %s" % [str(target["card"].get("name", "")), "Art" if target["what"] == "art" else "Token"]
	else:
		what = pic_name if pic_name != "" else "Canvas"
	title.text = "Studio · " + what + (" *" if dirty else "")
	hint.text = "%d by %d pixels. %s Two fingers pinch and pan." % [w, h, _tool_hint()]
	undo_btn.disabled = undo.is_empty()
	redo_btn.disabled = redo.is_empty()
	canvas.mirror = mirror
	canvas.queue_redraw()
	form.clear()
	_rows = []
	_row("Tool", TOOLS.map(func(t): return [t[1], ["tool", t[0]], UI.CYAN, tool == t[0]]))
	if tool == "rect" or tool == "ellipse":
		_row("Shape", [["Outline", ["filled", false], UI.CYAN, not filled], ["Filled", ["filled", true], UI.CYAN, filled]])
	var bs: Array = BRUSHES.map(func(b): return [str(b), ["size", b], UI.CYAN, brush_size == b])
	bs.append(["Round" if round_tip else "Square", ["tip"], UI.PALE, false])
	_row("Brush", bs)
	_row("Mirror", MIRRORS.map(func(m): return [m[1], ["mirror", m[0]], UI.CYAN, mirror == m[0]]))
	_colour_row()
	_palette_rows()
	_row("Picture", [["Name: " + (pic_name if pic_name != "" else "(none)"), ["name"], UI.TEXT, false], ["Clear it", ["clear"], UI.SOFT_RED, false]])
	form.settle()
	form.scroll_by(keep)


func _tool_hint() -> String:
	match tool:
		"pencil":
			return "Drag to draw."
		"eraser":
			return "Drag to erase to transparent."
		"fill":
			return "Tap an area of one colour to fill it."
		"pick":
			return "Tap a pixel to take its colour."
		"line":
			return "Drag from one end to the other."
		"rect", "ellipse":
			return "Drag across the area."
	return ""


func _colour_row() -> void:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", UI.box(UI.PANEL, UI.LINE, 1, 6, 8))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	row.add_child(hb)
	hb.add_child(UI.label("Colour", 15, UI.PALE))
	var sw := ColorRect.new()
	sw.custom_minimum_size = Vector2(56, 40)
	sw.color = PixelModel.colour(colour, custom) if colour > 0 else Color(0, 0, 0, 0)
	hb.add_child(sw)
	hb.add_child(UI.label(("#" + PixelModel.colour(colour, custom).to_html(false)) if colour > 0 else "transparent", 15, UI.TEXT))
	var tr := UI.chip("Transparent", UI.PALE, ["col", 0], colour == 0, 15)
	hb.add_child(tr)
	_rows.append({"text": "Colour", "acts": [["col", 0]]})
	form.add_row(row)


## The palette, as swatches a thumb can tap: the picture's own colours, then the KETER palette, by rows.
func _palette_rows() -> void:
	var idx: Array = []
	var cks: Array = custom.keys()
	cks.sort()
	idx.append_array(cks)
	for i in range(1, PixelModel.CUSTOM_FROM):
		idx.append(i)
	var per := 13
	var r := 0
	while r * per < idx.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		var acts := []
		for i in idx.slice(r * per, (r + 1) * per):
			var s := ColorRect.new()
			s.custom_minimum_size = Vector2(32, 30)
			s.color = PixelModel.colour(int(i), custom)
			s.set_meta("act", ["col", int(i)])
			if int(i) == colour:
				var ring := ReferenceRect.new()
				ring.border_color = Color.WHITE
				ring.border_width = 2.0
				ring.editor_only = false
				ring.set_anchors_preset(Control.PRESET_FULL_RECT)
				s.add_child(ring)
			row.add_child(s)
			acts.append(["col", int(i)])
		_rows.append({"text": "", "acts": acts})
		form.add_row(row)
		r += 1


func _row(text: String, chips: Array) -> void:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", UI.box(UI.PANEL, UI.LINE, 1, 6, 8))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	row.add_child(vb)
	if text != "":
		vb.add_child(UI.label(text, 15, UI.PALE, true))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	for c in chips:
		flow.add_child(UI.chip(str(c[0]), c[2], c[1], c[3], 15))
	vb.add_child(flow)
	_rows.append({"text": text, "acts": chips.filter(func(c): return c[1] != null).map(func(c): return c[1])})
	form.add_row(row)


func _on_form_row(i: int, at: Vector2) -> void:
	if dialog != null or i < 0 or i >= form.rows().size():
		return
	var what = UI.act_at(form.rows()[i], at)
	if what != null:
		act(what)


func offers() -> Array:
	var out := []
	for r in _rows:
		out.append_array(r.get("acts", []))
	return out


func act(what: Array) -> void:
	match what[0]:
		"tool":
			tool = what[1]
		"filled":
			filled = what[1]
		"size":
			brush_size = int(what[1])
		"tip":
			round_tip = not round_tip
		"mirror":
			mirror = what[1]
		"col":
			colour = int(what[1])
			if tool == "eraser" or tool == "pick":
				tool = "pencil"
		"name":
			_ask_text("The picture's name", pic_name, func(v):
				pic_name = v.strip_edges()
				dirty = true
				refresh())
			return
		"clear":
			_ask("Clear the picture?", "Every pixel goes transparent. Undo brings them back.", ["Keep it", "Clear"], func(k):
				if k == 1:
					_push()
					px = PackedByteArray()
					px.resize(w * h)
					_changed())
			return
	refresh()


# ---------------------------------------------------------------- drawing
func _on_stroke(phase: String, at: Vector2) -> void:
	if dialog != null or mode != "edit":
		return
	var p := canvas.px_at(at)
	match phase:
		"begin":
			_stroke = {"start": p, "last": p, "snap": px.duplicate(), "did": false}
			match tool:
				"pick":
					if _inside(p):
						colour = px[p.y * w + p.x]
						say("Picked %s." % (("#" + PixelModel.colour(colour, custom).to_html(false)) if colour > 0 else "transparent"))
						tool = "pencil" if colour > 0 else "eraser"
						refresh()
					_stroke = {}
					return
				"fill":
					var v := colour
					var n := 0
					for m in PixelModel.mirrored(p, w, h, mirror):
						n += PixelModel.fill(px, w, h, m.x, m.y, v)
					_stroke["did"] = n > 0
				"pencil", "eraser":
					_dab(p)
				_:
					_preview(p)
		"move":
			if _stroke.is_empty():
				return
			match tool:
				"pencil", "eraser":
					if p != _stroke["last"]:
						for q in PixelModel.line(_stroke["last"], p):
							_dab(q)
						_stroke["last"] = p
				"line", "rect", "ellipse":
					_preview(p)
		"end":
			if _stroke.is_empty():
				return
			if tool in ["line", "rect", "ellipse"]:
				_preview(p)
				for q in canvas.preview:
					_put_px(q, colour)
				canvas.preview = []
			if _stroke.get("did", false):
				undo.append(_stroke["snap"])
				if undo.size() > UNDO_MAX:
					undo.pop_front()
				redo = []
				_stroke = {}
				_changed()
			else:
				_stroke = {}
				canvas.queue_redraw()
			return
		"cancel":
			if _stroke.is_empty():
				return
			if _stroke.get("did", false):
				px = _stroke["snap"]
			_stroke = {}
			canvas.preview = []
			canvas.show_pixels(w, h, px, custom)
			return
	canvas.show_pixels(w, h, px, custom)


## A tap on a pixel, and a finger drawn over some (for the tests).
func tap_px(p: Vector2i) -> void:
	_on_stroke("begin", canvas.at(p))
	_on_stroke("end", canvas.at(p))


func drag_px(path: Array) -> void:
	_on_stroke("begin", canvas.at(path[0]))
	for i in range(1, path.size()):
		_on_stroke("move", canvas.at(path[i]))
	_on_stroke("end", canvas.at(path[path.size() - 1]))


func _inside(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < w and p.y < h


func _dab(p: Vector2i) -> void:
	var v := 0 if tool == "eraser" else colour
	for b in PixelModel.brush(p.x, p.y, brush_size, round_tip):
		_put_px(b, v)


## Sets a pixel and its mirror images.
func _put_px(p: Vector2i, v: int) -> void:
	for m in PixelModel.mirrored(p, w, h, mirror):
		if _inside(m) and px[m.y * w + m.x] != v:
			px[m.y * w + m.x] = v
			_stroke["did"] = true


func _preview(p: Vector2i) -> void:
	var a: Vector2i = _stroke["start"]
	var cs: Array
	match tool:
		"line":
			cs = PixelModel.line(a, p)
		"rect":
			cs = PixelModel.rect(a, p, filled)
		_:
			cs = PixelModel.ellipse(a, p, filled)
	var out := {}
	for c in cs:
		if brush_size > 1 and not filled:
			for b in PixelModel.brush(c.x, c.y, brush_size, round_tip):
				out[b] = true
		else:
			out[c] = true
	var all := {}
	for c in out:
		for m in PixelModel.mirrored(c, w, h, mirror):
			if _inside(m):
				all[m] = true
	canvas.preview = all.keys()
	canvas.queue_redraw()


func _push() -> void:
	undo.append(px.duplicate())
	if undo.size() > UNDO_MAX:
		undo.pop_front()
	redo = []


func do_undo() -> void:
	if undo.is_empty() or dialog != null:
		return
	redo.append(px)
	px = undo.pop_back()
	_changed()


func do_redo() -> void:
	if redo.is_empty() or dialog != null:
		return
	undo.append(px)
	px = redo.pop_back()
	_changed()


func _changed() -> void:
	dirty = true
	canvas.show_pixels(w, h, px, custom)
	refresh()


# ---------------------------------------------------------------- keeping it
func save_picture() -> void:
	var was_new := pid == ""
	pid = Sandbox.put_picture(PixelModel.make(w, h, px, custom, pic_name), pid)
	if target.get("kind") == "card":
		Sandbox.link(target["key"], target["what"], pid)
	dirty = false
	_commit(("%s saved: the card wears it." % pic_name) if target.get("kind") == "card" else ("%s %s." % [pic_name if pic_name != "" else "The canvas", "kept among your pictures" if was_new else "saved"]))
	_buttons()
	refresh()


## Reset: the card wears the export's picture again, and yours is gone.
func ask_reset() -> void:
	if target.get("kind") != "card":
		return
	var has_export := not export_file(target["card"], target["what"]).is_empty()
	_ask("Reset it?", ("It wears the export's picture again" if has_export else "It wears no picture of yours") + ", and what you drew for it is gone.", ["Keep mine", "Reset"], func(k):
		if k == 1:
			var mine := pid
			Sandbox.unlink(target["key"], target["what"])
			if mine != "":
				Sandbox.delete_picture(mine)
			pid = ""
			_commit("Back as the export has it.")
			edit_card(target["card"], target["what"]))


## Delete: one of yours is gone (a card that wore it wears nothing); the
## export's is taken off the card until Reset.
func ask_delete() -> void:
	var on_card: bool = target.get("kind") == "card"
	_ask("Delete the picture?", ("The card wears no %s until Reset brings the export's back." % ("art" if target.get("what") == "art" else "token")) if on_card else "It is gone for good.", ["Keep it", "Delete"], func(k):
		if k == 1:
			if pid != "":
				Sandbox.delete_picture(pid)
			if on_card:
				Sandbox.link(target["key"], target["what"], "")
			_commit("Deleted.")
			show_list())


func export_all() -> void:
	var f := Sandbox.export_game(roster)
	if f == "":
		say("It couldn't be written.", true)
	else:
		say("Written to %s. In the Companion, import it in the Card Forge: your pictures join the Pixel Studio's library." % f)


func _commit(msg: String) -> void:
	if Sandbox.save():
		say(msg)
	else:
		say(Sandbox.error, true)
	changed.emit()


# ---------------------------------------------------------------- boxes
func _ask(t: String, text: String, buttons: Array, then: Callable) -> void:
	_close_dialog()
	var dg := Dialog.new(t, text, buttons, UI.CYAN)
	dialog = dg
	add_child(dg)
	dg.chosen.connect(func(k):
		_close_dialog()
		then.call(k))


func _ask_text(t: String, start: String, then: Callable) -> void:
	_close_dialog()
	var nd := NameDialog.new(t, start)
	dialog = nd
	add_child(nd)
	nd.named.connect(func(v):
		_close_dialog()
		then.call(v))
	nd.cancelled.connect(func(): _close_dialog())


func _close_dialog() -> void:
	if dialog != null:
		Motion.pop_out(dialog, dialog.get_meta("box", null))
		dialog = null
