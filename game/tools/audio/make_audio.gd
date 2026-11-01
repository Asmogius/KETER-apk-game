## (0.45) The game's music and sounds, made once and kept as resources in
## res://audio (music_<name>.res, sfx_<name>.res), so the phone loads them
## rather than making them as it plays (on other threads, as it did). The same
## loops and blips Music.make and Sound._make make (run_tests checks they match).
##   godot --headless --path . --script res://tools/audio/make_audio.gd
extends SceneTree


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://audio"))
	var n := 0
	for name in Music.TRACKS:
		var err := ResourceSaver.save(Music.make(str(name)), Music.made_path(str(name)))
		print("%s %s" % [Music.made_path(str(name)), "ok" if err == OK else "FAILED %d" % err])
		n += 1 if err == OK else 0
	for name in Sound.NAMES:
		var err := ResourceSaver.save(Sound._make(str(name)), Sound.made_path(str(name)))
		print("%s %s" % [Sound.made_path(str(name)), "ok" if err == OK else "FAILED %d" % err])
		n += 1 if err == OK else 0
	print("made %d of %d" % [n, Music.TRACKS.size() + Sound.NAMES.size()])
	quit(0 if n == Music.TRACKS.size() + Sound.NAMES.size() else 1)
