## 1:1 port of src/ft/ftcommon/ftcommonpass.c (ssb-decomp-re): Pass / GuardPass (drop through platforms).
class_name Ftcommonpass
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80141D60
static func ftCommonPassProcInterrupt(fighter_gobj) -> void:
	if (not Ftcommonspecialair.ftCommonSpecialAirCheckInterruptCommon(fighter_gobj)) and (not Ftcommonattackair.ftCommonAttackAirCheckInterruptCommon(fighter_gobj)):
		Ftcommonjumpaerial.ftCommonJumpAerialCheckInterruptCommon(fighter_gobj)

## 0x80141DA0
static func ftCommonPassSetStatusParam(fighter_gobj, status_id: int, frame_begin: float, flags: int) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, status_id, frame_begin, 1.0, flags)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

	fp.physics.vel_air.y = 0.0

	fp.coll_data.ignore_line_id = fp.coll_data.floor_line_id

	fp.tap_stick_y = FTINPUT_STICKBUFFER_TICS_MAX

## 0x80141E18
static func ftCommonPassSetStatusSquat(fighter_gobj) -> void:
	Ftcommonsquat.ftCommonSquatSetStatusPass(fighter_gobj)

## 0x80141E38
static func ftCommonGuardPassSetStatus(fighter_gobj) -> void:
	ftCommonPassSetStatusParam(fighter_gobj, nFTCommonStatusGuardPass, 1.0, FTSTATUS_PRESERVE_NONE)

## 0x80141E60
static func ftCommonPassCheckInputSuccess(fp: Fighter) -> int:
	if (fp.input.pl.stick_range.y <= FTCOMMON_PASS_STICK_RANGE_MIN) and (fp.tap_stick_y < FTCOMMON_PASS_BUFFER_TICS_MAX) and (fp.coll_data.floor_flags & MAP_VERTEX_COLL_PASS):
		return TRUE
	else:
		return FALSE

## 0x80141EA4
static func ftCommonPassCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if Fthammer.ftHammerCheckHoldHammer(fighter_gobj):
		return Ftcommonhammerfall.ftCommonHammerFallCheckInterruptCommon(fighter_gobj)
	elif ftCommonPassCheckInputSuccess(fp) != FALSE:
		ftCommonPassSetStatusSquat(fighter_gobj)

		return TRUE
	else:
		return FALSE

## 0x80141F0C
static func ftCommonPassCheckInterruptSquat(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if Fthammer.ftHammerCheckHoldHammer(fighter_gobj):
		return Ftcommonhammerfall.ftCommonHammerFallCheckInterruptCommon(fighter_gobj)
	if fp.status_vars.common.squat.is_allow_pass == FALSE:
		if ftCommonPassCheckInputSuccess(fp) != FALSE:
			fp.status_vars.common.squat.is_allow_pass = TRUE
			fp.status_vars.common.squat.pass_wait = FTCOMMON_SQUAT_PASS_WAIT

			return TRUE
	return FALSE

## 0x80141F8C
static func ftCommonGuardPassCheckInterruptGuard(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if (ftCommonPassCheckInputSuccess(fp) != FALSE) and (fp.input.pl.button_hold & fp.input.button_mask_z):
		ftCommonGuardPassSetStatus(fighter_gobj)

		return TRUE
	else:
		return FALSE
