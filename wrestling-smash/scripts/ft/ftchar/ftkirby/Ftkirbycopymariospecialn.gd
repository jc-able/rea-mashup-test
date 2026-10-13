## 1:1 port of src/ft/ftchar/ftkirby/ftkirbycopymariospecialn.c (ssb-decomp-re): Kirby's copied
## Mario / Luigi Fireball.
class_name Ftkirbycopymariospecialn
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

## FTKIRBY_COPYMARIO_FIREBALL_CHECK_FTKIND(fp, id_true, id_false)
static func FTKIRBY_COPYMARIO_FIREBALL_CHECK_FTKIND(fp, id_true: int, id_false: int) -> int:
	return id_true if ((fp.passive_vars.kirby.copy_id == nFTKindMario) or (fp.passive_vars.kirby.copy_id == nFTKindNMario) or (fp.passive_vars.kirby.copy_id == nFTKindMMario)) else id_false

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801569B0
static func ftKirbyCopyMarioSpecialNProcUpdate(fighter_gobj = null) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Mpcommon, &"mpCommonSetFighterWaitOrFall"))

## 0x801569D4
static func ftKirbyCopyMarioSpecialNProcAccessory(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos
	var fireball_kind: int = 0 # C: uninitialized when copy_id is not a Mario/Luigi kind (unreachable)

	if fp.motion_vars.flags.flag0 != 0:
		fp.motion_vars.flags.flag0 = 0

		pos = Vector3(0.0, 0.0, 0.0)

		pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[FTKIRBY_COPYMARIO_FIREBALL_SPAWN_JOINT], pos)

		match fp.passive_vars.kirby.copy_id: # jtbl at 0x8018C6A0
			nFTKindMario, nFTKindMMario, nFTKindNMario:
				fireball_kind = 0

			nFTKindLuigi, nFTKindNLuigi:
				fireball_kind = 1

		Wpmariofireball.wpMarioFireballMakeWeapon(fighter_gobj, pos, fireball_kind)

## 0x80156A74
static func ftKirbyCopyMarioSpecialNProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftkirbycopymariospecialn, &"ftKirbyCopyMarioSpecialNSwitchStatusAir"))

## 0x80156A98
static func ftKirbyCopyMarioSpecialAirNProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbycopymariospecialn, &"ftKirbyCopyMarioSpecialAirNSwitchStatusGround"))

## 0x80156ABC
static func ftKirbyCopyMarioSpecialAirNSwitchStatusGround(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)

	Ftmain.ftMainSetStatus(fighter_gobj, FTKIRBY_COPYMARIO_FIREBALL_CHECK_FTKIND(fp, nFTKirbyStatusCopyMarioSpecialN, nFTKirbyStatusCopyLuigiSpecialN), fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_COLANIM)

	fp.proc_accessory = Callable(Ftkirbycopymariospecialn, &"ftKirbyCopyMarioSpecialNProcAccessory")

## 0x80156B38
static func ftKirbyCopyMarioSpecialNSwitchStatusAir(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)

	Ftmain.ftMainSetStatus(fighter_gobj, FTKIRBY_COPYMARIO_FIREBALL_CHECK_FTKIND(fp, nFTKirbyStatusCopyMarioSpecialAirN, nFTKirbyStatusCopyLuigiSpecialAirN), fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_COLANIM)

	Ftphysics.ftPhysicsClampAirVelXMax(fp)

	fp.proc_accessory = Callable(Ftkirbycopymariospecialn, &"ftKirbyCopyMarioSpecialNProcAccessory")

## 0x80156BB8
static func ftKirbyCopyMarioSpecialNInitStatusVars(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag0 = 0
	fp.proc_accessory = Callable(Ftkirbycopymariospecialn, &"ftKirbyCopyMarioSpecialNProcAccessory")

## 0x80156BD0
static func ftKirbyCopyMarioSpecialNSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, FTKIRBY_COPYMARIO_FIREBALL_CHECK_FTKIND(fp, nFTKirbyStatusCopyMarioSpecialN, nFTKirbyStatusCopyLuigiSpecialN), 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftKirbyCopyMarioSpecialNInitStatusVars(fighter_gobj)

## 0x80156C38
static func ftKirbyCopyMarioSpecialAirNSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, FTKIRBY_COPYMARIO_FIREBALL_CHECK_FTKIND(fp, nFTKirbyStatusCopyMarioSpecialAirN, nFTKirbyStatusCopyLuigiSpecialAirN), 0.0, 1.0, FTSTATUS_PRESERVE_FASTFALL)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftKirbyCopyMarioSpecialNInitStatusVars(fighter_gobj)
