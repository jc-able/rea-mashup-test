## 1:1 port of src/ft/ftcommon/ftcommondamagefall.c (ssb-decomp-re): tumble (DamageFall) status.
class_name Ftcommondamagefall
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80143560
static func ftCommonDamageFallProcInterrupt(fighter_gobj) -> void:
	if (
		not Ftcommonspecialair.ftCommonSpecialAirCheckInterruptCommon(fighter_gobj) and
		not Ftcommonattackair.ftCommonAttackAirCheckInterruptCommon(fighter_gobj) and
		not Ftcommonjumpaerial.ftCommonJumpAerialCheckInterruptCommon(fighter_gobj)
	):
		Ftcommonhammerfall.ftCommonHammerFallCheckInterruptDamageFall(fighter_gobj)

## 0x801435B0
static func ftCommonDamageFallProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if Mpcommon.mpCommonCheckFighterCliff(fighter_gobj):
		if fp.coll_data.mask_stat & MAP_FLAG_CLIFF_MASK:
			Ftcommoncliffcatchwait.ftCommonCliffCatchSetStatus(fighter_gobj)
		elif not Ftcommonpassivestand.ftCommonPassiveStandCheckInterruptDamage(fighter_gobj) and not Ftcommonpassive.ftCommonPassiveCheckInterruptDamage(fighter_gobj):
			Ftcommondownwaitbounce.ftCommonDownBounceSetStatus(fighter_gobj)

## 0x80143630
static func ftCommonDamageFallClampRumble(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftphysics.ftPhysicsClampAirVelXMax(fp)
	Ftparam.ftParamMakeRumble(fp, 3, 0)

## 0x80143664
static func ftCommonDamageFallSetStatusFromDamage(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusDamageFall, 0.0, 1.0, (FTSTATUS_PRESERVE_PLAYERTAG | FTSTATUS_PRESERVE_FASTFALL))
	ftCommonDamageFallClampRumble(fighter_gobj)

## 0x801436A0
static func ftCommonDamageFallSetStatusFromCliffWait(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusDamageFall, 0.0, 1.0, FTSTATUS_PRESERVE_FASTFALL)
	ftCommonDamageFallClampRumble(fighter_gobj)

	fp.tics_since_last_z = FTINPUT_ZTRIGLAST_TICS_MAX

## 0x801436F0
static func func_ovl3_801436F0(fighter_gobj) -> void: # Unused
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusDamageFall, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_PLAYERTAG | FTSTATUS_PRESERVE_FASTFALL))
	ftCommonDamageFallClampRumble(fighter_gobj)
