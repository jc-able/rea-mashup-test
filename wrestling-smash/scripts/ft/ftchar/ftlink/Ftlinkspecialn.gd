## 1:1 port of src/ft/ftchar/ftlink/ftlinkspecialn.c (ssb-decomp-re).
## Link neutral special (Boomerang).
class_name Ftlinkspecialn
extends Port

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x801636D0
static func ftLinkSpecialNDestroyBoomerang(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.passive_vars.link.boomerang_gobj != null:
		Wpmain.wpMainDestroyWeapon(fp.passive_vars.link.boomerang_gobj)

		fp.passive_vars.link.boomerang_gobj = null

## 0x80163708
static func ftLinkSpecialNMakeBoomerang(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3

	if fp.motion_vars.flags.flag0 != 0:
		fp.motion_vars.flags.flag0 = 0

		pos.x = 0.0
		pos.y = 0.0
		pos.z = 0.0

		pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[FTLINK_BOOMERANG_SPAWN_JOINT], pos)

		fp.passive_vars.link.boomerang_gobj = Wplinkboomerang.wpLinkBoomerangMakeWeapon(fighter_gobj, pos)

## 0x80163770
static func ftLinkSpecialNProcUpdate(fighter_gobj) -> void:
	ftLinkSpecialNMakeBoomerang(fighter_gobj)
	Ftanimend.ftAnimEndSetWait(fighter_gobj)

## 0x80163798
static func ftLinkSpecialAirNProcUpdate(fighter_gobj) -> void:
	ftLinkSpecialNMakeBoomerang(fighter_gobj)
	Ftanimend.ftAnimEndSetFall(fighter_gobj)

## 0x801637C0
static func ftLinkSpecialNProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftlinkspecialn, &"ftLinkSpecialNSwitchStatusAir"))

## 0x801637E4
static func ftLinkSpecialNEmptyProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftlinkspecialn, &"ftLinkSpecialNEmptySwitchStatusAir"))

## 0x80163808
static func ftLinkSpecialAirNProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftlinkspecialn, &"ftLinkSpecialAirNSwitchStatusGround"))

## 0x8016382C
static func ftLinkSpecialAirNEmptyProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftlinkspecialn, &"ftLinkSpecialAirNEmptySwitchStatusGround"))

## 0x80163850 - Check for Smash-B input and reset flag0
static func ftLinkSpecialNProcStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag0 = 0

	if (ABS(fp.input.pl.stick_range.x) >= FTLINK_BOOMERANG_SMASH_STICK_MIN) and (fp.hold_stick_x < FTLINK_BOOMERANG_SMASH_BUFFER):
		fp.status_vars.link.specialn.is_smash = TRUE
		fp.stat_flags.is_smash_attack = TRUE # REGION_US
	else:
		fp.status_vars.link.specialn.is_smash = FALSE

## 0x801638AC
static func ftLinkSpecialNSwitchStatusAir(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterAir(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTLinkStatusSpecialAirN, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_MODELPART)

## 0x801638EC
static func ftLinkSpecialAirNSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTLinkStatusSpecialN, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_MODELPART)

## 0x8016392C
static func ftLinkSpecialNEmptySwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTLinkStatusSpecialAirNEmpty, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_NONE)
	fp.is_special_interrupt = TRUE

## 0x8016397C
static func ftLinkSpecialAirNEmptySwitchStatusGround(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTLinkStatusSpecialNEmpty, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_NONE)
	fp.is_special_interrupt = TRUE

## 0x801639CC
static func ftLinkSpecialNSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_status = Callable(Ftlinkspecialn, &"ftLinkSpecialNProcStatus")

	if fp.passive_vars.link.boomerang_gobj != null:
		Ftmain.ftMainSetStatus(fighter_gobj, nFTLinkStatusSpecialNEmpty, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

		fp.is_special_interrupt = TRUE
	else:
		Ftmain.ftMainSetStatus(fighter_gobj, nFTLinkStatusSpecialN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80163A4C
static func ftLinkSpecialAirNSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_status = Callable(Ftlinkspecialn, &"ftLinkSpecialNProcStatus")

	if fp.passive_vars.link.boomerang_gobj != null:
		Ftmain.ftMainSetStatus(fighter_gobj, nFTLinkStatusSpecialAirNEmpty, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

		fp.is_special_interrupt = TRUE
	else:
		Ftmain.ftMainSetStatus(fighter_gobj, nFTLinkStatusSpecialAirN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80163ACC
static func ftLinkSpecialNGetSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsAir:
		Ftmain.ftMainSetStatus(fighter_gobj, nFTLinkStatusSpecialAirNReturn, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	else:
		Ftmain.ftMainSetStatus(fighter_gobj, nFTLinkStatusSpecialNGet, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
