## Maps Godot keyboard / gamepad input onto the four N64 controller ports (OSContPad: button
## bits + signed stick), written into Controller.sSYControllerData once per game frame.
##
## N64 controls as used by SSB64 (see ftmain.c ftMainProcUpdateInterrupt):
##   A attack, B special, Z shield (Z+A grab), R = grab macro (C adds A|Z), L taunt,
##   C buttons jump, START pause, control stick range ±80 (I_CONTROLLER_RANGE_MAX).
## Keyboards are digital, so a held "walk/tilt" modifier gives a half deflection (40): this
## allows walking and tilt attacks; a plain direction press is a full, instant deflection
## (dash / smash inputs exactly like slamming the N64 stick).
class_name InputMapper
extends RefCounted

const STICK_MAX := 80
const STICK_HALF := 40
const DEADZONE := 0.15

enum Device { NONE, KB1, KB2, PAD }

## Per port: device kind and joypad id (for PAD)
static var port_device: Array = [Device.KB1, Device.KB2, Device.NONE, Device.NONE]
static var port_joy: Array = [-1, -1, -1, -1]
## Port-only test hook: when a port has an entry here, it overrides live input (used by
## automated tests that feed scripted inputs); {button:int, stick:Vector2i}
static var scripted: Dictionary = {}

const KB_LAYOUTS := {
	Device.KB1: {
		"up": [KEY_W], "down": [KEY_S], "left": [KEY_A], "right": [KEY_D], "mod": [KEY_SHIFT],
		"a": [KEY_J], "b": [KEY_K], "z": [KEY_L], "r": [KEY_U], "c": [KEY_I, KEY_SPACE], "l": [KEY_O],
		"start": [KEY_ENTER],
	},
	Device.KB2: {
		"up": [KEY_UP], "down": [KEY_DOWN], "left": [KEY_LEFT], "right": [KEY_RIGHT], "mod": [KEY_CTRL],
		"a": [KEY_KP_1, KEY_COMMA], "b": [KEY_KP_2, KEY_PERIOD], "z": [KEY_KP_3, KEY_SLASH],
		"r": [KEY_KP_6, KEY_APOSTROPHE], "c": [KEY_KP_5, KEY_KP_0], "l": [KEY_KP_9], "start": [KEY_KP_ENTER, KEY_BACKSPACE],
	},
}

static func _any(keys: Array) -> bool:
	for k in keys:
		if Input.is_physical_key_pressed(k):
			return true
	return false

## Assign connected gamepads to ports without a keyboard (or to P1/P2 when only pads are used).
static func auto_assign_pads() -> void:
	var pads := Input.get_connected_joypads()
	var pi := 0
	for port in 4:
		if pi >= pads.size():
			break
		if port_device[port] == Device.NONE:
			port_device[port] = Device.PAD
			port_joy[port] = pads[pi]
			pi += 1

static func read_port(port: int) -> Dictionary:
	if scripted.has(port):
		return scripted[port]
	var dev: int = port_device[port]
	var button := 0
	var stick := Vector2i.ZERO
	match dev:
		Device.KB1, Device.KB2:
			var L: Dictionary = KB_LAYOUTS[dev]
			var x := 0
			var y := 0
			if _any(L.right): x += 1
			if _any(L.left): x -= 1
			if _any(L.up): y += 1
			if _any(L.down): y -= 1
			var mag := STICK_HALF if _any(L.mod) else STICK_MAX
			if x != 0 and y != 0:
				# diagonal: an N64 stick's octagonal gate corner reads about 70 on each axis
				stick = Vector2i(int(round(x * mag * 0.875)), int(round(y * mag * 0.875)))
			else:
				stick = Vector2i(x * mag, y * mag)
			if _any(L.a): button |= SSBDefs.A_BUTTON
			if _any(L.b): button |= SSBDefs.B_BUTTON
			if _any(L.z): button |= SSBDefs.Z_TRIG
			if _any(L.r): button |= SSBDefs.R_TRIG
			if _any(L.c): button |= SSBDefs.U_CBUTTONS
			if _any(L.l): button |= SSBDefs.L_TRIG
			if _any(L.start): button |= SSBDefs.START_BUTTON
		Device.PAD:
			var j: int = port_joy[port]
			if j < 0:
				return {"button": 0, "stick": Vector2i.ZERO}
			var ax := Input.get_joy_axis(j, JOY_AXIS_LEFT_X)
			var ay := -Input.get_joy_axis(j, JOY_AXIS_LEFT_Y)
			var v := Vector2(ax, ay)
			if v.length() < DEADZONE:
				v = Vector2.ZERO
			if Input.is_joy_button_pressed(j, JOY_BUTTON_DPAD_LEFT): v.x = -1.0
			if Input.is_joy_button_pressed(j, JOY_BUTTON_DPAD_RIGHT): v.x = 1.0
			if Input.is_joy_button_pressed(j, JOY_BUTTON_DPAD_UP): v.y = 1.0
			if Input.is_joy_button_pressed(j, JOY_BUTTON_DPAD_DOWN): v.y = -1.0
			stick = Vector2i(clampi(int(round(v.x * STICK_MAX)), -STICK_MAX, STICK_MAX), clampi(int(round(v.y * STICK_MAX)), -STICK_MAX, STICK_MAX))
			if Input.is_joy_button_pressed(j, JOY_BUTTON_A): button |= SSBDefs.A_BUTTON
			if Input.is_joy_button_pressed(j, JOY_BUTTON_X) or Input.is_joy_button_pressed(j, JOY_BUTTON_B): button |= SSBDefs.B_BUTTON
			if Input.is_joy_button_pressed(j, JOY_BUTTON_Y): button |= SSBDefs.U_CBUTTONS
			var rs := Vector2(Input.get_joy_axis(j, JOY_AXIS_RIGHT_X), Input.get_joy_axis(j, JOY_AXIS_RIGHT_Y))
			if rs.length() > 0.5: button |= SSBDefs.U_CBUTTONS
			if Input.is_joy_button_pressed(j, JOY_BUTTON_RIGHT_SHOULDER) or Input.get_joy_axis(j, JOY_AXIS_TRIGGER_RIGHT) > 0.4: button |= SSBDefs.Z_TRIG
			if Input.is_joy_button_pressed(j, JOY_BUTTON_LEFT_SHOULDER): button |= SSBDefs.R_TRIG
			if Input.get_joy_axis(j, JOY_AXIS_TRIGGER_LEFT) > 0.4: button |= SSBDefs.L_TRIG
			if Input.is_joy_button_pressed(j, JOY_BUTTON_START): button |= SSBDefs.START_BUTTON
	return {"button": button, "stick": stick}

## Write all four raw pads for this frame (port without a device reports no buttons).
static func poll() -> void:
	for port in 4:
		var r := read_port(port)
		var pad = Controller.sSYControllerData[port]
		pad.button = int(r.button) & 0xFFFF
		pad.stick_x = int(r.stick.x)
		pad.stick_y = int(r.stick.y)
		pad.errno = 0

static func describe_controls() -> String:
	return "P1 keyboard: move WASD (hold Shift = walk/tilt) | A attack J | B special K | jump I or Space | shield (Z) L | grab (R) U | taunt (L) O | pause Enter\n" + \
		"P2 keyboard: move arrows (hold Ctrl = walk/tilt) | A Num1 or , | B Num2 or . | jump Num5/Num0 | shield Num3 or / | grab Num6 or ' | taunt Num9 | pause NumEnter/Backspace\n" + \
		"Gamepad: left stick/D-pad move | A attack | B/X special | Y or right stick jump | RB/RT shield | LB grab | LT taunt | Start pause"
