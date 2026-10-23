## The dock: where deployments start and end, and home base between them.
##
## Tabs (0.10): the Stockpile (shards and components brought home, what the
## dock keeps for you, the blueprints and chassis you own, the deployments so
## far, and a Testing row); the Exchange (components, lots of rarer ones,
## blueprints and chassis, Consumables and Prototypes, pre-built Troops, and
## selling); (0.25) Recruit (the Heroes on offer, the free ones and the ones
## you have); Reclaiming; the Bounty Board; and Upgrades. Everything but looking
## waits while a Strike Team is out.
##
## (0.15) QM-7, the Hangar's logistics robot, keeps the dock: its portrait
## blinks at the top, and it says one line at a time to fit what is
## happening. What each tab is for is behind the "?" beside it. On the
## Exchange each thing for sale is a tile with its picture and a price tag;
## a section with nothing in it is one quiet line; Deploy is the gold button.
##
## Deploy chooses a Strike Team: its Troops must be your Workshop's designs,
## and every copy in its Deck is paid for in Troop parts as it leaves (the
## starter's first few free); pre-built copies bought at the Exchange join it;
## and the Pack picks which of the Consumables and Prototypes you own go with
## it. Field copy makes a copy of a team that holds other Troops, without
## them, ready to leave. The Workshop opens from here.
class_name DockScreen
extends Control

signal closed                          # Home
signal map_requested                   # look at the map, or go back to the team that is out
signal deployed                        # a Strike Team has just left
signal workshop_requested

const TABS := [["stockpile", "Stockpile"], ["exchange", "Exchange"], ["recruit", "Recruit"], ["reclaim", "Reclaim"], ["bounties", "Bounties"], ["upgrades", "Upgrades"]]

var campaign: Campaign = null
var roster: Roster = null
var teams: Array = []
var choosing := false                  # the list is the Strike Teams, to send one out
var team_i := -1
var tab := "stockpile"
var pack := {}                         # what the chosen team packs: name -> how many
var dialog: Dialog = null

var title: Label
var hint: Label
var tabs := {}
var tab_row: HBoxContainer
var list: TouchList
var note: Label
var back_btn: Button
var map_btn: Button
var go_btn: Button
var shop_btn: Button
var field_btn: Button
var keeper: PanelContainer             # (0.15) QM-7: its portrait, its line, and the tab's "?"
var portrait: TextureRect
var keeper_line: Label
var help_btn: Button
var help_text := ""                    # what the "?" says: what the tab is for
var moment := ""                       # what QM-7 is answering: a tab, or something just done
var _said := 0                         # how many lines it has said (it takes turns through them)
var _seen_deployments := -1            # the deployments it has seen come home
var _blink: Timer
var _rows: Array = []                  # what each row (or tile) stands for
var _list_of: Array = []               # (0.15) each row of the list: the entry it is, or the tiles in it


func _init() -> void:
	var col := UI.page(self, "dock", 0.72)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	col.add_child(head)
	title = UI.label("The dock", 30, UI.CYAN)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	tab_row = HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	head.add_child(tab_row)
	for k in TABS:
		var key: String = k[0]
		var b := UI.button(k[1], func(): show_tab(key), 124)
		b.toggle_mode = true
		tab_row.add_child(b)
		tabs[key] = b
	hint = UI.label("", 18, UI.PALE, true)
	hint.visible = false                 # (0.15) what the tab is for: behind the "?"
	col.add_child(hint)
	keeper = PanelContainer.new()
	keeper.add_theme_stylebox_override("panel", UI.box(UI.PANEL, UI.LINE, 1, 6, 10))
	col.add_child(keeper)
	var kh := HBoxContainer.new()
	kh.add_theme_constant_override("separation", 16)
	keeper.add_child(kh)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UI.box(UI.BG, Look.STEEL_EDGE, 2, 2, 2))
	kh.add_child(frame)
	portrait = TextureRect.new()
	portrait.texture = Art.menu_piece("qm7")
	portrait.custom_minimum_size = Vector2(128, 128)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(portrait)
	var kv := VBoxContainer.new()
	kv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kv.alignment = BoxContainer.ALIGNMENT_CENTER
	kv.add_theme_constant_override("separation", 8)
	kh.add_child(kv)
	kv.add_child(Look.read("QM-7 · Hangar Operations", Color("#e88a36")))
	keeper_line = Look.read("", UI.TEXT, true)
	kv.add_child(keeper_line)
	help_btn = Button.new()
	help_btn.text = "?"
	help_btn.theme_type_variation = "IconButton"
	help_btn.custom_minimum_size = Vector2(56, 56)
	help_btn.size_flags_vertical = Control.SIZE_SHRINK_END
	help_btn.tooltip_text = "What this tab is for"
	help_btn.pressed.connect(show_help)
	kh.add_child(help_btn)
	_blink = Timer.new()
	_blink.one_shot = true
	_blink.timeout.connect(_on_blink)
	add_child(_blink)
	list = TouchList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.row_tapped.connect(_on_row)
	col.add_child(list)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 14)
	col.add_child(foot)
	back_btn = UI.button("Home", _back)
	foot.add_child(back_btn)
	note = UI.label("", 17, UI.GOLD, true)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	foot.add_child(note)
	field_btn = UI.button("Field copy", func(): field_copy(), 170)
	field_btn.visible = false
	foot.add_child(field_btn)
	shop_btn = UI.button("Workshop", func(): workshop_requested.emit(), 170)
	foot.add_child(shop_btn)
	map_btn = UI.button("World Map", func(): map_requested.emit(), 170)
	foot.add_child(map_btn)
	go_btn = UI.button("Deploy", _go, 220)
	go_btn.theme_type_variation = "MainButton"     # (0.15) the one thing to do next
	foot.add_child(go_btn)


## Shows the dock for this campaign.
func open(c: Campaign, r: Roster) -> void:
	campaign = c
	roster = r
	choosing = false
	team_i = -1
	tab = "stockpile"
	_close_dialog()
	show_dock()


func dock() -> Dock:
	return campaign.dock


func _back() -> void:
	if dialog != null:
		return
	if choosing:
		choosing = false
		show_dock()
	else:
		closed.emit()


func _go() -> void:
	if campaign == null:
		return
	if campaign.deploy.active():
		map_requested.emit()
	elif not choosing:
		show_teams()
	else:
		leave()


func _close_dialog() -> void:
	if dialog != null:
		Motion.pop_out(dialog, dialog.get_meta("box", null))
		dialog = null


func _say(text: String, bad := false) -> void:
	note.text = text
	note.add_theme_color_override("font_color", UI.SOFT_RED if bad else UI.GOLD)


# ---------------------------------------------------------------- the dock itself
func show_dock() -> void:
	choosing = false
	_say(campaign.error if campaign.error != "" else campaign.note, campaign.error != "")
	# (0.15) a deployment just over: QM-7 has something to say about it
	var hist: Array = campaign.deploy.history
	if _seen_deployments >= 0 and hist.size() > _seen_deployments and not hist.is_empty():
		moment = "wipe" if hist[0].get("result") == "wipe" else "home"
	_seen_deployments = hist.size()
	show_tab(tab)


## One of the dock's tabs. (Deploy's list is show_teams.)
func show_tab(k: String) -> void:
	tab = k
	choosing = false
	for key in tabs:
		tabs[key].button_pressed = key == k
	tab_row.visible = true
	title.text = "The dock"
	back_btn.text = "Home"
	var out := campaign.deploy.active()
	go_btn.text = "Back to the team" if out else "Deploy"
	go_btn.disabled = false
	map_btn.visible = not out
	shop_btn.visible = true
	field_btn.visible = false
	var keep := list.scroll
	list.clear()
	_rows = []
	_list_of = []
	help_text = ""
	match k:
		"exchange": _exchange_rows()
		"recruit": _recruit_rows()
		"reclaim": _reclaim_rows()
		"bounties": _bounty_rows()
		"upgrades": _upgrade_rows()
		_: _stockpile_rows()
	if not campaign.world.exists():
		hint.text = "This export has no World Map. Export again from Companion 13.1 or later, put the zip in the game's folder, and tap Look again on the home screen."
		go_btn.disabled = true
		map_btn.visible = false
	_keeper_says(moment if moment != "" else ("out" if out and _said % 3 == 2 else k))
	moment = ""
	list.settle()
	list.scroll_by(keep)


## (0.15) QM-7's line for this moment: a tab, or what has just happened.
func _keeper_says(m: String) -> void:
	keeper_line.text = QM7.line(m, _said)
	_said += 1
	keeper.visible = true
	portrait.texture = Art.menu_piece("qm7")
	if _blink.is_inside_tree() and _blink.is_stopped():
		_blink.start(randf_range(2.5, 5.0))


## Its optics shut for a moment, now and then.
func _on_blink() -> void:
	if not is_visible_in_tree():
		_blink.start(4.0)
		return
	if portrait.texture == Art.menu_piece("qm7"):
		portrait.texture = Art.menu_piece("qm7_blink")
		_blink.start(0.14)
	else:
		portrait.texture = Art.menu_piece("qm7")
		_blink.start(randf_range(2.5, 5.0))


## (0.15) The "?": what the tab is for, in full.
func show_help() -> void:
	if dialog != null:
		return
	var name: String = "Deploy" if choosing else ({"stockpile": "Stockpile", "exchange": "Exchange", "recruit": "Recruit", "reclaim": "Reclaim", "bounties": "Bounties", "upgrades": "Upgrades"}.get(tab, "The dock"))
	dialog = Dialog.new(name, hint.text + ("\n\n" + help_text if help_text != "" else ""), ["Close"], UI.CYAN)
	add_child(dialog)
	dialog.chosen.connect(func(_k): _close_dialog())


func _closed_note() -> String:
	return " The dock is closed to changes while it is out: you can look, and buy or sell when it is home." if campaign.deploy.active() else ""


func _stockpile_rows() -> void:
	var out := campaign.deploy.active()
	hint.text = campaign.status_line() + (" The dock is closed to changes while it is out." if out else " Deploy sends a Strike Team onto the World Map; what it carries back is kept here.")
	_head("Stockpile", "", "Aether shards and components brought home. Troop parts pay for the copies of your designs as a Strike Team leaves; shards buy at the Exchange, and research blueprints in the Workshop.")
	for l in campaign.stock_lines():
		_row(l["text"], l.get("sub", ""), Color(l["colour"]), {}, false, "", str(l.get("icon", "")))
	var kept := kept_lines()
	if not kept.is_empty():
		_head("Also kept here", "", "Consumables and Prototypes you own, packed for a deployment as it leaves; pre-built copies, which join the next one.")
		for l in kept:
			_row(l["text"], l["sub"], UI.TEXT)
	var owned := campaign.progress.owned_lines()
	if owned.is_empty():
		_quiet("No blueprints or chassis found yet.", "Enemies, Loot Tiles, Locked Chests, Caches and POIs can all leave one; it is yours once the team that found it is home.", "Blueprints and chassis")
	else:
		_head("Blueprints and chassis", "%d found." % owned.size())
		for o in owned:
			_row(o["text"], o["kind"], UI.TEXT)
	var hist: Array = campaign.deploy.history
	if hist.is_empty():
		_quiet("No deployments yet.")
	else:
		_head("Deployments", "%d so far, the newest first." % hist.size())
		for e in hist:
			var bad: bool = e.get("result") == "wipe"
			_row(campaign.deploy.history_line(e), "", UI.SOFT_RED if bad else UI.PALE)
	_chips_row("Testing", "As the Companion's Dev Mode has them. Each asks first.",
		[["Restock now", ["testing", "restock"], UI.CYAN], ["Reach +1", ["testing", "reach"], UI.CYAN], ["Reset the dock", ["testing", "reset"], UI.SOFT_RED]])


## What the dock keeps for you: [{text, sub}].
func kept_lines() -> Array:
	var out := []
	var dk := dock()
	for n in Dock.js_keys(dk.inv["cards"]):
		var kind := dk.item_kind(n)
		out.append({"text": "%d × %s" % [dk.owned(n), n], "sub": ("Prototype" if kind == "prototype" else "Consumable") + " · owned"})
	for id in dk.waiting():
		var d = campaign.workshop.get_design(id)
		out.append({"text": "%d × %s" % [int(dk.waiting()[id]), str(d["name"]) if d != null else str(id)], "sub": "Pre-built copies · they join the next deployment"})
	return out


# ---------------------------------------------------------------- the Exchange
## A rarity's colour (Common to Mythic), as the loot tables have it.
static func rarity_colour(r: int) -> Color:
	var c = Loot.RARITIES[clampi(r, 0, Loot.RARITIES.size() - 1)].get("color")
	return Color(str(c)) if c != null and str(c) != "" else UI.TEXT


func _exchange_rows() -> void:
	var dk := dock()
	var t: Dictionary = dk.tables
	var st := dk.stock()
	dk.see_stock()                       # seeing one on the shelf names it
	var top := dk.reach_rarity()
	var bag := dk.stockpile()
	hint.text = "Everything is paid in Aether shards; you hold %d. Your reach is %s, so the rarest component the Exchange deals in is %s. It restocks after a deployment that sees new ground.%s" % [
		bag["shards"], ("Skull Level %d" % int(dk.state["reach"])) if int(dk.state["reach"]) > 0 else "none yet", Loot.RARITIES[top]["label"], _closed_note()]
	# components: a tile for each part type
	_head("Components", "You hold %d shards." % bag["shards"], "Commons of every part type, always, in any amount. Sold back at half price.")
	var comp := []
	for ty in Loot.TYPES:
		var held: Array = bag["parts"][ty["id"]]
		var have := []
		for r in 6:
			if held[r] > 0:
				have.append("%d %s" % [held[r], Loot.RARITIES[r]["label"]])
		var chips := [["Buy", ["buy_parts", ty["id"], 0, 1], UI.CYAN], ["Buy 5 · %s" % Scoring.text(float(t["price"][0]) * 5), ["buy_parts", ty["id"], 0, 5], UI.CYAN]]
		for r in 6:
			if held[r] > 0:
				chips.append(["Sell 1 %s · %d" % [Loot.RARITIES[r]["label"], int(floor(float(t["price"][r]) * float(t["sell"])))], ["sell_parts", ty["id"], r, 1], UI.PALE])
		comp.append({"text": str(ty["label"]), "sub": "You hold " + (" · ".join(have) if not have.is_empty() else "none"), "picture": Art.icon("part_" + str(ty["id"])),
			"price": Scoring.text(t["price"][0]), "chips": chips})
	_tiles(comp)
	# lots of rarer components
	if not st["lots"].is_empty():
		_head("Lots of rarer components", "", "A few at a time, never rarer than your reach. A lot sells out.")
		var lots := []
		for i in st["lots"].size():
			var lot: Dictionary = st["lots"][i]
			var left: int = lot["n"] - lot["bought"]
			var nm := campaign.loot.name_of(lot["type"], lot["rarity"])
			lots.append({"text": nm, "sub": "%s · %d left" % [Loot.RARITIES[lot["rarity"]]["label"], left], "picture": Art.icon("part_" + str(lot["type"])),
				"colour": rarity_colour(lot["rarity"]), "edge": rarity_colour(lot["rarity"]).darkened(0.3), "price": Scoring.text(t["price"][lot["rarity"]]),
				"chips": [["Buy", ["buy_parts", lot["type"], lot["rarity"], 1, i], UI.CYAN]] if left > 0 else [["Sold out", null, UI.DIM]]})
		_tiles(lots)
	# blueprints and chassis
	var offers: Array = st["bps"] + st["chs"]
	if offers.is_empty():
		_quiet("No blueprints or chassis on offer.", "They come from the pools of the Districts you've fought in: only the next level you're missing, or a chassis you don't have.", "Blueprints and chassis")
	else:
		_head("Blueprints and chassis", "", "From the pools of the Districts you've fought in: only the next level you're missing, or a chassis you don't have. Yours at once, in the Workshop.")
		var items := []
		for it in offers:
			var sold: bool = Rules.truthy(st["sold"].get(str(it)))
			var price = dk.bp_price(it)
			var can := campaign.progress.eligible(it)
			items.append({"text": campaign.progress.item_name(it, true), "sub": Progress.kind_word(it) + " · yours at once, in the Workshop", "picture": _item_picture(it),
				"edge": Color("#2789cd") if not str(it).begins_with("ch:") else UI.LINE, "price": Scoring.text(price) if (not sold and can) else null,
				"chips": [["Sold" if sold else ("Buy" if can else "You have it"), ["buy_item", it] if (not sold and can) else null, UI.CYAN if (not sold and can) else UI.DIM]]})
		_tiles(items)
	# Consumables and Prototypes
	var cons_about := ("Your export ticks none for the Exchange, so it carries all of them, at %d shards each, a few at a time. " % Dock.FALLBACK_PRICE if dk.carries_all() else "A few at a time, as the Companion's Dev Mode lists them. ") + "What you buy is yours, kept here, and packed for a deployment as it leaves."
	if st["items"].is_empty():
		_quiet("No Consumables or Prototypes on offer.", cons_about, "Consumables and Prototypes")
	else:
		_head("Consumables and Prototypes", "", cons_about)
		var cards := []
		for nm in st["items"]:
			var kind := dk.item_kind(nm)
			var card = dk.card_of(nm)
			cards.append({"text": str(nm), "sub": "%s · you own %d" % ["Prototype" if kind == "prototype" else "Consumable", dk.owned(nm)],
				"picture": _card_picture(card, kind), "px": Vector2(64, 45), "price": Scoring.text(dk.item_price(nm)), "chips": [["Buy", ["buy_card", nm, 1], UI.CYAN]]})
		_tiles(cards)
	# pre-built Troops
	if not dk.prebuilts().is_empty():
		_head("Pre-built Troops", "", "Finished designs you can't make yet. A copy joins your next deployment, on top of its Deck, and is gone when it ends; one lost in a fight is gone for the rest of it.")
		var pre := []
		for id in st["pre"]:
			var d = campaign.workshop.get_design(id)
			if d == null:
				continue
			var ch = campaign.workshop.chassis_of(d)
			pre.append({"text": str(d["name"]), "sub": "%s · power %d · %d waiting for the next deployment" % [str(ch.get("name")) if ch != null else "?", campaign.workshop.power(d), int(dk.waiting().get(id, 0))],
				"picture": Art.body_token(str(ch.get("bodyPlan", ""))) if ch != null else null, "price": str(dk.pre_cost(d)), "chips": [["Buy a copy", ["buy_pre", id, 1], UI.CYAN]]})
		_tiles(pre)
	# selling what you own
	var mine := Dock.js_keys(dk.inv["cards"])
	if not mine.is_empty():
		_head("Sell", "", "The Exchange buys Consumables and Prototypes back at half its price.")
		for nm in mine:
			var each = dk.item_price(nm)
			if not Rules.truthy(each):
				var c = dk.card_of(nm)
				each = Dock.num(c.get("price") if c != null else null, 10)
			_chips_row("%d × %s" % [dk.owned(nm), nm], "", [["Sell 1 · %d" % int(floor(float(each) * float(t["sell"]))), ["sell_card", nm, 1], UI.PALE]])


## (0.15) A blueprint or chassis on a tile: a chassis's body plan, standing; a
## blueprint as its sheet (the Aether parts' icon, until blueprints have art).
func _item_picture(it) -> Texture2D:
	var o = campaign.progress.parse_item(it)
	if o is Dictionary and o.get("kind") == "ch":
		var c = campaign.progress.chassis.get(o["id"])
		if c is Dictionary:
			var tok := Art.body_token(str(c.get("bodyPlan", "")))
			if tok != null:
				return tok
	return Art.icon("part_aether")


## (0.15) A Consumable or Prototype on a tile: its art, or the picture of its kind.
func _card_picture(card, kind: String) -> Texture2D:
	if card is Dictionary and roster != null:
		var f := roster.art_for(card)
		if f != null:
			return f
	return Art.card_standin("prototype" if kind == "prototype" else "consumable")


# ---------------------------------------------------------------- Recruit (0.25)
func _recruit_rows() -> void:
	var dk := dock()
	var st := dk.stock()
	hint.text = "Heroes to lead your Strike Teams, paid in Aether shards by their rarity; you hold %d. A Hero you recruit is yours until a team it goes out with is wiped out. The free Heroes are always yours, so a team can always leave. The roster changes when the Exchange restocks.%s" % [dk.stockpile()["shards"], _closed_note()]
	# teams that can't leave as they stand
	var stuck := []
	for t in StrikeTeams.load_all():
		var not_yet := dk.unowned(t.get("heroes", []).filter(func(n): return roster.card_named(str(n)) != null))
		if not not_yet.is_empty():
			stuck.append("%s (%s)" % [t.get("name", "?"), ", ".join(not_yet)])
	if not stuck.is_empty():
		_quiet("Can't deploy until their Heroes are recruited, or swapped for free ones: %s." % "; ".join(stuck))
	if st["heroes"].is_empty():
		_quiet("Nobody on offer.", "Heroes come from the Districts your teams have fought in, and those of no District.", "On offer")
	else:
		_head("On offer", "", "A few Heroes at a time, from the Districts your teams have fought in, and those of no District. Recruited, a Hero is yours until a team it goes out with is wiped out.")
		var offer := []
		for nm in st["heroes"]:
			var c = dk.card_of(nm)
			if c == null:
				continue
			var hired: bool = Rules.truthy(st["hired"].get(nm)) or dk.owns(nm)
			offer.append(_hero_tile(c, Scoring.text(dk.hero_price(nm)) if not hired else null,
				[["Recruited", null, UI.DIM]] if hired else [["Recruit", ["recruit", nm], UI.CYAN]]))
		_tiles(offer)
	var free := dk.hero_cards().filter(func(c): return dk.is_free(c["name"]))
	if free.is_empty():
		_quiet("No free Heroes.", "", "Free Heroes")
	else:
		_head("Free Heroes", "", "Always yours, never lost: a team led by them can always leave.")
		_tiles(free.map(func(c): return _hero_tile(c, null, [["Always yours", null, UI.DIM]])))
	var mine := dk.owned_heroes().filter(func(n): return dk.card_of(n) != null)
	if mine.is_empty():
		_quiet("No Heroes recruited yet.", "", "Recruited")
	else:
		_head("Recruited", "", "Yours until a team they go out with is wiped out.")
		_tiles(mine.map(func(n): return _hero_tile(dk.card_of(n), null, [["Yours", null, UI.DIM]])))


## A Hero on a tile: its token, its rarity, District and roles, its numbers and its abilities.
func _hero_tile(c: Dictionary, price, chips: Array) -> Dictionary:
	var r := Dock.hero_rarity(c)
	var d := Dock.hero_district(c)
	var stats: Dictionary = c.get("stats") if c.get("stats") is Dictionary else {}
	var nums := []
	for k in [["hp", "HP"], ["ac", "AC"], ["move", "Move"], ["slots", "Slots"], ["ldr", "Leadership"]]:
		if stats.get(k[0]) != null and str(stats[k[0]]) != "":
			nums.append("%s %s" % [k[1], str(stats[k[0]])])
	var abil := []
	for e in (c.get("entries") if c.get("entries") is Array else []):
		if e is Dictionary and str(e.get("name", "")) != "":
			abil.append(str(e["name"]))
	var roles: Array = c.get("combatRoles") if c.get("combatRoles") is Array else []
	var tok := roster.token_for(c) if roster != null else {}
	return {"text": str(c["name"]), "colour": rarity_colour(r), "edge": rarity_colour(r).darkened(0.3),
		"sub": "%s · %s%s\n%s%s" % [Loot.RARITIES[r]["label"], ("District " + d) if d != "" else "any District", (" · " + ", ".join(roles)) if not roles.is_empty() else "",
			" · ".join(nums), ("\n" + " · ".join(abil)) if not abil.is_empty() else ""],
		"picture": tok.get("texture"), "price": price, "chips": chips}


# ---------------------------------------------------------------- Reclaiming
func _reclaim_rows() -> void:
	var dk := dock()
	var t: Dictionary = dk.tables
	var top := dk.reach_rarity()
	var bag := dk.stockpile()
	hint.text = "Combine: %d of one rarity make 1 of the next, never rarer than your reach (%s). Swap: %d of one part type make 1 of another, same rarity.%s" % [int(t["reclaimUp"]), Loot.RARITIES[top]["label"], int(t["reclaimSwap"]), _closed_note()]
	var any := false
	for ty in Loot.TYPES:
		for r in 6:
			var n: int = bag["parts"][ty["id"]][r]
			if n <= 0:
				continue
			any = true
			var chips := []
			if r + 1 <= top:
				chips.append(["%d into 1 %s" % [int(t["reclaimUp"]), Loot.RARITIES[r + 1]["label"]], ["combine", ty["id"], r] if n >= int(t["reclaimUp"]) else null, UI.CYAN if n >= int(t["reclaimUp"]) else UI.DIM])
			for to in Loot.TYPES:
				if to["id"] != ty["id"]:
					chips.append(["%d into 1 %s" % [int(t["reclaimSwap"]), to["short"]], ["swap", ty["id"], to["id"], r] if n >= int(t["reclaimSwap"]) else null, UI.CYAN if n >= int(t["reclaimSwap"]) else UI.DIM])
			_chips_row("%d × %s" % [n, campaign.loot.name_of(ty["id"], r)], "%s · %s part" % [Loot.RARITIES[r]["label"], ty["short"]], chips, {}, "part_" + str(ty["id"]))
	if not any:
		_quiet("No components to reclaim yet: deployments bring them home, and the Exchange sells Commons.")


# ---------------------------------------------------------------- the Bounty Board
func _bounty_rows() -> void:
	var dk := dock()
	var t: Dictionary = dk.tables
	hint.text = "Beat one in a won fight on a deployment, or before an Emergency Exit, and get home: it pays shards and components, more the higher the Skull Level it fell at. A wipe loses the claim. The board changes when the Exchange restocks."
	var board := dk.bounties()
	if board.is_empty():
		_quiet("No bounties posted yet.", "The board names Enemies you've met in the Districts you've fought in, when the Exchange restocks.", "Bounties")
	for b in board:
		var kind := str(b.get("kind", "enemy"))
		var pay := "%s shards per Skull Level, and %d component%s" % [Scoring.text(t["bounty"]["shards"].get(kind, 0)), int(t["bounty"]["n"].get(kind, 0)), "" if int(t["bounty"]["n"].get(kind, 0)) == 1 else "s"]
		var where := ("District %s" % str(b["district"])) if str(b.get("district", "")) != "" else "any District"
		var sub := "%s · %s · pays %s" % [Dock.KIND_LABEL.get(kind, "Enemy"), where, pay]
		if Rules.truthy(b.get("claimed")):
			sub = "Paid at Skull %s: %s" % [str(b.get("skull", "?")), campaign.loot.text(b.get("paid"))]
		_row(str(b["name"]), sub, UI.DIM if Rules.truthy(b.get("claimed")) else UI.TEXT, {}, false, "Paid" if Rules.truthy(b.get("claimed")) else "")


# ---------------------------------------------------------------- upgrades
func _upgrade_rows() -> void:
	var dk := dock()
	var t: Dictionary = dk.tables
	hint.text = "Each has three levels, paid in shards and parts.%s" % _closed_note()
	for u in Dock.UPGRADES:
		var lv := dk.level(u["id"])
		var e: Array = t["effect"][u["id"]]
		var now := _effect_text(u["id"], dk.effect(u["id"]) if lv > 0 else null)
		var nc = dk.next_cost(u["id"])
		var chips := []
		if nc != null:
			var label := "Level %d · %s shards, %d %s %s parts" % [lv + 1, Scoring.text(nc["shards"]), int(nc["n"]), Loot.RARITIES[nc["rarity"]]["label"], str(nc["type"]).capitalize()]
			chips.append([label, ["upgrade", u["id"]], UI.CYAN])
		else:
			chips.append(["At its highest level", null, UI.DIM])
		_chips_row("%s · level %d of 3" % [u["name"], lv], "%s Now: %s. Next: %s." % [u["what"], now, _effect_text(u["id"], e[lv]) if lv < 3 else "—"], chips)


func _effect_text(id: String, v) -> String:
	var dk := dock()
	match id:
		"exchange": return ("+%s rare lot%s and pre-built%s on offer" % [Scoring.text(v), "" if Scoring.num(v) == 1.0 else "s", "" if Scoring.num(v) == 1.0 else "s"]) if v != null else "the usual stock"
		"starter": return ("%s free starter copies" % Scoring.text(v)) if v != null else ("%d free starter copies" % dk.starter_free())
		"insurance": return ("keep %s%% of a wiped haul" % Scoring.text(v)) if v != null else "a wipe keeps nothing"
		"scanner": return ("see %s steps away" % Scoring.text(v)) if v != null else "the team sees the tiles beside it"
	return str(v)


# ---------------------------------------------------------------- rows
## The lines the dock shows, top to bottom (for the tests).
func row_texts() -> Array:
	return _rows.map(func(r): return r["text"])


## A section's head: its name, and (0.15) a short line under it; what the
## section is for, at length, goes behind the "?".
func _head(text: String, sub: String, about := "") -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", 8)
	m.add_child(v)
	v.add_child(UI.label(text, 22, UI.CYAN))
	if sub != "":
		v.add_child(UI.label(sub, 15, UI.DIM, true))
	if about != "":
		help_text += ("\n\n" if help_text != "" else "") + text + ": " + about
	var e := {"head": true, "text": text, "row": m}
	_rows.append(e)
	_list_of.append(e)
	list.add_row(m)


## (0.15) A section with nothing in it: one quiet line, no head.
func _quiet(text: String, about := "", name := "") -> void:
	var l := UI.label(text, 15, UI.DIM, true)
	if about != "":
		help_text += ("\n\n" if help_text != "" else "") + (name + ": " if name != "" else "") + about
	var e := {"quiet": true, "text": text, "row": l}
	_rows.append(e)
	_list_of.append(e)
	list.add_row(l)


func _row(text: String, sub: String, colour: Color, what: Dictionary = {}, chosen := false, tag := "", icon_id := "") -> void:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 54 if what.is_empty() else 78)
	var sb := PixelBox.new()
	sb.bg_color = UI.PANEL_LIT if chosen else UI.PANEL
	sb.border_color = UI.CYAN if chosen else UI.LINE
	sb.set_border_width_all(3 if chosen else 1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12; sb.content_margin_right = 12; sb.content_margin_top = 6; sb.content_margin_bottom = 6
	row.add_theme_stylebox_override("panel", sb)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	row.add_child(hb)
	if icon_id != "":
		hb.add_child(UI.icon(icon_id, 32))
	var txt := VBoxContainer.new()
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	txt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	txt.add_theme_constant_override("separation", 2)
	hb.add_child(txt)
	var nl := UI.label(text, 18, colour, what.is_empty())
	nl.clip_text = not what.is_empty()
	txt.add_child(nl)
	if sub != "":
		var sl := UI.label(sub, 15, UI.DIM)
		sl.clip_text = true
		txt.add_child(sl)
	if tag != "":
		var tl := UI.label(tag, 16, UI.CYAN if chosen else UI.GOLD)
		tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(tl)
	var entry := what.duplicate()
	entry["text"] = text
	entry["row"] = row
	_rows.append(entry)
	_list_of.append(entry)
	list.add_row(row)


## A row with its text on the left and chips on the right: [[label, act (or null), colour]].
func _chips_row(text: String, sub: String, chips: Array, what: Dictionary = {}, icon_id := "") -> void:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 62)
	row.add_theme_stylebox_override("panel", UI.box(UI.PANEL, UI.LINE, 1, 6, 12))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	row.add_child(hb)
	if icon_id != "":
		hb.add_child(UI.icon(icon_id, 32))
	var txt := VBoxContainer.new()
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	txt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	txt.add_theme_constant_override("separation", 2)
	hb.add_child(txt)
	txt.add_child(UI.label(text, 18, UI.TEXT, true))
	if sub != "":
		txt.add_child(UI.label(sub, 15, UI.DIM, true))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	flow.alignment = FlowContainer.ALIGNMENT_END
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for c in chips:
		flow.add_child(UI.chip(str(c[0]), c[2], c[1], false, 15))
	hb.add_child(flow)
	var entry := what.duplicate()
	entry["text"] = text
	entry["row"] = row
	entry["acts"] = chips.filter(func(c): return c[1] != null).map(func(c): return c[1])
	_rows.append(entry)
	_list_of.append(entry)
	list.add_row(row)


## (0.15) Things for sale as tiles, side by side, wrapping: each its picture,
## its name, a line about it, a price tag in shards, and what can be done
## with it. tiles: [{text, sub, picture (Texture2D), px (its size on the
## tile), colour (its name's), price (or null), chips: [[label, act, colour]]}].
func _tiles(tiles: Array) -> void:
	var holder := HFlowContainer.new()
	holder.add_theme_constant_override("h_separation", 10)
	holder.add_theme_constant_override("v_separation", 10)
	var group := []
	for t in tiles:
		var tile := PanelContainer.new()
		tile.custom_minimum_size = Vector2(296, 0)
		tile.add_theme_stylebox_override("panel", UI.box(UI.PANEL, Color(t.get("edge", UI.LINE)), 1, 6, 10))
		holder.add_child(tile)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 6)
		tile.add_child(v)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 12)
		v.add_child(top)
		var pic := TextureRect.new()
		pic.texture = t.get("picture")
		var px: Vector2 = t.get("px", Vector2(48, 48))
		pic.custom_minimum_size = px
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		top.add_child(pic)
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.add_theme_constant_override("separation", 2)
		top.add_child(words)
		var name := UI.label(str(t["text"]), 18, Color(t.get("colour", UI.TEXT)), true)
		words.add_child(name)
		if str(t.get("sub", "")) != "":
			words.add_child(UI.label(str(t["sub"]), 15, UI.DIM, true))
		var bottom := HBoxContainer.new()
		bottom.add_theme_constant_override("separation", 8)
		v.add_child(bottom)
		if t.get("price") != null:
			var tag := PanelContainer.new()
			tag.add_theme_stylebox_override("panel", UI.box(Color("#271f1b"), UI.GOLD, 1, 2, 6))
			var th := HBoxContainer.new()
			th.add_theme_constant_override("separation", 4)
			tag.add_child(th)
			th.add_child(UI.icon("shards", 32))
			var pl := Look.title(str(t["price"]), UI.GOLD)
			pl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			th.add_child(pl)
			tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			bottom.add_child(tag)
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		flow.alignment = FlowContainer.ALIGNMENT_END
		flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for c in t.get("chips", []):
			flow.add_child(UI.chip(str(c[0]), c[2], c[1], false, 15))
		bottom.add_child(flow)
		var entry := {"text": str(t["text"]), "row": tile, "tile": true,
			"acts": t.get("chips", []).filter(func(c): return c[1] != null).map(func(c): return c[1])}
		_rows.append(entry)
		group.append(entry)
	_list_of.append(group)
	list.add_row(holder)


## Every tap a row offers now, as act() takes them (for the tests).
func offers() -> Array:
	var out := []
	for r in _rows:
		out.append_array(r.get("acts", []))
	return out


func _on_row(i: int, at: Vector2) -> void:
	if i < 0 or i >= list.rows().size() or dialog != null:
		return
	var what = UI.act_at(list.rows()[i], at)
	if what != null:
		act(what)
		return
	var e = _list_of[i] if i < _list_of.size() else null
	if choosing and e is Dictionary and e.has("team"):
		choose_team(e["team"])


# ---------------------------------------------------------------- what a tap does
## ["buy_parts", type, rarity, n, lot], ["sell_parts", type, rarity, n],
## ["buy_item", it], ["buy_card", name, n], ["sell_card", name, n],
## ["buy_pre", id, n], ["recruit", name], ["combine", type, rarity], ["swap", from, to, rarity],
## ["upgrade", id], ["testing", what], ["pack", name, by].
func act(what: Array) -> void:
	var dk := dock()
	var r := {}
	match what[0]:
		"buy_parts": r = dk.buy_parts(what[1], what[2], what[3], what[4] if what.size() > 4 else null)
		"sell_parts": r = dk.sell_parts(what[1], what[2], what[3])
		"buy_item": r = dk.buy_item(what[1])
		"buy_card": r = dk.buy_card(what[1], what[2])
		"sell_card": r = dk.sell_card(what[1], what[2])
		"buy_pre": r = dk.buy_pre(what[1], what[2])
		"recruit": r = dk.recruit(what[1])
		"combine": r = dk.combine(what[1], what[2], 1)
		"swap": r = dk.swap(what[1], what[2], what[3], 1)
		"upgrade": r = dk.upgrade(what[1])
		"testing":
			ask_testing(str(what[1]))
			return
		"pack":
			set_pack(str(what[1]), int(what[2]))
			return
	if r.get("ok"):
		campaign.save()
		_say(_done_text(what, r))
		moment = {"buy_parts": "bought", "buy_item": "bought", "buy_card": "bought", "buy_pre": "bought", "recruit": "recruited", "sell_parts": "sold", "sell_card": "sold",
			"combine": "made", "swap": "made", "upgrade": "upgraded"}.get(what[0], "")
	else:
		_say(str(r.get("why", "That can't be done")) + ".", true)
		moment = "refused"
	show_tab(tab)


func _done_text(what: Array, r: Dictionary) -> String:
	match what[0]:
		"buy_parts": return "Bought %d %s for %s shards." % [int(what[3]), campaign.loot.name_of(what[1], int(what[2])), Scoring.text(r["price"])]
		"sell_parts": return "Sold %d %s for %d shards." % [int(what[3]), campaign.loot.name_of(what[1], int(what[2])), r["gain"]]
		"buy_item": return "Bought %s %s for %s shards: it's yours in the Workshop." % [Progress.kind_word(what[1]).to_lower(), campaign.progress.item_name(what[1], true), Scoring.text(r["price"])]
		"buy_card": return "Bought %s for %s shards: it's kept here." % [what[1], Scoring.text(r["price"])]
		"sell_card": return "Sold %s for %d shards." % [what[1], r["gain"]]
		"buy_pre": return "Bought a copy for %d shards: it joins the next deployment." % r["price"]
		"recruit": return "%s recruited for %s shards: they can lead a Strike Team now." % [what[1], Scoring.text(r["price"])]
		"combine": return "Combined: 1 %s made." % Loot.RARITIES[int(what[2]) + 1]["label"]
		"swap": return "Swapped: 1 %s part made." % str(what[2])
		"upgrade": return "Upgraded to level %d." % r["level"]
	return "Done."


func ask_testing(which: String) -> void:
	var titles := {"restock": "Restock now?", "reach": "Reach +1?", "reset": "Reset the dock?"}
	var texts := {"restock": "The Exchange restocks and the Bounty Board changes, as after a deployment that saw new ground.",
		"reach": "Your reach goes up a Skull Level, as if a haul had come home from further out.",
		"reset": "Your reach, the upgrades, the Exchange's stock, the Bounty Board, and the Consumables, Prototypes and pre-built copies kept here are forgotten. The stockpile stays."}
	dialog = Dialog.new(titles.get(which, "Testing"), texts.get(which, ""), ["Yes", "Not now"], UI.SOFT_RED if which == "reset" else UI.CYAN)
	add_child(dialog)
	dialog.chosen.connect(func(k):
		_close_dialog()
		if k == 0:
			testing(which))


func testing(which: String) -> void:
	var dk := dock()
	match which:
		"restock":
			dk.restock_now()
			_say("The Exchange restocked; the Bounty Board changed.")
			moment = "restock"
		"reach":
			dk.reach_up()
			_say("Your reach is Skull Level %d." % int(dk.state["reach"]))
		"reset":
			dk.reset()
			_say("The dock is as it was at the start.")
	campaign.save()
	show_tab(tab)


# ---------------------------------------------------------------- sending a Strike Team out
func show_teams() -> void:
	choosing = true
	teams = StrikeTeams.load_all()
	if team_i >= teams.size():
		team_i = -1
	list.clear()
	_rows = []
	tab_row.visible = false
	title.text = "Deploy"
	back_btn.text = "Back"
	map_btn.visible = false
	shop_btn.visible = false
	go_btn.text = "Leave the dock"
	help_text = ""
	_keeper_says("deploy")
	_list_of = []
	hint.text = "Choose the Strike Team that goes out. Its Troops must be your designs, and each copy in its Deck is paid for in Troop parts as it leaves (the Frame Trooper's first %d free). A Hero who goes down sits out the rest of the deployment; a Troop that falls, and a Consumable that is used, are gone until the team is home. It can't be changed while it is out." % campaign.deploy.starter_free()
	if teams.is_empty():
		hint.text = "You have no Strike Teams yet. Go Home and build one under Strike Teams."
	for i in teams.size():
		var t: Dictionary = teams[i]
		var hs: Array = t["heroes"]
		var why := campaign.deploy.reasons_against(t)
		var tag := "Ready"
		if not why.is_empty():
			tag = "Field copy needed" if campaign.deploy.needs_field_copy(t) else "Can't go"
		var sub := "%s · Deck %d · Pouch %d · Level %d%s" % [(", ".join(hs)) if not hs.is_empty() else "No Hero", StrikeTeams.deck_count(t), StrikeTeams.pouch_count(t, roster), int(t["level"]),
			(" · %d Consumable%s" % [StrikeTeams.consumable_count(t, roster), "" if StrikeTeams.consumable_count(t, roster) == 1 else "s"]) if StrikeTeams.consumable_count(t, roster) > 0 else ""]
		_row(str(t["name"]), sub, UI.TEXT, {"team": i}, i == team_i, tag)
	if team_i >= 0:
		_pack_rows()
	list.settle()
	_refresh_go()


## The Pack: what the chosen team takes of what the dock keeps.
func _pack_rows() -> void:
	var dk := dock()
	var owned := Dock.js_keys(dk.inv["cards"])
	var t: Dictionary = teams[team_i]
	_head("Pack", ("What %s takes of what the dock keeps. Every packed Prototype joins each fight, and so does every packed Consumable; one used is gone. The rest comes home, unless the team is wiped out." % str(t["name"])) if not owned.is_empty()
		else "Nothing kept at the dock to pack. Consumables and Prototypes are bought at the Exchange.")
	for nm in owned:
		var on := int(pack.get(nm, 0))
		var have := dk.owned(nm)
		var kind := dk.item_kind(nm)
		_chips_row(str(nm), "%s · %d of %d packed" % ["Prototype" if kind == "prototype" else "Consumable", on, have],
			[["−", ["pack", nm, -1] if on > 0 else null, UI.TEXT if on > 0 else UI.DIM], ["+", ["pack", nm, 1] if on < have else null, UI.TEXT if on < have else UI.DIM]])


func set_pack(name: String, by: int) -> void:
	var n := clampi(int(pack.get(name, 0)) + by, 0, dock().owned(name))
	if n == 0:
		pack.erase(name)
	else:
		pack[name] = n
	var keep := list.scroll
	show_teams()
	list.scroll_by(keep)


## What a team's copies cost to send out, in a line: "3 × Frame Trooper, free · 2 × Lancer: 14 Common".
func plan_text(p: Dictionary) -> String:
	var bits := []
	for l in p["lines"]:
		var paid: int = l["copies"] - l["free"]
		bits.append("%d × %s%s" % [l["copies"], l["name"], (", free" if paid == 0 else (": %s%s" % [Workshop.cost_text(l["cost"]), (" (%d free)" % l["free"]) if l["free"] > 0 else ""]))])
	for l in p.get("pre", []):
		bits.append("%d × %s, pre-built" % [l["copies"], l["name"]])
	return " · ".join(bits) if not bits.is_empty() else "no Troops"


func _refresh_go() -> void:
	var t = teams[team_i] if team_i >= 0 and team_i < teams.size() else null
	var why: Array = campaign.deploy.reasons_against(t, pack) if t != null else ["Choose a Strike Team."]
	go_btn.disabled = not why.is_empty()
	field_btn.visible = t != null and campaign.deploy.needs_field_copy(t)
	if t == null:
		_say("")
	elif not why.is_empty():
		if field_btn.visible:
			# one sentence for the Troops a Field copy takes out, not one each
			why = why.filter(func(r): return not (" is a Forge Troop" in r or " is a design from your export" in r or " is a pre-built Troop" in r))
			why.push_front("Troops come only from the Workshop, and its Deck holds others (%s). Field copy makes a copy of it that can leave." % ", ".join(_not_designs(t)))
		_say(" ".join(why))
	else:
		var p := campaign.deploy.plan(t, pack)
		var packed := pack.keys().map(func(k): return ("%d × %s" % [int(pack[k]), k]) if int(pack[k]) > 1 else str(k))
		_say("%s is ready to leave. Its copies: %s.%s" % [str(t["name"]), plan_text(p), (" Packed: %s." % ", ".join(packed)) if not packed.is_empty() else ""])


## The Troops in a team's Deck that aren't your designs: "Test Drone ×3".
func _not_designs(t: Dictionary) -> Array:
	var out := []
	for n in t.get("deck", {}):
		var c = campaign.roster.card_named(str(n)) if campaign.roster != null else null
		var k := StrikeTeams.copies(t, str(n))
		if c != null and Roster.type_of(c) == "troop" and c.get("_src") != "workshop" and k > 0:
			out.append(str(n) + ((" ×%d" % k) if k > 1 else ""))
	return out


func choose_team(i: int) -> void:
	if i != team_i and i >= 0 and i < teams.size():
		pack = campaign.deploy.default_pack(teams[i])
	team_i = i
	var keep := list.scroll
	show_teams()
	list.scroll_by(keep)


## A copy of the chosen team that can leave: its other Troops out, the
## starter's free copies in. It is saved with your teams, and chosen.
func field_copy() -> void:
	if team_i < 0 or team_i >= teams.size():
		return
	var t: Dictionary = teams[team_i]
	var copy := campaign.deploy.field_copy(t, StrikeTeams.free_name(teams, str(t["name"]) + " · field"))
	teams.append(copy)
	StrikeTeams.save_all(teams)
	team_i = teams.size() - 1
	pack = campaign.deploy.default_pack(copy)
	show_teams()
	list.scroll_by(1.0e6)


## The chosen Strike Team leaves the dock, with what is packed.
func leave() -> void:
	if team_i < 0 or team_i >= teams.size():
		return
	var r := campaign.deploy.start(teams[team_i], pack)
	if not r["ok"]:
		_say(" ".join(r.get("reasons", [])), true)
		return
	campaign.note = ""
	campaign.save()
	choosing = false
	pack = {}
	deployed.emit()
