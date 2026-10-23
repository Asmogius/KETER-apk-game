## Cards held as a fan (0.14): the whole printed cards side by side along the
## bottom of the screen, overlapping when there are more than fit, each a
## little of the next showing. Tap one to read it (and play it); the one
## tapped stands up out of the fan. It takes the place a CardGrid had in the
## hand's tray, and answers the same: items, tiles, set_items, tile_centre.
## (0.19) Your hand's fan has the Deck beside it, face down, and the cards
## drawn since you last looked are dealt from it one by one, turning face up
## as they land.
class_name CardFan
extends Control

signal card_tapped(index: int)

const GAP := 10.0
const LIFT := 18.0

var items: Array = []
var tiles: Array[CardTile] = []
var empty_text := ""
var lifted := -1
var _empty: Label = null
var _press := Vector2(-1, -1)
var pile := -1                   # (0.19) the cards left in the Deck, shown beside the fan; -1: no Deck shown
var dealing := 0                 # cards still on their way from the Deck
var dealt: Array = []            # which tiles were dealt last (for the tests)
const PILE_GAP := 22.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false
	resized.connect(_layout)


## Shows these cards (keep_place: as CardGrid's, for the same calls).
func set_items(list: Array, _keep_place := true) -> void:
	items = list
	for t in tiles:
		t.queue_free()
	tiles = []
	if _empty != null:
		_empty.queue_free()
		_empty = null
	if items.is_empty() and empty_text != "":
		_empty = Look.read(empty_text, UI.DIM, true)
		_empty.position = Vector2(16, 12)
		_empty.size = Vector2(maxf(200.0, size.x - 32.0), 60)
		add_child(_empty)
	for i in items.size():
		var it: Dictionary = items[i]
		var t := CardTile.new(it["card"], it.get("art"))
		t.count = int(it.get("count", 0))
		t.mark = str(it.get("mark", ""))
		if it.has("mark_colour"):
			t.mark_colour = it["mark_colour"]
		t.plain = it.get("plain", false)
		t.chosen = it.get("chosen", false)
		t.faded = it.get("faded", false)
		t.gone = it.get("gone", false)
		if it.has("foot"):
			t.foot = str(it["foot"])
		add_child(t)
		tiles.append(t)
	if lifted >= tiles.size():
		lifted = -1
	dealing = 0
	_layout()
	queue_redraw()


## How far apart the cards sit: a full card and a gap each when they fit, closer when not.
func step() -> float:
	var n := tiles.size()
	if n <= 1:
		return CardTile.SIZE.x + GAP
	var room := maxf(CardTile.SIZE.x, size.x - 16.0 - _pile_room())
	return minf(CardTile.SIZE.x + GAP, (room - CardTile.SIZE.x) / float(n - 1))


## Where a tile lies in the fan, as it is laid out now.
func slot(i: int) -> Vector2:
	var s := step()
	var n := tiles.size()
	var total := CardTile.SIZE.x + s * maxi(0, n - 1)
	var x0 := maxf(8.0 + _pile_room(), (size.x - total) / 2.0)
	return Vector2(round(x0 + i * s), LIFT - (LIFT if i == lifted else 0.0))


func _layout() -> void:
	for i in tiles.size():
		if not tiles[i].has_meta("dealing"):         # (0.19) one on its way from the Deck goes on its way
			tiles[i].position = slot(i)


## (0.19) The room the Deck takes at the fan's left, when it is shown.
func _pile_room() -> float:
	return CardTile.SIZE.x + PILE_GAP if pile >= 0 else 0.0


## Where the Deck sits: its top card's corner.
func pile_at() -> Vector2:
	return Vector2(8.0, CardFan.LIFT)


func _draw() -> void:
	if pile < 0:
		return
	var at := pile_at()
	if pile == 0:
		# an empty place where the Deck was
		draw_rect(Rect2(at, CardTile.SIZE), Color("#406977", 0.5), false, 2.0)
	else:
		# a stack: a card or two showing under the top one, by how many are left
		for k in range(mini(2, pile - 1), -1, -1):
			CardTile.draw_back(self, Rect2(at + Vector2(k * 3, -k * 3), CardTile.SIZE))
	var label := "Deck %d" % pile
	var f := Look.font()
	var w := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, Look.SMALL).x
	var plate := Rect2(at + Vector2((CardTile.SIZE.x - w) / 2.0 - 8.0, CardTile.SIZE.y - 30.0), Vector2(w + 16.0, 24.0))
	draw_rect(plate, Color("#0e0c0c", 0.9))
	draw_rect(plate, Color("#406977"), false, 2.0)
	draw_string(f, plate.position + Vector2(8, 18), label, HORIZONTAL_ALIGNMENT_LEFT, -1, Look.SMALL, Color("#73efe8"))


## (0.19) Deals these tiles from the Deck: each starts on the Deck face down,
## slides to its place, and turns face up as it lands, one after another.
func deal(which: Array) -> void:
	dealt = which.duplicate()
	if which.is_empty() or not Motion.moving():
		return
	var k := Motion.k()
	var j := 0
	for i in which:
		if i < 0 or i >= tiles.size():
			continue
		var t := tiles[i]
		var idx: int = i
		t.position = pile_at()
		t.set_meta("dealing", true)
		t.face_down = true
		t.pivot_offset = CardTile.SIZE / 2.0
		t.queue_redraw()
		dealing += 1
		var tw := t.create_tween()
		tw.tween_interval(j * 0.12 * k)
		tw.tween_callback(func(): Sound.play("card") if j == 0 else null)
		# to its place in the fan as the fan lies when it arrives (the fan may still be finding its size)
		tw.tween_method(func(v: float): t.position = pile_at().lerp(slot(idx), v), 0.0, 1.0, 0.24 * k).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(t, "scale:x", 0.0, 0.07 * k)
		tw.tween_callback(func():
			t.face_down = false
			t.queue_redraw())
		tw.tween_property(t, "scale:x", 1.0, 0.07 * k)
		tw.tween_callback(func():
			dealing -= 1
			t.remove_meta("dealing")
			t.position = slot(idx))
		j += 1


## Where a tile can be tapped (the part of it no later card covers), in the fan's own coordinates.
func tile_centre(i: int) -> Vector2:
	var t := tiles[i]
	var w := CardTile.SIZE.x if i == tiles.size() - 1 else minf(CardTile.SIZE.x, step())
	return t.position + Vector2(w / 2.0, CardTile.SIZE.y / 2.0)


## The card on top at a point, or -1.
func tile_at(p: Vector2) -> int:
	for i in range(tiles.size() - 1, -1, -1):
		if Rect2(tiles[i].position, CardTile.SIZE).has_point(p):
			return i
	return -1


## A tap at a point (as a TouchList's): the card on top there is read.
func tap(p: Vector2) -> void:
	var i := tile_at(p)
	if i >= 0:
		lift(i)
		card_tapped.emit(i)


func lift(i: int) -> void:
	lifted = i
	_layout()


func _gui_input(e: InputEvent) -> void:
	var down := false
	var up := false
	var at := Vector2.ZERO
	if e is InputEventScreenTouch:
		down = e.pressed
		up = not e.pressed
		at = e.position
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.device != InputEvent.DEVICE_ID_EMULATION:
		down = e.pressed
		up = not e.pressed
		at = e.position
	else:
		return
	if down:
		_press = at
	elif up and _press.x >= 0.0:
		var moved := at.distance_to(_press)
		_press = Vector2(-1, -1)
		if moved <= 14.0:
			var i := tile_at(at)
			if i >= 0:
				lift(i)
				card_tapped.emit(i)
	accept_event()
