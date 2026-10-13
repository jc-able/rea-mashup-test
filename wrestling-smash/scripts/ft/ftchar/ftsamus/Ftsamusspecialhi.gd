## 1:1 port of src/ft/ftchar/ftsamus/ftsamusspecialhi.c (ssb-decomp-re).
## Samus up special (Screw Attack).
class_name Ftsamusspecialhi
extends Port

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8015DC40
static func ftSamusSpecialHiProcUpdate(fighter_gobj) -> void:
	if fighter_gobj.anim_frame <= 0.0:
		Ftcommonfallspecial.ftCommonFallSpecialSetStatus(fighter_gobj, FTSAMUS_SCREWATTACK_FALLSPECIAL_DRIFT, TRUE, TRUE, TRUE, FTSAMUS_SCREWATTACK_LANDING_LAG, FALSE)

## 0x8015DC94
static func ftSamusSpecialHiProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 != FALSE:
		fp.motion_vars.flags.flag1 = FALSE
		fp.physics.vel_air.x = fp.lr * FTSAMUS_SCREWATTACK_VEL_X_BASE
	if fp.ga == nMPKineticsAir:
		Ftphysics.ftPhysicsApplyAirVelTransNYZ(fighter_gobj)
		Ftphysics.ftPhysicsClampAirVelXStickRange(fp, 0, FTSAMUS_SCREWATTACK_DRIFT_MUL, FTSAMUS_SCREWATTACK_DRIFT_CLAMP)
	else:
		Ftphysics.ftPhysicsApplyGroundVelFriction(fighter_gobj)

## 0x8015DD20
static func ftSamusSpecialHiProcPass(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if not (fp.coll_data.floor_flags & MAP_VERTEX_COLL_PASS) or (fp.input.pl.stick_range.y >= FTSAMUS_SCREWATTACK_PASS_STICK_RANGE_MIN):
		return TRUE
	else:
		return FALSE

## 0x8015DD58
static func ftSamusSpecialHiProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsAir:
		if fp.physics.vel_air.y >= 0.0:
			Mpcommon.mpCommonCheckFighterProject(fighter_gobj)
		elif Mpcommon.mpCommonCheckFighterPassCliff(fighter_gobj, Callable(Ftsamusspecialhi, &"ftSamusSpecialHiProcPass")) != FALSE:
			if fp.coll_data.mask_stat & MAP_FLAG_CLIFF_MASK:
				Ftcommoncliffcatchwait.ftCommonCliffCatchSetStatus(fighter_gobj)
			else:
				Ftcommonlanding.ftCommonLandingFallSpecialSetStatus(fighter_gobj, FALSE, FTSAMUS_SCREWATTACK_LANDING_LAG)
	else:
		Mpcommon.mpCommonSetFighterFallOnEdgeBreak(fighter_gobj)

## 0x8015DE0C
static func ftSamusSpecialHiSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTSamusStatusSpecialHi, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.motion_vars.flags.flag1 = 0

## 0x8015DE54
static func ftSamusSpecialAirHiProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftphysics.ftPhysicsApplyGravityDefault(fp, fp.attr)
	Ftphysics.ftPhysicsClampAirVelXStickRange(fp, 0, FTSAMUS_SCREWATTACK_DRIFT_MUL, FTSAMUS_SCREWATTACK_DRIFT_CLAMP)

## 0x8015DE90
static func ftSamusSpecialAirHiSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTSamusStatusSpecialAirHi, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.jumps_used = fp.attr.jumps_max
	fp.physics.vel_air.y = FTSAMUS_SCREWATTACK_VEL_Y_BASE

	Ftphysics.ftPhysicsClampAirVelX(fp, FTSAMUS_SCREWATTACK_DRIFT_CLAMP)
