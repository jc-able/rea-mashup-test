## Controls / help: the battle key layout of both keyboard halves (read from InputMapper's
## KB_LAYOUTS so it never drifts), the gamepad layout, SSB64 techniques and menu keys.
extends "res://scripts/ui/ScreenBase.gd"

const ACTIONS := [["Move", "move"], ["Walk / tilt (hold)", "mod"], ["Attack  (A)", "a"], ["Special  (B)", "b"],
	["Jump  (C)", "c"], ["Shield  (Z)", "z"], ["Grab  (R)", "r"], ["Taunt  (L)", "l"], ["Pause  (START)", "start"]]
const PAD := {"move": "Left stick / D-pad", "mod": "Tilt the stick gently", "a": "A", "b": "B or X", "c": "Y or right stick",
	"z": "RB or RT", "r": "LB", "l": "LT", "start": "Start"}

func build() -> void:
	add_header("CONTROLS", "BATTLE LAYOUT   ·   SSB64 N64 BUTTONS IN BRACKETS")
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 18)
	cols.position = Vector2(56, 104)
	cols.size = Vector2(DESIGN.x - 112, 330)
	canvas.add_child(cols)
	var layouts: Dictionary = app.keyboard_layouts()
	cols.add_child(_column("KEYBOARD 1", UiTheme.PLAYER_COLORS[0], _kb_texts(layouts.get(1, {}), "W A S D")))
	cols.add_child(_column("KEYBOARD 2", UiTheme.PLAYER_COLORS[1], _kb_texts(layouts.get(2, {}), "Arrow keys")))
	cols.add_child(_column("GAMEPAD", UiTheme.PLAYER_COLORS[3], PAD))

	var tips := PanelContainer.new()
	tips.position = Vector2(56, 452)
	tips.size = Vector2(DESIGN.x - 112, 180)
	canvas.add_child(tips)
	var tl := UiTheme.make_label(
		"SMASH ATTACK: tap a direction and A together   ·   TILT: hold walk + direction + A   ·   GRAB: shield + A, or R\n" +
		"DROP THROUGH a platform: tap down   ·   ROLL / DODGE: shield + left/right   ·   RECOVER: up + B\n" +
		"PAUSE: START during battle   ·   QUIT A PAUSED MATCH: hold A + B + R + Z  (keyboard 1: J + K + U + L)\n" +
		"MENUS: move with WASD / arrows / D-pad, confirm with J / , / A, back with K / . / B / Esc, START = Enter / Backspace / Start.\n" +
		"IN BATTLE: F4 / gamepad SELECT switches wrestler animations SMASH 64 <-> SvR 2011 (the wrestlers' own moves; gameplay unchanged)   ·   F1 hitboxes + animation source   ·   F2 skeleton   ·   F3 camera   ·   Esc quit\n" +
		"F11 toggles fullscreen. Character select: J, comma or gamepad A on an unused device joins the next free player slot.",
		"", 15, Color(0.82, 0.85, 0.92))
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tips.add_child(tl)
	var back := make_button("◀  BACK", func() -> void: on_back(), 200)
	back.position = Vector2(56, 640)
	canvas.add_child(back)
	first_focus = back

func _kb_texts(layout: Dictionary, move: String) -> Dictionary:
	var out := {"move": move}
	for k in ["mod", "a", "b", "c", "z", "r", "l", "start"]:
		var names := []
		for code in layout.get(k, []):
			names.append(OS.get_keycode_string(int(code)))
		out[k] = " / ".join(names) if not names.is_empty() else "-"
	if out.has("mod"):
		out.mod = "Hold " + str(out.mod)
	return out

func _column(title: String, col: Color, texts: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	v.add_child(UiTheme.make_label(title, "NameLabel", 26, col))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 5)
	v.add_child(g)
	for a in ACTIONS:
		g.add_child(UiTheme.make_label(a[0], "DimLabel", 15))
		g.add_child(UiTheme.make_label(str(texts.get(a[1], "-")), "BoldLabel", 16))
	return p

func on_back() -> void:
	app.goto("title", {"menu": true})
