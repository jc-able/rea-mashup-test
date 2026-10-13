## Sound-effect entry points of the original audio library (libultra/n_audio, not decompiled C).
## func_800269C0_275C0(fgm_id) plays an FGM and returns a handle {sfx_id}; func_80026738_27338
## stops it. The render/audio layer may connect `player` to play actual sounds.
class_name Snd
extends Port

static var player: Callable = Callable()   # optional: func(fgm_id: int) -> void
static var _next_id: int = 1
## Port-only: playing handles finish after this many frames (the N64 audio library clears a voice's
## sfx_id when the sound ends; only audio bookkeeping such as the crowd-voice queue reads it).
const PORT_SOUND_FRAMES := 45
static var _active: Array = []

class SndHandle:
	var sfx_id: int = 0
	var fgm_id: int = 0

static func func_800269C0_275C0(fgm_id = 0):
	var h := SndHandle.new()
	h.sfx_id = _next_id
	h.fgm_id = fgm_id if fgm_id != null else 0
	_next_id = (_next_id % 0xFFFF) + 1
	_active.append([h, PORT_SOUND_FRAMES])
	if player.is_valid():
		player.call(h.fgm_id)
	return h

## Port-only: called once per game frame; ends handles whose sound would have finished.
static func port_tick() -> void:
	var i := 0
	while i < _active.size():
		var e: Array = _active[i]
		e[1] -= 1
		if e[1] <= 0 or e[0].sfx_id == 0:
			e[0].sfx_id = 0
			_active.remove_at(i)
		else:
			i += 1

static func func_80026738_27338(handle = null):
	if handle != null:
		handle.sfx_id = 0
	return null

static func func_800266A0_272A0():
	return null
