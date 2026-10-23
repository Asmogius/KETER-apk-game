## The keyword builder (Handbook 15.6), without its screen. (The Companion's
## builder.js.)
##
## It builds one effect, one sentence, at a time, by walking through the
## grammar: when it happens, who it is about, who it affects, what it does,
## any Modifiers, how long it lasts. Every step offers only what is legal for
## this kind of ability, and on a chassis only what the chassis allows;
## optional steps can be skipped. It ends on a review of the whole sentence
## where any part can be changed, then Insert.
##
## This class is the builder's mind: where it stands, what it offers there and
## what each choice does. builder_sheet.gd draws it and passes the taps on.
##
## Proved to offer, at every step of thousands of walks, exactly what
## builder.js offers, and to build the same sentence (tests/workshop_diff.gd).
class_name Builder
extends RefCounted

# Handbook 16.0: the statuses that lock a Unit down, 2 turns at most and never
# always-on (rules.gd)
const LOCKS := ["Stunned", "Rooted", "Pinned", "Marked"]
const LOCK_MAX_TURNS := 2
const DISTRICTS := [["1", "Threshold Dynamics"], ["2", "Halcyon Cognition"], ["3", "Vantage Robotics"],
	["4", "Lazarus Computing"], ["5", "Verdant Biogenics"], ["6", "Meridian Entropics"]]
const PLURAL := ["all enemies within", "all allies within", "all units within", "all enemies", "all allies"]
const TAKES := ["damage", "Push"]
const STEPS := [
	{"id": "cond", "title": "When does it happen?", "optional": false},
	{"id": "csubj", "title": "Who is it about?", "optional": false},
	{"id": "cnarrow", "title": "Narrow them down?", "optional": true},
	{"id": "cevent", "title": "What happens, or what must be true?", "optional": false},
	{"id": "check", "title": "Check something as well?", "optional": true},
	{"id": "ksubj", "title": "Who is the check about?", "optional": false},
	{"id": "knarrow", "title": "Narrow them down?", "optional": true},
	{"id": "kstate", "title": "What must be true?", "optional": false},
	{"id": "target", "title": "Who does it affect?", "optional": true},
	{"id": "tnarrow", "title": "Narrow them down?", "optional": true},
	{"id": "effect", "title": "What does it do?", "optional": false},
	{"id": "mods", "title": "Any Modifiers?", "optional": true},
	{"id": "dur", "title": "How long does it last?", "optional": true},
	{"id": "review", "title": "Review the effect", "optional": false}]
const _QUANT := ["an ally", "an enemy", "any Unit"]
const _NARROWED := ["target enemy", "target ally", "all enemies within", "all allies within", "all units within", "all enemies", "all allies"]

## What it was opened for: {kind: "action"|"passive", cardType, role, allowed
## (a chassis's keywords, or null for all), sentence (one to change), others
## (the rest of the ability's text, for its power), cards (what a Deploy can
## name), variable (the card has a variable cost), most (keyword -> the highest
## number you may give it: the game's own, for blueprint levels)}.
var opt := {}
## Where it stands: {when, check, target, effects, mods, dur, adjacent,
## visited, at, param, editing, ownWords, problems}.
var st := {}
var open := false
## What Insert gave (the sentence), once it has; "" until then.
var result := ""
var cancelled := false


static func step_index(id: String) -> int:
	for i in STEPS.size():
		if STEPS[i]["id"] == id:
			return i
	return -1


static func blank() -> Dictionary:
	return {"when": null, "check": null, "target": null, "effects": [], "mods": [], "dur": null, "adjacent": false, "visited": {},
		"at": 0, "param": null, "editing": false, "ownWords": false, "problems": []}


static func kw(name) -> Variant:
	return Keywords.by_name(name)


func allowed(name) -> bool:
	if not (opt.get("allowed") is Array):
		return true
	var k = kw(name)
	var nm := "Archetype" if (k != null and Rules.truthy(k.get("archetype"))) else str(name)
	return opt["allowed"].any(func(a): return str(a).to_lower() == nm.to_lower())


static func tok(p) -> String:
	if p == null:
		return ""
	var n = p.get("n")
	return "[[" + str(p["name"]) + ((" " + str(n)) if (n != null and not (n is String and n == "")) else "") + "]]"


# ---------------------------------------------------------------- the sentence it makes
static func clause_text(c) -> String:
	if c == null:
		return ""
	var parts := ["[[" + str(c["conn"]) + "]]"]
	if c.get("subject") != null:
		parts.append(tok(c["subject"]))
	for q in (c["narrow"] if c.get("narrow") is Array else []):
		parts.append(tok(q))
	if c.get("event") != null:
		parts.append(tok(c["event"]))
	return " ".join(parts)


static func build(s: Dictionary) -> String:
	var head := []
	if s.get("when") != null:
		head.append(clause_text(s["when"]))
	if s.get("check") != null:
		head.append(clause_text(s["check"]))
	var lead := (", ".join(head) + ", ") if not head.is_empty() else ""
	var t = s.get("target")
	var many: bool = t != null and PLURAL.has(t["name"])
	var who := ""
	if t != null:
		var bits0 := [tok(t)]
		for q in (t["narrow"] if t.get("narrow") is Array else []):
			bits0.append(tok(q))
		who = " ".join(bits0)
	var take := []
	var gain := []
	var cover = null
	var sac = null
	var exe = null
	var deploy := []
	var bare := []
	var barricade = null
	for e in s["effects"]:
		if e["name"] == "Sacrifice":
			sac = e
		elif e["name"] == "Execute":
			exe = e
		elif e["name"] == "Deploy":
			deploy.append(e)
		# Revision 16.3: Draw and gain Aether are what you do, not something a Unit gains; a Barricade goes on a tile
		elif e["name"] == "Draw" or e["name"] == "gain Aether":
			bare.append(e)
		elif e["name"] == "Barricade":
			barricade = e
		elif e["name"] == "Half Cover" or e["name"] == "Full Cover":
			cover = e
		elif TAKES.has(e["name"]):
			take.append(e)
		else:
			gain.append(e)
	var bits := []
	if not take.is_empty():
		bits.append(("take " if many else "takes ") + " and ".join(take.map(tok)))
	if not gain.is_empty():
		bits.append(("gain " if many else "gains ") + " and ".join(gain.map(tok)))
	if cover != null:
		bits.append(("count" if many else "counts") + " as behind " + tok(cover))
	var main := ""
	if sac != null:
		# what else it does happens first, then the Unit is spent
		main = (who if who != "" else "[[this Unit]]") + " " + ((" and ".join(bits) + " and ") if not bits.is_empty() else "") + "is spent as a " + tok(sac)
	elif exe != null:
		# likewise, what else it does happens first, then the Enemy faces the Execute
		main = ((who + " ") if who != "" else "") + ((" and ".join(bits) + " and ") if not bits.is_empty() else "") + ("face an " if many else "faces an ") + tok(exe)
	elif not bits.is_empty():
		main = ((who + " ") if who != "" else "") + " and ".join(bits)
	if not deploy.is_empty():
		main = ((main + " and ") if main != "" else "") + " and ".join(deploy.map(tok)) + (" [[adjacent]]" if Rules.truthy(s.get("adjacent")) else "")
	if barricade != null:
		main = ((main + " and ") if main != "" else "") + tok(barricade) + " on " + (who if who != "" else "[[target tile]]")
	if not bare.is_empty():
		main = ((main + ". ") if main != "" else "") + ". ".join(bare.map(tok))
	var mods := " and ".join(s["mods"].map(tok))
	# a Target with only Modifiers is the attack itself: "target enemy is hit with AoE 1"
	if mods != "":
		if main != "":
			main = main + " with " + mods
		elif who != "":
			main = who + (" are" if many else " is") + " hit with " + mods
		else:
			main = mods
	if s.get("dur") != null:
		if s["dur"]["name"] == "turns":
			main += " for " + tok(s["dur"])
		else:
			main += " " + tok(s["dur"])
	var out := Keywords._re("\\s+").sub(lead + main, " ", true).strip_edges()
	if main == "":
		out = Keywords._re(",\\s*$").sub(out, "")
	return (out + ".") if out != "" else ""


static func _p(p) -> Variant:
	if p == null:
		return null
	return {"name": p["kw"]["name"] if p.get("kw") != null else p.get("name"), "n": p.get("n")}


static func _clause(c) -> Variant:
	if c == null:
		return null
	return {"conn": c["connector"], "subject": _p(c.get("subject")), "narrow": (c["narrow"] if c.get("narrow") is Array else []).map(_p), "event": _p(c.get("event"))}


## An existing sentence, read back into the steps.
static func from_sentence(sent: String) -> Dictionary:
	var s := blank()
	var an := Keywords.analyse(sent)
	s["when"] = _clause(an["when"])
	s["check"] = _clause(an["check"])
	for t in an["targets"]:
		if t["part"]["kw"]["name"] == "adjacent":
			s["adjacent"] = true
			continue
		if s["target"] == null:
			s["target"] = {"name": t["part"]["kw"]["name"], "n": t["part"].get("n"), "narrow": t["narrow"].map(_p)}
	s["effects"] = an["effects"].map(_p) + an["covers"].map(_p)
	s["mods"] = an["mods"].map(_p)
	s["dur"] = _p(an["durations"][0]) if not an["durations"].is_empty() else null
	# anything written by hand in the sentence is lost if it is rebuilt
	s["ownWords"] = Keywords.render(build(s)) != Keywords.render(sent)
	for step in STEPS:
		s["visited"][step["id"]] = 1
	return s


# ---------------------------------------------------------------- what is legal
func is_passive() -> bool:
	return opt.get("kind") == "passive"


func is_equip() -> bool:
	return Keywords._test("(?i)equipment", str(opt["cardType"] if Rules.truthy(opt.get("cardType")) else ""))


func always() -> bool:
	return is_passive() and st["when"] == null


func _add(out: Array, name: String, label = null, desc = null) -> void:
	var k = kw(name)
	if k != null and allowed(name):
		out.append({"name": name, "label": label if Rules.truthy(label) else name, "desc": desc if Rules.truthy(desc) else k.get("desc")})


func subjects_for(conn, is_check: bool) -> Array:
	var out := []
	if not is_passive():
		_add(out, "the target", "the target", "The Unit this Action is used on.")
		_add(out, "this Unit")
	else:
		if is_equip():
			_add(out, "attached Unit")
		else:
			_add(out, "this Unit", "this Unit", "The Unit whose card this is.")
		if is_check and st["when"] != null and st["when"].get("subject") != null:
			_add(out, "that Unit", "that Unit", "Whoever the “when” is about.")
	_add(out, "an ally")
	_add(out, "an enemy")
	_add(out, "any Unit")
	if conn == "when" and allowed("the round begins"):
		out.append({"name": "", "special": "round", "label": "the round", "desc": "Something about the round itself, not a Unit."})
	return out


func events_for(c: Dictionary, is_check: bool) -> Array:
	var sn: String = str(c["subject"]["name"]) if c.get("subject") != null else ""
	var own := sn == "this Unit" or sn == "attached Unit"
	var out := []
	for k in Keywords.KEYWORDS:
		if k.get("cat") != "condition" or not (k.get("role") == "event" or k.get("role") == "state"):
			continue
		if not allowed(k["name"]) or Rules.truthy(k.get("noSubject")):
			continue
		if own and Rules.truthy(k.get("noSelf")):
			continue
		var keep := false
		if c["conn"] == "when":
			keep = k["role"] == "event"
		elif c["conn"] == "while":
			keep = k["role"] == "state"
		elif k["role"] == "state":
			keep = true          # if: a state; in an Action, also what the Action itself did
		else:
			keep = not is_passive() and not is_check and Rules.truthy(k.get("actionIf")) and (sn == "this Unit" or sn == "the target")
		if not keep:
			continue
		if k["role"] == "event" and not is_passive():
			# what an Action can ask about itself
			if sn == "the target":
				if not (k["name"] == "takes damage" or k["name"] == "is Incapacitated"):
					continue
			elif not (k["name"] == "deals damage" or k["name"] == "kills an enemy"):
				continue
		out.append(k)
	return out


func targets_for() -> Array:
	var out := []
	if not is_passive():
		for n in ["target enemy", "target ally", "target tile", "this Unit", "all enemies within", "all allies within", "all units within",
				"all enemies", "all allies"]:     # Revision 16.3: a whole side, wherever it stands
			_add(out, n)
	else:
		if is_equip():
			_add(out, "attached Unit")
		else:
			_add(out, "this Unit", "this Unit", "The Unit whose card this is.")
		var about = null
		if st["when"] != null and st["when"].get("subject") != null:
			about = st["when"]["subject"]
		elif st["check"] != null and st["check"].get("subject") != null:
			about = st["check"]["subject"]
		if about != null and about["name"] != "this Unit" and about["name"] != "attached Unit":
			_add(out, "that Unit", "that Unit", "Whoever the Condition is about.")
		if st["when"] != null:
			_add(out, "target enemy", "target enemy", "The Enemy involved in the event — the attacker, or the one hit.")
			_add(out, "target ally", "target ally", "The friendly Unit involved in the event.")
		_add(out, "all enemies within", "all enemies within", "Every Enemy within that many tiles of this Unit.")
		_add(out, "all allies within", "all allies within", "Every friendly Unit within that many tiles of this Unit.")
		_add(out, "all units within", "all units within", "Everything within that many tiles of this Unit.")
		_add(out, "all enemies")
		_add(out, "all allies")
	return out


func narrow_for() -> Array:
	var out := []
	for n in ["Melee", "Ranged", "Support", "Cyber"]:
		if allowed(n):
			out.append({"name": n, "group": "Subtype"})
	# Revision 16.3: Troop or Hero
	for n in ["Troop", "Hero"]:
		if kw(n) != null and allowed(n):
			out.append({"name": n, "group": "Troop or Hero"})
	if allowed("District"):
		out.append({"name": "District", "group": "District", "param": "district"})
	if allowed("Archetype") or not (opt.get("allowed") is Array):
		for a in Keywords.archetypes():
			if allowed(a):
				out.append({"name": a, "group": "Archetype"})
	return out


func effects_for() -> Array:
	var out := []
	var tn: String = str(st["target"]["name"]) if st.get("target") != null else ""
	for k in Keywords.KEYWORDS:
		if not allowed(k["name"]):
			continue
		# an always-on Passive cannot Stun, Root, Pin or Mark (Keywords.problems says why)
		if is_lock(k["name"]) and always():
			continue
		# Sacrifice removes a friendly Unit: not offered where the Target is (or may be) an Enemy
		if k["name"] == "Sacrifice" and ["target enemy", "all enemies within", "all units within", "target tile", "all enemies"].has(tn):
			continue
		# Revision 16.3: a Barricade goes on a tile, and only there
		if k["name"] == "Barricade" and tn != "target tile":
			continue
		# Execute removes an Enemy: offered only where the Target is one
		if k["name"] == "Execute" and not ["target enemy", "all enemies within", "all enemies"].has(tn):
			continue
		if k["cat"] == "effect":
			out.append({"name": k["name"], "group": "Effect"})
		elif k["cat"] == "status":
			out.append({"name": k["name"], "group": "Status"})
		elif k["cat"] == "stats":
			out.append({"name": k["name"], "group": "Stats"})
		elif k["name"] == "Half Cover" or k["name"] == "Full Cover":
			out.append({"name": k["name"], "group": "Cover"})
	return out


func mods_for() -> Array:
	var out := []
	for k in Keywords.KEYWORDS:
		if k["cat"] != "modifier" or not allowed(k["name"]):
			continue
		# Overclock carries no rules yet, so it is not offered (the Forge flags it where it is used)
		if k["name"] == "Overclock":
			continue
		# Revision 16.1: Lunge and Charge are made with a blow, so only a Melee Action has them
		if (k["name"] == "Lunge" or k["name"] == "Charge") and Rules.truthy(opt.get("role")) and str(opt["role"]).to_lower() != "melee":
			continue
		# Revision 16.3: Line and Cone are shapes an attack makes
		if (k["name"] == "Line" or k["name"] == "Cone") and Rules.truthy(opt.get("role")) and str(opt["role"]).to_lower() == "support":
			continue
		if (k["name"] == "Aura") if is_passive() else (k["name"] != "Aura"):
			out.append({"name": k["name"], "group": "Modifier"})
	return out


static func is_lock(name) -> bool:
	return LOCKS.has(name)


func has_lock() -> bool:
	for e in st["effects"]:
		if is_lock(e["name"]):
			return true
	return false


func needs_duration() -> bool:
	for e in st["effects"]:
		var k = kw(e["name"])
		if k != null and (k["cat"] == "stats" or k["cat"] == "status" or k["name"] == "Half Cover" or k["name"] == "Full Cover"):
			return true
	return false


func dur_required() -> bool:
	if always():
		return false
	for e in st["effects"]:
		var k = kw(e["name"])
		if k != null and k["cat"] == "stats":
			return true
	return false


# ---------------------------------------------------------------- the steps
## The Condition being built: the [when], or an Action's/[while]'s check.
func cond_of() -> Variant:
	if st["when"] != null:
		return st["when"]
	if st["check"] != null and (not is_passive() or st["check"]["conn"] == "while"):
		return st["check"]
	return null


func set_cond(c) -> void:
	if c == null:
		st["when"] = null
		st["check"] = null
		return
	if c["conn"] == "when":
		st["when"] = c
		if st["check"] != null and st["check"]["conn"] != "if":
			st["check"] = null
	else:
		st["when"] = null
		st["check"] = c


static func _no_subject(ev) -> bool:
	if ev == null:
		return false
	var k = kw(ev["name"])
	return k != null and Rules.truthy(k.get("noSubject"))


func step_on(i: int) -> bool:
	match STEPS[i]["id"]:
		"csubj":
			return cond_of() != null
		"cnarrow":
			var c = cond_of()
			return c != null and c.get("subject") != null and _QUANT.has(c["subject"]["name"])
		"cevent":
			var c2 = cond_of()
			return c2 != null and not (c2.get("event") != null and _no_subject(c2["event"]))
		"check":
			return is_passive() and st["when"] != null
		"ksubj", "kstate":
			return is_passive() and st["when"] != null and st["check"] != null
		"knarrow":
			return is_passive() and st["when"] != null and st["check"] != null and st["check"].get("subject") != null and _QUANT.has(st["check"]["subject"]["name"])
		"tnarrow":
			return st["target"] != null and _NARROWED.has(st["target"]["name"])
		"mods":
			return not mods_for().is_empty()
		"dur":
			return needs_duration() and not always()
	return true


func complete(id: String) -> bool:
	var c = cond_of()
	match id:
		"cond":
			return Rules.truthy(st["visited"].get("cond"))
		"csubj":
			return c != null and (c.get("subject") != null or (c.get("event") != null and _no_subject(c["event"])))
		"cevent":
			return c != null and c.get("event") != null
		"ksubj":
			return st["check"] != null and st["check"].get("subject") != null
		"kstate":
			return st["check"] != null and st["check"].get("event") != null
		"effect":
			return not st["effects"].is_empty() or not st["mods"].is_empty() or Rules.truthy(st["visited"].get("effect"))
		"dur":
			return not dur_required() or st["dur"] != null
	return Rules.truthy(st["visited"].get(id))


func can_next() -> bool:
	var s: Dictionary = STEPS[st["at"]]
	if s["optional"]:
		return true
	if s["id"] == "effect":
		return not st["effects"].is_empty() or not is_passive()
	return complete(s["id"])


func go(i: int) -> void:
	st["param"] = null
	st["at"] = i


func next() -> void:
	var s: Dictionary = STEPS[st["at"]]
	st["visited"][s["id"]] = 1
	for i in range(st["at"] + 1, STEPS.size()):
		if not step_on(i):
			continue
		# changing one part from the review returns there once nothing else is missing
		if Rules.truthy(st["editing"]) and STEPS[i]["id"] != "review" and (true if STEPS[i]["optional"] else complete(STEPS[i]["id"])):
			continue
		go(i)
		return
	go(STEPS.size() - 1)


func back() -> void:
	if st["param"] != null:
		st["param"] = null
		return
	for i in range(st["at"] - 1, -1, -1):
		if step_on(i):
			go(i)
			return


static func param_kind(name) -> Variant:
	var k = kw(name)
	if k == null:
		return null
	if ["amount", "signed", "status", "district", "what", "cover", "card"].has(k.get("num")):
		return k["num"]
	return null


static func default_value(name, kind) -> String:
	if kind == "signed":
		return "+1"
	if name == "turns":
		return "2"
	return "1"


func begin_param(name: String, into: Callable, label = null) -> void:
	var kind = param_kind(name)
	if kind == null:
		into.call(null)
		return
	st["param"] = {"name": name, "kind": kind, "value": default_value(name, kind), "into": into, "label": label if Rules.truthy(label) else name,
		"card": (opt["cards"][0] if opt.get("cards") is Array and not opt["cards"].is_empty() else null), "adj": Rules.truthy(st.get("adjacent"))}
	_within_most()


## A choice on the step it stands on (not while a number is being asked for).
func pick(key: String) -> void:
	var s: Dictionary = STEPS[st["at"]]
	var c = cond_of()
	match s["id"]:
		"cond":
			st["visited"]["cond"] = 1
			if key == "none":
				set_cond(null)
				next()
				return
			var had = cond_of()
			if had == null or had["conn"] != key:
				set_cond({"conn": key, "subject": null, "narrow": [], "event": null})
			next()
		"csubj", "ksubj":
			var cc: Dictionary = c if s["id"] == "csubj" else st["check"]
			if key == "round":
				cc["subject"] = null
				cc["narrow"] = []
				cc["event"] = {"name": "the round begins", "n": null}
				next()
				return
			if cc.get("subject") == null or cc["subject"]["name"] != key:
				cc["subject"] = {"name": key, "n": null}
				cc["narrow"] = []
				if cc.get("event") != null and _no_subject(cc["event"]):
					cc["event"] = null
				if cc.get("event") != null and (key == "this Unit" or key == "attached Unit"):
					var ek = kw(cc["event"]["name"])
					if ek != null and Rules.truthy(ek.get("noSelf")):
						cc["event"] = null
			next()
		"cevent", "kstate":
			var ce: Dictionary = c if s["id"] == "cevent" else st["check"]
			var set_event := func(v):
				ce["event"] = {"name": key, "n": v}
				next()
			begin_param(key, set_event)
		"check":
			st["visited"]["check"] = 1
			if key == "none":
				st["check"] = null
				next()
				return
			if st["check"] == null:
				st["check"] = {"conn": "if", "subject": null, "narrow": [], "event": null}
			next()
		"cnarrow", "knarrow", "tnarrow":
			var into: Dictionary = c if s["id"] == "cnarrow" else (st["check"] if s["id"] == "knarrow" else st["target"])
			if not (into.get("narrow") is Array):
				into["narrow"] = []
			var add_narrow := func(v):
				# one distance at most; a word already chosen is not added twice
				if key == "within":
					into["narrow"] = into["narrow"].filter(func(q): return q["name"] != "within")
				var vs := str(v) if Rules.truthy(v) else ""
				if not into["narrow"].any(func(q): return q["name"] == key and (str(q["n"]) if Rules.truthy(q.get("n")) else "") == vs):
					into["narrow"].append({"name": key, "n": v})
				st["param"] = null
			begin_param(key, add_narrow, key)
		"target":
			if key == "none":
				st["target"] = null
				return
			var set_target := func(v):
				var keep: Array = st["target"]["narrow"] if (st["target"] != null and st["target"]["name"] == key and st["target"].get("narrow") is Array) else []
				st["target"] = {"name": key, "n": v, "narrow": keep}
				next()
			begin_param(key, set_target)
		"effect", "mods":
			var list: Array = st["effects"] if s["id"] == "effect" else st["mods"]
			var add_word := func(v):
				list.append({"name": key, "n": v})
				st["param"] = null
			begin_param(key, add_word, key)
		"dur":
			st["visited"]["dur"] = 1
			if key == "none":
				st["dur"] = null
				next()
				return
			var set_dur := func(v):
				st["dur"] = {"name": key, "n": v}
				next()
			begin_param(key, set_dur, "How many turns" if key == "turns" else key)


# ---------------------------------------------------------------- what a tap does
## The least a number may be.
static func _least(name) -> int:
	if name == "turns":
		return 2
	return 0 if (name == "is within" or name == "within") else 1


## The most a number may be here: 10 turns as the Companion has it, and (the
## game's own) the highest number your blueprint level allows.
func most_of(name) -> Variant:
	if opt.get("most") is Dictionary and opt["most"].has(str(name)):
		return int(opt["most"][str(name)])
	return null


func _within_most() -> void:
	var pp = st.get("param")
	if pp == null or not (pp["kind"] == "amount" or pp["kind"] == "signed"):
		return
	var m = most_of(pp["name"])
	if m == null:
		return
	var v = Scoring.digits(pp["value"])
	if v != null and absi(v) > m:
		pp["value"] = (("+" if v > 0 else "-") + str(m)) if pp["kind"] == "signed" else str(m)


## The − and + beside a number.
func step(by: int) -> void:
	var pp = st.get("param")
	if pp == null or not (pp["kind"] == "amount" or pp["kind"] == "signed" or pp["kind"] == "card"):
		return
	var d = Scoring.digits(pp["value"])
	var v: int = (d if d != null else 0) + by
	if pp["kind"] == "signed":
		if v == 0:
			v = by
		pp["value"] = ("+" if v > 0 else "") + str(v)
	else:
		var lo := _least(pp["name"])
		pp["value"] = str(maxi(lo, mini(LOCK_MAX_TURNS if has_lock() else 10, v) if pp["name"] == "turns" else v))
	_within_most()


## Takes one chosen word back off the step it stands on.
func drop(i: int) -> void:
	var s: Dictionary = STEPS[st["at"]]
	var c = cond_of()
	var list: Array
	match s["id"]:
		"effect": list = st["effects"]
		"mods": list = st["mods"]
		"cnarrow": list = c["narrow"]
		"knarrow": list = st["check"]["narrow"]
		_: list = st["target"]["narrow"]
	if i >= 0 and i < list.size():
		list.remove_at(i)


## From the review: go and change one part.
func edit(step_id: String) -> void:
	st["editing"] = true
	go(step_index(step_id))


func skip() -> void:
	next()


## A choice inside a number or a list being asked for: "ok" takes the number
## as it stands, "X" asks for the card's variable cost, anything else is the
## Status, District or thing picked.
func param_pick(val: String) -> void:
	var pp = st.get("param")
	if pp == null:
		return
	var kind: String = pp["kind"]
	if val == "ok" or (val == "X" and (kind == "amount" or kind == "signed" or kind == "card")):
		var has_num: bool = kind == "amount" or kind == "signed" or kind == "card"
		var raw: String = str(pp["value"]).strip_edges() if has_num else ""
		var use_x: bool = Rules.truthy(opt.get("variable")) and (val == "X" or Keywords._test("(?i)^[+\\-−]?x$", raw))
		if kind == "signed":
			if use_x:
				val = ("-" if Keywords._test("^[\\-−]", raw) else "+") + "X"
			else:
				raw = Keywords._re("[^0-9+\\-−]").sub(raw, "", true)
				var at := raw.find("−")
				if at >= 0:
					raw = raw.substr(0, at) + "-" + raw.substr(at + 1)
				if raw == "":
					raw = "+1"
				if not Keywords._test("^[+-]", raw):
					raw = "+" + raw
				val = raw
		elif kind == "card":
			if pp.get("card") == null:
				return
			st["adjacent"] = Rules.truthy(pp.get("adj"))
			var n := Keywords._re("[^0-9]").sub(raw, "", true)
			val = ("X" if use_x else (n if n != "" else "1")) + " " + str(pp["card"])
		else:
			var n2 := Keywords._re("[^0-9]").sub(raw, "", true)
			val = "X" if use_x else (n2 if n2 != "" else "1")
			# a lock lasts 2 turns at most
			if pp["name"] == "turns" and has_lock():
				var tv = Scoring.digits(val)
				val = str(maxi(1, mini(LOCK_MAX_TURNS, tv if tv != null and tv != 0 else LOCK_MAX_TURNS)))
	var into: Callable = pp["into"]
	st["param"] = null
	into.call(val)


## Which card a Deploy names, and whether it lands beside this Unit.
func set_card(name: String) -> void:
	if st.get("param") != null and st["param"]["kind"] == "card":
		st["param"]["card"] = name


func set_adjacent(on: bool) -> void:
	if st.get("param") != null and st["param"]["kind"] == "card":
		st["param"]["adj"] = on


## Insert, on the review, with nothing wrong: the sentence, and it closes.
func insert() -> String:
	if STEPS[st["at"]]["id"] != "review" or not st["problems"].is_empty():
		return ""
	result = build(st)
	open = false
	return result


func close() -> void:
	cancelled = true
	open = false


## Lets go of what it was building. (A number being asked for holds a
## function that holds the builder: left as it is, neither is ever freed.)
func release() -> void:
	st = {}


## Opens it. o: see opt. Returns false where there is nothing to build with.
func begin(o: Dictionary = {}) -> bool:
	opt = o.duplicate()
	if not Rules.truthy(opt.get("kind")):
		opt["kind"] = Keywords.kind_of(opt.get("tag"))
	result = ""
	cancelled = false
	if Rules.truthy(opt.get("sentence")):
		st = from_sentence(str(opt["sentence"]))
		st["at"] = STEPS.size() - 1
	else:
		st = blank()
	open = true
	return true


# ---------------------------------------------------------------- what it shows
func _colour(name) -> String:
	var c = Keywords.colour_of(name)
	return str(c) if c != null else "#dce8ee"


func _opt(o: Dictionary, on = false) -> Dictionary:
	var name = o.get("name")
	var key: String = str(o["key"]) if Rules.truthy(o.get("key")) else (str(name) if Rules.truthy(name) else (str(o["special"]) if Rules.truthy(o.get("special")) else ""))
	return {"t": "opt", "key": key, "label": str(o["label"]) if Rules.truthy(o.get("label")) else str(name), "desc": str(o["desc"]) if Rules.truthy(o.get("desc")) else "",
		"on": Rules.truthy(on), "colour": _colour(name) if Rules.truthy(name) else "#dce8ee"}


func _chip_label(p: Dictionary) -> String:
	return Keywords.label({"type": "kw", "name": p["name"], "n": p.get("n"), "kw": kw(p["name"])})


func _drops(list: Array) -> Array:
	var out := []
	for i in list.size():
		out.append({"t": "drop", "i": i, "label": _chip_label(list[i]), "colour": _colour(list[i]["name"])})
	return out


## The coloured sentence as it will read: [{t, kw, colour}], or [] with nothing built.
static func runs(text: String) -> Array:
	return Keywords.display_runs(text) if text != "" else []


func _param_view() -> Array:
	var pp: Dictionary = st["param"]
	var k = kw(pp["name"])
	var kd: Dictionary = k if k is Dictionary else {}
	var out := [{"t": "note", "text": str(kd["desc"]) if Rules.truthy(kd.get("desc")) else ""}]
	var kind: String = pp["kind"]
	if kind == "amount" or kind == "signed":
		out.append({"t": "group", "text": str(kd["numLabel"]) if Rules.truthy(kd.get("numLabel")) else "Number"})
		out.append({"t": "num", "value": str(pp["value"])})
	elif kind == "status":
		out.append({"t": "group", "text": "Which Status"})
		for x in Keywords.KEYWORDS:
			if x["cat"] == "status":
				out.append(_opt({"name": x["name"], "key": "pv:" + str(x["name"]), "desc": x.get("desc")}))
	elif kind == "district":
		out.append({"t": "group", "text": "Which District"})
		for d in DISTRICTS:
			out.append(_opt({"name": "District", "label": "District %s · %s" % [d[0], d[1]], "key": "pv:" + d[0]}))
	elif kind == "what":
		out.append({"t": "group", "text": "What to take off"})
		out.append(_opt({"name": "remove", "label": "a piece of Equipment", "key": "pv:Equipment"}))
		for x in Keywords.KEYWORDS:
			if x["cat"] == "status":
				out.append(_opt({"name": x["name"], "key": "pv:" + str(x["name"])}))
	elif kind == "cover":
		# Revision 16.3
		out.append({"t": "group", "text": "Which Barricade"})
		out.append(_opt({"name": "Barricade", "label": "Half Cover Barricade", "key": "pv:Half"}))
		out.append(_opt({"name": "Barricade", "label": "Full Cover Barricade", "key": "pv:Full"}))
	elif kind == "card":
		var cards: Array = opt["cards"] if opt.get("cards") is Array else []
		out.append({"t": "group", "text": "How many"})
		out.append({"t": "num", "value": str(pp["value"])})
		out.append({"t": "group", "text": "What"})
		if not cards.is_empty():
			out.append({"t": "select", "options": cards.map(func(c): return str(c)), "value": pp.get("card")})
		else:
			out.append({"t": "note", "text": "No Troop cards to deploy yet."})
		out.append({"t": "check", "text": "beside this Unit (adjacent), not on a Spawn Tile", "on": Rules.truthy(pp.get("adj"))})
	# Handbook 15.8: on a card with a variable cost, a keyword's number may be X
	if kind == "amount" or kind == "signed" or kind == "card":
		out.append({"t": "button", "key": "pv:ok", "label": "Use this", "primary": true})
		if Rules.truthy(opt.get("variable")):
			out.append({"t": "button", "key": "pv:X", "label": "Use X, the card’s variable cost", "primary": false})
	return out


func _chips_by_group(src: Array, extra := {}) -> Array:
	var order := []
	var groups := {}
	for o in src:
		if not groups.has(o["group"]):
			groups[o["group"]] = []
			order.append(o["group"])
		groups[o["group"]].append(o)
	for g in extra:
		if not groups.has(g):
			order.append(g)
		groups[g] = extra[g]
	var out := []
	for g in order:
		out.append({"t": "group", "text": g})
		for o in groups[g]:
			out.append({"t": "chip", "key": o["name"], "label": str(o["label"]) if Rules.truthy(o.get("label")) else str(o["name"]), "colour": _colour(o["name"])})
	return out


## What the step it stands on shows, top to bottom: notes, groups, options,
## chips, a number, the review's rows.
func body() -> Array:
	var s: Dictionary = STEPS[st["at"]]
	if st["param"] != null:
		return _param_view()
	var c = cond_of()
	var out := []
	match s["id"]:
		"cond":
			var none: Dictionary
			if is_passive():
				none = {"key": "none", "label": "Always on", "desc": "On for as long as its card is active. Stats and Statuses simply hold; damage or healing happens once each round, at Recharge."}
			else:
				none = {"key": "none", "label": "Every time it is used", "desc": "No Condition."}
			out.append(_opt(none, Rules.truthy(st["visited"].get("cond")) and c == null))
			if is_passive():
				if allowed("when"):
					out.append(_opt({"name": "when", "key": "when", "label": "When something happens…", "desc": "Reacts: it happens each time the event does."}, st["when"] != null))
				if allowed("while"):
					out.append(_opt({"name": "while", "key": "while", "label": "While something is true…", "desc": "On for as long as a state holds, and off the moment it does not."}, st["check"] != null and st["check"]["conn"] == "while"))
			elif allowed("if"):
				out.append(_opt({"name": "if", "key": "if", "label": "Only if…", "desc": "Checks as the Action resolves; if it is not so, this effect does not happen."}, st["check"] != null))
		"csubj", "ksubj":
			var cc: Dictionary = c if s["id"] == "csubj" else st["check"]
			for o in subjects_for(cc["conn"], s["id"] == "ksubj"):
				var special := Rules.truthy(o.get("special"))
				var item: Dictionary = o.duplicate()
				item["key"] = "round" if special else o["name"]
				var on: bool = (cc.get("event") != null and cc["event"]["name"] == "the round begins") if special else (cc.get("subject") != null and cc["subject"]["name"] == o["name"])
				out.append(_opt(item, on))
		"cnarrow", "knarrow", "tnarrow":
			var into: Dictionary = c if s["id"] == "cnarrow" else (st["check"] if s["id"] == "knarrow" else st["target"])
			var list: Array = into["narrow"] if into.get("narrow") is Array else []
			out.append({"t": "note", "text": "Optional. Two of the same kind mean either will do; different kinds mean both must match."})
			out.append_array(_drops(list))
			var extra := {}
			if s["id"] != "tnarrow" and allowed("within"):
				extra["Distance"] = [{"name": "within", "label": "within N tiles", "desc": "Only those that many tiles or fewer from this Unit.", "group": "Distance"}]
			out.append_array(_chips_by_group(narrow_for(), extra))
		"cevent", "kstate":
			var ce: Dictionary = c if s["id"] == "cevent" else st["check"]
			var evs := events_for(ce, s["id"] == "kstate")
			if evs.is_empty():
				out.append({"t": "note", "text": "Nothing fits here" + (" on this chassis" if opt.get("allowed") is Array else "") + ". Go back and choose differently."})
			else:
				var ev := evs.filter(func(k): return k["role"] == "event")
				var stt := evs.filter(func(k): return k["role"] == "state")
				if not ev.is_empty():
					out.append({"t": "group", "text": "What this Action did" if ce["conn"] == "if" else "Events"})
					for k in ev:
						out.append(_opt({"name": k["name"], "desc": k.get("desc")}, ce.get("event") != null and ce["event"]["name"] == k["name"]))
				if not stt.is_empty():
					out.append({"t": "group", "text": "States"})
					for k in stt:
						out.append(_opt({"name": k["name"], "desc": k.get("desc")}, ce.get("event") != null and ce["event"]["name"] == k["name"]))
		"check":
			out.append(_opt({"key": "none", "label": "No", "desc": "It happens every time the event does."}, Rules.truthy(st["visited"].get("check")) and st["check"] == null))
			if allowed("if"):
				out.append(_opt({"name": "if", "key": "if", "label": "Only if…", "desc": "Checks a state at that moment: “when this Unit takes damage, if it is below half HP”."}, st["check"] != null))
		"target":
			out.append({"t": "note", "text": "With no Target, it applies to this Unit." if is_passive() else "Optional for a Deploy or Modifiers alone."})
			for o in targets_for():
				out.append(_opt(o, st["target"] != null and st["target"]["name"] == o["name"]))
			if st["target"] != null:
				out.append(_opt({"key": "none", "label": "No Target", "desc": "Clear the Target."}))
		"effect", "mods":
			var is_effect: bool = s["id"] == "effect"
			var list2: Array = st["effects"] if is_effect else st["mods"]
			out.append({"t": "note", "text": "Choose one, then add more if it does several things." if is_effect else "Optional. A Modifier changes how the Action works; several multiply together."})
			out.append_array(_drops(list2))
			out.append_array(_chips_by_group(effects_for() if is_effect else mods_for()))
		"dur":
			if not dur_required():
				out.append(_opt({"key": "none", "label": "The default", "desc": "A Status lasts 1 turn when no Duration is given."}, Rules.truthy(st["visited"].get("dur")) and st["dur"] == null))
			else:
				out.append({"t": "note", "text": "A Stats change needs a Duration, or it would last no time at all."})
			if has_lock():
				out.append({"t": "note", "text": "Stunned, Rooted, Pinned and Marked last 2 turns at most."})
			for n in ["turns", "persistent", "while attached"]:
				if kw(n) == null or not allowed(n):
					continue
				if n == "while attached" and not is_equip():
					continue
				# a lock lasts 2 turns at most, so it is never open-ended
				if n != "turns" and has_lock():
					continue
				out.append(_opt({"name": n, "label": "for N turns" if n == "turns" else n, "desc": kw(n).get("desc")}, st["dur"] != null and st["dur"]["name"] == n))
		"review":
			out = review()
	return out


## text: the part as it is marked; shown: as it reads.
func _row(label: String, text: String, step_id: String, dim := false) -> Dictionary:
	return {"t": "row", "label": label, "text": text, "shown": text if dim else shown(text), "step": step_id, "dim": dim}


## A marked text as it reads on the sheet.
static func shown(text: String) -> String:
	return "".join(Keywords.display_runs(text).map(func(r): return str(r["t"]))) if text != "" else ""


## The review: each part with a way to change it, then anything wrong.
func review() -> Array:
	var text := build(st)
	var probs: Array = ["the effect is empty"]
	if text != "":
		var ctx := {"kind": opt.get("kind")}
		if opt.has("variable"):
			ctx["variable"] = Rules.truthy(opt["variable"])
		probs = Keywords.problems(Keywords.analyse(text), ctx)
	if dur_required() and st["dur"] == null:
		probs.append("a Stats change needs a Duration")
	if st["effects"].is_empty() and st["mods"].is_empty():
		probs.append("it does nothing yet: choose what it does")
	var c = cond_of()
	var out := []
	out.append(_row("Condition", clause_text(c), "cond") if c != null else _row("Condition", "Always on" if is_passive() else "Every time it is used", "cond", true))
	if is_passive() and st["when"] != null:
		out.append(_row("Check", clause_text(st["check"]), "check") if st["check"] != null else _row("Check", "None", "check", true))
	if st["target"] != null:
		var bits := [tok(st["target"])]
		for q in (st["target"]["narrow"] if st["target"].get("narrow") is Array else []):
			bits.append(tok(q))
		out.append(_row("Target", " ".join(bits), "target"))
	else:
		out.append(_row("Target", "This Unit" if is_passive() else "None", "target", true))
	out.append(_row("Does", " and ".join(st["effects"].map(tok)), "effect") if not st["effects"].is_empty() else _row("Does", "Nothing yet", "effect", true))
	if not mods_for().is_empty():
		out.append(_row("Modifiers", " and ".join(st["mods"].map(tok)), "mods") if not st["mods"].is_empty() else _row("Modifiers", "None", "mods", true))
	if needs_duration() and not always():
		if st["dur"] != null:
			out.append(_row("Lasts", ("for " + tok(st["dur"])) if st["dur"]["name"] == "turns" else tok(st["dur"]), "dur"))
		else:
			out.append(_row("Lasts", "The default", "dur", true))
	if Rules.truthy(st.get("ownWords")):
		out.append({"t": "note", "text": "This effect had words of your own in it. Inserting replaces it with the built sentence; add flavour back in the Rules text afterwards."})
	if not probs.is_empty():
		out.append({"t": "bad", "lines": probs})
	st["problems"] = probs
	return out


## What this effect is worth, and the ability with it: {mine, detail, total, attack}.
func power_line(text: String) -> Dictionary:
	var role := str(opt["role"] if Rules.truthy(opt.get("role")) else "")
	var attack := Keywords._test("(?i)^(melee|ranged|cyber)$", role)
	var d = Scoring.keyword_detail(text, false)
	var mine: int = d["points"] if d != null else 0
	var total := Scoring.ability_power({"text": (str(opt["others"] if Rules.truthy(opt.get("others")) else "") + " " + text).strip_edges(), "role": role})
	var detail := ""
	if d != null and not d["mods"].is_empty():
		detail = " (%s × %s)" % [Scoring.text(d["base"]), " × ".join(d["mods"].map(func(m): return "%s %s" % [m["name"], Scoring.text(snappedf(m["x"], 0.01))]))]
	return {"mine": mine, "detail": detail, "total": total, "attack": attack}


## The same in words, as the sheet says it.
func power_texts(text: String) -> Array:
	var p := power_line(text)
	return ["This effect %d%s" % [p["mine"], p["detail"]], "Ability power %d%s" % [p["total"], " (with its attack)" if p["attack"] else ""], "Conditions are not scored yet"]


## Everything the sheet draws, in one piece.
func view() -> Dictionary:
	var s: Dictionary = STEPS[st["at"]]
	var text := build(st)
	var last: bool = s["id"] == "review"
	var b := body()      # (the review settles what is wrong, so it comes before the buttons)
	# later steps appear as earlier choices call for them, so only this step's number is shown
	var n := 0
	if step_on(st["at"]):
		for i in range(0, st["at"] + 1):
			if step_on(i):
				n += 1
	var in_param: bool = st["param"] != null
	return {"head": "Edit an effect" if Rules.truthy(opt.get("sentence")) else "Build an effect",
		"sentence": text, "runs": runs(text), "power": power_line(text),
		"step": ("Review" if last else "Step %d" % n) + (" · optional" if (s["optional"] and not last) else ""),
		"title": str(st["param"]["label"]) if in_param else str(s["title"]),
		"body": b,
		"back": not (st["at"] == 0 and not in_param),
		"skip": s["optional"] and not last and not in_param,
		"next": {"shown": not last and not in_param, "enabled": can_next()},
		"insert": {"shown": last, "enabled": last and st["problems"].is_empty(), "label": "Replace" if Rules.truthy(opt.get("sentence")) else "Insert"}}
