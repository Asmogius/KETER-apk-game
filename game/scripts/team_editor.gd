## Building a Strike Team: its Heroes, its Deck, the Action cards each Hero
## carries, its Aether Pouch, its Prototypes, its Consumables and its Player
## Level. Cards are tiles; tap one to read it in full and add it, take it off,
## or set how many. A tile whose text is partly plain says so: that text won't
## happen in a fight.
## The Checks tab lists what the Handbook has to say about the team as it
## stands. Nothing there blocks: only a team with no Hero can't fight.
## Every change is kept as it's made (the changed signal).
## (0.35) Opened guided, it walks a first team through its steps one at a time
## (team_guide.gd): the tabs give way to a bar that says what the step is for
## and what it still needs, with Back and Next. The step is kept on the team
## (guide), so opening it again picks up where it was left.
class_name TeamEditor
extends Control

signal changed
signal closed
signal guide_done

const TABS := ["heroes", "deck", "carried", "pouch", "protos", "consumables", "checks"]
const FILTERS := ["all", "troop", "equipment", "command", "aether"]
const MAX_COPIES := StrikeTeams.MAX_COPIES      # (0.36) 4 of a card; it was 60
const MAX_CHIPS := 30
const MAX_CONSUMABLES := 9

var roster: Roster
## (0.25) Says whether a Hero can lead the team out on a deployment (a free
## one, or one recruited at the dock); the others are marked, and fight only
## practice battles.
var owns: Callable = Callable()
var team: Dictionary = {}
var tab := "heroes"
var deck_filter := "all"
var deck_only := false          # See Deck: only the cards in it
var carrier := ""               # the Hero whose Action cards are being chosen
var sheet: CardSheet = null
var rename: NameDialog = null

var back_btn: Button
var name_btn: Button
var level_label: Label
var tab_btns := {}
var sub: HBoxContainer          # the row under the tabs: filters, the Hero carrying
var hint: Label
var grid: CardGrid
var checks: TouchList
var _shown: Array = []          # what each tile stands for: a card, or a chip's key
var guide := -1                 # (0.35) the walk-through's step, or -1 when it isn't guided
var tabs_row: HBoxContainer
var guide_bar: PanelContainer
var guide_title: Label
var guide_text: Label
var guide_need: Label
var guide_back: Button
var guide_extra: Button
var guide_next: Button


func _init() -> void:
	var col := UI.page(self)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	col.add_child(head)
	back_btn = UI.button("‹ Teams", func(): closed.emit(), 130)
	head.add_child(back_btn)
	name_btn = UI.button("", ask_name, 300)
	name_btn.add_theme_font_size_override("font_size", Look.fs(24))
	name_btn.add_theme_color_override("font_color", UI.CYAN)
	head.add_child(name_btn)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(gap)
	head.add_child(UI.label("Player Level", 18, UI.PALE))
	head.add_child(UI.button("−", func(): set_level(int(team["level"]) - 1), 64))
	level_label = UI.label("1", 28, UI.GOLD)
	level_label.custom_minimum_size = Vector2(40, 0)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(level_label)
	head.add_child(UI.button("+", func(): set_level(int(team["level"]) + 1), 64))

	_build_guide_bar(col)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	tabs_row = tabs
	col.add_child(tabs)
	for t in TABS:
		var k: String = t
		var b := UI.button("", func(): open_tab(k), 110)
		b.add_theme_font_size_override("font_size", Look.fs(19))
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
		tab_btns[k] = b

	sub = HBoxContainer.new()
	sub.add_theme_constant_override("separation", 8)
	col.add_child(sub)
	hint = UI.label("", 17, UI.PALE, true)
	col.add_child(hint)
	grid = CardGrid.new()
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.card_tapped.connect(tap_card)
	col.add_child(grid)
	checks = TouchList.new()
	checks.size_flags_vertical = Control.SIZE_EXPAND_FILL
	checks.visible = false
	col.add_child(checks)


func open(r: Roster, t: Dictionary, guided := false) -> void:
	roster = r
	team = t
	if guided:
		t["guide"] = 0
	var gv = Rules.num(t.get("guide"), -1) if t.has("guide") else -1
	guide = clampi(int(gv), 0, TeamGuide.count() - 1) if gv >= 0 else -1
	tab = "heroes" if guide < 0 else str(TeamGuide.STEPS[guide]["tab"])
	deck_filter = "all"
	deck_only = false
	carrier = ""
	_close_sheet()
	refresh(false)


# ---------------------------------------------------------------- what it shows
func refresh(keep_place := true) -> void:
	name_btn.text = str(team.get("name", "")) + "  ·  rename"
	level_label.text = str(team.get("level", 1))
	var list := StrikeTeams.pings(team, roster)
	var tally := StrikeTeams.tally(list)
	var names := {"heroes": "Heroes %d" % team["heroes"].size(), "deck": "Deck %d" % StrikeTeams.deck_count(team), "carried": "Carried %d" % _carried_count(),
		"pouch": "Pouch %d" % StrikeTeams.pouch_count(team, roster), "protos": "Prototypes %d" % team["protos"].size(),
		"consumables": "Consumables %d" % StrikeTeams.consumable_count(team, roster),
		"checks": "Checks" + ((" · %d to fix" % tally["bad"]) if tally["bad"] > 0 else (" · %d note%s" % [tally["warn"], "" if tally["warn"] == 1 else "s"] if tally["warn"] > 0 else " · fine"))}
	for k in tab_btns:
		tab_btns[k].text = names[k]
		tab_btns[k].set_pressed_no_signal(k == tab)
	tab_btns["checks"].add_theme_color_override("font_color", UI.SOFT_RED if tally["bad"] > 0 else (UI.GOLD if tally["warn"] > 0 else UI.GREEN))
	for c in sub.get_children():
		sub.remove_child(c)
		c.queue_free()
	_show_guide()
	grid.visible = tab != "checks" and tab != ""
	checks.visible = tab == "checks"
	_shown = []
	if tab == "":
		hint.text = ""
	match tab:
		"heroes": _show_heroes(keep_place)
		"deck": _show_deck(keep_place)
		"carried": _show_carried(keep_place)
		"pouch": _show_pouch(keep_place)
		"protos": _show_protos(keep_place)
		"consumables": _show_consumables(keep_place)
		"checks": _show_checks(list)


func open_tab(t: String) -> void:
	tab = t
	refresh(false)


# ---------------------------------------------------------------- (0.35) the walk-through
func _build_guide_bar(col: Control) -> void:
	guide_bar = PanelContainer.new()
	guide_bar.add_theme_stylebox_override("panel", UI.box(UI.PANEL_LIT, UI.GOLD, 2, 6, 12))
	guide_bar.visible = false
	col.add_child(guide_bar)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	guide_bar.add_child(v)
	guide_title = UI.label("", 22, UI.GOLD)
	v.add_child(guide_title)
	guide_text = UI.label("", 17, UI.TEXT, true)
	v.add_child(guide_text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	guide_back = UI.button("‹ Back", func(): guide_step(-1), 140)
	row.add_child(guide_back)
	guide_extra = UI.button("", guide_suggest, 230)
	row.add_child(guide_extra)
	guide_need = UI.label("", 17, UI.SOFT_RED, true)
	guide_need.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guide_need.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(guide_need)
	guide_next = UI.button("Next ›", func(): guide_step(1), 170)
	guide_next.theme_type_variation = "MainButton"
	row.add_child(guide_next)


func _show_guide() -> void:
	var on := guide >= 0
	guide_bar.visible = on
	tabs_row.visible = not on
	if not on:
		return
	var st: Dictionary = TeamGuide.STEPS[guide]
	guide_title.text = "Step %d of %d · %s" % [guide + 1, TeamGuide.count(), st["title"]]
	guide_text.text = str(st["text"])
	var need := TeamGuide.needs(guide, team, roster)
	guide_need.text = need
	guide_next.text = "Finish" if guide == TeamGuide.count() - 1 else "Next ›"
	guide_next.disabled = need != ""
	guide_back.disabled = guide == 0
	var extra: String = {"name": "Name it", "deck": "Suggest a Deck", "pouch": "Suggest a Pouch"}.get(str(st["id"]), "")
	guide_extra.text = extra
	guide_extra.visible = extra != ""


## Back (-1) or Next (+1). Next goes on only once the step has what it needs; past the last step the walk-through is done.
func guide_step(by: int) -> void:
	if guide < 0:
		return
	if by > 0 and TeamGuide.needs(guide, team, roster) != "":
		return
	var to := guide + by
	if to >= TeamGuide.count():
		guide = -1
		team.erase("guide")
		tab = "heroes"
		changed.emit()
		refresh(false)
		guide_done.emit()
		return
	guide = clampi(to, 0, TeamGuide.count() - 1)
	team["guide"] = guide
	changed.emit()
	tab = str(TeamGuide.STEPS[guide]["tab"])
	refresh(false)


## The step's own button: name it, or suggest a Deck or a Pouch.
func guide_suggest() -> void:
	if guide < 0:
		return
	match str(TeamGuide.STEPS[guide]["id"]):
		"name":
			ask_name()
		"deck":
			if TeamGuide.suggest_deck(team, roster) > 0:
				_touch()
		"pouch":
			if TeamGuide.suggest_pouch(team, roster) > 0:
				_touch()


func _carried_count() -> int:
	var n := 0
	for h in team["actions"]:
		n += team["actions"][h].size()
	return n


func _item(c: Dictionary, extra: Dictionary = {}) -> Dictionary:
	var it := {"card": c, "art": roster.art_for(c), "plain": not ["hero", "troop"].has(Roster.type_of(c)) and Roster.has_plain_text(c)}
	it.merge(extra)
	return it


## Cards the team names that the export no longer has, as tiles that say so.
func _gone_items(names: Array, extra: Callable = Callable()) -> Array:
	var out := []
	for n in names:
		if roster.card_named(Roster.ref_name(str(n))) == null and not str(n).begins_with("basic|"):
			var it := {"card": {"name": str(n), "cardType": ""}, "art": null, "gone": true}
			if extra.is_valid():
				it.merge(extra.call(str(n)))
			out.append(it)
			_shown.append({"gone": str(n)})
	return out


func _show_heroes(keep: bool) -> void:
	var n: int = team["heroes"].size()
	hint.text = "Up to 3 Heroes share the team's Deck. A floor lets in 1, 2 or 3 of them by its size; the rest wait in reserve. Tap a Hero to read it and add it. %s" % (("%d in the team." % n) if n > 0 else "None in the team yet.")
	if owns.is_valid():
		hint.text += " A Hero marked Not recruited fights practice battles; to deploy with them, recruit them at the dock."
	var items := _gone_items(team["heroes"], func(_n): return {"mark": "In team"})
	for c in roster.heroes():
		var at: int = team["heroes"].find(c["name"])
		var mark := ("In team · %d" % (at + 1)) if at >= 0 else ""
		if owns.is_valid() and not owns.call(str(c["name"])):
			mark = (mark + " · " if mark != "" else "") + "Not recruited"
		items.append(_item(c, {"chosen": at >= 0, "mark": mark}))
		_shown.append({"card": c})
	grid.empty_text = "The export has no Hero cards."
	grid.set_items(items, keep)


func _chip(text: String, on: bool, fn: Callable, width := 130.0) -> Button:
	var b := UI.button(text, fn, width)
	b.toggle_mode = true
	b.set_pressed_no_signal(on)
	b.custom_minimum_size.y = 52
	sub.add_child(b)
	return b


func _show_deck(keep: bool) -> void:
	for f in FILTERS:
		var k: String = f
		_chip("All" if f == "all" else str(UI.TYPE_NAME[f]), deck_filter == f, func(): set_filter(k))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.add_child(gap)
	_chip("See Deck", deck_only, func(): set_deck_only(not deck_only), 150)
	var n := StrikeTeams.deck_count(team)
	hint.text = "The Deck holds %d card%s; a Deck is 10 to 60, and 4 copies of a card at most. Troop, Equipment, Command and Aether cards go in it. Tap a card to read it and set how many copies." % [n, "" if n == 1 else "s"]
	var items := _gone_items(team["deck"].keys(), func(nm): return {"count": StrikeTeams.copies(team, nm)})
	for c in roster.of_types(StrikeTeams.DECK_TYPES):
		var k := StrikeTeams.copies(team, c["name"])
		if (deck_filter != "all" and Roster.type_of(c) != deck_filter) or (deck_only and k == 0):
			continue
		items.append(_item(c, {"count": k, "chosen": k > 0}))
		_shown.append({"card": c})
	grid.empty_text = "The Deck is empty. Turn off See Deck to choose cards." if deck_only else "The export has no cards of this kind."
	grid.set_items(items, keep)


func set_filter(f: String) -> void:
	deck_filter = f
	refresh(false)


func set_deck_only(on: bool) -> void:
	deck_only = on
	refresh(false)


func _show_carried(keep: bool) -> void:
	var hs := StrikeTeams.heroes(team, roster)
	if hs.is_empty():
		hint.text = "Action cards are carried by a Hero, never put in the Deck. Add a Hero to the team first."
		grid.empty_text = ""
		grid.set_items([], false)
		return
	if not hs.any(func(h): return h["name"] == carrier):
		carrier = hs[0]["name"]
	for h in hs:
		var nm: String = h["name"]
		_chip("%s  %d/%d" % [nm, team["actions"].get(nm, []).size(), StrikeTeams.action_slots(h)], carrier == nm, func(): set_carrier(nm), 220)
	var hero = roster.card_named(carrier)
	var has: Array = team["actions"].get(carrier, [])
	var slots := StrikeTeams.action_slots(hero)
	hint.text = "%s carries %d Action card%s and has %d Action Slot%s. A carried Action card is one of that Hero's Actions in a fight. Tap a card to read it and give it to %s." % [carrier, has.size(), "" if has.size() == 1 else "s", slots, "" if slots == 1 else "s", carrier]
	var items := _gone_items(has, func(_n): return {"mark": "Carried"})
	for c in roster.of_types(["action"]):
		var on := has.has(c["name"])
		items.append(_item(c, {"chosen": on, "mark": "Carried" if on else ""}))
		_shown.append({"card": c})
	grid.empty_text = "The export has no Action cards."
	grid.set_items(items, keep)


func set_carrier(n: String) -> void:
	carrier = n
	refresh(false)


func _show_pouch(keep: bool) -> void:
	var have := StrikeTeams.pouch_count(team, roster)
	var need := StrikeTeams.pouch_minimum(team, roster)
	hint.text = "The Pouch holds %d Chip%s. Each round, Chips equal to the Player Level (%d) are drawn into the Bank, where each generates its Aether every round after. %s" % [have, "" if have == 1 else "s", int(team["level"]),
		("The Deck's most expensive card costs %d, so the Pouch needs at least %d." % [need, need]) if need > 0 else "With no Deck yet, any number will do."]
	var items := _gone_items(team["pouch"].keys(), func(nm): return {"count": int(Rules.num(team["pouch"].get(nm), 0))})
	for d in StrikeTeams.DISTRICTS:
		var chip := StrikeTeams.basic_chip(d)
		var k := int(Rules.num(team["pouch"].get(chip["key"]), 0))
		items.append({"card": chip, "art": null, "count": k, "chosen": k > 0})
		_shown.append({"chip": chip["key"], "card": chip})
	for c in roster.of_types(["sphere"]):
		var k2 := int(Rules.num(team["pouch"].get(c["name"]), 0))
		items.append(_item(c, {"count": k2, "chosen": k2 > 0}))
		_shown.append({"chip": c["name"], "card": c})
	grid.empty_text = ""
	grid.set_items(items, keep)


func _show_protos(keep: bool) -> void:
	hint.text = "Prototypes belong to the Strike Team, not the Deck. Their Passives are always on in a fight, acting through the team's leader. Tap one to read it and add it."
	var items := _gone_items(team["protos"], func(_n): return {"mark": "In team"})
	for c in roster.of_types(["prototype"]):
		var on: bool = team["protos"].has(c["name"])
		items.append(_item(c, {"chosen": on, "mark": "In team" if on else ""}))
		_shown.append({"card": c})
	grid.empty_text = "The export has no Prototype cards."
	grid.set_items(items, keep)


func _show_consumables(keep: bool) -> void:
	var kinds := StrikeTeams.consumable_entries(team, roster).size()
	hint.text = "Consumables go into every Battle this team fights. Each is used once, on your turn, at no Aether cost. Only 3 kinds may be brought to a battle; this team carries %d. Tap one to read it and set how many." % kinds
	var items := _gone_items(team["consumables"].keys(), func(nm): return {"count": int(Rules.num(team["consumables"].get(nm), 0))})
	for c in roster.of_types(["consumable"]):
		var k := int(Rules.num(team["consumables"].get(c["name"]), 0))
		items.append(_item(c, {"count": k, "chosen": k > 0}))
		_shown.append({"card": c})
	grid.empty_text = "The export has no Consumable cards."
	grid.set_items(items, keep)


func _show_checks(list: Array) -> void:
	hint.text = "What the rules say about this team as it stands. None of it stops you: only a team with no Hero can't fight."
	checks.clear()
	if list.is_empty():
		checks.add_row(UI.label("Nothing to say.", 18, UI.DIM))
	for p in list:
		var row := PanelContainer.new()
		var colour: Color = {"bad": UI.SOFT_RED, "warn": UI.GOLD}.get(p[0], UI.DIM)
		row.add_theme_stylebox_override("panel", UI.box(UI.PANEL, colour.darkened(0.3), 1, 6, 14))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		row.add_child(v)
		var l := UI.label(("To fix: " if p[0] == "bad" else ("Note: " if p[0] == "warn" else "")) + str(p[1]), 18, colour if p[0] != "info" else UI.PALE, true)
		l.custom_minimum_size = Vector2(1100, 0)
		v.add_child(l)
		if str(p[2]) != "":
			v.add_child(UI.label(str(p[2]), 14, UI.DIM))
		checks.add_row(row)


# ---------------------------------------------------------------- changing it
func _touch() -> void:
	changed.emit()
	refresh()


func set_level(n: int) -> void:
	n = clampi(n, 1, 6)
	if n != int(team["level"]):
		team["level"] = n
		_touch()


func ask_name() -> void:
	if rename != null:
		return
	rename = NameDialog.new("Name this Strike Team", str(team.get("name", "")))
	rename.named.connect(func(t):
		_end_rename()
		set_team_name(t))
	rename.cancelled.connect(_end_rename)
	add_child(rename)


func _end_rename() -> void:
	if rename != null:
		rename.queue_free()
		rename = null


func set_team_name(t: String) -> void:
	team["name"] = t.strip_edges()
	_touch()


func toggle_hero(n: String) -> void:
	var at: int = team["heroes"].find(n)
	if at >= 0:
		team["heroes"].remove_at(at)
	else:
		team["heroes"].append(n)
	_touch()


func set_copies(n: String, k: int) -> void:
	StrikeTeams.set_copies(team, n, clampi(k, 0, MAX_COPIES))
	_touch()


func toggle_carried(hero: String, n: String) -> void:
	var list: Array = team["actions"].get(hero, [])
	if list.has(n):
		list.erase(n)
	else:
		list.append(n)
	if list.is_empty():
		team["actions"].erase(hero)
	else:
		team["actions"][hero] = list
	_touch()


func set_chips(key: String, k: int) -> void:
	StrikeTeams.set_chips(team, key, clampi(k, 0, MAX_CHIPS if key.begins_with("basic|") else StrikeTeams.MAX_COPIES))
	_touch()


func set_consumables(n: String, k: int) -> void:
	StrikeTeams.set_consumables(team, n, clampi(k, 0, MAX_CONSUMABLES))
	_touch()


func toggle_proto(n: String) -> void:
	if team["protos"].has(n):
		team["protos"].erase(n)
	else:
		team["protos"].append(n)
	_touch()


## Takes a card the export no longer has out of the team, wherever it sits.
func forget(n: String) -> void:
	team["heroes"].erase(n)
	team["deck"].erase(n)
	team["pouch"].erase(n)
	team["protos"].erase(n)
	team["consumables"].erase(n)
	for h in team["actions"].keys():
		team["actions"][h].erase(n)
		if team["actions"][h].is_empty():
			team["actions"].erase(h)
	team["actions"].erase(n)
	_touch()


# ---------------------------------------------------------------- reading a card
func tap_card(i: int) -> void:
	if i < 0 or i >= _shown.size() or sheet != null:
		return
	var what: Dictionary = _shown[i]
	if what.has("gone"):
		var n: String = what["gone"]
		_open_sheet(CardSheet.new({"name": n, "cardType": ""}, null, {"buttons": [["forget", "Take it out"]],
			"note": "This export has no card by this name. It stays in the team, and is left out of a fight, until an export brings it back or you take it out."}), func(id):
			if id == "forget":
				forget(n))
		return
	var c: Dictionary = what["card"]
	var nm := str(c["name"])
	match tab:
		"heroes":
			var on: bool = team["heroes"].has(nm)
			_open_sheet(CardSheet.new(c, roster.art_for(c), {"buttons": [["toggle", "Take off the team" if on else "Add to the team"]]}), func(id):
				if id == "toggle":
					toggle_hero(nm))
		"deck":
			var s := CardSheet.new(c, roster.art_for(c), {"stepper": {"value": StrikeTeams.copies(team, nm), "min": 0, "max": MAX_COPIES, "label": "Copies in the Deck"}})
			s.stepped.connect(func(v): set_copies(nm, v))
			_open_sheet(s, func(_id): pass)
		"carried":
			var has: bool = team["actions"].get(carrier, []).has(nm)
			var hero := carrier
			_open_sheet(CardSheet.new(c, roster.art_for(c), {"buttons": [["toggle", ("Take from %s" if has else "Give to %s") % hero]]}), func(id):
				if id == "toggle":
					toggle_carried(hero, nm))
		"pouch":
			var key: String = what["chip"]
			var s2 := CardSheet.new(c, roster.art_for(c) if not Rules.truthy(c.get("basic")) else null, {"stepper": {"value": int(Rules.num(team["pouch"].get(key), 0)), "min": 0, "max": MAX_CHIPS if key.begins_with("basic|") else StrikeTeams.MAX_COPIES, "label": "In the Pouch"}})
			s2.stepped.connect(func(v): set_chips(key, v))
			_open_sheet(s2, func(_id): pass)
		"consumables":
			var s3 := CardSheet.new(c, roster.art_for(c), {"stepper": {"value": int(Rules.num(team["consumables"].get(nm), 0)), "min": 0, "max": MAX_CONSUMABLES, "label": "Carried into each Battle"}})
			s3.stepped.connect(func(v): set_consumables(nm, v))
			_open_sheet(s3, func(_id): pass)
		"protos":
			var inn: bool = team["protos"].has(nm)
			_open_sheet(CardSheet.new(c, roster.art_for(c), {"buttons": [["toggle", "Take off the team" if inn else "Add to the team"]]}), func(id):
				if id == "toggle":
					toggle_proto(nm))


func _open_sheet(s: CardSheet, on_choice: Callable) -> void:
	_close_sheet()
	sheet = s
	s.chosen.connect(func(id):
		_close_sheet()
		on_choice.call(id))
	add_child(s)


func _close_sheet() -> void:
	if sheet != null:
		Motion.pop_out(sheet, sheet.get_meta("box", null))
		sheet = null
