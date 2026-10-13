## Prints SsbTiming (presentation retiming data) for a fighter's motions, to compare with the
## frame data measured through the engine (evidence/framedata).
##   Godot --headless --path game -s res://scripts/test/test_ssb_timing.gd -- [fkind] [filter]
extends SceneTree

const SsbTiming = preload("res://scripts/render/SsbTiming.gd")
const PoseDriver = preload("res://scripts/render/PoseDriver.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var fk := int(args[0]) if args.size() > 0 else 0
	var filt := args[1] if args.size() > 1 else ""
	var fp = PoseDriver.make_fighter(fk)
	var arr: Array = fp.data.mainmotion
	for mid in arr.size():
		var md = arr[mid]
		if md == null:
			continue
		var nm := str(md.get("name", ""))
		if filt != "" and not nm.containsn(filt):
			continue
		var info: Dictionary = SsbTiming.motion_info(fp, mid)
		print("%3d %-28s len %5.1f loops %-5s hit %5.1f..%5.1f throw %5.1f flag2 %5.1f" % [mid, nm, info.length, str(info.loops), info.hit_first, info.hit_last, info.throw, info.flag2])
	quit(0)
