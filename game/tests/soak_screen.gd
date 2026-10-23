## The same idea as soak.gd, through the screen: battles with the export's
## real cards, driven by taps as a player would make them. Every Unit is
## tapped (so its panel is drawn), moved, aimed with each Action it can use
## and fired (the blast previewed first where there is one, a Burst followed
## to its end), a hold is taken where one is offered, boxes are put away, the
## Log is opened, and the Enemies' turns are played back. Every third one is a
## Strike Team's Battle: the hand is opened and a card read, the Aether box
## looked at, cards are played from the hand, Consumables used and Chips
## spent the way a finger would (the tray, a tile, the sheet's button, then
## whatever lights up), some of them put back or taken back with Undo, and
## the round's phases play out after the Enemies. A card with a variable
## cost has its X stepped on its sheet; a carried Action card that asks for X
## is answered in its box. Now and then a Unit's Behavior keywords are
## changed in the picker, and in every other fight Auto is switched on: End
## turn is tapped, and the Units left alone take their own turns. It checks
## that the screen never breaks, never gets stuck, and shows what is so: the
## loot count, the tiles emptied, the result.
##   godot --headless --path . --script res://tests/soak_screen.gd [-- fights]
extends SceneTree

const FIXTURE := "res://tests/fixtures/export.zip"
const Kit := preload("res://tests/team_kit.gd")
var rng := RandomNumberGenerator.new()
var scene: Node2D
var stuck: Array = []
var taps := 0
var boxes := 0                 # card-problem boxes met and put away
var plays := {"hand": 0, "cons": 0, "chips": 0, "off": 0, "back": 0, "undone": 0, "asked": 0, "recover": 0, "shown": 0,
	"x": 0, "x_action": 0, "x_away": 0, "picker": 0, "auto_turns": 0, "auto_rounds": 0, "loot_seen": 0, "results": 0}


func _initialize() -> void:
	_run.call_deferred()


func _pick(list: Array):
	return list[rng.randi() % list.size()]


func _tap(h: Vector2i) -> void:
	taps += 1
	scene._on_tile_tapped(h)
	await process_frame


## Waits for the screen to be ready for the next tap, putting away any box.
func _ready_again(what: String) -> void:
	var n := 0
	while (scene.busy or scene.walking or scene.dialog != null or scene.auto_phase) and n < 4000:
		if scene.dialog != null and scene.battle != null:
			if scene.battle.over and not scene.busy and not scene.walking:
				return                    # the result is up: the fight is done
			if not scene.battle.over:
				boxes += 1
				scene.dialog.buttons[scene.dialog.buttons.size() - 1].pressed.emit()
		await process_frame
		n += 1
	if n >= 4000:
		stuck.append(what)


## What has dropped is what the screen says has: the count under the top
## bar, and the tiles dimmed on the board.
func _loot_true(when: String) -> void:
	var bt: Battle = scene.battle
	if scene.loot_label.text != scene.loot_words() or scene.loot_label.visible != (not Loot.is_empty(bt.loot)):
		stuck.append("%s: the loot count says '%s' (%s) and the haul is %s" % [when, scene.loot_label.text, "shown" if scene.loot_label.visible else "hidden", bt.loot_table.text(bt.loot)])
	if scene.board.searched.size() != bt.looted.size() or not bt.looted.keys().all(func(h): return scene.board.searched.has(h)):
		stuck.append("%s: the board dims %d tiles, and %d have been emptied" % [when, scene.board.searched.size(), bt.looted.size()])
	if not Loot.is_empty(bt.loot):
		plays["loot_seen"] += 1
	# (0.14) Auto is an icon: its name is in its tooltip, and it stays lit while on
	if scene.auto_btn.tooltip_text != ("Auto: on" if scene.auto else "Auto: off") or scene.auto_btn.button_pressed != scene.auto:
		stuck.append("%s: the Auto switch says %s (%s)" % [when, scene.auto_btn.tooltip_text, "lit" if scene.auto_btn.button_pressed else "not lit"])


## (0.14) The Aether button says what you have: in words in its tooltip, and a
## gem for each point.
func _aether_true() -> bool:
	var bt: Battle = scene.battle
	return scene.aether_btn.tooltip_text == "Aether " + UI.show(Battle.aether_label(bt.aether)) and scene.aether_gems.gems().size() == int(Rules.aether_total(bt.aether))


## A Unit's Behavior keywords, changed in the picker as a finger would: its
## row in the panel, a few keywords tapped, Done.
func _pick_behaviors(u: Dictionary) -> void:
	var bi := -1
	for i in scene.panel._rows.size():
		if scene.panel._rows[i].has("behavior") and scene.panel._rows[i].get("live", false):
			bi = i
	if bi < 0:
		stuck.append("%s's panel has no On Auto row to tap" % u["name"])
		return
	scene.panel._on_row(bi, Vector2.ZERO)
	await process_frame
	await process_frame
	var sh: BehaviorSheet = scene.beh_sheet
	if sh == null:
		stuck.append("the Behavior picker wouldn't open for %s" % u["name"])
		return
	for k in rng.randi_range(1, 5):
		var e: Dictionary = _pick(sh._rows)
		var row: Control = e["row"]
		var key: String = _pick(["", "", "plus", "minus"])
		var c: Control = e[key] if (key != "" and e.has(key)) else row
		sh.list.tap(c.global_position - sh.list.global_position + (c.size / 2.0 if c != row else Vector2(40, 10)))
		await process_frame
		await process_frame
		if sh.picked.size() > 3:
			stuck.append("the picker let %s carry %d Behavior keywords" % [u["name"], sh.picked.size()])
	var chosen: Array = sh.picked.duplicate(true)
	sh.done_btn.pressed.emit()
	await process_frame
	await process_frame
	plays["picker"] += 1
	var card := str(u.get("src") if Rules.truthy(u.get("src")) else u["name"])
	if scene.beh_sheet != null or u["behaviors"] != chosen or Behaviors.for_card(card) != chosen:
		stuck.append("%s was given %s, has %s, and the game remembers %s" % [u["name"], str(chosen), str(u["behaviors"]), str(Behaviors.for_card(card))])


## The bottom row says what the battle holds.
func _bar_true(when: String) -> void:
	var bt: Battle = scene.battle
	var left := bt.consumables.filter(func(c): return not Rules.truthy(c.get("used"))).size()
	if scene.hand_btn.text != "Hand %d" % bt.hand.size():
		stuck.append("%s: the button says %s with %d in hand" % [when, scene.hand_btn.text, bt.hand.size()])
	if scene.cons_btn.visible and scene.cons_btn.text != "Consumables %d" % left:
		stuck.append("%s: the button says %s with %d left" % [when, scene.cons_btn.text, left])
	if not scene.piles_btn.text.ends_with("Discard %d" % bt.discard.size()) or not scene.piles_btn.text.begins_with("Deck %d" % bt.deck.size()):
		stuck.append("%s: the count says %s with %d and %d" % [when, scene.piles_btn.text, bt.deck.size(), bt.discard.size()])
	if not _aether_true():
		stuck.append("%s: the Aether button says %s, with %d gems" % [when, scene.aether_btn.tooltip_text, scene.aether_gems.gems().size()])
	if scene.next_btn.disabled or not scene.play.is_empty():
		stuck.append("%s: End turn is still waiting" % when)


## A random hand at the cards, as a finger would: a tray opened, a tile
## tapped, the sheet's button pressed, then whatever it asks for tapped. One
## in six is put back instead with a tap off the floor, and one in four that
## can be is taken back with Undo.
func _play_some() -> void:
	var bt: Battle = scene.battle
	var tray: HandTray = scene.hand_tray
	for k in rng.randi_range(1, 4):
		if bt.over or not stuck.is_empty():
			return
		var kind: String = _pick(["hand", "hand", "hand", "cons", "chips"])
		var btn: Button = {"hand": scene.hand_btn, "cons": scene.cons_btn, "chips": scene.chips_btn}[kind]
		if not btn.visible:
			continue
		btn.pressed.emit()
		await process_frame
		if not tray.visible or tray.kind != kind:
			stuck.append("the %s tray wouldn't open" % kind)
			return
		if tray.grid.tiles.is_empty():
			tray.close_btn.pressed.emit()
			await process_frame
			continue
		var ti: int = rng.randi() % tray.grid.tiles.size()
		var tile = tray.grid.tiles[ti]
		var nm: String = tile.card["name"]
		var faded: bool = tile.faded
		tray.grid.tap(tray.grid.tile_centre(ti))
		await process_frame
		if scene.sheet == null or not scene.sheet.buttons.has("play"):
			stuck.append("%s wouldn't open from the %s tray" % [nm, kind])
			return
		var pb: Button = scene.sheet.buttons["play"]
		if pb.disabled != faded:
			stuck.append("%s is %s in the tray, and its button is %s" % [nm, "faded" if faded else "lit", "off" if pb.disabled else "on"])
		if pb.disabled:
			scene.sheet.buttons["close"].pressed.emit()
			await process_frame
			tray.close_btn.pressed.emit()
			await process_frame
			plays["off"] += 1
			continue
		var was := [bt.hand.size(), Rules.aether_total(bt.aether), bt.discard.size(), bt.units.size(), bt.log.size()]
		var undo0 := bt.undo.size()
		# a variable cost: X is stepped on the sheet first, as far as it will go or less
		var x_card = null
		var x_want := 0
		if kind == "hand" and Roster.card_var(bt.hand[tray.refs[ti]]):
			x_card = bt.hand[tray.refs[ti]]
			var cs: CardSheet = scene.sheet
			if cs.count_label == null or cs.lo != 1 or cs.hi != maxi(1, bt.max_x(x_card)):
				stuck.append("%s has a variable cost, and its sheet offers X from %d to %d (the Bank could pay %d)" % [nm, cs.lo, cs.hi, bt.max_x(x_card)])
				return
			for step in rng.randi_range(0, cs.hi):
				cs.plus_btn.pressed.emit()
			if rng.randf() < 0.3 and cs.value > 1:
				cs.minus_btn.pressed.emit()
			await process_frame
			x_want = cs.value
			if not ("at X = %d it costs" % x_want) in cs.note_label.text:
				stuck.append("%s's sheet is at X = %d and says: %s" % [nm, x_want, cs.note_label.text])
		elif kind == "hand" and scene.sheet.count_label != null:
			stuck.append("%s has no variable cost, and its sheet offers X" % nm)
		pb.pressed.emit()
		await process_frame
		await process_frame
		if scene.sheet != null or (tray.visible and tray.kind != "recover"):
			stuck.append("the sheet or the tray stayed up when %s was played" % nm)
			return
		var put_back := false
		var guard := 0
		while not scene.play.is_empty() and guard < 16 and stuck.is_empty():
			guard += 1
			plays["asked"] += 1
			if scene.next_btn.disabled == false:
				stuck.append("End turn is on while %s is being played" % nm)
			if rng.randf() < 0.25:
				scene._on_off_board()
				await process_frame
				put_back = true
				break
			if scene.play.get("at") != null and rng.randf() < 0.7:
				# its area is showing: the same place again plays it
				plays["shown"] += 1
				if scene.board.blast.is_empty():
					stuck.append("%s shows no area where it would land" % nm)
				await _tap(scene.play["at"])
				await _ready_again("playing " + nm)
				continue
			match str(scene.play.get("step")):
				"spawn":
					await _tap(_pick(scene.board.reach.keys()))
				"unit", "target":
					await _tap(Battle.tile_of(bt.unit_by_id(_pick(scene.play["pool"].keys()))))
				"tile":
					await _tap(_pick(bt.floor_data.tiles.keys()))
				"recover":
					plays["recover"] += 1
					tray.grid.tap(tray.grid.tile_centre(rng.randi() % tray.grid.tiles.size()))
					await process_frame
				_:
					stuck.append("%s is being played, and asks for nothing (%s)" % [nm, scene.play.get("step")])
			await _ready_again("playing " + nm)
		if not scene.play.is_empty():
			stuck.append("%s never landed" % nm)
			return
		await _ready_again("after " + nm)
		if bt.over:
			return
		if put_back:
			plays["back"] += 1
			if [bt.hand.size(), Rules.aether_total(bt.aether), bt.discard.size(), bt.units.size(), bt.log.size()] != was or bt.undo.size() != undo0:
				stuck.append("%s was put back, yet something was spent" % nm)
			_bar_true("after %s is put back" % nm)
			continue
		plays[kind] += 1
		if x_card != null:
			plays["x"] += 1
			if x_card.get("x") != x_want:
				stuck.append("%s was played for X = %d, and the card says X = %s" % [nm, x_want, str(x_card.get("x"))])
		_bar_true("after " + nm)
		_loot_true("after " + nm)
		for u in bt.units:
			if u.get("pos") is Dictionary and scene.board.view_of(u["id"]) == null:
				stuck.append("%s arrived with %s, and isn't on the board" % [u["name"], nm])
		if scene.undo_btn.visible != (not bt.undo.is_empty()):
			stuck.append("after %s, Undo is %s with %d to take back" % [nm, "shown" if scene.undo_btn.visible else "hidden", bt.undo.size()])
		if scene.undo_btn.visible and bt.undo.size() == undo0 + 1 and rng.randf() < 0.25:
			scene.undo_btn.pressed.emit()
			await process_frame
			await process_frame
			plays["undone"] += 1
			if [bt.hand.size(), Rules.aether_total(bt.aether), bt.discard.size(), bt.units.size(), bt.log.size()] != was:
				stuck.append("%s was taken back, yet not everything was: %s, was %s" % [nm, str([bt.hand.size(), Rules.aether_total(bt.aether), bt.discard.size(), bt.units.size(), bt.log.size()]), str(was)])
			for id in scene.board.views:
				if bt.unit_by_id(id) == null:
					stuck.append("%s was taken back, and what it deployed is still on the board" % nm)
			_bar_true("after %s is taken back" % nm)
		scene.deselect()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var want := int(args[0]) if args.size() > 0 else 24
	rng.seed = 41
	Engine.time_scale = 30.0          # walks and pauses, hurried along
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	Kit.fresh()
	scene.load_export(FIXTURE)
	var r: Roster = scene.roster
	var fights := 0
	var team_fights := 0
	var cards_read := 0
	var phases := 0
	var attacks := 0
	var previews := 0
	var bursts := 0
	var holds := 0
	var moving_fights := 0
	for i in want:
		# (0.12) every other fight plays with everything moving, at Fast: the taps
		# come as shots fly, Units hop and boxes pop, and nothing may break or stick
		Motion.still = i % 2 == 0
		Motion.speed = "fast"
		if not Motion.still:
			moving_fights += 1
		var fi: int = i % int(scene.floors.size())
		var heroes: Array = r.heroes().duplicate()
		var hc := []
		for k in Roster.hero_capacity(scene.floors[fi]):
			if not heroes.is_empty():
				hc.append(heroes.pop_at(rng.randi() % heroes.size()))
		var tc := []
		for k in rng.randi_range(0, 2):
			tc.append(_pick(r.troops()))
		# and one that is sure to try something: a Burst, a blast, a Sacrifice, a card problem
		var sure = r.card_named(["Test Drone", "Test Sapper", "Test Battery", "Scuttle brood mother", "Test Scout", "Defensive Platform Specialist"][i % 6])
		if sure != null:
			tc.append(sure)
		var team_fight := i % 3 == 2
		if team_fight:
			var team: Dictionary = Kit.random_team(r, rng)
			scene.start_team_battle(fi, team, Kit.entry(team, r, scene.floors[fi], rng), rng.randi())
			team_fights += 1
		else:
			scene.start_battle(fi, hc, tc, rng.randi())
		await process_frame
		await _ready_again("the start of battle %d" % i)
		var bt: Battle = scene.battle
		var rounds := 0
		# every other fight is fought with Auto on: the switch, then End turn
		var auto_fight := i % 2 == 1
		if scene.auto != auto_fight:
			scene.auto_btn.pressed.emit()
			await process_frame
		if scene.auto != auto_fight:
			stuck.append("the Auto switch wouldn't turn %s" % ("on" if auto_fight else "off"))
		_loot_true("at the start of battle %d" % i)
		while not bt.over and rounds < (6 if team_fight else 4) and stuck.is_empty():
			if team_fight:
				# the hand, a card in it, and the Aether box
				scene.toggle_hand()
				await process_frame
				if not scene.hand_tray.visible or scene.hand_tray.grid.tiles.size() != bt.hand.size():
					stuck.append("the hand shows %d cards of %d" % [scene.hand_tray.grid.tiles.size(), bt.hand.size()])
				if not bt.hand.is_empty():
					scene.read_hand_card(rng.randi() % bt.hand.size())
					await process_frame
					if scene.sheet == null:
						stuck.append("a card in the hand wouldn't open")
					else:
						cards_read += 1
						scene.sheet.buttons["close"].pressed.emit()
						await process_frame
				scene.toggle_hand()
				scene.show_bank()
				await process_frame
				if scene.dialog == null or scene.hand_tray.visible:
					stuck.append("the Aether box wouldn't open, or the hand wouldn't close")
				else:
					scene.dialog.buttons[0].pressed.emit()
					await process_frame
				await _play_some()
				if bt.over or not stuck.is_empty():
					break
			for u in bt.side_units("ally"):
				if Rules.truthy(u.get("down")) or bt.over or not (u.get("pos") is Dictionary):
					continue
				await _tap(Battle.tile_of(u))
				if scene.selected_id != u["id"]:
					continue
				if rng.randf() < 0.12:
					await _pick_behaviors(u)
					if not stuck.is_empty():
						break
				# with Auto on, most Units are left for it
				if auto_fight and rng.randf() < 0.65:
					continue
				var hold_rows: Array = scene.panel._rows.filter(func(row): return row.has("hold"))
				if not hold_rows.is_empty() and rng.randf() < 0.5:
					scene.panel.hold_pressed.emit(hold_rows[0]["hold"])
					holds += 1
					await process_frame
				if not scene.board.reach.is_empty() and rng.randf() < 0.8:
					await _tap(_pick(scene.board.reach.keys()))
					await _ready_again("a move by " + str(u["name"]))
					if rng.randf() < 0.15 and scene.undo_btn.visible:
						scene.undo_move()
						await process_frame
				for k in 3:
					if Rules.truthy(u.get("down")) or bt.over or scene.selected_id != u["id"]:
						break
					var live: Array = scene.panel._rows.filter(func(row): return row.has("action") and row.get("live", false))
					if live.is_empty():
						break
					var picked_i: int = _pick(live)["action"]
					var bank_before: int = int(Rules.aether_total(bt.aether))
					scene.panel.action_pressed.emit(picked_i)
					await process_frame
					# a carried Action card that asks for X: its box, a few steps, then Aim it (or it is put away)
					var asks: bool = u["actions"][picked_i].get("aetherX") is Dictionary
					if asks != (scene.xdlg != null):
						stuck.append("%s's %s %s for X" % [u["name"], u["actions"][picked_i]["name"], "wasn't asked" if asks else "was asked"])
						break
					if scene.xdlg != null:
						var xd: XDialog = scene.xdlg
						if xd.hi != bt.action_max_x(u["actions"][picked_i]):
							stuck.append("%s offers X up to %d, and the Bank could pay %d" % [u["actions"][picked_i]["name"], xd.hi, bt.action_max_x(u["actions"][picked_i])])
						for step in rng.randi_range(0, xd.hi):
							xd.plus_btn.pressed.emit()
						if rng.randf() < 0.2:
							xd.cancel_btn.pressed.emit()
							await process_frame
							await process_frame
							plays["x_away"] += 1
							if scene.aiming >= 0 or scene.xdlg != null or int(Rules.aether_total(bt.aether)) != bank_before:
								stuck.append("%s was put away, and something was aimed or spent" % u["actions"][picked_i]["name"])
							break
						var want_x: int = xd.value
						xd.ok_btn.pressed.emit()
						await process_frame
						await process_frame
						plays["x_action"] += 1
						if scene.xdlg != null or u["actions"][picked_i].get("x") != want_x:
							stuck.append("%s was to be aimed for X = %d, and has X = %s" % [u["actions"][picked_i]["name"], want_x, str(u["actions"][picked_i].get("x"))])
					if scene.aiming < 0 or scene.targets.is_empty():
						break
					var guard := 0
					while scene.aiming >= 0 and not scene.targets.is_empty() and guard < 12:      # a Burst asks again
						guard += 1
						var t = bt.unit_by_id(_pick(scene.targets.keys()))
						if Effects.has_area(u["actions"][scene.aiming]):
							await _tap(Battle.tile_of(t))
							previews += 1
							if scene.preview != t["id"]:
								stuck.append("no preview for " + str(u["actions"][scene.aiming]["name"]))
								break
						if not scene.burst.is_empty():
							bursts += 1
						await _tap(Battle.tile_of(t))
						attacks += 1
						await _ready_again("%s's %s" % [u["name"], "attack"])
						if scene.burst.is_empty():
							break
					if not scene.burst.is_empty():
						stuck.append("a Burst by %s never ended" % u["name"])
				_loot_true("after %s's turn" % u["name"])
			if bt.over or not stuck.is_empty():
				break
			# look at an Enemy, and at the Log
			var foes := bt.side_units("enemy").filter(func(e): return not Rules.truthy(e.get("down")) and e.get("pos") is Dictionary)
			if not foes.is_empty():
				scene.deselect()
				await _tap(Battle.tile_of(_pick(foes)))
			scene.toggle_log()
			await process_frame
			if scene.log_panel.haul.visible != (not Loot.is_empty(bt.loot)):
				stuck.append("the Log's head %s what has dropped, with %s in the haul" % ["shows" if scene.log_panel.haul.visible else "doesn't show", bt.loot_table.text(bt.loot)])
			scene.toggle_log()
			scene.deselect()
			# End turn, as a finger does it: the button, and End the turn if it asks
			var in_line := bt.auto_queue() if scene.auto else []
			var foes_up := bt.enemies_left()
			scene.next_btn.pressed.emit()
			await process_frame
			if scene.dialog != null and not bt.over:
				var asked_of: PackedStringArray = scene.dialog.text_label.text.split(" can still")[0].replace(" and ", ", ").split(", ")
				# (0.21) by name, so a name two of yours share (two Test Drones, one used, one not) proves nothing
				if scene.auto and in_line.any(func(id): var nm := str(bt.unit_by_id(id)["name"]); return asked_of.has(nm) and not bt.units.any(func(o): return o["side"] == "ally" and str(o["name"]) == nm and not in_line.has(o["id"]))):
					stuck.append("End turn asked about a Unit Auto was about to take: %s" % scene.dialog.text_label.text)
				scene.dialog.buttons[1].pressed.emit()
				await process_frame
			if scene.auto and not in_line.is_empty() and foes_up > 0:
				plays["auto_rounds"] += 1
				plays["auto_turns"] += in_line.size()
				if not scene.auto_phase and not scene.enemy_phase and not bt.over:
					stuck.append("Auto was on with %d Units in line, and End turn didn't start their turns" % in_line.size())
			scene.fast = true
			var n := 0
			var named := ""
			while (scene.enemy_phase or scene.auto_phase or (scene.busy and not bt.over)) and n < 20000:
				if scene.dialog != null:
					boxes += 1
					scene.dialog.buttons[0].pressed.emit()
				if scene.banner.visible and scene.banner_title.text != named:
					named = scene.banner_title.text
					phases += 1
				if scene.auto_phase and not scene.next_btn.disabled:
					stuck.append("End turn is on while Auto is playing")
				scene.fast = true
				await process_frame
				n += 1
			if n >= 20000:
				stuck.append("the Enemies' turn in battle %d" % i)
			if scene.auto != auto_fight:
				stuck.append("Auto switched itself %s" % ("off" if auto_fight else "on"))
			await _ready_again("the start of a round")
			rounds += 1
			if team_fight and not bt.over:
				if scene.banner.visible or scene.upkeep or bt.phase != "turn":
					stuck.append("the round's phases didn't finish in battle %d" % i)
				if scene.hand_btn.text != "Hand %d" % bt.hand.size() or scene.wave_label.text != scene.wave_text() or not scene.wave_label.text.begins_with("Wave %d of 6" % bt.wave):
					stuck.append("the bar is behind: %s, %s" % [scene.hand_btn.text, scene.wave_label.text])
				if not _aether_true():
					stuck.append("the Aether button is behind: %s, with %d gems" % [scene.aether_btn.tooltip_text, scene.aether_gems.gems().size()])
			_loot_true("as round %d begins" % bt.round)
			# every view shows what is so
			for u in bt.units:
				var v: UnitView = scene.board.view_of(u["id"])
				if u.get("pos") is Dictionary and v == null:
					stuck.append("%s has no view" % u["name"])
				elif v != null and not Rules.truthy(u.get("down")) and v.shown.get("hp") != u.get("hp"):
					stuck.append("%s shows %s Health, has %s" % [u["name"], str(v.shown.get("hp")), str(u.get("hp"))])
		# a fight still going when its rounds are up is ended by hand, won or lost in turn, so its result is read
		if not bt.over and stuck.is_empty():
			var win := i % 2 == 0
			for u in bt.side_units("enemy" if win else "ally"):
				if not Rules.truthy(u.get("down")):
					Rules.hit(u, 9999)
			bt.fx.check_downs()
			if win:
				bt.wave = bt.waves_total
				bt.enemy_pile.clear()
			await _ready_again("ending battle %d by hand" % i)
			if bt.settle():
				scene.board.refresh_units(bt)
				scene.show_result()
				await process_frame
		if bt.over:
			await _ready_again("the end of battle %d" % i)
			if scene.dialog == null:
				scene.show_result()
				await process_frame
			var told: String = scene.dialog.text_label.text if scene.dialog != null else ""
			var res: Dictionary = bt.loot_result
			plays["results"] += 1
			if res.is_empty():
				stuck.append("battle %d ended and its loot wasn't settled" % i)
			elif res["won"] and not ("Dropped and found: " + bt.loot_table.text(res["haul"]) + ".") in told:
				stuck.append("battle %d was won, and the result doesn't say what dropped: %s" % [i, told])
			elif res["won"] and not Loot.is_empty(res["reward"]) and not ("The floor's reward: " + bt.loot_table.text(res["reward"])) in told:
				stuck.append("battle %d paid a floor's reward the result doesn't name: %s" % [i, told])
			elif not res["won"] and not Loot.is_empty(res["haul"]) and not "Lost with the fight" in told:
				stuck.append("battle %d was lost with a haul, and the result doesn't say it's lost: %s" % [i, told])
			_loot_true("at the end of battle %d" % i)
		if scene.dialog != null:
			scene.dialog.buttons[scene.dialog.buttons.size() - 1].pressed.emit()      # See the board
			await process_frame
		fights += 1
		if not stuck.is_empty():
			break
	Motion.still = true
	print("(0.12: %d of them played with everything moving, at Fast; %d shots fired)" % [moving_fights, scene.fxl.fired.size()])
	print("(%d taps, %d attacks, %d blasts previewed, %d Burst attacks chosen, %d holds, %d boxes put away)" % [taps, attacks, previews, bursts, holds, boxes])
	print("(%d of them a Strike Team's Battle: %d cards read from the hand, %d phases announced)" % [team_fights, cards_read, phases])
	print("(played by touch: %d cards from the hand, %d Consumables, %d Chips; %d times it asked where or who, %d an area shown first; %d a Troop's card to Recover; %d put back, %d taken back with Undo; %d that couldn't be played had Play off)" % [
		plays["hand"], plays["cons"], plays["chips"], plays["asked"], plays["shown"], plays["recover"], plays["back"], plays["undone"], plays["off"]])
	print("(0.7: %d cards played for an X stepped on the sheet; %d carried Actions aimed for an X, %d put away; the Behavior picker used %d times; Auto played %d rounds, %d Units' turns; the loot count checked %d times with loot to count; %d results read)" % [
		plays["x"], plays["x_action"], plays["x_away"], plays["picker"], plays["auto_rounds"], plays["auto_turns"], plays["loot_seen"], plays["results"]])
	if team_fights >= 8 and (plays["hand"] < 10 or plays["cons"] < 2 or plays["back"] < 2 or plays["undone"] < 2):
		stuck.append("too few cards were played for this to have tried them: %s" % str(plays))
	if want >= 24 and (plays["picker"] < 5 or plays["auto_rounds"] < 10 or plays["loot_seen"] < 10):
		stuck.append("too little of 0.7 was tried: %s" % str(plays))
	# (said after the counts, so that a count too low is said too)
	for s2 in stuck.slice(0, 10):
		print("FAIL " + s2)
	# (0.14) the last tap's blip and any box still popping play out first: one
	# still going at exit is reported as a leak. (0.15: in time as it passes:
	# at thirty times, 0.6 seconds was 20 milliseconds, and the last fight's
	# sounds were still playing)
	Engine.time_scale = 1.0
	await create_timer(0.6).timeout
	scene.queue_free()
	Kit.fresh()
	await process_frame
	await process_frame
	Rules.hooks = {}
	print("\nSCREEN SOAK PASS %d  FAIL %d" % [fights if stuck.is_empty() else 0, stuck.size()])
	quit(1 if not stuck.is_empty() else 0)
