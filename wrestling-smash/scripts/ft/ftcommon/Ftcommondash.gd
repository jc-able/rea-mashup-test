## 1:1 port of src/ft/ftcommon/ftcommondash.c (ssb-decomp-re): Dash status.
class_name Ftcommondash
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8013EA40
static func ftCommonDashProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fighter_gobj.anim_frame <= 0.0:
		fp.physics.vel_ground.x *= 0.75

		Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)

## 0x8013EA90
static func ftCommonDashProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var goto_next := false   # C: goto next;

	if (fp.motion_vars.flags.flag1 != 0) and (fighter_gobj.anim_frame <= 5.0):
		if (
			(not Ftcommonspecialn.ftCommonSpecialNCheckInterruptCommon(fighter_gobj)) and
			(not Ftcommoncatch1.ftCommonCatchCheckInterruptCommon(fighter_gobj)) and
			(not Ftcommonattacks4.ftCommonAttackS4CheckInterruptDash(fighter_gobj))
		):
			if (fighter_gobj.anim_frame <= 3.0) and Ftcommonescape.ftCommonEscapeCheckInterruptDash(fighter_gobj):
				return
			elif Ftcommonguard1.ftCommonGuardOnCheckInterruptCommon(fighter_gobj): # Jump interrupt?
				return
			else:
				goto_next = true
	elif fighter_gobj.anim_frame <= 20.0:
		if not Ftcommonspecialn.ftCommonSpecialNCheckInterruptCommon(fighter_gobj):
			if not Ftcommoncatch1.ftCommonCatchCheckInterruptDashRun(fighter_gobj):
				if (
					(not Ftcommonattackdash.ftCommonAttackDashCheckInterruptCommon(fighter_gobj)) and
					(
						((fp.input.pl.stick_range.x * fp.lr) >= 0) or (not ftCommonDashCheckInterruptCommon(fighter_gobj))
					)
				):
					# s32 slide_tics parameter: (s32)(20.0F - anim_frame)
					if Ftcommonguard1.ftCommonGuardOnCheckInterruptDashRun(fighter_gobj, int(20.0 - fighter_gobj.anim_frame)):
						return
					else:
						goto_next = true
	elif (
		(not Ftcommoncatch1.ftCommonCatchCheckInterruptCommon(fighter_gobj)) and
		(not ftCommonDashCheckInterruptCommon(fighter_gobj)) and
		(not Ftcommonguard1.ftCommonGuardOnCheckInterruptCommon(fighter_gobj))
	):
		goto_next = true

	if goto_next:
		# next:
		if (not Ftcommonappeal.ftCommonAppealCheckInterruptCommon(fighter_gobj)) and (not Ftcommonkneebend.ftCommonKneeBendCheckInterruptRun(fighter_gobj)):
			Ftcommonrun.ftCommonRunCheckInterruptDash(fighter_gobj)

## 0x8013EC58
static func ftCommonDashProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if fighter_gobj.anim_frame >= FTCOMMON_DASH_DECELERATE_BEGIN:
		Ftphysics.ftPhysicsSetGroundVelFriction(fp, attr.dash_decel)
	Ftphysics.ftPhysicsSetGroundVelTransferAir(fighter_gobj)

## 0x8013ECB0
static func ftCommonDashProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if attr.dash_to_run <= fighter_gobj.anim_frame:
		Mpcommon.mpCommonProcFighterOnCliffEdge(fighter_gobj)
	else:
		Mpcommon.mpCommonSetFighterFallOnGroundBreak(fighter_gobj)

## 0x8013ED00
static func ftCommonDashSetStatus(fighter_gobj, flag: int) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusDash, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.physics.vel_ground.x = fp.attr.dash_speed
	fp.tap_stick_x = FTINPUT_STICKBUFFER_TICS_MAX
	fp.motion_vars.flags.flag1 = flag

## 0x8013ED64
static func ftCommonDashCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if (ABS(fp.input.pl.stick_range.x) >= FTCOMMON_DASH_STICK_RANGE_MIN) and (fp.tap_stick_x < FTCOMMON_DASH_BUFFER_TICS_MAX):
		if (fp.input.pl.stick_range.x * fp.lr) < 0:
			Ftcommonturn.ftCommonTurnSetStatusInvertLR(fighter_gobj)

			return TRUE
		Ftparam.ftParamSetStickLR(fp)
		ftCommonDashSetStatus(fighter_gobj, 1)

		return TRUE
	return FALSE

## 0x8013EDFC
static func ftCommonDashCheckTurn(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if ((fp.input.pl.stick_range.x * fp.status_vars.common.turn.lr_turn) >= FTCOMMON_DASH_STICK_RANGE_MIN) and (fp.tap_stick_x < FTCOMMON_DASH_BUFFER_TICS_MAX):
		fp.status_vars.common.turn.lr_dash = fp.status_vars.common.turn.lr_turn
		fp.status_vars.common.turn.attacks4_buffer = 0

		return TRUE
	else:
		return FALSE
