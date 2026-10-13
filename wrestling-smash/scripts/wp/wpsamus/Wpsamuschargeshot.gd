## 1:1 port of src/wp/wpsamus/wpsamuschargeshot.c (ssb-decomp-re).
## Samus (and Kirby's copy) Charge Shot projectile.
##
## WPDesc / WPAttributes are Dictionaries (see Wpmanager.wpManagerMakeWeapon): the C pair
## {p_weapon, o_attributes} is replaced by "attributes" (the WPAttributes transcribed from relocData)
## plus "visual_kind" (placeholder renderer id).
class_name Wpsamuschargeshot
extends Port

## wpvars.h constants used here (WPCHARGESHOT_GFX_SIZE_DIV, WPCHARGESHOT_ROTATE_SPEED) come from SSBDefs.

# // // // // // // // // // // // //
#      RELOC DATA (WPAttributes)
# // // // // // // // // // // // //

## src/relocData/218_SamusSpecial1.c : dSamusSpecial1_ChargeShot_WeaponAttributes
## (&gFTDataSamusSpecial1 + llSamusSpecial1ChargeShotWeaponAttributes).
## Model pointers (data / p_mobjsubs / anim_joints / p_matanim_joints) are render-only and left null.
const dSamusSpecial1_ChargeShot_WeaponAttributes := {
	"data": null,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 0,
	"map_coll_center": 0,
	"map_coll_bottom": 0,
	"map_coll_width": 0,
	"size": 0,
	"angle": 361,
	"knockback_scale": 100,
	"damage": 0,
	"element": 2,             # nGMHitElementElectric
	"knockback_weight": 0,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 1,
	"sfx": 0,
	"priority": 1,
	"can_rehit_item": 0,
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

## wpSamusChargeShotAttributes[8]
static var dWPSamusChargeShotWeaponAttributes: Array = [
	# Level 0 (Uncharged)
	{"gfx_size": 150.0, "vel_x": 60.0, "damage": 3, "attack_size": 100, "coll_size": 10, "shoot_fgm_id": nSYAudioFGMSamusSpecialNShootS, "charge_fgm_id": nSYAudioFGMSamusSpecialNCharge0, "attack_fgm_id": nSYAudioFGMShockS, "priority": 1},
	# Level 1
	{"gfx_size": 230.0, "vel_x": 62.0, "damage": 6, "attack_size": 120, "coll_size": 10, "shoot_fgm_id": nSYAudioFGMSamusSpecialNShootS, "charge_fgm_id": nSYAudioFGMSamusSpecialNCharge1, "attack_fgm_id": nSYAudioFGMShockS, "priority": 1},
	# Level 2
	{"gfx_size": 280.0, "vel_x": 64.0, "damage": 9, "attack_size": 140, "coll_size": 10, "shoot_fgm_id": nSYAudioFGMSamusSpecialNShootM, "charge_fgm_id": nSYAudioFGMSamusSpecialNCharge2, "attack_fgm_id": nSYAudioFGMShockM, "priority": 1},
	# Level 3
	{"gfx_size": 340.0, "vel_x": 66.0, "damage": 12, "attack_size": 160, "coll_size": 10, "shoot_fgm_id": nSYAudioFGMSamusSpecialNShootM, "charge_fgm_id": nSYAudioFGMSamusSpecialNCharge3, "attack_fgm_id": nSYAudioFGMShockM, "priority": 1},
	# Level 4
	{"gfx_size": 410.0, "vel_x": 68.0, "damage": 15, "attack_size": 180, "coll_size": 10, "shoot_fgm_id": nSYAudioFGMSamusSpecialNShootM, "charge_fgm_id": nSYAudioFGMSamusSpecialNCharge4, "attack_fgm_id": nSYAudioFGMShockM, "priority": 1},
	# Level 5
	{"gfx_size": 490.0, "vel_x": 70.0, "damage": 18, "attack_size": 200, "coll_size": 10, "shoot_fgm_id": nSYAudioFGMSamusSpecialNShootL, "charge_fgm_id": nSYAudioFGMSamusSpecialNCharge5, "attack_fgm_id": nSYAudioFGMShockL, "priority": 1},
	# Level 6
	{"gfx_size": 600.0, "vel_x": 72.0, "damage": 21, "attack_size": 240, "coll_size": 10, "shoot_fgm_id": nSYAudioFGMSamusSpecialNShootL, "charge_fgm_id": nSYAudioFGMSamusSpecialNCharge6, "attack_fgm_id": nSYAudioFGMShockL, "priority": 1},
	# Level 7 (Full charge)
	{"gfx_size": 700.0, "vel_x": 74.0, "damage": 26, "attack_size": 260, "coll_size": 10, "shoot_fgm_id": nSYAudioFGMSamusSpecialNShootF, "charge_fgm_id": nSYAudioFGMSamusSpecialNCharge7, "attack_fgm_id": nSYAudioFGMShockL, "priority": 2},
]

## C: {&gFTDataSamusSpecial1, &llSamusSpecial1ChargeShotWeaponAttributes}
static var dWPSamusChargeShotWeaponDesc: Dictionary = {
	"flags": 0x00,                                     # Render flags?
	"kind": nWPKindChargeShot,                         # Weapon Kind
	"attributes": dSamusSpecial1_ChargeShot_WeaponAttributes,
	"visual_kind": "samus_chargeshot",
	"transform_types": {"tk1": nGCMatrixKindTra, "tk2": 0x2E, "tk3": 0},
	"proc_update": Callable(Wpsamuschargeshot, &"wpSamusChargeShotProcUpdate"),
	"proc_map": Callable(Wpsamuschargeshot, &"wpSamusChargeShotProcMap"),
	"proc_hit": Callable(Wpsamuschargeshot, &"wpSamusChargeShotProcHit"),
	"proc_shield": Callable(Wpsamuschargeshot, &"wpSamusChargeShotProcHit"),
	"proc_hop": Callable(Wpsamuschargeshot, &"wpSamusChargeShotProcHop"),
	"proc_setoff": Callable(Wpsamuschargeshot, &"wpSamusChargeShotProcHit"),
	"proc_reflector": Callable(Wpsamuschargeshot, &"wpSamusChargeShotProcReflector"),
	"proc_absorb": Callable(Wpsamuschargeshot, &"wpSamusChargeShotProcHit"),
}

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x80168B00 - Set Charge Shot's attributes upon firing
static func wpSamusChargeShotLaunch(weapon_gobj) -> void:
	var wp := wpGetStruct(weapon_gobj)
	var coll_size: float

	wp.physics.vel_air.x = dWPSamusChargeShotWeaponAttributes[wp.weapon_vars.charge_shot.charge_size].vel_x * wp.lr

	wp.attack_coll.damage = dWPSamusChargeShotWeaponAttributes[wp.weapon_vars.charge_shot.charge_size].damage
	wp.attack_coll.size = dWPSamusChargeShotWeaponAttributes[wp.weapon_vars.charge_shot.charge_size].attack_size * 0.5

	coll_size = dWPSamusChargeShotWeaponAttributes[wp.weapon_vars.charge_shot.charge_size].coll_size * 0.5

	wp.coll_data.map_coll.width = coll_size
	wp.coll_data.map_coll.top = coll_size
	wp.coll_data.map_coll.bottom = -coll_size

	Snd.func_800269C0_275C0(dWPSamusChargeShotWeaponAttributes[wp.weapon_vars.charge_shot.charge_size].shoot_fgm_id)

	wp.attack_coll.fgm_id = dWPSamusChargeShotWeaponAttributes[wp.weapon_vars.charge_shot.charge_size].attack_fgm_id
	wp.attack_coll.priority = dWPSamusChargeShotWeaponAttributes[wp.weapon_vars.charge_shot.charge_size].priority

	wp.weapon_vars.charge_shot.owner_gobj = null

## 0x80168BDC - Clear GObj pointers
static func wpSamusChargeShotProcDead(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if wp.weapon_vars.charge_shot.owner_gobj != null: # Always NULL though?
		var fp := ftGetStruct(wp.weapon_vars.charge_shot.owner_gobj)

		# C: fp->status_vars.samus.specialn.charge_gobj = NULL; for Kirby this union slot is
		# status_vars.kirby.copysamus_specialn.charge_gobj (identical layout), which the port keeps separately.
		if (fp.fkind == nFTKindKirby) or (fp.fkind == nFTKindNKirby):
			fp.status_vars.kirby.copysamus_specialn.charge_gobj = null
		else:
			fp.status_vars.samus.specialn.charge_gobj = null
	return TRUE

## 0x80168BFC
static func wpSamusChargeShotProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if wp.weapon_vars.charge_shot.is_release == FALSE:
		DObjGetStruct(weapon_gobj).scale.y = dWPSamusChargeShotWeaponAttributes[wp.weapon_vars.charge_shot.charge_size].gfx_size / WPCHARGESHOT_GFX_SIZE_DIV
		DObjGetStruct(weapon_gobj).scale.x = DObjGetStruct(weapon_gobj).scale.y

		if wp.weapon_vars.charge_shot.is_full_charge != FALSE:
			wp.weapon_vars.charge_shot.is_release = TRUE

			wpSamusChargeShotLaunch(weapon_gobj)

			wp.attack_coll.attack_state = nGMAttackStateNew

			Wpprocess.wpProcessUpdateHitPositions(weapon_gobj)
	DObjGetStruct(weapon_gobj).rotate.z -= WPCHARGESHOT_ROTATE_SPEED * wp.lr

	return FALSE

## 0x80168CC4
static func wpSamusChargeShotProcMap(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if wp.weapon_vars.charge_shot.is_release != FALSE:
		# If Charge Shot has been fired, begin checking for collision

		if Wpmap.wpMapTestAllCheckCollEnd(weapon_gobj) != FALSE:
			Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

			return TRUE
		else:
			return FALSE # Redundant return here lol
	else:
		return FALSE

## 0x80168D24
static func wpSamusChargeShotProcHit(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	Efmanager.efManagerImpactShockMakeEffect(DObjGetStruct(weapon_gobj).translate, wp.attack_coll.damage)

	return TRUE

## 0x80168D54
static func wpSamusChargeShotProcHop(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	wp.physics.vel_air = syVectorRotateAbout3D(wp.physics.vel_air, wp.shield_collide_dir, wp.shield_collide_angle * 2)
	Wpmain.wpMainVelSetLR(weapon_gobj)

	return FALSE

## 0x80168DA4
static func wpSamusChargeShotProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)

	Wpmain.wpMainReflectorSetLR(wp, fp)
	Wpmain.wpMainVelSetLR(weapon_gobj)

	return FALSE

## 0x80168DDC
static func wpSamusChargeShotMakeWeapon(fighter_gobj, pos: Vector3, charge_level: int, is_release: int):
	var fp := ftGetStruct(fighter_gobj)
	var weapon_gobj = Wpmanager.wpManagerMakeWeapon(fighter_gobj, dWPSamusChargeShotWeaponDesc, pos, (WEAPON_FLAG_COLLPROJECT | WEAPON_FLAG_PARENT_FIGHTER) if (is_release != FALSE) else WEAPON_FLAG_PARENT_FIGHTER)
	var wp: Weapon

	if weapon_gobj == null:
		return null
	wp = wpGetStruct(weapon_gobj)

	wp.weapon_vars.charge_shot.is_release = is_release
	wp.weapon_vars.charge_shot.charge_size = charge_level

	if is_release != FALSE:
		wpSamusChargeShotLaunch(weapon_gobj)
	else:
		wp.attack_coll.attack_state = nGMAttackStateOff
		wp.weapon_vars.charge_shot.is_full_charge = FALSE

		wp.weapon_vars.charge_shot.owner_gobj = fighter_gobj

		Ftparam.ftParamPlayLoopSFX(fp, dWPSamusChargeShotWeaponAttributes[wp.weapon_vars.charge_shot.charge_size].charge_fgm_id)
	DObjGetStruct(weapon_gobj).scale.y = dWPSamusChargeShotWeaponAttributes[charge_level].gfx_size / WPCHARGESHOT_GFX_SIZE_DIV
	DObjGetStruct(weapon_gobj).scale.x = DObjGetStruct(weapon_gobj).scale.y

	wp.proc_dead = Callable(Wpsamuschargeshot, &"wpSamusChargeShotProcDead")

	return weapon_gobj
