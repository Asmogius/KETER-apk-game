## Where the game spends its time: a timing run, for the performance work (0.44).
##   godot --headless --path . --script res://tests/perf.gd -- [export=<zip>] [out=<json>] [only=<part,...>]
## Headless, a frame is the CPU's work alone (scripts, layout, the draw calls
## recorded; no GPU), so its time is what the scripts cost a phone. Parts:
## boot (the scene and the export read), home, dock (each tab), teams (the
## editor's tabs), cards (a grid of card tiles), map (a deployment's World
## Map), battle (a fight's frames, an Enemy turn played through, and the
## rules' own cost of one), ai (the rules alone: Enemy turns, many).
extends SceneTree

const Kit := preload("res://tests/team_kit.gd")
const FIXTURE := "res://tests/fixtures/export.zip"

var results := {}
var opts := {"export": FIXTURE, "out": "", "only": ""}


class Frames extends Node:
	var last := 0
	var times: Array = []
	var on := false

	func _init() -> void:
		process_priority = -1000
		process_mode = Node.PROCESS_MODE_ALWAYS

	func start() -> void:
		times = []
		last = Time.get_ticks_usec()
		on = true

	func stop() -> Array:
		on = false
		return times

	func _process(_d: float) -> void:
		var now := Time.get_ticks_usec()
		if on:
			times.append((now - last) / 1000.0)
		last = now


var frames: Frames


func _initialize() -> void:
	_run.call_deferred()


func _want(part: String) -> bool:
	return opts["only"] == "" or (opts["only"] as String).split(",").has(part)


func ms(us: int) -> float:
	return us / 1000.0


func note(name: String, v) -> void:
	results[name] = v
	if v is Dictionary:
		print("%-58s avg %7.2f  p95 %7.2f  max %7.2f ms  (%d frames)" % [name, v["avg"], v["p95"], v["max"], v["n"]])
	else:
		print("%-58s %9.1f ms" % [name, v])


static func stats(t: Array) -> Dictionary:
	if t.is_empty():
		return {"avg": 0.0, "p95": 0.0, "max": 0.0, "n": 0}
	var s := t.duplicate()
	s.sort()
	var sum := 0.0
	for x in s:
		sum += x
	return {"avg": sum / s.size(), "p95": s[mini(s.size() - 1, int(s.size() * 0.95))], "max": s[-1], "n": s.size()}


## The frames while n of them pass.
func idle(n: int) -> Dictionary:
	frames.start()
	for i in n:
		await process_frame
	return stats(frames.stop())


## How long a call takes, and the frame after it (where layout and drawing land).
func timed(name: String, fn: Callable) -> void:
	var s := Time.get_ticks_usec()
	await fn.call()
	var mid := Time.get_ticks_usec()
	await process_frame
	await process_frame
	note(name, ms(Time.get_ticks_usec() - s))
	results[name + " (call)"] = ms(mid - s)
	print("%-58s %9.1f ms of it in the call" % ["", ms(mid - s)])


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		if kv.size() == 2:
			opts[kv[0]] = kv[1]
	# no sleep between frames (headless sleeps ~6.9 ms a frame): a frame's time is its work
	OS.low_processor_usage_mode_sleep_usec = 0
	frames = Frames.new()
	root.add_child(frames)
	Kit.fresh()
	Motion.still = false                 # things move, as on the phone
	Motion.speed = "normal"
	Kit.keep([Kit.field_team(), Kit.team("Test Vanguard 2")])
	# ---- boot
	var s := Time.get_ticks_usec()
	var packed: PackedScene = load("res://scenes/main.tscn")
	var scene: Node2D = packed.instantiate()
	note("boot: main.tscn loaded and made", ms(Time.get_ticks_usec() - s))
	s = Time.get_ticks_usec()
	root.add_child(scene)
	await process_frame
	note("boot: in the tree, its first frame", ms(Time.get_ticks_usec() - s))
	var x := KeterExport.new()
	s = Time.get_ticks_usec()
	x.open(opts["export"])
	note("boot: the export opened (KeterExport.open)", ms(Time.get_ticks_usec() - s))
	s = Time.get_ticks_usec()
	var every := x.floors()
	note("boot: its floors read (%d)" % every.size(), ms(Time.get_ticks_usec() - s))
	s = Time.get_ticks_usec()
	var r := Roster.new(x)
	note("boot: the roster made (%d cards)" % r.cards.size(), ms(Time.get_ticks_usec() - s))
	s = Time.get_ticks_usec()
	var _c := Campaign.new(x, r, every)
	note("boot: the campaign read", ms(Time.get_ticks_usec() - s))
	s = Time.get_ticks_usec()
	Art.load_from(x)
	note("boot: Art read from it", ms(Time.get_ticks_usec() - s))
	s = Time.get_ticks_usec()
	scene.load_export(opts["export"])
	note("boot: load_export, all of it", ms(Time.get_ticks_usec() - s))
	await process_frame
	await process_frame
	if _want("home"):
		note("home: idle frames", await idle(120))
	# ---- the dock
	if _want("dock") and scene.campaign != null:
		var dk: DockScreen = scene.dock_screen
		await timed("dock: open", func(): scene.open_dock())
		var b := Loot.bag()
		b["shards"] = 3000
		for ty in ["troop", "equipment", "aether"]:
			b["parts"][ty] = [20, 12, 6, 3, 1, 0]
		scene.campaign.deploy.stock = b
		for d in ["1", "2", "3", "4", "5", "6"]:
			scene.campaign.progress.see("district", d)
		scene.campaign.dock.restock()
		for tab in ["stockpile", "exchange", "recruit", "craft", "reclaim", "bounties", "upgrades"]:
			await timed("dock: tab %s" % tab, func(): dk.show_tab(tab))
		note("dock: idle frames on Craft", await idle(60))
		for i in 2:
			var c0 := Time.get_ticks_usec()
			dk.list.clear()
			var c1 := Time.get_ticks_usec()
			dk._rows = []
			dk._list_of = []
			dk._read = []
			dk._craft_rows()
			var c2 := Time.get_ticks_usec()
			dk.list.settle()
			var c3 := Time.get_ticks_usec()
			note("dock: Craft, its list cleared", ms(c1 - c0))
			note("dock: Craft, its rows made", ms(c2 - c1))
			note("dock: Craft, its list settled", ms(c3 - c2))
			var lim: Array = scene.roster.from_export.filter(func(c): return Dock.is_limited(c)).slice(0, 60)
			var ents := lim.map(func(c): return {"card": c, "count": 1, "sub": "Rare · held 1\n+2 Equipment parts", "price": "70", "chips": [["Craft", ["craft", c["name"]], UI.GOLD]]})
			var c4 := Time.get_ticks_usec()
			dk._cards(ents)
			note("dock: _cards alone, 60 cards", ms(Time.get_ticks_usec() - c4))
			var ents2 := lim.map(func(c): return {"card": c, "art": null})
			c4 = Time.get_ticks_usec()
			dk._cards(ents2)
			note("dock: _cards alone, 60 bare cards (no art lookup, no sub, no chips)", ms(Time.get_ticks_usec() - c4))
			var acc := {"col": 0, "tile": 0, "sub": 0, "bottom": 0, "price": 0, "chip": 0, "art": 0}
			var hold := HFlowContainer.new()
			for c in lim:
				var q := Time.get_ticks_usec()
				var art = scene.roster.art_for(c)
				acc["art"] += Time.get_ticks_usec() - q
				q = Time.get_ticks_usec()
				var col := VBoxContainer.new()
				col.custom_minimum_size = Vector2(176, 0)
				hold.add_child(col)
				acc["col"] += Time.get_ticks_usec() - q
				q = Time.get_ticks_usec()
				var tile := CardTile.new(c, art)
				col.add_child(tile)
				acc["tile"] += Time.get_ticks_usec() - q
				q = Time.get_ticks_usec()
				var sl := UI.label("Rare · held 1\n+2 Equipment parts", 14, UI.DIM, true)
				sl.custom_minimum_size = Vector2(176, 0)
				sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				col.add_child(sl)
				acc["sub"] += Time.get_ticks_usec() - q
				q = Time.get_ticks_usec()
				var bottom := HFlowContainer.new()
				bottom.custom_minimum_size = Vector2(176, 0)
				col.add_child(bottom)
				acc["bottom"] += Time.get_ticks_usec() - q
				q = Time.get_ticks_usec()
				bottom.add_child(dk._price_tag("70"))
				acc["price"] += Time.get_ticks_usec() - q
				q = Time.get_ticks_usec()
				bottom.add_child(UI.chip("Craft", UI.GOLD, ["craft", "x"], false, 15))
				acc["chip"] += Time.get_ticks_usec() - q
			for k in acc:
				note("dock: a card entry's %s, 60 of them" % k, ms(acc[k]))
			var q2 := Time.get_ticks_usec()
			dk.list.add_row(hold)
			note("dock: the 60 entries put in the list (into the tree)", ms(Time.get_ticks_usec() - q2))
			q2 = Time.get_ticks_usec()
			dk.list.box.get_combined_minimum_size()
			note("dock: and the list's size worked out", ms(Time.get_ticks_usec() - q2))
			await process_frame
			await process_frame
		dk.show_tab("craft")
		await process_frame
		frames.start()
		for i in 30:
			dk.list.scroll_by(40.0)
			await process_frame
		note("dock: scrolling Craft", stats(frames.stop()))
		await timed("dock: Craft bought (the tab built again)", func(): dk.act(["craft", str(dk._rows.filter(func(e): return e.get("card") is Dictionary)[0]["card"]["name"])]))
		await timed("dock: Deploy list, a team chosen", func():
			dk.show_teams()
			dk.choose_team(0))
	# ---- the Exchange's parts, alone
	if _want("exchange") and scene.campaign != null:
		var dkk: Dock = scene.campaign.dock
		var ws: Workshop = scene.campaign.workshop
		var st := dkk.stock()
		var parts := {
			"dock.stock()": func(): dkk.stock(),
			"dock.see_stock()": func(): dkk.see_stock(),
			"dock.prebuilts()": func(): dkk.prebuilts(),
			"workshop.get_design (pre)": func():
				for id in st["pre"]:
					ws.get_design(id),
			"workshop.to_card (pre)": func():
				for id in st["pre"]:
					ws.to_card(ws.get_design(id)),
			"workshop.power (pre)": func():
				for id in st["pre"]:
					ws.power(ws.get_design(id)),
			"dock.pre_cost (pre)": func():
				for id in st["pre"]:
					dkk.pre_cost(ws.get_design(id)),
			"progress.item_name (bps+chs)": func():
				for it in st["bps"] + st["chs"]:
					scene.campaign.progress.item_name(it, true),
			"progress.eligible (bps+chs)": func():
				for it in st["bps"] + st["chs"]:
					scene.campaign.progress.eligible(it),
			"dock.bp_price (bps+chs)": func():
				for it in st["bps"] + st["chs"]:
					dkk.bp_price(it),
			"dock.item_price (items)": func():
				for nm in st["items"]:
					dkk.item_price(nm),
			"dock.craft_cost (every card) x1": func():
				for c in scene.roster.from_export:
					dkk.craft_cost(str(c["name"])),
			"dock.card_of (every card) x1": func():
				for c in scene.roster.from_export:
					dkk.card_of(str(c["name"])),
			"roster.art_for (every card) x1": func():
				for c in scene.roster.from_export:
					scene.roster.art_for(c),
			"dock.card_of (items)": func():
				for nm in st["items"]:
					dkk.card_of(nm),
		}
		print("  (the Exchange: %d items, %d pre-built, %d blueprints and chassis)" % [st["items"].size(), st["pre"].size(), (st["bps"] + st["chs"]).size()])
		for nm in parts:
			var t0 := Time.get_ticks_usec()
			parts[nm].call()
			note("exchange: " + nm, ms(Time.get_ticks_usec() - t0))
	# ---- the Strike Teams and the editor
	if _want("teams"):
		await timed("teams: open", func(): scene.open_teams())
		var ts: TeamsScreen = scene.teams_screen
		await timed("teams: the editor open", func(): ts.edit(0))
		for tab in ["heroes", "deck", "carried", "pouch", "protos", "consumables", "checks"]:
			await timed("teams: tab %s" % tab, func(): ts.editor.open_tab(tab))
		ts.editor.open_tab("deck")
		await process_frame
		frames.start()
		for i in 30:
			ts.editor.grid.scroll_by(40.0)
			await process_frame
		note("teams: scrolling the Deck", stats(frames.stop()))
		ts.editor.open_tab("deck")
		var first: int = ts.editor._shown.find(ts.editor._shown.filter(func(w): return w.has("card"))[0])
		await timed("teams: a card read", func(): ts.editor.tap_card(first))
		var sh: CardSheet = ts.editor.sheet
		if sh != null and sh.plus_btn != null:
			await timed("teams: a copy added (the grid built again)", func(): sh.step(1))
		ts.editor._close_sheet()
		ts.editor.closed.emit()
		await process_frame
	# ---- a grid of cards on its own
	if _want("cards"):
		var g := CardGrid.new()
		g.size = Vector2(1240, 640)
		g.position = Vector2(20, 40)
		var top := CanvasLayer.new()
		top.layer = 50
		root.add_child(top)
		top.add_child(g)
		var items := []
		for c in scene.roster.cards:
			items.append({"card": c, "art": scene.roster.art_for(c)})
		await timed("cards: a grid of every card (%d)" % items.size(), func(): g.set_items(items))
		await timed("cards: the same again", func(): g.set_items(items))
		var t0 := Time.get_ticks_usec()
		for i in 200:
			CardTile.foot_for(items[i % items.size()]["card"])
		note("cards: CardTile.foot_for x200", ms(Time.get_ticks_usec() - t0))
		t0 = Time.get_ticks_usec()
		for i in 200:
			CardFace.rules_words(items[i % items.size()]["card"])
		note("cards: CardFace.rules_words x200", ms(Time.get_ticks_usec() - t0))
		t0 = Time.get_ticks_usec()
		for i in 200:
			scene.roster.art_for(items[i % items.size()]["card"])
		note("cards: roster.art_for x200", ms(Time.get_ticks_usec() - t0))
		t0 = Time.get_ticks_usec()
		for i in 200:
			CardSheet.describe(items[i % items.size()]["card"])
		note("cards: CardSheet.describe x200", ms(Time.get_ticks_usec() - t0))
		var made := []
		t0 = Time.get_ticks_usec()
		for i in 100:
			made.append(UI.chip("Craft", UI.GOLD, ["craft", "x"], false, 15))
		note("cards: UI.chip x100", ms(Time.get_ticks_usec() - t0))
		t0 = Time.get_ticks_usec()
		for i in 100:
			made.append(UI.label("Uncommon · held 0", 14, UI.DIM, true))
		note("cards: UI.label x100", ms(Time.get_ticks_usec() - t0))
		t0 = Time.get_ticks_usec()
		for i in 100:
			var pc := PanelContainer.new()
			pc.add_theme_stylebox_override("panel", UI.box(Color("#271f1b"), UI.GOLD, 1, 2, 6))
			made.append(pc)
		note("cards: a panel with UI.box x100", ms(Time.get_ticks_usec() - t0))
		t0 = Time.get_ticks_usec()
		for i in 100:
			made.append(UI.icon("shards", 32))
		note("cards: UI.icon x100", ms(Time.get_ticks_usec() - t0))
		t0 = Time.get_ticks_usec()
		for i in 100:
			made.append(CardTile.new(items[i]["card"], items[i]["art"]))
		note("cards: CardTile.new x100", ms(Time.get_ticks_usec() - t0))
		for m in made:
			m.free()
		t0 = Time.get_ticks_usec()
		for i in 20:
			Look.fight_theme()
		note("cards: Look.fight_theme() x20", ms(Time.get_ticks_usec() - t0))
		t0 = Time.get_ticks_usec()
		for i in 10:
			var dd := Dialog.new("A box", "Some words in it.", ["Close", "Words"])
			dd.free()
		note("cards: Dialog.new x10", ms(Time.get_ticks_usec() - t0))
		t0 = Time.get_ticks_usec()
		for i in 10:
			var cs := CardSheet.new(items[i]["card"], items[i]["art"], {"buttons": [["a", "Add"]]})
			cs.free()
		note("cards: CardSheet.new x10", ms(Time.get_ticks_usec() - t0))
		top.queue_free()
		await process_frame
	# ---- the World Map's lookups, alone
	if _want("world") and scene.campaign != null:
		var w: World = scene.campaign.world
		var keys: Array = w.map["tiles"].keys()
		note("world: tiles on the map (count)", float(keys.size()))
		var fns := {"tile": func(k): return w.tile(k), "skull_of": func(k): return w.skull_of(k), "district_of": func(k): return w.district_of(k),
			"known": func(k): return w.known(k), "content_at": func(k): return w.content_at(k), "is_cleared": func(k): return w.is_cleared(k),
			"core_at": func(k): return w.core_at(k), "World.key+parse": func(k): return World.key(World.parse(k).x, World.parse(k).y)}
		for nm in fns:
			var t0 := Time.get_ticks_usec()
			for k in keys:
				fns[nm].call(k)
			note("world: %s over every tile" % nm, ms(Time.get_ticks_usec() - t0))
	# ---- the World Map, a team out
	if _want("map") and scene.campaign != null:
		var dk2: DockScreen = scene.dock_screen
		scene.open_dock()
		await process_frame
		dk2.show_teams()
		dk2.choose_team(0)
		await timed("map: the team leaves, the map shown", func(): dk2.leave())
		for i in 10:
			await process_frame
		note("map: idle frames", await idle(120))
		var ms_: MapScreen = scene.map_screen
		frames.start()
		for i in 60:
			scene.camera.zoom = Vector2.ONE * (0.6 + 0.01 * i)
			await process_frame
		note("map: zooming (drawn again each step)", stats(frames.stop()))
		frames.start()
		for i in 60:
			scene.map_view.refresh()
			await process_frame
		note("map: drawn again every frame", stats(frames.stop()))
		var wk: World = scene.campaign.world
		var spare := ""
		for k in wk.map["tiles"]:
			if not wk.known(k):
				spare = str(k)
				break
		frames.start()
		for i in 60:
			if i % 2 == 0:
				wk.state["known"][spare] = 1
			else:
				wk.state["known"].erase(spare)
			scene.map_view.refresh()
			await process_frame
		note("map: what is known changes every frame (the ground drawn again)", stats(frames.stop()))
		var cur = scene.campaign.deploy.cur()
		var near := ""
		for k in scene.campaign.world.map["tiles"]:
			if Hex.distance(World.parse(k), World.parse(cur["pos"])) == 1:
				near = str(k)
				break
		if near != "":
			await timed("map: a tile tapped", func(): ms_.tap(near))
	# ---- a fight
	if _want("battle"):
		scene.open_setup("team")
		var su: SetupScreen = scene.setup
		su.choose_floor(0)
		su._go(1)
		su.choose_team(0)
		su._go(1)
		su._go(1)
		var t1 := Time.get_ticks_usec()
		scene.start_team_battle(0, su.team(), StrikeTeams.setup_for(su.team(), scene.roster, su.heroes, su.leader, [], 3, 0), 7)
		var mid := Time.get_ticks_usec()
		await process_frame
		await process_frame
		note("battle: started (setup to its second frame)", ms(Time.get_ticks_usec() - t1))
		results["battle: start_team_battle (call)"] = ms(mid - t1)
		for i in 30:
			await process_frame
		note("battle: idle frames (atmosphere %s)" % Motion.atmos, await idle(180))
		var was_atmos: String = Motion.atmos
		Motion.atmos = "off"
		note("battle: idle frames, atmosphere off", await idle(120))
		Motion.atmos = was_atmos
		var u = scene.battle.side_units("ally").filter(func(x): return not Rules.truthy(x.get("down")))[0]
		await timed("battle: a Unit selected", func(): scene.select(u))
		await timed("battle: deselected", func(): scene.deselect())
		await timed("battle: the hand opened", func(): scene.toggle_hand())
		scene._close_tray()
		# an Enemy turn, played through on the screen
		scene.fast = false
		frames.start()
		var t2 := Time.get_ticks_usec()
		await scene.end_turn()
		var took := ms(Time.get_ticks_usec() - t2)
		var ft := stats(frames.stop())
		note("battle: the Enemies' turn, played (wall time)", took)
		note("battle: frames during the Enemies' turn", ft)
		results["battle: frames over 33 ms during the Enemies' turn"] = frames.times.filter(func(v): return v > 33.0).size()
		print("  frames over 33 ms: %d" % results["battle: frames over 33 ms during the Enemies' turn"])
	# ---- the rules alone
	if _want("ai"):
		var fl: FloorData = scene.floors[0]
		var total := 0
		var turns := 0
		var worst := 0
		var rounds_t := 0
		for sd in 6:
			var b2 := Battle.begin_team(fl, scene.roster, StrikeTeams.setup_for(Kit.team(), scene.roster, ["Test Warden", "Test Striker"], "Test Warden", [], 3, 0), 100 + sd)
			for rd in 4:
				if b2.over:
					break
				var tr := Time.get_ticks_usec()
				b2.end_player_turn()
				for id in b2.enemy_queue():
					var e = b2.unit_by_id(id)
					if e == null or Rules.truthy(e.get("down")):
						continue
					var te := Time.get_ticks_usec()
					b2.enemy_turn(e)
					var d := Time.get_ticks_usec() - te
					total += d
					worst = maxi(worst, d)
					turns += 1
					if b2.settle():
						break
				if not b2.over:
					b2.end_enemy_phase()
					if not b2.settle():
						b2.begin_round()
						for k in b2.upkeep():
							b2.run_phase(k)
						b2.begin_turn()
						b2.settle()
				rounds_t += Time.get_ticks_usec() - tr
		note("ai: an Enemy's turn decided, on average (%d turns)" % turns, ms(total) / maxi(1, turns))
		note("ai: the slowest Enemy turn", ms(worst))
		note("ai: a whole Enemy phase, on average", ms(rounds_t) / 24.0)
	if opts["out"] != "":
		var f := FileAccess.open(opts["out"], FileAccess.WRITE)
		f.store_string(JSON.stringify(results, "  "))
		f.close()
	Kit.fresh()
	scene.queue_free()
	await process_frame
	quit(0)
