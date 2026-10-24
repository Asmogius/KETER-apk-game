## (0.32) Three save files, each a whole run: the World Map as explored, the
## dock and its stockpile, what has been found and recruited, the designs, the
## deployment out, and the Strike Teams. Each slot is a folder of its own
## (user://saves/1/ ...), holding the run's campaign.json and
## strike_teams.json; slots.json says which is played and what each is called.
##
## What is the player's rather than a run's is shared by all three: the
## Sandbox, the Behavior keywords chosen for cards, the settings.
##
## A game saved before 0.32 kept its run beside the others' files; the first
## time this one starts, that run becomes Save 1.
class_name SaveSlots
extends RefCounted

const COUNT := 3
const ROOT := "user://saves/"
const OLD_CAMPAIGN := "user://campaign.json"
const OLD_TEAMS := "user://strike_teams.json"

## Where the slots are kept (the tests point this somewhere of their own).
static var root := ROOT
## Whether the game picks its slot when it starts (the tests keep files of their own).
static var auto := true
## Where a game saved before 0.32 kept its run (the tests point these elsewhere).
static var old_campaign := OLD_CAMPAIGN
static var old_teams := OLD_TEAMS
static var current := 1
static var error := ""


static func dir_of(n: int) -> String:
	return root.path_join(str(n))


static func campaign_file(n: int) -> String:
	return dir_of(n).path_join("campaign.json")


static func teams_file(n: int) -> String:
	return dir_of(n).path_join("strike_teams.json")


static func _index_file() -> String:
	return root.path_join("slots.json")


static func index() -> Dictionary:
	var out := {"current": 1, "names": {}}
	if FileAccess.file_exists(_index_file()):
		var d = JSON.parse_string(FileAccess.get_file_as_string(_index_file()))
		if d is Dictionary:
			out["current"] = clampi(int(d.get("current", 1)), 1, COUNT)
			if d.get("names") is Dictionary:
				out["names"] = d["names"]
	return out


static func _write_index(ix: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root))
	var f := FileAccess.open(_index_file(), FileAccess.WRITE)
	if f == null:
		error = "The save files' list couldn't be written."
		return false
	f.store_string(JSON.stringify(ix, "\t"))
	f.close()
	return true


## Starts the game on the slot last played: the run's files are that slot's.
## A run saved before 0.32 moves into Save 1 first.
static func start() -> void:
	_migrate()
	use(index()["current"])


## Plays a slot from now on (its files are where the run and teams are kept).
static func use(n: int) -> void:
	current = clampi(n, 1, COUNT)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_of(current)))
	Campaign.path = campaign_file(current)
	StrikeTeams.path = teams_file(current)
	var ix := index()
	ix["current"] = current
	_write_index(ix)


static func _migrate() -> void:
	var to1 := [[old_campaign, campaign_file(1)], [old_teams, teams_file(1)]]
	for pair in to1:
		if FileAccess.file_exists(pair[0]) and not FileAccess.file_exists(pair[1]):
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_of(1)))
			DirAccess.rename_absolute(ProjectSettings.globalize_path(pair[0]), ProjectSettings.globalize_path(pair[1]))


static func used(n: int) -> bool:
	return SafeFile.exists(campaign_file(n)) or SafeFile.exists(teams_file(n))


## A slot's name: the one given it, or "Save n".
static func name_of(n: int) -> String:
	var nm := str(index()["names"].get(str(n), "")).strip_edges()
	return nm if nm != "" else "Save %d" % n


static func rename(n: int, nm: String) -> bool:
	var ix := index()
	nm = nm.strip_edges().substr(0, 32)
	if nm == "":
		ix["names"].erase(str(n))
	else:
		ix["names"][str(n)] = nm
	return _write_index(ix)


## What a slot holds, read from its files without playing it: {used, shards,
## deployments, out (the team that is out, or ""), heroes recruited, designs,
## teams, saved (when, as text)}.
static func summary(n: int) -> Dictionary:
	var out := {"used": used(n), "shards": 0, "deployments": 0, "out": "", "heroes": 0, "designs": 0, "teams": 0, "saved": ""}
	if SafeFile.exists(campaign_file(n)):
		var d = SafeFile.read_json(campaign_file(n))
		if d is Dictionary:
			var stock = d.get("stock")
			out["shards"] = int(Rules.num(stock.get("shards"), 0)) if stock is Dictionary else 0
			var w = d.get("world")
			out["deployments"] = int(Rules.num(w.get("completed"), 0)) if w is Dictionary else 0
			var dp = d.get("deployment")
			if dp is Dictionary and dp.get("team") is Dictionary:
				out["out"] = str(dp["team"].get("name", "A Strike Team"))
			var dk = d.get("dock")
			out["heroes"] = (dk["heroes"] as Dictionary).size() if dk is Dictionary and dk.get("heroes") is Dictionary else 0
			out["designs"] = (d["designs"] as Dictionary).size() if d.get("designs") is Dictionary else 0
		var t := FileAccess.get_modified_time(campaign_file(n))
		if t > 0:
			out["saved"] = Time.get_datetime_string_from_unix_time(t + int(Time.get_time_zone_from_system().get("bias", 0)) * 60, true)
	if SafeFile.exists(teams_file(n)):
		var td = SafeFile.read_json(teams_file(n))
		out["teams"] = (td["teams"] as Array).size() if td is Dictionary and td.get("teams") is Array else 0
	return out


## One line for a slot: "1,240 shards · 6 deployments · Vanguard is out".
static func line_of(n: int) -> String:
	var s := summary(n)
	if not s["used"]:
		return "Empty: a new run starts here."
	var bits := ["%s shards" % grouped(int(s["shards"])), "%d deployment%s" % [s["deployments"], "" if s["deployments"] == 1 else "s"]]
	if s["heroes"] > 0:
		bits.append("%d Hero%s recruited" % [s["heroes"], "" if s["heroes"] == 1 else "es"])
	bits.append("%d Strike Team%s" % [s["teams"], "" if s["teams"] == 1 else "s"])
	if s["out"] != "":
		bits.append("%s is out" % s["out"])
	if s["saved"] != "":
		bits.append("saved " + str(s["saved"]).substr(0, 16).replace("T", " "))
	return " · ".join(bits)


## 1240 as "1,240".
static func grouped(v: int) -> String:
	var t := str(absi(v))
	var out := ""
	while t.length() > 3:
		out = "," + t.substr(t.length() - 3) + out
		t = t.substr(0, t.length() - 3)
	return ("-" if v < 0 else "") + t + out


## Wipes a slot: its run and its teams are gone.
static func delete(n: int) -> void:
	for f in [campaign_file(n), teams_file(n)]:
		SafeFile.remove(f)
	rename(n, "")


## Copies one slot's run and teams over another's (which is wiped first).
static func copy(from: int, to: int) -> bool:
	if from == to or not used(from):
		return false
	delete(to)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_of(to)))
	for pair in [[campaign_file(from), campaign_file(to)], [teams_file(from), teams_file(to)]]:
		var d = SafeFile.read_json(pair[0])
		if d != null and not SafeFile.write(pair[1], JSON.stringify(d, "\t")):
			error = "The copy couldn't be written."
			return false
	rename(to, name_of(from) + " (copy)")
	return true
