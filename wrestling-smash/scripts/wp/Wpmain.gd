## 1:1 port of src/wp/wpmain.c (ssb-decomp-re): generic weapon helpers (sound, velocity,
## lifetime, destruction, staling, attack records, reflector model rotation).
##
## Pointer conventions: func_ovl3_8016830C(dobj, vec) returns the written Vec3f.
class_name Wpmain
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80167EB0
static func wpMainStopFGM(wp = null) -> void: # Stop weapon's ongoing SFX
	if wp.p_sfx != null:
		if (wp.p_sfx.sfx_id != 0) and (wp.p_sfx.sfx_id == wp.sfx_id):
			Snd.func_80026738_27338(wp.p_sfx)
	wp.p_sfx = null
	wp.sfx_id = 0

## 0x80167F08
static func wpMainPlayFGM(wp = null, sfx_id = null) -> void: # Play sound effect for weapon
	if wp.p_sfx != null:
		wpMainStopFGM(wp)

	wp.p_sfx = Snd.func_800269C0_275C0(int(sfx_id) & 0xFFFF)

	if wp.p_sfx != null:
		wp.sfx_id = wp.p_sfx.sfx_id & 0xFFFF
	else:
		wp.sfx_id = 0

## 0x80167F68
static func wpMainVelSetLR(weapon_gobj = null) -> void: # Set weapon's facing direction based on velocity
	var wp := wpGetStruct(weapon_gobj)

	wp.lr = +1 if (wp.physics.vel_air.x >= 0.0) else -1

## 0x80167FA0
static func wpMainVelSetModelPitch(weapon_gobj = null) -> void: # Set pitch rotation based on velocity
	var wp := wpGetStruct(weapon_gobj)

	DObjGetStruct(weapon_gobj).rotate.y = F_CST_DTOR32(90.0) if (wp.physics.vel_air.x >= 0.0) else F_CST_DTOR32(-90.0)

## 0x80167FE8
static func wpMainDecLifeCheckExpire(wp = null) -> int: # Decrement lifetime and check whether item has expired
	wp.lifetime -= 1

	if wp.lifetime == 0:
		return TRUE
	else:
		return FALSE

## 0x8016800C
static func wpMainDestroyWeapon(weapon_gobj = null) -> void: # Destroy weapon?
	var wp := wpGetStruct(weapon_gobj)

	wpMainStopFGM(wp)                            # Stop weapon's SFX
	Wpmanager.wpManagerSetPrevStructAlloc(wp)    # Eject weapon's user_data from memory?
	Objman.gcEjectGObj(weapon_gobj)              # Eject GObj from memory?

## 0x80168044
static func wpMainVelGroundTransferAir(weapon_gobj = null) -> void: # Transfer weapon's base ground velocity to aerial velocity
	var wp := wpGetStruct(weapon_gobj)

	wp.physics.vel_air.x = wp.lr * wp.coll_data.floor_angle.y * wp.physics.vel_ground
	wp.physics.vel_air.y = wp.lr * -wp.coll_data.floor_angle.x * wp.physics.vel_ground

## 0x80168088
static func wpMainApplyGravityClampTVel(wp = null, gravity = null, terminal_velocity = null) -> void: # Subtract vertical velocity every frame and clamp to terminal velocity
	wp.physics.vel_air.y -= gravity

	if Lbcommon.lbCommonMag2D(wp.physics.vel_air) > terminal_velocity:
		wp.physics.vel_air = Lbcommon.lbCommonNormDist2D(wp.physics.vel_air).vec
		wp.physics.vel_air = Lbcommon.lbCommonScale2D(wp.physics.vel_air, terminal_velocity)

## 0x801680EC
static func wpMainReflectorSetLR(wp = null, fp = null) -> void: # Invert direction on reflect
	if (wp.physics.vel_air.x * fp.lr) < 0.0:
		wp.physics.vel_air.x = -wp.physics.vel_air.x

## 0x80168128
static func wpMainGetStaledDamage(wp = null) -> int: # Return final damage after applying staling and bonus 0.999%
	return int((wp.attack_coll.damage * wp.attack_coll.stale) + 0.999)

## 0x80168158
static func wpMainClearAttackRecord(wp = null) -> void: # Clear hit victims array
	for i in wp.attack_coll.attack_records.size():
		var record: GMAttackRecord = wp.attack_coll.attack_records[i]

		record.victim_gobj = null

		record.victim_flags.is_interact_hurt = FALSE
		record.victim_flags.is_interact_shield = FALSE
		record.victim_flags.is_interact_reflect = FALSE
		record.victim_flags.is_interact_absorb = FALSE

		record.victim_flags.timer_rehit = 0

		record.victim_flags.group_id = 7

## 0x8016830C
## Writes the world position of dobj's origin to vec (returned). The C version multiplies the
## XObj matrices of up to 0x12 joints up the parent chain; here the same matrices are rebuilt
## from each joint's translate / rotate (rpy) / scale (nGCMatrixKindTraRotRpyRSca layout).
static func func_ovl3_8016830C(dobj = null, vec = null) -> Vector3:
	var current_dobj: DObj = dobj
	var pos := Vector3(0.0, 0.0, 0.0)
	var i := 0

	while i != 0x12:
		pos = _wpMainDObjTransformPoint(current_dobj, pos)

		if current_dobj.parent == DOBJ_PARENT_NULL:
			break
		i += 1
		current_dobj = current_dobj.parent

	return pos

## 0x80168428
static func wpMainReflectorRotateWeaponModel(weapon_gobj = null) -> void:
	var wp := wpGetStruct(weapon_gobj)
	var vel: Vector3 = wp.physics.vel_air
	var direction: Vector3
	var angle: Vector3
	var dobj: DObj

	direction.x = 0
	direction.y = 0
	direction.z = -1 if (vel.x > 0.0) else +1

	vel = syVectorNorm3D(vel)

	angle = Lbcommon.lbCommonCross3D(vel, direction)

	dobj = DObjGetStruct(weapon_gobj) # rotate = &DObjGetStruct(weapon_gobj)->rotate.vec.f;

	if direction.z == -1:
		dobj.rotate.y = F_CST_DTOR32(90.0)
		dobj.rotate.x = syUtilsArcTan2(angle.x, angle.y)
	else:
		dobj.rotate.y = F_CST_DTOR32(-90.0)
		dobj.rotate.x = syUtilsArcTan2(-angle.x, angle.y)

	dobj.rotate.z = 0.0

# ---------------------------------------------------------------------------------------
# Port helpers
# ---------------------------------------------------------------------------------------

## One joint's TraRotRpyRSca matrix applied to a point (see func_ovl3_8016830C).
static func _wpMainDObjTransformPoint(dobj: DObj, p: Vector3) -> Vector3:
	var sx := sin(dobj.rotate.x)
	var cx := cos(dobj.rotate.x)
	var sy := sin(dobj.rotate.y)
	var cy := cos(dobj.rotate.y)
	var sz := sin(dobj.rotate.z)
	var cz := cos(dobj.rotate.z)
	var v := Vector3(p.x * dobj.scale.x, p.y * dobj.scale.y, p.z * dobj.scale.z)

	# roll (x), then pitch (y), then yaw (z)
	v = Vector3(v.x, v.y * cx - v.z * sx, v.y * sx + v.z * cx)
	v = Vector3(v.x * cy + v.z * sy, v.y, v.z * cy - v.x * sy)
	v = Vector3(v.x * cz - v.y * sz, v.x * sz + v.y * cz, v.z)

	return v + dobj.translate
