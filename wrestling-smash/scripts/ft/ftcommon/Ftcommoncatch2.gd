## 1:1 port of src/ft/ftcommon/ftcommoncatch2.c (ssb-decomp-re): CatchPull (grab connected,
## pulling the victim in) and CatchWait (holding the victim) statuses.
class_name Ftcommoncatch2
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x801886D0
static var dFTCommonCatchPullEffectOffset: Vector3 = Vector3(0.0, 0.0, 0.0)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80149EC0
static func ftCommonCatchPullProcUpdate(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)

	if B(Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommoncatch2, &"ftCommonCatchWaitSetStatus"))):
		var catch_fp := ftGetStruct(this_fp.catch_gobj)

		catch_fp.status_vars.common.capture.is_goto_pulled_wait = TRUE

## 0x80149F04
static func ftCommonCatchPullProcCatch(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCatchPull, fp.status_vars.common.catchmain.catch_pull_frame_begin, 1.0, (FTSTATUS_PRESERVE_SLOPECONTOUR | FTSTATUS_PRESERVE_EFFECT))

	fp.catch_gobj = fp.search_gobj

	fp.is_catch_or_capture = FALSE

	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

	if fp.proc_slope.is_valid():
		fp.proc_slope.call(fighter_gobj)
	pos = dFTCommonCatchPullEffectOffset

	pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[fp.attr.joint_itemheavy_id], pos)
	Efmanager.efManagerCatchSwirlMakeEffect(pos)
	Ftparam.ftParamMakeRumble(fp, 9, 0)

## 0x80149FCC
static func ftCommonCatchWaitProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.common.catchwait.throw_wait != 0:
		fp.status_vars.common.catchwait.throw_wait -= 1
	Ftcommonthrow.ftCommonThrowCheckInterruptCatchWait(fighter_gobj)

## 0x8014A000
static func ftCommonCatchWaitSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCatchWait, 0.0, 1.0, FTSTATUS_PRESERVE_SLOPECONTOUR)

	fp.status_vars.common.catchwait.throw_wait = FTCOMMON_CATCH_THROW_WAIT

	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

	if (fp.fkind == nFTKindLink) or (fp.fkind == nFTKindNLink):
		Ftparam.ftParamSetModelPartID(fighter_gobj, 21, 0)
		Ftparam.ftParamSetModelPartID(fighter_gobj, 19, -1)
	elif (fp.fkind == nFTKindYoshi) or (fp.fkind == nFTKindNYoshi):
		Ftparam.ftParamSetModelPartID(fighter_gobj, 7, 1)
