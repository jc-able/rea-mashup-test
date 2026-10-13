## Port of src/ft/ftchar/ftcaptain/ftcaptainspecialn.c (Captain Falcon neutral special: Falcon Punch).
class_name Ftcaptainspecialn
extends Port

## 0x8015F7F0
static func ftCaptainSpecialNUpdateEffect(fighter_gobj) -> void: # Falcon Punch
	var fp := ftGetStruct(fighter_gobj)

	if not fp.is_effect_attach:
		if fp.motion_vars.flags.flag0 == 1:
			if Efmanager.efManagerCaptainFalconPunchMakeEffect(fighter_gobj) != null:
				fp.is_effect_attach = TRUE

			fp.motion_vars.flags.flag0 = 0

	elif fp.motion_vars.flags.flag0 == 1:
		Ftparam.ftParamProcStopEffect(fighter_gobj)

		fp.motion_vars.flags.flag0 = 2

## 0x8015F874
static func ftCaptainSpecialNGetAngle(stick_y: int) -> float:
	var temp_stick_y: int = ABS(stick_y)

	if temp_stick_y > 50:
		temp_stick_y = 50

	temp_stick_y -= 10

	if temp_stick_y < 0:
		temp_stick_y = 0

	if stick_y < 0:
		temp_stick_y = -temp_stick_y

	return F_CLC_DTOR32((temp_stick_y * 30) / 40.0)

## 0x8015F8EC
static func ftCaptainSpecialNProcPhysics(fighter_gobj) -> void:
	ftCaptainSpecialNUpdateEffect(fighter_gobj)
	Ftphysics.ftPhysicsApplyGroundVelTransN(fighter_gobj)

## 0x8015F914
static func ftCaptainSpecialAirNProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var boost: float

	if fp.motion_vars.flags.flag1 != 0:
		fp.motion_vars.flags.flag1 = 0
		fp.passive_vars.captain.falcon_punch_unk += 1

		boost = ftCaptainSpecialNGetAngle(fp.input.pl.stick_range.y)

		fp.physics.vel_air.y = (__sinf(boost) * FTCAPTAIN_FALCONPUNCH_VEL_BASE)
		fp.physics.vel_air.x = (__cosf(boost) * fp.lr * FTCAPTAIN_FALCONPUNCH_VEL_BASE)

	ftCaptainSpecialNUpdateEffect(fighter_gobj)

	match fp.motion_vars.flags.flag2:
		0:
			Ftphysics.ftPhysicsApplyAirVelFriction(fighter_gobj)

		1:
			fp.physics.vel_air.y *= FTCAPTAIN_FALCONPUNCH_VEL_MUL
			fp.physics.vel_air.x *= FTCAPTAIN_FALCONPUNCH_VEL_MUL

		2:
			Ftphysics.ftPhysicsApplyAirVelDriftFastFall(fighter_gobj)

## 0x8015FA2C
static func ftCaptainSpecialAirNSwitchStatusGround(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCaptainStatusSpecialN, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_RUMBLE | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM))

	fp.proc_lagstart = Callable(Ftparam, &"ftParamProcPauseEffect")
	fp.proc_lagend = Callable(Ftparam, &"ftParamProcResumeEffect")

## 0x8015FA8C
static func ftCaptainSpecialNSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCaptainStatusSpecialAirN, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_RUMBLE | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM))
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

	fp.proc_lagstart = Callable(Ftparam, &"ftParamProcPauseEffect")
	fp.proc_lagend = Callable(Ftparam, &"ftParamProcResumeEffect")

## 0x8015FAF8
static func ftCaptainSpecialNProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftcaptainspecialn, &"ftCaptainSpecialNSwitchStatusAir"))

## 0x8015FB1C
static func ftCaptainSpecialAirNProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftcaptainspecialn, &"ftCaptainSpecialAirNSwitchStatusGround"))

## 0x8015FB40
static func ftCaptainSpecialNInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag2 = 0
	fp.motion_vars.flags.flag1 = 0
	fp.motion_vars.flags.flag0 = 0

## 0x8015FB54
static func func_ovl3_8015FB54() -> void: # Unused???
	return

## 0x8015FB5C
static func ftCaptainSpecialNSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCaptainStatusSpecialN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftCaptainSpecialNInitStatusVars(fighter_gobj)

	fp.proc_lagstart = Callable(Ftparam, &"ftParamProcPauseEffect")
	fp.proc_lagend = Callable(Ftparam, &"ftParamProcResumeEffect")

## 0x8015FBC0
static func ftCaptainSpecialAirNSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCaptainStatusSpecialAirN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftCaptainSpecialNInitStatusVars(fighter_gobj)

	fp.proc_lagstart = Callable(Ftparam, &"ftParamProcPauseEffect")
	fp.proc_lagend = Callable(Ftparam, &"ftParamProcResumeEffect")
