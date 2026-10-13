## Port of src/wp/wpfox/wpfoxblaster.c (Fox Blaster shot).
class_name Wpfoxblaster
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## WPAttributes at gFTDataFoxSpecial1 + llFoxSpecial1BlasterWeaponAttributes (0x0):
## src/relocData/210_FoxSpecial1.c dFoxSpecial1_Blaster_WeaponAttributes (US values; checked
## against the ROM's file 210). data/p_mobjsubs/anim_joints/p_matanim_joints are model pointers
## (render only) and are not exported.
const dFoxSpecial1_Blaster_WeaponAttributes := {
	"data": null,                       # dFoxSpecial4_ReflectorDL_DisplayList (display list)
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 10,
	"map_coll_center": 0,
	"map_coll_bottom": -10,
	"map_coll_width": 10,
	"size": 40,
	"angle": 10,
	"knockback_scale": 100,
	"damage": 6,
	"element": 0,
	"knockback_weight": 1,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 0,
	"sfx": 2,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_absorb": 1,
	"can_shield": 1,
	"knockback_base": 0,
}

static var dWPFoxBlasterWeaponDesc := {
	"flags": 0x00,                                              # Render flags?
	"kind": nWPKindBlaster,                                     # Weapon Kind
	# p_weapon = &gFTDataFoxSpecial1, o_attributes = &llFoxSpecial1BlasterWeaponAttributes
	"attributes": dFoxSpecial1_Blaster_WeaponAttributes,
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0},
	"proc_update": Callable(Wpfoxblaster, &"wpFoxBlasterProcUpdate"),
	"proc_map": Callable(Wpfoxblaster, &"wpFoxBlasterProcMap"),
	"proc_hit": Callable(Wpfoxblaster, &"wpFoxBlasterProcHit"),
	"proc_shield": Callable(Wpfoxblaster, &"wpFoxBlasterProcHit"),
	"proc_hop": Callable(Wpfoxblaster, &"wpFoxBlasterProcHop"),
	"proc_setoff": Callable(Wpfoxblaster, &"wpFoxBlasterProcHit"),
	"proc_reflector": Callable(Wpfoxblaster, &"wpFoxBlasterProcReflector"),
	"proc_absorb": Callable(Wpfoxblaster, &"wpFoxBlasterProcHit"),
	"visual_kind": "fox_blaster",
}

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801688D0
static func wpFoxBlasterProcUpdate(weapon_gobj) -> int:
	if DObjGetStruct(weapon_gobj).scale.x < WPBLASTER_CLAMP_SCALE_X:
		DObjGetStruct(weapon_gobj).scale.x += WPBLASTER_ADD_SCALE_X

		if DObjGetStruct(weapon_gobj).scale.x > WPBLASTER_CLAMP_SCALE_X:
			DObjGetStruct(weapon_gobj).scale.x = WPBLASTER_CLAMP_SCALE_X

	return FALSE

## 0x80168924
static func wpFoxBlasterProcMap(weapon_gobj) -> int:
	if Wpmap.wpMapTestAllCheckCollEnd(weapon_gobj) != FALSE:
		Efmanager.efManagerFoxBlasterGlowMakeEffect(DObjGetStruct(weapon_gobj).translate)

		return TRUE
	else:
		return FALSE

## 0x80168964
static func wpFoxBlasterProcHit(weapon_gobj) -> int:
	Efmanager.efManagerFoxBlasterGlowMakeEffect(DObjGetStruct(weapon_gobj).translate)

	return TRUE

## 0x8016898C
static func wpFoxBlasterProcHop(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	wp.physics.vel_air = syVectorRotateAbout3D(wp.physics.vel_air, wp.shield_collide_dir, wp.shield_collide_angle * 2)

	DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x)
	DObjGetStruct(weapon_gobj).scale.x = 1.0

	Efmanager.efManagerFoxBlasterGlowMakeEffect(DObjGetStruct(weapon_gobj).translate)

	return FALSE

## 0x80168A14
static func wpFoxBlasterProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)

	Wpmain.wpMainReflectorSetLR(wp, fp)

	DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x)
	DObjGetStruct(weapon_gobj).scale.x = 1.0

	return FALSE

## 0x80168A74
static func wpFoxBlasterMakeWeapon(fighter_gobj, pos: Vector3):
	var wp: Weapon
	var weapon_gobj = Wpmanager.wpManagerMakeWeapon(fighter_gobj, dWPFoxBlasterWeaponDesc, pos, (WEAPON_FLAG_COLLPROJECT | WEAPON_FLAG_PARENT_FIGHTER))

	if weapon_gobj == null:
		return null

	wp = wpGetStruct(weapon_gobj)

	wp.physics.vel_air.x = wp.lr * WPBLASTER_VEL_X

	DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x)

	Efmanager.efManagerFoxBlasterGlowMakeEffect(pos)

	return weapon_gobj
