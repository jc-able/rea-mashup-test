## 1:1 port of src/ft/ftchar/ftmario/ftmariospeciallw.c (ssb-decomp-re).
## Mario / Luigi down special (Mario Tornado / Luigi Cyclone).
class_name Ftmariospeciallw
extends Port

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x801564F0
static func ftMarioSpecialLwProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag3 != 0:
		fp.status_vars.mario.speciallw.dust_effect_int -= 1

		if fp.status_vars.mario.speciallw.dust_effect_int == 4:
			Ftparam.ftParamMakeEffect(fighter_gobj, nEFKindDustLight, nFTPartsJointTopN, Vector3.ZERO, Vector3.ZERO, -fp.lr, FALSE, FALSE) # Spawn GFX (C: NULL offset/scatter == zero vectors)
		elif fp.status_vars.mario.speciallw.dust_effect_int == 0:
			Ftparam.ftParamMakeEffect(fighter_gobj, nEFKindDustLight, nFTPartsJointTopN, Vector3.ZERO, Vector3.ZERO, fp.lr, FALSE, FALSE) # Spawn GFX

			fp.status_vars.mario.speciallw.dust_effect_int = 8
	Ftanimend.ftAnimEndSetWait(fighter_gobj)

## 0x801565A8
static func ftMarioSpecialAirLwProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag2 != 0:
		fp.motion_vars.flags.flag2 = 0
		fp.passive_vars.mario.is_expend_tornado = TRUE
	Ftanimend.ftAnimEndSetFall(fighter_gobj)

## 0x801565E4
static func ftMarioSpecialLwUpdateFriction(fp: Fighter, vel: float) -> float:
	if fp.motion_vars.flags.flag1 != 0:
		fp.status_vars.mario.speciallw.friction -= 2.0

		vel += fp.status_vars.mario.speciallw.friction

		if vel < 0.0:
			vel = 0.0
	return vel

## 0x80156630
static func ftMarioSpecialLwProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftphysics.ftPhysicsApplyClampGroundVelStickRange(fp, 0, FTMARIO_TORNADO_VEL_X_GROUND, ftMarioSpecialLwUpdateFriction(fp, FTMARIO_TORNADO_VEL_X_CLAMP))
	Ftphysics.ftPhysicsSetGroundVelTransferAir(fighter_gobj)

	if (fp.motion_vars.flags.flag3 != 0) and (fp.input.pl.button_tap & fp.input.button_mask_b):
		fp.physics.vel_air.y += FTMARIO_TORNADO_VEL_Y_TAP

		ftMarioSpecialLwSwitchStatusAir(fighter_gobj)

## 0x801566C4
static func ftMarioSpecialAirLwProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if (fp.passive_vars.mario.is_expend_tornado == FALSE) and (fp.motion_vars.flags.flag3 != 0) and (fp.input.pl.button_tap & fp.input.button_mask_b):
		Ftphysics.ftPhysicsAddClampAirVelY(fp, FTMARIO_TORNADO_VEL_Y_TAP, FTMARIO_TORNADO_VEL_Y_CLAMP)
	Ftphysics.ftPhysicsApplyGravityDefault(fp, attr)
	Ftphysics.ftPhysicsClampAirVelXStickRange(fp, 0, FTMARIO_TORNADO_VEL_X_AIR, ftMarioSpecialLwUpdateFriction(fp, FTMARIO_TORNADO_VEL_X_CLAMP))

## 0x8015675C
static func ftMarioSpecialLwProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftmariospeciallw, &"ftMarioSpecialLwSwitchStatusAir"))

## 0x80156780
static func ftMarioSpecialAirLwProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftmariospeciallw, &"ftMarioSpecialAirLwSwitchStatusGround"))

## 0x801567A4
static func ftMarioSpecialAirLwSetDisableRise(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag3 = 0

## 0x801567B0
static func ftMarioSpecialAirLwSwitchStatusGround(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftMarioSpecialAirLwSetDisableRise(fighter_gobj)
	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTMarioStatusSpecialLw, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_RUMBLE)
	Ftphysics.ftPhysicsClampGroundVel(fp, FTMARIO_TORNADO_VEL_X_CLAMP)

## 0x80156808
static func ftMarioSpecialLwSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftMarioSpecialAirLwSetDisableRise(fighter_gobj)
	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTMarioStatusSpecialAirLw, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_RUMBLE)
	Ftphysics.ftPhysicsClampAirVelY(fp, FTMARIO_TORNADO_VEL_Y_CLAMP)
	Ftphysics.ftPhysicsClampAirVelX(fp, FTMARIO_TORNADO_VEL_X_CLAMP)

## 0x8015686C
static func ftMarioSpecialLwInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag1 = 0
	fp.motion_vars.flags.flag2 = 0

	fp.status_vars.mario.speciallw.dust_effect_int = 5
	fp.status_vars.mario.speciallw.friction = 0.0

## 0x8015688C
static func ftMarioSpecialLwSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftMarioSpecialAirLwSetDisableRise(fighter_gobj)
	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTMarioStatusSpecialAirLw, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.physics.vel_air.y = -7.0

	Ftphysics.ftPhysicsClampAirVelX(fp, FTMARIO_TORNADO_VEL_X_CLAMP)
	ftMarioSpecialLwInitStatusVars(fighter_gobj)

	fp.stat_flags.ga = nMPKineticsGround

## 0x80156910
static func ftMarioSpecialAirLwSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var tornado_vel_y: float

	ftMarioSpecialAirLwSetDisableRise(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTMarioStatusSpecialAirLw, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	tornado_vel_y = 0.0 if (fp.passive_vars.mario.is_expend_tornado != FALSE) else FTMARIO_TORNADO_VEL_Y_TAP

	fp.physics.vel_air.y = (FTMARIO_TORNADO_VEL_Y_BASE - tornado_vel_y)

	Ftphysics.ftPhysicsClampAirVelX(fp, FTMARIO_TORNADO_VEL_X_CLAMP)
	ftMarioSpecialLwInitStatusVars(fighter_gobj)
