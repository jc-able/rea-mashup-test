## 1:1 port of src/wp/wpyoshi/wpyoshieggthrow.c (ssb-decomp-re).
## Yoshi Egg Throw projectile (held in Yoshi's hand until thrown, explodes on contact / expiry).
##
## WPDesc / WPAttributes are Dictionaries (see Wpmanager.wpManagerMakeWeapon): the C pair
## {p_weapon, o_attributes} is replaced by "attributes" (the WPAttributes transcribed from relocData)
## plus "visual_kind" (placeholder renderer id).
class_name Wpyoshieggthrow
extends Port

## wpvars.h constants used here (WPEGGTHROW_LIFETIME, WPEGGTHROW_EXPLODE_LIFETIME, WPEGGTHROW_EXPLODE_SIZE, WPEGGTHROW_TRAJECTORY_DIV, WPEGGTHROW_TRAJECTORY_SUB_FORWARD, WPEGGTHROW_TRAJECTORY_SUB_BEHIND, WPEGGTHROW_ANGLE_MUL, WPEGGTHROW_ANGLE_CLAMP, WPEGGTHROW_VEL_ADD, WPEGGTHROW_VEL_FORCE_MUL, WPEGGTHROW_ANGLE_FORCE_MUL, WPEGGTHROW_ANGLE_ADD, WPEGGTHROW_GRAVITY, WPEGGTHROW_TVEL) come from SSBDefs.

# // // // // // // // // // // // //
#      RELOC DATA (WPAttributes)
# // // // // // // // // // // // //

## src/relocData/247_YoshiMain.c : dYoshiMain_EggThrowWeaponAttributes
## (&gFTDataYoshiMain + llYoshiMainEggThrowWeaponAttributes = 0x0C).
## Model pointers (data / p_mobjsubs / anim_joints / p_matanim_joints) are render-only and left null.
const dYoshiMain_EggThrowWeaponAttributes := {
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
	"angle": 361,
	"knockback_scale": 50,
	"damage": 14,
	"element": nGMHitElementNormal,
	"knockback_weight": 0,
	"shield_damage": 6,
	"attack_count": 1,
	"can_setoff": 1,
	"sfx": nSYAudioFGMKickL,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_absorb": 0,
	"can_shield": 1,
	"knockback_base": 50,
}

# // // // // // // // // // // // //
#        INITIALIZED DATA
# // // // // // // // // // // // //

## C: {&gFTDataYoshiMain, &llYoshiMainEggThrowWeaponAttributes}
static var dWPYoshiEggThrowWeaponDesc: Dictionary = {
	"flags": 0x00,                                     # Render flags?
	"kind": nWPKindEggThrow,                           # Weapon Kind
	"attributes": dYoshiMain_EggThrowWeaponAttributes,
	"visual_kind": "yoshi_egg",
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": 0x2E, "tk3": 0},
	"proc_update": Callable(Wpyoshieggthrow, &"wpYoshiEggThrowProcUpdate"),
	"proc_map": Callable(Wpyoshieggthrow, &"wpYoshiEggThrowProcMap"),
	"proc_hit": Callable(Wpyoshieggthrow, &"wpYoshiEggThrowProcHit"),
	"proc_shield": Callable(Wpyoshieggthrow, &"wpYoshiEggThrowProcHit"),
	"proc_hop": Callable(Wpyoshieggthrow, &"wpYoshiEggThrowProcHop"),
	"proc_setoff": Callable(Wpyoshieggthrow, &"wpYoshiEggThrowProcHit"),
	"proc_reflector": Callable(Wpyoshieggthrow, &"wpYoshiEggThrowProcReflector"),
	"proc_absorb": Callable(),
}

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8016BF50
static func wpYoshiEggThrowProcDead(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if wp.weapon_vars.egg_throw.is_throw == FALSE:
		return FALSE
	else:
		return TRUE

## 0x8016BF74
static func wpYoshiEggExplodeProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if Wpmain.wpMainDecLifeCheckExpire(wp) != FALSE:
		return TRUE
	else:
		return FALSE

## 0x8016BFA0 - Egg Throw explodes from landing successfully
static func wpYoshiEggHitInitVars(weapon_gobj) -> void:
	var wp := wpGetStruct(weapon_gobj)

	wp.lifetime = WPEGGTHROW_EXPLODE_LIFETIME

	wp.attack_coll.can_hop = FALSE
	wp.attack_coll.can_reflect = FALSE

	wp.physics.vel_air.z = 0.0
	wp.physics.vel_air.y = wp.physics.vel_air.z
	wp.physics.vel_air.x = wp.physics.vel_air.y

	wp.attack_coll.size = WPEGGTHROW_EXPLODE_SIZE

	DObjGetStruct(weapon_gobj).dl = null

	wp.proc_update = Callable(Wpyoshieggthrow, &"wpYoshiEggExplodeProcUpdate")
	wp.proc_map = Callable()
	wp.proc_hit = Callable()
	wp.proc_shield = Callable()
	wp.proc_hop = Callable()
	wp.proc_setoff = Callable()
	wp.proc_reflector = Callable()

## 0x8016C00C - Egg Throw explodes from expiring
static func wpYoshiEggExpireInitVars(weapon_gobj) -> void:
	var wp := wpGetStruct(weapon_gobj)

	wp.lifetime = WPEGGTHROW_EXPLODE_LIFETIME

	wp.attack_coll.can_reflect = FALSE
	wp.attack_coll.can_shield = FALSE

	wp.physics.vel_air.z = 0.0
	wp.physics.vel_air.y = wp.physics.vel_air.z
	wp.physics.vel_air.x = wp.physics.vel_air.y

	wp.attack_coll.size = WPEGGTHROW_EXPLODE_SIZE

	DObjGetStruct(weapon_gobj).dl = null

	wp.proc_update = Callable(Wpyoshieggthrow, &"wpYoshiEggExplodeProcUpdate")
	wp.proc_map = Callable()
	wp.proc_hit = Callable()
	wp.proc_shield = Callable()
	wp.proc_hop = Callable()
	wp.proc_setoff = Callable()
	wp.proc_reflector = Callable()

## 0x8016C07C
static func wpYoshiEggThrowInitVars(weapon_gobj) -> void:
	var wp := wpGetStruct(weapon_gobj)
	var angle: float = ABS(wp.weapon_vars.egg_throw.stick_range) / WPEGGTHROW_TRAJECTORY_DIV

	if angle > 1.0:
		angle = 1.0

	angle *= WPEGGTHROW_ANGLE_MUL

	if angle < WPEGGTHROW_ANGLE_CLAMP:
		angle = 0.0

	angle *= (-1 if (wp.weapon_vars.egg_throw.stick_range < 0) else +1)

	angle = (WPEGGTHROW_TRAJECTORY_SUB_FORWARD - angle) if (wp.weapon_vars.egg_throw.lr > 0) else (WPEGGTHROW_TRAJECTORY_SUB_BEHIND - angle)

	wp.physics.vel_air.y = __sinf(angle) * ((wp.weapon_vars.egg_throw.throw_force * WPEGGTHROW_VEL_FORCE_MUL) + WPEGGTHROW_VEL_ADD)
	wp.physics.vel_air.x = __cosf(angle) * ((wp.weapon_vars.egg_throw.throw_force * WPEGGTHROW_VEL_FORCE_MUL) + WPEGGTHROW_VEL_ADD)

	wp.weapon_vars.egg_throw.angle = F_CLC_DTOR32((wp.weapon_vars.egg_throw.throw_force * WPEGGTHROW_ANGLE_FORCE_MUL) + WPEGGTHROW_ANGLE_ADD)

	DObjGetStruct(weapon_gobj).translate.z = 0.0

	wp.attack_coll.attack_state = nGMAttackStateNew

	Wpprocess.wpProcessUpdateHitPositions(weapon_gobj)

## 0x8016C218
static func wpYoshiEggThrowProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if wp.weapon_vars.egg_throw.is_spin != FALSE:
		if Wpmain.wpMainDecLifeCheckExpire(wp) != FALSE:
			Snd.func_800269C0_275C0(nSYAudioFGMYoshiEggShatter1)

			Efmanager.efManagerYoshiEggExplodeMakeEffect(DObjGetStruct(weapon_gobj).translate)
			Efmanager.efManagerEggBreakMakeEffect(DObjGetStruct(weapon_gobj).translate)

			wpYoshiEggExpireInitVars(weapon_gobj)

			return FALSE
		else:
			DObjGetStruct(weapon_gobj).rotate.z += wp.weapon_vars.egg_throw.angle
			Wpmain.wpMainApplyGravityClampTVel(wp, WPEGGTHROW_GRAVITY, WPEGGTHROW_TVEL)

			return FALSE
	elif wp.weapon_vars.egg_throw.is_throw != FALSE:
		wp.weapon_vars.egg_throw.is_spin = TRUE

		wpYoshiEggThrowInitVars(weapon_gobj)
	return FALSE

## 0x8016C2E0
static func wpYoshiEggThrowProcMap(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if (wp.weapon_vars.egg_throw.is_spin != FALSE) and (Wpmap.wpMapTestAllCheckCollEnd(weapon_gobj) != FALSE):
		Efmanager.efManagerQuakeMakeEffect(2)

		Snd.func_800269C0_275C0(nSYAudioFGMYoshiEggShatter1)

		Efmanager.efManagerYoshiEggExplodeMakeEffect(DObjGetStruct(weapon_gobj).translate)
		Efmanager.efManagerEggBreakMakeEffect(DObjGetStruct(weapon_gobj).translate)

		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

		wpYoshiEggHitInitVars(weapon_gobj)
	return FALSE

## 0x8016C374
static func wpYoshiEggThrowProcHit(weapon_gobj) -> int:
	Snd.func_800269C0_275C0(nSYAudioFGMYoshiEggShatter1)

	Efmanager.efManagerYoshiEggExplodeMakeEffect(DObjGetStruct(weapon_gobj).translate)
	Efmanager.efManagerEggBreakMakeEffect(DObjGetStruct(weapon_gobj).translate)

	wpYoshiEggHitInitVars(weapon_gobj)

	return FALSE

## 0x8016C3B4
static func wpYoshiEggThrowProcHop(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	wp.physics.vel_air = syVectorRotateAbout3D(wp.physics.vel_air, wp.shield_collide_dir, wp.shield_collide_angle * 2)

	Wpmain.wpMainVelSetModelPitch(weapon_gobj)

	return FALSE

## 0x8016C404
static func wpYoshiEggThrowProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)

	wp.lifetime = WPEGGTHROW_LIFETIME

	Wpmain.wpMainReflectorSetLR(wp, fp)
	Wpmain.wpMainVelSetModelPitch(weapon_gobj)

	return FALSE

## 0x8016C444 - display callback (render-only)
static func wpYoshiEggThrowProcDisplay(weapon_gobj) -> void:
	# gDPPipeSync(gSYTaskmanDLHeads[1]++);
	# gDPSetEnvColor(gSYTaskmanDLHeads[1]++, 0x00, 0x00, 0x00, 0x00);
	Wpdisplay.wpDisplayDLHead1(weapon_gobj)

## 0x8016C498
static func wpYoshiEggThrowMakeWeapon(fighter_gobj, pos: Vector3):
	var fp := ftGetStruct(fighter_gobj)
	var weapon_gobj = Wpmanager.wpManagerMakeWeapon(fighter_gobj, dWPYoshiEggThrowWeaponDesc, pos, WEAPON_FLAG_PARENT_FIGHTER)
	var wp: Weapon

	if weapon_gobj == null:
		return null

	wp = wpGetStruct(weapon_gobj)

	weapon_gobj.display_proc = Callable(Wpyoshieggthrow, &"wpYoshiEggThrowProcDisplay") # weapon_gobj->proc_display

	wp.weapon_vars.egg_throw.is_throw = FALSE

	wp.proc_dead = Callable(Wpyoshieggthrow, &"wpYoshiEggThrowProcDead")

	wp.lifetime = WPEGGTHROW_LIFETIME

	wp.attack_coll.attack_state = nGMAttackStateOff

	wp.is_camera_follow = TRUE

	wp.physics.vel_air.y = 0.0
	wp.physics.vel_air.x = wp.physics.vel_air.y

	wp.weapon_vars.egg_throw.is_spin = wp.weapon_vars.egg_throw.is_throw
	wp.weapon_vars.egg_throw.lr = fp.lr

	return weapon_gobj
