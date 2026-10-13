## Port of src/ft/ftchar/ftpikachu/ftpikachuspeciallw.c (Pikachu down special: Thunder).
class_name Ftpikachuspeciallw
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

const FTPIKACHU_SPECIALLWSTART_STATUS_FLAGS = (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM)
const FTPIKACHU_SPECIALLWLOOP_STATUS_FLAGS = (FTSTATUS_PRESERVE_RUMBLE | FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM | FTSTATUS_PRESERVE_HIT)
const FTPIKACHU_SPECIALLWHIT_STATUS_FLAGS = (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM | FTSTATUS_PRESERVE_HIT)
const FTPIKACHU_SPECIALLWEND_STATUS_FLAGS = (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80151DB0
static func ftPikachuSpecialLwMakeThunder(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3
	var vel: Vector3

	pos.x = 0.0
	pos.y = 0.0
	pos.z = 0.0

	pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[FTPIKACHU_THUNDER_SPAWN_JOINT], pos)

	pos.y = Mpcollision.gMPCollisionGroundData.map_bound_top - FTPIKACHU_THUNDER_SPAWN_OFF_Y

	vel.x = 0.0
	vel.z = 0.0
	vel.y = FTPIKACHU_THUNDER_VEL_Y

	fp.status_vars.pikachu.speciallw.thunder_gobj = Wppikachuthunder.wpPikachuThunderHeadMakeWeapon(fighter_gobj, pos, vel)

## 0x80151E44
static func ftPikachuSpecialLwStartUpdateThunder(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag0 != 0:
		ftPikachuSpecialLwMakeThunder(fighter_gobj)

## 0x80151E74
static func ftPikachuSpecialLwStartProcUpdate(fighter_gobj) -> void:
	ftPikachuSpecialLwStartUpdateThunder(fighter_gobj)
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftpikachuspeciallw, &"ftPikachuSpecialLwLoopSetStatus"))

## 0x80151EA4
static func ftPikachuSpecialAirLwStartProcUpdate(fighter_gobj) -> void:
	ftPikachuSpecialLwStartUpdateThunder(fighter_gobj)
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftpikachuspeciallw, &"ftPikachuSpecialAirLwLoopSetStatus"))

## 0x80151ED4
static func ftPikachuSpecialLwStartProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftpikachuspeciallw, &"ftPikachuSpecialLwStartSwitchStatusAir"))

## 0x80151EF8
static func ftPikachuSpecialAirLwStartProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftpikachuspeciallw, &"ftPikachuSpecialAirLwStartSwitchStatusGround"))

## 0x80151F1C
static func ftPikachuSpecialAirLwStartSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialLwStart, fighter_gobj.anim_frame, 1.0, FTPIKACHU_SPECIALLWSTART_STATUS_FLAGS)

## 0x80151F5C
static func ftPikachuSpecialLwStartSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialAirLwStart, fighter_gobj.anim_frame, 1.0, FTPIKACHU_SPECIALLWSTART_STATUS_FLAGS)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x80151FA8
static func ftPikachuSpecialLwStartInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag1 = 0
	fp.motion_vars.flags.flag0 = 0

	fp.passive_vars.pikachu.is_thunder_destroy = FALSE

## 0x80151FBC
static func ftPikachuSpecialLwStartSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialLwStart, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftPikachuSpecialLwStartInitStatusVars(fighter_gobj)

## 0x80151FFC
static func ftPikachuSpecialAirLwStartSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialAirLwStart, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftPikachuSpecialLwStartInitStatusVars(fighter_gobj)

## 0x8015203C
static func ftPikachuSpecialLwCheckCollideThunder(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var wp: Weapon
	var fj: DObj
	var wj: DObj
	var thunder_gobj
	var ft_temp_x: float
	var ft_temp_y: float
	var wp_temp_x: float
	var wp_temp_y: float
	var dist_x: float
	var dist_y: float

	thunder_gobj = fp.status_vars.pikachu.speciallw.thunder_gobj

	if thunder_gobj == null:
		fp.passive_vars.pikachu.is_thunder_destroy |= TRUE

	if fp.passive_vars.pikachu.is_thunder_destroy & TRUE:
		return FALSE

	wp = wpGetStruct(thunder_gobj)

	fj = DObjGetStruct(fighter_gobj)
	wj = DObjGetStruct(thunder_gobj)

	ft_temp_x = fj.translate.x
	wp_temp_x = wj.translate.x

	dist_x = -(ft_temp_x - wp_temp_x) if (ft_temp_x < wp_temp_x) else (ft_temp_x - wp_temp_x)

	if dist_x < FTPIKACHU_THUNDER_COLLIDE_X:
		ft_temp_y = fj.translate.y
		wp_temp_y = wj.translate.y + FTPIKACHU_THUNDER_COLL_OFF_Y

		dist_y = -(ft_temp_y - wp_temp_y) if (ft_temp_y < wp_temp_y) else (ft_temp_y - wp_temp_y)

		if dist_y < FTPIKACHU_THUNDER_COLLIDE_Y:
			wp.weapon_vars.thunder.thunder_state = nWPPikachuThunderStatusCollide

			return TRUE

	return FALSE

## 0x80152124
static func ftPikachuSpecialLwLoopProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if ftPikachuSpecialLwCheckCollideThunder(fighter_gobj) != FALSE:
		ftPikachuSpecialLwHitSetStatus(fighter_gobj)

	elif fp.passive_vars.pikachu.is_thunder_destroy & TRUE:
		ftPikachuSpecialLwEndSetStatus(fighter_gobj)

	elif fp.motion_vars.flags.flag1 != 0:
		ftPikachuSpecialLwEndSetStatus(fighter_gobj)

## 0x8015219C
static func ftPikachuSpecialAirLwLoopProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if ftPikachuSpecialLwCheckCollideThunder(fighter_gobj) != FALSE:
		ftPikachuSpecialAirLwHitSetStatus(fighter_gobj)

	elif fp.passive_vars.pikachu.is_thunder_destroy & TRUE:
		ftPikachuSpecialAirLwEndSetStatus(fighter_gobj)

	elif fp.motion_vars.flags.flag1 != 0:
		ftPikachuSpecialAirLwEndSetStatus(fighter_gobj)

## 0x80152214
static func ftPikachuSpecialLwLoopProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftpikachuspeciallw, &"ftPikachuSpecialLwLoopSwitchStatusAir"))

## 0x80152238
static func ftPikachuSpecialAirLwLoopProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftpikachuspeciallw, &"ftPikachuSpecialAirLwLoopSwitchStatusGround"))

## 0x8015225C
static func ftPikachuSpecialLwProcDamage(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var thunder_gobj = fp.status_vars.pikachu.speciallw.thunder_gobj

	if thunder_gobj == null:
		fp.passive_vars.pikachu.is_thunder_destroy |= TRUE

	if not (fp.passive_vars.pikachu.is_thunder_destroy & TRUE):
		var wp := wpGetStruct(thunder_gobj)

		wp.weapon_vars.thunder.thunder_state = nWPPikachuThunderStatusDestroy

## 0x8015229C
static func ftPikachuSpecialAirLwLoopSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialLwLoop, fighter_gobj.anim_frame, 1.0, FTPIKACHU_SPECIALLWLOOP_STATUS_FLAGS)

## 0x801522DC
static func ftPikachuSpecialLwLoopSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialAirLwLoop, fighter_gobj.anim_frame, 1.0, FTPIKACHU_SPECIALLWLOOP_STATUS_FLAGS)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x80152328
static func ftPikachuSpecialLwLoopUpdateThunder(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag0 == 0:
		ftPikachuSpecialLwMakeThunder(fighter_gobj)

	fp.motion_vars.flags.flag0 = 0

	fp.proc_damage = Callable(Ftpikachuspeciallw, &"ftPikachuSpecialLwProcDamage")

## 0x8015236C
static func ftPikachuSpecialLwLoopSetStatus(fighter_gobj) -> void:
	ftPikachuSpecialLwLoopUpdateThunder(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialLwLoop, 0.0, 1.0, FTSTATUS_PRESERVE_RUMBLE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x801523B0
static func ftPikachuSpecialAirLwLoopSetStatus(fighter_gobj) -> void:
	ftPikachuSpecialLwLoopUpdateThunder(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialAirLwLoop, 0.0, 1.0, FTSTATUS_PRESERVE_RUMBLE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x801523F4
static func ftPikachuSpecialLwHitProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 != 0:
		ftPikachuSpecialLwEndSetStatus(fighter_gobj)

## 0x80152424
static func ftPikachuSpecialAirLwHitProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 != 0:
		ftPikachuSpecialAirLwEndSetStatus(fighter_gobj)

## 0x80152454
static func ftPikachuSpecialAirLwHitProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	Ftphysics.ftPhysicsApplyGravityClampTVel(fp, FTPIKACHU_THUNDER_HIT_GRAVITY, attr.tvel_base)

	if Ftphysics.ftPhysicsCheckClampAirVelXDecMax(fp, attr) == FALSE:
		Ftphysics.ftPhysicsApplyAirVelXFriction(fp, attr)

## 0x801524A4
static func ftPikachuSpecialLwHitProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftpikachuspeciallw, &"ftPikachuSpecialLwHitSwitchStatusAir"))

## 0x801524C8
static func ftPikachuSpecialAirLwHitProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftpikachuspeciallw, &"ftPikachuSpecialAirLwHitSwitchStatusGround"))

## 0x801524EC
static func ftPikachuSpecialAirLwHitSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialLwHit, fighter_gobj.anim_frame, 1.0, FTPIKACHU_SPECIALLWHIT_STATUS_FLAGS)

## 0x8015252C
static func ftPikachuSpecialLwHitSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialAirLwHit, fighter_gobj.anim_frame, 1.0, FTPIKACHU_SPECIALLWHIT_STATUS_FLAGS)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x80152578
static func ftPikachuSpecialLwHitInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag1 = 0

	fp.proc_damage = Callable()

## 0x80152588
static func ftPikachuSpecialLwHitSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialLwHit, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftPikachuSpecialLwHitInitStatusVars(fighter_gobj)

## 0x801525C8
static func ftPikachuSpecialAirLwHitSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialAirLwHit, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftPikachuSpecialLwHitInitStatusVars(fighter_gobj)

	fp.physics.vel_air.y = FTPIKACHU_THUNDER_HITVEL_Y

## 0x80152620
static func ftPikachuSpecialAirLwEndProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommonfall, &"ftCommonFallSetStatus"))

## 0x80152644
static func ftPikachuSpecialLwEndProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftpikachuspeciallw, &"ftPikachuSpecialLwEndSwitchStatusAir"))

## 0x80152668
static func ftPikachuSpecialAirLwEndProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftpikachuspeciallw, &"ftPikachuSpecialAirLwEndSwitchStatusGround"))

## 0x8015268C
static func ftPikachuSpecialAirLwEndSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialLwEnd, fighter_gobj.anim_frame, 1.0, FTPIKACHU_SPECIALLWEND_STATUS_FLAGS)

## 0x801526CC
static func ftPikachuSpecialLwEndSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialAirLwEnd, fighter_gobj.anim_frame, 1.0, FTPIKACHU_SPECIALLWEND_STATUS_FLAGS)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x80152718
static func ftPikachuSpecialLwClearProcDamage(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_damage = Callable()

## 0x80152724
static func ftPikachuSpecialLwEndSetStatus(fighter_gobj) -> void:
	ftPikachuSpecialLwClearProcDamage(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialLwEnd, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80152764
static func ftPikachuSpecialAirLwEndSetStatus(fighter_gobj) -> void:
	ftPikachuSpecialLwClearProcDamage(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPikachuStatusSpecialAirLwEnd, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
