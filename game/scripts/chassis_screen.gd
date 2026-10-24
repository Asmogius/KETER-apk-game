## The Sandbox's Chassis builder (0.28), the Companion's Chassis editor made
## over for a thumb. Every chassis the game has (the export's, as you have
## changed them, and your own), grouped by District; and for one, its name,
## District, body plan, subtypes (one or two Combat Roles), power cap, ability
## cap, Troop parts, stats, the most range and AP and the best to-hit a
## design's attacks may have, its Aether cost to deploy, and the keywords a
## design on it may use. "Try a design" checks abilities against it as they
## are built, with the keyword builder offering only what it allows.
##
## Save keeps it in the Sandbox (sandbox.gd), over the export; a chassis made
## here is yours in the Workshop at once. Delete, Reset and Copy work as in
## the Card Forge, and Export writes it for the Companion with the cards.
class_name ChassisScreen
extends Control

signal closed
signal changed                 # the Sandbox's chassis have changed: the game reads them again
signal tool_requested(k: String)

const BODIES := ["Bipedal", "Quadruped", "Quadcopter", "Hexapod", "Octopod", "Other"]
const SUBTYPES := ["Melee", "Ranged", "Support", "Cyber"]
const STATS := [["hp", "HP", 1, 60], ["ac", "AC", 1, 20], ["move", "Movement", 0, 8], ["dmg", "Damage", 0, 20], ["nrg", "Energy", 0, 8], ["int", "Integrity", 1, 20]]
const SHOWS := [["all", "All"], ["changed", "Changed"], ["mine", "Yours"], ["deleted", "Deleted"]]
const TRY_ROLES := ["Melee", "Ranged", "Support", "Cyber", "Passive"]

var roster: Roster = null
var mode := "list"
var view := "all"
var ch := {}                   # the chassis being edited, as it will be kept
var id := ""                   # its id ("" while it is new)
var dirty := false
var tries: Array = [{"role": "Ranged", "text": "[[target enemy]] takes [[damage 3]]."}]   # "Try a design"
var dialog: Control = null
var sheet: BuilderSheet = null

var title: Label
var tools := {}
var tool_row: HBoxContainer
var sub: HFlowContainer
var hint: Label
var body: HBoxContainer
var list: TouchList
var preview_box: VBoxContainer
var preview_pic: TextureRect
var preview_text: Label
var form: TouchList
var note: Label
var back_btn: Button
var export_btn: Button
var new_btn: Button
var save_btn: Button
var copy_btn: Button
var delete_btn: Button
var reset_btn: Button
var _shown: Array = []         # the list's rows: a chassis each (or a District's head: null)
var _rows: Array = []          # the form's rows: {text, acts}


func _init() -> void:
	var col := UI.page(self, "menu", 0.78)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	col.add_child(head)
	title = UI.label("Sandbox · Chassis", 30, UI.CYAN)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	tool_row = HBoxContainer.new()
	tool_row.add_theme_constant_override("separation", 8)
	head.add_child(tool_row)
	for t in ForgeScreen.TOOLS:
		var k: String = t[0]
		var b := UI.button(t[1], func(): _tool(k), 150)
		b.toggle_mode = true
		b.button_pressed = k == "chassis"
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
	preview_box = VBoxContainer.new()
	preview_box.custom_minimum_size = Vector2(300, 0)
	preview_box.add_theme_constant_override("separation", 8)
	body.add_child(preview_box)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UI.box(UI.BG, UI.LINE, 2, 4, 6))
	preview_box.add_child(frame)
	preview_pic = TextureRect.new()
	preview_pic.custom_minimum_size = Vector2(288, 240)
	preview_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(preview_pic)
	preview_text = UI.label("", 16, UI.TEXT, true)
	preview_box.add_child(preview_text)
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
	new_btn = UI.button("New chassis", func(): edit(blank(), true), 190)
	new_btn.theme_type_variation = "MainButton"
	foot.add_child(new_btn)
	reset_btn = UI.button("Reset", ask_reset, 130)
	foot.add_child(reset_btn)
	delete_btn = UI.button("Delete", ask_delete, 130)
	foot.add_child(delete_btn)
	copy_btn = UI.button("Copy", copy_chassis, 120)
	foot.add_child(copy_btn)
	save_btn = UI.button("Save", save_chassis, 150)
	save_btn.theme_type_variation = "MainButton"
	foot.add_child(save_btn)


func open(r: Roster) -> void:
	roster = r
	_close_dialog()
	show_list()


func remember() -> Dictionary:
	return {"view": view}


func recall(u: Dictionary) -> void:
	view = str(u.get("view", view))


func draft() -> Dictionary:
	if mode != "edit" or not dirty:
		return {}
	return {"tool": "chassis", "id": id, "item": ch.duplicate(true), "what": str(ch.get("name", "a chassis"))}


func restore(d: Dictionary) -> void:
	var c: Dictionary = (d.get("item", {}) as Dictionary).duplicate(true)
	var i := str(d.get("id", ""))
	if i != "":
		c["id"] = i
	edit(c, i == "")
	dirty = true
	refresh()
	say("Your draft, as it was when the game closed: save it to keep it.")


func _tool(k: String) -> void:
	for t in tools:
		tools[t].set_pressed_no_signal(t == "chassis")
	if k != "chassis" and dialog == null:
		tool_requested.emit(k)


func say(t: String, bad := false) -> void:
	note.text = t
	note.add_theme_color_override("font_color", UI.SOFT_RED if bad else UI.GOLD)


func _back() -> void:
	if dialog != null or sheet != null:
		return
	if mode == "edit":
		if dirty:
			_ask("Leave without saving?", "Your changes to %s aren't kept." % str(ch.get("name", "this chassis")), ["Keep editing", "Leave"], func(k):
				if k == 1:
					show_list())
			return
		show_list()
	else:
		closed.emit()


## A new chassis, as the Companion starts one.
static func blank() -> Dictionary:
	return {"name": "New chassis", "district": "", "bodyPlan": "Bipedal", "subtypes": ["Melee"], "powerCap": 20, "abilityCap": 2, "cost": {"troop": 4},
		"maxRange": 6, "bestHit": 4, "maxAP": 6, "aether": {"generic": 1, "affinity": 0},
		"stats": {"hp": 12, "ac": 10, "move": 4, "dmg": 3, "nrg": 3, "int": 10}, "allowed": [], "notes": ""}


# ---------------------------------------------------------------- the chassis
func all_chassis() -> Array:
	var c = roster.data.content("chassis").get("chassis", []) if roster != null else []
	return Rules.ints(c) if c is Array else []


func deleted() -> Array:
	var gone: Array = Sandbox.deleted_chassis()
	var raw = roster.data._raw_content("chassis").get("chassis", []) if roster != null else []
	return Rules.ints(raw).filter(func(c): return c is Dictionary and gone.has(str(c.get("id", "")))) if raw is Array else []


func listed() -> Array:
	var src: Array = deleted() if view == "deleted" else all_chassis()
	return src.filter(func(c):
		var cid := str(c.get("id", ""))
		if view == "changed":
			return Sandbox.chassis_changed(cid) and not Sandbox.chassis_own(cid)
		if view == "mine":
			return Sandbox.chassis_own(cid)
		return true)


func show_list() -> void:
	Sandbox.drop_draft()          # (0.33) nothing left unsaved: no draft to keep
	mode = "list"
	ch = {}
	id = ""
	dirty = false
	title.text = "Sandbox · Chassis"
	tool_row.visible = true
	back_btn.text = "Home"
	list.visible = true
	preview_box.visible = false
	form.visible = false
	for b in [save_btn, copy_btn, delete_btn, reset_btn]:
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
	var n_made := all_chassis().filter(func(c): return Sandbox.chassis_own(str(c.get("id", "")))).size()
	hint.text = "%d chassis%s. A chassis is the frame a Troop is built on in the Workshop: its stats, its power and ability caps, what its attacks may reach, and the keywords a design on it may use. Tap one to change it. You have made %d; one you make is yours in the Workshop at once." % [
		all.size(), "" if view == "all" else (" " + view), n_made]
	var groups := [["", "General"]] + Builder.DISTRICTS
	for g in groups:
		var in_g := all.filter(func(c): return str(c.get("district", "")) == str(g[0]))
		if in_g.is_empty():
			continue
		var h := UI.label(str(g[1]), 21, UI.CYAN)
		list.add_row(h)
		_shown.append(null)
		for c in in_g:
			list.add_row(_chassis_row(c))
			_shown.append(c)
	if all.is_empty():
		list.add_row(UI.label("No chassis like that." if view != "deleted" else "No chassis deleted.", 16, UI.DIM, true))
		_shown.append(null)
	list.settle()
	list.scroll_by(keep)


func _chassis_row(c: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 72)
	row.add_theme_stylebox_override("panel", UI.box(UI.PANEL, UI.LINE, 1, 6, 10))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	row.add_child(hb)
	var tex := Art.body_token(str(c.get("bodyPlan", "")))
	if tex != null:
		hb.add_child(UI.pixels(tex, 48))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(v)
	v.add_child(UI.label(str(c.get("name", "")), 19, UI.TEXT))
	var subs: Array = c.get("subtypes", []) if c.get("subtypes") is Array else []
	v.add_child(UI.label("%s%s · power %s · %s abilit%s · %d keywords" % [str(c.get("bodyPlan", "")), (" · " + " + ".join(subs)) if not subs.is_empty() else "",
		str(c.get("powerCap", "")), str(c.get("abilityCap", "")), "y" if str(c.get("abilityCap", "")) == "1" else "ies", (c.get("allowed", []) as Array).size() if c.get("allowed") is Array else 0], 15, UI.DIM))
	var cid := str(c.get("id", ""))
	var mark := "Deleted" if view == "deleted" else ("Yours" if Sandbox.chassis_own(cid) else ("Changed" if Sandbox.chassis_changed(cid) else ""))
	if mark != "":
		hb.add_child(UI.tag(mark, UI.GOLD))
	return row


func _on_list_row(i: int, _at: Vector2) -> void:
	if dialog != null or i < 0 or i >= _shown.size() or _shown[i] == null:
		return
	var c: Dictionary = _shown[i]
	if view == "deleted":
		_ask("Restore %s?" % str(c.get("name", "")), "It comes back as the export has it.", ["Cancel", "Restore"], func(k):
			if k == 1:
				Sandbox.reset_chassis(str(c.get("id", "")))
				_commit("%s is back." % str(c.get("name", "")))
				_fill_list())
		return
	edit(c)


# ---------------------------------------------------------------- one chassis
func edit(c: Dictionary, as_new := false) -> void:
	mode = "edit"
	ch = Sandbox.stripped(c).duplicate(true)
	for k in blank():
		if not ch.has(k):
			ch[k] = blank()[k]
	id = "" if as_new else str(c.get("id", ""))
	if as_new:
		ch.erase("id")
	dirty = as_new
	tool_row.visible = false
	back_btn.text = "Back"
	list.visible = false
	preview_box.visible = true
	form.visible = true
	for x in sub.get_children():
		x.queue_free()
	export_btn.visible = false
	new_btn.visible = false
	save_btn.visible = true
	copy_btn.visible = id != ""
	delete_btn.visible = id != ""
	reset_btn.visible = id != "" and not Sandbox.chassis_own(id) and Sandbox.chassis_changed(id)
	say("A new chassis: fill it in, and save it to keep it." if as_new else "")
	refresh()


func refresh() -> void:
	var keep := form.scroll
	title.text = "Chassis · " + str(ch.get("name", "")) + (" *" if dirty else "")
	preview_pic.texture = Art.body_token(str(ch.get("bodyPlan", "")))
	var st: Dictionary = ch.get("stats", {})
	preview_text.text = "%s\n%s · %s\nHP %s · AC %s · MS %s · DMG %s · NRG %s · INT %s\nPower %s · %s abilities · %s Troop parts" % [
		str(ch.get("name", "")), ForgeModel.district_name(str(ch.get("district", ""))) if str(ch.get("district", "")) != "" else "General", " + ".join(ch.get("subtypes", [])),
		str(st.get("hp", "")), str(st.get("ac", "")), str(st.get("move", "")), str(st.get("dmg", "")), str(st.get("nrg", "")), str(st.get("int", "")),
		str(ch.get("powerCap", "")), str(ch.get("abilityCap", "")), str((ch.get("cost", {}) as Dictionary).get("troop", ""))]
	var probs := problems()
	hint.text = ("Can't be saved yet: " + " ".join(probs)) if not probs.is_empty() else "Tap a chip to change it. Try a design, at the end, checks abilities against it as it stands."
	hint.add_theme_color_override("font_color", UI.SOFT_RED if not probs.is_empty() else UI.PALE)
	save_btn.disabled = not probs.is_empty()
	form.clear()
	_rows = []
	_build_form()
	form.settle()
	form.scroll_by(keep)


func problems() -> Array:
	var out := []
	var nm := str(ch.get("name", "")).strip_edges()
	if nm == "":
		out.append("It needs a name.")
	elif all_chassis().any(func(c): return str(c.get("name", "")) == nm and str(c.get("id", "")) != id):
		out.append("Another chassis is called %s." % nm)
	if (ch.get("subtypes", []) as Array).is_empty():
		out.append("It needs a subtype.")
	return out


func _build_form() -> void:
	_row("Name", [[str(ch.get("name", "")), ["name"], UI.TEXT, false]])
	var ds := [["General", ["dist", ""], UI.CYAN, str(ch.get("district", "")) == ""]]
	for d in Builder.DISTRICTS:
		ds.append(["%s · %s" % d, ["dist", d[0]], UI.CYAN, str(ch.get("district", "")) == d[0]])
	_row("District", ds)
	_row("Body plan", BODIES.map(func(b): return [b, ["body", b], UI.CYAN, str(ch.get("bodyPlan", "")) == b]))
	var subs: Array = ch.get("subtypes", [])
	_row("Subtypes (one or two)", SUBTYPES.map(func(s): return [s, ["sub", s], UI.CYAN, subs.has(s)]))
	_head("Limits and cost")
	_row("Power cap", _stepper("powerCap", int(ch.get("powerCap", 0)), 1, 99))
	_row("Abilities", _stepper("abilityCap", int(ch.get("abilityCap", 0)), 0, 6))
	_row("Troop parts a copy", _stepper("cost", int((ch.get("cost", {}) as Dictionary).get("troop", 0)), 0, 30))
	_head("Stats")
	for s in STATS:
		_row("%s (%d to %d)" % [s[1], s[2], s[3]], _stepper("stat:" + str(s[0]), int((ch.get("stats", {}) as Dictionary).get(s[0], 0)), s[2], s[3]))
	_head("Attacks: the most range and AP, and the best (lowest) to-hit")
	_row("Range", _stepper("maxRange", int(ch.get("maxRange", 0)), 1, 12))
	_row("Best to-hit", _stepper("bestHit", int(ch.get("bestHit", 0)), 1, 20))
	_row("AP", _stepper("maxAP", int(ch.get("maxAP", 0)), 0, 12))
	_head("Aether cost to deploy a design on it")
	var ae: Dictionary = ch.get("aether", {}) if ch.get("aether") is Dictionary else {}
	_row("Any affinity", _stepper("ae:generic", int(ae.get("generic", 0)), 0, 9))
	_row("Its District's", _stepper("ae:affinity", int(ae.get("affinity", 0)), 0, 9))
	var allowed: Array = ch.get("allowed", []) if ch.get("allowed") is Array else []
	_head("Allowed keywords (%d of %d)" % [allowed.size(), chips().size()])
	for cat in Keywords.CATEGORIES:
		var ks: Array = chips().filter(func(k): return k["cat"] == cat["k"])
		var row := [["All", ["all", cat["k"]], UI.PALE, false], ["None", ["none", cat["k"]], UI.PALE, false]]
		for k in ks:
			row.append([str(k["name"]), ["kw", k["name"]], Color(cat["colour"]), allowed.has(k["name"])])
		_row(str(cat["label"]), row)
	_head("Notes")
	_row(str(ch.get("notes", "")) if str(ch.get("notes", "")) != "" else "(none)", [["Write", ["notes"], UI.CYAN, false]])
	_try_rows()


## The keyword chips a chassis offers: the library, and one for every Archetype.
static func chips() -> Array:
	var out: Array = Keywords.KEYWORDS.map(func(k): return {"name": k["name"], "cat": k["cat"]})
	out.append({"name": "Archetype", "cat": "target"})
	return out


## Try a design: abilities checked against the chassis as it stands.
func _try_rows() -> void:
	_head("Try a design")
	for i in tries.size():
		var t: Dictionary = tries[i]
		_row("Ability %d" % (i + 1), TRY_ROLES.map(func(r): return [r, ["try_role", i, r], UI.CYAN, t["role"] == r]) + [["Remove", ["try_del", i], UI.SOFT_RED, false]])
		var sents := Keywords.sentences(str(t["text"]))
		for j in sents.size():
			_rich_row("  " + str(sents[j]), [["Remove", ["try_sdel", i, j], UI.SOFT_RED, false]])
		_row("", [["+ Build an effect", ["try_build", i], UI.CYAN, false], ["Type it", ["try_type", i], UI.PALE, false]])
	_row("", [["+ Add an ability", ["try_add"], UI.CYAN, false]])
	var r := check_try()
	var lines := "Power %d of %s · %d of %s abilities. " % [r["power"], Scoring.text(r["cap"]), r["abilities"], Scoring.text(r["abilityCap"])]
	lines += "This design fits the chassis." if r["ok"] else ("It doesn't fit: " + "; ".join(r["reasons"]) + ".")
	var l := UI.label(lines, 17, UI.GREEN if r["ok"] else UI.SOFT_RED, true)
	_rows.append({"text": lines, "acts": []})
	form.add_row(l)


func check_try() -> Dictionary:
	return Workshop.chassis_check(ch, {"abilities": tries.map(func(t): return {"text": t["text"], "role": "" if t["role"] == "Passive" else str(t["role"]).to_lower()})})


func _stepper(what: String, v: int, lo: int, hi: int) -> Array:
	return [["−", ["step", what, -1, lo, hi], UI.CYAN, false], [str(v), null, UI.TEXT, false], ["+", ["step", what, 1, lo, hi], UI.CYAN, false]]


func _head(text: String) -> void:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", 8)
	m.add_child(UI.label(text, 21, UI.CYAN))
	_rows.append({"text": text, "acts": []})
	form.add_row(m)


func _row(text: String, chips: Array) -> void:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", UI.box(UI.PANEL, UI.LINE, 1, 6, 8))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	row.add_child(hb)
	if text != "":
		var l := UI.label(text, 16, UI.PALE, true)
		l.custom_minimum_size = Vector2(170, 0)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(l)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for c in chips:
		flow.add_child(UI.chip(str(c[0]), c[2], c[1], c[3], 15))
	hb.add_child(flow)
	_rows.append({"text": text, "acts": chips.filter(func(c): return c[1] != null).map(func(c): return c[1])})
	form.add_row(row)


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
	_rows.append({"text": text, "acts": chips.map(func(c): return c[1])})
	form.add_row(row)


func _on_form_row(i: int, at: Vector2) -> void:
	if dialog != null or sheet != null or i < 0 or i >= form.rows().size():
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
	var try_only := str(what[0]).begins_with("try")
	match what[0]:
		"name":
			_ask_text("Name", str(ch.get("name", "")), func(v):
				ch["name"] = v.strip_edges()
				_changed())
			return
		"notes":
			_ask_text("Notes", str(ch.get("notes", "")), func(v):
				ch["notes"] = v.strip_edges()
				_changed())
			return
		"dist":
			ch["district"] = what[1]
		"body":
			ch["bodyPlan"] = what[1]
		"sub":
			var subs: Array = ch.get("subtypes", [])
			if subs.has(what[1]):
				if subs.size() > 1:
					subs.erase(what[1])
			elif subs.size() >= 2:
				say("A chassis has at most two subtypes. Untick one first.", true)
				return
			else:
				subs.append(what[1])
			ch["subtypes"] = SUBTYPES.filter(func(s): return subs.has(s))
		"step":
			_step(str(what[1]), int(what[2]), int(what[3]), int(what[4]))
		"kw":
			var al: Array = ch.get("allowed", [])
			if al.has(what[1]):
				al.erase(what[1])
			else:
				al.append(what[1])
			ch["allowed"] = al
		"all", "none":
			var ks: Array = chips().filter(func(k): return k["cat"] == what[1]).map(func(k): return k["name"])
			var al: Array = (ch.get("allowed", []) as Array).filter(func(k): return not ks.has(k))
			if what[0] == "all":
				al.append_array(ks)
			ch["allowed"] = al
		"try_role":
			tries[int(what[1])]["role"] = what[2]
		"try_del":
			tries.remove_at(int(what[1]))
		"try_add":
			tries.append({"role": "Ranged", "text": ""})
		"try_sdel":
			var t: Dictionary = tries[int(what[1])]
			var sents := Keywords.sentences(str(t["text"]))
			sents.remove_at(int(what[2]))
			t["text"] = " ".join(sents)
		"try_build":
			open_builder(int(what[1]))
			return
		"try_type":
			var i := int(what[1])
			_ask_text("Effect, in keywords: [[target enemy]] takes [[damage 2]].", str(tries[i]["text"]), func(v):
				tries[i]["text"] = v.strip_edges()
				refresh())
			return
	if try_only:
		refresh()
	else:
		_changed()


func _changed() -> void:
	dirty = true
	refresh()


func _step(what: String, by: int, lo: int, hi: int) -> void:
	if what.begins_with("stat:"):
		var k := what.substr(5)
		ch["stats"][k] = clampi(int(ch["stats"].get(k, 0)) + by, lo, hi)
	elif what.begins_with("ae:"):
		var k := what.substr(3)
		var ae: Dictionary = ch.get("aether", {}) if ch.get("aether") is Dictionary else {}
		ae[k] = clampi(int(ae.get(k, 0)) + by, lo, hi)
		ch["aether"] = ae
	elif what == "cost":
		ch["cost"] = {"troop": clampi(int((ch.get("cost", {}) as Dictionary).get("troop", 0)) + by, lo, hi)}
	else:
		ch[what] = clampi(int(ch.get(what, 0)) + by, lo, hi)


## The keyword builder on a tried ability, offering only what the chassis allows.
func open_builder(i: int) -> void:
	var t: Dictionary = tries[i]
	var passive: bool = t["role"] == "Passive"
	sheet = BuilderSheet.new()
	add_child(sheet)
	sheet.done.connect(func(text):
		_drop_sheet()
		t["text"] = (str(t["text"]).strip_edges() + " " + text).strip_edges()
		refresh())
	sheet.cancelled.connect(func(): _drop_sheet())
	sheet.open({"kind": "passive" if passive else "action", "cardType": "troop", "role": "" if passive else str(t["role"]).to_lower(),
		"allowed": (ch.get("allowed", []) as Array).duplicate(), "others": str(t["text"]), "cards": roster.troops().map(func(c): return str(c["name"])) if roster != null else []})


func _drop_sheet() -> void:
	if sheet != null:
		Motion.pop_out(sheet, sheet.get_meta("box", null))
		sheet = null


# ---------------------------------------------------------------- keeping it
func save_chassis() -> void:
	var probs := problems()
	if not probs.is_empty():
		say(" ".join(probs), true)
		return
	var was_new := id == ""
	id = Sandbox.put_chassis(ch, id)
	dirty = false
	_commit("%s %s." % [str(ch["name"]), "made: it is yours in the Workshop" if was_new else "saved"])
	copy_btn.visible = true
	delete_btn.visible = true
	reset_btn.visible = not Sandbox.chassis_own(id)
	refresh()


func copy_chassis() -> void:
	var c := ch.duplicate(true)
	c["name"] = str(ch.get("name", "Chassis")) + " copy"
	c.erase("shipped")
	c.erase("test")
	edit(c, true)
	say("A copy: save it to keep it.")


func ask_delete() -> void:
	if id == "":
		return
	var own := Sandbox.chassis_own(id)
	_ask("Delete %s?" % str(ch.get("name", "")), ("It is gone for good." if own else "It leaves the game: no drop, Exchange or Workshop has it. Deleted, in the list, can bring it back.") + " Designs built on it can't be made until it is back.",
		["Keep it", "Delete"], func(k):
			if k == 1:
				var nm := str(ch.get("name", ""))
				Sandbox.delete_chassis(id)
				_commit("%s deleted." % nm)
				show_list())


func ask_reset() -> void:
	if id == "" or Sandbox.chassis_own(id):
		return
	_ask("Reset %s?" % str(ch.get("name", "")), "It goes back to how the export has it, and your changes to it are gone.", ["Keep mine", "Reset"], func(k):
		if k == 1:
			Sandbox.reset_chassis(id)
			_commit("Back as the export has it.")
			var orig := all_chassis().filter(func(c): return str(c.get("id", "")) == id)
			if not orig.is_empty():
				edit(orig[0])
			else:
				show_list())


func export_all() -> void:
	var f := Sandbox.export_game(roster)
	if f == "":
		say("It couldn't be written.", true)
	else:
		say("Written to %s. In the Companion, import it in the Card Forge: its chassis join the Chassis library." % f)


func _commit(msg: String) -> void:
	Sandbox.data.erase("draft")
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
