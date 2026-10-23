## The Sandbox's POI Sandbox (0.29), the Companion's floor editor made over
## for a thumb. Every floor the game has (the export's, as you have changed
## them, and your own), grouped as floors to fight on, battlefield chunks and
## World Map levels; and for one, its map, drawn with a finger.
##
## The tools: Place a tile, Paint one a colour, a Wall on an edge, a Symbol on
## a tile, Erase, the Spawn level of an Enemy Spawn tile, and the Ruler; each
## (but the wall, the level and the ruler) Free, in a Line or a Hex, and
## mirrored through a pivot if you like. Two fingers pinch and pan; Move pans
## with one. The Floor tab files it (name, District, POI type, Skull Level,
## size, notes, what each colour and wall means, a chunk's role and sides);
## Symbols holds its symbols, hazards among them; Checks says what it lacks.
##
## Save keeps it in the Sandbox (sandbox.gd), over the export: the floor list,
## the World Map and the chunks have it at once. Delete, Reset and Copy work as
## in the Card Forge, and Export writes it for the Companion with the cards.
class_name PoiScreen
extends Control

signal closed
signal changed                 # the Sandbox's floors have changed: the game reads them again
signal tool_requested(k: String)

const SHOWS := [["all", "All"], ["changed", "Changed"], ["mine", "Yours"], ["deleted", "Deleted"]]
const TABS := [["draw", "Draw"], ["floor", "Floor"], ["symbols", "Symbols"], ["checks", "Checks"]]
const TOOLS := [["place", "Place"], ["paint", "Paint"], ["wall", "Wall"], ["symbol", "Symbol"], ["erase", "Erase"],
	["level", "Spawn level"], ["ruler", "Ruler"], ["move", "Move"]]
const SHAPES := [["free", "Free"], ["line", "Line"], ["hex", "Hex"]]
const UNDO_MAX := 60

var roster: Roster = null
var mode := "list"
var view := "all"
var tab := "draw"
var st := {}                   # the floor being edited (PoiModel's)
var key := ""                  # its key ("" while it is new)
var dirty := false
var tool := "place"
var shape := "free"
var filled := true
var colour := 0
var edge := -1
var armed := -1                # the symbol a Symbol stroke stamps
var mirror = null              # {pivot, axis} or null
var picking_pivot := false
var undo: Array = []
var redo: Array = []
var dialog: Control = null

var title: Label
var tools := {}
var tool_row: HBoxContainer
var sub: HFlowContainer
var hint: Label
var body: HBoxContainer
var list: TouchList
var canvas: FloorCanvas
var form: TouchList
var note: Label
var back_btn: Button
var export_btn: Button
var new_btn: Button
var undo_btn: Button
var redo_btn: Button
var fit_btn: Button
var save_btn: Button
var copy_btn: Button
var delete_btn: Button
var reset_btn: Button
var _shown: Array = []         # the list's rows: a floor each (or a group's head: null)
var _rows: Array = []          # the form's rows: {text, acts}
var _stroke := {}              # the stroke under way: {start, last, on, snap, did}


func _init() -> void:
	var col := UI.page(self, "menu", 0.78)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	col.add_child(head)
	title = UI.label("Sandbox · POI Sandbox", 30, UI.CYAN)
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
		b.button_pressed = k == "poi"
		tool_row.add_child(b)
		tools[k] = b
	sub = HFlowContainer.new()
	sub.add_theme_constant_override("h_separation", 6)
	col.add_child(sub)
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
	canvas = FloorCanvas.new()
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.stroke.connect(_on_stroke)
	body.add_child(canvas)
	form = TouchList.new()
	form.custom_minimum_size = Vector2(500, 0)
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
	new_btn = UI.button("New floor", func(): edit({}, true), 180)
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
	copy_btn = UI.button("Copy", copy_floor, 100)
	foot.add_child(copy_btn)
	save_btn = UI.button("Save", save_floor, 130)
	save_btn.theme_type_variation = "MainButton"
	foot.add_child(save_btn)


func open(r: Roster) -> void:
	roster = r
	_close_dialog()
	show_list()


func _tool(k: String) -> void:
	for t in tools:
		tools[t].set_pressed_no_signal(t == "poi")
	if k != "poi" and dialog == null:
		tool_requested.emit(k)


func say(t: String, bad := false) -> void:
	note.text = t
	note.add_theme_color_override("font_color", UI.SOFT_RED if bad else UI.GOLD)


func _back() -> void:
	if dialog != null:
		return
	if mode == "edit":
		if dirty:
			_ask("Leave without saving?", "Your changes to %s aren't kept." % str(st.get("name", "this floor")), ["Keep editing", "Leave"], func(k):
				if k == 1:
					show_list())
			return
		show_list()
	else:
		closed.emit()


# ---------------------------------------------------------------- the floors
## Every floor as it now stands (a battlefield grown from chunks is not one to edit).
func all_floors() -> Array:
	var fs = roster.data.content("floors").get("floors", []) if roster != null else []
	return (fs as Array).filter(func(f): return f is Dictionary) if fs is Array else []


func deleted() -> Array:
	var gone: Array = Sandbox.deleted_floors()
	var raw = roster.data._raw_content("floors").get("floors", []) if roster != null else []
	return (raw as Array).filter(func(f): return f is Dictionary and gone.has(Sandbox.floor_key(f))) if raw is Array else []


func listed() -> Array:
	var src: Array = deleted() if view == "deleted" else all_floors()
	return src.filter(func(f):
		var k := Sandbox.floor_key(f)
		if view == "changed":
			return Sandbox.floor_changed(k) and not Sandbox.floor_own(k)
		if view == "mine":
			return Sandbox.floor_own(k)
		return true)


static func group_of(f: Dictionary) -> String:
	if str(f.get("poiType", "")) == "World Map":
		return "world"
	if ChunkGen.is_chunk(f):
		return "chunk"
	return "floor"


## The names every other floor goes by.
func other_names() -> Array:
	return all_floors().filter(func(f): return Sandbox.floor_key(f) != key or key == "").map(func(f): return str(f.get("name", "")))


func show_list() -> void:
	mode = "list"
	st = {}
	key = ""
	dirty = false
	undo = []
	redo = []
	mirror = null
	picking_pivot = false
	title.text = "Sandbox · POI Sandbox"
	tool_row.visible = true
	back_btn.text = "Home"
	list.visible = true
	canvas.visible = false
	form.visible = false
	for b in [save_btn, copy_btn, delete_btn, reset_btn, undo_btn, redo_btn, fit_btn]:
		b.visible = false
	export_btn.visible = true
	new_btn.visible = true
	for c in sub.get_children():
		c.queue_free()
	for s in SHOWS:
		var ss: String = s[0]
		var b := UI.button(s[1], func():
			view = ss
			show_list(), 0)
		b.toggle_mode = true
		b.button_pressed = view == ss
		sub.add_child(b)
	_fill_list()


func _fill_list() -> void:
	var keep := list.scroll
	list.clear()
	_shown = []
	var all := listed()
	var n_made := all_floors().filter(func(f): return Sandbox.floor_own(Sandbox.floor_key(f))).size()
	hint.text = "%d floor%s%s. Tap one to draw on it. You have made %d; a floor you make is in the floor list, and on the World Map, at once." % [
		all.size(), "" if all.size() == 1 else "s", "" if view == "all" else (" " + view), n_made]
	for g in [["floor", "Floors to fight on"], ["chunk", "Battlefield chunks"], ["world", "World Map levels"]]:
		var in_g := all.filter(func(f): return group_of(f) == g[0])
		if in_g.is_empty():
			continue
		list.add_row(UI.label(str(g[1]), 21, UI.CYAN))
		_shown.append(null)
		for f in in_g:
			list.add_row(_floor_row(f))
			_shown.append(f)
	if all.is_empty():
		list.add_row(UI.label("No floors like that." if view != "deleted" else "No floors deleted.", 16, UI.DIM, true))
		_shown.append(null)
	list.settle()
	list.scroll_by(keep)


func _floor_row(f: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 96)
	row.add_theme_stylebox_override("panel", UI.box(UI.PANEL, UI.LINE, 1, 6, 8))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	row.add_child(hb)
	var pic := FloorCanvas.new()
	pic.still = true
	pic.custom_minimum_size = Vector2(120, 80)
	pic.show_floor(PoiModel.from_level(f))
	hb.add_child(pic)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(v)
	v.add_child(UI.label(str(f.get("name", "")), 19, UI.TEXT))
	var bits := []
	var hx: Array = f["hexes"] if f.get("hexes") is Array else []
	bits.append("%d tiles" % hx.size())
	for k in ["district", "poiType"]:
		if str(f.get(k, "") if f.get(k) != null else "") != "":
			bits.append(str(f[k]))
	if str(f.get("level", "") if f.get("level") != null else "") != "":
		bits.append("Skull " + str(f["level"]))
	var sz = f.get("battlefieldSize") if Rules.truthy(f.get("battlefieldSize")) else f.get("floorSize")
	if Rules.truthy(sz):
		bits.append(str(sz))
	if f.get("chunk") is Dictionary:
		bits.append(str(f["chunk"].get("role", "")).capitalize() + " chunk")
	v.add_child(UI.label(" · ".join(bits), 15, UI.DIM, true))
	var k := Sandbox.floor_key(f)
	var mk := "Deleted" if view == "deleted" else ("Yours" if Sandbox.floor_own(k) else ("Changed" if Sandbox.floor_changed(k) else ""))
	if mk != "":
		hb.add_child(UI.tag(mk, UI.GOLD))
	return row


func _on_list_row(i: int, _at: Vector2) -> void:
	if dialog != null or i < 0 or i >= _shown.size() or _shown[i] == null:
		return
	var f: Dictionary = _shown[i]
	if view == "deleted":
		_ask("Restore %s?" % str(f.get("name", "")), "It comes back as the export has it.", ["Cancel", "Restore"], func(k):
			if k == 1:
				Sandbox.reset_floor(Sandbox.floor_key(f))
				_commit("%s is back." % str(f.get("name", "")))
				_fill_list())
		return
	edit(f)


# ---------------------------------------------------------------- one floor
func edit(f: Dictionary, as_new := false) -> void:
	mode = "edit"
	st = PoiModel.blank() if f.is_empty() else PoiModel.from_level(f)
	key = "" if as_new else Sandbox.floor_key(f)
	dirty = as_new
	undo = []
	redo = []
	mirror = null
	picking_pivot = false
	armed = -1 if st["symDefs"].is_empty() else int(st["symDefs"][0]["id"])
	tool_row.visible = false
	back_btn.text = "Back"
	list.visible = false
	canvas.visible = true
	form.visible = true
	export_btn.visible = false
	new_btn.visible = false
	for b in [save_btn, undo_btn, redo_btn, fit_btn]:
		b.visible = true
	copy_btn.visible = key != ""
	delete_btn.visible = key != ""
	reset_btn.visible = key != "" and not Sandbox.floor_own(key) and Sandbox.floor_changed(key)
	canvas.mirror = null
	canvas.show_floor(st)
	_tabs()
	say("A new floor: draw it, file it, and save it to keep it." if as_new else "")
	refresh()


func _tabs() -> void:
	for x in sub.get_children():
		x.queue_free()
	for t in TABS:
		var tt: String = t[0]
		var b := UI.button(t[1], func():
			tab = tt
			_tabs()
			refresh(), 0)
		b.toggle_mode = true
		b.button_pressed = tab == tt
		sub.add_child(b)


func refresh() -> void:
	var keep := form.scroll
	title.text = "POI · " + (str(st.get("name", "")) if str(st.get("name", "")) != "" else "Untitled") + (" *" if dirty else "")
	var probs := PoiModel.blocking(st, other_names())
	hint.text = ("Can't be saved yet: " + " ".join(probs)) if not probs.is_empty() else (PoiModel.readout(st) + ". " + _tool_hint())
	hint.add_theme_color_override("font_color", UI.SOFT_RED if not probs.is_empty() else UI.PALE)
	save_btn.disabled = not probs.is_empty()
	undo_btn.disabled = undo.is_empty()
	redo_btn.disabled = redo.is_empty()
	canvas.pan_only = tool == "move"
	canvas.mirror = mirror
	canvas.queue_redraw()
	form.clear()
	_rows = []
	match tab:
		"floor":
			_floor_form()
		"symbols":
			_symbols_form()
		"checks":
			_checks_form()
		_:
			_draw_form()
	form.settle()
	form.scroll_by(keep)


func _tool_hint() -> String:
	if picking_pivot:
		return "Tap the tile the mirror line runs through."
	match tool:
		"place":
			return "Drag to place tiles."
		"paint":
			return "Drag to paint tiles %s." % (_colour_name(colour) if colour >= 0 else "plain")
		"wall":
			return "Drag along the edges between tiles for a %s wall; over one already that colour, it comes off." % _edge_name(edge)
		"symbol":
			return "Tap tiles to stamp %s; tap one stamped to clear it." % (PoiModel.sym_text(PoiModel.sym(st, armed)) if armed >= 0 else "a symbol (add one in Symbols)")
		"erase":
			return "Drag to erase tiles, with their symbols and walls."
		"level":
			return "Tap an Enemy Spawn tile to raise its Skull Level; 6 goes back to 1."
		"ruler":
			return "Drag between two tiles to measure."
		"move":
			return "Drag to move the map; pinch to zoom."
	return ""


func _colour_name(c: int) -> String:
	var l := str(st["colorLabels"].get(c, ""))
	return PoiModel.NAMES[c] + ((" (" + l + ")") if l != "" else "")


func _edge_name(c: int) -> String:
	var l := str(st["wallLabels"].get(c, ""))
	return ("black" if c < 0 else PoiModel.NAMES[c].to_lower()) + ((" (" + l + ")") if l != "" else "")


# ---------------------------------------------------------------- the forms
func _draw_form() -> void:
	_row("Tool", TOOLS.map(func(t): return [t[1], ["tool", t[0]], UI.CYAN, tool == t[0]]))
	if tool in ["place", "paint", "symbol", "erase"]:
		var sh: Array = SHAPES.map(func(s): return [s[1], ["shape", s[0]], UI.CYAN, shape == s[0]])
		if shape == "hex":
			sh.append(["Filled" if filled else "Outline", ["filled"], UI.PALE, false])
		_row("Shape", sh)
	if tool == "paint":
		var cs := []
		for i in 6:
			cs.append([_colour_name(i), ["colour", i], FloorData.RAINBOW[i], colour == i])
		cs.append(["Plain", ["colour", -1], UI.PALE, colour == -1])
		_row("Colour", cs)
	if tool == "wall":
		_row("Wall", PoiModel.EDGES.map(func(c): return [_edge_name(c).capitalize(), ["edge", c], UI.PALE if c < 0 else FloorData.RAINBOW[c], edge == c]))
	if tool == "symbol":
		if st["symDefs"].is_empty():
			_row("Symbol", [["Add one in Symbols", ["tab", "symbols"], UI.CYAN, false]])
		else:
			_row("Symbol", (st["symDefs"] as Array).map(func(d): return [PoiModel.sym_text(d), ["arm", int(d["id"])], UI.SOFT_RED if PoiModel.is_hazard(d) else UI.CYAN, armed == int(d["id"])]))
	var mr := [["Off", ["mirror_off"], UI.PALE, mirror == null and not picking_pivot], ["Set pivot", ["mirror_pivot"], UI.CYAN, picking_pivot]]
	if mirror != null:
		mr.append(["Turn the line", ["mirror_axis"], UI.CYAN, false])
	_row("Mirror", mr)
	_head("The map")
	_row("Radius (rings out)", _stepper("radius", int(st["radius"]), 5, 20))
	_row("", [["Fill the hexagon", ["fill_all"], UI.CYAN, false], ["Clear the map", ["clear_map"], UI.SOFT_RED, false]])
	_head("What the colours mean")
	for i in 6:
		_row(PoiModel.NAMES[i], [[str(st["colorLabels"].get(i, "")) if str(st["colorLabels"].get(i, "")) != "" else "(no meaning)", ["clabel", i], FloorData.RAINBOW[i], false]])


func _floor_form() -> void:
	_row("Name", [[str(st.get("name", "")) if str(st.get("name", "")) != "" else "(none)", ["name"], UI.TEXT, false]])
	_row("District", PoiModel.DISTRICTS.map(func(d): return [d if d != "" else "None", ["district", d], UI.CYAN, str(st.get("district", "")) == d]))
	_row("POI type", PoiModel.POI_TYPES.map(func(t): return [t if t != "" else "None", ["ptype", t], UI.CYAN, str(st.get("poiType", "")) == t]))
	var lv := [["None", ["skull", ""], UI.CYAN, str(st.get("level", "")) == ""]]
	for n in range(1, 7):
		lv.append([str(n), ["skull", str(n)], UI.CYAN, str(st.get("level", "")) == str(n)])
	_row("Skull Level", lv)
	_row("Floor size (Heroes it admits)", PoiModel.SIZES.map(func(s): return [("Auto: " + (PoiModel.size_of({"floorSize": "", "hexes": st["hexes"]}) if not st["hexes"].is_empty() else "none")) if s == "" else "%s (%d)" % [s, PoiModel.heroes_of(s)], ["fsize", s], UI.CYAN, str(st.get("floorSize", "")) == s]))
	if str(st.get("poiType", "")) == "Chunk":
		_chunk_rows()
	_row("Play notes", [[_short(str(st.get("notes", ""))), ["notes"], UI.TEXT, false]])
	_row("Rewards", [[_short(str(st.get("rewards", ""))), ["rewards"], UI.TEXT, false]])
	_head("What the colours mean")
	for i in 6:
		_row(PoiModel.NAMES[i], [[str(st["colorLabels"].get(i, "")) if str(st["colorLabels"].get(i, "")) != "" else "(no meaning)", ["clabel", i], FloorData.RAINBOW[i], false]])
	_head("What the walls mean")
	for c in PoiModel.EDGES:
		_row(_edge_name(c).get_slice(" ", 0).capitalize(), [[str(st["wallLabels"].get(c, "")) if str(st["wallLabels"].get(c, "")) != "" else "(no meaning)", ["wlabel", c], UI.PALE if c < 0 else FloorData.RAINBOW[c], false]])
	_row("", [["Reset to KETER defaults", ["defaults"], UI.GOLD, false]])


func _chunk_rows() -> void:
	var ck := PoiModel.chunk_norm(st.get("chunk"))
	st["chunk"] = ck
	_head("Chunk")
	_row("Role", PoiModel.CHUNK_ROLES.map(func(r): return [r[1], ["crole", r[0]], UI.CYAN, ck["role"] == r[0]]))
	var sides := []
	for i in 6:
		sides.append([PoiModel.CHUNK_SIDES[i] + (" open" if ck["sides"][i] else " walled"), ["cside", i], UI.GREEN if ck["sides"][i] else UI.SOFT_RED, ck["sides"][i]])
	_row("Sides", sides)
	_row("Skull from", _stepper("skullMin", int(ck["skullMin"]), 1, 6))
	_row("Skull to", _stepper("skullMax", int(ck["skullMax"]), 1, 6))
	_row("", [["Lay out a chunk", ["chunk_lay"], UI.CYAN, false]])


func _symbols_form() -> void:
	_row("%d of %d symbols" % [st["symDefs"].size(), PoiModel.MAX_SYMBOLS], [["+ Add a symbol", ["sym_add"], UI.CYAN, false], ["KETER defaults", ["defaults"], UI.GOLD, false]])
	var statuses: Array = Keywords.KEYWORDS.filter(func(k): return k["cat"] == "status").map(func(k): return str(k["name"]))
	for d in st["symDefs"]:
		var id := int(d["id"])
		var n := 0
		for h in st["marks"]:
			if int(st["marks"][h]) == id:
				n += 1
		_head("%s · on %d tile%s%s" % [PoiModel.sym_text(d), n, "" if n == 1 else "s", (" · hazard: " + PoiModel.hazard_line(d)) if PoiModel.is_hazard(d) else ""])
		_row("Text", [[PoiModel.sym_text(d), ["sym_text", id], UI.TEXT, false], ["Stamp it", ["arm", id], UI.CYAN, armed == id and tool == "symbol"], ["Remove", ["sym_del", id], UI.SOFT_RED, false]])
		_row("Says", [[_short(str(d.get("desc", ""))), ["sym_desc", id], UI.TEXT, false]])
		var hz: Dictionary = d["hazard"] if d.get("hazard") is Dictionary else {}
		_row("Hazard damage", _stepper("dmg:%d" % id, int(Rules.num(hz.get("damage"), 0)) if Rules.truthy(hz.get("damage")) else 0, 0, 20))
		var kw := str(hz.get("keyword", ""))
		var ks := [["None", ["sym_kw", id, ""], UI.PALE, kw == ""]]
		for s in statuses:
			ks.append([s, ["sym_kw", id, s], UI.SOFT_RED, kw == s])
		_row("Hazard status", ks)


func _checks_form() -> void:
	_head(PoiModel.readout(st))
	var ps := PoiModel.pings(st, other_names())
	if ps.is_empty():
		var l := UI.label("Floor ready: nothing is flagged.", 18, UI.GREEN, true)
		_rows.append({"text": l.text, "acts": []})
		form.add_row(l)
	for p in ps:
		var c: Color = UI.SOFT_RED if p[0] == "red" else (UI.GOLD if p[0] == "amber" else UI.DIM)
		var l := UI.label(("Red: " if p[0] == "red" else ("Amber: " if p[0] == "amber" else "")) + str(p[1]), 17, c, true)
		_rows.append({"text": l.text, "acts": []})
		form.add_row(l)


func _short(t: String) -> String:
	t = t.strip_edges().replace("\n", " ")
	if t == "":
		return "(none)"
	return t if t.length() <= 60 else t.substr(0, 57) + "..."


func _stepper(what: String, v: int, lo: int, hi: int) -> Array:
	return [["−", ["step", what, -1, lo, hi], UI.CYAN, false], [str(v), null, UI.TEXT, false], ["+", ["step", what, 1, lo, hi], UI.CYAN, false]]


func _head(text: String) -> void:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", 8)
	m.add_child(UI.label(text, 19, UI.CYAN, true))
	_rows.append({"text": text, "acts": []})
	form.add_row(m)


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


# ---------------------------------------------------------------- what a tap does
func act(what: Array) -> void:
	match what[0]:
		"tab":
			tab = what[1]
			_tabs()
		"tool":
			tool = what[1]
			picking_pivot = false
			if tool == "symbol" and armed < 0 and not st["symDefs"].is_empty():
				armed = int(st["symDefs"][0]["id"])
		"shape":
			shape = what[1]
		"filled":
			filled = not filled
		"colour":
			colour = int(what[1])
		"edge":
			edge = int(what[1])
		"arm":
			armed = int(what[1])
			tool = "symbol"
		"mirror_off":
			mirror = null
			picking_pivot = false
		"mirror_pivot":
			picking_pivot = true
		"mirror_axis":
			if mirror != null:
				mirror["axis"] = (int(mirror["axis"]) + 1) % 3
		"fill_all":
			_push()
			var n := PoiModel.fill_all(st)
			say("%d tiles placed." % n)
			_changed()
			return
		"clear_map":
			_ask("Clear the map?", "Every tile, wall and symbol on it goes. Undo brings them back.", ["Keep it", "Clear"], func(k):
				if k == 1:
					_push()
					st["hexes"] = {}
					st["marks"] = {}
					st["walls"] = {}
					_changed())
			return
		"name":
			_ask_text("Name", str(st.get("name", "")), func(v):
				st["name"] = v.strip_edges()
				_changed())
			return
		"notes", "rewards":
			var k: String = what[0]
			_ask_text("Play notes" if k == "notes" else "Rewards", str(st.get(k, "")), func(v):
				st[k] = v.strip_edges()
				_changed())
			return
		"clabel":
			var c := int(what[1])
			_ask_text("What %s means" % PoiModel.NAMES[c].to_lower(), str(st["colorLabels"].get(c, "")), func(v):
				st["colorLabels"][c] = v.strip_edges()
				_changed())
			return
		"wlabel":
			var c := int(what[1])
			_ask_text("What a %s wall means" % ("black" if c < 0 else PoiModel.NAMES[c].to_lower()), str(st["wallLabels"].get(c, "")), func(v):
				st["wallLabels"][c] = v.strip_edges()
				_changed())
			return
		"defaults":
			_ask("Reset to KETER defaults?", "Every colour, wall and symbol description goes back to the POI rules' wording. Any wording you have changed is replaced.", ["Cancel", "Reset"], func(k):
				if k == 1:
					_push()
					PoiModel.apply_defaults(st, true)
					say("Reset to KETER defaults.")
					_changed())
			return
		"district":
			st["district"] = what[1]
		"ptype":
			st["poiType"] = what[1]
			if what[1] == "Chunk":
				st["chunk"] = PoiModel.chunk_norm(st.get("chunk"))
		"skull":
			st["level"] = what[1]
		"fsize":
			st["floorSize"] = what[1]
		"crole":
			st["chunk"]["role"] = what[1]
		"cside":
			st["chunk"]["sides"][int(what[1])] = not st["chunk"]["sides"][int(what[1])]
		"chunk_lay":
			_ask("Lay out a chunk?", "The 37 tiles of a radius-3 hexagon, and what is on the map now is cleared. Undo brings it back.", ["Cancel", "Lay it out"], func(k):
				if k == 1:
					_push()
					st["hexes"] = {}
					st["marks"] = {}
					st["walls"] = {}
					for h in PoiModel.hex_shape(Vector2i.ZERO, Vector2i(3, 0)):
						st["hexes"][h] = {}
					_changed())
			return
		"step":
			_step(str(what[1]), int(what[2]), int(what[3]), int(what[4]))
			return
		"sym_add":
			if st["symDefs"].size() >= PoiModel.MAX_SYMBOLS:
				say("A floor has at most %d symbols." % PoiModel.MAX_SYMBOLS, true)
				return
			_ask_text("A symbol: up to three characters", "", func(v):
				var id := PoiModel.add_sym(st, v)
				if id < 0:
					say("A symbol needs a character or three.", true)
					return
				armed = id
				tool = "symbol"
				_changed())
			return
		"sym_text":
			var d := PoiModel.sym(st, int(what[1]))
			_ask_text("The symbol's text: up to three characters", PoiModel.sym_text(d), func(v):
				v = v.strip_edges().substr(0, 3)
				if v != "":
					d["text"] = v
				_changed())
			return
		"sym_desc":
			var d := PoiModel.sym(st, int(what[1]))
			_ask_text("What it means", str(d.get("desc", "")), func(v):
				d["desc"] = v.strip_edges()
				_changed())
			return
		"sym_del":
			var id := int(what[1])
			var d := PoiModel.sym(st, id)
			_ask("Remove %s?" % PoiModel.sym_text(d), "Every tile it is stamped on loses it. Undo brings it back.", ["Keep it", "Remove"], func(k):
				if k == 1:
					_push()
					PoiModel.remove_sym(st, id)
					if armed == id:
						armed = -1 if st["symDefs"].is_empty() else int(st["symDefs"][0]["id"])
					_changed())
			return
		"sym_kw":
			var d := PoiModel.sym(st, int(what[1]))
			var hz: Dictionary = d["hazard"] if d.get("hazard") is Dictionary else {}
			PoiModel.set_hazard(d, int(Rules.num(hz.get("damage"), 0)) if Rules.truthy(hz.get("damage")) else 0, str(what[2]))
			_changed()
			return
	refresh()


func _step(what: String, by: int, lo: int, hi: int) -> void:
	if what == "radius":
		var n := clampi(int(st["radius"]) + by, lo, hi)
		var lose := 0
		for h in st["hexes"]:
			if Hex.distance(h, Vector2i.ZERO) > n:
				lose += 1
		var go := func():
			_push()
			PoiModel.set_radius(st, n)
			canvas.fit()
			_changed()
		if lose > 0:
			_ask("Shrink the map?", "%d tile%s outside the new hexagon go, with what is on them. Undo brings them back." % [lose, "" if lose == 1 else "s"], ["Keep it", "Shrink"], func(k):
				if k == 1:
					go.call())
		else:
			go.call()
		return
	if what.begins_with("dmg:"):
		var d := PoiModel.sym(st, int(what.substr(4)))
		var hz: Dictionary = d["hazard"] if d.get("hazard") is Dictionary else {}
		var dm := clampi((int(Rules.num(hz.get("damage"), 0)) if Rules.truthy(hz.get("damage")) else 0) + by, lo, hi)
		PoiModel.set_hazard(d, dm, str(hz.get("keyword", "")))
	elif what == "skullMin" or what == "skullMax":
		st["chunk"][what] = clampi(int(st["chunk"][what]) + by, lo, hi)
		if int(st["chunk"]["skullMin"]) > int(st["chunk"]["skullMax"]):
			st["chunk"]["skullMax" if what == "skullMin" else "skullMin"] = st["chunk"][what]
	_changed()


func _changed() -> void:
	dirty = true
	canvas.queue_redraw()
	refresh()


# ---------------------------------------------------------------- drawing on the map
func _on_stroke(phase: String, at: Vector2) -> void:
	if dialog != null or mode != "edit":
		return
	match phase:
		"begin":
			_stroke_begin(at)
		"move":
			_stroke_move(at)
		"end":
			_stroke_end(at)
		"cancel":
			_stroke_cancel()


## A tap on a tile, as a finger would make it (for the tests, and for the
## Ruler and Spawn level, which act on the tap).
func tap_hex(h: Vector2i) -> void:
	var p := canvas.at(h)
	_on_stroke("begin", p)
	_on_stroke("end", p)


## A finger drawn from one tile to another.
func drag_hexes(path: Array) -> void:
	if path.is_empty():
		return
	_on_stroke("begin", canvas.at(path[0]))
	for i in range(1, path.size()):
		_on_stroke("move", canvas.at(path[i]))
	_on_stroke("end", canvas.at(path[path.size() - 1]))


func _stroke_begin(p: Vector2) -> void:
	var h := canvas.hex_at(p)
	_stroke = {"start": h, "last": h, "snap": PoiModel.snap(st), "did": false}
	if picking_pivot:
		mirror = {"pivot": h, "axis": 0 if mirror == null else int(mirror["axis"])}
		picking_pivot = false
		_stroke = {}
		say("The mirror line runs through %s. Turn the line in Draw." % Hex.key(h))
		refresh()
		return
	match tool:
		"ruler":
			canvas.ruler = [h, h]
		"level":
			var got := -1
			for x in PoiModel.images(h, mirror):
				var r := PoiModel.step_level(st, x)
				if x == h:
					got = r
				if r >= 0:
					_stroke["did"] = true
			if got < 0:
				say("Only an Enemy Spawn tile has a Skull Level." if not PoiModel.is_world_map(st) else "Place a tile there first.", true)
			else:
				say("Skull Level %d." % got if got > 0 else "Its Skull Level is cleared.")
		"wall":
			var e := canvas.edge_at(p)
			var k := PoiModel.wall_key(e[0], e[1])
			_stroke["on"] = int(st["walls"].get(k, -999)) != edge
			_stroke["edge"] = k
			_wall_at(e)
		"move":
			pass
		_:
			if tool == "symbol" and armed < 0:
				say("Add a symbol in Symbols first.", true)
				_stroke = {}
				return
			if tool == "symbol":
				_stroke["on"] = int(st["marks"].get(h, -999)) != armed
			if shape == "free":
				_tile(h)
			else:
				_preview(h)
	canvas.queue_redraw()


func _stroke_move(p: Vector2) -> void:
	if _stroke.is_empty():
		return
	var h := canvas.hex_at(p)
	match tool:
		"ruler":
			canvas.ruler = [_stroke["start"], h]
		"level", "move":
			pass
		"wall":
			var e := canvas.edge_at(p)
			var k := PoiModel.wall_key(e[0], e[1])
			if k != _stroke.get("edge", ""):
				_stroke["edge"] = k
				_wall_at(e)
		_:
			if shape == "free":
				if h != _stroke["last"]:
					for x in PoiModel.line(_stroke["last"], h):
						_tile(x)
					_stroke["last"] = h
			else:
				_preview(h)
	canvas.queue_redraw()


func _stroke_end(p: Vector2) -> void:
	if _stroke.is_empty():
		return
	var h := canvas.hex_at(p)
	if tool == "ruler":
		say("%d tiles from %s to %s." % [Hex.distance(_stroke["start"], h), Hex.key(_stroke["start"]), Hex.key(h)])
		canvas.ruler = []
	elif tool not in ["level", "wall", "move"] and shape != "free":
		_preview(h)
		for x in canvas.preview:
			_tile(x)
		canvas.preview = []
	canvas.preview_edges = []
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
		refresh()


func _stroke_cancel() -> void:
	if _stroke.is_empty():
		return
	if _stroke.get("did", false):
		PoiModel.unsnap(st, _stroke["snap"])
	_stroke = {}
	canvas.preview = []
	canvas.preview_edges = []
	canvas.ruler = []
	canvas.queue_redraw()


## What the tool in hand does to a tile (and its reflection).
func _tile(h: Vector2i) -> void:
	for x in PoiModel.images(h, mirror):
		var did := false
		match tool:
			"place":
				did = PoiModel.place(st, x)
			"paint":
				did = PoiModel.paint(st, x, colour)
			"erase":
				did = PoiModel.erase(st, x)
			"symbol":
				did = PoiModel.mark(st, x, armed, _stroke.get("on", true))
		if did:
			_stroke["did"] = true


func _wall_at(e: Array) -> void:
	var ends := [[e[0], e[1]]]
	if mirror is Dictionary:
		var m := [PoiModel.reflect(e[0], mirror["pivot"], int(mirror["axis"])), PoiModel.reflect(e[1], mirror["pivot"], int(mirror["axis"]))]
		if PoiModel.wall_key(m[0], m[1]) != PoiModel.wall_key(e[0], e[1]):
			ends.append(m)
	for x in ends:
		if PoiModel.wall(st, x[0], x[1], edge, _stroke.get("on", true)):
			_stroke["did"] = true


func _preview(h: Vector2i) -> void:
	var a: Vector2i = _stroke["start"]
	var cs: Array = PoiModel.line(a, h) if shape == "line" else PoiModel.hex_shape(a, h, filled)
	var out := {}
	for c in cs:
		for x in PoiModel.images(c, mirror):
			if PoiModel.in_map(st, x):
				out[x] = true
	canvas.preview = out.keys()


# ---------------------------------------------------------------- undo
func _push() -> void:
	undo.append(PoiModel.snap(st))
	if undo.size() > UNDO_MAX:
		undo.pop_front()
	redo = []


func do_undo() -> void:
	if undo.is_empty() or dialog != null:
		return
	redo.append(PoiModel.snap(st))
	PoiModel.unsnap(st, undo.pop_back())
	_changed()


func do_redo() -> void:
	if redo.is_empty() or dialog != null:
		return
	undo.append(PoiModel.snap(st))
	PoiModel.unsnap(st, redo.pop_back())
	_changed()


# ---------------------------------------------------------------- keeping it
func save_floor() -> void:
	var probs := PoiModel.blocking(st, other_names())
	if not probs.is_empty():
		say(" ".join(probs), true)
		return
	var was_new := key == ""
	key = Sandbox.put_floor(PoiModel.to_level(st), key)
	dirty = false
	_commit("%s %s." % [str(st["name"]), "made: it is in the floor list" if was_new else "saved"])
	copy_btn.visible = true
	delete_btn.visible = true
	reset_btn.visible = not Sandbox.floor_own(key)
	refresh()


func copy_floor() -> void:
	var lv := PoiModel.to_level(st)
	lv["name"] = str(st.get("name", "Floor")) + " copy"
	for k in ["testMap", "shipped", "builtIn", "createdBy"]:
		lv.erase(k)
	edit(lv, true)
	say("A copy: save it to keep it.")


func ask_delete() -> void:
	if key == "":
		return
	var own := Sandbox.floor_own(key)
	_ask("Delete %s?" % str(st.get("name", "")), ("It is gone for good." if own else "It leaves the game: no fight is on it. Deleted, in the list, can bring it back.") + " A World Map POI that runs through it is left without it.",
		["Keep it", "Delete"], func(k):
			if k == 1:
				var nm := str(st.get("name", ""))
				Sandbox.delete_floor(key)
				_commit("%s deleted." % nm)
				show_list())


func ask_reset() -> void:
	if key == "" or Sandbox.floor_own(key):
		return
	_ask("Reset %s?" % str(st.get("name", "")), "It goes back to how the export has it, and your changes to it are gone.", ["Keep mine", "Reset"], func(k):
		if k == 1:
			Sandbox.reset_floor(key)
			_commit("Back as the export has it.")
			var orig := all_floors().filter(func(f): return Sandbox.floor_key(f) == key)
			if not orig.is_empty():
				edit(orig[0])
			else:
				show_list())


func export_all() -> void:
	var f := Sandbox.export_game(roster)
	if f == "":
		say("It couldn't be written.", true)
	else:
		say("Written to %s. In the Companion, import it in the Card Forge: its floors join the Sandbox's levels." % f)


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
