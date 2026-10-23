## The Workshop used by a random hand, through its screens (0.9): designs
## made on random chassis; abilities added, taken out and given other roles;
## numbers stepped; effects built and changed with the keyword builder by
## random taps, only ever those the sheet offers; looks chosen; designs
## renamed, copied, deleted and copied in from the export; blueprints
## researched, the testing switch flipped; and now and then everything read
## back from the save.
##
## Nothing here checks what a design is worth: workshop_diff.gd proves that
## against the Companion. It checks that nothing breaks and that what is shown
## is what is kept: the design on the screen is the design saved, its power
## and fit are the Workshop's and its card is in the roster as it is; an
## effect made with the builder never uses a keyword the chassis can't, or a
## number past what your blueprints allow; research spends exactly its price
## and nothing while it can't be done; a rename reaches the Strike Teams that
## hold the design, and a name that can't be taken is refused; what is saved
## is read back as it was.
##   godot --headless --path . --script res://tests/soak_workshop.gd [-- moves]
extends SceneTree

const FIXTURE := "res://tests/fixtures/export.zip"
const Kit := preload("res://tests/team_kit.gd")
var rng := RandomNumberGenerator.new()
var wrong: Array = []
var scene: Node2D
var cm: Campaign
var ws: Workshop
var wsn: WorkshopScreen
var ed: DesignEditor
var seen := {"moves": 0, "made": 0, "edits": 0, "inserted": 0, "changed": 0, "given_up": 0, "taps": 0, "abilities": 0, "removed": 0, "roles": 0, "steps": 0,
	"cuts": 0, "looks": 0, "renamed": 0, "refused_names": 0, "copies": 0, "deleted": 0, "copied_in": 0, "researched": 0, "research_refused": 0,
	"testing": 0, "read_back": 0, "fits": 0, "doesnt_fit": 0}


func _initialize() -> void:
	_run.call_deferred()


func _bad(what: String) -> void:
	if wrong.size() < 40:
		wrong.append(what)


func _pick(list: Array):
	return list[rng.randi() % list.size()]


# ---------------------------------------------------------------- what must always be true
## The design on the screen is the one kept, and says what the Workshop says of it.
func _shown_is_kept(when: String) -> void:
	if not ed.visible or not Rules.truthy(ed.d.get("id")):
		return
	var kept = ws.get_design(ed.d["id"])
	if kept == null:
		_bad("%s: %s is on the screen and not kept" % [when, ed.d.get("name")])
		return
	if not ed.locked and kept != ed.d:
		_bad("%s: the design on the screen isn't the one kept: %s / %s" % [when, str(ed.d).left(200), str(kept).left(200)])
	var chk := ws.check(kept)
	var labels := _labels(ed.result)
	if ws.chassis_of(kept) != null:
		if not labels.has("Power %d / %s" % [chk["power"], Scoring.text(chk["cap"])]) or chk["power"] != ws.power(kept):
			_bad("%s: the screen says %s, the Workshop power %d of %s" % [when, str(labels.slice(0, 2)), chk["power"], Scoring.text(chk["cap"])])
		if chk["ok"] != labels.has("Fits, and you own everything it uses."):
			_bad("%s: the screen and the check disagree on whether it fits: %s" % [when, str(chk["reasons"])])
		if chk["ok"] != chk["reasons"].is_empty():
			_bad("%s: the check says ok=%s with reasons %s" % [when, str(chk["ok"]), str(chk["reasons"])])
	var card = cm.roster.card_named(str(kept["name"]))
	if card == null or card.get("_design") != kept["id"]:
		_bad("%s: %s has no card of its own" % [when, kept["name"]])
	else:
		var texts: Array = card["entries"].map(func(e): return str(e.get("text", "")))
		var want: Array = kept["abilities"].map(func(a): return str(a.get("text", "")))
		if texts != want:
			_bad("%s: %s's card says %s and the design %s" % [when, kept["name"], str(texts), str(want)])


func _labels(n: Node) -> Array:
	var out := []
	var todo: Array = [n]
	while not todo.is_empty():
		var k: Node = todo.pop_back()
		if k is Label:
			out.append(k.text)
		todo.append_array(k.get_children())
	return out


## A sentence the builder made uses only what the chassis allows and you own.
## (A sentence being changed keeps what it had: what it had is checked by the fit check.)
func _made_right(sentence: String, d: Dictionary, when: String, was := "") -> void:
	var ch = ws.chassis_of(d)
	var allowed: Array = ws.allowed_for(ch).map(func(k): return str(k).to_lower())
	var had: Array = Workshop.keywords_in(was).map(func(k): return str(k).to_lower())
	for k in Workshop.keywords_in(sentence):
		if k != "Archetype" and not allowed.has(k.to_lower()) and not had.has(k.to_lower()):
			_bad("%s: the builder made '%s', and the chassis can't use %s (or it isn't owned)" % [when, sentence, k])
	var miss := ws.progress.missing([{"text": sentence}]).filter(func(m): return not had.has(str(m["name"]).to_lower()))
	if not miss.is_empty():
		_bad("%s: the builder made '%s', past what is owned: %s" % [when, sentence, str(miss)])
	if not Keywords.sentences(str(_ability_texts(d))).has(sentence) and not str(_ability_texts(d)).contains(sentence):
		_bad("%s: '%s' was inserted and isn't in the design" % [when, sentence])


func _ability_texts(d: Dictionary) -> String:
	return " ".join(d.get("abilities", []).map(func(a): return str(a.get("text", ""))))


## Read back from the save, the Workshop is as it is.
func _read_back(when: String) -> void:
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r2 := Roster.new(x)
	var c2 := Campaign.new(x, r2, x.floors(), null)
	seen["read_back"] += 1
	if c2.workshop.designs.keys().size() != ws.designs.keys().size():
		_bad("%s: %d designs are kept and %d read back" % [when, ws.designs.size(), c2.workshop.designs.size()])
		return
	for id in ws.designs:
		var a = c2.workshop.get_design(id)
		if a == null or JSON.stringify(a, "", true) != JSON.stringify(Rules.ints(JSON.parse_string(JSON.stringify(ws.designs[id]))), "", true):
			_bad("%s: %s read back as %s" % [when, str(ws.designs[id]).left(160), str(a).left(160)])
	if c2.progress.state["bp"] != Rules.ints(JSON.parse_string(JSON.stringify(cm.progress.state["bp"]))) or c2.progress.unlock_all() != cm.progress.unlock_all():
		_bad("%s: the blueprints read back as %s" % [when, str(c2.progress.state).left(200)])
	for d in c2.workshop.list():
		if r2.card_named(str(d["name"])) == null:
			_bad("%s: read back, %s has no card" % [when, d["name"]])


# ---------------------------------------------------------------- the moves
## The keyword builder, open on the editor: random taps until it is closed.
func _build(when: String, changing: bool, was := "") -> void:
	var sh: BuilderSheet = ed.sheet
	if sh == null:
		_bad("%s: the builder didn't open" % when)
		return
	var d: Dictionary = ed.d.duplicate(true)
	var inserted := [""]
	sh.done.connect(func(t): inserted[0] = t)
	for i in 90:
		if ed.sheet == null:
			break
		var offers := sh.offers()
		if offers.is_empty():
			_bad("%s: the builder offers nothing on '%s'" % [when, sh.title.text])
			break
		var tap: Array = offers[rng.randi() % offers.size()]
		if offers.has(["kb", "insert"]) and rng.randf() < 0.55:
			tap = ["kb", "insert"]
		elif offers.has(["kb", "next"]) and rng.randf() < 0.3:
			tap = ["kb", "next"]
		seen["taps"] += 1
		sh.act(tap)
		if ed.sheet != null and sh.b.open:
			# what is shown is what is offered: the sentence and its worth
			var v := sh.b.view()
			if sh.power.text != "   ".join(sh.b.power_texts(v["sentence"])):
				_bad("%s: the builder says '%s' of '%s'" % [when, sh.power.text, v["sentence"]])
	if ed.sheet != null:
		sh.act(["kb", "x"])
		if ed.sheet != null:
			_bad("%s: Close didn't close the builder" % when)
		if ed.d != d and not ed.locked:
			_bad("%s: closing the builder changed the design" % when)
		seen["given_up"] += 1
		return
	if inserted[0] == "":
		if ed.d["abilities"] != d["abilities"]:
			_bad("%s: the builder was given up and the design changed" % when)
		seen["given_up"] += 1
		return
	seen["changed" if changing else "inserted"] += 1
	_made_right(inserted[0], ed.d, when, was)


func _edit_move(when: String) -> void:
	if ed.locked or not ed.visible:
		return
	var abs_: Array = ed.d.get("abilities", [])
	var ch = ed.chassis()
	var roll := rng.randf()
	if abs_.is_empty() or roll < 0.12:
		ed.act(["add", "passive" if rng.randf() < 0.3 else "action"])
		seen["abilities"] += 1
	elif roll < 0.18:
		ed.act(["remove", rng.randi() % abs_.size()])
		seen["removed"] += 1
	elif roll < 0.25:
		var i := rng.randi() % abs_.size()
		if abs_[i].get("kind") != "passive" and ch != null and (ch.get("subtypes", []) as Array).size() > 1:
			ed.act(["role", i])
			seen["roles"] += 1
	elif roll < 0.4:
		var i := rng.randi() % abs_.size()
		if abs_[i].get("kind") != "passive":
			var k: String = _pick(["energy"] + Workshop.fields_for(abs_[i]))
			var was := Scoring.num(abs_[i].get(k), 0.0)
			var by: int = _pick([-1, 1])
			ed.act(["num", i, k, by])
			seen["steps"] += 1
			var most := Scoring.num(ch.get("stats", {}).get("nrg"), 0.0) if k == "energy" else Workshop.max_of(ch, k)
			var least := 0.0 if k == "energy" else Workshop.least_of(ch, k)
			var now := Scoring.num(ed.d["abilities"][i].get(k), 0.0)
			if now < 0 or (by > 0 and now > maxf(most, was)) or (by < 0 and now > was) or (by < 0 and now < minf(least, was)):
				_bad("%s: %s stepped %d from %s to %s, the most %s" % [when, k, by, Scoring.text(was), Scoring.text(now), Scoring.text(most)])
	elif roll < 0.75:
		var i := rng.randi() % abs_.size()
		ed.act(["build", i])
		_build(when + ", building", false)
	elif roll < 0.88:
		var i := rng.randi() % abs_.size()
		var sents := Keywords.sentences(str(abs_[i].get("text", "")))
		if not sents.is_empty():
			var j := rng.randi() % sents.size()
			ed.act(["change", i, j])
			_build(when + ", changing", true, sents[j])
	elif roll < 0.94:
		var i := rng.randi() % abs_.size()
		var sents := Keywords.sentences(str(abs_[i].get("text", "")))
		if not sents.is_empty():
			var j := rng.randi() % sents.size()
			ed.act(["cut", i, j])
			seen["cuts"] += 1
			if Keywords.sentences(str(ed.d["abilities"][i].get("text", ""))).size() != sents.size() - 1:
				_bad("%s: × didn't take the sentence out" % when)
	else:
		var opts := ws.skins.options_for(ed.d) if ws.skins != null else []
		if not opts.is_empty():
			var k: Dictionary = _pick(opts)["skin"]
			var v: Dictionary = _pick(k["variants"])
			ed.act(["look", k["id"], v.get("id")])
			seen["looks"] += 1
			if ws.get_design(ed.d["id"]).get("skin") != {"skin": k["id"], "variant": v.get("id")}:
				_bad("%s: the look chosen isn't kept" % when)


func _rename(when: String) -> void:
	var others: Array = ws.list().filter(func(o): return o["id"] != ed.d["id"]).map(func(o): return str(o["name"]))
	var want: String = ("Design %d" % rng.randi_range(1, 400)) if rng.randf() < 0.5 else _pick(["Frame Trooper", "Test Drone", "Test Warden", "Wasp", "Hornet %d" % rng.randi_range(1, 9)] + others)
	var old := str(ed.d["name"])
	var holding := StrikeTeams.load_all().filter(func(t): return t["deck"].has(old)).map(func(t): return [t["name"], StrikeTeams.copies(t, old)])
	var problem := ed.name_problem(want)
	var took := ed.rename(want)
	if took == (problem != ""):
		_bad("%s: renaming to %s was %s, and the problem is '%s'" % [when, want, "taken" if took else "refused", problem])
	if not took:
		seen["refused_names"] += 1
		if ws.get_design(ed.d["id"])["name"] != old:
			_bad("%s: a refused name changed the design" % when)
		return
	seen["renamed"] += 1
	if old != want:
		for h in holding:
			var t = StrikeTeams.load_all().filter(func(k): return k["name"] == h[0])
			if t.is_empty() or StrikeTeams.copies(t[0], want) != h[1] or t[0]["deck"].has(old):
				_bad("%s: %s held %d of %s, renamed %s, and now %s" % [when, h[0], h[1], old, want, str(t[0]["deck"] if not t.is_empty() else null)])
		if cm.roster.card_named(old) != null and cm.roster.card_named(old).get("_src") == "workshop":
			_bad("%s: %s is still a card of yours after its rename" % [when, old])


func _research(when: String) -> void:
	var p := cm.progress
	var room := p.catalog().filter(func(k): return int(Rules.num(p.state["bp"].get(k["name"]), 0)) >= 1 and int(Rules.num(p.state["bp"].get(k["name"]), 0)) < k["levels"])
	var b: Dictionary = _pick(room) if (not room.is_empty() and rng.randf() < 0.7) else _pick(p.catalog())
	if not p.state["bp"].has(b["name"]) and rng.randf() < 0.7:
		p.state["bp"][b["name"]] = 1      # (found, and brought home)
		cm.save()
	var bag := Loot.norm(cm.deploy.stock)
	bag["shards"] = rng.randi_range(0, 200)
	cm.deploy.stock = bag
	wsn.show_tab("blueprints")
	var have := int(Rules.num(p.state["bp"].get(b["name"]), 0))
	var price := p.research_price(b["name"], have + 1)
	var shards0: int = cm.deploy.stock["shards"]
	var row = wsn._rows.filter(func(rw): return rw.get("research") == b["name"])
	if have < 1 or have >= b["levels"]:
		if not row.is_empty():
			_bad("%s: %s at level %d is offered for research" % [when, b["name"], have])
		return
	if row.is_empty():
		_bad("%s: %s at level %d of %d isn't offered for research" % [when, b["name"], have, b["levels"]])
		return
	wsn.tap_row(row[0])
	if wsn.dialog == null:
		_bad("%s: research didn't ask" % when)
		return
	var can: bool = shards0 >= price
	if (wsn.dialog.buttons.size() == 2) != can:
		_bad("%s: research of %s for %d with %d shards offers %s" % [when, b["name"], price, shards0, str(wsn.dialog.buttons.map(func(x): return x.text))])
	wsn.dialog.buttons[0].pressed.emit()
	if can:
		seen["researched"] += 1
		if p.owned(b["name"]) != have + 1 and not p.unlock_all() or int(p.state["bp"][b["name"]]) != have + 1 or cm.deploy.stock["shards"] != shards0 - price:
			_bad("%s: researched %s level %d for %d: owned %s, shards %d of %d" % [when, b["name"], have + 1, price, str(p.state["bp"][b["name"]]), cm.deploy.stock["shards"], shards0])
	else:
		seen["research_refused"] += 1
		if int(p.state["bp"][b["name"]]) != have or cm.deploy.stock["shards"] != shards0:
			_bad("%s: research that couldn't be paid for changed something" % when)


func _new(when: String) -> void:
	wsn.show_tab("designs")
	wsn.pick_chassis()
	var rows: Array = wsn._rows.filter(func(rw): return rw.has("chassis"))
	if rows.is_empty():
		_bad("%s: no chassis to choose" % when)
		return
	var n0: int = ws.list().size()
	wsn.tap_row(_pick(rows))
	seen["made"] += 1
	if not ed.visible or ws.list().size() != n0 + 1 or ed.d.get("abilities", []).size() != 1:
		_bad("%s: a new design wasn't made and opened" % when)


func _open_some(when: String) -> bool:
	var list := ws.list()
	if list.size() < 2 and rng.randf() < 0.8:
		_new(when)
		return ed.visible
	wsn.show_tab("designs")
	var rows: Array = wsn._rows.filter(func(rw): return rw.has("design"))
	wsn.tap_row(_pick(rows))
	return ed.visible


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var want := int(args[0]) if args.size() > 0 else 300
	rng.seed = 20261007
	Engine.time_scale = 30.0
	root.size = Vector2i(1280, 720)
	Kit.fresh()
	var held := Kit.field_team("Holder")
	Kit.keep([held])
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	cm = scene.campaign
	ws = cm.workshop
	wsn = scene.workshop_screen
	ed = wsn.editor
	# a few chassis found, a few blueprints: the rest is found as it goes
	for id in ["ch_test_threshold", "ch_test_verdant"]:
		cm.progress.grant("ch:" + id)
	for b in cm.progress.catalog():
		if rng.randf() < 0.3:
			cm.progress.state["bp"][b["name"]] = rng.randi_range(1, b["levels"])
	cm.save()     # (0.23) kept, as found ones are: a first move that saves nothing reads them back
	scene.open_dock()
	scene.open_workshop()
	# a design of the Companion's, to copy in
	var comp := ws.to_card({"name": "Wasp", "chassis": "ch_test_threshold", "abilities": [{"name": "Sting", "kind": "action", "role": "Ranged", "energy": 1, "range": 4, "hit": 6, "ap": 4, "text": "[[target enemy]] takes [[damage 2]] with [[Burst 2]]."}]})
	comp["_src"] = "design"
	comp["design"] = "ds_wasp"
	scene.roster.from_export.append(comp)
	cm.designs_changed()
	for m in want:
		if not wrong.is_empty():
			break
		seen["moves"] += 1
		var when := "move %d" % m
		if OS.get_environment("SOAK_TRACE") != "":
			print("%s: %d designs, %d MB" % [when, ws.designs.size(), OS.get_static_memory_usage() / 1048576])
		var roll := rng.randf()
		if roll < 0.08:
			_new(when)
		elif roll < 0.70:
			if _open_some(when):
				seen["edits"] += 1
				for k in rng.randi_range(2, 8):
					_edit_move(when)
					_shown_is_kept(when)
				ed.close()
		elif roll < 0.78:
			if _open_some(when) and not ed.locked:
				_rename(when)
				_shown_is_kept(when + ", renamed")
				# a Strike Team holds it, so that the next rename has a team to reach
				var teams := StrikeTeams.load_all()
				teams[0]["deck"][str(ed.d["name"])] = rng.randi_range(1, 3)
				StrikeTeams.save_all(teams)
			ed.close()
		elif roll < 0.82:
			if _open_some(when):
				var n0: int = ws.list().size()
				var from: Dictionary = ed.d.duplicate(true)
				ed.copy()
				seen["copies"] += 1
				if ws.list().size() != n0 + 1 or ed.d["abilities"] != from["abilities"] or ed.d["id"] == from["id"] or ed.locked:
					_bad("%s: Copy didn't make a copy that can be changed" % when)
				_shown_is_kept(when + ", copied")
				ed.close()
		elif roll < 0.86:
			if _open_some(when) and not ed.locked:
				var id = ed.d["id"]
				var nm := str(ed.d["name"])
				ed.ask_delete()
				ed.dialog.buttons[0].pressed.emit()
				seen["deleted"] += 1
				if ws.get_design(id) != null or ed.visible or (cm.roster.card_named(nm) != null and cm.roster.card_named(nm).get("_design") == id):
					_bad("%s: Delete didn't delete %s" % [when, nm])
			ed.close()
		elif roll < 0.93:
			_research(when)
		elif roll < 0.95:
			wsn.show_tab("blueprints")
			var on := cm.progress.unlock_all()
			wsn.tap_row(wsn._rows[0])
			seen["testing"] += 1
			if cm.progress.unlock_all() == on:
				_bad("%s: the testing switch didn't switch" % when)
		elif roll < 0.97:
			wsn.show_tab("export")
			var rows: Array = wsn._rows.filter(func(rw): return rw.has("card"))
			var n0: int = ws.list().size()
			wsn.tap_row(_pick(rows))
			if wsn.dialog != null:
				wsn.dialog.buttons[0].pressed.emit()
				seen["copied_in"] += 1
				if ws.list().size() != n0 + 1 or not ed.visible or not Rules.truthy(ed.d.get("from")):
					_bad("%s: copying in didn't make a design of it" % when)
				_shown_is_kept(when + ", copied in")
			ed.close()
		else:
			_read_back(when)
		# (a frame, so that what the screens let go of is freed)
		await process_frame
		# the list says what is kept
		wsn.show_tab("designs")
		for rw in wsn._rows:
			if rw.has("design"):
				var d = ws.get_design(rw["design"])
				var chk := ws.check(d)
				seen["fits" if chk["ok"] else "doesnt_fit"] += 1
				var line := "%s · power %d of %s · %s" % [str(ws.chassis_of(d).get("name")) if ws.chassis_of(d) != null else "(its chassis is missing)", chk["power"], Scoring.text(chk["cap"]), "fits" if chk["ok"] else "doesn't fit"]
				if not _labels(rw["row"]).has(line):
					_bad("%s: the list says %s for %s" % [when, str(_labels(rw["row"])), line])
	_read_back("at the end")
	scene.queue_free()
	await process_frame
	Engine.time_scale = 1.0
	Rules.hooks = {}
	Kit.fresh()
	for w in wrong.slice(0, 14):
		print("FAIL " + w)
	print("(%d moves: %d designs made, %d opened to change; %d effects built and %d changed by %d taps, %d given up; %d abilities added, %d taken out, %d roles, %d numbers stepped, %d sentences cut, %d looks)" % [
		seen["moves"], seen["made"], seen["edits"], seen["inserted"], seen["changed"], seen["taps"], seen["given_up"], seen["abilities"], seen["removed"], seen["roles"], seen["steps"], seen["cuts"], seen["looks"]])
	print("(%d renamed, %d names refused; %d copies, %d deleted, %d copied in; %d researched, %d refused; the testing switch flipped %d times; read back %d times; designs seen fitting %d times, not %d)" % [
		seen["renamed"], seen["refused_names"], seen["copies"], seen["deleted"], seen["copied_in"], seen["researched"], seen["research_refused"], seen["testing"], seen["read_back"], seen["fits"], seen["doesnt_fit"]])
	if want >= 300 and (seen["inserted"] < 60 or seen["changed"] < 15 or seen["renamed"] < 3 or seen["refused_names"] < 2 or seen["researched"] < 2 or seen["research_refused"] < 1 or seen["copied_in"] < 1 or seen["deleted"] < 2 or seen["read_back"] < 3 or seen["fits"] < 20):
		wrong.append("too little of it was tried: %s" % str(seen))
		print("FAIL " + wrong[wrong.size() - 1])
	print("\nWORKSHOP SOAK PASS %d  FAIL %d" % [seen["moves"] if wrong.is_empty() else 0, wrong.size()])
	quit(1 if not wrong.is_empty() else 0)
