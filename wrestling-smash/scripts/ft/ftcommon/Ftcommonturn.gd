## 1:1 port of src/ft/ftcommon/ftcommonturn.c (ssb-decomp-re): standing Turn status.
class_name Ftcommonturn
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8013E690
static func ftCommonTurnProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 != 0:
		fp.motion_vars.flags.flag1 = 0

		fp.status_vars.common.turn.is_allow_turn_direction = TRUE
		fp.status_vars.common.turn.is_disable_sa_interrupts = TRUE

		fp.lr = -fp.lr
		fp.physics.vel_ground.x = -fp.physics.vel_ground.x
	if fighter_gobj.anim_frame <= 0.0:
		Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)

## "Dawg what" (no address comment in the decomp; between 0x8013E690 and 0x8013E908)
static func ftCommonTurnProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var is_interrupt_attacks4

	if fp.status_vars.common.turn.is_allow_turn_direction != FALSE:
		fp.input.pl.button_tap |= fp.status_vars.common.turn.button_mask

	# if (is_disable_sa_interrupts == FALSE) goto skip_interrupt_specials;
	if fp.status_vars.common.turn.is_disable_sa_interrupts != FALSE:
		if Ftcommonspecialn.ftCommonSpecialNCheckInterruptCommon(fighter_gobj): return
		if Ftcommonspecialhi.ftCommonSpecialHiCheckInterruptCommon(fighter_gobj): return
		if Ftcommonspeciallw.ftCommonSpecialLwCheckInterruptCommon(fighter_gobj): return

	# skip_interrupt_specials:
	if not Ftcommoncatch1.ftCommonCatchCheckInterruptCommon(fighter_gobj):
		if fp.status_vars.common.turn.attacks4_buffer < 256:
			fp.status_vars.common.turn.attacks4_buffer += 1
		is_interrupt_attacks4 = Ftcommonattacks4.ftCommonAttackS4CheckInterruptTurn(fighter_gobj) if (fp.status_vars.common.turn.attacks4_buffer < 6) else Ftcommonattacks4.ftCommonAttackS4CheckInterruptCommon(fighter_gobj)

		if not is_interrupt_attacks4:
			# if (is_disable_sa_interrupts == FALSE) goto skip_interrupt_attacks;
			if fp.status_vars.common.turn.is_disable_sa_interrupts != FALSE:
				if Ftcommonattackhi4.ftCommonAttackHi4CheckInterruptCommon(fighter_gobj): return
				if Ftcommonattacklw4.ftCommonAttackLw4CheckInterruptCommon(fighter_gobj): return
				if Ftcommonattacks3.ftCommonAttackS3CheckInterruptCommon(fighter_gobj): return
				if Ftcommonattackhi3.ftCommonAttackHi3CheckInterruptCommon(fighter_gobj): return
				if Ftcommonattacklw3.ftCommonAttackLw3CheckInterruptCommon(fighter_gobj): return
				if Ftcommonattack1.ftCommonAttack1CheckInterruptCommon(fighter_gobj): return

			# skip_interrupt_attacks:
			if (
				Ftcommonguard1.ftCommonGuardOnCheckInterruptCommon(fighter_gobj) or
				Ftcommonappeal.ftCommonAppealCheckInterruptCommon(fighter_gobj) or
				Ftcommonkneebend.ftCommonKneeBendCheckInterruptCommon(fighter_gobj)
			):
				return
			Ftcommondash.ftCommonDashCheckTurn(fighter_gobj)

			if fp.status_vars.common.turn.is_allow_turn_direction != FALSE:
				if fp.status_vars.common.turn.lr_dash != 0:
					if (fp.input.pl.stick_range.x * fp.status_vars.common.turn.lr_turn) >= FTCOMMON_DASH_STICK_RANGE_MIN:
						Ftcommondash.ftCommonDashSetStatus(fighter_gobj, 0)
			# NOTE: as in C, the following still runs (and writes the turn status vars) even if Dash was just entered.
			if fp.input.pl.button_tap & fp.input.button_mask_a:
				fp.status_vars.common.turn.button_mask |= fp.input.button_mask_a
			if fp.input.pl.button_tap & fp.input.button_mask_b:
				fp.status_vars.common.turn.button_mask |= fp.input.button_mask_b
			if fp.status_vars.common.turn.is_allow_turn_direction != FALSE:
				fp.status_vars.common.turn.is_allow_turn_direction = FALSE

## 0x8013E908
static func ftCommonTurnSetStatus(fighter_gobj, lr_dash: int) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag1 = 0

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusTurn, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.status_vars.common.turn.is_allow_turn_direction = FALSE
	fp.status_vars.common.turn.is_disable_sa_interrupts = FALSE
	fp.status_vars.common.turn.button_mask = 0
	fp.status_vars.common.turn.lr_dash = lr_dash
	fp.status_vars.common.turn.attacks4_buffer = 0 if (lr_dash != 0) else 256
	fp.status_vars.common.turn.lr_turn = -fp.lr

## 0x8013E988
static func ftCommonTurnSetStatusCenter(fighter_gobj) -> void:
	ftCommonTurnSetStatus(fighter_gobj, 0)

## 0x8013E9A8
static func ftCommonTurnSetStatusInvertLR(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftCommonTurnSetStatus(fighter_gobj, -fp.lr)

## 0x8013ED90
static func ftCommonTurnCheckInputSuccess(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.input.pl.stick_range.x * fp.lr) <= FTCOMMON_TURN_STICK_RANGE_MIN:
		return TRUE
	else:
		return FALSE

## 0x8013EA04
static func ftCommonTurnCheckInterruptCommon(fighter_gobj) -> int:
	if ftCommonTurnCheckInputSuccess(fighter_gobj) != FALSE:
		ftCommonTurnSetStatusCenter(fighter_gobj)

		return TRUE
	else:
		return FALSE
