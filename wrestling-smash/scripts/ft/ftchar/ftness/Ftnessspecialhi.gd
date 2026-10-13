## Port of src/ft/ftchar/ftness/ftnessspecialhi.c (Ness up special: PK Thunder / PK Thunder Blast).
class_name Ftnessspecialhi
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

const FTNESS_SPECIALHISTART_STATUS_FLAGS = (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM)
const FTNESS_SPECIALHIHOLD_STATUS_FLAGS = (FTSTATUS_PRESERVE_RUMBLE | FTSTATUS_PRESERVE_LOOPSFX | FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM | FTSTATUS_PRESERVE_HIT)
const FTNESS_SPECIALHIEND_STATUS_FLAGS = (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM)
const FTNESS_SPECIALHI_STATUS_FLAGS = (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM | FTSTATUS_PRESERVE_HIT)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80153C50
static func ftNessSpecialHiDecThunderTimers(fp) -> void:
	if fp.status_vars.ness.specialhi.pkjibaku_delay != 0:
		fp.status_vars.ness.specialhi.pkjibaku_delay -= 1

	if fp.passive_vars.ness.is_thunder_destroy & TRUE:
		if fp.status_vars.ness.specialhi.pkthunder_end_delay != 0:
			fp.status_vars.ness.specialhi.pkthunder_end_delay -= 1

## 0x80153C88
static func ftNessSpecialHiMakePKThunder(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3
	var vel: Vector3

	pos.x = 0.0
	pos.y = 0.0
	pos.z = 0.0

	pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[FTNESS_PKTHUNDER_SPAWN_JOINT], pos)

	pos.z = 0.0

	vel.z = 0.0
	vel.y = FTNESS_PKTHUNDER_SPAWN_VEL_Y
	vel.x = 0.0

	fp.status_vars.ness.specialhi.pkthunder_gobj = Wpnesspkthunder.wpNessPKThunderHeadMakeWeapon(fighter_gobj, pos, vel)

## 0x80153CFC
static func ftNessSpecialHiCheckCollidePKThunder(fighter_gobj) -> int:
	var ft_pos_x: float
	var ft_pos_y: float
	var wp_pos_x: float
	var wp_pos_y: float
	var collide_x: float
	var collide_y: float
	var pkthunder_gobj
	var ip: Weapon
	var fp := ftGetStruct(fighter_gobj)

	pkthunder_gobj = fp.status_vars.ness.specialhi.pkthunder_gobj

	if fp.status_vars.ness.specialhi.pkjibaku_delay != 0:
		return FALSE

	if (fp.passive_vars.ness.is_thunder_destroy & TRUE) or (pkthunder_gobj == null):
		return FALSE

	ip = wpGetStruct(pkthunder_gobj)

	ft_pos_x = DObjGetStruct(fighter_gobj).translate.x
	wp_pos_x = DObjGetStruct(pkthunder_gobj).translate.x

	collide_x = -(ft_pos_x - wp_pos_x) if (ft_pos_x < wp_pos_x) else (ft_pos_x - wp_pos_x)

	if collide_x < FTNESS_PKTHUNDER_COLLIDE_X:
		ft_pos_y = DObjGetStruct(fighter_gobj).translate.y + 150.0
		wp_pos_y = DObjGetStruct(pkthunder_gobj).translate.y

		collide_y = -(ft_pos_y - wp_pos_y) if (ft_pos_y < wp_pos_y) else (ft_pos_y - wp_pos_y)

		if collide_y < FTNESS_PKTHUNDER_COLLIDE_Y:
			ip.weapon_vars.pkthunder.status = nWPNessPKThunderStatusCollide

			fp.status_vars.ness.specialhi.pkthunder_pos = DObjGetStruct(pkthunder_gobj).translate

			return TRUE

	return FALSE

## 0x80153E04
static func ftNessSpecialHiStartProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftnessspecialhi, &"ftNessSpecialHiHoldSetStatus"))

## 0x80153E28
static func ftNessSpecialAirHiStartProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftnessspecialhi, &"ftNessSpecialAirHiHoldSetStatus"))

## 0x80153E4C
static func ftNessSpecialHiProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.ness.specialhi.pkthunder_gravity_delay != 0:
		fp.status_vars.ness.specialhi.pkthunder_gravity_delay -= 1

	Ftphysics.ftPhysicsApplyGroundVelFriction(fighter_gobj)

## 0x80153E80
static func ftNessSpecialAirHiProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if fp.status_vars.ness.specialhi.pkthunder_gravity_delay != 0:
		fp.status_vars.ness.specialhi.pkthunder_gravity_delay -= 1
	else:
		Ftphysics.ftPhysicsApplyGravityClampTVel(fp, 0.5, attr.tvel_base)

	if Ftphysics.ftPhysicsCheckClampAirVelXDecMax(fp, attr) == FALSE:
		Ftphysics.ftPhysicsApplyAirVelXFriction(fp, attr)

## 0x80153EF8
static func ftNessSpecialHiStartProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftnessspecialhi, &"ftNessSpecialHiStartSwitchStatusAir"))

## 0x80153F1C
static func ftNessSpecialAirHiStartProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterCliff(fighter_gobj, Callable(Ftnessspecialhi, &"ftNessSpecialAirHiStartSwitchStatusGround"))

## 0x80153F40
static func ftNessSpecialAirHiStartSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialHiStart, fighter_gobj.anim_frame, 1.0, FTNESS_SPECIALHISTART_STATUS_FLAGS)

## 0x80153F80
static func ftNessSpecialHiStartSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialAirHiStart, fighter_gobj.anim_frame, 1.0, FTNESS_SPECIALHISTART_STATUS_FLAGS)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x80153FCC
static func ftNessSpecialHiInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.ness.specialhi.pkjibaku_delay = FTNESS_PKJIBAKU_DELAY
	fp.status_vars.ness.specialhi.pkthunder_end_delay = FTNESS_PKTHUNDER_END_DELAY
	fp.status_vars.ness.specialhi.pkthunder_gravity_delay = FTNESS_PKTHUNDER_GRAVITY_DELAY
	fp.passive_vars.ness.is_thunder_destroy = FALSE
	fp.passive_vars.ness.pkthunder_trail_id = 0

## 0x80153FF0
static func ftNessSpecialHiStartSetStatus(fighter_gobj) -> void:
	ftNessSpecialHiInitStatusVars(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialHiStart, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80154030
static func ftNessSpecialAirHiStartSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftNessSpecialHiInitStatusVars(fighter_gobj)

	fp.physics.vel_air.y = 0.0
	fp.physics.vel_air.x /= 2

	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialAirHiStart, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80154098
static func ftNessSpecialHiUpdatePKThunder(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var weapon_gobj = fp.status_vars.ness.specialhi.pkthunder_gobj

	if weapon_gobj == null:
		fp.passive_vars.ness.is_thunder_destroy |= TRUE

	fp.passive_vars.ness.pkthunder_trail_id += 1

	if fp.passive_vars.ness.pkthunder_trail_id >= FTNESS_PKTHUNDER_TRAIL_POS_COUNT:
		fp.passive_vars.ness.pkthunder_trail_id = 0

	ftNessSpecialHiDecThunderTimers(fp)

## 0x801540EC
static func ftNessSpecialHiHoldProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftNessSpecialHiUpdatePKThunder(fighter_gobj)

	if (fp.status_vars.ness.specialhi.pkjibaku_delay <= 0) and (fp.status_vars.ness.specialhi.pkthunder_end_delay <= 0) and (fp.passive_vars.ness.is_thunder_destroy & TRUE):
		ftNessSpecialHiEndSetStatus(fighter_gobj)

	elif ftNessSpecialHiCheckCollidePKThunder(fighter_gobj) != FALSE:
		ftNessSpecialHiJibakuSetStatus(fighter_gobj)

## 0x8015416C
static func ftNessSpecialAirHiHoldProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftNessSpecialHiUpdatePKThunder(fighter_gobj)

	if (fp.status_vars.ness.specialhi.pkjibaku_delay <= 0) and (fp.status_vars.ness.specialhi.pkthunder_end_delay <= 0) and (fp.passive_vars.ness.is_thunder_destroy & TRUE):
		ftNessSpecialAirHiEndSetStatus(fighter_gobj)

	elif ftNessSpecialHiCheckCollidePKThunder(fighter_gobj) != FALSE:
		ftNessSpecialAirHiJibakuSetStatus(fighter_gobj)

## 0x801541EC
static func ftNessSpecialHiHoldProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftnessspecialhi, &"ftNessSpecialHiHoldSwitchStatusAir"))

## 0x80154210
static func ftNessSpecialAirHiHoldProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterCliff(fighter_gobj, Callable(Ftnessspecialhi, &"ftNessSpecialAirHiHoldSwitchStatusGround"))

## 0x80154234
static func ftNessSpecialHiSetPKThunderDestroy(fighter_gobj) -> void: # Unused
	var fp := ftGetStruct(fighter_gobj)
	var weapon_gobj = fp.status_vars.ness.specialhi.pkthunder_gobj

	if not (fp.passive_vars.ness.is_thunder_destroy & TRUE) and (weapon_gobj != null):
		var wp := wpGetStruct(weapon_gobj)

		wp.weapon_vars.pkthunder.status = nWPNessPKThunderStatusDestroy

## 0x80154268
static func ftNessSpecialAirHiHoldSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialHiHold, fighter_gobj.anim_frame, 1.0, FTNESS_SPECIALHIHOLD_STATUS_FLAGS)

## 0x801542A8
static func ftNessSpecialHiHoldSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialAirHiHold, fighter_gobj.anim_frame, 1.0, FTNESS_SPECIALHIHOLD_STATUS_FLAGS)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x801542F4
static func ftNessSpecialHiHoldInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftNessSpecialHiMakePKThunder(fighter_gobj)

	if not fp.is_effect_attach and (Efmanager.efManagerNessPKThunderWaveMakeEffect(fighter_gobj) != null):
		fp.is_effect_attach = TRUE

	fp.jumps_used = fp.attr.jumps_max

## 0x8015435C
static func ftNessSpecialHiHoldSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialHiHold, 0.0, 1.0, FTSTATUS_PRESERVE_LOOPSFX)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftNessSpecialHiHoldInitStatusVars(fighter_gobj)

## 0x801543A0
static func ftNessSpecialAirHiHoldSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialAirHiHold, 0.0, 1.0, FTSTATUS_PRESERVE_LOOPSFX)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftNessSpecialHiHoldInitStatusVars(fighter_gobj)

## 0x801543E4
static func ftNessSpecialAirHiEndProcUpdate(fighter_gobj) -> void:
	if fighter_gobj.anim_frame <= 0.0:
		Ftcommonfallspecial.ftCommonFallSpecialSetStatus(fighter_gobj, FTNESS_PKTHUNDER_FALLSPECIAL_DRIFT, FALSE, TRUE, TRUE, FTNESS_PKTHUNDER_LANDING_LAG, FALSE)

## 0x80154438
static func ftNessSpecialHiEndProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftnessspecialhi, &"ftNessSpecialHiEndSwitchStatusAir"))

## 0x8015445C
static func ftNessSpecialAirHiEndProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterCliff(fighter_gobj, Callable(Ftnessspecialhi, &"ftNessSpecialAirHiEndSwitchStatusGround"))

## 0x80154480
static func ftNessSpecialAirHiEndSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialHiEnd, fighter_gobj.anim_frame, 1.0, FTNESS_SPECIALHIEND_STATUS_FLAGS)

## 0x801544C0
static func ftNessSpecialHiEndSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialAirHiEnd, fighter_gobj.anim_frame, 1.0, FTNESS_SPECIALHIEND_STATUS_FLAGS)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x8015450C
static func ftNessSpecialHiClearProcDamage(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_damage = Callable()

## 0x80154518
static func ftNessSpecialHiEndSetStatus(fighter_gobj) -> void:
	ftNessSpecialHiClearProcDamage(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialHiEnd, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80154558
static func ftNessSpecialAirHiEndSetStatus(fighter_gobj) -> void:
	ftNessSpecialHiClearProcDamage(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialAirHiEnd, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80154598
## (The decomp keeps a commented-out "fixed" rewrite of this function; the matching original is ported.)
static func ftNessSpecialHiCollideWallPhysics(fighter_gobj, coll_data: MPCollData) -> void:
	var angle_old: float
	var angle_new: float = 0.0  # C: left uninitialized if neither wall flag is set (never happens in practice)
	var fp := ftGetStruct(fighter_gobj)

	angle_old = fp.status_vars.ness.specialhi.pkjibaku_angle if (fp.lr == +1) else (F_CST_DTOR32(180.0) - fp.status_vars.ness.specialhi.pkjibaku_angle)

	if angle_old > F_CST_DTOR32(360.0):
		angle_old -= F_CST_DTOR32(360.0)

	if coll_data.mask_curr & MAP_FLAG_LWALL:
		angle_new = syUtilsArcTan2(coll_data.lwall_angle.y, coll_data.lwall_angle.x)

		if angle_new > F_CST_DTOR32(360.0):
			angle_new -= F_CST_DTOR32(360.0)

		angle_new = (angle_new + F_CST_DTOR32(90.0)) if ((angle_old + F_CST_DTOR32(180.0)) < angle_new) else (angle_new + F_CST_DTOR32(-90.0))

	if coll_data.mask_curr & MAP_FLAG_RWALL:
		angle_new = syUtilsArcTan2(coll_data.rwall_angle.y, coll_data.rwall_angle.x)

		if angle_new > F_CST_DTOR32(360.0):
			angle_new -= F_CST_DTOR32(360.0)

		angle_new = (angle_new + F_CST_DTOR32(90.0)) if ((angle_new + F_CST_DTOR32(180.0)) < angle_old) else (angle_new + F_CST_DTOR32(-90.0))

	# WARNING: Even though this function only runs if Ness collides with an LWALL/RWALL, angle_new is uninitialized if both conditions fail somehow. Cosmic bit-flip?
	fp.physics.vel_air = syVectorRotate3D(fp.physics.vel_air, SYVECTOR_AXIS_Z, angle_new - (fp.status_vars.ness.specialhi.pkjibaku_angle * fp.lr))

	fp.status_vars.ness.specialhi.pkjibaku_angle = syUtilsArcTan2(fp.physics.vel_air.y, fp.physics.vel_air.x * fp.lr)

## 0x80154758
static func ftNessSpecialHiUpdateModelPitch(fighter_gobj) -> void: # Update joint's X rotation axis
	var fp := ftGetStruct(fighter_gobj)

	fp.joints[4].rotate.x = (syUtilsArcTan2(fp.physics.vel_air.x, fp.physics.vel_air.y) * fp.lr) - F_CST_DTOR32(90.0)

	Ftparam.ftParamsUpdateFighterPartsTransformAll(fp.joints[4])

## 0x801547B8
static func ftNessSpecialHiJibakuProcUpdate(fighter_gobj) -> void: # Grounded PK Thunder Blast
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.ness.specialhi.pkjibaku_anim_length -= 1

	if fp.status_vars.ness.specialhi.pkjibaku_anim_length == 0:
		ftNessSpecialHiEndSetStatus(fighter_gobj)

## 0x801547EC
static func ftNessSpecialAirHiJibakuProcUpdate(fighter_gobj) -> void: # Aerial PK Thunder Blast
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.ness.specialhi.pkjibaku_anim_length -= 1

	if fp.status_vars.ness.specialhi.pkjibaku_anim_length == 0:
		ftNessSpecialAirHiEndSetStatus(fighter_gobj)

## 0x80154820
static func ftNessSpecialHiJibakuProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.physics.vel_ground.x > 0.0:
		fp.physics.vel_ground.x -= FTNESS_PKJIBAKU_DECELERATE

	Ftphysics.ftPhysicsApplyGroundVelTransferAir(fighter_gobj)
	ftNessSpecialHiUpdateModelPitch(fighter_gobj)

## 0x80154874
static func ftNessSpecialAirHiJibakuProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var vel_x_bak: float = fp.physics.vel_air.x
	var vel_y_bak: float = fp.physics.vel_air.y

	fp.physics.vel_air.x -= (FTNESS_PKJIBAKU_DECELERATE * __cosf(fp.status_vars.ness.specialhi.pkjibaku_angle) * fp.lr)
	fp.physics.vel_air.y -= (FTNESS_PKJIBAKU_DECELERATE * __sinf(fp.status_vars.ness.specialhi.pkjibaku_angle))

	if ABSF(fp.physics.vel_air.x) > ABSF(vel_x_bak):
		fp.physics.vel_air.x = vel_x_bak

	if ABSF(fp.physics.vel_air.y) > ABSF(vel_y_bak):
		fp.physics.vel_air.y = vel_y_bak

	ftNessSpecialHiUpdateModelPitch(fighter_gobj)

## 0x801549B0
static func ftNessSpecialHiProcPass(fighter_gobj) -> int: # Check if Ness can pass through platforms, TRUE actually denies?
	var fp := ftGetStruct(fighter_gobj)

	if not (fp.coll_data.floor_flags & MAP_VERTEX_COLL_PASS) or (fp.status_vars.ness.specialhi.pkjibaku_anim_length <= FTNESS_PKJIBAKU_PASS_FRAME_END):
		return TRUE
	else:
		return FALSE

## 0x801549FC
static func ftNessSpecialHiJibakuProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if Mpcommon.mpCommonCheckFighterOnFloor(fighter_gobj) == FALSE:
		if fp.coll_data.mask_curr & (MAP_FLAG_RWALL | MAP_FLAG_LWALL):
			Mpcommon.mpCommonSetFighterAir(fp)
			ftNessSpecialAirHiEndSetStatus(fighter_gobj)
		else:
			ftNessSpecialHiJibakuSwitchStatusAir(fighter_gobj)

	elif fp.coll_data.mask_curr & (MAP_FLAG_CEIL | MAP_FLAG_RWALL | MAP_FLAG_LWALL):
		fp.physics.vel_ground.x = 0.0
		Ftcommondownwaitbounce.ftCommonDownBounceSetStatus(fighter_gobj)

## 0x80154A8C
static func ftNessSpecialAirHiJibakuProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3

	if Mpcommon.mpCommonCheckFighterPassCliff(fighter_gobj, Callable(Ftnessspecialhi, &"ftNessSpecialHiProcPass")) != FALSE:
		if fp.coll_data.mask_stat & MAP_FLAG_CLIFF_MASK:
			Ftcommoncliffcatchwait.ftCommonCliffCatchSetStatus(fighter_gobj)

		elif syVectorAngleDiff3D(fp.coll_data.floor_angle, fp.physics.vel_air) > FTNESS_PKJIBAKU_HALT_ANGLE:
			fp.physics.vel_air.x = 0.0
			fp.physics.vel_air.y = 0.0

			Mpcommon.mpCommonSetFighterGround(fp)
			Ftcommondownwaitbounce.ftCommonDownBounceSetStatus(fighter_gobj)

		else:
			ftNessSpecialAirHiJibakuSwitchStatusGround(fighter_gobj)

		return

	pos.x = DObjGetStruct(fighter_gobj).translate.x
	pos.y = DObjGetStruct(fighter_gobj).translate.y
	pos.z = 0.0

	if fp.coll_data.mask_curr & MAP_FLAG_CEIL:
		if syVectorAngleDiff3D(fp.coll_data.ceil_angle, fp.physics.vel_air) > FTNESS_PKJIBAKU_HALT_ANGLE:
			pos.y += fp.coll_data.map_coll.top

			ftNessSpecialAirHiJibakuBoundSetStatus(fighter_gobj, fp.coll_data.ceil_angle, pos)

	if fp.coll_data.mask_curr & MAP_FLAG_LWALL:
		if syVectorAngleDiff3D(fp.coll_data.lwall_angle, fp.physics.vel_air) > FTNESS_PKJIBAKU_HALT_ANGLE:
			pos.x += fp.coll_data.map_coll.width
			pos.y += fp.coll_data.map_coll.center

			ftNessSpecialAirHiJibakuBoundSetStatus(fighter_gobj, fp.coll_data.lwall_angle, pos)
		else:
			ftNessSpecialHiCollideWallPhysics(fighter_gobj, fp.coll_data)

	if fp.coll_data.mask_curr & MAP_FLAG_RWALL:
		if syVectorAngleDiff3D(fp.coll_data.rwall_angle, fp.physics.vel_air) > FTNESS_PKJIBAKU_HALT_ANGLE:
			pos.x -= fp.coll_data.map_coll.width
			pos.y += fp.coll_data.map_coll.center

			ftNessSpecialAirHiJibakuBoundSetStatus(fighter_gobj, fp.coll_data.rwall_angle, pos)
		else:
			ftNessSpecialHiCollideWallPhysics(fighter_gobj, fp.coll_data)

## 0x80154CBC
static func ftNessSpecialAirHiJibakuSwitchStatusGround(fighter_gobj) -> void:
	var frame_begin: float

	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))

	frame_begin = fighter_gobj.anim_frame

	if frame_begin == 0.0:
		frame_begin = 1.0

	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialHiJibaku, frame_begin, 1.0, FTNESS_SPECIALHI_STATUS_FLAGS) # Change Action State to PK Thunder Blast

## 0x80154D1C
static func ftNessSpecialHiJibakuSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var frame_begin: float

	Mpcommon.mpCommonSetFighterAir(fp)

	frame_begin = fighter_gobj.anim_frame

	if frame_begin == 0.0:
		frame_begin = 1.0

	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialAirHiJibaku, frame_begin, 1.0, FTNESS_SPECIALHI_STATUS_FLAGS)

	fp.status_vars.ness.specialhi.pkjibaku_angle = syUtilsArcTan2(fp.physics.vel_air.y, fp.physics.vel_air.x * fp.lr)

	fp.jumps_used = fp.attr.jumps_max

## 0x80154DBC
static func ftNessSpecialHiJibakuInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.ness.specialhi.pkjibaku_anim_length = FTNESS_PKJIBAKU_ANIM_LENGTH

	ftNessSpecialHiUpdateModelPitch(fighter_gobj)

	fp.proc_damage = Callable()

	fp.jumps_used = fp.attr.jumps_max

## 0x80154DFC
static func ftNessSpecialHiJibakuSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var angle_diff: float
	var pos: Vector3
	var is_setair := false  # C: goto setair

	if fp.coll_data.floor_flags & MAP_VERTEX_COLL_PASS:
		is_setair = true
	else:
		pos.x = DObjGetStruct(fighter_gobj).translate.x - fp.status_vars.ness.specialhi.pkthunder_pos.x
		pos.y = (DObjGetStruct(fighter_gobj).translate.y + 150.0) - fp.status_vars.ness.specialhi.pkthunder_pos.y
		pos.z = 0.0

		angle_diff = syVectorAngleDiff3D(fp.coll_data.floor_angle, pos)

		if angle_diff < F_CST_DTOR32(90.0):
			is_setair = true

		elif angle_diff > F_CST_DTOR32(155.0):
			# setdown: (2.3561945F)
			Ftcommondownwaitbounce.ftCommonDownBounceSetStatus(fighter_gobj)
			return

		else:
			fp.lr = +1 if (pos.x >= 0) else -1

			if pos.x < 0:
				pos.x = -pos.x

			fp.physics.vel_ground.x = FTNESS_PKJIBAKU_VEL

			ftNessSpecialHiJibakuInitStatusVars(fighter_gobj)
			Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialHiJibaku, 0.0, 1.0, FTSTATUS_PRESERVE_COLANIM)
			Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
			return

	if is_setair:
		# setair:
		Mpcommon.mpCommonSetFighterAir(fp)
		ftNessSpecialAirHiJibakuSetStatus(fighter_gobj)

## 0x80154F54
static func ftNessSpecialAirHiJibakuSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var dobj := DObjGetStruct(fighter_gobj)
	var dist_x: float = dobj.translate.x - fp.status_vars.ness.specialhi.pkthunder_pos.x
	var dist_y: float = (dobj.translate.y + 150.0) - fp.status_vars.ness.specialhi.pkthunder_pos.y

	fp.lr = +1 if (dist_x >= 0.0) else -1

	fp.status_vars.ness.specialhi.pkjibaku_angle = syUtilsArcTan2(dist_y, fp.lr * dist_x)

	fp.physics.vel_air.x = (__cosf(fp.status_vars.ness.specialhi.pkjibaku_angle) * FTNESS_PKJIBAKU_VEL * fp.lr)
	fp.physics.vel_air.y = (__sinf(fp.status_vars.ness.specialhi.pkjibaku_angle) * FTNESS_PKJIBAKU_VEL)

	ftNessSpecialHiJibakuInitStatusVars(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialAirHiJibaku, 0.0, 1.0, FTSTATUS_PRESERVE_COLANIM)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80155058
static func ftNessSpecialAirHiJibakuBoundProcUpdate(fighter_gobj) -> void:
	if fighter_gobj.anim_frame <= 0.0:
		Ftcommonfallspecial.ftCommonFallSpecialSetStatus(fighter_gobj, FTNESS_PKTHUNDER_FALLSPECIAL_DRIFT, FALSE, TRUE, TRUE, FTNESS_PKTHUNDER_LANDING_LAG, FALSE)

## 0x801550AC
static func ftNessSpecialAirHiJibakuBoundProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if Mpcommon.mpCommonCheckFighterCliff(fighter_gobj) != FALSE:
		if fp.coll_data.mask_stat & MAP_FLAG_CLIFF_MASK:
			Ftcommoncliffcatchwait.ftCommonCliffCatchSetStatus(fighter_gobj)
		else:
			Mpcommon.mpCommonSetFighterGround(fp)
			Ftcommondownwaitbounce.ftCommonDownBounceSetStatus(fighter_gobj)

## 0x80155114
## angle / pos are read-only Vec3f* inputs (C passes &fp->coll_data.*_angle and a local).
static func ftNessSpecialAirHiJibakuBoundSetStatus(fighter_gobj, angle: Vector3, pos: Vector3) -> void:
	var fp := ftGetStruct(fighter_gobj)

	# Vec3f *vel = &fp->physics.vel_air;
	fp.physics.vel_air = Lbcommon.lbCommonReflect2D(fp.physics.vel_air, angle) # writes *vel, returns it
	fp.physics.vel_air = Lbcommon.lbCommonScale2D(fp.physics.vel_air, FTNESS_PKJIBAKU_REBOUND_VEL_MAG) # writes *vel, returns it
	Lbcommon.lbCommonMag2D(fp.physics.vel_air) # return value unused in C
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

	fp.lr = +1 if (fp.physics.vel_air.x < 0.0) else -1

	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialAirHiBound, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	Efmanager.efManagerImpactWaveMakeEffect(pos, SYVECTOR_AXIS_Z, syUtilsArcTan2(-angle.x, angle.y))
	Efmanager.efManagerQuakeMakeEffect(2)
