## A battle in progress: the floor, every Unit on it and where it stands, the
## round and its phases, the waves still to come, the Strike Team's Aether,
## Deck and hand, and what has happened. The rules themselves are in rules.gd and what
## cards say is carried out by effects.gd; this keeps the state they work on,
## answers the board's questions (who is here, where can it go, what can it
## hit), and runs the parts of a fight that need the board: aiming, Cover,
## attacks, the Enemies' own turns, and the round turning over.
##
## Those parts are the Companion's Battle Simulator, brought across (simCanReach,
## simCoverFor, simApplyAttack, simOneEnemy and their helpers), and proved to
## match it case by case (tests/sim_diff.gd). Units are the rules' own
## Dictionaries, with pos = {q, r} as in the simulator.
class_name Battle
extends RefCounted

var floor_data: FloorData
var roster: Roster
var units: Array = []
var cards: Array = []         # every card, for a Deploy to find what it names
var looks := {}               # unit id -> {texture, hexagon} or {}
var round := 1
var moved := {}               # unit id -> the tiles it has moved this round, once it has moved
var dash_used := {}           # unit id -> the tiles of a Dash it has moved this round (Revision 16.1)
var notes: Array[String] = [] # what happened setting up, worth telling the player
var rng := RandomNumberGenerator.new()
var dice: Rules.Dice
## What has happened: {round, text, kind}. kind "act" is what the simulator
## would log too (attacks, effects, hazards, statuses ticking); "note" is the
## game's own news (the round's number, how it ended). A line may also carry
## plain (text with no keywords, not carried out), halt (a card problem),
## recharge (it happened as the round began) or rolls.
var log: Array = []
var over := false
var winner := ""              # "ally", "enemy" or "draw", once it's over
var undo: Array = []          # what the battle was before each move that can still be taken back
var fx: Effects               # the effect engine
var leader_id := ""           # the Strike Team's leader (its first Hero if unset)
var protos: Array = []        # the Strike Team's Prototypes (with cards, 0.5)
var discard: Array = []       # cards taken off Units (with cards, 0.5)
var halts: Array = []         # card problems the player hasn't been shown yet
var floats: Array = []        # {unit, text, kind}: numbers and words to rise off Units
var beats: Array = []         # what an Enemy's turn did, beat by beat, for the board to play
var deployed := 0             # Units put down by a Deploy, for their ids
## A Strike Team's fight has the whole round: six waves, Aether, Chips, a Deck
## and a hand. A Quick battle (and a battle made by hand) has one wave and none
## of the rest.
var with_cards := false
var floor_rev := 0            # Revision 16.3: goes up when the fight changes its floor (a Barricade), for the board to redraw
var _own_floor := false       # the floor has been copied for this fight to change
var phase := "turn"           # where the round is: a key from PHASES
var waves_total := 1
var wave := 1                 # the wave that has arrived (1 to waves_total)
var wave_turn := 0            # rounds since it did
var wave_timer := 3           # the next arrives after this many, or when the board is clear
var enemy_pile: Array = []    # {name, level}: the Enemies that can still arrive
var player_level := 1         # Chips drawn each round
var aether := {}              # this turn's Aether: {"d3": 2, "generic": 1}
var bank: Array = []          # Chips drawn so far: {name, value, district, text, spent}
var pouch: Array = []         # Chips still in the Pouch
var deck: Array = []          # cards still to draw, the next first
var hand: Array = []
var consumables: Array = []   # what the Strike Team carries: {name, used, text}
var instability := 0          # Dimensional Instability: the chance in 100 a spawn brings an Elite or a Mini-Boss
# 0.7: loot. Shown as it drops and totalled when the fight ends; not kept yet.
var loot_table: Loot          # the tables, and the stream that rolls
var loot := Loot.bag()        # everything dropped and found so far
var looted := {}              # Loot Tiles and chests already searched: tile -> true
var loot_result := {}         # once the fight is over: {won, haul, reward, total, items}
# 0.8: blueprints and chassis, and fights on a deployment.
var progress: Progress = null # what you own, so only what you lack can drop
var found: Array = []         # blueprints and chassis found in this fight: "bp:Burst:1", "ch:<id>"
## On a deployment: {district, skull, kind ("poi" or "ambush"), pending (what
## the deployment has found already)}. The tile's Skull Level sets the
## Enemies and the loot; inside a POI a Hero may leave by an Emergency Exit.
var deploy = null
var _salvaged := {}           # Enemies whose drop has been rolled: id -> true
var _walls := {}              # "q,r|q,r" -> true, both ways round
var _wall_dict := {}          # as the floor saved them
var _segs := []               # the walls as line segments, for sight
var _next := {"ally": 0, "enemy": 0}
## (0.26) Pass and play: two Strike Teams, two players, one phone. 0 for any
## other fight; 1 or 2, the player whose turn it is. The engine always sees the
## player whose turn it is as "ally" and the other as "enemy": at each hand-off
## every Unit changes side, and the two players' Aether, Chips, Deck, hand,
## Consumables, Prototypes and leader change places (pvp_store holds the one
## waiting). No Enemy waves come, and no Enemy turn is played.
var pvp := 0
var pvp_store := {}           # the waiting player's: {aether, bank, pouch, deck, hand, discard, consumables, protos, leader_id, player_level, opened}
var pvp_names := {1: "Player 1", 2: "Player 2"}
var pvp_opened := {1: true, 2: false}   # whether a player has had the opening Aether, Chips and six cards

## Cover a Barricade tile gives (Handbook: Half +2, Full +4 to be hit).
const COVER := {"cover-half": 2, "cover-full": 4}
## Handbook, Section 6: every Floor is fought in six waves.
const WAVES_PER_FLOOR := 6
## The round, in the Handbook's order (the simulator's SIM_PHASES).
const PHASES := [
	{"k": "waves", "name": "Waves", "hint": "Enemies arrive at every Spawn Tile."},
	{"k": "gen", "name": "Aether Generation", "hint": "Heroes generate Aether of their own Affinity."},
	{"k": "chips", "name": "Aether Draw", "hint": "Chips are drawn from the Pouch into the Bank."},
	{"k": "draw", "name": "Draw", "hint": "One card per Hero on the Battlefield."},
	{"k": "recharge", "name": "Recharge", "hint": "Statuses from your turn tick, and spent Chips turn face-up again."},
	{"k": "turn", "name": "Your turn", "hint": "Move and act in any order."},
	{"k": "enemy", "name": "Enemy turn", "hint": "Statuses from the Enemies' turn tick, then each Enemy moves and acts."}]


## Sets up a battle: the Heroes and Troops you chose on your spawn tiles, and
## an Enemy on every Enemy spawn tile. A seed makes the Enemies the same each time.
static func begin(f: FloorData, r: Roster, hero_cards: Array, troop_cards: Array, seed = null) -> Battle:
	var b := Battle.new()
	b.roster = r
	b.cards = r.cards
	b._set_floor(f, seed)
	for c in hero_cards:
		b._add(c, "ally", r.token_for(c))
	for c in troop_cards:
		x_fill(b._add(c, "ally", r.token_for(c)))
	b._place_allies()
	b.deploy_start()
	b._spawn_enemies()
	b.floats.clear()              # nothing floats before the board is up
	return b


## Sets up a Strike Team's fight (the end of the simulator's setup wizard,
## simWizFinish): the Heroes who enter, each with the Action cards it carries;
## Starting Troops, taken out of the Deck; the Deck shuffled; the Aether Pouch
## filled; the Enemy pile dealt for six waves; Prototypes; then the first wave
## arrives, the Heroes generate Aether, Chips are drawn and six cards are dealt.
## setup: heroes (cards, in the team's order), leader (a Hero's name),
## actions ({Hero name: [Action cards]}), start_troops (names), deck (cards),
## pouch ({chip: how many}), level, protos (names), wave_timer.
static func begin_team(f: FloorData, r: Roster, setup: Dictionary, seed = null) -> Battle:
	var b := Battle.new()
	b.roster = r
	b.cards = r.cards
	b._set_floor(f, seed)
	if setup.get("deploy") is Dictionary:
		var dp: Dictionary = setup["deploy"]
		var dsk = Rules.num(dp.get("skull"), 1)
		b.deploy = {"district": str(dp.get("district", "")), "skull": clampi(int(dsk) if Rules.truthy(dsk) else 1, 1, 6), "kind": str(dp.get("kind", "ambush")),
			"pending": dp["pending"].duplicate() if dp.get("pending") is Array else [],
			"bounties": dp["bounties"].duplicate() if dp.get("bounties") is Array else []}
	b.with_cards = true
	# (0.36) a deployment's fight has fewer waves at a low Skull Level, and one fewer in an ambush
	b.waves_total = Deployment.waves_for(b.deploy["skull"], b.deploy["kind"]) if b.deploy != null else WAVES_PER_FLOOR
	b.wave = 0
	b._build_team(setup, "ally")
	# The Enemy pile: six for every Spawn Tile at its level, from the floor's District
	var want := {}
	for t in b.enemy_spawns():
		want[t["level"]] = want.get(t["level"], 0) + b.waves_total
	var levels: Array = want.keys()
	levels.sort()
	var real := b.deploy != null
	for level in levels:
		var pool := r.foe_pool(level, f.district, real)
		if pool.is_empty():
			continue
		# (0.40) on a deployment, one Enemy in two is drawn from the level below
		var lower: Array = r.foe_pool(level - 1, f.district, true) if real and level > 1 else []
		for i in want[level]:
			var from: Array = lower if not lower.is_empty() and b.dice.roll("d6") <= 3 else pool
			var c: Dictionary = from[int(floor(float(b.dice.roll("d20")) / 21.0 * from.size()))]
			b.enemy_pile.append({"name": c["name"], "level": level})
	b._shuffle(b.enemy_pile)
	b._place_allies()
	b.deploy_start()
	b.spawn_wave()
	b._income()
	b.phase_chips()
	b.phase_draw(true)
	b.phase = "turn"
	return b


## A Strike Team on one side (0.26: begin_team's, and each side's in a
## pass-and-play match): its Heroes, each with the Action cards it carries
## and their Aether costs; its leader; its Starting Troops, out of the Deck;
## its level, wave timer and Instability; its Deck, shuffled; its Pouch; its
## Prototypes; and its Consumables. The dice are rolled as begin_team always
## rolled them: the Deck's shuffle first.
func _build_team(setup: Dictionary, side: String) -> void:
	var r := roster
	var heroes: Array = setup.get("heroes", [])
	var carried_by: Dictionary = setup.get("actions", {})
	for i in heroes.size():
		var hc: Dictionary = heroes[i]
		# The Action cards a Hero carries become Actions of that Hero
		var carried := []
		for ac in carried_by.get(hc.get("name"), []):
			if not (ac is Dictionary):
				continue
			for a in Roster.entries_of(ac):
				if str(a.get("text", "") if a.get("text") != null else "").strip_edges() == "" and str(a.get("name", "") if a.get("name") != null else "").strip_edges() == "":
					continue
				var copy: Dictionary = a.duplicate(true)
				copy["name"] = a["name"] if Rules.truthy(a.get("name")) else ac.get("name")
				copy["from"] = ac.get("name")
				carried.append(copy)
		var u := _add(hc, side, r.token_for(hc), carried)
		# An Action card prints its use cost: Energy, Aether, or both. The
		# Aether part is paid from the Bank at every use. (Handbook, Section 3)
		for ac in carried_by.get(hc.get("name"), []):
			if not (ac is Dictionary):
				continue
			# 0.7: with a variable cost, X is chosen each time it is used. Until
			# then it stands at 1, the least it can be: what it needs, how it reads.
			var hcard := Roster.hand_card(ac)
			var vary := Roster.card_var(hcard)
			var cost := Roster.card_cost(hcard, 1 if vary else null)
			if cost["generic"] == 0 and cost["affinity"] == 0:
				continue
			for a in Roster.entries_of(ac):
				var nm = a["name"] if Rules.truthy(a.get("name")) else ac.get("name")
				for ai in range(u["actions"].size() - 1, -1, -1):
					var ua: Dictionary = u["actions"][ai]
					if ua["name"] == nm and not Rules.truthy(ua.get("aether")):
						ua["aether"] = cost.duplicate()
						if vary:
							ua["aetherX"] = {"generic": hcard["cost"]["generic"], "affinity": hcard["cost"]["affinity"]}
							ua["textX"] = ua["text"]
							ua["x"] = 1
							ua["text"] = Keywords.fill_x(ua["textX"], 1)
						break
		if hc.get("name") == setup.get("leader") or (leader_id == "" and i == 0):
			leader_id = u["id"]
	# Starting Troops come out of the Deck and begin on Player Spawn Tiles
	var starters: Array = setup.get("start_troops", [])
	var started := []
	for nm in starters:
		var c = r.card_named(str(nm))
		if c != null:
			started.append({"name": str(nm), "unit": x_fill(_add(c, side, r.token_for(c)))})      # nobody paid: X is 1
	var lv = Rules.num(setup.get("level"), 1)
	player_level = clampi(int(lv) if Rules.truthy(lv) else 1, 1, 6)
	var wt = Rules.num(setup.get("wave_timer"), 3)
	wave_timer = int(wt) if Rules.truthy(wt) else 3
	var inst = Rules.num(setup.get("instability"), 0)
	instability = clampi(int(inst) if Rules.truthy(inst) else 0, 0, 100)
	deck = setup.get("deck", []).map(func(c): return Roster.hand_card(c))
	_shuffle(deck)
	# The Pouch is what the Strike Team carries: each Chip, as many as were packed
	var packed: Dictionary = setup.get("pouch", {})
	for k in packed:
		var qty = Rules.num(packed[k], 0)
		qty = int(qty) if Rules.truthy(qty) else 0
		var basic := str(k).begins_with("basic|")
		var card = null if basic else r.card_named(Roster.ref_name(str(k)))
		for i in qty:
			pouch.append(Roster.chip_of(str(k), card))
	# Prototypes are the Strike Team's, kept apart from the Deck
	for name in setup.get("protos", []):
		var c = r.card_named(str(name))
		var ents: Array = Roster.entries_of(c) if c != null else []
		protos.append({"name": c["name"] if c != null else name,
			"text": " ".join(ents.map(func(a): return a.get("text")).filter(func(t): return Rules.truthy(t))),
			"fx": ents.filter(func(a): return str(a.get("text", "") if a.get("text") != null else "").strip_edges() != "").map(func(a):
				return {"kind": a["kind"] if Rules.truthy(a.get("kind")) else (a["tag"] if Rules.truthy(a.get("tag")) else "Passive"), "text": a["text"]})})
	for nm in starters:
		for i in deck.size():
			if deck[i]["name"] == nm:
				# the card goes with its Troop, and to the Discard Pile when it falls
				var took: Dictionary = deck.pop_at(i)
				for st in started:
					if st["name"] == nm and not (st["unit"].get("card") is Dictionary):
						st["unit"]["card"] = took
						break
				break
	# Consumables are always to hand, cost no Aether, and are used once each
	var packed_cons: Dictionary = setup.get("consumables", {})
	for name in packed_cons:
		var cc = r.card_named(str(name))
		var n = Rules.num(packed_cons[name], 0)
		for i in (int(n) if Rules.truthy(n) else 0):
			consumables.append({"name": str(name), "used": false,
				"text": " ".join(Roster.entries_of(cc).map(func(a): return a.get("text")).filter(func(t): return Rules.truthy(t))) if cc != null else ""})


## The simulator's shuffle: the battle's own dice decide it, so a seed deals the same.
func _shuffle(list: Array) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := int(floor(float(dice.roll("d20")) / 21.0 * (i + 1)))
		var t = list[i]
		list[i] = list[j]
		list[j] = t


## A battle from Units already made and placed (the tests build these).
static func from_state(f: FloorData, unit_list: Array, seed = null, card_list: Array = []) -> Battle:
	var b := Battle.new()
	b._set_floor(f, seed)
	b.units = unit_list
	b.cards = card_list
	for u in unit_list:
		b.looks[u["id"]] = {}
	return b


func _set_floor(f: FloorData, seed) -> void:
	floor_data = f
	fx = Effects.new(self)
	if seed != null:
		rng.seed = int(seed)
		dice = Rules.make_dice(int(seed))
	else:
		rng.randomize()
		dice = Rules.make_dice()
	# loot has a stream of its own, so the fight's dice roll what they would have
	loot_table = Loot.new(roster.loot_tables() if roster != null else null, seed)
	if roster != null and roster.progress != null:
		progress = roster.progress
	elif roster != null and roster.data != null:
		progress = Progress.new(loot_table, roster.data.content("pools"), roster.data.content("chassis"), roster.data.content("tables"))
	else:
		progress = Progress.new(loot_table)
	# (0.10: a District fought in, for the dock's Exchange and Bounty Board)
	if progress != null and f.district != "":
		progress.see("district", f.district)
	for w in f.walls:
		_walls[Hex.key(w[0]) + "|" + Hex.key(w[1])] = true
		_walls[Hex.key(w[1]) + "|" + Hex.key(w[0])] = true
	for pair in f.raw.get("walls", []):
		if pair is Array and pair.size() >= 1:
			_wall_dict[str(pair[0])] = pair[1] if pair.size() > 1 else -1
	_segs = Rules.wall_segments(_wall_dict)


## The rules tell this battle's effect engine about damage and statuses as
## they happen (one battle at a time listens).
func _hook() -> void:
	Rules.hooks = {"hit": fx.on_hit, "status": fx.on_status, "half": half}


## Which half of the round this is (Handbook 15.9). Yours runs from the
## Recharge to the end of your turn; the Enemies' is everything else: their
## turn, its end, the next wave, the Aether and the draw. A Status ticks at
## the end of the half after the one it arrived in. (simHalf)
func half() -> String:
	if pvp > 0:
		return "ally" if phase in ["turn", "recharge", "handoff"] else "enemy"     # (0.26) a turn's end is that player's half
	return "ally" if (phase == "turn" or phase == "recharge") else "enemy"


## What a tick did, told as the Recharge tells it.
func _tell_tick(events: Array, tag: String) -> void:
	for ev in events:
		var u2 = unit_by_id(ev["unit"]) if ev.has("unit") else null
		var nm: String = u2["name"] if u2 != null else "A Unit"
		if ev["type"] == "tick":
			say("%s takes %s from %s" % [nm, str(ev["damage"]), ev["name"]], "act", {tag: true})
			if u2 != null:
				fx.float_on(u2, "-%s HP" % str(ev["damage"]), "damage")
		elif ev["type"] == "status" and Rules.truthy(ev.get("expired")):
			say("%s is no longer %s" % [nm, ev["name"]], "act", {tag: true})
		elif ev["type"] == "mod" and Rules.truthy(ev.get("expired")):
			say("%s's %s change wears off" % [nm, ev["stat"]], "act", {tag: true})


## Your turn is over (Handbook 15.9): the Statuses and timed changes that
## arrived in the Enemies' half tick now, as the rest tick at the Recharge.
## Asking twice does nothing the second time. (simTurnEndTick)
func end_player_turn() -> void:
	_hook()
	if phase != "turn" or over:
		return
	undo.clear()
	phase = "enemy"
	# Revision 16.1: a Dash is for the turn it was given in
	for u in units:
		if u["side"] == "ally" and Rules.truthy(u.get("dash")):
			u["dash"] = 0
	_tell_tick(Rules.turn_end_tick(units), "turnend")
	fx.check_downs()


## The fight begins: what is always on is worked out, and every Unit of yours
## on the board has been deployed. (the end of simPlace)
func deploy_start() -> void:
	_hook()
	fx.halted_passives = {}
	fx.queue = []
	fx.apply_continuous()
	for u in units.duplicate():
		if u["side"] == "ally" and Rules.truthy(u.get("pos")):
			fx.emit("is deployed", u)
	fx.flush()


## A Unit arrives on the board during the fight: the tile it lands on may
## bite, and its arriving is an event. (as simSpawnWave does for each Enemy)
func arrive(u: Dictionary) -> void:
	_hook()
	fx.hazard_hit(u, "arrives on")
	fx.run_trigger(u, "deployed")


func _add(card: Dictionary, side: String, look: Dictionary, carried: Array = []) -> Dictionary:
	var spec := Roster.unit_spec(card)
	if not carried.is_empty():
		spec["entries"] = (spec["entries"] if spec.get("entries") is Array else []) + carried
	var nm := str(card.get("name", "Unit"))
	var n := units.filter(func(u): return u["side"] == side and (u["name"] == nm or str(u["name"]).begins_with(nm + " "))).size()
	spec["name"] = nm + ((" " + str(n + 1)) if n > 0 else "")
	var u := Rules.unit_from_card(spec, side)
	_next[side] += 1
	u["id"] = ("a" if side == "ally" else "e") + str(_next[side])
	units.append(u)
	looks[u["id"]] = look
	return u


# ---------------------------------------------------------------- the floor
## Revision 16.3: a Half or Full Cover Barricade on an empty tile, for the rest
## of the fight. The floor is copied first, so the floor itself is not changed.
## False when the tile is not empty (a Unit, cover, a spawn or anything else on it).
func place_barricade(h: Vector2i, which: String) -> bool:
	if floor_data == null or not floor_data.has_tile(h) or unit_at(h) != null or kind_at(h) != "":
		return false
	if not _own_floor:
		floor_data = floor_data.copy()
		_own_floor = true
	var t = floor_data.tiles.get(h, {})
	var nt: Dictionary = t.duplicate() if t is Dictionary else {}
	nt["c"] = floor_data.cover_colour(which)
	floor_data.tiles[h] = nt
	floor_rev += 1
	return true


## What a tile's colour means for a battle (the simulator's simTileKind).
func kind_at(h: Vector2i) -> String:
	var t := floor_data.label_of(h).to_lower()
	if Keywords._re("player\\s*spawn").search(t): return "spawn-ally"
	if Keywords._re("enemy\\s*spawn").search(t): return "spawn-enemy"
	if Keywords._re("full\\s*cover").search(t): return "cover-full"
	if Keywords._re("half\\s*cover").search(t): return "cover-half"
	if "heal" in t: return "healing"
	if "loot" in t: return "loot"
	return ""


## Your spawn tiles, in the order the floor lists its tiles.
func ally_spawns() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for h in floor_data.tiles:
		if kind_at(h) == "spawn-ally":
			out.append(h)
	return out


## A side's spawn tiles, in the floor's order. (simSpawnTiles)
func spawn_tiles(side: String) -> Array[Vector2i]:
	var want := "spawn-ally" if side == "ally" else "spawn-enemy"
	var out: Array[Vector2i] = []
	for h in floor_data.tiles:
		if kind_at(h) == want:
			out.append(h)
	return out


## The Enemy spawn tiles, each with its level (1 to 6; 1 when unset).
func enemy_spawns() -> Array:
	var out := []
	for h in floor_data.tiles:
		var lab := floor_data.label_of(h)
		if Keywords._re("(?i)enemy").search(lab) and Keywords._re("(?i)spawn").search(lab):
			var t = floor_data.tiles[h]
			var lv = Rules.num(t.get("lvl") if t is Dictionary else null, 0)
			out.append({"at": h, "level": int(lv) if lv is int and lv >= 1 and lv <= 6 else 1})
	# On a deployment the tile's Skull Level sets the Enemies; a spawn tile
	# painted higher than its floor's own level stays that much higher.
	if deploy != null and not out.is_empty():
		var bv = Rules.num(floor_data.raw.get("level"), 0)
		var base: int = int(bv) if Rules.truthy(bv) else 0
		if base < 1 or base > 6:
			base = out[0]["level"]
			for t in out:
				base = mini(base, t["level"])
		for t in out:
			t["level"] = clampi(int(deploy["skull"]) + (t["level"] - base), 1, 6)
	return out


func _place_allies() -> void:
	var taken := {}
	var spawns := ally_spawns()
	var extra := _overflow_tiles(spawns)
	var overflow := false
	for u in units:
		if u["side"] != "ally":
			continue
		var at = _claim(spawns, taken)
		if at == null:
			at = _claim(extra, taken)
			overflow = true
		if at != null:
			u["pos"] = {"q": at.x, "r": at.y}
	if overflow:
		notes.append("More Units than spawn tiles; the rest start beside them." if not spawns.is_empty() else "This floor has no Player Spawn Tiles, so your Units start at its edge.")


## Where Units go when the spawn tiles run out. Beside the spawn tiles, nearest
## first (never on an Enemy's); with no spawn tiles, along the floor's bottom
## edge. (The simulator used the bottom edge for both, which could put a Troop
## among the Enemies on a floor laid out sideways.)
func _overflow_tiles(spawns: Array[Vector2i]) -> Array:
	var all: Array = floor_data.tiles.keys()
	if spawns.is_empty():
		all = Rules.stable_sort(all, func(a, b): return a.y - b.y)
		all.reverse()
		return all
	var near := func(h: Vector2i) -> int:
		var d := 1 << 30
		for s in spawns:
			d = mini(d, Hex.distance(h, s))
		return d
	var out: Array = all.filter(func(h): return not spawns.has(h) and kind_at(h) != "spawn-enemy")
	return Rules.stable_sort(out, func(a, b): return near.call(a) - near.call(b))


func _claim(list: Array, taken: Dictionary) -> Variant:
	for h in list:
		if not taken.has(h):
			taken[h] = true
			return h
	return null


## An Enemy on every Enemy spawn tile, from the floor's District at the tile's level.
func _spawn_enemies() -> void:
	var empty := 0
	for t in enemy_spawns():
		if unit_at(t["at"]) != null:
			continue
		var pool := roster.foe_pool(t["level"], floor_data.district)
		if pool.is_empty():
			empty += 1
			continue
		var card: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
		var lk := roster.enemy_looks(card)
		var look: Dictionary = {}
		if lk.size() >= 2:
			look = lk[rng.randi_range(0, lk.size() - 1)]
		elif lk.size() == 1:
			look = lk[0]
		var u := _add(card, "enemy", look)
		u["pos"] = {"q": t["at"].x, "r": t["at"].y}
		u["spawnLevel"] = t["level"]
		_met(u, card)
		arrive(u)
	if enemy_spawns().is_empty():
		notes.append("This floor has no Enemy Spawn Tiles, so no Enemies are here.")
	elif empty > 0:
		notes.append("The export has no Enemy cards, so the Enemy spawn tiles stand empty.")


# ---------------------------------------------------------------- questions
static func tile_of(u: Dictionary) -> Vector2i:
	var p = u.get("pos")
	return Vector2i(int(p["q"]), int(p["r"])) if p is Dictionary else Vector2i(999999, 999999)


func unit_at(h: Vector2i) -> Variant:
	for u in units:
		if not Rules.truthy(u.get("down")) and u.get("pos") is Dictionary and tile_of(u) == h:
			return u
	return null


func unit_by_id(id: String) -> Variant:
	for u in units:
		if u["id"] == id:
			return u
	return null


func side_units(side: String) -> Array:
	return units.filter(func(u): return u["side"] == side)


## How far a Unit may move now: its Movement Speed, after its statuses, and
## any Dash on top (Revision 16.1). A Unit moves once a round; once it has,
## only a Dash's tiles it hasn't spent are left.
func speed(u: Dictionary) -> int:
	var steps := move_steps(u)
	if not has_moved(u):
		return steps
	if steps == 0:
		return 0
	return maxi(0, _dash_total(u) - int(dash_used.get(u["id"], 0)))


## (simMoveSteps) How far a Unit may move this turn in all: its Movement
## Speed, and for one of yours any Dash on top (an Enemy Dashes at once
## instead). Rooted or Stunned, none.
func move_steps(u: Dictionary) -> int:
	var eff := Rules.effective(u)
	if eff["cannotMove"]:
		return 0
	return maxi(0, int(Rules.num(eff["ms"], 0))) + _dash_total(u)


func _dash_total(u: Dictionary) -> int:
	return (int(Rules.num(u.get("dash"), 0)) + int(Rules.num(u.get("pDash"), 0))) if u.get("side") == "ally" else 0


func has_moved(u: Dictionary) -> bool:
	return moved.has(u["id"])


func can_move(u: Dictionary) -> bool:
	return not Rules.truthy(u.get("down")) and speed(u) > 0 and u.get("pos") is Dictionary


## A wall between two tiles stops a Unit, unless it flies.
func _wall_for(u: Dictionary) -> Callable:
	var flying: bool = Rules.effective(u)["flying"]
	return func(a, b): return (not flying) and _walls.has(Rules.hex_key(a["q"], a["r"]) + "|" + Rules.hex_key(b["q"], b["r"]))


## Every tile a Unit could move to now, as {q, r, cost}.
func reach(u: Dictionary) -> Array:
	if not can_move(u):
		return []
	return reach_tiles(u, speed(u))


# ---------------------------------------------------------------- Revision 16.1: moving keywords
## Lunge and Charge ride on a Melee Action; Dash and Leap are given to a Unit.
## A Unit's travel is every tile it has moved this turn of its own accord:
## walking, a Lunge, a Leap or a Dash (never a Push). Charge reads it.

## (simKwNum) The number a keyword carries on an Action's text, or 0.
static func kw_num(action, name: String) -> int:
	var m := Keywords._re("(?i)\\[\\[\\s*" + name + "\\s+(\\d+)\\s*\\]\\]").search(str(action.get("text") if action is Dictionary and action.get("text") != null else ""))
	return maxi(0, int(Rules.num(m.get_string(1), 0))) if m != null else 0


static func melee_role(a) -> bool:
	var r := role_of(a) if a is Dictionary else ""
	return r == "melee" or r == ""


static func lunge_of(a) -> int:
	return kw_num(a, "Lunge") if melee_role(a) else 0


static func charge_of(a) -> int:
	return kw_num(a, "Charge") if melee_role(a) else 0


## (simLeapOf) How far a Unit can jump: Leap given for good, by a Passive, or for a time.
static func leap_of(u: Dictionary) -> int:
	var n := maxi(int(Rules.num(u.get("leap"), 0)), int(Rules.num(u.get("pLeap"), 0)))
	for m in (u.get("mods") if u.get("mods") != null else []):
		if m.get("stat") == "LEAP":
			n = maxi(n, int(Rules.num(m.get("amt"), 0)))
	return n


## (simReach) The tiles a Unit could move to with this many steps: walking
## round walls and Units, and with Leap, jumping to any empty tile that near too.
func reach_tiles(u: Dictionary, steps: int) -> Array:
	var tiles: Array = Rules.reachable(u["pos"], steps, {
		"passable": func(n): return floor_data.has_tile(Vector2i(n["q"], n["r"])),
		"blocked": func(n): return unit_at(Vector2i(n["q"], n["r"])) != null,
		"wall": _wall_for(u),
	})
	var lp := mini(leap_of(u), steps)
	if lp > 0:
		var at := {}
		for t in tiles:
			at[Rules.hex_key(t["q"], t["r"])] = t
		var jumps := []
		for h in floor_data.tiles:
			var p := {"q": h.x, "r": h.y}
			var d: int = Rules.hex_distance(u["pos"], p)
			if d < 1 or d > lp or unit_at(h) != null:
				continue
			var k := Rules.hex_key(h.x, h.y)
			if at.has(k):
				if d < int(at[k]["cost"]):
					at[k]["cost"] = d
					at[k]["leap"] = true
				continue
			jumps.append({"q": h.x, "r": h.y, "cost": d, "leap": true})
		jumps.sort_custom(func(a, c): return a["cost"] < c["cost"] or (a["cost"] == c["cost"] and (a["q"] < c["q"] or (a["q"] == c["q"] and a["r"] < c["r"]))))
		tiles.append_array(jumps)
	return tiles


func _cover_score(t: Dictionary) -> int:
	var sc := 0
	for n in Rules.hex_neighbours(t["q"], t["r"]):
		sc += int(COVER.get(kind_at(Vector2i(n["q"], n["r"])), 0))
	return sc


func _walled(a: Dictionary, c: Dictionary) -> bool:
	return _walls.has(Rules.hex_key(a["q"], a["r"]) + "|" + Rules.hex_key(c["q"], c["r"]))


## (simLungeSpot) Where a Lunge would end: a tile beside the target, with no
## wall between, that the attacker can walk to: one with no hazard on it if
## there is one, then the shortest way, then the most Cover around it, then
## the lowest tile. Where it stands, if that will do.
func lunge_spot(u: Dictionary, a: Dictionary, f: Dictionary) -> Variant:
	var n := lunge_of(a)
	if n == 0 or not (u.get("pos") is Dictionary) or not (f.get("pos") is Dictionary) or Rules.effective(u)["cannotMove"]:
		return null
	var tiles: Array = [{"q": u["pos"]["q"], "r": u["pos"]["r"], "cost": 0}]
	tiles.append_array(Rules.reachable(u["pos"], n, {
		"passable": func(p): return floor_data.has_tile(Vector2i(p["q"], p["r"])),
		"blocked": func(p): return unit_at(Vector2i(p["q"], p["r"])) != null,
		"wall": _wall_for(u),
	}))
	var best = null
	for t in tiles:
		if Rules.hex_distance(t, f["pos"]) != 1 or _walled(t, f["pos"]):
			continue
		var cv := _cover_score(t)
		var hz := 1 if fx.hazard_at(Vector2i(t["q"], t["r"])) != null else 0
		if best == null or hz < best["hz"] or (hz == best["hz"] and (t["cost"] < best["cost"] or (t["cost"] == best["cost"] and (cv > best["cv"] or (cv == best["cv"] and (t["q"] < best["q"] or (t["q"] == best["q"] and t["r"] < best["r"]))))))):
			best = {"q": t["q"], "r": t["r"], "cost": t["cost"], "cv": cv, "hz": hz}
	return best


## (simDoLunge) Makes the Lunge, if the Action has one and the target isn't
## beside it already. False if the attacker went down on the way.
func do_lunge(u: Dictionary, a: Dictionary, f: Dictionary) -> bool:
	if lunge_of(a) == 0 or not (u.get("pos") is Dictionary) or not (f.get("pos") is Dictionary):
		return true
	if Rules.hex_distance(u["pos"], f["pos"]) == 1 and not _walled(u["pos"], f["pos"]):
		return true
	var spot = lunge_spot(u, a, f)
	if spot == null:
		return true
	var from := tile_of(u)
	u["pos"] = {"q": spot["q"], "r": spot["r"]}
	u["travel"] = int(Rules.num(u.get("travel"), 0)) + int(spot["cost"])
	_beat({"type": "move", "unit": u["id"], "from": from, "to": tile_of(u), "path": _walked(u, from)})
	say(u["name"] + " lunges " + str(spot["cost"]) + " tile" + ("" if spot["cost"] == 1 else "s") + " at " + f["name"])
	fx.hazard_hit(u, "lunges onto")
	fx.emit("moves", u)
	if u["side"] == "enemy":
		fx.react_to(u)
	fx.check_downs()
	if u["side"] == "ally" and not Rules.truthy(u.get("down")):
		find_loot(u)
	return not Rules.truthy(u.get("down"))


## (simCharged) The Action as it lands: Charge adds its damage once the Unit
## has moved 3 tiles this turn (extra: tiles a Lunge would add first).
static func charged(u: Dictionary, a: Dictionary, extra := 0) -> Dictionary:
	var c := charge_of(a)
	if c == 0 or int(Rules.num(u.get("travel"), 0)) + extra < 3:
		return a
	var b2: Dictionary = a.duplicate()
	b2["dmg"] = str(int(Rules.action_effect(a)["damage"]) + c)
	b2["_charge"] = c
	return b2


## (simDashAway) An Enemy's Dash: at once, away from the Unit it attacked
## (or from your nearest, with none). What happened, in words.
func dash_away(u: Dictionary, from, n: int) -> String:
	var foes := units.filter(func(x): return x["side"] != u["side"] and not Rules.truthy(x.get("down")) and x.get("pos") is Dictionary)
	var away: Array = [from] if (from != null and from.get("pos") is Dictionary and not Rules.truthy(from.get("down"))) else foes
	if away.is_empty() or not (u.get("pos") is Dictionary) or Rules.effective(u)["cannotMove"]:
		return u["name"] + " cannot Dash"
	var far := func(p) -> int:
		var m := 1 << 30
		for x in away:
			m = mini(m, Rules.hex_distance(p, x["pos"]))
		return m
	var here: int = far.call(u["pos"])
	var best = null
	for t in reach_tiles(u, n):
		var d: int = far.call(t)
		if best == null or d > best["d"] or (d == best["d"] and t["cost"] < best["cost"]):
			best = {"q": t["q"], "r": t["r"], "d": d, "cost": t["cost"], "leap": t.get("leap", false)}
	if best == null or best["d"] <= here:
		return u["name"] + " has nowhere to Dash"
	var from_t := tile_of(u)
	u["pos"] = {"q": best["q"], "r": best["r"]}
	u["travel"] = int(Rules.num(u.get("travel"), 0)) + int(best["cost"])
	_beat({"type": "move", "unit": u["id"], "from": from_t, "to": tile_of(u), "path": _way(u, from_t, best["leap"])})
	fx.hazard_hit(u, "dashes onto")
	fx.emit("moves", u)
	if u["side"] == "enemy":
		fx.react_to(u)
	return u["name"] + " Dashes " + str(best["cost"]) + " tile" + ("" if best["cost"] == 1 else "s") + " away"


## The way a move came, for the board: a jump lands where it lands; a walk goes tile by tile.
func _way(u: Dictionary, from: Vector2i, leapt) -> Array[Vector2i]:
	if Rules.truthy(leapt):
		var p: Array[Vector2i] = [tile_of(u)]
		return p
	return _walked(u, from)


## (simAfterAttacks) An Enemy with an always-on Dash hits and runs: once its
## attacks are made, it Dashes away from the Unit it attacked last.
func after_attacks(e: Dictionary, target) -> void:
	if not (int(Rules.num(e.get("pDash"), 0)) > 0) or Rules.truthy(e.get("down")) or over:
		return
	say(dash_away(e, target, int(Rules.num(e.get("pDash"), 0))))
	fx.check_downs()


## The shortest way to a tile in reach, step by step (not counting where it
## stands), or [] if it can't get there.
func path_to(u: Dictionary, to: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var cost := -1
	var leapt := false
	for t in reach(u):
		if t["q"] == to.x and t["r"] == to.y:
			cost = t["cost"]
			leapt = Rules.truthy(t.get("leap"))
	if cost < 0:
		return out
	# (Revision 16.1) a Leap lands where it lands
	if leapt:
		out.append(to)
		return out
	var wall := _wall_for(u)
	var from := tile_of(u)
	var parent := {from: from}
	var edge: Array[Vector2i] = [from]
	while not edge.is_empty() and not parent.has(to):
		var next: Array[Vector2i] = []
		for cur in edge:
			for n in Rules.hex_neighbours(cur.x, cur.y):
				var h := Vector2i(n["q"], n["r"])
				if parent.has(h) or not floor_data.has_tile(h):
					continue
				if wall.call({"q": cur.x, "r": cur.y}, n) or unit_at(h) != null:
					continue
				parent[h] = cur
				next.append(h)
		edge = next
	var h := to
	while h != from:
		out.push_front(h)
		h = parent[h]
	return out


## Moves a Unit to a tile in its reach. Returns the path it took ([] if it
## can't). The tile it ends on may bite, and its move is an event. (simMoveTo)
func move(u: Dictionary, to: Vector2i) -> Array[Vector2i]:
	var cost := -1
	var leapt := false
	for t in reach(u):
		if t["q"] == to.x and t["r"] == to.y:
			cost = int(t["cost"])
			leapt = Rules.truthy(t.get("leap"))
	var path := path_to(u, to)
	if path.is_empty():
		return path
	_hook()
	undo.append(_snapshot(u["id"]))
	u["pos"] = {"q": to.x, "r": to.y}
	# what it has moved this round (a Dash may leave it more), and its travel, for Charge
	var ms := maxi(0, int(Rules.num(Rules.effective(u)["ms"], 0))) if not Rules.effective(u)["cannotMove"] else 0
	dash_used[u["id"]] = int(dash_used.get(u["id"], 0)) + (cost if has_moved(u) else maxi(0, cost - ms))
	moved[u["id"]] = int(moved.get(u["id"], 0)) + cost
	u["travel"] = int(Rules.num(u.get("travel"), 0)) + cost
	say(u["name"] + (" leaped " if leapt else " moved ") + "%d tile%s" % [cost, "" if cost == 1 else "s"])
	fx.hazard_hit(u, "moves onto")
	fx.emit("moves", u)
	fx.check_downs()
	find_loot(u)
	return path


## Everything a move or a card could change, kept so it can be taken back
## whole: where everyone stands, their Health and statuses, the log; and in a
## Strike Team's fight the Aether, the hand, the Discard Pile, the Bank's
## Chips and the Consumables. what: {kind: "move", mover: id} or
## {kind: "card", label: its name}.
func _snapshot(what) -> Dictionary:
	var d: Dictionary = what if what is Dictionary else {"kind": "move", "mover": str(what)}
	var snap := {"kind": d.get("kind", "move"), "mover": d.get("mover", ""), "label": d.get("label", ""),
		"units": units.map(func(x): return x.duplicate(true)), "moved": moved.duplicate(), "dash_used": dash_used.duplicate(), "log": log.size(),
		"halts": halts.size(), "deployed": deployed, "halted_passives": fx.halted_passives.duplicate(), "next": _next.duplicate(),
		"loot": loot.duplicate(true), "looted": looted.duplicate(), "salvaged": _salvaged.duplicate(), "loot_at": loot_table.state(), "found": found.duplicate(),
		"floor_tiles": floor_data.tiles.duplicate() if floor_data != null else {}, "floor_labels": floor_data.color_labels.duplicate() if floor_data != null else {}}
	if with_cards:
		snap["aether"] = aether.duplicate()
		snap["hand"] = hand.duplicate()
		snap["deck"] = deck.duplicate()   # Revision 16.3: a card that Draws takes from it
		snap["discard"] = discard.duplicate()
		snap["bank"] = bank.map(func(c): return c.duplicate())
		snap["consumables"] = consumables.map(func(c): return c.duplicate())
	return snap


## What Undo would take back now: {} when nothing can be, else {kind, label}:
## a move ("Test Warden's move") or a card ("Test Rally").
func undo_what() -> Dictionary:
	if undo.is_empty():
		return {}
	var last: Dictionary = undo[undo.size() - 1]
	if last["kind"] == "move":
		var u = unit_by_id(last["mover"])
		return {"kind": "move", "label": (str(u["name"]) + "'s move") if u != null else "the move"}
	return {"kind": "card", "label": last["label"]}


## Takes back the last move or card, with anything it set off, if nothing has
## been rolled since. Returns {} if there was nothing to take back, else
## {kind, label, unit}: unit is the one moved back (a move), or null.
func undo_last() -> Dictionary:
	if undo.is_empty():
		return {}
	var what := undo_what()
	var last: Dictionary = undo.pop_back()
	var was: Array = last["units"]
	for i in was.size():
		units[i].clear()
		units[i].merge(was[i])
	for i in range(was.size(), units.size()):
		looks.erase(units[i]["id"])
	units.resize(was.size())
	moved = last["moved"]
	dash_used = last.get("dash_used", {})
	log.resize(last["log"])
	halts.resize(mini(halts.size(), last["halts"]))
	deployed = last["deployed"]
	_next = last["next"]
	fx.halted_passives = last["halted_passives"]
	fx.queue = []
	floats.clear()
	# what it dropped or found is taken back with it, and would fall the same again
	loot = last["loot"]
	looted = last["looted"]
	_salvaged = last["salvaged"]
	found = last["found"]
	loot_table.restore(last["loot_at"])
	# a Barricade put down since is taken back with the rest
	if _own_floor and last.has("floor_tiles"):
		floor_data.tiles = last["floor_tiles"]
		floor_data.color_labels = last["floor_labels"]
		floor_rev += 1
	if last.has("aether"):
		aether = last["aether"]
		hand = last["hand"]
		if last.has("deck"):
			deck = last["deck"]
		discard = last["discard"]
		bank = last["bank"]
		consumables = last["consumables"]
	what["unit"] = unit_by_id(last["mover"]) if last["kind"] == "move" else null
	return what


## Takes back the last move. Returns the Unit moved back, or null. (Kept for
## what only knows moves; undo_last is the whole of it.)
func undo_move() -> Variant:
	return undo_last().get("unit")


func say(text: String, kind := "act", extra: Dictionary = {}) -> void:
	var e := {"round": round, "text": text, "kind": kind}
	e.merge(extra)
	log.append(e)


## A beat of an Enemy's turn begins: whatever happens from here until the next
## belongs to it. When it closes it carries the numbers that rose (floats), the
## log lines written (lines) and how every Unit stood when it was over (after),
## so the board can play a turn back one beat at a time.
func _beat(d: Dictionary) -> Dictionary:
	_close_beat()
	d["f0"] = floats.size()
	d["l0"] = log.size()
	beats.append(d)
	return d


func _close_beat() -> void:
	if beats.is_empty():
		return
	var last: Dictionary = beats[beats.size() - 1]
	if last.has("after"):
		return
	last["floats"] = floats.slice(last["f0"])
	last["lines"] = log.slice(last["l0"]).map(func(l): return l["text"])
	last["after"] = units.map(func(u): return u.duplicate(true))


# ---------------------------------------------------------------- aiming
## Cover is a Barricade standing between the shot and its target: a Cover tile
## next to the target and nearer the attacker than the target is. Cover a card
## has granted counts wherever the Unit stands. (simCoverFor)
func cover_for(target: Dictionary, attacker: Dictionary) -> int:
	if not (target.get("pos") is Dictionary) or not (attacker.get("pos") is Dictionary):
		return 0
	var best := 0
	if Rules.truthy(Rules.status_n(target, "Full Cover")):
		best = 4
	elif Rules.truthy(Rules.status_n(target, "Half Cover")):
		best = 2
	for n in Rules.hex_neighbours(target["pos"]["q"], target["pos"]["r"]):
		var val: int = COVER.get(kind_at(Vector2i(n["q"], n["r"])), 0)
		if val == 0:
			continue
		if Rules.hex_distance(attacker["pos"], n) < Rules.hex_distance(attacker["pos"], target["pos"]):
			best = maxi(best, val)
	return best


## A clear line between two tiles, past the floor's walls. (simSees)
func sees(a: Dictionary, b: Dictionary) -> bool:
	return Rules.line_of_sight(a, b, null, _segs)


static func role_of(a: Dictionary) -> String:
	return str(a.get("role") if a.get("role") != null else "").to_lower()


## Ranged and Cyber Actions reach and aim; the rest are blows. (simAimed)
static func aimed(role: String) -> bool:
	return role == "ranged" or role == "cyber"


## How far an aimed Action reaches (its range, 1 if it has none, plus any change).
static func reach_of(u: Dictionary, a: Dictionary) -> int:
	var r = Rules.num(a.get("rng"), 0)
	return int(r if Rules.truthy(r) else 1) + int(Rules.num(Rules.effective(u).get("range"), 0))


## Whether an Action can reach a Unit from here: an aimed one needs range and
## sight; anything else reaches a neighbouring tile with no wall between. (simCanReach)
## no_lunge: the next attacks of a Burst, and a held shot, reach as they stand.
## (Revision 16.1) A Lunge reaches as far as it can walk to stand beside the target.
func can_reach(u: Dictionary, a: Dictionary, f: Dictionary, no_lunge := false) -> bool:
	var d = Rules.hex_distance(u["pos"], f["pos"])
	if aimed(role_of(a)):
		return d <= reach_of(u, a) and sees(u["pos"], f["pos"])
	if d == 1 and not _walls.has(Rules.hex_key(u["pos"]["q"], u["pos"]["r"]) + "|" + Rules.hex_key(f["pos"]["q"], f["pos"]["r"])):
		return true
	var lg := 0 if no_lunge else lunge_of(a)
	if lg == 0 or d > lg + 1:
		return false
	return lunge_spot(u, a, f) != null


## The Actions a Unit can choose from (not its Passives or Auras).
static func usable_actions(u: Dictionary) -> Array:
	return (u.get("actions") if u.get("actions") != null else []).filter(func(a): return a.get("tag") != "Passive" and a.get("tag") != "Aura")


## Who an Action is aimed at: Support at your own side (never yourself),
## anything else at the other side.
func _pool_for(u: Dictionary, a: Dictionary) -> Array:
	var support := role_of(a) == "support"
	return units.filter(func(f): return not Rules.truthy(f.get("down")) and f.get("pos") is Dictionary and (
		(f["side"] == u["side"] and f != u) if support else f["side"] != u["side"]))


## (simSelfOnly) Revision 16.2: a Support Action whose only Target is "this
## Unit" needs no one to aim at: it is used at once, on the Unit using it.
static func self_only(a) -> bool:
	if not (a is Dictionary) or not Rules.truthy(a.get("text")) or role_of(a) != "support":
		return false
	var mine := false
	var other := false
	for sent in Keywords.sentences(str(a["text"])):
		for t in Keywords.analyse(sent)["targets"]:
			if t["part"]["kw"]["name"] == "this Unit":
				mine = true
			else:
				other = true
	return mine and not other


## (simUseOnSelf) Uses a self-targeted Action: it pays, and what it says is
## carried out on the Unit using it. Returns the line it added to the log.
func use_on_self(u: Dictionary, a: Dictionary) -> String:
	_hook()
	undo.clear()                  # Energy is paid: the moves before it stand
	u["nrg"] = maxi(0, int(u["nrg"]) - int(Rules.num(a.get("cost"), 0)))
	pay_aether(u, a)
	u["acted"] = true
	var line: String = u["name"] + " used " + str(a["name"])
	say(line)
	fx.run_text(a["text"], {"actor": u, "target": u, "sourceCard": a["name"]})
	fx.check_downs()
	return line


## (simTileAction) 0.23: an Action that says "target tile" is aimed at a tile:
## any tile within its range (1 for one that has none) the Unit can see, its
## own included. Its text is carried out there, with no attack roll, as a
## card's would be.
static func tile_action(a) -> bool:
	if not (a is Dictionary) or not Rules.truthy(a.get("text")):
		return false
	for sent in Keywords.sentences(str(a["text"])):
		var an := Keywords.analyse(sent)
		if an["when"] != null:
			continue
		for t in an["targets"]:
			if t["part"]["kw"]["name"] == "target tile":
				return true
	return false


## (simTileReach) The tiles a tile-aimed Action can go to now: {Vector2i: true}.
func tile_reach(u: Dictionary, a: Dictionary) -> Dictionary:
	var out := {}
	if not Rules.truthy(u.get("pos")) or floor_data == null:
		return out
	var r0 = Rules.num(a.get("rng"), 0)
	var rng := (int(r0) if Rules.truthy(r0) else 1) + int(Rules.num(Rules.effective(u).get("range"), 0))
	for h in floor_data.tiles:
		var t := {"q": h.x, "r": h.y}
		if Rules.hex_distance(u["pos"], t) <= rng and sees(u["pos"], t):
			out[h] = true
	return out


## (simUseOnTile) Uses a tile-aimed Action on a tile: it pays, and what it says
## is carried out there. Returns the line it added to the log.
func use_on_tile(u: Dictionary, a: Dictionary, h: Vector2i) -> String:
	_hook()
	undo.clear()                  # Energy is paid: the moves before it stand
	u["nrg"] = maxi(0, int(u["nrg"]) - int(Rules.num(a.get("cost"), 0)))
	pay_aether(u, a)
	u["acted"] = true
	var line: String = u["name"] + " used " + str(a["name"]) + " at " + str(h.x) + "," + str(h.y)
	say(line)
	fx.run_text(a["text"], {"actor": u, "tile": {"q": h.x, "r": h.y}, "target": null, "sourceCard": a["name"]})
	fx.check_downs()
	return line


## Every Unit an Action could be used on now. An Action written "target
## Sniper enemy" can only be aimed at one. (simPickAction)
func targets_for(u: Dictionary, a: Dictionary) -> Array:
	if self_only(a) or tile_action(a):
		return []
	var narrow := Effects.action_narrow(a)
	return _pool_for(u, a).filter(func(f): return fx.narrow_ok(f, narrow, {"actor": u}) and can_reach(u, a, f))


## Whether a Unit can use an Action now, and if not, why. (simActionState)
func action_state(u: Dictionary, a: Dictionary) -> Dictionary:
	if Rules.effective(u)["cannotAct"]:
		return {"ok": false, "why": "Stunned"}
	if not Rules.can_afford(u, a):
		return {"ok": false, "why": "Needs %d NRG" % int(Rules.num(a.get("cost"), 0))}
	if not aether_ok(u, a):
		return {"ok": false, "why": "Needs %s Aether" % aether_words(a["aether"])}
	if self_only(a):
		return {"ok": true}
	if tile_action(a):
		return {"ok": true} if not tile_reach(u, a).is_empty() else {"ok": false, "why": "No tile in reach"}
	var pool := _pool_for(u, a)
	if pool.any(func(f): return can_reach(u, a, f)):
		return {"ok": true}
	var blind := pool.any(func(f): return aimed(role_of(a)) and Rules.hex_distance(u["pos"], f["pos"]) <= int(Rules.num(a.get("rng"), 0) if Rules.truthy(Rules.num(a.get("rng"), 0)) else 1) and not sees(u["pos"], f["pos"]))
	return {"ok": false, "why": "No line of sight" if blind else "Nothing in reach"}


## The chance an Action gets through to a target (hits, then Penetrates), and
## what it would deal. Worked out from the rules themselves, so it is exact:
## every pair of d20 rolls is counted (tests check it against resolve_attack).
func odds(u: Dictionary, a: Dictionary, f: Dictionary) -> Dictionary:
	var role := role_of(a)
	if role == "":
		role = "melee"
	var eff := Rules.effective(f)
	var mine := Rules.effective(u)
	# Revision 16.1: Charge's damage, once it would apply (after any Lunge)
	var lsp = lunge_spot(u, a, f) if lunge_of(a) > 0 else null
	var fx := Rules.action_effect(charged(u, a, int(lsp["cost"]) if lsp != null else 0))
	var dmg := maxi(0, int(floor(float(fx["damage"]) * float(mine["dmgMult"]))) + int(Rules.num(mine["dmgFlat"], 0)))
	if role == "support" or role == "aether":
		return {"p": 1.0, "dmg": dmg}
	dmg = int(Rules.hardened_cut(f, dmg))   # 0.23: what a Hardened target would really take
	var p_hit := 1.0
	if aimed(role):
		if not eff["alwaysHit"]:
			# Revision 16.3: Aim takes off what it needs
			var need := int(Rules.num(a.get("hit"), 0)) + cover_for(f, u) + int(Rules.num(f.get("evasive"), 0)) + int(Rules.num(eff["evasion"], 0)) - int(Rules.num(mine.get("aim"), 0))
			p_hit = clampf((21.0 - need) / 20.0, 0.0, 1.0)
	elif eff["flying"]:
		p_hit = 0.0
	var ac := int(Rules.num(eff["integrity"] if role == "cyber" else eff["ac"], 0))
	var ap := int(Rules.num(a.get("pen"), 0)) + int(Rules.num(mine.get("ap"), 0))
	var p_pen := clampf((21.0 - (ac - ap)) / 20.0, 0.0, 1.0)
	return {"p": p_hit * p_pen, "dmg": dmg}


# ---------------------------------------------------------------- an Action's Aether
## A carried Action card may cost Aether to use, on top of its Energy.
## (simAetherOK, simAetherWords, simPayAether)
func aether_ok(u, a) -> bool:
	return not (a is Dictionary and a.get("aether") is Dictionary and u is Dictionary and u.get("side") == "ally") or Rules.aether_can_pay(aether, a["aether"])


static func aether_words(c) -> String:
	var parts := []
	if c is Dictionary and Rules.truthy(c.get("affinity")):
		parts.append(str(c["affinity"]) + ((" D" + str(c["district"])) if Rules.truthy(c.get("district")) else ""))
	if c is Dictionary and Rules.truthy(c.get("generic")):
		parts.append(str(c["generic"]) + "◇")
	return " + ".join(parts)


func pay_aether(u, a) -> void:
	var c = action_aether(a)
	if c is Dictionary and u is Dictionary and u.get("side") == "ally" and Rules.aether_can_pay(aether, c):
		Rules.aether_pay(aether, c)


## What a carried Action costs at the X it is being used for. (simActionAether)
static func action_aether(a) -> Variant:
	if not (a is Dictionary) or not (a.get("aether") is Dictionary):
		return null
	if a.get("aetherX") is Dictionary:
		return Roster.card_cost({"cost": a["aetherX"], "district": a["aether"].get("district")}, a["x"] if Rules.truthy(a.get("x")) else 1)
	return a["aether"]


## Sets the X a carried Action card is used for: its text reads with it. (simActionSetX)
static func set_action_x(a: Dictionary, n) -> void:
	var v = Rules.num(n, 1)
	a["x"] = maxi(1, int(v) if Rules.truthy(v) else 1)
	if Rules.truthy(a.get("textX")):
		a["text"] = Keywords.fill_x(a["textX"], a["x"])


## The most X the Bank could pay for a carried Action card: 0 if it isn't variable.
func action_max_x(a) -> int:
	if not (a is Dictionary) or not (a.get("aetherX") is Dictionary) or not (a.get("aether") is Dictionary):
		return 0
	return max_x({"cost": a["aetherX"], "district": a["aether"].get("district")})


## As it prints beside the Action: X where the card says X. (simActionAetherWords)
static func action_aether_words(a: Dictionary) -> String:
	if a.get("aetherX") is Dictionary:
		return aether_words({"generic": a["aetherX"].get("generic"), "affinity": a["aetherX"].get("affinity"), "district": a["aether"].get("district")})
	return aether_words(a.get("aether"))


# ---------------------------------------------------------------- variable costs
## A Unit that came from a variable-cost card reads its text with its X in
## place from the moment it arrives. (simXFill)
static func x_fill(u: Dictionary) -> Dictionary:
	if u.get("x") == null:
		return u
	for a in (u["actions"] if u.get("actions") is Array else []):
		if Rules.truthy(a.get("text")):
			a["text"] = Keywords.fill_x(a["text"], u["x"])
	return u


## The most X the Bank could pay for. (simMaxX)
func max_x(card: Dictionary) -> int:
	var n := 0
	while n < 20 and Rules.aether_can_pay(aether, Roster.card_cost(card, n + 1)):
		n += 1
	return n


## " (X = 3)" for the log, on a card with a variable cost. (simXNote)
static func x_note(card) -> String:
	if not Roster.card_var(card):
		return ""
	var v = Rules.num(card.get("x"), 1)
	return " (X = %d)" % (int(v) if Rules.truthy(v) else 1)


## Takes the X a variable-cost card is being played for: at least 1, and no
## more than the Bank can pay. An ordinary card takes none.
func _take_x(card: Dictionary, x) -> bool:
	if not Roster.card_var(card):
		return true
	var v = Rules.num(x, 1)
	var n: int = int(v) if Rules.truthy(v) else 1
	if n < 1 or n > max_x(card):
		return false
	card["x"] = n
	return true


# ---------------------------------------------------------------- playing cards
## Cards, Consumables and Chips are used on your turn. (simCanAct)
func can_act() -> bool:
	return phase == "turn" and not over


## Whether the Bank can pay for a card now: a variable cost at its least. (simCanPlay)
func can_play(card: Dictionary) -> bool:
	return Rules.aether_can_pay(aether, Roster.card_cost(card, 1 if Roster.card_var(card) else null))


## All of a card's text, in one piece.
static func text_of(effects) -> String:
	return " ".join((effects if effects is Array else []).map(func(e): return str(e.get("text") if e.get("text") != null else "")))


## What a card (or a Consumable, or a Chip) needs settled before it can be
## carried out: need "enemy", "ally" or "tile" (or "" for none), how wide an
## area it has, what narrows who it may be aimed at, and whether it Recovers
## a Troop's card. (simCardNeeds)
static func needs_of(effects, x = null) -> Dictionary:
	var need := ""
	var radius := 0
	var narrow := []
	var recover := false
	var list: Array = effects if effects is Array else []
	if x != null:
		# a variable cost: read with X in place, so an area of X is as wide as it will be
		list = list.map(func(e): return {"text": Keywords.fill_x(e.get("text") if e.get("text") != null else "", x)})
	var within := Keywords._re("^all (enemies|allies|units) within$")
	for e in list:
		for p in Keywords.parse(e.get("text") if e.get("text") != null else ""):
			if p["type"] != "kw" or p["kw"] == null:
				continue
			var nm: String = p["kw"]["name"]
			if need == "":
				if nm == "target enemy":
					need = "enemy"
				elif nm == "target ally":
					need = "ally"
				elif nm == "target tile":
					need = "tile"
			if within.search(nm) != null or nm == "AoE":
				var n = Rules.num(p["n"], 0)
				radius = maxi(radius, int(n) if Rules.truthy(n) else 0)
			if nm == "Recover":
				recover = true
	var aim := Keywords._re("^target (enemy|ally)$")
	for e in list:
		for sent in Keywords.sentences(e.get("text") if e.get("text") != null else ""):
			for t in Keywords.analyse(sent)["targets"]:
				if aim.search(t["part"]["kw"]["name"]) != null and narrow.is_empty():
					narrow = t["narrow"]
	return {"need": need, "radius": radius, "narrow": narrow, "recover": recover}


## Who a card could be aimed at now: Enemies or your own, standing, and of
## the kind its text narrows to.
func pool_for_need(needs: Dictionary) -> Array:
	var actor = fx.leader_unit()
	var foe: bool = needs["need"] == "enemy"
	return units.filter(func(u): return (not Rules.truthy(u.get("down")) and u.get("pos") is Dictionary and
		((u["side"] != "ally") if foe else (u["side"] == "ally")) and fx.narrow_ok(u, needs["narrow"], {"actor": actor})))


## The Troop cards in the Discard Pile, as where each lies in it: what a
## Recover could bring back. (simRecoverable)
func recoverable() -> Array:
	var out := []
	for i in discard.size():
		if discard[i] is Dictionary and discard[i].get("type") == "troop":
			out.append(i)
	return out


## The Player Spawn Tiles nobody stands on.
func open_spawns() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for t in spawn_tiles("ally"):
		if unit_at(t) == null:
			out.append(t)
	return out


## What stands in the way of something that needs a target or Recovers, if
## anything: "" when it can go ahead.
func _why_not(label: String, needs: Dictionary, another := false) -> String:
	if needs["recover"] and recoverable().is_empty():
		return "%s Recovers a Troop's card from the Discard Pile, and there is none there." % label
	if (needs["need"] == "enemy" or needs["need"] == "ally") and pool_for_need(needs).is_empty():
		return "%s needs %s to target, and there is none." % [label, "an Enemy" if needs["need"] == "enemy" else ("another friendly Unit" if another else "a friendly Unit")]
	return ""


## Whether a card in your hand can be played now, and if not, why:
## {ok, why, kind, needs}. kind is "troop", "equipment" or "plain" (anything
## else: it is paid for, its text carried out, and it is discarded).
func play_state(card: Dictionary, x = null) -> Dictionary:
	var kind := "troop" if card.get("type") == "troop" else ("equipment" if card.get("type") == "equipment" else "plain")
	var variable := Roster.card_var(card)
	var with_x = (x if x != null else (card["x"] if card.get("x") != null else 1)) if variable else null
	var needs := needs_of(card.get("effects"), with_x) if kind == "plain" else {"need": "", "radius": 0, "narrow": [], "recover": false}
	var out := {"ok": false, "why": "", "kind": kind, "needs": needs, "variable": variable, "max_x": max_x(card) if variable else 0}
	if not can_act():
		out["why"] = "Cards are played on your turn."
	elif not can_play(card):
		out["why"] = "%s needs %s%s, and the Bank holds %s." % [card["name"], "at least " if variable else "", Roster.cost_label(card, 1 if variable else null), aether_label(aether)]
	elif kind == "troop" and open_spawns().is_empty():
		out["why"] = "Every Player Spawn Tile is occupied. %s can't deploy until one is free." % card["name"]
	elif kind == "equipment" and side_units("ally").filter(func(u): return not Rules.truthy(u.get("down"))).is_empty():
		out["why"] = "Nothing on your side can carry it."
	elif kind == "plain" and _why_not(card["name"], needs, true) != "":
		out["why"] = _why_not(card["name"], needs, true)
	else:
		out["ok"] = true
	return out


## Pays for a card and takes it out of the hand. A Troop's card and an
## Equipment card stay on the Battlefield with their Unit; anything else is
## discarded as it is played. (simPayAndDiscard)
func _pay(i: int) -> Dictionary:
	var card: Dictionary = hand[i]
	_hook()
	undo.append(_snapshot({"kind": "card", "label": card["name"]}))
	Rules.aether_pay(aether, Roster.card_cost(card))
	hand.remove_at(i)
	if card.get("type") != "troop" and card.get("type") != "equipment":
		discard.append(card)
	return card


## Plays a Troop card: it arrives on an open Player Spawn Tile (the one
## given, or the first), and may move and act at once. Returns the Unit, or
## null if it can't be played. (simPlayTroop)
func play_troop(i: int, tile = null, x = null) -> Variant:
	if i < 0 or i >= hand.size() or not play_state(hand[i])["ok"] or hand[i].get("type") != "troop":
		return null
	if not _take_x(hand[i], x):
		return null
	var spots := open_spawns()
	var at: Vector2i = tile if (tile is Vector2i and spots.has(tile)) else spots[0]
	var card := _pay(i)
	var lib = roster.card_named(str(card["name"])) if roster != null else null
	var spec: Dictionary
	if lib != null:
		spec = Roster.unit_spec(lib)
		spec["cardType"] = "troop"
	else:
		var raw: Dictionary = card["_raw"] if card.get("_raw") is Dictionary else {}
		spec = {"name": card["name"], "cardType": "troop", "subtype": raw["subtype"] if Rules.truthy(raw.get("subtype")) else card.get("subtype"),
			"stats": raw["stats"] if Rules.truthy(raw.get("stats")) else card.get("stats"), "behaviors": raw["behaviors"] if Rules.truthy(raw.get("behaviors")) else card.get("behaviors"),
			"entries": raw["abilities"] if Rules.truthy(raw.get("abilities")) else card.get("effects")}
	# a variable-cost Troop arrives with the X it was played for
	if Roster.card_var(card):
		var xv = Rules.num(card.get("x"), 1)
		spec["x"] = maxi(1, int(xv) if Rules.truthy(xv) else 1)
	var u := x_fill(Rules.unit_from_card(spec, "ally"))
	_next["ally"] += 1
	u["id"] = "a" + str(_next["ally"])
	u["pos"] = {"q": at.x, "r": at.y}
	u["card"] = card              # goes to the Discard Pile when the Troop goes down
	units.append(u)
	looks[u["id"]] = roster.token_for(lib) if (roster != null and lib != null) else {}
	say(str(card["name"]) + " deployed" + x_note(card))
	fx.run_trigger(u, "deployed")
	_pvp_count("cards")
	return u


## Plays an Equipment card onto one of your Units: its Passives are on while
## it is attached, and anything else it says happens once, as it goes on.
## (simAttachEquipment)
func play_equipment(i: int, unit: Dictionary, x = null) -> bool:
	if i < 0 or i >= hand.size() or not play_state(hand[i])["ok"] or hand[i].get("type") != "equipment":
		return false
	if unit.get("side") != "ally" or Rules.truthy(unit.get("down")):
		return false
	if not _take_x(hand[i], x):
		return false
	var card := _pay(i)
	var effects: Array = card["effects"] if card.get("effects") is Array else []
	# with a variable cost, its text reads with the X it was played for
	if Roster.card_var(card):
		var xv = Rules.num(card.get("x"), 1)
		var ex: int = maxi(1, int(xv) if Rules.truthy(xv) else 1)
		effects = effects.map(func(e):
			var d: Dictionary = e.duplicate()
			d["text"] = Keywords.fill_x(e["text"] if Rules.truthy(e.get("text")) else "", ex)
			return d)
	if not (unit.get("equipment") is Array):
		unit["equipment"] = []
	unit["equipment"].append(card["name"])
	if not (unit.get("equipCards") is Array):
		unit["equipCards"] = []
	unit["equipCards"].append(card)
	if not (unit.get("equipFx") is Array):
		unit["equipFx"] = []
	unit["equipFx"].append({"name": card["name"], "fx": effects.map(func(e): return {"kind": e["kind"] if Rules.truthy(e.get("kind")) else "Active", "text": e["text"] if Rules.truthy(e.get("text")) else ""})})
	say(str(card["name"]) + " equipped on " + str(unit["name"]) + x_note(card))
	for e in effects:
		if Rules.truthy(e.get("text")) and not Effects._passive_tag(e.get("kind") if Rules.truthy(e.get("kind")) else ""):
			fx.run_text(e["text"], {"actor": unit, "holder": unit, "target": unit, "sourceCard": card["name"]})
	fx.apply_continuous()
	_pvp_count("cards")
	return true


## Carries out some text played from the hand: through the leader, on a
## target or at a tile if it has one, with the Troop's card it Recovers.
func _carry_out(effects, source: String, target, tile, recover, x = null) -> void:
	var actor = fx.leader_unit()
	var ctx := {"actor": actor, "target": target, "sourceCard": source, "fromHand": true}
	if x != null:
		ctx["x"] = x
	if tile is Vector2i:
		ctx["tile"] = {"q": tile.x, "r": tile.y}
	if recover != null:
		ctx["recover"] = recover
	for e in (effects if effects is Array else []):
		if Rules.truthy(e.get("text")):
			fx.run_text(e["text"], ctx.duplicate())
	fx.check_downs()


## Plays any other card (a Command, an Aether card): it is paid for, what it
## says is carried out through the leader, and it is discarded. target: the
## Unit it is aimed at; tile: where its area is centred; recover: where in
## the Discard Pile the Troop's card it brings back lies. (simPlayPlain,
## simResolveCard and simConfirmAim)
func play_card(i: int, target = null, tile = null, recover = null, x = null) -> bool:
	if i < 0 or i >= hand.size():
		return false
	var st := play_state(hand[i], x)
	if not st["ok"] or st["kind"] != "plain":
		return false
	if not _take_x(hand[i], x):
		return false
	var needs: Dictionary = st["needs"]
	if needs["need"] == "tile" and not (tile is Vector2i):
		return false
	if (needs["need"] == "enemy" or needs["need"] == "ally") and (target == null or not pool_for_need(needs).has(target)):
		return false
	if needs["recover"] and recover == null:
		recover = recoverable()[recoverable().size() - 1]
	var card := _pay(i)
	var cx = card.get("x") if Roster.card_var(card) else null
	if needs["need"] == "tile":
		say("Played %s%s at %d,%d" % [card["name"], x_note(card), tile.x, tile.y])
		_carry_out(card.get("effects"), str(card["name"]), null, tile, recover, cx)
	else:
		say("Played " + str(card["name"]) + x_note(card) + ((" on " + str(target["name"])) if target != null else ""))
		_carry_out(card.get("effects"), str(card["name"]), target, null, recover, cx)
	_pvp_count("cards")
	return true


# ---------------------------------------------------------------- Consumables
## Whether a Consumable can be used now, and if not, why: {ok, why, needs}.
func consumable_state(i: int) -> Dictionary:
	var item: Dictionary = consumables[i]
	var needs := needs_of([{"text": item.get("text", "")}])
	var out := {"ok": false, "why": "", "needs": needs}
	if Rules.truthy(item.get("used")):
		out["why"] = "Used."
	elif not can_act():
		out["why"] = "Consumables are used on your turn."
	elif _why_not(str(item["name"]), needs) != "":
		out["why"] = _why_not(str(item["name"]), needs)
	else:
		out["ok"] = true
	return out


## Uses a Consumable: it does what it says, costs no Aether, and is gone for
## the rest of the Combat. (simUseConsumable)
func use_consumable(i: int, target = null, tile = null, recover = null) -> bool:
	if i < 0 or i >= consumables.size():
		return false
	var st := consumable_state(i)
	if not st["ok"]:
		return false
	var needs: Dictionary = st["needs"]
	if needs["need"] == "tile" and not (tile is Vector2i):
		return false
	if (needs["need"] == "enemy" or needs["need"] == "ally") and (target == null or not pool_for_need(needs).has(target)):
		return false
	if needs["recover"] and recover == null:
		recover = recoverable()[recoverable().size() - 1]
	var item: Dictionary = consumables[i]
	_hook()
	undo.append(_snapshot({"kind": "card", "label": item["name"]}))
	item["used"] = true
	var at: Variant = tile if needs["need"] == "tile" else null
	say("Used " + str(item["name"]) + ((" on " + str(target["name"])) if (target != null and at == null) else "") + ((" at %d,%d" % [tile.x, tile.y]) if at != null else ""))
	_carry_out([{"text": item.get("text", "")}], str(item["name"]), target if at == null else null, at, recover)
	return true


# ---------------------------------------------------------------- Chips with an effect
## What a Chip in the Bank says, if anything: its own text, or its card's.
func chip_text(c: Dictionary) -> String:
	var t := str(c.get("text") if c.get("text") != null else "").strip_edges()
	if t != "":
		return t
	var card = roster.card_named(str(c.get("name"))) if roster != null else null
	return " ".join(Roster.entries_of(card).map(func(a): return str(a.get("text") if a.get("text") != null else ""))).strip_edges() if card != null else ""


## Whether a Chip in the Bank can be spent for its effect now: {ok, why, needs}.
func chip_state(i: int) -> Dictionary:
	var c: Dictionary = bank[i]
	var text := chip_text(c)
	var needs := needs_of([{"text": text}])
	var out := {"ok": false, "why": "", "needs": needs}
	if text == "":
		out["why"] = "It has no effect to spend it for."
	elif Rules.truthy(c.get("spent")):
		out["why"] = "Spent this round. It turns face-up again at the Recharge."
	elif not can_act():
		out["why"] = "Chips are spent on your turn."
	elif _why_not(str(c["name"]), needs) != "":
		out["why"] = _why_not(str(c["name"]), needs)
	else:
		out["ok"] = true
	return out


## Spends a Chip for its effect: once a round, and it still generated its
## Aether this turn. (simSpendChip)
func spend_chip(i: int, target = null, recover = null) -> bool:
	if i < 0 or i >= bank.size():
		return false
	var st := chip_state(i)
	if not st["ok"]:
		return false
	var needs: Dictionary = st["needs"]
	if (needs["need"] == "enemy" or needs["need"] == "ally") and (target == null or not pool_for_need(needs).has(target)):
		return false
	if needs["recover"] and recover == null:
		recover = recoverable()[recoverable().size() - 1]
	var c: Dictionary = bank[i]
	_hook()
	undo.append(_snapshot({"kind": "card", "label": c["name"]}))
	c["spent"] = true
	say("Spent " + str(c["name"]) + ((" on " + str(target["name"])) if target != null else ""))
	_carry_out([{"text": chip_text(c)}], str(c["name"]), target, null, recover)
	return true


# ---------------------------------------------------------------- attacking
## One of your Units uses an Action on a target: the rules decide it with the
## battle's dice, then the Action's text is carried out. Returns the rules'
## result, with the line it added to the log.
##
## A Burst makes the Action several times for one payment: the result then
## carries burst = {left, pool} (who the next attack could go to), and the
## next is made by calling this again with burst_left one less. The Burst is
## over when the result carries none. (simConfirmAttack, simApplyAttack and
## simBurstContinue)
func attack(attacker: Dictionary, action: Dictionary, target: Dictionary, burst_left := -1) -> Dictionary:
	_hook()
	var total := Effects.burst_of(action)
	if burst_left < 0:
		burst_left = total - 1
	var follow := burst_left < total - 1
	# Revision 16.1: a Lunge closes the gap first, once for the Action
	if not follow and lunge_of(action) > 0 and can_reach(attacker, action, target):
		undo.clear()              # it has moved for the attack: the moves before it stand
		if not do_lunge(attacker, action, target):
			var fell := {"inRange": false, "hit": null, "penetrated": null, "damage": 0, "rolls": {}, "line": attacker["name"] + " went down on the way"}
			say(fell["line"])
			return fell
	var cover := cover_for(target, attacker)
	var res := Rules.resolve_attack(attacker, charged(attacker, action), target, {
		"distance": Rules.hex_distance(attacker["pos"], target["pos"]), "cover": cover,
		"evasive": target.get("evasive") if Rules.truthy(target.get("evasive")) else 0, "rolls": {}, "dice": dice})
	if Rules.truthy(res.get("damage")) and charged(attacker, action).has("_charge"):
		res["charge"] = charge_of(action)
	res["cover"] = cover
	if not res["inRange"]:
		res["line"] = target["name"] + " is out of range."
		say(res["line"])
		return res
	undo.clear()                  # dice are rolled: the moves before it stand
	if not follow:
		attacker["nrg"] = maxi(0, int(attacker["nrg"]) - int(Rules.num(action.get("cost"), 0)))
		pay_aether(attacker, action)
	attacker["acted"] = true
	target["lastAttackedBy"] = attacker["id"]
	target["attackedThisRound"] = true
	fx.emit("attacks", attacker, target)
	fx.emit("is attacked", target, attacker)
	var prev = fx.dealer
	fx.dealer = attacker
	var line: String = attacker["name"] + " used " + str(action["name"]) + " on " + target["name"] + ": "
	if Rules.truthy(res["damage"]):
		Rules.hit(target, res["damage"], true)   # Revision 16.3: Hardened is in the damage already
		line += str(res["damage"]) + " damage" + ((" (Charge +%d)" % int(res["charge"])) if Rules.truthy(res.get("charge")) else "") + (" (halved)" if Rules.truthy(res.get("halved")) else "") + ((" — " + target["name"] + " is down") if Rules.truthy(target.get("down")) else "")
	elif res["hit"] == false:
		line += "missed" + ((" (cover +%d)" % cover) if cover else "")
	elif res["penetrated"] == false:
		line += "hit but did not Penetrate Armor Class"
	else:
		line += "no effect"
	say(line, "act", {"rolls": res["rolls"]})
	res["line"] = line
	if Rules.truthy(action.get("text")) and res["hit"] != false and res["penetrated"] != false:
		fx.run_text(action["text"], {"actor": attacker, "target": target, "damaged": Rules.num(res["damage"], 0) > 0, "killed": Rules.truthy(target.get("down")),
			"damage": res["damage"] if Rules.truthy(res["damage"]) else 0, "sourceCard": action["name"]})
	fx.dealer = prev
	fx.check_downs()
	if total > 1:
		var nxt := burst_next(attacker, action, burst_left)
		if not nxt.is_empty():
			res["burst"] = nxt
	return res


## What a Burst does next: {} when it's over, else {left, pool}. (simBurstContinue)
func burst_next(attacker: Dictionary, action: Dictionary, left: int) -> Dictionary:
	if left <= 0 or Rules.truthy(attacker.get("down")):
		return {}
	var pool := fx.burst_pool(attacker, action)
	if pool.is_empty():
		say("The Burst ends: nothing left in reach")
		return {}
	return {"left": left, "pool": pool.map(func(f): return f["id"])}


## Anything at 0 Health is down, and the Passives hear of it.
func check_downs() -> void:
	_hook()
	fx.check_downs()


## The Actions a Unit could hold fire with now (Suppressive Fire). (simHoldable)
func holdable(u: Dictionary) -> Array:
	# (0.26) a held shot waits for the Enemy turn, which a pass-and-play match never plays
	return [] if pvp > 0 else fx.holdable(u)


## Holds fire: pays the Action's Energy now, and shoots the first Enemy that
## moves within range and line of sight during the Enemy turn. (simHoldFire)
func hold_fire(u: Dictionary, action_name: String) -> bool:
	_hook()
	var held: bool = fx.hold_fire(u, action_name)
	if held:
		undo.clear()              # Energy is paid: the moves before it stand
	return held


## What a hazard tile does, in a few words: "AC: 2 damage and Poisoned".
func hazard_words(h: Vector2i) -> String:
	var hz = fx.hazard_at(h)
	if hz == null:
		return ""
	var bits := []
	if Rules.truthy(hz.get("damage")):
		bits.append("%d damage" % int(hz["damage"]))
	if Rules.truthy(hz.get("keyword")):
		bits.append(str(hz["keyword"]))
	return str(hz["text"] if Rules.truthy(hz.get("text")) else "A hazard") + ": " + " and ".join(bits)


# ---------------------------------------------------------------- the Enemies
## The Enemies still standing, in the order they act.
func enemy_queue() -> Array:
	return units.filter(func(u): return u["side"] == "enemy" and not Rules.truthy(u.get("down"))).map(func(u): return u["id"])


## Why an Enemy picked who it picked, in the words of the keywords that decided. (simWhyTarget)
static func why_target(e: Dictionary) -> String:
	var names := []
	for b in (e.get("behaviors") if e.get("behaviors") != null else []):
		var d = Rules.beh_of(b.get("k"))
		if d != null:
			names.append(d["name"])
	return ", ".join(names) if not names.is_empty() else "closest"


static func _combo(e: Dictionary) -> Array:
	return (e.get("actions") if e.get("actions") != null else []).filter(func(a): return a.get("tag") == "Combo")


## The Action an Enemy would use on a target, and whether it can reach with
## it from where it stands: its next Combo Action if it can use that, else the
## first it can. (simEnemyAction)
func enemy_action(e: Dictionary, target: Dictionary) -> Dictionary:
	var combo := _combo(e)
	var pick = null
	if not combo.is_empty():
		var n := combo.size()
		var i := (int(Rules.num(e.get("comboAt"), 0)) % n + n) % n
		pick = combo[i]
	var usable := func(a) -> bool:
		if a == null:
			return false
		if a.get("tag") == "Passive" or a.get("tag") == "Aura":
			return false
		if tile_action(a):
			return false                # 0.23: Auto aims at Units, not tiles
		if not Rules.can_afford(e, a):
			return false
		if not aether_ok(e, a):
			return false                # one of yours under Auto, with a carried Action card
		if not can_reach(e, a, target):
			return false
		# (0.40) nor one that would only give the target a status it already has
		if pointless(a, target):
			return false
		# an Enemy never drops an area effect on its own side
		return not fx.hurts_own_side(e, a, target)
	if usable.call(pick):
		return {"action": pick, "inReach": true}
	for a in (e.get("actions") if e.get("actions") != null else []):
		if usable.call(a):
			return {"action": a, "inReach": true}
	var first = (e.get("actions") if e.get("actions") != null else [null])
	return {"action": pick if pick != null else (first[0] if not first.is_empty() else null), "inReach": false}


## (0.40) An Action that would do nothing to this target: it deals no damage
## and heals nothing, does nothing else, and every status it gives is one the
## target already has (or has only just shrugged off). Auto and the Enemies
## don't use it; they move to bring another Action in reach. (simPointless)
static func pointless(a: Dictionary, target: Dictionary) -> bool:
	var eff := Rules.action_effect(a)
	if Rules.num(eff["damage"], 0) > 0 or Rules.num(eff["heal"], 0) > 0:
		return false
	var statuses := []
	for p in Keywords.parse(a.get("text", "") if a.get("text") != null else ""):
		if p["type"] != "kw" or p["kw"] == null:
			continue
		var cat := str(p["kw"].get("cat", ""))
		if cat == "status":
			statuses.append(str(p["kw"]["name"]))
		elif cat in ["effect", "modifier", "stats"]:
			return false
	if statuses.is_empty():
		return false
	return statuses.all(func(k): return Rules.lock_block(target, k) != "")


## (0.40) A Unit whose chosen target is still out of reach after its move
## attacks another it can reach, chosen by its own Behavior keywords, rather
## than do nothing. {target, act}, or null. (simInReachInstead)
func in_reach_instead(e: Dictionary, pool: Array, target: Dictionary) -> Variant:
	var near := pool.filter(func(u): return not is_same(u, target) and not Rules.truthy(u.get("down")) and u.get("pos") is Dictionary and enemy_action(e, u)["inReach"])
	if near.is_empty():
		return null
	var pick = Rules.choose_target(e, near, {"distance": func(u): return Rules.hex_distance(e["pos"], u["pos"])})
	if pick == null:
		pick = near[0]
	return {"target": pick, "act": enemy_action(e, pick)}


func _tiles_for(u: Dictionary) -> Array:
	return reach_tiles(u, move_steps(u))


## One move toward a target: the reachable tile nearest it (the cheaper of two
## as near), if that is nearer than where it stands. A hazard is walked round
## when there's a way round, and through when there isn't. Its move is an
## event, and a held shot may answer it. (simStepToward)
func step_toward(e: Dictionary, target: Dictionary) -> bool:
	var tiles := _tiles_for(e)
	if tiles.is_empty():
		return false
	var clear := tiles.filter(func(t): return fx.hazard_at(Vector2i(t["q"], t["r"])) == null)
	var pool: Array = clear if not clear.is_empty() else tiles
	var best = null
	for t in pool:
		var d = Rules.hex_distance(t, target["pos"])
		if best == null or d < best["d"] or (d == best["d"] and t["cost"] < best["cost"]):
			best = {"q": t["q"], "r": t["r"], "d": d, "cost": t["cost"], "leap": t.get("leap", false)}
	var here = Rules.hex_distance(e["pos"], target["pos"])
	if not clear.is_empty() and best != null and best["d"] >= here:
		var through = null
		for t in tiles:
			var d2 = Rules.hex_distance(t, target["pos"])
			if through == null or d2 < through["d"]:
				through = {"q": t["q"], "r": t["r"], "d": d2, "cost": t["cost"], "leap": t.get("leap", false)}
		if through != null and through["d"] < best["d"]:
			best = through
	if best != null and best["d"] < here:
		var from := tile_of(e)
		e["pos"] = {"q": best["q"], "r": best["r"]}
		e["travel"] = int(Rules.num(e.get("travel"), 0)) + int(best["cost"])
		_beat({"type": "move", "unit": e["id"], "from": from, "to": tile_of(e), "path": _way(e, from, best["leap"])})
		fx.hazard_hit(e, "moves onto")
		fx.emit("moves", e)
		fx.react_to(e)
		return true
	return false


## One move away from the nearest of your Units, if any tile is further. (simStepAway)
func step_away(e: Dictionary, allies: Array) -> bool:
	var tiles := _tiles_for(e)
	if tiles.is_empty():
		return false
	var nearest := func(p) -> int:
		var m := 1 << 30
		for a in allies:
			m = mini(m, Rules.hex_distance(p, a["pos"]))
		return m
	var here: int = nearest.call(e["pos"])
	var best = null
	for t in tiles:
		var d: int = nearest.call(t)
		if best == null or d > best["d"]:
			best = {"q": t["q"], "r": t["r"], "d": d, "cost": t["cost"], "leap": t.get("leap", false)}
	if best != null and best["d"] > here:
		var from := tile_of(e)
		e["pos"] = {"q": best["q"], "r": best["r"]}
		e["travel"] = int(Rules.num(e.get("travel"), 0)) + int(best["cost"])
		_beat({"type": "move", "unit": e["id"], "from": from, "to": tile_of(e), "path": _way(e, from, best["leap"])})
		fx.hazard_hit(e, "backs onto")
		fx.emit("moves", e)
		fx.check_downs()
		return true
	return false


## One Enemy's turn, decided by the rules and its behaviour keywords: it backs
## off or closes in as they say, then attacks if it can, as many times as its
## Action's Burst gives, and what the Action says is carried out. Returns what
## happened, beat by beat, for the board to play:
##   {type: "move", unit, from, to, path}
##   {type: "react", unit, target, action, res, line}   a held shot answering its move
##   {type: "attack", unit, target, action, res, line, why}
##   {type: "skip", unit, line}
## each with floats, lines and after (see _beat).
## (simOneEnemy and simApplyEnemyAttack)
func enemy_turn(e: Dictionary) -> Array:
	_hook()
	end_player_turn()
	beats = []
	_enemy_turn(e)
	_close_beat()
	return beats


func _enemy_turn(e: Dictionary) -> void:
	e["travel"] = 0               # Revision 16.1: what it moves this turn, for Charge
	var allies := units.filter(func(u): return u["side"] == "ally" and not Rules.truthy(u.get("down")))
	if allies.is_empty() or Rules.truthy(e.get("down")):
		return
	# Stunned: "cannot act or move at all" (Handbook). It loses its turn, and
	# its Combo, interrupted, starts again. Until 0.7 it was only held to its
	# tile, and attacked anyway.
	if Rules.effective(e)["cannotAct"]:
		if not _combo(e).is_empty():
			e["comboAt"] = 0
		var stun: String = e["name"] + " is Stunned and loses its turn"
		_beat({"type": "skip", "unit": e["id"], "line": stun})
		say(stun)
		return
	var nearest := 1 << 30
	for a in allies:
		nearest = mini(nearest, Rules.hex_distance(e["pos"], a["pos"]))
	var plan := Rules.move_plan(e, {"nearestEnemyDistance": nearest})
	var why_move: String = (" (" + str(plan["why"]) + ")") if Rules.truthy(plan.get("why")) else ""
	if plan["move"] == "away":
		if step_away(e, allies):
			say(e["name"] + " backs off" + why_move)
	if not plan["act"]:
		if not _combo(e).is_empty():
			e["comboAt"] = 0
		var line: String = e["name"] + " does not act" + why_move
		_beat({"type": "skip", "unit": e["id"], "line": line})
		say(line)
		return
	var target = Rules.choose_target(e, allies, {"distance": func(u): return Rules.hex_distance(e["pos"], u["pos"])})
	if target == null:
		return
	var act := enemy_action(e, target)
	if not act["inReach"]:
		step_toward(e, target)
		act = enemy_action(e, target)
	# Where the game parts from the simulator, twice. There, an Enemy brought
	# down mid-move by a held shot went on to attack; and one still out of reach
	# after its move attacked anyway, from wherever it stood.
	if Rules.truthy(e.get("down")):
		return
	# (0.40) still out of reach: another in reach instead
	if not act["inReach"]:
		var alt = in_reach_instead(e, allies, target)
		if alt != null:
			target = alt["target"]
			act = alt["act"]
	if act["action"] == null:
		var line2: String = e["name"] + " has nothing it can use"
		_beat({"type": "skip", "unit": e["id"], "line": line2})
		say(line2)
		return
	if not act["inReach"]:
		var line4: String = e["name"] + " has nothing in reach"
		_beat({"type": "skip", "unit": e["id"], "line": line4})
		say(line4)
		return
	var action: Dictionary = act["action"]
	# Revision 16.1: a Lunge closes the gap first
	if not do_lunge(e, action, target):
		return
	var why := why_target(e)
	var burst_total := Effects.burst_of(action)
	var burst_done := 0
	while true:
		var cover := cover_for(target, e)
		var res := Rules.resolve_attack(e, charged(e, action), target, {"distance": Rules.hex_distance(e["pos"], target["pos"]), "cover": cover,
			"evasive": target.get("evasive") if Rules.truthy(target.get("evasive")) else 0, "rolls": {}, "dice": dice})
		if Rules.truthy(res.get("damage")) and charged(e, action).has("_charge"):
			res["charge"] = charge_of(action)
		res["cover"] = cover
		var bt := _beat({"type": "attack", "unit": e["id"], "target": target["id"], "action": action, "res": res, "why": why})
		bt["line"] = _enemy_attack(e, action, target, res, why, burst_done > 0)
		# the next attack of a Burst chooses afresh among what it can still reach
		burst_done += 1
		if burst_done < burst_total and not Rules.truthy(e.get("down")):
			var pool := units.filter(func(u): return u["side"] == "ally" and not Rules.truthy(u.get("down")) and Rules.truthy(u.get("pos")) and can_reach(e, action, u, true))
			if not pool.is_empty():
				var nt = Rules.choose_target(e, pool, {"distance": func(u): return Rules.hex_distance(e["pos"], u["pos"])})
				target = nt if nt != null else pool[0]
				why = why_target(e)
				continue
			say(e["name"] + "'s Burst ends: nothing left in reach")
		break
	after_attacks(e, target)


## simApplyEnemyAttack: what an Enemy's attack does. Returns its log line.
func _enemy_attack(e: Dictionary, action: Dictionary, target: Dictionary, res: Dictionary, why: String, follow: bool) -> String:
	if not follow:
		e["nrg"] = maxi(0, int(e["nrg"]) - int(Rules.num(action.get("cost"), 0)))
	target["lastAttackedBy"] = e["id"]
	target["attackedThisRound"] = true
	fx.emit("attacks", e, target)
	fx.emit("is attacked", target, e)
	var prev = fx.dealer
	fx.dealer = e
	var line: String = e["name"] + " used " + str(action["name"]) + " on " + target["name"] + " (" + why + "): "
	if Rules.truthy(res["damage"]):
		Rules.hit(target, res["damage"], true)   # Revision 16.3: Hardened is in the damage already
		line += str(res["damage"]) + " damage" + ((" (Charge +%d)" % int(res["charge"])) if Rules.truthy(res.get("charge")) else "") + (" halved" if Rules.truthy(res.get("halved")) else "") + ((" — " + target["name"] + " is down") if Rules.truthy(target.get("down")) else "")
	elif res["hit"] == false:
		line += "missed"
	elif res["penetrated"] == false:
		line += "no Penetration"
	else:
		line += "no effect"
	say(line)
	if Rules.truthy(action.get("text")) and res["hit"] != false and res["penetrated"] != false:
		fx.run_text(action["text"], {"actor": e, "target": target, "damaged": Rules.num(res["damage"], 0) > 0, "killed": Rules.truthy(target.get("down")),
			"damage": res["damage"] if Rules.truthy(res["damage"]) else 0, "sourceCard": action["name"]})
	fx.dealer = prev
	fx.check_downs()
	var combo := _combo(e)
	if not combo.is_empty() and action.get("tag") == "Combo" and not follow:
		e["comboAt"] = (int(Rules.num(e.get("comboAt"), 0)) + 1) % combo.size()
	return line


# ---------------------------------------------------------------- Auto
## One of your Units takes its turn by itself, by its Behavior keywords,
## exactly as an Enemy does by its own: a Medic tends its own first; it backs
## off, keeps station on a Hero or closes in; picks its target; and attacks if
## it can reach. Returns what it did, beat by beat, for the board to play.
## (simAutoOne)
func auto_turn(u: Dictionary) -> Array:
	_hook()
	undo.clear()                  # what Auto does isn't taken back
	beats = []
	_auto_turn(u)
	_close_beat()
	if not Rules.truthy(u.get("down")):
		find_loot(u)
	# it has had its turn: it won't move again this round, by hand or by Auto,
	# nor use a Dash it gained on the way (0.22: a Rake's, a Kinetic Recycler's)
	moved[u["id"]] = 1 << 20
	dash_used[u["id"]] = _dash_total(u)
	u["acted"] = true
	return beats


## Whether one of your Units has done anything this turn: moved, used an
## Action, or holds fire. Auto leaves those to you and takes the rest.
func has_acted(u: Dictionary) -> bool:
	return moved.has(u.get("id")) or Rules.truthy(u.get("acted")) or u.get("holding") != null


## Your Units Auto would take this turn, in the order they'd go.
func auto_queue() -> Array:
	return units.filter(func(u): return u["side"] == "ally" and not Rules.truthy(u.get("down")) and u.get("pos") is Dictionary and not has_acted(u)).map(func(u): return u["id"])


func _auto_turn(u: Dictionary) -> void:
	var foes := units.filter(func(x): return x["side"] == "enemy" and not Rules.truthy(x.get("down")))
	var allies := units.filter(func(x): return x["side"] == "ally" and not Rules.truthy(x.get("down")))
	if foes.is_empty() or Rules.truthy(u.get("down")):
		return
	# a Stunned Unit of yours loses its turn on Auto, as an Enemy does
	if Rules.effective(u)["cannotAct"]:
		var stun: String = u["name"] + " is Stunned and loses its turn"
		_beat({"type": "skip", "unit": u["id"], "line": stun})
		say(stun)
		return
	# a Medic looks after its own before it looks for a target
	var sup = Rules.support_plan(u, allies)
	# a carried Action card costs its Aether under Auto too; without it, it isn't used
	if sup != null and not aether_ok(u, sup["action"]):
		sup = null
	if sup != null:
		if sup["action"].get("aetherX") is Dictionary:
			set_action_x(sup["action"], 1)
		pay_aether(u, sup["action"])
		var hp0: int = int(Rules.num(sup["target"].get("hp"), 0))
		Rules.use_action(u, sup["action"], sup["target"])
		var line0: String = "%s used %s on %s (%s)" % [u["name"], sup["action"]["name"], sup["target"]["name"], sup["why"]]
		var gained: int = int(Rules.num(sup["target"].get("hp"), 0)) - hp0
		_beat({"type": "skip", "unit": u["id"], "line": line0})
		if gained > 0:
			floats.append({"unit": sup["target"]["id"], "text": "+%d HP" % gained, "kind": "heal", "own": true})      # the simulator shows none
		say(line0)
		return
	var nearest := 1 << 30
	for f in foes:
		nearest = mini(nearest, Rules.hex_distance(u["pos"], f["pos"]))
	var plan := Rules.move_plan(u, {"nearestEnemyDistance": nearest})
	if plan["move"] == "away":
		step_away(u, foes)
	elif plan["move"] == "escort":
		var hero = Rules.escort_target(u, allies)
		if hero != null and Rules.hex_distance(u["pos"], hero["pos"]) > 1:
			step_toward(u, hero)
	if not plan["act"]:
		var line: String = u["name"] + " holds back" + ((" (" + str(plan["why"]) + ")") if Rules.truthy(plan.get("why")) else "")
		_beat({"type": "skip", "unit": u["id"], "line": line})
		say(line)
		return
	var target = Rules.choose_target(u, foes, {"distance": func(x): return Rules.hex_distance(u["pos"], x["pos"])})
	if target == null:
		return
	var act := enemy_action(u, target)
	if not act["inReach"] and plan["move"] != "hold":
		step_toward(u, target)
		act = enemy_action(u, target)
	# a hazard on the way can bring it down
	if Rules.truthy(u.get("down")):
		return
	# (0.40) still out of reach: another in reach instead
	if not act["inReach"]:
		var alt = in_reach_instead(u, foes, target)
		if alt != null:
			target = alt["target"]
			act = alt["act"]
	if act["action"] == null or not act["inReach"]:
		var line2: String = u["name"] + " cannot reach " + target["name"]
		_beat({"type": "skip", "unit": u["id"], "line": line2})
		say(line2)
		return
	var action: Dictionary = act["action"]
	var why := why_target(u)
	# a carried Action card pays its Aether (at X = 1 if its cost is variable),
	# and a Burst makes every one of its attacks, each choosing afresh
	if action.get("aetherX") is Dictionary:
		set_action_x(action, 1)
	pay_aether(u, action)
	# Revision 16.1: a Lunge closes the gap first
	if not do_lunge(u, action, target):
		return
	var burst_total := Effects.burst_of(action)
	var burst_done := 0
	while true:
		var cover := cover_for(target, u)
		var res := Rules.resolve_attack(u, charged(u, action), target, {"dice": dice, "distance": Rules.hex_distance(u["pos"], target["pos"]), "cover": cover,
			"evasive": target.get("evasive") if Rules.truthy(target.get("evasive")) else 0})
		if Rules.truthy(res.get("damage")) and charged(u, action).has("_charge"):
			res["charge"] = charge_of(action)
		res["cover"] = cover
		var bt := _beat({"type": "attack", "unit": u["id"], "target": target["id"], "action": action, "res": res, "why": why})
		bt["line"] = _enemy_attack(u, action, target, res, why, burst_done > 0)
		burst_done += 1
		if burst_done < burst_total and not Rules.truthy(u.get("down")):
			var pool := units.filter(func(x): return x["side"] == "enemy" and not Rules.truthy(x.get("down")) and Rules.truthy(x.get("pos")) and can_reach(u, action, x, true))
			if not pool.is_empty():
				var nt = Rules.choose_target(u, pool, {"distance": func(x): return Rules.hex_distance(u["pos"], x["pos"])})
				target = nt if nt != null else pool[0]
				why = why_target(u)
				continue
			say(u["name"] + "'s Burst ends: nothing left in reach")
		break


## The way a Unit that has just moved came, tile by tile, for the board to
## walk it: the shortest way round walls and other Units.
func _walked(u: Dictionary, from: Vector2i) -> Array[Vector2i]:
	var to := tile_of(u)
	var out: Array[Vector2i] = []
	var wall := _wall_for(u)
	var parent := {from: from}
	var edge: Array[Vector2i] = [from]
	while not edge.is_empty() and not parent.has(to):
		var next: Array[Vector2i] = []
		for cur in edge:
			for n in Rules.hex_neighbours(cur.x, cur.y):
				var h := Vector2i(n["q"], n["r"])
				if parent.has(h) or not floor_data.has_tile(h):
					continue
				if wall.call({"q": cur.x, "r": cur.y}, n):
					continue
				var o = unit_at(h)
				if o != null and o != u:
					continue
				parent[h] = cur
				next.append(h)
		edge = next
	if not parent.has(to):
		return [to]
	var h := to
	while h != from:
		out.push_front(h)
		h = parent[h]
	return out


# ---------------------------------------------------------------- the round
## Whether the battle is over: every Hero down is a loss; every Enemy down
## with no more to come is a win; no Hero ever and nobody left standing, a
## draw. (simOutcome)
func outcome() -> Dictionary:
	var heroes := units.filter(func(u): return u["side"] == "ally" and Keywords._re("(?i)hero").search(str(u.get("cardType", "") if u.get("cardType") != null else "")) != null)
	var up := heroes.filter(func(u): return not Rules.truthy(u.get("down"))).size()
	if not heroes.is_empty() and up == 0:
		return {"over": true, "winner": "enemy"}
	if units.any(func(u): return u["side"] == "enemy" and not Rules.truthy(u.get("down"))):
		return {"over": false, "winner": null}
	if not nothing_more_coming():
		return {"over": false, "winner": null}
	if heroes.is_empty() and not units.any(func(u): return u["side"] == "ally" and not Rules.truthy(u.get("down"))):
		return {"over": true, "winner": "draw"}
	return {"over": true, "winner": "ally"}


## Settles the battle if it's over. Returns whether it is.
func settle() -> bool:
	var o := outcome()
	if o["over"] and not over:
		over = true
		winner = o["winner"]
		say({"ally": "Victory", "enemy": "Defeat", "draw": "A draw"}.get(winner, "Over") + " in round %d." % round, "note")
		_settle_loot(winner == "ally")
	return over


# ---------------------------------------------------------------- loot
## The floor's Skull Level, for what drops on it. (simPoiSkull)
func poi_skull() -> int:
	if deploy != null:
		return int(deploy["skull"])
	return Loot.poi_skull(floor_data)


func _add_loot(bag: Dictionary, who: String, from: String, at = null) -> void:
	if Loot.is_empty(bag):
		return
	loot = Loot.add(loot, bag)
	say(who + " " + from + ": " + loot_table.text(bag), "loot")
	if at is Dictionary and at.get("id") != null:
		var n := Loot.count(bag)
		floats.append({"unit": at["id"], "text": ("+%d shard%s" % [bag["shards"], "" if bag["shards"] == 1 else "s"]) if bag["shards"] > 0 else "loot", "kind": "loot", "own": true})
		if n > 0:
			floats.append({"unit": at["id"], "text": "+%d part%s" % [n, "" if n == 1 else "s"], "kind": "loot", "own": true})


## An Enemy that has gone down drops its loot, once: by its kind, its Skull
## Level (the floor's, if it has none of its own) and its Salvage. (simSalvage)
func salvage(u: Dictionary) -> void:
	if u.get("side") != "enemy" or _salvaged.has(u.get("id")) or pvp > 0:      # (0.26) a player's Unit drops nothing
		return
	_salvaged[u["id"]] = true
	var poi := poi_skull()
	var src := Loot.source_for(u.get("cardType"))
	_add_loot(loot_table.roll({"source": src, "skull": u["skull"] if Rules.truthy(u.get("skull")) else poi,
		"poiSkull": poi, "salvage": u.get("salvage")}), str(u["name"]), "drops", u)
	find_items(src, {"lootPool": u.get("lootPool"), "setDrops": u.get("setDrops")}, str(u["name"]), u)
	if Rules.truthy(u.get("bounty")):
		say("Bounty: %s is down. It pays once the team is home." % str(u["src"] if Rules.truthy(u.get("src")) else u["name"]), "note", {"bounty": true})


## A blueprint or a chassis, by the source's chance, from the District's pool
## and the Enemy's own; an Enemy's set drops by their own chance. One not
## found before keeps its name to itself until the fight is won. (simFindItems)
func find_items(src: String, card: Dictionary, who: String, at = null) -> void:
	if progress == null:
		return
	# (0.22) the cards that can be found: the campaign's roster, or this battle's own
	if not progress.card_source.is_valid():
		# (a list, not this battle: the progress outlives it)
		var mine: Array = cards if not cards.is_empty() else (roster.from_export if roster != null else [])
		progress.card_source = func(): return mine
	var source = loot_table.tables["sources"].get(src)
	var chance = source.get("bp") if source is Dictionary else 0
	# (0.22) an Elite, a Mini-Boss, a Boss or a Locked Chest may leave a card as well
	var card_chance = source.get("card", 0) if source is Dictionary else 0
	var sk = at.get("skull") if (at is Dictionary and Rules.truthy(at.get("skull")) and src != "chest" and src != "lootTile") else poi_skull()
	var pending: Array = found + (deploy["pending"] if deploy != null else [])
	for it in progress.roll_items({"chance": chance, "district": floor_data.district if floor_data != null else "", "card": card, "cardChance": card_chance, "skull": sk}, pending, loot_table):
		found.append(it)
		var nm := progress.item_name(it, false)
		var what := "a chassis" if str(it).begins_with("ch:") else ("a card" if str(it).begins_with("cd:") else "a blueprint")
		say(who + " leaves " + what + ((" not found before \u2014 win to keep it and learn what it is") if nm.begins_with("an unknown ") else (": " + nm)), "loot", {"item": true})
		if at is Dictionary and at.get("id") != null:
			floats.append({"unit": at["id"], "text": what, "kind": "loot", "own": true})


## A Locked Chest is a symbol whose text starts LC; a number after it (LC3)
## is how many components it holds. Returns -1 for none, else that number
## (0: the usual).
func chest_at(h: Vector2i) -> int:
	if not floor_data.marks.has(h):
		return -1
	var d = floor_data.sym_defs.get(floor_data.marks[h])
	if not (d is Dictionary):
		return -1
	var m := Keywords._re("(?i)^LC(\\d*)$").search(str(d.get("text") if d.get("text") != null else "").strip_edges())
	if m == null:
		return -1
	return int(m.get_string(1)) if m.get_string(1) != "" else 0


## One of yours that ends a move on a Loot Tile, or on a Locked Chest, finds
## what is there, once a fight. (simFindLoot)
func find_loot(u: Dictionary) -> void:
	if u.get("side") != "ally" or Rules.truthy(u.get("down")) or not (u.get("pos") is Dictionary):
		return
	var h := tile_of(u)
	if looted.has(h):
		return
	var chest := chest_at(h)
	if chest < 0 and kind_at(h) != "loot":
		return
	looted[h] = true
	var poi := poi_skull()
	if chest >= 0:
		_add_loot(loot_table.roll({"source": "chest", "poiSkull": poi, "x": chest if chest > 0 else null}), str(u["name"]), "opens a Locked Chest", u)
		find_items("chest", {}, "The chest", u)
	else:
		_add_loot(loot_table.roll({"source": "lootTile", "poiSkull": poi}), str(u["name"]), "finds", u)
		find_items("lootTile", {}, "The Loot Tile", u)


## The fight is over: what dropped, and, won, the floor's own reward.
## (simSettleLoot, less the keeping: that comes with the dock.)
func _settle_loot(won: bool) -> void:
	if not loot_result.is_empty():
		return
	if pvp > 0:
		# (0.26) a pass-and-play match keeps nothing, and the floor gives no reward
		loot_result = {"won": won, "haul": Loot.norm(loot), "reward": Loot.bag(), "total": Loot.norm(loot), "items": []}
		return
	var haul := Loot.norm(loot)
	var reward := Loot.bag()
	var items: Array = found.duplicate()
	if won and floor_data != null and floor_data.raw.get("loot") is Dictionary:
		reward = loot_table.roll_reward(floor_data.raw["loot"], poi_skull())
		if not Loot.is_empty(reward):
			say("The floor's reward: " + loot_table.text(reward), "loot", {"own": true})      # the simulator shows it on its result, not in its log
		# the reward's own blueprints and chassis, each by its chance
		if progress != null:
			var more := progress.roll_reward_items(floor_data.raw["loot"], items + (deploy["pending"] if deploy != null else []), loot_table)
			for it in more:
				say("The floor's reward: " + ("a chassis" if str(it).begins_with("ch:") else "a blueprint"), "loot", {"own": true, "item": true})
			items = items + more
	loot_result = {"won": won, "haul": haul, "reward": reward, "total": Loot.add(haul, reward), "items": items}


# ---------------------------------------------------------------- a deployment's fights
## An Emergency Exit is a symbol whose text is EX.
func exit_at(h: Vector2i) -> bool:
	if floor_data == null or not floor_data.marks.has(h):
		return false
	var d = floor_data.sym_defs.get(floor_data.marks[h])
	return d is Dictionary and str(d.get("text") if d.get("text") != null else "").strip_edges().to_upper() == "EX"


## Inside a POI, a Hero standing on an Emergency Exit can take the Strike Team out.
func can_escape(u) -> bool:
	return deploy != null and deploy["kind"] == "poi" and not over and u is Dictionary and u.get("side") == "ally" and not Rules.truthy(u.get("down")) \
		and u.get("pos") is Dictionary and str(u.get("cardType", "")).to_lower().contains("hero") and exit_at(tile_of(u))


## The Strike Team gets out: the fight ends, what it found comes along, and
## the POI's own reward is given up.
func escape(u: Dictionary) -> bool:
	if not can_escape(u):
		return false
	say(str(u["name"]) + " reaches the Emergency Exit. The Strike Team gets out.")
	over = true
	winner = "escape"
	undo.clear()
	say("Escaped in round %d." % round, "note")
	_settle_loot(false)
	return true


## What the deployment needs to know of a fight that is over. (simDeployFinish)
func deploy_result() -> Dictionary:
	var mine := units.filter(func(u): return u["side"] == "ally" and Rules.truthy(u.get("down")))
	var who := func(u): return str(u["src"] if Rules.truthy(u.get("src")) else u["name"])
	var sk: int = int(deploy["skull"]) if deploy != null else poi_skull()
	return {"winner": winner, "haul": loot_result.get("haul", Loot.bag()), "reward": loot_result.get("reward", Loot.bag()), "items": loot_result.get("items", []).duplicate(),
		"heroesDown": mine.filter(func(u): return str(u.get("cardType", "")).to_lower().contains("hero")).map(who),
		"troopsLost": mine.filter(func(u): return u.get("cardType") == "troop").map(who),
		"kills": units.filter(func(u): return u["side"] == "enemy" and Rules.truthy(u.get("down"))).map(func(u): return {"name": who.call(u), "skull": u["skull"] if Rules.truthy(u.get("skull")) else sk}),
		"consUsed": consumables.filter(func(c): return Rules.truthy(c.get("used"))).map(func(c): return c["name"])}


## The Enemies are done (simEndOfRound): held shots nobody walked into lapse,
## hazards bite whoever ends the turn on them, and Energy refills (a Troop to
## full, a Hero carrying what it didn't spend).
func end_enemy_phase() -> void:
	_hook()
	end_player_turn()
	undo.clear()
	fx.lapse_holds()
	fx.hazard_end_of_turn()
	for ev in Rules.end_turn(units):
		if ev["type"] == "status" and Rules.truthy(ev.get("expired")):
			var u = unit_by_id(ev["unit"])
			say((u["name"] if u != null else "A Unit") + " lost " + str(ev["name"]))
		elif ev["type"] == "status" and ev.get("energyLost") != null:
			var u3 = unit_by_id(ev["unit"])
			say("%s loses %d Energy to Drained" % [u3["name"] if u3 != null else "A Unit", ev["energyLost"]], "note")


## Your turn begins: what your Units moved last turn no longer counts for Charge.
## (simRunPhase "turn")
func begin_turn() -> void:
	phase = "turn"
	for u in units:
		if u["side"] == "ally" and Rules.truthy(u.get("travel")):
			u["travel"] = 0


## The next round begins: every Unit may move again.
func begin_round() -> void:
	round += 1
	moved.clear()
	dash_used.clear()
	for u in units:
		u.erase("acted")
	say("Round %d" % round, "note")


## The phases between the Enemies' turn and yours, in order. A Strike Team's
## fight has all five; a Quick battle only the Recharge.
func upkeep() -> Array:
	if with_cards:
		return ["waves", "gen", "chips", "draw", "recharge"]
	return ["waves", "recharge"] if waves_total > 1 else ["recharge"]


static func phase_name(k: String) -> String:
	for p in PHASES:
		if p["k"] == k:
			return p["name"]
	return k


## Runs one phase of the round. (simRunPhase)
func run_phase(k: String) -> void:
	_hook()
	phase = k
	match k:
		"waves": wave_step()
		"gen": phase_gen()
		"chips": phase_chips()
		"draw": phase_draw()
		"recharge": phase_recharge()


## The round turns over once the Enemies have acted, all at once: the end of
## their turn, then every phase up to yours. (The screen plays the phases one
## at a time, announcing each; this is the same thing in one go.)
func end_round() -> void:
	end_enemy_phase()
	begin_round()
	for k in upkeep():
		run_phase(k)
	begin_turn()


# ---------------------------------------------------------------- waves
func enemies_left() -> int:
	return units.filter(func(u): return u["side"] == "enemy" and not Rules.truthy(u.get("down"))).size()


## The Reveal Rule: turn cards until one of the tile's level appears, and put
## the rest at the bottom. A pile with none of that level leaves the tile empty.
func _reveal(level: int) -> Variant:
	var seen := 0
	while seen < enemy_pile.size():
		var c: Dictionary = enemy_pile.pop_front()
		var lv = Rules.num(c.get("level"), 1)
		if (int(lv) if Rules.truthy(lv) else 1) == level:
			return c
		enemy_pile.append(c)
		seen += 1
	return null


## Dimensional Instability (Handbook, Section 5): 3% for every District
## cleared, up to 15%, that a spawn brings an Elite (two times in three) or a
## Mini-Boss (one in three) in place of the drawn Enemy, whatever the tile's
## level. It is chosen from those of the floor's own District, of the kind
## rolled; with none there, the ordinary Enemy arrives after all (15.8). (0.42)
## On a deployment, the test set's only when there are no others; and below
## Skull 4 a deployment's fight has none (Deployment.INSTABILITY_FROM).
## (simInstabilityPick)
func _instability_pick() -> Variant:
	if instability <= 0:
		return null
	if dice.roll("d100") > instability:
		return null
	var want := "elite" if dice.roll("d6") <= 4 else "miniboss"
	var district := str(floor_data.district) if floor_data != null else ""
	var pool := cards.filter(func(c): return c is Dictionary and c.get("cardType") == want and (district == "" or Roster.district_of(c) == district))
	# (0.42) on a deployment, the test set's only when the export has no others (as its Enemies, 0.40)
	var real := pool.filter(func(c): return not Roster.is_test(c))
	if deploy != null and not real.is_empty():
		pool = real
	if pool.is_empty():
		say("Dimensional instability stirs, but " + (("District " + district) if district != "" else "this place") +
			" has no " + ("Elite" if want == "elite" else "Mini-Boss") + " to send: an ordinary Enemy arrives")
		return null
	return pool[int(floor(float(dice.roll("d20")) / 21.0 * pool.size()))]


## The next wave arrives: an Enemy on every open Enemy spawn tile, revealed
## from the pile at the tile's level. Returns how many came. (simSpawnWave)
func spawn_wave() -> int:
	if wave >= waves_total:
		return 0
	_hook()
	wave += 1
	wave_turn = 0
	var made := 0
	var missed := 0
	var spawns := enemy_spawns()
	# (0.36) at Skull 1 or 2 on a deployment, the spawn tiles take turns; (0.40) and on a large floor
	var turns := deploy != null and spawns.size() > 1 and (Deployment.soft(deploy["skull"]) or Roster.hero_capacity(floor_data) >= 3)
	for i in spawns.size():
		var t: Dictionary = spawns[i]
		if turns and (wave + i) % 2 == 0:
			continue
		if unit_at(t["at"]) != null:
			continue                       # something is standing there
		var card = null
		var special = _instability_pick()
		if special != null:
			card = {"name": special["name"], "level": t["level"], "card": special}
			say("Dimensional instability: " + str(special["name"]) + " arrives in place of an ordinary Enemy")
		else:
			card = _reveal(t["level"])
			if card == null:
				missed += 1
				continue
		var src = card.get("card")
		if src == null and roster != null:
			src = roster.card_named(str(card["name"]))
		if src == null:
			for c in cards:
				if c.get("name") == card["name"]:
					src = c
					break
		if src == null:
			missed += 1
			continue
		var lk: Array = roster.enemy_looks(src) if roster != null else []
		var look: Dictionary = {}
		if lk.size() >= 2:
			look = lk[rng.randi_range(0, lk.size() - 1)]
		elif lk.size() == 1:
			look = lk[0]
		var u := _add(src, "enemy", look)
		u["pos"] = {"q": t["at"].x, "r": t["at"].y}
		u["spawnLevel"] = t["level"]
		# on a deployment it fights, and drops, at the level it spawned at
		if deploy != null:
			u["skull"] = t["level"]
		_met(u, src)
		arrive(u)
		made += 1
	say("Wave %d of %d: " % [wave, waves_total] + (("%d Enemy arrives" % made if made == 1 else "%d Enemies arrive" % made) if made > 0 else "nothing arrives") +
		((" (%d Spawn Tile%s had nothing left to draw)" % [missed, "" if missed == 1 else "s"]) if missed > 0 else ""))
	return made


## An Enemy met: known from now on (the Bounty Board names only those met),
## and, on a deployment, one the Bounty Board wants wears its tag. (0.10)
func _met(u: Dictionary, card) -> void:
	var nm := str(card.get("name", "")) if card is Dictionary else str(u.get("name", ""))
	if progress != null:
		progress.see("enemy", nm)
	if deploy != null and deploy.get("bounties") is Array and deploy["bounties"].has(nm):
		u["bounty"] = true


## Nothing more can arrive once the last wave has come, or the pile can no
## longer answer any spawn tile's level. (simNothingMoreComing)
func nothing_more_coming() -> bool:
	if wave < waves_total:
		var levels := {}
		for t in enemy_spawns():
			levels[t["level"]] = true
		for c in enemy_pile:
			var lv = Rules.num(c.get("level"), 1)
			if levels.has(int(lv) if Rules.truthy(lv) else 1):
				return false
	return true


## The Waves phase: the next wave comes when the board is clear, or when the
## wave timer runs out. (simWaveStep)
func wave_step() -> void:
	if wave == 0:
		spawn_wave()
		return
	wave_turn += 1
	var clear := enemies_left() == 0
	if wave >= waves_total:
		return
	if clear or wave_turn >= maxi(1, wave_timer):
		if not clear:
			say("The wave timer runs out.")
		spawn_wave()


## Rounds until the next wave comes by itself, or -1 when no more will.
func next_wave_in() -> int:
	if wave >= waves_total or nothing_more_coming():
		return -1
	return maxi(1, maxi(1, wave_timer) - wave_turn)


# ---------------------------------------------------------------- Aether, Chips and cards
## A pool of Aether as it reads: "2 D3  1◇", or "—" for none. (simAetherLabel)
static func aether_label(pool: Dictionary) -> String:
	var keys: Array = pool.keys()
	keys.sort()
	var parts := []
	for k in keys:
		if not Rules.truthy(pool[k]):
			continue
		parts.append(str(pool[k]) + ("\u25c7" if k == "generic" else " D" + str(k).substr(1)))
	return "  ".join(parts) if not parts.is_empty() else "\u2014"


## The Aether Generation phase: what wasn't spent is lost, then every standing
## Hero generates Aether of its own Affinity.
func phase_gen() -> void:
	if Rules.truthy(Rules.aether_total(aether)):
		say("Unspent Aether is lost: " + aether_label(aether))
	aether = {}
	_income()


func _income() -> void:
	var income := Rules.aether_income(units, "ally")
	if Rules.truthy(Rules.aether_total(income)):
		Rules.aether_add(aether, income)
		say("Heroes generated " + aether_label(income))
	else:
		say("No Hero generated Aether this turn")


## The Aether Draw phase: Chips equal to the Player Level come out of the
## Pouch into the Bank, and every Chip in the Bank generates its Aether. (simPhaseChips)
func phase_chips() -> void:
	var drew := []
	for i in player_level:
		if pouch.is_empty():
			break
		var idx := int(floor(float(dice.roll("d20")) / 21.0 * pouch.size()))
		var chip: Dictionary = pouch.pop_at(mini(idx, pouch.size() - 1))
		chip["spent"] = false
		bank.append(chip)
		drew.append(chip)
	say(("Drew %d Aether Chip%s: " % [drew.size(), "" if drew.size() == 1 else "s"] + ", ".join(drew.map(func(c): return str(c["name"])))) if not drew.is_empty() else "The Aether Pouch is empty")
	var gen := {}
	for c in bank:
		var key: String = ("d" + str(c["district"])) if Rules.truthy(c.get("district")) else "generic"
		gen[key] = gen.get(key, 0) + (c["value"] if Rules.truthy(c.get("value")) else 0)
	if Rules.truthy(Rules.aether_total(gen)):
		Rules.aether_add(aether, gen)
		say("The Bank generated %s from %d Chip%s" % [aether_label(gen), bank.size(), "" if bank.size() == 1 else "s"])


## The Draw phase: one card for every Hero standing (six to open). (simPhaseDraw)
func phase_draw(opening := false) -> void:
	var heroes := units.filter(func(u): return u["side"] == "ally" and not Rules.truthy(u.get("down")) and Keywords._re("(?i)hero").search(str(u.get("cardType", "") if u.get("cardType") != null else "")) != null).size()
	var want := 6 if opening else heroes
	var pulled := 0
	for h in want:
		if deck.is_empty() and not refill_deck():
			break
		hand.append(deck.pop_front())
		pulled += 1
	say(("Drew %d card%s" % [pulled, "" if pulled == 1 else "s"]) if pulled > 0 else ("No Hero left to draw for" if not deck.is_empty() else "The Deck is empty"))


## (0.40) An empty Deck takes back the cards played so far, shuffled: every one
## in the discard pile but a Troop's (a fallen Troop stays fallen). Returns
## whether there are cards to draw again. (simRefillDeck)
func refill_deck() -> bool:
	if not deck.is_empty():
		return true
	var back := discard.filter(func(c): return c is Dictionary and str(c.get("type", "")) != "troop")
	if back.is_empty():
		return false
	discard = discard.filter(func(c): return not (c is Dictionary and str(c.get("type", "")) != "troop"))
	_shuffle(back)
	deck = back
	say("The Deck is empty: %d played card%s shuffled back in" % [back.size(), " is" if back.size() == 1 else "s are"])
	return true


## The Recharge: every status ticks, for everyone at once; what is always on
## is worked out afresh, always-on Passives do their one-off effects, "the
## round begins" is announced; and spent Chips turn face-up again.
func phase_recharge() -> void:
	_tell_tick(Rules.recharge_tick(units), "recharge")
	fx.check_downs()
	fx.dealer = null
	fx.apply_continuous()
	fx.round_passives()
	fx.emit("the round begins")
	fx.check_downs()
	if with_cards:
		var n := bank.filter(func(c): return Rules.truthy(c.get("spent"))).size()
		for c in bank:
			c["spent"] = false
		say(("Recharge: %d Chip%s turned face-up" % [n, "" if n == 1 else "s"]) if n > 0 else "Recharge: nothing was spent")


## Kept for the screen's Next round in 0.2 tests: just the turnover.
func next_round() -> void:
	end_round()


# ---------------------------------------------------------------- (0.26) pass and play
const PVP_KEYS := ["aether", "bank", "pouch", "deck", "hand", "discard", "consumables", "protos", "leader_id", "player_level"]


## A match between two Strike Teams on one floor, for two players passing the
## phone. Player 1's team starts on the Player Spawn Tiles, Player 2's on the
## Enemy Spawn Tiles (or, on a floor without enough of them, on the tiles
## furthest from Player 1's). Player 1 goes first, with the opening Aether,
## Chips and six cards; Player 2 has theirs as their first turn begins.
## s1, s2: StrikeTeams.setup_for of each team.
static func begin_pvp(f: FloorData, r: Roster, s1: Dictionary, s2: Dictionary, seed = null, names: Array = []) -> Battle:
	var b := Battle.new()
	b.roster = r
	b.cards = r.cards
	b._set_floor(f, seed)
	b.pvp = 1
	b.with_cards = true
	b.waves_total = 0
	b.wave = 0
	if names.size() == 2:
		b.pvp_names = {1: str(names[0]), 2: str(names[1])}
	b._build_team(s1, "ally")
	var first := b._take_side()
	b._build_team(s2, "enemy")
	b.pvp_store = b._take_side()
	b._give_side(first)
	b.wave_timer = 0
	b.instability = 0
	b._place_allies()
	b._place_side("enemy")
	b.deploy_start()
	b._income()
	b.phase_chips()
	b.phase_draw(true)
	b.phase = "turn"
	b.pvp_snap()
	b.say("Round 1 · %s's turn" % b.pvp_names[1], "note")
	b.floats.clear()
	return b


## The side whose turn it is: its resources, taken off the battle (left empty).
func _take_side() -> Dictionary:
	var o := {}
	for k in PVP_KEYS:
		o[k] = get(k)
	aether = {}
	bank = []
	pouch = []
	deck = []
	hand = []
	discard = []
	consumables = []
	protos = []
	leader_id = ""
	player_level = 1
	return o


func _give_side(o: Dictionary) -> void:
	for k in PVP_KEYS:
		if o.has(k):
			set(k, o[k])


## The other player's Units go where the floor puts Enemies; without enough
## Enemy Spawn Tiles, on the free tiles furthest from the Player Spawn Tiles.
func _place_side(side: String) -> void:
	var taken := {}
	for u in units:
		if u.get("pos") is Dictionary:
			taken[Battle.tile_of(u)] = true
	var spawns := spawn_tiles("enemy")
	var mine := ally_spawns()
	var far := func(h: Vector2i) -> int:
		var d := 1 << 30
		for m in mine:
			d = mini(d, Hex.distance(h, m))
		return d if not mine.is_empty() else -h.y
	var extra: Array = floor_data.tiles.keys().filter(func(h): return not spawns.has(h) and kind_at(h) != "spawn-ally" and not kind_at(h).begins_with("cover") and unit_at(h) == null)
	extra = Rules.stable_sort(extra, func(a, c): return far.call(c) - far.call(a))
	var overflow := false
	for u in units:
		if u["side"] != side:
			continue
		var at = _claim(spawns, taken)
		if at == null:
			at = _claim(extra, taken)
			overflow = true
		if at != null:
			u["pos"] = {"q": at.x, "r": at.y}
	if overflow:
		notes.append("%s's team starts across the floor from %s's: it has too few Enemy Spawn Tiles for them all." % [pvp_names[2], pvp_names[1]])


func pvp_player() -> int:
	return pvp


func pvp_other() -> int:
	return 3 - pvp if pvp > 0 else 0


## The name of the player a side belongs to now ("ally": whose turn it is).
func pvp_name_of(side: String) -> String:
	if pvp == 0:
		return side
	return pvp_names[pvp] if side == "ally" else pvp_names[pvp_other()]


## The player whose turn it is ends it: what ends with a turn ends (a Dash, a
## held shot, a hazard under their Units), and the battle may be over. The
## other player takes the phone next (pvp_hand_over).
func pvp_end_turn() -> void:
	_hook()
	if pvp == 0 or phase != "turn" or over:
		return
	pvp_tally()
	undo.clear()
	phase = "handoff"
	for u in units:
		if u["side"] == "ally" and Rules.truthy(u.get("dash")):
			u["dash"] = 0
	fx.lapse_holds()
	for u in units:
		if u["side"] == "ally" and not Rules.truthy(u.get("down")):
			fx.hazard_hit(u, "ends its turn on")
	fx.check_downs()
	settle()


## The other player's turn begins: every Unit changes side, the players'
## cards and Aether change places, the incoming player's Units refill their
## Energy, and their Aether Generation, Aether Draw, Draw and Recharge play out
## (the opening Aether, Chips and six cards, the first time). A new round
## begins when it is Player 1's turn again.
## Handbook 15.9 holds for both: a Status lasts through the turn after the one
## it arrived in. Each player's Statuses tick as that player's next turn
## begins, so each is marked, at every hand-off, as the other half's.
func pvp_hand_over() -> void:
	_hook()
	if pvp == 0 or over:
		return
	for u in units:
		u["side"] = "enemy" if u["side"] == "ally" else "ally"
		for st in (u.get("statuses") if u.get("statuses") is Array else []):
			st["late"] = not Rules.truthy(st.get("late"))
		for m in (u.get("mods") if u.get("mods") is Array else []):
			m["late"] = not Rules.truthy(m.get("late"))
		if u.get("guards") is Dictionary:
			for g in u["guards"].keys():
				u["guards"][g] = not bool(u["guards"][g])
	var waiting := pvp_store
	pvp_store = _take_side()
	_give_side(waiting)
	pvp = pvp_other()
	var new_round := pvp == 1
	if new_round:
		round += 1
	moved.clear()
	dash_used.clear()
	for u in units:
		u.erase("acted")
		if u["side"] == "ally" and Rules.truthy(u.get("travel")):
			u["travel"] = 0
	say("Round %d · %s's turn" % [round, pvp_names[pvp]], "note")
	for ev in Rules.end_turn(units.filter(func(u): return u["side"] == "ally")):
		if ev["type"] == "status" and ev.get("energyLost") != null:
			var u3 = unit_by_id(ev["unit"])
			say("%s loses %d Energy to Drained" % [u3["name"] if u3 != null else "A Unit", ev["energyLost"]], "note")
	if not pvp_opened.get(pvp, true):
		pvp_opened[pvp] = true
		phase = "gen"
		_income()
		phase = "chips"
		phase_chips()
		phase = "draw"
		phase_draw(true)
	else:
		for k in ["gen", "chips", "draw"]:
			run_phase(k)
	phase = "recharge"
	_tell_tick(Rules.recharge_tick(units), "recharge")
	fx.check_downs()
	fx.dealer = null
	fx.apply_continuous()
	if new_round:
		fx.round_passives()
		fx.emit("the round begins")
		fx.check_downs()
	var n := bank.filter(func(c): return Rules.truthy(c.get("spent"))).size()
	for c in bank:
		c["spent"] = false
	if n > 0:
		say("Recharge: %d Chip%s turned face-up" % [n, "" if n == 1 else "s"])
	phase = "turn"
	settle()
	pvp_snap()


# ---------------------------------------------------------------- (0.33) the match, in numbers
## Each player's damage dealt, Units brought down and cards played. What the
## other player's Units lose in a player's turn is that player's doing (a
## hazard under one's own Units is nobody's); a Unit brought down then, theirs.
var pvp_stats := {1: {"damage": 0, "downs": 0, "cards": 0}, 2: {"damage": 0, "downs": 0, "cards": 0}}
var _pvp_seen := {}            # the other player's Units, as the turn began: id -> [hp, down]


func _pvp_count(k: String, n := 1) -> void:
	if pvp > 0 and pvp_stats.has(pvp):
		pvp_stats[pvp][k] += n


## The other side's Units as they stand: what the player whose turn it is does to them is counted from here.
func pvp_snap() -> void:
	_pvp_seen = {}
	if pvp == 0:
		return
	for u in units:
		if u["side"] == "enemy":
			_pvp_seen[str(u["id"])] = [int(Rules.num(u.get("hp"), 0)), Rules.truthy(u.get("down"))]


## Counts what this turn has done so far (and starts counting again from here).
func pvp_tally() -> void:
	if pvp == 0:
		return
	for u in units:
		var was = _pvp_seen.get(str(u["id"]))
		if u["side"] != "enemy" or was == null:
			continue
		var hp := int(Rules.num(u.get("hp"), 0))
		if hp < int(was[0]):
			_pvp_count("damage", int(was[0]) - hp)
		if Rules.truthy(u.get("down")) and not was[1]:
			_pvp_count("downs")
	pvp_snap()


## Who won a match, by name: "" while it goes on, or for a draw.
func pvp_winner() -> String:
	if pvp == 0 or not over:
		return ""
	if winner == "ally":
		return pvp_names[pvp]
	if winner == "enemy":
		return pvp_names[pvp_other()]
	return ""
