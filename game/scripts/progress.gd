## What you have found: blueprints and chassis. (The Companion's progress.js.)
##
## A blueprint unlocks a keyword. Target words, damage, heal and turns are
## free from the start; every other keyword is a blueprint. One with a number
## has three levels, each raising the highest number allowed (Burst: 2, 3, 4);
## the rest have one. A chassis is a frame a Troop is built on. One General
## chassis is the starter.
##
## Each District has a pool of the blueprint levels and chassis that can drop
## there; an Enemy card can add its own, and name set drops with their own
## chance. A drop only ever gives the next level you are missing, or a chassis
## you do not have.
##
## An item is a short text: "bp:Burst:2" or "ch:<chassis id>".
##
## Levels 2 and 3 of a blueprint can also be researched with shards, in the
## Workshop, while no Strike Team is out.
##
## The testing switch ("all") unlocks every blueprint and chassis while it is
## on. Nothing new drops meanwhile, because nothing is missing.
##
## Proved to roll what progress.js rolls, seed for seed (tests/world_diff.gd),
## and to count what it counts (tests/workshop_diff.gd).
class_name Progress
extends RefCounted

const STARTER := "ch_test_general"
const FREE := ["damage", "heal", "turns"]
## District 3 (where the test floors are) starts with a test pool: what an
## export with no pools of its own uses. 0.22: with content batch 1's movement keywords.
const DEFAULT_POOLS := {"3": {"items": ["bp:Burst:1", "bp:Burst:2", "bp:Pierce:1", "bp:Marked:1", "bp:Weakened:1", "bp:Weakened:2", "bp:Slowed:1",
	"bp:AoE:1", "bp:when:1", "bp:is attacked:1", "ch:ch_test_threshold", "ch:ch_test_verdant",
	"bp:Lunge:1", "bp:Charge:1", "bp:Dash:1", "bp:Leap:1"], "test": true}}

## What is owned: {bp: {keyword: level}, ch: {chassis id: true}, named: {"bp:Burst" or "ch:<id>": 1},
## all: the testing switch}. It is the Campaign's to save; this class only reads and changes it.
var state := {"bp": {}, "ch": {}, "named": {}, "all": false, "seen": {"enemy": {}, "district": {}, "comp": {}}}
var pools := {}               # District -> {items: [...]}
var chassis := {}             # id -> the chassis as exported
var caps := {}                # keyword -> [n, n, n], where you changed them in the Workshop's tables
var research_prices := {}     # keyword -> [0, n, n], likewise
var research_default: Array = [0, 60, 120]
var loot: Loot                # the stream every roll comes from


## pools_content, chassis_content, tables_content: content/pools.json,
## chassis.json and tables.json out of the export (any may be empty).
func _init(stream: Loot, pools_content = null, chassis_content = null, tables_content = null) -> void:
	loot = stream if stream != null else Loot.new()
	var p = pools_content.get("pools") if pools_content is Dictionary else null
	pools = Rules.ints(p) if p is Dictionary else DEFAULT_POOLS.duplicate(true)
	for c in (chassis_content.get("chassis", []) if chassis_content is Dictionary else []):
		if c is Dictionary and Rules.truthy(c.get("id")):
			chassis[str(c["id"])] = c
	var ws = tables_content.get("workshop") if tables_content is Dictionary else null
	if ws is Dictionary and ws.get("caps") is Dictionary:
		caps = Rules.ints(ws["caps"])
	if ws is Dictionary and ws.get("research") is Dictionary:
		research_prices = Rules.ints(ws["research"])
	if ws is Dictionary and ws.get("researchDefault") is Array:
		research_default = Rules.ints(ws["researchDefault"])


static func blank() -> Dictionary:
	return {"bp": {}, "ch": {}, "named": {}, "all": false, "seen": {"enemy": {}, "district": {}, "comp": {}}}


## A saved state with anything missing filled in.
static func tidy(s) -> Dictionary:
	var out := blank()
	if s is Dictionary:
		for k in ["bp", "ch", "named"]:
			if s.get(k) is Dictionary:
				out[k] = s[k]
		out["all"] = Rules.truthy(s.get("all"))
		if s.get("seen") is Dictionary:
			for k in ["enemy", "district", "comp"]:
				if s["seen"].get(k) is Dictionary:
					out["seen"][k] = s["seen"][k]
	return out


# ---------------------------------------------------------------- what has been met (0.10)
## The Districts fought in, the Enemies met, the components brought home:
## the dock's Exchange and Bounty Board draw on them. Every fight counts,
## practice ones too, as in the Companion.
func see(kind: String, key) -> void:
	if key == null or str(key) == "":
		return
	if not (state.get("seen") is Dictionary):
		state["seen"] = {"enemy": {}, "district": {}, "comp": {}}
	if not (state["seen"].get(kind) is Dictionary):
		state["seen"][kind] = {}
	state["seen"][kind][str(key)] = 1


func seen(kind: String, key) -> bool:
	return state.get("seen") is Dictionary and state["seen"].get(kind) is Dictionary and Rules.truthy(state["seen"][kind].get(str(key)))


## An Enemy's District: its first Affinity's.
static func enemy_district(c) -> String:
	var a = (c.get("affinities") if c is Dictionary and c.get("affinities") is Array else [])
	var f = a[0] if not a.is_empty() else null
	return str(f["district"]) if f is Dictionary and Rules.truthy(f.get("district")) else ""


static func is_foe(c) -> bool:
	return c is Dictionary and ["enemy", "elite", "miniboss", "boss"].has(str(c.get("cardType", "")))


## The testing switch: every blueprint and chassis counts as owned while it is on.
func unlock_all() -> bool:
	return Rules.truthy(state.get("all"))


func set_unlock_all(on: bool) -> void:
	state["all"] = on


# ---------------------------------------------------------------- the blueprints
## Revision 16.3: a whole side, and Troop or Hero, are Targets worth researching, unlike the rest
const PAID_TARGETS := ["all allies", "all enemies", "Troop", "Hero"]


static func is_free(k) -> bool:
	return k is Dictionary and ((k.get("cat") == "target" and not PAID_TARGETS.has(k.get("name"))) or FREE.has(k.get("name")))


static func levels_of(k) -> int:
	if k is Dictionary and (k.get("num") == "amount" or k.get("num") == "signed") and k.get("cat") != "condition" and k.get("cat") != "duration":
		return 3
	return 1


static func default_caps(k) -> Variant:
	if levels_of(k) == 1:
		return null
	if k.get("name") == "Burst" or k.get("name") == "Line":
		return [2, 3, 4]
	if k.get("cat") == "stats":
		return [2, 4, 6]
	return [1, 2, 3]


## The highest number each level of a keyword allows, or null for one with a single level.
func caps_of(name) -> Variant:
	var k = Keywords.by_name(name)
	if k == null:
		return null
	var d = default_caps(k)
	if d == null:
		return null
	var mine = caps.get(str(name))
	if mine is Array and mine.size() == 3:
		var out := []
		for i in 3:
			var v = Rules.num(mine[i], 0)
			var x: int = int(v) if Rules.truthy(v) else 0
			out.append(x if x > 0 else d[i])
		return out
	return d


## {name, cat, levels, caps}, or null for a keyword that is free or unknown.
func blueprint_of(name) -> Variant:
	var k = Keywords.by_name(name)
	if k == null or is_free(k):
		return null
	return {"name": k["name"], "cat": k["cat"], "levels": levels_of(k), "caps": caps_of(k["name"])}


## Every blueprint there is: [{name, cat, levels, caps}], in the library's order.
func catalog() -> Array:
	var out := []
	for k in Keywords.all_keywords():
		if not is_free(k) and not Keywords.is_retired(k["name"]):
			out.append({"name": k["name"], "cat": k["cat"], "levels": levels_of(k), "caps": caps_of(k["name"])})
	return out


func is_blueprint(name) -> bool:
	var k = Keywords.by_name(name)
	return k != null and not is_free(k)


## The level a keyword needs to be used with this number: 0 if it is free, 4
## if the number is over the most any level allows.
func level_for(name, n) -> int:
	var b = blueprint_of(name)
	if b == null:
		return 0
	if b["levels"] == 1 or b["caps"] == null:
		return 1
	var v = Scoring.digits(str(n) if n != null else "")
	if v == null:
		return 1
	for i in 3:
		if absi(v) <= b["caps"][i]:
			return i + 1
	return 4


## What the next level of a blueprint costs to research, in shards.
func research_price(name, level: int) -> int:
	var mine = research_prices.get(str(name))
	var v = null
	if mine is Array and level >= 1 and level <= mine.size() and mine[level - 1] != null and not (mine[level - 1] is String and mine[level - 1] == ""):
		v = Rules.num(mine[level - 1], null)
	elif level >= 1 and level <= research_default.size():
		var d := Scoring.parse_float(research_default[level - 1])
		v = null if is_nan(d) else int(d)
	return int(v) if v != null else 0


## The highest level owned. A free keyword counts as everything.
func owned(name) -> int:
	var b = blueprint_of(name)
	if b == null:
		return 99
	if unlock_all():
		return b["levels"]
	var v = Rules.num(state["bp"].get(str(name)), 0)
	return mini(b["levels"], int(v) if Rules.truthy(v) else 0)


## (0.28) A chassis made in the Sandbox is yours as soon as it is made.
func has_chassis(id) -> bool:
	return unlock_all() or Rules.truthy(state["ch"].get(str(id))) or str(id) == STARTER or (chassis.get(str(id)) is Dictionary and chassis[str(id)].get("_sandbox") == "made")


## The keywords a set of abilities uses, each at the highest level any use
## needs: [{name, level}], in the order they first appear.
func needs(abilities) -> Array:
	var order := []
	var most := {}
	for a in (abilities if abilities is Array else []):
		if not (a is Dictionary):
			continue
		for p in Keywords.parse(a["text"] if Rules.truthy(a.get("text")) else ""):
			if p["type"] != "kw" or p.get("kw") == null or Rules.truthy(p["kw"].get("archetype")):
				continue
			var nm: String = p["kw"]["name"]
			var lv := level_for(nm, p.get("n"))
			if lv == 0:
				continue
			if not most.has(nm):
				order.append(nm)
				most[nm] = lv
			elif most[nm] < lv:
				most[nm] = lv
	return order.map(func(k): return {"name": k, "level": most[k]})


## What a design uses that you don't own yet: [{name, level, have, over, max}].
func missing(abilities) -> Array:
	var out := []
	for n in needs(abilities):
		var have := owned(n["name"])
		if have < n["level"]:
			var b: Dictionary = blueprint_of(n["name"])
			out.append({"name": n["name"], "level": n["level"], "have": have, "over": n["level"] > b["levels"], "max": b["caps"][b["levels"] - 1] if b["caps"] != null else null})
	return out


## Research the next level with shards from the stockpile: levels 2 and 3
## only, and only while no Strike Team is out. stock is the bag the shards
## come out of. Returns {ok, level, price} or {ok: false, why}.
func research(name, stock: Dictionary, team_out := false) -> Dictionary:
	var b = blueprint_of(name)
	if b == null:
		return {"ok": false, "why": "Not a blueprint"}
	if team_out:
		return {"ok": false, "why": "The dock is closed while a Strike Team is out"}
	var hv = Rules.num(state["bp"].get(str(name)), 0)
	var have: int = int(hv) if Rules.truthy(hv) else 0
	var next := have + 1
	if have < 1:
		return {"ok": false, "why": "Its first level has to be found"}
	if next > b["levels"]:
		return {"ok": false, "why": "Already at its highest level"}
	var price := research_price(name, next)
	var shards := int(Rules.num(stock.get("shards"), 0))
	if shards < price:
		return {"ok": false, "why": "Needs %d shards; you have %d" % [price, shards], "price": price}
	stock["shards"] = shards - price
	state["bp"][str(name)] = next
	return {"ok": true, "level": next, "price": price}


# ---------------------------------------------------------------- items
## "bp:Burst:2" -> {kind: "bp", name, level}; "ch:x" -> {kind: "ch", id}; else null.
static func parse_item(it) -> Variant:
	var s := str(it if it != null else "")
	var m := Keywords._re("^bp:(.+):(\\d)$").search(s)
	if m != null:
		return {"kind": "bp", "name": m.get_string(1), "level": int(m.get_string(2))}
	var c := Keywords._re("^ch:(.+)$").search(s)
	if c != null:
		return {"kind": "ch", "id": c.get_string(1)}
	# (0.22) a card found, a Consumable or a Prototype, kept at the dock
	var d := Keywords._re("^cd:(.+)$").search(s)
	if d != null:
		return {"kind": "cd", "name": d.get_string(1)}
	return null


static func item_id(o: Dictionary) -> String:
	if o["kind"] == "cd":
		return "cd:" + str(o["name"])
	return ("bp:%s:%d" % [o["name"], int(o["level"])]) if o["kind"] == "bp" else ("ch:" + str(o["id"]))


## Can this item drop for you now? The next level you are missing, in order;
## a chassis you don't own. pending is what has been found and not yet kept.
func eligible(it, pending: Array = []) -> bool:
	var o = parse_item(it)
	if o == null:
		return false
	if o["kind"] == "cd":
		return true               # a card can be found again and again
	var pend := pending.map(func(p): return parse_item(p)).filter(func(p): return p != null)
	if o["kind"] == "ch":
		if not chassis.has(o["id"]):
			return false
		return not has_chassis(o["id"]) and not pend.any(func(p): return p["kind"] == "ch" and p["id"] == o["id"])
	var b = blueprint_of(o["name"])
	if b == null or o["level"] < 1 or o["level"] > b["levels"]:
		return false
	var have := owned(o["name"])
	for p in pend:
		if p["kind"] == "bp" and p["name"] == o["name"] and p["level"] > have:
			have = p["level"]
	return o["level"] == have + 1


## The item is yours. Returns false for one that can't be taken: a level out
## of order, or a chassis already owned.
func grant(it) -> bool:
	var o = parse_item(it)
	if o == null:
		return false
	if o["kind"] == "cd":
		# (0.22) kept at the dock, like one bought there
		if not card_sink.is_valid():
			return false
		card_sink.call(str(o["name"]))
		return true
	if o["kind"] == "ch":
		if has_chassis(o["id"]) and not unlock_all():
			return false
		state["ch"][o["id"]] = true
		return true
	var v = Rules.num(state["bp"].get(o["name"]), 0)
	var have: int = int(v) if Rules.truthy(v) else 0
	if o["level"] != have + 1:
		return false
	state["bp"][o["name"]] = o["level"]
	return true


## A fight won with this in hand: you know what it is from now on, even if
## it never reaches the dock.
func name(it) -> void:
	var o = parse_item(it)
	if o != null and o["kind"] != "cd":
		state["named"][("bp:" + str(o["name"])) if o["kind"] == "bp" else ("ch:" + str(o["id"]))] = 1


func known_bp(name) -> bool:
	return owned(name) >= 1 or Rules.truthy(state["named"].get("bp:" + str(name)))


func known_ch(id) -> bool:
	return has_chassis(id) or Rules.truthy(state["named"].get("ch:" + str(id)))


## "Burst L2 (up to 3)", a chassis's name, or "an unknown blueprint" until
## you know it. reveal says it anyway.
func item_name(it, reveal := false) -> String:
	var o = parse_item(it)
	if o == null:
		return str(it if it != null else "")
	if o["kind"] == "cd":
		return str(o["name"])
	if o["kind"] == "ch":
		var c = chassis.get(o["id"])
		var nm: String = str(c["name"]) if c is Dictionary and Rules.truthy(c.get("name")) else str(o["id"])
		return nm if (reveal or known_ch(o["id"])) else "an unknown chassis"
	var b = blueprint_of(o["name"])
	if not (reveal or known_bp(o["name"])):
		return "an unknown blueprint"
	var lv := (" L%d" % o["level"]) if b != null and b["levels"] > 1 else ""
	# (a level no keyword has reads as the Companion reads it: "up to undefined")
	var cap := (" (up to %s)" % (str(b["caps"][o["level"] - 1]) if o["level"] >= 1 and o["level"] <= 3 else "undefined")) if b != null and b["caps"] != null else ""
	return str(o["name"]) + lv + cap


## "Blueprint", "Chassis" or "Card".
static func kind_word(it) -> String:
	return "Chassis" if str(it).begins_with("ch:") else ("Card" if str(it).begins_with("cd:") else "Blueprint")


# ---------------------------------------------------------------- pools
func pool_items(d) -> Array:
	var p = pools.get(str(d if d != null else ""))
	return p["items"].duplicate() if p is Dictionary and p.get("items") is Array else []


# ---------------------------------------------------------------- rolling
static func _pct(v) -> float:
	return clampf(World.number(v), 0.0, 100.0)


## o: {chance (per cent), district, card (an Enemy's, with lootPool and setDrops)}.
## Set drops each roll their own chance; then, by the chance given, one item
## from the District's pool and the card's own that you could use.
## stream: the numbers to roll with, where they aren't this one's own (a
## fight rolls with its own).
func roll_items(o: Dictionary, pending: Array = [], stream: Loot = null) -> Array:
	var from: Loot = stream if stream != null else loot
	var out := []
	var card: Dictionary = o["card"] if o.get("card") is Dictionary else {}
	for d in (card["setDrops"] if card.get("setDrops") is Array else []):
		if not (d is Dictionary) or not Rules.truthy(d.get("item")):
			continue
		if from.rnd() * 100.0 < _pct(d.get("chance")) and eligible(d["item"], pending + out):
			out.append(d["item"])
	if from.rnd() * 100.0 < World.number(o.get("chance")):
		var cands := []
		for it in pool_items(o.get("district")) + (card["lootPool"] if card.get("lootPool") is Array else []):
			if not cands.has(it) and eligible(it, pending + out):
				cands.append(it)
		if not cands.is_empty():
			out.append(cands[int(floor(from.rnd() * cands.size()))])
	# (0.22) and, from an Elite, a Mini-Boss, a Boss, a Cache or a POI's reward, a card
	if World.number(o.get("cardChance")) > 0 and from.rnd() * 100.0 < World.number(o.get("cardChance")):
		var cd = card_drop(o.get("district"), o.get("skull"), from)
		if cd != null:
			out.append(cd)
	return out


# ---------------------------------------------------------------- (0.22) cards as loot
## The Consumables and Prototypes of a District (or of none), the rarer ones
## only at higher Skull Levels: common from Skull 1, uncommon from 2, rare from
## 3, epic from 4, legendary from 5. Sorted by name. (cardPool)
const RARITY_ORDER := ["common", "uncommon", "rare", "epic", "legendary"]
var card_source := Callable()     # () -> the cards that can be found (the roster's)
var card_sink := Callable()       # (name) -> a card found reaches the dock


static func card_district(c: Dictionary) -> String:
	var a = (c.get("affinities") if c.get("affinities") is Array else [])
	var d := ""
	if not a.is_empty() and a[0] is Dictionary and a[0].get("district") != null:
		d = str(a[0]["district"])
	elif c.get("district") != null:
		d = str(c["district"])
	return "" if d == "any" else d


func card_pool(district, skull) -> Array:
	var cards: Array = card_source.call() if card_source.is_valid() else []
	var d := str(district if district != null else "")
	var sk := clampi(int(Rules.num(skull, 0)) if Rules.truthy(Rules.num(skull, 0)) else 1, 1, 6)
	var seen := {}
	var out := []
	for c in cards:
		if not (c is Dictionary):
			continue
		var t := str(c.get("cardType") if c.get("cardType") != null else c.get("type", "")).to_lower()
		if t != "consumable" and t != "prototype":
			continue
		if Rules.truthy(c.get("testCard")):
			continue              # the test cards are for checking the rules, never loot
		var cdd := card_district(c)
		if cdd != "" and cdd != d:
			continue
		var r := RARITY_ORDER.find(str(c.get("rarity") if c.get("rarity") != null else "common").to_lower())
		if r < 0:
			r = 0
		var nm := str(c.get("name") if c.get("name") != null else "")
		if r > sk - 1 or nm == "" or seen.has(nm):
			continue
		seen[nm] = true
		out.append(nm)
	out.sort()
	return out


func card_drop(district, skull, stream: Loot = null) -> Variant:
	var from: Loot = stream if stream != null else loot
	var l := card_pool(district, skull)
	return ("cd:" + str(l[int(floor(from.rnd() * l.size()))])) if not l.is_empty() else null


## A floor reward's item lines: {kind: "item", item, chance}.
func roll_reward_items(rw, pending: Array = [], stream: Loot = null) -> Array:
	var from: Loot = stream if stream != null else loot
	var out := []
	for l in (rw["lines"] if rw is Dictionary and rw.get("lines") is Array else []):
		if not (l is Dictionary) or l.get("kind") != "item" or not Rules.truthy(l.get("item")):
			continue
		if from.rnd() * 100.0 < _pct(l.get("chance")) and eligible(l["item"], pending + out):
			out.append(l["item"])
	return out


## What is owned, as lines for the dock: [{item, text}], blueprints by name
## then chassis.
func owned_lines() -> Array:
	var out := []
	var names: Array = state["bp"].keys()
	names.sort()
	for n in names:
		var b = blueprint_of(n)
		var lv := owned(n)
		if b == null or lv < 1:
			continue
		out.append({"item": "bp:%s:%d" % [n, lv], "kind": "Blueprint",
			"text": str(n) + ((" · level %d of %d (numbers up to %s)" % [lv, b["levels"], str(b["caps"][lv - 1])]) if b["levels"] > 1 and b["caps"] != null else "")})
	var ids: Array = state["ch"].keys()
	ids.sort()
	for id in ids:
		if Rules.truthy(state["ch"][id]):
			out.append({"item": "ch:" + str(id), "kind": "Chassis", "text": item_name("ch:" + str(id), true)})
	return out
