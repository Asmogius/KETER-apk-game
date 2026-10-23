## The game's own pictures (0.11; drawn, 0.14, 0.15 and 0.16), and yours in their place.
##
## Every picture here is drawn by the game in pixels, on the Pixel Studio's
## palette: the icons (16 by 16), the backdrops behind Home, the dock and the
## other screens (256 by 144), the floor under a fight (a 64 by 64 tile that
## repeats) and the edge of a board tile. The Companion's Pixel Studio has a
## slot for each of the first three kinds, under Game look: a picture drawn in
## one comes in the export, and is used instead of the game's own.
class_name Art
extends RefCounted

## The icons, by id, with what each stands for (the slot's name in the Companion).
const ICONS := {"shards": "Aether shards", "part_troop": "Troop parts", "part_equipment": "Equipment parts", "part_aether": "Aether parts",
	"hp": "Health (HP)", "ac": "Armour (AC)", "ms": "Movement (MS)", "nrg": "Energy (NRG)", "aether": "Aether", "skull": "Skull Level"}
## The other slots: id -> [name, width, height].
const SLOTS := {"ui.title": ["Title", 256, 144], "ui.backdrop.dock": ["Dock backdrop", 256, 144], "ui.backdrop.menu": ["Menu backdrop", 256, 144], "ui.floor": ["Fight floor", 64, 64]}
## A backdrop's size: on a 1280 by 720 screen it is drawn five times over.
const BW := 256
const BH := 144
## The Pixel Studio's palette (AAP-Splendor128, its neons and the extra ramps):
## every pixel the game draws itself is one of these.
const PALETTE := [
	"050403", "0e0c0c", "2d1b1e", "612721", "b9451d", "f1641f", "fca570", "ffe0b7", "ffffff", "fff089", "f8c53a", "e88a36",
	"b05b2c", "673931", "271f1b", "4c3d2e", "855f39", "d39741", "f8f644", "d5dc1d", "adb834", "7f8e44", "586335", "333c24",
	"181c19", "293f21", "477238", "61a53f", "8fd032", "c4f129", "d0ffea", "97edca", "59cf93", "42a459", "3d6f43", "27412d",
	"14121d", "1b2447", "2b4e95", "2789cd", "42bfe8", "73efe8", "f1f2ff", "c9d4fd", "8aa1f6", "4572e3", "494182", "7864c6",
	"9c8bdb", "ceaaed", "fad6ff", "eeb59c", "d480bb", "9052bc", "171516", "373334", "695b59", "b28b78", "e2b27e", "f6d896",
	"fcf7be", "ecebe7", "cbc6c1", "a69e9a", "807b7a", "595757", "323232", "4f342f", "8c5b3e", "c68556", "d6a851", "b47538",
	"724b2c", "452a1b", "61683a", "939446", "c6b858", "efdd91", "b5e7cb", "86c69a", "5d9b79", "486859", "2c3b39", "171819",
	"2c3438", "465456", "64878c", "8ac4c3", "afe9df", "dceaee", "b8ccd8", "88a3bc", "5e718e", "485262", "282c3c", "464762",
	"696682", "9a97b9", "c5c7dd", "e6e7f0", "eee6ea", "e3cddf", "bfa5c9", "87738f", "564f5b", "322f35", "36282b", "654956",
	"966888", "c090a9", "d4b8b8", "eae0dd", "f1ebdb", "ddcebf", "bda499", "886e6a", "594d4d", "33272a", "b29476", "e1bf89",
	"f8e398", "ffe9e3", "fdc9c9", "f6a2a8", "e27285", "b25266", "64364b", "2a1e23", "8a3dff", "ff2bd6", "ff7a1a", "ff2a3c",
	"6dff3a", "22f0ff", "3dffc8", "2f7bff", "ff3d7f", "c23bff", "f0ff2a", "3e4246", "6e6a64", "6a7178", "7e858c", "b3ada2",
	"122616", "3c4a3a", "4e5e48", "65735a", "7f8a6e", "6e9f60", "9eb280", "3a2f3e", "4e4054", "654370", "66566c", "89609f",
	"a180b2", "406977", "5a6da6", "5a8ca6", "733a28", "7a4a36", "8e4a30", "a65d3c", "ad7a5e", "bf7652", "c98d68", "caa184",
	"d8b89a", "43360c", "635017", "983a1b", "804d17", "806517", "8a5a48", "9c5e44", "c8624d", "dd8877", "f0cbae", "bfae8c",
	"d4c6a8", "d0cb95", "e8dcc4", "37060b", "7e0e0e", "801c35", "9f2d35", "b81418", "b81439", "40740b", "6b6f11", "6f8707",
	"6aa208", "a2c113", "8ce50c"]
const OUTLINE := Color("#0e0c0c")

## (0.14) The game's own drawn art: sheets of tokens, board pieces, icons and
## card stand-ins, and art.json saying where each piece sits and what it is.
const ART_DIR := "res://art/"
const SHEET_OF := {"tokens": "tokens", "board": "board", "icons": "icons", "marks": "icons", "cards": "cards",
	"ground": "ground", "map": "map", "district": "district", "menu": "menu", "fx": "fx", "cardart": "cardart", "cardback": "cardback"}
## (0.16) The fight's drawn effects, each a row of frames: a muzzle flash, an
## impact where damage lands, an explosion on a tile a blast catches, a heal
## rising from whoever is mended, a shield as an attack glances off armour.
const FX := ["flash", "impact", "explosion", "heal", "shield"]

static var _mine := {}                 # slot id -> Texture2D: your drawings, from the export
static var _manifest = null            # art.json, once read
static var _sheets := {}               # sheet name -> Texture2D
static var _pieces := {}               # "kind/key" -> AtlasTexture
static var _made := {}                 # what the game drew itself, by key
static var ground := {}                # District -> [Texture2D]: the World Map's ground, as drawn
static var _mine_many := {}            # (0.15) a slot that takes many pictures -> [{texture, hex}]: map ground, rubble, map things
static var _mine_hex := {}             # (0.15) slot -> the export's word on a hex picture ({side, orient, shape, ...}), when it is one
static var _mine_frames := {}          # (0.16) slot -> {frames, fps}: a picture of yours drawn as frames, side by side in its PNG
static var _fx := {}                   # (0.16) effect name -> what fx() gives, while serial stays the same
static var _fx_serial := -1
static var serial := 0                 # goes up whenever the export's pictures change
static var _pal := PackedColorArray()


static func palette() -> PackedColorArray:
	if _pal.is_empty():
		for h in PALETTE:
			_pal.append(Color("#" + h))
	return _pal


## The palette's colour nearest this one (by how far apart they are in red, green and blue).
static func nearest(c: Color) -> Color:
	var best := Color.BLACK
	var far := INF
	for p in palette():
		var d := (p.r - c.r) * (p.r - c.r) + (p.g - c.g) * (p.g - c.g) + (p.b - c.b) * (p.b - c.b)
		if d < far:
			far = d
			best = p
	return Color(best, c.a)


## Whether a colour is on the palette (its opacity aside).
static func on_palette(c: Color) -> bool:
	return palette().has(Color(c, 1.0)) or nearest(c).to_html(false) == c.to_html(false)


## What the export carries for the game's look, and the World Map's ground.
static func load_from(data) -> void:
	_mine = {}
	ground = {}
	_mine_many = {}
	_mine_hex = {}
	_mine_frames = {}
	if data != null:
		for f in data.files():
			var o = f.get("owner")
			if not (o is Dictionary) or not Rules.truthy(o.get("slot")):
				continue
			var slot := str(o["slot"])
			if not (slot.begins_with("ui.") or slot.begins_with("map.") or slot.begins_with("fight.")):
				continue
			var tex: Texture2D = data.texture(str(f.get("file", "")))
			if tex == null:
				continue
			var hex = f.get("hex") if str(f.get("grid", "")) == "hex" and f.get("hex") is Dictionary else null
			if slot.begins_with("map.ground.") or slot == "map.collapsed" or slot.begins_with("map.prop."):
				# (0.15) the slots that take many pictures: one is picked for each tile
				if not _mine_many.has(slot):
					_mine_many[slot] = []
				_mine_many[slot].append({"texture": tex, "hex": hex})
				if slot.begins_with("map.ground."):
					var d := slot.substr(11)
					d = "" if d == "none" else d
					if not ground.has(d):
						ground[d] = []
					ground[d].append(tex)
			else:
				_mine[slot] = tex
				if hex != null:
					_mine_hex[slot] = hex
				# (0.16) one drawn as frames: its PNG has them side by side, and says how many and how fast
				if int(Rules.num(f.get("frames"), 1)) > 1 or slot.begins_with("fight.fx."):
					_mine_frames[slot] = {"frames": maxi(1, int(Rules.num(f.get("frames"), 1))), "fps": float(Rules.num(f.get("fps"), 0))}
	serial += 1


## Whether a slot has your drawing in it.
static func is_mine(slot: String) -> bool:
	return _mine.has(slot)


# ---------------------------------------------------------------- 0.14: the drawn art
## art.json: {tokens, board, icons, marks, cards}, each key -> {rect, ...}.
static func manifest() -> Dictionary:
	if _manifest == null:
		_manifest = {}
		var p := ART_DIR + "art.json"
		if FileAccess.file_exists(p):
			var j = JSON.parse_string(FileAccess.get_file_as_string(p))
			if j is Dictionary:
				_manifest = j
	return _manifest


static func _sheet(name: String) -> Texture2D:
	if _sheets.has(name):
		return _sheets[name]
	var p := ART_DIR + name + ".png"
	var tex: Texture2D = null
	if ResourceLoader.exists(p):
		tex = load(p) as Texture2D
	if tex == null and FileAccess.file_exists(p):
		var img := Image.load_from_file(ProjectSettings.globalize_path(p))
		if img != null and not img.is_empty():
			tex = ImageTexture.create_from_image(img)
	_sheets[name] = tex
	return tex


## One piece of the drawn art: kind is tokens, board, icons, marks or cards.
static func piece(kind: String, key: String) -> Texture2D:
	var k := kind + "/" + key
	if _pieces.has(k):
		return _pieces[k]
	var e = manifest().get(kind, {}).get(key)
	var sheet := _sheet(SHEET_OF.get(kind, kind))
	var out: Texture2D = null
	if e is Dictionary and e.get("rect") is Array and sheet != null:
		var r: Array = e["rect"]
		var a := AtlasTexture.new()
		a.atlas = sheet
		a.region = Rect2(r[0], r[1], r[2], r[3])
		out = a
	_pieces[k] = out
	return out


static func has_piece(kind: String, key: String) -> bool:
	return manifest().get(kind, {}).has(key)


## A name as the art knows it: "Sable-Nine, Ledger Adept" is sable_nine_ledger_adept.
static func slug(s: String) -> String:
	var out := ""
	var gap := false
	for ch in s.to_lower():
		var ok := (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9")
		if ok:
			if gap and out != "":
				out += "_"
			out += ch
			gap = false
		else:
			gap = true
	return out if out != "" else "untitled"


## The token drawn for a card: found by the card's number, then its name. Null if none.
static func token_drawn(card: Dictionary) -> Texture2D:
	var toks: Dictionary = manifest().get("tokens", {})
	var id := str(card.get("id", ""))
	if id != "":
		for k in toks:
			if str(toks[k].get("id", "")) == id:
				return piece("tokens", k)
	var nm := slug(str(card.get("name", "")))
	if toks.has(nm) and toks[nm].get("kind") != "standin":
		return piece("tokens", nm)
	return null


## A body plan's token (Bipedal, Quadcopter, Quadruped, Hexapod, Octopod).
static func body_token(plan: String) -> Texture2D:
	return piece("tokens", slug(plan)) if has_piece("tokens", slug(plan)) else null


## A Unit that has no token yet stands in as a shape by kind: melee, ranged, drone or beast.
static func standin_kind(card: Dictionary) -> String:
	var arch: Array = card["archetypes"] if card.get("archetypes") is Array else []
	var roles: Array = card["combatRoles"] if card.get("combatRoles") is Array else []
	var words := " ".join(arch.map(func(a): return str(a).to_lower())) + " " + str(card.get("bodyPlan", "")).to_lower()
	if "drone" in words or "quadcopter" in words:
		return "drone"
	if "quadruped" in words or "hexapod" in words or "octopod" in words or "monst" in words or "beast" in words or "swarm" in words:
		return "beast"
	if roles.has("ranged") or roles.has("Ranged"):
		return "ranged"
	return "melee"


## (yours if you drew it: the export's fight.standin.<kind> slot)
static func standin(kind: String) -> Texture2D:
	var t = _mine.get("fight.standin." + kind)
	return t if t != null else piece("tokens", "standin_" + kind)


## (0.14) A piece of the board: yours if you drew it (the export's fight.<name>
## slot), else the game's. With where it stands: {texture, foot}.
static func board(name: String) -> Dictionary:
	var t = _mine.get("fight." + name)
	var e = manifest().get("board", {}).get(name, {})
	var foot: Array = e.get("foot", [24, 40]) if e is Dictionary else [24, 40]
	if t != null:
		return {"texture": t, "foot": Vector2(foot[0], foot[1]), "mine": true}
	var p := piece("board", name)
	return {"texture": p, "foot": Vector2(foot[0], foot[1]), "mine": false} if p != null else {}


## (0.14) A status's icon (16 by 16) and its small mark on the board (8 by 8).
static func status_icon(name: String) -> Texture2D:
	var k := name.to_lower()
	var t = _mine.get("ui.status." + k.replace(" ", "_"))
	return t if t != null else piece("icons", k)


static func status_mark(name: String) -> Texture2D:
	var k := name.to_lower()
	var t = _mine.get("ui.mark." + k.replace(" ", "_"))
	if t != null:
		return t
	return piece("marks", k) if has_piece("marks", k) else piece("marks", k.replace("_", " "))


## (0.14) The drawn icons beyond the 0.11 ten: roles, actions, Districts and the bar's.
static func icon2(id: String) -> Texture2D:
	var t = _mine.get("ui.icon." + id)
	return t if t != null else piece("icons", id)


## (0.14) What a card shows in its art window until it has art: a picture of its kind.
static func card_standin(type: String) -> Texture2D:
	var t = _mine.get("ui.card." + type)
	return t if t != null else piece("cards", type)


## (0.19) The back of a card (75 by 105): yours in Game look's Card back slot,
## else the game's (the KETER emblem: the colony's surface over its labs).
static func card_back() -> Texture2D:
	var t = _mine.get("ui.card.back")
	return t if t != null else piece("cardback", "back")


## (0.17) The game's own picture for a card that is not a Unit (128 by 90: the
## thing, lit, on its District's backdrop), or null. Found by the card's id,
## else by its name, never for a card of another kind of the same name (the
## Aether Battery Unit is not the Aether battery card).
static func card_art(card: Dictionary) -> Texture2D:
	var all: Dictionary = manifest().get("cardart", {})
	var type := str(card.get("cardType", "")).to_lower()
	var id := str(card.get("id", ""))
	if id != "":
		for k in all:
			if str(all[k].get("id", "")) == id:
				return piece("cardart", k)
	var k := slug(str(card.get("name", "")))
	if all.has(k) and (type == "" or str(all[k].get("type", "")) == type):
		return piece("cardart", k)
	return null


# ---------------------------------------------------------------- 0.16: the fight's effects
## One of the fight's effects (flash, impact, explosion, heal, shield), as it
## plays: {frames: [Texture2D], fps (frames a second at Normal speed), anchor
## (the pixel that sits over the point it plays at), size (a frame's, in
## pixels), mine}. Yours if you drew it (the export's fight.fx.<name>: its
## frames side by side, with how many and how fast), else the game's. Yours
## sits as the game's does, its anchor where the game's is for its size; one
## of a single frame stays up as long as the game's would play.
static func fx(name: String) -> Dictionary:
	if _fx_serial != serial:
		_fx = {}
		_fx_serial = serial
	if _fx.has(name):
		return _fx[name]
	var out := {}
	var e = manifest().get("fx", {}).get(name)
	var game := {}
	if e is Dictionary and e.get("rect") is Array:
		var r: Array = e["rect"]
		var n := maxi(1, int(Rules.num(e.get("frames"), 1)))
		var w := int(Rules.num(e.get("w"), int(r[2]) / n))
		var h := int(Rules.num(e.get("h"), r[3]))
		var sheet := _sheet("fx")
		var frames := []
		if sheet != null:
			for i in n:
				var a := AtlasTexture.new()
				a.atlas = sheet
				a.region = Rect2(int(r[0]) + i * w, int(r[1]), w, h)
				frames.append(a)
		var an: Array = e.get("anchor", [w / 2, h / 2]) if e.get("anchor") is Array else [w / 2, h / 2]
		game = {"frames": frames, "fps": maxf(1.0, float(Rules.num(e.get("fps"), 12))), "anchor": Vector2(an[0], an[1]), "size": Vector2(w, h), "mine": false}
	out = game
	var slot := "fight.fx." + name
	var t: Texture2D = _mine.get(slot)
	if t != null:
		var info: Dictionary = _mine_frames.get(slot, {"frames": 1, "fps": 0.0})
		var n2 := maxi(1, int(info.get("frames", 1)))
		var sz := t.get_size()
		var w2 := maxi(1, int(sz.x) / n2)
		var h2 := int(sz.y)
		var frames2 := []
		for i in n2:
			var a2 := AtlasTexture.new()
			a2.atlas = t
			a2.region = Rect2(i * w2, 0, w2, h2)
			frames2.append(a2)
		var fps := float(info.get("fps", 0.0))
		if fps <= 0.0:
			fps = float(game.get("fps", 12.0))
		if n2 == 1 and not game.is_empty():
			# one picture: up as long as the game's would play
			fps = float(game["fps"]) / maxf(1.0, float(game["frames"].size()))
		var anchor := Vector2(w2, h2) / 2.0
		if not game.is_empty():
			var gs: Vector2 = game["size"]
			anchor = (game["anchor"] * Vector2(w2, h2) / Vector2(maxf(1.0, gs.x), maxf(1.0, gs.y))).round()
		out = {"frames": frames2, "fps": fps, "anchor": anchor, "size": Vector2(w2, h2), "mine": true}
	_fx[name] = out
	return out


# ---------------------------------------------------------------- 0.15: the map, each District's fights, the menus
## A tile of the World Map as a picture to clip to the tile's hexagon:
## {texture, mid (where the tile's middle falls in it), s (its pixels to a hex
## pixel's corner), mine}. A picture of yours that is not a hexagon of
## flat-top hex pixels comes as {texture, rect: true}, to be drawn over the
## tile as it is.
static func _hex_tile(t: Texture2D, hex) -> Dictionary:
	var sz := t.get_size()
	if not (hex is Dictionary) or str(hex.get("shape", "")) != "hexagon" or str(hex.get("orient", "")) != "flat":
		return {"texture": t, "rect": true, "mine": true}
	var side := maxi(2, int(Rules.num(hex.get("side"), 9)))
	var r := float(side - 1)
	# the cells' whole extent, in a cell's corner-lengths: 3R + 2 across, (2R + 1) x sqrt 3 down
	var s := minf(sz.x / (3.0 * r + 2.0), sz.y / ((2.0 * r + 1.0) * Hex.SQ3))
	return {"texture": t, "mid": sz / 2.0, "s": s, "side": side, "mine": true}


## (0.15) The ground for a District's tiles ("" for no District): yours if you
## drew any, else the game's four.
static func map_ground(d: String) -> Array:
	var slot := "map.ground." + (d if d != "" else "none")
	if _mine_many.has(slot):
		return _mine_many[slot].map(func(e): return _hex_tile(e["texture"], e["hex"]))
	return _game_tiles(func(e): return e.get("kind") == "ground" and str(e.get("d", "")) == d)


## (0.15) Rubble, for the tiles that have collapsed: yours, or the game's three.
static func rubble() -> Array:
	if _mine_many.has("map.collapsed"):
		return _mine_many["map.collapsed"].map(func(e): return _hex_tile(e["texture"], e["hex"]))
	return _game_tiles(func(e): return e.get("kind") == "rubble")


static func _game_tiles(want: Callable) -> Array:
	var out := []
	var g: Dictionary = manifest().get("ground", {})
	var keys := g.keys()
	keys.sort()
	var s := float(Rules.num(manifest().get("ground_layout", {}).get("s"), 3.0))
	for k in keys:
		var e: Dictionary = g[k]
		if want.call(e):
			var t := piece("ground", k)
			if t != null:
				var m: Array = e.get("mid", [39, 44])
				out.append({"texture": t, "mid": Vector2(m[0], m[1]), "s": s, "side": 9, "mine": false})
	return out


## (0.15) What stands on a District's empty tiles: [{texture, foot}], yours or the game's.
static func map_props(d: String) -> Array:
	var slot := "map.prop." + d
	if _mine_many.has(slot):
		return _mine_many[slot].map(func(e): return {"texture": e["texture"], "foot": Vector2(e["texture"].get_width() / 2.0, e["texture"].get_height() - 4.0), "mine": true})
	var out := []
	var m: Dictionary = manifest().get("map", {})
	var keys := m.keys()
	keys.sort()
	for k in keys:
		var e: Dictionary = m[k]
		if e.get("kind") == "prop" and str(e.get("d", "")) == d:
			var f: Array = e.get("foot", [16, 26])
			out.append({"texture": piece("map", k), "foot": Vector2(f[0], f[1]), "mine": false})
	return out


## (0.15) The icon for what a tile holds (poi, unique, ambush, cache, event), to
## sit on a plate in its colour: {texture, plate}. A hex picture of yours, from
## before 0.15, covers the tile instead: {texture, rect: true}.
const PLATE := {"poi": "#d6a851", "unique": "#f8e398", "ambush": "#ff2a3c", "cache": "#59cf93", "event": "#42bfe8"}


static func map_icon(kind: String) -> Dictionary:
	var slot := "map.icon." + kind
	var t = _mine.get(slot)
	if t != null:
		if _mine_hex.has(slot):
			return {"texture": t, "rect": true, "mine": true}
		return {"texture": t, "plate": Color(PLATE.get(kind, "#88a3bc")), "mine": true}
	var p := piece("map", "icon_" + kind)
	return {"texture": p, "plate": Color(PLATE.get(kind, "#88a3bc")), "mine": false} if p != null else {}


## (0.15) The dock: the Hangar, standing over its tile, {texture, foot}; or your
## hex picture of it from before, covering the tile ({texture, rect: true}).
static func hangar() -> Dictionary:
	var t = _mine.get("map.icon.dock")
	if t != null:
		if _mine_hex.has("map.icon.dock"):
			return {"texture": t, "rect": true, "mine": true}
		return {"texture": t, "foot": Vector2(t.get_width() / 2.0, t.get_height() - 12.0), "mine": true}
	var e = manifest().get("map", {}).get("hangar")
	var p := piece("map", "hangar")
	if p == null or not (e is Dictionary):
		return {}
	var f: Array = e.get("foot", [32, 52])
	return {"texture": p, "foot": Vector2(f[0], f[1]), "mine": false}


## (0.15) A District's own piece of a fight: floor_0 to floor_4, half_cover or
## full_cover. Yours (fight.d<n>.<name>), or the game's; {} where the District
## has none (a floor in no District keeps the grey deck).
static func district_board(d: String, name: String) -> Dictionary:
	if d == "" or d == "0":
		return {}
	var t = _mine.get("fight.d%s.%s" % [d, name])
	var e = manifest().get("district", {}).get("d%s_%s" % [d, name])
	var foot: Array = e.get("foot", [24, 40]) if e is Dictionary else ([21, 24] if name.begins_with("floor") else [24, 40])
	if t != null:
		return {"texture": t, "foot": Vector2(foot[0], foot[1]), "mine": true}
	var p := piece("district", "d%s_%s" % [d, name])
	return {"texture": p, "foot": Vector2(foot[0], foot[1]), "mine": false} if p != null else {}


## (0.15) A picture of the menus': qm7 and qm7_blink (the dock's keeper), victory
## and defeat (the end of a fight). Yours in the matching ui. slot, else the game's.
const MENU_SLOT := {"qm7": "ui.qm7", "qm7_blink": "ui.qm7_blink", "victory": "ui.title.victory", "defeat": "ui.title.defeat"}


static func menu_piece(key: String) -> Texture2D:
	var t = _mine.get(MENU_SLOT.get(key, "ui." + key))
	return t if t != null else piece("menu", key)


static func _texture(key: String, make: Callable) -> Texture2D:
	if not _made.has(key):
		_made[key] = ImageTexture.create_from_image(make.call())
	return _made[key]


## An icon: yours if you drew it, else the game's.
static func icon(id: String) -> Texture2D:
	var t = _mine.get("ui.icon." + id)
	if t != null:
		return t
	# (0.15) the drawn ones: shards, the parts, the Skull Level and the gear
	if has_piece("menu", "icon_" + id):
		return piece("menu", "icon_" + id)
	return _texture("icon." + id, func(): return icon_image(id))


## A backdrop: "title", "dock" or "menu".
static func backdrop(kind: String) -> Texture2D:
	var t = _mine.get("ui.title" if kind == "title" else "ui.backdrop." + kind)
	if t != null:
		return t
	# (0.15) the drawn ones: Home with the colony's sign, the Hangar inside, the colony at night
	var drawn: String = {"title": "home", "dock": "dock", "menu": "menu"}.get(kind, "")
	if drawn != "" and has_piece("menu", drawn):
		return piece("menu", drawn)
	return _texture("backdrop." + kind, func(): return backdrop_image(kind))


static func floor_tile() -> Texture2D:
	var t = _mine.get("ui.floor")
	if t != null:
		return t
	return _texture("floor", func(): return floor_image())


## The edge of a board tile, at half the board's scale (drawn twice its size).
static func hex_ring(size: float) -> Texture2D:
	return _texture("ring.%d" % int(size), func(): return ring_image(size))


# ---------------------------------------------------------------- icons
## The shape of each icon, in a 16 by 16 square centred on 0, 0: inside or not.
static func _inside(id: String, u: float, v: float) -> bool:
	var r := sqrt(u * u + v * v)
	match id:
		"shards":
			return absf(u + 1.2) / 3.8 + absf(v) / 6.8 <= 1.0 or absf(u - 4.6) / 1.9 + absf(v - 2.4) / 3.3 <= 1.0
		"part_troop":
			if r < 1.9:
				return false
			var a := atan2(v, u)
			return r <= 4.4 or (r <= 6.4 and cos(8.0 * a) > 0.15)
		"part_equipment":
			if r < 2.1:
				return false
			return absf(u) <= 5.6 and absf(u) * 0.5 + absf(v) * 0.866 <= 5.6
		"part_aether":
			return r <= 5.6 or (absf(u) <= 0.6 and absf(v) <= 7.0) or (absf(v) <= 0.6 and absf(u) <= 7.0)
		"hp":
			var x := u / 6.4
			var y := -v / 6.4 + 0.18
			var k := x * x + y * y - 1.0
			# the cleft at the top, a pixel wide, so it reads as a heart at this size
			return k * k * k - x * x * y * y * y <= 0.0 and not (absf(u) < 1.0 and v < -3.6)
		"ac":
			if v < -6.0:
				return false
			var hw := 5.8 if v < 0.5 else 5.8 * (1.0 - (v - 0.5) / 6.8)
			return absf(u) <= hw and v <= 7.0
		"ms":
			var shaft := absf(v) <= 1.6 and u >= -6.5 and u <= 1.0
			var head := u >= 0.0 and u <= 6.5 and absf(v) <= (6.5 - u) * 0.95
			var tail := u >= -6.5 and u <= -3.5 and absf(v) <= 4.5 and absf(v) >= 2.6 and absf(v) <= 4.5 - (u + 6.5) * 0.3
			return shaft or head or tail
		"nrg":
			return Geometry2D.is_point_in_polygon(Vector2(u, v), PackedVector2Array([Vector2(1.5, -7.2), Vector2(-4.8, 1.2), Vector2(-0.4, 1.2), Vector2(-2.4, 7.4), Vector2(5.0, -1.2), Vector2(0.8, -1.2), Vector2(3.8, -7.2)]))
		"aether":
			return absf(u) / 5.8 + absf(v) / 7.4 <= 1.0 and absf(u) / 2.4 + absf(v) / 3.2 > 1.0
		"skull":
			var head := sqrt(u * u + (v + 1.2) * (v + 1.2)) <= 5.8
			var jaw := absf(u) <= 3.4 and v >= 2.0 and v <= 6.6
			var eye := sqrt((absf(u) - 2.3) * (absf(u) - 2.3) + (v + 0.2) * (v + 0.2)) <= 1.5
			var nose := absf(u) <= 0.6 and v >= 2.0 and v <= 3.2
			var teeth := v >= 5.0 and v <= 6.6 and (int(floor(u + 8.0)) % 2 == 0)
			return (head or jaw) and not eye and not nose and not teeth
		# (0.12) the speed button's: not slots of their own
		"speed_normal":
			return _tri(-4.0, 5.0, u, v)
		"speed_fast":
			return _tri(-7.0, 0.5, u, v) or _tri(-0.5, 7.0, u, v)
		"speed_instant":
			return _tri(-7.5, -0.5, u, v) or _tri(-1.5, 5.0, u, v) or (u >= 5.0 and u <= 7.5 and absf(v) <= 5.5)
	return false


## A triangle pointing right, from u0 to u1, 11 pixels high at its back.
static func _tri(u0: float, u1: float, u: float, v: float) -> bool:
	return u >= u0 and u <= u1 and absf(v) <= (u1 - u) * 5.5 / (u1 - u0)


const ICON_COLOUR := {"shards": "#97edca", "part_troop": "#59cf93", "part_equipment": "#d6a851", "part_aether": "#8aa1f6",
	"hp": "#ff2a3c", "ac": "#88a3bc", "ms": "#73efe8", "nrg": "#f8c53a", "aether": "#8aa1f6", "skull": "#e8dcc4",
	"speed_normal": "#e6e7f0", "speed_fast": "#e6e7f0", "speed_instant": "#e6e7f0"}


## An icon as the game draws it: its shape filled, lit along its top and left
## edges and shaded along the others, and outlined.
static func icon_image(id: String) -> Image:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var base := nearest(Color(ICON_COLOUR.get(id, "#c5c7dd")))
	var lit := nearest(base.lightened(0.35))
	var shade := nearest(base.darkened(0.38))
	var shine := nearest(base.lightened(0.15))
	var inside := func(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < 16 and y < 16 and _inside(id, x + 0.5 - 8.0, y + 0.5 - 8.0)
	for y in 16:
		for x in 16:
			if not inside.call(x, y):
				continue
			var c := base
			if not inside.call(x, y - 1) or not inside.call(x - 1, y):
				c = lit
			elif not inside.call(x, y + 1) or not inside.call(x + 1, y):
				c = shade
			elif id == "shards" and x < 7:
				c = shine
			img.set_pixel(x, y, c)
	if id == "part_aether":
		img.set_pixel(6, 5, nearest(Color("#f1f2ff")))
		img.set_pixel(5, 6, nearest(Color("#f1f2ff")))
	# the outline: every empty pixel beside a filled one
	var out := img.duplicate()
	for y in 16:
		for x in 16:
			if img.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var p: Vector2i = Vector2i(x, y) + d
				if p.x >= 0 and p.y >= 0 and p.x < 16 and p.y < 16 and img.get_pixel(p.x, p.y).a > 0.0:
					out.set_pixel(x, y, OUTLINE)
					break
	return out


# ---------------------------------------------------------------- backdrops
## Ordered dithering: whether pixel x, y takes the next colour at this share (0 to 1).
static func _dither(x: int, y: int, share: float) -> bool:
	const B := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
	return share * 16.0 > B[(y % 4) * 4 + (x % 4)] + 0.5


## A sky that runs through these colours top to bottom, dithered between them.
static func _sky(img: Image, stops: Array, top: int, bottom: int) -> void:
	var w := img.get_width()
	for y in range(top, bottom):
		var t := float(y - top) / maxf(1.0, float(bottom - top - 1)) * (stops.size() - 1)
		var i := mini(int(floor(t)), stops.size() - 2)
		var f := t - i
		for x in w:
			img.set_pixel(x, y, Color(stops[i + 1]) if _dither(x, y, f) else Color(stops[i]))


static func _stars(img: Image, rng: RandomNumberGenerator, n: int, bottom: int) -> void:
	for i in n:
		var x := rng.randi_range(0, img.get_width() - 1)
		var y := rng.randi_range(0, bottom)
		img.set_pixel(x, y, Color("#c5c7dd") if rng.randf() < 0.25 else Color("#5a6da6"))


## A ridge of the Martian hills along the horizon.
static func _ridge(img: Image, rng: RandomNumberGenerator, base_y: int, height: float, colour: Color) -> void:
	var w := img.get_width()
	var a := rng.randf() * TAU
	var b := rng.randf() * TAU
	for x in w:
		var top := base_y - int(height * (0.55 + 0.3 * sin(x * 0.031 + a) + 0.15 * sin(x * 0.11 + b)))
		for y in range(maxi(0, top), img.get_height()):
			img.set_pixel(x, y, colour)


## The colony: towers in silhouette, a few windows lit.
static func _skyline(img: Image, rng: RandomNumberGenerator, ground_y: int, tallest: int, body: Color, edge: Color, gap := Vector2i(-1, -1)) -> void:
	var w := img.get_width()
	var x := rng.randi_range(-6, 4)
	while x < w:
		var tw := rng.randi_range(6, 22)
		var th := rng.randi_range(int(tallest * 0.3), tallest)
		if x + tw > gap.x and x < gap.y:
			# low buildings only, in the gap
			th = mini(th, int(tallest * 0.3))
		var top := ground_y - th
		for yy in range(maxi(0, top), ground_y):
			for xx in range(maxi(0, x), mini(w, x + tw)):
				img.set_pixel(xx, yy, edge if xx == x else body)
		# a stepped crown, or a mast
		if rng.randf() < 0.4 and tw > 9:
			for yy in range(maxi(0, top - 4), top):
				for xx in range(maxi(0, x + 3), mini(w, x + tw - 3)):
					img.set_pixel(xx, yy, body)
		if rng.randf() < 0.3:
			var mx := x + tw / 2
			for yy in range(maxi(0, top - rng.randi_range(6, 14)), top):
				if mx >= 0 and mx < w:
					img.set_pixel(mx, yy, edge)
			if mx >= 0 and mx < w and top - 14 >= 0:
				img.set_pixel(mx, maxi(0, top - 14), Color("#ff2a3c"))
		# windows
		for yy in range(top + 3, ground_y - 2, 4):
			for xx in range(x + 2, x + tw - 2, 3):
				if xx >= 0 and xx < w and rng.randf() < 0.18:
					img.set_pixel(xx, yy, Color("#d6a851") if rng.randf() < 0.7 else Color("#73efe8"))
		x += tw + rng.randi_range(0, 5)


static func backdrop_image(kind: String) -> Image:
	var img := Image.create(BW, BH, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	match kind:
		"title":
			rng.seed = 11
			_sky(img, ["#050403", "#14121d", "#2d1b1e", "#612721", "#b9451d"], 0, BH)
			_stars(img, rng, 72, 72)
			# the sun, low and red through the dust
			# (off to the right: Home's words sit in the middle)
			for y in range(74, BH):
				for x in range(170, 226):
					var d := Vector2(x - 198, y - 104).length()
					if d <= 24.0:
						var c := Color("#f8c53a") if d < 12.0 else Color("#f1641f")
						if d < 18.0 or _dither(x, y, (24.0 - d) / 6.0):
							img.set_pixel(x, y, c)
			_ridge(img, rng, 120, 18.0, Color("#2d1b1e"))
			# the colony, parted where the sun sets
			_skyline(img, rng, 141, 52, Color("#0e0c0c"), Color("#171516"), Vector2i(172, 224))
			for y in range(141, BH):
				for x in BW:
					img.set_pixel(x, y, Color("#050403"))
		"dock":
			rng.seed = 23
			# the colony through the dock's great window
			_sky(img, ["#050403", "#14121d", "#2a1e23", "#4f342f"], 0, 96)
			_stars(img, rng, 40, 48)
			_ridge(img, rng, 90, 12.0, Color("#2d1b1e"))
			_skyline(img, rng, 96, 40, Color("#14121d"), Color("#282c3c"))
			# the hangar: its frame, ribs and floor
			for y in BH:
				for x in BW:
					var frame := y < 10 or y >= 96 or x < 8 or x >= BW - 8 or (x % 64 >= 60)
					if frame:
						var c := Color("#171819")
						if y >= 96:
							c = Color("#2c3438") if _dither(x, y, 0.5 - (y - 96) / 96.0) else Color("#171819")
						if x % 64 == 60 or y == 9:
							c = Color("#406977")
						img.set_pixel(x, y, c)
			# a hazard stripe along the deck, and the gantry's lights
			for y in range(133, 138):
				for x in BW:
					img.set_pixel(x, y, Color("#d6a851") if ((x + y) / 4) % 2 == 0 else Color("#0e0c0c"))
			for x in range(24, BW - 20, 26):
				img.set_pixel(x, 4, Color("#73efe8"))
				img.set_pixel(x + 1, 4, Color("#73efe8"))
		_:
			rng.seed = 37
			_sky(img, ["#050403", "#0e0c0c", "#14121d", "#2a1e23"], 0, BH)
			_stars(img, rng, 56, 88)
			_ridge(img, rng, 120, 15.0, Color("#2d1b1e"))
			_skyline(img, rng, 138, 45, Color("#0e0c0c"), Color("#171516"))
			for y in range(138, BH):
				for x in BW:
					img.set_pixel(x, y, Color("#050403"))
	return img


## The floor under a fight: a metal deck plate, its seams and rivets.
static func floor_image() -> Image:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for y in 64:
		for x in 64:
			var c := Color("#2c3438")
			var n := rng.randf()
			if n < 0.18:
				c = Color("#282c3c")
			elif n > 0.93:
				c = Color("#3e4246")
			if x == 0 or y == 0 or x == 32 and y < 32 or y == 32 and x >= 32:
				c = Color("#171819")
			elif x == 1 or y == 1 or x == 33 and y < 32 or y == 33 and x >= 32:
				c = Color("#3e4246")
			img.set_pixel(x, y, c)
	for p in [Vector2i(4, 4), Vector2i(28, 4), Vector2i(4, 28), Vector2i(36, 36), Vector2i(60, 36), Vector2i(36, 60), Vector2i(60, 60), Vector2i(28, 28)]:
		img.set_pixel(p.x, p.y, Color("#6a7178"))
		img.set_pixel(p.x + 1, p.y + 1, Color("#171819"))
	# a scratch or two
	for i in 3:
		var x := rng.randi_range(6, 56)
		var y := rng.randi_range(6, 56)
		for k in rng.randi_range(3, 7):
			if x + k < 64 and y + k / 2 < 64:
				img.set_pixel(x + k, y + k / 2, Color("#3e4246"))
	return img


## A board tile's edge, at half scale: its outline dark, its top-left rim
## lit and its bottom-right rim shaded, the middle clear.
static func ring_image(size: float) -> Image:
	var hs := size / 2.0
	var w := int(ceil(Hex.SQ3 * hs))
	var h := int(ceil(2.0 * hs))
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var inside := func(x: int, y: int) -> bool:
		if x < 0 or y < 0 or x >= w or y >= h:
			return false
		var u := absf(x + 0.5 - w / 2.0)
		var v := absf(y + 0.5 - h / 2.0)
		return u <= Hex.SQ3 * hs / 2.0 - 0.5 and v <= hs - u / Hex.SQ3 - 0.5
	for y in h:
		for x in w:
			if not inside.call(x, y):
				continue
			var edge := false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if not inside.call(x + d.x, y + d.y):
					edge = true
			if edge:
				img.set_pixel(x, y, Color("#0e0c0c"))
			elif not inside.call(x, y - 2) or not inside.call(x - 2, y):
				img.set_pixel(x, y, Color(1, 1, 1, 0.16))
			elif not inside.call(x, y + 2) or not inside.call(x + 2, y):
				img.set_pixel(x, y, Color(0, 0, 0, 0.28))
	return img
