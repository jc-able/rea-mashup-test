## 1:1 port of src/ft/ftcommon/ftcommonrun.c (ssb-decomp-re): Run status.
class_name Ftcommonrun
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8013EE50
static func ftCommonRunProcInterrupt(fighter_gobj) -> void:
	if (
		(not Ftcommonspecialn.ftCommonSpecialNCheckInterruptCommon(fighter_gobj)) and
		(not Ftcommoncatch1.ftCommonCatchCheckInterruptDashRun(fighter_gobj)) and
		(not Ftcommonattackdash.ftCommonAttackDashCheckInterruptCommon(fighter_gobj)) and
		(not Ftcommonguard1.ftCommonGuardOnCheckInterruptDashRun(fighter_gobj, 4)) and
		(not Ftcommonappeal.ftCommonAppealCheckInterruptCommon(fighter_gobj)) and
		(not Ftcommonkneebend.ftCommonKneeBendCheckInterruptRun(fighter_gobj)) and
		(not Ftcommonturnrun.ftCommonTurnRunCheckInterruptRun(fighter_gobj))
	):
		Ftcommonrunbrake.ftCommonRunBrakeCheckInterruptRun(fighter_gobj)

## 0x8013EEE8
static func ftCommonRunSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusRun, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.physics.vel_ground.x = fp.attr.run_speed

## 0x8013EF2C
static func ftCommonRunCheckInterruptDash(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if attr.dash_to_run <= fighter_gobj.anim_frame:
		if fighter_gobj.anim_frame < (attr.dash_to_run + DObjGetStruct(fighter_gobj).anim_speed):
			if (fp.input.pl.stick_range.x * fp.lr) >= FTCOMMON_RUN_STICK_RANGE_MIN:
				ftCommonRunSetStatus(fighter_gobj)

				return TRUE
	return FALSE
