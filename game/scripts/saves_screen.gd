## (0.32) The three save files, from Home: each a whole run (save_slots.gd),
## named, with where it stands. Play switches to one (an empty one starts a new
## run); Rename names it; Copy puts its run over another slot's; Delete wipes
## it. The one being played is marked.
class_name SavesScreen
extends Control

signal closed
signal switched                # the save file played has changed: the game reads its run

var list: TouchList
var hint: Label
var note: Label
var back_btn: Button
var dialog: Control = null
var _rows: Array = []          # the list's rows: the slot each is (or 0)


func _init() -> void:
	var col := UI.page(self, "menu", 0.78)
	col.add_child(UI.label("Save files", 30, UI.CYAN))
	hint = UI.label("Each save file is a whole run: the World Map as explored, the dock and its stockpile, what has been found and recruited, the designs, and the Strike Teams. The Sandbox, the Behavior keywords and the settings are shared by all three.", 16, UI.PALE, true)
	col.add_child(hint)
	list = TouchList.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.row_tapped.connect(_on_row)
	col.add_child(list)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	col.add_child(foot)
	back_btn = UI.button("Home", func():
		if dialog == null:
			closed.emit(), 140)
	foot.add_child(back_btn)
	note = UI.label("", 17, UI.GOLD, true)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	foot.add_child(note)


func open(busy := false) -> void:
	_close_dialog()
	say("A fight is under way: finish it, or leave it, before switching." if busy else "")
	refresh()


func say(t: String, bad := false) -> void:
	note.text = t
	note.add_theme_color_override("font_color", UI.SOFT_RED if bad else UI.GOLD)


func refresh() -> void:
	var keep := list.scroll
	list.clear()
	_rows = []
	for n in range(1, SaveSlots.COUNT + 1):
		list.add_row(_slot_row(n))
		_rows.append(n)
	list.settle()
	list.scroll_by(keep)


func _slot_row(n: int) -> Control:
	var here := n == SaveSlots.current
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", UI.box(UI.PANEL_LIT if here else UI.PANEL, UI.CYAN if here else UI.LINE, 2 if here else 1, 6, 12))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	row.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	v.add_child(head)
	var nm := UI.label(SaveSlots.name_of(n), 24, UI.TEXT)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(nm)
	if here:
		head.add_child(UI.tag("Playing", UI.CYAN))
	v.add_child(UI.label(SaveSlots.line_of(n), 16, UI.DIM, true))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	var used := SaveSlots.used(n)
	if not here:
		flow.add_child(UI.chip("Play" if used else "Start a new run", UI.GOLD, ["play", n], false, 16))
	flow.add_child(UI.chip("Rename", UI.CYAN, ["rename", n], false, 16))
	if used:
		for m in range(1, SaveSlots.COUNT + 1):
			if m != n:
				flow.add_child(UI.chip("Copy to %s" % SaveSlots.name_of(m), UI.CYAN, ["copy", n, m], false, 16))
		flow.add_child(UI.chip("Delete", UI.SOFT_RED, ["delete", n], false, 16))
	v.add_child(flow)
	return row


func _on_row(i: int, at: Vector2) -> void:
	if dialog != null or i < 0 or i >= _rows.size():
		return
	var what = UI.act_at(list.rows()[i], at)
	if what is Array:
		act(what)


func offers() -> Array:
	var out := []
	for r in list.rows():
		var stack: Array = [r]
		while not stack.is_empty():
			var c = stack.pop_front()
			if c is Control and c.has_meta("act"):
				out.append(c.get_meta("act"))
			stack.append_array(c.get_children())
	return out


func act(what: Array) -> void:
	var n := int(what[1])
	match what[0]:
		"play":
			SaveSlots.use(n)
			say("Playing %s." % SaveSlots.name_of(n))
			switched.emit()
			refresh()
		"rename":
			_ask_text("Name %s" % SaveSlots.name_of(n), SaveSlots.name_of(n) if str(SaveSlots.index()["names"].get(str(n), "")) != "" else "", func(v):
				SaveSlots.rename(n, v)
				refresh())
		"copy":
			var m := int(what[2])
			var go := func():
				if SaveSlots.copy(n, m):
					say("%s copied to slot %d." % [SaveSlots.name_of(n), m])
					if m == SaveSlots.current:
						switched.emit()
				else:
					say(SaveSlots.error, true)
				refresh()
			if SaveSlots.used(m):
				_ask("Copy over %s?" % SaveSlots.name_of(m), "Its run and its Strike Teams are replaced by %s's, and can't be brought back." % SaveSlots.name_of(n), ["Cancel", "Copy over it"], func(k):
					if k == 1:
						go.call())
			else:
				go.call()
		"delete":
			_ask("Delete %s?" % SaveSlots.name_of(n), "Its run and its Strike Teams are gone for good." + (" It is the one being played: a new run starts in it." if n == SaveSlots.current else ""), ["Keep it", "Delete"], func(k):
				if k == 1:
					var nm := SaveSlots.name_of(n)
					SaveSlots.delete(n)
					say("%s deleted." % nm)
					if n == SaveSlots.current:
						switched.emit()
					refresh())


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
