## Pose Lab: no stage; each fighter is created through Ftmanager (demo kind) and animated by the
## ported status/figatree code. Left: retargeted wrestler with the SSB skeleton + hurtboxes/hitboxes
## overlaid; right: the SSB debug skeleton alone (same motion, same frame).
## Keys: Left/Right fighter, Up/Down motion, Space pause, Period step, F1 overlay, F2 side/3-4 view.
## Command line (after "--"): fighter=N motion=Name capture_dir=<dir> capture_motions=Wait,Run,...
##   (captures poselab_<slug>_<motion>.png for every fighter and listed motion, then quits)
extends Node3D

const RU = preload("res://scripts/render/RenderUtil.gd")
const PD = preload("res://scripts/render/PoseDriver.gd")
const FighterRenderer = preload("res://scripts/render/FighterRenderer.gd")
const DebugOverlay = preload("res://scripts/render/DebugOverlay.gd")

## frame shown in captures (frames after entering the motion)
const CAPTURE_FRAME := {"Wait": 20, "Walk": 14, "Run": 12, "Jump": 8, "JumpAerial": 10, "Squat": 6, "Jab": 3,
	"DashAttack": 8, "FTilt": 6, "UTilt": 8, "DTilt": 6, "FSmash": 18, "USmash": 12, "DSmash": 10, "NAir": 6,
	"FAir": 10, "BAir": 8, "UAir": 8, "DAir": 12, "Grab": 8, "Shield": 4, "Damage": 6, "Taunt": 30,
	"SpecialN": 16, "SpecialHi": 10, "SpecialLw": 10}

var fkind := 0
var motion_idx := 0
var paused := false
var view_34 := false
var overlay_on := true
var fa = null
var fb = null
var ra
var rb
var debug_a
var debug_b
var camera: Camera3D
var label: Label
var frame := 0
var _capture_queue: Array = []
var _capture_dir := ""
var _acc := 0.0

func _ready() -> void:
	Engine.physics_ticks_per_second = 60
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		if kv[0] == "fighter":
			fkind = int(kv[1])
		elif kv[0] == "motion":
			for i in PD.MOTIONS.size():
				if PD.MOTIONS[i][0] == kv[1]:
					motion_idx = i
		elif kv[0] == "capture_dir":
			_capture_dir = kv[1]
		elif kv[0] == "capture_motions":
			for fk in 12:
				for m in kv[1].split(","):
					_capture_queue.append([fk, m])
	_setup_world()
	debug_a = DebugOverlay.new()
	add_child(debug_a)
	debug_a.fill_alpha = 0.25
	debug_b = DebugOverlay.new()
	add_child(debug_b)
	debug_b.fill_alpha = 0.5
	if not _capture_queue.is_empty():
		_next_capture()
	else:
		_load()

func _setup_world() -> void:
	camera = Camera3D.new()
	camera.fov = 30.0
	camera.current = true
	add_child(camera)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.17, 0.19, 0.24)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.78, 0.85)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -30, 0)
	key.light_energy = 1.1
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-10, 140, 0)
	fill.light_energy = 0.35
	add_child(fill)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	floor_mi.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.32, 0.34, 0.38)
	fm.roughness = 0.9
	floor_mi.material_override = fm
	add_child(floor_mi)
	var grid := MeshInstance3D.new()
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(-20, 21):
		var c := Color(0.45, 0.47, 0.52) if i % 5 != 0 else Color(0.6, 0.62, 0.68)
		im.surface_set_color(c)
		im.surface_add_vertex(Vector3(i, 0.002, -20))
		im.surface_set_color(c)
		im.surface_add_vertex(Vector3(i, 0.002, 20))
		im.surface_set_color(c)
		im.surface_add_vertex(Vector3(-20, 0.002, i))
		im.surface_set_color(c)
		im.surface_add_vertex(Vector3(20, 0.002, i))
	im.surface_end()
	grid.mesh = im
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.vertex_color_use_as_albedo = true
	grid.material_override = gm
	add_child(grid)
	var cl := CanvasLayer.new()
	add_child(cl)
	label = Label.new()
	label.position = Vector2(16, 12)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 6)
	cl.add_child(label)

func _load() -> void:
	if ra != null:
		ra.queue_free()
		rb.queue_free()
	Sim.reset()
	fa = PD.make_fighter(fkind, Vector3.ZERO, 1, 0)
	var info: Dictionary = RU.roster().get(fkind, {})
	ra = FighterRenderer.new()
	add_child(ra)
	ra.setup(fa)
	var h: float = ra.retarget.standing_height if ra.retarget != null else 400.0
	fb = PD.make_fighter(fkind, Vector3(h * 1.05, 0, 0), 1, 1)
	rb = FighterRenderer.new()
	add_child(rb)
	rb.setup(fb)
	rb.show_model = false
	rb.ring.visible = false
	ra.tag.visible = false
	rb.tag.visible = false
	_set_motion()

func _set_motion() -> void:
	var label_name: String = PD.MOTIONS[motion_idx][0]
	var sid := PD.status_for(fkind, label_name)
	if sid < 0:
		sid = SSBDefs.nFTCommonStatusWait
	PD.set_status(fa, sid)
	PD.set_status(fb, sid)
	frame = 0

func _physics_process(_delta: float) -> void:
	if fa == null:
		return
	if not paused:
		_step()

func _step() -> void:
	var ended_a := PD.advance(fa)
	PD.advance(fb)
	frame += 1
	if ended_a:
		_set_motion()

func _process(delta: float) -> void:
	if fa == null:
		return
	for r in [ra, rb]:
		r.update(delta)
	ra.tag.visible = false
	rb.tag.visible = false
	rb.ring.visible = false
	debug_a.visible = overlay_on
	debug_a.show_boxes = true
	debug_a.show_skeleton = true
	if overlay_on:
		debug_a.update({fa: ra}, false)
	debug_b.show_boxes = true
	debug_b.show_skeleton = true
	debug_b.update({fb: rb}, true)
	_update_camera()
	var info: Dictionary = RU.roster().get(fkind, {})
	var rt = ra.retarget
	label.text = "POSE LAB  %s (SSB %s)  motion: %s  frame %d%s\nscale k=%.3f  standing %.0f u  hips %.0f u\n[Left/Right] fighter  [Up/Down] motion  [Space] pause  [.] step  [F1] overlay  [F2] view" % [
		info.get("name", "?"), info.get("ssb64", "?"), PD.MOTIONS[motion_idx][0], frame, "  (paused)" if paused else "",
		rt.scale_k if rt else 0.0, rt.standing_height if rt else 0.0, rt.hip_height if rt else 0.0]

func _update_camera() -> void:
	var h: float = ra.retarget.standing_height if ra.retarget != null else 400.0
	var center := Vector3(h * 0.52, h * 0.5, 0) * RU.S
	var dist := h * RU.S * 3.1
	var dir := Vector3(-0.18, 0.14, 1).normalized()
	if view_34:
		dir = Vector3(-0.45, 0.22, 1).normalized()
	camera.look_at_from_position(center + dir * dist, center, Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	match event.keycode:
		KEY_RIGHT:
			fkind = (fkind + 1) % 12
			_load()
		KEY_LEFT:
			fkind = (fkind + 11) % 12
			_load()
		KEY_UP:
			motion_idx = (motion_idx + PD.MOTIONS.size() - 1) % PD.MOTIONS.size()
			_set_motion()
		KEY_DOWN:
			motion_idx = (motion_idx + 1) % PD.MOTIONS.size()
			_set_motion()
		KEY_SPACE:
			paused = not paused
		KEY_PERIOD:
			_step()
		KEY_F1:
			overlay_on = not overlay_on
		KEY_F2:
			view_34 = not view_34

# --- automated evidence capture -----------------------------------------------------------
func _next_capture() -> void:
	if _capture_queue.is_empty():
		get_tree().quit()
		return
	var job: Array = _capture_queue.pop_front()
	var new_fk: int = job[0]
	var mname: String = job[1]
	for i in PD.MOTIONS.size():
		if PD.MOTIONS[i][0] == mname:
			motion_idx = i
	if new_fk != fkind or fa == null:
		fkind = new_fk
		_load()
	else:
		_set_motion()
	paused = true
	var n: int = CAPTURE_FRAME.get(mname, 10)
	for i in n:
		_step()
	_process(0.0)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var info: Dictionary = RU.roster().get(fkind, {})
	var path := "%s/poselab_%s_%s.png" % [_capture_dir, info.get("slug", str(fkind)), mname]
	get_viewport().get_texture().get_image().save_png(path)
	print("captured ", path)
	_next_capture.call_deferred()
