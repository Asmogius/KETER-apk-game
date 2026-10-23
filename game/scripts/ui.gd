## What the screens share: the colours, the names card types go by, and a few
## ready-made pieces (a button a thumb can hit, a panel, a line of text).
class_name UI
extends RefCounted

## (0.11: every colour is one of the Pixel Studio's: AAP-Splendor128, the
## neons and KETER's own, so the frames sit with the art)
const BG := Color("#0e0c0c")
const PANEL := Color("#171819")
const PANEL_LIT := Color("#282c3c")
const LINE := Color("#2c3b39")
const EDGE_HI := Color("#406977")
const BUTTON := Color("#2c3438")
const TEXT := Color("#e6e7f0")
const PALE := Color("#c5c7dd")
const DIM := Color("#88a3bc")
const CYAN := Color("#73efe8")
const GOLD := Color("#d6a851")
const RED := Color("#ff2a3c")
const SOFT_RED := Color("#dd8877")
const GREEN := Color("#59cf93")
const LOOT := Color("#efdd91")
const AETHER := Color("#8aa1f6")

## What each kind of card is called, and its colour on a tile.
const TYPE_NAME := {"hero": "Hero", "troop": "Troop", "equipment": "Equipment", "command": "Command", "aether": "Aether", "action": "Action",
	"sphere": "Aether Chip", "prototype": "Prototype", "consumable": "Consumable", "enemy": "Enemy", "elite": "Elite", "miniboss": "Mini-Boss", "boss": "Boss"}
const TYPE_COLOUR := {"hero": "#73efe8", "troop": "#59cf93", "equipment": "#d6a851", "command": "#9c8bdb", "aether": "#8aa1f6", "action": "#fca570",
	"sphere": "#efdd91", "prototype": "#d480bb", "consumable": "#8ac4c3", "enemy": "#ff2a3c", "elite": "#ff2a3c", "miniboss": "#ff2a3c", "boss": "#ff2a3c"}


static func type_name(c: Dictionary) -> String:
	return TYPE_NAME.get(str(c.get("cardType", "")).to_lower(), str(c.get("cardType", "Card")).capitalize())


static func type_colour(c: Dictionary) -> Color:
	return Color(TYPE_COLOUR.get(str(c.get("cardType", "")).to_lower(), "#88a3bc"))


## Text as the screen can show it. The Companion writes generic Aether with a
## diamond the game's font may not have; here it reads "any".
static func show(t: String) -> String:
	return t.replace("◇", " any")


static func button(text: String, fn: Callable, min_width := 150.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 60)
	b.pressed.connect(fn)
	return b


static func label(text: String, size := 18, colour := TEXT, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", Look.fs(size))
	l.add_theme_color_override("font_color", colour)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## A framed panel (0.11: in pixels, its corners cut; see PixelBox).
static func box(bg := PANEL, border := LINE, width := 1, radius := 6, margin := 12) -> PixelBox:
	var sb := PixelBox.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = margin
	sb.content_margin_right = margin
	sb.content_margin_top = margin * 0.6
	sb.content_margin_bottom = margin * 0.6
	return sb


## Which part of a row a tap fell on: the deepest Control under it carrying
## an "act" meta, as that meta; null for none. at: in the row's own
## coordinates. (A TouchList row takes no touches itself; this is how its
## buttons are told apart.)
static func act_at(row: Control, at: Vector2) -> Variant:
	var found = null
	var origin := row.get_global_rect().position
	var stack: Array = [row]
	while not stack.is_empty():
		var c = stack.pop_front()
		if c is Control and c.is_visible_in_tree() and c.has_meta("act"):
			if Rect2(c.get_global_rect().position - origin, c.size).has_point(at):
				found = c.get_meta("act")
		for k in c.get_children():
			stack.append(k)
	return found


## A pill a thumb can tap, inside a row: its text, its colour, and what a tap on it means.
static func chip(text: String, colour: Color, act, on := false, size := 17) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := PixelBox.new()
	sb.bg_color = PANEL_LIT if on else BUTTON.darkened(0.25)
	sb.border_color = colour if on else colour.darkened(0.45)
	sb.set_border_width_all(2 if on else 1)
	sb.set_corner_radius_all(4)
	sb.shadow = true
	sb.content_margin_left = 16; sb.content_margin_right = 16; sb.content_margin_top = 10; sb.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(label(text, size, colour))
	if act != null:
		p.set_meta("act", act)
	return p


## A full-screen page: a backdrop (0.11: "menu", "dock" or "title"), a
## margin, and a column to fill.
static func page(host: Control, backdrop := "menu", dim := 0.66) -> VBoxContainer:
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(Backdrop.new(backdrop, dim))
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 22 if side != "top" else 14)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(m)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(col)
	return col


## An icon in pixels, at twice its size (or as big as asked), with a number or
## a few words beside it: the way the game shows an amount.
static func stat(icon_id: String, text: String, colour := TEXT, size := 18, px := 32) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(icon(icon_id, px))
	var l := label(text, size, colour)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(l)
	h.set_meta("icon", icon_id)
	return h


static func icon(icon_id: String, px := 32) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Art.icon(icon_id)
	t.custom_minimum_size = Vector2(px, px)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.set_meta("icon", icon_id)
	return t


## A row of amounts, each an icon and its number: [[icon, text, colour], ...].
static func stats_row(items: Array, size := 18) -> HFlowContainer:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 18)
	f.add_theme_constant_override("v_separation", 6)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for it in items:
		f.add_child(stat(str(it[0]), str(it[1]), it[2] if it.size() > 2 else TEXT, size))
	return f


## A bag's amounts for a row of icons: its shards, then each part type's count.
static func bag_items(bag) -> Array:
	var b := Loot.norm(bag)
	var out := [["shards", str(b["shards"]), LOOT]]
	for ty in Loot.TYPES:
		var n := 0
		for r in 6:
			n += int(b["parts"][ty["id"]][r])
		if n > 0:
			out.append(["part_" + str(ty["id"]), str(n), TEXT])
	return out


## (0.15) A picture of pixels at a whole multiple of its size, as near px as
## that allows (or shrunk to fit, if it is bigger).
static func pixels(tex: Texture2D, px := 48) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if tex != null:
		var big := maxf(1.0, maxf(tex.get_width(), tex.get_height()))
		var k := floorf(px / big) if big <= px else px / big
		t.custom_minimum_size = (tex.get_size() * k).floor()
	else:
		t.custom_minimum_size = Vector2(px, px)
	return t


## (0.15) A Strike Team's Heroes, side by side as they stand: their tokens, in
## room for three, so the names beside them line up.
static func team_tokens(names: Array, roster: Roster, px := 48) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 2)
	h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.custom_minimum_size = Vector2(px * 3 + 4, px)
	for n in names.slice(0, 3):
		var c = roster.card_named(str(n)) if roster != null else null
		var tex: Texture2D = roster.token_for(c).get("texture") if c != null else null
		if tex == null:
			continue
		var slot := CenterContainer.new()
		slot.custom_minimum_size = Vector2(px, px)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tr := pixels(tex, px)
		tr.set_meta("hero", str(n))
		slot.add_child(tr)
		h.add_child(slot)
	return h


## (0.15) A few words in a frame of their colour: a row's state (Ready, Leads, 2 to fix).
static func tag(text: String, colour: Color, size := 16) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(BG, colour.darkened(0.25), 1, 2, 8))
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := label(text, size, colour)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return p

