## 1:1 port of src/ft/ftcommon/ftcommonattackhi3.c (ssb-decomp-re): up tilt (AttackHi3 / Hi3F / Hi3B).
class_name Ftcommonattackhi3
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8014FA50
static func ftCommonAttackHi3SetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var stick_angle: float
	var status_id: int

	if fp.data.mainmotion[nFTCommonMotionAttackHi3F].anim_file_id != 0:
		stick_angle = syUtilsArcTan2(fp.input.pl.stick_range.y, fp.input.pl.stick_range.x * fp.lr)

		if stick_angle < F_CLC_DTOR32(77.0): # 1.3439035F
			status_id = nFTCommonStatusAttackHi3F # WHAT
		elif stick_angle > F_CLC_DTOR32(103.0): # 1.7976892F
			status_id = nFTCommonStatusAttackHi3B # WHAT
		else:
			status_id = nFTCommonStatusAttackHi3
	else:
		status_id = nFTCommonStatusAttackHi3

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x8014FB1C
static func ftCommonAttackHi3CheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if (fp.input.pl.button_tap & fp.input.button_mask_a) and (fp.input.pl.stick_range.y >= FTCOMMON_ATTACKHI3_STICK_RANGE_MIN):
		if Ftparam.ftParamGetStickAngleRads(fp) > F_CST_DTOR32(50.0): # 0.87266463F
			if Ftcommonitemthrow.ftCommonLightThrowCheckItemTypeThrow(fp):
				Ftcommonitemthrow.ftCommonItemThrowSetStatus(fighter_gobj, nFTCommonStatusLightThrowHi)

				return TRUE
			elif attr.is_have_attackhi3:
				ftCommonAttackHi3SetStatus(fighter_gobj)

				return TRUE
	return FALSE
