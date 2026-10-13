## 1:1 port of src/ft/ftcommon/ftcommoncaptureyoshi.c (ssb-decomp-re): CaptureYoshi (being swallowed
## by Yoshi's Egg Lay) and the YoshiEgg status (trapped in an egg, mash to break out).
class_name Ftcommoncaptureyoshi
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x80188720 - ftCommonYoshiEggDesc {effect_size, offset, size}, indexed by FTKind
static var dFTCommonYoshiEggDamageCollDescs: Array = [
	{"effect_size": 2.0, "offset": Vector3(0.0, 157.0, 0.0), "size": Vector3(180.0, 180.0, 180.0)},   # Mario
	{"effect_size": 1.9, "offset": Vector3(0.0, 155.0, 0.0), "size": Vector3(171.0, 171.0, 171.0)},   # Fox
	{"effect_size": 3.5, "offset": Vector3(0.0, 230.0, 0.0), "size": Vector3(245.0, 245.0, 245.0)},   # Donkey Kong
	{"effect_size": 2.2, "offset": Vector3(0.0, 163.0, 0.0), "size": Vector3(198.0, 198.0, 198.0)},   # Samus
	{"effect_size": 2.2, "offset": Vector3(0.0, 160.0, 0.0), "size": Vector3(188.0, 188.0, 188.0)},   # Luigi
	{"effect_size": 2.0, "offset": Vector3(0.0, 133.0, 0.0), "size": Vector3(148.0, 148.0, 148.0)},   # Link
	{"effect_size": 2.5, "offset": Vector3(0.0, 175.0, 0.0), "size": Vector3(210.0, 210.0, 210.0)},   # Yoshi
	{"effect_size": 2.2, "offset": Vector3(0.0, 156.0, 0.0), "size": Vector3(198.0, 198.0, 198.0)},   # Captain Falcon
	{"effect_size": 1.8, "offset": Vector3(0.0, 132.0, 0.0), "size": Vector3(164.0, 164.0, 164.0)},   # Kirby
	{"effect_size": 1.8, "offset": Vector3(0.0, 144.0, 0.0), "size": Vector3(165.0, 165.0, 165.0)},   # Pikachu
	{"effect_size": 2.0, "offset": Vector3(0.0, 144.0, 0.0), "size": Vector3(162.0, 162.0, 162.0)},   # Jigglypuff
	{"effect_size": 1.8, "offset": Vector3(0.0, 160.0, 0.0), "size": Vector3(168.0, 168.0, 168.0)},   # Ness
	{"effect_size": 2.0, "offset": Vector3(0.0, 157.0, 0.0), "size": Vector3(180.0, 180.0, 180.0)},   # Master Hand
	{"effect_size": 2.0, "offset": Vector3(0.0, 157.0, 0.0), "size": Vector3(180.0, 180.0, 180.0)},   # Metal Mario
	{"effect_size": 2.0, "offset": Vector3(0.0, 157.0, 0.0), "size": Vector3(180.0, 180.0, 180.0)},   # Poly Mario
	{"effect_size": 1.9, "offset": Vector3(0.0, 155.0, 0.0), "size": Vector3(171.0, 171.0, 171.0)},   # Poly Fox
	{"effect_size": 3.5, "offset": Vector3(0.0, 230.0, 0.0), "size": Vector3(245.0, 245.0, 245.0)},   # Poly Donkey Kong
	{"effect_size": 2.2, "offset": Vector3(0.0, 163.0, 0.0), "size": Vector3(198.0, 198.0, 198.0)},   # Poly Samus
	{"effect_size": 2.2, "offset": Vector3(0.0, 160.0, 0.0), "size": Vector3(188.0, 188.0, 188.0)},   # Poly Luigi
	{"effect_size": 2.0, "offset": Vector3(0.0, 133.0, 0.0), "size": Vector3(148.0, 148.0, 148.0)},   # Poly Link
	{"effect_size": 2.5, "offset": Vector3(0.0, 175.0, 0.0), "size": Vector3(210.0, 210.0, 210.0)},   # Poly Yoshi
	{"effect_size": 2.2, "offset": Vector3(0.0, 156.0, 0.0), "size": Vector3(198.0, 198.0, 198.0)},   # Poly Captain Falcon
	{"effect_size": 1.8, "offset": Vector3(0.0, 132.0, 0.0), "size": Vector3(164.0, 164.0, 164.0)},   # Poly Kirby
	{"effect_size": 1.8, "offset": Vector3(0.0, 144.0, 0.0), "size": Vector3(165.0, 165.0, 165.0)},   # Poly Pikachu
	{"effect_size": 2.0, "offset": Vector3(0.0, 144.0, 0.0), "size": Vector3(162.0, 162.0, 162.0)},   # Poly Jigglypuff
	{"effect_size": 1.8, "offset": Vector3(0.0, 160.0, 0.0), "size": Vector3(168.0, 168.0, 168.0)},   # Poly Ness
	{"effect_size": 5.7, "offset": Vector3(0.0, 400.0, 0.0), "size": Vector3(350.0, 350.0, 350.0)},   # Giant Donkey Kong
]

## status_vars.common.captureyoshi.stage / breakout_wait are s16 in C.
static func _s16(x: int) -> int:
	return ((x + 0x8000) & 0xFFFF) - 0x8000

## efGetStruct(effect_gobj): ((EFStruct*)(effect_gobj)->user_data.p)
static func _efGetStruct(effect_gobj):
	return effect_gobj.user_data

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8014C770
static func func_ovl3_8014C770() -> void: # Unused
	return

## 0x8014C778
static func ftCommonCaptureYoshiProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3

	# ftCommonCapturePulledRotateScale(fighter_gobj, &pos, &DObjGetStruct(fighter_gobj)->rotate)
	var r: Dictionary = Ftcommoncapturepulled.ftCommonCapturePulledRotateScale(fighter_gobj)
	pos = r.this_pos
	DObjGetStruct(fighter_gobj).rotate = r.rotate

	DObjGetStruct(fighter_gobj).translate.x = pos.x
	DObjGetStruct(fighter_gobj).translate.z = pos.z

	if fp.status_id == nFTCommonStatusCaptureYoshi:
		if fp.status_vars.common.captureyoshi.stage == 3:
			ftCommonYoshiEggSetStatus(fighter_gobj)
		elif fp.status_vars.common.captureyoshi.stage == 1:
			fp.status_vars.common.captureyoshi.stage = 2

			fp.is_shadow_hide = TRUE
			fp.is_invisible = fp.is_shadow_hide

			Ftparam.ftParamSetHitStatusAll(fighter_gobj, nGMHitStatusIntangible)

## 0x8014C83C
static func ftCommonCaptureYoshiProcCapture(fighter_gobj, capture_gobj) -> void:
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
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCaptureYoshi, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	this_fp.status_vars.common.captureyoshi.stage = 0
	this_fp.status_vars.common.captureyoshi.breakout_wait = 0

	Ftparam.ftParamSetCaptureImmuneMask(this_fp, FTCATCHKIND_MASK_ALL)
	Ftphysics.ftPhysicsStopVelAll(fighter_gobj)
	ftCommonCaptureYoshiProcPhysics(fighter_gobj)
	Mpcommon.mpCommonUpdateFighterProjectFloor(fighter_gobj)

## 0x8014C958
static func ftCommonYoshiEggMakeEffect(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.common.captureyoshi.effect_gobj == null:
		fp.status_vars.common.captureyoshi.effect_gobj = Efmanager.efManagerYoshiEggLayMakeEffect(fighter_gobj)

		if fp.status_vars.common.captureyoshi.effect_gobj != null:
			fp.is_effect_attach = TRUE

## 0x8014C9A0
static func ftCommonYoshiEggProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var is_escape: int = FALSE

	if fp.status_vars.common.captureyoshi.is_damagefloor == TRUE:
		is_escape = TRUE

		if fp.status_vars.common.captureyoshi.effect_gobj != null:
			Ftparam.ftParamProcStopEffect(fighter_gobj)

			fp.status_vars.common.captureyoshi.effect_gobj = null
	else:
		ftCommonYoshiEggMakeEffect(fighter_gobj)

		if fp.status_vars.common.captureyoshi.effect_gobj != null:
			var ep = _efGetStruct(fp.status_vars.common.captureyoshi.effect_gobj)

			if (ep.effect_vars.yoshi_egg_lay.index == 1) and (fp.status_vars.common.captureyoshi.effect_gobj.anim_frame <= 0.0):
				is_escape = TRUE
		elif fp.motion_vars.flags.flag0 == 1:
			# if (breakout_wait-- <= 0): s16 post-decrement
			var breakout_wait_prev: int = fp.status_vars.common.captureyoshi.breakout_wait

			fp.status_vars.common.captureyoshi.breakout_wait = _s16(breakout_wait_prev - 1)

			if breakout_wait_prev <= 0:
				is_escape = TRUE
	if is_escape == TRUE:
		var pos: Vector3 = DObjGetStruct(fighter_gobj).translate
		pos.z = 0.0

		Efmanager.efManagerYoshiEggExplodeMakeEffect(pos)
		Efmanager.efManagerEggBreakMakeEffect(pos)
		Snd.func_800269C0_275C0(nSYAudioFGMYoshiEggLayShatter)

		fp.physics.vel_air.y = FTCOMMON_YOSHIEGG_ESCAPE_VEL_Y
		fp.physics.vel_air.z = 0.0
		fp.physics.vel_air.x = fp.physics.vel_air.z

		DObjGetStruct(fighter_gobj).translate.y += FTCOMMON_YOSHIEGG_ESCAPE_OFF_Y

		Mpcommon.mpCommonSetFighterAir(fp)
		Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusFall, 0.0, 1.0, FTSTATUS_PRESERVE_DAMAGEPLAYER)
		Ftparam.ftParamSetTimedHitStatusIntangible(fp, FTCOMMON_YOSHIEGG_INTANGIBLE_TIMER)

## 0x8014CB24
static func ftCommonYoshiEggProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.common.captureyoshi.effect_gobj != null:
		var joint: DObj = DObjGetStruct(fp.status_vars.common.captureyoshi.effect_gobj).child

		if fp.ga == nMPKineticsGround:
			if ABS(fp.input.pl.stick_range.y) >= FTCOMMON_YOSHIEGG_WIGGLE_STICK_RANGE_MIN:
				joint.translate.y = (-1 if (fp.input.pl.stick_range.y < 0) else 1) * FTCOMMON_YOSHIEGG_WIGGLE_GFX_RANGE_XY
			else:
				joint.translate.y = 0.0

			if ABS(fp.input.pl.stick_range.x) >= FTCOMMON_YOSHIEGG_WIGGLE_STICK_RANGE_MIN:
				joint.translate.x = (-1 if (fp.input.pl.stick_range.x < 0) else 1) * FTCOMMON_YOSHIEGG_WIGGLE_GFX_RANGE_XY
			else:
				joint.translate.x = 0.0
		else:
			joint.translate.x = 0.0
			joint.translate.y = 0.0

## 0x8014CC0C
static func ftCommonYoshiEggProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag0 == 0:
		var breakout_wait: int = fp.breakout_wait

		if Ftcommoncapture.ftCommonCaptureTrappedUpdateBreakoutVars(fp) == TRUE:
			if fp.status_vars.common.captureyoshi.effect_gobj != null:
				ObjAnim.gcSetAnimSpeed(fp.status_vars.common.captureyoshi.effect_gobj, FTCOMMON_YOSHIEGG_WIGGLE_ANIM_SPEED)
		elif fp.status_vars.common.captureyoshi.effect_gobj != null:
			ObjAnim.gcSetAnimSpeed(fp.status_vars.common.captureyoshi.effect_gobj, 1.0)
		# s16 -= s32
		fp.status_vars.common.captureyoshi.breakout_wait = _s16(fp.status_vars.common.captureyoshi.breakout_wait - ((breakout_wait - fp.breakout_wait) * 12))

		# if (breakout_wait-- <= 0): s16 post-decrement
		var breakout_wait_prev: int = fp.status_vars.common.captureyoshi.breakout_wait

		fp.status_vars.common.captureyoshi.breakout_wait = _s16(breakout_wait_prev - 1)

		if breakout_wait_prev <= 0:
			fp.motion_vars.flags.flag0 = 1
			fp.status_vars.common.captureyoshi.breakout_wait = FTCOMMON_YOSHIEGG_ESCAPE_WAIT_DEFAULT
	if fp.motion_vars.flags.flag0 == 1:
		if fp.status_vars.common.captureyoshi.effect_gobj != null:
			var ep = _efGetStruct(fp.status_vars.common.captureyoshi.effect_gobj)

			ep.effect_vars.yoshi_egg_lay.force_index = 1
	if fp.ga == nMPKineticsGround:
		Ftphysics.ftPhysicsApplyGroundVelFriction(fighter_gobj)
	else:
		Ftphysics.ftPhysicsApplyAirVelDriftFastFall(fighter_gobj)

## 0x8014CD24
static func ftCommonYoshiEggProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsGround:
		if not B(Mpcommon.mpCommonCheckFighterOnFloor(fighter_gobj)):
			fp.ga = nMPKineticsAir
	elif B(Mpcommon.mpCommonCheckFighterLanding(fighter_gobj)):
		fp.ga = nMPKineticsGround

## 0x8014CD7C
static func ftCommonYoshiEggProcTrap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag0 == 0:
		# s16 -= f32: breakout_wait = (s16)(s32)((f32)breakout_wait - ((2.0F * damage_queue) / 0.5F))
		fp.status_vars.common.captureyoshi.breakout_wait = _s16(int(fp.status_vars.common.captureyoshi.breakout_wait - ((2.0 * fp.damage_queue) / 0.5)))
	if (fp.damage_object_class == nFTHitLogObjectGround) and (fp.damage_object_kind == nGMHitEnvironmentAcid):
		fp.status_vars.common.captureyoshi.breakout_wait = 0
		fp.status_vars.common.captureyoshi.is_damagefloor = TRUE
	fp.damage_kind = nFTHitLogObjectGround

## 0x8014CDFC
static func ftCommonYoshiEggSetDamageCollCollisions(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var damage_coll: FTDamageColl = fp.damage_colls[0]
	var egg: Dictionary = dFTCommonYoshiEggDamageCollDescs[fp.fkind]
	var i: int

	damage_coll.joint = fp.joints[nFTPartsJointTopN]
	damage_coll.joint_id = nFTPartsJointTopN
	damage_coll.placement = nFTPartsPlacementMiddle
	damage_coll.is_grabbable = FALSE
	damage_coll.offset = egg.offset
	damage_coll.size = egg.size

	i = 1
	while i < fp.damage_colls.size():
		damage_coll = fp.damage_colls[i]

		if damage_coll.hitstatus != nGMHitStatusNone:
			damage_coll.hitstatus = nGMHitStatusIntangible
		i += 1
	fp.is_hitstatus_nodamage = TRUE
	fp.is_damage_coll_modify = TRUE

## 0x8014CF0C
static func ftCommonYoshiEggProcStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.common.captureyoshi.breakout_wait = FTCOMMON_YOSHIEGG_ESCAPE_WAIT_MAX

	fp.motion_vars.flags.flag0 = 0

## 0x8014CF20
static func ftCommonYoshiEggSetStatus(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var capture_fp: Fighter

	if this_fp.ga == nMPKineticsGround:
		Mpcommon.mpCommonSetFighterAir(this_fp)
	this_fp.proc_status = Callable(Ftcommoncaptureyoshi, &"ftCommonYoshiEggProcStatus")

	Mpcommon.mpCommonSetFighterAir(this_fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusYoshiEgg, 0.0, 0.0, FTSTATUS_PRESERVE_NONE)
	Ftparam.ftParamSetCaptureImmuneMask(this_fp, FTCATCHKIND_MASK_ALL)

	this_fp.is_invisible = TRUE

	ftCommonYoshiEggSetDamageCollCollisions(fighter_gobj)
	Ftcommoncapture.ftCommonCaptureTrappedInitBreakoutVars(this_fp, FTCOMMON_YOSHIEGG_BREAKOUT_INPUTS_MIN)
	Ftkirbyspecialn.ftKirbySpecialNApplyCaptureDamage(this_fp.capture_gobj, fighter_gobj, 5) # Br0h why
	Ftparam.ftParamSetPlayerTagWait(fighter_gobj, 1)

	capture_fp = ftGetStruct(this_fp.capture_gobj)

	DObjGetStruct(fighter_gobj).translate = DObjGetStruct(this_fp.capture_gobj).translate

	DObjGetStruct(fighter_gobj).translate.x -= (capture_fp.lr * FTCOMMON_YOSHIEGG_LAY_OFF_X)
	DObjGetStruct(fighter_gobj).translate.y += FTCOMMON_YOSHIEGG_LAY_OFF_Y

	Mpcommon.mpCommonRunFighterCollisionDefault(fighter_gobj, DObjGetStruct(this_fp.capture_gobj).translate, ftGetStruct(this_fp.capture_gobj).coll_data)

	this_fp.physics.vel_air.x = -capture_fp.lr * FTCOMMON_YOSHIEGG_LAY_VEL_X
	this_fp.physics.vel_air.y = FTCOMMON_YOSHIEGG_LAY_VEL_Y
	this_fp.damage_mul = FTCOMMON_YOSHIEGG_DAMAGE_MUL

	this_fp.capture_gobj = null

	this_fp.proc_trap = Callable(Ftcommoncaptureyoshi, &"ftCommonYoshiEggProcTrap")

	this_fp.status_vars.common.captureyoshi.lr = capture_fp.lr
	this_fp.status_vars.common.captureyoshi.effect_gobj = null
	this_fp.status_vars.common.captureyoshi.is_damagefloor = FALSE

	Ftparam.ftParamUpdate1PGameDamageStats(this_fp, capture_fp.player, nFTHitLogObjectFighter, capture_fp.fkind, capture_fp.stat_flags.halfword, capture_fp.stat_count)
	ftCommonYoshiEggMakeEffect(fighter_gobj)
