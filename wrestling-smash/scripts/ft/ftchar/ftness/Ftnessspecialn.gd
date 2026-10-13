## Port of src/ft/ftchar/ftness/ftnessspecialn.c (Ness neutral special: PK Fire).
class_name Ftnessspecialn
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

const FTNESS_SPECIALN_STATUS_FLAGS = (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80153950
static func ftNessSpecialNProcAccessory(fighter_gobj) -> void: # PK Fire setup
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3
	var vel: Vector3
	var angle: float

	if fp.motion_vars.flags.flag0 != FALSE: # Check if flag to summon PK Fire is true
		fp.motion_vars.flags.flag0 = FALSE # Revert to 0 if PK Fire is summoned, so it doesn't repeat on every frame of the move

		pos.x = 0.0
		pos.y = 0.0
		pos.z = 0.0

		pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[FTNESS_PKFIRE_SPAWN_JOINT], pos)

		pos.x += FTNESS_PKFIRE_SPAWN_OFF_X * fp.lr
		pos.y += FTNESS_PKFIRE_SPAWN_OFF_Y
		pos.z = 0.0

		if fp.ga == nMPKineticsAir:
			vel.z = 0.0
			angle = FTNESS_PKFIRE_SPARK_ANGLE_AIR
			vel.x = __cosf(FTNESS_PKFIRE_SPARK_ANGLE_AIR) * FTNESS_PKFIRE_SPARK_VEL_AIR * fp.lr
			vel.y = __sinf(FTNESS_PKFIRE_SPARK_ANGLE_AIR) * FTNESS_PKFIRE_SPARK_VEL_AIR
		else:
			vel.z = 0.0
			angle = FTNESS_PKFIRE_SPARK_ANGLE_GROUND
			vel.x = __cosf(FTNESS_PKFIRE_SPARK_ANGLE_GROUND) * FTNESS_PKFIRE_SPARK_VEL_GROUND * fp.lr
			vel.y = __sinf(FTNESS_PKFIRE_SPARK_ANGLE_GROUND) * FTNESS_PKFIRE_SPARK_VEL_GROUND

		Wpnesspkfire.wpNessPKFireMakeWeapon(fighter_gobj, pos, vel, angle) # Spawn PK Fire

## 0x80153AC0
static func ftNessSpecialNProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftnessspecialn, &"ftNessSpecialNSwitchStatusAir"))

## 0x80153AE4
static func ftNessSpecialAirNProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftnessspecialn, &"ftNessSpecialAirNSwitchStatusGround"))

## 0x80153B08
static func ftNessSpecialAirNSwitchStatusGround(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialN, fighter_gobj.anim_frame, 1.0, FTNESS_SPECIALN_STATUS_FLAGS) # Action State Change

	fp.proc_accessory = Callable(Ftnessspecialn, &"ftNessSpecialNProcAccessory")

## 0x80153B5C
static func ftNessSpecialNSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialAirN, fighter_gobj.anim_frame, 1.0, FTNESS_SPECIALN_STATUS_FLAGS) # Action State Change

	Ftphysics.ftPhysicsClampAirVelXMax(fp)

	fp.proc_accessory = Callable(Ftnessspecialn, &"ftNessSpecialNProcAccessory")

## 0x80153BB8
static func ftNessSpecialNInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag0 = FALSE
	fp.proc_accessory = Callable(Ftnessspecialn, &"ftNessSpecialNProcAccessory")

## 0x80153BD0
static func ftNessSpecialNSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftNessSpecialNInitStatusVars(fighter_gobj)

## 0x80153C10
static func ftNessSpecialAirNSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialAirN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftNessSpecialNInitStatusVars(fighter_gobj)
