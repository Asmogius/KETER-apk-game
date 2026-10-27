## The Workshop, opened from the dock: your designs, the blueprints you own
## (and research), and the designs your export brings from the Companion.
##
## Designs: each with its chassis, its power against the chassis's cap,
## whether it fits, what a copy costs and how many your stockpile could pay
## for. New design starts one on a chassis you have found.
## Blueprints: what you own, a level at a time; levels 2 and 3 can be
## researched with shards while no Strike Team is out. The testing switch
## unlocks everything while it is on.
## From your export: the Companion's designs, to copy in as yours.
class_name WorkshopScreen
extends Control

signal closed

var campaign: Campaign = null
var roster: Roster = null
var tab := "designs"
var picking := false            # choosing a chassis for a new design
var note := ""
var note_bad := false
var dialog: Dialog = null

var title: Label
var stock_label: Label
var hint: Label
var tabs := {}
var list: TouchList
var note_label: Label
var new_btn: Button
var back_btn: Button
var editor: DesignEditor
var _rows: Array = []


func _init() -> void:
	var col := UI.page(self)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	col.add_child(head)
	title = UI.label("Workshop", 30, UI.CYAN)
	head.add_child(title)
	stock_label = UI.label("", 17, Color("#efdd91"))
	stock_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stock_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stock_label.clip_text = true
	head.add_child(stock_label)
	for k in [["designs", "Designs"], ["blueprints", "Blueprints"], ["export", "From your export"]]:
		var key: String = k[0]
		var b := UI.button(k[1], func(): show_tab(key), 150)
		b.toggle_mode = true
		head.add_child(b)
		tabs[key] = b
	hint = UI.label("", 17, UI.PALE, true)
	col.add_child(hint)
	list = TouchList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.row_tapped.connect(_on_row)
	col.add_child(list)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 14)
	col.add_child(foot)
	back_btn = UI.button("Dock", func(): _back())
	foot.add_child(back_btn)
	note_label = UI.label("", 17, UI.GOLD, true)
	note_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	foot.add_child(note_label)
	new_btn = UI.button("New design", func(): pick_chassis(), 200)
	foot.add_child(new_btn)
	editor = DesignEditor.new()
	editor.visible = false
	editor.closed.connect(func():
		editor.visible = false
		show_tab(tab))
	add_child(editor)


func open(c: Campaign, r: Roster) -> void:
	campaign = c
	roster = r
	picking = false
	note = ""
	editor.visible = false
	_close_dialog()
	show_tab("designs")


func ws() -> Workshop:
	return campaign.workshop


func _back() -> void:
	if picking:
		picking = false
		show_tab(tab)
		return
	closed.emit()


func _close_dialog() -> void:
	if dialog != null:
		Motion.pop_out(dialog, dialog.get_meta("box", null))
		dialog = null


func _say(text: String, bad := false) -> void:
	note = text
	note_bad = bad
	note_label.text = text
	note_label.add_theme_color_override("font_color", UI.SOFT_RED if bad else UI.GOLD)


# ---------------------------------------------------------------- drawing
func show_tab(k: String) -> void:
	tab = k
	for key in tabs:
		tabs[key].button_pressed = key == k
	var st := Loot.norm(campaign.deploy.stock)
	stock_label.text = "Troop parts: %s · %d shards" % [Workshop.cost_text(st["parts"]["troop"]).replace("nothing", "none"), st["shards"]]
	new_btn.visible = k == "designs" and not picking
	back_btn.text = "Back" if picking else "Dock"
	note_label.text = note
	var keep := list.scroll
	list.clear()
	_rows = []
	if picking:
		_chassis_rows()
	elif k == "designs":
		_design_rows()
	elif k == "blueprints":
		_blueprint_rows()
	else:
		_export_rows()
	list.scroll_by(keep)


func row_texts() -> Array:
	return _rows.map(func(r): return r["text"])


func _add(row: Control, what: Dictionary) -> void:
	what["row"] = row
	_rows.append(what)
	list.add_row(row)


func _panel(text: String, subs: Array, band: Color, tag := "", tag_colour := UI.GOLD) -> PanelContainer:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 64)
	var sb := UI.box(UI.PANEL, UI.LINE, 1, 6, 14)
	sb.border_width_left = 6
	sb.border_color = band
	row.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	row.add_child(h)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.label(text, 20, UI.TEXT))
	for s in subs:
		var l := UI.label(str(s[0]), 15, s[1] if s.size() > 1 else UI.DIM, true)
		v.add_child(l)
	if tag != "":
		var t := UI.label(tag, 16, tag_colour)
		t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(t)
	return row


func _head_row(text: String, sub := "") -> void:
	var v := VBoxContainer.new()
	v.add_child(UI.label(text, 20, UI.CYAN))
	if sub != "":
		v.add_child(UI.label(sub, 15, UI.DIM, true))
	_add(v, {"text": text})


func _design_rows() -> void:
	var out := campaign.deploy.active()
	hint.text = "Design Troops on the chassis you have found, with the blueprints you own. A design is a Troop card: it goes into a Strike Team's Deck. A design that costs only Common parts goes out free; any other is paid for, copy by copy, as a team leaves. Open one to raise it to Mk II or Mk III with Troop parts." + (" The designs out on the deployment are locked until it is home." if out else "")
	for d in ws().list():
		var ch = ws().chassis_of(d)
		var dd := Workshop.district_of(ch)
		var chk := ws().check(d)
		var cost := ws().cost(d)
		var n := ws().affordable(d, campaign.deploy.stock)
		# (0.37) a design that costs only Common parts goes out free; and its Mark
		var free := Deployment.common_cost(cost["parts"])
		var subs := [["%s%s · power %d of %s · %s" % [(Workshop.MK_NAME[Workshop.mk_of(d) - 1] + " · ") if Workshop.mk_of(d) > 1 else "", str(ch.get("name")) if ch != null else "(its chassis is missing)", cost["power"], Scoring.text(chk["cap"]), "fits" if chk["ok"] else "doesn't fit"], UI.PALE if chk["ok"] else UI.SOFT_RED],
			["Free to take out: it costs only Common parts" if free else "One copy: %s Troop parts · you could pay for %d" % [Workshop.cost_text(cost["parts"]), n], UI.GREEN if free else UI.PALE]]
		var tag := ""
		if Rules.truthy(d.get("starter")):
			subs.append(["Starter · %d free copies every deployment · copy it to make your own" % campaign.deploy.starter_free(), UI.GOLD])
			tag = "Starter"
		if campaign.deploy.locked_design(d.get("id")):
			tag = "Out"
		_add(_panel(str(d.get("name", "")), subs, Color(dd["color"]), tag), {"text": str(d.get("name", "")), "design": d["id"]})
	if ws().list().size() == 1:
		_add(UI.label("Only the starter so far. New design starts one on a chassis you have found.", 16, UI.DIM, true), {"text": "only the starter"})


func pick_chassis() -> void:
	picking = true
	show_tab("designs")


func _chassis_rows() -> void:
	hint.text = "Choose a chassis. It sets the design's stats, its power cap, how many abilities it holds and which keywords it may use."
	new_btn.visible = false
	var rest := 0
	for ch in ws().chassis_list():
		if not ws().progress.has_chassis(ch.get("id")):
			rest += 1
			continue
		var dd := Workshop.district_of(ch)
		var st: Dictionary = ch.get("stats", {}) if ch.get("stats") is Dictionary else {}
		_add(_panel(str(ch.get("name", "")), [["%s · %s · power %s · %s abilit%s" % [dd["name"], " + ".join(ch.get("subtypes", [])), Scoring.text(ch.get("powerCap")), Scoring.text(ch.get("abilityCap")), "y" if Scoring.num(ch.get("abilityCap")) == 1.0 else "ies"], UI.PALE],
			["HP %s · AC %s · MS %s · NRG %s · INT %s · DMG %s" % [Scoring.text(st.get("hp")), Scoring.text(st.get("ac")), Scoring.text(st.get("move")), Scoring.text(st.get("nrg")), Scoring.text(st.get("int")), Scoring.text(st.get("dmg"))]]],
			Color(dd["color"])), {"text": str(ch.get("name", "")), "chassis": ch.get("id")})
	if rest > 0:
		_add(UI.label("%d more chassis are still to be found." % rest, 16, UI.DIM), {"text": "more to find"})


func _blueprint_rows() -> void:
	var out := campaign.deploy.active()
	var p := ws().progress
	var st := Loot.norm(campaign.deploy.stock)
	hint.text = "Target words, damage, heal and turns are yours from the start. Every other keyword is a blueprint: its first level is found, and levels 2 and 3 are found or researched here with shards." + (" Research waits while a Strike Team is out." if out else "")
	var on := p.unlock_all()
	_add(_panel("Testing: everything unlocked · " + ("on" if on else "off"), [["While it is on, every chassis and blueprint can be used, and nothing new drops. Switched off, a design that uses what you haven't found can't deploy.", UI.DIM]],
		UI.GOLD if on else UI.LINE, "Tap to turn " + ("off" if on else "on"), UI.CYAN), {"text": "testing", "testing": true})
	var owned := p.catalog().filter(func(b): return p.state["bp"].has(b["name"]) and int(Rules.num(p.state["bp"][b["name"]], 0)) >= 1)
	if owned.is_empty():
		_add(UI.label("No blueprints found yet. Enemies, Loot Tiles, Locked Chests, Caches and POIs can all leave one.", 16, UI.DIM, true), {"text": "none found"})
	for cat in Keywords.CATEGORIES:
		var mine := owned.filter(func(b): return b["cat"] == cat["k"])
		if mine.is_empty():
			continue
		_head_row(str(cat["label"]))
		for b in mine:
			var have := int(Rules.num(p.state["bp"][b["name"]], 0))
			var next := have + 1
			var sub := ("level %d of %d · up to %s" % [have, b["levels"], " · ".join(b["caps"].map(func(x): return str(x)))]) if b["levels"] > 1 else "owned"
			var tag := ""
			if next <= b["levels"]:
				var price := p.research_price(b["name"], next)
				tag = ("Research level %d · %d shards" % [next, price]) if not out else "At the dock"
				_add(_panel(str(b["name"]), [[sub, UI.PALE]], Color(cat["colour"]), tag, UI.CYAN if (st["shards"] >= price and not out) else UI.DIM), {"text": str(b["name"]), "research": b["name"]})
			else:
				_add(_panel(str(b["name"]), [[sub, UI.PALE]], Color(cat["colour"]), "Highest level" if b["levels"] > 1 else "", UI.DIM), {"text": str(b["name"])})


func _export_rows() -> void:
	hint.text = "Designs you made in the Companion's Workshop, as your export carries them. Copy one in and it becomes yours, held to the same checks as any: its chassis and blueprints must be yours before it can deploy."
	var any := false
	for c in roster.from_export:
		# (pre-built Troops are bought at the dock's Exchange, by the copy: 0.10)
		if c.get("_src") != "design":
			continue
		any = true
		var mine = ws().by_name(str(c.get("name", "")))
		var tag := "Copied" if mine != null else "Copy in"
		_add(_panel(str(c.get("name", "")), [["%s · %s" % [str(c.get("chassisName", c.get("chassis", ""))), "a Companion design"], UI.PALE]],
			UI.LINE, tag, UI.DIM if mine != null else UI.CYAN), {"text": str(c.get("name", "")), "card": c})
	if not any:
		_add(UI.label("Your export has no designs of the Companion's.", 16, UI.DIM), {"text": "none"})


# ---------------------------------------------------------------- taps
func _on_row(i: int, _at: Vector2) -> void:
	if i < 0 or i >= _rows.size() or dialog != null or editor.visible:
		return
	tap_row(_rows[i])


func tap_row(r: Dictionary) -> void:
	if r.has("design"):
		edit(ws().get_design(r["design"]))
	elif r.has("chassis"):
		picking = false
		var d := ws().blank(str(r["chassis"]))
		d["name"] = _free_name("New design")
		var id := ws().put(d)
		campaign.designs_changed()
		campaign.save()
		edit(ws().get_design(id))
	elif r.has("testing"):
		ws().progress.set_unlock_all(not ws().progress.unlock_all())
		campaign.designs_changed()
		campaign.save()
		_say("Testing is on: everything is unlocked, and nothing new drops." if ws().progress.unlock_all() else "Testing is off.")
		show_tab("blueprints")
	elif r.has("research"):
		ask_research(str(r["research"]))
	elif r.has("card"):
		ask_copy_in(r["card"])


func edit(d) -> void:
	if not (d is Dictionary):
		return
	editor.visible = true
	editor.open(campaign, roster, d)


func _free_name(want: String) -> String:
	var nm := want
	var n := 2
	while ws().by_name(nm) != null or roster.from_export.any(func(c): return str(c.get("name")) == nm and c.get("_src") != "design"):
		nm = "%s %d" % [want, n]
		n += 1
	return nm


func ask_research(kw: String) -> void:
	var p := ws().progress
	var have := int(Rules.num(p.state["bp"].get(kw), 0))
	var price := p.research_price(kw, have + 1)
	var st := Loot.norm(campaign.deploy.stock)
	var can: bool = st["shards"] >= price and not campaign.deploy.active()
	var text := "It costs %d shards; the stockpile holds %d." % [price, st["shards"]]
	if p.blueprint_of(kw)["caps"] != null:
		text += " Level %d allows numbers up to %s." % [have + 1, str(p.blueprint_of(kw)["caps"][have])]
	if campaign.deploy.active():
		text += " Research waits until the Strike Team is home."
	elif not can:
		text += " That isn't enough yet."
	dialog = Dialog.new("Research %s level %d?" % [kw, have + 1], text, ["Research", "Not now"] if can else ["OK"])
	add_child(dialog)
	dialog.chosen.connect(func(k):
		_close_dialog()
		if k == 0 and can:
			research(kw))


func research(kw: String) -> void:
	var r := ws().progress.research(kw, campaign.deploy.stock, campaign.deploy.active())
	if r["ok"]:
		campaign.deploy.stock = Loot.norm(campaign.deploy.stock)
		campaign.designs_changed()
		campaign.save()
		_say("Researched %s level %d for %d shards." % [kw, r["level"], r["price"]])
	else:
		_say(str(r["why"]) + ".", true)
	show_tab("blueprints")


func ask_copy_in(card: Dictionary) -> void:
	var mine = ws().by_name(str(card.get("name", "")))
	var text := "It becomes a design of yours, on %s. Its chassis and blueprints must be yours before it can deploy." % str(card.get("chassisName", "its chassis"))
	if mine != null:
		text = "You already have a design called %s. Another copy comes in under a new name." % str(card.get("name", ""))
	dialog = Dialog.new("Copy %s in?" % str(card.get("name", "")), text, ["Copy it in", "Not now"])
	add_child(dialog)
	dialog.chosen.connect(func(k):
		_close_dialog()
		if k == 0:
			copy_in(card))


## A design out of the export, made yours. Returns its id.
func copy_in(card: Dictionary) -> String:
	var d := Workshop.from_card(card)
	var look = ws().skins.look_wearing(card.get("pixelArt"), card.get("pixelToken")) if ws().skins != null else null
	if look != null:
		d["skin"] = look
	if ws().by_name(str(d["name"])) != null:
		d["name"] = _free_name(str(d["name"]))
	var id := ws().put(d)
	campaign.designs_changed()
	campaign.save()
	edit(ws().get_design(id))
	return id
