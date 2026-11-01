## (0.45) Deployments played through the screen, as on the phone: the built-in
## export (or another), music and sounds on, things moving, the first fight's
## field guide shown. A Strike Team leaves the dock, walks the World Map,
## fights what it meets (an ambush, a POI's floors) through the setup screen,
## plays each fight with Auto and cards from the hand, takes the result, and
## goes on; a team home or wiped out leaves again. It looks for a fight that
## breaks (a script error is in the output), one that gets stuck, and the
## engine's warnings.
##   godot --headless --path . --script res://tests/soak_deploy.gd -- [export=<zip>] [fights=<n>] [seed=<n>] [speed=fast|normal|instant] [fidget=1] [verbose=1]
extends SceneTree

const Kit := preload("res://tests/team_kit.gd")
const FIXTURE := "res://tests/fixtures/export.zip"

var scene: Node2D
var rng := RandomNumberGenerator.new()
var opts := {"export": FIXTURE, "fights": "8", "seed": "5", "speed": "instant"}
var stuck: Array = []
var fights := 0
var rounds := 0
var cards_played := 0
var results := {}
var fidget_on := false          # a finger busy on the screen while the fight plays (fidget=1)
var fidgets := {}


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## Waits while the fight is busy (walking, an animation, the Enemies' turn), up to a limit.
func _settle(what: String, limit := 6000) -> bool:
	var n := 0
	while scene.battle != null and (scene.busy or scene.walking or scene.auto_phase) and n < limit:
		await process_frame
		n += 1
	if n >= limit:
		stuck.append(what)
		return false
	return true


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		if kv.size() == 2:
			opts[kv[0]] = kv[1]
	rng.seed = int(opts["seed"])
	OS.low_processor_usage_mode_sleep_usec = 0
	Kit.fresh()
	# as the phone has it: music and sounds on, things moving, the field guide unread
	Music.auto = true
	Motion.sound = true
	Motion.music = "high"
	Motion.still = false
	Motion.speed = str(opts["speed"])
	Motion.coached = false
	Kit.keep([Kit.field_team()])
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await _frames(2)
	scene.load_export(opts["export"])
	await _frames(2)
	var cm: Campaign = scene.campaign
	if cm == null:
		print("SOAK DEPLOY: no campaign in this export")
		quit(1)
		return
	var want := int(opts["fights"])
	var walks := 0
	while fights < want and walks < 4000:
		if not cm.deploy.active():
			await _leave()
			if not cm.deploy.active():
				print("SOAK DEPLOY: the team can't leave: ", scene.dock_screen.note.text)
				break
		var c = cm.deploy.cur()
		if c["activity"] != null:
			await _fight()
			continue
		# what the tile offers: a POI to enter, a cache, an event's choice
		var acts: Array = scene.map_screen.actions().map(func(x): return x["id"])
		if acts.has("enter"):
			scene.map_screen.do("enter")
			await _frames(2)
			continue
		if acts.has("cache"):
			scene.map_screen.do("cache")
		if acts.has("choose"):
			scene.map_screen.do("choose", 0)
			await _frames(2)
			if cm.deploy.cur() != null and cm.deploy.cur()["activity"] != null:
				continue
		# walk: to a tile not yet stood on, near by, now and then home
		var to := _next_tile(cm)
		if to == "":
			break
		walks += 1
		await scene.map_screen.walk(to)
		await _frames(2)
		if scene.map_screen.dialog != null:
			scene.map_screen.dialog.buttons[scene.map_screen.dialog.buttons.size() - 1].pressed.emit()
			await _frames(1)
	print("(deployments: %d fights, %d rounds, %d cards played, results %s, fidgets %s)" % [fights, rounds, cards_played, results, fidgets])
	for s in stuck:
		print("STUCK " + s)
	print("\nSOAK DEPLOY PASS %d  FAIL %d" % [fights, stuck.size()])
	Music.auto = false
	Kit.fresh()
	scene.queue_free()
	await _frames(3)
	quit(1 if not stuck.is_empty() else 0)


## The team leaves the dock: the first Strike Team, with what it takes.
func _leave() -> void:
	var cm: Campaign = scene.campaign
	var b := Loot.bag()
	b["shards"] = 5000
	for ty in ["troop", "equipment", "aether"]:
		b["parts"][ty] = [60, 30, 20, 10, 5, 2]
	cm.deploy.stock = Loot.add(cm.deploy.stock, b)
	scene.open_dock()
	await _frames(2)
	var dk: DockScreen = scene.dock_screen
	if dk.dialog != null:
		dk.dialog.chosen.emit(0)
		await _frames(1)
	dk.show_teams()
	dk.choose_team(0)
	await _frames(1)
	if dk.field_btn.visible:
		dk.field_copy()
		await _frames(1)
	dk.leave()
	await _frames(4)


## The next tile to walk to: one beside the team not stood on, else any beside it.
func _next_tile(cm: Campaign) -> String:
	var w := cm.world
	var at: String = str(cm.deploy.cur()["pos"])
	var near: Array = w.neighbours(at).filter(func(k): return w.is_open(k))
	if near.is_empty():
		return ""
	var fresh := near.filter(func(k): return not w.state["stood"].has(str(k)))
	var pick: Array = fresh if not fresh.is_empty() and rng.randf() < 0.85 else near
	return str(pick[rng.randi() % pick.size()])


## A fight that is waiting: set up through the screen, played, its result taken.
func _fight() -> void:
	scene.map_screen.do("fight")
	await _frames(2)
	var su: SetupScreen = scene.setup
	var n := 0
	while scene.battle == null or not scene.board.visible:
		if not su.visible or n > 8:
			stuck.append("fight %d: the setup never started the fight (step %s)" % [fights, su.step])
			scene.show_map()
			return
		su._go(1)
		await _frames(2)
		n += 1
	fights += 1
	var b: Battle = scene.battle
	if OS.get_cmdline_user_args().has("fidget=1"):
		fidget_on = true
		_fidget(b)
	var r := 0
	while scene.battle == b and not b.over and r < 40:
		r += 1
		rounds += 1
		if not await _settle("fight %d round %d: busy before its turn" % [fights, r]):
			return
		# a card from the hand, played the way a finger would, now and then
		if r % 2 == 1 and not b.hand.is_empty():
			await _play_a_card(b)
			if not await _settle("fight %d round %d: busy after a card" % [fights, r]):
				return
		if b.over:
			break
		# the field guide, read and put away
		if scene.coach != null and rng.randf() < 0.5:
			scene.coach.queue_free()
			scene.coach = null
		scene.auto = rng.randf() < 0.8
		await scene.end_turn()
		await _frames(2)
		if not await _settle("fight %d round %d: the Enemies' turn never ended" % [fights, r]):
			return
	if scene.battle == b and not b.over:
		# a long fight: ended by hand, as the soak ends one
		for u in b.side_units("enemy"):
			u["hp"] = 0
			u["down"] = true
		b.wave = b.waves_total
		b.enemy_pile.clear()
		b.fx.check_downs()
		b.settle()
		scene.board.refresh_units(b)
		scene.show_result()
	fidget_on = false
	await _frames(4)
	# the result comes a moment after the last blow (and a Victory's neon first)
	var wait := 0
	while scene.dialog == null and wait < 1500:
		if scene.neon != null and wait % 60 == 30:
			scene.neon.finish()
		await process_frame
		wait += 1
	if scene.dialog == null:
		stuck.append("fight %d: no result came" % fights)
	if OS.get_cmdline_user_args().has("verbose=1"):
		print("fight %d: %d rounds, over %s, winner %s, battle still this one %s, deploy_out %s, dialog %s" % [fights, r, b.over, b.winner, scene.battle == b,
			str(scene.deploy_out.keys()) if scene.deploy_out is Dictionary else str(scene.deploy_out), scene.dialog.title_label.text if scene.dialog != null else "none"])
	var out := str(scene.deploy_out.get("next", "?")) if scene.deploy_out is Dictionary else "?"
	results[out] = int(results.get(out, 0)) + 1
	# the result's box: go on (the next floor, the map, retry with the reserves)
	var k := 0
	while scene.dialog != null and k < 6:
		scene.dialog.buttons[0].pressed.emit()
		await _frames(3)
		k += 1
	await _frames(2)


## A card from the hand, played as on the screen: the tray, its sheet's Play, then a lit tile.
func _play_a_card(b: Battle) -> void:
	var ok := []
	for i in b.hand.size():
		if b.play_state(b.hand[i])["ok"]:
			ok.append(i)
	if ok.is_empty():
		return
	var i: int = ok[rng.randi() % ok.size()]
	scene.begin_play("hand", i)
	await _frames(2)
	var tries := 0
	while not scene.play.is_empty() and tries < 4:
		var lit: Array = _targets(b)
		if lit.is_empty():
			scene._play_cancel()
			break
		var h: Vector2i = lit[rng.randi() % lit.size()]
		await scene._play_tap(h)
		await _frames(2)
		if not scene.play.is_empty() and scene.play.get("at") == h:
			await scene._play_tap(h)          # an area: the second tap plays it
			await _frames(2)
		tries += 1
	if not scene.play.is_empty():
		scene._play_cancel()
	else:
		cards_played += 1


## Where a card being played can go now: lit Units' tiles, lit spawn tiles, or any floor tile.
func _targets(b: Battle) -> Array:
	match str(scene.play.get("step", "")):
		"unit", "target":
			var out := []
			for id in scene.play.get("pool", {}):
				var u = b.unit_by_id(id)
				if u != null and u.get("pos") is Dictionary:
					out.append(Battle.tile_of(u))
			return out
		"spawn":
			return scene.board.reach.keys()
		"tile":
			return b.units.filter(func(u): return u["side"] == "enemy" and not Rules.truthy(u.get("down")) and u.get("pos") is Dictionary).map(func(u): return Battle.tile_of(u))
	return []


## (fidget=1) A finger that won't keep still while the fight plays: the board
## tapped (hurrying the Enemies, choosing a Unit), the hand opened and shut and a
## card read, the Log looked at, Back pressed (and the box it asks with put away).
func _fidget(b: Battle) -> void:
	while fidget_on and scene.battle == b and not b.over:
		await _frames(rng.randi_range(3, 25))
		if not fidget_on or scene.battle != b or b.over:
			return
		var live: Array = b.units.filter(func(u): return not Rules.truthy(u.get("down")) and u.get("pos") is Dictionary)
		var k := rng.randi() % 7
		var did: String = ["tap", "hand", "read", "log", "back", "select", "deselect"][k]
		fidgets[did] = int(fidgets.get(did, 0)) + 1
		match did:
			"tap":
				if not live.is_empty():
					scene._on_tile_tapped(Battle.tile_of(live[rng.randi() % live.size()]))
			"hand":
				if scene.battle != null and not scene.busy:
					scene.toggle_hand()
					await _frames(rng.randi_range(1, 6))
					if scene.hand_tray.visible:
						scene._close_tray()
			"read":
				if not b.hand.is_empty() and scene.sheet == null and scene.dialog == null and not scene.busy:
					scene.read_hand_card(rng.randi() % b.hand.size())
					await _frames(rng.randi_range(1, 8))
					if scene.sheet != null:
						scene.go_back()
			"log":
				scene.toggle_log()
				await _frames(rng.randi_range(1, 6))
				if scene.log_panel.visible:
					scene.toggle_log()
			"back":
				scene.go_back()
				await _frames(rng.randi_range(1, 4))
				if scene.dialog != null and scene.dialog.title_label.text.begins_with("Leave this"):
					scene.dialog.chosen.emit(scene.dialog.safe_index())
			"select":
				var mine := live.filter(func(u): return u["side"] == "ally")
				if not mine.is_empty() and not scene.busy and scene.play.is_empty():
					scene.select(mine[rng.randi() % mine.size()])
			"deselect":
				if not scene.busy:
					scene.deselect()
