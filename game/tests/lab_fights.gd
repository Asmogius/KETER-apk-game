## The balance lab's fights (not a test): a stand-in player plays real
## deployment fights on the content the game ships with, and each fight's
## outcome is written out as a line of JSON, for balance_lab.py to gather.
##
## The player, at two levels:
## - careful: every turn it plays what it sensibly can (Troops onto open
##   spawn tiles, Equipment onto its sturdiest Hero, damage at the weakest
##   Enemy in reach, help for the most hurt ally), spends Chips with an effect,
##   and uses Consumables when a Hero is hurt; then each Unit acts on Auto.
## - casual: a card or two a turn, at a target picked at random, and now and
##   then nothing; Consumables only in trouble; then Auto.
##
## The team is one a player would have at that point of a run (the stage):
## starter (Skull 1-2), mid (3-4), late (5-6). The fight is an ambush, a POI's
## floor, or a District Core's last floor (a Boss's where one fits).
##   godot --headless --path . --script res://tests/lab_fights.gd -- export=<zip> skull=<n> kind=<ambush|poi|core> bot=<careful|casual> n=<runs> seed=<n> out=<file> [stage=<starter|mid|late>] [inst=<Instability %>] [district=<1-6>]
extends SceneTree

const Kit := preload("res://tests/team_kit.gd")
const RARITY := ["common", "uncommon", "rare", "epic", "legendary", "mythic"]

var rng := RandomNumberGenerator.new()
var bot := "careful"
var played := 0
var all_floors: Array = []
var inst := 0
var district := "3"
var tune := {}              # the what-if switches (see tune=)
var lab_roster: Roster = null
var show_log := false


func _initialize() -> void:
	_run.call_deferred()


func _args() -> Dictionary:
	var o := {"export": "", "skull": "1", "kind": "ambush", "bot": "careful", "n": "20", "seed": "1", "out": "", "stage": "", "inst": "0", "district": "3", "tune": ""}
	for a in OS.get_cmdline_user_args():
		var kv := str(a).split("=", true, 1)
		if kv.size() == 2:
			o[kv[0]] = kv[1]
	return o


func _run() -> void:
	var o := _args()
	Kit.fresh()
	Deployment.common_designs_free = true
	var x := KeterExport.new()
	if not x.open(o["export"]):
		printerr("can't open the export: " + str(o["export"]))
		quit(2)
		return
	var r := Roster.new(x)
	if o.get("mode", "") == "foes":
		_foes(r, str(o["out"]))
		return
	if o.get("mode", "") == "map":
		var cm := Campaign.new(x, r, x.floors(), 1)
		var w := cm.world
		var by := {}
		for k in w.map.get("tiles", {}):
			var key := "D%s skull %d" % [w.district_of(k), w.skull_of(k)]
			by[key] = int(by.get(key, 0)) + 1
		print(JSON.stringify({"cores": w.cores().keys().map(func(k): return {"tile": k, "district": w.core_at(k), "skull": w.skull_of(k), "dist": w.dist(k, w.dock())}), "tiles": by,
			"draws": ["1", "2", "3", "4", "5", "6"].map(func(d): return {"district": d, "poi": w.draw_floors(d, 3, 2, false, "t" + d), "ambush": w.draw_floors(d, 3, 1, true, "a" + d)})}))
		quit(0)
		return
	var skull := int(o["skull"])
	bot = str(o["bot"])
	inst = int(o["inst"])
	district = str(o["district"])
	for part in str(o["tune"]).split(",", false):
		var kv := part.split(":")
		tune[kv[0]] = float(kv[1]) if kv.size() > 1 else 1.0
	lab_roster = r
	if tune.has("notest"):
		r.cards = r.cards.filter(func(c): return not (str(c.get("_src", "")) == "test" and str(c.get("cardType", "")).to_lower() in ["enemy", "elite", "miniboss", "boss"]))
	show_log = o.get("log", "") == "1"
	rng.seed = int(o["seed"])
	all_floors = x.floors()
	var c := Campaign.new(x, r, all_floors, int(o["seed"]))
	r.progress = c.progress
	var stage: String = o["stage"] if o["stage"] != "" else ("starter" if skull <= 2 else ("mid" if skull <= 4 else "late"))
	var t := team_for(stage, skull, r)
	var lines := PackedStringArray()
	for i in int(o["n"]):
		lines.append(JSON.stringify(run(c, r, t, skull, str(o["kind"]), stage)))
	var f := FileAccess.open(str(o["out"]), FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	quit(0)


## The Enemies as the rules read them, one JSON line each: for the report.
func _foes(r: Roster, out: String) -> void:
	var lines := PackedStringArray()
	for c in r.cards:
		var ty := Roster.type_of(c)
		var ours := ty in ["hero", "troop"] and not str(c.get("name", "")).begins_with("Test ")
		if not ours and not (ty in ["enemy", "elite", "miniboss", "boss"]) and not (str(c.get("cardType", "")) in ["elite", "miniboss", "boss"]):
			continue
		var u := Roster.unit_spec(c)
		var acts := []
		for a in u.get("entries", []):
			if not (a is Dictionary):
				continue
			acts.append({"name": a.get("name"), "kind": a.get("kind"), "role": a.get("role"), "dmg": a.get("damage"), "pen": a.get("armorPenetration"), "hit": a.get("toHit"), "rng": a.get("attackRange"), "text": str(a.get("text", "")).left(120)})
		lines.append(JSON.stringify({"name": c.get("name"), "type": c.get("cardType"), "level": Roster.foe_level(c), "district": Roster.district_of(c),
			"stats": u.get("stats"), "behaviors": u.get("behaviors"), "skull": u.get("skull"), "actions": acts}))
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	quit(0)


# ---------------------------------------------------------------- the team, by the stage of a run
static func rarity_of(c) -> int:
	return maxi(0, RARITY.find(str(c.get("rarity", "")).to_lower())) if c is Dictionary else 0


func team_for(stage: String, skull: int, r: Roster) -> Dictionary:
	var t := StrikeTeams.blank("Lab " + stage)
	var top: int = {"starter": 0, "mid": 2, "late": 4, "late2": 4}[stage]        # the rarest a card may be
	var heroes: Array = {"starter": ["Dock Hand", "Hangar Rifleman", "Field Medic"],
		"mid": ["Volt-Warden Ryska", "Dock Hand", "Field Medic"],
		"late": ["Quillon Vex", "Rictus", "Sable-Nine, Ledger Adept"],
		"late2": ["Ilsa Varn, Jump-Frame Pilot", "Volt-Warden Ryska", "Rictus"]}[stage]       # the hardest hitters instead of the rarest
	t["heroes"] = heroes.filter(func(n): return r.card_named(n) != null)
	t["level"] = clampi(skull, 1, 6)              # the Colony Rank a player would have by then
	var ok_card := func(c) -> bool:
		return c is Dictionary and not str(c.get("name", "")).begins_with("Test ") and rarity_of(c) <= top \
			and not ["design", "prebuilt"].has(str(c.get("_src", ""))) and Roster.district_of(c) in ["", "3", "any", "neu"]
	var best := func(types: Array, n: int) -> Array:
		var cs: Array = r.of_types(types).filter(func(c): return ok_card.call(c))
		cs.sort_custom(func(a, b): return rarity_of(a) > rarity_of(b) if rarity_of(a) != rarity_of(b) else str(a["name"]) < str(b["name"]))
		return cs.slice(0, n)
	# Troops: the starter's 4, then the best Troop cards; then Equipment, Command and Aether cards
	t["deck"]["Frame Trooper"] = 4
	for c in best.call(["troop"], 3):
		t["deck"][str(c["name"])] = 2
	for c in best.call(["equipment", "command", "aether"], 6):
		if StrikeTeams.deck_count(t) >= 20:
			break
		t["deck"][str(c["name"])] = mini(2, 20 - StrikeTeams.deck_count(t))
	if StrikeTeams.deck_count(t) < 10:
		TeamGuide.suggest_deck(t, r)
	# Action cards for each Hero, as many as it has slots
	var acts: Array = best.call(["action"], 9)
	var k := 0
	for h in StrikeTeams.heroes(t, r):
		var slots := StrikeTeams.action_slots(h)
		var mine := []
		while mine.size() < slots and k < acts.size():
			mine.append(str(acts[k]["name"]))
			k += 1
		if not mine.is_empty():
			t["actions"][str(h["name"])] = mine
	# the Pouch: Chips of its cards' Districts, enough for the Player Level, and the best Chips with an effect
	for c in best.call(["sphere"], 2 if stage != "starter" else 0):
		t["pouch"][str(c["name"])] = 2
	TeamGuide.suggest_pouch(t, r)
	var want := maxi(10, StrikeTeams.pouch_minimum(t, r)) + 2 * int(t["level"])
	if StrikeTeams.pouch_count(t, r) < want:
		var key := "basic|3"
		StrikeTeams.set_chips(t, key, int(Rules.num(t["pouch"].get(key), 0)) + want - StrikeTeams.pouch_count(t, r))
	return t


# ---------------------------------------------------------------- a run: an ambush, or a POI's floors
## A POI (or a Core) is its floors in a row, as a deployment plays them: a
## Hero who falls sits out the rest, a Troop copy lost is gone, a lost fight is
## tried again while any Hero is left, and the POI is lost when none is.
func run(c: Campaign, r: Roster, t0: Dictionary, skull: int, kind: String, stage: String) -> Dictionary:
	var t: Dictionary = t0.duplicate(true)
	var count := 1 if kind == "ambush" else (3 if kind == "core" else c.world.floor_count(skull))
	var keys: Array = c.world.draw_floors(district, skull, count, kind == "ambush", str(rng.randi()))
	var out := {"skull": skull, "kind": kind, "bot": bot, "stage": stage, "level": int(t["level"]), "inst": inst, "district": district, "tune": tune,
		"floors": keys.size(), "cleared": 0, "fights": 0, "retries": 0, "heroes_down": 0, "won": false, "fight": []}
	var heroes_out := []
	var i := 0
	while i < keys.size():
		var f := _floor(c, keys[i])
		if f == null:
			out["error"] = "no floor " + str(keys[i])
			return out
		f.district = district
		var left: Array = t["heroes"].filter(func(h): return not heroes_out.has(h))
		if left.is_empty():
			break
		var one := fight(r, t, skull, kind, f, left)
		out["fights"] += 1
		out["fight"].append(one["stats"])
		var res: Dictionary = one["res"]
		for h in res["heroesDown"]:
			if not heroes_out.has(h):
				heroes_out.append(h)
				out["heroes_down"] += 1
		for nm in res["troopsLost"]:
			if int(t["deck"].get(nm, 0)) > 0:
				t["deck"][nm] = int(t["deck"][nm]) - 1
				if int(t["deck"][nm]) <= 0:
					t["deck"].erase(nm)
		if res["winner"] == "ally":
			i += 1
			out["cleared"] = i
		elif out["fights"] > 12:
			break
		else:
			out["retries"] += 1
	out["won"] = out["cleared"] == keys.size() and not keys.is_empty()
	out["rounds"] = out["fight"].reduce(func(a, x): return a + int(x["rounds"]), 0)
	return out


# ---------------------------------------------------------------- a fight
func fight(r: Roster, t: Dictionary, skull: int, kind: String, f: FloorData, left: Array) -> Dictionary:
	var cap := Roster.deploy_capacity(f, skull)
	var entering: Array = left.slice(0, cap)
	var ldr := 0
	for h in entering:
		ldr += StrikeTeams.leadership(r.card_named(h))
	var starters := []
	for e in StrikeTeams.troops_in_deck(t, r):
		for n in e["copies"]:
			var sl := Roster.slots(e["card"])
			if sl <= ldr and (bot == "careful" or rng.randf() < 0.5):
				starters.append(e["card"]["name"])
				ldr -= sl
	var su := StrikeTeams.setup_for(t, r, entering, entering[0], starters, 3, inst)
	su["deploy"] = {"district": district, "skull": skull, "kind": "ambush" if kind == "ambush" else "poi", "pending": [], "bounties": []}
	var b := Battle.begin_team(f, r, su, rng.randi())
	if tune.has("mix"):
		_mix_pile(b, r)
	if tune.has("waves"):
		b.waves_total = maxi(1, b.waves_total + int(tune["waves"]))
	_tune_foes(b)
	played = 0
	while not b.settle() and b.round <= 40:
		_tune_foes(b)
		if tune.has("reshuffle") and b.deck.is_empty() and not b.discard.is_empty():
			var back: Array = b.discard.filter(func(c): return c is Dictionary and str(c.get("type", "")) != "troop")
			b.discard = b.discard.filter(func(c): return not back.has(c))
			back.shuffle()
			b.deck = back
		_my_turn(b)
		if b.settle():
			break
		if bot == "careful":
			_steer(b)
		if b.settle():
			break
		for id in b.auto_queue():
			var u = b.unit_by_id(id)
			if u != null and not Rules.truthy(u.get("down")) and b.enemies_left() > 0:
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
			_tune_foes(b)
	if show_log:
		print("---- %s, skull %d, %s: %s in round %d" % [f.name, skull, kind, b.winner if b.over else "unsettled", b.round])
		for l in b.log:
			print(str(l.get("text", l)) if l is Dictionary else str(l))
		for u in b.units:
			if not Rules.truthy(u.get("down")):
				print("  standing: %s %s hp %s at %s" % [u["side"], u["name"], str(u.get("hp")), str(u.get("pos"))])
	var heroes: Array = b.side_units("ally").filter(func(u): return str(u.get("cardType", "")).to_lower().contains("hero"))
	var foes: Array = b.units.filter(func(u): return u["side"] == "enemy")
	var res := b.deploy_result() if b.over else {"winner": "", "heroesDown": heroes.map(func(u): return str(u["src"] if Rules.truthy(u.get("src")) else u["name"])), "troopsLost": []}
	return {"res": res, "stats": {"won": b.over and b.winner == "ally", "over": b.over, "rounds": b.round, "heroes_in": heroes.size(),
		"down": heroes.filter(func(u): return Rules.truthy(u.get("down"))).size(), "waves": b.waves_total, "wave": b.wave,
		"foes": foes.size(), "foes_left": b.enemies_left(), "elite": foes.filter(func(u): return str(u.get("cardType", "")).to_lower() in ["elite", "miniboss", "boss"]).size(),
		"played": played, "floor": str(f.name), "hp": snappedf(_hp_of(heroes), 0.01), "deck_left": b.deck.size(), "hand_left": b.hand.size()}}


## The what-if switches on the Enemies as they arrive (each once).
func _tune_foes(b: Battle) -> void:
	if not tune.keys().any(func(k): return str(k).begins_with("hp") or str(k).begins_with("ac") or str(k).begins_with("dmg")):
		return
	for u in b.units:
		if u["side"] != "enemy" or u.has("_lab"):
			continue
		u["_lab"] = true
		var card = lab_roster.card_named(str(u["src"] if Rules.truthy(u.get("src")) else u["name"])) if lab_roster != null else null
		var lv := Roster.foe_level(card) if card is Dictionary else 0
		var hp = _knob("hp", lv)
		if hp != null:
			var mx := maxi(1, int(ceil(float(Rules.num(u.get("hpMax"), 1)) * float(hp) / 100.0)))
			u["hpMax"] = mx
			u["hp"] = mini(int(Rules.num(u.get("hp"), mx)), mx)
		var ac = _knob("ac", lv)
		if ac != null:
			u["ac"] = maxi(0, int(Rules.num(u.get("ac"), 10)) + int(ac))
			if u.has("integrity"):
				u["integrity"] = maxi(0, int(Rules.num(u.get("integrity"), 10)) + int(ac))
		var dmg = _knob("dmg", lv)
		if dmg != null:
			for a in u.get("actions", []):
				var d = Rules.num(a.get("dmg"), null)
				if d != null and d > 0 and not a.has("_lab"):       # once, even were the Action shared
					a["_lab"] = true
					a["dmg"] = maxi(1, int(round(float(d) * float(dmg) / 100.0)))


## A what-if for an Enemy of this Skull Level: "hp5:50" for those of level 5, "hp:50" for all.
func _knob(name: String, lv: int) -> Variant:
	if tune.has(name + str(lv)):
		return tune[name + str(lv)]
	return tune.get(name)


## mix: each Enemy in the pile is, one time in two, one drawn a level lower.
func _mix_pile(b: Battle, r: Roster) -> void:
	for e in b.enemy_pile:
		var lv := int(e["level"])
		if lv <= 1 or rng.randf() < 0.5:
			continue
		var pool := r.foe_pool(lv - 1, district)
		if not pool.is_empty():
			e["name"] = str(pool[rng.randi() % pool.size()]["name"])
			e["level"] = lv          # it still answers to the tile's level


## What is left of the Heroes' health, all told (0 to 1).
func _hp_of(heroes: Array) -> float:
	var hp := 0.0
	var mx := 0.0
	for u in heroes:
		hp += maxf(0.0, float(Rules.num(u.get("hp"), 0))) if not Rules.truthy(u.get("down")) else 0.0
		mx += maxf(1.0, float(Rules.num(u.get("hpMax"), 1)))
	return hp / maxf(1.0, mx)


func _floor(c: Campaign, k) -> FloorData:
	if k == null:
		return null
	if ChunkGen.is_gen_key(k):
		var lv := c.world.level(k)
		return FloorData.from_dict(lv) if not lv.is_empty() else null
	for f in all_floors:
		if str(f.raw.get("_key", f.name)) == str(k) or f.name == str(k):
			return FloorData.from_dict(f.raw)
	return null


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
			order.shuffle()
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
			var ok := false
			match st["kind"]:
				"troop":
					ok = b.play_troop(i, null, x) != null
				"equipment":
					var mine := b.side_units("ally").filter(func(u): return not Rules.truthy(u.get("down")))
					if bot == "careful":
						mine.sort_custom(func(a, c): return float(Rules.num(a.get("hpMax"), 0)) > float(Rules.num(c.get("hpMax"), 0)))
					else:
						mine.shuffle()
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


func _rank(h: Dictionary) -> int:
	return {"troop": 0, "equipment": 1}.get(str(h.get("type", "")), 2)
