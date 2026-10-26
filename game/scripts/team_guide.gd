## (0.35) Building a first Strike Team, one step at a time. With no Strike Team
## yet, the Strike Teams screen opens the Team editor on a new one in this
## walk-through: name it, choose its Heroes, fill its Deck, give its Heroes
## their Action cards, fill its Pouch, and look it over. Each step says what it
## needs before Next goes on; the Deck and the Pouch can be suggested, from
## Common cards (which are free to take out on a deployment) and Basic Chips.
## Prototypes and Consumables wait for later: the full editor has them.
class_name TeamGuide
extends RefCounted

const STEPS := [
	{"id": "name", "tab": "", "title": "Name it",
		"text": "A Strike Team is up to 3 Heroes, one Deck they share, the Action cards each Hero carries, and an Aether Pouch. First, give it a name: tap Name it. You can rename it at any time."},
	{"id": "heroes", "tab": "heroes", "title": "Choose its Heroes",
		"text": "Tap a Hero to read it, then add it. One is enough to begin; up to 3 share the Deck. The free Heroes can lead a deployment from the start; others are recruited at the dock."},
	{"id": "deck", "tab": "deck", "title": "Fill its Deck",
		"text": "The Deck is 10 to 60 Troop, Equipment, Command and Aether cards. Tap a card to set how many copies. Common cards are free to take on a deployment. Suggest a Deck fills it with Common cards to start."},
	{"id": "carried", "tab": "carried", "title": "Give out Action cards",
		"text": "Each Hero can carry Action cards, up to its Action Slots: they are its own Actions in a fight, never in the Deck. This step can be skipped."},
	{"id": "pouch", "tab": "pouch", "title": "Fill its Pouch",
		"text": "The Pouch holds the Chips that make Aether to play cards. It needs at least as many as the Deck's most expensive card costs. Suggest a Pouch fills it with Basic Chips of the Deck's Districts."},
	{"id": "checks", "tab": "checks", "title": "Look it over",
		"text": "What the rules say about the team. Set the Player Level at the top if you like. Tap Finish: the team is ready for practice fights and, with recruited or free Heroes, for a deployment."}]
const DECK_SIZE := 20
const POUCH_SIZE := 10


static func count() -> int:
	return STEPS.size()


## What a step still needs before Next goes on ("" when nothing).
static func needs(step: int, t: Dictionary, r: Roster) -> String:
	match str(STEPS[clampi(step, 0, STEPS.size() - 1)]["id"]):
		"name":
			if str(t.get("name", "")).strip_edges() == "":
				return "Give it a name first."
		"heroes":
			if StrikeTeams.heroes(t, r).is_empty():
				return "Add at least one Hero."
		"deck":
			var n := StrikeTeams.deck_count(t)
			if n < 10:
				return "The Deck needs at least 10 cards (it has %d)." % n
			if n > 60:
				return "The Deck holds at most 60 cards (it has %d)." % n
		"pouch":
			var have := StrikeTeams.pouch_count(t, r)
			var need := maxi(1, StrikeTeams.pouch_minimum(t, r))
			if have < need:
				return "The Pouch needs at least %d Chip%s (it has %d)." % [need, "" if need == 1 else "s", have]
	return ""


static func _common(c: Dictionary) -> bool:
	return Dock.hero_rarity(c) == 0 and not ["design", "prebuilt"].has(str(c.get("_src", "")))


## Fills an empty Deck to 20 with Common cards: Troops first, two copies each,
## those of the Heroes' Districts before the rest; then Equipment, Command and
## Aether cards the same way. Cards the Deck already holds are kept.
static func suggest_deck(t: Dictionary, r: Roster) -> int:
	var homes := {}
	for h in StrikeTeams.heroes(t, r):
		homes[Roster.district_of(h)] = true
	var pick := func(types: Array) -> Array:
		var cs: Array = r.of_types(types).filter(func(c): return _common(c))
		# not the test cards when there are others
		var real := cs.filter(func(c): return not str(c["name"]).begins_with("Test "))
		if not real.is_empty():
			cs = real
		cs.sort_custom(func(a, b):
			var ha: bool = homes.has(Roster.district_of(a))
			var hb: bool = homes.has(Roster.district_of(b))
			return ha if ha != hb else str(a["name"]) < str(b["name"]))
		return cs
	var added := 0
	var room := func() -> int: return DECK_SIZE - StrikeTeams.deck_count(t)
	for c in (pick.call(["troop"]) as Array).slice(0, 4) + pick.call(["equipment", "command", "aether"]):
		if room.call() <= 0:
			break
		if StrikeTeams.copies(t, str(c["name"])) > 0:
			continue
		var k := mini(2, room.call())
		StrikeTeams.set_copies(t, str(c["name"]), k)
		added += k
	return added


## Fills the Pouch with Basic Chips, split by the Districts the Deck's cards
## come from (by copies), to at least what it needs and 10. Returns how many were added.
static func suggest_pouch(t: Dictionary, r: Roster) -> int:
	var want := maxi(POUCH_SIZE, StrikeTeams.pouch_minimum(t, r)) - StrikeTeams.pouch_count(t, r)
	if want <= 0:
		return 0
	var by := {}
	for c in StrikeTeams.deck_cards(t, r):
		var d := Roster.district_of(c)
		if StrikeTeams.DISTRICTS.has(d):
			by[d] = int(by.get(d, 0)) + 1
	for h in StrikeTeams.heroes(t, r):
		var d := Roster.district_of(h)
		if StrikeTeams.DISTRICTS.has(d) and not by.has(d):
			by[d] = 1
	if by.is_empty():
		by["1"] = 1
	var ds: Array = by.keys()
	ds.sort_custom(func(a, b): return by[a] > by[b] if by[a] != by[b] else str(a) < str(b))
	var total := 0
	for d in ds:
		total += int(by[d])
	var given := 0
	for i in ds.size():
		var d: String = ds[i]
		var n := (want - given) if i == ds.size() - 1 else int(round(float(want) * by[d] / total))
		n = clampi(n, 0, want - given)
		if n > 0:
			var key := "basic|" + d
			StrikeTeams.set_chips(t, key, int(Rules.num(t["pouch"].get(key), 0)) + n)
			given += n
	return given
