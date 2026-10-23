## The Sandbox (0.26), from Home: the game's own tools for making content. Its
## first is the Card Forge, the Companion's Forge made over for a thumb: every
## card the game plays (the export's, as you have changed them, and your own)
## to find by kind or by name; and for one, its kind, rarity, District, Skull
## Level, Aether cost, Combat Roles, Origin, Archetypes, numbers, abilities
## (each its tag, role and numbers, and its effects built with the keyword
## builder, or typed) and lore, with the card drawn as it changes. Save keeps
## it in the Sandbox (sandbox.gd); Delete takes it out of the game; Reset puts
## one of the export's back as it came; Copy makes one of yours from it.
## Export writes everything as a Compendium file for the Companion.
##
## The Chassis builder, the POI Sandbox and the Pixel Studio take their tabs
## in later versions.
class_name ForgeScreen
extends Control

signal closed
signal changed                 # the Sandbox's cards have changed: the game reads them again
signal tool_requested(k: String)   # (0.28) another of the Sandbox's tools

const TOOLS := [["forge", "Card Forge"], ["chassis", "Chassis"], ["poi", "POI Sandbox"], ["studio", "Pixel Studio"]]
const SHOWS := [["all", "All"], ["changed", "Changed"], ["mine", "Yours"], ["deleted", "Deleted"]]

var roster: Roster = null
var mode := "list"             # "list": the cards; "edit": one of them
var type_filter := "all"
var view := "all"          # all, changed, mine (yours) or deleted
var search := ""
var card := {}                 # the card being edited, as it will be kept
var key := ""                  # its key ("" while it is new)
var dirty := false
var dialog: Control = null
var sheet: BuilderSheet = null

var title: Label
var tool_row: HBoxContainer
var tools := {}
var sub: HFlowContainer        # the filters (list) or nothing (edit)
var search_edit: LineEdit
var hint: Label
var body: HBoxContainer
var grid: CardGrid
var preview: CardTile
var preview_box: VBoxContainer
var form: TouchList
var note: Label
var back_btn: Button
var export_btn: Button
var new_btn: Button
var save_btn: Button
var copy_btn: Button
var delete_btn: Button
var reset_btn: Button
var _shown: Array = []         # the cards in the grid, in order
var _rows: Array = []          # the form's rows: {text, acts}


func _init() -> void:
	var col := UI.page(self, "menu", 0.78)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	col.add_child(head)
	title = UI.label("Sandbox", 30, UI.CYAN)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	tool_row = HBoxContainer.new()
	tool_row.add_theme_constant_override("separation", 8)
	head.add_child(tool_row)
	for t in TOOLS:
		var k: String = t[0]
		var b := UI.button(t[1], func(): open_tool(k), 150)
		b.toggle_mode = true
		tool_row.add_child(b)
		tools[k] = b
	sub = HFlowContainer.new()
	sub.add_theme_constant_override("h_separation", 6)
	sub.add_theme_constant_override("v_separation", 6)
	col.add_child(sub)
	hint = UI.label("", 16, UI.PALE, true)
	col.add_child(hint)
	body = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	col.add_child(body)
	grid = CardGrid.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.card_tapped.connect(_on_card)
	body.add_child(grid)
	preview_box = VBoxContainer.new()
	preview_box.add_theme_constant_override("separation", 6)
	body.add_child(preview_box)
	preview = CardTile.new()
	preview.custom_minimum_size = Vector2(360, 500)         # (a sheet's width: the art at five times its pixels)
	preview_box.add_child(preview)
	form = TouchList.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.size_flags_vertical = Control.SIZE_EXPAND_FILL
	form.row_tapped.connect(_on_form_row)
	body.add_child(form)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	col.add_child(foot)
	back_btn = UI.button("Home", _back)
	foot.add_child(back_btn)
	note = UI.label("", 17, UI.GOLD, true)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	foot.add_child(note)
	export_btn = UI.button("Export", export_all, 140)
	foot.add_child(export_btn)
	new_btn = UI.button("New card", ask_new, 170)
	new_btn.theme_type_variation = "MainButton"
	foot.add_child(new_btn)
	reset_btn = UI.button("Reset", ask_reset, 130)
	foot.add_child(reset_btn)
	delete_btn = UI.button("Delete", ask_delete, 130)
	foot.add_child(delete_btn)
	copy_btn = UI.button("Copy", copy_card, 120)
	foot.add_child(copy_btn)
	save_btn = UI.button("Save", save_card, 150)
	save_btn.theme_type_variation = "MainButton"
	foot.add_child(save_btn)


## Opens on the Card Forge, with the cards as the game now has them.
func open(r: Roster) -> void:
	roster = r
	_close_dialog()
	open_tool("forge")


func open_tool(k: String) -> void:
	for t in tools:
		tools[t].set_pressed_no_signal(t == k)
	if k == "chassis" and dialog == null:
		tools["forge"].set_pressed_no_signal(true)
		tools[k].set_pressed_no_signal(false)
		tool_requested.emit(k)
		return
	if k != "forge":
		tools["forge"].set_pressed_no_signal(true)
		tools[k].set_pressed_no_signal(false)
		say("The %s comes to the Sandbox in a later version. Until then it is in the Companion." % ("Chassis builder" if k == "chassis" else ("POI Sandbox" if k == "poi" else "Pixel Studio")))
		return
	show_list()


func say(t: String, bad := false) -> void:
	note.text = t
	note.add_theme_color_override("font_color", UI.SOFT_RED if bad else UI.GOLD)


func _back() -> void:
	if dialog != null or sheet != null:
		return
	if mode == "edit":
		if dirty:
			_ask("Leave without saving?", "Your changes to %s aren't kept." % str(card.get("name", "this card")), ["Keep editing", "Leave"], func(k):
				if k == 1:
					show_list())
			return
		show_list()
	else:
		closed.emit()


# ---------------------------------------------------------------- the cards
## Every card the game plays now, the deleted ones of the export's too (for Restore).
func all_cards() -> Array:
	return roster.cards.filter(func(c): return not ["workshop", "design", "prebuilt"].has(str(c.get("_src", ""))))


func deleted_cards() -> Array:
	var keys: Array = Sandbox.deleted_keys()
	return Rules.ints(roster.data.own_cards()).filter(func(c): return c is Dictionary and keys.has(Sandbox.key_of(c)))


func listed() -> Array:
	var src: Array = deleted_cards() if view == "deleted" else all_cards()
	var q := search.strip_edges().to_lower()
	return src.filter(func(c):
		var k := Sandbox.key_of(c)
		if type_filter != "all" and Roster.type_of(c) != type_filter:
			return false
		if view == "changed" and not (Sandbox.changed(k) and not Sandbox.is_own(k)):
			return false
		if view == "mine" and not Sandbox.is_own(k):
			return false
		return q == "" or q in str(c.get("name", "")).to_lower())


func show_list() -> void:
	mode = "list"
	card = {}
	key = ""
	dirty = false
	title.text = "Sandbox · Card Forge"
	tool_row.visible = true
	back_btn.text = "Home"
	grid.visible = true
	preview_box.visible = false
	form.visible = false
	for b in [save_btn, copy_btn, delete_btn, reset_btn]:
		b.visible = false
	export_btn.visible = true
	new_btn.visible = true
	_filters()
	_fill_grid()


func _filters() -> void:
	for ch in sub.get_children():
		ch.queue_free()
	var kinds := [["all", "All"]]
	for t in ForgeModel.TYPE_ORDER:
		kinds.append([t, ForgeModel.label(t)])
	for k in kinds:
		var kk: String = k[0]
		var b := UI.button(k[1], func():
			type_filter = kk
			_filters()
			_fill_grid(), 0)
		b.toggle_mode = true
		b.button_pressed = type_filter == kk
		sub.add_child(b)
	for s in SHOWS:
		var ss: String = s[0]
		var b := UI.button(s[1], func():
			view = ss
			_filters()
			_fill_grid(), 0)
		b.toggle_mode = true
		b.button_pressed = view == ss
		b.add_theme_color_override("font_color", UI.GOLD)
		sub.add_child(b)
	search_edit = LineEdit.new()
	search_edit.placeholder_text = "Find a card"
	search_edit.text = search
	search_edit.custom_minimum_size = Vector2(240, 44)
	search_edit.text_changed.connect(func(t):
		search = t
		_fill_grid())
	sub.add_child(search_edit)


func _fill_grid() -> void:
	_shown = listed()
	var items := []
	for c in _shown:
		var k := Sandbox.key_of(c)
		var mark := ""
		if view == "deleted":
			mark = "Deleted"
		elif Sandbox.is_own(k):
			mark = "Yours"
		elif Sandbox.changed(k):
			mark = "Changed"
		items.append({"card": c, "art": roster.art_for(c), "mark": mark})
	grid.empty_text = "No cards like that." if view != "deleted" else "No cards deleted."
	grid.set_items(items, false)
	var n := Sandbox.counts()
	hint.text = "%d card%s. You have made %d, changed %d and deleted %d. Tap a card to change it%s. Your cards are kept on this phone, over the export the game plays; Export writes them all for the Companion's Card Forge to import." % [
		_shown.size(), "" if _shown.size() == 1 else "s", n["made"], n["edited"], n["deleted"], ", or to restore it" if view == "deleted" else ""]


func _on_card(i: int) -> void:
	if dialog != null or i < 0 or i >= _shown.size():
		return
	var c: Dictionary = _shown[i]
	if view == "deleted":
		_ask("Restore %s?" % str(c.get("name", "")), "It comes back as the export has it.", ["Cancel", "Restore"], func(k):
			if k == 1:
				Sandbox.reset(Sandbox.key_of(c))
				_commit("%s is back." % str(c.get("name", "")))
				_fill_grid())
		return
	edit(c)


# ---------------------------------------------------------------- one card
## Opens a card to change: a working copy, kept only when saved.
func edit(c: Dictionary, as_new := false) -> void:
	mode = "edit"
	card = Sandbox.stripped(c).duplicate(true)
	if not (card.get("stats") is Dictionary):
		card["stats"] = {}
	if not (card.get("entries") is Array):
		card["entries"] = []
	key = "" if as_new else Sandbox.key_of(c)
	dirty = as_new
	tool_row.visible = false
	back_btn.text = "Back"
	grid.visible = false
	preview_box.visible = true
	form.visible = true
	for ch in sub.get_children():
		ch.queue_free()
	export_btn.visible = false
	new_btn.visible = false
	save_btn.visible = true
	copy_btn.visible = key != ""
	delete_btn.visible = key != ""
	reset_btn.visible = key != "" and not Sandbox.is_own(key) and Sandbox.changed(key)
	say("")
	refresh()


func type() -> String:
	return str(card.get("cardType", "hero")).to_lower()


func refresh() -> void:
	var keep := form.scroll
	title.text = "Card Forge · " + (str(card.get("name", "")) if str(card.get("name", "")) != "" else "New card") + (" *" if dirty else "")
	var shown: Dictionary = Rules.ints(card.duplicate(true))
	shown["_artName"] = key.split("|", true, 1)[1] if key.contains("|") and not Sandbox.is_own(key) else str(card.get("name", ""))
	preview.card = shown
	preview.art = roster.art_for(shown) if roster != null else null
	preview.mark = "Yours" if Sandbox.is_own(key) or key == "" else ("Changed" if Sandbox.changed(key) or dirty else "")
	preview.queue_redraw()
	var probs := ForgeModel.problems(card, all_cards(), key)
	var warns := ForgeModel.warnings(card)
	hint.text = ("Can't be saved yet: " + " ".join(probs)) if not probs.is_empty() else (("Saved anyway, but the game can't carry out all of it: " + " ".join(warns)) if not warns.is_empty() else "Tap a chip to change it. The card is drawn as it will be.")
	hint.add_theme_color_override("font_color", UI.SOFT_RED if not probs.is_empty() else (UI.GOLD if not warns.is_empty() else UI.PALE))
	save_btn.disabled = not probs.is_empty()
	form.clear()
	_rows = []
	_build_form()
	form.settle()
	form.scroll_by(keep)


func _build_form() -> void:
	var t := type()
	var d := ForgeModel.type_def(t)
	_row("Name", [[str(card.get("name", "")) if str(card.get("name", "")) != "" else "(none)", ["name"], UI.TEXT, false]])
	var kinds := []
	for k in ForgeModel.TYPE_ORDER:
		kinds.append([ForgeModel.label(k), ["type", k], UI.CYAN, k == t])
	_row("Kind", kinds)
	if ForgeModel.has_rarity(t):
		var rs := []
		for r in ForgeModel.RARITIES:
			if r != "":
				rs.append([r.capitalize(), ["rarity", r], Color(DockScreen.rarity_colour(ForgeModel.RARITIES.find(r) - 1)), str(card.get("rarity", "")) == r])
		_row("Rarity", rs)
	if ForgeModel.is_foe(t):
		_row("Skull Level", _stepper("skull", int(card.get("skullLevel", 1) if card.get("skullLevel") != null else 1)))
	var aff: Array = card.get("affinities", []) if card.get("affinities") is Array else []
	var dist := str(aff[0].get("district", "")) if not aff.is_empty() and aff[0] is Dictionary else ""
	var ds := []
	for x in ForgeModel.DISTRICTS:
		ds.append([str(x["name"]), ["dist", x["id"]], UI.CYAN, x["id"] == dist])
	_row("District", ds)
	if d.get("aether", false):
		var ac: Dictionary = card.get("aetherCost") if card.get("aetherCost") is Dictionary else {"generic": 0, "affinity": 0, "affinity2": 0}
		_row("Aether cost: any", _stepper("ae_generic", _num(ac.get("generic"))))
		_row("Aether cost: its District's", _stepper("ae_affinity", _num(ac.get("affinity"))))
	if d.get("chip", false):
		_row("Aether it gives", _stepper("chip", _num(card.get("aetherValue"))))
	if ForgeModel.is_unit(t):
		var have: Array = card.get("combatRoles", []) if card.get("combatRoles") is Array else []
		_row("Combat Roles", ForgeModel.ROLES.map(func(r): return [r.capitalize(), ["role", r], UI.CYAN, have.has(r)]))
		_row("Origin", ForgeModel.ORIGINS.map(func(o): return [o if o != "" else "None", ["origin", o], UI.CYAN, str(card.get("origin", "") if card.get("origin") != null else "") == o]))
	if d.get("token", false):
		_row("A Token (put down by another card, never in a Deck)", [["Yes" if Rules.truthy(card.get("token")) else "No", ["token"], UI.CYAN, Rules.truthy(card.get("token"))]])
	if not d.get("no_arch", false):
		var arch: Array = card.get("archetypes", []) if card.get("archetypes") is Array else []
		_row("Archetypes", ForgeModel.ARCHETYPES.map(func(a): return [a, ["arch", a], UI.CYAN, arch.has(a)]))
	for s in d["stats"]:
		var v = card["stats"].get(s[0], "")
		_row("%s (%d to %d)" % [s[1], s[2], s[3]], _stepper("stat:" + str(s[0]), _num(v), d.get("mods", false)))
	# the abilities
	var es: Array = card["entries"]
	var cap := int(d.get("cap", 99))
	_head("Abilities (%d%s)" % [es.size(), (" of " + str(cap)) if cap < 99 else ""])
	for i in es.size():
		_entry_rows(i, es[i])
	if es.size() < cap:
		_row("", [["+ Add an ability", ["e_add"], UI.CYAN, false]])
	# the lore
	_head("Lore")
	var lore := str(card.get("lore", "") if card.get("lore") != null else "")
	_row(lore if lore != "" else "(none)", [["Write", ["lore"], UI.CYAN, false], ["Shown on the card" if Rules.truthy(card.get("loreEnabled")) else "Hidden", ["lore_on"], UI.CYAN, Rules.truthy(card.get("loreEnabled"))]])


func _entry_rows(i: int, e: Dictionary) -> void:
	var t := type()
	var d := ForgeModel.type_def(t)
	var nm := str(e.get("name", ""))
	var top := [[nm if nm != "" else "(no name)", ["e_name", i], UI.TEXT, false]]
	if i > 0:
		top.append(["Move up", ["e_up", i], UI.PALE, false])
	top.append(["Remove", ["e_del", i], UI.SOFT_RED, false])
	_row("Ability %d" % (i + 1), top)
	_row("  Tag", (d["tags"] as Array).map(func(g): return [g, ["e_tag", i, g], UI.CYAN, str(e.get("kind", "")) == g]))
	if ForgeModel.is_unit(t) and str(e.get("kind", "")) != "Passive":
		var role := str(e.get("role", "") if e.get("role") != null else "")
		_row("  Role", ForgeModel.EROLES.map(func(r): return [r.capitalize() if r != "" else "None", ["e_role", i, r], UI.CYAN, role == r]))
	for n in ForgeModel.entry_numbers(t, e):
		_row("  %s (%d to %d)" % [n[1], n[2], n[3]], _stepper("e_num:%d:%s" % [i, n[0]], _num(e.get(n[0]))))
	if str(e.get("role", "")) == "ranged":
		var pr := str(e.get("projectile", "") if e.get("projectile") != null else "")
		_row("  It fires", ForgeModel.PROJECTILES.map(func(p): return [p.capitalize(), ["e_proj", i, p], UI.CYAN, pr == p or (pr == "" and p == "bolt")]))
	var sents := Keywords.sentences(str(e.get("text", "")))
	for j in sents.size():
		_rich_row("  " + str(sents[j]), [["Change", ["e_sent", i, j], UI.CYAN, false], ["Remove", ["e_sdel", i, j], UI.SOFT_RED, false]])
	_row("  " + ("No effect yet." if sents.is_empty() else ""), [["+ Build an effect", ["e_build", i], UI.CYAN, false], ["Type it", ["e_type", i], UI.PALE, false]])


## A stepper: − the value +, as chips.
func _stepper(what: String, v: int, blank_ok := false) -> Array:
	var shown := (("+" if v > 0 else "") + str(v)) if blank_ok else str(v)
	if blank_ok and v == 0:
		shown = "—"
	return [["−", ["step", what, -1], UI.CYAN, false], [shown, null, UI.TEXT, false], ["+", ["step", what, 1], UI.CYAN, false]]


static func _num(v) -> int:
	if v == null:
		return 0
	var x = Rules.num(str(v).replace("+", "").replace("−", "-"), 0)
	return int(x) if x is int or x is float else 0


func _head(text: String) -> void:
	var l := UI.label(text, 21, UI.CYAN)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", 8)
	m.add_child(l)
	_rows.append({"text": text, "acts": []})
	form.add_row(m)


## A row: what it is on the left, chips on the right: [[label, act, colour, on]].
func _row(text: String, chips: Array) -> void:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", UI.box(UI.PANEL, UI.LINE, 1, 6, 8))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	row.add_child(hb)
	if text != "":
		var l := UI.label(text, 16, UI.PALE, true)
		l.custom_minimum_size = Vector2(190, 0)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(l)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for c in chips:
		flow.add_child(UI.chip(str(c[0]), c[2], c[1], c[3], 15))
	hb.add_child(flow)
	_rows.append({"text": text, "acts": chips.filter(func(c): return c[1] != null).map(func(c): return c[1]), "chips": chips.map(func(c): return str(c[0]))})
	form.add_row(row)


## A row with an effect in its keywords' colours.
func _rich_row(text: String, chips: Array) -> void:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", UI.box(UI.PANEL, UI.LINE, 1, 6, 8))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	row.add_child(hb)
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.scroll_active = false
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_font_size_override("normal_font_size", 16)
	t.text = BuilderSheet.coloured(text.strip_edges())
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(t)
	for c in chips:
		hb.add_child(UI.chip(str(c[0]), c[2], c[1], c[3], 15))
	_rows.append({"text": text, "acts": chips.map(func(c): return c[1]), "chips": chips.map(func(c): return str(c[0]))})
	form.add_row(row)


func _on_form_row(i: int, at: Vector2) -> void:
	if dialog != null or sheet != null or i < 0 or i >= form.rows().size():
		return
	var what = UI.act_at(form.rows()[i], at)
	if what != null:
		act(what)


## Every tap the form offers now (for the tests).
func offers() -> Array:
	var out := []
	for r in _rows:
		out.append_array(r.get("acts", []))
	return out


# ---------------------------------------------------------------- what a tap does
func act(what: Array) -> void:
	var t := type()
	var d := ForgeModel.type_def(t)
	match what[0]:
		"name":
			_ask_text("Name", str(card.get("name", "")), func(v):
				card["name"] = v.strip_edges()
				_changed())
			return
		"type":
			_set_type(str(what[1]))
		"rarity":
			card["rarity"] = what[1]
		"dist":
			var id := str(what[1])
			if id == "":
				card["affinities"] = []
			else:
				var aff: Array = card.get("affinities", []) if card.get("affinities") is Array else []
				var lv := int(aff[0].get("level", 0)) if not aff.is_empty() and aff[0] is Dictionary else 0
				card["affinities"] = [{"district": id, "symbol": ForgeModel.district_sym(id), "level": lv}]
		"role":
			var rs: Array = card.get("combatRoles", []) if card.get("combatRoles") is Array else []
			if rs.has(what[1]):
				rs.erase(what[1])
			else:
				rs.append(what[1])
			card["combatRoles"] = ForgeModel.ROLES.filter(func(r): return rs.has(r))
		"origin":
			card["origin"] = what[1] if what[1] != "" else null
		"token":
			card["token"] = not Rules.truthy(card.get("token"))
		"arch":
			var arch: Array = card.get("archetypes", []) if card.get("archetypes") is Array else []
			if arch.has(what[1]):
				arch.erase(what[1])
			else:
				arch.append(what[1])
			card["archetypes"] = arch
			if ForgeModel.is_unit(t):
				card["mechanical"] = arch.has("Mechanical")
		"step":
			_step(str(what[1]), int(what[2]))
		"e_add":
			card["entries"].append(ForgeModel.blank_entry(t))
		"e_del":
			card["entries"].remove_at(int(what[1]))
		"e_up":
			var i := int(what[1])
			var e = card["entries"][i]
			card["entries"].remove_at(i)
			card["entries"].insert(i - 1, e)
		"e_name":
			var i := int(what[1])
			_ask_text("Ability name", str(card["entries"][i].get("name", "")), func(v):
				card["entries"][i]["name"] = v.strip_edges()
				_changed())
			return
		"e_tag":
			var e: Dictionary = card["entries"][int(what[1])]
			var keep_text = e.get("text", "")
			var fresh := ForgeModel.blank_entry(t, str(what[2]))
			fresh["name"] = e.get("name", fresh["name"])
			fresh["text"] = keep_text
			card["entries"][int(what[1])] = fresh
		"e_role":
			var e: Dictionary = card["entries"][int(what[1])]
			e["role"] = what[2] if what[2] != "" else null
			if what[2] == "ranged" and _num(e.get("attackRange")) == 0:
				e["attackRange"] = "4"
				e["toHit"] = "8"
		"e_proj":
			card["entries"][int(what[1])]["projectile"] = what[2]
		"e_sent", "e_build":
			open_builder(int(what[1]), int(what[2]) if what[0] == "e_sent" else -1)
			return
		"e_sdel":
			var e: Dictionary = card["entries"][int(what[1])]
			var sents := Keywords.sentences(str(e.get("text", "")))
			sents.remove_at(int(what[2]))
			e["text"] = " ".join(sents)
		"e_type":
			var i := int(what[1])
			_ask_text("Effect, in keywords: [[target enemy]] takes [[damage 2]].", str(card["entries"][i].get("text", "")), func(v):
				card["entries"][i]["text"] = v.strip_edges()
				_changed())
			return
		"lore":
			_ask_text("Lore", str(card.get("lore", "") if card.get("lore") != null else ""), func(v):
				card["lore"] = v.strip_edges() if v.strip_edges() != "" else null
				if card["lore"] != null:
					card["loreEnabled"] = true
				_changed())
			return
		"lore_on":
			card["loreEnabled"] = not Rules.truthy(card.get("loreEnabled"))
	_changed()


func _changed() -> void:
	dirty = true
	refresh()


## A new kind: the numbers that kind has, from what it had where they match.
func _set_type(t: String) -> void:
	if t == type():
		return
	var fresh := ForgeModel.blank(t, str(card.get("name", "")))
	for s in ForgeModel.type_def(t)["stats"]:
		if card["stats"].has(s[0]) and str(card["stats"][s[0]]) != "":
			fresh["stats"][s[0]] = card["stats"][s[0]]
	fresh["affinities"] = card.get("affinities", [])
	fresh["lore"] = card.get("lore")
	fresh["loreEnabled"] = card.get("loreEnabled", false)
	if ForgeModel.has_rarity(t) and str(card.get("rarity", "")) != "":
		fresh["rarity"] = card["rarity"]
	var tags: Array = ForgeModel.type_def(t)["tags"]
	var cap := int(ForgeModel.type_def(t).get("cap", 99))
	var es := []
	for e in card["entries"]:
		if es.size() >= cap:
			break
		var ne := ForgeModel.blank_entry(t, str(e.get("kind", "")) if tags.has(str(e.get("kind", ""))) else "")
		for k in ["name", "text", "role", "damage", "attackRange", "toHit", "armorPenetration", "energyCost", "auraRadius", "projectile"]:
			if e.has(k) and e[k] != null and str(e[k]) != "":
				ne[k] = e[k]
		es.append(ne)
	fresh["entries"] = es if not es.is_empty() else fresh["entries"]
	for k in ["id", "createdBy", "level", "testCard", "batch", "pixelArt", "pixelToken"]:
		if card.has(k):
			fresh[k] = card[k]
	card = fresh


func _step(what: String, by: int) -> void:
	var t := type()
	if what == "skull":
		card["skullLevel"] = clampi(_num(card.get("skullLevel")) + by, 1, 6)
	elif what.begins_with("ae_"):
		var ac: Dictionary = card.get("aetherCost") if card.get("aetherCost") is Dictionary else {"generic": 0, "affinity": 0, "affinity2": 0}
		var k := what.substr(3)
		ac[k] = clampi(_num(ac.get(k)) + by, 0, 9)
		card["aetherCost"] = ac
	elif what == "chip":
		card["aetherValue"] = str(clampi(_num(card.get("aetherValue")) + by, 0, 6))
	elif what.begins_with("stat:"):
		var k := what.substr(5)
		for s in ForgeModel.type_def(t)["stats"]:
			if s[0] == k:
				var v := clampi(_num(card["stats"].get(k)) + by, int(s[2]), int(s[3]))
				if ForgeModel.type_def(t).get("mods", false):
					card["stats"][k] = "" if v == 0 else (("+" if v > 0 else "") + str(v))
				else:
					card["stats"][k] = str(v)
	elif what.begins_with("e_num:"):
		var p := what.split(":")
		var e: Dictionary = card["entries"][int(p[1])]
		for n in ForgeModel.entry_numbers(t, e):
			if n[0] == p[2]:
				var v := clampi(_num(e.get(p[2])) + by, int(n[2]), int(n[3]))
				e[p[2]] = str(v) if v != 0 or p[2] == "energyCost" else null


## The keyword builder, on one of an ability's effects (j = -1: a new one).
func open_builder(i: int, j: int) -> void:
	var e: Dictionary = card["entries"][i]
	var sents := Keywords.sentences(str(e.get("text", "")))
	var tag := ForgeModel.builder_tag(e)
	var o := {"kind": Keywords.kind_of(tag), "tag": tag, "cardType": type(), "role": str(e.get("role", "") if e.get("role") != null else "").to_lower(),
		"others": " ".join(sents.filter(func(s): return j < 0 or s != sents[j])),
		"cards": roster.troops().map(func(c): return str(c["name"])) if roster != null else [], "variable": Rules.truthy(card.get("hasVariableCost"))}
	if j >= 0 and j < sents.size():
		o["sentence"] = sents[j]
	sheet = BuilderSheet.new()
	add_child(sheet)
	sheet.done.connect(func(text):
		_drop_sheet()
		if j >= 0:
			sents[j] = text
		else:
			sents.append(text)
		e["text"] = " ".join(sents.filter(func(s): return str(s).strip_edges() != ""))
		_changed())
	sheet.cancelled.connect(func(): _drop_sheet())
	sheet.open(o)


func _drop_sheet() -> void:
	if sheet != null:
		Motion.pop_out(sheet, sheet.get_meta("box", null))
		sheet = null


# ---------------------------------------------------------------- keeping it
func save_card() -> void:
	var probs := ForgeModel.problems(card, all_cards(), key)
	if not probs.is_empty():
		say(" ".join(probs), true)
		return
	card["lastEditedBy"] = "Sandbox"
	var was_new := key == ""
	key = Sandbox.put(card, key)
	dirty = false
	_commit("%s %s." % [str(card["name"]), "made" if was_new else "saved"])
	copy_btn.visible = true
	delete_btn.visible = true
	reset_btn.visible = not Sandbox.is_own(key)
	refresh()


func copy_card() -> void:
	var c := card.duplicate(true)
	c.erase("id")
	c["name"] = _free_name(str(card.get("name", "Card")) + " copy")
	edit(c, true)
	say("A copy: save it to keep it.")


func _free_name(want: String) -> String:
	var names := all_cards().map(func(c): return str(c.get("name", "")))
	var nm := want
	var n := 2
	while names.has(nm):
		nm = "%s %d" % [want, n]
		n += 1
	return nm


func ask_delete() -> void:
	if key == "":
		return
	var own := Sandbox.is_own(key)
	_ask("Delete %s?" % str(card.get("name", "")), ("It is gone for good." if own else "It leaves the game: no Deck, fight or drop has it. Deleted, under Deleted, can bring it back.") + " Strike Teams that hold it keep its name.",
		["Keep it", "Delete"], func(k):
			if k == 1:
				var nm := str(card.get("name", ""))
				Sandbox.delete(key)
				_commit("%s deleted." % nm)
				show_list())


func ask_reset() -> void:
	if key == "" or Sandbox.is_own(key):
		return
	_ask("Reset %s?" % str(card.get("name", "")), "It goes back to how the export has it, and your changes to it are gone.", ["Keep mine", "Reset"], func(k):
		if k == 1:
			Sandbox.reset(key)
			_commit("Back as the export has it.")
			var orig = roster.data.own_cards().filter(func(c): return c is Dictionary and Sandbox.key_of(c) == key)
			if not orig.is_empty():
				edit(Rules.ints(orig[0]))
			else:
				show_list())


## A new card: of the kind the list is showing (a Hero when it shows all); its Kind chips change it.
func ask_new() -> void:
	var t := type_filter if ForgeModel.TYPES.has(type_filter) else "hero"
	edit(ForgeModel.blank(t, _free_name("New " + ForgeModel.label(t).to_lower())), true)
	say("A new %s: choose its Kind, fill it in, and save it to keep it." % ForgeModel.label(t).to_lower())


func export_all() -> void:
	var chs = roster.data.content("chassis").get("chassis", [])
	var f := Sandbox.export_to(all_cards(), "", chs if chs is Array else [])
	if f == "":
		say("It couldn't be written.", true)
	else:
		say("Written to %s. In the Companion, import it in the Card Forge." % f)


## Saves the Sandbox and has the game read its cards again.
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
