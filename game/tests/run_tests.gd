## The game's own tests, run without a screen:
##   godot --headless --path . --script res://tests/run_tests.gd
## They read a real Export for Godot made by the Companion (tests/fixtures/export.zip).
## The rules have suites of their own: rules_tests.gd and rules_diff.gd.
extends SceneTree

const FIXTURE := "res://tests/fixtures/export.zip"
const Kit := preload("res://tests/team_kit.gd")
var ok := 0
var bad := 0


func ck(name: String, cond: bool, detail = "") -> void:
	if cond:
		ok += 1
		print("PASS " + name)
	else:
		bad += 1
		print("FAIL " + name + "  — " + str(detail).left(260))


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if OS.get_cmdline_user_args().has("twentythree"):
		# (only 0.23's, while working on them)
		Kit.fresh()
		_twentythree()
		await _twentythree_scene()
		Kit.fresh()
		print("\nGAME PASS %d  FAIL %d" % [ok, bad])
		Rules.hooks = {}
		quit(1 if bad > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("twentytwo"):
		# (only 0.22's, while working on them)
		Kit.fresh()
		_twentytwo()
		Kit.fresh()
		print("\nGAME PASS %d  FAIL %d" % [ok, bad])
		Rules.hooks = {}
		quit(1 if bad > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("twentyone"):
		# (only 0.21's, while working on them)
		Kit.fresh()
		_twentyone()
		Kit.fresh()
		print("\nGAME PASS %d  FAIL %d" % [ok, bad])
		Rules.hooks = {}
		quit(1 if bad > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("twenty"):
		# (only 0.20's, while working on them)
		Kit.fresh()
		_twenty()
		await _twenty_scene()
		Kit.fresh()
		print("\nGAME PASS %d  FAIL %d" % [ok, bad])
		Rules.hooks = {}
		quit(1 if bad > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("nineteen"):
		# (only 0.19's, while working on them)
		Kit.fresh()
		_nineteen()
		await _nineteen_scene()
		Kit.fresh()
		print("\nGAME PASS %d  FAIL %d" % [ok, bad])
		Rules.hooks = {}
		quit(1 if bad > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("eighteen"):
		# (only 0.18's, while working on them)
		Kit.fresh()
		_eighteen()
		await _eighteen_scene()
		Kit.fresh()
		print("\nGAME PASS %d  FAIL %d" % [ok, bad])
		Rules.hooks = {}
		quit(1 if bad > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("seventeen"):
		# (only 0.17's, while working on them)
		Kit.fresh()
		_seventeen()
		await _seventeen_scene()
		Kit.fresh()
		print("\nGAME PASS %d  FAIL %d" % [ok, bad])
		Rules.hooks = {}
		quit(1 if bad > 0 else 0)
	if OS.get_cmdline_user_args().has("sixteen"):
		# (only 0.16's, while working on them)
		Kit.fresh()
		_sixteen()
		await _sixteen_scene()
		Kit.fresh()
		print("\nGAME PASS %d  FAIL %d" % [ok, bad])
		Rules.hooks = {}
		quit(1 if bad > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("fifteen"):
		# (only 0.15's, while working on them)
		Kit.fresh()
		_fifteen()
		await _fifteen_scene()
		Kit.fresh()
		print("\nGAME PASS %d  FAIL %d" % [ok, bad])
		Rules.hooks = {}
		quit(1 if bad > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("fourteen"):
		# (only 0.14's, while working on them)
		Kit.fresh()
		_fourteen()
		await _fourteen_scene()
		Kit.fresh()
		print("\nGAME PASS %d  FAIL %d" % [ok, bad])
		Rules.hooks = {}
		quit(1 if bad > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("thirteen"):
		# (only 0.13's, while working on them)
		Kit.fresh()
		_thirteen()
		await _thirteen_scene()
		Kit.fresh()
		print("\nGAME PASS %d  FAIL %d" % [ok, bad])
		Rules.hooks = {}
		quit(1 if bad > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("twelve"):
		# (only 0.12's, while working on them)
		Kit.fresh()
		_twelve()
		await _twelve_scene()
		Kit.fresh()
		print("\nGAME PASS %d  FAIL %d" % [ok, bad])
		Rules.hooks = {}
		quit(1 if bad > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("eleven"):
		# (only 0.11's, while working on them)
		Kit.fresh()
		_fonts()
		_eleven()
		await _eleven_scene()
		Kit.fresh()
		print("\nGAME PASS %d  FAIL %d" % [ok, bad])
		Rules.hooks = {}
		quit(1 if bad > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("ten"):
		# (only 0.10's, while working on them)
		Kit.fresh()
		_ten()
		await _ten_scene()
		Kit.fresh()
		print("\nGAME PASS %d  FAIL %d" % [ok, bad])
		Rules.hooks = {}
		quit(1 if bad > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("nine"):
		# (only 0.9's, while working on them)
		Kit.fresh()
		_nine()
		await _nine_scene()
		Kit.fresh()
		print("\nGAME PASS %d  FAIL %d" % [ok, bad])
		Rules.hooks = {}
		quit(1 if bad > 0 else 0)
		return
	_hex()
	_export()
	_floors()
	_roster()
	_battle()
	_combat()
	_effects()
	_fonts()
	Kit.fresh()                   # the tests keep Strike Teams in a file of their own
	_teams()
	_team_battle()
	_cards()
	_seven()
	_eight()
	_nine()
	_ten()
	_eleven()
	_twelve()
	_thirteen()
	_fourteen()
	_fifteen()
	_sixteen()
	_seventeen()
	_eighteen()
	_nineteen()
	_twenty()
	_twentyone()
	_twentytwo()
	_twentythree()
	await _setup()
	await _team_setup()
	await _builder()
	await _main_scene()
	await _fight_scene()
	await _effects_scene()
	await _team_scene()
	await _play_scene()
	await _seven_scene()
	await _eight_scene()
	await _nine_scene()
	await _ten_scene()
	await _eleven_scene()
	await _twelve_scene()
	await _thirteen_scene()
	await _fourteen_scene()
	await _fifteen_scene()
	await _sixteen_scene()
	await _seventeen_scene()
	await _eighteen_scene()
	await _nineteen_scene()
	await _twenty_scene()
	await _twentythree_scene()
	Kit.fresh()
	print("\nGAME PASS %d  FAIL %d" % [ok, bad])
	Rules.hooks = {}              # the rules let go of the last battle
	quit(1 if bad > 0 else 0)


# ---------------------------------------------------------------- hex maths
func _hex() -> void:
	var all_back := true
	for q in range(-8, 9):
		for r in range(-8, 9):
			var h := Vector2i(q, r)
			if Hex.from_pixel(Hex.to_pixel(h, 48.0), 48.0) != h:
				all_back = false
	ck("hex: every tile's centre maps back to the tile", all_back)
	ck("hex: the Sandbox's layout (pointy-top)", Hex.to_pixel(Vector2i(1, 0), 10.0).is_equal_approx(Vector2(Hex.SQ3 * 10.0, 0)) and Hex.to_pixel(Vector2i(0, 1), 10.0).is_equal_approx(Vector2(Hex.SQ3 * 5.0, 15.0)), Hex.to_pixel(Vector2i(0, 1), 10.0))
	ck("hex: a point near an edge picks the nearer tile", Hex.from_pixel(Hex.to_pixel(Vector2i(2, -1), 48.0) + Vector2(20, 0), 48.0) == Vector2i(2, -1))
	ck("hex: distance", Hex.distance(Vector2i(0, 0), Vector2i(3, -1)) == 3 and Hex.distance(Vector2i(-2, 1), Vector2i(2, -1)) == 4 and Hex.distance(Vector2i(4, 4), Vector2i(4, 4)) == 0)
	ck("hex: six neighbours, each one step away", Hex.neighbours(Vector2i(1, 1)).size() == 6 and Hex.neighbours(Vector2i(1, 1)).all(func(n): return Hex.distance(n, Vector2i(1, 1)) == 1))
	ck("hex: keys read and write as the Companion's", Hex.parse("-4,6") == Vector2i(-4, 6) and Hex.key(Vector2i(-4, 6)) == "-4,6")
	var shared := true
	for d in Hex.DIRS:
		var e := Hex.shared_edge(Vector2i.ZERO, d, 30.0)
		var ca := Hex.corners(Hex.to_pixel(Vector2i.ZERO, 30.0), 30.0)
		var cb := Hex.corners(Hex.to_pixel(d, 30.0), 30.0)
		for p in e:
			var in_a := false
			var in_b := false
			for c in ca: in_a = in_a or c.distance_to(p) < 0.01
			for c in cb: in_b = in_b or c.distance_to(p) < 0.01
			shared = shared and in_a and in_b
	ck("hex: a wall's edge is a corner of both tiles", shared)
	ck("hex: no edge between tiles that don't touch", Hex.shared_edge(Vector2i.ZERO, Vector2i(2, 0), 30.0).is_empty())


# ---------------------------------------------------------------- the export
func _export() -> void:
	var x := KeterExport.new()
	var opened := x.open(FIXTURE)
	ck("export: the Companion's zip opens, no unzipping", opened and x.is_open(), x.error)
	ck("export: its manifest says what it is", x.manifest.get("game") == "KETER" and int(x.manifest.get("format", 0)) == 1 and x.manifest.has("companion"), x.manifest.keys())
	var kinds := []
	for c in x.manifest.get("content", []):
		kinds.append(c.get("kind"))
	ck("export: every kind of content is listed", kinds == ["cards", "floors", "world_map", "chassis", "pools", "tables", "skins"], kinds)
	var all_read := true
	for k in kinds:
		var d := x.content(k)
		all_read = all_read and int(d.get("format", 0)) == 1 and d.get("kind") == k
	ck("export: each content file reads, with its format", all_read)
	ck("export: the cards", x.cards().size() > 100 and x.cards().any(func(c): return c.get("name") == "Test Warden"), x.cards().size())
	ck("export: the world map", x.content("world_map").get("map", {}).has("tiles") and x.content("tables").has("dock"))
	var tok := x.hero_token()
	ck("export: a Hero's token, as a texture", tok.get("name") == "Test Warden" and tok.get("texture") is Texture2D and tok["texture"].get_width() > 20, tok)
	var t1 := x.texture(tok.get("file", ""))
	ck("export: textures are read once", t1 == x.texture(tok.get("file", "")))
	ck("export: a file it doesn't have is null", x.texture("nope.png") == null)
	x.close()
	ck("export: closes", not x.is_open())
	# the newest of several, and nothing when there's none
	var dir := "user://find_test/"
	DirAccess.make_dir_recursive_absolute(dir)
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + f)
	ck("export: none there, none found", KeterExport.find_newest([dir]) == "")
	var bytes := FileAccess.get_file_as_bytes(FIXTURE)
	for n in ["KETER_export_2026-09-01.zip", "KETER_export_2026-09-30.zip", "KETER_assets_2026-08-01.zip", "other.zip"]:
		var fa := FileAccess.open(dir + n, FileAccess.WRITE)
		fa.store_buffer(bytes)
		fa.close()
	ck("export: the newest by its date", KeterExport.find_newest([dir]).get_file() == "KETER_export_2026-09-30.zip", KeterExport.find_newest([dir]))
	# a newer format than this game reads
	var zp := ZIPPacker.new()
	zp.open(dir + "future.zip")
	zp.start_file("manifest.json")
	zp.write_file(JSON.stringify({"game": "KETER", "format": 99}).to_utf8_buffer())
	zp.close_file()
	zp.close()
	var y := KeterExport.new()
	ck("export: one from a newer Companion is refused, and says why", not y.open(dir + "future.zip") and "newer" in y.error, y.error)
	var z := KeterExport.new()
	ck("export: something that isn't a zip is refused", not z.open(dir + "missing.zip") and z.error != "")


# ---------------------------------------------------------------- floors
func _floors() -> void:
	var x := KeterExport.new()
	x.open(FIXTURE)
	var fl := x.floors()
	var names := fl.map(func(f): return f.name)
	ck("floors: every saved floor", names.has("TEST · Corridor") and names.has("TEST · Waves") and fl.size() >= 4, names)
	var cor: FloorData = fl.filter(func(f): return f.name == "TEST · Corridor")[0]
	ck("floors: tiles, with the Sandbox's colours", cor.tiles.size() == 45 and cor.label_of(cor.player_spawns()[0]) == "Player Spawn Tile", cor.tiles.size())
	ck("floors: a Hero starts on a player spawn tile", cor.player_spawns().has(cor.start_tile()))
	ck("floors: walls on the edge between two tiles", cor.walls.size() == 2 and cor.walls[0][0] == Vector2i(4, -1) and cor.walls[0][1] == Vector2i(5, -1), cor.walls)
	var haz: FloorData = fl.filter(func(f): return f.name == "TEST · Hazards and Cover")[0]
	ck("floors: symbols, with their text", haz.marks.size() == 5 and haz.sym_defs[1].get("text") == "AC", haz.marks)
	var r := cor.bounds(48.0)
	ck("floors: its size on the board", r.size.x > 0 and r.size.y > 0, r)
	var blank := FloorData.from_dict({"name": "Empty", "hexes": [["0,0", {}], ["1,0", {"c": null}]]})
	ck("floors: plain tiles, and a floor with no spawn starts in the middle", blank.colour_of(Vector2i(1, 0)) == -1 and blank.start_tile() == Vector2i.ZERO)


# ---------------------------------------------------------------- what a battle is made from
## (0.23) Gives a card plain text, as cards had before the effect box audit
## wrote them all in keywords: its first effect's text, in the roster's own copy.
func _make_plain(r: Roster, name: String, text := "Steady your nerve and press the attack.") -> void:
	var c = r.card_named(name)
	if c == null:
		return
	var list: Array = Roster.entries_of(c)
	if list.is_empty():
		list.append({"name": "", "kind": "Active", "text": text})
	else:
		list[0]["text"] = text


func _floor_named(x: KeterExport, n: String) -> FloorData:
	for f in x.floors():
		if f.name == n:
			return f
	return null


func _roster() -> void:
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)
	var hs := r.heroes()
	var hn := hs.map(func(c): return c["name"])
	ck("roster: every Hero card (0.22: Ilsa Varn among them)", hn.has("Rictus") and hn.has("Test Warden") and hn.has("Ilsa Varn, Jump-Frame Pilot") and hs.size() == 9, hn)
	ck("roster: test cards come last", hs[hs.size() - 1]["_src"] == "test" and hs[0]["_src"] != "test", hn)
	var ts := r.troops()
	ck("roster: the Companion's designs and pre-builts first, and marked as the Companion's", ts[0]["name"] == "Frame Trooper" and Roster.origin(ts[0]) == "Companion design", [ts[0]["name"], Roster.origin(ts[0])])
	ck("roster: 0.10: then the pre-built Troops, marked so", ts[1]["name"] == "Hornet Mk I" and ts[2]["name"] == "Bastion Mk I" and Roster.origin(ts[1]) == "Pre-built" and Roster.type_of(ts[2]) == "troop", ts.slice(0, 3).map(func(c): return [c["name"], Roster.origin(c)]))
	ck("roster: then every other Troop (0.21: the Test Skirmisher among them; 0.22: after the two shipped pre-builts on the Skitter Frame; 0.23: the Test Bulwark too)", ts.size() == 49 and ts[3]["name"] == "Skitter Runner Mk I" and ts[4]["name"] == "Skitter Harrier Mk I" and ts.slice(5).all(func(c): return c["_src"] != "design" and c["_src"] != "prebuilt"), ts.size())
	# 0.9: your own designs come before everything, and one of the export's with the same name gives way
	var ws_card := {"name": "Frame Trooper", "cardType": "troop", "_src": "workshop", "_design": "ds_starter", "stats": {}, "entries": []}
	r.set_designs([ws_card, {"name": "Lancer", "cardType": "troop", "_src": "workshop", "_design": "ds_x", "stats": {}, "entries": []}])
	ts = r.troops()
	ck("roster: 0.9: your designs first, marked as yours, and the Companion's copy of the starter gives way to yours", ts[0]["_src"] == "workshop" and ts[1]["name"] == "Lancer" and Roster.origin(ts[0]) == "Your design"
		and ts.size() == 50 and ts.filter(func(c): return c["name"] == "Frame Trooper").size() == 1 and r.card_named("Frame Trooper")["_src"] == "workshop", ts.slice(0, 3).map(func(c): return [c["name"], c["_src"]]))
	r.set_designs([])
	ts = r.troops()
	ck("roster: numbers are whole numbers, as the Companion has them", ts[0]["level"] is int, typeof(ts[0]["level"]))
	var sl: FloorData = _floor_named(x, "TEST · Sight Lines")
	ck("roster: a Medium floor lets 2 Heroes in", Roster.hero_capacity(sl) == 2)
	var small := FloorData.from_dict({"name": "S", "hexes": [["0,0", {}]]})
	var big := FloorData.from_dict({"name": "B", "battlefieldSize": "Large", "hexes": [["0,0", {}]]})
	var old := FloorData.from_dict({"name": "O", "floorSize": "small", "hexes": [["0,0", {}]]})
	ck("roster: an unsized floor is sized by its tiles; Large lets 3 in; the old floorSize still reads", Roster.hero_capacity(small) == 1 and Roster.hero_capacity(big) == 3 and Roster.hero_capacity(old) == 1)
	ck("roster: Leadership off the card", Roster.leadership(r.card_named("Volt-Warden Ryska")) == 8 and Roster.leadership(r.card_named("Dross, the Forge-Blind")) == 0)
	ck("roster: Unit Slots off the card, a blank or 0 counting 1 (as the simulator)", Roster.slots(r.card_named("Aetherium Golem")) == 5 and Roster.slots(r.card_named("Aether Battery")) == 1 and Roster.slots(r.card_named("Frame Trooper")) == 1)
	ck("roster: an Enemy's level is its Skull Level, else its level", Roster.foe_level(r.card_named("Arachnabot")) == 4 and Roster.foe_level(r.card_named("Test Grunt")) == 1)
	var p4 := r.foe_pool(4, "3")
	ck("roster: a spawn tile draws from its level in the floor's District", not p4.is_empty() and p4.all(func(c): return Roster.foe_level(c) == 4 and Roster.district_of(c) == "3"), p4.map(func(c): return c["name"]))
	var p5 := r.foe_pool(5, "3")
	ck("roster: failing the District, any at that level", not p5.is_empty() and p5.all(func(c): return Roster.foe_level(c) == 5), p5.map(func(c): return c["name"]))
	ck("roster: only Enemy cards, never Elites or Mini-Bosses", r.foe_pool(3, "3").all(func(c): return Roster.type_of(c) == "enemy") and r.foe_pool(4, "3").all(func(c): return c["name"] != "Test Overseer"))
	var r2 := Roster.new(x)
	r2.cards = [{"name": "Two", "cardType": "enemy", "level": 2}, {"name": "Four", "cardType": "enemy", "level": 4}, {"name": "Hero", "cardType": "hero"}]
	ck("roster: failing the level, the nearest, lower first", r2.foe_pool(3, "3")[0]["name"] == "Two" and r2.foe_pool(6, "")[0]["name"] == "Four" and r2.foe_pool(1, "")[0]["name"] == "Two")
	var spec := Roster.unit_spec(r.card_named("Rictus"))
	var u := Rules.unit_from_card(spec, "ally")
	ck("roster: a card becomes a Unit the rules read", u["hpMax"] == 40 and u["ac"] == 9 and u["ms"] == 4 and u["nrgMax"] == 4 and u["actions"].size() > 0, [u["hpMax"], u["ac"], u["ms"]])
	var tk := r.token_for(r.card_named("Test Warden"))
	ck("roster: a card's token, and whether it is a hexagon of hex pixels", tk.get("texture") is Texture2D and tk.get("hexagon") == true, tk)
	var sq := r.token_for(r.card_named("Test Grunt"))
	ck("roster: a square token is not", sq.get("texture") is Texture2D and sq.get("hexagon") == false)
	var ds := r.token_for(r.card_named("Frame Trooper"))
	ck("roster: a design wears its skin's token", ds.get("texture") is Texture2D and "bipedal" in str(ds.get("file")), ds)
	# (0.14) a master Unit the export has no token for wears the game's own drawing of it
	ck("roster: a card with no token of its own wears the game's drawing of it", r.token_for(r.card_named("Rictus")).get("drawn", false) and r.token_for(r.card_named("Rictus")).get("texture") == Art.token_drawn(r.card_named("Rictus")))
	ck("roster: a card the game hasn't drawn either has none", r.token_for({"name": "Nobody Drew Me", "cardType": "troop"}).is_empty())
	ck("roster: an Enemy's looks: its own token", r.enemy_looks(r.card_named("Test Grunt")).size() == 1 and r.enemy_looks(r.card_named("Arachnabot")).size() == 1 and r.enemy_looks(r.card_named("Arachnabot"))[0].get("drawn", false))
	r2._skins = [{"owner": {"kind": "enemy", "key": "Test Grunt"}, "variants": [{"token": "px_skin_bipedal_token"}, {"token": "missing"}]}]
	r2.cards = r.cards
	ck("roster: and its skins' tokens, when it has some", r2.enemy_looks(r.card_named("Test Grunt")).size() == 2)
	ck("roster: three letters when there's no token", Roster.letters("Test Grunt") == "GRU" and Roster.letters("\"Mincer\" Cleaner Bot") == "MIN" and Roster.letters("") == "?")
	x.close()


func _battle() -> void:
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)
	var cor: FloorData = _floor_named(x, "TEST · Corridor")
	var hc := [r.card_named("Test Warden"), r.card_named("Test Striker")]
	var tc := [r.card_named("Test Drone"), r.card_named("Test Drone"), r.card_named("Frame Trooper")]
	var b := Battle.begin(cor, r, hc, tc, 5)
	var allies := b.side_units("ally")
	ck("battle: your Heroes and Troops take the field", allies.map(func(u): return u["name"]) == ["Test Warden", "Test Striker", "Test Drone", "Test Drone 2", "Frame Trooper"], allies.map(func(u): return u["name"]))
	var spawns := b.ally_spawns()
	ck("battle: on your spawn tiles, in the floor's order", spawns == [Vector2i(-6, -1), Vector2i(-7, 0), Vector2i(-6, 0), Vector2i(-7, 1)] and Battle.tile_of(allies[0]) == spawns[0] and Battle.tile_of(allies[3]) == spawns[3], spawns)
	ck("battle: more Units than spawn tiles, the rest beside them, and it says so", Battle.tile_of(allies[4]) == Vector2i(-5, -1) and b.notes.size() == 1 and "beside" in b.notes[0], [Battle.tile_of(allies[4]), b.notes])
	var foes := b.side_units("enemy")
	var es := b.enemy_spawns()
	ck("battle: an Enemy on every Enemy spawn tile", foes.size() == 3 and foes.all(func(u): return es.any(func(t): return t["at"] == Battle.tile_of(u))), foes.map(func(u): return [u["name"], u.get("pos")]))
	var ids := {}
	for u in b.units:
		ids[u["id"]] = true
	ck("battle: every Unit has its own id", ids.size() == b.units.size())
	var wv: FloorData = _floor_named(x, "TEST · Waves")
	var bw := Battle.begin(wv, r, hc, [], 11)
	var lv_ok := true
	for u in bw.side_units("enemy"):
		lv_ok = lv_ok and Roster.foe_level(r.card_named(u["src"])) == u["spawnLevel"]
	ck("battle: each at its tile's level (Waves: 1 to 4)", lv_ok and bw.side_units("enemy").map(func(u): return u["spawnLevel"]) == [1, 2, 3, 4], bw.side_units("enemy").map(func(u): return [u["name"], u["spawnLevel"]]))
	var again := Battle.begin(wv, r, hc, [], 11)
	ck("battle: the same seed deals the same Enemies", again.side_units("enemy").map(func(u): return u["name"]) == bw.side_units("enemy").map(func(u): return u["name"]))
	var e1 = b.unit_at(Vector2i(8, -1))
	ck("battle: who stands where", e1 != null and e1["side"] == "enemy" and b.unit_at(Vector2i(0, 0)) == null)

	# reach is the rules' reach, around Units and walls
	var w: Dictionary = allies[0]
	var want := Rules.reachable(w["pos"], 4, {"passable": func(n): return cor.has_tile(Vector2i(n["q"], n["r"])), "blocked": func(n): return b.unit_at(Vector2i(n["q"], n["r"])) != null})
	ck("battle: a Unit reaches as far as its Movement Speed, as the rules say", b.speed(w) == 4 and b.reach(w) == want and want.all(func(t): return t["cost"] <= 4), b.reach(w).size())
	ck("battle: never onto another Unit", b.reach(w).all(func(t): return b.unit_at(Vector2i(t["q"], t["r"])) == null))
	w["pos"] = {"q": 4, "r": -1}
	w["ms"] = 1
	var near := b.reach(w).map(func(t): return Vector2i(t["q"], t["r"]))
	ck("battle: not through a wall", not near.has(Vector2i(5, -1)) and near.has(Vector2i(4, 0)) and near.has(Vector2i(3, -1)), near)
	w["flying"] = true
	ck("battle: unless it flies", b.reach(w).map(func(t): return Vector2i(t["q"], t["r"])).has(Vector2i(5, -1)))
	w.erase("flying")
	w["ms"] = 2
	var path := b.path_to(w, Vector2i(5, -1))
	ck("battle: the way there goes round the wall, one tile at a time", path == [Vector2i(4, 0), Vector2i(5, -1)], path)
	var steps_ok := true
	var all_reach := b.reach(w)
	for t in all_reach:
		var pth := b.path_to(w, Vector2i(t["q"], t["r"]))
		var prev := Battle.tile_of(w)
		steps_ok = steps_ok and pth.size() == t["cost"]
		for h in pth:
			steps_ok = steps_ok and Hex.distance(prev, h) == 1 and b.unit_at(h) == null
			prev = h
	ck("battle: every way is as long as its reach says, each step to a neighbour", steps_ok and all_reach.size() > 3)
	ck("battle: nowhere it can't reach", b.path_to(w, Vector2i(8, -1)).is_empty() and b.path_to(w, Vector2i(40, 40)).is_empty())
	var gone := b.move(w, Vector2i(5, -1))
	ck("battle: moving takes it there", gone.size() == 2 and Battle.tile_of(w) == Vector2i(5, -1) and b.unit_at(Vector2i(5, -1)) == w)
	ck("battle: once a round", b.has_moved(w) and not b.can_move(w) and b.reach(w).is_empty() and b.move(w, Vector2i(6, -1)).is_empty())
	var foe: Dictionary = foes[0]
	ck("battle: an Enemy moves too", b.can_move(foe) and not b.move(foe, Vector2i(Battle.tile_of(foe).x - 1, Battle.tile_of(foe).y)).is_empty())
	b.next_round()
	ck("battle: a new round lets every Unit move again", b.round == 2 and b.can_move(w) and b.can_move(foe))
	Rules.add_status(w, "Rooted", null, null, 2)
	ck("battle: a Rooted Unit can't", not b.can_move(w) and b.reach(w).is_empty() and b.speed(w) == 0)
	var none := Battle.begin(FloorData.from_dict({"name": "Bare", "hexes": [["0,0", {}], ["1,0", {}], ["0,1", {}]]}), r, [r.card_named("Rictus")], [], 1)
	ck("battle: a floor with no spawn tiles: your Units at its edge, no Enemies, and it says both", none.side_units("enemy").is_empty() and none.units[0].get("pos") != null and none.notes.size() == 2, none.notes)
	x.close()


# ---------------------------------------------------------------- fighting (the battle's own code)
func _mk(r: Roster, name: String, side: String, id: String, at: Vector2i) -> Dictionary:
	var u := Rules.unit_from_card(Roster.unit_spec(r.card_named(name)), side)
	u["id"] = id
	u["pos"] = {"q": at.x, "r": at.y}
	return u


func _act(u: Dictionary, name: String) -> Dictionary:
	for a in u["actions"]:
		if a["name"] == name:
			return a
	return {}


## The odds shown are the rules' own: every pair of d20 rolls counted.
func _exact(b: Battle, u: Dictionary, a: Dictionary, t: Dictionary) -> bool:
	var o := b.odds(u, a, t)
	var through := 0
	var dmg := -1
	for acc in range(1, 21):
		for pen in range(1, 21):
			var res := Rules.resolve_attack(u, a, t, {"distance": Rules.hex_distance(u["pos"], t["pos"]), "cover": b.cover_for(t, u),
				"evasive": t.get("evasive", 0), "rolls": {"accuracy": acc, "penetration": pen}})
			if res["hit"] == true and res["penetrated"] == true:
				through += 1
				dmg = res["damage"]
	return absf(o["p"] - through / 400.0) < 1e-9 and (dmg < 0 or dmg == o["dmg"])


func _combat() -> void:
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)
	var cor: FloorData = _floor_named(x, "TEST · Corridor")
	var haz: FloorData = _floor_named(x, "TEST · Hazards and Cover")
	var sl: FloorData = _floor_named(x, "TEST · Sight Lines")

	# aiming and the odds
	var w := _mk(r, "Test Warden", "ally", "a1", Vector2i(0, 0))
	var s := _mk(r, "Test Striker", "ally", "a2", Vector2i(3, 0))
	var g := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(4, 0))
	var g2 := _mk(r, "Test Grunt", "enemy", "e2", Vector2i(4, -1))
	var b := Battle.from_state(cor, [w, s, g, g2], 1)
	var volley := _act(w, "Pinning Volley")
	var check := _act(s, "Shoulder Check")
	var medic := _act(w, "Field Medicine")
	ck("fight: an aimed Action reaches as far as its range, a blow only next door", b.can_reach(w, volley, g) and b.can_reach(s, check, g) and not b.can_reach(w, check, g), [b.can_reach(w, volley, g), b.can_reach(s, check, g)])
	ck("fight: an attack is aimed at the other side; Support at your own, never yourself", b.targets_for(s, check).map(func(u): return u["id"]) == ["e1", "e2"] and b.targets_for(w, medic).is_empty())
	ck("fight: the odds are the rules' own, every pair of rolls counted (a shot)", _exact(b, w, volley, g), b.odds(w, volley, g))
	ck("fight: the odds are the rules' own (a blow)", _exact(b, s, check, g) and b.odds(s, check, g)["dmg"] == 4, b.odds(s, check, g))
	Rules.add_status(g, "Marked", null, "player", 2)
	ck("fight: a Marked target is always hit by a shot, and the odds know it", _exact(b, w, volley, g) and b.odds(w, volley, g)["p"] > 0.74, b.odds(w, volley, g))
	g["statuses"] = []
	g["flying"] = true
	ck("fight: a blow can't reach a Flying target: 0%", b.odds(s, check, g)["p"] == 0.0 and _exact(b, s, check, g))
	g.erase("flying")
	# Cover: a Barricade between the shot and its target
	var found := []
	for c in haz.tiles:
		var kind := Battle.from_state(haz, [], 1).kind_at(c)
		if kind == "cover-half" or kind == "cover-full":
			for d in Hex.DIRS:
				var t: Vector2i = c - d
				var a: Vector2i = c + d * 2
				if haz.has_tile(t) and haz.has_tile(a) and Battle.from_state(haz, [], 1).kind_at(t) == "" and Battle.from_state(haz, [], 1).kind_at(a) == "":
					found = [c, t, a, kind]
					break
		if not found.is_empty():
			break
	var cw := _mk(r, "Test Warden", "ally", "a1", found[2])
	var cg := _mk(r, "Test Grunt", "enemy", "e1", found[1])
	var bh := Battle.from_state(haz, [cw, cg], 1)
	var want_cover := 2 if found[3] == "cover-half" else 4
	ck("fight: a Barricade between the shot and its target is Cover", bh.cover_for(cg, cw) == want_cover, [found, bh.cover_for(cg, cw)])
	ck("fight: and the odds count it", _exact(bh, cw, _act(cw, "Pinning Volley"), cg) and bh.odds(cw, _act(cw, "Pinning Volley"), cg)["p"] < b.odds(w, volley, g2)["p"] + 1e-9)
	cw["pos"] = {"q": found[1].x * 2 - found[0].x, "r": found[1].y * 2 - found[0].y}
	ck("fight: from the other side it isn't", not haz.has_tile(Battle.tile_of(cw)) or bh.cover_for(cg, cw) == 0)

	# what an Action can do now, and why not
	ck("fight: an Action it can use", b.action_state(w, volley)["ok"])
	w["nrg"] = 0
	ck("fight: one it can't pay for says what it needs", b.action_state(w, volley) == {"ok": false, "why": "Needs 1 NRG"})
	w["nrg"] = 4
	ck("fight: Support with nobody beside it: nothing in reach", b.action_state(w, medic)["why"] == "Nothing in reach")
	Rules.add_status(w, "Stunned", null, "enemy", 1)
	ck("fight: a Stunned Unit can't act", b.action_state(w, volley)["why"] == "Stunned")
	w["statuses"] = []
	var lw := _mk(r, "Test Warden", "ally", "a1", Vector2i(0, 0))
	var lg := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(0, 0))
	var bl := Battle.from_state(sl, [lw, lg], 1)
	var pair := []
	for p in sl.tiles:
		for q in sl.tiles:
			if pair.is_empty() and Hex.distance(p, q) >= 2 and Hex.distance(p, q) <= 4 and not bl.sees({"q": p.x, "r": p.y}, {"q": q.x, "r": q.y}):
				pair = [p, q]
	lw["pos"] = {"q": pair[0].x, "r": pair[0].y}
	lg["pos"] = {"q": pair[1].x, "r": pair[1].y}
	ck("fight: in range but behind a wall: no line of sight", bl.action_state(lw, _act(lw, "Pinning Volley"))["why"] == "No line of sight", pair)

	# your attack
	var s2 := _mk(r, "Test Striker", "ally", "a2", Vector2i(1, 0))
	var g3 := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(4, 0))
	var b2 := Battle.from_state(cor, [s2, g3], 9)
	b2.move(s2, Vector2i(3, 0))
	ck("fight: a move can be taken back", b2.undo.size() == 1)
	var res := b2.attack(s2, _act(s2, "Shoulder Check"), g3)
	ck("fight: an attack spends the Action's Energy", s2["nrg"] == 3, s2["nrg"])
	ck("fight: and lands, or doesn't, by the dice", g3["hp"] == 18 - res["damage"] and res["pending"] == null and res["rolls"].has("penetration"), res)
	ck("fight: the target remembers who attacked it", g3["lastAttackedBy"] == "a2" and g3["attackedThisRound"] == true)
	ck("fight: it goes in the log, after the move that led to it", b2.log[0]["text"] == "Test Striker moved 2 tiles" and b2.log[1]["text"].begins_with("Test Striker used Shoulder Check on Test Grunt: "), b2.log)
	ck("fight: once the dice are rolled, the move before it stands", b2.undo.is_empty() and b2.undo_move() == null)
	g3["hp"] = 1
	var tries := 0
	while not Rules.truthy(g3.get("down")) and tries < 30:
		s2["nrg"] = 4
		b2.attack(s2, _act(s2, "Rending Blow"), g3)
		tries += 1
	ck("fight: at 0 Health a Unit is down, and the log says so", g3["down"] == true and g3["hp"] == 0 and b2.log.any(func(l): return l["text"].ends_with("Test Grunt is down")), b2.log[b2.log.size() - 1])
	ck("fight: every Enemy down: Victory", b2.settle() and b2.winner == "ally" and b2.log[b2.log.size() - 1]["text"] == "Victory in round 1." and b2.log[b2.log.size() - 1]["kind"] == "note")
	var hw := _mk(r, "Test Warden", "ally", "a1", Vector2i(0, 0))
	var hs := _mk(r, "Test Striker", "ally", "a2", Vector2i(1, 0))
	var b3 := Battle.from_state(cor, [hw, hs], 2)
	hs["hp"] = 10
	ck("fight: Support aims at a wounded ally beside it", b3.targets_for(hw, _act(hw, "Field Medicine")) == [hs])
	b3.attack(hw, _act(hw, "Field Medicine"), hs)
	ck("fight: and heals by what its text says (heal 5)", hs["hp"] == 15 and b3.log.any(func(l): return l["text"] == "Test Striker heals 5"), b3.log)

	# an Enemy's own turn
	var es := _mk(r, "Test Striker", "ally", "a2", Vector2i(3, 0))
	var eg := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(4, 0))
	var b4 := Battle.from_state(cor, [es, eg], 4)
	var beats := b4.enemy_turn(eg)
	ck("fight: an Enemy beside you attacks, with its Combo's first Action", beats.size() == 1 and beats[0]["type"] == "attack" and beats[0]["action"]["name"] == "Jab" and beats[0]["target"] == "a2" and eg["comboAt"] == 1, beats)
	ck("fight: and says why it chose you", beats[0]["line"].begins_with("Test Grunt used Jab on Test Striker (closest): "), beats[0]["line"])
	var beats2 := b4.enemy_turn(eg)
	ck("fight: then the next in its Combo, and round again", beats2[0]["action"]["name"] == "Bash" and eg["comboAt"] == 0, [beats2[0]["action"]["name"], eg["comboAt"]])
	var fs := _mk(r, "Test Striker", "ally", "a2", Vector2i(-6, 0))
	var fg := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(7, 0))
	var b5 := Battle.from_state(cor, [fs, fg], 4)
	var mv := b5.enemy_turn(fg)
	var walk_ok: bool = mv.size() >= 1 and mv[0]["type"] == "move" and mv[0]["path"][mv[0]["path"].size() - 1] == Battle.tile_of(fg) and mv[0]["path"].size() <= 3
	var prev: Vector2i = Vector2i(7, 0)
	for h in mv[0]["path"] if not mv.is_empty() else []:
		walk_ok = walk_ok and Hex.distance(prev, h) == 1
		prev = h
	ck("fight: one far off closes in, as far as its Movement Speed, a tile at a time", walk_ok and Hex.distance(Battle.tile_of(fg), Vector2i(-6, 0)) == 10, mv)
	ck("fight: and, out of reach still, doesn't attack (the simulator let it strike from afar)", mv.size() == 2 and mv[1]["type"] == "skip" and "nothing in reach" in mv[1]["line"] and fs["hp"] == fs["hpMax"], mv)
	var cs := _mk(r, "Test Striker", "ally", "a2", Vector2i(3, 0))
	var cg2 := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(4, 0))
	cg2["behaviors"] = [{"k": "cowardly", "x": 10}]
	cg2["hp"] = 5
	var b6 := Battle.from_state(cor, [cs, cg2], 4)
	var cb := b6.enemy_turn(cg2)
	ck("fight: a Cowardly Enemy, broken, backs off and takes no Action", cb.size() == 2 and cb[0]["type"] == "move" and Hex.distance(Battle.tile_of(cg2), Vector2i(3, 0)) > 1 and cb[1]["type"] == "skip" and "does not act" in cb[1]["line"], cb)

	# the round turning over
	var rh := _mk(r, "Test Warden", "ally", "a1", Vector2i(0, 0))
	var rt := _mk(r, "Test Drone", "ally", "a2", Vector2i(1, 0))
	var re := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(6, 0))
	var b7 := Battle.from_state(cor, [rh, rt, re], 4)
	rh["nrg"] = 1
	rt["nrg"] = 0
	b7.move(rt, Vector2i(2, 0))
	Rules.add_status(re, "Bleed", null, "player", 2)
	b7.end_round()
	ck("fight: the round turns over: a Hero carries its Energy over", rh["nrg"] == 1 + rh["nrgMax"], rh["nrg"])
	ck("fight: a Troop starts again full", rt["nrg"] == rt["nrgMax"])
	ck("fight: everyone may move again, and it's the next round", b7.round == 2 and b7.can_move(rt) and b7.log.any(func(l): return l["text"] == "Round 2"))
	ck("fight: statuses tick as it begins", b7.log.any(func(l): return l["text"].begins_with("Test Grunt takes") and "Bleed" in l["text"]), b7.log)
	ck("fight: and nothing from before can be taken back", b7.undo.is_empty())
	rh["hp"] = 0
	rh["down"] = true
	ck("fight: every Hero down is a Defeat, even with Troops standing", b7.outcome() == {"over": true, "winner": "enemy"})
	x.close()


# ---------------------------------------------------------------- what cards say (the effect engine)
## Makes an attack sure to land: the To-Hit can't be missed, and there's no armour to stop it.
func _sure(a: Dictionary, t: Dictionary) -> void:
	a["hit"] = 1
	t["ac"] = 0
	t["integrity"] = 0


func _texts(b: Battle, from := 0) -> Array:
	return b.log.slice(from).map(func(l): return l["text"])


func _effects() -> void:
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)
	var cor: FloorData = _floor_named(x, "TEST · Corridor")
	var haz: FloorData = _floor_named(x, "TEST · Hazards and Cover")
	ck("effects: the keyword library knows the cards' Archetypes", Keywords.by_name("Light Infantry") != null and Keywords.by_name("Light Infantry").get("narrow") == "archetype")
	ck("effects: card text reads as on the card, no marks, distances in tiles", Keywords.render("[[when]] [[this Unit]] [[is Incapacitated]], [[all enemies within 1]] take [[damage 3]].") == "When this Unit is Incapacitated, all enemies within 1 tile take damage 3.")

	# an Action's text is carried out when it lands
	var w := _mk(r, "Test Warden", "ally", "a1", Vector2i(0, 0))
	var g := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(3, 0))
	var b := Battle.from_state(cor, [w, g], 3, r.cards)
	var volley := _act(w, "Pinning Volley")
	_sure(volley, g)
	var res := b.attack(w, volley, g)
	ck("effects: an Action's damage, then what its text adds (damage 2)", res["damage"] == 4 and g["hp"] == 18 - 4 - 2, g["hp"])
	var pinned = Rules.status_of(g, "Pinned")
	ck("effects: and the status it gives, for as long as it says (Pinned, 2 turns)", pinned != null and pinned["turns"] == 2, g["statuses"])
	ck("effects: each thing it did is a line in the log", _texts(b).has("Test Grunt takes 2 damage") and _texts(b).has("Test Grunt gains Pinned for 2 turns"), _texts(b))
	ck("effects: and rises off the Unit: damage in red, a status that harms too", b.floats.any(func(f): return f["unit"] == "e1" and f["text"] == "-2 HP" and f["kind"] == "damage") and b.floats.any(func(f): return f["unit"] == "e1" and f["text"] == "Pinned" and f["kind"] == "debuff"), b.floats)
	ck("effects: a Passive hears it: the Grunt, attacked, hardens (AC +1 for a turn)", g["mods"].any(func(m): return m["stat"] == "AC" and m["amt"] == 1 and m["source"] == "Thick Skull"), g["mods"])
	var g0 := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(3, 0))
	var b0 := Battle.from_state(cor, [w, g0], 3, r.cards)
	volley["hit"] = 99
	w["nrg"] = 4
	b0.attack(w, volley, g0)
	ck("effects: a miss carries nothing out", g0["hp"] == 18 and not Rules.has_status(g0, "Pinned") and b0.floats.is_empty(), [g0["hp"], g0["statuses"]])

	# Push
	var s := _mk(r, "Test Striker", "ally", "a2", Vector2i(0, 0))
	var pg := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(1, 0))
	var bp := Battle.from_state(cor, [s, pg], 3, r.cards)
	var check := _act(s, "Shoulder Check")
	_sure(check, pg)
	bp.attack(s, check, pg)
	ck("effects: Push 2 sends it two tiles straight back", Battle.tile_of(pg) == Vector2i(3, 0) and _texts(bp).has("Test Grunt pushed 2 tiles"), [Battle.tile_of(pg), _texts(bp)])
	s["pos"] = {"q": 3, "r": -1}
	pg["pos"] = {"q": 4, "r": -1}
	s["nrg"] = 4
	var hp1: int = pg["hp"]
	bp.attack(s, check, pg)
	ck("effects: into a wall it stops, and takes 1 damage a tile it couldn't go", Battle.tile_of(pg) == Vector2i(4, -1) and pg["hp"] == hp1 - 4 - 2 and _texts(bp).has("Test Grunt hit a wall: 2 damage to Test Grunt"), [pg["hp"], hp1, _texts(bp)])
	ck("effects: the game shows that number too, as its own", bp.floats.any(func(f): return f["unit"] == "e1" and f["text"] == "-2 HP" and f.get("own", false)), bp.floats)
	var pg2 := _mk(r, "Test Grunt", "enemy", "e2", Vector2i(6, 0))
	pg2["name"] = "Test Grunt 2"
	bp.units.append(pg2)
	s["pos"] = {"q": 4, "r": 0}
	pg["pos"] = {"q": 5, "r": 0}
	pg["hp"] = 18
	s["nrg"] = 4
	bp.attack(s, check, pg)
	ck("effects: into another Unit, both take it", pg2["hp"] == 16 and pg["hp"] == 18 - 4 - 2 and _texts(bp).has("Test Grunt hit Test Grunt 2: 2 damage to Test Grunt and Test Grunt 2"), [pg["hp"], pg2["hp"]])

	# [if]: what the Action itself just did
	var rs := _mk(r, "Test Striker", "ally", "a2", Vector2i(0, 0))
	var rg := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(1, 0))
	var br := Battle.from_state(cor, [rs, rg], 3, r.cards)
	var rend := _act(rs, "Rending Blow")
	rg["ac"] = 99
	br.attack(rs, rend, rg)
	# (0.13: what an attack carries needs it to Penetrate, so the [if] isn't even asked)
	ck("effects: a blow that doesn't get through carries nothing it says, and says why", not Rules.has_status(rg, "Bleed") and _texts(br).any(func(t): return t.ends_with("did not Penetrate Armor Class")) and not _texts(br).any(func(t): return t.ends_with("— not met")), _texts(br))
	_sure(rend, rg)
	rs["nrg"] = 4
	br.attack(rs, rend, rg)
	ck("effects: one that does: Bleed, and Sundered 2, for 3 turns", Rules.has_status(rg, "Bleed") and Rules.status_n(rg, "Sundered") == 2 and Rules.status_of(rg, "Sundered")["turns"] == 3, rg["statuses"])
	rg["hp"] = 1
	rs["hp"] = 20
	rs["nrg"] = 4
	var fin := _act(rs, "Finisher")
	_sure(fin, rg)
	br.attack(rs, fin, rg)
	ck("effects: [if] this Unit kills an enemy: the Striker heals 4", rg["down"] == true and rs["hp"] == 24 and br.floats.any(func(f): return f["unit"] == "a2" and f["text"] == "+4 HP" and f["kind"] == "heal"), [rs["hp"], br.floats])

	# always on: a Passive with no [when]
	var fs := _mk(r, "Test Striker", "ally", "a2", Vector2i(0, 0))
	var fd := _mk(r, "Test Drone", "ally", "a3", Vector2i(-1, 0))
	var fg := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(1, 0))
	var bf := Battle.from_state(cor, [fs, fd, fg], 3, r.cards)
	bf.deploy_start()
	ck("effects: an always-on Passive is on from the start (the Drone flies)", Rules.effective(fd)["flying"] == true and bf.odds(fg, _act(fg, "Jab"), fd)["p"] == 0.0)
	ck("effects: [while] not yet met, nothing", bf.odds(fs, _act(fs, "Shoulder Check"), fg)["dmg"] == 4)
	fs["hp"] = 10
	bf.fx.apply_continuous()
	ck("effects: [while] this Unit is below half HP: +2 DMG, worked out afresh", bf.odds(fs, _act(fs, "Shoulder Check"), fg)["dmg"] == 6 and fs["mods"].any(func(m): return m["dur"] == "passive" and m["stat"] == "DMG"), fs["mods"])
	fs["hp"] = 30
	bf.fx.apply_continuous()
	ck("effects: and off again when it isn't", bf.odds(fs, _act(fs, "Shoulder Check"), fg)["dmg"] == 4)

	# Burst
	var d := _mk(r, "Test Drone", "ally", "a3", Vector2i(0, 0))
	var bg1 := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(3, 0))
	var bg2 := _mk(r, "Test Grunt", "enemy", "e2", Vector2i(3, -1))
	var bb := Battle.from_state(cor, [d, bg1, bg2], 3, r.cards)
	var rapid := _act(d, "Rapid Fire")
	_sure(rapid, bg1)
	_sure(rapid, bg2)
	var r1 := bb.attack(d, rapid, bg1)
	ck("effects: a Burst 3 has two more to make, and says who each could go to", r1.get("burst") == {"left": 2, "pool": ["e1", "e2"]}, r1.get("burst"))
	var r2 := bb.attack(d, rapid, bg2, r1["burst"]["left"] - 1)
	var r3 := bb.attack(d, rapid, bg1, r2["burst"]["left"] - 1)
	ck("effects: three attacks, each rolled and carried out on its own", not r3.has("burst") and bg1["hp"] == 18 - 3 - 3 and bg2["hp"] == 18 - 3 and _texts(bb).filter(func(t): return t.begins_with("Test Drone used Rapid Fire")).size() == 3, [bg1["hp"], bg2["hp"]])
	ck("effects: for one payment of Energy", d["nrg"] == 1, d["nrg"])
	bg2["down"] = true
	bg1["hp"] = 1
	d["nrg"] = 3
	var r4 := bb.attack(d, rapid, bg1)
	ck("effects: a Burst ends when nothing is left in reach", not r4.has("burst") and _texts(bb).has("The Burst ends: nothing left in reach"), _texts(bb).slice(-3))

	# an area: the preview is what happens
	var sp := _mk(r, "Test Sapper", "ally", "a4", Vector2i(0, 0))
	var aw := _mk(r, "Test Warden", "ally", "a1", Vector2i(2, 0))
	var ag := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(3, 0))
	var ag2 := _mk(r, "Test Grunt", "enemy", "e2", Vector2i(3, -1))
	ag2["name"] = "Test Grunt 2"
	var ag3 := _mk(r, "Test Grunt", "enemy", "e3", Vector2i(6, 0))
	var ba := Battle.from_state(cor, [sp, aw, ag, ag2, ag3], 3, r.cards)
	var charge := _act(sp, "Satchel Charge")
	ck("effects: an Action with an AoE has an area; one without doesn't", Effects.has_area(charge) and Effects.aoe_of(charge) == 1 and not Effects.has_area(_act(aw, "Pinning Volley")))
	var pv: Dictionary = ba.fx.area_preview(sp, charge, ag)
	ck("effects: its preview: everyone within the blast but the target, your own named", pv["radius"] == 1 and pv["caught"].map(func(u): return u["id"]) == ["a1", "e2"] and pv["own"].map(func(u): return u["id"]) == ["a1"], pv["caught"].map(func(u): return u["id"]))
	ck("effects: nothing has happened yet", ba.log.is_empty() and ag["hp"] == 18 and sp["nrg"] == 3)
	_sure(charge, ag)
	var before := {"a1": aw["hp"], "e2": ag2["hp"], "e3": ag3["hp"]}
	ba.attack(sp, charge, ag)
	ck("effects: fired, the blast carries its damage to exactly those", aw["hp"] == before["a1"] - 3 and ag2["hp"] == before["e2"] - 3 and ag3["hp"] == before["e3"] and _texts(ba).has("AoE 1 also hits Test Warden, Test Grunt 2 for 3"), _texts(ba))
	ck("effects: an Enemy never drops one on its own side", ba.fx.hurts_own_side(ag3, charge, aw) == true and ba.fx.hurts_own_side(ag3, charge, sp) == false and ba.fx.hurts_own_side(sp, charge, ag) == true)
	var wide := {"name": "Shockwave", "tag": "Active", "role": "ranged", "rng": 5, "hit": 1, "pen": 9, "dmg": 1, "cost": 0, "text": "[[all enemies within 1]] gain [[Slowed 1]]."}
	var pv2: Dictionary = ba.fx.area_preview(sp, wide, ag)
	ck("effects: 'all enemies within 1' takes in only Enemies", Effects.has_area(wide) and pv2["caught"].map(func(u): return u["id"]) == ["e2"] and pv2["own"].is_empty(), pv2["caught"].map(func(u): return u["id"]))

	# [when]: Passives that listen
	var ds := _mk(r, "Test Sapper", "ally", "a4", Vector2i(0, 0))
	var dg := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(1, 0))
	var dg2 := _mk(r, "Test Grunt", "enemy", "e2", Vector2i(3, 0))
	var hero := _mk(r, "Test Warden", "ally", "a1", Vector2i(-4, 0))
	var bd := Battle.from_state(cor, [hero, ds, dg, dg2], 3, r.cards)
	ds["hp"] = 10
	bd.end_round()
	ck("effects: [when] the round begins: the Sapper patches itself (heal 1)", ds["hp"] == 11 and _texts(bd).has("Test Sapper heals 1"), [ds["hp"], _texts(bd)])
	ds["hp"] = 0
	bd.check_downs()
	ck("effects: [when] this Unit is Incapacitated: its charge goes off on Enemies within 1", ds["down"] == true and dg["hp"] == 15 and dg2["hp"] == 18 and _texts(bd).has("Test Grunt takes 3 damage"), [dg["hp"], dg2["hp"], _texts(bd)])
	var bw := _mk(r, "Test Warden", "ally", "a1", Vector2i(0, 0))
	var bat := _mk(r, "Test Battery", "ally", "a5", Vector2i(1, 0))
	bw["hp"] = 20
	var bbat := Battle.from_state(cor, [bw, bat], 3, r.cards)
	bbat.deploy_start()
	ck("effects: [when] this Unit is deployed: the Battery's jump start heals those within 2", bw["hp"] == 22, bw["hp"])
	bbat.attack(bat, _act(bat, "Overcharge"), bw)
	ck("effects: Sacrifice spends the Unit; its allies within 2 gain +1 MS for 2 turns", bat["down"] == true and bbat.speed(bw) == 5 and _texts(bbat).has("Test Battery is Sacrificed"), [bat.get("down"), bbat.speed(bw), _texts(bbat)])
	var sc := _mk(r, "Test Scout", "ally", "a6", Vector2i(-6, 0))
	var hk := _mk(r, "Test Hacker", "enemy", "e1", Vector2i(7, 0))
	var bs := Battle.from_state(cor, [sc, hk], 3, r.cards)
	bs.enemy_turn(hk)
	ck("effects: [when] a Support or Cyber enemy moves, that Unit is Marked (the Scout's Spotter)", Rules.has_status(hk, "Marked") and Battle.tile_of(hk) != Vector2i(7, 0), hk["statuses"])

	# hazards
	var hw := _mk(r, "Test Warden", "ally", "a1", Vector2i(-3, 1))
	var hg := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(6, -6))
	var bh := Battle.from_state(haz, [hw, hg], 3, r.cards)
	ck("effects: the floor's hazards, and what one does in a few words", haz.hazards.size() == 5 and bh.hazard_words(Vector2i(-2, 1)) == "AC: 2 damage and Poisoned" and bh.hazard_words(Vector2i(0, 0)) == "", [haz.hazards.size(), bh.hazard_words(Vector2i(-2, 1))])
	bh.move(hw, Vector2i(-2, 1))
	ck("effects: moving onto a hazard bites: 2 damage and Poisoned", hw["hp"] == 28 and Rules.has_status(hw, "Poisoned") and _texts(bh).has("Test Warden moves onto AC: 2 damage and Poisoned"), [hw["hp"], _texts(bh)])
	ck("effects: and the game shows it rising off the Unit", bh.floats.any(func(f): return f["unit"] == "a1" and f["text"] == "-2 HP" and f.get("own", false)) and bh.floats.any(func(f): return f["text"] == "Poisoned"), bh.floats)
	var back = bh.undo_move()
	ck("effects: taking the move back takes back everything it set off", back != null and hw["hp"] == 30 and not Rules.has_status(hw, "Poisoned") and Battle.tile_of(hw) == Vector2i(-3, 1) and bh.log.is_empty() and bh.floats.is_empty() and bh.can_move(hw), [hw["hp"], hw["statuses"], bh.log])
	bh.move(hw, Vector2i(-2, 1))
	bh.end_round()
	ck("effects: ending the round on it bites again, then the poison ticks as the next begins", _texts(bh).has("Test Warden ends its turn on AC: 2 damage and Poisoned") and _texts(bh).any(func(t): return t.begins_with("Test Warden takes") and t.ends_with("from Poisoned")) and hw["hp"] < 26, [hw["hp"], _texts(bh)])
	var eg := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(-2, 0))
	var et := _mk(r, "Test Warden", "ally", "a1", Vector2i(-2, 3))
	var be := Battle.from_state(haz, [et, eg], 3, r.cards)
	be.enemy_turn(eg)
	ck("effects: an Enemy walks round a hazard when there's a way round", not haz.hazards.has(Battle.tile_of(eg)) and eg["hp"] == 18 and Hex.distance(Battle.tile_of(eg), Vector2i(-2, 3)) < 3, Battle.tile_of(eg))

	# holding fire (Suppressive Fire)
	var ow := _mk(r, "Test Warden", "ally", "a1", Vector2i(0, 0))
	var og := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(7, 0))
	var bo := Battle.from_state(cor, [ow, og], 3, r.cards)
	ck("effects: an Action with Suppressive Fire can be held", bo.holdable(ow).map(func(a): return a["name"]) == ["Overwatch"])
	bo.undo.append({})
	var held := bo.hold_fire(ow, "Overwatch")
	ck("effects: holding pays its Energy now, and can't be taken back", held and ow["nrg"] == 2 and ow["holding"]["name"] == "Overwatch" and bo.undo.is_empty(), [ow["nrg"], ow.get("holding")])
	_sure(_act(ow, "Overwatch"), og)
	var beats := bo.enemy_turn(og)
	ck("effects: the first Enemy to move into its reach is shot as it moves", beats.map(func(bt): return bt["type"]) == ["move", "react", "skip"] and beats[1]["unit"] == "a1" and beats[1]["target"] == "e1" and beats[1]["res"]["damage"] == 5 and og["hp"] == 13 and ow["holding"] == null, [beats.map(func(bt): return bt["type"]), og["hp"]])
	ck("effects: each beat of the turn carries how things stood when it was over", beats[0]["after"].filter(func(u): return u["id"] == "e1")[0]["hp"] == 18 and beats[1]["after"].filter(func(u): return u["id"] == "e1")[0]["hp"] == 13 and beats[1]["lines"][0].begins_with("Test Warden reacts with Overwatch as Test Grunt moves: 5 damage") and beats[0]["path"].size() == 3, beats[1]["lines"])
	var ow2 := _mk(r, "Test Warden", "ally", "a1", Vector2i(3, 0))
	var og2 := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(7, 0))
	og2["hp"] = 3
	var bo2 := Battle.from_state(cor, [ow2, og2], 3, r.cards)
	bo2.hold_fire(ow2, "Overwatch")
	_sure(_act(ow2, "Overwatch"), og2)
	var beats2 := bo2.enemy_turn(og2)
	ck("effects: one brought down by it mid-move doesn't go on to attack (the simulator let it)", og2["down"] == true and beats2.map(func(bt): return bt["type"]) == ["move", "react"] and ow2["hp"] == 30, [beats2.map(func(bt): return bt["type"]), ow2["hp"]])
	var ow3 := _mk(r, "Test Warden", "ally", "a1", Vector2i(-6, 0))
	var og3 := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(7, 0))
	var bo3 := Battle.from_state(cor, [ow3, og3], 3, r.cards)
	bo3.hold_fire(ow3, "Overwatch")
	bo3.enemy_turn(og3)
	bo3.end_round()
	ck("effects: a hold nobody walks into lapses with the round", ow3["holding"] == null and _texts(bo3).has("Test Warden's hold lapses; nothing came into range"), _texts(bo3))

	# Deploy, Chain, an Aura
	var ov := _mk(r, "Test Overseer", "enemy", "e1", Vector2i(4, 0))
	var vw := _mk(r, "Test Warden", "ally", "a1", Vector2i(0, 0))
	var vs := _mk(r, "Test Striker", "ally", "a2", Vector2i(-2, 0))
	var bv := Battle.from_state(cor, [vw, vs, ov], 3, r.cards)
	bv.deploy_start()
	ck("effects: an Aura reaches only as far as its radius", not Rules.has_status(vw, "Weakened") and not Rules.has_status(vs, "Weakened"))
	vw["pos"] = {"q": 2, "r": 0}
	bv.fx.apply_continuous()
	ck("effects: step inside it and it's on you (Weakened 1), step out and it's gone", Rules.status_n(vw, "Weakened") == 1 and Rules.status_of(vw, "Weakened")["source"] == "aura:e1", vw["statuses"])
	var lash := _act(ov, "Arc Lash")
	_sure(lash, vw)
	vs["pos"] = {"q": 0, "r": 0}
	var vs0: int = vs["hp"]
	bv.attack(ov, lash, vw)
	ck("effects: Chain 3 jumps to the nearest other within 3, for the same", vs["hp"] == vs0 - 5 and _texts(bv).has("Chain jumps to Test Striker for 5"), [vs["hp"], _texts(bv)])
	bv.fx.run_text("[[Deploy 1 Test Grunt]] [[adjacent]].", {"actor": ov, "sourceCard": "Call Reinforcement"})
	var put = bv.unit_by_id("d1")
	ck("effects: Deploy puts a new Unit beside whoever called it", put != null and put["side"] == "enemy" and put["name"] == "Test Grunt" and Hex.distance(Battle.tile_of(put), Battle.tile_of(ov)) == 1 and _texts(bv).has("Test Overseer deploys 1 Test Grunt"), _texts(bv).slice(-2))

	# what a card can't do, it says
	var cw := _mk(r, "Test Warden", "ally", "a1", Vector2i(0, 0))
	var cg := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(3, 0))
	var bc := Battle.from_state(cor, [cw, cg], 3, r.cards)
	var odd := _act(cw, "Pinning Volley")
	_sure(odd, cg)
	odd["text"] = "[[target enemy]] gains [[AC +2]]."
	bc.attack(cw, odd, cg)
	ck("effects: an effect that can't be carried out stops the fight to say so, naming the card", bc.halts.size() == 1 and bc.halts[0].begins_with("Pinning Volley: ") and "Duration" in bc.halts[0] and bc.log.any(func(l): return l.get("halt", false)), bc.halts)
	ck("effects: and the fight goes on without it", cg["hp"] == 14 and not cg["mods"].any(func(m): return m["amt"] == 2))
	odd["text"] = "[[target enemy]] is [[Zapped 3]]."
	cw["nrg"] = 4
	bc.attack(cw, odd, cg)
	ck("effects: a keyword the library doesn't have is said too", bc.halts.size() == 2 and "not in the keyword library" in bc.halts[1], bc.halts)
	odd["text"] = "Looks menacing."
	cw["nrg"] = 4
	bc.attack(cw, odd, cg)
	var let_go: WeakRef = weakref(Battle.from_state(cor, [_mk(r, "Test Warden", "ally", "a1", Vector2i(0, 0))], 1, r.cards))
	ck("effects: a battle that's over is let go, effect engine and all (neither keeps the other)", let_go.get_ref() == null)
	Rules.add_status(cw, "Marked", null, "test", 1)
	ck("effects: and the rules don't call on one that has gone", Rules.has_status(cw, "Marked"))
	ck("effects: text that isn't keywords is logged as not carried out, and doesn't stop anything", bc.halts.size() == 2 and bc.log.any(func(l): return l.get("plain", false) and l["text"] == "Not carried out — Pinning Volley has plain text: Looks menacing."), _texts(bc).slice(-2))
	x.close()


# ---------------------------------------------------------------- setting up
func _setup() -> void:
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)
	var s := SetupScreen.new()
	root.add_child(s)
	s.set_content(r, x.floors())
	await process_frame
	ck("setup: starts with the floors", s.step == "floor" and s._rows.size() == s.floors.size() and s.next_btn.disabled)
	var wi := -1
	for i in s.floors.size():
		if s.floors[i].name == "TEST · Waves":
			wi = i
	# a tap on the row, as the list sees it
	await process_frame
	var row: Control = s._rows[wi]["row"]
	s.list.tap(row.position + s.list.box.position + Vector2(40, 20))
	ck("setup: tap a floor to choose it", s.floor_i == wi and not s.next_btn.disabled, s.floor_i)
	s._go(1)
	ck("setup: then the Heroes", s.step == "heroes" and s._rows.size() == 9 and s.next_btn.disabled)
	s.toggle_hero("Test Warden")
	s.toggle_hero("Rictus")
	s.toggle_hero("Test Striker")
	ck("setup: no more Heroes than the floor lets in, and it says so", s.heroes == ["Test Warden", "Rictus"] and "Only 2" in s.note.text, [s.heroes, s.note.text])
	s.toggle_hero("Rictus")
	s.toggle_hero("Test Striker")
	ck("setup: tap a chosen one to leave it behind", s.heroes == ["Test Warden", "Test Striker"] and s.note.text == "")
	s._go(1)
	ck("setup: then the Troops, with the pooled Leadership", s.step == "troops" and s.pooled_leadership() == 6 and s.next_btn.text == "Start battle" and "0 of 6" in s.hint.text, s.hint.text)
	s.more_troop("Test Drone")
	s.more_troop("Test Drone")
	s.more_troop("Aetherium Golem")
	ck("setup: a Troop that doesn't fit is refused, and it says why", s.troops == {"Test Drone": 2} and "5 Unit Slots" in s.note.text and "4 of 6" in s.note.text, [s.troops, s.note.text])
	s.more_troop("Frame Trooper")
	s.less_troop("Test Drone")
	ck("setup: more and fewer", s.troops == {"Test Drone": 1, "Frame Trooper": 1} and s.used_slots() == Roster.slots(r.card_named("Test Drone")) + Roster.slots(r.card_named("Frame Trooper")), s.troops)
	await process_frame
	await process_frame
	# the minus on a row, and the row itself, as the list sees a tap
	var fe: Dictionary = {}
	for e in s._rows:
		if e.get("troop") == "Frame Trooper":
			fe = e
	var minus: Control = fe["minus"]
	var at: Vector2 = minus.global_position - s.list.global_position + minus.size / 2
	s.list.tap(at)
	ck("setup: the minus on a row takes one away", not s.troops.has("Frame Trooper"), s.troops)
	for e in s._rows:
		if e.get("troop") == "Frame Trooper":
			fe = e
	var body: Control = fe["row"]
	s.list.tap(body.global_position - s.list.global_position + Vector2(200, 30))
	ck("setup: the rest of the row adds one", s.troops.get("Frame Trooper", 0) == 1, s.troops)
	# a drag scrolls, and never picks
	var before := s.troops.duplicate()
	var t0 := InputEventScreenTouch.new()
	t0.position = Vector2(300, 300)
	t0.pressed = true
	s.list._gui_input(t0)
	var dr := InputEventScreenDrag.new()
	dr.position = Vector2(300, 200)
	dr.relative = Vector2(0, -100)
	s.list._gui_input(dr)
	var t1 := InputEventScreenTouch.new()
	t1.position = Vector2(300, 200)
	t1.pressed = false
	s.list._gui_input(t1)
	ck("setup: dragging scrolls the list and picks nothing", s.list.scroll > 50 and s.troops == before, [s.list.scroll, s.troops])
	var keep := s.list.scroll
	s.more_troop("Test Drone")
	ck("setup: and it keeps its place when a row changes", absf(s.list.scroll - keep) < 1.0, [keep, s.list.scroll])
	s._go(-1)
	s.toggle_hero("Test Striker")
	ck("setup: fewer Heroes, less Leadership: the last Troops step down", s.pooled_leadership() == 4 and s.used_slots() <= 4, [s.troops, s.used_slots()])
	s.toggle_hero("Test Striker")
	s._go(1)
	var got := []
	s.start_requested.connect(func(fi, h, t): got.append([fi, h.map(func(c): return c["name"]), t.map(func(c): return c["name"])]))
	s._go(1)
	ck("setup: Start battle hands over the floor, the Heroes and each Troop", got.size() == 1 and got[0][0] == wi and got[0][1] == ["Test Warden", "Test Striker"] and got[0][2].size() == s.troop_order.reduce(func(a, n): return a + s.troops[n], 0), got)
	s.show_message("Nothing here.")
	ck("setup: with nothing to set up from, it says why and offers Look again", s.hint.text == "Nothing here." and s.again_btn.visible and s.next_btn.disabled and s._rows.is_empty())
	s.queue_free()
	x.close()


# ---------------------------------------------------------------- the screen
func _screen_at(scene: Node, h: Vector2i) -> Vector2:
	return scene.get_viewport().get_canvas_transform() * (scene.board.to_global(Board.at(h)))


func _tap(scene: Node, h: Vector2i) -> void:
	var p := _screen_at(scene, h)
	_touch(scene, 0, p, true)
	_touch(scene, 0, p, false)


func _main_scene() -> void:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	ck("screen: it opens at home", scene.home.visible and not scene.setup.visible and not scene.teams_screen.visible and scene.home.title.text == "KETER")
	ck("screen: with no export there, it says how to add one, and nothing can be started", "Export for Godot" in scene.home.note.text and scene.home.battle_btn.disabled and scene.home.quick_btn.disabled and scene.home.teams_btn.disabled and scene.home.again_btn.visible, scene.home.note.text)
	scene.open_setup("quick")
	scene.open_teams()
	ck("screen: nor opened another way", scene.home.visible and not scene.setup.visible and not scene.teams_screen.visible)
	var loaded: bool = scene.load_export(FIXTURE)
	await process_frame
	ck("screen: loads the export: Battle, Quick battle and Strike Teams", loaded and scene.home.visible and not scene.home.battle_btn.disabled and not scene.home.quick_btn.disabled and not scene.home.teams_btn.disabled)
	ck("screen: says where it came from", "export.zip" in scene.home.source.text and "Companion" in scene.home.source.text, scene.home.source.text)
	ck("screen: with no Strike Team yet, it says to build one or fight a Quick battle", "No Strike Teams yet" in scene.home.note.text, scene.home.note.text)
	scene.home.quick_btn.pressed.emit()
	await process_frame
	ck("screen: Quick battle starts setting one up, at the floors", scene.setup.visible and not scene.home.visible and scene.setup.mode == "quick" and scene.setup.title.text == "Quick battle" and scene.setup.floors.size() >= 4 and scene.setup._rows.size() == scene.floors.size() and "export.zip" in scene.setup.hint.text)
	ck("screen: the board waits until the battle starts", scene.battle == null and not scene.aether_btn.visible and not scene.hand_btn.visible)
	var ci := -1
	for i in scene.floors.size():
		if scene.floors[i].name == "TEST · Corridor":
			ci = i
	var r: Roster = scene.roster
	scene.setup.start_requested.emit(ci, [r.card_named("Test Warden"), r.card_named("Test Striker")], [r.card_named("Test Drone")])
	await process_frame
	var b: Board = scene.board
	var bt: Battle = scene.battle
	ck("screen: Start battle puts the floor on the board", bt != null and b.floor_data.name == "TEST · Corridor" and not scene.setup.visible and not scene.home.visible and scene.next_btn.text == "End turn" and scene.round_label.text == "Round 1" and scene.floor_label.text == "TEST · Corridor")
	ck("screen: every Unit on it, in its tile", b.views.size() == bt.units.size() and bt.units.all(func(u): return b.view_of(u["id"]).position.is_equal_approx(Board.at(Battle.tile_of(u)))))
	var warden: Dictionary = bt.side_units("ally")[0]
	var wv := b.view_of(warden["id"])
	ck("screen: a Unit with a token wears it; one without shows letters", wv.token.texture != null and b.view_of(bt.side_units("enemy")[0]["id"]) != null)
	ck("screen: yours outlined cyan, Enemies red", wv.unit["side"] == "ally" and UnitView.ALLY != UnitView.ENEMY)
	# tap a Unit: the panel, and the tiles it can reach
	_tap(scene, Battle.tile_of(warden))
	await process_frame
	ck("screen: tap a Unit and the side panel shows it", scene.panel.visible and scene.panel.name_label.text == "Test Warden" and "Yours" in scene.panel.side_label.text, scene.panel.name_label.text)
	ck("screen: its numbers: HP, AC, MS, NRG, INT", scene.panel.stats_box.get_child_count() == 5)
	ck("screen: and the tiles it can reach are lit", b.reach.size() == bt.reach(warden).size() and b.reach.size() > 0 and wv.selected)
	var target := Vector2i(-3, 0)
	var cost: int = b.reach.get(target, -1)
	_tap(scene, target)
	await process_frame
	ck("screen: tap a lit tile and it sets off, showing the way", scene.walking and b.path.size() == cost and b.path[b.path.size() - 1] == target, [cost, b.path])
	var n := 0
	while scene.walking and n < 300:
		await process_frame
		n += 1
	ck("screen: it walks there, a tile at a time", not scene.walking and Battle.tile_of(warden) == target and wv.position.is_equal_approx(Board.at(target)), [Battle.tile_of(warden), n])
	ck("screen: then it is dimmed, and the lit tiles go", wv.dim and b.reach.is_empty() and b.path.is_empty() and ("moved %d tiles" % cost) in scene.info.text, scene.info.text)
	_tap(scene, target)
	await process_frame
	ck("screen: a Unit that has moved says so, and lights nothing", scene.panel.visible and b.reach.is_empty() and "has moved" in scene.info.text, scene.info.text)
	# an Enemy: its panel, read-only; it acts on its own
	var foe: Dictionary = bt.side_units("enemy")[0]
	_tap(scene, Battle.tile_of(foe))
	await process_frame
	ck("screen: tap an Enemy: its panel, read-only, and nothing lit (it acts on its own)", scene.panel.side_label.text.begins_with("Enemy") and b.reach.is_empty() and "on its own" in scene.panel.move_label.text and not scene.panel._rows.any(func(r): return r.get("live", false)))
	for k in 30:
		await process_frame
	var fx: float = _screen_at(scene, Battle.tile_of(foe)).x
	ck("screen: the board slides so the panel doesn't hide it", fx < scene.get_viewport_rect().size.x - UnitPanel.WIDTH, fx)
	# tap somewhere that is neither lit nor a Unit: cancelled
	_tap(scene, Vector2i(-7, 1)) if bt.unit_at(Vector2i(-7, 1)) == null else _tap(scene, Vector2i(0, 1))
	await process_frame
	ck("screen: tap elsewhere and it's cancelled", not scene.panel.visible and b.reach.is_empty() and scene.selected_id == "")
	_tap(scene, Battle.tile_of(foe))
	_touch(scene, 0, Vector2(5, 700), true)
	_touch(scene, 0, Vector2(5, 700), false)
	ck("screen: so is a tap off the floor", not scene.panel.visible and scene.selected_id == "")
	scene.next_round()
	await process_frame
	ck("screen: End turn with Units still able to act asks first", scene.dialog != null and "can still" in scene.dialog.text_label.text and bt.round == 1, scene.dialog.text_label.text if scene.dialog != null else "")
	scene.dialog.buttons[0].pressed.emit()
	await process_frame
	ck("screen: Go back leaves the round as it was", scene.dialog == null and bt.round == 1 and not scene.enemy_phase)
	scene.next_round()
	await process_frame
	scene.dialog.buttons[1].pressed.emit()
	await process_frame
	ck("screen: End the turn, and the Enemies take theirs", scene.enemy_phase and scene.busy and scene.next_btn.disabled)
	var w0 := 0
	while scene.enemy_phase and w0 < 2000:
		await process_frame
		w0 += 1
	ck("screen: then the next round: every Unit may move again", bt.round == 2 and scene.round_label.text == "Round 2" and not wv.dim and bt.can_move(warden) and not scene.busy and not scene.next_btn.disabled, [bt.round, w0])
	# a drag pans, and is not a tap
	var cam: Camera2D = scene.camera
	var before := cam.position
	_touch(scene, 0, Vector2(600, 400), true)
	_drag(scene, 0, Vector2(700, 420), Vector2(100, 20))
	_touch(scene, 0, Vector2(700, 420), false)
	await process_frame
	ck("screen: dragging pans the board", cam.position.distance_to(before - Vector2(100, 20) / cam.zoom.x) < 0.5 and scene.selected_id == "", [before, cam.position])
	var z0 := cam.zoom.x
	_touch(scene, 0, Vector2(500, 400), true)
	_touch(scene, 1, Vector2(700, 400), true)
	_drag(scene, 1, Vector2(800, 400), Vector2(100, 0))
	_touch(scene, 1, Vector2(800, 400), false)
	_touch(scene, 0, Vector2(500, 400), false)
	await process_frame
	ck("screen: pinching zooms", cam.zoom.x > z0 * 1.3, [z0, cam.zoom.x])
	scene._fit()
	cam.force_update_scroll()
	await process_frame
	var rr := b.extent()
	var xf := scene.get_viewport().get_canvas_transform()
	var tl := xf * rr.position
	var br := xf * rr.end
	var vp := scene.get_viewport_rect().size
	ck("screen: Fit frames the whole floor below the bar", tl.x >= -1 and tl.y >= 60 and br.x <= vp.x + 1 and br.y <= vp.y + 1, [tl, br, vp])
	scene.setup.step = "troops"
	scene.setup.heroes.assign(["Test Warden"])
	scene.new_battle()
	ck("screen: setting up another goes back to the first step, choices kept", scene.setup.visible and scene.setup.step == "floor" and scene.setup.mode == "quick" and scene.setup.heroes == ["Test Warden"] and scene.battle == null)
	_tap(scene, Vector2i(-3, 0))
	ck("screen: the board ignores taps while setting up", scene.selected_id == "" and not scene.panel.visible)
	var bad_path := "user://find_test/future.zip"
	scene.setup.back_btn.pressed.emit()
	ck("screen: Home, from the first step", scene.home.visible and not scene.setup.visible and scene.setup.back_btn.text == "Home")
	ck("screen: an export it can't read says why, at home", not scene.load_export(bad_path) and scene.home.visible and "newer" in scene.home.note.text and scene.home.battle_btn.disabled, scene.home.note.text)
	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------- the screen, fighting
func _place(scene: Node, id: String, h: Vector2i) -> void:
	var u = scene.battle.unit_by_id(id)
	u["pos"] = {"q": h.x, "r": h.y}
	scene.board.view_of(id).position = Board.at(h)


func _until(scene: Node, what: String, limit := 3000) -> int:
	var n := 0
	while scene.get(what) and n < limit:
		await process_frame
		n += 1
	return n


func _fight_scene() -> void:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	var r: Roster = scene.roster
	var ci := -1
	for i in scene.floors.size():
		if scene.floors[i].name == "TEST · Corridor":
			ci = i
	scene.start_battle(ci, [r.card_named("Test Warden"), r.card_named("Test Striker")], [], 6)
	await process_frame
	var bt: Battle = scene.battle
	var striker: Dictionary = bt.unit_by_id("a2")
	var grunt: Dictionary = bt.side_units("enemy")[0]
	_place(scene, "a2", Vector2i(1, 0))
	_place(scene, grunt["id"], Vector2i(4, 0))
	scene._fit()
	await process_frame
	_tap(scene, Vector2i(1, 0))
	await process_frame
	ck("fight screen: your Unit's Actions are in its panel, greyed with the reason while nothing is in reach", scene.panel.visible and scene.panel._rows.filter(func(row): return row.has("action")).size() >= 3 and scene.panel._rows.filter(func(row): return row.has("action") and row.get("live", false)).is_empty())
	_tap(scene, Vector2i(3, 0))
	await _until(scene, "walking")
	ck("fight screen: after a move, Undo is offered", scene.undo_btn.visible and not scene.undo_btn.disabled)
	scene.undo_move()
	await process_frame
	ck("fight screen: Undo takes it back", Battle.tile_of(striker) == Vector2i(1, 0) and bt.can_move(striker) and not scene.undo_btn.visible)
	_tap(scene, Vector2i(3, 0))
	await _until(scene, "walking")
	ck("fight screen: beside an Enemy, they light up", scene.panel._rows.filter(func(row): return row.get("live", false)).size() >= 1)
	var ci2 := -1
	for i in striker["actions"].size():
		if striker["actions"][i]["name"] == "Shoulder Check":
			ci2 = i
	scene.panel.action_pressed.emit(ci2)
	await process_frame
	ck("fight screen: pick an Action and the targets it can reach light up, with their odds", scene.aiming == ci2 and scene.targets.has(grunt["id"]) and scene.overlay.tags.size() == scene.targets.size() and scene.board.view_of(grunt["id"]).targeted, scene.targets)
	ck("fight screen: the tag is the chance and the damage", scene.overlay.tags[0]["text"].ends_with("· 4") and "%" in scene.overlay.tags[0]["text"], scene.overlay.tags)
	ck("fight screen: the reach goes while aiming", scene.board.reach.is_empty())
	_tap(scene, Vector2i(2, 1)) if bt.unit_at(Vector2i(2, 1)) == null else _tap(scene, Vector2i(2, -1))
	await process_frame
	ck("fight screen: tap elsewhere and the Action is put away, the Unit still chosen", scene.aiming == -1 and scene.selected_id == "a2" and scene.overlay.tags.is_empty())
	scene.pick_action(ci2)
	scene.pick_action(ci2)
	ck("fight screen: tap the Action again and it's put away too", scene.aiming == -1)
	scene.pick_action(ci2)
	var hp0: int = grunt["hp"]
	_tap(scene, Vector2i(4, 0))
	await process_frame
	ck("fight screen: tap a lit target: the dice are rolled and shown by it", not scene.overlay.readout.is_empty() and scene.overlay.readout["lines"].size() >= 2 and "Penetration" in scene.overlay.readout["lines"][0][0], scene.overlay.readout.get("lines"))
	ck("fight screen: Health and Energy change", striker["nrg"] == 3 and grunt["hp"] <= hp0 and grunt["lastAttackedBy"] == "a2")
	ck("fight screen: the bottom line says what happened", ("Shoulder Check on " + grunt["name"]) in scene.info.text, scene.info.text)
	ck("fight screen: once rolled, the move can't be undone", not scene.undo_btn.visible)
	await _until(scene, "busy")
	ck("fight screen: then the Unit is chosen again, ready for more", scene.selected_id == "a2" and scene.aiming == -1 and not scene.busy)
	scene.toggle_log()
	ck("fight screen: the Log holds it", scene.log_panel.visible and scene.log_panel.list.rows().size() >= 2)
	scene.toggle_log()
	# the Enemies' turn, hurried by a tap
	scene.deselect()
	scene.run_enemy_phase()
	await process_frame
	_tap(scene, Vector2i(0, 0))
	ck("fight screen: a tap during the Enemies' turn hurries them", scene.fast and scene.enemy_phase)
	var n := await _until(scene, "enemy_phase")
	ck("fight screen: then it's your turn again, Energy refilled (a Hero keeps what it didn't spend)", bt.round == 2 and striker["nrg"] == 3 + striker["nrgMax"] and not scene.busy, [bt.round, striker["nrg"], n])
	ck("fight screen: what the Enemies did is in the log", bt.log.any(func(l): return l["kind"] == "act" and str(l["text"]).begins_with(grunt["name"])), bt.log)
	# the end
	for e in bt.side_units("enemy"):
		e["hp"] = 0
		e["down"] = true
	bt.settle()
	scene.show_result()
	await process_frame
	var strip_said: Array = _labels(scene.dialog.strip) if scene.dialog != null and scene.dialog.strip != null else []
	ck("fight screen: every Enemy down: Victory, with what's left standing", scene.dialog != null and scene.dialog.title_label.text == "Victory" and strip_said.any(func(s): return str(s).ends_with("yours standing")), [scene.dialog.title_label.text if scene.dialog else "", strip_said])
	ck("0.15 result: Victory in neon over a strip of how it went (the round, yours standing, theirs down)", scene.dialog != null and scene.dialog.title_art != null and scene.dialog.title_art.texture == Art.menu_piece("victory") and not scene.dialog.title_label.visible
		and strip_said.size() == 3 and strip_said.has("Round 2") and strip_said.has("2 of 2 yours standing") and strip_said.has("3 of 3 Enemies down"), strip_said)
	ck("fight screen: and nothing can be done on the board but look", scene.next_btn.disabled)
	scene.dialog.buttons[0].pressed.emit()
	await process_frame
	ck("fight screen: Play again: the same floor and team, a fresh battle", scene.battle != bt and scene.battle.floor_data.name == "TEST · Corridor" and scene.battle.side_units("ally").size() == 2 and scene.dialog == null and scene.battle.round == 1)
	var bt2: Battle = scene.battle
	for u in bt2.side_units("ally"):
		u["hp"] = 0
		u["down"] = true
	bt2.settle()
	scene.show_result()
	await process_frame
	ck("fight screen: every Hero down: Defeat", scene.dialog.title_label.text == "Defeat" and "Every Hero is down" in scene.dialog.text_label.text)
	ck("fight screen: the box offers Play again, New battle, Home and See the board", scene.dialog.buttons.map(func(b): return b.text) == ["Play again", "New battle", "Home", "See the board"])
	scene.dialog.buttons[3].pressed.emit()
	await process_frame
	ck("fight screen: See the board puts the box away", scene.dialog == null and scene.battle == bt2 and "Defeat in round" in scene.info.text, scene.info.text)
	scene.new_btn.pressed.emit()
	await process_frame
	ck("fight screen: Leave, once it's over, brings the box back", scene.dialog != null and scene.dialog.title_label.text == "Defeat")
	scene.dialog.buttons[1].pressed.emit()
	await process_frame
	ck("fight screen: New battle from there goes back to setting up", scene.setup.visible and scene.dialog == null and scene.setup.mode == "quick")
	scene.start_battle(ci, [r.card_named("Test Warden")], [], 6)
	await process_frame
	for u in scene.battle.side_units("ally"):
		u["hp"] = 0
		u["down"] = true
	scene.battle.settle()
	scene.show_result()
	await process_frame
	scene.dialog.buttons[2].pressed.emit()
	await process_frame
	ck("fight screen: Home from there goes home", scene.home.visible and scene.dialog == null and scene.battle == null and not scene.setup.visible)
	scene.queue_free()
	await process_frame


func _touch(scene: Node, index: int, pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = pos
	e.pressed = pressed
	scene._unhandled_input(e)


func _drag(scene: Node, index: int, pos: Vector2, rel: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = pos
	e.relative = rel
	scene._unhandled_input(e)


# ---------------------------------------------------------------- the screen, with what cards say
## A battle made by hand, put on the screen.
func _stage(scene: Node, f: FloorData, units: Array, seed := 6) -> Battle:
	var b := Battle.from_state(f, units, seed, scene.roster.cards)
	b.roster = scene.roster
	for u in units:
		var c = scene.roster.card_named(str(u["src"])) if u.get("src") != null else null
		b.looks[u["id"]] = scene.roster.token_for(c) if c != null else {}
	b.deploy_start()
	b.floats.clear()
	scene.show_battle(b)
	return b


func _index(u: Dictionary, name: String) -> int:
	for i in u["actions"].size():
		if u["actions"][i]["name"] == name:
			return i
	return -1


## Every line of text in the side panel's body.
func _panel_text(scene: Node) -> Array:
	var out := []
	var todo: Array = scene.panel.body.rows()
	while not todo.is_empty():
		var n: Node = todo.pop_back()
		if n is Label:
			# 0.14: the summary keeps its pairs together with non-breaking
			# spaces; the checks read the words, so they read plain spaces.
			out.append(n.text.replace(" ", " "))
		todo.append_array(n.get_children())
	return out


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## Waits for a Unit on the board to finish sliding or walking.
func _still(v: UnitView) -> void:
	var n := 0
	await process_frame
	while v.is_walking() and n < 600:
		await process_frame
		n += 1


func _effects_scene() -> void:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	var r: Roster = scene.roster
	var haz: FloorData = null
	var cor: FloorData = null
	for f in scene.floors:
		if f.name == "TEST · Hazards and Cover":
			haz = f
		if f.name == "TEST · Corridor":
			cor = f

	# ---- hazards, statuses, holding fire, a Burst
	var w := _mk(r, "Test Warden", "ally", "a1", Vector2i(-3, 1))
	var d := _mk(r, "Test Drone", "ally", "a3", Vector2i(0, 4))
	var g1 := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(2, 2))
	var g2 := _mk(r, "Test Grunt", "enemy", "e2", Vector2i(3, 1))
	g2["name"] = "Test Grunt 2"
	var bt := _stage(scene, haz, [w, d, g1, g2])
	scene._fit()
	await process_frame
	ck("effects screen: a battle made by hand goes on the board", scene.board.views.size() == 4 and scene.battle == bt and not scene.setup.visible)
	_tap(scene, Vector2i(-3, 1))
	await process_frame
	var txt := _panel_text(scene)
	ck("effects screen: the panel reads a card's text as the card does", txt.has("Target enemy takes damage 2 and gains Pinned for 2 turns.") and txt.has("This Unit gains +1 INT."), txt)
	ck("effects screen: an Action with Suppressive Fire has a Hold fire button under it", scene.panel._rows.filter(func(row): return row.has("hold")).map(func(row): return row["hold"]) == ["Overwatch"])
	ck("effects screen: a hazard in reach is lit amber, and the bottom line says what it does", scene.board.reach.has(Vector2i(-2, 1)) and haz.hazards.has(Vector2i(-2, 1)) and "Amber tiles are hazards (AC: 2 damage and Poisoned)" in scene.info.text, scene.info.text)
	_tap(scene, Vector2i(-2, 1))
	await _until(scene, "walking")
	await process_frame
	var wv: UnitView = scene.board.view_of("a1")
	ck("effects screen: tapping it still moves there, and it bites", Battle.tile_of(w) == Vector2i(-2, 1) and w["hp"] == 28 and "moves onto AC: 2 damage and Poisoned" in scene.info.text, scene.info.text)
	ck("effects screen: the damage and the status rise off the Unit, one after the other", scene.overlay.floats.map(func(f): return f["text"]) == ["-2 HP", "Poisoned"] and scene.overlay.floats[1]["age"] < scene.overlay.floats[0]["age"], scene.overlay.floats)
	ck("effects screen: the Unit wears a dot for it", wv.shown["statuses"].size() == 1 and wv.shown["statuses"][0]["name"] == "Poisoned" and wv.shown["hp"] == 28)
	txt = _panel_text(scene)
	ck("effects screen: its statuses are under its numbers at a glance", scene.panel.chips.visible and scene.panel.chips.get_child_count() == 1 and scene.panel.chips.get_child(0).get_child(1).text == "Poisoned 1")
	ck("effects screen: and the panel names it in full, with what it does and how long it has", txt.any(func(t): return t.begins_with("Poisoned 1") and "1 turn left" in t) and txt.has("Deals 1 in damage at each Recharge."), txt)
	scene.undo_move()
	await _still(wv)
	ck("effects screen: Undo takes the bite back too", w["hp"] == 30 and wv.shown["statuses"].is_empty() and wv.shown["hp"] == 30 and wv.position.is_equal_approx(Board.at(Vector2i(-3, 1))) and scene.overlay.floats.is_empty(), [w["hp"], wv.shown, wv.position])
	scene.deselect()
	_tap(scene, Vector2i(2, 0))
	await process_frame
	ck("effects screen: tap a hazard tile with nothing chosen and it says what it is", scene.info.text.begins_with("Hazard: Acid") and scene.selected_id == "", scene.info.text)
	_tap(scene, Vector2i(-3, 1))
	await process_frame
	scene.panel.hold_pressed.emit("Overwatch")
	await process_frame
	ck("effects screen: Hold fire pays the Energy and marks the Unit", w["nrg"] == 2 and w["holding"]["name"] == "Overwatch" and wv.shown["holding"] == true and "holds fire with Overwatch" in scene.info.text, [w["nrg"], scene.info.text])
	ck("effects screen: its panel says so, and offers no second hold", "Holding fire with Overwatch" in scene.panel.move_label.text and not scene.panel._rows.any(func(row): return row.has("hold")), scene.panel.move_label.text)
	# a Burst: you choose each next target
	var rapid := _act(d, "Rapid Fire")
	_sure(rapid, g1)
	_sure(rapid, g2)
	var ri := _index(d, "Rapid Fire")
	_tap(scene, Vector2i(0, 4))
	await process_frame
	scene.pick_action(ri)
	ck("effects screen: the Drone's Burst can reach both Grunts", scene.targets.size() == 2 and scene.overlay.tags.size() == 2, scene.targets)
	_tap(scene, Vector2i(2, 2))
	await _until(scene, "busy")
	ck("effects screen: after the first attack the Burst waits, both lit again with their odds", scene.burst == {"unit": "a3", "action": ri, "left": 2} and scene.targets.size() == 2 and scene.overlay.tags.size() == 2 and scene.aiming == ri and "Burst: 2 more to make" in scene.info.text, [scene.burst, scene.info.text])
	ck("effects screen: the readout said which attack it was, and what the text did", scene.overlay.readout["lines"][0][0] == "Rapid Fire: attack 1 of 3" and scene.overlay.readout["lines"].any(func(l): return l[0] == "Test Grunt takes 1 damage"), scene.overlay.readout.get("lines"))
	ck("effects screen: nothing else can be done until it's finished", scene.next_btn.disabled and not scene.undo_btn.visible)
	_tap(scene, Vector2i(0, 0))
	scene.deselect()
	scene.pick_action(_index(d, "Tag"))
	await process_frame
	ck("effects screen: a tap elsewhere, or another Action, doesn't drop it", scene.burst.get("left") == 2 and scene.selected_id == "a3" and scene.aiming == ri and "The Burst isn't over" in scene.info.text, scene.info.text)
	_tap(scene, Vector2i(3, 1))
	await _until(scene, "busy")
	ck("effects screen: tap the other Grunt: the second attack goes there", scene.burst.get("left") == 1 and g2["hp"] == 15 and g1["hp"] == 15, [scene.burst, g1["hp"], g2["hp"]])
	_tap(scene, Vector2i(2, 2))
	await _until(scene, "busy")
	ck("effects screen: the third ends it: one payment of Energy for all three", scene.burst.is_empty() and d["nrg"] == 1 and g1["hp"] == 12 and not scene.next_btn.disabled and scene.aiming == -1, [scene.burst, d["nrg"], g1["hp"]])
	g2["hp"] = 0
	g2["down"] = true
	scene.board.refresh_units(bt)
	var fading := 0
	while scene.board.view_of("e2").visible and fading < 600:
		await process_frame
		fading += 1
	ck("effects screen: a Unit that goes down fades from the board", scene.board.view_of("e2").gone and not scene.board.view_of("e2").visible)
	d["nrg"] = 3
	var lines0 := bt.log.size()
	scene.pick_action(ri)
	_tap(scene, Vector2i(2, 2))
	var waited := await _until(scene, "busy", 4000)
	ck("effects screen: with one target in reach a Burst runs through by itself", scene.burst.is_empty() and _texts(bt, lines0).filter(func(t): return t.begins_with("Test Drone used Rapid Fire")).size() == 3 and g1["hp"] == 3 and d["nrg"] == 1, [waited, g1["hp"], _texts(bt, lines0)])

	# ---- an area: preview, then fire. A card problem. A Deploy.
	var sp := _mk(r, "Test Sapper", "ally", "a4", Vector2i(-4, 4))
	var s := _mk(r, "Test Striker", "ally", "a2", Vector2i(-1, 4))
	var ag := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(-2, 4))
	var ag2 := _mk(r, "Test Grunt", "enemy", "e2", Vector2i(-2, 3))
	ag2["name"] = "Test Grunt 2"
	var b2 := _stage(scene, haz, [sp, s, ag, ag2])
	scene._fit()
	await process_frame
	var charge := _act(sp, "Satchel Charge")
	_sure(charge, ag)
	_tap(scene, Vector2i(-4, 4))
	await process_frame
	scene.pick_action(_index(sp, "Satchel Charge"))
	ck("effects screen: aiming an area Action says the first tap only shows it", "to see what its area would take in" in scene.info.text and scene.preview == "", scene.info.text)
	_tap(scene, Vector2i(-2, 4))
	await process_frame
	ck("effects screen: the first tap lights the blast and rolls nothing", scene.preview == "e1" and scene.board.blast.size() == 7 and b2.log.is_empty() and sp["nrg"] == 3 and not scene.busy, [scene.preview, scene.board.blast.size(), b2.log])
	ck("effects screen: everyone it would catch is ringed", scene.board.view_of("a2").caught and scene.board.view_of("e2").caught and not scene.board.view_of("a4").caught)
	ck("effects screen: your own flagged, on the board and in the bottom line", scene.overlay.tags.any(func(t): return t["text"] == "Yours!" and t["at"].is_equal_approx(Board.at(Vector2i(-1, 4)))) and scene.overlay.tags.size() == 3 and "would also take in Test Grunt 2 — and your own Test Striker" in scene.info.text, [scene.overlay.tags.map(func(t): return t["text"]), scene.info.text])
	_tap(scene, Vector2i(-2, 3))
	await process_frame
	ck("effects screen: tap another target and the blast moves there", scene.preview == "e2" and scene.board.blast.has(Vector2i(-2, 2)) and b2.log.is_empty())
	_tap(scene, Vector2i(-5, 2))
	await process_frame
	ck("effects screen: tap elsewhere and the blast is put away, still aiming", scene.preview == "" and scene.board.blast.is_empty() and scene.aiming >= 0 and scene.targets.size() == 2 and not scene.board.view_of("a2").caught)
	_tap(scene, Vector2i(-2, 4))
	await process_frame
	var s0: int = s["hp"]
	_tap(scene, Vector2i(-2, 4))
	await process_frame
	ck("effects screen: the second tap on the same target fires", not b2.log.is_empty() and sp["nrg"] == 1 and scene.board.blast.is_empty() and scene.preview == "", b2.log)
	ck("effects screen: and the blast catches who it showed", s["hp"] == s0 - 3 and ag2["hp"] == 15 and scene.overlay.floats.any(func(f): return f["text"] == "-3 HP") and "AoE 1 also hits Test Striker, Test Grunt 2 for 3" in scene.info.text, [s["hp"], ag2["hp"], scene.info.text])
	await _until(scene, "busy")
	# a card that can't do what it says
	var check := _act(s, "Shoulder Check")
	_sure(check, ag)
	check["text"] = "[[target enemy]] gains [[AC +2]]."
	_tap(scene, Vector2i(-1, 4))
	await process_frame
	scene.pick_action(_index(s, "Shoulder Check"))
	_tap(scene, Vector2i(-2, 4))
	var n := 0
	while scene.dialog == null and n < 400:
		await process_frame
		n += 1
	ck("effects screen: a card that can't do what it says stops the fight on a box", scene.dialog != null and scene.dialog.title_label.text == "A card couldn't do what it says" and scene.busy, n)
	ck("effects screen: naming the card and what couldn't happen", scene.dialog != null and "Shoulder Check: " in scene.dialog.text_label.text and "no Duration" in scene.dialog.text_label.text, scene.dialog.text_label.text if scene.dialog != null else "")
	await _frames(30)
	ck("effects screen: it waits there", scene.dialog != null and scene.busy)
	scene.dialog.buttons[0].pressed.emit()
	await _until(scene, "busy")
	ck("effects screen: OK, and the fight goes on", scene.dialog == null and not scene.busy and b2.halts.is_empty() and scene.selected_id == "a2")
	scene.toggle_log()
	var log_lines: Array = scene.log_panel.list.rows().map(func(l): return l.text)
	ck("effects screen: the Log has it, marked as a card problem", log_lines.any(func(t): return t.begins_with("Card problem: ") and "no Duration" in t), log_lines.slice(-4))
	scene.toggle_log()
	b2.fx.run_text("[[Deploy 1 Test Grunt]] [[adjacent]].", {"actor": ag2, "sourceCard": "Call Reinforcement"})
	scene.board.refresh_units(b2)
	await process_frame
	var dv: UnitView = scene.board.view_of("d1")
	ck("effects screen: a Unit put down by a Deploy appears on the board", dv != null and dv.position.is_equal_approx(Board.at(Battle.tile_of(b2.unit_by_id("d1")))) and scene.board.views.size() == 5)

	# ---- a push slides; a held shot answers in the Enemies' turn
	var ps := _mk(r, "Test Striker", "ally", "a2", Vector2i(1, 0))
	var pg := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(2, 0))
	var b3 := _stage(scene, cor, [ps, pg])
	scene._fit()
	await process_frame
	_sure(_act(ps, "Shoulder Check"), pg)
	_tap(scene, Vector2i(1, 0))
	await process_frame
	scene.pick_action(_index(ps, "Shoulder Check"))
	_tap(scene, Vector2i(2, 0))
	await _until(scene, "busy")
	await _still(scene.board.view_of("e1"))
	ck("effects screen: a pushed Unit slides to where it lands", Battle.tile_of(pg) == Vector2i(4, 0) and scene.board.view_of("e1").position.is_equal_approx(Board.at(Vector2i(4, 0))) and "Test Grunt pushed 2 tiles" in scene.info.text, [Battle.tile_of(pg), scene.info.text])
	var ow := _mk(r, "Test Warden", "ally", "a1", Vector2i(0, 0))
	var og := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(7, 0))
	var b4 := _stage(scene, cor, [ow, og])
	scene._fit()
	await process_frame
	_sure(_act(ow, "Overwatch"), og)
	_tap(scene, Vector2i(0, 0))
	await process_frame
	scene.panel.hold_pressed.emit("Overwatch")
	scene.run_enemy_phase()
	await process_frame
	_tap(scene, Vector2i(0, 1))
	var seen_hold_shot := false
	var n2 := 0
	while scene.enemy_phase and n2 < 3000:
		if not scene.overlay.readout.is_empty() and str(scene.overlay.readout["lines"][0][0]) == "Test Warden reacts: Overwatch":
			seen_hold_shot = true
		await process_frame
		n2 += 1
	ck("effects screen: in the Enemies' turn the held shot answers the first to move into reach, and is shown", seen_hold_shot and og["hp"] == 13 and b4.log.any(func(l): return str(l["text"]).begins_with("Test Warden reacts with Overwatch")), [seen_hold_shot, og["hp"]])
	ck("effects screen: then the hold is spent, and the board shows things as they ended", ow["holding"] == null and not scene.board.view_of("a1").shown["holding"] and scene.board.view_of("e1").shown["hp"] == 13 and scene.board.view_of("e1").position.is_equal_approx(Board.at(Battle.tile_of(og))) and b4.round == 2)
	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------- what the phone can show
## Every special character the game's scripts write (a dot between words, a
## dash, a times sign) is one the game's own font has. A computer quietly
## borrows a missing one from its system fonts; a phone may show an empty box.
func _fonts() -> void:
	var font := Look.font()           # (0.11: Jersey 10, alone)
	var missing := {}
	var seen := {}
	var esc := RegEx.new()
	esc.compile("\\\\u([0-9a-fA-F]{4})")
	for f in DirAccess.get_files_at("res://scripts"):
		if not f.ends_with(".gd"):
			continue
		for line in FileAccess.get_file_as_string("res://scripts/" + f).split("\n"):
			if line.strip_edges().begins_with("#"):
				continue
			var codes := []
			for m in esc.search_all(line):
				codes.append(m.get_string(1).hex_to_int())
			for i in line.length():
				if line.unicode_at(i) > 127:
					codes.append(line.unicode_at(i))
			for c in codes:
				seen[c] = true
				# the diamond for generic Aether is swapped for " any" before it's shown (UI.show)
				if c != 0x25c7 and not font.has_char(c):
					missing[String.chr(c)] = f
	ck("fonts: 0.11: the game's typeface is Jersey 10, without pixels smoothed", font is FontFile and (font as FontFile).antialiasing == TextServer.FONT_ANTIALIASING_NONE and font.get_font_name().begins_with("Jersey") and (font as FontFile).fallbacks.is_empty(), font.get_font_name())
	ck("fonts: every special character the game writes is in its own font", missing.is_empty() and seen.size() >= 6 and seen.has(0xb7) and seen.has(0x2212), missing)
	ck("fonts: and the one that isn't never reaches the screen", not font.has_char(0x25c7) and not "\u25c7" in UI.show(Battle.aether_label({"generic": 2, "d3": 1})) and UI.show(Battle.aether_label({"generic": 2})) == "2 any", UI.show(Battle.aether_label({"generic": 2, "d3": 1})))


# ---------------------------------------------------------------- Strike Teams
func _teams() -> void:
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)
	Kit.fresh()
	ck("teams: none saved to begin with", StrikeTeams.load_all().is_empty() and StrikeTeams.error == "")
	var t: Dictionary = Kit.team()
	ck("teams: the Deck counts every copy", StrikeTeams.deck_count(t) == 17 and StrikeTeams.deck_cards(t, r).size() == 17 and StrikeTeams.copies(t, "Test Drone") == 3)
	ck("teams: its Heroes, as cards, in the team's order", StrikeTeams.heroes(t, r).map(func(c): return c["name"]) == ["Test Warden", "Test Striker", "Quillon Vex"])
	ck("teams: the Pouch counts basic Chips and Chip cards, and what it must hold", StrikeTeams.pouch_count(t, r) == 8 and StrikeTeams.pouch_minimum(t, r) == 2, [StrikeTeams.pouch_count(t, r), StrikeTeams.pouch_minimum(t, r)])
	ck("teams: a basic Chip is 1 Aether of its District", StrikeTeams.chip_by_key("basic|3", r)["district"] == "3" and StrikeTeams.chip_by_key("basic|9", r) == null and StrikeTeams.chip_by_key("Test Spark Chip", r)["name"] == "Test Spark Chip")
	var p := StrikeTeams.pings(t, r)
	ck("teams: a sound team: nothing to fix, and the Leadership it pools", StrikeTeams.tally(p)["bad"] == 0 and StrikeTeams.tally(p)["warn"] == 0 and p.any(func(q): return "Pooled Leadership 9" in q[1]) and StrikeTeams.can_fight(t, r), p)
	var e := StrikeTeams.blank("Empty")
	var pe := StrikeTeams.pings(e, r)
	ck("teams: an empty one has no Hero and a Deck of 0, and can't fight", pe.any(func(q): return q[0] == "bad" and "no Hero" in q[1]) and pe.any(func(q): return "holds 0 cards" in q[1]) and not StrikeTeams.can_fight(e, r), pe)
	var big: Dictionary = Kit.team()
	big["heroes"].append("Rictus")
	ck("teams: a fourth Hero is one too many", StrikeTeams.pings(big, r).any(func(q): return q[0] == "bad" and "up to 3 Heroes" in q[1]))
	var over: Dictionary = Kit.team()
	over["actions"]["Test Warden"] = ["Test Overclock Routine"]
	ck("teams: more Action cards than Action Slots", StrikeTeams.pings(over, r).any(func(q): return q[0] == "bad" and "Test Warden carries 1 Action Cards but has 0 Action Slots" in q[1]), StrikeTeams.pings(over, r))
	var poor: Dictionary = Kit.team()
	poor["pouch"] = {"basic|3": 1}
	ck("teams: a Pouch smaller than the dearest card", StrikeTeams.pings(poor, r).any(func(q): return q[0] == "bad" and "holds 1 chip." in q[1] and "at least 2" in q[1]), StrikeTeams.pings(poor, r))
	var off: Dictionary = Kit.team()
	off["pouch"] = {"basic|1": 8}
	ck("teams: a card that needs a District's Aether, and no Chip of it: a note, not a fault", StrikeTeams.pings(off, r).any(func(q): return q[0] == "warn" and "District 3 Aether, but the Pouch holds no District 3 chip" in q[1]) and StrikeTeams.tally(StrikeTeams.pings(off, r))["bad"] == 0, StrikeTeams.pings(off, r))
	var solo: Dictionary = Kit.team()
	solo["heroes"] = ["Test Warden"]
	solo["actions"] = {}
	ck("teams: one Hero: a note that there is no reserve", StrikeTeams.pings(solo, r).any(func(q): return q[0] == "warn" and "never a reserve" in q[1]))
	var acts: Dictionary = Kit.team()
	acts["deck"]["Test Piercing Rounds"] = 1
	ck("teams: an Action card in the Deck doesn't belong there", StrikeTeams.pings(acts, r).any(func(q): return q[0] == "bad" and "1 Action Card is in the Deck" in q[1]), StrikeTeams.pings(acts, r))
	var ghost: Dictionary = Kit.team()
	ghost["deck"]["Ghost Card"] = 2
	ghost["protos"].append("Ghost Core")
	var pg := StrikeTeams.pings(ghost, r)
	ck("teams: cards the export no longer has are kept, and said first", StrikeTeams.missing(ghost, r) == ["Ghost Card", "Ghost Core"] and pg[0][0] == "bad" and "2 cards this team uses are not in this export: Ghost Card, Ghost Core" in pg[0][1] and StrikeTeams.deck_count(ghost) == 19 and StrikeTeams.deck_cards(ghost, r).size() == 17, pg[0])
	ck("teams: the Companion's own checks, without the game's note", not StrikeTeams.pings(ghost, r, false).any(func(q): return "not in this export" in q[1]))
	ck("teams: two cards that differ only in capitals are two cards", r.card_named("Aether Battery") != null and r.card_named("Aether battery") != null and Roster.type_of(r.card_named("Aether Battery")) == "troop" and Roster.type_of(r.card_named("Aether battery")) == "aether")
	# keeping them
	ck("teams: saved", StrikeTeams.save_all([t, e]))
	var back := StrikeTeams.load_all()
	ck("teams: and read back as they were", back.size() == 2 and back[0]["name"] == "Test Vanguard" and back[0]["deck"]["Test Drone"] == 3 and typeof(back[0]["deck"]["Test Drone"]) == TYPE_INT and back[0]["actions"] == t["actions"] and back[0]["pouch"]["basic|3"] == 6 and back[0]["level"] == 2 and back[1]["heroes"].is_empty(), back)
	ck("teams: a name no other team has", StrikeTeams.free_name(back, "Test Vanguard") == "Test Vanguard 2" and StrikeTeams.free_name(back, "Other") == "Other")
	var c2 := StrikeTeams.copy_of(t, "Copy")
	c2["deck"]["Test Drone"] = 1
	ck("teams: a copy is a team of its own", t["deck"]["Test Drone"] == 3 and c2["name"] == "Copy" and t["name"] == "Test Vanguard")
	var raw := {"name": "Old", "level": 9, "deck": "nonsense"}
	StrikeTeams.tidy(raw)
	ck("teams: a team with parts missing is filled in", raw["level"] == 6 and raw["deck"] == {} and raw["heroes"] == [] and raw["protos"] == [] and raw["name"] == "Old", raw)
	var f := FileAccess.open(StrikeTeams.path, FileAccess.WRITE)
	f.store_string("{ not json")
	f.close()
	ck("teams: a file that can't be read gives none, and says so", StrikeTeams.load_all().is_empty() and "couldn't be read" in StrikeTeams.error, StrikeTeams.error)
	Kit.fresh()
	# into a fight
	var su := StrikeTeams.setup_for(t, r, ["Test Warden", "Quillon Vex"], "Quillon Vex", ["Test Drone", "Test Drone"], 2)
	ck("teams: what goes into a fight: who enters, who leads, what they carry, the Deck, the Pouch, the Prototypes", su["heroes"].map(func(c): return c["name"]) == ["Test Warden", "Quillon Vex"] and su["leader"] == "Quillon Vex" and su["actions"]["Quillon Vex"][0]["name"] == "Test Piercing Rounds" and su["deck"].size() == 17 and su["pouch"] == t["pouch"] and su["level"] == 2 and su["protos"] == ["Test Aegis Core"] and su["wave_timer"] == 2 and su["start_troops"] == ["Test Drone", "Test Drone"], su.keys())
	ck("teams: its Consumables go in too", su["consumables"] == {"Test Stim": 2, "Test Repair Kit": 1, "Test Sandbags": 1} and StrikeTeams.consumable_count(t, r) == 4, su.get("consumables"))
	var many: Dictionary = Kit.team()
	many["consumables"]["Test Smoke"] = 1
	ck("teams: a fourth kind of Consumable is a note, not a fault", StrikeTeams.pings(many, r).any(func(q): return q[0] == "warn" and "carries 4 kinds of Consumable" in q[1]) and StrikeTeams.tally(StrikeTeams.pings(many, r))["bad"] == 0 and not StrikeTeams.pings(many, r, false).any(func(q): return "Consumable" in q[1]), StrikeTeams.pings(many, r))
	# (0.23) since the effect box audit no card of these kinds is in plain text, so four are given some for the test
	for nm in ["Burning Heart", "Foundry Sentinel", "Field Dressing", "Mending Chip"]:
		_make_plain(r, nm)
	var plainly: Dictionary = Kit.team()
	plainly["deck"]["Burning Heart"] = 1
	plainly["deck"]["Foundry Sentinel"] = 1
	plainly["consumables"] = {"Field Dressing": 1}
	plainly["pouch"]["Mending Chip"] = 1
	var pp := StrikeTeams.pings(plainly, r)
	ck("teams: cards in plain text are named, last, as a note", StrikeTeams.plain_cards(plainly, r) == ["Burning Heart", "Mending Chip", "Field Dressing"] and pp[pp.size() - 1][0] == "warn" and "3 cards here have text the game can't carry out" in pp[pp.size() - 1][1] and "Burning Heart, Mending Chip, Field Dressing" in pp[pp.size() - 1][1], [StrikeTeams.plain_cards(plainly, r), pp[pp.size() - 1]])
	ck("teams: a Troop is never listed there: it fights by its numbers", not StrikeTeams.plain_cards(plainly, r).has("Foundry Sentinel") and Roster.has_plain_text(r.card_named("Foundry Sentinel")))
	ck("teams: a team written with keywords has none", StrikeTeams.plain_cards(t, r).is_empty() and not Roster.has_plain_text(r.card_named("Test Stim")) and Roster.is_plain("Heals 6 to an adjacent ally.") and not Roster.is_plain("[[target ally]] gains [[heal 6]]."))
	var gone_c: Dictionary = Kit.team()
	gone_c["consumables"]["Ghost Flask"] = 2
	ck("teams: a Consumable the export has lost is kept, flagged, and left out of a fight", StrikeTeams.missing(gone_c, r) == ["Ghost Flask"] and not StrikeTeams.setup_for(gone_c, r, ["Test Warden"], "Test Warden", [], 3)["consumables"].has("Ghost Flask") and StrikeTeams.consumable_count(gone_c, r) == 6)
	var old := {"name": "From 0.5", "level": 2, "heroes": ["Test Warden"], "deck": {}, "actions": {}, "pouch": {}, "protos": []}
	StrikeTeams.tidy(old)
	ck("teams: a team saved before Consumables existed gains an empty set", old["consumables"] == {} and StrikeTeams.blank()["consumables"] == {})
	ck("teams: the Troops in the Deck that could start beside them", StrikeTeams.troops_in_deck(t, r).map(func(d): return [d["card"]["name"], d["copies"]]) == [["Test Drone", 3], ["Test Sapper", 2], ["Test Battery", 2], ["Test Scout", 2]])
	x.close()


func _clear(b: Battle) -> void:
	for e in b.side_units("enemy"):
		e["hp"] = 0
		e["down"] = true


# ---------------------------------------------------------------- a Strike Team's fight
func _team_battle() -> void:
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)
	var t: Dictionary = Kit.team()
	var f := _floor_named(x, "TEST · Corridor")
	var su := StrikeTeams.setup_for(t, r, ["Test Warden", "Quillon Vex"], "Quillon Vex", ["Test Drone", "Test Sapper"], 2)
	var b := Battle.begin_team(f, r, su, 11)
	var mine := b.side_units("ally")
	ck("team battle: the Heroes entering and the Starting Troops stand on your spawn tiles", mine.map(func(u): return u["name"]) == ["Test Warden", "Quillon Vex", "Test Drone", "Test Sapper"] and mine.all(func(u): return u.get("pos") is Dictionary), mine.map(func(u): return u["name"]))
	ck("team battle: the chosen Hero leads", b.unit_by_id(b.leader_id)["name"] == "Quillon Vex")
	var vex: Dictionary = mine[1]
	ck("team battle: an Action card a Hero carries is one of its Actions", vex["actions"].any(func(a): return a["name"] == "Piercing Rounds" and a.get("tag") != "Passive") and not mine[0]["actions"].any(func(a): return a["name"] == "Piercing Rounds"), vex["actions"].map(func(a): return a["name"]))
	var spawns := b.enemy_spawns().size()
	ck("team battle: the first of six waves is on the board", b.wave == 1 and b.waves_total == 6 and b.enemies_left() == spawns and spawns > 0 and b.with_cards and b.phase == "turn")
	ck("team battle: the pile holds six for every spawn tile, less the wave that came", b.enemy_pile.size() == spawns * 5, b.enemy_pile.size())
	ck("team battle: six cards to open, the Starting Troops out of the Deck", b.hand.size() == 6 and b.deck.size() == 17 - 2 - 6 and b.discard.is_empty(), [b.hand.size(), b.deck.size()])
	ck("team battle: Chips equal to the Player Level go from the Pouch to the Bank", b.bank.size() == 2 and b.pouch.size() == 6 and b.player_level == 2)
	var worth := func(): return b.bank.reduce(func(a, c): return a + int(c["value"]), 0)
	ck("team battle: the Heroes' Aether (their Affinity Level, of their District) and the Bank's", b.aether.get("d3", 0) == 4 + worth.call() and Rules.aether_total(b.aether) == 4 + worth.call(), b.aether)
	var said := _texts(b)
	ck("team battle: said as it opened", said.any(func(l): return l.begins_with("Wave 1 of 6: %d Enemies arrive" % spawns)) and said.has("Heroes generated 4 D3") and said.any(func(l): return l.begins_with("Drew 2 Aether Chips: ")) and said.has("Drew 6 cards"), said)
	ck("team battle: the Prototype is the team's, through the leader", b.protos.size() == 1 and b.protos[0]["name"] == "Test Aegis Core" and b.fx.leader_unit() == vex)
	ck("team battle: the same seed deals the same hand, Chips and Enemies", Battle.begin_team(f, r, su, 11).hand == b.hand and Battle.begin_team(f, r, su, 11).enemy_pile == b.enemy_pile and Battle.begin_team(f, r, su, 12).hand != b.hand)
	# the round turns over
	b.aether["d3"] += 5                # as if unspent
	var from := b.log.size()
	b.end_round()
	said = _texts(b, from)
	ck("team battle: next round, unspent Aether is lost and it's generated afresh", b.round == 2 and Rules.aether_total(b.aether) == 4 + worth.call() and said.any(func(l): return l.begins_with("Unspent Aether is lost: ")), [b.aether, said])
	ck("team battle: two more Chips into the Bank, and every Chip there generates", b.bank.size() == 4 and b.pouch.size() == 4 and said.any(func(l): return l.begins_with("The Bank generated ") and l.ends_with("from 4 Chips")), said)
	ck("team battle: a card drawn for every Hero standing", b.hand.size() == 8 and b.deck.size() == 7 and said.has("Drew 2 cards"), [b.hand.size(), said])
	ck("team battle: the Recharge is said", said.has("Recharge: nothing was spent"), said)
	ck("team battle: the wave timer counts the rounds", b.wave == 1 and b.wave_turn == 1 and b.next_wave_in() == 1)
	# stepped off their spawn tiles, the next wave has room
	var free := f.tiles.keys().filter(func(h): return b.unit_at(h) == null and not b.enemy_spawns().any(func(s): return s["at"] == h))
	var foes := b.side_units("enemy")
	for i in foes.size():
		foes[i]["pos"] = {"q": free[i].x, "r": free[i].y}
	from = b.log.size()
	b.end_round()
	said = _texts(b, from)
	ck("team battle: when the timer runs out the next wave comes", b.wave == 2 and b.wave_turn == 0 and b.enemies_left() == spawns * 2 and said.has("The wave timer runs out.") and said.any(func(l): return l.begins_with("Wave 2 of 6: ")), said)
	_clear(b)
	ck("team battle: a clear board isn't Victory while more can come", not b.settle() and b.enemies_left() == 0 and not b.nothing_more_coming() and b.next_wave_in() == 2)
	from = b.log.size()
	b.end_round()
	ck("team battle: a clear board brings the next wave at once", b.wave == 3 and b.enemies_left() == spawns and not _texts(b, from).has("The wave timer runs out."), _texts(b, from))
	var rounds := 0
	while b.wave < 6 and rounds < 20:
		_clear(b)
		b.end_round()
		rounds += 1
	ck("team battle: the sixth wave is the last", b.wave == 6 and b.nothing_more_coming() and b.next_wave_in() == -1 and b.enemy_pile.is_empty(), [b.wave, b.enemy_pile.size()])
	ck("team battle: the Pouch runs dry, the Bank keeps generating", b.pouch.is_empty() and b.bank.size() == 8 and _texts(b).has("The Aether Pouch is empty") and Rules.aether_total(b.aether) == 4 + worth.call(), [b.pouch.size(), b.bank.size(), b.aether])
	ck("team battle: the Deck runs dry, and says so", b.deck.is_empty() and b.hand.size() == 15 and _texts(b).has("The Deck is empty"), [b.deck.size(), b.hand.size()])
	ck("team battle: it isn't over while the last wave stands", not b.settle())
	_clear(b)
	ck("team battle: the last wave beaten is Victory", b.settle() and b.winner == "ally")
	# a team with a card the export has lost fights without it
	var ghost: Dictionary = Kit.team()
	ghost["deck"]["Ghost Card"] = 2
	ghost["protos"].append("Ghost Core")
	var gb := Battle.begin_team(f, r, StrikeTeams.setup_for(ghost, r, ["Test Warden"], "Test Warden", [], 3), 4)
	ck("team battle: a card the export has lost is left out of the fight", gb.deck.size() + gb.hand.size() == 17 and gb.protos.size() == 1 and gb.wave_timer == 3)
	# a Quick battle is as it was
	var q := Battle.begin(f, r, [r.card_named("Test Warden")], [], 5)
	ck("team battle: a Quick battle has one wave, no Deck and no Aether", not q.with_cards and q.waves_total == 1 and q.hand.is_empty() and q.aether.is_empty() and q.upkeep() == ["recharge"] and q.nothing_more_coming())
	Rules.hooks = {}
	x.close()


# ---------------------------------------------------------------- setting up a Strike Team's Battle
func _team_setup() -> void:
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)
	var s := SetupScreen.new()
	root.add_child(s)
	s.set_content(r, x.floors())
	s.begin("team", [])
	await process_frame
	var ci := -1
	for i in s.floors.size():
		if s.floors[i].name == "TEST · Corridor":
			ci = i
	ck("team setup: a Battle has four steps, and its floors bring six waves", s.steps() == SetupScreen.TEAM_STEPS and s.title.text == "Battle" and "six waves" in s.hint.text and s.back_btn.text == "Home")
	s.choose_floor(ci)
	s._go(1)
	ck("team setup: with no teams, it says where to build one, and won't go on", s.step == "team" and "no Strike Teams yet" in s.hint.text and s.next_btn.disabled and s._rows.is_empty(), s.hint.text)
	var short: Dictionary = Kit.team("Short")
	short["deck"] = {"Test Drone": 2}
	s.begin("team", [Kit.team(), StrikeTeams.blank("Nobody"), short])
	s.choose_floor(ci)
	s._go(1)
	await _frames(2)
	ck("team setup: after the floor, your Strike Teams", s.step == "team" and s._rows.size() == 3 and "[ 2 Strike Team ]" in s.steps_label.text and s.next_btn.disabled, s.steps_label.text)
	s.choose_team(1)
	ck("team setup: a team with no Hero can't be sent in", s.next_btn.disabled and s.heroes.is_empty())
	s.choose_team(2)
	ck("team setup: one with things to fix can, and says what", not s.next_btn.disabled and "The Deck holds 2 cards" in s.note.text and "You can still fight" in s.note.text, s.note.text)
	await _frames(2)
	var row: Control = s._rows[0]["row"]
	s.list.tap(row.global_position - s.list.global_position + Vector2(60, 30))
	ck("team setup: tap a team to choose it", s.team_i == 0 and s.note.text == "" and not s.next_btn.disabled, [s.team_i, s.note.text])
	s._go(1)
	await _frames(2)
	ck("team setup: its Heroes: as many as the floor lets in enter, the first leads, the rest wait", s.step == "heroes" and s.heroes == ["Test Warden", "Test Striker"] and s.leader == "Test Warden" and s._rows.size() == 3 and "lets 2 Heroes in" in s.hint.text, [s.heroes, s.leader, s.hint.text])
	s.toggle_hero("Quillon Vex")
	ck("team setup: no more than the floor lets in", s.heroes == ["Test Warden", "Test Striker"] and "Only 2" in s.note.text, s.note.text)
	s.toggle_hero("Test Warden")
	ck("team setup: hold the leader back and the next one leads", s.heroes == ["Test Striker"] and s.leader == "Test Striker")
	s.toggle_hero("Quillon Vex")
	s.toggle_hero("Test Striker")
	s.toggle_hero("Test Warden")
	ck("team setup: they stand in the team's own order, whoever was chosen first", s.heroes == ["Test Warden", "Quillon Vex"] and s.leader == "Quillon Vex", [s.heroes, s.leader])
	await _frames(2)
	var we: Dictionary = {}
	for e in s._rows:
		if e.get("hero") == "Test Warden":
			we = e
	var lead: Control = we["action"]
	s.list.tap(lead.global_position - s.list.global_position + lead.size / 2)
	ck("team setup: tap Lead on a Hero to put it in charge", s.leader == "Test Warden" and s.heroes == ["Test Warden", "Quillon Vex"], [s.leader, s.heroes])
	s.set_leader("Test Striker")
	ck("team setup: a Hero held back can't lead", s.leader == "Test Warden")
	s.set_leader("Quillon Vex")
	s._go(1)
	await _frames(2)
	ck("team setup: then the Starting Troops, out of the Deck, and the wave timer", s.step == "troops" and s._rows.size() == 6 and s.pooled_leadership() == 7 and "0 of 7 used" in s.hint.text and s.next_btn.text == "Start battle" and s.wave_timer == 3, s.hint.text)
	for i in 3:
		s.more_troop("Test Sapper")
	ck("team setup: no more of a Troop than the Deck holds", s.troops == {"Test Sapper": 2} and "The Deck holds 2 Test Sapper" in s.note.text, s.note.text)
	for i in 3:
		s.more_troop("Test Drone")
	for i in 2:
		s.more_troop("Test Scout")
	s.more_troop("Test Battery")
	ck("team setup: nor more than the pooled Leadership of the Heroes entering", s.used_slots() == 7 and not s.troops.has("Test Battery") and "only 0 of 7" in s.note.text, s.note.text)
	s.less_troop("Test Scout")
	s.less_troop("Test Scout")
	s.less_troop("Test Drone")
	await _frames(2)
	var te: Dictionary = s._rows[s._rows.size() - 2]
	var plus: Control = te["plus"]
	s.list.tap(plus.global_position - s.list.global_position + plus.size / 2)
	ck("team setup: the wave timer's plus", s.wave_timer == 4 and te.has("timer") and not te.has("districts"), s.wave_timer)
	s.set_wave_timer(0)
	var low := s.wave_timer
	s.set_wave_timer(99)
	ck("team setup: from 1 to 10", low == 1 and s.wave_timer == 10)
	s.set_wave_timer(2)
	var got := []
	s.team_start_requested.connect(func(fi, tm, su): got.append([fi, tm, su]))
	s._go(1)
	ck("team setup: Start battle hands over the floor, the team and who goes in", got.size() == 1 and got[0][0] == ci and got[0][1]["name"] == "Test Vanguard" and got[0][2]["heroes"].map(func(c): return c["name"]) == ["Test Warden", "Quillon Vex"] and got[0][2]["leader"] == "Quillon Vex" and got[0][2]["start_troops"] == ["Test Sapper", "Test Sapper", "Test Drone", "Test Drone"] and got[0][2]["wave_timer"] == 2, got[0][2]["start_troops"] if not got.is_empty() else got)
	var shut := [0]
	s.closed.connect(func(): shut[0] += 1)
	for i in 3:
		s._go(-1)
	ck("team setup: Back, a step at a time, to the floors", s.step == "floor" and s.back_btn.text == "Home" and shut[0] == 0)
	s._go(-1)
	ck("team setup: and Home from there", shut[0] == 1)
	s.begin("quick")
	ck("team setup: a Quick battle starts with nobody chosen, and has three steps", s.mode == "quick" and s.heroes.is_empty() and s.steps() == SetupScreen.STEPS and s.title.text == "Quick battle")
	s.queue_free()
	x.close()
	await process_frame


# ---------------------------------------------------------------- the Strike Team builder
## Where a card's tile is in the builder's grid, or -1.
func _tile_of(ed: TeamEditor, name: String) -> int:
	for i in ed._shown.size():
		if str(ed._shown[i].get("card", {}).get("name", "")) == name:
			return i
	return -1


## Every line of text under a node.
func _labels(n: Node) -> Array:
	var out := []
	var todo: Array = [n]
	while not todo.is_empty():
		var k: Node = todo.pop_back()
		if k is Label:
			out.append(k.text.replace(" ", " "))
		todo.append_array(k.get_children())
	return out


func _builder() -> void:
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)
	Kit.fresh()
	var ts := TeamsScreen.new()
	root.add_child(ts)
	ts.open(r)
	await _frames(2)
	ck("builder: with no teams yet, it says how to start", ts._rows.is_empty() and "New team" in ts.hint.text, ts.hint.text)
	ts.ask_new()
	await process_frame
	ck("builder: New team asks for a name, with one offered", ts.namer != null and ts.namer.edit.text == "Strike Team")
	ts.namer.edit.text = "Vanguard"
	ts.namer.ok_btn.pressed.emit()
	await _frames(2)
	ck("builder: named, it opens to build on, and is kept already", ts.namer == null and ts.editor.visible and ts.editing == 0 and ts.teams[0]["name"] == "Vanguard" and StrikeTeams.load_all().size() == 1)
	var ed: TeamEditor = ts.editor
	ck("builder: it opens on the Heroes, every Hero in the export a tile", ed.tab == "heroes" and ed.grid.tiles.size() == r.heroes().size() and ed.tab_btns["heroes"].text == "Heroes 0" and ed.name_btn.text.begins_with("Vanguard"), ed.grid.tiles.size())
	ck("builder: the Checks tab says there is something to fix", "to fix" in ed.tab_btns["checks"].text, ed.tab_btns["checks"].text)
	# a tap on a tile, as the grid sees it
	var wi := _tile_of(ed, "Test Warden")
	ed.grid.tap(ed.grid.tile_centre(wi))
	await process_frame
	ck("builder: tap a Hero's tile to read it in full", ed.sheet != null and ed.sheet.card["name"] == "Test Warden" and ed.sheet.buttons.has("toggle") and ed.sheet.buttons["toggle"].text == "Add to the team")
	var lines := _labels(ed.sheet) if ed.sheet != null else []
	ck("builder: the sheet has its numbers, its Leadership and every Action", lines.any(func(l): return l.begins_with("HP 30")) and lines.any(func(l): return "Leadership 4" in l and "generates 2 D3" in l) and lines.any(func(l): return l.begins_with("Pinning Volley")) and lines.any(func(l): return l.begins_with("Steady Nerve")), lines)
	ed.grid.tap(ed.grid.tile_centre(0))
	ck("builder: nothing behind an open sheet takes a tap", ed.sheet != null and ed.sheet.card["name"] == "Test Warden")
	ed.sheet.buttons["toggle"].pressed.emit()
	await _frames(2)
	ck("builder: Add to the team: its tile is marked, and it's kept", ed.sheet == null and ed.team["heroes"] == ["Test Warden"] and ed.grid.tiles[_tile_of(ed, "Test Warden")].mark == "In team · 1" and ed.grid.tiles[_tile_of(ed, "Test Warden")].chosen and ed.tab_btns["heroes"].text == "Heroes 1" and StrikeTeams.load_all()[0]["heroes"] == ["Test Warden"])
	ed.grid.tap(ed.grid.tile_centre(0) + Vector2(CardTile.SIZE.x / 2.0 + 5, 0))
	ck("builder: a tap between two tiles picks neither", ed.sheet == null)
	ed.tap_card(wi)
	await process_frame
	ck("builder: a Hero in the team can be taken off it", ed.sheet.buttons["toggle"].text == "Take off the team")
	ed.sheet.buttons["close"].pressed.emit()
	await _frames(2)
	# the Deck
	ed.open_tab("deck")
	await _frames(2)
	ck("builder: the Deck tab: every Troop, Equipment, Command and Aether card", ed.grid.tiles.size() == r.of_types(StrikeTeams.DECK_TYPES).size() and ed.grid.tiles.size() > 50 and ed.sheet == null, ed.grid.tiles.size())
	ed.set_filter("command")
	await _frames(2)
	ck("builder: filtered by kind", ed.grid.tiles.size() == r.of_types(["command"]).size() and ed.grid.tiles.all(func(t): return Roster.type_of(t.card) == "command"))
	ed.set_filter("all")
	await _frames(2)
	ed.tap_card(_tile_of(ed, "Test Drone"))
	await process_frame
	ck("builder: a Deck card's sheet says what it costs and sets its copies", ed.sheet != null and ed.sheet.count_label.text == "0" and ed.sheet.minus_btn.disabled and _labels(ed.sheet).has("Costs 1 any Aether to play."), _labels(ed.sheet) if ed.sheet != null else [])
	for i in 3:
		ed.sheet.plus_btn.pressed.emit()
	await process_frame
	ck("builder: plus three times: three copies, counted on its tile at once", ed.team["deck"].get("Test Drone") == 3 and ed.sheet != null and ed.sheet.count_label.text == "3" and ed.grid.tiles[_tile_of(ed, "Test Drone")].count == 3 and ed.tab_btns["deck"].text == "Deck 3" and StrikeTeams.load_all()[0]["deck"]["Test Drone"] == 3, ed.team["deck"])
	ed.sheet.minus_btn.pressed.emit()
	ed.sheet.buttons["close"].pressed.emit()
	await _frames(2)
	ck("builder: minus takes one off; Close puts the sheet away", ed.team["deck"]["Test Drone"] == 2 and ed.sheet == null)
	ed.set_deck_only(true)
	await _frames(2)
	ck("builder: See Deck shows only what's in it", ed.grid.tiles.size() == 1 and ed.grid.tiles[0].card["name"] == "Test Drone" and ed.grid.tiles[0].count == 2)
	ed.set_copies("Test Drone", 0)
	await _frames(2)
	ck("builder: an empty Deck says so", ed.grid.tiles.is_empty() and ed.team["deck"].is_empty() and _labels(ed.grid).any(func(l): return "The Deck is empty" in l), _labels(ed.grid))
	ed.set_deck_only(false)
	ed.set_copies("Test Drone", 999)
	ck("builder: never more than 60 of a card", ed.team["deck"]["Test Drone"] == 60)
	ed.set_copies("Test Drone", 0)
	# what a Hero carries
	ed.toggle_hero("Quillon Vex")
	ed.open_tab("carried")
	await _frames(2)
	ck("builder: Carried: a Hero at a time, with its Action Slots", ed.carrier == "Test Warden" and "0 Action Slots" in ed.hint.text and ed.grid.tiles.size() == r.of_types(["action"]).size(), ed.hint.text)
	ed.set_carrier("Quillon Vex")
	await _frames(2)
	ed.tap_card(_tile_of(ed, "Test Piercing Rounds"))
	await process_frame
	ck("builder: an Action card's sheet gives it to that Hero", ed.sheet != null and ed.sheet.buttons["toggle"].text == "Give to Quillon Vex")
	ed.sheet.buttons["toggle"].pressed.emit()
	await _frames(2)
	ck("builder: given: marked Carried, and counted", ed.team["actions"] == {"Quillon Vex": ["Test Piercing Rounds"]} and ed.grid.tiles[_tile_of(ed, "Test Piercing Rounds")].mark == "Carried" and ed.tab_btns["carried"].text == "Carried 1" and "carries 1 Action card and has 2 Action Slots" in ed.hint.text, [ed.team["actions"], ed.hint.text])
	# the Pouch
	ed.open_tab("pouch")
	await _frames(2)
	ck("builder: the Pouch: a basic Chip for each District, then every Chip card", ed.grid.tiles.size() == 6 + r.of_types(["sphere"]).size() and ed.grid.tiles[2].card["name"] == "Basic Chip · District 3" and ed.grid.tiles[2].foot == "1 D3", ed.grid.tiles.size())
	ed.tap_card(2)
	await process_frame
	for i in 6:
		ed.sheet.plus_btn.pressed.emit()
	ed.sheet.buttons["close"].pressed.emit()
	await _frames(2)
	ck("builder: six basic District 3 Chips packed", ed.team["pouch"] == {"basic|3": 6} and ed.grid.tiles[2].count == 6 and ed.tab_btns["pouch"].text == "Pouch 6", ed.team["pouch"])
	# Prototypes
	ed.open_tab("protos")
	await _frames(2)
	ed.tap_card(_tile_of(ed, "Test Aegis Core"))
	await process_frame
	ed.sheet.buttons["toggle"].pressed.emit()
	await _frames(2)
	ck("builder: a Prototype added to the team", ed.team["protos"] == ["Test Aegis Core"] and ed.grid.tiles[_tile_of(ed, "Test Aegis Core")].mark == "In team" and ed.grid.tiles.size() == r.of_types(["prototype"]).size())
	# Consumables (0.23: Field Dressing given plain text for the test, as the audit wrote it in keywords)
	_make_plain(r, "Field Dressing")
	ed.open_tab("consumables")
	await _frames(2)
	ck("builder: Consumables: every Consumable card, plain text marked on its tile", ed.grid.tiles.size() == r.of_types(["consumable"]).size() and ed.grid.tiles[_tile_of(ed, "Field Dressing")].plain and not ed.grid.tiles[_tile_of(ed, "Test Stim")].plain and "this team carries 0" in ed.hint.text and ed.tab_btns["consumables"].text == "Consumables 0", [ed.grid.tiles.size(), ed.hint.text])
	ed.tap_card(_tile_of(ed, "Test Stim"))
	await process_frame
	ck("builder: a Consumable's sheet sets how many go into each Battle", ed.sheet != null and ed.sheet.minus_btn != null and ed.sheet.minus_btn.disabled and _labels(ed.sheet).has("Carried into each Battle"), _labels(ed.sheet))
	ed.sheet.plus_btn.pressed.emit()
	ed.sheet.plus_btn.pressed.emit()
	ed.sheet.buttons["close"].pressed.emit()
	await _frames(2)
	ck("builder: two packed: counted on the tile, the tab and the saved team", ed.team["consumables"] == {"Test Stim": 2} and ed.grid.tiles[_tile_of(ed, "Test Stim")].count == 2 and ed.tab_btns["consumables"].text == "Consumables 2" and "this team carries 1" in ed.hint.text and StrikeTeams.load_all()[0]["consumables"] == {"Test Stim": 2}, [ed.team["consumables"], ed.hint.text])
	ed.set_consumables("Test Sandbags", 99)
	ck("builder: never more than 9 of a Consumable", ed.team["consumables"]["Test Sandbags"] == 9)
	ed.set_consumables("Test Sandbags", 0)
	ck("builder: none of it left takes it off the team", not ed.team["consumables"].has("Test Sandbags"))
	for nm in ["Test Sandbags", "Test Repair Kit", "Field Dressing"]:
		ed.set_consumables(nm, 1)
	ed.open_tab("checks")
	await _frames(2)
	var said := _labels(ed.checks.box)
	ck("builder: a fourth kind of Consumable is a note in Checks, not a block", said.any(func(l): return l.begins_with("Note: The team carries 4 kinds of Consumable")) and said.has("Handbook 15.7 - Section 9, Consumables"), said)
	ck("builder: Checks names the team's cards in plain text, last", str(said[0]).begins_with("Note: 1 card here has text the game can't carry out") and "Field Dressing" in str(said[0]), said[0])  # _labels reads the last row first
	ed.set_consumables("Field Dressing", 0)
	ed.set_consumables("Test Repair Kit", 0)
	ed.set_consumables("Test Sandbags", 0)
	ed.set_level(3)
	var mid: int = ed.team["level"]
	ed.set_level(9)
	ck("builder: the Player Level, from 1 to 6", mid == 3 and ed.team["level"] == 6 and ed.level_label.text == "6")
	ed.set_level(2)
	# what the rules say
	ed.open_tab("checks")
	await _frames(2)
	var told := _labels(ed.checks.box)
	ck("builder: Checks lists what the rules say, with where the Handbook says it", told.any(func(l): return l.begins_with("To fix: The Deck holds 0 cards")) and told.any(func(l): return "Pooled Leadership 7" in l) and told.any(func(l): return l.begins_with("Handbook 14.0")) and not ed.grid.visible, told)
	ed.ask_name()
	await process_frame
	ed.rename.edit.text = "First Team"
	ed.rename.ok_btn.pressed.emit()
	await _frames(2)
	ck("builder: renamed", ed.rename == null and ed.team["name"] == "First Team" and ed.name_btn.text.begins_with("First Team") and StrikeTeams.load_all()[0]["name"] == "First Team")
	# a card the export no longer has
	ed.team["deck"]["Ghost Card"] = 2
	ed.open_tab("deck")
	await _frames(2)
	ck("builder: a card the export no longer has stays, first, and says so", ed.grid.tiles[0].gone and ed.grid.tiles[0].card["name"] == "Ghost Card" and ed.grid.tiles[0].count == 2)
	ed.tap_card(0)
	await process_frame
	ck("builder: its sheet offers to take it out", ed.sheet != null and ed.sheet.buttons.has("forget") and "no card by this name" in ed.sheet.note_label.text)
	ed.sheet.buttons["forget"].pressed.emit()
	await _frames(2)
	ck("builder: taken out", not ed.team["deck"].has("Ghost Card") and not ed.grid.tiles[0].gone)
	# back at the list
	ed.closed.emit()
	await _frames(2)
	told = _labels(ts.list.box)
	ck("builder: back at the list: the team, what it holds and what's to fix", not ts.editor.visible and ts._rows.size() == 1 and told.has("First Team") and told.has("Test Warden, Quillon Vex · Deck 0 · Pouch 6 · Level 2") and told.has("1 to fix"), told)
	var cp: Control = ts._rows[0]["copy"]
	ts.list.tap(cp.global_position - ts.list.global_position + cp.size / 2)
	await _frames(2)
	ck("builder: Copy makes another under a name of its own", ts.teams.size() == 2 and ts.teams[1]["name"] == "First Team copy" and ts.teams[1]["heroes"] == ts.teams[0]["heroes"] and StrikeTeams.load_all().size() == 2 and not ts.editor.visible, ts.teams.map(func(t): return t["name"]))
	var dl: Control = ts._rows[1]["delete"]
	ts.list.tap(dl.global_position - ts.list.global_position + dl.size / 2)
	await process_frame
	ck("builder: Delete asks first", ts.dialog != null and "First Team copy" in ts.dialog.text_label.text and ts.teams.size() == 2)
	ts.dialog.buttons[0].pressed.emit()
	await process_frame
	ck("builder: Keep it keeps it", ts.dialog == null and ts.teams.size() == 2)
	ts.ask_delete(1)
	ts.dialog.buttons[1].pressed.emit()
	await _frames(2)
	ck("builder: Delete, and it's gone for good", ts.teams.size() == 1 and StrikeTeams.load_all().size() == 1 and "deleted" in ts.note.text, ts.note.text)
	var row: Control = ts._rows[0]["row"]
	ts.list.tap(row.global_position - ts.list.global_position + Vector2(60, 30))
	await process_frame
	ck("builder: tap a team to build on it", ts.editor.visible and ts.editing == 0 and ts.editor.tab == "heroes")
	ts.queue_free()
	x.close()
	Kit.fresh()
	await process_frame


# ---------------------------------------------------------------- the screen, a Strike Team's Battle
## Lets the Enemies' turn and the round's phases play out, hurried, and
## returns the phases the banner named, in order.
func _play_out(scene: Node) -> Array:
	var seen := []
	var n := 0
	while scene.busy and n < 8000:
		scene.fast = true
		if scene.banner.visible and (seen.is_empty() or seen[seen.size() - 1] != scene.banner_title.text):
			seen.append(scene.banner_title.text)
		await process_frame
		n += 1
	return seen


func _team_scene() -> void:
	Kit.fresh()
	Kit.keep([Kit.team()])
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	await process_frame
	ck("battle screen: with a Strike Team built, home says where the deployments stand, and nothing else", scene.home.visible and scene.home.note.text == "0 deployments so far.", scene.home.note.text)
	scene.home.battle_btn.pressed.emit()
	await process_frame
	var s: SetupScreen = scene.setup
	ck("battle screen: Battle starts setting one up with your Strike Teams", s.visible and not scene.home.visible and s.mode == "team" and s.teams.size() == 1 and s.title.text == "Battle")
	var ci := -1
	for i in scene.floors.size():
		if scene.floors[i].name == "TEST · Corridor":
			ci = i
	s.choose_floor(ci)
	s._go(1)
	s.choose_team(0)
	s._go(1)
	s._go(1)
	s.more_troop("Test Drone")
	s.set_wave_timer(2)
	s.next_btn.pressed.emit()
	await _frames(3)
	var bt: Battle = scene.battle
	ck("battle screen: Start battle puts the team on the floor", bt != null and bt.with_cards and not s.visible and bt.side_units("ally").size() == 3 and scene.board.views.size() == bt.units.size() and scene.floor_label.text == "TEST · Corridor")
	ck("battle screen: the bar has the wave and when the next comes, and this turn's Aether", scene.wave_label.visible and scene.wave_label.text == "Wave 1 of 6 · next in 2" and scene.aether_btn.visible and scene.aether_btn.tooltip_text == "Aether " + UI.show(Battle.aether_label(bt.aether)) and scene.aether_btn.tooltip_text.ends_with(" D3") and scene.aether_gems.gems().size() == Rules.aether_total(bt.aether), [scene.wave_label.text, scene.aether_btn.tooltip_text])
	ck("battle screen: the Hand button counts your cards, the piles over it", scene.hand_btn.visible and scene.hand_btn.text == "Hand 6" and scene.piles_btn.visible and scene.piles_btn.text == "Deck 10  ·  Discard 0", [scene.hand_btn.text, scene.piles_btn.text])
	ck("battle screen: the bottom line says how it opened", "Wave 1 of 6" in scene.info.text and "Drew 6 cards" in scene.info.text and "Hand holds the cards you can play" in scene.info.text, scene.info.text)
	var lead: Dictionary = bt.unit_by_id(bt.leader_id)
	_tap(scene, Battle.tile_of(lead))
	await process_frame
	ck("battle screen: the leader's panel says it leads", scene.panel.visible and scene.panel.side_label.text.ends_with("· Leader"), scene.panel.side_label.text)
	var other: Dictionary = bt.side_units("ally")[1]
	_tap(scene, Battle.tile_of(other))
	await process_frame
	ck("battle screen: and nobody else's does", scene.panel.name_label.text == other["name"] and not "Leader" in scene.panel.side_label.text, scene.panel.side_label.text)
	scene.deselect()
	# the hand
	scene.hand_btn.pressed.emit()
	await _frames(3)
	var tray: HandTray = scene.hand_tray
	ck("battle screen: Hand opens the tray: every card you hold, as a tile", tray.visible and tray.grid.tiles.size() == 6 and not scene.hand_btn.visible and "6 cards" in tray.title.text and "Deck 10" in tray.title.text, tray.title.text)
	ck("battle screen: each tile says what the card costs", range(6).all(func(i): return tray.grid.tiles[i].foot == UI.show(Roster.cost_label(bt.hand[i])) and tray.grid.tiles[i].card["name"] == bt.hand[i]["name"]), tray.grid.tiles.map(func(t): return t.foot))
	ck("battle screen: with Aether to spend, none is faded", not tray.grid.tiles.any(func(t): return t.faded))
	var had: Dictionary = bt.aether.duplicate()
	bt.aether = {}
	scene._update_bar()
	await _frames(2)
	ck("battle screen: a card the Bank can't pay for is faded; a free one never", tray.grid.tiles.size() == 6 and tray.grid.tiles.all(func(t): return t.faded == (t.foot != "free")) and tray.grid.tiles.any(func(t): return t.faded) and scene.aether_btn.tooltip_text == "Aether —" and scene.aether_gems.gems().is_empty(), tray.grid.tiles.map(func(t): return [t.foot, t.faded]))
	bt.aether = had
	scene._update_bar()
	await _frames(2)
	ck("battle screen: the bottom line moves up over the tray", scene.info.offset_bottom < -HandTray.HEIGHT + 1)
	tray.grid.tap(tray.grid.tile_centre(0))
	await process_frame
	ck("battle screen: tap a card to read it, with Play at the bottom", scene.sheet != null and scene.sheet.card["name"] == bt.hand[0]["name"] and scene.sheet.note_label.text.begins_with("In your hand.") and scene.sheet.buttons.has("play") and scene.sheet.buttons["play"].text == "Play", scene.sheet.note_label.text if scene.sheet != null else "")
	_tap(scene, Battle.tile_of(lead))
	ck("battle screen: the board takes no taps while a card is open", scene.selected_id == "" and not scene.panel.visible)
	scene.sheet.buttons["close"].pressed.emit()
	await _frames(2)
	ck("battle screen: Close puts the card away, the tray still open", scene.sheet == null and tray.visible)
	tray.closed.emit()
	ck("battle screen: and Close on the tray puts that away", not tray.visible and scene.hand_btn.visible and scene.info.offset_bottom == 0.0)
	# the Aether
	scene.aether_btn.pressed.emit()
	await process_frame
	var box: String = scene.dialog.text_label.text if scene.dialog != null else ""
	ck("battle screen: the Aether button: this turn's, the Bank, the Pouch and the Prototypes", scene.dialog != null and scene.dialog.title_label.text == "Aether" and "The Bank holds 2 Chips" in box and "The Pouch has 6 Chips left" in box and "Player Level 2" in box and "Prototypes, through Test Warden: Test Aegis Core" in box, box)
	scene.dialog.buttons[0].pressed.emit()
	await process_frame
	# ending the turn
	scene.next_btn.pressed.emit()
	await process_frame
	ck("battle screen: End turn asks first while Units can still act", scene.dialog != null and scene.dialog.title_label.text == "End your turn?" and "can still move or act" in scene.dialog.text_label.text and scene.next_btn.text == "End turn")
	scene.dialog.buttons[1].pressed.emit()
	await process_frame
	ck("battle screen: End the turn: the Enemies take theirs", scene.busy and scene.enemy_phase and scene.next_btn.disabled)
	scene.show_bank()
	scene.toggle_hand()
	await process_frame
	var seen: Array = await _play_out(scene)
	ck("battle screen: then the round's phases play out, each announced in turn", seen == ["Waves", "Aether Generation", "Aether Draw", "Draw", "Recharge"], seen)
	var standing := bt.side_units("ally").filter(func(u): return str(u.get("cardType", "")).to_lower() == "hero" and not Rules.truthy(u.get("down"))).size()
	ck("battle screen: and it's your turn again: round 2, a card for each Hero, Aether afresh", bt.round == 2 and not scene.busy and not scene.banner.visible and not scene.upkeep and bt.phase == "turn" and scene.round_label.text == "Round 2" and bt.hand.size() == 6 + standing and scene.hand_btn.text == "Hand %d" % bt.hand.size() and bt.bank.size() == 4 and "your turn" in scene.info.text, [bt.round, bt.hand.size(), scene.info.text])
	ck("battle screen: the wave timer has counted the round", scene.wave_label.text == "Wave 1 of 6 · next in 1", scene.wave_label.text)
	var told := _texts(bt)
	ck("battle screen: the Log holds every phase", told.has("Heroes generated 4 D3") and told.any(func(l): return l.begins_with("The Bank generated ") and l.ends_with("from 4 Chips")) and told.has("Drew %d card%s" % [standing, "" if standing == 1 else "s"]) and told.any(func(l): return l.begins_with("Recharge: ")), told.slice(told.size() - 12))
	# a clear board
	_clear(bt)
	scene.board.refresh_units(bt)
	scene._update_bar()
	ck("battle screen: a clear board says the next wave is waiting", scene.wave_label.text == "Wave 1 of 6 · clear" and "next wave arrives when you end your turn" in scene._what_next() and not bt.settle(), [scene.wave_label.text, scene._what_next()])
	scene.next_btn.pressed.emit()
	await process_frame
	ck("battle screen: with nobody left to fight, End turn doesn't ask", scene.dialog == null and scene.busy)
	seen = await _play_out(scene)
	ck("battle screen: the next wave arrives, and the board shows it", bt.wave == 2 and bt.enemies_left() > 0 and scene.wave_label.text == "Wave 2 of 6 · next in 2" and bt.side_units("enemy").filter(func(u): return not Rules.truthy(u.get("down"))).all(func(u): return scene.board.view_of(u["id"]) != null and scene.board.view_of(u["id"]).visible) and seen.has("Waves"), [bt.wave, scene.wave_label.text])
	var turns := 0
	while bt.wave < 6 and not bt.over and turns < 12:
		_clear(bt)
		scene.board.refresh_units(bt)
		scene.next_round()
		await process_frame
		await _play_out(scene)
		turns += 1
	ck("battle screen: the sixth wave is marked as the last", bt.wave == 6 and scene.wave_label.text == "Wave 6 of 6 · the last" and not bt.over, [bt.wave, scene.wave_label.text, turns])
	_clear(bt)
	scene.board.refresh_units(bt)
	bt.settle()
	scene.show_result()
	await process_frame
	ck("battle screen: the last wave beaten: Victory", scene.dialog != null and scene.dialog.title_label.text == "Victory" and "Every wave beaten" in scene.dialog.text_label.text and scene.next_btn.disabled, scene.dialog.text_label.text if scene.dialog != null else "")
	scene.dialog.buttons[0].pressed.emit()
	await _frames(2)
	var bt2: Battle = scene.battle
	ck("battle screen: Play again: the same team on the same floor, from the first wave", bt2 != bt and bt2.with_cards and bt2.wave == 1 and bt2.round == 1 and bt2.hand.size() == 6 and bt2.wave_timer == 2 and bt2.side_units("ally").size() == 3 and scene.dialog == null and scene.wave_label.text == "Wave 1 of 6 · next in 2", scene.wave_label.text)
	# leaving
	scene.new_btn.pressed.emit()
	await process_frame
	ck("battle screen: Leave asks where to", scene.dialog != null and scene.dialog.title_label.text == "Leave this battle?" and scene.new_btn.tooltip_text == "Leave" and scene.dialog.buttons.map(func(b): return b.text) == ["Stay", "Set up another", "Home"])
	scene.dialog.buttons[0].pressed.emit()
	await process_frame
	ck("battle screen: Stay stays", scene.dialog == null and scene.battle == bt2 and not scene.home.visible and not s.visible)
	scene.ask_leave()
	scene.dialog.buttons[1].pressed.emit()
	await process_frame
	ck("battle screen: Set up another goes back to setting up a Battle", s.visible and s.mode == "team" and s.step == "floor" and scene.battle == null and scene.dialog == null and not scene.hand_btn.visible)
	_tap(scene, Vector2i(0, 0))
	ck("battle screen: the board takes no taps while setting up", scene.selected_id == "" and not scene.panel.visible)
	s.back_btn.pressed.emit()
	await process_frame
	ck("battle screen: Home from there", scene.home.visible and not s.visible)
	scene.home.teams_btn.pressed.emit()
	await _frames(2)
	ck("battle screen: Strike Teams opens your teams", scene.teams_screen.visible and scene.teams_screen._rows.size() == 1 and not scene.home.visible)
	scene.teams_screen.closed.emit()
	ck("battle screen: Back goes home", scene.home.visible and not scene.teams_screen.visible)
	# a Quick battle has none of it
	scene.start_battle(ci, [scene.roster.card_named("Test Warden")], [], 3)
	await _frames(2)
	ck("battle screen: a Quick battle has no wave count, no Aether and no Hand", scene.battle != null and not scene.wave_label.visible and not scene.aether_btn.visible and not scene.hand_btn.visible and not scene.cons_btn.visible and not scene.chips_btn.visible and not scene.piles_btn.visible and not scene.home.visible)
	scene.toggle_hand()
	scene.show_bank()
	ck("battle screen: and neither can be opened", not scene.hand_tray.visible and scene.dialog == null)
	scene.ask_leave()
	scene.dialog.buttons[2].pressed.emit()
	await process_frame
	ck("battle screen: Home leaves the fight", scene.home.visible and scene.battle == null and not scene.panel.visible and scene.dialog == null and scene.info.text == "")
	scene.queue_free()
	Kit.fresh()
	await process_frame


# ---------------------------------------------------------------- playing cards
func _hc(r: Roster, n: String) -> Dictionary:
	return Roster.hand_card(r.card_named(n))


func _names(list: Array) -> Array:
	return list.map(func(c): return c["name"])


func _cards() -> void:
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)
	var f := _floor_named(x, "TEST · Hazards and Cover")
	var t: Dictionary = Kit.team()
	var b := Battle.begin_team(f, r, StrikeTeams.setup_for(t, r, ["Test Warden", "Quillon Vex"], "Test Warden", ["Test Drone"], 3), 21)
	var warden: Dictionary = b.unit_by_id("a1")
	var vex: Dictionary = b.unit_by_id("a2")
	var drone: Dictionary = b.unit_by_id("a3")
	var e1: Dictionary = b.unit_by_id("e1")
	var e2: Dictionary = b.unit_by_id("e2")
	var e3: Dictionary = b.unit_by_id("e3")
	# (0.23) the Enemies dealt here had 20 Health before the effect box audit gave the Cleaner Bots their own; the checks keep that
	for e in [e1, e2, e3]:
		e["hp"] = 20
		e["hpMax"] = 20
	ck("cards: the Consumables the team carries come too, one for each packed", _names(b.consumables) == ["Test Stim", "Test Stim", "Test Repair Kit", "Test Sandbags"] and not b.consumables.any(func(c): return c["used"]) and b.consumables[2]["text"] == "[[Recover]] a Troop's card from the Discard Pile.", b.consumables)
	ck("cards: a Starting Troop keeps its card with it; a Hero has none", drone["card"]["name"] == "Test Drone" and drone["card"]["type"] == "troop" and warden.get("card") == null and b.discard.is_empty())
	# what a card needs
	ck("cards: what a card needs: a tile, and how wide its area is", Battle.needs_of(_hc(r, "Test Mortar Strike")["effects"]) == {"need": "tile", "radius": 1, "narrow": [], "recover": false})
	ck("cards: an Enemy; one of yours and an area round it; nobody at all; a Troop's card to Recover", Battle.needs_of(_hc(r, "Test Snare")["effects"])["need"] == "enemy" and Battle.needs_of(_hc(r, "Test Surge")["effects"]) == {"need": "ally", "radius": 3, "narrow": [], "recover": false} and Battle.needs_of(_hc(r, "Test Rally")["effects"])["need"] == "" and Battle.needs_of([{"text": b.consumables[2]["text"]}])["recover"])
	b.hand = ["Test Scout", "Test Plating", "Test Mortar Strike", "Test Snare", "Test Surge", "Test Rally"].map(func(n): return _hc(r, n))
	# when it can't be played
	b.aether = {}
	var st := b.play_state(b.hand[0])
	ck("cards: with an empty Bank a card can't be played, and says what it needs", not st["ok"] and st["kind"] == "troop" and "Test Scout needs 1" in st["why"] and "the Bank holds" in st["why"], st)
	ck("cards: and trying changes nothing", b.play_troop(0) == null and not b.play_equipment(1, drone) and not b.play_card(5) and b.hand.size() == 6 and b.undo.is_empty() and b.units.size() == 6)
	b.aether = {"generic": 10, "d3": 10}
	b.phase = "draw"
	ck("cards: only on your turn", not b.can_act() and not b.play_state(b.hand[0])["ok"] and "your turn" in b.play_state(b.hand[0])["why"] and b.play_troop(0) == null and not b.use_consumable(0, warden))
	b.phase = "turn"
	# a Troop
	var from := b.log.size()
	ck("cards: the Player Spawn Tiles nobody stands on", b.open_spawns() == [Vector2i(-1, 6), Vector2i(0, 6)], b.open_spawns())
	var scout = b.play_troop(0, Vector2i(0, 6))
	ck("cards: a Troop lands on the open Player Spawn Tile chosen, at full Health", scout != null and Battle.tile_of(scout) == Vector2i(0, 6) and b.units.size() == 7 and scout["side"] == "ally" and scout["id"] == "a4" and scout["hp"] == scout["hpMax"] and b.looks.has("a4"), scout)
	ck("cards: it is paid for, leaves the hand, and its card stays with it", b.aether == {"generic": 9, "d3": 10} and b.hand.size() == 5 and scout["card"]["name"] == "Test Scout" and b.discard.is_empty() and _texts(b, from).has("Test Scout deployed"), [b.aether, _texts(b, from)])
	ck("cards: it can move and act the turn it arrives", b.can_move(scout) and not b.reach(scout).is_empty())
	ck("cards: Undo offers to take it back", b.undo_what() == {"kind": "card", "label": "Test Scout"}, b.undo_what())
	var back := b.undo_last()
	ck("cards: taken back: the Troop is gone, the card in hand, the Aether returned, the Log as it was", back["kind"] == "card" and back["label"] == "Test Scout" and b.units.size() == 6 and b.unit_by_id("a4") == null and _names(b.hand)[0] == "Test Scout" and b.hand.size() == 6 and b.aether == {"generic": 10, "d3": 10} and b.log.size() == from and b.undo.is_empty() and not b.looks.has("a4"), [back, b.aether])
	scout = b.play_troop(0)
	ck("cards: with no tile chosen it takes the first open one, under the same id", Battle.tile_of(scout) == Vector2i(-1, 6) and scout["id"] == "a4")
	b.hand.push_front(_hc(r, "Test Scout"))
	ck("cards: a tile that isn't an open spawn tile falls back to one that is", Battle.tile_of(b.play_troop(0, Vector2i(0, 0))) == Vector2i(0, 6))
	b.hand.push_front(_hc(r, "Test Battery"))
	ck("cards: with no Player Spawn Tile open, no Troop can be played, and it says so", b.open_spawns().is_empty() and not b.play_state(b.hand[0])["ok"] and "Every Player Spawn Tile is occupied" in b.play_state(b.hand[0])["why"] and b.play_troop(0) == null, b.play_state(b.hand[0]))
	b.hand.pop_front()
	# Equipment
	var ac0 := int(Rules.effective(drone)["ac"])
	from = b.log.size()
	ck("cards: Equipment goes on the Unit chosen, and its Passive is on while it's worn", b.play_equipment(0, drone) and drone["equipment"] == ["Test Plating"] and _names(drone["equipCards"]) == ["Test Plating"] and int(Rules.effective(drone)["ac"]) == ac0 + 2 and b.discard.is_empty() and _texts(b, from).has("Test Plating equipped on Test Drone"), [drone.get("equipment"), Rules.effective(drone)["ac"], ac0])
	b.undo_last()
	ck("cards: taken back, it's off again and in hand", drone.get("equipment", []).is_empty() and int(Rules.effective(drone)["ac"]) == ac0 and _names(b.hand)[0] == "Test Plating")
	b.play_equipment(0, drone)
	b.hand.push_front(_hc(r, "Test Plating"))
	var hand_n := b.hand.size()
	ck("cards: never onto an Enemy", not b.play_equipment(0, e1) and b.hand.size() == hand_n and not e1.has("equipment"))
	b.hand.pop_front()
	# a Command at a tile
	var paid := func(): return 20 - int(Rules.aether_total(b.aether))
	var spent0: int = paid.call()
	ck("cards: one that needs a tile isn't played without one", not b.play_card(0) and not b.play_card(0, e1) and _names(b.hand)[0] == "Test Mortar Strike")
	from = b.log.size()
	ck("cards: a Command aimed at a tile: everyone within its area takes its damage", b.play_card(0, null, Vector2i(0, -6)) and e1["hp"] == 16 and e2["hp"] == 20 and _texts(b, from)[0] == "Played Test Mortar Strike at 0,-6" and paid.call() == spent0 + 2, [e1["hp"], _texts(b, from)])
	ck("cards: and it is discarded as it's played", _names(b.discard) == ["Test Mortar Strike"] and b.floats.any(func(fl): return fl["unit"] == "e1" and fl["text"] == "-4 HP"))
	# on an Enemy
	ck("cards: one that needs an Enemy isn't played without one, or onto your own", not b.play_card(0) and not b.play_card(0, warden) and _names(b.hand)[0] == "Test Snare")
	from = b.log.size()
	var d3: int = b.aether["d3"]
	ck("cards: a Command on an Enemy does what it says, and pays its District's Aether", b.play_card(0, e1) and Rules.has_status(e1, "Rooted") and b.aether["d3"] == d3 - 1 and _texts(b, from)[0] == "Played Test Snare on \"Binder\" Cleaner Bot", [_texts(b, from), b.aether])
	# on one of yours, with an area; and with no target at all
	var hp0: int = drone["hpMax"]
	ck("cards: an Aether card on one of yours, and on everyone within its area of them", b.play_card(0, drone) and drone["hpMax"] == hp0 + 5 and drone["mods"].any(func(m): return m["stat"] == "MS" and m["amt"] == 1) and warden.get("mods", []).any(func(m): return m["stat"] == "MS" and m["source"] == "Test Surge"), [drone["hpMax"], drone.get("mods")])
	ck("cards: a card that needs no target is played through the leader", b.play_card(0) and warden["mods"].any(func(m): return m["stat"] == "AC" and m["amt"] == 1 and m["source"] == "Test Rally") and b.hand.is_empty(), warden.get("mods"))
	var a: Dictionary = b.undo_last()
	var a2: Dictionary = b.undo_last()
	ck("cards: Undo takes back the last card first, then the one before", a["label"] == "Test Rally" and a2["label"] == "Test Surge" and _names(b.hand) == ["Test Surge", "Test Rally"] and drone["hpMax"] == hp0 and not warden.get("mods", []).any(func(m): return m.get("source") == "Test Rally") and _names(b.discard) == ["Test Mortar Strike", "Test Snare"], [a, a2, _names(b.hand)])
	# a move and a card are taken back in the order they were made
	var before_move := Battle.tile_of(warden)
	b.move(warden, Vector2i(b.reach(warden)[0]["q"], b.reach(warden)[0]["r"]))
	b.play_card(1)
	ck("cards: a card played after a move is taken back first, then the move", b.undo_what()["label"] == "Test Rally" and b.undo_last()["kind"] == "card" and b.undo_what() == {"kind": "move", "label": "Test Warden's move"} and b.undo_last()["unit"] == warden and Battle.tile_of(warden) == before_move and b.undo_what()["label"] == "Test Snare", b.undo_what())
	# dice
	b.play_card(1)
	e1["pos"] = {"q": -4, "r": 4}
	_sure(_act(warden, "Pinning Volley"), e1)
	b.attack(warden, _act(warden, "Pinning Volley"), e1)
	ck("cards: once dice are rolled, what was played before stands", b.undo.is_empty() and b.undo_last().is_empty() and _names(b.hand) == ["Test Surge"])
	# when a card reaches the Discard Pile
	scout["hp"] = 0
	b.check_downs()
	ck("cards: a Troop's card reaches the Discard Pile when the Troop goes down, not before", _names(b.discard) == ["Test Mortar Strike", "Test Snare", "Test Rally", "Test Scout"] and scout["card"] == null, _names(b.discard))
	drone["hp"] = 0
	b.check_downs()
	b.check_downs()
	ck("cards: with the Equipment it wore; a Starting Troop's card too; and only once", _names(b.discard).slice(4) == ["Test Plating", "Test Drone"], _names(b.discard))
	var held := b.discard.size()
	e2["hp"] = 0
	warden["_test"] = 1
	b.check_downs()
	ck("cards: an Enemy going down discards nothing of yours", b.discard.size() == held)
	# Recover
	ck("cards: what a Recover could bring back: the Troops' cards in the Discard Pile", b.recoverable() == [3, 5], b.recoverable())
	from = b.log.size()
	ck("cards: a Consumable that Recovers returns the Troop's card chosen to your hand", b.consumable_state(2)["ok"] and b.use_consumable(2, null, null, 3) and _names(b.hand) == ["Test Surge", "Test Scout"] and _names(b.discard) == ["Test Mortar Strike", "Test Snare", "Test Rally", "Test Plating", "Test Drone"] and b.consumables[2]["used"], [_names(b.hand), _names(b.discard)])
	ck("cards: and the Log says so", _texts(b, from) == ["Used Test Repair Kit", "Test Scout returns to your hand from the Discard Pile"], _texts(b, from))
	ck("cards: a Consumable is used once", not b.consumable_state(2)["ok"] and b.consumable_state(2)["why"] == "Used." and not b.use_consumable(2))
	b.undo_last()
	ck("cards: taken back, it's unused and the card is in the Discard Pile where it lay", not b.consumables[2]["used"] and b.recoverable() == [3, 5] and _names(b.hand) == ["Test Surge"])
	b.use_consumable(2)
	ck("cards: with nothing chosen, the one discarded last returns", _names(b.hand) == ["Test Surge", "Test Drone"] and b.recoverable() == [3])
	b.discard = b.discard.filter(func(c): return c["type"] != "troop")
	b.consumables.append({"name": "Test Repair Kit", "used": false, "text": "[[Recover]] a Troop's card from the Discard Pile."})
	ck("cards: with no Troop's card there, a card that Recovers can't be used", not b.consumable_state(4)["ok"] and "there is none there" in b.consumable_state(4)["why"] and not b.use_consumable(4) and not b.consumables[4]["used"], b.consumable_state(4))
	ck("cards: the Recovered Troop is played again at its cost, its card with it once more", b.play_state(b.hand[1])["ok"] and b.play_troop(1) != null and b.units[b.units.size() - 1]["card"]["name"] == "Test Drone" and b.units[b.units.size() - 1]["hp"] == b.units[b.units.size() - 1]["hpMax"])
	# a Consumable on a Unit
	warden["hp"] = int(warden["hpMax"]) - 10
	var nrg0: int = warden["nrg"]
	ck("cards: a Consumable that needs one of yours isn't used without one", not b.use_consumable(0) and not b.use_consumable(0, e1) and not b.consumables[0]["used"])
	from = b.log.size()
	var total0: int = Rules.aether_total(b.aether)
	ck("cards: used on one, its keywords are carried out, at no Aether cost", b.use_consumable(0, warden) and warden["hp"] == int(warden["hpMax"]) - 4 and warden["nrg"] == nrg0 + 1 and Rules.aether_total(b.aether) == total0 and _texts(b, from)[0] == "Used Test Stim on Test Warden", [warden["hp"], warden["nrg"], _texts(b, from)])
	# a Chip's effect
	b.bank.append(Roster.chip_of("Test Spark Chip", r.card_named("Test Spark Chip")))
	var ci := b.bank.size() - 1
	ck("cards: a Chip with no effect has nothing to be spent for", not b.chip_state(0)["ok"] and b.chip_text(b.bank[0]) == "" and not b.spend_chip(0))
	from = b.log.size()
	ck("cards: a Chip with one is spent for it, on the Enemy chosen", b.chip_state(ci)["ok"] and b.chip_state(ci)["needs"]["need"] == "enemy" and not b.spend_chip(ci) and b.spend_chip(ci, e3) and e3["hp"] == 17 and b.bank[ci]["spent"] and _texts(b, from)[0] == "Spent Test Spark Chip on \"Binder\" Cleaner Bot 2", [e3["hp"], _texts(b, from)])
	ck("cards: once a round", not b.chip_state(ci)["ok"] and "Spent this round" in b.chip_state(ci)["why"] and not b.spend_chip(ci, e3) and e3["hp"] == 17)
	b.undo_last()
	ck("cards: taken back, it's face-up again", not b.bank[ci]["spent"] and e3["hp"] == 20)
	b.spend_chip(ci, e3)
	b.end_round()
	ck("cards: and it turns face-up again at the Recharge", not b.bank[ci]["spent"] and b.chip_state(ci)["ok"] and _texts(b).has("Recharge: 1 Chip turned face-up") and b.undo.is_empty(), _texts(b).slice(_texts(b).size() - 4))
	# a carried Action card's Aether
	var pr := _act(vex, "Piercing Rounds")
	var debt := _act(vex, "Mark of Debt")
	e3["pos"] = {"q": -3, "r": 4}
	vex["nrg"] = 6
	b.aether = {}
	ck("cards: a carried Action card costs its Aether as well as its Energy", pr["aether"] == {"generic": 0, "affinity": 1, "district": "3"} and b.action_state(vex, pr) == {"ok": false, "why": "Needs 1 D3 Aether"} and not debt.has("aether") and b.action_state(vex, debt)["ok"], [pr.get("aether"), b.action_state(vex, pr), b.action_state(vex, debt)])
	b.aether = {"d1": 4}
	ck("cards: another District's Aether won't do", not b.action_state(vex, pr)["ok"])
	b.aether = {"d3": 2}
	_sure(pr, e3)
	b.attack(vex, pr, e3)
	ck("cards: using it pays both", b.aether == {"d3": 1} and vex["nrg"] == 4, [b.aether, vex["nrg"]])
	_sure(debt, e3)
	e3["pos"] = {"q": -3, "r": 5}
	b.attack(vex, debt, e3)
	ck("cards: one of the Hero's own Actions leaves the Bank alone", b.aether == {"d3": 1} and vex["nrg"] == 3, [b.aether, vex["nrg"]])
	ck("cards: its line in the panel says both", UnitPanel.action_summary(pr).begins_with("2 NRG + 1 D3 Aether") and UnitPanel.action_summary(debt).begins_with("1 NRG ·"), UnitPanel.action_summary(pr))
	var ow := _act(warden, "Overwatch")
	ow["aether"] = {"generic": 0, "affinity": 2, "district": "3"}
	b.moved.erase(warden["id"])
	warden["nrg"] = 6
	ck("cards: holding fire with one needs its Aether", b.holdable(warden).is_empty())
	b.aether = {"d3": 5}
	ck("cards: and pays it", b.holdable(warden).size() == 1 and b.hold_fire(warden, "Overwatch") and b.aether == {"d3": 3}, b.aether)
	# plain text (0.23: given it for the test, as the audit wrote Burning Heart in keywords)
	_make_plain(r, "Burning Heart")
	b.hand = [_hc(r, "Burning Heart")]
	b.aether = {"generic": 5, "d3": 5}
	from = b.log.size()
	ck("cards: a card in plain text is paid for, discarded, and logged as not carried out", b.play_card(0) and Rules.aether_total(b.aether) == 7 and b.discard[b.discard.size() - 1]["name"] == "Burning Heart" and b.log.slice(from).any(func(l): return l.get("plain", false) and "Burning Heart has plain text" in l["text"]), _texts(b, from))
	# the Bank after a District card is paid for with Generic
	b.hand = [_hc(r, "Test Rally"), _hc(r, "Test Rally")]
	b.aether = {"generic": 5}
	ck("cards: paid for with Generic alone, a District card leaves the Bank able to pay for the next", b.play_card(0) and b.play_state(b.hand[0])["ok"] and b.play_card(0) and Rules.aether_total(b.aether) == 3, b.aether)
	# a card whose Deploy names nothing: the problem names the card, not the leader who played it
	_make_plain(r, "Deploy Sentry", "[[Deploy]] [[adjacent]].")     # (0.23: as it was written before the audit)
	b.hand = [_hc(r, "Deploy Sentry")]
	b.aether = {"generic": 9, "d1": 9, "d2": 9, "d3": 9, "d4": 9, "d5": 9, "d6": 9}
	b.halts.clear()
	ck("cards: a card from the hand whose Deploy names nothing is named in the problem", b.play_state(b.hand[0])["ok"] and b.play_card(0) and b.halts == ["Deploy Sentry: Deploy on Deploy Sentry does not name what to deploy."] and b.log[b.log.size() - 1]["text"] == "Deploy on Deploy Sentry does not name what to deploy.", [b.halts, b.log[b.log.size() - 1]["text"]])
	Rules.hooks = {}
	x.close()


# ---------------------------------------------------------------- the screen, playing cards
## Every line of text in an open card sheet.
func _sheet_note(scene: Node) -> String:
	return scene.sheet.note_label.text if scene.sheet != null else ""


func _play_scene() -> void:
	Kit.fresh()
	var team: Dictionary = Kit.team()
	Kit.keep([team])
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	var r: Roster = scene.roster
	var fi := -1
	for i in scene.floors.size():
		if scene.floors[i].name == "TEST · Hazards and Cover":
			fi = i
	scene.start_team_battle(fi, team, StrikeTeams.setup_for(team, r, ["Test Warden", "Quillon Vex"], "Test Warden", ["Test Drone"], 3), 21)
	await _frames(3)
	var bt: Battle = scene.battle
	var warden: Dictionary = bt.unit_by_id("a1")
	var vex: Dictionary = bt.unit_by_id("a2")
	var drone: Dictionary = bt.unit_by_id("a3")
	var e1: Dictionary = bt.unit_by_id("e1")
	var e2: Dictionary = bt.unit_by_id("e2")
	# (0.23) as before the effect box audit: Burning Heart in plain text, and the Enemies dealt here at 20 Health
	_make_plain(r, "Burning Heart")
	for e in bt.side_units("enemy"):
		e["hp"] = 20
		e["hpMax"] = 20
	bt.hand = ["Test Scout", "Test Plating", "Test Mortar Strike", "Test Snare", "Test Surge", "Test Rally", "Burning Heart"].map(func(n): return _hc(r, n))
	bt.aether = {"generic": 12, "d3": 12}
	scene._update_bar()
	await _frames(2)
	ck("play screen: along the bottom: Hand, and Consumables when the team carries any", scene.hand_btn.visible and scene.hand_btn.text == "Hand 7" and scene.cons_btn.visible and scene.cons_btn.text == "Consumables 4" and not scene.chips_btn.visible, [scene.hand_btn.text, scene.cons_btn.text])
	bt.bank.append(Roster.chip_of("Test Spark Chip", r.card_named("Test Spark Chip")))
	scene._update_bar()
	await _frames(2)
	ck("play screen: and Chips once the Bank holds one with an effect", scene.chips_btn.visible and scene.chips_btn.text == "Chips 1")
	ck("play screen: side by side, the bottom line beyond them", scene.hand_btn.offset_right <= scene.cons_btn.offset_left and scene.cons_btn.offset_right <= scene.chips_btn.offset_left and scene.info.offset_left >= scene.chips_btn.offset_right, [scene.hand_btn.offset_right, scene.cons_btn.offset_left, scene.chips_btn.offset_right, scene.info.offset_left])
	# the hand
	scene.hand_btn.pressed.emit()
	await _frames(3)
	var tray: HandTray = scene.hand_tray
	ck("play screen: the hand's tray: a card in plain text says so on its tile", tray.visible and tray.kind == "hand" and tray.grid.tiles.size() == 7 and tray.grid.tiles[6].plain and not tray.grid.tiles[2].plain and not tray.grid.tiles.any(func(t): return t.faded), tray.grid.tiles.map(func(t): return t.plain))
	tray.grid.tap(tray.grid.tile_centre(2))
	await process_frame
	ck("play screen: a card's sheet says how it's played, and has Play", scene.sheet != null and scene.sheet.card["name"] == "Test Mortar Strike" and "You choose where it lands" in _sheet_note(scene) and scene.sheet.buttons["play"].text == "Play" and not scene.sheet.buttons["play"].disabled, _sheet_note(scene))
	scene.sheet.buttons["play"].pressed.emit()
	await _frames(2)
	ck("play screen: Play puts the sheet and the tray away and asks where", scene.sheet == null and not tray.visible and scene.play.get("step") == "tile" and scene.play["name"] == "Test Mortar Strike" and "tap a tile" in scene.info.text and bt.hand.size() == 7, scene.info.text)
	ck("play screen: End turn and Undo wait while a card is being played", scene.next_btn.disabled and not scene.undo_btn.visible)
	_tap(scene, Vector2i(0, -6))
	await _frames(2)
	ck("play screen: the first tap on a tile lights its area and names who it takes in", scene.play.get("at") == Vector2i(0, -6) and scene.board.blast.size() >= 3 and scene.board.view_of("e1").caught and not scene.board.view_of("e2").caught and "\"Binder\" Cleaner Bot" in scene.info.text and bt.hand.size() == 7 and e1["hp"] == 20, scene.info.text)
	_tap(scene, Vector2i(3, -6))
	await _frames(2)
	ck("play screen: another tile moves it; nothing is spent yet", scene.play.get("at") == Vector2i(3, -6) and scene.board.view_of("e2").caught and not scene.board.view_of("e1").caught and Rules.aether_total(bt.aether) == 24)
	_tap(scene, Vector2i(3, -6))
	await _until(scene, "busy")
	ck("play screen: the same tile again plays it: paid, carried out, discarded", scene.play.is_empty() and bt.hand.size() == 6 and e2["hp"] == 16 and Rules.aether_total(bt.aether) == 22 and bt.discard.size() == 1 and scene.board.blast.is_empty() and scene.hand_btn.text == "Hand 6" and scene.piles_btn.text.ends_with("Discard 1"), [bt.hand.size(), e2["hp"], scene.piles_btn.text])
	ck("play screen: the bottom line says what it did, and the number rose off the Enemy", "Played Test Mortar Strike" in scene.info.text and "take" in scene.info.text and scene.board.view_of("e2").shown["hp"] == 16, scene.info.text)
	ck("play screen: Undo is offered for it", scene.undo_btn.visible and not scene.next_btn.disabled)
	scene.undo_btn.pressed.emit()
	await _frames(2)
	ck("play screen: Undo takes the card back: in hand, the Aether returned, the damage undone", bt.hand.size() == 7 and e2["hp"] == 20 and Rules.aether_total(bt.aether) == 24 and bt.discard.is_empty() and "Test Mortar Strike is taken back" in scene.info.text and not scene.undo_btn.visible and scene.board.view_of("e2").shown["hp"] == 20, scene.info.text)
	# a card on an Enemy, and changing your mind
	scene.begin_play("hand", 3)
	await _frames(2)
	scene._play_cancel()
	scene._stop_camera()
	var cam0: Vector2 = scene.camera.position
	var far: Vector2 = scene.board.to_local(scene.get_viewport().get_canvas_transform().affine_inverse() * Vector2(scene.get_viewport_rect().size.x - 180, 400))
	scene._frame([far], 0.0)
	var stayed: bool = scene._cam_tween == null
	scene._frame([far])
	ck("play screen: with the panel shut, what's lit under where it would be is already in view: the board stays put", stayed and scene._cam_tween != null)
	scene._stop_camera()
	scene.camera.position = cam0
	scene.begin_play("hand", 3)
	await _frames(2)
	ck("play screen: a card that needs an Enemy lights them", scene.play.get("step") == "target" and scene.play["pool"].size() == 3 and scene.board.view_of("e1").targeted and not scene.board.view_of("a1").targeted and "tap a lit Enemy" in scene.info.text, scene.info.text)
	_touch(scene, 0, Vector2(5, 700), true)
	_touch(scene, 0, Vector2(5, 700), false)
	ck("play screen: a tap anywhere else puts it back: nothing spent", scene.play.is_empty() and bt.hand.size() == 7 and Rules.aether_total(bt.aether) == 24 and "back in your hand" in scene.info.text and not scene.board.view_of("e1").targeted and not scene.next_btn.disabled, scene.info.text)
	scene.begin_play("hand", 3)
	_tap(scene, Battle.tile_of(e1))
	await _until(scene, "busy")
	ck("play screen: tap a lit Enemy and it's played on them", Rules.has_status(e1, "Rooted") and bt.hand.size() == 6 and "Played Test Snare on" in scene.info.text and scene.play.is_empty(), scene.info.text)
	# a Troop
	scene.begin_play("hand", 0)
	await _frames(2)
	ck("play screen: a Troop lights the open Player Spawn Tiles", scene.play.get("step") == "spawn" and scene.board.reach.size() == 2 and scene.board.reach.has(Vector2i(-1, 6)) and scene.board.reach.has(Vector2i(0, 6)) and "tap a lit Player Spawn Tile" in scene.info.text, scene.info.text)
	_tap(scene, Vector2i(0, 6))
	await _until(scene, "busy")
	var scout = bt.unit_at(Vector2i(0, 6))
	ck("play screen: tap one and it deploys there, chosen and ready to go", scout != null and scout["name"] == "Test Scout" and scene.selected_id == scout["id"] and scene.panel.visible and scene.panel.name_label.text == "Test Scout" and scene.board.view_of(scout["id"]) != null and "It can move and act now" in scene.info.text and not scene.board.reach.is_empty(), scene.info.text)
	scene.deselect()
	bt.hand.push_front(_hc(r, "Test Scout"))
	scene.begin_play("hand", 0)
	await _until(scene, "busy")
	ck("play screen: with one tile open, it goes there by itself", bt.unit_at(Vector2i(-1, 6)) != null and bt.unit_at(Vector2i(-1, 6))["name"] == "Test Scout" and scene.play.is_empty() and bt.open_spawns().is_empty())
	scene.deselect()
	bt.hand.push_front(_hc(r, "Test Battery"))
	scene._update_bar()
	scene.hand_btn.pressed.emit()
	await _frames(3)
	ck("play screen: a Troop with nowhere to land is faded in the tray", tray.grid.tiles[0].faded and tray.grid.tiles[0].card["name"] == "Test Battery" and not tray.grid.tiles[1].faded)
	tray.grid.tap(tray.grid.tile_centre(0))
	await process_frame
	ck("play screen: its sheet says why, and Play is off", scene.sheet != null and "Every Player Spawn Tile is occupied" in _sheet_note(scene) and scene.sheet.buttons["play"].disabled, _sheet_note(scene))
	scene.sheet.buttons["close"].pressed.emit()
	await _frames(2)
	bt.hand.pop_front()
	scene._update_bar()
	# Equipment
	tray.grid.tap(tray.grid.tile_centre(0))
	await process_frame
	scene.sheet.buttons["play"].pressed.emit()
	await _frames(2)
	ck("play screen: Equipment lights your Units", scene.play.get("step") == "unit" and scene.play["name"] == "Test Plating" and scene.board.view_of("a3").targeted and not scene.board.view_of("e1").targeted and "tap one of your Units to equip it" in scene.info.text, scene.info.text)
	_tap(scene, Battle.tile_of(drone))
	await _until(scene, "busy")
	ck("play screen: tap one and it's equipped", drone.get("equipment") == ["Test Plating"] and "Test Plating equipped on Test Drone" in scene.info.text, scene.info.text)
	_tap(scene, Battle.tile_of(drone))
	await _frames(2)
	var lines := _panel_text(scene)
	ck("play screen: its panel lists what it wears, with what it says", lines.has("Equipment") or lines.has("EQUIPMENT"), lines)
	ck("play screen: by name and text", lines.has("Test Plating") and lines.any(func(l): return "Attached Unit gains +2 AC" in l), lines)
	scene.deselect()
	# a card with an area round one of yours: two taps
	bt.hand = bt.hand.filter(func(c): return c["name"] != "Test Mortar Strike")
	scene._update_bar()
	ck("play screen: what is left in the hand", _names(bt.hand) == ["Test Surge", "Test Rally", "Burning Heart"], _names(bt.hand))
	scene.begin_play("hand", 0)
	await _frames(2)
	ck("play screen: a card on one of yours lights them", scene.play["name"] == "Test Surge" and scene.play.get("step") == "target" and scene.board.view_of("a1").targeted and not scene.board.view_of("e1").targeted)
	_tap(scene, Battle.tile_of(warden))
	await _frames(2)
	ck("play screen: with an area, the first tap shows it and who else it takes in", scene.play.get("at") == Battle.tile_of(warden) and not scene.board.blast.is_empty() and "its area takes in also" in scene.info.text and "your Quillon Vex" in scene.info.text and bt.hand.size() == 3, scene.info.text)
	_tap(scene, Battle.tile_of(warden))
	await _until(scene, "busy")
	ck("play screen: the second plays it", warden["mods"].any(func(m): return m["source"] == "Test Surge") and bt.hand.size() == 2 and scene.board.blast.is_empty())
	# no target at all
	scene.begin_play("hand", 0)
	await _until(scene, "busy")
	ck("play screen: a card that needs no target is simply played", scene.play.is_empty() and bt.hand.size() == 1 and "Played Test Rally" in scene.info.text, scene.info.text)
	# plain text
	scene.hand_btn.pressed.emit()
	await _frames(3)
	tray.grid.tap(tray.grid.tile_centre(0))
	await process_frame
	ck("play screen: a plain-text card's sheet warns that playing it won't make its text happen", "Some of its text is plain" in _sheet_note(scene) and not scene.sheet.buttons["play"].disabled and _labels(scene.sheet).any(func(l): return l.begins_with("Plain text: the game can't carry this out")), _sheet_note(scene))
	scene.sheet.buttons["play"].pressed.emit()
	await _until(scene, "busy")
	ck("play screen: played, it says its plain text wasn't carried out", bt.hand.is_empty() and "plain text wasn't carried out" in scene.info.text and bt.log.any(func(l): return l.get("plain", false)), scene.info.text)
	# opening a tray puts a card being played back
	bt.hand = [_hc(r, "Test Snare")]
	scene._update_bar()
	scene.begin_play("hand", 0)
	scene.cons_btn.pressed.emit()
	await _frames(3)
	ck("play screen: opening a tray puts a card being played back", scene.play.is_empty() and bt.hand.size() == 1 and tray.visible and tray.kind == "cons")
	# Consumables
	ck("play screen: Consumables: a tile for each kind, counting what's left", tray.grid.tiles.size() == 3 and tray.grid.tiles.map(func(t): return [t.card["name"], t.count]) == [["Test Stim", 2], ["Test Repair Kit", 1], ["Test Sandbags", 1]] and "4 to use" in tray.title.text, tray.grid.tiles.map(func(t): return [t.card["name"], t.count]))
	ck("play screen: one that can't be used now is faded", tray.grid.tiles[1].faded and not tray.grid.tiles[0].faded)
	tray.grid.tap(tray.grid.tile_centre(1))
	await process_frame
	ck("play screen: a Repair Kit with nothing to Recover says so, and Use is off", scene.sheet != null and scene.sheet.card["name"] == "Test Repair Kit" and "there is none there" in _sheet_note(scene) and scene.sheet.buttons["play"].text == "Use" and scene.sheet.buttons["play"].disabled, _sheet_note(scene))
	scene.sheet.buttons["close"].pressed.emit()
	await _frames(2)
	warden["hp"] = int(warden["hpMax"]) - 9
	tray.grid.tap(tray.grid.tile_centre(0))
	await process_frame
	ck("play screen: a Consumable's sheet: no Aether cost, how many are left, and Use", "costs no Aether" in _sheet_note(scene) and "2 left" in _sheet_note(scene) and not scene.sheet.buttons["play"].disabled, _sheet_note(scene))
	scene.sheet.buttons["play"].pressed.emit()
	await _frames(2)
	ck("play screen: Use lights who it can go to", scene.play.get("kind") == "cons" and scene.play.get("step") == "target" and scene.board.view_of("a1").targeted)
	_tap(scene, Battle.tile_of(warden))
	await _until(scene, "busy")
	ck("play screen: tapped, it does what it says, and one fewer is left", warden["hp"] == int(warden["hpMax"]) - 3 and scene.cons_btn.text == "Consumables 3" and "Used Test Stim on Test Warden" in scene.info.text, [warden["hp"], scene.cons_btn.text, scene.info.text])
	scene.undo_btn.pressed.emit()
	await _frames(2)
	ck("play screen: Undo takes a Consumable back too", warden["hp"] == int(warden["hpMax"]) - 9 and scene.cons_btn.text == "Consumables 4" and "Test Stim is taken back" in scene.info.text, scene.info.text)
	# Recover: two Troops' cards in the Discard Pile
	for id in [drone["id"], bt.unit_at(Vector2i(0, 6))["id"]]:
		bt.unit_by_id(id)["hp"] = 0
	bt.check_downs()
	scene.board.refresh_units(bt)
	scene._update_bar()
	ck("play screen: Troops gone down, their cards are in the Discard Pile", bt.recoverable().size() == 2 and scene.piles_btn.text.ends_with("Discard %d" % bt.discard.size()), scene.piles_btn.text)
	scene.piles_btn.pressed.emit()
	await _frames(3)
	ck("play screen: tap the Deck and Discard count to look through the Discard Pile, newest first", tray.visible and tray.kind == "discard" and tray.grid.tiles.size() == bt.discard.size() and tray.grid.tiles[0].card["name"] == bt.discard[bt.discard.size() - 1]["name"], tray.grid.tiles.map(func(t): return t.card["name"]))
	tray.grid.tap(tray.grid.tile_centre(0))
	await process_frame
	ck("play screen: a discarded card can be read, not played", scene.sheet != null and not scene.sheet.buttons.has("play") and "In the Discard Pile" in _sheet_note(scene))
	scene.sheet.buttons["close"].pressed.emit()
	await _frames(2)
	scene.cons_btn.pressed.emit()
	await _frames(3)
	ck("play screen: now the Repair Kit can be used", tray.kind == "cons" and not tray.grid.tiles[1].faded)
	tray.grid.tap(tray.grid.tile_centre(1))
	await process_frame
	scene.sheet.buttons["play"].pressed.emit()
	await _frames(3)
	ck("play screen: with two to choose from, it asks which Troop", scene.play.get("step") == "recover" and tray.visible and tray.kind == "recover" and tray.grid.tiles.size() == 2 and "returns to your hand" in tray.title.text and not bt.consumables[2]["used"], tray.title.text)
	tray.close_btn.pressed.emit()
	await _frames(2)
	ck("play screen: Close puts the Repair Kit back, unused", scene.play.is_empty() and not tray.visible and not bt.consumables[2]["used"] and "back with your Consumables" in scene.info.text, scene.info.text)
	scene.begin_play("cons", 2)
	await _frames(3)
	var chosen: String = tray.grid.tiles[1].card["name"]
	tray.grid.tap(tray.grid.tile_centre(1))
	await _until(scene, "busy")
	await _frames(2)
	ck("play screen: tap one and that Troop's card is back in your hand", bt.consumables[2]["used"] and bt.hand[bt.hand.size() - 1]["name"] == chosen and bt.recoverable().size() == 1 and not tray.visible and ("%s returns to your hand" % chosen) in scene.info.text, [chosen, scene.info.text])
	# a Chip's effect
	scene.chips_btn.pressed.emit()
	await _frames(3)
	ck("play screen: Chips: only those with an effect", tray.kind == "chips" and tray.grid.tiles.size() == 1 and tray.grid.tiles[0].card["name"] == "Test Spark Chip" and "1 ready" in tray.title.text)
	tray.grid.tap(tray.grid.tile_centre(0))
	await process_frame
	ck("play screen: a Chip's sheet has Spend", scene.sheet != null and scene.sheet.buttons["play"].text == "Spend" and "has generated its Aether this turn" in _sheet_note(scene), _sheet_note(scene))
	scene.sheet.buttons["play"].pressed.emit()
	await _frames(2)
	var e3: Dictionary = bt.unit_by_id("e3")
	_tap(scene, Battle.tile_of(e3))
	await _until(scene, "busy")
	ck("play screen: spent on an Enemy, its effect happens", e3["hp"] == 17 and scene.chips_btn.text == "Chips 0" and "Spent Test Spark Chip on" in scene.info.text, [e3["hp"], scene.chips_btn.text])
	scene.chips_btn.pressed.emit()
	await _frames(3)
	ck("play screen: and its tile reads Spent until the Recharge", tray.grid.tiles[0].mark == "Spent" and tray.grid.tiles[0].faded)
	tray.close_btn.pressed.emit()
	# a carried Action card's Aether, in the panel
	bt.aether = {}
	scene._update_bar()
	_tap(scene, Battle.tile_of(vex))
	await _frames(2)
	lines = _panel_text(scene)
	ck("play screen: a carried Action card shows its Aether cost, and what it needs when the Bank is short", lines.any(func(l): return l.begins_with("2 NRG + 1 D3 Aether")) and lines.has("Needs 1 D3 Aether"), lines)
	scene._say("A long line. " + "Tap a lit tile to move there or an Action to attack, or tap anywhere else to cancel. ".repeat(3))
	await _frames(3)
	var ir: Rect2 = scene.info.get_global_rect()
	# (0.14) one line, cut with "…", and a "?" that reads all of it
	ck("play screen: beside three buttons and the panel, a long bottom line keeps to one line, and a ? reads the rest", ir.end.y <= scene.get_viewport_rect().size.y + 0.5 and ir.size.y <= 50 and ir.position.x >= scene.chips_btn.get_global_rect().end.x and scene.info_more.visible and scene.info_more.get_global_rect().position.x >= ir.end.x - 1, [ir, scene.info_more.get_global_rect()])
	scene.deselect()
	# the round turns over with a card half played
	bt.hand = [_hc(r, "Test Snare")]
	bt.aether = {"generic": 5, "d3": 5}
	scene._update_bar()
	scene.begin_play("hand", 0)
	scene.run_enemy_phase()
	await process_frame
	ck("play screen: ending the turn puts a card being played back first", scene.play.is_empty() and bt.hand.size() == 1 and scene.busy)
	await _play_out(scene)
	ck("play screen: next round, nothing from the last can be taken back", bt.round == 2 and not scene.undo_btn.visible and bt.undo.is_empty() and not bt.bank[bt.bank.size() - 1]["spent"])
	scene.queue_free()
	Kit.fresh()
	await process_frame


# ---------------------------------------------------------------- 0.7: finishing the fight
## Variable costs, Dimensional Instability, loot, Auto and the Behavior
## keywords you choose, without a screen.
func _seven() -> void:
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)
	var lf := _floor_named(x, "TEST · Loot")
	var t: Dictionary = Kit.team()
	for n in ["Test Swarm", "Test Barrage", "Test Capacitor", "Test Drone Bank"]:
		t["deck"][n] = 2
	t["actions"] = {"Quillon Vex": ["Test Overcharge"]}
	var hc := func(n): return Roster.hand_card(r.card_named(n))
	# ---- a variable cost, as it reads
	ck("variable cost: X where the card says X", Roster.cost_label(hc.call("Test Swarm")) == "X D3" and Roster.cost_label(hc.call("Test Capacitor")) == "1 D3 + X◇" and Roster.cost_label(hc.call("Test Drone Bank")) == "XX◇",
		[Roster.cost_label(hc.call("Test Swarm")), Roster.cost_label(hc.call("Test Capacitor")), Roster.cost_label(hc.call("Test Drone Bank"))])
	ck("variable cost: and what it comes to once X is chosen", Roster.cost_label(hc.call("Test Swarm"), 3) == "3 D3" and Roster.cost_label(hc.call("Test Capacitor"), 2) == "1 D3 + 2◇" and Roster.cost_label(hc.call("Test Drone Bank"), 2) == "4◇",
		[Roster.cost_label(hc.call("Test Swarm"), 3), Roster.cost_label(hc.call("Test Drone Bank"), 2)])
	ck("variable cost: only a card that has one", Roster.card_var(hc.call("Test Swarm")) and not Roster.card_var(hc.call("Test Drone")) and Roster.cost_label(hc.call("Test Drone")) == "1◇")
	ck("variable cost: the least it can cost counts X as 1", Roster.cost_least(r.card_named("Test Swarm")) == 1 and Roster.cost_least(r.card_named("Test Capacitor")) == 2 and Roster.cost_least(r.card_named("Test Drone Bank")) == 2 and Roster.cost_least(r.card_named("Test Sapper")) == 2)
	var lean := StrikeTeams.blank("Lean")
	lean["heroes"] = ["Test Warden"]
	lean["deck"] = {"Test Drone Bank": 1, "Test Drone": 1}
	ck("variable cost: the Pouch must cover the dearest card at its least", StrikeTeams.pouch_minimum(lean, r) == 2, StrikeTeams.pouch_minimum(lean, r))
	var an := Keywords.analyse("[[target enemy]] takes [[damage X]].")
	ck("variable cost: X in the text of a card without one is a card problem", Keywords.problems(an, {"kind": "action", "variable": false}).any(func(p): return "X needs a variable cost" in str(p)) and not Keywords.problems(an, {"kind": "action", "variable": true}).any(func(p): return "X needs" in str(p)) and not Keywords.problems(an, {"kind": "action"}).any(func(p): return "X needs" in str(p)), Keywords.problems(an, {"kind": "action", "variable": false}))
	ck("variable cost: X is filled in only where a keyword takes a number", Keywords.fill_x("[[Deploy X Test Drone]]. [[Deploy 2 Model X]]. X marks it.", 3) == "[[Deploy 3 Test Drone]]. [[Deploy 2 Model X]]. X marks it." and Keywords.uses_x("[[damage X]]") and not Keywords.uses_x("[[Deploy 2 Model X]]"), Keywords.fill_x("[[Deploy X Test Drone]]. [[Deploy 2 Model X]]. X marks it.", 3))
	# ---- playing them
	var su := StrikeTeams.setup_for(t, r, ["Test Warden", "Quillon Vex"], "Test Warden", ["Test Swarm"], 3)
	var b := Battle.begin_team(lf, r, su, 31)
	var starter: Dictionary = b.side_units("ally").filter(func(u): return u["name"] == "Test Swarm")[0]
	ck("variable cost: a Starting Troop pays nothing, so its X is 1", starter["hpMax"] == 4 and starter.get("x") == 1 and "[[damage 1]]" in str(starter["actions"][0]["text"]), [starter["hpMax"], starter.get("x"), starter["actions"][0]["text"]])
	b.hand = [hc.call("Test Swarm"), hc.call("Test Barrage"), hc.call("Test Capacitor"), hc.call("Test Drone Bank"), hc.call("Test Swarm")]
	b.aether = {"generic": 4, "d3": 3}
	ck("variable cost: the most X the Bank could pay", b.max_x(b.hand[0]) == 3 and b.max_x(b.hand[1]) == 7 and b.max_x(b.hand[2]) == 6 and b.max_x(b.hand[3]) == 3, [b.max_x(b.hand[0]), b.max_x(b.hand[1]), b.max_x(b.hand[2]), b.max_x(b.hand[3])])
	var st := b.play_state(b.hand[0])
	ck("variable cost: it can be played while the Bank covers X = 1", st["ok"] and st["variable"] and st["max_x"] == 3 and not b.play_state(hc.call("Test Drone"))["variable"])
	var before := [b.hand.size(), b.aether.duplicate(), b.units.size()]
	ck("variable cost: an X the Bank can't pay is refused, and nothing is spent", b.play_troop(0, null, 4) == null and b.play_troop(0, null, 99) == null and [b.hand.size(), b.aether, b.units.size()] == before, [b.hand.size(), b.aether, b.units.size()])
	var from := b.log.size()
	var sw = b.play_troop(0, null, 2)
	ck("variable cost: a Troop played for X = 2 costs 2, and its numbers are for each X", sw != null and sw["hpMax"] == 8 and sw["hp"] == 8 and sw.get("x") == 2 and b.aether.get("d3", 0) == 1 and "[[damage 2]]" in str(sw["actions"][0]["text"]),
		[sw["hpMax"] if sw != null else null, b.aether])
	ck("variable cost: the log says which X", _texts(b, from).has("Test Swarm deployed (X = 2)"), _texts(b, from))
	var took := b.undo_last()
	ck("variable cost: taken back, the card and its Aether return", took.get("label") == "Test Swarm" and b.hand.size() == 5 and b.aether == {"generic": 4, "d3": 3} and b.unit_by_id(str(sw["id"])) == null, [took, b.hand.size(), b.aether])
	var one = b.play_troop(0)
	ck("variable cost: played without choosing, X is 1", one != null and one["hpMax"] == 4 and one.get("x") == 1 and b.aether.get("d3", 0) == 2, [one["hpMax"] if one != null else null, b.aether])
	var foe: Dictionary = b.side_units("enemy")[0]
	var hp0: int = foe["hp"]
	var played := b.play_card(0, foe, null, null, 3)
	ck("variable cost: a Command's X is in what it does", played and foe["hp"] == hp0 - 3 and foe["statuses"].any(func(s): return s["name"] == "Weakened" and int(Rules.num(s.get("n"), 0)) == 3) and Rules.aether_total(b.aether) == 3, [played, hp0, foe["hp"], foe["statuses"], b.aether])
	var warden: Dictionary = b.unit_by_id("a1")
	var whp: int = int(warden["hpMax"])
	ck("variable cost: with a fixed part too, X is what's left", b.max_x(b.hand[0]) == 2 and b.hand[0]["name"] == "Test Capacitor", b.max_x(b.hand[0]))
	var worn := b.play_equipment(0, warden, 2)
	ck("variable cost: Equipment gives its X for as long as it's worn", worn and int(Rules.num(warden["hpMax"], 0)) == whp + 2 and Rules.aether_total(b.aether) == 0, [worn, warden["hpMax"], b.aether])
	b.aether = {"generic": 4}
	# (a Deploy needs open Player Spawn Tiles: the two Swarms step off theirs)
	starter["pos"] = {"q": 0, "r": 0}
	one["pos"] = {"q": 1, "r": 0}
	var n0 := b.units.size()
	ck("variable cost: XX is X paid twice", b.play_card(0, null, null, null, 2) and b.units.size() == n0 + 2 and Rules.aether_total(b.aether) == 0 and b.units.slice(n0).all(func(u): return str(u["name"]).begins_with("Test Drone")), [b.units.size() - n0, b.aether])
	b.aether = {}
	var short := b.play_state(b.hand[0])
	ck("variable cost: with the Bank short of X = 1 it can't be played, and says what it needs at least", not short["ok"] and "at least" in str(short["why"]) and b.hand[0]["name"] == "Test Swarm", short["why"])
	# X in a card's text, with no variable cost to give it a value
	var lost: Dictionary = hc.call("Test Barrage").duplicate(true)
	lost["cost"] = {"generic": 0, "affinity": 0}
	b.hand = [lost]
	b.halts.clear()
	b.play_card(0, foe)
	ck("variable cost: X with nothing to give it a value stops on a card problem", b.halts.any(func(h): return "X has no value here" in str(h)), b.halts)
	# a carried Action card
	var vex: Dictionary = b.unit_by_id("a2")
	var oc := _act(vex, "Overcharge")
	ck("variable cost: a carried Action card reads X beside its Energy", oc.get("aetherX") is Dictionary and Battle.action_aether_words(oc) == "X D3" and "X D3 Aether" in UnitPanel.action_summary(oc), UnitPanel.action_summary(oc))
	b.aether = {"d3": 3}
	foe["pos"] = {"q": int(vex["pos"]["q"]), "r": int(vex["pos"]["r"]) - 2}
	foe["hp"] = 40
	foe["hpMax"] = 40
	ck("variable cost: and can be used for as much as the Bank could pay", b.action_max_x(oc) == 3 and b.action_state(vex, oc)["ok"], [b.action_max_x(oc), b.action_state(vex, oc)])
	Battle.set_action_x(oc, 3)
	b.attack(vex, oc, foe)
	ck("variable cost: used for X = 3, it reads so and takes 3", "[[damage 3]]" in str(oc["text"]) and b.aether.get("d3", 0) == 0, [oc["text"], b.aether])
	Battle.set_action_x(oc, 1)
	ck("variable cost: with no Aether left it can't be used", "[[damage 1]]" in str(oc["text"]) and not b.action_state(vex, oc)["ok"], b.action_state(vex, oc))
	# ---- Usability Restrictions are gone (Handbook 15.8)
	ck("usability: no card restricts who may use it", r.cards.all(func(c): return not c.has("usableBySubtype")))
	var plate = r.card_named("Subdermal Armor Plating 2")
	if plate != null:
		# an Action card that only a Cyborg could carry before 15.8
		var tu: Dictionary = Kit.team()
		tu["actions"] = {}
		var bare: int = Battle.begin_team(lf, r, StrikeTeams.setup_for(tu, r, ["Quillon Vex"], "Quillon Vex", [], 3), 4).unit_by_id("a1")["actions"].size()
		tu["actions"] = {"Quillon Vex": ["Subdermal Armor Plating 2"]}
		var with_it: int = Battle.begin_team(lf, r, StrikeTeams.setup_for(tu, r, ["Quillon Vex"], "Quillon Vex", [], 3), 4).unit_by_id("a1")["actions"].size()
		ck("usability: any Hero may carry any Action card, and the builder has nothing to say about it", with_it == bare + 1 and not StrikeTeams.pings(tu, r).any(func(p): return "usable" in str(p).to_lower() or "cyborg" in str(p).to_lower() or "may not use" in str(p).to_lower()), [bare, with_it, StrikeTeams.pings(tu, r)])

	# ---- Dimensional Instability
	var wf := _floor_named(x, "TEST · Waves")
	var su9 := StrikeTeams.setup_for(t, r, ["Test Warden"], "Test Warden", [], 3, 9)
	ck("instability: set as the Battle is set up, 0 unless it is", su9["instability"] == 9 and Battle.begin_team(wf, r, su9, 5).instability == 9 and StrikeTeams.setup_for(t, r, ["Test Warden"], "Test Warden", [], 3)["instability"] == 0)
	var calm := Battle.begin_team(wf, r, StrikeTeams.setup_for(t, r, ["Test Warden"], "Test Warden", [], 3), 5)
	ck("instability: at 0, nothing unusual comes", calm.side_units("enemy").all(func(e): return str(e["cardType"]).to_lower() == "enemy") and not _texts(calm).any(func(l): return l.begins_with("Dimensional instability")))
	var su100 := StrikeTeams.setup_for(t, r, ["Test Warden"], "Test Warden", [], 3, 100)
	var bi := Battle.begin_team(wf, r, su100, 5)
	var foes := bi.side_units("enemy")
	ck("instability: at 100, every spawn brings an Elite or a Mini-Boss of the floor's District, whatever the tile's level (0.22: the Skitter Stalker and the Brood Matriarch among them)", foes.size() == 4 and foes.all(func(e): return ["Test Juggernaut", "Test Overseer", "Skitter Stalker", "Brood Matriarch"].has(str(e["src"]))) and _texts(bi).filter(func(l): return l.begins_with("Dimensional instability: ") and l.ends_with(" arrives in place of an ordinary Enemy")).size() == 4,
		[foes.map(func(e): return e["name"]), _texts(bi).slice(0, 5)])
	ck("instability: the same seed sends the same", Battle.begin_team(wf, r, su100, 5).side_units("enemy").map(func(e): return e["name"]) == foes.map(func(e): return e["name"]))
	var f5 := FloorData.from_dict(wf.raw)
	f5.district = "5"
	var b5 := Battle.begin_team(f5, r, su100, 5)
	ck("instability: a District with no Elite or Mini-Boss sends the ordinary Enemy after all, and says so", not b5.side_units("enemy").any(func(e): return ["elite", "miniboss"].has(str(e["cardType"]).to_lower())) and _texts(b5).any(func(l): return l.begins_with("Dimensional instability stirs, but District 5 has no ") and l.ends_with(": an ordinary Enemy arrives")), _texts(b5).slice(0, 4))

	# ---- loot
	var bl := Battle.begin_team(lf, r, StrikeTeams.setup_for(t, r, ["Test Warden", "Quillon Vex"], "Test Warden", [], 3), 77)
	ck("loot: the floor's Skull Level, its Loot Tiles and its Locked Chests", bl.poi_skull() == 2 and bl.kind_at(Vector2i(-2, 4)) == "loot" and bl.kind_at(Vector2i(0, 0)) == "" and bl.chest_at(Vector2i(-3, 5)) == 0 and bl.chest_at(Vector2i(3, 1)) == 3 and bl.chest_at(Vector2i(0, 0)) == -1,
		[bl.poi_skull(), bl.kind_at(Vector2i(-2, 4)), bl.chest_at(Vector2i(-3, 5)), bl.chest_at(Vector2i(3, 1))])
	ck("loot: nothing to begin with", Loot.is_empty(bl.loot) and bl.looted.is_empty() and bl.loot_result.is_empty())
	var le: Dictionary = bl.side_units("enemy")[0]
	le["hp"] = 0
	bl.check_downs()
	var last: Dictionary = bl.log[bl.log.size() - 1]
	ck("loot: an Enemy that goes down drops its loot, and the log says what", not Loot.is_empty(bl.loot) and bl.loot["shards"] >= 1 and last["kind"] == "loot" and str(last["text"]).begins_with(str(le["name"]) + " drops: ") and str(last["text"]).ends_with(bl.loot_table.text(bl.loot)), last)
	ck("loot: a number rises off it", bl.floats.any(func(f): return f["kind"] == "loot" and f["unit"] == le["id"] and str(f["text"]).begins_with("+")), bl.floats)
	var held := Loot.norm(bl.loot)
	bl.check_downs()
	bl.salvage(le)
	ck("loot: once", Loot.norm(bl.loot) == held)
	var lw: Dictionary = bl.unit_by_id("a1")
	var lv: Dictionary = bl.unit_by_id("a2")
	lw["pos"] = {"q": -2, "r": 5}
	var lines0 := bl.log.size()
	var walked := bl.move(lw, Vector2i(-2, 4))
	var found := Loot.norm(bl.loot)
	ck("loot: one of yours that ends a move on a Loot Tile finds what's there", not walked.is_empty() and bl.looted.has(Vector2i(-2, 4)) and found != held and _texts(bl, lines0).any(func(l): return l.begins_with("Test Warden finds: ")), _texts(bl, lines0))
	bl.undo_last()
	ck("loot: a move taken back takes what it found back too", Loot.norm(bl.loot) == held and bl.looted.is_empty() and not _texts(bl, lines0).any(func(l): return " finds: " in l), [bl.loot, bl.looted])
	bl.move(lw, Vector2i(-2, 4))
	ck("loot: and the same move finds the same again", Loot.norm(bl.loot) == found and bl.looted.size() == 1)
	lw["pos"] = {"q": -2, "r": 5}
	lv["pos"] = {"q": -2, "r": 4}
	bl.find_loot(lv)
	ck("loot: a tile gives up its loot once a fight", Loot.norm(bl.loot) == found)
	bl.moved.clear()
	lv["pos"] = {"q": 3, "r": 2}
	var c0 := Loot.count(bl.loot)
	lines0 = bl.log.size()
	bl.move(lv, Vector2i(3, 1))
	ck("loot: a Locked Chest marked LC3 holds three components", Loot.count(bl.loot) - c0 == 3 and bl.looted.has(Vector2i(3, 1)) and _texts(bl, lines0).any(func(l): return l.begins_with("Quillon Vex opens a Locked Chest: ")), [Loot.count(bl.loot) - c0, _texts(bl, lines0)])
	c0 = Loot.count(bl.loot)
	bl.move(lw, Vector2i(-3, 5))
	ck("loot: one marked LC holds the usual two", Loot.count(bl.loot) - c0 == 2 and bl.looted.has(Vector2i(-3, 5)), Loot.count(bl.loot) - c0)
	var le2: Dictionary = bl.side_units("enemy")[1]
	le2["pos"] = {"q": 2, "r": -2}
	var kept := Loot.norm(bl.loot)
	bl.find_loot(le2)
	ck("loot: an Enemy finds nothing", Loot.norm(bl.loot) == kept and not bl.looted.has(Vector2i(2, -2)))
	# the fight is won: the floor's own reward
	for e in bl.side_units("enemy"):
		e["hp"] = 0
	bl.check_downs()
	bl.wave = bl.waves_total
	bl.enemy_pile.clear()
	var haul := Loot.norm(bl.loot)
	ck("loot: won, the floor's own reward is rolled", bl.settle() and bl.winner == "ally" and bl.loot_result["won"] and bl.loot_result["haul"] == haul and bl.loot_result["reward"]["shards"] == 12 and bl.loot_result["reward"]["parts"]["equipment"][2] >= 1 and Loot.count(bl.loot_result["reward"]) == 3,
		bl.loot_result.get("reward"))
	ck("loot: and the total is the two together", bl.loot_result["total"] == Loot.add(haul, bl.loot_result["reward"]) and bl.log.any(func(l): return l["kind"] == "loot" and str(l["text"]).begins_with("The floor's reward: ")))
	var settled: Dictionary = bl.loot_result.duplicate(true)
	bl.settle()
	ck("loot: settled once", bl.loot_result == settled)
	# lost
	var bx := Battle.begin_team(lf, r, StrikeTeams.setup_for(t, r, ["Test Warden"], "Test Warden", [], 3), 77)
	var xe: Dictionary = bx.side_units("enemy")[0]
	xe["hp"] = 0
	bx.check_downs()
	bx.unit_by_id("a1")["hp"] = 0
	bx.check_downs()
	ck("loot: lost, there is no reward", bx.settle() and bx.winner == "enemy" and not bx.loot_result["won"] and Loot.is_empty(bx.loot_result["reward"]) and not Loot.is_empty(bx.loot_result["haul"]) and bx.loot_result["total"] == bx.loot_result["haul"], bx.loot_result)
	# the same seed drops the same
	var s1 := Battle.begin_team(lf, r, StrikeTeams.setup_for(t, r, ["Test Warden"], "Test Warden", [], 3), 77)
	s1.side_units("enemy")[0]["hp"] = 0
	s1.check_downs()
	ck("loot: the same seed drops the same", Loot.norm(s1.loot) == bx.loot_result["haul"])
	var qb := Battle.begin(lf, r, [r.card_named("Test Warden")], [], 9)
	qb.side_units("enemy")[0]["hp"] = 0
	qb.check_downs()
	ck("loot: a Quick battle drops loot too", not Loot.is_empty(qb.loot) and qb.instability == 0)
	ck("loot: an Elite is worth more than an Enemy, by the tables", Loot.source_for("elite") == "elite" and Loot.source_for("miniboss") == "miniboss" and Loot.source_for("enemy") == "enemy" and Loot.source_for("troop") == "enemy", [Loot.source_for("elite"), Loot.source_for("troop")])

	# ---- Auto
	var cf := _floor_named(x, "TEST · Corridor")
	var mk := func(seed):
		var w := _mk(r, "Test Warden", "ally", "a1", Vector2i(0, 0))
		var s := _mk(r, "Test Striker", "ally", "a2", Vector2i(0, 1))
		var g1 := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(3, 0))
		var g2 := _mk(r, "Test Gunner", "enemy", "e2", Vector2i(4, 0))
		return Battle.from_state(cf, [w, s, g1, g2], seed, r.cards)
	var ba: Battle = mk.call(3)
	var aw: Dictionary = ba.unit_by_id("a1")
	var as2: Dictionary = ba.unit_by_id("a2")
	ck("auto: every Unit of yours you haven't used is in line", ba.auto_queue() == ["a1", "a2"] and not ba.has_acted(aw))
	ba.move(as2, Vector2i(1, 1))
	ck("auto: one you've moved is left to you", ba.auto_queue() == ["a1"] and ba.has_acted(as2))
	aw["behaviors"] = [{"k": "steadfast"}]
	var beats := ba.auto_turn(aw)
	ck("auto: Steadfast, it holds its tile and attacks the closest Enemy in reach", Battle.tile_of(aw) == Vector2i(0, 0) and beats.any(func(bt): return bt["type"] == "attack" and bt["target"] == "e1") and not beats.any(func(bt): return bt["type"] == "move"), beats.map(func(bt): return [bt["type"], bt.get("target")]))
	ck("auto: every beat of its turn is whole", not beats.is_empty() and beats.all(func(bt): return bt.has("after") and bt.has("floats") and bt.has("lines")))
	ck("auto: it has had its turn: it can't move again, and nothing is taken back", ba.has_acted(aw) and not ba.can_move(aw) and ba.undo.is_empty() and ba.auto_queue().is_empty())
	ba.begin_round()
	ck("auto: next round, everyone is in line again", ba.auto_queue() == ["a1", "a2"])
	var bd: Battle = mk.call(4)
	bd.unit_by_id("a1")["behaviors"] = [{"k": "decisive"}]
	bd.unit_by_id("e2")["hp"] = 3
	var db := bd.auto_turn(bd.unit_by_id("a1"))
	ck("auto: Decisive, it goes for the Enemy with the least Health", db.any(func(bt): return bt["type"] == "attack" and bt["target"] == "e2") and not db.any(func(bt): return bt["type"] == "attack" and bt["target"] == "e1"), db.map(func(bt): return [bt["type"], bt.get("target")]))
	var bp: Battle = mk.call(5)
	var pw: Dictionary = bp.unit_by_id("a1")
	pw["behaviors"] = [{"k": "prudent", "x": 5}]
	pw["hp"] = 4
	var pb := bp.auto_turn(pw)
	ck("auto: Prudent 5 at 4 Health, it withdraws and takes no Action", not pb.any(func(bt): return bt["type"] == "attack") and _texts(bp).any(func(l): return l.begins_with("Test Warden holds back")) and Rules.hex_distance(pw["pos"], bp.unit_by_id("e1")["pos"]) > 3, [_texts(bp), pw["pos"]])
	var bm: Battle = mk.call(6)
	var mw: Dictionary = bm.unit_by_id("a1")
	mw["behaviors"] = [{"k": "medic"}]
	bm.unit_by_id("a2")["hp"] = 10
	var mb := bm.auto_turn(mw)
	ck("auto: a Medic tends the most wounded of its own first", bm.unit_by_id("a2")["hp"] == 15 and _texts(bm).any(func(l): return l.begins_with("Test Warden used Field Medicine on Test Striker")) and not mb.any(func(bt): return bt["type"] == "attack"), _texts(bm))
	var bn: Battle = mk.call(7)
	var ns: Dictionary = bn.unit_by_id("a2")
	var nb := bn.auto_turn(ns)
	ck("auto: with no Behavior keywords it closes on the nearest Enemy and attacks", Battle.tile_of(ns) != Vector2i(0, 1) and nb.any(func(bt): return bt["type"] == "move") and nb.any(func(bt): return bt["type"] == "attack" and bt["target"] == "e1"), [ns["pos"], nb.map(func(bt): return [bt["type"], bt.get("target")])])
	var bo: Battle = mk.call(8)
	_clear(bo)
	var ob := bo.auto_turn(bo.unit_by_id("a1"))
	ck("auto: with no Enemy standing it does nothing", ob.is_empty() and Battle.tile_of(bo.unit_by_id("a1")) == Vector2i(0, 0))
	# Stunned: "cannot act or move at all", on anyone's turn
	var bs1: Battle = mk.call(9)
	var sg: Dictionary = bs1.unit_by_id("e1")
	var sa: Dictionary = bs1.unit_by_id("a1")
	sg["pos"] = {"q": 1, "r": 0}
	sg["comboAt"] = 1
	Rules.add_status(sg, "Stunned", null, "ally", 2)
	var shp: int = sa["hp"]
	var sbeats := bs1.enemy_turn(sg)
	ck("stunned: a Stunned Enemy loses its turn: it neither moves nor attacks, and its Combo starts again", sa["hp"] == shp and Battle.tile_of(sg) == Vector2i(1, 0) and sg["comboAt"] == 0 and sbeats.size() == 1 and sbeats[0]["type"] == "skip" and _texts(bs1).has("Test Grunt is Stunned and loses its turn") and not _texts(bs1).any(func(l): return l.begins_with("Test Grunt used ")),
		[_texts(bs1), sg.get("comboAt")])
	var bs2: Battle = mk.call(10)
	var su2: Dictionary = bs2.unit_by_id("a1")
	Rules.add_status(su2, "Stunned", null, "enemy", 2)
	var ehp: int = bs2.unit_by_id("e1")["hp"]
	var abeats := bs2.auto_turn(su2)
	ck("stunned: so does a Stunned Unit of yours on Auto", bs2.unit_by_id("e1")["hp"] == ehp and Battle.tile_of(su2) == Vector2i(0, 0) and abeats.size() == 1 and abeats[0]["type"] == "skip" and _texts(bs2).has("Test Warden is Stunned and loses its turn") and bs2.has_acted(su2), _texts(bs2))
	var bs3: Battle = mk.call(11)
	var holder: Dictionary = bs3.unit_by_id("a1")
	var walker: Dictionary = bs3.unit_by_id("e1")
	walker["pos"] = {"q": 7, "r": 0}
	bs3.unit_by_id("e2")["pos"] = {"q": 7, "r": 1}
	var held_ok := bs3.hold_fire(holder, "Overwatch")
	Rules.add_status(holder, "Stunned", null, "enemy", 2)
	var walker_hp: int = walker["hp"]
	bs3.enemy_turn(walker)
	ck("stunned: a Unit Stunned after taking aim doesn't take its held shot", held_ok and walker["hp"] == walker_hp and Rules.hex_distance(holder["pos"], walker["pos"]) <= 5 and not _texts(bs3).any(func(l): return " reacts with " in l), [held_ok, _texts(bs3), walker["pos"]])
	var bs4: Battle = mk.call(11)
	var holder4: Dictionary = bs4.unit_by_id("a1")
	var walker4: Dictionary = bs4.unit_by_id("e1")
	walker4["pos"] = {"q": 7, "r": 0}
	bs4.unit_by_id("e2")["pos"] = {"q": 7, "r": 1}
	bs4.hold_fire(holder4, "Overwatch")
	bs4.enemy_turn(walker4)
	ck("stunned: (one that isn't does)", _texts(bs4).any(func(l): return " reacts with " in l), _texts(bs4))
	# on a Loot Tile, Auto finds what is there
	var blo := Battle.begin_team(lf, r, StrikeTeams.setup_for(t, r, ["Test Warden"], "Test Warden", [], 3), 12)
	var low: Dictionary = blo.unit_by_id("a1")
	low["pos"] = {"q": 1, "r": 3}
	low["behaviors"] = [{"k": "steadfast"}]
	blo.auto_turn(low)
	ck("auto: left standing on a Loot Tile, it finds what's there", blo.looted.has(Vector2i(1, 3)) and not Loot.is_empty(blo.loot))

	# ---- the Behavior keywords you choose
	ck("behaviors: twelve a Unit of yours may carry", Behaviors.choices().size() == 12 and Behaviors.choices().all(func(d): return d["side"] == "ally") and Behaviors.choices()[0]["k"] == "valiant")
	ck("behaviors: a list is kept to your side's, each once, three at most", Behaviors.clean([{"k": "decisive"}, {"k": "cunning"}, {"k": "decisive"}, {"k": "wary"}, {"k": "medic"}, {"k": "guardian"}, "x", {"k": "nonsense"}]) == [{"k": "decisive"}, {"k": "wary", "x": 2}, {"k": "medic"}],
		Behaviors.clean([{"k": "decisive"}, {"k": "cunning"}, {"k": "decisive"}, {"k": "wary"}, {"k": "medic"}, {"k": "guardian"}, "x", {"k": "nonsense"}]))
	var pick: Array = Behaviors.toggle([], "decisive")["list"]
	pick = Behaviors.toggle(pick, "wary")["list"]
	pick = Behaviors.step(pick, "wary", 1)
	ck("behaviors: put on in order; a number where the keyword takes one", pick == [{"k": "decisive"}, {"k": "wary", "x": 3}] and Behaviors.words(pick) == "Decisive, then Wary 3" and Behaviors.words([]) == "", [pick, Behaviors.words(pick)])
	ck("behaviors: the number stays between 1 and 99", Behaviors.step(pick, "wary", -9)[1]["x"] == 1 and Behaviors.step(pick, "wary", 500)[1]["x"] == 99 and Behaviors.step(pick, "decisive", 3) == pick)
	pick = Behaviors.toggle(pick, "medic")["list"]
	var fourth := Behaviors.toggle(pick, "guardian")
	ck("behaviors: a fourth is refused, with why", fourth["list"] == pick and "three" in str(fourth["note"]) and pick.size() == 3, fourth)
	ck("behaviors: tapped again, one comes off", Behaviors.toggle(pick, "wary")["list"] == [{"k": "decisive"}, {"k": "medic"}] and Behaviors.toggle(pick, "wary")["note"] == "")
	ck("behaviors: two that both always choose a target leave the second idle, and it says so", Behaviors.problems([{"k": "decisive"}, {"k": "precise"}]).size() == 1 and "Precise will never apply" in Behaviors.problems([{"k": "decisive"}, {"k": "precise"}])[0] and Behaviors.problems([{"k": "decisive"}, {"k": "defiant"}]).is_empty(), Behaviors.problems([{"k": "decisive"}, {"k": "precise"}]))
	ck("behaviors: what a keyword does, with its own number", Behaviors.text_of({"k": "wary", "x": 3}) == "Moves away from any Enemy within 3 tiles, then acts normally." and Behaviors.text_of({"k": "prudent"}) == "At 5 Health or below, withdraws and takes no Action.", Behaviors.text_of({"k": "wary", "x": 3}))
	Behaviors.forget_all()
	ck("behaviors: nothing remembered to begin with", Behaviors.for_card("Test Warden") == null and Behaviors.load_all().is_empty())
	ck("behaviors: a choice is remembered for the card", Behaviors.remember("Test Warden", pick) and Behaviors.for_card("Test Warden") == pick and Behaviors.for_card("Test Striker") == null)
	Behaviors._cache = null
	ck("behaviors: and kept in a file, for next time", FileAccess.file_exists(Behaviors.path) and Behaviors.for_card("Test Warden") == pick, Behaviors.load_all())
	var bw := _mk(r, "Test Warden", "ally", "a1", Vector2i(0, 0))
	var bs := _mk(r, "Test Striker", "ally", "a2", Vector2i(0, 1))
	var bg := _mk(r, "Test Warden", "enemy", "e1", Vector2i(3, 0))
	for u in [bw, bs, bg]:
		Behaviors.apply(u)
	ck("behaviors: your Units of that card arrive with them; nobody else does", bw["behaviors"] == pick and bs["behaviors"] == [] and bg["behaviors"] == [] and bw.get("behSeen") == true, [bw["behaviors"], bs["behaviors"], bg["behaviors"]])
	bw["behaviors"] = [{"k": "steadfast"}]
	Behaviors.remember("Test Warden", [])
	Behaviors.apply(bw)
	ck("behaviors: a Unit already seen keeps what it has", bw["behaviors"] == [{"k": "steadfast"}])
	var fresh_w := _mk(r, "Test Warden", "ally", "a3", Vector2i(1, 0))
	fresh_w["behaviors"] = [{"k": "valiant"}]
	Behaviors.apply(fresh_w)
	ck("behaviors: none, chosen, is remembered as none", fresh_w["behaviors"] == [] and Behaviors.for_card("Test Warden") == [])
	Behaviors.forget_all()


## The same, on the screen: Districts cleared in setup, the Auto switch and
## the turn it plays, the Behavior picker, loot shown as it drops and on the
## result, and X chosen for a card and for a carried Action card.
func _seven_scene() -> void:
	Kit.fresh()
	var team: Dictionary = Kit.team()
	for n in ["Test Swarm", "Test Barrage"]:
		team["deck"][n] = 2
	team["actions"] = {"Quillon Vex": ["Test Overcharge"]}
	Kit.keep([team])
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	var r: Roster = scene.roster
	var li := -1
	for i in scene.floors.size():
		if scene.floors[i].name == "TEST · Loot":
			li = i
	# ---- setting up: Districts cleared
	scene.open_setup("team")
	var s: SetupScreen = scene.setup
	s.choose_floor(li)
	s._go(1)
	s.choose_team(0)
	s._go(1)
	s._go(1)
	await _frames(2)
	var de: Dictionary = s._rows[s._rows.size() - 1]
	ck("0.7 setup: the last row is Districts cleared, at 0", de.has("districts") and s.districts_cleared == 0 and _labels(de["row"]).any(func(l): return l.begins_with("Dimensional Instability: none")) and "Districts cleared" in s.hint.text, _labels(de["row"]))
	for i in 3:
		de = s._rows[s._rows.size() - 1]          # the rows are made again after each tap
		var plus: Control = de["plus"]
		s.list.tap(plus.global_position - s.list.global_position + plus.size / 2)
		await _frames(2)
	de = s._rows[s._rows.size() - 1]
	ck("0.7 setup: its plus adds 3% for each", s.districts_cleared == 3 and _labels(de["row"]).any(func(l): return "9%" in l) and "9% chance" in s.note.text and "District 3 has 2 Elites and 2 Mini-Bosses to send" in s.note.text, s.note.text)
	var minus: Control = de["minus"]
	s.list.tap(minus.global_position - s.list.global_position + minus.size / 2)
	await _frames(2)
	ck("0.7 setup: and its minus takes one off, the wave timer left alone", s.districts_cleared == 2 and s.wave_timer == 3)
	s.set_districts(9)
	var most := s.districts_cleared
	s.set_districts(-2)
	ck("0.7 setup: from 0 to 5", most == 5 and s.districts_cleared == 0 and "At 0, none will" in s.note.text, s.note.text)
	s.set_districts(3)
	var got := []
	s.team_start_requested.connect(func(_fi, _tm, su): got.append(su))
	s._go(1)
	await _frames(3)
	ck("0.7 setup: Start battle takes the chance into the fight, and the fight says so", got.size() == 1 and got[0]["instability"] == 9 and scene.battle != null and scene.battle.instability == 9 and "Dimensional Instability 9%" in scene.info.text, scene.info.text)
	scene.open_setup("team")
	ck("0.7 setup: it starts at 0 again for the next Battle", s.districts_cleared == 0)
	scene.open_setup("quick")
	s.choose_floor(li)
	s._go(1)
	s.toggle_hero("Test Warden")
	s._go(1)
	await _frames(2)
	ck("0.7 setup: a Quick battle has no Districts to set", s.step == "troops" and not s._rows.any(func(e): return e.has("districts")))

	# ---- the fight
	scene.start_team_battle(li, team, StrikeTeams.setup_for(team, r, ["Test Warden", "Quillon Vex"], "Test Warden", ["Test Drone"], 3), 21)
	await _frames(3)
	var bt: Battle = scene.battle
	var warden: Dictionary = bt.unit_by_id("a1")
	var vex: Dictionary = bt.unit_by_id("a2")
	var drone: Dictionary = bt.unit_by_id("a3")
	ck("0.7 bar: Auto is off to begin with, and no loot yet", (scene.auto_btn.tooltip_text == "Auto: off" and not scene.auto_btn.button_pressed) and not scene.auto and not scene.loot_label.visible and "Dimensional Instability" not in scene.info.text, scene.info.text)
	ck("0.7 bar: everything fits across the top", scene.fit_btn.get_global_rect().end.x <= scene.get_viewport_rect().size.x + 0.5 and scene.floor_label.size.x >= 100, [scene.fit_btn.get_global_rect(), scene.floor_label.size])
	# loot, as it is found
	ck("0.7 loot: the board knows its Loot Tiles", scene.board.loot_tiles.size() == 3 and scene.board.loot_tiles.has(Vector2i(1, 3)) and scene.board.searched.is_empty())
	_tap(scene, Vector2i(1, 3))
	await _frames(2)
	ck("0.7 loot: a tap on a Loot Tile says what it is", scene.info.text.begins_with("A Loot Tile: the first of your Units to end a move here"), scene.info.text)
	_tap(scene, Vector2i(3, 1))
	await _frames(2)
	ck("0.7 loot: and on a Locked Chest", scene.info.text.begins_with("A Locked Chest: "), scene.info.text)
	_place(scene, "a1", Vector2i(-2, 5))
	_tap(scene, Vector2i(-2, 5))
	await _frames(2)
	_tap(scene, Vector2i(-2, 4))
	await _until(scene, "walking")
	await _frames(2)
	ck("0.7 loot: a Unit that walks onto a Loot Tile finds its loot: the bottom line, the tile and the count say so", "Test Warden finds: " in scene.info.text and scene.board.searched.has(Vector2i(-2, 4)) and scene.loot_label.visible and scene.loot_label.text == scene.loot_words() and scene.loot_label.text.begins_with("Loot: "),
		[scene.info.text, scene.loot_label.text])
	scene.deselect()
	_tap(scene, Vector2i(1, 2))
	_place(scene, "a1", Vector2i(-2, 5))
	_tap(scene, Vector2i(-2, 4))
	await _frames(2)
	ck("0.7 loot: an emptied tile says so", scene.info.text == "A Loot Tile, already emptied.", scene.info.text)
	_place(scene, "a1", Vector2i(-2, 4))
	scene.undo_move()
	await _frames(2)
	ck("0.7 loot: Undo takes the find back with the move", not scene.loot_label.visible and scene.board.searched.is_empty() and Loot.is_empty(bt.loot) and Battle.tile_of(warden) == Vector2i(-2, 5), [scene.loot_label.text, bt.loot])
	var e1: Dictionary = bt.unit_by_id("e1")
	var mark: Array = scene._mark()
	Rules.hit(e1, 999)
	bt.fx.check_downs()
	scene.board.refresh_units(bt)
	scene._news(mark)
	scene._update_bar()
	await _frames(2)
	ck("0.7 loot: an Enemy's drop rises off it in its own colour, and is counted", scene.overlay.floats.any(func(f): return f["colour"] == scene.LOOT) and scene.loot_label.visible and "shard" in scene.loot_label.text, [scene.overlay.floats.map(func(f): return f["text"]), scene.loot_label.text])
	scene.toggle_log()
	await _frames(2)
	ck("0.7 loot: the Log's head says what has dropped so far, and that it isn't kept", scene.log_panel.haul.visible and scene.log_panel.haul.text.begins_with("Loot so far: ") and scene.log_panel.haul.text.ends_with("A practice fight: not kept.") and bt.loot_table.text(bt.loot) in scene.log_panel.haul.text, scene.log_panel.haul.text)
	scene.toggle_log()
	ck("0.7 loot: the dice readout names a drop", scene.dice_lines({"kind": "aether", "damage": 3}, e1, "", [{"kind": "loot", "text": "Test Grunt drops: 2 shards", "round": 1}]).any(func(l): return l[0] == "Test Grunt drops: 2 shards" and l[1] == scene.LOOT))

	# ---- Auto
	scene.auto_btn.pressed.emit()
	await _frames(2)
	ck("0.7 auto: the switch turns it on, and says what it will do", scene.auto and (scene.auto_btn.tooltip_text == "Auto: on" and scene.auto_btn.button_pressed) and scene.info.text.begins_with("Auto is on.") and "End turn" in scene.info.text, scene.info.text)
	_tap(scene, Battle.tile_of(vex))
	await _frames(2)
	ck("0.7 auto: a Unit's panel says Auto will take its turn", "Auto takes its turn when you end yours" in scene.panel.move_label.text, scene.panel.move_label.text)
	ck("0.7 auto: and how it fights: no Behavior keywords yet, and a button to change that", scene.panel._rows.any(func(row): return row.has("behavior") and row.get("live", false)) and _panel_text(scene).has("No Behavior keywords: it attacks the closest Enemy.") and _panel_text(scene).has("Tap to change. Up to three."), _panel_text(scene))
	# the Behavior picker
	var bi := -1
	for i in scene.panel._rows.size():
		if scene.panel._rows[i].has("behavior"):
			bi = i
	scene.panel._on_row(bi, Vector2.ZERO)
	await _frames(3)
	var sh: BehaviorSheet = scene.beh_sheet
	ck("0.7 behaviors: the row opens the picker, with all twelve", sh != null and sh._rows.size() == 12 and sh.picked.is_empty() and "None chosen" in sh.summary.text and not scene._board_live(), sh.summary.text if sh != null else "")
	var tap_row := func(k: String, key := ""):
		for e in sh._rows:
			if e["k"] == k:
				var c: Control = e[key] if key != "" else e["row"]
				var at: Vector2 = c.global_position - sh.list.global_position + (c.size / 2 if key != "" else Vector2(40, 10))
				sh.list.tap(at)
	tap_row.call("decisive")
	await _frames(2)
	tap_row.call("wary")
	await _frames(2)
	tap_row.call("wary", "plus")
	await _frames(2)
	ck("0.7 behaviors: a tap puts a keyword on, in order; plus raises its number", sh.picked == [{"k": "decisive"}, {"k": "wary", "x": 3}] and sh.summary.text.begins_with("Chosen: Decisive, then Wary 3."), [sh.picked, sh.summary.text])
	tap_row.call("wary", "minus")
	await _frames(2)
	tap_row.call("precise")
	await _frames(2)
	ck("0.7 behaviors: two that always choose a target: it says the second does nothing", sh.picked.size() == 3 and "Precise will never apply" in sh.summary.text, sh.summary.text)
	tap_row.call("guardian")
	await _frames(2)
	ck("0.7 behaviors: a fourth is refused", sh.picked.size() == 3 and "three" in sh.note_label.text, sh.note_label.text)
	tap_row.call("precise")
	await _frames(2)
	ck("0.7 behaviors: tapped again, one comes off", sh.picked == [{"k": "decisive"}, {"k": "wary", "x": 2}], sh.picked)
	sh.done_btn.pressed.emit()
	await _frames(3)
	ck("0.7 behaviors: Done gives them to the Unit, and the panel shows them", scene.beh_sheet == null and vex["behaviors"] == [{"k": "decisive"}, {"k": "wary", "x": 2}] and _panel_text(scene).has("Decisive") and _panel_text(scene).has("Wary 2") and _panel_text(scene).has("Moves away from any Enemy within 2 tiles, then acts normally.") and "Quillon Vex fights by: Decisive, then Wary 2." in scene.info.text,
		[vex["behaviors"], scene.info.text])
	ck("0.7 behaviors: and the game remembers them for the card", Behaviors.for_card("Quillon Vex") == [{"k": "decisive"}, {"k": "wary", "x": 2}] and Behaviors.for_card("Test Warden") == null)
	# End turn, with Auto on
	scene.deselect()
	_place(scene, "a1", Vector2i(-5, 6))
	_place(scene, "a2", Vector2i(-6, 6))
	bt.moved.clear()
	bt.undo.clear()
	var dpos := Battle.tile_of(drone)
	_tap(scene, dpos)
	await _frames(2)
	_tap(scene, Vector2i(dpos.x, dpos.y - 1))
	await _until(scene, "walking")
	await _frames(2)
	var moved_to := Battle.tile_of(drone)
	ck("0.7 auto: a Unit you moved yourself is left to you", bt.auto_queue() == ["a1", "a2"] and bt.has_acted(drone) and "Auto leaves it alone now" in scene.panel.move_label.text, [bt.auto_queue(), scene.panel.move_label.text])
	scene.deselect()
	var w0 := Battle.tile_of(warden)
	var v0 := Battle.tile_of(vex)
	scene.next_btn.pressed.emit()
	await process_frame
	ck("0.7 auto: End turn doesn't ask about the Units Auto will take", scene.dialog == null and scene.auto_phase and scene.busy and scene.info.text.begins_with("Auto: 2 of your Units take their turns."), [scene.dialog != null, scene.auto_phase, scene.info.text])
	_tap(scene, Vector2i(0, 0))
	ck("0.7 auto: a tap on the board hurries them", scene.fast and scene.selected_id == "")
	var n := 0
	var saw_enemies := false
	while (scene.auto_phase or scene.enemy_phase or scene.busy) and n < 20000:
		scene.fast = true
		saw_enemies = saw_enemies or scene.enemy_phase
		if scene.dialog != null and not bt.over:
			scene.dialog.buttons[0].pressed.emit()
		await process_frame
		n += 1
	ck("0.7 auto: they take their turns by themselves, then the Enemies take theirs, and the round turns", saw_enemies and bt.round == 2 and not scene.busy and not scene.auto_phase and (Battle.tile_of(warden) != w0 or Battle.tile_of(vex) != v0) and bt.log.any(func(l): return l["round"] == 1 and (str(l["text"]).begins_with("Test Warden ") or str(l["text"]).begins_with("Quillon Vex "))),
		[bt.round, w0, Battle.tile_of(warden), v0, Battle.tile_of(vex)])
	ck("0.7 auto: it stays on, and everyone is in line again", scene.auto and (scene.auto_btn.tooltip_text == "Auto: on" and scene.auto_btn.button_pressed) and bt.auto_queue().size() == bt.side_units("ally").filter(func(u): return not Rules.truthy(u.get("down"))).size())
	# one you have used, that could still do something, is asked about
	var foe = null
	for e in bt.side_units("enemy"):
		if not Rules.truthy(e.get("down")):
			foe = e
	if foe != null and not bt.over:
		_place(scene, "a1", Vector2i(0, 0))
		_place(scene, foe["id"], Vector2i(0, -2))
		warden["nrg"] = warden["nrgMax"]
		_tap(scene, Vector2i(0, 0))
		await _frames(2)
		_tap(scene, Vector2i(1, 0))
		await _until(scene, "walking")
		await _frames(2)
		scene.deselect()
		scene.next_btn.pressed.emit()
		await _frames(2)
		ck("0.7 auto: End turn asks only about a Unit you used that could still act", scene.dialog != null and scene.dialog.text_label.text.begins_with("Test Warden can still move or act. Auto leaves it alone, because you've used it this turn."), scene.dialog.text_label.text if scene.dialog != null else "no box")
		if scene.dialog != null:
			scene.dialog.buttons[0].pressed.emit()
		await _frames(2)
	scene.auto_btn.pressed.emit()
	await _frames(2)
	ck("0.7 auto: switched off, your Units wait for you again", not scene.auto and (scene.auto_btn.tooltip_text == "Auto: off" and not scene.auto_btn.button_pressed) and scene.info.text.begins_with("Auto is off."), scene.info.text)
	scene.deselect()
	scene.next_btn.pressed.emit()
	await _frames(2)
	ck("0.7 auto: and End turn asks about everyone who could still act, as before", scene.dialog != null and "Auto" not in scene.dialog.text_label.text and scene.dialog.text_label.text.ends_with("The Enemies take their turn next."), scene.dialog.text_label.text if scene.dialog != null else "no box")
	if scene.dialog != null:
		scene.dialog.buttons[0].pressed.emit()
	await _frames(2)

	# an Enemy's own Behavior keywords are shown, and aren't yours to change
	var shown_foe = null
	for e in bt.side_units("enemy"):
		if not Rules.truthy(e.get("down")):
			shown_foe = e
	if shown_foe != null:
		shown_foe["behaviors"] = [{"k": "cunning"}, {"k": "cautious", "x": 3}]
		scene.deselect()
		_tap(scene, Battle.tile_of(shown_foe))
		await _frames(2)
		var ft := _panel_text(scene)
		ck("0.7 behaviors: an Enemy's panel shows its Behavior keywords, read-only", ft.has("BEHAVIOR") and ft.has("Cunning") and ft.has("Attacks the nearest Hero.") and ft.has("Cautious 3") and ft.has("Moves away from any Player Unit within 3 tiles, then acts normally.") and not ft.has("Tap to change. Up to three.") and not scene.panel._rows.any(func(row): return row.get("live", false)), ft)
		scene.open_behaviors()
		ck("0.7 behaviors: and the picker doesn't open for it", scene.beh_sheet == null)
		shown_foe["behaviors"] = []
		scene.deselect()
	# ---- a new Battle: what was chosen for a card comes with it
	scene.start_team_battle(li, team, StrikeTeams.setup_for(team, r, ["Test Warden", "Quillon Vex"], "Test Warden", [], 3), 22)
	await _frames(3)
	bt = scene.battle
	warden = bt.unit_by_id("a1")
	vex = bt.unit_by_id("a2")
	ck("0.7 behaviors: in the next Battle, the card's Units arrive with what you chose", vex["behaviors"] == [{"k": "decisive"}, {"k": "wary", "x": 2}] and warden["behaviors"] == [], [vex["behaviors"], warden["behaviors"]])
	# ---- X, for a card in the hand
	bt.hand = ["Test Swarm", "Test Barrage", "Test Drone"].map(func(nm): return _hc(r, nm))
	bt.aether = {"generic": 2, "d3": 3}
	scene._update_bar()
	scene.hand_btn.pressed.emit()
	await _frames(3)
	var tray: HandTray = scene.hand_tray
	ck("0.7 X: a variable cost reads X on its tile", tray.grid.tiles[0].foot.begins_with("X D3") and tray.grid.tiles[1].foot == "X any" and not tray.grid.tiles[0].faded, [tray.grid.tiles[0].foot, tray.grid.tiles[1].foot])
	tray.grid.tap(tray.grid.tile_centre(2))
	await _frames(2)
	ck("0.7 X: a card without one has nothing to choose", scene.sheet != null and scene.sheet.count_label == null and scene.sheet.x_shown == null)
	scene.sheet.buttons["close"].pressed.emit()
	await _frames(2)
	tray.grid.tap(tray.grid.tile_centre(0))
	await _frames(2)
	var cs: CardSheet = scene.sheet
	ck("0.7 X: its sheet has X to choose, from 1 to what the Bank could pay", cs != null and cs.count_label != null and cs.value == 1 and cs.lo == 1 and cs.hi == 3 and cs.minus_btn.disabled and not cs.plus_btn.disabled and "at X = 1 it costs 1 D3 Aether" in _sheet_note(scene), _sheet_note(scene))
	ck("0.7 X: and reads with X = 1 in place", _labels(cs.body).has("With X = 1:") and _labels(cs.body).any(func(l): return l.begins_with("HP 4 ")), _labels(cs.body))
	cs.plus_btn.pressed.emit()
	cs.plus_btn.pressed.emit()
	await _frames(2)
	ck("0.7 X: plus raises it: the cost, the numbers and the text follow", cs.value == 3 and cs.plus_btn.disabled and "at X = 3 it costs 3 D3 Aether" in _sheet_note(scene) and _labels(cs.body).has("With X = 3:") and _labels(cs.body).any(func(l): return l.begins_with("HP 12 ")) and _labels(cs.body).has("Target enemy takes damage 3."), [_sheet_note(scene), _labels(cs.body)])
	cs.minus_btn.pressed.emit()
	await _frames(2)
	var units0 := bt.units.size()
	cs.buttons["play"].pressed.emit()
	await _frames(2)
	if not scene.play.is_empty():
		_tap(scene, scene.board.reach.keys()[0])
	await _until(scene, "busy")
	await _frames(2)
	var swarm: Dictionary = bt.units[bt.units.size() - 1]
	ck("0.7 X: Play plays it for the X chosen", bt.units.size() == units0 + 1 and swarm["name"] == "Test Swarm" and swarm["hpMax"] == 8 and swarm.get("x") == 2 and bt.aether.get("d3", 0) == 1 and "Test Swarm deployed (X = 2)" in scene.info.text, [swarm["name"], swarm["hpMax"], bt.aether, scene.info.text])
	ck("0.7 X: its panel reads with that X", _panel_text(scene).has("Target enemy takes damage 2."), _panel_text(scene))
	scene.undo_move()
	await _frames(2)
	bt.aether = {}
	scene._update_bar()
	scene.read_hand_card(0)
	await _frames(2)
	ck("0.7 X: with the Bank short of X = 1, Play is off and it says what it needs at least", scene.sheet != null and scene.sheet.buttons["play"].disabled and scene.sheet.count_label == null and "needs at least 1 D3" in _sheet_note(scene), _sheet_note(scene))
	scene.sheet.buttons["close"].pressed.emit()
	await _frames(2)
	if tray.visible:
		tray.close_btn.pressed.emit()
	# ---- X, for a carried Action card
	var e2 = null
	for e in bt.side_units("enemy"):
		if not Rules.truthy(e.get("down")):
			e2 = e
	_place(scene, "a2", Vector2i(0, 2))
	_place(scene, e2["id"], Vector2i(0, 0))
	e2["hp"] = 60
	e2["hpMax"] = 60
	bt.aether = {"d3": 2}
	scene._update_bar()
	scene.deselect()
	_tap(scene, Vector2i(0, 2))
	await _frames(2)
	var oi := _index(vex, "Overcharge")
	ck("0.7 X: a carried Action card with a variable cost reads X in the panel", _panel_text(scene).any(func(l): return l.begins_with("1 NRG + X D3 Aether")) and _panel_text(scene).has("Target enemy takes damage X."), _panel_text(scene))
	scene.panel.action_pressed.emit(oi)
	await _frames(2)
	var xd: XDialog = scene.xdlg
	ck("0.7 X: picking it asks for X first", xd != null and scene.aiming == -1 and xd.value == 1 and xd.hi == 2 and xd.minus_btn.disabled and "Costs 1 D3 Aether, and 1 Energy." in xd.text_label.text and not scene._board_live(), xd.text_label.text if xd != null else "no box")
	xd.cancel_btn.pressed.emit()
	await _frames(2)
	ck("0.7 X: put away, nothing is aimed or spent", scene.xdlg == null and scene.aiming == -1 and bt.aether == {"d3": 2})
	scene.panel.action_pressed.emit(oi)
	await _frames(2)
	xd = scene.xdlg
	xd.plus_btn.pressed.emit()
	await _frames(2)
	ck("0.7 X: plus raises it, as far as the Bank could pay", xd.value == 2 and xd.plus_btn.disabled and "Costs 2 D3 Aether" in xd.text_label.text and "Target enemy takes damage 2." in xd.text_label.text, xd.text_label.text)
	xd.ok_btn.pressed.emit()
	await _frames(3)
	ck("0.7 X: Aim it aims the Action with that X", scene.xdlg == null and scene.aiming == oi and scene.targets.has(e2["id"]) and vex["actions"][oi].get("x") == 2 and _panel_text(scene).any(func(l): return l.begins_with("Target enemy takes damage 2.") and l.ends_with("(X = 2)")), [scene.aiming, _panel_text(scene)])
	_tap(scene, Vector2i(0, 0))
	await _until(scene, "busy")
	await _frames(2)
	ck("0.7 X: used, it takes the Aether for that X", bt.aether.get("d3", 0) == 0 and int(vex["nrg"]) == int(vex["nrgMax"]) - 1, [bt.aether, vex["nrg"]])

	# ---- the result
	for e in bt.side_units("enemy"):
		if not Rules.truthy(e.get("down")):
			e["hp"] = 0
	bt.fx.check_downs()
	bt.wave = bt.waves_total
	bt.enemy_pile.clear()
	bt.settle()
	scene.board.refresh_units(bt)
	scene.show_result()
	await _frames(3)
	var said: String = scene.dialog.text_label.text if scene.dialog != null else ""
	ck("0.7 result: won, it totals what dropped and the floor's own reward, and says none of it is kept yet", scene.dialog != null and scene.dialog.title_label.text == "Victory" and "Dropped and found: " in said and "The floor's reward: 12 shards" in said and _stat_total(scene.dialog.stats, "shards") == int(bt.loot_result["total"]["shards"]) and _stat_total(scene.dialog.stats, "part_") == Loot.count(bt.loot_result["total"]) and "A practice fight: nothing is kept" in said and bt.loot_table.text(bt.loot_result["haul"]) in said and bt.loot_table.text(bt.loot_result["reward"]) in said, said)
	ck("0.7 result: Auto can't be switched once it's over", scene.auto_btn.disabled)
	scene.dialog.buttons[3].pressed.emit()
	await _frames(2)
	# a loss
	scene.start_team_battle(li, team, StrikeTeams.setup_for(team, r, ["Test Warden"], "Test Warden", [], 3), 23)
	await _frames(3)
	bt = scene.battle
	bt.side_units("enemy")[0]["hp"] = 0
	bt.fx.check_downs()
	bt.unit_by_id("a1")["hp"] = 0
	bt.fx.check_downs()
	bt.settle()
	scene.board.refresh_units(bt)
	scene.show_result()
	await _frames(3)
	said = scene.dialog.text_label.text if scene.dialog != null else ""
	ck("0.7 result: lost, what was carried is lost with it, and there's no reward", scene.dialog != null and scene.dialog.title_label.text == "Defeat" and "Lost with the fight" in said and "reward" not in said and "In all" not in said, said)
	scene.dialog.buttons[3].pressed.emit()
	await _frames(2)
	# ---- a Quick battle has Auto too, and shows its loot
	scene.start_battle(li, [r.card_named("Test Warden")], [r.card_named("Test Drone")], 5)
	await _frames(3)
	bt = scene.battle
	ck("0.7 quick: the Auto switch is there", scene.auto_btn.visible and (scene.auto_btn.tooltip_text == "Auto: off" and not scene.auto_btn.button_pressed) and bt.instability == 0)
	scene.toggle_auto()
	scene.next_btn.pressed.emit()
	await process_frame
	var began: bool = scene.auto_phase
	n = 0
	while (scene.auto_phase or scene.enemy_phase or scene.busy) and n < 20000:
		scene.fast = true
		if scene.dialog != null and not bt.over:
			scene.dialog.buttons[0].pressed.emit()
		await process_frame
		n += 1
	ck("0.7 quick: and plays your turn the same way", began and (bt.round == 2 or bt.over) and not scene.busy, [began, bt.round, bt.over])
	scene.queue_free()
	Kit.fresh()
	await process_frame


# ---------------------------------------------------------------- 0.8: when a Status ticks, what a fight leaves behind, and a deployment
func _eight() -> void:
	Kit.fresh()
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)
	var lf := _floor_named(x, "TEST · Loot")
	var wf := _floor_named(x, "TEST · Waves")
	var t: Dictionary = Kit.team()
	var su := StrikeTeams.setup_for(t, r, ["Test Warden", "Test Striker"], "Test Warden", [], 3)

	# ---- Handbook 15.9: a Status ticks at the end of the turn after the one it arrived in
	var b := Battle.begin_team(lf, r, su, 41)
	var hero: Dictionary = b.side_units("ally")[0]
	var foe: Dictionary = b.side_units("enemy")[0]
	var halves := []
	for k in ["waves", "gen", "chips", "draw", "recharge", "turn", "enemy"]:
		b.phase = k
		halves.append(b.half())
	b.phase = "turn"
	ck("15.9: the fight opens in your half of the round", b.half() == "ally")
	ck("15.9: your half is the Recharge and your turn; the Enemies' is their turn and the Waves, Aether and Draw phases after it", halves == ["enemy", "enemy", "enemy", "enemy", "ally", "ally", "enemy"], halves)
	b._hook()
	Rules.add_status(foe, "Stunned", null, null, 1)
	Rules.add_status(foe, "Poisoned", 2, null, 2)
	ck("15.9: a Status given in your turn is not late", not Rules.truthy(Rules.status_of(foe, "Stunned").get("late")) and not Rules.truthy(Rules.status_of(foe, "Poisoned").get("late")))
	var hp0: int = foe["hp"]
	var from := b.log.size()
	b.end_player_turn()
	ck("15.9: ending your turn doesn't tick it", b.phase == "enemy" and Rules.has_status(foe, "Stunned") and foe["hp"] == hp0 and b.log.size() == from, b.log.slice(from).map(func(l): return l["text"]))
	for id in b.enemy_queue():
		b.enemy_turn(b.unit_by_id(id))
	ck("15.9: so the Enemy is still Stunned in its own turn, and loses it", b.log.slice(from).any(func(l): return l["text"] == foe["name"] + " is Stunned and loses its turn"))
	b.end_round()
	var said := b.log.slice(from).map(func(l): return l["text"])
	ck("15.9: the Recharge ticks it: Stunned ends and Poison bites once", not Rules.has_status(foe, "Stunned") and foe["hp"] == hp0 - 2 and Rules.status_turns(foe, "Poisoned") == 1 and said.has(foe["name"] + " takes 2 from Poisoned") and said.has(foe["name"] + " is no longer Stunned"), said)
	ck("15.9: and it is your turn again", b.phase == "turn" and b.half() == "ally")
	# given in the Enemies' turn
	b.end_player_turn()
	b._hook()
	Rules.add_status(hero, "Stunned", null, "enemy", 1)
	Rules.add_status(hero, "Poisoned", 3, "enemy", 2)
	ck("15.9: a Status given in the Enemies' turn is late", Rules.status_of(hero, "Stunned").get("late") == true and Rules.status_of(hero, "Poisoned").get("late") == true)
	for e in b.side_units("enemy"):
		e["actions"] = []         # nobody else touches the Hero while the clock is watched
	var hh: int = hero["hp"]
	from = b.log.size()
	b.end_round()
	ck("15.9: the Recharge leaves it alone: in your turn the Hero is still Stunned and Poison hasn't bitten", Rules.has_status(hero, "Stunned") and Rules.effective(hero)["cannotAct"] and hero["hp"] == hh and Rules.status_turns(hero, "Poisoned") == 2 and
		not b.log.slice(from).any(func(l): return str(l["text"]).begins_with(str(hero["name"]) + " ") and ("Poisoned" in l["text"] or "Stunned" in l["text"])), b.log.slice(from).map(func(l): return l["text"]))
	ck("15.9: a Stunned Hero can do nothing in the turn that follows", not b.can_move(hero) and Battle.usable_actions(hero).all(func(a): return not b.action_state(hero, a)["ok"]))
	from = b.log.size()
	b.end_player_turn()
	var ticked := b.log.slice(from)
	ck("15.9: ending your turn ticks it, before the Enemies act: Poison bites, Stunned ends", not Rules.has_status(hero, "Stunned") and hero["hp"] == hh - 3 and Rules.status_turns(hero, "Poisoned") == 1 and ticked.size() == 2 and
		ticked[0]["text"] == hero["name"] + " takes 3 from Poisoned" and ticked[1]["text"] == hero["name"] + " is no longer Stunned" and ticked.all(func(l): return l.get("turnend") == true), ticked.map(func(l): return l["text"]))
	var again := b.log.size()
	b.end_player_turn()
	ck("15.9: asked twice, the turn ends once", b.log.size() == again and hero["hp"] == hh - 3)
	b.end_round()
	b.end_player_turn()
	ck("15.9: its second turn passes the same way, and then it is gone", hero["hp"] == hh - 6 and not Rules.has_status(hero, "Poisoned"), [hero["hp"], hh])
	# what a card says, in either half
	b.end_round()
	b.fx.run_text("[[this Unit]] gains [[AC +2]] for [[turns 1]]. [[target enemy]] gains [[Weakened 2]] for [[turns 1]].", {"actor": hero, "target": foe, "sourceCard": "Mine"})
	var mine_mod: Dictionary = hero["mods"].filter(func(m): return m.get("source") == "Mine")[0]
	b.end_player_turn()
	b.fx.run_text("[[this Unit]] gains [[AC +3]] for [[turns 1]]. [[target enemy]] gains [[Slowed 1]] for [[turns 1]].", {"actor": foe, "target": hero, "sourceCard": "Theirs"})
	var their_mod: Dictionary = foe["mods"].filter(func(m): return m.get("source") == "Theirs")[0]
	ck("15.9: a timed Stats change and a Status from your turn are not late; from the Enemies' turn they are", not mine_mod.has("late") and not Rules.status_of(foe, "Weakened").has("late") and their_mod.get("late") == true and Rules.status_of(hero, "Slowed").get("late") == true)
	var ac_h: int = Rules.effective(hero)["ac"] - 2
	var ac_f: int = Rules.effective(foe)["ac"] - 3
	b.end_round()
	ck("15.9: your own boost lasts through the Enemies' turn and is gone by yours; so is what you gave them", Rules.effective(hero)["ac"] == ac_h and not Rules.has_status(foe, "Weakened"))
	ck("15.9: an Enemy's boost in its own turn lasts through yours, and so does what it gave you", Rules.effective(foe)["ac"] == ac_f + 3 and Rules.has_status(hero, "Slowed"))
	b.end_player_turn()
	ck("15.9: both end as your turn does", Rules.effective(foe)["ac"] == ac_f and not Rules.has_status(hero, "Slowed"))
	# a second dose keeps the timing of the first
	b.end_round()
	Rules.add_status(foe, "Poisoned", 1, null, 1)
	b.end_player_turn()
	Rules.add_status(foe, "Poisoned", 2, null, 1)
	var dose: Dictionary = Rules.status_of(foe, "Poisoned")
	ck("15.9: a second dose adds to the first and keeps its timing", dose["n"] == 3 and dose["turns"] == 2 and not dose.has("late"), dose)
	# and the other way round: the first in the Enemies' turn, the second in yours
	Rules.add_status(hero, "Weakened", 1, null, 1)
	b.end_round()
	Rules.add_status(hero, "Weakened", 2, null, 1)
	var dose2: Dictionary = Rules.status_of(hero, "Weakened")
	ck("15.9: one that arrived in the Enemies' turn still ticks as your turn ends when you add to it in yours", b.phase == "turn" and dose2["n"] == 3 and dose2["turns"] == 2 and dose2.get("late") == true, dose2)
	# a Quick battle ticks the same way
	var q := Battle.begin(lf, r, [r.card_named("Test Warden")], [], 5)
	var qh: Dictionary = q.side_units("ally")[0]
	q.end_player_turn()
	q._hook()
	Rules.add_status(qh, "Rooted", null, "enemy", 1)
	for e in q.side_units("enemy"):
		e["actions"] = []
	q.end_round()
	var rooted_in_turn := Rules.has_status(qh, "Rooted")
	q.end_player_turn()
	ck("15.9: a Quick battle keeps the same clock", rooted_in_turn and not Rules.has_status(qh, "Rooted") and q.phase == "enemy")
	ck("15.9: the phase hints say which Statuses tick where", "from your turn tick" in Battle.PHASES[4]["hint"] and "from the Enemies' turn tick" in Battle.PHASES[6]["hint"])

	# ---- blueprints and chassis
	var p := Progress.new(Loot.new(null, 3), x.content("pools"), x.content("chassis"), x.content("tables"))
	var burst = p.blueprint_of("Burst")
	ck("items: a keyword with a number is a blueprint of three levels, each allowing a higher number", burst != null and burst["levels"] == 3 and burst["caps"] == [2, 3, 4] and p.blueprint_of("Rooted")["levels"] == 1 and p.blueprint_of("HP")["caps"] == [2, 4, 6], burst)
	ck("items: target words, damage, heal and turns are free", p.blueprint_of("damage") == null and p.blueprint_of("target enemy") == null and p.blueprint_of("turns") == null and p.owned("damage") == 99)
	ck("items: only the next level you are missing can drop", p.eligible("bp:Burst:1") and not p.eligible("bp:Burst:2") and p.eligible("bp:Burst:2", ["bp:Burst:1"]) and not p.eligible("bp:Burst:1", ["bp:Burst:1"]) and not p.eligible("bp:Burst:4") and not p.eligible("garbage"))
	ck("items: a chassis drops once, and the starter never does", p.eligible("ch:ch_test_verdant") and not p.eligible("ch:ch_test_verdant", ["ch:ch_test_verdant"]) and not p.eligible("ch:" + Progress.STARTER) and not p.eligible("ch:nope") and p.has_chassis(Progress.STARTER))
	ck("items: one not found before keeps its name to itself", p.item_name("bp:Burst:1") == "an unknown blueprint" and p.item_name("ch:ch_test_verdant") == "an unknown chassis" and p.item_name("bp:Burst:1", true) == "Burst L1 (up to 2)")
	p.name("bp:Burst:1")
	ck("items: once a fight is won with it in hand, it is named", p.item_name("bp:Burst:1") == "Burst L1 (up to 2)" and p.owned("Burst") == 0 and p.known_bp("Burst"))
	ck("items: levels are kept in order", not p.grant("bp:Burst:2") and p.grant("bp:Burst:1") and not p.grant("bp:Burst:1") and p.grant("bp:Burst:2") and p.owned("Burst") == 2 and p.grant("ch:ch_test_verdant") and not p.grant("ch:ch_test_verdant"))
	ck("items: what is owned, in words", p.owned_lines().map(func(l): return l["text"]) == ["Burst · level 2 of 3 (numbers up to 3)", p.item_name("ch:ch_test_verdant", true)], p.owned_lines())
	var all_of := Progress.new(Loot.new(null, 9), x.content("pools"), x.content("chassis"), x.content("tables"))
	var got := all_of.roll_items({"chance": 100, "district": "3", "card": {"setDrops": [{"item": "bp:Marked:1", "chance": 100}, {"item": "bp:Marked:1", "chance": 100}]}})
	ck("items: a set drop falls by its own chance, once, and the District's pool gives one more", got.size() == 2 and got[0] == "bp:Marked:1" and all_of.pool_items("3").has(got[1]) and got[1] != "bp:Marked:1", got)
	ck("items: a District with no pool gives nothing of its own", all_of.roll_items({"chance": 100, "district": "5", "card": {}}).is_empty() and all_of.roll_items({"chance": 0, "district": "3", "card": {}}).is_empty())

	# ---- what a fight leaves behind
	b = Battle.begin_team(lf, r, su, 77)
	ck("items: a fight knows what you own (nothing yet), from the export's pools and chassis", b.progress != null and b.progress.pool_items("3").size() == 16 and b.progress.chassis.has("ch_test_verdant") and b.found.is_empty())
	var e1: Dictionary = b.side_units("enemy")[0]
	e1["setDrops"] = [{"item": "bp:Marked:1", "chance": 100}]
	from = b.log.size()
	e1["hp"] = 0
	b.check_downs()
	var left := b.log.slice(from).filter(func(l): return l["kind"] == "loot").map(func(l): return l["text"])
	ck("items: an Enemy's set drop is left as it falls, unnamed until the fight is won", b.found.has("bp:Marked:1") and left.has(e1["name"] + " leaves a blueprint not found before — win to keep it and learn what it is"), left)
	b.progress.name("bp:Sundered:1")
	var e2: Dictionary = b.side_units("enemy")[1]
	e2["setDrops"] = [{"item": "bp:Sundered:1", "chance": 100}, {"item": "bp:Marked:1", "chance": 100}]
	from = b.log.size()
	e2["hp"] = 0
	b.check_downs()
	left = b.log.slice(from).filter(func(l): return l["kind"] == "loot").map(func(l): return l["text"])
	ck("items: one you know by name is named, and one already found in this fight isn't left twice", left.has(e2["name"] + " leaves a blueprint: Sundered L1 (up to 1)") and b.found.count("bp:Marked:1") == 1 and b.found.has("bp:Sundered:1"), left)
	var marked := b.log.filter(func(l): return l["kind"] == "loot" and l.get("item", false))
	ck("items: the log tells a blueprint's line from a line of shards and components, one for each found", marked.size() == b.found.size() and marked.all(func(l): return " leaves a blueprint" in str(l["text"]))
		and not b.log.any(func(l): return l["kind"] == "loot" and not l.get("item", false) and " leaves a " in str(l["text"])), marked)
	for e in b.side_units("enemy"):
		e["hp"] = 0
	b.wave = b.waves_total
	b.enemy_pile.clear()
	b.check_downs()
	b.settle()
	ck("items: the fight's result carries what was found", b.over and b.winner == "ally" and b.loot_result["items"].slice(0, b.found.size()) == b.found and b.loot_result["items"].size() >= 2, b.loot_result["items"])
	ck("items: a practice fight keeps none of it", b.progress.state["bp"].is_empty() and b.progress.state["ch"].is_empty())
	# the floor's own reward: each blueprint and chassis by its chance, and only when the fight is won
	var item_lines: Array = lf.raw["loot"]["lines"].filter(func(l): return l.get("kind") == "item")
	var chances: Array = item_lines.map(func(l): return l["chance"])
	for l in item_lines:
		l["chance"] = 100
	b = Battle.begin_team(lf, r, su, 21)
	for e in b.side_units("enemy"):
		e["hp"] = 0
	b.wave = b.waves_total
	b.enemy_pile.clear()
	b.check_downs()
	b.settle()
	var given: Array = b.loot_result["items"].slice(b.found.size())
	var owed: Array = ["bp:Burst:1", "ch:ch_test_verdant"].filter(func(it): return not b.found.has(it))
	var told_items: Array = b.log.filter(func(l): return l["kind"] == "loot" and l.get("own", false) and l.get("item", false)).map(func(l): return l["text"])
	ck("items: a floor's reward gives its blueprints and chassis when the fight is won, and never one the export doesn't know", b.winner == "ally" and item_lines.size() == 3 and given == owed and given.has("ch:ch_test_verdant") and not b.loot_result["items"].has("bp:Test Drone")
		and told_items.size() == given.size() and told_items.has("The floor's reward: a chassis"), [given, owed, told_items])
	b = Battle.begin_team(lf, r, su, 21)
	for u in b.side_units("ally"):
		u["hp"] = 0
	b.check_downs()
	b.settle()
	ck("items: and none of them when it is lost", b.over and b.winner == "enemy" and b.loot_result["items"] == b.found and not b.log.any(func(l): return str(l["text"]).begins_with("The floor's reward")), b.loot_result)
	for i in item_lines.size():
		item_lines[i]["chance"] = chances[i]
	# found by walking, and taken back by Undo
	b = Battle.begin_team(lf, r, su, 12)
	b.loot_table.tables["sources"]["lootTile"]["bp"] = 100
	var walker: Dictionary = b.side_units("ally")[0]
	var spot := Vector2i(-2, 4)
	for h in Hex.neighbours(spot):
		if b.floor_data.has_tile(h) and b.unit_at(h) == null and b.kind_at(h) != "loot":
			walker["pos"] = {"q": h.x, "r": h.y}
			break
	b.move(walker, spot)
	ck("items: a Loot Tile can leave one too", b.looted.has(spot) and b.found.size() == 1 and b.log.any(func(l): return str(l["text"]).begins_with("The Loot Tile leaves ")), b.found)
	b.undo_last()
	ck("items: Undo takes it back with the move", b.found.is_empty() and not b.looted.has(spot))

	# ---- a deployment's fight
	var dsu := su.duplicate(true)
	dsu["deploy"] = {"district": "3", "skull": 3, "kind": "poi", "pending": ["bp:Burst:1"]}
	var plain := Battle.begin_team(wf, r, su, 9)
	var d := Battle.begin_team(wf, r, dsu, 9)
	var lv := func(bt: Battle): var l: Array = bt.enemy_spawns().map(func(sp): return sp["level"]); l.sort(); return l
	ck("deploy fight: the tile's Skull Level sets the Enemies, a spawn tile painted higher staying that much higher", lv.call(plain) == [1, 2, 3, 4] and lv.call(d) == [3, 4, 5, 6] and d.poi_skull() == 3 and plain.poi_skull() == Loot.poi_skull(wf), [lv.call(plain), lv.call(d)])
	ck("deploy fight: an Enemy fights, and drops, at the level it arrived at", d.side_units("enemy").all(func(u): return u["skull"] == u["spawnLevel"] and u["skull"] >= 3) and d.enemy_pile.all(func(c): return c["level"] >= 3), d.side_units("enemy").map(func(u): return [u["name"], u["skull"]]))
	ck("deploy fight: no Instability, and it knows what the deployment has found already", d.instability == 0 and d.deploy["pending"] == ["bp:Burst:1"] and d.deploy["kind"] == "poi")
	var dh: Dictionary = d.side_units("ally")[0]
	var de: Dictionary = d.side_units("enemy")[0]
	de["setDrops"] = [{"item": "bp:Burst:1", "chance": 100}, {"item": "bp:Burst:2", "chance": 100}]
	de["hp"] = 0
	d.check_downs()
	ck("deploy fight: what the deployment already carries isn't left again, and its next level can be", not d.found.has("bp:Burst:1") and d.found.has("bp:Burst:2"), d.found)
	# the Emergency Exit
	var ex := Battle.begin_team(lf, r, dsu, 4)
	var amb := dsu.duplicate(true)
	amb["deploy"]["kind"] = "ambush"
	var ab := Battle.begin_team(lf, r, amb, 4)
	var pr := Battle.begin_team(lf, r, su, 4)
	var door := Vector2i(-1, 5)
	ck("exit: a symbol reading EX is an Emergency Exit", ex.exit_at(door) and not ex.exit_at(Vector2i(-3, 5)) and not ex.exit_at(Vector2i(0, 0)))
	var eh: Dictionary = ex.side_units("ally")[0]
	ck("exit: a Hero somewhere else can't leave", not ex.can_escape(eh) and not ex.escape(eh) and not ex.over)
	for bt in [ex, ab, pr]:
		bt.side_units("ally")[0]["pos"] = {"q": door.x, "r": door.y}
	ck("exit: standing on it inside a POI, a Hero can; in an ambush or a practice fight nobody can", ex.can_escape(eh) and not ab.can_escape(ab.side_units("ally")[0]) and not pr.can_escape(pr.side_units("ally")[0]))
	var drone := Rules.unit_from_card(Roster.unit_spec(r.card_named("Test Drone")), "ally")
	drone["pos"] = {"q": door.x, "r": door.y}
	ck("exit: a Troop can't lead the way out", not ex.can_escape(drone))
	var fell: Dictionary = ex.side_units("enemy")[0]
	fell["hp"] = 0
	ex.check_downs()
	ex.consumables[0]["used"] = true
	var other: Dictionary = ex.side_units("ally")[1]
	other["hp"] = 0
	other["down"] = true
	ck("exit: the Strike Team gets out", ex.escape(eh) and ex.over and ex.winner == "escape" and ex.log.any(func(l): return l["text"] == eh["name"] + " reaches the Emergency Exit. The Strike Team gets out."))
	var res := ex.deploy_result()
	ck("exit: what it found comes along, and the floor's own reward is given up", res["winner"] == "escape" and Loot.is_empty(res["reward"]) and not Loot.is_empty(res["haul"]) and ex.loot_result["won"] == false, res)
	ck("deploy fight: the result names who fell, what was used and who was beaten", res["heroesDown"] == [other["name"]] and res["troopsLost"].is_empty() and res["consUsed"] == [ex.consumables[0]["name"]] and res["kills"].size() == 1 and res["kills"][0]["name"] == fell["src"] and res["kills"][0]["skull"] == fell["skull"], res)
	ck("exit: nothing more happens once out", not ex.can_escape(eh) and not ex.can_act())

	# ---- the World Map, the dock and a deployment (what the Companion's own cases don't cover)
	var floors := x.floors()
	var c := Campaign.new(x, r, floors, 11)
	var w := c.world
	ck("map: the export's World Map is read: 875 tiles round a dock, six Districts, a Unique POI", w.exists() and w.map["tiles"].size() == 875 and w.dock() == "0,0" and w.radius() == 18 and w.skull_of("0,0") == 1 and w.district_of("0,0") == "" and w.unique_at("-1,2") != null and w.floors.size() == 5)
	ck("map: Skull Level rises a level every three rings", w.skull_of("0,1") == 1 and w.skull_of("0,3") == 1 and w.skull_of("0,4") == 2 and w.ambush_chance("0,4") == 10 and w.ambush_chance("0,0") == 0, [w.skull_of("0,3"), w.skull_of("0,4")])
	ck("map: nothing is known of it yet, and nobody is out", w.known_count() == 0 and not c.deploy.active() and c.status_line() == "0 deployments so far." and Loot.is_empty(c.deploy.stock))
	ck("map: a fight elsewhere knows what the campaign owns", r.progress == c.progress)
	var none := StrikeTeams.blank("Nobody")
	ck("deploy: a Strike Team with no Hero can't leave", c.deploy.reasons_against(none) == ["It has no Hero."] and not c.deploy.start(none)["ok"] and not c.deploy.active())
	var gone := StrikeTeams.blank("Ghosts")
	gone["heroes"] = ["No Such Hero"]
	ck("deploy: nor one whose Heroes this export doesn't have", c.deploy.reasons_against(gone) == ["None of its Heroes is in this export."])
	# (0.9: on a deployment the Troops are your designs: the starter's free copies here)
	t = Kit.field_team()
	t["consumables"]["No Such Tonic"] = 2
	# (0.10: what is packed is owned at the dock)
	for n in ["Test Stim", "Test Repair Kit", "Test Sandbags"]:
		c.dock.add_card(n, 2)
	c.dock.add_card("Test Aegis Core", 1)
	var started := c.deploy.start(t, c.deploy.default_pack(t))
	var cur: Dictionary = c.deploy.cur()
	ck("deploy: the Strike Team leaves the dock as built, the starter's copies free", started["ok"] and c.deploy.active() and cur["n"] == 1 and cur["pos"] == "0,0" and cur["steps"] == 0 and Loot.is_empty(cur["haul"]) and Loot.is_empty(c.deploy.stock) and cur["log"][0]["text"] == "Left the dock with Test Vanguard.")
	ck("deploy: it packs its Consumables and its Prototypes, those owned at the dock", cur["pack"]["cons"] == {"Test Stim": 2, "Test Repair Kit": 1, "Test Sandbags": 1} and cur["pack"]["protos"] == {"Test Aegis Core": 1}
		and c.dock.inv["cards"] == {"Test Repair Kit": 1, "Test Sandbags": 1}, [cur["pack"], c.dock.inv])
	ck("deploy: standing on the dock shows the tiles beside it", w.known_count() == 7 and w.known("0,1") and not w.known("0,2"))
	ck("deploy: one at a time", c.deploy.reasons_against(t).has("A Strike Team is already out. Bring it home first.") and not c.deploy.start(t)["ok"] and c.deploy.cur()["n"] == 1)
	ck("deploy: the team that is out is locked, by name", c.deploy.locked_team(t) and not c.deploy.locked_team(none) and not c.deploy.locked_team(null))
	ck("deploy: changing the team at the dock doesn't change the one that left", (func(): t["level"] = 6; return c.deploy.cur()["team"]["level"] == 2).call())
	w.tables["ambushStep"] = 0
	var st := c.deploy.step_to("0,1")
	ck("deploy: a step is one tile, onto open ground", st["moved"] and st["pos"] == "0,1" and not st["ambush"] and c.deploy.cur()["steps"] == 1 and not c.deploy.step_to("0,5")["moved"] and c.deploy.step_to("0,5")["why"] == "Not a step away")
	w.tables["ambushStep"] = 100
	st = c.deploy.step_to("0,2")
	ck("deploy: a step can spring an ambush; one on a Cache's tile leaves the Cache for after", st["ambush"] and st["content"] == null and not Rules.truthy(st.get("tileAmbush")), st)
	var sp = c.deploy.ambush("0,2", {})
	ck("deploy: an ambush is one floor, in the tile's District at its Skull Level", sp != null and sp["kind"] == "ambush" and sp["count"] == 1 and sp["district"] == "3" and sp["skull"] == 1 and w.floor_named(sp["floor"]) != null and c.deploy.spec() == sp, sp)
	ck("deploy: nothing else can be done until it is fought", not c.deploy.step_to("0,1")["moved"] and c.deploy.open_cache("0,2") != null if false else c.deploy.step_to("0,1")["why"] == "Finish what you started here first" and not c.deploy.home()["ok"])
	var now: Dictionary = c.deploy.team_now()
	ck("deploy: the team as it stands is the team that left", now["heroes"] == ["Test Warden", "Test Striker", "Quillon Vex"] and now["deck"]["Frame Trooper"] == 3 and now["actions"].has("Quillon Vex") and now["consumables"]["Test Stim"] == 2 and now["protos"] == ["Test Aegis Core"] and now["level"] == 2)
	var bag := Loot.bag()
	bag["shards"] = 7
	bag["parts"]["troop"][0] = 2
	var out := c.deploy.fight_over({"winner": "enemy", "haul": bag, "reward": Loot.bag(), "items": ["bp:Burst:1"], "heroesDown": ["Test Warden", "Nobody"], "troopsLost": ["Frame Trooper", "Frame Trooper", "Test Rally", "Aether Battery"], "consUsed": ["Test Stim", "Test Stim", "Test Stim", "Never Packed"], "kills": []})
	cur = c.deploy.cur()
	ck("deploy: a fight lost with a Hero standing can be tried again, and its loot is gone", out["next"] == "retry" and out["reserves"] == ["Test Striker", "Quillon Vex"] and Loot.is_empty(cur["haul"]) and cur["items"].is_empty() and cur["activity"] != null and c.deploy.retryable(), out)
	ck("deploy: the Hero who went down sits out the rest of it", cur["heroesOut"] == ["Test Warden"] and c.deploy.hero_names() == ["Test Striker", "Quillon Vex"])
	ck("deploy: a Troop that fell is gone for the rest of it: a copy out of the Deck each, and only what the Deck held", cur["lost"] == {"Frame Trooper": 2} and c.deploy.copies_left("Frame Trooper") == 1 and c.deploy.copies_left("Test Plating") == 1, cur["lost"])
	ck("deploy: a Consumable used is used, whoever won", cur["pack"]["cons"] == {"Test Repair Kit": 1, "Test Sandbags": 1}, cur["pack"]["cons"])
	now = c.deploy.team_now()
	ck("deploy: the team as it stands now", now["heroes"] == ["Test Striker", "Quillon Vex"] and now["deck"]["Frame Trooper"] == 1 and not now["consumables"].has("Test Stim") and now["actions"].has("Quillon Vex") and StrikeTeams.deck_count(now) == StrikeTeams.deck_count(Kit.field_team()) - 2, now["deck"])
	out = c.deploy.fight_over({"winner": "ally", "haul": bag, "reward": bag, "items": ["bp:Burst:1", "bp:Burst:1", "bp:Burst:3", "ch:ch_test_verdant"], "heroesDown": [], "troopsLost": ["Frame Trooper", "Frame Trooper"], "consUsed": [], "kills": [{"name": "Test Grunt", "skull": 1}]})
	cur = c.deploy.cur()
	ck("deploy: a fight won puts what dropped, and the floor's reward, into the haul", out["next"] == "map" and cur["haul"]["shards"] == 14 and cur["haul"]["parts"]["troop"][0] == 4 and cur["activity"] == null and cur["fights"] == 2, cur["haul"])
	ck("deploy: and what it found, once each and in order", cur["items"] == ["bp:Burst:1", "ch:ch_test_verdant"] and out["items"] == cur["items"] and c.progress.item_name("bp:Burst:1") == "Burst L1 (up to 2)" and c.progress.owned("Burst") == 0, cur["items"])
	ck("deploy: the last copy of a Troop can be lost, and no more than that", cur["lost"] == {"Frame Trooper": 3} and c.deploy.copies_left("Frame Trooper") == 0 and not c.deploy.team_now()["deck"].has("Frame Trooper"), cur["lost"])
	ck("deploy: an ambush on the way leaves the tile as it was", w.available("0,2") and not w.is_cleared("0,2"))
	var cache = c.deploy.open_cache("0,2")
	ck("deploy: a Cache is opened where the team stands, once", cache != null and not Loot.is_empty(cache["bag"]) and w.is_cleared("0,2") and c.deploy.open_cache("0,2") == null and c.deploy.cur()["log"][0]["text"].begins_with("Opened a cache: "), cache)
	# saved, and read back
	ck("save: it is kept in a file of its own", c.save() and FileAccess.file_exists(Campaign.path) and Campaign.path == Kit.CAMPAIGN)
	var r2 := Roster.new(x)
	var c2 := Campaign.new(x, r2, floors, 11)
	ck("save: read back, the deployment is where it was", c2.deploy.active() and c2.deploy.cur()["pos"] == "0,2" and c2.deploy.cur()["haul"] == c.deploy.cur()["haul"] and c2.deploy.cur()["items"] == ["bp:Burst:1", "ch:ch_test_verdant"] and c2.deploy.cur()["heroesOut"] == ["Test Warden"] and c2.deploy.cur()["lost"] == {"Frame Trooper": 3} and c2.note == "",
		[c2.deploy.cur()["pos"] if c2.deploy.active() else null, c2.note])
	ck("save: and so is what has been seen and cleared, and what has been named", c2.world.known_count() == w.known_count() and c2.world.is_cleared("0,2") and c2.world.state["completed"] == 0 and c2.progress.known_bp("Burst") and c2.deploy.team_now()["heroes"] == ["Test Striker", "Quillon Vex"])
	# home
	ck("home: only from the dock", not c.deploy.home()["ok"] and c.deploy.home()["why"] == "The team has to reach the dock")
	w.tables["ambushStep"] = 0
	c.deploy.step_to("0,1")
	var back := c.deploy.step_to("0,0")
	var carried: Dictionary = Loot.norm(c.deploy.cur()["haul"])
	var h := c.deploy.home()
	ck("home: walking back onto the dock banks the haul", back["home"] and h["ok"] and h["n"] == 1 and h["haul"] == carried and c.deploy.stock == carried and not c.deploy.active() and c.deploy.last()["result"] == "home")
	ck("home: what was found is yours", h["items"].size() == 2 and h["items"].has("bp:Burst:1") and h["items"].has("ch:ch_test_verdant") and c.progress.owned("Burst") == 1 and c.progress.has_chassis("ch_test_verdant"))
	ck("home: the deployment is counted and told", w.state["completed"] == 1 and c.deploy.history.size() == 1 and c.deploy.history_line(c.deploy.history[0]).begins_with("Deployment 1 · came home · Test Vanguard · 4 steps, 2 fights · ") and "Burst L1 (up to 2)" in c.deploy.history_line(c.deploy.history[0]) and
		c.status_line() == "1 deployment so far. Deployment 1 came home.", c.deploy.history_line(c.deploy.history[0]))
	ck("home: the dock lists the stockpile and what you own", c.stock_lines()[0]["text"] == "%d Aether shards" % carried["shards"] and c.stock_lines().size() > 1 and c.progress.owned_lines().size() == 2, c.stock_lines())
	ck("home: the Cache is cleared for three deployments", w.is_cleared("0,2") and w.back_in("0,2") == 3 and not w.available("0,2"))
	# a wipe
	t["level"] = 2
	c.dock.add_card("Test Stim", 2)
	c.deploy.start(t, c.deploy.default_pack(t))
	ck("deploy: the next deployment starts whole again", c.deploy.cur()["n"] == 2 and c.deploy.hero_names().size() == 3 and c.deploy.copies_left("Frame Trooper") == 3 and c.deploy.cur()["pack"]["cons"].get("Test Stim") == 2)
	w.tables["ambushStep"] = 100
	c.deploy.step_to("0,1")
	c.deploy.ambush("0,1", {})
	out = c.deploy.fight_over({"winner": "ally", "haul": bag, "reward": Loot.bag(), "items": ["bp:Burst:2", "bp:Pierce:1"], "heroesDown": ["Test Warden", "Test Striker"], "troopsLost": [], "consUsed": [], "kills": []})
	c.deploy.ambush("0,1", {})
	var before_stock: Dictionary = c.deploy.stock.duplicate(true)
	out = c.deploy.fight_over({"winner": "draw", "haul": bag, "reward": bag, "items": [], "heroesDown": ["Quillon Vex"], "troopsLost": [], "consUsed": [], "kills": []})
	ck("wipe: with no Hero left, the deployment is over and what it carried is lost", out["next"] == "wipe" and out["lostHaul"]["shards"] == 7 and out["lostItems"] == ["bp:Burst:2", "bp:Pierce:1"] and not c.deploy.active() and c.deploy.last()["result"] == "wipe" and c.deploy.stock == before_stock and c.progress.owned("Burst") == 1 and c.progress.owned("Pierce") == 0, out)
	ck("wipe: but a blueprint it found stays named", c.progress.known_bp("Pierce") and c.progress.item_name("bp:Pierce:1") == "Pierce")
	ck("wipe: it is counted, and told as one", w.state["completed"] == 2 and c.deploy.history[0]["result"] == "wipe" and "wiped out" in c.deploy.history_line(c.deploy.history[0]) and "lost: 7 shards" in c.deploy.history_line(c.deploy.history[0]) and c.status_line() == "2 deployments so far. Deployment 2 was wiped out: its haul was lost.", c.deploy.history_line(c.deploy.history[0]))
	# a POI, to its end; and an Event
	w.tables["ambushStep"] = 0
	c.deploy.start(t)
	c.deploy.step_to("0,1")
	c.deploy.cur()["pos"] = "-1,2"
	var poi = c.deploy.enter_poi("-1,2")
	ck("POI: a Unique POI's own floors, in order, less any this export doesn't have", poi != null and poi["name"] == "Test Vault" and poi["count"] == 2 and poi["floor"] == "TEST · Loot" and c.deploy.cur()["activity"]["floors"] == ["TEST · Loot", "TEST · Corridor"], poi)
	out = c.deploy.fight_over({"winner": "ally", "haul": bag, "reward": Loot.bag(), "items": [], "heroesDown": [], "troopsLost": [], "consUsed": [], "kills": []})
	ck("POI: a floor won leads to the next", out["next"] == "floor" and out["floor"] == 2 and out["count"] == 2 and c.deploy.spec()["floor"] == "TEST · Corridor" and c.deploy.spec()["index"] == 1 and not w.is_cleared("-1,2"), out)
	out = c.deploy.fight_over({"winner": "ally", "haul": Loot.bag(), "reward": Loot.bag(), "items": [], "heroesDown": [], "troopsLost": [], "consUsed": [], "kills": []})
	ck("POI: the last floor won pays its reward and clears it", out["next"] == "map" and out["poiDone"] and out["final"]["bag"]["shards"] == 30 and Loot.count(out["final"]["bag"]) == 2 and out["final"]["items"].has("bp:Pierce:1") and c.deploy.cur()["items"].has("bp:Pierce:1") and w.is_cleared("-1,2") and c.deploy.cur()["activity"] == null, out)
	c.deploy.cur()["pos"] = "-1,-1"
	poi = c.deploy.enter_poi("-1,-1")
	out = c.deploy.fight_over({"winner": "escape", "haul": bag, "reward": bag, "items": ["bp:AoE:1"], "heroesDown": [], "troopsLost": [], "consUsed": [], "kills": []})
	ck("POI: leaving by an Emergency Exit keeps what was found there, gives up the rest, and clears it", out["next"] == "map" and out["escaped"] and out["gained"]["shards"] == 7 and not out.has("final") and c.deploy.cur()["items"].has("bp:AoE:1") and w.is_cleared("-1,-1"), out)
	c.deploy.cur()["pos"] = "0,3"
	var ev = c.deploy.event_at("0,3")
	ck("event: the tile's Event, with its choices", ev != null and ev["choices"].size() == 2 and ev == w.event_for("0,3") and c.deploy.event_at("0,2") == null, ev)
	var haul_before: Dictionary = Loot.norm(c.deploy.cur()["haul"])
	var o = c.deploy.choose("0,3", 1)
	ck("event: a choice with no check simply happens, and the Event is done", o != null and o["check"] == 0.0 and o["roll"] == 0 and o["won"] and o["text"] != "" and not o["fight"] and w.is_cleared("0,3") and c.deploy.choose("0,3", 0) == null and Loot.norm(c.deploy.cur()["haul"]) == haul_before, o)
	c.deploy.cur()["pos"] = "-2,3"
	var ev2: Dictionary = c.deploy.event_at("-2,3")
	c.loot.seed_with(5)
	o = c.deploy.choose("-2,3", 0)
	var need := World.number(ev2["choices"][0]["check"])
	ck("event: a check is a d20 against its number", o["check"] == need and o["roll"] >= 1 and o["roll"] <= 20 and o["won"] == (o["roll"] >= need) and c.deploy.cur()["log"][0]["text"] == "%s: %s (rolled %d, needed %d)." % [ev2["title"], ev2["choices"][0]["label"], o["roll"], int(need)], [o["roll"], need, c.deploy.cur()["log"][0]["text"]])
	ck("event: one that goes wrong can start a fight where the team stands", o["fight"] == (c.deploy.cur()["activity"] != null) and (not o["fight"] or (o["spec"]["kind"] == "ambush" and c.deploy.cur()["activity"]["fromEvent"])))
	# a different map
	c.deploy.cur()["activity"] = null
	c.save()
	var kept: Dictionary = Loot.add(c.deploy.stock, c.deploy.cur()["haul"])
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Campaign.path))
	raw["map"] = "another map"
	var f := FileAccess.open(Campaign.path, FileAccess.WRITE)
	f.store_string(JSON.stringify(raw))
	f.close()
	var c3 := Campaign.new(x, Roster.new(x), floors, 11)
	ck("new map: exploration starts again, and the stockpile and what was found stay", c3.world.known_count() == 0 and c3.world.state["cleared"].is_empty() and c3.world.state["completed"] == 3 and c3.progress.owned("Burst") == 1 and "different World Map" in c3.note, c3.note)
	ck("new map: a Strike Team out on the old one is brought home with its haul", not c3.deploy.active() and c3.deploy.stock == kept and c3.deploy.history[0]["result"] == "recalled" and c3.progress.owned("Pierce") == 1 and "brought home" in c3.note, [c3.deploy.stock, kept])
	var c4 := Campaign.new(x, Roster.new(x), floors, 11)
	ck("new map: and that is kept, so it is said once", c4.note == "" and c4.deploy.stock == kept and c4.world.state["completed"] == 3)
	# a floor the export no longer has
	c4.deploy.start(t)
	c4.deploy.cur()["activity"] = {"kind": "ambush", "tile": "0,0", "district": "3", "skull": 1, "floors": ["A floor since deleted"], "index": 0, "name": "Ambush", "type": "", "unique": null, "tileAmbush": false, "fromEvent": false}
	c4.save()
	var c5 := Campaign.new(x, Roster.new(x), floors, 11)
	ck("save: a fight waiting on a floor the export no longer has is drawn again", c5.deploy.active() and c5.deploy.spec() != null and c5.world.floor_named(c5.deploy.spec()["floor"]) != null, c5.deploy.spec())
	# an export with no World Map at all, with that team still out
	var c7 := Campaign.new(null, Roster.new(x), floors, 11)
	ck("new map: an export with no map at all brings a team that was out home too, and says so", not c7.world.exists() and not c7.deploy.active() and c7.deploy.history[0]["result"] == "recalled" and c7.deploy.stock == kept
		and c7.note == "This export has no World Map, so the Strike Team that was out has been brought home with its haul.", c7.note)
	# what is cleared comes back
	var w9 := World.new(Loot.new(null, 1), x.content("world_map"), floors)
	w9.clear("0,2", 1)
	var comes_back := []
	for i in 5:
		comes_back.append([w9.is_cleared("0,2"), w9.back_in("0,2"), w9.available("0,2")])
		w9.end_deployment()
	ck("map: a tile cleared in a deployment stays cleared through the next three, and then holds something again", w9.respawn() == 3 and comes_back == [[true, 4, false], [true, 3, false], [true, 2, false], [true, 1, false], [false, 0, true]], comes_back)
	# a save the device refuses
	var real_path := Campaign.path
	Campaign.path = "user://no_such_folder/campaign.json"
	ck("save: one the device refuses says so", not c7.save() and "couldn't be saved" in c7.error)
	Campaign.path = real_path
	ck("save: and the next one that works takes that back", c7.save() and c7.error == "")
	f = FileAccess.open(Campaign.path, FileAccess.WRITE)
	f.store_string("{ not json")
	f.close()
	var c6 := Campaign.new(x, Roster.new(x), floors, 11)
	ck("save: a file that can't be read starts afresh and says so", not c6.deploy.active() and Loot.is_empty(c6.deploy.stock) and "couldn't be read" in c6.note)
	c6.reset()
	ck("save: starting over forgets everything", not FileAccess.file_exists(Campaign.path) and c6.world.known_count() == 0 and c6.deploy.history.is_empty())
	# a POI's reward counts what its last floor has just left (what Companion 13.5 puts right, here from the start)
	c6.world.tables["ambushStep"] = 0
	c6.deploy.start(Kit.field_team())
	c6.deploy.cur()["pos"] = "-1,2"
	c6.deploy.enter_poi("-1,2")
	c6.deploy.fight_over({"winner": "ally", "haul": Loot.bag(), "reward": Loot.bag(), "items": [], "heroesDown": [], "troopsLost": [], "consUsed": [], "kills": []})
	out = c6.deploy.fight_over({"winner": "ally", "haul": Loot.bag(), "reward": Loot.bag(), "items": ["bp:Pierce:1"], "heroesDown": [], "troopsLost": [], "consUsed": [], "kills": []})
	ck("POI: its reward doesn't give again the blueprint its last floor has just left", out.get("poiDone", false) and out.get("items") == ["bp:Pierce:1"] and not out["final"]["items"].has("bp:Pierce:1") and c6.deploy.cur()["items"].count("bp:Pierce:1") == 1, [out.get("items"), out.get("final")])
	c6.reset()
	# an export with no World Map
	var bare := World.new(Loot.new(null, 1), null, floors)
	var nd := Deployment.new(bare, Progress.new(Loot.new(null, 1)), Loot.new(null, 1), r)
	ck("map: an export without one says so, and nobody can leave", not bare.exists() and nd.reasons_against(Kit.team()).any(func(why): return "no World Map" in why))
	Rules.hooks = {}
	Kit.fresh()


# ---------------------------------------------------------------- 0.8 on the screen: the dock, the World Map and a deployment
## Ends the fight on the board: every Enemy down with no more to come, or every Unit of yours.
func _end_fight(scene: Node, won: bool) -> void:
	var bt: Battle = scene.battle
	for u in bt.side_units("enemy" if won else "ally"):
		u["hp"] = 0
		u["down"] = true
	if won:
		bt.wave = bt.waves_total
		bt.enemy_pile.clear()
		bt.fx.check_downs()
	bt.settle()
	scene.board.refresh_units(bt)
	scene.show_result()
	await _frames(3)


func _map_point(scene: Node, k: String) -> Vector2:
	return scene.get_viewport().get_canvas_transform() * scene.map_view.to_global(scene.map_view.centre_of(k))


## Puts the Strike Team on a tile, as if it had walked there in peace.
func _put_team(scene: Node, k: String) -> void:
	scene.campaign.deploy.cur()["pos"] = k
	scene.campaign.world.stand(k)
	scene.map_view.place_team(k)
	scene.map_screen.tap(k)


func _eight_scene() -> void:
	Kit.fresh()
	var team: Dictionary = Kit.field_team()
	Kit.keep([team, StrikeTeams.blank("Empty Bench")])
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	var cm: Campaign = scene.campaign
	var ms: MapScreen = scene.map_screen
	var dk: DockScreen = scene.dock_screen
	cm.loot.seed_with(21)
	for n in ["Test Stim", "Test Repair Kit", "Test Sandbags"]:
		cm.dock.add_card(n, 2)
	cm.dock.add_card("Test Aegis Core", 1)
	ck("0.8 home: Play comes first, in gold, over Practice and Strike Teams", scene.home.visible and scene.home.world_btn.visible and not scene.home.world_btn.disabled and scene.home.world_btn.text == "Play" and scene.home.world_btn.theme_type_variation == "MainButton"
		and "Deploy a Strike Team" in scene.home.world_sub.text and scene.home.practice_btn.visible and scene.home.teams_btn.visible and not scene.home.practice_row.visible and scene.home.note.text == "0 deployments so far.", [scene.home.world_btn.text, scene.home.note.text])
	scene.home.practice_btn.pressed.emit()
	ck("0.15 home: Practice opens its two fights to pick from, a Battle and a Quick battle", scene.home.practice_row.visible and scene.home.practice_btn.button_pressed and scene.home.battle_btn.get_parent() == scene.home.practice_row and scene.home.quick_btn.get_parent() == scene.home.practice_row
		and _labels(scene.home.battle_btn).has("Battle") and _labels(scene.home.quick_btn).has("Quick battle"))
	scene.home.practice_btn.pressed.emit()
	ck("0.15 home: and pressed again, puts them away", not scene.home.practice_row.visible and not scene.home.practice_btn.button_pressed)
	ck("0.15 home: the sign is the game's name (no title over it), Look again only with no export", not scene.home.title.visible and not scene.home.again_btn.visible and not scene.home.source.visible)
	scene.home.options_btn.pressed.emit()
	await _frames(2)
	ck("home: Options (the gear) says its version, 0.24, and the export the content came from", scene.VERSION == "0.24" and scene.options != null and scene.options.about.visible and "version 0.24" in scene.options.about.text and "export.zip" in scene.options.about.text
		and scene.options.again_btn.visible and scene.home.options_btn.icon == Art.icon("gear"), scene.options.about.text if scene.options != null else "")
	scene.close_options()
	await _frames(2)
	# ---- the dock
	scene.home.world_btn.pressed.emit()
	await _frames(2)
	var rows := dk.row_texts()
	ck("0.8 dock: with nobody out, World Map opens the dock", dk.visible and not scene.home.visible and not ms.visible and dk.title.text == "The dock")
	ck("0.8 dock: it lists the stockpile, what you have found, and the deployments", rows == ["Stockpile", "0 Aether shards", "Also kept here", "2 × Test Stim", "2 × Test Repair Kit", "2 × Test Sandbags", "1 × Test Aegis Core", "No blueprints or chassis found yet.", "No deployments yet.", "Testing"] and dk.go_btn.text == "Deploy" and not dk.go_btn.disabled and dk.map_btn.visible, rows)
	var qm_said: String = dk.keeper_line.text
	ck("0.15 dock: QM-7 keeps it: its portrait, its name and one line of its own for the tab", dk.keeper.visible and dk.portrait.texture == Art.menu_piece("qm7") and qm_said != "" and (QM7.LINES["stockpile"] + QM7.LINES["anytime"]).has(qm_said)
		and dk.go_btn.theme_type_variation == "MainButton" and not dk.hint.visible, qm_said)
	ck("0.15 dock: what the tab is for waits behind the \"?\"", "Deploy sends a Strike Team onto the World Map" in dk.hint.text and "research blueprints in the Workshop" in dk.help_text and "Also kept here: " in dk.help_text, dk.help_text)
	dk.help_btn.pressed.emit()
	await _frames(2)
	ck("0.15 dock: the \"?\" opens it in a box, and Close puts it away", dk.dialog != null and dk.dialog.title_label.text == "Stockpile" and "Deploy sends a Strike Team" in dk.dialog.text_label.text and "Blueprints and chassis: Enemies, Loot Tiles" in dk.dialog.text_label.text, dk.dialog.text_label.text if dk.dialog != null else "")
	if dk.dialog != null:
		dk.dialog.buttons[0].pressed.emit()
		await _frames(2)
	dk.show_tab("exchange")
	var qm_ex: String = dk.keeper_line.text
	ck("0.15 dock: a new tab, a new line, its own or one it says any time", qm_ex != qm_said and (QM7.LINES["exchange"] + QM7.LINES["anytime"]).has(qm_ex), [qm_said, qm_ex])
	dk.show_tab("stockpile")
	ck("0.15 QM-7: about forty lines, none of them twice", QM7.count() >= 40 and dict_size(QM7.LINES.values().reduce(func(a, b): return a + b, [])) == QM7.count(), QM7.count())
	await _frames(1)
	dk._on_blink()
	ck("0.15 dock: now and then, its optics shut for a moment", dk.portrait.texture == Art.menu_piece("qm7_blink") and Art.menu_piece("qm7_blink") != Art.menu_piece("qm7"))
	dk._on_blink()
	ck("0.15 dock: and open again", dk.portrait.texture == Art.menu_piece("qm7"))
	rows = dk.row_texts()
	dk.map_btn.pressed.emit()
	await _frames(2)
	ck("0.8 map: it can be looked at with nobody out", ms.visible and scene.map_view.visible and not scene.board.visible and ms.title_label.text == "World Map  ·  at the dock" and ms.p_title.text == "Nobody is out" and ms.actions().map(func(a): return a["id"]) == ["dock"] and not ms.team_btn.visible, ms.actions())
	ms.tap("3,-2")
	ck("0.8 map: a tile tapped says its District and Skull Level, and that what it holds isn't known", ms.p_title.text == "District 1 · Threshold Dynamics" and ms.lines()[0] == "Skull 1  ·  Unknown: stand next to it to see what it holds" and "5% chance of an ambush" in ms.lines()[1] and not ms.actions().any(func(a): return a["id"] == "walk"), ms.lines())
	ms.do("dock")
	await _frames(2)
	ck("0.8 map: Back to the dock goes back", dk.visible and not ms.visible and not scene.map_view.visible and scene.board.visible)
	# ---- sending a Strike Team out
	dk.go_btn.pressed.emit()
	await _frames(2)
	ck("0.8 deploy: Deploy lists your Strike Teams, and which can go", dk.choosing and dk.title.text == "Deploy" and dk.row_texts() == ["Test Vanguard", "Empty Bench"] and dk.go_btn.text == "Leave the dock" and dk.go_btn.disabled and "Its Troops must be your designs" in dk.hint.text and "first 4 free" in dk.hint.text and
		_labels(dk._rows[0]["row"]).has("Ready") and _labels(dk._rows[1]["row"]).has("Can't go"), [dk.row_texts(), dk.hint.text])
	var row1: Control = dk._rows[1]["row"]
	dk.list.tap(row1.global_position - dk.list.global_position + row1.size / 2)
	await _frames(2)
	ck("0.8 deploy: one with no Hero is refused, and why is said", dk.team_i == 1 and dk.go_btn.disabled and dk.note.text == "It has no Hero.", dk.note.text)
	var row0: Control = dk._rows[0]["row"]
	dk.list.tap(row0.global_position - dk.list.global_position + row0.size / 2)
	await _frames(2)
	ck("0.8 deploy: a tap chooses one that can, and says what its copies cost", dk.team_i == 0 and not dk.go_btn.disabled and dk.note.text.begins_with("Test Vanguard is ready to leave. Its copies: 3 × Frame Trooper, free. Packed: ") and "2 × Test Stim" in dk.note.text and "Test Aegis Core" in dk.note.text and not dk.field_btn.visible, dk.note.text)
	dk.back_btn.pressed.emit()
	await _frames(1)
	ck("0.8 deploy: Back returns to the dock, with nobody sent", not dk.choosing and dk.visible and not cm.deploy.active())
	dk.go_btn.pressed.emit()
	await _frames(1)
	dk.choose_team(0)
	dk.go_btn.pressed.emit()
	await _frames(3)
	ck("0.8 deploy: Leave the dock sends it out, and the map opens on it", cm.deploy.active() and ms.visible and scene.map_view.visible and not dk.visible and ms.title_label.text == "Deployment 1  ·  Test Vanguard" and scene.map_view.team_at == "0,0" and ms.selected == "0,0")
	ck("0.8 deploy: it is saved at once", FileAccess.file_exists(Campaign.path) and JSON.parse_string(FileAccess.get_file_as_string(Campaign.path))["deployment"]["active"] == true)
	ck("0.8 map: the bar says who is standing and what is carried", ms.status_label.text == "Heroes standing: 3 of 3   ·   Haul: 0 shards, 0 parts   ·   0 steps, 0 fights" and ms.team_btn.visible and ms.log_btn.visible and ms.find_btn.text == "Find team", ms.status_label.text)
	ck("0.8 map: the team's marker is its first Hero's token", scene.map_view.token != null and scene.map_view.token == scene.roster.token_for(scene.roster.card_named("Test Warden")).get("texture"))
	ck("0.8 map: on the dock, the panel offers to come home", ms.p_title.text == "The dock" and ms.actions().map(func(a): return a["label"]) == ["Come home"], ms.actions())
	ck("0.8 map: the board's touches are the map's now", scene._map_live() and not scene._board_live())
	# ---- the Strike Team that is out can't be changed
	scene.open_teams()
	await _frames(2)
	var ts: TeamsScreen = scene.teams_screen
	ck("0.8 teams: the team that is out says so", ts.visible and not ms.visible and ts.is_locked(0) and not ts.is_locked(1) and _labels(ts._rows[0]["row"]).has("Out on a deployment"), _labels(ts._rows[0]["row"]))
	var trow: Control = ts._rows[0]["row"]
	ts.list.tap(trow.global_position - ts.list.global_position + Vector2(60, trow.size.y / 2))
	await _frames(2)
	ck("0.8 teams: tapping it opens nothing, and says why", not ts.editor.visible and ts.editing == -1 and "is out on a deployment" in ts.note.text, ts.note.text)
	var del: Control = ts._rows[0]["delete"]
	ts.list.tap(del.global_position - ts.list.global_position + del.size / 2)
	await _frames(2)
	ck("0.8 teams: nor can it be deleted", ts.dialog == null and ts.teams.size() == 2)
	ts.edit(1)
	ck("0.8 teams: another team can still be built on", ts.editor.visible and ts.editing == 1)
	ts.close_editor()
	scene.show_home()
	await _frames(1)
	ck("0.8 home: with a Strike Team out, home says so", "A Strike Team is out" in scene.home.world_sub.text and scene.home.note.text == "Deployment 1 is out with Test Vanguard: 0 steps, 0 fights.", scene.home.note.text)
	scene.home.world_btn.pressed.emit()
	await _frames(3)
	ck("0.8 home: and World Map goes straight back to it", ms.visible and not dk.visible and scene.map_view.team_at == "0,0")
	# ---- walking
	cm.world.tables["ambushStep"] = 0
	var p0 := _map_point(scene, "0,2")
	_touch(scene, 0, p0, true)
	_touch(scene, 0, p0, false)
	await _frames(2)
	ck("0.8 map: a touch on a tile chooses it, and shows the way there", ms.selected == "0,2" and scene.map_view.selected == "0,2" and scene.map_view.route == ["0,0", "0,1", "0,2"] and ms.lines().any(func(l): return l.begins_with("2 steps away  ·  0% chance")) and ms.actions().map(func(a): return a["id"]) == ["walk"], [ms.selected, scene.map_view.route, ms.lines()])
	var cam0: Vector2 = scene.camera.position
	_touch(scene, 0, Vector2(300, 400), true)
	_drag(scene, 0, Vector2(360, 400), Vector2(60, 0))
	_touch(scene, 0, Vector2(360, 400), false)
	ck("0.8 map: a drag pans it, and chooses nothing", scene.camera.position.x < cam0.x and ms.selected == "0,2")
	scene.fit_map()
	ck("0.8 map: Fit shows all of it", scene.camera.zoom.x < 0.4 and scene.camera.zoom.x >= scene.ZOOM_MIN, scene.camera.zoom)
	ms.find_btn.pressed.emit()
	await _frames(2)
	ck("0.8 map: Find team brings it back to where a thumb can use it", scene.camera.zoom == Vector2.ONE and absf(_map_point(scene, "0,0").x - (1280.0 - MapScreen.PANEL_W - 20.0) / 2.0) < 2.0, _map_point(scene, "0,0"))
	ms.tap("9,9")
	var off := ms.p_title.text
	ms.tap("1,-2")
	ck("0.8 map: collapsed structure is told as that", cm.world.is_open("9,9") == (off != "Collapsed structure") and (cm.world.is_open("1,-2") or ms.p_title.text == "Collapsed structure"))
	# (the Event two tiles past the Cache: the only way there is over the Cache's tile)
	ms.tap("0,3")
	ck("0.8 walk: the way to a tile further off runs over what lies between", scene.map_view.route == ["0,0", "0,1", "0,2", "0,3"] and ms.actions().map(func(a): return a["id"]) == ["walk"] and not cm.world.known("0,3"), scene.map_view.route)
	ms.act(0)
	ck("0.8 walk: Walk here sets off, and offers Stop", ms.walking and ms.actions().any(func(a): return a["id"] == "stop"))
	var n := 0
	while ms.walking and n < 600:
		await process_frame
		n += 1
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Campaign.path))
	ck("0.8 walk: it goes a step at a time and stops at what it finds, short of where it was sent", not ms.walking and cm.deploy.cur()["pos"] == "0,2" and cm.deploy.cur()["steps"] == 2 and scene.map_view.team_at == "0,2" and ms.selected == "0,2" and scene.map_view.marker.at.distance_to(scene.map_view.centre_of("0,2")) < 1.0, [cm.deploy.cur()["pos"], n])
	ck("0.8 walk: every step is saved", saved["deployment"]["pos"] == "0,2" and int(saved["deployment"]["steps"]) == 2 and saved["world"]["known"].has("0,3"))
	ck("0.8 walk: standing next to a tile shows what it holds", cm.world.known("0,3") and cm.world.known("-1,2") and ms.lines()[0] == "Skull 1  ·  Cache" and ms.actions().map(func(a): return a["label"]) == ["Open it"], ms.lines())
	ms.tap("-1,2")
	ck("0.8 map: a Unique POI is named", ms.lines()[0] == "Skull 1  ·  Unique POI: Test Vault (Vault)" and ms.actions().map(func(a): return a["id"]) == ["walk"], ms.lines())
	ms.tap("0,2")
	ms.do("cache")
	await _frames(2)
	ck("0.8 cache: Open it puts what it holds into the haul, and says what", ms.note.begins_with("The cache holds ") and not Loot.is_empty(cm.deploy.cur()["haul"]) and cm.world.is_cleared("0,2") and ms.lines()[0] == ms.note and "Haul: 0 shards, 0 parts" not in ms.status_label.text, [ms.note, ms.status_label.text])
	saved = JSON.parse_string(FileAccess.get_file_as_string(Campaign.path))
	ck("0.8 cache: and that is saved at once", saved["world"]["cleared"].has("0,2") and int(saved["deployment"]["haul"]["shards"]) == int(cm.deploy.cur()["haul"]["shards"]) and int(saved["deployment"]["haul"]["shards"]) > 0, saved["deployment"]["haul"])
	ck("0.8 cache: the tile now reads as cleared, and when it comes back", ms.lines().any(func(l): return "Cache  ·  cleared, back after 3 more deployments" in l) and not ms.actions().any(func(a): return a["id"] == "cache"), ms.lines())
	# a walk that is stopped
	var far_tile := ""
	for k in cm.world.map["tiles"]:
		var way: Array = cm.world.path("0,2", k)
		if way.size() >= 6 and way.slice(1).all(func(step): return cm.world.content_at(step) == null):
			far_tile = k
			break
	ms.tap(far_tile)
	var far: Array = scene.map_view.route.duplicate()
	ms.walk(far_tile)
	await _frames(2)
	ms.do("stop")
	n = 0
	while ms.walking and n < 600:
		await process_frame
		n += 1
	ck("0.8 walk: Stop stops it where it stands", far.size() >= 6 and cm.deploy.cur()["pos"] != far_tile and cm.deploy.cur()["pos"] != "0,2" and far.has(cm.deploy.cur()["pos"]) and ms.selected == cm.deploy.cur()["pos"] and not ms.walking, [far, cm.deploy.cur()["pos"]])
	# ---- an ambush, and the fight
	cm.world.tables["ambushStep"] = 100
	var here: String = cm.deploy.cur()["pos"]
	var next_tile: String = World.neighbours(here).filter(func(k): return cm.world.is_open(k) and cm.world.content_at(k) == null)[0]
	await ms.walk(next_tile)
	await _frames(2)
	ck("0.8 ambush: a step can spring one, and the walk stops there", cm.deploy.cur()["activity"] != null and cm.deploy.cur()["activity"]["kind"] == "ambush" and ms.note.begins_with("Ambush! Enemies close in on the way.") and ms.p_title.text == "Ambush" and ms.actions().map(func(a): return a["label"]) == ["Fight"], [ms.note, ms.actions()])
	saved = JSON.parse_string(FileAccess.get_file_as_string(Campaign.path))
	ck("0.8 ambush: the fight that waits is saved, so closing the game doesn't get out of it", saved["deployment"]["activity"] is Dictionary and saved["deployment"]["activity"]["kind"] == "ambush" and saved["deployment"]["pos"] == next_tile, saved["deployment"]["activity"])
	ms.tap("0,0")
	ck("0.8 ambush: nothing else can be done until it is fought", ms.actions().map(func(a): return a["id"]) == ["fight"] and ms.p_title.text == "Ambush")
	ms.act(0)
	await _frames(3)
	var s: SetupScreen = scene.setup
	var spec: Dictionary = cm.deploy.spec()
	ck("0.8 fight: Fight opens its setup at who enters, on the floor that was drawn", s.visible and not ms.visible and s.mode == "deploy" and s.step == "heroes" and s.title.text == "Ambush  ·  Skull %d" % spec["skull"] and (s.the_floor().name == spec["floor"] or (ChunkGen.is_gen_key(spec["floor"]) and s.the_floor().name == cm.world.level(spec["floor"])["name"])) and s.the_floor().district == spec["district"] and s.back_btn.text == "Map" and s.steps() == ["heroes", "troops"], [s.title.text, s.step])
	ck("0.8 fight: it is the Strike Team as it stands, and says what a fall costs", s.team()["heroes"] == ["Test Warden", "Test Striker", "Quillon Vex"] and s.heroes.size() == Roster.hero_capacity(s.the_floor()) and "sits out the rest of the deployment" in s.hint.text, s.hint.text)
	s.back_btn.pressed.emit()
	await _frames(3)
	ck("0.8 fight: Map goes back, with the fight still waiting", ms.visible and not s.visible and cm.deploy.cur()["activity"] != null and cm.deploy.cur()["fights"] == 0)
	ms.do("fight")
	await _frames(2)
	s._go(1)
	await _frames(2)
	ck("0.8 fight: Starting Troops come next, with no wave timer or Instability to set", s.step == "troops" and not s._rows.any(func(e): return e.has("timer")) and "gone for the rest of the deployment" in s.hint.text and s.next_btn.text == "Start battle", s.hint.text)
	s.more_troop("Frame Trooper")
	s.next_btn.pressed.emit()
	await _frames(4)
	var bt: Battle = scene.battle
	ck("0.8 fight: the Battle begins, as part of the deployment", bt != null and not s.visible and not scene.map_view.visible and scene.board.visible and bt.deploy != null and bt.deploy["kind"] == "ambush" and bt.deploy["skull"] == spec["skull"] and bt.floor_data.district == spec["district"] and bt.instability == 0 and bt.wave_timer == 3 and scene._board_live() and not scene._map_live())
	ck("0.8 fight: with its Heroes, its Starting Troop and its Consumables", bt.side_units("ally").map(func(u): return u["name"]).has("Frame Trooper") and bt.consumables.size() == 4 and bt.protos.size() == 1 and bt.progress == cm.progress)
	scene.ask_leave()
	await _frames(2)
	ck("0.8 fight: Leave asks, and says the fight starts again", scene.dialog != null and scene.dialog.title_label.text == "Leave this fight?" and "starts again from its setup" in scene.dialog.text_label.text and scene.dialog.buttons.map(func(x): return x.text) == ["Stay", "Back to the map"])
	scene.dialog.buttons[1].pressed.emit()
	await _frames(3)
	ck("0.8 fight: left half-way, nothing of it is kept or spent", ms.visible and scene.battle == null and cm.deploy.cur()["activity"] != null and cm.deploy.cur()["fights"] == 0 and cm.deploy.cur()["pack"]["cons"]["Test Stim"] == 2 and cm.deploy.copies_left("Frame Trooper") == 3)
	ms.do("fight")
	await _frames(2)
	s._go(1)
	s.more_troop("Frame Trooper")
	s.start()
	await _frames(4)
	bt = scene.battle
	bt.consumables[0]["used"] = true
	var used: String = bt.consumables[0]["name"]
	var the_drone: Dictionary = bt.side_units("ally").filter(func(u): return u["name"] == "Frame Trooper")[0]
	the_drone["hp"] = 0
	bt.check_downs()
	var haul0: Dictionary = Loot.norm(cm.deploy.cur()["haul"])
	await _end_fight(scene, true)
	var said: String = scene.dialog.text_label.text if scene.dialog != null else ""
	ck("0.8 result: won, it says what goes into the haul and what the fight cost", scene.dialog != null and scene.dialog.title_label.text == "Victory" and "Every Enemy is down" in said and "Into the haul: " in said and "Troops lost for the rest of it: Frame Trooper." in said and ("Consumables used: %s." % used) in said and "yours once the team walks back onto the dock" in said and
		scene.dialog.buttons.map(func(x): return x.text) == ["Back to the map", "See the board"], said)
	var cur: Dictionary = cm.deploy.cur()
	ck("0.8 result: the deployment has it: the haul, the Troop gone, the Consumable used", cur["activity"] == null and cur["fights"] == 1 and Loot.norm(cur["haul"])["shards"] > haul0["shards"] and cm.deploy.copies_left("Frame Trooper") == 2 and int(cur["pack"]["cons"].get(used, 0)) == int(Kit.team()["consumables"][used]) - 1 and scene.deploy_out["next"] == "map", [cur["haul"], cur["lost"], cur["pack"]["cons"]])
	saved = JSON.parse_string(FileAccess.get_file_as_string(Campaign.path))
	ck("0.8 result: and it is saved", saved["deployment"]["activity"] == null and int(saved["deployment"]["fights"]) == 1)
	scene.dialog.buttons[1].pressed.emit()
	await _frames(2)
	scene.ask_leave()
	await _frames(2)
	ck("0.8 result: See the board, then Leave, brings the result back, told once to the deployment", scene.dialog != null and scene.dialog.title_label.text == "Victory" and cm.deploy.cur()["fights"] == 1)
	scene.dialog.buttons[0].pressed.emit()
	await _frames(3)
	ck("0.8 result: Back to the map", ms.visible and scene.battle == null and scene.map_view.visible and "1 fight" in ms.status_label.text and ms.actions().all(func(a): return a["id"] != "fight"), ms.status_label.text)
	# ---- a fight lost with Heroes in reserve, tried again, and lost for good
	here = cm.deploy.cur()["pos"]
	next_tile = World.neighbours(here).filter(func(k): return cm.world.is_open(k) and cm.world.content_at(k) == null and k != cm.world.dock())[0]
	await ms.walk(next_tile)
	ms.do("fight")
	await _frames(2)
	for hn in s.heroes.duplicate():
		s.toggle_hero(hn)
	s.toggle_hero("Test Warden")
	s._go(1)
	s.start()
	await _frames(4)
	var carried: Dictionary = Loot.norm(cm.deploy.cur()["haul"])
	scene.battle.loot = Loot.add(scene.battle.loot, {"shards": 9})
	await _end_fight(scene, false)
	said = scene.dialog.text_label.text
	ck("0.8 lost: with Heroes in reserve the fight can be tried again, and the haul is safe", scene.dialog.title_label.text == "Defeat" and "Test Warden is down and sits out the rest of the deployment." in said and "What dropped here is lost with the fight: 9 shards." in said and "Test Striker and Quillon Vex can try this fight again." in said and
		scene.dialog.buttons.map(func(x): return x.text) == ["Retry with reserves", "Give up: lose the haul", "See the board"] and Loot.norm(cm.deploy.cur()["haul"]) == carried and cm.deploy.cur()["activity"] != null, said)
	scene.dialog.buttons[0].pressed.emit()
	await _frames(4)
	ck("0.8 lost: Retry sets the same fight up again with who is left", s.visible and s.mode == "deploy" and s.team()["heroes"] == ["Test Striker", "Quillon Vex"] and not s._rows.any(func(e): return e.get("hero") == "Test Warden") and s.the_floor().name == cm.deploy.spec()["floor"], s.team()["heroes"])
	s._go(1)
	s.start()
	await _frames(4)
	await _end_fight(scene, false)
	said = scene.dialog.text_label.text
	ck("0.8 wipe: with nobody left, the deployment is lost and says what went with it", scene.dialog.title_label.text == "Defeat" and "Deployment lost: a wipe loses everything carried: " in said and campaign_text(cm, carried) in said and scene.dialog.buttons.map(func(x): return x.text) == ["Back to the map", "See the board"] and not cm.deploy.active() and Loot.is_empty(cm.deploy.stock), said)
	scene.dialog.buttons[0].pressed.emit()
	await _frames(3)
	ck("0.8 wipe: back on the map, nobody is out", ms.visible and scene.map_view.team_at == "" and ms.p_title.text == "Nobody is out" and ms.status_label.text == "1 deployment so far. Deployment 1 was wiped out: its haul was lost.", ms.status_label.text)
	ms.do("dock")
	await _frames(2)
	ck("0.8 wipe: the dock tells it, and the team can be changed again", dk.visible and dk.row_texts().any(func(t): return t.begins_with("Deployment 1 · wiped out · Test Vanguard")) and not cm.deploy.locked_team(team), dk.row_texts())
	# ---- a POI, floor by floor, and home with what it gave
	cm.world.tables["ambushStep"] = 0
	dk.go_btn.pressed.emit()
	dk.choose_team(0)
	dk.go_btn.pressed.emit()
	await _frames(3)
	ck("0.8 deploy: out again, whole", cm.deploy.cur()["n"] == 2 and cm.deploy.hero_names().size() == 3 and cm.deploy.copies_left("Frame Trooper") == 3 and ms.visible)
	await ms.walk("-1,2")
	await _frames(2)
	ck("0.8 POI: standing on one, the panel says how many floors and offers to enter", cm.deploy.cur()["pos"] == "-1,2" and ms.lines().any(func(l): return l.begins_with("Test Vault: 2 floors, fought in order")) and ms.actions().map(func(a): return a["label"]) == ["Enter"], ms.lines())
	ms.act(0)
	await _frames(2)
	saved = JSON.parse_string(FileAccess.get_file_as_string(Campaign.path))
	ck("0.8 POI: once entered it is saved: the floors drawn are the floors to fight", saved["deployment"]["activity"] is Dictionary and saved["deployment"]["activity"]["kind"] == "poi" and saved["deployment"]["activity"]["floors"] == cm.deploy.cur()["activity"]["floors"] and int(saved["deployment"]["activity"]["index"]) == 0, saved["deployment"]["activity"])
	ck("0.8 POI: Enter draws its floors, and the first fight waits", cm.deploy.cur()["activity"]["kind"] == "poi" and ms.p_title.text == "Test Vault" and ms.lines()[0].begins_with("Floor 1 of 2  ·  Skull 1") and ms.actions().map(func(a): return a["id"]) == ["fight"], ms.lines())
	ms.act(0)
	await _frames(2)
	ck("0.8 POI: its setup says which floor", s.title.text == "Test Vault  ·  floor 1 of 2  ·  Skull 1" and s.the_floor().name == "TEST · Loot", s.title.text)
	s._go(1)
	s.start()
	await _frames(4)
	bt = scene.battle
	# the Emergency Exit
	var lead: Dictionary = bt.side_units("ally")[0]
	var door := Vector2i(-1, 5)
	var beside: Vector2i = Hex.neighbours(door).filter(func(h): return bt.floor_data.has_tile(h) and bt.unit_at(h) == null)[0]
	_place(scene, lead["id"], beside)
	scene.select(lead)
	_tap(scene, door)
	n = 0
	while (scene.walking or scene.dialog == null) and n < 400:
		await process_frame
		n += 1
	ck("0.8 exit: a Hero who walks onto the Emergency Exit is asked", Battle.tile_of(lead) == door and scene.dialog != null and scene.dialog.title_label.text == "Emergency Exit" and scene.dialog.buttons.map(func(x): return x.text) == ["Leave the POI", "Fight on"] and "final reward is given up" in scene.dialog.text_label.text and not bt.over, [Battle.tile_of(lead), scene.dialog.title_label.text if scene.dialog != null else ""])
	scene.dialog.buttons[1].pressed.emit()
	await _frames(2)
	ck("0.8 exit: Fight on fights on", scene.dialog == null and not bt.over and cm.deploy.cur()["activity"] != null)
	await _end_fight(scene, true)
	said = scene.dialog.text_label.text
	ck("0.8 POI: a floor won leads on, and says there is no other way out", scene.dialog.title_label.text == "Victory" and "Floor 1 of 2 cleared. The only way out is onward, or an Emergency Exit." in said and scene.dialog.buttons.map(func(x): return x.text) == ["Next floor (2 of 2)", "See the board"] and "The floor's reward" not in said, said)
	var after_one: Dictionary = Loot.norm(cm.deploy.cur()["haul"])
	ck("0.8 POI: the floor's own reward is in the haul with what dropped", after_one["shards"] >= 12 and Loot.count(after_one) >= 3, after_one)
	var fights_then: int = cm.deploy.cur()["fights"]
	scene.dialog.buttons[1].pressed.emit()
	await _frames(2)
	scene.ask_leave()
	await _frames(2)
	ck("0.8 POI: See the board, then Leave, brings that result back: the floor is counted once, and the next is still to fight", scene.dialog != null and scene.dialog.title_label.text == "Victory" and scene.dialog.buttons.map(func(x): return x.text) == ["Next floor (2 of 2)", "See the board"]
		and cm.deploy.cur()["activity"] != null and int(cm.deploy.cur()["activity"]["index"]) == 1 and cm.deploy.cur()["fights"] == fights_then and Loot.norm(cm.deploy.cur()["haul"]) == after_one, [cm.deploy.cur()["activity"], cm.deploy.cur()["fights"]])
	scene.dialog.buttons[0].pressed.emit()
	await _frames(4)
	ck("0.8 POI: Next floor sets up the next", s.visible and s.title.text == "Test Vault  ·  floor 2 of 2  ·  Skull 1" and s.the_floor().name == "TEST · Corridor", s.title.text)
	s._go(1)
	s.start()
	await _frames(4)
	await _end_fight(scene, true)
	said = scene.dialog.text_label.text
	ck("0.8 POI: its last floor won pays its reward, and names what it gave", "Test Vault cleared. Its reward: 30 shards" in said and "blueprint Pierce" in said and scene.dialog.buttons.map(func(x): return x.text) == ["Back to the map", "See the board"] and cm.deploy.cur()["items"].has("bp:Pierce:1") and cm.world.is_cleared("-1,2"), said)
	scene.dialog.buttons[0].pressed.emit()
	await _frames(3)
	ck("0.8 POI: back on the map it is cleared, and the find is counted", ms.visible and ms.lines().any(func(l): return "Unique POI: Test Vault (Vault)  ·  cleared, back after 3 more deployments" in l) and " find" in ms.status_label.text and not ms.actions().any(func(a): return a["id"] == "enter"), [ms.lines(), ms.status_label.text])
	ms.show_team()
	await _frames(2)
	# (what else the fights left behind is the dice's: a chassis, another blueprint, or nothing)
	var found_now: Array = cm.deploy.cur()["items"].duplicate()
	var found_line := ""
	for tl in ms.dialog.text_label.text.split("\n"):
		if tl.begins_with("Found: "):
			found_line = tl
	var found_names: Array = Array(found_line.trim_prefix("Found: ").trim_suffix(".").split(", "))
	ck("0.8 map: Team says who stands, what is left and what is carried", ms.dialog != null and "Heroes standing: Test Warden, Test Striker, Quillon Vex." in ms.dialog.text_label.text and "Consumables left: " in ms.dialog.text_label.text and "A wipe loses it." in ms.dialog.text_label.text and not scene._map_live()
		and found_now.has("bp:Pierce:1") and found_names.has("Pierce") and found_names == found_now.map(func(it): return cm.progress.item_name(it)) and "unknown" not in found_line, ms.dialog.text_label.text)
	ms.dialog.buttons[0].pressed.emit()
	ms.show_log()
	await _frames(2)
	var good_path := Campaign.path
	Campaign.path = "user://no_such_folder/campaign.json"
	cm.save()
	ms.refresh()
	ck("0.8 save: one the device refuses is said under the status, until one works", cm.error != "" and ms.status_label.text.ends_with("\n" + cm.error) and "couldn't be saved" in ms.status_label.text, ms.status_label.text)
	Campaign.path = good_path
	cm.save()
	ms.refresh()
	ck("0.8 save: and then it is gone", cm.error == "" and "couldn't be saved" not in ms.status_label.text and "\n" not in ms.status_label.text, ms.status_label.text)
	ck("0.8 map: Log tells the deployment, newest first", ms.dialog != null and ms.dialog.text_label.text.split("\n")[2] == "Test Vault cleared." and "Left the dock with Test Vanguard." in ms.dialog.text_label.text, ms.dialog.text_label.text)
	ms.dialog.buttons[0].pressed.emit()
	await _frames(2)
	# an Event
	await ms.walk("0,3")
	await _frames(2)
	var ev: Dictionary = cm.deploy.event_at("0,3")
	ck("0.8 event: standing on one tells it and offers its choices, a check with its number", cm.deploy.cur()["pos"] == "0,3" and ms.lines().has(str(ev["title"])) and ms.lines().has(str(ev["text"])) and ms.actions().size() == 2 and ms.actions()[0]["label"] == "%s (d20, %d or more)" % [ev["choices"][0]["label"], int(ev["choices"][0]["check"])] and ms.actions()[1]["label"] == str(ev["choices"][1]["label"]), ms.actions())
	ms.act(1)
	await _frames(2)
	saved = JSON.parse_string(FileAccess.get_file_as_string(Campaign.path))
	ck("0.8 event: and the choice is saved: it can't be made again for a better roll", saved["world"]["cleared"].has("0,3") and saved["deployment"]["log"][0]["text"] == cm.deploy.cur()["log"][0]["text"], saved["world"]["cleared"])
	ck("0.8 event: a choice is made and what came of it is told", ms.event_out != null and ms.lines().has("%s: %s" % [ev["title"], ev["choices"][1]["label"]]) and ms.lines().has(str(ev["choices"][1]["win"]["text"])) and cm.world.is_cleared("0,3") and ms.actions().is_empty(), ms.lines())
	# home
	await ms.walk("0,0")
	await _frames(2)
	ck("0.8 home: back on the dock", cm.deploy.cur()["pos"] == "0,0" and ms.actions().map(func(a): return a["id"]) == ["home"] and ms.event_out == null)
	var bringing: Dictionary = Loot.norm(cm.deploy.cur()["haul"])
	cm.dock.state["bounties"] = []        # (bounties are 0.10's, and tested on their own: here the haul alone is banked)
	ms.act(0)
	await _frames(2)
	ck("0.8 home: Come home banks the haul and what was found, and says so", not cm.deploy.active() and cm.deploy.stock == bringing and cm.progress.owned("Pierce") == 1 and ms.dialog != null and ms.dialog.title_label.text == "Home" and "Deployment 2 is home." in ms.dialog.text_label.text and
		("Into the stockpile: %s." % cm.loot.text(bringing)) in ms.dialog.text_label.text and "They are in the Workshop now." in ms.dialog.text_label.text and scene.map_view.team_at == "", ms.dialog.text_label.text)
	saved = JSON.parse_string(FileAccess.get_file_as_string(Campaign.path))
	ck("0.8 home: and it is saved: the stockpile, what is owned, and the deployment ended", saved["deployment"]["active"] == false and int(saved["stock"]["shards"]) == bringing["shards"] and saved["history"].size() == 2 and saved["history"][0]["result"] == "home" and int(saved["world"]["completed"]) == 2 and saved["progress"]["bp"].has("Pierce"), [saved["stock"], saved["progress"]])
	var yours_line := ""
	for tl in ms.dialog.text_label.text.split("\n"):
		if tl.begins_with("Now yours: "):
			yours_line = tl
	var yours: Array = Array(yours_line.trim_prefix("Now yours: ").trim_suffix(".").split(", "))
	var kept_now: Array = cm.deploy.history[0]["items"]
	ck("0.8 home: and names each blueprint and chassis that is now yours, everything it carried", yours.has("blueprint Pierce") and yours.size() == found_now.size() and kept_now.size() == found_now.size() and found_now.all(func(it): return kept_now.has(it))
		and yours.all(func(y): return str(y).begins_with("blueprint ") or str(y).begins_with("chassis ")) and "unknown" not in yours_line
		and kept_now.all(func(it): return not cm.progress.eligible(it)), [yours_line, found_now, kept_now])
	ms.dialog.buttons[0].pressed.emit()
	await _frames(3)
	rows = dk.row_texts()
	ck("0.8 home: the dock shows the stockpile, the blueprint and both deployments", dk.visible and rows.has("%d Aether shards" % bringing["shards"]) and rows.has("Pierce") and rows.filter(func(t): return t.begins_with("Deployment ")).size() == 2 and rows[rows.find("Deployments") + 1].begins_with("Deployment 2 · came home · Test Vanguard"), rows)
	# ---- a practice fight still keeps nothing, and knows what you own
	scene.open_setup("quick")
	scene.start_battle(0, [scene.roster.card_named("Test Warden")], [], 3)
	await _frames(3)
	ck("0.8 practice: a Battle from the menu is no part of a deployment, and knows what you own", scene.battle.deploy == null and scene.battle.progress == cm.progress and not scene.battle.progress.eligible("bp:Pierce:1"))
	await _end_fight(scene, true)
	ck("0.8 practice: it says nothing is kept, and nothing is", "A practice fight: nothing is kept." in scene.dialog.text_label.text or Loot.is_empty(scene.battle.loot_result["total"]), scene.dialog.text_label.text)
	ck("0.8 practice: the stockpile is as it was", cm.deploy.stock == bringing and not cm.deploy.active())
	scene.dialog.buttons[2].pressed.emit()
	await _frames(2)
	# ---- read again from the file
	scene.load_export(FIXTURE)
	await _frames(2)
	var c2: Campaign = scene.campaign
	ck("0.8 save: a new session finds it all: the stockpile, the blueprint, the map as explored, the deployments", c2 != cm and c2.deploy.stock == bringing and c2.progress.owned("Pierce") == 1 and c2.world.known("0,3") and c2.world.is_cleared("-1,2") and c2.world.state["completed"] == 2 and c2.deploy.history.size() == 2 and not c2.deploy.active() and
		scene.home.note.text == "2 deployments so far. Deployment 2 came home.", scene.home.note.text)
	# ---- a fight that could be tried again, given up
	c2.world.tables["ambushStep"] = 100
	scene.open_world()
	await _frames(2)
	dk.go_btn.pressed.emit()
	await _frames(1)
	dk.choose_team(0)
	dk.go_btn.pressed.emit()
	await _frames(3)
	var first_step: String = World.neighbours("0,0").filter(func(k): return c2.world.is_open(k) and c2.world.content_at(k) == null)[0]
	await ms.walk(first_step)
	await _frames(2)
	ms.do("fight")
	await _frames(2)
	for hn in s.heroes.duplicate():
		s.toggle_hero(hn)
	s.toggle_hero("Test Warden")
	s._go(1)
	s.start()
	await _frames(4)
	await _end_fight(scene, false)
	ck("0.8 give up: a fight lost with Heroes in reserve offers it", c2.deploy.active() and c2.deploy.cur()["n"] == 3 and scene.dialog != null and scene.dialog.buttons.map(func(x): return x.text) == ["Retry with reserves", "Give up: lose the haul", "See the board"])
	scene.dialog.buttons[1].pressed.emit()
	await _frames(2)
	saved = JSON.parse_string(FileAccess.get_file_as_string(Campaign.path))
	ck("0.8 give up: the deployment ends as a wipe and says what went with it", not c2.deploy.active() and scene.dialog != null and scene.dialog.title_label.text == "Deployment lost" and "A wipe loses everything carried: " in scene.dialog.text_label.text
		and scene.dialog.buttons.map(func(x): return x.text) == ["Back to the map"] and c2.deploy.history[0]["result"] == "wipe" and c2.world.state["completed"] == 3, scene.dialog.text_label.text if scene.dialog != null else "")
	ck("0.8 give up: and that is saved", saved["deployment"]["active"] == false and saved["history"].size() == 3 and saved["history"][0]["result"] == "wipe" and int(saved["world"]["completed"]) == 3, saved["history"][0])
	scene.dialog.buttons[0].pressed.emit()
	await _frames(3)
	ck("0.8 give up: back on the map, nobody is out, and the stockpile is as it was", ms.visible and scene.battle == null and scene.map_view.team_at == "" and ms.p_title.text == "Nobody is out" and c2.deploy.stock == bringing, ms.p_title.text)
	scene.queue_free()
	await _frames(2)
	Kit.fresh()


## A bag as the campaign's tables word it.
func campaign_text(cm: Campaign, bag: Dictionary) -> String:
	return cm.loot.text(bag)


# ---------------------------------------------------------------- 0.9: the Workshop
## A design to work with: one Action on the Threshold chassis.
func _hornet(ws: Workshop, text := "[[target enemy]] takes [[damage 2]] with [[Burst 2]].") -> Dictionary:
	var d := ws.blank("ch_test_threshold")
	d["name"] = "Hornet"
	d["abilities"][0]["name"] = "Stinger"
	d["abilities"][0]["text"] = text
	return d


func _parts(common: int, uncommon := 0) -> Array:
	return [common, uncommon, 0, 0, 0, 0]


func _stock(common: int, shards := 0) -> Dictionary:
	var b := Loot.bag()
	b["parts"]["troop"][0] = common
	b["shards"] = shards
	return b


func _nine() -> void:
	Kit.fresh()
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)
	var c := Campaign.new(x, r, x.floors(), 5)
	var ws := c.workshop
	var p := c.progress
	# ---- the starter
	var st: Dictionary = ws.get_design("ds_starter")
	ck("0.9 workshop: the starter is there from the first", ws.list().size() == 1 and ws.list()[0]["name"] == "Frame Trooper" and st["chassis"] == "ch_test_general" and st["abilities"][0]["name"] == "Carbine", ws.list())
	ck("0.9 workshop: it can't be changed or deleted", ws.locked("ds_starter") and ws.put(st.duplicate(true)) == "" and not ws.remove("ds_starter") and ws.list().size() == 1)
	ck("0.9 workshop: it fits, at power 6, and a copy costs 6 Common Troop parts", ws.check(st)["ok"] and ws.cost(st)["power"] == 6 and ws.cost(st)["parts"] == _parts(6) and Workshop.cost_text(ws.cost(st)["parts"]) == "6 Common", ws.cost(st))
	var fc = r.card_named("Frame Trooper")
	ck("0.9 roster: your designs are Troop cards, the starter among them, and the export's copy of it gives way", fc != null and fc["_src"] == "workshop" and fc["_design"] == "ds_starter" and Roster.type_of(fc) == "troop" and r.troops()[0]["name"] == "Frame Trooper"
		and r.cards.filter(func(k): return k["name"] == "Frame Trooper").size() == 1, fc.get("_src") if fc != null else null)
	# ---- chassis and blueprints
	ck("0.9 workshop: only the starter's chassis is yours at first, and no blueprint", p.has_chassis("ch_test_general") and not p.has_chassis("ch_test_threshold") and p.owned("Burst") == 0 and p.owned("damage") == 99 and not p.is_blueprint("target enemy") and p.is_blueprint("Burst"))
	ck("0.9 workshop: the chassis list holds them all, found or not (0.22: the Skitter Frame too)", ws.chassis_list().size() == 6 and ws.chassis_list().map(func(k): return k["id"]).has("ch_test_threshold"))
	var ab: Dictionary = ws.blank("ch_test_threshold")["abilities"][0]
	ck("0.9 workshop: a new design starts with one Action of its chassis's first subtype, its numbers at the baseline", ab["kind"] == "action" and ab["role"] == "Ranged" and ab["energy"] == 1 and ab["range"] == 4 and ab["hit"] == 6 and ab["ap"] == 4 and ab["text"] == "", ab)
	ck("0.9 workshop: the keywords it may use are its chassis's, less the blueprints you haven't found", ws.allowed_for(ws.chassis_of({"chassis": "ch_test_threshold"})) == ["target enemy", "damage", "turns"], ws.allowed_for(ws.chassis_of({"chassis": "ch_test_threshold"})))
	var d := _hornet(ws)
	var chk := ws.check(d)
	ck("0.9 check: on a chassis not found, with a blueprint not found, it can't deploy, and says why", not chk["ok"] and chk["reasons"] == ["Burst needs blueprint level 1 — not found yet", "this chassis has not been found yet"], chk["reasons"])
	p.grant("ch:ch_test_threshold")
	p.grant("bp:Burst:1")
	chk = ws.check(d)
	ck("0.9 check: found, it fits", chk["ok"] and chk["reasons"].is_empty() and chk["cap"] == 30.0 and chk["abilityCap"] == 2.0, chk)
	d["abilities"][0]["text"] = "[[target enemy]] takes [[damage 2]] with [[Burst 3]]."
	ck("0.9 check: a number higher than your blueprint's level allows needs the next level", ws.check(d)["reasons"] == ["Burst needs blueprint level 2 — you have level 1"], ws.check(d)["reasons"])
	p.set_unlock_all(true)
	ck("0.9 testing: with everything unlocked, it fits", ws.check(d)["ok"] and p.owned("Burst") == 3 and p.has_chassis("ch_test_lazarus"))
	ck("0.9 testing: and nothing drops", p.roll_items({"chance": 100, "district": "1", "card": {"setDrops": [{"item": "bp:Pierce:1", "chance": 100}]}}).is_empty() and not p.eligible("ch:ch_test_lazarus") and not p.eligible("bp:Pierce:1"))
	p.set_unlock_all(false)
	ck("0.9 testing: switched off, it is as it was", not ws.check(d)["ok"] and p.owned("Burst") == 1 and not p.has_chassis("ch_test_lazarus") and p.eligible("bp:Pierce:1"))
	d["abilities"][0]["text"] = "[[target enemy]] takes [[damage 2]] with [[Burst 2]]."
	var three := d.duplicate(true)
	three["abilities"] = [d["abilities"][0].duplicate(), d["abilities"][0].duplicate(), d["abilities"][0].duplicate()]
	three["abilities"][1]["energy"] = 5
	three["abilities"][2]["role"] = "Melee"
	three["abilities"][2]["range"] = 9
	var rs: Array = ws.check(three)["reasons"]
	ck("0.9 check: too many abilities, power over the cap, Energy over the chassis's, a role it hasn't and a number over its maximum are each said",
		rs.has("3 abilities, where this chassis holds 2") and rs.any(func(k): return str(k).begins_with("power ") and "is over this chassis's cap of 30" in str(k)) and rs.has("ability 2 (Stinger) costs 5 Energy, more than this chassis's 4")
		and rs.has("ability 3 is Melee, which this chassis's subtypes (Ranged and Cyber) do not allow") and not rs.any(func(k): return "range of 9" in str(k)), rs)
	three["abilities"][2]["role"] = "Ranged"
	rs = ws.check(three)["reasons"]
	ck("0.9 check: an attack's range over its chassis's maximum", rs.has("ability 3 (Stinger)'s range of 9 is over this chassis's 7"), rs)
	var empty := ws.blank("ch_test_general")
	ck("0.9 check: an ability with no text doesn't fit", ws.check(empty)["reasons"] == ["ability 1 has no text"], ws.check(empty)["reasons"])
	var wasp := ws.blank("ch_test_general")
	wasp["abilities"][0]["text"] = "[[target enemy]] gains [[Marked]]."
	ck("0.9 check: a keyword its chassis can't use", ws.check(wasp)["reasons"].has("this chassis cannot use Marked"), ws.check(wasp)["reasons"])
	# ---- saved as yours
	var id := ws.put(d)
	c.designs_changed()
	var hc = r.card_named("Hornet")
	ck("0.9 workshop: a design is kept under an id of its own", id.begins_with("ds_") and ws.get_design(id)["name"] == "Hornet" and ws.by_name("Hornet")["id"] == id and ws.list().map(func(k): return k["name"]) == ["Frame Trooper", "Hornet"], id)
	ck("0.9 roster: and is a Troop card, its stats its chassis's", hc != null and hc["_src"] == "workshop" and hc["_design"] == id and str(hc["stats"]["hp"]) == "10" and hc["entries"][0]["text"] == d["abilities"][0]["text"] and Roster.origin(hc) == "Your design", hc)
	var pw: int = ws.cost(d)["power"]
	ck("0.9 cost: a copy costs its chassis's parts and half its power, rounded up", ws.cost(d)["parts"] == _parts(int(ceil(6 + 0.5 * pw))) and ws.cost(d)["lines"][0]["label"] == "Chassis 6 + 0.5 × power %d" % pw, ws.cost(d))
	ck("0.9 cost: and the stockpile pays for so many", ws.affordable(d, _stock(30)) == int(floor(30.0 / ws.cost(d)["parts"][0])) and ws.affordable(d, Loot.bag()) == 0)
	# ---- research
	var bag := _stock(0, 50)
	var res := p.research("Burst", bag)
	ck("0.9 research: level 2 costs 60 shards, and 50 aren't enough", not res["ok"] and res.get("why") == "Needs 60 shards; you have 50" and bag["shards"] == 50 and p.owned("Burst") == 1, res)
	bag["shards"] = 70
	res = p.research("Burst", bag)
	ck("0.9 research: with enough, it is yours, and the shards are spent", res["ok"] and res["level"] == 2 and res["price"] == 60 and bag["shards"] == 10 and p.owned("Burst") == 2, res)
	ck("0.9 research: one not found yet can't be", p.research("Pierce", _stock(0, 500)).get("why") == "Its first level has to be found")
	ck("0.9 research: nor while a team is out", p.research("Burst", _stock(0, 500), true).get("why") == "The dock is closed while a Strike Team is out")
	ck("0.9 research: nor past its highest level, nor a free keyword", (func(): p.state["bp"]["Burst"] = 3; return p.research("Burst", _stock(0, 500)).get("why") == "Already at its highest level").call() and p.research("damage", _stock(0, 500)).get("why") == "Not a blueprint")
	p.state["bp"]["Burst"] = 1
	# ---- leaving the dock
	var t := Kit.field_team()
	t["deck"]["Frame Trooper"] = 6
	t["deck"]["Hornet"] = 2
	var each: int = ws.cost(d)["parts"][0]
	var pl := c.deploy.plan(t)
	ck("0.9 leaving: each copy is paid for, the starter's first 4 free", pl["fits"] and not pl["afford"] and pl["lines"].size() == 2 and pl["lines"][0]["name"] == "Frame Trooper" and pl["lines"][0]["free"] == 4 and pl["lines"][0]["cost"] == _parts(12)
		and pl["lines"][1]["name"] == "Hornet" and pl["lines"][1]["cost"] == _parts(2 * each) and pl["parts"] == _parts(12 + 2 * each), pl)
	c.deploy.stock = _stock(10, 3)
	var why := c.deploy.reasons_against(t)
	ck("0.9 leaving: a stockpile that can't pay says so, and it doesn't leave", why == ["The stockpile can't pay for its copies: they cost %d Common, and it holds 10 Common." % (12 + 2 * each)] and not c.deploy.start(t)["ok"] and not c.deploy.active() and c.deploy.stock == _stock(10, 3), why)
	c.deploy.stock = _stock(100, 3)
	var go := c.deploy.start(t)
	var cur: Dictionary = c.deploy.cur() if c.deploy.active() else {}
	ck("0.9 leaving: one that can pays as it leaves, and what was paid is kept", go["ok"] and c.deploy.stock == _stock(100 - 12 - 2 * each, 3) and cur["paid"] == _parts(12 + 2 * each) and cur["copies"] == {"ds_starter": 6, id: 2}, c.deploy.stock)
	ck("0.9 out: its designs are locked while it is out", ws.locked(id) and c.deploy.locked_design(id) and ws.put(ws.get_design(id)) == "" and not ws.remove(id) and not c.deploy.locked_design("ds_none"))
	ck("0.9 out: and research waits", not p.research("Burst", _stock(0, 500), c.deploy.active())["ok"])
	c.world.tables["ambushStep"] = 100
	var k1: String = World.neighbours("0,0").filter(func(k): return c.world.is_open(k) and c.world.content_at(k) == null)[0]
	c.deploy.step_to(k1)
	c.deploy.ambush(k1, {})
	var lost := c.deploy.fight_over({"winner": "ally", "haul": Loot.bag(), "reward": Loot.bag(), "items": [], "heroesDown": [], "troopsLost": ["Hornet", "Hornet", "Hornet"], "consUsed": [], "kills": []})
	ck("0.9 out: a design's copies fall like any Troop's, no more than went out", c.deploy.cur()["lost"] == {"Hornet": 2} and c.deploy.copies_left("Hornet") == 0 and lost["next"] == "map", c.deploy.cur()["lost"])
	c.world.tables["ambushStep"] = 0
	c.deploy.step_to("0,0")
	var home := c.deploy.home()
	ck("0.9 home: the copies aren't paid back, and its designs can be changed again", home["ok"] and c.deploy.stock == _stock(100 - 12 - 2 * each, 3) and not ws.locked(id) and ws.put(ws.get_design(id)) == id, c.deploy.stock)
	# ---- teams made before 0.9
	var old := Kit.team()
	why = c.deploy.reasons_against(old)
	ck("0.9 leaving: Forge Troops can't go, and each is said", why.has("Test Drone is a Forge Troop (×3): Troops come only from the Workshop.") and why.has("Test Scout is a Forge Troop (×2): Troops come only from the Workshop.") and c.deploy.needs_field_copy(old) and not c.deploy.start(old)["ok"], why)
	var field := c.deploy.field_copy(old, "Field")
	ck("0.9 field copy: it takes the Forge Troops out and puts the starter's free copies in, the rest as it was", field["name"] == "Field" and not field["deck"].has("Test Drone") and field["deck"].get("Frame Trooper") == 4 and field["deck"].get("Test Rally") == old["deck"]["Test Rally"]
		and field["heroes"] == old["heroes"] and field["consumables"] == old["consumables"] and c.deploy.reasons_against(field).is_empty() and not c.deploy.needs_field_copy(field) and old["deck"].has("Test Drone"), field["deck"])
	ck("0.9 field copy: a team that has the starter keeps its count", c.deploy.field_copy(t, "F2")["deck"].get("Frame Trooper") == 6)
	# a design of the Companion's that hasn't been copied in
	var comp := ws.to_card(_hornet(ws))
	comp["name"] = "Companion Wasp"
	comp["_src"] = "design"
	r.from_export.append(comp)
	c.designs_changed()
	var ct := Kit.field_team()
	ct["deck"]["Companion Wasp"] = 1
	ck("0.9 leaving: a design from the export has to be copied in first", c.deploy.reasons_against(ct) == ["Companion Wasp is a design from your export: copy it into your Workshop to take it out."] and c.deploy.needs_field_copy(ct), c.deploy.reasons_against(ct))
	var mine := Workshop.from_card(comp)
	ck("0.9 copy in: the design comes back as it was made", mine["name"] == "Companion Wasp" and mine["chassis"] == "ch_test_threshold" and mine["abilities"][0]["text"] == d["abilities"][0]["text"] and mine["abilities"][0]["role"] == "Ranged" and mine["abilities"][0]["range"] == 4 and mine["abilities"][0]["name"] == "Stinger" and mine["id"] == null, mine)
	r.from_export.pop_back()
	# a design that no longer fits, or is gone
	var bad_d: Dictionary = ws.get_design(id)
	bad_d["abilities"][0]["text"] = "[[target enemy]] takes [[damage 2]] with [[Burst 4]]."
	ws.put(bad_d)
	c.designs_changed()
	var ht := Kit.field_team()
	ht["deck"]["Hornet"] = 1
	ck("0.9 leaving: a design that doesn't fit can't go", c.deploy.reasons_against(ht) == ["Hornet does not fit its chassis (Burst needs blueprint level 3 — you have level 1)."], c.deploy.reasons_against(ht))
	ws.remove(id)
	c.designs_changed()
	ck("0.9 leaving: nor one deleted", c.deploy.reasons_against(ht) == ["A card in its Deck is missing (Hornet)."] and r.card_named("Hornet") == null, c.deploy.reasons_against(ht))
	# ---- kept
	var id2 := ws.put(_hornet(ws))
	p.set_unlock_all(true)
	ck("0.9 save: designs and the testing switch are saved", c.save() and JSON.parse_string(FileAccess.get_file_as_string(Campaign.path))["designs"].has(id2) and JSON.parse_string(FileAccess.get_file_as_string(Campaign.path))["progress"]["all"] == true)
	var r2 := Roster.new(x)
	var c2 := Campaign.new(x, r2, x.floors(), 5)
	var back: Dictionary = c2.workshop.get_design(id2) if c2.workshop.get_design(id2) != null else {}
	ck("0.9 save: read back, they are as they were, and cards again", back.get("name") == "Hornet" and back["abilities"][0]["range"] is int and back["abilities"] == ws.get_design(id2)["abilities"] and c2.progress.unlock_all() and r2.card_named("Hornet") != null and r2.card_named("Hornet")["_design"] == id2, back)
	var f := FileAccess.open(Campaign.path, FileAccess.WRITE)
	var raw: Dictionary = c.to_dict()
	raw["designs"] = {"ds_starter": {"name": "Mine now"}, "ds_x": "junk", "ds_y": {"name": "Kept", "chassis": "ch_test_general", "abilities": []}}
	f.store_string(JSON.stringify(raw))
	f.close()
	var c3 := Campaign.new(x, Roster.new(x), x.floors(), 5)
	ck("0.9 save: a saved starter or a broken entry is passed over", c3.workshop.list().map(func(k): return k["name"]) == ["Frame Trooper", "Kept"] and str(c3.workshop.get_design("ds_starter").get("abilities", [{}])[0].get("name")) == "Carbine", c3.workshop.list().map(func(k): return k["name"]))
	Kit.fresh()


## The builder sheet's taps, one after another.
func _sheet(sh: BuilderSheet, taps: Array) -> void:
	for t in taps:
		var tap: Array = t if t is Array else ["kb", t]
		if not sh.offers().has(tap):
			ck("0.9 builder: %s is offered" % str(tap), false, [sh.title.text, sh.offers()])
		sh.act(tap)


func _nine_scene() -> void:
	Kit.fresh()
	Kit.keep([Kit.field_team(), Kit.team("Old Vanguard")])
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	var cm: Campaign = scene.campaign
	var dk: DockScreen = scene.dock_screen
	var wsn: WorkshopScreen = scene.workshop_screen
	var ed: DesignEditor = wsn.editor
	var ws: Workshop = cm.workshop
	scene.open_dock()
	await _frames(2)
	ck("0.9 dock: it has a Workshop", dk.visible and dk.shop_btn.visible and dk.shop_btn.text == "Workshop" and "research blueprints in the Workshop" in dk.help_text)
	dk.shop_btn.pressed.emit()
	await _frames(2)
	ck("0.9 workshop: it opens from the dock on your designs", wsn.visible and not dk.visible and wsn.tab == "designs" and wsn.row_texts() == ["Frame Trooper", "only the starter"] and wsn.new_btn.visible and wsn.stock_label.text == "Troop parts: none · 0 shards", [wsn.row_texts(), wsn.stock_label.text])
	ck("0.9 workshop: the starter's row says what it is and costs", _labels(wsn._rows[0]["row"]).has("Test Frame · General · power 6 of 12 · fits") and _labels(wsn._rows[0]["row"]).has("One copy: 6 Common Troop parts · you could pay for 0")
		and _labels(wsn._rows[0]["row"]).has("Starter · 4 free copies every deployment · copy it to make your own"), _labels(wsn._rows[0]["row"]))
	# ---- a new design
	wsn.new_btn.pressed.emit()
	await _frames(1)
	ck("0.9 new design: it starts by choosing a chassis, of those found", wsn.picking and wsn.row_texts() == ["Test Frame · General", "more to find"] and wsn.back_btn.text == "Back" and not wsn.new_btn.visible and "5 more chassis are still to be found." in _labels(wsn.list), wsn.row_texts())
	wsn.back_btn.pressed.emit()
	await _frames(1)
	ck("0.9 new design: Back goes back to the list", not wsn.picking and wsn.visible and wsn.back_btn.text == "Dock" and wsn.row_texts()[0] == "Frame Trooper")
	wsn.pick_chassis()
	wsn.tap_row(wsn._rows[0])
	await _frames(2)
	var nid = ed.d.get("id")
	ck("0.9 new design: choosing one opens the new design, already kept", ed.visible and ed.d["name"] == "New design" and ws.get_design(nid) != null and scene.roster.card_named("New design") != null and ed.name_label.text == "New design" and ed.rename_btn.visible and ed.delete_btn.visible, ed.d)
	ck("0.9 editor: the right side says what doesn't fit yet, and what a copy costs", _labels(ed.result).has("Power 5 / 12") and _labels(ed.result).has("Abilities 1 / 2") and _labels(ed.result).has("• Ability 1 has no text.") and _labels(ed.result).has("In all: 6 Common Troop parts"), _labels(ed.result))
	ed.act(["add", "action"])
	ed.act(["add", "passive"])
	ck("0.9 editor: Actions and Passives are added, and too many is said", ed.d["abilities"].size() == 3 and ed.d["abilities"][2]["kind"] == "passive" and ws.get_design(nid)["abilities"].size() == 3 and _labels(ed.result).any(func(l): return "3 abilities, where this chassis holds 2." in l), _labels(ed.result))
	ed.act(["remove", 2])
	ed.act(["remove", 1])
	for i in 4:
		ed.act(["num", 0, "energy", 1])
	ed.act(["num", 0, "range", 1])
	ed.act(["num", 0, "range", 1])
	ck("0.9 editor: a number steps within its chassis's maximum", ed.d["abilities"][0]["energy"] == 3 and ed.d["abilities"][0]["range"] == 5 and ws.get_design(nid)["abilities"][0]["energy"] == 3, ed.d["abilities"][0])
	ed.act(["num", 0, "energy", -1])
	ed.act(["num", 0, "energy", -1])
	# ---- the keyword builder
	ed.act(["build", 0])
	await _frames(1)
	var sh: BuilderSheet = ed.sheet
	ck("0.9 builder: + Add an effect opens it, on the first step", sh != null and sh.visible and sh.title.text == "When does it happen?" and sh.head.text == "Build an effect" and sh.offers().has(["kb", "none"]) and sh.back_btn.disabled and not sh.insert_btn.visible, sh.offers() if sh != null else null)
	_sheet(sh, ["none", "target enemy", "next", "damage"])
	ck("0.9 builder: a number is set with − and +", sh.title.text == "damage" and sh.offers().has(["step", 1]) and sh.offers().has(["kb", "pv:ok"]) and _labels(sh.list).has("1"), _labels(sh.list))
	_sheet(sh, [["step", 1], ["step", 1], "pv:ok", "next"])
	ck("0.9 builder: the review shows each part, with Change", sh.title.text == "Review the effect" and sh.insert_btn.visible and not sh.insert_btn.disabled and sh.offers().has(["edit", "effect"]) and "takes" in sh.sentence.text and "damage 3" in sh.sentence.text, [sh.title.text, sh.sentence.text])
	ck("0.9 builder: and what it is worth", sh.power.text.begins_with("This effect 3") and "with its attack" in sh.power.text, sh.power.text)
	sh.act(["kb", "insert"])
	await _frames(1)
	ck("0.9 builder: Insert puts the sentence into the ability, and it is kept", ed.sheet == null and ed.d["abilities"][0]["text"] == "[[target enemy]] takes [[damage 3]]." and ws.get_design(nid)["abilities"][0]["text"] == "[[target enemy]] takes [[damage 3]]." and _labels(ed.result).has("Fits, and you own everything it uses."), ed.d["abilities"][0])
	ed.act(["change", 0, 0])
	await _frames(1)
	ck("0.9 builder: Change opens it on the sentence as it is", ed.sheet != null and ed.sheet.title.text == "Review the effect" and "damage 3" in ed.sheet.sentence.text)
	_sheet(ed.sheet, [["edit", "effect"]])
	ed.sheet.act(["kb", "x"])
	await _frames(1)
	ck("0.9 builder: Close leaves it as it was", ed.sheet == null and ed.d["abilities"][0]["text"] == "[[target enemy]] takes [[damage 3]].")
	ed.act(["build", 0])
	_sheet(ed.sheet, ["none", "this Unit", "heal", "pv:ok", "next", "insert"])
	ck("0.9 builder: a second sentence follows the first", Keywords.sentences(ed.d["abilities"][0]["text"]) == ["[[target enemy]] takes [[damage 3]].", "[[this Unit]] gains [[heal 1]]."], ed.d["abilities"][0]["text"])
	ed.act(["cut", 0, 1])
	ck("0.9 editor: × takes a sentence out", ed.d["abilities"][0]["text"] == "[[target enemy]] takes [[damage 3]].", ed.d["abilities"][0]["text"])
	# the blueprint's level caps a number
	cm.progress.grant("ch:ch_test_threshold")
	cm.progress.grant("bp:Burst:1")
	ed.d["chassis"] = "ch_test_threshold"
	ed.save()
	ed.act(["build", 0])
	_sheet(ed.sheet, ["none", "target enemy", "next", "damage", "pv:ok", "next", "Burst"])
	for i in 6:
		ed.sheet.act(["step", 1])
	ck("0.9 builder: a number stops at what your blueprint's level allows, and says so", str(ed.sheet.b.st["param"]["value"]) == "2" and _labels(ed.sheet.list).has("Your blueprint allows up to 2."), _labels(ed.sheet.list))
	ed.sheet.act(["kb", "x"])
	await _frames(1)
	# ---- names
	ck("0.9 names: one another design has, or an export card, can't be taken; a Companion design's can", ed.name_problem("Frame Trooper") == "Another design is called Frame Trooper." and ed.name_problem("Test Drone") == "A card in your export is called Test Drone." and ed.name_problem("Lancer") == "")
	var teams := StrikeTeams.load_all()
	teams[0]["deck"]["New design"] = 2
	StrikeTeams.save_all(teams)
	ck("0.9 names: a name that can't be taken is refused, and said", not ed.rename("Test Drone") and ed.d["name"] == "New design" and ed.lock_label.text == "A card in your export is called Test Drone.")
	ck("0.9 names: renamed, Strike Teams holding it hold it under the new name", ed.rename("Lancer") and ws.get_design(nid)["name"] == "Lancer" and StrikeTeams.load_all()[0]["deck"].get("Lancer") == 2 and not StrikeTeams.load_all()[0]["deck"].has("New design") and scene.roster.card_named("Lancer") != null and scene.roster.card_named("New design") == null, StrikeTeams.load_all()[0]["deck"])
	ed.ask_name()
	ck("0.9 names: Rename asks for one", ed.namer != null and ed.namer.edit.text == "Lancer")
	ed.namer.cancelled.emit()
	# ---- its look
	var opts := ws.skins.options_for(ed.d)
	ck("0.9 look: the skins of its chassis's body plan are offered", not opts.is_empty() and ws.skins.body_plan_of(ed.d) == "Quadcopter" and _labels(ed.list).has("LOOK · QUADCOPTER"), opts.map(func(o): return o["skin"]["name"]))
	var sk: Dictionary = opts[-1]["skin"]
	ed.act(["look", sk["id"], sk["variants"][0]["id"]])
	ck("0.9 look: choosing one makes it the design's", ws.get_design(nid)["skin"] == {"skin": sk["id"], "variant": sk["variants"][0]["id"]} and ws.skins.look_of(ws.get_design(nid))["skin"] == sk["id"])
	# ---- copy and delete
	ed.copy()
	await _frames(1)
	var cid = ed.d["id"]
	ck("0.9 copy: Copy makes another, opened", cid != nid and ed.d["name"] == "Lancer copy" and ws.get_design(cid)["abilities"] == ws.get_design(nid)["abilities"] and ws.list().size() == 3)
	ed.ask_delete()
	ck("0.9 delete: Delete asks first", ed.dialog != null and ed.dialog.title_label.text == "Delete this design?")
	ed.dialog.buttons[1].pressed.emit()
	ck("0.9 delete: Keep it keeps it", ed.dialog == null and ws.get_design(cid) != null)
	ed.ask_delete()
	ed.dialog.buttons[0].pressed.emit()
	await _frames(1)
	ck("0.9 delete: Delete deletes it, back to the list", ws.get_design(cid) == null and not ed.visible and wsn.row_texts() == ["Frame Trooper", "Lancer"], wsn.row_texts())
	# ---- the starter
	wsn.tap_row(wsn._rows[0])
	await _frames(1)
	ck("0.9 starter: shown, not changed: Copy makes one that can be", ed.visible and ed.locked and not ed.rename_btn.visible and not ed.delete_btn.visible and ed.copy_btn.visible and "built-in starter" in ed.lock_label.text and not _labels(ed.list).has("Remove"))
	ed.act(["add", "action"])
	ck("0.9 starter: a tap changes nothing", ws.get_design("ds_starter")["abilities"].size() == 1 and ed.d["abilities"].size() == 1)
	ed.close()
	await _frames(1)
	# ---- blueprints, research and the testing switch
	cm.deploy.stock = _stock(0, 70)
	wsn.show_tab("blueprints")
	ck("0.9 blueprints: what you own, with research beside it", wsn.row_texts() == ["testing", "Modifier", "Burst"] and _labels(wsn._rows[2]["row"]).has("Research level 2 · 60 shards") and _labels(wsn._rows[2]["row"]).has("level 1 of 3 · up to 2 · 3 · 4"), wsn.row_texts())
	wsn.tap_row(wsn._rows[2])
	ck("0.9 research: a tap asks, saying the price", wsn.dialog != null and wsn.dialog.title_label.text == "Research Burst level 2?" and wsn.dialog.text_label.text == "It costs 60 shards; the stockpile holds 70. Level 2 allows numbers up to 3." and wsn.dialog.buttons.size() == 2, wsn.dialog.text_label.text if wsn.dialog != null else "")
	wsn.dialog.buttons[0].pressed.emit()
	await _frames(1)
	ck("0.9 research: Research spends the shards, and the level is yours, kept", cm.progress.owned("Burst") == 2 and cm.deploy.stock["shards"] == 10 and wsn.note == "Researched Burst level 2 for 60 shards." and wsn.stock_label.text == "Troop parts: none · 10 shards"
		and int(JSON.parse_string(FileAccess.get_file_as_string(Campaign.path))["progress"]["bp"]["Burst"]) == 2, wsn.note)
	wsn.tap_row(wsn._rows[2])
	ck("0.9 research: not enough shards, and it says so, with nothing to tap but OK", wsn.dialog != null and wsn.dialog.text_label.text.ends_with("That isn't enough yet.") and wsn.dialog.buttons.map(func(b): return b.text) == ["OK"])
	wsn.dialog.buttons[0].pressed.emit()
	ck("0.9 research: and OK does nothing", cm.progress.owned("Burst") == 2 and cm.deploy.stock["shards"] == 10 and wsn.dialog == null)
	wsn.tap_row(wsn._rows[0])
	ck("0.9 testing: the switch unlocks everything, kept", cm.progress.unlock_all() and wsn.note == "Testing is on: everything is unlocked, and nothing new drops." and JSON.parse_string(FileAccess.get_file_as_string(Campaign.path))["progress"]["all"] == true and _labels(wsn._rows[0]["row"]).has("Tap to turn off"))
	wsn.show_tab("designs")
	wsn.pick_chassis()
	ck("0.9 testing: every chassis can be chosen", wsn.row_texts().size() == 6 and not wsn.row_texts().has("more to find"), wsn.row_texts())
	wsn.back_btn.pressed.emit()
	wsn.show_tab("blueprints")
	wsn.tap_row(wsn._rows[0])
	ck("0.9 testing: and off again", not cm.progress.unlock_all() and wsn.note == "Testing is off.")
	# ---- from your export
	var comp := ws.to_card(_hornet(ws))
	comp["name"] = "Wasp"
	comp["_src"] = "design"
	comp["design"] = "ds_companion"
	scene.roster.from_export.append(comp)
	cm.designs_changed()
	wsn.show_tab("export")
	ck("0.9 export: the Companion's designs, the starter already yours", wsn.row_texts() == ["Frame Trooper", "Wasp"] and _labels(wsn._rows[0]["row"]).has("Copied") and _labels(wsn._rows[1]["row"]).has("Copy in") and _labels(wsn._rows[1]["row"]).has("Test Frame · Threshold Burst · a Companion design"), wsn.row_texts())
	wsn.tap_row(wsn._rows[1])
	ck("0.9 export: a tap asks before copying it in", wsn.dialog != null and wsn.dialog.title_label.text == "Copy Wasp in?" and "Its chassis and blueprints must be yours" in wsn.dialog.text_label.text)
	wsn.dialog.buttons[0].pressed.emit()
	await _frames(1)
	var wd = ws.by_name("Wasp")
	ck("0.9 export: copied in, it is yours, opened, and held to the same checks", wd != null and wd["from"] == "ds_companion" and ed.visible and ed.d["id"] == wd["id"] and scene.roster.card_named("Wasp")["_src"] == "workshop" and ws.check(wd)["ok"], ws.check(wd)["reasons"] if wd != null else null)
	ed.close()
	await _frames(1)
	wsn.show_tab("export")
	wsn.tap_row(wsn._rows[1])
	ck("0.9 export: copying it again says it comes in under a new name", "You already have a design called Wasp." in wsn.dialog.text_label.text)
	wsn.dialog.buttons[0].pressed.emit()
	await _frames(1)
	ck("0.9 export: and it does", ws.by_name("Wasp 2") != null and ed.d["name"] == "Wasp 2")
	ed.close()
	await _frames(1)
	# ---- leaving the dock with designs
	wsn.back_btn.pressed.emit()
	await _frames(1)
	ck("0.9 workshop: Dock goes back to the dock", dk.visible and not wsn.visible)
	dk.go_btn.pressed.emit()
	await _frames(1)
	ck("0.9 deploy: a team made before 0.9 needs a Field copy, and says which Troops", dk.row_texts() == ["Test Vanguard", "Old Vanguard"] and _labels(dk._rows[1]["row"]).has("Field copy needed"))
	dk.choose_team(1)
	ck("0.9 deploy: chosen, Field copy is offered", dk.field_btn.visible and dk.go_btn.disabled and dk.note.text.begins_with("Troops come only from the Workshop, and its Deck holds others (") and "Test Drone ×3" in dk.note.text and dk.note.text.ends_with("Field copy makes a copy of it that can leave."), dk.note.text)
	dk.field_btn.pressed.emit()
	await _frames(1)
	var tl := StrikeTeams.load_all()
	ck("0.9 field copy: a copy without them is made, saved and chosen, ready", tl.size() == 3 and tl[2]["name"] == "Old Vanguard · field" and tl[2]["deck"].get("Frame Trooper") == 4 and not tl[2]["deck"].has("Test Drone") and dk.team_i == 2 and not dk.go_btn.disabled and not dk.field_btn.visible
		and _labels(dk._rows[2]["row"]).has("Ready") and tl[1]["deck"].has("Test Drone"), [dk.row_texts(), dk.note.text])
	# a design and its price
	tl[0]["deck"]["Lancer"] = 2
	tl[0]["deck"]["Frame Trooper"] = 5
	StrikeTeams.save_all(tl)
	var each: int = ws.cost(ws.by_name("Lancer"))["parts"][0]
	cm.deploy.stock = _stock(6, 10)
	dk.show_teams()
	dk.choose_team(0)
	ck("0.9 deploy: copies that can't be paid for keep it at the dock", dk.go_btn.disabled and dk.note.text == "The stockpile can't pay for its copies: they cost %d Common, and it holds 6 Common." % (6 + 2 * each), dk.note.text)
	cm.deploy.stock = _stock(100, 10)
	dk.show_teams()
	dk.choose_team(0)
	ck("0.9 deploy: those that can are priced before it leaves", not dk.go_btn.disabled and dk.note.text == "Test Vanguard is ready to leave. Its copies: 5 × Frame Trooper: 6 Common (4 free) · 2 × Lancer: %d Common." % (2 * each), dk.note.text)
	dk.go_btn.pressed.emit()
	await _frames(3)
	ck("0.9 deploy: leaving pays", cm.deploy.active() and cm.deploy.stock == _stock(100 - 6 - 2 * each, 10), cm.deploy.stock)
	# ---- the Workshop while it is out
	scene.open_dock()
	await _frames(1)
	dk.shop_btn.pressed.emit()
	await _frames(1)
	var lrow: Control = wsn._rows[wsn.row_texts().find("Lancer")]["row"]
	ck("0.9 out: the Workshop can be looked at, its designs that are out marked", wsn.visible and _labels(lrow).has("Out") and "locked until it is home" in wsn.hint.text)
	wsn.tap_row(wsn._rows[wsn.row_texts().find("Lancer")])
	await _frames(1)
	ck("0.9 out: a design out is shown, not changed", ed.visible and ed.locked and "Out on a deployment" in ed.lock_label.text and not ed.rename_btn.visible and not ed.delete_btn.visible)
	var before: Dictionary = ws.by_name("Lancer").duplicate(true)
	ed.act(["add", "action"])
	ed.act(["num", 0, "energy", 1])
	ck("0.9 out: taps change nothing", ws.by_name("Lancer")["abilities"] == before["abilities"] and ed.d["abilities"] == before["abilities"])
	ed.close()
	await _frames(1)
	wsn.show_tab("blueprints")
	ck("0.9 out: research waits", "Research waits while a Strike Team is out." in wsn.hint.text and _labels(wsn._rows[2]["row"]).has("At the dock"), _labels(wsn._rows[2]["row"]))
	wsn.ask_research("Burst")
	ck("0.9 out: and asking says so", wsn.dialog != null and "Research waits until the Strike Team is home." in wsn.dialog.text_label.text and wsn.dialog.buttons.size() == 1)
	wsn.dialog.buttons[0].pressed.emit()
	scene.queue_free()
	await _frames(2)
	Kit.fresh()


# ---------------------------------------------------------------- 0.10: the dock
func _ten() -> void:
	Kit.fresh()
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)
	var c := Campaign.new(x, r, x.floors(), 7)
	var dk := c.dock
	var dep := c.deploy
	var ws := c.workshop
	var w := c.world
	# ---- a new campaign
	ck("0.10 dock: a new campaign's starts with nothing: no reach, no upgrades, nothing kept, no bounties, nothing on the shelves yet", dk.state["reach"] == 0 and Dock.UPGRADES.all(func(u): return dk.level(u["id"]) == 0)
		and dk.inv == {"cards": {}, "pre": {}} and dk.bounties().is_empty() and dk.state["stock"] == null and dk.reach_rarity() == 0 and dk.starter_free() == 4 and dk.scan_range() == 1, dk.state)
	ck("0.10 dock: it reads the export's tables", dk.tables["price"] == [6, 15, 40, 100, 250, 600] and dk.tables["preMult"] == 1.5 and dk.tables["effect"]["scanner"] == [2, 3, 4] and dk.tables["cost"]["starter"][0] == [150, "troop", 0, 10], dk.tables)
	# ---- the Exchange
	var all_items: Array = r.from_export.filter(func(k): return ["consumable", "prototype"].has(Roster.type_of(k))).map(func(k): return str(k["name"]))
	ck("0.10 exchange: with none ticked in the export, it carries every Consumable and Prototype, at 20 shards each (0.24: Quartermaster's Seal withdrawn)", dk.carries_all() and dk.items().map(func(i): return i["name"]) == all_items and dk.items().all(func(i): return i["price"] == 20) and all_items.size() == 26 and all_items.has("Grav-Boot Charge") and all_items.has("Gantry Mapper"), dk.items().size())
	dk.fallback_items = false
	ck("0.10 exchange: (the Companion's own carries none then)", dk.items().is_empty() and not dk.carries_all())
	dk.fallback_items = true
	var st := dk.stock()
	ck("0.10 exchange: the first stock is laid out when it is first looked at: three of them, three of the four pre-built Troops (0.22: two on the Skitter Frame), no lot past your reach, nothing from Districts not fought in",
		st["n"] == 1 and dk.state["restocks"] == 1 and st["items"].size() == 3 and st["pre"].size() == 3 and st["lots"].is_empty() and st["bps"].is_empty() and st["chs"].is_empty(), st)
	ck("0.10 exchange: and it stays until it restocks", dk.stock() == st and dk.state["restocks"] == 1)
	dep.stock = _stock(0, 100)
	var nm: String = st["items"][0]
	var o := dk.buy_card(nm, 2)
	ck("0.10 exchange: bought, it is yours, kept at the dock, and the shards are spent", o["ok"] and o["price"] == 40 and dk.owned(nm) == 2 and dep.stock["shards"] == 60, [o, dep.stock["shards"]])
	o = dk.buy_card(nm, 4)
	ck("0.10 exchange: not enough shards: nothing changes, and it says so", not o["ok"] and o["why"] == "Needs 80 shards; you have 60" and dk.owned(nm) == 2 and dep.stock["shards"] == 60, o)
	var off: String = all_items.filter(func(n): return not st["items"].has(n))[0]
	ck("0.10 exchange: one not on the shelf can't be bought", dk.buy_card(off, 1)["why"] == "Not in stock" and dk.owned(off) == 0)
	o = dk.sell_card(nm, 1)
	ck("0.10 exchange: sold back at half its price", o["ok"] and o["gain"] == 10 and dk.owned(nm) == 1 and dep.stock["shards"] == 70 and dk.sell_card(nm, 2)["why"] == "You don't have that many", o)
	o = dk.buy_parts("equipment", 0, 5)
	ck("0.10 exchange: Commons of any part type, any amount", o["ok"] and o["price"] == 30 and dep.stock["parts"]["equipment"][0] == 5 and dep.stock["shards"] == 40 and dk.buy_parts("equipment", 1, 1)["why"] == "Not in stock", o)
	dk.sell_parts("equipment", 0, 5)
	# ---- pre-built Troops
	var pid: String = st["pre"][0]
	var pd: Dictionary = ws.get_design(pid)
	ck("0.10 pre-built: the export's pre-built Troops are kept apart from your designs, and aren't yours to change", pd["prebuilt"] and pd["name"] == "Hornet Mk I" and not ws.list().any(func(k): return k["id"] == pid) and ws.prebuilts().size() == 4
		and r.card_named("Hornet Mk I") != null and r.card_named("Hornet Mk I")["_src"] == "prebuilt", ws.list().map(func(k): return k["name"]))
	var sh := 0.0
	for i in 6:
		sh += float(ws.cost(pd)["parts"][i]) * float(dk.tables["price"][i])
	var each_pre := dk.pre_cost(pd)
	dep.stock = _stock(0, each_pre * 2 + 5)
	o = dk.buy_pre(pid, 2)
	ck("0.10 pre-built: a copy costs the parts of one, priced in shards, half again; bought, the copies wait for the next deployment", each_pre == maxi(1, int(Rules.js_round(sh * 1.5))) and o["ok"] and o["price"] == each_pre * 2 and dk.waiting() == {pid: 2} and dep.stock["shards"] == 5, [o, each_pre])
	var tp := Kit.field_team("Pre")
	tp["deck"]["Hornet Mk I"] = 1
	ck("0.10 pre-built: one in a team's Deck can't go: its copies are bought", dep.reasons_against(tp) == ["Hornet Mk I is a pre-built Troop: its copies are bought at the Exchange, and join the next deployment."] and dep.needs_field_copy(tp) and not dep.field_copy(tp, "F")["deck"].has("Hornet Mk I"), dep.reasons_against(tp))
	# ---- the Bounty Board
	var foe: Dictionary = dk.foes().filter(func(k): return k["cardType"] == "enemy")[0]
	ck("0.10 bounties: an Enemy not met is never on the board", dk.post_bounties().is_empty())
	c.progress.see("enemy", foe["name"])
	c.progress.see("district", Progress.enemy_district(foe))
	dk.restock_now()
	ck("0.10 bounties: one met, in a District fought in, is, when the Exchange restocks", dk.wanted() == [foe["name"]] and dk.bounties()[0]["kind"] == "enemy" and not dk.bounties()[0]["claimed"] and dk.stock()["n"] == 2 and dk.state["log"][0]["text"] == "The Exchange restocked; the Bounty Board changed.", dk.bounties())
	st = dk.stock()
	# ---- the Pack
	var t := Kit.field_team()
	dk.inv["cards"] = {"Test Stim": 1, "Test Aegis Core": 1, "Test Smoke": 3}
	ck("0.10 pack: a team packs what its own lists ask for, as far as the dock holds it", dep.default_pack(t) == {"Test Stim": 1, "Test Aegis Core": 1}, dep.default_pack(t))
	var pk := {"Test Stim": 1, "Test Aegis Core": 1, "Test Smoke": 4}
	ck("0.10 pack: more than the dock holds can't go, and it says so", dep.reasons_against(t, pk) == ["Only 3 Test Smoke to pack."] and not dep.start(t, pk)["ok"] and not dep.active() and dk.owned("Test Smoke") == 3, dep.reasons_against(t, pk))
	pk["Test Smoke"] = 2
	var pl := dep.plan(t, pk)
	ck("0.10 deploy: the plan has the pre-built copies going too, and what is packed", pl["pre"] == [{"id": pid, "name": "Hornet Mk I", "copies": 2}] and pl["packed"].map(func(p): return [p["name"], p["n"], p["kind"]]) == [["Test Stim", 1, "consumable"], ["Test Aegis Core", 1, "prototype"], ["Test Smoke", 2, "consumable"]], pl["packed"])
	var go := dep.start(t, pk)
	var cur: Dictionary = dep.cur() if dep.active() else {}
	ck("0.10 deploy: it leaves with what was packed, taken from the dock, and the pre-built copies", go["ok"] and cur["pack"]["cons"] == {"Test Stim": 1, "Test Smoke": 2} and cur["pack"]["protos"] == {"Test Aegis Core": 1} and dk.inv["cards"] == {"Test Smoke": 1} and dk.waiting().is_empty() and cur["pre"] == {pid: 2}, cur.get("pack"))
	var now: Dictionary = dep.team_now()
	ck("0.10 out: the pre-built copies ride on top of its Deck, and what was packed is its Consumables and Prototypes", now["deck"].get("Hornet Mk I") == 2 and dep.copies_left("Hornet Mk I") == 2 and now["consumables"] == {"Test Stim": 1, "Test Smoke": 2} and now["protos"] == ["Test Aegis Core"], now)
	ck("0.10 out: the dock is closed: nothing bought, sold, reclaimed or upgraded", dk.closed() and dk.buy_card(st["items"][0], 1)["why"] == Dock.CLOSED and dk.sell_card("Test Smoke", 1)["why"] == Dock.CLOSED and dk.upgrade("scanner")["why"] == Dock.CLOSED
		and dk.buy_pre(pid, 1)["why"] == Dock.CLOSED and dk.combine("troop", 0, 1)["why"] == Dock.CLOSED and dk.buy_parts("troop", 0, 1)["why"] == Dock.CLOSED)
	w.tables["ambushStep"] = 100
	var k1: String = World.neighbours(w.dock()).filter(func(k): return w.is_open(k) and w.content_at(k) == null)[0]
	dep.step_to(k1)
	dep.ambush(k1, {})
	dep.fight_over({"winner": "ally", "haul": _stock(0, 10), "reward": Loot.bag(), "items": [], "heroesDown": [], "troopsLost": ["Hornet Mk I"], "consUsed": ["Test Smoke"], "kills": [{"name": foe["name"], "skull": 2}]})
	ck("0.10 out: a pre-built copy falls like any other, a Consumable used is gone, and what was brought down is counted", dep.copies_left("Hornet Mk I") == 1 and dep.cur()["pack"]["cons"] == {"Test Stim": 1, "Test Smoke": 1} and dep.cur()["kills"] == [{"name": foe["name"], "skull": 2}], dep.cur()["pack"])
	w.tables["ambushStep"] = 0
	dep.step_to(w.dock())
	var stock_was: Dictionary = dep.stock.duplicate(true)
	var h := dep.home()
	var paid: Array = h["dock"].get("bounties", [])
	ck("0.10 home: the bounty pays 15 shards a Skull Level and a component, into the stockpile", paid.size() == 1 and paid[0]["name"] == foe["name"] and paid[0]["bag"]["shards"] == 30 and Loot.count(paid[0]["bag"]) == 1
		and dep.stock == Loot.add(Loot.add(stock_was, _stock(0, 10)), paid[0]["bag"]), paid)
	ck("0.10 home: what was packed and not used is back at the dock; the pre-built copies are gone", dk.inv["cards"] == {"Test Smoke": 2, "Test Stim": 1, "Test Aegis Core": 1} and dk.waiting().is_empty(), dk.inv)
	ck("0.10 home: the reach is the furthest Skull Level it came home from, and new ground restocks the Exchange", h["dock"].get("reach") == w.skull_of(k1) and dk.state["reach"] == w.skull_of(k1) and h["dock"].get("restocked") == true and dk.stock()["n"] == 3, h["dock"])
	var lines := c.end_lines(h, false)
	ck("0.10 home: and the dock says it all", lines.has("Back to the dock, unused: Test Stim, Test Smoke, Test Aegis Core.") and lines.has("Bounty on %s paid: %s." % [foe["name"], c.loot.text(paid[0]["bag"])]) and lines.has("The Exchange has restocked, and the Bounty Board has changed."), lines)
	# ---- upgrades
	dep.stock = Loot.bag()
	ck("0.10 upgrades: one that can't be paid for isn't, and says what it needs", dk.upgrade("starter")["why"] == "Needs 150 shards and 10 Common troop parts" and dk.level("starter") == 0)
	var big := Loot.bag()
	big["shards"] = 1000
	for ty in ["troop", "equipment", "aether"]:
		big["parts"][ty][0] = 30
	dep.stock = big
	var u1 := dk.upgrade("starter")
	ck("0.10 upgrades: the Starter bay, paid for, frees 6 starter copies, not 4", u1["ok"] and u1["level"] == 1 and dk.starter_free() == 6 and dep.starter_free() == 6 and dep.stock["shards"] == 850 and dep.stock["parts"]["troop"][0] == 20, dep.stock)
	t["deck"]["Frame Trooper"] = 6
	ck("0.10 upgrades: and a team's first 6 Frame Troopers go free", dep.plan(t)["lines"][0]["free"] == 6 and dep.plan(t)["parts"] == _parts(0), dep.plan(t)["lines"])
	dk.upgrade("insurance")
	dk.upgrade("scanner")
	ck("0.10 upgrades: insurance keeps 10% of a wiped haul; the scanner sees 2 steps away; each raised one level, its next level dearer", dk.insurance() == 10 and dk.scan_range() == 2 and dk.level("scanner") == 1 and dk.next_cost("scanner") == {"shards": 400, "type": "equipment", "rarity": 1, "n": 6})
	for i in 2:
		dk.state["upgrades"]["scanner"] += 1
	ck("0.10 upgrades: three levels and no more", dk.upgrade("scanner")["why"] == "Already at its highest level" and dk.next_cost("scanner") == null)
	dk.state["upgrades"]["scanner"] = 1
	# ---- a wipe, insured
	var far: Array = w.map["tiles"].keys().filter(func(k): return World.dist(k, w.dock()) == 2 and w.is_open(k) and not w.known(k))
	var t2 := Kit.field_team("Second")
	var inv_was: Dictionary = dk.inv.duplicate(true)
	dep.start(t2, {"Test Stim": 1})
	ck("0.10 upgrades: the scanner shows the team what lies 2 steps away", not far.is_empty() and far.all(func(k): return w.known(k)), far)
	var inv_out: Dictionary = dk.inv.duplicate(true)
	w.tables["ambushStep"] = 100
	dep.step_to(k1)
	dep.ambush(k1, {})
	var loot_bag := _stock(7, 55)
	dep.fight_over({"winner": "ally", "haul": loot_bag, "reward": Loot.bag(), "items": [], "heroesDown": [], "troopsLost": [], "consUsed": [], "kills": [{"name": foe["name"], "skull": 1}]})
	w.tables["ambushStep"] = 0
	stock_was = dep.stock.duplicate(true)
	var wp := dep.wipe()
	var kept := _stock(0, 5)
	ck("0.10 wipe: insurance keeps its share of the haul, rounded down; the bounty isn't paid; what was packed is lost", wp["dock"].get("insured") == kept and dep.stock == Loot.add(stock_was, kept) and not wp["dock"].has("bounties") and dk.inv == inv_out
		and inv_out["cards"].get("Test Stim", 0) == inv_was["cards"]["Test Stim"] - 1 and wp["lostPack"]["cons"] == {"Test Stim": 1}, [wp["dock"], dk.inv])
	ck("0.10 wipe: and the dock says so", c.end_lines(wp, true).has("Lost with it, as packed: Test Stim.") and c.end_lines(wp, true).has("Salvage insurance kept 5 shards."), c.end_lines(wp, true))
	# ---- kept
	ck("0.10 save: the dock and what it keeps are saved", c.save() and JSON.parse_string(FileAccess.get_file_as_string(Campaign.path)).has("dock") and JSON.parse_string(FileAccess.get_file_as_string(Campaign.path)).has("inventory"))
	var c2 := Campaign.new(x, Roster.new(x), x.floors(), 7)
	ck("0.10 save: read back, they are as they were", JSON.stringify(c2.dock.state) == JSON.stringify(Rules.ints(JSON.parse_string(JSON.stringify(dk.state)))) and c2.dock.inv == dk.inv and c2.dock.level("scanner") == 1 and c2.dock.wanted() == dk.wanted() and c2.note == "", [c2.dock.inv, dk.inv])
	var raw: Dictionary = c.to_dict()
	raw.erase("dock")
	raw.erase("inventory")
	var f := FileAccess.open(Campaign.path, FileAccess.WRITE)
	f.store_string(JSON.stringify(raw))
	f.close()
	var c3 := Campaign.new(x, Roster.new(x), x.floors(), 7)
	ck("0.10 save: one saved before 0.10 starts the dock afresh, the rest as it was", c3.dock.state["reach"] == 0 and c3.dock.inv == {"cards": {}, "pre": {}} and c3.dock.state["stock"] == null and c3.deploy.history.size() == 2 and c3.note == "", c3.dock.state)
	raw["dock"] = "junk"
	raw["inventory"] = [1, 2]
	f = FileAccess.open(Campaign.path, FileAccess.WRITE)
	f.store_string(JSON.stringify(raw))
	f.close()
	var c4 := Campaign.new(x, Roster.new(x), x.floors(), 7)
	ck("0.10 save: a broken one too", c4.dock.state == Dock.blank() and c4.dock.inv == {"cards": {}, "pre": {}}, c4.dock.state)
	# ---- testing, and starting over
	dk.reach_up()
	ck("0.10 testing: Reach +1", dk.state["reach"] == mini(6, w.skull_of(k1) + 1) and dk.state["log"][0]["text"] == "Reach set to Skull Level %d (testing)." % dk.state["reach"])
	var n0: int = dk.state["restocks"]
	dk.restock_now()
	ck("0.10 testing: Restock now", dk.state["restocks"] == n0 + 1 and dk.stock()["n"] == n0 + 1)
	var sh_left: int = dep.stock["shards"]
	dk.reset()
	ck("0.10 testing: Reset the dock forgets the dock, and the stockpile stays", dk.state["reach"] == 0 and dk.level("insurance") == 0 and dk.inv == {"cards": {}, "pre": {}} and dk.state["stock"] == null and dep.stock["shards"] == sh_left)
	dk.upgrade("scanner")
	c.reset()
	ck("0.10 start over: a new campaign's dock has nothing", dk.state == Dock.blank() and dk.inv == {"cards": {}, "pre": {}})
	Kit.fresh()


## The control under a node that a tap with this meaning lands on.
func _chip_of(n: Node, what: Array) -> Control:
	var todo: Array = [n]
	while not todo.is_empty():
		var k = todo.pop_front()
		if k is Control and k.has_meta("act") and k.get_meta("act") == what and k.is_visible_in_tree():
			return k
		todo.append_array(k.get_children())
	return null


func _ten_scene() -> void:
	Kit.fresh()
	Kit.keep([Kit.field_team()])
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	var cm: Campaign = scene.campaign
	var ms: MapScreen = scene.map_screen
	var dk: DockScreen = scene.dock_screen
	var dock: Dock = cm.dock
	cm.loot.seed_with(31)
	scene.home.world_btn.pressed.emit()
	await _frames(2)
	ck("0.10 dock: five tabs, the Stockpile first", dk.visible and dk.tab == "stockpile" and dk.tabs.keys() == ["stockpile", "exchange", "reclaim", "bounties", "upgrades"] and dk.tabs["stockpile"].button_pressed and dk.tab_row.visible
		and dk.map_btn.visible and dk.shop_btn.visible and dk.go_btn.text == "Deploy", dk.tabs.keys())
	ck("0.10 dock: the Stockpile ends with a Testing row: Restock now, Reach +1, Reset the dock", dk.row_texts()[-1] == "Testing" and dk.offers() == [["testing", "restock"], ["testing", "reach"], ["testing", "reset"]], dk.offers())
	# ---- the Exchange
	var gift := Loot.bag()
	gift["shards"] = 300
	dock.add_to_stockpile(gift)
	dk.tabs["exchange"].pressed.emit()
	await _frames(2)
	ck("0.10 exchange: its tab shows what it sells, and the shards you hold", dk.tab == "exchange" and dk.tabs["exchange"].button_pressed and not dk.tabs["stockpile"].button_pressed
		and dk.hint.text.begins_with("Everything is paid in Aether shards; you hold 300. Your reach is none yet, so the rarest component the Exchange deals in is Common.") and dk.row_texts().has("Components")
		and dk.row_texts().has("Consumables and Prototypes") and dk.row_texts().has("Pre-built Troops") and dk.row_texts().has("Troop parts"), [dk.hint.text, dk.row_texts()])
	var cons_head: Control = dk._rows[dk.row_texts().find("Consumables and Prototypes")]["row"]
	ck("0.10 exchange: with none ticked in the export it carries them all, at 20 shards, and says so (behind the \"?\")", cons_head != null and "Consumables and Prototypes: Your export ticks none for the Exchange, so it carries all of them, at 20 shards each" in dk.help_text, dk.help_text)
	var nm: String = dock.stock()["items"][0] if not dock.stock()["items"].is_empty() else "Field Dressing"
	var i_row: int = dk.row_texts().find(nm)
	ck("0.10 exchange: each on offer is a tile: what it is, how many you own, its price in gold, and Buy", i_row >= 0 and dk._rows[i_row].get("tile", false) and _labels(dk._rows[i_row]["row"]).has("%s · you own 0" % ("Prototype" if dock.item_kind(nm) == "prototype" else "Consumable")) and _labels(dk._rows[i_row]["row"]).has("20")
		and dk._rows[i_row]["acts"] == [["buy_card", nm, 1]] and _first_icon(dk._rows[i_row]["row"], "shards") != null, _labels(dk._rows[i_row]["row"]) if i_row >= 0 else dk.row_texts())
	dk.act(["buy_card", nm, 1])
	ck("0.10 exchange: Buy 1 buys one, says so, and offers to sell it back", dock.owned(nm) == 1 and dock.stockpile()["shards"] == 280 and dk.note.text == "Bought %s for 20 shards: it's kept here." % nm and dk.tab == "exchange" and dk.row_texts().has("Sell") and dk.row_texts().has("1 × %s" % nm), dk.note.text)
	var saved10 = JSON.parse_string(FileAccess.get_file_as_string(Campaign.path)) if FileAccess.file_exists(Campaign.path) else null
	ck("0.10 exchange: and it is saved", saved10 is Dictionary and int(saved10["inventory"]["cards"].get(nm, 0)) == 1)
	await _frames(1)
	var chip := _chip_of(dk.list, ["buy_parts", "troop", 0, 1])
	var had_chip := chip != null
	if had_chip:
		dk.list.tap(chip.global_position - dk.list.global_position + chip.size / 2)
	await _frames(1)
	ck("0.10 exchange: a tap on a row's Buy 1 buys a Common part", had_chip and cm.deploy.stock["parts"]["troop"][0] == 1 and dock.stockpile()["shards"] == 274 and dk.note.text == "Bought 1 Scrap servos for 6 shards.", [dk.note.text, cm.deploy.stock, dock.stockpile()["shards"]])
	dk.act(["buy_card", "Nothing of the sort", 1])
	ck("0.10 exchange: what can't be done is said", dk.note.text == "Not in stock." and dock.stockpile()["shards"] == 274, dk.note.text)
	var pid: String = dock.stock()["pre"][0]
	var pdn: String = cm.workshop.get_design(pid)["name"]
	var pcost: int = dock.pre_cost(cm.workshop.get_design(pid))
	var prow: Control = dk._rows[dk.row_texts().find(pdn)]["row"]
	ck("0.10 exchange: a pre-built Troop says its chassis, its power and how many wait", _labels(prow).any(func(l): return l.ends_with("· 0 waiting for the next deployment")) and _labels(prow).has("Buy a copy") and _labels(prow).has(str(pcost)), _labels(prow))
	gift["shards"] = pcost * 2
	dock.add_to_stockpile(gift)
	dk.act(["buy_pre", pid, 1])
	dk.act(["buy_pre", pid, 1])
	ck("0.10 exchange: Buy a copy buys one for the next deployment", dock.waiting() == {pid: 2} and dock.stockpile()["shards"] == 274 and dk.note.text == "Bought a copy for %d shards: it joins the next deployment." % pcost, dk.note.text)
	dk.show_tab("stockpile")
	var rows := dk.row_texts()
	ck("0.10 stockpile: what the dock keeps for you is listed under the stockpile", rows.has("Also kept here") and rows.has("1 × %s" % nm) and rows.has("2 × %s" % pdn) and _labels(dk._rows[rows.find("2 × %s" % pdn)]["row"]).has("Pre-built copies · they join the next deployment"), rows)
	# ---- Reclaiming
	dk.show_tab("reclaim")
	ck("0.10 reclaim: one part isn't enough to do anything with", dk.row_texts() == ["1 × Scrap servos"] and dk.offers().is_empty() and "never rarer than your reach (Common)" in dk.hint.text, [dk.row_texts(), dk.offers()])
	dock.state["reach"] = 2
	var parts := Loot.bag()
	parts["parts"]["troop"][0] = 5
	dock.add_to_stockpile(parts)
	dk.show_tab("reclaim")
	ck("0.10 reclaim: with enough, and the reach for it, Combine and Swap are offered", dk.row_texts() == ["6 × Scrap servos"] and dk.offers() == [["combine", "troop", 0], ["swap", "troop", "equipment", 0], ["swap", "troop", "aether", 0]]
		and _labels(dk._rows[0]["row"]).has("3 into 1 Uncommon") and _labels(dk._rows[0]["row"]).has("2 into 1 Aether"), dk.offers())
	dk.act(["combine", "troop", 0])
	dk.act(["swap", "troop", "aether", 0])
	ck("0.10 reclaim: three make one of the next rarity; two make one of another type", cm.deploy.stock["parts"]["troop"] == [1, 1, 0, 0, 0, 0] and cm.deploy.stock["parts"]["aether"][0] == 1 and dk.note.text == "Swapped: 1 aether part made." and dk.row_texts().size() == 3, [cm.deploy.stock["parts"], dk.row_texts()])
	# ---- upgrades
	dk.show_tab("upgrades")
	var srow: Control = dk._rows[1]["row"]
	ck("0.10 upgrades: four, each at level 0 of 3, with what it does and what the next level costs", dk.row_texts() == ["Exchange stock · level 0 of 3", "Starter bay · level 0 of 3", "Salvage insurance · level 0 of 3", "Long-range scanner · level 0 of 3"]
		and _labels(srow).has("Level 1 · 150 shards, 10 Common Troop parts") and _labels(srow).any(func(l): return "Now: 4 free starter copies. Next: 6 free starter copies." in l), _labels(srow))
	dk.act(["upgrade", "starter"])
	ck("0.10 upgrades: one not paid for says what it needs", dk.note.text == "Needs 150 shards and 10 Common troop parts." and dock.level("starter") == 0, dk.note.text)
	parts["parts"]["troop"][0] = 9
	dock.add_to_stockpile(parts)
	dk.act(["upgrade", "starter"])
	srow = dk._rows[1]["row"]
	ck("0.10 upgrades: paid for, it is raised, and says what it does now", dock.level("starter") == 1 and dk.note.text == "Upgraded to level 1." and dk.row_texts()[1] == "Starter bay · level 1 of 3" and _labels(srow).has("Level 2 · 400 shards, 6 Uncommon Troop parts")
		and _labels(srow).any(func(l): return "Now: 6 free starter copies. Next: 8 free starter copies." in l) and dock.stockpile()["shards"] == 124, [dk.note.text, _labels(srow)])
	# ---- testing
	dk.show_tab("stockpile")
	var n0: int = dock.state["restocks"]
	dk.act(["testing", "restock"])
	ck("0.10 testing: Restock now asks first", dk.dialog != null and dk.dialog.title_label.text == "Restock now?" and dk.dialog.buttons.map(func(b): return b.text) == ["Yes", "Not now"])
	if dk.dialog != null:
		dk.dialog.buttons[1].pressed.emit()
	ck("0.10 testing: Not now leaves it", dk.dialog == null and dock.state["restocks"] == n0)
	dk.act(["testing", "restock"])
	if dk.dialog != null:
		dk.dialog.buttons[0].pressed.emit()
	ck("0.10 testing: Yes restocks", dock.state["restocks"] == n0 + 1 and dk.note.text == "The Exchange restocked; the Bounty Board changed.", dk.note.text)
	dk.act(["testing", "reach"])
	if dk.dialog != null:
		dk.dialog.buttons[0].pressed.emit()
	ck("0.10 testing: Reach +1", dock.state["reach"] == 3 and dk.note.text == "Your reach is Skull Level 3.", dk.note.text)
	# ---- the Bounty Board (one that wants every Enemy, so that whatever is met is wanted)
	dk.show_tab("bounties")
	ck("0.10 bounties: an empty board says how one comes", dk.row_texts() == ["No bounties posted yet."], dk.row_texts())
	dock.state["bounties"] = dock.foes().map(func(k): return {"name": k["name"], "kind": k["cardType"], "district": Progress.enemy_district(k), "claimed": false})
	dk.show_tab("bounties")
	var at := -1
	for i in dock.bounties().size():
		if dock.bounties()[i]["kind"] == "enemy" and dock.bounties()[i]["district"] != "" and at < 0:
			at = i
	ck("0.10 bounties: each says what it is, where, and what it pays", at >= 0 and dk.row_texts() == dock.bounties().map(func(b): return b["name"])
		and _labels(dk._rows[at]["row"]).has("Enemy · District %s · pays 15 shards per Skull Level, and 1 component" % dock.bounties()[at]["district"]), _labels(dk._rows[maxi(at, 0)]["row"]))
	# ---- the Pack
	dock.add_card("Test Stim", 3)
	dk.go_btn.pressed.emit()
	await _frames(1)
	dk.choose_team(0)
	ck("0.10 pack: a chosen team packs what its lists ask for, as far as the dock holds it, and the Pack lists all the dock keeps", dk.pack.get("Test Stim") == 2 and dk.row_texts().has("Pack") and dk.row_texts().has("Test Stim") and dk.row_texts().has(nm)
		and _labels(dk._rows[dk.row_texts().find("Test Stim")]["row"]).has("Consumable · 2 of 3 packed"), [dk.pack, dk.row_texts()])
	dk.act(["pack", "Test Stim", 1])
	dk.act(["pack", "Test Stim", 1])
	ck("0.10 pack: + packs one more, as far as there are", dk.pack.get("Test Stim") == 3 and dk._rows[dk.row_texts().find("Test Stim")]["acts"] == [["pack", "Test Stim", -1]], dk.pack)
	dk.act(["pack", nm, 1])
	dk.act(["pack", nm, -1])
	ck("0.10 pack: − takes one out", not dk.pack.has(nm), dk.pack)
	ck("0.10 deploy: the ready note says the pre-built copies and what is packed", dk.note.text.begins_with("Test Vanguard is ready to leave. Its copies: 3 × Frame Trooper, free · 2 × %s, pre-built. Packed: " % pdn) and "3 × Test Stim" in dk.note.text, dk.note.text)
	dk.go_btn.pressed.emit()
	await _frames(3)
	ck("0.10 deploy: it leaves with the Pack, taken from what the dock keeps, and the pre-built copies", cm.deploy.active() and dock.owned("Test Stim") == 0 and dock.owned(nm) == 1 and cm.deploy.cur()["pack"]["cons"].get("Test Stim") == 3 and dock.waiting().is_empty() and ms.visible, cm.deploy.cur()["pack"])
	ms.show_team()
	var box: String = ms.dialog.text_label.text if ms.dialog != null else ""
	ck("0.10 map: the Team box lists the pre-built copies and the Bounty Board", "Pre-built copies: 2 × %s." % pdn in box and "Bounty Board: " in box and not "(beaten" in box, box)
	ms.dialog.buttons[0].pressed.emit()
	scene.open_dock()
	await _frames(1)
	ck("0.10 out: the dock can be looked at, and says it is closed", dk.visible and dk.go_btn.text == "Back to the team" and not dk.map_btn.visible and "The dock is closed to changes while it is out." in dk.hint.text, dk.hint.text)
	dk.show_tab("exchange")
	dk.act(["buy_card", dock.stock()["items"][0], 1])
	ck("0.10 out: and buys nothing", dk.note.text == "The dock is closed while a Strike Team is out." and "you can look, and buy or sell when it is home" in dk.hint.text, dk.note.text)
	dk.go_btn.pressed.emit()
	await _frames(2)
	# ---- a fight with what the board wants
	cm.world.tables["ambushStep"] = 100
	var next_tile: String = World.neighbours("0,0").filter(func(k): return cm.world.is_open(k) and cm.world.content_at(k) == null)[0]
	await ms.walk(next_tile)
	await _frames(2)
	ms.do("fight")
	await _frames(2)
	var s: SetupScreen = scene.setup
	s._go(1)
	await _frames(1)
	s.next_btn.pressed.emit()
	await _frames(4)
	var bt: Battle = scene.battle
	var foes_in: Array = bt.side_units("enemy") if bt != null else []
	ck("0.10 fight: the Enemies the Bounty Board wants wear its tag", bt != null and bt.deploy["bounties"] == dock.wanted() and not foes_in.is_empty() and foes_in.all(func(u): return Rules.truthy(u.get("bounty"))), foes_in.map(func(u): return [u["name"], u.get("bounty")]))
	ck("0.10 fight: the pre-built copies came with the team, on top of its Deck", cm.deploy.team_now()["deck"].get(pdn) == 2 and cm.deploy.copies_left(pdn) == 2, cm.deploy.team_now()["deck"])
	if not foes_in.is_empty():
		scene.select(foes_in[0])
		await _frames(1)
		ck("0.10 fight: the panel says so", scene.panel.side_label.text.ends_with("· Bounty"), scene.panel.side_label.text)
		var who := str(foes_in[0]["src"] if Rules.truthy(foes_in[0].get("src")) else foes_in[0]["name"])
		foes_in[0]["hp"] = 0
		bt.check_downs()
		ck("0.10 fight: one brought down is told in the Log: it pays at home", bt.log.any(func(l): return l["text"] == "Bounty: %s is down. It pays once the team is home." % who and l.get("bounty") == true), _texts(bt).slice(-4))
	await _end_fight(scene, true)
	if scene.dialog != null:
		scene.dialog.buttons[0].pressed.emit()
	await _frames(3)
	var beaten: Array = cm.deploy.cur()["kills"].map(func(k): return str(k["name"]))
	ms.show_team()
	box = ms.dialog.text_label.text if ms.dialog != null else ""
	ck("0.10 map: a bounty beaten says it pays at home", ms.visible and not beaten.is_empty() and ("%s (beaten: it pays at home)" % beaten[0]) in box, box)
	ms.dialog.buttons[0].pressed.emit()
	cm.world.tables["ambushStep"] = 0
	_put_team(scene, "0,0")
	var was: Dictionary = cm.deploy.stock.duplicate(true)
	var haul: Dictionary = Loot.norm(cm.deploy.cur()["haul"])
	ms.do("home")
	await _frames(2)
	var told: String = ms.dialog.text_label.text if ms.dialog != null else ""
	var paid: Array = ms.last_home.get("dock", {}).get("bounties", []) if ms.last_home.get("dock") is Dictionary else []
	var owed := Loot.add(was, haul)
	for b in paid:
		owed = Loot.add(owed, b["bag"])
	ck("0.10 home: each bounty beaten pays once, into the stockpile, and Home says so", not paid.is_empty() and paid.size() == dict_size(beaten) and cm.deploy.stock == owed and ("Bounty on %s paid: " % paid[0]["name"]) in told, [paid.size(), beaten, told])
	ck("0.10 home: what was packed and not used is back at the dock", dock.owned("Test Stim") == cm.deploy.last()["pack"]["cons"].get("Test Stim", 0) and "Back to the dock, unused: " in told and dock.waiting().is_empty(), told)
	ms.dialog.buttons[0].pressed.emit()
	await _frames(2)
	dk.show_tab("bounties")
	ck("0.10 bounties: a bounty paid is marked so on the board, until it changes", dk.visible and dock.bounties().any(func(b): return Rules.truthy(b.get("claimed"))) == (not ms.last_home["dock"].get("restocked", false)), dk.row_texts())
	# ---- Reset the dock
	dk.show_tab("stockpile")
	var sh_now: int = dock.stockpile()["shards"]
	dk.act(["testing", "reset"])
	ck("0.10 testing: Reset the dock asks first, and says what it forgets", dk.dialog != null and dk.dialog.title_label.text == "Reset the dock?" and "The stockpile stays." in dk.dialog.text_label.text)
	dk.dialog.buttons[0].pressed.emit()
	ck("0.10 testing: Yes forgets the dock, and the stockpile stays", dock.state["reach"] == 0 and dock.level("starter") == 0 and dock.inv == {"cards": {}, "pre": {}} and dock.stockpile()["shards"] == sh_now and dk.note.text == "The dock is as it was at the start." and not dk.row_texts().has("Also kept here"), dk.row_texts())
	# ---- the Workshop's export list
	dk.shop_btn.pressed.emit()
	await _frames(1)
	scene.workshop_screen.show_tab("export")
	ck("0.10 workshop: From your export lists the Companion's designs, and not the pre-built Troops", not scene.workshop_screen.row_texts().has("Hornet Mk I") and not scene.workshop_screen.row_texts().has("Bastion Mk I") and scene.workshop_screen.row_texts().has("Frame Trooper"), scene.workshop_screen.row_texts())
	scene.queue_free()
	await _frames(2)
	Kit.fresh()


# ---------------------------------------------------------------- 0.11: the look
func _eleven() -> void:
	# ---- the typeface and its sizes
	ck("0.11 look: a size written for the old face is a third larger in this one, in whole pixels", Look.fs(18) == 24 and Look.fs(15) == 20 and Look.fs(30) == 40 and Look.fs(22) == 29, [Look.fs(18), Look.fs(22)])
	var th := Look.theme()
	var bn = th.get_stylebox("normal", "Button")
	var bp = th.get_stylebox("pressed", "Button")
	var bd = th.get_stylebox("disabled", "Button")
	ck("0.11 look: the theme's face is Jersey 10, and a button is a raised pixel plate with cut corners", th.default_font == Look.font() and bn is PixelBox and bn.notch == 2 and bn.border == 1 and bn.shadow and bn.bevel and bn.bg_color == UI.BUTTON and bn.border_color == UI.EDGE_HI, bn)
	ck("0.11 look: pressed or chosen it lights in cyan; disabled it lies flat", bp is PixelBox and bp.border_color == UI.CYAN and th.get_color("font_pressed_color", "Button") == UI.CYAN and bd is PixelBox and not bd.bevel and not bd.shadow)
	ck("0.11 look: panels, and lines to type in, wear frames too", th.get_stylebox("panel", "PanelContainer") is PixelBox and th.get_stylebox("panel", "Panel") is PixelBox and th.get_stylebox("normal", "LineEdit") is PixelBox and th.get_stylebox("focus", "LineEdit").border_color == UI.CYAN)
	ck("0.11 look: text has a pixel's shadow under it, so it reads on a backdrop", th.get_color("font_shadow_color", "Label").a > 0.5 and th.get_constant("shadow_offset_x", "Label") == 2 and th.get_constant("shadow_offset_y", "Label") == 2)
	# ---- the frames
	var pb := PixelBox.new()
	var notches := []
	for r in [0, 2, 6, 20]:
		pb.set_corner_radius_all(r)
		notches.append(pb.notch)
	pb.set_border_width_all(2)
	pb.bg_color = UI.GOLD
	pb.shadow = true
	pb.content_margin_left = 9
	var cp := pb.copy()
	ck("0.11 frames: a rounded corner asked for is cut instead, in up to three steps of two pixels", notches == [0, 1, 2, 3] and PixelBox.PX == 2.0, notches)
	ck("0.11 frames: a copy keeps everything, and is its own", cp != pb and cp.notch == 3 and cp.border == pb.border and pb.border > 0 and cp.bg_color == UI.GOLD and cp.shadow and cp.content_margin_left == 9)
	var fr := Look.frame(UI.PANEL, UI.LINE, 2, 1, Vector2(10, 4))
	ck("0.11 frames: Look.frame makes one: fill, edge, weight, corners and the space inside", fr.bg_color == UI.PANEL and fr.border_color == UI.LINE and fr.border == 2 and fr.notch == 1 and fr.content_margin_left == 10 and fr.content_margin_bottom == 4)
	# ---- the colours
	var off := []
	for c in [UI.BG, UI.PANEL, UI.PANEL_LIT, UI.LINE, UI.EDGE_HI, UI.BUTTON, UI.TEXT, UI.PALE, UI.DIM, UI.CYAN, UI.GOLD, UI.RED, UI.SOFT_RED, UI.GREEN, UI.LOOT, UI.AETHER]:
		if not Art.on_palette(c):
			off.append(c.to_html(false))
	for k in UI.TYPE_COLOUR:
		if not Art.on_palette(Color(UI.TYPE_COLOUR[k])):
			off.append(k)
	ck("0.11 colours: every colour the screens use is one of the Pixel Studio's", off.is_empty() and Art.palette().size() == 195, off)
	ck("0.11 colours: nearest finds the palette's colour closest to one that isn't", Art.nearest(Color("#ff2b3d")).to_html(false) == "ff2a3c" and Art.on_palette(Art.nearest(Color(0.33, 0.21, 0.77))) and not Art.on_palette(Color(0.33, 0.21, 0.77)))
	# ---- the icons
	Art.load_from(null)
	var shapes := {}
	var icon_bad := []
	for id in Art.ICONS:
		var img := Art.icon_image(id)
		var filled := 0
		var edge := 0
		var tones := {}
		for y in 16:
			for x in 16:
				var c := img.get_pixel(x, y)
				if c.a == 0.0:
					continue
				filled += 1
				tones[c.to_html(false)] = true
				if c == Art.OUTLINE:
					edge += 1
				elif not Art.on_palette(c):
					icon_bad.append("%s off the palette at %d,%d" % [id, x, y])
		if img.get_width() != 16 or img.get_height() != 16 or filled < 40 or edge < 12 or tones.size() < 4:
			icon_bad.append("%s: %d filled, %d outline, %d tones" % [id, filled, edge, tones.size()])
		for p in [Vector2i(0, 0), Vector2i(15, 0), Vector2i(0, 15), Vector2i(15, 15)]:
			if img.get_pixel(p.x, p.y).a > 0.0:
				icon_bad.append("%s fills its corner" % id)
		shapes[img.get_data()] = id
	ck("0.11 icons: ten, each 16 by 16: a shape on the palette, lit, shaded and outlined, its corners clear", Art.ICONS.size() == 10 and icon_bad.is_empty(), icon_bad)
	ck("0.11 icons: no two alike", shapes.size() == Art.ICONS.size(), shapes.values())
	var t1 := Art.icon("shards")
	ck("0.11 icons: as textures, made once", t1 is Texture2D and t1.get_width() == 16 and Art.icon("shards") == t1)
	# ---- the backdrops and the floor
	var seen := {}
	var bd_bad := []
	for kind in ["title", "dock", "menu"]:
		var img := Art.backdrop_image(kind)
		if img.get_width() != 256 or img.get_height() != 144:
			bd_bad.append("%s is %dx%d" % [kind, img.get_width(), img.get_height()])
		var n_off := 0
		for y in range(0, 144, 3):
			for x in range(0, 256, 3):
				if not Art.on_palette(img.get_pixel(x, y)) or img.get_pixel(x, y).a < 1.0:
					n_off += 1
		if n_off > 0:
			bd_bad.append("%s: %d pixels off the palette" % [kind, n_off])
		seen[img.get_data()] = kind
	ck("0.11 backdrops: Home's, the dock's and the menus', each 256 by 144, opaque, on the palette", bd_bad.is_empty() and seen.size() == 3, bd_bad)
	ck("0.11 backdrops: the size of the Companion's slots, which fill 1280 by 720 five times over", Art.BW * 5 == 1280 and Art.BH * 5 == 720 and Art.SLOTS["ui.title"] == ["Title", 256, 144] and Art.SLOTS["ui.backdrop.dock"][1] == 256 and Art.SLOTS["ui.floor"] == ["Fight floor", 64, 64])
	var fl := Art.floor_image()
	var fl_off := 0
	for y in 64:
		for x in 64:
			if not Art.on_palette(fl.get_pixel(x, y)):
				fl_off += 1
	ck("0.11 floor: a 64 by 64 deck plate that repeats, on the palette", fl.get_width() == 64 and fl.get_height() == 64 and fl_off == 0 and Art.floor_tile().get_width() == 64, fl_off)
	var ring := Art.ring_image(Board.SIZE)
	var rw := ring.get_width()
	var rh := ring.get_height()
	ck("0.11 board: a tile's pixel edge, at half the board's scale: dark outline, clear middle and corners", absf(rw * Board.PIXEL - Hex.SQ3 * Board.SIZE) <= Board.PIXEL and absf(rh * Board.PIXEL - 2.0 * Board.SIZE) <= Board.PIXEL
		and ring.get_pixel(rw / 2, rh / 2).a == 0.0 and ring.get_pixel(0, 0).a == 0.0 and ring.get_pixel(rw / 2, 1) == Art.OUTLINE, [rw, rh])
	# ---- yours, from the export
	var x := KeterExport.new()
	x.open(FIXTURE)
	var s0 := Art.serial
	Art.load_from(x)
	var hp := Art.icon("hp")
	ck("0.11 art: an icon drawn in its Game look slot comes in the export and is used in place of the game's", Art.is_mine("ui.icon.hp") and Art.serial == s0 + 1 and hp != null and hp.get_image().get_pixel(7, 7).to_html(false) == "6dff3a" and hp.get_image().get_pixel(4, 1).to_html(false) == "2a1e23", hp.get_image().get_pixel(7, 7).to_html(false) if hp != null else null)
	ck("0.11 art: a slot left empty is the game's own", not Art.is_mine("ui.icon.ac") and not Art.is_mine("ui.title") and Art.icon("ac").get_image().get_data() == Art.icon_image("ac").get_data() and Art.backdrop("title").get_width() == 256 and Art.floor_tile().get_width() == 64)
	var gpic: Texture2D = Art.icon("ac")
	Art._mine["ui.backdrop.dock"] = gpic
	Art._mine["ui.floor"] = gpic
	ck("0.11 art: a backdrop or a floor of yours, used just the same", Art.backdrop("dock") == gpic and Art.floor_tile() == gpic and Art.backdrop("menu") != gpic)
	Art.load_from(null)
	ck("0.11 art: and without them, the game's own again", not Art.is_mine("ui.icon.hp") and Art.icon("hp").get_image().get_data() == Art.icon_image("hp").get_data() and Art.backdrop("dock") != gpic and Art.ground.is_empty())
	x.close()
	# ---- amounts as icons and numbers
	var bag := Loot.bag()
	bag["shards"] = 25
	bag["parts"]["troop"][0] = 2
	bag["parts"]["troop"][2] = 1
	bag["parts"]["aether"][1] = 1
	var items := UI.bag_items(bag)
	ck("0.11 icons: a bag reads as shards, then each kind of part it holds", items.map(func(i): return [i[0], i[1]]) == [["shards", "25"], ["part_troop", "3"], ["part_aether", "1"]] and items[0][2] == UI.LOOT, items)
	ck("0.11 icons: an empty bag still says its shards", UI.bag_items(Loot.bag()).map(func(i): return i[1]) == ["0"])
	var row := UI.stats_row(items, 24)
	ck("0.11 icons: a row of them, each its icon at twice its size and its number", _stats(row) == [["shards", "25"], ["part_troop", "3"], ["part_aether", "1"]] and row.get_child(0).get_child(0) is TextureRect and row.get_child(0).get_child(0).custom_minimum_size == Vector2(32, 32)
		and row.get_child(0).get_child(0).texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and _stat_total(row, "part_") == 4, _stats(row))
	row.free()


# ---------------------------------------------------------------- 0.12: motion and feedback
func _twelve() -> void:
	Kit.fresh()
	ck("0.12 settings: a new game plays at Normal, with shake and sound", Motion.speed == "normal" and Motion.shake and Motion.sound and Motion.still)
	Motion.set_speed("fast")
	var saved1 = JSON.parse_string(FileAccess.get_file_as_string(Motion.path)) if FileAccess.file_exists(Motion.path) else null
	Motion.set_shake(false)
	Motion.set_sound(false)
	var saved = JSON.parse_string(FileAccess.get_file_as_string(Motion.path)) if FileAccess.file_exists(Motion.path) else null
	Motion.speed = "normal"
	Motion.shake = true
	Motion.sound = true
	Motion._read = false
	Motion.settings()
	ck("0.12 settings: each choice is kept, and read back next time", saved1 is Dictionary and saved1["speed"] == "fast" and saved is Dictionary and saved["speed"] == "fast" and saved["shake"] == false and Motion.speed == "fast" and not Motion.shake and not Motion.sound, saved)
	ck("0.12 settings: the speed steps Normal, Fast, Instant and round again", [Motion.next_speed(), Motion.next_speed(), Motion.next_speed()] == ["instant", "normal", "fast"])
	var f := FileAccess.open(Motion.path, FileAccess.WRITE)
	f.store_string("{ not json")
	f.close()
	Motion._read = false
	Motion.speed = "instant"
	Motion.settings()
	ck("0.12 settings: a file that can't be read leaves them as they were", Motion.speed == "instant")
	Motion.reset()
	Motion.still = false
	var ks := []
	for sp in Motion.SPEEDS:
		Motion.speed = sp
		ks.append([Motion.moving(), Motion.k(), Motion.wait_k()])
	ck("0.12 speed: Normal moves at full length, Fast at under half, Instant not at all, with short pauses", ks == [[true, 1.0, 1.0], [true, 0.45, 0.45], [false, 0.0, 0.12]], ks)
	Motion.speed = "normal"
	Motion.still = true
	ck("0.12 speed: while the tests hold it still, nothing moves and the pauses are as before", not Motion.moving() and Motion.k() == 0.0 and Motion.wait_k() == 1.0)
	# ---- what an Action fires
	ck("0.12 shots: an Action fires its own kind, and a bolt when it has none or one the game doesn't know",
		Motion.kind_of({"proj": "shell"}) == "shell" and Motion.kind_of({"projectile": "beam"}) == "beam" and Motion.kind_of({"proj": ""}) == "bolt" and Motion.kind_of({"proj": "laser"}) == "bolt" and Motion.kind_of(null) == "bolt")
	ck("0.12 shots: yours in cyan, the Enemies' in orange, Aether's blue and Cyber's violet", Motion.colour_of("ally", "ranged") == UI.CYAN and Motion.colour_of("enemy", "ranged") == Color("#ff7a1a") and Motion.colour_of("enemy", "aether") == UI.AETHER and Motion.colour_of("ally", "cyber") == Color("#c23bff"))
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)
	var gun = Rules.unit_from_card(r.card_named("Test Gunner"), "enemy")
	var war = Rules.unit_from_card(r.card_named("Test Warden"), "ally")
	ck("0.12 shots: a card's Projectile comes in the export and onto its Unit's Actions (as rules.js has it)", gun["actions"].map(func(a): return a["proj"]) == ["beam", "spray"] and war["actions"][0]["proj"] == "spray" and war["actions"][1]["proj"] == "", [gun["actions"].map(func(a): return a["proj"]), war["actions"].map(func(a): return a["proj"])])
	ck("0.12 panel: an Action's line says what it fires, where its card says", UnitPanel.action_summary(war["actions"][0]).ends_with(" · fires a Spray") and not "fires" in UnitPanel.action_summary(war["actions"][1]), UnitPanel.action_summary(war["actions"][0]))
	x.close()
	# ---- the Workshop
	var d := {"id": "ds_x", "name": "P", "chassis": "ch_test_general", "abilities": [
		{"name": "a", "kind": "action", "role": "Ranged", "energy": 1, "range": 4, "hit": 6, "ap": 2, "projectile": "shell", "text": ""},
		{"name": "b", "kind": "action", "role": "Melee", "energy": 1, "ap": 2, "projectile": "beam", "text": ""},
		{"name": "c", "kind": "action", "role": "Cyber", "energy": 1, "range": 3, "hit": 6, "ap": 2, "projectile": "laser", "text": ""}]}
	var ws := Workshop.new(Progress.new(Loot.new(null, 1), null, null, null), null)
	var card := ws.to_card(d)
	ck("0.12 workshop: a design's Troop card carries what its ranged attacks fire, and only those the game knows", card["entries"].map(func(e): return e.get("projectile")) == ["shell", null, null], card["entries"].map(func(e): return e.get("projectile")))
	var back := Workshop.from_card(card)
	ck("0.12 workshop: and a design read back from its card has it again", back["abilities"][0].get("projectile") == "shell" and not back["abilities"][1].has("projectile"))
	ck("0.12 workshop: what an ability fires, a bolt by default", Workshop.projectile_of({"projectile": "spray"}) == "spray" and Workshop.projectile_of({}) == "bolt" and Workshop.projectile_of({"projectile": "x"}) == "bolt")
	# ---- the sounds
	Sound.load_all()
	var made := Sound.NAMES.keys().all(func(n): return Sound.streams.get(n) is AudioStreamWAV and (Sound.streams[n] as AudioStreamWAV).data.size() > 400)
	ck("0.12 sounds: thirteen, each made by the game: shots of each kind, hits, misses, downs, steps, cards and buttons", Sound.NAMES.size() == 13 and made and Sound.mine.is_empty() and ["bolt", "shell", "beam", "spray"].all(func(n): return Sound.NAMES.has(n)))
	var datas := {}
	for n in Sound.NAMES:
		datas[(Sound.streams[n] as AudioStreamWAV).data] = n
	ck("0.12 sounds: no two alike", datas.size() == Sound.NAMES.size())
	DirAccess.make_dir_recursive_absolute("res://sounds")
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = 11025
	var pcm := PackedByteArray()
	pcm.resize(2000)
	w.data = pcm
	w.save_to_wav("res://sounds/hit.wav")
	Sound.load_all()
	var yours: AudioStreamWAV = Sound.streams["hit"]
	ck("0.12 sounds: a .wav of yours in the sounds folder, named for one, plays in its place", Sound.mine.has("hit") and Sound.mine.size() == 1 and yours.mix_rate == 11025, Sound.mine)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://sounds/hit.wav"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://sounds"))
	Sound.load_all()
	ck("0.12 sounds: and with it gone, the game's own again", Sound.mine.is_empty() and (Sound.streams["hit"] as AudioStreamWAV).mix_rate == Sound.RATE)
	var shapes := {}
	for sp in Motion.SPEEDS:
		shapes[Art.icon_image("speed_" + sp).get_data()] = sp
	ck("0.12 speed: the speed button's three icons, one for each speed", shapes.size() == 3 and Art.icon("speed_fast").get_width() == 16)
	Kit.fresh()


## Until the fight's screen has nothing under way (0.12).
func _idle(scene: Node) -> void:
	await process_frame
	var n := 0
	while (scene.busy or scene.walking) and n < 600:
		await process_frame
		n += 1


func _twelve_scene() -> void:
	Kit.fresh()
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	await _frames(2)
	Motion.still = false
	Motion.speed = "fast"
	# ---- buttons, Options, the speed button
	Sound.played.clear()
	scene.home.options_btn.pressed.emit()
	await _frames(1)
	var ob: OptionsBox = scene.options
	ck("0.12 home: Options opens, with Speed, Screen shake and Sound, each lit at what is chosen", ob != null and ob.speed_btns.keys() == ["normal", "fast", "instant"] and ob.speed_btns["fast"].button_pressed and not ob.speed_btns["normal"].button_pressed and ob.shake_btns[true].button_pressed and ob.sound_btns[true].button_pressed)
	ck("0.12 sounds: a button clicks as it is pressed", Sound.played.has("tap"), Sound.played)
	ob.speed_btns["instant"].pressed.emit()
	ob.shake_btns[false].pressed.emit()
	var kept = JSON.parse_string(FileAccess.get_file_as_string(Motion.path))
	ck("0.12 options: a choice is made, lit, and kept at once", Motion.speed == "instant" and not Motion.shake and ob.speed_btns["instant"].button_pressed and not ob.speed_btns["fast"].button_pressed and ob.shake_btns[false].button_pressed and kept["speed"] == "instant" and kept["shake"] == false)
	ob.close_btn.pressed.emit()
	await _frames(1)
	ck("0.12 options: Close puts it away", scene.options == null)
	Motion.set_shake(true)
	Motion.set_speed("fast")
	# ---- a fight
	var ci := -1
	for i in scene.floors.size():
		if scene.floors[i].name == "TEST · Corridor":
			ci = i
	var r: Roster = scene.roster
	scene.start_battle(ci, [r.card_named("Test Warden"), r.card_named("Test Striker")], [], 6)
	await _frames(3)
	scene._show_speed()
	ck("0.12 fight: the bar's speed button wears the speed, and opens Options", scene.speed_btn.visible and scene.speed_btn.icon == Art.icon("speed_fast"))
	scene.speed_btn.pressed.emit()
	await _frames(1)
	ck("0.12 fight: (Options, from the fight)", scene.options != null)
	scene.close_options()
	var bt: Battle = scene.battle
	for u in bt.units:
		u["ac"] = 0
		u["integrity"] = 0
		u["hpMax"] = 200
		u["hp"] = 200
		for a in u["actions"]:
			if a.get("hit") != null:
				a["hit"] = 1
	_place(scene, "a1", Vector2i(0, 0))
	_place(scene, "a2", Vector2i(2, 0))
	_place(scene, "e1", Vector2i(3, 0))
	scene.board.refresh_units(bt)
	await _frames(2)
	var war = bt.unit_by_id("a1")
	var str_ = bt.unit_by_id("a2")
	var foe = bt.unit_by_id("e1")
	var fv: UnitView = scene.board.view_of("e1")
	# a Ranged Action: its shot, as its kind
	Sound.played.clear()
	scene.fxl.fired.clear()
	var hp0: int = foe["hp"]
	scene.attack_with(war, war["actions"][0], foe)
	await _frames(3)
	var in_air: bool = not scene.fxl.shots.is_empty()
	var kinds: Array = scene.fxl.shots.map(func(x): return x["kind"])
	var before_land: bool = foe["hp"] < hp0 and scene.overlay.readout.is_empty()
	var tile_at := Board.at(Vector2i(3, 0))
	var jolt := 0.0
	for i in 40:
		await process_frame
		jolt = maxf(jolt, fv.position.distance_to(tile_at))
	await _idle(scene)
	ck("0.12 fight: a Ranged Action fires its kind at the target (Pinning Volley, a spray of pellets)", in_air and kinds.size() == 6 and kinds.all(func(k): return k == "spray") and scene.fxl.fired.back() == {"kind": "spray", "hit": true}, [kinds, scene.fxl.fired])
	ck("0.12 fight: the rules have decided it before the shot lands, and what it did is shown as it lands", before_land and not scene.overlay.readout.is_empty() and foe["hp"] < hp0)
	ck("0.12 fight: it lands: sparks, the sound of the shot and of the hit", Sound.played.has("spray") and Sound.played.has("hit"), Sound.played)
	ck("0.12 fight: the damage pops up big", scene.overlay.floats.any(func(x): return x.get("big", false) and str(x["text"]).begins_with("-")))
	await _frames(30)
	ck("0.12 fight: the target shook where it stands, and is back on its tile", jolt > 2.0 and fv.position.is_equal_approx(Board.at(Vector2i(3, 0))) and fv.flash < 0.05, [jolt, fv.position])
	# a blow struck
	var sv: UnitView = scene.board.view_of("a2")
	Sound.played.clear()
	scene.attack_with(str_, str_["actions"][0], foe)
	await _frames(2)
	var mid := sv.position
	await _idle(scene)
	await _frames(30)
	ck("0.12 fight: a Melee Action lunges at the target and steps back", not mid.is_equal_approx(Board.at(Vector2i(2, 0))) and sv.position.is_equal_approx(Board.at(Vector2i(2, 0))) and Sound.played.has("melee"), [mid, sv.position])
	# a miss flies past
	war["nrg"] = 9
	foe["ac"] = 99
	for a in war["actions"]:
		if a.get("hit") != null:
			a["hit"] = 99
	scene.fxl.fired.clear()
	Sound.played.clear()
	await scene.attack_with(war, war["actions"][0], foe)
	ck("0.12 fight: a miss flies past, and sounds so", scene.fxl.fired.back() == {"kind": "spray", "hit": false} and Sound.played.has("miss"), [scene.fxl.fired, Sound.played])
	foe["ac"] = 0
	# walking: hop by hop
	scene.select(war)
	await _frames(1)
	Sound.played.clear()
	var wv: UnitView = scene.board.view_of("a1")
	scene.move_selected(Vector2i(-2, 0))
	var lifted := false
	for i in 40:
		await process_frame
		lifted = lifted or wv.lift > 1.0
	await _idle(scene)
	ck("0.12 fight: a Unit hops from tile to tile, a step at a time, and lands", bt.unit_by_id("a1")["pos"] == {"q": -2, "r": 0} and lifted and wv.lift == 0.0 and wv.position.is_equal_approx(Board.at(Vector2i(-2, 0))) and Sound.played.count("step") == 2, Sound.played)
	# brought down: it crumbles
	foe["hp"] = 1
	str_["nrg"] = 9
	str_["moved"] = false
	Sound.played.clear()
	var shook := false
	scene.attack_with(str_, str_["actions"][0], foe)
	for i in 20:
		await process_frame
		shook = shook or scene.camera.offset.length() > 0.5
	await _idle(scene)
	ck("0.12 fight: a Unit brought down flashes, crumbles into pieces and is gone, and the screen shakes", Rules.truthy(foe.get("down")) and fv.gone and (not fv.bits.is_empty() or not fv.visible) and Sound.played.has("down") and shook)
	await _frames(60)
	ck("0.12 fight: then it is gone, and the screen is still", not fv.visible and scene.camera.offset == Vector2.ZERO)
	# shake off: still
	Motion.set_shake(false)
	scene._shake(1.0)
	await _frames(3)
	ck("0.12 options: with Screen shake off, nothing shakes", scene.camera.offset == Vector2.ZERO)
	Motion.set_shake(true)
	# an area lands; a card flies
	scene.fxl.clear()
	scene.fxl.area(Vector2i(0, 0), 1)
	# (0.16: an explosion on each tile, where 0.12 had a ring)
	var booms: Array = scene.fxl.plays.filter(func(x): return x["name"] == "explosion")
	ck("0.12 fight: an area bursts over every tile it catches, the middle first", booms.size() == 7 and booms.filter(func(x): return x["t"] == 0.0).size() == 1 and booms.filter(func(x): return x["t"] < 0.0).size() == 6)
	Sound.played.clear()
	scene.fxl.clear()
	# (0.16: what the card did plays where it did it: here, it hurt the Unit standing in the middle)
	var cmark: Array = scene._mark()
	bt.floats.append({"unit": war["id"], "text": "-3 HP", "kind": "damage"})
	scene._card_flight({"kind": "hand", "name": "Test Mortar Strike", "needs": {"radius": 1}}, null, null, Vector2i(1, 0), cmark)
	await _frames(2)
	var flying: bool = scene.overlay.flights.size() == 1
	var n := 0
	while not scene.overlay.flights.is_empty() and n < 300:
		await process_frame
		n += 1
	ck("0.12 cards: a card played flies to where it goes, and lands with a flash and its area's burst", flying and scene.overlay.flights.is_empty() and scene.overlay.flashes.size() == 1 and scene.fxl.played.filter(func(x): return x["name"] == "explosion").size() >= 7 and scene.fxl.played.any(func(x): return x["name"] == "impact") and Sound.played.has("card"), scene.fxl.played)
	# Instant: nothing moves
	Motion.set_speed("instant")
	scene.fxl.clear()
	war["moved"] = false
	bt.moved = {}
	scene.select(war)
	scene.move_selected(Vector2i(-1, 0))
	var at_once := wv.position.is_equal_approx(Board.at(Vector2i(-1, 0)))
	await _frames(2)
	ck("0.12 instant: a Unit is simply where it went", at_once and wv.position.is_equal_approx(Board.at(Vector2i(-1, 0))) and wv.lift == 0.0 and not scene.walking)
	scene.fxl.fired.clear()
	await scene.attack_with(war, war["actions"][0], bt.unit_by_id("e2") if bt.unit_by_id("e2") != null else foe)
	ck("0.12 instant: a shot is made, but nothing is drawn in the air", scene.fxl.fired.size() == 1 and scene.fxl.shots.is_empty() and scene.fxl.plays.is_empty())
	# boxes pop
	Motion.set_speed("normal")
	scene._open_dialog(Dialog.new("Test", "A box.", ["OK"]), func(_i): pass)
	var dl: Dialog = scene.dialog
	# (one frame: the box starts small then; by a second, a slow frame can see it whole already)
	await _frames(1)
	var small: bool = dl.box.scale.x < 0.999
	await _frames(30)
	ck("0.12 boxes: a box pops open, from a little smaller", small and dl.box.scale.is_equal_approx(Vector2.ONE))
	var calls := [0]
	dl.chosen.connect(func(_i): calls[0] += 1)
	scene._close_dialog()
	dl.buttons[0].pressed.emit()
	await _frames(2)
	var still_there := is_instance_valid(dl) and dl.is_inside_tree() and dl.mouse_filter == Control.MOUSE_FILTER_IGNORE
	await _frames(40)
	ck("0.12 boxes: and shuts: let go at once (a second tap does nothing), shrinking away, then gone", scene.dialog == null and calls[0] == 0 and still_there and not is_instance_valid(dl), [still_there, calls])
	# a new screen fades in
	scene.show_home()
	await _frames(1)
	var veil: float = scene.curtain.color.a
	# (the fade runs in real time, and a frame without a screen can be very short: wait for it, a while at most)
	var waited := 0
	while scene.curtain.color.a > 0.0 and waited < 600:
		await process_frame
		waited += 1
	ck("0.12 screens: a new screen fades in", veil > 0.3 and scene.curtain.color.a == 0.0 and scene.curtain.mouse_filter == Control.MOUSE_FILTER_IGNORE, [veil, waited])
	scene.queue_free()
	await _frames(2)
	Kit.fresh()


## The Backdrop a screen stands on (0.11), or null.
func _backdrop_of(n: Node) -> Backdrop:
	for c in n.get_children():
		if c is Backdrop:
			return c
	return null


## Every icon shown under a node (0.11), by its id.
func _icons(n: Node) -> Array:
	var out := []
	for c in n.get_children():
		if c is TextureRect and c.has_meta("icon"):
			out.append(str(c.get_meta("icon")))
		out.append_array(_icons(c))
	return out


func _eleven_scene() -> void:
	Kit.fresh()
	Kit.keep([Kit.field_team()])
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	await _frames(2)
	var cm: Campaign = scene.campaign
	var ms: MapScreen = scene.map_screen
	var dk: DockScreen = scene.dock_screen
	cm.loot.seed_with(41)
	ck("0.11 screen: every screen wears the theme, in Jersey 10", scene.ui.theme != null and scene.ui.theme.default_font == Look.font() and ThemeDB.fallback_font == Look.font() and ThemeDB.fallback_font_size == Look.fs(16))
	var hb := _backdrop_of(scene.home)
	ck("0.11 home: on the title backdrop, not dimmed: the colony's sign is the game's name (0.15), nothing written over it", hb != null and hb.kind == "title" and hb.dim < 0.2 and not scene.home.title.visible and scene.home.title.text == "KETER"
		and Art.backdrop("title") == Art.piece("menu", "home") and Art.piece("menu", "home") != null)
	ck("0.11 home: the export's own icon is in use from the start", Art.is_mine("ui.icon.hp"))
	Art._mine["ui.title"] = Art.backdrop("menu")
	scene.show_home()
	ck("0.11 home: with a Title of yours, it is Home's picture", not scene.home.title.visible and Art.backdrop("title") == Art._mine["ui.title"])
	Art._mine.erase("ui.title")
	scene.show_home()
	ck("0.11 home: and without, the game's sign is back", not scene.home.title.visible and Art.backdrop("title") == Art.piece("menu", "home"))
	var sb := _backdrop_of(scene.setup) if scene.setup != null else null
	ck("0.11 screens: the menus stand on the menu backdrop, dimmed", sb != null and sb.kind == "menu" and sb.dim >= 0.5 and _backdrop_of(scene.teams_screen).kind == "menu" and _backdrop_of(scene.workshop_screen).kind == "menu", [sb])
	# ---- the dock
	var gift := Loot.bag()
	gift["shards"] = 40
	gift["parts"]["troop"][0] = 3
	gift["parts"]["equipment"][1] = 2
	cm.dock.add_to_stockpile(gift)
	scene.home.world_btn.pressed.emit()
	await _frames(2)
	var db := _backdrop_of(dk)
	var rows := dk.row_texts()
	var i_sh := rows.find("40 Aether shards")
	ck("0.11 dock: it stands on its own backdrop, dimmed further", dk.visible and db != null and db.kind == "dock" and db.dim >= 0.7)
	ck("0.11 dock: the stockpile's shards and parts wear their icons", i_sh >= 0 and _icons(dk._rows[i_sh]["row"]) == ["shards"] and _icons(dk._rows[i_sh + 1]["row"]).size() == 1 and _icons(dk._rows[i_sh + 1]["row"])[0].begins_with("part_"), [rows, _icons(dk._rows[i_sh]["row"]) if i_sh >= 0 else null])
	dk.show_tab("reclaim")
	ck("0.11 dock: so do the parts on Reclaim", not dk.row_texts().is_empty() and dk._rows.all(func(r): return _icons(r["row"]).size() == 1 and _icons(r["row"])[0].begins_with("part_")), dk.row_texts())
	dk.show_tab("stockpile")
	# ---- out on the map
	dk.go_btn.pressed.emit()
	await _frames(1)
	dk.choose_team(0)
	dk.go_btn.pressed.emit()
	await _frames(3)
	ck("0.11 map: the bar shows who is standing and the haul as icons and numbers", cm.deploy.active() and ms.visible and ms.status_icons.visible and not ms.status_label.visible
		and _stats(ms.status_icons) == [["hp", "3 of 3 standing"], ["shards", "0"]] and ms.status_label.text.begins_with("Heroes standing: 3 of 3"), [_stats(ms.status_icons), ms.status_label.text])
	ck("0.11 map: on the dock, no Skull Level is shown", not ms.p_skull.visible)
	cm.world.tables["ambushStep"] = 100
	var here: String = cm.deploy.cur()["pos"]
	var next_tile: String = World.neighbours(here).filter(func(k): return cm.world.is_open(k) and cm.world.content_at(k) == null)[0]
	ms.tap(next_tile)
	await _frames(1)
	var sk := cm.world.skull_of(next_tile)
	ck("0.11 map: a tile chosen shows its Skull Level as the skull and its number", ms.p_skull.visible and (ms.p_skull.get_child(1) as Label).text.is_valid_int() and int((ms.p_skull.get_child(1) as Label).text) == sk and ms.p_skull.get_meta("icon") == "skull", (ms.p_skull.get_child(1) as Label).text)
	await ms.walk(next_tile)
	await _frames(2)
	ms.do("fight")
	await _frames(2)
	var s: SetupScreen = scene.setup
	s._go(1)
	s.start()
	await _frames(4)
	var bt: Battle = scene.battle
	ck("0.11 fight: it begins", bt != null and scene.board.visible and bt.deploy != null)
	if bt == null:
		scene.queue_free()
		await _frames(2)
		Kit.fresh()
		return
	var dist: String = bt.floor_data.district
	ck("0.11 board: without ground drawn for its District, none is laid", scene.board.ground_of().is_empty())
	var gt: Texture2D = Art.icon("skull")
	Art.ground[dist if dist != "" else "1"] = [gt]
	ck("0.15 board: in a District with its own floor, the export's old ground isn't laid over it: the tiles are the District's plates", dist == "" or (scene.board.ground_of().is_empty() and scene.board.plate_for(Vector2i(0, 0)) == Art.district_board(dist, "floor_%d" % Board.D_FLOORS[scene.board._hash(Vector2i(0, 0)) % Board.D_FLOORS.size()])["texture"]), dist)
	Art.ground.clear()
	# the unit panel
	var hero: Dictionary = bt.side_units("ally")[0]
	scene.select(hero)
	await _frames(2)
	var stat_icons := _icons(scene.panel.stats_box)
	ck("0.11 panel: HP, AC, MS and NRG each wear their icon (Health the export's own)", stat_icons == ["hp", "ac", "ms", "nrg"] and scene.panel.stats_box.get_child_count() == 5, stat_icons)
	var hp_rect: TextureRect = _first_icon(scene.panel.stats_box, "hp")
	ck("0.11 panel: the icon is the one you drew", hp_rect != null and hp_rect.texture == Art.icon("hp") and Art.is_mine("ui.icon.hp"))
	# the bottom line's bar
	scene._say("Something happened.")
	await _frames(2)
	var ar: Rect2 = scene.info_back.area()
	ck("0.11 fight: the bottom line sits on a bar as tall as what it says", ar.size.x > 100.0 and ar.size.y >= scene.info.get_line_height() and ar.size.y < scene.info.get_line_height() * 2.0 + 20.0 and ar.end.y >= scene.info.position.y + scene.info.size.y, [ar, scene.info.get_line_height()])
	scene._say("")
	ck("0.11 fight: and with nothing to say, no bar", scene.info_back.area().size == Vector2.ZERO)
	ck("0.11 fight: the Aether button wears Aether's icon", scene.aether_btn.icon == Art.icon("aether"))
	# the result
	await _end_fight(scene, true)
	var d: Dialog = scene.dialog
	var got := _stats(d.stats) if d != null else []
	ck("0.11 result: what the fight brings into the haul is added up as a row of icons", d != null and not got.is_empty() and got[0][0] == "shards" and _labels(d).has("In all") and _stat_total(d.stats, "shards") >= 0, got)
	scene.queue_free()
	await _frames(2)
	Kit.fresh()


func _first_icon(n: Node, id: String) -> TextureRect:
	for c in n.get_children():
		if c is TextureRect and c.get_meta("icon", "") == id:
			return c
		var f := _first_icon(c, id)
		if f != null:
			return f
	return null


## A row of icons and numbers (0.11), as [[icon, text], ...].
func _stats(row: Node) -> Array:
	var out := []
	if row == null:
		return out
	for c in row.get_children():
		if c.has_meta("icon"):
			out.append([str(c.get_meta("icon")), str(c.get_meta("count")) if c.has_meta("count") else (c.get_child(1) as Label).text])
	return out


## What a row of icons adds up to, for icons whose names begin so.
func _stat_total(row: Node, begins: String) -> int:
	var n := 0
	for s in _stats(row):
		if str(s[0]).begins_with(begins):
			n += int(s[1])
	return n


func dict_size(names: Array) -> int:
	var d := {}
	for n in names:
		d[n] = true
	return d.size()


# ---------------------------------------------------------------- 0.13: the playtest's fixes
func _thirteen() -> void:
	Kit.fresh()
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)
	var cor: FloorData = _floor_named(x, "TEST · Corridor")

	# ---- the locks: 2 turns at most, no second dose, and a guard once over
	for nm in ["Stunned", "Rooted", "Pinned", "Marked"]:
		var u := {"id": "l1", "name": "Lock", "side": "enemy", "hp": 10, "hpMax": 10, "statuses": []}
		Rules.add_status(u, nm, null, null, 5)
		ck("0.13 locks: %s lasts 2 turns at most, however long it is given for" % nm, Rules.status_turns(u, nm) == 2, u["statuses"])
		var again := Rules.add_status(u, nm, null, null, 2)
		ck("0.13 locks: a second dose of %s does nothing while it lasts" % nm, Rules.status_turns(u, nm) == 2 and again[0].get("resisted") == true and Rules.lock_block(u, nm) == "already", u["statuses"])
		Rules.tick_statuses([u], false)
		Rules.tick_statuses([u], false)
		ck("0.13 locks: when %s ends, the Unit is guarded against it" % nm, not Rules.has_status(u, nm) and u.get("guards") is Dictionary and u["guards"].has(nm.to_lower()) and Rules.lock_block(u, nm) == "guard", u)
		Rules.add_status(u, nm)
		ck("0.13 locks: guarded, it can't be %s again yet" % nm, not Rules.has_status(u, nm), u["statuses"])
		Rules.tick_statuses([u], true)
		ck("0.13 locks: the other half of the round leaves the guard on (%s)" % nm, u.get("guards") is Dictionary and u["guards"].has(nm.to_lower()), u)
		Rules.tick_statuses([u], false)
		Rules.add_status(u, nm)
		ck("0.13 locks: a round on, the guard is gone and %s lands again" % nm, not u.has("guards") and Rules.has_status(u, nm), u)
	var pz := {"id": "p1", "name": "Pz", "side": "enemy", "hp": 10, "hpMax": 10, "statuses": []}
	Rules.add_status(pz, "Poisoned", 2, null, 2)
	Rules.add_status(pz, "Poisoned", 1, null, 3)
	ck("0.13 locks: any other Status still adds both doses", Rules.status_n(pz, "Poisoned") == 3 and Rules.status_turns(pz, "Poisoned") == 5 and not Rules.is_lock("Poisoned"), pz["statuses"])

	# ---- in a fight: the guard says so in the Log
	var w := _mk(r, "Test Warden", "ally", "a1", Vector2i(0, 0))
	var g := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(2, 0))
	var b := Battle.from_state(cor, [w, g], 3, r.cards)
	g["guards"] = {"stunned": false}
	var at := b.log.size()
	b.fx.run_text("[[target enemy]] gains [[Stunned]].", {"actor": w, "target": g, "sourceCard": "Test Stun"})
	ck("0.13 locks: a guarded Unit shrugs a Stun off, and the Log says why", not Rules.has_status(g, "Stunned") and _texts(b, at).any(func(t): return "just came out of a Stun and shrugs it off" in t), _texts(b, at))
	g.erase("guards")
	b.fx.run_text("[[target enemy]] gains [[Rooted]].", {"actor": w, "target": g, "sourceCard": "Test Root"})
	at = b.log.size()
	b.fx.run_text("[[target enemy]] gains [[Rooted]].", {"actor": w, "target": g, "sourceCard": "Test Root"})
	ck("0.13 locks: a second Root does nothing, and says the Unit is already Rooted", Rules.status_turns(g, "Rooted") == 1 and _texts(b, at).any(func(t): return "already Rooted" in t), _texts(b, at))

	# ---- what an attack carries needs it to Penetrate (Melee, Ranged and Cyber; Support always lands)
	var w2 := _mk(r, "Test Warden", "ally", "a1", Vector2i(0, 0))
	var s2 := _mk(r, "Test Striker", "ally", "a2", Vector2i(3, 1))
	var g2 := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(3, 0))
	var hk := _mk(r, "Test Hacker", "enemy", "e2", Vector2i(5, 0))
	var b2 := Battle.from_state(cor, [w2, s2, g2, hk], 3, r.cards)
	var volley := _act(w2, "Pinning Volley")
	volley["hit"] = 1
	g2["ac"] = 99
	var hp0: int = g2["hp"]
	b2.attack(w2, volley, g2)
	ck("0.13 riders: a Ranged shot that hits but doesn't Penetrate gives no Status and no extra damage", not Rules.has_status(g2, "Pinned") and g2["hp"] == hp0, [g2["hp"], g2["statuses"], _texts(b2)])
	g2["ac"] = 0
	b2.attack(w2, volley, g2)
	ck("0.13 riders: once it Penetrates, it carries them", Rules.has_status(g2, "Pinned") and g2["hp"] < hp0, [g2["hp"], g2["statuses"]])
	g2["ac"] = 99
	g2["pos"] = {"q": 3, "r": 0}
	var t0 := Battle.tile_of(g2)
	s2["nrg"] = 9
	b2.attack(s2, _act(s2, "Shoulder Check"), g2)
	ck("0.13 riders: a Melee blow that doesn't Penetrate pushes nobody", Battle.tile_of(g2) == t0, Battle.tile_of(g2))
	var breach := _act(hk, "Breach").duplicate(true)
	breach["text"] = "[[target enemy]] gains [[Slowed 1]]."
	breach["hit"] = 1
	w2["integrity"] = 99
	hk["nrg"] = 9
	b2.attack(hk, breach, w2)
	ck("0.13 riders: a Cyber attack that doesn't get past Integrity carries nothing", not Rules.has_status(w2, "Slowed"), w2["statuses"])
	w2["ac"] = 99
	w2["hp"] = 10
	s2["hp"] = 5
	w2["nrg"] = 9
	b2.attack(w2, _act(w2, "Field Medicine"), s2)
	ck("0.13 riders: a Support Action always lands what it carries", s2["hp"] == 10, s2["hp"])

	# ---- Execute
	ck("0.13 Execute: in the keyword library, an Effect priced like heavy damage", Keywords.by_name("Execute") != null and Keywords.by_name("Execute")["cat"] == "effect" and int(Keywords.by_name("Execute")["weight"]) == 6)
	var ex := _mk(r, "Test Warden", "ally", "a1", Vector2i(0, 0))
	var e1 := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(2, 0))
	var e2 := _mk(r, "Test Grunt", "enemy", "e2", Vector2i(2, 1))
	e2["name"] = "Test Grunt 2"
	var jg := _mk(r, "Test Juggernaut", "enemy", "e3", Vector2i(3, 0))
	var ov := _mk(r, "Test Overseer", "enemy", "e4", Vector2i(3, 1))
	var b3 := Battle.from_state(cor, [ex, e1, e2, jg, ov], 3, r.cards)
	e1["hp"] = int(e1["hpMax"]) / 2 - 1
	e2["hp"] = int(ceil(float(e2["hpMax"]) / 2.0))
	jg["hp"] = 1
	ov["hp"] = 1
	var kills := []
	b3.fx.run_text("[[all enemies within 9]] face an [[Execute]].", {"actor": ex, "target": e1, "sourceCard": "Test Execution"})
	var lines := _texts(b3)
	ck("0.13 Execute: an Enemy below half its Health is removed outright, the kill the actor's", e1["down"] == true and e1["hp"] == 0 and lines.has("Test Grunt is Executed"), lines)
	ck("0.13 Execute: one at half its Health or more is untouched, and the Log says so", not Rules.truthy(e2.get("down")) and lines.has("Test Grunt 2 is not weak enough to be Executed"), lines)
	ck("0.13 Execute: an Elite and a Mini-Boss never are", not Rules.truthy(jg.get("down")) and not Rules.truthy(ov.get("down")) and lines.has("Test Juggernaut is too strong to be Executed") and lines.has("Test Overseer is too strong to be Executed"), lines)
	ex["hp"] = 1
	b3.fx.run_text("[[this Unit]] faces an [[Execute]].", {"actor": ex, "sourceCard": "Test Misfire"})
	ck("0.13 Execute: aimed at its own side, it is refused before anything happens", not Rules.truthy(ex.get("down")) and _texts(b3).any(func(t): return "Execute removes an Enemy" in t), _texts(b3))
	ck("0.13 Execute: the builder phrases it, and reads it back", Builder.build({"when": null, "check": null, "target": {"name": "target enemy", "n": null, "narrow": []}, "effects": [{"name": "damage", "n": "2"}, {"name": "Execute", "n": null}], "mods": [], "dur": null, "adjacent": false})
		== "[[target enemy]] takes [[damage 2]] and faces an [[Execute]]." and not Rules.truthy(Builder.from_sentence("[[target enemy]] takes [[damage 2]] and faces an [[Execute]].").get("ownWords")))
	ck("0.13 Execute: and for several, face", Builder.build({"when": null, "check": null, "target": {"name": "all enemies within", "n": "2", "narrow": []}, "effects": [{"name": "Execute", "n": null}], "mods": [], "dur": null, "adjacent": false}) == "[[all enemies within 2]] face an [[Execute]].")

	# ---- Sacrifice: never an Enemy, and no discount
	var sv := _mk(r, "Test Warden", "ally", "a1", Vector2i(0, 0))
	var sg := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(1, 0))
	var b4 := Battle.from_state(cor, [sv, sg], 3, r.cards)
	b4.fx.apply_keyword({"kw": Keywords.by_name("Sacrifice"), "n": null}, [sg], {"actor": sv}, null)
	ck("0.13 Sacrifice: it never removes an Enemy, and says so", not Rules.truthy(sg.get("down")) and _texts(b4).any(func(t): return "is not a friendly Unit, so it cannot be Sacrificed" in t), _texts(b4))
	ck("0.13 Sacrifice: it costs nothing and earns nothing", int(Keywords.by_name("Sacrifice")["weight"]) == 0)

	# ---- the keyword checks
	var probs := func(t: String, kind := "action"): return Keywords.problems(Keywords.analyse(t), {"kind": kind})
	for nm in ["Stunned", "Rooted", "Pinned", "Marked"]:
		ck("0.13 checks: an always-on Passive cannot give %s" % nm, (probs.call("[[all enemies within 2]] gain [[%s]]." % nm, "passive") as Array).any(func(p): return "always-on Passive" in p), probs.call("[[all enemies within 2]] gain [[%s]]." % nm, "passive"))
		ck("0.13 checks: a triggered one can", not (probs.call("[[when]] [[the round begins]], [[all enemies within 2]] gain [[%s]]." % nm, "passive") as Array).any(func(p): return "always-on Passive" in p))
		for d in ["[[turns 3]]", "[[persistent]]", "[[while attached]]"]:
			ck("0.13 checks: %s for %s is too long" % [nm, d], (probs.call("[[target enemy]] gains [[%s]] %s." % [nm, d]) as Array).has(nm + " lasts 2 turns at most: use turns 1 or 2"), probs.call("[[target enemy]] gains [[%s]] %s." % [nm, d]))
		ck("0.13 checks: %s for 2 turns is fine" % nm, (probs.call("[[target enemy]] gains [[%s]] for [[turns 2]]." % nm) as Array).is_empty(), probs.call("[[target enemy]] gains [[%s]] for [[turns 2]]." % nm))
	ck("0.13 checks: Execute aimed at an ally is flagged", (probs.call("[[target ally]] faces an [[Execute]].") as Array).has("Execute removes an Enemy: use target enemy or all enemies within"))
	ck("0.13 checks: Execute aimed at an Enemy is fine", (probs.call("[[target enemy]] faces an [[Execute]].") as Array).is_empty() and (probs.call("[[all enemies within 2]] face an [[Execute]].") as Array).is_empty())
	ck("0.13 checks: Overclock does nothing, but stops nothing: the rest of the sentence still works", (probs.call("[[Overclock]]: [[this Unit]] gains [[DMG +2]] for [[turns 2]].") as Array).is_empty())

	# ---- the builder offers only what is legal
	var kb := Builder.new()
	kb.begin({"kind": "passive"})
	var names := func(list: Array): return list.map(func(o): return o["name"])
	var on_passive: Array = names.call(kb.effects_for())
	ck("0.13 builder: an always-on Passive is offered no lock", not on_passive.has("Stunned") and not on_passive.has("Rooted") and not on_passive.has("Pinned") and not on_passive.has("Marked") and on_passive.has("Slowed"), on_passive)
	kb.begin({"kind": "action"})
	kb.st["target"] = {"name": "target ally", "n": null, "narrow": []}
	ck("0.13 builder: Execute is not offered for an ally", not names.call(kb.effects_for()).has("Execute") and names.call(kb.effects_for()).has("Stunned"))
	kb.st["target"] = {"name": "target enemy", "n": null, "narrow": []}
	ck("0.13 builder: Execute is offered for an Enemy", names.call(kb.effects_for()).has("Execute"))
	kb.st["target"] = {"name": "all enemies within", "n": "2", "narrow": []}
	ck("0.13 builder: and for every Enemy within reach", names.call(kb.effects_for()).has("Execute"))
	ck("0.13 builder: Overclock is no longer offered", not names.call(kb.mods_for()).has("Overclock") and names.call(kb.mods_for()).has("Burst"), names.call(kb.mods_for()))
	kb.st["target"] = {"name": "target enemy", "n": null, "narrow": []}
	kb.st["effects"] = [{"name": "Stunned", "n": null}]
	kb.go(Builder.step_index("dur"))
	var keys: Array = kb.body().filter(func(o): return o.get("t") == "opt").map(func(o): return o["key"])
	ck("0.13 builder: a lock's Duration is the default or a number of turns, never open-ended", keys.has("none") and keys.has("turns") and not keys.has("persistent"), keys)
	kb.pick("turns")
	for i in 4:
		kb.step(1)
	ck("0.13 builder: its turns step no higher than 2", kb.st["param"] != null and kb.st["param"]["value"] == "2", kb.st.get("param"))
	kb.st["param"]["value"] = "7"
	kb.param_pick("ok")
	ck("0.13 builder: and a number typed in is held to 2", kb.st["dur"] == {"name": "turns", "n": "2"}, kb.st["dur"])
	kb.st["effects"] = [{"name": "Slowed", "n": "1"}]
	kb.go(Builder.step_index("dur"))
	keys = kb.body().filter(func(o): return o.get("t") == "opt").map(func(o): return o["key"])
	ck("0.13 builder: anything else may still be persistent", keys.has("persistent"), keys)

	# ---- prices
	var dk := func(t: String): return Scoring.keyword_detail(t)
	var hit2: float = float(Keywords.by_name("damage")["weight"]) * 2.0
	var areas := []
	for rad in [1, 2, 3]:
		areas.append(dk.call("[[all enemies within %d]] take [[damage 2]]." % rad))
	ck("0.13 prices: an area Target makes its sentence cost 1.5, 2 and 2.5 times as much at 1, 2 and 3 tiles",
		areas.map(func(d): return d["base"]) == [hit2 * 1.5, hit2 * 2.0, hit2 * 2.5] and areas[0]["mods"] == [{"name": "area", "x": 1.5}], areas)
	var both = dk.call("[[all allies within 2]] gain [[heal 2]]. [[this Unit]] gains [[heal 2]].")
	ck("0.13 prices: only the sentence with the area Target", both["base"] == dk.call("[[all allies within 2]] gain [[heal 2]].")["base"] + dk.call("[[this Unit]] gains [[heal 2]].")["base"]
		and dk.call("[[all allies within 2]] gain [[heal 2]].")["base"] == float(Keywords.by_name("heal")["weight"]) * 2.0 * 2.0 and both["mods"] == [{"name": "area", "x": 2.0}]
		and both["mult"] == 1.0 and both["points"] == int(both["base"]), both)
	ck("0.13 prices: Stunned is worth 2, Overclock nothing", int(Keywords.by_name("Stunned")["weight"]) == 2 and dk.call("[[Overclock]]: [[this Unit]] gains [[DMG +2]] for [[turns 2]].")["mult"] == 1.0)

	# ---- a chassis's best (lowest) to-hit
	ck("0.13 chassis: the best to-hit is read as given, held between 1 and 20", Workshop.best_hit({"bestHit": 5}) == 5.0 and Workshop.best_hit({"bestHit": 0}) == 1.0 and Workshop.best_hit({"bestHit": 30}) == 20.0)
	ck("0.13 chassis: one made before reads its old maximum as 12 minus it (8 is 4), and none says 4", Workshop.best_hit({"maxHit": 8}) == 4.0 and Workshop.best_hit({"maxHit": 9}) == 3.0 and Workshop.best_hit({}) == 4.0)
	ck("0.13 chassis: a to-hit may go as high as 20; range and AP keep their maximums", Workshop.max_of({"maxRange": 5}, "hit") == 20.0 and Workshop.max_of({"maxRange": 5}, "range") == 5.0 and Workshop.least_of({"bestHit": 5}, "hit") == 5.0 and Workshop.least_of({"bestHit": 5}, "ap") == 0.0)
	var c := Campaign.new(x, r, x.floors(), 5)
	var ws := c.workshop
	c.progress.set_unlock_all(true)
	var gen = ws.chassis_of({"chassis": "ch_test_general"})
	var dsn := ws.blank("ch_test_general")
	ck("0.13 chassis: the test General's best is 5 (it was a maximum of 7)", Workshop.best_hit(gen) == 5.0, gen)
	ck("0.13 workshop: a new design's to-hit starts at the priced-at 6, or the chassis's best where that is worse", dsn["abilities"][0]["hit"] == 6 and ws.blank_ability({"bestHit": 9, "subtypes": ["Ranged"]}, "action")["hit"] == 9, dsn["abilities"][0])
	dsn["abilities"][0]["text"] = "[[target enemy]] takes [[damage 1]]."
	dsn["abilities"][0]["hit"] = 3
	ck("0.13 workshop: a to-hit better than the chassis's best doesn't fit", ws.check(dsn)["reasons"].has("ability 1's to-hit of 3 is better than this chassis's best of 5"), ws.check(dsn)["reasons"])
	dsn["abilities"][0]["hit"] = 21
	ck("0.13 workshop: nor one over 20", ws.check(dsn)["reasons"].has("ability 1's to-hit of 21 is over 20, so it could never hit"), ws.check(dsn)["reasons"])
	dsn["abilities"][0]["hit"] = 5
	ck("0.13 workshop: at the best, it fits", ws.check(dsn)["ok"], ws.check(dsn)["reasons"])
	var pw := []
	for h in [5, 6, 12]:
		dsn["abilities"][0]["hit"] = h
		pw.append(ws.ability_power(dsn["abilities"][0]))
	ck("0.13 workshop: a surer shot costs more", pw[0] >= pw[1] and pw[1] > pw[2], pw)
	c.progress.set_unlock_all(false)

	# ---- the master Enemies aim at about 8 to 10 now
	var aims := []
	for card in x.cards():
		var t := str(card.get("cardType", "")).to_lower()
		if not ("enemy" in t or "elite" in t or "boss" in t) or str(card.get("name", "")).begins_with("Test"):
			continue
		for e in (card.get("entries") if card.get("entries") is Array else []):
			if str(e.get("role", "")).to_lower() == "ranged" and Rules.truthy(e.get("toHit")):
				aims.append([card["name"], e.get("name"), int(Rules.num(e["toHit"], 0))])
	ck("0.13 Enemies: every master Enemy's Ranged to-hit is 10 or better", not aims.is_empty() and aims.all(func(a): return a[2] >= 8 and a[2] <= 10), aims)
	Kit.fresh()


func _thirteen_scene() -> void:
	Kit.fresh()
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	await _frames(2)
	var ci := -1
	for i in scene.floors.size():
		if scene.floors[i].name == "TEST · Corridor":
			ci = i
	var r: Roster = scene.roster
	scene.start_battle(ci, [r.card_named("Test Warden"), r.card_named("Test Striker")], [], 6)
	await _frames(3)
	var bt: Battle = scene.battle
	_place(scene, "a1", Vector2i(0, 0))
	_place(scene, "e1", Vector2i(3, 0))
	var foe = bt.unit_by_id("e1")
	foe["guards"] = {"stunned": false}
	Rules.add_status(foe, "Slowed", 1, null, 2)
	scene.board.refresh_units(bt)
	await _frames(2)
	var fv: UnitView = scene.board.view_of("e1")
	ck("0.13 badge: a guarded Unit wears a ring for it beside its Status dots", fv.shown["guards"] == ["stunned"] and fv.shown["statuses"].size() == 1, fv.shown)
	_tap(scene, Battle.tile_of(foe))
	await _frames(2)
	var chips: Array = []
	for ch in scene.panel.chips.get_children():
		chips.append((ch.get_child(1) as Label).text)
	ck("0.13 badge: the side panel says it at a glance", chips.has("Guarded: Stunned") and chips.has("Slowed 1"), chips)
	var txt := _panel_text(scene)
	ck("0.13 badge: and under Statuses, how long for and why", txt.any(func(t): return t.begins_with("Guarded: Stunned") and "for a round" in t) and txt.any(func(t): return "can't be Stunned again until the same point of the next round" in t), txt)
	foe.erase("guards")
	scene.board.refresh_units(bt)
	await _frames(1)
	ck("0.13 badge: once the guard is gone, so is the ring", fv.shown["guards"].is_empty())
	scene.queue_free()
	await _frames(2)

	# ---- the Workshop: a to-hit steps no better than the chassis's best
	Kit.fresh()
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	var wsn: WorkshopScreen = scene.workshop_screen
	var ed: DesignEditor = wsn.editor
	scene.open_dock()
	scene.open_workshop()
	await _frames(2)
	wsn.new_btn.pressed.emit()
	await _frames(1)
	wsn.tap_row(wsn._rows[0])
	await _frames(2)
	ck("0.13 editor: the chassis says its to-hit at best", _labels(ed).any(func(l): return l.begins_with("Attacks up to range 5 and AP 5, to-hit 5 at best")), _labels(ed))
	ck("0.13 editor: the To-Hit stepper says its best", _labels(ed).has("best 5"), _labels(ed))
	for i in 3:
		ed.act(["num", 0, "hit", -1])
	ck("0.13 editor: stepping down stops at the best", ed.d["abilities"][0]["hit"] == 5, ed.d["abilities"][0])
	for i in 20:
		ed.act(["num", 0, "hit", 1])
	ck("0.13 editor: stepping up stops at 20", ed.d["abilities"][0]["hit"] == 20, ed.d["abilities"][0])
	scene.queue_free()
	await _frames(2)
	Kit.fresh()


# ---------------------------------------------------------------- 0.14: the look of a fight
## Every special character the game's scripts write: {code: file}.
func _chars_written() -> Dictionary:
	var seen := {}
	var esc := RegEx.new()
	esc.compile("\\\\u([0-9a-fA-F]{4})")
	for f in DirAccess.get_files_at("res://scripts"):
		if not f.ends_with(".gd"):
			continue
		for line in FileAccess.get_file_as_string("res://scripts/" + f).split("\n"):
			if line.strip_edges().begins_with("#"):
				continue
			for m in esc.search_all(line):
				seen[m.get_string(1).hex_to_int()] = f
			for i in line.length():
				if line.unicode_at(i) > 127:
					seen[line.unicode_at(i)] = f
	return seen


## Two pictures the same, pixel for pixel (where a pixel is see-through, only that it is).
func _same_pixels(a: Texture2D, b: Texture2D) -> bool:
	if a == null or b == null or a.get_size() != b.get_size():
		return false
	var ia := a.get_image()
	var ib := b.get_image()
	for y in ia.get_height():
		for xx in ia.get_width():
			var ca := ia.get_pixel(xx, y)
			var cb := ib.get_pixel(xx, y)
			if (ca.a > 0.0) != (cb.a > 0.0) or (ca.a > 0.0 and ca.to_html(false) != cb.to_html(false)):
				return false
	return true


func _fourteen() -> void:
	Kit.fresh()
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)

	# ---- type: VT323 for what you read, Jersey 10 for titles and numbers, each at its own pixels
	var body := Look.body()
	ck("0.14 type: VT323 is the body face, its pixels unsmoothed, not Jersey 10 standing in", body is FontFile and body != Look.font() and body.get_font_name().begins_with("VT323") and (body as FontFile).antialiasing == TextServer.FONT_ANTIALIASING_NONE and FileAccess.file_exists("res://fonts/OFL-VT323.txt"), body.get_font_name() if body != null else "none")
	var on_px := func(size: int, per: float) -> bool: return absf(size / per - roundf(size / per)) < 0.05 and roundf(size / per) >= 1.0
	ck("0.14 type: every size lands on whole pixels of its face: Jersey 10 at 1, 2 and 3; VT323 at 2 and 4", on_px.call(Look.SMALL, 1400.0 / 75.0) and on_px.call(Look.TITLE, 1400.0 / 75.0) and on_px.call(Look.HUGE, 1400.0 / 75.0) and on_px.call(Look.BODY, 12.5) and on_px.call(Look.BODY_BIG, 12.5), [Look.SMALL, Look.TITLE, Look.HUGE, Look.BODY, Look.BODY_BIG])
	var missing := {}
	var written := _chars_written()
	for c in written:
		if c != 0x25c7 and not body.has_char(c):
			missing[String.chr(c)] = written[c]
	ck("0.14 type: VT323 has every special character the game writes, too", missing.is_empty() and written.has(0xb7) and written.has(0x2026), missing)
	var rd := Look.read("Words")
	var tt := Look.title("Words")
	var sm := Label.new()
	var md := Label.new()
	var bg := Label.new()
	Look.size_to(sm, 12)
	Look.size_to(md, 17)
	Look.size_to(bg, 23)
	ck("0.14 type: words to read are VT323 at 25; titles Jersey 10 at 37; an old size goes to the nearest of the two faces' own",
		rd.get_theme_font("font") == body and rd.get_theme_font_size("font_size") == Look.BODY and tt.get_theme_font("font") == Look.font() and tt.get_theme_font_size("font_size") == Look.TITLE
		and sm.get_theme_font("font") == Look.font() and sm.get_theme_font_size("font_size") == Look.SMALL and md.get_theme_font("font") == body and md.get_theme_font_size("font_size") == Look.BODY
		and bg.get_theme_font("font") == Look.font() and bg.get_theme_font_size("font_size") == Look.TITLE)
	for l in [rd, tt, sm, md, bg]:
		l.free()

	# ---- the UI kit
	var th := Look.fight_theme()
	ck("0.14 kit: a fight's theme reads in VT323, with a main, a danger and an icon button, an inset and a tooltip",
		th.default_font == body and th.default_font_size == Look.BODY and ["MainButton", "DangerButton", "IconButton"].all(func(v): return th.get_type_variation_base(v) == "Button" and th.has_stylebox("normal", v) and th.has_stylebox("pressed", v) and th.has_stylebox("disabled", v))
		and th.get_type_variation_base("Inset") == "PanelContainer" and th.get_type_variation_base("Tooltip") == "PanelContainer")
	ck("0.14 kit: the main button is gold with dark words; the danger one red", (th.get_stylebox("normal", "MainButton") as PixelBox).bg_color == Look.MAIN and th.get_color("font_color", "MainButton") == Look.INK and (th.get_stylebox("normal", "DangerButton") as PixelBox).bg_color == Color("#7e0e0e"))
	ck("0.14 kit: an icon button lights cyan while it is on", (th.get_stylebox("pressed", "IconButton") as PixelBox).border_color == Look.YOURS)

	# ---- the drawn art: art.json, its four sheets, every piece cut from them
	var m := Art.manifest()
	var cut := []
	for kind in ["tokens", "board", "icons", "marks", "cards"]:
		var sheet := Art._sheet(Art.SHEET_OF[kind])
		for k in m.get(kind, {}):
			var rc: Array = m[kind][k]["rect"]
			var tex := Art.piece(kind, k)
			if tex == null or sheet == null or rc[0] + rc[2] > sheet.get_width() or rc[1] + rc[3] > sheet.get_height() or tex.get_size() != Vector2(rc[2], rc[3]):
				cut.append(kind + "/" + k)
	ck("0.14 art: art.json and its four sheets: every piece is cut from its sheet", m.get("tokens", {}).size() >= 70 and m.get("board", {}).size() >= 20 and m.get("icons", {}).size() >= 33 and m.get("marks", {}).size() >= 22 and m.get("cards", {}).size() == 7 and cut.is_empty(), cut)
	var sized := func(kind: String, w: int, h: int, only: String) -> bool:
		return m[kind].keys().filter(func(k): return only == "" or Keywords._re(only).search(k) != null).all(func(k): return int(m[kind][k]["rect"][2]) == w and int(m[kind][k]["rect"][3]) == h)
	ck("0.14 art: every token is 48 by 48, a tile's plate, pad or hazard 42 by 48, an icon 16, a mark 8, a card's picture 64 by 45",
		sized.call("tokens", 48, 48, "") and sized.call("board", 42, 48, "^(floor|pad|hazard)_") and sized.call("icons", 16, 16, "") and sized.call("marks", 8, 8, "") and sized.call("cards", 64, 45, ""))
	var pal := {}
	for c in Art.palette():
		pal[c.to_html(false)] = true
	var off := []
	for s in ["tokens", "board", "icons", "cards"]:
		var img: Image = Art._sheet(s).get_image()
		var found := false
		for y in img.get_height():
			for xx in img.get_width():
				var c := img.get_pixel(xx, y)
				if c.a > 0.0 and (c.a < 1.0 or not pal.has(c.to_html(false))):
					off.append([s, xx, y, c.to_html(true)])
					found = true
					break
			if found:
				break
	ck("0.14 art: every pixel of it is on the Pixel Studio's palette, and there or not, never half", off.is_empty(), off)

	# ---- tokens
	var masters := x.cards().filter(func(c): return CardFace.UNITS.has(Roster.type_of(c)) and not str(c.get("name", "")).begins_with("Test"))
	ck("0.14 tokens: every master Unit stands on the board as itself", masters.size() >= 60 and masters.all(func(c): return not r.token_for(c).is_empty()), masters.filter(func(c): return r.token_for(c).is_empty()).map(func(c): return c["name"]))
	ck("0.14 tokens: the game draws every one of them that isn't a Workshop design", masters.filter(func(c): return not str(c.get("id", "")).begins_with("WS-")).all(func(c): return r.token_for(c).get("drawn", false)),
		masters.filter(func(c): return not str(c.get("id", "")).begins_with("WS-") and not r.token_for(c).get("drawn", false)).map(func(c): return c["name"]))
	ck("0.14 tokens: found by the card's number, so a renamed card keeps its token; never a stand-in's", Art.token_drawn({"id": "D3-T21", "name": "Something Else"}) == Art.piece("tokens", "aether_battery") and Art.token_drawn({"name": "Aether Battery"}) == Art.piece("tokens", "aether_battery")
		and Art.token_drawn({"name": "No Such Unit"}) == null and Art.token_drawn({"name": "Standin Melee"}) == null)
	ck("0.14 tokens: a picture in the export comes first", not r.token_for(r.card_named("Test Warden")).is_empty() and not r.token_for(r.card_named("Test Warden")).get("drawn", false))
	ck("0.14 tokens: the five body plans, and the four stand-ins", ["Bipedal", "Quadcopter", "Quadruped", "Hexapod", "Octopod"].all(func(p): return Art.body_token(p) != null) and ["melee", "ranged", "drone", "beast"].all(func(k): return Art.standin(k) != null)
		and r.token_for({"name": "A Design", "bodyPlan": "Hexapod"}).get("texture") == Art.body_token("Hexapod"))
	var fits := []
	var feet := false
	for n in [48, 24, 16, 32]:
		var v := UnitView.new()
		root.add_child(v)
		v.setup({"id": "t", "name": "Fit", "side": "ally", "hp": 5, "hpMax": 5, "statuses": [], "pos": {"q": 0, "r": 0}}, {"texture": ImageTexture.create_from_image(Image.create(n, n, false, Image.FORMAT_RGBA8))}, Board.SIZE)
		fits.append(v.token.scale.x)
		if n == 48:
			feet = (v.token.offset + Vector2(24, 46)) * v.token.scale.x == UnitView.FOOT and v.token.offset == v.token.offset.round()
		v.free()
	ck("0.14 tokens: a 48 token stands at the board's scale, a 24 at twice it, a 16 at three times, a 32 at it", fits == [2.0, 4.0, 6.0, 2.0], fits)
	ck("0.14 tokens: its feet on the spot it stands on, on whole pixels", feet)
	var kinds := []
	for u in [{"name": "Scout Drone"}, {"name": "Rust Hound"}, {"name": "Rifleman", "actions": [{"role": "Ranged"}]}, {"name": "Brawler", "actions": [{"role": "Melee"}]}]:
		var sv := UnitView.new()
		root.add_child(sv)
		u.merge({"id": "s", "side": "enemy", "hp": 5, "hpMax": 5, "statuses": [], "pos": {"q": 0, "r": 0}})
		sv.setup(u, {}, Board.SIZE)
		kinds.append([sv.standing_in, sv.token.texture == Art.standin(sv.standing_in), sv.token.scale.x])
		sv.free()
	ck("0.14 tokens: one with no token stands in as a shape of its kind: a drone, a beast, a shooter or a fighter", kinds == [["drone", true, 2.0], ["beast", true, 2.0], ["ranged", true, 2.0], ["melee", true, 2.0]], kinds)

	# ---- icons, marks and gems
	var sts: Array = UnitView.STATUS_DOT.keys()
	ck("0.14 art: every Status has its icon, and its mark on the board", sts.all(func(s): return Art.status_icon(s) != null and Art.status_mark(s) != null) and Art.status_mark("guarded") != null and Art.status_mark("overwatch") != null,
		sts.filter(func(s): return Art.status_icon(s) == null or Art.status_mark(s) == null))
	ck("0.14 art: a gem for each District's Aether and one for any, by either spelling", range(1, 7).all(func(i): return Art.status_mark("gem_%d" % i) != null and Art.status_mark("gem %d" % i) != null) and Art.status_mark("gem_any") != null and Art.status_mark("gem_3") != Art.status_mark("gem_4"))
	ck("0.14 art: the bar's icons, the roles', the Actions' and the Districts'", ["bar_undo", "bar_auto", "bar_log", "bar_fit", "bar_leave", "role_melee", "role_ranged", "role_support", "role_cyber", "act_move", "act_attack", "act_end"].all(func(k): return Art.icon2(k) != null) and range(1, 7).all(func(i): return Art.icon2("district_%d" % i) != null))
	var ctypes := {}
	for c in x.cards():
		if not CardFace.UNITS.has(Roster.type_of(c)):
			ctypes[Roster.type_of(c)] = Art.card_standin(Roster.type_of(c)) != null
	ck("0.14 art: every kind of card that isn't a Unit has a picture of its kind, until it has art of its own", ctypes.size() >= 6 and ctypes.values().all(func(v): return v), ctypes)
	ck("0.14 art: the board's pieces: the deck's plates, both pads, five hazards, two of each cover, and what stands on a tile", Board.FLOORS.all(func(k): return not Art.board(k).is_empty())
		and ["pad_yours", "pad_theirs", "hazard_acid", "hazard_sparks", "hazard_razor", "hazard_sludge", "hazard_fire", "half_cover_a", "half_cover_b", "full_cover_a", "full_cover_b", "crate", "locked_chest", "emergency_exit", "healing_station"].all(func(k): return not Art.board(k).is_empty() and Art.board(k)["mine"] == false))

	# ---- your drawings take the place of the game's, piece by piece
	var yours := ImageTexture.create_from_image(Image.create(32, 32, false, Image.FORMAT_RGBA8))
	Art._mine = {"fight.crate": yours, "ui.status.stunned": yours, "ui.mark.gem_3": yours, "ui.icon.bar_log": yours, "ui.card.action": yours, "fight.standin.melee": yours}
	ck("0.14 art: a drawing of yours in a slot is used instead of the game's: a prop, a Status, a gem, an icon, a card's picture, a stand-in",
		Art.board("crate").get("texture") == yours and Art.board("crate").get("mine") == true and Art.board("crate").get("foot") == Vector2(16, 27) and Art.status_icon("Stunned") == yours and Art.status_mark("gem 3") == yours and Art.icon2("bar_log") == yours and Art.card_standin("action") == yours
		and Art.standin("melee") == yours)
	ck("0.14 art: and the rest stay the game's", Art.board("locked_chest").get("mine") == false and Art.status_icon("Rooted") != yours and Art.status_mark("gem_4") != yours and Art.icon2("bar_fit") != yours and Art.card_standin("command") != yours and Art.standin("drone") != yours)
	Art.load_from(null)
	# through the Companion's export (the fixture drew over the game's crate in its slot)
	Art.load_from(x)
	var crate: Texture2D = Art.board("crate").get("texture")
	ck("0.14 export: the game's crate, drawn over in the Companion, comes in the export and is used", Art.is_mine("fight.crate") and Art.board("crate")["mine"] == true and crate != null and crate.get_size() == Vector2(32, 32)
		and crate.get_image().get_pixel(10, 2).to_html(false) == "6dff3a", crate.get_image().get_pixel(10, 2).to_html(false) if crate != null else null)
	var games_own := ["fight.locked_chest", "fight.floor_bolts", "fight.standin.melee", "ui.status.stunned", "ui.mark.gem_3", "ui.icon.bar_log", "ui.card.action"]
	ck("0.14 export: the game's own pictures nobody drew on stay out of it, a master Unit's token too", not games_own.any(func(sl): return Art.is_mine(sl)) and x.card_file("Aether Battery", "token").is_empty() and r.token_for(r.card_named("Aether Battery")).get("drawn", false))
	var bp := x.picture_file("px_skin_bipedal_token")
	ck("0.14 export: a body plan's stand-in token is the game's drawing of it, 48 by 48", not bp.is_empty() and int(bp.get("w", 0)) == 48 and int(bp.get("h", 0)) == 48 and bp.get("grid") == "square"
		and _same_pixels(x.texture(str(bp["file"])), Art.body_token("Bipedal")), bp)
	Art.load_from(null)

	# ---- the grid: every tile on whole art pixels
	var back := true
	var whole := true
	for q in range(-8, 9):
		for rr in range(-8, 9):
			var h := Vector2i(q, rr)
			var c := Board.at(h)
			if Board.hex_at(c) != h or Board.hex_at(c + Vector2(38, 0)) != h or Board.hex_at(c + Vector2(0, -44)) != h or Board.hex_at(c + Vector2(-28, 28)) != h:
				back = false
			for p in Board.corners(c):
				if fmod(absf(p.x), Board.PIXEL) != 0.0 or fmod(absf(p.y), Board.PIXEL) != 0.0:
					whole = false
	ck("0.14 grid: every tile's centre, and a point just inside its edges, maps back to it", back)
	ck("0.14 grid: every tile's corners land on whole art pixels (two world units)", whole)
	ck("0.14 grid: a column is 42 art pixels, a row 36, each row half a column over", Board.at(Vector2i(1, 0)) == Vector2(84, 0) and Board.at(Vector2i(0, 1)) == Vector2(42, 72) and Board.at(Vector2i(-1, 2)) == Vector2(0, 144))
	var meet := true
	for d in Hex.DIRS:
		var a0 := Vector2i(2, -1)
		var e1 := Board.shared_edge(a0, a0 + d)
		var e2 := Board.shared_edge(a0 + d, a0)
		if e1.size() != 2 or e2.size() != 2 or not ((e1[0] == e2[1] and e1[1] == e2[0]) or (e1[0] == e2[0] and e1[1] == e2[1])) or not ((e1[0] + e1[1]) / 2.0).is_equal_approx((Board.at(a0) + Board.at(a0 + d)) / 2.0):
			meet = false
	ck("0.14 grid: neighbours share an edge, end to end, halfway between them: where a wall stands", meet and Board.shared_edge(Vector2i(0, 0), Vector2i(2, 0)).is_empty())
	ck("0.14 grid: a point just past an edge is the neighbour's; a rectangle snaps to the art's pixels", Board.hex_at(Board.at(Vector2i(0, 0)) + Vector2(44, 0)) == Vector2i(1, 0) and Board.snap_rect(Rect2(3.2, 5.9, 10.7, 3.1)) == Rect2(4, 6, 10, 4))

	# ---- the board: what stands on the floor, sorted with the Units
	var bd := Board.new()
	root.add_child(bd)
	var props_ok := true
	var seen_props := {}
	var walls_ok := true
	var all_walls := 0
	var on_px_props := true
	for f in x.floors():
		bd.show_floor(f)
		for h in f.tiles:
			var want := ""
			match Board.tile_kind(f, h):
				"cover-half": want = "half_cover"
				"cover-full": want = "full_cover"
				"loot": want = "crate"
				"healing": want = "healing_station"
			match Board.symbol_kind(f, h):
				"chest": want = "locked_chest"
				"exit": want = "emergency_exit"
			var got := str(bd.props[h].get_meta("prop")) if bd.props.has(h) else ""
			if not got.begins_with(want) or (want == "" and got != ""):
				props_ok = false
			if got != "":
				seen_props[got.trim_suffix("_a").trim_suffix("_b")] = true
				var s: Sprite2D = bd.props[h]
				var tl := s.position + s.offset * s.scale.x
				if s.scale != Vector2(Board.PIXEL, Board.PIXEL) or fmod(absf(tl.x), Board.PIXEL) != 0.0 or fmod(absf(tl.y), Board.PIXEL) != 0.0 or s.get_parent() != bd.units_layer:
					on_px_props = false
		all_walls += f.walls.size()
		if bd.wall_pieces.size() != f.walls.size() or not bd.wall_pieces.all(func(w): return w.get_parent() == bd.units_layer):
			walls_ok = false
	ck("0.14 board: cover, crates, Locked Chests and the Emergency Exit stand on their tiles as themselves", props_ok and ["half_cover", "full_cover", "crate", "locked_chest", "emergency_exit"].all(func(k): return seen_props.has(k)), seen_props.keys())
	ck("0.14 board: each is drawn at the board's scale, on whole art pixels, in the layer the Units stand in", on_px_props and bd.units_layer.y_sort_enabled)
	ck("0.14 board: every wall stands on its edge, in that layer too", walls_ok and all_walls >= 10, all_walls)
	var hc := _floor_named(x, "TEST · Hazards and Cover")
	bd.show_floor(hc)
	var cover_at: Array = bd.props.keys().filter(func(h): return "cover" in str(bd.props[h].get_meta("prop")))
	var cover_front: bool = not cover_at.is_empty() and cover_at.all(func(h): return bd.props[h].position.y > Board.at(h).y)
	var lf := _floor_named(x, "TEST · Loot")
	bd.show_floor(lf)
	var behind := true
	var hatch := false
	var crate_at := Vector2i(99, 99)
	for h in bd.props:
		var nm := str(bd.props[h].get_meta("prop"))
		if nm in ["crate", "locked_chest"] and bd.props[h].position.y >= Board.at(h).y:
			behind = false
		if nm == "crate":
			crate_at = h
		if nm == "emergency_exit":
			hatch = bd.props[h].position.y < Board.at(h).y - 30.0
	ck("0.14 board: a Unit on cover stands behind it; on a crate or a chest, in front of it; on an Exit, over the hatch", cover_front and behind and hatch)
	bd.set_searched({crate_at: true})
	ck("0.14 board: a Loot Tile once emptied is dimmed", bd.props.has(crate_at) and bd.props[crate_at].modulate != Color.WHITE and bd.props.keys().filter(func(h): return h != crate_at).all(func(h): return bd.props[h].modulate == Color.WHITE))
	bd.free()
	ck("0.14 board: a hazard wears what it does: acid, sparks, razor wire, sludge or fire", Board.hazard_art({"keyword": "Poisoned 2"}) == "hazard_acid" and Board.hazard_art({"keyword": "Stunned"}) == "hazard_sparks" and Board.hazard_art({"keyword": "Drained 1"}) == "hazard_sparks"
		and Board.hazard_art({"keyword": "Bleed 2"}) == "hazard_razor" and Board.hazard_art({"keyword": "Sundered"}) == "hazard_razor" and Board.hazard_art({"keyword": "Slowed 1"}) == "hazard_sludge" and Board.hazard_art({"keyword": "Rooted"}) == "hazard_sludge"
		and Board.hazard_art({"keyword": "damage 3"}) == "hazard_fire" and Board.hazard_art({}) == "hazard_fire")

	# ---- the printed card
	ck("0.14 card: printed at two sizes, a tile's and a sheet's, the same shape", CardFace.SMALL == CardTile.SIZE and CardFace.LARGE == Vector2(360, 504) and is_equal_approx(CardFace.SMALL.x / CardFace.SMALL.y, CardFace.LARGE.x / CardFace.LARGE.y))
	var words := CardFace.rules_words(r.card_named("Test Snare"))
	ck("0.14 card: its rules as the Forge prints them: no markup, its keywords in their colours", not words.is_empty() and not words.any(func(w): return "[[" in str(w[0]) or "]]" in str(w[0])) and words.any(func(w): return w[0] == "Rooted" and w[1] != UI.PALE) and words.any(func(w): return w[0] == "gains" and w[1] == UI.PALE), words.map(func(w): return w[0]))
	var named := CardFace.rules_words(r.card_named("Test Scout"))
	ck("0.14 card: a Unit's card names each Action in white before what it does", named.size() > 2 and named[0][0] == "Quick" and named[1][0] == "Shot:" and named[1][1] == UI.TEXT)
	ck("0.14 card: its cost as gems: its District's, then any", CardFace.cost_gems(r.card_named("Test Snare")) == [["gem_3", 1], ["gem_any", 1]] and CardFace.cost_gems(r.card_named("Test Mortar Strike")) == [["gem_any", 2]], CardFace.cost_gems(r.card_named("Test Snare")))
	ck("0.14 card: a Unit's numbers along its bottom", CardFace.stat_line(r.card_named("Test Warden")).begins_with("HP ") and CardFace.stat_line(r.card_named("Test Snare")) == "")
	var wl := CardFace.wrap_lines(body, Look.BODY, "one two three four five six seven eight nine ten eleven twelve", 120.0, 2)
	ck("0.14 card: words wrap to fit, and what doesn't fit ends in …", wl.size() == 2 and str(wl[1]).ends_with("…") and wl.all(func(l): return body.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, Look.BODY).x <= 120.0), wl)
	var ww := CardFace.wrap_words(body, Look.BODY, [["takes", UI.PALE], ["damage", Color.RED], [".", UI.PALE]], 1000.0, 3)
	ck("0.14 card: a stop sits against the word before it", ww.size() == 1 and ww[0].size() == 2 and ww[0][1].size() == 3 and ww[0][1][2][0] == ".", ww)
	ck("0.14 card: its District's colour round its edge", CardFace.colours(r.card_named("Test Snare"))[0] == Color(CardFace.DISTRICT["3"][0]) and CardFace.colours({"name": "Plain"})[0] == Color(CardFace.DISTRICT[""][0]))

	# ---- the hand, as a fan
	var fan := CardFan.new()
	root.add_child(fan)
	fan.size = Vector2(1200, 240)
	fan.set_items(["Test Scout", "Test Snare", "Test Rally"].map(func(n): return {"card": r.card_named(n)}))
	ck("0.14 fan: a few cards sit side by side, a gap apart, in the middle", fan.tiles.size() == 3 and fan.step() == CardTile.SIZE.x + CardFan.GAP and is_equal_approx(fan.tiles[0].position.x + fan.tiles[2].position.x + CardTile.SIZE.x, 1200.0), fan.tiles.map(func(t): return t.position))
	var many := []
	for i in 12:
		many.append({"card": r.card_named("Test Scout")})
	fan.set_items(many)
	ck("0.14 fan: more than fit overlap, a good part of each showing, none off the edge", fan.tiles.size() == 12 and fan.step() < CardTile.SIZE.x and fan.step() >= 40.0 and fan.tiles[0].position.x >= 8.0 and fan.tiles[11].position.x + CardTile.SIZE.x <= 1200.0 - 7.0, [fan.step(), fan.tiles[11].position.x])
	var tapped := []
	fan.card_tapped.connect(func(i): tapped.append(i))
	fan.tap(fan.tile_centre(4))
	ck("0.14 fan: a tap reads the card on top there, and it stands up out of the fan", tapped == [4] and fan.lifted == 4 and fan.tiles[4].position.y == 0.0 and fan.tiles[3].position.y == CardFan.LIFT, tapped)
	ck("0.14 fan: where two overlap, the later one is on top", fan.tile_at(fan.tiles[5].position + Vector2(5, 100)) == 5 and fan.tile_at(Vector2(2, 2)) == -1)
	fan.set_items([])
	fan.empty_text = "Your hand is empty."
	fan.set_items([])
	ck("0.14 fan: an empty hand says so", fan.tiles.is_empty() and fan._empty != null and fan._empty.text == "Your hand is empty.")
	fan.free()

	# ---- Aether, as gems
	var ag := AetherGems.new()
	ag.show_pool({"generic": 2, "d3": 3, "d5": 0})
	ck("0.14 Aether: a gem for each point, in its District's colour, Aether of any kind last", ag.gems() == ["gem_3", "gem_3", "gem_3", "gem_any", "gem_any"] and ag.gems().all(func(g): return Art.status_mark(g) != null), ag.gems())
	ag.show_pool({"generic": 20})
	var wide := ag.width()
	ag.show_pool({})
	ck("0.14 Aether: past ten, a number says the rest; none, a dash", wide > AetherGems.STEP * AetherGems.MOST and ag.gems().is_empty() and ag.width() == 22.0)
	ag.free()

	# ---- the zoom: whole steps
	var M = load("res://scripts/main.gd")
	ck("0.14 zoom: the board rests at whole steps: 1, 2, 3 or 4 screen pixels to an art pixel", M.ZOOM_STEPS == [0.5, 1.0, 1.5, 2.0])
	ck("0.14 zoom: the step at or below a zoom (a floor too big for the smallest keeps what fits it)", M.step_below(0.8) == 0.5 and M.step_below(1.0) == 1.0 and M.step_below(1.49) == 1.0 and M.step_below(3.0) == 2.0 and M.step_below(0.3) == 0.3)
	ck("0.14 zoom: and the step nearest it, after a pinch", M.step_near(1.2) == 1.0 and M.step_near(1.3) == 1.5 and M.step_near(0.6) == 0.5 and M.step_near(0.3) == 0.3)
	var snap_ok := true
	for z in M.ZOOM_STEPS:
		var p: Vector2 = M._snap_cam(Vector2(123.37, -45.81), z)
		if not (p * z).is_equal_approx((p * z).round()) or p.distance_to(Vector2(123.37, -45.81)) > 1.0 / z:
			snap_ok = false
	ck("0.14 zoom: at a step, the camera sits where the board's pixels are the screen's", snap_ok and M._snap_cam(Vector2(1.3, 2.7), 0.8) == Vector2(1.3, 2.7))
	Kit.fresh()


func _fourteen_scene() -> void:
	Kit.fresh()
	# a phone's screen, on its side (headless, the window is square)
	var was_size: Vector2i = root.size
	root.size = Vector2i(1280, 720)
	var team: Dictionary = Kit.team()
	Kit.keep([team])
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	var r: Roster = scene.roster
	var fi := -1
	for i in scene.floors.size():
		if scene.floors[i].name == "TEST · Hazards and Cover":
			fi = i
	scene.start_team_battle(fi, team, StrikeTeams.setup_for(team, r, ["Test Warden", "Quillon Vex"], "Test Warden", ["Test Drone"], 3), 21)
	await _frames(3)
	var bt: Battle = scene.battle
	var cam: Camera2D = scene.camera
	var steps: Array = load("res://scripts/main.gd").ZOOM_STEPS
	var vp: Rect2 = scene.get_viewport_rect()
	var xf: Transform2D = scene.get_viewport().get_canvas_transform()

	# ---- the view
	ck("0.14 view: a fight opens at a whole step: one art pixel to two screen pixels, or closer, where the whole floor won't fit at that", vp.size == Vector2(1280, 720) and steps.has(cam.zoom.x) and cam.zoom.x >= 1.0, [cam.zoom, vp])
	ck("0.14 view: on whole screen pixels", (cam.position * cam.zoom.x).is_equal_approx((cam.position * cam.zoom.x).round()), cam.position)
	ck("0.14 view: your Units in view", bt.side_units("ally").all(func(u): return vp.has_point(xf * scene.board.to_global(Board.at(Battle.tile_of(u))))))
	var mid := vp.size / 2.0
	var z0: float = cam.zoom.x
	var i0 := steps.find(z0)
	var seen_z := []
	for d in [1, -1, -1, 1]:
		scene._wheel(d, mid)
		seen_z.append(cam.zoom.x)
	ck("0.14 view: the wheel zooms a whole step at a time", seen_z == [steps[mini(i0 + 1, 3)], z0, steps[maxi(i0 - 1, 0)], z0], seen_z)
	cam.zoom = Vector2(1.3, 1.3)
	scene._settle_zoom(mid)
	await create_timer(0.4).timeout
	ck("0.14 view: after a pinch it settles on the nearest step, on whole pixels", cam.zoom.x == 1.5 and (cam.position * 1.5).is_equal_approx((cam.position * 1.5).round()), [cam.zoom, cam.position])
	cam.zoom = Vector2(z0, z0)

	# ---- the bar
	var bar_btns: Array = [scene.aether_btn, scene.undo_btn, scene.auto_btn, scene.speed_btn, scene.log_btn, scene.fit_btn, scene.new_btn, scene.next_btn]
	ck("0.14 bar: End turn is the one gold button", scene.next_btn.theme_type_variation == "MainButton" and bar_btns.filter(func(b): return b.theme_type_variation == "MainButton").size() == 1)
	ck("0.14 bar: Undo, Auto, Log, Fit and Leave are icons, each named in its tooltip", [[scene.undo_btn, "Undo"], [scene.auto_btn, "Auto: off"], [scene.log_btn, "Log"], [scene.fit_btn, "Fit"], [scene.new_btn, "Leave"]].all(func(p): return p[0].icon != null and p[0].text == "" and p[0].tooltip_text == p[1] and p[0].theme_type_variation == "IconButton"),
		[scene.auto_btn.tooltip_text, scene.log_btn.tooltip_text])
	ck("0.14 bar: where you are reads in VT323, the round in Jersey 10", scene.floor_label.get_theme_font("font") == Look.body() and scene.round_label.get_theme_font("font") == Look.font() and scene.round_label.text == "Round %d" % bt.round)
	bt.aether = {"generic": 2, "d3": 3}
	scene._update_bar()
	await _frames(1)
	ck("0.14 bar: your Aether as gems on its button, in words in its tooltip", scene.aether_btn.visible and scene.aether_gems.get_parent() == scene.aether_btn and scene.aether_gems.gems().size() == 5 and scene.aether_btn.tooltip_text == "Aether " + UI.show(Battle.aether_label(bt.aether))
		and scene.aether_btn.size.x >= scene.aether_gems.position.x + scene.aether_gems.width(), [scene.aether_btn.tooltip_text, scene.aether_btn.size])
	scene.toggle_auto()
	await _frames(1)
	ck("0.14 bar: Auto stays lit while it is on", scene.auto_btn.button_pressed and scene.auto_btn.tooltip_text == "Auto: on")
	scene.toggle_auto()
	await _frames(1)

	# ---- the board
	var views: Array = scene.board.views.values()
	ck("0.14 board: every Unit stands on its tile, in the sorted layer, with the cover", not views.is_empty() and views.all(func(v): return v.get_parent() == scene.board.units_layer and v.position == Board.at(Battle.tile_of(v.unit))) and scene.board.props.size() == 4)
	ck("0.14 board: each wears its token: none stands in", views.all(func(v): return v.standing_in == "" and v.token.texture != null))
	var fv: UnitView = scene.board.view_of("e1")
	Rules.add_status(bt.unit_by_id("e1"), "Slowed", 1, null, 2)
	scene.board.refresh_units(bt)
	await _frames(1)
	ck("0.14 board: a Status shows as its mark", fv.shown["statuses"].size() == 1 and Art.status_mark("Slowed") != null)

	# ---- the bottom line: one line; a "?" reads all of it
	scene._say("A short line.")
	await _frames(1)
	var short_hidden: bool = not scene.info_more.visible
	scene._say("A long line that goes on. ".repeat(30).strip_edges())
	await _frames(2)
	var mr: Rect2 = scene.info_more.get_global_rect()
	ck("0.14 bottom line: a long one is cut with …, and a ? on the screen reads the rest", short_hidden and scene.info_more.visible and vp.encloses(mr) and mr.size.x >= 40.0 and scene.info.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS and mr.position.x >= scene.info.get_global_rect().end.x - 1.0, [short_hidden, mr, scene.info.get_global_rect()])
	scene.info_more.pressed.emit()
	await _frames(2)
	ck("0.14 bottom line: the ? opens all of it", scene.dialog != null and scene.dialog.text_label.text.begins_with("A long line that goes on.") and scene.dialog.text_label.text.length() > 500)
	if scene.dialog != null:
		scene._close_dialog()
		await _frames(2)

	# ---- the banner: the phase named once
	scene._announce("Enemy phase", "Enemy phase: the Enemies close in.")
	ck("0.14 banner: the phase's name is said once, as its title", scene.banner_title.text == "Enemy phase" and scene.banner_text.text == "The Enemies close in.", scene.banner_text.text)
	scene.banner.visible = false

	# ---- the hand, and a card's sheet
	bt.hand = ["Test Scout", "Test Plating", "Test Mortar Strike", "Test Snare"].map(func(n): return _hc(r, n))
	scene._update_bar()
	scene.hand_btn.pressed.emit()
	await _frames(3)
	var tray: HandTray = scene.hand_tray
	ck("0.14 hand: a fan of whole printed cards", tray.visible and tray.grid is CardFan and tray.grid.tiles.size() == 4 and tray.grid.tiles.all(func(t): return t.size == CardTile.SIZE))
	ck("0.14 hand: all of them on the screen, above the bottom edge", tray.grid.tiles.all(func(t): return vp.encloses(t.get_global_rect())), tray.grid.tiles.map(func(t): return t.get_global_rect()))
	tray.grid.tap(tray.grid.tile_centre(2))
	await _frames(2)
	var face = scene.sheet.get_meta("face") if scene.sheet != null else null
	ck("0.14 sheet: a card's sheet shows the card itself, large, as printed", face is CardFace.Face and face.size == CardFace.LARGE and face.card["name"] == "Test Mortar Strike" and vp.encloses(face.get_global_rect()), face.get_global_rect() if face is Control else null)
	ck("0.14 sheet: what it says, in VT323", scene.sheet != null and scene.sheet.note_label.get_theme_font("font") == Look.body())
	scene._close_sheet()
	await _frames(2)
	if tray.visible:
		scene.hand_btn.pressed.emit()
		await _frames(2)

	# ---- the side panel
	_tap(scene, Battle.tile_of(bt.unit_by_id("a1")))
	await _frames(2)
	var pnl: UnitPanel = scene.panel
	ck("0.14 panel: the Unit's token, large, in the fight's theme", pnl.visible and pnl.pic.texture != null and pnl.pic.get_parent().custom_minimum_size == Vector2(96, 96) and pnl.theme.default_font == Look.body())
	var role_icons := 0
	var todo: Array = pnl.body.rows()
	while not todo.is_empty():
		var n: Node = todo.pop_back()
		if n is TextureRect and ["role_melee", "role_ranged", "role_support", "role_cyber"].any(func(k): return n.texture == Art.icon2(k)):
			role_icons += 1
		todo.append_array(n.get_children())
	ck("0.14 panel: each Action wears its role's icon", role_icons >= 2, role_icons)
	# a Unit with a Status: its icon at a glance and under Statuses, where the dot was
	var slow_icon := Art.status_icon("Slowed")
	_tap(scene, Battle.tile_of(bt.unit_by_id("e1")))
	await _frames(2)
	var chip_icons: Array = pnl.chips.get_children().map(func(ch): return ch.get_child(0).texture if ch.get_child(0) is TextureRect else null)
	var row_icons := 0
	todo = pnl.body.rows()
	while not todo.is_empty():
		var n2: Node = todo.pop_back()
		if n2 is TextureRect and n2.texture == slow_icon and n2.custom_minimum_size == Vector2(32, 32):
			row_icons += 1
		todo.append_array(n2.get_children())
	ck("0.14 panel: a Status shows its icon, at twice its pixels, at a glance and under Statuses", slow_icon != null and chip_icons.has(slow_icon) and row_icons == 1, [chip_icons, row_icons])

	# ---- the Look board
	scene.deselect()
	await _frames(1)
	scene.open_options()
	await _frames(1)
	scene.options.look_btn.pressed.emit()
	await _frames(2)
	var lb: LookBoard = scene.look_board
	var parts := {"tile": 0, "face": 0, "pics": 0, "buttons": 0}
	if lb != null:
		var all: Array = [lb]
		while not all.is_empty():
			var n: Node = all.pop_back()
			if n is CardTile:
				parts["tile"] += 1
			elif n is CardFace.Face:
				parts["face"] += 1
			elif n is TextureRect and n.texture != null:
				parts["pics"] += 1
			elif n is Button:
				parts["buttons"] += 1
			all.append_array(n.get_children())
	ck("0.14 Look board: from Options, every piece of the look on one screen", lb != null and lb.visible and scene.options == null and parts["tile"] == 1 and parts["face"] == 1 and parts["pics"] >= 33 + 22 + 12 + 20 and parts["buttons"] >= 10, parts)
	if lb != null:
		lb.closed.emit()
	await _frames(2)
	ck("0.14 Look board: Close puts it away", scene.look_board == null)
	# the last button's blip plays out first: one still playing at exit is reported as a leak
	await create_timer(0.6).timeout
	scene.queue_free()
	await _frames(2)
	root.size = was_size
	Kit.fresh()


# ---------------------------------------------------------------- 0.15: the World Map, each District's fights, the menus
func _fifteen() -> void:
	Kit.fresh()
	var x := KeterExport.new()
	x.open(FIXTURE)
	Art.load_from(null)

	# ---- art.json's new kinds, each cut from its sheet
	var m := Art.manifest()
	var cut := []
	for kind in ["ground", "map", "district", "menu"]:
		var sheet := Art._sheet(Art.SHEET_OF[kind])
		for k in m.get(kind, {}):
			var rc: Array = m[kind][k]["rect"]
			var tex := Art.piece(kind, k)
			if tex == null or sheet == null or rc[0] + rc[2] > sheet.get_width() or rc[1] + rc[3] > sheet.get_height() or tex.get_size() != Vector2(rc[2], rc[3]):
				cut.append(kind + "/" + k)
	ck("0.15 art: art.json says 0.15 or later, with the World Map's ground and things, each District's fight and the menus, each cut from its sheet", str(m.get("version")) in ["0.15", "0.16", "0.17", "0.18", "0.19", "0.22", "0.23", "0.24"] and m.get("ground", {}).size() == 31 and m.get("map", {}).size() == 24
		and m.get("district", {}).size() == 42 and m.get("menu", {}).size() >= 13 and cut.is_empty(), cut)
	var lay: Dictionary = m.get("ground_layout", {})
	var clip := Hex.SQ3 * 8.0 + 0.5
	ck("0.15 art: the ground is hexagons of flat-top hex pixels, nine to a side, three screen pixels to a hex pixel's corner", int(lay.get("side", 0)) == 9 and str(lay.get("orient")) == "flat" and float(lay.get("s", 0)) == 3.0
		and is_equal_approx(MapView.SIZE, snappedf(clip * MapView.S, 0.01)) and absf(float(lay.get("clip", 0)) - clip) < 0.001, [lay, MapView.SIZE])
	var sizes_ok: bool = m["ground"].keys().all(func(k): return m["ground"][k]["rect"][2] == 78 and m["ground"][k]["rect"][3] == 89)
	var props_sized: bool = m["map"].keys().filter(func(k): return m["map"][k].get("kind") == "prop").all(func(k): return m["map"][k]["rect"][2] == 32 and m["map"][k]["rect"][3] == 32)
	var icons_sized: bool = m["map"].keys().filter(func(k): return m["map"][k].get("kind") == "icon").all(func(k): return m["map"][k]["rect"][2] == 16 and m["map"][k]["rect"][3] == 16)
	var floors_sized: bool = m["district"].keys().filter(func(k): return m["district"][k].get("kind") == "floor").all(func(k): return m["district"][k]["rect"][2] == 42 and m["district"][k]["rect"][3] == 48)
	var covers_sized: bool = m["district"].keys().filter(func(k): return m["district"][k].get("kind") != "floor").all(func(k): return m["district"][k]["rect"][2] == 48 and m["district"][k]["rect"][3] == 48)
	ck("0.15 art: a tile of ground is 78 by 89; a map thing 32, the Hangar 64, a map icon 16; a fight's floor plate 42 by 48, its cover 48",
		sizes_ok and props_sized and icons_sized and floors_sized and covers_sized and Art.piece("map", "hangar").get_size() == Vector2(64, 64))
	ck("0.15 art: the menus: Home, the Hangar inside and the menus' backdrop at 256 by 144, QM-7 at 64, and its blink",
		["home", "dock", "menu"].all(func(k): return Art.piece("menu", k).get_size() == Vector2(256, 144)) and Art.piece("menu", "qm7").get_size() == Vector2(64, 64) and Art.piece("menu", "qm7_blink").get_size() == Vector2(64, 64)
		and not _same_pixels(Art.piece("menu", "qm7"), Art.piece("menu", "qm7_blink")) and Art.piece("menu", "victory").get_size().y == 32 and Art.piece("menu", "defeat").get_size().y == 32)
	var pal := {}
	for c in Art.palette():
		pal[c.to_html(false)] = true
	var off := []
	for sname in ["ground", "map", "district", "menu"]:
		var img: Image = Art._sheet(sname).get_image()
		var found := false
		for y in img.get_height():
			for xx in img.get_width():
				var c := img.get_pixel(xx, y)
				if c.a > 0.0 and (c.a < 1.0 or not pal.has(c.to_html(false))):
					off.append([sname, xx, y, c.to_html(true)])
					found = true
					break
			if found:
				break
	ck("0.15 art: every pixel of it on the Pixel Studio's palette, and there or not, never half", off.is_empty(), off)

	# ---- the World Map's pieces
	var grounds_ok := true
	for d in ["", "1", "2", "3", "4", "5", "6"]:
		var g := Art.map_ground(d)
		if g.size() != 4 or not g.all(func(t): return t["texture"] != null and t["s"] == 3.0 and t["side"] == 9 and not t["mine"] and t["mid"] is Vector2):
			grounds_ok = false
	ck("0.15 map: four tiles of ground for each District, and for ground in none", grounds_ok and Art.map_ground("1")[0]["texture"] != Art.map_ground("2")[0]["texture"])
	ck("0.15 map: three of rubble, for what has collapsed", Art.rubble().size() == 3 and Art.rubble().all(func(t): return t["texture"] != null))
	var things_ok := range(1, 7).all(func(i): return Art.map_props(str(i)).size() == 3 and Art.map_props(str(i)).all(func(p): return p["texture"] != null and p["foot"].y > 16.0 and p["foot"].y <= 32.0))
	ck("0.15 map: three things of each District's to stand on its empty tiles, each standing on its foot", things_ok and Art.map_props("").is_empty())
	var icons_ok := ["poi", "unique", "ambush", "cache", "event"].all(func(k): return not Art.map_icon(k).is_empty() and Art.map_icon(k)["texture"].get_size() == Vector2(16, 16) and Art.map_icon(k)["plate"] == Color(Art.PLATE[k]))
	ck("0.15 map: what a tile holds is an icon on a plate in its colour: a POI gold, a Unique POI pale gold, an Ambush red, a Cache green, an Event blue", icons_ok and Art.map_icon("nothing").is_empty())
	var hg := Art.hangar()
	ck("0.15 map: the dock is the Hangar, lit, standing on its tile", not hg.is_empty() and hg["texture"].get_size() == Vector2(64, 64) and hg["foot"] == Vector2(32, 52) and not hg.get("rect", false))
	ck("0.15 map: the same picture for the same tile, every time", MapView.pick_from([1, 2, 3, 4], "3,-2") == MapView.pick_from([1, 2, 3, 4], "3,-2") and MapView.pick_from([], "0,0") == null and MapView._hash("a") == 97)

	# ---- each District's fights
	var dist_ok := true
	for i in range(1, 7):
		for n in 5:
			var e := Art.district_board(str(i), "floor_%d" % n)
			if e.is_empty() or e["texture"].get_size() != Vector2(42, 48) or e["foot"] != Vector2(21, 24):
				dist_ok = false
		for kind in ["half_cover", "full_cover"]:
			var e2 := Art.district_board(str(i), kind)
			if e2.is_empty() or e2["texture"].get_size() != Vector2(48, 48):
				dist_ok = false
	ck("0.15 fights: each District has five floor plates and its own Half and Full Cover", dist_ok and Art.district_board("1", "floor_0")["texture"] != Art.district_board("2", "floor_0")["texture"])
	ck("0.15 fights: a floor in no District has none (it keeps the grey deck)", Art.district_board("", "floor_0").is_empty() and Art.district_board("0", "half_cover").is_empty())
	ck("0.15 fights: the quiet plate most often, the busiest seldom", Board.D_FLOORS.count(0) > Board.D_FLOORS.size() / 3 and Board.D_FLOORS.count(4) == 1 and Board.D_FLOORS.all(func(n): return n >= 0 and n < 5))
	var bd := Board.new()
	root.add_child(bd)
	var hc := _floor_named(x, "TEST · Hazards and Cover")
	bd.show_floor(hc)
	var dd := hc.district
	var covers: Array = bd.props.keys().filter(func(h): return "cover" in str(bd.props[h].get_meta("prop")))
	var own_cover: bool = not covers.is_empty() and covers.all(func(h): return bd.props[h].texture == Art.district_board(dd, "half_cover" if str(bd.props[h].get_meta("prop")).begins_with("half") else "full_cover")["texture"])
	var plate_ok := hc.tiles.keys().all(func(h): return bd.plate_for(h) == Art.district_board(dd, "floor_%d" % Board.D_FLOORS[Board._hash(h) % Board.D_FLOORS.size()])["texture"])
	ck("0.15 fights: in its District, a floor's tiles are its plates and its cover its own", dd == "3" and own_cover and plate_ok and bd.district() == "3", dd)
	var crate_kept: bool = bd.props.values().filter(func(sp): return sp.get_meta("prop") in ["crate", "healing_station"]).all(func(sp): return sp.texture == Art.board(str(sp.get_meta("prop")))["texture"])
	ck("0.15 fights: hazards, pads, crates, chests, Exits and Healing Stations stay as they are", crate_kept and bd.piece_for("crate") == Art.board("crate") and bd.piece_for("locked_chest") == Art.board("locked_chest"))
	hc.district = ""
	bd.show_floor(hc)
	var grey: bool = hc.tiles.keys().all(func(h): return bd.plate_for(h) == Art.board(Board.FLOORS[Board._hash(h) % Board.FLOORS.size()])["texture"])
	var grey_cover: bool = bd.props.keys().filter(func(h): return "cover" in str(bd.props[h].get_meta("prop"))).all(func(h): return bd.props[h].texture == Art.board(str(bd.props[h].get_meta("prop")))["texture"])
	ck("0.15 fights: in none, the grey deck's plates and cover", grey and grey_cover)
	hc.district = dd
	bd.free()

	# ---- the menus' pictures and icons
	ck("0.15 menus: Home is the colony's sign over the night; the dock, the Hangar inside; the other menus, the colony", Art.backdrop("title") == Art.piece("menu", "home") and Art.backdrop("dock") == Art.piece("menu", "dock") and Art.backdrop("menu") == Art.piece("menu", "menu"))
	ck("0.15 menus: shards, the three parts, the Skull Level and the gear are drawn", ["shards", "part_troop", "part_equipment", "part_aether", "skull", "gear"].all(func(k): return Art.icon(k) == Art.piece("menu", "icon_" + k) and Art.icon(k).get_size() == Vector2(16, 16)))
	ck("0.15 menus: Victory and Defeat in neon, QM-7 and its blink", Art.menu_piece("victory") == Art.piece("menu", "victory") and Art.menu_piece("defeat") == Art.piece("menu", "defeat") and Art.menu_piece("qm7") == Art.piece("menu", "qm7") and Art.menu_piece("qm7_blink") == Art.piece("menu", "qm7_blink"))

	# ---- your drawings take their places
	var yours := ImageTexture.create_from_image(Image.create(32, 32, false, Image.FORMAT_RGBA8))
	var yhex := ImageTexture.create_from_image(Image.create(98, 112, false, Image.FORMAT_RGBA8))
	var big := ImageTexture.create_from_image(Image.create(64, 64, false, Image.FORMAT_RGBA8))
	Art._mine = {"fight.d3.floor_0": yours, "fight.d3.half_cover": big, "ui.qm7": big, "ui.title.victory": yours, "map.icon.poi": yours, "map.icon.cache": yhex, "map.icon.dock": big}
	Art._mine_hex = {"map.icon.cache": {"shape": "hexagon", "orient": "flat", "side": 9}}
	Art._mine_many = {"map.ground.3": [{"texture": yhex, "hex": {"shape": "hexagon", "orient": "flat", "side": 9}}], "map.ground.4": [{"texture": yours, "hex": null}],
		"map.prop.5": [{"texture": yours, "hex": null}], "map.collapsed": [{"texture": yhex, "hex": {"shape": "hexagon", "orient": "flat", "side": 9}}]}
	var g3 := Art.map_ground("3")
	ck("0.15 yours: a District's ground of yours, a hexagon of hex pixels, is laid as the game's is, fitted to its size", g3.size() == 1 and g3[0]["mine"] and g3[0]["texture"] == yhex and g3[0]["mid"] == Vector2(49, 56) and is_equal_approx(g3[0]["s"], minf(98.0 / 26.0, 112.0 / (17.0 * Hex.SQ3))), g3)
	ck("0.15 yours: one that isn't is drawn over the tile as it is; a District you drew none for keeps the game's", Art.map_ground("4")[0].get("rect", false) and Art.map_ground("1").size() == 4 and not Art.map_ground("1")[0]["mine"])
	ck("0.15 yours: your things on a District's tiles, standing on their foot; your rubble", Art.map_props("5").size() == 1 and Art.map_props("5")[0]["mine"] and Art.map_props("5")[0]["foot"] == Vector2(16, 28) and Art.map_props("6").size() == 3 and Art.rubble().size() == 1 and Art.rubble()[0]["mine"])
	ck("0.15 yours: a map icon of yours sits on its plate; a hex picture of one, from before, covers the tile", Art.map_icon("poi")["texture"] == yours and Art.map_icon("poi")["plate"] == Color(Art.PLATE["poi"]) and Art.map_icon("cache").get("rect", false) and Art.map_icon("ambush")["mine"] == false)
	ck("0.15 yours: your Hangar stands on the dock's tile", Art.hangar()["texture"] == big and Art.hangar()["foot"] == Vector2(32, 52) and Art.hangar()["mine"])
	ck("0.15 yours: a District's plate and cover of yours, in its fights; the rest stay the game's", Art.district_board("3", "floor_0")["texture"] == yours and Art.district_board("3", "floor_0")["mine"] and Art.district_board("3", "half_cover")["texture"] == big
		and Art.district_board("3", "floor_1")["mine"] == false and Art.district_board("3", "full_cover")["mine"] == false and Art.district_board("4", "floor_0")["mine"] == false)
	ck("0.15 yours: your QM-7 and your Victory; the blink and Defeat stay the game's", Art.menu_piece("qm7") == big and Art.menu_piece("victory") == yours and Art.menu_piece("qm7_blink") == Art.piece("menu", "qm7_blink") and Art.menu_piece("defeat") == Art.piece("menu", "defeat"))
	Art.load_from(null)
	ck("0.15 yours: and with none, all the game's again", Art.map_ground("3").size() == 4 and Art.rubble().size() == 3 and Art.map_icon("cache")["mine"] == false and Art.hangar()["mine"] == false and Art.menu_piece("qm7") == Art.piece("menu", "qm7"))
	# through the Companion's export: District 3's Half Cover drawn over, and one of District 2's grounds
	Art.load_from(x)
	var hc3 := Art.district_board("3", "half_cover")
	ck("0.15 export: District 3's Half Cover, drawn over in the Companion, comes in the export and is used", Art.is_mine("fight.d3.half_cover") and hc3.get("mine", false) and hc3["texture"].get_size() == Vector2(48, 48)
		and hc3["texture"].get_image().get_pixel(20, 3).to_html(false) == "6dff3a", hc3)
	var g2 := Art.map_ground("2")
	var green := g2.filter(func(t): return t["texture"].get_image().get_pixel(int(t["mid"].x), int(t["mid"].y)).to_html(false) == "6dff3a")
	ck("0.15 export: one of District 2's grounds drawn over, all four come, as hexagons of hex pixels fitted to their size, the drawn one among them", g2.size() == 4 and g2.all(func(t): return t["mine"] and not t.get("rect", false) and absf(float(t["s"]) - 4.0) < 0.05 and t["mid"] == Vector2(52, 59) and t["side"] == 9)
		and green.size() == 1, g2.map(func(t): return [t["texture"].get_size(), t["s"], t["mid"]]))
	ck("0.15 export: the game's own nobody drew on stay out of it: the rest of the ground and rubble, the things, the icons, the Hangar, the other Districts' fights, the menus'",
		not Art._mine_many.has("map.ground.1") and not Art._mine_many.has("map.collapsed") and not Art._mine_many.keys().any(func(k): return str(k).begins_with("map.prop.")) and not Art.is_mine("map.icon.poi") and not Art.is_mine("map.icon.dock")
		and not Art.is_mine("fight.d3.full_cover") and not Art.is_mine("fight.d1.floor_0") and not Art.is_mine("ui.qm7") and not Art.is_mine("ui.title") and not Art.is_mine("ui.title.victory") and not Art.is_mine("ui.icon.gear"), Art._mine_many.keys())
	Art.load_from(null)

	# ---- QM-7
	ck("0.15 QM-7: a line for each tab, and for what has just happened", ["stockpile", "exchange", "reclaim", "bounties", "upgrades", "deploy", "out", "home", "wipe", "bought", "sold", "made", "refused", "upgraded", "restock", "anytime"].all(func(k): return not QM7.LINES.get(k, []).is_empty()))
	var pool: int = QM7.LINES["exchange"].size() + QM7.LINES["anytime"].size()
	var said := {}
	for i in pool:
		said[QM7.line("exchange", i)] = true
	ck("0.15 QM-7: a tab's lines take turns with what it says any time, every one once before it comes round again", said.size() == pool and said.has(QM7.LINES["anytime"][0]) and said.has(QM7.LINES["exchange"][0])
		and QM7.line("exchange", 0) == QM7.line("exchange", pool) and QM7.LINES["bought"].has(QM7.line("bought", 1)) and QM7.LINES["anytime"].has(QM7.line("no such moment", 2)), said.size())

	# ---- the end of a fight: title art, a strip, what dropped as tiles
	var dg := Dialog.new("Victory", "Some words.", ["Close"], Color("#d6a851"))
	root.add_child(dg)
	dg.set_title_art(Art.menu_piece("victory"))
	dg.add_strip([["Round 3", "#d6a851"], ["2 of 3 yours standing", "#73efe8"]])
	var bag := Loot.bag()
	bag["shards"] = 12
	bag["parts"]["troop"][0] = 2
	var lt := dg.add_loot(UI.bag_items(bag), "In all")
	ck("0.15 result: the title is a picture, at twice its pixels; its words stay for the tests and for reading", dg.title_art != null and dg.title_art.texture == Art.menu_piece("victory") and dg.title_art.custom_minimum_size == Art.menu_piece("victory").get_size() * 2.0 and not dg.title_label.visible and dg.title_label.text == "Victory")
	ck("0.15 result: under it, a strip of chips", dg.strip != null and dg.strip.get_child_count() == 2 and _labels(dg.strip).has("Round 3"))
	ck("0.15 result: what dropped as tiles, each its picture, its count and its name", lt == dg.stats and dg.loot_tiles.size() == 2 and _stats(lt) == [["shards", "12"], ["part_troop", "2"]] and _labels(dg.loot_tiles[0]).has("Aether shards") and _first_icon(dg.loot_tiles[0], "shards").custom_minimum_size == Vector2(48, 48), _stats(lt))
	dg.set_title_art(null)
	dg.free()

	# ---- Home
	var hs := HomeScreen.new("0.15")
	root.add_child(hs)
	hs.show_state(true, "", "export.zip", 1, "1 deployment so far.", true)
	ck("0.15 home: with a Strike Team out, Play is Continue, straight to the World Map", hs.world_btn.text == "Continue" and "carry on" in hs.world_sub.text and not hs.world_btn.disabled and hs.note.text == "1 deployment so far.")
	hs.show_state(true, "", "export.zip", 0, "", false)
	ck("0.15 home: with no Strike Team yet, it says to build one, or try a Quick battle under Practice", hs.world_btn.text == "Play" and "Quick battle under Practice" in hs.note.text)
	hs.show_state(false, "No export found.", "No export", 0)
	ck("0.15 home: with no export, all of it waits, and Look again is on Home", hs.world_btn.disabled and hs.practice_btn.disabled and hs.teams_btn.disabled and hs.again_btn.visible and hs.source.visible and hs.note.text == "No export found." and not hs.practice_row.visible)
	ck("0.15 home: the gear is in the top right corner", hs.options_btn.anchor_left == 1.0 and hs.options_btn.offset_right == -20.0 and hs.options_btn.icon == Art.icon("gear"))
	hs.free()
	Kit.fresh()


func _fifteen_scene() -> void:
	Kit.fresh()
	var was_size: Vector2i = root.size
	root.size = Vector2i(1280, 720)
	Kit.keep([Kit.field_team()])
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	await _frames(2)
	var cm: Campaign = scene.campaign
	var ms: MapScreen = scene.map_screen
	var dk: DockScreen = scene.dock_screen
	cm.loot.seed_with(15)
	# ---- Home and Options
	ck("0.15 home: Play in gold, Practice and Strike Teams beside each other, the gear", scene.home.visible and scene.home.world_btn.text == "Play" and scene.home.practice_btn.get_parent() == scene.home.teams_btn.get_parent() and scene.home.options_btn.visible)
	scene.home.options_btn.pressed.emit()
	await _frames(2)
	ck("0.15 options: from Home, the version and the export, and Look again", scene.options != null and scene.options.about.visible and scene.options.again_btn.visible and scene.options.about.text.begins_with("KETER · the game · version " + scene.VERSION), scene.options.about.text if scene.options != null else "")
	scene.close_options()
	await _frames(2)
	# ---- the dock: QM-7, and the Exchange as tiles
	var gift := Loot.bag()
	gift["shards"] = 200
	cm.dock.add_to_stockpile(gift)
	scene.home.world_btn.pressed.emit()
	await _frames(2)
	ck("0.15 dock: QM-7 is there, at its post", dk.visible and dk.keeper.visible and dk.portrait.texture != null and dk.keeper_line.text != "")
	dk.tabs["exchange"].pressed.emit()
	await _frames(2)
	var tiles: Array = dk._rows.filter(func(r): return r.get("tile", false))
	var parts_tiles: Array = tiles.filter(func(r): return Loot.TYPES.any(func(t): return str(t["label"]) == r["text"]))
	ck("0.15 exchange: components are tiles, each its part's picture, its price in gold, Buy and Buy 5", parts_tiles.size() == Loot.TYPES.size() and parts_tiles.all(func(r): return r["acts"].size() >= 2 and r["acts"][0][0] == "buy_parts" and r["acts"][1][3] == 5 and _first_icon(r["row"], "shards") != null),
		dk.row_texts())
	var before: int = int(cm.dock.stockpile()["shards"])
	var moment_before: String = dk.keeper_line.text
	dk.act(parts_tiles[0]["acts"][0])
	ck("0.15 exchange: bought: QM-7 says so", cm.dock.stockpile()["shards"] < before and QM7.LINES["bought"].has(dk.keeper_line.text), [dk.keeper_line.text, moment_before])
	dk.act(["buy_card", "Nothing of the sort", 1])
	ck("0.15 exchange: refused: and that", QM7.LINES["refused"].has(dk.keeper_line.text) and dk.note.text == "Not in stock.", [dk.keeper_line.text, dk.note.text])
	dk.show_tab("stockpile")
	# ---- the World Map
	dk.map_btn.pressed.emit()
	await _frames(3)
	var mv: MapView = scene.map_view
	ck("0.15 map: drawn, at the usual zoom, on the game's ground", ms.visible and mv.visible and mv.world != null and is_equal_approx(mv._drawn_zoom, mv._zoom()) and Art.map_ground("1").size() == 4, [mv._drawn_zoom, mv._zoom()])
	ms.tap("3,-2")
	await _frames(1)
	ck("0.15 map: a tile tapped shows its District's emblem by its name", ms.p_emblem.visible and ms.p_emblem.texture == Art.icon2("district_1") and ms.p_title.text == "District 1 · Threshold Dynamics")
	ms.tap(cm.world.dock())
	await _frames(1)
	ck("0.15 map: the dock, none", not ms.p_emblem.visible)
	ms.do("dock")
	await _frames(2)
	# ---- the Workshop: the design as its card and its token
	scene.open_workshop()
	await _frames(2)
	var wsn: WorkshopScreen = scene.workshop_screen
	wsn.tap_row(wsn._rows[0])
	await _frames(2)
	var ed: DesignEditor = wsn.editor
	ck("0.15 workshop: the design as its card, beside its token on a pedestal", ed.visible and ed.preview != null and ed.preview.is_inside_tree() and ed.preview.card.get("name") == ed.d["name"] and _find(ed.result, func(n): return n is DesignEditor.Pedestal) != null)
	var banner_icons := _icons(ed.list)
	ck("0.15 workshop: the chassis as a banner: its body standing, its numbers as icons", banner_icons.has("hp") and banner_icons.has("ac") and banner_icons.has("ms") and banner_icons.has("nrg"), banner_icons)
	# ---- Strike Teams and a Battle's setup, to match
	scene.show_home()
	await _frames(1)
	scene.open_teams()
	await _frames(2)
	var tsn: TeamsScreen = scene.teams_screen
	var stood: Array = []
	if not tsn._rows.is_empty():
		var tr0 = _find(tsn._rows[0]["row"], func(n): return n is TextureRect and n.has_meta("hero"))
		var hb0: Node = tr0.get_parent().get_parent() if tr0 != null else null
		if hb0 != null:
			for sl in hb0.get_children():
				if sl.get_child_count() > 0:
					stood.append(str(sl.get_child(0).get_meta("hero")))
	ck("0.15 teams: each Strike Team shows its Heroes standing, its state in a frame; New team in gold", tsn.visible and stood == tsn.teams[0]["heroes"].slice(0, 3) and tsn.new_btn.theme_type_variation == "MainButton" and _labels(tsn._rows[0]["row"]).has("Ready"), stood)
	tsn.closed.emit()
	await _frames(1)
	scene.open_setup("team")
	await _frames(2)
	var su: SetupScreen = scene.setup
	var emblems: Array = su._rows.map(func(e): var em = _find(e["row"], func(n): return n.has_meta("district")); return str(em.get_meta("district")) if em != null else "")
	ck("0.15 setup: each floor wears its District's emblem; Next is the gold button", su.visible and not emblems.is_empty() and emblems.all(func(d): return d == "3") and su.next_btn.theme_type_variation == "MainButton", emblems)
	su.choose_floor(0)
	su._go(1)
	await _frames(1)
	ck("0.15 setup: a Strike Team, its Heroes standing", su.step == "team" and _find(su._rows[0]["row"], func(n): return n is TextureRect and n.has_meta("hero")) != null)
	await create_timer(0.6).timeout
	scene.queue_free()
	await _frames(2)
	root.size = was_size
	Kit.fresh()


## The first node under n (n too) for which want is true.
func _find(n: Node, want: Callable) -> Node:
	var todo: Array = [n]
	while not todo.is_empty():
		var k: Node = todo.pop_front()
		if want.call(k):
			return k
		todo.append_array(k.get_children())
	return null


# ---------------------------------------------------------------- 0.16: the fight's effects, drawn; the turn strip
## A stand-in for an export, carrying one picture of yours: files() and texture().
class FakeExport extends RefCounted:
	var entries: Array = []
	var textures := {}

	func files() -> Array:
		return entries

	func texture(file: String) -> Texture2D:
		return textures.get(file)


func _strip_texture(frames: int, w: int, h: int) -> Texture2D:
	var img := Image.create(w * frames, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in frames:
		img.set_pixel(i * w + 1, 1, Color("#f8c53a"))
	return ImageTexture.create_from_image(img)


func _sixteen() -> void:
	Art.load_from(null)
	# ---- art.json: the effects, each a row of frames cut from fx.png
	var m := Art.manifest()
	var fx: Dictionary = m.get("fx", {})
	var sheet := Art._sheet("fx")
	var bad_cut := []
	for name in Art.FX:
		var e: Dictionary = fx.get(name, {})
		var rc: Array = e.get("rect", [0, 0, 0, 0])
		if e.is_empty() or sheet == null or rc[0] + rc[2] > sheet.get_width() or rc[1] + rc[3] > sheet.get_height() or int(rc[2]) != int(e["w"]) * int(e["frames"]) or int(rc[3]) != int(e["h"]):
			bad_cut.append(name)
	ck("0.16 art: art.json says 0.16 or later, with the five effects, each a row of its frames in fx.png", str(m.get("version")) in ["0.16", "0.17", "0.18", "0.19", "0.22", "0.23", "0.24"] and fx.keys().filter(func(k): return not fx[k].get("atmos", false)).size() == 5 and bad_cut.is_empty(), bad_cut)
	var want := {"flash": [4, 24, 24, 20], "impact": [5, 32, 32, 16], "explosion": [8, 48, 48, 14], "heal": [6, 32, 48, 12], "shield": [6, 48, 48, 14]}
	var off := []
	for name in want:
		var f := Art.fx(name)
		var w: Array = want[name]
		var frames: Array = f.get("frames", [])
		if frames.size() != w[0] or f["size"] != Vector2(w[1], w[2]) or float(f["fps"]) != float(w[3]) or f.get("mine", true) or frames.any(func(t): return t == null or t.get_size() != Vector2(w[1], w[2])):
			off.append(name)
		var an: Vector2 = f.get("anchor", Vector2(-1, -1))
		if an.x < 0 or an.y < 0 or an.x > w[1] or an.y > w[2]:
			off.append(name + " anchor")
	ck("0.16 art: each effect as it plays: its frames (flash 4, impact 5, explosion 8, heal 6, shield 6), its size, its speed and where it sits", off.is_empty(), off)
	var a_exp: Vector2 = Art.fx("explosion")["anchor"]
	var a_heal: Vector2 = Art.fx("heal")["anchor"]
	ck("0.16 art: an explosion sits a little low on its tile (the fire rises); a heal stands on the Unit's feet", a_exp.y > 24 and a_heal.y >= 40, [a_exp, a_heal])
	var frame0: AtlasTexture = Art.fx("impact")["frames"][0]
	var frame1: AtlasTexture = Art.fx("impact")["frames"][1]
	ck("0.16 art: the frames are side by side in the sheet, in order", frame1.region.position.x - frame0.region.position.x == 32 and frame0.region.position.y == frame1.region.position.y)
	# ---- the Action icons
	var ic: Dictionary = m.get("icons", {})
	ck("0.16 art: Move, Attack and End turn have their icons; Hold fire is the Holding fire eye", ic.has("act_move") and ic.has("act_attack") and ic.has("act_end") and ic.has("overwatch") and not ic.has("act_hold") and Art.icon2("act_end") != null and Art.icon2("act_move").get_size() == Vector2(16, 16))
	# ---- yours: frames side by side, how many and how fast
	var ex := FakeExport.new()
	ex.entries = [{"file": "fight/effects/impact.png", "owner": {"slot": "fight.fx.impact"}, "grid": "square", "w": 20, "h": 20, "frames": 3, "fps": 10},
		{"file": "fight/effects/shield.png", "owner": {"slot": "fight.fx.shield"}, "grid": "square", "w": 24, "h": 24}]
	ex.textures = {"fight/effects/impact.png": _strip_texture(3, 20, 20), "fight/effects/shield.png": _strip_texture(1, 24, 24)}
	var before_serial := Art.serial
	Art.load_from(ex)
	var mi := Art.fx("impact")
	var ms := Art.fx("shield")
	ck("0.16 art: an effect of yours plays its own frames at its own speed, sat where the game's sits for its size", mi.get("mine", false) and (mi["frames"] as Array).size() == 3 and mi["size"] == Vector2(20, 20) and float(mi["fps"]) == 10.0 and mi["anchor"] == Vector2(10, 10) and (mi["frames"][2] as AtlasTexture).region.position.x == 40, [mi.get("size"), mi.get("fps"), mi.get("anchor")])
	ck("0.16 art: one of a single frame stays up as long as the game's would play", ms.get("mine", false) and (ms["frames"] as Array).size() == 1 and is_equal_approx(float(ms["fps"]), 14.0 / 6.0) and ms["anchor"] == Vector2(12, 13), [ms.get("fps"), ms.get("anchor")])
	ck("0.16 art: the others are still the game's", not Art.fx("explosion").get("mine", true) and Art.serial > before_serial)
	Art.load_from(null)
	ck("0.16 art: and with no export, the game's again", not Art.fx("impact").get("mine", true) and (Art.fx("impact")["frames"] as Array).size() == 5)
	# through the Companion's export: its impact drawn over (a green pixel in the middle of the third frame), at 10 a second
	var x := KeterExport.new()
	x.open(FIXTURE)
	Art.load_from(x)
	var fi := Art.fx("impact")
	var third: Texture2D = fi["frames"][2] if (fi.get("frames", []) as Array).size() > 2 else null
	var file_of: Array = x.files().filter(func(f): return str(f.get("owner", {}).get("slot", "")) == "fight.fx.impact")
	ck("0.16 export: the impact drawn over in the Companion comes as its five frames side by side, at 10 a second, and is played",
		fi.get("mine", false) and (fi["frames"] as Array).size() == 5 and float(fi["fps"]) == 10.0 and fi["size"] == Vector2(32, 32) and fi["anchor"] == Vector2(16, 16)
		and third != null and third.get_image().get_pixel(16, 16).to_html(false) == "6dff3a" and file_of.size() == 1 and int(file_of[0].get("frames", 0)) == 5, [fi.get("fps"), fi.get("size"), file_of])
	ck("0.16 export: the other effects, and the Action icons nobody drew on, stay the game's", not Art.fx("explosion").get("mine", true) and not Art.fx("heal").get("mine", true)
		and not Art.is_mine("ui.icon.act_move") and not Art.is_mine("ui.icon.act_end") and Art.icon2("act_end") == Art.piece("icons", "act_end"))
	Art.load_from(null)
	# ---- Motion: an effect plays its frames at its speed, then is gone
	var was_still := Motion.still
	var was_speed := Motion.speed
	Motion.still = false
	Motion.speed = "normal"
	var mo := Motion.new()
	mo.play("impact", Vector2(10, 20))
	var p0: Dictionary = mo.plays[0] if not mo.plays.is_empty() else {}
	mo._process(0.07)
	var f1 := Motion.frame_of(p0) if not p0.is_empty() else -9
	mo._process(0.07)
	var f2 := Motion.frame_of(p0) if not p0.is_empty() else -9
	mo._process(0.2)
	ck("0.16 motion: an effect plays its frames one after another at its speed (16 a second for an impact), then is gone", not p0.is_empty() and f1 == 1 and f2 == 2 and mo.plays.is_empty() and mo.played.back()["name"] == "impact", [f1, f2, mo.plays.size()])
	mo.play("heal", Vector2.ZERO, 0.2)
	var waiting: Dictionary = mo.plays[0]
	mo._process(0.1)
	var not_yet := Motion.frame_of(waiting)
	mo._process(0.15)
	ck("0.16 motion: one asked to wait waits, then plays", not_yet == -1 and Motion.frame_of(waiting) == 0, [not_yet, Motion.frame_of(waiting)])
	mo.clear()
	Motion.speed = "fast"
	mo.play("explosion", Vector2.ZERO)
	mo._process(0.1)
	var fast_frame := Motion.frame_of(mo.plays[0])
	ck("0.16 motion: at Fast they play faster", fast_frame >= 3, fast_frame)
	mo.clear()
	mo.area(Vector2i(0, 0), 1)
	var booms: Array = mo.plays.filter(func(p): return p["name"] == "explosion")
	var middle: Array = booms.filter(func(p): return p["at"] == Board.at(Vector2i(0, 0)))
	ck("0.16 motion: an area explodes on every tile it catches, the middle first, then the ring", booms.size() == 7 and middle.size() == 1 and middle[0]["t"] == 0.0 and booms.filter(func(p): return p["t"] < 0.0).size() == 6)
	mo.clear()
	mo.area(Vector2i(0, 0), 1, 1)
	ck("0.16 motion: after a shell comes down in the middle, only the ring explodes", mo.plays.size() == 6 and not mo.plays.any(func(p): return p["at"] == Board.at(Vector2i(0, 0))))
	mo.clear()
	Motion.speed = "instant"
	mo.played.clear()
	mo.play("shield", Vector2.ZERO)
	mo.fire("shell", Vector2.ZERO, Vector2(100, 0), Color.WHITE, true)
	ck("0.16 motion: at Instant nothing plays (though it is told what would)", mo.plays.is_empty() and mo.played.map(func(p): return p["name"]) == ["shield", "flash", "explosion"], mo.played)
	mo.free()
	Motion.speed = was_speed
	Motion.still = was_still
	# ---- the turn strip, in the side panel
	var pn := UnitPanel.new()
	var u := {"id": "a1", "name": "Test", "side": "ally", "hp": 10, "hpMax": 10, "ac": 5, "ms": 4, "nrg": 2, "nrgMax": 4, "actions": [], "statuses": []}
	pn.show_unit(u, {}, {"interactive": true, "speed": 4, "turn": {"move": true, "moved": false, "speed": 4, "attack": true, "hold": "can"}})
	var items: Array = pn.turn_row.get_children()
	var words := func(it): return (_find(it, func(n): return n is Label) as Label).text
	ck("0.16 panel: one of yours in your turn shows what it can still do: Move 4, Attack, Hold fire, each with its icon, all lit", pn.turn_row.visible and items.map(func(it): return it.get_meta("turn")) == ["move", "attack", "hold"] and items.map(words) == ["Move 4", "Attack", "Hold fire"]
		and items.all(func(it): return it.get_meta("lit")) and items.all(func(it): return _find(it, func(n): return n is TextureRect and n.texture != null) != null), items.map(words))
	ck("0.16 panel: the line under its name doesn't say again how far it can move", not pn.move_label.visible, pn.move_label.text)
	for c in pn.turn_row.get_children():
		pn.turn_row.remove_child(c)
		c.free()
	pn.show_unit(u, {}, {"interactive": true, "moved": true, "speed": 4, "turn": {"move": false, "moved": true, "speed": 4, "attack": false, "hold": "spent"}})
	items = pn.turn_row.get_children()
	var tr_dim: TextureRect = _find(items[0], func(n): return n is TextureRect)
	ck("0.16 panel: once used, each is dimmed: Moved, Attack, Hold fire", items.map(words) == ["Moved", "Attack", "Hold fire"] and not items.any(func(it): return it.get_meta("lit")) and tr_dim.modulate.a < 0.5, items.map(words))
	for c in pn.turn_row.get_children():
		pn.turn_row.remove_child(c)
		c.free()
	u["holding"] = {"name": "Overwatch"}
	pn.show_unit(u, {}, {"interactive": true, "speed": 4, "turn": {"move": true, "moved": false, "speed": 4, "attack": true, "hold": "holding"}})
	items = pn.turn_row.get_children()
	ck("0.16 panel: holding fire, it says Holding, dimmed (it is paid for), and the line under its name says what it will do", items.map(words) == ["Move 4", "Attack", "Holding"] and not items[2].get_meta("lit") and pn.move_label.visible and pn.move_label.text.begins_with("Holding fire with Overwatch"), [items.map(words), pn.move_label.text])
	u.erase("holding")
	for c in pn.turn_row.get_children():
		pn.turn_row.remove_child(c)
		c.free()
	pn.show_unit(u, {}, {"interactive": true, "speed": 0, "turn": {"move": false, "moved": false, "speed": 0, "attack": true, "hold": ""}})
	items = pn.turn_row.get_children()
	ck("0.16 panel: one with nothing to hold fire with has no Hold fire; one that can't move says so", items.map(words) == ["Can't move", "Attack"], items.map(words))
	pn.show_unit(u, {}, {"interactive": false, "speed": 4})
	ck("0.16 panel: none when you can't act with it (an Enemy, the Enemies' turn)", not pn.turn_row.visible and pn.move_label.visible and pn.move_label.text == "Can move up to 4 tiles.", pn.move_label.text)
	pn.free()


func _sixteen_scene() -> void:
	Kit.fresh()
	var was_size: Vector2i = root.size
	root.size = Vector2i(1280, 720)
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	await _frames(2)
	var r: Roster = scene.roster
	var cor: FloorData = null
	for f in scene.floors:
		if f.name == "TEST · Corridor":
			cor = f
	var w := _mk(r, "Test Warden", "ally", "a1", Vector2i(0, 0))
	var s := _mk(r, "Test Striker", "ally", "a2", Vector2i(1, 0))
	var g := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(4, 0))
	var g2 := _mk(r, "Test Grunt", "enemy", "e2", Vector2i(6, -1))
	g2["name"] = "Test Grunt 2"
	var bt := _stage(scene, cor, [w, s, g, g2])
	await _frames(2)
	# ---- End turn wears its hourglass
	ck("0.16 fight: End turn has its icon beside the words", scene.next_btn.icon != null and scene.next_btn.icon == Art.icon2("act_end") and scene.next_btn.text == "End turn" and scene.next_btn.expand_icon)
	# ---- the turn strip, as the fight has it
	scene.select(w)
	await _frames(1)
	var tr: HBoxContainer = scene.panel.turn_row
	var items: Array = tr.get_children()
	var words := func(it): return (_find(it, func(n): return n is Label) as Label).text
	ck("0.16 fight: select one of yours: Move (how far), Attack, Hold fire, under its name", tr.visible and items.map(words) == ["Move %d" % bt.speed(w), "Attack", "Hold fire"] and items[0].get_meta("lit") and items[2].get_meta("lit"), items.map(words))
	ck("0.16 fight: Attack is lit while any of its Actions can be used now", items[1].get_meta("lit") == Battle.usable_actions(w).any(func(a): return bt.action_state(w, a)["ok"]))
	scene.move_selected(Vector2i(1, -1))
	await _idle(scene)
	scene.select(w)
	await _frames(1)
	items = tr.get_children()
	ck("0.16 fight: after it moves: Moved, dimmed; Hold fire dimmed too (it can only be held before moving)", items.map(words)[0] == "Moved" and not items[0].get_meta("lit") and items.size() == 3 and not items[2].get_meta("lit"), items.map(words))
	scene.select(g)
	await _frames(1)
	ck("0.16 fight: an Enemy's panel has no strip", not scene.panel.turn_row.visible)
	scene.deselect()
	await _frames(1)
	# ---- the effects, as a strike plays them (the rules are not asked: this only shows)
	Motion.still = false
	Motion.speed = "normal"
	var fx: Motion = scene.fxl
	var volley := _act(w, "Pinning Volley")
	var wat := Board.at(Battle.tile_of(w))
	var gat := Board.at(Battle.tile_of(g))
	fx.clear()
	fx.played.clear()
	await scene._strike(w, volley, g, {"kind": "ranged", "hit": true, "penetrated": true, "damage": 3})
	var names: Array = fx.played.map(func(p): return p["name"])
	var dir := ((gat + Motion.BODY) - (wat + Motion.BODY)).normalized()
	ck("0.16 fight: a shot goes off in a muzzle flash at the shooter's middle, and an impact plays where the damage lands", names == ["flash", "impact"] and fx.played[0]["at"].distance_to(wat + Motion.BODY + dir * 22.0) < 0.5 and fx.played[1]["at"] == gat + Motion.BODY, fx.played)
	ck("0.16 fight: they play on the board", fx.plays.size() >= 1 and fx.plays.all(func(p): return p["name"] in ["flash", "impact"]))
	fx.clear()
	fx.played.clear()
	await scene._strike(w, volley, g, {"kind": "ranged", "hit": true, "penetrated": false, "damage": 0})
	ck("0.16 fight: a shot that hits and glances off the armour flares a shield on the target", fx.played.map(func(p): return p["name"]) == ["flash", "shield"] and fx.played[1]["at"] == gat + Motion.BODY, fx.played)
	fx.played.clear()
	await scene._strike(w, volley, g, {"kind": "ranged", "hit": false, "penetrated": false, "damage": 0})
	ck("0.16 fight: one that misses only flashes as it leaves (it flies past)", fx.played.map(func(p): return p["name"]) == ["flash"], fx.played)
	fx.played.clear()
	await scene._strike(w, _act(w, "Field Medicine"), s, {"kind": "support", "healed": 4})
	var sat := Board.at(Battle.tile_of(s))
	ck("0.16 fight: a mend rises from the feet of whoever is mended", fx.played.map(func(p): return p["name"]) == ["heal"] and fx.played[0]["at"] == sat + Motion.FEET, fx.played)
	fx.played.clear()
	var blow := _act(s, "Shoulder Check")
	await scene._strike(s, blow, g, {"kind": "melee", "hit": true, "penetrated": true, "damage": 2})
	ck("0.16 fight: a blow struck lands in an impact too (and no muzzle flash)", fx.played.map(func(p): return p["name"]) == ["impact"], fx.played)
	# a shell comes down in an explosion; with an area, the ring round it goes up too
	var shell := volley.duplicate(true)
	shell["proj"] = "shell"
	fx.played.clear()
	await scene._strike(w, shell, g, {"kind": "ranged", "hit": true, "penetrated": true, "damage": 3})
	ck("0.16 fight: a shell comes down in an explosion on the tile (it takes the place of the impact)", fx.played.map(func(p): return p["name"]) == ["flash", "explosion"] and fx.played[1]["at"] == gat, fx.played)
	shell["text"] = "[[target enemy]] takes [[damage 3]]. [[AoE 1]]."
	fx.played.clear()
	await scene._strike(w, shell, g, {"kind": "ranged", "hit": true, "penetrated": true, "damage": 3})
	var ex_n: int = fx.played.filter(func(p): return p["name"] == "explosion").size()
	ck("0.16 fight: a shell with an area: its own explosion in the middle, then one on each tile round it", ex_n == 7 and fx.played.filter(func(p): return p["name"] == "explosion" and p["at"] == gat).size() == 1, fx.played.map(func(p): return p["name"]))
	var aoe := volley.duplicate(true)
	aoe["text"] = "[[target enemy]] takes [[damage 3]]. [[AoE 1]]."
	fx.played.clear()
	await scene._strike(w, aoe, g, {"kind": "ranged", "hit": true, "penetrated": true, "damage": 3})
	ck("0.16 fight: a bolt with an area: an impact on the target, an explosion on every tile it catches", fx.played.filter(func(p): return p["name"] == "explosion").size() == 7 and fx.played.filter(func(p): return p["name"] == "impact").size() == 1, fx.played.map(func(p): return p["name"]))
	# an area at the edge of the floor explodes only on the floor's tiles
	var edge := Vector2i(99, 99)
	for tq in range(-8, 9):
		for tr2 in range(-4, 5):
			var th := Vector2i(tq, tr2)
			if edge.x == 99 and cor.has_tile(th) and Hex.neighbours(th).any(func(nb): return not cor.has_tile(nb)):
				edge = th
	var want_n := 0
	for dq in range(-1, 2):
		for dr in range(-1, 2):
			if Hex.distance(edge, edge + Vector2i(dq, dr)) <= 1 and cor.has_tile(edge + Vector2i(dq, dr)):
				want_n += 1
	fx.played.clear()
	var on_edge := g.duplicate(true)
	on_edge["pos"] = {"q": edge.x, "r": edge.y}
	await scene._strike(w, aoe, on_edge, {"kind": "ranged", "hit": true, "penetrated": true, "damage": 3})
	ck("0.16 fight: at the floor's edge, an area explodes only on the floor's tiles", edge.x != 99 and want_n < 7 and fx.played.filter(func(p): return p["name"] == "explosion").size() == want_n, [edge, want_n, fx.played.map(func(p): return p["name"])])
	# a real attack plays them too
	_sure(volley, g)
	w["nrg"] = 9
	fx.played.clear()
	await scene.attack_with(w, volley, g)
	await _idle(scene)
	ck("0.16 fight: a real attack plays them: the flash as it fires, the impact as it lands", fx.played.map(func(p): return p["name"]).slice(0, 2) == ["flash", "impact"], fx.played.map(func(p): return p["name"]))
	# a card that hurts plays an impact where it hurt
	var cmark: Array = scene._mark()
	bt.floats.append({"unit": "e1", "text": "-2 HP", "kind": "damage"})
	bt.floats.append({"unit": "a2", "text": "+2 HP", "kind": "heal"})
	fx.played.clear()
	await scene._card_flight({"kind": "hand", "name": "Test card"}, null, g, null, cmark)
	ck("0.16 cards: a card's play lands where it did something: an impact where it hurt, a heal where it mended", fx.played.map(func(p): return p["name"]) == ["impact", "heal"] and fx.played[0]["at"] == gat + Motion.BODY and fx.played[1]["at"] == sat + Motion.FEET, fx.played)
	fx.played.clear()
	var cmark2: Array = scene._mark()
	bt.floats.append({"unit": "a2", "text": "Evasive", "kind": "buff"})
	await scene._card_flight({"kind": "hand", "name": "Test card", "needs": {"radius": 1}}, null, null, Vector2i(1, 0), cmark2)
	ck("0.16 cards: one with an area that only helps doesn't explode", fx.played.map(func(p): return p["name"]) == ["heal"], fx.played)
	# ---- Instant: nothing plays
	Motion.speed = "instant"
	fx.clear()
	await scene._strike(w, volley, g, {"kind": "ranged", "hit": true, "penetrated": true, "damage": 3})
	ck("0.16 instant: nothing plays", fx.plays.is_empty())
	Motion.speed = "normal"
	# ---- the Look board
	scene.open_look_board()
	await _frames(3)
	var lb = scene.look_board if scene.get("look_board") != null else null
	var loops: Array = []
	if lb != null:
		var todo: Array = [lb]
		while not todo.is_empty():
			var n: Node = todo.pop_back()
			if n.has_meta("fx"):
				loops.append(str(n.get_meta("fx")))
			todo.append_array(n.get_children())
	ck("0.16 look: the Look board plays each effect beside its frames", lb != null and loops.size() == 5 and Art.FX.all(func(k): return loops.has(k)), loops)
	Motion.still = true
	await create_timer(0.6).timeout
	scene.queue_free()
	await _frames(2)
	root.size = was_size
	Kit.fresh()


# ---------------------------------------------------------------- 0.17: card art
const UNIT_KINDS := ["hero", "troop", "enemy", "elite", "miniboss", "boss", "unit"]


func _seventeen() -> void:
	Art.load_from(null)
	var m := Art.manifest()
	var ca: Dictionary = m.get("cardart", {})
	var sheet := Art._sheet("cardart")
	var bad_cut := []
	for k in ca:
		var rc: Array = ca[k].get("rect", [0, 0, 0, 0])
		if sheet == null or rc[2] != 128 or rc[3] != 90 or rc[0] + rc[2] > sheet.get_width() or rc[1] + rc[3] > sheet.get_height() or str(ca[k].get("name", "")) == "" or UNIT_KINDS.has(str(ca[k].get("type", ""))):
			bad_cut.append(k)
	ck("0.17 art: art.json says 0.17 or later, with a picture for each of the 93 cards that are not Units (14 more in 0.22; 4 withdrawn in 0.24), 128 by 90, cut from cardart.png", str(m.get("version")) in ["0.17", "0.18", "0.19", "0.22", "0.23", "0.24"] and ca.size() == 93 and bad_cut.is_empty(), [m.get("version"), ca.size(), bad_cut])
	var with_id := ca.keys().filter(func(k): return str(ca[k].get("id", "")) != "")
	var kinds := {}
	for k in ca:
		kinds[str(ca[k]["type"])] = int(kinds.get(str(ca[k]["type"]), 0)) + 1
	ck("0.17 art: each says its card's name and kind, and its id when the card has one (0.24: a Chip, two Commands and a Prototype fewer)", with_id.size() == 60 and kinds == {"aether": 19, "equipment": 18, "sphere": 14, "action": 11, "command": 10, "consumable": 12, "prototype": 9}, [with_id.size(), kinds])
	var lance := Art.card_art({"id": "D3-AE05", "name": "Aether Lance", "cardType": "aether"})
	ck("0.17 art: a card's picture, found by its id", lance is AtlasTexture and lance.get_size() == Vector2(128, 90) and (lance as AtlasTexture).atlas == sheet)
	var renamed := Art.card_art({"id": "D3-AE05", "name": "Lance, renamed", "cardType": "aether"})
	ck("0.17 art: by its id even when its name has changed", renamed != null and (renamed as AtlasTexture).region == (lance as AtlasTexture).region)
	var dress := Art.card_art({"name": "Field Dressing", "cardType": "consumable"})
	ck("0.17 art: a card of no id, by its name", dress != null and dress.get_size() == Vector2(128, 90))
	var cell := Art.card_art({"id": "D3-AE08", "name": "Aether battery", "cardType": "aether"})
	var unit := Art.card_art({"id": "D3-T21", "name": "Aether Battery", "cardType": "troop"})
	ck("0.17 art: the Aether battery card has its picture; the Aether Battery Unit, of the same name, does not", cell != null and unit == null)
	ck("0.17 art: a card nobody drew (a design of yours, a test card) has none", Art.card_art({"name": "My Own Gadget", "cardType": "equipment"}) == null and Art.card_art({"name": "Test Plating", "cardType": "equipment"}) == null)
	# the pictures are solid to their edges (the backdrop behind the thing) and differ one from another
	var img := sheet.get_image() if sheet != null else null
	var holes := []
	var seen := {}
	if img != null:
		for k in ca:
			var rc: Array = ca[k]["rect"]
			var sig := ""
			for p in [[0, 0], [127, 89], [64, 45], [3, 80], [120, 10]]:
				if img.get_pixel(rc[0] + p[0], rc[1] + p[1]).a < 1.0:
					holes.append(k)
			for y in range(20, 70, 7):
				for x in range(20, 108, 9):
					sig += img.get_pixel(rc[0] + x, rc[1] + y).to_html(false)
			seen[sig] = true
	ck("0.17 art: each picture is solid, edge to edge, and no two are alike", img != null and holes.is_empty() and seen.size() == ca.size(), [holes, seen.size()])


func _seventeen_scene() -> void:
	Kit.fresh()
	var was_size: Vector2i = root.size
	root.size = Vector2i(1280, 720)
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	await _frames(2)
	var r: Roster = scene.roster
	var sheet := Art._sheet("cardart")
	var game_art := func(t) -> bool: return t is AtlasTexture and (t as AtlasTexture).atlas == sheet and t.get_size() == Vector2(128, 90)
	# every master card that is not a Unit, and no test card, wears the game's picture
	var wearing := []
	var missing := []
	for c in r.cards:
		if UNIT_KINDS.has(Roster.type_of(c)) or str(c.get("_src", "")) == "test":
			continue
		if str(c.get("_src", "")) != "master":
			continue
		var a := r.art_for(c)
		if c["name"] == "Field Dressing":
			continue
		if game_art.call(a):
			wearing.append(c["name"])
		else:
			missing.append(c["name"])
	ck("0.17 roster: every master card that is not a Unit shows its own picture (92 of the game's since 0.24, Field Dressing drawn over in the Companion)", wearing.size() == 92 and missing.is_empty(), [wearing.size(), missing])
	var fd := r.art_for(r.card_named("Field Dressing"))
	var fd_img := fd.get_image() if fd != null and not (fd is AtlasTexture) else null
	ck("0.17 export: art drawn over in the Companion comes in the export, and the game uses it in place of its own (its green line along the top)", fd != null and not game_art.call(fd) and fd.get_size() == Vector2(128, 90)
		and fd_img != null and fd_img.get_pixel(40, 2).is_equal_approx(Color("#6dff3a")), [fd, fd.get_size() if fd != null else null])
	var bat_unit := r.cards.filter(func(c): return c["name"] == "Aether Battery" and Roster.type_of(c) == "troop")
	var bat_card := r.cards.filter(func(c): return c["name"] == "Aether battery" and Roster.type_of(c) == "aether")
	ck("0.17 roster: the Aether battery card shows its picture; the Aether Battery Unit still its token", bat_card.size() == 1 and game_art.call(r.art_for(bat_card[0]))
		and bat_unit.size() == 1 and r.art_for(bat_unit[0]) != null and r.art_for(bat_unit[0]).get_size() == Vector2(48, 48), [bat_card.size(), bat_unit.size()])
	var tp: Dictionary = r.card_named("Test Plating")
	var tp_art: Texture2D = r.art_for(tp) if not tp.is_empty() else null
	ck("0.17 roster: a test card still wears the art the export has for it", tp_art != null and not game_art.call(tp_art))
	var units := r.cards.filter(func(c): return UNIT_KINDS.has(Roster.type_of(c)) and str(c.get("_src", "")) == "master")
	ck("0.17 roster: no Unit wears a card picture", not units.is_empty() and not units.any(func(c): return game_art.call(r.art_for(c))))
	# the Look board shows them all
	scene.open_look_board()
	await _frames(3)
	var lb = scene.look_board if scene.get("look_board") != null else null
	var arts := 0
	if lb != null:
		var todo: Array = [lb]
		while not todo.is_empty():
			var n: Node = todo.pop_back()
			if n.has_meta("cardart"):
				arts += 1
			todo.append_array(n.get_children())
	ck("0.17 look: the Look board shows every card's picture (93 since 0.24)", arts == 93, arts)
	scene.queue_free()
	await _frames(2)
	root.size = was_size
	Kit.fresh()


# ---------------------------------------------------------------- 0.18: the fight's atmosphere
func _eighteen() -> void:
	Art.load_from(null)
	var m := Art.manifest()
	var fx: Dictionary = m.get("fx", {})
	var want := {"ember": [4, 8, 8], "spark": [3, 12, 12], "ash": [3, 8, 8], "dust": [2, 6, 6]}
	var off := []
	for k in want:
		var e: Dictionary = fx.get(k, {})
		var f := Art.fx(k)
		var w: Array = want[k]
		if not e.get("atmos", false) or (f.get("frames", []) as Array).size() != w[0] or f.get("size") != Vector2(w[1], w[2]) or f.get("mine", true):
			off.append(k)
	ck("0.18 art: art.json says 0.18 or later, with the atmosphere's four motes in fx.png, each its frames: ember 4 (8 by 8), spark 3 (12), ash 3 (8), dust 2 (6)", str(m.get("version")) in ["0.18", "0.19", "0.22", "0.23", "0.24"] and off.is_empty() and Atmos.MOTES == ["ember", "spark", "ash", "dust"], off)
	ck("0.18 art: the five effects are still the fight's effects, the motes kept apart from them", Art.FX.size() == 5 and not Art.FX.any(func(k): return Atmos.MOTES.has(k)))
	# the setting: kept between sessions, Subtle to begin with
	Motion.reset()
	var was := Motion.atmos
	Motion.set_atmos("full")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(Motion.path)) if FileAccess.file_exists(Motion.path) else null
	Motion.set_atmos("loud")
	var kept := Motion.atmos
	Motion._read = false
	Motion.atmos = "subtle"
	Motion.settings()
	var read_back := Motion.atmos
	ck("0.18 settings: Atmosphere starts at Subtle; Full is kept in the settings and read back; a level that isn't one is ignored", was == "subtle" and saved is Dictionary and saved.get("atmos") == "full" and kept == "full" and read_back == "full", [was, saved, kept, read_back])
	Motion.reset()
	ck("0.18 settings: and back to Subtle when the game is new again", Motion.atmos == "subtle")


## A board on its own, showing a floor, for the atmosphere's tests.
func _atmos_board(f: FloorData) -> Board:
	var b := Board.new()
	root.add_child(b)
	b.show_floor(f)
	return b


func _eighteen_scene() -> void:
	Kit.fresh()
	var x := KeterExport.new()
	x.open(FIXTURE)
	var d3: FloorData = null
	for f in x.floors():
		if f.district == "3" and not f.hazards.is_empty() and d3 == null:
			d3 = f
	# (the test export's floors are all in District 3: one of no District, made here)
	var plain := FloorData.from_dict({"name": "Plain", "hexes": [["0,0", {}], ["1,0", {}], ["0,1", {}], ["-1,1", {}], ["2,0", {}], ["1,1", {}]]})
	ck("0.18: the test export has a floor in District 3 with hazards; and one of no District", d3 != null and plain != null and plain.district == "", [d3.name if d3 else null])
	if d3 == null or plain == null:
		return
	# the tests hold the world still: no atmosphere then, as before
	Motion.still = true
	Atmos.allow_still = false
	var b0 := _atmos_board(d3)
	ck("0.18: while the tests hold the world still, the board has no atmosphere", not Atmos.running() and not b0.atmos.visible and b0.atmos.motes.is_empty())
	b0.queue_free()
	Atmos.allow_still = true
	Motion.atmos = "subtle"
	var b := _atmos_board(d3)
	var a: Atmos = b.atmos
	var want_glows := d3.hazards.size()
	for h in d3.tiles:
		if Board.tile_kind(d3, h) in ["spawn-ally", "spawn-enemy", "healing"]:
			want_glows += 1
		if Board.symbol_kind(d3, h) == "exit":
			want_glows += 1
	ck("0.18: a glow on every hazard, spawn pad, Emergency Exit and Healing Station", a.glows.size() == want_glows and a.glows.filter(func(g): return g["hazard"]).size() == d3.hazards.size(), [a.glows.size(), want_glows])
	var hz_col: Color = a.glows.filter(func(g): return g["hazard"])[0]["colour"]
	var pad := a.glows.filter(func(g): return g["colour"] == Atmos.PAD_YOURS or g["colour"] == Atmos.PAD_THEIRS)
	ck("0.18: each in its colour: a hazard as what it is, your pads cyan, theirs red", Atmos.HAZARD_GLOW.values().has(hz_col) and not pad.is_empty())
	var kinds := {}
	for mo in a.motes:
		kinds[mo["kind"]] = int(kinds.get(mo["kind"], 0)) + 1
	ck("0.18: a fight in District 3 opens with its air already full: embers rising and ash falling, no more than Subtle's count", a.visible and a.motes.size() > 8 and a.motes.size() <= Atmos.MOST["subtle"] + 6
		and kinds.get("ember", 0) > 0 and kinds.get("ash", 0) > 0, kinds)
	var risers := a.motes.filter(func(mo): return mo["kind"] == "ember").all(func(mo): return mo["v"].y < 0.0)
	var fallers := a.motes.filter(func(mo): return mo["kind"] == "ash").all(func(mo): return mo["v"].y > 0.0)
	ck("0.18: embers rise, ash falls", risers and fallers)
	var sparked := false
	var most_seen := 0
	for i in 300:
		a.step(1.0 / 30.0)
		most_seen = maxi(most_seen, a.motes.filter(func(mo): return mo["kind"] != "spark").size())
		if a.motes.any(func(mo): return mo["kind"] == "spark"):
			sparked = true
	ck("0.18: over ten seconds, sparks spit from its hazards, and the motes never pass Subtle's count", sparked and most_seen <= Atmos.MOST["subtle"], [sparked, most_seen])
	var area := b.extent().grow(200.0)
	ck("0.18: the motes stay over the board", a.motes.all(func(mo): return area.has_point(mo["p"])))
	var flickered := false
	for i in 400:
		a.step(1.0 / 30.0)
		if a.veil > 0.0:
			flickered = true
	ck("0.18: and now and then the lights flicker", flickered)
	var g0: Dictionary = a.glows[0]
	var lo := 1.0
	var hi := 0.0
	for i in 120:
		a.step(1.0 / 30.0)
		lo = minf(lo, a.breath(g0))
		hi = maxf(hi, a.breath(g0))
	ck("0.18: a glow breathes, brighter and dimmer", hi - lo > 0.5, [lo, hi])
	# Full: more of it
	Motion.atmos = "full"
	a.reset(b)
	var full_n := a.motes.size()
	Motion.atmos = "subtle"
	a.reset(b)
	var subtle_n := a.motes.size()
	ck("0.18: at Full the air is thicker than at Subtle", full_n > subtle_n and full_n <= Atmos.MOST["full"] + 6, [subtle_n, full_n])
	# Off: none of it
	Motion.atmos = "off"
	a._process(0.1)
	a.reset(b)
	ck("0.18: at Off, nothing: no glow, no motes, no flicker", not a.visible and a.motes.is_empty() and not Atmos.running())
	b.queue_free()
	# a floor of no District: only dust
	Motion.atmos = "full"
	var b2 := _atmos_board(plain)
	var only := {}
	for mo in b2.atmos.motes:
		only[mo["kind"]] = true
	ck("0.18: a fight in no District has dust drifting, and no embers, ash or sparks", only.keys() == ["dust"], only.keys())
	b2.queue_free()
	Motion.atmos = "subtle"
	Atmos.allow_still = false
	await _frames(2)
	# Options: the Atmosphere row
	var ob := OptionsBox.new()
	root.add_child(ob)
	await _frames(2)
	var row_ok: bool = ob.atmos_btns.keys() == ["off", "subtle", "full"] and ob.atmos_btns["subtle"].button_pressed
	ob.atmos_btns["full"].pressed.emit()
	await _frames(1)
	ck("0.18 options: Atmosphere, Off, Subtle or Full, lit at what is chosen; a tap chooses and keeps it", row_ok and Motion.atmos == "full" and ob.atmos_btns["full"].button_pressed and not ob.atmos_btns["subtle"].button_pressed, [row_ok, Motion.atmos])
	ob.queue_free()
	Motion.reset()
	# yours: the ash drawn over in the Companion drifts in place of the game's
	Art.load_from(x)
	var ash := Art.fx("ash")
	ck("0.18 export: the ash drawn over in the Companion's Effects comes in the export, and is the one that drifts", ash.get("mine", false) and (ash.get("frames", []) as Array).size() == 3 and not Art.fx("ember").get("mine", true), [ash.get("mine"), (ash.get("frames", []) as Array).size()])
	Art.load_from(null)
	# the Look board shows the motes, each looping
	var was_size: Vector2i = root.size
	root.size = Vector2i(1280, 720)
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	await _frames(2)
	scene.open_look_board()
	await _frames(3)
	var lb = scene.look_board if scene.get("look_board") != null else null
	var motes := []
	if lb != null:
		var todo: Array = [lb]
		while not todo.is_empty():
			var n: Node = todo.pop_back()
			if n.has_meta("mote"):
				motes.append(str(n.get_meta("mote")))
			todo.append_array(n.get_children())
	motes.sort()
	ck("0.18 look: the Look board plays each mote beside its frames", motes == ["ash", "dust", "ember", "spark"], motes)
	scene.queue_free()
	await _frames(2)
	root.size = was_size
	Kit.fresh()


# ---------------------------------------------------------------- 0.19: transitions, Victory and Defeat, cards dealt
func _nineteen() -> void:
	Art.load_from(null)
	var m := Art.manifest()
	var cb: Dictionary = m.get("cardback", {}).get("back", {})
	var back := Art.card_back()
	var cbr: Array = (cb.get("rect", []) as Array).map(func(v): return int(v))
	ck("0.19 art: art.json says 0.19 or later, with the card back, 75 by 105, in cardback.png", ["0.19", "0.22", "0.23", "0.24"].has(str(m.get("version"))) and cbr == [0, 0, 75, 105]
		and back != null and back.get_size() == Vector2(75, 105), [m.get("version"), cb])
	var img := back.get_image() if back != null else null
	var red := 0
	var cyan := 0
	if img != null:
		for y in 105:
			for x in 75:
				var c := img.get_pixel(x, y)
				if c.r > 0.9 and c.g < 0.35 and c.b < 0.35:
					red += 1
				if c.g > 0.8 and c.b > 0.8 and c.r < 0.6:
					cyan += 1
	ck("0.19 art: solid, edge to edge, its emblem's labs lit red and its frame cyan", img != null and img.get_pixel(0, 0).a == 1.0 and img.get_pixel(74, 104).a == 1.0 and img.get_pixel(37, 52).a == 1.0 and red > 8 and cyan > 40, [red, cyan])
	# a hand seen, then a card drawn: only the new one is dealt; an Undo deals nothing; a new battle deals them all
	var tray := HandTray.new()
	var b := Battle.new()
	b.hand = [{"name": "A", "type": "command"}, {"name": "B", "type": "command"}, {"name": "A", "type": "command"}]
	var first := tray.new_cards(b)
	var again := tray.new_cards(b)
	b.hand.append({"name": "A", "type": "command"})
	var drew := tray.new_cards(b)
	b.hand = b.hand.duplicate(true)
	var undone := tray.new_cards(b)
	b.hand.remove_at(0)
	var played := tray.new_cards(b)
	var b2 := Battle.new()
	b2.hand = [{"name": "C", "type": "command"}]
	var other := tray.new_cards(b2)
	ck("0.19 hand: the first look deals every card; looking again deals none", first == [0, 1, 2] and again.is_empty(), [first, again])
	ck("0.19 hand: a card drawn is dealt alone; an Undo or a card played deals nothing; a new battle deals its hand", drew == [3] and undone.is_empty() and played.is_empty() and other == [0], [drew, undone, played, other])
	tray.free()
	# the transitions: none while the tests hold the world still
	var tr := Transition.new()
	root.add_child(tr)
	Motion.still = true
	tr.play(Transition.HEX)
	ck("0.19 transition: while the world is held still, none plays (it is told which would)", not tr.playing() and tr.played == ["hex"])
	tr.queue_free()
	# the scene: how the sign powers on (at Normal)
	Motion.still = false
	Motion.speed = "normal"
	var ns := NeonScene.new(true, Art.menu_piece("victory"), [])
	var pattern := [ns.lit(0.1), ns.lit(0.32), ns.lit(0.4), ns.lit(0.47), ns.lit(0.52), ns.lit(1.5)]
	ck("0.19 scene: the sign powers on like a failing tube: dark, lit, dark, lit, dark, then holding", pattern == [false, true, false, true, false, true], pattern)
	var nl := NeonScene.new(false, Art.menu_piece("defeat"), [])
	Motion.still = true
	var half := []
	for i in 40:
		half.append(nl.dead_half(1.0 + i * 0.05))
	var dim := half.filter(func(v): return v < 0.5).size()
	ck("0.19 scene: Defeat never quite catches: its right half mostly dim, flickering", dim > 20 and dim < 40, dim)
	ns.free()
	nl.free()
	# (0.19) the Android app: an export built into it is the oldest, so one of yours wins; off Android, the usual places
	var dir := "user://built_in_test"
	DirAccess.make_dir_recursive_absolute(dir)
	for f in [KeterExport.BUILT_IN, "KETER_export_2026-01-02.zip"]:
		var fh := FileAccess.open(dir.path_join(f), FileAccess.WRITE)
		fh.store_string("x")
		fh.close()
	var newest := KeterExport.find_newest([dir])
	DirAccess.remove_absolute(dir.path_join("KETER_export_2026-01-02.zip"))
	var alone := KeterExport.find_newest([dir])
	DirAccess.remove_absolute(dir.path_join(KeterExport.BUILT_IN))
	DirAccess.remove_absolute(dir)
	ck("0.19 android: the built-in export gives way to any export of yours, and is used when there is none", newest.get_file() == "KETER_export_2026-01-02.zip" and alone.get_file() == KeterExport.BUILT_IN, [newest, alone])
	var MainScript = load("res://scripts/main.gd")
	ck("0.19 android: it is named as the built-in export; off Android the game looks where it always has, and asks for nothing", MainScript.export_name("res://exports/" + KeterExport.BUILT_IN) == "The built-in export"
		and KeterExport.places() == KeterExport.PLACES and not KeterExport.android_can_read())


func _nineteen_scene() -> void:
	Kit.fresh()
	var was_size: Vector2i = root.size
	root.size = Vector2i(1280, 720)
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	await _frames(2)
	var tr: Transition = scene.transition
	ck("0.19: the game has its transitions", tr != null and tr.is_inside_tree())
	# which plays where
	tr.played.clear()
	scene.open_teams()
	scene.show_home()
	var r: Roster = scene.roster
	var ci := -1
	for i in scene.floors.size():
		if scene.floors[i].name == "TEST · Corridor":
			ci = i
	scene.start_battle(ci, [r.card_named("Test Warden")], [], 6)
	await process_frame
	scene.leave()
	await process_frame
	ck("0.19 transition: between the menus a hex wipe; into a fight and out of one, a pixel dissolve", tr.played == ["hex", "hex", "pixels", "pixels"], tr.played)
	# a hex wipe and a pixel dissolve, as they play
	Motion.still = false
	Motion.speed = "normal"
	await _frames(2)
	tr.play(Transition.HEX)
	var hexes := tr.cells.size()
	var holding := tr.playing() and tr.still != null and tr.still.get_size().x > 0
	await create_timer(0.25).timeout
	var mid := tr.progress()
	await create_timer(0.4).timeout
	ck("0.19 transition: a hex wipe holds a still of the old screen in hexagons, takes it away, and is gone in half a second", holding and hexes > 30 and mid > 0.2 and mid < 0.95 and not tr.playing(), [holding, hexes, mid, tr.playing()])
	tr.play(Transition.PIXELS)
	var blocks := tr.cells.size()
	await create_timer(0.6).timeout
	ck("0.19 transition: a pixel dissolve, in blocks of 16, gone as quickly", blocks == int(ceil(1280.0 / 16.0) * ceil(720.0 / 16.0)) and not tr.playing(), blocks)
	Motion.speed = "instant"
	tr.played.clear()
	tr.play(Transition.HEX)
	ck("0.19 transition: none at Instant", not tr.playing() and tr.played == ["hex"])
	Motion.speed = "normal"
	# Victory, powering on, then the tally
	scene.start_battle(ci, [r.card_named("Test Warden"), r.card_named("Test Striker")], [], 6)
	await create_timer(0.7).timeout
	var bt: Battle = scene.battle
	for e in bt.side_units("enemy"):
		e["hp"] = 0
		e["down"] = true
	bt.settle()
	scene.show_result()
	await process_frame
	var ns: NeonScene = scene.neon
	ck("0.19 scene: a won fight plays Victory first, your two standing under it, before any tally", ns != null and ns.won and ns.tokens.size() == 2 and scene.dialog == null and ns.sign == Art.menu_piece("victory"), [ns != null, ns.tokens.size() if ns else -1, scene.dialog != null])
	await create_timer(2.4).timeout
	ck("0.19 scene: and gives way to the tally when it is over", scene.neon == null and scene.dialog != null and scene.dialog.title_label.text == "Victory")
	scene.show_result()
	await process_frame
	ck("0.19 scene: shown again (Leave after looking at the board), the tally comes at once", scene.neon == null and scene.dialog != null)
	scene.dialog.buttons[0].pressed.emit()
	await create_timer(0.7).timeout
	var bt2: Battle = scene.battle
	for u in bt2.side_units("ally"):
		u["hp"] = 0
		u["down"] = true
	bt2.settle()
	scene.show_result()
	await process_frame
	var nl: NeonScene = scene.neon
	ck("0.19 scene: a lost fight plays Defeat, your fallen under it", nl != null and not nl.won and nl.tokens.size() == 2)
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	if nl != null:
		nl._gui_input(tap)
	await process_frame
	ck("0.19 scene: a tap skips it to the tally", scene.neon == null and scene.dialog != null and scene.dialog.title_label.text == "Defeat")
	scene.dialog.buttons[0].pressed.emit()
	await create_timer(0.7).timeout
	# the hand: the Deck beside it, the cards dealt from it, turning face up (a Strike Team's Battle)
	var team: Dictionary = Kit.team()
	Kit.keep([team])
	var fi := -1
	for i in scene.floors.size():
		if scene.floors[i].name == "TEST · Hazards and Cover":
			fi = i
	scene.start_team_battle(fi, team, StrikeTeams.setup_for(team, r, ["Test Warden", "Quillon Vex"], "Test Warden", ["Test Drone"], 3), 21)
	await create_timer(0.7).timeout
	var bt3: Battle = scene.battle
	scene.toggle_hand()
	await process_frame
	var fan: CardFan = scene.hand_tray.grid
	var n: int = bt3.hand.size()
	var on_way := fan.dealing
	var down := fan.tiles.filter(func(t): return t.face_down).size()
	ck("0.19 hand: the Deck sits beside the fan, face down, its count on it; every card of the first hand is dealt from it", fan.pile == bt3.deck.size() and n > 0 and fan.dealt.size() == n and on_way == n and down == n, [fan.pile, n, fan.dealt.size(), on_way, down])
	await create_timer(0.12 * n + 0.6).timeout
	var at_rest := true
	fan._layout()
	ck("0.19 hand: they land in their places, face up", fan.dealing == 0 and fan.tiles.all(func(t): return not t.face_down and t.scale.x == 1.0), fan.dealing)
	scene.toggle_hand()
	scene.toggle_hand()
	await process_frame
	ck("0.19 hand: opened again, nothing new: nothing dealt", fan.dealt.is_empty() and fan.dealing == 0)
	scene.toggle_tray("cons")
	await process_frame
	ck("0.19 hand: the Consumables have no Deck beside them", fan.pile == -1)
	scene.toggle_tray("cons")
	Motion.still = true
	# yours: the card back drawn over in the Companion
	var x := KeterExport.new()
	x.open(FIXTURE)
	Art.load_from(x)
	var mine := Art.card_back()
	var mi := mine.get_image() if mine != null else null
	ck("0.19 export: the card back drawn over in the Companion comes in the export, and is the one the hand shows", mine != null and not (mine is AtlasTexture) and mine.get_size() == Vector2(75, 105)
		and mi != null and mi.get_pixel(37, 3).is_equal_approx(Color("#6dff3a")), mine)
	Art.load_from(null)
	# the Look board shows the back
	scene.open_look_board()
	await _frames(3)
	var lb = scene.look_board if scene.get("look_board") != null else null
	var found := false
	if lb != null:
		var todo: Array = [lb]
		while not todo.is_empty():
			var nd: Node = todo.pop_back()
			if nd.has_meta("cardback"):
				found = true
			todo.append_array(nd.get_children())
	ck("0.19 look: the Look board shows the card back", found)
	scene.queue_free()
	await _frames(2)
	root.size = was_size
	Kit.fresh()


# ---------------------------------------------------------------- 0.20: battlefields grown from chunks
func _chunks_of(x: KeterExport) -> Array:
	return x.floors().map(func(f): return f.raw).filter(func(r): return ChunkGen.is_chunk(r))


func _twenty() -> void:
	var x := KeterExport.new()
	x.open(FIXTURE)
	var chunks := _chunks_of(x)
	var roles := {}
	for c in chunks:
		roles[str(c["chunk"]["role"])] = int(roles.get(str(c["chunk"]["role"]), 0)) + 1
	ck("0.20 chunks: the export carries the 20 built-in District 3 chunks (four more in 0.22): 4 Start, 6 Enemy, 3 Loot, an Exit and 6 Fillers, each a hexagon of 37 tiles at most",
		chunks.size() == 20 and roles == {"start": 4, "enemy": 6, "loot": 3, "exit": 1, "filler": 6} and chunks.all(func(c): return c["hexes"].size() <= 37 and str(c["district"]) == "3"), [chunks.size(), roles])
	# the lattice: six neighbours, each a hexagon's width away, the sides meeting along flat edges
	var dirs_ok := true
	for k in 6:
		var v: Vector2i = ChunkGen.SIDE_VEC[k]
		if Hex.distance(v, Vector2i.ZERO) != 7 or ChunkGen.place(v, 1, false, Vector2i.ZERO) != ChunkGen.SIDE_VEC[(k + 1) % 6]:
			dirs_ok = false
	ck("0.20 chunks: they sit on a lattice of hexagons, each neighbour seven tiles away; turning a chunk a sixth turns its sides one round", dirs_ok)
	ck("0.20 chunks: mirrored, its top row becomes its lower-left edge and its upper-right its bottom; turned, the open sides turn with it",
		ChunkGen.place(Vector2i(1, -3), 0, true, Vector2i.ZERO) == Vector2i(-3, 1) and ChunkGen.world_side(0, 0, true) == 4 and ChunkGen.world_side(1, 0, true) == 3 and ChunkGen.world_side(2, 2, false) == 4)
	# growing one
	var lv := ChunkGen.generate(chunks, "3", 2, "medium", 12345)
	var g: Array = lv.get("generated", {}).get("chunks", [])
	var f := FloorData.from_dict(lv)
	ck("0.20 grow: a medium battlefield is 5 chunks: a Start, then a Filler, an Enemy, a Filler and Loot, as one floor of the Sandbox's own kind", g.size() == 5 and g[0][5] == "start" and g.map(func(c): return c[5]).has("enemy") and g.map(func(c): return c[5]).has("loot")
		and lv["battlefieldSize"] == "medium" and lv["poiType"] == "Generated" and f.tiles.size() > 150 and not f.player_spawns().is_empty(), [g.size(), f.tiles.size()])
	var sizes := ["small", "medium", "large"].map(func(z): return (ChunkGen.generate(chunks, "3", 3, z, 777).get("generated", {}).get("chunks", []) as Array).size())
	ck("0.20 grow: small is 3 chunks, medium 5, large 7", sizes == [3, 5, 7], sizes)
	ck("0.20 grow: the same seed grows the same battlefield; another seed, another", JSON.stringify(ChunkGen.generate(chunks, "3", 2, "medium", 12345)) == JSON.stringify(lv)
		and JSON.stringify(ChunkGen.generate(chunks, "3", 2, "medium", 54321)) != JSON.stringify(lv))
	var foes: Array = lv["hexes"].filter(func(h): return h[1].get("c") == 0)
	ck("0.20 grow: every enemy pad takes the Skull Level asked for", not foes.is_empty() and foes.all(func(h): return h[1].get("lvl") == 2), foes.size())
	var all_ok := true
	for i in 60:
		var t := ChunkGen.generate(chunks, "3", 1 + i % 6, ["small", "medium", "large"][i % 3], i * 104729 + 3)
		if t.is_empty() or not ChunkGen.connected(t):
			all_ok = false
	ck("0.20 grow: sixty grown at every Skull Level and size, every one whole: your pads reach every enemy pad, Loot Tile, chest and hazard", all_ok)
	# where sides don't both open, a wall along the join
	var walled := {"v": 6, "name": "W", "district": "3", "hexes": chunks[0]["hexes"], "walls": [], "marks": [], "symDefs": [], "colorLabels": chunks[0]["colorLabels"],
		"chunk": {"role": "filler", "sides": [true, false, false, false, false, false], "skullMin": 1, "skullMax": 6}}
	var placed := [{"lv": chunks[0], "at": Vector2i.ZERO, "rot": 0, "mir": false, "open": [true, true, true, true, true, true], "hops": 0, "role": "start"},
		{"lv": walled, "at": ChunkGen.SIDE_VEC[1], "rot": 0, "mir": false, "open": [true, false, false, false, false, false], "hops": 1, "role": "filler"}]
	var joined := ChunkGen.assemble(placed, "3", 1, "small", "J")
	var join_walls: Array = joined["walls"].filter(func(w): var e := str(w[0]).split("|"); return ChunkGen._within(ChunkGen.parse(e[0]), Vector2i.ZERO) != ChunkGen._within(ChunkGen.parse(e[1]), Vector2i.ZERO))
	ck("0.20 grow: where an open side meets a walled one, a wall runs the whole join (seven tile edges)", join_walls.size() == 7, join_walls.size())
	ck("0.20 grow: too few chunks (no Enemy chunk, or none in the District), nothing is grown", ChunkGen.generate(chunks.filter(func(c): return c["chunk"]["role"] != "enemy"), "3", 2, "medium", 1).is_empty()
		and ChunkGen.generate(chunks, "4", 2, "medium", 1).is_empty() and not ChunkGen.can(chunks, "4", 2) and ChunkGen.can(chunks, "3", 2))
	var k := ChunkGen.gen_key("3", 2, "medium", 12345)
	ck("0.20 grow: a key says all it is grown from, and grows it again anywhere", k == "gen|3|2|medium|12345" and ChunkGen.is_gen_key(k) and JSON.stringify(ChunkGen.from_key(chunks, k)) == JSON.stringify(lv))
	# the World Map: a POI's floors grown, the same until cleared; an ambush small; a Boss floor last
	var floors := x.floors()
	var w := World.new(Loot.new(null, 1), x.content("world_map"), floors)
	var fl := w.draw_floors("3", 4, 3, false, "2,-1")
	var again := w.draw_floors("3", 4, 3, false, "2,-1")
	var other := w.draw_floors("3", 4, 3, false, "3,-1")
	ck("0.20 world: a POI in District 3 grows its floors: medium ones, the last large from Skull 4; the same tile grows the same; another tile, others",
		fl.size() == 3 and fl.all(func(f2): return ChunkGen.is_gen_key(f2)) and str(fl[0]).contains("|medium|") and str(fl[2]).contains("|large|") and fl == again and fl != other, fl)
	w.clear("2,-1", 1)
	var after := w.draw_floors("3", 4, 3, false, "2,-1")
	ck("0.20 world: once the tile is cleared, it grows anew", after != fl, after)
	var amb := w.draw_floors("3", 2, 1, true, "1,0")
	ck("0.20 world: an ambush is a small battlefield", amb.size() == 1 and str(amb[0]).contains("|small|"), amb)
	ck("0.20 world: a grown floor stands for itself, and is grown again to fight on", w.floor_named(fl[0]) != null and not w.level(fl[0]).is_empty() and w.level(fl[0])["name"] == "Generated \u00b7 D3 \u00b7 Skull 4")
	var whole := w.draw_floors("4", 2, 2, false, "9,9")
	ck("0.20 world: a District with no chunks still draws whole floors", whole.size() == 2 and not whole.any(func(f2): return ChunkGen.is_gen_key(f2)), whole)
	ck("0.20 world: the chunks are kept apart from the floors a fight is drawn from", w.chunks.size() == 20 and not w.floors.any(func(f2): return str(f2["key"]).begins_with("Chunk")))
	# a Boss floor last, when one fits
	var boss_raw := {"v": 6, "name": "Boss · Foundry Core", "district": "3", "poiType": "Boss", "level": "4", "hexes": floors[0].raw["hexes"], "colorLabels": floors[0].raw["colorLabels"]}
	var w2 := World.new(Loot.new(null, 1), x.content("world_map"), floors + [FloorData.from_dict(boss_raw)])
	var withboss := w2.draw_floors("3", 4, 3, false, "2,-1")
	var single := w2.draw_floors("3", 4, 1, false, "2,-1")
	ck("0.20 world: a POI of more than one floor ends on a Boss floor that fits its District and Skull; a single floor is grown", withboss[2] == "Boss · Foundry Core" and ChunkGen.is_gen_key(withboss[0]) and ChunkGen.is_gen_key(single[0]), [withboss, single])
	var w3 := World.new(Loot.new(null, 1), x.content("world_map"), floors.filter(func(f2): return not ChunkGen.is_chunk(f2.raw)) + [FloorData.from_dict(boss_raw)])
	ck("0.20 world: and without chunks, a Boss floor is never drawn as an ordinary one", not w3.draw_floors("3", 4, 4, false, "2,-1").has("Boss · Foundry Core"))


func _twenty_scene() -> void:
	Kit.fresh()
	var was_size: Vector2i = root.size
	root.size = Vector2i(1280, 720)
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	await _frames(2)
	ck("0.20: the chunks are not floors to pick for a fight", not scene.floors.any(func(f): return ChunkGen.is_chunk(f.raw)) and scene.campaign.world.chunks.size() == 20)
	# a deployment's POI grown, fought on
	var c: Campaign = scene.campaign
	c.world.tables["ambushStep"] = 0
	c.deploy.start(Kit.field_team())
	var poi := ""
	for k in c.world.map["tiles"]:
		if c.world.district_of(k) == "3" and c.world.content_at(k) != null and str(c.world.content_at(k).get("kind", "")) == "poi" and not (c.world.content_at(k).get("unique") is Dictionary):
			poi = k
			break
	c.deploy.cur()["pos"] = poi
	var sp = c.deploy.enter_poi(poi) if poi != "" else null
	ck("0.20: a District 3 POI entered on a deployment grows its floor", sp != null and ChunkGen.is_gen_key(sp["floor"]), sp)
	if sp != null:
		scene.start_deploy_fight()
		await _frames(2)
		var df = scene.setup.get("deploy_floor") if scene.setup.get("deploy_floor") != null else null
		ck("0.20: and it is fought on: the setup opens on the grown battlefield", scene.setup.visible and scene.map_screen.note == "", scene.map_screen.note)
	c.reset()
	scene.queue_free()
	await _frames(2)
	root.size = was_size
	Kit.fresh()


# ---------------------------------------------------------------- 0.21: the movement keywords (Revision 16.1)
## A floor with a gap the whole way down the middle (no tiles at q = 0): walking
## can't cross it, a Leap can.
func _gap_floor() -> FloorData:
	var hexes := []
	for q in range(-4, 5):
		for r in range(-4, 5):
			if absi(q + r) > 4 or q == 0:
				continue
			hexes.append(["%d,%d" % [q, r], {}])
	return FloorData.from_dict({"v": 6, "name": "Gap", "hexes": hexes, "walls": [], "marks": [], "symDefs": [], "colorLabels": {}})


func _twentyone() -> void:
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)
	# the library
	var names := ["Lunge", "Charge", "Dash", "Leap"]
	var kws := names.map(func(n): return Keywords.by_name(n))
	ck("0.21 keywords: Lunge and Charge are Modifiers, Dash and Leap Effects, each with a number; Lunge, Dash and Leap count tiles",
		kws.all(func(k): return k != null and k["num"] == "amount") and kws.map(func(k): return k["cat"]) == ["modifier", "modifier", "effect", "effect"]
		and Keywords.render("[[Lunge 2]]. [[Charge 2]]. [[this Unit]] gains [[Dash 2]]. [[this Unit]] gains [[Leap 3]].") == "Lunge 2 tiles. Charge 2. This Unit gains Dash 2 tiles. This Unit gains Leap 3 tiles.",
		Keywords.render("[[Lunge 2]]. [[Charge 2]]. [[this Unit]] gains [[Dash 2]]. [[this Unit]] gains [[Leap 3]]."))
	var pa := Keywords.problems(Keywords.analyse("[[Lunge 2]]."), {"kind": "passive"})
	ck("0.21 keywords: Lunge or Charge in a Passive is flagged; on an Action it reads clean", pa.has("Lunge is made with an attack: put it on a Melee Action") and Keywords.problems(Keywords.analyse("[[Lunge 2]]. [[Charge 1]]."), {"kind": "action"}).is_empty(), pa)
	ck("0.21 power: Lunge and Charge add to an attack (1 a tile, 1 a point) rather than multiply it; Dash and Leap are worth 1 a tile",
		Scoring.keyword_points("[[Lunge 2]]. [[Charge 2]].", true) == 8 and Scoring.keyword_points("[[this Unit]] gains [[Dash 2]].") == 2 and Scoring.keyword_points("[[this Unit]] gains [[Leap 3]].") == 3,
		[Scoring.keyword_points("[[Lunge 2]]. [[Charge 2]].", true), Scoring.keyword_points("[[this Unit]] gains [[Dash 2]].")])
	var bld := Builder.new()
	bld.opt = {"kind": "action", "role": "melee"}
	var melee: Array = bld.mods_for().map(func(m): return m["name"])
	bld.opt = {"kind": "action", "role": "ranged"}
	var ranged: Array = bld.mods_for().map(func(m): return m["name"])
	ck("0.21 builder: Lunge and Charge are offered on a Melee Action, not on a Ranged one", melee.has("Lunge") and melee.has("Charge") and not ranged.has("Lunge") and not ranged.has("Charge") and ranged.has("Burst"), [melee, ranged])
	var sk_card = r.card_named("Test Skirmisher")
	var st_card = r.card_named("Test Skitter")
	ck("0.21: the export carries the Test Skirmisher and the Test Skitter, written in the four keywords", sk_card != null and st_card != null
		and str(Roster.entries_of(sk_card).map(func(a): return a.get("text", ""))).contains("[[Lunge 2]]") and str(Roster.entries_of(st_card).map(func(a): return a.get("text", ""))).contains("[[Dash 1]]"))
	var gap := _gap_floor()
	# Lunge
	var sk := _mk(r, "Test Skirmisher", "ally", "a1", Vector2i(-2, -1))
	var gr := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(-2, 2))
	var far := _mk(r, "Test Grunt", "enemy", "e2", Vector2i(-3, 4))
	var b := Battle.from_state(gap, [sk, gr, far], 3, r.cards)
	b.deploy_start()
	var pounce := _act(sk, "Pounce")
	ck("0.21 Lunge: Pounce (Lunge 2) reaches an Enemy 3 tiles off, not one 4 off; without its Lunge it reaches only beside it",
		b.can_reach(sk, pounce, gr) and not b.can_reach(sk, pounce, far) and not b.can_reach(sk, pounce, gr, true) and b.targets_for(sk, pounce).map(func(u): return u["id"]) == ["e1"])
	var spot = b.lunge_spot(sk, pounce, gr)
	ck("0.21 Lunge: it would walk 2 tiles to stand beside the target", spot != null and spot["cost"] == 2 and Rules.hex_distance(spot, gr["pos"]) == 1, spot)
	ck("0.21 Charge: the odds show Charge's 2 once the Lunge would bring its travel to 3 or more", b.odds(sk, pounce, gr)["dmg"] == 3 and (func(): sk["travel"] = 1; return b.odds(sk, pounce, gr)["dmg"] == 5).call(), b.odds(sk, pounce, gr))
	var hz_floor := _floor_named(x, "TEST · Hazards and Cover")
	var hs := _mk(r, "Test Skirmisher", "ally", "a1", Vector2i(-2, 3))
	var hg := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(-3, 1))
	var bh := Battle.from_state(hz_floor, [hs, hg], 3, r.cards)
	var hspot = bh.lunge_spot(hs, _act(hs, "Pounce"), hg)
	ck("0.21 Lunge: it keeps off a hazard where another tile beside the target will do", hspot != null and bh.fx.hazard_at(Vector2i(hspot["q"], hspot["r"])) == null and Rules.hex_distance(hspot, hg["pos"]) == 1, hspot)
	sk["travel"] = 0
	var mark := b.log.size()
	var res := b.attack(sk, pounce, gr)
	ck("0.21 Lunge: used, the Skirmisher walks the 2 tiles first, free, and strikes from beside it; the Log says so",
		Rules.hex_distance(sk["pos"], gr["pos"]) == 1 and int(sk["travel"]) == 2 and _texts(b, mark)[0] == "Test Skirmisher lunges 2 tiles at Test Grunt" and int(sk["nrg"]) == 2, [_texts(b, mark), sk["pos"]])
	# Charge, in the attack
	var sk2 := _mk(r, "Test Skirmisher", "ally", "a1", Vector2i(-2, 1))
	var gr2 := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(-2, 2))
	var b2 := Battle.from_state(gap, [sk2, gr2], 3, r.cards)
	sk2["travel"] = 3
	var hits := 0
	for i in 12:
		gr2["hp"] = 18
		gr2["statuses"] = []
		gr2["mods"] = []
		sk2["nrg"] = 3
		var rr := b2.attack(sk2, _act(sk2, "Pounce"), gr2)
		if Rules.truthy(rr.get("damage")):
			hits += 1
			if int(rr["damage"]) != 5 or not str(rr["line"]).contains("(Charge +2)"):
				hits = -100
	ck("0.21 Charge: having moved 3 tiles this turn, each blow that lands deals 3 + 2, and the Log says (Charge +2)", hits > 0, hits)
	# Dash
	var sk3 := _mk(r, "Test Skirmisher", "ally", "a1", Vector2i(-4, 0))
	var b3 := Battle.from_state(gap, [sk3, _mk(r, "Test Grunt", "enemy", "e1", Vector2i(3, 0))], 3, r.cards)
	b3._hook()
	b3.fx.run_text("[[this Unit]] gains [[Dash 2]].", {"actor": sk3, "sourceCard": "Test"})
	ck("0.21 Dash: one of yours given Dash 2 may move its 4 and 2 more this turn", b3.speed(sk3) == 6 and _texts(b3).has("Test Skirmisher may Dash 2 tiles more this turn"), [b3.speed(sk3), _texts(b3)])
	b3.move(sk3, Vector2i(-3, 0))
	ck("0.21 Dash: having moved 1, it may still move the Dash's 2 (a Unit moves once a round, and a Dash's tiles are over and above)", b3.has_moved(sk3) and b3.speed(sk3) == 2 and b3.can_move(sk3) and b3.reach(sk3).all(func(t): return t["cost"] <= 2), b3.speed(sk3))
	b3.move(sk3, Vector2i(-3, 2))
	ck("0.21 Dash: and then it is spent", b3.speed(sk3) == 0 and not b3.can_move(sk3) and int(sk3["travel"]) == 3)
	var sk4 := _mk(r, "Test Skirmisher", "ally", "a2", Vector2i(-4, 2))
	b3.units.append(sk4)
	b3.fx.run_text("[[this Unit]] gains [[Dash 1]].", {"actor": sk4, "sourceCard": "Test"})
	b3.end_player_turn()
	ck("0.21 Dash: what isn't used is gone when your turn ends", not Rules.truthy(sk4.get("dash")) and b3.speed(sk4) == 4)
	# an Enemy's Dash: at once, away from the Unit it struck
	var al := _mk(r, "Test Warden", "ally", "a1", Vector2i(1, 0))
	var sx := _mk(r, "Test Skitter", "enemy", "e1", Vector2i(2, 0))
	var b4 := Battle.from_state(gap, [al, sx], 3, r.cards)
	b4._hook()
	b4.fx.run_text("[[this Unit]] gains [[Dash 2]].", {"actor": sx, "target": al, "sourceCard": "Rake"})
	ck("0.21 Dash: an Enemy Dashes at once, away from the Unit it struck", Rules.hex_distance(sx["pos"], al["pos"]) == 3 and _texts(b4).any(func(t): return t.begins_with("Test Skitter Dashes 2 tiles away")), [sx["pos"], _texts(b4)])
	# Leap
	var lp := _mk(r, "Test Warden", "ally", "a1", Vector2i(-1, 0))
	var b5 := Battle.from_state(gap, [lp, _mk(r, "Test Grunt", "enemy", "e1", Vector2i(4, -4))], 3, r.cards)
	b5._hook()
	var walk: Array = b5.reach(lp)
	ck("0.21 Leap: without it, the gap stops a walk: nothing beyond it is in reach", not walk.any(func(t): return t["q"] > 0))
	b5.fx.run_text("[[this Unit]] gains [[Leap 3]] for [[turns 2]].", {"actor": lp, "sourceCard": "Spring"})
	var jumps: Array = b5.reach(lp).filter(func(t): return t["q"] > 0)
	ck("0.21 Leap: with Leap 3 the tiles beyond the gap within 3 are in reach, each costing the tiles jumped", Battle.leap_of(lp) == 3 and not jumps.is_empty() and jumps.all(func(t): return t.get("leap", false) and t["cost"] == Rules.hex_distance(lp["pos"], t) and t["cost"] <= 3), jumps.size())
	var path := b5.move(lp, Vector2i(2, 0))
	ck("0.21 Leap: the jump lands where it lands, and counts its 3 tiles as moved", path == ([Vector2i(2, 0)] as Array[Vector2i]) and Battle.tile_of(lp) == Vector2i(2, 0) and int(lp["travel"]) == 3 and _texts(b5).has("Test Warden leaped 3 tiles"), [path, _texts(b5)])
	Rules.tick_statuses(b5.units, false)
	Rules.tick_statuses(b5.units, false)
	ck("0.21 Leap: given for 2 turns, it lasts 2", Battle.leap_of(lp) == 0)
	# the Test Skitter's turn: it leaps the gap, lunges, claws, and skitters off
	var wd := _mk(r, "Test Warden", "ally", "a1", Vector2i(-4, 1))
	var sk5 := _mk(r, "Test Skitter", "enemy", "e1", Vector2i(1, 0))
	var b6 := Battle.from_state(gap, [wd, sk5], 7, r.cards)
	b6.deploy_start()
	ck("0.21 Skitter: always able to Leap 2, and to Dash 1 after attacking", Battle.leap_of(sk5) == 2 and int(sk5.get("pDash", 0)) == 1)
	var m6 := b6.log.size()
	b6.enemy_turn(sk5)
	var t6 := _texts(b6, m6)
	ck("0.21 Skitter: it crosses the gap, attacks with its Claw (lunging if it must), and Dashes 1 tile away after", Battle.tile_of(sk5).x < 0 and t6.any(func(t): return t.begins_with("Test Skitter used Claw on Test Warden")) and t6[t6.size() - 1].begins_with("Test Skitter Dashes 1 tile away"), t6)


# ---------------------------------------------------------------- 0.22: content batch 1 (District 3, fast melee)
func _twentytwo() -> void:
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)
	var batch := ["Skitterling", "Skitter Stalker", "Brood Matriarch", "Ilsa Varn, Jump-Frame Pilot", "Kinetic Surge", "Gravity Well",
		"Leaper Greaves", "Momentum Plating", "Flank Them", "Pin the Runner", "Spring Chip", "Gyro Chip", "Grav-Boot Charge",
		"Adrenal Overdrive", "Vault Strike", "Skitter Step", "Kinetic Recycler", "Gantry Mapper"]
	var missing := batch.filter(func(n): return r.card_named(n) == null)
	ck("0.22 batch 1: the export carries its 18 cards", missing.is_empty(), missing)
	var mat = r.card_named("Brood Matriarch")
	var stl = r.card_named("Skitter Stalker")
	var drops_of := func(c): return (c.get("setDrops", []) as Array).map(func(d): return str(d.get("item")))
	ck("0.22 batch 1: the Skitterling is Skull 2, the Stalker an Elite of Skull 3, the Matriarch a Mini-Boss of Skull 4",
		mat != null and stl != null and int(Rules.num(r.card_named("Skitterling").get("skullLevel"), 0)) == 2 and int(Rules.num(stl.get("skullLevel"), 0)) == 3
		and int(Rules.num(mat.get("skullLevel"), 0)) == 4 and str(stl.get("cardType")) == "elite" and str(mat.get("cardType")) == "miniboss")
	ck("0.22 batch 1: the Matriarch can drop the Skitter Frame and a Kinetic Recycler; the Stalker a Grav-Boot Charge",
		drops_of.call(mat).has("ch:ch_skitter_frame") and drops_of.call(mat).has("cd:Kinetic Recycler") and drops_of.call(stl).has("cd:Grav-Boot Charge"),
		[drops_of.call(mat), drops_of.call(stl)])
	# the frame and its Troops
	var p := Progress.new(Loot.new(null, 1), x.content("pools"), x.content("chassis"), x.content("tables"))
	var ch = p.chassis.get("ch_skitter_frame")
	ck("0.22 frame: the export carries the Skitter Frame: District 3, a Hexapod for Melee, power 14 and two abilities, HP 12, AC 11, Movement 5",
		ch is Dictionary and str(ch.get("district")) == "3" and ch.get("bodyPlan") == "Hexapod" and ch.get("subtypes") == ["Melee"] and int(ch["powerCap"]) == 14
		and int(ch["abilityCap"]) == 2 and int(ch["stats"]["hp"]) == 12 and int(ch["stats"]["ac"]) == 11 and int(ch["stats"]["move"]) == 5
		and ["Lunge", "Charge", "Dash", "Leap"].all(func(k): return (ch["allowed"] as Array).has(k)), ch)
	var ws := Workshop.new(p, null)
	ws.set_prebuilts(r.from_export)
	var pre := ws.prebuilts().filter(func(d): return d.get("chassis") == "ch_skitter_frame")
	ck("0.22 frame: two pre-built Troops on it come with the export, the Skitter Runner Mk I and the Skitter Harrier Mk I, each fitting its frame",
		pre.map(func(d): return d["name"]) == ["Skitter Runner Mk I", "Skitter Harrier Mk I"] and pre.all(func(d): return ws.check(d)["ok"]),
		[pre.map(func(d): return d["name"]), pre.map(func(d): return ws.check(d)["reasons"])])
	var pool: Array = Progress.DEFAULT_POOLS["3"]["items"]
	ck("0.22 pools: Lunge, Charge, Dash and Leap blueprints join District 3's, in the game's own and in the export's",
		["bp:Lunge:1", "bp:Charge:1", "bp:Dash:1", "bp:Leap:1"].all(func(i): return pool.has(i) and (p.pools["3"]["items"] as Array).has(i)), p.pools)
	# a Support Action aimed only at this Unit
	var gap := _gap_floor()
	var il := _mk(r, "Ilsa Varn, Jump-Frame Pilot", "ally", "a1", Vector2i(-2, 1))
	var gr := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(-2, 3))
	var b := Battle.from_state(gap, [il, gr], 3, r.cards)
	b.deploy_start()
	var jj := _act(il, "Jump Jets")
	ck("0.22 self-use: Jump Jets (Support, aimed only at this Unit) needs no target; Hammerfall still does",
		not jj.is_empty() and Battle.self_only(jj) and b.targets_for(il, jj).is_empty() and not Battle.self_only(_act(il, "Hammerfall")))
	var n0 := int(il["nrg"])
	var mark := b.log.size()
	var line := b.use_on_self(il, jj)
	ck("0.22 self-use: used, it pays its Energy, says so in the Log, and Ilsa has Leap 4 for the turn",
		line == "Ilsa Varn, Jump-Frame Pilot used Jump Jets" and _texts(b, mark).has(line) and int(il["nrg"]) == n0 - int(Rules.num(jj.get("cost"), 0)) and Rules.truthy(il.get("acted"))
		and (il.get("mods", []) as Array).any(func(m): return m.get("stat") == "LEAP" and int(m.get("amt", 0)) == 4), [line, il.get("mods")])
	# cards in the haul
	p.card_source = func(): return r.from_export
	var got := []
	p.card_sink = func(n): got.append(n)
	var p1 := p.card_pool("3", 1)
	var p3 := p.card_pool("3", 3)
	ck("0.22 cards: a Skull 1 haul can hold a common Consumable or Prototype, never a rarer one; at Skull 3 the rare ones join",
		p1.has("Grav-Boot Charge") and not p1.has("Adrenal Overdrive") and not p1.has("Kinetic Recycler") and p3.has("Kinetic Recycler") and p3.has("Gantry Mapper")
		and not p3.any(func(n): return str(n).begins_with("Test ")), [p1, p3])
	ck("0.22 cards: one found reaches the dock, and reads as itself", p.grant("cd:Grav-Boot Charge") and got == ["Grav-Boot Charge"] and p.item_name("cd:Grav-Boot Charge") == "Grav-Boot Charge", [got, p.item_name("cd:Grav-Boot Charge")])
	var lt := Loot.new(null, 1)
	var src: Dictionary = lt.tables["sources"]
	ck("0.22 cards: the chances: an Elite 25%, a Mini-Boss 50%, a Boss always, a Locked Chest 10%; a plain Enemy and a Loot Tile never",
		[src["enemy"]["card"], src["elite"]["card"], src["miniboss"]["card"], src["boss"]["card"], src["lootTile"]["card"], src["chest"]["card"]] == [0, 25, 50, 100, 0, 10])
	var d3 := _gap_floor()
	d3.district = "3"
	var bb := Battle.from_state(d3, [_mk(r, "Test Grunt", "ally", "a1", Vector2i(-2, 1))], 3, r.cards)
	bb.progress = Progress.new(Loot.new(null, 4), x.content("pools"), x.content("chassis"), x.content("tables"))
	var m0 := bb.log.size()
	bb.find_items("boss", {}, "The Boss")
	var cds := bb.found.filter(func(i): return str(i).begins_with("cd:"))
	ck("0.22 cards: a Boss always leaves one, a District 3 card of the fight's Skull Level, and the Log says so",
		cds.size() == 1 and bb.progress.card_pool("3", bb.poi_skull()).has(str(cds[0]).substr(3)) and _texts(bb, m0).any(func(t): return str(t).begins_with("The Boss leaves a card: ")),
		[bb.found, _texts(bb, m0)])
	# the chunks
	var chunks := _chunks_of(x)
	var new_ones := chunks.filter(func(c): return ["Gantry Landing", "Skitter Nest", "Gantry Crossing", "Catwalk Run"].any(func(n): return str(c.get("name", "")).ends_with(n)))
	ck("0.22 chunks: four more for gaps and gantries: Gantry Landing (a Start), Skitter Nest and Gantry Crossing (Enemy), Catwalk Run (a Filler)",
		new_ones.size() == 4 and new_ones.map(func(c): return c["chunk"]["role"]).has("start") and new_ones.filter(func(c): return c["chunk"]["role"] == "enemy").size() == 2,
		new_ones.map(func(c): return [c.get("name"), c["chunk"]["role"]]))
	# the art
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/art.json"))
	var toks: Array = m["tokens"].values().map(func(e): return e["name"])
	ck("0.22 art: a token for each of batch 1's Units and the two pre-built Troops, and a picture for each of its cards that is not a Unit",
		["Skitterling", "Skitter Stalker", "Brood Matriarch", "Ilsa Varn, Jump-Frame Pilot", "Skitter Runner Mk I", "Skitter Harrier Mk I"].all(func(n): return toks.has(n))
		and m["cardart"].values().filter(func(e): return ["Kinetic Surge", "Gantry Mapper", "Vault Strike", "Pin the Runner", "Spring Chip", "Gyro Chip"].has(e["name"])).size() == 6, toks.size())



# ---------------------------------------------------------------- 0.23: Revision 16.3's eleven keywords, and Actions aimed at tiles
## A plain floor of radius 5, every tile there.
func _open_floor() -> FloorData:
	var hexes := []
	for q in range(-5, 6):
		for r in range(-5, 6):
			if absi(q + r) <= 5:
				hexes.append(["%d,%d" % [q, r], {}])
	return FloorData.from_dict({"v": 6, "name": "Open", "hexes": hexes, "walls": [], "marks": [], "symDefs": [], "colorLabels": {"1": "Half Cover Barricade", "5": "Full Cover Barricade"}})


func _twentythree() -> void:
	var x := KeterExport.new()
	x.open(FIXTURE)
	var r := Roster.new(x)
	# the library
	var names := ["Troop", "Hero", "all allies", "all enemies", "Aim", "Draw", "gain Aether", "Hardened", "Barricade", "Line", "Cone"]
	var cats := names.map(func(n): return Keywords.by_name(n)["cat"] if Keywords.by_name(n) != null else null)
	ck("0.23 keywords: the library holds 94, the eleven among them: Troop and Hero narrow a Target, all allies and all enemies are Targets, Aim a Stat, Draw, gain Aether and Barricade Effects, Hardened a Status, Line and Cone Modifiers",
		Keywords.KEYWORDS.size() == 94 and cats == ["target", "target", "target", "target", "stats", "effect", "effect", "status", "effect", "modifier", "modifier"] and Keywords.STATS.has("Aim"), [Keywords.KEYWORDS.size(), cats])
	var reads := ["[[Barricade Full]] on [[target tile]].", "[[all allies]] [[Troop]] gain [[Aim +1]] for [[turns 1]].", "[[target ally]] [[Hero]] gains [[Hardened 2]] for [[turns 1]].", "[[gain Aether 1]]. [[Draw 2]].", "[[target enemy]] takes [[damage 6]] with [[Line 4]]."].map(func(t): return Keywords.render(t))
	ck("0.23 keywords: they read as the Companion prints them", reads == ["Full Cover Barricade on target tile.", "All Troop allies gain +1 Aim for 1 turn.", "Target Hero ally gains Hardened 2 for 1 turn.", "Gain Aether 1. Draw 2.", "Target enemy takes damage 6 with Line 4 tiles."], reads)
	var pr := [Keywords.problems(Keywords.analyse("[[this Unit]] gains [[Line 2]]."), {"kind": "passive"}), Keywords.problems(Keywords.analyse("[[Barricade Huge]] on [[target tile]]."), {"kind": "action"}),
		Keywords.problems(Keywords.analyse("[[target ally]] gains [[Barricade Full]]."), {"kind": "action"}), Keywords.problems(Keywords.analyse("[[all enemies]] face an [[Execute]]."), {"kind": "action"})]
	ck("0.23 keywords: a Line in a Passive, a Barricade that isn't Half or Full, or not on a tile, are flagged; an Execute on all enemies is fine",
		pr[0].has("Line is a shape an attack makes: put it on an Action") and pr[1].has("Barricade needs Half or Full") and pr[2].has("Barricade goes on a tile: use target tile") and pr[3].is_empty(), pr)
	var pts := [Scoring.keyword_points("[[all allies]] gain [[Aim +1]] for [[turns 1]]."), Scoring.keyword_points("[[all allies within 1]] gain [[Aim +1]] for [[turns 1]]."),
		Scoring.keyword_points("[[Line 4]].", true), Scoring.keyword_points("[[Cone 2]].", true), Scoring.keyword_points("[[Draw 2]]."), Scoring.keyword_points("[[gain Aether 1]]."),
		Scoring.keyword_points("[[Barricade Full]] on [[target tile]]."), Scoring.keyword_points("[[target enemy]] gains [[Hardened 2]] for [[turns 1]]."), Scoring.keyword_points("[[all enemies]] take [[damage 2]].")]
	ck("0.23 power: as scoring.js prices them (a whole side x3, a Line 4 x2, a Cone 2 x2)", pts == [9, 5, 8, 8, 4, 2, 3, 7, 6], pts)
	# the builder
	var bld := Builder.new()
	bld.opt = {"kind": "action", "role": "support"}
	bld.st = Builder.blank()
	var tg: Array = bld.targets_for().map(func(o): return o["name"])
	var nw: Array = bld.narrow_for().map(func(o): return o["name"])
	var sup_mods: Array = bld.mods_for().map(func(o): return o["name"])
	bld.st["target"] = {"name": "target tile", "n": null, "narrow": []}
	var on_tile: Array = bld.effects_for().map(func(o): return o["name"])
	bld.st["target"] = {"name": "target ally", "n": null, "narrow": []}
	var on_ally: Array = bld.effects_for().map(func(o): return o["name"])
	bld.opt = {"kind": "action", "role": "ranged"}
	var rng_mods: Array = bld.mods_for().map(func(o): return o["name"])
	ck("0.23 builder: it offers all allies and all enemies, Troop and Hero; a Barricade only on a target tile; Line and Cone on an attack, not on a Support Action",
		tg.has("all allies") and tg.has("all enemies") and nw.has("Troop") and nw.has("Hero") and on_tile.has("Barricade") and not on_ally.has("Barricade")
		and rng_mods.has("Line") and rng_mods.has("Cone") and not sup_mods.has("Line"), [tg, nw, rng_mods, sup_mods])
	var rt := ["[[Barricade Full]] on [[target tile]].", "[[Draw 2]].", "[[all enemies]] take [[damage 2]]."].map(func(t): return Builder.build(Builder.from_sentence(t)))
	ck("0.23 builder: and writes these sentences back as they were", rt == ["[[Barricade Full]] on [[target tile]].", "[[Draw 2]].", "[[all enemies]] take [[damage 2]]."], rt)
	# the blueprints
	var p := Progress.new(Loot.new(null, 1), x.content("pools"), x.content("chassis"), x.content("tables"))
	var bps := names.map(func(n): return p.blueprint_of(n))
	ck("0.23 blueprints: every one of the eleven is a blueprint, the numbered ones in three levels (a Line's up to 2, 3 and 4)",
		bps.all(func(bp): return bp != null) and p.blueprint_of("Line")["caps"] == [2, 3, 4] and p.blueprint_of("Hardened")["levels"] == 3 and p.blueprint_of("Troop")["levels"] == 1
		and p.blueprint_of("target enemy") == null, bps.map(func(bp): return bp["name"] if bp != null else null))
	# Troop and Hero; all allies and all enemies
	var fl := _open_floor()
	var h := _mk(r, "Test Warden", "ally", "h1", Vector2i(0, 0))
	var t := _mk(r, "Test Drone", "ally", "t1", Vector2i(4, 0))
	var e1 := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(-4, 4))
	var e2 := _mk(r, "Test Grunt", "enemy", "e2", Vector2i(4, -4))
	var b := Battle.from_state(fl, [h, t, e1, e2], 3, r.cards)
	b._hook()
	var ac0 := [int(Rules.effective(h)["ac"]), int(Rules.effective(t)["ac"])]
	b.fx.run_text("[[all allies]] [[Troop]] gain [[AC +2]] for [[turns 1]].", {"actor": h, "sourceCard": "Test"})
	ck("0.23 Troop: all Troop allies reaches the Drone 4 tiles off, and not the Warden, a Hero", int(Rules.effective(t)["ac"]) == ac0[1] + 2 and int(Rules.effective(h)["ac"]) == ac0[0])
	b.fx.run_text("[[all allies]] [[Hero]] gain [[MS +1]] for [[turns 1]].", {"actor": h, "sourceCard": "Test"})
	ck("0.23 Hero: all Hero allies reaches the Warden only", (h.get("mods", []) as Array).any(func(m): return m.get("stat") == "MS") and not (t.get("mods", []) as Array).any(func(m): return m.get("stat") == "MS"))
	var hp := [e1["hp"], e2["hp"]]
	b.fx.run_text("[[all enemies]] take [[damage 2]].", {"actor": h, "sourceCard": "Test"})
	ck("0.23 all enemies: every Enemy takes it, however far", e1["hp"] == hp[0] - 2 and e2["hp"] == hp[1] - 2 and h["hp"] == h["hpMax"], [e1["hp"], e2["hp"]])
	# Aim, and Hardened, in the odds and the rules
	var w := _mk(r, "Test Warden", "ally", "a1", Vector2i(0, 0))
	var g := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(3, 0))
	var bo := Battle.from_state(fl, [w, g], 3, r.cards)
	bo._hook()
	var pv := _act(w, "Pinning Volley")
	var before: Dictionary = bo.odds(w, pv, g)
	bo.fx.run_text("[[this Unit]] gains [[Aim +4]] for [[turns 2]].", {"actor": w, "sourceCard": "Test"})
	var after: Dictionary = bo.odds(w, pv, g)
	ck("0.23 Aim: +4 Aim, and the Warden's ranged odds rise by 4 in 20 (13 in 20 to hit becomes 17), exactly as the rules roll them",
		absf(after["p"] / before["p"] - 17.0 / 13.0) < 1e-9 and _exact(bo, w, pv, g), [before, after])
	bo.fx.run_text("[[this Unit]] gains [[Hardened 2]] for [[turns 2]].", {"actor": g, "sourceCard": "Test"})
	var hp1: int = g["hp"]
	Rules.hit(g, 5)
	var a5: int = hp1 - g["hp"]
	hp1 = g["hp"]
	Rules.hit(g, 2)
	var a2: int = hp1 - g["hp"]
	ck("0.23 Hardened 2: a hit of 5 deals 3, and one of 2 still deals 1", a5 == 3 and a2 == 1, [a5, a2])
	ck("0.23 Hardened: the odds show what it would take, as the rules roll it", bo.odds(w, pv, g)["dmg"] == maxi(1, before["dmg"] - 2) and _exact(bo, w, pv, g), bo.odds(w, pv, g))
	hp1 = g["hp"]
	Rules.add_status(g, "Poisoned", 3, "Test", 2)
	Rules.tick_statuses(bo.units, false)
	ck("0.23 Hardened: a Poisoned tick is a hit too: 3 less 2", hp1 - g["hp"] == 1, hp1 - g["hp"])
	_sure(pv, g)
	g["hp"] = 30
	var res := bo.attack(w, pv, g)
	ck("0.23 Hardened: an attack's damage is cut once, not twice", Rules.truthy(res.get("damage")) and 30 - g["hp"] >= int(res["damage"]) and int(res["damage"]) == maxi(1, int(Rules.num(pv.get("dmg"), 0)) - 2) , [res.get("damage"), 30 - g["hp"]])
	# Draw and gain Aether
	var bc := Battle.from_state(fl, [_mk(r, "Test Warden", "ally", "h1", Vector2i(0, 0)), _mk(r, "Test Grunt", "enemy", "e1", Vector2i(3, 0))], 3, r.cards)
	bc._hook()
	bc.with_cards = true
	bc.deck = [Roster.hand_card(r.card_named("Test Stim")), Roster.hand_card(r.card_named("Test Smoke")), Roster.hand_card(r.card_named("Test Stim"))]
	bc.hand = []
	var hw = bc.unit_by_id("h1")
	bc.fx.run_text("[[Draw 2]].", {"actor": hw, "sourceCard": "Test Warden"})
	ck("0.23 Draw: two cards go from the Deck to the hand, and the Log says so", bc.hand.size() == 2 and bc.deck.size() == 1 and _texts(bc).has("Test Warden: drew 2 cards"), _texts(bc))
	bc.fx.run_text("[[gain Aether 1]].", {"actor": hw, "sourceCard": "Test Warden"})
	ck("0.23 gain Aether: 1 of the card's District (3) goes into the Bank", int(bc.aether.get("d3", 0)) == 1, bc.aether)
	var eg = bc.unit_by_id("e1")
	bc.fx.run_text("[[Draw 2]].", {"actor": eg, "sourceCard": "Test Grunt"})
	bc.fx.run_text("[[gain Aether 3]].", {"actor": eg, "sourceCard": "Test Grunt"})
	ck("0.23 Draw and gain Aether do nothing on an Enemy's card", bc.hand.size() == 2 and int(bc.aether.get("d3", 0)) == 1 and _texts(bc).has("An Enemy has no cards to draw"))
	var lc = r.card_named("Ledger Chip")
	var syn := {"cardType": "sphere", "aetherValue": 1, "entries": [{"kind": "Passive", "text": "[[gain Aether 1]]."}]}
	ck("0.23 chips: a Chip whose Passive gains Aether 1 gives 1 more (a value-1 Chip: 2; the Ledger Chip, Level 1 and Rare, 2 and 1: 3)", Rules.chip_value(syn) == 2 and lc != null and Rules.chip_value(lc) == 3, [Rules.chip_value(syn), Rules.chip_value(lc) if lc != null else null])
	# Barricade
	var orig := _open_floor()
	var bb := Battle.from_state(orig, [_mk(r, "Test Striker", "ally", "a1", Vector2i(-3, 0)), _mk(r, "Test Grunt", "enemy", "e1", Vector2i(3, 0))], 3, r.cards)
	bb._hook()
	var sa = bb.unit_by_id("a1")
	var ge = bb.unit_by_id("e1")
	var cov0 := bb.cover_for(ge, sa)
	var rev0 := bb.floor_rev
	bb.fx.run_text("[[Barricade Full]] on [[target tile]].", {"actor": sa, "tile": {"q": 2, "r": 0}, "sourceCard": "Test"})
	ck("0.23 Barricade: a Full Cover Barricade goes on the empty tile, and the Enemy behind it has Full Cover (4) against the shot",
		bb.kind_at(Vector2i(2, 0)) == "cover-full" and cov0 == 0 and bb.cover_for(ge, sa) == 4 and bb.floor_rev > rev0, [bb.kind_at(Vector2i(2, 0)), bb.cover_for(ge, sa)])
	ck("0.23 Barricade: the floor itself is left as it was: the fight changed a copy", orig.colour_of(Vector2i(2, 0)) == -1 and bb.floor_data != orig)
	var m0 := bb.log.size()
	bb.fx.run_text("[[Barricade Half]] on [[target tile]].", {"actor": sa, "tile": {"q": 3, "r": 0}, "sourceCard": "Test"})
	ck("0.23 Barricade: a tile with a Unit on it takes none, and the Log says why", bb.kind_at(Vector2i(3, 0)) == "" and _texts(bb, m0).has("A Barricade needs an empty tile, and that one is not"), _texts(bb, m0))
	bb.undo.append(bb._snapshot({"kind": "card", "label": "Test"}))
	bb.fx.run_text("[[Barricade Half]] on [[target tile]].", {"actor": sa, "tile": {"q": 0, "r": 2}, "sourceCard": "Test"})
	var put := bb.kind_at(Vector2i(0, 2))
	bb.undo_last()
	ck("0.23 Barricade: Undo takes one back", put == "cover-half" and bb.kind_at(Vector2i(0, 2)) == "" and bb.kind_at(Vector2i(2, 0)) == "cover-full", put)
	# Line and Cone
	var ls := _mk(r, "Test Striker", "ally", "a1", Vector2i(0, 0))
	var foes := [[1, 0], [2, 0], [3, 0], [2, -2], [-1, 0]].map(func(c): return _mk(r, "Test Grunt", "enemy", "e%d" % (c[0] * 10 + c[1] + 50), Vector2i(c[0], c[1])))
	var bl := Battle.from_state(fl, [ls] + foes, 3, r.cards)
	bl._hook()
	var hp2: Array = foes.map(func(f): return f["hp"])
	bl.fx.run_text("[[target enemy]] takes [[damage 4]] with [[Line 3]].", {"actor": ls, "target": foes[0], "sourceCard": "Test"})
	var line_d: Array = []
	for i in foes.size():
		line_d.append(hp2[i] - foes[i]["hp"])
		foes[i]["hp"] = hp2[i]
	bl.fx.run_text("[[target enemy]] takes [[damage 4]] with [[Cone 2]].", {"actor": ls, "target": foes[0], "sourceCard": "Test"})
	var cone_d: Array = []
	for i in foes.size():
		cone_d.append(hp2[i] - foes[i]["hp"])
	ck("0.23 Line: Line 3 from the Striker through its target hits the two behind it in the row, not those off the line or behind the Striker", line_d == [4, 4, 4, 0, 0], line_d)
	ck("0.23 Cone: Cone 2 hits the wedge 2 tiles deep toward the target, not the Enemy behind the Striker", cone_d[0] == 4 and cone_d[1] == 4 and cone_d[2] == 0 and cone_d[4] == 0, cone_d)
	var pvw: Dictionary = bl.fx.area_preview(ls, {"name": "Shot", "text": "[[Line 3]]."}, foes[0])
	ck("0.23 Line: aimed, its preview lights the 3 tiles and rings the two it would also take in", pvw["tiles"] == [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)] and pvw["caught"].size() == 2, pvw)
	# Actions aimed at a tile: Test Bulwark's Raise Wall
	var bw := _mk(r, "Test Bulwark", "ally", "b1", Vector2i(0, 0))
	var wd := _mk(r, "Test Warden", "ally", "h1", Vector2i(0, 2))
	var gg := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(3, 0))
	var bt := Battle.from_state(_open_floor(), [bw, wd, gg], 3, r.cards)
	bt.deploy_start()
	var rw := _act(bw, "Raise Wall")
	var reach := bt.tile_reach(bw, rw)
	ck("0.23 tile Actions: Raise Wall is aimed at a tile: it has no Unit targets, can be used, and reaches the tiles within 3 it can see, its own included, none further",
		Battle.tile_action(rw) and not Battle.tile_action(_act(bw, "Breach Shot")) and bt.targets_for(bw, rw).is_empty() and bt.action_state(bw, rw)["ok"]
		and reach.has(Vector2i(0, 0)) and reach.has(Vector2i(-3, 0)) and not reach.keys().any(func(k): return Hex.distance(k, Vector2i.ZERO) > 3), reach.size())
	var n0 := int(bw["nrg"])
	var m1 := bt.log.size()
	var line := bt.use_on_tile(bw, rw, Vector2i(-1, 1))
	ck("0.23 tile Actions: used on an empty tile, it pays its Energy and puts a Full Cover Barricade there; the Log says so",
		bt.kind_at(Vector2i(-1, 1)) == "cover-full" and int(bw["nrg"]) == n0 - int(Rules.num(rw.get("cost"), 0)) and Rules.truthy(bw.get("acted")) and line == "Test Bulwark used Raise Wall at -1,1"
		and _texts(bt, m1).has("Raise Wall puts a Full Cover Barricade on -1,1"), _texts(bt, m1))
	bw["side"] = "enemy"
	var pick := bt.enemy_action(bw, wd)
	bw["side"] = "ally"
	ck("0.23 tile Actions: Auto never aims one", pick.get("action") == null or pick["action"].get("name") != "Raise Wall" or not pick.get("inReach", false), pick.get("action", {}).get("name") if pick.get("action") != null else null)
	# the cards, the chip and the icon
	ck("0.23: the export carries the Test Bulwark, the Test Muster and the Test Shockwave, and the Bastion Chip (no Hardened Chip)",
		["Test Bulwark", "Test Muster", "Test Shockwave", "Bastion Chip"].all(func(n): return r.card_named(n) != null) and r.card_named("Hardened Chip") == null)
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/art.json"))
	ck("0.23 art: Hardened has its icon and its board mark, and the Bastion Chip its picture", m["icons"].has("hardened") and m["marks"].has("hardened")
		and m["cardart"].values().any(func(e): return e["name"] == "Bastion Chip") and Art.status_icon("Hardened") != null and Art.status_mark("Hardened") != null)


func _twentythree_scene() -> void:
	Kit.fresh()
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_export(FIXTURE)
	await _frames(2)
	var r: Roster = scene.roster
	var bw := _mk(r, "Test Bulwark", "ally", "a1", Vector2i(0, 0))
	bw["src"] = "Test Bulwark"
	var g1 := _mk(r, "Test Grunt", "enemy", "e1", Vector2i(1, 0))
	g1["src"] = "Test Grunt"
	var g2 := _mk(r, "Test Grunt", "enemy", "e2", Vector2i(2, 0))
	g2["src"] = "Test Grunt"
	var b := _stage(scene, _open_floor(), [bw, g1, g2])
	scene._fit()
	await process_frame
	_tap(scene, Vector2i(0, 0))
	await process_frame
	var ri := _index(bw, "Raise Wall")
	scene.pick_action(ri)
	await process_frame
	ck("0.23 screen: picking Raise Wall lights the tiles it can go to, and no Unit", scene.aiming == ri and not scene.tile_aim.is_empty() and scene.board.aim_tiles.size() == scene.tile_aim.size() and scene.targets.is_empty(), scene.tile_aim.size())
	_tap(scene, Vector2i(-1, 1))
	await process_frame
	ck("0.23 screen: a first tap shows where (the tile lit), and nothing is put down yet", scene.tile_at == Vector2i(-1, 1) and scene.board.blast.has(Vector2i(-1, 1)) and b.kind_at(Vector2i(-1, 1)) == "")
	_tap(scene, Vector2i(-1, 1))
	await _frames(2)
	ck("0.23 screen: a second tap uses it: the Barricade stands on the board", b.kind_at(Vector2i(-1, 1)) == "cover-full" and scene.board.props.has(Vector2i(-1, 1)) and scene.aiming == -1 and scene.board.aim_tiles.is_empty(), [b.kind_at(Vector2i(-1, 1)), scene.board.props.keys()])
	# a Line, aimed: the tiles it runs through are lit before it fires
	bw["acted"] = false
	bw["nrg"] = 3
	_tap(scene, Vector2i(0, 0))
	await process_frame
	var bi := _index(bw, "Breach Shot")
	scene.pick_action(bi)
	await process_frame
	_tap(scene, Vector2i(1, 0))
	await process_frame
	ck("0.23 screen: aimed at the first Grunt, Breach Shot (Line 3) lights its line and rings the Grunt behind", scene.preview == "e1" and scene.board.blast.has(Vector2i(2, 0)) and scene.board.blast.has(Vector2i(3, 0)) and scene.board.view_of("e2").caught, scene.board.blast.keys())
	scene.queue_free()
	await _frames(2)
	Kit.fresh()
