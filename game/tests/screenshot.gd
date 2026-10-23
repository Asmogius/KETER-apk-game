## Renders a screen from the test export and saves a PNG:
##   godot --path . --script res://tests/screenshot.gd -- <out.png> [key=value ...]
##     screen=home|teams|editor|battle|dock|deploy|map    which screen (default battle)
##     map=<op>;<op>                      on the World Map (screen=map), with the test team
##                                        sent out: tap a tile (sel:<q,r>), walk to one
##                                        (walk:<q,r>), press one of the panel's buttons
##                                        (do:<id> or do:<id>:<arg>: walk, enter, cache,
##                                        choose, home, fight), put the team on a tile
##                                        (put:<q,r>), show every tile's contents (known),
##                                        Fit (fit), zoom (zoom:<n>), the Team or Log box
##                                        (team, log), begin the waiting fight's setup
##                                        (fight), go on a step in it (next), start it
##                                        (start), end it (win, lose), press a button of
##                                        the box that is up (ok:<n>), go to the dock
##                                        (dock), wait (wait:<frames>)
##     tab=heroes|deck|carried|pouch|protos|checks   the builder's tab (screen=editor)
##     card=<name>                        a card opened to read, in the builder
##     deckonly=1                         the builder's See Deck
##     empty=1                            the test team with nothing in it yet
##     mode=quick|team                    a Quick battle (default) or a Strike Team's
##     step=floor|team|heroes|troops|battle   how far into setting up (default battle)
##     floor=<name>                       the floor (default the first)
##     heroes=<name>;<name>               Heroes to choose (default the first that fit)
##     troops=<name>;<name>               Troops to bring (one each)
##     timer=<n>                          the wave timer (a Strike Team's battle)
##     districts=<n>                      Districts cleared, for Dimensional Instability
##     carry=<Action card>                the Action card Quillon Vex carries instead
##     taps=<q,r>;a:1;<q,r>;next          once the battle starts: tap tiles, pick an
##                                        Action (a:index), end the round (next),
##                                        open the log (log), wait (wait:frames),
##                                        end it (win, lose), start the Enemies'
##                                        turn and catch it under way (go)
##                                        wait for the dice (until), hold fire
##                                        (hold:<Action>), put a box away (ok),
##                                        break an Action's text (break:<id>:<Action>),
##                                        open the hand (hand), read a card in it
##                                        (card:<index>), open the Aether box (bank),
##                                        clear the board of Enemies (clear),
##                                        open the Consumables, Chips or Discard
##                                        tray (cons, chips, discard), tap a tile in
##                                        the open tray (read:<n>), begin playing
##                                        (play:<hand|cons|chip>:<n>), fill the Bank
##                                        (aether:<n>), put cards in the hand
##                                        (hand:<card>,<card>), give a card plain
##                                        text first (plain:<card>, 0.24),
##                                        ask to leave (leave), stop when the
##                                        round reaches a phase (phase:<its name>,
##                                        after go), switch Auto (auto), end the
##                                        turn and wait (end) or catch it under way
##                                        (endgo), open a Unit's Behaviors (beh) or
##                                        set them (beh:<key>,<key>), tap a keyword in
##                                        the open picker (bk:<key>), step the open
##                                        sheet's X (x:<n>), bring an Enemy down so
##                                        it drops its loot (kill:<id>), guard a Unit
##                                        just out of a lock (guard:<id>:<lock>, 0.13)
##     place=a1:3,0;e2:5,0                puts Units (by id) on tiles before the taps
##     stage=Test Warden@0,0;!Test Grunt@3,0   a battle made by hand instead: each card
##                                        on its tile, ! for an Enemy (ids a1.., e1..)
##     sure=1                             every attack lands (for showing what cards do)
##     seed=<n>                           deals the same Enemies each time (default 7)
##     motion=normal|fast|instant         (0.12) things move, at this speed (by default
##                                        nothing does, as the tests have it)
##     taps=...;midair:<0-1>;...            (0.12) shots and cards stop this far along
##                                        ((0.16) and the effects this far through)
##     taps=...;fx:<effect>:<tile>[:body|feet];area:<tile>:<r>   (0.16) an effect played there
##     options=1                          (0.12) Options open over Home
##     view=start                         (0.14) a staged fight seen as one opens: the usual
##                                        zoom, on your Units (by default, the whole floor)
##     after=<frames>                     frames waited after each tap (default 40):
##                                        a few, to catch a shot in the air
## Needs a display (a virtual one will do); used to check what the phone will show.
extends SceneTree

const Kit := preload("res://tests/team_kit.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "user://shot.png"
	var o := {"step": "battle", "floor": "", "heroes": "", "troops": "", "taps": "", "seed": "7", "place": "", "stage": "", "sure": "",
		"screen": "battle", "mode": "quick", "tab": "heroes", "card": "", "deckonly": "", "empty": "", "timer": "", "districts": "", "carry": "", "map": "", "ws": "", "stock": "", "pick": "0", "dock": "", "motion": "", "after": "40", "options": "", "scroll": "", "view": "", "atmos": "", "freeze": "", "turns": "", "gen": "", "genchunks": "", "whole": "", "kind": "", "forge": "", "pvp": "", "chassis": "", "poi": "", "poitab": "", "poitool": "", "studio": "", "studioview": ""}
	for a in args.slice(1):
		var kv: PackedStringArray = a.split("=", true, 1)
		if kv.size() == 2:
			o[kv[0]] = kv[1]
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	Kit.fresh()
	# (0.18) the fight's atmosphere, seen in a still: atmos=off|subtle|full (in a shot of things
	# moving, none unless asked, so the shot is the same every time)
	if o["motion"] != "":
		Motion.atmos = "off"
	if o["atmos"] != "":
		Motion.atmos = o["atmos"]
		Atmos.allow_still = true
	# (0.19) the screens' transitions only when asked for: turns=1
	Transition.enabled = o["turns"] != ""
	# (0.12) things move only when asked: motion=normal|fast|instant
	if o["motion"] != "":
		Motion.still = false
		Motion.speed = o["motion"]
	if o["screen"] != "home" or o["empty"] == "":
		var kt: Dictionary = Kit.team() if o["empty"] == "" else StrikeTeams.blank("Test Vanguard")
		if o["carry"] != "" and o["empty"] == "":
			kt["actions"] = {"Quillon Vex": [o["carry"]]}
		if o["screen"] in ["dock", "deploy", "map", "workshop"] and o["empty"] == "":
			# 0.9: a team leaves with your designs only; the old one needs a Field copy
			Kit.keep([Kit.field_team(), Kit.team("Old Vanguard")])
		else:
			Kit.keep([kt])
	scene.load_export("res://tests/fixtures/export.zip")
	# (0.20) a battlefield grown from chunks, to fight on: gen=<size>:<seed>:<skull> (the export's chunks,
	# or those in the JSON file genchunks names)
	if o["gen"] != "":
		var gp: PackedStringArray = o["gen"].split(":")
		var chunks: Array = scene.data.floors().map(func(f): return f.raw).filter(func(r): return ChunkGen.is_chunk(r)) if scene.data != null else []
		if o["genchunks"] != "":
			var gj = JSON.parse_string(FileAccess.get_file_as_string(o["genchunks"]))
			chunks = gj["chunks"] if gj is Dictionary else gj
		var glv := ChunkGen.generate(chunks, "3", int(gp[2]) if gp.size() > 2 else 2, gp[0], int(gp[1]) if gp.size() > 1 else 1)
		if not glv.is_empty():
			var gf := FloorData.from_dict(glv)
			scene.floors.append(gf)
			scene.setup.set_content(scene.roster, scene.floors)
			o["floor"] = gf.name
	if o["screen"] == "look":
		# (0.14) the Look board, scrolled by scroll=<px>
		scene.open_look_board()
		for i in 10:
			await process_frame
		if o.get("scroll", "") != "":
			scene.look_board.list.scroll_by(float(o["scroll"]))
			for i in 4:
				await process_frame
		await _shoot(out)
		return
	if o["screen"] == "home":
		if o["options"] != "":
			# (0.12) Options, open
			scene.open_options()
			for i in 30:
				await process_frame
		await _shoot(out)
		return
	if o["screen"] == "teams" or o["screen"] == "editor":
		scene.open_teams()
		if o["screen"] == "editor":
			var ts: TeamsScreen = scene.teams_screen
			ts.edit(0)
			for i in 4:
				await process_frame
			ts.editor.open_tab(o["tab"])
			if o["deckonly"] != "":
				ts.editor.set_deck_only(true)
			for i in 4:
				await process_frame
			if o["card"] != "":
				for i in ts.editor._shown.size():
					if str(ts.editor._shown[i].get("card", {}).get("name", "")) == o["card"]:
						ts.editor.tap_card(i)
		await _shoot(out)
		return
	if o["stock"] != "":
		# troop parts by rarity, then shards: "6,4,2,0,0,0:30"
		var bits: PackedStringArray = o["stock"].split(":")
		var st := Loot.bag()
		var ps: PackedStringArray = bits[0].split(",")
		for i in mini(6, ps.size()):
			st["parts"]["troop"][i] = int(ps[i])
		st["shards"] = int(bits[1]) if bits.size() > 1 else 0
		scene.campaign.deploy.stock = st
	if o["screen"] == "dock" or o["screen"] == "deploy" or o["screen"] == "map":
		await _world(scene, o)
		await _shoot(out)
		return
	if o["screen"] == "workshop":
		await _workshop(scene, o)
		await _shoot(out)
		return
	# (0.26) pass and play: screen=pvp on floor=<name>, the test teams (Player 2's led by the free Heroes);
	# pvp=cover (the hand-off screen), ready (Player 1's turn), two (Player 2's turn)
	if o["screen"] == "pvp":
		var red := Kit.team("Reds")
		var blue := Kit.team("Blues")
		blue["heroes"] = ["Dock Hand", "Field Medic", "Hangar Rifleman"]
		blue["actions"] = {}
		var fi := 0
		for i in scene.floors.size():
			if scene.floors[i].name == (o["floor"] if o["floor"] != "" else "TEST · Waves"):
				fi = i
		var cap := Roster.hero_capacity(scene.floors[fi])
		var h1: Array = StrikeTeams.heroes(red, scene.roster).map(func(c): return str(c["name"])).slice(0, cap)
		var h2: Array = StrikeTeams.heroes(blue, scene.roster).map(func(c): return str(c["name"])).slice(0, cap)
		scene.start_pvp(fi, red, StrikeTeams.setup_for(red, scene.roster, h1, h1[0], [], 0, 0), blue, StrikeTeams.setup_for(blue, scene.roster, h2, h2[0], [], 0, 0), int(o["seed"]))
		if o.get("pvp", "") != "cover":
			scene.handoff.ready_btn.pressed.emit()
		if o.get("pvp", "") == "two":
			scene.end_turn()
			for i in 4:
				await process_frame
			scene.handoff.ready_btn.pressed.emit()
		for i in 30:
			await process_frame
		await _shoot(out)
		return
	# (0.26) the Sandbox's Card Forge: screen=sandbox, kind=<type>, forge=<a card's name to open>, scroll=<px>
	if o["screen"] == "sandbox":
		scene.open_sandbox()
		var fs: ForgeScreen = scene.forge_screen
		if o.get("kind", "") != "":
			fs.type_filter = o["kind"]
			fs.show_list()
		if o.get("forge", "") != "":
			var hit = scene.roster.card_named(o["forge"])
			if hit != null:
				fs.edit(hit)
		# (0.30) studio=list, or studio=<a card's name>|art or |token; studioview=art/token/mine
		if o.get("studio", "") != "":
			scene.open_sandbox_tool("studio")
			var ss: StudioScreen = scene.studio_screen
			if o["studioview"] != "":
				ss.view = o["studioview"]
				ss.show_list()
			if o["studio"] != "list":
				var pr: PackedStringArray = o["studio"].split("|")
				var sc = scene.roster.card_named(pr[0])
				if sc != null:
					ss.edit_card(sc, pr[1] if pr.size() > 1 else "art")
					ss.act(["col", 141])
					ss.act(["tool", "pencil"])
					ss.act(["mirror", "x"])
			for i in 6:
				await process_frame
			if ss.mode == "edit":
				ss.canvas.fit()
			for i in 4:
				await process_frame
			await _shoot(out)
			return
		# (0.29) poi=<a floor's name> opens the POI Sandbox on it (poi=list: its list), poitab=<tab>, poitool=<tool>
		if o.get("poi", "") != "":
			scene.open_sandbox_tool("poi")
			var ps: PoiScreen = scene.poi_screen
			var hf = scene.data.content("floors")["floors"].filter(func(f): return f["name"] == o["poi"])
			if not hf.is_empty():
				ps.edit(hf[0])
			if o["poitab"] != "":
				ps.act(["tab", o["poitab"]])
			if o["poitool"] != "":
				ps.act(["tool", o["poitool"]])
			for i in 6:
				await process_frame
			if ps.mode == "edit":
				ps.canvas.fit()
				if o["poitool"] == "wall":
					ps.mirror = {"pivot": Vector2i.ZERO, "axis": 1}
					ps.refresh()
			for i in 4:
				await process_frame
			if o["scroll"] != "":
				(ps.form if ps.mode == "edit" else ps.list).scroll_by(float(o["scroll"]))
			await _shoot(out)
			return
		# (0.28) chassis=<id> opens the Chassis builder on it (chassis=list: its list)
		if o.get("chassis", "") != "":
			scene.open_sandbox_tool("chassis")
			var cs: ChassisScreen = scene.chassis_screen
			var hc = scene.data.content("chassis")["chassis"].filter(func(c): return c["id"] == o["chassis"])
			if not hc.is_empty():
				cs.edit(Rules.ints(hc[0]))
			for i in 6:
				await process_frame
			if o["scroll"] != "":
				cs.form.scroll_by(float(o["scroll"]))
			await _shoot(out)
			return
		for i in 6:
			await process_frame
		if o["scroll"] != "":
			fs.form.scroll_by(float(o["scroll"]))
		await _shoot(out)
		return
	scene.open_setup(o["mode"])
	var s: SetupScreen = scene.setup
	var fi := 0
	for i in scene.floors.size():
		if scene.floors[i].name == o["floor"]:
			fi = i
	s.choose_floor(fi)
	var team_mode: bool = o["mode"] == "team"
	if team_mode and o["step"] != "floor":
		s._go(1)
		s.choose_team(0)
		if o["step"] != "team":
			s._go(1)
			if o["heroes"] != "":
				for n in s.heroes.duplicate():
					s.toggle_hero(n)
				for n in o["heroes"].split(";", false):
					s.toggle_hero(n)
		if o["step"] == "troops" or o["step"] == "battle":
			s._go(1)
			for n in (o["troops"].split(";", false) if o["troops"] != "" else []):
				s.more_troop(n)
			if o["timer"] != "":
				s.set_wave_timer(int(o["timer"]))
			if o["districts"] != "":
				s.set_districts(int(o["districts"]))
	elif o["step"] != "floor":
		s._go(1)
		var want: Array = o["heroes"].split(";", false) if o["heroes"] != "" else []
		if want.is_empty():
			for c in scene.roster.heroes():
				if want.size() < Roster.hero_capacity(scene.floors[fi]) and Roster.leadership(c) > 0:
					want.append(c["name"])
		for n in want:
			s.toggle_hero(n)
	if not team_mode and (o["step"] == "troops" or o["step"] == "battle"):
		s._go(1)
		for n in (o["troops"].split(";", false) if o["troops"] != "" else []):
			s.more_troop(n)
	if o["step"] == "battle":
		var hc := s.heroes.map(func(n): return scene.roster.card_named(n))
		var tc := []
		for n in s.troop_order:
			for k in s.troops[n]:
				tc.append(scene.roster.card_named(n))
		if o["stage"] != "":
			var units := []
			var count := {"ally": 0, "enemy": 0}
			for bit in o["stage"].split(";", false):
				var foe: bool = bit.begins_with("!")
				var parts: PackedStringArray = bit.trim_prefix("!").split("@")
				var side := "enemy" if foe else "ally"
				var card = scene.roster.card_named(parts[0])
				var u := Rules.unit_from_card(Roster.unit_spec(card), side)
				count[side] += 1
				u["id"] = ("e" if foe else "a") + str(count[side])
				var same := units.filter(func(x): return x["side"] == side and str(x["name"]).begins_with(str(card["name"]))).size()
				if same > 0:
					u["name"] = str(card["name"]) + " " + str(same + 1)
				var at := Hex.parse(parts[1])
				u["pos"] = {"q": at.x, "r": at.y}
				units.append(u)
			var made := Battle.from_state(scene.floors[fi], units, int(o["seed"]), scene.roster.cards)
			made.roster = scene.roster
			for u in units:
				made.looks[u["id"]] = scene.roster.token_for(scene.roster.card_named(str(u["src"])))
			made.deploy_start()
			made.floats.clear()
			scene.show_battle(made)
			# (0.14) view=start: as a fight opens, at the usual zoom on your Units; else the whole floor
			if o["view"] == "start":
				scene._start_view()
			else:
				scene._fit()
		elif team_mode:
			var starters := []
			for n in s.troop_order:
				for k in s.troops[n]:
					starters.append(n)
			scene.start_team_battle(fi, s.team(), StrikeTeams.setup_for(s.team(), scene.roster, s.heroes, s.leader, starters, s.wave_timer, s.districts_cleared * 3), int(o["seed"]))
		else:
			scene.start_battle(fi, hc, tc, int(o["seed"]))
		if o["sure"] != "":
			for u in scene.battle.units:
				u["ac"] = 0
				u["integrity"] = 0
				for a in u["actions"]:
					if a.get("hit") != null:
						a["hit"] = 1
		for pl in (o["place"].split(";", false) if o["place"] != "" else []):
			var bits: PackedStringArray = pl.split(":")
			var u = scene.battle.unit_by_id(bits[0])
			var h := Hex.parse(bits[1])
			u["pos"] = {"q": h.x, "r": h.y}
			scene.board.view_of(bits[0]).position = Board.at(h)
		await process_frame
		for t in (o["taps"].split(";", false) if o["taps"] != "" else []):
			if t.begins_with("a:"):
				scene.pick_action(int(t.substr(2)))
			elif t == "next":
				scene.run_enemy_phase()
				while scene.enemy_phase:
					await process_frame
			elif t == "go":
				scene.run_enemy_phase()      # not waited for: the shot catches it under way
			elif t == "log":
				scene.toggle_log()
			elif t == "hand":
				scene.toggle_hand()
			elif t.begins_with("card:"):
				scene.read_hand_card(int(t.substr(5)))
			elif t == "bank":
				scene.show_bank()
			elif t == "cons" or t == "chips" or t == "discard":
				scene.toggle_tray(t)
			elif t.begins_with("read:"):
				# read:<tile> taps a tile in the open tray
				scene._on_tray_card(int(t.substr(5)))
			elif t.begins_with("play:"):
				# play:<hand|cons|chip>:<index> begins playing it, as the sheet's button does
				var pb: PackedStringArray = t.split(":")
				scene.begin_play(pb[1], int(pb[2]))
			elif t.begins_with("aether:"):
				scene.battle.aether = {"generic": int(t.substr(7)), "d3": int(t.substr(7))}
				scene._update_bar()
				continue
			elif t.begins_with("plain:"):
				# (0.24) plain:<card> gives a card plain text, as cards had before the effect box audit
				# wrote every one in keywords, for showing how plain text is marked
				var pc = scene.roster.card_named(t.substr(6))
				if pc != null:
					var pl: Array = Roster.entries_of(pc)
					if pl.is_empty():
						pl.append({"name": "", "kind": "Active", "text": "Steady your nerve and press the attack."})
					else:
						pl[0]["text"] = "Steady your nerve and press the attack."
				continue
			elif t.begins_with("hand:"):
				# hand:<card>,<card> puts these cards in the hand, for showing what each does
				scene.battle.hand = Array(t.substr(5).split(",", false)).map(func(n): return Roster.hand_card(scene.roster.card_named(n)))
				scene._update_bar()
				continue
			elif t == "leave":
				scene.ask_leave()
			elif t == "auto":
				scene.toggle_auto()
			elif t == "end":
				scene.end_turn()
				await process_frame
				while scene.busy and scene.dialog == null:
					await process_frame
			elif t == "endgo":
				scene.end_turn()             # not waited for: the shot catches Auto under way
			elif t == "beh":
				scene.open_behaviors()
			elif t.begins_with("bk:"):
				# bk:<key> taps a keyword in the open Behavior picker
				if scene.beh_sheet != null:
					scene.beh_sheet.toggle(t.substr(3))
			elif t.begins_with("beh:"):
				scene.set_behaviors(scene.selected(), Array(t.substr(4).split(",", false)).map(func(k): return {"k": k}))
			elif t.begins_with("x:"):
				if scene.sheet != null:
					scene.sheet.step(int(t.substr(2)) - scene.sheet.value)
				elif scene.xdlg != null:
					scene.xdlg.step(int(t.substr(2)) - scene.xdlg.value)
			elif t.begins_with("guard:"):
				# (0.13) a Unit just out of a lock: guard:<id>:<lock>
				var gp: PackedStringArray = str(t).substr(6).split(":")
				var gu = scene.battle.unit_by_id(gp[0])
				if not (gu.get("guards") is Dictionary):
					gu["guards"] = {}
				gu["guards"][gp[1].to_lower()] = false
				scene.board.refresh_units(scene.battle)
				if scene.selected_id == gp[0]:
					scene._show_panel(gu)
			elif t.begins_with("kill:"):
				var ku = scene.battle.unit_by_id(t.substr(5))
				var km: Array = scene._mark()
				Rules.hit(ku, 999)
				scene.battle.fx.check_downs()
				scene.board.refresh_units(scene.battle)
				scene._say(scene._tell(scene._news(km)))
				scene._update_bar()
			elif t == "clear":
				for u in scene.battle.side_units("enemy"):
					u["hp"] = 0
					u["down"] = true
				scene.board.refresh_units(scene.battle)
				continue
			elif t == "win" or t == "lose":
				for u in scene.battle.side_units("enemy" if t == "win" else "ally"):
					u["hp"] = 0
					u["down"] = true
				if t == "win":
					# nothing more to come, and what was standing drops its loot
					scene.battle.wave = scene.battle.waves_total
					scene.battle.enemy_pile.clear()
					scene.battle.fx.check_downs()
				scene.battle.settle()
				scene.board.refresh_units(scene.battle)
				scene.show_result()
			elif t.begins_with("fx:"):
				# (0.16) fx:<effect>:<tile>[:body|feet] plays one of the fight's effects there (midair: holds it)
				var fb: PackedStringArray = t.split(":")
				var off := Motion.BODY if (fb.size() > 3 and fb[3] == "body") else (Motion.FEET if (fb.size() > 3 and fb[3] == "feet") else Vector2.ZERO)
				scene.fxl.play(fb[1], Board.at(Hex.parse(fb[2])) + off)
				continue
			elif t.begins_with("area:"):
				# (0.16) area:<tile>:<radius> explodes every tile of an area there
				var ab: PackedStringArray = t.split(":")
				scene.fxl.area(Hex.parse(ab[1]), int(ab[2]))
				continue
			elif t.begins_with("midair:"):
				# (0.12) shots and cards from here on stop this far along, to be seen in the air
				Motion.freeze_at = float(t.substr(7))
				continue
			elif t.begins_with("wait:"):
				for i in int(t.substr(5)):
					await process_frame
				continue
			elif t.begins_with("phase:"):
				# the round's phases are playing: stop on the one named
				var n := 0
				while n < 4000 and not (scene.banner.visible and scene.banner_title.text == t.substr(6)):
					await process_frame
					n += 1
				for i in 12:
					await process_frame
				break
			elif t == "until":
				while scene.busy and scene.dialog == null:
					await process_frame
				continue
			elif t.begins_with("hold:"):
				scene.hold_fire(t.substr(5))
			elif t == "ok":
				if scene.dialog != null:
					scene.dialog.buttons[0].pressed.emit()
			elif t.begins_with("turn:"):
				# (0.19) a transition, as a screen changes: turn:hex or turn:pixels
				scene.transition.play(t.substr(5))
				continue
			elif t.begins_with("neon:"):
				# (0.19) the end of the fight: neon:win (every Enemy down) or neon:lose (every one of yours)
				var side := "enemy" if t.substr(5) == "win" else "ally"
				for u in scene.battle.side_units(side):
					u["hp"] = 0
					u["down"] = true
				scene.battle.settle()
				scene.show_result()
				continue
			elif t == "hand":
				scene.toggle_hand()
				continue
			elif t == "home":
				scene.leave()
				continue
			elif t.begins_with("break:"):
				var bb: PackedStringArray = t.split(":")
				for a in scene.battle.unit_by_id(bb[1])["actions"]:
					if a["name"] == bb[2]:
						a["text"] = "[[target enemy]] gains [[AC +2]]."
				continue
			else:
				scene._on_tile_tapped(Hex.parse(t))
			for i in int(o["after"]):
				await process_frame
	if o["whole"] != "":
		# (0.20) the whole board, however small that makes it (past the game's own furthest zoom)
		for i in 20:
			await process_frame
		var er: Rect2 = scene.board.extent()
		var vs: Vector2 = scene.get_viewport_rect().size
		var zz := minf(vs.x / er.size.x, (vs.y - 130.0) / er.size.y) * 0.95
		scene._stop_camera()
		scene.camera.zoom = Vector2(zz, zz)
		scene.camera.position = scene.board.to_global(er.get_center()) + Vector2(0, -10.0 / zz)
	# (0.19) catch what is moving partway: freeze=<seconds> from now, then everything stops
	if o["freeze"] != "":
		await create_timer(float(o["freeze"])).timeout
		paused = true
	await _shoot(out)


## The dock and the World Map.
func _world(scene: Node2D, o: Dictionary) -> void:
	scene.campaign.loot.seed_with(int(o["seed"]))
	scene.open_dock()
	if o["screen"] == "dock" and o.get("map", "") == "":
		await _dock(scene, o)
		return
	if o["dock"] != "":
		await _dock(scene, o)           # (0.10: the dock as it is before the team leaves)
	scene.dock_screen.show_teams()
	scene.dock_screen.choose_team(int(o["pick"]))
	if o["screen"] == "deploy":
		return
	scene.dock_screen.leave()
	var ms: MapScreen = scene.map_screen
	for i in 6:
		await process_frame
	for t in (o.get("map", "").split(";", false) if o.get("map", "") != "" else []):
		var bits: PackedStringArray = t.split(":")
		match bits[0]:
			"sel": ms.tap(bits[1])
			"walk": await ms.walk(bits[1])
			"do": ms.do(bits[1], bits[2] if bits.size() > 2 else null)
			"put":
				var c = scene.campaign.deploy.cur()
				c["pos"] = bits[1]
				scene.campaign.world.stand(bits[1])
				ms.selected = bits[1]
				scene.map_view.place_team(bits[1])
				ms.refresh()
				scene.centre_map(bits[1], true)
			"known":
				for k in scene.campaign.world.map["tiles"]:
					scene.campaign.world.state["known"][k] = 1
				ms.refresh()
			"fit": scene.fit_map()
			"zoom": scene.camera.zoom = Vector2.ONE * float(bits[1])
			"team": ms.show_team()
			"log": ms.show_log()
			"fight": scene.start_deploy_fight()
			"next": scene.setup._go(1)
			"start": scene._on_deploy_start(scene.setup.team(), StrikeTeams.setup_for(scene.setup.team(), scene.roster, scene.setup.heroes, scene.setup.leader, [], 3, 0), int(o["seed"]))
			"win", "lose":
				for u in scene.battle.side_units("enemy" if bits[0] == "win" else "ally"):
					u["hp"] = 0
					u["down"] = true
				if bits[0] == "win":
					scene.battle.wave = scene.battle.waves_total
					scene.battle.enemy_pile.clear()
					scene.battle.fx.check_downs()
				scene.battle.settle()
				scene.board.refresh_units(scene.battle)
				scene.show_result()
			"ok":
				var d: Dialog = scene.dialog if scene.dialog != null else ms.dialog
				if d != null:
					d.buttons[int(bits[1]) if bits.size() > 1 else 0].pressed.emit()
			"dock": scene.open_dock()
			"unit": scene.select(scene.battle.unit_by_id(bits[1]))
			"wait":
				for i in int(bits[1]):
					await process_frame
		for i in 12:
			await process_frame


## The dock: dock= ops, ";"-separated.
##   tab:<k>   give:<name>:<n>   reach:<n>   meet   restock   wantall   up:<id>:<level>   items:<name>,<name>
##   deploy   pick:<i>   pack:<name>:<by>   testing:<which>   ok:<n>   act:<what>:<args>   wait:<frames>
##   (0.25) strict (only the Heroes recruited, and the free ones, are yours)   hire:<name>   scroll:<px>
func _dock(scene: Node2D, o: Dictionary) -> void:
	var cm: Campaign = scene.campaign
	var dk: DockScreen = scene.dock_screen
	for t in (o["dock"].split(";", false) if o["dock"] != "" else []):
		var bits: PackedStringArray = t.split(":")
		match bits[0]:
			"tab": dk.show_tab(bits[1])
			"give": cm.dock.add_card(bits[1], int(bits[2]) if bits.size() > 2 else 1)
			"reach": cm.dock.state["reach"] = int(bits[1])
			"meet":
				for d in ["1", "2", "3", "4", "5", "6"]:
					cm.progress.see("district", d)
				for c in scene.roster.from_export:
					if Progress.is_foe(c):
						cm.progress.see("enemy", c["name"])
			"restock": cm.dock.restock()
			"strict": Dock.every_hero = false
			"hire": cm.dock.state["heroes"][bits[1]] = 1
			"scroll":
				await process_frame
				dk.list.scroll_by(float(bits[1]))
			"wantall":
				# (a Bounty Board that wants every Enemy, so that whatever is met wears the tag)
				cm.dock.state["bounties"] = cm.dock.foes().map(func(k): return {"name": k["name"], "kind": k["cardType"], "district": Progress.enemy_district(k), "claimed": false})
			"up": cm.dock.state["upgrades"][bits[1]] = int(bits[2])
			"pre": cm.dock.inv["pre"][bits[1]] = int(bits[2]) if bits.size() > 2 else 1
			"deploy": dk.show_teams()
			"pick": dk.choose_team(int(bits[1]))
			"pack": dk.set_pack(bits[1], int(bits[2]))
			"testing": dk.ask_testing(bits[1])
			"ok":
				if dk.dialog != null:
					dk.dialog.buttons[int(bits[1]) if bits.size() > 1 else 0].pressed.emit()
			"act":
				var what: Array = [bits[1]]
				for b in bits.slice(2):
					what.append(int(b) if b.is_valid_int() else b)
				dk.act(what)
			"show": dk.show_tab(dk.tab)
			"scroll": dk.list.scroll_by(float(bits[1]))
			"wait":
				for i in int(bits[1]):
					await process_frame
		for i in 4:
			await process_frame


## The Workshop: ws= ops, ";"-separated.
##   tab:designs|blueprints|export   new   chassis:<name>   edit:<design>
##   copyin:<export card>   testing   research:<keyword>   ok:<n>   grant:<keyword>:<level>
##   find:<chassis id>   act:<what>:<i>[:<more>]  (the editor's taps)   build:<i>   change:<i>:<j>
##   kb:<key>   step:<n>   drop:<i>   bedit:<step>   card:<name>   adj:1|0   (the builder's taps)
##   rename:<name>   copy   delete   leave   wait:<frames>   scroll:<px>
func _workshop(scene: Node2D, o: Dictionary) -> void:
	scene.open_dock()
	var cm: Campaign = scene.campaign
	scene.open_workshop()
	var w: WorkshopScreen = scene.workshop_screen
	for t in (o["ws"].split(";", false) if o["ws"] != "" else []):
		var bits: PackedStringArray = t.split(":")
		var ed: DesignEditor = w.editor
		match bits[0]:
			"tab": w.show_tab(bits[1])
			"new": w.pick_chassis()
			"chassis", "row":
				for r in w._rows:
					if r["text"] == bits[1]:
						w.tap_row(r)
						break
			"edit": w.edit(w.ws().by_name(bits[1]))
			"copyin":
				for c in scene.roster.from_export:
					if str(c.get("name")) == bits[1] and (c.get("_src") == "design" or c.get("_src") == "prebuilt"):
						w.copy_in(c)
						break
			"testing":
				for r in w._rows:
					if r.has("testing"):
						w.tap_row(r)
			"research": w.ask_research(bits[1])
			"ok":
				var d: Dialog = w.dialog if w.dialog != null else ed.dialog
				if d != null:
					d.buttons[int(bits[1]) if bits.size() > 1 else 0].pressed.emit()
			"grant":
				cm.progress.state["bp"][bits[1]] = int(bits[2]) if bits.size() > 2 else 1
				cm.designs_changed()
				w.show_tab(w.tab)
			"find":
				cm.progress.state["ch"][bits[1]] = 1
				cm.designs_changed()
				w.show_tab(w.tab)
			"act":
				var what: Array = [bits[1]]
				for b in bits.slice(2):
					what.append(int(b) if b.is_valid_int() else b)
				ed.act(what)
			"build": ed.open_builder(int(bits[1]), -1)
			"change": ed.open_builder(int(bits[1]), int(bits[2]))
			"kb": ed.sheet.act(["kb", t.substr(3)])
			"step": ed.sheet.act(["step", int(bits[1])])
			"drop": ed.sheet.act(["drop", int(bits[1])])
			"bedit": ed.sheet.act(["edit", bits[1]])
			"card": ed.sheet.act(["card", t.substr(5)])
			"adj": ed.sheet.act(["adj", bits[1] == "1"])
			"rename": ed.rename(bits[1])
			"copy": ed.copy()
			"delete": ed.ask_delete()
			"leave":
				scene.open_dock()
				scene.dock_screen.show_teams()
				scene.dock_screen.choose_team(0)
				scene.dock_screen.leave()
			"open":
				scene.open_dock()
				scene.open_workshop()
			"scroll":
				var l: TouchList = ed.list if ed.visible else w.list
				if ed.sheet != null:
					l = ed.sheet.list
				l.scroll_by(float(bits[1]))
			"wait":
				for i in int(bits[1]):
					await process_frame
			"dump":
				if ed.sheet != null:
					print("DUMP ", ed.sheet.b.view()["title"], " ", ed.sheet.b.view()["sentence"], " ", ed.sheet.offers())
				else:
					print("DUMP ", w.row_texts())
		for i in 6:
			await process_frame


func _shoot(out: String) -> void:
	for i in 30:
		await process_frame
	var img := root.get_texture().get_image()
	img.save_png(out)
	print("SHOT ", out, " ", img.get_size())
	# (0.16) where each Unit stands on the screen, and a tile's size there: for pictures made from a shot
	var sc = root.get_child(root.get_child_count() - 1)
	if sc != null and sc.get("battle") != null and sc.get("board") != null:
		for u in sc.battle.units:
			var v = sc.board.view_of(str(u["id"]))
			if v != null and v.is_inside_tree():
				var at: Vector2 = v.get_global_transform_with_canvas().origin
				print("UNITPOS ", u["id"], " ", str(u["name"]).replace(" ", "_"), " ", u["side"], " ", int(at.x), " ", int(at.y), " ", u.get("pos"))
		print("ZOOM ", sc.board.get_global_transform_with_canvas().get_scale().x)
	Kit.fresh()
	quit()
