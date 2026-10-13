## 1:1 port of src/ft/ftchar/ftdonkey/ftdonkeythrowfwalk.c (ssb-decomp-re).
## Donkey Kong Cargo Throw: walk (slow / middle / fast).
class_name Ftdonkeythrowfwalk
extends Port

# // // // // // // // // // // // //
#             MACROS
# // // // // // // // // // // // //

## #define ftDonkeyThrowFWalkCheckInterrupt(fighter_gobj) (short-circuit ||)
static func _ftDonkeyThrowFWalkCheckInterrupt(fighter_gobj) -> bool:
	return (
		(Ftcommonitemthrow.ftCommonHeavyThrowCheckInterruptCommon(fighter_gobj) != FALSE) or
		(Ftdonkeythrowff.ftDonkeyThrowFFCheckInterruptThrowFCommon(fighter_gobj) != FALSE) or
		(Ftdonkeythrowfkneebend.ftDonkeyThrowFKneeBendCheckInterruptThrowFCommon(fighter_gobj) != FALSE) or
		(Ftdonkeythrowffall.ftDonkeyThrowFFallCheckInterruptPass(fighter_gobj) != FALSE) or
		(Ftdonkeythrowfwait.ftDonkeyThrowFWaitCheckInterruptThrowFWalk(fighter_gobj) != FALSE)
	)

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8014D530
static func ftDonkeyThrowFWalkGetWalkAnimLength(fp: Fighter, status_id: int) -> float:
	var walk_anim_length: float = 0.0 # uninitialized in C for other status IDs (never reached)

	match status_id:
		nFTDonkeyStatusThrowFWalkSlow:
			walk_anim_length = fp.attr.throw_walkslow_anim_length

		nFTDonkeyStatusThrowFWalkMiddle:
			walk_anim_length = fp.attr.throw_walkmiddle_anim_length

		nFTDonkeyStatusThrowFWalkFast:
			walk_anim_length = fp.attr.throw_walkfast_anim_length
	return walk_anim_length

## 0x8014D590
static func ftDonkeyThrowFWalkProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if not (_ftDonkeyThrowFWalkCheckInterrupt(fighter_gobj)):
		var status_id: int = Ftcommonwalk.ftCommonWalkGetWalkStatus(ABS(fp.input.pl.stick_range.x)) + (nFTDonkeyStatusThrowFWalkSlow - nFTCommonStatusWalkSlow)

		if status_id != fp.status_id:
			var div: float = ftDonkeyThrowFWalkGetWalkAnimLength(fp, fp.status_id)
			var mul: float = ftDonkeyThrowFWalkGetWalkAnimLength(fp, status_id)

			ftDonkeyThrowFWalkSetStatusParam(fighter_gobj, float(int(mul * (fighter_gobj.anim_frame / div)))) # (s32) cast, passed as f32

## 0x8014D68C
static func ftDonkeyThrowFWalkSetStatusParam(fighter_gobj, frame_begin: float) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, Ftcommonwalk.ftCommonWalkGetWalkStatus(fp.input.pl.stick_range.x) + (nFTDonkeyStatusThrowFWalkSlow - nFTCommonStatusWalkSlow), frame_begin, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x8014D6D8
static func ftDonkeyThrowFWalkSetStatusDefault(fighter_gobj) -> void:
	ftDonkeyThrowFWalkSetStatusParam(fighter_gobj, 0.0)

## 0x8014D6F8
static func ftDonkeyThrowFWalkCheckInterruptThrowFWait(fighter_gobj) -> int:
	if Ftcommonwalk.ftCommonWalkCheckInputSuccess(fighter_gobj) != FALSE:
		ftDonkeyThrowFWalkSetStatusDefault(fighter_gobj)

		return TRUE
	else:
		return FALSE
