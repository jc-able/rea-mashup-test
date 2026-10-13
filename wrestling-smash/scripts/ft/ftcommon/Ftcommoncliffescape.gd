## 1:1 port of src/ft/ftcommon/ftcommoncliffescape.c (ssb-decomp-re): ledge roll (CliffEscapeQuick/Slow 1/2).
class_name Ftcommoncliffescape
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801457E0
static func ftCommonCliffEscapeCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if fp.input.pl.button_tap & fp.input.button_mask_z:
		Ftcommoncliffclimb.ftCommonCliffQuickOrSlowSetStatus(fighter_gobj, 2)

		return TRUE
	else:
		return FALSE

## 0x80145824
static func ftCommonCliffEscapeQuick1ProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommoncliffescape, &"ftCommonCliffEscapeQuick2SetStatus"))

## 0x80145848
static func ftCommonCliffEscapeSlow1ProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommoncliffescape, &"ftCommonCliffEscapeSlow2SetStatus"))

## 0x8014586C
static func ftCommonCliffEscapeQuick1SetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCliffEscapeQuick1, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.is_cliff_hold = TRUE

	fp.proc_damage = Callable(Ftcommoncliffcatchwait, &"ftCommonCliffCommonProcDamage")

## 0x801458BC
static func ftCommonCliffEscapeSlow1SetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCliffEscapeSlow1, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.is_cliff_hold = TRUE

	fp.proc_damage = Callable(Ftcommoncliffcatchwait, &"ftCommonCliffCommonProcDamage")

## 0x8014590C
static func ftCommonCliffEscapeQuick2SetStatus(fighter_gobj) -> void:
	Ftcommoncliffclimb.ftCommonCliffCommon2UpdateCollData(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCliffEscapeQuick2, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftcommoncliffclimb.ftCommonCliffCommon2InitStatusVars(fighter_gobj)

## 0x8014594C
static func ftCommonCliffEscapeSlow2SetStatus(fighter_gobj) -> void:
	Ftcommoncliffclimb.ftCommonCliffCommon2UpdateCollData(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCliffEscapeSlow2, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftcommoncliffclimb.ftCommonCliffCommon2InitStatusVars(fighter_gobj)
