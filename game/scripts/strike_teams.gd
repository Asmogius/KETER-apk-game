## Strike Teams: what you build before a fight and keep between them. A team
## is up to 3 Heroes, one Deck of 10 to 60 Combat Cards shared by them, the
## Action cards each Hero carries, one Aether Pouch, any Prototypes, and a
## Player Level (Handbook, Sections 3, 6 and 7), and the Consumables it
## carries (Section 9).
##
## A team is a plain Dictionary, saved as it is:
##   name, level (1 to 6),
##   heroes   [card names, in order],
##   deck     {card name: copies},
##   actions  {Hero name: [Action card names]},
##   pouch    {chip: how many}   a chip is "basic|3" (1 Aether of District 3)
##                               or the name of a Chip card,
##   protos   [Prototype card names],
##   consumables {Consumable card name: how many}
## Cards are kept by name, so a team outlives a new export; a card the export
## no longer has stays in the team and is flagged, never silently dropped.
##
## The checks are the Companion's Deck Builder's (pingsForLoadout), word for
## word, and like them they never block anything: they say what the rules say.
class_name StrikeTeams
extends RefCounted

const FILE := "user://strike_teams.json"
const FORMAT := 1
## What may go in a Deck. Action cards never do: a Hero carries those.
const DECK_TYPES := ["troop", "equipment", "command", "aether"]
const DISTRICTS := ["1", "2", "3", "4", "5", "6"]

## Where the teams are kept (the tests point this somewhere of their own).
static var path := FILE


# ---------------------------------------------------------------- a team
static func blank(name := "New Strike Team") -> Dictionary:
	return {"name": name, "level": 1, "heroes": [], "deck": {}, "actions": {}, "pouch": {}, "protos": [], "consumables": {}}


## Fills in anything a saved team lacks, and returns it.
static func tidy(t: Dictionary) -> Dictionary:
	var b := blank(str(t.get("name", "Strike Team")))
	for k in b:
		if not t.has(k) or typeof(t[k]) != typeof(b[k]):
			t[k] = b[k]
	var lv = Rules.num(t["level"], 1)
	t["level"] = clampi(int(lv) if Rules.truthy(lv) else 1, 1, 6)
	return t


static func copy_of(t: Dictionary, name: String) -> Dictionary:
	var c: Dictionary = t.duplicate(true)
	c["name"] = name
	return c


static func _card(r: Roster, name) -> Variant:
	return r.card_named(Roster.ref_name(str(name))) if r != null else null


## The team's Heroes, as cards (one the export no longer has is left out).
static func heroes(t: Dictionary, r: Roster) -> Array:
	var out := []
	for n in t.get("heroes", []):
		var c = _card(r, n)
		if c != null:
			out.append(c)
	return out


## The Deck as cards, each as many times as it has copies.
static func deck_cards(t: Dictionary, r: Roster) -> Array:
	var out := []
	var d: Dictionary = t.get("deck", {})
	for n in d:
		var c = _card(r, n)
		if c == null:
			continue
		for i in copies(t, str(n)):
			out.append(c)
	return out


static func copies(t: Dictionary, name: String) -> int:
	var n = Rules.num(t.get("deck", {}).get(name), 0)
	return maxi(0, int(n) if Rules.truthy(n) else 0)


## How many cards the Deck holds (copies counted, missing cards too).
static func deck_count(t: Dictionary) -> int:
	var n := 0
	for k in t.get("deck", {}):
		n += copies(t, str(k))
	return n


static func set_copies(t: Dictionary, name: String, n: int) -> void:
	if n <= 0:
		t["deck"].erase(name)
	else:
		t["deck"][name] = n


## The Action cards a Hero carries, as cards.
static func carried(t: Dictionary, r: Roster, hero_name: String) -> Array:
	var out := []
	for n in t.get("actions", {}).get(hero_name, []):
		var c = _card(r, n)
		if c != null:
			out.append(c)
	return out


## Every Action card any Hero of the team carries.
static func all_carried(t: Dictionary, r: Roster) -> Array:
	var out := []
	for h in t.get("actions", {}):
		out.append_array(carried(t, r, str(h)))
	return out


static func action_slots(hero: Dictionary) -> int:
	var n = Rules.num((hero.get("stats") if hero.get("stats") is Dictionary else {}).get("slots"), 0)
	return maxi(0, int(n) if Rules.truthy(n) else 0)


static func leadership(hero: Dictionary) -> int:
	var n = Rules.num((hero.get("stats") if hero.get("stats") is Dictionary else {}).get("ldr"), 0)
	return int(n) if Rules.truthy(n) else 0


## A card's whole Aether cost: generic plus both Districts.
static func aether_cost(c: Dictionary) -> int:
	var a: Dictionary = c["aetherCost"] if c.get("aetherCost") is Dictionary else {}
	var total := 0
	for k in ["generic", "affinity", "affinity2"]:
		var n = Rules.num(a.get(k), 0)
		total += int(n) if Rules.truthy(n) else 0
	return total


# ---------------------------------------------------------------- the Pouch
## The Pouch must hold at least as many Chips as the full cost of the most
## expensive card in the Deck. (Handbook, The Aether Pouch)
## A variable cost counts at its least: X is 1. (Handbook 15.8)
static func pouch_minimum(t: Dictionary, r: Roster) -> int:
	var m := 0
	for c in deck_cards(t, r):
		m = maxi(m, Roster.cost_least(c))
	return m


## The Chips packed: [{key, chip (a card, a basic chip, or null), qty}].
static func pouch_entries(t: Dictionary, r: Roster) -> Array:
	var out := []
	var p: Dictionary = t.get("pouch", {})
	for k in p:
		var q = Rules.num(p[k], 0)
		q = int(q) if Rules.truthy(q) else 0
		if q > 0:
			out.append({"key": str(k), "chip": chip_by_key(str(k), r), "qty": q})
	return out


static func pouch_count(t: Dictionary, r: Roster) -> int:
	var n := 0
	for e in pouch_entries(t, r):
		n += e["qty"]
	return n


## A basic Chip: 1 Aether of its District.
static func basic_chip(d: String) -> Dictionary:
	return {"key": "basic|" + d, "name": "Basic Chip · District " + d, "district": d, "basic": true, "aetherValue": 1, "cardType": "sphere"}


static func chip_by_key(k: String, r: Roster) -> Variant:
	if k.begins_with("basic|"):
		var d := k.split("|")[1]
		return basic_chip(d) if DISTRICTS.has(d) else null
	return _card(r, k)


static func chip_district(ch) -> String:
	if not (ch is Dictionary):
		return ""
	if Rules.truthy(ch.get("basic")):
		return str(ch.get("district", ""))
	return Roster.district_of(ch)


static func set_chips(t: Dictionary, key: String, n: int) -> void:
	if n <= 0:
		t["pouch"].erase(key)
	else:
		t["pouch"][key] = n


# ---------------------------------------------------------------- Consumables
## The Consumables packed: [{name, card (or null), qty}].
static func consumable_entries(t: Dictionary, r: Roster) -> Array:
	var out := []
	var c: Dictionary = t.get("consumables", {})
	for k in c:
		var q = Rules.num(c[k], 0)
		q = int(q) if Rules.truthy(q) else 0
		if q > 0:
			out.append({"name": str(k), "card": _card(r, k), "qty": q})
	return out


static func consumable_count(t: Dictionary, r: Roster) -> int:
	var n := 0
	for e in consumable_entries(t, r):
		n += e["qty"]
	return n


static func set_consumables(t: Dictionary, name: String, n: int) -> void:
	if n <= 0:
		t["consumables"].erase(name)
	else:
		t["consumables"][name] = n


## The team's cards whose text is, in part or whole, plain: it won't happen
## when the card is used. Troops and Heroes aren't listed: they fight by
## their numbers whatever their text. Names, each once.
static func plain_cards(t: Dictionary, r: Roster) -> Array:
	var names := []
	names.append_array(t.get("deck", {}).keys())
	for h in t.get("actions", {}):
		names.append_array(t["actions"][h])
	for k in t.get("pouch", {}):
		if not str(k).begins_with("basic|"):
			names.append(k)
	names.append_array(t.get("consumables", {}).keys())
	names.append_array(t.get("protos", []))
	var out := []
	for n in names:
		var c = _card(r, n)
		if c != null and Roster.type_of(c) != "troop" and Roster.type_of(c) != "hero" and Roster.has_plain_text(c) and not out.has(str(c["name"])):
			out.append(str(c["name"]))
	return out


# ---------------------------------------------------------------- the checks
## Cards the team names that this export doesn't have.
static func missing(t: Dictionary, r: Roster) -> Array:
	var out := []
	var names := []
	names.append_array(t.get("heroes", []))
	names.append_array(t.get("deck", {}).keys())
	for h in t.get("actions", {}):
		names.append_array(t["actions"][h])
	for k in t.get("pouch", {}):
		if not str(k).begins_with("basic|"):
			names.append(k)
	names.append_array(t.get("protos", []))
	names.append_array(t.get("consumables", {}).keys())
	for n in names:
		if _card(r, n) == null and not out.has(str(n)):
			out.append(str(n))
	return out


## What the rules have to say about a team: [[level, text, cite, pinned]],
## level "bad", "warn" or "info". None of it blocks. With own, the game's own
## notes come as well: cards missing from the export (first), more than 3
## kinds of Consumable, and cards in plain text (last).
## (The rest is the Companion's pingsForLoadout, word for word.)
static func pings(t: Dictionary, r: Roster, own := true) -> Array:
	var out := []
	if own:
		var gone := missing(t, r)
		if not gone.is_empty():
			out.append(["bad", "%d card%s this team uses %s not in this export: %s. %s kept in the team, and left out of a fight." % [gone.size(), "" if gone.size() == 1 else "s",
				"is" if gone.size() == 1 else "are", ", ".join(gone), "It is" if gone.size() == 1 else "They are"], "", false])
	var hs := heroes(t, r)
	var deck := deck_cards(t, r)
	var n := deck.size()
	if hs.is_empty():
		out.append(["bad", "This Strike Team has no Hero. It needs at least one to lead a Combat.", "Handbook 14.0 - Section 7, Deployment Rules"])
	if t.get("heroes", []).size() > 3:
		out.append(["bad", "A Strike Team holds up to 3 Heroes.", "Handbook 14.0 - Section 7"])
	if n < 10 or n > 60:
		out.append(["bad", "The Deck holds %d card%s. A Deck is 10 to 60." % [n, "" if n == 1 else "s"], "Handbook 14.0 - Section 6, Decks"])
	var acts := deck.filter(func(c): return c.get("cardType") == "action")
	if not acts.is_empty():
		out.append(["bad", "%d Action Card%s in the Deck. Action Cards are never part of it — assign them to a Hero instead." % [acts.size(), " is" if acts.size() == 1 else "s are"],
			"Handbook 14.0 - Section 3, Action Cards"])
	for h in hs:
		var got: int = t.get("actions", {}).get(h["name"], []).size()
		var cap := action_slots(h)
		if got > cap:
			out.append(["bad", "%s carries %d Action Cards but has %d Action Slot%s." % [h["name"], got, cap, "" if cap == 1 else "s"], "Handbook 14.0 - Section 3, Action Cards"])
	var need := pouch_minimum(t, r)
	var have := pouch_count(t, r)
	if need > 0 and have < need:
		out.append(["bad", "The Aether Pouch holds %d chip%s. The most expensive card in the Deck costs %d, so it needs at least %d." % [have, "" if have == 1 else "s", need, need],
			"Handbook 14.0 - Section 6, The Aether Pouch"])
	# cards that need a District's Aether, with no chip of that District to pay
	var need_d := {}
	var have_d := {}
	for c in deck + all_carried(t, r):
		var ac: Dictionary = c["aetherCost"] if c.get("aetherCost") is Dictionary else {}
		var affs: Array = c["affinities"] if c.get("affinities") is Array else []
		for pair in [["affinity", 0], ["affinity2", 1]]:
			var amt = Rules.num(ac.get(pair[0]), 0)
			if (int(amt) if Rules.truthy(amt) else 0) > 0 and affs.size() > pair[1] and affs[pair[1]] is Dictionary and Rules.truthy(affs[pair[1]].get("district")) and str(affs[pair[1]]["district"]) != "any" and str(affs[pair[1]]["district"]) != "neu":
				var d := str(affs[pair[1]]["district"])
				need_d[d] = need_d.get(d, 0) + 1
	for e in pouch_entries(t, r):
		var d2 := chip_district(e["chip"])
		if d2 != "":
			have_d[d2] = 1
	var ds: Array = need_d.keys()
	ds.sort()
	for d in ds:
		if not have_d.has(d):
			var k: int = need_d[d]
			out.append(["warn", "%d card%s District %s Aether, but the Pouch holds no District %s chip, so %s cannot be paid for." % [k, " needs" if k == 1 else "s need", d, d, "it" if k == 1 else "they"],
				"Handbook 14.0 - Section 6, District matching"])
	if not hs.is_empty():
		var ldr := 0
		for h in hs:
			ldr += leadership(h)
		out.append(["info", "Pooled Leadership %d: up to %d Unit Slots of Troops can start a Combat, chosen from the Deck before it begins. Only the Heroes who enter add theirs." % [ldr, ldr],
			"Handbook 14.0 - Section 3, Leadership"])
	if hs.size() == 1:
		out.append(["warn", "One Hero, so there is never a reserve: a lost Combat cannot be retried.", "Handbook 14.0 - Section 7, Losing a Combat", true])
	if own:
		var kinds := consumable_entries(t, r).filter(func(e): return e["card"] != null).size()
		if kinds > 3:
			out.append(["warn", "The team carries %d kinds of Consumable. Only 3 kinds may be brought to a battle." % kinds, "Handbook 15.7 - Section 9, Consumables", false])
		var plain := plain_cards(t, r)
		if not plain.is_empty():
			out.append(["warn", "%d card%s here %s text the game can't carry out, because it isn't written with keywords: %s. Used in a fight, that text does nothing. Rewrite it in the Companion's Card Forge and export again." % [
				plain.size(), "" if plain.size() == 1 else "s", "has" if plain.size() == 1 else "have", ", ".join(plain)], "", false])
	return out


## How many of a team's checks are problems ("bad") and how many warnings.
static func tally(list: Array) -> Dictionary:
	var out := {"bad": 0, "warn": 0, "info": 0}
	for p in list:
		out[p[0]] = out.get(p[0], 0) + 1
	return out


## A team can fight if it has a Hero. Nothing else stops it.
static func can_fight(t: Dictionary, r: Roster) -> bool:
	return not heroes(t, r).is_empty()


# ---------------------------------------------------------------- into a fight
## What Battle.begin_team needs: the Heroes entering (names, in the team's
## order), who leads, the Starting Troops (names, out of the Deck) and the
## wave timer.
static func setup_for(t: Dictionary, r: Roster, entering: Array, leader: String, start_troops: Array, wave_timer := 3, instability := 0) -> Dictionary:
	var hs := heroes(t, r).filter(func(c): return entering.has(c["name"]))
	var carried_by := {}
	for h in hs:
		carried_by[h["name"]] = carried(t, r, h["name"])
	return {"heroes": hs, "leader": leader, "actions": carried_by, "start_troops": start_troops.duplicate(), "deck": deck_cards(t, r),
		"pouch": t.get("pouch", {}).duplicate(), "level": t.get("level", 1), "protos": t.get("protos", []).filter(func(n): return _card(r, n) != null), "wave_timer": wave_timer,
		"consumables": _packed(t, r), "instability": instability}


## The Consumables that go into a fight: those this export still has.
static func _packed(t: Dictionary, r: Roster) -> Dictionary:
	var out := {}
	for e in consumable_entries(t, r):
		if e["card"] != null:
			out[e["name"]] = e["qty"]
	return out


## The Troop cards in the Deck that could start a fight, each once: [{card, copies}].
static func troops_in_deck(t: Dictionary, r: Roster) -> Array:
	var out := []
	for n in t.get("deck", {}):
		var c = _card(r, n)
		if c != null and Roster.type_of(c) == "troop" and copies(t, str(n)) > 0:
			out.append({"card": c, "copies": copies(t, str(n))})
	return out


# ---------------------------------------------------------------- keeping them
## Every saved team. A file that can't be read gives none, and says why in error.
static var error := ""


static func load_all() -> Array:
	error = ""
	if not FileAccess.file_exists(path):
		return []
	var json := JSON.new()
	var data = json.data if json.parse(FileAccess.get_file_as_string(path)) == OK else null
	if not (data is Dictionary) or not (data.get("teams") is Array):
		error = "The saved Strike Teams couldn't be read."
		return []
	var out := []
	for t in Rules.ints(data["teams"]):
		if t is Dictionary:
			out.append(tidy(t))
	return out


static func save_all(teams: Array) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		error = "The Strike Teams couldn't be saved."
		return false
	f.store_string(JSON.stringify({"game": "KETER", "format": FORMAT, "teams": teams}, "\t"))
	f.close()
	return true


## A name no other team has: "Vanguard", then "Vanguard 2".
static func free_name(teams: Array, want: String) -> String:
	var names := teams.map(func(t): return str(t.get("name", "")))
	if not names.has(want):
		return want
	var i := 2
	while names.has("%s %d" % [want, i]):
		i += 1
	return "%s %d" % [want, i]
