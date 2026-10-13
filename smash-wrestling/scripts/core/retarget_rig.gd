class_name RetargetRig
extends RefCounted
## Applies canonical SvR motion (global rotation deltas of the 21 SvR joints + hips position) to any Skeleton3D.
## For every target bone: mapped bones get  G = D[src] * gref  (gref = the bone's global orientation when the
## target rig stands in the SvR reference T-pose), unmapped bones follow their parent with their rest rotation.
## Local pose rotation = inverse(G_parent) * G.  Written in this run (custom retargeter).

var skel: Skeleton3D
var bone_count := 0
var parent := PackedInt32Array()
var src := PackedInt32Array()
var gref: Array = []            # Quaternion per bone (skeleton space)
var rest_rot: Array = []        # Quaternion per bone (local rest)
var rest_pos: Array = []        # Vector3 per bone (local rest)
var order := PackedInt32Array() # parents before children
var hips_bone := -1
var hip_height := 0.9158        # hips height in skeleton space at rest (model units)
var mirror_twist := {}          # optional per-bone extra local rotation (Quaternion) applied after retarget
var _glob: Array = []
var _id := Quaternion.IDENTITY
var _snap_rot: Array = []
var _snap_pos: Array = []
var _lb_dur := 0.0
var _lb_t := 0.0


## Blend from the pose the skeleton shows now (e.g. a Smash 64 animation) into the next retargeted poses.
func begin_local_blend(dur: float) -> void:
	_snap_rot.resize(bone_count)
	_snap_pos.resize(bone_count)
	for i in bone_count:
		_snap_rot[i] = skel.get_bone_pose_rotation(i)
		_snap_pos[i] = skel.get_bone_pose_position(i)
	_lb_dur = dur
	_lb_t = 0.0


func tick_blend(dt: float) -> void:
	if _lb_dur > 0.0:
		_lb_t += dt


## spec: {"bones": [{"name", "src" (int or -1), "gref" [x,y,z,w]} ...], "hips_bone": name, "hip_height": float}
func setup(skeleton: Skeleton3D, spec: Dictionary) -> bool:
	skel = skeleton
	bone_count = skel.get_bone_count()
	parent.resize(bone_count)
	src.resize(bone_count)
	gref.resize(bone_count)
	rest_rot.resize(bone_count)
	rest_pos.resize(bone_count)
	_glob.resize(bone_count)
	for i in bone_count:
		parent[i] = skel.get_bone_parent(i)
		src[i] = -1
		var r := skel.get_bone_rest(i)
		rest_rot[i] = r.basis.get_rotation_quaternion()
		rest_pos[i] = r.origin
		gref[i] = _id
	# default gref = global rest rotation (bones that are already in T-pose orientation)
	for i in bone_count:
		var p := parent[i]
		gref[i] = (gref[p] * rest_rot[i]) if p >= 0 else rest_rot[i]
	for b in spec.get("bones", []):
		var i := skel.find_bone(b["name"])
		if i < 0:
			continue
		src[i] = int(b.get("src", -1))
		if b.has("gref"):
			var g: Array = b["gref"]
			gref[i] = Quaternion(g[0], g[1], g[2], g[3]).normalized()
	hips_bone = skel.find_bone(spec.get("hips_bone", ""))
	hip_height = float(spec.get("hip_height", hip_height))
	# topological order
	var visited := {}
	order.clear()
	for i in bone_count:
		_visit(i, visited)
	return hips_bone >= 0


func _visit(i: int, visited: Dictionary) -> void:
	if visited.has(i):
		return
	var p := parent[i]
	if p >= 0:
		_visit(p, visited)
	visited[i] = true
	order.append(i)


## deltas: Array of 21 Quaternions (canonical/skeleton space). hips_local: desired hips position in skeleton space.
func apply(deltas: Array, hips_local: Vector3) -> void:
	for i in order:
		var p := parent[i]
		var gp: Quaternion = _glob[p] if p >= 0 else _id
		var g: Quaternion
		var s := src[i]
		if s >= 0:
			g = (deltas[s] as Quaternion) * (gref[i] as Quaternion)
		else:
			g = gp * (rest_rot[i] as Quaternion)
		_glob[i] = g
		var lr := (gp.inverse() * g).normalized()
		if _lb_dur > 0.0 and _lb_t < _lb_dur:
			lr = (_snap_rot[i] as Quaternion).slerp(lr, clampf(_lb_t / _lb_dur, 0.0, 1.0))
		skel.set_bone_pose_rotation(i, lr)
	if hips_bone >= 0:
		# hips position: convert the skeleton-space target into the hips bone's parent space
		var p := parent[hips_bone]
		var hp := hips_local
		if p >= 0:
			var pg := skel.get_bone_global_pose(p)
			hp = pg.affine_inverse() * hips_local
		if _lb_dur > 0.0 and _lb_t < _lb_dur:
			hp = (_snap_pos[hips_bone] as Vector3).lerp(hp, clampf(_lb_t / _lb_dur, 0.0, 1.0))
		skel.set_bone_pose_position(hips_bone, hp)
		# joints other than the hips keep their rest translation (Smash animations may have moved them)
		if _lb_dur > 0.0 and _lb_t < _lb_dur:
			var w := clampf(_lb_t / _lb_dur, 0.0, 1.0)
			for i in bone_count:
				if i != hips_bone:
					skel.set_bone_pose_position(i, (_snap_pos[i] as Vector3).lerp(rest_pos[i], w))


## Rest pose (used for model previews).
func apply_rest() -> void:
	for i in bone_count:
		skel.set_bone_pose_rotation(i, rest_rot[i])
		skel.set_bone_pose_position(i, rest_pos[i])


## Global orientation of a bone after the last apply().
func global_rot(i: int) -> Quaternion:
	return _glob[i]
