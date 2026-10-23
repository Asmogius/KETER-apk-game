## A deployment: leaving the dock, and coming home or not. (The Companion's
## deploy.js.)
##
## A deployment brings one Strike Team. Its Troops must be designs from your
## Workshop that fit their chassis; every copy in the Deck costs Troop parts,
## paid before leaving and spent whatever happens. The built-in starter design
## comes with a few free copies each time. Everything else in the Deck comes
## along free. Pre-built copies bought at the dock join it, on top of its
## Deck, and the Consumables and Prototypes packed for it must be owned at the
## dock (0.10): a used Consumable is gone, the rest comes home, and a wipe
## loses all of it. Out on the map it
## walks tile by tile. Each step may spring an ambush, likelier the higher the
## tile's Skull Level. A POI is a run of floors fought in order, with a reward
## at the end; the only way out early is a Hero reaching an Emergency Exit. A
## Hero who goes down sits out the rest of the deployment; a Troop that goes
## down is gone for the rest of it, and so is a Consumable that was used. A
## lost fight can be tried again with the Heroes still standing; with none
## left, it is a wipe.
##
## Loot rides in the haul. It reaches the stockpile only when the team walks
## back onto the dock. A wipe loses it.
##
## Proved to decide as deploy.js decides, roll for roll (tests/world_diff.gd).
class_name Deployment
extends RefCounted

const LOG_MOST := 60
const HISTORY_MOST := 30

var world: World
var progress: Progress
var loot: Loot                # the stream every roll comes from, and the loot tables
var roster: Roster = null     # the cards (to know a Troop from a Command); may be null in tests
## The designs. With none (some tests of the map alone), leaving is free, as it was in 0.8.
var workshop: Workshop = null
## The dock (0.10): what you own to pack, pre-built copies, the free starter
## copies, the scanner, and what happens at the end. With none, a team packs
## its own lists, as in 0.9.
var dock: Dock = null

## The deployment in progress (active), or the last one (ended), or null.
var s = null
## What is kept at the dock: a bag of shards and components.
var stock := Loot.bag()
## The deployments that have ended, newest first.
var history: Array = []


func _init(w: World, p: Progress, stream: Loot, r: Roster = null) -> void:
	world = w
	progress = p
	loot = stream
	roster = r


# ---------------------------------------------------------------- where things stand
func cur() -> Variant:
	return s if s is Dictionary and Rules.truthy(s.get("active")) else null


func active() -> bool:
	return cur() != null


## The one that ended last, if none is out.
func last() -> Variant:
	return s if s is Dictionary and not Rules.truthy(s.get("active")) else null


static func _now() -> String:
	return Time.get_datetime_string_from_system(true) + "Z"


func note(text: String) -> void:
	var c = cur() if cur() != null else s
	if c == null:
		return
	if not (c.get("log") is Array):
		c["log"] = []
	c["log"].push_front({"t": _now(), "text": text})
	if c["log"].size() > LOG_MOST:
		c["log"].resize(LOG_MOST)


func _push_history(entry: Dictionary) -> void:
	history.push_front(entry)
	if history.size() > HISTORY_MOST:
		history.resize(HISTORY_MOST)


# ---------------------------------------------------------------- leaving
## How many free copies of the starter each deployment brings.
func starter_free() -> int:
	if dock != null:
		return dock.starter_free()
	var n = Rules.num(world.tables.get("starterFree"), 0) if world != null else 0
	return maxi(0, int(n) if Rules.truthy(n) else 0)


## How far a standing team sees what the tiles hold (the dock's scanner).
func _scan() -> int:
	return dock.scan_range() if dock != null else 1


## What leaving costs, worked out as deploy.js's plan does it:
## {ok, fits, afford, reasons, heroes, lines, parts, other, busy}. The reasons
## are deploy.js's own words; reasons_against says them as the dock does.
## lines: a line for each design, {id, name, copies, free, each, cost, starter}.
func plan(team: Dictionary, pack = null) -> Dictionary:
	var reasons := []
	var heroes := []
	for h in team.get("heroes", []):
		var hc = roster.card_named(str(h)) if roster != null else {"name": str(h)}
		if hc != null:
			heroes.append(hc["name"])
		else:
			reasons.append("a Hero in it is missing (%s)" % str(h))
	if team.get("heroes", []).is_empty():
		reasons.append("it has no Hero")
	var per := {}
	var per_order := []
	var forge := {}
	var forge_order := []
	var other := 0
	var deck: Dictionary = team.get("deck", {})
	for n in deck:
		for i in StrikeTeams.copies(team, str(n)):
			var c = roster.card_named(str(n)) if roster != null else null
			if c == null:
				reasons.append("a card in its Deck is missing (%s)" % str(n))
				continue
			if Roster.type_of(c) == "troop":
				if c.get("_src") != "workshop":
					var key := str(c["name"]) + ("|design" if c.get("_src") == "design" else ("|prebuilt" if c.get("_src") == "prebuilt" else ""))
					if not forge.has(key):
						forge[key] = 0
						forge_order.append(key)
					forge[key] += 1
					continue
				var id := str(c["_design"])
				if not per.has(id):
					per[id] = {"id": id, "name": c["name"], "copies": 0}
					per_order.append(id)
				per[id]["copies"] += 1
			else:
				other += 1
	for key in forge_order:
		var nm: String = key.trim_suffix("|design").trim_suffix("|prebuilt")
		var times := (" (×%d)" % forge[key]) if forge[key] > 1 else ""
		if key.ends_with("|prebuilt"):
			reasons.append("%s is a pre-built Troop%s: its copies are bought at the Exchange, and join the next deployment" % [nm, times])
		elif key.ends_with("|design"):
			reasons.append("%s is a design from your export%s: copy it into your Workshop to take it out" % [nm, times])
		else:
			reasons.append("%s is a Forge Troop%s: Troops come only from the Workshop" % [nm, times])
	var parts := [0, 0, 0, 0, 0, 0]
	var lines := []
	for id in per_order:
		var ln: Dictionary = per[id]
		var d = workshop.get_design(id) if workshop != null else null
		if d == null:
			reasons.append("%s is no longer in the Workshop" % ln["name"])
			continue
		var chk := workshop.check(d)
		if not chk["ok"]:
			reasons.append("%s does not fit its chassis (%s)" % [ln["name"], "; ".join(chk["reasons"])])
		var each: Array = workshop.cost(d)["parts"]
		var free: int = mini(ln["copies"], starter_free()) if Rules.truthy(d.get("starter")) else 0
		var paid: int = ln["copies"] - free
		var cost := each.map(func(n): return int(n) * paid)
		for r in 6:
			parts[r] += cost[r]
		lines.append({"id": id, "name": ln["name"], "copies": ln["copies"], "free": free, "each": each, "cost": cost, "starter": Rules.truthy(d.get("starter"))})
	var have: Array = Loot.norm(stock)["parts"]["troop"]
	var afford := true
	for r in 6:
		if have[r] < parts[r]:
			afford = false
	# 0.10: pre-built copies bought at the dock go too; packed Consumables and Prototypes must be owned
	var pre := []
	var packed := []
	if dock != null:
		var wait := dock.waiting()
		for id in wait:
			var d = workshop.get_design(id) if workshop != null else null
			if d != null and int(wait[id]) > 0:
				pre.append({"id": str(id), "name": d["name"], "copies": int(wait[id])})
		var pk: Dictionary = pack if pack is Dictionary else {}
		for nm in pk:
			var n := Dock._pi(pk[nm])
			if n == 0:
				continue
			var own := dock.owned(str(nm))
			if n > own:
				reasons.append("only %d %s to pack" % [own, str(nm)])
			else:
				packed.append({"name": str(nm), "n": n, "kind": dock.item_kind(str(nm))})
	return {"ok": reasons.is_empty() and afford and not active(), "fits": reasons.is_empty(), "afford": afford, "reasons": reasons, "heroes": heroes,
		"lines": lines, "parts": parts, "other": other, "busy": active(), "pre": pre, "packed": packed}


## What a team packs to begin with (0.10): what its own Consumables and
## Prototypes tabs ask for, as far as the dock holds them.
func default_pack(team: Dictionary) -> Dictionary:
	var out := {}
	if dock == null:
		return out
	for k in team.get("consumables", {}):
		var n := mini(Dock._pi(team["consumables"][k]), dock.owned(str(k)))
		if n > 0:
			out[str(k)] = n
	for k in team.get("protos", []):
		if dock.owned(str(k)) > 0 and not out.has(str(k)):
			out[str(k)] = 1
	return out


## Why a Strike Team can't leave, in a list of sentences (empty: it can).
func reasons_against(team: Dictionary, pack = null) -> Array:
	var out := []
	if active():
		out.append("A Strike Team is already out. Bring it home first.")
	if not world.exists():
		out.append("This export has no World Map. Export again from Companion 13.1 or later.")
	if team.get("heroes", []).is_empty():
		out.append("It has no Hero.")
	elif roster != null and StrikeTeams.heroes(team, roster).is_empty():
		out.append("None of its Heroes is in this export.")
	if world.floors.is_empty():
		out.append("This export has no floors to fight on. Make one in the Companion's POI Sandbox.")
	if workshop != null:
		var p := plan(team, pack)
		for r in p["reasons"]:
			# (the Heroes are said above, the game's own way)
			if str(r).begins_with("a Hero in it is missing") or r == "it has no Hero":
				continue
			out.append(str(r).left(1).to_upper() + str(r).substr(1) + ".")
		if p["fits"] and not p["afford"]:
			out.append("The stockpile can't pay for its copies: they cost %s, and it holds %s." % [Workshop.cost_text(p["parts"]), Workshop.cost_text(Loot.norm(stock)["parts"]["troop"])])
	return out


## A copy of a team that can leave: its Troops that aren't your designs taken
## out, and the starter's free copies put in if it has none. (The dock's Field copy.)
func field_copy(team: Dictionary, name: String) -> Dictionary:
	var t := StrikeTeams.copy_of(team, name)
	for n in team.get("deck", {}).keys():
		var c = roster.card_named(str(n)) if roster != null else null
		if c != null and Roster.type_of(c) == "troop" and c.get("_src") != "workshop":
			t["deck"].erase(n)
	if workshop != null:
		var starter_name := str(Workshop.STARTER["name"])
		if StrikeTeams.copies(t, starter_name) == 0 and starter_free() > 0:
			t["deck"][starter_name] = starter_free()
	return t


## Whether a team needs a Field copy to leave: Troops in its Deck that aren't your designs.
func needs_field_copy(team: Dictionary) -> bool:
	for n in team.get("deck", {}):
		var c = roster.card_named(str(n)) if roster != null else null
		if c != null and Roster.type_of(c) == "troop" and c.get("_src") != "workshop" and StrikeTeams.copies(team, str(n)) > 0:
			return true
	return false


## The Strike Team leaves the dock. Returns {ok, state} or {ok: false, reasons}.
func start(team: Dictionary, pack = null) -> Dictionary:
	var why := reasons_against(team, pack)
	if not why.is_empty():
		return {"ok": false, "reasons": why}
	var t: Dictionary = team.duplicate(true)
	# the copies are paid before leaving, and spent whatever happens
	var p := plan(team, pack) if workshop != null else {"parts": [0, 0, 0, 0, 0, 0], "lines": [], "pre": [], "packed": []}
	var bag := Loot.norm(stock)
	for r in 6:
		bag["parts"]["troop"][r] -= int(p["parts"][r])
	stock = bag
	var copies := {}
	for l in p["lines"]:
		copies[l["id"]] = l["copies"]
	var packed := {}
	var protos = t.get("protos", []).duplicate()
	var pre := {}
	if dock != null:
		# pre-built copies leave the dock with the team; packed items ride with it
		for x in p.get("pre", []):
			pre[x["id"]] = x["copies"]
		dock.inv["pre"] = {}
		protos = {}
		for x in p.get("packed", []):
			dock.add_card(x["name"], -int(x["n"]))
			if x["kind"] == "prototype":
				protos[x["name"]] = x["n"]
			else:
				packed[x["name"]] = x["n"]
	else:
		for k in t.get("consumables", {}):
			var n = Rules.num(t["consumables"][k], 0)
			if Rules.truthy(n) and int(n) > 0 and (roster == null or roster.card_named(str(k)) != null):
				packed[str(k)] = int(n)
	s = {"active": true, "n": int(world.state["completed"]) + 1, "started": _now(), "team": t, "heroesOut": [], "lost": {},
		"pack": {"cons": packed, "protos": protos}, "pos": world.dock(), "haul": Loot.bag(), "items": [],
		"activity": null, "log": [], "steps": 0, "fights": 0, "known0": world.known_count(), "maxSkull": 0, "kills": [],
		"copies": copies, "lines": p["lines"], "paid": p["parts"], "pre": pre, "preLines": p.get("pre", [])}
	note("Left the dock with %s." % str(t.get("name", "a Strike Team")))
	world.stand(s["pos"], _scan())
	return {"ok": true, "state": s}


## A design whose copies are out waits at the dock until they come home.
func locked_design(id) -> bool:
	var c = cur()
	return c != null and c.get("copies") is Dictionary and Rules.truthy(c["copies"].get(str(id)))


## A Strike Team that is out waits until it comes home: it can't be changed.
func locked_team(team) -> bool:
	var c = cur()
	return c != null and team is Dictionary and str(c["team"].get("name")) == str(team.get("name"))


# ---------------------------------------------------------------- the team as it stands
## The Heroes still with the team (names).
func hero_names() -> Array:
	var c = cur()
	if c == null:
		return []
	return c["team"].get("heroes", []).filter(func(h): return not c["heroesOut"].has(h))


## How many copies of a Troop the Deck still holds on this deployment.
func copies_left(name: String) -> int:
	var c = cur()
	if c == null:
		return 0
	var lost = Rules.num(c["lost"].get(name), 0)
	return maxi(0, StrikeTeams.copies(c["team"], name) + pre_copies(name) - (int(lost) if Rules.truthy(lost) else 0))


## The pre-built copies of this name that went out with it (0.10).
func pre_copies(name: String) -> int:
	var c = cur()
	var n := 0
	for l in (c.get("preLines", []) if c != null and c.get("preLines") is Array else []):
		if str(l.get("name")) == name:
			n += int(l.get("copies", 0))
	return n


## The Strike Team as it stands now: the Heroes still up, the Deck less the
## Troops that fell, the Consumables not yet used.
func team_now() -> Variant:
	var c = cur()
	if c == null:
		return null
	var t: Dictionary = c["team"].duplicate(true)
	t["heroes"] = hero_names()
	var acts := {}
	for h in t["heroes"]:
		if c["team"].get("actions", {}).has(h):
			acts[h] = c["team"]["actions"][h].duplicate()
	t["actions"] = acts
	# pre-built copies ride on top of the Deck
	for l in (c.get("preLines", []) if c.get("preLines") is Array else []):
		t["deck"][str(l["name"])] = int(t["deck"].get(str(l["name"]), 0)) + int(l["copies"])
	for name in c["lost"]:
		if t["deck"].has(name):
			StrikeTeams.set_copies(t, str(name), copies_left(str(name)))
	t["consumables"] = c["pack"]["cons"].duplicate()
	var pp = c["pack"]["protos"]
	t["protos"] = pp.keys().filter(func(k): return int(pp[k]) > 0) if pp is Dictionary else pp.duplicate()
	t["deployed"] = true
	return t


# ---------------------------------------------------------------- walking
## One step, to a tile beside the team. Returns {moved, why} or
## {moved, pos, home, content, ambush, tileAmbush}.
func step_to(k) -> Dictionary:
	var c = cur()
	if c == null:
		return {"moved": false, "why": "No deployment"}
	if c["activity"] != null:
		return {"moved": false, "why": "Finish what you started here first"}
	var to := str(k)
	if not World.neighbours(c["pos"]).has(to) or not world.is_open(to):
		return {"moved": false, "why": "Not a step away"}
	c["pos"] = to
	c["steps"] = int(c["steps"]) + 1
	c["maxSkull"] = maxi(int(c.get("maxSkull", 0)), world.skull_of(to))
	world.stand(to, _scan())
	var home := to == world.dock()
	var content = world.content_at(to) if world.available(to) else null
	var out := {"moved": true, "pos": to, "home": home, "content": content, "ambush": false}
	if content != null and content["kind"] == "ambush":
		out["ambush"] = true
		out["tileAmbush"] = true
		return out
	if not home and loot.rnd() * 100.0 < world.ambush_chance(to):
		out["ambush"] = true
		out["content"] = null
	return out


# ---------------------------------------------------------------- fights
## A POI or an ambush begins: its floors are drawn. Returns what the first
## fight needs (see spec), or null with no floor to fight on.
func begin(kind: String, k, opts: Dictionary = {}) -> Variant:
	var c = cur()
	if c == null:
		return null
	var tile := str(k)
	var d := world.district_of(tile)
	var sk := world.skull_of(tile)
	var content = world.content_at(tile)
	var fl := []
	if kind == "poi":
		if content != null and content.get("unique") is Dictionary:
			var listed = content["unique"].get("floors")
			fl = (listed if listed is Array else []).filter(func(f): return world.floor_named(f) != null)
			if fl.is_empty():
				fl = world.draw_floors(d, sk, world.floor_count(sk), false, tile)
		else:
			fl = world.draw_floors(d, sk, world.floor_count(sk), false, tile)
	else:
		fl = world.draw_floors(d, sk, 1, true, tile)
	if fl.is_empty():
		return null
	var poi_name: String = str(content["name"]) if content != null and Rules.truthy(content.get("name")) else "POI"
	c["activity"] = {"kind": kind, "tile": tile, "district": d, "skull": sk, "floors": fl, "index": 0, "name": poi_name if kind == "poi" else "Ambush",
		"type": (str(content["type"]) if content != null and Rules.truthy(content.get("type")) else "") if kind == "poi" else "",
		"unique": content["unique"].get("id") if content != null and content.get("unique") is Dictionary else null,
		"tileAmbush": Rules.truthy(opts.get("tileAmbush")), "fromEvent": Rules.truthy(opts.get("fromEvent"))}
	if kind == "poi":
		note("Entered %s (%d floor%s)." % [c["activity"]["name"], fl.size(), "" if fl.size() == 1 else "s"])
	else:
		note("Ambushed%s." % (" after an event" if Rules.truthy(opts.get("fromEvent")) else ""))
	return spec()


func enter_poi(k) -> Variant:
	return begin("poi", k)


func ambush(k, opts: Dictionary = {}) -> Variant:
	return begin("ambush", k, opts)


## The fight that is waiting: {floor, district, skull, kind, index, count,
## name, type, tile, n, pending}, or null.
func spec() -> Variant:
	var c = cur()
	if c == null or c["activity"] == null:
		return null
	var a: Dictionary = c["activity"]
	return {"floor": a["floors"][a["index"]], "district": a["district"], "skull": a["skull"], "kind": a["kind"], "index": a["index"], "count": a["floors"].size(),
		"name": a["name"], "type": a["type"], "tile": a["tile"], "n": c["n"], "pending": c["items"].duplicate()}


## A fight is over. res: {winner ("ally", "escape", anything else is lost),
## haul, reward, items, heroesDown [names], troopsLost [card names],
## consUsed [names], kills [{name, skull}]}. Returns what comes next:
## {next: "map" | "floor" | "retry" | "wipe", ...}.
func fight_over(res: Dictionary) -> Dictionary:
	var c = cur()
	if c == null or c["activity"] == null:
		return {"next": "map"}
	var a: Dictionary = c["activity"]
	c["fights"] = int(c["fights"]) + 1
	# the fallen: Heroes sit out, Troops are gone
	for nm in res.get("heroesDown", []):
		if c["team"].get("heroes", []).has(nm) and not c["heroesOut"].has(nm):
			c["heroesOut"].append(nm)
			note("%s is down and sits out the rest of the deployment." % nm)
	for nm in res.get("troopsLost", []):
		# a copy out of the Deck, while it has one: a Troop a card put down is nobody's copy
		var card = roster.card_named(str(nm)) if roster != null else null
		if roster != null and (card == null or Roster.type_of(card) != "troop"):
			continue
		if copies_left(str(nm)) > 0:
			c["lost"][str(nm)] = int(c["lost"].get(str(nm), 0)) + 1
			note("A copy of %s is lost." % nm)
	# a Consumable used is used, whoever won
	for nm in res.get("consUsed", []):
		var pk: Dictionary = c["pack"]["cons"]
		if int(pk.get(str(nm), 0)) > 0:
			pk[str(nm)] = int(pk[str(nm)]) - 1
			if pk[str(nm)] <= 0:
				pk.erase(str(nm))
	var out := {"next": "map", "kind": a["kind"], "name": a["name"]}
	var winner = res.get("winner")
	if winner == "ally" or winner == "escape":
		for x in res.get("kills", []):
			if x is Dictionary and Rules.truthy(x.get("name")):
				var ks = Rules.num(x.get("skull"), 0)
				c["kills"].append({"name": x["name"], "skull": int(ks) if Rules.truthy(ks) else a["skull"]})
		var gained := Loot.add(res.get("haul"), res.get("reward") if winner == "ally" else null)
		c["haul"] = Loot.add(c["haul"], gained)
		var its := []
		for it in res.get("items", []):
			if progress.eligible(it, c["items"]):
				c["items"].append(it)
				its.append(it)
				progress.name(it)
		out["gained"] = gained
		out["items"] = its
		if winner == "escape":
			world.clear(a["tile"], int(c["n"]))
			c["activity"] = null
			note("Escaped %s through the Emergency Exit." % a["name"])
			out["escaped"] = true
		elif a["kind"] == "poi" and int(a["index"]) + 1 < a["floors"].size():
			a["index"] = int(a["index"]) + 1
			out["next"] = "floor"
			out["floor"] = a["index"] + 1
			out["count"] = a["floors"].size()
			note("Floor %d of %d cleared." % [a["index"], a["floors"].size()])
		elif a["kind"] == "poi":
			var fin := final_reward(a)
			c["haul"] = Loot.add(c["haul"], fin["bag"])
			for it in fin["items"]:
				c["items"].append(it)
				progress.name(it)
			world.clear(a["tile"], int(c["n"]))
			c["activity"] = null
			out["poiDone"] = true
			out["final"] = fin
			note("%s cleared." % a["name"])
		else:
			if Rules.truthy(a.get("tileAmbush")):
				world.clear(a["tile"], int(c["n"]))
			c["activity"] = null
			note("The ambush is beaten.")
		return out
	# lost: the fight's loot is gone; the haul stays while any Hero stands
	if not hero_names().is_empty():
		out["next"] = "retry"
		out["reserves"] = hero_names()
		note("The fight is lost; %s can try again." % ", ".join(out["reserves"]))
		return out
	var w: Dictionary = wipe()
	w["next"] = "wipe"
	w["kind"] = a["kind"]
	w["name"] = a["name"]
	return w


## A POI's reward, once its last floor is won: {bag, items}.
func final_reward(a: Dictionary) -> Dictionary:
	var u = null
	if a.get("unique") != null:
		for x in world.uniques:
			if x is Dictionary and x.get("id") == a["unique"]:
				u = x
	var rw := {}
	var items := []
	var set_reward = u.get("reward") if u is Dictionary else null
	if set_reward is Dictionary:
		rw = {"shards": World.number(set_reward.get("shards")), "lines": [{"kind": "roll", "n": World.number(set_reward.get("n")),
			"type": set_reward["type"] if Rules.truthy(set_reward.get("type")) else "any", "bonus": World.number(set_reward.get("bonus"))}]}
	else:
		rw = {"shards": World.number(world.tables["poi"].get("shards")) * int(a["skull"]), "lines": [{"kind": "roll", "n": world.tables["poi"].get("n"), "type": "any", "bonus": world.tables["poi"].get("bonus")}]}
	var bag := loot.roll_reward(rw, a["skull"])
	var c = cur()
	var pend: Array = c["items"].duplicate() if c != null else []
	if set_reward is Dictionary and set_reward.get("items") is Array:
		items = progress.roll_reward_items({"lines": set_reward["items"].map(func(x): return {"kind": "item", "item": x.get("item"), "chance": x.get("chance")})}, pend)
	var chance = set_reward.get("bp") if set_reward is Dictionary and set_reward.get("bp") != null else world.tables["poi"].get("bp")
	items = items + progress.roll_items({"chance": chance, "district": a["district"], "card": {}, "cardChance": world.tables["poi"].get("card"), "skull": a["skull"]}, pend + items)
	return {"bag": bag, "items": items}


func retryable() -> bool:
	var c = cur()
	return c != null and c["activity"] != null and not hero_names().is_empty()


# ---------------------------------------------------------------- a cache: loot, no fight
func open_cache(k) -> Variant:
	var c = cur()
	if c == null:
		return null
	var content = world.content_at(k)
	if not world.available(k) or content == null or content["kind"] != "cache":
		return null
	var sk := world.skull_of(k)
	var tc: Dictionary = world.tables["cache"]
	var bag := loot.roll_reward({"shards": World.number(tc.get("shards")) * sk, "lines": [{"kind": "roll", "n": tc.get("n"), "type": "any", "bonus": tc.get("bonus")}]}, sk)
	var its := progress.roll_items({"chance": tc.get("bp"), "district": world.district_of(k), "card": {}, "cardChance": tc.get("card"), "skull": sk}, c["items"])
	c["haul"] = Loot.add(c["haul"], bag)
	for it in its:
		c["items"].append(it)
		progress.name(it)
	world.clear(k, int(c["n"]))
	note("Opened a cache: %s%s." % [loot.text(bag), (", and %d more" % its.size()) if not its.is_empty() else ""])
	return {"bag": bag, "items": its}


# ---------------------------------------------------------------- an event: a choice, sometimes a d20 check
func event_at(k) -> Variant:
	var content = world.content_at(k)
	return world.event_for(k) if world.available(k) and content != null and content["kind"] == "event" else null


## Chooses. Returns {event, choice, check, roll, won, text, got, items, lost,
## fight, spec}: what was rolled against what, what it gave or cost, and the
## fight it starts, if it starts one.
func choose(k, i: int) -> Variant:
	var c = cur()
	var ev = event_at(k)
	if c == null or ev == null:
		return null
	var choices: Array = ev["choices"] if ev.get("choices") is Array else []
	if i < 0 or i >= choices.size() or not (choices[i] is Dictionary):
		return null
	var ch: Dictionary = choices[i]
	var check := World.number(ch.get("check"))
	var roll := (1 + int(floor(loot.rnd() * 20.0))) if check != 0.0 else 0
	var won := check == 0.0 or roll >= check
	var o = ch.get("win") if won else ch.get("fail")
	if not (o is Dictionary):
		o = {}
	var sk := world.skull_of(k)
	var got := Loot.bag()
	var items := []
	var lost_bag = null
	if World.number(o.get("shards")) != 0.0:
		got["shards"] = maxi(0, int(Rules.js_round(World.number(o["shards"]) * sk)))
	if World.number(o.get("n")) != 0.0:
		got = Loot.add(got, loot.roll_reward({"shards": 0, "lines": [{"kind": "roll", "n": World.number(o["n"]), "type": o["type"] if Rules.truthy(o.get("type")) else "any", "bonus": World.number(o.get("bonus"))}]}, sk))
	if World.number(o.get("bp")) != 0.0:
		items = progress.roll_items({"chance": World.number(o["bp"]), "district": world.district_of(k), "card": {}}, c["items"])
	if World.number(o.get("lose")) != 0.0:
		var pc := clampf(World.number(o["lose"]), 0.0, 100.0) / 100.0
		var h := Loot.norm(c["haul"])
		lost_bag = Loot.bag()
		lost_bag["shards"] = int(floor(h["shards"] * pc))
		for ty in Loot.TYPES:
			for r in 6:
				lost_bag["parts"][ty["id"]][r] = int(floor(h["parts"][ty["id"]][r] * pc))
		h["shards"] -= lost_bag["shards"]
		for ty in Loot.TYPES:
			for r in 6:
				h["parts"][ty["id"]][r] -= lost_bag["parts"][ty["id"]][r]
		c["haul"] = h
	c["haul"] = Loot.add(c["haul"], got)
	for it in items:
		c["items"].append(it)
		progress.name(it)
	world.clear(k, int(c["n"]))
	note("%s: %s%s." % [str(ev.get("title", "An event")), str(ch.get("label", "")), (" (rolled %d, needed %s)" % [roll, _whole_text(check)]) if check != 0.0 else ""])
	var out := {"event": ev, "choice": ch, "check": check, "roll": roll, "won": won, "text": str(o["text"]) if Rules.truthy(o.get("text")) else "",
		"got": got, "items": items, "lost": lost_bag, "fight": Rules.truthy(o.get("fight"))}
	if Rules.truthy(o.get("fight")):
		out["spec"] = ambush(k, {"fromEvent": true})
	return out


## 10.0 as "10", 10.5 as "10.5".
static func _whole_text(v: float) -> String:
	return str(int(v)) if v == floor(v) else str(v)


# ---------------------------------------------------------------- coming home, or not
## The team walks back onto the dock: the haul goes into the stockpile and
## what it found is yours. Returns {ok, haul, items, n} or {ok: false, why}.
func home() -> Dictionary:
	var c = cur()
	if c == null:
		return {"ok": false, "why": "No deployment"}
	if c["pos"] != world.dock():
		return {"ok": false, "why": "The team has to reach the dock"}
	if c["activity"] != null:
		return {"ok": false, "why": "Finish what you started first"}
	return _bank(c, "home", "Home.")


func _bank(c: Dictionary, result: String, said: String) -> Dictionary:
	var haul := Loot.norm(c["haul"])
	stock = Loot.add(stock, haul)
	# 0.10: components brought home are known; what was packed and not used goes back to the dock
	for ty in Loot.TYPES:
		for r in 6:
			if haul["parts"][ty["id"]][r] > 0:
				progress.see("comp", "%s:%d" % [ty["id"], r])
	if dock != null:
		for part in ["cons", "protos"]:
			var m = c["pack"].get(part)
			if m is Dictionary:
				for nm in m:
					dock.add_card(str(nm), int(m[nm]))
	var explored: bool = world.known_count() > int(c.get("known0", 0))
	# in level order, so a level 1 and its level 2 found on one trip are both kept
	var parsed: Array = c["items"].map(func(it): return Progress.parse_item(it)).filter(func(o): return o != null)
	parsed = Rules.stable_sort(parsed, func(a, b): return int(a.get("level", 0)) - int(b.get("level", 0)))
	var granted := []
	for o in parsed:
		var id := Progress.item_id(o)
		if progress.grant(id):
			granted.append(id)
	world.end_deployment()
	_push_history({"n": c["n"], "result": result, "ended": _now(), "team": c["team"].get("name"), "steps": c["steps"], "fights": c["fights"],
		"haul": haul, "items": granted, "lost": c["lost"].duplicate(), "out": c["heroesOut"].size()})
	c["active"] = false
	c["ended"] = _now()
	c["result"] = result
	c["activity"] = null
	s = c
	note(said)
	# (a team brought home because the map changed has explored nothing that counts)
	var dk := dock.deployment_ended({"result": "home", "maxSkull": int(c.get("maxSkull", 0)), "kills": c.get("kills", []), "explored": explored and result == "home"}) if dock != null else {}
	return {"ok": true, "haul": haul, "items": granted, "n": c["n"], "dock": dk}


## Every Hero is down, or you gave up: the haul and what was found are lost.
func wipe() -> Dictionary:
	var c = cur()
	if c == null:
		return {"ok": false}
	var haul := Loot.norm(c["haul"])
	var items: Array = c["items"].duplicate()
	var explored: bool = world.known_count() > int(c.get("known0", 0))
	world.end_deployment()
	_push_history({"n": c["n"], "result": "wipe", "ended": _now(), "team": c["team"].get("name"), "steps": c["steps"], "fights": c["fights"],
		"haul": haul, "items": items, "lost": c["lost"].duplicate(), "out": c["heroesOut"].size()})
	c["active"] = false
	c["ended"] = _now()
	c["result"] = "wipe"
	c["activity"] = null
	s = c
	note("Wiped out. The haul is lost.")
	# packed Consumables and Prototypes are lost with it; insurance may keep some of the haul
	var dk := dock.deployment_ended({"result": "wipe", "haul": haul, "explored": explored}) if dock != null else {}
	return {"ok": true, "lostHaul": haul, "lostItems": items, "n": c["n"], "dock": dk, "lostPack": c["pack"].duplicate(true)}


## The map under the team is gone (a new export with another map): it is
## brought home with what it carries.
func recall() -> Variant:
	var c = cur()
	if c == null:
		return null
	return _bank(c, "recalled", "The map changed, so the team was brought home with its haul.")


# ---------------------------------------------------------------- in words
## A history entry in a line: "Deployment 3 · home · Vanguard · 14 steps, 2 fights · 12 shards, 2 × Scrap servos · Burst L1".
func history_line(e: Dictionary) -> String:
	var how: String = {"home": "came home", "wipe": "wiped out", "recalled": "brought home"}.get(e.get("result"), str(e.get("result")))
	var bits := ["Deployment %d" % int(e.get("n", 0)), how, str(e.get("team", "")), "%d step%s, %d fight%s" % [int(e.get("steps", 0)), "" if int(e.get("steps", 0)) == 1 else "s", int(e.get("fights", 0)), "" if int(e.get("fights", 0)) == 1 else "s"]]
	var lost_it: bool = e.get("result") == "wipe"
	var haul_text := loot.text(e.get("haul"))
	var found: Array = e.get("items", []).map(func(it): return progress.item_name(it, not lost_it))
	if lost_it:
		bits.append("lost: " + haul_text + ((", " + ", ".join(found)) if not found.is_empty() else ""))
	else:
		bits.append(haul_text + ((", " + ", ".join(found)) if not found.is_empty() else ""))
	return " · ".join(bits)
