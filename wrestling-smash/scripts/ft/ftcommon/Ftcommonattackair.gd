## 1:1 port of src/ft/ftcommon/ftcommonattackair.c (ssb-decomp-re): aerial attacks (AttackAirN/F/B/Hi/Lw),
## their landing, Link's down-air rehit, and the aerial item throw / item shoot interrupts.
class_name Ftcommonattackair
extends Port

## C f32 rounding of an intermediate result (the original computes in single precision).
static func _f32(x: float) -> float:
	var a := PackedFloat32Array([x])
	return a[0]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801508E0
static func ftCommonAttackAirLwProcHit(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.fkind == nFTKindLink) or (fp.fkind == nFTKindNLink):
		Ftparam.ftParamClearAttackCollAll(fighter_gobj)

		fp.is_fastfall = FALSE

		fp.physics.vel_air.y = FTCOMMON_ATTACKAIRLW_LINK_REHIT_BOUNCE_VEL_Y

		if fighter_gobj.anim_frame > FTCOMMON_ATTACKAIRLW_LINK_REHIT_FRAME_BEGIN:
			Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusAttackAirLw, FTCOMMON_ATTACKAIRLW_LINK_REHIT_FRAME_BEGIN, 1.0, FTSTATUS_PRESERVE_NONE)
		fp.status_vars.common.attackair.rehit_timer = FTCOMMON_ATTACKAIRLW_LINK_REHIT_TIMER

## 0x80150980
static func ftCommonAttackAirLwProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.fkind == nFTKindLink) or (fp.fkind == nFTKindNLink):
		if fp.status_vars.common.attackair.rehit_timer != 0:
			fp.status_vars.common.attackair.rehit_timer -= 1

			if (fp.status_vars.common.attackair.rehit_timer == 0) and (fighter_gobj.anim_frame < FTCOMMON_ATTACKAIRLW_LINK_REHIT_FRAME_END):
				Ftparam.ftParamRefreshAttackCollID(fighter_gobj, 0)
				Ftparam.ftParamRefreshAttackCollID(fighter_gobj, 1)
	Ftanimend.ftAnimEndSetFall(fighter_gobj)

## 0x80150A08
static func ftCommonAttackAirProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if Mpcommon.mpCommonCheckFighterLanding(fighter_gobj):
		if (fp.motion_vars.flags.flag1 != 0) and (fp.tics_since_last_z > FTCOMMON_ATTACKAIR_SMOOTHLANDING_TICS_MAX):
			var landing_motion_id: int = nFTCommonMotionLandingAirStart - nFTCommonMotionAttackAirStart

			# fp->data->mainmotion->motion_desc[fp->motion_id + landing_motion_id].anim_file_id
			if fp.data.mainmotion[fp.motion_id + landing_motion_id].anim_file_id != 0:
				Ftcommonlandingair.ftCommonLandingAirSetStatus(fighter_gobj)
			else:
				# F_PCT_TO_DEC(x) = (float)((x) * 0.01F), evaluated in f32 like the original (it is the landing anim speed)
				Ftcommonlanding.ftCommonLandingAirNullSetStatus(fighter_gobj, _f32(_f32(float(fp.motion_vars.flags.flag1)) * _f32(0.01)))
		elif fp.physics.vel_air.y > FTCOMMON_ATTACKAIR_SKIPLANDING_VEL_Y_MAX:
			Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)
		else:
			Ftcommonlanding.ftCommonLandingSetStatus(fighter_gobj)

## 0x80150B00 - Also checks LightThrowAir and ItemShoot
static func ftCommonAttackAirCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr
	var status_id: int = 0
	var is_have_attackair: int = 0
	var angle: float
	var is_goto_shoot: int = FALSE

	if fp.input.pl.button_tap & fp.input.button_mask_a:
		if not Fthammer.ftHammerCheckHoldHammer(fighter_gobj):
			if Ftcommonitemthrow.ftCommonLightThrowCheckItemTypeThrow(fp):
				if (ABS(fp.input.pl.stick_range.x) < FTCOMMON_ATTACKAIR_DIRECTION_STICK_RANGE_MIN) and (ABS(fp.input.pl.stick_range.y) < FTCOMMON_ATTACKAIR_DIRECTION_STICK_RANGE_MIN):
					if itGetStruct(fp.item_gobj).type == nITTypeThrow:
						Ftcommonitemthrow.ftCommonItemThrowSetStatus(fighter_gobj, nFTCommonStatusLightThrowAirF)

						return TRUE
					else:
						# ftSetupDropItem(fp) (macro in src/ft/fighter.h)
						var vel := Vector3(0.0, 0.0, 0.0)

						Itmain.itMainSetFighterDrop(fp.item_gobj, vel, 1.0)

					return FALSE
				else:
					angle = Ftparam.ftParamGetStickAngleRads(fp)

					if angle > F_CST_DTOR32(50.0): # 0.87266463F
						if fp.hold_stick_y < FTCOMMON_LIGHTTHROWAIR4_BUFFER_TICS_MAX:
							status_id = nFTCommonStatusLightThrowAirHi4
						else:
							status_id = nFTCommonStatusLightThrowAirHi
					elif angle < F_CST_DTOR32(-50.0): # -0.87266463F
						if fp.hold_stick_y < FTCOMMON_LIGHTTHROWAIR4_BUFFER_TICS_MAX:
							status_id = nFTCommonStatusLightThrowAirLw4
						else:
							status_id = nFTCommonStatusLightThrowAirLw
					elif (fp.input.pl.stick_range.x * fp.lr) >= 0:
						if fp.hold_stick_x < FTCOMMON_LIGHTTHROWAIR4_BUFFER_TICS_MAX:
							status_id = nFTCommonStatusLightThrowAirF4
						else:
							status_id = nFTCommonStatusLightThrowAirF
					elif fp.hold_stick_x < FTCOMMON_LIGHTTHROWAIR4_BUFFER_TICS_MAX:
						status_id = nFTCommonStatusLightThrowAirB4
					else:
						status_id = nFTCommonStatusLightThrowAirB

					Ftcommonitemthrow.ftCommonItemThrowSetStatus(fighter_gobj, status_id)

					return TRUE
			else:
				if (ABS(fp.input.pl.stick_range.x) < FTCOMMON_ATTACKAIR_DIRECTION_STICK_RANGE_MIN) and (ABS(fp.input.pl.stick_range.y) < FTCOMMON_ATTACKAIR_DIRECTION_STICK_RANGE_MIN):
					status_id = nFTCommonStatusAttackAirN
					is_have_attackair = attr.is_have_attackairn
					is_goto_shoot = TRUE
				else:
					angle = Ftparam.ftParamGetStickAngleRads(fp)

					if angle > F_CST_DTOR32(50.0): # 0.87266463F
						status_id = nFTCommonStatusAttackAirHi
						is_have_attackair = attr.is_have_attackairhi
					elif angle < F_CST_DTOR32(-50.0): # -0.87266463F
						status_id = nFTCommonStatusAttackAirLw
						is_have_attackair = attr.is_have_attackairlw
					elif (fp.input.pl.stick_range.x * fp.lr) >= 0:
						status_id = nFTCommonStatusAttackAirF
						is_have_attackair = attr.is_have_attackairf
						is_goto_shoot = TRUE
					else:
						status_id = nFTCommonStatusAttackAirB
						is_have_attackair = attr.is_have_attackairb
			if is_goto_shoot != FALSE:
				if (fp.item_gobj != null) and (itGetStruct(fp.item_gobj).type == nITTypeShoot):
					Ftcommonitemshoot.ftCommonItemShootAirSetStatus(fighter_gobj)

					return TRUE
			if is_have_attackair:
				fp.motion_vars.flags.flag1 = 0

				Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_FASTFALL)

				if status_id == nFTCommonStatusAttackAirLw:
					fp.proc_hit = Callable(Ftcommonattackair, &"ftCommonAttackAirLwProcHit")

					fp.status_vars.common.attackair.rehit_timer = 0
				Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

				fp.tics_since_last_z = FTINPUT_ZTRIGLAST_TICS_MAX

				return TRUE
	return FALSE
