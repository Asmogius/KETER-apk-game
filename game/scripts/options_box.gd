## Options (0.12): how fast fights play, whether big hits shake the screen,
## and the sound. From Home, and from the speed button on a fight's bar. Each
## choice is kept at once, and kept between sessions. (0.15) From Home it also
## says the game's version and which export the content came from, and can
## look again for a newer one.
class_name OptionsBox
extends Control

signal closed
signal look_board_requested           # (0.14) the Look board: every piece of the look on one screen
signal look_again_requested           # (0.15) read the export again

var speed_btns := {}           # speed -> Button
var atmos_btns := {}           # (0.18) level -> Button
var shake_btns := {}           # true/false -> Button
var buzz_btns := {}            # (0.33) true/false -> Button
var sound_btns := {}
var close_btn: Button
var look_btn: Button
var again_btn: Button                 # (0.15) Look again (from Home)
var about: Label                      # (0.15) the version, and the export it read
var box: PanelContainer


func _init() -> void:
	Motion.settings()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	box = PanelContainer.new()
	box.add_theme_stylebox_override("panel", UI.box(Color("#171819", 0.98), UI.CYAN, 2, 20, 28))
	centre.add_child(box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	box.add_child(col)
	var t := UI.label("Options", 34, UI.CYAN)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	col.add_child(_row("Speed", "How fast fights play. At Instant nothing moves; the rules are the same at every speed.",
		Motion.SPEEDS.map(func(s): return [s, Motion.SPEED_NAMES[s]]), speed_btns, func(k): Motion.set_speed(k)))
	col.add_child(_row("Atmosphere", "Glows on hazards and pads, flickering lights, and embers, ash and dust over a fight.",
		Atmos.LEVELS.map(func(s): return [s, Atmos.LEVEL_NAMES[s]]), atmos_btns, func(k): Motion.set_atmos(k)))
	col.add_child(_row("Screen shake", "A small shake on a heavy blow, or a Unit brought down.",
		[[true, "On"], [false, "Off"]], shake_btns, func(k): Motion.set_shake(k)))
	col.add_child(_row("Vibration", "On a phone: a buzz when one of yours is hit, or lands a heavy blow.",
		[[true, "On"], [false, "Off"]], buzz_btns, func(k): Motion.set_buzz(k)))
	col.add_child(_row("Sound", "Retro blips for shots, hits, cards and buttons (yours, if the README's .wavs are there).",
		[[true, "On"], [false, "Off"]], sound_btns, func(k): Motion.set_sound(k)))
	about = Look.read("", UI.DIM, true)
	about.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	about.custom_minimum_size = Vector2(640, 0)
	about.visible = false
	col.add_child(about)
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(foot)
	again_btn = UI.button("Look again", func(): look_again_requested.emit(), 200)
	again_btn.visible = false
	foot.add_child(again_btn)
	look_btn = UI.button("Look board", func(): look_board_requested.emit(), 200)
	foot.add_child(look_btn)
	close_btn = UI.button("Close", func(): closed.emit(), 180)
	foot.add_child(close_btn)
	_show()


func _row(title: String, under: String, choices: Array, into: Dictionary, pick: Callable) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	var l := UI.label(title, 22, UI.TEXT)
	l.custom_minimum_size = Vector2(200, 0)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	for c in choices:
		var key = c[0]
		var b := Button.new()
		b.text = str(c[1])
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(140, 56)
		b.pressed.connect(func():
			pick.call(key)
			_show())
		h.add_child(b)
		into[key] = b
	var u := UI.label(under, 15, UI.DIM, true)
	u.custom_minimum_size = Vector2(640, 0)
	v.add_child(u)
	return v


## (0.15) From Home: the game's version and the export it read, and Look again.
func show_about(version: String, source: String) -> void:
	about.text = "KETER · the game · version %s" % version + ("\n" + source if source != "" else "")
	about.visible = true
	again_btn.visible = true


## Each row lit at what is chosen now.
func _show() -> void:
	for k in speed_btns:
		speed_btns[k].set_pressed_no_signal(k == Motion.speed)
	for k in atmos_btns:
		atmos_btns[k].set_pressed_no_signal(k == Motion.atmos)
	for k in shake_btns:
		shake_btns[k].set_pressed_no_signal(k == Motion.shake)
	for k in sound_btns:
		sound_btns[k].set_pressed_no_signal(k == Motion.sound)
	for k in buzz_btns:
		buzz_btns[k].set_pressed_no_signal(k == Motion.buzz)


func _ready() -> void:
	Motion.pop_in(box)
