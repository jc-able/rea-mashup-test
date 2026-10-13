## 1:1 port of src/ft/ftchar/ftdonkey/ftdonkeythrowffall.c (ssb-decomp-re).
## Donkey Kong Cargo Throw: fall / jump / platform drop.
class_name Ftdonkeythrowffall
extends Port

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8014DA00
static func ftDonkeyThrowFFallProcInterrupt(fighter_gobj) -> void:
	if Ftcommonitemthrow.ftCommonHeavyThrowCheckInterruptCommon(fighter_gobj) == FALSE:
		Ftdonkeythrowff.ftDonkeyThrowFFCheckInterruptThrowFCommon(fighter_gobj)

## 0x8014DA30
static func ftDonkeyThrowFFallProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if Mpcommon.mpCommonCheckFighterLanding(fighter_gobj) != FALSE:
		if fp.physics.vel_air.y > FTCOMMON_THROWFFALL_SKIPLANDING_VEL_Y_MAX:
			Ftdonkeythrowfwait.ftDonkeyThrowFWaitSetStatus(fighter_gobj)
		else:
			Ftdonkeythrowflanding.ftDonkeyThrowFLandingSetStatus(fighter_gobj)

## 0x8014DA98
static func ftDonkeyThrowFFallSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsGround:
		Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusThrowFFall, 0.0, 0.0, FTSTATUS_PRESERVE_FASTFALL)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x8014DAF8
static func ftDonkeyThrowFJumpSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr
	var vel_x: int
	var vel_y: int

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusThrowFFall, 0.0, 0.0, FTSTATUS_PRESERVE_NONE)

	match fp.status_vars.common.throwf.input_source:
		FTCOMMON_KNEEBEND_INPUT_TYPE_BUTTON:
			# ftCommonJumpGetJumpForceButton(stick_range_x, &vel_x, &vel_y, is_shorthop): two out-params
			var r = Ftcommonjump.ftCommonJumpGetJumpForceButton(fp.input.pl.stick_range.x, fp.status_vars.common.throwf.is_shorthop)
			vel_x = r.jump_vel_x
			vel_y = r.jump_vel_y

		_: # FTCOMMON_KNEEBEND_INPUT_TYPE_STICK, default
			vel_x = fp.input.pl.stick_range.x
			vel_y = int(fp.status_vars.common.throwf.jump_force) # f32 -> s32
	fp.physics.vel_air.y = (vel_y * attr.jump_height_mul) + attr.jump_height_base
	fp.physics.vel_air.x = vel_x * attr.jump_vel_x

	fp.tap_stick_y = FTINPUT_STICKBUFFER_TICS_MAX

## 0x8014DBE0
static func ftDonkeyThrowFFallSetStatusPass(fighter_gobj) -> void:
	Ftcommonpass.ftCommonPassSetStatusParam(fighter_gobj, nFTDonkeyStatusThrowFFall, 1.0, 0)

## 0x8014DC08
static func ftDonkeyThrowFFallCheckInterruptPass(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if Ftcommonpass.ftCommonPassCheckInputSuccess(fp) != FALSE:
		ftDonkeyThrowFFallSetStatusPass(fighter_gobj)

		return TRUE
	else:
		return FALSE
