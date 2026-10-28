## Deployments played through by a random hand, on the export's own World Map
## with its real cards and floors.
##
## First without the screen: Strike Teams thrown together from the export
## leave the dock and walk the map; ambushes are sprung, POIs entered and
## fought floor by floor, Caches opened, Events chosen, Emergency Exits taken;
## every fight is a real Battle, both sides on Auto, with Consumables used
## along the way; fights are won, lost, tried again with whoever is left, and
## lost for good; teams come home, or are wiped out, one deployment after
## another so that cleared tiles come back. Everything is saved and read back
## as it goes.
##
## Then through the screen: the dock, Deploy, the map's panel and its
## buttons, Walk here, each fight's setup, the Battle on Auto, its result box,
## and home.
##
## Nothing here checks who wins. It checks that nothing breaks and that the
## books balance: the haul and the stockpile are never short or over, a Hero
## who went down stays out, a Troop that fell stays gone, a Consumable used
## stays used, a blueprint is found once and in order, nothing is done while
## a fight waits, what is saved is what is so, and the screen says what is so.
##   godot --headless --path . --script res://tests/soak_world.gd [-- deployments]
extends SceneTree

const FIXTURE := "res://tests/fixtures/export.zip"
const Kit := preload("res://tests/team_kit.gd")
var rng := RandomNumberGenerator.new()
var wrong: Array = []
var x: KeterExport
var r: Roster
var floors: Array[FloorData] = []
var seen := {"deployments": 0, "steps": 0, "ambush": 0, "tile_ambush": 0, "poi": 0, "poi_done": 0, "floor": 0, "cache": 0, "event": 0, "event_fight": 0, "check_won": 0, "check_failed": 0,
	"fights": 0, "won": 0, "lost": 0, "retry": 0, "withdraw": 0, "wipe": 0, "escape": 0, "home": 0, "items": 0, "items_home": 0, "troops_lost": 0, "heroes_down": 0, "cons_used": 0,
	"refused": 0, "refused_leave": 0, "paid": 0, "designs": 0, "design_copies": 0, "designs_fought": 0, "saves": 0, "respawned": 0, "rounds": 0, "screen_deployments": 0, "screen_fights": 0, "screen_walks": 0, "screen_boxes": 0, "lose_from_event": 0,
	"bought": 0, "pre_bought": 0, "pre_out": 0, "upgraded": 0, "packed": 0, "pack_home": 0, "pack_lost": 0, "bounties_posted": 0, "bounty_fights": 0, "bounties_paid": 0, "insured": 0, "restocks": 0, "reach": 0, "screen_bought": 0, "screen_dock_taps": 0}
var packed_at_start := {}              # (0.10: what the deployment out now packed at the dock)
var inv_after_start := {}              # (and what the dock held once it had left)
var last_kept := Loot.bag()            # (and what insurance kept when it was last wiped out)
var wanted_at_start := []             # (and the bounties the board wanted as it left)


func _initialize() -> void:
	_run.call_deferred()


func _pick(list: Array):
	return list[rng.randi() % list.size()]


func _bad(what: String) -> void:
	if wrong.size() < 40:
		wrong.append(what)


# ---------------------------------------------------------------- what must always be true
func _whole_bag(b, what: String, when: String) -> void:
	var o := Loot.norm(b)
	if o != b:
		_bad("%s: %s is not a whole bag: %s" % [when, what, str(b).left(160)])
	if o["shards"] < 0:
		_bad("%s: %s has %d shards" % [when, what, o["shards"]])
	for ty in Loot.TYPES:
		for n in o["parts"][ty["id"]]:
			if n < 0:
				_bad("%s: %s has a negative count" % [when, what])


func _sound(c: Campaign, when: String) -> void:
	var dep := c.deploy
	var w := c.world
	_whole_bag(dep.stock, "the stockpile", when)
	for k in w.state["stood"]:
		if not w.state["known"].has(k):
			_bad("%s: the team stood on %s and doesn't know it" % [when, k])
	for k in w.state["known"]:
		if not w.is_open(k):
			_bad("%s: %s is known and isn't a tile" % [when, k])
	for name in c.progress.state["bp"]:
		var b = c.progress.blueprint_of(name)
		if b == null or int(c.progress.state["bp"][name]) < 1 or int(c.progress.state["bp"][name]) > b["levels"]:
			_bad("%s: owns %s at level %s" % [when, name, str(c.progress.state["bp"][name])])
	if dep.history.size() > Deployment.HISTORY_MOST:
		_bad("%s: the history holds %d deployments" % [when, dep.history.size()])
	var cur = dep.cur()
	if cur == null:
		return
	var team: Dictionary = cur["team"]
	_whole_bag(cur["haul"], "the haul", when)
	if not w.is_open(cur["pos"]) or not w.state["stood"].has(cur["pos"]):
		_bad("%s: the team is on %s, which is not ground it has stood on" % [when, cur["pos"]])
	var up := dep.hero_names()
	for h in cur["heroesOut"]:
		if up.has(h) or not team["heroes"].has(h):
			_bad("%s: %s sits out and %s" % [when, h, "stands too" if up.has(h) else "was never in the team"])
	if up.size() + cur["heroesOut"].size() != team["heroes"].size():
		_bad("%s: %d Heroes stand and %d sit out, of %d" % [when, up.size(), cur["heroesOut"].size(), team["heroes"].size()])
	for name in cur["lost"]:
		var went := StrikeTeams.copies(team, str(name)) + dep.pre_copies(str(name))
		if int(cur["lost"][name]) < 1 or int(cur["lost"][name]) > went:
			_bad("%s: %d copies of %s are lost, of %d" % [when, int(cur["lost"][name]), name, went])
		var card = r.card_named(str(name))
		if card == null or Roster.type_of(card) != "troop":
			_bad("%s: %s is counted as a Troop lost" % [when, name])
	# (0.10: what was packed at the dock, less what has been used)
	for name in cur["pack"]["cons"]:
		var had := int(packed_at_start.get(name, 0))
		if int(cur["pack"]["cons"][name]) < 0 or int(cur["pack"]["cons"][name]) > had:
			_bad("%s: %d %s are packed, of %d" % [when, int(cur["pack"]["cons"][name]), name, had])
	for name in cur["pack"]["protos"]:
		if int(cur["pack"]["protos"][name]) != int(packed_at_start.get(name, 0)):
			_bad("%s: %d of the Prototype %s ride along, of %d packed" % [when, int(cur["pack"]["protos"][name]), name, int(packed_at_start.get(name, 0))])
	if c.dock.closed() != true or c.dock.buy_card("x", 1)["ok"] or c.dock.upgrade("scanner")["ok"]:
		_bad("%s: the dock trades while the team is out" % when)
	# what it has found: each once, each one it could keep, levels in order
	var so_far := []
	for it in cur["items"]:
		if not c.progress.eligible(it, so_far):
			_bad("%s: the team carries %s, which it couldn't keep (with %s)" % [when, it, str(so_far)])
		so_far.append(it)
	var a = cur["activity"]
	if a != null:
		if a["floors"].is_empty() or int(a["index"]) < 0 or int(a["index"]) >= a["floors"].size() or a["floors"].any(func(k): return w.floor_named(k) == null):
			_bad("%s: a fight waits on floors %s at %s" % [when, str(a["floors"]), str(a["index"])])
		if a["tile"] != cur["pos"]:
			_bad("%s: a fight waits on %s and the team is on %s" % [when, a["tile"], cur["pos"]])
		if int(a["skull"]) != w.skull_of(a["tile"]) or a["district"] != w.district_of(a["tile"]):
			_bad("%s: the fight on %s is at Skull %s in District '%s'" % [when, a["tile"], str(a["skull"]), a["district"]])
		if up.is_empty():
			_bad("%s: a fight waits and nobody stands" % when)
	var now: Dictionary = dep.team_now()
	if now["heroes"] != up or StrikeTeams.deck_count(now) != StrikeTeams.deck_count(team) + _sum(cur.get("pre", {})) - _sum(cur["lost"]) or now["consumables"] != cur["pack"]["cons"]:
		_bad("%s: the team as it stands doesn't add up" % when)


func _sum(d) -> int:
	var n := 0
	if d is Dictionary:
		for k in d:
			n += int(d[k])
	return n


## What salvage insurance keeps of a haul lost: its share of each, rounded down.
func _kept(c: Campaign, haul) -> Dictionary:
	var ins = c.dock.insurance()
	var kept := Loot.bag()
	if Rules.truthy(ins):
		var h := Loot.norm(haul)
		kept["shards"] = int(floor(h["shards"] * float(ins) / 100.0))
		for ty in Loot.TYPES:
			for rr in 6:
				kept["parts"][ty["id"]][rr] = int(floor(h["parts"][ty["id"]][rr] * float(ins) / 100.0))
	return kept


## 0.10: a deployment wiped out. Insurance keeps its share of the haul (and
## nothing else reaches the dock); what was packed is lost; what the dock
## holds is what it held when the team left. Returns what the stockpile
## should now be.
func _after_wipe(c: Campaign, stock0: Dictionary, out: Dictionary, haul: Dictionary, when: String) -> Dictionary:
	var dk: Dictionary = out.get("dock", {}) if out.get("dock") is Dictionary else {}
	var ins = c.dock.insurance()
	var kept := _kept(c, haul)
	var said = dk.get("insured")
	if (Loot.norm(said) if said != null else Loot.bag()) != kept or (said != null and Loot.is_empty(kept)):
		_bad("%s: insurance at %s%% kept %s of a haul of %s" % [when, str(ins), c.loot.text(said) if said != null else "nothing", c.loot.text(haul)])
	if not Loot.is_empty(kept):
		seen["insured"] += 1
	last_kept = kept
	if dk.has("reach") or dk.has("bounties"):
		_bad("%s: a wipe extended the reach, or paid a bounty" % when)
	if Rules.truthy(dk.get("restocked")):
		seen["restocks"] += 1
	if c.dock.inv != inv_after_start:
		_bad("%s: a wipe changed what the dock holds: %s, and it held %s" % [when, str(c.dock.inv), str(inv_after_start)])
	var lp = out.get("lostPack", {})
	seen["pack_lost"] += _sum(lp.get("cons")) + _sum(lp.get("protos")) if lp is Dictionary else 0
	return Loot.add(stock0, kept)


## 0.10: a deployment home. What it carried and the bounties it claimed reach
## the stockpile; what was packed and not used goes back to the dock.
func _after_home(c: Campaign, stock0: Dictionary, carried: Dictionary, pack: Dictionary, h: Dictionary, when: String) -> Dictionary:
	var dk: Dictionary = h.get("dock", {}) if h.get("dock") is Dictionary else {}
	var owed := Loot.add(stock0, carried)
	var claimed: Array = dk.get("bounties", [])
	for b in claimed:
		owed = Loot.add(owed, b["bag"])
		# (unless the board has changed since, with a restock)
		var on_board = c.dock.bounties().filter(func(x): return x["name"] == b["name"])
		if not Rules.truthy(dk.get("restocked")) and (on_board.is_empty() or not Rules.truthy(on_board[0].get("claimed")) or on_board[0].get("paid") != b["bag"]):
			_bad("%s: the bounty on %s was paid and the board doesn't say so" % [when, b["name"]])
		if not wanted_at_start.has(b["name"]):
			_bad("%s: a bounty on %s was paid, and the board didn't want it when the team left" % [when, b["name"]])
	seen["bounties_paid"] += claimed.size()
	if dk.has("insured"):
		_bad("%s: insurance paid out on a team that came home" % when)
	if Rules.truthy(dk.get("restocked")):
		seen["restocks"] += 1
	if dk.has("reach"):
		seen["reach"] += 1
	var inv: Dictionary = inv_after_start.duplicate(true)
	for part in ["cons", "protos"]:
		var m = pack.get(part)
		if m is Dictionary:
			for nm in m:
				if int(m[nm]) > 0:
					inv["cards"][nm] = int(inv["cards"].get(nm, 0)) + int(m[nm])
					seen["pack_home"] += int(m[nm])
	# (0.22) and a card found on the way is kept there
	for it in h.get("items", []):
		if str(it).begins_with("cd:"):
			var cn := str(it).substr(3)
			inv["cards"][cn] = int(inv["cards"].get(cn, 0)) + 1
			seen["cards_home"] = int(seen.get("cards_home", 0)) + 1
	if c.dock.inv != inv:
		_bad("%s: home, and the dock holds %s; it should hold %s" % [when, str(c.dock.inv), str(inv)])
	return owed


## Saved, read into a campaign of its own, and the same.
func _round_trip(c: Campaign, when: String) -> void:
	if not c.save():
		_bad("%s: it couldn't be saved" % when)
		return
	seen["saves"] += 1
	var again := Campaign.new(x, Roster.new(x), floors, 1)
	var a = JSON.parse_string(JSON.stringify(c.to_dict()))
	var b = JSON.parse_string(JSON.stringify(again.to_dict()))
	if a != b:
		_bad("%s: what was read back is not what was saved" % when)
	if again.note != "":
		_bad("%s: reading it back said: %s" % [when, again.note])
	r.progress = c.progress           # the roster is this campaign's again


# ---------------------------------------------------------------- a fight, both sides on Auto
## Fights the fight that is waiting, and tells the deployment. Returns what it said.
func _fight(c: Campaign, when: String) -> Dictionary:
	var dep := c.deploy
	var sp: Dictionary = dep.spec()
	var team: Dictionary = dep.team_now()
	var f := FloorData.from_dict(_floor(sp["floor"]).raw)
	f.district = str(sp["district"])
	var su: Dictionary = Kit.entry(team, r, f, rng)
	su["wave_timer"] = 3
	su["instability"] = 0
	su["deploy"] = {"district": sp["district"], "skull": sp["skull"], "kind": sp["kind"], "pending": sp["pending"], "bounties": c.dock.wanted()}
	var b := Battle.begin_team(f, r, su, rng.randi())
	seen["fights"] += 1
	# (0.10: an Enemy the Bounty Board wants is tagged so, and no other)
	var wanted: Array = c.dock.wanted()
	for e in b.side_units("enemy"):
		var en := str(e["src"] if Rules.truthy(e.get("src")) else e["name"])
		if Rules.truthy(e.get("bounty")) != wanted.has(en):
			_bad("%s: %s is %stagged as a bounty, and the board wants %s" % [when, en, "" if Rules.truthy(e.get("bounty")) else "not ", str(wanted)])
	if b.side_units("enemy").any(func(e): return Rules.truthy(e.get("bounty"))):
		seen["bounty_fights"] += 1
	if b.deploy == null or b.poi_skull() != int(sp["skull"]) or b.floor_data.district != str(sp["district"]) or b.instability != 0:
		_bad("%s: the fight isn't the deployment's: Skull %d, District '%s'" % [when, b.poi_skull(), b.floor_data.district])
	if b.progress != c.progress:
		_bad("%s: the fight doesn't know what the campaign owns" % when)
	var entering: Array = su["heroes"].map(func(h): return h["name"])
	for u in b.side_units("ally"):
		var src := str(u["src"] if Rules.truthy(u.get("src")) else u["name"])
		# (0.23) a Unit a Starting Troop's arrival Deploys (a FALCON Drone Token) is no copy of the team's
		if str(u["id"]).begins_with("d"):
			continue
		if str(u.get("cardType", "")).to_lower().contains("hero"):
			if not dep.hero_names().has(src):
				_bad("%s: %s is in the fight, and sits out" % [when, src])
		elif dep.copies_left(src) < 1:
			_bad("%s: %s started the fight with no copy left" % [when, src])
		else:
			var uc = r.card_named(src)
			if uc != null and uc.get("_src") == "workshop" and src != "Frame Trooper":
				seen["designs_fought"] += 1
	if b.consumables.size() != _sum(dep.cur()["pack"]["cons"]):
		_bad("%s: %d Consumables came to the fight, of %d packed" % [when, b.consumables.size(), _sum(dep.cur()["pack"]["cons"])])
	# an Enemy fights at the level of the spawn tile it arrived on, which the tile's Skull Level sets
	# (one put down by another Enemy's card has no spawn tile, and keeps its own level)
	var levels: Array = b.enemy_spawns().map(func(t): return t["level"])
	for e in b.side_units("enemy"):
		if e.has("spawnLevel") and (e["skull"] != e["spawnLevel"] or not levels.has(e["skull"]) or int(e["skull"]) < 1 or int(e["skull"]) > 6):
			_bad("%s: %s arrived at Skull %s; the spawn tiles are %s" % [when, e["name"], str(e["skull"]), str(levels)])
	var keys: Array = Behaviors.choices()
	var want := rng.randf()             # who should come out of it, if the fight itself doesn't say
	var exit_tiles := b.floor_data.marks.keys().filter(func(h): return b.exit_at(h))
	while not b.settle() and b.round <= 5:
		# a Consumable is used now and then (marked as the game marks one used)
		for con in b.consumables:
			if not con["used"] and rng.randf() < 0.08:
				con["used"] = true
		# inside a POI with an Emergency Exit, a Hero sometimes makes for it
		if sp["kind"] == "poi" and not exit_tiles.is_empty() and rng.randf() < 0.12:
			var runner = b.side_units("ally").filter(func(u): return not Rules.truthy(u.get("down")) and str(u.get("cardType", "")).to_lower().contains("hero"))
			if not runner.is_empty() and b.unit_at(exit_tiles[0]) == null:
				runner[0]["pos"] = {"q": exit_tiles[0].x, "r": exit_tiles[0].y}
				if not b.can_escape(runner[0]) or not b.escape(runner[0]):
					_bad("%s: a Hero on the Emergency Exit of a POI couldn't leave" % when)
				break
		for id in b.auto_queue():
			var u = b.unit_by_id(id)
			if u == null or Rules.truthy(u.get("down")) or b.enemies_left() == 0:
				continue
			u["behaviors"] = Behaviors.toggle([], _pick(keys)["k"])["list"]
			b.auto_turn(u)
			if b.settle():
				break
		if b.settle():
			break
		for id in b.enemy_queue():
			var e = b.unit_by_id(id)
			if e != null and not Rules.truthy(e.get("down")):
				b.enemy_turn(e)
			if b.settle():
				break
		if not b.over:
			b.end_round()
			seen["rounds"] += 1
	if not b.over:
		# the rounds are up: one side is brought down, the way the fight was leaning or by chance
		var win := want < 0.62
		for u in b.side_units("enemy" if win else "ally"):
			if win or str(u.get("cardType", "")).to_lower().contains("hero") or rng.randf() < 0.5:
				u["hp"] = 0
		if win:
			b.wave = b.waves_total
			b.enemy_pile.clear()
		b.check_downs()
		b.settle()
	if not b.over:
		_bad("%s: the fight wouldn't end" % when)
		return {"next": "map"}
	var res := b.deploy_result()
	for h in res["heroesDown"]:
		if not entering.has(h):
			_bad("%s: %s went down and never went in" % [when, h])
	if res["winner"] != b.winner or (b.winner != "ally" and not Loot.is_empty(res["reward"])):
		_bad("%s: a fight that ended '%s' is told as '%s', with a reward of %s" % [when, b.winner, res["winner"], c.loot.text(res["reward"])])
	var cur: Dictionary = dep.cur()
	var haul0: Dictionary = Loot.norm(cur["haul"])
	var items0: Array = cur["items"].duplicate()
	var out0: int = cur["heroesOut"].size()
	var lost0: int = _sum(cur["lost"])
	var cons0: int = _sum(cur["pack"]["cons"])
	var stock0: Dictionary = dep.stock.duplicate(true)
	var owned0: Dictionary = c.progress.state.duplicate(true)
	var tile: String = cur["activity"]["tile"]
	var was_tile_ambush: bool = Rules.truthy(cur["activity"].get("tileAmbush"))
	var kind: String = cur["activity"]["kind"]
	var out := dep.fight_over(res)
	var next: String = str(out.get("next"))
	seen["heroes_down"] += res["heroesDown"].size()
	seen["cons_used"] += res["consUsed"].size()
	var kept: bool = b.winner == "ally" or b.winner == "escape"
	seen["won" if kept else "lost"] += 1
	if next == "wipe":
		seen["wipe"] += 1
		if dep.active() or dep.stock != _after_wipe(c, stock0, out, haul0, when) or c.progress.state["bp"] != owned0["bp"] or c.progress.state["ch"] != owned0["ch"]:
			_bad("%s: a wipe left the team out, or banked something" % when)
		if Loot.norm(out["lostHaul"]) != haul0 or out["lostItems"] != items0:
			_bad("%s: a wipe lost %s, and the team carried %s" % [when, c.loot.text(out["lostHaul"]), c.loot.text(haul0)])
		if dep.history[0]["result"] != "wipe" or kept:
			_bad("%s: a wipe after a fight that was %s" % [when, b.winner])
		return out
	cur = dep.cur()
	if cur["heroesOut"].size() != out0 + res["heroesDown"].size():
		_bad("%s: %d Heroes went down and %d more sit out" % [when, res["heroesDown"].size(), cur["heroesOut"].size() - out0])
	var lost_now := _sum(cur["lost"])
	seen["troops_lost"] += lost_now - lost0
	if lost_now < lost0 or lost_now - lost0 > res["troopsLost"].size():
		_bad("%s: %d Troops fell and %d copies went" % [when, res["troopsLost"].size(), lost_now - lost0])
	if _sum(cur["pack"]["cons"]) != cons0 - res["consUsed"].size():
		_bad("%s: %d Consumables were used and %d are gone" % [when, res["consUsed"].size(), cons0 - _sum(cur["pack"]["cons"])])
	if kept:
		var gained := Loot.add(res["haul"], res["reward"] if b.winner == "ally" else null)
		var fin = out["final"]["bag"] if out.get("final") is Dictionary else Loot.bag()
		if Loot.norm(cur["haul"]) != Loot.add(Loot.add(haul0, gained), fin):
			_bad("%s: the haul is %s after %s came in" % [when, c.loot.text(cur["haul"]), c.loot.text(gained)])
		seen["items"] += cur["items"].size() - items0.size()
		if cur["activity"] != null and next != "floor":
			_bad("%s: a fight won, and it still waits" % when)
		match next:
			"floor":
				seen["floor"] += 1
				if kind != "poi" or c.world.is_cleared(tile):
					_bad("%s: a next floor, outside a POI or in one already cleared" % when)
			"map":
				if b.winner == "escape":
					seen["escape"] += 1
				if Rules.truthy(out.get("poiDone")):
					seen["poi_done"] += 1
				var should_clear: bool = kind == "poi" or was_tile_ambush
				if c.world.is_cleared(tile) != should_clear and c.world.content_at(tile) != null and not (kind == "ambush" and not was_tile_ambush):
					_bad("%s: %s on %s is %scleared" % [when, kind, tile, "" if c.world.is_cleared(tile) else "not "])
	else:
		if Loot.norm(cur["haul"]) != haul0 or cur["items"] != items0:
			_bad("%s: a fight lost changed what the team carries" % when)
		if next != "retry" or cur["activity"] == null or out.get("reserves") != dep.hero_names():
			_bad("%s: a fight lost with %d Heroes standing leads to '%s'" % [when, dep.hero_names().size(), next])
		seen["retry"] += 1
	return out


func _floor(name) -> FloorData:
	# (0.20) a battlefield grown from chunks, from its key
	if ChunkGen.is_gen_key(name):
		var lv := ChunkGen.from_key(floors.map(func(f): return f.raw).filter(func(r2): return ChunkGen.is_chunk(r2)), name)
		return FloorData.from_dict(lv) if not lv.is_empty() else null
	for f in floors:
		if f.name == str(name):
			return f
	return null


# ---------------------------------------------------------------- designs of your own
## 0.9: designs made with the keyword builder, as a player makes them, on
## the chassis found so far: they go out in the teams and fight. Returns
## their names.
func _designs(c: Campaign) -> Array:
	var ws := c.workshop
	# (one chassis found already, and two blueprints: the rest is left to drop on the way)
	c.progress.grant("ch:ch_test_threshold")
	c.progress.grant("bp:Burst:1")
	c.progress.grant("bp:Marked:1")
	var names := []
	var cards: Array = r.troops().map(func(k): return str(k["name"]))
	var tries := 0
	while names.size() < 5 and tries < 200:
		tries += 1
		var ch: Dictionary = _pick(ws.chassis_list().filter(func(k): return c.progress.has_chassis(k["id"])))
		var d := ws.blank(str(ch["id"]))
		d["name"] = "Soak Design %d" % (names.size() + 1)
		d["abilities"] = []
		for k in rng.randi_range(1, int(Scoring.num(ch.get("abilityCap"), 1.0))):
			d["abilities"].append(ws.blank_ability(ch, "passive" if rng.randf() < 0.3 else "action"))
		for i in d["abilities"].size():
			var sents := []
			for k in rng.randi_range(1, 2):
				var t := Kit.random_effect(ws.builder_options(d, i, -1, cards), rng)
				if t != "":
					sents.append(t)
			d["abilities"][i]["text"] = " ".join(sents)
		var chk := ws.check(d)
		# made with the builder, a design never uses what the chassis can't, or more than you own
		for why in chk["reasons"]:
			if "cannot use" in str(why) or "blueprint level" in str(why) or "not been found" in str(why):
				_bad("a design made with the builder: %s (%s)" % [why, str(d["abilities"].map(func(a): return a["text"]))])
		if chk["ok"]:
			ws.put(d)
			names.append(d["name"])
	c.designs_changed()
	seen["designs"] = names.size()
	if names.size() < 3:
		_bad("only %d designs were made that fit, in %d tries" % [names.size(), tries])
	return names


# ---------------------------------------------------------------- at the dock (0.10)
## Between deployments: shards given now and then, and spent at the Exchange
## and on upgrades as a player might, every price paid to the shard.
func _shop(c: Campaign, when: String) -> void:
	var dk := c.dock
	if dk.closed():
		_bad("%s: the dock is closed with nobody out" % when)
		return
	if rng.randf() < 0.6:
		var gift := Loot.bag()
		gift["shards"] = rng.randi_range(20, 260)
		if rng.randf() < 0.35:
			for ty in Loot.TYPES:
				gift["parts"][ty["id"]][rng.randi_range(0, 2)] += rng.randi_range(0, 5)
		dk.add_to_stockpile(gift)
	# (salvage insurance from the fifth deployment on, so that wipes with it are seen)
	if c.world.state["completed"] >= 4 and dk.level("insurance") == 0:
		var fee := Loot.bag()
		fee["shards"] = 150
		fee["parts"]["aether"][0] = 10
		dk.add_to_stockpile(fee)
		var left_i := dk.stockpile()
		left_i["shards"] -= 150
		left_i["parts"]["aether"][0] -= 10
		if not dk.upgrade("insurance")["ok"] or dk.insurance() != dk.tables["effect"]["insurance"][0] or dk.stockpile() != left_i:
			_bad("%s: salvage insurance, paid for, isn't had, or cost what it shouldn't" % when)
		seen["upgraded"] += 1
	var st := dk.stock()
	for k in rng.randi_range(0, 4):
		var before := dk.stockpile()
		var inv0: Dictionary = dk.inv.duplicate(true)
		var lv := {}
		for u in Dock.UPGRADES:
			lv[u["id"]] = dk.level(u["id"])
		var roll := rng.randf()
		var o := {}
		var cost := 0.0
		var what := ""
		if roll < 0.5 and not st["items"].is_empty():
			var nm: String = _pick(st["items"])
			var n := rng.randi_range(1, 3)
			what = "%d %s" % [n, nm]
			cost = float(dk.item_price(nm)) * n
			o = dk.buy_card(nm, n)
			if o["ok"]:
				seen["bought"] += n
				if dk.owned(nm) != int(inv0["cards"].get(nm, 0)) + n:
					_bad("%s: bought %s and the dock holds %d" % [when, what, dk.owned(nm)])
		elif roll < 0.75 and not st["pre"].is_empty():
			var id: String = _pick(st["pre"])
			var n := rng.randi_range(1, 2)
			var d = c.workshop.get_design(id)
			what = "%d pre-built %s" % [n, id]
			cost = float(dk.pre_cost(d)) * n if d != null else 0.0
			o = dk.buy_pre(id, n)
			if o["ok"]:
				seen["pre_bought"] += n
				if int(dk.waiting().get(id, 0)) != int(inv0["pre"].get(id, 0)) + n:
					_bad("%s: bought %s and %d wait" % [when, what, int(dk.waiting().get(id, 0))])
		elif roll < 0.85 and not (st["bps"] + st["chs"]).is_empty():
			var it: String = _pick(st["bps"] + st["chs"])
			what = it
			cost = float(dk.bp_price(it))
			var owned_before: bool = not c.progress.eligible(it)
			o = dk.buy_item(it)
			if o["ok"] and (owned_before or c.progress.eligible(it)):
				_bad("%s: bought %s and it isn't owned, or was already" % [when, it])
		else:
			var u: String = _pick(Dock.UPGRADES)["id"]
			var nc = dk.next_cost(u)
			what = "the %s upgrade" % u
			o = dk.upgrade(u)
			if o["ok"]:
				seen["upgraded"] += 1
				var owed := before.duplicate(true)
				owed["shards"] -= int(nc["shards"])
				owed["parts"][nc["type"]][nc["rarity"]] -= int(nc["n"])
				if dk.stockpile() != owed or dk.level(u) != lv[u] + 1:
					_bad("%s: %s cost %s, and the stockpile went from %s to %s" % [when, what, str(nc), c.loot.text(before), c.loot.text(dk.stockpile())])
			elif nc != null and dk.stockpile() != before:
				_bad("%s: %s was refused and the stockpile changed" % [when, what])
			continue
		var after := dk.stockpile()
		if o["ok"]:
			var left := before.duplicate(true)
			left["shards"] = int(floor(float(before["shards"]) - cost))
			if after != left or absf(float(o.get("price", cost)) - cost) > 1e-6:
				_bad("%s: %s cost %s, and the stockpile went from %d to %d shards" % [when, what, str(cost), before["shards"], after["shards"]])
		elif after != before or dk.inv != inv0:
			_bad("%s: buying %s was refused (%s) and something changed" % [when, what, str(o.get("why"))])
	if dk.starter_free() < int(Rules.num(c.world.tables.get("starterFree"), 4)) or dk.scan_range() < 1:
		_bad("%s: the Starter bay frees %d and the scanner sees %d" % [when, dk.starter_free(), dk.scan_range()])


# ---------------------------------------------------------------- deployments, without the screen
func _engine(want: int) -> void:
	var c := Campaign.new(x, r, floors, null)
	var w := c.world
	var cleared_once := {}
	var made := _designs(c)
	for i in want:
		var team: Dictionary = Kit.field_random(r, rng, "Soak %d" % i, made)
		# now and then a gift of Troop parts, so that copies past the free ones can be paid for
		if rng.randf() < 0.4:
			var gift := Loot.bag()
			gift["parts"]["troop"][0] = rng.randi_range(5, 60)
			c.deploy.stock = Loot.add(c.deploy.stock, gift)
		_shop(c, "at the dock before deployment %d" % (w.state["completed"] + 1))
		if not c.deploy.reasons_against(team).is_empty():
			var held: Dictionary = c.deploy.stock.duplicate(true)
			var why := c.deploy.reasons_against(team)
			if c.deploy.start(team)["ok"] or c.deploy.active() or c.deploy.stock != held:
				_bad("a team that couldn't leave (%s) left, or paid" % str(why))
			if not why.all(func(k): return str(k).begins_with("The stockpile can't pay")):
				_bad("a team of designs that fit can't leave: %s" % str(why))
			seen["refused_leave"] += 1
			# the starter's free copies alone, then
			for n in team["deck"].keys():
				var tc = r.card_named(str(n))
				if tc != null and Roster.type_of(tc) == "troop":
					team["deck"].erase(n)
			team["deck"]["Frame Trooper"] = rng.randi_range(1, c.deploy.starter_free())
			if not c.deploy.reasons_against(team).is_empty():
				_bad("a Strike Team with Heroes and free copies can't leave: %s" % str(c.deploy.reasons_against(team)))
				continue
		# 0.10: what it packs: what its own lists ask for, as far as the dock holds it, and now and then more
		var pack := c.deploy.default_pack(team)
		for nm in c.dock.inv["cards"]:
			if rng.randf() < 0.35:
				pack[nm] = rng.randi_range(0, c.dock.owned(nm))
		if not c.dock.inv["cards"].is_empty() and rng.randf() < 0.08:
			var over: String = _pick(c.dock.inv["cards"].keys())
			var held2: Dictionary = c.deploy.stock.duplicate(true)
			var inv2: Dictionary = c.dock.inv.duplicate(true)
			pack[over] = c.dock.owned(over) + 1
			if c.deploy.start(team, pack)["ok"] or c.deploy.active() or c.deploy.stock != held2 or c.dock.inv != inv2:
				_bad("a team packing %d %s, of %d held, left, or took something" % [pack[over], over, c.dock.owned(over)])
			if not c.deploy.reasons_against(team, pack).any(func(k): return str(k).begins_with("Only %d %s to pack" % [c.dock.owned(over), over])):
				_bad("packing more %s than the dock holds, and it says %s" % [over, str(c.deploy.reasons_against(team, pack))])
			pack[over] = c.dock.owned(over)
		var plan := c.deploy.plan(team, pack)
		var stock0: Dictionary = c.deploy.stock.duplicate(true)
		var inv0: Dictionary = c.dock.inv.duplicate(true)
		var done0: int = w.state["completed"]
		seen["bounties_posted"] += c.dock.wanted().size()
		wanted_at_start = c.dock.wanted()
		c.deploy.start(team, pack)
		var paid_off := Loot.norm(stock0)
		for k in 6:
			paid_off["parts"]["troop"][k] -= int(plan["parts"][k])
			seen["paid"] += int(plan["parts"][k])
		if c.deploy.stock != paid_off or c.deploy.cur()["paid"] != plan["parts"]:
			_bad("deployment %d paid %s for copies costing %s" % [w.state["completed"] + 1, c.loot.text(c.deploy.stock), str(plan["parts"])])
		# what was packed left the dock with the team, and the pre-built copies went too
		var packed_now: Dictionary = c.deploy.cur()["pack"]["cons"].duplicate()
		packed_now.merge(c.deploy.cur()["pack"]["protos"])
		var inv_left: Dictionary = inv0["cards"].duplicate()
		var want_packed := {}
		for nm in pack:
			if int(pack[nm]) > 0:
				want_packed[nm] = int(pack[nm])
				inv_left[nm] = int(inv_left.get(nm, 0)) - int(pack[nm])
				if inv_left[nm] == 0:
					inv_left.erase(nm)
		if packed_now != want_packed or c.dock.inv["cards"] != inv_left or not c.dock.inv["pre"].is_empty() or c.deploy.cur()["pre"] != inv0["pre"]:
			_bad("deployment %d packed %s and took %s; the dock held %s and holds %s" % [w.state["completed"], str(pack), str(packed_now), str(inv0), str(c.dock.inv)])
		packed_at_start = packed_now.duplicate()
		inv_after_start = c.dock.inv.duplicate(true)
		seen["packed"] += _sum(packed_now)
		seen["pre_out"] += _sum(inv0["pre"])
		for pl in c.deploy.cur()["preLines"]:
			if c.deploy.copies_left(str(pl["name"])) < int(pl["copies"]):
				_bad("deployment %d took %d pre-built copies of %s and has %d" % [w.state["completed"], pl["copies"], pl["name"], c.deploy.copies_left(str(pl["name"]))])
		for l in plan["lines"]:
			if not l["starter"]:
				seen["design_copies"] += l["copies"]
			if not c.workshop.locked(l["id"]):
				_bad("%s is out and can be changed" % l["name"])
		stock0 = c.deploy.stock.duplicate(true)      # (what comes home is added to what is left)
		seen["deployments"] += 1
		var n: int = c.deploy.cur()["n"]
		if n != done0 + 1 or c.deploy.start(team)["ok"]:
			_bad("deployment %d began as number %d, or a second left with it" % [done0 + 1, n])
		_sound(c, "leaving the dock")
		# a tile that was cleared long enough ago holds something again
		for k in cleared_once.keys():
			if not w.is_cleared(k) and w.content_at(k) != null:
				if not w.available(k):
					_bad("%s came back and can't be used" % k)
				cleared_once.erase(k)
				seen["respawned"] += 1
		var goal := ""
		var budget := rng.randi_range(10, 45)
		var visited := {}
		while budget > 0 and c.deploy.active():
			budget -= 1
			var cur: Dictionary = c.deploy.cur()
			var when := "deployment %d, step %d" % [n, int(cur["steps"])]
			if cur["activity"] != null:
				# nothing else can be done while a fight waits
				if c.deploy.step_to(_pick(World.neighbours(cur["pos"])))["moved"] or c.deploy.home()["ok"]:
					_bad("%s: something else was done while a fight waited" % when)
				seen["refused"] += 1
				var out := _fight(c, when)
				_sound(c, when + ", after the fight")
				if rng.randf() < 0.25:
					_round_trip(c, when)
				var roll := rng.randf()
				if out.get("next") == "retry" and roll < 0.15:
					# given up
					var held: Dictionary = c.deploy.stock.duplicate(true)
					var haul_g: Dictionary = Loot.norm(c.deploy.cur()["haul"])
					var wo := c.deploy.wipe()
					seen["wipe"] += 1
					if c.deploy.active() or c.deploy.stock != _after_wipe(c, held, wo, haul_g, when):
						_bad("%s: giving up left the team out, or banked something" % when)
				elif out.get("next") == "retry" and roll < 0.5:
					# (0.41) withdrawn: the haul and the Heroes down as they were, the place left as it was
					var a_w: Dictionary = c.deploy.cur()["activity"]
					var haul_w: Dictionary = Loot.norm(c.deploy.cur()["haul"])
					var out_w: Array = c.deploy.cur()["heroesOut"].duplicate()
					var wd := c.deploy.withdraw()
					seen["withdraw"] += 1
					if not wd["ok"] or c.deploy.cur()["activity"] != null or Loot.norm(c.deploy.cur()["haul"]) != haul_w or c.deploy.cur()["heroesOut"] != out_w or c.deploy.withdraw()["ok"]:
						_bad("%s: withdrawing didn't go back to the map with the haul, once" % when)
					if a_w["kind"] == "poi" and w.is_cleared(a_w["tile"]):
						_bad("%s: withdrawing cleared the POI" % when)
				continue
			var here: String = cur["pos"]
			var content = w.content_at(here) if w.available(here) else null
			if content != null and content["kind"] == "poi" and rng.randf() < 0.85:
				var sp = c.deploy.enter_poi(here)
				seen["poi"] += 1
				if sp == null or sp["kind"] != "poi" or sp["count"] < 1 or sp["tile"] != here:
					_bad("%s: the POI on %s couldn't be entered" % [when, here])
				continue
			if content != null and content["kind"] == "cache" and rng.randf() < 0.9:
				var before: Dictionary = Loot.norm(cur["haul"])
				var got = c.deploy.open_cache(here)
				seen["cache"] += 1
				if got == null or Loot.norm(c.deploy.cur()["haul"]) != Loot.add(before, got["bag"]) or not w.is_cleared(here) or c.deploy.open_cache(here) != null:
					_bad("%s: the Cache on %s didn't open once, into the haul" % [when, here])
				cleared_once[here] = true
				_sound(c, when + ", a Cache opened")
				continue
			if content != null and content["kind"] == "event" and rng.randf() < 0.9:
				var ev: Dictionary = c.deploy.event_at(here)
				var i2 := rng.randi_range(0, ev["choices"].size() - 1)
				var before2: Dictionary = Loot.norm(cur["haul"])
				var o = c.deploy.choose(here, i2)
				seen["event"] += 1
				if o == null or not w.is_cleared(here) or c.deploy.choose(here, i2) != null:
					_bad("%s: the Event on %s wasn't chosen once" % [when, here])
				else:
					if o["check"] != 0.0:
						seen["check_won" if o["won"] else "check_failed"] += 1
						if o["roll"] < 1 or o["roll"] > 20 or o["won"] != (o["roll"] >= o["check"]):
							_bad("%s: a check of %s rolled %d and %s" % [when, str(o["check"]), o["roll"], "won" if o["won"] else "failed"])
					var after: Dictionary = Loot.norm(c.deploy.cur()["haul"])
					var owed := Loot.add(before2, o["got"])
					if o["lost"] != null:
						owed["shards"] -= o["lost"]["shards"]
						for ty in Loot.TYPES:
							for rr in 6:
								owed["parts"][ty["id"]][rr] -= o["lost"]["parts"][ty["id"]][rr]
					if after != owed:
						_bad("%s: an Event left the haul at %s" % [when, c.loot.text(after)])
					if o["fight"]:
						seen["event_fight"] += 1
						if c.deploy.cur()["activity"] == null or not c.deploy.cur()["activity"]["fromEvent"]:
							_bad("%s: an Event that starts a fight started none" % when)
				cleared_once[here] = true
				_sound(c, when + ", an Event chosen")
				continue
			if here == w.dock() and int(cur["steps"]) > 0 and rng.randf() < 0.55:
				break                     # home, below
			if goal == "" or goal == here or w.path(here, goal).is_empty():
				var near: Array = w.map["tiles"].keys().filter(func(k): return not visited.has(k) and w.available(k) and World.dist(k, here) <= 8 and k != w.dock())
				goal = w.dock() if (budget < 14 or near.is_empty() or rng.randf() < 0.1) else _pick(near)
				if goal == here:
					goal = _pick(World.neighbours(here).filter(func(k): return w.is_open(k)))
			var way := w.path(here, goal)
			var st := c.deploy.step_to(way[1])
			seen["steps"] += 1
			visited[way[1]] = true
			if not st["moved"] or c.deploy.cur()["pos"] != way[1] or not w.known(way[1]):
				_bad("%s: a step to %s went nowhere" % [when, way[1]])
			if rng.randf() < 0.1:
				_round_trip(c, when)
			if st["ambush"]:
				var tile_ambush: bool = Rules.truthy(st.get("tileAmbush"))
				seen["tile_ambush" if tile_ambush else "ambush"] += 1
				if c.deploy.ambush(way[1], {"tileAmbush": tile_ambush}) == null:
					_bad("%s: an ambush with no floor to fight on" % when)
				if tile_ambush:
					cleared_once[way[1]] = true
				goal = ""
			_sound(c, when)
		if not c.deploy.active():
			# wiped out: nothing reached the dock but what insurance kept
			if c.deploy.stock != Loot.add(stock0, last_kept):
				_bad("deployment %d was wiped out and the stockpile changed" % n)
			if w.state["completed"] != done0 + 1:
				_bad("deployment %d ended and %d are counted" % [n, w.state["completed"]])
			continue
		# walk home, fighting whatever is met on the way
		var guard := 0
		while c.deploy.active() and c.deploy.cur()["pos"] != w.dock() and guard < 200:
			guard += 1
			if c.deploy.cur()["activity"] != null:
				_fight(c, "deployment %d, on the way home" % n)
				continue
			var back := w.path(c.deploy.cur()["pos"], w.dock())
			var st2 := c.deploy.step_to(back[1])
			seen["steps"] += 1
			if st2["ambush"]:
				c.deploy.ambush(back[1], {"tileAmbush": Rules.truthy(st2.get("tileAmbush"))})
		while c.deploy.active() and c.deploy.cur()["activity"] != null:
			_fight(c, "deployment %d, at the dock" % n)
		if not c.deploy.active():
			continue
		var carried: Dictionary = Loot.norm(c.deploy.cur()["haul"])
		var found: Array = c.deploy.cur()["items"].duplicate()
		var pack_left: Dictionary = c.deploy.cur()["pack"].duplicate(true)
		var h := c.deploy.home()
		if not h["ok"] or c.deploy.active() or c.deploy.stock != _after_home(c, stock0, carried, pack_left, h, "home from deployment %d" % n) or h["haul"] != carried:
			_bad("deployment %d came home and the stockpile is %s" % [n, c.loot.text(c.deploy.stock)])
		if h["items"].size() != found.size():
			_bad("deployment %d found %s and kept %s" % [n, str(found), str(h["items"])])
		for it in found:
			var o2: Dictionary = Progress.parse_item(it)
			if (o2["kind"] == "bp" and c.progress.owned(o2["name"]) < o2["level"]) or (o2["kind"] == "ch" and not c.progress.has_chassis(o2["id"])):
				_bad("deployment %d brought %s home and it isn't owned" % [n, it])
		seen["home"] += 1
		seen["items_home"] += h["items"].size()
		if w.state["completed"] != done0 + 1 or c.deploy.history[0]["n"] != n or c.deploy.history[0]["result"] != "home":
			_bad("deployment %d came home and the count is %d" % [n, w.state["completed"]])
		_sound(c, "home from deployment %d" % n)
		_round_trip(c, "home from deployment %d" % n)
	Rules.hooks = {}


# ---------------------------------------------------------------- deployments, through the screen
var scene: Node2D


func _settled(what: String, limit := 6000) -> void:
	var n := 0
	while (scene.busy or scene.walking or scene.auto_phase or scene.map_screen.walking) and n < limit:
		await process_frame
		n += 1
	if n >= limit:
		_bad("the screen never settled: " + what)


## 0.10: the dock's tabs tapped by a random hand: whatever a row offers, the
## Testing row's questions answered either way. Nothing breaks, the books
## balance, what is saved is what is so, and the screen says what is so.
func _screen_dock(when: String) -> void:
	var cm: Campaign = scene.campaign
	var dk: DockScreen = scene.dock_screen
	var dock: Dock = cm.dock
	var gift := Loot.bag()
	gift["shards"] = rng.randi_range(0, 400)
	for ty in Loot.TYPES:
		gift["parts"][ty["id"]][rng.randi_range(0, 2)] += rng.randi_range(0, 12)
	dock.add_to_stockpile(gift)
	for k in rng.randi_range(6, 16):
		dk.show_tab(_pick(DockScreen.TABS)[0])
		var offers := dk.offers()
		if offers.is_empty():
			continue
		var a: Array = _pick(offers)
		if a == ["testing", "reset"] and rng.randf() < 0.8:
			continue                      # (now and then: it forgets the dock)
		var before := dock.stockpile()
		dk.act(a)
		seen["screen_dock_taps"] += 1
		var answer := -1
		if dk.dialog != null:
			answer = rng.randi_range(0, dk.dialog.buttons.size() - 1)
			dk.dialog.buttons[answer].pressed.emit()
			await process_frame
		if dk.dialog != null:
			_bad("%s: %s left a box open" % [when, str(a)])
			return
		_whole_bag(cm.deploy.stock, "the stockpile", when)
		var now := dock.stockpile()
		var changed: bool = now != before
		if changed and not (a[0] in ["buy_parts", "sell_parts", "buy_item", "buy_card", "sell_card", "buy_pre", "combine", "swap", "upgrade", "craft"]):
			_bad("%s: %s changed the stockpile" % [when, str(a)])
		var shards_said: bool = dk.note.text.contains("shards") or not changed
		if not shards_said and a[0] != "combine" and a[0] != "swap" and a[0] != "upgrade":
			_bad("%s: %s spent shards and said '%s'" % [when, str(a), dk.note.text])
		# what is saved is what is so (each change is saved as it is made)
		var saved = JSON.parse_string(FileAccess.get_file_as_string(Campaign.path)) if FileAccess.file_exists(Campaign.path) else null
		# (a Testing question answered "Not now" before anything was ever saved leaves no file, and
		# nothing to keep: the campaign starts as it is now)
		if (changed or a[0] == "testing") and not (saved == null and a[0] == "testing" and answer != 0 and not changed):
			if not (saved is Dictionary) or Rules.ints(saved.get("inventory")) != dock.inv or int(saved["dock"]["reach"]) != int(dock.state["reach"]) or Rules.ints(saved["dock"]["upgrades"]) != dock.state["upgrades"]:
				_bad("%s: after %s, what is saved isn't what is so" % [when, str(a)])
		# and the dock says what is so
		dk.show_tab("exchange")
		if not dk.hint.text.begins_with("Everything is paid in Aether shards; you hold %d." % dock.stockpile()["shards"]):
			_bad("%s: the Exchange says '%s', and the stockpile holds %d shards" % [when, dk.hint.text.left(60), dock.stockpile()["shards"]])
		dk.show_tab("stockpile")
		var kept := (dk.kept_lines() + dk.stash_lines()).map(func(l): return l["text"])
		for nm in dock.inv["cards"]:
			if not kept.has("%d × %s" % [dock.owned(nm), nm]):
				_bad("%s: the dock holds %d %s and lists %s" % [when, dock.owned(nm), nm, str(kept)])
	dk.show_tab("stockpile")
	if not dk.visible:
		_bad("%s: the dock isn't showing" % when)


## What the screen shows is what is so.
func _screen_true(when: String) -> void:
	var cm: Campaign = scene.campaign
	var ms: MapScreen = scene.map_screen
	var cur = cm.deploy.cur()
	if not ms.visible:
		return
	if (cur != null) != (scene.map_view.team_at != "") or (cur != null and scene.map_view.team_at != cur["pos"]):
		_bad("%s: the marker is on '%s' and the team on %s" % [when, scene.map_view.team_at, str(cur["pos"]) if cur != null else "nothing"])
	if cur != null and ms.status_label.text != ms.status_text():
		_bad("%s: the bar's count is stale" % when)
	var ids: Array = ms.actions().map(func(a): return a["id"])
	# (0.41) and Withdraw, after a lost fight with a Hero standing
	if cur != null and cur["activity"] != null and ids != (["fight", "withdraw"] if cm.deploy.can_withdraw() else ["fight"]):
		_bad("%s: a fight waits and the panel offers %s" % [when, str(ids)])
	if cur == null and (ids.has("walk") or ids.has("fight") or ids.has("home") or ids.has("enter") or ids.has("cache") or ids.has("choose")):
		_bad("%s: nobody is out and the panel offers %s" % [when, str(ids)])
	if ids.has("home") and (cur == null or cur["pos"] != cm.world.dock()):
		_bad("%s: Come home is offered away from the dock" % when)
	var saved = JSON.parse_string(FileAccess.get_file_as_string(Campaign.path)) if FileAccess.file_exists(Campaign.path) else null
	if cur != null and (not (saved is Dictionary) or not (saved.get("deployment") is Dictionary) or saved["deployment"]["pos"] != cur["pos"] or int(saved["deployment"]["steps"]) != int(cur["steps"]) or int(saved["deployment"]["fights"]) != int(cur["fights"])):
		_bad("%s: what is saved is behind what is so" % when)


## The fight that is waiting, from its setup to its result box, on Auto.
func _screen_fight(when: String) -> void:
	var cm: Campaign = scene.campaign
	var ms: MapScreen = scene.map_screen
	var s: SetupScreen = scene.setup
	ms.do("fight")
	await process_frame
	await process_frame
	if not s.visible or s.mode != "deploy" or s.step != "heroes":
		_bad("%s: Fight didn't open the setup" % when)
		return
	if s.team()["heroes"] != cm.deploy.hero_names():
		_bad("%s: the setup lists %s, and %s stand" % [when, str(s.team()["heroes"]), str(cm.deploy.hero_names())])
	# sometimes fewer go in, to leave reserves
	if s.heroes.size() > 1 and rng.randf() < 0.4:
		s.toggle_hero(s.heroes[s.heroes.size() - 1])
	s._go(1)
	var ts := StrikeTeams.troops_in_deck(s.team(), scene.roster)
	if not ts.is_empty() and rng.randf() < 0.5:
		s.more_troop(str(_pick(ts)["card"]["name"]))
	s.next_btn.pressed.emit()
	for i in 4:
		await process_frame
	var bt: Battle = scene.battle
	if bt == null or bt.deploy == null or s.visible or scene.map_view.visible:
		_bad("%s: the fight didn't start" % when)
		return
	seen["screen_fights"] += 1
	if OS.get_environment("SOAK_TRACE") != "":
		print("TRACE   fight begun on ", bt.floor_data.name)
	if not scene.auto:
		scene.auto_btn.pressed.emit()
		await process_frame
	var rounds := 0
	while not bt.over and rounds < 3 and wrong.is_empty():
		scene.end_turn()              # not waited for: a card problem's box stops it until OK
		var n := 0
		await process_frame
		while (scene.busy or scene.auto_phase or scene.enemy_phase or scene.upkeep or scene.dialog != null) and n < 8000:
			if scene.dialog != null:
				if bt.over:
					break                 # the result is up
				seen["screen_boxes"] += 1
				scene.dialog.buttons[scene.dialog.buttons.size() - 1].pressed.emit()
			await process_frame
			n += 1
		if n >= 8000:
			_bad("%s: round %d of the fight never ended" % [when, rounds])
		rounds += 1
	if not bt.over:
		var win := rng.randf() < 0.6
		for u in bt.side_units("enemy" if win else "ally"):
			u["hp"] = 0
			u["down"] = true
		if win:
			bt.wave = bt.waves_total
			bt.enemy_pile.clear()
			bt.fx.check_downs()
		bt.settle()
		scene.board.refresh_units(bt)
		scene.show_result()
	for i in 4:
		await process_frame
	await _settled(when + ", the result")
	if scene.dialog == null:
		scene.show_result()
		await process_frame
	if scene.dialog == null or scene.deploy_out.is_empty():
		_bad("%s: the fight ended and no result came up" % when)
		return
	var next: String = str(scene.deploy_out.get("next"))
	var labels: Array = scene.dialog.buttons.map(func(b): return b.text)
	var fights_now: int = cm.deploy.s["fights"]
	# See the board and back: the deployment is told once
	if rng.randf() < 0.3:
		scene.dialog.buttons[labels.size() - 1].pressed.emit()
		await process_frame
		scene.ask_leave()
		await process_frame
		if scene.dialog == null or int(cm.deploy.s["fights"]) != fights_now:
			_bad("%s: looking at the board told the deployment twice" % when)
			return
	match next:
		"floor":
			if not labels[0].begins_with("Next floor ("):
				_bad("%s: a next floor, and the box offers %s" % [when, str(labels)])
			scene.dialog.buttons[0].pressed.emit()
			await process_frame
			await process_frame
			if not s.visible or s.mode != "deploy":
				_bad("%s: Next floor didn't set the next one up" % when)
			s.back_btn.pressed.emit()       # back to the map; the next floor waits there
		"retry":
			if labels.slice(0, 3) != ["Retry with reserves", "Withdraw: back to the map with the haul", "Give up: lose the haul"]:
				_bad("%s: a fight to try again, and the box offers %s" % [when, str(labels)])
			var roll := rng.randf()
			if roll < 0.25:
				scene.dialog.buttons[2].pressed.emit()
				await process_frame
				if scene.dialog == null or scene.dialog.title_label.text != "Deployment lost" or cm.deploy.active():
					_bad("%s: giving up didn't end the deployment" % when)
				else:
					scene.dialog.buttons[0].pressed.emit()
			elif roll < 0.45:
				# (0.41) withdrawn: back on the map, the team still out, nothing waiting
				var haul_w: Dictionary = Loot.norm(cm.deploy.cur()["haul"])
				scene.dialog.buttons[1].pressed.emit()
				await process_frame
				if not cm.deploy.active() or cm.deploy.cur()["activity"] != null or Loot.norm(cm.deploy.cur()["haul"]) != haul_w:
					_bad("%s: withdrawing didn't leave the team on the map with its haul" % when)
				seen["withdraw"] += 1
			else:
				scene.dialog.buttons[0].pressed.emit()
				await process_frame
				await process_frame
				s.back_btn.pressed.emit()
		_:
			if labels[0] != "Back to the map":
				_bad("%s: '%s', and the box offers %s" % [when, next, str(labels)])
			scene.dialog.buttons[0].pressed.emit()
	for i in 4:
		await process_frame
	if not ms.visible or scene.battle != null or scene.dialog != null:
		_bad("%s: after the fight the map isn't what the screen shows" % when)
	_screen_true(when + ", after the fight")


func _screen(want: int) -> void:
	Engine.time_scale = 30.0
	root.size = Vector2i(1280, 720)
	Kit.fresh()
	var teams := []
	for i in 3:
		# (the starter's free copies only: nothing to pay with yet)
		var t := Kit.field_random(r, rng, "Screen %d" % i)
		t["deck"]["Frame Trooper"] = rng.randi_range(1, 4)
		for n in t["deck"].keys():
			var tc = r.card_named(str(n))
			if tc != null and tc.get("_src") == "workshop" and n != "Frame Trooper":
				t["deck"].erase(n)        # (the designs made above are another campaign's)
		teams.append(t)
	Kit.keep(teams)
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	var cm: Campaign = scene.campaign
	var ms: MapScreen = scene.map_screen
	var dk: DockScreen = scene.dock_screen
	for d in want:
		if not wrong.is_empty():
			break
		scene.show_home()
		scene.home.world_btn.pressed.emit()
		await process_frame
		if not dk.visible:
			_bad("screen deployment %d: World Map didn't open the dock" % d)
			break
		await _screen_dock("screen deployment %d, at the dock" % d)
		if not wrong.is_empty():
			break
		# 0.10: shards given, and spent at the Exchange through its chips
		var gift := Loot.bag()
		gift["shards"] = 90
		cm.dock.add_to_stockpile(gift)
		dk.show_tab("exchange")
		var price_of := func(a: Array) -> float:
			if a[0] == "buy_card":
				return float(cm.dock.item_price(a[1])) * int(a[2])
			var pd = cm.workshop.get_design(a[1])
			return float(cm.dock.pre_cost(pd)) * int(a[2]) if pd != null else INF
		var buys: Array = dk.offers().filter(func(a): return (a[0] == "buy_card" or a[0] == "buy_pre") and price_of.call(a) <= float(cm.dock.stockpile()["shards"]))
		if buys.is_empty():
			_bad("screen deployment %d: the Exchange offers nothing to buy: %s" % [d, str(dk.offers()).left(200)])
		else:
			var buy: Array = _pick(buys)
			var sh0: int = cm.dock.stockpile()["shards"]
			var inv0: Dictionary = cm.dock.inv.duplicate(true)
			dk.act(buy)
			await process_frame
			if cm.dock.stockpile()["shards"] >= sh0 or cm.dock.inv == inv0:
				_bad("screen deployment %d: %s through the screen didn't buy, or cost nothing" % [d, str(buy)])
			seen["screen_bought"] += 1
			if dk.dialog != null:
				dk.dialog.buttons[0].pressed.emit()
				await process_frame
		dk.show_tab("stockpile")
		var stock0: Dictionary = cm.deploy.stock.duplicate(true)
		if dk.row_texts()[1] != "%d Aether shard%s" % [stock0["shards"], "" if stock0["shards"] == 1 else "s"]:
			_bad("screen deployment %d: the dock says '%s' and the stockpile has %d shards" % [d, dk.row_texts()[1], stock0["shards"]])
		var claimed0: Array = cm.dock.bounties().filter(func(b): return Rules.truthy(b.get("claimed"))).map(func(b): return b["name"])
		dk.go_btn.pressed.emit()
		dk.choose_team(d % 3)
		var inv_out: Dictionary = cm.dock.inv.duplicate(true)
		for nm in dk.pack:
			inv_out["cards"][nm] = int(inv_out["cards"][nm]) - int(dk.pack[nm])
			if inv_out["cards"][nm] == 0:
				inv_out["cards"].erase(nm)
		inv_out["pre"] = {}
		dk.go_btn.pressed.emit()
		for i in 4:
			await process_frame
		if not cm.deploy.active() or not ms.visible:
			_bad("screen deployment %d: it didn't leave the dock" % d)
			break
		seen["screen_deployments"] += 1
		if cm.dock.inv != inv_out or not cm.dock.closed():
			_bad("screen deployment %d: it left packing %s, and the dock holds %s" % [d, str(dk.pack), str(cm.dock.inv)])
		cm.world.tables["ambushStep"] = [5, 5, 30, 0][d % 4]
		_screen_true("screen deployment %d, leaving" % d)
		var acts := rng.randi_range(8, 18)
		while acts > 0 and cm.deploy.active() and wrong.is_empty():
			acts -= 1
			var cur: Dictionary = cm.deploy.cur()
			var when := "screen deployment %d, step %d" % [d, int(cur["steps"])]
			if OS.get_environment("SOAK_TRACE") != "":
				print("TRACE ", when, " acts ", acts, " activity ", cur["activity"] != null)
			if cur["activity"] != null:
				await _screen_fight(when)
				continue
			var ids: Array = ms.actions().map(func(a): return a["id"])
			ms.tap(cur["pos"])
			ids = ms.actions().map(func(a): return a["id"])
			var special := ids.filter(func(i): return i == "enter" or i == "cache" or i == "choose")
			if not special.is_empty() and rng.randf() < 0.85:
				var at: int = ids.find(special[0]) if special[0] != "choose" else rng.randi_range(0, ids.size() - 1)
				ms.act(at)
				await process_frame
				_screen_true(when + ", after " + str(special[0]))
				continue
			# somewhere to walk: something seen and not yet seen to, or anywhere near
			var near: Array = cm.world.map["tiles"].keys().filter(func(k): return World.dist(k, cur["pos"]) <= 5 and World.dist(k, cur["pos"]) >= 1 and cm.world.is_open(k))
			var worth: Array = near.filter(func(k): return cm.world.known(k) and cm.world.available(k))
			var to: String = _pick(worth) if (not worth.is_empty() and rng.randf() < 0.7) else _pick(near)
			ms.tap(to)
			if not ms.actions().any(func(a): return a["id"] == "walk"):
				continue                  # no way through
			if scene.map_view.route.is_empty() or scene.map_view.route[scene.map_view.route.size() - 1] != to:
				_bad("%s: the way shown doesn't lead to the tile chosen" % when)
			ms.act(ms.actions().map(func(a): return a["id"]).find("walk"))
			seen["screen_walks"] += 1
			if rng.randf() < 0.15:
				await process_frame
				ms.do("stop")
			await _settled(when + ", a walk")
			for i in 2:
				await process_frame
			_screen_true(when + ", after a walk")
		# home, if the team still stands: walk back, fighting what is met
		var guard := 0
		while cm.deploy.active() and wrong.is_empty() and guard < 60:
			guard += 1
			var cur2: Dictionary = cm.deploy.cur()
			if cur2["activity"] != null:
				await _screen_fight("screen deployment %d, on the way home" % d)
				continue
			if cur2["pos"] == cm.world.dock():
				break
			ms.tap(cm.world.dock())
			ms.act(ms.actions().map(func(a): return a["id"]).find("walk"))
			await _settled("screen deployment %d, walking home" % d)
			for i in 2:
				await process_frame
		if cm.deploy.active() and wrong.is_empty():
			var carried: Dictionary = Loot.norm(cm.deploy.cur()["haul"])
			ms.tap(cm.world.dock())
			var home_at: int = ms.actions().map(func(a): return a["id"]).find("home")
			if home_at < 0:
				_bad("screen deployment %d: on the dock, and Come home isn't offered" % d)
				break
			var pack_back: Dictionary = cm.deploy.cur()["pack"].duplicate(true)
			ms.act(home_at)
			await process_frame
			var owed := Loot.add(stock0, carried)
			var paid: Array = ms.last_home.get("dock", {}).get("bounties", []) if ms.last_home.get("dock") is Dictionary else []
			for b in paid:
				owed = Loot.add(owed, b["bag"])
				if claimed0.has(b["name"]):
					_bad("screen deployment %d: the bounty on %s was paid twice" % [d, b["name"]])
			seen["bounties_paid"] += paid.size()
			if cm.deploy.active() or ms.dialog == null or ms.dialog.title_label.text != "Home" or cm.deploy.stock != owed:
				_bad("screen deployment %d: Come home didn't bank the haul" % d)
				break
			for part in ["cons", "protos"]:
				for nm in pack_back.get(part, {}):
					if int(pack_back[part][nm]) > 0:
						inv_out["cards"][nm] = int(inv_out["cards"].get(nm, 0)) + int(pack_back[part][nm])
			# (0.22) and a card found on the way is kept there
			for it in ms.last_home.get("items", []):
				if str(it).begins_with("cd:"):
					var cn := str(it).substr(3)
					inv_out["cards"][cn] = int(inv_out["cards"].get(cn, 0)) + 1
			if cm.dock.inv != inv_out:
				_bad("screen deployment %d: home, and the dock holds %s, not %s" % [d, str(cm.dock.inv), str(inv_out)])
			if not paid.is_empty() and not ms.dialog.text_label.text.contains("Bounty on "):
				_bad("screen deployment %d: %d bounties paid and Home doesn't say so: %s" % [d, paid.size(), ms.dialog.text_label.text])
			seen["home"] += 1
			ms.dialog.buttons[0].pressed.emit()
			await process_frame
			if not dk.visible or dk.row_texts()[1] != "%d Aether shard%s" % [cm.deploy.stock["shards"], "" if cm.deploy.stock["shards"] == 1 else "s"]:
				_bad("screen deployment %d: the dock doesn't show what came home" % d)
		elif wrong.is_empty() and (cm.deploy.stock != Loot.add(stock0, _kept(cm, cm.deploy.history[0]["haul"])) or cm.dock.inv != inv_out):
			_bad("screen deployment %d was lost and the stockpile, or what the dock holds, changed" % d)
	scene.queue_free()
	await process_frame
	Engine.time_scale = 1.0
	Rules.hooks = {}


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var want := int(args[0]) if args.size() > 0 else 40
	rng.seed = 20261021      # (0.22: a new seed; card drops change every path, and the old one found almost nothing)
	Kit.fresh()
	x = KeterExport.new()
	x.open(FIXTURE)
	# (0.9: teams of designs bring down fewer Enemies than the 0.8 soak's did, so blueprints
	# and chassis drop ten times as often here as in play: enough are found to check)
	var srcs: Dictionary = x.content("tables").get("loot", {}).get("sources", {})
	for k in srcs:
		if srcs[k] is Dictionary:
			srcs[k]["bp"] = Scoring.num(srcs[k].get("bp"), 0.0) * 10.0
	r = Roster.new(x)
	floors = x.floors()
	if OS.get_environment("SOAK_SCREEN_ONLY") == "":
		_engine(want)
	await _screen(maxi(2, want / 5))
	for w in wrong.slice(0, 14):
		print("FAIL " + w)
	print("(%d deployments: %d steps, %d ambushes on the way and %d on their own tiles, %d POIs entered and %d cleared (%d next floors), %d Caches, %d Events (%d checks won, %d failed, %d into a fight))" % [
		seen["deployments"], seen["steps"], seen["ambush"], seen["tile_ambush"], seen["poi"], seen["poi_done"], seen["floor"], seen["cache"], seen["event"], seen["check_won"], seen["check_failed"], seen["event_fight"]])
	print("(%d fights in %d rounds: %d won, %d lost; %d tried again, %d withdrawn from, %d wipes, %d Emergency Exits; %d Heroes down, %d Troops lost, %d Consumables used; %d blueprints and chassis found, %d brought home; %d came home)" % [
		seen["fights"], seen["rounds"], seen["won"], seen["lost"], seen["retry"], seen["withdraw"], seen["wipe"], seen["escape"], seen["heroes_down"], seen["troops_lost"], seen["cons_used"], seen["items"], seen["items_home"], seen["home"]])
	print("(0.9: %d designs made with the builder; %d of their copies went out, %d into fights; %d Troop parts paid for copies; %d teams sent back for what they couldn't pay)" % [seen["designs"], seen["design_copies"], seen["designs_fought"], seen["paid"], seen["refused_leave"]])
	print("(0.10: %d Consumables and Prototypes bought, %d pre-built copies bought and %d taken out, %d upgrades; %d packed, %d back to the dock unused, %d lost with a wipe; %d bounties posted when teams left, %d fights with one, %d paid; insurance kept something %d times; %d restocks, the reach extended %d times; %d bought through the screen, and %d taps at the dock by a random hand)" % [
		seen["bought"], seen["pre_bought"], seen["pre_out"], seen["upgraded"], seen["packed"], seen["pack_home"], seen["pack_lost"], seen["bounties_posted"], seen["bounty_fights"], seen["bounties_paid"], seen["insured"], seen["restocks"], seen["reach"], seen["screen_bought"], seen["screen_dock_taps"]])
	print("(saved and read back %d times; %d cleared tiles came back; through the screen: %d deployments, %d walks, %d fights)" % [seen["saves"], seen["respawned"], seen["screen_deployments"], seen["screen_walks"], seen["screen_fights"]])
	# (0.13: the master Enemies aim at 8 to 10 now, so more teams are wiped and fewer
	# finds come home: one brought home is enough to show they are kept)
	if want >= 40 and (seen["poi_done"] < 3 or seen["cache"] < 10 or seen["event"] < 8 or seen["retry"] < 3 or seen["wipe"] < 2 or seen["home"] < 8 or seen["items_home"] < 1 or seen["troops_lost"] < 2 or seen["cons_used"] < 5 or seen["screen_fights"] < 3
			or seen["designs"] < 3 or seen["design_copies"] < 5 or seen["designs_fought"] < 3 or seen["paid"] < 1 or seen["refused_leave"] < 1
			or seen["bought"] < 5 or seen["pre_out"] < 1 or seen["upgraded"] < 1 or seen["packed"] < 10 or seen["pack_home"] < 2 or seen["pack_lost"] < 1 or seen["bounty_fights"] < 1 or seen["bounties_paid"] < 1
			or seen["insured"] < 1 or seen["restocks"] < 3 or seen["screen_bought"] < 1 or seen["screen_dock_taps"] < 20):
		wrong.append("too little of it was tried: %s" % str(seen))
		print("FAIL " + wrong[wrong.size() - 1])
	Kit.fresh()
	print("\nWORLD SOAK PASS %d  FAIL %d" % [(seen["deployments"] + seen["screen_deployments"]) if wrong.is_empty() else 0, wrong.size()])
	quit(1 if not wrong.is_empty() else 0)
