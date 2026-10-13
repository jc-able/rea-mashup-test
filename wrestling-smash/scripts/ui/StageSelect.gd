## Stage select (SSB64 map select): the 9 VS stages + random, previews drawn from the ROM
## collision outlines. Any device moves the single selection; A / START fights.
extends "res://scripts/ui/ScreenBase.gd"

const Roster := preload("res://scripts/ui/Roster.gd")
const StagePreview := preload("res://scripts/ui/StagePreview.gd")

var _big
var _name: Label
var _info: Label
var _entries: Array = []   # {gkind (-1 random), key, name}

func build() -> void:
	add_header("SELECT ARENA", app.rules_summary())
	var frame := Panel.new()
	frame.position = Vector2(50, 100)
	frame.size = Vector2(732, 476)
	canvas.add_child(frame)
	_big = StagePreview.new()
	_big.detail = true
	_big.position = Vector2(58, 108)
	_big.size = Vector2(716, 460)
	canvas.add_child(_big)
	_name = UiTheme.make_label("", "NameLabel", 38, Color.WHITE)
	_name.position = Vector2(76, 114)
	canvas.add_child(_name)
	_info = UiTheme.make_label("", "DimLabel", 15)
	_info.clip_text = true
	_info.position = Vector2(76, 536)
	_info.size = Vector2(690, 24)
	canvas.add_child(_info)

	for s in Roster.stages():
		_entries.append({"gkind": int(s.get("gkind", 0)), "key": str(s.get("key", "")), "name": str(s.get("name", "?"))})
	_entries.append({"gkind": -1, "key": "", "name": "RANDOM"})
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	grid.position = Vector2(806, 100)
	canvas.add_child(grid)
	for i in _entries.size():
		var e: Dictionary = _entries[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(206, 84)
		b.focus_mode = Control.FOCUS_ALL
		b.add_theme_stylebox_override("normal", _tile_box(Color(0.08, 0.09, 0.135, 0.95), UiTheme.LINE, 2))
		b.add_theme_stylebox_override("hover", _tile_box(Color(0.13, 0.14, 0.2, 0.97), Color(UiTheme.GOLD, 0.5), 2))
		b.add_theme_stylebox_override("pressed", _tile_box(Color(0.3, 0.22, 0.07, 0.97), UiTheme.GOLD, 2))
		b.add_theme_stylebox_override("focus", UiTheme.glow_box(UiTheme.GOLD, 3, 6))
		var mini = StagePreview.new()
		mini.position = Vector2(6, 6)
		mini.size = Vector2(92, 72)
		b.add_child(mini)
		mini.set_stage(e.key)
		var l := UiTheme.make_label(str(e.name).to_upper(), "BoldLabel", 15)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.position = Vector2(106, 8)
		l.size = Vector2(94, 68)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		b.add_child(l)
		b.focus_entered.connect(func() -> void: _show(i))
		b.pressed.connect(func() -> void: _choose(i))
		hover_focus(b)
		grid.add_child(b)
		if e.gkind == int(app.stage_gkind) or first_focus == null:
			first_focus = b
	add_footer("IN BATTLE:  START pauses   ·   while paused hold A + B + R + Z  (J + K + U + L)  to end the match   ·   ESC / B  back")

static func _tile_box(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	var s := UiTheme.box(bg, border, bw, 6, 0.0, 6.0)
	return s

func _show(i: int) -> void:
	var e: Dictionary = _entries[i]
	_big.set_stage(e.key)
	_name.text = str(e.name).to_upper()
	if e.gkind < 0:
		_info.text = "A random VS stage is chosen when the match starts."
		return
	var g: Dictionary = Roster.stage_geometry(e.key)
	var names := []
	for h in g.get("hazards", []):
		names.append(str(h).get_slice(" (", 0))
	var hz := ", ".join(names) if not names.is_empty() else "none"
	var bl: Rect2 = g.get("blast", Rect2())
	_info.text = "BLOCKOUT ARENA   ·   blast zone %d × %d   ·   hazards: %s" % [int(bl.size.x), int(bl.size.y), hz]

func _choose(i: int) -> void:
	var g := int(_entries[i].gkind)
	if g < 0:
		var real := _entries.filter(func(e) -> bool: return int(e.gkind) >= 0)
		g = int(real[randi() % real.size()].gkind) if not real.is_empty() else 0
	app.start_battle(g)

func on_back() -> void:
	app.goto("css")
