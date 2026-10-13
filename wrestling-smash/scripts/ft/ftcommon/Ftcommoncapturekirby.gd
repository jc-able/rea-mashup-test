## 1:1 port of src/ft/ftcommon/ftcommoncapturekirby.c (ssb-decomp-re): CaptureKirby (being inhaled),
## CaptureWaitKirby (inside Kirby), and the ThrownKirbyStar / ThrownCopyStar statuses (spat out as a star).
class_name Ftcommoncapturekirby
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x80188700 - FTThrowReleaseDesc { 361, 100, 90, 0 }
static var dFTCommonCaptureKirbyKnockbackCatch: Dictionary = {"angle": 361, "knockback_scale": 100, "knockback_weight": 90, "knockback_base": 0}

## 0x80188710 - FTThrowReleaseDesc { 80, 100, 60, 0 }
static var dFTCommonCaptureKirbyKnockbackCapture: Dictionary = {"angle": 80, "knockback_scale": 100, "knockback_weight": 60, "knockback_base": 0}

## FTKirbyCopy copy[] = lbRelocGetFileData(FTKirbyCopy*, gFTDataKirbyMainMotion, &llKirbyMainMotionSpecialNFTKirbyCopy)
## Transcribed from src/relocData/228_KirbyMainMotion.c dKirbyMainMotion_0x0000[27] (indexed by FTKind):
## {copy_id, copy_modelpart_id, effect_scale, star_damage}.
const dKirbyMainMotionSpecialNFTKirbyCopy: Array = [
	{"copy_id": nFTKindMario, "copy_modelpart_id": 12, "effect_scale": 1.5, "star_damage": 17},
	{"copy_id": nFTKindFox, "copy_modelpart_id": 7, "effect_scale": 1.5, "star_damage": 17},
	{"copy_id": nFTKindDonkey, "copy_modelpart_id": 4, "effect_scale": 2.0, "star_damage": 30},
	{"copy_id": nFTKindSamus, "copy_modelpart_id": 8, "effect_scale": 1.6, "star_damage": 17},
	{"copy_id": nFTKindLuigi, "copy_modelpart_id": 11, "effect_scale": 1.6, "star_damage": 17},
	{"copy_id": nFTKindLink, "copy_modelpart_id": 10, "effect_scale": 1.5, "star_damage": 17},
	{"copy_id": nFTKindYoshi, "copy_modelpart_id": 5, "effect_scale": 1.7, "star_damage": 25},
	{"copy_id": nFTKindCaptain, "copy_modelpart_id": 9, "effect_scale": 1.7, "star_damage": 17},
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.6, "star_damage": 17},
	{"copy_id": nFTKindPikachu, "copy_modelpart_id": 6, "effect_scale": 1.5, "star_damage": 17},
	{"copy_id": nFTKindPurin, "copy_modelpart_id": 3, "effect_scale": 1.6, "star_damage": 17},
	{"copy_id": nFTKindNess, "copy_modelpart_id": 13, "effect_scale": 1.6, "star_damage": 17},
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.0, "star_damage": 17},
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.5, "star_damage": 17},
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.5, "star_damage": 17},
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.5, "star_damage": 17},
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 2.0, "star_damage": 30},
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.6, "star_damage": 17},
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.6, "star_damage": 17},
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.5, "star_damage": 17},
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.7, "star_damage": 17},
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.7, "star_damage": 17},
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.6, "star_damage": 17},
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.5, "star_damage": 17},
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.6, "star_damage": 17},
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.6, "star_damage": 17},
	{"copy_id": nFTKindDonkey, "copy_modelpart_id": 4, "effect_scale": 2.0, "star_damage": 50},
]

## motion_vars.flags.flagN are u32 in C.
static func _u32(x: int) -> int:
	return x & 0xFFFFFFFF

## lbCommonReflect2D(Vec3f *a, Vec3f *b) writes *a and returns a: accept the Dictionary
## ({"ret", "a"}) or the bare Vector3 out-param return convention.
static func _lbCommonReflect2D(a: Vector3, b: Vector3) -> Vector3:
	var r = Lbcommon.lbCommonReflect2D(a, b)

	if r is Dictionary:
		return r.a
	return r

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8014B700
static func ftCommonCaptureKirbyUpdatePositionsMag(fighter_gobj, dist) -> void:
	var mag: float = syVectorMag3D(dist)

	if mag < FTCOMMON_CAPTUREKIRBY_MAGNITUDE_MAX:
		var joint: DObj = DObjGetStruct(fighter_gobj).child
		var scale: float

		mag /= FTCOMMON_CAPTUREKIRBY_MAGNITUDE_MAX
		mag *= FTCOMMON_CAPTUREKIRBY_MAGNITUDE_MUL

		scale = FTCOMMON_CAPTUREKIRBY_MAGNITUDE_ADD + mag

		joint.scale = Vector3(scale, scale, scale)

## 0x8014B774
static func ftCommonCaptureKirbyUpdatePositionsAll(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var dist: Vector3
	var capture_fp := ftGetStruct(this_fp.capture_gobj)

	dist.x = capture_fp.status_vars.kirby.specialn.dist.x
	dist.y = capture_fp.status_vars.kirby.specialn.dist.y
	dist.z = 0

	ftCommonCaptureKirbyUpdatePositionsMag(fighter_gobj, dist)

	if ABSF(dist.x) > FTCOMMON_CAPTUREKIRBY_DIST_X_MIN:
		dist.x = (-1 if (dist.x < 0.0) else +1) * FTCOMMON_CAPTUREKIRBY_DIST_X_MIN
	if ABSF(dist.y) > FTCOMMON_CAPTUREKIRBY_DIST_Y_MIN:
		dist.y = (-1 if (dist.y < 0.0) else +1) * FTCOMMON_CAPTUREKIRBY_DIST_Y_MIN
	capture_fp.status_vars.kirby.specialn.dist.x -= dist.x
	capture_fp.status_vars.kirby.specialn.dist.y -= dist.y

	# ftKirbySpecialNAddCaptureDistance(capture_fp, capture_gobj, &dist): dist is a pure output
	dist = Ftkirbyspecialn.ftKirbySpecialNAddCaptureDistance(capture_fp, this_fp.capture_gobj)

	DObjGetStruct(fighter_gobj).translate.x = capture_fp.status_vars.kirby.specialn.dist.x + dist.x
	DObjGetStruct(fighter_gobj).translate.y = capture_fp.status_vars.kirby.specialn.dist.y + dist.y
	DObjGetStruct(fighter_gobj).translate.z = DObjGetStruct(this_fp.capture_gobj).translate.z

## 0x8014B914
static func ftCommonCaptureKirbyProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftCommonCaptureKirbyUpdatePositionsAll(fighter_gobj)

	if (fp.status_id == nFTCommonStatusCaptureKirby) and B(fp.status_vars.common.capturekirby.is_goto_capturewait):
		ftCommonCaptureWaitKirbySetStatus(fighter_gobj)

## 0x8014B968
static func ftCommonCaptureKirbyProcCapture(fighter_gobj, capture_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var capture_fp: Fighter

	Ftparam.ftParamStopVoiceRunProcDamage(fighter_gobj)

	if (this_fp.item_gobj != null) and (itGetStruct(this_fp.item_gobj).weight == nITWeightHeavy):
		Itmain.itMainSetFighterDrop(this_fp.item_gobj, Vector3.ZERO, 1.0)    # ftSetupDropItem(this_fp)
	if this_fp.catch_gobj != null:
		Ftcommonthrown2.ftCommonThrownSetStatusDamageRelease(this_fp.catch_gobj)

		this_fp.catch_gobj = null
	elif this_fp.capture_gobj != null:
		Ftcommonthrown2.ftCommonThrownDecideFighterLoseGrip(this_fp.capture_gobj, fighter_gobj)
	this_fp.is_catch_or_capture = FALSE

	this_fp.capture_gobj = capture_gobj

	capture_fp = ftGetStruct(capture_gobj)

	this_fp.lr = -capture_fp.lr

	Mpcommon.mpCommonSetFighterAir(this_fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCaptureKirby, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	Ftparam.ftParamMakeRumble(this_fp, 7, 0)

	this_fp.status_vars.common.capturekirby.is_goto_capturewait = FALSE
	this_fp.status_vars.common.capturekirby.lr = 0
	this_fp.status_vars.common.capturekirby.is_kirby = FALSE

	Ftparam.ftParamSetCaptureImmuneMask(this_fp, FTCATCHKIND_MASK_ALL)
	Ftphysics.ftPhysicsStopVelAll(fighter_gobj)
	ftCommonCaptureKirbyProcPhysics(fighter_gobj)
	Mpcommon.mpCommonUpdateFighterProjectFloor(fighter_gobj)

## 0x8014BA98
static func ftCommonCaptureWaitKirbyUpdateBreakoutVars(this_fp, capture_fp) -> void:
	var is_wiggle: int = FALSE

	if (capture_fp.status_id == nFTKirbyStatusSpecialAirNWait) or (capture_fp.status_id == nFTKirbyStatusSpecialNWait):
		if (this_fp.input.pl.stick_range.y >= FTCOMMON_CAPTUREKIRBY_WIGGLE_STICK_RANGE_MIN) and (this_fp.tap_stick_y < FTCOMMON_CAPTUREKIRBY_WIGGLE_BUFFER_TICS_MAX):
			this_fp.tap_stick_y = FTINPUT_STICKBUFFER_TICS_MAX
			is_wiggle = TRUE

			if capture_fp.ga == nMPKineticsGround:
				Ftkirbyspecialn.ftKirbySpecialNWaitSwitchStatusAir(capture_fp.fighter_gobj)

				is_wiggle = TRUE

				capture_fp.physics.vel_air.y = FTCOMMON_CAPTUREKIRBY_WIGGLE_VEL
		elif (this_fp.input.pl.stick_range.y <= -FTCOMMON_CAPTUREKIRBY_WIGGLE_STICK_RANGE_MIN) and (this_fp.tap_stick_y < FTCOMMON_CAPTUREKIRBY_WIGGLE_BUFFER_TICS_MAX) and (this_fp.coll_data.floor_flags & 0x4000):
			this_fp.tap_stick_y = FTINPUT_STICKBUFFER_TICS_MAX
			is_wiggle = TRUE

			if capture_fp.ga == nMPKineticsGround:
				Ftkirbyspecialn.ftKirbySpecialNWaitSwitchStatusAir(capture_fp.fighter_gobj)

				is_wiggle = TRUE

				capture_fp.coll_data.ignore_line_id = capture_fp.coll_data.floor_line_id
				capture_fp.physics.vel_air.y = -FTCOMMON_CAPTUREKIRBY_WIGGLE_VEL
		if (ABS(this_fp.input.pl.stick_range.x) >= (FTCOMMON_CAPTUREKIRBY_WIGGLE_STICK_RANGE_MIN + 3)) and (this_fp.tap_stick_x < (FTCOMMON_CAPTUREKIRBY_WIGGLE_BUFFER_TICS_MAX * 2)):
			this_fp.tap_stick_x = FTINPUT_STICKBUFFER_TICS_MAX
			is_wiggle = TRUE

			if capture_fp.ga == nMPKineticsGround:
				capture_fp.physics.vel_ground.x = ((-1 if (this_fp.input.pl.stick_range.x < 0) else 1) * capture_fp.lr) * FTCOMMON_CAPTUREKIRBY_WIGGLE_VEL
			else:
				capture_fp.physics.vel_air.x = (-1 if (this_fp.input.pl.stick_range.x < 0) else 1) * FTCOMMON_CAPTUREKIRBY_WIGGLE_VEL
		if is_wiggle != FALSE:
			if capture_fp.figatree != null:
				ObjAnim.lbCommonAddFighterPartsFigatree(capture_fp.joints[nFTPartsJointTopN].child, capture_fp.figatree, 0.0)

## 0x8014BC94
static func ftCommonCaptureWaitKirbyProcMap(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var capture_gobj = this_fp.capture_gobj
	var capture_fp := ftGetStruct(capture_gobj)
	var this_dobj := DObjGetStruct(fighter_gobj)    # Vec3f *this_translate = &this_dobj->translate

	this_dobj.translate = DObjGetStruct(capture_gobj).translate

	if capture_fp.lr == +1:
		this_dobj.translate.x += 10.0
	else:
		this_dobj.translate.x -= 10.0

## 0x8014BD04
static func ftCommonCaptureWaitKirbyProcInterrupt(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var capture_gobj = this_fp.capture_gobj

	if capture_gobj != null:
		var capture_fp := ftGetStruct(capture_gobj)
		var breakout_wait: int

		ftCommonCaptureWaitKirbyUpdateBreakoutVars(this_fp, capture_fp)

		breakout_wait = this_fp.breakout_wait

		Ftcommoncapture.ftCommonCaptureTrappedUpdateBreakoutVars(this_fp)

		this_fp.breakout_wait -= ((breakout_wait - this_fp.breakout_wait) * 5)

		this_fp.breakout_wait -= 1

		if this_fp.breakout_wait <= 0:
			Ftcommoncapture.ftCommonCaptureApplyCatchKnockback(capture_gobj, dFTCommonCaptureKirbyKnockbackCatch) # Deal knockback to player who caught this fighter
			Ftcommoncapture.ftCommonCaptureApplyCaptureKnockback(fighter_gobj, dFTCommonCaptureKirbyKnockbackCapture) # Deal knockback to this fighter

			capture_fp.catch_gobj = null
			this_fp.capture_gobj = null

## 0x8014BDB4
static func ftCommonCaptureWaitKirbySetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCaptureWaitKirby, 0.0, 1.0, (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_MODELPART))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

	fp.is_invisible = TRUE

	Ftparam.ftParamSetHitStatusAll(fighter_gobj, nGMHitStatusIntangible)
	Ftcommoncapture.ftCommonCaptureTrappedInitBreakoutVars(fp, 500)

## 0x8014BE24
static func ftCommonThrownKirbyEscape(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusFall, 0.0, 1.0, FTSTATUS_PRESERVE_DAMAGEPLAYER)

## 0x8014BE54
static func ftCommonThrownCommonStarProcHit(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusFall, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x8014BE90
static func ftCommonThrownKirbyStarMakeEffect(fighter_gobj, arg1, arg2) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if not B(fp.is_effect_attach):
		if Efmanager.efManagerCaptureKirbyStarMakeEffect(fighter_gobj) != null:
			fp.is_effect_attach = TRUE

## 0x8014BEE0
static func ftCommonThrownKirbyStarProcUpdate(fighter_gobj) -> void:
	ftCommonThrownKirbyStarMakeEffect(fighter_gobj, 360.0, 210.0)

## 0x8014BF04
static func ftCommonThrownCommonStarUpdatePhysics(fighter_gobj, decelerate) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.motion_vars.flags.flag1 != 0) and (fp.motion_vars.flags.flag2 != 3):
		var sqrt_vel: float = sqrtf(SQUARE(fp.physics.vel_air.x) + SQUARE(fp.physics.vel_air.y))

		if decelerate < sqrt_vel:
			fp.physics.vel_air.x = (fp.physics.vel_air.x * (sqrt_vel - decelerate)) / sqrt_vel
			fp.physics.vel_air.y = (fp.physics.vel_air.y * (sqrt_vel - decelerate)) / sqrt_vel

			if fp.physics.vel_air.y < 0:
				fp.lr = -1
			else:
				fp.lr = +1
		else:
			fp.physics.vel_air.y = 0.0
			fp.physics.vel_air.x = fp.physics.vel_air.y

		fp.motion_vars.flags.flag1 = _u32(fp.motion_vars.flags.flag1 - 1)

		Ftcommoncapture.ftCommonCaptureTrappedUpdateBreakoutVars(fp)

		if fp.breakout_wait <= 0:
			fp.motion_vars.flags.flag1 = 0
	else:
		if fp.motion_vars.flags.flag2 == 1:
			if ((fp.fkind == nFTKindKirby) or (fp.fkind == nFTKindNKirby)) and B(fp.status_vars.common.capturekirby.is_kirby):
				Ftkirbyspecialn.ftKirbySpecialNInitPassiveVars(fp)

				fp.passive_vars.kirby.copy_id = nFTKindKirby

				Ftparam.ftParamSetModelPartDefaultID(fighter_gobj, 6, 0)
				Ftparam.ftParamResetModelPartAll(fighter_gobj)
			fp.is_invisible = FALSE

			Ftparam.ftParamSetHitStatusAll(fighter_gobj, nGMHitStatusNormal)
			Ftparam.ftParamProcStopEffect(fighter_gobj)
			ftCommonThrownKirbyEscape(fighter_gobj)

			if Efmanager.efManagerStarSplashMakeEffect(DObjGetStruct(fighter_gobj).translate, -1 if (-fp.physics.vel_air.x < 0.0) else +1) != null:
				fp.is_effect_attach = TRUE
		else:
			if fp.motion_vars.flags.flag2 == 2:
				fp.motion_vars.flags.flag1 = 4
				fp.motion_vars.flags.flag2 = 3

				fp.physics.vel_air.y = FTCOMMON_THROWNKIRBYSTAR_RELEASE_VEL_Y

				if fp.status_vars.common.capturekirby.lr != 0:
					fp.physics.vel_air.x = fp.status_vars.common.capturekirby.lr * FTCOMMON_THROWNKIRBYSTAR_RELEASE_VEL_X
				else:
					fp.physics.vel_air.x = (-1 if (fp.physics.vel_air.x < 0.0) else +1) * FTCOMMON_THROWNKIRBYSTAR_RELEASE_VEL_X

				Ftparam.ftParamProcStopEffect(fighter_gobj)

				if Efmanager.efManagerStarSplashMakeEffect(DObjGetStruct(fighter_gobj).translate, -1 if (-fp.physics.vel_air.x < 0.0) else +1) != null:
					fp.is_effect_attach = TRUE
				fp.is_invisible = FALSE

				Ftparam.ftParamSetHitStatusAll(fighter_gobj, nGMHitStatusNormal)
			if fp.motion_vars.flags.flag2 == 3:
				var joint: DObj = DObjGetStruct(fighter_gobj).child
				# (4.0F - (f32)u32 flag1) * 0.25F
				var scale: float = (4.0 - _u32(fp.motion_vars.flags.flag1)) * 0.25
				var joint_scale: float

				scale *= FTCOMMON_CAPTUREKIRBY_MAGNITUDE_MUL

				joint_scale = FTCOMMON_CAPTUREKIRBY_MAGNITUDE_ADD + scale

				joint.scale = Vector3(joint_scale, joint_scale, joint_scale)

				# if (fp->motion_vars.flags.flag1-- <= 0): u32 post-decrement, so "<= 0" is "== 0" and 0 wraps
				var flag1_prev: int = _u32(fp.motion_vars.flags.flag1)

				fp.motion_vars.flags.flag1 = _u32(flag1_prev - 1)

				if flag1_prev <= 0:
					ftCommonThrownKirbyEscape(fighter_gobj)

## 0x8014C260
static func ftCommonThrownKirbyStarProcPhysics(fighter_gobj) -> void:
	ftCommonThrownCommonStarUpdatePhysics(fighter_gobj, FTCOMMON_THROWNKIRBYSTAR_DECELERATE)

## 0x8014C280
static func ftCommonThrownCommonStarProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var angle = null    # Vec3f *angle (pointer into coll_data; not modified while in use)
	var pos: Vector3 = DObjGetStruct(fighter_gobj).translate
	var vel_bak: Vector3

	if B(Mpcommon.mpCommonCheckFighterLanding(fighter_gobj)):
		angle = fp.coll_data.floor_angle
	elif fp.coll_data.mask_curr & MAP_FLAG_CEIL:
		angle = fp.coll_data.ceil_angle

		pos.y += fp.coll_data.map_coll.top
	elif fp.coll_data.mask_curr & MAP_FLAG_LWALL:
		angle = fp.coll_data.lwall_angle

		pos.x += fp.coll_data.map_coll.width
		pos.y += fp.coll_data.map_coll.center
	elif fp.coll_data.mask_curr & MAP_FLAG_RWALL:
		angle = fp.coll_data.rwall_angle

		pos.x -= fp.coll_data.map_coll.width
		pos.y += fp.coll_data.map_coll.center
	if angle != null:
		vel_bak = fp.physics.vel_air

		fp.physics.vel_air = _lbCommonReflect2D(fp.physics.vel_air, angle)

		if ((fp.physics.vel_air.x * vel_bak.x) + (vel_bak.y * fp.physics.vel_air.y)) < 0.0:
			fp.status_vars.common.capturekirby.lr = -1 if (angle.x < 0) else +1

			fp.motion_vars.flags.flag1 = 0
		Efmanager.efManagerQuakeMakeEffect(2)
		Efmanager.efManagerImpactWaveMakeEffect(pos, SYVECTOR_AXIS_Z, syUtilsArcTan2(-angle.x, angle.y))

## 0x8014C424
static func ftCommonThrownKirbyStarInitStatusVars(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var capture_gobj = this_fp.capture_gobj

	if capture_gobj != null:
		var capture_fp := ftGetStruct(capture_gobj)

		Ftcommonthrown2.ftCommonThrownReleaseFighterLoseGrip(fighter_gobj)
		Ftparam.ftParamSetCaptureImmuneMask(this_fp, FTCATCHKIND_MASK_NONE)
		Ftparam.ftParamSetCaptureImmuneMask(capture_fp, FTCATCHKIND_MASK_NONE)
		Ftparam.ftParamUpdate1PGameDamageStats(this_fp, capture_fp.player, nFTHitLogObjectFighter, capture_fp.fkind, capture_fp.stat_flags.halfword, capture_fp.stat_count)

		this_fp.capture_gobj = null
		this_fp.catch_gobj = null
		capture_fp.catch_gobj = null
		capture_fp.capture_gobj = null

		this_fp.status_vars.common.capturekirby.lr = -1 if (this_fp.physics.vel_air.x < 0.0) else +1

## 0x8014C4D8
static func ftCommonThrownKirbyStarProcStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag1 = 30
	fp.motion_vars.flags.flag2 = 2

	ftCommonThrownKirbyStarInitStatusVars(fighter_gobj)

## 0x8014C508
static func ftCommonThrownKirbyStarSetStatus(fighter_gobj) -> void:
	var i: int
	var fp := ftGetStruct(fighter_gobj)
	var copy: Array = dKirbyMainMotionSpecialNFTKirbyCopy

	if fp.ga == nMPKineticsGround:
		Mpcommon.mpCommonSetFighterAir(fp)
	fp.proc_status = Callable(Ftcommoncapturekirby, &"ftCommonThrownKirbyStarProcStatus")

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusThrownKirbyStar, 0.0, 1.0, FTSTATUS_PRESERVE_THROWPOINTER)
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

	fp.proc_hit = Callable(Ftcommoncapturekirby, &"ftCommonThrownCommonStarProcHit")

	i = 0
	while i < fp.attack_colls.size():
		var attack_coll: FTAttackColl = fp.attack_colls[i]

		if attack_coll.attack_state == nGMAttackStateNew:
			attack_coll.damage = copy[fp.fkind].star_damage
		i += 1
	fp.is_shadow_hide = TRUE
	fp.is_invisible = fp.is_shadow_hide

	Ftparam.ftParamSetHitStatusAll(fighter_gobj, nGMHitStatusIntangible)
	Ftparam.ftParamSetPlayerTagWait(fighter_gobj, 1)
	Ftcommoncapture.ftCommonCaptureTrappedInitBreakoutVars(fp, FTCOMMON_THROWNKIRBYSTAR_BREAKOUT_INPUTS_MIN)

## 0x8014C634
static func ftCommonThrownCopyStarProcUpdate(fighter_gobj) -> void:
	ftCommonThrownKirbyStarMakeEffect(fighter_gobj, -400.0, 280.0)

## 0x8014C658
static func ftCommonThrownCopyStarProcPhysics(fighter_gobj) -> void:
	ftCommonThrownCommonStarUpdatePhysics(fighter_gobj, FTCOMMON_THROWNCOPYSTAR_DECELERATE)

## 0x8014C67C
static func ftCommonThrownCopyStarProcStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag1 = 10
	fp.motion_vars.flags.flag2 = 1

	ftCommonThrownKirbyStarInitStatusVars(fighter_gobj)

## 0x8014C6AC
static func ftCommonThrownCopyStarSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsGround:
		Mpcommon.mpCommonSetFighterAir(fp)
	fp.proc_status = Callable(Ftcommoncapturekirby, &"ftCommonThrownCopyStarProcStatus")

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusThrownCopyStar, 0.0, 1.0, FTSTATUS_PRESERVE_THROWPOINTER)
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

	fp.proc_hit = Callable(Ftcommoncapturekirby, &"ftCommonThrownCommonStarProcHit")
	fp.is_shadow_hide = TRUE
	fp.is_invisible = fp.is_shadow_hide

	Ftparam.ftParamSetHitStatusAll(fighter_gobj, nGMHitStatusIntangible)
	Ftparam.ftParamSetPlayerTagWait(fighter_gobj, 1)
