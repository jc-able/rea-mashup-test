## 1:1 port of src/ft/ftcommon/ftcommonspecialn.c (ssb-decomp-re): grounded neutral special dispatch.
class_name Ftcommonspecialn
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x80188C00 - indexed by passive_vars.kirby.copy_id (FTKind)
static var dFTKirbySpecialNStatusList: Array = [
	Callable(Ftkirbycopymariospecialn, &"ftKirbyCopyMarioSpecialNSetStatus"),
	Callable(Ftkirbycopyfoxspecialn, &"ftKirbyCopyFoxSpecialNSetStatus"),
	Callable(Ftkirbycopydonkeyspecialn, &"ftKirbyCopyDonkeySpecialNStartSetStatus"),
	Callable(Ftkirbycopysamusspecialn, &"ftKirbyCopySamusSpecialNStartSetStatus"),
	Callable(Ftkirbycopymariospecialn, &"ftKirbyCopyMarioSpecialNSetStatus"),
	Callable(Ftkirbycopylinkspecialn, &"ftKirbyCopyLinkSpecialNSetStatus"),
	Callable(Ftkirbycopyyoshispecialn, &"ftKirbyCopyYoshiSpecialNSetStatus"),
	Callable(Ftkirbycopycaptainspecialn, &"ftKirbyCopyCaptainSpecialNSetStatus"),
	Callable(Ftkirbyspecialn, &"ftKirbySpecialNStartSetStatus"),
	Callable(Ftkirbycopypikachuspecialn, &"ftKirbyCopyPikachuSpecialNSetStatus"),
	Callable(Ftkirbycopypurinspecialn, &"ftKirbyCopyPurinSpecialNSetStatus"),
	Callable(Ftkirbycopynessspecialn, &"ftKirbyCopyNessSpecialNSetStatus"),
	Callable(Ftkirbyspecialn, &"ftKirbySpecialNStartSetStatus"),
	Callable(Ftkirbycopymariospecialn, &"ftKirbyCopyMarioSpecialNSetStatus"),
	Callable(Ftkirbyspecialn, &"ftKirbySpecialNStartSetStatus"),
	Callable(Ftkirbyspecialn, &"ftKirbySpecialNStartSetStatus"),
	Callable(Ftkirbyspecialn, &"ftKirbySpecialNStartSetStatus"),
	Callable(Ftkirbyspecialn, &"ftKirbySpecialNStartSetStatus"),
	Callable(Ftkirbyspecialn, &"ftKirbySpecialNStartSetStatus"),
	Callable(Ftkirbyspecialn, &"ftKirbySpecialNStartSetStatus"),
	Callable(Ftkirbyspecialn, &"ftKirbySpecialNStartSetStatus"),
	Callable(Ftkirbyspecialn, &"ftKirbySpecialNStartSetStatus"),
	Callable(Ftkirbyspecialn, &"ftKirbySpecialNStartSetStatus"),
	Callable(Ftkirbyspecialn, &"ftKirbySpecialNStartSetStatus"),
	Callable(Ftkirbyspecialn, &"ftKirbySpecialNStartSetStatus"),
	Callable(Ftkirbyspecialn, &"ftKirbySpecialNStartSetStatus"),
	Callable(Ftkirbyspecialn, &"ftKirbySpecialNStartSetStatus"),
]

## 0x80188C6C - indexed by FTKind
static var dFTCommonSpecialNStatusList: Array = [
	Callable(Ftmariospecialn, &"ftMarioSpecialNSetStatus"),
	Callable(Ftfoxspecialn, &"ftFoxSpecialNSetStatus"),
	Callable(Ftdonkeyspecialn, &"ftDonkeySpecialNStartSetStatus"),
	Callable(Ftsamusspecialn, &"ftSamusSpecialNStartSetStatus"),
	Callable(Ftmariospecialn, &"ftMarioSpecialNSetStatus"),
	Callable(Ftlinkspecialn, &"ftLinkSpecialNSetStatus"),
	Callable(Ftyoshispecialn, &"ftYoshiSpecialNSetStatus"),
	Callable(Ftcaptainspecialn, &"ftCaptainSpecialNSetStatus"),
	Callable(Ftcommonspecialn, &"ftKirbySpecialNSetStatusSelect"),
	Callable(Ftpikachuspecialn, &"ftPikachuSpecialNSetStatus"),
	Callable(Ftpurinspecialn, &"ftPurinSpecialNSetStatus"),
	Callable(Ftnessspecialn, &"ftNessSpecialNSetStatus"),
	Callable(Ftmariospecialn, &"ftMarioSpecialNSetStatus"),
	Callable(Ftmariospecialn, &"ftMarioSpecialNSetStatus"),
	Callable(Ftmariospecialn, &"ftMarioSpecialNSetStatus"),
	Callable(Ftfoxspecialn, &"ftFoxSpecialNSetStatus"),
	Callable(Ftdonkeyspecialn, &"ftDonkeySpecialNStartSetStatus"),
	Callable(Ftsamusspecialn, &"ftSamusSpecialNStartSetStatus"),
	Callable(Ftmariospecialn, &"ftMarioSpecialNSetStatus"),
	Callable(Ftlinkspecialn, &"ftLinkSpecialNSetStatus"),
	Callable(Ftmariospecialn, &"ftMarioSpecialNSetStatus"),           # un bro momento
	Callable(Ftcaptainspecialn, &"ftCaptainSpecialNSetStatus"),
	Callable(Ftcommonspecialn, &"ftKirbySpecialNSetStatusSelect"),
	Callable(Ftpikachuspecialn, &"ftPikachuSpecialNSetStatus"),
	Callable(Ftpurinspecialn, &"ftPurinSpecialNSetStatus"),
	Callable(Ftnessspecialn, &"ftNessSpecialNSetStatus"),
	Callable(Ftdonkeyspecialn, &"ftDonkeySpecialNStartSetStatus"),
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80151060
static func ftKirbySpecialNSetStatusSelect(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	dFTKirbySpecialNStatusList[fp.passive_vars.kirby.copy_id].call(fighter_gobj)

## 0x80151098
static func ftCommonSpecialNCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if (fp.input.pl.button_tap & fp.input.button_mask_b) and attr.is_have_specialn:
		if (fp.input.pl.stick_range.y < FTCOMMON_SPECIALHI_STICK_RANGE_MIN) and (fp.input.pl.stick_range.y > FTCOMMON_SPECIALLW_STICK_RANGE_MIN):
			if (fp.input.pl.stick_range.x * fp.lr) < FTCOMMON_SPECIALN_TURN_STICK_RANGE_MIN:
				Ftparam.ftParamSetStickLR(fp)
			dFTCommonSpecialNStatusList[fp.fkind].call(fighter_gobj)

			return TRUE
	return FALSE
