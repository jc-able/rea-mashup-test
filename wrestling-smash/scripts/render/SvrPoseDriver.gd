## "SvR 2011" animation mode for one wrestler: poses the wrestler's own skeleton with ORIGINAL
## SmackDown vs. Raw 2011 motions (.svrm clips, SvrClip) chosen from the SSB64 fighter state
## (SvrAnimMap) and retimed against the SSB64 motion (SsbTiming):
##   * attacks ("hit"): the clip's impact frame lands on the frame the SSB64 hitbox becomes active,
##     the rest of the clip is stretched/compressed over the SSB64 recovery;
##   * other one-shots ("fit"): clip [in, out] follows the SSB64 animation progress (anim_frame);
##   * cycles ("loop") run at the clip's own rate, "hold" plays once and holds.
## Position, facing and the hit-lag shake come from the SSB64 fighter (TopN), so the model stays
## over the real hurtboxes; root motion inside a clip is kept vertically only.
## Grapples: a thrown/captured fighter plays the victim side of the thrower's SvR move, placed in the
## thrower's frame (the two clips were authored together).
## Strictly read-only on the engine: the gameplay simulation is identical in both animation modes.
extends RefCounted

const RU = preload("res://scripts/render/RenderUtil.gd")
const SvrClip = preload("res://scripts/render/SvrClip.gd")
const SsbTiming = preload("res://scripts/render/SsbTiming.gd")
const SvrAnimMap = preload("res://scripts/render/SvrAnimMap.gd")
const WL = preload("res://scripts/render/WrestlerLibrary.gd")
## the clips were exported on John Cena's GLB skeleton (glb_scale 0.0973633): root translations are
## scaled by each wrestler's own glb_scale relative to that
const CLIP_GLB_SCALE := 0.0973633

const FADE_FRAMES := 5.0          # cross-fade between clips (engine frames)
const HIT_ROLES := ["hit_hi", "hit_n", "hit_lw", "hit_air", "tumble"]
const REACT_MAX := 36.0           # clip frames (1.2 s) of an authored reaction shown on a hit
const MAX_SPEEDUP := 3.0          # windup/recovery may be played at most this much faster

## Fighter -> driver, so a thrown fighter can follow its thrower's clip.
static var _drivers: Dictionary = {}

var ok := false
var skel: Skeleton3D
var root_node: Node3D
var slug := ""
var scale_k := 1.0
var fighter = null
var info := {}                    # last decision (HUD / debug overlay / evidence)
var clip_t := 0.0                 # current clip frame
var yaw_fix_cur := Quaternion.IDENTITY   # facing correction applied to the clip root this frame
var root_scale := 1.0                     # this wrestler's glb_scale / CLIP_GLB_SCALE
var spec: Dictionary = {}
var clip = null

var _up_skel := Vector3.UP
var _bone_maps: Dictionary = {}   # clip key -> PackedInt32Array (clip bone -> skeleton bone or -1)
var _root_clip_bone: Dictionary = {}   # clip key -> clip bone index of the skeleton root (or -1)
var _status := -1
var _elapsed := 0.0               # engine frames in the current status (hit-lag excluded)
var _adv := 0.0                   # engine frames advanced since the last apply (hit-lag excluded)
var _loop_t := 0.0                # accumulated cycle time (clip frames) for "loop" playback
var _last_sim := -1
var _last_anim_frame := 0.0
var _clip_key := ""
var _fade_q: Dictionary = {}      # skeleton bone -> Quaternion at the last clip change
var _fade_p: Dictionary = {}      # skeleton bone -> Vector3
var _fade_e := FADE_FRAMES
var _touched: Dictionary = {}     # skeleton bones posed by the current clip
var _was_lead := false            # last frame was placed in a thrower's frame (paired grapple)
var _role := ""                   # role of the last applied clip
var _cont := false                # playing a continuation status ("=role")
var _react_key := ""              # reaction clip being shown after a hit
var _react_from = null
var _react_in := 0.0
var _react_move := ""
var _place_from := Transform3D.IDENTITY   # model placement when the paired move ended
var _place_e := 99.0              # engine frames since then (placement blends back to SSB64)
var _last_place := Transform3D.IDENTITY

func setup(p_fighter, p_root: Node3D, p_skel: Skeleton3D, p_slug: String, p_scale_k: float) -> bool:
	fighter = p_fighter
	root_node = p_root
	skel = p_skel
	slug = p_slug
	scale_k = p_scale_k
	ok = skel != null and root_node != null and slug != ""
	if ok:
		var s2r := Transform3D.IDENTITY
		var n: Node = skel
		while n != null and n != root_node:
			if n is Node3D:
				s2r = (n as Node3D).transform * s2r
			n = n.get_parent()
		_up_skel = (s2r.basis.orthonormalized().inverse() * Vector3.UP).normalized()
		var gs := float(WL.meta(slug).get("glb_scale", CLIP_GLB_SCALE))
		root_scale = gs / CLIP_GLB_SCALE if gs > 0.0 else 1.0
		_drivers[fighter] = self
	return ok

## The driver of the wrestler who last damaged this fighter (SSB64 damage_player), if any.
func _attacker_driver(fp):
	var who := int(fp.damage_player)
	if who < 0:
		return null
	for f in _drivers:
		if f != fighter and int(f.player) == who:
			return _drivers[f]
	return null

## Loads every clip this wrestler may need (avoids a hitch the first time a move is used).
func preload_clips() -> int:
	var n := 0
	for k in SvrAnimMap.clips_for(slug):
		if SvrClip.get_clip(k) != null:
			n += 1
	return n

func dispose() -> void:
	if _drivers.get(fighter, null) == self:
		_drivers.erase(fighter)

## Puts every bone this driver posed back to its rest pose (before the SSB64 retarget takes over).
func release() -> void:
	if skel == null:
		return
	for b in _touched:
		skel.reset_bone_pose(b)
	_touched.clear()
	_clip_key = ""
	clip = null
	spec = {}

## Decide and apply the pose for this frame. Returns false when no recovered SvR clip covers the
## fighter's current state (the caller then shows the SSB64 motion and labels it a fallback).
func apply(fp, jw: Array, extra: Vector3) -> bool:
	if not ok or jw[0] == null:
		return false
	var ri: Array = SvrAnimMap.role_info(int(fp.fkind), int(fp.status_id))
	var role: String = ri[0]
	var status_name: String = ri[1]
	var cont := false
	if role.begins_with("="):
		role = role.substr(1)
		cont = _role == role and _clip_key != "" and int(fp.status_id) != _status
	# --- frame bookkeeping (engine frames, hit-lag excluded) -----------------------------------
	var restarted := false
	if int(fp.status_id) != _status:
		_status = int(fp.status_id)
		restarted = true
	elif fp.anim_frame + 0.5 < _last_anim_frame and fp.anim_frame > 0.0 and SvrAnimMap.ROLE_TIMING.get(role, "") != "loop" \
			and not bool(SsbTiming.motion_info(fp, int(fp.motion_id)).loops):
		restarted = true          # same status entered again (e.g. a second hit); looping SSB64 motions just wrap
	_adv = 0.0
	if cont:
		restarted = false          # same move continues in its next status: keep the clip running
		_cont = true
	elif restarted:
		_cont = false
	if restarted:
		_elapsed = 0.0
	elif _last_sim >= 0 and Sim.frame != _last_sim:
		var d := clampi(Sim.frame - _last_sim, 0, 4)
		if int(fp.hitlag_tics) <= 0:
			_elapsed += d
			_adv = d
		_fade_e += d
		_place_e += d
	_last_sim = Sim.frame
	_last_anim_frame = fp.anim_frame
	# --- choose the clip ------------------------------------------------------------------------
	var lead = null               # thrower's driver when this fighter is in a paired grapple
	var s := SvrAnimMap.spec_for(slug, role)
	if s.has("by_status") and (s.by_status as Dictionary).has(status_name):
		var o: Dictionary = (s.by_status as Dictionary)[status_name]
		for k in o:
			s[k] = o[k]
	var key := str(s.get("clip", ""))
	if role in ["thrown", "captured"] and fp.capture_gobj != null:
		var d2 = _drivers.get(fp.capture_gobj, null)
		if d2 != null and d2.clip != null and d2.spec.has("victim_clip"):
			lead = d2
			key = str(d2.spec.victim_clip)
			s = {"clip": key, "timing": "lead", "move": d2.spec.get("move", ""), "source": d2.spec.get("source", "")}
	if role in HIT_ROLES and lead == null:
		# hit by a wrestler whose SvR strike has an authored opponent reaction: play that reaction
		# from the strike's impact frame (the two clips share one timeline)
		var att = _attacker_driver(fp)
		if att != null and att.clip != null and att.spec.has("hit_victim_clip"):
			if restarted or _react_key == "" or _react_from != att:
				_react_key = str(att.spec.hit_victim_clip)
				_react_from = att
				_react_in = float(att.spec.get("impact", 0.0))
				_react_move = str(att.spec.get("move", ""))
			key = _react_key
			s = {"clip": key, "timing": "react", "in": _react_in, "move": "reaction to " + _react_move,
				"source": "SvR 2011 opponent side of %s's %s" % [att.slug, _react_move]}
		else:
			_react_key = ""
	else:
		_react_key = ""
	var c = SvrClip.get_clip(key) if key != "" else null
	info = {"role": role, "status": status_name, "clip": key if c != null else "", "move": s.get("move", ""),
		"source": s.get("source", ""), "origin": "SvR 2011" if c != null else "SSB64 fallback"}
	if c == null:
		if _clip_key != "":
			release()
		_was_lead = false
		return false
	if key != _clip_key:
		_begin_fade(c)
		_clip_key = key
		_loop_t = 0.0
	elif restarted and str(s.get("timing", "")) != "loop":
		_begin_fade(c)
	clip = c
	spec = s
	_role = role
	# --- clip time --------------------------------------------------------------------------------
	var t := 0.0
	if lead != null:
		t = clampf(lead.clip_t, 0.0, c.frames - 1.0)
	elif _cont:
		# continuation status of a multi-status move: run on from where the clip was
		t = minf(clip_t + _adv * float(s.get("rate", 1.0)) * c.fps / 60.0, float(s.get("out", c.frames - 1.0)))
	else:
		t = _clip_time(fp, c, s)
	clip_t = t
	info["t"] = t
	# --- placement: SSB64 position / facing / hit-lag shake -----------------------------------
	var topn: Transform3D = jw[0]
	if lead != null:
		root_node.transform = Transform3D(lead.root_node.transform.basis.orthonormalized().scaled(Vector3.ONE * scale_k), lead.root_node.transform.origin + extra)
	else:
		var fwd: Vector3 = topn.basis.orthonormalized() * Vector3(0, 0, 1)
		fwd.y = 0.0
		var yaw := atan2(fwd.x, fwd.z) if fwd.length() > 1e-4 else PI * 0.5 * float(fp.lr)
		var target := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scale_k), topn.origin * RU.S + extra)
		if _was_lead:
			# released from a paired grapple: glide from the paired placement to the SSB64 one
			_place_from = _last_place
			_place_e = 0.0
		if _place_e < FADE_FRAMES:
			var w := clampf(_place_e / FADE_FRAMES, 0.0, 1.0)
			var q0 := _place_from.basis.orthonormalized().get_rotation_quaternion()
			var q1 := target.basis.orthonormalized().get_rotation_quaternion()
			target = Transform3D(Basis(q0.slerp(q1, w)).scaled(Vector3.ONE * scale_k), _place_from.origin.lerp(target.origin, w))
		root_node.transform = target
	_was_lead = lead != null
	_last_place = root_node.transform
	# --- pose -------------------------------------------------------------------------------------
	_pose(c, s, t, lead)
	return true

func _clip_time(fp, c, s: Dictionary) -> float:
	var last: float = c.frames - 1.0
	var c_in := clampf(float(s.get("in", 0.0)), 0.0, last)
	var c_out := clampf(float(s.get("out", last)), c_in, last)
	var rate: float = float(s.get("rate", 1.0)) * c.fps / 60.0          # clip frames per engine frame
	match str(s.get("timing", "fit")):
		"react":
			# the reaction from the impact frame on, at the clip's own speed, for at most REACT_MAX
			# clip frames (a knock-down tail would not match SSB64's flight / landing)
			return minf(c_in + _elapsed * rate, minf(c_out, c_in + REACT_MAX))
		"loop":
			# cycles with a natural speed (walk / run) follow the SSB64 ground speed so feet do not slide
			if s.has("speed_mps") and float(s.speed_mps) > 0.0:
				var v: float = absf(fp.physics.vel_ground.x) * RU.S * 60.0
				rate *= clampf(v / (float(s.speed_mps) * scale_k), 0.3, 3.0)
			_loop_t += _adv * rate
			return c_in + fmod(_loop_t, maxf(c_out - c_in, 1.0))
		"hold":
			return minf(c_in + _elapsed * rate, c_out)
		"pose":
			return c_in
	var mi: Dictionary = SsbTiming.motion_info(fp, int(fp.motion_id))
	var L: float = mi.length
	if L <= 0.0:
		return minf(c_in + _elapsed * rate, c_out)
	var f: float = fp.anim_frame
	if f <= 0.0:
		f = L if _elapsed > 0.0 else 0.0
	f = clampf(f, 0.0, L)
	var impact := float(s.get("impact", -1.0))
	# anchor on the SSB64 timeline: first active hitbox, or for throws the release frame (flag2)
	var h: float = mi.hit_first
	var anchor := str(s.get("anchor", "release" if str(info.get("role", "")) in ["throw_f", "throw_b"] else "hit"))
	if anchor == "release" and float(mi.get("flag2", -1.0)) > 0.0:
		h = mi.flag2
	if str(s.get("timing", "fit")) == "hit" and impact >= c_in and h > 0.0:
		# limit how fast the windup / recovery may run so short SSB64 startups skip part of the windup
		var msu := float(s.get("max_speedup", MAX_SPEEDUP))
		var a := maxf(c_in, impact - h * rate * msu)
		var b := minf(c_out, impact + maxf(L - h, 1.0) * rate * msu)
		if f <= h:
			return a + (impact - a) * (f / h)
		return impact + (b - impact) * clampf((f - h) / maxf(L - h, 1.0), 0.0, 1.0)
	return c_in + (c_out - c_in) * (f / L)

func _bone_map(c) -> PackedInt32Array:
	if _bone_maps.has(c.key):
		return _bone_maps[c.key]
	var m := PackedInt32Array()
	m.resize(c.bones.size())
	var root_i := -1
	for i in c.bones.size():
		m[i] = skel.find_bone(c.bones[i])
		if m[i] >= 0 and skel.get_bone_parent(m[i]) < 0:
			root_i = i
	_bone_maps[c.key] = m
	_root_clip_bone[c.key] = root_i
	return m

func _begin_fade(c) -> void:
	_fade_q.clear()
	_fade_p.clear()
	var m := _bone_map(c)
	var keep := {}
	for i in m.size():
		var b := m[i]
		if b < 0:
			continue
		keep[b] = true
		_fade_q[b] = skel.get_bone_pose_rotation(b)
		_fade_p[b] = skel.get_bone_pose_position(b)
	if _clip_key == "":
		# taking over from the SSB64 retarget: bones this clip does not drive go back to rest
		for b in skel.get_bone_count():
			if not keep.has(b):
				skel.reset_bone_pose(b)
	else:
		for b in _touched:
			if not keep.has(b):
				skel.reset_bone_pose(b)
	_touched = keep
	_fade_e = 0.0

func _pose(c, s: Dictionary, t: float, lead) -> void:
	var m := _bone_map(c)
	var w := clampf(_fade_e / FADE_FRAMES, 0.0, 1.0)
	var root_i: int = _root_clip_bone.get(c.key, -1)
	var paired: bool = lead != null or s.has("victim_clip")
	var keep_root: bool = paired or str(s.get("root", "strip_xz")) == "keep"
	var yaw_fix := Quaternion.IDENTITY
	if lead != null:
		yaw_fix = lead.yaw_fix_cur
	elif root_i >= 0 and str(s.get("root_yaw", "strip")) == "strip" and m[root_i] >= 0:
		# start the move facing the SSB64 direction: compare the clip root's facing at "in" with the
		# rest facing (+Z) about the skeleton's up axis; turning inside the move is kept
		var q_rest: Quaternion = skel.get_bone_rest(m[root_i]).basis.get_rotation_quaternion()
		var a: Vector3 = q_rest.inverse() * Vector3(0, 0, 1)
		var f0: Vector3 = c.rotation_at(root_i, float(s.get("in", 0.0))) * a
		var r0 := Vector3(0, 0, 1)
		f0 -= _up_skel * f0.dot(_up_skel)
		r0 -= _up_skel * r0.dot(_up_skel)
		if f0.length() > 1e-4 and r0.length() > 1e-4:
			yaw_fix = Quaternion(f0.normalized(), r0.normalized())
	yaw_fix_cur = yaw_fix
	for i in m.size():
		var b := m[i]
		if b < 0:
			continue
		var q: Quaternion = c.rotation_at(i, t)
		if i == root_i:
			q = yaw_fix * q
		if w < 1.0 and _fade_q.has(b):
			q = (_fade_q[b] as Quaternion).slerp(q, w)
		skel.set_bone_pose_rotation(b, q)
		if c.pos_varies[i] or i == root_i:
			var p: Vector3 = c.position_at(i, t)
			if i == root_i:
				p *= root_scale
				if keep_root:
					p = yaw_fix * p
				else:
					# single moves: the SSB64 physics moves the fighter, so only the clip's vertical
					# root motion is kept (crouches, knock-downs, lifts); horizontally the root stays
					# at its rest offset over the SSB64 position
					var rp: Vector3 = skel.get_bone_rest(b).origin
					p = (rp - _up_skel * rp.dot(_up_skel)) + _up_skel * p.dot(_up_skel)
			if w < 1.0 and _fade_p.has(b):
				p = (_fade_p[b] as Vector3).lerp(p, w)
			skel.set_bone_pose_position(b, p)
