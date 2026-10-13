## 1:1 port of src/ft/ftcommon/ftcommonattackhi4.c (ssb-decomp-re): up smash (AttackHi4).
class_name Ftcommonattackhi4
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801505F0
static func ftCommonAttackHi4SetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusAttackHi4, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80150628
static func ftCommonAttackHi4CheckInputSuccess(fp) -> int:
	if (fp.input.pl.stick_range.y >= FTCOMMON_ATTACKHI4_STICK_RANGE_MIN) and (fp.input.pl.button_tap & fp.input.button_mask_a):
		return TRUE
	else:
		return FALSE

## 0x80150660
static func ftCommonAttackHi4CheckInterruptMain(fp) -> int:
	var attr = fp.attr

	if Ftcommonitemthrow.ftCommonLightThrowCheckItemTypeThrow(fp):
		Ftcommonitemthrow.ftCommonItemThrowSetStatus(fp.fighter_gobj, nFTCommonStatusLightThrowHi4)

		return TRUE
	if attr.is_have_attackhi4:
		ftCommonAttackHi4SetStatus(fp.fighter_gobj)

		return TRUE
	return FALSE

## 0x801506CC
static func ftCommonAttackHi4CheckInterruptKneeBend(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if ftCommonAttackHi4CheckInputSuccess(fp) != FALSE:
		return ftCommonAttackHi4CheckInterruptMain(fp)
	else:
		return FALSE

## 0x8015070C
static func ftCommonAttackHi4CheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if (ftCommonAttackHi4CheckInputSuccess(fp) != FALSE) and (fp.tap_stick_y < FTCOMMON_ATTACKHI4_BUFFER_TICS_MAX):
		return ftCommonAttackHi4CheckInterruptMain(fp)
	else:
		return FALSE
