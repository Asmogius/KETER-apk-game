## The Workshop: designing Troops. (The Companion's workshop.js and chassis.js.)
##
## A design is a chassis plus abilities. The chassis fixes its stats (HP, AC,
## MS, NRG, INT and the DMG of its attacks), its subtypes, its Aether cost, a
## power cap, an ability cap, the keywords it allows, and the most range,
## to-hit and armour penetration an attack may have. You name the design,
## write each ability, pick each Action's Energy cost and each attack's range,
## to-hit and AP.
##
## Power: the keyword score (an attack counts 4; Modifiers multiply), plus
## points for an attack's numbers above the baseline, then more for a cheap
## Action (a free one can be used every turn).
##
## A copy costs  chassis cost + rate x power  Common Troop parts, plus whatever
## rarer parts its keywords require at the level used. Copies are paid when a
## Strike Team leaves the dock.
##
## A design is also a Troop card: it goes into a Deck and fights like any other.
##
## The designs are the Campaign's to save; this class reads and changes them.
## Proved to check, score and cost what workshop.js does (tests/workshop_diff.gd).
class_name Workshop
extends RefCounted

const ROLES := ["Melee", "Ranged", "Support", "Cyber"]
## (0.12) what a Ranged or Cyber Action fires, on the screen; none is a bolt (the Companion's PROJECTILES)
const PROJECTILES := ["bolt", "shell", "beam", "spray"]


## What an ability fires: its own, if the game knows it, else a bolt.
static func projectile_of(a) -> String:
	var p = a.get("projectile") if a is Dictionary else null
	return str(p) if PROJECTILES.has(p) else "bolt"
const DEFAULTS := {"v": 1, "rate": 0.5, "energyBase": 2, "energyStep": 0.25,
	# hit: "base" is the to-hit an attack is priced at; "per" is no longer used (see hit_factor)
	"numbers": {"range": {"base": 4, "per": 0.5}, "hit": {"base": 6, "per": 0}, "ap": {"base": 4, "per": 0.5}},
	"researchDefault": [0, 60, 120], "research": {}, "caps": {}, "require": {}}
## The built-in starter: a plain design on the General chassis. Each
## deployment brings a few copies of it free, so it can't be changed; copy it
## to make your own.
const STARTER := {"id": "ds_starter", "name": "Frame Trooper", "chassis": "ch_test_general", "starter": true,
	"abilities": [{"name": "Carbine", "kind": "action", "role": "Ranged", "energy": 1, "range": 4, "hit": 6, "ap": 4, "text": "[[target enemy]] takes [[damage 1]]."}],
	"notes": "The built-in starter: a few free copies every deployment."}
## The starter's chassis, for an export that no longer carries it.
const STARTER_CHASSIS := {"id": "ch_test_general", "name": "Frame · General", "district": "", "bodyPlan": "Bipedal", "subtypes": ["Ranged"],
	"powerCap": 12, "abilityCap": 2, "cost": {"troop": 3}, "maxRange": 6, "bestHit": 4, "maxAP": 6, "aether": {"generic": 1, "affinity": 0},
	"stats": {"hp": 12, "ac": 10, "move": 4, "dmg": 2, "nrg": 3, "int": 10},
	"allowed": ["target enemy", "target ally", "this Unit", "damage", "heal", "turns"], "notes": ""}
const DISTRICTS := [
	{"id": "", "name": "General", "color": "#5d7078", "lite": "#d6e3e8"},
	{"id": "1", "name": "Threshold Dynamics", "color": "#6a49cc", "lite": "#a98ef0"},
	{"id": "2", "name": "Halcyon Cognition", "color": "#c23a8d", "lite": "#ef7fbe"},
	{"id": "3", "name": "Vantage Robotics", "color": "#d1751c", "lite": "#f0a457"},
	{"id": "4", "name": "Lazarus Computing", "color": "#bb3d30", "lite": "#ef8175"},
	{"id": "5", "name": "Verdant Biogenics", "color": "#38914c", "lite": "#6fd189"},
	{"id": "6", "name": "Meridian Entropics", "color": "#1f8da3", "lite": "#56c6da"}]

var progress: Progress
var skins: Skins = null
## The Workshop's tables as the export has them (rate, Energy, attack numbers, part requirements).
var tables := {}
## Every design of yours but the starter: id -> design. The Campaign saves it.
var designs := {}
## Which designs are out on a deployment (the Deployment answers).
var is_out: Callable = Callable()
## The Companion's pre-built Troops (0.10), out of the export: finished designs
## the dock's Exchange sells by the copy. Never yours to change.
var prebuilt_designs: Array = []


func _init(p: Progress, tables_content = null, skin_library: Skins = null) -> void:
	progress = p
	skins = skin_library
	tables = read_tables(tables_content.get("workshop") if tables_content is Dictionary else null)
	if progress != null and not progress.chassis.has(STARTER["chassis"]):
		progress.chassis[STARTER["chassis"]] = STARTER_CHASSIS.duplicate(true)


## The Workshop's tables: the starting values, with whatever the export changed.
static func read_tables(m) -> Dictionary:
	var t: Dictionary = DEFAULTS.duplicate(true)
	if not (m is Dictionary):
		return t
	var fin := func(d: Dictionary, k: String) -> bool:
		if not d.has(k):
			return false
		var x := Scoring.plus(d[k])
		return not is_nan(x) and not is_inf(x)
	for k in ["rate", "energyBase", "energyStep"]:
		if fin.call(m, k):
			t[k] = maxf(0.0, Scoring.plus(m[k]))
	if m.get("numbers") is Dictionary:
		for k in ["range", "hit", "ap"]:
			var x = m["numbers"].get(k)
			if x is Dictionary:
				if fin.call(x, "base"):
					t["numbers"][k]["base"] = Scoring.plus(x["base"])
				if fin.call(x, "per"):
					t["numbers"][k]["per"] = Scoring.plus(x["per"])
	for k in ["research", "caps", "require"]:
		if m.get(k) is Dictionary:
			t[k] = Rules.ints(m[k])
	return t


# ---------------------------------------------------------------- the chassis
func chassis_of(d) -> Variant:
	if not (d is Dictionary) or progress == null:
		return null
	var ch = progress.chassis.get(str(d.get("chassis")))
	return ch if ch is Dictionary else null


static func district_of(ch) -> Dictionary:
	var id := str(ch["district"] if ch is Dictionary and Rules.truthy(ch.get("district")) else "")
	for d in DISTRICTS:
		if d["id"] == id:
			return d
	return DISTRICTS[0]


## Every chassis in the export, by name.
func chassis_list() -> Array:
	var out: Array = progress.chassis.values() if progress != null else []
	out.sort_custom(func(a, b): return str(a.get("name", "")).naturalnocasecmp_to(str(b.get("name", ""))) < 0)
	return out


## The chassis's keywords you can use now: the free ones, and the blueprints you own.
func allowed_for(ch) -> Array:
	return (ch["allowed"] if ch is Dictionary and ch.get("allowed") is Array else []).filter(func(k): return not progress.is_blueprint(k) or progress.owned(k) >= 1)


## The keywords a text uses, each once, in order. Every Archetype counts as one: "Archetype".
static func keywords_in(text) -> Array:
	var out := []
	for p in Keywords.parse(text if text != null else ""):
		if p["type"] != "kw" or p.get("kw") == null:
			continue
		var nm: String = "Archetype" if Rules.truthy(p["kw"].get("archetype")) else str(p["kw"]["name"])
		if not out.has(nm):
			out.append(nm)
	return out


## Whether a design fits a chassis, and if not, why. (chassis.js's check)
## design: {abilities: [{text, role, power}]}.
static func chassis_check(ch: Dictionary, design: Dictionary) -> Dictionary:
	var abilities: Array = design["abilities"] if design.get("abilities") is Array else []
	var allowed := {}
	var forbidden := []
	var reasons := []
	for k in (ch["allowed"] if ch.get("allowed") is Array else []):
		allowed[str(k).to_lower()] = 1
	for a in abilities:
		for k in keywords_in(a.get("text")):
			if not allowed.has(k.to_lower()) and not forbidden.has(k):
				forbidden.append(k)
	var power := 0
	for a in abilities:
		power += Scoring.ability_power(a)
	var cap := Scoring.num(ch.get("powerCap"))
	var acap := Scoring.num(ch.get("abilityCap"))
	if power > cap:
		reasons.append("power %d is over this chassis's cap of %s" % [power, Scoring.text(cap)])
	if abilities.size() > acap:
		reasons.append("%d abilities, where this chassis holds %s" % [abilities.size(), Scoring.text(acap)])
	if not forbidden.is_empty():
		reasons.append("this chassis cannot use " + ", ".join(forbidden))
	# its subtypes decide which kinds of Actions it may have; Passives have none
	var subs: Array = (ch["subtypes"] if ch.get("subtypes") is Array else []).map(func(x): return str(x).to_lower())
	var wrong := []
	for i in abilities.size():
		var r := str(abilities[i]["role"] if Rules.truthy(abilities[i].get("role")) else "").to_lower()
		if r != "" and r != "passive" and not subs.is_empty() and not subs.has(r):
			wrong.append("ability %d is %s" % [i + 1, r.left(1).to_upper() + r.substr(1)])
	if not wrong.is_empty():
		reasons.append(", ".join(wrong) + ", which this chassis's subtypes (" + " and ".join((ch["subtypes"] if ch.get("subtypes") is Array else []).map(func(x): return str(x))) + ") do not allow")
	return {"ok": reasons.is_empty(), "power": power, "cap": cap, "abilities": abilities.size(), "abilityCap": acap, "forbidden": forbidden, "wrongKind": wrong, "reasons": reasons}


# ---------------------------------------------------------------- designs
func starter() -> Dictionary:
	return STARTER.duplicate(true)


## Every design, the starter included: id -> design.
func all() -> Dictionary:
	var m := designs.duplicate()
	if not m.has(STARTER["id"]):
		m[STARTER["id"]] = starter()
	return m


## The starter, or a design out on a deployment, is not changed here.
func locked(id) -> bool:
	return str(id) == STARTER["id"] or (is_out.is_valid() and is_out.call(str(id)))


## Your designs, by name (the starter among them).
func list() -> Array:
	var out: Array = all().values().filter(func(d): return not Rules.truthy(d.get("prebuilt")))
	out.sort_custom(func(a, b):
		var c := str(a.get("name", "")).naturalnocasecmp_to(str(b.get("name", "")))
		return c < 0 if c != 0 else str(a.get("id", "")) < str(b.get("id", "")))
	return out


func get_design(id) -> Variant:
	var d = all().get(str(id))
	if d == null:
		for p in prebuilt_designs:
			if p["id"] == str(id):
				d = p
	return d.duplicate(true) if d is Dictionary else null


## The export's pre-built Troops, as designs, in the order the Exchange offers them.
func set_prebuilts(export_cards: Array) -> void:
	prebuilt_designs = []
	for c in export_cards:
		if c is Dictionary and c.get("_src") == "prebuilt":
			var d := from_card(c)
			d["id"] = str(c["_design"] if Rules.truthy(c.get("_design")) else c.get("design", ""))
			d["prebuilt"] = true
			d["order"] = prebuilt_designs.size()
			prebuilt_designs.append(d)


func prebuilts() -> Array:
	return prebuilt_designs


func by_name(name: String) -> Variant:
	for d in list():
		if str(d.get("name", "")) == name:
			return d
	return null


static func _new_id() -> String:
	return "ds_%s%04x" % [String.num_int64(int(Time.get_unix_time_from_system() * 1000.0), 36), randi() % 65536]


## Keeps a design (a new one is given its id). Returns its id, or "" for one
## that is locked.
func put(d: Dictionary) -> String:
	if Rules.truthy(d.get("id")) and locked(d["id"]):
		return ""
	if not Rules.truthy(d.get("id")):
		d["id"] = _new_id()
		while designs.has(d["id"]):
			d["id"] = _new_id()
	d["saved"] = Time.get_datetime_string_from_system(true) + "Z"
	designs[str(d["id"])] = d.duplicate(true)
	return str(d["id"])


# ---------------------------------------------------------------- (0.37) Mk II and Mk III
## A design made tougher (Health, Armor Class, then Movement), paid in Troop
## parts at the dock. The starter can be raised too; the cost of its copies
## doesn't change.
const MK := [{"hp": 0, "ac": 0, "move": 0}, {"hp": 3, "ac": 1, "move": 0}, {"hp": 6, "ac": 2, "move": 1}]
const MK_COST := [null, [8, 4, 0, 0, 0, 0], [0, 6, 4, 0, 0, 0]]
const MK_NAME := ["Mk I", "Mk II", "Mk III"]


static func mk_of(d) -> int:
	var v = Rules.num(d.get("mk"), 1) if d is Dictionary else 1
	return clampi(int(v) if Rules.truthy(v) else 1, 1, 3)


## What raising it a Mark costs, in Troop parts by rarity; null at Mk III.
static func mk_cost(d) -> Variant:
	var m := mk_of(d)
	return null if m >= 3 else (MK_COST[m] as Array).duplicate()


## Raises a design a Mark, paid out of this stockpile (changed in place).
func upgrade(id, stock: Dictionary, team_out := false) -> Dictionary:
	var d = designs.get(str(id))
	if d == null and str(id) == STARTER["id"]:
		d = starter()
	if not (d is Dictionary) or Rules.truthy(d.get("prebuilt")):
		return {"ok": false, "why": "No such design"}
	if team_out:
		return {"ok": false, "why": "The dock is closed while a Strike Team is out"}
	var c = mk_cost(d)
	if c == null:
		return {"ok": false, "why": "Already Mk III"}
	var st := Loot.norm(stock)
	for r in 6:
		if st["parts"]["troop"][r] < int(c[r]):
			return {"ok": false, "why": "Needs %s Troop parts" % cost_text(c)}
	for r in 6:
		st["parts"]["troop"][r] -= int(c[r])
	stock.merge(st, true)
	d["mk"] = mk_of(d) + 1
	designs[str(d["id"])] = d
	return {"ok": true, "mk": d["mk"], "cost": c}


func remove(id) -> bool:
	if locked(id):
		return false
	designs.erase(str(id))
	return true


## The most a chassis lets an attack's range or AP be; a to-hit can be as
## high as 20.
static func max_of(ch, k: String) -> float:
	if k == "hit":
		return 20.0
	var key: String = {"range": "maxRange", "ap": "maxAP"}[k]
	var d: float = {"range": 6.0, "ap": 6.0}[k]
	return maxf(0.0, Scoring.num(ch.get(key) if ch is Dictionary else null, d))


## Handbook 16.0: a lower to-hit is better, so a chassis sets the best (lowest)
## to-hit its attacks may have, and they choose from it up to 20. A chassis
## from before kept "maxHit", the most an attack could have: it reads as 12
## minus that, so the old ranking holds (8 becomes 4).
static func best_hit(ch) -> float:
	var given := func(v): return v != null and not (v is String and v == "")
	if ch is Dictionary and given.call(ch.get("bestHit")):
		return minf(20.0, maxf(1.0, Scoring.num(ch["bestHit"], 4.0)))
	if ch is Dictionary and given.call(ch.get("maxHit")):
		return minf(20.0, maxf(1.0, 12.0 - Scoring.num(ch["maxHit"], 8.0)))
	return 4.0


## The least a chassis lets an attack's number be: the best to-hit, else 0.
static func least_of(ch, k: String) -> float:
	return best_hit(ch) if k == "hit" else 0.0


## An ability to start from: an attack's numbers at the baseline, within the chassis's maximums.
func blank_ability(ch, kind: String) -> Dictionary:
	if kind == "passive":
		return {"name": "", "kind": "passive", "role": "", "text": ""}
	# (what the chassis says, even where it says nothing: a chassis with no subtype gives no role)
	var role = "Melee"
	if ch is Dictionary and ch.get("subtypes") is Array:
		role = ch["subtypes"][0] if not ch["subtypes"].is_empty() else ""
	var t: Dictionary = tables["numbers"]
	var least := func(a: float, b: float): return Rules.ints(minf(a, b))
	return {"name": "", "kind": "action", "role": role, "energy": 1, "range": least.call(float(t["range"]["base"]), max_of(ch, "range")),
		"hit": least.call(max_of(ch, "hit"), maxf(float(t["hit"]["base"]), best_hit(ch))), "ap": least.call(float(t["ap"]["base"]), max_of(ch, "ap")), "text": ""}


func blank(chassis_id: String) -> Dictionary:
	return {"id": null, "name": "New design", "chassis": chassis_id, "abilities": [blank_ability(progress.chassis.get(chassis_id), "action")], "notes": ""}


## Which of range, to-hit and AP an Action uses.
static func fields_for(ab) -> Array:
	if not (ab is Dictionary) or ab.get("kind") == "passive":
		return []
	var r := str(ab["role"] if Rules.truthy(ab.get("role")) else "").to_lower()
	if r == "melee":
		return ["ap"]
	if r == "ranged" or r == "cyber":
		return ["range", "hit", "ap"]
	return []


static func is_attack(ab) -> bool:
	if not (ab is Dictionary) or ab.get("kind") == "passive":
		return false
	var r := str(ab["role"] if Rules.truthy(ab.get("role")) else "").to_lower()
	return r == "melee" or r == "ranged" or r == "cyber"


## What the keyword builder is opened with, on ability i of a design: a new
## sentence (j = -1) or sentence j to change. Its keywords are those the
## chassis allows that you own, and a number stops at what your blueprint's
## level allows. cards: the Troops a Deploy can name.
func builder_options(d: Dictionary, i: int, j: int, cards: Array) -> Dictionary:
	var ch = chassis_of(d)
	var a: Dictionary = d["abilities"][i]
	var sents := Keywords.sentences(str(a.get("text", "")))
	var passive: bool = a.get("kind") == "passive"
	var allowed := allowed_for(ch)
	var most := {}
	for k in allowed:
		var b = progress.blueprint_of(k)
		if b != null and b["caps"] != null:
			var lv := progress.owned(k)
			if lv >= 1 and lv <= 3:
				most[str(k)] = b["caps"][lv - 1]
	var others := " ".join(sents.filter(func(s): return j < 0 or s != sents[j]))
	var o := {"kind": "passive" if passive else "action", "cardType": "troop", "role": "" if passive else str(a.get("role", "")).to_lower(),
		"allowed": allowed, "others": others, "cards": cards, "most": most}
	if j >= 0 and j < sents.size():
		o["sentence"] = sents[j]
	return o


# ---------------------------------------------------------------- power
func ability_power(ab: Dictionary) -> int:
	var att := is_attack(ab)
	var text: String = str(ab["text"]) if Rules.truthy(ab.get("text")) else ""
	var d = Scoring.keyword_detail(text, att)
	var base: float = d["base"] if d != null else (4.0 if att else (4.0 if text.strip_edges() != "" else 0.0))
	var mult: float = d["mult"] if d != null else 1.0
	var extra := 0.0
	var hf := 1.0
	for k in fields_for(ab):
		var n: Dictionary = tables["numbers"][k]
		if k == "hit":
			hf = hit_factor(Scoring.num(ab.get(k), float(n["base"])), float(n["base"]))
			continue
		extra += (Scoring.num(ab.get(k), float(n["base"])) - float(n["base"])) * float(n["per"])
	var ef := 1.0
	if ab.get("kind") != "passive":
		ef = 1.0 + float(tables["energyStep"]) * maxf(0.0, float(tables["energyBase"]) - Scoring.num(ab.get("energy"), float(tables["energyBase"])))
	return int(maxf(0.0, Rules.js_round(maxf(0.0, base + extra) * mult * ef * hf)))


## To-hit is a d20 threshold (rules.gd: the roll must reach it), so the lower
## it is the more often everything the attack carries lands. An aimed attack's
## worth scales with its chance to hit, P = (21 - hit) / 20, measured against the
## priced-at to-hit: 1.0 at base 6, 1.33 at 1 (always hits), 0 at 21 (never).
static func hit_factor(hit: float, base: float) -> float:
	var h := clampf(hit, 1.0, 21.0)
	var b := clampf(base, 1.0, 20.0)
	return (21.0 - h) / (21.0 - b)


func power(d: Dictionary) -> int:
	var total := 0
	for a in (d["abilities"] if d.get("abilities") is Array else []):
		total += ability_power(a)
	return total


# ---------------------------------------------------------------- the fit check
## Whether a design can be built and sent out: its chassis's limits, its
## numbers, and the blueprints and chassis you own.
## {ok, reasons, power, cap, abilities, abilityCap, missing}.
func check(d: Dictionary) -> Dictionary:
	var ch = chassis_of(d)
	if ch == null:
		return {"ok": false, "reasons": ["its chassis is missing"], "power": 0, "cap": 0, "abilities": 0, "abilityCap": 0, "missing": []}
	var abilities: Array = d["abilities"] if d.get("abilities") is Array else []
	var abs_in := abilities.map(func(a): return {"text": a["text"] if Rules.truthy(a.get("text")) else "",
		"role": "" if a.get("kind") == "passive" else str(a["role"] if Rules.truthy(a.get("role")) else "").to_lower(), "power": ability_power(a)})
	var c := chassis_check(ch, {"abilities": abs_in})
	var reasons: Array = c["reasons"].duplicate()
	var nrg := Scoring.num(ch.get("stats", {}).get("nrg") if ch.get("stats") is Dictionary else null, 0.0)
	for i in abilities.size():
		var a: Dictionary = abilities[i]
		var label := "ability %d%s" % [i + 1, (" (%s)" % str(a["name"])) if Rules.truthy(a.get("name")) else ""]
		if str(a["text"] if Rules.truthy(a.get("text")) else "").strip_edges() == "":
			reasons.append(label + " has no text")
		if a.get("kind") != "passive" and Scoring.num(a.get("energy"), 0.0) > nrg:
			reasons.append("%s costs %s Energy, more than this chassis's %s" % [label, Scoring.text(a.get("energy")), Scoring.text(nrg)])
		for k in fields_for(a):
			var mx := max_of(ch, k)
			if k == "hit":
				var h := Scoring.num(a.get("hit"), float(tables["numbers"]["hit"]["base"]))
				var lo := best_hit(ch)
				if h < lo:
					reasons.append("%s's to-hit of %s is better than this chassis's best of %s" % [label, Scoring.text(h), Scoring.text(lo)])
				elif h > mx:
					reasons.append("%s's to-hit of %s is over %s, so it could never hit" % [label, Scoring.text(h), Scoring.text(mx)])
				continue
			if Scoring.num(a.get(k), 0.0) > mx:
				reasons.append("%s's %s of %s is over this chassis's %s" % [label, {"range": "range", "hit": "to-hit", "ap": "AP"}[k], Scoring.text(a.get(k)), Scoring.text(mx)])
	# a pre-built Troop is made to show what you can't make yet: only its fit counts
	var miss: Array = progress.missing(abilities).filter(func(m): return not Rules.truthy(d.get("prebuilt")) or m["over"])
	for m in miss:
		if m["over"]:
			reasons.append("%s is used higher than any blueprint level allows (the most is %s)" % [m["name"], Scoring.text(m["max"])])
		else:
			reasons.append("%s needs blueprint level %d%s" % [m["name"], m["level"], (" — you have level %d" % m["have"]) if m["have"] > 0 else " — not found yet"])
	if not Rules.truthy(d.get("prebuilt")) and not progress.has_chassis(ch.get("id")):
		reasons.append("this chassis has not been found yet")
	return {"ok": reasons.is_empty(), "reasons": reasons, "power": c["power"], "cap": c["cap"], "abilities": c["abilities"], "abilityCap": c["abilityCap"], "missing": miss}


# ---------------------------------------------------------------- what a copy costs
## In Troop parts by rarity: {parts: [6], power, lines: [{label, parts}]}.
func cost(d: Dictionary) -> Dictionary:
	var ch = chassis_of(d)
	var parts := [0, 0, 0, 0, 0, 0]
	var p := power(d)
	var chassis_cost := Scoring.num(ch["cost"].get("troop") if ch is Dictionary and ch.get("cost") is Dictionary else null, 0.0)
	parts[0] = int(ceil(chassis_cost + float(tables["rate"]) * p))
	var lines := [{"label": "Chassis %s + %s × power %d" % [Scoring.text(chassis_cost), Scoring.text(tables["rate"]), p], "parts": [parts[0], 0, 0, 0, 0, 0]}]
	var require: Dictionary = tables["require"] if tables.get("require") is Dictionary else {}
	for n in progress.needs(d["abilities"] if d.get("abilities") is Array else []):
		var by_level = require.get(n["name"])
		var req = _level_row(by_level, n["level"])
		if not (req is Dictionary):
			continue
		var row := [0, 0, 0, 0, 0, 0]
		var any := false
		for r in req:
			var cv = Rules.num(req[r], 0)
			var c: int = maxi(0, int(cv) if Rules.truthy(cv) else 0)
			var ri := int(World.number(r))
			if c > 0 and ri >= 0 and ri < 6:
				row[ri] += c
				parts[ri] += c
				any = true
		if any:
			lines.append({"label": str(n["name"]) + ((" L%d" % n["level"]) if progress.blueprint_of(n["name"])["levels"] > 1 else ""), "parts": row})
	return {"parts": parts, "power": p, "lines": lines}


## A row of a table keyed by level, whether the key was read as a number or as text.
static func _level_row(by_level, level: int) -> Variant:
	if not (by_level is Dictionary):
		return null
	for k in by_level:
		if str(k) == str(level):
			return by_level[k]
	return null


## How many copies a stockpile could pay for.
func affordable(d: Dictionary, stock: Dictionary) -> int:
	var c := cost(d)
	var have: Array = Loot.norm(stock)["parts"]["troop"]
	var best := -1
	for r in 6:
		var n: int = c["parts"][r]
		if n > 0:
			var can := int(floor(float(have[r]) / float(n)))
			best = can if best < 0 else mini(best, can)
	return maxi(0, best)


## A bag of what some copies cost, as loot text reads it: "6 Common".
static func cost_text(parts: Array) -> String:
	var bits := []
	for r in 6:
		if int(parts[r]) > 0:
			bits.append("%d %s" % [int(parts[r]), Loot.RARITIES[r]["label"]])
	return " · ".join(bits) if not bits.is_empty() else "nothing"


# ---------------------------------------------------------------- a design as a Troop card
func to_card(d: Dictionary) -> Dictionary:
	var ch = chassis_of(d)
	var c: Dictionary = ch if ch is Dictionary else {}
	var st: Dictionary = c["stats"] if c.get("stats") is Dictionary else {}
	var dist := str(c["district"] if Rules.truthy(c.get("district")) else "")
	var look = skins.pics_of_design(d) if skins != null else null
	var ae: Dictionary = c["aether"] if c.get("aether") is Dictionary else {}
	var s := func(v, dflt: float) -> String: return Scoring.text(Rules.ints(Scoring.num(v, dflt)))
	var entries := []
	for a in (d["abilities"] if d.get("abilities") is Array else []):
		var passive: bool = a.get("kind") == "passive"
		var e := {"name": a["name"] if Rules.truthy(a.get("name")) else ("Passive" if passive else "Action"), "kind": "Passive" if passive else "Active",
			"text": a["text"] if Rules.truthy(a.get("text")) else ""}
		if not passive:
			e["role"] = str(a["role"] if Rules.truthy(a.get("role")) else "").to_lower()
			e["energyCost"] = s.call(a.get("energy"), 0.0)
		if is_attack(a):
			e["damage"] = s.call(st.get("dmg"), 2.0)
			e["armorPenetration"] = s.call(a.get("ap"), 0.0)
			if e["role"] != "melee":
				e["attackRange"] = s.call(a.get("range"), 1.0)
				e["toHit"] = s.call(a.get("hit"), 0.0)
				# (0.12) what it fires, for the screen to draw
				if PROJECTILES.has(a.get("projectile")):
					e["projectile"] = a["projectile"]
		entries.append(e)
	var card := {"id": "WS-" + str(d["id"] if Rules.truthy(d.get("id")) else "").substr(3).to_upper(), "cardType": "troop",
		"name": d["name"] if Rules.truthy(d.get("name")) else "Untitled design",
		"affinities": [{"district": dist, "level": 0}] if dist != "" else [], "archetypes": [], "rarity": null, "level": 1,
		"stats": {"hp": _plus(s.call(st.get("hp"), 12.0), MK[mk_of(d) - 1]["hp"]), "ac": _plus(s.call(st.get("ac"), 10.0), MK[mk_of(d) - 1]["ac"]), "int": s.call(st.get("int"), 10.0), "nrg": s.call(st.get("nrg"), 3.0), "move": _plus(s.call(st.get("move"), 4.0), MK[mk_of(d) - 1]["move"]), "uslot": "1"},
		"aetherCost": {"generic": Rules.ints(Scoring.num(ae.get("generic"), 1.0)), "affinity": Rules.ints(Scoring.num(ae.get("affinity"), 0.0)), "affinity2": 0},
		"combatRoles": (c["subtypes"] if c.get("subtypes") is Array else []).map(func(x): return str(x).to_lower()),
		"entries": entries, "design": d.get("id"), "chassis": c["id"] if Rules.truthy(c.get("id")) else d.get("chassis"),
		"chassisName": c["name"] if Rules.truthy(c.get("name")) else ""}
	if mk_of(d) > 1:
		card["mk"] = mk_of(d)
	var art = look["art"] if look is Dictionary and Rules.truthy(look.get("art")) else d.get("pixelArt")
	var token = look["token"] if look is Dictionary and Rules.truthy(look.get("token")) else d.get("pixelToken")
	if Rules.truthy(art):
		card["pixelArt"] = art
	if Rules.truthy(token):
		card["pixelToken"] = token
	return card


## A stat as text, raised by a Mark's bonus (as JavaScript adds a number to one).
static func _plus(t: String, n: int) -> String:
	return t if n == 0 else Scoring.text(Scoring.num(t, 0.0) + n)


## Your designs as Troop cards, each marked as yours.
func cards() -> Array:
	var out := []
	for d in list():
		var c := to_card(d)
		c["_src"] = "workshop"
		c["_design"] = d["id"]
		if Rules.truthy(d.get("starter")):
			c["starter"] = true
		out.append(c)
	return out


# ---------------------------------------------------------------- designs out of the export
## A design card from the Companion's Workshop, read back into a design of
## yours: the same chassis, the same abilities. (What to_card took apart.)
static func from_card(card: Dictionary) -> Dictionary:
	var abilities := []
	for e in (card["entries"] if card.get("entries") is Array else []):
		if not (e is Dictionary):
			continue
		var passive := str(e.get("kind", "")).to_lower() == "passive"
		if passive:
			abilities.append({"name": "" if e.get("name") == "Passive" else str(e.get("name", "")), "kind": "passive", "role": "", "text": str(e.get("text", ""))})
			continue
		var role := str(e.get("role", ""))
		var a := {"name": "" if e.get("name") == "Action" else str(e.get("name", "")), "kind": "action", "role": role.left(1).to_upper() + role.substr(1),
			"energy": int(Rules.num(e.get("energyCost"), 0)), "text": str(e.get("text", ""))}
		if e.has("attackRange"):
			a["range"] = int(Rules.num(e["attackRange"], 0))
		if e.has("toHit"):
			a["hit"] = int(Rules.num(e["toHit"], 0))
		if e.has("armorPenetration"):
			a["ap"] = int(Rules.num(e["armorPenetration"], 0))
		if PROJECTILES.has(e.get("projectile")):
			a["projectile"] = str(e["projectile"])
		abilities.append(a)
	return {"id": null, "name": str(card.get("name", "Untitled design")), "chassis": str(card.get("chassis", "")), "abilities": abilities, "notes": "", "from": str(card.get("design", ""))}
