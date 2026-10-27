## One design, being built: its chassis, its abilities, its look, and on the
## right whether it fits and what a copy costs, all as it changes. (0.15) The
## chassis is a banner: its body standing, its numbers as icons. Each Action's
## numbers sit under their icons, and what it does is set large. On the right,
## always in view, the design as its card and its token on a pedestal; its
## power as a bar; what a copy costs as parts.
##
## An ability is an Action or a Passive. An Action has a role (one of its
## chassis's subtypes) and an Energy cost; an attack also has its range,
## to-hit and AP, each within the chassis's maximum. Its text is built a
## sentence at a time with the keyword builder; each sentence can be changed
## or taken out again. Everything is saved as it is changed.
##
## The starter, and a design whose copies are out on a deployment, are shown
## but not changed: Copy makes one that can be.
class_name DesignEditor
extends Control

signal closed                  # back to the list
signal changed                 # the design was saved

var campaign: Campaign = null
var roster: Roster = null
var d := {}                    # the design (a copy; saved through the Workshop)
var locked := false
var sheet: BuilderSheet = null
var namer: NameDialog = null
var dialog: Dialog = null
var note := ""

var name_label: Label
var lock_label: Label
var rename_btn: Button
var copy_btn: Button
var mk_btn: Button                     # (0.37) raise it a Mark
var delete_btn: Button
var list: TouchList
var result: VBoxContainer
var preview: CardTile = null           # (0.15) the design as its card, on the right
var _rows: Array = []


## (0.15) A small plate for a token to stand on.
class Pedestal extends Node2D:
	func _draw() -> void:
		var pts := PackedVector2Array()
		for i in 33:
			var a := TAU * i / 32.0
			pts.append(Vector2(cos(a) * 40.0, sin(a) * 12.0))
		draw_colored_polygon(pts, Color("#282c3c"))
		var rim := PackedVector2Array()
		for i in 33:
			var a := TAU * i / 32.0
			rim.append(Vector2(cos(a) * 40.0, sin(a) * 12.0 - 3.0))
		draw_colored_polygon(rim, Color("#485262"))
		draw_polyline(rim, Color("#73efe8"), 2.0)


func _init() -> void:
	var col := UI.page(self)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	col.add_child(top)
	top.add_child(UI.button("Workshop", func(): close(), 150))
	name_label = UI.label("", 28, UI.CYAN)
	name_label.clip_text = true
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(name_label)
	rename_btn = UI.button("Rename", func(): ask_name(), 130)
	top.add_child(rename_btn)
	copy_btn = UI.button("Copy", func(): copy(), 110)
	top.add_child(copy_btn)
	mk_btn = UI.button("Mk II", func(): ask_upgrade(), 130)
	top.add_child(mk_btn)
	delete_btn = UI.button("Delete", func(): ask_delete(), 110)
	top.add_child(delete_btn)
	lock_label = UI.label("", 17, UI.GOLD, true)
	col.add_child(lock_label)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	list = TouchList.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.row_tapped.connect(_on_row)
	body.add_child(list)
	var side := PanelContainer.new()
	side.custom_minimum_size = Vector2(400, 0)
	side.add_theme_stylebox_override("panel", UI.box(UI.PANEL, UI.LINE, 1, 8, 16))
	body.add_child(side)
	result = VBoxContainer.new()
	result.add_theme_constant_override("separation", 8)
	side.add_child(result)


func open(c: Campaign, r: Roster, design: Dictionary) -> void:
	campaign = c
	roster = r
	d = design.duplicate(true)
	note = ""
	_close_overlays()
	refresh()


func ws() -> Workshop:
	return campaign.workshop


func chassis() -> Variant:
	return ws().chassis_of(d)


func close() -> void:
	_close_overlays()
	closed.emit()


func _close_overlays() -> void:
	for o in [sheet, namer, dialog]:
		if o != null:
			o.queue_free()
	sheet = null
	namer = null
	dialog = null


# ---------------------------------------------------------------- saving
func save() -> void:
	if locked:
		return
	var id := ws().put(d)
	if id != "":
		d["id"] = id
	campaign.designs_changed()
	campaign.save()
	changed.emit()
	refresh()


# ---------------------------------------------------------------- drawing
func refresh() -> void:
	locked = Rules.truthy(d.get("id")) and ws().locked(d["id"])
	name_label.text = str(d.get("name", "Untitled design"))
	rename_btn.visible = not locked
	delete_btn.visible = not locked
	# (0.37) a saved design can be raised a Mark, the starter too, while the team is home
	var mk := Workshop.mk_of(ws().get_design(d.get("id")) if Rules.truthy(d.get("id")) else d)
	mk_btn.visible = Rules.truthy(d.get("id")) and ws().get_design(d["id"]) != null
	mk_btn.text = Workshop.MK_NAME[mk] if mk < 3 else "Mk III"
	mk_btn.disabled = mk >= 3 or campaign.deploy.active()
	if Rules.truthy(d.get("starter")):
		lock_label.text = "The built-in starter: every deployment brings a few free copies of it, so it can't be changed; it can be raised a Mark. Copy it to make your own." + ((" " + note) if note != "" else "")
	elif locked:
		lock_label.text = "Out on a deployment: it can be changed again once the Strike Team is home. Copy it to change a copy."
	else:
		lock_label.text = note
	lock_label.add_theme_color_override("font_color", UI.GOLD if (locked or note == "") else UI.SOFT_RED)
	var keep := list.scroll
	list.clear()
	_rows = []
	var ch = chassis()
	if ch == null:
		_add(UI.label("This design's chassis is missing from the export.", 18, UI.SOFT_RED, true))
	else:
		_add(_chassis_row(ch))
		var abilities: Array = d.get("abilities", [])
		for i in abilities.size():
			_add(_ability_row(i, abilities[i], ch))
		if not locked:
			var adds := HBoxContainer.new()
			adds.add_theme_constant_override("separation", 12)
			adds.add_child(UI.chip("+ Add an Action", UI.CYAN, ["add", "action"]))
			adds.add_child(UI.chip("+ Add a Passive", UI.CYAN, ["add", "passive"]))
			_add(adds)
		_look_rows()
	list.scroll_by(keep)
	_result()


func _add(c: Control) -> void:
	_rows.append(c)
	list.add_row(c)


func _chassis_row(ch: Dictionary) -> Control:
	var dd := Workshop.district_of(ch)
	var st: Dictionary = ch.get("stats", {}) if ch.get("stats") is Dictionary else {}
	var row := PanelContainer.new()
	var sb := UI.box(UI.PANEL, Color(dd["color"]), 1, 6, 14)
	sb.border_width_left = 6
	row.add_theme_stylebox_override("panel", sb)
	# (0.15) a banner: the body standing, the chassis's name, its numbers as icons
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	row.add_child(h)
	var body := TextureRect.new()
	body.texture = Art.body_token(str(ch.get("bodyPlan", "")))
	body.custom_minimum_size = Vector2(96, 96)
	body.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	body.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.visible = body.texture != null
	h.add_child(body)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.label(str(ch.get("name", "")), 20, UI.TEXT))
	v.add_child(UI.label("%s · %s · %s" % [dd["name"], " + ".join(ch.get("subtypes", [])), str(ch.get("bodyPlan", ""))], 15, UI.DIM))
	var nums := UI.stats_row([["hp", Scoring.text(st.get("hp")), UI.TEXT], ["ac", Scoring.text(st.get("ac")), UI.TEXT], ["ms", Scoring.text(st.get("move")), UI.TEXT], ["nrg", Scoring.text(st.get("nrg")), UI.TEXT]], 18)
	nums.add_child(UI.label("INT %s · DMG %s" % [Scoring.text(st.get("int")), Scoring.text(st.get("dmg"))], 18, UI.PALE))
	v.add_child(nums)
	var ae: Dictionary = ch.get("aether", {}) if ch.get("aether") is Dictionary else {}
	var aff := Scoring.num(ae.get("affinity"), 0.0)
	v.add_child(UI.label("Attacks up to range %s and AP %s, to-hit %s at best · deploys for %s Aether%s" % [Scoring.text(Workshop.max_of(ch, "range")), Scoring.text(Workshop.max_of(ch, "ap")), Scoring.text(Workshop.best_hit(ch)),
		Scoring.text(Scoring.num(ae.get("generic"), 1.0)), (" + %s of its District" % Scoring.text(aff)) if aff > 0 else ""], 15, UI.PALE))
	v.add_child(UI.label("Power cap %s · %s abilit%s · you can use %d of its %d keywords" % [Scoring.text(ch.get("powerCap")), Scoring.text(ch.get("abilityCap")), "y" if Scoring.num(ch.get("abilityCap")) == 1.0 else "ies",
		ws().allowed_for(ch).size(), (ch.get("allowed", []) as Array).size()], 15, UI.PALE))
	return row


## (0.15) Each number of an Action under its icon: Energy, Range, To-Hit, AP.
const STEP_ICON := {"Energy": "nrg", "Range": "ms", "To-Hit": "marked", "AP": "sundered"}


func _stepper(label: String, value, most: String, act_base: Array) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var ic: String = STEP_ICON.get(label, "")
	if ic != "":
		var tr := UI.icon(ic, 32)
		if ic == "marked" or ic == "sundered":
			tr.texture = Art.status_icon(ic)
		h.add_child(tr)
	var l := UI.label(label, 15, UI.DIM)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	if not locked:
		h.add_child(UI.chip("−", UI.TEXT, act_base + [-1], false, 18))
	var v := UI.label(Scoring.text(value), 20, UI.TEXT)
	v.custom_minimum_size = Vector2(30, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(v)
	if not locked:
		h.add_child(UI.chip("+", UI.TEXT, act_base + [1], false, 18))
	var m := UI.label(most, 13, UI.DIM)
	m.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(m)
	return h


func _ability_row(i: int, a: Dictionary, ch: Dictionary) -> Control:
	var passive: bool = a.get("kind") == "passive"
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", UI.box(Color("#181c19"), UI.LINE, 1, 6, 14))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	row.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	v.add_child(top)
	var nm := str(a.get("name", "")) if Rules.truthy(a.get("name")) else ("Passive" if passive else "Action")
	var name_chip := UI.chip(nm, UI.TEXT, null if locked else ["ability name", i], false, 19)
	top.add_child(name_chip)
	if passive:
		top.add_child(UI.chip("Passive", UI.DIM, null, false, 15))
	else:
		var subs: Array = ch.get("subtypes", []) if ch.get("subtypes") is Array else []
		top.add_child(UI.chip(str(a.get("role", "")) + ("  ›" if subs.size() > 1 and not locked else ""), UI.GOLD, ["role", i] if subs.size() > 1 and not locked else null, false, 16))
	var pw := UI.label("power %d%s" % [ws().ability_power(a), (" · %s damage" % Scoring.text(Scoring.num(ch.get("stats", {}).get("dmg"), 0.0))) if Workshop.is_attack(a) else ""], 15, UI.CYAN)
	pw.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(pw)
	if not locked:
		top.add_child(UI.chip("Remove", UI.SOFT_RED, ["remove", i], false, 15))
	if not passive:
		var nums := HFlowContainer.new()
		nums.add_theme_constant_override("h_separation", 22)
		var nrg := Scoring.num(ch.get("stats", {}).get("nrg") if ch.get("stats") is Dictionary else null, 0.0)
		nums.add_child(_stepper("Energy", a.get("energy", 0), "0–" + Scoring.text(nrg), ["num", i, "energy"]))
		for k in Workshop.fields_for(a):
			# 0.13: a to-hit goes from the chassis's best (lowest) up to 20
			nums.add_child(_stepper({"range": "Range", "hit": "To-Hit", "ap": "AP"}[k], a.get(k, 0), ("best " + Scoring.text(Workshop.best_hit(ch))) if k == "hit" else ("max " + Scoring.text(Workshop.max_of(ch, k))), ["num", i, k]))
		# (0.12) what it fires, on the screen: a tap moves on to the next
		if Workshop.fields_for(a).has("range"):
			var pj := HBoxContainer.new()
			pj.add_theme_constant_override("separation", 6)
			var pl := UI.label("Fires", 15, UI.DIM)
			pl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			pj.add_child(pl)
			pj.add_child(UI.chip(Workshop.projectile_of(a).capitalize() + ("  ›" if not locked else ""), UI.CYAN, null if locked else ["projectile", i], false, 16))
			nums.add_child(pj)
		v.add_child(nums)
	var sents := Keywords.sentences(str(a.get("text", "")))
	if sents.is_empty():
		v.add_child(UI.label("It does nothing yet: add an effect.", 16, UI.DIM))
	for j in sents.size():
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		var t := RichTextLabel.new()
		t.bbcode_enabled = true
		t.fit_content = true
		t.scroll_active = false
		t.add_theme_font_override("normal_font", Look.font())
		t.add_theme_font_size_override("normal_font_size", Look.TITLE)      # (0.15) what it does, large
		t.text = BuilderSheet.coloured(sents[j])
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(t)
		if not locked:
			h.add_child(UI.chip("Change", UI.CYAN, ["change", i, j], false, 15))
			h.add_child(UI.chip("×", UI.SOFT_RED, ["cut", i, j], false, 15))
		v.add_child(h)
	if not locked:
		var add := HBoxContainer.new()
		add.add_child(UI.chip("+ Add an effect", UI.CYAN, ["build", i], false, 16))
		v.add_child(add)
	return row


func _look_rows() -> void:
	var sk: Skins = ws().skins
	if sk == null:
		return
	var opts := sk.options_for(d)
	var look = sk.look_of(d)
	_add(UI.label("LOOK · " + sk.body_plan_of(d).to_upper(), 14, UI.DIM))
	if opts.is_empty():
		_add(UI.label("No %s skins in your export yet. They are drawn in the Companion's Pixel Studio." % sk.body_plan_of(d), 16, UI.DIM, true))
		return
	_add(UI.label("Its card art and board token, from the %s skins. Those that suit its roles come first; any can be chosen." % sk.body_plan_of(d), 15, UI.DIM, true))
	for o in opts:
		var k: Dictionary = o["skin"]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var l := UI.label(str(k.get("name", "")) + ("  · suits its roles" if o["fits"] else ""), 17, UI.TEXT)
		l.custom_minimum_size = Vector2(260, 0)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(l)
		for vr in k["variants"]:
			var on: bool = look is Dictionary and look["skin"] == k["id"] and look["variant"] == vr.get("id")
			var chip := UI.chip(str(vr.get("name", "")), UI.CYAN if on else UI.PALE, null if locked else ["look", k["id"], vr.get("id")], on, 16)
			var tex: Texture2D = campaign.roster_texture(vr.get("token")) if campaign != null else null
			if tex != null:
				var hb := HBoxContainer.new()
				hb.add_theme_constant_override("separation", 8)
				var tr := TextureRect.new()
				tr.texture = tex
				tr.custom_minimum_size = Vector2(32, 32)
				tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				var lbl: Node = chip.get_child(0)
				chip.remove_child(lbl)
				hb.add_child(tr)
				hb.add_child(lbl)
				chip.add_child(hb)
			row.add_child(chip)
		_add(row)


## Power, the fit check and what a copy costs, on the right.
func _result() -> void:
	for c in result.get_children():
		result.remove_child(c)
		c.queue_free()
	if chassis() == null:
		return
	var chk := ws().check(d)
	var cost := ws().cost(d)
	# (0.15) the design as its card, and its token standing on a pedestal: always in view
	var card := ws().to_card(d)
	var look := HBoxContainer.new()
	look.alignment = BoxContainer.ALIGNMENT_CENTER
	look.add_theme_constant_override("separation", 16)
	result.add_child(look)
	var stand := Control.new()
	stand.custom_minimum_size = Vector2(112, 210)
	look.add_child(stand)
	var plate := Pedestal.new()
	plate.position = Vector2(56, 176)
	stand.add_child(plate)
	var tok: Texture2D = roster.token_for(card).get("texture") if roster != null else null
	if tok == null:
		tok = Art.body_token(str(chassis().get("bodyPlan", "")))
	if tok != null:
		var tr := TextureRect.new()
		tr.texture = tok
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.size = Vector2(96, 96)
		tr.position = Vector2(8, 84)
		stand.add_child(tr)
	preview = CardTile.new(card, roster.art_for(card) if roster != null else null)
	look.add_child(preview)
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 12)
	var bg := ColorRect.new()
	bg.color = Color("#282c3c")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.add_child(bg)
	var fill := ColorRect.new()
	var frac := clampf(float(chk["power"]) / maxf(1.0, float(chk["cap"])), 0.0, 1.0)
	fill.color = UI.RED if chk["power"] > chk["cap"] else UI.CYAN
	fill.anchor_right = frac
	fill.anchor_bottom = 1.0
	bar.add_child(fill)
	result.add_child(bar)
	result.add_child(UI.label("Power %d / %s" % [chk["power"], Scoring.text(chk["cap"])], 20, UI.TEXT))
	result.add_child(UI.label("Abilities %d / %s" % [chk["abilities"], Scoring.text(chk["abilityCap"])], 17, UI.PALE))
	if chk["ok"]:
		result.add_child(UI.label("Fits, and you own everything it uses.", 17, UI.GREEN, true))
	else:
		result.add_child(UI.label("• " + "\n• ".join(chk["reasons"].map(func(r): return str(r).left(1).to_upper() + str(r).substr(1) + ".")), 16, UI.SOFT_RED, true))
	result.add_child(UI.label("ONE COPY COSTS", 14, UI.DIM))
	for l in cost["lines"]:
		result.add_child(UI.label("%s: %s" % [l["label"], Workshop.cost_text(l["parts"])], 15, UI.PALE, true))
	result.add_child(UI.label("In all: %s Troop parts" % Workshop.cost_text(cost["parts"]), 17, UI.GOLD, true))
	# (0.15) and as parts, each rarity's count beside the Troop parts' icon
	var parts := []
	for r in 6:
		if int(cost["parts"][r]) > 0:
			parts.append(["part_troop", "%d %s" % [int(cost["parts"][r]), Loot.RARITIES[r]["label"]], DockScreen.rarity_colour(r)])
	if not parts.is_empty():
		result.add_child(UI.stats_row(parts, 18))
	var n := ws().affordable(d, campaign.deploy.stock)
	var free_note := (" The first %d of a deployment are free." % campaign.deploy.starter_free()) if Rules.truthy(d.get("starter")) else ""
	result.add_child(UI.label("Your stockpile could pay for %d cop%s. Copies are paid when a Strike Team leaves the dock.%s" % [n, "y" if n == 1 else "ies", free_note], 15, UI.PALE, true))


# ---------------------------------------------------------------- taps
func _on_row(i: int, at: Vector2) -> void:
	if i < 0 or i >= _rows.size() or sheet != null or namer != null or dialog != null:
		return
	var what = UI.act_at(_rows[i], at)
	if what != null:
		act(what)


## Does what a tap asks. (The tests send these too.)
func act(what: Array) -> void:
	if locked or campaign == null:
		return
	var abilities: Array = d.get("abilities", [])
	var ch = chassis()
	match what[0]:
		"add":
			abilities.append(ws().blank_ability(ch, str(what[1])))
			d["abilities"] = abilities
			save()
		"remove":
			abilities.remove_at(int(what[1]))
			save()
		"role":
			var a: Dictionary = abilities[int(what[1])]
			var subs: Array = ch.get("subtypes", [])
			var at := subs.find(a.get("role"))
			a["role"] = subs[(at + 1) % subs.size()]
			for k in Workshop.fields_for(a):
				if not a.has(k):
					a[k] = ws().blank_ability(ch, "action")[k]
			save()
		"num":
			var a2: Dictionary = abilities[int(what[1])]
			var k: String = what[2]
			var most := Scoring.num(ch.get("stats", {}).get("nrg"), 0.0) if k == "energy" else Workshop.max_of(ch, k)
			var least := 0.0 if k == "energy" else Workshop.least_of(ch, k)
			var now := Scoring.num(a2.get(k), 0.0)
			# a number already past a limit may still step back toward it
			a2[k] = int(clampf(now + int(what[3]), minf(least, now if int(what[3]) > 0 else least), maxf(most, now if int(what[3]) < 0 else most)))
			save()
		"projectile":
			var a4: Dictionary = abilities[int(what[1])]
			a4["projectile"] = Workshop.PROJECTILES[(Workshop.PROJECTILES.find(Workshop.projectile_of(a4)) + 1) % Workshop.PROJECTILES.size()]
			save()
		"build":
			open_builder(int(what[1]), -1)
		"change":
			open_builder(int(what[1]), int(what[2]))
		"cut":
			var a3: Dictionary = abilities[int(what[1])]
			var sents := Keywords.sentences(str(a3.get("text", "")))
			sents.remove_at(int(what[2]))
			a3["text"] = " ".join(sents)
			save()
		"ability name":
			ask_ability_name(int(what[1]))
		"look":
			d["skin"] = {"skin": what[1], "variant": what[2]}
			save()


## The keyword builder, on one ability: a new sentence (j = -1) or one to change.
func open_builder(i: int, j: int) -> void:
	var a: Dictionary = d["abilities"][i]
	var sents := Keywords.sentences(str(a.get("text", "")))
	var o := ws().builder_options(d, i, j, roster.troops().map(func(c): return str(c["name"])) if roster != null else [])
	sheet = BuilderSheet.new()
	add_child(sheet)
	sheet.done.connect(func(text):
		_drop_sheet()
		if j >= 0:
			sents[j] = text
		else:
			sents.append(text)
		a["text"] = " ".join(sents.filter(func(s): return str(s).strip_edges() != ""))
		save())
	sheet.cancelled.connect(func(): _drop_sheet())
	sheet.open(o)


func _drop_sheet() -> void:
	if sheet != null:
		Motion.pop_out(sheet, sheet.get_meta("box", null))
		sheet = null


# ---------------------------------------------------------------- names
## A name another design has, or a card of the export's (not the Companion's
## own designs, which a design of yours takes the place of), can't be taken.
func name_problem(want: String) -> String:
	for o in ws().list():
		if str(o.get("name")) == want and o.get("id") != d.get("id"):
			return "Another design is called %s." % want
	if roster != null:
		for c in roster.from_export:
			if str(c.get("name")) == want and c.get("_src") != "design":
				return "A card in your export is called %s." % want
	return ""


func ask_name() -> void:
	namer = NameDialog.new("Rename the design", str(d.get("name", "")), "Strike Teams that hold it keep it under its new name.")
	add_child(namer)
	namer.named.connect(func(t): rename(t))
	namer.cancelled.connect(func(): _drop_namer())


func _drop_namer() -> void:
	if namer != null:
		Motion.pop_out(namer, namer.get_meta("box", null))
		namer = null


## Renames it, and every Strike Team that holds it.
func rename(want: String) -> bool:
	_drop_namer()
	var why := name_problem(want)
	if why != "":
		note = why
		refresh()
		return false
	var old := str(d.get("name", ""))
	d["name"] = want
	note = ""
	if old != want and old != "":
		var teams := StrikeTeams.load_all()
		var touched := false
		for t in teams:
			if t["deck"].has(old):
				var n := StrikeTeams.copies(t, old)
				t["deck"].erase(old)
				t["deck"][want] = n
				touched = true
		if touched:
			StrikeTeams.save_all(teams)
	save()
	return true


func ask_ability_name(i: int) -> void:
	var a: Dictionary = d["abilities"][i]
	namer = NameDialog.new("Name the ability", str(a.get("name", "")))
	add_child(namer)
	namer.named.connect(func(t):
		_drop_namer()
		a["name"] = t
		save())
	namer.cancelled.connect(func(): _drop_namer())


# ---------------------------------------------------------------- copy and delete
func copy() -> void:
	var c := d.duplicate(true)
	c["id"] = null
	c.erase("starter")
	c.erase("saved")
	c.erase("mk")                 # (0.37) a copy starts at Mk I
	var base := str(d.get("name", "Design")) + " copy"
	var want := base
	var n := 2
	while name_problem(want) != "" and n < 100:
		want = "%s %d" % [base, n]
		n += 1
	c["name"] = want
	var id := ws().put(c)
	campaign.designs_changed()
	campaign.save()
	changed.emit()
	open(campaign, roster, ws().get_design(id))


## (0.37) Raise it a Mark: what it costs, and what it gives.
func ask_upgrade() -> void:
	if dialog != null or not Rules.truthy(d.get("id")):
		return
	var cur = ws().get_design(d["id"])
	var c = Workshop.mk_cost(cur)
	if c == null:
		return
	var to := Workshop.mk_of(cur) + 1
	var gain: Dictionary = Workshop.MK[to - 1]
	var st := Loot.norm(campaign.deploy.stock)
	var can := true
	for r in 6:
		if st["parts"]["troop"][r] < int(c[r]):
			can = false
	var text := "%s becomes %s: %s in all, against Mk I. It costs %s Troop parts; the stockpile holds %s." % [str(cur["name"]), Workshop.MK_NAME[to - 1],
		"+%d Health, +%d Armor Class%s" % [gain["hp"], gain["ac"], (", +%d Movement" % gain["move"]) if gain["move"] > 0 else ""], Workshop.cost_text(c), Workshop.cost_text(st["parts"]["troop"])]
	dialog = Dialog.new("Raise it to %s?" % Workshop.MK_NAME[to - 1], text + ("" if can else " That isn't enough yet."), ["Raise it", "Not now"] if can else ["OK"], UI.GOLD)
	add_child(dialog)
	dialog.chosen.connect(func(k):
		Motion.pop_out(dialog, dialog.get_meta("box", null))
		dialog = null
		if k == 0 and can:
			upgrade())


func upgrade() -> void:
	var r := ws().upgrade(d.get("id"), campaign.deploy.stock, campaign.deploy.active())
	if r["ok"]:
		campaign.designs_changed()
		campaign.save()
		changed.emit()
		d = ws().get_design(d["id"])
		note = "Raised to %s." % Workshop.MK_NAME[int(r["mk"]) - 1]
	else:
		note = str(r["why"]) + "."
	refresh()


func ask_delete() -> void:
	dialog = Dialog.new("Delete this design?", "Strike Teams that hold it keep its name, marked as missing, until you take it out.", ["Delete", "Keep it"], UI.SOFT_RED)
	add_child(dialog)
	dialog.chosen.connect(func(k):
		Motion.pop_out(dialog, dialog.get_meta("box", null))
		dialog = null
		if k == 0:
			delete_design())


func delete_design() -> void:
	if ws().remove(d.get("id")):
		campaign.designs_changed()
		campaign.save()
		changed.emit()
		close()
