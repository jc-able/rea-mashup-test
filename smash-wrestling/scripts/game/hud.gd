class_name Hud
extends CanvasLayer
## Match HUD (custom layout in the spirit of SvR 2011: name plates, momentum meters with Signature/Finisher
## states, body-damage indicator, referee counts, kick-out and submission meters, reversal prompt, results).

var m: Match
var root: Control
var panels: Array = []
var center_label: Label
var count_label: Label
var timer_label: Label
var countout_label: Label
var move_label: Label
var reversal_label: Label
var kick_box: Control
var kick_bar: ProgressBar
var kick_label: Label
var sub_box: Control
var sub_bar: ProgressBar
var results_box: PanelContainer
var pause_box: PanelContainer
var help_label: Label
var lower_label: Label
var _announce_t := 0.0
var _count_t := 0.0
var _rev_t := 0.0
var _move_t := 0.0
var _kick_target: Wrestler
var _flash := [0.0, 0.0]


func setup(match_: Match) -> void:
	m = match_
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	for i in 2:
		panels.append(_make_panel(i))
	center_label = _label(54, Color.WHITE)
	center_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	center_label.position = Vector2(-600, 150)
	center_label.size = Vector2(1200, 80)
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(center_label)
	count_label = _label(150, Color(1, 0.95, 0.4))
	count_label.set_anchors_preset(Control.PRESET_CENTER)
	count_label.position = Vector2(-200, -160)
	count_label.size = Vector2(400, 200)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(count_label)
	timer_label = _label(26, Color(0.9, 0.9, 0.9))
	timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	timer_label.position = Vector2(-100, 14)
	timer_label.size = Vector2(200, 40)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(timer_label)
	countout_label = _label(34, Color(1, 0.6, 0.3))
	countout_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	countout_label.position = Vector2(-300, 56)
	countout_label.size = Vector2(600, 50)
	countout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(countout_label)
	move_label = _label(30, Color(1, 1, 1))
	move_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	move_label.position = Vector2(-500, -262)
	move_label.size = Vector2(1000, 44)
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(move_label)
	reversal_label = _label(40, Color(0.3, 1, 0.4))
	reversal_label.set_anchors_preset(Control.PRESET_CENTER)
	reversal_label.position = Vector2(-300, 60)
	reversal_label.size = Vector2(600, 60)
	reversal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reversal_label.text = "REVERSE!  [I] / [RT]"
	reversal_label.visible = false
	root.add_child(reversal_label)
	_make_kick_box()
	_make_sub_box()
	lower_label = _label(34, Color.WHITE)
	lower_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	lower_label.position = Vector2(40, -110)
	lower_label.size = Vector2(1400, 60)
	root.add_child(lower_label)
	help_label = _label(17, Color(0.85, 0.85, 0.85))
	help_label.position = Vector2(16, 14)
	help_label.size = Vector2(620, 300)
	help_label.text = "F1: controls"
	root.add_child(help_label)
	set_visible_match(false)


func _label(sz: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", maxi(4, sz / 8))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _make_panel(i: int) -> Dictionary:
	var w: Wrestler = m.wrestlers[i]
	var box := Control.new()
	box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT if i == 0 else Control.PRESET_BOTTOM_RIGHT)
	box.position = Vector2(24, -150) if i == 0 else Vector2(-544, -150)
	box.size = Vector2(520, 130)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.size = Vector2(520, 130)
	box.add_child(bg)
	var strip := ColorRect.new()
	strip.color = w.color
	strip.size = Vector2(8, 130)
	strip.position = Vector2(0 if i == 0 else 512, 0)
	box.add_child(strip)
	var name_l := _label(32, Color.WHITE)
	name_l.text = w.display_name.to_upper() + ("  (CPU)" if w.is_cpu else "  (P1)")
	name_l.position = Vector2(20, 4)
	box.add_child(name_l)
	var tmpl := _label(15, Color(0.75, 0.75, 0.75))
	tmpl.text = "moves & entrance from SvR 2011: " + String(Game.def_of(w.kind).get("template_name", ""))
	tmpl.position = Vector2(22, 44)
	box.add_child(tmpl)
	var mbar := ProgressBar.new()
	mbar.min_value = 0
	mbar.max_value = 100
	mbar.show_percentage = false
	mbar.position = Vector2(20, 72)
	mbar.size = Vector2(330, 22)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.2, 0.6, 1.0)
	mbar.add_theme_stylebox_override("fill", fill)
	var bgs := StyleBoxFlat.new()
	bgs.bg_color = Color(0.15, 0.15, 0.18)
	mbar.add_theme_stylebox_override("background", bgs)
	box.add_child(mbar)
	var mlab := _label(18, Color(1, 0.9, 0.3))
	mlab.position = Vector2(22, 98)
	box.add_child(mlab)
	# body damage indicator (head / arms / body / legs)
	var body := Control.new()
	body.position = Vector2(380, 18)
	box.add_child(body)
	var parts := {}
	var defs := {"head": Rect2(48, 0, 26, 24), "body": Rect2(42, 28, 38, 42), "arms": Rect2(16, 28, 22, 42),
		"arms2": Rect2(84, 28, 22, 42), "legs": Rect2(44, 74, 34, 36)}
	for k in defs:
		var r := ColorRect.new()
		r.position = defs[k].position
		r.size = defs[k].size
		r.color = Color(0.3, 0.8, 0.3)
		body.add_child(r)
		parts[k] = r
	return {"box": box, "bar": mbar, "fill": fill, "mlab": mlab, "parts": parts}


func _make_kick_box() -> void:
	kick_box = Control.new()
	kick_box.set_anchors_preset(Control.PRESET_CENTER)
	kick_box.position = Vector2(-260, 140)
	kick_box.size = Vector2(520, 70)
	kick_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(kick_box)
	kick_label = _label(26, Color(1, 1, 1))
	kick_label.text = "KICK OUT!  mash J / K / L / Space  (A B X Y)"
	kick_label.position = Vector2(0, 0)
	kick_box.add_child(kick_label)
	kick_bar = ProgressBar.new()
	kick_bar.position = Vector2(0, 38)
	kick_bar.size = Vector2(520, 24)
	kick_bar.show_percentage = false
	var f := StyleBoxFlat.new()
	f.bg_color = Color(0.3, 1.0, 0.4)
	kick_bar.add_theme_stylebox_override("fill", f)
	kick_box.add_child(kick_bar)
	kick_box.visible = false


func _make_sub_box() -> void:
	sub_box = Control.new()
	sub_box.set_anchors_preset(Control.PRESET_CENTER)
	sub_box.position = Vector2(-300, 140)
	sub_box.size = Vector2(600, 70)
	sub_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(sub_box)
	var l := _label(24, Color.WHITE)
	l.text = "SUBMISSION: mash to escape / apply pressure"
	sub_box.add_child(l)
	sub_bar = ProgressBar.new()
	sub_bar.position = Vector2(0, 36)
	sub_bar.size = Vector2(600, 26)
	sub_bar.show_percentage = false
	sub_bar.max_value = 1.0
	var f := StyleBoxFlat.new()
	f.bg_color = Color(1.0, 0.3, 0.2)
	sub_bar.add_theme_stylebox_override("fill", f)
	sub_box.add_child(sub_bar)
	sub_box.visible = false


func set_visible_match(v: bool) -> void:
	for p in panels:
		p["box"].visible = v
	timer_label.visible = v
	help_label.visible = v


func update_hud(dt: float) -> void:
	if Input.is_key_pressed(KEY_F1):
		help_label.text = "\n".join(Controls.help_lines())
	else:
		help_label.text = "F1: controls"
	for i in 2:
		var w: Wrestler = m.wrestlers[i]
		var p: Dictionary = panels[i]
		p["bar"].value = w.momentum
		var t := Time.get_ticks_msec() * 0.008
		match w.momentum_state:
			"signature":
				p["fill"].bg_color = Color(1, 0.75, 0.1).lerp(Color(1, 1, 0.6), 0.5 + 0.5 * sin(t))
				p["mlab"].text = "SIGNATURE READY  [O] / [Y]"
			"finisher":
				p["fill"].bg_color = Color(1, 0.2, 0.15).lerp(Color(1, 0.7, 0.6), 0.5 + 0.5 * sin(t * 1.5))
				p["mlab"].text = "FINISHER READY  [O] / [Y]"
			_:
				p["fill"].bg_color = Color(0.2, 0.6, 1.0)
				p["mlab"].text = "MOMENTUM"
		for k in p["parts"]:
			var region: String = "arms" if k == "arms2" else k
			var d: float = w.damage[region]
			var c := Color(0.3, 0.8, 0.3).lerp(Color(1, 0.85, 0.1), clampf(d * 2.0, 0, 1)).lerp(Color(0.95, 0.1, 0.1), clampf(d * 2.0 - 1.0, 0, 1))
			if _flash[i] > 0.0:
				c = c.lerp(Color.WHITE, _flash[i])
			p["parts"][k].color = c
		_flash[i] = maxf(_flash[i] - dt * 3.0, 0.0)
	timer_label.text = "%d:%02d" % [int(m.match_time) / 60, int(m.match_time) % 60]
	if _announce_t > 0.0:
		_announce_t -= dt
		if _announce_t <= 0.0:
			center_label.text = ""
	if _count_t > 0.0:
		_count_t -= dt
		count_label.modulate.a = clampf(_count_t * 2.0, 0, 1)
		if _count_t <= 0.0:
			count_label.text = ""
	if _rev_t > 0.0:
		_rev_t -= dt
		reversal_label.visible = _rev_t > 0.0
		reversal_label.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.03)
	if _move_t > 0.0:
		_move_t -= dt
		if _move_t <= 0.0:
			move_label.text = ""
	if kick_box.visible and _kick_target:
		kick_bar.max_value = _kick_target.kickout_needed()
		kick_bar.value = _kick_target.kickout_progress


func lower_third(text: String, col: Color, font_size := 34) -> void:
	lower_label.add_theme_font_size_override("font_size", font_size)
	# sit above the name plates when they are shown
	var above: bool = panels.size() > 0 and panels[0]["box"].visible
	lower_label.offset_top = -200.0 if above else -110.0
	lower_label.offset_bottom = lower_label.offset_top + 60.0
	lower_label.text = text
	lower_label.add_theme_color_override("font_color", col.lightened(0.35))


func announce(text: String, col: Color, dur: float) -> void:
	center_label.text = text
	center_label.add_theme_color_override("font_color", col.lightened(0.2))
	_announce_t = dur


func show_count(n: int) -> void:
	count_label.text = str(n)
	_count_t = 0.8


func show_countout(n: int) -> void:
	countout_label.text = ("COUNT-OUT  %d" % n) if n > 0 else ""


func reversal_prompt(window: float) -> void:
	_rev_t = maxf(window, 0.2)


func move_name(w: Wrestler, n: String) -> void:
	move_label.text = n.to_upper()
	move_label.add_theme_color_override("font_color", w.color.lightened(0.4))
	_move_t = 2.2


func flash_damage(w: Wrestler) -> void:
	_flash[w.idx] = 1.0


func show_kickout(w: Wrestler) -> void:
	_kick_target = w
	kick_box.visible = not w.is_cpu
	kick_label.text = "KICK OUT!  mash J / K / L / Space  (A B X Y)" if not w.is_cpu else ""


func hide_kickout() -> void:
	kick_box.visible = false
	count_label.text = ""


func show_submission(_a: Wrestler, _v: Wrestler) -> void:
	sub_box.visible = true


func set_submission(v: float) -> void:
	sub_bar.value = clampf(v, 0.0, 1.0)


func hide_submission() -> void:
	sub_box.visible = false


func show_pause(on: bool) -> void:
	if on:
		pause_box = _menu_box("PAUSED", [["Resume", "resume"], ["Restart match", "rematch"],
			["Character select", "select"], ["Main menu", "title"]])
	elif pause_box:
		pause_box.queue_free()
		pause_box = null


func show_results(r: Dictionary) -> void:
	var title := "%s WINS" % String(r.get("winner", "")).to_upper() if String(r.get("winner", "")) != "" else "NO CONTEST"
	var t := float(r.get("time", 0.0))
	var lines := "%s   -   %d:%02d" % [r.get("method", ""), int(t) / 60, int(t) % 60]
	results_box = _menu_box(title + "\n" + lines, [["Rematch", "rematch"], ["Character select", "select"], ["Main menu", "title"]])
	# ignore button presses for a moment so kick-out mashing does not trigger "Rematch" by accident
	for b in results_box.find_children("*", "Button", true, false):
		(b as Button).disabled = true
	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(results_box):
			for b2 in results_box.find_children("*", "Button", true, false):
				(b2 as Button).disabled = false
			var first := results_box.find_children("*", "Button", true, false)
			if not first.is_empty():
				(first[0] as Button).grab_focus())


func _menu_box(title: String, items: Array) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.set_anchors_preset(Control.PRESET_CENTER)
	pc.position = Vector2(-280, -170)
	pc.size = Vector2(560, 340)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.05, 0.08, 0.92)
	sb.border_color = Color(1, 0.8, 0.2)
	sb.set_border_width_all(3)
	sb.set_content_margin_all(18)
	pc.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	pc.add_child(vb)
	var tl := _label(30, Color(1, 0.85, 0.25))
	tl.text = title
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(tl)
	var first: Button = null
	for it in items:
		var b := Button.new()
		b.text = it[0]
		b.add_theme_font_size_override("font_size", 26)
		b.custom_minimum_size = Vector2(0, 48)
		b.pressed.connect(_on_menu.bind(it[1]))
		vb.add_child(b)
		if first == null:
			first = b
	root.add_child(pc)
	if first:
		first.grab_focus.call_deferred()
	return pc


func _on_menu(id: String) -> void:
	match id:
		"resume":
			m._toggle_pause()
		"rematch":
			Game.rematch()
		"select":
			Game.goto_select()
		"title":
			Game.goto_title()
