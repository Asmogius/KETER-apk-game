## (0.45) The game's black box: the last few things it was doing, kept in a
## small file as it does them (written and closed each time, so it survives the
## game closing all at once), marked closed when the game is put away or shut
## the usual way. If it opens and finds the last run never closed (the phone
## killed it, or it crashed), it can say what it was doing then, with the
## engine's last messages from that run's log, for you to copy and send.
class_name BlackBox
extends RefCounted

const KEEP := 12                        # steps kept, the newest last

static var path := "user://black_box.json"
static var log_dir := "user://logs"
## Off for the tests (Kit.fresh), which make and drop the game many times over.
static var enabled := true
static var trail: Array = []            # [{t: unix seconds, step}]
static var _state := "open"


## The game starts: what the last run left, read before anything is written.
## Returns the report to show ("" when the last run closed as it should).
static func begin(version: String) -> String:
	if not enabled:
		return ""
	var last := read()
	trail = []
	_state = "open"
	mark("started, version " + version)
	if str(last.get("state", "")) != "open" or (last.get("trail", []) as Array).is_empty():
		return ""
	return report(last)


static func read() -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d if d is Dictionary else {}


## A step, kept at once.
static func mark(step: String) -> void:
	if not enabled:
		return
	trail.append({"t": int(Time.get_unix_time_from_system()), "step": step})
	while trail.size() > KEEP:
		trail.pop_front()
	_write()


## The game put away (paused, closed) or brought back.
static func set_state(s: String) -> void:
	if not enabled:
		return
	_state = s
	_write()


static func _write() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"state": _state, "trail": trail}))
	f.close()


## What to show and copy: what it was doing as it closed, and the engine's last
## errors and warnings from that run's log.
static func report(last: Dictionary) -> String:
	var steps: Array = last.get("trail", [])
	var lines := []
	for s in steps.slice(maxi(0, steps.size() - 6)):
		var when := Time.get_datetime_string_from_unix_time(int(s.get("t", 0)), true)
		lines.append("%s  %s" % [when, str(s.get("step", ""))])
	var text := "Last time, KETER closed while it was doing this (the newest last):\n" + "\n".join(lines)
	var tail := log_tail()
	if not tail.is_empty():
		text += "\n\nThe engine's last messages then:\n" + "\n".join(tail)
	return text


## The last errors and warnings in the log of the run before this one (Godot
## starts a new log each run, keeping the last few with their times on them).
static func log_tail(n := 8) -> Array:
	var d := DirAccess.open(log_dir)
	if d == null:
		return []
	var logs := Array(d.get_files()).filter(func(f): return str(f).begins_with("godot") and str(f).ends_with(".log") and str(f) != "godot.log")
	if logs.is_empty():
		return []
	logs.sort()
	var text := FileAccess.get_file_as_string(log_dir.path_join(str(logs[-1])))
	var out := []
	var lines := text.split("\n")
	for i in lines.size():
		var l: String = lines[i]
		if l.begins_with("ERROR") or l.begins_with("SCRIPT ERROR") or l.begins_with("WARNING") or l.contains("crash") or l.contains("signal"):
			out.append(l.strip_edges().left(220))
			if i + 1 < lines.size() and lines[i + 1].strip_edges().begins_with("at:"):
				out.append("   " + lines[i + 1].strip_edges().left(200))
	return out.slice(maxi(0, out.size() - n * 2))
