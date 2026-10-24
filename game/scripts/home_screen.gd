## Where the game opens (0.15): the colony's sign over the night, and one
## thing to do next, gold: Play, which goes to the dock (Continue, straight to
## the World Map, while a Strike Team is out). Practice beneath it opens its
## two fights to pick from (a Battle with a Strike Team, a Quick battle with
## anyone at all), beside Strike Teams. Options is the gear in the corner: the
## version, the export the content came from, and Look again are in there
## (Look again is on Home too while there is no export to play with).
## (0.26) Sandbox, beside Strike Teams, opens the game's own tools for making
## content: the Card Forge first. Pass and play sets up a match between two
## players on one phone.
## (0.32) The save file being played is named in the top left corner; a tap
## opens the three save files.
class_name HomeScreen
extends Control

signal world_pressed
signal battle_pressed
signal quick_pressed
signal teams_pressed
signal look_again_pressed
signal options_pressed
signal sandbox_pressed
signal pvp_pressed
signal saves_pressed

var title: Label               # (0.15) the sign in the picture is the game's name: this stays hidden
var note: Label
var source: Label              # which export the content came from (shown in Options)
var world_btn: Button          # Play, or Continue
var world_sub: Label           # what it does
var practice_btn: Button       # (0.15) opens the two practice fights
var practice_row: HBoxContainer
var battle_btn: Button
var quick_btn: Button
var teams_btn: Button
var sandbox_btn: Button
var pvp_btn: Button
var again_btn: Button
var options_btn: Button
var save_btn: Button           # (0.32) the save file being played: a tap opens the three
var version := ""


func _init(ver: String) -> void:
	version = ver
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(Backdrop.new("title", 0.0))
	title = UI.label("KETER", 72, UI.CYAN)
	title.visible = false
	add_child(title)
	# the column under the sign
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_top", 312)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(m)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_BEGIN
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(col)
	world_btn = Button.new()
	world_btn.text = "Play"
	world_btn.theme_type_variation = "MainButton"
	world_btn.custom_minimum_size = Vector2(420, 88)
	world_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	world_btn.add_theme_font_override("font", Look.font())
	world_btn.add_theme_font_size_override("font_size", Look.HUGE)
	world_btn.pressed.connect(func(): world_pressed.emit())
	col.add_child(world_btn)
	world_sub = Look.read("Deploy a Strike Team, explore, and come home", UI.PALE)
	world_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(world_sub)
	note = Look.read("", UI.GOLD, true)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.custom_minimum_size = Vector2(900, 0)
	note.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(note)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	col.add_child(row)
	practice_btn = _steel("Practice", func(): show_practice(not practice_row.visible))
	practice_btn.toggle_mode = true
	row.add_child(practice_btn)
	teams_btn = _steel("Strike Teams", func(): teams_pressed.emit())
	row.add_child(teams_btn)
	sandbox_btn = _steel("Sandbox", func(): sandbox_pressed.emit())
	row.add_child(sandbox_btn)
	pvp_btn = _steel("Pass and play", func(): pvp_pressed.emit())
	row.add_child(pvp_btn)
	# Practice's two fights, under it once it is pressed
	practice_row = HBoxContainer.new()
	practice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	practice_row.add_theme_constant_override("separation", 20)
	practice_row.visible = false
	col.add_child(practice_row)
	battle_btn = _big("Battle", "A Strike Team, six waves,\na hand of cards", func(): battle_pressed.emit())
	practice_row.add_child(battle_btn)
	quick_btn = _big("Quick battle", "Any Heroes and Troops,\none wave, no Deck", func(): quick_pressed.emit())
	practice_row.add_child(quick_btn)
	# with no export yet: Look again, here, and which export it was
	again_btn = UI.button("Look again", func(): look_again_pressed.emit(), 200)
	again_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(again_btn)
	source = Look.read("", UI.DIM)
	source.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	source.visible = false
	col.add_child(source)
	# Options: the gear in the corner
	options_btn = Button.new()
	options_btn.theme_type_variation = "IconButton"
	options_btn.icon = Art.icon("gear")
	options_btn.expand_icon = true
	options_btn.add_theme_constant_override("icon_max_width", 32)
	options_btn.tooltip_text = "Options"
	options_btn.custom_minimum_size = Vector2(64, 64)
	options_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	options_btn.position = Vector2(-84, 18)
	options_btn.offset_left = -84
	options_btn.offset_right = -20
	options_btn.offset_top = 18
	options_btn.offset_bottom = 82
	options_btn.pressed.connect(func(): options_pressed.emit())
	add_child(options_btn)
	# (0.32) the save file, in the other corner
	save_btn = Button.new()
	save_btn.text = "Save 1"
	save_btn.tooltip_text = "Save files"
	save_btn.add_theme_font_override("font", Look.font())
	save_btn.add_theme_font_size_override("font_size", Look.SMALL + 3)
	save_btn.custom_minimum_size = Vector2(200, 64)
	save_btn.position = Vector2(20, 18)
	save_btn.pressed.connect(func(): saves_pressed.emit())
	add_child(save_btn)


## (0.32) Which save file is played.
func show_save(name: String) -> void:
	save_btn.text = name + "  (switch)"


func _steel(text: String, fn: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(220, 64)
	b.add_theme_font_override("font", Look.font())
	b.add_theme_font_size_override("font_size", Look.TITLE)
	b.pressed.connect(fn)
	return b


func _big(text: String, under: String, fn: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(300, 112)
	b.pressed.connect(fn)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var t := Look.title(text, UI.TEXT)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(t)
	var u := Look.read(under, UI.DIM)
	u.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	u.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(u)
	return b


## (0.15) Practice's two fights shown under it, or put away.
func show_practice(on: bool) -> void:
	practice_row.visible = on
	practice_btn.set_pressed_no_signal(on)


## With content: what there is to fight with. Without: why not, and what to do.
func show_state(ready: bool, message: String, from: String, teams: int, world_line := "", out := false) -> void:
	world_btn.disabled = not ready
	world_btn.text = "Continue" if out else "Play"
	world_sub.text = "A Strike Team is out: carry on where it stands" if out else "Deploy a Strike Team, explore, and come home"
	practice_btn.disabled = not ready
	battle_btn.disabled = not ready
	quick_btn.disabled = not ready
	teams_btn.disabled = not ready
	sandbox_btn.disabled = not ready
	pvp_btn.disabled = not ready
	again_btn.visible = not ready
	source.text = from
	source.visible = not ready and from != ""
	show_practice(false)
	if not ready:
		note.text = message
	elif teams == 0:
		note.text = "No Strike Teams yet. Build one to deploy or to fight a full Battle, or try a Quick battle under Practice."
	else:
		note.text = message if message != "" else world_line
