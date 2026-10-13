## 1:1 port of src/ft/ftchar/ftdonkey/ftdonkeythrowfwait.c (ssb-decomp-re).
## Donkey Kong Cargo Throw: wait (holding the victim).
class_name Ftdonkeythrowfwait
extends Port

# // // // // // // // // // // // //
#             MACROS
# // // // // // // // // // // // //

## #define ftDonkeyThrowFWaitCheckInterupt(fighter_gobj) - Donkey Kong's Cargo Wait (short-circuit ||)
static func _ftDonkeyThrowFWaitCheckInterupt(fighter_gobj) -> bool:
	return (
		(Ftcommonitemthrow.ftCommonHeavyThrowCheckInterruptCommon(fighter_gobj) != FALSE) or
		(Ftdonkeythrowff.ftDonkeyThrowFFCheckInterruptThrowFCommon(fighter_gobj) != FALSE) or
		(Ftdonkeythrowfkneebend.ftDonkeyThrowFKneeBendCheckInterruptThrowFCommon(fighter_gobj) != FALSE) or
		(Ftdonkeythrowffall.ftDonkeyThrowFFallCheckInterruptPass(fighter_gobj) != FALSE) or
		(Ftdonkeythrowfturn.ftDonkeyThrowFTurnCheckInterruptThrowFCommon(fighter_gobj) != FALSE)
	)

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8014D400
static func ftDonkeyThrowFWaitProcInterrupt(fighter_gobj) -> void:
	if not (_ftDonkeyThrowFWaitCheckInterupt(fighter_gobj)):
		Ftdonkeythrowfwalk.ftDonkeyThrowFWalkCheckInterruptThrowFWait(fighter_gobj)

## 0x8014D478
static func ftDonkeyThrowFCommonProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftdonkeythrowffall, &"ftDonkeyThrowFFallSetStatus"))

## 0x8014D49C
static func ftDonkeyThrowFWaitSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsAir:
		Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusThrowFWait, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

## 0x8014D4EC
static func ftDonkeyThrowFWaitCheckInterruptThrowFWalk(fighter_gobj) -> int:
	if Ftcommonwait.ftCommonWaitCheckInputSuccess(fighter_gobj) != FALSE:
		ftDonkeyThrowFWaitSetStatus(fighter_gobj)

		return TRUE
	else:
		return FALSE
