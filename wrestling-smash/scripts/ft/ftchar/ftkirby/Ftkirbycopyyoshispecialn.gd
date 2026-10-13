## 1:1 port of src/ft/ftchar/ftkirby/ftkirbycopyyoshispecialn.c (ssb-decomp-re): Kirby's copied
## Yoshi Egg Lay.
class_name Ftkirbycopyyoshispecialn
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8015F180
static func ftKirbyCopyYoshiSpecialNSetCatchParams(fp = null, proc_catch = null) -> void: # Kirby's Yoshi Copy
	Ftparam.ftParamSetCatchParams(fp, FTCATCHKIND_MASK_YOSHISPECIALN, proc_catch, Callable(Ftcommoncaptureyoshi, &"ftCommonCaptureYoshiProcCapture"))

## 0x8015F1AC
static func ftKirbyCopyYoshiSpecialNCatchUpdateProcStatus(fighter_gobj = null, proc_status = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if ((fp.motion_vars.flags.flag1 != 0) and (fp.catch_gobj != null)) or (fighter_gobj.anim_frame <= 0.0):
		fp.motion_vars.flags.flag1 = 0

		proc_status.call(fighter_gobj)

## 0x8015F200
static func ftKirbyCopyYoshiSpecialNCatchProcUpdate(fighter_gobj = null) -> void:
	ftKirbyCopyYoshiSpecialNCatchUpdateProcStatus(fighter_gobj, Callable(Ftkirbycopyyoshispecialn, &"ftKirbyCopyYoshiSpecialNReleaseSetStatus"))

## 0x8015F224
static func ftKirbyCopyYoshiSpecialAirNCatchProcUpdate(fighter_gobj = null) -> void:
	ftKirbyCopyYoshiSpecialNCatchUpdateProcStatus(fighter_gobj, Callable(Ftkirbycopyyoshispecialn, &"ftKirbyCopyYoshiSpecialAirNReleaseSetStatus"))

## 0x8015F248
static func ftKirbyCopyYoshiSpecialAirNCatchUpdateCaptureVars(fp = null) -> void:
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

## 0x8015F2BC
static func ftKirbyCopyYoshiSpecialNReleaseProcUpdate(fighter_gobj = null) -> void:
	ftKirbyCopyYoshiSpecialAirNCatchUpdateCaptureVars(ftGetStruct(fighter_gobj))
	Ftanimend.ftAnimEndSetWait(fighter_gobj)

## 0x8015F2E8
static func ftKirbyCopyYoshiSpecialAirNReleaseProcUpdate(fighter_gobj = null) -> void:
	ftKirbyCopyYoshiSpecialAirNCatchUpdateCaptureVars(ftGetStruct(fighter_gobj))
	Ftanimend.ftAnimEndSetFall(fighter_gobj)

## 0x8015F314
static func ftKirbyCopyYoshiSpecialNProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftkirbycopyyoshispecialn, &"ftKirbyCopyYoshiSpecialNSwitchStatusAir"))

## 0x8015F338
static func ftKirbyCopyYoshiSpecialAirNProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbycopyyoshispecialn, &"ftKirbyCopyYoshiSpecialAirNSwitchStatusGround"))

## 0x8015F35C
static func ftKirbyCopyYoshiSpecialNCatchProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftkirbycopyyoshispecialn, &"ftKirbyCopyYoshiSpecialNCatchSwitchStatusAir"))

## 0x8015F380
static func ftKirbyCopyYoshiSpecialAirNCatchProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbycopyyoshispecialn, &"ftKirbyCopyYoshiSpecialAirNCatchSwitchStatusGround"))

## 0x8015F3A4
static func ftKirbyCopyYoshiSpecialNReleaseProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftkirbycopyyoshispecialn, &"ftKirbyCopyYoshiSpecialNReleaseSwitchStatusAir"))

## 0x8015F3C8
static func ftKirbyCopyYoshiSpecialAirNReleaseProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbycopyyoshispecialn, &"ftKirbyCopyYoshiSpecialAirNReleaseSwitchStatusGround"))

## 0x8015F3EC
static func ftKirbyCopyYoshiSpecialNProcStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag1 = 0

## 0x8015F3F8
static func ftKirbyCopyYoshiSpecialAirNProcStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag2 = 0
	fp.motion_vars.flags.flag1 = 0

## 0x8015F408
static func ftKirbyCopyYoshiSpecialAirNSwitchStatusGround(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyYoshiSpecialN, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_HIT))
	ftKirbyCopyYoshiSpecialNSetCatchParams(fp, Callable(Ftkirbycopyyoshispecialn, &"ftKirbyCopyYoshiSpecialNCatchProcCatch"))

## 0x8015F45C
static func ftKirbyCopyYoshiSpecialNSwitchStatusAir(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyYoshiSpecialAirN, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_HIT))
	ftKirbyCopyYoshiSpecialNSetCatchParams(fp, Callable(Ftkirbycopyyoshispecialn, &"ftKirbyCopyYoshiSpecialAirNCatchProcCatch"))

## 0x8015F4B0
static func ftKirbyCopyYoshiSpecialAirNCatchSwitchStatusGround(fighter_gobj = null) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyYoshiSpecialNCatch, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))

## 0x8015F4F0
static func ftKirbyCopyYoshiSpecialNCatchSwitchStatusAir(fighter_gobj = null) -> void:
	Mpcommon.mpCommonSetFighterAir(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyYoshiSpecialAirNCatch, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))

## 0x8015F530
static func ftKirbyCopyYoshiSpecialAirNReleaseSwitchStatusGround(fighter_gobj = null) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyYoshiSpecialNRelease, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))

## 0x8015F570
static func ftKirbyCopyYoshiSpecialNReleaseSwitchStatusAir(fighter_gobj = null) -> void:
	Mpcommon.mpCommonSetFighterAir(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyYoshiSpecialAirNRelease, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))

## 0x8015F5B0
static func ftKirbyCopyYoshiSpecialNSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_status = Callable(Ftkirbycopyyoshispecialn, &"ftKirbyCopyYoshiSpecialNProcStatus")

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyYoshiSpecialN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftKirbyCopyYoshiSpecialNSetCatchParams(fp, Callable(Ftkirbycopyyoshispecialn, &"ftKirbyCopyYoshiSpecialNCatchProcCatch"))
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x8015F60C
static func ftKirbyCopyYoshiSpecialAirNSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_status = Callable(Ftkirbycopyyoshispecialn, &"ftKirbyCopyYoshiSpecialAirNProcStatus")

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyYoshiSpecialAirN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftKirbyCopyYoshiSpecialNSetCatchParams(fp, Callable(Ftkirbycopyyoshispecialn, &"ftKirbyCopyYoshiSpecialAirNCatchProcCatch"))
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x8015F668
static func ftKirbyCopyYoshiSpecialNCatchInitStatusVars(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)
	Ftphysics.ftPhysicsStopVelAll(fighter_gobj)

	fp.catch_gobj = fp.search_gobj

## 0x8015F6AC
static func ftKirbyCopyYoshiSpecialNCatchProcCatch(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyYoshiSpecialNCatch, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftKirbyCopyYoshiSpecialNCatchInitStatusVars(fighter_gobj)

## 0x8015F6F0
static func ftKirbyCopyYoshiSpecialAirNCatchProcCatch(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyYoshiSpecialAirNCatch, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftKirbyCopyYoshiSpecialNCatchInitStatusVars(fighter_gobj)

## 0x8015F734
static func ftKirbyCopyYoshiSpecialNReleaseInitStatusVars(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

	fp.motion_vars.flags.flag2 = 0
	fp.motion_vars.flags.flag1 = 0

## 0x8015F768
static func ftKirbyCopyYoshiSpecialNReleaseSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyYoshiSpecialNRelease, 0.0, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftKirbyCopyYoshiSpecialNReleaseInitStatusVars(fighter_gobj)

## 0x8015F7AC
static func ftKirbyCopyYoshiSpecialAirNReleaseSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyYoshiSpecialAirNRelease, 0.0, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftKirbyCopyYoshiSpecialNReleaseInitStatusVars(fighter_gobj)
