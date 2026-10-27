## Setting up a battle, a step at a time.
##
## A Quick battle: a floor, any Heroes (as many as the floor lets in), and any
## Troops to start beside them (as many Unit Slots as your Heroes' Leadership
## allows). One wave of Enemies, no Deck.
##
## A Battle: a floor, one of your Strike Teams, which of its Heroes enter (as
## many as the floor lets in) and who leads, then Starting Troops out of its
## Deck and the wave timer. Six waves, Aether, and a hand of cards.
##
## A deployment's fight: the floor is the one the POI or the ambush drew, and
## the Strike Team is the one that is out, as it stands. It asks only who
## enters, who leads, and the Starting Troops.
##
## (0.26) Pass and play: a floor, then Player 1's Strike Team, who enters and
## leads and its Starting Troops; then Player 2's the same way. Every card is
## theirs to use: nothing is recruited, researched or paid for. Strike Teams,
## on a team's step, builds or changes teams and comes back here.
class_name SetupScreen
extends Control

signal start_requested(floor_index: int, heroes: Array, troops: Array)
signal team_start_requested(floor_index: int, team: Dictionary, setup: Dictionary)
signal deploy_start_requested(team: Dictionary, setup: Dictionary)
signal pvp_start_requested(floor_index: int, team1: Dictionary, setup1: Dictionary, team2: Dictionary, setup2: Dictionary)
signal teams_requested                  # (0.26) Strike Teams, to build one for a match, and back
signal look_again_requested
signal closed

const CYAN := Color("#73efe8")
const DIM := Color("#88a3bc")
const WARN := Color("#d6a851")
const STEPS := ["floor", "heroes", "troops"]
const TEAM_STEPS := ["floor", "team", "heroes", "troops"]
const DEPLOY_STEPS := ["heroes", "troops"]
const PVP_SECOND := ["team", "heroes", "troops"]
const STEP_NAMES := {"floor": "Floor", "team": "Strike Team", "heroes": "Heroes", "troops": "Troops"}

var roster: Roster = null
var floors: Array[FloorData] = []
var step := "floor"
var floor_i := -1
var source := ""                        # where the content came from
var heroes: Array[String] = []          # names, in the order chosen
var troops := {}                        # name -> how many
var troop_order: Array[String] = []
var mode := "quick"                     # "quick", "team" for a Strike Team's Battle, or "deploy" for a deployment's fight
var deploy_spec := {}                   # a deployment's fight: {floor, district, skull, kind, index, count, name, ...}
var deploy_floor: FloorData = null      # its floor, in the tile's District
var deploy_team := {}                   # the Strike Team as it stands on the deployment
var teams: Array = []                   # the saved Strike Teams
var team_i := -1
var leader := ""                        # the Hero who leads (a Battle)
var wave_timer := 3
var districts_cleared := 0              # Dimensional Instability: 3% for each, set afresh for every Battle
var pvp_player := 1                     # (0.26) pass and play: whose team is being chosen
var pvp_first := {}                     # Player 1's choices, kept while Player 2 makes theirs

var title: Label
var steps_label: Label
var hint: Label
var list: TouchList
var note: Label
var back_btn: Button
var again_btn: Button
var next_btn: Button
var _rows: Array = []                   # what each row stands for


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(Backdrop.new("menu"))
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 22 if side != "top" else 14)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(m)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 24)
	col.add_child(head)
	title = Label.new()
	title.text = "New battle"
	title.add_theme_font_size_override("font_size", Look.fs(30))
	title.add_theme_color_override("font_color", CYAN)
	head.add_child(title)
	steps_label = Label.new()
	steps_label.add_theme_color_override("font_color", DIM)
	steps_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(steps_label)

	hint = Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", Look.fs(18))
	hint.add_theme_color_override("font_color", Color("#c5c7dd"))
	col.add_child(hint)

	list = TouchList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.row_tapped.connect(_on_row)
	col.add_child(list)

	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 14)
	col.add_child(foot)
	back_btn = _button("Back", func(): _go(-1))
	foot.add_child(back_btn)
	again_btn = _button("Look again", func(): look_again_requested.emit())
	foot.add_child(again_btn)
	note = Label.new()
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", Look.fs(17))
	note.add_theme_color_override("font_color", WARN)
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	foot.add_child(note)
	next_btn = _button("Next", func(): _go(1))
	next_btn.custom_minimum_size.x = 200
	next_btn.theme_type_variation = "MainButton"    # (0.15) the one thing to do next
	foot.add_child(next_btn)


func _button(text: String, fn: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(150, 60)
	b.pressed.connect(fn)
	return b


# ---------------------------------------------------------------- what it shows
## Starts over from a fresh export (keeping what was chosen, where it still fits).
func set_content(r: Roster, fl: Array[FloorData]) -> void:
	roster = r
	floors = fl
	if floor_i >= floors.size():
		floor_i = -1
	heroes = heroes.filter(func(n): return r.card_named(n) != null)
	for n in troops.keys():
		if r.card_named(n) == null:
			troops.erase(n)
	troop_order = troop_order.filter(func(n): return troops.has(n))
	step = "floor"
	show_step()


## Nothing to set up from: says why, and offers Look again.
func show_message(text: String) -> void:
	roster = null
	floors = []
	step = "floor"
	list.clear()
	_rows = []
	hint.text = text
	note.text = ""
	steps_label.text = ""
	back_btn.visible = false
	again_btn.visible = true
	next_btn.disabled = true
	next_btn.text = "Next"


func show_step() -> void:
	list.clear()
	_rows = []
	note.text = ""
	var parts := []
	for i in steps().size():
		var s: String = steps()[i]
		parts.append(("[ %d %s ]" if s == step else "%d %s") % [i + 1, STEP_NAMES[s]])
	steps_label.text = "   ›   ".join(parts)
	title.text = "Battle" if mode == "team" else "Quick battle"
	if mode == "pvp":
		title.text = "Pass and play  \u00b7  Player %d" % pvp_player
	back_btn.visible = true
	back_btn.text = "Home" if step == "floor" else "Back"
	if mode == "deploy":
		title.text = deploy_title()
		back_btn.text = "Map" if step == "heroes" else "Back"
	again_btn.visible = false
	next_btn.text = "Start battle" if step == "troops" else "Next"
	if mode == "pvp" and step == "troops":
		next_btn.text = "Player 2" if pvp_player == 1 else "Start the match"
	match step:
		"floor": _show_floors()
		"team": _show_teams()
		"heroes": _show_team_heroes() if mode != "quick" else _show_heroes()
		"troops": _show_team_troops() if mode != "quick" else _show_troops()
	_refresh_next()


func steps() -> Array:
	if mode == "deploy":
		return DEPLOY_STEPS
	if mode == "pvp":
		return TEAM_STEPS if pvp_player == 1 else PVP_SECOND
	return TEAM_STEPS if mode == "team" else STEPS


## "Bunker · floor 1 of 2 · Skull 3", or "Ambush · Skull 2".
## How many Heroes may enter: the floor's size says, and (0.36) a deployment's fight at Skull 1 or 2 lets two in.
func cap_of(f: FloorData) -> int:
	if f == null:
		return 1
	return Roster.deploy_capacity(f, deploy_spec.get("skull", 1)) if mode == "deploy" else Roster.hero_capacity(f)


func deploy_title() -> String:
	var sp := deploy_spec
	if sp.get("kind") == "poi":
		return "%s  \u00b7  floor %d of %d  \u00b7  Skull %d" % [str(sp.get("name", "POI")), int(sp.get("index", 0)) + 1, int(sp.get("count", 1)), int(sp.get("skull", 1))]
	return "Ambush  \u00b7  Skull %d" % int(sp.get("skull", 1))


## The floor being set up for.
func the_floor() -> FloorData:
	if mode == "deploy":
		return deploy_floor
	return floors[floor_i] if floor_i >= 0 and floor_i < floors.size() else null


## Sets up a deployment's fight: this floor, this Strike Team as it stands.
func begin_deploy(spec: Dictionary, f: FloorData, t: Dictionary) -> void:
	mode = "deploy"
	deploy_spec = spec
	deploy_floor = f
	deploy_team = t
	districts_cleared = 0
	wave_timer = 3
	_default_entry()
	step = "heroes"
	show_step()


func _refresh_next() -> void:
	match step:
		"floor": next_btn.disabled = floor_i < 0
		"team": next_btn.disabled = team() == null or not StrikeTeams.can_fight(team(), roster)
		"heroes": next_btn.disabled = heroes.is_empty()
		"troops": next_btn.disabled = heroes.is_empty()


## Starts setting up afresh: a Quick battle, or a Battle with these Strike Teams.
func begin(new_mode: String, saved_teams: Array = []) -> void:
	if new_mode != mode:
		heroes = []
		troops = {}
		troop_order = []
	mode = new_mode
	districts_cleared = 0
	teams = saved_teams
	pvp_player = 1
	pvp_first = {}
	if team_i >= teams.size():
		team_i = -1
	step = "floor"
	if roster != null:
		show_step()


func team() -> Variant:
	if mode == "deploy":
		return deploy_team
	return teams[team_i] if team_i >= 0 and team_i < teams.size() else null


func _show_floors() -> void:
	hint.text = ("Choose where to fight. Each player's Heroes enter by the floor's size; Player 1's team starts on its Player Spawn Tiles, Player 2's on its Enemy Spawn Tiles. No Enemy waves come. " if mode == "pvp" else "Choose where to fight. A floor's size decides how many Heroes may enter; Enemies come to its Enemy spawn tiles in six waves. " if mode == "team" else "Choose where to fight. A floor's size decides how many Heroes may enter; Enemies wait on its Enemy spawn tiles. ") + source
	for i in floors.size():
		var f: FloorData = floors[i]
		var cap := Roster.hero_capacity(f)
		var foes := 0
		for h in f.tiles:
			var lab := f.label_of(h).to_lower()
			if "enemy" in lab and "spawn" in lab:
				foes += 1
		var sub := "%d tiles · %s: %d Hero%s · %d Enemy spawn tile%s%s" % [f.tiles.size(), Roster.size_word(f).capitalize() if Roster.size_word(f) != "" else "Unsized", cap, "" if cap == 1 else "es", foes, "" if foes == 1 else "s", (" · District " + f.district) if f.district != "" else ""]
		var tag := "Test floor" if Rules.truthy(f.raw.get("testMap")) else ""
		_add_row({"floor": i}, f.name, sub, {}, i == floor_i, tag)


func _show_heroes() -> void:
	var f: FloorData = floors[floor_i]
	var cap := Roster.hero_capacity(f)
	var hs := roster.heroes()
	hint.text = "%s is %s, so %d Hero%s may enter. Tap to choose; %s" % [f.name, Roster.size_word(f).to_lower() if Roster.size_word(f) != "" else "sized by its tiles", cap, "" if cap == 1 else "es", ("%d chosen." % heroes.size()) if not heroes.is_empty() else "none chosen yet."]
	if hs.is_empty():
		hint.text = "The export has no Hero cards. Make one in the Companion, export again, and tap Look again on the first step."
	for c in hs:
		var n := str(c.get("name", ""))
		var u := Rules.unit_from_card(Roster.unit_spec(c), "ally")
		var sub := "Leadership %d · HP %d · AC %d · MS %d" % [Roster.leadership(c), u["hpMax"], u["ac"], u["ms"]]
		var tag := Roster.origin(c)
		var pos := heroes.find(n)
		_add_row({"hero": n}, n, sub, roster.token_for(c), pos >= 0, ("Chosen" if pos >= 0 else "") + (("  ·  " + tag) if tag != "" and pos >= 0 else tag))


func _show_troops() -> void:
	var ldr := pooled_leadership()
	var used := used_slots()
	var ts := roster.troops()
	hint.text = "Troops start beside your Heroes, on your spawn tiles. Their Unit Slots come out of your Heroes' pooled Leadership: %d of %d used. This step is optional." % [used, ldr]
	if ldr == 0:
		hint.text = "These Heroes have no Leadership, so no Troops can start beside them. Start the battle, or go Back and choose other Heroes."
	if ts.is_empty():
		hint.text += " The export has no Troop cards."
	for c in ts:
		var n := str(c.get("name", ""))
		var u := Rules.unit_from_card(Roster.unit_spec(c), "ally")
		var sl := Roster.slots(c)
		var sub := "%d Unit Slot%s · HP %d · AC %d · MS %d" % [sl, "" if sl == 1 else "s", u["hpMax"], u["ac"], u["ms"]]
		_add_row({"troop": n}, n, sub, roster.token_for(c), troops.get(n, 0) > 0, Roster.origin(c), troops.get(n, 0))


# ---------------------------------------------------------------- a Strike Team's steps
func _show_teams() -> void:
	hint.text = "Choose the Strike Team that goes in. It brings its Heroes, its Deck, its Aether Pouch and its Prototypes."
	if mode == "pvp":
		hint.text = "Player %d: choose your Strike Team. Every card is yours to use here. Strike Teams builds a new one, or changes one, and comes back.%s" % [pvp_player,
			(" Player 1 has %s." % str(pvp_first["team"].get("name", ""))) if pvp_player == 2 and pvp_first.get("team") is Dictionary else ""]
		_add_row({"build": true}, "Strike Teams", "Build a team, or change one, then come back to choose it", {}, false, "Open")
	if teams.is_empty():
		hint.text = "You have no Strike Teams yet. Go Home and build one under Strike Teams, or fight a Quick battle."
	for i in teams.size():
		var t: Dictionary = teams[i]
		var tally := StrikeTeams.tally(StrikeTeams.pings(t, roster))
		var hs: Array = t["heroes"]
		var sub := "%s \u00b7 Deck %d \u00b7 Pouch %d \u00b7 Level %d" % [(", ".join(hs)) if not hs.is_empty() else "No Hero", StrikeTeams.deck_count(t), StrikeTeams.pouch_count(t, roster), int(t["level"])]
		var state := "Has no Hero: it can't fight" if not StrikeTeams.can_fight(t, roster) else (("%d to fix" % tally["bad"]) if tally["bad"] > 0 else (("%d note%s" % [tally["warn"], "" if tally["warn"] == 1 else "s"]) if tally["warn"] > 0 else "Ready"))
		_add_row({"team": i}, str(t["name"]), sub, {}, i == team_i, state)
	if team() != null and StrikeTeams.can_fight(team(), roster):
		var bad := StrikeTeams.pings(team(), roster).filter(func(p): return p[0] == "bad")
		if not bad.is_empty():
			note.text = "%s: %s%s You can still fight." % [team()["name"], bad[0][1], (" (and %d more.)" % (bad.size() - 1)) if bad.size() > 1 else ""]


func choose_team(i: int) -> void:
	team_i = i
	_default_entry()
	var keep := list.scroll
	show_step()
	list.scroll_by(keep)


## Who enters unless told otherwise: the team's first Heroes, as many as the
## floor lets in, the first of them leading. No Starting Troops yet.
func _default_entry() -> void:
	heroes = []
	troops = {}
	troop_order = []
	leader = ""
	if team() == null or the_floor() == null:
		return
	var cap := cap_of(the_floor())
	for c in StrikeTeams.heroes(team(), roster):
		if heroes.size() < cap:
			heroes.append(str(c["name"]))
	leader = heroes[0] if not heroes.is_empty() else ""


func _show_team_heroes() -> void:
	var f: FloorData = the_floor()
	var cap := cap_of(f)
	var hs := StrikeTeams.heroes(team(), roster)
	hint.text = "%s lets %d Hero%s in. Tap a Hero to send it in or hold it back; tap Lead on one to put it in charge (Prototypes act through the leader). %d enter%s." % [f.name, cap, "" if cap == 1 else "es", heroes.size(), "s" if heroes.size() == 1 else ""]
	if mode == "deploy":
		hint.text += " A Hero who goes down here sits out the rest of the deployment. Enemies are %s, at Skull Level %d, in %d waves." % [("from District " + str(deploy_spec.get("district"))) if str(deploy_spec.get("district", "")) != "" else "from any District", int(deploy_spec.get("skull", 1)), Deployment.waves_for(deploy_spec.get("skull", 1), str(deploy_spec.get("kind", "ambush")))]
	for c in hs:
		var n := str(c.get("name", ""))
		var u := Rules.unit_from_card(Roster.unit_spec(c), "ally")
		var carried: int = team()["actions"].get(n, []).size()
		var sub := "Leadership %d \u00b7 HP %d \u00b7 AC %d \u00b7 MS %d%s" % [Roster.leadership(c), u["hpMax"], u["ac"], u["ms"], (" \u00b7 carries %d Action card%s" % [carried, "" if carried == 1 else "s"]) if carried > 0 else ""]
		var inn := heroes.has(n)
		_add_row({"hero": n}, n, sub, roster.token_for(c), inn, ("Leads" if n == leader else "Enters") if inn else "In reserve", null, "Lead" if inn and n != leader else "")


func set_leader(n: String) -> void:
	if heroes.has(n):
		leader = n
		var keep := list.scroll
		show_step()
		list.scroll_by(keep)


func _show_team_troops() -> void:
	var ldr := pooled_leadership()
	var used := used_slots()
	var ts := StrikeTeams.troops_in_deck(team(), roster)
	hint.text = "Starting Troops come out of the Deck and begin beside your Heroes at no Aether cost. Their Unit Slots come out of the pooled Leadership of the Heroes entering: %d of %d used. The rest deploy from your hand." % [used, ldr]
	if ts.is_empty():
		hint.text = "This team's Deck has no Troop cards, so nobody starts beside your Heroes."
	elif ldr == 0:
		hint.text = "The Heroes entering have no Leadership, so no Troops can start beside them."
	if mode == "deploy":
		hint.text += " A Troop that falls is gone for the rest of the deployment."
	elif mode != "pvp":
		hint.text += " Below: the wave timer and Districts cleared."
	for e in ts:
		var c: Dictionary = e["card"]
		var n := str(c.get("name", ""))
		var u := Rules.unit_from_card(Roster.unit_spec(c), "ally")
		var sl := Roster.slots(c)
		var sub := "%d Unit Slot%s \u00b7 HP %d \u00b7 AC %d \u00b7 MS %d \u00b7 %d in the Deck" % [sl, "" if sl == 1 else "s", u["hpMax"], u["ac"], u["ms"], e["copies"]]
		if u.get("x") != null:
			sub += " \u00b7 a variable cost: starting here, nobody pays, so X is 1"
		_add_row({"troop": n, "most": e["copies"]}, n, sub, roster.token_for(c), troops.get(n, 0) > 0, Roster.origin(c), troops.get(n, 0))
	if mode == "deploy" or mode == "pvp":
		return                # a deployment sets these itself: the timer is 3, and there is no Instability yet; (0.26) a match has no waves
	_add_row({"timer": true}, "Wave timer", "The next wave arrives when the board is clear, or after this many rounds. The Companion uses 3.", {}, false, "", wave_timer)
	_add_row({"timer": true, "districts": true}, "Districts cleared", instability_short(), {}, false, "", districts_cleared)


## Dimensional Instability, in a line: the chance, and what this floor's
## District has to send.
func instability_words() -> String:
	var pct := districts_cleared * 3
	var f: FloorData = floors[floor_i] if (floor_i >= 0 and floor_i < floors.size()) else null
	var d := f.district if f != null else ""
	var elites := 0
	var minis := 0
	for c in (roster.cards if roster != null else []):
		if d == "" or Roster.district_of(c) == d:
			if Roster.type_of(c) == "elite":
				elites += 1
			elif Roster.type_of(c) == "miniboss":
				minis += 1
	var where := ("District %s" % d) if d != "" else "This floor"
	var has := "%s has %d Elite%s and %d Mini-Boss%s to send" % [where, elites, "" if elites == 1 else "s", minis, "" if minis == 1 else "es"]
	if elites == 0 and minis == 0:
		has = "%s has no Elite or Mini-Boss, so the ordinary Enemy arrives each time" % where
	if pct == 0:
		return "Dimensional Instability: each District cleared adds 3% that a spawn brings an Elite or a Mini-Boss instead of the Enemy drawn. At 0, none will."
	return "Dimensional Instability: every spawn has a %d%% chance of bringing an Elite (two times in three) or a Mini-Boss in place of the Enemy drawn. %s." % [pct, has]


## The same, short enough for its row.
func instability_short() -> String:
	var pct := districts_cleared * 3
	if pct == 0:
		return "Dimensional Instability: none. Each District cleared adds 3%, up to 15%."
	return "Dimensional Instability: %d%% that a spawn brings an Elite or a Mini-Boss instead." % pct


func set_districts(n: int) -> void:
	districts_cleared = clampi(n, 0, 5)
	var keep := list.scroll
	show_step()
	list.scroll_by(keep)
	note.text = instability_words()


func set_wave_timer(n: int) -> void:
	wave_timer = clampi(n, 1, 10)
	var keep := list.scroll
	show_step()
	list.scroll_by(keep)


func pooled_leadership() -> int:
	var n := 0
	for h in heroes:
		var c = roster.card_named(h)
		if c != null:
			n += Roster.leadership(c)
	return n


func used_slots() -> int:
	var n := 0
	for t in troops:
		var c = roster.card_named(t)
		if c != null:
			n += Roster.slots(c) * int(troops[t])
	return n


# ---------------------------------------------------------------- a row
func _add_row(what: Dictionary, name: String, sub: String, look: Dictionary, chosen: bool, tag: String, count = null, action := "") -> void:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 78)
	var sb := PixelBox.new()
	sb.bg_color = Color("#282c3c") if chosen else Color("#171819")
	sb.border_color = CYAN if chosen else Color("#2c3b39")
	sb.set_border_width_all(3 if chosen else 1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12; sb.content_margin_right = 12; sb.content_margin_top = 6; sb.content_margin_bottom = 6
	row.add_theme_stylebox_override("panel", sb)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	row.add_child(hb)
	# (0.15) a floor wears its District's emblem; a Strike Team, its Heroes standing
	if what.has("floor"):
		var f: FloorData = floors[int(what["floor"])]
		var em := Control.new()
		em.custom_minimum_size = Vector2(48, 48)
		em.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		em.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var et: Texture2D = Art.icon2("district_" + f.district) if f.district != "" else null
		if et != null:
			var er := UI.pixels(et, 48)
			er.set_meta("district", f.district)
			em.add_child(er)
		hb.add_child(em)
	elif what.has("team"):
		var t = teams[int(what["team"])] if int(what["team"]) < teams.size() else {}
		hb.add_child(UI.team_tokens(t.get("heroes", []) if t is Dictionary else [], roster))
	if not what.has("floor") and not what.has("team") and not what.has("timer"):
		var pic := Control.new()
		pic.custom_minimum_size = Vector2(62, 62)
		pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if look.get("texture") != null:
			var tr := TextureRect.new()
			tr.texture = look["texture"]
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tr.set_anchors_preset(Control.PRESET_FULL_RECT)
			pic.add_child(tr)
		else:
			var lt := Label.new()
			lt.text = Roster.letters(name)
			lt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lt.set_anchors_preset(Control.PRESET_FULL_RECT)
			lt.add_theme_color_override("font_color", Color("#e6e7f0"))
			pic.add_child(lt)
		hb.add_child(pic)
	var txt := VBoxContainer.new()
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	txt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	txt.add_theme_constant_override("separation", 2)
	hb.add_child(txt)
	var nl := Label.new()
	nl.text = name
	nl.clip_text = true
	txt.add_child(nl)
	var sl := Label.new()
	sl.text = sub
	sl.clip_text = true
	sl.add_theme_font_size_override("font_size", Look.fs(16))
	sl.add_theme_color_override("font_color", DIM)
	txt.add_child(sl)
	if tag != "":
		hb.add_child(UI.tag(tag, CYAN if chosen else WARN))
	var entry := what.duplicate()
	if action != "":
		var act := _count_box(action)
		act.custom_minimum_size.x = 104
		act.get_child(0).add_theme_font_size_override("font_size", Look.fs(20))
		hb.add_child(act)
		entry["action"] = act
	if count != null:
		var minus := _count_box("−")
		var num := Label.new()
		num.text = str(count)
		num.custom_minimum_size = Vector2(44, 0)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		num.add_theme_font_size_override("font_size", Look.fs(24))
		var plus := _count_box("+")
		hb.add_child(minus)
		hb.add_child(num)
		hb.add_child(plus)
		entry["minus"] = minus
		entry["plus"] = plus
	entry["row"] = row
	_rows.append(entry)
	list.add_row(row)


func _count_box(sign_text: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(64, 60)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb := PixelBox.new()
	sb.bg_color = Color("#2c3438")
	sb.set_corner_radius_all(6)
	p.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = sign_text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", Look.fs(30))
	p.add_child(l)
	return p


func _hit(entry: Dictionary, key: String, at: Vector2) -> bool:
	var c: Control = entry.get(key)
	if c == null:
		return false
	var row: Control = entry["row"]
	return Rect2(c.global_position - row.global_position, c.size).grow(6).has_point(at)


# ---------------------------------------------------------------- choosing
func _on_row(i: int, at: Vector2) -> void:
	if i < 0 or i >= _rows.size():
		return
	var e: Dictionary = _rows[i]
	if e.has("floor"):
		choose_floor(e["floor"])
	elif e.has("team"):
		choose_team(e["team"])
	elif e.has("build"):
		teams_requested.emit()
	elif e.has("districts"):
		set_districts(districts_cleared + (-1 if _hit(e, "minus", at) else (1 if _hit(e, "plus", at) else 0)))
	elif e.has("timer"):
		set_wave_timer(wave_timer + (-1 if _hit(e, "minus", at) else (1 if _hit(e, "plus", at) else 0)))
	elif e.has("hero"):
		if e.has("action") and _hit(e, "action", at):
			set_leader(e["hero"])
		else:
			toggle_hero(e["hero"])
	elif e.has("troop"):
		if _hit(e, "minus", at):
			less_troop(e["troop"])
		else:
			more_troop(e["troop"])


func choose_floor(i: int) -> void:
	floor_i = i
	# a smaller floor lets fewer Heroes in
	var cap := Roster.hero_capacity(floors[i])
	if mode == "team" or mode == "pvp":
		_default_entry()
	elif heroes.size() > cap:
		heroes = heroes.slice(0, cap)
		_trim_troops()
	var keep := list.scroll
	show_step()
	list.scroll_by(keep)


func toggle_hero(n: String) -> void:
	var keep := list.scroll
	var at := heroes.find(n)
	var cap := cap_of(the_floor())
	var msg := ""
	if at >= 0:
		heroes.remove_at(at)
		_trim_troops()
		if leader == n:
			leader = heroes[0] if not heroes.is_empty() else ""
	elif heroes.size() >= cap:
		msg = "Only %d Hero%s may enter %s. Tap a chosen one to leave it behind first." % [cap, "" if cap == 1 else "es", the_floor().name]
	else:
		heroes.append(n)
		if mode != "quick":
			# kept in the team's own order, as they will stand
			var order: Array = StrikeTeams.heroes(team(), roster).map(func(c): return str(c["name"]))
			heroes.sort_custom(func(a, b): return order.find(a) < order.find(b))
			if leader == "":
				leader = n
	show_step()
	list.scroll_by(keep)
	note.text = msg


func more_troop(n: String) -> void:
	var c = roster.card_named(n)
	if c == null:
		return
	var keep := list.scroll
	var sl := Roster.slots(c)
	var left := pooled_leadership() - used_slots()
	var msg := ""
	var in_deck := StrikeTeams.copies(team(), n) if mode != "quick" else 1 << 30
	if troops.get(n, 0) >= in_deck:
		msg = "The Deck holds %d %s, and %s already starting." % [in_deck, n, "it is" if in_deck == 1 else "they are all"]
	elif sl > left:
		msg = "%s takes %d Unit Slot%s, and only %d of %d %s left." % [n, sl, "" if sl == 1 else "s", left, pooled_leadership(), "is" if left == 1 else "are"]
	else:
		troops[n] = troops.get(n, 0) + 1
		if not troop_order.has(n):
			troop_order.append(n)
	show_step()
	list.scroll_by(keep)
	note.text = msg


func less_troop(n: String) -> void:
	var keep := list.scroll
	if troops.get(n, 0) > 0:
		troops[n] -= 1
		if troops[n] == 0:
			troops.erase(n)
			troop_order.erase(n)
	show_step()
	list.scroll_by(keep)


## Fewer Heroes may mean less Leadership: the last Troops chosen step down.
func _trim_troops() -> void:
	if roster == null:
		return
	var ldr := pooled_leadership()
	while used_slots() > ldr and not troop_order.is_empty():
		var n: String = troop_order[troop_order.size() - 1]
		troops[n] -= 1
		if troops[n] <= 0:
			troops.erase(n)
			troop_order.remove_at(troop_order.size() - 1)


func _go(d: int) -> void:
	var i := steps().find(step) + d
	if i < 0 and mode == "pvp" and pvp_player == 2:
		_pvp_back()
		return
	if i < 0:
		closed.emit()
		return
	if i >= steps().size() and mode == "pvp" and pvp_player == 1:
		if next_btn.disabled:
			return
		_pvp_next()
		return
	if i >= steps().size():
		start()
		return
	if d > 0 and next_btn.disabled:
		return
	step = steps()[i]
	show_step()


## (0.26) Player 1 has chosen: their choices are kept, and Player 2 chooses theirs.
func _pvp_next() -> void:
	pvp_first = {"team_i": team_i, "team": team(), "heroes": heroes.duplicate(), "leader": leader, "troops": troops.duplicate(), "troop_order": troop_order.duplicate(),
		"setup": StrikeTeams.setup_for(team(), roster, heroes, leader, _starters(), 0, 0)}
	pvp_player = 2
	team_i = -1
	heroes = []
	troops = {}
	troop_order = []
	leader = ""
	step = "team"
	show_step()


## Back from Player 2's first step: Player 1's choices, as they were.
func _pvp_back() -> void:
	pvp_player = 1
	team_i = int(pvp_first.get("team_i", -1))
	heroes.assign(pvp_first.get("heroes", []))
	leader = str(pvp_first.get("leader", ""))
	troops = pvp_first.get("troops", {})
	troop_order.assign(pvp_first.get("troop_order", []))
	step = "troops"
	show_step()


## Back from Strike Teams: the teams read again, and the step as it was.
func resume(saved_teams: Array) -> void:
	teams = saved_teams
	if team_i >= teams.size():
		team_i = -1
	show_step()


func _starters() -> Array:
	var out := []
	for n in troop_order:
		for k in troops.get(n, 0):
			out.append(n)
	return out


## The chosen cards, Heroes then Troops (one entry per Troop brought).
func start() -> void:
	if the_floor() == null or heroes.is_empty():
		return
	if mode == "pvp":
		pvp_start_requested.emit(floor_i, pvp_first["team"], pvp_first["setup"], team(), StrikeTeams.setup_for(team(), roster, heroes, leader, _starters(), 0, 0))
		return
	if mode != "quick":
		var starters := []
		for n in troop_order:
			for k in troops.get(n, 0):
				starters.append(n)
		if mode == "deploy":
			deploy_start_requested.emit(team(), StrikeTeams.setup_for(team(), roster, heroes, leader, starters, 3, 0))
		else:
			team_start_requested.emit(floor_i, team(), StrikeTeams.setup_for(team(), roster, heroes, leader, starters, wave_timer, districts_cleared * 3))
		return
	var hc := []
	for n in heroes:
		hc.append(roster.card_named(n))
	var tc := []
	for n in troop_order:
		for k in troops.get(n, 0):
			tc.append(roster.card_named(n))
	start_requested.emit(floor_i, hc, tc)
