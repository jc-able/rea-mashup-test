## 1:1 port of src/ft/ftanimend.c (ssb-decomp-re): "when the animation ends, go to status X" helpers.
class_name Ftanimend
extends Port

## 0x800D9480
## proc_status: Callable taking (fighter_gobj) (C: void (*proc_status)(GObj*)).
static func ftAnimEndCheckSetStatus(fighter_gobj, proc_status: Callable) -> int:
	if fighter_gobj.anim_frame <= 0.0:
		proc_status.call(fighter_gobj)

		return TRUE
	else:
		return FALSE

## 0x800D94C4
static func ftAnimEndSetWait(fighter_gobj) -> void:
	ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommonwait, &"ftCommonWaitSetStatus"))

## 0x800D94E8
static func ftAnimEndSetFall(fighter_gobj) -> void:
	ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommonfall, &"ftCommonFallSetStatus"))
