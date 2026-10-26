## Your Strike Teams: every team you've built, each with what it holds and
## whether the rules have anything to say about it. Tap one to build on it;
## New team starts another; a team can be copied or deleted. Teams are kept on
## the phone, and outlive a new export.
## (0.35) With no Strike Team yet, opening it walks a first team through being
## built, one step at a time (team_guide.gd); Walk me through starts that
## again while no team is ready.
class_name TeamsScreen
extends Control

signal closed

var roster: Roster
var teams: Array = []
## Says whether a team is out on a deployment (the main scene sets it). One
## that is can be copied, and nothing else, until it is home.
var locked: Callable = Callable()
## (0.25) Says whether a Hero can lead a team out (the main scene sets it):
## a free one, or one recruited at the dock. Practice fights take any Hero.
var owns: Callable = Callable()
var editing := -1
var editor: TeamEditor
var list: TouchList
var hint: Label
var note: Label
var back_btn: Button
var new_btn: Button
var guide_btn: Button
## (0.35) Whether opening with no team starts the walk-through (the tests turn it off).
static var auto_guide := true
var dialog: Dialog = null
var namer: NameDialog = null
var _rows: Array = []
var _page: VBoxContainer


func _init() -> void:
	_page = UI.page(self)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 24)
	_page.add_child(head)
	head.add_child(UI.label("Strike Teams", 30, UI.CYAN))
	hint = UI.label("", 18, UI.PALE, true)
	_page.add_child(hint)
	list = TouchList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.row_tapped.connect(_on_row)
	_page.add_child(list)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 14)
	_page.add_child(foot)
	back_btn = UI.button("Back", func(): closed.emit())
	foot.add_child(back_btn)
	note = UI.label("", 17, UI.GOLD, true)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	foot.add_child(note)
	guide_btn = UI.button("Walk me through", func(): start_guide(), 230)
	foot.add_child(guide_btn)
	new_btn = UI.button("New team", ask_new, 200)
	new_btn.theme_type_variation = "MainButton"     # (0.15) the one thing to do next
	foot.add_child(new_btn)
	editor = TeamEditor.new()
	editor.visible = false
	editor.changed.connect(save)
	editor.closed.connect(close_editor)
	editor.guide_done.connect(_guide_done)
	add_child(editor)


## Shows the saved teams (read afresh), for this export's cards.
func open(r: Roster) -> void:
	roster = r
	teams = StrikeTeams.load_all()
	editing = -1
	editor.visible = false
	show_list()
	note.text = StrikeTeams.error
	if teams.is_empty() and auto_guide:
		start_guide()


func save() -> void:
	if not StrikeTeams.save_all(teams):
		note.text = StrikeTeams.error


# ---------------------------------------------------------------- the list
func show_list() -> void:
	var keep := list.scroll
	list.clear()
	_rows = []
	hint.text = "A Strike Team is up to 3 Heroes, one Deck they share, the Action cards each carries, an Aether Pouch, any Prototypes and its Consumables. Tap a team to build on it." if not teams.is_empty() else "No Strike Teams yet. Tap Walk me through to build your first one step at a time, or New team to build it your own way."
	guide_btn.visible = not any_ready()
	for i in teams.size():
		var t: Dictionary = teams[i]
		var tally := StrikeTeams.tally(StrikeTeams.pings(t, roster))
		var hs: Array = t["heroes"]
		var sub := "%s · Deck %d · Pouch %d · Level %d" % [(", ".join(hs)) if not hs.is_empty() else "No Hero", StrikeTeams.deck_count(t), StrikeTeams.pouch_count(t, roster), int(t["level"])]
		var state := ("%d to fix" % tally["bad"]) if tally["bad"] > 0 else (("%d note%s" % [tally["warn"], "" if tally["warn"] == 1 else "s"]) if tally["warn"] > 0 else "Ready")
		if is_locked(i):
			_add_row(i, str(t["name"]), sub, "Out on a deployment", UI.CYAN, hs)
			continue
		if t.has("guide"):
			_add_row(i, str(t["name"]), sub, "Being built · step %d of %d" % [clampi(int(Rules.num(t["guide"], 0)), 0, TeamGuide.count() - 1) + 1, TeamGuide.count()], UI.GOLD, hs)
			continue
		var unrecruited := unowned(t)
		if tally["bad"] == 0 and not unrecruited.is_empty():
			_add_row(i, str(t["name"]), sub, "Recruit %s to deploy" % ", ".join(unrecruited), UI.GOLD, hs)
			continue
		_add_row(i, str(t["name"]), sub, state, UI.SOFT_RED if tally["bad"] > 0 else (UI.GOLD if tally["warn"] > 0 else UI.GREEN), hs)
	list.scroll_by(keep)


func _add_row(i: int, name: String, sub: String, state: String, colour: Color, heroes: Array = []) -> void:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 84)
	row.add_theme_stylebox_override("panel", UI.box(UI.PANEL, UI.LINE, 1, 6, 14))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	row.add_child(hb)
	# (0.15) its Heroes, standing
	hb.add_child(UI.team_tokens(heroes, roster))
	var txt := VBoxContainer.new()
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	txt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	txt.add_theme_constant_override("separation", 2)
	hb.add_child(txt)
	var nl := UI.label(name, 22)
	nl.clip_text = true
	txt.add_child(nl)
	var sl := UI.label(sub, 16, UI.DIM)
	sl.clip_text = true
	txt.add_child(sl)
	hb.add_child(UI.tag(state, colour))
	var copy := _box("Copy")
	hb.add_child(copy)
	var del := _box("Delete")
	hb.add_child(del)
	_rows.append({"team": i, "row": row, "copy": copy, "delete": del})
	list.add_row(row)


func _box(text: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(104, 58)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_theme_stylebox_override("panel", UI.box(Color("#2c3438"), UI.LINE, 1, 6, 6))
	var l := UI.label(text, 18)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


func _hit(e: Dictionary, key: String, at: Vector2) -> bool:
	var c: Control = e[key]
	var row: Control = e["row"]
	return Rect2(c.global_position - row.global_position, c.size).grow(6).has_point(at)


func _on_row(i: int, at: Vector2) -> void:
	if i < 0 or i >= _rows.size() or dialog != null or namer != null:
		return
	var e: Dictionary = _rows[i]
	if _hit(e, "copy", at):
		copy_team(e["team"])
	elif is_locked(e["team"]):
		note.text = "%s is out on a deployment. It can be changed, or deleted, once it is home; a copy of it can be changed now." % teams[e["team"]]["name"]
	elif _hit(e, "delete", at):
		ask_delete(e["team"])
	else:
		edit(e["team"])


## Whether a team is out on a deployment.
## (0.25) The team's Heroes that can't lead it out until they're recruited.
func unowned(t: Dictionary) -> Array:
	if not owns.is_valid():
		return []
	return t.get("heroes", []).filter(func(n): return roster.card_named(str(n)) != null and not owns.call(str(n)))


func is_locked(i: int) -> bool:
	return i >= 0 and i < teams.size() and locked.is_valid() and locked.call(teams[i])


# ---------------------------------------------------------------- teams
func ask_new() -> void:
	if namer != null:
		return
	namer = NameDialog.new("Name the new Strike Team", StrikeTeams.free_name(teams, "Strike Team"), "You can rename it at any time.")
	namer.named.connect(func(t):
		_end_namer()
		edit(new_team(t)))
	namer.cancelled.connect(_end_namer)
	add_child(namer)


func _end_namer() -> void:
	if namer != null:
		Motion.pop_out(namer, namer.get_meta("box", null))
		namer = null


## Adds an empty team and returns where it is.
func new_team(name: String) -> int:
	teams.append(StrikeTeams.blank(StrikeTeams.free_name(teams, name.strip_edges() if name.strip_edges() != "" else "Strike Team")))
	save()
	show_list()
	return teams.size() - 1


func copy_team(i: int) -> int:
	teams.append(StrikeTeams.copy_of(teams[i], StrikeTeams.free_name(teams, str(teams[i]["name"]) + " copy")))
	save()
	show_list()
	note.text = "%s copied." % teams[i]["name"]
	return teams.size() - 1


func ask_delete(i: int) -> void:
	if dialog != null:
		return
	dialog = Dialog.new("Delete this Strike Team?", "%s will be gone for good. Its cards stay in your export." % teams[i]["name"], ["Keep it", "Delete"], UI.SOFT_RED)
	dialog.chosen.connect(func(k):
		Motion.pop_out(dialog, dialog.get_meta("box", null))
		dialog = null
		if k == 1:
			delete_team(i))
	add_child(dialog)


func delete_team(i: int) -> void:
	var name := str(teams[i]["name"])
	teams.remove_at(i)
	save()
	show_list()
	note.text = "%s deleted." % name


func edit(i: int, guided := false) -> void:
	if is_locked(i):
		return
	editing = i
	editor.owns = owns
	editor.open(roster, teams[i], guided)
	editor.visible = true


## (0.35) Whether some team is built: a Hero, a Deck of 10 or more, and not still in the walk-through.
func any_ready() -> bool:
	return teams.any(func(t): return not t.has("guide") and not t.get("heroes", []).is_empty() and StrikeTeams.deck_count(t) >= 10)


## (0.35) A new team, built in the walk-through.
func start_guide() -> void:
	if dialog != null or namer != null:
		return
	edit(new_team("Strike Team"), true)
	save()           # the step is kept on the team: it picks up there if it's left


func _guide_done() -> void:
	var nm := str(teams[editing]["name"]) if editing >= 0 and editing < teams.size() else "The team"
	close_editor()
	note.text = "%s is built. Tap it to change it, or take it out from the dock's Deploy." % nm


func close_editor() -> void:
	editing = -1
	editor.visible = false
	save()
	show_list()
