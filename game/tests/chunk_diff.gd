## Grows every battlefield the Companion grew (tests/fixtures/chunk_cases.json,
## made by make_chunk_cases.js from chunkgen.js) and compares, field by field.
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
	var raw := FileAccess.get_file_as_string("res://tests/fixtures/chunk_cases.json")
	var d = JSON.parse_string(raw)
	if not (d is Dictionary):
		print("CHUNK MATCH 0  DIFFER 1  (no chunk_cases.json: run make_chunk_cases.js)")
		quit(1)
		return
	var shown := 0
	for c in d["cases"]:
		var chunks: Array = d["sets"][c["set"]]
		var got: Dictionary
		if c.has("key"):
			got = ChunkGen.from_key(chunks, c["key"])
		else:
			var a: Array = c["args"]
			got = ChunkGen.generate(chunks, str(a[0]), int(a[1]), str(a[2]), int(a[3]))
		var want = _norm(c["result"]) if c["result"] != null else null
		var have = _norm(got) if not got.is_empty() else null
		if JSON.stringify(want) == JSON.stringify(have):
			ok += 1
		else:
			bad += 1
			if shown < 3:
				shown += 1
				print("DIFFER ", c.get("key", c.get("args")), "\n  want ", JSON.stringify(want).substr(0, 300), "\n  got  ", JSON.stringify(have).substr(0, 300))
	print("CHUNK MATCH %d  DIFFER %d" % [ok, bad])
	quit(1 if bad > 0 else 0)
