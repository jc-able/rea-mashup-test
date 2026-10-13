## 1:1 port of src/ft/ftkey.c (ssb-decomp-re): scripted ("key") controller input playback.
##
## fp->key.script is fp.key.key_script: an Array of u16 FTKeyEvent halfwords, with the C pointer
## position kept in fp.key.script_index (key->script++ == script_index += 1, NULL == null).
## union FTKeyEvent { u16 halfword; struct { u16 opcode : 4; u16 param : 12; } command; Vec2b stick_range; }
## (IDO big-endian bitfields: opcode = bits 15..12, param = bits 11..0; stick_range.x = high byte,
## stick_range.y = low byte, both s8).
class_name Ftkey
extends Port

static func _ftKeyEventHalfword(key) -> int:
	return int(key.key_script[key.script_index]) & 0xFFFF

static func _s8(x: int) -> int:
	return ((x + 0x80) & 0xFF) - 0x80

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80115B10
static func ftKeyProcessKeyEvents(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var cp = fp.input.cp
	var key = fp.key

	if key.key_script != null:
		if key.input_wait != 0:
			key.input_wait -= 1
		while true:
			if (key.key_script == null) or (key.input_wait > 0):
				break
			else:
				key.input_wait = _ftKeyEventHalfword(key) & 0xFFF                # key->script->command.param

			match (_ftKeyEventHalfword(key) >> 12) & 0xF:                       # key->script->command.opcode
				nFTKeyEventEnd:
					key.key_script = null
					key.script_index = 0

				nFTKeyEventButton:
					key.script_index += 1

					cp.button_inputs = _ftKeyEventHalfword(key)                  # ftKeyGetButtons(key->script)

					key.script_index += 1

				nFTKeyEventStick:
					key.script_index += 1

					cp.stick_range.x = _s8(_ftKeyEventHalfword(key) >> 8)        # ftKeyGetStickRange(key->script)->x
					cp.stick_range.y = _s8(_ftKeyEventHalfword(key) & 0xFF)      # ftKeyGetStickRange(key->script)->y

					key.script_index += 1
