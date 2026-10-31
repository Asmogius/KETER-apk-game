## Builds every Lab card the Companion built (tests/fixtures/lab_cases.json,
## made by make_lab_cases.js from lab.js) and compares: the card, its points,
## its target, its cost and what the build breaks.
extends SceneTree

var ok := 0
var bad := 0


func _norm(v):
	if v is float and v == floor(v):
		return int(v)
	if v is Array:
		return v.map(func(x): return _norm(x))
	if v is Dictionary:
		var o := {}
		var ks: Array = v.keys()
		ks.sort()
		for k in ks:
			o[str(k)] = _norm(v[k])
		return o
	return v


func _initialize() -> void:
	var raw := FileAccess.get_file_as_string("res://tests/fixtures/lab_cases.json")
	var d = JSON.parse_string(raw)
	if not (d is Dictionary):
		print("LAB MATCH 0  DIFFER 1  (no lab_cases.json: run make_lab_cases.js)")
		quit(1)
		return
	if str(d.get("version")) != LabSystems.version():
		print("LAB MATCH 0  DIFFER 1  (the cases are for systems %s, the game reads %s)" % [d.get("version"), LabSystems.version()])
		quit(1)
		return
	var shown := 0
	for c in d["cases"]:
		var b: Dictionary = Rules.ints(c["build"])
		var got := LabSystems.compile(b)
		var want = _norm(c["result"])
		var have = _norm(got)
		if JSON.stringify(want) == JSON.stringify(have):
			ok += 1
		else:
			bad += 1
			if shown < 4:
				shown += 1
				print("DIFFER ", JSON.stringify(c["build"]), "\n  want ", JSON.stringify(want).substr(0, 600), "\n  got  ", JSON.stringify(have).substr(0, 600))
	print("LAB MATCH %d  DIFFER %d" % [ok, bad])
	quit(1 if bad > 0 else 0)
