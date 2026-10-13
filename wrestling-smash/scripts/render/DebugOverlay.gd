## F1 debug overlay: hurtboxes coloured by hit status, active hitboxes (spheres + prev->curr sweep),
## shields, item/weapon collision, ledge / blast-zone / camera-bound lines and the SSB joint skeleton.
## Boxes/spheres/capsules are MultiMesh instances, lines one ImmediateMesh rebuilt per frame.
extends Node3D

const RU = preload("res://scripts/render/RenderUtil.gd")
const MAX_BOX := 96
const MAX_SPH := 256
const MAX_CYL := 192

var mm_box: MultiMesh
var mm_sph: MultiMesh
var mm_cyl: MultiMesh
var lines: ImmediateMesh
var lines_mi: MeshInstance3D
var _nb := 0
var _ns := 0
var _nc := 0
var show_boxes := true
var show_skeleton := true
var fill_alpha := 0.35

const HIT_COLORS := {
	SSBDefs.nGMHitStatusNormal: Color(1.0, 0.9, 0.2, 0.28),
	SSBDefs.nGMHitStatusInvincible: Color(0.3, 1.0, 0.35, 0.3),
	SSBDefs.nGMHitStatusIntangible: Color(0.3, 0.55, 1.0, 0.3),
}

func _ready() -> void:
	mm_box = _mm(BoxMesh.new(), MAX_BOX)
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 16
	sm.rings = 8
	mm_sph = _mm(sm, MAX_SPH)
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 0.5
	cm.height = 1.0
	cm.radial_segments = 12
	cm.cap_top = false
	cm.cap_bottom = false
	mm_cyl = _mm(cm, MAX_CYL)
	lines = ImmediateMesh.new()
	lines_mi = MeshInstance3D.new()
	lines_mi.mesh = lines
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.vertex_color_use_as_albedo = true
	lm.no_depth_test = true
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lm.render_priority = 5
	lines_mi.material_override = lm
	lines_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lines_mi)

func _mm(mesh: Mesh, n: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = n
	mm.visible_instance_count = 0
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = true
	mat.render_priority = 4
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 16384.0
	add_child(mi)
	return mm

func _box(t: Transform3D, col: Color) -> void:
	if _nb < MAX_BOX:
		mm_box.set_instance_transform(_nb, t)
		mm_box.set_instance_color(_nb, Color(col, col.a * fill_alpha))
		_nb += 1
	# edges
	var ec := Color(col, minf(col.a * 3.0, 0.95))
	var c: Array = []
	for i in 8:
		c.append(t * Vector3((i & 1) - 0.5, ((i >> 1) & 1) - 0.5, ((i >> 2) & 1) - 0.5))
	for e in [[0, 1], [2, 3], [4, 5], [6, 7], [0, 2], [1, 3], [4, 6], [5, 7], [0, 4], [1, 5], [2, 6], [3, 7]]:
		_line(c[e[0]], c[e[1]], ec)

func _sphere(c: Vector3, r: float, col: Color) -> void:
	if _ns < MAX_SPH:
		mm_sph.set_instance_transform(_ns, Transform3D(Basis.from_scale(Vector3.ONE * r * 2.0), c))
		mm_sph.set_instance_color(_ns, col)
		_ns += 1

func _capsule(a: Vector3, b: Vector3, r: float, col: Color) -> void:
	var d := b - a
	if d.length() < 0.001:
		return
	if _nc < MAX_CYL:
		var y := d.normalized()
		var x := y.cross(Vector3.BACK)
		if x.length() < 0.01:
			x = y.cross(Vector3.RIGHT)
		x = x.normalized()
		var z := x.cross(y)
		mm_cyl.set_instance_transform(_nc, Transform3D(Basis(x * r * 2.0, d, z * r * 2.0), (a + b) * 0.5))
		mm_cyl.set_instance_color(_nc, col)
		_nc += 1
	_sphere(a, r, col)

## fighters: Dictionary Fighter -> FighterRenderer (for joint world transforms)
func update(fighters: Dictionary, skeleton_only: bool) -> void:
	_nb = 0
	_ns = 0
	_nc = 0
	lines.clear_surfaces()
	lines.surface_begin(Mesh.PRIMITIVE_LINES)
	var any := false
	if show_boxes:
		any = _stage_lines() or any
	for fp in fighters:
		var fr = fighters[fp]
		var jw: Array = fr.jw
		if jw.is_empty() or jw[0] == null:
			continue
		if show_boxes:
			for dc in fp.damage_colls:
				if dc.hitstatus == SSBDefs.nGMHitStatusNone or dc.joint_id < 0 or jw[dc.joint_id] == null:
					continue
				var w: Transform3D = jw[dc.joint_id]
				var col: Color = HIT_COLORS.get(dc.hitstatus, Color(1, 1, 1, 0.25))
				var hs: int = maxi(maxi(fp.hitstatus, fp.special_hitstatus), fp.star_hitstatus)
				if hs != SSBDefs.nGMHitStatusNormal:
					col = HIT_COLORS.get(hs, col)
				var box := Transform3D(Basis.from_scale(dc.size * 2.0), dc.offset)
				_box(RU.to_godot(w * box), col)
			for ac in fp.attack_colls:
				if ac.attack_state == SSBDefs.nGMAttackStateOff:
					continue
				var r: float = ac.size * RU.S
				var c := Color(1.0, 0.15, 0.15, 0.45)
				var pc: Vector3 = ac.pos_curr
				if fp.pkind == SSBDefs.nFTPlayerKindDemo and ac.joint_id >= 0 and ac.joint_id < jw.size() and jw[ac.joint_id] != null:
					var off: Vector3 = ac.offset / fp.attr.size if ac.is_scale_pos != 0 else ac.offset
					pc = (jw[ac.joint_id] as Transform3D) * off
				elif ac.attack_state == SSBDefs.nGMAttackStateInterpolate:
					_capsule(ac.pos_prev * RU.S, ac.pos_curr * RU.S, r, Color(1.0, 0.35, 0.2, 0.3))
				_sphere(pc * RU.S, r, c)
			if fp.is_shield != 0 and jw[SSBDefs.nFTPartsJointYRotN] != null:
				var sw: Transform3D = jw[SSBDefs.nFTPartsJointYRotN]
				var sc := sw.basis.get_scale().x
				var sp := sw.origin
				sp.z = fp.dobj.translate.z
				var hp := clampf(float(fp.shield_health) / 55.0, 0.0, 1.0)
				_sphere(sp * RU.S, 30.0 * sc * RU.S, Color(1.0 - hp * 0.6, 0.45 + 0.4 * hp, 1.0, 0.18))
		if show_skeleton or skeleton_only:
			_skeleton(fp, jw, skeleton_only)
		any = true
	if show_boxes:
		for wp in Sim.get_link(SSBDefs.nGCCommonLinkIDWeapon):
			if not (wp is Weapon) or not wp.is_alive:
				continue
			var ac = wp.attack_coll
			if ac.attack_state == SSBDefs.nGMAttackStateOff:
				continue
			for i in mini(maxi(ac.attack_count, 1), 2):
				var ap = ac.attack_pos[i]
				if ac.attack_state == SSBDefs.nGMAttackStateInterpolate:
					_capsule(ap.pos_prev * RU.S, ap.pos_curr * RU.S, ac.size * RU.S, Color(1.0, 0.4, 0.2, 0.3))
				_sphere(ap.pos_curr * RU.S, ac.size * RU.S, Color(1.0, 0.2, 0.6, 0.45))
		for ip in Sim.get_link(SSBDefs.nGCCommonLinkIDItem):
			if not (ip is Item) or not ip.is_alive or ip.dobj == null:
				continue
			var dcl = ip.damage_coll
			if dcl.hitstatus != SSBDefs.nGMHitStatusNone and dcl.size.length() > 0.0:
				_box(Transform3D(Basis.from_scale(dcl.size * 2.0 * RU.S), (ip.dobj.translate + dcl.offset) * RU.S), Color(0.3, 0.9, 1.0, 0.25))
			var iac = ip.attack_coll
			if iac.attack_state != SSBDefs.nGMAttackStateOff:
				for i in mini(maxi(iac.attack_count, 1), 2):
					_sphere(iac.attack_pos[i].pos_curr * RU.S, iac.size * RU.S, Color(1.0, 0.2, 0.6, 0.45))
	if not any:
		lines.surface_add_vertex(Vector3.ZERO)
		lines.surface_add_vertex(Vector3.ZERO)
	lines.surface_end()
	mm_box.visible_instance_count = _nb
	mm_sph.visible_instance_count = _ns
	mm_cyl.visible_instance_count = _nc

func _line(a: Vector3, b: Vector3, col: Color) -> void:
	lines.surface_set_color(col)
	lines.surface_add_vertex(a)
	lines.surface_set_color(col)
	lines.surface_add_vertex(b)

func _skeleton(fp, jw: Array, strong: bool) -> void:
	var col := Color(0.2, 1.0, 1.0, 0.95) if strong else Color(0.6, 1.0, 1.0, 0.7)
	_walk_skel(fp.dobj, jw, col, strong)
	for i in jw.size():
		if jw[i] != null and i >= SSBDefs.nFTPartsJointCommonStart:
			var p: Vector3 = (jw[i] as Transform3D).origin * RU.S
			var s := 0.04 if strong else 0.025
			_line(p - Vector3(s, 0, 0), p + Vector3(s, 0, 0), col)
			_line(p - Vector3(0, s, 0), p + Vector3(0, s, 0), col)

func _walk_skel(d, jw: Array, col: Color, solid := false) -> void:
	if d == null:
		return
	var c = d.child
	while c != null:
		var a = _jw_of(d, jw)
		var b = _jw_of(c, jw)
		if a != null and b != null:
			var pa: Vector3 = (a as Transform3D).origin * RU.S
			var pb: Vector3 = (b as Transform3D).origin * RU.S
			_line(pa, pb, col)
			if solid and pa.distance_to(pb) > 0.01:
				_capsule(pa, pb, 0.05, Color(0.25, 0.95, 1.0, 0.85))
		_walk_skel(c, jw, col, solid)
		c = c.sib_next

func _jw_of(d, jw: Array):
	var ud = d.user_data
	if ud is FtParts and ud.joint_id >= 0 and ud.joint_id < jw.size():
		return jw[ud.joint_id]
	return null

func _stage_lines() -> bool:
	var gd = Mpcollision.gMPCollisionGroundData
	if gd == null or Mpcollision.gMPCollisionVertexInfo == null:
		return false
	var z := 0.0
	# blast zones (red) and camera bounds (blue)
	var bl := Rect2(Vector2(gd.map_bound_left, gd.map_bound_bottom), Vector2(gd.map_bound_right - gd.map_bound_left, gd.map_bound_top - gd.map_bound_bottom))
	_rect(bl, Color(1.0, 0.25, 0.25, 0.9), z)
	var cb := Rect2(Vector2(gd.camera_bound_left, gd.camera_bound_bottom), Vector2(gd.camera_bound_right - gd.camera_bound_left, gd.camera_bound_top - gd.camera_bound_bottom))
	_rect(cb, Color(0.3, 0.6, 1.0, 0.7), z)
	# collision lines by kind; ledges marked
	for line_id in Mpcollision.gMPCollisionLinesNum:
		if Mpcollision.mpCollisionCheckExistLineID(line_id) == 0:
			continue
		var kind: int = Mpcollision.mpCollisionGetLineTypeID(line_id)
		var n: int = Mpcollision.mpCollisionGetVertexCountLineID(line_id)
		var col := Color(0.3, 1.0, 0.4)
		match kind:
			SSBDefs.nMPLineKindCeil:
				col = Color(1.0, 0.5, 0.2)
			SSBDefs.nMPLineKindRWall, SSBDefs.nMPLineKindLWall:
				col = Color(0.9, 0.3, 1.0)
		var flags: int = Mpcollision.mpCollisionGetVertexFlagsLineID(line_id)
		if kind == SSBDefs.nMPLineKindFloor and (flags & 0x4000):
			col = Color(0.5, 1.0, 1.0)
		var prev := Vector3.ZERO
		for i in n:
			var v: Vector3 = Mpcollision.mpCollisionGetVertexPositionID(line_id, i) * RU.S
			if i > 0:
				_line(prev, v, col)
			prev = v
		if kind == SSBDefs.nMPLineKindFloor and (flags & 0x8000) and n >= 2:
			for e in [0, n - 1]:
				var p: Vector3 = Mpcollision.mpCollisionGetVertexPositionID(line_id, e) * RU.S
				_line(p + Vector3(0, -0.25, 0), p + Vector3(0, 0.25, 0), Color(1, 1, 0.3))
	return true

func _rect(r: Rect2, col: Color, z: float) -> void:
	var a := Vector3(r.position.x, r.position.y, z) * RU.S
	var b := Vector3(r.end.x, r.position.y, z) * RU.S
	var c := Vector3(r.end.x, r.end.y, z) * RU.S
	var d := Vector3(r.position.x, r.end.y, z) * RU.S
	_line(a, b, col)
	_line(b, c, col)
	_line(c, d, col)
	_line(d, a, col)
