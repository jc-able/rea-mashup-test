extends Node
## Input actions (created in code so they are easy to read and edit).
## Mapping follows SvR 2011's own control help (string.pac 30000-30448, decoded in extracted/svr2011_moves/
## controls_help.json): LS move, LB run, X strike, RS grapple, B Irish whip / pin, A action, RT reversal,
## Y signature/finisher (string 24767/24847), D-pad taunt, RB position change, RS click submission.
## Keyboard equivalents are custom.

const ACTIONS := {
	"p1_left": [KEY_A, KEY_LEFT],
	"p1_right": [KEY_D, KEY_RIGHT],
	"p1_up": [KEY_W, KEY_UP],
	"p1_down": [KEY_S, KEY_DOWN],
	"p1_run": [KEY_SHIFT],
	"p1_strike": [KEY_J],
	"p1_grapple": [KEY_K],
	"p1_whip": [KEY_L],
	"p1_action": [KEY_SPACE],
	"p1_reversal": [KEY_I],
	"p1_special": [KEY_O],
	"p1_taunt": [KEY_T],
	"p1_change": [KEY_Q],
	"p1_submission": [KEY_E],
	"ui_pause": [KEY_ESCAPE, KEY_P],
	"ui_skip": [KEY_ENTER, KEY_KP_ENTER],
}
const PAD_BUTTONS := {
	"p1_run": [JOY_BUTTON_LEFT_SHOULDER],
	"p1_strike": [JOY_BUTTON_X],
	"p1_whip": [JOY_BUTTON_B],
	"p1_action": [JOY_BUTTON_A],
	"p1_special": [JOY_BUTTON_Y],
	"p1_taunt": [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT],
	"p1_change": [JOY_BUTTON_RIGHT_SHOULDER],
	"p1_submission": [JOY_BUTTON_RIGHT_STICK],
	"ui_pause": [JOY_BUTTON_START],
	"ui_skip": [JOY_BUTTON_START],
}


func _ready() -> void:
	for a in ACTIONS:
		if not InputMap.has_action(a):
			InputMap.add_action(a, 0.25)
		for k in ACTIONS[a]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(a, ev)
	for a in PAD_BUTTONS:
		if not InputMap.has_action(a):
			InputMap.add_action(a, 0.25)
		for b in PAD_BUTTONS[a]:
			var ev := InputEventJoypadButton.new()
			ev.button_index = b
			ev.device = -1
			InputMap.action_add_event(a, ev)
	# left stick -> movement, right trigger -> reversal
	_axis("p1_left", JOY_AXIS_LEFT_X, -1.0)
	_axis("p1_right", JOY_AXIS_LEFT_X, 1.0)
	_axis("p1_up", JOY_AXIS_LEFT_Y, -1.0)
	_axis("p1_down", JOY_AXIS_LEFT_Y, 1.0)
	_axis("p1_reversal", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	# menus also accept the gameplay keys
	for pair in [["ui_accept", KEY_J], ["ui_accept", KEY_SPACE], ["ui_cancel", KEY_L], ["ui_cancel", KEY_BACKSPACE]]:
		var ev := InputEventKey.new()
		ev.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0], ev)


func _axis(action: String, axis: int, dir: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = dir
	ev.device = -1
	InputMap.action_add_event(action, ev)


## Right stick as a grapple direction (SvR: "MOVE [RS ANY]"): returns a non-zero vector on a flick.
static func right_stick() -> Vector2:
	var v := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	return v if v.length() > 0.6 else Vector2.ZERO


static func help_lines() -> PackedStringArray:
	return PackedStringArray([
		"MOVE  WASD / arrows  (left stick)",
		"RUN  hold Shift  (LB)",
		"STRIKE  J  (X)  - tap for combo, hold for strong strike",
		"GRAPPLE  K + direction  (right stick)  - then K + direction again to throw",
		"   in a hold: J strike, E submission, Space release",
		"IRISH WHIP / PIN  L  (B)  - pin a downed opponent",
		"ACTION  Space  (A)  - climb turnbuckle / exit or enter ring / lift opponent",
		"REVERSAL  I  (RT)  - press when the opponent attacks",
		"SIGNATURE / FINISHER  O  (Y)  - when the momentum meter is full",
		"TAUNT  T  (D-pad)",
		"KICK OUT / ESCAPE  mash J K L Space  (X Y B A)",
		"PAUSE  Esc  (Start)",
	])
