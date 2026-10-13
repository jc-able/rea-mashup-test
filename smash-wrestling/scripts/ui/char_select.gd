class_name CharSelect
extends Control
## Character select: pick your Smash fighter, then the opponent; difficulty and entrances options (custom UI).

var picking := "p1"
var buttons := {}
var info: Label
var start_btn: Button
var diff_btn: Button
var ent_btn: Button
var arena_btn: Button


func _fit() -> void:
	# the screen's parent is a plain Node: size the Control to the viewport explicitly
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_fit()
	get_viewport().size_changed.connect(_fit)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.09)
	add_child(bg)
	var title := Label.new()
	title.text = "SELECT YOUR SUPERSTAR"
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	title.position = Vector2(60, 30)
	add_child(title)
	info = Label.new()
	info.add_theme_font_size_override("font_size", 24)
	info.position = Vector2(64, 100)
	info.size = Vector2(1500, 70)
	add_child(info)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.position = Vector2(60, 180)
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	add_child(grid)
	var first: Button
	for c in Game.roster:
		var b := Button.new()
		b.custom_minimum_size = Vector2(230, 250)
		b.text = ""
		b.focus_mode = Control.FOCUS_ALL
		var vb := VBoxContainer.new()
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.add_child(vb)
		var port := "res://assets/portraits/%s.png" % c["kind"]
		if ResourceLoader.exists(port):
			var tr := TextureRect.new()
			tr.texture = load(port)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.custom_minimum_size = Vector2(220, 180)
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vb.add_child(tr)
		else:
			var cr := ColorRect.new()
			cr.color = Color(c["color"])
			cr.custom_minimum_size = Vector2(220, 180)
			cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vb.add_child(cr)
		var nl := Label.new()
		nl.text = c["name"]
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.add_theme_font_size_override("font_size", 22)
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(nl)
		var tl := Label.new()
		tl.text = "as " + String(c["template_name"])
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tl.add_theme_font_size_override("font_size", 15)
		tl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
		tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(tl)
		b.pressed.connect(_pick.bind(c["kind"]))
		b.focus_entered.connect(_hover.bind(c["kind"]))
		grid.add_child(b)
		buttons[c["kind"]] = b
		if first == null:
			first = b
	var hb := HBoxContainer.new()
	hb.position = Vector2(60, 760)
	hb.add_theme_constant_override("separation", 20)
	add_child(hb)
	diff_btn = _btn(hb, "", _toggle_diff)
	ent_btn = _btn(hb, "", _toggle_ent)
	arena_btn = _btn(hb, "", _toggle_arena)
	start_btn = _btn(hb, "START MATCH", _start)
	_btn(hb, "BACK", func(): Game.goto_title())
	_refresh()
	first.grab_focus.call_deferred()


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if picking == "p1":
			Game.goto_title()
		else:
			picking = "p1"
			_refresh()
			buttons[Game.sel["p1"]].grab_focus()


func _btn(parent: Node, t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", 24)
	b.custom_minimum_size = Vector2(260, 56)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _hover(kind: String) -> void:
	var c: Dictionary = Game.def_of(kind)
	info.text = "%s  -  moveset & entrance of SvR 2011's %s (%s)" % [c["name"], c["template_name"], c["why"]]


func _pick(kind: String) -> void:
	if picking == "p1":
		Game.sel["p1"] = kind
		picking = "p2"
	else:
		Game.sel["p2"] = kind
		picking = "done"
		start_btn.grab_focus()
	_refresh()


func _toggle_diff() -> void:
	Game.sel["difficulty"] = (int(Game.sel["difficulty"]) + 1) % 3
	_refresh()


func _toggle_arena() -> void:
	var keys := ["smackdown", "raw", "wrestlemania26"]
	Game.sel["arena"] = keys[(keys.find(String(Game.sel.get("arena", "smackdown"))) + 1) % keys.size()]
	_refresh()


func _toggle_ent() -> void:
	Game.sel["entrances"] = not bool(Game.sel["entrances"])
	_refresh()


func _start() -> void:
	if picking == "p1":
		_pick(Game.sel["p1"])
		return
	Game.start_match()


func _refresh() -> void:
	var who := "PLAYER 1" if not Game.sel["p1_cpu"] else "CPU 1"
	var step := ("Pick %s" % who) if picking == "p1" else ("Pick the opponent (CPU)" if picking == "p2" else "Ready!")
	var p1: Dictionary = Game.def_of(Game.sel["p1"])
	var p2: Dictionary = Game.def_of(Game.sel["p2"])
	info.text = "%s     %s  vs  %s" % [step, p1["name"], p2["name"]]
	diff_btn.text = "CPU: " + ["EASY", "NORMAL", "HARD"][int(Game.sel["difficulty"])]
	ent_btn.text = "ENTRANCES: " + ("ON" if Game.sel["entrances"] else "OFF")
	arena_btn.text = "ARENA: " + {"smackdown": "SMACKDOWN", "raw": "RAW", "wrestlemania26": "WM XXVI"}.get(String(Game.sel.get("arena", "smackdown")), "SMACKDOWN")
	for k in buttons:
		var b: Button = buttons[k]
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.12, 0.12, 0.16)
		if k == Game.sel["p1"]:
			sb.border_color = Color(0.2, 0.6, 1)
			sb.set_border_width_all(5)
		elif k == Game.sel["p2"] and picking != "p1":
			sb.border_color = Color(1, 0.25, 0.2)
			sb.set_border_width_all(5)
		b.add_theme_stylebox_override("normal", sb)
