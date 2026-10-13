## Headless test of the gmcollision port (plus smoke tests of gmcamera / ftphysics).
## Run: cd W/game_check && /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s res://scripts/test/test_gm.gd
##
## 1. Builds a 3-joint fighter DObj chain with FtParts and checks
##    gmCollisionGetFighterPartsWorldPosition against a hand computation (per-axis rotations with
##    the same lbCommonSin/lbCommonCos values), for both the per-joint path (is_use_animlocks
##    FALSE) and the cached world-matrix path with non-compensated scale (is_use_animlocks TRUE),
##    plus the inverse transform (func_ovl2_800EE018) and world scale extraction.
## 2. Hitbox sphere vs hurtbox box (gmCollisionCheckFighterAttackDamageCollide): point hit/miss and
##    swept-segment hit/miss.
## 3. Hitbox vs shield ellipsoid, hitbox vs hitbox (point and swept capsule), detect range.
## 4. Smoke tests of Gmcamera / Ftphysics (loaded dynamically so this test does not depend on
##    other modules compiling).
extends SceneTree

var failures: int = 0
var checks: int = 0

func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("PASS: ", what)
	else:
		failures += 1
		print("FAIL: ", what)

func near_v(a: Vector3, b: Vector3, eps: float) -> bool:
	return absf(a.x - b.x) <= eps and absf(a.y - b.y) <= eps and absf(a.z - b.z) <= eps

# ---------------------------------------------------------------------------
# Hand computation helpers (independent of the matrix code)
# ---------------------------------------------------------------------------

## Rotate p by the joint's Euler angles in the order used by gmCollisionTransformMatrixAll
## (row vectors: p * Rx(x) * Ry(y) * Rz(z)), using the game's sine/cosine tables.
func rot_xyz(p: Vector3, r: Vector3) -> Vector3:
	var sx := Port.lbCommonSin(r.x)
	var cx := Port.lbCommonCos(r.x)
	var sy := Port.lbCommonSin(r.y)
	var cy := Port.lbCommonCos(r.y)
	var sz := Port.lbCommonSin(r.z)
	var cz := Port.lbCommonCos(r.z)
	var x := p.x
	var y := p.y
	var z := p.z
	# about X
	var y1 := y * cx - z * sx
	var z1 := y * sx + z * cx
	y = y1
	z = z1
	# about Y
	var x2 := x * cy + z * sy
	var z2 := -x * sy + z * cy
	x = x2
	z = z2
	# about Z
	var x3 := x * cz - y * sz
	var y3 := x * sz + y * cz
	return Vector3(x3, y3, z)

## Plain hierarchy: p_parent = rot(p * scale) + translate, joint by joint up to the root.
func hand_world(joint: DObj, p: Vector3) -> Vector3:
	var j := joint
	while j != null:
		p = Vector3(p.x * j.scale.x, p.y * j.scale.y, p.z * j.scale.z)
		p = rot_xyz(p, j.rotate)
		p += j.translate
		j = j.parent
	return p

## Non-compensated-scale hierarchy (gmCollisionSetMatrixNcs): nscale = parent_nscale * scale;
## p_parent = (rot(p * nscale)) / parent_nscale + translate.
func hand_world_ncs(joint: DObj, p: Vector3) -> Vector3:
	var chain: Array = []
	var j := joint
	while j != null:
		chain.push_front(j)
		j = j.parent
	var nscales: Array = []
	var parent_ns = null
	for jt in chain:
		var ns: Vector3 = jt.scale if parent_ns == null else Vector3(parent_ns.x * jt.scale.x, parent_ns.y * jt.scale.y, parent_ns.z * jt.scale.z)
		nscales.append(ns)
		parent_ns = ns
	for k in range(chain.size() - 1, -1, -1):
		var jt: DObj = chain[k]
		var ns: Vector3 = nscales[k]
		p = Vector3(p.x * ns.x, p.y * ns.y, p.z * ns.z)
		p = rot_xyz(p, jt.rotate)
		if k > 0:
			var m: Vector3 = nscales[k - 1]
			p = Vector3(p.x / m.x, p.y / m.y, p.z / m.z)
		p += jt.translate
	return p

## Invalidate every cached matrix of the chain (what the animation update does each frame).
func reset_parts(joints: Array) -> void:
	for jt in joints:
		var parts: FtParts = jt.user_data
		parts.transform_update_mode = 0
		parts.unk_dobjtrans_0x5 = 0
		parts.unk_dobjtrans_0x6 = 0
		parts.unk_dobjtrans_0x7 = 0

# ---------------------------------------------------------------------------

func make_fighter_chain() -> Dictionary:
	var fp := Fighter.new()
	var j0: DObj = Objman.gcAddDObjForGObj(fp, null)
	var j1: DObj = Objman.gcAddChildForDObj(j0, null)
	var j2: DObj = Objman.gcAddChildForDObj(j1, null)
	for jt in [j0, j1, j2]:
		var parts := FtParts.new()
		parts.gobj = fp
		jt.user_data = parts
	fp.joints[0] = j0
	fp.joints[1] = j1
	fp.joints[2] = j2

	j0.translate = Vector3(100.0, 200.0, -50.0)
	j0.rotate = Vector3(0.3, -0.7, 1.1)
	j0.scale = Vector3(1.0, 1.0, 1.0)

	j1.translate = Vector3(0.0, 75.0, 10.0)
	j1.rotate = Vector3(-0.4, 0.25, 0.6)
	j1.scale = Vector3(1.5, 0.8, 1.2)

	j2.translate = Vector3(12.0, 30.0, -8.0)
	j2.rotate = Vector3(1.2, -0.3, 0.05)
	j2.scale = Vector3(1.0, 1.0, 1.0)

	fp.attr = {"hit_detect_range": Vector3(300.0, 100.0, 200.0), "cam_offset_y": 150.0}
	return {"fp": fp, "joints": [j0, j1, j2]}

func test_world_position() -> void:
	var c := make_fighter_chain()
	var fp: Fighter = c.fp
	var joints: Array = c.joints
	var j0: DObj = joints[0]
	var j2: DObj = joints[2]
	var offset := Vector3(5.0, -10.0, 20.0)

	# --- per-joint path (is_use_animlocks == FALSE)
	fp.is_use_animlocks = Port.FALSE
	reset_parts(joints)
	var expect := hand_world(j2, offset)
	var got: Vector3 = Gmcollision.gmCollisionGetFighterPartsWorldPosition(j2, offset)
	print("  world (per-joint) got ", got, " expected ", expect)
	check(near_v(got, expect, 0.01), "gmCollisionGetFighterPartsWorldPosition (is_use_animlocks FALSE) matches hand computation")
	check((j2.user_data as FtParts).transform_update_mode == 1 and (j0.user_data as FtParts).transform_update_mode == 1, "local matrices cached (transform_update_mode = 1)")

	# root joint alone: rot(p) + t
	var expect_root := rot_xyz(offset, j0.rotate) + j0.translate
	check(near_v(Gmcollision.gmCollisionGetFighterPartsWorldPosition(j0, offset), expect_root, 0.001), "root joint world position")

	# cached world matrix chain (func_ovl2_800EDBA4) gives the same answer when no scale compensation applies
	reset_parts(joints)
	Gmcollision.func_ovl2_800EDBA4(j2)
	var parts2: FtParts = j2.user_data
	check(parts2.unk_dobjtrans_0x5 == 1 and (joints[1].user_data as FtParts).unk_dobjtrans_0x5 == 1 and (j0.user_data as FtParts).unk_dobjtrans_0x5 == 1, "func_ovl2_800EDBA4 marks the whole chain world-valid")
	var via_world: Vector3 = Gmcollision.gmCollisionGetWorldPosition(parts2.mtx_translate, offset)
	check(near_v(via_world, expect, 0.01), "world matrix (mtx_translate) transform matches hand computation")
	# once the world matrix is valid the fast path is used
	check(near_v(Gmcollision.gmCollisionGetFighterPartsWorldPosition(j2, offset), expect, 0.01), "world position via cached world matrix")

	# inverse world matrix (func_ovl2_800EE018) maps the world position back to the joint space
	var back: Vector3 = Gmcollision.func_ovl2_800EE018(j2, expect)
	print("  inverse got ", back, " expected ", offset)
	check(near_v(back, offset, 0.01), "func_ovl2_800EE018 (inverse world matrix) round trip")
	check((j2.user_data as FtParts).unk_dobjtrans_0x7 == 1, "inverse matrix cached (unk_dobjtrans_0x7)")

	# world scale extraction (row norms of the world matrix). The game's sine table quantises sin and
	# cos at slightly different indices, so the rows are not exactly unit length: compute the
	# expected norms by hand from the same table values.
	reset_parts(joints)
	Gmcollision.func_ovl2_800EDE5C(j0)
	var r0 := rot_xyz(Vector3(1, 0, 0), j0.rotate) * j0.scale.x
	var r1 := rot_xyz(Vector3(0, 1, 0), j0.rotate) * j0.scale.y
	var r2 := rot_xyz(Vector3(0, 0, 1), j0.rotate) * j0.scale.z
	var expect_scale := Vector3(r0.length(), r1.length(), r2.length())
	print("  root vec_scale got ", (j0.user_data as FtParts).vec_scale, " expected ", expect_scale)
	check(near_v((j0.user_data as FtParts).vec_scale, expect_scale, 0.00001), "func_ovl2_800EDE5C root vec_scale == world matrix row norms")
	check(near_v((j0.user_data as FtParts).vec_scale, j0.scale, 0.005), "root vec_scale ~= joint scale (table sin/cos)")

	# --- world-matrix path with non-compensated scale (is_use_animlocks == TRUE)
	fp.is_use_animlocks = Port.TRUE
	reset_parts(joints)
	var expect_ncs := hand_world_ncs(j2, offset)
	var got_ncs: Vector3 = Gmcollision.gmCollisionGetFighterPartsWorldPosition(j2, offset)
	print("  world (NCS) got ", got_ncs, " expected ", expect_ncs)
	check(near_v(got_ncs, expect_ncs, 0.01), "gmCollisionGetFighterPartsWorldPosition (is_use_animlocks TRUE, gmCollisionSetMatrixNcs) matches hand computation")
	var ns2: Vector3 = (j2.user_data as FtParts).vec_scale
	check(near_v(ns2, Vector3(1.5, 0.8, 1.2), 0.0001), "NCS vec_scale accumulates parent scale")
	check(near_v(Gmcollision.func_ovl2_800EE018(j2, got_ncs), offset, 0.01), "NCS inverse round trip")

	# --- matrix helpers
	var m := PackedFloat32Array([1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0])
	var src := PackedFloat32Array([0, 1, 0, -1, 0, 0, 0, 0, 1, 7, 8, 9])
	var ret: PackedFloat32Array = Gmcollision.gmCollisionCopyMatrix(m, src)
	check(m == src and ret == src, "gmCollisionCopyMatrix copies in place and returns dst")
	check(Gmcollision.func_ovl2_800EDB88(src) == Vector3(7, 8, 9), "func_ovl2_800EDB88 translation row")
	var rot: Vector3 = Gmcollision.func_ovl2_800EDA0C(src)
	# src rows: x->(0,1,0), y->(-1,0,0): rotation of +90 deg about Z
	check(absf(rot.z - PI / 2.0) < 0.001 and absf(rot.x) < 0.001 and absf(rot.y) < 0.001, "func_ovl2_800EDA0C extracts rotate.z = 90 deg (got %s)" % rot)

func test_hurtbox() -> void:
	var c := make_fighter_chain()
	var fp: Fighter = c.fp
	var joints: Array = c.joints
	var j2: DObj = joints[2]
	fp.is_use_animlocks = Port.FALSE

	var dc := FTDamageColl.new()
	dc.joint = j2
	dc.joint_id = 2
	dc.offset = Vector3(0.0, 10.0, 0.0)
	dc.size = Vector3(20.0, 15.0, 10.0)

	var ac := FTAttackColl.new()
	ac.size = 5.0

	# point (transfer) test inside the box
	reset_parts(joints)
	ac.attack_state = SSBDefs.nGMAttackStateTransfer
	ac.pos_curr = Gmcollision.gmCollisionGetFighterPartsWorldPosition(j2, dc.offset + Vector3(3.0, -4.0, 2.0))
	ac.pos_prev = ac.pos_curr
	check(Gmcollision.gmCollisionCheckFighterAttackDamageCollide(ac, dc) == Port.TRUE, "sphere hitbox inside hurtbox box -> hit")

	# the box is grown by radius / world scale of the joint (vec_scale = world matrix row norms)
	reset_parts(joints)
	Gmcollision.func_ovl2_800EDE5C(j2)
	var grow_x: float = ac.size / (j2.user_data as FtParts).vec_scale.x
	print("  j2 vec_scale ", (j2.user_data as FtParts).vec_scale, " -> box grows by ", grow_x, " along local x")

	# just outside the box but within the hitbox radius -> still a hit
	reset_parts(joints)
	ac.pos_curr = Gmcollision.gmCollisionGetFighterPartsWorldPosition(j2, dc.offset + Vector3(dc.size.x + 0.8 * grow_x, 0.0, 0.0))
	ac.pos_prev = ac.pos_curr
	check(Gmcollision.gmCollisionCheckFighterAttackDamageCollide(ac, dc) == Port.TRUE, "sphere hitbox overlapping the box face -> hit")

	# just beyond the grown box -> miss
	reset_parts(joints)
	ac.pos_curr = Gmcollision.gmCollisionGetFighterPartsWorldPosition(j2, dc.offset + Vector3(dc.size.x + 1.2 * grow_x, 0.0, 0.0))
	ac.pos_prev = ac.pos_curr
	check(Gmcollision.gmCollisionCheckFighterAttackDamageCollide(ac, dc) == Port.FALSE, "sphere hitbox just beyond radius / scale -> miss")

	# far outside -> miss
	reset_parts(joints)
	ac.pos_curr = Gmcollision.gmCollisionGetFighterPartsWorldPosition(j2, dc.offset + Vector3(dc.size.x + 40.0, 0.0, 0.0))
	ac.pos_prev = ac.pos_curr
	check(Gmcollision.gmCollisionCheckFighterAttackDamageCollide(ac, dc) == Port.FALSE, "sphere hitbox outside hurtbox box -> miss")

	# swept segment (interpolate) passing through the box -> hit, both ends outside
	reset_parts(joints)
	ac.attack_state = SSBDefs.nGMAttackStateInterpolate
	ac.pos_prev = Gmcollision.gmCollisionGetFighterPartsWorldPosition(j2, dc.offset + Vector3(-100.0, 2.0, 1.0))
	ac.pos_curr = Gmcollision.gmCollisionGetFighterPartsWorldPosition(j2, dc.offset + Vector3(100.0, -2.0, -1.0))
	check(Gmcollision.gmCollisionCheckFighterAttackDamageCollide(ac, dc) == Port.TRUE, "swept hitbox crossing the box -> hit")

	# swept segment passing above the box -> miss
	reset_parts(joints)
	ac.pos_prev = Gmcollision.gmCollisionGetFighterPartsWorldPosition(j2, dc.offset + Vector3(-100.0, 60.0, 0.0))
	ac.pos_curr = Gmcollision.gmCollisionGetFighterPartsWorldPosition(j2, dc.offset + Vector3(100.0, 60.0, 0.0))
	check(Gmcollision.gmCollisionCheckFighterAttackDamageCollide(ac, dc) == Port.FALSE, "swept hitbox passing above the box -> miss")

	# item hurtbox (no matrix, item scale)
	var item := Item.new()
	item.dobj = DObj.new()
	item.dobj.translate = Vector3(500.0, 0.0, 0.0)
	var idc := ITDamageColl.new()
	idc.offset = Vector3(0.0, 20.0, 0.0)
	idc.size = Vector3(30.0, 30.0, 30.0)
	ac.attack_state = SSBDefs.nGMAttackStateTransfer
	ac.pos_curr = Vector3(520.0, 40.0, 0.0)
	ac.pos_prev = ac.pos_curr
	check(Gmcollision.gmCollisionCheckFighterAttackItemDamageCollide(ac, idc, item) == Port.TRUE, "hitbox vs item hurtbox -> hit")
	ac.pos_curr = Vector3(600.0, 40.0, 0.0)
	ac.pos_prev = ac.pos_curr
	check(Gmcollision.gmCollisionCheckFighterAttackItemDamageCollide(ac, idc, item) == Port.FALSE, "hitbox vs item hurtbox -> miss")

	# impact position helper: midpoint of the hitbox and the hurtbox center
	reset_parts(joints)
	Gmcollision.func_ovl2_800EDBA4(j2)
	ac.pos_curr = Vector3(10.0, 20.0, 30.0)
	var hurt_center: Vector3 = Gmcollision.gmCollisionGetWorldPosition((j2.user_data as FtParts).mtx_translate, dc.offset)
	var impact: Vector3 = Gmcollision.gmCollisionGetFighterAttackDamagePosition(ac, dc)
	check(near_v(impact, (ac.pos_curr + hurt_center) * 0.5, 0.001), "gmCollisionGetFighterAttackDamagePosition midpoint")

func test_shield_and_hitboxes() -> void:
	var c := make_fighter_chain()
	var fp: Fighter = c.fp
	var joints: Array = c.joints
	var j1: DObj = joints[1]
	fp.is_use_animlocks = Port.FALSE

	# shield: radius-30 ellipsoid (scaled by the joint's world scale) at the joint origin
	reset_parts(joints)
	var center: Vector3 = Gmcollision.gmCollisionGetFighterPartsWorldPosition(j1, Vector3.ZERO)
	var ac := FTAttackColl.new()
	ac.size = 5.0
	ac.attack_state = SSBDefs.nGMAttackStateTransfer
	ac.pos_curr = center + Vector3(10.0, 0.0, 0.0)
	ac.pos_prev = ac.pos_curr
	var r: Dictionary = Gmcollision.gmCollisionCheckFighterAttackShieldCollide(ac, fp, j1)
	check(r.ret == Port.TRUE and is_equal_approx(r.p_angle, Gmcollision.F_CLC_DTOR32_180), "hitbox inside shield -> hit, p_angle = 180 deg")
	ac.pos_curr = center + Vector3(300.0, 0.0, 0.0)
	ac.pos_prev = ac.pos_curr
	r = Gmcollision.gmCollisionCheckFighterAttackShieldCollide(ac, fp, j1, 1.25)
	check(r.ret == Port.FALSE and r.p_angle == 1.25, "hitbox outside shield -> miss, p_angle untouched")

	# weapon swept through the shield (sphit_kind 1 computes angle + rotation axis)
	var wac := WPAttackColl.new()
	wac.size = 4.0
	wac.attack_state = SSBDefs.nGMAttackStateInterpolate
	wac.attack_pos[0].pos_prev = center + Vector3(-200.0, 3.0, 0.0)
	wac.attack_pos[0].pos_curr = center + Vector3(200.0, -3.0, 0.0)
	var rw: Dictionary = Gmcollision.gmCollisionCheckWeaponAttackShieldCollide(wac, 0, fp, j1)
	print("  weapon vs shield ", rw)
	check(rw.ret == Port.TRUE and rw.has("p_angle") and rw.has("vec"), "swept weapon through shield -> hit with p_angle / vec outputs")
	wac.attack_pos[0].pos_prev = center + Vector3(-200.0, 300.0, 0.0)
	wac.attack_pos[0].pos_curr = center + Vector3(200.0, 300.0, 0.0)
	check(Gmcollision.gmCollisionCheckWeaponAttackShieldCollide(wac, 0, fp, j1).ret == Port.FALSE, "swept weapon above shield -> miss")

	# fighter hitbox vs fighter hitbox (points)
	var a1 := FTAttackColl.new()
	var a2 := FTAttackColl.new()
	a1.size = 10.0
	a2.size = 10.0
	a1.attack_state = SSBDefs.nGMAttackStateTransfer
	a2.attack_state = SSBDefs.nGMAttackStateTransfer
	a1.pos_curr = Vector3(0, 0, 0)
	a1.pos_prev = a1.pos_curr
	a2.pos_curr = Vector3(15, 0, 0)
	a2.pos_prev = a2.pos_curr
	check(Gmcollision.gmCollisionCheckFighterAttacksCollide(a1, a2) == Port.TRUE, "hitbox vs hitbox (points, dist 15 < 20) -> clang")
	a2.pos_curr = Vector3(25, 0, 0)
	a2.pos_prev = a2.pos_curr
	check(Gmcollision.gmCollisionCheckFighterAttacksCollide(a1, a2) == Port.FALSE, "hitbox vs hitbox (points, dist 25 > 20) -> none")

	# point vs swept vertical capsule (general branch of func_ovl2_800EE050)
	a2.attack_state = SSBDefs.nGMAttackStateInterpolate
	a2.attack_matrix_unk_fthitmtx_0x0 = Port.FALSE
	a2.pos_curr = Vector3(0, -50, 0)
	a2.pos_prev = Vector3(0, 50, 0)
	a1.pos_curr = Vector3(15, 0, 0)
	a1.pos_prev = a1.pos_curr
	check(Gmcollision.gmCollisionCheckFighterAttacksCollide(a1, a2) == Port.TRUE, "point vs swept capsule (dist 15 < 20) -> clang")
	check(a2.attack_matrix_unk_fthitmtx_0x0 == Port.TRUE and absf(a2.attack_matrix_unk_fthitmtx_0x44 - 50.0) < 0.0001, "capsule frame cached (unk_fthitmtx_0x0 = TRUE, half length 50)")
	a1.pos_curr = Vector3(25, 0, 0)
	a1.pos_prev = a1.pos_curr
	check(Gmcollision.gmCollisionCheckFighterAttacksCollide(a1, a2) == Port.FALSE, "point vs swept capsule (dist 25 > 20) -> none")

	# coarse detect range
	var victim := Fighter.new()
	victim.dobj = DObj.new()
	victim.dobj.translate = Vector3(0, 0, 0)
	victim.attr = {"hit_detect_range": Vector3(300.0, 100.0, 200.0)}
	a1.attack_state = SSBDefs.nGMAttackStateTransfer
	a1.pos_curr = Vector3(150, 250, 0)
	check(Gmcollision.gmCollisionCheckFighterInFighterRange(a1, victim) == Port.TRUE, "attack inside hit_detect_range")
	a1.pos_curr = Vector3(150, -150, 0)
	check(Gmcollision.gmCollisionCheckFighterInFighterRange(a1, victim) == Port.FALSE, "attack below hit_detect_range")

# ---------------------------------------------------------------------------
# Smoke tests (scripts loaded dynamically)
# ---------------------------------------------------------------------------

func test_camera_smoke() -> void:
	var GmcameraS = load("res://scripts/gm/Gmcamera.gd")
	if (GmcameraS == null) or (GmcameraS.get("gGMCameraStruct") == null):
		print("SKIP: Gmcamera did not compile (see errors above: a module it depends on is broken)")
		return
	var MpcollisionS = load("res://scripts/mp/Mpcollision.gd")
	Sim.reset()
	var ground_data_saved = MpcollisionS.gMPCollisionGroundData
	MpcollisionS.gMPCollisionGroundData = {
		"camera_bound_top": 4000, "camera_bound_bottom": -2000, "camera_bound_right": 4000, "camera_bound_left": -4000,
		"camera_bound_team_top": 4000, "camera_bound_team_bottom": -2000, "camera_bound_team_right": 4000, "camera_bound_team_left": -4000,
		"map_bound_top": 6000, "light_angle": Vector3(0.0, 0.0, 0.0),
	}
	GmcameraS.gmCameraSetViewportDimensions(10, 10, 310, 230)
	GmcameraS.gmCameraMakeBattleCamera()
	var cam_gobj = GmcameraS.gGMCameraGObj
	check(cam_gobj != null and GmcameraS.CObjGetStruct(cam_gobj) != null, "gmCameraMakeBattleCamera creates the camera GObj + CObj")

	var fp := Fighter.new()
	fp.dobj = DObj.new()
	fp.dobj.translate = Vector3(1200.0, 300.0, 0.0)
	fp.attr = {"cam_offset_y": 150.0}
	fp.camera_zoom_frame = 1.0
	fp.camera_zoom_range = 1.0
	Sim.add_gobj(fp, SSBDefs.nGCCommonLinkIDFighter)

	var eye0: Vector3 = GmcameraS.gGMCameraRenderEye
	for i in 120:
		Sim.run_frame()    # the camera process (gmCameraRunFuncCamera, priority 3)
	var cobj = GmcameraS.CObjGetStruct(cam_gobj)
	var interests: Dictionary = GmcameraS.gmCameraUpdateInterests()
	print("  camera at ", cobj.vec.at, " eye ", cobj.vec.eye, " interest ", interests.vec, " fovy ", GmcameraS.gGMCameraRenderFovy)
	check(GmcameraS.gGMCameraRenderEye != eye0 and GmcameraS.gGMCameraRenderEye == cobj.vec.eye, "camera process runs every frame and publishes eye")
	check(cobj.vec.at.distance_to(interests.vec) < 50.0, "camera 'at' converges to the interest point")
	check(absf(GmcameraS.gGMCameraRenderFovy - 38.0) < 0.001, "fovy eased to 38")

	GmcameraS.gmCameraLookAtFuncMatrix(null, cobj, null)
	var screen: Vector2 = GmcameraS._gmCameraProjectScreen(cobj, GmcameraS.gGMCameraMatrix, cobj.vec.at)
	check(GmcameraS.gmCameraGetMatrixMax() > 0.0 and screen.length() < 0.5, "gGMCameraMatrix projects 'at' to the screen center (got %s)" % screen)

	# bounds clamp
	var clamped: Vector3 = GmcameraS.gmCameraSetBoundsPosition(Vector3(9000.0, -5000.0, 0.0))
	check(clamped == Vector3(4000.0, -2000.0, 0.0), "gmCameraSetBoundsPosition clamps to the stage camera bounds")
	MpcollisionS.gMPCollisionGroundData = ground_data_saved
	Sim.reset()

func test_physics_smoke() -> void:
	var FtphysicsS = load("res://scripts/ft/Ftphysics.gd")
	var fp := Fighter.new()
	fp.dobj = DObj.new()
	fp.attr = {"gravity": 0.85, "tvel_base": 30.0, "tvel_fast": 45.0, "air_speed_max_x": 3.0, "air_accel": 0.0625, "air_friction": 0.05, "traction": 0.08}
	# a call into a script that failed to compile returns null
	if (FtphysicsS == null) or (FtphysicsS.ftPhysicsCheckClampAirVelXDec(fp, 100.0) == null):
		print("SKIP: Ftphysics did not compile (see errors above: a module it depends on is broken)")
		return
	fp.physics.vel_air = Vector3(4.0, -29.5, 0.0)
	fp.input.pl.stick_range = Vector2i(0, 0)
	FtphysicsS.ftPhysicsApplyAirVelDrift(fp)
	check(is_equal_approx(fp.physics.vel_air.y, -30.0), "gravity clamped to -tvel_base")
	check(is_equal_approx(fp.physics.vel_air.x, 3.0), "air x speed above max decelerates by 1 and clamps to air_speed_max_x")

	fp.physics.vel_ground = Vector3(2.0, 0.0, 0.0)
	fp.coll_data.floor_flags = 1          # material 1: friction 3.0
	fp.coll_data.floor_angle = Vector3(0.0, 1.0, 0.0)
	fp.lr = 1
	FtphysicsS.ftPhysicsApplyGroundVelFriction(fp)
	check(is_equal_approx(fp.physics.vel_ground.x, 2.0 - 3.0 * 0.08), "ground friction (material table * traction)")
	check(is_equal_approx(fp.physics.vel_air.x, fp.physics.vel_ground.x), "ground velocity transferred to vel_air")

	var r: Dictionary = FtphysicsS.ftPhysicsGetAirVelTransN(_transn_fighter())
	check(r.has("x") and r.has("y") and r.has("z"), "ftPhysicsGetAirVelTransN returns {z, y, x}")

func _transn_fighter() -> Fighter:
	var fp := Fighter.new()
	var top := DObj.new()
	var transn := DObj.new()
	transn.translate = Vector3(1.0, 2.0, 3.0)
	fp.joints[SSBDefs.nFTPartsJointTopN] = top
	fp.joints[SSBDefs.nFTPartsJointTransN] = transn
	return fp

func _init() -> void:
	print("== gmcollision: joint world matrices ==")
	test_world_position()
	print("== gmcollision: hitbox vs hurtbox ==")
	test_hurtbox()
	print("== gmcollision: shield / hitbox vs hitbox / range ==")
	test_shield_and_hitboxes()
	print("== gmcamera smoke ==")
	test_camera_smoke()
	print("== ftphysics smoke ==")
	test_physics_smoke()
	print("%d checks, %d failed" % [checks, failures])
	quit(1 if failures else 0)
