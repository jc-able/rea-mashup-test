## 1:1 port of src/it/itground/ithitokage.c (Saffron City Charmander and its Flamethrower weapon).
##
## Port notes:
##   * ITDesc / ITStatusDesc / WPDesc -> Dictionaries with the C field names; p_file / p_weapon +
##     o_attributes cannot be dereferenced in the port, "attributes" carries the ITAttributes /
##     WPAttributes they point at (Itnesspkfire / Wpmanager convention).
##   * The AnimJoint script (relocData file 159) drives Charmander's position, the Flamethrower window
##     (anim_frame 40..120) and its lifetime (anim_wait == AOBJ_ANIM_NULL), so it is transcribed word for
##     word as an AnimStream.
##   * dGRYamabukiMonsterAttackKind is the static var of Gryamabuki (src/gr/grcommon/gryamabuki.c).
##   * dobj->mobj->texture_id_curr (mouth texture) is render-only material state: see _itHitokageGetMObj.
##   * u16 fields (item_vars.hitokage.flags / flame_spawn_wait) wrap like C.
class_name Ithitokage
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## relocData offsets (tools/relocFileDescriptions.us.txt [264] GRYamabukiMap, relative to item_head)
const llGRYamabukiMapHitokageItemAttributes := 0x1FC
const llGRYamabukiMapHitokageFlameWeaponAttributes := 0x244

## AObjEvent32 script, src/relocData/159_StageYamabukiFile3.c dStageYamabukiFile3_AnimJoint_0x1A28
## (aobjEvent32* macros of src/sys/objdef.h expanded to the raw u32 words).
const dStageYamabukiFile3_AnimJoint_0x1A28: Array = [
	0x0C180000, 0x00000000, 0xC2B0AF56, 0x00000000, 0x403C2BE9, 0x14200000, 0x00000000, 0x0C10000F,
	0x4209FAA7, 0xBE6A7767, 0x0A08000E, 0xC414C192, 0xBF83A453, 0x0C080056, 0xC4127730, 0x3F8A4E54,
	0x04000001, 0x0A10000F, 0xC0DBCFF1, 0xC0820542, 0x0E100000, 0x40995677, 0x0A10000F, 0x42064E5A,
	0x3E6A7767, 0x0A10000F, 0x00000000, 0xC0873109, 0x0E100000, 0x4033481A, 0x1010000F, 0x42064E5A,
	0x0A10000F, 0x00000000, 0xC064EE44, 0x0E100000, 0x406E1671, 0x0C10000F, 0x42064E5A, 0x3C6B817A,
	0x0400000A, 0x0E080000, 0x42676C2C, 0x12080014, 0x00000000, 0x04000005, 0x0A10000F, 0x3EDCC962,
	0xC06D2A6E, 0x00000000,
]

## ITAttributes at gGRCommonStruct.yamabuki.item_head + llGRYamabukiMapHitokageItemAttributes (0x1FC):
## src/relocData/264_GRYamabukiMap.c dGRYamabukiMap_Hitokage_ItemAttributes (US FGM enum values).
## data -> 159_StageYamabukiFile3.c dStageYamabukiFile3_DObjDesc_0x1990;
## p_mobjsubs -> dStageYamabukiFile3_mobjlink_0x17D0 (material, render-only: not transcribed);
## anim_joints -> dStageYamabukiFile3_mobjlink_0x1A20 = { NULL, dStageYamabukiFile3_AnimJoint_0x1A28 }.
static var dGRYamabukiMap_Hitokage_ItemAttributes := {
	"data": [
		{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 1, "dl": "dStageYamabukiFile3_DL_0x18A0", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
	],
	"p_mobjsubs": null,                 # dStageYamabukiFile3_mobjlink_0x17D0 (render-only)
	"anim_joints": [null, AnimStream.from_u32(dStageYamabukiFile3_AnimJoint_0x1A28, "dStageYamabukiFile3_AnimJoint_0x1A28")],
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
	"map_coll_top": 252,
	"map_coll_center": 0,
	"map_coll_bottom": -252,
	"map_coll_width": 273,
	"size": 340,
	"angle": 361,
	"knockback_scale": 100,
	"damage": 5,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 0,
	"hit_sfx": nSYAudioFGMBurnM,
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

## WPAttributes at item_head + llGRYamabukiMapHitokageFlameWeaponAttributes (0x244):
## src/relocData/264_GRYamabukiMap.c dGRYamabukiMap_HitokageFlame_WeaponAttributes (US FGM enum values).
## No model (data NULL): the flame is drawn by the particles made in itHitokageWeaponFlameMakeWeapon.
const dGRYamabukiMap_HitokageFlame_WeaponAttributes := {
	"data": null,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 50,
	"map_coll_center": 0,
	"map_coll_bottom": -50,
	"map_coll_width": 50,
	"size": 320,
	"angle": 0,
	"knockback_scale": 100,
	"damage": 2,
	"element": 1,
	"knockback_weight": 3,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 0,
	"sfx": nSYAudioFGMBurnS,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 0,
	"can_reflect": 1,
	"can_absorb": 1,
	"can_shield": 1,
	"unused_0x2F_b6": 0,
	"unused_0x2F_b7": 0,
	"knockback_base": 0,
}

static var dITHitokageItemDesc := {
	"kind": nITKindHitokage,                                    # Item Kind
	"p_file": null,                                             # &gGRCommonStruct.yamabuki.item_head
	"o_attributes": llGRYamabukiMapHitokageItemAttributes,      # Offset of item attributes in file
	"attributes": dGRYamabukiMap_Hitokage_ItemAttributes,
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyR, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateNew,                          # Hitbox Update State
	"proc_update": Callable(Ithitokage, &"itHitokageCommonProcUpdate"),
	"proc_map": Callable(),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(Ithitokage, &"itHitokageCommonProcDamage"),
	"visual_kind": "ground_hitokage",                           # port-only (placeholder visual id)
}

static var dITHitokageStatusDescs: Array = [
	# Status 0 (Neutral Damage)
	{
		"proc_update": Callable(Ithitokage, &"itHitokageDamagedProcUpdate"),
		"proc_map": Callable(),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
	},
]

static var dITHitokageWeaponFlameWeaponDesc := {
	"flags": 0x00,                                              # Render flags?
	"kind": nWPKindHitokageFlame,                               # Weapon Kind
	"p_weapon": null,                                           # &gGRCommonStruct.yamabuki.item_head
	"o_attributes": llGRYamabukiMapHitokageFlameWeaponAttributes,
	"attributes": dGRYamabukiMap_HitokageFlame_WeaponAttributes,
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0},
	"proc_update": Callable(Ithitokage, &"itHitokageWeaponFlameProcUpdate"),
	"proc_map": Callable(Ithitokage, &"itHitokageWeaponFlameProcMap"),
	"proc_hit": Callable(Ithitokage, &"itHitokageWeaponFlameProcHit"),
	"proc_shield": Callable(Ithitokage, &"itHitokageWeaponFlameProcHit"),
	"proc_hop": Callable(),
	"proc_setoff": Callable(Ithitokage, &"itHitokageWeaponFlameProcHit"),
	"proc_reflector": Callable(Ithitokage, &"itHitokageWeaponFlameProcReflector"),
	"proc_absorb": Callable(),
	"visual_kind": "hitokage_flame",                            # port-only (Wpmanager convention)
}

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itHitokageStatus
const itHitokageStatusDamaged = 0
const itHitokageStatusEnumCount = 1

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80183DA0
static func itHitokageDamagedSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITHitokageStatusDescs, itHitokageStatusDamaged)

	itGetStruct(item_gobj).proc_dead = Callable(Ithitokage, &"itHitokageDamagedProcDead")

## 0x80183DE0
static func itHitokageCommonProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)
	var pos: Vector3

	dobj.translate.x += ip.item_vars.hitokage.offset.x
	dobj.translate.y += ip.item_vars.hitokage.offset.y

	pos = dobj.translate

	pos.x += ITHITOKAGE_FLAME_SPAWN_OFF_X

	if (
		(ip.item_vars.hitokage.flags == GRYAMABUKI_MONSTER_WEAPON_INSTANT) or
		((((ip.item_vars.hitokage.flags & GRYAMABUKI_MONSTER_WEAPON_WAIT) != 0) and (dobj.anim_frame >= ITHITOKAGE_FLAME_SPAWN_BEGIN)) and
		(dobj.anim_frame <= ITHITOKAGE_FLAME_SPAWN_END))
	):
		_itHitokageGetMObj(dobj).texture_id_curr = 1

		if ip.item_vars.hitokage.flame_spawn_wait <= 0:
			itHitokageCommonMakeFlame(item_gobj, pos)

			ip.item_vars.hitokage.flame_spawn_wait = ITHITOKAGE_FLAME_SPAWN_WAIT
		else:
			ip.item_vars.hitokage.flame_spawn_wait -= 1
	else:
		_itHitokageGetMObj(dobj).texture_id_curr = 0

	if dobj.anim_wait == AOBJ_ANIM_NULL:
		Gryamabuki.grYamabukiGateSetClosedWait()

		return TRUE

	return FALSE

## 0x80183F20
static func itHitokageDamagedProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj: DObj

	Itmain.itMainApplyGravityClampTVel(ip, ITHITOKAGE_GRAVITY, ITHITOKAGE_TVEL)

	dobj = DObjGetStruct(item_gobj)

	dobj.rotate.z -= (ITHITOKAGE_HIT_ROTATE_Z * ip.lr)

	return FALSE

## 0x80183F88
static func itHitokageDamagedProcDead(item_gobj) -> int:
	return TRUE

## 0x80183F94
static func itHitokageCommonProcDamage(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	if ip.damage_knockback >= ITHITOKAGE_NDAMAGE_KNOCKBACK_MIN:
		var angle: float = Ftcommondamage.ftCommonDamageGetKnockbackAngle(ip.damage_angle, ip.ga, ip.damage_knockback)

		ip.physics.vel_air.x = __cosf(angle) * ip.damage_knockback * -ip.damage_lr
		ip.physics.vel_air.y = __sinf(angle) * ip.damage_knockback

		ip.attack_coll.attack_state = nGMAttackStateOff
		ip.damage_coll.hitstatus = nGMHitStatusNone

		dobj.anim_wait = AOBJ_ANIM_NULL

		Gryamabuki.grYamabukiGateClearMonsterGObj()
		itHitokageDamagedSetStatus(item_gobj)

	return FALSE

## 0x80184058
static func itHitokageMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITHitokageItemDesc, pos, vel, flags)
	var dobj: DObj
	var ip: Item

	if item_gobj != null:
		ip = itGetStruct(item_gobj)
		dobj = DObjGetStruct(item_gobj)

		ip.item_vars.hitokage.flame_spawn_wait = 0
		ip.item_vars.hitokage.offset = pos

		ip.is_allow_knockback = TRUE

		ip.item_vars.hitokage.flags = syUtilsRandIntRange(GRYAMABUKI_MONSTER_WEAPON_MAX) & 0xFFFF # u16

		if (Gryamabuki.dGRYamabukiMonsterAttackKind == ip.item_vars.hitokage.flags) or ((ip.item_vars.hitokage.flags & Gryamabuki.dGRYamabukiMonsterAttackKind) != 0):
			ip.item_vars.hitokage.flags = (ip.item_vars.hitokage.flags + 1) & 0xFFFF # u16

			ip.item_vars.hitokage.flags %= GRYAMABUKI_MONSTER_WEAPON_MAX

		if ip.item_vars.hitokage.flags == GRYAMABUKI_MONSTER_WEAPON_INSTANT:
			_itHitokageGetMObj(dobj).texture_id_curr = 1

		Gryamabuki.dGRYamabukiMonsterAttackKind = ip.item_vars.hitokage.flags

		Snd.func_800269C0_275C0(nSYAudioVoiceYamabukiHitokage)

	return item_gobj

## 0x8018415C
static func itHitokageWeaponFlameProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if Wpmain.wpMainDecLifeCheckExpire(wp) != FALSE:
		return TRUE
	else:
		return FALSE

## 0x80184188
static func itHitokageWeaponFlameProcMap(weapon_gobj) -> int:
	if Wpmap.wpMapTestAllCheckCollEnd(weapon_gobj) != FALSE:
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

		return TRUE
	else:
		return FALSE

## 0x801841CC
static func itHitokageWeaponFlameProcHit(weapon_gobj) -> int:
	Snd.func_800269C0_275C0(nSYAudioFGMExplodeS)
	Efmanager.efManagerSparkleWhiteMakeEffect(DObjGetStruct(weapon_gobj).translate)

	return FALSE

## 0x80184204
static func itHitokageWeaponFlameProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)
	var translate: Vector3

	wp.lifetime = ITHITOKAGE_FLAME_LIFETIME

	Wpmain.wpMainReflectorSetLR(wp, fp)

	translate = DObjGetStruct(weapon_gobj).translate

	Lbparticle.lbParticleMakePosVel(Itmanager.gITManagerParticleBankID | LBPARTICLE_MASK_GENLINK(0), 2, translate.x, translate.y, 0.0, wp.physics.vel_air.x, wp.physics.vel_air.y, 0.0)
	Lbparticle.lbParticleMakePosVel(Itmanager.gITManagerParticleBankID | LBPARTICLE_MASK_GENLINK(0), 0, translate.x, translate.y, 0.0, wp.physics.vel_air.x, wp.physics.vel_air.y, 0.0)

	return FALSE

## 0x801842C8
static func itHitokageWeaponFlameMakeWeapon(item_gobj, pos: Vector3, vel: Vector3):
	var weapon_gobj = Wpmanager.wpManagerMakeWeapon(item_gobj, dITHitokageWeaponFlameWeaponDesc, pos, WEAPON_FLAG_PARENT_ITEM)
	var wp: Weapon

	if weapon_gobj == null:
		return null

	wp = wpGetStruct(weapon_gobj)

	wp.physics.vel_air = vel

	wp.lifetime = ITHITOKAGE_FLAME_LIFETIME

	wp.lr = -1

	Lbparticle.lbParticleMakePosVel(Itmanager.gITManagerParticleBankID | LBPARTICLE_MASK_GENLINK(0), 2, pos.x, pos.y, 0.0, wp.physics.vel_air.x, wp.physics.vel_air.y, 0.0)
	Lbparticle.lbParticleMakePosVel(Itmanager.gITManagerParticleBankID | LBPARTICLE_MASK_GENLINK(0), 0, pos.x, pos.y, 0.0, wp.physics.vel_air.x, wp.physics.vel_air.y, 0.0)

	return weapon_gobj

## 0x801843C4
static func itHitokageCommonMakeFlame(item_gobj, pos: Vector3) -> void:
	var vel: Vector3

	vel.x = __cosf(ITHITOKAGE_FLAME_SPAWN_ANGLE) * -ITHITOKAGE_FLAME_VEL_BASE
	vel.y = __sinf(ITHITOKAGE_FLAME_SPAWN_ANGLE) * ITHITOKAGE_FLAME_VEL_BASE
	vel.z = 0.0

	itHitokageWeaponFlameMakeWeapon(item_gobj, pos, vel)

	Snd.func_800269C0_275C0(nSYAudioFGMLizardonFlame)

# ---------------------------------------------------------------------------------------
# Port helpers
# ---------------------------------------------------------------------------------------

## lbdef.h LBPARTICLE_MASK_GENLINK(id): (((id) + 1) * 8), OR'ed with a particle bank ID.
static func LBPARTICLE_MASK_GENLINK(id: int) -> int:
	return (id + 1) * 8

## dobj->mobj (first MObj of the joint). Core DObj has no mobj field: MObjs are kept in the DObj's
## "mobjs" metadata (as Grdisplay does). Charmander's MObjSub (mouth texture swap) is render-only and not
## transcribed, so when the item setup attached no MObj a stand-in with the MObj fields this code uses is
## attached on first access (gcAddMObjForDObj initial values: texture ids 0, palette_id 0).
static func _itHitokageGetMObj(dobj: DObj):
	var mobjs: Array = dobj.get_meta(&"mobjs", [])

	if mobjs.is_empty():
		mobjs.append({"texture_id_curr": 0, "texture_id_next": 0, "palette_id": 0.0, "anim_wait": AOBJ_ANIM_NULL})
		dobj.set_meta(&"mobjs", mobjs)

	return mobjs[0]
