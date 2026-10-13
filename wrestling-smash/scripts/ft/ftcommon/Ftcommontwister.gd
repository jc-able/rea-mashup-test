## 1:1 port of src/ft/ftcommon/ftcommontwister.c (ssb-decomp-re): Twister (caught in Hyrule Castle's tornado).
class_name Ftcommontwister
extends Port

## FTThrowHitDesc *tornado = (gMPCollisionGroundData - &llGRHyruleMapMapHeader) + &llGRHyruleMapTwisterThrowHitDesc
## Transcribed from src/relocData/265_GRHyruleMap.c dGRHyruleMap_TwisterThrow_HitDesc = { 2, 14, 90, 60, 0, 115, 0 }.
const dGRHyruleMapTwisterThrowHitDesc: Dictionary = {
	"status_id": 2, "damage": 14, "angle": 90, "knockback_scale": 60, "knockback_weight": 0, "knockback_base": 115, "element": 0
}

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801439D0
static func ftCommonTwisterProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.common.twister.release_wait += 1

	if fp.status_vars.common.twister.release_wait >= FTCOMMON_TORNADO_RELEASE_WAIT:
		ftCommonTwisterShootFighter(fighter_gobj)

## 0x80143A20
static func ftCommonTwisterProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var tornado_gobj = fp.status_vars.common.twister.tornado_gobj
	var pos: Vector3 = DObjGetStruct(tornado_gobj).translate
	var vel: Vector3
	var mul: float
	var angle_d: float
	var mag: float

	angle_d = (fp.status_vars.common.twister.release_wait * 0.016666668)
	mul = (((400.0 * angle_d) + 100.0) * 0.5)

	pos.x += (mul * lbCommonCos(F_CLC_DTOR32(1800.0 * angle_d)))
	pos.z += (mul * lbCommonSin(F_CLC_DTOR32(1800.0 * angle_d)))
	pos.y += 500.0 * angle_d

	# syVectorDiff3D(&vel, &pos, &DObjGetStruct(fighter_gobj)->translate)
	vel.x = pos.x - DObjGetStruct(fighter_gobj).translate.x
	vel.y = pos.y - DObjGetStruct(fighter_gobj).translate.y
	vel.z = pos.z - DObjGetStruct(fighter_gobj).translate.z

	mag = syVectorMag3D(vel)

	if mag > 50.0:
		# syVectorScale3D(&vel, 50.0F / mag)
		var scale: float = 50.0 / mag

		vel.x *= scale
		vel.y *= scale
		vel.z *= scale
	fp.physics.vel_air = vel

	DObjGetStruct(fighter_gobj).rotate.y = (fp.lr * F_CLC_DTOR32(90.0)) + F_CLC_DTOR32(1800.0 * angle_d)

## 0x80143BC4
static func ftCommonTwisterSetStatus(fighter_gobj, tornado_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftparam.ftParamStopVoiceRunProcDamage(fighter_gobj)

	if (fp.item_gobj != null) and (itGetStruct(fp.item_gobj).weight == nITWeightHeavy):
		Itmain.itMainSetFighterDrop(fp.item_gobj, Vector3.ZERO, 1.0)    # ftSetupDropItem(fp)
	if fp.catch_gobj != null:
		Ftcommonthrown2.ftCommonThrownSetStatusDamageRelease(fp.catch_gobj)

		fp.catch_gobj = null
	elif fp.capture_gobj != null:
		Ftcommonthrown2.ftCommonThrownDecideFighterLoseGrip(fp.capture_gobj, fighter_gobj)
	if fp.ga == nMPKineticsGround:
		Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusTwister, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	Ftphysics.ftPhysicsStopVelAll(fighter_gobj)

	fp.status_vars.common.twister.release_wait = 0
	fp.status_vars.common.twister.tornado_gobj = tornado_gobj

	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)
	Snd.func_800269C0_275C0(nSYAudioFGMHyruleTwisterTrapped)

## 0x80143CC4
static func ftCommonTwisterShootFighter(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var tornado: Dictionary = dGRHyruleMapTwisterThrowHitDesc
	var knockback: float
	var damage: int

	DObjGetStruct(fighter_gobj).translate.z = 0.0

	knockback = Ftparam.ftParamGetCommonKnockback(fp.percent_damage, tornado.damage, tornado.damage, tornado.knockback_weight, tornado.knockback_scale, tornado.knockback_base, fp.attr.weight, 9, fp.handicap)

	if Ftparam.ftParamGetBestHitStatusAll(fighter_gobj) != nGMHitStatusNormal:
		damage = 0
	else:
		damage = tornado.damage

	Ftcommondamage.ftCommonDamageInitDamageVars(fighter_gobj, -1, damage, knockback, tornado.angle, fp.lr, 0, tornado.element, 0, TRUE, TRUE, TRUE)
	Ftparam.ftParamUpdate1PGameDamageStats(fp, GMCOMMON_PLAYERS_MAX, nFTHitLogObjectGround, nGMHitEnvironmentTwister, 0, 0)

	if damage != 0:
		Ftparam.ftParamUpdateDamage(fp, damage)
	fp.twister_wait = FTCOMMON_TORNADO_PICKUP_WAIT
