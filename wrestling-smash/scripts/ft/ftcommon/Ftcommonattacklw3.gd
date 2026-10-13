## 1:1 port of src/ft/ftcommon/ftcommonattacklw3.c (ssb-decomp-re): down tilt (AttackLw3), re-triggerable.
class_name Ftcommonattacklw3
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8014FBF0
static func ftCommonAttackLw3ProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.motion_vars.flags.flag1 != 0) and (fp.status_vars.common.attacklw3.is_goto_attacklw3 != FALSE):
		ftCommonAttackLw3SetStatus(fighter_gobj)
	else:
		Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommonsquat, &"ftCommonSquatWaitSetStatus"))

## 0x8014FC40
static func ftCommonAttackLw3ProcInterrupt(fighter_gobj) -> void:
	ftCommonAttackLw3CheckInterruptSelf(fighter_gobj)

## 0x8014FC60
static func ftCommonAttackLw3CheckInterruptSelf(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if (fp.input.pl.button_tap & fp.input.button_mask_a) and attr.is_have_attacklw3:
		if fp.motion_vars.flags.flag1 != 0:
			ftCommonAttackLw3SetStatus(fighter_gobj)

			return TRUE
		else:
			fp.status_vars.common.attacklw3.is_goto_attacklw3 = TRUE
	return FALSE

## 0x8014FCCC
static func ftCommonAttackLw3InitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag1 = 0

	fp.status_vars.common.attacklw3.is_goto_attacklw3 = FALSE

	Ftparam.ftParamSetMotionID(fp, nFTMotionAttackIDAttackLw3)
	Ftparam.ftParamSetStatUpdate(fp, fp.stat_flags.halfword)
	Ftparam.ftParamUpdate1PGameAttackStats(fp, 0)

## 0x8014FD14
static func ftCommonAttackLw3SetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if not Ftcommonget.ftCommonGetCheckInterruptCommon(fighter_gobj):
		fp.proc_status = Callable(Ftcommonattacklw3, &"ftCommonAttackLw3InitStatusVars")

		Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusAttackLw3, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
		Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x8014FD70
static func ftCommonAttackLw3CheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if (fp.input.pl.button_tap & fp.input.button_mask_a) and (fp.input.pl.stick_range.y <= FTCOMMON_ATTACKLW3_STICK_RANGE_MIN):
		if Ftparam.ftParamGetStickAngleRads(fp) < F_CST_DTOR32(-50.0): # -0.87266463F
			if Ftcommonitemthrow.ftCommonLightThrowCheckItemTypeThrow(fp):
				Ftcommonitemthrow.ftCommonItemThrowSetStatus(fighter_gobj, nFTCommonStatusLightThrowLw)

				return TRUE
			elif attr.is_have_attacklw3:
				ftCommonAttackLw3SetStatus(fighter_gobj)

				return TRUE
	return FALSE
