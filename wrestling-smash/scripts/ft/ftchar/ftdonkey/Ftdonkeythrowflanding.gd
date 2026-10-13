## 1:1 port of src/ft/ftchar/ftdonkey/ftdonkeythrowflanding.c (ssb-decomp-re).
## Donkey Kong Cargo Throw: landing.
class_name Ftdonkeythrowflanding
extends Port

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8014DC50
static func ftDonkeyThrowFLandingProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.common.throwf.landing_anim_frame += 1

	# (sic) "<=": DK leaves Landing on its first update, exactly like the C.
	if fp.status_vars.common.throwf.landing_anim_frame <= 4.0:
		Ftdonkeythrowfwait.ftDonkeyThrowFWaitSetStatus(fighter_gobj)

## 0x8014DCA4
static func ftDonkeyThrowFLandingSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusThrowFLanding, 0.0, 0.0, FTSTATUS_PRESERVE_NONE)

	fp.status_vars.common.throwf.landing_anim_frame = 0.0
