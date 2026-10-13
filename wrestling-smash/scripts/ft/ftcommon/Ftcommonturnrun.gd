## 1:1 port of src/ft/ftcommon/ftcommonturnrun.c (ssb-decomp-re): TurnRun status.
class_name Ftcommonturnrun
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8013F170
static func ftCommonTurnRunProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 != 0:
		fp.motion_vars.flags.flag1 = 0

		fp.lr = -fp.lr
		fp.physics.vel_ground.x = -fp.physics.vel_ground.x
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommonrun, &"ftCommonRunSetStatus"))

## 0x8013F1C0
static func ftCommonTurnRunProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (not Ftcommonkneebend.ftCommonKneeBendCheckInterruptRun(fighter_gobj)) and (fp.motion_vars.flags.flag2 != 0):
		Ftcommonrunbrake.ftCommonRunBrakeCheckInterruptTurnRun(fighter_gobj)

## 0x8013F208
static func ftCommonTurnRunSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusTurnRun, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.motion_vars.flags.flag1 = 0
	fp.motion_vars.flags.flag2 = 0

## 0x8013F248
static func ftCommonTurnRunCheckInterruptRun(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.input.pl.stick_range.x * fp.lr) <= FTCOMMON_TURNRUN_STICK_RANGE_MIN:
		ftCommonTurnRunSetStatus(fighter_gobj)

		return TRUE
	else:
		return FALSE
