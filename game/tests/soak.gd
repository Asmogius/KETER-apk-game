## Battles played through by a random hand, on every floor in the export, with
## its real cards: Units move (and sometimes take a move back), hold fire, use
## whatever Actions they can on whoever they can reach, Bursts and all; the
## Enemies take their turns; rounds turn over, until someone wins or the
## rounds are up. Every other one is a Strike Team's Battle, with a team
## thrown together from the export: six waves, Aether, Chips and a hand, and
## the hand is played: Troops deployed, Equipment attached, Commands aimed,
## Consumables used, Chips spent for their effect, and now and then one of
## them taken back. A card with a variable cost is played for an X the Bank
## can pay; a carried Action card that asks for X is given one. In every
## other fight some rounds are left to Auto: the Units not yet used take
## their own turns, by Behavior keywords dealt at random. Loot drops, and is
## found on Loot Tiles and in Locked Chests.
## Nothing here checks who wins. It checks that nothing breaks: no script
## error, no two Units on one tile, nobody off the floor, no Health below
## zero, every beat of an Enemy's turn whole; and in a Strike Team's Battle
## no card or Chip lost or made from nothing (a Troop's card and an Equipment
## card are with their Unit until it goes down), a card that says it can be
## played can be, a card taken back leaves everything as it was, and the
## waves in order; a card played for X costs exactly that, and one asked for
## more than the Bank holds is refused; every Enemy that goes down drops its
## loot once, nothing is found twice, and a fight that ends settles what
## dropped (and, won, the floor's reward) once; a Unit Auto has played has had
## its turn; a blueprint or a chassis left behind is one the export knows, is
## found once, has its line in the log, and is settled with the fight.
##   godot --headless --path . --script res://tests/soak.gd [-- fights]
extends SceneTree

const FIXTURE := "res://tests/fixtures/export.zip"
const Kit := preload("res://tests/team_kit.gd")
var rng := RandomNumberGenerator.new()
var wrong: Array = []
var plays := {"troop": 0, "equipment": 0, "plain": 0, "cons": 0, "chip": 0, "back": 0, "refused": 0, "recover": 0, "x": 0, "x_over": 0, "x_action": 0,
	"auto": 0, "auto_beats": 0, "drops": 0, "found": 0, "settled": 0, "rewards": 0, "special": 0, "items": 0, "item_rewards": 0}


func _initialize() -> void:
	_run.call_deferred()


func _down(u) -> bool:
	return u == null or Rules.truthy(u.get("down"))


func _pick(list: Array):
	return list[rng.randi() % list.size()]


## What must always be true of a battle.
func _sound(b: Battle, when: String) -> void:
	var at := {}
	for u in b.units:
		if not (u.get("pos") is Dictionary):
			continue
		var h := Battle.tile_of(u)
		if not b.floor_data.has_tile(h):
			wrong.append("%s: %s is off the floor at %s" % [when, u["name"], h])
		if int(Rules.num(u.get("hp"), 0)) < 0:
			wrong.append("%s: %s has %s Health" % [when, u["name"], str(u.get("hp"))])
		if _down(u):
			continue
		if at.has(h):
			wrong.append("%s: %s and %s both stand on %s" % [when, u["name"], at[h], h])
		at[h] = u["name"]
		if int(Rules.num(u.get("nrg"), 0)) < 0:
			wrong.append("%s: %s has %s Energy" % [when, u["name"], str(u.get("nrg"))])
	_sound_loot(b, when)
	if b.with_cards:
		_sound_cards(b, when)


## Of loot: every Enemy that is down has dropped (once), nothing but a Loot
## Tile or a Locked Chest has been searched, the haul is whole numbers, and
## the log's loot lines add up to it. Of blueprints and chassis (0.8): every
## one found has its line in the log and no line is there without one, none is
## found twice in a fight, each is one the export knows, and what the fight
## settles is what was found, with the floor's own on top only when it is won.
func _sound_loot(b: Battle, when: String) -> void:
	for u in b.units:
		if u.get("side") == "enemy" and _down(u) and not b._salvaged.has(u["id"]):
			wrong.append("%s: %s is down and dropped nothing" % [when, u["name"]])
	for id in b._salvaged:
		var su = b.unit_by_id(str(id))
		if su == null or su.get("side") != "enemy":
			wrong.append("%s: %s dropped loot, and is no Enemy of this fight" % [when, str(id)])
	for h in b.looted:
		if b.chest_at(h) < 0 and b.kind_at(h) != "loot":
			wrong.append("%s: %s was searched, and is neither a Loot Tile nor a Locked Chest" % [when, h])
	if Loot.norm(b.loot) != b.loot:
		wrong.append("%s: the haul isn't whole: %s" % [when, str(b.loot)])
	var lines := b.log.filter(func(l): return l["kind"] == "loot" and not l.get("own", false) and not l.get("item", false))
	var item_lines := b.log.filter(func(l): return l["kind"] == "loot" and l.get("item", false) and not l.get("own", false))
	if item_lines.size() != b.found.size():
		wrong.append("%s: %d blueprints and chassis in the log, %d found" % [when, item_lines.size(), b.found.size()])
	var once := {}
	for it in b.found:
		if once.has(it):
			wrong.append("%s: %s was found twice in one fight" % [when, str(it)])
		once[it] = true
		if b.progress == null or Progress.parse_item(it) == null:
			wrong.append("%s: %s was found, and is no blueprint or chassis of this export" % [when, str(it)])
	var drops := lines.filter(func(l): return " drops: " in str(l["text"])).size()
	var finds := lines.size() - drops
	if finds != b.looted.size() and finds > b.looted.size():
		wrong.append("%s: %d finds in the log, %d tiles searched" % [when, finds, b.looted.size()])
	if drops > b._salvaged.size():
		wrong.append("%s: %d drops in the log, %d Enemies have dropped" % [when, drops, b._salvaged.size()])
	if lines.is_empty() != Loot.is_empty(b.loot):
		wrong.append("%s: the log has %d loot lines and the haul is %s" % [when, lines.size(), b.loot_table.text(b.loot)])
	if b.over:
		var r: Dictionary = b.loot_result
		if r.is_empty():
			wrong.append("%s: the fight is over and its loot isn't settled" % when)
		elif r["total"] != Loot.add(r["haul"], r["reward"]) or r["haul"] != Loot.norm(b.loot) or (not r["won"] and not Loot.is_empty(r["reward"])) or r["won"] != (b.winner == "ally"):
			wrong.append("%s: the loot is settled wrongly: %s" % [when, str(r)])
		else:
			var kept: Array = r.get("items", [])
			var more := b.log.filter(func(l): return l["kind"] == "loot" and l.get("item", false) and l.get("own", false)).size()
			if kept.slice(0, b.found.size()) != b.found or kept.size() != b.found.size() + more or (not r["won"] and more > 0):
				wrong.append("%s: the blueprints and chassis are settled wrongly: found %s, the floor gave %d, settled %s" % [when, str(b.found), more, str(kept)])
			var twice := {}
			for it in kept:
				if twice.has(it):
					wrong.append("%s: %s is settled twice" % [when, str(it)])
				twice[it] = true


## And of a Strike Team's: every card is in the Deck, the hand or the discard,
## or on the Battlefield with its Troop or the Unit wearing it; every Chip in
## the Pouch or the Bank; no Aether below nothing; a Unit that is down holds
## no card; the waves only ever go up, to six.
func _sound_cards(b: Battle, when: String) -> void:
	var cards := b.deck.size() + b.hand.size() + b.discard.size()
	for u in b.units:
		var held: int = (1 if u.get("card") is Dictionary else 0) + (int(u["equipCards"].size()) if u.get("equipCards") is Array else 0)
		if held > 0 and (_down(u) or u.get("side") != "ally"):
			wrong.append("%s: %s, %s, still holds %d card(s)" % [when, u["name"], "down" if _down(u) else "not yours", held])
		cards += held
	if cards != int(b.get_meta("cards")):
		wrong.append("%s: %d cards in the Deck, hand, discard and on the Battlefield; there were %d" % [when, cards, b.get_meta("cards")])
	if b.consumables.size() != int(b.get_meta("cons")):
		wrong.append("%s: %d Consumables; there were %d" % [when, b.consumables.size(), b.get_meta("cons")])
	if b.pouch.size() + b.bank.size() != int(b.get_meta("chips")):
		wrong.append("%s: %d Chips in the Pouch and the Bank; there were %d" % [when, b.pouch.size() + b.bank.size(), b.get_meta("chips")])
	for k in b.aether:
		if int(b.aether[k]) < 0:
			wrong.append("%s: %s %s Aether" % [when, str(b.aether[k]), k])
	if b.wave < int(b.get_meta("wave")) or b.wave > b.waves_total or b.wave < 1:
		wrong.append("%s: wave %d after wave %d" % [when, b.wave, b.get_meta("wave")])
	b.set_meta("wave", b.wave)


## Everything Undo should put back, as one piece of text to compare.
func _shape(b: Battle) -> String:
	return var_to_str([b.hand.map(func(c): return c["name"]), b.discard.map(func(c): return c["name"]), b.deck.size(), b.aether,
		b.bank.map(func(c): return [c["name"], Rules.truthy(c.get("spent"))]), b.consumables.map(func(c): return [c["name"], Rules.truthy(c.get("used"))]),
		b.units, b.moved, b.log.size(), b.deployed, b.loot, b.looted, b._salvaged, b.loot_table.state()])


## Who, where and which Troop's card something that needs them is given.
func _aim(b: Battle, needs: Dictionary) -> Dictionary:
	var out := {"target": null, "tile": null, "recover": null}
	if needs["need"] == "enemy" or needs["need"] == "ally":
		out["target"] = _pick(b.pool_for_need(needs))
	elif needs["need"] == "tile":
		out["tile"] = _pick(b.floor_data.tiles.keys())
	if needs["recover"]:
		out["recover"] = _pick(b.recoverable())
		plays["recover"] += 1
	return out


## A random hand at the cards: a few of whatever can be played from the hand,
## the Consumables and the Bank's Chips; and one in four that can be is taken
## back, which must leave everything as it was.
func _play_some(b: Battle, most: int) -> void:
	for k in rng.randi_range(0, most):
		if b.settle():
			return
		var before := _shape(b)
		var n0 := b.undo.size()
		var roll := rng.randf()
		var what := ""
		var kind := ""
		var said := false
		var done := false
		if roll < 0.6 and not b.hand.is_empty():
			var i := rng.randi() % b.hand.size()
			var card: Dictionary = b.hand[i]
			# a variable cost: an X the Bank can pay, chosen first (what the card needs may depend on it)
			var x = null
			if Roster.card_var(card) and b.max_x(card) >= 1:
				x = rng.randi_range(1, b.max_x(card))
			var st := b.play_state(card, x)
			what = str(card["name"])
			kind = st["kind"]
			said = st["ok"]
			var bank0: int = int(Rules.aether_total(b.aether))
			var units0 := b.units.size()
			if said and x != null:
				# more than the Bank holds is refused, and nothing changes
				var over: int = b.max_x(card) + 1
				var held := _shape(b)
				var took: bool = (b.play_troop(i, null, over) != null) if kind == "troop" else (b.play_equipment(i, b.side_units("ally")[0], over) if kind == "equipment" else b.play_card(i, null, null, null, over))
				if took or _shape(b) != held:
					wrong.append("%s was played for X = %d, more than the Bank could pay" % [what, over])
				plays["x_over"] += 1
			if said:
				match kind:
					"troop":
						var came = b.play_troop(i, _pick(b.open_spawns()), x)
						done = came != null
						if done and x != null and came.get("x") != x:
							wrong.append("%s was played for X = %d and arrived with X = %s" % [what, x, str(came.get("x"))])
					"equipment":
						done = b.play_equipment(i, _pick(b.side_units("ally").filter(func(u): return not _down(u))), x)
					_:
						var a := _aim(b, st["needs"])
						done = b.play_card(i, a["target"], a["tile"], a["recover"], x)
				if done and x != null:
					plays["x"] += 1
					var cost := Roster.card_cost(card, x)
					if bank0 - int(Rules.aether_total(b.aether)) != int(cost["generic"]) + int(cost["affinity"]) and units0 == b.units.size() and kind != "plain":
						wrong.append("%s at X = %d took %d Aether, not %d" % [what, x, bank0 - int(Rules.aether_total(b.aether)), int(cost["generic"]) + int(cost["affinity"])])
			elif b.play_troop(i) != null or b.play_card(i) or b.play_equipment(i, b.side_units("ally")[0]):
				wrong.append("%s was played though it can't be: %s" % [what, st["why"]])
		elif roll < 0.85 and not b.consumables.is_empty():
			var i2 := rng.randi() % b.consumables.size()
			var st2 := b.consumable_state(i2)
			what = str(b.consumables[i2]["name"])
			kind = "cons"
			said = st2["ok"]
			if said and Rules.truthy(b.consumables[i2].get("used")):
				wrong.append("%s, used already, says it can be used again" % what)
			if said:
				var a2 := _aim(b, st2["needs"])
				done = b.use_consumable(i2, a2["target"], a2["tile"], a2["recover"])
			elif b.use_consumable(i2):
				wrong.append("%s was used though it can't be: %s" % [what, st2["why"]])
		elif not b.bank.is_empty():
			var i3 := rng.randi() % b.bank.size()
			var st3 := b.chip_state(i3)
			what = str(b.bank[i3]["name"])
			kind = "chip"
			said = st3["ok"]
			if said and Rules.truthy(b.bank[i3].get("spent")):
				wrong.append("%s, spent this round, says it can be spent again" % what)
			if said:
				var a3 := _aim(b, st3["needs"])
				done = b.spend_chip(i3, a3["target"], a3["recover"])
			elif b.spend_chip(i3):
				wrong.append("%s was spent though it can't be: %s" % [what, st3["why"]])
		if kind == "":
			continue
		if not said:
			plays["refused"] += 1
			if _shape(b) != before:
				wrong.append("%s couldn't be played, yet something changed" % what)
			continue
		if not done:
			wrong.append("%s (%s) said it could be played, and wasn't" % [what, kind])
			continue
		plays[kind] += 1
		_sound(b, "after " + what)
		if b.undo.size() == n0 + 1 and rng.randf() < 0.25:
			var took := b.undo_last()
			plays["back"] += 1
			if took.get("label") != what:
				wrong.append("Undo after %s took back %s" % [what, took.get("label")])
			if _shape(b) != before:
				wrong.append("taking back %s left things changed" % what)
			_sound(b, "after " + what + " is taken back")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var want := int(args[0]) if args.size() > 0 else 120
	rng.seed = 20261006
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)
	var floors := x.floors()
	var fights := 0
	var rounds := 0
	var attacks := 0
	var moves := 0
	var holds := 0
	var bursts := 0
	var beats_seen := 0
	var ended := {"ally": 0, "enemy": 0, "draw": 0, "unfinished": 0}
	var team_fights := 0
	var waves_met := 0
	var last_waves := 0
	var drawn := 0
	var problems := {}
	for i in want:
		var f: FloorData = floors[i % floors.size()]
		var heroes: Array = r.heroes().duplicate()
		var troops: Array = r.troops().duplicate()
		var hc := []
		for k in Roster.hero_capacity(f):
			if not heroes.is_empty():
				hc.append(heroes.pop_at(rng.randi() % heroes.size()))
		var tc := []
		for k in rng.randi_range(0, 3):
			tc.append(_pick(troops))
		var b: Battle
		var team_fight := i % 2 == 1
		if team_fight:
			var team: Dictionary = Kit.random_team(r, rng)
			var su: Dictionary = Kit.entry(team, r, f, rng)
			b = Battle.begin_team(f, r, su, rng.randi())
			b.set_meta("cards", su["deck"].size())
			b.set_meta("cons", StrikeTeams.consumable_count(team, r))
			b.set_meta("chips", StrikeTeams.pouch_count(team, r))
			b.set_meta("wave", 1)
			team_fights += 1
			# (0.23) a Unit a Starting Troop's arrival Deploys (FALCON Drone Tokens, id d1, d2...) isn't one of them
			if b.side_units("ally").filter(func(u): return not str(u["id"]).begins_with("d")).size() != su["heroes"].size() + su["start_troops"].size():
				wrong.append("a Strike Team of %d Heroes and %d Starting Troops put %d Units on %s" % [su["heroes"].size(), su["start_troops"].size(), b.side_units("ally").size(), f.name])
		else:
			b = Battle.begin(f, r, hc, tc, rng.randi())
		_sound(b, "at the start")
		if team_fight:
			plays["special"] += b.side_units("enemy").filter(func(e): return ["elite", "miniboss"].has(str(e.get("cardType")).to_lower())).size()
		var auto_fight := i % 4 >= 2
		var keys: Array = Behaviors.choices()
		while not b.settle() and b.round <= (16 if team_fight else 10):
			if team_fight:
				_play_some(b, 4)
			# in an Auto fight, most rounds leave some Units (or all of them) to Auto
			var auto_round := auto_fight and rng.randf() < 0.7
			for u in b.side_units("ally"):
				if _down(u) or b.over:
					continue
				if auto_round and rng.randf() < 0.7:
					continue              # left for Auto
				if team_fight and rng.randf() < 0.3:
					_play_some(b, 1)
				if _down(u) or b.over:
					continue
				var can_hold := b.holdable(u)
				if not can_hold.is_empty() and rng.randf() < 0.35:
					b.hold_fire(u, can_hold[0]["name"])
					holds += 1
				var reach := b.reach(u)
				if not reach.is_empty() and rng.randf() < 0.85:
					var t: Dictionary = _pick(reach)
					b.move(u, Vector2i(t["q"], t["r"]))
					moves += 1
					_sound(b, "after a move")
					if rng.randf() < 0.12:
						b.undo_move()
						_sound(b, "after a move is taken back")
				for k in 3:
					if _down(u) or b.settle():
						break
					var usable := Battle.usable_actions(u).filter(func(a): return b.action_state(u, a)["ok"])
					if usable.is_empty():
						break
					var a: Dictionary = _pick(usable)
					var bank1: int = int(Rules.aether_total(b.aether))
					if a.get("aetherX") is Dictionary:
						# a carried Action card that asks for X: one the Bank can pay
						var most := b.action_max_x(a)
						if most < 1:
							wrong.append("%s can use %s, and the Bank can't pay for X = 1" % [u["name"], a["name"]])
							break
						Battle.set_action_x(a, rng.randi_range(1, most))
						plays["x_action"] += 1
					var ts := b.targets_for(u, a)
					if ts.is_empty():
						break
					var tgt: Dictionary = _pick(ts)
					if Effects.has_area(a):
						b.fx.area_preview(u, a, tgt)
					b.odds(u, a, tgt)
					var res := b.attack(u, a, tgt)
					attacks += 1
					while res.has("burst"):
						bursts += 1
						var pool: Array = res["burst"]["pool"]
						res = b.attack(u, a, b.unit_by_id(_pick(pool)), int(res["burst"]["left"]) - 1)
						attacks += 1
					if a.get("aetherX") is Dictionary and res.get("inRange", true):
						var owed = Battle.action_aether(a)
						if bank1 - int(Rules.aether_total(b.aether)) != int(owed["generic"]) + int(owed["affinity"]):
							wrong.append("%s for X = %s took %d Aether, not %d" % [a["name"], str(a.get("x")), bank1 - int(Rules.aether_total(b.aether)), int(owed["generic"]) + int(owed["affinity"])])
					_sound(b, "after " + str(a.get("name")))
			if b.settle():
				break
			if auto_round:
				var line := b.auto_queue()
				# (0.40) as the game's Auto does: one that arrives meanwhile takes its turn too
				var at := 0
				while true:
					if at >= line.size():
						var more := b.auto_queue().filter(func(i): return not line.has(i))
						if more.is_empty():
							break
						line.append_array(more)
					var id = line[at]
					at += 1
					var au = b.unit_by_id(id)
					if _down(au) or b.has_acted(au) or b.enemies_left() == 0:
						continue
					# Behavior keywords dealt at random, as a player might choose them
					var mine := []
					for k in rng.randi_range(0, 3):
						var d: Dictionary = _pick(keys)
						mine = Behaviors.toggle(mine, d["k"])["list"]
					au["behaviors"] = mine
					var at0 := Battle.tile_of(au)
					for bt in b.auto_turn(au):
						plays["auto_beats"] += 1
						if not (bt.has("after") and bt.has("floats") and bt.has("lines") and bt["after"].size() >= 1):
							wrong.append("a beat of %s's Auto turn is not whole: %s" % [au["name"], bt.get("type")])
					plays["auto"] += 1
					if not b.has_acted(au) or b.can_move(au) or not b.undo.is_empty():
						wrong.append("%s took its turn on Auto, and could go again (or be taken back)" % au["name"])
					# (Wary and Prudent have conditions, and a keyword with one outranks Steadfast)
					if Behaviors.has(mine, "steadfast") and not Behaviors.has(mine, "wary") and not Behaviors.has(mine, "prudent") and not _down(au) and Battle.tile_of(au) != at0:
						wrong.append("%s, Steadfast, left its tile on Auto" % au["name"])
					_sound(b, "after " + str(au["name"]) + "'s Auto turn")
					if b.settle():
						break
				if not b.over and not b.auto_queue().is_empty() and b.enemies_left() > 0:
					wrong.append("Auto left %d Units that hadn't had a turn" % b.auto_queue().size())
					if OS.get_environment("SOAK_WHY") != "":
						print("LEFT: ", b.auto_queue().map(func(i): return [i, b.unit_by_id(i)["name"], line.has(i)]))
			if b.settle():
				break
			for id in b.enemy_queue():
				var e = b.unit_by_id(id)
				if _down(e):
					continue
				for bt in b.enemy_turn(e):
					beats_seen += 1
					if not (bt.has("after") and bt.has("floats") and bt.has("lines") and bt["after"].size() >= 1):
						wrong.append("a beat of %s's turn is not whole: %s" % [e["name"], bt.get("type")])
				_sound(b, "after " + str(e["name"]) + "'s turn")
				if b.settle():
					break
			if not b.over:
				var before_wave := b.units.size()
				b.end_round()
				plays["special"] += b.units.slice(before_wave).filter(func(e): return e["side"] == "enemy" and ["elite", "miniboss"].has(str(e.get("cardType")).to_lower())).size()
				_sound(b, "as round %d begins" % b.round)
				rounds += 1
		_sound(b, "at the end")
		plays["drops"] += b._salvaged.size()
		plays["found"] += b.looted.size()
		plays["items"] += b.found.size()
		if b.over:
			plays["item_rewards"] += b.loot_result.get("items", []).size() - b.found.size()
		if b.over:
			plays["settled"] += 1
			if not Loot.is_empty(b.loot_result["reward"]):
				plays["rewards"] += 1
		fights += 1
		ended[b.winner if b.over else "unfinished"] += 1
		if team_fight:
			waves_met += b.wave
			drawn += b.hand.size()
			if b.wave >= b.waves_total:
				last_waves += 1
			if b.over and b.winner == "ally" and not b.nothing_more_coming():
				wrong.append("a Strike Team's Battle on %s was won with waves still to come" % f.name)
		for l in b.log:
			if l.get("halt", false):
				problems[l["text"]] = problems.get(l["text"], 0) + 1
	for w in wrong.slice(0, 12):
		print("FAIL " + w)
	print("(%d rounds, %d moves, %d attacks, %d of them in Bursts, %d holds, %d beats of Enemy turns; won %d, lost %d, drawn %d, unfinished %d)" % [rounds, moves, attacks, bursts, holds, beats_seen, ended["ally"], ended["enemy"], ended["draw"], ended["unfinished"]])
	print("(%d of them a Strike Team's Battle: %d waves met, %d reached the sixth, %d cards in hand at the end)" % [team_fights, waves_met, last_waves, drawn])
	print("(played from the hand: %d Troops, %d Equipment, %d other cards; %d Consumables used, %d Chips spent; %d of them Recovered a Troop's card; %d taken back; %d that couldn't be played weren't)" % [
		plays["troop"], plays["equipment"], plays["plain"], plays["cons"], plays["chip"], plays["recover"], plays["back"], plays["refused"]])
	print("(0.7: %d cards played for an X, %d asked for more than the Bank held and refused, %d carried Actions used for an X; %d Auto turns in %d beats; %d Enemies dropped loot, %d Loot Tiles and Locked Chests emptied, %d fights settled, %d of them paid a floor's reward; %d Elites and Mini-Bosses sent by Instability)" % [
		plays["x"], plays["x_over"], plays["x_action"], plays["auto"], plays["auto_beats"], plays["drops"], plays["found"], plays["settled"], plays["rewards"], plays["special"]])
	if team_fights > 0 and (plays["troop"] < 5 or plays["equipment"] < 2 or plays["plain"] < 10 or plays["cons"] < 5 or plays["back"] < 5):
		wrong.append("too few cards were played for this to have tried them: %s" % str(plays))
	if fights >= 100 and (plays["x"] < 10 or plays["auto"] < 40 or plays["drops"] < 40 or plays["found"] < 3 or plays["special"] < 3):
		wrong.append("too little of 0.7 was tried: %s" % str(plays))
	if fights >= 100 and plays["items"] < 5:
		wrong.append("too few blueprints and chassis were left behind for this to have tried them: %d" % plays["items"])
	print("(0.8: %d blueprints and chassis left behind in the fights, %d more from floors' rewards)" % [plays["items"], plays["item_rewards"]])
	if not problems.is_empty():
		print("Card problems met on the way (each stops the fight on a box until OK):")
		for p in problems:
			print("   %dx  %s" % [problems[p], p])
	Rules.hooks = {}
	print("\nSOAK PASS %d  FAIL %d" % [fights if wrong.is_empty() else 0, wrong.size()])
	quit(1 if not wrong.is_empty() else 0)
