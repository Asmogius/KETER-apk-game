## The Aether you have this turn, as gems (0.14): one for each point, in its
## District's colour (Aether of any kind is white). Past ten, a number.
class_name AetherGems
extends Control

const GEM := 16.0              # a gem's 8 pixels, at twice their size
const STEP := 14.0
const MOST := 10             # (past ten, a number: the bar has room for the rest)

var pool := {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(46, 18)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func show_pool(p: Dictionary) -> void:
	pool = p.duplicate()
	size = Vector2(width(), GEM)
	queue_redraw()


## The gems, in order: [gem key, ...].
func gems() -> Array:
	var keys: Array = pool.keys()
	keys.sort()
	var out := []
	for k in keys:
		var n := int(Rules.num(pool[k], 0)) if Rules.truthy(pool[k]) else 0
		var g := "gem_any" if k == "generic" else "gem_" + str(k).substr(1)
		for i in n:
			out.append(g)
	return out


func width() -> float:
	var n := gems().size()
	if n == 0:
		return 22.0
	return STEP * mini(n, MOST) + 4.0 + (30.0 if n > MOST else 0.0)


func _draw() -> void:
	var list := gems()
	if list.is_empty():
		draw_string(Look.font(), Vector2(2, 14), "—", HORIZONTAL_ALIGNMENT_LEFT, -1, Look.SMALL, UI.DIM)
		return
	for i in mini(list.size(), MOST):
		var tex := Art.status_mark(str(list[i]))
		if tex != null:
			draw_set_transform(Vector2(i * STEP, 0), 0.0, Vector2(2, 2))
			draw_texture(tex, Vector2.ZERO)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if list.size() > MOST:
		draw_string(Look.font(), Vector2(MOST * STEP + 4.0, 15), "+%d" % (list.size() - MOST), HORIZONTAL_ALIGNMENT_LEFT, -1, Look.SMALL, UI.TEXT)
