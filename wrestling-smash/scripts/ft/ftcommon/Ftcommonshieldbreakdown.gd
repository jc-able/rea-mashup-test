## 1:1 port of src/ft/ftcommon/ftcommonshieldbreakdown.c (ssb-decomp-re): landing after a shield break.
class_name Ftcommonshieldbreakdown
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

const FTCOMMON_SHIELDBREAKDOWN_STATUS_FLAGS = (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80149680 - Probably its own file?
static func ftCommonShieldBreakDownProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommonshieldbreakstand, &"ftCommonShieldBreakStandSetStatus"))

## 0x801496A4
static func ftCommonShieldBreakDownSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int

	if fp.ga == nMPKineticsAir:
		Mpcommon.mpCommonSetFighterGround(fp)
	status_id = nFTCommonStatusShieldBreakDownD if (Ftcommondownwaitbounce.ftCommonDownBounceCheckUpOrDown(fighter_gobj) != 0) else nFTCommonStatusShieldBreakDownU

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTCOMMON_SHIELDBREAKDOWN_STATUS_FLAGS)
	Ftcommondownwaitbounce.ftCommonDownBounceUpdateEffects(fighter_gobj)
