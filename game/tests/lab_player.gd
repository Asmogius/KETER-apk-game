## The balance lab's stand-in player (not a test): plays one fight, a Battle
## already begun, to its end or to a round limit. The fight lab
## (lab_fights.gd) and the campaign lab (lab_campaign.gd) both play through it.
##
## At two levels:
## - careful: every turn it plays what it sensibly can (Troops onto open
##   spawn tiles, Equipment onto its sturdiest Unit, damage at the weakest
##   Enemy in reach, help only when an ally is hurt), spends Chips with an
##   effect (never one that Sacrifices its own) and uses Consumables when a
##   Hero is hurt; then it moves and aims each Unit by hand, and leaves a
##   Medic's care, or a Unit with nothing to do, to Auto.
## - casual: a card or two a turn at a target picked at random, a Chip now
##   and then, Consumables only in trouble; then every Unit on Auto.
extends RefCounted

var bot := "careful"
var rng: RandomNumberGenerator
var played := 0                 # cards played in the last fight


func _init(style: String, generator: RandomNumberGenerator) -> void:
	bot = style
	rng = generator


## The Starting Troops a player takes in: as many as the entering Heroes'
## Leadership holds (careful), or about half of them (casual).
func starters(t: Dictionary, r: Roster, entering: Array) -> Array:
	var ldr := 0
	for h in entering:
		ldr += StrikeTeams.leadership(r.card_named(h))
	var out := []
	for e in StrikeTeams.troops_in_deck(t, r):
		for n in e["copies"]:
			var sl := Roster.slots(e["card"])
			if sl <= ldr and (bot == "careful" or rng.randf() < 0.5):
				out.append(e["card"]["name"])
				ldr -= sl
	return out


## Plays the fight: the player's turn, then Auto (one that arrives meanwhile
## takes its turn too, as in the game), then the Enemies, round after round,
## until it settles or the round limit passes. before(b) is called at the start
## of each round's turn, after(b) once each round has turned over.
func play(b: Battle, before := Callable(), after := Callable(), most := 40) -> void:
	played = 0
	while not b.settle() and b.round <= most:
		if before.is_valid():
			before.call(b)
		_my_turn(b)
		if b.settle():
			break
		if bot == "careful":
			_steer(b)
		if b.settle():
			break
		var line := b.auto_queue()
		var at := 0
		while not b.settle():
			if at >= line.size():
				var more := b.auto_queue().filter(func(i): return not line.has(i))
				if more.is_empty():
					break
				line.append_array(more)
			var u = b.unit_by_id(line[at])
			at += 1
			if u != null and not Rules.truthy(u.get("down")) and not b.has_acted(u) and b.enemies_left() > 0:
				b.auto_turn(u)
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
			if after.is_valid():
				after.call(b)


## What a fight came to, for the lab's lines.
func stats(b: Battle, floor_name: String) -> Dictionary:
	var heroes: Array = b.side_units("ally").filter(func(u): return str(u.get("cardType", "")).to_lower().contains("hero"))
	var foes: Array = b.units.filter(func(u): return u["side"] == "enemy")
	return {"won": b.over and b.winner == "ally", "over": b.over, "rounds": b.round, "heroes_in": heroes.size(),
		"down": heroes.filter(func(u): return Rules.truthy(u.get("down"))).size(), "waves": b.waves_total, "wave": b.wave,
		"foes": foes.size(), "foes_left": b.enemies_left(), "elite": foes.filter(func(u): return str(u.get("cardType", "")).to_lower() in ["elite", "miniboss", "boss"]).size(),
		"played": played, "floor": floor_name, "hp": snappedf(hp_of(heroes), 0.01), "deck_left": b.deck.size(), "hand_left": b.hand.size()}


## What is left of the Heroes' health, all told (0 to 1).
static func hp_of(heroes: Array) -> float:
	var hp := 0.0
	var mx := 0.0
	for u in heroes:
		hp += maxf(0.0, float(Rules.num(u.get("hp"), 0))) if not Rules.truthy(u.get("down")) else 0.0
		mx += maxf(1.0, float(Rules.num(u.get("hpMax"), 1)))
	return hp / maxf(1.0, mx)


# ---------------------------------------------------------------- the player's turn
func _hurt(u: Dictionary) -> float:
	return float(Rules.num(u.get("hp"), 0)) / maxf(1.0, float(Rules.num(u.get("hpMax"), 1)))


## Whom to aim at: careful picks well, casual at random.
func _aim(b: Battle, needs: Dictionary) -> Variant:
	var pool := b.pool_for_need(needs)
	if pool.is_empty():
		return null
	if bot == "casual":
		return pool[rng.randi() % pool.size()]
	if needs["need"] == "enemy":
		pool.sort_custom(func(a, c): return float(Rules.num(a.get("hp"), 0)) < float(Rules.num(c.get("hp"), 0)))
	else:
		pool.sort_custom(func(a, c): return _hurt(a) < _hurt(c))
	return pool[0]


func _tile(b: Battle) -> Variant:
	var foes := b.side_units("enemy").filter(func(u): return not Rules.truthy(u.get("down")) and u.get("pos") is Dictionary)
	if foes.is_empty():
		return null
	var u: Dictionary = foes[rng.randi() % foes.size()] if bot == "casual" else foes[0]
	return Battle.tile_of(u)


## Help for allies only when someone needs it (careful).
func _worth(b: Battle, needs: Dictionary) -> bool:
	if bot == "casual" or needs["need"] != "ally":
		return true
	return b.side_units("ally").any(func(u): return not Rules.truthy(u.get("down")) and _hurt(u) < 0.8)


func _my_turn(b: Battle) -> void:
	var budget := 12 if bot == "careful" else (rng.randi_range(0, 2))
	var guard := 0
	while budget > 0 and guard < 30 and not b.settle():
		guard += 1
		var did := false
		var order := range(b.hand.size())
		if bot == "casual":
			_shuffle(order)
		else:
			# Troops first, then Equipment, then the rest
			order.sort_custom(func(i, j): return _rank(b.hand[i]) < _rank(b.hand[j]))
		for i in order:
			if i >= b.hand.size():
				continue
			var h: Dictionary = b.hand[i]
			var st0 := b.play_state(h)
			var x = st0["max_x"] if st0["variable"] else null
			var st := b.play_state(h, x) if x != null else st0
			if not st["ok"]:
				continue
			if bot == "careful" and _harms_own(str(h.get("text", ""))):
				continue
			var ok := false
			match st["kind"]:
				"troop":
					ok = b.play_troop(i, null, x) != null
				"equipment":
					var mine := b.side_units("ally").filter(func(u): return not Rules.truthy(u.get("down")))
					if bot == "careful":
						mine.sort_custom(func(a, c): return float(Rules.num(a.get("hpMax"), 0)) > float(Rules.num(c.get("hpMax"), 0)))
					else:
						_shuffle(mine)
					ok = not mine.is_empty() and b.play_equipment(i, mine[0], x)
				_:
					var needs: Dictionary = st["needs"]
					if not _worth(b, needs):
						continue
					if needs["need"] == "tile":
						var tl = _tile(b)
						ok = tl != null and b.play_card(i, null, tl, null, x)
					elif needs["need"] == "enemy" or needs["need"] == "ally":
						var tg = _aim(b, needs)
						ok = tg != null and b.play_card(i, tg, null, null, x)
					else:
						ok = b.play_card(i, null, null, null, x)
			if ok:
				played += 1
				budget -= 1
				did = true
				break
		if not did:
			break
	# Chips with an effect, and Consumables
	for i in b.bank.size():
		if b.settle():
			return
		if bot == "casual" and rng.randf() < 0.5:
			continue
		var cs := b.chip_state(i)
		if bot == "careful" and _harms_own(b.chip_text(b.bank[i])):
			continue
		if cs["ok"] and _worth(b, cs["needs"]):
			var tg = _aim(b, cs["needs"]) if (cs["needs"]["need"] == "enemy" or cs["needs"]["need"] == "ally") else null
			b.spend_chip(i, tg)
	var low := 0.5 if bot == "careful" else 0.3
	var trouble := b.side_units("ally").any(func(u): return str(u.get("cardType", "")).to_lower().contains("hero") and not Rules.truthy(u.get("down")) and _hurt(u) < low)
	for i in b.consumables.size():
		if b.settle():
			return
		var cn := b.consumable_state(i)
		if not cn["ok"]:
			continue
		var need: String = cn["needs"]["need"]
		if need == "ally" and not trouble:
			continue
		if need != "enemy" and need != "ally" and not trouble:
			continue
		if need == "tile":
			var tl = _tile(b)
			if tl != null:
				b.use_consumable(i, null, tl)
		else:
			b.use_consumable(i, _aim(b, cn["needs"]) if (need == "enemy" or need == "ally") else null)


# ---------------------------------------------------------------- careful: each Unit by hand
## A careful player moves and aims each Unit: from the tile it can move to
## that gives the best shot (what it would deal, by the odds, and a kill
## counts for more), at the best target; with nothing in reach anywhere, as
## near the Enemy as it can get. A Unit with a Medic's care to give, or one
## that can do nothing, is left to Auto.
func _steer(b: Battle) -> void:
	for id in b.auto_queue():
		if b.settle():
			return
		var u = b.unit_by_id(id)
		if u == null or Rules.truthy(u.get("down")) or not (u.get("pos") is Dictionary):
			continue
		var allies: Array = b.side_units("ally").filter(func(x): return not Rules.truthy(x.get("down")) and x.get("pos") is Dictionary)
		if Rules.support_plan(u, allies) != null:
			continue
		var shot := _best_shot(b, u)
		if shot.is_empty() and b.can_move(u) and not b.has_moved(u):
			var home: Dictionary = u["pos"].duplicate()
			var pick = null
			var top := -float(_nearest(b, u))     # where it stands: nothing in reach
			for t in b.reach(u):
				var at := Vector2i(int(t["q"]), int(t["r"]))
				if b.fx.hazard_at(at) != null:
					continue
				u["pos"] = {"q": at.x, "r": at.y}
				var s2 := _best_shot(b, u)
				var score: float = (1000.0 + float(s2["ev"]) * 10.0 if not s2.is_empty() else 0.0) - float(_nearest(b, u)) - float(t["cost"]) * 0.01
				if score > top:
					top = score
					pick = at
			u["pos"] = home
			if pick != null:
				b.move(u, pick)
			shot = _best_shot(b, u)
		if shot.is_empty() or Rules.truthy(u.get("down")):
			continue
		var a: Dictionary = shot["a"]
		if a.get("aetherX") is Dictionary:
			Battle.set_action_x(a, 1)
		var res := b.attack(u, a, shot["t"])
		var left := 0
		while res.has("burst") and not Rules.truthy(u.get("down")) and not b.settle() and left < 10:
			left += 1
			var pool: Array = res["burst"]["pool"].map(func(i): return b.unit_by_id(i)).filter(func(x): return x != null)
			if pool.is_empty():
				break
			pool.sort_custom(func(x, y): return float(Rules.num(x.get("hp"), 0)) < float(Rules.num(y.get("hp"), 0)))
			res = b.attack(u, a, pool[0], int(res["burst"]["left"]) - 1)


## The best Action and target a Unit has from where it stands: {a, t, ev}, or {}.
func _best_shot(b: Battle, u: Dictionary) -> Dictionary:
	var foes: Array = b.side_units("enemy").filter(func(x): return not Rules.truthy(x.get("down")) and x.get("pos") is Dictionary)
	var out := {}
	for a in Battle.usable_actions(u):
		if Battle.self_only(a) or Battle.tile_action(a) or Battle.role_of(a) == "support":
			continue
		if not Rules.can_afford(u, a) or not b.aether_ok(u, a) or Rules.effective(u)["cannotAct"]:
			continue
		for f in foes:
			if not b.can_reach(u, a, f):
				continue
			var o := b.odds(u, a, f)
			var hp := float(Rules.num(f.get("hp"), 0))
			var ev := float(o["p"]) * minf(float(o["dmg"]), hp) + (float(o["p"]) * 8.0 if float(o["dmg"]) >= hp else 0.0)
			var blast := Battle.kw_num(a, "AoE")
			if blast > 0:
				for m in b.side_units("ally"):
					if m != u and not Rules.truthy(m.get("down")) and m.get("pos") is Dictionary and Rules.hex_distance(m["pos"], f["pos"]) <= blast:
						ev -= float(o["p"]) * float(o["dmg"]) * (3.0 if str(m.get("cardType", "")).to_lower().contains("hero") else 1.5)
			if ev <= 0.0:
				continue
			if out.is_empty() or ev > float(out["ev"]):
				out = {"a": a, "t": f, "ev": ev}
	return out


func _nearest(b: Battle, u: Dictionary) -> int:
	return _nearest_at(b, u, Vector2i(int(u["pos"]["q"]), int(u["pos"]["r"])))


func _nearest_at(b: Battle, _u: Dictionary, at: Vector2i) -> int:
	var n := 1 << 20
	for f in b.side_units("enemy"):
		if not Rules.truthy(f.get("down")) and f.get("pos") is Dictionary:
			n = mini(n, Rules.hex_distance({"q": at.x, "r": at.y}, f["pos"]))
	return n


## A careful player doesn't spend its own Units for Aether, nor hurt them.
func _harms_own(text: String) -> bool:
	return text.to_lower().contains("sacrific")


## A shuffle by the lab's own seeded stream, so a run can be played again.
func _shuffle(list: Array) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = list[i]
		list[i] = list[j]
		list[j] = t


func _rank(h: Dictionary) -> int:
	return {"troop": 0, "equipment": 1}.get(str(h.get("type", "")), 2)
