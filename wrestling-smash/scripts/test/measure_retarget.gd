## Headless tool: measures every fighter's Wait pose (frame 0, lr=+1) with the ported engine and
## stores standing/hip heights in res://data/retarget_map.json ("measured"), then checks that each
## wrestler rig can be retargeted (loads the GLB, runs Retarget.setup + one apply).
##   Godot --headless --path game_check -s res://scripts/test/measure_retarget.gd
extends SceneTree

const PD = preload("res://scripts/render/PoseDriver.gd")
const RT = preload("res://scripts/render/Retarget.gd")
const WL = preload("res://scripts/render/WrestlerLibrary.gd")
const RU = preload("res://scripts/render/RenderUtil.gd")

func _initialize() -> void:
	var path := "res://data/retarget_map.json"
	var md: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var check_rigs := not ("--no-rigs" in OS.get_cmdline_user_args())
	for fk in 12:
		Sim.reset()
		var entry: Dictionary = md.fighters[str(fk)]
		var fp = PD.make_fighter(fk)
		PD.set_status(fp, SSBDefs.nFTCommonStatusWait)
		var m := PD.measure(fp, int(entry.roles.hips))
		entry["measured"] = m
		var line := "fk%2d %-8s Wait: standing %.1f hips %.1f head_joint %.1f" % [fk, entry.data, m.standing_height, m.hip_height, m.head_joint_height]
		if check_rigs:
			var slug: String = entry.slug
			var inst := WL.instantiate(slug)
			var skel := WL.find_skeleton(inst) if inst != null else null
			RT._map = md
			var rt := RT.new()
			var okk := rt.setup(fp, inst, skel, WL.meta(slug)) if skel != null else false
			if okk:
				var jw := []
				jw.resize(SSBDefs.FTPARTS_JOINT_NUM_MAX)
				RU.fighter_world(fp, jw)
				rt.apply(jw)
				var head := rt.bone_world("atama")
				var lfoot := rt.bone_world("l_ashi")
				line += " | rig ok bones=%d mapped=%d k=%.3f hipratio=%.2f head_y=%.1f lfoot_y=%.1f" % [skel.get_bone_count(), rt.debug_info.mapped, rt.scale_k, rt.hip_ratio, head.y / RU.S, lfoot.y / RU.S]
			else:
				line += " | RIG SETUP FAILED"
			if inst != null:
				inst.free()
		print(line)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(md, " ", false))
	f.close()
	print("wrote ", path)
	quit(0)
