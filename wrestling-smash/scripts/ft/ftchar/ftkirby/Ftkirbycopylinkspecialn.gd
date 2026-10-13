## 1:1 port of src/ft/ftchar/ftkirby/ftkirbycopylinkspecialn.c (ssb-decomp-re): Kirby's copied
## Link Boomerang.
class_name Ftkirbycopylinkspecialn
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80164650
static func ftKirbyCopyLinkSpecialNDestroyBoomerang(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.passive_vars.kirby.copylink_boomerang_gobj != null:
		Wpmain.wpMainDestroyWeapon(fp.passive_vars.kirby.copylink_boomerang_gobj)

		fp.passive_vars.kirby.copylink_boomerang_gobj = null

## 0x80164688
static func ftKirbyCopyLinkSpecialNMakeBoomerang(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos

	if fp.motion_vars.flags.flag0 != 0:
		fp.motion_vars.flags.flag0 = 0

		pos = Vector3(0.0, 0.0, 0.0)

		pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[FTKIRBY_COPYLINK_BOOMERANG_SPAWN_JOINT], pos)

		fp.passive_vars.kirby.copylink_boomerang_gobj = Wplinkboomerang.wpLinkBoomerangMakeWeapon(fighter_gobj, pos)

## 0x801646F0
static func ftKirbyCopyLinkSpecialNProcUpdate(fighter_gobj = null) -> void:
	ftKirbyCopyLinkSpecialNMakeBoomerang(fighter_gobj)
	Ftanimend.ftAnimEndSetWait(fighter_gobj)

## 0x80164718
static func ftKirbyCopyLinkSpecialAirNProcUpdate(fighter_gobj = null) -> void:
	ftKirbyCopyLinkSpecialNMakeBoomerang(fighter_gobj)
	Ftanimend.ftAnimEndSetFall(fighter_gobj)

## 0x80164740
static func ftKirbyCopyLinkSpecialNProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftkirbycopylinkspecialn, &"ftKirbyCopyLinkSpecialNSwitchStatusAir"))

## 0x80164764
static func ftKirbyCopyLinkSpecialNEmptyProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftkirbycopylinkspecialn, &"ftKirbyCopyLinkSpecialNEmptySwitchStatusAir"))

## 0x80164788
static func ftKirbyCopyLinkSpecialAirNProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbycopylinkspecialn, &"ftKirbyCopyLinkSpecialAirNSwitchStatusGround"))

## 0x801647AC
static func ftKirbyCopyLinkSpecialAirNEmptyProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbycopylinkspecialn, &"ftKirbyCopyLinkSpecialAirNEmptySwitchStatusGround"))

## 0x801647D0
static func ftKirbyCopyLinkSpecialNProcStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag0 = 0

	if (ABS(fp.input.pl.stick_range.x) >= FTKIRBY_COPYLINK_BOOMERANG_SMASH_STICK_MIN) and (fp.hold_stick_x < FTKIRBY_COPYLINK_BOOMERANG_SMASH_BUFFER):
		fp.status_vars.kirby.copylink_specialn.is_smash = TRUE
	else:
		fp.status_vars.kirby.copylink_specialn.is_smash = FALSE

## 0x80164820
static func ftKirbyCopyLinkSpecialNSwitchStatusAir(fighter_gobj = null) -> void:
	Mpcommon.mpCommonSetFighterAir(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyLinkSpecialAirN, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_MODELPART)

## 0x80164860
static func ftKirbyCopyLinkSpecialAirNSwitchStatusGround(fighter_gobj = null) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyLinkSpecialN, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_MODELPART)

## 0x801648A0
static func ftKirbyCopyLinkSpecialNEmptySwitchStatusAir(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyLinkSpecialAirNEmpty, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.is_special_interrupt = TRUE

## 0x801648F0
static func ftKirbyCopyLinkSpecialAirNEmptySwitchStatusGround(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyLinkSpecialNEmpty, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.is_special_interrupt = TRUE

## 0x80164940
static func ftKirbyCopyLinkSpecialNSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_status = Callable(Ftkirbycopylinkspecialn, &"ftKirbyCopyLinkSpecialNProcStatus")

	if fp.passive_vars.kirby.copylink_boomerang_gobj != null:
		Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyLinkSpecialNEmpty, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

		fp.is_special_interrupt = TRUE

	else:
		Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyLinkSpecialN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x801649C0
static func ftKirbyCopyLinkSpecialAirNSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_status = Callable(Ftkirbycopylinkspecialn, &"ftKirbyCopyLinkSpecialNProcStatus")

	if fp.passive_vars.kirby.copylink_boomerang_gobj != null:
		Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyLinkSpecialAirNEmpty, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

		fp.is_special_interrupt = TRUE

	else:
		Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyLinkSpecialAirN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80164A40
static func ftKirbyCopyLinkSpecialNGetSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsAir:
		Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyLinkSpecialAirNReturn, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	else:
		Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyLinkSpecialNGet, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
