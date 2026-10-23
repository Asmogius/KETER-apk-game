## The game's look (0.11): its typeface, the sizes text comes in, and the
## theme every screen wears (pixel frames on panels, buttons and boxes).
##
## The typeface is Jersey 10 (fonts/, under the SIL Open Font License), drawn
## on a pixel grid. Its capitals sit lower in the em than the old face's, so a
## size written for the old face is a third larger in this one: Look.fs(18) is
## 24, and reads the same height. It has every character the game writes (the
## fonts test says so); it has no second face behind it, because a taller one
## there would space every line out to its own height.
class_name Look
extends RefCounted

const FONT_PATH := "res://fonts/Jersey10-Regular.ttf"
## (0.14) The body face: VT323, for everything you read in a fight and on a
## card. Its pixels land on the screen's only at 25 (2 to each) and 50.
const BODY_PATH := "res://fonts/VT323-Regular.ttf"

## (0.14) The sizes text comes in, each a whole number of the face's own
## pixels so no letter is drawn with a stretched or squashed pixel. Jersey 10's
## pixel is 1/18.7 of its size; VT323's 1/12.5.
const SMALL := 19              # Jersey 10 at 1: small labels, a card's small print
const TITLE := 37              # Jersey 10 at 2: titles, names, numbers
const HUGE := 56               # Jersey 10 at 3: banners
const BODY := 25               # VT323 at 2: what you read
const BODY_BIG := 50           # VT323 at 4

## (0.14) Colour roles: each colour means one thing.
const YOURS := Color("#73efe8")        # yours, and what is chosen
const THEIRS := Color("#ff2a3c")       # the Enemies
const MAIN := Color("#d6a851")         # the one thing to do next; money and time
const DANGER := Color("#f8c53a")       # look out
const STEEL := Color("#2c3438")        # a button that isn't the main one
const STEEL_EDGE := Color("#5e718e")
const INK := Color("#271f1b")          # words on gold

static var _font: Font = null
static var _old: Font = null
static var _body: Font = null


## Jersey 10 (the engine's own face if the file is missing).
static func font() -> Font:
	if _font != null:
		return _font
	if _old == null:
		_old = ThemeDB.fallback_font
	var f: FontFile = null
	if ResourceLoader.exists(FONT_PATH):
		f = load(FONT_PATH) as FontFile
	if f == null and FileAccess.file_exists(FONT_PATH):
		f = FontFile.new()
		f.data = FileAccess.get_file_as_bytes(FONT_PATH)
	if f == null:
		_font = _old
		return _font
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.generate_mipmaps = false
	_font = f
	return _font


## (0.14) VT323, the body face (Jersey 10 if its file is missing).
static func body() -> Font:
	if _body != null:
		return _body
	var f: FontFile = null
	if ResourceLoader.exists(BODY_PATH):
		f = load(BODY_PATH) as FontFile
	if f == null and FileAccess.file_exists(BODY_PATH):
		f = FontFile.new()
		f.data = FileAccess.get_file_as_bytes(BODY_PATH)
	if f == null:
		_body = font()
		return _body
	f = f.duplicate() as FontFile
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.generate_mipmaps = false
	_body = f
	return _body


## (0.14) Text to read, in VT323 at its size.
static func read(text: String, colour := Color("#e6e7f0"), wrap := false, big := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", body())
	l.add_theme_font_size_override("font_size", BODY_BIG if big else BODY)
	l.add_theme_color_override("font_color", colour)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## (0.14) A title or a number, in Jersey 10 at one of its sizes.
static func title(text: String, colour := Color("#e6e7f0"), size := TITLE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	return l


## (0.14) An old size, set in one of the two faces at its own pixels: names
## and numbers (20 and up) in Jersey 10 at 2, what you read (15 to 19) in
## VT323, the small print (14 and under) in Jersey 10 at 1.
static func size_to(l: Control, n: int) -> void:
	if n >= 20:
		l.add_theme_font_override("font", font())
		l.add_theme_font_size_override("font_size", TITLE)
	elif n >= 15:
		l.add_theme_font_override("font", body())
		l.add_theme_font_size_override("font_size", BODY)
	else:
		l.add_theme_font_override("font", font())
		l.add_theme_font_size_override("font_size", SMALL)


## A size written for the old face, in this one.
static func fs(n) -> int:
	return int(round(float(n) * 4.0 / 3.0))


## The face every Control and every drawn word uses from now on.
static func install() -> void:
	var f := font()
	if f != null:
		ThemeDB.fallback_font = f
		ThemeDB.fallback_font_size = fs(16)


## A frame: fill, edge, how heavy the edge is (0 none, 1, 2), how deep the
## corners are cut (0 to 3 steps of two pixels), and the space inside.
static func frame(bg: Color, edge: Color, border := 1, notch := 2, margin := Vector2(14, 8)) -> PixelBox:
	var b := PixelBox.new()
	b.bg_color = bg
	b.border_color = edge
	b.border = border
	b.notch = notch
	b.content_margin_left = margin.x
	b.content_margin_right = margin.x
	b.content_margin_top = margin.y
	b.content_margin_bottom = margin.y
	return b


## (0.14) The UI kit: a button for the one thing to do next (gold), one for
## anything else (steel), one that can't be taken back (red), and one that is
## only an icon; each with its pressed and its disabled look.
static func kit(t: Theme) -> void:
	var variants := {
		"MainButton": [MAIN, Color("#efdd91"), INK, Color("#f8e398"), Color("#b47538")],
		"DangerButton": [Color("#7e0e0e"), Color("#e27285"), Color("#f1ebdb"), Color("#9f2d35"), Color("#37060b")],
		"IconButton": [STEEL, STEEL_EDGE, Color("#e6e7f0"), Color("#465456"), Color("#171819")],
	}
	for v in variants:
		var c: Array = variants[v]
		t.set_type_variation(v, "Button")
		var normal := frame(c[0], c[1], 1, 2, Vector2(10, 6) if v == "IconButton" else Vector2(20, 8))
		normal.shadow = true
		var hover := normal.copy()
		hover.bg_color = c[3]
		var pressed := normal.copy()
		pressed.bg_color = c[4]
		pressed.shadow = false
		var lit := frame(UI.PANEL_LIT, YOURS, 1, 2, normal_margin(normal))
		var disabled := frame(UI.PANEL, UI.LINE, 1, 2, normal_margin(normal))
		disabled.bevel = false
		t.set_stylebox("normal", v, normal)
		t.set_stylebox("hover", v, hover)
		t.set_stylebox("pressed", v, lit if v == "IconButton" else pressed)
		t.set_stylebox("hover_pressed", v, lit if v == "IconButton" else pressed)
		t.set_stylebox("disabled", v, disabled)
		t.set_stylebox("focus", v, StyleBoxEmpty.new())
		for k in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
			t.set_color(k, v, c[2])
		t.set_color("font_disabled_color", v, UI.DIM.darkened(0.25))
		t.set_color("icon_normal_color", v, Color.WHITE)
		t.set_color("icon_disabled_color", v, Color(1, 1, 1, 0.35))
	t.set_type_variation("Inset", "PanelContainer")
	t.set_stylebox("panel", "Inset", frame(UI.BG, UI.LINE, 1, 1, Vector2(10, 6)))
	t.set_type_variation("Tooltip", "PanelContainer")
	t.set_stylebox("panel", "Tooltip", frame(Color("#282c3c"), STEEL_EDGE, 1, 1, Vector2(12, 8)))


static func normal_margin(b: PixelBox) -> Vector2:
	return Vector2(b.content_margin_left, b.content_margin_top)


## (0.14) A fight's screens read in VT323: this theme on their parts.
static func fight_theme() -> Theme:
	var t := theme()
	t.default_font = body()
	t.default_font_size = BODY
	return t


## The theme on the game's screens.
static func theme() -> Theme:
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = fs(22)
	# buttons: a raised plate with a cut corner; pressed (or chosen) it lights in cyan
	var normal := frame(UI.BUTTON, UI.EDGE_HI, 1, 2, Vector2(16, 8))
	normal.shadow = true
	var hover := normal.copy()
	hover.bg_color = UI.BUTTON.lightened(0.08)
	var pressed := frame(UI.PANEL_LIT, UI.CYAN, 1, 2, Vector2(16, 8))
	var disabled := frame(UI.PANEL, UI.LINE, 1, 2, Vector2(16, 8))
	disabled.bevel = false
	for k in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		t.set_stylebox(k, "Button", {"normal": normal, "hover": hover, "pressed": pressed, "disabled": disabled, "hover_pressed": pressed}[k])
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", UI.TEXT)
	t.set_color("font_hover_color", "Button", UI.TEXT)
	t.set_color("font_focus_color", "Button", UI.TEXT)
	t.set_color("font_pressed_color", "Button", UI.CYAN)
	t.set_color("font_hover_pressed_color", "Button", UI.CYAN)
	t.set_color("font_disabled_color", "Button", UI.DIM.darkened(0.25))
	# panels
	t.set_stylebox("panel", "PanelContainer", frame(UI.PANEL, UI.LINE, 1, 2, Vector2(12, 8)))
	t.set_stylebox("panel", "Panel", frame(UI.PANEL, UI.LINE, 1, 2, Vector2(12, 8)))
	# a line to type in
	var le := frame(UI.BG, UI.LINE, 1, 1, Vector2(12, 8))
	var le_on := frame(UI.BG, UI.CYAN, 1, 1, Vector2(12, 8))
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", le_on)
	t.set_stylebox("read_only", "LineEdit", le)
	t.set_color("font_color", "LineEdit", UI.TEXT)
	t.set_color("caret_color", "LineEdit", UI.CYAN)
	# text, with a pixel's shadow under it so it reads on a backdrop
	t.set_color("font_color", "Label", UI.TEXT)
	t.set_color("font_shadow_color", "Label", Color("#050403", 0.85))
	t.set_constant("shadow_offset_x", "Label", 2)
	t.set_constant("shadow_offset_y", "Label", 2)
	kit(t)
	return t
