## Port of src/ft/ftchar/ftpurin/ftpurinspeciallw.c (Jigglypuff down special: Rest).
class_name Ftpurinspeciallw
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

const FTPURIN_SPECIALLW_STATUS_FLAGS = (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80151710
static func ftPurinSpecialLwProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftpurinspeciallw, &"ftPurinSpecialLwSwitchStatusAir"))

## 0x80151734
static func ftPurinSpecialAirLwProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftpurinspeciallw, &"ftPurinSpecialAirLwSwitchStatusGround"))

## 0x80151758
static func ftPurinSpecialAirLwSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPurinStatusSpecialLw, fighter_gobj.anim_frame, 1.0, FTPURIN_SPECIALLW_STATUS_FLAGS)

## 0x80151798
static func ftPurinSpecialLwSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPurinStatusSpecialAirLw, fighter_gobj.anim_frame, 1.0, FTPURIN_SPECIALLW_STATUS_FLAGS)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x801517E4
static func ftPurinSpecialLwSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPurinStatusSpecialLw, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x8015181C
static func ftPurinSpecialAirLwSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPurinStatusSpecialAirLw, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
