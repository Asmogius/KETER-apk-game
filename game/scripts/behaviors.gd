## The Behavior keywords you give your own Units, for Auto. (Handbook, Enemy
## Behavior: "Player Units may carry them too, up to three each.")
##
## A Unit fights by the keywords on its card. You may change them in its
## panel during a fight, and the game remembers what you chose for that card
## (by its name), so the next Unit of that card arrives with the same. Order
## matters: where two conditions are both met, the one chosen first wins.
class_name Behaviors
extends RefCounted

const FILE := "user://behaviors.json"
const MOST := 3

## Where the choices are kept (the tests point this somewhere of their own).
static var path := FILE
static var _cache = null         # {card name: [{k, x}]}, once read
static var _cache_path := ""


## The twelve a Unit of yours may carry, in the Handbook's order.
static func choices() -> Array:
	return Rules.behaviors().filter(func(b): return b["side"] == "ally")


# ---------------------------------------------------------------- a list of them
## A list as the rules read it: only keywords for your side, each once, three
## at most, a number where the keyword takes one (its usual if none is given).
static func clean(list) -> Array:
	var out := []
	for b in (list if list is Array else []):
		if not (b is Dictionary):
			continue
		var d = Rules.beh_of(b.get("k"))
		if d == null or d["side"] != "ally" or out.any(func(o): return o["k"] == d["k"]):
			continue
		var o := {"k": d["k"]}
		if d.has("param"):
			var v = Rules.num(b.get("x"), d["pdef"])
			o["x"] = clampi(int(v) if Rules.truthy(v) else 0, 1, 99) if b.has("x") else int(d["pdef"])
		out.append(o)
		if out.size() >= MOST:
			break
	return out


static func has(list: Array, k: String) -> bool:
	return list.any(func(b): return b.get("k") == k)


## Puts a keyword on, or takes it off. Returns {list, note}: note says why
## nothing changed, when a fourth is asked for.
static func toggle(list: Array, k: String) -> Dictionary:
	var now := clean(list)
	if has(now, k):
		return {"list": now.filter(func(b): return b["k"] != k), "note": ""}
	var d = Rules.beh_of(k)
	if d == null or d["side"] != "ally":
		return {"list": now, "note": ""}
	if now.size() >= MOST:
		return {"list": now, "note": "A Unit carries three Behavior keywords at most. Take one off first."}
	var o := {"k": k}
	if d.has("param"):
		o["x"] = int(d["pdef"])
	now.append(o)
	return {"list": now, "note": ""}


## Changes the number on a keyword that takes one (Wary X, Prudent X): 1 to 99.
static func step(list: Array, k: String, by: int) -> Array:
	var now := clean(list)
	for b in now:
		if b["k"] == k and b.has("x"):
			b["x"] = clampi(int(b["x"]) + by, 1, 99)
	return now


## "Decisive, then Wary 2", or "" for none.
static func words(list) -> String:
	var bits := []
	for b in clean(list):
		var d = Rules.beh_of(b["k"])
		bits.append(str(d["name"]) + ((" " + str(b["x"])) if b.has("x") else ""))
	return ", then ".join(bits)


## What a keyword does, with its own number in place.
static func text_of(b: Dictionary) -> String:
	var d = Rules.beh_of(b.get("k"))
	if d == null:
		return ""
	var t := str(d["text"])
	if d.has("param"):
		t = t.replace(" X ", " %d " % int(b["x"] if b.has("x") else d["pdef"]))
	return t


## What the rules have to say about a choice. The Card Forge says the same of
## an Enemy's: two keywords that both always apply leave the second doing nothing.
static func problems(list) -> Array:
	var out := []
	var defs := clean(list).map(func(b): return Rules.beh_of(b["k"]))
	var aim := defs.filter(func(d): return d["cat"] == "target" and not d["cond"])
	if aim.size() > 1:
		out.append("%s and %s both choose a target and neither has a condition, so %s will never apply." % [aim[0]["name"], aim[1]["name"], aim[1]["name"]])
	var go := defs.filter(func(d): return d["cat"] == "move" and not d["cond"])
	if go.size() > 1:
		out.append("%s and %s both decide movement and neither has a condition." % [go[0]["name"], go[1]["name"]])
	return out


# ---------------------------------------------------------------- remembered
static func load_all() -> Dictionary:
	if _cache is Dictionary and _cache_path == path:
		return _cache
	var d := {}
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f != null:
			var j = JSON.parse_string(f.get_as_text())
			if j is Dictionary and j.get("cards") is Dictionary:
				for name in j["cards"]:
					if j["cards"][name] is Array:
						d[str(name)] = clean(j["cards"][name])
	_cache = d
	_cache_path = path
	return d


static func save_all(d: Dictionary) -> bool:
	_cache = d
	_cache_path = path
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify({"format": 1, "cards": d}, "  "))
	return true


## What you chose for a card, or null if you never chose.
static func for_card(name: String) -> Variant:
	return load_all().get(name)


## Remembers a choice for a card. Returns whether it could be saved.
static func remember(name: String, list) -> bool:
	var d := load_all()
	d[name] = clean(list)
	return save_all(d)


## Forgets everything (for the tests).
static func forget_all() -> void:
	_cache = null
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Gives a Unit of yours what you chose for its card, the first time it is
## seen. One whose card you never chose for keeps what the card says.
static func apply(u: Dictionary) -> void:
	if u.get("side") != "ally" or u.has("behSeen"):
		return
	u["behSeen"] = true
	var mine = for_card(str(u.get("src") if Rules.truthy(u.get("src")) else u.get("name")))
	if mine is Array:
		u["behaviors"] = clean(mine).map(func(b): return b.duplicate())
