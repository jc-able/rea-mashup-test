## 1:1 port of src/ft/ftchar/ftkirby/ftkirbyspeciallw.c (ssb-decomp-re): Kirby's Stone.
class_name Ftkirbyspeciallw
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80161360
static func ftKirbySpecialLwUnused(fighter_gobj = null) -> void:
	return

## 0x80161368
static func ftKirbySpecialLwUpdateColAnim(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.damage_resist < FTKIRBY_STONE_HEALTH_MID: # Apply color overlay based on remaining Stone HP
		if fp.damage_resist < FTKIRBY_STONE_HEALTH_LOW:
			if fp.status_vars.kirby.speciallw.colanim_id != nGMColAnimFighterKirbySpeciaLwLow:
				Ftparam.ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterKirbySpeciaLwLow, 0)
				fp.status_vars.kirby.speciallw.colanim_id = nGMColAnimFighterKirbySpeciaLwLow

		elif fp.status_vars.kirby.speciallw.colanim_id != nGMColAnimFighterKirbySpeciaLwMid:
			Ftparam.ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterKirbySpeciaLwMid, 0)
			fp.status_vars.kirby.speciallw.colanim_id = nGMColAnimFighterKirbySpeciaLwMid

	elif fp.status_vars.kirby.speciallw.colanim_id != nGMColAnimFighterKirbySpeciaLwHigh:
		Ftparam.ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterKirbySpeciaLwHigh, 0)
		fp.status_vars.kirby.speciallw.colanim_id = nGMColAnimFighterKirbySpeciaLwHigh

## 0x8016141C
static func ftKirbySpecialLwSetDamageResist(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.is_damage_resist = TRUE
	fp.damage_resist = FTKIRBY_STONE_HEALTH_MAX

	fp.status_vars.kirby.speciallw.duration = FTKIRBY_STONE_DURATION_MAX
	fp.status_vars.kirby.speciallw.colanim_id = nGMColAnimFighterKirbySpeciaLwHigh

	Ftparam.ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterKirbySpeciaLwHigh, 0)

## 0x80161468
static func ftKirbySpecialLwSetDropFallVel(fp = null) -> void:
	fp.physics.vel_air.y = FTKIRBY_STONE_FALL_VEL

## 0x80161478
static func ftKirbySpecialLwGetGroundAxisYaw(fp = null) -> float:
	var rot_z: float = -syUtilsArcTan2(fp.coll_data.floor_angle.x, fp.coll_data.floor_angle.y)

	fp.joints[nFTPartsJointTopN].rotate.z = rot_z

	return rot_z

## 0x801614B4
static func ftKirbySpecialLwCheckRelease(fighter_gobj = null, is_allow_release = null) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if is_allow_release == TRUE:
		if fp.input.pl.button_tap & fp.input.button_mask_b:
			return TRUE

	elif (fp.status_vars.kirby.speciallw.duration < (FTKIRBY_STONE_DURATION_MAX - FTKIRBY_STONE_DURATION_MIN)) and (fp.input.pl.button_tap & fp.input.button_mask_b):
		return TRUE

	if fp.status_vars.kirby.speciallw.duration > 0:
		fp.status_vars.kirby.speciallw.duration -= 1

		return FALSE

	else:
		return TRUE

## 0x80161530
static func ftKirbySpecialLwStartProcUpdate(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 != 0:
		Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialLwHold, 0.0, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM))
		ftKirbySpecialLwSetDamageResist(fighter_gobj)

		fp.motion_vars.flags.flag1 = 0

	else:
		Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftkirbyspeciallw, &"ftKirbySpecialLwUnkSetStatus"))

## 0x80161598
static func ftKirbySpecialAirLwStartProcUpdate(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 != 0:
		ftKirbySpecialLwSetDamageResist(fighter_gobj)

		fp.motion_vars.flags.flag1 = 0

	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftkirbyspeciallw, &"ftKirbySpecialAirLwHoldSetStatus"))

## 0x801615E4
static func ftKirbySpecialLwUnkDecideNextStatus(fighter_gobj = null, ga = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if not B(fp.is_damage_resist) and (fp.motion_vars.flags.flag1 != 0):
		if ga == nMPKineticsGround:
			Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialLwHold, 0.0, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM))

		ftKirbySpecialLwSetDamageResist(fighter_gobj)

		fp.motion_vars.flags.flag1 = 0
		fp.motion_vars.flags.flag2 = 1

	if fp.motion_vars.flags.flag2 != 0:
		if ftKirbySpecialLwCheckRelease(fighter_gobj, FALSE) == TRUE:
			if ga == nMPKineticsGround:
				ftKirbySpecialLwEndSetStatus(fighter_gobj)
			else:
				ftKirbySpecialAirLwEndSetStatus(fighter_gobj)

			fp.motion_vars.flags.flag2 = 0

		ftKirbySpecialLwUpdateColAnim(fighter_gobj)

## 0x801616B0
static func ftKirbySpecialLwUnkProcUpdate(fighter_gobj = null) -> void:
	ftKirbySpecialLwUnkDecideNextStatus(fighter_gobj, nMPKineticsGround)

## 0x801616D0
static func ftKirbySpecialAirLwHoldProcUpdate(fighter_gobj = null) -> void:
	ftKirbySpecialLwUnkDecideNextStatus(fighter_gobj, nMPKineticsAir)

## 0x801616F0
static func ftKirbySpecialLwHoldDecideNextStatus(fighter_gobj = null, ga = null) -> void:
	if ftKirbySpecialLwCheckRelease(fighter_gobj, TRUE) == TRUE:
		if ga == nMPKineticsGround:
			ftKirbySpecialLwEndSetStatus(fighter_gobj)
		else:
			ftKirbySpecialAirLwEndSetStatus(fighter_gobj)

	ftKirbySpecialLwUpdateColAnim(fighter_gobj)

## 0x8016174C
static func ftKirbySpecialLwHoldProcUpdate(fighter_gobj = null) -> void:
	ftKirbySpecialLwHoldDecideNextStatus(fighter_gobj, nMPKineticsGround)

## 0x8016176C
static func ftKirbySpecialAirLwFallProcUpdate(fighter_gobj = null) -> void:
	ftKirbySpecialLwHoldDecideNextStatus(fighter_gobj, nMPKineticsAir)

## 0x8016178C
static func ftKirbySpecialLwHoldProcPhysics(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr
	var temp_slide_angle: float
	var ground_vel_x: float
	var slide_angle: float

	temp_slide_angle = ftKirbySpecialLwGetGroundAxisYaw(fp)

	slide_angle = temp_slide_angle

	if FTKIRBY_STONE_SLIDE_ANGLE < temp_slide_angle:
		slide_angle = FTKIRBY_STONE_SLIDE_ANGLE

	elif temp_slide_angle < -FTKIRBY_STONE_SLIDE_ANGLE:
		slide_angle = -FTKIRBY_STONE_SLIDE_ANGLE

	fp.physics.vel_ground.x -= (__sinf(slide_angle) * FTKIRBY_STONE_SLIDE_VEL_MUL * fp.lr)

	ground_vel_x = fp.physics.vel_ground.x

	if ground_vel_x > FTKIRBY_STONE_SLIDE_CLAMP_VEL_X:
		fp.physics.vel_ground.x = FTKIRBY_STONE_SLIDE_CLAMP_VEL_X

	elif ground_vel_x < -FTKIRBY_STONE_SLIDE_CLAMP_VEL_X:
		fp.physics.vel_ground.x = -FTKIRBY_STONE_SLIDE_CLAMP_VEL_X

	Ftphysics.ftPhysicsSetGroundVelFriction(fp, (Mpcollision.dMPCollisionMaterialFrictions[fp.coll_data.floor_flags & MAP_VERTEX_MAT_MASK] * attr.traction * FTKIRBY_STONE_SLIDE_TRACTION_MUL))
	Ftphysics.ftPhysicsSetGroundVelTransferAir(fighter_gobj)

## 0x801618C4
static func ftKirbySpecialLwStartProcMap(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if not B(Mpcommon.mpCommonCheckFighterOnFloor(fighter_gobj)):
		Mpcommon.mpCommonSetFighterAir(fp)
		Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirLwStart, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM))
		ftKirbySpecialLwSetDropFallVel(fp)

## 0x80161920
static func ftKirbySpecialLwUnkProcMap(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if not B(Mpcommon.mpCommonCheckFighterOnFloor(fighter_gobj)):
		Mpcommon.mpCommonSetFighterAir(fp)
		Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirLwHold, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM))

## 0x80161974
static func ftKirbySpecialLwHoldProcMap(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if not B(Mpcommon.mpCommonCheckFighterOnFloor(fighter_gobj)):
		Mpcommon.mpCommonSetFighterAir(fp)
		Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirLwFall, 0.0, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM))

		fp.is_damage_resist = TRUE

		ftKirbySpecialLwSetDropFallVel(fp)

## 0x801619E0
static func ftKirbySpecialAirLwStartProcMap(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if B(Mpcommon.mpCommonCheckFighterLanding(fighter_gobj)):
		Mpcommon.mpCommonSetFighterGround(fp)
		Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialLwStart, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_NONE)

## 0x80161A30
static func ftKirbySpecialAirLwHoldProcMap(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if B(Mpcommon.mpCommonCheckFighterLanding(fighter_gobj)):
		Mpcommon.mpCommonSetFighterGround(fp)
		Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirLwLanding, 0.0, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM))

		fp.is_damage_resist = TRUE

## 0x80161A94
static func ftKirbySpecialLwStartSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialLwStart, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.motion_vars.flags.flag2 = 0
	fp.motion_vars.flags.flag1 = 0

	fp.physics.vel_air.y = 0.0
	fp.physics.vel_air.x = 0.0

## 0x80161AEC
static func ftKirbySpecialLwUnkSetStatus(fighter_gobj = null) -> void: # Unused
	var _fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialLwUnk, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	ftKirbySpecialLwUnused(fighter_gobj)

## 0x80161B2C
static func ftKirbySpecialLwEndSetStatus(fighter_gobj = null) -> void:
	Mpcommon.mpCommonSetFighterAir(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialLwEnd, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80161B70
static func ftKirbySpecialAirLwStartSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var is_damage_resist: int = fp.is_damage_resist

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirLwStart, 0.0, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM))
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.is_damage_resist = is_damage_resist & TRUE

	if fp.is_damage_resist: # if (fp->is_damage_resist = is_damage_resist & TRUE) // wat
		fp.motion_vars.flags.flag2 = 1
	else:
		fp.motion_vars.flags.flag2 = 0
		fp.motion_vars.flags.flag1 = 0

	fp.physics.vel_air.y = 0.0
	fp.physics.vel_air.x = 0.0

## 0x80161C0C
static func ftKirbySpecialAirLwHoldSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirLwHold, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftKirbySpecialLwUnused(fighter_gobj)
	ftKirbySpecialLwSetDropFallVel(fp)

## 0x80161C5C
static func ftKirbySpecialAirLwEndSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirLwEnd, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
