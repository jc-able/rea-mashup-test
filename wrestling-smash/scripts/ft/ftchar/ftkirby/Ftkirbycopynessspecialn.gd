## 1:1 port of src/ft/ftchar/ftkirby/ftkirbycopynessspecialn.c (ssb-decomp-re): Kirby's copied
## Ness PK Fire.
class_name Ftkirbycopynessspecialn
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

const FTKIRBY_COPYNESS_SPECIALN_STATUS_FLAGS := (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80155B40
static func ftKirbyCopyNessSpecialNProcAccessory(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos
	var vel: Vector3
	var angle: float

	if fp.motion_vars.flags.flag0 != FALSE: # Check if flag to summon PK Fire is true
		fp.motion_vars.flags.flag0 = FALSE # Revert to 0 if PK Fire is summoned, so it doesn't repeat on every frame of the move

		pos = Vector3(0.0, 0.0, 0.0)

		pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[FTKIRBY_COPYNESS_PKFIRE_SPAWN_JOINT], pos)

		pos.x += FTKIRBY_COPYNESS_PKFIRE_SPAWN_OFF_X * fp.lr
		pos.y += FTKIRBY_COPYNESS_PKFIRE_SPAWN_OFF_Y

		if fp.ga == nMPKineticsAir:
			vel.z = 0.0
			angle = FTKIRBY_COPYNESS_PKFIRE_SPARK_ANGLE_AIR
			vel.x = __cosf(FTKIRBY_COPYNESS_PKFIRE_SPARK_ANGLE_AIR) * FTKIRBY_COPYNESS_PKFIRE_SPARK_VEL_AIR * fp.lr
			vel.y = __sinf(FTKIRBY_COPYNESS_PKFIRE_SPARK_ANGLE_AIR) * FTKIRBY_COPYNESS_PKFIRE_SPARK_VEL_AIR
		else:
			vel.z = 0.0
			angle = FTKIRBY_COPYNESS_PKFIRE_SPARK_ANGLE_GROUND
			vel.x = __cosf(FTKIRBY_COPYNESS_PKFIRE_SPARK_ANGLE_GROUND) * FTKIRBY_COPYNESS_PKFIRE_SPARK_VEL_GROUND * fp.lr
			vel.y = __sinf(FTKIRBY_COPYNESS_PKFIRE_SPARK_ANGLE_GROUND) * FTKIRBY_COPYNESS_PKFIRE_SPARK_VEL_GROUND

		Wpnesspkfire.wpNessPKFireMakeWeapon(fighter_gobj, pos, vel, angle) # Spawn PK Fire

## 0x80155CAC
static func ftKirbyCopyNessSpecialNProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftkirbycopynessspecialn, &"ftKirbyCopyNessSpecialNSwitchStatusAir"))

## 0x80155CD0
static func ftKirbyCopyNessSpecialAirNProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbycopynessspecialn, &"ftKirbyCopyNessSpecialAirNSwitchStatusGround"))

## 0x80155CF4
static func ftKirbyCopyNessSpecialAirNSwitchStatusGround(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyNessSpecialN, fighter_gobj.anim_frame, 1.0, FTKIRBY_COPYNESS_SPECIALN_STATUS_FLAGS)

	fp.proc_accessory = Callable(Ftkirbycopynessspecialn, &"ftKirbyCopyNessSpecialNProcAccessory")

## 0x80155D48
static func ftKirbyCopyNessSpecialNSwitchStatusAir(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyNessSpecialAirN, fighter_gobj.anim_frame, 1.0, FTKIRBY_COPYNESS_SPECIALN_STATUS_FLAGS)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

	fp.proc_accessory = Callable(Ftkirbycopynessspecialn, &"ftKirbyCopyNessSpecialNProcAccessory")

## 0x80155DA4
static func ftKirbyCopyNessSpecialNInitStatusVars(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag0 = 0

	fp.proc_accessory = Callable(Ftkirbycopynessspecialn, &"ftKirbyCopyNessSpecialNProcAccessory")

## 0x80155DBC
static func ftKirbyCopyNessSpecialNSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyNessSpecialN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftKirbyCopyNessSpecialNInitStatusVars(fighter_gobj)

## 0x80155DFC
static func ftKirbyCopyNessSpecialAirNSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyNessSpecialAirN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftKirbyCopyNessSpecialNInitStatusVars(fighter_gobj)
