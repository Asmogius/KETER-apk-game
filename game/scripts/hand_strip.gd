## (0.39) Your hand, always in sight: a strip of small cards along the bottom
## of a Strike Team's fight, each faded if it can't be played now. Tap one to
## read it in full, and Play it, as from the Hand tray.
class_name HandStrip
extends Control

signal tapped(index: int)

const SCALE := 0.5
const MINI := Vector2(75, 105)
const GAP := 6.0
const MOST := 12               # more than this, and the rest are counted

var _tiles: Array = []         # [holder, hand index]


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The hand as it stands.
func show_hand(b: Battle, r: Roster) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_tiles = []
	if b == null:
		return
	var x := 0.0
	for i in mini(b.hand.size(), MOST):
		var h: Dictionary = b.hand[i]
		var c = r.card_named(str(h["name"])) if r != null else null
		var holder := Control.new()
		holder.custom_minimum_size = MINI
		holder.size = MINI
		holder.position = Vector2(x, 0)
		holder.mouse_filter = Control.MOUSE_FILTER_STOP
		holder.tooltip_text = str(h["name"])
		var tile := CardTile.new(c if c != null else {"name": str(h["name"]), "cardType": str(h.get("type", ""))}, r.art_for(c) if (r != null and c != null) else null)
		tile.scale = Vector2(SCALE, SCALE)
		tile.faded = not b.play_state(h)["ok"]
		tile.foot = UI.show(Roster.cost_label(h))
		holder.add_child(tile)
		var at := i
		holder.gui_input.connect(func(e):
			if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or (e is InputEventScreenTouch and e.pressed):
				tapped.emit(at))
		add_child(holder)
		_tiles.append([holder, i])
		x += MINI.x + GAP
	if b.hand.size() > MOST:
		var more := UI.label("+%d" % (b.hand.size() - MOST), 18, UI.PALE)
		more.position = Vector2(x, MINI.y / 2.0 - 12)
		add_child(more)
		x += 40
	custom_minimum_size = Vector2(x, MINI.y)
	size = custom_minimum_size


## How many cards it shows.
func count() -> int:
	return _tiles.size()
