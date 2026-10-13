## Port of FTMotionScript (src/ft/fttypes.h): a running motion (hitbox/event) script.
## C layout: { f32 script_wait; u32 *p_script; s32 script_id; void *p_goto[1]; s32 loop_count[4]; }
## p_goto[] and loop_count[] are contiguous, so the game indexes them as ONE shared stack:
##   p_goto[i] == stack[i]   and   loop_count[i] == stack[i + 1]
## (loops push a return position and a count, subroutines push a return position).
class_name FTMotionScript
extends RefCounted

var script_wait: float = 0.0
var p_script: MotionPtr = null      # null == NULL
var script_id: int = 0
var stack: Array = [null, 0, 0, 0, 0]

func get_goto(i: int):
	return stack[i]

func set_goto(i: int, v) -> void:
	stack[i] = v

func get_loop_count(i: int) -> int:
	return stack[i + 1]

func set_loop_count(i: int, v: int) -> void:
	stack[i + 1] = v

func copy_from(o: FTMotionScript) -> void:
	script_wait = o.script_wait
	p_script = o.p_script.dup() if o.p_script != null else null
	script_id = o.script_id
	for i in stack.size():
		var v = o.stack[i]
		stack[i] = v.dup() if v is MotionPtr else v
