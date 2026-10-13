## 1:1 port of src/ft/ftcommon/ftcommonstopceil.c (ssb-decomp-re): StopCeil (head bonk) status.
class_name Ftcommonstopceil
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801441C0
static func ftCommonStopCeilSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusStopCeil, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	# fp->physics.vel_air.y = fp->physics.vel_air.z = 0.0F;
	fp.physics.vel_air.z = 0.0
	fp.physics.vel_air.y = fp.physics.vel_air.z
