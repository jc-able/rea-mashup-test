## Port of src/ft/ftchar/ftpurin/ftpurinspecialn.c (Jigglypuff neutral special: Pound).
class_name Ftpurinspecialn
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

const FTPURIN_SPECIALN_STATUS_FLAGS = (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80151260
static func ftPurinSpecialNInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag2 = 0
	fp.motion_vars.flags.flag1 = 0
	fp.motion_vars.flags.flag0 = 0

## 0x80151274
static func ftPurinSpecialNGetAngle(stick_y: int) -> float:
	var temp_stick_y: int = ABS(stick_y)

	if temp_stick_y > 50:
		temp_stick_y = 50

	temp_stick_y -= 10

	if temp_stick_y < 0:
		temp_stick_y = 0

	if stick_y < 0:
		temp_stick_y = -temp_stick_y

	return F_CLC_DTOR32((temp_stick_y * 20) / 40.0)

## 0x801512EC
static func ftPurinSpecialAirNProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var angle: float

	if fp.motion_vars.flags.flag1 != 0:
		fp.motion_vars.flags.flag1 = 0

		fp.passive_vars.purin.unk_0x0 = (fp.passive_vars.purin.unk_0x0 + 1) & 0xFFFFFFFF # u32

		angle = ftPurinSpecialNGetAngle(fp.input.pl.stick_range.y)

		fp.physics.vel_air.y = __sinf(angle) * FTPURIN_POUND_VEL_BASE
		fp.physics.vel_air.x = __cosf(angle) * fp.lr * FTPURIN_POUND_VEL_BASE

	match fp.motion_vars.flags.flag2:
		0:
			Ftphysics.ftPhysicsApplyAirVelFriction(fighter_gobj)

		1:
			fp.physics.vel_air.y *= FTPURIN_POUND_VEL_MUL
			fp.physics.vel_air.x *= FTPURIN_POUND_VEL_MUL

		2:
			Ftphysics.ftPhysicsApplyAirVelDriftFastFall(fighter_gobj)

## 0x801513F0
static func ftPurinSpecialNProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftpurinspecialn, &"ftPurinSpecialNSwitchStatusAir"))

## 0x80151414
static func ftPurinSpecialAirNProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftpurinspecialn, &"ftPurinSpecialAirNSwitchStatusGround"))

## 0x80151438
static func ftPurinSpecialAirNSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPurinStatusSpecialN, fighter_gobj.anim_frame, 1.0, FTPURIN_SPECIALN_STATUS_FLAGS)

## 0x80151478
static func ftPurinSpecialNSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPurinStatusSpecialAirN, fighter_gobj.anim_frame, 1.0, FTPURIN_SPECIALN_STATUS_FLAGS)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x801514C4
static func ftPurinSpecialNSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPurinStatusSpecialN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftPurinSpecialNInitStatusVars(fighter_gobj)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80151504
static func ftPurinSpecialAirNSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTPurinStatusSpecialAirN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftPurinSpecialNInitStatusVars(fighter_gobj)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
