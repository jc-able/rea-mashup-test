## 1:1 port of src/ft/ftchar/ftkirby/ftkirbycopycaptainspecialn.c (ssb-decomp-re): Kirby's copied
## Captain Falcon Falcon Punch.
class_name Ftkirbycopycaptainspecialn
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80160810
static func ftKirbyCopyCaptainSpecialNUpdateEffect(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if not B(fp.is_effect_attach):
		if fp.motion_vars.flags.flag0 == 1:
			if Efmanager.efManagerCaptainFalconPunchMakeEffect(fighter_gobj) != null: # != FALSE (pointer)
				fp.is_effect_attach = TRUE

			fp.motion_vars.flags.flag0 = 0

	elif fp.motion_vars.flags.flag0 == 1:
		Ftparam.ftParamProcStopEffect(fighter_gobj)

		fp.motion_vars.flags.flag0 = 2

## 0x80160894
static func ftKirbyCopyCaptainSpecialNGetAngle(stick_y = null) -> float:
	var temp_stick_y: int = ABS(stick_y)

	if temp_stick_y > 50:
		temp_stick_y = 50

	temp_stick_y -= 10

	if temp_stick_y < 0:
		temp_stick_y = 0

	if stick_y < 0:
		temp_stick_y = -temp_stick_y

	return F_CLC_DTOR32((temp_stick_y * 30) / 40.0)

## 0x8016090C
static func ftKirbyCopyCaptainSpecialNProcPhysics(fighter_gobj = null) -> void:
	ftKirbyCopyCaptainSpecialNUpdateEffect(fighter_gobj)
	Ftphysics.ftPhysicsApplyGroundVelTransN(fighter_gobj)

## 0x80160934
static func ftKirbyCopyCaptainSpecialAirNProcPhysics(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var boost: float

	if fp.motion_vars.flags.flag1 != 0:
		fp.motion_vars.flags.flag1 = 0
		fp.passive_vars.kirby.copycaptain_falcon_punch_unk += 1

		boost = ftKirbyCopyCaptainSpecialNGetAngle(fp.input.pl.stick_range.y)

		fp.physics.vel_air.y = __sinf(boost) * FTKIRBY_COPYCAPTAIN_FALCONPUNCH_VEL_BASE
		fp.physics.vel_air.x = __cosf(boost) * fp.lr * FTKIRBY_COPYCAPTAIN_FALCONPUNCH_VEL_BASE

	ftKirbyCopyCaptainSpecialNUpdateEffect(fighter_gobj)

	match fp.motion_vars.flags.flag2:
		0:
			Ftphysics.ftPhysicsApplyAirVelFriction(fighter_gobj)

		1:
			fp.physics.vel_air.y *= FTKIRBY_COPYCAPTAIN_FALCONPUNCH_VEL_MUL # Interestingly, Kirby's version multiplies by singles,
			fp.physics.vel_air.x *= FTKIRBY_COPYCAPTAIN_FALCONPUNCH_VEL_MUL # as opposed to Falcon's multiplying by doubles

		2:
			Ftphysics.ftPhysicsApplyAirVelDriftFastFall(fighter_gobj)

## 0x80160A40
static func ftKirbyCopyCaptainSpecialAirNSwitchStatusGround(fighter_gobj = null) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyCaptainSpecialN, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_RUMBLE | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM))

## 0x80160A80
static func ftKirbyCopyCaptainSpecialNSwitchStatusAir(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyCaptainSpecialAirN, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_RUMBLE | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM))
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x80160ACC
static func ftKirbyCopyCaptainSpecialNProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftkirbycopycaptainspecialn, &"ftKirbyCopyCaptainSpecialNSwitchStatusAir"))

## 0x80160AF0
static func ftKirbyCopyCaptainSpecialAirNProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbycopycaptainspecialn, &"ftKirbyCopyCaptainSpecialAirNSwitchStatusGround"))

## 0x80160B14
static func ftKirbyCopyCaptainSpecialNInitStatusVars(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag2 = 0
	fp.motion_vars.flags.flag1 = 0
	fp.motion_vars.flags.flag0 = 0

## 0x80160B28
static func func_ovl3_80160B28() -> void: # Unused
	return

## 0x80160B30
static func ftKirbyCopyCaptainSpecialNSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyCaptainSpecialN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftKirbyCopyCaptainSpecialNInitStatusVars(fighter_gobj)

## 0x80160B70
static func ftKirbyCopyCaptainSpecialAirNSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyCaptainSpecialAirN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftKirbyCopyCaptainSpecialNInitStatusVars(fighter_gobj)
