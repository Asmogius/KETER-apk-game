## (0.43) A choice of cards, shown as the cards themselves: each printed large,
## as a card's sheet prints it (three across fit the screen), a button under
## each to take it, and a tap on a card to read all it says on its sheet,
## which can take it too.
## It is a Dialog still: its buttons are the choices, in order, and chosen says
## which was taken. The pick of a rare card to begin a run with is one.
class_name CardChoice
extends Dialog

## How large each card is printed: the sheet's size, for up to three; more, as tiles at twice their pixels.
static func size_for(n: int) -> Vector2:
	return CardFace.LARGE if n <= 3 else CardTile.SIZE * 2.0

var cards: Array = []                  # the cards on offer, in order
var names: Array = []                  # their names
var tiles: Array = []                  # the printed face of each (a CardFace.Face, or a CardTile)
var holders: Array = []                # what a tap on each lands on
var sheet: CardSheet = null            # the card being read, or null
var _arts: Array = []
var _take := "Take"


## list: the cards; arts: each one's art (or null); take: what each button says.
func _init(title: String, text: String, list: Array, arts: Array = [], take := "Take", accent := Color("#d6a851")) -> void:
	var labels := []
	for _c in list:
		labels.append(take)
	super(title, text, labels, accent)
	cards = list
	_arts = arts
	_take = take
	names = list.map(func(c): return str(c.get("name", "")) if c is Dictionary else "")
	text_label.custom_minimum_size = Vector2(1000, 0)
	Look.size_to(text_label, 17)
	text_label.get_parent().add_theme_constant_override("separation", 10)
	var at := size_for(list.size())
	# the row of buttons becomes a row of cards, each with its button under it
	var row: HBoxContainer = buttons[0].get_parent() if not buttons.is_empty() else null
	if row == null:
		return
	row.add_theme_constant_override("separation", 28)
	for i in buttons.size():
		var b: Button = buttons[i]
		row.remove_child(b)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 10)
		row.add_child(col)
		var holder := Button.new()
		holder.flat = true
		holder.focus_mode = Control.FOCUS_NONE
		holder.custom_minimum_size = at
		holder.tooltip_text = "Read %s in full" % names[i]
		var k := i
		holder.pressed.connect(func(): read(k))
		col.add_child(holder)
		var c: Dictionary = cards[i] if cards[i] is Dictionary else {}
		var art: Texture2D = arts[i] if i < arts.size() else null
		var tile: Control
		if at == CardFace.LARGE:
			tile = CardFace.Face.new(c, art)
		else:
			tile = CardTile.new(c, art)
			tile.scale = at / CardTile.SIZE
		holder.add_child(tile)
		tiles.append(tile)
		holders.append(holder)
		b.custom_minimum_size = Vector2(at.x, 54)
		col.add_child(b)


## Reads one of the cards in full, on its sheet; it can be taken from there.
func read(i: int) -> void:
	if i < 0 or i >= cards.size() or sheet != null or not (cards[i] is Dictionary):
		return
	sheet = CardSheet.new(cards[i], _arts[i] if i < _arts.size() else null, {"buttons": [["take", "%s this one" % _take]]})
	sheet.chosen.connect(func(id):
		_close_sheet()
		if id == "take":
			chosen.emit(i))
	add_child(sheet)


func _close_sheet() -> void:
	if sheet != null:
		Motion.pop_out(sheet, sheet.get_meta("box", null))
		sheet = null
