## 1:1 port of src/ft/ftchar/ftmario/ftmariospecialn.c (ssb-decomp-re).
## Mario / Luigi neutral special (Fireball). Luigi shares these functions (dFTLuigiSpecialStatusDescs).
class_name Ftmariospecialn
extends Port

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x80155E40
static func ftMarioSpecialNProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Mpcommon, &"mpCommonSetFighterWaitOrFall"))

## 0x80155E64
static func ftMarioSpecialNProcAccessory(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3
	var fireball_item_id: int = 0 # 0 = Mario, 1 = Luigi

	if fp.motion_vars.flags.flag0 != 0:
		fp.motion_vars.flags.flag0 = 0

		pos.x = 0.0
		pos.y = 0.0
		pos.z = 0.0

		pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[FTMARIO_FIREBALL_SPAWN_JOINT], pos)

		match fp.fkind: # jtbl at 0x8018C630
			nFTKindMario, nFTKindMMario, nFTKindNMario:
				fireball_item_id = 0

			nFTKindLuigi, nFTKindNLuigi:
				fireball_item_id = 1

			_:
				# Undefined behavior in C (uninitialized var, the projectile spawn function still runs).
				# Only Mario/Luigi kinds ever reach this status, so this case is unreachable in practice.
				pass

		Wpmariofireball.wpMarioFireballMakeWeapon(fighter_gobj, pos, fireball_item_id)

## 0x80155F04
static func ftMarioSpecialNProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftmariospecialn, &"ftMarioSpecialNSwitchStatusAir"))

## 0x80155F28
static func ftMarioSpecialAirNProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftmariospecialn, &"ftMarioSpecialAirNSwitchStatusGround"))

## 0x80155F4C
static func ftMarioSpecialAirNSwitchStatusGround(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTMarioStatusSpecialN, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_COLANIM)

	fp.proc_accessory = Callable(Ftmariospecialn, &"ftMarioSpecialNProcAccessory")

## 0x80155FA0
static func ftMarioSpecialNSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTMarioStatusSpecialAirN, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_COLANIM)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

	fp.proc_accessory = Callable(Ftmariospecialn, &"ftMarioSpecialNProcAccessory")

## 0x80155FFC
static func ftMarioSpecialNInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag0 = FALSE
	fp.proc_accessory = Callable(Ftmariospecialn, &"ftMarioSpecialNProcAccessory")

## 0x80156014
static func ftMarioSpecialNSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTMarioStatusSpecialN, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftMarioSpecialNInitStatusVars(fighter_gobj)

## 0x80156054
static func ftMarioSpecialAirNSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTMarioStatusSpecialAirN, 0.0, 1.0, FTSTATUS_PRESERVE_FASTFALL)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftMarioSpecialNInitStatusVars(fighter_gobj)
