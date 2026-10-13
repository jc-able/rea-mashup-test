## 1:1 port of src/ft/ftcommon/ftcommonpassivestand.c (ssb-decomp-re): tech roll (PassiveStandF / B).
class_name Ftcommonpassivestand
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80144700
static func ftCommonPassiveStandSetStatus(fighter_gobj, status_id) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsAir:
		Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftparam.ftParamVelDamageTransferGround(fp)

## 0x80144760
static func ftCommonPassiveStandCheckInterruptDamage(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int

	if fp.tics_since_last_z < FTCOMMON_PASSIVE_BUFFER_TICS_MAX:
		if ABS(fp.input.pl.stick_range.x) >= FTCOMMON_PASSIVE_F_OR_B_RANGE:
			if (fp.input.pl.stick_range.x * fp.lr) >= 0:
				status_id = nFTCommonStatusPassiveStandF
			else:
				status_id = nFTCommonStatusPassiveStandB

			ftCommonPassiveStandSetStatus(fighter_gobj, status_id)

			return TRUE
	return FALSE
