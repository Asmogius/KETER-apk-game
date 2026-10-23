## A card, read in full: its art, what kind it is and what it costs, a Unit's
## numbers, and every Action and Passive on it with its text as it reads. Text
## the game can't carry out (no keywords in it) is marked, so a card that will
## do nothing says so before it's in a Deck. Along the bottom: whatever can be
## done with the card from here (copies in a Deck, carried by a Hero...), and
## Close. It covers the screen while it's up.
class_name CardSheet
extends Control

signal chosen(id: String)
signal stepped(value: int)

var card: Dictionary
var value := 0
var lo := 0
var hi := 99
var count_label: Label
var minus_btn: Button
var plus_btn: Button
var body: TouchList
var buttons := {}              # id -> Button
var note_label: Label
var x_shown = null             # the X a variable-cost card is being read at, or null


## opts: buttons [[id, label]], stepper {value, min, max, label}, note (a line
## under the name), unit (a Unit of this card in a battle, for its numbers now),
## x (a variable-cost card is read with this X in place: show_x changes it).
func _init(c: Dictionary, art: Texture2D, opts: Dictionary = {}) -> void:
	card = c
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 56)
	m.add_theme_constant_override("margin_top", 20)
	m.add_theme_constant_override("margin_bottom", 20)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(m)
	var panel := PanelContainer.new()
	set_meta("box", panel)               # (0.12) what pops open and shut
	panel.add_theme_stylebox_override("panel", UI.box(Color("#171819", 0.99), UI.LINE, 1, 10, 18))
	panel.theme = Look.fight_theme()
	m.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	panel.add_child(col)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 22)
	top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(top)

	# (0.14) the card itself, large, as the Forge prints it
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(CardFace.LARGE.x, 0)
	left.add_theme_constant_override("separation", 8)
	top.add_child(left)
	var face := CardFace.Face.new(c, art)
	set_meta("face", face)
	left.add_child(face)
	# everything it says
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	top.add_child(right)
	right.add_child(Look.title(str(c.get("name", "")), UI.TEXT, Look.TITLE))
	var kl := Look.read(kind_line(c), UI.type_colour(c), true)
	right.add_child(kl)
	var cost := cost_line(c)
	if cost != "":
		right.add_child(Look.read(cost, UI.GOLD, true))
	note_label = Look.read(str(opts.get("note", "")), UI.PALE, true)
	note_label.visible = note_label.text != ""
	right.add_child(note_label)
	body = TouchList.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.box.add_theme_constant_override("separation", 5)
	right.add_child(body)
	x_shown = opts.get("x")
	_fill_body()

	# what can be done with it from here
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	foot.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(foot)
	if opts.has("stepper"):
		var st: Dictionary = opts["stepper"]
		value = int(st.get("value", 0))
		lo = int(st.get("min", 0))
		hi = int(st.get("max", 99))
		foot.add_child(UI.label(str(st.get("label", "Copies")), 20, UI.PALE))
		minus_btn = UI.button("−", func(): step(-1), 76)
		foot.add_child(minus_btn)
		count_label = UI.label(str(value), 30, UI.GOLD)
		count_label.custom_minimum_size = Vector2(56, 0)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		foot.add_child(count_label)
		plus_btn = UI.button("+", func(): step(1), 76)
		foot.add_child(plus_btn)
		_stepper_state()
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(30, 0)
		foot.add_child(gap)
	for b in opts.get("buttons", []):
		var id: String = b[0]
		var btn := UI.button(str(b[1]), func(): chosen.emit(id), 170)
		if b.size() > 2 and b[2] == false:
			btn.disabled = true
		foot.add_child(btn)
		buttons[id] = btn
	var close := UI.button("Close", func(): chosen.emit("close"), 150)
	foot.add_child(close)
	buttons["close"] = close


func _fill_body() -> void:
	var keep := body.scroll
	body.clear()
	for l in describe(card, x_shown):
		# (0.14) read in VT323; the small print in Jersey 10 at its own pixel
		var lab: Label = Look.read(l[0], l[1], true) if int(l[2]) >= 15 else Look.title(l[0], l[1], Look.SMALL)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.custom_minimum_size = Vector2(620, 0)
		body.add_row(lab)
	body.scroll_by(keep)


## Reads a variable-cost card with this X in place: its numbers and its text.
func show_x(x: int) -> void:
	x_shown = maxi(1, x)
	_fill_body()


func step(d: int) -> void:
	var v := clampi(value + d, lo, hi)
	if v == value:
		return
	value = v
	count_label.text = str(value)
	_stepper_state()
	stepped.emit(value)


func _stepper_state() -> void:
	minus_btn.disabled = value <= lo
	plus_btn.disabled = value >= hi


func set_note(t: String) -> void:
	note_label.text = t
	note_label.visible = t != ""


# ---------------------------------------------------------------- what a card says
## "Troop · District 3 · Rare · Level 2"
static func kind_line(c: Dictionary) -> String:
	var bits := [UI.type_name(c)]
	if Rules.truthy(c.get("basic")):
		return "Aether Chip · District " + str(c.get("district", ""))
	var affs: Array = c["affinities"] if c.get("affinities") is Array else []
	var ds := []
	for a in affs:
		if a is Dictionary and Rules.truthy(a.get("district")):
			ds.append("any District" if str(a["district"]) == "any" else "District " + str(a["district"]))
	if not ds.is_empty():
		bits.append(" / ".join(ds))
	if Rules.truthy(c.get("rarity")):
		bits.append(str(c["rarity"]).capitalize())
	var lv = c.get("skullLevel") if Rules.truthy(c.get("skullLevel")) else c.get("level")
	if Rules.truthy(lv):
		bits.append("Level " + str(lv))
	var o := Roster.origin(c)
	if o != "":
		bits.append(o)
	return " · ".join(bits)


## What it costs to play, or what a Chip is worth; "" for a card that has neither.
static func cost_line(c: Dictionary) -> String:
	var t := Roster.type_of(c)
	if t == "sphere":
		var v := 1 if Rules.truthy(c.get("basic")) else Rules.chip_value(c)
		var d := StrikeTeams.chip_district(c)
		return "Once drawn from the Pouch it generates %d Aether %s every round." % [v, ("of District " + d) if d != "" and d != "any" else "of any kind"]
	if StrikeTeams.DECK_TYPES.has(t):
		var label := UI.show(Roster.cost_label(Roster.hand_card(c)))
		return "Free to play." if label == "free" else "Costs %s Aether to play." % label
	if t == "prototype":
		return "Always on, through the team's leader."
	if t == "action":
		var each := UI.show(Roster.cost_label(Roster.hand_card(c)))
		if each == "free":
			return "Carried by a Hero, as one of its Actions."
		return "Carried by a Hero, as one of its Actions. Each use costs %s Aether%s." % [each, ", with X chosen each time (at least 1)" if Roster.card_var(Roster.hand_card(c)) else ""]
	if t == "consumable":
		return "No Aether cost."
	return ""


## A plain sentence is one with no keywords in it: the game can't carry it out.
static func is_plain(text) -> bool:
	return Roster.is_plain(text)


## Everything a card says, a line at a time: [[text, colour, size]]. A card
## with a variable cost is read with X as it is written, unless x is given:
## then its numbers and its text have that X in place.
static func describe(c: Dictionary, x = null) -> Array:
	var out := []
	var t := Roster.type_of(c)
	var st: Dictionary = c["stats"] if c.get("stats") is Dictionary else {}
	var is_unit := ["hero", "troop", "enemy", "elite", "miniboss", "boss"].has(t)
	var variable := Roster.card_var(Roster.hand_card(c)) if StrikeTeams.DECK_TYPES.has(t) else false
	if variable:
		out.append([("With X = %d:" % int(x)) if x != null else "A variable cost: X is chosen as it is played, at least 1.", UI.GOLD, 15])
	if is_unit:
		var spec := Roster.unit_spec(c)
		if variable and x != null:
			spec["x"] = maxi(1, int(x))
		var u := Battle.x_fill(Rules.unit_from_card(spec, "ally")) if (variable and x != null) else Rules.unit_from_card(spec, "ally")
		var per := stats_per_x(st) if (variable and x == null) else ""
		out.append(["HP %d   AC %d   MS %d   NRG %d   INT %d" % [u["hpMax"], u["ac"], u["ms"], u["nrgMax"], u["integrity"]] + per, UI.TEXT, 22])
		if t == "hero":
			var gen := Battle.aether_label(Rules.aether_from_hero(u))
			out.append(["Leadership %d   ·   %d Action Slot%s   ·   generates %s" % [StrikeTeams.leadership(c), StrikeTeams.action_slots(c), "" if StrikeTeams.action_slots(c) == 1 else "s",
				(UI.show(gen) + " Aether a round") if gen != "—" else "no Aether"], UI.CYAN, 17])
		elif t == "troop":
			out.append(["%d Unit Slot%s to start a fight beside your Heroes" % [Roster.slots(c), "" if Roster.slots(c) == 1 else "s"], UI.CYAN, 17])
		for a in u["actions"]:
			out.append([str(a.get("name", "")) + "  ·  " + str(a.get("tag", "Active")), UI.TEXT, 19])
			if a.get("tag") != "Passive" and a.get("tag") != "Aura":
				out.append([UnitPanel.action_summary(a), UI.CYAN, 15])
			_text_lines(out, a.get("text"))
	else:
		for e in Roster.hand_card(c)["effects"]:
			var head := str(e["name"]) if str(e["name"]) != "" else str(e["kind"])
			if str(e["name"]) != "":
				head += "  ·  " + str(e["kind"])
			out.append([head, UI.TEXT, 19])
			var bits := []
			if str(e["role"]) != "":
				bits.append(str(e["role"]).capitalize())
			if Rules.truthy(e.get("range")):
				bits.append("range " + str(e["range"]))
			if Rules.truthy(e.get("damage")):
				bits.append(str(e["damage"]) + " damage")
			if Rules.truthy(e.get("toHit")):
				bits.append("To-Hit " + str(e["toHit"]))
			if Rules.truthy(e.get("pen")):
				bits.append("AP " + str(e["pen"]))
			if not bits.is_empty():
				out.append([" · ".join(bits), UI.CYAN, 15])
			_text_lines(out, Keywords.fill_x(str(e.get("text") if e.get("text") != null else ""), int(x)) if (variable and x != null) else e.get("text"))
		if Rules.truthy(c.get("basic")):
			out.append(["A basic Chip. It has no effect of its own.", UI.DIM, 17])
	if out.is_empty():
		out.append(["No rules text on this card.", UI.DIM, 17])
	if Rules.truthy(c.get("loreEnabled")) and Rules.truthy(c.get("lore")):
		out.append([str(c["lore"]), UI.DIM, 15])
	return out


## Which of a variable-cost Unit's numbers grow with X: "   (at X = 1; HP 4 for each X)".
static func stats_per_x(st: Dictionary) -> String:
	var bits := []
	for pair in [["hp", "HP"], ["ac", "AC"], ["move", "MS"], ["nrg", "NRG"], ["int", "INT"]]:
		var m := Rules._re_stat_x.search(str(st.get(pair[0]) if st.get(pair[0]) != null else ""))
		if m != null:
			bits.append("%s %s for each X" % [pair[1], m.get_string(1)])
	return ("   (at X = 1; " + ", ".join(bits) + ")") if not bits.is_empty() else ""


static func _text_lines(out: Array, text) -> void:
	var t := str(text if text != null else "").strip_edges()
	if t == "":
		return
	for sent in Keywords.sentences(t):
		if is_plain(sent):
			out.append([sent, UI.DIM, 16])
			out.append(["Plain text: the game can't carry this out until it's written with keywords.", UI.GOLD, 14])
		else:
			out.append([UI.show(Keywords.render(sent)), UI.PALE, 16])


## (0.12) It pops open.
func _ready() -> void:
	Motion.pop_in(get_meta("box"))
