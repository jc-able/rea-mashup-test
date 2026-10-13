## Title: "WRESTLING SMASH" logo over a slow parade of the 12 superstars, controls summary and
## "PRESS START"; START/accept reveals the main menu (VS mode, controls, settings, quit).
## Whoever presses START here becomes player 1's input device.
extends "res://scripts/ui/ScreenBase.gd"

const Roster := preload("res://scripts/ui/Roster.gd")

var _press: Label
var _menu: VBoxContainer
var _parade: Control
var _t := 0.0
var _menu_open := false

func build() -> void:
	_parade = Control.new()
	_parade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_parade.position = Vector2(0, 250)
	_parade.size = Vector2(DESIGN.x, 330)
	_parade.draw.connect(_draw_parade)
	canvas.add_child(_parade)

	var top := UiTheme.make_label("WRESTLING", "TitleLabel", 88, Color.WHITE)
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.position = Vector2(0, 34)
	top.size = Vector2(DESIGN.x, 100)
	canvas.add_child(top)
	var smash := UiTheme.make_label("SMASH", "TitleLabel", 128, UiTheme.GOLD)
	smash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	smash.add_theme_color_override("font_outline_color", Color(0.45, 0.04, 0.08))
	smash.add_theme_constant_override("outline_size", 18)
	smash.position = Vector2(0, 104)
	smash.size = Vector2(DESIGN.x, 150)
	canvas.add_child(smash)
	var sub := UiTheme.make_label("SUPER SMASH BROS. 64 VS MODE   ·   SMACKDOWN VS. RAW 2011 SUPERSTARS", "BoldLabel", 17, Color(0.85, 0.87, 0.95))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 254)
	sub.size = Vector2(DESIGN.x, 26)
	canvas.add_child(sub)

	_press = UiTheme.make_label("PRESS START  ·  ENTER", "NameLabel", 34)
	_press.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_press.position = Vector2(0, 438)
	_press.size = Vector2(DESIGN.x, 50)
	canvas.add_child(_press)

	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 10)
	_menu.position = Vector2(DESIGN.x * 0.5 - 170, 318)
	_menu.size = Vector2(340, 0)
	_menu.visible = false
	canvas.add_child(_menu)
	var vs := make_button("VS MODE", func() -> void: app.goto("rules"), 340)
	_menu.add_child(vs)
	_menu.add_child(make_button("CONTROLS", func() -> void: app.goto("controls"), 340))
	_menu.add_child(make_button("SETTINGS", func() -> void: app.goto("settings"), 340))
	_menu.add_child(make_button("QUIT", func() -> void: app.quit_game(), 340))
	first_focus = vs

	var panel := PanelContainer.new()
	panel.position = Vector2(70, 596)
	panel.size = Vector2(DESIGN.x - 140, 96)
	var ctl := UiTheme.make_label(app.controls_summary(), "DimLabel", 13)
	ctl.add_theme_color_override("font_color", Color(0.78, 0.8, 0.88))
	ctl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(ctl)
	canvas.add_child(panel)

func on_enter() -> void:
	if args.get("menu", false):
		_open_menu()

func _process(delta: float) -> void:
	_t += delta
	_press.modulate.a = 0.35 + 0.65 * absf(sin(_t * 2.4))
	_parade.queue_redraw()

func _draw_parade() -> void:
	var fs := Roster.fighters()
	if fs.is_empty():
		return
	var w := 214.0
	var h := 300.0
	var total := w * fs.size()
	var off := fmod(_t * 26.0, total)
	var i := 0
	for f in fs:
		var tex := Roster.portrait(str(f.get("slug", "")))
		var x := fmod(i * w - off + total, total) - w
		i += 1
		if tex == null or x > DESIGN.x:
			continue
		var a := 0.30 + 0.25 * maxf(0.0, 1.0 - absf((x + w * 0.5) - DESIGN.x * 0.5) / (DESIGN.x * 0.5))
		_parade.draw_texture_rect(tex, Rect2(x, 0, w * 1.4, h * 1.0), false, Color(1, 1, 1, a))
	# fade the parade into the floor
	var cols := PackedColorArray([Color(UiTheme.BG, 0.0), Color(UiTheme.BG, 0.0), Color(UiTheme.BG, 0.95), Color(UiTheme.BG, 0.95)])
	_parade.draw_polygon(PackedVector2Array([Vector2(0, 120), Vector2(DESIGN.x, 120), Vector2(DESIGN.x, h + 30), Vector2(0, h + 30)]), cols)

func _open_menu() -> void:
	_menu_open = true
	_press.visible = false
	_menu.visible = true
	first_focus.grab_focus()

func handle_intent(action: String, device: int) -> void:
	if not _menu_open:
		if action in ["accept", "start"]:
			app.set_primary_device(device)
			_open_menu()
		return
	super.handle_intent(action, device)

func on_back() -> void:
	if _menu_open:
		_menu_open = false
		_menu.visible = false
		_press.visible = true

func _gui_input(_e: InputEvent) -> void:
	pass

func _unhandled_input(e: InputEvent) -> void:
	if not _menu_open and e is InputEventMouseButton and e.pressed:
		_open_menu()
