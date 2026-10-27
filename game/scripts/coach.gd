## (0.39) The first deployment fight, explained: QM-7's field guide, a few
## short pages beside the board, read at your own pace. Next turns the page;
## Skip puts it away. Once read or skipped it isn't shown again (Options keeps
## that it was).
class_name Coach
extends PanelContainer

signal finished

const PAGES := [
	["Your Heroes", "They stand on the blue pads. Tap one to see where it can go and what it can do; tap a lit tile to move it, then an Enemy to attack."],
	["Aether", "The gems at the top are this turn's Aether. Your Heroes make some each round, and so do the Chips in your Bank. Cards are paid with it."],
	["Your hand", "Your cards, along the bottom. Tap one to read it and Play it: a Troop joins the fight, Command and Aether cards do what they say, Equipment goes on a Unit."],
	["Waves", "Enemies arrive in waves on the red pads. The next comes when the board is clear, or when the timer at the top runs out. Beat the last wave to win."],
	["End turn", "When you're done, End turn: the Enemies act, then a new round begins. Auto plays your Units' turns for you, if you'd rather watch."],
]

var page := 0
var title: Label
var text: Label
var count: Label
var next_btn: Button
var skip_btn: Button


func _init() -> void:
	custom_minimum_size = Vector2(430, 0)
	add_theme_stylebox_override("panel", UI.box(Color("#171819", 0.96), UI.GOLD, 2, 8, 14))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	title = UI.label("", 20, UI.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	count = UI.label("", 15, UI.DIM)
	head.add_child(count)
	text = UI.label("", 16, UI.TEXT, true)
	text.custom_minimum_size = Vector2(400, 0)
	v.add_child(text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	skip_btn = UI.button("Skip", func(): finish(), 110)
	row.add_child(skip_btn)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gap)
	next_btn = UI.button("Next ›", func(): turn(), 140)
	row.add_child(next_btn)
	show_page(0)


func show_page(i: int) -> void:
	page = clampi(i, 0, PAGES.size() - 1)
	title.text = "QM-7's field guide · " + str(PAGES[page][0])
	count.text = "%d of %d" % [page + 1, PAGES.size()]
	text.text = str(PAGES[page][1])
	next_btn.text = "Got it" if page == PAGES.size() - 1 else "Next ›"


func turn() -> void:
	if page >= PAGES.size() - 1:
		finish()
	else:
		show_page(page + 1)


func finish() -> void:
	Motion.set_coached(true)
	finished.emit()
