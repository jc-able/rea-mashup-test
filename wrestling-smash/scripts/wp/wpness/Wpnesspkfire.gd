## Port of src/wp/wpness/wpnesspkfire.c (Ness PK Fire spark; spawns the PK Fire pillar item on hit).
class_name Wpnesspkfire
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## WPAttributes at gFTNessFileSpecial1 + llNessSpecial1PKFireWeaponAttributes (0x00):
## src/relocData/240_NessSpecial1.c dNessSpecial1_PKFire_WeaponAttributes (US values; checked against ROM file 240).
const dNessSpecial1_PKFire_WeaponAttributes := {
	"data": null,                       # NessSpecial3 + 0x168 (model; not exported)
	"p_mobjsubs": null,                 # NessSpecial3 + 0x000
	"anim_joints": null,
	"p_matanim_joints": null,           # NessSpecial3 + 0x1E0 (visual)
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 10,
	"map_coll_center": 0,
	"map_coll_bottom": -10,
	"map_coll_width": 10,
	"size": 200,
	"angle": 80,
	"knockback_scale": 50,
	"damage": 4,
	"element": 1,
	"knockback_weight": 0,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 1,
	"sfx": 2,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_absorb": 1,
	"can_shield": 1,
	"knockback_base": 40,
}

static var dWPNessPKFireWeaponDesc := {
	"flags": 0x00,                                              # Render flags?
	"kind": nWPKindPKFire,                                      # Weapon Kind
	# p_weapon = &gFTNessFileSpecial1, o_attributes = &llNessSpecial1PKFireWeaponAttributes
	"attributes": dNessSpecial1_PKFire_WeaponAttributes,
	"transform_types": {"tk1": nGCMatrixKindTra, "tk2": 0x2E, "tk3": 0},
	"proc_update": Callable(Wpnesspkfire, &"wpNessPKFireProcUpdate"),
	"proc_map": Callable(Wpnesspkfire, &"wpNessPKFireProcMap"),
	"proc_hit": Callable(Wpnesspkfire, &"wpNessPKFireProcHit"),
	"proc_shield": Callable(Wpnesspkfire, &"wpNessPKFireProcAbsorb"),
	"proc_hop": Callable(Wpnesspkfire, &"wpNessPKFireProcHop"),
	"proc_setoff": Callable(Wpnesspkfire, &"wpNessPKFireProcHit"),
	"proc_reflector": Callable(Wpnesspkfire, &"wpNessPKFireProcReflector"),
	"proc_absorb": Callable(Wpnesspkfire, &"wpNessPKFireProcAbsorb"),
	"visual_kind": "ness_pk_fire",
}

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8016AA40
static func wpNessPKFireProcUpdate(weapon_gobj) -> int:
	if Wpmain.wpMainDecLifeCheckExpire(wpGetStruct(weapon_gobj)) != FALSE:
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

		return TRUE
	else:
		return FALSE

## 0x8016AA88
static func wpNessPKFireProcMap(weapon_gobj) -> int:
	if Wpmap.wpMapTestAllCheckCollEnd(weapon_gobj) != FALSE:
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

		return TRUE
	else:
		return FALSE

## 0x8016AACC
static func wpNessPKFireProcHit(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var pos: Vector3
	var vel: Vector3

	vel.x = 0.0
	vel.y = 0.0
	vel.z = 0.0

	pos = wp.physics.vel_air

	pos = syVectorNorm3D(pos)

	pos.x = (pos.x * WPPKFIRE_POS_MUL) + DObjGetStruct(weapon_gobj).translate.x
	pos.y = (pos.y * WPPKFIRE_POS_MUL) + DObjGetStruct(weapon_gobj).translate.y
	pos.z = (pos.z * WPPKFIRE_POS_MUL) + DObjGetStruct(weapon_gobj).translate.z

	Itnesspkfire.itNessPKFireMakeItem(weapon_gobj, pos, vel)

	return TRUE

## 0x8016AB84
static func wpNessPKFireProcHop(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	wp.physics.vel_air = syVectorRotateAbout3D(wp.physics.vel_air, wp.shield_collide_dir, wp.shield_collide_angle * 2)
	Wpmain.wpMainVelSetLR(weapon_gobj)

	DObjGetStruct(weapon_gobj).rotate.z *= -1.0

	return FALSE

## 0x8016ABF0
static func wpNessPKFireProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)

	wp.lifetime = WPPKFIRE_LIFETIME

	Wpmain.wpMainReflectorSetLR(wp, fp)
	Wpmain.wpMainVelSetLR(weapon_gobj)

	DObjGetStruct(weapon_gobj).rotate.z *= -1.0

	return FALSE

## 0x8016AC4C
static func wpNessPKFireProcAbsorb(weapon_gobj) -> int:
	Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

	return TRUE

## 0x8016AC78
static func wpNessPKFireMakeWeapon(fighter_gobj, pos: Vector3, vel: Vector3, angle: float):
	var weapon_gobj = Wpmanager.wpManagerMakeWeapon(fighter_gobj, dWPNessPKFireWeaponDesc, pos, (WEAPON_FLAG_COLLPROJECT | WEAPON_FLAG_PARENT_FIGHTER))
	var wp: Weapon

	if weapon_gobj == null:
		return null

	wp = wpGetStruct(weapon_gobj)

	wp.lifetime = WPPKFIRE_LIFETIME

	wp.physics.vel_air = vel

	Wpmain.wpMainVelSetLR(weapon_gobj)

	DObjGetStruct(weapon_gobj).rotate.z = (angle + F_CST_DTOR32(90.0)) * wp.lr

	return weapon_gobj
