## 1:1 port of src/ft/ftchar/ftyoshi/ftyoshispecialn.c (ssb-decomp-re).
## Yoshi neutral special (Egg Lay).
class_name Ftyoshispecialn
extends Port

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8015E310
static func ftYoshiSpecialNSetCatchParams(fp: Fighter, proc_catch: Callable) -> void:
	Ftparam.ftParamSetCatchParams(fp, FTCATCHKIND_MASK_YOSHISPECIALN, proc_catch, Callable(Ftcommoncaptureyoshi, &"ftCommonCaptureYoshiProcCapture"))

## 0x8015E33C
static func ftYoshiSpecialNCatchUpdateProcStatus(fighter_gobj, proc_status: Callable) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if ((fp.motion_vars.flags.flag1 != 0) and (fp.catch_gobj != null)) or (fighter_gobj.anim_frame <= 0.0):
		fp.motion_vars.flags.flag1 = 0

		proc_status.call(fighter_gobj)

## 0x8015E390
static func ftYoshiSpecialNCatchProcUpdate(fighter_gobj) -> void:
	ftYoshiSpecialNCatchUpdateProcStatus(fighter_gobj, Callable(Ftyoshispecialn, &"ftYoshiSpecialNReleaseSetStatus"))

## 0x8015E3B4
static func ftYoshiSpecialAirNCatchProcUpdate(fighter_gobj) -> void:
	ftYoshiSpecialNCatchUpdateProcStatus(fighter_gobj, Callable(Ftyoshispecialn, &"ftYoshiSpecialAirNReleaseSetStatus"))

## 0x8015E3D8
static func ftYoshiSpecialNCatchUpdateCaptureVars(fp: Fighter) -> void:
	if fp.motion_vars.flags.flag2 != 0:
		if fp.catch_gobj != null:
			var catch_fp := ftGetStruct(fp.catch_gobj)

			catch_fp.status_vars.common.captureyoshi.stage = 1

			fp.motion_vars.flags.flag2 = 0
	if fp.motion_vars.flags.flag1 != 0:
		if fp.catch_gobj != null:
			var catch_fp := ftGetStruct(fp.catch_gobj)

			catch_fp.status_vars.common.captureyoshi.stage = 3

			fp.catch_gobj = null

			fp.motion_vars.flags.flag1 = 0

			Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_NONE)

## 0x8015E44C
static func ftYoshiSpecialNReleaseProcUpdate(fighter_gobj) -> void:
	ftYoshiSpecialNCatchUpdateCaptureVars(ftGetStruct(fighter_gobj))
	Ftanimend.ftAnimEndSetWait(fighter_gobj)

## 0x8015E478
static func ftYoshiSpecialAirNReleaseProcUpdate(fighter_gobj) -> void:
	ftYoshiSpecialNCatchUpdateCaptureVars(ftGetStruct(fighter_gobj))
	Ftanimend.ftAnimEndSetFall(fighter_gobj)

## 0x8015E4A4
static func ftYoshiSpecialNProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftyoshispecialn, &"ftYoshiSpecialNSwitchStatusAir"))

## 0x8015E4C8
static func ftYoshiSpecialAirNProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftyoshispecialn, &"ftYoshiSpecialAirNSwitchStatusGround"))

## 0x8015E4EC
static func ftYoshiSpecialNCatchProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftyoshispecialn, &"ftYoshiSpecialNCatchSwitchStatusAir"))

## 0x8015E510
static func ftYoshiSpecialAirNCatchProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftyoshispecialn, &"ftYoshiSpecialAirNCatchSwitchStatusGround"))

## 0x8015E534
static func ftYoshiSpecialNReleaseProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftyoshispecialn, &"ftYoshiSpecialNReleaseSwitchStatusAir"))

## 0x8015E558
static func ftYoshiSpecialAirNReleaseProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftyoshispecialn, &"ftYoshiSpecialAirNReleaseSwitchStatusGround"))

## 0x8015E57C
static func ftYoshiSpecialNProcStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag1 = 0

## 0x8015E588
static func ftYoshiSpecialAirNProcStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag2 = 0
	fp.motion_vars.flags.flag1 = 0

## 0x8015E598
static func ftYoshiSpecialAirNSwitchStatusGround(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialN, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_HIT))
	ftYoshiSpecialNSetCatchParams(fp, Callable(Ftyoshispecialn, &"ftYoshiSpecialNCatchProcCatch"))

## 0x8015E5EC
static func ftYoshiSpecialNSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialAirN, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_HIT))
	ftYoshiSpecialNSetCatchParams(fp, Callable(Ftyoshispecialn, &"ftYoshiSpecialAirNCatchProcCatch"))

## 0x8015E640
static func ftYoshiSpecialAirNCatchSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialNCatch, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))

## 0x8015E680
static func ftYoshiSpecialNCatchSwitchStatusAir(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterAir(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialAirNCatch, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))

## 0x8015E6C0
static func ftYoshiSpecialAirNReleaseSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialNRelease, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))

## 0x8015E700
static func ftYoshiSpecialNReleaseSwitchStatusAir(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterAir(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialAirNRelease, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))

## 0x8015E740
static func ftYoshiSpecialNSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_status = Callable(Ftyoshispecialn, &"ftYoshiSpecialNProcStatus")

	Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftYoshiSpecialNSetCatchParams(fp, Callable(Ftyoshispecialn, &"ftYoshiSpecialNCatchProcCatch"))
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x8015E79C
static func ftYoshiSpecialAirNSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_status = Callable(Ftyoshispecialn, &"ftYoshiSpecialAirNProcStatus")

	Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialAirN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftYoshiSpecialNSetCatchParams(fp, Callable(Ftyoshispecialn, &"ftYoshiSpecialAirNCatchProcCatch"))
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x8015E7F8
static func ftYoshiSpecialNCatchInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL) # Store grab vulnerability flags?
	Ftphysics.ftPhysicsStopVelAll(fighter_gobj)

	fp.catch_gobj = fp.search_gobj

## 0x8015E83C
static func ftYoshiSpecialNCatchProcCatch(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialNCatch, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftYoshiSpecialNCatchInitStatusVars(fighter_gobj)

## 0x8015E880
static func ftYoshiSpecialAirNCatchProcCatch(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialAirNCatch, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftYoshiSpecialNCatchInitStatusVars(fighter_gobj)

## 0x8015E8C4
static func ftYoshiSpecialNReleaseInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

	fp.motion_vars.flags.flag2 = 0
	fp.motion_vars.flags.flag1 = 0

## 0x8015E8F8
static func ftYoshiSpecialNReleaseSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialNRelease, 0.0, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftYoshiSpecialNReleaseInitStatusVars(fighter_gobj)

## 0x8015E93C
static func ftYoshiSpecialAirNReleaseSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialAirNRelease, 0.0, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftYoshiSpecialNReleaseInitStatusVars(fighter_gobj)
