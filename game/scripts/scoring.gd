## What an ability is worth: its power. (The Companion's scoring.js, the part
## the Workshop uses.)
##
## An effect's keywords are machine-readable, so its score is worked out from
## them, and a design's copies cost in step with it:
##
## - Everything but a Modifier adds into a base value: a keyword's weight,
##   times its number where it has one.
## - An attack counts for 4 of its own, and a Modifier with nothing else to
##   act on is modifying the attack.
## - Modifiers multiply that base: Burst 3 makes three attacks, so it triples
##   what it bursts. Several multiply together.
##
## Proved to score what scoring.js scores (tests/workshop_diff.gd).
class_name Scoring
extends RefCounted

const ATTACK_BASE := 4


## JavaScript's parseFloat: a number as it is, the number a text begins with,
## or NaN.
static func parse_float(v) -> float:
	if v is int:
		return float(v)
	if v is float:
		return v
	if v == null or v is bool:
		return NAN
	var m := Keywords._re("^[\\s]*([+-]?(?:Infinity|(?:\\d+\\.?\\d*|\\.\\d+)(?:[eE][+-]?\\d+)?))").search(str(v))
	if m == null:
		return NAN
	var t := m.get_string(1)
	if t.ends_with("Infinity"):
		return -INF if t.begins_with("-") else INF
	return t.to_float()


## JavaScript's unary plus: what a value is as a number, or NaN.
static func plus(v) -> float:
	if v == null:
		return 0.0
	if v is bool:
		return 1.0 if v else 0.0
	if v is int:
		return float(v)
	if v is float:
		return v
	if v is String or v is StringName:
		var t := str(v).strip_edges()
		if t == "":
			return 0.0
		return t.to_float() if t.is_valid_float() else NAN
	return NAN


## workshop.js's and chassis.js's num(v, d): parseFloat, or d where that is no number.
static func num(v, d: float = 0.0) -> float:
	var x := parse_float(v)
	return d if is_nan(x) else x


## JavaScript's parseInt of what is left of a text once everything but digits
## and minus signs is taken out: null where that is no number.
static func digits(v) -> Variant:
	var s := Keywords._re("[^0-9-]").sub(str(v) if Rules.truthy(v) else "", "", true)
	var m := Keywords._re("^-?\\d+").search(s)
	return int(m.get_string(0)) if m != null else null


## A number as JavaScript prints it: 3, not 3.0.
static func text(v) -> String:
	if v is int:
		return str(v)
	if v is float:
		if is_nan(v):
			return "NaN"
		if is_inf(v):
			return "-Infinity" if v < 0 else "Infinity"
		return str(int(v)) if v == floor(v) and absf(v) < 1.0e15 else str(v)
	return str(v)


static func _mult(name: String, n: float) -> Variant:
	match name.to_lower():
		"burst": return maxf(1.0, n)                 # n attacks in all
		"aoe": return 1.0 + maxf(0.0, n)             # more Units in reach
		"chain": return 1.5 + 0.1 * maxf(0.0, n)     # one more hit, farther with reach
		"pierce": return 1.4                         # the Unit behind, when there is one
		"suppressive fire": return 1.3               # a reaction shot as well
		"overclock": return 1.0                      # carries no rules yet (effects.gd), so it costs nothing
		"aura": return 1.0 + 0.5 * maxf(0.0, n)      # everyone within reach, continuously
		# Revision 16.3: a line reaches a Unit or two more, a cone about what AoE 1 does
		"line": return 1.0 + 0.25 * maxf(0.0, n)
		"cone": return 1.0 + 0.5 * maxf(0.0, n)
	return null


## {base, mult, mods: [{name, x}], points}, or null for text with no keywords
## that isn't an attack.
## Handbook 16.0: an area Target makes its sentence's effects cost
## (1 + 0.5 x radius) times as much: x1.5 at 1, x2 at 2, x2.5 at 3.
const AREA_TARGETS := ["all enemies within", "all allies within", "all units within"]
## Revision 16.3: a whole side, wherever it stands, counts like an area of 4 tiles (x3)
const WHOLE_SIDE := {"all enemies": 4, "all allies": 4}
## Revision 16.1: Lunge and Charge add to an attack rather than multiply it:
## a tile of reach, or a point of damage, at the keyword's weight
const ADDING_MODIFIERS := ["lunge", "charge"]


static func area_factor(r: float) -> float:
	return 1.0 + 0.5 * maxf(0.0, r)


static func keyword_detail(text, attack := false) -> Variant:
	var is_kw := func(p): return p["type"] == "kw" and p.get("kw") != null
	if Keywords.parse(text if text != null else "").filter(is_kw).is_empty() and not attack:
		return null
	var base: float = float(ATTACK_BASE) if attack else 0.0
	var mult := 1.0
	var mods := []
	for sent in Keywords.sentences(text if text != null else ""):
		var sum := 0.0
		var area := 1.0
		for p in Keywords.parse(sent).filter(is_kw):
			var kw: Dictionary = p["kw"]
			var n = digits(p.get("n"))
			if kw.get("cat") == "modifier" and not ADDING_MODIFIERS.has(str(kw.get("name")).to_lower()):
				var f = _mult(str(kw.get("name")), 1.0 if n == null else absf(float(n)))
				var m: float = f if f != null else 1.0
				mult *= m
				mods.append({"name": kw["name"], "x": m})
				continue
			if AREA_TARGETS.has(kw.get("name")):
				area = maxf(area, area_factor(1.0 if n == null else absf(float(n))))
				continue
			if WHOLE_SIDE.has(kw.get("name")):
				area = maxf(area, area_factor(float(WHOLE_SIDE[kw["name"]])))
				continue
			var w: float = 1.0 if kw.get("weight") == null else float(kw["weight"])
			sum += (w * absf(float(n))) if (Rules.truthy(kw.get("num")) and n != null) else w
		if area != 1.0:
			mods.append({"name": "area", "x": area})
		base += sum * area
	if base == 0.0 and mult != 1.0:
		base = float(ATTACK_BASE)
	return {"base": base, "mult": mult, "mods": mods, "points": int(Rules.js_round(base * mult))}


static func keyword_points(text, attack := false) -> Variant:
	var d = keyword_detail(text, attack)
	return d["points"] if d != null else null


## One ability's power: the number given for it, else its keywords, else 4.
static func ability_power(entry) -> int:
	var e: Dictionary = entry if entry is Dictionary else {}
	var role := str(e["role"] if Rules.truthy(e.get("role")) else "").to_lower()
	if e.has("power") and e["power"] != null and not (e["power"] is String and e["power"] == ""):
		var v = Rules.num(e["power"], 0)
		return int(v) if Rules.truthy(v) else 0
	var kw = keyword_points(e["text"] if Rules.truthy(e.get("text")) else "", role == "melee" or role == "ranged" or role == "cyber")
	return 4 if kw == null else kw
