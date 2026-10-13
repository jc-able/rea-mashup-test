class_name EntranceDirector
extends Node
## Ring entrances played from the recovered SvR 2011 entrance data (evt/Nyujyo*.pac, decoded by tools/svr_entrance):
## each fighter performs its template superstar's entrance - parts INTRO / STAGE / RAMP / RING-IN / RING - with the
## game's own body motion (retargeted) and camera tracks. Rules recovered from the game code (helper C, REA-checked):
## a part lasts as long as its camera record; one camera role is picked at random for the whole entrance; the
## wrestler is hidden during INTRO.  Custom: titantron text, pyro timing (data not decoded), small-fighter re-aim,
## the opponent entering first, the fallback entrance when no data exists.

const ARENA_TO_WORLD := 0.973633
const FPS := 30.0

var m: Match
var data: Dictionary = {}
var queue: Array = []
var cur: Wrestler
var spec: Dictionary = {}
var parts: Array = []
var part_i := -1
var part_f := 0.0
var part_frames := 1
var role := 0
var cam_rows: Array = []
var cam_json: Dictionary = {}
var clip: SwmClip
var done := false
var _pyro_on_top := false
var _first_visible := true
var fallback := false
var t := 0.0
var log_lines: PackedStringArray = []
var only_p1 := false
signal part_started(kind: String, part: String, frames: int)
signal finished_all


func setup(match_: Match) -> void:
	m = match_
	if FileAccess.file_exists("res://data/entrances.json"):
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/entrances.json"))
		if d is Dictionary:
			data = d


func start() -> void:
	# SvR order (custom choice here): the opponent comes out first, then player 1
	queue = [m.wrestlers[0]] if only_p1 else [m.wrestlers[1], m.wrestlers[0]]
	for w in m.wrestlers:
		w.visible = false
	m.hud.set_visible_match(false)
	_next_fighter()


func skip() -> void:
	if done:
		return
	done = true
	for w in m.wrestlers:
		w.visible = true
	m.arena.set_stage_lights(0.0)
	m.hud.lower_third("", Color.WHITE)
	m.on_entrances_done()


func _next_fighter() -> void:
	if cur:
		# park the finished superstar in a corner while the next one comes out
		var c := Ring.corners()[1] as Vector3 if cur == m.wrestlers[0] else Ring.corners()[2] as Vector3
		cur.visible = true
		cur.teleport(Vector3(c.x, Ring.MAT_Y, c.z), atan2(-c.x, -c.z))
	if queue.is_empty():
		done = true
		m.arena.set_stage_lights(0.0)
		m.hud.lower_third("", Color.WHITE)
		finished_all.emit()
		m.on_entrances_done()
		return
	cur = queue.pop_front()
	spec = data.get("characters", {}).get(cur.kind, {})
	parts = spec.get("parts", [])
	fallback = parts.is_empty()
	role = randi() % 2      # SvR picks one camera role per entrance (byte table & 1), falling back to role 0
	part_i = -1
	_first_visible = true
	_pyro_on_top = false
	m.arena.set_titantron(cur.display_name.to_upper(), cur.color)
	m.arena.set_stage_lights(3.0, cur.color.lightened(0.5))
	var ename := String(Game.def_of(cur.kind).get("template_name", spec.get("entrance_name", ""))).replace("_", " ")
	m.hud.lower_third("%s   -   entrance of SvR 2011's %s        (Enter / Esc: skip entrances)" % [cur.display_name.to_upper(), ename if ename != "" else "?"], cur.color, 28)
	_log("entrance %s: SvR id %s (%s), camera role %d, %d parts" % [cur.display_name, spec.get("entrance_id", "-"), ename, role, parts.size()])
	if fallback:
		_fallback_entrance()
		return
	_next_part()


func _next_part() -> void:
	part_i += 1
	if part_i >= parts.size():
		_next_fighter()
		return
	var p: Dictionary = parts[part_i]
	part_f = 0.0
	cam_json = JSON.parse_string(FileAccess.get_file_as_string(String(p["cam"])))
	var roles: Array = cam_json.get("roles", [])
	var r: Dictionary = roles[0]
	for rr in roles:
		if int(rr["role"]) == role:
			r = rr
	cam_rows = r["rows"]
	part_frames = maxi(1, int(r["frames"]))
	clip = SwmClip.load_clip(String(p["clip"]))
	var visible := bool(p.get("visible", true))
	cur.visible = visible
	if visible and clip:
		var k := ARENA_TO_WORLD
		cur.scripted_play(clip, {"anchor": Transform3D.IDENTITY, "blend": 0.0 if _first_visible else 0.12,
			"kh": k, "kv": cur.hip_k * k, "ks": k, "floor_y": 0.0})
		_first_visible = false
		if String(p["part"]) == "stage":
			_pyro(Vector3(0, Ring.STAGE_Y, Ring.STAGE_Z + 2.0))
	_log("  part %s: %d frames (clip %d)" % [p["part"], part_frames, clip.frames if clip else -1])
	part_started.emit(cur.kind, String(p["part"]), part_frames)


func tick(dt: float) -> void:
	if done or cur == null:
		return
	t += dt
	if fallback:
		_fallback_tick(dt)
		return
	part_f += dt * FPS
	if part_f >= float(part_frames):
		_next_part()
		return
	_apply_camera(part_f)
	# pyro when the superstar stands on the turnbuckle during the ring part (cue data not decoded: custom trigger)
	if cur.visible and String(parts[part_i]["part"]) == "inring" and not _pyro_on_top:
		if cur.pp.cur_hips.y > Ring.MAT_Y + 1.25 * cur.hip_k:
			_pyro_on_top = true
			for c in Ring.corners():
				_pyro(Vector3((c as Vector3).x * 1.15, Ring.MAT_Y + Ring.POST_TOP, (c as Vector3).z * 1.15))


func _apply_camera(f: float) -> void:
	if cam_rows.is_empty():
		return
	var i0 := clampi(int(f), 0, cam_rows.size() - 1)
	var i1 := mini(i0 + 1, cam_rows.size() - 1)
	var u := f - float(i0)
	var a: Array = cam_rows[i0]
	var b: Array = cam_rows[i1]
	var k := ARENA_TO_WORLD
	var pos := Vector3(a[0], a[1], a[2]).lerp(Vector3(b[0], b[1], b[2]), u) * k
	var q := Quaternion(a[3], a[4], a[5], a[6]).slerp(Quaternion(b[3], b[4], b[5], b[6]), u)
	var fov := lerpf(float(a[7]), float(b[7]), u)
	var look := Vector3(a[8], a[9], a[10]).lerp(Vector3(b[8], b[9], b[10]), u) * k
	var basis := Basis(q)
	# re-aim for fighters shorter than an SvR superstar (helper C's recipe, Custom): lower the look-at by the
	# body height the fighter lacks above its support, keeping the authored camera position and roll
	if cur.visible and clip and cur.hip_k < 0.97:
		var fi := clampi(int(f), 0, clip.frames - 1)
		var sup := clip.support_at(float(fi)) * k
		var hy := clip.hips[fi].y * k
		var drop := (1.0 - cur.hip_k) * maxf(hy - sup, 0.0)
		var look2 := look - Vector3(0, drop, 0)
		var d0 := (look - pos).normalized()
		var d1 := (look2 - pos).normalized()
		if d0.dot(d1) < 0.99999:
			basis = Basis(Quaternion(d0, d1)) * basis
	# Custom: SvR frames tight face close-ups for ~1.9 m superstars; widen narrow shots so the low-poly
	# Smash heads read as characters rather than filling the screen
	if fov < 26.0:
		fov = minf(fov * 1.55, 34.0)
	m.cam.set_manual(Transform3D(basis, pos), fov)


func _pyro(p: Vector3) -> void:
	FX.pyro(m, p, cur.color)
	m.sfx.pyro()
	m.sfx.crowd_pop()


func _log(s: String) -> void:
	log_lines.append(s)
	m._log(s)


# ------------------------------------------------------------------------------------------ fallback (no data)
var _fb_step := ""
var _fb_t := 0.0


func _fallback_entrance() -> void:
	# Fallback / blockout: template taunt on the stage, walk down the ramp, ring-in clip
	_fb_step = "stage"
	_fb_t = 0.0
	cur.visible = true
	cur.in_ring = false
	cur.floor_level = Ring.STAGE_Y
	cur.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, Ring.STAGE_Y, Ring.STAGE_Z))
	var c := MotionDB.move_clip(MotionDB.slot(cur.kind, "taunt", "taunt2"), 0)
	if c:
		cur.scripted_play(c, {"blend": 0.0, "align": "keep", "floor_y": Ring.STAGE_Y})
	m.cam.set_script_shot(Vector3(0, Ring.STAGE_Y + 1.6, Ring.STAGE_Z + 7.5), Vector3(0, Ring.STAGE_Y + 1.2, Ring.STAGE_Z), 55.0)


func _fallback_tick(dt: float) -> void:
	_fb_t += dt
	match _fb_step:
		"stage":
			if cur.pp.finished or _fb_t > 6.0:
				_fb_step = "ramp"
				cur.scripted_play(MotionDB.role("walk_f"), {"loop": true, "blend": 0.3, "align": "pelvis"})
		"ramp":
			var to := Vector3(0, 0, -(Ring.HALF + Ring.APRON + 0.6)) - cur.global_position
			to.y = 0
			if to.length() < 0.15 or _fb_t > 20.0:
				_next_fighter()
				return
			var p := cur.global_position + to.normalized() * minf(1.6 * dt, to.length())
			p.y = Ring.ramp_y(p.z)
			cur.floor_level = p.y
			cur.global_position = p
			var hp := cur.hips()
			m.cam.set_script_shot(hp + Vector3(2.8, 0.9, 4.2), hp + Vector3(0, 0.2, -1.0), 50.0)
