## 1:1 port of src/ft/ftchar/ftdonkey/ftdonkeythrowff.c (ssb-decomp-re).
## Donkey Kong Cargo Throw: the actual throw (ThrowFF / ThrowAirFF).
class_name Ftdonkeythrowff
extends Port

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8014DD00
static func ftDonkeyThrowFFProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.common.throwff.is_turn != FALSE:
		fp.status_vars.common.throwff.turn_tics -= 1

		if fp.lr == +1:
			DObjGetStruct(fighter_gobj).rotate.y = F_CST_DTOR32(90.0) - ((float(fp.status_vars.common.throwff.turn_tics) / FTCOMMON_THROWFF_TURN_FRAMES) * F_CST_DTOR32(180.0))
		else:
			DObjGetStruct(fighter_gobj).rotate.y = F_CST_DTOR32(-90.0) + ((float(fp.status_vars.common.throwff.turn_tics) / FTCOMMON_THROWFF_TURN_FRAMES) * F_CST_DTOR32(180.0))

		if fp.status_vars.common.throwff.turn_tics == 0:
			fp.status_vars.common.throwff.is_turn = FALSE
	if fp.motion_vars.flags.flag2 != 0:
		Ftcommonthrown1.ftCommonThrownProcPhysics(fp.catch_gobj)
		Ftcommonthrown2.ftCommonThrownReleaseThrownUpdateStats(fp.catch_gobj, -fp.lr, 0, TRUE)

		fp.motion_vars.flags.flag2 = 0
		fp.catch_gobj = null

		Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_NONE)
	if fighter_gobj.anim_frame <= 0.0:
		Mpcommon.mpCommonSetFighterWaitOrFall(fighter_gobj)

## 0x8014DE30
static func ftDonkeyThrowAirFFSwitchStatusGround(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusThrowFF, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.status_vars.common.throwff.is_turn = FALSE

	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

## 0x8014DE80
static func ftDonkeyThrowFFSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusThrowAirFF, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

## 0x8014DECC
static func ftDonkeyThrowFFProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftdonkeythrowff, &"ftDonkeyThrowFFSwitchStatusAir"))

## 0x8014DEF0
static func ftDonkeyThrowAirFFProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftdonkeythrowff, &"ftDonkeyThrowAirFFSwitchStatusGround"))

## 0x8014DF14
static func ftDonkeyThrowFFSetStatus(fighter_gobj, is_turn: int) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int
	var flags: int

	if fp.ga == nMPKineticsGround:
		status_id = nFTDonkeyStatusThrowFF
		flags = FTSTATUS_PRESERVE_NONE
	else:
		status_id = nFTDonkeyStatusThrowAirFF
		flags = FTSTATUS_PRESERVE_FASTFALL
	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, flags)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

	fp.motion_vars.flags.flag2 = 0

	fp.status_vars.common.throwff.is_turn = is_turn

	if is_turn != FALSE:
		fp.lr = -fp.lr

		fp.status_vars.common.throwff.turn_tics = FTCOMMON_THROWFF_TURN_FRAMES

## 0x8014DFA8
static func ftDonkeyThrowFFCheckInterruptThrowFCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var is_turn: int = FALSE

	if fp.input.pl.button_tap & (fp.input.button_mask_a | fp.input.button_mask_b):
		if (ABS(fp.input.pl.stick_range.x) >= FTCOMMON_THROWFF_TURN_STICK_RANGE_MIN) and ((fp.input.pl.stick_range.x * fp.lr) < 0) and (fp.ga == nMPKineticsAir):
			is_turn = TRUE
		ftDonkeyThrowFFSetStatus(fighter_gobj, is_turn)

		return TRUE
	else:
		return FALSE
