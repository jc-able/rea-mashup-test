## Port of src/ft/ftchar/ftpurin/ftpurinspecialhi.c (Jigglypuff up special: Sing).
class_name Ftpurinspecialhi
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

const FTPURIN_SPECIALHI_STATUS_FLAGS = (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM | FTSTATUS_PRESERVE_HIT)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80151550
static func ftPurinSpecialHiProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 == 1:
		if Efmanager.efManagerPurinSingMakeEffect(fighter_gobj) != null:
			fp.is_effect_attach = TRUE

		fp.motion_vars.flags.flag1 = 0

	if fp.status_id == nFTPurinStatusSpecialHi:
		Ftanimend.ftAnimEndSetWait(fighter_gobj)
	else:
		Ftanimend.ftAnimEndSetFall(fighter_gobj)

## 0x801515CC
static func ftPurinSpecialHiProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftpurinspecialhi, &"ftPurinSpecialHiSwitchStatusAir"))

## 0x801515F0
static func ftPurinSpecialAirHiProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftpurinspecialhi, &"ftPurinSpecialAirHiSwitchStatusGround"))

## 0x80151614
static func ftPurinSpecialAirHiSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPurinStatusSpecialHi, fighter_gobj.anim_frame, 1.0, FTPURIN_SPECIALHI_STATUS_FLAGS)

## 0x80151654
static func ftPurinSpecialHiSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPurinStatusSpecialAirHi, fighter_gobj.anim_frame, 1.0, FTPURIN_SPECIALHI_STATUS_FLAGS)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x801516A0
static func ftPurinSpecialHiSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPurinStatusSpecialHi, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x801516D8
static func ftPurinSpecialAirHiSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPurinStatusSpecialAirHi, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
