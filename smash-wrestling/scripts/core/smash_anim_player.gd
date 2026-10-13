class_name SmashAnimPlayer
extends RefCounted
## Plays a fighter's OWN Super Smash Bros. 64 animations (baked from the ROM figatree data by tools/smash_models:
## absolute parent-relative joint rotations at 60 fps) directly on the Skeleton3D. Used for taunts (Appeal),
## victory poses (Win1-3), the dizzy state (FuraFura) and entrance flourishes (Entry).  Written in this run.

var skel: Skeleton3D
var anims: Dictionary = {}
var bone_of := {}           # "j05" -> bone index
var cur: Dictionary = {}
var cur_name := ""
var t := 0.0
var loop := false
var finished := true
var speed := 1.0
var _snap_rot: Array = []
var _snap_pos: Array = []
var _blend := 0.0
var _blend_t := 0.0
var hips_bone := -1
var yaw_fix := Quaternion.IDENTITY   # SSB64 idle/taunt poses turn toward Smash's side camera (hips_yaw_deg)
var root_bone := 0


func setup(skeleton: Skeleton3D, data: Dictionary) -> void:
	skel = skeleton
	anims = data.get("animations", {})
	for i in skel.get_bone_count():
		var n := skel.get_bone_name(i)
		var key := n.substr(0, 3)
		bone_of[key] = i
		bone_of[n] = i
		if skel.get_bone_parent(i) < 0:
			root_bone = i


func has(name: String) -> bool:
	return anims.has(name)


func play(name: String, opts: Dictionary = {}) -> bool:
	if not anims.has(name):
		return false
	cur = anims[name]
	cur_name = name
	t = 0.0
	loop = bool(opts.get("loop", cur.get("loop", false)))
	speed = float(opts.get("speed", 1.0))
	finished = false
	# blend from whatever pose the skeleton shows now
	var n := skel.get_bone_count()
	_snap_rot.resize(n)
	_snap_pos.resize(n)
	for i in n:
		_snap_rot[i] = skel.get_bone_pose_rotation(i)
		_snap_pos[i] = skel.get_bone_pose_position(i)
	_blend = float(opts.get("blend", 0.25))
	_blend_t = 0.0
	# face the wrestler's forward (+Z) instead of the side-view camera: rotate the root by -yaw (frame 0)
	yaw_fix = Quaternion.IDENTITY
	var hy = cur.get("hips_yaw_deg", null)
	if bool(opts.get("face_forward", true)) and hy is Dictionary and hy.has("frame0"):
		yaw_fix = Quaternion(Vector3.UP, deg_to_rad(-float(hy["frame0"])))
	return true


func frames() -> int:
	return int(cur.get("frames", 1))


func progress() -> float:
	return clampf(t / maxf(float(frames() - 1), 1.0), 0.0, 1.0)


func update(dt: float) -> void:
	if cur.is_empty():
		return
	var fps := float(cur.get("fps", 60))
	var n := frames()
	t += dt * fps * speed
	if t >= float(n - 1):
		if loop:
			t = fmod(t, float(maxi(n - 1, 1)))
		else:
			t = float(n - 1)
			finished = true
	var f0 := int(t)
	var f1 := mini(f0 + 1, n - 1)
	var u := t - float(f0)
	var w := 1.0
	if _blend > 0.0 and _blend_t < _blend:
		_blend_t += dt
		w = clampf(_blend_t / _blend, 0.0, 1.0)
	var tracks: Dictionary = cur.get("tracks", {})
	for key in tracks:
		var bi: int = bone_of.get(key, -1)
		if bi < 0:
			continue
		var tr: Dictionary = tracks[key]
		if tr.has("rotation"):
			var rs: Array = tr["rotation"]
			var a: Array = rs[mini(f0, rs.size() - 1)]
			var b: Array = rs[mini(f1, rs.size() - 1)]
			var q := Quaternion(a[0], a[1], a[2], a[3]).slerp(Quaternion(b[0], b[1], b[2], b[3]), u)
			if bi == root_bone:
				q = yaw_fix * q
			if w < 1.0:
				q = (_snap_rot[bi] as Quaternion).slerp(q, w)
			skel.set_bone_pose_rotation(bi, q)
		if tr.has("translation"):
			var ts: Array = tr["translation"]
			var a2: Array = ts[mini(f0, ts.size() - 1)]
			var b2: Array = ts[mini(f1, ts.size() - 1)]
			var p := Vector3(a2[0], a2[1], a2[2]).lerp(Vector3(b2[0], b2[1], b2[2]), u)
			if w < 1.0:
				p = (_snap_pos[bi] as Vector3).lerp(p, w)
			skel.set_bone_pose_position(bi, p)
		else:
			# joints without translation keys keep their rest translation
			var rp := skel.get_bone_rest(bi).origin
			skel.set_bone_pose_position(bi, (_snap_pos[bi] as Vector3).lerp(rp, w) if w < 1.0 else rp)
	# bones without any track (e.g. the hips moved by the SvR retargeter) return to rest
	for bi in skel.get_bone_count():
		var key := skel.get_bone_name(bi).substr(0, 3)
		if tracks.has(key) or tracks.has(skel.get_bone_name(bi)):
			continue
		var rest := skel.get_bone_rest(bi)
		var rq := rest.basis.get_rotation_quaternion()
		if bi == root_bone:
			rq = yaw_fix * rq
		if w < 1.0:
			skel.set_bone_pose_rotation(bi, (_snap_rot[bi] as Quaternion).slerp(rq, w))
			skel.set_bone_pose_position(bi, (_snap_pos[bi] as Vector3).lerp(rest.origin, w))
		else:
			skel.set_bone_pose_rotation(bi, rq)
			skel.set_bone_pose_position(bi, rest.origin)
