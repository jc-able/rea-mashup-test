class_name TitleScreen
extends Control
## Title / main menu (custom).

var _help: Label


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
	bg.color = Color(0.04, 0.04, 0.07)
	add_child(bg)
	var stripe := ColorRect.new()
	stripe.set_anchors_preset(Control.PRESET_TOP_WIDE)
	stripe.size = Vector2(4000, 6)
	stripe.position = Vector2(0, 250)
	stripe.color = Color(0.85, 0.1, 0.1)
	add_child(stripe)
	var title := _label("SMASH WRESTLING 64", 92, Color(1, 0.85, 0.2))
	add_child(title)
	title.offset_top = 70
	title.offset_bottom = 180
	var sub := _label("Super Smash Bros. 64 fighters  x  WWE SmackDown vs. Raw 2011 wrestling", 28, Color(0.9, 0.9, 0.95))
	add_child(sub)
	sub.offset_top = 190
	sub.offset_bottom = 240
	var strip := HBoxContainer.new()
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 6)
	add_child(strip)
	strip.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	strip.offset_top = 222
	strip.offset_bottom = 322
	for c in Game.roster:
		var port := "res://assets/portraits/%s.png" % c["kind"]
		if ResourceLoader.exists(port):
			var tr := TextureRect.new()
			tr.texture = load(port)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			tr.custom_minimum_size = Vector2(96, 96)
			strip.add_child(tr)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 330
	add_child(center)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(460, 300)
	vb.add_theme_constant_override("separation", 14)
	center.add_child(vb)
	var items := [["EXHIBITION  -  1P vs CPU", "1p"], ["CPU vs CPU  (watch)", "cpu"], ["CONTROLS", "controls"], ["QUIT", "quit"]]
	var first: Button
	for it in items:
		var b := Button.new()
		b.text = it[0]
		b.add_theme_font_size_override("font_size", 28)
		b.custom_minimum_size = Vector2(0, 56)
		b.pressed.connect(_on.bind(it[1]))
		vb.add_child(b)
		if first == null:
			first = b
	first.grab_focus.call_deferred()
	_help = _label("", 21, Color(0.9, 0.9, 0.9))
	_help.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_help.offset_top = 560
	_help.visible = false
	add_child(_help)
	var foot := _label("Fan-made research/benchmark build. Smash 64 assets read from the user's ROM; SvR 2011 data from the user's game files.  Enter / J / Space = select", 16, Color(0.6, 0.6, 0.65))
	add_child(foot)
	foot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	foot.offset_top = -44


func _label(t: String, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	l.custom_minimum_size = Vector2(0, sz + 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 6)
	return l


func _on(id: String) -> void:
	match id:
		"1p":
			Game.sel["p1_cpu"] = false
			Game.sel["p2_cpu"] = true
			Game.goto_select()
		"cpu":
			Game.sel["p1_cpu"] = true
			Game.sel["p2_cpu"] = true
			Game.goto_select()
		"controls":
			_help.visible = not _help.visible
			_help.text = "\n".join(Controls.help_lines())
		"quit":
			get_tree().quit()
