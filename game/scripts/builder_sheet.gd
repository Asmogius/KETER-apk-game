## The keyword builder on the screen: one effect, built a step at a time with
## taps. builder.gd decides what is offered and what each tap does; this draws
## it and passes the taps on.
##
## The sentence being built reads across the top, in its keywords' colours,
## with what it is worth under it. Each step offers its choices as big rows
## or as chips; a number has a − and a + (and stops at what your blueprint's
## level allows); the review shows each part with Change beside it, and what
## is wrong, if anything is. Back, Skip, Next and Insert are along the bottom.
class_name BuilderSheet
extends Control

signal done(text: String)
signal cancelled

var b := Builder.new()
var head: Label
var step_label: Label
var sentence: RichTextLabel
var power: Label
var title: Label
var list: TouchList
var back_btn: Button
var skip_btn: Button
var next_btn: Button
var insert_btn: Button
var close_btn: Button
var _rows: Array = []


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.7)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 70)
	for side in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 16)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(m)
	var panel := PanelContainer.new()
	set_meta("box", panel)               # (0.12) what pops open and shut
	panel.add_theme_stylebox_override("panel", UI.box(Color("#171819"), Color("#3e4246"), 1, 10, 18))
	m.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	col.add_child(top)
	head = UI.label("Build an effect", 22, UI.CYAN)
	top.add_child(head)
	step_label = UI.label("", 16, UI.DIM)
	step_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	step_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(step_label)
	close_btn = UI.button("Close", func(): act(["kb", "x"]), 120)
	close_btn.custom_minimum_size.y = 50
	top.add_child(close_btn)
	var sp := PanelContainer.new()
	sp.add_theme_stylebox_override("panel", UI.box(Color("#14121d"), Color("#2c3b39"), 1, 6, 12))
	col.add_child(sp)
	sentence = RichTextLabel.new()
	sentence.bbcode_enabled = true
	sentence.fit_content = true
	sentence.scroll_active = false
	sentence.custom_minimum_size = Vector2(0, 34)
	sentence.add_theme_font_size_override("normal_font_size", Look.fs(20))
	sentence.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sp.add_child(sentence)
	power = UI.label("", 15, UI.DIM, true)
	col.add_child(power)
	title = UI.label("", 22, UI.TEXT)
	col.add_child(title)
	list = TouchList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.row_tapped.connect(_on_row)
	col.add_child(list)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	col.add_child(foot)
	back_btn = UI.button("Back", func(): act(["kb", "back"]), 140)
	foot.add_child(back_btn)
	skip_btn = UI.button("Skip", func(): act(["kb", "skip"]), 140)
	foot.add_child(skip_btn)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(gap)
	next_btn = UI.button("Next", func(): act(["kb", "next"]), 180)
	foot.add_child(next_btn)
	insert_btn = UI.button("Insert", func(): act(["kb", "insert"]), 180)
	insert_btn.add_theme_color_override("font_color", UI.CYAN)
	foot.add_child(insert_btn)


## Opens on an ability. o: what Builder.begin takes.
func open(o: Dictionary) -> void:
	b.begin(o)
	refresh()


# ---------------------------------------------------------------- drawing
static func _bb(text: String) -> String:
	return text.replace("[", "[lb]")


## A marked sentence, in its keywords' colours.
static func coloured(text: String) -> String:
	if text == "":
		return "[color=#6d838d]Your effect will appear here as you build it.[/color]"
	var out := ""
	for r in Builder.runs(text):
		if r["kw"] and r.get("colour") != null:
			out += "[color=%s]%s[/color]" % [str(r["colour"]), _bb(UI.show(str(r["t"])))]
		else:
			out += _bb(UI.show(str(r["t"])))
	return out


func refresh() -> void:
	var v := b.view()
	head.text = v["head"]
	step_label.text = v["step"]
	sentence.text = coloured(v["sentence"])
	power.text = "   ".join(b.power_texts(v["sentence"]))
	title.text = v["title"]
	back_btn.disabled = not v["back"]
	skip_btn.visible = v["skip"]
	next_btn.visible = v["next"]["shown"]
	next_btn.disabled = not v["next"]["enabled"]
	insert_btn.visible = v["insert"]["shown"]
	insert_btn.text = v["insert"]["label"]
	insert_btn.disabled = not v["insert"]["enabled"]
	var keep := list.scroll if b.st.get("param") == null else 0.0
	list.clear()
	_rows = []
	var flow: HFlowContainer = null
	for it in v["body"]:
		var chipish: bool = it["t"] == "chip" or it["t"] == "drop"
		if chipish:
			if flow == null:
				flow = HFlowContainer.new()
				flow.add_theme_constant_override("h_separation", 10)
				flow.add_theme_constant_override("v_separation", 10)
				_add(flow)
			if it["t"] == "chip":
				flow.add_child(UI.chip(it["label"], Color(it["colour"]), ["kb", it["key"]]))
			else:
				flow.add_child(UI.chip(it["label"] + "  ×", Color(it["colour"]), ["drop", it["i"]], true))
			continue
		flow = null
		match it["t"]:
			"note":
				_add(UI.label(UI.show(it["text"]), 16, UI.PALE, true))
			"group":
				var g := UI.label(str(it["text"]).to_upper(), 14, UI.DIM)
				_add(g)
			"opt":
				_add(_opt_row(it))
			"num":
				_add(_num_row(it))
			"select":
				for c in it["options"]:
					_add(_opt_row({"key": "", "label": c, "desc": "", "on": c == it["value"], "colour": UI.TEXT.to_html()}, ["card", c]))
			"check":
				_add(_opt_row({"key": "", "label": ("•  " if it["on"] else "  ") + it["text"], "desc": "", "on": it["on"], "colour": UI.TEXT.to_html()}, ["adj", not it["on"]]))
			"button":
				var bt := UI.chip(it["label"], UI.CYAN if it["primary"] else UI.PALE, ["kb", it["key"]], it["primary"], 19)
				var hold := HBoxContainer.new()
				hold.add_child(bt)
				_add(hold)
			"row":
				_add(_review_row(it))
			"bad":
				_add(UI.label("• " + "\n• ".join(it["lines"]), 17, UI.SOFT_RED, true))
	list.settle()           # (the chips went in after their row)
	list.scroll_by(keep)


func _add(c: Control) -> void:
	_rows.append(c)
	list.add_row(c)


func _opt_row(it: Dictionary, what = null) -> Control:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 58)
	row.add_theme_stylebox_override("panel", UI.box(UI.PANEL_LIT if it["on"] else Color("#2c3438"), UI.CYAN if it["on"] else Color("#2c3b39"), 2 if it["on"] else 1, 6, 14))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	row.add_child(v)
	v.add_child(UI.label(UI.show(str(it["label"])), 19, Color(it["colour"])))
	if str(it.get("desc", "")) != "":
		v.add_child(UI.label(UI.show(str(it["desc"])), 15, UI.DIM, true))
	row.set_meta("act", what if what != null else ["kb", it["key"]])
	return row


func _num_row(it: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var minus := UI.chip("  −  ", UI.TEXT, ["step", -1], false, 26)
	row.add_child(minus)
	var val := UI.label(str(it["value"]), 30, UI.CYAN)
	val.custom_minimum_size = Vector2(70, 0)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(val)
	row.add_child(UI.chip("  +  ", UI.TEXT, ["step", 1], false, 26))
	var pp = b.st.get("param")
	var most = b.most_of(pp["name"]) if pp != null else null
	if most != null:
		var note := UI.label("Your blueprint allows up to %d." % most, 15, UI.GOLD)
		note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(note)
	return row


func _review_row(it: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", UI.box(Color("#171819"), Color("#282c3c"), 1, 6, 10))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	row.add_child(h)
	var l := UI.label(it["label"], 15, UI.DIM)
	l.custom_minimum_size = Vector2(110, 0)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	var t := UI.label(UI.show(it["shown"]), 18, UI.DIM if it["dim"] else UI.TEXT, true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(t)
	h.add_child(UI.chip("Change", UI.CYAN, ["edit", it["step"]]))
	return row


# ---------------------------------------------------------------- taps
func _on_row(i: int, at: Vector2) -> void:
	if i < 0 or i >= _rows.size():
		return
	var what = UI.act_at(_rows[i], at)
	if what != null:
		act(what)


## Does what a tap asks: ["kb", key], ["step", n], ["drop", i], ["edit", step],
## ["card", name], ["adj", on]. (The tests send these too.)
func act(what: Array) -> void:
	match what[0]:
		"kb":
			var k := str(what[1])
			if k == "x": b.close()
			elif k == "back": b.back()
			elif k == "skip": b.skip()
			elif k == "next":
				if b.can_next():
					b.next()
			elif k == "insert": b.insert()
			elif k.begins_with("pv:"): b.param_pick(k.substr(3))
			else: b.pick(k)
		"step": b.step(int(what[1]))
		"drop": b.drop(int(what[1]))
		"edit": b.edit(str(what[1]))
		"card": b.set_card(str(what[1]))
		"adj": b.set_adjacent(bool(what[1]))
	if not b.open:
		var text := b.result
		var gave_up := b.cancelled
		b.release()
		if gave_up:
			cancelled.emit()
		else:
			done.emit(text)
		return
	refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		b.release()


## Every tap the sheet offers now, as act() takes them: for the tests.
func offers() -> Array:
	var out := []
	for r in _rows:
		var stack: Array = [r]
		while not stack.is_empty():
			var c = stack.pop_front()
			if c is Control and c.has_meta("act"):
				out.append(c.get_meta("act"))
			for k in c.get_children():
				stack.append(k)
	if not back_btn.disabled:
		out.append(["kb", "back"])
	if skip_btn.visible:
		out.append(["kb", "skip"])
	if next_btn.visible and not next_btn.disabled:
		out.append(["kb", "next"])
	if insert_btn.visible and not insert_btn.disabled:
		out.append(["kb", "insert"])
	return out


## (0.12) It pops open.
func _ready() -> void:
	Motion.pop_in(get_meta("box"))
