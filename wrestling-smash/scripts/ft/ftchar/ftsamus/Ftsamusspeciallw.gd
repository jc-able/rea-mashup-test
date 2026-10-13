## 1:1 port of src/ft/ftchar/ftsamus/ftsamusspeciallw.c (ssb-decomp-re).
## Samus down special (Bomb).
class_name Ftsamusspeciallw
extends Port

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8015DF00
static func ftSamusSpecialLwMakeBomb(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3
	var joint: DObj

	if fp.motion_vars.flags.flag0 != FALSE:
		fp.motion_vars.flags.flag0 = FALSE

		pos.z = 0.0
		pos.x = pos.z
		pos.y = FTSAMUS_BOMB_OFF_Y

		joint = fp.joints[nFTPartsJointTopN] # Not required but stack frame might be suggesting they wrote it like this

		pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(joint, pos)
		Wpsamusbomb.wpSamusBombMakeWeapon(fighter_gobj, pos)

## 0x8015DF64
static func ftSamusSpecialLwProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftSamusSpecialLwMakeBomb(fighter_gobj)

	if fp.ga == nMPKineticsAir:
		ftSamusSpecialLwTransferStatusAir(fighter_gobj)
	else:
		Ftanimend.ftAnimEndSetWait(fighter_gobj)

## 0x8015DFBC
static func ftSamusSpecialAirLwProcUpdate(fighter_gobj) -> void:
	ftSamusSpecialLwMakeBomb(fighter_gobj)
	Ftanimend.ftAnimEndSetFall(fighter_gobj)

## 0x8015DFE4
static func ftSamusSpecialLwProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if fp.motion_vars.flags.flag3 != FALSE:
		Ftphysics.ftPhysicsSetGroundVelStickRange(fp, attr.walk_speed_mul * FTSAMUS_BOMB_DRIFT, attr.traction)
		Ftphysics.ftPhysicsSetGroundVelTransferAir(fighter_gobj)
	else:
		Ftphysics.ftPhysicsApplyGroundVelFriction(fighter_gobj)

## 0x8015E050
static func ftSamusSpecialAirLwProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	Ftphysics.ftPhysicsApplyGravityDefault(fp, attr)

	if Ftphysics.ftPhysicsCheckClampAirVelXDec(fp, attr.air_speed_max_x * FTSAMUS_BOMB_DRIFT) == FALSE:
		Ftphysics.ftPhysicsClampAirVelXStickRange(fp, FTPHYSICS_AIRDRIFT_CLAMP_RANGE_MIN, attr.air_accel * FTSAMUS_BOMB_DRIFT, attr.air_speed_max_x * FTSAMUS_BOMB_DRIFT)
		Ftphysics.ftPhysicsApplyAirVelXFriction(fp, attr)

## 0x8015E0E8
static func ftSamusSpecialLwProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftsamusspeciallw, &"ftSamusSpecialLwSwitchStatusAir"))

## 0x8015E10C
static func ftSamusSpecialAirLwProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftsamusspeciallw, &"ftSamusSpecialAirLwSwitchStatusGround"))

## 0x8015E130
static func ftSamusSpecialAirLwSwitchStatusGround(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag3 = FALSE

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTSamusStatusSpecialLw, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_NONE)

## 0x8015E170 - Go to aerial Screw Attack from grounded update process
static func ftSamusSpecialLwTransferStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTSamusStatusSpecialAirLw, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.physics.vel_air.y = FTSAMUS_BOMB_VEL_Y_BASE
	fp.jumps_used = attr.jumps_max

## 0x8015E1DC
static func ftSamusSpecialLwSwitchStatusAir(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterAir(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTSamusStatusSpecialAirLw, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_NONE)

## 0x8015E218
static func ftSamusSpecialLwInitStatusVars(fp: Fighter) -> void:
	fp.motion_vars.flags.flag0 = FALSE

## 0x8015E220
static func ftSamusSpecialLwSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag3 = FALSE

	Ftmain.ftMainSetStatus(fighter_gobj, nFTSamusStatusSpecialLw, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftSamusSpecialLwInitStatusVars(fp)

	fp.status_vars.samus.speciallw.unused = FALSE

## 0x8015E274
static func ftSamusSpecialAirLwSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	Ftmain.ftMainSetStatus(fighter_gobj, nFTSamusStatusSpecialAirLw, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftSamusSpecialLwInitStatusVars(fp)

	fp.physics.vel_air.y = FTSAMUS_BOMB_VEL_Y_BASE - FTSAMUS_BOMB_VEL_Y_SUB

	Ftphysics.ftPhysicsClampAirVelX(fp, attr.air_speed_max_x * FTSAMUS_BOMB_DRIFT)

	fp.jumps_used = attr.jumps_max # Why tho

	fp.status_vars.samus.speciallw.unused = TRUE
