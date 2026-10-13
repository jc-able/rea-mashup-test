## 1:1 port of src/wp/wpyoshi/wpyoshistar.c (ssb-decomp-re).
## Yoshi Bomb landing stars (two per landing, one in each direction).
##
## WPDesc / WPAttributes are Dictionaries (see Wpmanager.wpManagerMakeWeapon): the C pair
## {p_weapon, o_attributes} is replaced by "attributes" (the WPAttributes transcribed from relocData)
## plus "visual_kind" (placeholder renderer id).
class_name Wpyoshistar
extends Port

## wpvars.h constants used here (WPYOSHISTAR_LIFETIME, WPYOSHISTAR_LIFETIME_SCALE_MUL, WPYOSHISTAR_LIFETIME_SCALE_ADD, WPYOSHISTAR_ROTATE_SPEED, WPYOSHISTAR_VEL_CLAMP, WPYOSHISTAR_ANGLE, WPYOSHISTAR_VEL, WPYOSHISTAR_OFF_X, WPYOSHISTAR_OFF_Y) come from SSBDefs.

# // // // // // // // // // // // //
#      RELOC DATA (WPAttributes)
# // // // // // // // // // // // //

## src/relocData/247_YoshiMain.c : dYoshiMain_StarWeaponAttributes
## (&gFTDataYoshiMain + llYoshiMainStarWeaponAttributes = 0x40).
## Model pointers (data / p_mobjsubs / anim_joints / p_matanim_joints) are render-only and left null.
const dYoshiMain_StarWeaponAttributes := {
	"data": null,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 100,
	"map_coll_center": 0,
	"map_coll_bottom": -100,
	"map_coll_width": 96,
	"size": 160,
	"angle": 361,
	"knockback_scale": 100,
	"damage": 4,
	"element": nGMHitElementNormal,
	"knockback_weight": 30,
	"shield_damage": -3,      # (heals shields)
	"attack_count": 1,
	"can_setoff": 1,
	"sfx": nSYAudioFGMKickS,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_absorb": 1,
	"can_shield": 1,
	"knockback_base": 0,
}

# // // // // // // // // // // // //
#        INITIALIZED DATA
# // // // // // // // // // // // //

## C: {&gFTDataYoshiMain, &llYoshiMainStarWeaponAttributes}
static var dWPYoshiStarWeaponDesc: Dictionary = {
	"flags": 0x00,                                     # Render flags?
	"kind": nWPKindYoshiStar,                          # Weapon Kind
	"attributes": dYoshiMain_StarWeaponAttributes,
	"visual_kind": "yoshi_star",
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0},
	"proc_update": Callable(Wpyoshistar, &"wpYoshiStarProcUpdate"),
	"proc_map": Callable(Wpyoshistar, &"wpYoshiStarProcMap"),
	"proc_hit": Callable(Wpyoshistar, &"wpYoshiStarProcHit"),
	"proc_shield": Callable(Wpyoshistar, &"wpYoshiStarProcShield"),
	"proc_hop": Callable(Wpyoshistar, &"wpYoshiStarProcHop"),
	"proc_setoff": Callable(Wpyoshistar, &"wpYoshiStarProcHit"),
	"proc_reflector": Callable(Wpyoshistar, &"wpYoshiStarProcReflector"),
	"proc_absorb": Callable(Wpyoshistar, &"wpYoshiStarProcShield"),
}

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8016C540
static func wpYoshiStarGetScale(wp: Weapon) -> float:
	var scale: float = (wp.lifetime * WPYOSHISTAR_LIFETIME_SCALE_MUL) + WPYOSHISTAR_LIFETIME_SCALE_ADD

	if scale > 1.0:
		scale = 1.0
	return scale

## 0x8016C588
static func wpYoshiStarProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var scale: float
	var vel_sqrt: float
	var vel_mul: float

	if Wpmain.wpMainDecLifeCheckExpire(wp) != FALSE:
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

		return TRUE
	scale = wpYoshiStarGetScale(wp)

	DObjGetStruct(weapon_gobj).scale.x = scale
	DObjGetStruct(weapon_gobj).scale.y = scale

	DObjGetStruct(weapon_gobj).rotate.z += (WPYOSHISTAR_ROTATE_SPEED * wp.lr)

	vel_sqrt = sqrtf(SQUARE(wp.physics.vel_air.x) + SQUARE(wp.physics.vel_air.y))

	if vel_sqrt > 0.0:
		if vel_sqrt < WPYOSHISTAR_VEL_CLAMP:
			vel_mul = 0.0
		else:
			vel_mul = vel_sqrt - WPYOSHISTAR_VEL_CLAMP

		wp.physics.vel_air.x = (wp.physics.vel_air.x * vel_mul) / vel_sqrt
		wp.physics.vel_air.y = (wp.physics.vel_air.y * vel_mul) / vel_sqrt
	return FALSE

## 0x8016C6A0
static func wpYoshiStarProcMap(weapon_gobj) -> int:
	return FALSE

## 0x8016C6AC
static func wpYoshiStarProcHit(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	Efmanager.efManagerSparkleWhiteMakeEffect(DObjGetStruct(weapon_gobj).translate)

	if wp.hit_normal_damage != 0:
		return TRUE
	else:
		return FALSE

## 0x8016C6F0
static func wpYoshiStarProcShield(weapon_gobj) -> int:
	Efmanager.efManagerSparkleWhiteMakeEffect(DObjGetStruct(weapon_gobj).translate)

	return TRUE

## 0x8016C718
static func wpYoshiStarProcHop(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	wp.physics.vel_air = syVectorRotateAbout3D(wp.physics.vel_air, wp.shield_collide_dir, wp.shield_collide_angle * 2)

	DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x)

	if wp.physics.vel_air.x > 0.0:
		wp.lr = +1
	else:
		wp.lr = -1

	return FALSE

## 0x8016C7B0
static func wpYoshiStarProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)

	wp.lifetime = WPYOSHISTAR_LIFETIME

	Wpmain.wpMainReflectorSetLR(wp, fp)

	DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x)

	DObjGetStruct(weapon_gobj).scale.x = 1.0
	DObjGetStruct(weapon_gobj).scale.y = 1.0

	wp.lr = -wp.lr

	return FALSE

## 0x8016C834
## (non-AVOID_UB build: the non-NULL path falls off the end without a return value; the only caller,
## wpYoshiStarMakeStars, ignores it.)
static func wpYoshiStarMakeWeapon(fighter_gobj, pos: Vector3, lr: int):
	var weapon_gobj
	var wp: Weapon
	var offset: Vector3 = pos

	offset.y += WPYOSHISTAR_OFF_Y

	if lr == +1:
		offset.x += WPYOSHISTAR_OFF_X
	else:
		offset.x -= WPYOSHISTAR_OFF_X

	weapon_gobj = Wpmanager.wpManagerMakeWeapon(fighter_gobj, dWPYoshiStarWeaponDesc, offset, (WEAPON_FLAG_COLLPROJECT | WEAPON_FLAG_PARENT_FIGHTER))

	if weapon_gobj == null:
		return null
	wp = wpGetStruct(weapon_gobj)

	wp.lr = lr

	wp.lifetime = WPYOSHISTAR_LIFETIME

	wp.physics.vel_air.x = __cosf(WPYOSHISTAR_ANGLE) * (WPYOSHISTAR_VEL * wp.lr)
	wp.physics.vel_air.y = __sinf(WPYOSHISTAR_ANGLE) * WPYOSHISTAR_VEL

	return weapon_gobj

## 0x8016C954
static func wpYoshiStarMakeStars(fighter_gobj, pos: Vector3):
	var fp := ftGetStruct(fighter_gobj)

	wpYoshiStarMakeWeapon(fighter_gobj, pos, fp.lr)
	wpYoshiStarMakeWeapon(fighter_gobj, pos, -fp.lr)

	return null
