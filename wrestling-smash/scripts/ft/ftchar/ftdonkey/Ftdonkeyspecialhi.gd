## 1:1 port of src/ft/ftchar/ftdonkey/ftdonkeyspecialhi.c (ssb-decomp-re).
## Donkey Kong up special (Spinning Kong).
class_name Ftdonkeyspecialhi
extends Port

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8015B6D0
static func ftDonkeySpecialHiProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndSetWait(fighter_gobj)

## 0x8015B6F0
static func ftDonkeySpecialAirHiProcUpdate(fighter_gobj) -> void:
	if fighter_gobj.anim_frame <= 0.0:
		Ftcommonfallspecial.ftCommonFallSpecialSetStatus(fighter_gobj, FTDONKEY_SPINNINGKONG_FALLSPECIAL_DRIFT, FALSE, TRUE, FALSE, FTDONKEY_SPINNINGKONG_LANDING_LAG, TRUE)

## 0x8015B744
static func ftDonkeySpecialHiProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftphysics.ftPhysicsApplyClampGroundVelStickRange(fp, 0, FTDONKEY_SPINNINGKONG_GROUND_ACCEL, FTDONKEY_SPINNINGKONG_GROUND_VEL_MAX)
	Ftphysics.ftPhysicsSetGroundVelTransferAir(fighter_gobj)

## 0x8015B780
static func ftDonkeySpecialAirHiProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	var attr = fp.attr

	var gravity_mul: float = FTDONKEY_SPINNINGKONG_END_GRAVITY_MUL if (fp.motion_vars.flags.flag1 != 0) else FTDONKEY_SPINNINGKONG_START_GRAVITY_MUL

	Ftphysics.ftPhysicsApplyGravityClampTVel(fp, attr.gravity * gravity_mul, attr.tvel_base)

	Ftphysics.ftPhysicsClampAirVelXStickRange(fp, 0, FTDONKEY_SPINNINGKONG_AIR_ACCEL, FTDONKEY_SPINNINGKONG_AIR_VEL_MAX)

## 0x8015B800
static func ftDonkeySpecialHiProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftdonkeyspecialhi, &"ftDonkeySpecialHiSwitchStatusAir"))

## 0x8015B824
static func ftDonkeySpecialAirHiProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterCliff(fighter_gobj, Callable(Ftdonkeyspecialhi, &"ftDonkeySpecialAirHiSwitchStatusGround"))

## 0x8015B848
static func ftDonkeySpecialAirHiSwitchStatusGround(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusSpecialHi, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_RUMBLE)
	Ftphysics.ftPhysicsClampGroundVel(fp, FTDONKEY_SPINNINGKONG_GROUND_VEL_MAX)

## 0x8015B898
static func ftDonkeySpecialHiSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusSpecialAirHi, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_RUMBLE)
	Ftphysics.ftPhysicsClampAirVelX(fp, FTDONKEY_SPINNINGKONG_AIR_VEL_MAX)

## 0x8015B8E8
static func ftDonkeySpecialHiSetStatusFlagGA(fighter_gobj, ga: int) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusSpecialAirHi, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	Ftphysics.ftPhysicsClampAirVelX(fp, FTDONKEY_SPINNINGKONG_AIR_VEL_MAX)

	fp.jumps_used = attr.jumps_max

	fp.motion_vars.flags.flag1 = 0

	fp.status_vars.donkey.specialhi.unk_0x0 = 9

	if ga == nMPKineticsGround:
		fp.stat_flags.ga = nMPKineticsGround

## 0x8015B974
static func ftDonkeySpecialHiSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)

	fp.physics.vel_air.y = 0.0

	ftDonkeySpecialHiSetStatusFlagGA(fighter_gobj, nMPKineticsGround)

## 0x8015B9B8
static func ftDonkeySpecialAirHiSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.physics.vel_air.y = FTDONKEY_SPINNINGKONG_AIR_VEL_Y

	ftDonkeySpecialHiSetStatusFlagGA(fighter_gobj, nMPKineticsAir)
