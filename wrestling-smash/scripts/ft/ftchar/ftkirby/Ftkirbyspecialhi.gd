## 1:1 port of src/ft/ftchar/ftkirby/ftkirbyspecialhi.c (ssb-decomp-re): Kirby's Final Cutter.
class_name Ftkirbyspecialhi
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80160BB0
static func ftKirbySpecialHiUpdateEffect(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 != 0:
		match fp.motion_vars.flags.flag1:
			1:
				if B(fp.is_effect_attach):
					Ftparam.ftParamProcStopEffect(fighter_gobj)
					fp.motion_vars.flags.flag1 = 0

			_:
				# while (TRUE) { syDebugPrintf(...); scManagerRunPrintGObjStatus(); } - the game halts
				# on the debug crash screen here. Port: report the error once and continue.
				Debug.syDebugPrintf("gcFighterSpecialHiEffectKirby : Error  Unknown value %d \n", fp.motion_vars.flags.flag1)
				push_error("gcFighterSpecialHiEffectKirby : Error  Unknown value %d" % fp.motion_vars.flags.flag1)
				return

	match fp.motion_vars.flags.flag2:
		0:
			pass

		1:
			if B(fp.is_effect_attach):
				Ftparam.ftParamProcStopEffect(fighter_gobj)
				fp.motion_vars.flags.flag2 = 0

		2:
			if Efmanager.efManagerKirbyCutterDrawMakeEffect(fighter_gobj) != null:
				fp.is_effect_attach = TRUE
				fp.motion_vars.flags.flag2 = 0

		3:
			if Efmanager.efManagerKirbyCutterUpMakeEffect(fighter_gobj) != null:
				fp.is_effect_attach = TRUE
				fp.motion_vars.flags.flag2 = 0

		4:
			if Efmanager.efManagerKirbyCutterDownMakeEffect(fighter_gobj) != null:
				fp.is_effect_attach = TRUE
				fp.motion_vars.flags.flag2 = 0

		5:
			if Efmanager.efManagerKirbyCutterTrailMakeEffect(fighter_gobj) != null:
				fp.is_effect_attach = TRUE
				fp.motion_vars.flags.flag2 = 0

		_:
			# while (TRUE) { syDebugPrintf(...); scManagerRunPrintGObjStatus(); } (see above)
			Debug.syDebugPrintf("gcFighterSpecialHiEffectKirby : Error  Unknown value %d \n", fp.motion_vars.flags.flag2)
			push_error("gcFighterSpecialHiEffectKirby : Error  Unknown value %d" % fp.motion_vars.flags.flag2)

## 0x80160D1C
static func ftKirbySpecialHiProcUpdate(fighter_gobj = null) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftkirbyspecialhi, &"ftKirbySpecialAirHiFallSetStatus"))

## 0x80160D40
static func ftKirbySpecialHiLandingProcUpdate(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos

	if fp.motion_vars.flags.flag0 != 0:
		fp.motion_vars.flags.flag0 = 0

		pos = Vector3(0.0, 0.0, 0.0)

		pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[FTKIRBY_FINALCUTTER_BEAM_SPAWN_JOINT], pos)

		if fp.lr == +1:
			pos.x += FTKIRBY_FINALCUTTER_OFF_X # Ternary doesn't match here, only if/else :(
		else:
			pos.x -= FTKIRBY_FINALCUTTER_OFF_X

		Wpkirbycutter.wpKirbyCutterMakeWeapon(fighter_gobj, pos)

	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommonwait, &"ftCommonWaitSetStatus"))

## 0x80160DF0
static func ftKirbySpecialHiProcPhysics(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	ftKirbySpecialHiUpdateEffect(fighter_gobj)
	Ftphysics.ftPhysicsApplyAirVelTransNYZ(fighter_gobj)

	if not B(Ftphysics.ftPhysicsCheckClampAirVelXDecMax(fp, attr)):
		Ftphysics.ftPhysicsClampAirVelXStickRange(fp, FTPHYSICS_AIRDRIFT_CLAMP_RANGE_MIN, attr.air_accel * FTKIRBY_FINALCUTTER_AIR_ACCEL_MUL, attr.air_speed_max_x)
		Ftphysics.ftPhysicsApplyAirVelXFriction(fp, attr)

## 0x80160E70
static func ftKirbySpecialHiLandingProcPhysics(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	ftKirbySpecialHiUpdateEffect(fighter_gobj)

	if fp.ga == nMPKineticsGround:
		Ftphysics.ftPhysicsApplyGroundVelTransN(fighter_gobj)

	else:
		Ftphysics.ftPhysicsApplyAirVelTransNYZ(fighter_gobj)

		if not B(Ftphysics.ftPhysicsCheckClampAirVelXDecMax(fp, attr)):
			Ftphysics.ftPhysicsClampAirVelXStickRange(fp, FTPHYSICS_AIRDRIFT_CLAMP_RANGE_MIN, attr.air_accel * FTKIRBY_FINALCUTTER_AIR_ACCEL_MUL, attr.air_speed_max_x)
			Ftphysics.ftPhysicsApplyAirVelXFriction(fp, attr)

## 0x80160F10
static func ftKirbySpecialAirHiProcPhysics(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	ftKirbySpecialHiUpdateEffect(fighter_gobj)

	fp.joints[nFTPartsJointTopN].scale.x = 0.8
	fp.joints[nFTPartsJointTopN].scale.y = 0.8
	fp.joints[nFTPartsJointTopN].scale.z = 0.8

	Ftphysics.ftPhysicsApplyAirVelTransNYZ(fighter_gobj)

	fp.joints[nFTPartsJointTopN].scale.x = 1.0
	fp.joints[nFTPartsJointTopN].scale.y = 1.0
	fp.joints[nFTPartsJointTopN].scale.z = 1.0

	if not B(Ftphysics.ftPhysicsCheckClampAirVelXDecMax(fp, attr)):
		Ftphysics.ftPhysicsClampAirVelXStickRange(fp, FTPHYSICS_AIRDRIFT_CLAMP_RANGE_MIN, attr.air_accel * FTKIRBY_FINALCUTTER_AIR_ACCEL_MUL, attr.air_speed_max_x)
		Ftphysics.ftPhysicsApplyAirVelXFriction(fp, attr)

## 0x80160FD8
static func ftKirbySpecialAirHiFallProcPhysics(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	ftKirbySpecialHiUpdateEffect(fighter_gobj)

	if not B(Ftphysics.ftPhysicsCheckClampAirVelXDecMax(fp, attr)):
		Ftphysics.ftPhysicsClampAirVelXStickRange(fp, FTPHYSICS_AIRDRIFT_CLAMP_RANGE_MIN, attr.air_accel * FTKIRBY_FINALCUTTER_AIR_ACCEL_MUL, attr.air_speed_max_x)
		Ftphysics.ftPhysicsApplyAirVelXFriction(fp, attr)

## 0x8016104C
static func ftKirbySpecialHiProcMap(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsGround:
		if not B(Mpcommon.mpCommonCheckFighterOnEdge(fighter_gobj)):
			fp.ga = nMPKineticsAir
	else:
		if B(Mpcommon.mpCommonCheckFighterCeilHeavyCliff(fighter_gobj)):
			if fp.coll_data.mask_stat & MAP_FLAG_CLIFF_MASK:
				Ftcommoncliffcatchwait.ftCommonCliffCatchSetStatus(fighter_gobj)

			elif (fp.coll_data.mask_stat & MAP_FLAG_FLOOR) and (fp.physics.vel_air.y < 0.0):
				Mpcommon.mpCommonSetFighterGround(fp)
				ftKirbySpecialHiLandingSetStatus(fighter_gobj)

## 0x80161104
static func ftKirbySpecialAirHiFallProcMap(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if B(Mpcommon.mpCommonCheckFighterCeilHeavyCliff(fighter_gobj)):
		if fp.coll_data.mask_stat & MAP_FLAG_FLOOR:
			Mpcommon.mpCommonSetFighterGround(fp)
			Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialHiLanding, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

			fp.proc_lagstart = Callable(Ftparam, &"ftParamProcPauseEffect")
			fp.proc_lagend = Callable(Ftparam, &"ftParamProcResumeEffect")

		elif fp.coll_data.mask_stat & MAP_FLAG_CLIFF_MASK:
			Ftcommoncliffcatchwait.ftCommonCliffCatchSetStatus(fighter_gobj)

## 0x80161194
static func ftKirbySpecialHiProcStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag2 = 0
	fp.motion_vars.flags.flag1 = 0
	fp.motion_vars.flags.flag0 = 0

## 0x801611A8
static func ftKirbySpecialHiSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_status = Callable(Ftkirbyspecialhi, &"ftKirbySpecialHiProcStatus")

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialHi, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.proc_lagstart = Callable(Ftparam, &"ftParamProcPauseEffect")
	fp.proc_lagend = Callable(Ftparam, &"ftParamProcResumeEffect")

## 0x80161210
static func ftKirbySpecialHiLandingSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialHiLanding, 0.0, 1.0, FTSTATUS_PRESERVE_EFFECT)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.proc_lagstart = Callable(Ftparam, &"ftParamProcPauseEffect")
	fp.proc_lagend = Callable(Ftparam, &"ftParamProcResumeEffect")

## 0x80161270
static func ftKirbySpecialAirHiSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_status = Callable(Ftkirbyspecialhi, &"ftKirbySpecialHiProcStatus")

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirHi, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.proc_lagstart = Callable(Ftparam, &"ftParamProcPauseEffect")
	fp.proc_lagend = Callable(Ftparam, &"ftParamProcResumeEffect")

## 0x801612D8
static func ftKirbySpecialAirHiFallSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var vel_y_bak: float = fp.physics.vel_air.y

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirHiFall, 0.0, 1.0, FTSTATUS_PRESERVE_EFFECT)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.proc_lagstart = Callable(Ftparam, &"ftParamProcPauseEffect")
	fp.proc_lagend = Callable(Ftparam, &"ftParamProcResumeEffect")

	fp.jumps_used = fp.attr.jumps_max

	fp.physics.vel_air.y = vel_y_bak
