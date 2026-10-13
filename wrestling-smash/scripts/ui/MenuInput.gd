## Menu input layer: turns key / gamepad events into {device, action} intents so every menu
## works with both keyboard halves, any gamepad and the mouse (mouse goes through the GUI).
## Keys follow the battle layout of scripts/input/InputMapper.gd (physical keys, no InputMap
## actions needed): the "A" button confirms, "B" goes back, START proceeds.
##   device 1 = keyboard 1 (WASD side), 2 = keyboard 2 (arrows / numpad side),
##   10 = shared keys (Esc), 100 + j = gamepad j.
## actions: up down left right accept back start aux z r l
extends RefCounted

const DEV_NONE := 0
const DEV_KB1 := 1
const DEV_KB2 := 2
const DEV_KEYS := 10
const DEV_PAD0 := 100

const KB1_KEYS := {
	KEY_W: "up", KEY_S: "down", KEY_A: "left", KEY_D: "right",
	KEY_J: "accept", KEY_SPACE: "accept", KEY_K: "back", KEY_ENTER: "start",
	KEY_I: "aux", KEY_L: "z", KEY_U: "r", KEY_O: "l",
}
const KB2_KEYS := {
	KEY_UP: "up", KEY_DOWN: "down", KEY_LEFT: "left", KEY_RIGHT: "right",
	KEY_KP_1: "accept", KEY_COMMA: "accept", KEY_KP_2: "back", KEY_PERIOD: "back",
	KEY_KP_ENTER: "start", KEY_BACKSPACE: "start", KEY_KP_5: "aux", KEY_KP_0: "aux",
	KEY_KP_3: "z", KEY_SLASH: "z", KEY_KP_6: "r", KEY_APOSTROPHE: "r", KEY_KP_9: "l",
}
const SHARED_KEYS := {KEY_ESCAPE: "back"}
const PAD_BUTTONS := {
	JOY_BUTTON_A: "accept", JOY_BUTTON_B: "back", JOY_BUTTON_BACK: "back", JOY_BUTTON_START: "start",
	JOY_BUTTON_Y: "aux", JOY_BUTTON_X: "aux", JOY_BUTTON_RIGHT_SHOULDER: "z", JOY_BUTTON_LEFT_SHOULDER: "r",
}
const DIRS := ["up", "down", "left", "right"]
const REPEAT_DELAY := 0.38
const REPEAT_RATE := 0.085

## joy id -> {dir, t}: held direction (stick or D-pad) with auto-repeat.
var _pads: Dictionary = {}

static func is_dir(action: String) -> bool:
	return action in DIRS

static func is_pad(dev: int) -> bool:
	return dev >= DEV_PAD0

static func device_label(dev: int) -> String:
	if dev == DEV_KB1:
		return "KEYBOARD 1"
	if dev == DEV_KB2:
		return "KEYBOARD 2"
	if dev >= DEV_PAD0:
		return "GAMEPAD %d" % (dev - DEV_PAD0 + 1)
	return "NO INPUT"

static func device_hint(dev: int) -> String:
	if dev == DEV_KB1:
		return "WASD · J pick · K back"
	if dev == DEV_KB2:
		return "ARROWS · , pick · . back"
	if dev >= DEV_PAD0:
		return "D-PAD · A pick · B back"
	return "MOUSE ONLY"

## Every currently selectable input device (keyboards + connected pads).
static func available_devices() -> Array:
	var out := [DEV_KB1, DEV_KB2]
	for j in Input.get_connected_joypads():
		out.append(DEV_PAD0 + int(j))
	return out

func _pad_dir(j: int) -> String:
	if Input.is_joy_button_pressed(j, JOY_BUTTON_DPAD_UP):
		return "up"
	if Input.is_joy_button_pressed(j, JOY_BUTTON_DPAD_DOWN):
		return "down"
	if Input.is_joy_button_pressed(j, JOY_BUTTON_DPAD_LEFT):
		return "left"
	if Input.is_joy_button_pressed(j, JOY_BUTTON_DPAD_RIGHT):
		return "right"
	var v := Vector2(Input.get_joy_axis(j, JOY_AXIS_LEFT_X), Input.get_joy_axis(j, JOY_AXIS_LEFT_Y))
	if v.length() < 0.55:
		return ""
	if absf(v.x) > absf(v.y):
		return "right" if v.x > 0.0 else "left"
	return "down" if v.y > 0.0 else "up"

func _update_pad(j: int, out: Array) -> void:
	var d := _pad_dir(j)
	var st: Dictionary = _pads.get(j, {"dir": "", "t": 0.0})
	if d != st.dir:
		_pads[j] = {"dir": d, "t": REPEAT_DELAY}
		if d != "":
			out.append({"device": DEV_PAD0 + j, "action": d})

## Returns the intents carried by one input event (empty for unrelated events).
func translate(event: InputEvent) -> Array:
	var out: Array = []
	if event is InputEventKey:
		var ek := event as InputEventKey
		if not ek.pressed:
			return out
		var k: int = ek.physical_keycode if ek.physical_keycode != KEY_NONE else ek.keycode
		var dev := DEV_NONE
		var act := ""
		if KB1_KEYS.has(k):
			dev = DEV_KB1
			act = KB1_KEYS[k]
		elif KB2_KEYS.has(k):
			dev = DEV_KB2
			act = KB2_KEYS[k]
		elif SHARED_KEYS.has(k):
			dev = DEV_KEYS
			act = SHARED_KEYS[k]
		if act != "" and (not ek.echo or is_dir(act)):
			out.append({"device": dev, "action": act})
	elif event is InputEventJoypadButton:
		var eb := event as InputEventJoypadButton
		if eb.button_index in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
			_update_pad(eb.device, out)
		elif eb.pressed and PAD_BUTTONS.has(eb.button_index):
			out.append({"device": DEV_PAD0 + eb.device, "action": PAD_BUTTONS[eb.button_index]})
	elif event is InputEventJoypadMotion:
		var em := event as InputEventJoypadMotion
		if em.axis == JOY_AXIS_LEFT_X or em.axis == JOY_AXIS_LEFT_Y:
			_update_pad(em.device, out)
	return out

## Auto-repeat for held pad directions; call every frame.
func poll(delta: float) -> Array:
	var out: Array = []
	for j in _pads.keys():
		var st: Dictionary = _pads[j]
		if st.dir == "":
			continue
		st.t -= delta
		if st.t <= 0.0:
			st.t = REPEAT_RATE
			out.append({"device": DEV_PAD0 + int(j), "action": st.dir})
	return out

## True for events that the menu layer owns (consumed so the GUI does not double-handle them).
static func is_menu_event(event: InputEvent) -> bool:
	return event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion
