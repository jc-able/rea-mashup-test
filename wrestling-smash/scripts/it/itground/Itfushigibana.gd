## 1:1 port of src/it/itground/itfushigibana.c (Saffron City Venusaur and its Razor Leaf weapon).
##
## Port notes:
##   * ITDesc / WPDesc -> Dictionaries with the C field names; p_file / p_weapon + o_attributes cannot
##     be dereferenced in the port, "attributes" carries the ITAttributes / WPAttributes they point at
##     (Itnesspkfire / Wpmanager convention).
##   * The AnimJoint script (relocData file 159) drives Venusaur's position, the Razor Leaf window
##     (anim_frame 40..120) and its lifetime (anim_wait == AOBJ_ANIM_NULL), so it is transcribed word for
##     word as an AnimStream.
##   * itGetMonsterEvent(dITFushigibanaItemDesc, &llGRYamabukiMapFushigibanaHitParties) resolves to the
##     ITMonsterEvent table transcribed below (Array of Dictionaries with the C field names).
##   * dGRYamabukiMonsterAttackKind is the static var of Gryamabuki (src/gr/grcommon/gryamabuki.c).
##   * dobj->mobj->texture_id_curr (mouth texture) is render-only material state: see _itFushigibanaGetMObj.
##   * u16 fields (multi, item_vars.fushigibana.flags / razor_spawn_wait) and event_id (u32 : 4) wrap
##     like C.
class_name Itfushigibana
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## relocData offsets (tools/relocFileDescriptions.us.txt [264] GRYamabukiMap, relative to item_head)
const llGRYamabukiMapFushigibanaItemAttributes := 0x278
const llGRYamabukiMapFushigibanaHitParties := 0x2C0
const llGRYamabukiMapFushigibanaRazorWeaponAttributes := 0x308

## AObjEvent32 script, src/relocData/159_StageYamabukiFile3.c dStageYamabukiFile3_AnimJoint_0x23D8
## (aobjEvent32* macros of src/sys/objdef.h expanded to the raw u32 words).
const dStageYamabukiFile3_AnimJoint_0x23D8: Array = [
	0x0C100000, 0x42B5C212, 0x40D7AEEC, 0x06280000, 0x00000000, 0x3B160D4E, 0x0C100013, 0x00000000,
	0xC1A78CBB, 0x08200078, 0x00000000, 0x06080005, 0xC414FB4A, 0x0808000F, 0xC42F3983, 0x0400000E,
	0x0E100000, 0x00000000, 0x12100065, 0x00000000, 0x04000001, 0x0E080000, 0xBEBBE830, 0x0A080016,
	0xC418335F, 0x3F6E632C, 0x1008001B, 0xC42E034B, 0x0A080033, 0x3FB4AFE9, 0x41D3968F, 0x12100008,
	0x00000000, 0x06280008, 0x3FB4AFE9, 0x00000000, 0x00000000,
]

## ITAttributes at gGRCommonStruct.yamabuki.item_head + llGRYamabukiMapFushigibanaItemAttributes (0x278):
## src/relocData/264_GRYamabukiMap.c dGRYamabukiMap_Fushigibana_ItemAttributes (US FGM enum values).
## data -> 159_StageYamabukiFile3.c dStageYamabukiFile3_DObjDesc_0x2340;
## p_mobjsubs -> dStageYamabukiFile3_mobjlink_0x2180 (material, render-only: not transcribed);
## anim_joints -> dStageYamabukiFile3_mobjlink_0x23D0 = { NULL, dStageYamabukiFile3_AnimJoint_0x23D8 }.
static var dGRYamabukiMap_Fushigibana_ItemAttributes := {
	"data": [
		{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 1, "dl": "dStageYamabukiFile3_DL_0x2250", "translate": Vector3(0.0, 90.87904357910156, 0.0022899999748915434), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
	],
	"p_mobjsubs": null,                 # dStageYamabukiFile3_mobjlink_0x2180 (render-only)
	"anim_joints": [null, AnimStream.from_u32(dStageYamabukiFile3_AnimJoint_0x23D8, "dStageYamabukiFile3_AnimJoint_0x23D8")],
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 1,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,                        # Heavy = 0, Light = 1
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(200, 200, 200),
	"map_coll_top": 360,
	"map_coll_center": 0,
	"map_coll_bottom": -360,
	"map_coll_width": 510,
	"size": 200,
	"angle": 361,
	"knockback_scale": 100,
	"damage": 5,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 0,
	"hit_sfx": nSYAudioFGMPunchL,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 1,
	"can_hop": 0,
	"can_reflect": 0,
	"can_shield": 1,
	"knockback_base": 20,
	"type": 6,
	"hitstatus": 1,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## ITMonsterEvent[2] at item_head + llGRYamabukiMapFushigibanaHitParties (0x2C0):
## src/relocData/264_GRYamabukiMap.c dGRYamabukiMap_Fushigibana_HitParties.
const dGRYamabukiMap_Fushigibana_HitParties: Array = [
	{"timer": 0, "angle": 40, "damage": 20, "size": 300, "knockback_scale": 100, "knockback_weight": 90, "knockback_base": 0, "element": 0, "can_setoff": 0, "shield_damage": 0, "fgm_id": nSYAudioFGMPunchL},
	{"timer": 8, "angle": 361, "damage": 8, "size": 300, "knockback_scale": 70, "knockback_weight": 0, "knockback_base": 30, "element": 0, "can_setoff": 0, "shield_damage": 0, "fgm_id": nSYAudioFGMPunchL},
]

## WPAttributes at item_head + llGRYamabukiMapFushigibanaRazorWeaponAttributes (0x308):
## src/relocData/264_GRYamabukiMap.c dGRYamabukiMap_FushigibanaRazor_WeaponAttributes (US FGM enum values).
## data -> 159_StageYamabukiFile3.c dStageYamabukiFile3_DObjDesc_0x2A50 (joint 1 draws the
## dStageYamabukiFile3_DLLink_0x2A38 DObjDLLink; models are render-only, "dl" only names the C symbol).
const dGRYamabukiMap_FushigibanaRazor_WeaponAttributes := {
	"data": [
		{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 1, "dl": "dStageYamabukiFile3_DLLink_0x2A38", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
	],
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 120,
	"map_coll_center": 0,
	"map_coll_bottom": -120,
	"map_coll_width": 360,
	"size": 200,
	"angle": 90,
	"knockback_scale": 60,
	"damage": 3,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 1,
	"sfx": nSYAudioFGMKickM,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_absorb": 1,
	"can_shield": 1,
	"unused_0x2F_b6": 0,
	"unused_0x2F_b7": 0,
	"knockback_base": 30,
}

static var dITFushigibanaItemDesc := {
	"kind": nITKindFushigibana,                                 # Item Kind
	"p_file": null,                                             # &gGRCommonStruct.yamabuki.item_head
	"o_attributes": llGRYamabukiMapFushigibanaItemAttributes,   # Offset of item attributes in file
	"attributes": dGRYamabukiMap_Fushigibana_ItemAttributes,
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyR, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateNew,                          # Hitbox Update State
	"proc_update": Callable(Itfushigibana, &"itFushigibanaCommonProcUpdate"),
	"proc_map": Callable(),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
	"visual_kind": "ground_fushigibana",                        # port-only (placeholder visual id)
}

static var dITFushigibanaWeaponRazorWeaponDesc := {
	"flags": 0x03,                                              # Render flags? (WEAPON_FLAG_DOBJDESC | WEAPON_FLAG_DOBJLINKS)
	"kind": nWPKindFushigibanaRazor,                            # Weapon Kind
	"p_weapon": null,                                           # &gGRCommonStruct.yamabuki.item_head
	"o_attributes": llGRYamabukiMapFushigibanaRazorWeaponAttributes,
	"attributes": dGRYamabukiMap_FushigibanaRazor_WeaponAttributes,
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0},
	"proc_update": Callable(Itfushigibana, &"itFushigibanaWeaponRazorProcUpdate"),
	"proc_map": Callable(),
	"proc_hit": Callable(Itfushigibana, &"itFushigibanaWeaponRazorProcHit"),
	"proc_shield": Callable(Itfushigibana, &"itFushigibanaWeaponRazorProcHit"),
	"proc_hop": Callable(Itfushigibana, &"itFushigibanaWeaponRazorProcHop"),
	"proc_setoff": Callable(Itfushigibana, &"itFushigibanaWeaponRazorProcHit"),
	"proc_reflector": Callable(Itfushigibana, &"itFushigibanaWeaponRazorProcReflector"),
	"proc_absorb": Callable(Itfushigibana, &"itFushigibanaWeaponRazorProcHit"),
	"visual_kind": "fushigibana_razor",                         # port-only (Wpmanager convention)
}

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80184440
static func itFushigibanaCommonUpdateMonsterEvent(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var ev: Array = dGRYamabukiMap_Fushigibana_HitParties # itGetMonsterEvent(dITFushigibanaItemDesc, &llGRYamabukiMapFushigibanaHitParties)

	if ip.multi == ev[ip.event_id].timer:
		ip.attack_coll.angle            = ev[ip.event_id].angle
		ip.attack_coll.damage           = ev[ip.event_id].damage
		ip.attack_coll.size             = ev[ip.event_id].size
		ip.attack_coll.knockback_scale  = ev[ip.event_id].knockback_scale
		ip.attack_coll.knockback_weight = ev[ip.event_id].knockback_weight
		ip.attack_coll.knockback_base   = ev[ip.event_id].knockback_base
		ip.attack_coll.element          = ev[ip.event_id].element
		ip.attack_coll.can_setoff       = ev[ip.event_id].can_setoff
		ip.attack_coll.shield_damage    = ev[ip.event_id].shield_damage
		ip.attack_coll.fgm_id           = ev[ip.event_id].fgm_id

		ip.event_id = (ip.event_id + 1) & 0xF # u32 event_id : 4

		if ip.event_id == 2:
			ip.event_id = 1

	ip.multi = (ip.multi + 1) & 0xFFFF # u16

	if ip.multi == ITFUSHIGIBANA_RETURN_WAIT:
		var pos: Vector3 = DObjGetStruct(item_gobj).translate

		pos.y = 0.0

		Efmanager.efManagerDustLightMakeEffect(pos, -1, 1.0)

## 0x801845B4
static func itFushigibanaCommonProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)
	var pos: Vector3

	dobj.translate.x += ip.item_vars.fushigibana.offset.x
	dobj.translate.y += ip.item_vars.fushigibana.offset.y

	itFushigibanaCommonUpdateMonsterEvent(item_gobj)

	pos = dobj.translate

	pos.x += ITFUSHIGIBANA_RAZOR_SPAWN_OFF_X

	if (
		(ip.item_vars.fushigibana.flags == GRYAMABUKI_MONSTER_WEAPON_INSTANT) or
		((((ip.item_vars.fushigibana.flags & GRYAMABUKI_MONSTER_WEAPON_WAIT) != 0) and (dobj.anim_frame >= ITFUSHIGIBANA_RAZOR_SPAWN_BEGIN)) and
		(dobj.anim_frame <= ITFUSHIGIBANA_RAZOR_SPAWN_END))
	):
		_itFushigibanaGetMObj(dobj).texture_id_curr = 1

		if ip.item_vars.fushigibana.razor_spawn_wait == 0:
			itFushigibanaWeaponRazorMakeWeapon(item_gobj, pos)

			ip.item_vars.fushigibana.razor_spawn_wait = ITFUSHIGIBANA_RAZOR_SPAWN_WAIT

			Snd.func_800269C0_275C0(nSYAudioFGMMonsterShoot)

			Efmanager.efManagerDustCollideMakeEffect(pos)

		if ip.item_vars.fushigibana.razor_spawn_wait > 0:
			ip.item_vars.fushigibana.razor_spawn_wait -= 1
	else:
		_itFushigibanaGetMObj(dobj).texture_id_curr = 0

	if dobj.anim_wait == AOBJ_ANIM_NULL:
		Gryamabuki.grYamabukiGateSetClosedWait()

		return TRUE

	return FALSE

## 0x8018470C
static func itFushigibanaMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITFushigibanaItemDesc, pos, vel, flags)
	var dobj: DObj
	var ip: Item

	if item_gobj != null:
		ip = itGetStruct(item_gobj)
		dobj = DObjGetStruct(item_gobj)

		ip.event_id = 0

		ip.multi = 0

		ip.item_vars.fushigibana.razor_spawn_wait = 0
		ip.item_vars.fushigibana.offset = pos

		ip.is_allow_knockback = TRUE

		ip.item_vars.fushigibana.flags = syUtilsRandIntRange(GRYAMABUKI_MONSTER_WEAPON_MAX) & 0xFFFF # u16

		if (Gryamabuki.dGRYamabukiMonsterAttackKind == ip.item_vars.fushigibana.flags) or ((ip.item_vars.fushigibana.flags & Gryamabuki.dGRYamabukiMonsterAttackKind) != 0):
			ip.item_vars.fushigibana.flags = (ip.item_vars.fushigibana.flags + 1) & 0xFFFF # u16

			ip.item_vars.fushigibana.flags %= GRYAMABUKI_MONSTER_WEAPON_MAX

		if ip.item_vars.fushigibana.flags == GRYAMABUKI_MONSTER_WEAPON_INSTANT:
			_itFushigibanaGetMObj(dobj).texture_id_curr = 1

		Gryamabuki.dGRYamabukiMonsterAttackKind = ip.item_vars.fushigibana.flags

		Snd.func_800269C0_275C0(nSYAudioVoiceYamabukiFushigibana)

	return item_gobj

## 0x80184820
static func itFushigibanaWeaponRazorProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	wp.physics.vel_air.x += ITFUSHIGIBANA_RAZOR_ADD_VEL_X * wp.lr

	if Wpmain.wpMainDecLifeCheckExpire(wp) != FALSE:
		return TRUE
	else:
		return FALSE

## 0x80184874
static func itFushigibanaWeaponRazorProcHit(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	Efmanager.efManagerDamageSlashMakeEffect(DObjGetStruct(weapon_gobj).translate, wp.attack_coll.damage, wp.lr)

	return TRUE

## 0x801848BC
static func itFushigibanaWeaponRazorProcHop(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	wp.physics.vel_air = syVectorRotateAbout3D(wp.physics.vel_air, wp.shield_collide_dir, wp.shield_collide_angle * 2)

	DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x) + F_CLC_DTOR32(180.0)
	DObjGetStruct(weapon_gobj).scale.x = 1.0

	if wp.physics.vel_air.x > 0.0:
		wp.lr = +1
	else:
		wp.lr = -1

	return FALSE

## 0x80184970
static func itFushigibanaWeaponRazorProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)

	Wpmain.wpMainReflectorSetLR(wp, fp)

	DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x) + F_CLC_DTOR32(180.0)
	DObjGetStruct(weapon_gobj).scale.x = 1.0

	wp.lr = -wp.lr

	return FALSE

## 0x801849EC
static func itFushigibanaWeaponRazorMakeWeapon(item_gobj, pos: Vector3):
	var weapon_gobj = Wpmanager.wpManagerMakeWeapon(item_gobj, dITFushigibanaWeaponRazorWeaponDesc, pos, WEAPON_FLAG_PARENT_ITEM)
	var dobj: DObj
	var wp: Weapon

	if weapon_gobj == null:
		return null

	wp = wpGetStruct(weapon_gobj)

	wp.lr = -1

	wp.physics.vel_air.x = ITFUSHIGIBANA_RAZOR_VEL_X

	dobj = DObjGetStruct(weapon_gobj)

	dobj.translate = pos

	wp.lifetime = ITFUSHIGIBANA_RAZOR_LIFETIME

	return weapon_gobj

# ---------------------------------------------------------------------------------------
# Port helpers
# ---------------------------------------------------------------------------------------

## dobj->mobj (first MObj of the joint). Core DObj has no mobj field: MObjs are kept in the DObj's
## "mobjs" metadata (as Grdisplay does). Venusaur's MObjSub (mouth texture swap) is render-only and not
## transcribed, so when the item setup attached no MObj a stand-in with the MObj fields this code uses is
## attached on first access (gcAddMObjForDObj initial values: texture ids 0, palette_id 0).
static func _itFushigibanaGetMObj(dobj: DObj):
	var mobjs: Array = dobj.get_meta(&"mobjs", [])

	if mobjs.is_empty():
		mobjs.append({"texture_id_curr": 0, "texture_id_next": 0, "palette_id": 0.0, "anim_wait": AOBJ_ANIM_NULL})
		dobj.set_meta(&"mobjs", mobjs)

	return mobjs[0]
