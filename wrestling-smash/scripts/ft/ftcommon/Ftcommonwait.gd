## 1:1 port of src/ft/ftcommon/ftcommonwait.c (ssb-decomp-re): standing idle (Wait) status.
class_name Ftcommonwait
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

## ftCommonGroundCheckInterrupt (src/ft/fighter.h): "Macro to check if a move has been interrupted
## by any standard action". Short-circuit || chain of `!= FALSE` tests, in the exact C order.
static func ftCommonGroundCheckInterrupt(fighter_gobj) -> bool:
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
		Ftcommondokan.ftCommonDokanStartCheckInterruptCommon(fighter_gobj) or
		Ftcommonsquat.ftCommonSquatCheckInterruptCommon(fighter_gobj) or
		Ftcommonturn.ftCommonTurnCheckInterruptCommon(fighter_gobj) or
		Ftcommonwalk.ftCommonWalkCheckInterruptCommon(fighter_gobj)
	)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8013E070
static func ftCommonWaitProcInterrupt(fighter_gobj) -> void:
	# !(ftCommonGroundCheckInterrupt(fighter_gobj)); - evaluated for its side effects, result discarded
	ftCommonGroundCheckInterrupt(fighter_gobj)

## 0x8013E1C8
static func ftCommonWaitSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if Fthammer.ftHammerCheckHoldHammer(fighter_gobj):
		Fthammer.ftHammerSetStatusHammerWait(fighter_gobj)
	else:
		if fp.ga == nMPKineticsAir:
			Mpcommon.mpCommonSetFighterGround(fp)
		Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusWait, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

		fp.is_special_interrupt = TRUE

		Ftparam.ftParamSetPlayerTagWait(fighter_gobj, 120)

## 0x8013E258
static func ftCommonWaitCheckInputSuccess(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if ((fp.input.pl.stick_range.x * fp.lr) < 0) or (ABS(fp.input.pl.stick_range.x) < 8):
		return TRUE
	else:
		return FALSE

## 0x8013E2A0
static func ftCommonWaitCheckInterruptCommon(fighter_gobj) -> int:
	if ftCommonWaitCheckInputSuccess(fighter_gobj) != FALSE:
		ftCommonWaitSetStatus(fighter_gobj)

		return TRUE
	else:
		return FALSE
