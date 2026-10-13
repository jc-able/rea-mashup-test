## 1:1 port of src/ft/ftcommon/ftcommonspeciallw.c (ssb-decomp-re): grounded down special dispatch.
class_name Ftcommonspeciallw
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x80188D50 - indexed by FTKind
static var dFTCommonSpecialLwStatusList: Array = [
	Callable(Ftmariospeciallw, &"ftMarioSpecialLwSetStatus"),
	Callable(Ftfoxspeciallw, &"ftFoxSpecialLwStartSetStatus"),
	Callable(Ftdonkeyspeciallw, &"ftDonkeySpecialLwStartSetStatus"),
	Callable(Ftsamusspeciallw, &"ftSamusSpecialLwSetStatus"),
	Callable(Ftmariospeciallw, &"ftMarioSpecialLwSetStatus"),
	Callable(Ftlinkspeciallw, &"ftLinkSpecialLwSetStatus"),
	Callable(Ftyoshispeciallw, &"ftYoshiSpecialLwStartSetStatus"),
	Callable(Ftcaptainspeciallw, &"ftCaptainSpecialLwSetStatus"),
	Callable(Ftkirbyspeciallw, &"ftKirbySpecialLwStartSetStatus"),
	Callable(Ftpikachuspeciallw, &"ftPikachuSpecialLwStartSetStatus"),
	Callable(Ftpurinspeciallw, &"ftPurinSpecialLwSetStatus"),
	Callable(Ftnessspeciallw, &"ftNessSpecialLwStartSetStatus"),
	Callable(Ftmariospeciallw, &"ftMarioSpecialLwSetStatus"),
	Callable(Ftmariospeciallw, &"ftMarioSpecialLwSetStatus"),
	Callable(Ftmariospeciallw, &"ftMarioSpecialLwSetStatus"),
	Callable(Ftfoxspeciallw, &"ftFoxSpecialLwStartSetStatus"),
	Callable(Ftdonkeyspeciallw, &"ftDonkeySpecialLwStartSetStatus"),
	Callable(Ftsamusspeciallw, &"ftSamusSpecialLwSetStatus"),
	Callable(Ftmariospeciallw, &"ftMarioSpecialLwSetStatus"),
	Callable(Ftlinkspeciallw, &"ftLinkSpecialLwSetStatus"),
	Callable(Ftyoshispeciallw, &"ftYoshiSpecialLwStartSetStatus"),
	Callable(Ftcaptainspeciallw, &"ftCaptainSpecialLwSetStatus"),
	Callable(Ftkirbyspeciallw, &"ftKirbySpecialLwStartSetStatus"),
	Callable(Ftpikachuspeciallw, &"ftPikachuSpecialLwStartSetStatus"),
	Callable(Ftpurinspeciallw, &"ftPurinSpecialLwSetStatus"),
	Callable(Ftnessspeciallw, &"ftNessSpecialLwStartSetStatus"),
	Callable(Ftdonkeyspeciallw, &"ftDonkeySpecialLwStartSetStatus"),
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801511E0
static func ftCommonSpecialLwCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if (fp.input.pl.button_tap & fp.input.button_mask_b) and attr.is_have_speciallw and (fp.input.pl.stick_range.y <= FTCOMMON_SPECIALLW_STICK_RANGE_MIN):
		dFTCommonSpecialLwStatusList[fp.fkind].call(fighter_gobj)

		return TRUE
	else:
		return FALSE
