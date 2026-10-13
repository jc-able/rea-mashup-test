## 1:1 port of src/ft/ftcommon/ftcommonlanding.c (ssb-decomp-re): LandingLight / LandingHeavy /
## LandingAirNull / LandingFallSpecial.
class_name Ftcommonlanding
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

## ftCommonLandingCheckInterrupt (macro in ftcommonlanding.c): short-circuit || chain, exact C order.
static func ftCommonLandingCheckInterrupt(fighter_gobj) -> bool:
	return (
		Ftcommonspecialn.ftCommonSpecialNCheckInterruptCommon(fighter_gobj) or
		Ftcommonspecialhi.ftCommonSpecialHiCheckInterruptCommon(fighter_gobj) or
		Ftcommonspeciallw.ftCommonSpecialLwCheckInterruptCommon(fighter_gobj) or
		Ftcommoncatch1.ftCommonCatchCheckInterruptCommon(fighter_gobj) or
		Ftcommonattacks4.ftCommonAttackS4CheckInterruptCommon(fighter_gobj) or
		Ftcommonattackhi4.ftCommonAttackHi4CheckInterruptCommon(fighter_gobj) or
		Ftcommonattacklw4.ftCommonAttackLw4CheckInterruptCommon(fighter_gobj) or
		Ftcommonattacks3.ftCommonAttackS3CheckInterruptCommon(fighter_gobj) or
		Ftcommonattackhi3.ftCommonAttackHi3CheckInterruptCommon(fighter_gobj) or
		Ftcommonattacklw3.ftCommonAttackLw3CheckInterruptCommon(fighter_gobj) or
		Ftcommonattack1.ftCommonAttack1CheckInterruptCommon(fighter_gobj) or
		Ftcommonguard1.ftCommonGuardOnCheckInterruptCommon(fighter_gobj) or
		Ftcommonappeal.ftCommonAppealCheckInterruptCommon(fighter_gobj) or
		Ftcommonkneebend.ftCommonKneeBendCheckInterruptCommon(fighter_gobj) or
		Ftcommondash.ftCommonDashCheckInterruptCommon(fighter_gobj) or
		Ftcommonpass.ftCommonPassCheckInterruptCommon(fighter_gobj) or
		Ftcommondokan.ftCommonDokanStartCheckInterruptCommon(fighter_gobj)
	)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80142B70
static func ftCommonLandingProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fighter_gobj.anim_frame < FTCOMMON_LANDING_INTERRUPT_BEGIN:
		return
	elif (fp.status_vars.common.landing.is_allow_interrupt != FALSE) and not ftCommonLandingCheckInterrupt(fighter_gobj):
		if (fighter_gobj.anim_frame >= FTCOMMON_LANDING_INTERRUPT_BEGIN) and (fighter_gobj.anim_frame < (FTCOMMON_LANDING_INTERRUPT_BEGIN + DObjGetStruct(fighter_gobj).anim_speed)):
			if Ftcommonsquat.ftCommonSquatWaitCheckInterruptLanding(fighter_gobj): return
		elif Ftcommonsquat.ftCommonSquatCheckInterruptCommon(fighter_gobj): return

		if not Ftcommonturn.ftCommonTurnCheckInterruptCommon(fighter_gobj):
			Ftcommonwalk.ftCommonWalkCheckInterruptCommon(fighter_gobj)

## 0x80142D44
static func ftCommonLandingSetStatusParam(fighter_gobj, status_id: int, is_allow_interrupt: int, anim_speed: float) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, anim_speed, FTSTATUS_PRESERVE_NONE)

	fp.status_vars.common.landing.is_allow_interrupt = is_allow_interrupt

## 0x80142D9C
static func ftCommonLandingSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.is_fastfall and (fp.physics.vel_air.y <= -fp.attr.tvel_fast):
		ftCommonLandingSetStatusParam(fighter_gobj, nFTCommonStatusLandingHeavy, TRUE, FTCOMMON_LANDING_HEAVY_ANIM_SPEED)
	else:
		ftCommonLandingSetStatusParam(fighter_gobj, nFTCommonStatusLandingLight, TRUE, FTCOMMON_LANDING_LIGHT_ANIM_SPEED)

## 0x80142E10
static func ftCommonLandingAirNullSetStatus(fighter_gobj, anim_speed: float) -> void:
	ftCommonLandingSetStatusParam(fighter_gobj, nFTCommonStatusLandingAirNull, FALSE, anim_speed)

## 0x80142E3C
static func ftCommonLandingFallSpecialSetStatus(fighter_gobj, is_allow_interrupt: int, anim_speed: float) -> void:
	ftCommonLandingSetStatusParam(fighter_gobj, nFTCommonStatusLandingFallSpecial, is_allow_interrupt, anim_speed)
