## A card, small. (0.14) The whole printed card, as CardFace draws it: its
## District's colour round the edge, its name and cost gems, what kind of card
## it is, its art (or a picture of its kind until it has some), its rules and a
## line of what matters most about it (what it costs, or what a Unit brings). A
## gold badge counts copies; a ribbon across the art says something about it
## here ("Leads", "In team"); a gold strip says some of its text is plain, and
## won't happen.
class_name CardTile
extends Control

const SIZE := Vector2(150, 210)
const ART := Rect2(11, 46, 128, 90)

var card: Dictionary = {}
var art: Texture2D = null
var count := 0                 # copies: shown as a badge when above 0
var mark := ""                 # a ribbon across the art
var mark_colour := UI.CYAN
var plain := false             # some of its text is plain: the game can't carry it out
var chosen := false            # outlined in cyan
var faded := false             # can't be used here just now
var gone := false              # the export no longer has this card
var foot := ""                 # the bottom line
var face_down := false         # (0.19) its back shows: dealt, not yet turned
var _font: Font


func _init(c: Dictionary = {}, picture: Texture2D = null) -> void:
	card = c
	art = picture
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_font = Look.font()
	foot = foot_for(c)


## What a card's bottom line says: a Unit's Leadership or Unit Slots and
## Health; what a Deck card costs; what a Chip is worth.
static func foot_for(c: Dictionary) -> String:
	var st: Dictionary = c["stats"] if c.get("stats") is Dictionary else {}
	match str(c.get("cardType", "")).to_lower():
		"hero":
			return "LDR %d · %d slot%s" % [StrikeTeams.leadership(c), StrikeTeams.action_slots(c), "" if StrikeTeams.action_slots(c) == 1 else "s"]
		"troop":
			var cost := UI.show(Roster.cost_label(Roster.hand_card(c)))
			return ("%s · " % cost if cost != "free" else "") + "HP %s" % str(st.get("hp", "?"))
		"sphere":
			var v := 1 if Rules.truthy(c.get("basic")) else Rules.chip_value(c)
			var d := StrikeTeams.chip_district(c)
			return "%d %s" % [v, ("D" + d) if d != "" and d != "any" else "any"]
		"prototype":
			return "always on"
		"action":
			var es := Roster.entries_of(c)
			var e = es[0].get("energyCost") if not es.is_empty() and es[0] is Dictionary else null
			return ("%s NRG" % str(e)) if Rules.truthy(e) else "carried"
		"enemy", "elite", "miniboss", "boss":
			return "Level %d" % Roster.foe_level(c)
	return UI.show(Roster.cost_label(Roster.hand_card(c)))


func _draw() -> void:
	if face_down:
		draw_back(self, Rect2(Vector2.ZERO, size))
		return
	# (0.14) the card itself, as the Forge prints it, at tile size
	CardFace.paint(self, Rect2(Vector2.ZERO, size), card, art, {"chosen": chosen, "faded": faded, "gone": gone, "count": count,
		"mark": mark, "mark_colour": mark_colour, "plain": plain, "foot": foot})


## (0.19) A card's back, filling a rectangle (at a whole number of its pixels
## when it fits, as a card in the hand does: twice them).
static func draw_back(ci: CanvasItem, r: Rect2) -> void:
	var tex := Art.card_back()
	if tex == null:
		ci.draw_rect(r, Color("#14121d"))
		ci.draw_rect(r, Color("#406977"), false, 2.0)
		return
	ci.draw_texture_rect(tex, r, false)
