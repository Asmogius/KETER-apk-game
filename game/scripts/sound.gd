## The game's sounds (0.12): retro blips it makes for itself at start-up, out
## of square waves and noise, and yours in their place. A .wav in a folder
## named sounds, in the game's folder, named as below (hit.wav, say), is used
## instead of the game's own. Settings' Sound switch mutes them all.
class_name Sound
extends Node

## Each sound, and when it plays.
const NAMES := {
	"bolt": "a Bolt is fired", "shell": "a Shell is fired", "beam": "a Beam is fired", "spray": "a Spray is fired",
	"blast": "a Shell or an area lands", "melee": "a Unit lunges at another", "hit": "an attack hurts",
	"miss": "an attack misses, or glances off", "heal": "a Unit is healed", "down": "a Unit goes down",
	"step": "a Unit steps onto a tile", "card": "a card is played", "tap": "a button is pressed"}
const DIR := "res://sounds/"
const RATE := 22050

static var host: Sound = null           # the one in the game
static var streams := {}                # name -> AudioStream
static var mine := {}                   # name -> true: yours, from the sounds folder
static var played: Array = []           # every sound asked for, muted or not (the tests read it)

var _players: Array[AudioStreamPlayer] = []


func _init() -> void:
	host = self
	load_all()


func _ready() -> void:
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.volume_db = -8.0
		add_child(p)
		_players.append(p)


## The game's own sounds, then yours over them where there are any.
static func load_all() -> void:
	streams = {}
	mine = {}
	for n in NAMES:
		streams[n] = _make(n)
		var f: String = DIR + n + ".wav"
		if FileAccess.file_exists(f):
			var w := AudioStreamWAV.load_from_buffer(FileAccess.get_file_as_bytes(f))
			if w != null:
				streams[n] = w
				mine[n] = true


## Plays a sound (unless the sound is off).
static func play(n: String) -> void:
	played.append(n)
	if played.size() > 400:
		played = played.slice(-200)
	if not Motion.sound or host == null or not streams.has(n) or not host.is_inside_tree():
		return
	for p in host._players:
		if not p.playing:
			p.stream = streams[n]
			p.play()
			return
	host._players[0].stream = streams[n]
	host._players[0].play()


# ---------------------------------------------------------------- making them
## A sound of the game's own: a square wave, noise, or both, its pitch sliding
## from one note to another as it fades.
static func _make(n: String) -> AudioStreamWAV:
	var spec: Dictionary = {
		"bolt": {"len": 0.09, "f0": 1300.0, "f1": 380.0, "noise": 0.1},
		"shell": {"len": 0.16, "f0": 260.0, "f1": 120.0, "noise": 0.25},
		"beam": {"len": 0.26, "f0": 1500.0, "f1": 1100.0, "noise": 0.0, "wobble": 40.0},
		"spray": {"len": 0.13, "f0": 600.0, "f1": 300.0, "noise": 0.85, "chop": 3},
		"blast": {"len": 0.34, "f0": 120.0, "f1": 40.0, "noise": 0.9},
		"melee": {"len": 0.1, "f0": 300.0, "f1": 700.0, "noise": 0.75},
		"hit": {"len": 0.09, "f0": 220.0, "f1": 90.0, "noise": 0.6},
		"miss": {"len": 0.14, "f0": 500.0, "f1": 900.0, "noise": 0.9, "soft": 0.5},
		"heal": {"len": 0.22, "f0": 600.0, "f1": 1200.0, "noise": 0.0, "steps": 3},
		"down": {"len": 0.36, "f0": 420.0, "f1": 55.0, "noise": 0.2},
		"step": {"len": 0.04, "f0": 180.0, "f1": 140.0, "noise": 0.5, "soft": 0.45},
		"card": {"len": 0.12, "f0": 700.0, "f1": 1050.0, "noise": 0.0, "steps": 2},
		"tap": {"len": 0.035, "f0": 1100.0, "f1": 1000.0, "noise": 0.0, "soft": 0.6},
	}.get(n, {"len": 0.05, "f0": 800.0, "f1": 800.0, "noise": 0.0})
	var count := int(RATE * float(spec["len"]))
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(n)
	var phase := 0.0
	var held := 0.0
	var steps := int(spec.get("steps", 0))
	var chop := int(spec.get("chop", 0))
	for i in count:
		var t := float(i) / count
		var f: float = lerpf(spec["f0"], spec["f1"], t)
		if steps > 0:
			f = lerpf(spec["f0"], spec["f1"], floorf(t * steps) / maxf(1.0, steps - 1))
		f += sin(t * TAU * 12.0) * float(spec.get("wobble", 0.0))
		phase = fmod(phase + f / RATE, 1.0)
		var sq := 1.0 if phase < 0.5 else -1.0
		# noise held for a few samples, so it reads as 8-bit
		if i % 3 == 0:
			held = rng.randf_range(-1.0, 1.0)
		var nz: float = spec["noise"]
		var v := sq * (1.0 - nz) + held * nz
		var env := (1.0 - t) * (1.0 - t) * minf(1.0, t * 60.0 + 0.05)
		if chop > 0 and int(t * chop * 2) % 2 == 1:
			env *= 0.15
		v *= env * float(spec.get("soft", 1.0)) * 0.55
		var s := int(clampf(v, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
