## KETER rules resolver, brought across from the Companion's rules.js (v13.1).
##
## The rules of combat, with nothing else attached: no drawing, no saving. A
## function that changes a Unit returns a list of events describing what
## happened; the caller decides whether to log them, draw them, or ignore them.
##
## Units, Actions and events are plain Dictionaries with the same keys as in
## the Companion, so the two can be compared case by case (tests/rules_*.gd).
## Where JavaScript and GDScript differ (parseInt, Math.round, a stable sort),
## the JavaScript behaviour is copied exactly: this is the same game.
##
## Since game 0.2 this file owns the combat rules. The Companion's rules.js is
## frozen; a rule changes here, and only here.
class_name Rules
extends RefCounted

const VERSION := "1.0"

## Handbook behaviour keywords: nine for Enemies, twelve for the Player's side.
const BEHAVIORS := [
	{"k": "cunning", "name": "Cunning", "side": "enemy", "cat": "target", "cond": false, "text": "Attacks the nearest Hero."},
	{"k": "sadistic", "name": "Sadistic", "side": "enemy", "cat": "target", "cond": false, "text": "Attacks the Unit with the lowest current Health."},
	{"k": "opportunistic", "name": "Opportunistic", "side": "enemy", "cat": "target", "cond": false, "text": "Attacks the Unit with the lowest Armor Class."},
	{"k": "brutish", "name": "Brutish", "side": "enemy", "cat": "target", "cond": false, "text": "Attacks the Unit with the highest Armor Class."},
	{"k": "vindictive", "name": "Vindictive", "side": "enemy", "cat": "target", "cond": true, "text": "Attacks the last Unit that attacked it."},
	{"k": "ravenous", "name": "Ravenous", "side": "enemy", "cat": "target", "cond": true, "text": "Attacks a Unit another Enemy has already attacked this round."},
	{"k": "methodical", "name": "Methodical", "side": "enemy", "cat": "target", "cond": true, "text": "Attacks a Unit with no Enemy-applied status on it."},
	{"k": "cautious", "name": "Cautious", "side": "enemy", "cat": "move", "cond": true, "param": "tiles", "pdef": 2, "text": "Moves away from any Player Unit within X tiles, then acts normally."},
	{"k": "cowardly", "name": "Cowardly", "side": "enemy", "cat": "move", "cond": true, "param": "Health", "pdef": 5, "text": "At X Health or below, moves away from the closest Player Unit and takes no Action."},
	{"k": "valiant", "name": "Valiant", "side": "ally", "cat": "target", "cond": false, "text": "Attacks the nearest Boss or Mini-Boss, ignoring lesser Enemies."},
	{"k": "decisive", "name": "Decisive", "side": "ally", "cat": "target", "cond": false, "text": "Attacks the Enemy with the lowest current Health."},
	{"k": "precise", "name": "Precise", "side": "ally", "cat": "target", "cond": false, "text": "Attacks the Enemy with the lowest Armor Class."},
	{"k": "dauntless", "name": "Dauntless", "side": "ally", "cat": "target", "cond": false, "text": "Attacks the Enemy with the highest Armor Class."},
	{"k": "defiant", "name": "Defiant", "side": "ally", "cat": "target", "cond": true, "text": "Attacks the last Enemy that attacked it."},
	{"k": "coordinated", "name": "Coordinated", "side": "ally", "cat": "target", "cond": true, "text": "Attacks an Enemy an ally has already attacked this round."},
	{"k": "thorough", "name": "Thorough", "side": "ally", "cat": "target", "cond": true, "text": "Attacks an Enemy carrying no status yet."},
	{"k": "wary", "name": "Wary", "side": "ally", "cat": "move", "cond": true, "param": "tiles", "pdef": 2, "text": "Moves away from any Enemy within X tiles, then acts normally."},
	{"k": "prudent", "name": "Prudent", "side": "ally", "cat": "move", "cond": true, "param": "Health", "pdef": 5, "text": "At X Health or below, withdraws and takes no Action."},
	{"k": "steadfast", "name": "Steadfast", "side": "ally", "cat": "move", "cond": false, "text": "Holds its tile and does not move."},
	{"k": "medic", "name": "Medic", "side": "ally", "cat": "support", "cond": true, "text": "Uses a Support Action on the most wounded ally before attacking."},
	{"k": "guardian", "name": "Guardian", "side": "ally", "cat": "support", "cond": false, "text": "Stays within 1 tile of your Hero rather than chasing targets."},
]

## Revision 15.6: whatever is listening for "gains [Status]" or "takes damage"
## is told here: hooks.status(unit, name) and hooks.hit(unit, amount).
static var hooks := {}


static func behaviors() -> Array:
	return BEHAVIORS


static func beh_of(k) -> Variant:
	for b in BEHAVIORS:
		if b["k"] == k:
			return b
	return null


# ================================================================== JavaScript's rules
## parseInt(v, 10), with a default for NaN: "3.7" is 3, "12abc" is 12, null is d.
static func num(v, d = 0):
	if v == null or v is bool:
		return d
	if v is int:
		return v
	if v is float:
		if is_nan(v) or is_inf(v):
			return d
		return int(v)   # parseInt of a number reads its digits: truncates toward zero
	var s := str(v).strip_edges(true, false)
	var i := 0
	var neg := false
	if i < s.length() and (s[i] == "+" or s[i] == "-"):
		neg = s[i] == "-"
		i += 1
	var start := i
	while i < s.length() and s.unicode_at(i) >= 48 and s.unicode_at(i) <= 57:
		i += 1
	if i == start:
		return d
	var n := int(s.substr(start, i - start))
	return -n if neg else n


## Math.round: halves go up, toward +infinity.
static func js_round(x: float) -> float:
	return floor(x + 0.5)


## JSON read by Godot makes every number a float; JavaScript sees 3, not 3.0.
## This turns whole-number floats back into ints, all the way down.
static func ints(v):
	if v is float:
		return int(v) if v == floor(v) and absf(v) < 9.0e15 else v
	if v is Array:
		var a := []
		for x in v:
			a.append(ints(x))
		return a
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = ints(v[k])
		return d
	return v


## JavaScript truthiness.
static func truthy(v) -> bool:
	if v == null:
		return false
	if v is bool:
		return v
	if v is int or v is float:
		return v != 0 and not (v is float and is_nan(v))
	if v is String or v is StringName:
		return str(v) != ""
	return true


## A stable sort (JavaScript's is; Godot's is not), cmp(a, b) returning a number.
static func stable_sort(list: Array, cmp: Callable) -> Array:
	var idx := []
	for i in list.size():
		idx.append([list[i], i])
	idx.sort_custom(func(x, y):
		var c = cmp.call(x[0], y[0])
		if c != 0:
			return c < 0
		return x[1] < y[1])
	var out := []
	for p in idx:
		out.append(p[0])
	return out


static func _lower(v) -> String:
	return str("" if v == null else v).to_lower()


static func _is(v, word: String) -> bool:
	return word in _lower(v)


# ================================================================== aether
## Handbook, Aether Generation: a Hero produces Aether of its own Affinity equal
## to its Affinity Level, every turn, while it stands. Two Affinities: both.
static func aether_from_hero(unit: Dictionary) -> Dictionary:
	var out := {}
	for a in unit.get("affinities", []):
		var lvl = num(a.get("level"), 0)
		if lvl <= 0:
			continue
		# (0.31) a Neutral Affinity ("neu") generates Neutral Aether, which pays any cost
		var key: String = ("d" + str(a["district"])) if truthy(a.get("district")) and str(a["district"]) != "neu" else "generic"
		out[key] = out.get(key, 0) + lvl
	return out


## What every standing Hero on a side produces together.
static func aether_income(units: Array, side: String) -> Dictionary:
	var total := {}
	for u in units:
		if u.get("side") != side or truthy(u.get("down")):
			continue
		if not _is(u.get("cardType", ""), "hero"):
			continue
		var got := aether_from_hero(u)
		for k in got:
			total[k] = total.get(k, 0) + got[k]
	return total


static func aether_add(pool: Dictionary, gain_: Dictionary) -> Dictionary:
	for k in gain_:
		pool[k] = pool.get(k, 0) + gain_[k]
	return pool


## Can a cost be paid? District Aether pays its own District; generic pays anything.
static func aether_can_pay(pool: Dictionary, cost) -> bool:
	if cost == null:
		cost = {}
	var need = num(cost.get("affinity"), 0)
	var gen = num(cost.get("generic"), 0)
	var key = ("d" + str(cost["district"])) if truthy(cost.get("district")) else null
	var have = pool.get(key, 0) if key != null else 0
	if need > have:
		return false
	var spare = 0
	for k in pool:
		spare += pool[k]
	return (spare - need) >= gen


static func aether_pay(pool: Dictionary, cost) -> bool:
	if not aether_can_pay(pool, cost):
		return false
	if cost == null:
		cost = {}
	var need = num(cost.get("affinity"), 0)
	var gen = num(cost.get("generic"), 0)
	var key = ("d" + str(cost["district"])) if truthy(cost.get("district")) else null
	if key != null:
		pool[key] = pool.get(key, 0) - need
	var left = gen
	var order := ["generic"]
	order.append_array(pool.keys())
	for k in order:
		if left <= 0 or not truthy(pool.get(k)):
			continue
		var take = min(left, pool[k])
		pool[k] -= take
		left -= take
	return left <= 0


static func aether_total(pool: Dictionary):
	var n = 0
	for k in pool:
		n += pool[k]
	return n


# ================================================================== hex
## Axial, pointy-top, matching the Sandbox. Neighbours in the resolver's order.
const HEX_DIRS := [[1, 0], [1, -1], [0, -1], [-1, 0], [-1, 1], [0, 1]]


static func hex_key(q, r) -> String:
	return str(q) + "," + str(r)


static func hex_parse(k) -> Dictionary:
	var a := str(k).split(",")
	return {"q": _jsnum(a[0]), "r": _jsnum(a[1] if a.size() > 1 else "")}


## Number("x") as JavaScript's unary plus would read it.
static func _jsnum(s: String):
	s = s.strip_edges()
	if s == "":
		return 0
	if s.is_valid_int():
		return int(s)
	if s.is_valid_float():
		var f := float(s)
		return int(f) if f == floor(f) else f
	return NAN


static func hex_distance(a: Dictionary, b: Dictionary):
	var dq = a["q"] - b["q"]
	var dr = a["r"] - b["r"]
	var s = abs(dq) + abs(dq + dr) + abs(dr)
	return s / 2 if (s is int and s % 2 == 0) else s / 2.0


static func hex_neighbours(q, r) -> Array:
	var out := []
	for d in HEX_DIRS:
		out.append({"q": q + d[0], "r": r + d[1]})
	return out


## Tiles a Unit can reach with the Movement Speed it has, walking round walls and
## other Units rather than through them. Breadth-first, so the cost is the real
## number of tiles walked. opts: passable(tile), blocked(tile), wall(from, to).
static func reachable(from: Dictionary, steps, opts = null) -> Array:
	if opts == null:
		opts = {}
	var passable: Callable = opts.get("passable", func(_t): return true)
	var blocked: Callable = opts.get("blocked", func(_t): return false)
	var wall: Callable = opts.get("wall", func(_a, _b): return false)
	var seen := {}
	var out := []
	seen[hex_key(from["q"], from["r"])] = 0
	var edge := [{"q": from["q"], "r": from["r"]}]
	var step := 1
	while step <= steps:
		var next := []
		for cur in edge:
			for n in hex_neighbours(cur["q"], cur["r"]):
				var k := hex_key(n["q"], n["r"])
				if seen.has(k):
					continue
				if not passable.call(n):
					continue
				if wall.call(cur, n):
					continue
				if blocked.call(n):
					continue
				seen[k] = step
				out.append({"q": n["q"], "r": n["r"], "cost": step})
				next.append(n)
		edge = next
		if edge.is_empty():
			break
		step += 1
	return out


## A straight line between two tiles: the cube line, rounded at each step.
static func hex_line(a: Dictionary, b: Dictionary) -> Array:
	var n = hex_distance(a, b)
	if not truthy(n):
		return [{"q": a["q"], "r": a["r"]}]
	var out := []
	var i := 0
	while i <= n:
		var t: float = float(i) / n
		var q = a["q"] + (b["q"] - a["q"]) * t
		var r = a["r"] + (b["r"] - a["r"]) * t
		out.append(hex_round(q, r))
		i += 1
	return out


static func hex_round(q: float, r: float) -> Dictionary:
	var x := q
	var z := r
	var y := -x - z
	var rx := js_round(x)
	var ry := js_round(y)
	var rz := js_round(z)
	var dx := absf(rx - x)
	var dy := absf(ry - y)
	var dz := absf(rz - z)
	if dx > dy and dx > dz:
		rx = -ry - rz
	elif dy > dz:
		ry = -rx - rz
	else:
		rz = -rx - ry
	return {"q": int(rx), "r": int(rz)}


# ================================================================== units
static var _next_id := 0


static func make_unit(spec = null) -> Dictionary:
	if spec == null:
		spec = {}
	var id = spec.get("id")
	if not truthy(id):
		_next_id += 1
		id = "u" + str(randi() % 100000).pad_zeros(5) + str(_next_id)
	var roles := []
	for x in (spec.get("roles") if spec.get("roles") != null else []):
		if roles.size() < 2:
			roles.append(_lower(x))
	return {
		"id": id,
		"name": spec.get("name") if truthy(spec.get("name")) else "Unit",
		"side": spec.get("side") if truthy(spec.get("side")) else "ally",
		"hp": num(spec.get("hp"), num(spec.get("hpMax"), 20)),
		"hpMax": num(spec.get("hpMax"), 20),
		"nrg": num(spec.get("nrg"), num(spec.get("nrgMax"), 4)),
		"nrgMax": num(spec.get("nrgMax"), 4),
		"ac": num(spec.get("ac"), 10),
		# Integrity (the unit rework): every Unit's armour against Cyber, 1 to 20
		"integrity": num(spec.get("integrity"), num(spec.get("ac"), 10)),
		"ms": num(spec.get("ms"), 3),
		"subtype": spec.get("subtype") if truthy(spec.get("subtype")) else "",
		"cardType": spec.get("cardType") if truthy(spec.get("cardType")) else "",
		"affinities": (spec.get("affinities") if spec.get("affinities") != null else []).duplicate(),
		"roles": roles,
		"archetypes": (spec.get("archetypes") if spec.get("archetypes") != null else []).duplicate(),
		"skull": num(spec.get("skull"), 0),
		"salvage": spec.get("salvage") if truthy(spec.get("salvage")) else "",
		"src": spec.get("src") if truthy(spec.get("src")) else (spec.get("name") if truthy(spec.get("name")) else ""),
		"lootPool": (spec.get("lootPool") if spec.get("lootPool") != null else []).duplicate(),
		"setDrops": (spec.get("setDrops") if spec.get("setDrops") != null else []).duplicate(),
		# Handbook stat table: Troops reset Energy each turn; Heroes carry it over
		"carries": truthy(spec["carries"]) if spec.has("carries") else _is(spec.get("cardType", ""), "hero"),
		"hits": 0,
		"statuses": [],
		"behaviors": (spec.get("behaviors") if spec.get("behaviors") != null else []).duplicate(),
		"actions": (spec.get("actions") if spec.get("actions") != null else []).duplicate(),
		"down": false,
		"lastAttackedBy": null,
		"attackedThisRound": false,
	}


## Reads a card in the Companion's schema form, so nothing can disagree about
## what a card means.
static func unit_from_card(card: Dictionary, side = null) -> Dictionary:
	var st: Dictionary = card.get("stats") if card.get("stats") is Dictionary else {}
	var sd = side if truthy(side) else ("enemy" if _re_foe.search(str(card.get("cardType", "") if card.get("cardType") != null else "")) else "ally")
	var behs := []
	for b in (card.get("behaviors") if card.get("behaviors") != null else []):
		var k = b.get("key") if truthy(b.get("key")) else b.get("k")
		var x = b.get("x") if not b.has("value") else b["value"]
		var o := {"k": k}
		if b.has("value") or b.has("x"):
			o["x"] = x
		behs.append(o)
	var acts := []
	var src_list = card.get("entries") if truthy(card.get("entries")) else card.get("abilities")
	for a in (src_list if src_list != null else []):
		if str(a.get("text", "") if a.get("text") != null else "").strip_edges() == "" and str(a.get("name", "") if a.get("name") != null else "").strip_edges() == "":
			continue
		var nm := str(a.get("name", "") if a.get("name") != null else "").strip_edges()
		var act := {
			"name": nm if nm != "" else "(unnamed)",
			"tag": a.get("kind") if truthy(a.get("kind")) else (a.get("tag") if truthy(a.get("tag")) else "Active"),
			"cost": num(a["energyCost"] if a.has("energyCost") else a.get("cost"), 0),
			"role": a.get("role") if truthy(a.get("role")) else "",
			# (0.12) what a Ranged Action fires, for the screen to draw (none is a Bolt)
			"proj": a.get("projectile") if truthy(a.get("projectile")) else (a.get("proj") if truthy(a.get("proj")) else ""),
			"text": str(a.get("text", "") if a.get("text") != null else "").strip_edges(),
		}
		_carry(act, "dmg", a, "damage", "dmg")
		_carry(act, "rng", a, "attackRange", "rng")
		_carry(act, "hit", a, "toHit", "hit")
		_carry(act, "pen", a, "armorPenetration", "pen")
		acts.append(act)
	# Handbook 15.8: on a card with a variable cost a stat may be written N(X),
	# N for each X. X is what was chosen as the card was played, and 1 when
	# nobody chose (a Starting Troop, a Unit put down by a Deploy).
	var xv = num(card.get("x"), 1)
	var x: int = maxi(1, int(xv) if truthy(xv) else 1)
	var sx := func(v, d):
		var m := _re_stat_x.search(str(v if v != null else ""))
		return (int(m.get_string(1)) * x) if m != null else num(v, d)
	var made := make_unit({
		"name": card.get("name"),
		"side": sd,
		"hpMax": sx.call(st.get("hp"), 20),
		# a Hero's Energy is its per-turn generation; a Troop's is its pool
		"nrgMax": sx.call(st.get("nrg"), num(st.get("apT"), 4)),
		"ac": sx.call(st.get("ac"), 10),
		# Integrity replaced Will and Security; a card without one uses its AC
		"integrity": sx.call(st.get("int"), sx.call(st.get("ac"), 10)),
		"ms": sx.call(st.get("move"), 3),
		"subtype": "", "roles": (card.get("combatRoles") if card.get("combatRoles") != null else []).slice(0, 2), "cardType": card.get("cardType"),
		"affinities": card.get("affinities") if truthy(card.get("affinities")) else [],
		"archetypes": (card.get("archetypes") if card.get("archetypes") != null else []).duplicate(),
		"skull": card.get("skull"), "salvage": card.get("salvage"), "lootPool": card.get("lootPool"), "setDrops": card.get("setDrops"),
		"src": card.get("src") if truthy(card.get("src")) else card.get("name"),
		"behaviors": behs,
		"actions": acts,
	})
	# a Unit from a variable-cost card remembers its X, for what its text says
	if card.get("x") != null:
		made["x"] = x
	return made


## JavaScript's "a.x !== undefined ? a.x : a.y", kept only when it has a value.
static func _carry(act: Dictionary, key: String, a: Dictionary, first: String, second: String) -> void:
	if a.has(first):
		act[key] = a[first]
	elif a.has(second):
		act[key] = a[second]


# ================================================================== statuses
## Revision 15.4: every status lasts its Duration at full strength, then ends.
## Strength is the number; strengthless statuses carry none. Each Recharge
## applies its per-turn effect and takes a turn off. A second dose adds both.
const STATUS_RULES := {
	"rooted": {}, "stunned": {}, "marked": {}, "pinned": {},
	"bleed": {"dmg": "pct10"}, "half cover": {}, "full cover": {},
	"slowed": {"strength": true}, "drained": {"strength": true}, "evasive": {"strength": true},
	"poisoned": {"strength": true, "dmg": "n"}, "weakened": {"strength": true}, "sundered": {"strength": true},
	# Revision 16.3
	"hardened": {"strength": true},
}


static func has_status(u, name) -> bool:
	var n := _lower(name)
	if u == null or u.get("statuses") == null:
		return false
	for s in u["statuses"]:
		if _lower(s.get("name")) == n:
			return true
	return false


static func strengthless(name) -> bool:
	var r = STATUS_RULES.get(_lower(name))
	return r == null or not r.get("strength", false)


static func status_of(u: Dictionary, name) -> Variant:
	var n := _lower(name)
	for s in (u.get("statuses") if u.get("statuses") != null else []):
		if _lower(s.get("name")) == n:
			return s
	return null


## A status's strength; 1 for a strengthless status that is present.
static func status_n(u: Dictionary, name):
	var st = status_of(u, name)
	if st == null:
		return 0
	if st.get("n") == null:
		return 1
	return num(st["n"], 0)


static func status_turns(u: Dictionary, name):
	var st = status_of(u, name)
	return num(st.get("turns"), 0) if st != null else 0


static func _blank(v) -> bool:
	return v == null or (v is String and v == "")


## The locks (Handbook 16.0): Stunned, Rooted, Pinned and Marked last 2 turns
## at most and never stack or refresh: a Unit that has one ignores another
## dose, and one just out of it cannot be given it again until the same point
## of the next round (its guard, in u.guards, cleared by tick_statuses). So a
## lock can take at most turns/(turns+1) of a Unit's turns.
const LOCKS := ["stunned", "rooted", "pinned", "marked"]
const LOCK_MAX_TURNS := 2
const STUN_MAX_TURNS := LOCK_MAX_TURNS


static func is_lock(name) -> bool:
	return LOCKS.has(_lower(name))


## "" if name can land on u; "guard" (just out of it) or "already" (has it now) if not.
static func lock_block(u, name) -> String:
	if not is_lock(name) or not (u is Dictionary):
		return ""
	if u.get("guards") is Dictionary and u["guards"].has(_lower(name)):
		return "guard"
	if has_status(u, name):
		return "already"
	return ""


static func stun_block(u, name) -> String:
	return lock_block(u, name)


static func add_status(u: Dictionary, name, n = null, source = null, turns = null) -> Array:
	if u.get("statuses") == null:
		u["statuses"] = []
	if lock_block(u, name) != "":
		return [{"type": "status", "unit": u["id"], "name": name, "gained": false, "resisted": true}]
	if hooks.has("status") and hooks["status"].is_valid():      # a battle that has gone listens no more
		hooks["status"].call(u, name)
	var raw = null if _blank(n) else num(n, 0)
	var t = null if _blank(turns) else num(turns, 0)
	var strn = null
	var trn
	if strengthless(name):
		strn = null
		trn = t if t != null else (raw if raw != null else 1)
	else:
		strn = raw if raw != null else 1
		trn = t if t != null else 1
	trn = max(1, trn)
	if is_lock(name):
		trn = min(trn, LOCK_MAX_TURNS)
	var had = status_of(u, name)
	if had != null:
		if strn != null:
			had["n"] = num(had.get("n"), 0) + strn
		had["turns"] = num(had.get("turns"), 0) + trn
		return [{"type": "status", "unit": u["id"], "name": had["name"], "gained": true, "stacked": true, "n": had["n"], "turns": had["turns"]}]
	var st := {"name": name, "n": strn, "turns": trn, "source": source if truthy(source) else null}
	if hooks.has("half") and hooks["half"].is_valid() and hooks["half"].call() == "enemy":
		st["late"] = true           # arrived in the Enemies' turn: it ticks as your next turn ends
	u["statuses"].append(st)
	return [{"type": "status", "unit": u["id"], "name": name, "gained": true, "n": strn, "turns": trn}]


static func drop_status(u: Dictionary, name) -> Array:
	var before: int = u["statuses"].size()
	u["statuses"] = u["statuses"].filter(func(s): return s.get("name") != name)
	return [] if before == u["statuses"].size() else [{"type": "status", "unit": u["id"], "name": name, "gained": false}]


## What the statuses (and card modifiers) on a Unit change about it.
static func effective(u: Dictionary) -> Dictionary:
	var e := {"ms": u.get("ms"), "msBase": u.get("ms"), "ac": num(u.get("ac"), 10), "integrity": num(u.get("integrity"), num(u.get("ac"), 10)),
		"dmgMult": 1, "dmgFlat": 0, "passivesOff": false, "alwaysHit": false,
		"cannotMove": false, "cannotAct": false, "evasion": 0, "aim": 0, "hardened": 0, "flying": truthy(u.get("flying")) or truthy(u.get("pFlying")),
		"reactionAlwaysHit": false, "notes": []}
	if has_status(u, "Slowed"):
		var sl = status_n(u, "Slowed")
		e["ms"] = max(0, e["ms"] - sl)
		e["notes"].append("Slowed: Movement Speed down " + str(sl))
	if has_status(u, "Rooted"):
		e["ms"] = 0; e["cannotMove"] = true; e["notes"].append("Rooted: cannot move")
	if has_status(u, "Stunned"):
		e["ms"] = 0; e["cannotMove"] = true; e["cannotAct"] = true
		e["notes"].append("Stunned: cannot act or move")
	if has_status(u, "Sundered"):
		var su = status_n(u, "Sundered")
		e["ac"] = max(0, e["ac"] - su)
		e["notes"].append("Sundered: Armor Class down " + str(su))
	if has_status(u, "Weakened"):
		e["dmgFlat"] = -status_n(u, "Weakened")
		e["notes"].append("Weakened: deals " + str(-e["dmgFlat"]) + " less damage")
	if has_status(u, "Marked"):
		e["alwaysHit"] = true; e["notes"].append("Marked: Ranged attacks against it always hit")
	if has_status(u, "Pinned"):
		e["reactionAlwaysHit"] = true; e["notes"].append("Pinned: reaction shots against it always hit")
	if has_status(u, "Evasive"):
		e["evasion"] = status_n(u, "Evasive")
		e["notes"].append("Evasive: +" + str(e["evasion"]) + " to be hit by Ranged attacks")
	# Revision 16.3: each hit on it is that much less, never below 1
	if has_status(u, "Hardened"):
		e["hardened"] = status_n(u, "Hardened")
		e["notes"].append("Hardened: each hit on it is " + str(e["hardened"]) + " less, never below 1")
	# Modify, from cards: each carries its stat, amount and how long it lasts
	for m in (u.get("mods") if u.get("mods") != null else []):
		var a = num(m.get("amt"), 0)
		var stat = m.get("stat")
		if stat == "AC": e["ac"] = max(0, e["ac"] + a)
		elif stat == "MS":
			if not e["cannotMove"]: e["ms"] = max(0, e["ms"] + a)
		elif stat == "DMG": e["dmgFlat"] += a
		elif stat == "INT" or stat == "WIL": e["integrity"] = max(0, e["integrity"] + a)
		elif stat == "RANGE" or stat == "Range": e["range"] = (e.get("range") if truthy(e.get("range")) else 0) + a
		elif stat == "AP": e["ap"] = (e.get("ap") if truthy(e.get("ap")) else 0) + a
		elif stat == "Aim": e["aim"] += a   # Revision 16.3: its ranged attacks need that much less
		var how: String = "Passive, while it holds" if m.get("dur") == "passive" else (str(m.get("dur")) + ((" " + str(m.get("n"))) if truthy(m.get("n")) else ""))
		e["notes"].append(("+" if a >= 0 else "") + str(a) + " " + str(stat) + " (" + how + ")")
	return e


static func _held(source) -> bool:
	return _re_held.search(str("" if source == null else source)) != null


## Handbook 15.9: every Status ticks once a round, at the end of the turn after
## the one it arrived in. One that arrived in the Player's half of the round
## (from the Recharge to the end of the Player's turn) ticks in the Recharge
## Phase, as every Status did before 15.9. One that arrived in the Enemies'
## half (their turn, its end, the next wave, up to the Recharge) is marked
## late, and ticks when the Player's next turn ends. So a Status for 1 turn
## always lasts through the next turn, whoever put it there. Timed stat
## changes follow the same rule. The decaying ones do their damage first.
static func tick_statuses(units, late: bool) -> Array:
	var ev := []
	for u in (units if units != null else []):
		if truthy(u.get("down")):
			continue
		if u.get("guards") is Dictionary:
			for g in u["guards"].keys():
				if bool(u["guards"][g]) == late:
					u["guards"].erase(g)      # a round has gone by since it ended
			if u["guards"].is_empty():
				u.erase("guards")
		for st in (u.get("statuses") if u.get("statuses") != null else []):
			if _held(st.get("source")):
				continue   # an Aura or a Passive lasts while it holds
			if truthy(st.get("late")) != late:
				continue
			var rule = STATUS_RULES.get(_lower(st.get("name")), {})
			if rule.get("dmg") == "n" and num(st.get("n"), 0) > 0:
				ev.append_array(hit(u, num(st.get("n"), 0)))
				ev.append({"type": "tick", "unit": u["id"], "name": st["name"], "damage": num(st.get("n"), 0)})
			if rule.get("dmg") == "pct10":
				var d = max(1, int(js_round(num(u.get("hp"), 0) * 0.10)))
				ev.append_array(hit(u, d))
				ev.append({"type": "tick", "unit": u["id"], "name": st["name"], "damage": d})
			st["turns"] = num(st.get("turns"), 0) - 1
		var kept := []
		for m in (u.get("mods") if u.get("mods") != null else []):
			if m.get("dur") != "turns":
				kept.append(m)   # persistent, while attached, and a Passive's stay
				continue
			if truthy(m.get("late")) != late:
				kept.append(m)
				continue
			m["n"] = num(m.get("n"), 0) - 1
			if m["n"] > 0:
				kept.append(m)
				continue
			if m.get("stat") == "HP":
				u["hpMax"] = max(1, num(u.get("hpMax"), 1) - num(m.get("amt"), 0)); u["hp"] = min(num(u.get("hp"), 0), u["hpMax"])
			if m.get("stat") == "NRG":
				u["nrgMax"] = max(0, num(u.get("nrgMax"), 0) - num(m.get("amt"), 0)); u["nrg"] = min(num(u.get("nrg"), 0), u["nrgMax"])
			ev.append({"type": "mod", "unit": u["id"], "stat": m.get("stat"), "expired": true})
		u["mods"] = kept
		var left := []
		for st in (u.get("statuses") if u.get("statuses") != null else []):
			if _held(st.get("source")) or num(st.get("turns"), 0) > 0:
				left.append(st)
				continue
			if is_lock(st.get("name")):
				if not (u.get("guards") is Dictionary):
					u["guards"] = {}
				u["guards"][_lower(st.get("name"))] = late
			ev.append({"type": "status", "unit": u["id"], "name": st["name"], "gained": false, "expired": true})
		u["statuses"] = left
	return ev


## The Recharge Phase: what arrived in the Player's half of the round.
static func recharge_tick(units) -> Array:
	return tick_statuses(units, false)


## The end of the Player's turn: what arrived in the Enemies' half.
static func turn_end_tick(units) -> Array:
	return tick_statuses(units, true)


# ================================================================== health
## Each hit is one instance, whatever its size.
## Revision 16.3: Hardened takes its number off each hit, never below 1.
static func hardened_cut(u: Dictionary, amount):
	amount = max(0, num(amount, 0))
	var hard = status_n(u, "Hardened") if has_status(u, "Hardened") else 0
	return max(1, amount - hard) if (hard > 0 and amount > 0) else amount


## cut: the amount has had Hardened taken off already (an attack's damage has).
static func hit(u: Dictionary, amount, cut := false) -> Array:
	amount = max(0, num(amount, 0)) if cut else hardened_cut(u, amount)
	var ev := []
	var before = u["hp"]
	u["hp"] = max(0, u["hp"] - amount)
	u["hits"] = u.get("hits", 0) + 1
	ev.append({"type": "hit", "unit": u["id"], "amount": amount, "instance": u["hits"]})
	if u["hp"] == 0 and not truthy(u.get("down")):
		u["down"] = true
		ev.append({"type": "down", "unit": u["id"]})
	if hooks.has("hit") and hooks["hit"].is_valid() and before - u["hp"] > 0:
		hooks["hit"].call(u, before - u["hp"])
	return ev


## Healing restores what was lost and stops at the printed figure.
static func heal(u: Dictionary, amount) -> Array:
	amount = max(0, num(amount, 0))
	var before = u["hp"]
	u["hp"] = min(u["hpMax"], u["hp"] + amount)
	if u["hp"] > 0:
		u["down"] = false
	return [{"type": "heal", "unit": u["id"], "amount": u["hp"] - before, "wasted": amount - (u["hp"] - before)}]


## Gaining Health is a different thing and may go above the printed figure.
static func gain(u: Dictionary, amount) -> Array:
	amount = max(0, num(amount, 0))
	u["hp"] += amount
	if u["hp"] > 0:
		u["down"] = false
	return [{"type": "gain", "unit": u["id"], "amount": amount, "over": max(0, u["hp"] - u["hpMax"])}]


# ================================================================== actions
static var _re_foe := RegEx.create_from_string("(?i)enemy|boss")
static var _re_stat_x := RegEx.create_from_string("(?i)^\\s*(\\d+)\\s*\\(\\s*X\\s*\\)\\s*$")
static var _re_held := RegEx.create_from_string("^(aura|passive):")
static var _re_gain_aether := RegEx.create_from_string("(?i)\\[\\[gain Aether (\\d+)\\]\\]")
static var _re_deal := RegEx.create_from_string("(?i)deal\\s+(\\d+)\\s+damage")
static var _re_dmg := RegEx.create_from_string("(?i)(\\d+)\\s+damage")
static var _re_heal := RegEx.create_from_string("(?i)heals?\\s+(?:for\\s+)?(\\d+)")
static var _re_restore := RegEx.create_from_string("(?i)restores?\\s+(\\d+)")
static var _re_gain := RegEx.create_from_string("(?i)gains?\\s+\\+?(\\d+)\\s*(?:HP|Health)")


## What an Action does to whoever it lands on. The damage strip is
## authoritative; otherwise the rules text is read for the usual phrasing.
static func action_effect(a: Dictionary) -> Dictionary:
	var out := {"damage": 0, "heal": 0, "gain": 0}
	var d = num(a.get("dmg"), null)
	if d != null and d > 0:
		out["damage"] = d
	var t := str(a.get("text", "") if a.get("text") != null else "")
	if not truthy(out["damage"]):
		var m := _re_deal.search(t)
		if m == null:
			m = _re_dmg.search(t)
		if m != null:
			out["damage"] = num(m.get_string(1), 0)
	var h := _re_heal.search(t)
	if h == null:
		h = _re_restore.search(t)
	if h != null:
		out["heal"] = num(h.get_string(1), 0)
	var g := _re_gain.search(t)
	if g != null:
		out["gain"] = num(g.get_string(1), 0)
	return out


static func can_afford(u: Dictionary, a: Dictionary) -> bool:
	return not ((a.get("tag") == "Active" or a.get("tag") == "Combo") and num(a.get("cost"), 0) > u["nrg"])


## Resolve an Action from one Unit onto another. Legality is the caller's.
static func use_action(actor: Dictionary, action: Dictionary, target) -> Array:
	var ev := [{"type": "action", "unit": actor["id"], "name": action.get("name"), "cost": num(action.get("cost"), 0)}]
	actor["nrg"] = max(0, actor["nrg"] - num(action.get("cost"), 0))
	var eff := action_effect(action)
	var mine := effective(actor)
	if target != null:
		target["lastAttackedBy"] = actor["id"]
		target["attackedThisRound"] = true
		if truthy(eff["damage"]):
			var dealt = int(floor(eff["damage"] * mine["dmgMult"]))
			if dealt != eff["damage"]:
				ev.append({"type": "modified", "unit": actor["id"], "from": eff["damage"], "to": dealt, "why": "a status"})
			ev.append_array(hit(target, dealt))
		if truthy(eff["heal"]):
			ev.append_array(heal(target, eff["heal"]))
		if truthy(eff["gain"]):
			ev.append_array(gain(target, eff["gain"]))
	return ev


# ================================================================== the dice
## A seeded generator (xorshift32, exactly as the Companion's), so the same
## fight can be run twice and give the same answer. No seed: ordinary chance.
const DIE := {"d20": 20, "d6": 6, "coin": 2}


class Dice:
	extends RefCounted
	var seeded := false
	var s0 := 0

	func _init(seed = null) -> void:
		seeded = seed != null
		if seeded:
			var s := Rules._i32(int(seed))
			s0 = s if s != 0 else 1

	func raw(sides: int) -> int:
		if not seeded:
			return 1 + randi() % sides
		s0 = Rules._i32(s0 ^ Rules._i32(s0 << 13))
		s0 = Rules._i32(s0 ^ ((s0 & 0xFFFFFFFF) >> 17))
		s0 = Rules._i32(s0 ^ Rules._i32(s0 << 5))
		return 1 + (absi(s0) % sides)

	func d20() -> int:
		return raw(20)

	func d6() -> int:
		return raw(6)

	## A coin reports as heads or tails, and as 1 or 2 for anything counting.
	func coin() -> Dictionary:
		var v := raw(2)
		return {"value": v, "face": "heads" if v == 1 else "tails"}

	func roll(kind) -> int:
		if kind == "coin":
			return coin()["value"]
		return raw(Rules.DIE.get(kind, 20))


## A 32-bit signed integer, as JavaScript's bit operators leave one.
static func _i32(x: int) -> int:
	x = x & 0xFFFFFFFF
	return x - 0x100000000 if x >= 0x80000000 else x


static func make_dice(seed = null) -> Dice:
	return Dice.new(seed)


## The face a player would read off the table.
static func face_of(kind, value) -> String:
	if kind == "coin":
		return "heads" if value == 1 else "tails"
	return str(value)


# ================================================================== attacks
## Handbook, Attack Types and Armor Class & Penetration:
##   Ranged  must hit (d20 against To-Hit, plus Cover and Evasive) and Penetrate
##           (d20 plus AP against Armor Class); beyond Attack Range, no attack.
##   Melee   always hits, but must still Penetrate.
##   Aether  always hits and always Penetrates.
##   Support always hits.
##   Cyber   reaches and aims like Ranged, then Penetrates Integrity.
## A Marked target is always hit by Ranged attacks.
##
## Resumable: called without a roll it needs, it returns what it is waiting for
## ({pending:"accuracy", die:"d20", needed:13}); fill that in and call again.
static func resolve_attack(attacker: Dictionary, action: Dictionary, target: Dictionary, ctx = null) -> Dictionary:
	if ctx == null:
		ctx = {}
	var rolls: Dictionary = ctx.get("rolls") if ctx.get("rolls") != null else {}
	var dice = ctx.get("dice")
	var manual := truthy(ctx.get("manual"))
	var kind := _lower(action.get("role") if truthy(action.get("role")) else (action.get("kind") if truthy(action.get("kind")) else "melee"))
	var out := {"kind": kind, "inRange": true, "hit": null, "penetrated": null, "damage": 0, "rolls": {}, "reason": null, "pending": null}

	var need := func(what: String, die: String, needed):
		if rolls.get(what) != null:
			return num(rolls[what], 0)
		if not manual and dice != null:
			return dice.roll(die)
		out["pending"] = what; out["die"] = die; out["needed"] = needed
		return null

	if kind == "support" or kind == "aether":
		out["hit"] = true
		out["penetrated"] = true
		if kind == "aether":
			out["aetherDamage"] = true
	else:
		# a Cyber Action reaches and aims like a ranged attack
		var aimed := kind == "ranged" or kind == "cyber"
		if aimed and action.has("rng") and not (action["rng"] is String and action["rng"] == "") and ctx.has("distance"):
			var reach = num(action["rng"], 0) + num(effective(attacker).get("range"), 0)
			var dval = ctx["distance"]
			if (dval is int or dval is float) and dval > reach:
				out["inRange"] = false
				out["reason"] = "beyond Attack Range " + str(reach)
				return out
		if aimed:
			var t_eff := effective(target)
			if t_eff["alwaysHit"] or (truthy(ctx.get("reaction")) and t_eff["reactionAlwaysHit"]):
				out["hit"] = true
				out["reason"] = "target Marked, always hit" if has_status(target, "Marked") else ("target Pinned, the reaction always hits" if truthy(ctx.get("reaction")) else "target always hit")
			else:
				var threshold = num(action.get("hit"), 0) + num(ctx.get("cover"), 0) + num(ctx.get("evasive"), 0) + num(t_eff.get("evasion"), 0) - num(effective(attacker).get("aim"), 0)
				var acc = need.call("accuracy", "d20", threshold)
				if acc == null:
					return out
				out["rolls"]["accuracy"] = acc
				out["needed"] = threshold
				out["hit"] = acc >= threshold
				if not out["hit"]:
					out["reason"] = "missed: " + str(acc) + " against " + str(threshold)
		else:
			# Flying: cannot be hit by melee attacks
			if effective(target)["flying"]:
				out["hit"] = false; out["penetrated"] = false; out["reason"] = "target is Flying: melee cannot reach it"
				return out
			out["hit"] = true   # melee always hits
		# penetration, asked for only once it has hit
		if out["hit"]:
			var cyber := kind == "cyber"
			var ac = effective(target)["integrity"] if cyber else effective(target)["ac"]
			var pen = need.call("penetration", "d20", ac)
			if pen == null:
				return out
			out["rolls"]["penetration"] = pen
			var with_ap = pen + num(action.get("pen"), 0) + num(effective(attacker).get("ap"), 0)
			out["needed_ac"] = ac
			out["against"] = "Integrity" if cyber else "Armor Class"
			out["penetrated"] = with_ap >= ac
			out["penetrationTotal"] = with_ap
			if not out["penetrated"]:
				out["reason"] = "did not Penetrate: " + str(with_ap) + " against " + ("Integrity " if cyber else "Armor Class ") + str(ac)
		else:
			out["penetrated"] = false

	if out["hit"] and out["penetrated"]:
		var eff := action_effect(action)
		var mine := effective(attacker)
		out["damage"] = hardened_cut(target, max(0, int(floor(eff["damage"] * mine["dmgMult"])) + num(mine.get("dmgFlat"), 0)))
		if out["damage"] != eff["damage"]:
			out["halved"] = mine["dmgMult"] < 1
		if truthy(mine["dmgFlat"]):
			out["weakened"] = -mine["dmgFlat"]
	return out


## What an attack will ask for before it is resolved.
static func rolls_for(action: Dictionary, target: Dictionary) -> Array:
	var kind := _lower(action.get("role") if truthy(action.get("role")) else (action.get("kind") if truthy(action.get("kind")) else "melee"))
	if kind == "support" or kind == "aether":
		return []
	if (kind == "ranged" or kind == "cyber") and not effective(target)["alwaysHit"]:
		return [{"what": "accuracy", "die": "d20"}, {"what": "penetration", "die": "d20"}]
	return [{"what": "penetration", "die": "d20"}]


## Resolve and apply, returning events. What a simulator calls once per attack.
static func attack(attacker: Dictionary, action: Dictionary, target: Dictionary, ctx = null) -> Array:
	var res := resolve_attack(attacker, action, target, ctx)
	var ev := [{"type": "attack", "unit": attacker["id"], "target": target["id"], "name": action.get("name"), "result": res}]
	if not res["inRange"]:
		return ev
	attacker["nrg"] = max(0, attacker["nrg"] - num(action.get("cost"), 0))
	target["lastAttackedBy"] = attacker["id"]
	target["attackedThisRound"] = true
	if truthy(res["damage"]):
		ev.append_array(hit(target, res["damage"], true))
	return ev


# ================================================================== turns
## The three things a table forgets, in one place.
static func end_turn(units: Array) -> Array:
	var ev := []
	for u in units:
		u["hits"] = 0
		u["attackedThisRound"] = false
		u["nrg"] = (u["nrg"] + u["nrgMax"]) if truthy(u.get("carries")) else u["nrgMax"]
		# Drained takes its strength from every refill while it lasts (15.4)
		var dr = status_n(u, "Drained") if has_status(u, "Drained") else 0
		if truthy(dr):
			u["nrg"] = max(0, u["nrg"] - dr)
			ev.append({"type": "status", "unit": u["id"], "name": "Drained", "energyLost": dr})
	ev.append({"type": "turn"})
	return ev


## Combat ends when every Enemy is down, or every Player Unit is.
static func outcome(units: Array) -> Dictionary:
	var live := func(side):
		return units.filter(func(u): return u.get("side") == side and not truthy(u.get("down"))).size()
	var allies: int = live.call("ally")
	var foes: int = live.call("enemy")
	if foes == 0 and allies == 0:
		return {"over": true, "winner": "draw"}
	if foes == 0:
		return {"over": true, "winner": "ally"}
	if allies == 0:
		return {"over": true, "winner": "enemy"}
	return {"over": false, "winner": null}


# ================================================================== behaviour
## Tie-breaks are fixed: closest, then lowest current Health, then lowest Armor
## Class, then lowest card number (id).
static func tie_break(list: Array, ctx):
	var sorted := stable_sort(list, func(a, b):
		var da = dist(ctx, a)
		var db = dist(ctx, b)
		if da != db: return da - db
		if a["hp"] != b["hp"]: return a["hp"] - b["hp"]
		if a["ac"] != b["ac"]: return a["ac"] - b["ac"]
		return _cmp_str(str(a["id"]), str(b["id"])))
	return sorted[0] if not sorted.is_empty() else null


static func _cmp_str(a: String, b: String) -> int:
	# localeCompare on the ids used here (letters and digits)
	var la := a.to_lower()
	var lb := b.to_lower()
	if la != lb:
		return -1 if la < lb else 1
	if a == b:
		return 0
	return -1 if a > b else 1   # lower case first, as a locale compare puts it


static func dist(ctx, u):
	if ctx == null or not (ctx.get("distance") is Callable):
		return 0
	return ctx["distance"].call(u)


## Who an Enemy attacks. A keyword with a condition outranks one without;
## where two conditions are both met, the one printed first wins.
static func choose_target(enemy: Dictionary, candidates: Array, ctx = null):
	if ctx == null:
		ctx = {}
	var live := candidates.filter(func(u): return not truthy(u.get("down")))
	if live.is_empty():
		return null
	var defs := []
	for b in (enemy.get("behaviors") if enemy.get("behaviors") != null else []):
		var d = beh_of(b.get("k"))
		if d != null and d["cat"] == "target":
			defs.append({"def": d, "x": b["x"] if b.has("x") else d.get("pdef")})
	var ordered := defs.filter(func(d): return d["def"]["cond"])
	ordered.append_array(defs.filter(func(d): return not d["def"]["cond"]))
	for o in ordered:
		var pick = apply_targeting(o["def"]["k"], enemy, live, ctx)
		if pick != null:
			return pick
	return tie_break(live, ctx)


static func apply_targeting(key: String, enemy: Dictionary, live: Array, ctx):
	var pool: Array
	match key:
		# the Player keywords mirror an Enemy one each
		"decisive": return apply_targeting("sadistic", enemy, live, ctx)
		"precise": return apply_targeting("opportunistic", enemy, live, ctx)
		"dauntless": return apply_targeting("brutish", enemy, live, ctx)
		"defiant": return apply_targeting("vindictive", enemy, live, ctx)
		"coordinated": return apply_targeting("ravenous", enemy, live, ctx)
		"thorough": return apply_targeting("methodical", enemy, live, ctx)
		"valiant":
			pool = live.filter(func(u): return _is(u.get("cardType", ""), "boss"))
			return tie_break(pool, ctx) if not pool.is_empty() else null
		"cunning":
			pool = live.filter(func(u): return _is(u.get("cardType", ""), "hero"))
			return tie_break(pool, ctx) if not pool.is_empty() else null
		"sadistic":
			return best(live, func(u): return -u["hp"], ctx)
		"opportunistic":
			return best(live, func(u): return -u["ac"], ctx)
		"brutish":
			return best(live, func(u): return u["ac"], ctx)
		"vindictive":
			pool = live.filter(func(u): return u["id"] == enemy.get("lastAttackedBy"))
			return pool[0] if not pool.is_empty() else null
		"ravenous":
			pool = live.filter(func(u): return truthy(u.get("attackedThisRound")))
			return best(pool, func(u): return -u["hp"], ctx) if not pool.is_empty() else null
		"methodical":
			# only statuses an Enemy applied count
			pool = live.filter(func(u): return not u["statuses"].any(func(s): return s.get("source") == "enemy" or s.get("source") == "rule"))
			return tie_break(pool, ctx) if not pool.is_empty() else null
	return null


static func best(list: Array, score: Callable, ctx):
	var top = -INF
	var pool := []
	for u in list:
		var v = score.call(u)
		if v > top:
			top = v
			pool = [u]
		elif v == top:
			pool.append(u)
	return tie_break(pool, ctx)


## What a Unit's movement keywords tell it to do this turn.
static func move_plan(enemy: Dictionary, ctx = null) -> Dictionary:
	if ctx == null:
		ctx = {}
	var nearest = ctx.get("nearestEnemyDistance")
	var out := {"move": "toward", "act": true, "why": null}
	var defs := []
	for b in (enemy.get("behaviors") if enemy.get("behaviors") != null else []):
		var d = beh_of(b.get("k"))
		# Guardian is filed under support, but it changes where the Unit stands
		if d != null and (d["cat"] == "move" or d["k"] == "guardian"):
			defs.append({"def": d, "x": b["x"] if b.has("x") else d.get("pdef")})
	for o in defs:
		var k: String = o["def"]["k"]
		var x = o["x"]
		var nm: String = o["def"]["name"]
		# Prudent and Wary are the Player's Cowardly and Cautious
		if (k == "cowardly" or k == "prudent") and x != null and enemy["hp"] <= x:
			return {"move": "away", "act": false, "why": nm + " " + str(x)}
		if (k == "cautious" or k == "wary") and nearest != null and x != null and nearest <= x:
			out = {"move": "away", "act": true, "why": nm + " " + str(x)}
		if k == "steadfast" and out["move"] != "away":
			out = {"move": "hold", "act": true, "why": "Steadfast"}
		if k == "guardian" and out["move"] == "toward":
			out = {"move": "escort", "act": true, "why": "Guardian"}
	return out


# ================================================================== the round
## Where no map is given, every Unit is treated as adjacent.
static func distance_between(ctx, a, b):
	if ctx != null and ctx.get("distance") is Callable:
		return ctx["distance"].call(a, b)
	return 1


## The Action a Unit would choose against a target: the most damaging it can
## afford (the simulator's stand-in for a Player's judgement).
static func best_action(unit: Dictionary, target, ctx):
	var usable: Array = (unit.get("actions") if unit.get("actions") != null else []).filter(func(a):
		if a.get("tag") == "Passive" or a.get("tag") == "Aura": return false
		if not can_afford(unit, a): return false
		var reach = num(a.get("rng"), 0)
		if _lower(a.get("role", "")) == "ranged" and truthy(reach):
			return distance_between(ctx, unit, target) <= reach
		return true)
	if usable.is_empty():
		return null
	return stable_sort(usable, func(x, y): return action_effect(y)["damage"] - action_effect(x)["damage"])[0]


## An Enemy running a Combo takes them in order, restarting if it can't act. A
## Special Ability overrides the next one without advancing the sequence.
static func combo_actions(u: Dictionary) -> Array:
	return (u.get("actions") if u.get("actions") != null else []).filter(func(a): return a.get("tag") == "Combo")


static func next_combo_action(u: Dictionary):
	var combo := combo_actions(u)
	if combo.is_empty():
		return null
	if truthy(u.get("overrideNext")):
		var sps: Array = (u.get("actions") if u.get("actions") != null else []).filter(func(a): return a.get("tag") == "Special" and a.get("name") == u["overrideNext"])
		if not sps.is_empty():
			return {"action": sps[0], "override": true}
	var n := combo.size()
	var at = u.get("comboAt") if truthy(u.get("comboAt")) else 0
	var i = ((at % n) + n) % n
	return {"action": combo[i], "index": i, "override": false}


static func enemy_turn(enemy: Dictionary, state: Dictionary, ctx) -> Array:
	var ev := []
	if truthy(enemy.get("down")):
		return ev
	var foes: Array = state["units"].filter(func(u): return u.get("side") == "ally" and not truthy(u.get("down")))
	if foes.is_empty():
		return ev
	# movement keywords decide whether it closes, backs off, or breaks entirely
	var nearest = INF
	for f in foes:
		nearest = min(nearest, distance_between(ctx, enemy, f))
	var plan := move_plan(enemy, {"nearestEnemyDistance": nearest})
	if plan["move"] == "away":
		ev.append({"type": "move", "unit": enemy["id"], "away": true, "why": plan["why"]})
	if not plan["act"]:
		if not combo_actions(enemy).is_empty():
			enemy["comboAt"] = 0
		ev.append({"type": "skip", "unit": enemy["id"], "why": plan["why"]})
		return ev
	var target = choose_target(enemy, foes, {"distance": func(u): return distance_between(ctx, enemy, u)})
	if target == null:
		return ev
	var pick = next_combo_action(enemy)
	var action = pick["action"] if pick != null else best_action(enemy, target, ctx)
	if action == null:
		action = best_action(enemy, target, ctx)
	if action == null:
		if not combo_actions(enemy).is_empty():
			enemy["comboAt"] = 0
		ev.append({"type": "skip", "unit": enemy["id"], "why": "nothing it can use"})
		return ev
	ev.append_array(attack(enemy, action, target, {
		"dice": ctx.get("dice"),
		"distance": distance_between(ctx, enemy, target),
		"cover": ctx["coverFor"].call(target, enemy) if ctx.get("coverFor") is Callable else 0,
		"evasive": target.get("evasive") if truthy(target.get("evasive")) else 0,
	}))
	if pick != null and not pick["override"] and not combo_actions(enemy).is_empty():
		enemy["comboAt"] = ((enemy.get("comboAt") if truthy(enemy.get("comboAt")) else 0) + 1) % combo_actions(enemy).size()
	if pick != null and pick["override"]:
		enemy["overrideNext"] = null
	return ev


## The Player's side, in the order given (or the order the caller chooses).
static func player_turn(state: Dictionary, ctx) -> Array:
	var ev := []
	var mine: Array = state["units"].filter(func(u): return u.get("side") == "ally" and not truthy(u.get("down")))
	if ctx.get("playerOrder") is Callable:
		mine = ctx["playerOrder"].call(mine.duplicate(), state)
	for u in mine:
		if truthy(u.get("down")):
			continue
		var foes: Array = state["units"].filter(func(f): return f.get("side") == "enemy" and not truthy(f.get("down")))
		if foes.is_empty():
			continue
		var choice = ctx["playerPolicy"].call(u, state, ctx) if ctx.get("playerPolicy") is Callable else default_player_policy(u, foes, ctx)
		if choice == null or choice.get("action") == null or choice.get("target") == null:
			continue
		ev.append_array(attack(u, choice["action"], choice["target"], {
			"dice": ctx.get("dice"),
			"distance": distance_between(ctx, u, choice["target"]),
			"cover": ctx["coverFor"].call(choice["target"], u) if ctx.get("coverFor") is Callable else 0,
			"evasive": choice["target"].get("evasive") if truthy(choice["target"].get("evasive")) else 0,
		}))
	return ev


## Finish something if you can, otherwise hit the most dangerous thing in reach.
static func default_player_policy(unit: Dictionary, foes: Array, ctx):
	var top = null
	for f in foes:
		var a = best_action(unit, f, ctx)
		if a == null:
			continue
		var dmg = action_effect(a)["damage"]
		var kills: bool = dmg >= f["hp"]
		var score = (1000 if kills else 0) + dmg - f["hp"] * 0.01
		if top == null or score > top["score"]:
			top = {"action": a, "target": f, "score": score}
	return top


static func run_round(state: Dictionary, ctx = null) -> Array:
	if ctx == null:
		ctx = {}
	state["round"] = (state.get("round") if truthy(state.get("round")) else 0) + 1
	var ev := [{"type": "round", "round": state["round"]}]
	if ctx.get("onDraw") is Callable:
		var got = ctx["onDraw"].call(state)
		if got != null:
			ev.append_array(got)
	ev.append_array(player_turn(state, ctx))
	var done := outcome(state["units"])
	if not done["over"]:
		for e in state["units"].filter(func(u): return u.get("side") == "enemy"):
			ev.append_array(enemy_turn(e, state, ctx))
	ev.append_array(end_turn(state["units"]))
	return ev


## A whole fight. The cap makes a stalemate report itself rather than hang.
static func run_combat(units: Array, ctx = null) -> Dictionary:
	if ctx == null:
		ctx = {}
	var state := {"units": units, "round": 0, "log": []}
	var cap = ctx.get("maxRounds") if truthy(ctx.get("maxRounds")) else 50
	var res: Dictionary
	while true:
		state["log"].append_array(run_round(state, ctx))
		res = outcome(state["units"])
		if res["over"]:
			break
		if state["round"] >= cap:
			res = {"over": false, "winner": "stalemate"}
			break
	var survivors := []
	for u in state["units"]:
		if not truthy(u.get("down")):
			survivors.append({"name": u["name"], "side": u["side"], "hp": u["hp"], "hpMax": u["hpMax"]})
	return {"winner": res["winner"], "rounds": state["round"], "units": state["units"], "log": state["log"], "survivors": survivors}


## Medic looks for a wounded ally first.
static func support_plan(unit: Dictionary, allies: Array):
	var keys := []
	for b in (unit.get("behaviors") if unit.get("behaviors") != null else []):
		keys.append(b.get("k"))
	if not keys.has("medic"):
		return null
	var heals: Array = (unit.get("actions") if unit.get("actions") != null else []).filter(func(a):
		if a.get("tag") == "Passive" or a.get("tag") == "Aura": return false
		if not can_afford(unit, a): return false
		var eff := action_effect(a)
		return eff["heal"] > 0 or eff["gain"] > 0 or _lower(a.get("role", "")) == "support")
	if heals.is_empty():
		return null
	var hurt := stable_sort(allies.filter(func(u): return not truthy(u.get("down")) and u["id"] != unit["id"] and u["hp"] < u["hpMax"]),
		func(a, b): return float(a["hp"]) / a["hpMax"] - float(b["hp"]) / b["hpMax"])
	if hurt.is_empty():
		return null
	return {"action": heals[0], "target": hurt[0], "why": "Medic"}


## Guardian keeps station on the Hero.
static func escort_target(unit: Dictionary, allies: Array):
	for u in allies:
		if not truthy(u.get("down")) and _is(u.get("cardType", ""), "hero") and u["id"] != unit["id"]:
			return u
	return null


## Handbook 14.0: every Aether Chip prints its own value, 0 to 10.
const CHIP_RARITY_BONUS := {"common": 0, "uncommon": 0, "rare": 1, "epic": 1, "legendary": 2, "mythic": 2}


static func chip_value(card) -> int:
	if card == null:
		return 0
	# Revision 16.3: a Chip whose Passive gains Aether (the Ledger Chip) gives that much more
	var more := 0
	var raw = card.get("_raw") if card.get("_raw") is Dictionary else {}
	var list = raw.get("abilities") if raw.get("abilities") is Array else (card.get("entries") if card.get("entries") is Array else [])
	for e in list:
		if _lower(e.get("kind", "")) != "passive":
			continue
		var m = _re_gain_aether.search(str(e.get("text") if e.get("text") != null else ""))
		if m != null:
			more += int(m.get_string(1))
	return max(0, min(10, chip_base(card) + more))


static func chip_base(card) -> int:
	var v = card.get("aetherValue")
	if v != null and str(v).strip_edges() != "":
		var n = num(v, null)
		if n != null:
			return max(0, min(10, n))
	var lvl = max(1, min(6, num(card.get("level"), 1) if truthy(num(card.get("level"), 0)) else 1))
	return lvl + CHIP_RARITY_BONUS.get(_lower(card.get("rarity", "")), 0)


# ================================================================== line of sight
## Handbook 15.3. A Unit sees a target if any point in its tile joins any point
## in the target's tile by a straight line touching no wall. Walls sit on the
## edge two neighbouring hexes share.
const LOS_DIRS := [[1, 0], [0, 1], [-1, 1], [-1, 0], [0, -1], [1, -1]]


## Sight is worked out in whole-precision numbers, as the Companion's is. (It
## was first written with Vector2, which holds single precision: a line that
## only just touched a wall's end could be read the other way. Found by the
## comparison in 0.7.) A point is [x, y].
static func hex_centre(q, r) -> PackedFloat64Array:
	return PackedFloat64Array([sqrt(3.0) * (q + r / 2.0), 1.5 * r])


static func hex_corner(q, r, k: int) -> PackedFloat64Array:
	var a := PI / 180.0 * (60 * k - 30)
	return PackedFloat64Array([sqrt(3.0) * (q + r / 2.0) + cos(a), 1.5 * r + sin(a)])


## Walls keyed "q,r|q,r", as the Sandbox saves them, to segments: each a pair of points.
static func wall_segments(walls) -> Array:
	var out := []
	for key in (walls.keys() if walls is Dictionary else []):
		var ends := str(key).split("|")
		if ends.size() != 2:
			continue
		var a := hex_parse(ends[0])
		var b := hex_parse(ends[1])
		for i in 6:
			if a["q"] + LOS_DIRS[i][0] == b["q"] and a["r"] + LOS_DIRS[i][1] == b["r"]:
				out.append([hex_corner(a["q"], a["r"], i), hex_corner(a["q"], a["r"], (i + 1) % 6)])
				break
	return out


static func _seg_on(ox: float, oy: float, ax: float, ay: float, bx: float, by: float) -> bool:
	return minf(ox, ax) - 1e-9 <= bx and bx <= maxf(ox, ax) + 1e-9 and minf(oy, ay) - 1e-9 <= by and by <= maxf(oy, ay) + 1e-9


## Closed segments (p1 to p2, p3 to p4): touching counts, including at an end.
static func seg_touch(p1x: float, p1y: float, p2x: float, p2y: float, p3x: float, p3y: float, p4x: float, p4y: float) -> bool:
	var d1 := (p4x - p3x) * (p1y - p3y) - (p4y - p3y) * (p1x - p3x)
	var d2 := (p4x - p3x) * (p2y - p3y) - (p4y - p3y) * (p2x - p3x)
	var d3 := (p2x - p1x) * (p3y - p1y) - (p2y - p1y) * (p3x - p1x)
	var d4 := (p2x - p1x) * (p4y - p1y) - (p2y - p1y) * (p4x - p1x)
	var E := 1e-9
	if ((d1 > E and d2 < -E) or (d1 < -E and d2 > E)) and ((d3 > E and d4 < -E) or (d3 < -E and d4 > E)):
		return true
	if absf(d1) <= E and _seg_on(p3x, p3y, p4x, p4y, p1x, p1y): return true
	if absf(d2) <= E and _seg_on(p3x, p3y, p4x, p4y, p2x, p2y): return true
	if absf(d3) <= E and _seg_on(p1x, p1y, p2x, p2y, p3x, p3y): return true
	if absf(d4) <= E and _seg_on(p1x, p1y, p2x, p2y, p4x, p4y): return true
	return false


## The centre, and the corners and edge midpoints pulled a little inward, so a
## line cannot run along an edge shared with a walled neighbour and slip
## through: thirteen points, as x, y, x, y...
static func tile_points(q, r) -> PackedFloat64Array:
	var c := hex_centre(q, r)
	var pts := PackedFloat64Array([c[0], c[1]])
	var IN := 0.86
	for k in 6:
		var a := hex_corner(q, r, k)
		var b := hex_corner(q, r, (k + 1) % 6)
		pts.append(c[0] + (a[0] - c[0]) * IN)
		pts.append(c[1] + (a[1] - c[1]) * IN)
		pts.append(c[0] + ((a[0] + b[0]) / 2 - c[0]) * IN)
		pts.append(c[1] + ((a[1] + b[1]) / 2 - c[1]) * IN)
	return pts


static func line_of_sight(from, to, walls = null, segs = null) -> bool:
	if from == null or to == null:
		return false
	if from["q"] == to["q"] and from["r"] == to["r"]:
		return true
	if segs == null:
		segs = wall_segments(walls)
	if segs.is_empty():
		return true
	var A := tile_points(from["q"], from["r"])
	var B := tile_points(to["q"], to["r"])
	for i in range(0, A.size(), 2):
		var px := A[i]
		var py := A[i + 1]
		for j in range(0, B.size(), 2):
			var qx := B[j]
			var qy := B[j + 1]
			var minx := minf(px, qx) - 1
			var maxx := maxf(px, qx) + 1
			var miny := minf(py, qy) - 1
			var maxy := maxf(py, qy) + 1
			var blocked := false
			for s in segs:
				var s1x: float = s[0][0]
				var s1y: float = s[0][1]
				var s2x: float = s[1][0]
				var s2y: float = s[1][1]
				if maxf(s1x, s2x) < minx or minf(s1x, s2x) > maxx or maxf(s1y, s2y) < miny or minf(s1y, s2y) > maxy:
					continue
				if seg_touch(px, py, qx, qy, s1x, s1y, s2x, s2y):
					blocked = true
					break
			if not blocked:
				return true
	return false
