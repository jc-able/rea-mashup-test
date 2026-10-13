## 1:1 port of src/ft/ftchar/ftmario/ftmariospecialhi.c (ssb-decomp-re).
## Mario / Luigi up special (Super Jump Punch).
class_name Ftmariospecialhi
extends Port

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x801560A0
static func ftMarioSpecialHiProcUpdate(fighter_gobj) -> void:
	if fighter_gobj.anim_frame <= 0.0:
		Ftcommonfallspecial.ftCommonFallSpecialSetStatus(fighter_gobj, FTMARIO_SUPERJUMP_AIR_DRIFT, TRUE, FALSE, TRUE, FTMARIO_SUPERJUMP_LANDING_LAG, FALSE)

## 0x801560F4
static func ftMarioSpecialHiProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var rot_z: float
	var stick_rot: float
	var joint_rot: float
	var stick_x: int

	if fp.motion_vars.flags.flag1 == 0:
		stick_x = ABS(fp.input.pl.stick_range.x)

		if stick_x > FTMARIO_SUPERJUMP_TURN_STICK_THRESHOLD:
			stick_x = FTMARIO_SUPERJUMP_TURN_STICK_THRESHOLD if (fp.input.pl.stick_range.x > 0) else -FTMARIO_SUPERJUMP_TURN_STICK_THRESHOLD

			rot_z = ((fp.input.pl.stick_range.x - stick_x) * FTMARIO_SUPERJUMP_AIR_DRIFT)

			rot_z = -F_CLC_DTOR32(rot_z)

			stick_rot = ABSF(rot_z)

			joint_rot = ABSF(fp.joints[nFTPartsJointTransN].rotate.z)

			if joint_rot < stick_rot:
				fp.joints[nFTPartsJointTransN].rotate.z = rot_z

	if fp.motion_vars.flags.flag2 != 0:
		fp.motion_vars.flags.flag2 = 0

		stick_x = ABS(fp.input.pl.stick_range.x)

		if stick_x > FTMARIO_SUPERJUMP_TURN_MODEL_THRESHOLD:
			Ftparam.ftParamSetStickLR(fp)

			fp.joints[nFTPartsJointTopN].rotate.y = fp.lr * F_CST_DTOR32(90.0)

## 0x80156240
static func ftMarioSpecialHiProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if fp.status_vars.mario.specialhi.is_air_bool == FALSE:
		if fp.ga == nMPKineticsAir:
			Ftphysics.ftPhysicsApplyAirVelTransNAll(fighter_gobj)
		else:
			Ftphysics.ftPhysicsApplyGroundVelTransN(fighter_gobj)
	elif fp.motion_vars.flags.flag1 != 0:
		Ftphysics.ftPhysicsApplyAirVelTransNAll(fighter_gobj)

		fp.physics.vel_air.x *= 0.95
		fp.physics.vel_air.y *= 0.95
		fp.physics.vel_air.z *= 0.95
	else:
		Ftphysics.ftPhysicsApplyGravityClampTVel(fp, 0.5, attr.tvel_base)

		if Ftphysics.ftPhysicsCheckClampAirVelXDecMax(fp, attr) == FALSE:
			Ftphysics.ftPhysicsApplyAirVelXFriction(fp, attr)

## 0x80156320
static func ftMarioSpecialHiProcPass(fighter_gobj) -> int: # TRUE = no platform pass?
	var fp := ftGetStruct(fighter_gobj)

	if not (fp.coll_data.floor_flags & MAP_VERTEX_COLL_PASS) or (fp.input.pl.stick_range.y >= FTMARIO_SUPERJUMP_STICK_Y_UNK):
		return TRUE
	else:
		return FALSE

## 0x80156358
static func ftMarioSpecialHiProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsAir:
		if (fp.motion_vars.flags.flag1 == 0) or (fp.physics.vel_air.y >= 0.0):
			Mpcommon.mpCommonCheckFighterProject(fighter_gobj)
		elif Mpcommon.mpCommonCheckFighterPassCliff(fighter_gobj, Callable(Ftmariospecialhi, &"ftMarioSpecialHiProcPass")) != FALSE:
			if fp.coll_data.mask_stat & MAP_FLAG_CLIFF_MASK:
				Ftcommoncliffcatchwait.ftCommonCliffCatchSetStatus(fighter_gobj)
			else:
				Ftcommonlanding.ftCommonLandingFallSpecialSetStatus(fighter_gobj, FALSE, FTMARIO_SUPERJUMP_LANDING_LAG)
	else:
		Mpcommon.mpCommonSetFighterFallOnEdgeBreak(fighter_gobj)

## 0x80156418
static func ftMarioSpecialHiInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag2 = 0
	fp.motion_vars.flags.flag1 = fp.motion_vars.flags.flag2

## 0x80156428
static func ftMarioSpecialHiSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftMarioSpecialHiInitStatusVars(fighter_gobj)

	fp.status_vars.mario.specialhi.is_air_bool = FALSE

	Ftmain.ftMainSetStatus(fighter_gobj, nFTMarioStatusSpecialHi, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80156478
static func ftMarioSpecialAirHiSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftMarioSpecialHiInitStatusVars(fighter_gobj)

	fp.status_vars.mario.specialhi.is_air_bool = TRUE

	fp.physics.vel_air.y = 0.0
	fp.physics.vel_air.x /= 1.5

	Ftmain.ftMainSetStatus(fighter_gobj, nFTMarioStatusSpecialAirHi, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
