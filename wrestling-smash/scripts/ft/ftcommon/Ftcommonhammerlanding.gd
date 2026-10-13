## 1:1 port of src/ft/ftcommon/ftcommonhammerlanding.c (ssb-decomp-re): HammerLanding.
## (landing_anim_frame shares its storage with jump_force in the C union; both keys are written.)
class_name Ftcommonhammerlanding
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80148050
static func ftCommonHammerLandingProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.common.hammer.landing_anim_frame += 1.0
	fp.status_vars.common.hammer.jump_force = fp.status_vars.common.hammer.landing_anim_frame    # union

	# Decomp quirk preserved: "<= 4.0F" is already true on the first update, so the landing lasts 1 tic
	if fp.status_vars.common.hammer.landing_anim_frame <= 4.0:
		Fthammer.ftHammerSetStatusHammerWait(fighter_gobj)

## 0x801480A4
static func ftCommonHammerLandingSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusHammerLanding, Fthammer.ftHammerGetAnimFrame(fighter_gobj), 1.0, Fthammer.ftHammerGetStatUpdateFlags(fighter_gobj))
	Fthammer.ftHammerSetColAnim(fighter_gobj)

	fp.status_vars.common.hammer.landing_anim_frame = 0.0
	fp.status_vars.common.hammer.jump_force = fp.status_vars.common.hammer.landing_anim_frame    # union
