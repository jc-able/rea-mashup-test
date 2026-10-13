## 1:1 port of src/wp/wplink/wplinkspinattack.c (ssb-decomp-re).
## Link Spin Attack hitbox weapon (two hitboxes that sweep outwards and follow Link).
##
## WPDesc / WPAttributes are Dictionaries (see Wpmanager.wpManagerMakeWeapon): the C pair
## {p_weapon, o_attributes} is replaced by "attributes" (the WPAttributes transcribed from relocData)
## plus "visual_kind" (placeholder renderer id).
class_name Wplinkspinattack
extends Port

## wpvars.h constants used here (WPSPINATTACK_LIFETIME, WPSPINATTACK_EXTEND_POS_COUNT, WPSPINATTACK_VEL, WPSPINATTACK_VEL_CLAMP, WPSPINATTACK_OFF_X, WPSPINATTACK_OFF_Y, WPSPINATTACK_ANGLE) come from SSBDefs.

# // // // // // // // // // // // //
#      RELOC DATA (WPAttributes)
# // // // // // // // // // // // //

## src/relocData/225_LinkMain.c : dLinkMain_SpinAttackWeaponAttributes
## (&gFTDataLinkMain + llLinkMainSpinAttackWeaponAttributes = 0x0C).
## Model pointers (data / p_mobjsubs / anim_joints / p_matanim_joints) are render-only and left null
## (the model's AnimJoint only animates the child slash joint, not the root DObj used for hit offsets).
const dLinkMain_SpinAttackWeaponAttributes := {
	"data": null,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 150,
	"map_coll_center": 0,
	"map_coll_bottom": -150,
	"map_coll_width": 150,
	"size": 400,
	"angle": 30,
	"knockback_scale": 50,
	"damage": 5,
	"element": nGMHitElementNormal,
	"knockback_weight": 0,
	"shield_damage": 1,
	"attack_count": 2,
	"can_setoff": 1,
	"sfx": nSYAudioFGMKickM,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 0,
	"can_reflect": 0,
	"can_absorb": 0,
	"can_shield": 1,
	"knockback_base": 30,
}

# // // // // // // // // // // // //
#        INITIALIZED DATA
# // // // // // // // // // // // //

## C: {&gFTDataLinkMain, &llLinkMainSpinAttackWeaponAttributes}
static var dWPLinkSpinAttackWeaponDesc: Dictionary = {
	"flags": 0x03,                                     # Render flags? (DOBJDESC | DOBJLINKS)
	"kind": nWPKindSpinAttack,                         # Weapon Kind
	"attributes": dLinkMain_SpinAttackWeaponAttributes,
	"visual_kind": "link_spinattack",
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0},
	"proc_update": Callable(Wplinkspinattack, &"wpLinkSpinAttackProcUpdate"),
	"proc_map": Callable(Wplinkspinattack, &"wpLinkSpinAttackProcMap"),
	"proc_hit": Callable(Wplinkspinattack, &"wpLinkSpinAttackProcHit"),
	"proc_shield": Callable(Wplinkspinattack, &"wpLinkSpinAttackProcHit"),
	"proc_hop": Callable(),
	"proc_setoff": Callable(Wplinkspinattack, &"wpLinkSpinAttackProcHit"),
	"proc_reflector": Callable(),
	"proc_absorb": Callable(),
}

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8016C9A0 - Unused
static func func_ovl3_8016C9A0() -> void:
	return

## 0x8016C9A8
static func wpLinkSpinAttackProcDead(weapon_gobj) -> int:
	return FALSE

## 0x8016C9B4
static func wpLinkSpinAttackProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var sqrt_vel: float
	var mod_vel: float

	if wp.weapon_vars.spin_attack.is_destroy != FALSE:
		return TRUE

	sqrt_vel = sqrtf(SQUARE(wp.weapon_vars.spin_attack.vel.x) + SQUARE(wp.weapon_vars.spin_attack.vel.y))

	if sqrt_vel > 0.0:
		if sqrt_vel < WPSPINATTACK_VEL_CLAMP:
			mod_vel = 0.0
		else:
			mod_vel = sqrt_vel - WPSPINATTACK_VEL_CLAMP

		wp.weapon_vars.spin_attack.vel.x = (wp.weapon_vars.spin_attack.vel.x * mod_vel) / sqrt_vel
		wp.weapon_vars.spin_attack.vel.y = (wp.weapon_vars.spin_attack.vel.y * mod_vel) / sqrt_vel

		wp.attack_coll.offsets[0].x += wp.weapon_vars.spin_attack.vel.x # TO DO: this might not be an array at all, loops don't match when indexed with iterator
		wp.attack_coll.offsets[0].y += wp.weapon_vars.spin_attack.vel.y
		wp.attack_coll.offsets[1].x -= wp.weapon_vars.spin_attack.vel.x
		wp.attack_coll.offsets[1].y += wp.weapon_vars.spin_attack.vel.y
	return FALSE

## 0x8016CA9C
static func wpLinkSpinAttackProcMap(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var pos_x: float
	var pos_y: float
	var index: int = (wp.weapon_vars.spin_attack.pos_index + 1) % WPSPINATTACK_EXTEND_POS_COUNT

	pos_x = wp.weapon_vars.spin_attack.pos_x[index]
	pos_y = wp.weapon_vars.spin_attack.pos_y[index]

	pos_y += WPSPINATTACK_OFF_Y

	wp.physics.vel_air.x = pos_x - DObjGetStruct(weapon_gobj).translate.x
	wp.physics.vel_air.y = pos_y - DObjGetStruct(weapon_gobj).translate.y

	return FALSE

## 0x8016CB10
static func wpLinkSpinAttackProcHit(weapon_gobj) -> int:
	return FALSE

## 0x8016CB1C
static func wpLinkSpinAttackMakeWeapon(fighter_gobj, pos: Vector3):
	var fp := ftGetStruct(fighter_gobj)
	var weapon_gobj
	var wp: Weapon
	var offset: Vector3 = pos

	offset.y += WPSPINATTACK_OFF_Y

	weapon_gobj = Wpmanager.wpManagerMakeWeapon(fighter_gobj, dWPLinkSpinAttackWeaponDesc, offset, WEAPON_FLAG_PARENT_FIGHTER)

	if weapon_gobj == null:
		return null
	wp = wpGetStruct(weapon_gobj)

	wp.attack_coll.offsets[0].x = WPSPINATTACK_OFF_X
	wp.attack_coll.offsets[0].y = 0.0
	wp.attack_coll.offsets[1].x = -WPSPINATTACK_OFF_X
	wp.attack_coll.offsets[1].y = 0.0

	wp.lr = fp.lr

	wp.lifetime = WPSPINATTACK_LIFETIME

	wp.proc_dead = Callable(Wplinkspinattack, &"wpLinkSpinAttackProcDead")

	# bzero(&wp->weapon_vars.spin_attack, sizeof(wp->weapon_vars));
	_wpLinkSpinAttackClearVars(wp)

	wp.weapon_vars.spin_attack.vel.x = __cosf(WPSPINATTACK_ANGLE) * WPSPINATTACK_VEL
	wp.weapon_vars.spin_attack.vel.y = __sinf(WPSPINATTACK_ANGLE) * WPSPINATTACK_VEL

	wp.physics.vel_air.z = 0.0
	wp.physics.vel_air.y = wp.physics.vel_air.z
	wp.physics.vel_air.x = wp.physics.vel_air.y

	Wpprocess.wpProcessUpdateHitPositions(weapon_gobj)

	return weapon_gobj

# // // // // // // // // // // // //
#        PORT HELPERS
# // // // // // // // // // // // //

## bzero of wpLinkWeaponVarsSpinAttack {s16 pos_x[4]; s16 pos_y[4]; Vec2f vel; sb8 is_destroy; s8 pos_index;}
## (the generated Dictionary sizes the arrays from an unresolved macro, so they are rebuilt here).
static func _wpLinkSpinAttackClearVars(wp: Weapon) -> void:
	var vars: Dictionary = wp.weapon_vars.spin_attack
	var pos_x: Array = []
	var pos_y: Array = []

	pos_x.resize(WPSPINATTACK_EXTEND_POS_COUNT)
	pos_x.fill(0)
	pos_y.resize(WPSPINATTACK_EXTEND_POS_COUNT)
	pos_y.fill(0)

	vars.pos_x = pos_x
	vars.pos_y = pos_y
	vars.vel = Vector2.ZERO
	vars.is_destroy = 0
	vars.pos_index = 0
