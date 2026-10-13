## Port of src/ft/ftchar/ftfox/ftfoxspecialn.c (Fox neutral special: Blaster).
class_name Ftfoxspecialn
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8015BB50
static func ftFoxSpecialNProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3

	if fp.motion_vars.flags.flag0 != 0:
		fp.motion_vars.flags.flag0 = 0

		pos.x = FTFOX_BLASTER_SPAWN_OFF_X
		pos.y = 0.0
		pos.z = 0.0

		pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[FTFOX_BLASTER_HOLD_JOINT], pos)
		Wpfoxblaster.wpFoxBlasterMakeWeapon(fighter_gobj, pos)

	if fighter_gobj.anim_frame <= 0.0:
		Mpcommon.mpCommonSetFighterWaitOrFall(fighter_gobj)

## 0x8015BBD8
static func ftFoxSpecialNProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.motion_vars.flags.flag1 != 0) and (fp.input.pl.button_tap & fp.input.button_mask_b):
		if fp.ga == nMPKineticsAir:
			ftFoxSpecialAirNSetStatus(fighter_gobj)
		else:
			ftFoxSpecialNSetStatus(fighter_gobj)

		Ftparam.ftParamSetMotionID(fp, nFTMotionAttackIDSpecialN)
		Ftparam.ftParamSetStatUpdate(fp, fp.stat_flags.halfword)
		Ftparam.ftParamUpdate1PGameAttackStats(fp, 0)

## 0x8015BC68
static func ftFoxSpecialNInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag0 = 0
	fp.motion_vars.flags.flag1 = 0

## 0x8015BC78
static func ftFoxSpecialNSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftFoxSpecialNInitStatusVars(fighter_gobj)

## 0x8015BCB8
static func ftFoxSpecialAirNSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialAirN, 0.0, 1.0, FTSTATUS_PRESERVE_FASTFALL)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftFoxSpecialNInitStatusVars(fighter_gobj)
