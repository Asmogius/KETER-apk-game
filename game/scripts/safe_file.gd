## (0.32) Saving without losing what was saved: the new file is written beside
## the old one and only then put in its place, and the one it replaces is kept
## as <file>.bak. A phone that dies, or an app closed, part-way through a save
## leaves the last good one, never half a file; and a file that can't be read
## is read from its .bak instead.
class_name SafeFile
extends RefCounted


## Writes text to path. Returns false if it couldn't be written (what was there is untouched).
static func write(path: String, text: String) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.flush()
	var ok := f.get_error() == OK
	f.close()
	if not ok:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
		return false
	var real := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		var bak := real + ".bak"
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(bak)
		DirAccess.rename_absolute(real, bak)
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), real) == OK


## The JSON kept at path: the file's, or failing that its .bak's; null if neither reads.
## (used: which one it was, "file" or "bak", for saying so.)
static func read_json(path: String, used: Array = []) -> Variant:
	for p in [path, path + ".bak"]:
		if not FileAccess.file_exists(p):
			continue
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(p)) == OK and json.data != null:
			used.clear()
			used.append("file" if p == path else "bak")
			return json.data
	return null


## Whether anything is kept at path (the file or its .bak).
static func exists(path: String) -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak")


## Removes the file and its .bak.
static func remove(path: String) -> void:
	for p in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
