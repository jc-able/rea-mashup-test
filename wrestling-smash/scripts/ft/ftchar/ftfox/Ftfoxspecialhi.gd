## Port of src/ft/ftchar/ftfox/ftfoxspecialhi.c (Fox up special: Fire Fox).
class_name Ftfoxspecialhi
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8015BD00
static func ftFoxSpecialHiStartProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftfoxspecialhi, &"ftFoxSpecialHiHoldSetStatus"))

## 0x8015BD24
static func ftFoxSpecialAirHiStartProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftfoxspecialhi, &"ftFoxSpecialAirHiHoldSetStatus"))

## 0x8015BD48
static func ftFoxSpecialAirHiStartProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if fp.status_vars.fox.specialhi.gravity_delay != 0:
		fp.status_vars.fox.specialhi.gravity_delay -= 1
	else:
		Ftphysics.ftPhysicsApplyGravityClampTVel(fp, 0.5, attr.tvel_base)

	if Ftphysics.ftPhysicsCheckClampAirVelXDecMax(fp, attr) == FALSE:
		Ftphysics.ftPhysicsApplyAirVelXFriction(fp, attr)

## 0x8015BDC0
static func ftFoxSpecialHiStartProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftfoxspecialhi, &"ftFoxSpecialHiStartSwitchStatusAir"))

## 0x8015BDE4
static func ftFoxSpecialAirHiStartProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftfoxspecialhi, &"ftFoxSpecialAirHiStartSwitchStatusGround"))

## 0x8015BE08
static func ftFoxSpecialAirHiStartSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialHiStart, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_COLANIM)

## 0x8015BE48
static func ftFoxSpecialHiStartSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialAirHiStart, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_COLANIM)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x8015BE94
static func ftFoxSpecialHiHoldProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.fox.specialhi.launch_delay -= 1

	if fp.status_vars.fox.specialhi.launch_delay == 0:
		if fp.ga == nMPKineticsAir:
			ftFoxSpecialAirHiSetStatusFromGround(fighter_gobj)
		else:
			ftFoxSpecialHiDecideSetStatus(fighter_gobj)

## 0x8015BEE8
static func ftFoxSpecialHiHoldProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftfoxspecialhi, &"ftFoxSpecialHiHoldSwitchStatusAir"))

## 0x8015BF0C
static func ftFoxSpecialAirHiHoldProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftfoxspecialhi, &"ftFoxSpecialAirHiHoldSwitchStatusGround"))

## 0x8015BF30
static func ftFoxSpecialAirHiHoldSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialHiHold, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_RUMBLE | FTSTATUS_PRESERVE_COLANIM))

## 0x8015BF70
static func ftFoxSpecialHiHoldSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialAirHiHold, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_RUMBLE | FTSTATUS_PRESERVE_COLANIM))
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x8015BFBC
static func ftFoxSpecialHiHoldInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	fp.status_vars.fox.specialhi.launch_delay = FTFOX_FIREFOX_LAUNCH_DELAY

## 0x8015BFCC
static func ftFoxSpecialHiHoldSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialHiHold, 0.0, 1.0, FTSTATUS_PRESERVE_COLANIM)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftFoxSpecialHiHoldInitStatusVars(fighter_gobj)

## 0x8015C010
static func ftFoxSpecialAirHiHoldSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialAirHiHold, 0.0, 1.0, FTSTATUS_PRESERVE_COLANIM)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftFoxSpecialHiHoldInitStatusVars(fighter_gobj)

## 0x8015C054
static func ftFoxSpecialHiUpdateModelPitch(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.joints[4].rotate.x = (syUtilsArcTan2(fp.physics.vel_air.x, fp.physics.vel_air.y) * fp.lr) - F_CST_DTOR32(90.0)
	Ftparam.ftParamsUpdateFighterPartsTransformAll(fp.joints[4])

## 0x8015C0B4
static func ftFoxSpecialHiProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.fox.specialhi.anim_frames -= 1

	if fp.status_vars.fox.specialhi.anim_frames == 0:
		if fp.ga == nMPKineticsAir:
			ftFoxSpecialAirHiEndSetStatus(fighter_gobj)
		else:
			ftFoxSpecialHiEndSetStatus(fighter_gobj)

## 0x8015C108
static func ftFoxSpecialHiProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.fox.specialhi.decelerate_wait += 1

	if fp.status_vars.fox.specialhi.decelerate_wait >= FTFOX_FIREFOX_DECELERATE_DELAY:
		Ftphysics.ftPhysicsSetGroundVelFriction(fp, FTFOX_FIREFOX_DECELERATE_VEL)

	Ftphysics.ftPhysicsSetGroundVelTransferAir(fighter_gobj)

## 0x8015C15C
static func ftFoxSpecialAirHiProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.fox.specialhi.decelerate_wait += 1

	if fp.status_vars.fox.specialhi.decelerate_wait >= FTFOX_FIREFOX_DECELERATE_DELAY:
		fp.physics.vel_air.x -= (FTFOX_FIREFOX_DECELERATE_VEL * __cosf(fp.status_vars.fox.specialhi.angle) * fp.lr)
		fp.physics.vel_air.y -= (FTFOX_FIREFOX_DECELERATE_VEL * __sinf(fp.status_vars.fox.specialhi.angle))

	ftFoxSpecialHiUpdateModelPitch(fighter_gobj)

## 0x8015C1F4
static func ftFoxSpecialHiProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.fox.specialhi.pass_timer += 1

	if Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftfoxspecialhi, &"ftFoxSpecialAirHiSetStatus")) != FALSE:
		fp.status_vars.fox.specialhi.angle = syUtilsArcTan2(-fp.coll_data.floor_angle.x * fp.lr, fp.coll_data.floor_angle.y)

## 0x8015C264
static func ftFoxSpecialHiProcPass(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if not (fp.coll_data.floor_flags & MAP_VERTEX_COLL_PASS) or (fp.status_vars.fox.specialhi.pass_timer >= 15):
		return TRUE
	else:
		return FALSE

## 0x8015C29C
static func ftFoxSpecialAirHiProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var mask: int
	var r: Dictionary
	var is_coll_end := false   # C: goto coll_end

	fp.status_vars.fox.specialhi.pass_timer += 1

	if Mpcommon.mpCommonCheckFighterPass(fighter_gobj, Callable(Ftfoxspecialhi, &"ftFoxSpecialHiProcPass")) != FALSE:
		mask = ((fp.coll_data.mask_prev ^ fp.coll_data.mask_curr) & fp.coll_data.mask_curr & MAP_FLAG_FLOOR) & 0xFFFF

		var is_adjust := FALSE
		if mask & MAP_FLAG_FLOOR:
			r = Lbcommon.lbCommonCheckAdjustSim2D(fp.physics.vel_air, fp.coll_data.floor_angle, FTFOX_FIREFOX_BOUND_ANGLE)
			fp.physics.vel_air = r.a
			is_adjust = r.ret
		if not (mask & MAP_FLAG_FLOOR) or (is_adjust == FALSE):
			if syVectorAngleDiff3D(fp.coll_data.floor_angle, fp.physics.vel_air) > F_CST_DTOR32(110.0): # 1.9198622F
				ftFoxSpecialAirHiBoundSetStatus(fighter_gobj)
			else:
				ftFoxSpecialHiEndSetStatus(fighter_gobj)
			return
		is_coll_end = true
	else:
		mask = ((fp.coll_data.mask_prev ^ fp.coll_data.mask_curr) & fp.coll_data.mask_curr & (MAP_FLAG_CEIL | MAP_FLAG_RWALL | MAP_FLAG_LWALL)) & 0xFFFF

		if mask & MAP_FLAG_CEIL:
			r = Lbcommon.lbCommonCheckAdjustSim2D(fp.physics.vel_air, fp.coll_data.ceil_angle, FTFOX_FIREFOX_BOUND_ANGLE)
			fp.physics.vel_air = r.a
			if r.ret != FALSE:
				is_coll_end = true
		elif mask & MAP_FLAG_LWALL:
			r = Lbcommon.lbCommonCheckAdjustSim2D(fp.physics.vel_air, fp.coll_data.lwall_angle, FTFOX_FIREFOX_BOUND_ANGLE)
			fp.physics.vel_air = r.a
			if r.ret != FALSE:
				is_coll_end = true
		elif mask & MAP_FLAG_RWALL:
			r = Lbcommon.lbCommonCheckAdjustSim2D(fp.physics.vel_air, fp.coll_data.rwall_angle, FTFOX_FIREFOX_BOUND_ANGLE)
			fp.physics.vel_air = r.a
			if r.ret != FALSE:
				is_coll_end = true

	if is_coll_end:
		# coll_end:
		fp.lr = +1 if (fp.physics.vel_air.x >= 0.0) else -1

		fp.joints[nFTPartsJointTopN].rotate.y = fp.lr * F_CST_DTOR32(90.0)

		fp.status_vars.fox.specialhi.angle = syUtilsArcTan2(fp.physics.vel_air.y, fp.physics.vel_air.x * fp.lr)

		ftFoxSpecialHiUpdateModelPitch(fighter_gobj)

## 0x8015C46C
static func ftFoxSpecialAirHiSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialAirHi, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_COLANIM)

	fp.jumps_used = attr.jumps_max

## 0x8015C4C8
static func ftFoxSpecialHiInitStatusVars(fp) -> void:
	fp.status_vars.fox.specialhi.anim_frames = FTFOX_FIREFOX_TRAVEL_TIME
	fp.status_vars.fox.specialhi.decelerate_wait = 0
	fp.status_vars.fox.specialhi.pass_timer = 0

## 0x8015C4DC
static func ftFoxSpecialHiDecideSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var angle: Vector3

	if (ABS(fp.input.pl.stick_range.x) + ABS(fp.input.pl.stick_range.y) >= FTFOX_FIREFOX_ANGLE_STICK_THRESHOLD) and not (fp.coll_data.floor_flags & MAP_VERTEX_COLL_PASS):
		angle.x = fp.input.pl.stick_range.x
		angle.y = fp.input.pl.stick_range.y
		angle.z = 0.0

		if not (syVectorAngleDiff3D(fp.coll_data.floor_angle, angle) < F_CST_DTOR32(90.0)):
			Ftparam.ftParamSetStickLR(fp)
			Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialHi, 0.0, 1.0, FTSTATUS_PRESERVE_COLANIM)
			ftFoxSpecialHiInitStatusVars(fp)

			fp.physics.vel_ground.x = 115.0
			fp.status_vars.fox.specialhi.angle = syUtilsArcTan2(-fp.coll_data.floor_angle.x * fp.lr, fp.coll_data.floor_angle.y)
			return
		# else: goto setair
	# setair:
	Mpcommon.mpCommonSetFighterAir(fp)
	ftFoxSpecialAirHiSetStatusFromGround(fighter_gobj)

## 0x8015C60C
static func ftFoxSpecialAirHiSetStatusFromGround(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if ABS(fp.input.pl.stick_range.x) + ABS(fp.input.pl.stick_range.y) >= FTFOX_FIREFOX_ANGLE_STICK_THRESHOLD:
		if ABS(fp.input.pl.stick_range.x) >= FTFOX_FIREFOX_MODEL_STICK_THRESHOLD:
			Ftparam.ftParamSetStickLR(fp)
		fp.status_vars.fox.specialhi.angle = syUtilsArcTan2(fp.input.pl.stick_range.y, fp.input.pl.stick_range.x * fp.lr)
	else:
		fp.status_vars.fox.specialhi.angle = F_CST_DTOR32(90.0)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialAirHi, 0.0, 1.0, FTSTATUS_PRESERVE_COLANIM)
	ftFoxSpecialHiInitStatusVars(fp)

	fp.physics.vel_air.x = (__cosf(fp.status_vars.fox.specialhi.angle) * FTFOX_FIREFOX_VEL * fp.lr)
	fp.physics.vel_air.y = (__sinf(fp.status_vars.fox.specialhi.angle) * FTFOX_FIREFOX_VEL)

	ftFoxSpecialHiUpdateModelPitch(fighter_gobj)

	fp.jumps_used = attr.jumps_max

## 0x8015C750
static func ftFoxSpecialAirHiEndProcUpdate(fighter_gobj) -> void:
	if fighter_gobj.anim_frame <= 0.0:
		Ftcommonfallspecial.ftCommonFallSpecialSetStatus(fighter_gobj, FTFOX_FIREFOX_AIR_DRIFT, FALSE, TRUE, FALSE, FTFOX_FIREFOX_LANDING_LAG, TRUE)

## 0x8015C7A4
static func ftFoxSpecialHiEndProcPhysics(fighter_gobj) -> void:
	Ftphysics.ftPhysicsSetGroundVelFriction(ftGetStruct(fighter_gobj), FTFOX_FIREFOX_DECELERATE_END)
	Ftphysics.ftPhysicsSetGroundVelTransferAir(fighter_gobj)

## 0x8015C7D4
static func ftFoxSpecialAirHiEndProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterCliff(fighter_gobj, Callable(Ftfoxspecialhi, &"ftFoxSpecialAirHiEndSwitchStatusGround"))

## 0x8015C7F8
static func ftFoxSpecialAirHiEndSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialHiEnd, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_COLANIM)

## 0x8015C838
static func ftFoxSpecialHiEndSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsAir:
		Mpcommon.mpCommonSetFighterGround(fp)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialHiEnd, 0.0, 1.0, FTSTATUS_PRESERVE_COLANIM)

## 0x8015C88C
static func ftFoxSpecialAirHiEndSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialAirHiEnd, 0.0, 1.0, FTSTATUS_PRESERVE_COLANIM)

## 0x8015C8BC
static func ftFoxSpecialAirHiBoundProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.motion_vars.flags.flag1 != 0) and (fp.ga == nMPKineticsAir):
		Ftcommonfallspecial.ftCommonFallSpecialSetStatus(fighter_gobj, FTFOX_FIREFOX_AIR_DRIFT, FALSE, TRUE, FALSE, FTFOX_FIREFOX_LANDING_LAG, TRUE)

	elif fighter_gobj.anim_frame <= 0.0:
		if fp.ga == nMPKineticsAir:
			Ftcommonfallspecial.ftCommonFallSpecialSetStatus(fighter_gobj, FTFOX_FIREFOX_AIR_DRIFT, FALSE, TRUE, FALSE, FTFOX_FIREFOX_LANDING_LAG, TRUE)
		else:
			Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)

## 0x8015C97C
static func ftFoxSpecialAirHiBoundProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if fp.ga == nMPKineticsAir:
		Ftphysics.ftPhysicsApplyAirVelTransNYZ(fighter_gobj)

		if Ftphysics.ftPhysicsCheckClampAirVelXDecMax(fp, attr) == FALSE:
			Ftphysics.ftPhysicsApplyAirVelXFriction(fp, attr)
	else:
		Ftphysics.ftPhysicsApplyGroundVelFriction(fighter_gobj)

## 0x8015C9E8
static func ftFoxSpecialAirHiBoundProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsAir:
		if Mpcommon.mpCommonCheckFighterCliff(fighter_gobj) != FALSE:
			if fp.coll_data.mask_stat & MAP_FLAG_CLIFF_MASK:
				Ftcommoncliffcatchwait.ftCommonCliffCatchSetStatus(fighter_gobj)
			else:
				Mpcommon.mpCommonSetFighterGround(fp)
	else:
		Mpcommon.mpCommonSetFighterFallOnGroundBreak(fighter_gobj)

## 0x8015CA64
static func ftFoxSpecialAirHiBoundSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialAirHiBound, 0.0, 1.0, FTSTATUS_PRESERVE_COLANIM)

	fp.motion_vars.flags.flag1 = FALSE

## 0x8015CAA4
static func ftFoxSpecialHiStartInitGravity(fp) -> void:
	fp.status_vars.fox.specialhi.gravity_delay = FTFOX_FIREFOX_GRAVITY_DELAY

## 0x8015CAB0
static func ftFoxSpecialHiStartSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialHiStart, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftFoxSpecialHiStartInitGravity(fp)

	fp.physics.vel_ground.x /= 2

## 0x8015CB10
static func ftFoxSpecialAirHiStartSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialAirHiStart, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftFoxSpecialHiStartInitGravity(fp)

	fp.physics.vel_air.y = 0.0
	fp.physics.vel_air.x /= 2
