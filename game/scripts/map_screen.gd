## The World Map on the screen: a bar along the top (the deployment, the
## team, the log, Fit, Home), the haul under it, and a panel on the right for
## the tile you tapped and for what the Strike Team can do where it stands:
## walk there, enter a POI, open a Cache, choose in an Event, fight, or come
## home. The map itself is drawn under it (map_view.gd) and takes the touches
## this leaves alone: drag to pan, pinch to zoom, tap a tile.
##
## With no Strike Team out the map can still be looked at: the tiles you have
## seen stay seen.
class_name MapScreen
extends Control

signal fight_requested          # the fight that is waiting should begin
signal closed                   # Home
signal dock_requested           # back to the dock (nobody is out)
signal fit_requested
signal centre_requested(key: String, at_once: bool)   # bring a tile into view: at once (Find team), or only if it has drifted off

const PANEL_W := 400.0
const BAR_H := 72.0

var campaign: Campaign = null
var roster: Roster = null
var view: MapView = null
var selected := ""
var walking := false
var stop_asked := false
var _walk := 0                   # which walk is under way: one that was cut short never carries on
var event_out = null             # what the Event just chosen came to, until the team moves on
var note := ""                   # a line at the head of the panel: an ambush, a cache opened
var note_bad := false
var last_home := {}               # what the last Come home said (0.10: its bounties among it)
var dialog: Dialog = null

var bar: PanelContainer
var title_label: Label
var team_btn: Button
var log_btn: Button
var fit_btn: Button
var find_btn: Button
var home_btn: Button
var status_label: Label
var status_icons: HBoxContainer          # (0.11) the same, as icons and numbers, while a team is out
var hint_label: Label
var panel: PanelContainer
var p_title: Label
var p_skull: HBoxContainer               # (0.11) the tile's Skull Level, as an icon and its number
var p_emblem: TextureRect                # (0.15) the tile's District, as its emblem
var p_lines: VBoxContainer
var p_buttons: VBoxContainer
var _actions: Array = []         # what each button in the panel does: {id, arg}
var _buttons: Array = []


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE          # the map takes what this doesn't
	bar = PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	var sb := PixelBox.new()
	sb.bg_color = Color("#171819", 1.0)
	sb.content_margin_left = 14; sb.content_margin_right = 14; sb.content_margin_top = 8; sb.content_margin_bottom = 8
	bar.add_theme_stylebox_override("panel", sb)
	add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	bar.add_child(row)
	title_label = UI.label("World Map", 22, UI.CYAN)
	title_label.clip_text = true
	title_label.custom_minimum_size = Vector2(100, 0)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_label)
	team_btn = _bar_button("Team", show_team)
	row.add_child(team_btn)
	log_btn = _bar_button("Log", show_log)
	row.add_child(log_btn)
	find_btn = _bar_button("Find team", func(): centre_requested.emit(_pos(), true))
	row.add_child(find_btn)
	fit_btn = _bar_button("Fit", func(): fit_requested.emit())
	fit_btn.custom_minimum_size.x = 70
	row.add_child(fit_btn)
	home_btn = _bar_button("Home", func(): closed.emit())
	row.add_child(home_btn)

	status_label = UI.label("", 16, Color("#efdd91"))
	status_label.position = Vector2(14, BAR_H + 6)
	_outline(status_label)
	add_child(status_label)
	status_icons = HBoxContainer.new()
	status_icons.position = Vector2(14, BAR_H + 6)
	status_icons.add_theme_constant_override("separation", 18)
	status_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(status_icons)

	hint_label = UI.label("", 18, UI.PALE, true)
	hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint_label.offset_top = -80
	hint_label.offset_left = 14
	hint_label.offset_right = -(PANEL_W + 24)
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	hint_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_outline(hint_label)
	add_child(hint_label)

	panel = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0             # as tall as what it says, and no taller
	panel.offset_left = -PANEL_W - 10
	panel.offset_right = -10
	panel.offset_top = BAR_H + 10
	panel.offset_bottom = BAR_H + 10
	panel.add_theme_stylebox_override("panel", UI.box(Color("#171819", 0.96), UI.LINE, 1, 8, 16))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	col.add_child(head)
	p_emblem = UI.icon("skull", 32)
	p_emblem.visible = false
	head.add_child(p_emblem)
	p_title = UI.label("", 22, UI.TEXT, true)
	p_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(p_title)
	p_skull = UI.stat("skull", "", UI.TEXT, 22, 32)
	p_skull.visible = false
	head.add_child(p_skull)
	p_lines = VBoxContainer.new()
	p_lines.add_theme_constant_override("separation", 6)
	col.add_child(p_lines)
	p_buttons = VBoxContainer.new()
	p_buttons.add_theme_constant_override("separation", 8)
	col.add_child(p_buttons)


func _bar_button(text: String, fn: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(96, 54)
	b.pressed.connect(fn)
	return b


static func _outline(l: Label) -> void:
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE


static func plural(n: int, word: String, many := "") -> String:
	return "%d %s" % [n, word if n == 1 else (many if many != "" else word + "s")]


# ---------------------------------------------------------------- opening it
## Shows the map for this campaign. With a Strike Team out, it stands where it was left.
func open(c: Campaign, r: Roster, v: MapView) -> void:
	campaign = c
	roster = r
	view = v
	walking = false
	stop_asked = false
	event_out = null
	note = ""
	_close_dialog()
	var cur = campaign.deploy.cur()
	selected = str(cur["pos"]) if cur != null else ""
	view.place_team(str(cur["pos"]) if cur != null else "")
	refresh()


func _cur() -> Variant:
	return campaign.deploy.cur() if campaign != null else null


func _pos() -> String:
	var c = _cur()
	return str(c["pos"]) if c != null else (campaign.world.dock() if campaign != null else "0,0")


## Whether the map should take a touch: not while a box is up.
func map_live() -> bool:
	return visible and dialog == null


# ---------------------------------------------------------------- what it shows
func refresh() -> void:
	if campaign == null or view == null:
		return
	var w := campaign.world
	var dep := campaign.deploy
	var c = dep.cur()
	view.selected = selected
	view.route = []
	if c != null and selected != "" and selected != c["pos"] and c["activity"] == null and not walking:
		view.route = w.path(c["pos"], selected)
	view.team_at = str(c["pos"]) if c != null else ""
	view.token = _team_token()
	view.token_hex = _team_token_hex()
	view.refresh()
	if c != null:
		title_label.text = "Deployment %d  ·  %s" % [int(c["n"]), str(c["team"].get("name", ""))]
		status_label.text = status_text() + _unsaved()
	else:
		title_label.text = "World Map  ·  at the dock"
		status_label.text = campaign.status_line() + _unsaved()
	_status_icons()
	team_btn.visible = c != null
	log_btn.visible = c != null
	find_btn.text = "Find team" if c != null else "Find dock"
	_fill_panel()


## The first Hero still standing is the team's marker, in its own token.
func _team_token() -> Texture2D:
	var names := campaign.deploy.hero_names()
	if names.is_empty() or roster == null:
		return null
	var card = roster.card_named(str(names[0]))
	return roster.token_for(card).get("texture") if card != null else null


## (0.15) Whether that token is a picture of hex pixels (fitted to a token's width).
func _team_token_hex() -> bool:
	var names := campaign.deploy.hero_names()
	if names.is_empty() or roster == null:
		return false
	var card = roster.card_named(str(names[0]))
	return card != null and bool(roster.token_for(card).get("hexagon", false))


func _line(text: String, colour := UI.PALE, size := 17) -> void:
	var l := UI.label(UI.show(text), size, colour, true)
	l.custom_minimum_size = Vector2(PANEL_W - 40, 0)
	p_lines.add_child(l)


func _action(label: String, id: String, arg = null, primary := false) -> void:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(0, 58)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART      # a long choice takes a second line
	if primary:
		b.add_theme_color_override("font_color", UI.CYAN)
	var at := _actions.size()
	b.pressed.connect(func(): act(at))
	_actions.append({"id": id, "arg": arg})
	_buttons.append(b)
	p_buttons.add_child(b)


func _clear_panel() -> void:
	p_skull.visible = false
	p_emblem.visible = false
	for c in p_lines.get_children():
		p_lines.remove_child(c)
		c.queue_free()
	for c in p_buttons.get_children():
		p_buttons.remove_child(c)
		c.queue_free()
	_actions = []
	_buttons = []


## The panel's buttons, as {id, arg, label} (for the tests, and nothing else).
func actions() -> Array:
	var out := []
	for i in _actions.size():
		out.append({"id": _actions[i]["id"], "arg": _actions[i]["arg"], "label": _buttons[i].text})
	return out


## The panel's words, top to bottom (for the tests).
func lines() -> Array:
	return p_lines.get_children().map(func(l): return (l as Label).text)


func _fill_panel() -> void:
	_clear_panel()
	_fill_panel_now()
	# it shrinks to what it now says (a Control grows by itself, and never shrinks)
	panel.size = Vector2(PANEL_W, 0)
	panel.reset_size.call_deferred()


func _fill_panel_now() -> void:
	var w := campaign.world
	var dep := campaign.deploy
	var c = dep.cur()
	panel.visible = true
	hint_label.text = ""
	p_title.add_theme_color_override("font_color", UI.TEXT)
	if note != "":
		_line(note, UI.SOFT_RED if note_bad else UI.GREEN, 18)
	# a fight is waiting: nothing else can be done until it is fought
	if c != null and c["activity"] != null:
		var a: Dictionary = c["activity"]
		p_title.text = str(a["name"]) if a["kind"] == "poi" else "Ambush"
		_line(("Floor %d of %d  ·  " % [int(a["index"]) + 1, a["floors"].size()] if a["kind"] == "poi" else "") + "Skull %d  ·  %s" % [int(a["skull"]), World.district_name(a["district"])])
		if event_out != null and event_out.get("tile") == a["tile"]:
			_event_outcome(event_out)
		_line("The next fight is waiting: %s." % str(a["floors"][a["index"]]), UI.DIM)
		_line("Heroes who can go in: %s." % ", ".join(dep.hero_names()), UI.DIM)
		if dep.can_withdraw():
			_line("The last fight here was lost. Withdraw leaves it as it is and takes the haul back to the map.", UI.DIM)
		_action("Fight", "fight", null, true)
		if dep.can_withdraw():
			_action("Withdraw with the haul", "withdraw")
		return
	if selected == "":
		panel.visible = false
		hint_label.text = "Tap a tile to see it. Tap one further off, then Walk here." if c != null else ""
		if c == null:
			panel.visible = true
			p_title.text = "Nobody is out"
			_line("Drag to look around, pinch to zoom, tap a tile to see it. What a tile holds shows once a Strike Team has stood next to it.")
			_action("Back to the dock", "dock", null, true)
		return
	var k := selected
	if not w.is_open(k):
		p_title.text = "Collapsed structure"
		_line("Nothing gets through here.")
		if c == null:
			_action("Back to the dock", "dock")
		return
	var t: Dictionary = w.tile(k)
	var sk := w.skull_of(k)
	var content = w.content_at(k)
	var kn := w.known(k)
	var dock := k == w.dock()
	var d := w.district_of(k)
	p_title.text = "The dock" if dock else World.district_name(d)
	# (0.15) the District's emblem before its name
	p_emblem.texture = Art.icon2("district_" + d) if d != "" and not dock else null
	p_emblem.visible = p_emblem.texture != null
	p_title.add_theme_color_override("font_color", UI.TEXT if dock else Color(World.DCOL.get(d, World.DCOL[""])))
	var what := "where deployments start and end"
	if not dock:
		if not kn:
			what = "Unknown: stand next to it to see what it holds"
		elif content == null:
			what = "Empty"
		elif Rules.truthy(content.get("core")):
			what = "%s: beat it to clear the District" % str(content["name"])
		elif content.get("unique") is Dictionary:
			what = "Unique POI: %s%s" % [str(content["name"]), (" (%s)" % str(content["type"])) if Rules.truthy(content.get("type")) and content["name"] != content["type"] else ""]
		elif content["kind"] == "poi":
			what = "POI: " + str(content["name"])
		else:
			what = str(content["name"])
	if kn and content != null and not dock and Rules.truthy(content.get("core")) and w.is_district_cleared(content["core"]):
		what = "%s  ·  the District is cleared" % str(content["name"])
	elif kn and content != null and not dock and w.is_cleared(k):
		var back := maxi(0, w.back_in(k) - (1 if c != null else 0))
		what += "  ·  cleared, back after " + (plural(back, "more deployment") if back > 0 else "this deployment")
	_line("Skull %d%s  ·  %s" % [sk, " (set)" if Rules.truthy(t.get("s")) else "", what], UI.TEXT, 18)
	if not dock:
		p_skull.visible = true
		(p_skull.get_child(1) as Label).text = str(sk)
	if not dock:
		_line("Stepping here: %d%% chance of an ambush." % w.ambush_chance(k), UI.DIM)
	if c != null:
		if k == c["pos"]:
			_here(k)
		elif not walking:
			var p := w.path(c["pos"], k)
			if p.is_empty():
				_line("There is no way through to here.", UI.SOFT_RED)
			else:
				_line("%s away  ·  %d%% chance of at least one ambush on the way." % [plural(p.size() - 1, "step"), w.path_risk(p)], UI.DIM)
				_action("Walk here", "walk", k, true)
	else:
		_action("Back to the dock", "dock")
	if walking:
		_action("Stop", "stop")


## What the team can do where it stands.
func _here(k: String) -> void:
	var w := campaign.world
	var dep := campaign.deploy
	if k == w.dock():
		_line("The Strike Team is at the dock.")
		_line("Coming home banks the haul into your stockpile, keeps what was found, and ends the deployment.", UI.DIM)
		_action("Come home", "home", null, true)
		return
	if event_out != null and event_out.get("tile") == k:
		_event_outcome(event_out)
		return
	var content = w.content_at(k)
	if content == null or not w.available(k):
		_line("The Strike Team is here.")
		return
	match content["kind"]:
		"poi":
			var n: int = 3 if Rules.truthy(content.get("core")) else w.floor_count(w.skull_of(k))
			if Rules.truthy(content.get("core")):
				_line("The heart of District %s: %s, the last a Boss's. Beat it to clear the District for good: 5 merits, and Dimensional Instability rises." % [str(content["core"]), plural(n, "floor")], UI.GOLD)
			if content.get("unique") is Dictionary and content["unique"].get("floors") is Array:
				var own: int = content["unique"]["floors"].filter(func(f): return w.floor_named(f) != null).size()
				n = own if own > 0 else n
			_line("%s: %s, fought in order, with a reward at the end. Once inside, the only way out early is an Emergency Exit." % [str(content["name"]), plural(n, "floor")])
			_action("Enter", "enter", k, true)
		"cache":
			_line("A cache, unguarded.")
			_action("Open it", "cache", k, true)
		"event":
			var ev = dep.event_at(k)
			if ev == null:
				_line("The Strike Team is here.")
				return
			_line(str(ev.get("title", "An event")), UI.GOLD, 20)
			_line(str(ev.get("text", "")))
			var choices: Array = ev["choices"] if ev.get("choices") is Array else []
			for i in choices.size():
				var ch: Dictionary = choices[i]
				var check := World.number(ch.get("check"))
				_action(str(ch.get("label", "Choose")) + ((" (d20, %s or more)" % Deployment._whole_text(check)) if check != 0.0 else ""), "choose", i, i == 0)
		_:
			_line("The Strike Team is here.")


func _event_outcome(o: Dictionary) -> void:
	_line("%s: %s" % [str(o["event"].get("title", "An event")), str(o["choice"].get("label", ""))], UI.GOLD, 19)
	if o["check"] != 0.0:
		_line("Rolled %d (needed %s)." % [int(o["roll"]), Deployment._whole_text(o["check"])], UI.GREEN if o["won"] else UI.SOFT_RED)
	if o["text"] != "":
		_line(str(o["text"]))
	if not Loot.is_empty(o["got"]):
		_line("Into the haul: %s." % campaign.loot.text(o["got"]), Color("#efdd91"))
	if not o["items"].is_empty():
		_line("Found: %s." % ", ".join(o["items"].map(func(it): return campaign.progress.item_name(it))), Color("#efdd91"))
	if o["lost"] != null and not Loot.is_empty(o["lost"]):
		_line("Lost from the haul: %s." % campaign.loot.text(o["lost"]), UI.SOFT_RED)


# ---------------------------------------------------------------- doing things
## A tile was tapped.
func tap(k: String) -> void:
	if campaign == null or walking:
		return
	selected = k
	if event_out != null and event_out.get("tile") != k:
		event_out = null
	note = ""
	refresh()


## A button in the panel, by its place.
func act(i: int) -> void:
	if i < 0 or i >= _actions.size():
		return
	var a: Dictionary = _actions[i]
	do(a["id"], a["arg"])


func do(id: String, arg = null) -> void:
	var dep := campaign.deploy
	var c = dep.cur()
	match id:
		"dock":
			dock_requested.emit()
		"stop":
			stop_asked = true
		"walk":
			walk(str(arg))
		"fight":
			if c != null and c["activity"] != null:
				fight_requested.emit()
		"withdraw":
			if dep.withdraw()["ok"]:
				campaign.save()
				say_note("The team withdraws with its haul. Walk home to keep it.")
		"enter":
			if c == null:
				return
			note = ""
			var sp = dep.enter_poi(c["pos"])
			campaign.save()
			if sp == null:
				note = "No floor to fight on: make one in the Companion's POI Sandbox and export again."
				note_bad = true
			refresh()
		"cache":
			if c == null:
				return
			var r = dep.open_cache(c["pos"])
			campaign.save()
			if r != null:
				note = "The cache holds %s%s." % [campaign.loot.text(r["bag"]), ("; and " + ", ".join(r["items"].map(func(it): return campaign.progress.item_name(it)))) if not r["items"].is_empty() else ""]
				note_bad = false
			refresh()
		"choose":
			if c == null:
				return
			note = ""
			var o = dep.choose(c["pos"], int(arg))
			campaign.save()
			if o != null:
				o["tile"] = c["pos"]
				event_out = o
				if o["fight"] and o.get("spec") == null:
					note = "No floor to fight on, so nothing comes of it."
					note_bad = true
			refresh()
		"home":
			come_home()


## Walks to a tile, a step at a time: each step may spring an ambush, and the
## team stops at anything it finds.
func walk(to: String) -> void:
	var dep := campaign.deploy
	var c = dep.cur()
	if c == null or walking or c["activity"] != null:
		return
	var p := campaign.world.path(c["pos"], to)
	if p.size() < 2:
		return
	walking = true
	stop_asked = false
	event_out = null
	note = ""
	selected = to
	_walk += 1
	var mine := _walk
	refresh()
	for i in range(1, p.size()):
		if stop_asked:
			selected = str(dep.cur()["pos"])
			break
		var r := dep.step_to(p[i])
		if not r["moved"]:
			note = str(r.get("why", "Can't go on"))
			note_bad = true
			break
		campaign.save()
		view.step_team(str(r["pos"]))
		centre_requested.emit(str(r["pos"]), false)
		_status_only()
		await view.stepped
		if not walking or _walk != mine:
			return                      # the screen was closed under it (every step taken is saved)
		if r["ambush"]:
			var sp = dep.ambush(r["pos"], {"tileAmbush": Rules.truthy(r.get("tileAmbush"))})
			campaign.save()
			selected = str(r["pos"])
			note = "Ambush! " + ("Something was waiting here." if Rules.truthy(r.get("tileAmbush")) else "Enemies close in on the way.") + ("" if sp != null else " (No floor to fight on: make one in the Companion's POI Sandbox.)")
			note_bad = true
			break
		if r.get("content") != null or i == p.size() - 1:
			selected = str(r["pos"])
			break
	walking = false
	stop_asked = false
	refresh()


func _status_only() -> void:
	if _cur() != null:
		status_label.text = status_text() + _unsaved()
		_status_icons()
	view.refresh()


## (0.11) While a team is out, the bar's count as icons and numbers: who is
## standing, the haul by kind, the steps and fights. (The words stay in
## status_label, which shows only with nobody out.)
func _status_icons() -> void:
	var c = _cur()
	status_label.visible = c == null
	status_icons.visible = c != null
	for k in status_icons.get_children():
		status_icons.remove_child(k)
		k.queue_free()
	if c == null:
		return
	var haul := Loot.norm(c["haul"])
	var standing := "%d of %d" % [campaign.deploy.hero_names().size(), c["team"].get("heroes", []).size()]
	var items := [["hp", standing + " standing", UI.TEXT]]
	items.append_array(UI.bag_items(haul))
	for it in items:
		var s := UI.stat(it[0], it[1], it[2], 18, 28)
		for l in s.get_children():
			if l is Label:
				_outline(l)
		status_icons.add_child(s)
	var more := UI.label("%s, %s%s%s" % [plural(int(c["steps"]), "step"), plural(int(c["fights"]), "fight"), (", " + plural(c["items"].size(), "find")) if not c["items"].is_empty() else "", _unsaved().replace("\n", "   ")], 16, UI.PALE if _unsaved() == "" else UI.SOFT_RED)
	more.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_outline(more)
	status_icons.add_child(more)


## A save that failed, said under the status until one works.
func _unsaved() -> String:
	return ("\n" + campaign.error) if campaign != null and campaign.error != "" else ""


## Who is standing, what the team carries, and how far it has come.
func status_text() -> String:
	var c = _cur()
	if c == null:
		return ""
	var haul := Loot.norm(c["haul"])
	return "Heroes standing: %d of %d%s   ·   Haul: %s, %s%s   ·   %s, %s" % [campaign.deploy.hero_names().size(), c["team"].get("heroes", []).size(),
		(" (%d sitting out)" % c["heroesOut"].size()) if not c["heroesOut"].is_empty() else "",
		plural(haul["shards"], "shard"), plural(Loot.count(haul), "part"), (", " + plural(c["items"].size(), "find")) if not c["items"].is_empty() else "",
		plural(int(c["steps"]), "step"), plural(int(c["fights"]), "fight")]


## The team walks back onto the dock: the haul is banked, and what happened is told.
func come_home() -> void:
	var dep := campaign.deploy
	var h := dep.home()
	if not h["ok"]:
		note = str(h.get("why", ""))
		note_bad = true
		refresh()
		return
	last_home = h
	campaign.save()
	view.place_team("")
	selected = ""
	note = ""
	var text := "Deployment %d is home." % int(h["n"])
	if Loot.is_empty(h["haul"]) and h["items"].is_empty():
		text += "\n\nIt brought nothing back this time."
	else:
		if not Loot.is_empty(h["haul"]):
			text += "\n\nInto the stockpile: %s." % campaign.loot.text(h["haul"])
		if not h["items"].is_empty():
			text += "\n\nNow yours: %s." % ", ".join(h["items"].map(func(it): return "%s %s" % [Progress.kind_word(it).to_lower(), campaign.progress.item_name(it, true)]))
			text += "\nThey are in the Workshop now."
	var more := campaign.end_lines(h, false)
	if not more.is_empty():
		text += "\n\n" + "\n".join(more)
	refresh()
	_open_dialog(Dialog.new("Home", text, ["To the dock", "Stay on the map"], UI.GREEN), func(i):
		_close_dialog()
		if i == 0:
			dock_requested.emit())


## (0.41) A line at the head of the panel, from outside it (a withdrawal).
func say_note(text: String, bad := false) -> void:
	note = text
	note_bad = bad
	refresh()


## A fight is over and the deployment has said what comes next: the map shows it.
func after_fight(out: Dictionary) -> void:
	var c = _cur()
	event_out = null
	note = ""
	if c != null:
		selected = str(c["pos"])
		view.place_team(str(c["pos"]))
	else:
		selected = ""
		view.place_team("")
	refresh()


# ---------------------------------------------------------------- the team, and the log
## Who is standing, what has been lost and used, and what the team carries.
func team_text() -> String:
	var dep := campaign.deploy
	var c = dep.cur()
	if c == null:
		return "Nobody is out."
	var bits := ["Heroes standing: %s." % (", ".join(dep.hero_names()) if not dep.hero_names().is_empty() else "none")]
	if not c["heroesOut"].is_empty():
		bits.append("Sitting out the rest of the deployment: %s." % ", ".join(c["heroesOut"]))
	var lost := []
	for n in c["lost"]:
		lost.append("%d × %s" % [int(c["lost"][n]), str(n)])
	if not lost.is_empty():
		bits.append("Troops lost for the rest of it: %s." % ", ".join(lost))
	var cons := []
	for n in c["pack"]["cons"]:
		cons.append("%d × %s" % [int(c["pack"]["cons"][n]), str(n)])
	bits.append("Consumables left: %s." % (", ".join(cons) if not cons.is_empty() else "none"))
	var pp = c["pack"]["protos"]
	var protos: Array = pp.keys() if pp is Dictionary else pp
	if not protos.is_empty():
		bits.append("Prototypes: %s." % ", ".join(protos))
	var pre := []
	for l in (c.get("preLines", []) if c.get("preLines") is Array else []):
		pre.append("%d × %s" % [int(l["copies"]), str(l["name"])])
	if not pre.is_empty():
		bits.append("Pre-built copies: %s." % ", ".join(pre))
	# 0.10: the Bounty Board, and which of it this team has beaten
	var board: Array = campaign.dock.bounties() if campaign.dock != null else []
	if not board.is_empty():
		var beaten: Array = c.get("kills", []).map(func(k): return str(k.get("name")))
		bits.append("Bounty Board: %s." % ", ".join(board.map(func(b): return str(b["name"]) + (" (paid)" if Rules.truthy(b.get("claimed")) else (" (beaten: it pays at home)" if beaten.has(str(b["name"])) else "")))))
	bits.append("Haul: %s." % campaign.loot.text(c["haul"]))
	if not c["items"].is_empty():
		bits.append("Found: %s." % ", ".join(c["items"].map(func(it): return campaign.progress.item_name(it))))
	bits.append("It is all yours once the team reaches the dock. A wipe loses it.")
	return "\n".join(bits)


func show_team() -> void:
	var c = _cur()
	if c == null:
		return
	_open_dialog(Dialog.new(str(c["team"].get("name", "The Strike Team")), team_text(), ["Close"]), func(_i): _close_dialog())


func log_text(most := 14) -> String:
	var c = _cur()
	if c == null:
		return ""
	return "\n".join(c["log"].slice(0, most).map(func(l): return str(l["text"])))


func show_log() -> void:
	if _cur() == null:
		return
	_open_dialog(Dialog.new("Deployment log", "Newest first.\n\n" + log_text(), ["Close"]), func(_i): _close_dialog())


func _open_dialog(d: Dialog, on_choice: Callable) -> void:
	_close_dialog()
	dialog = d
	d.chosen.connect(on_choice)
	add_child(d)


func _close_dialog() -> void:
	if dialog != null:
		Motion.pop_out(dialog, dialog.get_meta("box", null))
		dialog = null


## Leaving the screen: a walk under way stops where it is (every step is saved).
func close() -> void:
	walking = false
	stop_asked = false
	_walk += 1
	_close_dialog()
