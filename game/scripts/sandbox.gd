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
	return {"v": 1, "cards": {}, "made": 0}


static func load_saved() -> void:
	data = blank()
	error = ""
	if not FileAccess.file_exists(path):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if d is Dictionary and d.get("cards") is Dictionary:
		data = Rules.ints(d)
		data["made"] = int(d.get("made", 0))
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
## Every card as it now stands, as a Compendium file the Companion's Card Forge imports.
static func compendium(all_cards: Array, version := 0) -> Dictionary:
	return {"schema": SCHEMA, "version": str(version), "made": "KETER, the game's Sandbox",
		"cards": all_cards.filter(func(c): return c is Dictionary and str(c.get("_src", "")) != "workshop" and str(c.get("_src", "")) != "design" and str(c.get("_src", "")) != "prebuilt").map(func(c): return stripped(c))}


## Writes it where the Companion can pick it up: the phone's Downloads when the
## game may write there, else beside its saves. Returns the file, or "".
static func export_to(all_cards: Array, where := "") -> String:
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
	f.store_string(JSON.stringify(compendium(all_cards), " "))
	f.close()
	return file
