## 1:1 port of src/ft/ftcommon/ftcommonlandingair.c (ssb-decomp-re): landing lag after an aerial attack.
class_name Ftcommonlandingair
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80150E80
static func ftCommonLandingAirSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, fp.status_id + (nFTCommonStatusLandingAirEnd - nFTCommonStatusLandingAirStart), 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
