## Port of GMColAnim (src/gm/gmtypes.h): color animation state run by ftMainUpdateColAnim.
## Scripts are the generated Gmcolscripts data; a script pointer is [script_name, word_index].
class_name GMColAnim
extends RefCounted

## GMColKeys: u8 r, g, b, a; s16 ir, ig, ib, ia (interpolation steps)
class ColKeys:
	var r: int = 0
	var g: int = 0
	var b: int = 0
	var a: int = 0
	var ir: int = 0
	var ig: int = 0
	var ib: int = 0
	var ia: int = 0

## GMColScript: p_script, color_event_timer (u16), script_id (u16), and the contiguous
## p_subroutine[1] / loop_count[1] / p_goto[2] / unk_ca_timer words that ftMainUpdateColAnim indexes as
## one 5-word stack (p_subroutine[script_id++]). The fire/electric scripts nest LoopBegin inside a
## Subroutine inside a loop and reach script_id 5, i.e. they use unk_ca_timer as the 5th slot.
class ColScript:
	var p_script = null              # [name, word_index] or null
	var color_event_timer: int = 0
	var script_id: int = 0
	var stack: Array = [null, 0, null, null, 0]

var cs: Array = [ColScript.new(), ColScript.new()]
var length: int = 0
var colanim_id: int = 0
var color1 := ColKeys.new()
var light_angle_x: float = 0.0
var light_angle_y: float = 0.0
var color2 := ColKeys.new()
var is_use_color1: int = 0
var is_use_light: int = 0
var is_use_color2: int = 0
var skeleton_id: int = 0
