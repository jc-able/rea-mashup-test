## 1:1 port of src/ft/ftcommon/ftcommonjump.c (ssb-decomp-re): grounded JumpF / JumpB.
class_name Ftcommonjump
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8013F660
static func ftCommonJumpProcInterrupt(fighter_gobj) -> void:
	if (not Ftcommonspecialair.ftCommonSpecialAirCheckInterruptCommon(fighter_gobj)) and (not Ftcommonattackair.ftCommonAttackAirCheckInterruptCommon(fighter_gobj)):
		Ftcommonjumpaerial.ftCommonJumpAerialCheckInterruptCommon(fighter_gobj)

## 0x8013F6A0
## C: void ftCommonJumpGetJumpForceButton(s32 stick_range_x, s32 *jump_vel_x, s32 *jump_vel_y, sb32 is_shorthop)
## jump_vel_x / jump_vel_y are pure outputs -> returns {"jump_vel_x": s32, "jump_vel_y": s32}.
static func ftCommonJumpGetJumpForceButton(stick_range_x: int, is_shorthop: int) -> Dictionary:
	var sqrt_vel_x: float
	var vel_y: float
	var vel_x: float

	vel_x = ABS(stick_range_x)

	sqrt_vel_x = sqrtf(1.0 - SQUARE(vel_x / float(F_CONTROLLER_RANGE_MAX)))

	if is_shorthop == FALSE:
		vel_y = (FTCOMMON_KNEEBEND_BUTTON_LONG_FORCE * sqrt_vel_x) + FTCOMMON_KNEEBEND_BUTTON_LONG_MIN

		if (SQUARE(vel_x) + SQUARE(vel_y)) > SQUARE(float(F_CONTROLLER_RANGE_MAX)):
			vel_y = sqrtf(SQUARE(float(F_CONTROLLER_RANGE_MAX)) - SQUARE(vel_x))
		if vel_y < FTCOMMON_KNEEBEND_BUTTON_LONG_MIN:
			vel_y = FTCOMMON_KNEEBEND_BUTTON_LONG_MIN
	else:
		vel_y = (FTCOMMON_KNEEBEND_BUTTON_SHORT_FORCE * sqrt_vel_x) + FTCOMMON_KNEEBEND_BUTTON_SHORT_MIN

		if (SQUARE(vel_x) + SQUARE(vel_y)) > SQUARE(float(F_CONTROLLER_RANGE_MAX)):
			vel_y = sqrtf(SQUARE(float(F_CONTROLLER_RANGE_MAX)) - SQUARE(vel_x))
		if vel_y < FTCOMMON_KNEEBEND_BUTTON_SHORT_MIN:
			vel_y = FTCOMMON_KNEEBEND_BUTTON_SHORT_MIN
	if vel_y > FTCOMMON_KNEEBEND_BUTTON_HEIGHT_CLAMP:
		vel_y = FTCOMMON_KNEEBEND_BUTTON_HEIGHT_CLAMP

	# f32 -> s32 conversions (truncation toward zero)
	var jump_vel_x: int = int(vel_x if (stick_range_x >= 0) else -vel_x)
	var jump_vel_y: int = int(vel_y)

	return {"jump_vel_x": jump_vel_x, "jump_vel_y": jump_vel_y}

## 0x8013F880
static func ftCommonJumpSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr
	var status_id: int
	var vel_x: int
	var vel_y: int

	Mpcommon.mpCommonSetFighterAir(fp)

	status_id = nFTCommonStatusJumpF if ((fp.input.pl.stick_range.x * fp.lr) > FTCOMMON_KNEEBEND_JUMP_F_OR_B_RANGE) else nFTCommonStatusJumpB

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	# The KneeBend status vars are still intact here: ftMainSetStatus does not touch status_vars.
	match fp.status_vars.common.kneebend.input_source:
		FTCOMMON_KNEEBEND_INPUT_TYPE_BUTTON:
			var r: Dictionary = ftCommonJumpGetJumpForceButton(fp.input.pl.stick_range.x, fp.status_vars.common.kneebend.is_shorthop)
			vel_x = r.jump_vel_x
			vel_y = r.jump_vel_y

		_: # FTCOMMON_KNEEBEND_INPUT_TYPE_STICK, default
			vel_x = fp.input.pl.stick_range.x
			vel_y = int(fp.status_vars.common.kneebend.jump_force)   # f32 -> s32

			if vel_y < FTCOMMON_KNEEBEND_STICK_RANGE_MIN:
				vel_y = FTCOMMON_KNEEBEND_STICK_RANGE_MIN
	fp.physics.vel_air.y = (vel_y * attr.jump_height_mul) + attr.jump_height_base
	fp.physics.vel_air.x = vel_x * attr.jump_vel_x

	fp.tap_stick_y = FTINPUT_STICKBUFFER_TICS_MAX

	fp.is_special_interrupt = TRUE
