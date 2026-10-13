## 1:1 port of src/wp/wpkirby/wpkirbycutter.c (ssb-decomp-re): Kirby's Final Cutter shockwave.
##
## wpKirbyCutterMakeWeapon(fighter_gobj, pos: Vector3) -> weapon_gobj or null
class_name Wpkirbycutter
extends Port

# src/wp/wpvars.h
# (const WPFINALCUTTER_LIFETIME now provided by SSBDefs: 20)
# (const WPFINALCUTTER_VEL now provided by SSBDefs: 100.0)

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## WPAttributes dKirbyMain_CutterWeaponAttributes - relocData 229_KirbyMain.c @ 0x0008
## (llKirbyMainCutterWeaponAttributes, file gFTDataKirbyMain).
##   data       = dKirbyModel_gap_0x1A2FC_sub_0x308C (328_KirbyModel.c @ 0x1D388, DObjDesc[3])
##   anim_joints = dKirbyModel_gap_0x1A2FC_sub_0x3114 (328_KirbyModel.c @ 0x1D410) -> { NULL,
##                 dKirbyModel_gap_0x1A2FC_sub_0x311C (@ 0x1D418, AObjEvent32[40]) }
static var dWPKirbyCutterWeaponAttributes: Dictionary = _wpKirbyCutterMakeAttributes()

## 0x801892A0 - WPDesc dWPKirbyCutterWeaponDesc
static var dWPKirbyCutterWeaponDesc: Dictionary = _wpKirbyCutterMakeWeaponDesc()

static func _wpKirbyCutterMakeAttributes() -> Dictionary:
	# dKirbyModel_gap_0x1A2FC_sub_0x311C: AObjEvent32 stream (words verified against the ROM file 328)
	var anim_joint := AnimStream.from_u32([
		0x15C38000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, # aobjEvent32SetValAfterBlock(AOBJ_FLAG_ROTXYZ | AOBJ_FLAG_SCAXYZ, 0)
		0x15C38001, 0x00000000, 0x00000000, 0x40490FDB, 0x3F800000, 0x3F800000, 0x3FA00000, # aobjEvent32SetValAfterBlock(AOBJ_FLAG_ROTXYZ | AOBJ_FLAG_SCAXYZ, 1)
		0x15C38001, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3FA00000, # aobjEvent32SetValAfterBlock(AOBJ_FLAG_ROTXYZ | AOBJ_FLAG_SCAXYZ, 1)
		0x15C38001, 0x00000000, 0x00000000, 0x40490FDB, 0x3F800000, 0x3F800000, 0x3F800000, # aobjEvent32SetValAfterBlock(AOBJ_FLAG_ROTXYZ | AOBJ_FLAG_SCAXYZ, 1)
		0x15C38001, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, # aobjEvent32SetValAfterBlock(AOBJ_FLAG_ROTXYZ | AOBJ_FLAG_SCAXYZ, 1)
		0x1C000000, 0x00000000,                                                             # aobjEvent32SetAnim(0x000, 0), dKirbyModel_gap_0x1A2FC_sub_0x311C
		0x00000000, 0x00000000, 0x00000000,                                                 # trailing pad
	], "dKirbyModel_gap_0x1A2FC_sub_0x311C")
	anim_joint.ptr[36] = [anim_joint, 0] # SetAnim target: the start of this same stream

	return {
		"data": [ # DObjDesc dKirbyModel_gap_0x1A2FC_sub_0x308C[3]
			{"id": 0, "translate": Vector3(0.0, 225.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
			{"id": 1, "translate": Vector3(0.0, 0.0, 225.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
			{"id": 18, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
		],
		"p_mobjsubs": null,
		"anim_joints": [null, anim_joint],
		"p_matanim_joints": null,
		"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
		"map_coll_top": 220,
		"map_coll_center": 0,
		"map_coll_bottom": -220,
		"map_coll_width": 50,
		"size": 250,
		"angle": 361,
		"knockback_scale": 50,
		"damage": 6,
		"element": nGMHitElementSlash,
		"knockback_weight": 0,
		"shield_damage": 1,
		"attack_count": 1,
		"can_setoff": 1,
		"sfx": nSYAudioFGMSlashM,
		"priority": 1,
		"can_rehit_item": 1,
		"can_rehit_fighter": 0,
		"can_hop": 0,
		"can_reflect": 1,
		"can_absorb": 1,
		"can_shield": 1,
		"unused_0x2F_b6": 0,
		"unused_0x2F_b7": 0,
		"knockback_base": 70,
	}

static func _wpKirbyCutterMakeWeaponDesc() -> Dictionary:
	return {
		"flags": 0x03,                                  # Render flags? (WEAPON_FLAG_DOBJDESC | WEAPON_FLAG_DOBJLINKS)
		"kind": nWPKindCutter,                          # Weapon Kind
		"attributes": dWPKirbyCutterWeaponAttributes,   # &gFTDataKirbyMain, &llKirbyMainCutterWeaponAttributes

		# DObj transformation struct
		"transform_types": {
			"tk1": nGCMatrixKindTraRotRpyRSca,          # Main matrix transformations
			"tk2": nGCMatrixKindNull,                   # Secondary matrix transformations?
			"tk3": 0,                                   # ???
		},

		"proc_update": Callable(Wpkirbycutter, &"wpKirbyCutterProcUpdate"),       # Proc Update
		"proc_map": Callable(Wpkirbycutter, &"wpKirbyCutterProcMap"),             # Proc Map
		"proc_hit": Callable(Wpkirbycutter, &"wpKirbyCutterProcHit"),             # Proc Hit
		"proc_shield": Callable(Wpkirbycutter, &"wpKirbyCutterProcShield"),       # Proc Shield
		"proc_hop": Callable(),                                                    # Proc Hop
		"proc_setoff": Callable(Wpkirbycutter, &"wpKirbyCutterProcSetOff"),       # Proc Set-Off
		"proc_reflector": Callable(Wpkirbycutter, &"wpKirbyCutterProcReflector"), # Proc Reflector
		"proc_absorb": Callable(Wpkirbycutter, &"wpKirbyCutterProcShield"),       # Proc Absorb

		"visual_kind": "kirby_cutter",
	}

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8016BC50
static func wpKirbyCutterProcUpdate(weapon_gobj = null) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if B(Wpmain.wpMainDecLifeCheckExpire(wp)):
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

		return TRUE

	elif wp.ga == nMPKineticsGround:
		DObjGetStruct(weapon_gobj).rotate.z = -syUtilsArcTan2(wp.coll_data.floor_angle.x, wp.coll_data.floor_angle.y)

	return FALSE

## 0x8016BCC8
static func wpKirbyCutterProcMap(weapon_gobj = null) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if wp.ga == nMPKineticsAir:
		if Wpmap.wpMapTestAllCheckFloor(weapon_gobj) == TRUE:
			Wpmap.wpMapSetGround(wp)

	elif Wpmap.wpMapTestLRWallCheckFloor(weapon_gobj) == FALSE:
		Wpmap.wpMapSetAir(wp)

		wp.physics.vel_air.x = __cosf(DObjGetStruct(weapon_gobj).rotate.z) * wp.physics.vel_ground
		wp.physics.vel_air.y = __sinf(DObjGetStruct(weapon_gobj).rotate.z) * wp.physics.vel_ground

		if DObjGetStruct(weapon_gobj).rotate.y < 0.0:
			wp.physics.vel_air.x = -wp.physics.vel_air.x
			wp.physics.vel_air.y = -wp.physics.vel_air.y

	if wp.coll_data.mask_curr & (MAP_FLAG_CEIL | MAP_FLAG_RWALL | MAP_FLAG_LWALL):
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

		return TRUE

	else:
		return FALSE

## 0x8016BDD0
static func wpKirbyCutterProcHit(weapon_gobj = null) -> int:
	Snd.func_800269C0_275C0(nSYAudioFGMExplodeS)
	Efmanager.efManagerSparkleWhiteMakeEffect(DObjGetStruct(weapon_gobj).translate)

	return FALSE

## 0x8016BE08
static func wpKirbyCutterProcShield(weapon_gobj = null) -> int:
	return FALSE

## 0x8016BE14
static func wpKirbyCutterProcSetOff(weapon_gobj = null) -> int:
	Snd.func_800269C0_275C0(nSYAudioFGMExplodeS)
	Efmanager.efManagerSparkleWhiteMakeEffect(DObjGetStruct(weapon_gobj).translate)

	return TRUE

## 0x8016BE4C
static func wpKirbyCutterProcReflector(weapon_gobj = null) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)

	wp.lifetime = WPFINALCUTTER_LIFETIME

	Wpmain.wpMainReflectorSetLR(wp, fp)
	Wpmain.wpMainVelSetModelPitch(weapon_gobj)

	return FALSE

## 0x8016BE8C
static func wpKirbyCutterMakeWeapon(fighter_gobj = null, pos = null):
	var fp := ftGetStruct(fighter_gobj)
	var weapon_gobj = Wpmanager.wpManagerMakeWeapon(fighter_gobj, dWPKirbyCutterWeaponDesc, pos, (WEAPON_FLAG_COLLPROJECT | WEAPON_FLAG_PARENT_FIGHTER))
	var wp

	if weapon_gobj == null:
		return null

	wp = wpGetStruct(weapon_gobj)

	wp.lifetime = WPFINALCUTTER_LIFETIME

	wp.physics.vel_air.x = wp.lr * WPFINALCUTTER_VEL

	# mpCollisionGetFCCommonFloor(fp->coll_data.floor_line_id, pos, NULL, NULL, &wp->coll_data.floor_angle)
	var r = Mpcollision.mpCollisionGetFCCommonFloor(fp.coll_data.floor_line_id, pos)

	if r.ret != FALSE:
		wp.coll_data.floor_angle = r.angle # written by the callee only when it returns TRUE

		wp.coll_data.floor_line_id = fp.coll_data.floor_line_id

		Wpmap.wpMapSetGround(wp)

	Wpmain.wpMainVelSetModelPitch(weapon_gobj)

	return weapon_gobj
