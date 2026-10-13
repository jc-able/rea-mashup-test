## Port of src/sys/controller.c (ssb-decomp-re): per-port controller state as the game sees it.
## The N64 serial-interface polling (osContStartReadData/osContGetReadData) is replaced by the
## Godot input layer (scripts/input/InputMapper.gd), which writes the raw pad state
## (OSContPad: button bits, stick_x, stick_y) into sSYControllerData each frame. The state logic
## (taps, releases, auto-repeat "update" buttons, globals copied once per game frame) is verbatim.
class_name Controller
extends Port

## SYController (src/sys/controller.h)
class SYController:
	var button_hold: int = 0      # u16
	var button_tap: int = 0       # u16
	var button_update: int = 0    # u16
	var button_release: int = 0   # u16
	var stick_range: Vector2i = Vector2i.ZERO   # Vec2b (s8 each)

## ControllerInfo (src/sys/controller.h)
class ControllerInfo:
	var unk00: int = 0   # contpad button
	var unk02: int = 0   # new button presses
	var unk04: int = 0   # pressed buttons ( |= .02)
	var unk06: int = 0   # auto-repeat presses
	var unk08: int = 0   # ( |= .06)
	var unk0A: int = 0   # button releases
	var unk0C: int = 0   # released buttons ( |= .0A)
	var unk0E: int = 0   # stick x (s8)
	var unk0F: int = 0   # stick y (s8)
	var unk10: int = 30  # repeat initial delay
	var unk14: int = 5   # repeat interval
	var unk18: int = 30  # repeat countdown
	var unk1C: int = 0   # cont status errno (0 = connected)
	var unk1D: int = 0   # cont status

## OSContPad
class OSContPad:
	var button: int = 0
	var stick_x: int = 0
	var stick_y: int = 0
	var errno: int = 0

static var gSYControllerDevices: Array = _make(SYController, MAXCONTROLLERS)
static var gSYControllerMain: SYController = SYController.new()
static var sSYControllerDescs: Array = _make(ControllerInfo, MAXCONTROLLERS)
static var sSYControllerData: Array = _make(OSContPad, MAXCONTROLLERS)
static var gSYControllerDeviceStatuses: Array = [0, 1, 2, 3]
static var gSYControllerConnectedNum: int = MAXCONTROLLERS
static var sSYControllerIsUpdateData: int = FALSE

static func _make(cls, n: int) -> Array:
	var a := []
	for i in n:
		a.append(cls.new())
	return a

static func _s8(v: int) -> int:
	v &= 0xFF
	return v - 0x100 if v >= 0x80 else v

## 0x80003C00
static func syControllerUpdateDeviceIndexes():
	var controllers := 0
	for i in MAXCONTROLLERS:
		if sSYControllerDescs[i].unk1C == 0:
			gSYControllerDeviceStatuses[controllers] = i
			controllers += 1
	gSYControllerConnectedNum = controllers
	for i in range(controllers, MAXCONTROLLERS):
		gSYControllerDeviceStatuses[i] = -1

## 0x80003CC4 - controller pak / rumble detection: not applicable.
static func syControllerUpdateDeviceStatuses():
	pass

## 0x80003DD4
static func syControllerReadDeviceData():
	for i in MAXCONTROLLERS:
		var d: ControllerInfo = sSYControllerDescs[i]
		var pad: OSContPad = sSYControllerData[i]
		d.unk1C = pad.errno
		if d.unk1C == 0:
			var button: int = pad.button & 0xFFFF
			d.unk02 = (button ^ d.unk00) & button
			d.unk0A = (button ^ d.unk00) & d.unk00
			if button ^ d.unk00:
				# there is a new press
				d.unk06 = d.unk02
				d.unk18 = d.unk10
			else:
				# no new button presses
				d.unk18 -= 1
				if d.unk18 > 0:
					d.unk06 = 0
				else:
					d.unk06 = button
					d.unk18 = d.unk14
			d.unk00 = button
			d.unk0E = _s8(pad.stick_x)
			d.unk0F = _s8(pad.stick_y)
			d.unk04 |= d.unk02
			d.unk0C |= d.unk0A
			d.unk08 |= d.unk06
	sSYControllerIsUpdateData = TRUE

## 0x80003F98
static func syControllerUpdateGlobalData():
	for i in MAXCONTROLLERS:
		var d: ControllerInfo = sSYControllerDescs[i]
		if d.unk1C == FALSE:
			var c: SYController = gSYControllerDevices[i]
			c.button_hold = d.unk00
			c.button_tap = d.unk04
			c.button_release = d.unk0C
			c.button_update = d.unk08
			c.stick_range = Vector2i(d.unk0E, d.unk0F)
			d.unk04 = 0
			d.unk08 = 0
			d.unk0C = 0
	syControllerUpdateDeviceIndexes()
	var idx: int = gSYControllerDeviceStatuses[0]
	if idx >= 0:
		var players: SYController = gSYControllerDevices[idx]
		gSYControllerMain.button_tap = players.button_tap
		gSYControllerMain.button_hold = players.button_hold
		gSYControllerMain.button_update = players.button_update
		gSYControllerMain.button_release = players.button_release
		gSYControllerMain.stick_range = players.stick_range
	sSYControllerIsUpdateData = FALSE

static func syControllerInitDevices():
	for i in MAXCONTROLLERS:
		sSYControllerData[i].button = 0
		var d: ControllerInfo = sSYControllerDescs[i]
		d.unk06 = 0
		d.unk02 = 0
		d.unk00 = 0
		d.unk0F = 0
		d.unk18 = 30
		d.unk10 = 30
		d.unk14 = 5
		d.unk0E = d.unk0F
		d.unk1C = sSYControllerData[i].errno
		var c: SYController = gSYControllerDevices[i]
		c.button_hold = 0
		c.button_tap = 0
		c.button_update = 0
		c.stick_range = Vector2i.ZERO
	syControllerUpdateDeviceIndexes()
	sSYControllerIsUpdateData = FALSE

static func syControllerDispatchEvent(evt = null):
	pass

static func syControllerScheduleRead():
	syControllerReadDeviceData()

static func syControllerFuncRead():
	syControllerReadDeviceData()
	syControllerUpdateGlobalData()

## Port-only: one game frame of input: raw pads were already written by the input layer.
static func port_poll_frame() -> void:
	syControllerReadDeviceData()
	syControllerUpdateGlobalData()

## 0x80004338 - repeat timings (unk10/unk14) via the controller thread event.
static func unref_80004338(arg0 = null, arg1 = null):
	for i in MAXCONTROLLERS:
		sSYControllerDescs[i].unk10 = arg0
		sSYControllerDescs[i].unk14 = arg1

static func syControllerSetAutoRead(is_scheduled = null):
	pass

static func syControllerSetStatusDelay(delay = null):
	pass

## Rumble Pak events: no rumble hardware in this port (Gmrumble keeps the game-side state).
static func syControllerUpdateRumbleEvent(port = null, ev_kind = null):
	pass

static func syControllerStartRumble(port = null):
	pass

static func syControllerStopRumble(port = null):
	pass

static func syControllerInitRumble(port = null):
	pass

static func syControllerParseEvent(evt = null):
	pass

static func syControllerThreadMain(unused = null):
	pass
