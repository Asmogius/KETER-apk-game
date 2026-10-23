## The dock: home base between deployments. (The Companion's dock.js.)
##
## The Exchange sells components (Commons always; a few limited lots of rarer
## ones, never rarer than your reach, the highest Skull Level a haul has come
## home from), blueprints and chassis from the pools of Districts you have
## fought in (only what you could get next), Consumables and Prototypes, and
## pre-built Troops: finished designs you can't make yet, bought by the copy
## for the next deployment only. It restocks after a deployment that revealed
## new ground, and buys components, Consumables and Prototypes back at half
## price.
##
## Reclaiming turns three of a rarity into one of the next (never past your
## reach) and two of one part type into one of another.
##
## The Bounty Board names two Enemies and one Elite, Mini-Boss or Boss you have
## met; beat one in a won fight on a deployment and it pays shards and
## components when you get home.
##
## Upgrades, paid in shards and parts: more Exchange stock, more free starter
## copies, insurance on a wiped haul, and a longer-range scanner.
##
## The dock is closed while a Strike Team is out.
##
## The game's own, beside dock.js: an export whose Exchange list is empty (none
## ticked in the Companion's Dev Mode) carries every Consumable and Prototype
## at 20 shards. Everything else is proved to be dock.js's, roll for roll
## (tests/dock_diff.gd).
class_name Dock
extends RefCounted

const UPGRADES := [
	{"id": "exchange", "name": "Exchange stock", "what": "More lots of rarer components, and more pre-built Troops on offer at once."},
	{"id": "starter", "name": "Starter bay", "what": "More free starter copies every deployment."},
	{"id": "insurance", "name": "Salvage insurance", "what": "Keep a share of the haul's shards and parts after a wipe."},
	{"id": "scanner", "name": "Long-range scanner", "what": "See what tiles hold further from where the Strike Team stands."}]
const KIND_LABEL := {"enemy": "Enemy", "elite": "Elite", "miniboss": "Mini-Boss", "boss": "Boss"}
const DEFAULTS := {"v": 1,
	"price": [6, 15, 40, 100, 250, 600], "sell": 0.5,
	"bpFirst": 150, "bpLater": 1.25, "chassis": 300, "preMult": 1.5,
	"lots": 3, "lotMax": 3, "bpOffers": 2, "chOffers": 1, "itemsOnOffer": 3, "preOnOffer": 3,
	"reclaimUp": 3, "reclaimSwap": 2,
	"bounty": {"shards": {"enemy": 15, "elite": 30, "miniboss": 60, "boss": 120}, "n": {"enemy": 1, "elite": 2, "miniboss": 3, "boss": 5}},
	"items": [],
	"effect": {"exchange": [1, 2, 3], "starter": [6, 8, 10], "insurance": [10, 20, 30], "scanner": [2, 3, 4]},
	"cost": {"exchange": [[150, "equipment", 0, 10], [400, "equipment", 1, 6], [900, "equipment", 2, 3]],
		"starter": [[150, "troop", 0, 10], [400, "troop", 1, 6], [900, "troop", 2, 3]],
		"insurance": [[150, "aether", 0, 10], [400, "aether", 1, 6], [900, "aether", 2, 3]],
		"scanner": [[150, "equipment", 0, 10], [400, "equipment", 1, 6], [900, "equipment", 2, 3]]}}
const SCALARS := ["sell", "bpFirst", "bpLater", "chassis", "preMult", "lots", "lotMax", "bpOffers", "chOffers", "itemsOnOffer", "preOnOffer", "reclaimUp", "reclaimSwap"]
const CLOSED := "The dock is closed while a Strike Team is out"
## What a Consumable or Prototype costs when the export ticks none for the Exchange.
const FALLBACK_PRICE := 20

var tables: Dictionary = DEFAULTS.duplicate(true)
var state := blank()
var inv := {"cards": {}, "pre": {}}
## (held weakly: the deployment holds the dock, and a pair that holds each other is never freed)
var _deploy_ref: WeakRef = null
var deploy: Deployment:
	get:
		return _deploy_ref.get_ref() if _deploy_ref != null else null
	set(v):
		_deploy_ref = weakref(v) if v != null else null
var progress: Progress = null
var workshop: Workshop = null
var roster: Roster = null
var loot: Loot = null                 # the stream every roll comes from, and the tables to roll on
var world: World = null
## The game's own: with no Consumables or Prototypes ticked for the Exchange,
## it carries all of them. (Off, it is dock.js exactly: the comparison turns it off.)
var fallback_items := true


func _init(dep: Deployment = null, tables_content = null) -> void:
	deploy = dep
	if dep != null:
		progress = dep.progress
		loot = dep.loot
		world = dep.world
		roster = dep.roster
	tables = read_tables(tables_content.get("dock") if tables_content is Dictionary else null)


# ---------------------------------------------------------------- JavaScript, as dock.js reads numbers
## parseFloat(v), or d.
static func num(v, d):
	if v is Array:
		v = ",".join(v.map(func(e): return "" if e == null else (Scoring.text(e) if (e is int or e is float) else str(e))))
	elif v is Dictionary:
		return d
	var x := Scoring.parse_float(v)
	return d if is_nan(x) else x


## parseInt(v, 10), or null.
static func parse_int(v) -> Variant:
	if v == null or v is bool:
		return null
	if v is int:
		return v
	var m := Keywords._re("^\\s*([+-]?\\d+)").search(Scoring.text(v) if v is float else str(v))
	return int(m.get_string(1)) if m != null else null


static func _pi(v) -> int:
	var n = parse_int(v)
	return int(n) if n != null else 0


## JavaScript's unary plus, arrays included (+[] is 0, +[5] is 5).
static func jsplus(v) -> float:
	if v is Array:
		if v.is_empty():
			return 0.0
		if v.size() == 1:
			return jsplus("" if v[0] == null else (Scoring.text(v[0]) if (v[0] is float or v[0] is int) else str(v[0])))
		return NAN
	if v is Dictionary:
		return NAN
	return Scoring.plus(v)


## Whether +v is a finite number (a key that isn't there is undefined).
static func _finite(m: Dictionary, k: String) -> bool:
	if not m.has(k):
		return false
	var x := jsplus(m[k])
	return not is_nan(x) and not is_inf(x)


static func _whole(v):
	return int(v) if v is float and v == floor(v) and absf(v) < 1.0e15 else v


# ---------------------------------------------------------------- the dock's tables
## The export's dock tables over the defaults, as dock.js's tables() reads its own.
static func read_tables(m) -> Dictionary:
	var t: Dictionary = DEFAULTS.duplicate(true)
	if m is Dictionary:
		if m.get("price") is Array and m["price"].size() == 6:
			var pr := []
			for i in 6:
				pr.append(_whole(maxf(0.0, float(num(m["price"][i], DEFAULTS["price"][i])))))
			t["price"] = pr
		for k in SCALARS:
			if m.get(k) != null and _finite(m, k):
				t[k] = _whole(maxf(0.0, jsplus(m[k])))
		if m.get("bounty") is Dictionary:
			for s in ["shards", "n"]:
				if Rules.truthy(m["bounty"].get(s)) and m["bounty"][s] is Dictionary:
					for k in KIND_LABEL:
						if _finite(m["bounty"][s], k):
							t["bounty"][s][k] = _whole(maxf(0.0, jsplus(m["bounty"][s][k])))
		if m.get("items") is Array:
			var its := []
			for x in m["items"]:
				if x is Dictionary and Rules.truthy(x.get("name")):
					its.append({"name": str(x["name"]), "price": _whole(maxf(0.0, float(num(x.get("price"), 20))))})
			t["items"] = its
		if m.get("effect") is Dictionary:
			for u in UPGRADES:
				var e = m["effect"].get(u["id"])
				if e is Array and e.size() == 3:
					var row := []
					for i in 3:
						row.append(_whole(num(e[i], DEFAULTS["effect"][u["id"]][i])))
					t["effect"][u["id"]] = row
		if m.get("cost") is Dictionary:
			for u in UPGRADES:
				var cs = m["cost"].get(u["id"])
				if cs is Array and cs.size() == 3:
					var rows := []
					for i in 3:
						var d: Array = DEFAULTS["cost"][u["id"]][i]
						var c: Array = cs[i] if cs[i] is Array else d
						rows.append([_whole(maxf(0.0, float(num(c[0] if c.size() > 0 else null, d[0])))), c[1] if (c.size() > 1 and ["troop", "equipment", "aether"].has(c[1])) else d[1],
							maxi(0, mini(5, _pi(c[2] if c.size() > 2 else null))), maxi(0, _pi(c[3] if c.size() > 3 else null))])
					t["cost"][u["id"]] = rows
	t["reclaimUp"] = maxi(2, int(Rules.js_round(float(t["reclaimUp"]))))
	t["reclaimSwap"] = maxi(1, int(Rules.js_round(float(t["reclaimSwap"]))))
	return t


## What the Exchange carries of Consumables and Prototypes: the list ticked in
## the Companion, or (the game's own) every one of them at 20 shards when none is.
func items() -> Array:
	if not tables["items"].is_empty() or not fallback_items:
		return tables["items"]
	return fallback_list()


func fallback_list() -> Array:
	var out := []
	var had := {}
	for c in (roster.from_export if roster != null else []):
		var ty := str(c.get("cardType", "")).to_lower()
		if (ty == "consumable" or ty == "prototype") and not had.has(c["name"]):
			had[c["name"]] = true
			out.append({"name": str(c["name"]), "price": FALLBACK_PRICE})
	return out


## Whether the Exchange's Consumables and Prototypes are the game's fallback (none ticked).
func carries_all() -> bool:
	return tables["items"].is_empty() and fallback_items


# ---------------------------------------------------------------- the dock's own state
static func blank() -> Dictionary:
	return {"v": 1, "reach": 0, "upgrades": {"exchange": 0, "starter": 0, "insurance": 0, "scanner": 0}, "stock": null, "bounties": [], "rot": {"pre": 0, "items": 0}, "restocks": 0, "log": []}


## A saved state with anything missing filled in (dock.js's state()).
static func tidy(s) -> Dictionary:
	var o: Dictionary = s.duplicate(true) if s is Dictionary else blank()
	var ups: Dictionary = o["upgrades"] if o.get("upgrades") is Dictionary else {}
	for u in UPGRADES:
		ups[u["id"]] = _pi(ups.get(u["id"]))
	o["upgrades"] = ups
	if not (o.get("rot") is Dictionary):
		o["rot"] = {"pre": 0, "items": 0}
	if not (o.get("bounties") is Array):
		o["bounties"] = []
	if not (o.get("log") is Array):
		o["log"] = []
	var r := Scoring.plus(o.get("reach"))
	o["reach"] = int(r) if not is_nan(r) and r != 0.0 else 0
	if not o.has("stock"):
		o["stock"] = null
	if not o.has("restocks"):
		o["restocks"] = 0
	return o


static func tidy_inv(v) -> Dictionary:
	var o: Dictionary = v.duplicate(true) if v is Dictionary else {}
	if not (o.get("cards") is Dictionary):
		o["cards"] = {}
	if not (o.get("pre") is Dictionary):
		o["pre"] = {}
	return o


func reset() -> void:
	state = blank()
	inv = {"cards": {}, "pre": {}}


func note(text: String) -> void:
	state["log"].push_front({"t": Deployment._now(), "text": text})
	if state["log"].size() > 40:
		state["log"].resize(40)


func closed() -> bool:
	return deploy != null and deploy.active()


## The rarest component within reach: Skull N reaches the Nth rarity.
func reach_rarity() -> int:
	var r: int = int(state["reach"]) if Rules.truthy(state["reach"]) else 1
	return maxi(0, mini(5, r - 1))


func rnd() -> float:
	return loot.rnd() if loot != null else randf()


# ---------------------------------------------------------------- the stockpile (the deployment keeps it)
func stockpile() -> Dictionary:
	return Loot.norm(deploy.stock) if deploy != null else Loot.bag()


func set_stockpile(b: Dictionary) -> void:
	if deploy != null:
		deploy.stock = Loot.norm(b)


func add_to_stockpile(b) -> void:
	set_stockpile(Loot.add(stockpile(), b))


# ---------------------------------------------------------------- what the dock holds for you
func owned(name: String) -> int:
	return int(inv["cards"].get(name, 0))


func add_card(name: String, n: int) -> int:
	var v := maxi(0, owned(name) + n)
	if v == 0:
		inv["cards"].erase(name)
	else:
		inv["cards"][name] = v
	return v


## Pre-built copies bought, waiting for the next deployment: id -> copies.
func waiting() -> Dictionary:
	return inv["pre"]


func card_of(name: String) -> Variant:
	if roster == null:
		return null
	for c in roster.from_export:
		if c.get("name") == name:
			return c
	return null


func item_kind(name: String) -> String:
	var c = card_of(name)
	return str(c.get("cardType", "")) if c != null else ""


# ---------------------------------------------------------------- pre-built Troops
func prebuilts() -> Array:
	return workshop.prebuilts() if workshop != null else []


func pre_cost(d: Dictionary, t = null) -> int:
	var tb: Dictionary = t if t is Dictionary else tables
	var parts: Array = workshop.cost(d)["parts"]
	var sh := 0.0
	for r in parts.size():
		sh += float(parts[r]) * float(tb["price"][r])
	return maxi(1, int(Rules.js_round(sh * float(tb["preMult"]))))


func bp_price(it, t = null):
	var tb: Dictionary = t if t is Dictionary else tables
	var o = Progress.parse_item(it)
	if o == null:
		return 0
	if o["kind"] == "ch":
		return tb["chassis"]
	return tb["bpFirst"] if o["level"] <= 1 else int(Rules.js_round(float(progress.research_price(o["name"], o["level"])) * float(tb["bpLater"])))


# ---------------------------------------------------------------- restocking
static func _cycle(list: Array, from: int, n) -> Array:
	var out := []
	if list.is_empty():
		return out
	# as many as JavaScript's i < Math.min(n, length) gives: a fraction counts up (0.21)
	var lim := minf(float(n), float(list.size()))
	var i := 0
	while float(i) < lim:
		out.append(list[(from + i) % list.size()])
		i += 1
	return out


## The keys of a JavaScript object, in the order it gives them: whole numbers
## first, smallest first, then the rest in the order they were added.
static func js_keys(d: Dictionary) -> Array:
	var nums := []
	var rest := []
	for k in d:
		var s := str(k)
		if s.is_valid_int() and not s.begins_with("-") and not (s.length() > 1 and s.begins_with("0")) and s.length() < 10:
			nums.append(int(s))
		else:
			rest.append(s)
	nums.sort()
	return nums.map(func(n): return str(n)) + rest


func districts_fought() -> Array:
	var d = progress.state.get("seen", {}).get("district", {}) if progress != null else {}
	return js_keys(d if d is Dictionary else {}).filter(func(k): return k != "")


func _pick_n(list: Array, n) -> Array:
	var l := list.duplicate()
	var out := []
	while out.size() < float(n) and not l.is_empty():
		out.append(l.pop_at(int(floor(rnd() * l.size()))))
	return out


func restock(opts: Dictionary = {}) -> Dictionary:
	var t := tables
	var up: int = state["upgrades"]["exchange"]
	var extra = t["effect"]["exchange"][up - 1] if up > 0 else 0
	var top := reach_rarity()
	var lots := []
	# each lot a different part type or rarity, while there are enough to go round
	var kinds := []
	for r0 in range(1, top + 1):
		for ty in Loot.TYPES:
			kinds.append({"type": ty["id"], "rarity": r0})
	var i := 0
	while i < float(t["lots"]) + float(extra) and not kinds.is_empty():
		var k: Dictionary = kinds.pop_at(int(floor(rnd() * kinds.size())))
		lots.append({"type": k["type"], "rarity": k["rarity"], "n": 1 + int(floor(rnd() * maxf(1.0, float(t["lotMax"])))), "bought": 0})
		i += 1
	var order := Loot.TYPES.map(func(x): return x["id"])
	lots = Rules.stable_sort(lots, func(a, b): return (a["rarity"] - b["rarity"]) if a["rarity"] != b["rarity"] else order.find(a["type"]) - order.find(b["type"]))
	# blueprints and chassis: the pools of Districts fought in, only what could come next
	var pool := []
	var had := {}
	for d in districts_fought():
		for it in progress.pool_items(d):
			if not had.has(it):
				had[it] = true
				pool.append(it)
	var bp := pool.filter(func(it): return str(it).begins_with("bp:") and progress.eligible(it))
	var ch := pool.filter(func(it): return str(it).begins_with("ch:") and progress.eligible(it))
	var pre := prebuilts()
	var its := items()
	if state["stock"] is Dictionary and not Rules.truthy(opts.get("first")):
		var sp: Array = state["stock"].get("pre", []) if state["stock"].get("pre") is Array else []
		var si: Array = state["stock"].get("items", []) if state["stock"].get("items") is Array else []
		state["rot"]["pre"] = ((int(state["rot"]["pre"]) + sp.size()) % pre.size()) if not pre.is_empty() else 0
		state["rot"]["items"] = ((int(state["rot"]["items"]) + si.size()) % its.size()) if not its.is_empty() else 0
	var bps := _pick_n(bp, t["bpOffers"])
	var chs := _pick_n(ch, t["chOffers"])
	state["stock"] = {"n": int(state["restocks"]) + 1, "made": Deployment._now(), "lots": lots, "bps": bps, "chs": chs,
		"items": _cycle(its.map(func(x): return x["name"]), int(state["rot"]["items"]), t["itemsOnOffer"]),
		"pre": _cycle(pre.map(func(d): return d["id"]), int(state["rot"]["pre"]), float(t["preOnOffer"]) + float(extra)), "sold": {}}
	state["restocks"] = int(state["restocks"]) + 1
	state["bounties"] = post_bounties()
	note("The Exchange restocked; the Bounty Board changed.")
	return state["stock"]


## What is on offer now (the first stock is laid out the first time it is asked for).
func stock() -> Dictionary:
	if not (state["stock"] is Dictionary):
		restock({"first": true})
	return state["stock"]


## Seeing a blueprint or chassis on the shelf names it.
func see_stock() -> void:
	var st := stock()
	for it in st["bps"] + st["chs"]:
		progress.name(it)


# ---------------------------------------------------------------- buying and selling
func pay(shards) -> bool:
	var st := stockpile()
	if st["shards"] < float(shards):
		return false
	# (a price with a fraction leaves the stockpile at the whole shards below it, as loot.js keeps it)
	st["shards"] = float(st["shards"]) - float(shards)
	set_stockpile(st)
	return true


func short(price) -> Dictionary:
	return {"ok": false, "why": "Needs %s shards; you have %d" % [Scoring.text(price), stockpile()["shards"]]}


## Components: Commons any amount; a lot's rarer ones up to what it holds.
func buy_parts(type: String, rarity, n, lot_index = null) -> Dictionary:
	if closed():
		return {"ok": false, "why": CLOSED}
	var t := tables
	var st := stock()
	var many: int = maxi(1, _pi(n) if _pi(n) != 0 else 1)
	var rr := Scoring.plus(rarity)
	var rar: int = int(rr) if not is_nan(rr) and rr != 0.0 else 0
	var lot = null
	if rar > 0:
		lot = st["lots"][int(lot_index)] if lot_index != null and int(lot_index) >= 0 and int(lot_index) < st["lots"].size() else null
		if lot == null or lot["type"] != type or lot["rarity"] != rar:
			return {"ok": false, "why": "Not in stock"}
		if lot["bought"] + many > lot["n"]:
			return {"ok": false, "why": "Only %d left in that lot" % (lot["n"] - lot["bought"])}
	var price = _whole(float(t["price"][rar]) * many)
	if not pay(price):
		return short(price)
	var st2 := stockpile()
	st2["parts"][type][rar] += many
	set_stockpile(st2)
	if rar > 0:
		lot["bought"] += many
	return {"ok": true, "price": price}


func sell_parts(type: String, rarity, n) -> Dictionary:
	if closed():
		return {"ok": false, "why": CLOSED}
	var t := tables
	var st := stockpile()
	var many: int = maxi(1, _pi(n) if _pi(n) != 0 else 1)
	var rar := int(rarity)
	var have: Array = st["parts"].get(type, [])
	if rar < 0 or rar >= have.size() or have[rar] < many:
		return {"ok": false, "why": "You don't have that many"}
	var gain: int = int(floor(float(t["price"][rar]) * float(t["sell"]))) * many
	st["parts"][type][rar] -= many
	st["shards"] += gain
	set_stockpile(st)
	return {"ok": true, "gain": gain}


func buy_item(it) -> Dictionary:
	if closed():
		return {"ok": false, "why": CLOSED}
	var st := stock()
	if not st["bps"].has(it) and not st["chs"].has(it):
		return {"ok": false, "why": "Not in stock"}
	if not progress.eligible(it):
		return {"ok": false, "why": "You can't use that one yet"}
	var price = bp_price(it)
	if not pay(price):
		return short(price)
	progress.grant(it)
	progress.name(it)
	state["stock"]["sold"][str(it)] = 1
	return {"ok": true, "price": price}


func item_price(name: String):
	for x in items():
		if x["name"] == name:
			return x["price"]
	return 0


func buy_card(name: String, n) -> Dictionary:
	if closed():
		return {"ok": false, "why": CLOSED}
	var many: int = maxi(1, _pi(n) if _pi(n) != 0 else 1)
	if not stock()["items"].has(name):
		return {"ok": false, "why": "Not in stock"}
	var price = _whole(float(item_price(name)) * many)
	if not pay(price):
		return short(price)
	add_card(name, many)
	return {"ok": true, "price": price}


func sell_card(name: String, n) -> Dictionary:
	if closed():
		return {"ok": false, "why": CLOSED}
	var many: int = maxi(1, _pi(n) if _pi(n) != 0 else 1)
	if owned(name) < many:
		return {"ok": false, "why": "You don't have that many"}
	var each = item_price(name)
	if not Rules.truthy(each):
		var c = card_of(name)
		each = num(c.get("price") if c != null else null, 10)
	var gain: int = int(floor(float(each) * float(tables["sell"]))) * many
	add_card(name, -many)
	var st := stockpile()
	st["shards"] += gain
	set_stockpile(st)
	return {"ok": true, "gain": gain}


func buy_pre(id: String, n) -> Dictionary:
	if closed():
		return {"ok": false, "why": CLOSED}
	var many: int = maxi(1, _pi(n) if _pi(n) != 0 else 1)
	if not stock()["pre"].has(id):
		return {"ok": false, "why": "Not in stock"}
	var d = workshop.get_design(id) if workshop != null else null
	if d == null:
		return {"ok": false, "why": "That design is gone"}
	var price: int = pre_cost(d) * many
	if not pay(price):
		return short(price)
	inv["pre"][id] = int(inv["pre"].get(id, 0)) + many
	return {"ok": true, "price": price}


# ---------------------------------------------------------------- Reclaiming
func combine(type: String, rarity, times) -> Dictionary:
	if closed():
		return {"ok": false, "why": CLOSED}
	var t := tables
	var st := stockpile()
	var top := reach_rarity()
	var rar := int(rarity)
	var k: int = maxi(1, _pi(times) if _pi(times) != 0 else 1)
	if rar + 1 > top:
		return {"ok": false, "why": "Nothing rarer than your reach: bring a haul home from further out first"}
	var need: int = int(t["reclaimUp"]) * k
	var have: Array = st["parts"].get(type, [])
	if rar < 0 or rar >= have.size() or have[rar] < need:
		return {"ok": false, "why": "Needs %d of them" % need}
	st["parts"][type][rar] -= need
	st["parts"][type][rar + 1] += k
	set_stockpile(st)
	return {"ok": true, "made": k}


func swap(from: String, to: String, rarity, times) -> Dictionary:
	if closed():
		return {"ok": false, "why": CLOSED}
	var t := tables
	var st := stockpile()
	var rar := int(rarity)
	var k: int = maxi(1, _pi(times) if _pi(times) != 0 else 1)
	if from == to:
		return {"ok": false, "why": "Pick another type"}
	var need: int = int(t["reclaimSwap"]) * k
	var have: Array = st["parts"].get(from, [])
	if rar < 0 or rar >= have.size() or have[rar] < need:
		return {"ok": false, "why": "Needs %d of them" % need}
	st["parts"][from][rar] -= need
	st["parts"][to][rar] += k
	set_stockpile(st)
	return {"ok": true, "made": k}


# ---------------------------------------------------------------- the Bounty Board
func foes() -> Array:
	var had := {}
	var out := []
	for c in (roster.from_export if roster != null else []):
		if Progress.is_foe(c) and not had.has(c["name"]):
			had[c["name"]] = true
			out.append(c)
	return out


func post_bounties() -> Array:
	var fought := districts_fought()
	var met := foes().filter(func(c):
		var d := Progress.enemy_district(c)
		return progress.seen("enemy", c["name"]) and (d == "" or fought.has(d)))
	var small := _pick_n(met.filter(func(c): return c["cardType"] == "enemy"), 2)
	var big := _pick_n(met.filter(func(c): return c["cardType"] != "enemy"), 1)
	return (small + big).map(func(c): return {"name": c["name"], "kind": c["cardType"], "district": Progress.enemy_district(c), "claimed": false})


func bounties() -> Array:
	return state["bounties"]


## The names the Bounty Board wants that aren't claimed yet.
func wanted() -> Array:
	return state["bounties"].filter(func(b): return not Rules.truthy(b.get("claimed"))).map(func(b): return str(b["name"]))


func bounty_pay(kind: String, skull, t = null) -> Dictionary:
	var tb: Dictionary = t if t is Dictionary else tables
	var sk := Scoring.plus(skull)
	var s: int = maxi(1, mini(6, int(sk) if not is_nan(sk) and sk != 0.0 else 1))
	return {"shards": _whole(float(tb["bounty"]["shards"].get(kind, 0)) * s), "lines": [{"kind": "roll", "n": tb["bounty"]["n"].get(kind, 0), "type": "any", "bonus": 0}]}


## A deployment home: its kills claim what they match.
func claim(kills: Array) -> Array:
	var paid := []
	for b in state["bounties"]:
		if Rules.truthy(b.get("claimed")):
			continue
		var mine := kills.filter(func(x): return x is Dictionary and x.get("name") == b["name"])
		mine = Rules.stable_sort(mine, func(a, c): return int(Scoring.plus(c.get("skull"))) - int(Scoring.plus(a.get("skull"))))
		if mine.is_empty():
			continue
		var k: Dictionary = mine[0]
		var bag := loot.roll_reward(bounty_pay(str(b["kind"]), k.get("skull")), k.get("skull"))
		add_to_stockpile(bag)
		b["claimed"] = true
		b["paid"] = bag
		b["skull"] = k.get("skull")
		paid.append({"name": b["name"], "bag": bag})
	if not paid.is_empty():
		note("%d bount%s paid." % [paid.size(), "y" if paid.size() == 1 else "ies"])
	return paid


# ---------------------------------------------------------------- upgrades
func level(id: String) -> int:
	return int(state["upgrades"].get(id, 0))


func effect(id: String):
	var l := level(id)
	return tables["effect"][id][l - 1] if l > 0 else 0


func next_cost(id: String) -> Variant:
	var l := level(id)
	if l >= 3:
		return null
	var c: Array = tables["cost"][id][l]
	return {"shards": c[0], "type": c[1], "rarity": c[2], "n": c[3]}


func upgrade(id: String) -> Dictionary:
	if closed():
		return {"ok": false, "why": CLOSED}
	var c = next_cost(id)
	if c == null:
		return {"ok": false, "why": "Already at its highest level"}
	var st := stockpile()
	if st["shards"] < float(c["shards"]) or st["parts"][c["type"]][c["rarity"]] < int(c["n"]):
		return {"ok": false, "why": "Needs %s shards and %d %s %s parts" % [Scoring.text(c["shards"]), int(c["n"]), Loot.RARITIES[c["rarity"]]["label"], c["type"]]}
	st["shards"] -= int(c["shards"])
	st["parts"][c["type"]][c["rarity"]] -= int(c["n"])
	set_stockpile(st)
	state["upgrades"][id] = level(id) + 1
	var nm := ""
	for u in UPGRADES:
		if u["id"] == id:
			nm = u["name"]
	note("%s raised to level %d." % [nm, state["upgrades"][id]])
	return {"ok": true, "level": state["upgrades"][id]}


## The effects the rest of the game asks for.
func starter_free() -> int:
	var base = Rules.num(world.tables.get("starterFree"), 4) if world != null else 4
	var b: int = int(base) if Rules.truthy(base) else 0
	var e = effect("starter")
	return maxi(b, int(e)) if Rules.truthy(e) else b


func scan_range() -> int:
	var e = effect("scanner")
	return maxi(1, int(e) if Rules.truthy(e) else 1)


func insurance():
	return effect("insurance")


# ---------------------------------------------------------------- a deployment ends: reach, restock, bounties, insurance
## o: {result: "home" | "wipe" | ..., maxSkull, kills, haul, explored}.
func deployment_ended(o: Dictionary) -> Dictionary:
	var out := {}
	var ms := Scoring.plus(o.get("maxSkull"))
	if o.get("result") == "home" and not is_nan(ms) and ms > float(state["reach"]):
		state["reach"] = mini(6, int(ms))
		out["reach"] = state["reach"]
		note("Reach extended to Skull Level %d." % state["reach"])
	if o.get("result") == "home":
		out["bounties"] = claim(o["kills"] if o.get("kills") is Array else [])
	var ins = insurance()
	if o.get("result") == "wipe" and Rules.truthy(ins) and Rules.truthy(o.get("haul")):
		var pc := float(ins) / 100.0
		var h := Loot.norm(o["haul"])
		var kept := Loot.bag()
		kept["shards"] = int(floor(h["shards"] * pc))
		for ty in Loot.TYPES:
			for r in 6:
				kept["parts"][ty["id"]][r] = int(floor(h["parts"][ty["id"]][r] * pc))
		if not Loot.is_empty(kept):
			add_to_stockpile(kept)
			out["insured"] = kept
	if Rules.truthy(o.get("explored")):
		restock()
		out["restocked"] = true
	return out


# ---------------------------------------------------------------- testing (as the Companion's Dev Mode has them)
func restock_now() -> void:
	restock()


func reach_up() -> void:
	state["reach"] = mini(6, int(state["reach"]) + 1)
	note("Reach set to Skull Level %d (testing)." % state["reach"])
