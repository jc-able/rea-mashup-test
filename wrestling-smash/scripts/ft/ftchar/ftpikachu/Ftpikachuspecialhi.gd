## Port of src/ft/ftchar/ftpikachu/ftpikachuspecialhi.c (Pikachu up special: Quick Attack).
class_name Ftpikachuspecialhi
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

const FTPIKACHU_SPECIALHI_STATUS_FLAGS = (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801527B0
static func ftPikachuSpecialHiStartProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.pikachu.specialhi.anim_frames -= 1

	if fp.status_vars.pikachu.specialhi.anim_frames == 0:
		ftPikachuSpecialHiSetStatus(fighter_gobj)

## 0x801527E4
static func ftPikachuSpecialAirHiStartProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.pikachu.specialhi.anim_frames -= 1

	if fp.status_vars.pikachu.specialhi.anim_frames == 0:
		ftPikachuSpecialAirHiSetStatus(fighter_gobj)

## 0x80152818
static func ftPikachuSpecialAirHiStartProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	Ftphysics.ftPhysicsApplyGravityClampTVel(fp, 0.8, attr.tvel_base)

	if Ftphysics.ftPhysicsCheckClampAirVelXDecMax(fp, attr) == FALSE:
		Ftphysics.ftPhysicsApplyAirVelXFriction(fp, attr)

## 0x8015286C
static func ftPikachuSpecialHiStartProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftpikachuspecialhi, &"ftPikachuSpecialHiStartSwitchStatusAir"))

## 0x80152890
static func ftPikachuSpecialAirHiStartProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterCliff(fighter_gobj, Callable(Ftpikachuspecialhi, &"ftPikachuSpecialAirHiStartSwitchStatusGround"))

## 0x801528B4
static func ftPikachuSpecialAirHiStartSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialHiStart, fighter_gobj.anim_frame, 0.0, FTPIKACHU_SPECIALHI_STATUS_FLAGS)

## 0x801528F4
static func ftPikachuSpecialHiStartSwitchStatusAir(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterAir(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialAirHiStart, fighter_gobj.anim_frame, 0.0, FTPIKACHU_SPECIALHI_STATUS_FLAGS)

## 0x80152934
static func ftPikachuSpecialHiStartInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag1 = 0

	fp.status_vars.pikachu.specialhi.anim_frames = FTPIKACHU_QUICKATTACK_START_TIME
	fp.status_vars.pikachu.specialhi.is_subsequent_zip = FALSE
	fp.status_vars.pikachu.specialhi.pass_timer = 0

	fp.physics.vel_ground.x = 0.0
	fp.physics.vel_air.y = fp.physics.vel_ground.x
	fp.physics.vel_air.x = fp.physics.vel_air.y

## 0x80152960 - Set hit collision, color animation and anim rate
static func ftPikachuSpecialHiInitMiscVars(fighter_gobj) -> void:
	Ftparam.ftParamSetHitStatusAll(fighter_gobj, nGMHitStatusIntangible) # Set hit status
	Ftparam.ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterPikachuSpecialHiStart, 0) # Apply color animation
	ObjAnim.gcSetAnimSpeed(fighter_gobj, 0.0) # Set animation speed (0.0F = freeze)

## 0x801529A0
static func ftPikachuSpecialHiStartSetStatus(fighter_gobj) -> void:
	ftPikachuSpecialHiStartInitStatusVars(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialHiStart, 0.0, 0.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftPikachuSpecialHiInitMiscVars(fighter_gobj)

## 0x801529EC
static func ftPikachuSpecialAirHiStartSetStatus(fighter_gobj) -> void:
	ftPikachuSpecialHiStartInitStatusVars(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialAirHiStart, 0.0, 0.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftPikachuSpecialHiInitMiscVars(fighter_gobj)

## 0x80152A38
static func ftPikachuSpecialHiProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.pikachu.specialhi.anim_frames -= 1

	if fp.status_vars.pikachu.specialhi.anim_frames <= 0: # NOW you're checking if less than too?
		ftPikachuSpecialHiEndSetStatus(fighter_gobj)

## 0x80152A6C
static func ftPikachuSpecialAirHiProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.pikachu.specialhi.anim_frames -= 1

	if fp.status_vars.pikachu.specialhi.anim_frames <= 0: # NOW you're checking if less than too?
		ftPikachuSpecialAirHiEndSetStatus(fighter_gobj)

## 0x80152AA0
static func ftPikachuSpecialHiUpdateModelPitchScale(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.joints[FTPIKACHU_QUICKATTACK_BASE_JOINT].rotate.x = (syUtilsArcTan2(fp.physics.vel_air.x, fp.physics.vel_air.y) * fp.lr) - F_CST_DTOR32(90.0)

	fp.joints[FTPIKACHU_QUICKATTACK_BASE_JOINT].scale.x = FTPIKACHU_QUICKATTACK_SCALE_X
	fp.joints[FTPIKACHU_QUICKATTACK_BASE_JOINT].scale.y = FTPIKACHU_QUICKATTACK_SCALE_Y
	fp.joints[FTPIKACHU_QUICKATTACK_BASE_JOINT].scale.z = FTPIKACHU_QUICKATTACK_SCALE_Z

	Ftparam.ftParamsUpdateFighterPartsTransformAll(fp.joints[FTPIKACHU_QUICKATTACK_BASE_JOINT])

## 0x80152B24
static func ftPikachuSpecialHiProcPhysics(fighter_gobj) -> void:
	Ftphysics.ftPhysicsApplyGroundVelTransferAir(fighter_gobj)
	ftPikachuSpecialHiUpdateModelPitchScale(fighter_gobj)

## 0x80152B4C
static func ftPikachuSpecialAirHiProcPhysics(fighter_gobj) -> void:
	ftPikachuSpecialHiUpdateModelPitchScale(fighter_gobj)

## 0x80152B6C
static func ftPikachuSpecialHiProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if Mpcommon.mpCommonCheckFighterOnFloor(fighter_gobj) == FALSE:
		if fp.coll_data.mask_curr & (MAP_FLAG_RWALL | MAP_FLAG_LWALL):
			Mpcommon.mpCommonSetFighterAir(fp)
			ftPikachuSpecialAirHiEndSetStatus(fighter_gobj)
		else:
			ftPikachuSpecialHiSwitchStatusAir(fighter_gobj)

	elif fp.coll_data.mask_curr & (MAP_FLAG_RWALL | MAP_FLAG_LWALL): # REGION_US: "else if" (JP checks unconditionally)
		ftPikachuSpecialHiEndSetStatus(fighter_gobj)

## 0x80152BF4
static func ftPikachuSpecialHiProcPass(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if not (fp.coll_data.floor_flags & MAP_VERTEX_COLL_PASS) or (fp.status_vars.pikachu.specialhi.pass_timer >= FTPIKACHU_QUICKATTACK_PASS_BUFFER_MAX):
		return TRUE
	else:
		return FALSE

## 0x80152C2C
static func ftPikachuSpecialAirHiProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.pikachu.specialhi.pass_timer += 1

	if Mpcommon.mpCommonCheckFighterPassCliff(fighter_gobj, Callable(Ftpikachuspecialhi, &"ftPikachuSpecialHiProcPass")) != FALSE:
		if fp.coll_data.mask_stat & MAP_FLAG_CLIFF_MASK:
			Ftcommoncliffcatchwait.ftCommonCliffCatchSetStatus(fighter_gobj)

		elif syVectorAngleDiff3D(fp.coll_data.floor_angle, fp.physics.vel_air) > FTPIKACHU_QUICKATTACK_HALT_ANGLE:
			Mpcommon.mpCommonSetFighterGround(fp)
			ftPikachuSpecialHiEndSetStatus(fighter_gobj)

		else:
			ftPikachuSpecialAirHiSwitchStatusGround(fighter_gobj)
	else:
		if (fp.coll_data.mask_curr & MAP_FLAG_CEIL) and (syVectorAngleDiff3D(fp.coll_data.ceil_angle, fp.physics.vel_air) > FTPIKACHU_QUICKATTACK_HALT_ANGLE):
			ftPikachuSpecialAirHiEndSetStatus(fighter_gobj)

		if (fp.coll_data.mask_curr & MAP_FLAG_LWALL) and (syVectorAngleDiff3D(fp.coll_data.lwall_angle, fp.physics.vel_air) > FTPIKACHU_QUICKATTACK_HALT_ANGLE):
			ftPikachuSpecialAirHiEndSetStatus(fighter_gobj)

		if (fp.coll_data.mask_curr & MAP_FLAG_RWALL) and (syVectorAngleDiff3D(fp.coll_data.rwall_angle, fp.physics.vel_air) > FTPIKACHU_QUICKATTACK_HALT_ANGLE):
			ftPikachuSpecialAirHiEndSetStatus(fighter_gobj)

## 0x80152D98
static func ftPikachuSpecialAirHiSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialHi, fighter_gobj.anim_frame, 0.0, FTPIKACHU_SPECIALHI_STATUS_FLAGS)

## 0x80152DD8
static func ftPikachuSpecialHiSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialAirHi, fighter_gobj.anim_frame, 0.0, FTPIKACHU_SPECIALHI_STATUS_FLAGS)

	fp.jumps_used = fp.attr.jumps_max

## 0x80152E2C
static func ftPikachuSpecialHiInitStatusVarsZip(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.pikachu.specialhi.anim_frames = FTPIKACHU_QUICKATTACK_ZIP_TIME
	fp.jumps_used = fp.attr.jumps_max

## 0x80152E48
static func ftPikachuSpecialHiSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var sqrt_stick_range: float
	var temp_stick_x: float
	var stick_range: Vector3
	var temp_stick_y: float

	temp_stick_x = fp.input.pl.stick_range.x
	temp_stick_y = fp.input.pl.stick_range.y

	sqrt_stick_range = sqrtf(SQUARE(temp_stick_x) + SQUARE(temp_stick_y))

	if sqrt_stick_range > F_CONTROLLER_RANGE_MAX:
		sqrt_stick_range = F_CONTROLLER_RANGE_MAX

	if not (sqrt_stick_range < FTPIKACHU_QUICKATTACK_STICK_RANGE_MIN) and not (fp.coll_data.floor_flags & MAP_VERTEX_COLL_PASS):
		stick_range.x = fp.input.pl.stick_range.x
		stick_range.y = fp.input.pl.stick_range.y
		stick_range.z = 0.0

		if not (syVectorAngleDiff3D(fp.coll_data.floor_angle, stick_range) < F_CST_DTOR32(90.0)): # else goto block_end (HALF_PI32)
			fp.status_vars.pikachu.specialhi.stick_range.x = int(stick_range.x)
			fp.status_vars.pikachu.specialhi.stick_range.y = int(stick_range.y)

			Ftparam.ftParamSetStickLR(fp)
			ftPikachuSpecialHiInitStatusVarsZip(fighter_gobj)

			fp.physics.vel_ground.x = (FTPIKACHU_QUICKATTACK_VEL_BASE * sqrt_stick_range) + FTPIKACHU_QUICKATTACK_VEL_ADD

			if fp.status_vars.pikachu.specialhi.is_subsequent_zip != FALSE:
				fp.physics.vel_ground.x *= FTPIKACHU_QUICKATTACK_VEL_MUL

			Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialHi, 0.0, 0.0, FTSTATUS_PRESERVE_NONE)
			Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

			return
	# block_end:
	Mpcommon.mpCommonSetFighterAir(fp)

	ftPikachuSpecialAirHiSetStatus(fighter_gobj)

## 0x80152FEC
static func ftPikachuSpecialAirHiSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var angle: float
	var sqrt_stick_range: float = sqrtf(SQUARE(float(fp.input.pl.stick_range.x)) + SQUARE(float(fp.input.pl.stick_range.y)))

	if sqrt_stick_range > F_CONTROLLER_RANGE_MAX:
		sqrt_stick_range = F_CONTROLLER_RANGE_MAX

	Ftparam.ftParamSetStickLR(fp)

	if sqrt_stick_range > FTPIKACHU_QUICKATTACK_STICK_RANGE_MIN:
		angle = syUtilsArcTan2(fp.input.pl.stick_range.y, fp.input.pl.stick_range.x * fp.lr)

		fp.status_vars.pikachu.specialhi.stick_range.x = fp.input.pl.stick_range.x
		fp.status_vars.pikachu.specialhi.stick_range.y = fp.input.pl.stick_range.y
	else:
		angle = F_CST_DTOR32(90.0)
		sqrt_stick_range = F_CONTROLLER_RANGE_MAX

		fp.status_vars.pikachu.specialhi.stick_range.x = 0
		fp.status_vars.pikachu.specialhi.stick_range.y = I_CONTROLLER_RANGE_MAX

	ftPikachuSpecialHiInitStatusVarsZip(fighter_gobj)

	fp.physics.vel_air.x = __cosf(angle) * ((FTPIKACHU_QUICKATTACK_VEL_BASE * sqrt_stick_range) + FTPIKACHU_QUICKATTACK_VEL_ADD) * fp.lr
	fp.physics.vel_air.y = __sinf(angle) * ((FTPIKACHU_QUICKATTACK_VEL_BASE * sqrt_stick_range) + FTPIKACHU_QUICKATTACK_VEL_ADD)

	if fp.status_vars.pikachu.specialhi.is_subsequent_zip != FALSE:
		fp.physics.vel_air.x *= FTPIKACHU_QUICKATTACK_VEL_MUL
		fp.physics.vel_air.y *= FTPIKACHU_QUICKATTACK_VEL_MUL

	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialAirHi, 0.0, 0.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x801531AC
static func ftPikachuSpecialHiCheckGotoSubZip(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var current_angle: Vector3
	var previous_angle: Vector3
	var temp_stick_x: float
	var temp_stick_y: float

	temp_stick_x = float(fp.input.pl.stick_range.x)
	temp_stick_y = float(fp.input.pl.stick_range.y)

	if sqrtf((temp_stick_x * temp_stick_x) + (temp_stick_y * temp_stick_y)) < FTPIKACHU_QUICKATTACK_STICK_RANGE_MIN:
		return FALSE

	elif fp.status_vars.pikachu.specialhi.is_subsequent_zip == FALSE:
		current_angle.x = fp.input.pl.stick_range.x
		current_angle.y = fp.input.pl.stick_range.y
		current_angle.z = 0.0

		previous_angle.x = fp.status_vars.pikachu.specialhi.stick_range.x
		previous_angle.y = fp.status_vars.pikachu.specialhi.stick_range.y
		previous_angle.z = 0.0

		if syVectorAngleDiff3D(previous_angle, current_angle) > FTPIKACHU_QUICKATTACK_ANGLE_DIFF_MIN:
			return TRUE
		else:
			return FALSE
	else:
		return FALSE

## 0x801532B8
static func ftPikachuSpecialHiEndProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 == 1:
		if ftPikachuSpecialHiCheckGotoSubZip(fighter_gobj) != FALSE:
			fp.motion_vars.flags.flag1 = 0

			fp.status_vars.pikachu.specialhi.is_subsequent_zip = TRUE

			ftPikachuSpecialHiSetStatus(fighter_gobj)
		else:
			fp.motion_vars.flags.flag1 = 2

	elif fighter_gobj.anim_frame <= 0.0:
		Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)

## 0x80153340
static func ftPikachuSpecialAirHiEndProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 == 1:
		if ftPikachuSpecialHiCheckGotoSubZip(fighter_gobj) != FALSE:
			fp.motion_vars.flags.flag1 = 0
			fp.status_vars.pikachu.specialhi.is_subsequent_zip = TRUE

			ftPikachuSpecialAirHiSetStatus(fighter_gobj)
		else:
			fp.motion_vars.flags.flag1 = 2

	elif fighter_gobj.anim_frame <= 0.0:
		Ftcommonfallspecial.ftCommonFallSpecialSetStatus(fighter_gobj, FTPIKACHU_QUICKATTACK_FALLSPECIAL_DRIFT, FALSE, TRUE, TRUE, FTPIKACHU_QUICKATTACK_LANDING_LAG, FALSE)

## 0x801533E4
static func ftPikachuSpecialHiEndProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 != 0:
		Ftphysics.ftPhysicsApplyGroundVelFriction(fighter_gobj)

## 0x80153414
static func ftPikachuSpecialAirHiEndProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 != 0:
		var attr

		Ftphysics.ftPhysicsApplyGravityDefault(fp, fp.attr)

		attr = fp.attr

		Ftphysics.ftPhysicsClampAirVelXStickRange(fp, FTPHYSICS_AIRDRIFT_CLAMP_RANGE_MIN, attr.air_accel * FTPIKACHU_QUICKATTACK_AIR_ACCEL_MUL, attr.air_speed_max_x * FTPIKACHU_QUICKATTACK_AIR_SPEED_MUL)

		Ftphysics.ftPhysicsApplyAirVelXFriction(fp, fp.attr)
	else:
		fp.physics.vel_air.y -= (fp.physics.vel_air.y / FTPIKACHU_QUICKATTACK_VEL_Y_DIV)

		Ftphysics.ftPhysicsApplyAirVelXFriction(fp, fp.attr)

## 0x801534BC
static func ftPikachuSpecialHiEndProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftpikachuspecialhi, &"ftPikachuSpecialHiEndSwitchStatusAir"))

## 0x801534E0
static func ftPikachuSpecialAirHiEndProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if Mpcommon.mpCommonCheckFighterCliff(fighter_gobj) != FALSE:
		if fp.coll_data.mask_stat & MAP_FLAG_CLIFF_MASK:
			Ftcommoncliffcatchwait.ftCommonCliffCatchSetStatus(fighter_gobj)
		else:
			Ftcommonlanding.ftCommonLandingFallSpecialSetStatus(fighter_gobj, FALSE, FTPIKACHU_QUICKATTACK_LANDING_LAG)

## 0x80153544
static func ftPikachuSpecialAirHiEndSwitchStatusGround(fighter_gobj) -> void: # Unused
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialHiEnd, fighter_gobj.anim_frame, 1.0, FTPIKACHU_SPECIALHI_STATUS_FLAGS)

## 0x80153584
static func ftPikachuSpecialHiEndSwitchStatusAir(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterAir(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialAirHiEnd, fighter_gobj.anim_frame, 1.0, FTPIKACHU_SPECIALHI_STATUS_FLAGS)

## 0x801535C4
static func ftPikachuSpecialHiEndBackupVel(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.pikachu.specialhi.vel_x_bak = fp.physics.vel_air.x
	fp.status_vars.pikachu.specialhi.vel_y_bak = fp.physics.vel_air.y
	fp.status_vars.pikachu.specialhi.vel_ground_bak = fp.physics.vel_ground.x

	fp.physics.vel_air.y = 0.0
	fp.physics.vel_air.x = fp.physics.vel_air.y
	fp.physics.vel_ground.x = 0.0

## 0x801535F4
static func ftPikachuSpecialHiEndSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftPikachuSpecialHiEndBackupVel(fighter_gobj)

	fp.physics.vel_ground.x = fp.status_vars.pikachu.specialhi.vel_ground_bak * FTPIKACHU_QUICKATTACK_VEL_BAK_MUL

	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialHiEnd, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80153654
static func ftPikachuSpecialAirHiEndSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftPikachuSpecialHiEndBackupVel(fighter_gobj)

	fp.physics.vel_air.x = fp.status_vars.pikachu.specialhi.vel_x_bak * FTPIKACHU_QUICKATTACK_VEL_BAK_MUL
	fp.physics.vel_air.y = fp.status_vars.pikachu.specialhi.vel_y_bak * FTPIKACHU_QUICKATTACK_VEL_BAK_MUL

	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialAirHiEnd, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
