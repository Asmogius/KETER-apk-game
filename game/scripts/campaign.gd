## What the game keeps between sessions, other than your Strike Teams: what
## you have seen of the World Map, the stockpile at the dock, the blueprints
## and chassis you have found, your designs, the deployment that is out, and
## the ones that came home or didn't.
##
## It is the game's own, not the Companion's: the map and its tables come in
## the export, what you have done on it stays here. A new export with a
## different map starts exploration again; the stockpile and what you have
## found stay.
##
## Saved after every step, Cache, Event and finished fight. A fight is not
## saved part-way: one closed half-way starts again from its setup.
class_name Campaign
extends RefCounted

const FILE := "user://campaign.json"
const FORMAT := 1

## Where it is kept (the tests point this somewhere of their own).
static var path := FILE

var loot: Loot                # the map's own stream: chance, or a seed in the tests
var world: World
var progress: Progress
var deploy: Deployment
var skins: Skins
var workshop: Workshop
var dock: Dock
var roster: Roster = null
var data: KeterExport = null
var note := ""                # what loading had to say: a new map, a file that couldn't be read
var error := ""               # why the last save failed, if it did


## data: the export. floors: its floors. seed: a number makes every roll on
## the map the same each time (the tests); null is chance.
func _init(data: KeterExport, roster: Roster, floors: Array, seed = null) -> void:
	loot = Loot.new(roster.loot_tables() if roster != null else null, seed)
	world = World.new(loot, data.content("world_map") if data != null else null, floors)
	progress = Progress.new(loot, data.content("pools") if data != null else null, data.content("chassis") if data != null else null, data.content("tables") if data != null else null)
	deploy = Deployment.new(world, progress, loot, roster)
	skins = Skins.new(data.content("skins") if data != null else null, progress.chassis,
		func(id): return data != null and not data.picture_file(id).is_empty())
	workshop = Workshop.new(progress, data.content("tables") if data != null else null, skins)
	workshop.is_out = deploy.locked_design
	deploy.workshop = workshop
	dock = Dock.new(deploy, data.content("tables") if data != null else null)
	dock.workshop = workshop
	deploy.dock = dock
	# (0.22) cards found as loot: the export's own, kept at the dock when the team comes home
	# (held weakly: the progress is the dock's own, through its deployment, and a
	# strong hold either way would keep both alive for ever)
	var cards_from: Array = roster.from_export if roster != null else []
	var dock_ref: WeakRef = weakref(dock)
	progress.card_source = func(): return cards_from
	progress.card_sink = func(nm):
		var d = dock_ref.get_ref()
		if d != null:
			d.add_card(str(nm), 1)
	self.roster = roster
	self.data = data
	if roster != null:
		workshop.set_prebuilts(roster.from_export)
	if roster != null:
		roster.progress = progress
	load_saved()
	designs_changed()


## A picture from the export, by the Pixel Studio's id for it, or null.
func roster_texture(picture_id) -> Texture2D:
	return data.picture_texture(picture_id) if data != null and Rules.truthy(picture_id) else null


## The designs have changed: the cards they make are what the Decks and the
## fights see from now on.
func designs_changed() -> void:
	if roster != null:
		roster.set_designs(workshop.cards())


# ---------------------------------------------------------------- keeping it
func to_dict() -> Dictionary:
	return {"game": "KETER", "kind": "campaign", "format": FORMAT, "map": world.identity(), "world": world.state, "progress": progress.state,
		"stock": deploy.stock, "history": deploy.history, "deployment": deploy.s, "designs": workshop.designs, "dock": dock.state, "inventory": dock.inv}


func save() -> bool:
	# (0.32) written beside the last save and only then put in its place: a phone that dies part-way loses nothing
	if not SafeFile.write(path, JSON.stringify(to_dict(), "\t")):
		# said on the map and at the dock: progress that isn't kept must not come as a surprise
		error = "Your progress couldn't be saved: the device wouldn't write the file. It is tried again at every step."
		return false
	error = ""
	return true


## Reads what was saved. A map that isn't the one saved against starts
## exploration again, and a Strike Team out on the old one is brought home
## with what it carries.
func load_saved() -> void:
	note = ""
	if not SafeFile.exists(path):
		return
	var used := []
	var d = SafeFile.read_json(path, used)
	if not (d is Dictionary) or d.get("kind") != "campaign":
		note = "Your saved progress couldn't be read, so this starts afresh."
		return
	if used == ["bak"]:
		note = "The last save couldn't be read, so the one before it was used: the last step or fight may need doing again."
	d = Rules.ints(d)
	progress.state = Progress.tidy(d.get("progress"))
	deploy.stock = Loot.norm(d.get("stock"))
	deploy.history = d["history"] if d.get("history") is Array else []
	deploy.s = d["deployment"] if d.get("deployment") is Dictionary else null
	workshop.designs = {}
	if d.get("designs") is Dictionary:
		for id in d["designs"]:
			var ds = d["designs"][id]
			if ds is Dictionary and str(id) != Workshop.STARTER["id"]:
				ds["id"] = str(id)
				workshop.designs[str(id)] = ds
	dock.state = Dock.tidy(d.get("dock"))
	dock.inv = Dock.tidy_inv(d.get("inventory"))
	world.state = World.tidy(d.get("world"))
	if str(d.get("map", "")) != world.identity():
		var was_out := deploy.active()
		if was_out:
			deploy.recall()
		var done: int = world.state["completed"]
		world.state = World.blank_state()
		world.state["completed"] = done
		if world.exists():
			note = (note + " " if note != "" else "") + "This export has a different World Map, so exploration starts again. Your stockpile and what you have found are kept." + (" The Strike Team that was out has been brought home with its haul." if was_out else "")
		elif was_out:
			note = (note + " " if note != "" else "") + "This export has no World Map, so the Strike Team that was out has been brought home with its haul."
		save()
	elif deploy.active():
		_mend()


## A deployment saved against cards or floors the export no longer has still
## has to be playable: a fight whose floor is gone is drawn again.
func _mend() -> void:
	var c = deploy.cur()
	if c == null or c["activity"] == null:
		return
	var a: Dictionary = c["activity"]
	var fl: Array = a["floors"] if a.get("floors") is Array else []
	if fl.is_empty() or fl.any(func(k): return world.floor_named(k) == null):
		var fresh := world.draw_floors(a["district"], int(a["skull"]), maxi(1, fl.size()), a["kind"] != "poi", str(a.get("tile", "")))
		if fresh.is_empty():
			c["activity"] = null
		else:
			a["floors"] = fresh
			a["index"] = clampi(int(a.get("index", 0)), 0, fresh.size() - 1)


## Forgets everything (the tests, and Start over).
func reset() -> void:
	world.state = World.blank_state()
	progress.state = Progress.blank()
	deploy.s = null
	deploy.stock = Loot.bag()
	deploy.history = []
	workshop.designs = {}
	dock.reset()
	designs_changed()
	SafeFile.remove(path)


# ---------------------------------------------------------------- in words
## The stockpile, as lines for the dock: [{text, colour}], shards first, then
## each kind of component it holds, rarest first.
func stock_lines() -> Array:
	var b := Loot.norm(deploy.stock)
	var out := [{"text": "%d Aether shard%s" % [b["shards"], "" if b["shards"] == 1 else "s"], "colour": "#efdd91", "icon": "shards"}]
	for l in loot.lines(b):
		var ty: String = ""
		for t in Loot.TYPES:
			if t["id"] == l["type"]:
				ty = t["short"]
		out.append({"text": "%d × %s" % [l["n"], l["name"]], "sub": "%s · %s part" % [l["rarityLabel"], ty], "colour": l["color"], "icon": "part_" + str(l["type"])})
	return out


## What the dock made of a deployment's end, in sentences (0.10): what came
## back to it or was lost with the team, bounties paid, your reach, insurance,
## and the Exchange restocked. r: what home() or wipe() returned.
func end_lines(r: Dictionary, wiped: bool) -> Array:
	var out := []
	var dk: Dictionary = r.get("dock", {}) if r.get("dock") is Dictionary else {}
	var pk = r.get("lostPack") if wiped else (deploy.last().get("pack") if deploy.last() != null else null)
	var names := []
	if pk is Dictionary:
		for part in ["cons", "protos"]:
			var m = pk.get(part)
			if m is Dictionary:
				for nm in m:
					if int(m[nm]) > 0:
						names.append(("%d × %s" % [int(m[nm]), nm]) if int(m[nm]) > 1 else str(nm))
	if not names.is_empty():
		out.append(("Lost with it, as packed: %s." if wiped else "Back to the dock, unused: %s.") % ", ".join(names))
	if dk.get("lostHeroes") is Array and not dk["lostHeroes"].is_empty():
		out.append("Lost with the team: %s. Recruit them again at the dock when they're on offer." % ", ".join(dk["lostHeroes"]))
	for b in dk.get("bounties", []):
		out.append("Bounty on %s paid: %s." % [b["name"], loot.text(b["bag"])])
	if dk.get("insured") != null:
		out.append("Salvage insurance kept %s." % loot.text(dk["insured"]))
	if dk.get("reach") != null:
		out.append("Your reach is now Skull Level %d: the Exchange deals in components up to %s." % [int(dk["reach"]), Loot.RARITIES[dock.reach_rarity()]["label"]])
	if Rules.truthy(dk.get("restocked")):
		out.append("The Exchange has restocked, and the Bounty Board has changed.")
	return out


## Where things stand, in a line for the home screen.
func status_line() -> String:
	if not world.exists():
		return "This export has no World Map."
	var c = deploy.cur()
	if c != null:
		return "Deployment %d is out with %s: %d step%s, %d fight%s." % [int(c["n"]), str(c["team"].get("name", "")), int(c["steps"]), "" if int(c["steps"]) == 1 else "s", int(c["fights"]), "" if int(c["fights"]) == 1 else "s"]
	var done: int = world.state["completed"]
	var last = deploy.last()
	var said := "%d deployment%s so far." % [done, "" if done == 1 else "s"]
	if last != null and last.get("result") == "wipe":
		said += " Deployment %d was wiped out: its haul was lost." % int(last["n"])
	elif last != null and last.get("result") == "home":
		said += " Deployment %d came home." % int(last["n"])
	return said
