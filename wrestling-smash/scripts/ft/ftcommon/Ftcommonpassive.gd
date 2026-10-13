## 1:1 port of src/ft/ftcommon/ftcommonpassive.c (ssb-decomp-re): in-place tech (Passive).
class_name Ftcommonpassive
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80144660
static func ftCommonPassiveSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsAir:
		Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusPassive, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftparam.ftParamVelDamageTransferGround(fp)

## 0x801446BC
static func ftCommonPassiveCheckInterruptDamage(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if fp.tics_since_last_z < FTCOMMON_PASSIVE_BUFFER_TICS_MAX:
		ftCommonPassiveSetStatus(fighter_gobj)

		return TRUE
	else:
		return FALSE
