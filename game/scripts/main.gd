## KETER v0.8: the World Map and a deployment.
##
## The game opens on a home screen: World Map, Battle, Quick battle, Strike
## Teams.
##
## World Map leads to the dock, where a Strike Team is sent out. On the map
## it walks tile by tile: tap a tile, then Walk here. A step may spring an
## ambush. A POI is a run of floors fought in order; a Cache is opened; an
## Event asks for a choice, sometimes on a d20. Each fight is a Battle with
## the team as it stands: a Hero who went down sits out, a Troop that fell
## and a Consumable that was used are gone until home. Loot rides in the haul
## and is kept once the team walks back onto the dock; a wipe loses it. The
## map, the stockpile and what you have found are saved as you go
## (campaign.gd); a fight is not, and starts again from its setup.
##
## Battle and Quick battle are practice: what drops is shown, and not kept.
##
## Strike Teams are built and kept in the game: up to 3 Heroes, a Deck they
## share, the Action cards each carries, an Aether Pouch, Prototypes and a
## Player Level. A Battle sends one into a floor: six waves of Enemies, and
## each round Heroes generate Aether, Chips are drawn into the Bank, and cards
## are drawn into your hand. Along the bottom are Hand, Consumables and Chips:
## each opens a tray of tiles. Tap a card to read it, then Play: a Troop lands
## on the open Player Spawn Tile you tap, Equipment goes on the Unit you tap,
## and a Command or Aether card does what it says, on whoever or wherever you
## tap if it needs a target (an area shows what it would take in first). A
## Consumable is used and a Chip spent for its effect the same way. Undo takes
## back the last move or card until dice are rolled. A Quick battle is the
## free pick of before: any Heroes and Troops, one wave, no Deck.
##
## In a fight, tap one of your Units: the side panel shows it, with its
## Actions as buttons, and the tiles it can reach are lit (amber where a
## hazard would bite). Tap a lit tile and it walks there. Tap an Action and
## the targets it can reach light up, each with its odds; tap one and the dice
## are rolled and shown, and what the Action's text says is carried out. An
## Action with an area shows its blast on the first tap and fires on the
## second. A Burst asks for each next target. An Action with Suppressive Fire
## can be held. End turn: the Enemies act on their own, one at a time (a tap
## hurries them), then the round's phases play out, each announced, and it's
## your turn again. A card that can't do what it says stops the fight on a box
## saying so. The battle ends when every Enemy is down with no more to come,
## or every Hero is.
##
## 0.7. Auto, in the top bar: with it on, End turn has every Unit of yours
## that you haven't used this turn take its turn by itself, by its Behavior
## keywords (set in its panel, and remembered for its card), before the
## Enemies take theirs. Loot drops as Enemies fall and is found on Loot Tiles
## and in Locked Chests; it is shown and totalled, with the floor's own reward
## on a win, and not kept yet. A card with a variable cost asks for its X as
## it is played. Dimensional Instability, set as a Battle is set up, may send
## an Elite or a Mini-Boss in place of an ordinary Enemy.
##
## 0.8 (Handbook 15.9). A Status ticks at the end of the turn after the one it
## arrived in: one from your turn at the Recharge, one from the Enemies' turn
## as you end your next turn, before the Enemies act.
extends Node2D

## (0.33) the project's own version: it was written out by hand here, and fell behind
var VERSION: String = str(ProjectSettings.get_setting("application/config/version", ""))
const TAP_MOVE := 14.0        # a touch that moves further than this is a drag
const TAP_TIME := 450         # ms; longer is a press, not a tap
const ZOOM_MIN := 0.25
const ZOOM_MAX := 3.5
## (0.14) the board's zoom comes to rest at whole steps: one art pixel is 1, 2, 3 or 4 screen pixels
const ZOOM_STEPS := [0.5, 1.0, 1.5, 2.0]
const BAR_H := 72.0
const HAND_W := 128.0        # the Hand button
const CONS_W := 190.0        # the Consumables button
const CHIPS_W := 118.0       # the Chips button
const BANNER_W := 660.0      # the phase banner
const HURT := Color("#ff2a3c")
const OWN := Color("#ff3d7f")          # (0.11) your own Unit caught in a blast: not the Enemies' red
const MEND := Color("#59cf93")
const PALE := Color("#c5c7dd")
const LOOT := Color("#efdd91")

var data := KeterExport.new()
var roster: Roster = null
var floors: Array[FloorData] = []
var battle: Battle = null
var selected_id := ""
var aiming := -1              # the Action being aimed (its index), or -1
var targets := {}             # unit id -> odds, while aiming
var tile_aim := {}            # 0.23: the tiles an Action aimed at a tile can go to (Vector2i -> true)
var tile_at = null            # 0.23: the tile it is previewed on, before the second tap
var aim_pool: Array = []      # the ids of the Units the Action being aimed could go to
var preview := ""             # the target an area Action's blast is being shown on, or ""
var burst := {}               # a Burst waiting on its next target: {unit, action, left}
var walking := false          # a Unit of yours is on its way
var busy := false             # dice rolling, or the Enemies taking their turn
var enemy_phase := false
var fast := false             # a tap during the Enemies' turn hurries them
var upkeep := false           # the round's phases are playing out, before your turn
var play := {}                # a card, Consumable or Chip being played: {kind, i, name, type, needs, step, pool, recover, at}
var last_setup := []          # what the last battle was started with, for Play again
var auto := false             # Auto: on End turn, the Units you haven't used take their own turns
var auto_phase := false       # they are taking them now
var campaign: Campaign = null # the World Map as you know it, the stockpile, what you have found, who is out
var deploy_out := {}          # what the deployment said of the fight that just ended ({} until it has)

var board: Board
var camera: Camera2D
var ui: Control
var transition: Transition       # (0.19) one screen giving way to the next
var neon: NeonScene = null       # (0.19) Victory or Defeat, powering on
var _neon_for = null             # the fight it played for
var overlay: Overlay
var home: HomeScreen
var teams_screen: TeamsScreen
var forge_screen: ForgeScreen   # (0.26) the Sandbox: the Card Forge
var handoff: HandoffScreen      # (0.26) pass and play: the screen covered between turns
var chassis_screen: ChassisScreen   # (0.28) the Sandbox: the Chassis builder
var poi_screen: PoiScreen           # (0.29) the Sandbox: the POI Sandbox
var studio_screen: StudioScreen     # (0.30) the Sandbox: the Pixel Studio
var saves_screen: SavesScreen       # (0.32) the three save files
var _sandbox_recalled := false      # (0.33) each tool's list as it was last left: read once
var _teams_for_setup := false   # (0.26) Strike Teams was opened from a match's setup: back there after
var map_view: MapView
var map_screen: MapScreen
var dock_screen: DockScreen
var workshop_screen: WorkshopScreen
var setup: SetupScreen
var panel: UnitPanel
var hand_tray: HandTray
var sheet: CardSheet = null
var banner: PanelContainer
var banner_title: Label
var banner_text: Label
var wave_label: Label
var aether_btn: Button
var hand_btn: Button
var cons_btn: Button
var chips_btn: Button
var piles_btn: Button
var home_note := ""           # what the home screen has to say about the export
var log_panel: LogPanel
var dialog: Dialog = null
var xdlg: XDialog = null      # choosing X for a carried Action card
var beh_sheet: BehaviorSheet = null
var auto_btn: Button
var loot_label: Label
var floor_label: Label
var round_label: Label
var undo_btn: Button
var log_btn: Button
var next_btn: Button
var new_btn: Button
var fit_btn: Button
var source_text := ""        # which export the content came from (the home screen shows it)
var info: Label
var info_back: InfoBack                 # the bar behind it (0.11)
var info_more: Button                   # (0.14) "?": the bottom line in full, when it is cut
var aether_gems: AetherGems             # (0.14) a gem for each point of Aether, on the Aether button
var _info_fade: Tween = null
var _info_right := -14.0
var fxl: Motion                         # (0.12) shots, sparks and bursts over the board
var sound: Sound                        # (0.12) the game's sounds
var options: OptionsBox = null          # (0.12) Speed, Screen shake and Sound
var look_board: LookBoard = null        # (0.14) every piece of the look, to check on a phone
var speed_btn: Button                   # (0.12) on a fight's bar: the speed, and Options
var curtain: ColorRect                  # (0.12) a screen fades in through it
var _screen_was := ""
var _shake_tween: Tween = null

var _touches := {}            # index -> position
var _press := {}              # index -> {at, start, moved}
var _pinch_dist := 0.0
var _mouse_drag := false
var _mouse_start := Vector2.ZERO
var _mouse_moved := 0.0
var _cam_tween: Tween = null


func _ready() -> void:
	# (0.12) the speed, shake and sound you chose, and the game's sounds; a tap on any button is heard
	Motion.settings()
	# (0.32) the save file last played: its run and its Strike Teams
	if SaveSlots.auto:
		SaveSlots.start()
	sound = Sound.new()
	add_child(sound)
	get_tree().node_added.connect(_on_node_added)
	board = Board.new()
	add_child(board)
	fxl = Motion.new()
	board.add_child(fxl)
	board.tile_tapped.connect(_on_tile_tapped)
	board.off_board_tapped.connect(_on_off_board)
	map_view = MapView.new()
	map_view.visible = false
	add_child(map_view)
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	_build_ui()
	transition = Transition.new()
	add_child(transition)
	# (0.19) the Android app asks to read your Downloads, where your exports land; once allowed, it looks again
	if OS.has_feature("android") and not KeterExport.android_can_read():
		get_tree().on_request_permissions_result.connect(func(_perm, granted):
			if granted:
				load_export())
		OS.request_permission("android.permission.MANAGE_EXTERNAL_STORAGE")
	get_viewport().size_changed.connect(_fit)
	load_export()


## (0.32) The phone's Back button goes back a step, as the screen's own Back,
## Home or Close would; on Home it asks before leaving the game.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_keep_sandbox()


## (0.33) The game going to the background or closing: what the Sandbox has
## open and unsaved is kept as a draft, and where you were in it.
func _keep_sandbox() -> void:
	for pair in _sandbox_tools():
		var s = pair[1]
		if s != null and s.visible:
			Sandbox.ui()["tool"] = pair[0]
			var d: Dictionary = s.draft()
			if not d.is_empty():
				Sandbox.keep_draft(d)
	_remember_sandbox()


func _sandbox_tools() -> Array:
	return [["forge", forge_screen], ["chassis", chassis_screen], ["poi", poi_screen], ["studio", studio_screen]]


## Each tool's list as it was left, kept for next time.
func _remember_sandbox() -> void:
	if forge_screen == null:
		return
	var u := Sandbox.ui()
	for pair in _sandbox_tools():
		u[pair[0]] = pair[1].remember()
	Sandbox.save()


func go_back() -> void:
	# a box over everything first: the topmost one shown
	var top: Control = null
	var stack: Array = [ui]
	while not stack.is_empty():
		var n = stack.pop_front()
		if n is Control and not n.is_visible_in_tree():
			continue
		if n is Dialog or n is NameDialog or n is XDialog or n is BuilderSheet or n is OptionsBox or n is CardSheet or n is BehaviorSheet:
			top = n
		for k in n.get_children():
			stack.append(k)
	if top is Dialog:
		var i: int = top.safe_index()
		if i >= 0:
			top.chosen.emit(i)
		return
	if top is NameDialog or top is BuilderSheet:
		top.cancelled.emit()
		return
	if top is XDialog:
		top.chosen.emit(0)
		return
	if top is OptionsBox:
		top.closed.emit()
		return
	if top is CardSheet:
		_close_sheet()
		return
	if top is BehaviorSheet:
		_close_behaviors()
		return
	if handoff != null and handoff.visible:
		return
	if hand_tray != null and hand_tray.visible:
		hand_tray.closed.emit()
		return
	if panel != null and panel.visible:
		panel.closed.emit()
		return
	# then the screen shown: its own Back (or Home)
	for s in [saves_screen, studio_screen, poi_screen, chassis_screen, forge_screen, workshop_screen, dock_screen, teams_screen, setup]:
		if s != null and s.visible:
			if s == teams_screen and teams_screen.editor != null and teams_screen.editor.visible:
				teams_screen.editor.back_btn.pressed.emit()
			else:
				s.back_btn.pressed.emit()
			return
	if _board_live():
		ask_leave()
		return
	if _map_live():
		map_screen.home_btn.pressed.emit()
		return
	if home.visible and dialog == null:
		_open_dialog(Dialog.new("Leave KETER?", "Your run is saved as it stands.", ["Stay", "Leave"], Color("#d6a851")), func(i):
			_close_dialog()
			if i == 1:
				get_tree().quit())


func _exit_tree() -> void:
	Rules.hooks = {}              # the rules let go of the battle
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)


## (0.12) Every button, wherever it is, clicks when pressed.
func _on_node_added(n: Node) -> void:
	if n is BaseButton and not n.has_meta("tapped"):
		n.set_meta("tapped", true)
		n.pressed.connect(func(): Sound.play("tap"))


## (0.12) A new screen fades in: Home, the Strike Teams, a fight's setup, the
## dock, the Workshop, the World Map, a fight.
func _process(_delta: float) -> void:
	var k := _screen_key()
	if k != _screen_was:
		_screen_was = k
		if Motion.moving() and curtain != null:
			curtain.color.a = 0.85
			var tw := curtain.create_tween()
			tw.tween_property(curtain, "color:a", 0.0, 0.28 * Motion.k())


## Which screen is up.
func _screen_key() -> String:
	if home == null:
		return ""
	if home.visible:
		return "home"
	if teams_screen != null and teams_screen.visible:
		return "teams"
	if setup != null and setup.visible:
		return "setup"
	if dock_screen != null and dock_screen.visible:
		return "dock"
	if workshop_screen != null and workshop_screen.visible:
		return "workshop"
	if map_screen != null and map_screen.visible:
		return "map"
	# (0.32) and the Sandbox's tools and the save files
	for pair in [[forge_screen, "forge"], [chassis_screen, "chassis"], [poi_screen, "poi"], [studio_screen, "studio"], [saves_screen, "saves"]]:
		if pair[0] != null and pair[0].visible:
			return pair[1]
	return "battle" if battle != null else ""


## (0.12) Options: Speed, Screen shake and Sound.
func open_options() -> void:
	if options != null:
		return
	options = OptionsBox.new()
	options.closed.connect(close_options)
	options.look_board_requested.connect(open_look_board)
	# (0.15) from Home, it says what this is and where the content came from, and can look again
	if home != null and home.visible:
		options.show_about(VERSION, source_text)
		options.look_again_requested.connect(func():
			close_options()
			load_export())
	ui.add_child(options)


## (0.14) The Look board, over everything; Close puts it away.
func open_look_board() -> void:
	close_options()
	if look_board != null:
		return
	look_board = LookBoard.new()
	look_board.closed.connect(func():
		look_board.queue_free()
		look_board = null)
	ui.add_child(look_board)


func close_options() -> void:
	if options == null:
		return
	Motion.pop_out(options, options.box)
	options = null
	_show_speed()


## The speed button wears the speed: one arrow Normal, two Fast, two and a bar Instant.
func _show_speed() -> void:
	if speed_btn != null:
		speed_btn.icon = Art.icon("speed_" + Motion.speed)
		speed_btn.tooltip_text = "Speed: " + Motion.SPEED_NAMES[Motion.speed] + ". Tap for Options."


## (0.12) The screen shakes: a heavy blow, or a Unit brought down.
func _shake(power: float) -> void:
	if not Motion.shake or not Motion.moving() or camera == null:
		return
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	_shake_tween = create_tween()
	var amp := 7.0 * power
	for i in 6:
		_shake_tween.tween_property(camera, "offset", Vector2(randf_range(-amp, amp), randf_range(-amp, amp)) * (1.0 - i / 6.0), 0.03)
	_shake_tween.tween_property(camera, "offset", Vector2.ZERO, 0.03)


# ---------------------------------------------------------------- the export
## Looks for the newest export (or opens the one given), and goes home.
## (0.19) On Android, what Home says until the game may read your Downloads.
const ANDROID_NOTE := "Playing the export built into this app. To play your own, allow KETER \"All files access\" when Android asks (or in Settings, Apps, KETER), put the Companion's KETER_export_\u2026 .zip in Downloads, and tap Look again."


func load_export(p: String = "") -> bool:
	Sandbox.load_saved()            # (0.26) what you have made and changed in the Sandbox, over the export
	data.close()
	floors.clear()
	roster = null
	campaign = null
	var found := p if p != "" else KeterExport.find_newest()
	var ok := false
	home_note = ""
	if OS.has_feature("android") and not KeterExport.android_can_read():
		# (0.19) the Android app: until it may read your Downloads, it plays the export built into it
		home_note = ANDROID_NOTE
	if found == "":
		source_text = "No export"
		home_note = "No export found yet.\n\nIn the Companion, open the Pixel Studio, go to the Assets tab and tap Export for Godot. Put the KETER_export_\u2026 .zip it downloads into this game's folder, next to project.godot. You don't need to unzip it. Then tap Look again."
	elif not data.open(found):
		source_text = "Export unreadable"
		home_note = data.error + "\n\nTap Look again after replacing it."
	else:
		# (0.20) the battlefield chunks are the World Map's to grow battlefields from, not floors to pick
		var every := data.floors()
		floors.assign(every.filter(func(f): return not ChunkGen.is_chunk(f.raw)))
		var comp := str(data.manifest.get("companion", ""))
		source_text = "%s%s" % [export_name(found), (" \u00b7 Companion " + comp) if comp != "" else ""]
		setup.source = "From " + found.get_file() + ((", made by Companion " + comp) if comp != "" else "") + "."
		if floors.is_empty():
			home_note = found.get_file() + " has no floors. Save a floor in the Companion's Sandbox, export again, and tap Look again."
		else:
			roster = Roster.new(data)
			setup.set_content(roster, floors)
			# what you have done on the map so far, read against this export's map
			campaign = Campaign.new(data, roster, every)
			ok = true
	# (0.11: the pictures for the game's look you drew, and the World Map's ground, from this export)
	Art.load_from(data if found != "" and data.manifest is Dictionary and not data.manifest.is_empty() else null)
	if not ok:
		setup.show_message(home_note)
	show_home()
	return ok


## "KETER_export_2026-09-30.zip" reads "Export 2026-09-30".
static func export_name(p: String) -> String:
	if p.get_file() == KeterExport.BUILT_IN:
		return "The built-in export"
	var n := p.get_file().get_basename()
	for pre in ["KETER_export_", "KETER_assets_"]:
		if n.begins_with(pre):
			return "Export " + n.substr(pre.length())
	return p.get_file()


# ---------------------------------------------------------------- a battle
## Hides everything a battle shows.
func _leave_battle() -> void:
	if neon != null:
		neon.queue_free()
		neon = null
	_close_dialog()
	_close_sheet()
	_close_x()
	_close_behaviors()
	loot_label.visible = false
	auto_phase = false
	panel.visible = false
	log_panel.visible = false
	hand_tray.visible = false
	banner.visible = false
	overlay.clear_tags()
	overlay.clear_readout()
	overlay.clear_floats()
	play = {}
	wave_label.visible = false
	aether_btn.visible = false
	hand_btn.visible = false
	cons_btn.visible = false
	chips_btn.visible = false
	piles_btn.visible = false
	floor_label.text = ""
	round_label.text = ""
	info.text = ""


## (0.19) The screen is about to change: a pixel dissolve into or out of a
## fight, a hex wipe between the menus.
func _turn(into_fight := false) -> void:
	if transition != null:
		transition.play(Transition.PIXELS if (into_fight or battle != null) else Transition.HEX)


## The home screen: World Map, Battle, Quick battle, Strike Teams.
## (0.26) The Sandbox: the game's own tools, the Card Forge first.
func open_sandbox() -> void:
	if roster == null:
		return
	_turn()
	_leave_battle()
	_hide_world()
	home.visible = false
	setup.visible = false
	teams_screen.visible = false
	# (0.33) where you were: the tool used last, each list as it was left; and a draft the game closed on
	if not _sandbox_recalled:
		_sandbox_recalled = true
		var u := Sandbox.ui()
		for pair in _sandbox_tools():
			if u.get(pair[0]) is Dictionary:
				pair[1].recall(u[pair[0]])
	var d := Sandbox.draft()
	var k: String = str(d.get("tool", Sandbox.ui().get("tool", "forge")))
	if not ["forge", "chassis", "poi", "studio"].has(k):
		k = "forge"
	open_sandbox_tool(k)
	if not d.is_empty():
		var s = _sandbox_tools().filter(func(p): return p[0] == k)[0][1]
		_open_dialog(Dialog.new("Pick up where you left off?", "You were working on %s when the game closed, and hadn't saved it." % str(d.get("what", "something")), ["Discard it", "Pick it up"], Color("#73efe8")), func(i):
			_close_dialog()
			if i == 1:
				s.restore(d)
			else:
				Sandbox.drop_draft())


## (0.32) The three save files, from Home.
func open_saves() -> void:
	_turn()
	_leave_battle()
	_hide_world()
	home.visible = false
	setup.visible = false
	teams_screen.visible = false
	saves_screen.visible = true
	saves_screen.open()


## (0.32) Another save file is played: its run is read, and its Strike Teams
## are the ones the screens show from now on.
func reload_run() -> void:
	if data.is_open() and not floors.is_empty() and roster != null:
		campaign = Campaign.new(data, roster, data.floors())
	home.show_save(SaveSlots.name_of(SaveSlots.current))


## (0.28) One of the Sandbox's tools: the Card Forge, the Chassis builder, (0.29) the POI Sandbox.
func open_sandbox_tool(k: String) -> void:
	Sandbox.ui()["tool"] = k
	forge_screen.visible = not ["chassis", "poi", "studio"].has(k)
	chassis_screen.visible = k == "chassis"
	poi_screen.visible = k == "poi"
	studio_screen.visible = k == "studio"
	if k == "chassis":
		chassis_screen.open(roster)
	elif k == "poi":
		poi_screen.open(roster)
	elif k == "studio":
		studio_screen.open(roster)
	else:
		forge_screen.open(roster)


## (0.26) The Sandbox's cards have changed: the game reads its cards again from the
## export it has open, with them laid over it, and the campaign with them.
func reload_cards() -> void:
	if not data.is_open() or floors.is_empty():
		return
	roster = Roster.new(data)
	# (0.29) and its floors, the Sandbox's laid over them
	var every := data.floors()
	var fights := every.filter(func(f): return not ChunkGen.is_chunk(f.raw))
	if not fights.is_empty():
		floors.assign(fights)
	setup.set_content(roster, floors)
	campaign = Campaign.new(data, roster, every)
	if forge_screen != null:
		forge_screen.roster = roster
	if chassis_screen != null:
		chassis_screen.roster = roster
	if poi_screen != null:
		poi_screen.roster = roster
	if studio_screen != null:
		studio_screen.roster = roster


func show_home() -> void:
	if forge_screen != null and _sandbox_tools().any(func(p): return p[1].visible):
		_remember_sandbox()
	_turn()
	_leave_battle()
	_hide_world()
	battle = null
	setup.visible = false
	teams_screen.visible = false
	forge_screen.visible = false
	chassis_screen.visible = false
	poi_screen.visible = false
	studio_screen.visible = false
	saves_screen.visible = false
	home.visible = true
	home.show_save(SaveSlots.name_of(SaveSlots.current))
	# what loading had to say (a new map, a file that couldn't be read) comes before where things stand
	var world_line := ""
	if campaign != null:
		world_line = campaign.note if campaign.note != "" else campaign.status_line()
	home.show_state(roster != null, home_note, source_text, StrikeTeams.load_all().size() if roster != null else 0, world_line, campaign != null and campaign.deploy.active())


## Setting up a fight: "team" for a Strike Team's Battle, "quick" for the free pick.
func open_setup(mode: String) -> void:
	if roster == null:
		return
	_turn()
	_leave_battle()
	_hide_world()
	battle = null
	home.visible = false
	teams_screen.visible = false
	setup.visible = true
	setup.begin(mode, StrikeTeams.load_all() if mode == "team" or mode == "pvp" else [])


func open_teams() -> void:
	if roster == null:
		return
	_turn()
	_leave_battle()
	_hide_world()
	home.visible = false
	setup.visible = false
	teams_screen.visible = true
	# a Strike Team that is out can't be changed until it is home
	teams_screen.locked = func(t): return campaign != null and campaign.deploy.locked_team(t)
	teams_screen.owns = func(n): return campaign == null or campaign.dock.owns(n)
	teams_screen.open(roster)


func _show_setup() -> void:
	open_setup(setup.mode)


# ---------------------------------------------------------------- the World Map
## Puts the map and the dock away.
func _hide_world() -> void:
	map_screen.close()
	map_screen.visible = false
	dock_screen.visible = false
	workshop_screen.visible = false
	map_view.visible = false
	board.visible = true


## World Map, from the home screen: the team that is out, or the dock.
func open_world() -> void:
	if campaign == null:
		return
	if campaign.deploy.active():
		show_map()
	else:
		open_dock()


func open_dock() -> void:
	if campaign == null:
		return
	_turn()
	_leave_battle()
	_hide_world()
	battle = null
	home.visible = false
	setup.visible = false
	teams_screen.visible = false
	dock_screen.visible = true
	dock_screen.open(campaign, roster)


## The Workshop, from the dock.
func open_workshop() -> void:
	if campaign == null:
		return
	_turn()
	dock_screen.visible = false
	workshop_screen.visible = true
	workshop_screen.open(campaign, roster)


## The map, with the Strike Team where it stands (or nobody out, to look around).
func show_map() -> void:
	if campaign == null:
		return
	_turn()
	_leave_battle()
	battle = null
	home.visible = false
	setup.visible = false
	teams_screen.visible = false
	dock_screen.visible = false
	board.visible = false
	map_view.visible = true
	map_view.show_world(campaign.world, data)
	map_screen.visible = true
	map_screen.open(campaign, roster, map_view)
	centre_map(map_screen._pos(), true)


## Brings a tile of the map to the middle of what the panel leaves free. At
## once, or only if it has drifted near an edge.
func centre_map(k: String, at_once := false) -> void:
	var p := map_view.to_global(map_view.centre_of(k))
	var vp := get_viewport_rect().size
	var free := Rect2(0, MapScreen.BAR_H, vp.x - MapScreen.PANEL_W - 20, vp.y - MapScreen.BAR_H)
	if at_once:
		_stop_camera()
		camera.zoom = Vector2.ONE
		camera.position = p + (vp / 2.0 - free.get_center())
		return
	var at := get_viewport().get_canvas_transform() * p
	if free.grow(-90).has_point(at):
		return
	_stop_camera()
	_cam_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_cam_tween.tween_property(camera, "position", p + (vp / 2.0 - free.get_center()) / camera.zoom.x, 0.25)


## The whole map on the screen.
func fit_map() -> void:
	_stop_camera()
	var r := map_view.bounds()
	var vp := get_viewport_rect().size
	var room := Vector2(vp.x - MapScreen.PANEL_W - 20, vp.y - MapScreen.BAR_H)
	var z := clampf(minf(room.x / r.size.x, room.y / r.size.y) * 0.98, ZOOM_MIN, ZOOM_MAX)
	camera.zoom = Vector2(z, z)
	camera.position = r.get_center() + Vector2((MapScreen.PANEL_W + 20) / 2.0, -MapScreen.BAR_H / 2.0) / z


## The fight that is waiting on the map: who enters, then the Battle.
func start_deploy_fight() -> void:
	if campaign == null:
		return
	var sp = campaign.deploy.spec()
	var team = campaign.deploy.team_now()
	if sp == null or team == null:
		return
	var f: FloorData = null
	for x in floors:
		if x.key == str(sp["floor"]):
			f = FloorData.from_dict(x.raw)
	# (0.20) a battlefield grown from chunks, grown again from its key
	if f == null and ChunkGen.is_gen_key(sp["floor"]):
		var lv := campaign.world.level(sp["floor"])
		if not lv.is_empty():
			f = FloorData.from_dict(lv)
	if f == null:
		map_screen.note = "The floor this fight needs (%s) is not in this export." % str(sp["floor"])
		map_screen.note_bad = true
		map_screen.refresh()
		return
	# the fight takes the tile's District: its Enemies, and what they can leave
	f.district = str(sp["district"])
	map_screen.close()
	map_screen.visible = false
	setup.visible = true
	setup.begin_deploy(sp, f, team)


func _on_deploy_start(_team: Dictionary, team_setup: Dictionary, seed = null) -> void:
	var sp = campaign.deploy.spec() if campaign != null else null
	if sp == null:
		show_map()
		return
	team_setup["deploy"] = {"district": sp["district"], "skull": sp["skull"], "kind": sp["kind"], "pending": sp["pending"], "bounties": campaign.dock.wanted()}
	last_setup = ["deploy"]
	map_view.visible = false
	board.visible = true
	show_battle(Battle.begin_team(setup.deploy_floor, roster, team_setup, seed))


func _on_start(fi: int, hero_cards: Array, troop_cards: Array) -> void:
	start_battle(fi, hero_cards, troop_cards)


func _on_team_start(fi: int, team: Dictionary, team_setup: Dictionary) -> void:
	start_team_battle(fi, team, team_setup)


## Starts a Strike Team's Battle on a floor. A seed deals the same Deck,
## Chips and Enemies, and rolls the same dice, each time.
func start_team_battle(fi: int, team: Dictionary, team_setup: Dictionary, seed = null) -> void:
	last_setup = ["team", fi, team, team_setup]
	show_battle(Battle.begin_team(floors[fi], roster, team_setup, seed))


## Starts a battle on a floor with these cards. A seed deals the same Enemies
## and rolls the same dice each time.
## (0.26) Pass and play: a match between two Strike Teams on a floor. Player 1
## takes the phone first.
func start_pvp(fi: int, t1: Dictionary, s1: Dictionary, t2: Dictionary, s2: Dictionary, seed = null) -> void:
	last_setup = ["pvp", fi, t1, s1, t2, s2]
	show_battle(Battle.begin_pvp(floors[fi], roster, s1, s2, seed, ["Player 1", "Player 2"]))
	handoff.show_for(battle.pvp_names[1], 1, true)


## (0.26) Back to a match's setup from Strike Teams, where it was.
func _back_to_setup() -> void:
	_teams_for_setup = false
	teams_screen.visible = false
	home.visible = false
	setup.visible = true
	setup.resume(StrikeTeams.load_all())


func start_battle(fi: int, hero_cards: Array, troop_cards: Array, seed = null) -> void:
	last_setup = ["quick", fi, hero_cards, troop_cards]
	show_battle(Battle.begin(floors[fi], roster, hero_cards, troop_cards, seed))


## Puts a battle on the board, ready to play.
func show_battle(fight: Battle) -> void:
	_turn(true)
	_close_dialog()
	battle = fight
	deploy_out = {}
	map_screen.visible = false
	dock_screen.visible = false
	map_view.visible = false
	board.visible = true
	selected_id = ""
	aiming = -1
	targets = {}
	aim_pool = []
	preview = ""
	tile_aim = {}
	tile_at = null
	burst = {}
	walking = false
	busy = false
	enemy_phase = false
	auto_phase = false
	upkeep = false
	play = {}
	_close_sheet()
	_close_x()
	_close_behaviors()
	_apply_behaviors()
	home.visible = false
	teams_screen.visible = false
	setup.visible = false
	panel.visible = false
	log_panel.visible = false
	hand_tray.visible = false
	banner.visible = false
	overlay.clear_tags()
	overlay.clear_readout()
	overlay.clear_floats()
	board.show_floor(battle.floor_data)
	var loot_at := {}
	for h in battle.floor_data.tiles:
		if battle.kind_at(h) == "loot":
			loot_at[h] = true
	board.set_loot_tiles(loot_at)
	board.show_units(battle)
	floor_label.text = battle.floor_data.name
	_update_bar()
	var foes := battle.side_units("enemy").size()
	if battle.with_cards:
		# how it opened: the first wave, the Aether, the Chips and the six cards
		_say(_tell(battle.log, 5) + "  Tap one of your Units to move it or use its Actions; Hand holds the cards you can play. " + instability_words() + " ".join(battle.notes))
	else:
		_say("%d of your Units and %d Enem%s. Tap one of yours to move it or use its Actions. %s" % [battle.side_units("ally").size(), foes, "y" if foes == 1 else "ies", " ".join(battle.notes)])
	_layout_info()
	_start_view()
	_show_halts()


## "Dimensional Instability 9%: a spawn may bring an Elite or a Mini-Boss. ", or "".
func instability_words() -> String:
	if battle == null or battle.instability <= 0:
		return ""
	return "Dimensional Instability %d%%: any spawn may bring an Elite or a Mini-Boss instead. " % battle.instability


## Your Units arrive with the Behavior keywords you chose for their cards.
func _apply_behaviors() -> void:
	if battle == null:
		return
	for u in battle.units:
		Behaviors.apply(u)


## What has dropped and been found so far, in a few words: "Loot: 12 shards · 3 parts".
func loot_words() -> String:
	if battle == null or Loot.is_empty(battle.loot):
		return ""
	var b := Loot.norm(battle.loot)
	var n := Loot.count(b)
	var bits := []
	if b["shards"] > 0:
		bits.append("%d shard%s" % [b["shards"], "" if b["shards"] == 1 else "s"])
	if n > 0:
		bits.append("%d part%s" % [n, "" if n == 1 else "s"])
	return "Loot: " + " \u00b7 ".join(bits)


func _update_bar() -> void:
	if battle == null:
		return
	round_label.text = ("Round %d \u00b7 %s" % [battle.round, battle.pvp_names[battle.pvp]]) if battle.pvp > 0 else "Round %d" % battle.round
	auto_btn.tooltip_text = "Auto: on" if auto else "Auto: off"
	auto_btn.set_pressed_no_signal(auto)
	auto_btn.disabled = busy or walking or battle.over
	loot_label.text = loot_words()
	loot_label.visible = loot_label.text != ""
	board.set_searched(battle.looted)
	board.sync_floor(battle.floor_data, battle.floor_rev)   # Revision 16.3: a Barricade put down, or taken back
	undo_btn.visible = not battle.undo.is_empty() and not busy and not battle.over and play.is_empty()
	next_btn.disabled = busy or battle.over or walking or not burst.is_empty() or not play.is_empty()
	undo_btn.disabled = busy or walking
	# waves, Aether, the hand, Consumables and Chips: a Strike Team's fight has them
	wave_label.visible = battle.waves_total > 1
	aether_btn.visible = battle.with_cards
	if battle.waves_total > 1:
		wave_label.text = wave_text()
	if battle.with_cards:
		aether_btn.tooltip_text = "Aether " + UI.show(Battle.aether_label(battle.aether))
		aether_gems.show_pool(battle.aether)
		aether_btn.custom_minimum_size.x = 50.0 + aether_gems.width()
		hand_btn.text = "Hand %d" % battle.hand.size()
		cons_btn.text = "Consumables %d" % battle.consumables.filter(func(c): return not Rules.truthy(c.get("used"))).size()
		chips_btn.text = "Chips %d" % range(battle.bank.size()).filter(func(i): return battle.chip_text(battle.bank[i]) != "" and not Rules.truthy(battle.bank[i].get("spent"))).size()
		piles_btn.text = "Deck %d  \u00b7  Discard %d" % [battle.deck.size(), battle.discard.size()]
		if hand_tray.visible:
			_fill_tray(hand_tray.kind)
	_layout_info()


## Whether the Strike Team has anything a button would open.
func _has_consumables() -> bool:
	return battle != null and battle.with_cards and not battle.consumables.is_empty()


func _has_effect_chips() -> bool:
	return battle != null and battle.with_cards and battle.bank.any(func(c): return battle.chip_text(c) != "")


## "Wave 2 of 6 · next in 2", "Wave 6 of 6 · the last", "Wave 3 of 6 · clear".
func wave_text() -> String:
	var t := "Wave %d of %d" % [battle.wave, battle.waves_total]
	if battle.nothing_more_coming():
		return t + " \u00b7 the last"
	if battle.enemies_left() == 0:
		return t + " \u00b7 clear"
	return t + " \u00b7 next in %d" % battle.next_wave_in()


func play_again() -> void:
	if last_setup.is_empty():
		return
	if last_setup[0] == "team":
		start_team_battle(last_setup[1], last_setup[2], last_setup[3])
	elif last_setup[0] == "pvp":
		start_pvp(last_setup[1], last_setup[2], last_setup[3], last_setup[4], last_setup[5])
	else:
		start_battle(last_setup[1], last_setup[2], last_setup[3])


## Leaves the fight and sets up another of the same kind.
func new_battle() -> void:
	if walking or busy:
		return
	play = {}
	burst = {}
	deselect()
	open_setup("pvp" if (battle != null and battle.pvp > 0) else ("team" if (battle != null and battle.with_cards) else "quick"))


## Leaves the fight for the home screen.
func leave() -> void:
	if walking or busy:
		return
	play = {}
	burst = {}
	deselect()
	show_home()


# ---------------------------------------------------------------- choosing
func selected() -> Variant:
	return battle.unit_by_id(selected_id) if battle != null and selected_id != "" else null


## Yours, standing, and the battle still on: its Actions are buttons.
func _mine(u: Dictionary) -> bool:
	return u["side"] == "ally" and not Rules.truthy(u.get("down")) and not battle.over


func _panel_info(u: Dictionary) -> Dictionary:
	var states := {}
	var acts: Array = u.get("actions", [])
	for i in acts.size():
		states[i] = battle.action_state(u, acts[i])
	var live := _mine(u) and not busy
	var holds := []
	if live and burst.is_empty() and u.get("holding") == null:
		holds = battle.holdable(u).map(func(a): return a["name"])
	var hint := ""
	if not burst.is_empty():
		hint = "Burst: %d more to make. Tap a lit target for the next." % burst["left"]
	elif preview != "":
		hint = "Tap the target again to fire, or another to move the blast."
	elif aiming >= 0 and aiming < acts.size() and Effects.has_area(acts[aiming]):
		hint = "Aiming: tap a lit target to see what its area takes in, then again to fire."
	# (0.16) what it can still do this turn, for the strip under its name
	var turn := {}
	if live:
		var hold := ""
		if u.get("holding") != null:
			hold = "holding"
		elif Battle.usable_actions(u).any(func(a): return Effects.suppressive(a)):
			hold = "can" if not holds.is_empty() else "spent"
		var attack := false
		for i in acts.size():
			if acts[i].get("tag") != "Passive" and acts[i].get("tag") != "Aura" and states[i].get("ok", false):
				attack = true
		turn = {"move": battle.can_move(u), "moved": battle.has_moved(u), "speed": battle.speed(u), "attack": attack, "hold": hold}
	return {"moved": battle.has_moved(u), "speed": battle.speed(u), "interactive": live, "states": states, "picked": aiming, "holds": holds, "hint": hint,
		"leader": battle.with_cards and u["id"] == battle.leader_id, "auto": auto, "acted": battle.has_acted(u), "turn": turn}


func _show_panel(u: Dictionary) -> void:
	Behaviors.apply(u)
	panel.show_unit(u, battle.looks.get(u["id"], {}), _panel_info(u))
	_layout_info()


func select(u: Dictionary) -> void:
	selected_id = u["id"]
	aiming = -1
	targets = {}
	aim_pool = []
	preview = ""
	tile_aim = {}
	tile_at = null
	overlay.clear_tags()
	log_panel.visible = false
	_show_panel(u)
	board.clear_marks()
	board.refresh_units(battle, selected_id)
	_keep_in_view(u)
	var nm := str(u["name"])
	if u["side"] != "ally":
		_say("%s acts on its own when you end your turn." % nm)
		return
	var can_act := Battle.usable_actions(u).any(func(a): return battle.action_state(u, a)["ok"])
	var act_hint := " or an Action to attack" if can_act else ""
	if battle.has_moved(u) and not battle.can_move(u):
		_say(("%s has moved this round. Tap an Action to attack." % nm) if can_act else ("%s has moved and has nothing it can use now. It can go again next round." % nm))
	elif battle.speed(u) <= 0:
		_say(("%s can't move. Tap an Action to attack." % nm) if can_act else ("%s can't move or act now." % nm))
	else:
		var r := battle.reach(u)
		board.set_reach(r, u["side"])
		if r.is_empty():
			_say("%s has nowhere to go%s." % [nm, (", but can use an Action" if can_act else "")])
		else:
			var bites := r.filter(func(t): return battle.floor_data.hazards.has(Vector2i(t["q"], t["r"])))
			var warn := ""
			if not bites.is_empty():
				warn = "  Amber tiles are hazards (%s)." % battle.hazard_words(Vector2i(bites[0]["q"], bites[0]["r"]))
			_say("%s: tap a lit tile to move there (up to %d tile%s)%s, or tap anywhere else to cancel.%s%s" % [nm, battle.speed(u), "" if battle.speed(u) == 1 else "s", act_hint, warn, _hold_hint(u)])


## An Action it could hold fire with, for the bottom line.
func _hold_hint(u: Dictionary) -> String:
	if u.get("holding") != null:
		return ""
	var can := battle.holdable(u)
	return ("  It can hold fire with %s: the gold button in its panel." % can[0]["name"]) if not can.is_empty() else ""


func deselect() -> void:
	if walking or busy:
		return
	if not burst.is_empty():
		_say(_burst_hint())
		return
	selected_id = ""
	aiming = -1
	targets = {}
	aim_pool = []
	preview = ""
	tile_aim = {}
	tile_at = null
	overlay.clear_tags()
	panel.visible = false
	board.clear_marks()
	_layout_info()
	if battle != null:
		board.refresh_units(battle)
		if not battle.over:
			_say("Tap one of your Units to move it or use its Actions.")


## An Action button in the panel: aim it, or put it away if it's aimed already.
func pick_action(i: int) -> void:
	var u = selected()
	if u == null or busy or walking or not _mine(u):
		return
	if not burst.is_empty():
		_say(_burst_hint())
		return
	if aiming == i:
		select(u)
		return
	var a: Dictionary = u["actions"][i]
	if not battle.action_state(u, a)["ok"]:
		return
	# a carried Action card with a variable cost asks for its X each time
	if a.get("aetherX") is Dictionary:
		var x := await ask_action_x(u, a)
		if x <= 0 or battle == null or selected() == null or not is_same(selected(), u) or not battle.action_state(u, a)["ok"]:
			return
		Battle.set_action_x(a, x)
	# (0.22, Revision 16.2) one used on its own Unit needs no target: at once
	if Battle.self_only(a):
		var mark := _mark()
		battle.use_on_self(u, a)
		board.refresh_units(battle, selected_id)
		_float_all(battle.floats.slice(mark[0]), u["id"])
		var said := _tell(battle.log.slice(mark[1]))
		_show_panel(u)
		_update_bar()
		_say(said)
		await _show_halts()
		if battle.settle():
			show_result()
		return
	# (0.23) one aimed at a tile: the tiles it can go to are lit
	if Battle.tile_action(a):
		aiming = i
		preview = ""
		aim_pool = []
		targets = {}
		board.clear_marks()
		overlay.clear_tags()
		tile_aim = battle.tile_reach(u, a)
		tile_at = null
		board.set_aim_tiles(tile_aim)
		_show_panel(u)
		_say("%s: tap a lit tile to see what it would do there; tap it again to use it. Tap %s again to put it away." % [a["name"], a["name"]])
		return
	_aim(u, i, battle.targets_for(u, a))
	var who := "ally" if Battle.role_of(a) == "support" else "Enemy"
	if Effects.has_area(a):
		_say("%s: tap a lit %s to see what its area would take in; a second tap fires. Tap %s again to put it away." % [a["name"], who, a["name"]])
	elif Battle.role_of(a) == "support":
		_say("%s: tap a lit ally to use it on them, or tap %s again to put it away." % [a["name"], a["name"]])
	else:
		_say("%s: tap a lit %s to use it on them (the tags say the chance it gets through, and the damage), or tap %s again to put it away." % [a["name"], who, a["name"]])


## Which X to use a carried Action card for: from 1 to the most the Bank
## could pay. Returns 0 if it's put away.
func ask_action_x(u: Dictionary, a: Dictionary) -> int:
	var most := battle.action_max_x(a)
	if most < 1:
		return 0
	var probe: Dictionary = a.duplicate(true)
	var d := XDialog.new("%s: choose X" % a["name"], most, func(x):
		Battle.set_action_x(probe, x)
		var cost = Battle.action_aether(probe)
		return "Costs %s Aether, and %d Energy. The Bank holds %s.\n%s" % [UI.show(Battle.aether_words(cost)), int(Rules.num(a.get("cost"), 0)),
			UI.show(Battle.aether_label(battle.aether)), UI.show(UnitPanel.card_text(probe.get("text", "")))], "Aim it")
	_close_x()
	xdlg = d
	ui.add_child(d)
	var x: int = await d.chosen
	_close_x()
	return x


func _close_x() -> void:
	if xdlg != null:
		Motion.pop_out(xdlg, xdlg.get_meta("box", null))
		xdlg = null


## The Behavior row in a Unit's panel: choose how it fights on Auto. What is
## chosen is remembered for its card.
func open_behaviors() -> void:
	var u = selected()
	if u == null or busy or walking or not _mine(u) or beh_sheet != null or not burst.is_empty() or not play.is_empty():
		return
	var sh := BehaviorSheet.new(str(u.get("src") if Rules.truthy(u.get("src")) else u["name"]), u["behaviors"] if u.get("behaviors") is Array else [])
	beh_sheet = sh
	sh.done.connect(func(list): set_behaviors(u, list))
	ui.add_child(sh)


## Gives a Unit these Behavior keywords, and every other Unit of its card on
## your side with it; the game remembers them for that card.
func set_behaviors(u: Dictionary, list: Array) -> void:
	_close_behaviors()
	if battle == null:
		return
	var card := str(u.get("src") if Rules.truthy(u.get("src")) else u["name"])
	var kept := Behaviors.remember(card, list)
	for o in battle.units:
		if o["side"] == "ally" and str(o.get("src") if Rules.truthy(o.get("src")) else o["name"]) == card:
			o["behaviors"] = Behaviors.clean(list)
			o["behSeen"] = true
	if selected() != null:
		_show_panel(selected())
	var w := Behaviors.words(list)
	_say("On Auto, %s %s%s" % [card, ("fights by: " + w + ".") if w != "" else "attacks the closest Enemy.", "" if kept else "  (That couldn't be saved, so it holds for this battle only.)"])


func _close_behaviors() -> void:
	if beh_sheet != null:
		Motion.pop_out(beh_sheet, beh_sheet.get_meta("box", null))
		beh_sheet = null


## The Auto switch in the top bar.
func toggle_auto() -> void:
	if battle == null or busy or walking or battle.over:
		return
	auto = not auto
	_update_bar()
	if selected() != null:
		_show_panel(selected())
	if auto:
		_say("Auto is on. Play your cards and move anyone you like; when you tap End turn, every Unit of yours you haven't used this turn takes its turn by itself, by its Behavior keywords (set in its panel). Then the Enemies go. It stays on until you switch it off.")
	else:
		_say("Auto is off. Your Units wait for you.")


## Lights the Units an Action could go to, each with its odds.
func _aim(u: Dictionary, i: int, pool: Array) -> void:
	var a: Dictionary = u["actions"][i]
	aiming = i
	preview = ""
	aim_pool = pool.map(func(t): return t["id"])
	board.clear_marks()
	targets = {}
	for t in pool:
		targets[t["id"]] = battle.odds(u, a, t)
	var tags := _odds_tags(a)
	overlay.set_tags(tags, _unit_points())
	board.mark_units(battle, selected_id, targets)
	var pts := [Board.at(Battle.tile_of(u))]
	for t in tags:
		pts.append(t["at"])
	_frame(pts)
	_show_panel(u)


## A tag over each Unit being aimed at: the chance it gets through, and the damage.
func _odds_tags(a: Dictionary) -> Array:
	var tags := []
	for id in aim_pool:
		var t = battle.unit_by_id(id)
		if t == null or not targets.has(id):
			continue
		var o: Dictionary = targets[id]
		var text := ("%d%%" % roundi(o["p"] * 100.0)) + ((" · %d" % o["dmg"]) if o["dmg"] > 0 else "")
		if Battle.role_of(a) == "support":
			text = _support_tag(a)
		tags.append({"at": Board.at(Battle.tile_of(t)), "text": text, "colour": Overlay.odds_colour(o["p"])})
	return tags


## Where every Unit stands, for the tags to keep clear of.
func _unit_points() -> Array:
	return battle.units.filter(func(u): return not Rules.truthy(u.get("down")) and u.get("pos") is Dictionary).map(func(u): return Board.at(Battle.tile_of(u)))


## What a Support Action's tag says: the Health its text gives, if it heals.
static func _support_tag(a: Dictionary) -> String:
	for p in Keywords.parse(a.get("text") if a.get("text") != null else ""):
		if p["type"] == "kw" and p["kw"] != null and p["kw"]["name"] == "heal" and Rules.truthy(Rules.num(p["n"], 0)):
			return "+%d HP" % int(Rules.num(p["n"], 0))
	return "Support"


func _burst_hint() -> String:
	return "The Burst isn't over: tap a lit target for the next attack (%d more to make)." % burst.get("left", 0)


## The first tap on a target with an area Action: the blast is lit, and
## everyone it would take in is marked, your own Units plainly.
func show_preview(u: Dictionary, a: Dictionary, t: Dictionary) -> void:
	preview = t["id"]
	var pv: Dictionary = battle.fx.area_preview(u, a, t)
	board.set_blast(Battle.tile_of(t), pv["radius"])
	board.add_blast(pv.get("tiles", []))   # Revision 16.3: a Line or a Cone
	var caught := {}
	var tags := _odds_tags(a)
	# everyone caught is ringed; one of your own that it would hurt is flagged as well
	for c in pv["caught"]:
		caught[c["id"]] = true
		if c["side"] == u["side"] and Battle.role_of(a) != "support":
			tags.append({"at": Board.at(Battle.tile_of(c)), "below": true, "text": "Itself!" if is_same(c, u) else "Yours!", "colour": OWN})
	overlay.set_tags(tags, _unit_points())
	board.mark_units(battle, selected_id, targets, "", caught)
	var pts := [Board.at(Battle.tile_of(u))]
	for tg in tags:
		pts.append(tg["at"])
	_frame(pts)
	_show_panel(u)
	var others: Array = pv["caught"].filter(func(c): return c["side"] != u["side"]).map(func(c): return c["name"])
	var mine: Array = pv["own"].map(func(c): return "itself" if is_same(c, u) else c["name"])
	var said: String = "%s on %s: " % [a["name"], t["name"]]
	if others.is_empty() and mine.is_empty():
		said += "its area would take in nobody else."
	else:
		said += "its area would also take in " + (_list(others) if not others.is_empty() else "")
		if not mine.is_empty():
			said += (" — and " if not others.is_empty() else "") + ("your own " if mine != ["itself"] else "") + _list(mine)
		said += "."
	_say(said + "  Tap %s again to fire, or another lit target to move it." % t["name"])


# ---------------------------------------------------------------- taps on the board
func _on_off_board() -> void:
	if enemy_phase or auto_phase:
		fast = true
		return
	if walking or busy:
		return
	if not play.is_empty():
		_play_cancel()
		return
	if aiming >= 0 and selected() != null:
		_step_back()
		return
	deselect()


## A tap that isn't on a target while aiming: a preview is put away (still
## aiming); a Burst waits; otherwise the Action is put away.
func _step_back() -> void:
	var sel = selected()
	if preview != "":
		_aim(sel, aiming, aim_pool.map(func(id): return battle.unit_by_id(id)).filter(func(t): return t != null))
		_say("%s: tap a lit target." % sel["actions"][aiming]["name"] if burst.is_empty() else _burst_hint())
	elif not burst.is_empty():
		_say(_burst_hint())
	else:
		select(sel)


func _on_tile_tapped(h: Vector2i) -> void:
	if battle == null:
		return
	if enemy_phase or auto_phase:
		fast = true
		return
	if not play.is_empty():
		if not busy and not walking:
			await _play_tap(h)
		return
	if walking or busy or battle.over:
		if battle.over and not busy:
			var o = battle.unit_at(h)
			if o != null:
				select(o)
		return
	var sel = selected()
	var there = battle.unit_at(h)
	if aiming >= 0 and sel != null and not tile_aim.is_empty():
		# (0.23) an Action aimed at a tile: a first tap shows where, a second uses it
		if tile_aim.has(h):
			if tile_at == h:
				await use_on_tile(sel, sel["actions"][aiming], h)
			else:
				_tile_preview(sel, sel["actions"][aiming], h)
			return
		select(sel)
		return
	if aiming >= 0 and sel != null:
		if there != null and targets.has(there["id"]):
			var a: Dictionary = sel["actions"][aiming]
			if Effects.has_area(a) and preview != there["id"]:
				show_preview(sel, a, there)
				return
			await attack_with(sel, a, there, (int(burst["left"]) - 1) if not burst.is_empty() else -1)
			return
		if preview != "" or not burst.is_empty():
			_step_back()
		elif there != null and not is_same(there, sel):
			select(there)
		else:
			select(sel)
		return
	if sel != null and sel["side"] == "ally" and there == null and board.reach.has(h):
		await move_selected(h)
	elif there != null:
		select(there)
	else:
		deselect()
		if battle.floor_data.hazards.has(h):
			_say(hazard_sentence(h))
		elif loot_sentence(h) != "":
			_say(loot_sentence(h))


## What a Loot Tile or a Locked Chest holds, for the bottom line; "" for any other tile.
func loot_sentence(h: Vector2i) -> String:
	var chest := battle.chest_at(h)
	if chest < 0 and battle.kind_at(h) != "loot":
		return ""
	var what := "A Locked Chest" if chest >= 0 else "A Loot Tile"
	if battle.looted.has(h):
		return "%s, already emptied." % what
	return "%s: the first of your Units to end a move here finds what it holds." % what


## What a hazard tile does, for the bottom line.
func hazard_sentence(h: Vector2i) -> String:
	var hz: Dictionary = battle.floor_data.hazards[h]
	if str(hz.get("desc", "")) != "":
		return "Hazard: %s." % str(hz["desc"]).trim_suffix(".")
	return "Hazard: %s to any Unit that moves onto it, is pushed onto it, or ends the round on it." % battle.hazard_words(h)


## Walks the chosen Unit to a lit tile, tile by tile. The tile it ends on may
## bite, and its move may set a Passive off.
func move_selected(h: Vector2i) -> void:
	var u = selected()
	if u == null:
		return
	var from := Battle.tile_of(u)
	var mark := _mark()
	var path := battle.move(u, h)
	if path.is_empty():
		return
	walking = true
	_update_bar()
	board.reach.clear()
	board.set_path(from, path)
	var v := board.view_of(u["id"])
	v.walk(path)
	await v.walked
	walking = false
	board.clear_marks()
	board.refresh_units(battle, selected_id)
	var said := _tell(_news(mark))
	await _show_halts()
	if battle.settle():
		_update_bar()
		await _wait(0.5)
		show_result()
		return
	if Rules.truthy(u.get("down")):
		deselect()
		_say(said)
	else:
		select(u)
		_say(said + "  " + _what_next())
	_update_bar()
	if battle.can_escape(u):
		ask_escape(u)


## A Hero stands on an Emergency Exit, inside a POI: leave, or fight on.
func ask_escape(u: Dictionary) -> void:
	_open_dialog(Dialog.new("Emergency Exit", "%s has reached the Emergency Exit. Leave now and the Strike Team gets out of the POI with what it has found here; the POI's final reward is given up, and the POI is cleared." % u["name"],
		["Leave the POI", "Fight on"], Color("#d6a851")), func(i):
		_close_dialog()
		if i == 0 and battle != null and battle.escape(u):
			board.refresh_units(battle)
			_update_bar()
			show_result())


## Takes back the last move or card, with anything it set off.
func undo_move() -> void:
	if battle == null or busy or walking or not burst.is_empty() or not play.is_empty():
		return
	var what := battle.undo_last()
	if what.is_empty():
		return
	overlay.clear_floats()
	overlay.clear_readout()
	board.refresh_units(battle)
	if what["kind"] == "move" and what.get("unit") != null:
		select(what["unit"])
		_say("%s's move is taken back." % what["unit"]["name"])
	else:
		selected_id = ""
		deselect()
		_say("%s is taken back, with everything it did." % what["label"])
	_update_bar()


func _what_next() -> String:
	if battle.enemies_left() == 0 and not battle.nothing_more_coming():
		return "The board is clear: the next wave arrives when you end your turn."
	var left := battle.units.filter(func(x): return x["side"] == "ally" and not Rules.truthy(x.get("down")) and (battle.can_move(x) or Battle.usable_actions(x).any(func(a): return battle.action_state(x, a)["ok"]))).size()
	return ("%d of your Units can still move or act." % left) if left > 0 else "Every Unit has done what it can: tap End turn."


# ---------------------------------------------------------------- what happened
## Where the battle's record stands, so what the next thing adds can be told.
func _mark() -> Array:
	return [battle.floats.size(), battle.log.size()]


## Plays what has happened since a mark (the numbers and words that rise off
## Units) and returns the log lines it added. after: the id of a Unit that has
## a number rising off it already, so its others wait their turn.
func _news(mark: Array, after := "") -> Array:
	_float_all(battle.floats.slice(mark[0]), after)
	return battle.log.slice(mark[1])


## Numbers and words rise off Units: damage and what harms in red, healing and
## what helps in green. Several off one Unit go one after another.
func _float_all(list: Array, after := "") -> void:
	var queued := {}
	if after != "":
		queued[after] = 1
	for f in list:
		var v := board.view_of(str(f["unit"]))
		if v == null:
			continue
		var n: int = queued.get(f["unit"], 0)
		queued[f["unit"]] = n + 1
		overlay.float_text(v.position, str(f["text"]), LOOT if f["kind"] == "loot" else (MEND if (f["kind"] == "heal" or f["kind"] == "buff") else HURT), n * 0.5)


## Log lines as the bottom line tells them: the first few, in a row. Text a
## card carries that isn't keywords is left to the Log, and so is the round's number.
static func _tell(entries: Array, most := 3) -> String:
	var lines := []
	for e in entries:
		if e.get("plain", false) or e.get("halt", false) or e["kind"] == "note":
			continue
		lines.append(str(e["text"]).strip_edges().trim_suffix("."))
	if lines.is_empty():
		return ""
	var out := ". ".join(lines.slice(0, most)) + "."
	if lines.size() > most:
		out += " (%d more in the Log.)" % (lines.size() - most)
	return out


## A card couldn't do what it says: the fight stops on a box that names the
## card and what couldn't happen, and goes on when it's put away. The line is
## in the Log.
func _show_halts() -> void:
	while battle != null and not battle.halts.is_empty():
		var all: Array = battle.halts.duplicate()
		battle.halts.clear()
		var d := Dialog.new("A card couldn't do what it says", "\n\n".join(all) + "\n\nThe fight goes on without it. The line is in the Log.", ["OK"], Color("#dd8877"))
		_open_dialog(d, func(_i): _close_dialog())
		await d.chosen


# ---------------------------------------------------------------- attacking
## One of your Units uses an Action on a target: the dice are rolled and shown,
## and what the Action's text says is carried out. A Burst then makes the next
## attack: by itself when one target is in reach, else it waits for your tap.
func attack_with(u: Dictionary, a: Dictionary, t: Dictionary, burst_left := -1) -> void:
	busy = true
	overlay.clear_tags()
	board.clear_blast()
	preview = ""
	var total := Effects.burst_of(a)
	var tv := board.view_of(t["id"])
	var at: Vector2 = tv.position if tv != null else Board.at(Battle.tile_of(t))
	var mark := _mark()
	var res := battle.attack(u, a, t, burst_left)
	aiming = -1
	targets = {}
	aim_pool = []
	burst = {}
	# (0.12) the blow or the shot, before what it did
	await _strike(u, a, t, res)
	var news := battle.log.slice(mark[1])
	var head := ""
	if total > 1 and res.get("inRange", true):
		head = "%s: attack %d of %d" % [a["name"], total - ((total - 1) if burst_left < 0 else burst_left), total]
	_show_result_at(res, t, at, head, news.slice(1))
	board.refresh_units(battle, selected_id)
	_float_all(battle.floats.slice(mark[0]), t["id"])
	var said := _tell(news)
	_show_panel(u)
	_update_bar()
	_say(said)
	await _wait(0.45)
	await _show_halts()
	if battle.settle():
		busy = false
		_update_bar()
		await _wait(0.6)
		show_result()
		return
	if res.has("burst") and not Rules.truthy(u.get("down")):
		var b: Dictionary = res["burst"]
		if b["pool"].size() == 1:
			_say(said + "  The Burst goes on: %d more." % b["left"])
			await _wait(0.6)
			await attack_with(u, a, battle.unit_by_id(b["pool"][0]), int(b["left"]) - 1)
			return
		busy = false
		_aim_burst(u, a, b, said)
		return
	busy = false
	if Rules.truthy(u.get("down")):
		deselect()
		_say(said)
	else:
		select(u)
		_say(said + "  " + _what_next())
	_update_bar()


## A Burst with more than one target in reach: they light up, and it waits.
func _aim_burst(u: Dictionary, a: Dictionary, b: Dictionary, said: String) -> void:
	var i := 0
	for k in u["actions"].size():
		if is_same(u["actions"][k], a):
			i = k
	selected_id = u["id"]
	burst = {"unit": u["id"], "action": i, "left": int(b["left"])}
	_aim(u, i, b["pool"].map(func(id): return battle.unit_by_id(id)))
	_update_bar()
	_say(said + "  Burst: %d more to make. Tap a lit target for the next." % burst["left"])


## One of your Units holds fire with an Action that has Suppressive Fire: its
## Energy is paid now, and it shoots the first Enemy that moves into its reach.
func hold_fire(action_name: String) -> void:
	var u = selected()
	if u == null or busy or walking or not _mine(u) or not burst.is_empty():
		return
	if not battle.hold_fire(u, action_name):
		return
	board.refresh_units(battle, selected_id)
	select(u)
	_update_bar()
	_say("%s holds fire with %s. In the Enemies' turn it shoots the first of them to move into its reach; if none does, the hold lapses." % [u["name"], action_name])


## (0.12) An attack, shown before what it did: a blow struck, or a shot of
## the Action's kind fired at the target (one that misses flies past); where
## it lands the target flashes and shakes, an area bursts over every tile it
## catches, and a heavy blow or a Unit brought down shakes the screen. The
## rules decided it all already: this only shows it. (0.16) The drawn effects:
## a muzzle flash as a shot leaves (it flies from the shooter's middle to the
## target's), an impact where damage lands, a heal rising from whoever is
## mended or helped, a shield where an attack glances off armour, and an
## explosion on every tile an area catches, or where a shell comes down.
func _strike(u, a: Dictionary, t, res: Dictionary) -> void:
	if Motion.still or u == null or t == null or battle == null:
		return
	var av := board.view_of(str(u["id"]))
	var tv := board.view_of(str(t["id"]))
	if tv == null:
		return
	var to: Vector2 = Board.at(Battle.tile_of(t)) if t.get("pos") is Dictionary else tv.position
	var from: Vector2 = Board.at(Battle.tile_of(u)) if u.get("pos") is Dictionary else (av.position if av != null else to)
	var kind := str(res.get("kind", Battle.role_of(a)))
	var hit: bool = res.get("hit") != false
	var through: bool = hit and res.get("penetrated") != false
	var mine := is_same(u, t) or str(u["id"]) == str(t["id"])
	# (0.16) a shell comes down on the tile, in an explosion of its own
	var shelled := false
	match kind:
		"melee":
			if av != null and not mine:
				await av.lunge(to)
		"support":
			pass
		_:
			if not mine:
				shelled = Motion.kind_of(a) == "shell"
				await fxl.fire(Motion.kind_of(a), from + Motion.BODY, to if shelled else to + Motion.BODY, Motion.colour_of(str(u.get("side", "")), kind), hit)
	var dmg := int(Rules.num(res.get("damage"), 0))
	if dmg > 0:
		var down := Rules.truthy(t.get("down"))
		tv.struck(dmg >= 6 or down)
		if not shelled:
			fxl.play("impact", to + Motion.BODY)
		Sound.play("hit")
		if dmg >= 6 or down:
			_shake(1.0 if down else 0.6)
		# (0.33) and the phone buzzes: one of yours hit (longer if brought down), or a heavy blow of yours
		if str(t.get("side", "")) == "ally":
			Motion.vibrate(160 if down else 45)
		elif str(u.get("side", "")) == "ally" and (dmg >= 6 or down):
			Motion.vibrate(25)
	elif Rules.truthy(res.get("healed")) or Rules.truthy(res.get("gained")):
		fxl.play("heal", to + Motion.FEET)
		Sound.play("heal")
	elif hit and not through and not shelled:
		# it hit, and glanced off the armour
		fxl.play("shield", to + Motion.BODY)
		Sound.play("miss")
	elif not through:
		Sound.play("miss")
	var r := Effects.aoe_of(a)
	if r > 0 and hit and t.get("pos") is Dictionary:
		fxl.area(Battle.tile_of(t), r, 1 if shelled else 0, _on_floor)


## (0.16) Whether a tile is on the fight's floor: an area explodes only there.
func _on_floor(h: Vector2i) -> bool:
	return battle != null and battle.floor_data != null and battle.floor_data.has_tile(h)


## The card a play is of (before it leaves the hand, the Consumables or the Bank).
func _card_of(p: Dictionary):
	if battle == null or p.is_empty():
		return null
	var list: Array = {"hand": battle.hand, "cons": battle.consumables, "chip": battle.bank}.get(p.get("kind"), [])
	var i := int(p.get("i", -1))
	return list[i] if i >= 0 and i < list.size() else null


## (0.12) A card played flies from where it was played from (the Hand,
## Consumables or Chips button) to whoever or wherever it goes, and lands with
## a flash. (0.16) Then what it did plays where it did it: an impact on each
## Unit it hurt, a heal on each it mended or helped, and, for one with an
## area that hurt, an explosion over every tile it catches. mark: where the
## fight's floats stood before it was played (what it did is after it).
func _card_flight(p: Dictionary, card, target, tile, mark: Array = []) -> void:
	if Motion.still:
		return
	Sound.play("card")
	var h = null
	if target != null and target.get("pos") is Dictionary:
		h = Battle.tile_of(target)
	elif tile is Vector2i:
		h = tile
	var vp := get_viewport_rect().size
	var btn: Button = {"hand": hand_btn, "cons": cons_btn, "chip": chips_btn}.get(p.get("kind"), hand_btn)
	var from: Vector2 = (btn.global_position + btn.size / 2.0) if btn != null and btn.visible else Vector2(90, vp.y - 50)
	var world: Vector2 = Board.at(h) if h != null else Vector2.ZERO
	var to: Vector2 = (get_viewport().get_canvas_transform() * board.to_global(world)) if h != null else vp / 2.0
	var colour := UI.type_colour(card) if card is Dictionary else UI.GOLD
	if Motion.moving():
		await overlay.fly_card(from, to, colour, str(p.get("name", "")), 0.34 * Motion.k())
	var hurt := false
	var seen := {}
	for f in (battle.floats.slice(int(mark[0])) if mark.size() > 0 and battle != null else []):
		var v := board.view_of(str(f["unit"]))
		var key := str(f["unit"]) + "/" + str(f["kind"])
		if v == null or seen.has(key):
			continue
		seen[key] = 1
		match str(f["kind"]):
			"damage":
				hurt = true
				fxl.play("impact", v.position + Motion.BODY)
			"heal", "buff":
				fxl.play("heal", v.position + Motion.FEET)
	var r := int(p.get("needs", {}).get("radius", 0))
	if h != null and r > 0 and hurt:
		fxl.area(h, r, 0, _on_floor)


## The dice readout where the target stood, and a number rising off it.
func _show_result_at(res: Dictionary, t: Dictionary, at: Vector2, head := "", more: Array = []) -> void:
	overlay.show_readout(at, dice_lines(res, t, head, more))
	if Rules.truthy(res.get("damage")):
		overlay.float_text(at, "-%d HP" % res["damage"], HURT, 0.0, Motion.moving())
	elif Rules.truthy(res.get("healed")):
		overlay.float_text(at, "+%d HP" % res["healed"], MEND)
	elif Rules.truthy(res.get("gained")):
		overlay.float_text(at, "+%d HP" % res["gained"], MEND)
	elif res.get("hit") == false:
		overlay.float_text(at, "Miss", PALE)
	elif res.get("penetrated") == false:
		overlay.float_text(at, "Glances off", PALE)


func _show_result_of(res: Dictionary, t: Dictionary) -> void:
	_show_result_at(res, t, Board.at(Battle.tile_of(t)))


## The dice and what they meant, a line each, then what the Action's text did:
##   Rapid Fire: attack 2 of 3
##   To-Hit: d20 14 vs 11 (Cover +2): hit
##   Penetration: d20 12 + 4 = 16 vs Armor Class 13: through
##   6 damage
##   Test Grunt gains Pinned for 2 turns
static func dice_lines(res: Dictionary, t: Dictionary, head := "", more: Array = []) -> Array:
	var out := []
	var kind := str(res.get("kind", "melee"))
	var good := Overlay.GOOD
	var bad := Overlay.POOR
	var rolls: Dictionary = res.get("rolls", {})
	if head != "":
		out.append([head, Color("#d6a851")])
	if kind == "aether":
		out.append(["Aether: always hits, always gets through", PALE])
	elif kind == "support":
		out.append(["Support: always lands", PALE])
	else:
		if Battle.aimed(kind):
			if rolls.has("accuracy"):
				var cov: int = res.get("cover", 0)
				out.append(["To-Hit: d20 %d vs %d%s: %s" % [rolls["accuracy"], res.get("needed", 0), (" (Cover +%d)" % cov) if cov else "", "hit" if res["hit"] else "miss"], good if res["hit"] else bad])
			elif res.get("hit") == true:
				out.append(["To-Hit: " + str(res.get("reason", "always hits")), good])
		elif res.get("hit") == false:
			out.append([str(res.get("reason", "can't reach")).capitalize(), bad])
		if rolls.has("penetration"):
			var total: int = res.get("penetrationTotal", rolls["penetration"])
			var ap: int = total - int(rolls["penetration"])
			var against := str(res.get("against", "Armor Class"))
			out.append(["Penetration: d20 %d%s vs %s %d: %s" % [rolls["penetration"], (" + %d = %d" % [ap, total]) if ap != 0 else "", against, res.get("needed_ac", 0), "through" if res["penetrated"] else "glances off"], good if res["penetrated"] else bad])
	var told: Array = more.filter(func(e): return not e.get("plain", false) and not e.get("halt", false) and e["kind"] == "act")
	if Rules.truthy(res.get("damage")):
		out.append(["%d damage%s" % [res["damage"], (" — %s is down" % t["name"]) if Rules.truthy(t.get("down")) else ""], HURT])
	elif Rules.truthy(res.get("healed")):
		out.append(["Healed %d" % res["healed"], MEND])
	elif Rules.truthy(res.get("gained")):
		out.append(["Gained %d Health" % res["gained"], MEND])
	elif res.get("hit") == false:
		out.append(["Miss", PALE])
	elif res.get("penetrated") == false:
		out.append(["No damage", PALE])
	elif told.is_empty():
		out.append(["No effect", PALE])
	# what the Action's text did, as the log has it
	for e in told.slice(0, 4):
		var line := str(e["text"])
		out.append([line if line.length() <= 60 else line.left(58) + "…", Color("#e6e7f0")])
	if told.size() > 4:
		out.append(["(%d more in the Log)" % (told.size() - 4), PALE])
	# what it dropped
	for e in more:
		if e["kind"] == "loot":
			var drop := str(e["text"])
			out.append([drop if drop.length() <= 60 else drop.left(58) + "…", LOOT])
	return out


# ---------------------------------------------------------------- the round
## End turn: if any of your Units could still do something, asks first.
func next_round() -> void:
	if battle == null or busy or walking or battle.over or not burst.is_empty() or not play.is_empty():
		return
	var still := battle.units.filter(func(x): return x["side"] == "ally" and not Rules.truthy(x.get("down")) and (battle.can_move(x) or Battle.usable_actions(x).any(func(a): return battle.action_state(x, a)["ok"])))
	# Auto takes the ones you haven't used; it asks only about the rest
	var taken := battle.auto_queue() if auto else []
	still = still.filter(func(x): return not taken.has(x["id"]))
	if still.is_empty() or battle.enemies_left() == 0:
		await end_turn()
		return
	var names := still.map(func(x): return x["name"])
	var text := "%s can still move or act." % _list(names)
	if auto:
		text += " Auto leaves %s alone, because you've used %s this turn." % ["it" if names.size() == 1 else "them", "it" if names.size() == 1 else "them"]
	_open_dialog(Dialog.new("End your turn?", text + (" The Enemies take their turn next." if taken.is_empty() else " The rest of your Units take their turns, then the Enemies."), ["Go back", "End the turn"], Color("#d6a851")), func(i):
		_close_dialog()
		if i == 1:
			end_turn())


## Your turn ends: with Auto on, the Units you haven't used take their own
## turns first; then the Enemies take theirs.
func end_turn() -> void:
	if auto and not await run_auto_phase():
		return
	if battle != null and battle.pvp > 0:
		await run_pvp_hand_over()
		return
	await run_enemy_phase()


## (0.26) Pass and play: the player whose turn it was ends it, the screen is
## covered, and once the other player is ready their turn begins: the sides
## change over, and their Aether, Chips, cards and Recharge play out.
func run_pvp_hand_over() -> void:
	if battle == null or busy or battle.over or not burst.is_empty():
		return
	if not play.is_empty():
		_play_cancel()
	hand_tray.visible = false
	deselect()
	busy = true
	_update_bar()
	battle.pvp_end_turn()
	board.refresh_units(battle)
	if battle.over:
		busy = false
		await _wait(0.4)
		show_result()
		return
	handoff.show_for(battle.pvp_names[battle.pvp_other()], battle.round + (1 if battle.pvp == 2 else 0))
	await handoff.ready_pressed
	var mk := _mark()
	battle.pvp_hand_over()
	board.refresh_units(battle)
	_start_view()                 # the board as the player taking the phone stands
	busy = false
	_update_bar()
	await _show_halts()
	if battle.over:
		await _wait(0.4)
		show_result()
		return
	_say("Round %d: %s's turn. %s" % [battle.round, battle.pvp_names[battle.pvp], _tell(_news(mk), 4)])


## Auto: every Unit of yours that you haven't moved or used this turn takes
## its turn by itself, one at a time, by its Behavior keywords. Returns
## whether the battle goes on (false: it ended here, and the result is up).
func run_auto_phase() -> bool:
	if battle == null or busy or battle.over or not burst.is_empty():
		return false
	var queue := battle.auto_queue()
	if queue.is_empty() or battle.enemies_left() == 0:
		return true
	if not play.is_empty():
		_play_cancel()
	hand_tray.visible = false
	deselect()
	busy = true
	auto_phase = true
	fast = false
	_update_bar()
	_say("Auto: %d of your Units take%s their turn%s. Tap the board to hurry them." % [queue.size(), "s" if queue.size() == 1 else "", "" if queue.size() == 1 else "s"])
	for id in queue:
		var u = battle.unit_by_id(id)
		if u == null or Rules.truthy(u.get("down")) or battle.has_acted(u):
			continue
		if battle.enemies_left() == 0:
			break
		Behaviors.apply(u)
		board.mark_units(battle, "", {}, id)
		await _follow(Battle.tile_of(u))
		await _wait(0.25)
		# its whole turn is decided here; the beats play it back as it went
		var beats := battle.auto_turn(u)
		for beat in beats:
			await _play_beat(beat, id)
		if beats.is_empty():
			await _wait(0.15)
		board.refresh_units(battle, "", {}, id)
		_update_bar()
		await _show_halts()
		if battle.settle():
			break
	board.refresh_units(battle)
	auto_phase = false
	busy = false
	fast = false
	_update_bar()
	if battle.over:
		await _wait(0.4)
		show_result()
		return false
	return true


static func _list(names: Array) -> String:
	if names.size() <= 1:
		return "".join(names)
	if names.size() > 4:
		return ", ".join(names.slice(0, 3)) + " and %d more" % (names.size() - 3)
	return ", ".join(names.slice(0, names.size() - 1)) + " and " + str(names[names.size() - 1])


## The Enemies' turn, one at a time, then the round turns over.
func run_enemy_phase() -> void:
	if battle == null or busy or battle.over or not burst.is_empty():
		return
	if not play.is_empty():
		_play_cancel()
	hand_tray.visible = false
	deselect()
	busy = true
	enemy_phase = true
	fast = false
	_update_bar()
	# Handbook 15.9: your turn is over, so what arrived in the Enemies' turn ticks now
	var m0 := _mark()
	battle.end_player_turn()
	var ticked := _tell(_news(m0))
	board.refresh_units(battle)
	if ticked != "":
		_say("Your turn ends: " + ticked)
		await _wait(1.1)
		await _show_halts()
	if not battle.settle():
		_say("The Enemies' turn. Tap the board to hurry them.")
	for id in (battle.enemy_queue() if not battle.over else []):
		var e = battle.unit_by_id(id)
		if e == null or Rules.truthy(e.get("down")):
			continue
		board.mark_units(battle, "", {}, id)
		await _follow(Battle.tile_of(e))
		await _wait(0.25)
		# its whole turn is decided here; the beats play it back as it went
		var beats := battle.enemy_turn(e)
		for beat in beats:
			await _play_beat(beat, id)
		if beats.is_empty():
			await _wait(0.15)
		board.refresh_units(battle, "", {}, id)
		await _show_halts()
		if battle.settle():
			break
	board.refresh_units(battle)
	var said := ""
	if not battle.over:
		said = await _turn_over()
	enemy_phase = false
	upkeep = false
	busy = false
	fast = false
	banner.visible = false
	_update_bar()
	await _show_halts()
	if battle.over:
		await _wait(0.4)
		show_result()
		return
	_say("Round %d: your turn. Energy is refilled.%s" % [battle.round, ("  " + said) if said != "" else ""])


## The round turns over. The Enemies' turn ends (held shots lapse, hazards
## bite, Energy refills), then each phase before yours plays out and is
## announced: Waves, Aether Generation, Aether Draw, Draw, Recharge. A Quick
## battle has only the Recharge, and says it in the bottom line as before.
## Returns what to tell as your turn begins.
func _turn_over() -> String:
	var mark := _mark()
	battle.end_enemy_phase()
	board.refresh_units(battle)
	var ending := _news(mark)
	if battle.settle():
		return ""
	battle.begin_round()
	_update_bar()
	if not battle.with_cards and battle.waves_total <= 1:
		var m2 := _mark()
		battle.run_phase("recharge")
		battle.begin_turn()
		battle.settle()
		board.refresh_units(battle)
		return _tell(ending + _news(m2), 2)
	upkeep = true
	if _tell(ending) != "":
		_say(_tell(ending))
		await _wait(0.8)
	for k in battle.upkeep():
		var mk := _mark()
		var before := battle.units.size()
		battle.run_phase(k)
		board.refresh_units(battle)
		var news := _news(mk)
		_update_bar()
		_announce(Battle.phase_name(k), _tell(news, 4))
		if battle.units.size() > before:
			var pts := []
			for u in battle.units.slice(before):
				if u.get("pos") is Dictionary:
					pts.append(Board.at(Battle.tile_of(u)))
			if not pts.is_empty():
				await _follow_point(pts[0])
		await _wait(1.15 if _tell(news, 4) != "" else 0.5)
		await _show_halts()
		if battle.settle():
			break
	battle.begin_turn()
	return ""


## Names the phase the round is in, with what it did, across the top of the board.
func _announce(phase_name: String, text: String) -> void:
	# (0.14) the phase's name is said once: the banner's title, not again in its line
	if text.begins_with(phase_name + ": "):
		text = text.substr(phase_name.length() + 2)
		text = text.substr(0, 1).to_upper() + text.substr(1)
	banner.visible = true
	banner_title.text = phase_name
	banner_text.text = UI.show(text)
	banner_text.visible = text != ""
	# (0.14) the banner alone says it; the Log keeps the line


## One beat of an Enemy's turn, played back: it walks, a held shot answers it,
## it attacks, or it has nothing to do. The board then shows how things stood
## when the beat was over.
func _play_beat(beat: Dictionary, acting: String) -> void:
	var after: Array = beat.get("after", [])
	var entries := battle.log.slice(beat["l0"], beat["l0"] + beat.get("lines", []).size())
	match beat["type"]:
		"move":
			var v := board.view_of(beat["unit"])
			if v != null:
				v.step_time = UnitView.STEP_TIME * (0.3 if fast else 1.0)
				v.walk(beat["path"])
				await v.walked
				v.step_time = UnitView.STEP_TIME
			board.sync(battle, after)
			board.mark_units(battle, "", {}, acting)
			_float_all(beat.get("floats", []))
			var told := _tell(entries)
			if told != "":
				_say(told)
				await _wait(0.9)
		"attack", "react":
			var tv := board.view_of(beat["target"])
			var t = battle.unit_by_id(beat["target"])
			var at: Vector2 = tv.position if tv != null else Board.at(Battle.tile_of(t))
			await _follow_point(at)
			var then = t
			for d in after:
				if d["id"] == beat["target"]:
					then = d
			# (0.12) the blow or the shot, before what it did
			await _strike(battle.unit_by_id(beat["unit"]), beat["action"], then, beat["res"])
			_show_result_at(beat["res"], then, at, "%s reacts: %s" % [battle.unit_by_id(beat["unit"])["name"], beat["action"]["name"]] if beat["type"] == "react" else "", entries.slice(1))
			board.sync(battle, after)
			board.mark_units(battle, "", {}, acting)
			_float_all(beat.get("floats", []), beat["target"])
			_say(_tell(entries))
			await _wait(1.1 + 0.25 * mini(3, maxi(0, entries.size() - 1)))
		"skip":
			board.sync(battle, after)
			board.mark_units(battle, "", {}, acting)
			_float_all(beat.get("floats", []))
			_say(_tell(entries))
			await _wait(0.6)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds * (0.25 if fast else 1.0) * Motion.wait_k()).timeout


## Brings a tile into view if it's off the screen.
func _follow(h: Vector2i) -> void:
	await _follow_point(Board.at(h))


func _follow_point(p: Vector2) -> void:
	var vp := get_viewport_rect().size
	var at := get_viewport().get_canvas_transform() * board.to_global(p)
	var safe := Rect2(80, BAR_H + 50, vp.x - 160, vp.y - BAR_H - 120)
	if safe.has_point(at):
		return
	_stop_camera()
	_cam_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_cam_tween.tween_property(camera, "position", board.to_global(p), 0.3 * (0.3 if fast else 1.0))
	await _cam_tween.finished


# ---------------------------------------------------------------- the end
func show_result() -> void:
	if battle == null or not battle.over:
		return
	# (0.19) Victory or Defeat powers on first; then the tally
	if _neon_first():
		return
	burst = {}
	deselect()
	if battle.pvp > 0:
		show_pvp_result()
		return
	if battle.deploy != null and campaign != null:
		show_deploy_result()
		return
	# (0.10: a practice fight's Districts and Enemies count as met, for the dock's Exchange and Bounty Board)
	if campaign != null:
		campaign.save()
	var mine := battle.side_units("ally")
	var up := mine.filter(func(u): return not Rules.truthy(u.get("down"))).size()
	var foes := battle.side_units("enemy")
	var downed := foes.filter(func(u): return Rules.truthy(u.get("down"))).size()
	var title: String = {"ally": "Victory", "enemy": "Defeat", "draw": "A draw"}.get(battle.winner, "Over")
	# (0.15) how it went, as a strip: the rounds, yours standing, theirs down
	var lead := ""
	if battle.winner == "enemy":
		lead = "Every Hero is down."
	elif battle.winner == "ally" and battle.waves_total > 1:
		lead = "Every wave beaten." if battle.wave >= battle.waves_total else "Nothing more can come."
	var text := (lead + "\n\n" if lead != "" else "") + "\n".join(loot_result_lines())
	var d := Dialog.new(title, text, ["Play again", "New battle", "Home", "See the board"], Color("#d6a851") if battle.winner == "ally" else Color("#ff2a3c"))
	d.set_title_art(Art.menu_piece("victory" if battle.winner == "ally" else "defeat") if battle.winner in ["ally", "enemy"] else null)
	d.add_strip(result_strip(up, mine.size(), downed, foes.size()))
	# (0.11) what dropped, at a glance (0.15: as tiles, one by one)
	var lr: Dictionary = battle.loot_result
	if not lr.is_empty() and not Loot.is_empty(lr["total"] if lr["won"] else lr["haul"]):
		d.add_loot(UI.bag_items(lr["total"] if lr["won"] else lr["haul"]), "In all" if lr["won"] else "Lost with the fight")
	_open_dialog(d, func(i):
		_close_dialog()
		if i == 0:
			play_again()
		elif i == 1:
			new_battle()
		elif i == 2:
			leave()
		else:
			_say("%s in round %d. Look over the board and the Log; Leave takes you on." % [title, battle.round]))
	_update_bar()


## (0.19) A won or lost fight plays its scene once before its tally (and not
## when nothing moves): its sign powers on, yours standing (or fallen) under
## it. True when it has begun, and show_result is asked again when it is over.
func _neon_first() -> bool:
	if battle.pvp > 0 or not (battle.winner in ["ally", "enemy"]) or not Motion.moving() or _neon_for == battle:
		return false
	_neon_for = battle
	var won: bool = battle.winner == "ally"
	var toks := []
	for u in battle.side_units("ally"):
		if Rules.truthy(u.get("down")) != won:
			var c = roster.card_named(str(u.get("name", ""))) if roster != null else null
			var look: Dictionary = roster.token_for(c) if c != null else {}
			if look.get("texture") != null:
				toks.append(look["texture"])
	neon = NeonScene.new(won, Art.menu_piece("victory" if won else "defeat"), toks)
	neon.done.connect(func():
		neon = null
		show_result())
	ui.add_child(neon)
	return true


## (0.26) A match is over: who won, by name, and how it stood; Rematch plays
## the same two teams again.
func show_pvp_result() -> void:
	battle.pvp_tally()
	var champ := battle.pvp_winner()
	var title := ("%s wins" % champ) if champ != "" else "A draw"
	var standing := func(side: String) -> String:
		var us: Array = battle.side_units(side)
		return "%s: %d of %d Units standing" % [battle.pvp_name_of(side), us.filter(func(u): return not Rules.truthy(u.get("down"))).size(), us.size()]
	var text := "Every Hero of %s's is down.\n\n%s\n%s" % [battle.pvp_name_of("enemy" if battle.winner == "ally" else "ally"), standing.call("ally"), standing.call("enemy")] if champ != "" else "Nobody is left standing."
	# (0.33) the match in numbers, player by player
	text += "\n\nIn %d round%s:" % [battle.round, "" if battle.round == 1 else "s"]
	for p in [1, 2]:
		var st: Dictionary = battle.pvp_stats[p]
		text += "\n%s dealt %d damage, brought down %d Unit%s and played %d card%s." % [battle.pvp_names[p], st["damage"], st["downs"], "" if st["downs"] == 1 else "s", st["cards"], "" if st["cards"] == 1 else "s"]
	var d := Dialog.new(title, text, ["Rematch", "New match", "Home", "See the board"], Color("#d6a851"))
	d.add_strip([["Round %d" % battle.round, "#d6a851"]])
	_open_dialog(d, func(i):
		_close_dialog()
		if i == 0:
			play_again()
		elif i == 1:
			new_battle()
		elif i == 2:
			leave()
		else:
			_say("%s in round %d. Look over the board and the Log; Leave takes you on." % [title, battle.round]))
	_update_bar()


## (0.15) The strip under a fight's title: [[text, colour], ...].
func result_strip(up: int, of: int, downed: int, foes: int) -> Array:
	return [["Round %d" % battle.round, "#d6a851"], ["%d of %d yours standing" % [up, of], "#73efe8"], ["%d of %d Enem%s down" % [downed, foes, "y" if foes == 1 else "ies"], "#ff2a3c"]]


## A deployment's fight is over: the deployment is told, once, and says what
## comes next: another floor, the map, the same fight again with the Heroes
## still standing, or a wipe. (simDeployFinish and simDeployResultHTML)
func show_deploy_result() -> void:
	if deploy_out.is_empty():
		deploy_out = campaign.deploy.fight_over(battle.deploy_result())
		campaign.save()
	var o := deploy_out
	var next: String = str(o.get("next", "map"))
	var title: String = {"ally": "Victory", "enemy": "Defeat", "draw": "A draw", "escape": "Escaped"}.get(battle.winner, "Over")
	var labels := ["Back to the map"]
	if next == "floor":
		labels = ["Next floor (%d of %d)" % [int(o["floor"]), int(o["count"])]]
	elif next == "retry":
		labels = ["Retry with reserves", "Give up: lose the haul"]
	labels.append("See the board")
	var d := Dialog.new(title, "\n\n".join(deploy_result_lines()), labels, Color("#d6a851") if (battle.winner == "ally" or battle.winner == "escape") else Color("#ff2a3c"))
	d.set_title_art(Art.menu_piece("victory" if battle.winner == "ally" else "defeat") if battle.winner in ["ally", "enemy"] else null)
	var mine := battle.side_units("ally")
	var foes := battle.side_units("enemy")
	d.add_strip(result_strip(mine.filter(func(u): return not Rules.truthy(u.get("down"))).size(), mine.size(), foes.filter(func(u): return Rules.truthy(u.get("down"))).size(), foes.size()))
	# (0.11) what went into the haul, at a glance (0.15: as tiles, one by one)
	var got := Loot.add(o.get("gained") if o.get("gained") is Dictionary else null, o["final"]["bag"] if o.get("final") is Dictionary else null)
	if not Loot.is_empty(got):
		d.add_loot(UI.bag_items(got), "In all")
	elif str(o.get("next")) == "wipe" and not Loot.is_empty(o.get("lostHaul")):
		d.add_loot(UI.bag_items(o.get("lostHaul")), "Lost")
	_open_dialog(d, func(i):
		_close_dialog()
		if i == labels.size() - 1:
			_say("%s in round %d. Look over the board and the Log; Leave takes you on." % [title, battle.round])
		elif next == "floor" or (next == "retry" and i == 0):
			_from_fight()
			start_deploy_fight()
		elif next == "retry":
			var w := campaign.deploy.wipe()
			campaign.save()
			var more := campaign.end_lines(w, true)
			_open_dialog(Dialog.new("Deployment lost", "A wipe loses everything carried: %s%s.\n\nThe free Heroes recover at the dock; a recruited one is lost with the team.%s" % [campaign.loot.text(w.get("lostHaul")),
				(", " + ", ".join(w["lostItems"].map(func(it): return campaign.progress.item_name(it, true)))) if not w.get("lostItems", []).is_empty() else "",
				("\n\n" + "\n".join(more)) if not more.is_empty() else ""], ["Back to the map"], Color("#ff2a3c")), func(_j):
				_close_dialog()
				_from_fight())
		else:
			_from_fight())
	_update_bar()


## Back on the map after a fight, with the board put away.
func _from_fight() -> void:
	play = {}
	burst = {}
	show_map()
	map_screen.after_fight(deploy_out)


## What a deployment's fight came to, a paragraph a line.
func deploy_result_lines() -> Array:
	var o := deploy_out
	var res := battle.deploy_result()
	var t := campaign.loot
	var out := []
	var rounds := "%d round%s" % [battle.round, "" if battle.round == 1 else "s"]
	match battle.winner:
		"escape": out.append("A Hero reached the Emergency Exit. The Strike Team leaves the POI with what it found; its final reward is given up.")
		"ally": out.append("Every Enemy is down after %s." % rounds)
		"enemy": out.append("Every Hero who went in is down after %s." % rounds)
		_: out.append("Both sides are down, so the fight counts as lost.")
	var fallen := []
	if not res["heroesDown"].is_empty():
		fallen.append("%s %s down and sit%s out the rest of the deployment." % [_list(res["heroesDown"]), "is" if res["heroesDown"].size() == 1 else "are", "s" if res["heroesDown"].size() == 1 else ""])
	if not res["troopsLost"].is_empty():
		fallen.append("Troops lost for the rest of it: %s." % ", ".join(res["troopsLost"]))
	if not res["consUsed"].is_empty():
		fallen.append("Consumables used: %s." % ", ".join(res["consUsed"]))
	if not fallen.is_empty():
		out.append(" ".join(fallen))
	var named := func(it): return "%s %s" % [Progress.kind_word(it).to_lower(), campaign.progress.item_name(it, true)]
	if o.get("gained") != null and (not Loot.is_empty(o["gained"]) or not o.get("items", []).is_empty()):
		out.append("Into the haul: %s%s." % [t.text(o["gained"]) if not Loot.is_empty(o["gained"]) else "no components", ("; and " + ", ".join(o["items"].map(named))) if not o.get("items", []).is_empty() else ""])
	elif o.get("gained") != null:
		out.append("Nothing dropped.")
	elif not Loot.is_empty(res["haul"]) or not res["items"].is_empty():
		out.append("What dropped here is lost with the fight: %s." % t.text(res["haul"]))
	if Rules.truthy(o.get("poiDone")) and o.get("final") is Dictionary:
		var fin: Dictionary = o["final"]
		out.append("%s cleared. Its reward: %s%s." % [str(o.get("name", "The POI")), t.text(fin["bag"]), ("; and " + ", ".join(fin["items"].map(named))) if not fin["items"].is_empty() else ""])
	match str(o.get("next", "map")):
		"floor": out.append("Floor %d of %d cleared. The only way out is onward, or an Emergency Exit." % [int(o["floor"]) - 1, int(o["count"])])
		"retry": out.append("The haul is safe while a Hero stands. %s can try this fight again." % _list(o.get("reserves", [])))
		"wipe":
			out.append("Deployment lost: a wipe loses everything carried: %s%s. The free Heroes recover at the dock; a recruited one is lost with the team." % [t.text(o.get("lostHaul")),
				(", " + ", ".join(o["lostItems"].map(func(it): return campaign.progress.item_name(it, true)))) if not o.get("lostItems", []).is_empty() else ""])
			out.append_array(campaign.end_lines(o, true))
		_: out.append("It is yours once the team walks back onto the dock.")
	return out


## What dropped, the floor's own reward on a win, and that none of it is kept
## yet. A fight that is lost loses what it was carrying (Handbook: a wipe
## loses everything carried).
func loot_result_lines() -> Array:
	var r: Dictionary = battle.loot_result
	if r.is_empty():
		return []
	var out := []
	var t := battle.loot_table
	if not r["won"]:
		if Loot.is_empty(r["haul"]):
			return ["Nothing had dropped."]
		return ["Dropped and found: %s. Lost with the fight: what a Strike Team carries is kept only by winning." % t.text(r["haul"])]
	out.append("Dropped and found: %s." % t.text(r["haul"]))
	if Loot.is_empty(r["reward"]):
		out.append("This floor has no reward of its own." if not (battle.floor_data.raw.get("loot") is Dictionary) else "The floor's reward came to nothing this time.")
	else:
		out.append("The floor's reward: %s." % t.text(r["reward"]))
		# (0.11: the two together are shown under the text, as icons and numbers)
	var items: Array = r.get("items", [])
	if not items.is_empty():
		out.append("It would have left %d blueprint or chassis find%s." % [items.size(), "" if items.size() == 1 else "s"])
	if not Loot.is_empty(r["total"]) or not items.is_empty():
		out.append("A practice fight: nothing is kept. Deploy from the World Map to keep what you find.")
	return out


func _open_dialog(d: Dialog, on_choice: Callable) -> void:
	_close_dialog()
	dialog = d
	d.chosen.connect(on_choice)
	ui.add_child(d)


func _close_dialog() -> void:
	if dialog != null:
		Motion.pop_out(dialog, dialog.get_meta("box", null))
		dialog = null


func toggle_log() -> void:
	if battle == null:
		return
	if log_panel.visible:
		log_panel.visible = false
	else:
		log_panel.show_log(battle.log, ("Loot so far: " + battle.loot_table.text(battle.loot) + (". Yours if the fight is won and the team gets home." if battle.deploy != null else ". A practice fight: not kept.")) if not Loot.is_empty(battle.loot) else "")
	_layout_info()


func _say(t: String) -> void:
	info.text = UI.show(t.strip_edges())
	# (0.14) what is said while the round plays out is news: it fades; the Log keeps it
	if _info_fade != null and _info_fade.is_valid():
		_info_fade.kill()
	info.modulate.a = 1.0
	info_back.modulate.a = 1.0
	info_more.modulate.a = 1.0
	if busy and is_inside_tree():
		_info_fade = create_tween()
		_info_fade.tween_interval(5.0)
		_info_fade.tween_property(info, "modulate:a", 0.0, 0.6)
		_info_fade.parallel().tween_property(info_back, "modulate:a", 0.0, 0.6)
		_info_fade.parallel().tween_property(info_more, "modulate:a", 0.0, 0.6)
	_layout_more()


# ---------------------------------------------------------------- the trays
## Opens a tray (your hand, Consumables, Chips with an effect, the Discard
## Pile), or puts it away if it's the one that's open.
func toggle_tray(kind: String) -> void:
	if battle == null or not battle.with_cards or busy:
		return
	if not play.is_empty():
		_play_cancel()
	if hand_tray.visible and hand_tray.kind == kind:
		hand_tray.visible = false
	else:
		_fill_tray(kind)
	_layout_info()


func toggle_hand() -> void:
	toggle_tray("hand")


func _fill_tray(kind: String) -> void:
	match kind:
		"hand": hand_tray.show_hand(battle, roster)
		"cons": hand_tray.show_consumables(battle, roster)
		"chips": hand_tray.show_chips(battle, roster)
		"discard": hand_tray.show_discard(battle, roster)
		"recover": hand_tray.show_discard(battle, roster, true, str(play.get("name", "")))


func _close_tray() -> void:
	if hand_tray.kind == "recover" and not play.is_empty():
		_play_cancel()
	hand_tray.visible = false
	_layout_info()


## A tile in the open tray is tapped: the card is read, or (choosing which
## Troop's card a Recover returns) chosen.
func _on_tray_card(index: int) -> void:
	if battle == null or index < 0 or index >= hand_tray.refs.size():
		return
	var at: int = hand_tray.refs[index]
	match hand_tray.kind:
		"hand": read_hand_card(at)
		"cons": read_consumable(at)
		"chips": read_chip(at)
		"discard": read_discard(at)
		"recover":
			if not play.is_empty():
				play["recover"] = at
				hand_tray.visible = false
				_layout_info()
				await _play_next()


## Warns that some of a card's text is plain, if it is.
static func _plain_note(plain: bool, verb: String) -> String:
	return ("  Some of its text is plain (no keywords), so %s it won't make that text happen." % verb) if plain else ""


## A card in your hand, read in full: what it costs, whether it can be played
## now, and Play.
func read_hand_card(i: int) -> void:
	if battle == null or i < 0 or i >= battle.hand.size() or sheet != null:
		return
	var h: Dictionary = battle.hand[i]
	var c = roster.card_named(str(h["name"]))
	var st := battle.play_state(h)
	var note := "In your hand."
	if st["ok"]:
		match st["kind"]:
			"troop": note += " It deploys on an open Player Spawn Tile, and can move and act at once."
			"equipment": note += " It goes on one of your Units."
			_:
				var needs: Dictionary = st["needs"]
				if needs["recover"]:
					note += " It returns a Troop's card from the Discard Pile to your hand."
				if needs["need"] == "tile":
					note += " You choose where it lands."
				elif needs["need"] != "":
					note += " You choose who it's aimed at."
	else:
		note += "  " + UI.show(str(st["why"]))
	note += _plain_note(h.get("type") != "troop" and Roster.has_plain_text(c), "playing")
	var opts := {"note": note, "buttons": [["play", "Play", st["ok"]]]}
	# a variable cost: X is chosen here, from 1 to the most the Bank could pay
	var variable: bool = st.get("variable", false) and st["ok"]
	if variable:
		opts["stepper"] = {"value": 1, "min": 1, "max": maxi(1, int(st["max_x"])), "label": "X"}
		opts["x"] = 1
		opts["note"] = note + "  " + x_cost_words(h, 1)
	var s := CardSheet.new(c if c != null else {"name": h["name"], "cardType": h.get("type", "")}, roster.art_for(c) if c != null else null, opts)
	if variable:
		s.stepped.connect(func(x):
			s.set_note(note + "  " + x_cost_words(h, x))
			s.show_x(x))
	_open_sheet(s, func(id):
		if id == "play":
			begin_play("hand", i, s.value if variable else null))


## "At X = 2 it costs 2 D3 Aether; the Bank holds 3 D3."
func x_cost_words(h: Dictionary, x: int) -> String:
	return "A variable cost: at X = %d it costs %s Aether. The Bank holds %s." % [x, UI.show(Roster.cost_label(h, x)), UI.show(Battle.aether_label(battle.aether))]


## A Consumable, read in full, and Use.
func read_consumable(i: int) -> void:
	if battle == null or i < 0 or i >= battle.consumables.size() or sheet != null:
		return
	var item: Dictionary = battle.consumables[i]
	var c = roster.card_named(str(item["name"]))
	var st := battle.consumable_state(i)
	var left := battle.consumables.filter(func(x): return x["name"] == item["name"] and not Rules.truthy(x.get("used"))).size()
	var note := "A Consumable: it costs no Aether and is used once. %d left for this Battle." % left
	if not st["ok"]:
		note += "  " + str(st["why"])
	note += _plain_note(Roster.text_has_plain(item.get("text", "")), "using")
	var s := CardSheet.new(c if c != null else {"name": item["name"], "cardType": "consumable"}, roster.art_for(c) if c != null else null,
		{"note": note, "buttons": [["play", "Use", st["ok"]]]})
	_open_sheet(s, func(id):
		if id == "play":
			begin_play("cons", i))


## A Chip in the Bank that carries an effect, read in full, and Spend.
func read_chip(i: int) -> void:
	if battle == null or i < 0 or i >= battle.bank.size() or sheet != null:
		return
	var chip: Dictionary = battle.bank[i]
	var c = roster.card_named(str(chip["name"]))
	var st := battle.chip_state(i)
	var note := "In the Bank. Spending it for its effect costs nothing more: it has generated its Aether this turn, and turns face-up again at the Recharge."
	if not st["ok"]:
		note += "  " + str(st["why"])
	note += _plain_note(Roster.text_has_plain(battle.chip_text(chip)), "spending")
	var s := CardSheet.new(c if c != null else {"name": chip["name"], "cardType": "sphere"}, roster.art_for(c) if c != null else null,
		{"note": note, "buttons": [["play", "Spend", st["ok"]]]})
	_open_sheet(s, func(id):
		if id == "play":
			begin_play("chip", i))


## A card in the Discard Pile, read in full.
func read_discard(i: int) -> void:
	if battle == null or i < 0 or i >= battle.discard.size() or sheet != null:
		return
	var d: Dictionary = battle.discard[i]
	var c = roster.card_named(str(d["name"]))
	_open_sheet(CardSheet.new(c if c != null else {"name": d["name"], "cardType": d.get("type", "")}, roster.art_for(c) if c != null else null,
		{"note": "In the Discard Pile. Every discarded card returns to the Deck when the Battle ends." + (" A Recover can return this one to your hand." if d.get("type") == "troop" else "")}))


func _open_sheet(s: CardSheet, on_choice: Callable = Callable()) -> void:
	_close_sheet()
	sheet = s
	s.chosen.connect(func(id):
		_close_sheet()
		if on_choice.is_valid():
			on_choice.call(id))
	ui.add_child(s)


func _close_sheet() -> void:
	if sheet != null:
		Motion.pop_out(sheet, sheet.get_meta("box", null))
		sheet = null


# ---------------------------------------------------------------- playing a card
## Play (or Use, or Spend) is tapped: the tray slides away and whatever the
## card needs is asked for on the board. Nothing is paid until it lands.
func begin_play(kind: String, i: int, x = null) -> void:
	if battle == null or busy or walking or not burst.is_empty() or battle.over:
		return
	_close_sheet()
	hand_tray.visible = false
	play = {}
	deselect()
	var st: Dictionary
	var nm := ""
	match kind:
		"hand":
			if i < 0 or i >= battle.hand.size():
				return
			# a variable cost: the X it is played for (1 if nobody chose), no more than the Bank could pay
			if Roster.card_var(battle.hand[i]):
				x = clampi(int(x) if x != null else 1, 1, maxi(1, battle.max_x(battle.hand[i])))
			else:
				x = null
			st = battle.play_state(battle.hand[i], x)
			nm = str(battle.hand[i]["name"])
		"cons":
			if i < 0 or i >= battle.consumables.size():
				return
			st = battle.consumable_state(i)
			nm = str(battle.consumables[i]["name"])
		"chip":
			if i < 0 or i >= battle.bank.size():
				return
			st = battle.chip_state(i)
			nm = str(battle.bank[i]["name"])
		_:
			return
	if not st["ok"]:
		_layout_info()
		_say(UI.show(str(st["why"])))
		return
	play = {"kind": kind, "i": i, "name": nm, "type": st.get("kind", "plain"), "needs": st.get("needs", {"need": "", "radius": 0, "narrow": [], "recover": false}),
		"step": "", "pool": {}, "recover": null, "at": null, "x": x if kind == "hand" else null}
	_update_bar()
	await _play_next()


## What the card being played still needs: which Troop's card to Recover,
## then where or who. With nothing left to ask, it is played.
func _play_next() -> void:
	if play.is_empty():
		return
	var nm: String = play["name"]
	var needs: Dictionary = play["needs"]
	if play["type"] == "troop":
		var spots := battle.open_spawns()
		if spots.size() == 1:
			await _play_commit(null, spots[0])
			return
		play["step"] = "spawn"
		board.clear_marks()
		board.set_reach(spots.map(func(t): return {"q": t.x, "r": t.y, "cost": 0}), "ally")
		_frame(spots.map(func(t): return Board.at(t)), 0.0)
		_say("%s: tap a lit Player Spawn Tile to deploy it there, or anywhere else to put it back in your hand." % nm)
		return
	if play["type"] == "equipment":
		var mine := battle.side_units("ally").filter(func(u): return not Rules.truthy(u.get("down")) and u.get("pos") is Dictionary)
		if mine.size() == 1:
			await _play_commit(mine[0], null)
			return
		_light("unit", mine)
		_say("%s: tap one of your Units to equip it, or anywhere else to put it back in your hand." % nm)
		return
	if needs["recover"] and play["recover"] == null:
		var pile := battle.recoverable()
		if pile.size() > 1:
			play["step"] = "recover"
			_fill_tray("recover")
			_layout_info()
			_say("%s: tap the Troop whose card returns to your hand." % nm)
			return
		play["recover"] = pile[0]
	match needs["need"]:
		"enemy", "ally":
			_light("target", battle.pool_for_need(needs))
			_say("%s: tap a lit %s%s, or anywhere else to put it back." % [nm, "Enemy" if needs["need"] == "enemy" else "Unit of yours",
				" to see what its area would take in; a second tap plays it" if int(needs["radius"]) > 0 else ""])
		"tile":
			play["step"] = "tile"
			board.clear_marks()
			_say("%s: tap a tile to see what it would take in there. Tap it again to play it, or tap off the floor to put it back." % nm)
		_:
			await _play_commit(null, null)


## Lights the Units a card could go to.
func _light(step: String, pool: Array) -> void:
	play["step"] = step
	play["at"] = null
	var lit := {}
	for u in pool:
		lit[u["id"]] = true
	play["pool"] = lit
	board.clear_marks()
	overlay.clear_tags()
	board.mark_units(battle, "", lit)
	_frame(pool.map(func(u): return Board.at(Battle.tile_of(u))), 0.0)


## A tap on the board while a card is being played.
func _play_tap(h: Vector2i) -> void:
	var there = battle.unit_at(h)
	match str(play.get("step", "")):
		"spawn":
			if board.reach.has(h):
				await _play_commit(null, h)
			else:
				_play_cancel()
		"unit":
			if there != null and play["pool"].has(there["id"]):
				await _play_commit(there, null)
			else:
				_play_cancel()
		"target":
			if there != null and play["pool"].has(there["id"]):
				if int(play["needs"]["radius"]) > 0 and play["at"] != h:
					_play_preview(h, there)
				else:
					await _play_commit(there, null)
			elif play["at"] != null:
				# the preview is put away; still choosing
				play["at"] = null
				board.clear_blast()
				board.mark_units(battle, "", play["pool"])
				_say("%s: tap a lit target, or anywhere else to put it back." % play["name"])
			else:
				_play_cancel()
		"tile":
			if play["at"] == h:
				await _play_commit(null, h)
			else:
				_play_preview(h, null)
		_:
			_play_cancel()


## Everyone standing within a card's area of a tile.
func _in_area(h: Vector2i, radius: int) -> Array:
	return battle.units.filter(func(u): return not Rules.truthy(u.get("down")) and u.get("pos") is Dictionary and Hex.distance(Battle.tile_of(u), h) <= radius)


## (0.23) A tile-aimed Action's first tap: the tile, and any area it would
## centre there, is lit, and everyone in it is ringed.
func _tile_preview(u: Dictionary, a: Dictionary, h: Vector2i) -> void:
	tile_at = h
	var radius := 0
	for sent in Keywords.sentences(a.get("text", "")):
		for t in Keywords.analyse(sent)["targets"]:
			if Keywords._re("^all (enemies|allies|units) within$").search(t["part"]["kw"]["name"]) != null:
				radius = maxi(radius, int(Rules.num(t["part"]["n"], 0)))
	radius = maxi(radius, Effects.aoe_of(a))
	board.set_blast(h, radius)
	var caught := {}
	for c in _in_area(h, radius):
		caught[c["id"]] = true
	board.mark_units(battle, selected_id, {}, "", caught)
	var why := ""
	if Effects.barricade_of(a) != "" and (battle.unit_at(h) != null or battle.kind_at(h) != ""):
		why = "  A Barricade needs an empty tile, and that one is not."
	_say("%s at %d,%d: tap it again to use it, or another lit tile.%s" % [a["name"], h.x, h.y, why])


## (0.23) Uses a tile-aimed Action on the tile chosen.
func use_on_tile(u: Dictionary, a: Dictionary, h: Vector2i) -> void:
	var mark := _mark()
	battle.use_on_tile(u, a, h)
	aiming = -1
	tile_aim = {}
	tile_at = null
	board.clear_marks()
	board.refresh_units(battle, selected_id)
	_float_all(battle.floats.slice(mark[0]), u["id"])
	var said := _tell(battle.log.slice(mark[1]))
	_show_panel(u)
	_update_bar()
	_say(said)
	await _show_halts()
	if battle.settle():
		show_result()


## The first tap with an area: it is lit, and everyone in it is ringed and named.
func _play_preview(h: Vector2i, target) -> void:
	var radius := int(play["needs"]["radius"])
	play["at"] = h
	board.set_blast(h, radius)
	# (0.14) the whole of the area in view, where an edge of the screen would cut it
	_frame(board.blast.keys().map(func(t): return Board.at(t)), 0.0)
	var caught := {}
	var names := []
	for u in _in_area(h, radius):
		caught[u["id"]] = true
		if target == null or not is_same(u, target):
			names.append(("your " if u["side"] == "ally" else "") + str(u["name"]))
	board.mark_units(battle, "", play["pool"], "", caught)
	var where := ("on %s" % target["name"]) if target != null else "there"
	var takes := ("its area takes in %s%s" % ["also " if target != null else "", _list(names)]) if not names.is_empty() else ("its area takes in nobody else" if target != null else "nobody is in its area")
	_say("%s %s: %s.  Tap %s again to play it, %s, or tap off the floor to put it back." % [play["name"], where, takes,
		target["name"] if target != null else "the tile", "another lit target to move it" if target != null else "another tile to move it"])


## The card is put back: nothing was paid.
func _play_cancel() -> void:
	if play.is_empty():
		return
	var nm: String = play["name"]
	var kind: String = play["kind"]
	play = {}
	if hand_tray.kind == "recover":
		hand_tray.visible = false
	board.clear_marks()
	overlay.clear_tags()
	if battle != null:
		board.mark_units(battle)
	_update_bar()
	_say("%s is back %s. Nothing was spent." % [nm, {"hand": "in your hand", "cons": "with your Consumables", "chip": "in the Bank"}.get(kind, "")])


## The card lands: it is paid for and what it says is carried out, shown as
## it happens. A Troop that arrives is chosen, ready to move and act.
func _play_commit(target, tile) -> void:
	var p := play
	var card = _card_of(p)
	play = {}
	busy = true
	board.clear_marks()
	overlay.clear_tags()
	board.mark_units(battle)
	_update_bar()
	var mark := _mark()
	var done := false
	var arrived = null
	match p["kind"]:
		"hand":
			match p["type"]:
				"troop":
					arrived = battle.play_troop(p["i"], tile, p.get("x"))
					done = arrived != null
				"equipment":
					done = target != null and battle.play_equipment(p["i"], target, p.get("x"))
				_:
					done = battle.play_card(p["i"], target, tile, p["recover"], p.get("x"))
		"cons":
			done = battle.use_consumable(p["i"], target, tile, p["recover"])
		"chip":
			done = battle.spend_chip(p["i"], target, p["recover"])
	if not done:
		busy = false
		_update_bar()
		_say("%s couldn't be played after all. Nothing was spent." % p["name"])
		return
	# (0.12) the card flies to where it goes, and lands
	await _card_flight(p, card, target, tile if tile is Vector2i else (Battle.tile_of(arrived) if arrived != null else null), mark)
	_apply_behaviors()
	board.refresh_units(battle)
	var news := _news(mark)
	var said := _tell(news, 4)
	if news.any(func(e): return e.get("plain", false)):
		said += "  Its plain text wasn't carried out (see the Log)."
	_update_bar()
	_say(said)
	if arrived != null:
		await _follow(Battle.tile_of(arrived))
	elif target != null and target.get("pos") is Dictionary:
		await _follow(Battle.tile_of(target))
	elif tile is Vector2i:
		await _follow(tile)
	await _wait(0.35)
	await _show_halts()
	busy = false
	if battle.settle():
		_update_bar()
		await _wait(0.6)
		show_result()
		return
	if arrived != null and not Rules.truthy(arrived.get("down")):
		select(arrived)
		_say(said + "  It can move and act now.")
	else:
		_say(said)
	_update_bar()


## The Aether button: this turn's Aether, the Chips in the Bank, what's left
## in the Pouch, and the team's Prototypes.
func show_bank() -> void:
	if battle == null or not battle.with_cards or busy:
		return
	_open_dialog(Dialog.new("Aether", "\n".join(bank_lines()), ["OK"], Color("#8aa1f6")), func(_i): _close_dialog())


func bank_lines() -> Array:
	var out := ["This turn: %s. What isn't spent is lost when the next round begins." % UI.show(Battle.aether_label(battle.aether)), ""]
	out.append("The Bank holds %d Chip%s, each generating every round:" % [battle.bank.size(), "" if battle.bank.size() == 1 else "s"])
	var by := {}
	var order := []
	for c in battle.bank:
		var k := "%s (%d %s)" % [c["name"], int(c["value"]), ("D" + str(c["district"])) if Rules.truthy(c.get("district")) else "any"]
		if not by.has(k):
			by[k] = 0
			order.append(k)
		by[k] += 1
	for k in order:
		out.append(("%d \u00d7 " % by[k] if by[k] > 1 else "") + k)
	if battle.bank.is_empty():
		out.append("none yet")
	out.append("")
	out.append("The Pouch has %d Chip%s left; %d %s drawn each round (Player Level %d)." % [battle.pouch.size(), "" if battle.pouch.size() == 1 else "s", battle.player_level, "is" if battle.player_level == 1 else "are", battle.player_level])
	if not battle.protos.is_empty():
		var lead = battle.fx.leader_unit()
		out.append("")
		out.append("Prototypes, through %s: %s." % [lead["name"] if lead != null else "the leader", ", ".join(battle.protos.map(func(p): return str(p["name"])))])
	return out


## The bottom line stays clear of a panel on the right and of the buttons on
## the left (Hand, and Consumables and Chips when the team has any), and sits
## over a tray while one is open.
func _layout_info() -> void:
	var side := (UnitPanel.WIDTH + 80) if log_panel.visible else (UnitPanel.WIDTH if panel.visible else 0.0)
	var cards := battle != null and battle.with_cards
	var tray := hand_tray.visible
	var show := cards and not tray
	hand_btn.visible = show
	cons_btn.visible = show and _has_consumables()
	chips_btn.visible = show and _has_effect_chips()
	piles_btn.visible = show
	var x := 12.0
	for pair in [[hand_btn, HAND_W], [cons_btn, CONS_W], [chips_btn, CHIPS_W]]:
		var b: Button = pair[0]
		if b.visible:
			b.offset_left = x
			b.offset_right = x + pair[1]
			x += pair[1] + 8.0
	_info_right = -(side + 14)
	info.offset_right = _info_right
	info.offset_left = (x + 6.0) if show else 14.0
	info.offset_bottom = -(HandTray.HEIGHT + 4) if tray else 0.0
	info.offset_top = info.offset_bottom - 44
	_layout_more()
	hand_tray.offset_right = -side
	overlay.right_margin = side


## (0.14) The "?" at the end of the bottom line, when the line is cut short.
func _layout_more() -> void:
	if info_more == null:
		return
	var w := Look.body().get_string_size(info.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Look.BODY).x
	var room := get_viewport_rect().size.x + _info_right - info.offset_left
	var cut := info.text.strip_edges() != "" and w > room and info.visible
	info.offset_right = _info_right - (52.0 if cut else 0.0)
	info_more.visible = cut
	info_more.offset_right = info.offset_right + 50.0
	info_more.offset_left = info_more.offset_right - 44.0
	info_more.offset_bottom = info.offset_bottom - 2.0
	info_more.offset_top = info_more.offset_bottom - 40.0


## Leave asks where to: it's easy to hit by mistake in the middle of a fight.
func ask_leave() -> void:
	if battle == null or walking or busy:
		return
	if battle.over:
		show_result()
		return
	if battle.deploy != null:
		_open_dialog(Dialog.new("Leave this fight?", "The Strike Team stays where it is on the map, and the fight starts again from its setup. Nothing from this attempt is kept, and nothing it used is spent.", ["Stay", "Back to the map"], Color("#d6a851")), func(i):
			_close_dialog()
			if i == 1:
				play = {}
				burst = {}
				deselect()
				show_map())
		return
	_open_dialog(Dialog.new("Leave this battle?", "It won't be kept: a battle can't be picked up again later.", ["Stay", "Set up another", "Home"], Color("#d6a851")), func(i):
		_close_dialog()
		if i == 1:
			new_battle()
		elif i == 2:
			leave())


# ---------------------------------------------------------------- the screen
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# (0.11: the game's look: its typeface, and pixel frames on everything)
	Look.install()
	ui.theme = Look.theme()
	layer.add_child(ui)

	overlay = Overlay.new()
	overlay.to_screen = func(p: Vector2) -> Vector2: return get_viewport().get_canvas_transform() * board.to_global(p)
	ui.add_child(overlay)

	# (0.14) the fight's bar: where you are and when, your Aether as gems, the
	# icon buttons, and End turn as the one gold button
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.theme = Look.fight_theme()
	var sb := PixelBox.new()
	sb.bg_color = Color("#171819", 0.94)
	sb.content_margin_left = 14; sb.content_margin_right = 10; sb.content_margin_top = 6; sb.content_margin_bottom = 6
	bar.add_theme_stylebox_override("panel", sb)
	ui.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	bar.add_child(row)
	floor_label = Look.read("", UI.PALE)
	floor_label.clip_text = true
	floor_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	floor_label.custom_minimum_size = Vector2(100, 0)
	floor_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(floor_label)
	wave_label = Look.read("", UI.DIM)
	wave_label.visible = false
	row.add_child(wave_label)
	round_label = Look.title("", UI.GOLD, Look.TITLE)
	row.add_child(round_label)
	aether_btn = _button("", show_bank)
	aether_btn.theme_type_variation = "IconButton"
	# (0.11) with Aether's icon; (0.14) and a gem for each point
	aether_btn.icon = Art.icon("aether")
	aether_btn.expand_icon = true
	aether_btn.add_theme_constant_override("icon_max_width", 32)
	aether_btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	aether_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	aether_btn.visible = false
	aether_gems = AetherGems.new()
	aether_btn.add_child(aether_gems)
	row.add_child(aether_btn)
	# (an icon as the others are: as words and an icon, its icon was squeezed out)
	undo_btn = _icon_button("bar_undo", "Undo", undo_move)
	row.add_child(undo_btn)
	auto_btn = _icon_button("bar_auto", "Auto: off", toggle_auto)
	auto_btn.toggle_mode = true
	row.add_child(auto_btn)
	# (0.12) the speed, and Options
	speed_btn = _icon_button("", "Speed and Options", open_options)
	row.add_child(speed_btn)
	_show_speed()
	log_btn = _icon_button("bar_log", "Log", toggle_log)
	row.add_child(log_btn)
	fit_btn = _icon_button("bar_fit", "Fit", _fit)
	row.add_child(fit_btn)
	new_btn = _icon_button("bar_leave", "Leave", ask_leave)
	row.add_child(new_btn)
	next_btn = _button("End turn", next_round)
	next_btn.theme_type_variation = "MainButton"
	# (0.16) with its icon, the hourglass, beside the words
	next_btn.icon = Art.icon2("act_end")
	next_btn.expand_icon = true
	next_btn.add_theme_constant_override("icon_max_width", 32)
	next_btn.add_theme_constant_override("h_separation", 8)
	next_btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	next_btn.custom_minimum_size.x = 156
	row.add_child(next_btn)
	# the bottom line (0.14): one line, VT323; a long one ends in "…" and a "?" reads the rest
	info = Look.read("")
	info.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	info.offset_top = -44
	info.offset_left = 14
	info.offset_right = -14
	info.clip_text = true
	info.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	info.grow_vertical = Control.GROW_DIRECTION_BEGIN
	info.add_theme_color_override("font_color", PALE)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# (0.11) on a bar of its own, as tall as what it says
	info_back = InfoBack.new(info)
	ui.add_child(info_back)
	ui.add_child(info)
	info_more = _icon_button("", "Read all of it", read_info)
	info_more.text = "?"
	info_more.theme = Look.fight_theme()
	info_more.custom_minimum_size = Vector2(44, 40)
	info_more.anchor_top = 1.0
	info_more.anchor_bottom = 1.0
	info_more.anchor_left = 1.0
	info_more.anchor_right = 1.0
	info_more.visible = false
	ui.add_child(info_more)

	# what has dropped so far, under the top bar
	loot_label = Look.read("", LOOT)
	loot_label.position = Vector2(14, BAR_H + 6)
	loot_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	loot_label.add_theme_constant_override("outline_size", 6)
	loot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loot_label.visible = false
	ui.add_child(loot_label)

	# a Strike Team's fight: Hand, Consumables and Chips along the bottom, the piles over them
	hand_btn = _corner_button("Hand", toggle_hand)
	cons_btn = _corner_button("Consumables", func(): toggle_tray("cons"))
	chips_btn = _corner_button("Chips", func(): toggle_tray("chips"))
	piles_btn = Button.new()
	piles_btn.flat = true
	piles_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	piles_btn.anchor_top = 1.0
	piles_btn.anchor_bottom = 1.0
	piles_btn.offset_left = 10
	piles_btn.offset_right = 10 + 250
	piles_btn.offset_top = -104
	piles_btn.offset_bottom = -68
	piles_btn.add_theme_font_override("font", Look.body())
	piles_btn.add_theme_font_size_override("font_size", Look.BODY)
	piles_btn.add_theme_color_override("font_color", Color("#88a3bc"))
	piles_btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	piles_btn.add_theme_constant_override("outline_size", 6)
	piles_btn.pressed.connect(func(): toggle_tray("discard"))
	piles_btn.visible = false
	ui.add_child(piles_btn)

	# the phase the round is in, across the top of the board
	banner = PanelContainer.new()
	banner.anchor_left = 0.5
	banner.anchor_right = 0.5
	banner.offset_left = -BANNER_W / 2.0
	banner.offset_right = BANNER_W / 2.0
	banner.offset_top = BAR_H + 10
	banner.grow_vertical = Control.GROW_DIRECTION_END
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_theme_stylebox_override("panel", UI.box(Color("#171819", 0.95), UI.GOLD, 2, 8, 18))
	banner.visible = false
	ui.add_child(banner)
	var bcol := VBoxContainer.new()
	bcol.add_theme_constant_override("separation", 2)
	bcol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(bcol)
	banner_title = Look.title("", UI.GOLD, Look.TITLE)
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bcol.add_child(banner_title)
	banner_text = Look.read("", UI.PALE)
	banner_text.clip_text = true
	banner_text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	banner_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bcol.add_child(banner_text)

	hand_tray = HandTray.new()
	hand_tray.visible = false
	hand_tray.closed.connect(_close_tray)
	hand_tray.card_tapped.connect(_on_tray_card)
	ui.add_child(hand_tray)

	panel = UnitPanel.new()
	_dock_right(panel, UnitPanel.WIDTH)
	panel.visible = false
	panel.closed.connect(deselect)
	panel.action_pressed.connect(pick_action)
	panel.hold_pressed.connect(hold_fire)
	panel.behavior_pressed.connect(open_behaviors)
	ui.add_child(panel)

	log_panel = LogPanel.new()
	_dock_right(log_panel, UnitPanel.WIDTH + 80)
	log_panel.visible = false
	log_panel.closed.connect(toggle_log)
	ui.add_child(log_panel)

	setup = SetupScreen.new()
	setup.visible = false
	setup.start_requested.connect(_on_start)
	setup.team_start_requested.connect(_on_team_start)
	setup.pvp_start_requested.connect(func(fi, t1, s1, t2, s2): start_pvp(fi, t1, s1, t2, s2))
	setup.teams_requested.connect(func():
		_teams_for_setup = true
		open_teams())
	setup.look_again_requested.connect(func(): load_export())
	setup.deploy_start_requested.connect(_on_deploy_start)
	# Back on a deployment fight's first step goes to the map, where the fight waits
	setup.closed.connect(func(): show_map() if setup.mode == "deploy" else show_home())
	# the World Map's own screen sits under the setup, which covers it for a deployment's fight
	map_screen = MapScreen.new()
	map_screen.visible = false
	map_screen.closed.connect(show_home)
	map_screen.dock_requested.connect(open_dock)
	map_screen.fit_requested.connect(fit_map)
	map_screen.centre_requested.connect(centre_map)
	map_screen.fight_requested.connect(start_deploy_fight)
	map_view.tile_tapped.connect(map_screen.tap)
	ui.add_child(map_screen)
	ui.add_child(setup)

	teams_screen = TeamsScreen.new()
	teams_screen.visible = false
	teams_screen.closed.connect(func():
		if _teams_for_setup:
			_back_to_setup()
		else:
			show_home())
	ui.add_child(teams_screen)

	forge_screen = ForgeScreen.new()
	forge_screen.visible = false
	forge_screen.closed.connect(show_home)
	forge_screen.changed.connect(reload_cards)
	forge_screen.tool_requested.connect(open_sandbox_tool)
	ui.add_child(forge_screen)

	chassis_screen = ChassisScreen.new()
	chassis_screen.visible = false
	chassis_screen.closed.connect(show_home)
	chassis_screen.changed.connect(reload_cards)
	chassis_screen.tool_requested.connect(open_sandbox_tool)
	ui.add_child(chassis_screen)

	poi_screen = PoiScreen.new()
	poi_screen.visible = false
	poi_screen.closed.connect(show_home)
	poi_screen.changed.connect(reload_cards)
	poi_screen.tool_requested.connect(open_sandbox_tool)
	ui.add_child(poi_screen)

	studio_screen = StudioScreen.new()
	studio_screen.visible = false
	studio_screen.closed.connect(show_home)
	studio_screen.changed.connect(reload_cards)
	studio_screen.tool_requested.connect(open_sandbox_tool)
	ui.add_child(studio_screen)

	saves_screen = SavesScreen.new()
	saves_screen.visible = false
	saves_screen.closed.connect(show_home)
	saves_screen.switched.connect(reload_run)
	ui.add_child(saves_screen)

	dock_screen = DockScreen.new()
	dock_screen.visible = false
	dock_screen.closed.connect(show_home)
	dock_screen.map_requested.connect(show_map)
	dock_screen.deployed.connect(show_map)
	dock_screen.workshop_requested.connect(open_workshop)
	ui.add_child(dock_screen)

	workshop_screen = WorkshopScreen.new()
	workshop_screen.visible = false
	workshop_screen.closed.connect(open_dock)
	ui.add_child(workshop_screen)

	home = HomeScreen.new(VERSION)
	home.world_pressed.connect(open_world)
	home.battle_pressed.connect(func(): open_setup("team"))
	home.quick_pressed.connect(func(): open_setup("quick"))
	home.teams_pressed.connect(open_teams)
	home.sandbox_pressed.connect(open_sandbox)
	home.saves_pressed.connect(open_saves)
	home.pvp_pressed.connect(func(): open_setup("pvp"))
	home.look_again_pressed.connect(func(): load_export())
	home.options_pressed.connect(open_options)
	ui.add_child(home)
	# (0.12) on top of everything: a new screen fades in through it
	handoff = HandoffScreen.new()
	ui.add_child(handoff)
	curtain = ColorRect.new()
	curtain.color = Color(UI.BG, 0.0)
	curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(curtain)


## (0.14) A button that is only an icon; its name is in its tooltip.
func _icon_button(icon_id: String, name: String, fn: Callable) -> Button:
	var b := _button("", fn)
	b.theme_type_variation = "IconButton"
	b.tooltip_text = name
	b.custom_minimum_size = Vector2(56, 52)
	if icon_id != "":
		b.icon = Art.icon2(icon_id)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_constant_override("icon_max_width", 32)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return b


## (0.14) The bottom line, all of it, when it is longer than the line.
func read_info() -> void:
	if info.text.strip_edges() == "":
		return
	_open_dialog(Dialog.new("What's happening", info.text, ["OK"], UI.PALE), func(_i): _close_dialog())


## A button along the bottom edge, placed by _layout_info.
func _corner_button(text: String, fn: Callable) -> Button:
	var b := _button(text, fn)
	b.theme = Look.fight_theme()
	b.anchor_top = 1.0
	b.anchor_bottom = 1.0
	b.offset_top = -64
	b.offset_bottom = -10
	b.visible = false
	ui.add_child(b)
	return b


func _dock_right(c: Control, w: float) -> void:
	c.anchor_left = 1.0
	c.anchor_right = 1.0
	c.anchor_top = 0.0
	c.anchor_bottom = 1.0
	c.offset_left = -w
	c.offset_top = BAR_H


func _button(text: String, fn: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
	b.pressed.connect(fn)
	return b


## Slides the board so a Unit isn't hidden behind the side panel.
func _keep_in_view(u: Dictionary) -> void:
	_frame([Board.at(Battle.tile_of(u))])


## Brings these board points into the part of the screen the side panel
## leaves clear, sliding the board and, if they can't all fit, zooming out.
## side is the panel's width: 0 while a card is being played, when it is shut.
func _frame(points: Array, side := UnitPanel.WIDTH) -> void:
	if points.is_empty():
		return
	var vp := get_viewport_rect().size
	var clear := Rect2(50, BAR_H + 60, vp.x - side - 100, vp.y - BAR_H - 150)
	var xf := get_viewport().get_canvas_transform()
	var inside := true
	for p in points:
		inside = inside and clear.has_point(xf * board.to_global(p))
	if inside:
		return
	var box := Rect2(points[0], Vector2.ZERO)
	for p in points:
		box = box.expand(p)
	var z := camera.zoom.x
	if box.size.x > 0 and box.size.x * z > clear.size.x:
		z = clampf(clear.size.x / box.size.x, ZOOM_MIN, z)
	if box.size.y > 0 and box.size.y * z > clear.size.y:
		z = clampf(clear.size.y / box.size.y, ZOOM_MIN, z)
	if z < camera.zoom.x:
		z = step_below(z)
	# the camera's centre is the screen's centre: put the box's centre at the clear area's centre
	var want := _snap_cam(board.to_global(box.get_center()) - (clear.get_center() - vp / 2.0) / z, z)
	_stop_camera()
	_cam_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_cam_tween.tween_property(camera, "position", want, 0.25)
	_cam_tween.tween_property(camera, "zoom", Vector2(z, z), 0.25)


## A finger on the board, or Fit, takes over from any slide in progress.
func _stop_camera() -> void:
	if _cam_tween != null and _cam_tween.is_valid():
		_cam_tween.kill()
	_cam_tween = null


## Frames the whole floor below the top bar.
func _fit() -> void:
	if map_view != null and map_view.visible:
		if map_screen.visible:
			centre_map(map_screen._pos(), true)
		return
	if board == null or board.floor_data == null:
		return
	_stop_camera()
	var r := board.extent()
	var vp := get_viewport_rect().size
	# below the board: the bottom line, and in a Strike Team's fight the Hand button
	var foot := 84.0 if (battle != null and battle.with_cards) else 48.0
	var room := Vector2(vp.x, vp.y - BAR_H - foot)
	var z := clampf(minf(room.x / maxf(r.size.x, 1.0), room.y / maxf(r.size.y, 1.0)) * 0.92, ZOOM_MIN, ZOOM_MAX)
	z = step_below(z)
	camera.zoom = Vector2(z, z)
	camera.position = _snap_cam(r.get_center() - Vector2(0, (BAR_H - foot) / 2.0 / z), z)


## (0.14) A fight opens at the usual zoom (one art pixel to two screen pixels)
## on your Units, unless the whole floor fits closer than that.
func _start_view() -> void:
	_fit()
	if battle == null or camera.zoom.x >= 1.0:
		return
	var pts: Array = battle.side_units("ally").filter(func(u): return u.get("pos") is Dictionary).map(func(u): return Board.at(Battle.tile_of(u)))
	if pts.is_empty():
		return
	var c := Vector2.ZERO
	for p in pts:
		c += p
	c /= float(pts.size())
	var foot := 84.0 if battle.with_cards else 48.0
	camera.zoom = Vector2.ONE
	# a little below the middle, the field ahead above them; not so low that the hand's tray,
	# opened, would cover them
	camera.position = _snap_cam(c - Vector2(0, (BAR_H - foot) / 2.0 + 40.0), 1.0)


## (0.14) The largest whole step at or below a zoom (a floor too big for the
## smallest keeps the zoom that fits it).
static func step_below(z: float) -> float:
	var best: float = -1.0
	for s in ZOOM_STEPS:
		if s <= z + 0.0001:
			best = s
	return best if best > 0.0 else z


## (0.14) The step nearest a zoom.
static func step_near(z: float) -> float:
	var best: float = ZOOM_STEPS[0]
	for s in ZOOM_STEPS:
		if absf(s - z) < absf(best - z):
			best = s
	return best if z >= ZOOM_STEPS[0] * 0.75 else z


## (0.14) A camera position that puts the board's pixels on the screen's.
static func _snap_cam(p: Vector2, z: float) -> Vector2:
	return (p * z).round() / z if ZOOM_STEPS.has(z) else p


## (0.14) After a pinch, the board's zoom settles on the nearest step, about the same point.
func _settle_zoom(screen_point: Vector2) -> void:
	if not _board_live():
		return
	var want := step_near(camera.zoom.x)
	if is_equal_approx(want, camera.zoom.x):
		camera.position = _snap_cam(camera.position, want)
		return
	var before := _screen_to_world(screen_point)
	var vp := get_viewport_rect().size
	var after_pos := before - (screen_point - vp / 2.0) / want
	_stop_camera()
	_cam_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_cam_tween.tween_property(camera, "zoom", Vector2(want, want), 0.14)
	_cam_tween.tween_property(camera, "position", _snap_cam(after_pos, want), 0.14)


# ---------------------------------------------------------------- touch and mouse
func _screen_to_world(p: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * p


func _zoom_at(factor: float, screen_point: Vector2) -> void:
	var before := _screen_to_world(screen_point)
	var z := clampf(camera.zoom.x * factor, ZOOM_MIN, ZOOM_MAX)
	camera.zoom = Vector2(z, z)
	camera.force_update_scroll()
	var after := _screen_to_world(screen_point)
	camera.position += before - after


## The board takes touches only while it's what the screen is showing.
func _board_live() -> bool:
	return battle != null and not (setup.visible or home.visible or teams_screen.visible or dock_screen.visible or workshop_screen.visible or map_screen.visible) and sheet == null and dialog == null and xdlg == null and beh_sheet == null


## The map takes them while it is what the screen is showing.
func _map_live() -> bool:
	return campaign != null and map_view.visible and map_screen.map_live() and not (setup.visible or home.visible or teams_screen.visible or dock_screen.visible or workshop_screen.visible) and dialog == null


## A tap on the board or the map, at a point of the world.
func _tap_world(p: Vector2) -> void:
	if map_view.visible:
		map_view.tap(map_view.to_local(p))
	else:
		board.tap(board.to_local(p))


func _unhandled_input(e: InputEvent) -> void:
	if not (_board_live() or _map_live()):
		return
	if e is InputEventScreenTouch:
		if e.pressed:
			_stop_camera()
			_touches[e.index] = e.position
			_press[e.index] = {"at": Time.get_ticks_msec(), "start": e.position, "moved": 0.0}
			if _touches.size() == 2:
				_pinch_dist = _two_touch_distance()
		else:
			var pr = _press.get(e.index)
			var was_single := _touches.size() == 1
			var was_pinch := _touches.size() == 2
			var mid := _two_touch_mid() if was_pinch else Vector2.ZERO
			_touches.erase(e.index)
			_press.erase(e.index)
			if was_pinch:
				_settle_zoom(mid)
			if pr != null and was_single and pr["moved"] < TAP_MOVE and Time.get_ticks_msec() - pr["at"] < TAP_TIME:
				_tap_world(_screen_to_world(e.position))
			if _touches.size() == 2:
				_pinch_dist = _two_touch_distance()
		get_viewport().set_input_as_handled()
	elif e is InputEventScreenDrag:
		if _press.has(e.index):
			_press[e.index]["moved"] += e.relative.length()
		var prev: Vector2 = _touches.get(e.index, e.position)
		_touches[e.index] = e.position
		if _touches.size() == 1:
			camera.position -= e.relative / camera.zoom.x
		elif _touches.size() == 2:
			var d := _two_touch_distance()
			var mid := _two_touch_mid()
			if _pinch_dist > 0.0:
				_zoom_at(d / _pinch_dist, mid)
			camera.position -= (e.position - prev) / 2.0 / camera.zoom.x
			_pinch_dist = d
			for i in _press:
				_press[i]["moved"] = TAP_MOVE
		get_viewport().set_input_as_handled()
	elif e is InputEventMouseButton and e.device != InputEvent.DEVICE_ID_EMULATION:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			_wheel(1, e.position)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			_wheel(-1, e.position)
		elif e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_stop_camera()
				_mouse_drag = true; _mouse_start = e.position; _mouse_moved = 0.0
			else:
				_mouse_drag = false
				if _mouse_moved < TAP_MOVE:
					_tap_world(_screen_to_world(e.position))
	elif e is InputEventMouseMotion and e.device != InputEvent.DEVICE_ID_EMULATION and _mouse_drag:
		_mouse_moved += e.relative.length()
		camera.position -= e.relative / camera.zoom.x
	elif e is InputEventMagnifyGesture:
		_zoom_at(e.factor, e.position)


## The wheel: on the board a whole step at a time (0.14); on the map a little.
func _wheel(dir: int, at: Vector2) -> void:
	if not _board_live():
		_zoom_at(1.12 if dir > 0 else 1.0 / 1.12, at)
		return
	var z := camera.zoom.x
	var i := ZOOM_STEPS.find(step_near(z))
	i = clampi(i + dir, 0, ZOOM_STEPS.size() - 1)
	_zoom_at(ZOOM_STEPS[i] / z, at)
	camera.position = _snap_cam(camera.position, camera.zoom.x)


func _two_touch_distance() -> float:
	var v := _touches.values()
	return (v[0] as Vector2).distance_to(v[1]) if v.size() >= 2 else 0.0


func _two_touch_mid() -> Vector2:
	var v := _touches.values()
	return ((v[0] as Vector2) + (v[1] as Vector2)) / 2.0 if v.size() >= 2 else Vector2.ZERO
