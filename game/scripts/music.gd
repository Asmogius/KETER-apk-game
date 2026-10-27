## (0.39) The game's music: short chiptune loops it makes for itself, as it
## makes its sounds (sound.gd): a square-wave bass, a triangle arpeggio over
## it, and noise for drums. One for Home, one for the World Map and the dock,
## one for a fight and one for a Boss's floor. Each is made the first time it
## is wanted, off the main thread, and then kept; the change from one to
## another fades. Options' Music sets Off, Low or High.
class_name Music
extends Node

const RATE := 16000
const BARS := 4
## Each loop: its tempo, its key (a MIDI note), the chords (steps from the key,
## a bar each), the arpeggio's steps over a chord, and its drums.
const TRACKS := {
	"home": {"bpm": 84, "root": 45, "prog": [0, -4, -2, -5], "arp": [0, 7, 12, 7, 15, 7, 12, 7], "kick": false, "hat": false, "minor": true},
	"map": {"bpm": 96, "root": 43, "prog": [0, 3, -2, 5], "arp": [0, 3, 7, 10, 12, 10, 7, 3], "kick": false, "hat": true, "minor": true},
	"fight": {"bpm": 126, "root": 40, "prog": [0, 0, 3, -2], "arp": [0, 7, 12, 15, 12, 7, 12, 19], "kick": true, "hat": true, "minor": true},
	"boss": {"bpm": 138, "root": 38, "prog": [0, 1, 0, -1], "arp": [0, 6, 12, 6, 13, 6, 12, 18], "kick": true, "hat": true, "minor": true},
}
const LEVEL_DB := {"low": -20.0, "high": -11.0}

## Whether the game plays music at all (the tests turn it off: making a loop takes a moment).
static var auto := true
static var host: Music = null

var player: AudioStreamPlayer
var current := ""                       # the loop wanted now
var streams := {}                       # name -> AudioStreamWAV, once made
var _making := {}                       # name -> WorkerThreadPool task id
var _made := {}                         # name -> AudioStreamWAV, made off the main thread, not yet taken
var _mutex := Mutex.new()
var _fade: Tween = null


func _init() -> void:
	host = self


func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.volume_db = -80.0
	add_child(player)


## Plays this loop (or, with "", none), fading from the one before.
func want(name: String) -> void:
	if not auto:
		return
	if name == current and (player.playing or name == ""):
		_apply_level()
		return
	current = name
	if name == "" or Motion.music == "off":
		_fade_to(-80.0, true)
		return
	if streams.has(name):
		_start(name)
	elif not _making.has(name):
		_making[name] = WorkerThreadPool.add_task(_make_into.bind(name), false, "music " + name)


## The level Options asks for, now.
func _apply_level() -> void:
	if Motion.music == "off" or current == "":
		_fade_to(-80.0, true)
	elif player.playing:
		_fade_to(LEVEL_DB.get(Motion.music, -20.0), false)
	elif streams.has(current):
		_start(current)


func _process(_dt: float) -> void:
	if _making.is_empty():
		return
	for name in _making.keys():
		if WorkerThreadPool.is_task_completed(_making[name]):
			WorkerThreadPool.wait_for_task_completion(_making[name])
			_making.erase(name)
			_mutex.lock()
			if _made.has(name):
				streams[name] = _made[name]
				_made.erase(name)
			_mutex.unlock()
			if name == current and Motion.music != "off":
				_start(name)


func _start(name: String) -> void:
	player.stream = streams[name]
	player.volume_db = -40.0
	player.play()
	_fade_to(LEVEL_DB.get(Motion.music, -20.0), false)


func _fade_to(db: float, stop: bool) -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(player, "volume_db", db, 0.8)
	if stop:
		_fade.tween_callback(player.stop)


func _make_into(name: String) -> void:
	var w := make(name)
	_mutex.lock()
	_made[name] = w
	_mutex.unlock()


# ---------------------------------------------------------------- making a loop
static func _hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


## A loop of BARS bars, as a 16-bit stream that repeats.
static func make(name: String) -> AudioStreamWAV:
	var tr: Dictionary = TRACKS.get(name, TRACKS["map"])
	var beat := 60.0 / float(tr["bpm"])
	var count := int(RATE * beat * 4.0 * BARS)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name)
	var bass_ph := 0.0
	var arp_ph := 0.0
	var held := 0.0
	var prog: Array = tr["prog"]
	var arp: Array = tr["arp"]
	var root := float(tr["root"])
	var eighth := beat / 2.0
	var sixteenth := beat / 4.0
	for i in count:
		var t := float(i) / RATE
		var bar := int(t / (beat * 4.0)) % prog.size()
		var chord := root + float(prog[bar])
		# the bass: the chord's root on the eighths, a fifth on the off-beats
		var e := int(t / eighth)
		var et := fmod(t, eighth) / eighth
		var bf := _hz(chord + (7.0 if e % 4 == 3 else 0.0))
		bass_ph = fmod(bass_ph + bf / RATE, 1.0)
		var bass := (1.0 if bass_ph < 0.5 else -1.0) * (1.0 - et * 0.6) * 0.32
		# the arpeggio, two octaves up, a triangle on the sixteenths
		var s := int(t / sixteenth)
		var st := fmod(t, sixteenth) / sixteenth
		var af := _hz(chord + 24.0 + float(arp[s % arp.size()]))
		arp_ph = fmod(arp_ph + af / RATE, 1.0)
		var tri := 4.0 * absf(arp_ph - 0.5) - 1.0
		var arp_v := tri * (1.0 - st) * (1.0 - st) * 0.26
		# drums: a kick on the beats, a hat on the off-eighths
		var drum := 0.0
		var bt := fmod(t, beat)
		if tr["kick"] and bt < 0.12:
			drum += sin(TAU * (60.0 + 90.0 * (1.0 - bt / 0.12)) * bt) * (1.0 - bt / 0.12) * 0.55
		if tr["hat"] and e % 2 == 1 and et < 0.18:
			if i % 2 == 0:
				held = rng.randf_range(-1.0, 1.0)
			drum += held * (1.0 - et / 0.18) * 0.13
		var v := bass + arp_v + drum
		data.encode_s16(i * 2, int(clampf(v * 0.7, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = count
	return w
