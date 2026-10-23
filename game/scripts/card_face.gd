## A card as the Forge prints it (0.14), at any size: its District's colour
## round the edge, its name and what it costs at the top, what kind of card it
## is, its art in a window, its rules in a box, and a Unit's numbers or what
## the card is worth along the bottom. The same face in a hand, on a tile, in a
## loot drop and on a card's sheet; only the size changes.
##
## Small (a tile, 150 wide) prints everything in Jersey 10 at its own pixel,
## with the art at twice its pixels; large (a sheet, 360 wide) prints the
## rules in VT323 and the art at five times. Art always lands on whole pixels.
class_name CardFace
extends RefCounted

const SMALL := Vector2(150, 210)
const LARGE := Vector2(360, 504)
## Each District's colour, and its light shade (the Workshop's)
const DISTRICT := {"": ["#5d7078", "#d6e3e8"], "1": ["#6a49cc", "#a98ef0"], "2": ["#c23a8d", "#ef7fbe"], "3": ["#d1751c", "#f0a457"],
	"4": ["#bb3d30", "#ef8175"], "5": ["#38914c", "#6fd189"], "6": ["#1f8da3", "#56c6da"]}
const UNITS := ["hero", "troop", "enemy", "elite", "miniboss", "boss"]


## The card's District: its first Affinity's ("" for none).
static func district_of(c: Dictionary) -> String:
	if Rules.truthy(c.get("district")):
		return str(c["district"])
	var affs = c.get("affinities")
	if affs is Array:
		for a in affs:
			if a is Dictionary and Rules.truthy(a.get("district")) and str(a["district"]) != "any" and str(a["district"]) != "neu":
				return str(a["district"])
	return ""


static func colours(c: Dictionary) -> Array:
	var d := district_of(c)
	var pair: Array = DISTRICT.get(d, DISTRICT[""])
	return [Color(pair[0]), Color(pair[1])]


## Words broken into lines that fit, at most max_lines; the last line cut with "…" if it had to be.
static func wrap_lines(font: Font, size: int, text: String, width: float, max_lines: int) -> Array:
	var lines := []
	var line := ""
	for w in text.split(" ", false):
		var t := w if line == "" else line + " " + w
		if font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= width or line == "":
			line = t
		else:
			lines.append(line)
			line = w
	if line != "":
		lines.append(line)
	if lines.size() > max_lines:
		lines = lines.slice(0, max_lines)
		var last: String = lines[max_lines - 1]
		while last.length() > 1 and font.get_string_size(last + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
			last = last.substr(0, last.length() - 1)
		lines[max_lines - 1] = last.strip_edges() + "…"
	return lines


## What the rules box says, as words each with its colour: an Action's or an
## effect's name in white, its keywords in their categories' colours (as the
## Forge prints them), the rest pale.
static func rules_words(c: Dictionary) -> Array:
	var out := []
	var add_text := func(text: String, colour: Color) -> void:
		for w in text.split(" ", false):
			out.append([w, colour])
	var add_rules := func(text) -> void:
		for r in Keywords.display_runs(str(text if text != null else "")):
			var col := UI.PALE
			if r.get("kw", false) and r.get("colour") != null:
				col = Color(str(r["colour"]))
			add_text.call(UI.show(str(r["t"] if r["t"] != null else "")), col)
	var t := Roster.type_of(c)
	if UNITS.has(t):
		var u := Rules.unit_from_card(Roster.unit_spec(c), "ally")
		for a in u["actions"]:
			add_text.call(str(a.get("name", "")) + ":", UI.TEXT)
			var said := str(a.get("text", "") if a.get("text") != null else "").strip_edges()
			if said != "":
				add_rules.call(said)
			elif a.get("tag") != "Passive" and a.get("tag") != "Aura":
				var fx := Rules.action_effect(a)
				add_text.call(("%d damage." % fx["damage"]) if fx["damage"] > 0 else (("heals %d." % fx["heal"]) if fx["heal"] > 0 else ""), UI.PALE)
	else:
		for e in Roster.hand_card(c)["effects"]:
			var head := str(e.get("name", ""))
			if head != "":
				add_text.call(head + ":", UI.TEXT)
			var said := str(e.get("text", "") if e.get("text") != null else "").strip_edges()
			if said != "":
				add_rules.call(said)
			elif Rules.truthy(e.get("damage")):
				add_text.call(str(e["damage"]) + " damage.", UI.PALE)
	if Rules.truthy(c.get("basic")):
		add_text.call("A basic Chip: it has no effect of its own.", UI.DIM)
	if out.is_empty():
		add_text.call("No rules text.", UI.DIM)
	return out


## Coloured words broken into lines that fit, at most max_lines (the last cut with "…").
static func wrap_words(font: Font, size: int, words: Array, width: float, max_lines: int) -> Array:
	var space := font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var lines := []
	var line := []
	var w := 0.0
	for wd0 in words:
		var wd: Array = wd0.duplicate()
		var ww := font.get_string_size(str(wd[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		# a stop or a comma sits against the word before it
		var glued := not line.is_empty() and str(wd[0]).length() > 0 and ".,;:!?)".contains(str(wd[0])[0])
		if glued:
			line[line.size() - 1] = [str(line[line.size() - 1][0]), line[line.size() - 1][1], wd]
			w += ww
			continue
		if not line.is_empty() and w + space + ww > width:
			lines.append(line)
			line = []
			w = 0.0
		w += (space if not line.is_empty() else 0.0) + ww
		line.append(wd)
	if not line.is_empty():
		lines.append(line)
	if lines.size() > max_lines:
		lines = lines.slice(0, max_lines)
		var last: Array = lines[max_lines - 1]
		last.append(["…", UI.DIM])
		var lw := func(l: Array) -> float:
			var t := 0.0
			for x in l:
				t += font.get_string_size(str(x[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + space
			return t
		while last.size() > 1 and lw.call(last) > width:
			last.remove_at(last.size() - 2)
	return lines


## What the rules box says, as one run of text: each Action or effect, by name, and what it does.
static func rules_text(c: Dictionary) -> String:
	var t := Roster.type_of(c)
	var bits := []
	if UNITS.has(t):
		var u := Rules.unit_from_card(Roster.unit_spec(c), "ally")
		for a in u["actions"]:
			var nm := str(a.get("name", ""))
			var said := Keywords.render(str(a.get("text", "") if a.get("text") != null else "")).strip_edges()
			if said == "" and a.get("tag") != "Passive" and a.get("tag") != "Aura":
				var fx := Rules.action_effect(a)
				said = ("%d damage" % fx["damage"]) if fx["damage"] > 0 else (("heals %d" % fx["heal"]) if fx["heal"] > 0 else "")
			bits.append(nm + (": " + said if said != "" else ""))
	else:
		for e in Roster.hand_card(c)["effects"]:
			var head := str(e.get("name", ""))
			var said := Keywords.render(str(e.get("text", "") if e.get("text") != null else "")).strip_edges()
			if said == "" and Rules.truthy(e.get("damage")):
				said = str(e["damage"]) + " damage"
			bits.append((head + ": " if head != "" and said != "" else head) + said)
	if Rules.truthy(c.get("basic")):
		bits.append("A basic Chip: it has no effect of its own.")
	var out := UI.show(". ".join(bits.filter(func(b): return str(b).strip_edges() != "")))
	return out if out != "" else "No rules text."


## A Unit's numbers ("HP 20  AC 10  MS 3"), or "" for a card that isn't one.
static func stat_line(c: Dictionary) -> String:
	if not UNITS.has(Roster.type_of(c)):
		return ""
	var u := Rules.unit_from_card(Roster.unit_spec(c), "ally")
	return "HP %d  AC %d  MS %d" % [u["hpMax"], u["ac"], u["ms"]]


## Its cost as gems: [[gem key, count], ...] (a variable slot has none: it shows X).
static func cost_gems(c: Dictionary) -> Array:
	var t := Roster.type_of(c)
	if not StrikeTeams.DECK_TYPES.has(t) and t != "action":
		return []
	var h := Roster.hand_card(c)
	var raw: Dictionary = h["cost"] if h.get("cost") is Dictionary else {}
	var cc := Roster.card_cost(h)
	var out := []
	var d := str(cc.get("district") if Rules.truthy(cc.get("district")) else "")
	if Roster.slot_x(raw.get("affinity")) == 0 and int(cc["affinity"]) > 0:
		out.append(["gem_" + (d if d != "" else "any"), int(cc["affinity"])])
	if Roster.slot_x(raw.get("generic")) == 0 and int(cc["generic"]) > 0:
		out.append(["gem_any", int(cc["generic"])])
	return out


static func _px(ci: CanvasItem, r: Rect2, c: Color) -> void:
	ci.draw_rect(Rect2(r.position.round(), r.size.round()), c)


## Paints the face into rect. opts: chosen, faded, gone, count, mark, mark_colour, plain, foot.
static func paint(ci: CanvasItem, rect: Rect2, card: Dictionary, art: Texture2D, opts: Dictionary = {}) -> void:
	var big := rect.size.x >= 300.0
	var p := 4.0 if big else 2.0                     # one pixel of the frame
	var face := Look.font()
	var body := Look.body() if big else Look.font()
	var name_size := Look.TITLE if big else Look.SMALL
	var body_size := Look.BODY if big else Look.SMALL
	var t := Roster.type_of(card)
	var col := colours(card)
	var dark: Color = col[0]
	var lite: Color = col[1]
	var gone: bool = opts.get("gone", false)
	var chosen: bool = opts.get("chosen", false)
	var r := Rect2(rect.position.round(), rect.size.round())
	# the frame: a dark rim, the District's keyline, the card
	_px(ci, r, Color("#0e0c0c"))
	_px(ci, r.grow(-p), (UI.CYAN if chosen else (UI.RED if gone else lite)))
	var inner := r.grow(-p * 2.0)
	_px(ci, inner, Color("#171819"))
	# the name band
	var band_h := (52.0 if big else 24.0)
	var band := Rect2(inner.position, Vector2(inner.size.x, band_h))
	_px(ci, band, dark.darkened(0.55))
	_px(ci, Rect2(band.position.x, band.end.y - p, band.size.x, p), dark.darkened(0.2))
	# cost gems, right to left
	var gx := band.end.x - p * 2.0
	var gem_s := 2.0 if big else 1.0
	var gems := cost_gems(card)
	var xcost := StrikeTeams.DECK_TYPES.has(t) and Roster.card_var(Roster.hand_card(card))
	if xcost:
		var xw := face.get_string_size("X", HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x
		gx -= xw
		ci.draw_string(face, Vector2(gx, band.position.y + band_h * 0.72), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, name_size, UI.GOLD)
		gx -= p * 2.0
	var shown := 0
	for g in gems:
		var tex := Art.status_mark(str(g[0]))
		for i in mini(int(g[1]), 6 - shown):
			gx -= 7.0 * gem_s
			if tex != null:
				ci.draw_set_transform(Vector2(gx, band.position.y + (band_h - 8.0 * gem_s) / 2.0).round(), 0.0, Vector2(gem_s, gem_s))
				ci.draw_texture(tex, Vector2.ZERO)
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			shown += 1
	# the name
	var name_w := gx - band.position.x - p * 4.0
	var nm := str(card.get("name", ""))
	var nl: Array = wrap_lines(face, name_size, nm, name_w, 1)
	ci.draw_string(face, Vector2(band.position.x + p * 3.0, band.position.y + band_h * 0.74).round(), str(nl[0]) if not nl.is_empty() else "", HORIZONTAL_ALIGNMENT_LEFT, -1, name_size, UI.SOFT_RED if gone else UI.TEXT)
	# what kind of card
	var y := band.end.y + p * 2.0
	var kind := "Not in this export" if gone else UI.type_name(card)
	var d := district_of(card)
	if not gone and d != "":
		kind += " · D" + d
	if big and not gone:
		kind = "Not in this export" if gone else CardSheet.kind_line(card)
	var kl: Array = wrap_lines(body, body_size, kind, inner.size.x - p * 6.0, 1)
	var kh := (26.0 if big else 16.0)
	ci.draw_string(body, Vector2(inner.position.x + p * 3.0, y + kh * 0.8).round(), str(kl[0]) if not kl.is_empty() else "", HORIZONTAL_ALIGNMENT_LEFT, -1, body_size, UI.SOFT_RED if gone else UI.type_colour(card))
	y += kh + p
	# the art window: the District's colour behind, the art at a whole number of its pixels
	var scale := 5.0 if big else 2.0
	var win := Rect2(Vector2(inner.position.x + (inner.size.x - 64.0 * scale) / 2.0, y), Vector2(64.0 * scale, 45.0 * scale))
	_px(ci, win.grow(p), Color("#0e0c0c"))
	_px(ci, win, dark.darkened(0.7))
	var stripe := p * 2.0
	var sy := win.position.y + stripe
	while sy < win.end.y:
		_px(ci, Rect2(win.position.x, sy, win.size.x, p), dark.darkened(0.6))
		sy += stripe * 2.0
	var tex := art
	if tex == null and not UNITS.has(t):
		tex = Art.card_standin(t)
	if tex != null:
		var ts := tex.get_size()
		var k := floorf(minf(win.size.x / ts.x, win.size.y / ts.y))
		var bottom := false
		if ts.x <= 48.0 and ts.y <= 48.0:
			# a token: at the card's own scale (2 or 5 to a pixel), standing on the window's floor, its head allowed off the top
			k = scale if ts.y * scale <= win.size.y + 12.0 * scale else k
			bottom = true
		if k < 1.0:
			k = minf(win.size.x / ts.x, win.size.y / ts.y)
		var sz := ts * k
		var at := Vector2(win.position.x + (win.size.x - sz.x) / 2.0, (win.end.y - sz.y + k * 2.0) if bottom else win.position.y + (win.size.y - sz.y) / 2.0).round()
		var src := Rect2(Vector2.ZERO, ts)
		if at.y < win.position.y:
			var cut := ceilf((win.position.y - at.y) / k)
			src = Rect2(0, cut, ts.x, ts.y - cut)
			at.y += cut * k
		ci.draw_texture_rect_region(tex, Rect2(at, src.size * k), src)
	elif UNITS.has(t):
		var lt := Roster.letters(nm)
		var lw := face.get_string_size(lt, HORIZONTAL_ALIGNMENT_LEFT, -1, Look.HUGE).x
		ci.draw_string(face, Vector2(win.position.x + (win.size.x - lw) / 2.0, win.position.y + win.size.y * 0.66).round(), lt, HORIZONTAL_ALIGNMENT_LEFT, -1, Look.HUGE, lite)
	var mark := str(opts.get("mark", ""))
	if mark != "":
		var mw := face.get_string_size(mark, HORIZONTAL_ALIGNMENT_LEFT, -1, Look.SMALL).x + 12.0
		_px(ci, Rect2(win.position.x, win.end.y - 20.0, mw, 20.0), opts.get("mark_colour", UI.CYAN))
		ci.draw_string(face, Vector2(win.position.x + 6.0, win.end.y - 5.0), mark, HORIZONTAL_ALIGNMENT_LEFT, -1, Look.SMALL, Color("#0e0c0c"))
	if opts.get("plain", false):
		var pw := face.get_string_size("Plain text", HORIZONTAL_ALIGNMENT_LEFT, -1, Look.SMALL).x + 10.0
		_px(ci, Rect2(win.position.x, win.position.y, pw, 18.0), UI.GOLD)
		ci.draw_string(face, Vector2(win.position.x + 5.0, win.position.y + 14.0), "Plain text", HORIZONTAL_ALIGNMENT_LEFT, -1, Look.SMALL, Color("#0e0c0c"))
	y = win.end.y + p * 3.0
	# the rules box
	var foot := str(opts.get("foot", ""))
	var stats := stat_line(card)
	var bottom_h := (40.0 if big else 18.0)
	var box := Rect2(inner.position.x + p * 2.0, y, inner.size.x - p * 4.0, inner.end.y - y - bottom_h - p * 3.0)
	_px(ci, box, Color("#0e0c0c"))
	_px(ci, box.grow(-p), Color("#282c3c") if not big else Color("#1b2027"))
	var lh := (25.0 if big else 15.0)
	var max_lines := maxi(1, int((box.size.y - p * 2.0) / lh))
	var lines: Array = wrap_words(body, body_size, rules_words(card), box.size.x - p * 6.0, max_lines)
	var space := body.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, body_size).x
	for i in lines.size():
		var x := box.position.x + p * 3.0
		for wd in lines[i]:
			ci.draw_string(body, Vector2(x, box.position.y + p + lh * (i + 0.8)).round(), str(wd[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, body_size, wd[1])
			x += body.get_string_size(str(wd[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, body_size).x
			if wd.size() > 2:
				# the stop glued to it
				var g: Array = wd[2]
				ci.draw_string(body, Vector2(x, box.position.y + p + lh * (i + 0.8)).round(), str(g[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, body_size, g[1])
				x += body.get_string_size(str(g[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, body_size).x
			x += space
	# the bottom: a Unit's numbers, or what the card is worth here
	var line := stats if stats != "" else foot
	if stats != "" and foot != "" and not big and foot.begins_with("LDR"):
		line = foot
	if line != "" and not gone:
		ci.draw_string(face, Vector2(inner.position.x + p * 3.0, inner.end.y - bottom_h * 0.28).round(), line, HORIZONTAL_ALIGNMENT_LEFT, inner.size.x - p * 6.0, name_size, UI.GOLD)
	# copies: a gold plate with cut corners
	var count := int(opts.get("count", 0))
	if count > 0:
		var ct := "×%d" % count
		var tw := face.get_string_size(ct, HORIZONTAL_ALIGNMENT_LEFT, -1, Look.SMALL).x
		var bw := maxf(30.0, tw + 12.0)
		var bp := Vector2(r.end.x - bw - 2.0, r.position.y + band_h + p * 2.0)
		ci.draw_style_box(Look.frame(UI.GOLD, Color("#0e0c0c"), 1, 2, Vector2.ZERO), Rect2(bp, Vector2(bw, 26.0)))
		ci.draw_string(face, bp + Vector2((bw - tw) / 2.0, 19.0), ct, HORIZONTAL_ALIGNMENT_LEFT, -1, Look.SMALL, Color("#0e0c0c"))
	if opts.get("faded", false):
		ci.draw_rect(r, Color("#0e0c0c", 0.55))


## (0.14) The face as a Control of its own, for a card's sheet.
class Face extends Control:
	var card: Dictionary
	var art: Texture2D

	func _init(c: Dictionary, picture: Texture2D, at := CardFace.LARGE) -> void:
		card = c
		art = picture
		custom_minimum_size = at
		size = at
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _draw() -> void:
		CardFace.paint(self, Rect2(Vector2.ZERO, size), card, art, {})
