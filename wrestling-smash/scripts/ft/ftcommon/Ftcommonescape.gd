## 1:1 port of src/ft/ftcommon/ftcommonescape.c (ssb-decomp-re): EscapeF / EscapeB (rolls).
class_name Ftcommonescape
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801491D0
static func ftCommonEscapeProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 != 0:
		fp.motion_vars.flags.flag1 = 0
		fp.lr = -fp.lr
	if fighter_gobj.anim_frame <= 0.0:
		# fp->physics.vel_air.x = fp->physics.vel_air.y = fp->physics.vel_air.z = 0.0F;
		fp.physics.vel_air = Vector3(0.0, 0.0, 0.0)
		# fp->physics.vel_ground.x = fp->physics.vel_ground.y = fp->physics.vel_ground.z = 0.0F;
		fp.physics.vel_ground = Vector3(0.0, 0.0, 0.0)

		# C: (fkind != Yoshi) && (fkind != NYoshi) || (ftCommonGuardCheckInterruptEscape(fighter_gobj) == FALSE)
		if ((fp.fkind != nFTKindYoshi) and (fp.fkind != nFTKindNYoshi)) or (not Ftcommonguard2.ftCommonGuardCheckInterruptEscape(fighter_gobj)):
			Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)

## 0x80149268
static func ftCommonEscapeProcInterrupt(fighter_gobj) -> void:
	Ftcommonitemthrow.ftCommonLightThrowCheckInterruptEscape(fighter_gobj)

## 0x80149288
static func ftCommonEscapeProcStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag1 = 0

## 0x80149294
static func ftCommonEscapeSetStatus(fighter_gobj, status_id: int, itemthrow_buffer_tics: int) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_status = Callable(Ftcommonescape, &"ftCommonEscapeProcStatus")

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.is_jostle_ignore = TRUE

	fp.status_vars.common.escape.itemthrow_buffer_tics = itemthrow_buffer_tics

## 0x801492F8
static func ftCommonEscapeGetStatus(fp: Fighter) -> int:
	if (ABS(fp.input.pl.stick_range.x) >= FTCOMMON_ESCAPE_STICK_RANGE_MIN) and (fp.tap_stick_x < FTCOMMON_ESCAPE_BUFFER_TICS_MAX):
		return nFTCommonStatusEscapeF if ((fp.input.pl.stick_range.x * fp.lr) >= 0) else nFTCommonStatusEscapeB
	else:
		return -1

## 0x8014935C
static func ftCommonEscapeCheckInterruptSpecialNDonkey(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int = ftCommonEscapeGetStatus(fp)

	if status_id != -1:
		ftCommonEscapeSetStatus(fighter_gobj, status_id, 0)

		return TRUE
	else:
		return FALSE

## 0x801493A4
static func ftCommonEscapeCheckInterruptDash(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if fp.input.pl.button_tap & fp.input.button_mask_z:
		ftCommonEscapeSetStatus(fighter_gobj, nFTCommonStatusEscapeF, 0)

		return TRUE
	else:
		return FALSE

## 0x801493EC
static func ftCommonEscapeCheckInterruptGuard(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int = ftCommonEscapeGetStatus(fp)

	if status_id != -1:
		ftCommonEscapeSetStatus(fighter_gobj, status_id, 5)

		return TRUE
	else:
		return FALSE
