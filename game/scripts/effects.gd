## The effect engine (Handbook 15.3 and 15.6), brought across from the
## Companion's Battle Simulator: it reads a card's text with the keyword
## library and carries it out on the battle.
##
## One sentence is one effect, read Condition, Target, Effect, Duration. Things
## that happen are announced as events; a Passive listening with [when] fires
## each time its event happens, never from anything its own effect set off. A
## Passive with no [when] is always on while its card is active, worked out
## afresh from where everyone stands. What it cannot do it says: plain text is
## logged as not carried out, and an effect with keywords that could not
## resolve stops the fight until the player has seen it.
##
## Each function names the simulator's own (simRunText, simApplyKeyword...);
## tests/sim_diff.gd proves they give the same answers, fight by fight.
class_name Effects
extends RefCounted

## Effects that happen at once rather than staying on.
const INSTANT := {"damage": 1, "heal": 1, "Push": 1, "Deploy": 1, "remove": 1, "Sacrifice": 1, "Recover": 1, "Draw": 1, "gain Aether": 1, "Barricade": 1}
## Statuses that help the Unit that has them (their floats are green).
const BUFFS := {"evasive": 1, "half cover": 1, "full cover": 1, "hardened": 1}
## The order the simulator looks round a tile, for Push, Pierce and Deploy.
const AROUND := [[1, 0], [0, 1], [-1, 1], [-1, 0], [0, -1], [1, -1]]

## The Battle. It holds this engine, so the engine holds it only weakly:
## two things each keeping the other alive would never be let go.
var _battle: WeakRef
var b:
	get:
		return _battle.get_ref()
var queue: Array = []        # events waiting for the Passives
var busy := false
var origin: Array = []       # the Passives whose effect is running now
var dealer = null            # who is dealing whatever damage happens now
var halted_passives := {}
var source := ""             # the card whose text is being carried out now


func _init(battle) -> void:
	_battle = weakref(battle)


# ---------------------------------------------------------------- events
## simEmit
func emit(type: String, subject = null, other = null, extra = null) -> void:
	if b.units == null:
		return
	queue.append({"type": type, "subject": subject, "other": other,
		"status": extra.get("status") if extra is Dictionary and extra.get("status") != null else null, "origin": origin.duplicate()})


func _is_ours(u) -> bool:
	for x in b.units:
		if is_same(x, u):
			return true
	return false


## The rules report damage and statuses as they happen.
func on_hit(u, _amount) -> void:
	if not _is_ours(u):
		return
	var d = dealer
	u["_lastDealer"] = d["id"] if d != null and not is_same(d, u) else null
	emit("takes damage", u, d if d != null and not is_same(d, u) else null)
	if d != null and not is_same(d, u):
		emit("deals damage", d, u)


func on_status(u, name) -> void:
	if not _is_ours(u):
		return
	emit("gains", u, dealer, {"status": name})


## simLeader and simLeaderUnit: the Strike Team's leader while it stands, else
## the first of your Units standing, else your first Hero.
func leader_unit():
	for u in b.units:
		if b.leader_id != "" and u["id"] == b.leader_id and not Rules.truthy(u.get("down")):
			return u
	for u in b.units:
		if u["side"] == "ally" and not Rules.truthy(u.get("down")):
			return u
	for u in b.units:
		if u["side"] == "ally" and Keywords._re("(?i)hero").search(str(u.get("cardType", "") if u.get("cardType") != null else "")) != null:
			return u
	return null


static func _passive_tag(tag) -> bool:
	return Keywords._re("(?i)^(passive|aura)$").search(str(tag if tag != null else "")) != null


## simPassiveSources: every Passive that could be active.
func passive_sources() -> Array:
	var out := []
	for u in b.units:
		var acts: Array = u.get("actions") if u.get("actions") != null else []
		for ai in acts.size():
			var a: Dictionary = acts[ai]
			if not Rules.truthy(a.get("text")) or not _passive_tag(a.get("tag")):
				continue
			out.append({"pid": str(u["id"]) + ":a" + str(ai), "owner": u, "holder": null, "text": a["text"], "name": a.get("name") if Rules.truthy(a.get("name")) else u["name"]})
		var eqs: Array = u.get("equipFx") if u.get("equipFx") != null else []
		for ei in eqs.size():
			var eq: Dictionary = eqs[ei]
			var fxl: Array = eq.get("fx") if eq.get("fx") != null else []
			for fi in fxl.size():
				var f: Dictionary = fxl[fi]
				if not Rules.truthy(f.get("text")) or not _passive_tag(f.get("kind")):
					continue
				out.append({"pid": str(u["id"]) + ":e" + str(ei) + "." + str(fi), "owner": u, "holder": u, "text": f["text"], "name": eq.get("name")})
	var lead = leader_unit()
	if lead != null:
		for pi in b.protos.size():
			var pr: Dictionary = b.protos[pi]
			var fx: Array = pr.get("fx") if pr.get("fx") != null else ([{"kind": "Passive", "text": pr["text"]}] if Rules.truthy(pr.get("text")) else [])
			for fi in fx.size():
				var f2: Dictionary = fx[fi]
				if not Rules.truthy(f2.get("text")) or not _passive_tag(f2.get("kind") if Rules.truthy(f2.get("kind")) else "Passive"):
					continue
				out.append({"pid": "proto" + str(pi) + "." + str(fi), "owner": lead, "holder": null, "text": f2["text"], "name": pr.get("name"), "proto": true})
	return out


## simFlushEvents: the Passives hear what has happened.
func flush() -> void:
	if busy:
		return
	busy = true
	var guard := 0
	while not queue.is_empty() and guard < 200:
		guard += 1
		var ev: Dictionary = queue.pop_front()
		for src in passive_sources():
			if ev["origin"].has(src["pid"]):
				continue
			var owner: Dictionary = src["owner"]
			if not Rules.truthy(owner.get("pos")):
				continue
			if Rules.truthy(owner.get("down")) and not (ev["type"] == "is Incapacitated" and is_same(ev["subject"], owner)):
				continue
			for sent in Keywords.sentences(src["text"]):
				var an := Keywords.analyse(sent)
				if an["when"] == null:
					continue
				var ctx := {"actor": owner, "holder": src["holder"], "sourceCard": src["name"], "kind": "passive", "event": ev,
					"subject": ev["subject"], "target": ev["other"], "pid": src["pid"]}
				if not when_matches(an["when"], ev, ctx):
					continue
				origin = ev["origin"] + [src["pid"]]
				run_sentence(sent, ctx, an)
				origin = []
		check_downs(true)
	busy = false
	if not queue.is_empty():
		queue = []
		log_effect("Passives stopped after 200 events in a row, so none could run forever")


# ---------------------------------------------------------------- saying
func log_effect(text: String) -> void:
	b.say(text)


## A card problem: the log has it as the simulator words it; the box the
## player is shown also names the card, when the words don't already.
func halt(text: String) -> void:
	b.say(text, "act", {"halt": true})
	b.halts.append(text if (source == "" or text.begins_with(source + ":")) else source + ": " + text)


func halt_once(ctx: Dictionary, text: String) -> void:
	if Rules.truthy(ctx.get("pid")):
		if halted_passives.has(ctx["pid"]):
			return
		halted_passives[ctx["pid"]] = 1
	halt(text)


## A number floats off a Unit: damage, healing, a status.
func float_on(u, text: String, kind: String) -> void:
	if u != null:
		b.floats.append({"unit": u["id"], "text": text, "kind": kind})


## The same, where the simulator shows nothing (a hazard's bite, a push into a
## wall): the game's own, marked so, and left out when the two are compared.
func float_own(u, text: String, kind: String) -> void:
	if u != null:
		b.floats.append({"unit": u["id"], "text": text, "kind": kind, "own": true})


# ---------------------------------------------------------------- who
func enemies_of(u) -> Array:
	return b.units.filter(func(x): return not Rules.truthy(x.get("down")) and x["side"] != u["side"])


func allies_of(u) -> Array:
	return b.units.filter(func(x): return not Rules.truthy(x.get("down")) and x["side"] == u["side"])


static func dist(a, c) -> int:
	return Rules.hex_distance(a, c) if (Rules.truthy(a) and Rules.truthy(c)) else 99


## simNarrowOK: each Target's narrowing words; two of a kind mean either,
## different kinds mean both.
func narrow_ok(u, narrow, ctx: Dictionary) -> bool:
	if narrow == null or narrow.is_empty():
		return true
	var by := {}
	var kinds := []
	for q in narrow:
		var k: String = q["kw"].get("narrow") if Rules.truthy(q["kw"].get("narrow")) else "archetype"
		if not by.has(k):
			by[k] = []
			kinds.append(k)
		by[k].append(q)
	for kind in kinds:
		var any := false
		for q in by[kind]:
			if kind == "subtype":
				var roles: Array = (u.get("roles") if u.get("roles") != null else []).map(func(x): return str(x).to_lower())
				any = any or roles.has(q["kw"]["name"].to_lower())
			elif kind == "archetype":
				any = any or (u.get("archetypes") if u.get("archetypes") != null else []).any(func(a): return str(a).to_lower() == q["kw"]["name"].to_lower())
			elif kind == "district":
				any = any or (u.get("affinities") if u.get("affinities") != null else []).any(func(a): return str(a.get("district") if a is Dictionary else null) == str(q["n"]))
			elif kind == "distance":
				any = any or (ctx.get("actor") != null and Rules.truthy(ctx["actor"].get("pos")) and Rules.truthy(u.get("pos")) and dist(u["pos"], ctx["actor"]["pos"]) <= int(Rules.num(q["n"], 0)))
			elif kind == "cardtype":
				# Revision 16.3: Troop or Hero
				any = any or str(u.get("cardType") if u.get("cardType") != null else "").to_lower() == q["kw"]["name"].to_lower()
		if not any:
			return false
	return true


## simResolveTargets: who a sentence happens to.
func resolve_targets(targ, ctx: Dictionary) -> Array:
	var actor = ctx.get("actor")
	var centre = ctx.get("tile") if Rules.truthy(ctx.get("tile")) else (ctx["target"]["pos"] if ctx.get("target") != null and Rules.truthy(ctx["target"].get("pos")) else (actor["pos"] if actor != null and Rules.truthy(actor.get("pos")) else null))
	var groups: Array = (targ if targ != null else []).map(func(t): return t if t.has("part") else {"part": t, "narrow": []})
	var plain := []
	var kept := []
	for g in groups:
		if Rules.truthy(g["part"]["kw"].get("narrow")):
			if not plain.is_empty():
				plain[plain.size() - 1]["narrow"].append(g["part"])
			continue
		plain.append(g)
		kept.append(g)
	groups = kept
	var who = null
	var narrow := []
	if ctx.get("kind") == "passive" and not Rules.truthy(ctx.get("tile")):
		centre = actor["pos"] if actor != null else null
	var has_area: bool = groups.any(func(g): return Keywords._re("^all (enemies|allies|units) within$").search(g["part"]["kw"]["name"]) != null)
	for g in groups:
		var p: Dictionary = g["part"]
		var k: String = p["kw"]["name"]
		var n := int(Rules.num(p["n"], 0))
		narrow += (g["narrow"] if g.get("narrow") != null else [])
		if has_area and k.begins_with("target "):
			continue
		var t = ctx.get("target")
		if k == "target enemy":
			who = [t] if t != null and t["side"] != actor["side"] else []
		elif k == "target ally":
			who = [t] if t != null and t["side"] == actor["side"] and (Rules.truthy(ctx.get("fromHand")) or not is_same(t, actor)) else []
		elif k == "target tile":
			var tile = ctx.get("tile")
			who = b.units.filter(func(u): return not Rules.truthy(u.get("down")) and Rules.truthy(u.get("pos")) and u["pos"]["q"] == tile["q"] and u["pos"]["r"] == tile["r"]) if Rules.truthy(tile) else []
		elif k == "this Unit":
			who = [actor]
		elif k == "attached Unit":
			who = [ctx["holder"] if ctx.get("holder") != null else actor]
		elif k == "that Unit":
			who = [ctx["subject"]] if ctx.get("subject") != null else []
		elif k == "the target":
			who = [t] if t != null else []
		elif k == "all enemies within":
			who = enemies_of(actor).filter(func(u): return dist(u.get("pos"), centre) <= n)
		elif k == "all allies within":
			who = allies_of(actor).filter(func(u): return (Rules.truthy(ctx.get("fromHand")) or not is_same(u, actor)) and dist(u.get("pos"), centre) <= n)
		elif k == "all units within":
			who = b.units.filter(func(u): return not Rules.truthy(u.get("down")) and Rules.truthy(u.get("pos")) and dist(u["pos"], centre) <= n)
		# Revision 16.3: a whole side, wherever it stands
		elif k == "all allies":
			who = allies_of(actor).filter(func(u): return Rules.truthy(u.get("pos")))
		elif k == "all enemies":
			who = enemies_of(actor).filter(func(u): return Rules.truthy(u.get("pos")))
		elif k == "adjacent":
			who = (who if who != null else b.units).filter(func(u): return not Rules.truthy(u.get("down")) and Rules.truthy(u.get("pos")) and dist(u["pos"], centre) == 1)
	if who == null:
		who = [ctx["target"]] if ctx.get("target") != null else ([actor] if actor != null else [])
	if not narrow.is_empty():
		who = who.filter(func(u): return narrow_ok(u, narrow, ctx))
	return who


## simSubjectPool: who a Condition is about.
func subject_pool(c: Dictionary, ctx: Dictionary) -> Array:
	var sn: String = c["subject"]["kw"]["name"] if c["subject"] != null else ""
	var a = ctx.get("actor")
	var pool := []
	if sn == "this Unit": pool = [a]
	elif sn == "attached Unit": pool = [ctx["holder"] if ctx.get("holder") != null else a]
	elif sn == "the target": pool = [ctx["target"]] if ctx.get("target") != null else []
	elif sn == "that Unit": pool = [ctx["subject"]] if ctx.get("subject") != null else []
	elif sn == "an ally": pool = allies_of(a).filter(func(u): return not is_same(u, a))
	elif sn == "an enemy": pool = enemies_of(a)
	elif sn == "any Unit": pool = b.units.filter(func(u): return not Rules.truthy(u.get("down")) and Rules.truthy(u.get("pos")))
	return pool.filter(func(u): return u != null and narrow_ok(u, c["narrow"], ctx))


## simWhenMatches: a [when] clause against something that happened.
func when_matches(c: Dictionary, ev: Dictionary, ctx: Dictionary) -> bool:
	var e: Dictionary = c["event"]["kw"]
	var a = ctx.get("actor")
	if ("moves" if e["name"] == "ends its move within" else e["name"]) != ev["type"]:
		return false
	if e["name"] == "gains" and str(c["event"]["n"] if c["event"]["n"] != null else "").strip_edges().to_lower() != str(ev["status"] if ev["status"] != null else "").to_lower():
		return false
	if Rules.truthy(e.get("noSubject")):
		return true
	var s = ev["subject"]
	var sn: String = c["subject"]["kw"]["name"] if c["subject"] != null else ""
	if s == null:
		return false
	var ok := false
	if sn == "this Unit": ok = is_same(s, a)
	elif sn == "attached Unit": ok = is_same(s, ctx["holder"] if ctx.get("holder") != null else a)
	elif sn == "an ally": ok = s["side"] == a["side"] and not is_same(s, a)
	elif sn == "an enemy": ok = s["side"] != a["side"]
	else: ok = sn == "any Unit"
	if not ok or not narrow_ok(s, c["narrow"], ctx):
		return false
	if e["name"] == "ends its move within":
		return Rules.truthy(s.get("pos")) and Rules.truthy(a.get("pos")) and dist(s["pos"], a["pos"]) <= int(Rules.num(c["event"]["n"], 0))
	return true


## simStateOf
func state_of(u: Dictionary, c: Dictionary, ctx: Dictionary) -> bool:
	var e: Dictionary = c["event"]["kw"]
	var n := int(Rules.num(c["event"]["n"], 0))
	var a = ctx.get("actor")
	match e["name"]:
		"is below half HP": return float(u["hp"]) < float(u["hpMax"]) / 2.0
		"is at full HP": return u["hp"] >= u["hpMax"]
		"has": return Rules.has_status(u, str(c["event"]["n"] if c["event"]["n"] != null else "").strip_edges())
		"is within": return Rules.truthy(u.get("pos")) and a != null and Rules.truthy(a.get("pos")) and dist(u["pos"], a["pos"]) <= n
		"is further than": return Rules.truthy(u.get("pos")) and a != null and Rules.truthy(a.get("pos")) and dist(u["pos"], a["pos"]) > n
	return false


## simCheck: an [if] or [while]. In an Action, [if] may also ask what the
## Action itself just did.
func check(c: Dictionary, ctx: Dictionary) -> Dictionary:
	var e: Dictionary = c["event"]["kw"]
	var sn: String = c["subject"]["kw"]["name"] if c["subject"] != null else ""
	if e.get("role") == "event":
		match e["name"]:
			"takes damage": return {"ok": Rules.truthy(ctx.get("selfDamaged")) if sn == "this Unit" else Rules.truthy(ctx.get("damaged"))}
			"deals damage": return {"ok": sn == "this Unit" and Rules.truthy(ctx.get("damaged"))}
			"kills an enemy": return {"ok": sn == "this Unit" and Rules.truthy(ctx.get("killed"))}
			"is Incapacitated": return {"ok": (ctx.get("actor") != null and Rules.truthy(ctx["actor"].get("down"))) if sn == "this Unit" else Rules.truthy(ctx.get("killed"))}
		return {"ok": false}
	var hit = null
	for u in subject_pool(c, ctx):
		if state_of(u, c, ctx):
			hit = u
			break
	return {"ok": hit != null, "who": hit}


# ---------------------------------------------------------------- the board
## A tile's centre, as two whole-precision numbers. (A Vector2 holds single
## precision, and where a line runs exactly between two tiles the smaller
## rounding picked the other one: found by the comparison in 0.7.)
static func centre(q, r) -> Array:
	return [sqrt(3.0) * (float(q) + float(r) / 2.0), 1.5 * float(r)]


## simShapeTiles (Revision 16.3): the tiles a Line or a Cone covers, from the
## attacker toward where it aims. A Line runs n tiles from the neighbour that
## points most nearly at the aim; a Cone is every tile 1 to n away within 30
## degrees either side of it.
func shape_tiles(kind: String, from: Dictionary, aim: Dictionary, n: int) -> Array:
	var out := []
	var a := centre(from["q"], from["r"])
	var c := centre(aim["q"], aim["r"])
	if kind == "Line":
		var dx: float = c[0] - a[0]
		var dy: float = c[1] - a[1]
		var best = null
		var bd := -1e9
		for d in AROUND:
			var p := centre(from["q"] + d[0], from["r"] + d[1])
			var dot: float = (p[0] - a[0]) * dx + (p[1] - a[1]) * dy
			if dot > bd:
				bd = dot
				best = {"q": from["q"] + d[0], "r": from["r"] + d[1]}
		var cur = best
		for i in n:
			if cur == null:
				break
			out.append(cur)
			cur = line_step(from, cur)
		return out
	var ang := atan2(c[1] - a[1], c[0] - a[0])
	for h in b.floor_data.tiles:
		var t := {"q": h.x, "r": h.y}
		var dd: int = int(Rules.hex_distance(from, t))
		if dd < 1 or dd > n:
			continue
		var pc := centre(h.x, h.y)
		var da := absf(atan2(pc[1] - a[1], pc[0] - a[0]) - ang)
		if da > PI:
			da = 2.0 * PI - da
		if da <= PI / 6.0 + 1e-6:
			out.append(t)
	return out


## simAetherDistrict: the District whose Aether a "gain Aether" gives: the
## card's own, or for a Unit's ability the Unit's; "" means Neutral.
func aether_district(ctx: Dictionary) -> String:
	var c = null
	if Rules.truthy(ctx.get("sourceCard")):
		for x in b.cards:
			if x.get("name") == ctx["sourceCard"]:
				c = x
				break
	var aff = null
	if c != null and c.get("affinities") is Array and not c["affinities"].is_empty():
		aff = c["affinities"][0]
	elif ctx.get("actor") != null and ctx["actor"].get("affinities") is Array and not ctx["actor"]["affinities"].is_empty():
		aff = ctx["actor"]["affinities"][0]
	var d = aff.get("district") if aff is Dictionary else null
	return str(d) if (Rules.truthy(d) and str(d) != "any" and str(d) != "neu") else ""


## simLineStep: the tile that carries the line on from one tile through another.
static func line_step(from: Dictionary, at: Dictionary) -> Dictionary:
	var a := centre(from["q"], from["r"])
	var c := centre(at["q"], at["r"])
	var dx: float = c[0] - a[0]
	var dy: float = c[1] - a[1]
	var best = null
	var bd := -1e9
	for d in AROUND:
		var n := {"q": at["q"] + d[0], "r": at["r"] + d[1]}
		var p := centre(n["q"], n["r"])
		var dot: float = (p[0] - c[0]) * dx + (p[1] - c[1]) * dy
		if dot > bd:
			bd = dot
			best = n
	return best


func _sorted_key(a: Dictionary, c: Dictionary) -> String:
	var ka := Rules.hex_key(a["q"], a["r"])
	var kb := Rules.hex_key(c["q"], c["r"])
	return (ka + "|" + kb) if ka < kb else (kb + "|" + ka)


## simPush: straight away from whoever pushed. Blocked, it stops and takes 1
## damage per tile it could not move, and a Unit that blocked it takes the same.
func push(u: Dictionary, from, tiles: int) -> String:
	if not Rules.truthy(u.get("pos")) or not Rules.truthy(from):
		return "nowhere to push from"
	var moved := 0
	for i in tiles:
		var best := line_step(from, u["pos"])
		var h := Vector2i(best["q"], best["r"])
		var blocker = b.unit_at(h)
		var off: bool = not b.floor_data.has_tile(h)
		var walled: bool = b._wall_dict.has(_sorted_key(u["pos"], best))
		if off or walled or blocker != null:
			var left := tiles - i
			Rules.hit(u, left)
			float_own(u, "-%d HP" % left, "damage")
			var why: String = blocker["name"] if blocker != null else ("a wall" if walled else "the edge of the floor")
			if blocker != null:
				Rules.hit(blocker, left)
				float_own(blocker, "-%d HP" % left, "damage")
			return ("pushed %d, then " % moved if moved else "") + "hit " + why + ": " + str(left) + " damage to " + u["name"] + ((" and " + blocker["name"]) if blocker != null else "")
		u["pos"] = best
		moved += 1
		hazard_hit(u, "is pushed onto")
	return "pushed %d tile%s" % [moved, "" if moved == 1 else "s"]


static func _int_of(v, keep: String = "0-9-"):
	var s := Keywords._re("[^" + keep + "]").sub(str(v if v != null and not (v is String and v == "") else ""), "", true)
	return Rules.num(s, null)


static func _names(who: Array) -> String:
	return ", ".join(who.map(func(u): return u["name"]))


## simApplyKeyword: one keyword, on the Units it falls to.
func apply_keyword(p: Dictionary, who: Array, ctx: Dictionary, dur) -> void:
	var k: String = p["kw"]["name"]
	var n = _int_of(p["n"])
	var name: String = ctx["actor"]["name"] if ctx.get("actor") != null else "The effect"
	if p["kw"]["cat"] == "status":
		var turns = null
		if dur != null:
			turns = (Rules.num(dur["n"], 0) if Rules.truthy(Rules.num(dur["n"], 0)) else 1) if dur["kw"]["name"] == "turns" else 999
		var strength = null if Rules.strengthless(k) else (1 if n == null else n)
		# (Handbook 16.0) a lock doesn't stack, and doesn't land again just after it ends
		var guarded := who.filter(func(u): return Rules.lock_block(u, k) == "guard")
		var already := who.filter(func(u): return Rules.lock_block(u, k) == "already")
		if not guarded.is_empty():
			log_effect(_names(guarded) + " " + ("just came out of a Stun" if k.to_lower() == "stunned" else "was only just " + k) + " and shrug" + ("s" if guarded.size() == 1 else "") + " it off")
		if not already.is_empty():
			log_effect(_names(already) + (" is" if already.size() == 1 else " are") + " already " + k)
		if not guarded.is_empty() or not already.is_empty():
			who = who.filter(func(u): return Rules.lock_block(u, k) == "")
			if who.is_empty():
				return
		if Rules.is_lock(k) and turns != null:
			turns = mini(int(turns), Rules.LOCK_MAX_TURNS)
		for u in who:
			Rules.add_status(u, k, n if (Rules.strengthless(k) and n != null and turns == null) else strength, name, turns)
			float_on(u, k + ((" " + str(strength)) if strength != null else ""), "buff" if BUFFS.has(k.to_lower()) else "debuff")
		var tt = turns if turns != null else (n if (Rules.strengthless(k) and n != null) else 1)
		if Rules.is_lock(k):
			tt = mini(int(tt), Rules.LOCK_MAX_TURNS)
		log_effect(_names(who) + " gain" + ("s " if who.size() == 1 else " ") + k + ((" " + str(strength)) if strength != null else "") + ("" if tt >= 999 else " for " + str(tt) + " turn" + ("" if tt == 1 else "s")))
		return
	if k == "Burst" or k == "Lunge" or k == "Charge":
		return                    # carried out by the attack itself
	# Revision 16.1: Dash. One of yours may move that much more this turn; an
	# Enemy Dashes at once, away from the Unit it attacked.
	if k == "Dash":
		var dn: int = 1 if n == null else maxi(1, n)
		for u in who:
			if Rules.truthy(u.get("down")) or not Rules.truthy(u.get("pos")):
				continue
			if u["side"] == "enemy":
				var from = ctx.get("target") if (ctx.get("target") != null and ctx["target"]["side"] != u["side"]) else null
				log_effect(b.dash_away(u, from, dn))
				continue
			u["dash"] = int(Rules.num(u.get("dash"), 0)) + dn
			log_effect(u["name"] + " may Dash " + str(dn) + " tile" + ("" if dn == 1 else "s") + " more this turn")
		return
	# Leap: for as long as its Duration, or with none for the rest of the fight
	if k == "Leap":
		var ln: int = 1 if n == null else maxi(1, n)
		for u in who:
			if dur != null:
				var dn2 = Rules.num(dur["n"], 0)
				var lm := {"stat": "LEAP", "amt": ln, "dur": dur["kw"]["name"], "n": dn2 if Rules.truthy(dn2) else null, "source": ctx["sourceCard"] if Rules.truthy(ctx.get("sourceCard")) else name}
				if lm["dur"] == "turns" and b.half() == "enemy":
					lm["late"] = true
				if u.get("mods") == null:
					u["mods"] = []
				u["mods"].append(lm)
			else:
				u["leap"] = maxi(int(Rules.num(u.get("leap"), 0)), ln)
		log_effect(_names(who) + " can Leap " + str(ln) + " tile" + ("" if ln == 1 else "s") + ((" (" + dur["kw"]["name"] + ((" " + str(dur["n"])) if Rules.truthy(dur["n"]) else "") + ")") if dur != null else ""))
		return
	if k == "damage":
		var dmg: int = n if Rules.truthy(n) else 0
		for u in who:
			Rules.hit(u, dmg)
			float_on(u, "-%d HP" % dmg, "damage")
		# Revision 16.3: on a card with no attack of its own, this is the damage its AoE, Line or Cone carries on
		if not (float(Rules.num(ctx.get("damage"), 0)) > 0):
			ctx["damage"] = dmg
		log_effect(_names(who) + " take" + ("s " if who.size() == 1 else " ") + str(dmg) + " damage")
		return
	if k == "heal":
		var amt: int = n if Rules.truthy(n) else 0
		for u in who:
			var before: int = u["hp"]
			u["hp"] = mini(u["hpMax"], u["hp"] + amt)
			if u["hp"] > before:
				float_on(u, "+%d HP" % (u["hp"] - before), "heal")
			log_effect(u["name"] + (" is already at full Health" if u["hp"] == before else " heals " + str(u["hp"] - before)))
		return
	if p["kw"]["cat"] == "stats":
		var amt2 = _int_of(p["n"], "0-9+-")
		if amt2 == null:
			halt(k + " on " + name + " gives no amount.")
			return
		if dur == null:
			halt(Keywords.label(p) + " on " + name + " has no Duration, so it would last no time.")
			return
		var stat := "RANGE" if k == "Range" else k
		var dn = Rules.num(dur["n"], 0)
		for u in who:
			if u.get("mods") == null:
				u["mods"] = []
			var mod := {"stat": stat, "amt": amt2, "dur": dur["kw"]["name"], "n": dn if Rules.truthy(dn) else null, "source": ctx["sourceCard"] if Rules.truthy(ctx.get("sourceCard")) else name}
			# Handbook 15.9: a timed change that arrives in the Enemies' half ticks as your next turn ends
			if mod["dur"] == "turns" and b.half() == "enemy":
				mod["late"] = true
			u["mods"].append(mod)
			if stat == "HP":
				u["hpMax"] = maxi(1, u["hpMax"] + amt2)
				u["hp"] = u["hp"] + amt2 if amt2 > 0 else mini(u["hp"], u["hpMax"])
			if stat == "NRG":
				u["nrgMax"] = maxi(0, int(Rules.num(u.get("nrgMax"), 0)) + amt2)
				u["nrg"] = maxi(0, int(Rules.num(u.get("nrg"), 0)) + amt2)
		log_effect(_names(who) + ": " + Keywords.label(p) + " (" + dur["kw"]["name"] + ((" " + str(dur["n"])) if Rules.truthy(dur["n"]) else "") + ")")
		return
	if k == "Push":
		for u in who:
			log_effect(u["name"] + " " + push(u, ctx["actor"]["pos"], n if Rules.truthy(n) else 1))
		return
	if (k == "AoE" or k == "Chain" or k == "Pierce" or k == "Line" or k == "Cone") and not (float(Rules.num(ctx.get("damage"), 0)) > 0):
		log_effect(str(ctx["sourceCard"] if Rules.truthy(ctx.get("sourceCard")) else k) + " did no damage, so its " + k + " carried nothing on")
		return
	var carried: int = ctx["damage"] if Rules.truthy(ctx.get("damage")) else 0
	var rad: int = n if Rules.truthy(n) else 1
	if k == "AoE":
		var ctr = ctx["tile"] if Rules.truthy(ctx.get("tile")) else (ctx["target"]["pos"] if ctx.get("target") != null else null)
		var hit_all: Array = b.units.filter(func(u): return not Rules.truthy(u.get("down")) and Rules.truthy(u.get("pos")) and not is_same(u, ctx.get("target")) and dist(u["pos"], ctr) <= rad)
		if hit_all.is_empty():
			log_effect("AoE caught nobody else")
			return
		for u in hit_all:
			Rules.hit(u, carried)
			float_on(u, "-%d HP" % carried, "damage")
		log_effect("AoE " + str(rad) + " also hits " + _names(hit_all) + " for " + str(carried))
		return
	if k == "Chain":
		var from = ctx["target"]["pos"] if ctx.get("target") != null else null
		var cands := enemies_of(ctx["actor"]).filter(func(u): return not is_same(u, ctx.get("target")) and dist(u.get("pos"), from) <= rad)
		cands = Rules.stable_sort(cands, func(x, y): return dist(x.get("pos"), from) - dist(y.get("pos"), from))
		if cands.is_empty():
			log_effect("Chain found no second Enemy")
			return
		var nxt: Dictionary = cands[0]
		Rules.hit(nxt, carried)
		float_on(nxt, "-%d HP" % carried, "damage")
		log_effect("Chain jumps to " + nxt["name"] + " for " + str(carried))
		return
	if k == "Pierce":
		var a = ctx["actor"].get("pos")
		var t = ctx["target"]["pos"] if ctx.get("target") != null else null
		if not Rules.truthy(a) or not Rules.truthy(t):
			log_effect("Pierce had no line to follow")
			return
		var best := line_step(a, t)
		var behind = b.unit_at(Vector2i(best["q"], best["r"]))
		if behind == null:
			log_effect("Pierce found nobody behind " + ctx["target"]["name"])
			return
		Rules.hit(behind, carried)
		float_on(behind, "-%d HP" % carried, "damage")
		log_effect("Pierce carries through to " + behind["name"] + " for " + str(carried))
		return
	# Revision 16.3: Line and Cone carry the attack's damage to everyone in their shape
	if k == "Line" or k == "Cone":
		var from2 = ctx["actor"].get("pos") if ctx.get("actor") != null else null
		var aim2 = ctx["tile"] if Rules.truthy(ctx.get("tile")) else (ctx["target"]["pos"] if ctx.get("target") != null else null)
		if not Rules.truthy(from2) or not Rules.truthy(aim2):
			log_effect(k + " had no direction to go in")
			return
		var shaped := []
		for t3 in shape_tiles(k, from2, aim2, rad):
			var su = b.unit_at(Vector2i(t3["q"], t3["r"]))
			if su != null and not is_same(su, ctx.get("target")) and not is_same(su, ctx.get("actor")):
				shaped.append(su)
		if shaped.is_empty():
			log_effect(k + " " + str(rad) + " caught nobody else")
			return
		for u in shaped:
			Rules.hit(u, carried)
			float_on(u, "-%d HP" % carried, "damage")
		log_effect(k + " " + str(rad) + " also hits " + _names(shaped) + " for " + str(carried))
		return
	# Revision 16.3: drawing cards and gaining Aether are yours to do; on an Enemy's card they do nothing
	if k == "Draw" or k == "gain Aether":
		if ctx.get("actor") == null or ctx["actor"]["side"] != "ally":
			log_effect("An Enemy has no cards to draw" if k == "Draw" else "An Enemy has no Aether to gain")
			return
		var amt3: int = 1 if n == null else maxi(0, n)
		# a nameless Passive is told by its Unit's name, not "(unnamed)"
		var by: String = str(ctx["sourceCard"]) if (Rules.truthy(ctx.get("sourceCard")) and str(ctx["sourceCard"]) != "(unnamed)") else name
		if k == "Draw":
			var drawn := 0
			for i3 in amt3:
				if b.deck.is_empty():
					break
				b.hand.append(b.deck.pop_front())
				drawn += 1
			log_effect((by + ": drew " + str(drawn) + " card" + ("" if drawn == 1 else "s")) if drawn > 0 else "The Deck is empty: nothing to draw")
			return
		var dist3 = aether_district(ctx)
		var gain := {}
		gain["d" + dist3 if dist3 != "" else "generic"] = amt3
		Rules.aether_add(b.aether, gain)
		log_effect(by + ": gained " + Battle.aether_label(gain) + " Aether")
		return
	# Revision 16.3: a Half or Full Cover Barricade on an empty tile, for the rest of the fight
	if k == "Barricade":
		var nb := str(p["n"] if p["n"] != null else "").strip_edges()
		var which := "Full" if Keywords._test("(?i)^full$", nb) else ("Half" if Keywords._test("(?i)^half$", nb) else "")
		var spot = ctx.get("tile")
		var src: String = str(ctx["sourceCard"]) if Rules.truthy(ctx.get("sourceCard")) else name
		if which == "":
			halt("Barricade on " + src + " does not say Half or Full.")
			return
		if not Rules.truthy(spot):
			log_effect("Barricade had no tile to go on")
			return
		var h3 := Vector2i(int(spot["q"]), int(spot["r"]))
		if not b.place_barricade(h3, which):
			log_effect("A Barricade needs an empty tile, and that one is not")
			return
		log_effect(src + " puts a " + which + " Cover Barricade on " + str(h3.x) + "," + str(h3.y))
		return
	if k == "Deploy":
		var dm := Keywords._re("^(\\d+)\\s+(.+)$").search(str(p["n"] if p["n"] != null else ""))
		if dm == null:
			halt("Deploy on " + (str(ctx["sourceCard"]) if (Rules.truthy(ctx.get("fromHand")) and Rules.truthy(ctx.get("sourceCard"))) else name) + " does not name what to deploy.")
			return
		var card = null
		for c in b.cards:
			if c.get("name") == dm.get_string(2).strip_edges():
				card = c
				break
		if card == null:
			halt("Deploy names " + dm.get_string(2) + ", which is not a card you have.")
			return
		var adj: bool = Rules.truthy(ctx.get("adjacent"))
		var placed := 0
		var count = Rules.num(dm.get_string(1), 0)
		count = count if Rules.truthy(count) else 1
		for i in count:
			var spot = null
			if adj and Rules.truthy(ctx["actor"].get("pos")):
				for d in AROUND:
					var c2 := Vector2i(ctx["actor"]["pos"]["q"] + d[0], ctx["actor"]["pos"]["r"] + d[1])
					if b.floor_data.has_tile(c2) and b.unit_at(c2) == null:
						spot = {"q": c2.x, "r": c2.y}
						break
			else:
				for t2 in b.spawn_tiles(ctx["actor"]["side"]):
					if b.unit_at(t2) == null:
						spot = {"q": t2.x, "r": t2.y}
						break
			if spot == null:
				log_effect("Deploy had nowhere to put " + card["name"] + ((" " + str(i + 1)) if count > 1 else ""))
				continue
			var nu := Battle.x_fill(Rules.unit_from_card(Roster.unit_spec(card), ctx["actor"]["side"]))
			b.deployed += 1
			nu["id"] = "d" + str(b.deployed)
			nu["pos"] = spot
			b.units.append(nu)
			b.looks[nu["id"]] = b.roster.token_for(card) if b.roster != null else {}
			placed += 1
			run_trigger(nu, "deployed")
		if placed:
			log_effect(name + " deploys " + str(placed) + " " + card["name"])
		return
	if k == "Sacrifice":
		var side = ctx["actor"]["side"] if ctx.get("actor") != null else null
		for u in who.filter(func(x): return side != null and x["side"] != side):
			log_effect(u["name"] + " is not a friendly Unit, so it cannot be Sacrificed")
		for u in who.filter(func(x): return side == null or x["side"] == side):
			u["hp"] = 0
			u["down"] = true
			u["_lastDealer"] = null
			log_effect(u["name"] + " is Sacrificed")
		return
	# Handbook 16.0: Execute removes an Enemy below half its Health, never an
	# Elite, a Mini-Boss or a Boss; the kill is the actor's
	if k == "Execute":
		var es = ctx["actor"]["side"] if ctx.get("actor") != null else null
		for u in who:
			if Rules.truthy(u.get("down")):
				continue
			if es != null and u["side"] == es:
				log_effect(u["name"] + " is not an Enemy, so it cannot be Executed")
				continue
			if Keywords._re("elite|miniboss|boss").search(str(u.get("cardType", "")).to_lower()) != null:
				log_effect(u["name"] + " is too strong to be Executed")
				continue
			if Rules.num(u.get("hp"), 0) * 2 >= Rules.num(u.get("hpMax"), 1):
				log_effect(u["name"] + " is not weak enough to be Executed")
				continue
			u["hp"] = 0
			u["down"] = true
			u["_lastDealer"] = ctx["actor"]["id"] if ctx.get("actor") != null and not is_same(ctx["actor"], u) else null
			log_effect(u["name"] + " is Executed")
		return
	if k == "remove":
		var what := str(p["n"] if p["n"] != null else "").strip_edges()
		for u in who:
			if what.to_lower() == "equipment":
				var eqs: Array = u.get("equipment") if u.get("equipment") != null else []
				if eqs.is_empty():
					log_effect(u["name"] + " has no Equipment to remove")
					continue
				var eq = eqs.pop_back()
				if u.get("equipFx") is Array and not u["equipFx"].is_empty():
					u["equipFx"].pop_back()
				# the card itself goes to the Discard Pile here, not when it was played
				if u.get("equipCards") is Array and not u["equipCards"].is_empty():
					b.discard.append(u["equipCards"].pop_back())
				var en = eq.get("name", eq) if eq is Dictionary else eq
				u["mods"] = (u.get("mods") if u.get("mods") != null else []).filter(func(m): return not (m.get("dur") == "while attached" and m.get("source") == en))
				log_effect(u["name"] + " loses " + str(en if Rules.truthy(en) else "a piece of Equipment"))
			else:
				var had := Rules.has_status(u, what)
				u["statuses"] = (u.get("statuses") if u.get("statuses") != null else []).filter(func(s): return str(s["name"]).to_lower() != what.to_lower())
				log_effect((u["name"] + " is cleared of " + what) if had else (u["name"] + " was not " + what))
		return
	# Revision 15.7: a Troop's card comes back from the Discard Pile to the hand.
	# Whoever plays it chooses which (ctx.recover, where it lies in the pile);
	# where nothing was chosen it is the one discarded last.
	if k == "Recover":
		var pile: Array = b.discard if (ctx.get("actor") != null and ctx["actor"]["side"] == "ally") else []
		var at := int(ctx["recover"]) if (ctx.get("recover") is int or ctx.get("recover") is float) else -1
		if at < 0 or at >= pile.size() or not (pile[at] is Dictionary) or pile[at].get("type") != "troop":
			at = -1
			for ri in range(pile.size() - 1, -1, -1):
				if pile[ri] is Dictionary and pile[ri].get("type") == "troop":
					at = ri
					break
		if at < 0:
			log_effect("There is no Troop card in the Discard Pile to Recover")
			return
		var back: Dictionary = pile.pop_at(at)
		b.hand.append(back)
		log_effect(str(back["name"]) + " returns to your hand from the Discard Pile")
		return
	if k == "Flying":
		for u in who:
			u["flying"] = true
		log_effect(_names(who) + " is Flying")
		return
	if k == "Suppressive Fire" or k == "Aura" or k == "Overclock":
		return
	halt(k + " on " + name + " is a keyword the Simulator cannot carry out yet.")


# ---------------------------------------------------------------- running text
## simRunText: an effect's text, sentence by sentence.
func run_text(text, ctx: Dictionary) -> void:
	if str(text if text != null else "").strip_edges() == "":
		return
	for sent in Keywords.sentences(text):
		run_sentence(sent, ctx)
	check_downs()
	apply_continuous()


## simRunSentence
func run_sentence(sent: String, ctx: Dictionary, an = null) -> void:
	var was := source
	source = str(ctx["sourceCard"]) if Rules.truthy(ctx.get("sourceCard")) else ""
	_run_sentence(sent, ctx, an)
	source = was


func _run_sentence(sent: String, ctx: Dictionary, an = null) -> void:
	var src: String = ctx["sourceCard"] if Rules.truthy(ctx.get("sourceCard")) else "An effect"
	# 0.7 (Handbook 15.8): X reads as the number chosen when the card was
	# played, or as the X of the Unit acting. With neither, it has no value.
	if Keywords.uses_x(sent):
		var xv = ctx.get("x")
		if xv == null and ctx.get("actor") is Dictionary:
			xv = ctx["actor"].get("x")
		if xv == null:
			halt_once(ctx, src + ": X has no value here, because the card has no variable cost. It was not carried out.")
			return
		sent = Keywords.fill_x(sent, xv)
		an = Keywords.analyse(sent)
	if an == null:
		an = Keywords.analyse(sent)
	if an["all"].is_empty():
		if ctx.get("event") == null and not Rules.truthy(ctx.get("round")):
			b.say("Not carried out — " + ((str(ctx["sourceCard"]) + " has plain text: ") if Rules.truthy(ctx.get("sourceCard")) else "plain text: ") + sent, "act", {"plain": true})
		return
	if not an["bad"].is_empty():
		halt_once(ctx, src + ": " + "; ".join(an["bad"].map(func(p): return (p["name"] + " has been withdrawn") if p["retired"] else (p["name"] + " is not in the keyword library"))) + ". It was not carried out.")
		return
	var probs := Keywords.problems(an, {"kind": ctx["kind"] if Rules.truthy(ctx.get("kind")) else "action"})
	if not probs.is_empty():
		halt_once(ctx, src + ": " + probs[0] + ". It was not carried out.")
		return
	if an["when"] != null and ctx.get("event") == null:
		return
	if an["check"] != null:
		var ck := check(an["check"], ctx)
		if not ck["ok"]:
			if not Rules.truthy(ctx.get("round")):
				var c: Dictionary = an["check"]
				log_effect(src + ": " + Keywords.render("[[" + c["connector"] + "]] " + (("[[" + c["subject"]["kw"]["name"] + "]] ") if c["subject"] != null else "") + "[[" + c["event"]["kw"]["name"] + ((" " + str(c["event"]["n"])) if Rules.truthy(c["event"]["n"]) else "") + "]]") + " — not met")
			return
		if ck.get("who") != null and ctx.get("subject") == null:
			ctx["subject"] = ck["who"]
	var prev = dealer
	dealer = ctx.get("actor")
	apply_sentence(an, ctx)
	dealer = prev


## simApplySentence
func apply_sentence(an: Dictionary, ctx: Dictionary) -> void:
	var who := resolve_targets(an["targets"], ctx)
	var aura = null
	for p in an["mods"]:
		if p["kw"]["name"] == "Aura":
			aura = p
			break
	if aura != null and ctx.get("actor") != null and Rules.truthy(ctx["actor"].get("pos")):
		var rad = Rules.num(aura["n"], 0)
		rad = rad if Rules.truthy(rad) else 1
		who = who.filter(func(u): return not is_same(u, ctx["actor"]) and Rules.truthy(u.get("pos")) and not Rules.truthy(u.get("down")) and dist(u["pos"], ctx["actor"]["pos"]) <= rad)
	ctx["adjacent"] = an["targets"].any(func(t): return t["part"]["kw"]["name"] == "adjacent")
	var eff: Array = an["effects"] + an["mods"]
	if Rules.truthy(ctx.get("onlyInstant")):
		eff = an["effects"].filter(func(p): return INSTANT.has(p["kw"]["name"]))
	# Revision 16.3: Draw, gain Aether and a Barricade need no Unit to land on
	if who.is_empty() and eff.any(func(p): return not ["Deploy", "Draw", "gain Aether", "Barricade"].has(p["kw"]["name"]) and p["kw"]["cat"] != "modifier"):
		if not Rules.truthy(ctx.get("round")):
			log_effect(str(ctx["sourceCard"] if Rules.truthy(ctx.get("sourceCard")) else "An effect") + " found no target")
		return
	var dur = an["durations"][0] if not an["durations"].is_empty() else null
	if an["effects"].is_empty() and not an["covers"].is_empty() and not Rules.truthy(ctx.get("onlyInstant")):
		var cov: Dictionary = an["covers"][0]
		var turns = 1
		if dur != null:
			var dn = Rules.num(dur["n"], 0)
			turns = dn if Rules.truthy(dn) else (999 if dur["kw"]["name"] == "persistent" else 1)
		var gets: Array = who if not who.is_empty() else ([ctx["actor"]] if ctx.get("actor") != null else [])
		for u in gets:
			Rules.add_status(u, cov["kw"]["name"], turns, ctx["sourceCard"] if Rules.truthy(ctx.get("sourceCard")) else "card")
		log_effect(_names(gets) + " counts as behind " + cov["kw"]["name"] + ((" for " + str(turns) + " turn" + ("" if turns == 1 else "s")) if turns < 999 else ""))
		return
	for p in eff:
		apply_keyword(p, who, ctx, dur)


## simApplyContinuous: what is always on, worked out afresh. Health and Energy
## move by the difference, so nothing is healed twice.
func apply_continuous() -> void:
	for u in b.units:
		u["statuses"] = (u.get("statuses") if u.get("statuses") != null else []).filter(func(st): return not Rules._held(st.get("source")))
		u["mods"] = (u.get("mods") if u.get("mods") != null else []).filter(func(m): return m.get("dur") != "passive")
		u["_pWant"] = {"HP": 0, "NRG": 0}
		u["pFlying"] = false
		u["pLeap"] = 0
		u["pDash"] = 0
	for src in passive_sources():
		var owner: Dictionary = src["owner"]
		if Rules.truthy(owner.get("down")) or not Rules.truthy(owner.get("pos")):
			continue
		for sent in Keywords.sentences(src["text"]):
			var an := Keywords.analyse(sent)
			if an["when"] != null or not an["bad"].is_empty() or not Keywords.problems(an, {"kind": "passive"}).is_empty():
				continue
			var ctx := {"actor": owner, "holder": src["holder"], "sourceCard": src["name"], "kind": "passive"}
			if an["check"] != null:
				var ck := check(an["check"], ctx)
				if not ck["ok"]:
					continue
				ctx["subject"] = ck.get("who")
			var aura = null
			for p in an["mods"]:
				if p["kw"]["name"] == "Aura":
					aura = p
					break
			var who := resolve_targets(an["targets"], ctx)
			if aura != null:
				var rad = Rules.num(aura["n"], 0)
				rad = rad if Rules.truthy(rad) else 1
				who = who.filter(func(u): return not is_same(u, owner) and Rules.truthy(u.get("pos")) and not Rules.truthy(u.get("down")) and dist(u["pos"], owner["pos"]) <= rad)
			var tag: String = ("aura:" + str(owner["id"])) if aura != null else ("passive:" + str(src["pid"]))
			for p in an["effects"]:
				var k: Dictionary = p["kw"]
				if k["cat"] == "status":
					var n = Rules.num(p["n"], null)
					for u in who:
						u["statuses"].append({"name": k["name"], "n": null if Rules.strengthless(k["name"]) else (1 if n == null else n), "turns": 99, "source": tag})
				elif k["cat"] == "stats":
					var amt = _int_of(p["n"], "0-9+-")
					if amt == null:
						continue
					var stat: String = "RANGE" if k["name"] == "Range" else k["name"]
					for u in who:
						if stat == "HP" or stat == "NRG":
							u["_pWant"][stat] += amt
						else:
							u["mods"].append({"stat": stat, "amt": amt, "dur": "passive", "source": src["name"]})
				elif k["name"] == "Flying":
					for u in who:
						u["pFlying"] = true
				# Revision 16.1: always able to Leap, or to Dash each turn
				elif k["name"] == "Leap" or k["name"] == "Dash":
					var pn = Rules.num(p["n"], null)
					var pv: int = 1 if pn == null else maxi(1, int(pn))
					for u in who:
						if k["name"] == "Leap":
							u["pLeap"] = maxi(int(Rules.num(u.get("pLeap"), 0)), pv)
						else:
							u["pDash"] = int(Rules.num(u.get("pDash"), 0)) + pv
			if an["effects"].is_empty():
				for cv in an["covers"]:
					for u in who:
						u["statuses"].append({"name": cv["kw"]["name"], "n": null, "turns": 99, "source": tag})
	for u in b.units:
		if u.get("pMods") == null:
			u["pMods"] = {}
		for st in ["HP", "NRG"]:
			var want: int = u["_pWant"][st]
			var d: int = want - int(Rules.num(u["pMods"].get(st), 0))
			if d == 0:
				continue
			if st == "HP":
				u["hpMax"] = maxi(1, u["hpMax"] + d)
				u["hp"] = u["hp"] + d if (d > 0 and not Rules.truthy(u.get("down"))) else mini(u["hp"], u["hpMax"])
			else:
				u["nrgMax"] = maxi(0, int(Rules.num(u.get("nrgMax"), 0)) + d)
				u["nrg"] = int(Rules.num(u.get("nrg"), 0)) + d if d > 0 else mini(int(Rules.num(u.get("nrg"), 0)), u["nrgMax"])
			u["pMods"][st] = want
		u.erase("_pWant")


## simRoundPassives: an always-on Passive's one-off effects happen once a round.
func round_passives() -> void:
	for src in passive_sources():
		var owner: Dictionary = src["owner"]
		if Rules.truthy(owner.get("down")) or not Rules.truthy(owner.get("pos")):
			continue
		for sent in Keywords.sentences(src["text"]):
			var an := Keywords.analyse(sent)
			if an["when"] != null or not an["effects"].any(func(p): return INSTANT.has(p["kw"]["name"])):
				continue
			run_sentence(sent, {"actor": owner, "holder": src["holder"], "sourceCard": src["name"], "kind": "passive",
				"round": true, "onlyInstant": true, "pid": src["pid"]}, an)


## simCheckDowns: anything at 0 Health is down, and its going down is an event.
func check_downs(no_flush := false) -> void:
	for u in b.units:
		if not Rules.truthy(u.get("down")) and Rules.truthy(u.get("pos")) and (u.get("hp") is int or u.get("hp") is float) and u["hp"] <= 0:
			u["hp"] = 0
			u["down"] = true
		if Rules.truthy(u.get("down")) and not Rules.truthy(u.get("_downFired")):
			u["_downFired"] = true
			discard_of(u)
			b.salvage(u)
			var by = b.unit_by_id(u["_lastDealer"]) if Rules.truthy(u.get("_lastDealer")) else null
			emit("is Incapacitated", u, by)
			if by != null and by["side"] != u["side"]:
				emit("kills an enemy", by, u)
	if not no_flush:
		flush()


## simDiscardOf (Handbook, Sections 3 and 6): a Troop's card stays with its
## Troop, and Equipment with the Unit wearing it. Each reaches the Discard
## Pile when it leaves the Battlefield, which is when a Recover can bring it back.
func discard_of(u: Dictionary) -> void:
	if u.get("side") != "ally":
		return
	for c in (u["equipCards"] if u.get("equipCards") is Array else []):
		b.discard.append(c)
	u["equipCards"] = []
	if u.get("card") is Dictionary:
		b.discard.append(u["card"])
		u["card"] = null


## simRunTrigger
func run_trigger(u: Dictionary, trigger: String) -> void:
	if trigger == "deployed":
		emit("is deployed", u)
	elif trigger == "incapacitated":
		emit("is Incapacitated", u)
	flush()


# ---------------------------------------------------------------- hazards
func hazard_at(h: Vector2i) -> Variant:
	return b.floor_data.hazards.get(h)


## simHazardHit: a hazard bites a Unit on it.
func hazard_hit(u: Dictionary, why: String) -> bool:
	var h = hazard_at(Battle.tile_of(u)) if Rules.truthy(u.get("pos")) else null
	if h == null or Rules.truthy(u.get("down")):
		return false
	var bits := []
	if Rules.truthy(h.get("damage")):
		Rules.hit(u, h["damage"])
		float_own(u, "-%s HP" % str(h["damage"]), "damage")
		bits.append(str(h["damage"]) + " damage")
	if Rules.truthy(h.get("keyword")):
		Rules.add_status(u, h["keyword"], 1, "hazard")
		float_own(u, str(h["keyword"]), "debuff")
		bits.append(h["keyword"])
	if bits.is_empty():
		return false
	b.say(u["name"] + " " + why + " " + str(h["text"] if Rules.truthy(h.get("text")) else "a hazard") + ": " + " and ".join(bits) + ((" — " + u["name"] + " is down") if Rules.truthy(u.get("down")) else ""))
	return true


func hazard_end_of_turn() -> void:
	for u in b.units:
		if not Rules.truthy(u.get("down")):
			hazard_hit(u, "ends its turn on")


# ---------------------------------------------------------------- holding fire
## simHoldable: the Actions with Suppressive Fire a Unit could hold fire with now.
func holdable(u: Dictionary) -> Array:
	if Rules.truthy(u.get("down")) or b.has_moved(u):
		return []
	return (u.get("actions") if u.get("actions") != null else []).filter(func(a):
		return suppressive(a) and Rules.can_afford(u, a) and b.aether_ok(u, a))


## (0.16) Whether an Action has Suppressive Fire, so it could be held, whatever
## the Unit has to pay for it now.
static func suppressive(a: Dictionary) -> bool:
	if a.get("tag") == "Passive" or a.get("tag") == "Aura" or not Rules.truthy(a.get("text")):
		return false
	return Keywords.parse(a["text"]).any(func(p): return p["type"] == "kw" and p["kw"] != null and p["kw"]["name"] == "Suppressive Fire")


## simHoldFire: pays the Action's Energy now, and shoots the first Enemy that
## moves within range and line of sight during the Enemy turn.
func hold_fire(u: Dictionary, action_name: String) -> bool:
	var a = null
	for x in holdable(u):
		if x["name"] == action_name:
			a = x
			break
	if a == null:
		return false
	if a.get("aetherX") is Dictionary:
		Battle.set_action_x(a, 1)          # a held shot is made at X = 1
	u["nrg"] = maxi(0, int(u["nrg"]) - int(Rules.num(a.get("cost"), 0)))
	b.pay_aether(u, a)
	u["holding"] = {"name": a["name"], "action": a}
	b.say(u["name"] + " holds fire with " + a["name"] + ".")
	return true


## simReactTo: a held shot, as an Enemy moves into its reach.
func react_to(enemy: Dictionary) -> void:
	if not Rules.truthy(enemy.get("pos")) or Rules.truthy(enemy.get("down")):
		return
	for h in b.units.duplicate():
		if h.get("holding") == null or Rules.truthy(h.get("down")) or not Rules.truthy(h.get("pos")) or h["side"] == enemy["side"]:
			continue
		if Rules.effective(h)["cannotAct"]:
			continue              # Stunned since it took aim: it can't take the shot
		var a: Dictionary = h["holding"]["action"]
		if not b.can_reach(h, a, enemy, true):
			continue
		h["holding"] = null
		var shot := 0
		while shot < burst_of(a) and not Rules.truthy(enemy.get("down")) and b.can_reach(h, a, enemy, true):
			var d = Rules.hex_distance(h["pos"], enemy["pos"])
			var res := Rules.resolve_attack(h, a, enemy, {"dice": b.dice, "distance": d, "reaction": true, "cover": b.cover_for(enemy, h)})
			var bt: Dictionary = b._beat({"type": "react", "unit": h["id"], "target": enemy["id"], "action": a, "res": res})
			emit("attacks", h, enemy)
			emit("is attacked", enemy, h)
			var prev = dealer
			dealer = h
			var line: String = h["name"] + " reacts with " + a["name"] + " as " + enemy["name"] + " moves: "
			if Rules.truthy(res["damage"]):
				Rules.hit(enemy, res["damage"], true)   # Revision 16.3: Hardened is in the damage already
				line += str(res["damage"]) + " damage" + ((" — " + enemy["name"] + " is down") if Rules.truthy(enemy.get("down")) else "")
			elif res["hit"] == false:
				line += "missed"
			elif res["penetrated"] == false:
				line += "hit but did not Penetrate"
			else:
				line += "no effect"
			bt["line"] = line
			b.say(line, "act", {"rolls": res["rolls"]})
			if Rules.truthy(a.get("text")) and res["hit"] != false and res["penetrated"] != false:
				run_text(a["text"], {"actor": h, "target": enemy, "damaged": Rules.num(res["damage"], 0) > 0, "killed": Rules.truthy(enemy.get("down")),
					"damage": res["damage"] if Rules.truthy(res["damage"]) else 0, "sourceCard": a["name"]})
			dealer = prev
			shot += 1
	check_downs()


## simLapseHolds: a hold nobody walked into ends with the round.
func lapse_holds() -> void:
	for u in b.units:
		if u.get("holding") != null:
			b.say(u["name"] + "'s hold lapses; nothing came into range")
			u["holding"] = null


# ---------------------------------------------------------------- Burst and area
## simBurstOf: how many attacks an Action makes for one payment.
static func burst_of(action) -> int:
	var m := Keywords._re("(?i)\\[\\[\\s*Burst\\s+(\\d+)\\s*\\]\\]").search(str(action.get("text") if action is Dictionary and action.get("text") != null else ""))
	return maxi(1, int(Rules.num(m.get_string(1), 1))) if m != null else 1


## simBurstPool: who a Burst's next attack could go to.
func burst_pool(attacker: Dictionary, action: Dictionary) -> Array:
	var support := Battle.role_of(action) == "support"
	return b.units.filter(func(f): return not Rules.truthy(f.get("down")) and Rules.truthy(f.get("pos")) and (
		(f["side"] == attacker["side"] and not is_same(f, attacker)) if support else f["side"] != attacker["side"]) and b.can_reach(attacker, action, f, true))


## simHurtsOwnSide: whether an Action's AoE would catch a Unit on its own side.
func hurts_own_side(actor: Dictionary, a: Dictionary, target) -> bool:
	if not Rules.truthy(a.get("text")) or target == null or not Rules.truthy(target.get("pos")):
		return false
	# 14.12: a Line or a Cone running through one of its own counts too
	for p in Keywords.parse(a["text"]):
		if p["type"] == "kw" and p["kw"] != null and (p["kw"]["name"] == "Line" or p["kw"]["name"] == "Cone") and Rules.truthy(actor.get("pos")):
			var sn = Rules.num(p["n"], 0)
			for t in shape_tiles(p["kw"]["name"], actor["pos"], target["pos"], int(sn) if Rules.truthy(sn) else 1):
				var su = b.unit_at(Vector2i(t["q"], t["r"]))
				if su != null and not is_same(su, target) and not is_same(su, actor) and su["side"] == actor["side"]:
					return true
			break
	var aoe = null
	for p in Keywords.parse(a["text"]):
		if p["type"] == "kw" and p["kw"] != null and p["kw"]["name"] == "AoE":
			aoe = p
			break
	if aoe == null:
		return false
	var rad = Rules.num(aoe["n"], 0)
	rad = rad if Rules.truthy(rad) else 1
	return b.units.any(func(u): return not is_same(u, target) and not Rules.truthy(u.get("down")) and Rules.truthy(u.get("pos")) and u["side"] == actor["side"] and Rules.hex_distance(u["pos"], target["pos"]) <= rad)


## Revision 16.3: "Full" or "Half" when an Action's text puts down a Barricade, else "".
static func barricade_of(a: Dictionary) -> String:
	for p in Keywords.parse(a.get("text", "")):
		if p["type"] == "kw" and p["kw"] != null and p["kw"]["name"] == "Barricade":
			var w := str(p["n"] if p["n"] != null else "").strip_edges()
			return "Full" if w.to_lower() == "full" else ("Half" if w.to_lower() == "half" else "")
	return ""


## The AoE radius an Action's text gives, or 0.
static func aoe_of(a: Dictionary) -> int:
	for p in Keywords.parse(a.get("text", "")):
		if p["type"] == "kw" and p["kw"] != null and p["kw"]["name"] == "AoE":
			var r = Rules.num(p["n"], 0)
			return r if Rules.truthy(r) else 1
	return 0


## (The game's own.) Whether an Action's text reaches past its target: an AoE,
## or an effect on "all enemies / allies / units within" some distance.
static func has_area(a: Dictionary) -> bool:
	for p in Keywords.parse(a.get("text") if a.get("text") != null else ""):
		if p["type"] == "kw" and p["kw"] != null and (p["kw"]["name"] == "AoE" or p["kw"]["name"] == "Line" or p["kw"]["name"] == "Cone" or Keywords._re("^all (enemies|allies|units) within$").search(p["kw"]["name"]) != null):
			return true
	return false


## (The game's own.) Who an area Action would take in besides its target if
## used on it now, worked out by the same reading of the text that carries it
## out: {radius, caught, own}. An AoE catches everyone within its radius of the
## target, either side, the attacker too; "all enemies within 2" only those it names.
func area_preview(actor: Dictionary, a: Dictionary, target: Dictionary) -> Dictionary:
	var caught := []
	var radius := 0
	var tiles := []           # 0.23: the tiles a Line or a Cone covers, to light them
	var add := func(u) -> void:
		if u == null or is_same(u, target) or Rules.truthy(u.get("down")) or not Rules.truthy(u.get("pos")):
			return
		if not caught.any(func(x): return is_same(x, u)):
			caught.append(u)
	for sent in Keywords.sentences(a.get("text")):
		var an := Keywords.analyse(sent)
		if an["when"] != null or not an["bad"].is_empty():
			continue
		for p in an["all"]:
			if p["kw"] != null and p["kw"]["name"] == "AoE":
				var rad = Rules.num(p["n"], 0)
				rad = int(rad) if Rules.truthy(rad) else 1
				radius = maxi(radius, rad)
				for u in b.units:
					if Rules.truthy(u.get("pos")) and dist(u["pos"], target["pos"]) <= rad:
						add.call(u)
			# Revision 16.3: a Line or a Cone, from the attacker toward the target
			if p["kw"] != null and (p["kw"]["name"] == "Line" or p["kw"]["name"] == "Cone") and Rules.truthy(actor.get("pos")):
				var sn = Rules.num(p["n"], 0)
				for t in shape_tiles(p["kw"]["name"], actor["pos"], target["pos"], int(sn) if Rules.truthy(sn) else 1):
					tiles.append(Vector2i(t["q"], t["r"]))
					var su = b.unit_at(Vector2i(t["q"], t["r"]))
					if not is_same(su, actor):
						add.call(su)
		var wide := false
		for t in an["targets"]:
			if Keywords._re("^all (enemies|allies|units) within$").search(t["part"]["kw"]["name"]) != null:
				wide = true
				radius = maxi(radius, int(Rules.num(t["part"]["n"], 0)))
		if wide:
			for u in resolve_targets(an["targets"], {"actor": actor, "target": target, "sourceCard": a.get("name"), "kind": "action"}):
				add.call(u)
	return {"radius": radius, "tiles": tiles, "caught": caught, "own": caught.filter(func(u): return u["side"] == actor["side"])}


## simActionNarrow: an Action written "target Sniper enemy" can only be aimed at one.
static func action_narrow(a: Dictionary) -> Array:
	if not Rules.truthy(a.get("text")):
		return []
	for sent in Keywords.sentences(a["text"]):
		var an := Keywords.analyse(sent)
		if an["check"] != null or an["when"] != null:
			continue
		for t in an["targets"]:
			if Keywords._re("^target (enemy|ally)$").search(t["part"]["kw"]["name"]) != null:
				return t["narrow"]
	return []
