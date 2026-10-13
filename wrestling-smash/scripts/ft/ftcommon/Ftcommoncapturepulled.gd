## 1:1 port of src/ft/ftcommon/ftcommoncapturepulled.c (ssb-decomp-re): CapturePulled (victim being
## pulled into the grab) and the hand-joint attachment used by every held/thrown status.
class_name Ftcommoncapturepulled
extends Port

## C f32 arithmetic (single-precision rounding of every intermediate result).
static func _f32(x: float) -> float:
	return Vector2(x, 0.0).x

## sqrtf(SQUARE(m[row][0]) + SQUARE(m[row][1]) + SQUARE(m[row][2])) evaluated in f32.
static func _f32_row_mag(m: PackedFloat32Array, row: int) -> float:
	var sum: float = _f32(_f32(_f32(m[row * 3 + 0] * m[row * 3 + 0]) + _f32(m[row * 3 + 1] * m[row * 3 + 1])) + _f32(m[row * 3 + 2] * m[row * 3 + 2]))

	return _f32(sqrtf(sum))

## Local 1:1 port of func_ovl0_800C9A38 (src/lb/lbcommon.c, 0x800C9A38): world matrix of a fighter
## joint with the scale removed from every row (Mtx44f = 4x3 row-major PackedFloat32Array, see
## Gmcollision). Lbcommon.gd currently keeps this function as a (display-side) stub, but the grab
## code uses it to place the captured fighter on the thrower's hand, so it is only used when
## Lbcommon's version leaves the matrix untouched (see ftCommonCapturePulledRotateScale).
static func _func_ovl0_800C9A38(mtx: PackedFloat32Array, dobj: DObj) -> PackedFloat32Array:
	var parts: FtParts = dobj.user_data
	var fp := ftGetStruct(dobj.parent_gobj)
	var p: PackedFloat32Array
	var scale: float
	var parent_dobj: DObj
	var f := PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])   # Mtx44f f
	var i: int

	if B(fp.is_use_animlocks) or (dobj.parent == DOBJ_PARENT_NULL):
		Gmcollision.func_ovl2_800EDBA4(dobj)

		p = parts.mtx_translate

		i = 0
		while i < 3:
			scale = _f32_row_mag(p, i)

			if scale != 0.0:
				scale = _f32(1.0 / scale)
			mtx[i * 3 + 0] = p[i * 3 + 0] * scale
			mtx[i * 3 + 1] = p[i * 3 + 1] * scale
			mtx[i * 3 + 2] = p[i * 3 + 2] * scale
			i += 1
		mtx[9] = p[9]
		mtx[10] = p[10]
		mtx[11] = p[11]
	else:
		parent_dobj = dobj.parent

		Gmcollision.gmCollisionTransformMatrixAll(dobj, parts, parts.unk_dobjtrans_0x10)

		p = parts.unk_dobjtrans_0x10

		i = 0
		while i < 3:
			scale = _f32_row_mag(p, i)

			if scale != 0.0:
				scale = _f32(1.0 / scale)
			f[i * 3 + 0] = p[i * 3 + 0] * scale
			f[i * 3 + 1] = p[i * 3 + 1] * scale
			f[i * 3 + 2] = p[i * 3 + 2] * scale
			i += 1
		f[9] = p[9]
		f[10] = p[10]
		f[11] = p[11]

		Gmcollision.func_ovl2_800EDBA4(parent_dobj)

		p = parent_dobj.user_data.mtx_translate

		# column j of f is divided by the scale of row j of the parent's world matrix
		i = 0
		while i < 3:
			scale = _f32_row_mag(p, i)

			if scale != 0.0:
				scale = _f32(1.0 / scale)
			f[0 * 3 + i] *= scale
			f[1 * 3 + i] *= scale
			f[2 * 3 + i] *= scale
			i += 1
		Gmcollision.func_ovl2_800ED490(mtx, p, f)
	return mtx

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8014A5F0 (REGION_US path)
## C: void ftCommonCapturePulledRotateScale(GObj *fighter_gobj, Vec3f *this_pos, Vec3f *rotate)
## Both pointer params are pure outputs -> returns {"this_pos": Vector3, "rotate": Vector3}
## (the optional this_pos/rotate arguments are ignored; they only keep the C parameter list).
static func ftCommonCapturePulledRotateScale(fighter_gobj, this_pos = null, rotate = null) -> Dictionary:
	var this_fp := ftGetStruct(fighter_gobj)
	var capture_fp := ftGetStruct(this_fp.capture_gobj)
	var joint: DObj = DObjGetStruct(fighter_gobj).child
	# Mtx44f mtx (4x3 row-major PackedFloat32Array, see Gmcollision); fully written below
	var mtx := PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
	var out_pos: Vector3
	var out_rotate: Vector3
	var hand_joint: DObj = capture_fp.joints[capture_fp.attr.joint_itemheavy_id]

	# func_ovl0_800C9A38(mtx, hand_joint): writes mtx (in place and/or returned)
	var mtx_ret = Lbcommon.func_ovl0_800C9A38(mtx, hand_joint)

	if mtx_ret is PackedFloat32Array:
		mtx = mtx_ret
	elif mtx == PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]):
		# Lbcommon's func_ovl0_800C9A38 is still a stub: use the local port
		mtx = _func_ovl0_800C9A38(mtx, hand_joint)
	out_rotate = Gmcollision.func_ovl2_800EDA0C(mtx)

	out_pos.x = (-joint.translate.x * DObjGetStruct(fighter_gobj).scale.x)
	out_pos.y = (-joint.translate.y * DObjGetStruct(fighter_gobj).scale.y)
	out_pos.z = (-joint.translate.z * DObjGetStruct(fighter_gobj).scale.z)

	out_pos = Gmcollision.gmCollisionGetWorldPosition(mtx, out_pos)

	return {"this_pos": out_pos, "rotate": out_rotate}

## 0x8014A6B4
static func ftCommonCapturePulledProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3

	# ftCommonCapturePulledRotateScale(fighter_gobj, &pos, &DObjGetStruct(fighter_gobj)->rotate)
	var r: Dictionary = ftCommonCapturePulledRotateScale(fighter_gobj)
	pos = r.this_pos
	DObjGetStruct(fighter_gobj).rotate = r.rotate

	DObjGetStruct(fighter_gobj).translate.x = pos.x
	DObjGetStruct(fighter_gobj).translate.z = pos.z

	if (fp.status_id == nFTCommonStatusCapturePulled) and B(fp.status_vars.common.capture.is_goto_pulled_wait):
		Ftcommoncapturewait.ftCommonCaptureWaitSetStatus(fighter_gobj)

## 0x8014A72C
static func ftCommonCapturePulledProcMap(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var capture_gobj = this_fp.capture_gobj
	var capture_fp := ftGetStruct(capture_gobj)
	var this_dobj := DObjGetStruct(fighter_gobj)    # Vec3f *this_pos = &this_dobj->translate
	var capture_pos: Vector3
	var dist_y: float

	# mpCollisionGetFCCommonFloor(line_id, this_pos, &dist_y, &floor_flags, &floor_angle)
	var r = Mpcollision.mpCollisionGetFCCommonFloor(capture_fp.coll_data.floor_line_id, this_dobj.translate)

	if B(r.ret):
		dist_y = r.dist
		this_fp.coll_data.floor_flags = r.flags
		this_fp.coll_data.floor_angle = r.angle

		this_fp.coll_data.floor_line_id = capture_fp.coll_data.floor_line_id

		if dist_y >= 0.0:
			this_dobj.translate.y += dist_y

			this_fp.ga = nMPKineticsGround
			this_fp.jumps_used = 0
		else:
			this_dobj.translate.y += dist_y * 0.5

			this_fp.ga = nMPKineticsAir
			this_fp.jumps_used = 1
	else:
		if capture_fp.lr == +1:
			capture_pos = Mpcollision.mpCollisionGetFloorEdgeR(capture_fp.coll_data.floor_line_id)
		else:
			capture_pos = Mpcollision.mpCollisionGetFloorEdgeL(capture_fp.coll_data.floor_line_id)

		this_dobj.translate.y = this_dobj.translate.y + ((capture_pos.y - this_dobj.translate.y) * 0.5)

		Mpcommon.mpCommonSetFighterProjectFloor(fighter_gobj)

		this_fp.ga = nMPKineticsAir
		this_fp.jumps_used = 1

## 0x8014A860
static func ftCommonCapturePulledProcCapture(fighter_gobj, capture_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var capture_fp: Fighter

	Ftparam.ftParamStopVoiceRunProcDamage(fighter_gobj)

	if (this_fp.item_gobj != null) and (itGetStruct(this_fp.item_gobj).weight == nITWeightHeavy):
		Itmain.itMainSetFighterDrop(this_fp.item_gobj, Vector3.ZERO, 1.0)    # ftSetupDropItem(this_fp)
	if this_fp.catch_gobj != null:
		Ftcommonthrown2.ftCommonThrownSetStatusDamageRelease(this_fp.catch_gobj)

		this_fp.catch_gobj = null
	elif this_fp.capture_gobj != null:
		Ftcommonthrown2.ftCommonThrownDecideFighterLoseGrip(this_fp.capture_gobj, fighter_gobj)
	this_fp.is_catch_or_capture = FALSE

	this_fp.capture_gobj = capture_gobj

	capture_fp = ftGetStruct(capture_gobj)

	this_fp.lr = -capture_fp.lr

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCapturePulled, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	this_fp.status_vars.common.capture.is_goto_pulled_wait = FALSE

	Ftparam.ftParamSetCaptureImmuneMask(this_fp, FTCATCHKIND_MASK_ALL)
	Ftparam.ftParamMakeRumble(this_fp, 9, 0)
	Ftphysics.ftPhysicsStopVelAll(fighter_gobj)
	ftCommonCapturePulledProcPhysics(fighter_gobj)
	ftCommonCapturePulledProcMap(fighter_gobj)
