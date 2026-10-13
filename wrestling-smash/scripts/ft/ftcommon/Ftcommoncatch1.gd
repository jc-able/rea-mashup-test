## 1:1 port of src/ft/ftcommon/ftcommoncatch1.c (ssb-decomp-re): grab start (Catch) status and
## the grab / item-throw interrupt checks used by ground statuses.
class_name Ftcommoncatch1
extends Port

## C stores the catch-pull countdown in f32 variables; round like the original so the frame on
## which it reaches 0 (and the CatchPull start frame) matches exactly.
static func _f32(x: float) -> float:
	return Vector2(x, 0.0).x

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80149A10
static func ftCommonCatchProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.common.catchmain.catch_pull_frame_begin > 0.0:
		fp.status_vars.common.catchmain.catch_pull_frame_begin = _f32(fp.status_vars.common.catchmain.catch_pull_frame_begin - fp.status_vars.common.catchmain.catch_pull_anim_frames)

		if fp.status_vars.common.catchmain.catch_pull_frame_begin <= 0.0:
			fp.status_vars.common.catchmain.catch_pull_frame_begin = 0.0
	if fp.motion_vars.flags.flag2 != 0:
		# u32 -> f32
		fp.status_vars.common.catchmain.catch_pull_frame_begin = _f32(float(fp.motion_vars.flags.flag2 & 0xFFFFFFFF))

		# f32 / u32
		fp.status_vars.common.catchmain.catch_pull_anim_frames = _f32(fp.status_vars.common.catchmain.catch_pull_frame_begin / float(fp.motion_vars.flags.flag1 & 0xFFFFFFFF))

		fp.motion_vars.flags.flag2 = 0
	Ftanimend.ftAnimEndSetWait(fighter_gobj)

## 0x80149AC8
static func ftCommonCatchCaptureSetStatusRelease(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var catch_fp: Fighter
	var catch_gobj

	Ftcommonfall.ftCommonFallSetStatus(fighter_gobj)

	catch_gobj = this_fp.catch_gobj

	if catch_gobj != null:
		catch_fp = ftGetStruct(catch_gobj)

		Ftcommonthrown2.ftCommonThrownReleaseFighterLoseGrip(catch_gobj)

		if catch_fp.ga == nMPKineticsGround:
			Ftcommonwait.ftCommonWaitSetStatus(catch_gobj)
		else:
			Ftcommonfall.ftCommonFallSetStatus(catch_gobj)

		catch_fp.capture_gobj = null
		this_fp.catch_gobj = null

## 0x80149B48
static func func_ovl3_80149B48(fighter_gobj) -> void: # Unused
	if not B(Mpcommon.mpCommonCheckFighterOnFloor(fighter_gobj)):
		ftCommonCatchCaptureSetStatusRelease(fighter_gobj)

## 0x80149B78
static func ftCommonCatchProcMap(fighter_gobj) -> void:
	if not B(Mpcommon.mpCommonCheckFighterOnEdge(fighter_gobj)):
		ftCommonCatchCaptureSetStatusRelease(fighter_gobj)

## 0x80149BA8
static func ftCommonCatchSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCatch, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.motion_vars.flags.flag1 = 1
	fp.motion_vars.flags.flag2 = 0

	fp.status_vars.common.catchmain.catch_pull_anim_frames = 0.0
	fp.status_vars.common.catchmain.catch_pull_frame_begin = 0.0

	Ftparam.ftParamSetCatchParams(fp, FTCATCHKIND_MASK_COMMON, Callable(Ftcommoncatch2, &"ftCommonCatchPullProcCatch"), Callable(Ftcommoncapturepulled, &"ftCommonCapturePulledProcCapture"))

	fp.is_shield_catch = FALSE

	if ((fp.fkind == nFTKindSamus) or (fp.fkind == nFTKindNSamus)) and (Efmanager.efManagerSamusGrappleBeamGlowMakeEffect(fighter_gobj) != null):
		fp.is_effect_attach = TRUE

## 0x80149C60
static func ftCommonCatchCheckInterruptGuard(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr
	var is_shield_catch = fp.status_vars.common.guard.is_setoff

	if (fp.input.pl.button_tap & fp.input.button_mask_a) and B(attr.is_have_catch):
		ftCommonCatchSetStatus(fighter_gobj)

		# ub32 is_shield_catch : 1
		fp.is_shield_catch = int(is_shield_catch) & 1

		return TRUE
	else:
		return FALSE

## 0x80149CE0
static func ftCommonCatchCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if B(Ftcommonitemthrow.ftCommonLightThrowCheckItemTypeThrow(fp)):
		Ftcommonitemthrow.ftCommonLightThrowDecideSetStatus(fighter_gobj)

		return TRUE
	elif (fp.input.pl.button_hold & fp.input.button_mask_z) and (fp.input.pl.button_tap & fp.input.button_mask_a) and B(attr.is_have_catch):
		ftCommonCatchSetStatus(fighter_gobj)

		return TRUE
	else:
		return FALSE

## 0x80149D80
static func ftCommonCatchCheckInterruptDashRun(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if B(Ftcommonitemthrow.ftCommonLightThrowCheckItemTypeThrow(fp)):
		Ftcommonitemthrow.ftCommonItemThrowSetStatus(fighter_gobj, nFTCommonStatusLightThrowDash)

		return TRUE
	elif (fp.input.pl.button_hold & fp.input.button_mask_z) and (fp.input.pl.button_tap & fp.input.button_mask_a) and B(attr.is_have_catch):
		ftCommonCatchSetStatus(fighter_gobj)

		return TRUE
	else:
		return FALSE

## 0x80149E24
static func ftCommonCatchCheckInterruptAttack11(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if B(Ftcommonitemthrow.ftCommonLightThrowCheckItemTypeThrow(fp)):
		Ftcommonitemthrow.ftCommonItemThrowSetStatus(fighter_gobj, nFTCommonStatusLightThrowDash)

		return TRUE
	elif (fp.input.pl.button_tap & fp.input.button_mask_z) and B(attr.is_have_catch):
		ftCommonCatchSetStatus(fighter_gobj)

		return TRUE
	else:
		return FALSE
