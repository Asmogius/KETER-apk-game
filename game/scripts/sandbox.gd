## The Sandbox (0.26): what you make and change in the game's own tools, kept
## on the phone over the export the game plays. The export stays as it came;
## this holds, by each card's key, a card of yours, a card of the export's as
## you changed it, or the word that you deleted it. KeterExport.cards() lays it
## over the export's, so every part of the game (the Roster, the dock, the
## World Map, a fight) sees your cards as they now stand. Reset takes a card
## of the export's back to how it came.
##
## Export writes all of it as a Compendium file (keter.compendium/1), the
## shape the Companion's Card Forge imports, so what you make here can go back
## into the Companion.
##
## A card's key is where it came from and its name as it came ("master|Rictus");
## a card made here is "sandbox|<its id>", and keeps that key when renamed.
##
## (0.28) Chassis too, under "chassis", by their ids: {"item": {...}, "own": true
## for one made here} or {"deleted": true}. KeterExport.content("chassis")
## lays them over the export's, so the Workshop, the drops and the Exchange
## have them.
##
## (0.29) Floors too, under "floors", by the name they came with (one made here:
## "fl_sb<...>"), in the same shapes; content("floors") lays them over the
## export's, so the floor list, the World Map and the chunks have them.
class_name Sandbox
extends RefCounted

const FILE := "user://sandbox.json"
const SCHEMA := "keter.compendium/1"
static var path := FILE
## {v, cards: {key: {"card": {...}} | {"deleted": true}}, made}. Empty until load(): the
## game's tests that compare with the Companion never see what a player has made.
static var data := blank()
static var error := ""


static func blank() -> Dictionary:
	return {"v": 2, "cards": {}, "chassis": {}, "floors": {}, "made": 0}


static func load_saved() -> void:
	data = blank()
	error = ""
	if not FileAccess.file_exists(path):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if d is Dictionary and d.get("cards") is Dictionary:
		data = Rules.ints(d)
		data["made"] = int(d.get("made", 0))
		for k in ["chassis", "floors"]:
			if not (data.get(k) is Dictionary):
				data[k] = {}
	else:
		error = "Your Sandbox couldn't be read, so it starts empty."


static func save() -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		error = "The Sandbox couldn't be saved."
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	error = ""
	return true


## Forgets everything made and changed here.
static func clear() -> void:
	data = blank()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# ---------------------------------------------------------------- cards
## Where a card came from, and its name as it came.
static func key_of(c: Dictionary) -> String:
	if c.has("_key"):
		return str(c["_key"])
	return "%s|%s" % [str(c.get("_src", "master")) if Rules.truthy(c.get("_src")) else "master", str(c.get("name", ""))]


static func is_own(key: String) -> bool:
	return key.begins_with("sandbox|")


## The export's cards as they now stand: yours in place of theirs, the deleted
## left out, the ones made here after them. One of yours carries its key, and
## _sandbox: "edited" or "made"; the rest are the export's own, untouched.
static func apply(export_cards: Array) -> Array:
	var cs: Dictionary = data.get("cards", {})
	if cs.is_empty():
		return export_cards
	var out := []
	for c in export_cards:
		if not (c is Dictionary):
			continue
		var k := key_of(c)
		var o = cs.get(k)
		if o is Dictionary and Rules.truthy(o.get("deleted")):
			continue
		if o is Dictionary and o.get("card") is Dictionary:
			var e: Dictionary = o["card"].duplicate(true)
			e["_src"] = c.get("_src", "master")
			e["_key"] = k
			e["_sandbox"] = "edited"
			e["_artName"] = str(c.get("name", ""))     # its pictures stay its own when it is renamed
			out.append(e)
		else:
			out.append(c)
	for k in cs:
		if is_own(str(k)) and cs[k] is Dictionary and cs[k].get("card") is Dictionary:
			var e: Dictionary = cs[k]["card"].duplicate(true)
			e["_src"] = "sandbox"
			e["_key"] = str(k)
			e["_sandbox"] = "made"
			out.append(e)
	return out


## A card as it is kept: without what the game adds to it when it reads it.
static func stripped(c: Dictionary) -> Dictionary:
	var o := {}
	for k in c:
		if not str(k).begins_with("_"):
			o[k] = c[k]
	return o


## Keeps a card: the one under this key (one of the export's, or one of yours),
## or a new one when key is "". Returns its key.
static func put(card: Dictionary, key := "") -> String:
	if key == "":
		data["made"] = int(data.get("made", 0)) + 1
		key = "sandbox|sb%d_%d" % [int(Time.get_unix_time_from_system()), int(data["made"])]
	data["cards"][key] = {"card": stripped(card)}
	return key


## Deletes a card: one of yours is gone; one of the export's is left out until Reset.
static func delete(key: String) -> void:
	if is_own(key):
		data["cards"].erase(key)
	else:
		data["cards"][key] = {"deleted": true}


## A card of the export's back as it came (one of yours has nothing to go back to).
static func reset(key: String) -> void:
	if not is_own(key):
		data["cards"].erase(key)


static func changed(key: String) -> bool:
	return data["cards"].has(key)


static func deleted_keys() -> Array:
	return data["cards"].keys().filter(func(k): return data["cards"][k] is Dictionary and Rules.truthy(data["cards"][k].get("deleted")))


static func counts() -> Dictionary:
	var made := 0
	var edited := 0
	var gone := 0
	for k in data["cards"]:
		var o = data["cards"][k]
		if is_own(str(k)):
			made += 1
		elif o is Dictionary and Rules.truthy(o.get("deleted")):
			gone += 1
		else:
			edited += 1
	return {"made": made, "edited": edited, "deleted": gone}


# ---------------------------------------------------------------- back to the Companion
## Every card as it now stands, as a Compendium file the Companion's Card Forge
## imports; (0.28) with every chassis as it stands, which the Companion's
## import installs in its Chassis library.
static func compendium(all_cards: Array, version := 0, all_chassis: Array = [], all_floors: Array = []) -> Dictionary:
	return {"schema": SCHEMA, "version": str(version), "made": "KETER, the game's Sandbox", "chassis": all_chassis.map(func(c): return stripped(c)),
		"floors": all_floors.map(func(f): return stripped(f)),
		"cards": all_cards.filter(func(c): return c is Dictionary and str(c.get("_src", "")) != "workshop" and str(c.get("_src", "")) != "design" and str(c.get("_src", "")) != "prebuilt").map(func(c): return stripped(c))}


## Writes it where the Companion can pick it up: the phone's Downloads when the
## game may write there, else beside its saves. Returns the file, or "".
static func export_to(all_cards: Array, where := "", all_chassis: Array = [], all_floors: Array = []) -> String:
	var dir := where
	if dir == "":
		dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS) if OS.has_feature("android") else ProjectSettings.globalize_path("user://")
	var file := dir.path_join("KETER_sandbox_%s.json" % Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_"))
	var f := FileAccess.open(file, FileAccess.WRITE)
	if f == null:
		file = ProjectSettings.globalize_path("user://").path_join(file.get_file())
		f = FileAccess.open(file, FileAccess.WRITE)
		if f == null:
			return ""
	f.store_string(JSON.stringify(compendium(all_cards, 0, all_chassis, all_floors), " "))
	f.close()
	return file


# ---------------------------------------------------------------- (0.28) chassis
## The export's chassis as they now stand: yours in place of theirs, the deleted
## left out, the ones made here after them. One of yours carries _sandbox:
## "edited" or "made"; the rest are the export's own, untouched.
static func apply_chassis(export_chassis: Array) -> Array:
	var cs: Dictionary = data.get("chassis", {})
	if cs.is_empty():
		return export_chassis
	var out := []
	var had := {}
	for c in export_chassis:
		if not (c is Dictionary):
			continue
		var id := str(c.get("id", ""))
		had[id] = true
		var o = cs.get(id)
		if o is Dictionary and Rules.truthy(o.get("deleted")):
			continue
		if o is Dictionary and o.get("item") is Dictionary:
			var e: Dictionary = o["item"].duplicate(true)
			e["id"] = id
			e["_sandbox"] = "edited"
			out.append(e)
		else:
			out.append(c)
	for id in cs:
		var o = cs[id]
		if not had.has(str(id)) and o is Dictionary and o.get("item") is Dictionary:
			var e: Dictionary = o["item"].duplicate(true)
			e["id"] = str(id)
			e["_sandbox"] = "made"
			out.append(e)
	return out


## Keeps a chassis: the export's or yours under its id, or a new one (id ""). Returns its id.
static func put_chassis(ch: Dictionary, id := "") -> String:
	var own := id == "" or chassis_own(id)
	if id == "":
		data["made"] = int(data.get("made", 0)) + 1
		id = "ch_sb%d_%d" % [int(Time.get_unix_time_from_system()), int(data["made"])]
	var item := stripped(ch)
	item["id"] = id
	data["chassis"][id] = {"item": item, "own": own}
	return id


static func chassis_own(id: String) -> bool:
	var o = data.get("chassis", {}).get(id)
	return o is Dictionary and Rules.truthy(o.get("own"))


static func chassis_changed(id: String) -> bool:
	return data.get("chassis", {}).has(id)


## Deletes a chassis: one of yours is gone; one of the export's is left out until Reset.
static func delete_chassis(id: String) -> void:
	if chassis_own(id):
		data["chassis"].erase(id)
	else:
		data["chassis"][id] = {"deleted": true}


static func reset_chassis(id: String) -> void:
	if not chassis_own(id):
		data["chassis"].erase(id)


static func deleted_chassis() -> Array:
	return data.get("chassis", {}).keys().filter(func(k): return data["chassis"][k] is Dictionary and Rules.truthy(data["chassis"][k].get("deleted")))


# ---------------------------------------------------------------- (0.29) floors
## A floor's key: the name it came with ("_key" once the Sandbox has had it).
static func floor_key(f: Dictionary) -> String:
	return str(f["_key"]) if f.has("_key") else str(f.get("name", ""))


## The export's floors as they now stand: yours in place of theirs, the deleted
## left out, the ones made here after them. One of yours carries its _key and
## _sandbox: "edited" or "made"; the rest are the export's own, untouched.
static func apply_floors(export_floors: Array) -> Array:
	var fs: Dictionary = data.get("floors", {})
	if fs.is_empty():
		return export_floors
	var out := []
	var had := {}
	for f in export_floors:
		if not (f is Dictionary):
			continue
		var k := floor_key(f)
		had[k] = true
		var o = fs.get(k)
		if o is Dictionary and Rules.truthy(o.get("deleted")):
			continue
		if o is Dictionary and o.get("item") is Dictionary:
			var e: Dictionary = o["item"].duplicate(true)
			e["_key"] = k
			e["_sandbox"] = "edited"
			out.append(e)
		else:
			out.append(f)
	for k in fs:
		var o = fs[k]
		if not had.has(str(k)) and o is Dictionary and o.get("item") is Dictionary:
			var e: Dictionary = o["item"].duplicate(true)
			e["_key"] = str(k)
			e["_sandbox"] = "made"
			out.append(e)
	return out


## Keeps a floor: the export's or yours under its key, or a new one (key ""). Returns its key.
static func put_floor(lv: Dictionary, key := "") -> String:
	var own := key == "" or floor_own(key)
	if key == "":
		data["made"] = int(data.get("made", 0)) + 1
		key = "fl_sb%d_%d" % [int(Time.get_unix_time_from_system()), int(data["made"])]
	data["floors"][key] = {"item": stripped(lv), "own": own}
	return key


static func floor_own(key: String) -> bool:
	var o = data.get("floors", {}).get(key)
	return o is Dictionary and Rules.truthy(o.get("own"))


static func floor_changed(key: String) -> bool:
	return data.get("floors", {}).has(key)


## Deletes a floor: one of yours is gone; one of the export's is left out until Reset.
static func delete_floor(key: String) -> void:
	if floor_own(key):
		data["floors"].erase(key)
	else:
		data["floors"][key] = {"deleted": true}


static func reset_floor(key: String) -> void:
	if not floor_own(key):
		data["floors"].erase(key)


static func deleted_floors() -> Array:
	return data.get("floors", {}).keys().filter(func(k): return data["floors"][k] is Dictionary and Rules.truthy(data["floors"][k].get("deleted")))


## (0.29) Everything the game has as it now stands (cards, chassis and floors),
## written for the Companion. Returns the file, or "".
static func export_game(r: Roster, where := "") -> String:
	if r == null or r.data == null:
		return ""
	var chs = r.data.content("chassis").get("chassis", [])
	var fls = r.data.content("floors").get("floors", [])
	return export_to(r.cards, where, chs if chs is Array else [], fls if fls is Array else [])
