## 1:1 port of src/ft/ftcommon/ftcommonshieldbreakfly.c (ssb-decomp-re): launched upward after a
## shield (or reflector) break (ShieldBreakFly).
class_name Ftcommonshieldbreakfly
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80149440
static func ftCommonShieldBreakFlyProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommonshieldbreakfall, &"ftCommonShieldBreakFallSetStatus"))

## 0x80149464
static func ftCommonShieldBreakFlyProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftcommonshieldbreakdown, &"ftCommonShieldBreakDownSetStatus"))

## 0x80149488
static func ftCommonShieldBreakFlySetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusShieldBreakFly, 0.0, 1.0, FTSTATUS_PRESERVE_DAMAGEPLAYER)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.physics.vel_air.x = 0.0
	fp.physics.vel_air.y = attr.shield_break_vel_y

	Ftparam.ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterShieldBreakFly, 0)
	Snd.func_800269C0_275C0(nSYAudioFGMShieldBreak)

## 0x80149510
static func ftCommonShieldBreakFlyCommonSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var offset = Vector3.ZERO

	offset.x = 0.0
	offset.y = 0.0
	offset.z = 0.0

	offset = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[nFTPartsJointYRotN], offset)

	if fp.fkind == nFTKindYoshi:
		Efmanager.efManagerYoshiEggExplodeMakeEffect(DObjGetStruct(fighter_gobj).translate)
		Efmanager.efManagerEggBreakMakeEffect(DObjGetStruct(fighter_gobj).translate)
	else:
		Efmanager.efManagerShieldBreakMakeEffect(offset)

	Ftparam.ftParamUpdate1PGameDamageStats(fp, fp.shield_player, nFTHitLogObjectNone, 0, 0, 0)

	if (G.gSCManagerBattleState.game_type == nSCBattleGameType1PGame) and (fp.shield_damage != 0):
		if (fp.shield_player == G.gSCManagerSceneData.player) and (fp.shield_player != fp.player):
			G.gSC1PGameBonusShieldBreaker = TRUE
	ftCommonShieldBreakFlySetStatus(fighter_gobj)

## 0x80149608
static func ftCommonShieldBreakFlyReflectorSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var special_coll: FTSpecialColl = fp.special_coll
	var offset = special_coll.offset

	offset = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[special_coll.joint_id], offset)
	Efmanager.efManagerReflectBreakMakeEffect(offset, fp.reflect_lr)
	ftCommonShieldBreakFlySetStatus(fighter_gobj)
