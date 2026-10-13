## 1:1 port of src/ft/ftcommon/ftcommonhammerwalk.c (ssb-decomp-re): HammerWalk.
class_name Ftcommonhammerwalk
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801479A0
static func ftCommonHammerWalkProcInterrupt(fighter_gobj) -> void:
	if (not B(Ftcommonhammerkneebend.ftCommonHammerKneeBendCheckInterruptCommon(fighter_gobj))) and (not B(Ftcommonhammerfall.ftCommonHammerFallCheckInterruptCommon(fighter_gobj))):
		Fthammer.ftHammerCheckGotoHammerWait(fighter_gobj)

## 0x801479E0
static func ftCommonHammerWalkSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusHammerWalk, Fthammer.ftHammerGetAnimFrame(fighter_gobj), 1.0, Fthammer.ftHammerGetStatUpdateFlags(fighter_gobj))
	Fthammer.ftHammerSetColAnim(fighter_gobj)

## 0x80147A2C
static func ftCommonHammerWalkCheckInterruptCommon(fighter_gobj) -> int:
	if B(Ftcommonwalk.ftCommonWalkCheckInputSuccess(fighter_gobj)):
		ftCommonHammerWalkSetStatus(fighter_gobj)

		return TRUE
	else:
		return FALSE
