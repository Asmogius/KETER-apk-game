## The balance lab's campaigns (not a test): a stand-in player plays a whole
## run from a new save, on the content the game ships with: deployment after
## deployment from the dock, until every District is cleared or the run gives
## out. Each deployment, and then the run, is written out as a line of JSON for
## balance_lab.py to gather.
##
## At the dock, between deployments, the player:
## - begins with the starter stash, and picks the rarest card offered;
## - recruits a Hero on offer that is rarer than the weakest of its best three,
##   while it can pay and keep a reserve;
## - crafts Uncommon and rarer cards (District 3's or none) it holds fewer
##   than two of, the rarest first, with what is left;
## - raises Salvage insurance, then Exchange stock, when it can spare them.
## Its Strike Team is its best three Heroes (rarest first), and a Deck of 4
## Frame Troopers, the best Common Troops, every Uncommon or rarer card it
## holds (4 at most), then free Common cards to 20; Action cards and Chips
## likewise; and the Consumables it holds.
##
## On the World Map it knows where everything is (a real player has to find
## it). It aims at a Skull Level (from 1): the nearest POI there, and walks
## there; opens Caches on the way and makes a choice at Events; fights every
## ambush; then, with every Hero standing and fewer than two POIs behind it,
## goes on to the next, or else walks home. Two trips home in a row that
## cleared a POI at its aim with every Hero standing raise its aim a Skull
## Level; a wipe lowers it one. With its aim at Skull 6 passed (two clean Skull 6
## trips) it goes for the nearest Core instead. It raises its Frame Troopers to
## Mk II and Mk III as Troop parts allow. Every fight is played by
## lab_player.gd, careful or casual; one still going at round 40 is lost.
## It makes no designs in the Workshop: its Troops are the free ones.
## What-ifs (lab only, the game is untouched): d3floors=1 fights every
## District's floors on battlefields grown from District 3's chunks, as if
## every District had content of its own like District 3's; keepheroes=1 keeps
## the recruited Heroes through a wipe, and keepcards=1 the cards it took;
## retreat=1 lets a team that loses a fight give up that POI or ambush and walk
## home with its haul, instead of trying again until it is wiped out.
##   godot --headless --path . --script res://tests/lab_campaign.gd -- export=<zip> bot=<careful|casual> seed=<n> most=<deployments> out=<file> [d3floors=1]
extends SceneTree

const Kit := preload("res://tests/team_kit.gd")
const LabPlayer := preload("res://tests/lab_player.gd")
const RESERVE := 40                  # shards kept back when recruiting

var rng := RandomNumberGenerator.new()
var player: LabPlayer
var bot := "careful"
var x: KeterExport
var r: Roster
var floors: Array = []
var out_file: FileAccess
# the run so far
var comfort := 0                     # the Skull Level it aims at, less one (lowered by a wipe)
var clean := 0                       # trips home in a row at its aim, every Hero standing and a POI cleared there
var first_stash := true
var tally := {}                      # this deployment's counts
var d3floors := false                # (what-if) every District on District 3's kind of floor
var keepheroes := false              # (what-if) a wipe keeps the recruited Heroes
var keepcards := false               # (what-if) and the cards taken
var retreat := false                 # (what-if) a lost fight: give the place up and go home
var retreating := false


func _initialize() -> void:
	_run.call_deferred()


func _args() -> Dictionary:
	var o := {"export": "", "bot": "careful", "seed": "1", "most": "150", "out": "", "d3floors": "0", "keepheroes": "0", "keepcards": "0", "retreat": "0"}
	for a in OS.get_cmdline_user_args():
		var kv := str(a).split("=", true, 1)
		if kv.size() == 2:
			o[kv[0]] = kv[1]
	return o


func _run() -> void:
	var o := _args()
	Kit.fresh()
	# a real run: Heroes and cards are only what it has; Common designs go out free
	Dock.every_hero = false
	Dock.every_card = false
	Deployment.common_designs_free = true
	x = KeterExport.new()
	if not x.open(o["export"]):
		printerr("can't open the export: " + str(o["export"]))
		quit(2)
		return
	r = Roster.new(x)
	floors = x.floors()
	bot = str(o["bot"])
	d3floors = str(o["d3floors"]) == "1"
	keepheroes = str(o["keepheroes"]) == "1"
	keepcards = str(o["keepcards"]) == "1"
	retreat = str(o["retreat"]) == "1"
	rng.seed = int(o["seed"])
	player = LabPlayer.new(bot, rng)
	var c := Campaign.new(x, r, floors, int(o["seed"]))
	r.progress = c.progress
	out_file = FileAccess.open(str(o["out"]), FileAccess.WRITE)
	var most := int(o["most"])
	var run := {"seed": int(o["seed"]), "bot": bot, "d3floors": d3floors, "keepheroes": keepheroes, "keepcards": keepcards, "retreat": retreat, "deployments": 0, "wipes": 0, "first_district": 0, "all_districts": 0,
		"rank_at": {}, "districts_at": [], "comfort_at": {}, "error": ""}
	for n in range(1, most + 1):
		var line := _deployment(c, n)
		run["deployments"] = n
		if line.get("error"):
			run["error"] = str(line["error"])
			_write(line)
			break
		if line["result"] == "wipe":
			run["wipes"] += 1
		var rank: int = c.dock.rank()
		if not run["rank_at"].has(str(rank)):
			run["rank_at"][str(rank)] = n
		if not run["comfort_at"].has(str(comfort)):
			run["comfort_at"][str(comfort)] = n
		var dn: int = c.world.districts_cleared().size()
		while run["districts_at"].size() < dn:
			run["districts_at"].append(n)
		if dn >= 1 and run["first_district"] == 0:
			run["first_district"] = n
		_write(line)
		if dn >= 6:
			run["all_districts"] = n
			break
	run["final"] = {"rank": c.dock.rank(), "merits": c.dock.merits(), "comfort": comfort, "shards": int(c.deploy.stock["shards"]),
		"heroes": _heroes(c).map(func(h): return str(h["name"])), "districts": c.world.districts_cleared().size(),
		"cards": c.dock.inv["cards"].duplicate()}
	run["summary"] = true
	_write(run)
	out_file.close()
	quit(0)


func _write(d: Dictionary) -> void:
	out_file.store_line(JSON.stringify(d))
	out_file.flush()


# ---------------------------------------------------------------- at the dock
static func power(card) -> float:
	if not (card is Dictionary):
		return 0.0
	var st = Roster.unit_spec(card).get("stats", {})
	return Dock.hero_rarity(card) * 100.0 + float(Rules.num(st.get("hp") if st is Dictionary else 0, 0))


## The Heroes it may take, best first.
func _heroes(c: Campaign) -> Array:
	var hs: Array = c.dock.hero_cards().filter(func(h): return not Dock.is_test_hero(h) and c.dock.owns(str(h["name"])))
	hs.sort_custom(func(a, b): return power(a) > power(b))
	return hs


func _usable(card) -> bool:
	return card is Dictionary and not Roster.is_test(card) and not str(card.get("name", "")).begins_with("Test ") \
		and not ["design", "prebuilt", "workshop"].has(str(card.get("_src", ""))) and Roster.district_of(card) in ["", "3", "any", "neu"]


func _shop(c: Campaign) -> Dictionary:
	var dk := c.dock
	var did := {"recruited": [], "crafted": [], "upgraded": []}
	if first_stash:
		first_stash = false
		dk.begin_stash(false)
		var offer: Array = dk.rare_offer()
		if not offer.is_empty():
			offer.sort_custom(func(a, b): return Dock.hero_rarity(dk.card_of(a)) > Dock.hero_rarity(dk.card_of(b)))
			dk.pick_rare(str(offer[0]))
	# a Hero, if one on offer beats the weakest of the best three
	var on: Array = dk.stock().get("heroes", [])
	var best := _heroes(c)
	var weakest := power(best[mini(2, best.size() - 1)]) if best.size() >= 3 else -1.0
	var cands: Array = on.filter(func(n): return not dk.owns(str(n)) and dk.card_of(str(n)) != null and power(dk.card_of(str(n))) > weakest)
	cands.sort_custom(func(a, b): return power(dk.card_of(a)) > power(dk.card_of(b)))
	for n in cands:
		if dk.stockpile()["shards"] >= float(dk.hero_price(str(n))) + RESERVE and dk.recruit(str(n))["ok"]:
			did["recruited"].append(str(n))
			break
	# its Frame Troopers raised a Mark, with Troop parts (the one design it has)
	if c.workshop.upgrade(Workshop.STARTER["id"], c.deploy.stock)["ok"]:
		did["upgraded"].append("Frame Trooper Mk")
	# upgrades it can spare
	for id in ["insurance", "exchange"]:
		var cost = dk.next_cost(id)
		if cost != null and dk.stockpile()["shards"] >= float(cost["shards"]) + 2 * RESERVE and dk.upgrade(id)["ok"]:
			did["upgraded"].append(id)
	# cards: the rarest it can craft first, up to two of each
	var craftable: Array = r.cards.filter(func(cd): return _usable(cd) and Dock.is_limited(cd))
	craftable.sort_custom(func(a, b): return Dock.hero_rarity(a) > Dock.hero_rarity(b) if Dock.hero_rarity(a) != Dock.hero_rarity(b) else str(a["name"]) < str(b["name"]))
	for cd in craftable:
		var nm := str(cd["name"])
		while dk.owned(nm) < 2:
			var cc = dk.craft_cost(nm)
			if cc == null or dk.stockpile()["shards"] < float(cc["shards"]) + RESERVE:
				break
			if not dk.craft(nm, 1)["ok"]:
				break
			did["crafted"].append(nm)
	return did


## Its Strike Team, from what it has now.
func _team(c: Campaign) -> Dictionary:
	var dk := c.dock
	var t := StrikeTeams.blank("Lab run")
	t["heroes"] = _heroes(c).slice(0, 3).map(func(h): return str(h["name"]))
	t["level"] = dk.rank()
	var held := func(cd) -> int: return dk.owned(str(cd["name"])) if Dock.is_limited(cd) else 4
	var best := func(types: Array, limited: bool) -> Array:
		var cs: Array = r.of_types(types).filter(func(cd): return _usable(cd) and Dock.is_limited(cd) == limited and (not limited or dk.owned(str(cd["name"])) > 0))
		cs.sort_custom(func(a, b): return Dock.hero_rarity(a) > Dock.hero_rarity(b) if Dock.hero_rarity(a) != Dock.hero_rarity(b) else power(a) > power(b) if power(a) != power(b) else str(a["name"]) < str(b["name"]))
		return cs
	t["deck"]["Frame Trooper"] = 4
	for cd in best.call(["troop"], false).filter(func(cd): return Dock.hero_rarity(cd) == 0).slice(0, 2):
		t["deck"][str(cd["name"])] = 3
	for cd in best.call(["equipment", "command", "aether"], true):
		if StrikeTeams.deck_count(t) >= 20:
			break
		t["deck"][str(cd["name"])] = mini(mini(4, held.call(cd)), 20 - StrikeTeams.deck_count(t))
	for cd in best.call(["equipment", "command", "aether"], false):
		if StrikeTeams.deck_count(t) >= 20:
			break
		t["deck"][str(cd["name"])] = mini(2, 20 - StrikeTeams.deck_count(t))
	# Action cards for each Hero, held ones first
	var acts: Array = best.call(["action"], true)
	var spare := {}
	for cd in acts:
		spare[str(cd["name"])] = dk.owned(str(cd["name"]))
	acts.append_array(best.call(["action"], false))
	for h in StrikeTeams.heroes(t, r):
		var mine := []
		for cd in acts:
			if mine.size() >= StrikeTeams.action_slots(h):
				break
			var nm := str(cd["name"])
			if spare.has(nm):
				if int(spare[nm]) <= 0:
					continue
				spare[nm] = int(spare[nm]) - 1
			mine.append(nm)
		if not mine.is_empty():
			t["actions"][str(h["name"])] = mine
	# the Pouch: Chips with an effect it holds, then Basic Chips for the Player Level
	for cd in best.call(["sphere"], true):
		t["pouch"][str(cd["name"])] = mini(2, dk.owned(str(cd["name"])))
	TeamGuide.suggest_pouch(t, r)
	var want := maxi(10, StrikeTeams.pouch_minimum(t, r)) + 2 * int(t["level"])
	if StrikeTeams.pouch_count(t, r) < want:
		StrikeTeams.set_chips(t, "basic|3", int(Rules.num(t["pouch"].get("basic|3"), 0)) + want - StrikeTeams.pouch_count(t, r))
	# the Consumables it holds, three of each at most
	t["consumables"] = {}
	for nm in dk.inv["cards"]:
		var cd = r.card_named(str(nm))
		if cd != null and Roster.type_of(cd) == "consumable" and dk.owned(str(nm)) > 0:
			t["consumables"][str(nm)] = mini(3, dk.owned(str(nm)))
	return t


# ---------------------------------------------------------------- a deployment
func _deployment(c: Campaign, n: int) -> Dictionary:
	var dep := c.deploy
	var w := c.world
	tally = {"fights": 0, "won": 0, "lost": 0, "ambushes": 0, "pois": 0, "poi_skulls": [], "cores": 0, "core_tries": 0, "heroes_down": 0,
		"caches": 0, "events": 0, "steps": 0, "rounds": 0}
	var shop := _shop(c)
	var team := _team(c)
	var pack := dep.default_pack(team)
	var why := dep.reasons_against(team, pack)
	if not why.is_empty():
		# what it can't take stays behind: held cards first, then the Consumables
		team["consumables"] = {}
		pack = dep.default_pack(team)
		why = dep.reasons_against(team, pack)
	if not why.is_empty():
		return {"n": n, "error": "can't leave: " + str(why)}
	var stock0 := Loot.norm(dep.stock)
	var heroes0: Dictionary = c.dock.state["heroes"].duplicate(true)
	var cards0: Dictionary = c.dock.inv["cards"].duplicate(true)
	var started := dep.start(team, pack)
	if not started["ok"]:
		return {"n": n, "error": "start refused: " + str(started.get("reasons"))}
	var target := mini(6, comfort + 1)
	var line := {"n": n, "target": target, "rank": c.dock.rank(), "heroes": team["heroes"].duplicate(), "deck": StrikeTeams.deck_count(team),
		"held": c.dock.inv["cards"].size(), "shop": shop, "shards_before": int(stock0["shards"]), "districts_before": w.districts_cleared().size()}
	var pois_done := 0
	var guard := 0
	retreating = false
	var goal := _goal(c, target)
	line["goal"] = goal.duplicate()
	while dep.active() and guard < 400:
		guard += 1
		var cur: Dictionary = dep.cur()
		if cur["activity"] != null:
			_fights(c)
			continue
		var here: String = cur["pos"]
		if retreating and goal.get("home") != true:
			goal = {"tile": w.dock(), "home": true}
		if goal.is_empty() or (goal.get("tile") == here and not w.available(here)):
			# done here: on to another POI, or home
			var standing: bool = cur["heroesOut"].is_empty()
			if goal.get("tile") == here and goal.get("home") != true:
				goal = {}
			if standing and pois_done < 2 and goal.is_empty():
				var nxt := _goal(c, target, here)
				if not nxt.is_empty() and w.path(here, nxt["tile"]).size() <= 8:
					goal = nxt
			if goal.is_empty():
				goal = {"tile": w.dock(), "home": true}
		if here == goal["tile"]:
			if goal.get("home") == true:
				break
			var content = w.content_at(here) if w.available(here) else null
			if content != null and content["kind"] == "poi":
				var is_core: bool = Rules.truthy(content.get("core"))
				if is_core:
					tally["core_tries"] += 1
				var dcl: int = w.districts_cleared().size()
				dep.enter_poi(here)
				_fights(c)
				if dep.active() and w.is_cleared(here):
					pois_done += 1
					tally["pois"] += 1
					tally["poi_skulls"].append(w.skull_of(here))
					if is_core and w.districts_cleared().size() > dcl:
						tally["cores"] += 1
			goal = {"tile": here}          # (looked at again above)
			continue
		# a step on the way
		var way := w.path(here, goal["tile"])
		if way.size() < 2:
			goal = {"tile": w.dock(), "home": true}
			continue
		var st := dep.step_to(way[1])
		tally["steps"] += 1
		if not st["moved"]:
			return {"n": n, "error": "a step went nowhere: " + str(st)}
		if st["ambush"]:
			tally["ambushes"] += 1
			dep.ambush(way[1], {"tileAmbush": Rules.truthy(st.get("tileAmbush"))})
			_fights(c)
			continue
		var on: String = way[1]
		var content2 = w.content_at(on) if w.available(on) else null
		if content2 != null and content2["kind"] == "cache":
			dep.open_cache(on)
			tally["caches"] += 1
		elif content2 != null and content2["kind"] == "event" and on != goal["tile"]:
			var ev = dep.event_at(on)
			if ev != null and ev.get("choices") is Array and not ev["choices"].is_empty():
				dep.choose(on, rng.randi_range(0, ev["choices"].size() - 1))
				tally["events"] += 1
				if dep.active() and dep.cur()["activity"] != null:
					_fights(c)
	var result := "wipe"
	var haul := {}
	if dep.active():
		if dep.cur()["pos"] != w.dock():
			return {"n": n, "error": "ran out of steps away from the dock"}
		var lost_none: bool = dep.cur()["heroesOut"].is_empty()
		var h := dep.home()
		result = "home"
		haul = h["haul"]
		# two clean trips at its aim, and it aims a Skull Level higher
		if lost_none and tally["poi_skulls"].any(func(k): return int(k) >= target):
			clean += 1
			if clean >= 2 and comfort < 6:
				comfort = mini(6, target)
				clean = 0
		elif not lost_none:
			clean = 0
	else:
		comfort = maxi(0, mini(comfort, target - 1) - 1)
		clean = 0
		if keepheroes:
			c.dock.state["heroes"] = heroes0
		if keepcards:
			c.dock.inv["cards"] = cards0
	line.merge(tally)
	line["result"] = result
	line["haul_shards"] = int(Loot.norm(haul)["shards"]) if result == "home" else 0
	line["shards_after"] = int(dep.stock["shards"])
	line["rank_after"] = c.dock.rank()
	line["merits"] = c.dock.merits()
	line["comfort"] = comfort
	line["districts"] = w.districts_cleared().size()
	line["heroes_owned"] = _heroes(c).size()
	return line


## Where to go next: the nearest POI at the Skull Level it aims at (lower, if
## there is none), or, once a Skull 6 POI is behind it, the nearest Core.
## {tile, kind, skull, district} or {}.
func _goal(c: Campaign, target: int, from := "") -> Dictionary:
	var w := c.world
	var at := from if from != "" else w.dock()
	var cand := []
	if comfort >= 6:
		cand = w.cores().keys().filter(func(k): return w.available(k))
	if cand.is_empty():
		# at its aim; or, with none there just now (cleared, not back yet), the nearest level that has one, lower first
		var order := [target]
		for d in range(1, 6):
			order.append(target - d)
			order.append(target + d)
		for s in order:
			if s < 1 or s > 6:
				continue
			cand = w.map["tiles"].keys().filter(func(k): return w.skull_of(k) == s and w.available(k) and w.content_at(k)["kind"] == "poi" and not Rules.truthy(w.content_at(k).get("core")))
			if not cand.is_empty():
				break
	if cand.is_empty():
		return {}
	var best := ""
	var bl := 1 << 20
	for k in cand:
		var p := w.path(at, k)
		if not p.is_empty() and p.size() < bl:
			bl = p.size()
			best = str(k)
	if best == "":
		return {}
	return {"tile": best, "kind": "core" if w.core_at(best) != "" else "poi", "skull": w.skull_of(best), "district": w.district_of(best), "dist": bl - 1}


# ---------------------------------------------------------------- the fights
## Every fight the deployment waits on, until none does or the team is wiped out.
func _fights(c: Campaign) -> void:
	var dep := c.deploy
	var guard := 0
	while dep.active() and dep.cur()["activity"] != null and guard < 30:
		guard += 1
		var won := _fight(c)
		if retreat and not won and dep.active() and dep.cur()["activity"] != null:
			# (what-if) it gives the place up: no more floors, and home with what it carries
			dep.cur()["activity"] = null
			tally["retreats"] = int(tally.get("retreats", 0)) + 1
			retreating = true


func _fight(c: Campaign) -> bool:
	var dep := c.deploy
	var sp: Dictionary = dep.spec()
	var team: Dictionary = dep.team_now()
	var f := _floor(c, sp["floor"])
	if d3floors and not ChunkGen.is_gen_key(sp["floor"]):
		# (what-if) a whole floor (a TEST floor) gives way to one grown from District 3's chunks, of the size this fight would have
		var size := "small" if sp["kind"] == "ambush" else ("large" if int(sp["index"]) == int(sp["count"]) - 1 and int(sp["skull"]) >= 4 else "medium")
		var lv := ChunkGen.generate(c.world.chunks, "3", int(sp["skull"]), size, hash(str(sp["tile"]) + ":" + str(sp["index"]) + ":" + str(sp["n"])) & 0x7FFFFFFF)
		if not lv.is_empty():
			f = FloorData.from_dict(lv)
	if f == null:
		dep.wipe()
		return false
	f.district = str(sp["district"])
	var standing: Array = team["heroes"].duplicate()
	standing.sort_custom(func(a, b): return power(r.card_named(a)) > power(r.card_named(b)))
	var entering: Array = standing.slice(0, Roster.deploy_capacity(f, int(sp["skull"])))
	var su := StrikeTeams.setup_for(team, r, entering, entering[0], player.starters(team, r, entering), 3, int(Rules.num(sp.get("instability"), 0)))
	su["deploy"] = {"district": sp["district"], "skull": sp["skull"], "kind": sp["kind"], "pending": sp["pending"], "bounties": c.dock.wanted()}
	var b := Battle.begin_team(f, r, su, rng.randi())
	player.play(b)
	tally["fights"] += 1
	tally["rounds"] += b.round
	if not b.over:
		# still going at the round limit: counted lost, as a player would give it up
		for u in b.side_units("ally"):
			if str(u.get("cardType", "")).to_lower().contains("hero"):
				u["hp"] = 0
		b.check_downs()
		b.settle()
	var res := b.deploy_result()
	tally["won" if res["winner"] == "ally" else "lost"] += 1
	tally["heroes_down"] += res["heroesDown"].size()
	dep.fight_over(res)
	return res["winner"] == "ally"


func _floor(c: Campaign, k) -> FloorData:
	if k == null:
		return null
	if ChunkGen.is_gen_key(k):
		var lv := c.world.level(k)
		return FloorData.from_dict(lv) if not lv.is_empty() else null
	for f in floors:
		if str(f.raw.get("_key", f.name)) == str(k) or f.name == str(k):
			return FloorData.from_dict(f.raw)
	return null
