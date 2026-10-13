## 1:1 port of src/ft/ftcommon/ftcommonfall.c (ssb-decomp-re): Fall / FallAerial.
class_name Ftcommonfall
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8013F9A0
static func ftCommonFallProcInterrupt(fighter_gobj) -> void:
	if (not Ftcommonspecialair.ftCommonSpecialAirCheckInterruptCommon(fighter_gobj)) and (not Ftcommonattackair.ftCommonAttackAirCheckInterruptCommon(fighter_gobj)):
		Ftcommonjumpaerial.ftCommonJumpAerialCheckInterruptCommon(fighter_gobj)

## 0x8013F9E0
static func ftCommonFallSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if Fthammer.ftHammerCheckHoldHammer(fighter_gobj):
		Ftcommonhammerfall.ftCommonHammerFallSetStatus(fighter_gobj)
	else:
		if fp.ga == nMPKineticsGround:
			Mpcommon.mpCommonSetFighterAir(fp)
		Ftmain.ftMainSetStatus(fighter_gobj, (nFTCommonStatusFallAerial if (fp.jumps_used >= fp.attr.jumps_max) else nFTCommonStatusFall), 0.0, 1.0, FTSTATUS_PRESERVE_FASTFALL)

		Ftphysics.ftPhysicsClampAirVelXMax(fp)

		fp.is_special_interrupt = TRUE
