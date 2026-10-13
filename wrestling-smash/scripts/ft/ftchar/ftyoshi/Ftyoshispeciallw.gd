## 1:1 port of src/ft/ftchar/ftyoshi/ftyoshispeciallw.c (ssb-decomp-re).
## Yoshi down special (Yoshi Bomb); landing spawns two stars (Wpyoshistar).
class_name Ftyoshispeciallw
extends Port

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8015EDC0
static func ftYoshiSpecialLwStartProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftyoshispeciallw, &"ftYoshiSpecialAirLwLoopSetStatus"))

## 0x8015EDE4
static func ftYoshiSpecialLwLandingProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3

	if fp.motion_vars.flags.flag0 != 0:
		fp.motion_vars.flags.flag0 = 0

		pos.x = 0.0
		pos.y = 0.0
		pos.z = 0.0

		pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[FTYOSHI_YOSHIBOMB_STAR_SPAWN_JOINT], pos)
		Wpyoshistar.wpYoshiStarMakeStars(fighter_gobj, pos)
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommonwait, &"ftCommonWaitSetStatus"))

## 0x8015EE4C
static func ftYoshiSpecialAirLwLoopProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if Ftphysics.ftPhysicsCheckClampAirVelXDecMax(fp, fp.attr) == FALSE:
		Ftphysics.ftPhysicsApplyAirVelXFriction(fp, fp.attr)

## 0x8015EE84
static func ftYoshiSpecialLwStartProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.motion_vars.flags.flag1 != 0) and (fp.physics.vel_air.y <= 0.0):
		if Mpcommon.mpCommonCheckFighterCeilHeavyCliff(fighter_gobj) != FALSE:
			if fp.coll_data.mask_stat & MAP_FLAG_FLOOR:
				Mpcommon.mpCommonSetFighterGround(fp)
				Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialLwLanding, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
			elif fp.coll_data.mask_stat & MAP_FLAG_CLIFF_MASK:
				Ftcommoncliffcatchwait.ftCommonCliffCatchSetStatus(fighter_gobj)
	elif (Mpcommon.mpCommonCheckFighterCeilHeavy(fighter_gobj) != FALSE) and (fp.coll_data.mask_curr & MAP_FLAG_CEILHEAVY):
		ftYoshiSpecialAirLwLoopSetStatus(fighter_gobj)

## 0x8015EF5C
static func ftYoshiSpecialAirLwLoopProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if Mpcommon.mpCommonCheckFighterCeilHeavyCliff(fighter_gobj) != FALSE:
		if fp.coll_data.mask_stat & MAP_FLAG_FLOOR:
			Mpcommon.mpCommonSetFighterGround(fp)
			Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialLwLanding, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
		elif fp.coll_data.mask_stat & MAP_FLAG_CLIFF_MASK:
			Ftcommoncliffcatchwait.ftCommonCliffCatchSetStatus(fighter_gobj)

## 0x8015EFD4
static func ftYoshiSpecialLwStartProcStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag0 = 0
	fp.motion_vars.flags.flag1 = 0

## 0x8015EFE4
static func ftYoshiSpecialLwStartSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_status = Callable(Ftyoshispeciallw, &"ftYoshiSpecialLwStartProcStatus")

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialLwStart, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.jumps_used = fp.attr.jumps_max

## 0x8015F04C
static func ftYoshiSpecialAirLwStartSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_status = Callable(Ftyoshispeciallw, &"ftYoshiSpecialLwStartProcStatus")

	Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialAirLwStart, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.jumps_used = fp.attr.jumps_max

## 0x8015F0A8
static func ftYoshiSpecialAirLwLoopSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var vel_y_bak: float

	if ABSF(fp.physics.vel_air.x) > FTYOSHI_YOSHIBOMB_VEL_X_CLAMP:
		fp.physics.vel_air.x = (-1 if (fp.physics.vel_air.x < 0.0) else +1) * FTYOSHI_YOSHIBOMB_VEL_X_CLAMP

	vel_y_bak = fp.physics.vel_air.y

	Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialAirLwLoop, fighter_gobj.anim_frame, 0.0, FTSTATUS_PRESERVE_HIT)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.physics.vel_air.y = vel_y_bak

	if vel_y_bak > FTYOSHI_YOSHIBOMB_VEL_Y_CLAMP:
		fp.physics.vel_air.y = FTYOSHI_YOSHIBOMB_VEL_Y_CLAMP
