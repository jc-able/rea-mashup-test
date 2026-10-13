## 1:1 port of src/wp/wpmario/wpmariofireball.c (ssb-decomp-re).
## Mario / Luigi Fireball projectile (index 0 = Mario, 1 = Luigi).
##
## WPDesc / WPAttributes are Dictionaries (see Wpmanager.wpManagerMakeWeapon): the C pair
## {p_weapon, o_attributes} is replaced by "attributes" (the WPAttributes transcribed from relocData)
## plus "visual_kind" (placeholder renderer id).
class_name Wpmariofireball
extends Port

# // // // // // // // // // // // //
#      RELOC DATA (WPAttributes)
# // // // // // // // // // // // //

## src/relocData/204_MarioSpecial1.c : dMarioSpecial1_Fireball_WeaponAttributes
## (&gFTMarioFileSpecial1 + llMarioSpecial1FireballWeaponAttributes), REGION_US values.
## Model pointers (data / p_mobjsubs / anim_joints / p_matanim_joints) are render-only and left null.
const dMarioSpecial1_Fireball_WeaponAttributes := {
	"data": null,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 50,
	"map_coll_center": 0,
	"map_coll_bottom": -50,
	"map_coll_width": 50,
	"size": 200,
	"angle": 361,
	"knockback_scale": 25,
	"damage": 7,
	"element": 1,             # nGMHitElementFire
	"knockback_weight": 0,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 1,
	"sfx": 28,                # nSYAudioFGMBurnS
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_absorb": 1,
	"can_shield": 1,
	"knockback_base": 10,
}

## src/relocData/222_LuigiSpecial1.c : dLuigiSpecial1_Fireball_WeaponAttributes
## (&gFTDataLuigiSpecial1 + llLuigiSpecial1FireballWeaponAttributes), REGION_US values.
const dLuigiSpecial1_Fireball_WeaponAttributes := {
	"data": null,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 50,
	"map_coll_center": 0,
	"map_coll_bottom": -50,
	"map_coll_width": 50,
	"size": 200,
	"angle": 361,
	"knockback_scale": 25,
	"damage": 6,
	"element": 1,             # nGMHitElementFire
	"knockback_weight": 0,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 1,
	"sfx": 28,                # nSYAudioFGMBurnS
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_absorb": 1,
	"can_shield": 1,
	"knockback_base": 10,
}

# // // // // // // // // // // // //
#        INITIALIZED DATA
# // // // // // // // // // // // //

## 0x80188E30 - wpMarioFireballAttributes[]; p_weapon/offset -> "attributes" (+ "visual_kind")
static var dWPMarioFireballWeaponAttributes: Array = [
	# Mario
	{
		"lifetime": 140,                         # Lifetime
		"vel_terminal": 55.0,                    # Terminal velocity
		"vel_min": 30.0,                         # Map collision damage
		"gravity": 1.2,                          # Gravity
		"collide_rebound": 0.85,                 # Map collision rebound velocity?
		"rotate_speed": 0.349065870047,          # F_CLC_DTOR32(20.0F) - Rotate speed
		"angle_ground": -0.0872664675117,        # F_CLC_DTOR32(-5.0F) - Grounded launch angle
		"angle_air": -0.0872664675117,           # F_CLC_DTOR32(-5.0F) - Aerial launch angle
		"vel_base": 50.0,                        # Base velocity
		"attributes": dMarioSpecial1_Fireball_WeaponAttributes, # &gFTMarioFileSpecial1 + llMarioSpecial1FireballWeaponAttributes
		"visual_kind": "mario_fireball",
		"anim_frame": 0.0                        # Animation starting frame?
	},
	# Luigi
	{
		"lifetime": 80,                          # Lifetime (REGION_US)
		"vel_terminal": 55.0,                    # Terminal velocity
		"vel_min": 30.0,                         # Map collision damage
		"gravity": 0.0,                          # Gravity
		"collide_rebound": 0.85,                 # Map collision rebound velocity?
		"rotate_speed": 0.436332315207,          # F_CLC_DTOR32(25.0F) - Rotate speed
		"angle_ground": 0.0,                     # F_CLC_DTOR32(0.0F) - Grounded launch angle
		"angle_air": 0.0,                        # F_CLC_DTOR32(0.0F) - Aerial launch angle
		"vel_base": 36.0,                        # Base velocity
		"attributes": dLuigiSpecial1_Fireball_WeaponAttributes, # &gFTDataLuigiSpecial1 + llLuigiSpecial1FireballWeaponAttributes
		"visual_kind": "luigi_fireball",
		"anim_frame": 1.0                        # Animation starting frame?
	},
]

## 0x80188E90
## C: {&gFTMarioFileMain, &llMarioMainFireballWeaponAttributes}; overwritten by
## wpMarioFireballMakeWeapon before every use (see dWPMarioFireballWeaponAttributes[index]).
static var dWPMarioFireballWeaponDesc: Dictionary = {
	"flags": 0x00,                                     # Render flags?
	"kind": nWPKindFireball,                           # Weapon Kind
	"attributes": dMarioSpecial1_Fireball_WeaponAttributes,
	"visual_kind": "mario_fireball",
	"transform_types": {"tk1": nGCMatrixKindTra, "tk2": 0x47, "tk3": 0},
	"proc_update": Callable(Wpmariofireball, &"wpMarioFireballProcUpdate"),
	"proc_map": Callable(Wpmariofireball, &"wpMarioFireballProcMap"),
	"proc_hit": Callable(Wpmariofireball, &"wpMarioFireballProcHit"),
	"proc_shield": Callable(Wpmariofireball, &"wpMarioFireballProcHit"),
	"proc_hop": Callable(Wpmariofireball, &"wpMarioFireballProcHop"),
	"proc_setoff": Callable(Wpmariofireball, &"wpMarioFireballProcHit"),
	"proc_reflector": Callable(Wpmariofireball, &"wpMarioFireballProcReflector"),
	"proc_absorb": Callable(Wpmariofireball, &"wpMarioFireballProcHit"),
}

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x80168540
static func wpMarioFireballProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var dobj: DObj

	if Wpmain.wpMainDecLifeCheckExpire(wp) != FALSE:
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

		return TRUE
	Wpmain.wpMainApplyGravityClampTVel(wp, dWPMarioFireballWeaponAttributes[wp.weapon_vars.fireball.index].gravity, dWPMarioFireballWeaponAttributes[wp.weapon_vars.fireball.index].vel_terminal)

	dobj = DObjGetStruct(weapon_gobj)

	dobj.rotate.x += dWPMarioFireballWeaponAttributes[wp.weapon_vars.fireball.index].rotate_speed

	return FALSE

## 0x801685F0
static func wpMarioFireballProcMap(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	Wpmap.wpMapTestAll(weapon_gobj)

	# C passes &pos (Vec3f) as a pure output that is never read afterwards.
	if _ret(Wpmap.wpMapCheckAllRebound(weapon_gobj, MAP_FLAG_MAIN_MASK, dWPMarioFireballWeaponAttributes[wp.weapon_vars.fireball.index].collide_rebound)) != FALSE:
		if Lbcommon.lbCommonMag2D(wp.physics.vel_air) < dWPMarioFireballWeaponAttributes[wp.weapon_vars.fireball.index].vel_min:
			Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)
			return TRUE
		Wpmain.wpMainVelSetModelPitch(weapon_gobj)

		Efmanager.efManagerFireGrindMakeEffect(DObjGetStruct(weapon_gobj).translate)
	return FALSE

## 0x801686C0
static func wpMarioFireballProcHit(weapon_gobj) -> int:
	Snd.func_800269C0_275C0(nSYAudioFGMExplodeS)
	Efmanager.efManagerSparkleWhiteMakeEffect(DObjGetStruct(weapon_gobj).translate)

	return TRUE

## 0x801686F8
static func wpMarioFireballProcHop(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	wp.physics.vel_air = syVectorRotateAbout3D(wp.physics.vel_air, wp.shield_collide_dir, wp.shield_collide_angle * 2)
	Wpmain.wpMainVelSetModelPitch(weapon_gobj)

	return FALSE

## 0x80168748
static func wpMarioFireballProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)

	wp.lifetime = dWPMarioFireballWeaponAttributes[wp.weapon_vars.fireball.index].lifetime

	Wpmain.wpMainReflectorSetLR(wp, fp)
	Wpmain.wpMainVelSetModelPitch(weapon_gobj)

	return FALSE

## 0x801687A0
static func wpMarioFireballMakeWeapon(fighter_gobj, pos: Vector3, index: int):
	var fp := ftGetStruct(fighter_gobj)
	var weapon_gobj
	var wp: Weapon
	var angle: float

	# dWPMarioFireballWeaponDesc.p_weapon / .o_attributes
	dWPMarioFireballWeaponDesc.attributes = dWPMarioFireballWeaponAttributes[index].attributes
	dWPMarioFireballWeaponDesc.visual_kind = dWPMarioFireballWeaponAttributes[index].visual_kind

	weapon_gobj = Wpmanager.wpManagerMakeWeapon(fighter_gobj, dWPMarioFireballWeaponDesc, pos, (WEAPON_FLAG_COLLPROJECT | WEAPON_FLAG_PARENT_FIGHTER))

	if weapon_gobj == null:
		return null
	wp = wpGetStruct(weapon_gobj)

	wp.weapon_vars.fireball.index = index

	wp.lifetime = dWPMarioFireballWeaponAttributes[index].lifetime

	angle = dWPMarioFireballWeaponAttributes[index].angle_air if (fp.ga == nMPKineticsAir) else dWPMarioFireballWeaponAttributes[index].angle_ground

	wp.physics.vel_air.z = 0.0

	wp.physics.vel_air.x = dWPMarioFireballWeaponAttributes[index].vel_base * __cosf(angle) * fp.lr
	wp.physics.vel_air.y = dWPMarioFireballWeaponAttributes[index].vel_base * __sinf(angle)

	# DObjGetStruct(weapon_gobj)->mobj->palette_id = anim_frame (texture frame, render-only)
	_mobjSetPaletteID(DObjGetStruct(weapon_gobj), dWPMarioFireballWeaponAttributes[index].anim_frame)

	Wpmain.wpMainVelSetModelPitch(weapon_gobj)

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

## MObj palette (texture animation frame) of the weapon model: render-only, stored as DObj metadata
## because this port's DObj has no MObj.
static func _mobjSetPaletteID(dobj: DObj, palette_id: float) -> void:
	if dobj != null:
		dobj.set_meta(&"mobj_palette_id", palette_id)
