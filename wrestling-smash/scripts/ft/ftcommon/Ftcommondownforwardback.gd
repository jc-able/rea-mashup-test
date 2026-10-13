## 1:1 port of src/ft/ftcommon/ftcommondownforwardback.c (ssb-decomp-re): missed-tech roll from
## knockdown (DownForward / DownBack).
class_name Ftcommondownforwardback
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801447E0
static func ftCommonDownForwardOrBackSetStatus(fighter_gobj, status_id) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.is_jostle_ignore = TRUE

## 0x8014482C
static func ftCommonDownForwardOrBackCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int

	if ABS(fp.input.pl.stick_range.x) >= FTCOMMON_DOWN_FORWARD_BACK_RANGE_MIN:
		if Ftparam.ftParamGetStickAngleRads(fp) < F_CST_DTOR32(50.0): # 0.87266463F
			if (fp.input.pl.stick_range.x * fp.lr) >= 0:
				if (fp.status_id == nFTCommonStatusDownBounceD) or (fp.status_id == nFTCommonStatusDownWaitD):
					status_id = nFTCommonStatusDownForwardD
				else:
					status_id = nFTCommonStatusDownForwardU
			elif (fp.status_id == nFTCommonStatusDownBounceD) or (fp.status_id == nFTCommonStatusDownWaitD):
				status_id = nFTCommonStatusDownBackD
			else:
				status_id = nFTCommonStatusDownBackU

			ftCommonDownForwardOrBackSetStatus(fighter_gobj, status_id)

			return TRUE
	return FALSE
