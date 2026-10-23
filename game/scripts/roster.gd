## Everything a battle is set up from, read out of the Companion's export: the
## Heroes, Troops and Enemies that can take part, how many may, and how each
## one looks. The choices mirror the Companion's Battle Simulator.
class_name Roster
extends RefCounted

var data: KeterExport
## What you have found so far (the campaign's), so a fight knows which
## blueprints and chassis could still drop. Null: nothing found yet.
var progress: Progress = null
var cards: Array = []            # every card, numbers made whole: your designs first
var from_export: Array = []      # the export's own
var _skins: Array = []


func _init(export_data: KeterExport) -> void:
	data = export_data
	var seen := {}
	for c in Rules.ints(data.cards()):
		if not (c is Dictionary):
			continue
		# one card per source and name. (The simulator also folds names that differ
		# only in capitals, which loses "Aether battery", the Aether card, behind
		# "Aether Battery", the Troop. The game keeps both.)
		var k := str(c.get("_src", "m")) + "|" + str(c.get("name", ""))
		if seen.has(k):
			continue
		seen[k] = true
		from_export.append(c)
		# an Archetype is a keyword too ("target Sniper enemy"): the library learns them from the cards
		Keywords.register_archetypes(c.get("archetypes"))
	cards = from_export.duplicate()
	_skins = Rules.ints(data.content("skins").get("skins", []))


## Your Workshop's designs, as cards, join the export's (0.9). A card of the
## export's with the same name as a design of yours (the Companion's own copy
## of the starter, say) gives way to it.
func set_designs(design_cards: Array) -> void:
	var mine := {}
	for c in design_cards:
		mine[str(c.get("name", ""))] = true
	cards = design_cards.duplicate() + from_export.filter(func(c): return not mine.has(str(c.get("name", ""))))


static func type_of(c: Dictionary) -> String:
	return str(c.get("cardType", "")).to_lower()


## Your own designs and pre-builts first, then the rest; test cards last.
static func _group(c: Dictionary) -> int:
	var src := str(c.get("_src", ""))
	if src == "workshop":
		return -1
	if src == "design" or src == "prebuilt":
		return 0
	if src == "test":
		return 3
	if src == "master":
		return 2
	return 1


func _ordered(list: Array) -> Array:
	return Rules.stable_sort(list, func(a, b): return _group(a) - _group(b))


func heroes() -> Array:
	return _ordered(cards.filter(func(c): return type_of(c) == "hero"))


func troops() -> Array:
	return _ordered(cards.filter(func(c): return type_of(c) == "troop"))


func enemies() -> Array:
	return cards.filter(func(c): return type_of(c) == "enemy")


func card_named(name: String) -> Variant:
	for c in cards:
		if c.get("name") == name:
			return c
	return null


## A few words for how a card came to be here, or "".
static func origin(c: Dictionary) -> String:
	match str(c.get("_src", "")):
		"workshop": return "Your design"
		"design": return "Companion design"
		"prebuilt": return "Pre-built"
		"test": return "Test card"
	return ""


# ---------------------------------------------------------------- how many
## The floor's size decides how many Heroes enter: Small 1, Medium 2, Large 3.
## A floor saved without a size is sized by counting its tiles.
static func hero_capacity(f: FloorData) -> int:
	var sz := size_word(f)
	if sz == "":
		var n := f.tiles.size()
		sz = "Small" if n < 100 else ("Medium" if n <= 250 else "Large")
	return {"small": 1, "medium": 2, "large": 3}.get(sz.to_lower(), 1)


## The size the Sandbox saved (battlefieldSize, or the older floorSize), or "".
static func size_word(f: FloorData) -> String:
	for k in ["battlefieldSize", "floorSize"]:
		if Rules.truthy(f.raw.get(k)):
			return str(f.raw[k])
	return ""


## A Hero's Leadership: the Unit Slots of Troops it brings in.
static func leadership(c: Dictionary) -> int:
	return int(Rules.num(c.get("stats", {}).get("ldr"), 0))


## The Unit Slots a Troop takes (the simulator counts a blank or 0 as 1).
static func slots(c: Dictionary) -> int:
	var n = Rules.num(c.get("stats", {}).get("uslot"), 0)
	return int(n) if Rules.truthy(n) else 1


## An Enemy card's level: its Skull Level, or its level, or 1.
static func foe_level(c: Dictionary) -> int:
	var v = c.get("skullLevel") if Rules.truthy(c.get("skullLevel")) else c.get("level")
	var n = Rules.num(v, 0)
	return int(n) if Rules.truthy(n) else 1


static func district_of(c: Dictionary) -> String:
	var a = c.get("affinities")
	if a is Array and a.size() > 0 and a[0] is Dictionary:
		return str(a[0].get("district", "") if a[0].get("district") != null else "")
	return ""


## The Enemies a spawn tile draws from: the floor's District at the tile's
## level; failing that any District at that level; then the nearest level,
## lower first. (The Battle Simulator's deployment rule.)
func foe_pool(level: int, district: String) -> Array:
	var foes := enemies()
	for d in [0, -1, 1, -2, 2, -3, 3, -4, 4, -5, 5]:
		var want: int = level + d
		if want < 1 or want > 6:
			continue
		var same := foes.filter(func(c): return foe_level(c) == want and district != "" and district_of(c) == district)
		if not same.is_empty():
			return same
		var any := foes.filter(func(c): return foe_level(c) == want)
		if not any.is_empty():
			return any
	return foes


## The loot tables as you set them on the Companion's Loot page, or null for
## an export that carries none (the game then uses loot.js's own).
func loot_tables() -> Variant:
	if data == null:
		return null
	var t = data.content("tables").get("loot")
	return Rules.ints(t) if t is Dictionary else null


# ---------------------------------------------------------------- units
## A card as the rules read it (the simulator's simUnitSpec).
static func unit_spec(card: Dictionary) -> Dictionary:
	var raw: Dictionary = card.get("_raw") if card.get("_raw") is Dictionary else {}
	var fx = raw.get("abilities") if raw.get("abilities") else (card.get("entries") if card.get("entries") else (card.get("abilities") if card.get("abilities") else []))
	var affs = card.get("affinities")
	if not (affs is Array and affs.size() > 0):
		affs = []
		if Rules.truthy(raw.get("aff")):
			affs.append({"district": raw["aff"], "level": Rules.num(raw.get("lvl"), 0)})
		if Rules.truthy(raw.get("aff2")):
			affs.append({"district": raw["aff2"], "level": Rules.num(raw.get("lvl2"), 0)})
	var roles = card.get("combatRoles")
	if roles == null:
		roles = []
		if raw.get("roles") is Dictionary:
			for k in raw["roles"]:
				if Rules.truthy(raw["roles"][k]):
					roles.append(k)
	var skull = Rules.num(card.get("skullLevel") if Rules.truthy(card.get("skullLevel")) else raw.get("skull"), 0)
	var spec := {"name": card.get("name"), "src": card.get("name"), "cardType": card.get("cardType"),
		"subtype": raw.get("subtype") if Rules.truthy(raw.get("subtype")) else card.get("subtype"),
		"stats": raw.get("stats") if Rules.truthy(raw.get("stats")) else card.get("stats"),
		"behaviors": raw.get("behaviors") if Rules.truthy(raw.get("behaviors")) else card.get("behaviors"),
		"combatRoles": roles, "archetypes": card.get("archetypes") if Rules.truthy(card.get("archetypes")) else (raw.get("arches") if raw.get("arches") != null else []),
		"entries": fx, "affinities": affs,
		"skull": skull if Rules.truthy(skull) else 0,
		"salvage": card.get("salvage") if Rules.truthy(card.get("salvage")) else (raw.get("salvage") if Rules.truthy(raw.get("salvage")) else ""),
		"lootPool": card.get("lootPool") if Rules.truthy(card.get("lootPool")) else (raw.get("lootPool") if Rules.truthy(raw.get("lootPool")) else []),
		"setDrops": card.get("setDrops") if Rules.truthy(card.get("setDrops")) else (raw.get("setDrops") if Rules.truthy(raw.get("setDrops")) else [])}
	# 0.7 (Handbook 15.8): a Unit from a variable-cost card has X = 1 until it is paid for
	var vc := cost_of(card)
	if slot_x(vc["generic"]) > 0 or slot_x(vc["affinity"]) > 0:
		spec["x"] = 1
	return spec


# ---------------------------------------------------------------- cards in hand
## A card's effects, wherever it keeps them: a Forge card in _raw.abilities,
## a schema card in entries, a Master card in abilities.
static func entries_of(c) -> Array:
	if not (c is Dictionary):
		return []
	var raw: Dictionary = c.get("_raw") if c.get("_raw") is Dictionary else {}
	for list in [raw.get("abilities"), c.get("entries"), c.get("abilities")]:
		if list is Array:
			return list
	return []


## A card as it sits in a Deck or a hand. (the simulator's simHandCardOf)
static func hand_card(c: Dictionary) -> Dictionary:
	var raw: Dictionary = c.get("_raw") if c.get("_raw") is Dictionary else {}
	var fx := []
	for a in entries_of(c):
		fx.append({"name": a["name"] if Rules.truthy(a.get("name")) else "",
			"kind": a["kind"] if Rules.truthy(a.get("kind")) else (a["tag"] if Rules.truthy(a.get("tag")) else "Active"),
			"role": a["role"] if Rules.truthy(a.get("role")) else "", "text": a["text"] if Rules.truthy(a.get("text")) else "",
			"damage": a["damage"] if a.has("damage") else a.get("dmg"),
			"range": a["attackRange"] if a.has("attackRange") else a.get("rng"),
			"toHit": a["toHit"] if a.has("toHit") else a.get("hit"),
			"pen": a["armorPenetration"] if a.has("armorPenetration") else a.get("pen")})
	var affs = c.get("affinities")
	var first: Dictionary = affs[0] if (affs is Array and affs.size() > 0 and affs[0] is Dictionary) else {}
	return {"name": c.get("name"), "type": c.get("cardType"),
		"cost": cost_of(c),
		"district": first["district"] if Rules.truthy(first.get("district")) else null,
		"stats": raw["stats"] if Rules.truthy(raw.get("stats")) else (c["stats"] if Rules.truthy(c.get("stats")) else {}),
		"subtype": raw["subtype"] if Rules.truthy(raw.get("subtype")) else (c["subtype"] if Rules.truthy(c.get("subtype")) else ""),
		"behaviors": raw["behaviors"] if Rules.truthy(raw.get("behaviors")) else (c["behaviors"] if Rules.truthy(c.get("behaviors")) else []),
		"effects": fx, "_raw": c.get("_raw")}


## A sentence with no keywords in it is plain text: the game can't carry it out.
static func is_plain(text) -> bool:
	var t := str(text if text != null else "").strip_edges()
	if t == "":
		return false
	for p in Keywords.parse(t):
		if p["type"] == "kw":
			return false
	return true


## Whether any of a card's text is plain, and so won't happen when it's used.
static func has_plain_text(c) -> bool:
	if not (c is Dictionary):
		return false
	for a in entries_of(c):
		for sent in Keywords.sentences(str(a.get("text") if a.get("text") != null else "")):
			if is_plain(sent):
				return true
	return false


## The same, for text on its own (a Consumable's, a Chip's in the Bank).
static func text_has_plain(text) -> bool:
	for sent in Keywords.sentences(str(text if text != null else "")):
		if is_plain(sent):
			return true
	return false


# ---------------------------------------------------------------- variable costs
## Handbook 15.8, Variable Costs: a cost slot may hold X, XX or XXX. X is
## chosen as the card is played, at least 1; XX is that X paid twice.
## How many X a slot holds: 0 for a number. (simSlotX)
static func slot_x(v) -> int:
	var m := _re_slot_x.search(str(v if v != null else "").strip_edges())
	return m.get_string(0).length() if m != null else 0


## A card's Aether cost as it is printed, X and all. An older card kept only
## a flag that it had a variable cost, and a 0 where the X stood: its X is
## taken to be in the first slot that is empty, Generic before Affinity.
## (simCostOf)
static func cost_of(c: Dictionary) -> Dictionary:
	var a: Dictionary = c["aetherCost"] if c.get("aetherCost") is Dictionary else {}
	var raw: Dictionary = c["_raw"] if c.get("_raw") is Dictionary else {}
	var cost := {"generic": a["generic"] if a.get("generic") != null else 0, "affinity": a["affinity"] if a.get("affinity") != null else 0}
	# the Forge's own copy of a card still has the X where it was typed
	if slot_x(raw.get("aeGen")) > 0:
		cost["generic"] = raw["aeGen"]
	if slot_x(raw.get("aeAff")) > 0:
		cost["affinity"] = raw["aeAff"]
	for k in ["generic", "affinity"]:
		if slot_x(cost[k]) > 0:
			cost[k] = str(cost[k]).strip_edges().to_upper()
	if Rules.truthy(c.get("hasVariableCost")) and slot_x(cost["generic"]) == 0 and slot_x(cost["affinity"]) == 0 and slot_x(a.get("affinity2")) == 0:
		if not (Rules.num(cost["generic"], 0) > 0):
			cost["generic"] = "X"
		elif not (Rules.num(cost["affinity"], 0) > 0):
			cost["affinity"] = "X"
	return cost


## Whether a card (as it sits in a hand) has a variable cost. (simCardVar)
static func card_var(card) -> bool:
	if not (card is Dictionary) or not (card.get("cost") is Dictionary):
		return false
	return slot_x(card["cost"].get("generic")) > 0 or slot_x(card["cost"].get("affinity")) > 0


## What a card costs to play, as the rules read it: with X as given, else
## the X it is being played for, else 1. (simCardCost)
static func card_cost(card: Dictionary, x = null) -> Dictionary:
	var c: Dictionary = card["cost"] if card.get("cost") is Dictionary else {"generic": 0, "affinity": 0}
	var xv = Rules.num(card.get("x") if x == null else x, 1)
	var n: int = maxi(1, int(xv) if Rules.truthy(xv) else 1)
	var slot := func(v) -> int:
		var k := slot_x(v)
		if k > 0:
			return k * n
		var w = Rules.num(v, 0)
		return int(w) if Rules.truthy(w) else 0
	return {"generic": slot.call(c.get("generic")), "affinity": slot.call(c.get("affinity")), "district": card.get("district")}


## A card's cost in a few words: "2 D3 + 1◇", "X D3", "free". A variable slot
## reads X until x is given. (simCostLabel)
static func cost_label(card: Dictionary, x = null) -> String:
	if card.get("type") == "sphere":
		return "generates Aether"
	if card.get("type") == "consumable":
		return "no Aether cost"
	var c := card_cost(card, x)
	var raw: Dictionary = card["cost"] if card.get("cost") is Dictionary else {}
	var aff = str(raw.get("affinity")).strip_edges().to_upper() if (slot_x(raw.get("affinity")) > 0 and x == null) else c["affinity"]
	var gen = str(raw.get("generic")).strip_edges().to_upper() if (slot_x(raw.get("generic")) > 0 and x == null) else c["generic"]
	var parts := []
	if Rules.truthy(aff):
		parts.append(str(aff) + ((" D" + str(c["district"])) if Rules.truthy(c.get("district")) else ""))
	if Rules.truthy(gen):
		parts.append(str(gen) + "\u25c7")
	return " + ".join(parts) if not parts.is_empty() else "free"


## The least a card can cost: X counts 1, XX 2, XXX 3. For the Pouch's
## minimum. (aetherCostLeast)
static func cost_least(c: Dictionary) -> int:
	var a: Dictionary = (c["aetherCost"] if c.get("aetherCost") is Dictionary else {}).duplicate()
	a.merge(cost_of(c), true)
	var total := 0
	for k in ["generic", "affinity", "affinity2"]:
		var n := slot_x(a.get(k))
		if n > 0:
			total += n
		else:
			var w = Rules.num(a.get(k), 0)
			total += int(w) if Rules.truthy(w) else 0
	return total


## The name a saved reference points at: "master|Aether Bolt" is Aether Bolt.
static func ref_name(ref: String) -> String:
	var bits := ref.split("|")
	if bits.size() > 1:
		var rest := "|".join(bits.slice(1))
		if rest != "":
			return rest
	return ref


## An Aether Chip as the Bank holds it: a basic one ("basic|3": 1 Aether of
## District 3), or a Chip card worth what the rules say.
static func chip_of(key: String, card) -> Dictionary:
	if key.begins_with("basic|"):
		var d := key.split("|")[1]
		return {"name": "Basic Chip \u00b7 District " + d, "value": 1, "district": d, "text": "", "spent": false}
	var c: Dictionary = card if card is Dictionary else {}
	var affs = c.get("affinities")
	var first: Dictionary = affs[0] if (affs is Array and affs.size() > 0 and affs[0] is Dictionary) else {}
	var raw: Dictionary = c.get("_raw") if c.get("_raw") is Dictionary else {}
	var fx: Array = raw["abilities"] if raw.get("abilities") is Array else (c["entries"] if c.get("entries") is Array else [])
	return {"name": c["name"] if Rules.truthy(c.get("name")) else key, "value": Rules.chip_value(c),
		"district": first["district"] if Rules.truthy(first.get("district")) else null,
		"text": " ".join(fx.map(func(a): return a.get("text")).filter(func(t): return Rules.truthy(t))), "spent": false}


# ---------------------------------------------------------------- looks
## A card's token as {texture, hexagon}: the token drawn on the card, or the
## one its design wears; {} when it has none (the board then shows letters).
func token_for(card: Dictionary) -> Dictionary:
	var f := data.card_file(str(card.get("_artName", card.get("name", ""))), "token")
	if f.is_empty() and Rules.truthy(card.get("pixelToken")):
		f = data.picture_file(card["pixelToken"])
	if not f.is_empty():
		var l := _look(f)
		if not l.is_empty():
			return l
	# (0.14) the game's own drawing of a master Unit, or of a design's body plan
	var drawn := Art.token_drawn(card)
	if drawn == null and Rules.truthy(card.get("bodyPlan")):
		drawn = Art.body_token(str(card["bodyPlan"]))
	if drawn != null:
		return {"texture": drawn, "hexagon": false, "file": "", "drawn": true}
	return {}


## A card's art as a texture: the picture drawn for the card, or the one its
## design wears; failing that the game's own picture of it (0.17, a card that
## is not a Unit); failing that its token; null when it has none (a tile then
## shows letters).
func art_for(card: Dictionary) -> Texture2D:
	var f := data.card_file(str(card.get("_artName", card.get("name", ""))), "art")
	if f.is_empty() and Rules.truthy(card.get("pixelArt")):
		f = data.picture_file(card["pixelArt"])
	if not f.is_empty():
		var tex := data.texture(str(f.get("file", "")))
		if tex != null:
			return tex
	# (0.17) the game's own picture of a card that is not a Unit
	var drawn := Art.card_art(card)
	if drawn != null:
		return drawn
	return token_for(card).get("texture")


## Every card of some kinds, your own designs first and test cards last.
func of_types(types: Array) -> Array:
	return _ordered(cards.filter(func(c): return types.has(type_of(c))))


func _look(f: Dictionary) -> Dictionary:
	var tex := data.texture(str(f.get("file", "")))
	if tex == null:
		return {}
	var hx = f.get("hex")
	return {"texture": tex, "hexagon": f.get("grid") == "hex" and hx is Dictionary and hx.get("shape") == "hexagon", "file": f.get("file")}


## Every look an Enemy can spawn with: its own token, then its skins' tokens.
func enemy_looks(card: Dictionary) -> Array:
	var out := []
	var own := token_for(card)
	if not own.is_empty():
		out.append(own)
	for k in _skins:
		var o = k.get("owner", {})
		if o is Dictionary and o.get("kind") == "enemy" and str(o.get("key")) == str(card.get("name")):
			for v in k.get("variants", []):
				if Rules.truthy(v.get("token")):
					var f := data.picture_file(v["token"])
					if not f.is_empty():
						var l := _look(f)
						if not l.is_empty():
							out.append(l)
	return out


## Three letters for a Unit with no token ("Test" left off, as the simulator does).
static func letters(name: String) -> String:
	var s := Keywords._re("(?i)^Test\\s+").sub(name, "")
	s = Keywords._re("[^A-Za-z0-9]").sub(s, "", true)
	return s.left(3).to_upper() if s != "" else "?"


static var _re_slot_x := RegEx.create_from_string("(?i)^X{1,3}$")
