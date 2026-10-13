## 1:1 port of src/ft/ftcommon/ftcommoncliffattack.c (ssb-decomp-re): ledge attack (CliffAttackQuick/Slow 1/2).
class_name Ftcommoncliffattack
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80145620
static func ftCommonCliffAttackCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if fp.input.pl.button_tap & (fp.input.button_mask_a | fp.input.button_mask_b):
		Ftcommoncliffclimb.ftCommonCliffQuickOrSlowSetStatus(fighter_gobj, nFTCommonCliffKindAttackQuick)

		return TRUE
	else:
		return FALSE

## 0x8014566C
static func ftCommonCliffAttackQuick1ProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommoncliffattack, &"ftCommonCliffAttackQuick2SetStatus"))

## 0x80145690
static func ftCommonCliffAttackSlow1ProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommoncliffattack, &"ftCommonCliffAttackSlow2SetStatus"))

## 0x801456B4
static func ftCommonCliffAttackQuick1SetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCliffAttackQuick1, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.is_cliff_hold = TRUE

	fp.proc_damage = Callable(Ftcommoncliffcatchwait, &"ftCommonCliffCommonProcDamage")

## 0x80145704
static func ftCommonCliffAttackSlow1SetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCliffAttackSlow1, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.is_cliff_hold = TRUE

	fp.proc_damage = Callable(Ftcommoncliffcatchwait, &"ftCommonCliffCommonProcDamage")

## 0x80145754
static func ftCommonCliffAttackQuick2SetStatus(fighter_gobj) -> void:
	Ftcommoncliffclimb.ftCommonCliffCommon2UpdateCollData(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCliffAttackQuick2, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftcommoncliffclimb.ftCommonCliffCommon2InitStatusVars(fighter_gobj)

## 0x80145794
static func ftCommonCliffAttackSlow2SetStatus(fighter_gobj) -> void:
	Ftcommoncliffclimb.ftCommonCliffCommon2UpdateCollData(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCliffAttackSlow2, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftcommoncliffclimb.ftCommonCliffCommon2InitStatusVars(fighter_gobj)
