## (0.26) Pass and play: between two players' turns the whole screen is
## covered, so the player taking the phone sees neither the other's hand nor
## their own until they are ready, and then only their own.
class_name HandoffScreen
extends Control

signal ready_pressed

var title: Label
var line: Label
var ready_btn: Button


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	add_child(Backdrop.new("title", 0.0))
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.04, 0.82)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(m)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 24)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(col)
	title = Look.title("", UI.CYAN)
	title.add_theme_font_size_override("font_size", Look.HUGE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	line = Look.read("", UI.PALE, true)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.custom_minimum_size = Vector2(760, 0)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(line)
	ready_btn = Button.new()
	ready_btn.text = "Ready"
	ready_btn.theme_type_variation = "MainButton"
	ready_btn.custom_minimum_size = Vector2(360, 88)
	ready_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ready_btn.add_theme_font_override("font", Look.font())
	ready_btn.add_theme_font_size_override("font_size", Look.HUGE)
	ready_btn.pressed.connect(func():
		visible = false
		ready_pressed.emit())
	col.add_child(ready_btn)


## Covers the screen for a player: whose turn it is, and the round.
func show_for(player: String, round_n: int, first := false) -> void:
	title.text = "%s's turn" % player
	line.text = ("Round %d. " % round_n) + ("%s goes first. " % player if first else "") + "Pass the phone to %s. Tap Ready once only they can see the screen: their hand and Aether are shown, and nobody else's." % player
	visible = true
