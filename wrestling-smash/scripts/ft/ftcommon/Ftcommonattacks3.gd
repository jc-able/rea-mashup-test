## 1:1 port of src/ft/ftcommon/ftcommonattacks3.c (ssb-decomp-re): forward tilt (AttackS3 + angled variants).
class_name Ftcommonattacks3
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8014F760
static func ftCommonAttackS3SetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var stick_angle: float
	var status_id: int

	if not Ftcommonget.ftCommonGetCheckInterruptCommon(fighter_gobj):
		if fp.data.mainmotion[nFTCommonMotionAttackS3HiS].anim_file_id != 0:
			stick_angle = Ftparam.ftParamGetStickAngleRads(fp)

			if stick_angle > FTCOMMON_ATTACKS3_5ANGLE_HI_MIN:
				status_id = nFTCommonStatusAttackS3Hi    # High-Angled Forward Tilt
			elif stick_angle > FTCOMMON_ATTACKS3_5ANGLE_HIS_MIN:
				status_id = nFTCommonStatusAttackS3HiS   # Middle High-Angled Forward Tilt
			elif stick_angle < FTCOMMON_ATTACKS3_5ANGLE_LW_MIN:
				status_id = nFTCommonStatusAttackS3Lw    # Low-Angled Forward Tilt
			elif stick_angle < FTCOMMON_ATTACKS3_5ANGLE_LWS_MIN:
				status_id = nFTCommonStatusAttackS3LwS   # Middle Low-Angled Forward Tilt
			else:
				status_id = nFTCommonStatusAttackS3      # Default Forward Tilt
		elif fp.data.mainmotion[nFTCommonMotionAttackS3Hi].anim_file_id != 0:
			stick_angle = Ftparam.ftParamGetStickAngleRads(fp)

			if stick_angle > FTCOMMON_ATTACKS3_3ANGLE_HI_MIN:
				status_id = nFTCommonStatusAttackS3Hi    # High-Angled Forward Tilt
			elif stick_angle < FTCOMMON_ATTACKS3_3ANGLE_LW_MIN:
				status_id = nFTCommonStatusAttackS3Lw    # Low-Angled Forward Tilt
			else:
				status_id = nFTCommonStatusAttackS3      # Default Forward Tilt
		else:
			status_id = nFTCommonStatusAttackS3

		Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
		Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x8014F8C0
static func ftCommonAttackS3CheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if (fp.input.pl.button_tap & fp.input.button_mask_a) and ((fp.input.pl.stick_range.x * fp.lr) >= FTCOMMON_ATTACKS3_STICK_RANGE_MIN):
		if ((-Ftparam.ftParamGetStickAngleRads(fp)) if (Ftparam.ftParamGetStickAngleRads(fp) < 0.0) else Ftparam.ftParamGetStickAngleRads(fp)) <= F_CST_DTOR32(50.0): # 0.87266463F
			if fp.item_gobj != null:
				if (fp.input.pl.button_hold & fp.input.button_mask_z) or (itGetStruct(fp.item_gobj).type == nITTypeThrow):
					Ftcommonitemthrow.ftCommonItemThrowSetStatus(fighter_gobj, nFTCommonStatusLightThrowF)

					return TRUE
				match itGetStruct(fp.item_gobj).type:
					nITTypeSwing:
						Ftcommonitemswing.ftCommonItemSwingSetStatus(fighter_gobj, nFTItemSwingTypeAttack3)
						return TRUE

					nITTypeShoot:
						Ftcommonitemshoot.ftCommonItemShootSetStatus(fighter_gobj)
						return TRUE
			if attr.is_have_attacks3:
				ftCommonAttackS3SetStatus(fighter_gobj)

				return TRUE
	return FALSE
