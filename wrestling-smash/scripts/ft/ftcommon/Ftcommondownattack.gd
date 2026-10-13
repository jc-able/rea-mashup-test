## 1:1 port of src/ft/ftcommon/ftcommondownattack.c (ssb-decomp-re): getup attack from knockdown (DownAttack).
class_name Ftcommondownattack
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80144910
static func ftCommonDownAttackSetStatus(fighter_gobj, status_id) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80144944
static func ftCommonDownAttackCheckInterruptDownBounce(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int

	if fp.status_vars.common.downbounce.attack_buffer != 0:
		if fp.status_id == nFTCommonStatusDownBounceD:
			status_id = nFTCommonStatusDownAttackD
		else:
			status_id = nFTCommonStatusDownAttackU

		ftCommonDownAttackSetStatus(fighter_gobj, status_id)

		return TRUE
	else:
		return FALSE

## 0x8014499C
static func ftCommonDownAttackCheckInterruptDownWait(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int

	if fp.input.pl.button_tap & (fp.input.button_mask_a | fp.input.button_mask_b):
		if fp.status_id == nFTCommonStatusDownWaitD:
			status_id = nFTCommonStatusDownAttackD
		else:
			status_id = nFTCommonStatusDownAttackU

		ftCommonDownAttackSetStatus(fighter_gobj, status_id)

		return TRUE
	else:
		return FALSE
