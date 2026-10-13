## 1:1 port of src/ft/ftcommon/ftcommonshieldbreakfall.c (ssb-decomp-re): falling after a shield break.
class_name Ftcommonshieldbreakfall
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

const FTCOMMON_SHIELDBREAKFALL_STATUS_FLAGS = (FTSTATUS_PRESERVE_DAMAGEPLAYER | FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80149720
static func ftCommonShieldBreakFallProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftcommonshieldbreakdown, &"ftCommonShieldBreakDownSetStatus"))

## 0x80149744
static func ftCommonShieldBreakFallSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusShieldBreakFall, 0.0, 1.0, FTCOMMON_SHIELDBREAKFALL_STATUS_FLAGS) # 0x10B2
	Ftphysics.ftPhysicsClampAirVelXMax(fp)
	Ftparam.ftParamMakeRumble(fp, 3, 0)
