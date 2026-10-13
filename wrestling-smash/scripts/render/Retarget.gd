## Drives one wrestler Skeleton3D from the SSB64 joint world transforms of one fighter.
##
## Method (see data/retarget_map.json notes):
##  * rest analysis once: SSB bind-pose world frames S0 (from fp.data.joints_desc, TopN unrotated)
##    and wrestler rest frames W0 (skeleton global rests, in the model-root space; both rigs face +Z,
##    +Y up, +X = character's left).
##  * limb roles: canonical frames built from the bone axis (SSB: joint -> limb_child direction,
##    wrestler: bone -> limb_end) and the facing reference projected perpendicular to it, giving a
##    constant offset O = B_ssb * B_wrestler^T; at runtime R_w = R_ssb(t) * O, so the wrestler bone
##    axis lies exactly on the SSB segment and twist follows the SSB joint frame.
##  * other roles: rest-delta transfer R_w = R_ssb(t) * S0^T * W0 (spine = halfway slerp).
##  * positions: only the pelvis is placed (SSB hips position, height-ratio scaled about TopN);
##    every other bone keeps the wrestler's own bone lengths. The model root is scaled so the
##    wrestler's height equals the SSB fighter's standing height (Wait pose).
extends RefCounted

const RU = preload("res://scripts/render/RenderUtil.gd")

const LIMB_ROLES := ["l_upperarm", "l_forearm", "r_upperarm", "r_forearm", "l_thigh", "l_shin", "r_thigh", "r_shin"]

static var _map: Dictionary = {}

static func map_data() -> Dictionary:
	if _map.is_empty():
		var p := "res://data/retarget_map.json"
		if FileAccess.file_exists(p):
			var d = JSON.parse_string(FileAccess.get_file_as_string(p))
			if d is Dictionary:
				_map = d
	return _map

var ok := false
var skel: Skeleton3D
var root_node: Node3D
var scale_k := 1.0                 # model root scale (GLB metres -> render metres)
var hip_ratio := 1.0               # wrestler pelvis height / SSB hips height
var hips_joint := -1
var skel_to_root := Transform3D.IDENTITY
var _sr_rot_inv := Basis.IDENTITY
var _rest_local: Array = []        # Transform3D per bone
var _parent: PackedInt32Array
var _order: PackedInt32Array       # bones to evaluate (mapped + ancestors), parents first
var _drive: Dictionary = {}        # bone -> {"joint": int, "o": Basis} or {"spine": true}
var _hips_bone := -1
var _spine := {}                   # {"bone", "jh", "jc", "s0h_t", "s0c_t", "w0"}
var _G: Array = []                 # global pose per bone (skeleton space), scratch
var _feet: Array = []              # [{bone, joint, ssb_rest_y, w_rest_y}] ground anchoring
var _shift := Vector3.ZERO         # skeleton-space vertical correction applied to the pelvis
var _blend: Dictionary = {}        # bone -> {"f": float, "q": rest local Quaternion} (tamed limbs)
var standing_height := 0.0
var hip_height := 0.0
var debug_info := {}
var _hips_local_pos := Vector3.ZERO

func setup(fp, p_root: Node3D, p_skel: Skeleton3D, wrestler_meta: Dictionary) -> bool:
	root_node = p_root
	skel = p_skel
	var md := map_data()
	var entry: Dictionary = md.get("fighters", {}).get(str(fp.fkind), {})
	if entry.is_empty() or skel == null:
		return false
	var roles: Dictionary = entry.get("roles", {})
	var limb_child: Dictionary = entry.get("limb_child", {})
	var wb: Dictionary = md.get("wrestler_bones", {})
	var lend: Dictionary = md.get("limb_end", {})

	# --- wrestler rest (root space) ---------------------------------------------------------
	skel_to_root = Transform3D.IDENTITY
	var n: Node = skel
	while n != null and n != root_node:
		if n is Node3D:
			skel_to_root = (n as Node3D).transform * skel_to_root
		n = n.get_parent()
	_sr_rot_inv = skel_to_root.basis.orthonormalized().inverse()
	var bc := skel.get_bone_count()
	_parent.resize(bc)
	_rest_local.resize(bc)
	_G.resize(bc)
	var grest: Array = []
	grest.resize(bc)
	for b in bc:
		_parent[b] = skel.get_bone_parent(b)
		_rest_local[b] = skel.get_bone_rest(b)
	for b in bc:
		grest[b] = skel_to_root * skel.get_bone_global_rest(b)

	# --- SSB bind pose world (TopN unrotated, scaled by attr.size) -------------------------
	var bind := _ssb_bind(fp)
	if bind.is_empty():
		return false

	var used := {}
	for role in wb:
		var jid = roles.get(role, null)
		if role == "spine" or jid == null:
			continue
		jid = int(jid)
		if not bind.has(jid):
			continue
		var bone := skel.find_bone(wb[role])
		if bone < 0:
			continue
		var s0: Basis = (bind[jid] as Transform3D).basis.orthonormalized()
		var w0: Basis = (grest[bone] as Transform3D).basis.orthonormalized()
		var o: Basis
		if role in LIMB_ROLES:
			var cs := Vector3.RIGHT
			var cj = limb_child.get(role, null)
			if cj != null and _joint_rec(fp, int(cj)) != null:
				var t := _vec(_joint_rec(fp, int(cj)).translate)
				if t.length() > 0.001:
					cs = t.normalized()
			var end_bone := skel.find_bone(lend.get(role, ""))
			var axis_w := Vector3.ZERO
			if end_bone >= 0:
				axis_w = ((grest[end_bone] as Transform3D).origin - (grest[bone] as Transform3D).origin)
			if axis_w.length() < 1e-5:
				axis_w = w0 * Vector3.RIGHT
			axis_w = axis_w.normalized()
			var axis_s: Vector3 = (s0 * cs).normalized()
			var refv := _pick_ref(axis_s, axis_w)
			var fs := (refv - axis_s * refv.dot(axis_s)).normalized()
			var fw := (refv - axis_w * refv.dot(axis_w)).normalized()
			var cw: Vector3 = (w0.inverse() * axis_w).normalized()
			var rs: Vector3 = (s0.inverse() * fs).normalized()
			var rw: Vector3 = (w0.inverse() * fw).normalized()
			var bs := Basis(cs, rs, cs.cross(rs).normalized())
			var bw := Basis(cw, rw, cw.cross(rw).normalized())
			o = bs * bw.transposed()
		else:
			o = s0.transposed() * w0
		_drive[bone] = {"joint": jid, "o": o}
		used[bone] = true
		var bl = entry.get("blend", {}).get(role, null)
		if bl != null and float(bl) < 1.0:
			_blend[bone] = {"f": float(bl), "q": (_rest_local[bone] as Transform3D).basis.get_rotation_quaternion()}
		if role == "hips":
			_hips_bone = bone
			hips_joint = jid
		if role == "l_foot" or role == "r_foot":
			_feet.append({"bone": bone, "joint": jid, "ssb_rest_y": (bind[jid] as Transform3D).origin.y,
				"w_rest_y": (grest[bone] as Transform3D).origin.y})
	# spine: halfway between hips and chest deltas
	var spine_bone := skel.find_bone(wb.get("spine", ""))
	var jh = roles.get("hips", null)
	var jc = roles.get("chest", null)
	if spine_bone >= 0 and jh != null and jc != null and bind.has(int(jh)) and bind.has(int(jc)):
		_spine = {"bone": spine_bone, "jh": int(jh), "jc": int(jc),
			"s0h_t": (bind[int(jh)] as Transform3D).basis.orthonormalized().transposed(),
			"s0c_t": (bind[int(jc)] as Transform3D).basis.orthonormalized().transposed(),
			"w0": (grest[spine_bone] as Transform3D).basis.orthonormalized()}
		used[spine_bone] = true
	if _hips_bone < 0:
		return false

	# evaluation order: used bones + ancestors, parents first
	var need := {}
	for b in used:
		var c: int = b
		while c >= 0 and not need.has(c):
			need[c] = true
			c = _parent[c]
	var lst: Array = need.keys()
	lst.sort_custom(func(a, b2): return _depth(a) < _depth(b2) or (_depth(a) == _depth(b2) and a < b2))
	_order = PackedInt32Array(lst)

	# --- scale: wrestler height == SSB standing height --------------------------------------
	var meas: Dictionary = entry.get("measured", {})
	standing_height = float(meas.get("standing_height", 0.0))
	hip_height = float(meas.get("hip_height", 0.0))
	if standing_height <= 0.0:
		standing_height = _bind_standing_height(fp, bind)
	if hip_height <= 0.0:
		hip_height = (bind[hips_joint] as Transform3D).origin.y
	var h_w := float(wrestler_meta.get("height_m", 0.0))
	if h_w <= 0.0:
		h_w = 1.9
	scale_k = standing_height * RU.S / h_w
	var pelvis_y: float = (grest[_hips_bone] as Transform3D).origin.y
	hip_ratio = (pelvis_y * scale_k) / maxf(hip_height * RU.S, 0.01)
	debug_info = {"standing_height": standing_height, "hip_height": hip_height, "scale_k": scale_k,
		"hip_ratio": hip_ratio, "mapped": _drive.size()}
	ok = true
	return true

func _depth(b: int) -> int:
	var d := 0
	var c := _parent[b]
	while c >= 0:
		d += 1
		c = _parent[c]
	return d

static func _pick_ref(a: Vector3, b: Vector3) -> Vector3:
	var best := Vector3.BACK
	var best_v := -1.0
	for r in [Vector3.BACK, Vector3.UP, Vector3.RIGHT]:
		var v := minf((r - a * r.dot(a)).length(), (r - b * r.dot(b)).length())
		if v > best_v + 0.05:
			best_v = v
			best = r
	return best

static func _vec(a) -> Vector3:
	if a is Vector3:
		return a
	return Vector3(float(a[0]), float(a[1]), float(a[2]))

static func _joint_rec(fp, jid: int):
	for jr in fp.data.joints_desc:
		if int(jr.index) == jid:
			return jr
	return null

## Bind-pose world transforms of every exported joint (SSB units), TopN = scale(attr.size).
static func _ssb_bind(fp) -> Dictionary:
	var out := {}
	var recs: Array = fp.data.joints_desc
	var size: float = fp.attr.size
	var pending := recs.duplicate()
	var guard := 0
	while not pending.is_empty() and guard < 64:
		guard += 1
		var rest := []
		for jr in pending:
			var idx := int(jr.index)
			var par := int(jr.parent) if jr.parent != null else -1
			var local: Transform3D
			if idx == 0:
				local = Transform3D(Basis.from_scale(Vector3(size, size, size)), Vector3.ZERO)
			elif idx >= 1 and idx <= 3:
				local = Transform3D.IDENTITY
			else:
				local = RU.euler_local(_vec(jr.translate), _vec(jr.rotate), _vec(jr.scale))
			if par < 0:
				out[idx] = local
			elif out.has(par):
				out[idx] = (out[par] as Transform3D) * local
			else:
				rest.append(jr)
		pending = rest
	return out

## Fallback when no measured Wait value exists: top of the highest bind-pose hurtbox.
static func _bind_standing_height(fp, bind: Dictionary) -> float:
	var top := 0.0
	for dd in fp.attr.damage_coll_descs:
		var jid := int(dd.joint_id)
		if jid < 0 or not bind.has(jid):
			continue
		top = maxf(top, box_top(bind[jid], _vec(dd.offset), _vec(dd.size) * 0.5))
	if top <= 0.0:
		top = float(fp.attr.map_coll.top) if fp.attr.map_coll is Object else 300.0
	return top

static func box_top(w: Transform3D, off: Vector3, half: Vector3) -> float:
	var c := w * off
	var b := w.basis
	return c.y + absf(b.x.y) * half.x + absf(b.y.y) * half.y + absf(b.z.y) * half.z

## jw: SSB world transforms per joint (RenderUtil.fighter_world). extra: render offset (metres).
func apply(jw: Array, extra := Vector3.ZERO) -> void:
	if not ok:
		return
	var topn: Transform3D = jw[0] if jw[0] != null else Transform3D.IDENTITY
	var root_pos: Vector3 = topn.origin * RU.S + extra
	root_node.transform = Transform3D(Basis.from_scale(Vector3(scale_k, scale_k, scale_k)), root_pos)
	var inv_k := 1.0 / scale_k
	var skel_inv := skel_to_root.affine_inverse()
	for b in _order:
		var p := _parent[b]
		var g: Transform3D
		if _drive.has(b):
			var d: Dictionary = _drive[b]
			var jt = jw[d.joint]
			if jt == null:
				g = (_G[p] * _rest_local[b]) if p >= 0 else _rest_local[b]
			else:
				var rw: Basis = (jt as Transform3D).basis.orthonormalized() * (d.o as Basis)
				var rot: Basis = _sr_rot_inv * rw
				var pos: Vector3
				if b == _hips_bone:
					var hp: Vector3 = (jt as Transform3D).origin
					pos = skel_inv * ((hp * RU.S + extra - root_pos) * inv_k)
				else:
					pos = (_G[p] * _rest_local[b]).origin if p >= 0 else _rest_local[b].origin
				g = Transform3D(rot, pos)
				if p >= 0 and _blend.has(b):
					var loc: Transform3D = (_G[p] as Transform3D).affine_inverse() * g
					var bq: Quaternion = (_blend[b].q as Quaternion).slerp(loc.basis.get_rotation_quaternion(), _blend[b].f)
					g = (_G[p] as Transform3D) * Transform3D(Basis(bq), loc.origin)
		elif not _spine.is_empty() and b == _spine.bone and jw[_spine.jh] != null and jw[_spine.jc] != null:
			var dh: Basis = (jw[_spine.jh] as Transform3D).basis.orthonormalized() * (_spine.s0h_t as Basis)
			var dc: Basis = (jw[_spine.jc] as Transform3D).basis.orthonormalized() * (_spine.s0c_t as Basis)
			var dq := dh.get_rotation_quaternion().slerp(dc.get_rotation_quaternion(), 0.5)
			var rot2: Basis = _sr_rot_inv * (Basis(dq) * (_spine.w0 as Basis))
			var pos2: Vector3 = (_G[p] * _rest_local[b]).origin if p >= 0 else _rest_local[b].origin
			g = Transform3D(rot2, pos2)
		else:
			g = (_G[p] * _rest_local[b]) if p >= 0 else _rest_local[b]
		_G[b] = g
		if _drive.has(b) or (not _spine.is_empty() and b == _spine.bone):
			var local: Transform3D = (_G[p].affine_inverse() * g) if p >= 0 else g
			skel.set_bone_pose_rotation(b, local.basis.get_rotation_quaternion())
			if b == _hips_bone:
				_hips_local_pos = local.origin
	# Vertical anchoring: put the wrestler's lower ankle where the SSB foot joint is (corrected by
	# the two rigs' rest ankle heights), so grounded poses keep the feet on the floor whatever the
	# leg-length ratio; x/z of the pelvis stay on the SSB hips.
	_shift = Vector3.ZERO
	if not _feet.is_empty():
		var best_dy := 0.0
		var best_y := INF
		for f in _feet:
			var jt = jw[f.joint]
			if jt == null or _G[f.bone] == null:
				continue
			var ssb_y: float = (jt as Transform3D).origin.y - float(f.ssb_rest_y)
			if ssb_y < best_y:
				best_y = ssb_y
				var target_m: float = (ssb_y - topn.origin.y) * RU.S + float(f.w_rest_y) * scale_k
				var cur_m: float = (root_node.transform * (skel_to_root * (_G[f.bone] as Transform3D).origin)).y - root_pos.y
				best_dy = target_m - cur_m
		_shift = skel_inv.basis * Vector3(0.0, best_dy * inv_k, 0.0)
	skel.set_bone_pose_position(_hips_bone, _hips_local_pos + _shift)

## World position (Godot metres) of a wrestler bone from the last apply().
func bone_world(bone_name: String) -> Vector3:
	var b := skel.find_bone(bone_name)
	if b < 0:
		return root_node.transform.origin
	var chain: Array = []
	var c := b
	while c >= 0 and _G[c] == null:
		chain.push_front(c)
		c = _parent[c]
	var g: Transform3D = _G[c] if c >= 0 else Transform3D.IDENTITY
	for cb in chain:
		g = g * _rest_local[cb]
	g.origin += _shift
	return root_node.transform * (skel_to_root * g.origin)
