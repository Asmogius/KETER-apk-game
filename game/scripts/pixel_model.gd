## The Pixel Studio's model of a picture (0.30), as the Companion keeps one
## (pixelart.js): w by h palette colours, one byte a pixel, 0 transparent,
## 1 to 195 the palette (Art.PALETTE: AAP-Splendor128, its neons, KETER 56),
## 196 to 255 colours of the picture's own (custom: {index: "#rrggbb"}).
## Stored as {v, w, h, name, frames: [{layers: [{name, visible, locked,
## opacity, mode, px}]}], flat, custom}, px and flat run-length encoded and
## base64'd, so a picture made in the game's studio is one the Companion's
## opens as it is.
##
## The game's studio (studio_screen.gd) draws on one layer: a picture of the
## Companion's with several is flattened when it is opened here.
class_name PixelModel
extends RefCounted

const CUSTOM_FROM := 196
const PAL_MAX := 255
const ART_WIDTHS := [128, 64]
const TOKEN_SIZES := [48, 32, 24, 16]
const BLANK_SIZES := [[16, 16], [32, 32], [48, 48], [64, 64], [128, 128], [64, 32], [128, 64], [256, 144]]


# ---------------------------------------------------------------- storage
## Runs of (count, colour), as base64: the Companion's encode().
static func encode(px: PackedByteArray) -> String:
	var out := PackedByteArray()
	var i := 0
	var n := px.size()
	while i < n:
		var v := px[i]
		var run := 1
		while i + run < n and px[i + run] == v and run < 255:
			run += 1
		out.append(run)
		out.append(v)
		i += run
	return Marshalls.raw_to_base64(out) if not out.is_empty() else ""


static func decode(s: String, n: int) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(n)
	if s == "":
		return out
	var b := Marshalls.base64_to_raw(s)
	var o := 0
	var i := 0
	while i + 1 < b.size() and o < n:
		var run := b[i]
		var v := b[i + 1]
		for r in run:
			if o >= n:
				break
			out[o] = v
			o += 1
		i += 2
	return out


# ---------------------------------------------------------------- pictures
## A blank picture, one layer.
static func blank(w: int, h: int, name := "") -> Dictionary:
	var px := PackedByteArray()
	px.resize(w * h)
	return make(w, h, px, {}, name)


## A picture of these pixels (the flat copy made from them).
static func make(w: int, h: int, px: PackedByteArray, custom: Dictionary, name := "") -> Dictionary:
	var e := encode(px)
	var pic := {"v": 1, "w": w, "h": h, "name": name, "frames": [{"layers": [{"name": "Layer 1", "visible": true, "locked": false, "opacity": 100, "mode": "view", "px": e}]}], "flat": e}
	var used := {}
	for v in px:
		if v >= CUSTOM_FROM:
			used[v] = true
	var keep := {}
	for k in used:
		if custom.has(k):
			keep[str(k)] = ("#" + (custom[k] as Color).to_html(false)) if custom[k] is Color else str(custom[k])
	if not keep.is_empty():
		pic["custom"] = keep
	return pic


## A picture's pixels, its visible layers laid over each other (the first frame).
static func pixels(pic: Dictionary) -> PackedByteArray:
	var w := int(pic.get("w", 0))
	var h := int(pic.get("h", 0))
	var n := w * h
	var frames: Array = pic["frames"] if pic.get("frames") is Array else []
	if frames.is_empty() or not (frames[0] is Dictionary) or not (frames[0].get("layers") is Array):
		return decode(str(pic.get("flat", "")), n)
	var out := PackedByteArray()
	out.resize(n)
	for L in frames[0]["layers"]:
		if not (L is Dictionary) or L.get("visible") == false:
			continue
		var px := decode(str(L.get("px", "")), n)
		for i in n:
			if px[i] != 0:
				out[i] = px[i]
	return out


## The picture's own colours: index -> Color.
static func customs(pic: Dictionary) -> Dictionary:
	var out := {}
	if pic.get("custom") is Dictionary:
		for k in pic["custom"]:
			out[int(k)] = Color(str(pic["custom"][k]))
	return out


## The colour of an index (0: transparent).
static func colour(i: int, custom: Dictionary = {}) -> Color:
	if i <= 0:
		return Color(0, 0, 0, 0)
	if i < CUSTOM_FROM:
		return Art.palette()[i - 1]
	return custom.get(i, Color.MAGENTA)


static func to_image(w: int, h: int, px: PackedByteArray, custom: Dictionary = {}) -> Image:
	var img := Image.create_empty(maxi(1, w), maxi(1, h), false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var v := px[y * w + x]
			if v != 0:
				img.set_pixel(x, y, colour(v, custom))
	return img


static func image_of(pic: Dictionary) -> Image:
	return to_image(int(pic["w"]), int(pic["h"]), pixels(pic), customs(pic))


## A picture from an image: each pixel the palette's colour that matches it,
## else one of the picture's own (up to 60 of them), else the nearest.
## Returns {w, h, px, custom}.
static func from_image(img: Image) -> Dictionary:
	var w := img.get_width()
	var h := img.get_height()
	var px := PackedByteArray()
	px.resize(w * h)
	var index := {}
	var pal := Art.palette()
	for i in pal.size():
		index[pal[i].to_html(false)] = i + 1
	var custom := {}
	var next := CUSTOM_FROM
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var k := c.to_html(false)
			if not index.has(k):
				if next <= PAL_MAX:
					index[k] = next
					custom[next] = Color(c.r, c.g, c.b, 1.0)
					next += 1
				else:
					index[k] = nearest(c)
			px[y * w + x] = int(index[k])
	return {"w": w, "h": h, "px": px, "custom": custom}


static func nearest(c: Color) -> int:
	var best := 1
	var far := INF
	var pal := Art.palette()
	for i in pal.size():
		var p := pal[i]
		var d := (p.r - c.r) * (p.r - c.r) * 0.3 + (p.g - c.g) * (p.g - c.g) * 0.59 + (p.b - c.b) * (p.b - c.b) * 0.11
		if d < far:
			far = d
			best = i + 1
	return best


# ---------------------------------------------------------------- drawing
## The pixels a brush of this size covers about (x, y): square or round.
static func brush(x: int, y: int, size: int, round_tip := false) -> Array:
	var out := []
	var lo := -int((size - 1) / 2)
	for dy in range(lo, lo + size):
		for dx in range(lo, lo + size):
			if round_tip and size > 2:
				var cx := dx - lo - (size - 1) / 2.0
				var cy := dy - lo - (size - 1) / 2.0
				if cx * cx + cy * cy > (size / 2.0) * (size / 2.0) + 0.25:
					continue
			out.append(Vector2i(x + dx, y + dy))
	return out


## A straight run of pixels (Bresenham).
static func line(a: Vector2i, b: Vector2i) -> Array:
	var out := []
	var x0 := a.x
	var y0 := a.y
	var dx := absi(b.x - x0)
	var dy := -absi(b.y - y0)
	var sx := 1 if x0 < b.x else -1
	var sy := 1 if y0 < b.y else -1
	var err := dx + dy
	while true:
		out.append(Vector2i(x0, y0))
		if x0 == b.x and y0 == b.y:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy
	return out


static func rect(a: Vector2i, b: Vector2i, fill: bool) -> Array:
	var out := []
	for y in range(mini(a.y, b.y), maxi(a.y, b.y) + 1):
		for x in range(mini(a.x, b.x), maxi(a.x, b.x) + 1):
			if fill or x == a.x or x == b.x or y == a.y or y == b.y:
				out.append(Vector2i(x, y))
	return out


## An ellipse inside the box from a to b.
static func ellipse(a: Vector2i, b: Vector2i, fill: bool) -> Array:
	var x0 := mini(a.x, b.x)
	var x1 := maxi(a.x, b.x)
	var y0 := mini(a.y, b.y)
	var y1 := maxi(a.y, b.y)
	var cx := (x0 + x1) / 2.0
	var cy := (y0 + y1) / 2.0
	var rx := (x1 - x0) / 2.0 + 0.5
	var ry := (y1 - y0) / 2.0 + 0.5
	var inside := {}
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var dx := (x - cx) / rx
			var dy := (y - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				inside[Vector2i(x, y)] = true
	if fill:
		return inside.keys()
	var out := []
	for p in inside:
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if not inside.has(p + d):
				out.append(p)
				break
	return out


## A pixel and its mirror images: mode "", "x" (left and right), "y" (top and bottom), "xy".
static func mirrored(p: Vector2i, w: int, h: int, mode: String) -> Array:
	var out := [p]
	if "x" in mode:
		out.append(Vector2i(w - 1 - p.x, p.y))
	if "y" in mode:
		out.append(Vector2i(p.x, h - 1 - p.y))
	if mode == "xy":
		out.append(Vector2i(w - 1 - p.x, h - 1 - p.y))
	return out


## Fills the area of one colour about (x, y) with v. Returns how many pixels changed.
static func fill(px: PackedByteArray, w: int, h: int, x: int, y: int, v: int) -> int:
	if x < 0 or y < 0 or x >= w or y >= h:
		return 0
	var from := px[y * w + x]
	if from == v:
		return 0
	var n := 0
	var stack := [Vector2i(x, y)]
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or px[p.y * w + p.x] != from:
			continue
		px[p.y * w + p.x] = v
		n += 1
		stack.append(p + Vector2i(1, 0))
		stack.append(p + Vector2i(-1, 0))
		stack.append(p + Vector2i(0, 1))
		stack.append(p + Vector2i(0, -1))
	return n
