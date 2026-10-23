## For the tests: a Strike Team built from the test cards, and a file of
## their own to keep teams in, so a test never touches the teams you've built.
extends RefCounted

const PATH := "user://test_strike_teams.json"
const SETTINGS := "user://test_settings.json"
const BEHAVIORS := "user://test_behaviors.json"
const CAMPAIGN := "user://test_campaign.json"
const SANDBOX := "user://test_sandbox.json"


## Points the game's saved teams at the tests' own file, and empties it.
static func fresh() -> void:
	StrikeTeams.path = PATH
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	# and the Behavior keywords chosen for cards, likewise
	Behaviors.path = BEHAVIORS
	Behaviors.forget_all()
	# and the World Map as it has been explored, the stockpile and what has been found
	Campaign.path = CAMPAIGN
	if FileAccess.file_exists(CAMPAIGN):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CAMPAIGN))
	# (0.12) and the speed, shake and sound; and nothing moves, as 0.11 played, unless a test says so
	Motion.path = SETTINGS
	Motion.reset()
	Motion.still = true
	# (0.25) the tests' teams lead with Heroes nobody has recruited: they count as yours, unless a test says not
	Dock.every_hero = true
	# (0.26) and the Sandbox: a file of the tests' own, empty
	Sandbox.path = SANDBOX
	Sandbox.clear()


## Three Heroes (the third has the Action Slots, and carries an Action card),
## seventeen cards, a Pouch that covers them, one Prototype and three kinds of
## Consumable, every card written with keywords: a team the rules have nothing
## to object to.
static func team(name := "Test Vanguard") -> Dictionary:
	var t := StrikeTeams.blank(name)
	t["level"] = 2
	t["heroes"] = ["Test Warden", "Test Striker", "Quillon Vex"]
	t["deck"] = {"Test Drone": 3, "Test Sapper": 2, "Test Battery": 2, "Test Scout": 2, "Test Plating": 1, "Test Targeting Suite": 1,
		"Test Mortar Strike": 1, "Test Snare": 1, "Test Rally": 1, "Test Strip": 1, "Test Surge": 2}
	t["actions"] = {"Quillon Vex": ["Test Piercing Rounds"]}
	t["pouch"] = {"basic|3": 6, "Test Spark Chip": 2}
	t["protos"] = ["Test Aegis Core"]
	t["consumables"] = {"Test Stim": 2, "Test Repair Kit": 1, "Test Sandbags": 1}
	return t


## The same team as it can leave the dock (0.9): its Troops are the starter
## design's free copies, the rest of its Deck as it was.
static func field_team(name := "Test Vanguard") -> Dictionary:
	var t := team(name)
	for n in ["Test Drone", "Test Sapper", "Test Battery", "Test Scout"]:
		t["deck"].erase(n)
	t["deck"]["Frame Trooper"] = 3
	return t


## Saves these teams where the tests keep theirs.
static func keep(teams: Array) -> void:
	StrikeTeams.save_all(teams)


## A team thrown together from whatever the export holds, for the soak tests:
## one to three Heroes, a Deck of 10 to 30 cards, a Pouch, and sometimes
## Prototypes, carried Action cards and Consumables.
static func random_team(r: Roster, rng: RandomNumberGenerator, name := "Soak") -> Dictionary:
	var t := StrikeTeams.blank(name)
	t["level"] = rng.randi_range(1, 3)
	var heroes: Array = r.heroes().duplicate()
	for k in rng.randi_range(1, 3):
		if not heroes.is_empty():
			t["heroes"].append(heroes.pop_at(rng.randi() % heroes.size())["name"])
	var pool := r.of_types(StrikeTeams.DECK_TYPES)
	for k in rng.randi_range(10, 30):
		var c: Dictionary = pool[rng.randi() % pool.size()]
		t["deck"][c["name"]] = int(t["deck"].get(c["name"], 0)) + 1
	# now and then, cards with a variable cost, so that X is chosen and paid for
	if rng.randf() < 0.5:
		for n in ["Test Swarm", "Test Barrage", "Test Capacitor", "Test Drone Bank"]:
			if r.card_named(n) != null and rng.randf() < 0.7:
				t["deck"][n] = int(t["deck"].get(n, 0)) + rng.randi_range(1, 2)
	var acts := r.of_types(["action"])
	for h in t["heroes"]:
		var got := []
		for k in StrikeTeams.action_slots(r.card_named(h)):
			if not acts.is_empty() and rng.randf() < 0.7:
				var a: String = acts[rng.randi() % acts.size()]["name"]
				if not got.has(a):
					got.append(a)
		# and now and then a carried Action card that asks for X
		if StrikeTeams.action_slots(r.card_named(h)) > got.size() and r.card_named("Test Overcharge") != null and rng.randf() < 0.4:
			got.append("Test Overcharge")
		if not got.is_empty():
			t["actions"][h] = got
	var chips := r.of_types(["sphere"])
	for k in rng.randi_range(4, 12):
		var key := ("basic|" + str(rng.randi_range(1, 6))) if (chips.is_empty() or rng.randf() < 0.6) else str(chips[rng.randi() % chips.size()]["name"])
		t["pouch"][key] = int(t["pouch"].get(key, 0)) + 1
	var cons := r.of_types(["consumable"])
	for k in rng.randi_range(0, 4):
		if not cons.is_empty():
			var cn: String = cons[rng.randi() % cons.size()]["name"]
			t["consumables"][cn] = int(t["consumables"].get(cn, 0)) + 1
	var protos := r.of_types(["prototype"])
	for k in rng.randi_range(0, 2):
		if not protos.is_empty():
			var p: String = protos[rng.randi() % protos.size()]["name"]
			if not t["protos"].has(p):
				t["protos"].append(p)
	return t


## Sends a team onto a floor as a player might: as many of its Heroes as the
## floor lets in, one of them leading, some Troops out of the Deck beside them
## (within their Leadership), a wave timer of 1 to 4, and none to five
## Districts cleared (Dimensional Instability).
static func entry(t: Dictionary, r: Roster, f: FloorData, rng: RandomNumberGenerator) -> Dictionary:
	var entering: Array = t["heroes"].slice(0, Roster.hero_capacity(f))
	var ldr := 0
	for h in entering:
		ldr += StrikeTeams.leadership(r.card_named(h))
	var starters := []
	for e in StrikeTeams.troops_in_deck(t, r):
		for k in e["copies"]:
			var sl := Roster.slots(e["card"])
			if sl <= ldr and rng.randf() < 0.5:
				starters.append(e["card"]["name"])
				ldr -= sl
	return StrikeTeams.setup_for(t, r, entering, entering[rng.randi() % entering.size()], starters, rng.randi_range(1, 4), rng.randi_range(0, 5) * 3)


## A random team as it can leave the dock (0.9): its Troops only your
## designs, the starter's copies (1 to 6 of them: past the free ones they are
## paid for) and now and then some of the designs named.
static func field_random(r: Roster, rng: RandomNumberGenerator, name := "Soak", designs: Array = []) -> Dictionary:
	var t := random_team(r, rng, name)
	for n in t["deck"].keys():
		var c = r.card_named(str(n))
		if c != null and Roster.type_of(c) == "troop" and c.get("_src") != "workshop":
			t["deck"].erase(n)
	t["deck"]["Frame Trooper"] = rng.randi_range(1, 6)
	for d in designs:
		if rng.randf() < 0.4:
			t["deck"][str(d)] = rng.randi_range(1, 2)
	return t


## An effect put together by random taps on the keyword builder, as a player
## might: the sentence Inserted, or "" when it was given up. o: what
## Builder.begin takes. Every tap is one the sheet offers.
static func random_effect(o: Dictionary, rng: RandomNumberGenerator, most_taps := 80) -> String:
	var sh := BuilderSheet.new()
	var got := [""]
	sh.done.connect(func(t): got[0] = t)
	sh.open(o)
	for i in most_taps:
		if not sh.b.open:
			break
		var offers := sh.offers()
		if offers.is_empty():
			break
		var tap: Array = offers[rng.randi() % offers.size()]
		if offers.has(["kb", "insert"]) and rng.randf() < 0.6:
			tap = ["kb", "insert"]
		elif offers.has(["kb", "next"]) and rng.randf() < 0.3:
			tap = ["kb", "next"]
		elif tap == ["kb", "back"] and rng.randf() < 0.7:
			tap = offers[rng.randi() % offers.size()]
		sh.act(tap)
	sh.free()
	return got[0]
