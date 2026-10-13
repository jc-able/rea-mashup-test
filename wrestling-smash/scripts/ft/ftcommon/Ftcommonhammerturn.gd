## 1:1 port of src/ft/ftcommon/ftcommonhammerturn.c (ssb-decomp-re): HammerTurn.
class_name Ftcommonhammerturn
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80147A70
static func ftCommonHammerTurnUpdateModelYaw(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 != 0:
		fp.motion_vars.flags.flag1 -= 1    # u32, nonzero here so no wrap

		if fp.motion_vars.flags.flag1 == (FTCOMMON_HAMMER_TURN_FRAMES / 2):
			fp.lr = -fp.lr
		fp.joints[nFTPartsJointTopN].rotate.y += FTCOMMON_HAMMER_TURN_ROTATE_STEP

		Ftparam.ftParamsUpdateFighterPartsTransformAll(fp.joints[nFTPartsJointTopN])

## 0x80147AD0
static func ftCommonHammerTurnProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftCommonHammerTurnUpdateModelYaw(fighter_gobj)

	if fp.motion_vars.flags.flag1 == 0:
		Fthammer.ftHammerSetStatusHammerWait(fighter_gobj)

## 0x80147B14
static func ftCommonHammerTurnProcInterrupt(fighter_gobj) -> void:
	Ftcommonhammerkneebend.ftCommonHammerKneeBendCheckInterruptCommon(fighter_gobj)

## 0x80147B34
static func ftCommonHammerTurnSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag1 = FTCOMMON_HAMMER_TURN_FRAMES

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusHammerTurn, Fthammer.ftHammerGetAnimFrame(fighter_gobj), 1.0, Fthammer.ftHammerGetStatUpdateFlags(fighter_gobj))
	Fthammer.ftHammerSetColAnim(fighter_gobj)
	ftCommonHammerTurnUpdateModelYaw(fighter_gobj)

## 0x80147B9C
static func ftCommonHammerTurnCheckInterruptCommon(fighter_gobj) -> int:
	if B(Ftcommonturn.ftCommonTurnCheckInputSuccess(fighter_gobj)):
		ftCommonHammerTurnSetStatus(fighter_gobj)

		return TRUE
	else:
		return FALSE
