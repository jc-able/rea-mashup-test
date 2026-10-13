## 1:1 port of src/ft/ftcommon/ftcommonsquat.c (ssb-decomp-re): Squat / SquatWait / SquatRv.
class_name Ftcommonsquat
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

## ftCommonSquatCheckInterrupt (macro in ftcommonsquat.c): short-circuit || chain, exact C order.
static func ftCommonSquatCheckInterrupt(fighter_gobj) -> bool:
	return (
		Ftcommonspecialn.ftCommonSpecialNCheckInterruptCommon(fighter_gobj) or
		Ftcommonspecialhi.ftCommonSpecialHiCheckInterruptCommon(fighter_gobj) or
		Ftcommonspeciallw.ftCommonSpecialLwCheckInterruptCommon(fighter_gobj) or
		Ftcommoncatch1.ftCommonCatchCheckInterruptCommon(fighter_gobj) or
		Ftcommonattacks4.ftCommonAttackS4CheckInterruptCommon(fighter_gobj) or
		Ftcommonattackhi4.ftCommonAttackHi4CheckInterruptCommon(fighter_gobj) or
		Ftcommonattacklw4.ftCommonAttackLw4CheckInterruptSquat(fighter_gobj) or
		Ftcommonattacks3.ftCommonAttackS3CheckInterruptCommon(fighter_gobj) or
		Ftcommonattackhi3.ftCommonAttackHi3CheckInterruptCommon(fighter_gobj) or
		Ftcommonattacklw3.ftCommonAttackLw3CheckInterruptCommon(fighter_gobj) or
		Ftcommonattack1.ftCommonAttack1CheckInterruptCommon(fighter_gobj) or
		Ftcommonguard1.ftCommonGuardOnCheckInterruptCommon(fighter_gobj) or
		Ftcommonappeal.ftCommonAppealCheckInterruptCommon(fighter_gobj) or
		Ftcommonkneebend.ftCommonKneeBendCheckInterruptCommon(fighter_gobj) or
		Ftcommonpass.ftCommonPassCheckInterruptSquat(fighter_gobj) or
		Ftcommondokan.ftCommonDokanStartCheckInterruptCommon(fighter_gobj)
	)

## ftCommonSquatWaitCheckInterrupt (macro in ftcommonsquat.c): short-circuit || chain, exact C order.
static func ftCommonSquatWaitCheckInterrupt(fighter_gobj) -> bool:
	return (
		Ftcommonspecialn.ftCommonSpecialNCheckInterruptCommon(fighter_gobj) or
		Ftcommonspecialhi.ftCommonSpecialHiCheckInterruptCommon(fighter_gobj) or
		Ftcommonspeciallw.ftCommonSpecialLwCheckInterruptCommon(fighter_gobj) or
		Ftcommoncatch1.ftCommonCatchCheckInterruptCommon(fighter_gobj) or
		Ftcommonattacks4.ftCommonAttackS4CheckInterruptCommon(fighter_gobj) or
		Ftcommonattackhi4.ftCommonAttackHi4CheckInterruptCommon(fighter_gobj) or
		Ftcommonattacklw4.ftCommonAttackLw4CheckInterruptSquat(fighter_gobj) or
		Ftcommonattacks3.ftCommonAttackS3CheckInterruptCommon(fighter_gobj) or
		Ftcommonattackhi3.ftCommonAttackHi3CheckInterruptCommon(fighter_gobj) or
		Ftcommonattacklw3.ftCommonAttackLw3CheckInterruptCommon(fighter_gobj) or
		Ftcommonattack1.ftCommonAttack1CheckInterruptCommon(fighter_gobj) or
		Ftcommonguard1.ftCommonGuardOnCheckInterruptCommon(fighter_gobj) or
		Ftcommonappeal.ftCommonAppealCheckInterruptCommon(fighter_gobj) or
		Ftcommonkneebend.ftCommonKneeBendCheckInterruptCommon(fighter_gobj) or
		Ftcommondash.ftCommonDashCheckInterruptCommon(fighter_gobj) or
		Ftcommonpass.ftCommonPassCheckInterruptSquat(fighter_gobj) or
		Ftcommondokan.ftCommonDokanStartCheckInterruptCommon(fighter_gobj) or
		ftCommonSquatRvCheckInterruptSquatWait(fighter_gobj)
	)

## ftCommonSquatRvCheckInterrupt (macro in ftcommonsquat.c): short-circuit || chain, exact C order.
static func ftCommonSquatRvCheckInterrupt(fighter_gobj) -> bool:
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

## 0x80142E70
static func ftCommonSquatCheckGotoPass(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.common.squat.is_allow_pass != FALSE:
		if fp.status_vars.common.squat.pass_wait != 0:
			fp.status_vars.common.squat.pass_wait -= 1

			if fp.status_vars.common.squat.pass_wait == 0:
				Ftcommonpass.ftCommonPassSetStatusParam(fighter_gobj, nFTCommonStatusPass, 1.0, 0)

				return TRUE
	if fp.status_vars.common.squat.unk_0x8 != 0:
		fp.status_vars.common.squat.unk_0x8 -= 1
	return FALSE

## 0x80142ED8
static func ftCommonSquatProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommonsquat, &"ftCommonSquatWaitSetStatus"))

## 0x80142EFC
static func ftCommonSquatProcInterrupt(fighter_gobj) -> void:
	if not ftCommonSquatCheckInterrupt(fighter_gobj):
		ftCommonSquatCheckGotoPass(fighter_gobj)

## 0x80143024
static func ftCommonSquatSetStatusNoPass(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusSquat, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.is_special_interrupt = TRUE

	fp.status_vars.common.squat.is_allow_pass = FALSE
	fp.status_vars.common.squat.pass_wait = 0

	if (fp.input.pl.stick_range.y <= FTCOMMON_SQUAT_STICK_RANGE_MIN) and (fp.tap_stick_y < FTCOMMON_SQUAT_BUFFER_TICS_MAX):
		fp.status_vars.common.squat.unk_0x8 = 3
	else:
		fp.status_vars.common.squat.unk_0x8 = 0

## 0x801430A8
static func ftCommonSquatSetStatusPass(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusSquat, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.is_special_interrupt = TRUE

	fp.status_vars.common.squat.is_allow_pass = TRUE
	fp.status_vars.common.squat.pass_wait = FTCOMMON_SQUAT_PASS_WAIT
	fp.status_vars.common.squat.unk_0x8 = 3

## 0x8014310C
static func ftCommonSquatCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if fp.input.pl.stick_range.y <= (FTCOMMON_SQUAT_STICK_RANGE_MIN - 2):
		ftCommonSquatSetStatusNoPass(fighter_gobj)

		return TRUE
	else:
		return FALSE

## 0x8014314C
static func ftCommonSquatWaitProcUpdate(fighter_gobj) -> void:
	return

## 0x80143154
static func ftCommonSquatWaitProcInterrupt(fighter_gobj) -> void:
	if not ftCommonSquatWaitCheckInterrupt(fighter_gobj):
		ftCommonSquatCheckGotoPass(fighter_gobj)

## 0x8014329C
static func ftCommonSquatWaitSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	# PORT (C union aliasing): this function does not initialise the squat vars. Its callers are Squat's and
	# AttackLw3's anim end; after AttackLw3 the C union word read as squat.is_allow_pass (offset 0) is
	# attacklw3.is_goto_attacklw3, so mirror it here (the port keeps each union view in its own Dictionary).
	# pass_wait / unk_0x8 (offsets 4 / 8) would be stale words of older views and keep the last squat values.
	if fp.status_id == nFTCommonStatusAttackLw3:
		fp.status_vars.common.squat.is_allow_pass = fp.status_vars.common.attacklw3.is_goto_attacklw3

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusSquatWait, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.is_special_interrupt = TRUE

	Ftparam.ftParamSetPlayerTagWait(fighter_gobj, 120)

## 0x801432F0
static func ftCommonSquatWaitSetStatusNoPass(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusSquatWait, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.is_special_interrupt = TRUE

	Ftparam.ftParamSetPlayerTagWait(fighter_gobj, 120)

	fp.status_vars.common.squat.is_allow_pass = FALSE
	fp.status_vars.common.squat.unk_0x8 = 0
	fp.status_vars.common.squat.pass_wait = 0

## 0x80143354
static func ftCommonSquatWaitCheckInterruptLanding(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if fp.input.pl.stick_range.y <= (FTCOMMON_SQUAT_STICK_RANGE_MIN - 2):
		ftCommonSquatWaitSetStatusNoPass(fighter_gobj)

		return TRUE
	else:
		return FALSE

## 0x80143394
static func ftCommonSquatRvProcInterrupt(fighter_gobj) -> void:
	if not ftCommonSquatRvCheckInterrupt(fighter_gobj):
		Ftcommonwalk.ftCommonWalkCheckInterruptCommon(fighter_gobj)

## 0x801434CC
static func ftCommonSquatRvSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusSquatRv, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.is_special_interrupt = TRUE

## 0x8014351C
static func ftCommonSquatRvCheckInterruptSquatWait(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if fp.input.pl.stick_range.y >= (FTCOMMON_SQUAT_STICK_RANGE_MIN + 4):
		ftCommonSquatRvSetStatus(fighter_gobj)

		return TRUE
	else:
		return FALSE
