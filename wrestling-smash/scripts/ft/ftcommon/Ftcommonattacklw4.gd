## 1:1 port of src/ft/ftcommon/ftcommonattacklw4.c (ssb-decomp-re): down smash (AttackLw4).
class_name Ftcommonattacklw4
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80150760
static func ftCommonAttackLw4SetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusAttackLw4, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80150798
static func ftCommonAttackLw4CheckInputSuccess(fp) -> int:
	if (fp.input.pl.stick_range.y <= FTCOMMON_ATTACKLW4_STICK_RANGE_MIN) and (fp.input.pl.button_tap & fp.input.button_mask_a):
		return TRUE
	else:
		return FALSE

## 0x801507D0
static func ftCommonAttackLw4CheckInterruptMain(fp) -> int:
	var attr = fp.attr

	if Ftcommonitemthrow.ftCommonLightThrowCheckItemTypeThrow(fp):
		Ftcommonitemthrow.ftCommonItemThrowSetStatus(fp.fighter_gobj, nFTCommonStatusLightThrowLw4)

		return TRUE
	if attr.is_have_attacklw4:
		ftCommonAttackLw4SetStatus(fp.fighter_gobj)

		return TRUE
	return FALSE

## 0x80150838 - only called from the Squat statuses (ftcommonsquat.c).
## Union note: C reads fp->status_vars.common.attack4.is_goto_attacklw4 (offset 0x8 of the
## FTCommonStatusVars union). Nothing ever writes that member; in the Squat statuses the same word
## is status_vars.common.squat.unk_0x8 (the 3-frame down-smash window set by ftcommonsquat.c).
## The port keeps union members in separate Dictionaries, so the aliased field is read through
## `squat.unk_0x8` to keep the shared storage.
static func ftCommonAttackLw4CheckInterruptSquat(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if (ftCommonAttackLw4CheckInputSuccess(fp) != FALSE) and (fp.status_vars.common.squat.unk_0x8 != FALSE):
		return ftCommonAttackLw4CheckInterruptMain(fp)
	else:
		return FALSE

## 0x80150884
static func ftCommonAttackLw4CheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if (ftCommonAttackLw4CheckInputSuccess(fp) != FALSE) and (fp.tap_stick_y < FTCOMMON_ATTACKLW4_BUFFER_TICS_MAX):
		return ftCommonAttackLw4CheckInterruptMain(fp)
	else:
		return FALSE
