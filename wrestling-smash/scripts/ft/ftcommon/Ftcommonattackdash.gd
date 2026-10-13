## 1:1 port of src/ft/ftcommon/ftcommonattackdash.c (ssb-decomp-re): dash attack (AttackDash).
class_name Ftcommonattackdash
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8014F670
static func ftCommonAttackDashSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusAttackDash, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

## 0x8014F69C - Also checks LightThrowDash and ItemSwingDash
static func ftCommonAttackDashCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if fp.input.pl.button_tap & fp.input.button_mask_a:
		if fp.item_gobj != null:
			if (fp.input.pl.button_hold & fp.input.button_mask_z) or (itGetStruct(fp.item_gobj).type == nITTypeThrow):
				Ftcommonitemthrow.ftCommonItemThrowSetStatus(fighter_gobj, nFTCommonStatusLightThrowDash)

				return TRUE
			if itGetStruct(fp.item_gobj).type == nITTypeSwing:
				Ftcommonitemswing.ftCommonItemSwingSetStatus(fighter_gobj, nFTItemSwingTypeAttackDash)

				return TRUE
		if attr.is_have_attackdash:
			ftCommonAttackDashSetStatus(fighter_gobj)

			return TRUE
	return FALSE
