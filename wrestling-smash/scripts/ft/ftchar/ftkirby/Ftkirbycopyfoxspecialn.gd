## 1:1 port of src/ft/ftchar/ftkirby/ftkirbycopyfoxspecialn.c (ssb-decomp-re): Kirby's copied
## Fox Blaster.
class_name Ftkirbycopyfoxspecialn
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80156CB0
static func ftKirbyCopyFoxSpecialNProcUpdate(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos

	if fp.motion_vars.flags.flag0 != FALSE:
		fp.motion_vars.flags.flag0 = FALSE

		pos = Vector3(FTKIRBY_COPYFOX_BLASTER_SPAWN_OFF_X, 0.0, 0.0)

		pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[FTKIRBY_COPYFOX_BLASTER_SPAWN_JOINT], pos)
		Wpfoxblaster.wpFoxBlasterMakeWeapon(fighter_gobj, pos)

	if fighter_gobj.anim_frame <= 0.0:
		Mpcommon.mpCommonSetFighterWaitOrFall(fighter_gobj)

## 0x80156D38
static func ftKirbyCopyFoxSpecialNProcInterrupt(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.motion_vars.flags.flag1 != 0) and (fp.input.pl.button_tap & fp.input.button_mask_b):
		if fp.ga == nMPKineticsAir:
			ftKirbyCopyFoxSpecialAirNSetStatus(fighter_gobj)
		else:
			ftKirbyCopyFoxSpecialNSetStatus(fighter_gobj)

		Ftparam.ftParamSetMotionID(fp, nFTMotionAttackIDSpecialNCopyFox)
		Ftparam.ftParamSetStatUpdate(fp, fp.stat_flags.halfword)
		Ftparam.ftParamUpdate1PGameAttackStats(fp, 0)

## 0x80156DC8
static func ftKirbyCopyFoxSpecialNInitStatusVars(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag0 = 0
	fp.motion_vars.flags.flag1 = 0

## 0x80156DD8
static func ftKirbyCopyFoxSpecialNSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyFoxSpecialN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftKirbyCopyFoxSpecialNInitStatusVars(fighter_gobj)

## 0x80156E18
static func ftKirbyCopyFoxSpecialAirNSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyFoxSpecialAirN, 0.0, 1.0, FTSTATUS_PRESERVE_FASTFALL)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftKirbyCopyFoxSpecialNInitStatusVars(fighter_gobj)
