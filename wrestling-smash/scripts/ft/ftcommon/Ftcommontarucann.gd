## 1:1 port of src/ft/ftcommon/ftcommontarucann.c (ssb-decomp-re): TaruCann (inside Kongo Jungle's
## Barrel Cannon).
class_name Ftcommontarucann
extends Port

## FTThrowHitDesc *tarucann = (gMPCollisionGroundData - &llGRJungleMapMapHeader) + &llGRJungleMapTaruCannThrowHitDesc
## Transcribed from src/relocData/261_GRJungleMap.c dGRJungleMap_TaruCannThrow_HitDesc = { 3, 0, 90, 0, 0, 180, 0 }.
const dGRJungleMapTaruCannThrowHitDesc: Dictionary = {
	"status_id": 3, "damage": 0, "angle": 90, "knockback_scale": 0, "knockback_weight": 0, "knockback_base": 180, "element": 0
}

## PI32 (3.1415927F) as the f32 value the N64 uses.
const PI32_F32 := 3.1415927410125732

## C f32 arithmetic (single-precision rounding of an intermediate result).
static func _f32(x: float) -> float:
	return Vector2(x, 0.0).x

## I_CLC_RTOD32(x) (( int )(((x) / PI32) * 180.0F)) evaluated in f32 like the N64, since the result
## is truncated to an integer angle.
static func _I_CLC_RTOD32(x: float) -> int:
	return int(_f32(_f32(_f32(x) / PI32_F32) * 180.0))

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80143E10
static func ftCommonTaruCannProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.common.tarucann.shoot_wait != 0:
		fp.status_vars.common.tarucann.shoot_wait -= 1

		if fp.status_vars.common.tarucann.shoot_wait == (FTCOMMON_TARUCANN_SHOOT_WAIT / 2):
			Snd.func_800269C0_275C0(nSYAudioFGMJungleTaruCannShoot)
		if fp.status_vars.common.tarucann.shoot_wait == 0:
			ftCommonTaruCannShootFighter(fighter_gobj)

			return
	fp.status_vars.common.tarucann.release_wait += 1

	if (fp.status_vars.common.tarucann.release_wait >= FTCOMMON_TARUCANN_RELEASE_WAIT) and (fp.status_vars.common.tarucann.shoot_wait == 0):
		fp.status_vars.common.tarucann.shoot_wait = FTCOMMON_TARUCANN_SHOOT_WAIT

		Grjungle.grJungleTaruCannAddAnimShoot(fp.status_vars.common.tarucann.tarucann_gobj)

## 0x80143EB0
static func ftCommonTaruCannProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.status_vars.common.tarucann.shoot_wait == 0) and (fp.input.pl.button_tap & (fp.input.button_mask_a | fp.input.button_mask_b)):
		fp.status_vars.common.tarucann.shoot_wait = FTCOMMON_TARUCANN_SHOOT_WAIT

		Grjungle.grJungleTaruCannAddAnimShoot(fp.status_vars.common.tarucann.tarucann_gobj)

## 0x80143F04
static func ftCommonTaruCannProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var tarucann_gobj = fp.status_vars.common.tarucann.tarucann_gobj

	DObjGetStruct(fighter_gobj).translate = DObjGetStruct(tarucann_gobj).translate

## 0x80143F30
static func ftCommonTaruCannSetStatus(fighter_gobj, tarucann_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftparam.ftParamStopVoiceRunProcDamage(fighter_gobj)

	if (fp.item_gobj != null) and (itGetStruct(fp.item_gobj).weight == nITWeightHeavy):
		Itmain.itMainSetFighterDrop(fp.item_gobj, Vector3.ZERO, 1.0)    # ftSetupDropItem(fp)
	if fp.catch_gobj != null:
		Ftcommonthrown2.ftCommonThrownSetStatusDamageRelease(fp.catch_gobj)

		fp.catch_gobj = null
	elif fp.capture_gobj != null:
		Ftcommonthrown2.ftCommonThrownDecideFighterLoseGrip(fp.capture_gobj, fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusTaruCann, 0.0, 0.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	Ftphysics.ftPhysicsStopVelAll(fighter_gobj)

	fp.status_vars.common.tarucann.shoot_wait = 0
	fp.status_vars.common.tarucann.release_wait = 0
	fp.status_vars.common.tarucann.tarucann_gobj = tarucann_gobj

	Ftparam.ftParamSetHitStatusAll(fighter_gobj, nGMHitStatusIntangible)

	fp.is_invisible = TRUE

	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)
	Snd.func_800269C0_275C0(nSYAudioFGMJungleTaruCannEnter)

## 0x80144038
static func ftCommonTaruCannShootFighter(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var tarucann: Dictionary = dGRJungleMapTaruCannThrowHitDesc
	var knockback: float
	var angle: int

	DObjGetStruct(fighter_gobj).translate.z = 0.0

	knockback = Ftparam.ftParamGetGroundHazardKnockback(fp.percent_damage, tarucann.damage, tarucann.damage, tarucann.knockback_weight, tarucann.knockback_scale, tarucann.knockback_base, fp.attr.weight, 9, 9)

	angle = ((_I_CLC_RTOD32(Grjungle.grJungleTaruCannGetRotate()) * -fp.lr) + 90)
	angle -= (angle / 360) * 360

	Ftcommondamage.ftCommonDamageInitDamageVars(fighter_gobj, nFTCommonStatusDamageFlyRoll, tarucann.damage, knockback, angle, fp.lr, 0, tarucann.element, 0, TRUE, TRUE, FALSE)
	Ftparam.ftParamUpdate1PGameDamageStats(fp, GMCOMMON_PLAYERS_MAX, nFTHitLogObjectGround, nGMHitEnvironmentTaruCann, 0, 0)

	fp.playertag_wait = 0
	fp.tarucann_wait = FTCOMMON_TARUCANN_PICKUP_WAIT
