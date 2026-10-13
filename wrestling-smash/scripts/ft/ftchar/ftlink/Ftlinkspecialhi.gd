## 1:1 port of src/ft/ftchar/ftlink/ftlinkspecialhi.c (ssb-decomp-re).
## Link up special (Spin Attack); the hitbox is a weapon (Wplinkspinattack) that follows Link.
class_name Ftlinkspecialhi
extends Port

## wpvars.h constants used here (WPSPINATTACK_EXTEND_POS_COUNT) come from SSBDefs.

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x80163B40
static func ftLinkSpecialHiDestroyWeapon(fp: Fighter, wp: Weapon) -> void:
	wp.is_hitlag_weapon = FALSE

	wp.weapon_vars.spin_attack.is_destroy = TRUE

	Wpmain.wpMainDestroyWeapon(wp.weapon_gobj)

	fp.status_vars.link.specialhi.spin_attack_gobj = null

## 0x80163B80
static func ftLinkSpecialHiUpdateWeaponPos(fighter_gobj, wp: Weapon) -> void:
	wp.weapon_vars.spin_attack.pos_index += 1
	wp.weapon_vars.spin_attack.pos_index %= WPSPINATTACK_EXTEND_POS_COUNT

	# s16 pos_x[] / pos_y[]: implicit f32 -> s16 conversion
	wp.weapon_vars.spin_attack.pos_x[wp.weapon_vars.spin_attack.pos_index] = _s16(DObjGetStruct(fighter_gobj).translate.x)
	wp.weapon_vars.spin_attack.pos_y[wp.weapon_vars.spin_attack.pos_index] = _s16(DObjGetStruct(fighter_gobj).translate.y)

## 0x80163BF0
static func ftLinkSpecialHiDecWeaponLifeCheckDestroy(fighter_gobj, wp: Weapon) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if Wpmain.wpMainDecLifeCheckExpire(wp) != FALSE:
		ftLinkSpecialHiDestroyWeapon(fp, wp)

## 0x80163C2C
static func ftLinkSpecialHiUpdateWeaponAttack(fighter_gobj, wp: Weapon) -> void:
	var fp := ftGetStruct(fighter_gobj)

	# WARNING (C comment): UB - the original passes fighter_gobj to wpProcessUpdateHitPositions, which
	# expects a weapon_gobj (see _wpProcessUpdateHitPositionsFighterUB below).
	match fp.motion_vars.flags.flag2:
		0:
			pass

		1:
			wp.attack_coll.attack_state = nGMAttackStateNew
			wp.attack_coll.size = FTLINK_SPINATTACK_FLAG_SIZE_1

			_wpProcessUpdateHitPositionsFighterUB(fighter_gobj)

		2:
			wp.attack_coll.attack_state = nGMAttackStateNew
			wp.attack_coll.size = FTLINK_SPINATTACK_FLAG_SIZE_2

			_wpProcessUpdateHitPositionsFighterUB(fighter_gobj)

		3:
			wp.attack_coll.attack_state = nGMAttackStateNew
			wp.attack_coll.size = FTLINK_SPINATTACK_FLAG_SIZE_3

			_wpProcessUpdateHitPositionsFighterUB(fighter_gobj)

		4:
			wp.attack_coll.attack_state = nGMAttackStateNew
			wp.attack_coll.size = FTLINK_SPINATTACK_FLAG_SIZE_4

			_wpProcessUpdateHitPositionsFighterUB(fighter_gobj)

		13:
			wp.attack_coll.attack_state = nGMAttackStateOff

		_:
			wp.attack_coll.attack_state = nGMAttackStateOff
	fp.motion_vars.flags.flag2 = 0

## 0x80163D00
static func ftLinkSpecialHiProcEffect(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.link.specialhi.spin_attack_gobj != null:
		var wp := wpGetStruct(fp.status_vars.link.specialhi.spin_attack_gobj)

		if fp.hitlag_tics != 0:
			wp.is_hitlag_weapon = TRUE
		else:
			wp.is_hitlag_weapon = FALSE

## 0x80163D44
static func ftLinkSpecialHiUpdateWeaponVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.link.specialhi.spin_attack_gobj != null:
		var wp := wpGetStruct(fp.status_vars.link.specialhi.spin_attack_gobj)

		ftLinkSpecialHiUpdateWeaponAttack(fighter_gobj, wp)
		ftLinkSpecialHiUpdateWeaponPos(fighter_gobj, wp)
		ftLinkSpecialHiDecWeaponLifeCheckDestroy(fighter_gobj, wp)

## 0x80163D94
static func ftLinkSpecialHiMakeWeapon(fighter_gobj, is_skip_gobj: int) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3

	if (fp.motion_vars.flags.flag0 != 0) and (fp.status_vars.link.specialhi.spin_attack_gobj == null):
		fp.motion_vars.flags.flag0 = 0

		if Efmanager.efManagerLinkSpinAttackMakeEffect(fighter_gobj) != null:
			fp.is_effect_attach = TRUE
		if is_skip_gobj == FALSE:
			pos.z = 0.0
			pos.y = pos.z
			pos.x = pos.y

			pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[FTLINK_SPINATTACK_SPAWN_JOINT], pos)

			fp.status_vars.link.specialhi.spin_attack_gobj = Wplinkspinattack.wpLinkSpinAttackMakeWeapon(fighter_gobj, pos)

			if fp.status_vars.link.specialhi.spin_attack_gobj != null:
				var wp := wpGetStruct(fp.status_vars.link.specialhi.spin_attack_gobj)
				var i: int

				wp.attack_coll.attack_state = nGMAttackStateOff

				i = 0
				while i < WPSPINATTACK_EXTEND_POS_COUNT:
					wp.weapon_vars.spin_attack.pos_x[i] = _s16(DObjGetStruct(fighter_gobj).translate.x)
					wp.weapon_vars.spin_attack.pos_y[i] = _s16(DObjGetStruct(fighter_gobj).translate.y)
					i += 1

## 0x80163EFC
static func ftLinkSpecialHiProcDamage(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.link.specialhi.spin_attack_gobj != null:
		ftLinkSpecialHiDestroyWeapon(fp, wpGetStruct(fp.status_vars.link.specialhi.spin_attack_gobj))

## 0x80163F30
static func ftLinkSpecialHiProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftlinkspecialhi, &"ftLinkSpecialHiEndSetStatus"))

## 0x80163F54
static func ftLinkSpecialHiEndProcUpdate(fighter_gobj) -> void:
	if fighter_gobj.anim_frame <= 0.0:
		var fp := ftGetStruct(fighter_gobj)

		if fp.status_vars.link.specialhi.spin_attack_gobj != null:
			ftLinkSpecialHiDestroyWeapon(fp, wpGetStruct(fp.status_vars.link.specialhi.spin_attack_gobj))
		Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)

## 0x80163FB0
static func ftLinkSpecialAirHiProcUpdate(fighter_gobj) -> void:
	if fighter_gobj.anim_frame <= 0.0:
		var fp := ftGetStruct(fighter_gobj)

		if fp.status_vars.link.specialhi.spin_attack_gobj != null:
			ftLinkSpecialHiDestroyWeapon(fp, wpGetStruct(fp.status_vars.link.specialhi.spin_attack_gobj))
		Ftcommonfallspecial.ftCommonFallSpecialSetStatus(fighter_gobj, FTLINK_SPINATTACK_FALLSPECIAL_DRIFT, FALSE, TRUE, TRUE, FTLINK_SPINATTACK_LANDING_LAG, FALSE)

## 0x80164030
static func ftLinkSpecialHiProcPhysics(fighter_gobj) -> void:
	ftLinkSpecialHiUpdateWeaponVars(fighter_gobj)
	ftLinkSpecialHiMakeWeapon(fighter_gobj, FALSE)
	Ftphysics.ftPhysicsApplyGroundVelFriction(fighter_gobj)

## 0x80164064
static func ftLinkSpecialAirHiProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var gravity: float

	ftLinkSpecialHiUpdateWeaponVars(fighter_gobj)
	ftLinkSpecialHiMakeWeapon(fighter_gobj, TRUE)

	gravity = fp.attr.gravity if (fp.motion_vars.flags.flag1 != 0) else fp.attr.gravity * FTLINK_SPINATTACK_GRAVITY_MUL

	Ftphysics.ftPhysicsApplyGravityClampTVel(fp, gravity, fp.attr.tvel_base)

	if Ftphysics.ftPhysicsCheckClampAirVelXDecMax(fp, fp.attr) == FALSE:
		var attr = fp.attr

		Ftphysics.ftPhysicsClampAirVelXStickRange(fp, FTPHYSICS_AIRDRIFT_CLAMP_RANGE_MIN, attr.air_accel * FTLINK_SPINATTACK_AIR_DRIFT_MUL, attr.air_speed_max_x)
		Ftphysics.ftPhysicsApplyAirVelXFriction(fp, fp.attr)

## 0x80164128
static func ftLinkSpecialHiProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if Mpcommon.mpCommonCheckFighterOnFloor(fighter_gobj) == FALSE:
		Mpcommon.mpCommonSetFighterAir(fp)
		Ftmain.ftMainSetStatus(fighter_gobj, nFTLinkStatusSpecialAirHi, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_HIT))

		fp.proc_damage = Callable(Ftlinkspecialhi, &"ftLinkSpecialHiProcDamage")

		fp.jumps_used = fp.attr.jumps_max

## 0x80164198
static func ftLinkSpecialHiEndProcMap(fighter_gobj) -> void:
	if Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftcommonfall, &"ftCommonFallSetStatus")) == FALSE:
		ftLinkSpecialHiProcDamage(fighter_gobj)

## 0x801641D0
static func ftLinkSpecialAirHiProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if Mpcommon.mpCommonCheckFighterCeilHeavyCliff(fighter_gobj) != FALSE:
		ftLinkSpecialHiProcDamage(fighter_gobj)

		if fp.coll_data.mask_stat & MAP_FLAG_CLIFF_MASK:
			Ftcommoncliffcatchwait.ftCommonCliffCatchSetStatus(fighter_gobj)
		elif fp.coll_data.mask_stat & MAP_FLAG_FLOOR:
			Mpcommon.mpCommonSetFighterGround(fp)
			Ftmain.ftMainSetStatus(fighter_gobj, nFTLinkStatusSpecialHiEnd, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

			fp.proc_damage = Callable(Ftlinkspecialhi, &"ftLinkSpecialHiProcDamage")

## 0x8016426C
static func ftLinkSpecialHiProcStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag0 = 0
	fp.motion_vars.flags.flag2 = 0
	fp.motion_vars.flags.flag1 = 0

	fp.status_vars.link.specialhi.spin_attack_gobj = null

## 0x80164284
static func ftLinkSpecialHiSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_status = Callable(Ftlinkspecialhi, &"ftLinkSpecialHiProcStatus")

	Ftmain.ftMainSetStatus(fighter_gobj, nFTLinkStatusSpecialHi, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.proc_damage = Callable(Ftlinkspecialhi, &"ftLinkSpecialHiProcDamage")
	fp.proc_passive = Callable(Ftlinkspecialhi, &"ftLinkSpecialHiProcEffect")

## 0x801642EC
static func ftLinkSpecialHiEndSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTLinkStatusSpecialHiEnd, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.proc_damage = Callable(Ftlinkspecialhi, &"ftLinkSpecialHiProcDamage")
	fp.proc_passive = Callable(Ftlinkspecialhi, &"ftLinkSpecialHiProcEffect")

## 0x80164348
static func ftLinkSpecialAirHiSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_status = Callable(Ftlinkspecialhi, &"ftLinkSpecialHiProcStatus")

	Ftmain.ftMainSetStatus(fighter_gobj, nFTLinkStatusSpecialAirHi, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.physics.vel_air.y = FTLINK_SPINATTACK_AIR_VEL_Y

	fp.jumps_used = fp.attr.jumps_max

	fp.proc_damage = Callable(Ftlinkspecialhi, &"ftLinkSpecialHiProcDamage")
	fp.proc_passive = Callable(Ftlinkspecialhi, &"ftLinkSpecialHiProcEffect")

# // // // // // // // // // // // //
#        PORT HELPERS
# // // // // // // // // // // // //

## C implicit f32 -> s16 store (truncate toward zero, keep the low 16 bits as signed).
static func _s16(x: float) -> int:
	var v: int = int(x) & 0xFFFF
	return v - 0x10000 if v >= 0x8000 else v

## Non-AVOID_UB build: `wpProcessUpdateHitPositions(fighter_gobj)` reinterprets the FTStruct as a WPStruct.
## In the US ROM (0x80165FA0) the hitbox loop bound is `lw v1, 0x150(user_data)` followed by `blez v1`;
## FTStruct+0x150 is `attack1_followup_frames` (an f32 read as s32). The loop therefore only runs when
## that float is > 0.0F (only possible right after a jab), in which case the original reads/writes
## fighter memory as weapon hitbox data (memory corruption that cannot be reproduced). In every other
## case - the normal one - the call is a no-op, which is what this port does. The weapon's own
## wpProcessProcWeaponMain still runs wpProcessUpdateHitPositions(weapon_gobj) later in the frame.
static func _wpProcessUpdateHitPositionsFighterUB(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.attack1_followup_frames > 0.0:
		StubLog.hit("Ftlinkspecialhi.wpProcessUpdateHitPositions(fighter_gobj) UB with attack1_followup_frames > 0")
