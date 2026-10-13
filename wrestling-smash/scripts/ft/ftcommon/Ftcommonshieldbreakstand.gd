## 1:1 port of src/ft/ftcommon/ftcommonshieldbreakstand.c (ssb-decomp-re): standing up after a shield break.
class_name Ftcommonshieldbreakstand
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

const FTCOMMON_SHIELDBREAKSTAND_STATUS_FLAGS = (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801497A0
static func ftCommonShieldBreakStandProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommonfurafura, &"ftCommonFuraFuraSetStatus"))

## 0x801497C4
static func ftCommonShieldBreakStandSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int = nFTCommonStatusShieldBreakStandD if (fp.status_id == nFTCommonStatusShieldBreakDownD) else nFTCommonStatusShieldBreakStandU

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTCOMMON_SHIELDBREAKSTAND_STATUS_FLAGS)
