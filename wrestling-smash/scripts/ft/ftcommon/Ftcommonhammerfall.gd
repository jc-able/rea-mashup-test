## 1:1 port of src/ft/ftcommon/ftcommonhammerfall.c (ssb-decomp-re): HammerFall (airborne with the Hammer).
class_name Ftcommonhammerfall
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80147BE0
static func ftCommonHammerFallProcInterrupt(fighter_gobj) -> void:
	return

## 0x80147BE8
static func ftCommonHammerFallProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if B(Mpcommon.mpCommonCheckFighterLanding(fighter_gobj)):
		if fp.physics.vel_air.y > FTCOMMON_HAMMER_SKIPLANDING_VEL_Y_MAX:
			Fthammer.ftHammerSetStatusHammerWait(fighter_gobj)
		else:
			Ftcommonhammerlanding.ftCommonHammerLandingSetStatus(fighter_gobj)

## 0x80147C50
static func ftCommonHammerFallSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsGround:
		Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusHammerFall, Fthammer.ftHammerGetAnimFrame(fighter_gobj), 1.0, Fthammer.ftHammerGetStatUpdateFlags(fighter_gobj))
	Fthammer.ftHammerSetColAnim(fighter_gobj)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x80147CCC
static func ftCommonHammerFallCheckInterruptDamageFall(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if B(Fthammer.ftHammerCheckHoldHammer(fighter_gobj)) and (fp.input.pl.button_tap & (fp.input.button_mask_a | fp.input.button_mask_b)):
		ftCommonHammerFallSetStatus(fighter_gobj) # Wiggle out of DamageFall if A or B is pressed

		return TRUE
	else:
		return FALSE

## 0x80147D30
static func ftCommonHammerFallSetStatusJump(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr
	var vel_x: int
	var vel_y: int

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusHammerFall, Fthammer.ftHammerGetAnimFrame(fighter_gobj), 1.0, Fthammer.ftHammerGetStatUpdateFlags(fighter_gobj))
	Fthammer.ftHammerSetColAnim(fighter_gobj)

	match fp.status_vars.common.hammer.input_source:
		FTCOMMON_KNEEBEND_INPUT_TYPE_BUTTON:
			# ftCommonJumpGetJumpForceButton(stick_range_x, &vel_x, &vel_y, is_shorthop): two pure s32 outputs
			var r: Dictionary = Ftcommonjump.ftCommonJumpGetJumpForceButton(fp.input.pl.stick_range.x, fp.status_vars.common.hammer.is_shorthop)
			vel_x = r.jump_vel_x
			vel_y = r.jump_vel_y

		_:
			# case FTCOMMON_KNEEBEND_INPUT_TYPE_STICK: / default:
			vel_x = fp.input.pl.stick_range.x
			vel_y = int(fp.status_vars.common.hammer.jump_force)    # s32 = f32
	fp.physics.vel_air.y = (vel_y * attr.jump_height_mul) + attr.jump_height_base
	fp.physics.vel_air.x = vel_x * attr.jump_vel_x

	fp.tap_stick_y = FTINPUT_STICKBUFFER_TICS_MAX

## 0x80147E34
static func ftCommonHammerFallSetStatusPass(fighter_gobj) -> void:
	Ftcommonpass.ftCommonPassSetStatusParam(fighter_gobj, nFTCommonStatusHammerFall, Fthammer.ftHammerGetAnimFrame(fighter_gobj), Fthammer.ftHammerGetStatUpdateFlags(fighter_gobj))
	Fthammer.ftHammerSetColAnim(fighter_gobj)

## 0x80147E7C
static func ftCommonHammerFallCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if B(Ftcommonpass.ftCommonPassCheckInputSuccess(fp)):
		ftCommonHammerFallSetStatusPass(fighter_gobj)

		return TRUE
	else:
		return FALSE
