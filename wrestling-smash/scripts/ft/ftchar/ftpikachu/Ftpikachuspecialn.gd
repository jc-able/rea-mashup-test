## Port of src/ft/ftchar/ftpikachu/ftpikachuspecialn.c (Pikachu neutral special: Thunder Jolt).
class_name Ftpikachuspecialn
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

const FTPIKACHU_SPECIALN_STATUS_FLAGS = (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80151B50
static func ftPikachuSpecialNProcAccessory(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3
	var vel: Vector3

	if fp.motion_vars.flags.flag0 != 0:
		fp.motion_vars.flags.flag0 = 0

		pos.x = 0.0
		pos.y = 0.0
		pos.z = 0.0

		pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[FTPIKACHU_THUNDERJOLT_SPAWN_JOINT], pos)

		vel.x = __cosf(FTPIKACHU_THUNDERJOLT_SPAWN_ANGLE) * FTPIKACHU_THUNDERJOLTVEL * fp.lr
		vel.y = __sinf(FTPIKACHU_THUNDERJOLT_SPAWN_ANGLE) * FTPIKACHU_THUNDERJOLTVEL
		vel.z = 0.0

		Wppikachuthunderjolt.wpPikachuThunderJoltAirMakeWeapon(fighter_gobj, pos, vel)
		Ftparam.ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterPikachuSpecialN, 0)

## 0x80151C14
static func ftPikachuSpecialNProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftpikachuspecialn, &"ftPikachuSpecialNSwitchStatusAir"))

## 0x80151C38
static func ftPikachuSpecialAirNProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftpikachuspecialn, &"ftPikachuSpecialAirNSwitchStatusGround"))

## 0x80151C5C
static func ftPikachuSpecialAirNSwitchStatusGround(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialN, fighter_gobj.anim_frame, 1.0, FTPIKACHU_SPECIALN_STATUS_FLAGS)

	fp.proc_accessory = Callable(Ftpikachuspecialn, &"ftPikachuSpecialNProcAccessory")

## 0x80151CB0
static func ftPikachuSpecialNSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialAirN, fighter_gobj.anim_frame, 1.0, FTPIKACHU_SPECIALN_STATUS_FLAGS)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

	fp.proc_accessory = Callable(Ftpikachuspecialn, &"ftPikachuSpecialNProcAccessory")

## 0x80151D0C
static func ftPikachuSpecialNInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag0 = 0
	fp.proc_accessory = Callable(Ftpikachuspecialn, &"ftPikachuSpecialNProcAccessory")

## 0x80151D24
static func ftPikachuSpecialNSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftPikachuSpecialNInitStatusVars(fighter_gobj)

## 0x80151D64
static func ftPikachuSpecialAirNSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialAirN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftPikachuSpecialNInitStatusVars(fighter_gobj)
