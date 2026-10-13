## 1:1 port of src/wp/wpsamus/wpsamusbomb.c (ssb-decomp-re).
## Samus Bomb projectile (down special).
##
## WPDesc / WPAttributes are Dictionaries (see Wpmanager.wpManagerMakeWeapon): the C pair
## {p_weapon, o_attributes} is replaced by "attributes" (the WPAttributes transcribed from relocData)
## plus "visual_kind" (placeholder renderer id).
class_name Wpsamusbomb
extends Port

## wpvars.h constants used here (WPSAMUSBOMB_EXPLODE_LIFETIME, WPSAMUSBOMB_EXPLODE_SIZE, WPSAMUSBOMB_WAIT_LIFETIME, WPSAMUSBOMB_WAIT_VEL_Y, WPSAMUSBOMB_WAIT_ROTATE_SPEED_AIR, WPSAMUSBOMB_WAIT_ROTATE_SPEED_GROUND, WPSAMUSBOMB_WAIT_COLLIDE_MOD_VEL, WPSAMUSBOMB_WAIT_GRAVITY, WPSAMUSBOMB_WAIT_TVEL, WPSAMUSBOMB_WAIT_BLINK_SLOW, WPSAMUSBOMB_WAIT_BLINK_MID, WPSAMUSBOMB_WAIT_BLINK_TIMER_SLOW, WPSAMUSBOMB_WAIT_BLINK_TIMER_MID, WPSAMUSBOMB_WAIT_BLINK_TIMER_FAST) come from SSBDefs.

# // // // // // // // // // // // //
#      RELOC DATA (WPAttributes)
# // // // // // // // // // // // //

## src/relocData/217_SamusMain.c : dSamusMain_BombWeaponAttributes
## (&gFTDataSamusMain + llSamusMainBombWeaponAttributes = 0x0C).
## Model pointers (data / p_mobjsubs / anim_joints / p_matanim_joints) are render-only and left null.
const dSamusMain_BombWeaponAttributes := {
	"data": null,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 75,
	"map_coll_center": 0,
	"map_coll_bottom": -75,
	"map_coll_width": 75,
	"size": 160,
	"angle": 361,
	"knockback_scale": 65,
	"damage": 9,
	"element": nGMHitElementFire,
	"knockback_weight": 0,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 0,
	"sfx": nSYAudioFGMBurnS,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 0,
	"can_absorb": 0,
	"can_shield": 1,
	"knockback_base": 10,
}

# // // // // // // // // // // // //
#        INITIALIZED DATA
# // // // // // // // // // // // //

## C: {&gFTDataSamusMain, &llSamusMainBombWeaponAttributes}
static var dWPSamusBombWeaponDesc: Dictionary = {
	"flags": 0x00,                                     # Render flags?
	"kind": nWPKindSamusBomb,                          # Weapon Kind
	"attributes": dSamusMain_BombWeaponAttributes,
	"visual_kind": "samus_bomb",
	"transform_types": {"tk1": nGCMatrixKindTra, "tk2": 0x46, "tk3": 0},
	"proc_update": Callable(Wpsamusbomb, &"wpSamusBombProcUpdate"),
	"proc_map": Callable(Wpsamusbomb, &"wpSamusBombProcMap"),
	"proc_hit": Callable(Wpsamusbomb, &"wpSamusBombProcHit"),
	"proc_shield": Callable(Wpsamusbomb, &"wpSamusBombProcHit"),
	"proc_hop": Callable(Wpsamusbomb, &"wpSamusBombProcHop"),
	"proc_setoff": Callable(Wpsamusbomb, &"wpSamusBombProcHit"),
	"proc_reflector": Callable(Wpsamusbomb, &"wpSamusBombProcReflector"),
	"proc_absorb": Callable(Wpsamusbomb, &"wpSamusBombProcAbsorb"),
}

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x80168F00
static func wpSamusBombExplodeProcUpdate(weapon_gobj) -> int:
	if Wpmain.wpMainDecLifeCheckExpire(wpGetStruct(weapon_gobj)) != FALSE:
		return TRUE
	else:
		return FALSE

## 0x80168F2C
static func wpSamusBombExplodeInitVars(weapon_gobj) -> void:
	var wp := wpGetStruct(weapon_gobj)

	wp.lifetime = WPSAMUSBOMB_EXPLODE_LIFETIME

	wp.attack_coll.can_rehit_item = TRUE
	wp.attack_coll.can_hop = FALSE

	wp.physics.vel_air.z = 0.0
	wp.physics.vel_air.y = wp.physics.vel_air.z
	wp.physics.vel_air.x = wp.physics.vel_air.y

	wp.attack_coll.size = WPSAMUSBOMB_EXPLODE_SIZE

	DObjGetStruct(weapon_gobj).dl = null

	wp.proc_update = Callable(Wpsamusbomb, &"wpSamusBombExplodeProcUpdate")
	wp.proc_map = Callable()
	wp.proc_hit = Callable()
	wp.proc_shield = Callable()
	wp.proc_hop = Callable()
	wp.proc_setoff = Callable()
	wp.proc_reflector = Callable()

## 0x80168F98
static func wpSamusBombProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if Wpmain.wpMainDecLifeCheckExpire(wp) != FALSE:
		Efmanager.efManagerSparkleWhiteMultiExplodeMakeEffect(DObjGetStruct(weapon_gobj).translate)
		wpSamusBombExplodeInitVars(weapon_gobj)
		Snd.func_800269C0_275C0(nSYAudioFGMExplodeS)

		return FALSE
	else:
		if wp.ga == nMPKineticsAir:
			Wpmain.wpMainApplyGravityClampTVel(wp, WPSAMUSBOMB_WAIT_GRAVITY, WPSAMUSBOMB_WAIT_TVEL)
			DObjGetStruct(weapon_gobj).rotate.z -= (WPSAMUSBOMB_WAIT_ROTATE_SPEED_AIR * wp.lr)
		else:
			Wpmain.wpMainVelGroundTransferAir(weapon_gobj)
			DObjGetStruct(weapon_gobj).rotate.z -= (WPSAMUSBOMB_WAIT_ROTATE_SPEED_GROUND * wp.lr)
		wp.weapon_vars.samus_bomb.bomb_blink_timer -= 1

		if wp.weapon_vars.samus_bomb.bomb_blink_timer == 0:
			# MObj *mobj = DObjGetStruct(weapon_gobj)->mobj; (texture blink frame, render-only)
			var dobj := DObjGetStruct(weapon_gobj)

			_mobjSetPaletteID(dobj, 0.0 if (_mobjGetPaletteID(dobj) != 0) else 1.0)

			if wp.lifetime > WPSAMUSBOMB_WAIT_BLINK_SLOW:
				wp.weapon_vars.samus_bomb.bomb_blink_timer = WPSAMUSBOMB_WAIT_BLINK_TIMER_SLOW
			elif wp.lifetime > WPSAMUSBOMB_WAIT_BLINK_MID:
				wp.weapon_vars.samus_bomb.bomb_blink_timer = WPSAMUSBOMB_WAIT_BLINK_TIMER_MID
			else:
				wp.weapon_vars.samus_bomb.bomb_blink_timer = WPSAMUSBOMB_WAIT_BLINK_TIMER_FAST
	return FALSE

## 0x80169108
static func wpSamusBombProcMap(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var is_collide: int

	if wp.ga == nMPKineticsAir:
		is_collide = Wpmap.wpMapTestAllCheckFloor(weapon_gobj)

		# C passes NULL for the pos out-parameter.
		if _ret(Wpmap.wpMapCheckAllRebound(weapon_gobj, (MAP_FLAG_CEIL | MAP_FLAG_RWALL | MAP_FLAG_LWALL), WPSAMUSBOMB_WAIT_COLLIDE_MOD_VEL)) != FALSE:
			Wpmain.wpMainVelSetLR(weapon_gobj)
		if is_collide != FALSE:
			# vel = &wp->physics.vel_air;
			wp.physics.vel_air = _vec(Lbcommon.lbCommonReflect2D(wp.physics.vel_air, wp.coll_data.floor_angle), "a")
			wp.physics.vel_air = _vec(Lbcommon.lbCommonScale2D(wp.physics.vel_air, 0.6), "vec")
			Wpmain.wpMainVelSetLR(weapon_gobj)

			if Lbcommon.lbCommonMag2D(wp.physics.vel_air) < 8.0:
				Wpmap.wpMapSetGround(wp)
	elif Wpmap.wpMapTestLRWallCheckFloor(weapon_gobj) == FALSE:
		Wpmap.wpMapSetAir(wp)
	return FALSE

## 0x801691FC
static func wpSamusBombProcHit(weapon_gobj) -> int:
	Snd.func_800269C0_275C0(nSYAudioFGMExplodeS)
	Efmanager.efManagerSparkleWhiteMultiExplodeMakeEffect(DObjGetStruct(weapon_gobj).translate)
	wpSamusBombExplodeInitVars(weapon_gobj)

	return FALSE

## 0x8016923C
static func wpSamusBombProcAbsorb(weapon_gobj) -> int:
	Snd.func_800269C0_275C0(nSYAudioFGMExplodeS)
	Efmanager.efManagerSparkleWhiteMultiExplodeMakeEffect(DObjGetStruct(weapon_gobj).translate)

	return TRUE

## 0x80169274
static func wpSamusBombProcHop(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	wp.physics.vel_air = syVectorRotateAbout3D(wp.physics.vel_air, wp.shield_collide_dir, wp.shield_collide_angle * 2)
	Wpmain.wpMainVelSetLR(weapon_gobj)

	return FALSE

## 0x801692C4
static func wpSamusBombProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)

	wp.lifetime = WPSAMUSBOMB_WAIT_LIFETIME

	if wp.ga == nMPKineticsAir:
		Wpmain.wpMainReflectorSetLR(wp, fp)
		Wpmain.wpMainVelSetLR(weapon_gobj)
	else:
		wp.lr = fp.lr

	return FALSE

## 0x80169328
static func wpSamusBombMakeWeapon(fighter_gobj, pos: Vector3):
	var weapon_gobj = Wpmanager.wpManagerMakeWeapon(fighter_gobj, dWPSamusBombWeaponDesc, pos, (WEAPON_FLAG_COLLPROJECT | WEAPON_FLAG_PARENT_FIGHTER))
	var wp: Weapon

	if weapon_gobj == null:
		return null
	wp = wpGetStruct(weapon_gobj)

	wp.lifetime = WPSAMUSBOMB_WAIT_LIFETIME

	wp.weapon_vars.samus_bomb.bomb_blink_timer = WPSAMUSBOMB_WAIT_BLINK_TIMER_SLOW

	wp.physics.vel_air.y = WPSAMUSBOMB_WAIT_VEL_Y

	return weapon_gobj

# // // // // // // // // // // // //
#        PORT HELPERS
# // // // // // // // // // // // //

## sb32 return of a function that also has (pure) out-parameters: Dictionary {"ret", ...} per the
## out-parameter convention; tolerate a plain value too.
static func _ret(r) -> int:
	if r is Dictionary:
		return int(r.ret)
	return 0 if r == null else int(r)

## lbCommonReflect2D / lbCommonScale2D write their Vec3f* argument (and return the same pointer):
## accept either the written vector or a {"ret", "<param>"} Dictionary.
static func _vec(r, key: String) -> Vector3:
	if r is Dictionary:
		return r[key]
	return r

## MObj palette (texture animation frame) of the weapon model: render-only, stored as DObj metadata
## because this port's DObj has no MObj.
static func _mobjGetPaletteID(dobj: DObj) -> float:
	if dobj == null:
		return 0.0
	return dobj.get_meta(&"mobj_palette_id", 0.0)

static func _mobjSetPaletteID(dobj: DObj, palette_id: float) -> void:
	if dobj != null:
		dobj.set_meta(&"mobj_palette_id", palette_id)
