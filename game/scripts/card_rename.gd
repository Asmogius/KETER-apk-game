## (0.32) A card renamed in the Sandbox's Card Forge keeps its place wherever a
## run or a team has it: every Strike Team, the dock (Heroes recruited and on
## offer, the Exchange's items, cards held), the team that is out, and the
## Behavior keywords chosen for it, in all three save files. Without this a
## rename would leave each of them holding a name no card has.
##
## A reference may be the name ("Dock Hand") or where it came from and the
## name ("master|Dock Hand"); either is renamed, the "where" kept.
class_name CardRename
extends RefCounted


static func ref(r: String, old: String, new: String) -> String:
	if r == old:
		return new
	var i := r.find("|")
	if i >= 0 and r.substr(i + 1) == old:
		return r.substr(0, i + 1) + new
	return r


static func _list(a, old: String, new: String) -> bool:
	if not (a is Array):
		return false
	var did := false
	for i in a.size():
		if a[i] is String:
			var n := ref(a[i], old, new)
			if n != a[i]:
				a[i] = n
				did = true
	return did


## A Dictionary's keys renamed (where two meet, their numbers add).
static func _keys(d, old: String, new: String) -> bool:
	if not (d is Dictionary):
		return false
	var did := false
	for k in d.keys():
		var n := ref(str(k), old, new)
		if n == str(k):
			continue
		var v = d[k]
		d.erase(k)
		if d.has(n) and (v is int or v is float) and (d[n] is int or d[n] is float):
			d[n] = d[n] + v
		else:
			d[n] = v
		did = true
	return did


## A Strike Team, renamed in place. Returns whether anything changed.
static func team(t: Dictionary, old: String, new: String) -> bool:
	var did := _list(t.get("heroes"), old, new)
	did = _list(t.get("protos"), old, new) or did
	for k in ["deck", "pouch", "consumables"]:
		did = _keys(t.get(k), old, new) or did
	var acts = t.get("actions")
	if acts is Dictionary:
		did = _keys(acts, old, new) or did
		for h in acts:
			did = _list(acts[h], old, new) or did
	for k in ["leader"]:
		if t.get(k) is String and ref(t[k], old, new) != t[k]:
			t[k] = ref(t[k], old, new)
			did = true
	return did


## A run as saved (campaign.json), renamed in place.
static func run(d: Dictionary, old: String, new: String) -> bool:
	var did := false
	var dk = d.get("dock")
	if dk is Dictionary:
		did = _keys(dk.get("heroes"), old, new) or did
		var st = dk.get("stock")
		if st is Dictionary:
			did = _list(st.get("items"), old, new) or did
			did = _list(st.get("heroes"), old, new) or did
			did = _keys(st.get("sold"), old, new) or did
			did = _keys(st.get("hired"), old, new) or did
	var inv = d.get("inventory")
	if inv is Dictionary:
		did = _keys(inv.get("cards"), old, new) or did
	var dp = d.get("deployment")
	if dp is Dictionary and dp.get("team") is Dictionary:
		did = team(dp["team"], old, new) or did
	return did


## Everywhere: all three save files' runs and teams, and the Behavior keywords.
static func everywhere(old: String, new: String) -> void:
	if old == "" or new == "" or old == new:
		return
	var files := []
	for n in range(1, SaveSlots.COUNT + 1):
		files.append(SaveSlots.campaign_file(n))
		files.append(SaveSlots.teams_file(n))
	# the run being played, wherever it is kept (the tests keep theirs elsewhere)
	for f in [Campaign.path, StrikeTeams.path]:
		if not files.has(f):
			files.append(f)
	for f in files:
		var d = SafeFile.read_json(f)
		if not (d is Dictionary):
			continue
		var did := false
		if d.get("teams") is Array:
			for t in d["teams"]:
				if t is Dictionary:
					did = team(t, old, new) or did
		elif d.get("kind") == "campaign":
			did = run(d, old, new)
		if did:
			SafeFile.write(f, JSON.stringify(d, "\t"))
	var b := Behaviors.load_all()
	if b.has(old) and not b.has(new):
		b[new] = b[old]
		b.erase(old)
		Behaviors.save_all(b)
