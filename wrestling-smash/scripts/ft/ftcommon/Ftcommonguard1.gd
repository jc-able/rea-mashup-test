## 1:1 port of src/ft/ftcommon/ftcommonguard1.c (ssb-decomp-re): GuardOn / Guard (shield) statuses,
## shield decay, shield size and shield tilt (pose) handling.
##
## Data assumptions (FTAttributes fields resolved by the fighter data loader, C field names):
##   attr.shield_anim_joints : Array[8] (one per 45 degree direction), each an Array of AnimStream
##                             (C: AObjEvent32 **shield_anim_joints[8]; one script per joint in tree order, null if none)
##   attr.dobj_lookup        : Array of DObjDesc Dictionaries {id, translate: Vector3, rotate: Vector3, scale: Vector3}
##                             (C: DObjDesc *dobj_lookup)
##   attr.translate_scales   : null or Array of Vector3 (C: Vec3f *translate_scales)
## The shield-angle maths is evaluated with explicit f32 rounding because its result is truncated
## to an integer (angle_i): double-precision evaluation flips the result at exact multiples of 45 degrees.
class_name Ftcommonguard1
extends Port

## PI32 (3.1415927F) rounded to f32, used by F_CLC_RTOD32(x) = ((x) / PI32) * 180.0F
const _PI32_F32 := 3.1415927410125732
## F_CST_DTOR32(360.0F) = (float)(360.0F * DTOR32) as f32
const _F_CST_DTOR32_360_F32 := 6.2831854820251465

## C f32 rounding of an intermediate result (the original computes in single precision).
static func _f32(x: float) -> float:
	var a := PackedFloat32Array([x])
	return a[0]

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

## ftCommonGuardCheckInterrupt (macro in ftcommonguard1.c): short-circuit || chain, exact C order.
static func ftCommonGuardCheckInterrupt(fighter_gobj) -> bool:
	return (
		Ftcommonitemthrow.ftCommonLightThrowCheckInterruptGuardOn(fighter_gobj) or
		Ftcommonescape.ftCommonEscapeCheckInterruptGuard(fighter_gobj) or
		Ftcommoncatch1.ftCommonCatchCheckInterruptGuard(fighter_gobj) or
		Ftcommonkneebend.ftCommonGuardKneeBendCheckInterruptGuard(fighter_gobj) or
		Ftcommonpass.ftCommonGuardPassCheckInterruptGuard(fighter_gobj)
	)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80148120
static func ftCommonGuardCheckScheduleRelease(fp: Fighter) -> void:
	if not (fp.input.pl.button_hold & fp.input.button_mask_z):
		fp.status_vars.common.guard.is_release = TRUE

## 0x80148144
## Set all of Yoshi's hurtbox collision states to invincible (GuardOn)
static func ftCommonGuardOnSetHitStatusYoshi(fighter_gobj) -> void:
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 5,  nGMHitStatusInvincible)
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 6,  nGMHitStatusInvincible)
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 7,  nGMHitStatusInvincible)
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 15, nGMHitStatusInvincible)
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 11, nGMHitStatusInvincible)
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 16, nGMHitStatusInvincible)
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 12, nGMHitStatusInvincible)
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 27, nGMHitStatusInvincible)
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 22, nGMHitStatusInvincible)
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 28, nGMHitStatusInvincible)
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 23, nGMHitStatusInvincible)

## 0x80148214
## Set all of Yoshi's hurtbox collision states to intangible (Guard)
static func ftCommonGuardSetHitStatusYoshi(fighter_gobj) -> void:
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 5,  nGMHitStatusNormal)
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 6,  nGMHitStatusIntangible)
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 7,  nGMHitStatusIntangible)
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 15, nGMHitStatusIntangible)
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 11, nGMHitStatusIntangible)
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 16, nGMHitStatusIntangible)
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 12, nGMHitStatusIntangible)
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 27, nGMHitStatusIntangible)
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 22, nGMHitStatusIntangible)
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 28, nGMHitStatusIntangible)
	Ftparam.ftParamSetHitStatusPartID(fighter_gobj, 23, nGMHitStatusIntangible)

## 0x801482E4
static func ftCommonGuardOffSetHitStatusYoshi(fighter_gobj) -> void:
	Ftparam.ftParamSetHitStatusPartAll(fighter_gobj, nGMHitStatusNormal)

## 0x80148304
static func ftCommonGuardUpdateShieldVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.is_shield:
		var goto_lag_end := false

		if fp.status_vars.common.guard.shield_decay_wait != 0:
			fp.status_vars.common.guard.shield_decay_wait -= 1

			if fp.status_vars.common.guard.shield_decay_wait == 0:
				fp.shield_health -= 1

				if fp.shield_health != 0:
					fp.status_vars.common.guard.shield_decay_wait = FTCOMMON_GUARD_DECAY_INT

					# goto lag_decrement;
				else:
					goto_lag_end = true   # goto lag_end;
		if not goto_lag_end:
			# lag_decrement:
			if fp.status_vars.common.guard.release_lag != 0:
				fp.status_vars.common.guard.release_lag -= 1
			if (fp.status_vars.common.guard.release_lag == 0) and (fp.status_vars.common.guard.is_release != FALSE):
				goto_lag_end = true
		if goto_lag_end:
			# lag_end:
			if fp.fkind == nFTKindYoshi:
				Ftparam.ftParamResetModelPartAll(fighter_gobj)
				ftCommonGuardOffSetHitStatusYoshi(fighter_gobj)

				if fp.is_effect_attach:
					# 0x801886C0
					var egg_effect_offset = Vector3(0.0, 0.0, 0.0)

					egg_effect_offset = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[nFTPartsJointYRotN], egg_effect_offset)
					Efmanager.efManagerEggBreakMakeEffect(egg_effect_offset)
			Ftparam.ftParamProcStopEffect(fighter_gobj)

			fp.is_shield = FALSE

## 0x80148408
static func ftCommonGuardUpdateShieldCollision(fp: Fighter) -> void:
	# Vec3f *scale = &fp->joints[nFTPartsJointYRotN]->scale.vec.f;
	var scale_final: float
	var scale_mul: float

	if fp.fkind == nFTKindYoshi:
		scale_mul = 1.0
	else:
		scale_mul = _f32(fp.shield_health / FTCOMMON_GUARD_SIZE_HEALTH_DIV)

	scale_final = _f32(
		_f32(
			_f32(
				_f32(_f32(FTCOMMON_GUARD_SIZE_SCALE_MUL_INIT) * scale_mul) +
				_f32(FTCOMMON_GUARD_SIZE_SCALE_MUL_ADD)
			) * fp.attr.shield_size
		) / FTCOMMON_GUARD_SIZE_SCALE_MUL_DIV
	)

	# scale->x = scale->y = scale->z = scale_final;
	fp.joints[nFTPartsJointYRotN].scale = Vector3(scale_final, scale_final, scale_final)

## 0x80148488
static func ftCommonGuardUpdateShieldAngle(fp: Fighter) -> void:
	var angle_r: float = _f32(syUtilsArcTan2(fp.input.pl.stick_range.y, fp.input.pl.stick_range.x * fp.lr))
	var angle_d: float
	var range_: float

	if angle_r < 0.0:
		angle_r = _f32(angle_r + _F_CST_DTOR32_360_F32)   # F_CST_DTOR32(360.0F)
	angle_d = _f32(_f32(angle_r / _PI32_F32) * 180.0)      # F_CLC_RTOD32(angle_r)

	if angle_d < 0.0:
		angle_d = 0.0
	if angle_d > FTCOMMON_GUARD_ANGLE_MAX:
		angle_d = FTCOMMON_GUARD_ANGLE_MAX
	fp.status_vars.common.guard.angle_i = int(_f32(angle_d / 45.0))   # f32 -> s32
	fp.status_vars.common.guard.angle_f = _f32(angle_d - _f32(fp.status_vars.common.guard.angle_i * 45.0))

	range_ = _f32(_f32(sqrtf(SQUARE(fp.input.pl.stick_range.x) + SQUARE(fp.input.pl.stick_range.y))) / float(F_CONTROLLER_RANGE_MAX))

	if range_ > 1.0:
		range_ = 1.0
	fp.status_vars.common.guard.shield_rotate_range = range_

## WARNING: Actually DObjDesc*? (no address comment in the decomp)
static func ftCommonGuardGetJointTransform(joint: DObj, dobjdesc, range_: float) -> void:
	joint.rotate.x = ((joint.rotate.x - dobjdesc.rotate.x) * range_) + dobjdesc.rotate.x
	joint.rotate.y = ((joint.rotate.y - dobjdesc.rotate.y) * range_) + dobjdesc.rotate.y
	joint.rotate.z = ((joint.rotate.z - dobjdesc.rotate.z) * range_) + dobjdesc.rotate.z

	joint.translate.x = ((joint.translate.x - dobjdesc.translate.x) * range_) + dobjdesc.translate.x
	joint.translate.y = ((joint.translate.y - dobjdesc.translate.y) * range_) + dobjdesc.translate.y
	joint.translate.z = ((joint.translate.z - dobjdesc.translate.z) * range_) + dobjdesc.translate.z

## WARNING: Actually DObjDesc*? (no address comment in the decomp)
## C: Vec3f *scale is only read -> passed by value.
static func ftCommonGuardGetJointTransformScale(joint: DObj, dobjdesc, range_: float, scale: Vector3) -> void:
	var scale_translate: float

	joint.rotate.x = ((joint.rotate.x - dobjdesc.rotate.x) * range_) + dobjdesc.rotate.x
	joint.rotate.y = ((joint.rotate.y - dobjdesc.rotate.y) * range_) + dobjdesc.rotate.y
	joint.rotate.z = ((joint.rotate.z - dobjdesc.rotate.z) * range_) + dobjdesc.rotate.z

	# y tho

	scale_translate = dobjdesc.translate.x * scale.x
	joint.translate.x = ((joint.translate.x - scale_translate) * range_) + scale_translate

	scale_translate = dobjdesc.translate.y * scale.y
	joint.translate.y = ((joint.translate.y - scale_translate) * range_) + scale_translate

	scale_translate = dobjdesc.translate.z * scale.z
	joint.translate.z = ((joint.translate.z - scale_translate) * range_) + scale_translate

## Return to this when the struct at 0x2D8 of FTAttributes is mapped (no address comment in the decomp)
static func ftCommonGuardUpdateJoints(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var yrotn_joint: DObj = fp.joints[nFTPartsJointYRotN]
	var joint_num: int
	var i: int
	# Vec3f *scale = &fp->attr->translate_scales[nFTPartsJointYRotN]; (only dereferenced when is_have_translate_scale)

	if fp.is_shield:
		ftCommonGuardUpdateShieldAngle(fp)

		# for (i = nFTPartsJointXRotN, joint_num = 0; i < ARRAY_COUNT(fp->joints); i++, p_joint++)
		i = nFTPartsJointXRotN
		joint_num = 0
		while i < FTPARTS_JOINT_NUM_MAX:
			if fp.joints[i] != null:
				joint_num += 1
			i += 1
		joint_num -= 1

		ObjAnim.gcAddDObjAnimJoint(yrotn_joint, fp.attr.shield_anim_joints[fp.status_vars.common.guard.angle_i][joint_num], fp.status_vars.common.guard.angle_f)
		ObjAnim.gcParseDObjAnimJoint(yrotn_joint)

		if fp.is_have_translate_scale:
			Lbcommon.lbCommonPlayTranslateScaledDObjAnim(yrotn_joint, fp.attr.translate_scales[nFTPartsJointYRotN])
		else:
			ObjAnim.gcPlayDObjAnimJoint(yrotn_joint)

		if fp.is_have_translate_scale:
			ftCommonGuardGetJointTransformScale(yrotn_joint, fp.attr.dobj_lookup[joint_num], fp.status_vars.common.guard.shield_rotate_range, fp.attr.translate_scales[nFTPartsJointYRotN])
		else:
			ftCommonGuardGetJointTransform(yrotn_joint, fp.attr.dobj_lookup[joint_num], fp.status_vars.common.guard.shield_rotate_range)

		yrotn_joint.anim_wait = AOBJ_ANIM_NULL

		ftCommonGuardUpdateShieldCollision(fp)
		Ftparam.ftParamsUpdateFighterPartsTransformAll(fp.joints[nFTPartsJointYRotN])

## Need to revisit this when once I have a better understanding of these structs... (no address comment in the decomp)
static func ftCommonGuardInitJoints(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr
	# DObj **p_joint = &fp->joints[nFTPartsJointCommonStart];  -> fp.joints[i]
	# DObjDesc *dobjdesc = &attr->dobj_lookup[1];               -> attr.dobj_lookup[dobjdesc]
	var dobjdesc: int = 1
	var joint: DObj
	# Vec3f *scale;                                              -> attr.translate_scales[i]
	var i: int

	if fp.status_id != nFTCommonStatusGuardSetOff:
		ftCommonGuardUpdateShieldAngle(fp)

	# fp->anim_desc.flags.is_anim_joint = TRUE;
	fp.anim_desc |= FTANIM_FLAG_ANIMJOINT

	Lbcommon.lbCommonAddDObjAnimJointAll(
		fp.joints[nFTPartsJointXRotN],
		attr.shield_anim_joints[fp.status_vars.common.guard.angle_i],
		fp.status_vars.common.guard.angle_f
	)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	if fp.is_have_translate_scale:
		# scale = &fp->attr->translate_scales[nFTPartsJointCommonStart]; advanced together with i
		i = nFTPartsJointCommonStart
		while i < FTPARTS_JOINT_NUM_MAX:
			joint = fp.joints[i]

			if joint != null:
				if joint.anim_wait != AOBJ_ANIM_NULL:
					ftCommonGuardGetJointTransformScale(
						joint,
						attr.dobj_lookup[dobjdesc],
						fp.status_vars.common.guard.shield_rotate_range,
						attr.translate_scales[i]
					)
					joint.anim_wait = AOBJ_ANIM_NULL
				dobjdesc += 1
			i += 1
		joint = fp.joints[nFTPartsJointYRotN]

		if joint.anim_wait != AOBJ_ANIM_NULL:
			ftCommonGuardGetJointTransformScale(
				joint,
				attr.dobj_lookup[dobjdesc],
				fp.status_vars.common.guard.shield_rotate_range,
				fp.attr.translate_scales[nFTPartsJointYRotN]
			)
			joint.anim_wait = AOBJ_ANIM_NULL
	else:
		i = nFTPartsJointCommonStart
		while i < FTPARTS_JOINT_NUM_MAX:
			joint = fp.joints[i]

			if joint != null:
				if joint.anim_wait != AOBJ_ANIM_NULL:
					ftCommonGuardGetJointTransform(
						joint,
						attr.dobj_lookup[dobjdesc],
						fp.status_vars.common.guard.shield_rotate_range
					)
					joint.anim_wait = AOBJ_ANIM_NULL
				dobjdesc += 1
			i += 1
		joint = fp.joints[nFTPartsJointYRotN]

		if joint.anim_wait != AOBJ_ANIM_NULL:
			ftCommonGuardGetJointTransform(
				joint,
				attr.dobj_lookup[dobjdesc],
				fp.status_vars.common.guard.shield_rotate_range
			)
			joint.anim_wait = AOBJ_ANIM_NULL
	ftCommonGuardUpdateShieldCollision(fp)
	Ftparam.ftParamsUpdateFighterPartsTransform(fp.joints[nFTPartsJointXRotN])

## 0x80148A88
static func ftCommonGuardOnProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftCommonGuardCheckScheduleRelease(fp)
	ftCommonGuardUpdateShieldVars(fighter_gobj)

	if fp.shield_health == 0:
		Ftcommonshieldbreakfly.ftCommonShieldBreakFlyCommonSetStatus(fighter_gobj)
	else:
		if fighter_gobj.anim_frame <= 0.0:
			if fp.status_vars.common.guard.is_release != FALSE:
				if fp.fkind == nFTKindYoshi:
					ftCommonGuardOffSetHitStatusYoshi(fighter_gobj)
				Ftcommonguard2.ftCommonGuardOffSetStatus(fighter_gobj)
			else:
				if fp.fkind == nFTKindYoshi:
					fp.status_vars.common.guard.effect_gobj = Efmanager.efManagerYoshiShieldMakeEffect(fighter_gobj)

					Ftparam.ftParamHideModelPartAll(fighter_gobj)
					ftCommonGuardSetHitStatusYoshi(fighter_gobj)

					fp.is_shield = TRUE

					ftCommonGuardUpdateJoints(fighter_gobj)
				ftCommonGuardSetStatus(fighter_gobj)
		else:
			ftCommonGuardUpdateJoints(fighter_gobj)

## 0x80148B84
static func ftCommonGuardCommonProcInterrupt(fighter_gobj) -> void:
	if not ftCommonGuardCheckInterrupt(fighter_gobj):
		Ftcommondokan.ftCommonDokanStartCheckInterruptCommon(fighter_gobj)

## 0x80148BFC
static func ftCommonGuardOnSetStatus(fighter_gobj, slide_tics: int) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusGuardOn, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	if fp.shield_health != 0:
		if fp.fkind == nFTKindYoshi:
			ftCommonGuardOnSetHitStatusYoshi(fighter_gobj)
		else:
			fp.status_vars.common.guard.effect_gobj = Efmanager.efManagerShieldMakeEffect(fighter_gobj)
			fp.is_shield = TRUE
	ftCommonGuardUpdateJoints(fighter_gobj)

	fp.status_vars.common.guard.release_lag = FTCOMMON_GUARD_RELEASE_LAG
	fp.status_vars.common.guard.shield_decay_wait = FTCOMMON_GUARD_DECAY_INT
	fp.status_vars.common.guard.is_release = FALSE
	fp.status_vars.common.guard.slide_tics = slide_tics
	fp.status_vars.common.guard.is_setoff = FALSE

	Snd.func_800269C0_275C0(nSYAudioFGMGuardOn)

## 0x80148CBC
static func ftCommonGuardOnCheckInterruptSuccess(fighter_gobj, slide_tics: int) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.input.pl.button_hold & fp.input.button_mask_z) and (fp.shield_health != 0):
		ftCommonGuardOnSetStatus(fighter_gobj, slide_tics)

		return TRUE
	else:
		return FALSE

## 0x80148D0C
static func ftCommonGuardOnCheckInterruptCommon(fighter_gobj) -> int:
	return ftCommonGuardOnCheckInterruptSuccess(fighter_gobj, 0)

## 0x80148D2C
static func ftCommonGuardOnCheckInterruptDashRun(fighter_gobj, slide_tics: int) -> int:
	return ftCommonGuardOnCheckInterruptSuccess(fighter_gobj, slide_tics)

## 0x80148D4C
static func ftCommonGuardProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftCommonGuardCheckScheduleRelease(fp)
	ftCommonGuardUpdateShieldVars(fighter_gobj)

	if fp.shield_health == 0:
		Ftcommonshieldbreakfly.ftCommonShieldBreakFlyCommonSetStatus(fighter_gobj)
	elif (fp.status_vars.common.guard.is_release != FALSE) or not fp.is_shield:
		Ftcommonguard2.ftCommonGuardOffSetStatus(fighter_gobj)
	else:
		ftCommonGuardInitJoints(fighter_gobj)

## 0x80148DDC
static func ftCommonGuardSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusGuard, 0.0, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_EFFECT))
	ftCommonGuardInitJoints(fighter_gobj)

	fp.is_shield = TRUE
