## 1:1 port of src/ft/ftchar/ftyoshi/ftyoshispecialhi.c (ssb-decomp-re).
## Yoshi up special (Egg Throw); the egg is a weapon (Wpyoshieggthrow) held until thrown.
class_name Ftyoshispecialhi
extends Port

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8015E980
static func ftYoshiSpecialHiProcDamage(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.yoshi.specialhi.egg_gobj != null:
		Wpmain.wpMainDestroyWeapon(fp.status_vars.yoshi.specialhi.egg_gobj)

## 0x8015E9B0
## C: void ftYoshiSpecialHiGetEggPosition(FTStruct *fp, Vec3f *pos) - `pos` is a pure output
## (fully written before use), so per the out-parameter convention it is the return value.
static func ftYoshiSpecialHiGetEggPosition(fp: Fighter) -> Vector3:
	var pos: Vector3

	pos.x = 0.0
	pos.y = 0.0
	pos.z = 0.0

	pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[FTYOSHI_EGGTHROW_JOINT], pos)

	return pos

## 0x8015E9E0
static func ftYoshiSpecialHiUpdateEggVectors(fp: Fighter) -> void:
	var pos: Vector3

	if fp.status_vars.yoshi.specialhi.egg_gobj != null:
		pos = ftYoshiSpecialHiGetEggPosition(fp)

		DObjGetStruct(fp.status_vars.yoshi.specialhi.egg_gobj).translate = pos

		DObjGetStruct(fp.status_vars.yoshi.specialhi.egg_gobj).scale = fp.joints[FTYOSHI_EGGTHROW_JOINT].scale

## 0x8015EA5C
static func ftYoshiSpecialHiUpdateEggVars(fighter_gobj) -> void:
	var wp: Weapon
	var pos: Vector3
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag2 == 2:
		fp.motion_vars.flags.flag2 = 0

		if fp.status_vars.yoshi.specialhi.egg_gobj != null:
			wp = wpGetStruct(fp.status_vars.yoshi.specialhi.egg_gobj)

			wp.weapon_vars.egg_throw.is_throw = TRUE
			wp.weapon_vars.egg_throw.throw_force = fp.status_vars.yoshi.specialhi.throw_force
			wp.weapon_vars.egg_throw.stick_range = fp.input.pl.stick_range.x

			Mpcommon.mpCommonRunWeaponCollisionDefault(fp.status_vars.yoshi.specialhi.egg_gobj, fp.coll_data.p_translate, fp.coll_data)

			fp.status_vars.yoshi.specialhi.egg_gobj = null
		fp.motion_vars.flags.flag1 = 1
	elif fp.motion_vars.flags.flag2 == 1:
		fp.motion_vars.flags.flag2 = 0

		pos = ftYoshiSpecialHiGetEggPosition(fp)

		fp.status_vars.yoshi.specialhi.egg_gobj = Wpyoshieggthrow.wpYoshiEggThrowMakeWeapon(fighter_gobj, pos)

## 0x8015EB0C
static func ftYoshiSpecialHiUpdateEggThrowForce(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.input.pl.button_hold & fp.input.button_mask_b:
		fp.status_vars.yoshi.specialhi.throw_force += 1 # s16

## 0x8015EB38
static func ftYoshiSpecialHiProcUpdate(fighter_gobj) -> void:
	ftYoshiSpecialHiUpdateEggThrowForce(fighter_gobj)
	ftYoshiSpecialHiUpdateEggVars(fighter_gobj)
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommonwait, &"ftCommonWaitSetStatus"))

## 0x8015EB70
static func ftYoshiSpecialAirHiProcUpdate(fighter_gobj) -> void:
	ftYoshiSpecialHiUpdateEggThrowForce(fighter_gobj)
	ftYoshiSpecialHiUpdateEggVars(fighter_gobj)
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommonfall, &"ftCommonFallSetStatus"))

## 0x8015EBA8
static func ftYoshiSpecialHiProcPhysics(fighter_gobj) -> void:
	ftYoshiSpecialHiUpdateEggVectors(ftGetStruct(fighter_gobj))
	Ftphysics.ftPhysicsApplyGroundVelFriction(fighter_gobj)

## 0x8015EBD4
static func ftYoshiSpecialAirHiProcPhysics(fighter_gobj) -> void:
	ftYoshiSpecialHiUpdateEggVectors(ftGetStruct(fighter_gobj))
	Ftphysics.ftPhysicsApplyAirVelFriction(fighter_gobj)

## 0x8015EC00
static func ftYoshiSpecialAirHiSwitchStatusGround(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialHi, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_EFFECT)

	fp.proc_damage = Callable(Ftyoshispecialhi, &"ftYoshiSpecialHiProcDamage")

## 0x8015EC54
static func ftYoshiSpecialHiSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialAirHi, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_EFFECT)

	fp.proc_damage = Callable(Ftyoshispecialhi, &"ftYoshiSpecialHiProcDamage")

	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x8015ECAC
static func ftYoshiSpecialHiProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftyoshispecialhi, &"ftYoshiSpecialHiSwitchStatusAir"))

## 0x8015ECD0
static func ftYoshiSpecialAirHiProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 != 0:
		Mpcommon.mpCommonProcFighterCliff(fighter_gobj, Callable(Ftyoshispecialhi, &"ftYoshiSpecialAirHiSwitchStatusGround"))
	else:
		Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftyoshispecialhi, &"ftYoshiSpecialAirHiSwitchStatusGround"))

## 0x8015ED18
static func ftYoshiSpecialHiInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_damage = Callable(Ftyoshispecialhi, &"ftYoshiSpecialHiProcDamage")
	fp.motion_vars.flags.flag2 = 0
	fp.motion_vars.flags.flag1 = 0
	fp.status_vars.yoshi.specialhi.egg_gobj = null
	fp.status_vars.yoshi.specialhi.throw_force = 0

## 0x8015ED3C
static func ftYoshiSpecialHiSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialHi, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftYoshiSpecialHiInitStatusVars(fighter_gobj)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x8015ED7C
static func ftYoshiSpecialAirHiSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTYoshiStatusSpecialAirHi, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftYoshiSpecialHiInitStatusVars(fighter_gobj)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
