## The proof that the game's Workshop is the Companion's: cases made by
## running scoring.js, chassis.js, workshop.js, progress.js, skins.js and
## builder.js as they are (make_workshop_cases.js, in the Companion's sources)
## on the export's own chassis, cards and skins, each replayed here and
## compared: what text is worth, which blueprint levels a design needs,
## research, a design's power, its fit check, what a copy costs, the card it
## makes, the look it wears; and the keyword builder walked tap by tap, with
## what it offers, how the sentence reads and what is wrong with it compared
## after every tap.
##   godot --headless --path . --script res://tests/workshop_diff.gd
extends SceneTree

const CASES := "res://tests/fixtures/workshop_cases.json"
const EXPORT := "res://tests/fixtures/export.zip"
var by_fn := {}
var shown := {}
var x: KeterExport
var table_sets: Array = []
var pictures := {}
var taps := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(CASES))
	if not (data is Dictionary):
		print("FAIL no cases at " + CASES)
		print("\nWORKSHOP MATCH 0  DIFFER 1")
		quit(1)
		return
	data = Rules.ints(data)
	x = KeterExport.new()
	x.open(EXPORT)
	for c in Rules.ints(x.cards()):
		Keywords.register_archetypes(c.get("archetypes"))
	table_sets = data.get("tables", [])
	for p in data.get("pictures", []):
		pictures[str(p)] = true
	for c in data["cases"]:
		_case(c)
	var ok := 0
	var bad := 0
	var names := by_fn.keys()
	names.sort()
	for fn in names:
		ok += by_fn[fn][0]
		bad += by_fn[fn][1]
		print(("PASS " if by_fn[fn][1] == 0 else "FAIL ") + "%s: %d of %d match" % [fn, by_fn[fn][0], by_fn[fn][0] + by_fn[fn][1]])
	print("(from %s; %d chassis; %d taps in the builder)" % [data.get("made", "?"), data.get("chassis", 0), taps])
	print("\nWORKSHOP MATCH %d  DIFFER %d" % [ok, bad])
	quit(1 if bad > 0 else 0)


func _tally(fn: String, good: bool, got, want) -> void:
	if not by_fn.has(fn):
		by_fn[fn] = [0, 0]
	by_fn[fn][0 if good else 1] += 1
	if not good and shown.get(fn, 0) < 3:
		shown[fn] = shown.get(fn, 0) + 1
		print("DIFF %s\n   game: %s\n   comp: %s" % [fn, JSON.stringify(got).left(700), JSON.stringify(want).left(700)])
		var at := []
		_where(got, want, "", at)
		for w in at.slice(0, 6):
			print("   differs at " + w)


## Missing and null alike; numbers within a hair.
func same(a, b) -> bool:
	if a == null or b == null:
		return a == null and b == null
	if (a is int or a is float) and (b is int or b is float):
		return absf(float(a) - float(b)) < 1e-6
	if a is bool or b is bool:
		return a is bool and b is bool and a == b
	if (a is String or a is StringName) and (b is String or b is StringName):
		return str(a) == str(b)
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for i in a.size():
			if not same(a[i], b[i]):
				return false
		return true
	if a is Dictionary and b is Dictionary:
		var keys := {}
		for k in a: keys[k] = true
		for k in b: keys[k] = true
		for k in keys:
			if not same(a.get(k), b.get(k)):
				return false
		return true
	return false


func _where(a, b, path: String, out: Array) -> void:
	if out.size() >= 6 or same(a, b):
		return
	if a is Array and b is Array and a.size() == b.size():
		for i in a.size():
			_where(a[i], b[i], path + "[" + str(i) + "]", out)
		return
	if a is Dictionary and b is Dictionary:
		var keys := {}
		for k in a: keys[k] = true
		for k in b: keys[k] = true
		for k in keys:
			_where(a.get(k), b.get(k), path + "." + str(k), out)
		return
	out.append("%s: game %s, comp %s" % [path, JSON.stringify(a).left(200), JSON.stringify(b).left(200)])


# ---------------------------------------------------------------- what a case needs
## The progress of a case: what is owned, with one set of the Workshop's tables.
func _progress(state, tables = null) -> Progress:
	var p := Progress.new(Loot.new(null, 1), x.content("pools"), x.content("chassis"), {"workshop": tables} if tables is Dictionary else (x.content("tables") if tables == null else {}))
	p.state = Progress.tidy(state.duplicate(true) if state is Dictionary else null)
	return p


func _skins(p: Progress, list = null) -> Skins:
	return Skins.new(list if list != null else x.content("skins"), p.chassis, func(id): return pictures.has(str(id)))


## A Workshop over one of the generator's sets of tables (-1: the export's own).
func _workshop(state, ti: int, skin_list = null) -> Workshop:
	var t = table_sets[ti] if ti >= 0 else x.content("tables").get("workshop")
	var p := _progress(state, t if t is Dictionary else false)
	return Workshop.new(p, {"workshop": t} if t is Dictionary else {}, _skins(p, skin_list))


func _snap(b: Builder) -> Dictionary:
	var v := b.view()
	var body := []
	for it in v["body"]:
		match it["t"]:
			"note": body.append({"t": "note", "text": World.hash_str(it["text"])})
			"check": body.append({"t": "check", "text": it["text"], "on": it["on"]})
			"group": body.append({"t": "group", "text": it["text"]})
			"opt": body.append({"t": "opt", "key": it["key"], "label": it["label"], "desc": World.hash_str(it["desc"]), "on": it["on"], "colour": it["colour"]})
			"drop": body.append({"t": "drop", "i": it["i"], "label": it["label"], "colour": it["colour"]})
			"chip": body.append({"t": "chip", "key": it["key"], "label": it["label"], "colour": it["colour"]})
			"num": body.append({"t": "num", "value": it["value"]})
			"select": body.append({"t": "select", "options": it["options"], "value": it["value"]})
			"button": body.append({"t": "button", "key": it["key"], "label": it["label"], "primary": it["primary"]})
			"row": body.append({"t": "row", "label": it["label"], "shown": it["shown"], "dim": it["dim"], "step": it["step"]})
			"bad": body.append({"t": "bad", "lines": it["lines"]})
	return {"head": v["head"], "sentence": Builder.shown(v["sentence"]), "power": b.power_texts(v["sentence"]), "step": v["step"], "title": v["title"], "body": body,
		"back": v["back"], "skip": v["skip"], "next": v["next"]["enabled"] if v["next"]["shown"] else null,
		"insert": {"enabled": v["insert"]["enabled"], "label": v["insert"]["label"]} if v["insert"]["shown"] else null}


func _builder(c: Dictionary) -> void:
	var o: Dictionary = c["args"][0].duplicate(true)
	var ops: Array = c["args"][1]
	var want: Array = c["result"]
	var b := Builder.new()
	b.begin(o)
	var got := [{"snap": _snap(b)}]
	for op in ops:
		taps += 1
		match op[0]:
			"kb":
				var k := str(op[1])
				if k == "x": b.close()
				elif k == "back": b.back()
				elif k == "skip": b.skip()
				elif k == "next": b.next()
				elif k == "insert": b.insert()
				elif k.begins_with("pv:"): b.param_pick(k.substr(3))
				else: b.pick(k)
			"step": b.step(int(op[1]))
			"drop": b.drop(int(op[1]))
			"edit": b.edit(str(op[1]))
			"card": b.set_card(str(op[1]))
			"adj": b.set_adjacent(Rules.truthy(op[1]))
		if b.open:
			got.append({"snap": _snap(b)})
		else:
			got.append({"done": null if b.cancelled else b.result, "cancelled": b.cancelled})
	b.release()           # (a number left being asked for would keep it, and its function, for good)
	# the first place they part is the one worth reading
	var good := same(got, want)
	if not good and shown.get("builder", 0) < 3:
		for i in mini(got.size(), want.size()):
			if not same(got[i], want[i]):
				print("   (after %s, tap %d of %d: %s)" % [JSON.stringify(o).left(260), i, ops.size(), JSON.stringify(ops.slice(maxi(0, i - 4), i))])
				_tally("builder", false, got[i], want[i])
				return
	_tally("builder", good, got.size(), want.size())


func _case(c: Dictionary) -> void:
	var a: Array = c["args"]
	var want = c["result"]
	match c["fn"]:
		"builder":
			_builder(c)
		"fromSentence":
			var s := Builder.from_sentence(str(a[0]))
			_tally("fromSentence", same({"when": s["when"], "check": s["check"], "target": s["target"], "effects": s["effects"], "mods": s["mods"], "dur": s["dur"], "adjacent": Rules.truthy(s["adjacent"]), "ownWords": s["ownWords"], "built": Builder.build(s)}, want), s, want)
		"score":
			var d = Scoring.keyword_detail(a[0], a[1])
			_tally("score", same(d, want), d, want)
		"abilityPower":
			var n := Scoring.ability_power(a[0])
			_tally("abilityPower", same(n, want), n, want)
		"catalog":
			var cat := _progress({}).catalog()
			_tally("catalog", same(cat, want), cat, want)
		"levelFor":
			var lv := _progress({}).level_for(a[0], a[1])
			_tally("levelFor", same(lv, want), lv, want)
		"needs":
			var p := _progress(a[0])
			var got := {"needs": p.needs(a[1]), "missing": p.missing(a[1])}
			_tally("needs", same(got, want), got, want)
		"researchPrice":
			var price := _progress({}).research_price(a[0], int(a[1]))
			_tally("researchPrice", same(price, want), price, want)
		"research":
			var p2 := _progress(a[0])
			var stock := Loot.bag()
			stock["shards"] = int(a[1])
			var outs := []
			for nm in a[2]:
				outs.append(p2.research(nm, stock, false))
			var got2 := {"got": outs, "bp": p2.state["bp"], "shards": stock["shards"]}
			_tally("research", same(got2, want), got2, want)
		"owned":
			var p3 := _progress(a[0])
			var got3 := {"owned": p3.owned(a[1]), "has": p3.has_chassis(a[2]), "knownBp": p3.known_bp(a[1]), "knownCh": p3.known_ch(a[2]),
				"bpItem": p3.eligible("bp:%s:1" % a[1], []), "chItem": p3.eligible("ch:%s" % a[2], [])}
			got3["grant"] = p3.grant("ch:%s" % a[2])
			got3["after"] = p3.state["ch"]
			_tally("owned", same(got3, want), got3, want)
		"design":
			var w := _workshop(a[1], int(a[0]))
			var d2: Dictionary = a[2]
			var stock2 := Loot.bag()
			stock2["parts"]["troop"] = a[3].duplicate()
			var chk := w.check(d2)
			var no_chassis: bool = w.chassis_of(d2) == null
			var card := w.to_card(d2)
			var abilities: Array = d2["abilities"] if d2.get("abilities") is Array else []
			var got4 := {"abilityPowers": abilities.map(func(ab): return w.ability_power(ab)), "power": w.power(d2),
				"check": {"ok": chk["ok"], "reasons": chk["reasons"], "power": chk["power"], "cap": chk["cap"], "abilities": null if no_chassis else chk["abilities"],
					"abilityCap": null if no_chassis else chk["abilityCap"], "missing": null if no_chassis else chk["missing"]},
				"cost": w.cost(d2), "affordable": w.affordable(d2, stock2), "card": card,
				"fields": abilities.map(func(ab): return Workshop.fields_for(ab)), "attacks": abilities.map(func(ab): return Workshop.is_attack(ab))}
			_tally("design", same(got4, want), got4, want)
		"tables":
			var ts := []
			for t in table_sets:
				ts.append(Workshop.read_tables(t))
			_tally("tables", same(ts, want), ts, want)
		"blank":
			var w2 := _workshop({}, int(a[0]))
			var ch = w2.progress.chassis.get(str(a[1]))
			var got5 := {"design": w2.blank(str(a[1])), "action": w2.blank_ability(ch, "action"), "passive": w2.blank_ability(ch, "passive"),
				"max": {"range": Workshop.max_of(ch, "range"), "hit": Workshop.max_of(ch, "hit"), "ap": Workshop.max_of(ch, "ap")}, "best": Workshop.best_hit(ch)}
			_tally("blank", same(got5, want), got5, want)
		"starter":
			var w3 := _workshop({}, -1)
			var st := w3.starter()
			var sc := w3.check(st)
			var got6 := {"design": st, "card": w3.to_card(st), "check": {"ok": sc["ok"], "reasons": sc["reasons"], "power": sc["power"], "cap": sc["cap"]}, "cost": w3.cost(st)}
			_tally("starter", same(got6, want), got6, want)
		"chassisCheck":
			var ch2: Dictionary = _progress({}).chassis.get(str(a[0]))
			var got7 := Workshop.chassis_check(ch2, {"abilities": a[1]})
			_tally("chassisCheck", same(got7, want), got7, want)
		"allowedFor":
			var w4 := _workshop(a[0], -1)
			var got8 := w4.allowed_for(w4.progress.chassis.get(str(a[1])))
			_tally("allowedFor", same(got8, want), got8, want)
		"districtOf":
			var got9 := Workshop.district_of(_progress({}).chassis.get(str(a[0])))
			_tally("districtOf", same(got9, want), got9, want)
		"keywordsIn":
			var got10 := Workshop.keywords_in(a[0])
			_tally("keywordsIn", same(got10, want), got10, want)
		"look":
			var p4 := _progress({})
			var sk := _skins(p4, a[0])
			var d3: Dictionary = a[1]
			var got11 := {"plan": sk.body_plan_of(d3), "roles": sk.roles_of(d3), "options": sk.options_for(d3).map(func(o): return {"skin": o["skin"]["id"], "fits": o["fits"]}),
				"look": sk.look_of(d3), "pics": sk.pics_of_design(d3)}
			_tally("look", same(got11, want), got11, want)
		_:
			_tally(str(c["fn"]), false, "no such case here", want)
