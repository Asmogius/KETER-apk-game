## Hex maths for KETER's boards: axial coordinates (q, r) on pointy-top hexes,
## the same layout the Companion's Sandbox and Battle Simulator use:
##   x = sqrt(3) * size * (q + r / 2),  y = 1.5 * size * r
class_name Hex
extends RefCounted

const SQ3 := 1.7320508075688772
## The six neighbours, in the Sandbox's order.
const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)]


## "q,r" (the Companion's key) to a coordinate.
static func parse(key: String) -> Vector2i:
	var p := key.split(",")
	if p.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(p[0]), int(p[1]))


static func key(h: Vector2i) -> String:
	return "%d,%d" % [h.x, h.y]


## The centre of a hex, for hexes of this size (centre to corner).
static func to_pixel(h: Vector2i, size: float) -> Vector2:
	return Vector2(SQ3 * size * (h.x + h.y / 2.0), 1.5 * size * h.y)


## The hex under a point.
static func from_pixel(p: Vector2, size: float) -> Vector2i:
	var q := (SQ3 / 3.0 * p.x - p.y / 3.0) / size
	var r := (2.0 / 3.0 * p.y) / size
	return round_cube(q, r)


static func round_cube(q: float, r: float) -> Vector2i:
	var s := -q - r
	var rq := roundf(q)
	var rr := roundf(r)
	var rs := roundf(s)
	var dq := absf(rq - q)
	var dr := absf(rr - r)
	var ds := absf(rs - s)
	if dq > dr and dq > ds:
		rq = -rr - rs
	elif dr > ds:
		rr = -rq - rs
	return Vector2i(int(rq), int(rr))


static func distance(a: Vector2i, b: Vector2i) -> int:
	var dq := a.x - b.x
	var dr := a.y - b.y
	return (absi(dq) + absi(dr) + absi(dq + dr)) / 2


static func neighbours(h: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in DIRS:
		out.append(h + d)
	return out


## The six corners of a hex, pointy at the top, clockwise from the upper right.
static func corners(centre: Vector2, size: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var a := deg_to_rad(60.0 * i - 30.0)
		pts.append(centre + Vector2(cos(a), sin(a)) * size)
	return pts


## The edge two neighbouring hexes share, as its two end points (for walls).
static func shared_edge(a: Vector2i, b: Vector2i, size: float) -> PackedVector2Array:
	var d := b - a
	var i := DIRS.find(d)
	if i < 0:
		return PackedVector2Array()
	var c := to_pixel(a, size)
	# the edge facing direction i lies between corners i-1 and i (pointy-top)
	var ang: float = [0.0, 60.0, 120.0, 180.0, 240.0, 300.0][i]
	var a1 := deg_to_rad(ang - 30.0)
	var a2 := deg_to_rad(ang + 30.0)
	return PackedVector2Array([c + Vector2(cos(a1), sin(a1)) * size, c + Vector2(cos(a2), sin(a2)) * size])
