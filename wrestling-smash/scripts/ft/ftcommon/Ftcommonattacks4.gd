## 1:1 port of src/ft/ftcommon/ftcommonattacks4.c (ssb-decomp-re): forward smash (AttackS4 + angled
## variants), incl. Pikachu's Thunder Shock effects and Ness's bat reflector.
class_name Ftcommonattacks4
extends Port

## FTSpecialColl (src/relocData/238_NessMainMotion.c, dNessMainMotion_AttackS4ReflectorFTSpecialColl =
## llNessMainMotionAttackS4ReflectorFTSpecialColl). fp->special_coll points at this file data in C,
## so one shared instance is used here as well.
static var dFTNessMainMotionAttackS4ReflectorFTSpecialColl: FTSpecialColl = FTSpecialColl.make(
	2,                                  # kind
	0,                                  # joint_id
	Vector3(0.0, 150.0, 0.0),           # offset
	Vector3(300.0, 300.0, 300.0),       # size
	1000                                # damage_resist
)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8014FE40
static func ftCommonAttackS4ProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var offset = Vector3.ZERO

	# switch (fp->fkind): the Pikachu case has no break and falls through into the Ness case.
	var is_fallthrough := false

	if (fp.fkind == nFTKindPikachu) or (fp.fkind == nFTKindNPikachu):
		if (fp.motion_vars.flags.flag1 != 0) or (fp.motion_vars.flags.flag2 != 0):
			fp.status_vars.common.attack4.gfx_id += syUtilsRandIntRange((FTCOMMON_ATTACKS4_THUNDERSHOCK_GFX_ID_MAX - 1)) + 1

			if fp.status_vars.common.attack4.gfx_id >= FTCOMMON_ATTACKS4_THUNDERSHOCK_GFX_ID_MAX:
				fp.status_vars.common.attack4.gfx_id -= FTCOMMON_ATTACKS4_THUNDERSHOCK_GFX_ID_MAX
			if fp.motion_vars.flags.flag1 != 0:
				fp.motion_vars.flags.flag1 = 0

				offset.x = -FTCOMMON_ATTACKS4_THUNDERSHOCK_GFX_OFF_X
				offset.z = FTCOMMON_ATTACKS4_THUNDERSHOCK_GFX_OFF_Z
				offset.y = FTCOMMON_ATTACKS4_THUNDERSHOCK_GFX_OFF_Y
			if fp.motion_vars.flags.flag2 != 0:
				fp.motion_vars.flags.flag2 = 0

				offset.x = FTCOMMON_ATTACKS4_THUNDERSHOCK_GFX_OFF_X
				offset.z = FTCOMMON_ATTACKS4_THUNDERSHOCK_GFX_OFF_Z
				offset.y = FTCOMMON_ATTACKS4_THUNDERSHOCK_GFX_OFF_Y

			offset = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[11], offset)
			offset = Gmcollision.func_ovl2_800EE018(fp.joints[nFTPartsJointTopN], offset)

			if Efmanager.efManagerPikachuThunderShockMakeEffect(fighter_gobj, offset, fp.status_vars.common.attack4.gfx_id) != null:
				fp.is_effect_attach = TRUE
		# Fallthrough, should break here for efficiency
		is_fallthrough = true
	if is_fallthrough or (fp.fkind == nFTKindNess) or (fp.fkind == nFTKindNNess):
		if (fp.motion_vars.flags.flag1 != 0) and not fp.is_reflect:
			fp.is_reflect = TRUE
		if (fp.motion_vars.flags.flag1 == 0) and fp.is_reflect:
			fp.is_reflect = FALSE
	Ftanimend.ftAnimEndSetWait(fighter_gobj)

## 0x8014FFE0
static func ftCommonAttackS4SetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var stick_angle: float
	var status_id: int

	if fp.data.mainmotion[nFTCommonMotionAttackS4HiS].anim_file_id != 0:
		stick_angle = Ftparam.ftParamGetStickAngleRads(fp)

		if stick_angle > FTCOMMON_ATTACKS4_5ANGLE_HI_MIN:
			status_id = nFTCommonStatusAttackS4Hi
		elif stick_angle > FTCOMMON_ATTACKS4_5ANGLE_HIS_MIN:
			status_id = nFTCommonStatusAttackS4HiS
		elif stick_angle < FTCOMMON_ATTACKS4_5ANGLE_LW_MIN:
			status_id = nFTCommonStatusAttackS4Lw
		elif stick_angle < FTCOMMON_ATTACKS4_5ANGLE_LWS_MIN:
			status_id = nFTCommonStatusAttackS4LwS
		else:
			status_id = nFTCommonStatusAttackS4
	elif fp.data.mainmotion[nFTCommonMotionAttackS4Hi].anim_file_id != 0:
		stick_angle = Ftparam.ftParamGetStickAngleRads(fp)

		if stick_angle > FTCOMMON_ATTACKS4_3ANGLE_HI_MIN:
			status_id = nFTCommonStatusAttackS4Hi
		elif stick_angle < FTCOMMON_ATTACKS4_3ANGLE_LW_MIN:
			status_id = nFTCommonStatusAttackS4Lw
		else:
			status_id = nFTCommonStatusAttackS4
	else:
		status_id = nFTCommonStatusAttackS4

	match fp.fkind:
		nFTKindPikachu, nFTKindNPikachu:
			fp.motion_vars.flags.flag2 = 0
			fp.motion_vars.flags.flag1 = 0

		nFTKindNess, nFTKindNNess:
			fp.motion_vars.flags.flag1 = 0

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	match fp.fkind:
		nFTKindPikachu, nFTKindNPikachu:
			fp.status_vars.common.attack4.gfx_id = 0

			fp.proc_lagstart = Callable(Ftparam, &"ftParamProcPauseEffect")
			fp.proc_lagend = Callable(Ftparam, &"ftParamProcResumeEffect")

		nFTKindNess, nFTKindNNess:
			fp.special_coll = dFTNessMainMotionAttackS4ReflectorFTSpecialColl

## 0x801501E0
static func ftCommonAttackS4CheckInterruptDash(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if ((fp.input.pl.stick_range.x * fp.lr) >= FTCOMMON_ATTACKS4_STICK_RANGE_MIN) and (fp.input.pl.button_tap & fp.input.button_mask_a):
		var item_gobj = fp.item_gobj

		if item_gobj != null:
			var ip := itGetStruct(item_gobj)

			if (fp.input.pl.button_hold & fp.input.button_mask_z) or ((ip.type == nITTypeThrow) or ((ip.type == nITTypeShoot) and Itmain.itMainCheckShootNoAmmo(item_gobj))):
				Ftcommonitemthrow.ftCommonItemThrowSetStatus(fighter_gobj, nFTCommonStatusLightThrowF4)

				return TRUE
			match ip.type:
				nITTypeSwing:
					Ftcommonitemswing.ftCommonItemSwingSetStatus(fighter_gobj, nFTItemSwingTypeAttack4)
					return TRUE

				nITTypeShoot:
					Ftcommonitemshoot.ftCommonItemShootSetStatus(fighter_gobj)
					return TRUE
		if attr.is_have_attacks4:
			ftCommonAttackS4SetStatus(fighter_gobj)

			return TRUE
	return FALSE

## 0x8015030C - only called from the Turn status (ftcommonturn.c).
## Union note: C reads fp->status_vars.common.attack4.lr (offset 0x10 of the FTCommonStatusVars
## union). Nothing writes that member; in the Turn status the same word is
## status_vars.common.turn.lr_turn (= -lr at the start of the turn, set by ftCommonTurnSetStatus).
## The port keeps union members in separate Dictionaries, so the aliased field is read through
## `turn.lr_turn` to keep the shared storage.
static func ftCommonAttackS4CheckInterruptTurn(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if ((fp.input.pl.stick_range.x * fp.status_vars.common.turn.lr_turn) >= FTCOMMON_ATTACKS4_STICK_RANGE_MIN) and (fp.input.pl.button_tap & fp.input.button_mask_a):
		var item_gobj = fp.item_gobj

		if item_gobj != null:
			var ip := itGetStruct(item_gobj)

			if (fp.input.pl.button_hold & fp.input.button_mask_z) or ((ip.type == nITTypeThrow) or ((ip.type == nITTypeShoot) and Itmain.itMainCheckShootNoAmmo(item_gobj))):
				Ftcommonitemthrow.ftCommonItemThrowSetStatus(fighter_gobj, nFTCommonStatusLightThrowF4 if ((fp.input.pl.stick_range.x * fp.lr) >= 0) else nFTCommonStatusLightThrowB4)

				return TRUE
			match ip.type:
				nITTypeSwing:
					Ftparam.ftParamSetStickLR(fp)
					Ftcommonitemswing.ftCommonItemSwingSetStatus(fighter_gobj, nFTItemSwingTypeAttack4)
					return TRUE

				nITTypeShoot:
					Ftparam.ftParamSetStickLR(fp)
					Ftcommonitemshoot.ftCommonItemShootSetStatus(fighter_gobj)
					return TRUE
		if attr.is_have_attacks4:
			Ftparam.ftParamSetStickLR(fp)
			ftCommonAttackS4SetStatus(fighter_gobj)

			return TRUE
	return FALSE

## 0x80150470
static func ftCommonAttackS4CheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if (ABS(fp.input.pl.stick_range.x) >= FTCOMMON_ATTACKS4_STICK_RANGE_MIN) and (fp.tap_stick_x < FTCOMMON_ATTACKS4_BUFFER_TICS_MAX) and (fp.input.pl.button_tap & fp.input.button_mask_a):
		var item_gobj = fp.item_gobj

		if item_gobj != null:
			var ip := itGetStruct(item_gobj)

			if (fp.input.pl.button_hold & fp.input.button_mask_z) or ((ip.type == nITTypeThrow) or ((ip.type == nITTypeShoot) and Itmain.itMainCheckShootNoAmmo(item_gobj))):
				Ftcommonitemthrow.ftCommonItemThrowSetStatus(fighter_gobj, nFTCommonStatusLightThrowF4 if ((fp.input.pl.stick_range.x * fp.lr) >= 0) else nFTCommonStatusLightThrowB4)

				return TRUE
			match ip.type:
				nITTypeSwing:
					Ftparam.ftParamSetStickLR(fp)
					Ftcommonitemswing.ftCommonItemSwingSetStatus(fighter_gobj, nFTItemSwingTypeAttack4)
					return TRUE

				nITTypeShoot:
					Ftparam.ftParamSetStickLR(fp)
					Ftcommonitemshoot.ftCommonItemShootSetStatus(fighter_gobj)
					return TRUE
		if attr.is_have_attacks4:
			Ftparam.ftParamSetStickLR(fp)
			ftCommonAttackS4SetStatus(fighter_gobj)

			return TRUE
	return FALSE
