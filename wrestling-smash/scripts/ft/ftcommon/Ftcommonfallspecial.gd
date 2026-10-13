## 1:1 port of src/ft/ftcommon/ftcommonfallspecial.c (ssb-decomp-re): FallSpecial (helpless fall).
class_name Ftcommonfallspecial
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80143730
static func ftCommonFallSpecialProcInterrupt(fighter_gobj) -> void:
	Ftcommonjumpaerial.ftCommonJumpAerialCheckInterruptCommon(fighter_gobj)

## 0x80143750
static func ftCommonFallSpecialProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	Ftphysics.ftPhysicsCheckSetFastFall(fp)

	if fp.is_fastfall:
		Ftphysics.ftPhysicsApplyFastFall(fp, attr)
	elif fp.status_vars.common.fallspecial.is_fall_accelerate != FALSE: # Accelerate until fighter reaches terminal velocity?
		Ftphysics.ftPhysicsApplyGravityDefault(fp, attr)
	else:
		Ftphysics.ftPhysicsApplyGravityClampTVel(fp, attr.gravity, attr.tvel_fast)

	if not Ftphysics.ftPhysicsCheckClampAirVelXDec(fp, fp.status_vars.common.fallspecial.drift):
		Ftphysics.ftPhysicsClampAirVelXStickRange(fp, FTPHYSICS_AIRDRIFT_CLAMP_RANGE_MIN, attr.air_accel, fp.status_vars.common.fallspecial.drift)
		Ftphysics.ftPhysicsApplyAirVelXFriction(fp, attr)

## 0x80143808
static func ftCommonFallSpecialProcPass(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.status_vars.common.fallspecial.is_allow_pass == FALSE) or not (fp.coll_data.floor_flags & MAP_VERTEX_COLL_PASS) or (fp.input.pl.stick_range.y >= FTCOMMON_FALLSPECIAL_PASS_STICK_RANGE_MIN):
		return TRUE
	else:
		return FALSE

## 0x8014384C
static func ftCommonFallSpecialProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if Mpcommon.mpCommonCheckFighterPassCliff(fighter_gobj, Callable(Ftcommonfallspecial, &"ftCommonFallSpecialProcPass")):
		if fp.coll_data.mask_stat & MAP_FLAG_CLIFF_MASK:
			Ftcommoncliffcatchwait.ftCommonCliffCatchSetStatus(fighter_gobj)
		elif (fp.status_vars.common.fallspecial.is_goto_landing != FALSE) or (fp.physics.vel_air.y < FTCOMMON_FALLSPECIAL_SKIPLANDING_VEL_Y_MAX):
			Ftcommonlanding.ftCommonLandingFallSpecialSetStatus(fighter_gobj, fp.status_vars.common.fallspecial.is_allow_interrupt, fp.status_vars.common.fallspecial.landing_lag)
		else:
			Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)

## 0x801438F0
static func ftCommonFallSpecialSetStatus(fighter_gobj, drift: float, unknown: int, is_fall_accelerate: int, is_goto_landing: int, landing_lag: float, is_allow_interrupt: int) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusFallSpecial, 0.0, 1.0, FTSTATUS_PRESERVE_FASTFALL)

	fp.status_vars.common.fallspecial.drift = (attr.air_speed_max_x * drift)

	Ftphysics.ftPhysicsClampAirVelX(fp, fp.status_vars.common.fallspecial.drift)

	if fp.ga == nMPKineticsGround:
		Mpcommon.mpCommonSetFighterAir(fp)
	fp.jumps_used = attr.jumps_max

	fp.status_vars.common.fallspecial.is_allow_pass = TRUE
	fp.status_vars.common.fallspecial.is_goto_landing = is_goto_landing
	fp.status_vars.common.fallspecial.landing_lag = landing_lag
	fp.status_vars.common.fallspecial.is_allow_interrupt = is_allow_interrupt
	fp.status_vars.common.fallspecial.is_fall_accelerate = is_fall_accelerate

	Ftparam.ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterFallSpecial, 0)
	Ftpublic.ftPublicTryPlayFallSpecialReact(fighter_gobj)

	fp.is_special_interrupt = TRUE
