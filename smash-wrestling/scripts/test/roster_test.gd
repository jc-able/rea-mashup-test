extends Node
## Roster retarget check: all 12 Smash fighters lined up and posed with the same SvR 2011 clips.
## usage: Godot --path game --resolution 1800x620 -- test=roster_test out=/abs/dir
## Written in this run.

var out_dir := "user://roster_test"
var poses := [
	["tpose", "", 0],
	["idle", "STAT_1700_0", 0],
	["walk", "STAT_9900_0", 8],
	["strong_strike", "move:strong", 0],
	["lying", "STAT_0_0", 0],
	["getup", "STAT_20_0", 40],
	["turnbuckle_top", "STAT_156_0", 999],
]
var views := ["front", "side"]


func _ready() -> void:
	out_dir = Game.args.get("out", out_dir)
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()


func _run() -> void:
	var w := Node3D.new()
	add_child(w)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.16, 0.17, 0.2)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.6, 0.65)
	env.environment = e
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 25, 0)
	w.add_child(sun)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 10)
	floor.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.4, 0.4, 0.42)
	floor.material_override = fm
	w.add_child(floor)
	var cam := Camera3D.new()
	w.add_child(cam)
	cam.current = true
	var fighters := []
	var i := 0
	for c in Game.roster:
		var wr := Wrestler.new()
		w.add_child(wr)
		wr.setup(c, 0, true)
		wr.global_transform = Transform3D(Basis.IDENTITY, Vector3(((i % 6) - 2.5) * 1.5, 0, -6.0 * int(i / 6)))
		var lbl := Label3D.new()
		lbl.text = c["name"] + ("" if not wr.model.is_fallback else " (fallback)")
		lbl.font_size = 48
		lbl.pixel_size = 0.004
		lbl.position = Vector3(0, 2.25, 0)
		wr.add_child(lbl)
		fighters.append(wr)
		i += 1
	var log := []
	for pose in poses:
		for wr in fighters:
			var key: String = pose[1]
			if key == "":
				var ids := []
				for j in 21:
					ids.append(Quaternion.IDENTITY)
				wr.rig.apply(ids, Vector3(0, wr.rig.hip_height, 0))
				continue
			var clip: SwmClip
			if key.begins_with("move:"):
				clip = MotionDB.move_clip(MotionDB.slot(wr.kind, "strong", "strong_1"), 0)
			else:
				clip = MotionDB.clip(key)
			if clip == null:
				continue
			wr._play(clip, {"anchor": wr.global_transform, "blend": 0.0})
			var f := int(pose[2])
			if key.begins_with("move:"):
				var imp := MotionDB.impact_frames(MotionDB.slot(wr.kind, "strong", "strong_1"))
				f = int(imp[0]) if imp.size() > 0 else int(clip.frames * 0.45)
			wr.pp.t = float(mini(f, clip.frames - 1))
			wr.pp.update(0.0)
		for v in ["front_a", "front_b", "side_a", "side_b"]:
			var zrow := 0.0 if v.ends_with("_a") else -6.0
			for k in fighters.size():
				fighters[k].visible = (k < 6) == v.ends_with("_a")
			cam.fov = 40.0
			if v.begins_with("front"):
				cam.look_at_from_position(Vector3(0, 1.5, zrow + 13.0), Vector3(0, 0.95, zrow))
			else:
				cam.look_at_from_position(Vector3(-13.0, 1.5, zrow + 2.5), Vector3(0.0, 0.95, zrow))
			await get_tree().process_frame
			await get_tree().process_frame
			await get_tree().process_frame
			var path := "%s/roster_%s_%s.png" % [out_dir, pose[0], v]
			get_viewport().get_texture().get_image().save_png(path)
			log.append(path)
	for wr in fighters:
		log.append("%s fallback=%s size_k=%.2f hip_k=%.2f model_scale=%.3f bones=%d" % [wr.kind, wr.model.is_fallback,
			wr.size_k, wr.hip_k, wr.model.model_scale, wr.model.skeleton.get_bone_count()])
	var fl := FileAccess.open(out_dir + "/roster_test_log.txt", FileAccess.WRITE)
	for l in log:
		fl.store_line(l)
	fl.close()
	print("\n".join(log))
	get_tree().quit()
