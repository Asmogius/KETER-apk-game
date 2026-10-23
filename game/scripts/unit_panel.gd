## The side panel: everything about the Unit you tapped. Its token, name and
## side; Health, Armor Class, Movement Speed, Energy and Integrity; its Actions
## with their Energy, range and damage and what their text does, as it reads;
## its Passives; every status on it by name, with what it does and how long it
## has left; anything changing its numbers. For one of your Units the Actions
## are buttons: tap one to aim it, tap it again to put it away. One it can't
## use now is greyed, with the reason. An Action with Suppressive Fire has a
## second button under it: Hold fire. Under the Actions is how it fights on
## Auto: its Behavior keywords, and for one of yours a button to change them.
## (0.16) Under the name of one of yours, in your turn, a strip of what it can
## still do this turn: Move (and how far), Attack, Hold fire, each with its
## icon, dimmed once used.
class_name UnitPanel
extends PanelContainer

signal closed
signal action_pressed(index: int)
signal hold_pressed(action_name: String)
signal behavior_pressed

const WIDTH := 400.0
const CYAN := Color("#73efe8")
const RED := Color("#ff2a3c")
const DIM := Color("#88a3bc")
const GOLD := Color("#d6a851")

var unit: Dictionary = {}
var pic: TextureRect
var letters: Label
var name_label: Label
var side_label: Label
var move_label: Label
var turn_row: HBoxContainer      # (0.16) what it can still do this turn: Move, Attack, Hold fire
var stats_box: GridContainer
var chips: HFlowContainer        # the Unit's statuses at a glance, under its numbers
var body: TouchList
var close_btn: Button
var _rows: Array = []            # what each row of the body is: {action: index} or {}


## (0.14) Old sizes into the two faces at their own pixels: names and numbers
## in Jersey 10, what you read in VT323, the small print in Jersey 10 at 1.
static func _type(l: Control, n: int) -> void:
	if n >= 20:
		l.add_theme_font_override("font", Look.font())
		l.add_theme_font_size_override("font_size", Look.TITLE)
	elif n >= 15:
		l.add_theme_font_override("font", Look.body())
		l.add_theme_font_size_override("font_size", Look.BODY)
	else:
		l.add_theme_font_override("font", Look.font())
		l.add_theme_font_size_override("font_size", Look.SMALL)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = Look.fight_theme()
	var sb := PixelBox.new()
	sb.bg_color = Color("#171819", 1.0)
	sb.border_color = Color("#2c3b39")
	sb.border_width_left = 2
	sb.content_margin_left = 16; sb.content_margin_right = 14; sb.content_margin_top = 12; sb.content_margin_bottom = 12
	add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	col.add_child(head)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(96, 96)
	head.add_child(holder)
	pic = TextureRect.new()
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(pic)
	letters = Label.new()
	letters.set_anchors_preset(Control.PRESET_FULL_RECT)
	letters.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letters.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_type(letters, 30)
	holder.add_child(letters)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 2)
	head.add_child(names)
	name_label = Label.new()
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_type(name_label, 23)
	names.add_child(name_label)
	side_label = Label.new()
	# (0.14) it may wrap: "Enemy · Level 1 · Bounty" in one line pushed the × off the panel
	side_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_type(side_label, 17)
	names.add_child(side_label)
	move_label = Label.new()
	move_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_type(move_label, 16)
	move_label.add_theme_color_override("font_color", DIM)
	names.add_child(move_label)
	close_btn = Button.new()
	close_btn.text = "×"
	_type(close_btn, 34)
	close_btn.custom_minimum_size = Vector2(56, 56)
	close_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close_btn.pressed.connect(func(): closed.emit())
	head.add_child(close_btn)

	turn_row = HBoxContainer.new()
	turn_row.add_theme_constant_override("separation", 6)
	turn_row.visible = false
	col.add_child(turn_row)

	stats_box = GridContainer.new()
	stats_box.columns = 5
	stats_box.add_theme_constant_override("h_separation", 6)
	col.add_child(stats_box)

	chips = HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 14)
	chips.add_theme_constant_override("v_separation", 2)
	chips.visible = false
	col.add_child(chips)

	body = TouchList.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.box.add_theme_constant_override("separation", 6)
	body.row_tapped.connect(_on_row)
	col.add_child(body)


## Shows a Unit. info: moved (has moved this round), speed (how far it may
## go), interactive (its Actions are buttons), states (action index -> {ok,
## why}), picked (the Action being aimed, or -1), holds (the names of the
## Actions it could hold fire with now), hint (what to say under the Action
## being aimed), leader (it leads its Strike Team), auto (Auto is on),
## acted (it has moved or used an Action this turn).
func show_unit(u: Dictionary, look: Dictionary, info: Dictionary = {}) -> void:
	unit = u
	visible = true
	var moved: bool = info.get("moved", false)
	var speed: int = info.get("speed", 0)
	var tex = look.get("texture")
	# (0.14) a Unit with no token shows its stand-in, as on the board
	if tex == null:
		tex = Art.standin(UnitView.stand_in_kind(u))
	pic.texture = tex
	letters.text = "" if tex != null else Roster.letters(str(u.get("name", "?")))
	name_label.text = str(u.get("name", "Unit"))
	var ally: bool = u.get("side") == "ally"
	var kind := str(u.get("cardType", "")).to_lower()
	var kinds := {"hero": "Hero", "troop": "Troop", "elite": "Elite", "miniboss": "Mini-Boss", "boss": "Boss"}
	var lvl = u.get("spawnLevel")
	var wanted := Rules.truthy(u.get("bounty"))
	side_label.text = keep_pairs(("Yours" if ally else "Enemy") + ((" · " + kinds[kind]) if kinds.has(kind) else "") + ((" · Level %d" % lvl) if lvl != null else "") + (" · Leader" if info.get("leader", false) else "") + (" · Bounty" if wanted else ""))
	side_label.add_theme_color_override("font_color", CYAN if ally else (Color("#d6a851") if wanted else RED))
	# (0.16) the strip says how far it can move, or that it has: the line under its name doesn't again
	var turn: Dictionary = info.get("turn", {})
	if Rules.truthy(u.get("down")):
		move_label.text = "Down."
	elif not ally:
		move_label.text = "Acts on its own when you end your turn."
	elif u.get("holding") != null:
		move_label.text = "Holding fire with %s: it shoots the first Enemy that moves into its reach." % str(u["holding"].get("name", "an Action"))
	elif not turn.is_empty():
		move_label.text = ""
	elif moved:
		move_label.text = "Has moved this round."
	elif speed <= 0:
		move_label.text = "Can't move."
	else:
		move_label.text = "Can move up to %d tile%s." % [speed, "" if speed == 1 else "s"]
	if ally and not Rules.truthy(u.get("down")) and info.get("auto", false) and info.get("interactive", false):
		move_label.text += (" " if move_label.text != "" else "") + ("Auto leaves it alone now: you've used it this turn." if info.get("acted", false) else "Auto takes its turn when you end yours.")
	move_label.visible = move_label.text != ""
	_turn_strip(turn)

	for c in stats_box.get_children():
		c.queue_free()
	var eff := Rules.effective(u)
	var ms_now := int(Rules.num(eff["ms"], 0))
	var ms_base := int(Rules.num(u.get("ms"), 0))
	_stat("HP", "%d/%d" % [int(Rules.num(u.get("hp"), 0)), int(Rules.num(u.get("hpMax"), 0))])
	_stat("AC", str(int(Rules.num(eff["ac"], 0))))
	_stat("MS", str(ms_now) if ms_now == ms_base else "%d (%d)" % [ms_now, ms_base])
	_stat("NRG", "%d/%d" % [int(Rules.num(u.get("nrg"), 0)), int(Rules.num(u.get("nrgMax"), 0))])
	_stat("INT", str(int(Rules.num(eff["integrity"], 0))))

	# its statuses at a glance: the same colours as the dots on the board
	for c in chips.get_children():
		chips.remove_child(c)
		c.queue_free()
	if eff["flying"]:
		_chip("Flying", Color("#73efe8"))
	for st in (u.get("statuses", []) if u.get("statuses") != null else []):
		_chip(str(st.get("name", "")) + ((" " + str(st["n"])) if st.get("n") != null else ""), UnitView.status_colour(str(st.get("name", ""))), Art.status_icon(str(st.get("name", ""))))
	for g in guarded(u):
		_chip("Guarded: " + g, UnitView.status_colour(g).darkened(0.35), Art.status_icon("guarded"))
	if u.get("holding") != null:
		_chip("Holding fire", GOLD, Art.status_icon("overwatch"))
	chips.visible = chips.get_child_count() > 0

	var keep := body.scroll if body.has_meta("unit") and body.get_meta("unit") == u.get("id") else 0.0
	body.set_meta("unit", u.get("id"))
	body.clear()
	_rows = []
	var interactive: bool = info.get("interactive", false)
	var states: Dictionary = info.get("states", {})
	var picked: int = info.get("picked", -1)
	var holds: Array = info.get("holds", [])
	var acts: Array = u.get("actions", [])
	var passives := []
	_heading("Actions")
	var any := false
	for i in acts.size():
		var a: Dictionary = acts[i]
		if a.get("tag") == "Passive" or a.get("tag") == "Aura":
			passives.append(a)
			continue
		any = true
		_action_row(i, a, interactive, states.get(i, {"ok": true}), i == picked, str(info.get("hint", "")))
		if interactive and holds.has(a.get("name")):
			_hold_row(a)
	if not any:
		_line("None.", DIM, 16)
	_behavior_rows(u, ally and interactive)
	if not passives.is_empty():
		_heading("Passives")
		for a in passives:
			_line(str(a.get("name", "")) + "  ·  " + str(a.get("tag", "")), Color("#e6e7f0"), 17)
			if str(a.get("text", "")) != "":
				_line(card_text(a["text"]), DIM, 15)
	# what it wears: each piece of Equipment, with what it says
	var worn: Array = u["equipFx"] if u.get("equipFx") is Array else []
	if not worn.is_empty():
		_heading("Equipment")
		for eq in worn:
			_line(str(eq.get("name", "")), Color("#e6e7f0"), 17)
			for f in (eq["fx"] if eq.get("fx") is Array else []):
				if str(f.get("text", "")) != "":
					_line(card_text(f["text"]), DIM, 15)
	_heading("Statuses")
	var sts: Array = u.get("statuses", [])
	var flying: bool = eff["flying"]
	var gds := guarded(u)
	if sts.is_empty() and not flying and gds.is_empty():
		_line("None.", DIM, 16)
	if flying:
		_status_row("Flying", "", "Melee Attacks can't reach it, and walls don't stop it.", Color("#73efe8"))
	for s in sts:
		var nm := str(s.get("name", ""))
		_status_row(nm + ((" " + str(s["n"])) if s.get("n") != null else ""), lasting(s), status_words(nm, s.get("n")), UnitView.status_colour(nm), Art.status_icon(nm))
	for g in gds:
		_status_row("Guarded: " + g, "for a round", guard_words(g), UnitView.status_colour(g).darkened(0.35), Art.status_icon("guarded"))
	var mods: Array = u.get("mods", []) if u.get("mods") != null else []
	if not mods.is_empty():
		_heading("Changes")
		for m in mods:
			_line(mod_words(m), Color("#e6e7f0"), 16)
	body.scroll_by(keep)


## (0.14) A line of pairs ("2 NRG · range 5 · AP 6") that only breaks between
## pairs: the spaces inside each are ones a line can't break at.
static func keep_pairs(t: String) -> String:
	var bits := t.split(" \u00b7 ")
	for i in bits.size():
		bits[i] = bits[i].replace(" ", "\u00a0")
	# (the dot stays with the pair before it: a line ends "·", and never starts with one)
	return "\u00a0\u00b7 ".join(bits)


## Card text as it reads: no markers, distances in tiles.
static func card_text(t) -> String:
	return Keywords.render(str(t if t != null else ""))


## 0.13: what a Unit is guarded against, by name ("Stunned"): it has just
## come out of it, so it cannot have it again until the same point of the next
## round (Handbook 16.0).
static func guarded(u: Dictionary) -> Array:
	var out := []
	if u.get("guards") is Dictionary:
		for g in u["guards"].keys():
			out.append(str(g).capitalize())
	return out


## A guard, in words.
static func guard_words(name: String) -> String:
	return "Just came out of being " + name + ": it can't be " + name + " again until the same point of the next round."


## How long a status has left, in words.
static func lasting(s: Dictionary) -> String:
	var src := str(s.get("source", "") if s.get("source") != null else "")
	if src.begins_with("aura:"):
		return "while in the Aura"
	if src.begins_with("passive:"):
		return "always on"
	var t = s.get("turns")
	if t == null:
		return ""
	if int(t) >= 99:
		return "until removed"
	return "%d turn%s left" % [int(t), "" if int(t) == 1 else "s"]


## What a status does, from the keyword library, with its own number in place:
## "Slowed 2" reads "Movement Speed reduced by 2."
static func status_words(name: String, n) -> String:
	var low := name.to_lower()
	if low == "half cover":
		return "Counts as behind Half Cover: +2 to the To-Hit of Ranged Attacks against it."
	if low == "full cover":
		return "Counts as behind Full Cover: +4 to the To-Hit of Ranged Attacks against it."
	var kw = Keywords.by_name(name)
	if kw == null or not Rules.truthy(kw.get("desc")):
		return ""
	var d := str(kw["desc"])
	var stop := d.find(". ")
	if stop >= 0:
		d = d.substr(0, stop + 1)
	if n != null:
		d = d.replace("the number less", str(n) + " less").replace("the number", str(n)).replace("its number", str(n))
	return d


## A change to a Unit's numbers, in words: "AC +2 · 2 turns · from Thick Skull".
static func mod_words(m: Dictionary) -> String:
	var amt := int(Rules.num(m.get("amt"), 0))
	var stat := str(m.get("stat", ""))
	var bits := [("Range" if stat == "RANGE" else stat) + (" +%d" % amt if amt >= 0 else " %d" % amt)]
	var dur := str(m.get("dur", "") if m.get("dur") != null else "")
	var n = m.get("n")
	if dur == "turns":
		bits.append("%d turn%s" % [int(Rules.num(n, 1)), "" if int(Rules.num(n, 1)) == 1 else "s"])
	elif dur == "passive":
		bits.append("always on")
	elif dur != "":
		bits.append(dur)
	if Rules.truthy(m.get("source")):
		bits.append("from " + str(m["source"]))
	return " · ".join(bits)


## What an Action does, in one line: "2 NRG · Ranged · range 5 · 6 damage · To-Hit 8 · AP 4".
static func action_summary(a: Dictionary) -> String:
	var bits := ["%d NRG" % int(Rules.num(a.get("cost"), 0))]
	# a carried Action card may cost Aether as well, at every use
	# (one with a variable cost reads X: it is chosen each time the Action is used)
	if a.get("aether") is Dictionary and Battle.action_aether_words(a) != "":
		bits[0] += " + " + UI.show(Battle.action_aether_words(a)) + " Aether"
	var role := str(a.get("role", "") if a.get("role") != null else "")
	bits.append(role.capitalize() if role != "" else "Melee")
	if Battle.aimed(role.to_lower()):
		bits.append("range %d" % int(Rules.num(a.get("rng"), 0) if Rules.truthy(Rules.num(a.get("rng"), 0)) else 1))
	var fx := Rules.action_effect(a)
	if fx["damage"] > 0:
		bits.append("%d damage" % fx["damage"])
	if fx["heal"] > 0:
		bits.append("heals %d" % fx["heal"])
	if a.get("hit") != null and str(a["hit"]) != "":
		bits.append("To-Hit " + str(a["hit"]))
	if a.get("pen") != null and str(a["pen"]) != "" and str(a["pen"]) != "0":
		bits.append("AP " + str(a["pen"]))
	# (0.12) what it fires, where its card says
	if Battle.aimed(role.to_lower()) and Motion.KINDS.has(a.get("proj")):
		bits.append("fires a " + str(a["proj"]).capitalize())
	return " · ".join(bits)


func _action_row(i: int, a: Dictionary, interactive: bool, state: Dictionary, picked: bool, hint_text := "") -> void:
	var ok: bool = state.get("ok", true) or picked      # one being aimed (a Burst under way) reads as live
	var row := PanelContainer.new()
	var sb := PixelBox.new()
	sb.bg_color = Color("#282c3c") if picked else (Color("#282c3c") if interactive and ok else Color("#171819"))
	sb.border_color = GOLD if picked else (CYAN if interactive and ok else Color("#2c3b39"))
	sb.set_border_width_all(3 if picked else (2 if interactive and ok else 1))
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10; sb.content_margin_right = 10; sb.content_margin_top = 6; sb.content_margin_bottom = 8
	row.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	row.add_child(v)
	var title := Label.new()
	title.text = str(a.get("name", "")) + "  ·  " + str(a.get("tag", "Active"))
	_type(title, 18)
	title.add_theme_color_override("font_color", Color("#e6e7f0") if ok or not interactive else DIM)
	# (0.14) its role's icon before its name
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 8)
	var role := str(a.get("role", "") if a.get("role") != null else "").to_lower()
	var ic := Art.icon2("role_" + (role if role in ["melee", "ranged", "support", "cyber"] else "melee"))
	if ic != null:
		var tr := TextureRect.new()
		tr.texture = ic
		tr.custom_minimum_size = Vector2(32, 32)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.modulate = Color.WHITE if ok or not interactive else Color(1, 1, 1, 0.4)
		th.add_child(tr)
	th.add_child(title)
	v.add_child(th)
	var sumy := Label.new()
	sumy.text = keep_pairs(action_summary(a))
	sumy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sumy.custom_minimum_size = Vector2(WIDTH - 70, 0)
	_type(sumy, 15)
	sumy.add_theme_color_override("font_color", CYAN if ok or not interactive else DIM)
	v.add_child(sumy)
	if interactive and not ok:
		var why := Label.new()
		why.text = str(state.get("why", ""))
		_type(why, 15)
		why.add_theme_color_override("font_color", GOLD)
		v.add_child(why)
	elif picked:
		var hint := Label.new()
		hint.text = hint_text if hint_text != "" else "Aiming: tap a lit target, or this again to put it away."
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.custom_minimum_size = Vector2(WIDTH - 70, 0)
		_type(hint, 15)
		hint.add_theme_color_override("font_color", GOLD)
		v.add_child(hint)
	# a carried Action card with a variable cost reads X until it is being aimed with one
	var words := str(a.get("text", ""))
	if a.get("aetherX") is Dictionary and Rules.truthy(a.get("textX")) and not picked:
		words = str(a["textX"])
	if words != "":
		var tx := Label.new()
		tx.text = card_text(words) + ("  (X = %d)" % int(a["x"]) if (picked and a.get("aetherX") is Dictionary and Rules.truthy(a.get("x"))) else "")
		tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tx.custom_minimum_size = Vector2(WIDTH - 70, 0)
		_type(tx, 14)
		tx.add_theme_color_override("font_color", DIM)
		v.add_child(tx)
	_rows.append({"action": i, "live": interactive and ok})
	body.add_row(row)


## How it fights when nobody is choosing for it: its Behavior keywords, each
## with what it does. One of yours (while you can act) has a button to change
## them; an Enemy's are its card's.
func _behavior_rows(u: Dictionary, mine: bool) -> void:
	var behs: Array = u["behaviors"] if u.get("behaviors") is Array else []
	var ally: bool = u.get("side") == "ally"
	if behs.is_empty() and not ally:
		return
	_heading("On Auto" if ally else "Behavior")
	var row := PanelContainer.new()
	var sb := PixelBox.new()
	sb.bg_color = Color("#282c3c") if mine else Color("#171819")
	sb.border_color = CYAN if mine else Color("#2c3b39")
	sb.set_border_width_all(2 if mine else 1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10; sb.content_margin_right = 10; sb.content_margin_top = 6; sb.content_margin_bottom = 8
	row.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	row.add_child(v)
	if behs.is_empty():
		v.add_child(_wrapped("No Behavior keywords: it attacks the closest Enemy.", Color("#e6e7f0"), 16))
	for b in behs:
		var d = Rules.beh_of(b.get("k"))
		if d == null:
			continue
		var n = b.get("x") if b.get("x") != null else d.get("pdef")
		var numbered: bool = d.has("param") and n != null
		v.add_child(_wrapped(str(d["name"]) + ((" " + str(int(n))) if numbered else ""), Color("#e6e7f0"), 17))
		v.add_child(_wrapped(str(d["text"]).replace(" X ", " %s " % str(int(n))) if numbered else str(d["text"]), DIM, 14))
	if mine:
		v.add_child(_wrapped("Tap to change. Up to three.", CYAN, 15))
	_rows.append({"behavior": true, "live": mine})
	body.add_row(row)


func _wrapped(t: String, col: Color, fs: int) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(WIDTH - 70, 0)
	_type(l, fs)
	l.add_theme_color_override("font_color", col)
	return l


## Under an Action with Suppressive Fire: pay now, shoot in the Enemies' turn.
func _hold_row(a: Dictionary) -> void:
	var row := PanelContainer.new()
	var sb := PixelBox.new()
	sb.bg_color = Color("#271f1b")
	sb.border_color = GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10; sb.content_margin_right = 10; sb.content_margin_top = 6; sb.content_margin_bottom = 8
	row.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = "Hold fire with %s  ·  %d NRG now. It shoots the first Enemy that moves into its reach in their turn." % [str(a.get("name", "")), int(Rules.num(a.get("cost"), 0))]
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(WIDTH - 70, 0)
	_type(l, 15)
	l.add_theme_color_override("font_color", GOLD)
	row.add_child(l)
	_rows.append({"hold": str(a.get("name", ""))})
	body.add_row(row)


## A status: (0.14) its icon (or its colour, the dot's on the board, where it
## has none), its name and strength, how long it has left, and what it does.
func _status_row(title: String, left: String, what: String, colour: Color, icon: Texture2D = null) -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	v.add_child(head)
	head.add_child(_badge(colour, icon, 14.0))
	var t := Label.new()
	t.text = title + (("  ·  " + left) if left != "" else "")
	_type(t, 17)
	t.add_theme_color_override("font_color", Color("#e6e7f0"))
	head.add_child(t)
	if what != "":
		var w := Label.new()
		w.text = what
		w.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		w.custom_minimum_size = Vector2(WIDTH - 50, 0)
		_type(w, 14)
		w.add_theme_color_override("font_color", DIM)
		v.add_child(w)
	_rows.append({})
	body.add_row(v)


func _on_row(i: int, _at: Vector2) -> void:
	if i < 0 or i >= _rows.size():
		return
	var r: Dictionary = _rows[i]
	if r.has("action") and r.get("live", false):
		action_pressed.emit(r["action"])
	elif r.has("hold"):
		hold_pressed.emit(r["hold"])
	elif r.has("behavior") and r.get("live", false):
		behavior_pressed.emit()


## Card text without the Companion's keyword marks: "[[Push 2]]" reads "Push 2".
static func plain_text(t: String) -> String:
	return Keywords._re("\\[\\[(.*?)\\]\\]").sub(t, "$1", true)


## (0.14) A Status's icon at twice its pixels; a dot of its colour where it has none.
func _badge(colour: Color, icon: Texture2D, dot_size: float) -> Control:
	if icon != null:
		var tr := TextureRect.new()
		tr.texture = icon
		tr.custom_minimum_size = icon.get_size() * 2.0
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return tr
	var dot := ColorRect.new()
	dot.color = colour
	dot.custom_minimum_size = Vector2(dot_size, dot_size)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return dot


## (0.16) The strip of what it can still do this turn: Move (with how far),
## Attack, and, for one with Suppressive Fire, Hold fire. One it has used, or
## can't use now, is dimmed. turn: {move, moved, speed, attack, hold} as the
## fight works them out, hold "" (none to hold with), "can", "spent" or
## "holding"; empty for a Unit you can't act with now (no strip).
func _turn_strip(turn: Dictionary) -> void:
	for c in turn_row.get_children():
		turn_row.remove_child(c)
		c.queue_free()
	turn_row.visible = not turn.is_empty()
	if turn.is_empty():
		return
	var can_move: bool = turn.get("move", false)
	var spd := int(turn.get("speed", 0))
	var mv := ("Move %d" % spd) if can_move else ("Moved" if turn.get("moved", false) else "Can't move")
	turn_row.add_child(_turn_item("move", Art.icon2("act_move"), mv, MOVE_COLOUR, can_move))
	turn_row.add_child(_turn_item("attack", Art.icon2("act_attack"), "Attack", ATTACK_COLOUR, turn.get("attack", false)))
	var hold := str(turn.get("hold", ""))
	if hold != "":
		turn_row.add_child(_turn_item("hold", Art.status_icon("overwatch"), "Holding" if hold == "holding" else "Hold fire", GOLD, hold == "can"))


const MOVE_COLOUR := Color("#8aa1f6")
const ATTACK_COLOUR := Color("#fca570")


## One of the strip's three: its icon at twice its pixels and a word or two,
## in a frame of its colour while it can still be done; dimmed once it can't.
func _turn_item(what: String, icon: Texture2D, text: String, colour: Color, lit: bool) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := PixelBox.new()
	sb.bg_color = Color("#282c3c") if lit else Color("#171819")
	sb.border_color = colour.darkened(0.15) if lit else Color("#2c3b39")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 4; sb.content_margin_right = 10; sb.content_margin_top = 2; sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.set_meta("turn", what)
	p.set_meta("lit", lit)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(h)
	var tr := TextureRect.new()
	tr.texture = icon
	tr.custom_minimum_size = Vector2(32, 32)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.modulate = Color.WHITE if lit else Color(1, 1, 1, 0.3)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(tr)
	var l := Label.new()
	l.text = text
	_type(l, 16)
	l.add_theme_color_override("font_color", Color("#e6e7f0") if lit else DIM.darkened(0.25))
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(l)
	return p


func _chip(text: String, colour: Color, icon: Texture2D = null) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(_badge(colour, icon, 12.0))
	var l := Label.new()
	l.text = text
	_type(l, 16)
	l.add_theme_color_override("font_color", Color("#e6e7f0"))
	h.add_child(l)
	chips.add_child(h)


## (0.11: each with its icon, where the game has one)
const STAT_ICON := {"HP": "hp", "AC": "ac", "MS": "ms", "NRG": "nrg"}


func _stat(cap: String, value: String) -> void:
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(66, 0)
	v.add_theme_constant_override("separation", 0)
	var c := Label.new()
	c.text = cap
	_type(c, 13)
	c.add_theme_color_override("font_color", DIM)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	if STAT_ICON.has(cap):
		h.add_child(UI.icon(STAT_ICON[cap], 24))
	var l := Label.new()
	l.text = value
	_type(l, 18)
	h.add_child(l)
	v.add_child(h)
	v.add_child(c)
	stats_box.add_child(v)


func _heading(t: String) -> void:
	var l := Label.new()
	l.text = t.to_upper()
	_type(l, 14)
	l.add_theme_color_override("font_color", DIM)
	_rows.append({})
	body.add_row(l)


func _line(t: String, col: Color, fs: int) -> void:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(WIDTH - 50, 0)
	_type(l, fs)
	l.add_theme_color_override("font_color", col)
	_rows.append({})
	body.add_row(l)
