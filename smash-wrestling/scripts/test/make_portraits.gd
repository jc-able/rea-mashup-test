extends Node
## Renders character-select portraits of the 12 Smash 64 fighters (their own Smash "Wait" animation, frame 0)
## into res://assets/portraits/<kind>.png.  usage: Godot --path game --resolution 512x512 -- test=make_portraits
## Written in this run.


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/portraits"))
	var w := Node3D.new()
	add_child(w)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.1, 0.1, 0.14)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.55, 0.6)
	env.environment = e
	w.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, 30, 0)
	key.light_energy = 1.1
	w.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 200, 0)
	rim.light_energy = 0.6
	w.add_child(rim)
	var cam := Camera3D.new()
	cam.fov = 30.0
	w.add_child(cam)
	cam.current = true
	var out := []
	for c in Game.roster:
		var wr := Wrestler.new()
		w.add_child(wr)
		wr.setup(c, 0, true)
		e.background_color = Color(c["color"]).darkened(0.65)
		wr.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(-18)), Vector3.ZERO)
		if not wr.play_smash("Wait", {"blend": 0.0}):
			wr.pp.update(0.0)
		else:
			wr.smash.update(0.0)
		var h: float = wr.model.height_world
		cam.look_at_from_position(Vector3(0.0, h * 0.62, h * 2.7), Vector3(0, h * 0.5, 0))
		for i in 4:
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		var path := ProjectSettings.globalize_path("res://assets/portraits/%s.png" % c["kind"])
		img.save_png(path)
		out.append(path)
		wr.queue_free()
		await get_tree().process_frame
	print("\n".join(out))
	get_tree().quit()
