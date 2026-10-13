class_name Arena
extends Node3D
## Arena: loads the recovered SvR 2011 arena (assets/arena/...) when present, otherwise builds a labeled
## blockout ring + arena with the same metrics. Also owns the titantron screen and the arena lights.

signal layout_applied

var using_svr_arena := false
var titantron_label: Label3D
var titantron_screen: MeshInstance3D
var tron_mat: StandardMaterial3D
var stage_lights: Array = []
var crowd_root: Node3D
var layout: Dictionary = {}

const ARENAS := {"smackdown": "SMACKDOWN", "raw": "RAW", "wrestlemania26": "WRESTLEMANIA XXVI"}
const PARTS := ["ring", "arena", "screens", "fx", "props", "crowd_lod100"]
var slug := "smackdown"
var SVR_ARENA_DIR := "res://assets/arena/smackdown"
## The arena was converted at 0.1 m per SvR game unit; the motion pipeline uses 0.0973633 m per unit (the earlier run's
## reference-skeleton convention incl. SvR's in-game wrestler scale). Scale the arena into motion metres.
const SVR_TO_MOTION := 0.0973633 / 0.1


func build() -> void:
	slug = String(Game.sel.get("arena", "smackdown"))
	if not ARENAS.has(slug):
		slug = "smackdown"
	SVR_ARENA_DIR = "res://assets/arena/" + slug
	_environment()
	var layout_path := SVR_ARENA_DIR + "/arena_layout.json"
	if Game.args.get("blockout_arena", "0") == "1":
		layout_path = "res://__none__"
	if FileAccess.file_exists(layout_path):
		layout = JSON.parse_string(FileAccess.get_file_as_string(layout_path))
		apply_layout(layout)
		using_svr_arena = _load_svr_models()
	if not using_svr_arena:
		_blockout_ring()
		_blockout_arena()
	else:
		_ropes_if_missing()
	_titantron()
	_lights()


func _environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.02, 0.02, 0.04)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.42, 0.42, 0.5)
	e.ambient_light_energy = 0.9
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.fog_enabled = false
	env.environment = e
	add_child(env)


## Layout JSON from tools/svr_arena (recovered metrics, metres at 0.1 m/unit) -> Ring constants in motion metres.
func apply_layout(l: Dictionary) -> void:
	var k := SVR_TO_MOTION
	Ring.MOVE_SCALE = k
	var v = func(sec: String, key: String, default):
		var d = l.get(sec, {}).get(key, null)
		if d is Dictionary and d.has("value"):
			return d["value"]
		return default
	Ring.MAT_Y = float(v.call("ring", "mat_top_y", 1.2)) * k
	Ring.HALF = float(v.call("ring", "half_width_inside_ropes", 2.88)) * k
	Ring.APRON = (float(v.call("ring", "apron_edge_half_width", 3.13)) - float(v.call("ring", "half_width_inside_ropes", 2.88))) * k
	var ropes = v.call("ring", "rope_heights_above_mat", [0.34, 0.76, 1.18])
	Ring.ROPE_Y = [float(ropes[0]) * k, float(ropes[1]) * k, float(ropes[2]) * k]
	var posts = v.call("ring", "posts", {})
	if posts is Dictionary and posts.has("centres_xz"):
		Ring.POST_HALF = absf(float(posts["centres_xz"][0][0])) * k
	if posts is Dictionary and posts.has("top_y"):
		Ring.POST_TOP = float(posts["top_y"]) * k - Ring.MAT_Y
	else:
		Ring.POST_TOP = 2.51 * k - Ring.MAT_Y
	Ring.BARRICADE = float(v.call("barricade", "side_inner_x", 7.0)) * k
	Ring.BARRICADE_NEAR_Z = float(v.call("barricade", "near_side_z", 9.4)) * k
	Ring.BARRICADE_FAR_Z = float(v.call("barricade", "stage_side_z", -9.589)) * k
	Ring.RAMP_GAP = float(v.call("barricade", "ramp_gap_half_width", 2.25)) * k
	Ring.RAMP_W = float(v.call("ramp", "width", 3.92)) * k
	Ring.STAGE_Y = float(v.call("stage", "top_y", 1.8)) * k
	var spawn = v.call("stage", "wrestler_spawn", [0.0, 1.8, -29.2])
	Ring.STAGE_Z = float(spawn[2]) * k
	var prof = v.call("ramp", "profile_z_y", [])
	Ring.RAMP_PROFILE = []
	for p in prof:
		Ring.RAMP_PROFILE.append([float(p[0]) * k, float(p[1]) * k])
	layout_applied.emit()


func _load_svr_models() -> bool:
	var ok := false
	for part in PARTS:
		var f := "%s_%s.glb" % [slug, part]
		var p := SVR_ARENA_DIR + "/" + f
		if not ResourceLoader.exists(p):
			continue
		var ps := load(p)
		if ps is PackedScene:
			var inst: Node3D = ps.instantiate()
			inst.scale = Vector3.ONE * Ring.MOVE_SCALE
			add_child(inst)
			if f.find("ring") >= 0:
				ok = true
			# SvR shows MoveCamOnly_* pieces (truss, roof, centre-hung TV) only in replay/move cameras
			for n in inst.find_children("MoveCamOnly_*", "", true, false):
				(n as Node3D).visible = false
	return ok


func _mat(c: Color, rough := 0.8, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _box(size: Vector3, pos: Vector3, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	(parent if parent else self).add_child(mi)
	return mi


func _cyl(r: float, h: float, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 10
	mi.mesh = cm
	mi.position = pos
	mi.rotation = rot
	mi.material_override = mat
	add_child(mi)
	return mi


func _blockout_ring() -> void:
	var h := Ring.HALF
	var y := Ring.MAT_Y
	var outer := h + Ring.APRON
	_box(Vector3(outer * 2, 0.12, outer * 2), Vector3(0, y - 0.06, 0), _mat(Color(0.86, 0.86, 0.84), 0.9))
	# apron skirt (SvR rings use show-coloured skirts; blockout uses dark red)
	_box(Vector3(outer * 2, y - 0.12, outer * 2 - 0.02), Vector3(0, (y - 0.12) * 0.5, 0), _mat(Color(0.35, 0.05, 0.06), 0.7))
	var post_mat := _mat(Color(0.75, 0.75, 0.78), 0.3, 0.8)
	var pad_mat := _mat(Color(0.1, 0.12, 0.6), 0.6)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var p := Vector3(sx * Ring.POST_HALF, 0, sz * Ring.POST_HALF)
			_cyl(0.07, y + Ring.POST_TOP + 0.1, Vector3(p.x, (y + Ring.POST_TOP + 0.1) * 0.5, p.z), post_mat)
			for ry in Ring.ROPE_Y:
				var pad := _box(Vector3(0.22, 0.24, 0.22), Vector3(p.x - sx * 0.12, y + ry, p.z - sz * 0.12), pad_mat)
				pad.rotation.y = PI / 4
	_build_ropes()
	# steps (two corners)
	var steps_mat := _mat(Color(0.25, 0.25, 0.28), 0.6, 0.3)
	for s in [[1, 1], [-1, -1]]:
		for i in 3:
			var hh := y * (i + 1) / 3.0
			_box(Vector3(0.9, hh, 0.45), Vector3(s[0] * (outer + 0.4 + 0.45 * (2 - i)), hh * 0.5, s[1] * (outer + 0.4)), steps_mat).rotation.y = PI / 4


func _build_ropes() -> void:
	var rope_mat := _mat(Color(0.85, 0.1, 0.1), 0.4)
	var c := Ring.POST_HALF - 0.12
	for ry in Ring.ROPE_Y:
		var yy: float = Ring.MAT_Y + ry
		for side in 4:
			var mi := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.03
			cm.bottom_radius = 0.03
			cm.height = c * 2
			cm.radial_segments = 6
			mi.mesh = cm
			mi.material_override = rope_mat
			match side:
				0:
					mi.position = Vector3(0, yy, c)
					mi.rotation = Vector3(0, 0, PI / 2)
				1:
					mi.position = Vector3(0, yy, -c)
					mi.rotation = Vector3(0, 0, PI / 2)
				2:
					mi.position = Vector3(c, yy, 0)
					mi.rotation = Vector3(PI / 2, 0, 0)
				3:
					mi.position = Vector3(-c, yy, 0)
					mi.rotation = Vector3(PI / 2, 0, 0)
			add_child(mi)


func _ropes_if_missing() -> void:
	if not bool(layout.get("ropes_in_model", false)):
		_build_ropes()


func _blockout_arena() -> void:
	var floor_mat := _mat(Color(0.08, 0.08, 0.1), 0.9)
	_box(Vector3(60, 0.1, 70), Vector3(0, -0.05, -8), floor_mat)
	var mat_mat := _mat(Color(0.12, 0.12, 0.14), 0.9)
	_box(Vector3(Ring.BARRICADE * 2, 0.02, Ring.BARRICADE * 2), Vector3(0, 0.01, 0), mat_mat)
	var bar_mat := _mat(Color(0.1, 0.1, 0.12), 0.5, 0.4)
	var b := Ring.BARRICADE
	_box(Vector3(b * 2, 1.1, 0.12), Vector3(0, 0.55, b), bar_mat)
	_box(Vector3(0.12, 1.1, b * 2), Vector3(b, 0.55, 0), bar_mat)
	_box(Vector3(0.12, 1.1, b * 2), Vector3(-b, 0.55, 0), bar_mat)
	var gap := Ring.RAMP_W * 0.5 + 0.5
	_box(Vector3(b - gap, 1.1, 0.12), Vector3(-(b + gap) * 0.5, 0.55, -b), bar_mat)
	_box(Vector3(b - gap, 1.1, 0.12), Vector3((b + gap) * 0.5, 0.55, -b), bar_mat)
	# ramp + stage
	var ramp_mat := _mat(Color(0.18, 0.18, 0.22), 0.6, 0.2)
	var ramp_len := absf(Ring.STAGE_Z) - b
	var ramp := _box(Vector3(Ring.RAMP_W, 0.3, ramp_len), Vector3(0, Ring.STAGE_Y * 0.5, -b - ramp_len * 0.5), ramp_mat)
	ramp.rotation.x = -atan2(Ring.STAGE_Y, ramp_len) * 0.0
	_box(Vector3(Ring.RAMP_W, Ring.STAGE_Y * 0.5, ramp_len), Vector3(0, Ring.STAGE_Y * 0.25, -b - ramp_len * 0.5), ramp_mat)
	_box(Vector3(16, Ring.STAGE_Y, 6), Vector3(0, Ring.STAGE_Y * 0.5, Ring.STAGE_Z - 3), _mat(Color(0.14, 0.14, 0.18), 0.5, 0.3))
	# crowd blockout: tiers of coloured boxes around the floor
	crowd_root = Node3D.new()
	add_child(crowd_root)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2011
	var tier_mat := _mat(Color(0.06, 0.06, 0.08), 0.9)
	for side in [[0, 1], [1, 0], [-1, 0]]:
		for tier in 6:
			var dist := b + 2.5 + tier * 1.4
			var hgt := 0.6 + tier * 0.9
			var len := 2 * (b + 4 + tier * 1.4)
			if side[1] != 0:
				_box(Vector3(len, 0.6, 1.2), Vector3(0, hgt, dist), tier_mat, crowd_root)
			else:
				_box(Vector3(1.2, 0.6, len), Vector3(side[0] * dist, hgt, 0), tier_mat, crowd_root)
			var n := int(len / 0.7)
			for i in n:
				if rng.randf() < 0.18:
					continue
				var t := -len * 0.5 + (i + 0.5) * len / n
				var col := Color.from_hsv(rng.randf(), 0.45, 0.35 + rng.randf() * 0.35)
				var pos := Vector3(t, hgt + 0.65, dist) if side[1] != 0 else Vector3(side[0] * dist, hgt + 0.65, t)
				var fan := _box(Vector3(0.42, 0.75 + rng.randf() * 0.2, 0.3), pos, _mat(col, 0.9), crowd_root)
				fan.set_meta("phase", rng.randf() * TAU)


func _titantron() -> void:
	var y := Ring.STAGE_Y + 5.5
	var z := Ring.STAGE_Z - 5.8
	var x := 0.0
	var size := Vector2(12.0, 6.75)
	if layout.has("titantron"):
		var t = layout["titantron"].get("main_titantron", {})
		if t is Dictionary and t.has("value"):
			t = t["value"]
		if t is Dictionary and t.has("centre"):
			var c: Array = t["centre"]
			x = float(c[0]) * Ring.MOVE_SCALE
			y = float(c[1]) * Ring.MOVE_SCALE
			z = float(c[2]) * Ring.MOVE_SCALE + 0.15
			if t.has("size"):
				size = Vector2(float(t["size"][0]), float(t["size"][1])) * Ring.MOVE_SCALE
	titantron_screen = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size
	titantron_screen.mesh = qm
	titantron_screen.position = Vector3(x, y, z)
	tron_mat = StandardMaterial3D.new()
	tron_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tron_mat.albedo_color = Color(0.05, 0.05, 0.12)
	titantron_screen.material_override = tron_mat
	add_child(titantron_screen)
	titantron_label = Label3D.new()
	titantron_label.text = "SMASH WRESTLING"
	titantron_label.font_size = 220
	titantron_label.outline_size = 24
	titantron_label.pixel_size = 0.012
	titantron_label.position = Vector3(x, y, z + 0.05)
	titantron_label.modulate = Color(1, 0.85, 0.2)
	add_child(titantron_label)


func set_titantron(text: String, col: Color) -> void:
	if titantron_label:
		titantron_label.text = text
		titantron_label.modulate = col.lightened(0.35)
	if tron_mat:
		tron_mat.albedo_color = col.darkened(0.55)


func _lights() -> void:
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-62, 25, 0)
	key.light_energy = 0.9
	key.shadow_enabled = true
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-35, 200, 0)
	fill.light_energy = 0.35
	add_child(fill)
	for i in 4:
		var sp := SpotLight3D.new()
		var a := i * PI / 2 + PI / 4
		sp.position = Vector3(cos(a) * 6, 9, sin(a) * 6)
		sp.look_at_from_position(sp.position, Vector3(0, Ring.MAT_Y, 0))
		sp.spot_angle = 30
		sp.spot_range = 20
		sp.light_energy = 2.0
		add_child(sp)
	for i in 2:
		var sl := SpotLight3D.new()
		sl.position = Vector3(-3 + i * 6, Ring.STAGE_Y + 8, Ring.STAGE_Z + 6)
		sl.look_at_from_position(sl.position, Vector3(0, Ring.STAGE_Y, Ring.STAGE_Z))
		sl.spot_angle = 25
		sl.spot_range = 25
		sl.light_energy = 0.0
		sl.light_color = Color(1, 0.9, 0.7)
		add_child(sl)
		stage_lights.append(sl)


func set_stage_lights(e: float, col: Color = Color(1, 0.9, 0.7)) -> void:
	for sl in stage_lights:
		sl.light_energy = e
		sl.light_color = col


func _process(_dt: float) -> void:
	if crowd_root and crowd_root.get_child_count() > 0:
		var t := Time.get_ticks_msec() * 0.001
		var i := 0
		for c in crowd_root.get_children():
			i += 1
			if i % 3 != 0 or not c.has_meta("phase"):
				continue
			c.position.y += sin(t * 6.0 + float(c.get_meta("phase"))) * 0.002
