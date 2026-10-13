## 1:1 port of src/ft/ftcommon/ftcommonrunbrake.c (ssb-decomp-re): RunBrake status.
class_name Ftcommonrunbrake
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8013EFB0
static func ftCommonRunBrakeProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (not Ftcommonkneebend.ftCommonKneeBendCheckInterruptRun(fighter_gobj)) and (fp.motion_vars.flags.flag1 != 0) and (fighter_gobj.anim_frame <= 4.0):
		Ftcommonturnrun.ftCommonTurnRunCheckInterruptRun(fighter_gobj)

## 0x8013F014
static func ftCommonRunBrakeProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	Ftphysics.ftPhysicsSetGroundVelFriction(fp, attr.traction * 1.25)
	Ftphysics.ftPhysicsSetGroundVelTransferAir(fighter_gobj)

## 0x8013F05C
static func ftCommonRunBrakeSetStatus(fighter_gobj, flag: int) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusRunBrake, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.motion_vars.flags.flag1 = flag

## 0x8013F0A0
static func ftCommonRunBrakeCheckInterruptRun(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.input.pl.stick_range.x * fp.lr) < FTCOMMON_RUN_STICK_RANGE_MIN:
		ftCommonRunBrakeSetStatus(fighter_gobj, 1)

		return TRUE
	else:
		return FALSE

## 0x8013F0EC
static func ftCommonRunBrakeCheckInterruptTurnRun(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if ABS(fp.input.pl.stick_range.x) < FTCOMMON_RUN_STICK_RANGE_MIN:
		ftCommonRunBrakeSetStatus(fighter_gobj, 0)

		# REGION_US: Momentum slide fix
		if fp.physics.vel_ground.x > fp.attr.run_speed:
			fp.physics.vel_ground.x = fp.attr.run_speed
		return TRUE
	else:
		return FALSE
