## Port of src/wp/wppikachu/wppikachuthunder.c (Pikachu Thunder bolt head + trail).
class_name Wppikachuthunder
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## WPAttributes at gFTDataPikachuMain + llPikachuMainThunderHeadWeaponAttributes (0x0C):
## src/relocData/243_PikachuMain.c dPikachuMain_ThunderHeadWeaponAttributes (checked against ROM file 243).
const dPikachuMain_ThunderHeadWeaponAttributes := {
	"data": null,                       # &dPikachuModel_ThunderTrailDObjDesc (model; not exported)
	"p_mobjsubs": null,                 # &dPikachuModel_ThunderTrailMObjSub_MObjSub
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 225, 0), Vector3(0, 0, 0)],
	"map_coll_top": 100,
	"map_coll_center": 0,
	"map_coll_bottom": -100,
	"map_coll_width": 50,
	"size": 100,
	"angle": 70,
	"knockback_scale": 50,
	"damage": 12,
	"element": nGMHitElementElectric,
	"knockback_weight": 0,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 0,
	"sfx": nSYAudioFGMShockM,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 1,
	"can_hop": 0,
	"can_reflect": 0,
	"can_absorb": 0,
	"can_shield": 0,
	"knockback_base": 80,
}

## WPAttributes at gFTDataPikachuMain + llPikachuMainThunderTrailWeaponAttributes (0x40):
## src/relocData/243_PikachuMain.c dPikachuMain_ThunderTrailWeaponAttributes (checked against ROM file 243).
const dPikachuMain_ThunderTrailWeaponAttributes := {
	"data": null,                       # &dPikachuModel_ThunderTrailDObjDesc (model; not exported)
	"p_mobjsubs": null,                 # &dPikachuModel_ThunderTrailMObjSub_MObjSub
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 240, 0), Vector3(0, -240, 0)],
	"map_coll_top": 225,
	"map_coll_center": 0,
	"map_coll_bottom": -225,
	"map_coll_width": 75,
	"size": 400,
	"angle": 70,
	"knockback_scale": 50,
	"damage": 12,
	"element": nGMHitElementElectric,
	"knockback_weight": 0,
	"shield_damage": 1,
	"attack_count": 2,
	"can_setoff": 0,
	"sfx": nSYAudioFGMShockM,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 0,
	"can_reflect": 0,
	"can_absorb": 0,
	"can_shield": 1,
	"knockback_base": 80,
}

static var dWPPikachuThunderHeadWeaponDesc := {
	"flags": 0x02,                                              # Render flags?
	"kind": nWPKindThunderHead,                                 # Weapon Kind
	# p_weapon = &gFTDataPikachuMain, o_attributes = &llPikachuMainThunderHeadWeaponAttributes
	"attributes": dPikachuMain_ThunderHeadWeaponAttributes,
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0},
	"proc_update": Callable(Wppikachuthunder, &"wpPikachuThunderHeadProcUpdate"),
	"proc_map": Callable(Wppikachuthunder, &"wpPikachuThunderHeadProcMap"),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_absorb": Callable(),
	"visual_kind": "pikachu_thunder_head",
}

static var dWPPikachuThunderTrailWeaponDesc := {
	"flags": 0x02,                                              # Render flags?
	"kind": nWPKindThunderTrail,                                # Weapon Kind
	# p_weapon = &gFTDataPikachuMain, o_attributes = &llPikachuMainThunderTrailWeaponAttributes
	"attributes": dPikachuMain_ThunderTrailWeaponAttributes,
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0},
	"proc_update": Callable(Wppikachuthunder, &"wpPikachuThunderTrailProcUpdate"),
	"proc_map": Callable(),
	"proc_hit": Callable(Wppikachuthunder, &"wpPikachuThunderTrailProcHit"),
	"proc_shield": Callable(Wppikachuthunder, &"wpPikachuThunderTrailProcHit"),
	"proc_hop": Callable(),
	"proc_setoff": Callable(Wppikachuthunder, &"wpPikachuThunderTrailProcHit"),
	"proc_reflector": Callable(),
	"proc_absorb": Callable(Wppikachuthunder, &"wpPikachuThunderTrailProcHit"),
	"visual_kind": "pikachu_thunder_trail",
}

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## DObjGetStruct(weapon_gobj)->mobj->texture_id_curr = texture_id (render-only). DObj has no MObj in this
## port yet, so the value is kept as DObj metadata for the render layer when there is no `mobj`.
static func _dobjSetMObjTextureIDCurr(weapon_gobj, texture_id: int) -> void:
	var dobj: Object = DObjGetStruct(weapon_gobj)
	var mobj = dobj.get("mobj")

	if mobj != null:
		mobj.texture_id_curr = texture_id
	else:
		dobj.set_meta(&"texture_id_curr", texture_id)

## 0x8016A640
static func wpPikachuThunderHeadSetDestroy(weapon_gobj, is_destroy: int) -> void:
	var wp := wpGetStruct(weapon_gobj)

	if not (wp.weapon_vars.thunder.thunder_state & nWPPikachuThunderStatusDestroy):
		var fp := ftGetStruct(wp.owner_gobj)

		if fp.player_num == wp.player_num: # Check number of player that spawned Thunder
			fp.passive_vars.pikachu.is_thunder_destroy |= is_destroy

## 0x8016A680
static func wpPikachuThunderHeadMakeTrailEffect(weapon_gobj, arg1: int) -> void:
	var pos: Vector3

	pos.x = DObjGetStruct(weapon_gobj).translate.x
	pos.y = DObjGetStruct(weapon_gobj).translate.y
	pos.z = 0.0

	if arg1 == 3:
		Efmanager.efManagerPikachuThunderTrailMakeEffect(pos, 10, 3)

	elif arg1 == -1:
		Efmanager.efManagerPikachuThunderTrailMakeEffect(pos, 6, 0)

	else:
		wpPikachuThunderTrailMakeWeapon(weapon_gobj, pos)

## 0x8016A700
static func wpPikachuThunderHeadProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if wp.weapon_vars.thunder.thunder_state == nWPPikachuThunderStatusCollide:
		wpPikachuThunderHeadMakeTrailEffect(weapon_gobj, 3)

		return TRUE

	elif Wpmain.wpMainDecLifeCheckExpire(wp) != FALSE:
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)
		wpPikachuThunderHeadSetDestroy(weapon_gobj, TRUE)
		wpPikachuThunderHeadMakeTrailEffect(weapon_gobj, 3)

		return TRUE

	else:
		wpPikachuThunderHeadMakeTrailEffect(weapon_gobj, 0)

	return FALSE

## 0x8016A794
static func wpPikachuThunderHeadProcMap(weapon_gobj) -> int:
	if Wpmap.wpMapTestAllCheckCollEnd(weapon_gobj) != FALSE:
		wpPikachuThunderHeadSetDestroy(weapon_gobj, TRUE)
		Efmanager.efManagerQuakeMakeEffect(1)
		Efmanager.efManagerSparkleWhiteMakeEffect(DObjGetStruct(weapon_gobj).translate)

		return TRUE

	return FALSE

## 0x8016A7E8
static func wpPikachuThunderHeadProcDead(weapon_gobj) -> int:
	wpPikachuThunderHeadSetDestroy(weapon_gobj, TRUE)

	return TRUE

## 0x8016A80C
static func wpPikachuThunderHeadMakeWeapon(fighter_gobj, pos: Vector3, vel: Vector3):
	var weapon_gobj = Wpmanager.wpManagerMakeWeapon(fighter_gobj, dWPPikachuThunderHeadWeaponDesc, pos, WEAPON_FLAG_PARENT_FIGHTER)
	var wp: Weapon

	if weapon_gobj == null:
		return null

	wp = wpGetStruct(weapon_gobj)

	wp.proc_dead = Callable(Wppikachuthunder, &"wpPikachuThunderHeadProcDead")

	wp.lifetime = WPPIKACHUTHUNDER_SPAWN_LIFETIME

	wp.physics.vel_air = vel

	wp.attack_coll.attack_state = nGMAttackStateOff
	wp.weapon_vars.thunder.thunder_state = nWPPikachuThunderStatusActive

	wp.group_id = Wpmanager.wpManagerGetGroupID()

	_dobjSetMObjTextureIDCurr(weapon_gobj, 3) # DObjGetStruct(weapon_gobj)->mobj->texture_id_curr = 3;

	DObjGetStruct(weapon_gobj).scale.x = 0.5
	DObjGetStruct(weapon_gobj).scale.y = 0.5
	DObjGetStruct(weapon_gobj).scale.z = 0.5

	return weapon_gobj

## 0x8016A8D8
static func wpPikachuThunderTrailProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if Wpmain.wpMainDecLifeCheckExpire(wp) != FALSE:
		return TRUE

	elif wp.lifetime < WPPIKACHUTHUNDER_EXPIRE:
		wpPikachuThunderHeadMakeTrailEffect(weapon_gobj, -1)

		return TRUE

	else:
		# DObjGetStruct(weapon_gobj)->mobj->texture_id_curr = syUtilsRandIntRange(...); the RNG call is game state.
		_dobjSetMObjTextureIDCurr(weapon_gobj, syUtilsRandIntRange(WPPIKACHUTHUNDER_TEXTURES_NUM - 1))

	return FALSE

## 0x8016A950
static func wpPikachuThunderTrailProcHit(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	Efmanager.efManagerImpactShockMakeEffect(DObjGetStruct(weapon_gobj).translate, wp.attack_coll.damage)

	return FALSE

## 0x8016A980
static func wpPikachuThunderTrailMakeWeapon(weapon_gobj, pos: Vector3):
	var spawn_wp := wpGetStruct(weapon_gobj)
	var trail_gobj = Wpmanager.wpManagerMakeWeapon(weapon_gobj, dWPPikachuThunderTrailWeaponDesc, pos, WEAPON_FLAG_PARENT_WEAPON)
	var trail_wp: Weapon

	if trail_gobj == null:
		return null

	trail_wp = wpGetStruct(trail_gobj)

	trail_wp.lifetime = WPPIKACHUTHUNDER_TRAIL_LIFETIME
	trail_wp.group_id = spawn_wp.group_id

	for i in spawn_wp.attack_coll.attack_records.size():
		trail_wp.attack_coll.attack_records[i].copy_from(spawn_wp.attack_coll.attack_records[i]) # struct copy

	DObjGetStruct(trail_gobj).scale.x = 0.5
	DObjGetStruct(trail_gobj).scale.y = 0.5
	DObjGetStruct(trail_gobj).scale.z = 0.5

	return trail_gobj
