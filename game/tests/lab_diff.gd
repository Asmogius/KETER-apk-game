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
	# the Lab card set, laid over the same cards as the Companion laid it
	if d.get("sets") is Array:
		LabSet.force(true)
		if str(d.get("setVersion")) != str(LabSet.data().get("version", "")):
			bad += 1
			print("DIFFER the cases lay set %s, the game reads %s" % [d.get("setVersion"), LabSet.data().get("version", "")])
		else:
			for sc in d["sets"]:
				var want = _norm(sc["output"])
				var have = _norm(LabSet.apply_cards(sc["input"]))
				if JSON.stringify(want) == JSON.stringify(have):
					ok += 1
				else:
					bad += 1
					var w: Array = want
					var h: Array = have
					print("DIFFER the set laid over %d cards: %d cards, the game %d" % [sc["input"].size(), w.size(), h.size()])
					for i in mini(w.size(), h.size()):
						if JSON.stringify(w[i]) != JSON.stringify(h[i]):
							print("  first at ", i, "\n  want ", JSON.stringify(w[i]).substr(0, 500), "\n  got  ", JSON.stringify(h[i]).substr(0, 500))
							break
		LabSet.reset()
	# the Forge's help: Convert's nearest build, a type's new build, what a build may hold
	var shown2 := 0
	for g in d.get("guesses", []):
		var b2 = LabSystems.guess(Rules.ints(g["card"]))
		var res = LabSystems.compile(Rules.ints(b2)) if b2 is Dictionary else null
		if JSON.stringify(_norm(g["build"])) == JSON.stringify(_norm(b2)) and JSON.stringify(_norm(g["result"])) == JSON.stringify(_norm(res)):
			ok += 1
		else:
			bad += 1
			if shown2 < 4:
				shown2 += 1
				print("DIFFER converting ", str(g["card"].get("name", "?")), "\n  want ", JSON.stringify(_norm(g["build"])), "\n  got  ", JSON.stringify(_norm(b2)))
	for g in d.get("defaults", []):
		var b3 = LabSystems.default_build(str(g["type"]), Rules.ints(g["prev"]) if g["prev"] is Dictionary else g["prev"])
		if JSON.stringify(_norm(g["build"])) == JSON.stringify(_norm(b3)):
			ok += 1
		else:
			bad += 1
			if shown2 < 8:
				shown2 += 1
				print("DIFFER a new ", g["type"], " after ", JSON.stringify(g["prev"]), "\n  want ", JSON.stringify(_norm(g["build"])), "\n  got  ", JSON.stringify(_norm(b3)))
	for g in d.get("caps", []):
		var c3 := LabSystems.caps(Rules.ints(g["build"]))
		if JSON.stringify(_norm(g["caps"])) == JSON.stringify(_norm(c3)):
			ok += 1
		else:
			bad += 1
			if shown2 < 12:
				shown2 += 1
				print("DIFFER caps of ", JSON.stringify(g["build"]), "\n  want ", JSON.stringify(_norm(g["caps"])), "\n  got  ", JSON.stringify(_norm(c3)))
	# the Workshop's modules
	for g in d.get("modules", []):
		var ch = Rules.ints(g["ch"]) if g["ch"] is Dictionary else null
		var dd: Dictionary = Rules.ints(g["d"])
		var kw: Dictionary = Rules.ints(g["kw"])
		var mods: Dictionary = Rules.ints(g["mods"])
		var mid := str(g["mid"])
		var have := {"line": LabSystems.chassis_line(ch), "build": LabSystems.design_build(dd, ch), "points": LabSystems.design_points(dd), "check": LabSystems.design_check(dd, ch, kw, mods),
			"cost": LabSystems.design_cost(dd, ch), "card": LabSystems.design_card(dd, ch), "guess": LabSystems.design_guess(Rules.ints(g["legacy"]), ch), "level": LabSystems.module_level(mid, kw, mods),
			"open": [1, 2, 3].map(func(t): return LabSystems.module_open(mid, t, kw, mods)),
			"free": [LabSystems.is_free_module("A1", 1), LabSystems.is_free_module("A1", 2), LabSystems.is_free_module("S1", 0), LabSystems.is_free_module(mid, 1)],
			"research": LabSystems.module_research(mid, kw, mods, g["sh"], Rules.ints(g["pr"]))}
		var want = _norm(g["out"])
		var got = _norm(have)
		if JSON.stringify(want) == JSON.stringify(got):
			ok += 1
		else:
			bad += 1
			if shown2 < 16:
				shown2 += 1
				for k in (want as Dictionary):
					if JSON.stringify(want[k]) != JSON.stringify(got.get(k)):
						print("DIFFER a Workshop design's ", k, "\n  want ", JSON.stringify(want[k]).substr(0, 400), "\n  got  ", JSON.stringify(got.get(k)).substr(0, 400))
						break
	print("LAB MATCH %d  DIFFER %d" % [ok, bad])
	quit(1 if bad > 0 else 0)
