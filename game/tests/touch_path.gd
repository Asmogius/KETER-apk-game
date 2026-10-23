## Touches sent the way the phone sends them (through Input, with mouse
## emulation on, as the project has it), to check that each lands where it
## should: a list row, a button, a card's tile, the board, and never the board
## (or the tiles) through whatever lies over them.
##   godot --headless --path . --script res://tests/touch_path.gd
extends SceneTree

const Kit := preload("res://tests/team_kit.gd")

var ok := 0
var bad := 0


func ck(name: String, cond: bool, detail = "") -> void:
	if cond:
		ok += 1
		print("PASS " + name)
	else:
		bad += 1
		print("FAIL " + name + "  — " + str(detail).left(260))


func _initialize() -> void:
	_run.call_deferred()


## What Godot's Input does with a finger when mouse emulation is on: first a
## pretend mouse event (which is what presses a Button), then the touch itself.
## Headless, Input doesn't dispatch, so both go to the window as it would send them.
## Positions are in the game's 1280x720 view; the window (tiny, headless) is
## scaled from it, so each is turned into the window's own.
func _touch(p0: Vector2, pressed: bool, index := 0) -> void:
	var p := root.get_final_transform() * p0
	if index == 0:
		var m := InputEventMouseButton.new()
		m.device = InputEvent.DEVICE_ID_EMULATION
		m.button_index = MOUSE_BUTTON_LEFT
		m.pressed = pressed
		m.position = p
		m.global_position = p
		m.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		root.push_input(m)
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = p
	e.pressed = pressed
	root.push_input(e)


func _drag(p0: Vector2, rel0: Vector2) -> void:
	var p := root.get_final_transform() * p0
	var rel := root.get_final_transform().basis_xform(rel0)
	var m := InputEventMouseMotion.new()
	m.device = InputEvent.DEVICE_ID_EMULATION
	m.position = p
	m.global_position = p
	m.relative = rel
	m.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(m)
	var d := InputEventScreenDrag.new()
	d.position = p
	d.relative = rel
	root.push_input(d)


## The middle of something on the screen.
func _mid(c: Control) -> Vector2:
	return c.get_global_rect().get_center()


func _tap(p: Vector2) -> void:
	_touch(p, true)
	await process_frame
	_touch(p, false)
	await process_frame
	await process_frame


## Where a tile is on the screen.
func _at(scene: Node, h: Vector2i) -> Vector2:
	return scene.get_viewport().get_canvas_transform() * scene.board.to_global(Board.at(h))


## Waits for what a card set going (numbers rising, the board sliding) to finish.
func _calm(scene: Node) -> void:
	var n := 0
	for f in 4:
		await process_frame
	while (scene.busy or scene.walking) and n < 900:
		await process_frame
		n += 1
	for f in 20:
		await process_frame


func _run() -> void:
	# headless, the window is 64 pixels square: make it a phone held sideways
	root.size = Vector2i(1280, 720)
	await process_frame
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	Kit.fresh()
	scene.load_export("res://tests/fixtures/export.zip")
	await process_frame
	await process_frame
	# home, and the Strike Team builder
	await _tap(_mid(scene.home.teams_btn))
	var ts: TeamsScreen = scene.teams_screen
	ck("a touch on Strike Teams opens them", ts.visible and not scene.home.visible)
	await _tap(_mid(ts.new_btn))
	ck("a touch on New team asks its name", ts.namer != null)
	await _tap(_mid(ts.namer.ok_btn))
	var ed: TeamEditor = ts.editor
	ck("a touch on OK makes the team and opens it", ts.namer == null and ed.visible and ts.teams.size() == 1, ts.teams.size())
	var hi0 := -1
	for i in ed._shown.size():
		if ed._shown[i]["card"]["name"] == "Test Warden":
			hi0 = i
	await _tap(_mid(ed.grid.tiles[hi0]))
	ck("a touch on a card's tile opens it to read", ed.sheet != null and ed.sheet.card["name"] == "Test Warden")
	await _tap(_mid(ed.grid.tiles[1]))
	ck("a touch on the open card never reaches the tiles behind", ed.sheet != null and ed.sheet.card["name"] == "Test Warden" and ed.team["heroes"].is_empty())
	await _tap(_mid(ed.sheet.buttons["toggle"]))
	ck("a touch on Add to the team adds it", ed.sheet == null and ed.team["heroes"] == ["Test Warden"], ed.team["heroes"])
	await _tap(_mid(ed.tab_btns["deck"]))
	ck("a touch on a tab opens it", ed.tab == "deck" and ed.grid.tiles.size() > 50)
	var from0: Vector2 = _mid(ed.grid)
	_touch(from0, true)
	await process_frame
	for k in 6:
		_drag(from0 - Vector2(0, 30 * (k + 1)), Vector2(0, -30))
		await process_frame
	_touch(from0 - Vector2(0, 180), false)
	await process_frame
	ck("a drag on the tiles scrolls them and opens nothing", ed.grid.scroll > 60 and ed.sheet == null, ed.grid.scroll)
	var seen := -1
	for i in ed.grid.tiles.size():
		if seen < 0 and ed.grid.get_global_rect().has_point(_mid(ed.grid.tiles[i])):
			seen = i
	var picked: String = ed.grid.tiles[seen].card["name"]
	await _tap(_mid(ed.grid.tiles[seen]))
	ck("then a touch on a tile opens that card", ed.sheet != null and ed.sheet.card["name"] == picked, picked)
	await _tap(_mid(ed.sheet.plus_btn))
	await _tap(_mid(ed.sheet.plus_btn))
	ck("a touch on plus adds a copy to the Deck", ed.team["deck"].get(picked) == 2 and ed.sheet != null and ed.sheet.count_label.text == "2", ed.team["deck"])
	await _tap(_mid(ed.sheet.buttons["close"]))
	ck("a touch on Close puts the card away", ed.sheet == null)
	await _tap(_mid(ed.back_btn))
	ck("a touch on Teams goes back to the list, the team kept", not ed.visible and ts._rows.size() == 1 and StrikeTeams.load_all()[0]["deck"].get(picked) == 2)
	await _tap(_mid(ts.back_btn))
	ck("a touch on Back goes home", scene.home.visible and not ts.visible)
	# a Strike Team's Battle
	Kit.keep([Kit.team()])
	await _tap(_mid(scene.home.practice_btn))
	ck("a touch on Practice opens its two fights", scene.home.practice_row.visible and scene.home.battle_btn.is_visible_in_tree())
	await _tap(_mid(scene.home.battle_btn))
	var s: SetupScreen = scene.setup
	ck("a touch on Battle starts setting one up", s.visible and s.mode == "team" and s.teams.size() == 1)
	var wi := -1
	for i in s.floors.size():
		if s.floors[i].name == "TEST · Corridor":
			wi = i
	await _tap(_mid(s._rows[wi]["row"]))
	await _tap(_mid(s.next_btn))
	await _tap(_mid(s._rows[0]["row"]))
	ck("a touch on a Strike Team picks it", s.step == "team" and s.team_i == 0, [s.step, s.team_i])
	await _tap(_mid(s.next_btn))
	var lead_box: Control = s._rows[1]["action"]
	await _tap(_mid(lead_box))
	ck("a touch on Lead puts that Hero in charge, and leaves it going in", s.leader == "Test Striker" and s.heroes == ["Test Warden", "Test Striker"], [s.leader, s.heroes])
	await _tap(_mid(s.next_btn))
	var drone := {}
	for e in s._rows:
		if e.get("troop") == "Test Drone":
			drone = e
	await _tap(_mid(drone["plus"]))
	var timer: Dictionary = s._rows[s._rows.size() - 2]
	await _tap(_mid(timer["minus"]))
	ck("a touch on a row's plus and minus", s.troops == {"Test Drone": 1} and s.wave_timer == 2, [s.troops, s.wave_timer])
	# Districts cleared is the row under it, below the fold: the list is dragged up to it
	var tries := 0
	while _mid(s._rows[s._rows.size() - 1]["plus"]).y > s.list.get_global_rect().end.y - 30 and tries < 12:
		var grab: Vector2 = s.list.get_global_rect().get_center()
		_touch(grab, true)
		await process_frame
		for d in 4:
			_drag(grab - Vector2(0, 30 * (d + 1)), Vector2(0, -30))
			await process_frame
		_touch(grab - Vector2(0, 120), false)
		await process_frame
		tries += 1
	await _tap(_mid(s._rows[s._rows.size() - 1]["plus"]))
	await _tap(_mid(s._rows[s._rows.size() - 1]["plus"]))
	ck("the list dragged up, touches on Districts cleared set Dimensional Instability", s.districts_cleared == 2 and s.wave_timer == 2 and s.troops == {"Test Drone": 1} and "6% chance" in s.note.text, [s.districts_cleared, s.wave_timer, s.note.text])
	await _tap(_mid(s.next_btn))
	var tb: Battle = scene.battle
	ck("a touch on Start battle starts it", tb != null and tb.with_cards and not s.visible and tb.wave_timer == 2 and tb.instability == 6 and tb.unit_by_id(tb.leader_id)["name"] == "Test Striker")
	await _tap(_mid(scene.hand_btn))
	var tray: HandTray = scene.hand_tray
	ck("a touch on Hand opens your hand", tray.visible and tray.grid.tiles.size() == 6)
	await _tap(_mid(tray.title))
	ck("a touch on the tray never reaches the board under it", scene.selected_id == "" and tray.visible and not scene.panel.visible)
	await _tap(_mid(tray.grid.tiles[1]))
	ck("a touch on a card in your hand opens it", scene.sheet != null and scene.sheet.card["name"] == tb.hand[1]["name"])
	await _tap(_mid(scene.sheet.buttons["close"]))
	await _tap(_mid(tray.close_btn))
	ck("touches on Close put the card, then the tray, away", scene.sheet == null and not tray.visible and scene.hand_btn.visible)
	# playing cards, by touch alone
	var r0: Roster = scene.roster
	tb.hand = ["Test Snare", "Test Mortar Strike", "Test Scout"].map(func(n): return Roster.hand_card(r0.card_named(n)))
	tb.aether = {"generic": 9, "d3": 9}
	scene._update_bar()
	await process_frame
	var foe: Dictionary = tb.side_units("enemy")[0]
	await _tap(_mid(scene.hand_btn))
	await _tap(_mid(tray.grid.tiles[0]))
	ck("a card's sheet, opened by touch, has Play", scene.sheet != null and scene.sheet.buttons.has("play") and not scene.sheet.buttons["play"].disabled)
	await _tap(_mid(scene.sheet.buttons["play"]))
	ck("a touch on Play puts the sheet and the tray away and lights who it can go to", scene.sheet == null and not tray.visible and scene.play.get("step") == "target" and scene.board.view_of(foe["id"]).targeted, scene.play.get("step"))
	await _tap(Vector2(640, 140))
	ck("a touch off the floor puts the card back, nothing spent", scene.play.is_empty() and tb.hand.size() == 3 and Rules.aether_total(tb.aether) == 18, [scene.play, tb.hand.size()])
	await _tap(_mid(scene.hand_btn))
	await _tap(_mid(tray.grid.tiles[0]))
	await _tap(_mid(scene.sheet.buttons["play"]))
	await _tap(_at(scene, Battle.tile_of(foe)))
	await _calm(scene)
	ck("a touch on a lit Enemy plays the card on it", Rules.has_status(foe, "Rooted") and tb.hand.size() == 2 and scene.play.is_empty() and tb.discard.size() == 1, [tb.hand.size(), scene.info.text])
	await _tap(_mid(scene.undo_btn))
	ck("a touch on Undo takes the card back", not Rules.has_status(foe, "Rooted") and tb.hand.size() == 3 and tb.discard.is_empty() and Rules.aether_total(tb.aether) == 18, scene.info.text)
	# a card aimed at a tile: one touch to see, another to play
	await _tap(_mid(scene.hand_btn))
	await _tap(_mid(tray.grid.tiles[1]))
	await _tap(_mid(scene.sheet.buttons["play"]))
	var spot := Battle.tile_of(foe)
	await _tap(_at(scene, spot))
	ck("the first touch on a tile shows the card's area and spends nothing", scene.play.get("at") == spot and not scene.board.blast.is_empty() and tb.hand.size() == 3 and foe["hp"] == foe["hpMax"])
	await _tap(_at(scene, spot))
	await _calm(scene)
	ck("the second plays it there", scene.play.is_empty() and tb.hand.size() == 2 and foe["hp"] < foe["hpMax"], [tb.hand.size(), foe["hp"]])
	# a Troop: with one Player Spawn Tile open it goes there by itself
	var open: Array = tb.open_spawns()
	await _tap(_mid(scene.hand_btn))
	await _tap(_mid(tray.grid.tiles[1]))
	ck("a Troop's sheet says where it will go", scene.sheet != null and scene.sheet.card["name"] == "Test Scout" and "Player Spawn Tile" in scene.sheet.note_label.text, scene.sheet.note_label.text if scene.sheet != null else "")
	await _tap(_mid(scene.sheet.buttons["play"]))
	if open.size() > 1:
		await _tap(_at(scene, open[0]))
	await _calm(scene)
	var came = tb.unit_at(open[0])
	ck("a touch on Play deploys the Troop", came != null and came["name"] == "Test Scout" and tb.hand.size() == 1 and scene.selected_id == came["id"], [open, tb.hand.size()])
	await _tap(_mid(scene.panel.close_btn))
	# a Consumable
	var hurt: Dictionary = tb.unit_by_id(tb.leader_id)
	hurt["hp"] = int(hurt["hpMax"]) - 8
	await _tap(_mid(scene.cons_btn))
	ck("a touch on Consumables opens them", tray.visible and tray.kind == "cons" and tray.grid.tiles.size() == 3)
	var stim := -1
	for i in tray.grid.tiles.size():
		if tray.grid.tiles[i].card["name"] == "Test Stim":
			stim = i
	await _tap(_mid(tray.grid.tiles[stim]))
	await _tap(_mid(scene.sheet.buttons["play"]))
	ck("a touch on Use lights who it can go to", scene.play.get("kind") == "cons" and scene.board.view_of(hurt["id"]).targeted)
	await _tap(_at(scene, Battle.tile_of(hurt)))
	await _calm(scene)
	ck("a touch on one of yours uses it on them", hurt["hp"] == int(hurt["hpMax"]) - 2 and scene.cons_btn.text == "Consumables 3", [hurt["hp"], scene.cons_btn.text])
	await _tap(_mid(scene.piles_btn))
	ck("a touch on the Deck and Discard count opens the Discard Pile", tray.visible and tray.kind == "discard" and tray.grid.tiles.size() == tb.discard.size() and tb.discard.size() == 1, tray.kind)
	await _tap(_mid(tray.close_btn))
	await _tap(_mid(scene.aether_btn))
	ck("a touch on Aether opens the Bank", scene.dialog != null and scene.dialog.title_label.text == "Aether")
	await _tap(_mid(scene.dialog.buttons[0]))
	# a card with a variable cost: X is chosen on its sheet
	tb.hand = [Roster.hand_card(r0.card_named("Test Barrage"))]
	tb.aether = {"generic": 3}
	scene._update_bar()
	await process_frame
	var mark0: Dictionary = tb.side_units("enemy").filter(func(e): return not Rules.truthy(e.get("down")))[0]
	mark0["hp"] = 30
	mark0["hpMax"] = 30
	await _tap(_mid(scene.hand_btn))
	await _tap(_mid(tray.grid.tiles[0]))
	ck("a variable cost's sheet, opened by touch, has X to choose", scene.sheet != null and scene.sheet.plus_btn != null and scene.sheet.value == 1 and scene.sheet.hi == 3)
	await _tap(_mid(scene.sheet.plus_btn))
	ck("a touch on plus raises X", scene.sheet.value == 2 and "at X = 2 it costs 2 any Aether" in scene.sheet.note_label.text, scene.sheet.note_label.text)
	await _tap(_mid(scene.sheet.buttons["play"]))
	await _tap(_at(scene, Battle.tile_of(mark0)))
	await _calm(scene)
	ck("a touch on Play, then on an Enemy, plays it for that X", mark0["hp"] == 28 and mark0["statuses"].any(func(st): return st["name"] == "Weakened" and int(Rules.num(st.get("n"), 0)) == 2) and Rules.aether_total(tb.aether) == 1, [tb.aether, mark0["hp"], mark0["statuses"]])
	# Auto: the switch, a Unit's Behavior keywords, and End turn
	await _tap(_mid(scene.auto_btn))
	ck("a touch on Auto switches it on", scene.auto and (scene.auto_btn.tooltip_text == "Auto: on" and scene.auto_btn.button_pressed))
	var lead: Dictionary = tb.unit_by_id(tb.leader_id)
	await _tap(_at(scene, Battle.tile_of(lead)))
	var bi := -1
	for i in scene.panel._rows.size():
		if scene.panel._rows[i].has("behavior"):
			bi = i
	var beh_rect: Rect2 = scene.panel.body.rows()[bi].get_global_rect() if bi >= 0 else Rect2()
	tries = 0
	while bi >= 0 and beh_rect.get_center().y > 690 and tries < 20:      # below the fold: the panel is dragged up to it
		var from2: Vector2 = scene.panel.body.get_global_rect().get_center()
		_touch(from2, true)
		await process_frame
		for d in 4:
			_drag(from2 - Vector2(0, 30 * (d + 1)), Vector2(0, -30))
			await process_frame
		_touch(from2 - Vector2(0, 120), false)
		await process_frame
		beh_rect = scene.panel.body.rows()[bi].get_global_rect()
		tries += 1
	await _tap(beh_rect.get_center())
	ck("a touch on the Unit's On Auto row opens its Behavior keywords", scene.beh_sheet != null and scene.selected_id == lead["id"], [bi, beh_rect])
	var bsh: BehaviorSheet = scene.beh_sheet
	await _tap(_mid(bsh._rows[1]["row"]))
	await _tap(Vector2(640, 20))
	ck("a touch on a keyword puts it on, and one outside the list does nothing", bsh.picked == [{"k": "decisive"}] and scene.beh_sheet != null and scene.selected_id == lead["id"], bsh.picked)
	await _tap(_mid(bsh.done_btn))
	ck("a touch on Done gives it to the Unit", scene.beh_sheet == null and lead["behaviors"] == [{"k": "decisive"}] and Behaviors.for_card(str(lead["src"])) == [{"k": "decisive"}], lead["behaviors"])
	await _tap(_mid(scene.panel.close_btn))
	var round0: int = tb.round
	await _tap(_mid(scene.next_btn))
	if scene.dialog != null:
		await _tap(_mid(scene.dialog.buttons[1]))
	await process_frame
	var auto_seen: bool = scene.auto_phase
	var waited := 0
	while (scene.auto_phase or scene.enemy_phase or scene.busy) and waited < 20000:
		auto_seen = auto_seen or scene.auto_phase
		if scene.dialog != null and not tb.over:
			await _tap(_mid(scene.dialog.buttons[0]))
		scene.fast = true
		await process_frame
		waited += 1
	ck("a touch on End turn, with Auto on: your Units take their turns, then the Enemies", auto_seen and (tb.round == round0 + 1 or tb.over) and not scene.busy, [auto_seen, tb.round, tb.over])
	if scene.dialog != null:
		await _tap(_mid(scene.dialog.buttons[scene.dialog.buttons.size() - 1]))
	await _tap(_mid(scene.auto_btn)) if not tb.over else scene.toggle_auto()
	if tb.over:
		scene.auto = false
	ck("a touch on Auto again switches it off", not scene.auto)
	await _tap(_mid(scene.new_btn))
	if tb.over and scene.dialog != null and scene.dialog.title_label.text != "Leave this battle?":
		# the fight ended on that turn: its result is up, and Home is on it
		await _tap(_mid(scene.dialog.buttons[2]))
		scene.open_setup("team")
		scene.show_home()
		ok += 1
		print("PASS a touch on Leave asks where to (the fight had ended: its result took the touch)")
	else:
		ck("a touch on Leave asks where to", scene.dialog != null and scene.dialog.title_label.text == "Leave this battle?")
	if scene.dialog != null:
		await _tap(_mid(scene.dialog.buttons[2]))
	ck("a touch on Home goes home", scene.home.visible and scene.battle == null and scene.dialog == null)
	# a Quick battle
	await _tap(_mid(scene.home.practice_btn))
	await _tap(_mid(scene.home.quick_btn))
	ck("a touch on Quick battle starts setting one up", s.visible and s.mode == "quick" and s.step == "floor")
	var row: Control = s._rows[wi]["row"]
	await _tap(row.get_global_rect().get_center())
	ck("a touch on a list row picks it", s.floor_i == wi, s.floor_i)
	await _tap(s.next_btn.get_global_rect().get_center())
	ck("a touch on a button presses it", s.step == "heroes", s.step)
	# a drag on the list scrolls it and picks nothing
	var start: Vector2 = s._rows[3]["row"].get_global_rect().get_center()
	_touch(start, true)
	await process_frame
	for k in 6:
		_drag(start - Vector2(0, 30 * (k + 1)), Vector2(0, -30))
		await process_frame
	_touch(start - Vector2(0, 180), false)
	await process_frame
	ck("a drag on the list scrolls it and picks nothing", s.list.scroll > 60 and s.heroes.is_empty(), [s.list.scroll, s.heroes])
	var r: Roster = scene.roster
	scene.start_battle(wi, [r.card_named("Test Warden")], [], 3)
	await process_frame
	await process_frame
	var bt: Battle = scene.battle
	var w: Dictionary = bt.side_units("ally")[0]
	var p: Vector2 = scene.get_viewport().get_canvas_transform() * scene.board.to_global(Board.at(Battle.tile_of(w)))
	await _tap(p)
	ck("a touch on a Unit selects it", scene.selected_id == w["id"] and scene.panel.visible, scene.selected_id)
	# a touch on the panel, over the board, goes to the panel
	var over: Vector2 = scene.panel.get_global_rect().get_center()
	await _tap(over)
	ck("a touch on the panel never reaches the board", scene.selected_id == w["id"] and scene.panel.visible)
	await _tap(scene.panel.close_btn.get_global_rect().get_center())
	ck("the panel's close button closes it", not scene.panel.visible and scene.selected_id == "")
	await _tap(p)
	var dest := Vector2i(-4, 0)
	var dp: Vector2 = scene.get_viewport().get_canvas_transform() * scene.board.to_global(Board.at(dest))
	await _tap(dp)
	var n := 0
	while scene.walking and n < 300:
		await process_frame
		n += 1
	ck("a touch on a lit tile walks the Unit there", Battle.tile_of(w) == dest and bt.has_moved(w), Battle.tile_of(w))
	# a drag on the board pans it and selects nothing
	var cam: Camera2D = scene.camera
	var was := cam.position
	scene.deselect()
	_touch(Vector2(400, 400), true)
	await process_frame
	for k in 5:
		_drag(Vector2(400 + 20 * (k + 1), 400), Vector2(20, 0))
		await process_frame
	_touch(Vector2(500, 400), false)
	await process_frame
	ck("a drag on the board pans it and picks nothing", cam.position.x < was.x - 50 and scene.selected_id == "", [was, cam.position])
	# an Action, picked by touch in the panel, then a target
	var g: Dictionary = bt.side_units("enemy")[0]
	g["pos"] = {"q": dest.x + 1, "r": dest.y}
	scene.board.view_of(g["id"]).position = Board.at(Vector2i(dest.x + 1, dest.y))
	dp = scene.get_viewport().get_canvas_transform() * scene.board.to_global(Board.at(dest))   # the board was panned
	await _tap(dp)
	for f in 20:
		await process_frame
	var vi := -1
	for i in scene.panel._rows.size():
		if scene.panel._rows[i].has("action") and scene.panel._rows[i].get("live", false) and vi < 0:
			vi = i
	var row_ctl: Control = scene.panel.body.rows()[vi]
	await _tap(row_ctl.get_global_rect().get_center())
	ck("a touch on an Action in the panel aims it", scene.aiming >= 0 and scene.targets.has(g["id"]), [scene.aiming, scene.targets, vi, scene.selected_id])
	var gp: Vector2 = scene.get_viewport().get_canvas_transform() * scene.board.to_global(Board.at(Battle.tile_of(g)))
	var nrg0: int = w["nrg"]
	await _tap(gp)
	ck("a touch on a lit target attacks it", w["nrg"] < nrg0 and g.get("lastAttackedBy") == w["id"], [w["nrg"], g.get("lastAttackedBy")])
	var m := 0
	while scene.busy and m < 600:
		await process_frame
		m += 1
	await _tap(scene.next_btn.get_global_rect().get_center())
	var asked: bool = scene.dialog != null
	if asked:
		await _tap(scene.dialog.buttons[1].get_global_rect().get_center())
	await process_frame
	ck("End turn, by touch (and End the turn, if it asks)", scene.enemy_phase or bt.round == 2, [asked, bt.round])
	var k := 0
	while scene.enemy_phase and k < 3000:
		await process_frame
		k += 1
	ck("the Enemies take their turn, and it's round 2", bt.round == 2 and not scene.busy, bt.round)
	# an area Action: the first touch on a target shows the blast, the second fires
	for a in w["actions"]:
		if a["name"] == "Pinning Volley":
			a["text"] = "[[target enemy]] is caught in an [[AoE 1]] blast."
			a["hit"] = 1
	w["hp"] = w["hpMax"]
	scene.deselect()
	var wp: Vector2 = scene.get_viewport().get_canvas_transform() * scene.board.to_global(Board.at(Battle.tile_of(w)))
	await _tap(wp)
	for f in 20:
		await process_frame
	var ai := -1
	for i in scene.panel._rows.size():
		if scene.panel._rows[i].has("action") and scene.panel._rows[i].get("live", false) and ai < 0:
			ai = i
	await _tap(scene.panel.body.rows()[ai].get_global_rect().get_center())
	for f in 20:
		await process_frame
	gp = scene.get_viewport().get_canvas_transform() * scene.board.to_global(Board.at(Battle.tile_of(g)))
	var nrg1: int = w["nrg"]
	var lines1 := bt.log.size()
	await _tap(gp)
	ck("the first touch on an area Action's target only shows its blast", scene.preview == g["id"] and not scene.board.blast.is_empty() and w["nrg"] == nrg1 and bt.log.size() == lines1, [scene.preview, scene.aiming, w["nrg"], nrg1])
	for f in 20:
		await process_frame
	gp = scene.get_viewport().get_canvas_transform() * scene.board.to_global(Board.at(Battle.tile_of(g)))
	await _tap(gp)
	ck("the second fires it", w["nrg"] < nrg1 and bt.log.size() > lines1 and scene.preview == "", [w["nrg"], nrg1])
	m = 0
	while scene.busy and m < 600:
		await process_frame
		m += 1
	# Hold fire, the gold button under an Action with Suppressive Fire
	var hi := -1
	for i in scene.panel._rows.size():
		if scene.panel._rows[i].has("hold"):
			hi = i
	var hold_rect: Rect2 = scene.panel.body.rows()[hi].get_global_rect() if hi >= 0 else Rect2()
	var guard := 0
	while hi >= 0 and hold_rect.get_center().y > 700 and guard < 20:      # below the fold: drag the list up to it
		var from: Vector2 = scene.panel.body.get_global_rect().get_center()
		_touch(from, true)
		await process_frame
		for d in 4:
			_drag(from - Vector2(0, 30 * (d + 1)), Vector2(0, -30))
			await process_frame
		_touch(from - Vector2(0, 120), false)
		await process_frame
		hold_rect = scene.panel.body.rows()[hi].get_global_rect()
		guard += 1
	var nrg2: int = w["nrg"]
	if hi >= 0:
		await _tap(hold_rect.get_center())
	ck("a touch on Hold fire holds it", hi >= 0 and w.get("holding") != null and w["nrg"] == nrg2 - 2 and scene.board.view_of(w["id"]).shown["holding"], [hi, w.get("holding"), w["nrg"], nrg2, hold_rect])
	await _workshop(scene)
	await _dock(scene)
	await _world(scene)
	print("\nTOUCH PASS %d  FAIL %d" % [ok, bad])
	# (0.14) the last tap's blip plays out first: one still playing at exit is reported as a leak
	await create_timer(0.6).timeout
	scene.queue_free()
	Kit.fresh()
	await process_frame
	Rules.hooks = {}              # the rules let go of the last battle
	quit(1 if bad > 0 else 0)


## Where a tile of the World Map is on the screen.
func _map_at(scene: Node, k: String) -> Vector2:
	return scene.get_viewport().get_canvas_transform() * scene.map_view.to_global(scene.map_view.centre_of(k))


## The control under a node that a tap with this meaning lands on.
func _act_node(n: Node, what: Array) -> Control:
	var todo: Array = [n]
	while not todo.is_empty():
		var k = todo.pop_front()
		if k is Control and k.has_meta("act") and k.get_meta("act") == what and k.is_visible_in_tree():
			return k
		todo.append_array(k.get_children())
	return null


func _button_called(n: Node, text: String) -> Button:
	var todo: Array = [n]
	while not todo.is_empty():
		var k = todo.pop_front()
		if k is Button and k.text == text and k.is_visible_in_tree():
			return k
		todo.append_array(k.get_children())
	return null


## A tap on what a sheet offers, by its meaning.
func _tap_act(n: Node, what: Array) -> bool:
	var c := _act_node(n, what)
	if c == null:
		return false
	await _tap(_mid(c))
	return true


## 0.9: the Workshop, a design built and an effect put together, by touch alone.
func _workshop(scene: Node) -> void:
	# (a team that can leave, for the deployment after)
	Kit.keep([Kit.team(), Kit.field_team("Field Vanguard")])
	scene.show_home()
	await process_frame
	var cm: Campaign = scene.campaign
	var dk: DockScreen = scene.dock_screen
	var wsn: WorkshopScreen = scene.workshop_screen
	var ed: DesignEditor = wsn.editor
	await _tap(_mid(scene.home.world_btn))
	await _tap(_mid(dk.shop_btn))
	ck("a touch on Workshop opens it", wsn.visible and not dk.visible and wsn.tab == "designs")
	await _tap(_mid(wsn.tabs["blueprints"]))
	ck("a touch on a tab shows it", wsn.tab == "blueprints" and wsn.row_texts()[0] == "testing")
	await _tap(_mid(wsn.tabs["designs"]))
	await _tap(_mid(wsn.new_btn))
	ck("a touch on New design offers the chassis", wsn.picking and wsn.row_texts()[0] == "Test Frame · General")
	await _tap(_mid(wsn._rows[0]["row"]))
	ck("a touch on a chassis makes the design and opens it", ed.visible and ed.d["name"] == "New design" and cm.workshop.by_name("New design") != null)
	var e0: int = ed.d["abilities"][0]["energy"]
	await _tap_act(ed.list, ["num", 0, "energy", 1])
	ck("a touch on + steps a number", ed.d["abilities"][0]["energy"] == e0 + 1, ed.d["abilities"][0])
	var opened := await _tap_act(ed.list, ["build", 0])
	ck("a touch on + Add an effect opens the builder", opened and ed.sheet != null)
	var sh: BuilderSheet = ed.sheet
	await _tap_act(sh.list, ["kb", "none"])
	await _tap_act(sh.list, ["kb", "target enemy"])
	ck("a touch on a choice takes it", sh.title.text == "Narrow them down?", sh.title.text)
	await _tap(_mid(sh.next_btn))
	await _tap_act(sh.list, ["kb", "damage"])
	ck("a touch on a chip takes it, and asks its number", sh.title.text == "damage", sh.title.text)
	await _tap_act(sh.list, ["step", 1])
	await _tap_act(sh.list, ["kb", "pv:ok"])
	await _tap(_mid(sh.next_btn))
	ck("touches build the sentence", sh.title.text == "Review the effect" and sh.insert_btn.visible and "damage 2" in sh.sentence.text, [sh.title.text, sh.sentence.text])
	await _tap_act(sh.list, ["edit", "effect"])
	ck("a touch on Change goes back to that step", sh.title.text == "What does it do?", sh.title.text)
	await _tap(_mid(sh.next_btn))
	await _tap(_mid(sh.insert_btn))
	ck("a touch on Insert puts it into the ability", ed.sheet == null and ed.d["abilities"][0]["text"] == "[[target enemy]] takes [[damage 2]]." and cm.workshop.by_name("New design")["abilities"][0]["text"] == ed.d["abilities"][0]["text"], ed.d["abilities"][0]["text"])
	await _tap(_mid(_button_called(ed, "Workshop")))
	ck("a touch on Workshop goes back to the list", not ed.visible and wsn.visible and wsn.row_texts().has("New design"), wsn.row_texts())
	await _tap(_mid(wsn.back_btn))
	ck("a touch on Dock goes back to the dock", dk.visible and not wsn.visible)
	await _tap(_mid(dk.back_btn))


## Brings a control inside the dock's list up where a thumb can reach it.
func _into_view(dk: DockScreen, c: Control) -> void:
	var guard := 0
	while c != null and _mid(c).y > 600 and guard < 30:
		dk.list.scroll_by(120)
		await process_frame
		guard += 1


## 0.10: the dock's tabs, the Exchange and the Pack, by touch alone.
func _dock(scene: Node) -> void:
	scene.show_home()
	await process_frame
	var cm: Campaign = scene.campaign
	var dk: DockScreen = scene.dock_screen
	var gift := Loot.bag()
	gift["shards"] = 200
	cm.dock.add_to_stockpile(gift)
	await _tap(_mid(scene.home.world_btn))
	ck("the dock opens on its Stockpile", dk.visible and dk.tab == "stockpile")
	await _tap(_mid(dk.tabs["exchange"]))
	ck("a touch on the Exchange tab opens it", dk.tab == "exchange" and dk.tabs["exchange"].button_pressed and not dk.tabs["stockpile"].button_pressed, dk.tab)
	var nm: String = cm.dock.stock()["items"][0]
	var chip := _act_node(dk.list, ["buy_card", nm, 1])
	await _into_view(dk, chip)
	var sh0: int = cm.dock.stockpile()["shards"]
	var had: int = cm.dock.owned(nm)
	if chip != null:
		await _tap(_mid(chip))
	ck("a touch on Buy 1 buys one", cm.dock.owned(nm) == had + 1 and cm.dock.stockpile()["shards"] == sh0 - 20, [dk.note.text, cm.dock.owned(nm)])
	await _tap(_mid(dk.tabs["upgrades"]))
	ck("a touch on the Upgrades tab opens it", dk.tab == "upgrades" and dk.row_texts().size() == 4, dk.row_texts())
	await _tap_act(dk.list, ["upgrade", "scanner"])
	ck("a touch on an upgrade's chip asks the dock for it", dk.note.text.begins_with("Needs ") or dk.note.text == "Upgraded to level 1.", dk.note.text)
	await _tap(_mid(dk.tabs["stockpile"]))
	await _tap_act(dk.list, ["testing", "restock"])
	ck("a touch on Restock now asks first", dk.dialog != null and dk.dialog.title_label.text == "Restock now?")
	await _tap(_mid(dk.dialog.buttons[1]))
	ck("a touch on Not now closes it", dk.dialog == null)
	# the Pack
	await _tap(_mid(dk.go_btn))
	var able := -1
	for i in dk._rows.size():
		if dk._rows[i].has("team") and cm.deploy.reasons_against(dk.teams[dk._rows[i]["team"]]).is_empty():
			able = i
	await _tap(_mid(dk._rows[able]["row"]))
	ck("a Strike Team chosen, the Pack lists what the dock keeps", dk.row_texts().has("Pack") and dk.row_texts().has(nm), dk.row_texts())
	var was := int(dk.pack.get(nm, 0))
	var first: Array = ["pack", nm, 1] if was == 0 else ["pack", nm, -1]
	var then: Array = ["pack", nm, -1] if was == 0 else ["pack", nm, 1]
	var c1 := _act_node(dk.list, first)
	await _into_view(dk, c1)
	if c1 != null:
		await _tap(_mid(c1))
	var mid := int(dk.pack.get(nm, 0))
	var c2 := _act_node(dk.list, then)
	await _into_view(dk, c2)
	if c2 != null:
		await _tap(_mid(c2))
	ck("touches on + and − pack one, and take it out again", mid == was + int(first[2]) and int(dk.pack.get(nm, 0)) == was, [was, mid, dk.pack])
	await _tap(_mid(dk.back_btn))
	await _tap(_mid(dk.back_btn))
	ck("a touch on Back, then Home, leaves the dock", scene.home.visible and not dk.visible)


## 0.8: the dock, the World Map and a deployment, by touch alone.
func _world(scene: Node) -> void:
	scene.show_home()
	await process_frame
	var cm: Campaign = scene.campaign
	var ms: MapScreen = scene.map_screen
	var dk: DockScreen = scene.dock_screen
	cm.world.tables["ambushStep"] = 0
	await _tap(_mid(scene.home.world_btn))
	ck("a touch on World Map opens the dock", dk.visible and not scene.home.visible)
	await _tap(_mid(dk.go_btn))
	ck("a touch on Deploy lists the Strike Teams", dk.choosing and dk._rows.size() >= 1)
	var able := -1
	for i in dk._rows.size():
		if dk._rows[i].has("team") and cm.deploy.reasons_against(dk.teams[dk._rows[i]["team"]]).is_empty():
			able = i
	await _tap(_mid(dk._rows[able]["row"]))
	ck("a touch on a Strike Team chooses it", dk.team_i == dk._rows[able]["team"] and not dk.go_btn.disabled)
	await _tap(_mid(dk.go_btn))
	for f in 6:
		await process_frame
	ck("a touch on Leave the dock sends it out and opens the map", cm.deploy.active() and ms.visible and scene.map_view.visible and not dk.visible)
	# a tile, and the way to it
	var goal := ""
	for k in cm.world.map["tiles"]:
		var way: Array = cm.world.path("0,0", k)
		if way.size() == 3 and cm.world.content_at(k) == null and _map_at(scene, k).x < 760 and _map_at(scene, k).y > 150:
			goal = k
			break
	await _tap(_map_at(scene, goal))
	ck("a touch on a tile of the map chooses it", ms.selected == goal and scene.map_view.route.size() == 3, [goal, ms.selected])
	# the panel lies over the map: a touch on it never reaches the tiles under it
	var under: String = scene.map_view.key_at(scene.map_view.to_local(scene._screen_to_world(_mid(ms.p_title))))
	await _tap(_mid(ms.p_title))
	ck("a touch on the panel never reaches the map under it", ms.selected == goal and under != "" and under != goal, [under, ms.selected])
	var below: String = scene.map_view.key_at(scene.map_view.to_local(scene._screen_to_world(_mid(ms.fit_btn))))
	var zoom0: Vector2 = scene.camera.zoom
	await _tap(_mid(ms.fit_btn))
	ck("a touch on Fit fits the map, and chooses nothing under the bar", scene.camera.zoom.x < zoom0.x and ms.selected == goal, [below, scene.camera.zoom])
	await _tap(_mid(ms.find_btn))
	for f in 3:
		await process_frame
	ck("a touch on Find team comes back to it", scene.camera.zoom == Vector2.ONE)
	# drag to pan, two fingers to zoom
	var cam0: Vector2 = scene.camera.position
	_touch(Vector2(300, 420), true)
	await process_frame
	for k in 5:
		_drag(Vector2(300 + 30 * (k + 1), 420), Vector2(30, 0))
		await process_frame
	_touch(Vector2(450, 420), false)
	await process_frame
	ck("a drag pans the map and chooses nothing", scene.camera.position.x < cam0.x - 100 and ms.selected == goal, [cam0, scene.camera.position])
	_touch(Vector2(300, 400), true, 0)
	_touch(Vector2(500, 400), true, 1)
	await process_frame
	var d1 := InputEventScreenDrag.new()
	d1.index = 1
	d1.position = root.get_final_transform() * Vector2(600, 400)
	d1.relative = root.get_final_transform().basis_xform(Vector2(100, 0))
	root.push_input(d1)
	await process_frame
	_touch(Vector2(600, 400), false, 1)
	_touch(Vector2(300, 400), false, 0)
	await process_frame
	ck("two fingers apart zoom it in", scene.camera.zoom.x > 1.2, scene.camera.zoom)
	await _tap(_mid(ms.find_btn))
	for f in 3:
		await process_frame
	# walk
	await _tap(_map_at(scene, goal))
	await _tap(_mid(ms._buttons[0]))
	var n := 0
	while ms.walking and n < 600:
		await process_frame
		n += 1
	ck("a touch on Walk here walks there", cm.deploy.cur()["pos"] == goal and cm.deploy.cur()["steps"] == 2 and not ms.walking, cm.deploy.cur()["pos"])
	# the Team box covers the map
	await _tap(_mid(ms.team_btn))
	ck("a touch on Team opens the team's box", ms.dialog != null)
	var was: String = ms.selected
	await _tap(Vector2(120, 600))
	ck("a touch outside the box does nothing to the map", ms.dialog != null and ms.selected == was)
	await _tap(_mid(ms.dialog.buttons[0]))
	ck("a touch on Close puts it away", ms.dialog == null)
	# an ambush, its setup and its fight
	cm.world.tables["ambushStep"] = 100
	var step_to: String = World.neighbours(goal).filter(func(k): return cm.world.is_open(k) and cm.world.content_at(k) == null and k != cm.world.dock())[0]
	await _tap(_map_at(scene, step_to))
	await _tap(_mid(ms._buttons[0]))
	n = 0
	while ms.walking and n < 600:
		await process_frame
		n += 1
	ck("a step into an ambush stops at it", cm.deploy.cur()["activity"] != null and ms.actions().map(func(a): return a["id"]) == ["fight"])
	await _tap(_mid(ms._buttons[0]))
	for f in 4:
		await process_frame
	var s: SetupScreen = scene.setup
	ck("a touch on Fight opens who enters", s.visible and s.mode == "deploy" and s.step == "heroes")
	await _tap(_mid(s.next_btn))
	ck("a touch on Next goes on to the Starting Troops", s.step == "troops")
	await _tap(_mid(s.next_btn))
	for f in 6:
		await process_frame
	ck("a touch on Start battle starts the deployment's fight", scene.battle != null and scene.battle.deploy != null and not s.visible and scene.board.visible and not scene.map_view.visible)
	var hero: Dictionary = scene.battle.side_units("ally")[0]
	await _tap(_at(scene, Battle.tile_of(hero)))
	ck("a touch on the board reaches the board again", scene.selected_id == hero["id"])
	await _tap(_mid(scene.new_btn))
	ck("a touch on Leave asks first", scene.dialog != null and scene.dialog.title_label.text == "Leave this fight?")
	await _tap(_mid(scene.dialog.buttons[1]))
	for f in 4:
		await process_frame
	ck("a touch on Back to the map goes back, the fight still waiting", ms.visible and scene.battle == null and cm.deploy.cur()["activity"] != null)
	await _tap(_mid(ms.home_btn))
	ck("a touch on Home goes home, the team still out", scene.home.visible and not ms.visible and cm.deploy.active())
	await _tap(_mid(scene.home.world_btn))
	for f in 4:
		await process_frame
	ck("and World Map goes straight back to it", ms.visible and not dk.visible and scene.map_view.team_at == step_to)
