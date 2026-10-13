## 1:1 port of src/ft/fthammer.c (ssb-decomp-re): Hammer item timer and the shared helpers of the
## Hammer statuses (HammerWait / Walk / Turn / KneeBend / Fall / Landing).
class_name Fthammer
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x800F36E0
static func ftHammerUpdateStats(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.hammer_tics != 0:
		fp.hammer_tics -= 1
	if fp.hammer_tics == ITHAMMER_WARN_BEGIN_FRAME:
		Ithammer.itHammerCommonSetColAnim(fp.item_gobj)
	if fp.hammer_tics == 0:
		var is_colanim_reset: int = FALSE

		Itmain.itMainDestroyItem(fp.item_gobj)
		Ftparam.ftParamTryUpdateItemMusic()

		if fp.colanim.colanim_id == FTCOMMON_HAMMER_COLANIM_ID:
			is_colanim_reset = TRUE
		if ftHammerCheckStatusHammerAll(fighter_gobj) != FALSE:
			Mpcommon.mpCommonSetFighterWaitOrFall(fighter_gobj)
		if is_colanim_reset != FALSE:
			Ftparam.ftParamResetStatUpdateColAnim(fighter_gobj)

## 0x800F3794
static func ftHammerCheckHoldHammer(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.item_gobj != null) and (itGetStruct(fp.item_gobj).kind == nITKindHammer):
		return TRUE
	else:
		return FALSE

## 0x800F37CC
static func ftHammerCheckStatusHammerAll(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.status_id >= nFTCommonStatusHammerStart) and (fp.status_id <= nFTCommonStatusHammerEnd):
		return TRUE
	else:
		return FALSE

## 0x800F37FC
static func ftHammerCheckMotionWaitOrWalk(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.motion_id == nFTCommonMotionHammerWait) or (fp.motion_id == nFTCommonMotionHammerWalk):
		return TRUE
	else:
		return FALSE

## 0x800F3828
static func ftHammerGetAnimFrame(fighter_gobj) -> float:
	if ftHammerCheckMotionWaitOrWalk(fighter_gobj) != FALSE:
		return fighter_gobj.anim_frame
	else:
		return 0.0

## 0x800F385C
static func ftHammerGetStatUpdateFlags(fighter_gobj) -> int:
	var flags: int

	if ftHammerCheckMotionWaitOrWalk(fighter_gobj) != FALSE:
		flags = (FTSTATUS_PRESERVE_RUMBLE | FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_SLOPECONTOUR | FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_COLANIM | FTSTATUS_PRESERVE_HIT)
	else:
		flags = FTSTATUS_PRESERVE_NONE

	return flags

## 0x800F388C
static func ftHammerSetColAnim(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.colanim.colanim_id != nGMColAnimFighterHammer:
		Ftparam.ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterHammer, 0)

## 0x800F38C4
static func ftHammerProcInterrupt(fighter_gobj) -> void:
	if (
		(not B(Ftcommonhammerkneebend.ftCommonHammerKneeBendCheckInterruptCommon(fighter_gobj))) and
		(not B(Ftcommonhammerfall.ftCommonHammerFallCheckInterruptCommon(fighter_gobj))) and
		(not B(Ftcommonhammerturn.ftCommonHammerTurnCheckInterruptCommon(fighter_gobj)))
	):
		Ftcommonhammerwalk.ftCommonHammerWalkCheckInterruptCommon(fighter_gobj)

## 0x800F3914
static func ftHammerProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftcommonhammerfall, &"ftCommonHammerFallSetStatus"))

## 0x800F3938
static func ftHammerSetStatusHammerWait(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsAir:
		Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusHammerWait, ftHammerGetAnimFrame(fighter_gobj), 1.0, ftHammerGetStatUpdateFlags(fighter_gobj))
	ftHammerSetColAnim(fighter_gobj)

## 0x800F39AC
static func ftHammerCheckGotoHammerWait(fighter_gobj) -> int:
	if B(Ftcommonwait.ftCommonWaitCheckInputSuccess(fighter_gobj)):
		ftHammerSetStatusHammerWait(fighter_gobj)

		return TRUE
	else:
		return FALSE
