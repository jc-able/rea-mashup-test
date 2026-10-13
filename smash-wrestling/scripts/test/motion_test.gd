extends SceneTree
## Motion pipeline check: plays SvR clips (paired moves with the fitted placement) on two procedural mannequins and
## saves screenshots.  usage:
##   Godot --path game -s res://scripts/test/motion_test.gd -- moves=5024,4680 frames=0,15,30,45 out=/abs/dir
## (run with a window so it renders).  Written in this run.

var moves_db: Dictionary
var lib: Dictionary
var out_dir := "user://motion_test"
var frames := [0, 15, 30, 45]
var move_ids := ["5024"]
var gpairs := []   # [name, theta_deg, d_m]
var cam_dist := 2.6
var cam: Camera3D


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() < 2:
			continue
		match kv[0]:
			"moves":
				move_ids = Array(kv[1].split(","))
			"frames":
				frames = []
				for x in kv[1].split(","):
					frames.append(int(x))
			"out":
				out_dir = kv[1]
			"pairs":
				for x in kv[1].split(","):
					var p := x.split(":")
					gpairs.append([p[0], float(p[1]), float(p[2])])
				move_ids = []
			"camdist":
				cam_dist = float(kv[1])
	DirAccess.make_dir_recursive_absolute(out_dir)
	moves_db = JSON.parse_string(FileAccess.get_file_as_string("res://data/moves.json"))["moves"]
	lib = JSON.parse_string(FileAccess.get_file_as_string("res://data/motion_library.json"))
	_run.call_deferred()


func _make_world() -> Node3D:
	var w := Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.12, 0.13, 0.16)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.environment = e
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	w.add_child(sun)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(8, 8)
	floor.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.35, 0.35, 0.38)
	floor.material_override = fm
	w.add_child(floor)
	cam = Camera3D.new()
	w.add_child(cam)
	cam.look_at_from_position(Vector3(cam_dist, 1.3, 0.6), Vector3(0, 0.6, 0.6))
	return w


func _mk(w: Node3D, tint: Color) -> Array:
	var holder := Node3D.new()
	w.add_child(holder)
	var m := Mannequin.new()
	m.tint = tint
	holder.add_child(m)
	m.build()
	var rig := RetargetRig.new()
	rig.setup(m.skeleton, m.spec)
	var pp := PosePlayer.new()
	pp.setup(rig, holder)
	return [holder, pp]


func _run() -> void:
	var w := _make_world()
	var a := _mk(w, Color(0.9, 0.9, 0.9))
	var v := _mk(w, Color(0.95, 0.75, 0.3))
	var log := []
	for mid in move_ids:
		var m: Dictionary = moves_db.get(mid, {})
		if m.is_empty():
			log.append("move %s missing" % mid)
			continue
		var ca := SwmClip.load_clip(lib[m["clips"]["0"]]["file"])
		var cv: SwmClip = null
		if m["clips"].has("1"):
			cv = SwmClip.load_clip(lib[m["clips"]["1"]]["file"])
		var anchor := Transform3D.IDENTITY
		a[1].play(ca, {"anchor": anchor, "blend": 0.0})
		if cv:
			var pair: Dictionary = m.get("pair", {}) if m.get("pair") != null else {}
			var d := float(pair.get("d_m", 1.2))
			var th := deg_to_rad(float(pair.get("theta_deg", 180)))
			var va := anchor * Transform3D(Basis(Vector3.UP, th), Vector3(0, 0, d))
			v[1].play(cv, {"anchor": va, "blend": 0.0})
		for f in frames:
			a[1].t = float(f)
			a[1].update(0.0)
			if cv:
				v[1].t = float(f)
				v[1].update(0.0)
			await process_frame
			await process_frame
			var img := root.get_texture().get_image()
			var path := "%s/move_%s_f%03d.png" % [out_dir, mid, f]
			img.save_png(path)
			var ha: Vector3 = a[1].cur_hips
			var hv: Vector3 = v[1].cur_hips if cv else Vector3.ZERO
			log.append("%s %s f%d hipsA %s hipsV %s" % [mid, m["name"], f, ha, hv])
	var gen: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/generic_clips.json"))
	for gp in gpairs:
		var roles: Dictionary = gen["roles"]
		var ca := SwmClip.load_clip(lib[roles[gp[0] + "_a"]["clip"]]["file"])
		var cv := SwmClip.load_clip(lib[roles[gp[0] + "_v"]["clip"]]["file"])
		a[1].play(ca, {"anchor": Transform3D.IDENTITY, "blend": 0.0})
		var va := Transform3D(Basis(Vector3.UP, deg_to_rad(gp[1])), Vector3.ZERO) * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0))
		va = Transform3D(Basis.IDENTITY, Vector3(0, 0, gp[2])) * Transform3D(Basis(Vector3.UP, deg_to_rad(gp[1])), Vector3.ZERO)
		v[1].play(cv, {"anchor": va, "blend": 0.0})
		for f in frames:
			a[1].t = float(f)
			a[1].update(0.0)
			v[1].t = float(f)
			v[1].update(0.0)
			await process_frame
			await process_frame
			root.get_texture().get_image().save_png("%s/pair_%s_t%d_d%.2f_f%03d.png" % [out_dir, gp[0], int(gp[1]), gp[2], f])
	var fl := FileAccess.open(out_dir + "/motion_test_log.txt", FileAccess.WRITE)
	for l in log:
		fl.store_line(l)
	fl.close()
	print("\n".join(log))
	quit()
