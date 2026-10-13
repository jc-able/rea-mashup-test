## 1:1 port of src/ft/ftcommon/ftcommonspecialhi.c (ssb-decomp-re): grounded up special dispatch.
class_name Ftcommonspecialhi
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x80188CE0 - indexed by FTKind
static var dFTCommonSpecialHiStatusList: Array = [
	Callable(Ftmariospecialhi, &"ftMarioSpecialHiSetStatus"),
	Callable(Ftfoxspecialhi, &"ftFoxSpecialHiStartSetStatus"),
	Callable(Ftdonkeyspecialhi, &"ftDonkeySpecialHiSetStatus"),
	Callable(Ftsamusspecialhi, &"ftSamusSpecialHiSetStatus"),
	Callable(Ftmariospecialhi, &"ftMarioSpecialHiSetStatus"),
	Callable(Ftlinkspecialhi, &"ftLinkSpecialHiSetStatus"),
	Callable(Ftyoshispecialhi, &"ftYoshiSpecialHiSetStatus"),
	Callable(Ftcaptainspecialhi, &"ftCaptainSpecialHiSetStatus"),
	Callable(Ftkirbyspecialhi, &"ftKirbySpecialHiSetStatus"),
	Callable(Ftpikachuspecialhi, &"ftPikachuSpecialHiStartSetStatus"),
	Callable(Ftpurinspecialhi, &"ftPurinSpecialHiSetStatus"),
	Callable(Ftnessspecialhi, &"ftNessSpecialHiStartSetStatus"),
	Callable(Ftmariospecialhi, &"ftMarioSpecialHiSetStatus"),
	Callable(Ftmariospecialhi, &"ftMarioSpecialHiSetStatus"),
	Callable(Ftmariospecialhi, &"ftMarioSpecialHiSetStatus"),
	Callable(Ftfoxspecialhi, &"ftFoxSpecialHiStartSetStatus"),
	Callable(Ftdonkeyspecialhi, &"ftDonkeySpecialHiSetStatus"),
	Callable(Ftsamusspecialhi, &"ftSamusSpecialHiSetStatus"),
	Callable(Ftmariospecialhi, &"ftMarioSpecialHiSetStatus"),
	Callable(Ftlinkspecialhi, &"ftLinkSpecialHiSetStatus"),
	Callable(Ftyoshispecialhi, &"ftYoshiSpecialHiSetStatus"),
	Callable(Ftcaptainspecialhi, &"ftCaptainSpecialHiSetStatus"),
	Callable(Ftkirbyspecialhi, &"ftKirbySpecialHiSetStatus"),
	Callable(Ftpikachuspecialhi, &"ftPikachuSpecialHiStartSetStatus"),
	Callable(Ftpurinspecialhi, &"ftPurinSpecialHiSetStatus"),
	Callable(Ftnessspecialhi, &"ftNessSpecialHiStartSetStatus"),
	Callable(Ftdonkeyspecialhi, &"ftDonkeySpecialHiSetStatus"),
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80151160
static func ftCommonSpecialHiCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if (fp.input.pl.button_tap & fp.input.button_mask_b) and attr.is_have_specialhi and (fp.input.pl.stick_range.y >= FTCOMMON_SPECIALHI_STICK_RANGE_MIN):
		dFTCommonSpecialHiStatusList[fp.fkind].call(fighter_gobj)

		return TRUE
	else:
		return FALSE
