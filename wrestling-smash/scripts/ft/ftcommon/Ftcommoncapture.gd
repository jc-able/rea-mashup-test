## 1:1 port of src/ft/ftcommon/ftcommoncapture.c (ssb-decomp-re): grab breakout (mash) helpers,
## breakout knockback, and the Shouldered (Donkey Kong cargo) capture status.
class_name Ftcommoncapture
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x80188A30 - FTThrowReleaseDesc { 361, 100, 30, 0 }: knockback suffered by throwing player
static var dFTCommonCaptureKnockbackCatch: Dictionary = {"angle": 361, "knockback_scale": 100, "knockback_weight": 30, "knockback_base": 0}

## 0x80188A40 - FTThrowReleaseDesc { 361, 80, 0, 20 }: knockback suffered by caught player
static var dFTCommonCaptureKnockbackCapture: Dictionary = {"angle": 361, "knockback_scale": 80, "knockback_weight": 0, "knockback_base": 20}

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8014E1D0
static func ftCommonCaptureApplyCatchKnockback(fighter_gobj, throw_release) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var catch_gobj = this_fp.catch_gobj
	var catch_fp := ftGetStruct(catch_gobj)
	var knockback: float = Ftparam.ftParamGetCommonKnockback(this_fp.percent_damage, 0, 0, throw_release.knockback_weight, throw_release.knockback_scale, throw_release.knockback_base, this_fp.attr.weight, catch_fp.handicap, this_fp.handicap)

	Ftcommondamage.ftCommonDamageInitDamageVars(fighter_gobj, -1, 0, knockback, throw_release.angle, this_fp.lr, 1, 0, 0, FALSE, FALSE, FALSE)
	Ftparam.ftParamUpdate1PGameDamageStats(this_fp, GMCOMMON_PLAYERS_MAX, nFTHitLogObjectNone, 0, 0, 0)

## 0x8014E2A8
static func ftCommonCaptureApplyCaptureKnockback(fighter_gobj, throw_release) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var capture_gobj = this_fp.capture_gobj
	var capture_fp := ftGetStruct(capture_gobj)
	var knockback: float
	var lr: int

	Ftcommonthrown2.ftCommonThrownReleaseFighterLoseGrip(fighter_gobj)

	if this_fp.ga == nMPKineticsAir:
		this_fp.jumps_used = 1

		DObjGetStruct(fighter_gobj).translate.z = 0.0

		this_fp.physics.vel_air.z = DObjGetStruct(fighter_gobj).translate.z
	knockback = Ftparam.ftParamGetCommonKnockback(this_fp.percent_damage, 0, 0, throw_release.knockback_weight, throw_release.knockback_scale, throw_release.knockback_base, this_fp.attr.weight, capture_fp.handicap, this_fp.handicap)

	if DObjGetStruct(fighter_gobj).translate.x < DObjGetStruct(capture_gobj).translate.x:
		lr = +1
	else:
		lr = -1

	Ftcommondamage.ftCommonDamageInitDamageVars(fighter_gobj, -1, 0, knockback, throw_release.angle, lr, 1, 0, 0, FALSE, FALSE, FALSE)
	Ftparam.ftParamUpdate1PGameDamageStats(this_fp, GMCOMMON_PLAYERS_MAX, nFTHitLogObjectNone, 0, 0, 0)

## 0x8014E3EC
static func ftCommonCaptureTrappedInitBreakoutVars(fp, breakout_wait) -> void:
	# s32 breakout_wait (callers passing an f32 expression get C's implicit truncation)
	fp.breakout_wait = int(breakout_wait)
	fp.breakout_ud = 0
	fp.breakout_lr = fp.breakout_ud

## 0x8014E400
static func ftCommonCaptureTrappedUpdateBreakoutVars(fp) -> int:
	var is_mash: int = FALSE
	var breakout_lr_bak: int
	var breakout_ud_bak: int

	if (fp.input.pl.button_tap & fp.input.button_mask_a) or (fp.input.pl.button_tap & fp.input.button_mask_b) or (fp.input.pl.button_tap & fp.input.button_mask_z):
		is_mash = TRUE

		fp.breakout_wait -= 1
	breakout_lr_bak = fp.breakout_lr
	breakout_ud_bak = fp.breakout_ud

	if fp.input.pl.stick_range.x < -FTCOMMON_CAPTURE_MASH_STICK_RANGE_MIN:
		fp.breakout_lr = -1
	if fp.input.pl.stick_range.x > FTCOMMON_CAPTURE_MASH_STICK_RANGE_MIN:
		fp.breakout_lr = +1
	if fp.input.pl.stick_range.y < -FTCOMMON_CAPTURE_MASH_STICK_RANGE_MIN:
		fp.breakout_ud = -1
	if fp.input.pl.stick_range.y > FTCOMMON_CAPTURE_MASH_STICK_RANGE_MIN:
		fp.breakout_ud = +1
	if (fp.breakout_lr != breakout_lr_bak) or (fp.breakout_ud != breakout_ud_bak):
		is_mash = TRUE

		fp.breakout_wait -= 1
	return is_mash

## 0x8014E4D4
static func ftCommonCaptureShoulderedProcInterrupt(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var capture_gobj = this_fp.capture_gobj
	var capture_fp := ftGetStruct(capture_gobj)

	ftCommonCaptureTrappedUpdateBreakoutVars(this_fp)

	if this_fp.breakout_wait <= 0:
		ftCommonCaptureApplyCatchKnockback(capture_gobj, dFTCommonCaptureKnockbackCatch) # Deal knockback to player this fighter is caught by
		ftCommonCaptureApplyCaptureKnockback(fighter_gobj, dFTCommonCaptureKnockbackCapture) # Deal knockback to this fighter

		capture_fp.catch_gobj = null
		this_fp.capture_gobj = null

## 0x8014E558
static func ftCommonCaptureShoulderedSetStatus(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var capture_gobj = this_fp.capture_gobj
	var capture_fp := ftGetStruct(capture_gobj)
	var damage: int

	Ftcommonthrown1.ftCommonThrownSetStatusImmediate(fighter_gobj, nFTCommonStatusShouldered)

	# REGION_US: (s32)((percent_damage * 0.08F) + 14.0F)
	ftCommonCaptureTrappedInitBreakoutVars(this_fp, int((this_fp.percent_damage * 0.08) + 14.0))

	damage = Ftparam.ftParamGetStaledDamage(capture_fp.player, 8, capture_fp.motion_attack_id, capture_fp.motion_count)

	if Ftparam.ftParamGetBestHitStatusAll(fighter_gobj) != nGMHitStatusNormal:
		damage = 0
	if damage != 0:
		Ftcommondamage.ftCommonDamageUpdateDamageColAnim(fighter_gobj, Ftparam.ftParamGetCommonKnockback(this_fp.percent_damage, damage, damage, 0, 100, 0, this_fp.attr.weight, capture_fp.handicap, this_fp.handicap), 0)
		Ftparam.ftParamUpdateDamage(this_fp, damage)
		Ftparam.ftParamUpdatePlayerBattleStats(capture_fp.player, this_fp.player, damage)
		Ftparam.ftParamUpdateStaleQueue(capture_fp.player, this_fp.player, capture_fp.motion_attack_id, capture_fp.motion_count)
	Ftparam.ftParamMakeRumble(this_fp, 7, 0)
