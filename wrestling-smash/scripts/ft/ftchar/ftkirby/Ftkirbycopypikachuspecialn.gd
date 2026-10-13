## 1:1 port of src/ft/ftchar/ftkirby/ftkirbycopypikachuspecialn.c (ssb-decomp-re): Kirby's copied
## Pikachu Thunder Jolt.
class_name Ftkirbycopypikachuspecialn
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

const FTKIRBY_COPYPIKACHU_SPECIALN_STATUS_FLAGS := (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801536C0
static func ftKirbyCopyPikachuSpecialNProcAccessory(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos
	var vel: Vector3

	if fp.motion_vars.flags.flag0 != 0:
		fp.motion_vars.flags.flag0 = 0

		pos = Vector3(0.0, 0.0, 0.0)

		pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[FTKIRBY_COPYPIKACHU_THUNDERJOLT_SPAWN_JOINT], pos)

		pos.x += FTKIRBY_COPYPIKACHU_THUNDERJOLT_SPAWN_OFF_X * fp.lr
		pos.y += FTKIRBY_COPYPIKACHU_THUNDERJOLT_SPAWN_OFF_Y

		vel.x = __cosf(FTKIRBY_COPYPIKACHU_THUNDERJOLT_SPAWN_ANGLE) * FTKIRBY_COPYPIKACHU_THUNDERJOLTVEL * fp.lr
		vel.y = __sinf(FTKIRBY_COPYPIKACHU_THUNDERJOLT_SPAWN_ANGLE) * FTKIRBY_COPYPIKACHU_THUNDERJOLTVEL
		vel.z = 0.0

		Wppikachuthunderjolt.wpPikachuThunderJoltAirMakeWeapon(fighter_gobj, pos, vel)
		Ftparam.ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterPikachuSpecialN, 0)

## 0x801537B8
static func ftKirbyCopyPikachuSpecialNProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftkirbycopypikachuspecialn, &"ftKirbyCopyPikachuSpecialNSwitchStatusAir"))

## 0x801537DC
static func ftKirbyCopyPikachuSpecialAirNProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbycopypikachuspecialn, &"ftKirbyCopyPikachuSpecialAirNSwitchStatusGround"))

## 0x80153800
static func ftKirbyCopyPikachuSpecialAirNSwitchStatusGround(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyPikachuSpecialN, fighter_gobj.anim_frame, 1.0, FTKIRBY_COPYPIKACHU_SPECIALN_STATUS_FLAGS)

	fp.proc_accessory = Callable(Ftkirbycopypikachuspecialn, &"ftKirbyCopyPikachuSpecialNProcAccessory")

## 0x80153854
static func ftKirbyCopyPikachuSpecialNSwitchStatusAir(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyPikachuSpecialAirN, fighter_gobj.anim_frame, 1.0, FTKIRBY_COPYPIKACHU_SPECIALN_STATUS_FLAGS)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

	fp.proc_accessory = Callable(Ftkirbycopypikachuspecialn, &"ftKirbyCopyPikachuSpecialNProcAccessory")

## 0x801538B0
static func ftKirbyCopyPikachuSpecialNInitStatusVars(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag0 = 0

	fp.proc_accessory = Callable(Ftkirbycopypikachuspecialn, &"ftKirbyCopyPikachuSpecialNProcAccessory")

## 0x801538C8
static func ftKirbyCopyPikachuSpecialNSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyPikachuSpecialN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftKirbyCopyPikachuSpecialNInitStatusVars(fighter_gobj)

## 0x80153908
static func ftKirbyCopyPikachuSpecialAirNSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyPikachuSpecialAirN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftKirbyCopyPikachuSpecialNInitStatusVars(fighter_gobj)
