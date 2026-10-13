## 1:1 port of src/ft/ftcommon/ftcommonappeal.c (ssb-decomp-re): Appeal (taunt) status.
class_name Ftcommonappeal
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8014E6A0
static func ftCommonAppealProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.motion_vars.flags.flag1 != 0) and (not Ftcommoncatch1.ftCommonCatchCheckInterruptCommon(fighter_gobj)):
		Ftcommonguard1.ftCommonGuardOnCheckInterruptCommon(fighter_gobj)

## 0x8014E6E0
static func ftCommonAppealSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.fkind == nFTKindKirby) or (fp.fkind == nFTKindNKirby):
		if (fp.passive_vars.kirby.copy_id != nFTKindKirby) and (fp.passive_vars.kirby.is_ignore_losecopy == FALSE):
			Ftkirbyspecialn.ftKirbySpecialNLoseCopy(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusAppeal, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.motion_vars.flags.flag1 = 0

## 0x8014E764
static func ftCommonAppealCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if fp.input.pl.button_tap & fp.input.button_mask_l:
		ftCommonAppealSetStatus(fighter_gobj)

		return TRUE
	else:
		return FALSE
