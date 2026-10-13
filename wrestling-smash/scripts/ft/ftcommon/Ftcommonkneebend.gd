## 1:1 port of src/ft/ftcommon/ftcommonkneebend.c (ssb-decomp-re): KneeBend (jump squat) and GuardKneeBend.
class_name Ftcommonkneebend
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8013F2A0
static func ftCommonKneeBendProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	fp.status_vars.common.kneebend.anim_frame += DObjGetStruct(fighter_gobj).anim_speed

	if (
		(fp.status_vars.common.kneebend.input_source == FTCOMMON_KNEEBEND_INPUT_TYPE_BUTTON) and
		(fp.status_vars.common.kneebend.anim_frame <= FTCOMMON_KNEEBEND_SHORTHOP_FRAMES) and
		(fp.input.pl.button_release & (R_CBUTTONS | L_CBUTTONS | D_CBUTTONS | U_CBUTTONS))
	):
		fp.status_vars.common.kneebend.is_shorthop = TRUE
	if attr.kneebend_anim_length <= fp.status_vars.common.kneebend.anim_frame:
		Ftcommonjump.ftCommonJumpSetStatus(fighter_gobj)

## 0x8013F334
static func ftCommonKneeBendProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if not Ftcommonspecialhi.ftCommonSpecialHiCheckInterruptCommon(fighter_gobj):
		if not Ftcommonattackhi4.ftCommonAttackHi4CheckInterruptKneeBend(fighter_gobj):
			if fp.status_vars.common.kneebend.jump_force < fp.input.pl.stick_range.y:
				fp.status_vars.common.kneebend.jump_force = float(fp.input.pl.stick_range.y)

## 0x8013F3A0
static func ftCommonKneeBendSetStatusParam(fighter_gobj, status_id: int, input_source: int) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.status_vars.common.kneebend.jump_force = float(fp.input.pl.stick_range.y)
	fp.status_vars.common.kneebend.anim_frame = 0.0
	fp.status_vars.common.kneebend.input_source = input_source
	fp.status_vars.common.kneebend.is_shorthop = FALSE

	fp.is_special_interrupt = TRUE

## 0x8013F408
static func ftCommonKneeBendSetStatus(fighter_gobj, input_source: int) -> void:
	ftCommonKneeBendSetStatusParam(fighter_gobj, nFTCommonStatusKneeBend, input_source)

## 0x8013F42C
static func ftCommonGuardKneeBendSetStatus(fighter_gobj, input_source: int) -> void:
	ftCommonKneeBendSetStatusParam(fighter_gobj, nFTCommonStatusGuardKneeBend, input_source)

## 0x8013F450
static func ftCommonKneeBendCheckButtonTap(fp: Fighter) -> int:
	if fp.input.pl.button_tap & (R_CBUTTONS | L_CBUTTONS | D_CBUTTONS | U_CBUTTONS):
		return TRUE
	else:
		return FALSE

## 0x8013F474
static func ftCommonKneeBendGetInputTypeCommon(fp: Fighter) -> int:
	if (fp.input.pl.stick_range.y >= FTCOMMON_KNEEBEND_STICK_RANGE_MIN) and (fp.tap_stick_y <= FTCOMMON_KNEEBEND_BUFFER_TICS_MAX):
		return FTCOMMON_KNEEBEND_INPUT_TYPE_STICK
	elif ftCommonKneeBendCheckButtonTap(fp) != FALSE:
		return FTCOMMON_KNEEBEND_INPUT_TYPE_BUTTON
	else:
		return FTCOMMON_KNEEBEND_INPUT_TYPE_NONE

## 0x8013F4D0
static func ftCommonKneeBendCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var input_source: int

	if Fthammer.ftHammerCheckHoldHammer(fighter_gobj):
		return Ftcommonhammerkneebend.ftCommonHammerKneeBendCheckInterruptCommon(fighter_gobj)
	input_source = ftCommonKneeBendGetInputTypeCommon(fp)

	if input_source != FTCOMMON_KNEEBEND_INPUT_TYPE_NONE:
		ftCommonKneeBendSetStatus(fighter_gobj, input_source)

		return TRUE
	else:
		return FALSE

## 0x8013F53C
static func ftCommonKneeBendGetInputTypeRun(fp: Fighter) -> int:
	if (fp.input.pl.stick_range.y > FTCOMMON_KNEEBEND_RUN_STICK_RANGE_MIN) and (fp.tap_stick_y <= FTCOMMON_KNEEBEND_BUFFER_TICS_MAX):
		return FTCOMMON_KNEEBEND_INPUT_TYPE_STICK
	elif ftCommonKneeBendCheckButtonTap(fp) != FALSE:
		return FTCOMMON_KNEEBEND_INPUT_TYPE_BUTTON
	else:
		return FTCOMMON_KNEEBEND_INPUT_TYPE_NONE

## 0x8013F598
static func ftCommonKneeBendCheckInterruptRun(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var input_source: int

	if Fthammer.ftHammerCheckHoldHammer(fighter_gobj):
		return Ftcommonhammerkneebend.ftCommonHammerKneeBendCheckInterruptCommon(fighter_gobj)
	input_source = ftCommonKneeBendGetInputTypeRun(fp)

	if input_source != FTCOMMON_KNEEBEND_INPUT_TYPE_NONE:
		ftCommonKneeBendSetStatus(fighter_gobj, input_source)

		return TRUE
	else:
		return FALSE

## 0x8013F604
static func ftCommonGuardKneeBendCheckInterruptGuard(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var input_source: int = ftCommonKneeBendGetInputTypeCommon(fp)

	if (input_source != FTCOMMON_KNEEBEND_INPUT_TYPE_NONE) and (fp.input.pl.button_hold & fp.input.button_mask_z):
		ftCommonGuardKneeBendSetStatus(fighter_gobj, input_source)

		return TRUE
	else:
		return FALSE
