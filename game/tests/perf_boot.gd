## (0.44) What booting costs, a script at a time: each loaded (compiled) on its own, slowest first.
##   godot --headless --path . --script res://tests/perf_boot.gd
extends SceneTree


func _initialize() -> void:
	var rows := []
	var t_all := Time.get_ticks_usec()
	var d := DirAccess.open("res://scripts")
	for f in d.get_files():
		if not f.ends_with(".gd"):
			continue
		var s := Time.get_ticks_usec()
		var sc = load("res://scripts/" + f)
		rows.append([(Time.get_ticks_usec() - s) / 1000.0, f])
	rows.sort_custom(func(a, b): return a[0] > b[0])
	for r in rows.slice(0, 25):
		print("%8.1f ms  %s" % r)
	print("all scripts: %.1f ms" % ((Time.get_ticks_usec() - t_all) / 1000.0))
	var s2 := Time.get_ticks_usec()
	var packed: PackedScene = load("res://scenes/main.tscn")
	print("main.tscn after them: %.1f ms" % ((Time.get_ticks_usec() - s2) / 1000.0))
	s2 = Time.get_ticks_usec()
	var n = packed.instantiate()
	print("instantiate: %.1f ms" % ((Time.get_ticks_usec() - s2) / 1000.0))
	n.free()
	# each screen, made on its own (the scripts loaded already)
	var made := []
	for pair in [["SetupScreen", func(): return SetupScreen.new()], ["MapScreen", func(): return MapScreen.new()], ["TeamsScreen", func(): return TeamsScreen.new()],
			["ForgeScreen", func(): return ForgeScreen.new()], ["ChassisScreen", func(): return ChassisScreen.new()], ["PoiScreen", func(): return PoiScreen.new()],
			["StudioScreen", func(): return StudioScreen.new()], ["SavesScreen", func(): return SavesScreen.new()], ["DockScreen", func(): return DockScreen.new()],
			["WorkshopScreen", func(): return WorkshopScreen.new()], ["HandoffScreen", func(): return HandoffScreen.new()], ["Board", func(): return Board.new()],
			["HandTray", func(): return HandTray.new()], ["UnitPanel", func(): return UnitPanel.new()], ["LogPanel", func(): return LogPanel.new()], ["HomeScreen", func(): return HomeScreen.new("0")],
			["Music", func(): return Music.new()], ["Sound", func(): return Sound.new()], ["MapView", func(): return MapView.new()]]:
		var s3 := Time.get_ticks_usec()
		var o = pair[1].call()
		made.append([(Time.get_ticks_usec() - s3) / 1000.0, pair[0]])
		if o is Node:
			o.free()
	made.sort_custom(func(a, b): return a[0] > b[0])
	for m in made:
		print("%8.1f ms  new %s" % m)
	quit(0)
