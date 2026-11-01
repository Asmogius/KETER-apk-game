## Cards laid out as tiles, as many across as fit, scrolled by dragging and
## picked by tapping (a drag never picks). Each item is {card, art} with,
## optionally, count, mark, mark_colour, plain, chosen, faded, gone and foot,
## as a CardTile shows them.
class_name CardGrid
extends TouchList

signal card_tapped(index: int)

const GAP := 10.0

var items: Array = []
var tiles: Array[CardTile] = []
var empty_text := ""
var _columns := 0


func _init() -> void:
	super._init()
	box.add_theme_constant_override("separation", int(GAP))
	row_tapped.connect(_on_row)
	resized.connect(_on_resized)


func columns() -> int:
	return maxi(1, int((size.x + GAP) / (CardTile.SIZE.x + GAP)))


## Shows these cards, keeping the place scrolled to unless told to start over.
## (0.44) The same cards again, in the same order (a copy added, a card
## chosen): the tiles there are kept, and only those that changed are drawn
## again, rather than every tile made anew.
func set_items(list: Array, keep_place := true) -> void:
	if keep_place and _same_cards(list):
		items = list
		for i in items.size():
			_dress(tiles[i], items[i])
		return
	var was := scroll if keep_place else 0.0
	items = list
	clear()
	tiles = []
	_columns = columns()
	if items.is_empty() and empty_text != "":
		add_row(UI.label(empty_text, 18, UI.DIM, true))
	var row: HBoxContainer = null
	for i in items.size():
		if i % _columns == 0:
			row = HBoxContainer.new()
			row.add_theme_constant_override("separation", int(GAP))
			box.add_child(row)
		var it: Dictionary = items[i]
		var t := CardTile.new(it["card"], it.get("art"))
		_dress(t, it)
		row.add_child(t)
		tiles.append(t)
	for r in box.get_children():
		_ignore(r)
	_layout()
	scroll_by(was)


## Whether these are the cards shown now, the same ones in the same order (and laid out as they are).
func _same_cards(list: Array) -> bool:
	if list.size() != items.size() or list.size() != tiles.size() or list.is_empty() or columns() != _columns:
		return false
	for i in list.size():
		if not is_same(list[i]["card"], items[i]["card"]) or not is_instance_valid(tiles[i]):
			return false
	return true


## A tile as its item has it: its copies, ribbon, marks and art; drawn again only if any of it changed.
func _dress(t: CardTile, it: Dictionary) -> void:
	var was := [t.art, t.count, t.mark, t.mark_colour, t.plain, t.chosen, t.faded, t.gone, t.foot]
	t.art = it.get("art")
	t.count = int(it.get("count", 0))
	t.mark = str(it.get("mark", ""))
	t.mark_colour = it["mark_colour"] if it.has("mark_colour") else UI.CYAN
	t.plain = it.get("plain", false)
	t.chosen = it.get("chosen", false)
	t.faded = it.get("faded", false)
	t.gone = it.get("gone", false)
	t.foot = str(it["foot"]) if it.has("foot") else t.base_foot
	if was != [t.art, t.count, t.mark, t.mark_colour, t.plain, t.chosen, t.faded, t.gone, t.foot]:
		t.queue_redraw()


func _on_resized() -> void:
	if not items.is_empty() and columns() != _columns:
		set_items(items)


## The tile a tap on a row landed on, if it landed on one.
func _on_row(r: int, at: Vector2) -> void:
	if items.is_empty():
		return
	var col := int(at.x / (CardTile.SIZE.x + GAP))
	if col < 0 or col >= _columns or at.x - col * (CardTile.SIZE.x + GAP) > CardTile.SIZE.x:
		return
	var i := r * _columns + col
	if i >= 0 and i < items.size():
		card_tapped.emit(i)


## Where a tile is, in the grid's own coordinates (for a test's tap).
func tile_centre(i: int) -> Vector2:
	var t := tiles[i]
	return t.global_position - global_position + t.size / 2.0
