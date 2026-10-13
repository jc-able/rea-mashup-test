## Port of src/ft/ftchar/ftcaptain/ftcaptainspeciallw.c (Captain Falcon down special: Falcon Kick).
class_name Ftcaptainspeciallw
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8015FC30
static func ftCaptainSpecialLwUpdateEffect(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if not fp.is_effect_attach:
		if fp.motion_vars.flags.flag2 == 1:
			if Efmanager.efManagerCaptainFalconKickMakeEffect(fighter_gobj) != null:
				fp.is_effect_attach = TRUE

			fp.motion_vars.flags.flag2 = 0

	elif fp.motion_vars.flags.flag2 == 2:
		Ftparam.ftParamProcStopEffect(fighter_gobj)
		fp.motion_vars.flags.flag2 = 0

## 0x8015FCB0
static func ftCaptainSpecialLwSetAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.ga = nMPKineticsAir
	fp.jumps_used = 1

## 0x8015FCC8
static func ftCaptainSpecialLwSetGround(fighter_gobj) -> void: # Unused?
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))

## 0x8015FCE8
static func ftCaptainSpecialLwDecideMapCollide(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsGround:
		if fp.motion_vars.flags.flag3 != 0:
			Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftcaptainspeciallw, &"ftCaptainSpecialLwSetAir"))
		else:
			Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftcaptainspeciallw, &"ftCaptainSpecialLwSetAir"))
	else:
		Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftcaptainspeciallw, &"ftCaptainSpecialLwSetGround"))

## 0x8015FD50
static func ftCaptainSpecialLwDecideSetEndStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsGround:
		Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)
	else:
		Ftcommonfall.ftCommonFallSetStatus(fighter_gobj)

## 0x8015FD90
static func ftCaptainSpecialLwProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcaptainspeciallw, &"ftCaptainSpecialLwDecideSetEndStatus"))

## 0x8015FDB4
static func ftCaptainSpecialLwProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsGround:
		fp.joints[nFTPartsJointTopN].rotate.z = -syUtilsArcTan2(fp.coll_data.floor_angle.x, fp.coll_data.floor_angle.y)
		Ftphysics.ftPhysicsApplyGroundVelTransN(fighter_gobj)

	elif fp.motion_vars.flags.flag0 != 0:
		Ftphysics.ftPhysicsApplyAirVelFriction(fighter_gobj)

	else:
		Ftphysics.ftPhysicsApplyAirVelTransNAll(fighter_gobj)

	# syVectorScale3D(&fp->physics.vel_air, vel_scale) (sys/vector.c: dst->x/y/z *= scale)
	fp.physics.vel_air.x *= fp.status_vars.captain.speciallw.vel_scale
	fp.physics.vel_air.y *= fp.status_vars.captain.speciallw.vel_scale
	fp.physics.vel_air.z *= fp.status_vars.captain.speciallw.vel_scale

	ftCaptainSpecialLwUpdateEffect(fighter_gobj)

## 0x8015FE4C
static func ftCaptainSpecialLwLandingProcPhysics(fighter_gobj) -> void:
	Ftphysics.ftPhysicsApplyGroundVelTransN(fighter_gobj)

## 0x8015FE6C
static func ftCaptainSpecialAirLwProcPhysics(fighter_gobj) -> void:
	ftCaptainSpecialLwUpdateEffect(fighter_gobj)
	Ftphysics.ftPhysicsApplyAirVelTransNAll(fighter_gobj)

## 0x8015FE94
static func ftCaptainSpecialLwBoundProcPhysics(fighter_gobj) -> void:
	Ftphysics.ftPhysicsApplyAirVelTransNAll(fighter_gobj)

## 0x8015FEB4
static func ftCaptainSpecialLwBoundCheckGoto(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.motion_vars.flags.flag1 == 1) and (fp.coll_data.mask_curr & (MAP_FLAG_RWALL | MAP_FLAG_LWALL)):
		Mpcommon.mpCommonSetFighterAir(fp)
		Ftmain.ftMainSetStatus(fighter_gobj, nFTCaptainStatusSpecialLwBound, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

		fp.motion_vars.flags.flag1 = 0

		return TRUE
	else:
		return FALSE

## 0x8015FF2C
static func ftCaptainSpecialLwAirCheckAirGoto(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 == 2:
		if fp.ga == nMPKineticsAir:
			ftCaptainSpecialLwAirSetStatus(fighter_gobj)

			fp.motion_vars.flags.flag1 = 0

			return TRUE

		fp.motion_vars.flags.flag1 = 0

	return FALSE

## 0x8015FF88
static func ftCaptainSpecialLwProcMap(fighter_gobj) -> void:
	ftCaptainSpecialLwDecideMapCollide(fighter_gobj)

	if ftCaptainSpecialLwBoundCheckGoto(fighter_gobj) == FALSE:
		ftCaptainSpecialLwAirCheckAirGoto(fighter_gobj)

## 0x8015FFC0
static func ftCaptainSpecialLwAirProcMap(fighter_gobj) -> void:
	ftCaptainSpecialLwDecideMapCollide(fighter_gobj)

## 0x8015FFE0
static func ftCaptainSpecialAirLwProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftcaptainspeciallw, &"ftCaptainSpecialLwLandingSetStatus"))

## 0x80160004
static func ftCaptainSpecialLwProcHit(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.captain.speciallw.scale_apply_timer < FTCAPTAIN_FALCONKICK_VEL_SCALE_APPLY_TIME:
		fp.status_vars.captain.speciallw.scale_apply_timer = (fp.status_vars.captain.speciallw.scale_apply_timer + 1) & 0xFFFF # u16

		fp.status_vars.captain.speciallw.vel_scale /= FTCAPTAIN_FALCONKICK_VEL_SCALE_DIV

## 0x80160038
static func ftCaptainSpecialLwProcStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.captain.speciallw.scale_apply_timer = 0

	fp.motion_vars.flags.flag0 = 0
	fp.motion_vars.flags.flag3 = 0
	fp.motion_vars.flags.flag1 = 0
	fp.motion_vars.flags.flag2 = 0

	fp.status_vars.captain.speciallw.vel_scale = 1.0

## 0x80160060
static func ftCaptainSpecialLwAirSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var rot_z: float = fp.joints[nFTPartsJointTopN].rotate.z

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCaptainStatusSpecialLwAir, 0.0, 1.0, FTSTATUS_PRESERVE_EFFECT)

	fp.joints[nFTPartsJointTopN].rotate.z = rot_z
	fp.joints[nFTPartsJointTransN].rotate.z = fp.joints[nFTPartsJointTopN].rotate.z

	fp.proc_lagstart = Callable(Ftparam, &"ftParamProcPauseEffect")
	fp.proc_lagend = Callable(Ftparam, &"ftParamProcResumeEffect")

## 0x801600EC
static func ftCaptainSpecialLwLandingSetStatus(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCaptainStatusSpecialLwLanding, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

## 0x80160128
static func ftCaptainSpecialLwSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_status = Callable(Ftcaptainspeciallw, &"ftCaptainSpecialLwProcStatus")

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCaptainStatusSpecialLw, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.proc_shield = Callable(Ftcaptainspeciallw, &"ftCaptainSpecialLwProcHit")
	fp.proc_hit = Callable(Ftcaptainspeciallw, &"ftCaptainSpecialLwProcHit")

	fp.proc_lagstart = Callable(Ftparam, &"ftParamProcPauseEffect")
	fp.proc_lagend = Callable(Ftparam, &"ftParamProcResumeEffect")

## 0x801601A0
static func jtgt_ovl3_801601A0(fighter_gobj) -> void: # Unused
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCaptainStatusSpecialLwAir, 0.0, 1.0, FTSTATUS_PRESERVE_EFFECT)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.proc_hit = Callable(Ftcaptainspeciallw, &"ftCaptainSpecialLwProcHit")

	fp.proc_lagstart = Callable(Ftparam, &"ftParamProcPauseEffect")
	fp.proc_lagend = Callable(Ftparam, &"ftParamProcResumeEffect")

## 0x8016020C
static func ftCaptainSpecialAirLwSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_status = Callable(Ftcaptainspeciallw, &"ftCaptainSpecialLwProcStatus")

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCaptainStatusSpecialAirLw, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.proc_lagstart = Callable(Ftparam, &"ftParamProcPauseEffect")
	fp.proc_lagend = Callable(Ftparam, &"ftParamProcResumeEffect")
