## 1:1 port of src/ft/ftchar/ftdonkey/ftdonkeythrowfturn.c (ssb-decomp-re).
## Donkey Kong Cargo Throw: turn around.
class_name Ftdonkeythrowfturn
extends Port

# // // // // // // // // // // // //
#             MACROS
# // // // // // // // // // // // //

## #define ftDonkeyThrowFTurnCheckInterrupt(fighter_gobj) (short-circuit ||)
static func _ftDonkeyThrowFTurnCheckInterrupt(fighter_gobj) -> bool:
	return (
		(Ftcommonitemthrow.ftCommonHeavyThrowCheckInterruptCommon(fighter_gobj) != FALSE) or
		(Ftdonkeythrowff.ftDonkeyThrowFFCheckInterruptThrowFCommon(fighter_gobj) != FALSE)
	)

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8014D740
static func ftDonkeyThrowFTurnProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 != 0:
		fp.motion_vars.flags.flag1 = 0

		fp.lr = -fp.lr

		fp.physics.vel_ground.x = -fp.physics.vel_ground.x
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftdonkeythrowfwait, &"ftDonkeyThrowFWaitSetStatus"))

## 0x8014D790
static func ftDonkeyThrowFTurnProcInterrupt(fighter_gobj) -> void:
	if not (_ftDonkeyThrowFTurnCheckInterrupt(fighter_gobj)):
		Ftdonkeythrowfkneebend.ftDonkeyThrowFKneeBendCheckInterruptThrowFCommon(fighter_gobj)

## 0x8014D7D0
static func ftDonkeyThrowFTurnSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag1 = 0

	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusThrowFTurn, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x8014D810
static func ftDonkeyThrowFTurnCheckInterruptThrowFCommon(fighter_gobj) -> int:
	if Ftcommonturn.ftCommonTurnCheckInputSuccess(fighter_gobj) != FALSE:
		ftDonkeyThrowFTurnSetStatus(fighter_gobj)

		return TRUE
	else:
		return FALSE
