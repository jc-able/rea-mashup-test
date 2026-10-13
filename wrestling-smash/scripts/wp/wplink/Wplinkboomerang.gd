## 1:1 port of src/wp/wplink/wplinkboomerang.c (ssb-decomp-re).
## Link (and Kirby's copy) Boomerang projectile.
##
## WPDesc / WPAttributes are Dictionaries (see Wpmanager.wpManagerMakeWeapon): the C pair
## {p_weapon, o_attributes} is replaced by "attributes" (the WPAttributes transcribed from relocData)
## plus "visual_kind" (placeholder renderer id).
class_name Wplinkboomerang
extends Port

## wpvars.h constants used here (WPBOOMERANG_OFF_X, WPBOOMERANG_OFF_Y, WPBOOMERANG_HOMING_ANGLE_MAX, WPBOOMERANG_HOMING_ANGLE_MIN, WPBOOMERANG_VEL_SMASH, WPBOOMERANG_VEL_TILT, WPBOOMERANG_RETURN_DAMAGE, WPBOOMERANG_ANGLE_STICK_THRESHOLD, WPBOOMERANG_LIFETIME_SMASH, WPBOOMERANG_LIFETIME_TILT, WPBOOMERANG_LIFETIME_REFLECT) come from SSBDefs.

# // // // // // // // // // // // //
#          ENUMERATORS
# // // // // // // // // // // // //

## enum wpLinkBoomerangFlags
const nWPLinkBoomerangFlagReturn = 0
const nWPLinkBoomerangFlagDestroy = 1
const nWPLinkBoomerangFlagForward = 2
const nWPLinkBoomerangFlagUnk2 = 3
const nWPLinkBoomerangFlagUnk3 = 4
const nWPLinkBoomerangFlagReflect = 5

# // // // // // // // // // // // //
#             MACROS
# // // // // // // // // // // // //

const WPLINK_BOOMERANG_FLAG_RETURN = (1 << nWPLinkBoomerangFlagReturn)
const WPLINK_BOOMERANG_FLAG_DESTROY = (1 << nWPLinkBoomerangFlagDestroy)
const WPLINK_BOOMERANG_FLAG_FORWARD = (1 << nWPLinkBoomerangFlagForward)
const WPLINK_BOOMERANG_FLAG_UNK2 = (1 << nWPLinkBoomerangFlagUnk2)
const WPLINK_BOOMERANG_FLAG_UNK3 = (1 << nWPLinkBoomerangFlagUnk3)
const WPLINK_BOOMERANG_FLAG_REFLECT = (1 << nWPLinkBoomerangFlagReflect)

# // // // // // // // // // // // //
#      RELOC DATA (WPAttributes)
# // // // // // // // // // // // //

## src/relocData/226_LinkSpecial1.c : dLinkSpecial1_Boomerang_WeaponAttributes
## (&gFTDataLinkSpecial1 + llLinkSpecial1BoomerangWeaponAttributes), REGION_US values.
## Model pointers (data / p_mobjsubs / anim_joints / p_matanim_joints) are render-only and left null.
const dLinkSpecial1_Boomerang_WeaponAttributes := {
	"data": null,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 150,
	"map_coll_center": 0,
	"map_coll_bottom": -150,
	"map_coll_width": 150,
	"size": 200,
	"angle": 70,
	"knockback_scale": 30,
	"damage": 9,
	"element": 0,             # nGMHitElementNormal
	"knockback_weight": 0,
	"shield_damage": 1,
	"attack_count": 2,
	"can_setoff": 1,
	"sfx": 31,                # nSYAudioFGMKickL (REGION_US enum value)
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_absorb": 0,
	"can_shield": 1,
	"knockback_base": 55,
}

# // // // // // // // // // // // //
#        INITIALIZED DATA
# // // // // // // // // // // // //

## C: {&gFTDataLinkSpecial1, &llLinkSpecial1BoomerangWeaponAttributes}
static var dWPLinkBoomerangWeaponDesc: Dictionary = {
	"flags": 0x01,                                     # Render flags? (DOBJDESC)
	"kind": nWPKindBoomerang,                          # Weapon Kind
	"attributes": dLinkSpecial1_Boomerang_WeaponAttributes,
	"visual_kind": "link_boomerang",
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0},
	"proc_update": Callable(Wplinkboomerang, &"wpLinkBoomerangProcUpdate"),
	"proc_map": Callable(Wplinkboomerang, &"wpLinkBoomerangProcMap"),
	"proc_hit": Callable(Wplinkboomerang, &"wpLinkBoomerangProcHit"),
	"proc_shield": Callable(Wplinkboomerang, &"wpLinkBoomerangProcShield"),
	"proc_hop": Callable(Wplinkboomerang, &"wpLinkBoomerangProcHop"),
	"proc_setoff": Callable(Wplinkboomerang, &"wpLinkBoomerangProcHit"),
	"proc_reflector": Callable(Wplinkboomerang, &"wpLinkBoomerangProcReflector"),
	"proc_absorb": Callable(Wplinkboomerang, &"wpLinkBoomerangProcHit"),
}

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8016CC50
## C: void wpLinkBoomerangClampAngle360(f32 *angle) - in/out parameter, returned.
static func wpLinkBoomerangClampAngle360(angle: float) -> float:
	if angle > F_CST_DTOR32(360.0):
		angle -= F_CST_DTOR32(360.0)
	elif angle < F_CST_DTOR32(-360.0):
		angle += F_CST_DTOR32(360.0)
	return angle

## 0x8016CCA0
static func wpLinkBoomerangCheckOffCamera(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var pos_x: float
	var pos_y: float
	var camera_bound_x: float
	var camera_bound_y: float

	if wp.weapon_vars.boomerang.homing_delay > 0:
		wp.weapon_vars.boomerang.homing_delay -= 1
	else:
		wp.weapon_vars.boomerang.adjust_angle_delay += 1

		if wp.weapon_vars.boomerang.adjust_angle_delay > 8:
			wp.weapon_vars.boomerang.adjust_angle_delay = 0

			# func_ovl2_800EB924(CObjGetStruct(gGMCameraGObj), gGMCameraMatrix, &DObjGetStruct(weapon_gobj)->translate.vec.f, &pos_x, &pos_y);
			var r: Dictionary = _func_ovl2_800EB924(Gmcamera.CObjGetStruct(Gmcamera.gGMCameraGObj), Gmcamera.gGMCameraMatrix, DObjGetStruct(weapon_gobj).translate)
			pos_x = r.rx
			pos_y = r.ry

			camera_bound_x = (Gmcamera.gGMCameraStruct.viewport_width / 2) + 40.0 # s32 / 2 (integer division)
			camera_bound_y = (Gmcamera.gGMCameraStruct.viewport_height / 2) + 40.0

			if (pos_x < -camera_bound_x) or (pos_x > camera_bound_x) or (pos_y < -camera_bound_y) or (pos_y > camera_bound_y):
				return TRUE
	return FALSE

## 0x8016CDC8
static func wpLinkBoomerangSetReturnVars(weapon_gobj, angle_max_or_min: int) -> void:
	var wp := wpGetStruct(weapon_gobj)

	wp.weapon_vars.boomerang.flags |= WPLINK_BOOMERANG_FLAG_RETURN

	wp.attack_coll.damage = WPBOOMERANG_RETURN_DAMAGE

	wp.weapon_vars.boomerang.default_angle -= F_CST_DTOR32(180.0)

	if wp.weapon_vars.boomerang.default_angle < 0.0:
		wp.weapon_vars.boomerang.default_angle += F_CST_DTOR32(360.0)
	wp.lr = -wp.lr

	wp.weapon_vars.boomerang.flyforward_timer = 140

	wp.weapon_vars.boomerang.homing_angle = WPBOOMERANG_HOMING_ANGLE_MAX if (angle_max_or_min == 1) else WPBOOMERANG_HOMING_ANGLE_MIN

	# DObjGetStruct(weapon_gobj)->child->child->flags = DOBJ_FLAG_NOTEXTURE; (render-only; the port's
	# weapon DObj tree may not contain the model's child joints)
	var dobj := DObjGetStruct(weapon_gobj)
	if (dobj != null) and (dobj.child != null) and (dobj.child.child != null):
		dobj.child.child.flags = DOBJ_FLAG_NOTEXTURE

	Wpmain.wpMainPlayFGM(wp, nSYAudioFGMLinkSpecialNReturn)

## 0x8016CE90
static func wpLinkBoomerangAddVelSqrt(wp: Weapon, vel_add: float) -> float:
	var sqrt_vel: float = sqrtf(SQUARE(wp.physics.vel_air.x) + SQUARE(wp.physics.vel_air.y)) + vel_add

	if sqrt_vel > 90.0:
		sqrt_vel = 90.0
	return sqrt_vel

## 0x8016CEEC
static func wpLinkBoomerangSubVelSqrt(wp: Weapon, vel_sub: float) -> float:
	var sqrt_vel: float = sqrtf(SQUARE(wp.physics.vel_air.x) + SQUARE(wp.physics.vel_air.y)) - vel_sub

	if sqrt_vel < 10.0:
		sqrt_vel = 10.0
	return sqrt_vel

## 0x8016CF48
static func wpLinkBoomerangUpdateVelLR(wp: Weapon, vel_mul: float) -> void:
	# The following floating point operations and sqrtf subroutine call are unused and waste CPU cycles
	sqrtf(SQUARE(wp.physics.vel_air.x) + SQUARE(wp.physics.vel_air.y)) # Can we just talk about how this doesn't do anything

	wp.physics.vel_air.x = __cosf(wp.weapon_vars.boomerang.default_angle) * vel_mul
	wp.physics.vel_air.y = __sinf(wp.weapon_vars.boomerang.default_angle) * vel_mul

	wp.lr = -1 if ((wp.weapon_vars.boomerang.default_angle > F_CST_DTOR32(90.0)) and (wp.weapon_vars.boomerang.default_angle < F_CST_DTOR32(270.0))) else +1

## 0x8016CFFC
## C: void wpLinkBoomerangClampAngleForward(f32 *angle) - in/out parameter, returned.
static func wpLinkBoomerangClampAngleForward(angle: float) -> float:
	if (angle > F_CST_DTOR32(30.0)) and (angle <= F_CST_DTOR32(90.0)):
		angle = F_CST_DTOR32(30.0)
	elif (angle < F_CST_DTOR32(150.0)) and (angle >= F_CST_DTOR32(90.0)):
		angle = F_CST_DTOR32(150.0)
	elif (angle > F_CLC_DTOR32(210.0)) and (angle <= F_CST_DTOR32(270.0)):
		angle = F_CLC_DTOR32(210.0)
	elif (angle < F_CLC_DTOR32(330.0)) and (angle >= F_CST_DTOR32(270.0)):
		angle = F_CLC_DTOR32(330.0)
	return angle

## 0x8016D0E4
static func wpLinkBoomerangGetDistUpdateAngle(weapon_gobj) -> float:
	var wp := wpGetStruct(weapon_gobj)
	var dist_x: float
	var dist_y: float
	var angle: float
	var sqrt_dist: float = 0.0

	if wp.weapon_vars.boomerang.parent_gobj != null:
		dist_x = DObjGetStruct(wp.weapon_vars.boomerang.parent_gobj).translate.x - DObjGetStruct(weapon_gobj).translate.x
		dist_y = (DObjGetStruct(wp.weapon_vars.boomerang.parent_gobj).translate.y - DObjGetStruct(weapon_gobj).translate.y) + 290.0

		sqrt_dist = sqrtf(SQUARE(dist_x) + SQUARE(dist_y))

		if wp.weapon_vars.boomerang.flags & WPLINK_BOOMERANG_FLAG_FORWARD:
			if wp.weapon_vars.boomerang.flyforward_timer > 0:
				wp.weapon_vars.boomerang.flyforward_timer -= 1
			elif wp.weapon_vars.boomerang.flyforward_timer == 0:
				return sqrt_dist
		if (wp.weapon_vars.boomerang.flags & WPLINK_BOOMERANG_FLAG_UNK3) and (((dist_x < 0.0) and (wp.lr == +1)) or ((dist_x > 0.0) and (wp.lr == -1))):
			return sqrt_dist
		else:
			angle = syUtilsArcTan2(dist_y, dist_x)

			if angle < F_CST_DTOR32(-180.0):
				angle += F_CST_DTOR32(360.0)
			elif angle > F_CST_DTOR32(180.0):
				angle -= F_CST_DTOR32(360.0)
			angle -= wp.weapon_vars.boomerang.default_angle

			if angle < F_CST_DTOR32(-180.0):
				angle += F_CST_DTOR32(360.0)
			elif angle > F_CST_DTOR32(180.0):
				angle -= F_CST_DTOR32(360.0)
			if angle > wp.weapon_vars.boomerang.homing_angle:
				angle = wp.weapon_vars.boomerang.homing_angle
			elif angle < -wp.weapon_vars.boomerang.homing_angle:
				angle = -wp.weapon_vars.boomerang.homing_angle
			wp.weapon_vars.boomerang.default_angle += angle

			wp.weapon_vars.boomerang.default_angle = wpLinkBoomerangClampAngle360(wp.weapon_vars.boomerang.default_angle)

			if wp.weapon_vars.boomerang.flags & WPLINK_BOOMERANG_FLAG_UNK2:
				wp.weapon_vars.boomerang.default_angle = wpLinkBoomerangClampAngleForward(wp.weapon_vars.boomerang.default_angle)
	return sqrt_dist

## 0x8016D31C
static func wpLinkBoomerangClearGObjs(wp: Weapon) -> void:
	if wp.weapon_vars.boomerang.parent_gobj != null:
		var fp := ftGetStruct(wp.weapon_vars.boomerang.parent_gobj)

		if (fp.fkind == nFTKindKirby) or (fp.fkind == nFTKindNKirby):
			fp.passive_vars.kirby.copylink_boomerang_gobj = null
		else:
			fp.passive_vars.link.boomerang_gobj = null

		wp.weapon_vars.boomerang.parent_gobj = null

## 0x8016D35C
static func wpLinkBoomerangCheckOwnerCatch(weapon_gobj, distance: float) -> void:
	var wp := wpGetStruct(weapon_gobj)

	if (wp.weapon_vars.boomerang.flags & WPLINK_BOOMERANG_FLAG_RETURN) and (distance < 180.0):
		if wp.weapon_vars.boomerang.parent_gobj != null:
			var fp := ftGetStruct(wp.weapon_vars.boomerang.parent_gobj)

			if fp.is_special_interrupt:
				if (fp.fkind == nFTKindKirby) or (fp.fkind == nFTKindNKirby):
					Ftkirbycopylinkspecialn.ftKirbyCopyLinkSpecialNGetSetStatus(wp.weapon_vars.boomerang.parent_gobj)
				else:
					Ftlinkspecialn.ftLinkSpecialNGetSetStatus(wp.weapon_vars.boomerang.parent_gobj)
		wpLinkBoomerangClearGObjs(wp)
		Wpmain.wpMainDestroyWeapon(weapon_gobj)

## 0x8016D40C
static func wpLinkBoomerangCheckBound(wp: Weapon, coll_angle: Vector3) -> int:
	var angle: float = Lbcommon.lbCommonSim2D(wp.physics.vel_air, coll_angle)

	if angle < 0.0:
		if angle > -__sinf(F_CST_DTOR32(30.0)): # 0.5235988F
			wp.physics.vel_air = _vec(Lbcommon.lbCommonReflect2D(wp.physics.vel_air, coll_angle), "a")

			wp.weapon_vars.boomerang.default_angle = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x)

			wp.weapon_vars.boomerang.default_angle = wpLinkBoomerangClampAngle360(wp.weapon_vars.boomerang.default_angle)
		else:
			return TRUE
	return FALSE

## 0x8016D4B8
static func wpLinkBoomerangProcDead(weapon_gobj) -> int:
	wpLinkBoomerangClearGObjs(wpGetStruct(weapon_gobj))

	return TRUE

## 0x8016D4DC
static func wpLinkBoomerangProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if (Wpmain.wpMainDecLifeCheckExpire(wp) != FALSE) or (wpLinkBoomerangCheckOffCamera(weapon_gobj) == TRUE):
		wpLinkBoomerangClearGObjs(wp)

		return TRUE
	if wp.weapon_vars.boomerang.flags & WPLINK_BOOMERANG_FLAG_DESTROY:
		wpLinkBoomerangClearGObjs(wp)

		return TRUE
	if wp.weapon_vars.boomerang.flags & WPLINK_BOOMERANG_FLAG_REFLECT:
		return FALSE
	elif wp.weapon_vars.boomerang.flags & WPLINK_BOOMERANG_FLAG_RETURN:
		wpLinkBoomerangUpdateVelLR(wp, wpLinkBoomerangAddVelSqrt(wp, 1.0))

		wpLinkBoomerangCheckOwnerCatch(weapon_gobj, wpLinkBoomerangGetDistUpdateAngle(weapon_gobj))
	else:
		var vel: float = wpLinkBoomerangSubVelSqrt(wp, 1.4)

		wpLinkBoomerangUpdateVelLR(wp, vel)

		if vel == 10.0:
			wpLinkBoomerangSetReturnVars(weapon_gobj, 0)
	return FALSE

## 0x8016D5EC
static func wpLinkBoomerangProcMap(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var is_collide: int = FALSE
	var coll_flags: int

	if not (wp.weapon_vars.boomerang.flags & (WPLINK_BOOMERANG_FLAG_REFLECT | WPLINK_BOOMERANG_FLAG_RETURN)):
		Wpmap.wpMapTestAll(weapon_gobj)

		coll_flags = ((wp.coll_data.mask_prev ^ wp.coll_data.mask_curr) & wp.coll_data.mask_curr & MAP_FLAG_MAIN_MASK) & 0xFFFF

		if coll_flags:
			Efmanager.efManagerDustCollideMakeEffect(DObjGetStruct(weapon_gobj).translate)

			if coll_flags & MAP_FLAG_LWALL:
				is_collide |= wpLinkBoomerangCheckBound(wp, wp.coll_data.lwall_angle)
			if coll_flags & MAP_FLAG_RWALL:
				is_collide |= wpLinkBoomerangCheckBound(wp, wp.coll_data.rwall_angle)
			if coll_flags & MAP_FLAG_CEIL:
				is_collide |= wpLinkBoomerangCheckBound(wp, wp.coll_data.ceil_angle)
			if coll_flags & MAP_FLAG_FLOOR:
				is_collide |= wpLinkBoomerangCheckBound(wp, wp.coll_data.floor_angle)
			if is_collide == TRUE:
				wpLinkBoomerangSetReturnVars(weapon_gobj, 1)
	return FALSE

## 0x8016D714
static func wpLinkBoomerangProcHit(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if not (wp.weapon_vars.boomerang.flags & (WPLINK_BOOMERANG_FLAG_REFLECT | WPLINK_BOOMERANG_FLAG_RETURN)) and (wp.hit_normal_damage != 0):
		wpLinkBoomerangUpdateVelLR(wp, wpLinkBoomerangSubVelSqrt(wp, 5.0))
		wpLinkBoomerangSetReturnVars(weapon_gobj, 1)
	return FALSE

## 0x8016D77C
static func wpLinkBoomerangProcSetOff(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if not (wp.weapon_vars.boomerang.flags & (WPLINK_BOOMERANG_FLAG_REFLECT | WPLINK_BOOMERANG_FLAG_RETURN)):
		wpLinkBoomerangSetReturnVars(weapon_gobj, 1)
	return FALSE

## 0x8016D7B4
static func wpLinkBoomerangProcShield(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if not (wp.weapon_vars.boomerang.flags & (WPLINK_BOOMERANG_FLAG_REFLECT | WPLINK_BOOMERANG_FLAG_RETURN)):
		wpLinkBoomerangSetReturnVars(weapon_gobj, 1)
	return FALSE

## 0x8016D7EC
static func wpLinkBoomerangProcHop(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if wp.shield_collide_dir.z > 0.0:
		wp.weapon_vars.boomerang.default_angle += (wp.shield_collide_angle * 2)
	else:
		wp.weapon_vars.boomerang.default_angle -= (wp.shield_collide_angle * 2)

	wp.weapon_vars.boomerang.default_angle = wpLinkBoomerangClampAngle360(wp.weapon_vars.boomerang.default_angle)

	return FALSE

## 0x8016D868
static func wpLinkBoomerangProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var dist_x: float
	var dist_y: float

	if not (wp.weapon_vars.boomerang.flags & WPLINK_BOOMERANG_FLAG_REFLECT):
		wp.weapon_vars.boomerang.flags = WPLINK_BOOMERANG_FLAG_REFLECT
		wp.lifetime = WPBOOMERANG_LIFETIME_REFLECT
	dist_x = DObjGetStruct(weapon_gobj).translate.x - DObjGetStruct(wp.owner_gobj).translate.x
	dist_y = DObjGetStruct(weapon_gobj).translate.y - (DObjGetStruct(wp.owner_gobj).translate.y + 250.0)

	wp.weapon_vars.boomerang.default_angle = syUtilsArcTan2(dist_y, dist_x)

	wp.weapon_vars.boomerang.default_angle = wpLinkBoomerangClampAngle360(wp.weapon_vars.boomerang.default_angle)
	wpLinkBoomerangUpdateVelLR(wp, sqrtf(SQUARE(wp.physics.vel_air.x) + SQUARE(wp.physics.vel_air.y)))

	return FALSE

## 0x8016D914
## C: f32 wpLinkBoomerangGetAngleSetVel(Vec3f *vel, FTStruct *fp, s32 lr, f32 vel_mul) - `vel` is a pure
## output, so per the out-parameter convention this returns {"ret": angle, "vel": Vector3}.
static func wpLinkBoomerangGetAngleSetVel(fp: Fighter, lr: int, vel_mul: float) -> Dictionary:
	var angle: float
	var vel: Vector3

	if ABS(fp.input.pl.stick_range.y) > WPBOOMERANG_ANGLE_STICK_THRESHOLD:
		angle = syUtilsArcTan2(fp.input.pl.stick_range.y, ABS(fp.input.pl.stick_range.x))

		if angle > F_CST_DTOR32(30.0): # 0.5235988F
			angle = F_CST_DTOR32(30.0)
		elif angle < F_CST_DTOR32(-30.0): # -0.5235988F
			angle = F_CST_DTOR32(-30.0)
	else:
		angle = 0.0

	vel.x = (__cosf(angle) * vel_mul * lr)
	vel.y = (__sinf(angle) * vel_mul * lr)
	vel.z = 0.0

	if lr == -1:
		if angle < 0.0:
			angle = F_CST_DTOR32(-180.0) - angle
		else:
			angle = F_CST_DTOR32(180.0) - angle
	if angle < 0.0:
		angle += F_CST_DTOR32(360.0)
	return {"ret": angle, "vel": vel}

## 0x8016DA78
static func wpLinkBoomerangMakeWeapon(fighter_gobj, pos: Vector3):
	var fp := ftGetStruct(fighter_gobj)
	var weapon_gobj
	var wp: Weapon
	var offset: Vector3
	var r: Dictionary

	offset = pos

	offset.y += WPBOOMERANG_OFF_Y

	offset.x = offset.x + WPBOOMERANG_OFF_X if (fp.lr == +1) else offset.x - WPBOOMERANG_OFF_X

	weapon_gobj = Wpmanager.wpManagerMakeWeapon(fighter_gobj, dWPLinkBoomerangWeaponDesc, offset, WEAPON_FLAG_PARENT_FIGHTER)

	if weapon_gobj == null:
		return null
	wp = wpGetStruct(weapon_gobj)

	wp.lr = fp.lr

	if _ftLinkSpecialNGetIsSmash(fp) == TRUE:
		wp.lifetime = WPBOOMERANG_LIFETIME_SMASH
		r = wpLinkBoomerangGetAngleSetVel(fp, wp.lr, WPBOOMERANG_VEL_SMASH)
		wp.physics.vel_air = r.vel
		wp.weapon_vars.boomerang.default_angle = r.ret
	else:
		wp.lifetime = WPBOOMERANG_LIFETIME_TILT
		r = wpLinkBoomerangGetAngleSetVel(fp, wp.lr, WPBOOMERANG_VEL_TILT)
		wp.physics.vel_air = r.vel
		wp.weapon_vars.boomerang.default_angle = r.ret
	wp.proc_setoff = Callable(Wplinkboomerang, &"wpLinkBoomerangProcSetOff")
	wp.proc_dead = Callable(Wplinkboomerang, &"wpLinkBoomerangProcDead")

	wp.is_camera_follow = TRUE

	Wpmain.wpMainPlayFGM(wp, nSYAudioFGMLinkSpecialNShoot)

	wp.weapon_vars.boomerang.parent_gobj = fighter_gobj
	wp.weapon_vars.boomerang.flags = WPLINK_BOOMERANG_FLAG_FORWARD
	wp.weapon_vars.boomerang.homing_delay = 130
	wp.weapon_vars.boomerang.adjust_angle_delay = 0

	Wpmain.wpMainVelSetModelPitch(weapon_gobj)

	wp.is_hitlag_victim = TRUE

	return weapon_gobj

# // // // // // // // // // // // //
#        PORT HELPERS
# // // // // // // // // // // // //

## C reads `fp->status_vars.link.specialn.is_smash`. Kirby's copy ability writes the same union slot as
## `status_vars.kirby.copylink_specialn.is_smash` (identical layout); the port keeps union members apart.
static func _ftLinkSpecialNGetIsSmash(fp: Fighter) -> int:
	if (fp.fkind == nFTKindKirby) or (fp.fkind == nFTKindNKirby):
		return fp.status_vars.kirby.copylink_specialn.is_smash
	return fp.status_vars.link.specialn.is_smash

## lbCommonReflect2D writes its Vec3f* argument (and returns the same pointer): accept either the
## written vector or a {"ret", "<param>"} Dictionary.
static func _vec(r, key: String) -> Vector3:
	if r is Dictionary:
		return r[key]
	return r

## func_ovl2_800EB924 (src/ft/ftparam.c): project a world position with the camera matrix into
## viewport coordinates (void, two out-params rx / ry -> {"rx", "ry"} per the out-parameter convention).
## The boomerang's off-camera despawn depends on it, so when Ftparam's port does not return the
## projection (its render-side stub returns null), the same C math is evaluated here:
##     tempx = mtx[0][0]x + mtx[1][0]y + mtx[2][0]z + mtx[3][0];  tempy = (column 1);  scale = (column 3)
##     if (ABSF(scale) < 0.1F) scale = (scale < 0.0F) ? -0.1F : 0.1F;   scale = 1.0F / scale;
##     *rx = (cobj->viewport.vp.vscale[0] / 4) * (tempx * scale);  *ry = (vscale[1] / 4) * (tempy * scale);
## gGMCameraMatrix is a row-major PackedFloat32Array(16) (mtx[i][j] == mtx[i * 4 + j]).
static func _func_ovl2_800EB924(cobj, mtx, vec: Vector3) -> Dictionary:
	var projection := Callable(Ftparam, &"func_ovl2_800EB924")
	var r

	if projection.get_argument_count() >= 5:
		r = projection.call(cobj, mtx, vec, 0.0, 0.0) # pre-convention signature (cobj, mtx, vec, rx, ry)
	else:
		r = projection.call(cobj, mtx, vec)

	if r is Dictionary:
		return r
	if (cobj == null) or (mtx == null):
		# Port-only guard: no battle camera exists (e.g. a test scene) -> treat as on screen.
		return {"rx": 0.0, "ry": 0.0}
	var x: float = vec.x
	var y: float = vec.y
	var z: float = vec.z
	var tempx: float = ((mtx[0 * 4 + 0] * x) + (mtx[1 * 4 + 0] * y) + (mtx[2 * 4 + 0] * z)) + mtx[3 * 4 + 0]
	var tempy: float = ((mtx[0 * 4 + 1] * x) + (mtx[1 * 4 + 1] * y) + (mtx[2 * 4 + 1] * z)) + mtx[3 * 4 + 1]
	var scale: float = ((mtx[0 * 4 + 3] * x) + (mtx[1 * 4 + 3] * y) + (mtx[2 * 4 + 3] * z)) + mtx[3 * 4 + 3]

	if ABSF(scale) < 0.1:
		scale = -0.1 if (scale < 0.0) else 0.1
	scale = 1.0 / scale

	var vscale: Array = cobj.viewport.vp.vscale

	return {"rx": (_s16(vscale[0]) / 4) * (tempx * scale), "ry": (_s16(vscale[1]) / 4) * (tempy * scale)}

## Vp.vscale[] entries are s16 (the camera port stores them as u16 bit patterns).
static func _s16(v) -> int:
	var i: int = int(v) & 0xFFFF
	return i - 0x10000 if i >= 0x8000 else i
