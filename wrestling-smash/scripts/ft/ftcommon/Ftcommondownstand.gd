## 1:1 port of src/ft/ftcommon/ftcommondownstand.c (ssb-decomp-re): getting up from knockdown (DownStand).
class_name Ftcommondownstand
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80144530
static func ftCommonDownStandProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.motion_vars.flags.flag1 != 0) and not Ftcommonkneebend.ftCommonKneeBendCheckInterruptCommon(fighter_gobj) and not Ftcommonpass.ftCommonPassCheckInterruptCommon(fighter_gobj):
		Ftcommondokan.ftCommonDokanStartCheckInterruptCommon(fighter_gobj)

## 0x80144580
static func ftCommonDownStandSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int

	if (fp.status_id == nFTCommonStatusDownBounceD) or (fp.status_id == nFTCommonStatusDownWaitD):
		status_id = nFTCommonStatusDownStandD
	else:
		status_id = nFTCommonStatusDownStandU

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.motion_vars.flags.flag1 = 0

## 0x801445D8
static func ftCommonDownStandCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if ((fp.input.pl.stick_range.y >= FTCOMMON_DOWNWAIT_STAND_STICK_RANGE_MIN) and (Ftparam.ftParamGetStickAngleRads(fp) >= F_CST_DTOR32(50.0))) or ((fp.input.pl.button_tap & fp.input.button_mask_z) != 0):
		ftCommonDownStandSetStatus(fighter_gobj)

		return TRUE
	else:
		return FALSE
