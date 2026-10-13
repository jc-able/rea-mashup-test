## 1:1 port of src/ft/ftcommon/ftcommonspecialair.c (ssb-decomp-re): aerial special dispatch.
class_name Ftcommonspecialair
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x80188A50 - indexed by passive_vars.kirby.copy_id (FTKind)
static var dFTKirbySpecialAirNStatusList: Array = [
	Callable(Ftkirbycopymariospecialn, &"ftKirbyCopyMarioSpecialAirNSetStatus"),            # Mario
	Callable(Ftkirbycopyfoxspecialn, &"ftKirbyCopyFoxSpecialAirNSetStatus"),                # Fox
	Callable(Ftkirbycopydonkeyspecialn, &"ftKirbyCopyDonkeySpecialAirNStartSetStatus"),     # Donkey Kong
	Callable(Ftkirbycopysamusspecialn, &"ftKirbyCopySamusSpecialAirNStartSetStatus"),       # Samus
	Callable(Ftkirbycopymariospecialn, &"ftKirbyCopyMarioSpecialAirNSetStatus"),            # Luigi
	Callable(Ftkirbycopylinkspecialn, &"ftKirbyCopyLinkSpecialAirNSetStatus"),              # Link
	Callable(Ftkirbycopyyoshispecialn, &"ftKirbyCopyYoshiSpecialAirNSetStatus"),            # Yoshi
	Callable(Ftkirbycopycaptainspecialn, &"ftKirbyCopyCaptainSpecialAirNSetStatus"),        # Captain Falcon
	Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNStartSetStatus"),                         # Kirby
	Callable(Ftkirbycopypikachuspecialn, &"ftKirbyCopyPikachuSpecialAirNSetStatus"),        # Pikachu
	Callable(Ftkirbycopypurinspecialn, &"ftKirbyCopyPurinSpecialAirNSetStatus"),            # Jigglypuff
	Callable(Ftkirbycopynessspecialn, &"ftKirbyCopyNessSpecialAirNSetStatus"),              # Ness
	Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNStartSetStatus"),                         # Master Hand
	Callable(Ftkirbycopymariospecialn, &"ftKirbyCopyMarioSpecialAirNSetStatus"),            # Metal Mario
	Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNStartSetStatus"),                         # Poly Mario
	Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNStartSetStatus"),                         # Poly Fox
	Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNStartSetStatus"),                         # Poly Donkey Kong
	Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNStartSetStatus"),                         # Poly Samus
	Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNStartSetStatus"),                         # Poly Luigi
	Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNStartSetStatus"),                         # Poly Link
	Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNStartSetStatus"),                         # Poly Yoshi
	Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNStartSetStatus"),                         # Poly Captain Falcon
	Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNStartSetStatus"),                         # Poly Kirby
	Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNStartSetStatus"),                         # Poly Pikachu
	Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNStartSetStatus"),                         # Poly Jigglypuff
	Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNStartSetStatus"),                         # Poly Ness
	Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNStartSetStatus"),                         # Giant Donkey Kong (inaccessible, Kirby's copy ID for Giant DK is always 2)
]

## 0x80188ABC - indexed by FTKind
static var dFTCommonSpecialAirNStatusList: Array = [
	Callable(Ftmariospecialn, &"ftMarioSpecialAirNSetStatus"),
	Callable(Ftfoxspecialn, &"ftFoxSpecialAirNSetStatus"),
	Callable(Ftdonkeyspecialn, &"ftDonkeySpecialAirNStartSetStatus"),
	Callable(Ftsamusspecialn, &"ftSamusSpecialAirNStartSetStatus"),
	Callable(Ftmariospecialn, &"ftMarioSpecialAirNSetStatus"),
	Callable(Ftlinkspecialn, &"ftLinkSpecialAirNSetStatus"),
	Callable(Ftyoshispecialn, &"ftYoshiSpecialAirNSetStatus"),
	Callable(Ftcaptainspecialn, &"ftCaptainSpecialAirNSetStatus"),
	Callable(Ftcommonspecialair, &"ftKirbySpecialAirNSetStatusSelect"),
	Callable(Ftpikachuspecialn, &"ftPikachuSpecialAirNSetStatus"),
	Callable(Ftpurinspecialn, &"ftPurinSpecialAirNSetStatus"),
	Callable(Ftnessspecialn, &"ftNessSpecialAirNSetStatus"),
	Callable(Ftmariospecialn, &"ftMarioSpecialAirNSetStatus"),
	Callable(Ftmariospecialn, &"ftMarioSpecialAirNSetStatus"),
	Callable(Ftmariospecialn, &"ftMarioSpecialAirNSetStatus"),
	Callable(Ftfoxspecialn, &"ftFoxSpecialAirNSetStatus"),
	Callable(Ftdonkeyspecialn, &"ftDonkeySpecialAirNStartSetStatus"),
	Callable(Ftsamusspecialn, &"ftSamusSpecialAirNStartSetStatus"),
	Callable(Ftmariospecialn, &"ftMarioSpecialAirNSetStatus"),
	Callable(Ftlinkspecialn, &"ftLinkSpecialAirNSetStatus"),
	Callable(Ftmariospecialn, &"ftMarioSpecialAirNSetStatus"),            # more bro momento
	Callable(Ftcaptainspecialn, &"ftCaptainSpecialAirNSetStatus"),
	Callable(Ftcommonspecialair, &"ftKirbySpecialAirNSetStatusSelect"),
	Callable(Ftpikachuspecialn, &"ftPikachuSpecialAirNSetStatus"),
	Callable(Ftpurinspecialn, &"ftPurinSpecialAirNSetStatus"),
	Callable(Ftnessspecialn, &"ftNessSpecialAirNSetStatus"),
	Callable(Ftdonkeyspecialn, &"ftDonkeySpecialAirNStartSetStatus"),
]

## 0x80188B28 - indexed by FTKind (note: Master Hand's slot uses Mario's SpecialAirN, as in the original)
static var dFTCommonSpecialAirHiStatusList: Array = [
	Callable(Ftmariospecialhi, &"ftMarioSpecialAirHiSetStatus"),
	Callable(Ftfoxspecialhi, &"ftFoxSpecialAirHiStartSetStatus"),
	Callable(Ftdonkeyspecialhi, &"ftDonkeySpecialAirHiSetStatus"),
	Callable(Ftsamusspecialhi, &"ftSamusSpecialAirHiSetStatus"),
	Callable(Ftmariospecialhi, &"ftMarioSpecialAirHiSetStatus"),
	Callable(Ftlinkspecialhi, &"ftLinkSpecialAirHiSetStatus"),
	Callable(Ftyoshispecialhi, &"ftYoshiSpecialAirHiSetStatus"),
	Callable(Ftcaptainspecialhi, &"ftCaptainSpecialAirHiSetStatus"),
	Callable(Ftkirbyspecialhi, &"ftKirbySpecialAirHiSetStatus"),
	Callable(Ftpikachuspecialhi, &"ftPikachuSpecialAirHiStartSetStatus"),
	Callable(Ftpurinspecialhi, &"ftPurinSpecialAirHiSetStatus"),
	Callable(Ftnessspecialhi, &"ftNessSpecialAirHiStartSetStatus"),
	Callable(Ftmariospecialn, &"ftMarioSpecialAirNSetStatus"),
	Callable(Ftmariospecialhi, &"ftMarioSpecialAirHiSetStatus"),
	Callable(Ftmariospecialhi, &"ftMarioSpecialAirHiSetStatus"),
	Callable(Ftfoxspecialhi, &"ftFoxSpecialAirHiStartSetStatus"),
	Callable(Ftdonkeyspecialhi, &"ftDonkeySpecialAirHiSetStatus"),
	Callable(Ftsamusspecialhi, &"ftSamusSpecialAirHiSetStatus"),
	Callable(Ftmariospecialhi, &"ftMarioSpecialAirHiSetStatus"),
	Callable(Ftlinkspecialhi, &"ftLinkSpecialAirHiSetStatus"),
	Callable(Ftyoshispecialhi, &"ftYoshiSpecialAirHiSetStatus"),
	Callable(Ftcaptainspecialhi, &"ftCaptainSpecialAirHiSetStatus"),
	Callable(Ftkirbyspecialhi, &"ftKirbySpecialAirHiSetStatus"),
	Callable(Ftpikachuspecialhi, &"ftPikachuSpecialAirHiStartSetStatus"),
	Callable(Ftpurinspecialhi, &"ftPurinSpecialAirHiSetStatus"),
	Callable(Ftnessspecialhi, &"ftNessSpecialAirHiStartSetStatus"),
	Callable(Ftdonkeyspecialhi, &"ftDonkeySpecialAirHiSetStatus"),
]

## 0x80188B94 - indexed by FTKind (NULL entries: Donkey Kong variants have no aerial down special)
static var dFTCommonSpecialAirLwStatusList: Array = [
	Callable(Ftmariospeciallw, &"ftMarioSpecialAirLwSetStatus"),
	Callable(Ftfoxspeciallw, &"ftFoxSpecialAirLwStartSetStatus"),
	Callable(),
	Callable(Ftsamusspeciallw, &"ftSamusSpecialAirLwSetStatus"),
	Callable(Ftmariospeciallw, &"ftMarioSpecialAirLwSetStatus"),
	Callable(Ftlinkspeciallw, &"ftLinkSpecialAirLwSetStatus"),
	Callable(Ftyoshispeciallw, &"ftYoshiSpecialAirLwStartSetStatus"),
	Callable(Ftcaptainspeciallw, &"ftCaptainSpecialAirLwSetStatus"),
	Callable(Ftkirbyspeciallw, &"ftKirbySpecialAirLwStartSetStatus"),
	Callable(Ftpikachuspeciallw, &"ftPikachuSpecialAirLwStartSetStatus"),
	Callable(Ftpurinspeciallw, &"ftPurinSpecialAirLwSetStatus"),
	Callable(Ftnessspeciallw, &"ftNessSpecialAirLwStartSetStatus"),
	Callable(Ftmariospeciallw, &"ftMarioSpecialAirLwSetStatus"),
	Callable(Ftmariospeciallw, &"ftMarioSpecialAirLwSetStatus"),
	Callable(Ftmariospeciallw, &"ftMarioSpecialAirLwSetStatus"),
	Callable(Ftfoxspeciallw, &"ftFoxSpecialAirLwStartSetStatus"),
	Callable(),
	Callable(Ftsamusspeciallw, &"ftSamusSpecialAirLwSetStatus"),
	Callable(Ftmariospeciallw, &"ftMarioSpecialAirLwSetStatus"),
	Callable(Ftlinkspeciallw, &"ftLinkSpecialAirLwSetStatus"),
	Callable(Ftyoshispeciallw, &"ftYoshiSpecialAirLwStartSetStatus"),
	Callable(Ftcaptainspeciallw, &"ftCaptainSpecialAirLwSetStatus"),
	Callable(Ftkirbyspeciallw, &"ftKirbySpecialAirLwStartSetStatus"),
	Callable(Ftpikachuspeciallw, &"ftPikachuSpecialAirLwStartSetStatus"),
	Callable(Ftpurinspeciallw, &"ftPurinSpecialAirLwSetStatus"),
	Callable(Ftnessspeciallw, &"ftNessSpecialAirLwStartSetStatus"),
	Callable(),
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80150ED0
static func ftKirbySpecialAirNSetStatusSelect(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	dFTKirbySpecialAirNStatusList[fp.passive_vars.kirby.copy_id].call(fighter_gobj)

## 0x80150F08
static func ftCommonSpecialAirCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if fp.input.pl.button_tap & fp.input.button_mask_b:
		if not Fthammer.ftHammerCheckHoldHammer(fighter_gobj):
			if fp.input.pl.stick_range.y >= FTCOMMON_SPECIALHI_STICK_RANGE_MIN:
				if attr.is_have_specialairhi:
					dFTCommonSpecialAirHiStatusList[fp.fkind].call(fighter_gobj)

					return TRUE
			elif fp.input.pl.stick_range.y <= FTCOMMON_SPECIALLW_STICK_RANGE_MIN:
				if attr.is_have_specialairlw:
					dFTCommonSpecialAirLwStatusList[fp.fkind].call(fighter_gobj)

					return TRUE
			elif attr.is_have_specialairn:
				if (fp.input.pl.stick_range.x * fp.lr) < FTCOMMON_SPECIALN_TURN_STICK_RANGE_MIN:
					Ftparam.ftParamSetStickLR(fp)
				dFTCommonSpecialAirNStatusList[fp.fkind].call(fighter_gobj)

				return TRUE
	return FALSE
