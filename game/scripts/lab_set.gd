## (Lab) KETER Lab, the experimental build: the Lab card set laid over whatever
## export the game plays, yours included. The set (data/lab_set.json, made by
## lab/make_lab_set.js) holds a build for every master card, not the card: each
## is compiled here with the Lab systems (LabSystems), as the Companion does
## with its Lab switch on (lab_set.js), so the two show the same cards.
##
## Only KETER Lab lays it (project setting keter/lab, which make_game.py's Lab
## build sets); the main game plays every export as it is. The tests switch it
## with force().
##
## The set: {format, version, systems, cards: [{name, id, build, was, art,
## meta, merges, aetherCost, change, why}], retired: [{name, into, why}], kept}.
## A set card takes the place of the export's master card of its name (or the
## one it "was": a card that became another, as the cluster ordnance became
## Lay Waste); what its build doesn't decide (District, archetypes, loot, lore,
## pictures) stays that card's. A new card brings its own ("meta") and shows
## the pictures of the card it names ("art"). A retired card is left out. A
## master card the set doesn't mention (the test set's, the tokens) stays as
## it is, and so does every card that isn't a master card (your designs, the
## Sandbox's).
class_name LabSet
extends RefCounted

const PATH := "res://data/lab_set.json"
const FORMAT := 1

static var _set = null            # the set as read; {} when there is none
static var _from := ""            # a set to read instead of the build's (the lab's tools)
static var _forced := -1          # (tests) 1 on, 0 off, -1 as the project says


## (the lab's tools) Read the set from this file ("" for the build's own).
static func use(path: String) -> void:
	_from = path
	_set = null


## (tests) Lay the set (true) or not (false), whatever the project says; reset() undoes it.
static func force(on: bool) -> void:
	_forced = 1 if on else 0


static func reset() -> void:
	_forced = -1
	_from = ""
	_set = null


static func data() -> Dictionary:
	if _set == null:
		_set = {}
		var p := _from if _from != "" else PATH
		if FileAccess.file_exists(p):
			var d = JSON.parse_string(FileAccess.get_file_as_string(p))
			if d is Dictionary and d.get("cards") is Array and int(Rules.num(d.get("format"), 0)) <= FORMAT:
				_set = d
	return _set


## Whether this build lays the set: KETER Lab does (and it has one to lay).
static func active() -> bool:
	var on: bool = (_forced == 1) if _forced >= 0 else bool(ProjectSettings.get_setting("keter/lab", false))
	return on and not data().is_empty()


## "S1", or "" with no set laid.
static func version() -> String:
	return str(data().get("version", "")) if active() else ""


## The names the set retires (merged into another, or gone).
static func retired() -> Dictionary:
	var out := {}
	for r in data().get("retired", []):
		if r is Dictionary:
			out[str(r.get("name", ""))] = r
		else:
			out[str(r)] = {"name": str(r)}
	return out


## An export's cards with the set laid over them (as it is when the set isn't laid).
static func apply_cards(cards: Array) -> Array:
	if not active():
		return cards
	var s := data()
	var by := {}                  # master card's name -> the set card in its place
	for lc in s["cards"]:
		if lc is Dictionary:
			by[str(lc.get("was", lc.get("name", "")))] = lc
	var gone := retired()
	var out := []
	var placed := {}
	for c in cards:
		if not (c is Dictionary):
			continue
		if str(c.get("_src", "master")) != "master":
			out.append(c)
			continue
		var nm := str(c.get("name", ""))
		if gone.has(nm):
			continue
		var lc = by.get(nm)
		if lc == null or placed.has(str(lc.get("name", ""))):
			out.append(c)
			continue
		placed[str(lc.get("name", ""))] = true
		out.append(card(lc, c))
	# the set's new cards, and any whose master card this export hasn't got
	for lc in s["cards"]:
		if lc is Dictionary and not placed.has(str(lc.get("name", ""))):
			placed[str(lc.get("name", ""))] = true
			out.append(card(lc, null))
	return out


## One set card as the game reads it: the master card it takes the place of
## (or its own meta), with what its build compiles to.
static func card(lc: Dictionary, was) -> Dictionary:
	var e: Dictionary = was.duplicate(true) if was is Dictionary else {}
	if lc.get("meta") is Dictionary:
		for k in lc["meta"]:
			e[k] = lc["meta"][k].duplicate(true) if (lc["meta"][k] is Dictionary or lc["meta"][k] is Array) else lc["meta"][k]
	var r := LabSystems.compile(Rules.ints(lc.get("build", {})))
	var cc = r.get("card")
	if cc is Dictionary:
		for k in ["cardType", "rarity", "skullLevel", "combatRoles", "stats", "entries", "lab"]:
			if cc.has(k):
				e[k] = cc[k]
	e.erase("abilities")              # (the old form of entries)
	e["name"] = str(lc.get("name", ""))
	if Rules.truthy(lc.get("id")):
		e["id"] = str(lc["id"])
	e["aetherCost"] = lc["aetherCost"].duplicate() if lc.get("aetherCost") is Dictionary else null
	e["hasVariableCost"] = null       # (the Lab has no X cost)
	e["_src"] = "master"
	e["_lab"] = str(lc.get("change", "rebuilt"))
	var art := str(lc.get("art", ""))
	if art == "" and was is Dictionary:
		art = str(was["_artName"]) if Rules.truthy(was.get("_artName")) else str(was.get("name", ""))
	if art != "" and art != e["name"]:
		e["_artName"] = art
	return e
