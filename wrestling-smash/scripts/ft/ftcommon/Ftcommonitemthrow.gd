## 1:1 port of src/ft/ftcommon/ftcommonitemthrow.c (ssb-decomp-re): LightThrow* / HeavyThrow* item
## throw statuses (direction decision, release velocity/angle/damage, turn-around yaw).
class_name Ftcommonitemthrow
extends Port

## F_PCT_TO_DEC(x) ((float)((x)*0.01F)) (include/macros.h)
static func _F_PCT_TO_DEC(x) -> float:
	return x * 0.01

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801462A0
static func ftCommonItemThrowUpdateModelYaw(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag3 != 0:
		# s32 = s32 = u32
		fp.status_vars.common.itemthrow.turn_tics = fp.motion_vars.flags.flag3
		fp.status_vars.common.itemthrow.turn_rotate_step = fp.status_vars.common.itemthrow.turn_tics

		# u32 / 2
		fp.status_vars.common.itemthrow.turn_invert_lr_wait = (fp.motion_vars.flags.flag3 & 0xFFFFFFFF) / 2

		fp.motion_vars.flags.flag3 = 0

	if fp.status_vars.common.itemthrow.turn_tics != 0:
		fp.status_vars.common.itemthrow.turn_tics -= 1

		if fp.status_vars.common.itemthrow.turn_invert_lr_wait != 0:
			fp.status_vars.common.itemthrow.turn_invert_lr_wait -= 1

			if fp.status_vars.common.itemthrow.turn_invert_lr_wait == 0:
				fp.lr = -fp.lr
		fp.joints[nFTPartsJointTopN].rotate.y -= F_CLC_DTOR32(180.0 / fp.status_vars.common.itemthrow.turn_rotate_step)

		Ftparam.ftParamsUpdateFighterPartsTransformAll(fp.joints[nFTPartsJointTopN])

## 0x8014634C
static func ftCommonItemThrowProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var vel_base: float
	var item_throw_desc: Dictionary
	var damage_mul: float
	var vel: Vector3
	var status_id: int
	var angle: int

	ftCommonItemThrowUpdateModelYaw(fighter_gobj)

	if fp.motion_vars.flags.flag2 != 0:
		fp.status_vars.common.itemthrow.throw_vel = _F_PCT_TO_DEC(fp.motion_vars.item_throw.vel)
		fp.status_vars.common.itemthrow.throw_angle = fp.motion_vars.item_throw.angle

		fp.motion_vars.flags.flag2 = 0
	if fp.motion_vars.flags.flag1 != 0:
		fp.status_vars.common.itemthrow.throw_damage = _F_PCT_TO_DEC(fp.motion_vars.item_throw.damage)

		fp.motion_vars.flags.flag1 = 0
	if (fp.item_gobj != null) and (fp.motion_vars.item_throw.is_throw_item != FALSE):
		if (
			((fp.fkind == nFTKindDonkey) or (fp.fkind == nFTKindNDonkey) or (fp.fkind == nFTKindGDonkey)) and
			((fp.status_id >= nFTDonkeyStatusHeavyThrowStart) and (fp.status_id <= nFTDonkeyStatusHeavyThrowEnd))
		):
			status_id = fp.status_id - nFTCommonStatusHeavyThrow4Start
		else:
			status_id = fp.status_id

		# dFTCommonDataItemThrowDescs[status_id - nFTCommonStatusLightThrowStart] (FTItemThrow bitfields, src/ft/ftcommondata.c)
		item_throw_desc = Ftcommondata.dFTCommonDataItemThrowDescs[status_id - nFTCommonStatusLightThrowStart]

		vel_base = _F_PCT_TO_DEC(
			item_throw_desc.vel_scale *
			fp.status_vars.common.itemthrow.throw_vel *
			fp.attr.itemthrow_vel_scale
		)

		if fp.status_vars.common.itemthrow.throw_angle == 361:
			angle = item_throw_desc.angle
		else:
			angle = fp.status_vars.common.itemthrow.throw_angle

		damage_mul = _F_PCT_TO_DEC(
			_F_PCT_TO_DEC(item_throw_desc.damage_scale) *
			fp.status_vars.common.itemthrow.throw_damage *
			fp.attr.itemthrow_damage_scale
		)

		vel.x = __cosf(F_CLC_DTOR32(angle)) * vel_base * fp.lr
		vel.y = __sinf(F_CLC_DTOR32(angle)) * vel_base
		vel.z = 0.0

		if status_id == nFTCommonStatusLightThrowDrop:
			Itmain.itMainSetFighterDrop(fp.item_gobj, vel, damage_mul)
		else:
			Itmain.itMainSetFighterThrow(fp.item_gobj, vel, damage_mul, item_throw_desc.is_smash_throw)

		fp.motion_vars.flags.flag0 = 0
	if fighter_gobj.anim_frame <= 0.0:
		Mpcommon.mpCommonSetFighterWaitOrFall(fighter_gobj)

## 0x80146618
static func ftCommonItemThrowProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsAir:
		Ftphysics.ftPhysicsApplyAirVelDrift(fighter_gobj)
	else:
		Ftphysics.ftPhysicsApplyGroundVelFriction(fighter_gobj)

## 0x8014665C
static func ftCommonItemThrowInitCommandVars(fp) -> void:
	fp.motion_vars.flags.flag0 = 0
	fp.motion_vars.flags.flag1 = 0
	fp.motion_vars.flags.flag2 = 0
	fp.motion_vars.flags.flag3 = 0

## 0x80146670
static func ftCommonItemThrowInitStatusVars(fp) -> void:
	fp.status_vars.common.itemthrow.turn_tics = 0
	fp.status_vars.common.itemthrow.throw_angle = 361
	fp.status_vars.common.itemthrow.throw_vel = 1.0
	fp.status_vars.common.itemthrow.throw_damage = 1.0

## 0x80146690
static func ftCommonItemThrowSetStatus(fighter_gobj, status_id) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftCommonItemThrowInitCommandVars(fp)

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	ftCommonItemThrowInitStatusVars(fp)
	ftCommonItemThrowUpdateModelYaw(fighter_gobj)

## 0x801466EC
static func ftCommonLightThrowDecideSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int

	if (ABS(fp.input.pl.stick_range.x) >= FTCOMMON_LIGHTTHROW4_STICK_RANGE_X_MIN) and (fp.hold_stick_x < FTCOMMON_LIGHTTHROW4_F_OR_B_BUFFER_TICS_MAX):
		status_id = nFTCommonStatusLightThrowF4 if ((fp.input.pl.stick_range.x * fp.lr) >= 0) else nFTCommonStatusLightThrowB4
	elif (
		(fp.input.pl.stick_range.y >= FTCOMMON_LIGHTTHROW4_STICK_RANGE_Y_MIN) and
		(fp.hold_stick_y < (FTCOMMON_LIGHTTHROW4_HI_OR_LW_BUFFER_TICS_MAX + fp.attr.kneebend_anim_length))
	):
		status_id = nFTCommonStatusLightThrowHi4
	elif (fp.input.pl.stick_range.y <= -FTCOMMON_LIGHTTHROW4_STICK_RANGE_Y_MIN) and (fp.hold_stick_y < FTCOMMON_LIGHTTHROW4_HI_OR_LW_BUFFER_TICS_MAX):
		status_id = nFTCommonStatusLightThrowLw4
	elif (
		(ABS(fp.input.pl.stick_range.x) >= FTCOMMON_LIGHTTHROW_STICK_RANGE_XY_MIN) and
		((-Ftparam.ftParamGetStickAngleRads(fp) if (Ftparam.ftParamGetStickAngleRads(fp) < 0.0) else Ftparam.ftParamGetStickAngleRads(fp)) <= FTCOMMON_LIGHTTHROW_HI_OR_LW_ANGLE)
	):
		status_id = nFTCommonStatusLightThrowF if ((fp.input.pl.stick_range.x * fp.lr) >= 0) else nFTCommonStatusLightThrowB
	elif (fp.input.pl.stick_range.y >= FTCOMMON_LIGHTTHROW_STICK_RANGE_XY_MIN) and (Ftparam.ftParamGetStickAngleRads(fp) > FTCOMMON_LIGHTTHROW_HI_OR_LW_ANGLE):
		status_id = nFTCommonStatusLightThrowHi
	elif (fp.input.pl.stick_range.y <= -FTCOMMON_LIGHTTHROW_STICK_RANGE_XY_MIN) and (Ftparam.ftParamGetStickAngleRads(fp) < -FTCOMMON_LIGHTTHROW_HI_OR_LW_ANGLE):
		status_id = nFTCommonStatusLightThrowLw
	else:
		status_id = nFTCommonStatusLightThrowF if (itGetStruct(fp.item_gobj).type == nITTypeThrow) else nFTCommonStatusLightThrowDrop # No NULL check

	ftCommonItemThrowSetStatus(fighter_gobj, status_id)

## 0x80146930
static func ftCommonHeavyThrowDecideSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int

	if (ABS(fp.input.pl.stick_range.x) >= FTCOMMON_HEAVYTHROW4_STICK_RANGE_X_MIN) and (fp.hold_stick_x < FTCOMMON_HEAVYTHROW4_F_OR_B_BUFFER_TICS_MAX):
		status_id = nFTCommonStatusHeavyThrowF4 if ((fp.input.pl.stick_range.x * fp.lr) >= 0) else nFTCommonStatusHeavyThrowB4
	elif (
		(ABS(fp.input.pl.stick_range.x) >= FTCOMMON_HEAVYTHROW_STICK_RANGE_XY_MIN) and
		((-Ftparam.ftParamGetStickAngleRads(fp) if (Ftparam.ftParamGetStickAngleRads(fp) < 0.0) else Ftparam.ftParamGetStickAngleRads(fp)) <= FTCOMMON_HEAVYTHROW_HI_OR_LW_ANGLE)
	):
		status_id = nFTCommonStatusHeavyThrowF if ((fp.input.pl.stick_range.x * fp.lr) >= 0) else nFTCommonStatusHeavyThrowB
	else:
		status_id = nFTCommonStatusHeavyThrowStart

	if (fp.fkind == nFTKindDonkey) or (fp.fkind == nFTKindNDonkey) or (fp.fkind == nFTKindGDonkey):
		status_id += nFTCommonStatusHeavyThrow4Start
	ftCommonItemThrowSetStatus(fighter_gobj, status_id)

	fp.proc_damage = Callable(Ftcommonget, &"ftCommonHeavyGetProcDamage")

## 0x80146A8C
static func ftCommonLightThrowCheckItemTypeThrow(fp) -> int:
	if fp.item_gobj != null:
		if fp.input.pl.button_tap & fp.input.button_mask_a:
			if (fp.input.pl.button_hold & fp.input.button_mask_z) or (itGetStruct(fp.item_gobj).type == nITTypeThrow):
				return TRUE
	return FALSE

## 0x80146AE8
static func ftCommonLightThrowCheckInterruptGuardOn(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.item_gobj != null) and (fp.input.pl.button_tap & fp.input.button_mask_a):
		if fp.status_vars.common.guard.slide_tics != 0:
			ftCommonItemThrowSetStatus(fighter_gobj, nFTCommonStatusLightThrowDash)
		else:
			ftCommonLightThrowDecideSetStatus(fighter_gobj)

		return TRUE
	if fp.status_vars.common.guard.slide_tics != 0:
		fp.status_vars.common.guard.slide_tics -= 1
	return FALSE

## 0x80146B64
static func ftCommonLightThrowCheckInterruptEscape(fighter_gobj) -> int: # Interrupt item throw from roll
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int

	if B(ftCommonLightThrowCheckItemTypeThrow(fp)) and (fp.status_vars.common.escape.itemthrow_buffer_tics != 0):
		if fp.status_id == nFTCommonStatusEscapeF:
			status_id = nFTCommonStatusLightThrowF4
		else:
			status_id = nFTCommonStatusLightThrowB4

		ftCommonItemThrowSetStatus(fighter_gobj, status_id)

		return TRUE
	if fp.status_vars.common.escape.itemthrow_buffer_tics != 0:
		fp.status_vars.common.escape.itemthrow_buffer_tics -= 1
	return FALSE

## 0x80146BE0
static func ftCommonHeavyThrowCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.item_gobj != null) and (fp.input.pl.button_tap & (fp.input.button_mask_a | fp.input.button_mask_b)):
		ftCommonHeavyThrowDecideSetStatus(fighter_gobj)

		return TRUE
	else:
		return FALSE
