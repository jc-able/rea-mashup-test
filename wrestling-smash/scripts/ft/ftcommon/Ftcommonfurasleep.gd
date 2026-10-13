## 1:1 port of src/ft/ftcommon/ftcommonfurasleep.c (ssb-decomp-re): put to sleep (FuraSleep).
class_name Ftcommonfurasleep
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80149940
static func ftCommonFuraSleepProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var breakout_wait: int

	fp.breakout_wait -= 1

	breakout_wait = fp.breakout_wait

	Ftcommoncapture.ftCommonCaptureTrappedUpdateBreakoutVars(fp)

	fp.breakout_wait += (fp.breakout_wait - breakout_wait) * 3

	if fp.breakout_wait <= 0:
		Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)

## 0x801499A4
static func ftCommonFuraSleepSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var breakout_wait: int

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusFuraSleep, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	breakout_wait = FTCOMMON_FURASLEEP_BREAKOUT_WAIT_DEFAULT - fp.percent_damage

	if breakout_wait <= 0:
		breakout_wait = 0
	breakout_wait += FTCOMMON_FURASLEEP_BREAKOUT_WAIT_MIN

	Ftcommoncapture.ftCommonCaptureTrappedInitBreakoutVars(fp, breakout_wait)
	Ftparam.ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterFuraSleep, 0)
