## A tray of card tiles over the lower part of the board, opened from one of
## the buttons along the bottom: your hand, your Consumables, the Chips in the
## Bank that carry an effect, or the Discard Pile. A card that can't be used
## now is faded; one with plain text says so. Tap a tile to read the card,
## and to play it; Close, or the same button again, puts the tray away.
class_name HandTray
extends PanelContainer

signal closed
signal card_tapped(index: int)

const HEIGHT := 312.0

var kind := "hand"               # "hand", "cons", "chips", "discard", or "recover" (choosing a Troop's card)
var title: Label
var grid: CardFan                # (0.14) the cards as a fan of whole printed cards
var close_btn: Button
var cards: Array = []            # the hand, as the battle holds it
var refs: Array = []             # what each tile stands for: where it lies in the hand, the Consumables, the Bank or the Discard Pile
var _seen := {}                  # (0.19) name -> how many of it were in the hand when you last looked
var _seen_of = null              # the battle that was


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := UI.box(Color("#171819", 0.94), Look.STEEL_EDGE, 0, 0, 12)
	sb.border_width_top = 2
	add_theme_stylebox_override("panel", sb)
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_top = -HEIGHT
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	col.add_child(head)
	theme = Look.fight_theme()
	title = Look.read("Your hand", UI.PALE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	head.add_child(title)
	close_btn = UI.button("Close", func(): closed.emit(), 120)
	close_btn.custom_minimum_size.y = 48
	head.add_child(close_btn)
	grid = CardFan.new()
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.custom_minimum_size = Vector2(0, CardTile.SIZE.y + CardFan.LIFT)
	grid.empty_text = "Your hand is empty."
	grid.card_tapped.connect(func(i): card_tapped.emit(i))
	col.add_child(grid)


## A card as a tile: the export's own card, with its art, or a stand-in by name.
static func _item(r: Roster, name: String, type: String, extra: Dictionary = {}) -> Dictionary:
	var c = r.card_named(name) if r != null else null
	var it := {"card": c if c != null else {"name": name, "cardType": type}, "art": r.art_for(c) if (r != null and c != null) else null}
	it.merge(extra)
	return it


func _show(k: String, heading: String, items: Array, empty: String) -> void:
	var keep := visible and kind == k
	if k != "hand":
		grid.pile = -1
	kind = k
	visible = true
	title.text = heading
	grid.empty_text = empty
	grid.set_items(items, keep)


## Your hand: each card as its tile, faded if it can't be played now.
func show_hand(b: Battle, r: Roster) -> void:
	cards = b.hand
	refs = range(b.hand.size())
	var items := []
	for h in b.hand:
		var c = r.card_named(str(h["name"])) if r != null else null
		items.append(_item(r, str(h["name"]), str(h.get("type", "")), {"faded": not b.play_state(h)["ok"], "foot": UI.show(Roster.cost_label(h)),
			"plain": h.get("type") != "troop" and Roster.has_plain_text(c)}))
	# (0.19) the Deck beside the fan, and the cards drawn since you last looked dealt from it
	grid.pile = b.deck.size()
	var fresh := new_cards(b)
	_show("hand", "Your hand: %d card%s   ·   Aether this turn: %s   ·   Deck %d   ·   Discard %d" % [b.hand.size(), "" if b.hand.size() == 1 else "s",
		UI.show(Battle.aether_label(b.aether)), b.deck.size(), b.discard.size()], items, "Your hand is empty.")
	grid.deal(fresh)


## (0.19) Which of the hand's cards are new since you last looked at it (the
## last of each name, as many as there are more of it), as their places in the
## hand; and it is looked at now. A new battle starts with none seen. (Counted
## by name, so an Undo that puts the hand back as it was deals nothing.)
func new_cards(b: Battle) -> Array:
	if _seen_of != b:
		_seen_of = b
		_seen = {}
	var now := {}
	for h in b.hand:
		var nm := str(h.get("name", ""))
		now[nm] = int(now.get(nm, 0)) + 1
	var fresh := []
	for nm in now:
		var more := int(now[nm]) - int(_seen.get(nm, 0))
		if more <= 0:
			continue
		for i in range(b.hand.size() - 1, -1, -1):
			if more > 0 and str(b.hand[i].get("name", "")) == nm:
				fresh.append(i)
				more -= 1
	fresh.sort()
	_seen = now
	return fresh


## Your Consumables, one tile for each kind with how many are left; a kind
## used up stays, faded.
func show_consumables(b: Battle, r: Roster) -> void:
	refs = []
	var items := []
	var seen := {}
	var left := 0
	for i in b.consumables.size():
		var item: Dictionary = b.consumables[i]
		var nm := str(item["name"])
		var used: bool = Rules.truthy(item.get("used"))
		if not used:
			left += 1
		if seen.has(nm):
			var at: int = seen[nm]
			if not used:
				items[at]["count"] += 1
				if refs[at] < 0 or Rules.truthy(b.consumables[refs[at]].get("used")):
					refs[at] = i
			continue
		seen[nm] = items.size()
		refs.append(i)
		items.append(_item(r, nm, "consumable", {"count": 0 if used else 1, "foot": "no Aether cost", "plain": Roster.text_has_plain(item.get("text", ""))}))
	for k in items.size():
		var gone: bool = items[k]["count"] == 0
		items[k]["faded"] = gone or not b.consumable_state(refs[k])["ok"]
		if gone:
			items[k]["mark"] = "Used"
			items[k]["mark_colour"] = UI.DIM
	_show("cons", "Consumables: %d to use   ·   each once, at no Aether cost" % left, items, "This team carries no Consumables.")


## The Chips in the Bank that carry an effect: each can be spent for it once
## a round, and still generated its Aether.
func show_chips(b: Battle, r: Roster) -> void:
	refs = []
	var items := []
	var ready := 0
	for i in b.bank.size():
		var c: Dictionary = b.bank[i]
		if b.chip_text(c) == "":
			continue
		var spent: bool = Rules.truthy(c.get("spent"))
		if not spent:
			ready += 1
		refs.append(i)
		var it := _item(r, str(c["name"]), "sphere", {"faded": not b.chip_state(i)["ok"], "plain": Roster.text_has_plain(b.chip_text(c)),
			"foot": "%d %s" % [int(c["value"]), ("D" + str(c["district"])) if Rules.truthy(c.get("district")) else "any"]})
		if spent:
			it["mark"] = "Spent"
			it["mark_colour"] = UI.DIM
		items.append(it)
	_show("chips", "Chips with an effect: %d ready   ·   each is spent for it once a round, and still generates its Aether" % ready, items, "No Chip in the Bank has an effect of its own.")


## The Discard Pile, newest first. (only: just the Troops' cards, to choose
## the one a Recover returns.)
func show_discard(b: Battle, r: Roster, only_troops := false, label := "") -> void:
	refs = []
	var items := []
	for i in range(b.discard.size() - 1, -1, -1):
		var c: Dictionary = b.discard[i]
		if only_troops and c.get("type") != "troop":
			continue
		refs.append(i)
		items.append(_item(r, str(c["name"]), str(c.get("type", "")), {"foot": UI.show(Roster.cost_label(c))}))
	if only_troops:
		_show("recover", "%s: tap the Troop whose card returns to your hand" % label, items, "No Troop's card is in the Discard Pile.")
	else:
		_show("discard", "Discard Pile: %d card%s, newest first   ·   they return to the Deck when the Battle ends" % [b.discard.size(), "" if b.discard.size() == 1 else "s"], items, "The Discard Pile is empty.")
