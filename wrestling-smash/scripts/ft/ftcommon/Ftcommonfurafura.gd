## 1:1 port of src/ft/ftcommon/ftcommonfurafura.c (ssb-decomp-re): dizzy after a shield break (FuraFura).
class_name Ftcommonfurafura
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80149810
static func ftCommonFuraFuraProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var breakout_wait: int

	fp.shield_health = 30 if (fp.fkind == nFTKindYoshi) else 30

	fp.breakout_wait -= 1

	breakout_wait = fp.breakout_wait

	Ftcommoncapture.ftCommonCaptureTrappedUpdateBreakoutVars(fp)

	fp.breakout_wait += (fp.breakout_wait - breakout_wait) * 3

	if fp.breakout_wait <= 0:
		Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)

## 0x801498A4
static func ftCommonFuraFuraSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var breakout_wait: int

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusFuraFura, 0.0, 1.0, (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_MODELPART))

	fp.shield_health = 30 if (fp.fkind == nFTKindYoshi) else 30

	breakout_wait = FTCOMMON_FURAFURA_BREAKOUT_WAIT_DEFAULT - fp.percent_damage

	if breakout_wait <= 0:
		breakout_wait = 0
	breakout_wait += FTCOMMON_FURAFURA_BREAKOUT_WAIT_MIN

	Ftcommoncapture.ftCommonCaptureTrappedInitBreakoutVars(fp, breakout_wait)
	Ftparam.ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterFuraFura, 0)
