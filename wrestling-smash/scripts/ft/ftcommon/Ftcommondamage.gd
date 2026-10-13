## 1:1 port of src/ft/ftcommon/ftcommondamage.c (ssb-decomp-re): the knockback / hitstun core
## (damage status selection, ground/air knockback velocity, Sakurai angle, damage level, hitstun,
## DamageE electric, FlyTop/FlyRoll, smash DI, crowd reaction, grab interactions, item drop).
class_name Ftcommondamage
extends Port

## Note on angles: attack angles of exactly 70 / 110 / 75 / 115 degrees are common; the run-time
## F_CLC_DTOR32(angle_i) (Port, f32-exact) then *equals* the FlyTop / crowd-gasp bounds (SSBDefs,
## exact f32 like the ROM rodata) and the strict comparisons fail exactly like the C.

## Exact f32 values of float literals used in f32 arithmetic below.
const FTCOMMON_DAMAGE_SAKURAI_KNOCKBACK_DIV_F32 := 0.09999847412109375      # 0.099998474F (0x3DCCCC00)
const FTCOMMON_DAMAGE_BOUNCE_VEL_MUL_F32 := 0.800000011920929               # 0.8F

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x801885A0
static var dFTCommonDamageStatusGroundIDs: Array = [
	[nFTCommonStatusDamageLw1,   nFTCommonStatusDamageN1,    nFTCommonStatusDamageHi1],
	[nFTCommonStatusDamageLw2,   nFTCommonStatusDamageN2,    nFTCommonStatusDamageHi2],
	[nFTCommonStatusDamageLw3,   nFTCommonStatusDamageN3,    nFTCommonStatusDamageHi3],
	[nFTCommonStatusDamageFlyLw, nFTCommonStatusDamageFlyN,  nFTCommonStatusDamageFlyHi],
]

## 0x801885D0
static var dFTCommonDamageStatusAirIDs: Array = [
	[nFTCommonStatusDamageAir1,  nFTCommonStatusDamageAir1,  nFTCommonStatusDamageAir1],
	[nFTCommonStatusDamageAir2,  nFTCommonStatusDamageAir2,  nFTCommonStatusDamageAir2],
	[nFTCommonStatusDamageAir3,  nFTCommonStatusDamageAir3,  nFTCommonStatusDamageAir3],
	[nFTCommonStatusDamageFlyLw, nFTCommonStatusDamageFlyN,  nFTCommonStatusDamageFlyHi],
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80140340
static func ftCommonDamageSetDustEffectInterval(fp) -> void:
	var vel: float = syVectorMag3D(fp.physics.vel_damage_air) if (fp.ga == nMPKineticsAir) else ABSF(fp.physics.vel_damage_ground)
	var make_effect_wait: int

	if vel < FTCOMMON_DAMAGE_EFFECT_KNOCKBACK_LOW:
		make_effect_wait = FTCOMMON_DAMAGE_EFFECT_WAIT_LOW
	elif vel < FTCOMMON_DAMAGE_EFFECT_KNOCKBACK_MID_LOW:
		make_effect_wait = FTCOMMON_DAMAGE_EFFECT_WAIT_MID_LOW
	elif vel < FTCOMMON_DAMAGE_EFFECT_KNOCKBACK_MID:
		make_effect_wait = FTCOMMON_DAMAGE_EFFECT_WAIT_MID
	elif vel < FTCOMMON_DAMAGE_EFFECT_KNOCKBACK_MID_HIGH:
		make_effect_wait = FTCOMMON_DAMAGE_EFFECT_WAIT_MID_HIGH
	elif vel < FTCOMMON_DAMAGE_EFFECT_KNOCKBACK_HIGH:
		make_effect_wait = FTCOMMON_DAMAGE_EFFECT_WAIT_HIGH
	else:
		make_effect_wait = FTCOMMON_DAMAGE_EFFECT_WAIT_DEFAULT

	fp.status_vars.common.damage.dust_effect_int = make_effect_wait

## 0x80140454
static func ftCommonDamageUpdateDustEffect(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.common.damage.dust_effect_int != 0:
		fp.status_vars.common.damage.dust_effect_int -= 1

		if fp.status_vars.common.damage.dust_effect_int == 0:
			# C: NULL effect_pos / effect_scatter
			Ftparam.ftParamMakeEffect(fighter_gobj, nEFKindDustExpandLarge, 4, Vector3.ZERO, Vector3.ZERO, fp.lr, FALSE, FALSE)
			ftCommonDamageSetDustEffectInterval(fp)

## 0x801404B8
static func ftCommonDamageDecHitStunSetPublic(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.common.damage.hitstun_tics != 0:
		fp.status_vars.common.damage.hitstun_tics -= 1

		if fp.status_vars.common.damage.hitstun_tics == 0:
			fp.public_knockback = fp.status_vars.common.damage.public_knockback

## 0x801404E0
static func ftCommonDamageCommonProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftCommonDamageDecHitStunSetPublic(fighter_gobj)

	if (fighter_gobj.anim_frame <= 0.0) and (fp.status_vars.common.damage.hitstun_tics == 0):
		Mpcommon.mpCommonSetFighterWaitOrFall(fighter_gobj)

## 0x8014053C
static func ftCommonDamageAirCommonProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftCommonDamageUpdateDustEffect(fighter_gobj)
	ftCommonDamageDecHitStunSetPublic(fighter_gobj)

	if (fighter_gobj.anim_frame <= 0.0) and (fp.status_vars.common.damage.hitstun_tics == 0):
		Ftcommondamagefall.ftCommonDamageFallSetStatusFromDamage(fighter_gobj)

## 0x801405A0
static func ftCommonDamageCheckSetInvincible(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.hitlag_tics <= 0) and (fp.status_vars.common.damage.is_knockback_over != FALSE):
		fp.status_vars.common.damage.is_knockback_over = FALSE

		Ftparam.ftParamSetTimedHitStatusInvincible(fp, 1)

## 0x801405E4
static func ftCommonDamageSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.hitlag_tics <= 0:
		Ftmain.ftMainSetStatus(fighter_gobj, fp.status_vars.common.damage.status_id, 0.0, 1.0, (FTSTATUS_PRESERVE_DAMAGEPLAYER | FTSTATUS_PRESERVE_SHUFFLETIME))
		Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

		if fp.status_id == nFTCommonStatusDamageFlyRoll:
			ftCommonDamageFlyRollUpdateModelPitch(fighter_gobj)
		fp.is_hitstun = TRUE

		if fp.status_vars.common.damage.is_knockback_over != FALSE:
			fp.status_vars.common.damage.is_knockback_over = FALSE

			Ftparam.ftParamSetTimedHitStatusInvincible(fp, 1)

## 0x80140674
static func ftCommonDamageCommonProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.common.damage.hitstun_tics == 0:
		fp.is_hitstun = FALSE

		if fp.ga == nMPKineticsAir:
			if Fthammer.ftHammerCheckHoldHammer(fighter_gobj):
				Ftcommonhammerfall.ftCommonHammerFallProcInterrupt(fighter_gobj)
			else:
				Ftcommonfall.ftCommonFallProcInterrupt(fighter_gobj)
		elif Fthammer.ftHammerCheckHoldHammer(fighter_gobj):
			Fthammer.ftHammerProcInterrupt(fighter_gobj)
		else:
			Ftcommonwait.ftCommonWaitProcInterrupt(fighter_gobj)

## 0x8014070C
static func ftCommonDamageAirCommonProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.common.damage.hitstun_tics == 0:
		fp.is_hitstun = FALSE

		Ftcommondamagefall.ftCommonDamageFallProcInterrupt(fighter_gobj)

## 0x80140744
static func ftCommonDamageFlyRollUpdateModelPitch(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.joints[4].rotate.x = syUtilsArcTan2(f32(fp.physics.vel_air.x + fp.physics.vel_damage_air.x), f32(fp.physics.vel_air.y + fp.physics.vel_damage_air.y)) * fp.lr

	Ftparam.ftParamsUpdateFighterPartsTransformAll(fp.joints[4])

## 0x801407A8
static func ftCommonDamageCommonProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsAir:
		if fp.status_vars.common.damage.hitstun_tics == 0:
			Ftphysics.ftPhysicsApplyAirVelDriftFastFall(fighter_gobj)
		else:
			Ftphysics.ftPhysicsApplyAirVelFriction(fighter_gobj)
	else:
		Ftphysics.ftPhysicsApplyGroundVelFriction(fighter_gobj)

	if fp.status_id == nFTCommonStatusDamageFlyRoll:
		ftCommonDamageFlyRollUpdateModelPitch(fighter_gobj)
	if (fp.throw_gobj != null) and (syVectorMag3D(fp.physics.vel_damage_air) < 70.0):
		Ftparam.ftParamClearAttackCollAll(fighter_gobj)

## 0x80140878 - Smash DI during hitlag
static func ftCommonDamageCommonProcLagUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.hitlag_tics != 0:
		if (SQUARE(fp.input.pl.stick_range.x) + SQUARE(fp.input.pl.stick_range.y)) >= SQUARE(FTCOMMON_DAMAGE_SMASH_DI_RANGE_MIN):
			if (fp.tap_stick_x < FTCOMMON_DAMAGE_SMASH_DI_BUFFER_TICS_MAX) or (fp.tap_stick_y < FTCOMMON_DAMAGE_SMASH_DI_BUFFER_TICS_MAX):
				# Vec3f *translate = &DObjGetStruct(fighter_gobj)->translate.vec.f;
				var translate_dobj: DObj = DObjGetStruct(fighter_gobj)

				translate_dobj.translate.x += f32(fp.input.pl.stick_range.x * FTCOMMON_DAMAGE_SMASH_DI_RANGE_MUL)
				translate_dobj.translate.y += f32(fp.input.pl.stick_range.y * FTCOMMON_DAMAGE_SMASH_DI_RANGE_MUL)

				fp.tap_stick_y = FTINPUT_STICKBUFFER_TICS_MAX
				fp.tap_stick_x = fp.tap_stick_y

## 0x80140934
static func func_ovl3_80140934() -> void: # Unused?
	return

## 0x8014093C
static func ftCommonDamageAirCommonProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (
		Mpcommon.mpCommonCheckFighterDamageCollision(fighter_gobj) and
		not Ftcommonwalldamage.ftCommonWallDamageCheckGoto(fighter_gobj) and
		((fp.status_vars.common.damage.coll_mask_curr & MAP_FLAG_FLOOR) != 0) and
		not Ftcommonpassivestand.ftCommonPassiveStandCheckInterruptDamage(fighter_gobj) and
		not Ftcommonpassive.ftCommonPassiveCheckInterruptDamage(fighter_gobj)
	):
		Ftcommondownwaitbounce.ftCommonDownBounceSetStatus(fighter_gobj)

## 0x801409BC
static func ftCommonDamageGetKnockbackAngle(angle_i, ga, knockback) -> float:
	var angle_f: float

	knockback = f32(knockback) # f32 parameter

	if angle_i != 361:
		angle_f = F_CLC_DTOR32(angle_i)
	elif ga == nMPKineticsAir:
		angle_f = FTCOMMON_DAMAGE_SAKURAI_ANGLE_DEFAULT_AR
	elif knockback < FTCOMMON_DAMAGE_SAKURAI_KNOCKBACK_LOW:
		angle_f = FTCOMMON_DAMAGE_SAKURAI_ANGLE_LOW_GR
	else:
		# F_CLC_DTOR32((((knockback - FTCOMMON_DAMAGE_SAKURAI_KNOCKBACK_LOW) / 0.099998474F) * FTCOMMON_DAMAGE_SAKURAI_ANGLE_HIGH_GD) + 1.0F)
		# (each f32 step rounded like the C)
		var deg: float = f32(knockback - FTCOMMON_DAMAGE_SAKURAI_KNOCKBACK_LOW)

		deg = f32(deg / FTCOMMON_DAMAGE_SAKURAI_KNOCKBACK_DIV_F32)
		deg = f32(deg * FTCOMMON_DAMAGE_SAKURAI_ANGLE_HIGH_GD)
		deg = f32(deg + 1.0)

		angle_f = F_CLC_DTOR32(deg)

		if angle_f > FTCOMMON_DAMAGE_SAKURAI_ANGLE_HIGH_GR:
			angle_f = FTCOMMON_DAMAGE_SAKURAI_ANGLE_HIGH_GR
	return angle_f

## 0x80140A94
static func ftCommonDamageGetDamageLevel(hitstun) -> int:
	var damage_level: int

	hitstun = f32(hitstun) # f32 parameter

	if hitstun < FTCOMMON_DAMAGE_LEVEL_HITSTUN_LOW:
		damage_level = 0 # DamageX1
	elif hitstun < FTCOMMON_DAMAGE_LEVEL_HITSTUN_MID:
		damage_level = 1 # DamageX2
	elif hitstun < FTCOMMON_DAMAGE_LEVEL_HITSTUN_HIGH:
		damage_level = 2 # DamageX3
	else:
		damage_level = 3 # Fighter becomes airborne

	return damage_level

## 0x80140B00
static func ftCommonDamageSetPublic(this_fp, knockback, angle) -> void:
	var attacker_gobj = Ftparam.ftParamGetPlayerNumGObj(this_fp.damage_player_num)
	var is_force_curr_knockback: int

	this_fp.status_vars.common.damage.public_knockback = knockback
	this_fp.public_knockback = 0.0

	# By default, if knockback angle is between 75 and 115 degrees, the crowd is 20% less likely to gasp
	if (angle > FTCOMMON_DAMAGE_PUBLIC_REACT_GASP_ANGLE_LOW) and (angle < FTCOMMON_DAMAGE_PUBLIC_REACT_GASP_ANGLE_HIGH):
		this_fp.status_vars.common.damage.public_knockback = f32(this_fp.status_vars.common.damage.public_knockback * FTCOMMON_DAMAGE_PUBLIC_REACT_GASP_KNOCKBACK_MUL) # f32 *=
	if (attacker_gobj != null) and (ftGetStruct(attacker_gobj).public_knockback >= FTCOMMON_DAMAGE_KNOCKBACK_VERYHIGH):
		is_force_curr_knockback = TRUE
	else:
		is_force_curr_knockback = FALSE

	Ftpublic.ftPublicCommonCheck(this_fp.fighter_gobj, this_fp.status_vars.common.damage.public_knockback, is_force_curr_knockback)

## 0x80140BCC
static func ftCommonDamageCheckElementSetColAnim(fighter_gobj, element, damage_level):
	var is_set_colanim

	match element:
		nGMHitElementFire:
			is_set_colanim = Ftparam.ftParamCheckSetFighterColAnimID(fighter_gobj, damage_level + nGMColAnimFighterDamageFireStart, 0)

		nGMHitElementElectric:
			is_set_colanim = Ftparam.ftParamCheckSetSkeletonColAnimID(fighter_gobj, damage_level)

		nGMHitElementFreezing:
			is_set_colanim = Ftparam.ftParamCheckSetFighterColAnimID(fighter_gobj, damage_level + nGMColAnimFighterDamageIceStart, 0)

		_:
			is_set_colanim = Ftparam.ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterDamageCommon, 0)

	return is_set_colanim

## 0x80140C50
static func ftCommonDamageCheckMakeScreenFlash(knockback, element) -> void:
	match element:
		nGMHitElementFire:
			if knockback > FTCOMMON_DAMAGE_KNOCKBACK_VERYHIGH:
				Ifscreenflash.ifScreenFlashSetColAnimID(nGMColAnimScreenFlashDamageFire, 0)

		nGMHitElementElectric:
			if knockback > FTCOMMON_DAMAGE_KNOCKBACK_VERYHIGH:
				Ifscreenflash.ifScreenFlashSetColAnimID(nGMColAnimScreenFlashDamageElectric, 0)

		nGMHitElementFreezing:
			if knockback > FTCOMMON_DAMAGE_KNOCKBACK_VERYHIGH:
				Ifscreenflash.ifScreenFlashSetColAnimID(nGMColAnimScreenFlashDamageIce, 0)

		_:
			if knockback > FTCOMMON_DAMAGE_KNOCKBACK_VERYHIGH:
				Ifscreenflash.ifScreenFlashSetColAnimID(nGMColAnimScreenFlashDamageNormal, 0)

## 0x80140D30
static func ftCommonDamageCheckCatchResist(fp) -> int:
	# Something to do with a fighter in Catch(Wait) being hit?

	if fp.damage_element == nGMHitElementSleep:
		return FALSE
	if fp.damage_knockback == 0.0:
		return TRUE
	if (fp.hitlag_tics > 0) and B(fp.is_knockback_paused) and (f32(fp.damage_knockback) < f32(fp.damage_knockback_stack + 30.0)):
		return TRUE
	if (fp.fkind == nFTKindDonkey) or (fp.fkind == nFTKindNDonkey) or (fp.fkind == nFTKindGDonkey):
		if (fp.status_id >= nFTDonkeyStatusThrowFStart) and (fp.status_id <= nFTDonkeyStatusThrowFEnd) and (ftCommonDamageGetDamageLevel(Ftparam.ftParamGetHitStun(f32(fp.damage_knockback))) < 3):
			return TRUE
	return FALSE

## 0x80140E2C
static func ftCommonDamageUpdateCatchResist(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.damage_knockback == 0.0) or ((fp.hitlag_tics > 0) and B(fp.is_knockback_paused) and (f32(fp.damage_knockback) < f32(fp.damage_knockback_stack + 30.0))):
		ftCommonDamageSetDamageColAnim(fighter_gobj)
	else:
		Ftparam.ftParamStopVoiceRunProcDamage(fighter_gobj)
		Ftdonkeythrowfdamage.ftDonkeyThrowFDamageSetStatus(fighter_gobj)

## 0x80140EC0
static func ftCommonDamageCheckCaptureKeepHold(fp) -> int:
	if fp.damage_queue < FTCOMMON_DAMAGE_CATCH_RELEASE_THRESHOLD:
		return TRUE
	else:
		return FALSE

## 0x80140EE4
static func ftCommonDamageInitDamageVars(this_gobj, status_id_replace, damage, knockback, angle_start, damage_lr,
damage_index, element, damage_player_num, is_rumble, is_force_damage_sfx, is_allow_losecopy) -> void:
	knockback = f32(knockback) # f32 parameter

	var this_fp := ftGetStruct(this_gobj)
	var attacker_gobj
	var angle_end: float = ftCommonDamageGetKnockbackAngle(angle_start, this_fp.ga, knockback)
	var vel_x: float = f32(f32(__cosf(angle_end)) * knockback)
	var vel_y: float = f32(f32(__sinf(angle_end)) * knockback)
	var hitstun_tics: float = f32(Ftparam.ftParamGetHitStun(knockback))
	var damage_level: int
	var status_id_set: int
	var status_id_var: int
	var vel_damage: Vector3
	var angle_diff: float

	this_fp.status_vars.common.damage.hitstun_tics = int(hitstun_tics) # f32 -> s32 (truncation)

	if this_fp.status_vars.common.damage.hitstun_tics == 0:
		this_fp.status_vars.common.damage.hitstun_tics = 1
	damage_level = ftCommonDamageGetDamageLevel(hitstun_tics)

	if status_id_replace != -1:
		damage_level = 3
	this_fp.lr = damage_lr

	if this_fp.ga == nMPKineticsAir:
		status_id_set = dFTCommonDamageStatusAirIDs[damage_level][damage_index]
		status_id_var = status_id_set

		this_fp.physics.vel_damage_air.x = -vel_x * this_fp.lr
		this_fp.physics.vel_damage_air.y = vel_y
		this_fp.physics.vel_damage_ground = 0.0
	else:
		vel_damage.x = -vel_x * this_fp.lr
		vel_damage.y = vel_y
		vel_damage.z = 0.0

		angle_diff = syVectorAngleDiff3D(this_fp.coll_data.floor_angle, vel_damage)

		# Knockback exactly along a flat floor (angle 0, e.g. the grounded low-knockback Sakurai
		# angle) gives syUtilsArcCos(0) = M_PI_F / 2.0F, bit-identical to F_CST_DTOR32(90.0F): the
		# strict test fails and the fighter stays grounded (ground knockback), as in the C.
		if angle_diff < F_CST_DTOR32(90.0):
			status_id_set = dFTCommonDamageStatusGroundIDs[damage_level][damage_index]
			status_id_var = status_id_set

			Mpcommon.mpCommonSetFighterAir(this_fp)

			this_fp.physics.vel_damage_air.x = vel_damage.x
			this_fp.physics.vel_damage_air.y = vel_damage.y
			this_fp.physics.vel_damage_ground = 0.0
		elif damage_level == 3:
			Mpcommon.mpCommonSetFighterAir(this_fp)

			status_id_set = dFTCommonDamageStatusGroundIDs[damage_level][damage_index]
			status_id_var = status_id_set

			if angle_diff > F_CST_DTOR32(100.0): # 1.7453293F
				this_fp.physics.vel_damage_air.x = vel_damage.x
				this_fp.physics.vel_damage_air.y = -vel_damage.y * FTCOMMON_DAMAGE_BOUNCE_VEL_MUL_F32 # 0.8F
				this_fp.physics.vel_damage_ground = 0.0

				Ftparam.ftParamMakeEffect(this_gobj, nEFKindImpactWave, nFTPartsJointTopN, Vector3.ZERO, Vector3.ZERO, this_fp.lr, 0, 0)
				Ftparam.ftParamMakeEffect(this_gobj, nEFKindQuakeMag0, nFTPartsJointTopN, Vector3.ZERO, Vector3.ZERO, this_fp.lr, 0, 0)
			else:
				this_fp.physics.vel_damage_air.x = vel_damage.x
				this_fp.physics.vel_damage_air.y = vel_damage.y
				this_fp.physics.vel_damage_ground = 0.0
		else:
			status_id_set = dFTCommonDamageStatusGroundIDs[damage_level][damage_index]
			status_id_var = status_id_set

			this_fp.physics.vel_damage_ground = (-vel_x * this_fp.lr)
			this_fp.physics.vel_damage_air.x = this_fp.coll_data.floor_angle.y * (-vel_x * this_fp.lr)
			this_fp.physics.vel_damage_air.y = -this_fp.coll_data.floor_angle.x * (-vel_x * this_fp.lr)

	this_fp.physics.vel_ground.x = 0.0
	this_fp.physics.vel_air.z = 0.0
	this_fp.physics.vel_air.y = 0.0
	this_fp.physics.vel_air.x = 0.0

	if (damage_level == 3) and (this_fp.ga == nMPKineticsAir):
		if (angle_end > FTCOMMON_DAMAGE_FIGHTER_FLYTOP_ANGLE_LOW) and (angle_end < FTCOMMON_DAMAGE_FIGHTER_FLYTOP_ANGLE_HIGH):
			status_id_set = nFTCommonStatusDamageFlyTop
			status_id_var = status_id_set
		# Short-circuit: the RNG is only advanced when percent_damage >= 100
		elif (this_fp.percent_damage >= FTCOMMON_DAMAGE_FIGHTER_FLYROLL_DAMAGE_MIN) and (syUtilsRandFloat() < FTCOMMON_DAMAGE_FIGHTER_FLYROLL_RANDOM_CHANCE):
			status_id_set = nFTCommonStatusDamageFlyRoll
			status_id_var = status_id_set
	if status_id_replace != -1:
		status_id_set = status_id_replace

	if ((element == nGMHitElementElectric) and (status_id_set >= nFTCommonStatusDamageStart)) and (status_id_set <= nFTCommonStatusDamageEnd):
		status_id_var = status_id_set

		status_id_set = nFTCommonStatusDamageE2 if (damage_level == 3) else nFTCommonStatusDamageE1
	this_fp.damage_player_num = damage_player_num

	ftCommonDamageSetPublic(this_fp, knockback, angle_end)

	if damage != 0:
		ftCommonDamageCheckElementSetColAnim(this_gobj, element, damage_level)
	ftCommonDamageCheckMakeScreenFlash(knockback, element)

	if (damage_level == 3) and B(is_allow_losecopy):
		Ftkirbyspecialn.ftKirbySpecialNDamageCheckLoseCopy(this_gobj)
	Ftmain.ftMainSetStatus(this_gobj, status_id_set, 0.0, 1.0, FTSTATUS_PRESERVE_DAMAGEPLAYER)
	Ftmain.ftMainPlayAnimEventsAll(this_gobj)

	if knockback >= 65000.0:
		this_fp.status_vars.common.damage.is_knockback_over = TRUE
	else:
		this_fp.status_vars.common.damage.is_knockback_over = FALSE

	if (this_fp.status_id == nFTCommonStatusDamageE1) or (this_fp.status_id == nFTCommonStatusDamageE2):
		this_fp.proc_passive = Callable(Ftcommondamage, &"ftCommonDamageSetStatus")
		this_fp.status_vars.common.damage.status_id = status_id_var
	else:
		this_fp.proc_passive = Callable(Ftcommondamage, &"ftCommonDamageCheckSetInvincible")

	this_fp.proc_lagupdate = Callable(Ftcommondamage, &"ftCommonDamageCommonProcLagUpdate")

	this_fp.tap_stick_y = FTINPUT_STICKBUFFER_TICS_MAX
	this_fp.tap_stick_x = this_fp.tap_stick_y

	this_fp.damage_knockback_stack = knockback

	if (damage_level == 3) or B(is_rumble):
		Ftparam.ftParamMakeRumble(this_fp, 2, 0)
	if this_fp.status_id == nFTCommonStatusDamageFlyRoll:
		ftCommonDamageFlyRollUpdateModelPitch(this_gobj)
	ftCommonDamageSetDustEffectInterval(this_fp)

	if this_fp.status_vars.common.damage.dust_effect_int != 0:
		this_fp.status_vars.common.damage.dust_effect_int = 1
	if ((hitstun_tics >= FTCOMMON_DAMAGE_FIGHTER_DAMAGEVOICE_MIN) and (this_fp.attr.damage_sfx != nSYAudioFGMVoiceEnd)) or B(is_force_damage_sfx):
		Snd.func_800269C0_275C0(this_fp.attr.damage_sfx)

	this_fp.is_hitstun = TRUE
	this_fp.tics_since_last_z = FTINPUT_ZTRIGLAST_TICS_MAX

	if (damage_level == 3) and (knockback >= FTCOMMON_DAMAGE_FIGHTER_PLAYERTAG_KNOCKBACK_MIN):
		Ftparam.ftParamSetPlayerTagWait(this_gobj, FTCOMMON_DAMAGE_FIGHTER_PLAYERTAG_HIDE_FRAMES)
	this_fp.status_vars.common.damage.coll_mask_curr = 0

	attacker_gobj = Ftparam.ftParamGetPlayerNumGObj(damage_player_num)

	if attacker_gobj != null:
		var attacker_fp := ftGetStruct(attacker_gobj)

		attacker_fp.attack_count += 1
		attacker_fp.attack_knockback = knockback

## 0x80141560 - Enter sleep or common damage state
static func ftCommonDamageGotoDamageStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.is_cliff_hold:
		fp.cliffcatch_wait = FTCOMMON_CLIFF_CATCH_WAIT
	if fp.damage_element == nGMHitElementSleep:
		Ftcommonfurasleep.ftCommonFuraSleepSetStatus(fighter_gobj)
	else:
		ftCommonDamageInitDamageVars(fighter_gobj, -1, fp.damage_queue, fp.damage_knockback, fp.damage_angle, fp.damage_lr, fp.damage_index, fp.damage_element, fp.damage_player_num, FALSE, FALSE, TRUE)

## 0x801415F8
static func ftCommonDamageUpdateDamageColAnim(fighter_gobj, knockback, element) -> void:
	knockback = f32(knockback) # f32 parameter

	if ftCommonDamageCheckElementSetColAnim(fighter_gobj, element, ftCommonDamageGetDamageLevel(Ftparam.ftParamGetHitStun(knockback))):
		Ftmain.ftMainRunUpdateColAnim(fighter_gobj)

## 0x80141648
static func ftCommonDamageSetDamageColAnim(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftCommonDamageUpdateDamageColAnim(fighter_gobj, fp.damage_knockback, fp.damage_element)

## 0x80141670
static func ftCommonDamageUpdateMain(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var grab_gobj = this_fp.catch_gobj
	var grab_fp: Fighter

	if grab_gobj != null:
		grab_fp = ftGetStruct(grab_gobj)

		if ftCommonDamageCheckCatchResist(this_fp) != FALSE:
			if grab_fp.damage_knockback != 0:
				if ftCommonDamageCheckCaptureKeepHold(grab_fp) != FALSE:
					grab_fp.damage_lag = this_fp.damage_lag
					grab_fp.hitlag_mul = this_fp.hitlag_mul

					ftCommonDamageUpdateCatchResist(fighter_gobj)

					grab_fp.damage_kind = nFTDamageKindColAnim
				else:
					Ftcommonthrown2.ftCommonThrownDecideFighterLoseGrip(fighter_gobj, grab_gobj)
					Ftparam.ftParamStopVoiceRunProcDamage(fighter_gobj)
					ftCommonDamageGotoDamageStatus(fighter_gobj)

					grab_fp.damage_kind = nFTDamageKindStatus
			else:
				ftCommonDamageUpdateCatchResist(fighter_gobj)
		elif grab_fp.damage_knockback != 0:
			if ftCommonDamageCheckCaptureKeepHold(grab_fp) != FALSE:
				Ftcommonthrown2.ftCommonThrownUpdateDamageStats(grab_fp)
			Ftcommonthrown2.ftCommonThrownDecideFighterLoseGrip(fighter_gobj, grab_gobj)
			Ftparam.ftParamStopVoiceRunProcDamage(fighter_gobj)
			ftCommonDamageGotoDamageStatus(fighter_gobj)

			grab_fp.damage_kind = nFTDamageKindStatus
		else:
			Ftparam.ftParamStopVoiceRunProcDamage(grab_gobj)
			Ftcommonthrown2.ftCommonThrownSetStatusDamageRelease(grab_gobj)

			if this_fp.is_catch_or_capture:
				Ftcommonthrown2.ftCommonThrownReleaseFighterLoseGrip(fighter_gobj)
			this_fp.catch_gobj = null

			Ftparam.ftParamStopVoiceRunProcDamage(fighter_gobj)
			ftCommonDamageGotoDamageStatus(fighter_gobj)
		return
	else:
		grab_gobj = this_fp.capture_gobj

	if grab_gobj != null:
		grab_fp = ftGetStruct(grab_gobj)

		if ftCommonDamageCheckCaptureKeepHold(this_fp) != FALSE:
			if grab_fp.damage_knockback != 0:
				if ftCommonDamageCheckCatchResist(grab_fp) != FALSE:
					this_fp.damage_lag = grab_fp.damage_lag
					this_fp.hitlag_mul = grab_fp.hitlag_mul
					grab_fp.damage_kind = nFTDamageKindCatch

					ftCommonDamageSetDamageColAnim(fighter_gobj)
				else:
					Ftcommonthrown2.ftCommonThrownUpdateDamageStats(this_fp)
					Ftcommonthrown2.ftCommonThrownDecideFighterLoseGrip(grab_gobj, fighter_gobj)
					Ftparam.ftParamStopVoiceRunProcDamage(fighter_gobj)
					ftCommonDamageGotoDamageStatus(fighter_gobj)

					grab_fp.damage_kind = nFTDamageKindStatus
			else:
				grab_fp.hitlag_tics = Ftparam.ftParamGetHitLag(this_fp.damage_lag, grab_fp.status_id, grab_fp.hitlag_mul)

				this_fp.input.pl.button_release = 0
				this_fp.input.pl.button_tap = this_fp.input.pl.button_release

				if this_fp.proc_lagstart.is_valid():
					this_fp.proc_lagstart.call(fighter_gobj)
				ftCommonDamageSetDamageColAnim(fighter_gobj)
		elif grab_fp.damage_knockback != 0:
			Ftcommonthrown2.ftCommonThrownDecideFighterLoseGrip(grab_gobj, fighter_gobj)
			Ftparam.ftParamStopVoiceRunProcDamage(fighter_gobj)
			ftCommonDamageGotoDamageStatus(fighter_gobj)

			grab_fp.damage_kind = nFTDamageKindStatus
		else:
			Ftcommonthrown2.ftCommonThrownDecideFighterLoseGrip(grab_gobj, fighter_gobj)
			Ftparam.ftParamStopVoiceRunProcDamage(fighter_gobj)
			ftCommonDamageGotoDamageStatus(fighter_gobj)
			Ftparam.ftParamStopVoiceRunProcDamage(grab_gobj)
			Ftcommonthrown2.ftCommonThrownSetStatusNoDamageRelease(grab_gobj)
		return
	if this_fp.item_gobj != null:
		if (itGetStruct(this_fp.item_gobj).weight == nITWeightHeavy) and ((this_fp.fkind == nFTKindDonkey) or (this_fp.fkind == nFTKindNDonkey) or (this_fp.fkind == nFTKindGDonkey)):
			if ftCommonDamageCheckCatchResist(this_fp) != FALSE:
				ftCommonDamageUpdateCatchResist(fighter_gobj)
			else:
				# ftSetupDropItem(this_fp) (macro in fighter.h)
				var vel := Vector3.ZERO

				Itmain.itMainSetFighterDrop(this_fp.item_gobj, vel, 1.0)

				Ftparam.ftParamStopVoiceRunProcDamage(fighter_gobj)
				ftCommonDamageGotoDamageStatus(fighter_gobj)
			return
	if (this_fp.damage_element != nGMHitElementSleep) and ((this_fp.damage_knockback == 0.0) or ((this_fp.hitlag_tics > 0) and B(this_fp.is_knockback_paused) and (f32(this_fp.damage_knockback) < f32(this_fp.damage_knockback_stack + 30.0)))):
		ftCommonDamageSetDamageColAnim(fighter_gobj)
	else:
		Ftparam.ftParamStopVoiceRunProcDamage(fighter_gobj)
		ftCommonDamageGotoDamageStatus(fighter_gobj)
