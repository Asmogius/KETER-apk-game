## The Companion's Export for Godot, read straight from its zip.
##
## Drop KETER_export_<date>.zip into the game's folder (the project folder, res://)
## and the game finds the newest one. Nothing needs unzipping.
##
## Inside: manifest.json (what every file is), content/<kind>.json (cards,
## floors, world_map, chassis, pools, tables, skins; each with its format), and
## a PNG per drawn graphic in skins/, cards/, map/ and custom/.
class_name KeterExport
extends RefCounted

## The content format this game reads. A newer export says so.
const FORMAT := 1
## Where to look, in order.
const PLACES := ["res://", "res://exports/", "user://"]
## (0.19) The export built into the Android app: the oldest by its name, so an
## export of yours in Downloads is always newer.
const BUILT_IN := "KETER_export_0000_built_in.zip"


## (0.19) Where to look on this device: the usual places, and on Android your
## Downloads too (where the Companion's Export for Godot lands), once the game
## may read them.
static func places() -> Array:
	var out := PLACES.duplicate()
	if OS.has_feature("android"):
		var dl := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
		if dl != "" and android_can_read():
			out.append(dl)
	return out


## (0.19) Whether the Android app may read your Downloads (All files access).
static func android_can_read() -> bool:
	if not OS.has_feature("android"):
		return false
	return OS.get_granted_permissions().has("android.permission.MANAGE_EXTERNAL_STORAGE")

var path := ""
var manifest := {}
var error := ""
var _zip: ZIPReader = null
var _content := {}
var _textures := {}
var _names := {}              # every file in the zip, so a missing one is asked for quietly
var _pictures := {}           # picture id -> manifest entry


## The newest export in the usual places, or "" if there is none.
static func find_newest(where: Array = []) -> String:
	var found: Array[String] = []
	for place in (where if not where.is_empty() else places()):
		if not DirAccess.dir_exists_absolute(place):
			continue
		var dir := DirAccess.open(place)
		if dir == null:
			continue
		for f in dir.get_files():
			var n := f.to_lower()
			if n.ends_with(".zip") and (n.begins_with("keter_export_") or n.begins_with("keter_assets_")):
				found.append(place.path_join(f) if not place.ends_with("/") else place + f)
	if found.is_empty():
		return ""
	# the date is in the name; newest last. Ties go to the later place.
	found.sort_custom(func(a, b): return a.get_file().substr(13) < b.get_file().substr(13))
	return found[found.size() - 1]


## Opens an export. Returns false (and sets error) if it can't be read.
func open(p: String) -> bool:
	close()
	path = p
	_zip = ZIPReader.new()
	if _zip.open(p) != OK:
		error = "Couldn't open " + p.get_file() + " as a zip."
		_zip = null
		return false
	_names = {}
	for n in _zip.get_files():
		_names[n] = true
	var raw := _zip.read_file("manifest.json") if _names.has("manifest.json") else PackedByteArray()
	if raw.is_empty():
		error = p.get_file() + " has no manifest.json. Is it an Export for Godot from the Companion?"
		return false
	var m = JSON.parse_string(raw.get_string_from_utf8())
	if not (m is Dictionary):
		error = "Its manifest.json couldn't be read."
		return false
	manifest = m
	if int(manifest.get("format", 1)) > FORMAT:
		error = "This export is newer than this game can read (format %d). Update the game." % int(manifest.get("format", 1))
		return false
	error = ""
	return true


func close() -> void:
	if _zip != null:
		_zip.close()
	_zip = null
	_content = {}
	_textures = {}
	_names = {}
	_pictures = {}


func is_open() -> bool:
	return _zip != null and error == ""


## One kind of content (cards, floors, world_map, chassis, pools, tables, skins), or {}.
func content(kind: String) -> Dictionary:
	# (0.28) the Sandbox's chassis laid over the export's
	if kind == "chassis" and not Sandbox.data.get("chassis", {}).is_empty():
		var raw := _raw_content(kind)
		var o := raw.duplicate()
		o["chassis"] = Sandbox.apply_chassis(raw.get("chassis", []) if raw.get("chassis") is Array else [])
		return o
	return _raw_content(kind)


## One kind of content, as the export has it.
func _raw_content(kind: String) -> Dictionary:
	if _content.has(kind):
		return _content[kind]
	var out := {}
	if _zip != null and _names.has("content/" + kind + ".json"):
		var raw := _zip.read_file("content/" + kind + ".json")
		if not raw.is_empty():
			var d = JSON.parse_string(raw.get_string_from_utf8())
			if d is Dictionary:
				out = d
	_content[kind] = out
	return out


func floors() -> Array[FloorData]:
	var out: Array[FloorData] = []
	for f in content("floors").get("floors", []):
		if f is Dictionary:
			out.append(FloorData.from_dict(f))
	return out


## The export's cards, with the Sandbox's laid over them (0.26): yours made
## and changed there, those deleted there left out.
func cards() -> Array:
	return Sandbox.apply(content("cards").get("cards", []))


## The export's own cards, as they came.
func own_cards() -> Array:
	return content("cards").get("cards", [])


## What the manifest says about each file.
func files() -> Array:
	return manifest.get("files", [])


## A PNG from the export as a texture (cached), or null.
func texture(file: String) -> Texture2D:
	if _textures.has(file):
		return _textures[file]
	var tex: Texture2D = null
	if _zip != null and _names.has(file):
		var bytes := _zip.read_file(file)
		if not bytes.is_empty():
			var img := Image.new()
			if img.load_png_from_buffer(bytes) == OK:
				tex = ImageTexture.create_from_image(img)
	_textures[file] = tex
	return tex


## The manifest entry for a card's art or token.
func card_file(card_name: String, what: String) -> Dictionary:
	for f in files():
		var o = f.get("owner", {})
		if f.get("group") == "cards" and f.get("what") == what and o is Dictionary and o.get("card") == card_name:
			return f
	return {}


## The manifest entry for a picture, by the Pixel Studio's id for it.
func picture_file(picture_id) -> Dictionary:
	if picture_id == null or str(picture_id) == "":
		return {}
	if _pictures.is_empty():
		for f in files():
			if f is Dictionary and f.get("picture") != null:
				_pictures[str(f["picture"])] = f
	return _pictures.get(str(picture_id), {})


## A picture drawn in the Pixel Studio, as a texture, or null.
func picture_texture(picture_id) -> Texture2D:
	var f := picture_file(picture_id)
	return texture(f["file"]) if not f.is_empty() else null


## A Hero to show: the first Hero card that has a token drawn, as
## {name, file, texture}; failing that, a body plan's stand-in skin token.
func hero_token() -> Dictionary:
	for c in cards():
		if c is Dictionary and str(c.get("cardType", "")).to_lower() == "hero":
			var f := card_file(str(c.get("name", "")), "token")
			if not f.is_empty():
				return {"name": c["name"], "file": f["file"], "texture": texture(f["file"])}
	for f in files():
		if f.get("group") == "skins" and f.get("what") == "token":
			return {"name": str(f.get("name", "Token")), "file": f["file"], "texture": texture(f["file"])}
	return {}
