## 1:1 port of src/ft/ftchar/ftlink/ftlinkspeciallw.c (ssb-decomp-re).
## Link down special (Bomb); the bomb is an item (Itlinkbomb).
class_name Ftlinkspeciallw
extends Port

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x801643D0
static func ftLinkSpecialLwMakeBomb(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3
	var vel: Vector3

	if fp.motion_vars.flags.flag0 != 0:
		fp.motion_vars.flags.flag0 = 0

		pos = DObjGetStruct(fighter_gobj).translate

		vel.x = 0.0
		vel.y = 0.0
		vel.z = 0.0

		Itlinkbomb.itLinkBombMakeItem(fighter_gobj, pos, vel)

## 0x80164434
static func ftLinkSpecialLwProcUpdate(fighter_gobj) -> void:
	ftLinkSpecialLwMakeBomb(fighter_gobj)
	Ftanimend.ftAnimEndSetWait(fighter_gobj)

## 0x8016445C
static func ftLinkSpecialAirLwProcUpdate(fighter_gobj) -> void:
	ftLinkSpecialLwMakeBomb(fighter_gobj)
	Ftanimend.ftAnimEndSetFall(fighter_gobj)

## 0x80164484
static func ftLinkSpecialLwProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if Mpcommon.mpCommonCheckFighterOnFloor(fighter_gobj) == FALSE:
		Mpcommon.mpCommonSetFighterAir(fp)
		Ftmain.ftMainSetStatus(fighter_gobj, nFTLinkStatusSpecialAirLw, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_NONE)

## 0x801644D4
static func ftLinkSpecialAirLwProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if Mpcommon.mpCommonCheckFighterLanding(fighter_gobj) != FALSE:
		Mpcommon.mpCommonSetFighterGround(fp)
		Ftmain.ftMainSetStatus(fighter_gobj, nFTLinkStatusSpecialLw, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_NONE)

## 0x80164524
static func ftLinkSpecialLwCheckGotoItemThrow(fighter_gobj, is_ground: int) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if fp.item_gobj != null:
		var ip := itGetStruct(fp.item_gobj)

		if ip.kind == nITKindLinkBomb:
			if is_ground == TRUE:
				Ftcommonitemthrow.ftCommonItemThrowSetStatus(fighter_gobj, nFTCommonStatusLightThrowF4)

				return TRUE
			else:
				Ftcommonitemthrow.ftCommonItemThrowSetStatus(fighter_gobj, nFTCommonStatusLightThrowAirF4)
		return TRUE
	return FALSE

## 0x8016458C
static func ftLinkSpecialLwSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if ftLinkSpecialLwCheckGotoItemThrow(fighter_gobj, TRUE) != TRUE:
		fp.motion_vars.flags.flag0 = 0

		Ftmain.ftMainSetStatus(fighter_gobj, nFTLinkStatusSpecialLw, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
		Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x801645E8
static func ftLinkSpecialAirLwSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if ftLinkSpecialLwCheckGotoItemThrow(fighter_gobj, FALSE) != TRUE:
		fp.motion_vars.flags.flag0 = 0

		Ftmain.ftMainSetStatus(fighter_gobj, nFTLinkStatusSpecialAirLw, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
		Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
