class_name PosePlayer
extends RefCounted
## Plays SwmClips on a RetargetRig: clip timing, looping, cross-fades in world space, root motion anchoring.
## The wrestler node is the clip "anchor": hips_world = anchor * (hips_clip * (kh, kv, kh)).
## Written in this run (custom).

var rig: RetargetRig
var node: Node3D                 # wrestler root = anchor (no scale)
var skel_from_node := Transform3D.IDENTITY  # node-local -> skeleton space
var skel_rot := Quaternion.IDENTITY          # rotation part of node-local -> skeleton space
var kh := 1.0          # horizontal root-motion scale
var kv := 1.0          # vertical scale of the hips ABOVE the support (what the feet stand on)
var ks := 1.0          # scale of the support height itself (1 = world-true: mat, turnbuckle, floor)

var clip: SwmClip
var t := 0.0
var speed := 1.0
var loop := false
var finished := false
var clip_name := ""

var _blend_dur := 0.0
var _blend_t := 0.0
var _prev_rots: Array = []
var _prev_hips := Vector3.ZERO
var cur_rots: Array = []         # world-space deltas of the last update
var cur_hips := Vector3.ZERO      # world-space hips of the last update
var _tmp: Array = []
var _has_pose := false


func setup(r: RetargetRig, wrestler: Node3D) -> void:
	rig = r
	node = wrestler
	_tmp.resize(21)
	cur_rots.resize(21)
	_prev_rots.resize(21)
	for j in 21:
		cur_rots[j] = Quaternion.IDENTITY
		_prev_rots[j] = Quaternion.IDENTITY
	refresh_space()


func refresh_space() -> void:
	var to_skel := rig.skel.global_transform.affine_inverse() * node.global_transform
	skel_from_node = to_skel
	skel_rot = to_skel.basis.get_rotation_quaternion()


## opts: loop, speed, blend (s), start (frame), align ("keep" | "pelvis"), anchor (Transform3D)
func play(c: SwmClip, opts: Dictionary = {}) -> void:
	if c == null:
		return
	if _has_pose:
		for j in 21:
			_prev_rots[j] = cur_rots[j]
		_prev_hips = cur_hips
		_blend_dur = float(opts.get("blend", 0.18))
		_blend_t = 0.0
	else:
		_blend_dur = 0.0
	clip = c
	clip_name = c.key
	loop = bool(opts.get("loop", false))
	speed = float(opts.get("speed", 1.0))
	t = float(opts.get("start", 0.0))
	finished = false
	if opts.has("anchor"):
		node.global_transform = opts["anchor"]
	elif String(opts.get("align", "keep")) == "pelvis" and _has_pose:
		align_to_current_pelvis(float(opts.get("floor_y", node.global_position.y)))


## Move the anchor so the new clip's start pelvis (ground position + heading) matches the current one.
func align_to_current_pelvis(floor_y: float = 0.0) -> void:
	var h0 := clip.hips_at(t)
	var q0 := clip.quat_at(int(t), SwmClip.J_ROOT)
	var head_new := heading_of(q0)
	var head_cur := heading_of(cur_rots[SwmClip.J_ROOT])
	var yaw := head_cur - head_new
	var basis := Basis(Vector3.UP, yaw)
	var local := Vector3(h0.x * kh, 0.0, h0.z * kh)
	var pos := Vector3(cur_hips.x, floor_y, cur_hips.z) - basis * local
	node.global_transform = Transform3D(basis, pos)


## Heading (yaw about +Y) of a pelvis orientation; uses the forward axis when upright, the up axis when lying.
static func heading_of(q: Quaternion) -> float:
	var f := q * Vector3(0, 0, 1)
	if absf(f.y) < 0.8:
		return atan2(f.x, f.z)
	var u := q * Vector3(0, 1, 0)
	return atan2(u.x, u.z) + (PI if f.y > 0.0 else 0.0)


func update(dt: float) -> void:
	if clip == null:
		return
	if not finished:
		t += dt * clip.fps * speed
		if not loop and t >= float(clip.frames - 1):
			t = float(clip.frames - 1)
			finished = true
	var h := clip.sample(t, _tmp, loop)
	var anchor := node.global_transform
	var ar := anchor.basis.get_rotation_quaternion()
	var sup := clip.support_at(t, loop)
	var hy := sup * (ks if sup > 0.0 else 1.0) + (h.y - sup) * kv
	var hips_w := anchor * Vector3(h.x * kh, hy, h.z * kh)
	var w := 1.0
	if _blend_dur > 0.0 and _blend_t < _blend_dur:
		_blend_t += dt
		w = clampf(_blend_t / _blend_dur, 0.0, 1.0)
		w = w * w * (3.0 - 2.0 * w)
	for j in 21:
		var dw: Quaternion = ar * (_tmp[j] as Quaternion)
		if w < 1.0:
			dw = (_prev_rots[j] as Quaternion).slerp(dw, w)
		cur_rots[j] = dw
	if w < 1.0:
		hips_w = _prev_hips.lerp(hips_w, w)
	cur_hips = hips_w
	_has_pose = true
	_apply_to_rig()


func _apply_to_rig() -> void:
	var inv := node.global_transform.basis.get_rotation_quaternion().inverse()
	var sr := skel_rot
	var sri := sr.inverse()
	for j in 21:
		# world delta -> node-local delta -> skeleton-space delta (conjugation by the node->skeleton rotation)
		_tmp[j] = sr * (inv * (cur_rots[j] as Quaternion)) * sri
	var hl := node.global_transform.affine_inverse() * cur_hips
	rig.apply(_tmp, skel_from_node * hl)


func progress() -> float:
	if clip == null or clip.frames <= 1:
		return 1.0
	return clampf(t / float(clip.frames - 1), 0.0, 1.0)


func frame() -> int:
	return int(t)


## Ground point under the hips (world) and pelvis heading of the current pose.
func ground_point() -> Vector3:
	return Vector3(cur_hips.x, 0.0, cur_hips.z)


func heading() -> float:
	return heading_of(cur_rots[SwmClip.J_ROOT])


## Re-anchor after a one-shot clip: node moves under the hips with the pelvis heading, pose unchanged.
func settle_anchor_to_pelvis(floor_y: float = 0.0) -> void:
	var yaw := heading()
	var pos := Vector3(cur_hips.x, floor_y, cur_hips.z)
	node.global_transform = Transform3D(Basis(Vector3.UP, yaw), pos)
