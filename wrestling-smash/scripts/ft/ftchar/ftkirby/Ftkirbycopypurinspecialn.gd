## 1:1 port of src/ft/ftchar/ftkirby/ftkirbycopypurinspecialn.c (ssb-decomp-re): Kirby's copied
## Jigglypuff Pound.
class_name Ftkirbycopypurinspecialn
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

const FTKIRBY_COPYPURIN_SPECIALN_STATUS_FLAGS := (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80151860
static func ftKirbyCopyPurinSpecialNInitStatusVars(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag2 = 0
	fp.motion_vars.flags.flag1 = 0
	fp.motion_vars.flags.flag0 = 0

## 0x80151874
static func ftKirbyCopyPurinSpecialNGetAngle(stick_y = null) -> float:
	var temp_stick_y: int = ABS(stick_y)

	if temp_stick_y > 50:
		temp_stick_y = 50

	temp_stick_y -= 10

	if temp_stick_y < 0:
		temp_stick_y = 0

	if stick_y < 0:
		temp_stick_y = -temp_stick_y

	return F_CLC_DTOR32((temp_stick_y * 20) / 40.0)

## 0x801518EC
static func ftKirbyCopyPurinSpecialAirNProcPhysics(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var boost: float

	if fp.motion_vars.flags.flag1 != 0:
		fp.motion_vars.flags.flag1 = 0

		fp.passive_vars.kirby.copypurin_unk += 1

		boost = ftKirbyCopyPurinSpecialNGetAngle(fp.input.pl.stick_range.y)

		fp.physics.vel_air.y = __sinf(boost) * FTKIRBY_COPYPURIN_POUND_VEL_BASE
		fp.physics.vel_air.x = __cosf(boost) * fp.lr * FTKIRBY_COPYPURIN_POUND_VEL_BASE

	match fp.motion_vars.flags.flag2:
		0:
			Ftphysics.ftPhysicsApplyAirVelFriction(fighter_gobj)

		1:
			fp.physics.vel_air.y *= FTKIRBY_COPYPURIN_POUND_VEL_MUL
			fp.physics.vel_air.x *= FTKIRBY_COPYPURIN_POUND_VEL_MUL

		2:
			Ftphysics.ftPhysicsApplyAirVelDriftFastFall(fighter_gobj)

## 0x801519F0
static func ftKirbyCopyPurinSpecialNProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftkirbycopypurinspecialn, &"ftKirbyCopyPurinSpecialNSwitchStatusAir"))

## 0x80151A14
static func ftKirbyCopyPurinSpecialAirNProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbycopypurinspecialn, &"ftKirbyCopyPurinSpecialAirNSwitchStatusGround"))

## 0x80151A38
static func ftKirbyCopyPurinSpecialAirNSwitchStatusGround(fighter_gobj = null) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyPurinSpecialN, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM))

## 0x80151A78
static func ftKirbyCopyPurinSpecialNSwitchStatusAir(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyPurinSpecialAirN, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM))
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x80151AC4
static func ftKirbyCopyPurinSpecialNSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyPurinSpecialN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftKirbyCopyPurinSpecialNInitStatusVars(fighter_gobj)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80151B04
static func ftKirbyCopyPurinSpecialAirNSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyPurinSpecialAirN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftKirbyCopyPurinSpecialNInitStatusVars(fighter_gobj)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
