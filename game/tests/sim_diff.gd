## The proof that the game's battle code is the Companion's Battle Simulator:
## cases made by running the simulator's own functions, effect engine and all
## (make_sim_cases.js, in the Companion's sources), on the export's floors and
## cards, each replayed here and compared: the keyword reader on every card's
## text; Cover, reach, what an Action can do and who it can be aimed at; the
## start of a fight; your moves and attacks with everything the Action's text
## does; holding fire; whole Enemy phases with the round turning over; whole
## fights begun from a Strike Team and carried through rounds of waves, Aether,
## Chips and cards; and the Deck Builder's checks on Strike Teams of every
## shape. Unit by Unit, log line by log line, down to the numbers that rise
## off them.
##   godot --headless --path . --script res://tests/sim_diff.gd
extends SceneTree

const CASES := "res://tests/fixtures/sim_cases.json"
const EXPORT := "res://tests/fixtures/export.zip"
var by_fn := {}
var shown := {}
var floors := {}
var fights: Array = []
var cards: Array = []
var roster: Roster
var loot_tables: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(CASES))
	if not (data is Dictionary):
		print("FAIL no cases at " + CASES)
		print("\nSIM MATCH 0  DIFFER 1")
		quit(1)
		return
	data = Rules.ints(data)
	var x := KeterExport.new()
	x.open(EXPORT)
	for f in x.floors():
		floors[f.name] = f
	fights = data.get("fights", [])
	loot_tables = data.get("lootTables", [])
	# the simulator knows every Archetype a card carries; so must the game
	cards = Rules.ints(x.cards())
	for c in cards:
		Keywords.register_archetypes(c.get("archetypes"))
	roster = Roster.new(x)
	_tally("archetypes", same(Keywords.archetypes(), data.get("archetypes", [])), Keywords.archetypes(), data.get("archetypes", []))
	for c in data["cases"]:
		_case(c)
	var ok := 0
	var bad := 0
	var names := by_fn.keys()
	names.sort()
	for fn in names:
		ok += by_fn[fn][0]
		bad += by_fn[fn][1]
		print(("PASS " if by_fn[fn][1] == 0 else "FAIL ") + "%s: %d of %d match" % [fn, by_fn[fn][0], by_fn[fn][0] + by_fn[fn][1]])
	print("(from %s; %d cards, %d floors)" % [data.get("made", "?"), data.get("cards", 0), data.get("floors", 0)])
	print("\nSIM MATCH %d  DIFFER %d" % [ok, bad])
	Rules.hooks = {}              # the rules let go of the last battle
	quit(1 if bad > 0 else 0)


func _tally(fn: String, good: bool, got, want) -> void:
	if not by_fn.has(fn):
		by_fn[fn] = [0, 0]
	by_fn[fn][0 if good else 1] += 1
	if not good and shown.get(fn, 0) < 3:
		shown[fn] = shown.get(fn, 0) + 1
		print("DIFF %s\n   game: %s\n   sim:  %s" % [fn, JSON.stringify(got).left(900), JSON.stringify(want).left(900)])
		var at := []
		_where(got, want, "", at)
		for w in at.slice(0, 6):
			print("   differs at " + w)


## Missing and null alike; numbers within a hair.
func same(a, b) -> bool:
	if a == null or b == null:
		return a == null and b == null
	if (a is int or a is float) and (b is int or b is float):
		return absf(float(a) - float(b)) < 1e-6
	if a is bool or b is bool:
		return a is bool and b is bool and a == b
	if (a is String or a is StringName) and (b is String or b is StringName):
		return str(a) == str(b)
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for i in a.size():
			if not same(a[i], b[i]):
				return false
		return true
	if a is Dictionary and b is Dictionary:
		var keys := {}
		for k in a: keys[k] = true
		for k in b: keys[k] = true
		for k in keys:
			if not same(a.get(k), b.get(k)):
				return false
		return true
	return false


## Where two results part, for reading a difference: the first few paths.
func _where(a, b, path: String, out: Array) -> void:
	if out.size() >= 6 or same(a, b):
		return
	if a is Array and b is Array and a.size() == b.size():
		for i in a.size():
			_where(a[i], b[i], path + "[" + str(i) + "]", out)
		return
	if a is Dictionary and b is Dictionary:
		var keys := {}
		for k in a: keys[k] = true
		for k in b: keys[k] = true
		for k in keys:
			_where(a.get(k), b.get(k), path + "." + str(k), out)
		return
	out.append("%s: game %s, sim %s" % [path, JSON.stringify(a).left(160), JSON.stringify(b).left(160)])


func _check(fn: String, got, want) -> void:
	_tally(fn, same(got, want), got, want)


## A fresh copy of one of the generated fights.
func _battle(fi: int, seed = null) -> Battle:
	var f: Dictionary = fights[fi]
	var b := Battle.from_state(floors[f["floor"]], f["units"].duplicate(true), seed, cards)
	# nothing is owned yet, so whatever the District's pool holds can drop
	b.progress = _progress(null)
	# loot rolls from a stream of its own: the fight's seed, or 0 where a case has none
	if seed == null:
		b.loot_table.seed_with(0)
	return b


func _unit(b: Battle, id: String) -> Dictionary:
	return b.unit_by_id(id)


## What is owned, for one case: the export's pools and chassis, and the levels the case gives.
func _progress(state) -> Progress:
	var p := Progress.new(null, roster.data.content("pools"), roster.data.content("chassis"), roster.data.content("tables"))
	p.state = Progress.tidy(state.duplicate(true) if state is Dictionary else null)
	p.card_source = func(): return roster.from_export      # (0.22) the cards that can be found
	return p


## What a case came to, as the simulator's side records it.
func _told(b: Battle) -> Dictionary:
	var acts := b.log.filter(func(l): return l["kind"] == "act")
	# the game floats a few numbers the simulator doesn't (a hazard's bite); those are marked its own
	return {"log": acts.map(func(l): return l["text"]), "floats": b.floats.filter(func(f): return not f.get("own", false)),
		"halted": acts.filter(func(l): return l.get("halt", false)).map(func(l): return l["text"]), "loot": _loot_of(b)}


## What has dropped and been found: the log's lines, the haul, and the tiles emptied.
func _loot_of(b: Battle) -> Dictionary:
	var tiles := b.looted.keys().map(func(h): return "%d,%d" % [h.x, h.y])
	tiles.sort()
	return {"lines": b.log.filter(func(l): return l["kind"] == "loot" and not l.get("own", false)).map(func(l): return l["text"]),
		"haul": Loot.norm(b.loot), "looted": tiles}


func _case(c: Dictionary) -> void:
	var before: int = by_fn.get(c.get("fn"), [0, 0])[1]
	_case_run(c)
	if by_fn.get(c.get("fn"), [0, 0])[1] > before and shown.get(str(c.get("fn")) + "#args", 0) < 3:
		shown[str(c.get("fn")) + "#args"] = shown.get(str(c.get("fn")) + "#args", 0) + 1
		print("   its arguments: " + JSON.stringify(c.get("args")).left(300))


func _case_run(c: Dictionary) -> void:
	var fn: String = c["fn"]
	var A: Array = c["args"]
	var want = c.get("result")
	match fn:
		"unitSpec":
			_check(fn, Roster.unit_spec(A[0]), want)
		"kwParse":
			_check(fn, Keywords.parse(A[0]), want)
		"kwRender":
			_check(fn, Keywords.render(A[0]), want)
		"kwSentences":
			_check(fn, Keywords.sentences(A[0]), want)
		"kwAnalyse":
			_check(fn, Keywords.analyse(A[0]), want)
		"kwProblems":
			var pctx := {"kind": A[1]}
			if A.size() > 2:
				pctx["variable"] = A[2]
			_check(fn, Keywords.problems(Keywords.analyse(A[0]), pctx), want)
		"kwX":
			_check(fn, {"uses": Keywords.uses_x(A[0]), "one": Keywords.fill_x(A[0], 1), "four": Keywords.fill_x(A[0], 4), "none": Keywords.fill_x(A[0], 0), "odd": Keywords.fill_x(A[0], "2")}, want)
		"kwResolve":
			_check(fn, Keywords.resolve(A[0]), want)
		"startFight":
			var b := _battle(A[0])
			b.deploy_start()
			for u in b.units.duplicate():
				if u["side"] == "enemy" and Rules.truthy(u.get("pos")) and not Rules.truthy(u.get("down")):
					b.arrive(u)
			_check(fn, [_told(b), _strip(b.units)], [want, _strip(c["after"])])
		"coverFor":
			var b := _battle(A[0])
			_check(fn, b.cover_for(_unit(b, A[1]), _unit(b, A[2])), want)
		"canReach":
			var b := _battle(A[0])
			var u := _unit(b, A[1])
			_check(fn, b.can_reach(u, u["actions"][A[2]], _unit(b, A[3])), want)
		# (0.21, Revision 16.1) the movement keywords
		"reachTiles":
			var b := _battle(A[0])
			var u := _unit(b, A[1])
			u["leap"] = A[3]
			_check(fn, b.reach_tiles(u, int(A[2])), want)
		"lungeSpot":
			var b := _battle(A[0])
			var u := _unit(b, A[1])
			_check(fn, b.lunge_spot(u, A[2], _unit(b, A[3])), want)
		"canReachLunge":
			var b := _battle(A[0])
			var u := _unit(b, A[1])
			_check(fn, [b.can_reach(u, A[2], _unit(b, A[3])), b.can_reach(u, A[2], _unit(b, A[3]), true)], want)
		"charged":
			var b := _battle(A[0])
			var u := _unit(b, A[1])
			u["travel"] = A[4]
			_check(fn, {"act": Battle.charged(u, A[2]), "dmg": b.odds(u, A[2], _unit(b, A[3]))["dmg"]}, want)
		"dashAway":
			var b := _battle(A[0])
			b._hook()
			var u := _unit(b, A[1])
			var said := b.dash_away(u, _unit(b, A[2]) if A[2] != null else null, int(A[3]))
			_check(fn, [{"said": said, "told": _told(b)}, _strip(b.units)], [want, _strip(c["after"])])
		"actionState":
			var b := _battle(A[0])
			var u := _unit(b, A[1])
			_check(fn, b.action_state(u, u["actions"][A[2]]), want)
		"targets":
			var b := _battle(A[0])
			var u := _unit(b, A[1])
			var a: Dictionary = u["actions"][A[2]]
			var ids: Array = b.targets_for(u, a).map(func(t): return t["id"]) if b.action_state(u, a)["ok"] else []
			ids.sort()
			_check(fn, ids, want)
		"hurtsOwnSide":
			var b := _battle(A[0])
			var u := _unit(b, A[1])
			_check(fn, b.fx.hurts_own_side(u, u["actions"][A[2]], _unit(b, A[3])), want)
		"holdable":
			var b := _battle(A[0])
			_check(fn, b.holdable(_unit(b, A[1])).map(func(a): return a["name"]), want)
		"playerMove":
			var b := _battle(A[0])
			b.move(_unit(b, A[1]), Vector2i(A[2], A[3]))
			_check(fn, [_told(b), _strip(b.units)], [want, _strip(c["after"])])
		# (0.22, Revision 16.2) an Action used on its own Unit
		"selfUse":
			var b := _battle(A[0], A[3])
			var u := _unit(b, A[1])
			b.use_on_self(u, u["actions"][A[2]])
			_check(fn, [_told(b), _strip(b.units)], [want, _strip(c["after"])])
		"tileUse":
			# (0.23) an Action aimed at a tile
			var b := _battle(A[0], A[5])
			var u := _unit(b, A[1])
			b.use_on_tile(u, u["actions"][A[2]], Vector2i(int(A[3]), int(A[4])))
			var got := _told(b)
			got["tile"] = b.kind_at(Vector2i(int(A[3]), int(A[4])))
			_check(fn, [got, _strip(b.units)], [want, _strip(c["after"])])
		"playerAttack":
			var b := _battle(A[0], A[4])
			var u := _unit(b, A[1])
			var a: Dictionary = u["actions"][A[2]]
			var res := b.attack(u, a, _unit(b, A[3]))
			# a Burst runs on by itself, as the simulator's Auto does: the only
			# target left, or the one the Unit's own targeting picks
			while res.has("burst"):
				var pool: Array = res["burst"]["pool"].map(func(id): return b.unit_by_id(id))
				var t = pool[0]
				if pool.size() > 1:
					var pick = Rules.choose_target(u, pool, {"distance": func(x): return Rules.hex_distance(u["pos"], x["pos"])})
					t = pick if pick != null else pool[0]
				res = b.attack(u, a, t, res["burst"]["left"] - 1)
			_check(fn, [_told(b), _strip(b.units)], [want, _strip(c["after"])])
		"enemyPhase":
			var b := _battle(A[0], A[1])
			for h in A[2]:
				b.hold_fire(_unit(b, h[0]), h[1])
			# Handbook 15.9: what arrived in either half of the round
			b._hook()
			for h in (A[3] if A.size() > 3 else []):
				var hu = _unit(b, h[0])
				if h[1] == "status":
					b.phase = "enemy" if h[5] else "turn"
					Rules.add_status(hu, h[2], h[3], null, h[4])
				else:
					if hu.get("mods") == null:
						hu["mods"] = []
					hu["mods"].append(h[2].duplicate(true))
			b.phase = "turn"
			if not b.outcome()["over"]:
				b.end_player_turn()
				for id in (b.enemy_queue() if not b.outcome()["over"] else []):
					var e = b.unit_by_id(id)
					if e == null or Rules.truthy(e.get("down")):
						continue
					b.enemy_turn(e)
					if b.outcome()["over"]:
						break
				if not b.outcome()["over"]:
					b.end_round()
			var got := _told(b)
			got["outcome"] = b.outcome()
			_check(fn, [got, _strip(b.units)], [want, _strip(c["after"])])
		"lootRoll":
			var lt := Loot.new(loot_tables[A[0]], A[1])
			var bags := []
			for i in int(A[3]):
				bags.append(lt.roll(A[2]))
			_check(fn, bags, want)
		"lootReward":
			var lr := Loot.new(loot_tables[A[0]], A[1])
			_check(fn, {"bag": lr.roll_reward(A[2], A[3]), "said": lr.reward_text(A[2])}, want)
		"lootText":
			var lx := Loot.new(loot_tables[A[0]])
			_check(fn, {"text": lx.text(A[1]), "lines": lx.lines(A[1]).map(func(l): return {"type": l["type"], "rarity": l["rarity"], "n": l["n"], "name": l["name"], "rarityLabel": l["rarityLabel"]}),
				"empty": Loot.is_empty(A[1]), "count": Loot.count(A[1])}, want)
		"lootAdd":
			_check(fn, Loot.add(A[0], A[1]), want)
		"lootSource":
			_check(fn, Loot.source_for(A[0]), want)
		"lootPoiSkull":
			var pf: FloorData = floors[A[0]]
			if not A[2]:
				var praw: Dictionary = pf.raw.duplicate()
				praw["level"] = A[1]
				pf = FloorData.from_dict(praw)
			_check(fn, Loot.poi_skull(pf), want)
		"autoTurn":
			# your Units take their turns by the Behavior keywords they are given
			var ab := _battle(A[0], A[1])
			for pair in A[2]:
				_unit(ab, pair[0])["behaviors"] = Rules.ints(pair[1]).duplicate(true)
			for pair in A[3]:
				_unit(ab, pair[0])["hp"] = int(pair[1])
			_auto_all(ab)
			_check(fn, [_told(ab), _strip(ab.units)], [want, _strip(c["after"])])
		"handCard":
			_check(fn, Roster.hand_card(roster.card_named(A[0])), want)
		"costLabel":
			_check(fn, Roster.cost_label(Roster.hand_card(roster.card_named(A[0]))), want)
		"aetherLabel":
			_check(fn, Battle.aether_label(A[0]), want)
		"cardCost":
			var cc = roster.card_named(str(A[0]))
			var ch := Roster.hand_card(cc)
			_check(fn, {"variable": Roster.card_var(ch), "one": Roster.card_cost(ch, 1), "three": Roster.card_cost(ch, 3), "asIs": Roster.card_cost(ch),
				"label": Roster.cost_label(ch), "at2": Roster.cost_label(ch, 2), "least": Roster.cost_least(cc)}, want)
		"costOf":
			var oc: Dictionary = A[0]
			var oh := Roster.hand_card(oc)
			_check(fn, {"cost": oh["cost"], "variable": Roster.card_var(oh), "one": Roster.card_cost(oh, 1), "four": Roster.card_cost(oh, 4),
				"label": Roster.cost_label(oh), "at3": Roster.cost_label(oh, 3), "least": Roster.cost_least(oc), "spec": Roster.unit_spec(oc)}, want)
		"unitX":
			var xs := Roster.unit_spec(roster.card_named(str(A[0])))
			if A[1] != null:
				xs["x"] = A[1]
			var xu := Battle.x_fill(Rules.unit_from_card(xs, "ally"))
			xu["id"] = "u"
			_check(fn, xu, want)
		"statX":
			var ss := {"name": "S", "cardType": "troop", "stats": {"hp": A[0], "nrg": A[0], "ac": A[0], "int": A[0], "move": A[0]}}
			if A[1] != null:
				ss["x"] = A[1]
			var su := Rules.unit_from_card(ss, "ally")
			su["id"] = "u"
			_check(fn, su, want)
		"teamFight":
			var cfg: Dictionary = A[0]
			var b := _team_begin(cfg, A[1])
			var shots := [_team_shot(b)]
			for step in A[2]:
				_team_round(b, step["felled"])
				shots.append(_team_shot(b))
			for shot in want:
				shot["units"] = _strip(shot["units"])
			# said round by round, so a difference is shown where it first appears
			for i in maxi(shots.size(), want.size()):
				var got_i = shots[i] if i < shots.size() else null
				var want_i = want[i] if i < want.size() else null
				if not same(got_i, want_i):
					_tally(fn, false, _first_difference(got_i, want_i, "after round %d" % i), "")
					return
			_tally(fn, true, null, null)
		"cardNeeds":
			var nc = roster.card_named(str(A[0]))
			var nh: Dictionary = Roster.hand_card(nc) if nc != null else {}
			_check(fn, Battle.needs_of(nh["effects"], 1 if Roster.card_var(nh) else null) if nc != null else null, want)
		"textNeeds":
			_check(fn, Battle.needs_of([{"text": A[0]}]), want)
		"teamPlay":
			var pcfg: Dictionary = A[0]
			var pb := _team_begin(pcfg, A[1])
			var pshots := [_team_shot(pb)]
			var wrong := ""
			for op in A[2]:
				var tile = Vector2i(int(op["tile"][0]), int(op["tile"][1])) if op.get("tile") != null else null
				var who = pb.unit_by_id(str(op["target"])) if op.get("target") != null else null
				var rec = int(op["recover"]) if op.get("recover") != null else null
				var refused: bool = Rules.truthy(op.get("refused"))
				var did = null
				match op["op"]:
					"aether":
						pb.aether = Rules.ints(op["pool"]).duplicate()
					"hand":
						var hi := int(op["i"])
						match op["type"]:
							"troop":
								did = pb.play_troop(hi, tile, op.get("x")) != null
							"equipment":
								did = pb.play_equipment(hi, pb.unit_by_id(str(op["unit"])), op.get("x")) if op.get("unit") != null else pb.play_state(pb.hand[hi])["ok"]
							_:
								did = pb.play_card(hi, who, tile, rec, op.get("x"))
					"cons":
						did = pb.use_consumable(int(op["i"]), who, tile, rec)
					"chip":
						did = pb.spend_chip(int(op["i"]), who, rec)
					"fell":
						for id in op["ids"]:
							pb.unit_by_id(id)["hp"] = 0
						pb.check_downs()
					"act":
						var au = pb.unit_by_id(str(op["unit"]))
						var aa = null
						# (0.21) which of its Actions, where two carry one name
						if op.get("index") != null and int(op["index"]) >= 0 and int(op["index"]) < au["actions"].size():
							aa = au["actions"][int(op["index"])]
						for x in au["actions"]:
							if x["name"] == op["action"] and aa == null:
								aa = x
						var st := pb.action_state(au, aa)
						if not same(st, op["state"]) and wrong == "":
							wrong = "step %d: %s's %s can be used: %s, the simulator has %s" % [pshots.size(), au["name"], aa["name"], JSON.stringify(st), JSON.stringify(op["state"])]
						if Rules.truthy(op.get("self")):
							# (0.22) used on itself, at once
							if op.get("x") != null:
								Battle.set_action_x(aa, op["x"])
							pb.use_on_self(au, aa)
						elif who != null:
							if op.get("x") != null:
								Battle.set_action_x(aa, op["x"])      # a carried Action card with a variable cost, used for this X
							pb.attack(au, aa, who)
					"place":
						pb.unit_by_id(str(op["unit"]))["pos"] = {"q": int(op["q"]), "r": int(op["r"])}
					"drain":
						# (0.40) the Deck has run out: what was in it is in the discard pile
						pb.discard.append_array(pb.deck)
						pb.deck = []
					"move":
						if pb.move(pb.unit_by_id(str(op["unit"])), Vector2i(int(op["q"]), int(op["r"]))).is_empty() and wrong == "":
							wrong = "step %d: %s couldn't walk to %d,%d" % [pshots.size(), str(op["unit"]), int(op["q"]), int(op["r"])]
					"auto":
						for pair in op["beh"]:
							pb.unit_by_id(str(pair[0]))["behaviors"] = Rules.ints(pair[1]).duplicate(true)
						_auto_all(pb)
					"wrongturn":
						pb.phase = "draw"
						var any := false
						if int(op["hand"]) >= 0:
							var wi := int(op["hand"])
							var wk: String = pb.play_state(pb.hand[wi])["kind"]
							any = (pb.play_troop(wi) != null) if wk == "troop" else (pb.play_state(pb.hand[wi])["ok"] if wk == "equipment" else pb.play_card(wi, pb.fx.leader_unit()))
						if int(op["cons"]) >= 0:
							any = pb.use_consumable(int(op["cons"]), pb.fx.leader_unit()) or any
						pb.phase = "turn"
						if any and wrong == "":
							wrong = "step %d: something was played out of turn" % pshots.size()
					"round":
						_team_round(pb, [])
				if did != null and did == refused and wrong == "":
					wrong = "step %d (%s %s): the game %s what the simulator %s" % [pshots.size(), op["op"], str(op.get("name", "")), "refused" if refused == false else "did", "did" if refused == false else "refused"]
				pshots.append(_team_shot(pb))
			if wrong != "":
				_tally(fn, false, wrong, "")
				return
			for shot in want:
				shot["units"] = _strip(shot["units"])
			for i in maxi(pshots.size(), want.size()):
				var pg = pshots[i] if i < pshots.size() else null
				var pw = want[i] if i < want.size() else null
				if not same(pg, pw):
					var what: Dictionary = A[2][i - 1] if (i > 0 and i - 1 < A[2].size()) else {}
					_tally(fn, false, _first_difference(pg, pw, "after step %d (%s)" % [i, JSON.stringify(what).left(160)]), "")
					return
			_tally(fn, true, null, null)
		"teamPings":
			var t: Dictionary = A[0]
			var team := StrikeTeams.blank(t["name"])
			team["level"] = t["level"]
			team["heroes"] = t["heroes"]
			for n in t["deck"]:
				team["deck"][n] = team["deck"].get(n, 0) + 1
			team["actions"] = t["actions"]
			for pair in t["pouch"]:
				team["pouch"][pair[0]] = pair[1]
			_check(fn, StrikeTeams.pings(team, roster, false), want)
		_:
			_tally("unknown:" + fn, false, null, null)


## A Strike Team's fight begun as a case describes it.
func _team_begin(cfg: Dictionary, seed) -> Battle:
	var named := func(n): return roster.card_named(str(n))
	var carried := {}
	for h in cfg["actions"]:
		carried[h] = cfg["actions"][h].map(named).filter(func(c): return c != null)
	var packed := {}
	for pair in cfg["pouch"]:
		packed[pair[0]] = pair[1]
	var cons := {}
	for pair in cfg.get("cons", []):
		cons[pair[0]] = pair[1]
	# now and then the fight is given a District of its own: one with no Elite to send, or none at all
	var f: FloorData = floors[cfg["floor"]]
	if cfg.has("district"):
		f = FloorData.from_dict(f.raw)
		f.district = str(cfg["district"])
	var setup := {"heroes": cfg["heroes"].map(named), "leader": cfg["leader"] if cfg["leader"] != null else "",
		"actions": carried, "start_troops": cfg["startTroops"], "deck": cfg["deck"].map(named).filter(func(c): return c != null), "pouch": packed,
		"level": cfg["level"], "protos": cfg["protos"], "wave_timer": cfg["waveTimer"], "consumables": cons, "instability": cfg.get("instability", 0)}
	# 0.8: a deployment's fight (the floor has taken the tile's District already), and what is owned
	if cfg.get("deploy") is Dictionary:
		setup["deploy"] = {"district": f.district, "skull": cfg["deploy"]["skull"], "kind": cfg["deploy"]["kind"], "pending": cfg["deploy"]["pending"]}
	roster.progress = _progress(cfg.get("prog"))
	var b := Battle.begin_team(f, roster, setup, seed)
	roster.progress = null
	return b


## Auto: each of your Units still standing takes its turn by itself. (simAutoAllies)
func _auto_all(b: Battle) -> void:
	var mine := b.units.filter(func(u): return u["side"] == "ally" and not Rules.truthy(u.get("down")))
	for u in mine:
		if not Rules.truthy(u.get("down")):
			b.auto_turn(u)


## Some Units fall, the Enemies take their turn and the round turns over,
## unless the fight is done.
func _team_round(b: Battle, felled: Array) -> void:
	for id in felled:
		b.unit_by_id(id)["hp"] = 0
	if not felled.is_empty():
		b.check_downs()
	if b.outcome()["over"]:
		return
	b.end_player_turn()
	if b.outcome()["over"]:
		return
	for id in b.enemy_queue():
		var e = b.unit_by_id(id)
		if e == null or Rules.truthy(e.get("down")):
			continue
		b.enemy_turn(e)
		if b.outcome()["over"]:
			return
	b.end_round()


## A Strike Team's fight, as the simulator's side records it.
func _team_shot(b: Battle) -> Dictionary:
	# a fight that is over settles its loot, once: what dropped, and, won, the floor's own reward
	var done := b.outcome()
	if done["over"] and b.loot_result.is_empty():
		b._settle_loot(done["winner"] == "ally")
	var told := _told(b)
	var sp = null
	var dr = null
	if not b.loot_result.is_empty() and b.deploy != null:
		# a deployment's fight tells the deployment how it went (simDeployFinish)
		# told once, as the fight ends; whatever a case does to the board afterwards changes nothing
		if not b.has_meta("dep"):
			b.winner = str(done["winner"])
			b.set_meta("dep", b.deploy_result())
		dr = b.get_meta("dep")
	elif not b.loot_result.is_empty():
		sp = {"won": b.loot_result["won"], "haul": b.loot_result["haul"], "reward": b.loot_result["reward"], "total": b.loot_result["total"], "items": b.loot_result["items"]}
	return {"loot": told["loot"], "found": b.found.duplicate(), "spoils": sp, "dep": dr,
		"log": told["log"], "floats": told["floats"], "halted": told["halted"], "units": _strip(b.units),
		"discard": b.discard.map(func(c): return str(c["name"]) + "|" + str(c["type"])), "cons": b.consumables.map(func(c): return [c["name"], Rules.truthy(c.get("used"))]),
		"aether": b.aether.duplicate(), "bank": b.bank.map(func(c): return [c["name"], c["value"], c["district"] if Rules.truthy(c.get("district")) else null, Rules.truthy(c.get("spent"))]),
		"pouch": b.pouch.map(func(c): return c["name"]), "hand": b.hand.map(func(c): return c["name"]), "deck": b.deck.map(func(c): return c["name"]),
		"pile": b.enemy_pile.map(func(c): return str(c["name"]) + "|" + str(c["level"])), "wave": b.wave, "waveTurn": b.wave_turn, "round": b.round,
		"leader": b.leader_id if b.leader_id != "" else null, "protos": b.protos, "level": b.player_level, "outcome": b.outcome()}


## Where two records first part, in a few words.
func _first_difference(got, want, where: String) -> String:
	if not (got is Dictionary and want is Dictionary):
		return where + ": one side has no record"
	for k in want:
		if not same(got.get(k), want[k]):
			var g = got.get(k)
			var w = want[k]
			if g is Array and w is Array:
				for i in maxi(g.size(), w.size()):
					var gi = g[i] if i < g.size() else null
					var wi = w[i] if i < w.size() else null
					if not same(gi, wi):
						if gi is Dictionary and wi is Dictionary:
							for kk in wi:
								if not same(gi.get(kk), wi[kk]):
									return "%s: %s[%d].%s is %s, the simulator has %s" % [where, k, i, kk, JSON.stringify(gi.get(kk)).left(6000), JSON.stringify(wi[kk]).left(6000)]
							for kk in gi:
								if not wi.has(kk) and gi[kk] != null:
									return "%s: %s[%d].%s is %s, the simulator has none" % [where, k, i, kk, JSON.stringify(gi[kk]).left(300)]
						return "%s: %s[%d] is %s, the simulator has %s" % [where, k, i, JSON.stringify(gi).left(300), JSON.stringify(wi).left(300)]
			if g is Dictionary and w is Dictionary:
				for kk in w:
					if not same(g.get(kk), w[kk]):
						return "%s: %s.%s is %s, the simulator has %s" % [where, k, kk, JSON.stringify(g.get(kk)).left(300), JSON.stringify(w[kk]).left(300)]
			return "%s: %s is %s, the simulator has %s" % [where, k, JSON.stringify(g).left(300), JSON.stringify(w).left(300)]
	return where + ": differ"


## The game and the simulator each keep a note or two of their own on a Unit
## (whether it has acted; how far it has moved). Everything else is compared.
func _strip(units: Array) -> Array:
	return units.map(func(u):
		var d: Dictionary = u.duplicate(true)
		d.erase("acted")
		d.erase("moved")
		d.erase("spawnLevel")      # the game's note of the tile's level an Enemy arrived at
		d.erase("_salvaged")       # the simulator's note that an Enemy has dropped its loot (the game keeps its own)
		# a Unit's own card, and the Equipment cards on it, are told by name
		if d.get("card") is Dictionary:
			d["card"] = d["card"]["name"]
		if d.get("equipCards") is Array:
			d["equipCards"] = d["equipCards"].map(func(c): return c["name"] if c is Dictionary else c)
		return d)
