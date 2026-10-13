## 1:1 port of src/it/itground/itglucky.c (Saffron City Chansey).
##
## Port notes:
##   * ITDesc / ITStatusDesc -> Dictionaries with the C field names; p_file/o_attributes cannot be
##     dereferenced in the port, "attributes" carries the ITAttributes they point at.
##   * The AnimJoint script (relocData file 159) drives Chansey's position, the egg-spawn window
##     (anim_frame 80..85) and its lifetime (anim_wait == AOBJ_ANIM_NULL), so it is transcribed word
##     for word as an AnimStream.
##   * RNG call order of the egg spawn is kept (vel.x first, then vel.y).
##   * u16 fields (multi, item_vars.glucky.egg_spawn_count) wrap like C.
class_name Itglucky
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## relocData offset (tools/relocFileDescriptions.us.txt [264] GRYamabukiMap, relative to item_head)
const llGRYamabukiMapGLuckyItemAttributes := 0xBC

## AObjEvent32 script, src/relocData/159_StageYamabukiFile3.c dStageYamabukiFile3_AnimJoint_0x03F8
## (aobjEvent32* macros of src/sys/objdef.h expanded to the raw u32 words).
const dStageYamabukiFile3_AnimJoint_0x03F8: Array = [
	0x08080000, 0x00000000, 0x16300000, 0x00000000, 0x00000000, 0x06080012, 0xC3E10C79, 0x06080035,
	0xC3E5F502, 0x06080059, 0x3FBC46A1, 0x00000000,
]

## ITAttributes at gGRCommonStruct.yamabuki.item_head + llGRYamabukiMapGLuckyItemAttributes (0xBC):
## src/relocData/264_GRYamabukiMap.c dGRYamabukiMap_GLucky_ItemAttributes (US FGM enum values).
## data -> 159_StageYamabukiFile3.c dStageYamabukiFile3_DObjDesc_0x0360;
## anim_joints -> dStageYamabukiFile3_mobjlink_0x03F0 = { NULL, dStageYamabukiFile3_AnimJoint_0x03F8 }.
static var dGRYamabukiMap_GLucky_ItemAttributes := {
	"data": [
		{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 1, "dl": "dStageYamabukiFile3_DL_0x0270", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
	],
	"p_mobjsubs": null,
	"anim_joints": [null, AnimStream.from_u32(dStageYamabukiFile3_AnimJoint_0x03F8, "dStageYamabukiFile3_AnimJoint_0x03F8")],
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
	"damage_coll_size": Vector3(390, 360, 360),
	"map_coll_top": 180,
	"map_coll_center": 0,
	"map_coll_bottom": -180,
	"map_coll_width": 195,
	"size": 300,
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
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 0,
	"can_reflect": 0,
	"can_shield": 0,
	"knockback_base": 20,
	"type": 4,
	"hitstatus": 1,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

static var dITGLuckyItemDesc := {
	"kind": nITKindGLucky,                                      # Item Kind
	"p_file": null,                                             # &gGRCommonStruct.yamabuki.item_head
	"o_attributes": llGRYamabukiMapGLuckyItemAttributes,        # Offset of item attributes in file
	"attributes": dGRYamabukiMap_GLucky_ItemAttributes,
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyR, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateNew,                          # Hitbox Update State
	"proc_update": Callable(Itglucky, &"itGLuckyCommonProcUpdate"),
	"proc_map": Callable(),
	"proc_hit": Callable(Itglucky, &"itGLuckyCommonProcHit"),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(Itglucky, &"itGLuckyCommonProcDamage"),
	"visual_kind": "ground_glucky",                             # port-only (placeholder visual id)
}

static var dITGLuckyStatusDescs: Array = [
	# Status 0 (Neutral Damage)
	{
		"proc_update": Callable(Itglucky, &"itGLuckyDamagedProcUpdate"),
		"proc_map": Callable(),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
	},
]

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itGLuckyStatus
const nITGLuckyStatusDamaged = 0
const nITGLuckyStatusEnumCount = 1

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8017C240
static func itGLuckyDamagedSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITGLuckyStatusDescs, nITGLuckyStatusDamaged)

	itGetStruct(item_gobj).proc_dead = Callable(Itglucky, &"itGLuckyDamagedProcDead")

## 0x8017C280
static func itGLuckyCommonUpdateEggSpawn(lucky_gobj) -> void:
	var lucky_ip := itGetStruct(lucky_gobj)
	var egg_ip: Item
	var dobj := DObjGetStruct(lucky_gobj)
	var egg_gobj
	var pos: Vector3
	var vel: Vector3

	if lucky_ip.multi == 0:
		if lucky_ip.item_vars.glucky.egg_spawn_count != 0:
			# ITEM_TOGGLE_MASK_KIND(nITKindEgg) = (1 << nITKindEgg)
			if ((G.gSCManagerBattleState.item_toggles & (1 << nITKindEgg)) != 0) and (G.gSCManagerBattleState.item_appearance_rate != nSCBattleItemSwitchNone): # Return to this when 0x8 is mapped
				pos = dobj.translate

				pos.x -= ITGLUCKY_EGG_SPAWN_OFF_X
				pos.y += ITGLUCKY_EGG_SPAWN_OFF_Y

				vel.x = -((syUtilsRandFloat() * ITGLUCKY_EGG_SPAWN_MUL) + ITGLUCKY_EGG_SPAWN_ADD_X)
				vel.y = (syUtilsRandFloat() * ITGLUCKY_EGG_SPAWN_MUL) + ITGLUCKY_EGG_SPAWN_ADD_Y
				vel.z = 0.0

				egg_gobj = Itmanager.itManagerMakeItemSetupCommon(lucky_gobj, nITKindEgg, pos, vel, (ITEM_FLAG_COLLPROJECT | ITEM_FLAG_PARENT_ITEM))

				if egg_gobj != null:
					egg_ip = itGetStruct(egg_gobj)

					Snd.func_800269C0_275C0(nSYAudioFGMKirbySpecialLwStart) # Bruh lol

					lucky_ip.multi = 10
					lucky_ip.item_vars.glucky.egg_spawn_count = (lucky_ip.item_vars.glucky.egg_spawn_count - 1) & 0xFFFF # u16

					Efmanager.efManagerDustLightMakeEffect(pos, egg_ip.lr, 1.0)
			else:
				lucky_ip.multi = 10
				lucky_ip.item_vars.glucky.egg_spawn_count = (lucky_ip.item_vars.glucky.egg_spawn_count - 1) & 0xFFFF # u16

	if lucky_ip.item_vars.glucky.egg_spawn_count != 0:
		if lucky_ip.multi > 0:
			lucky_ip.multi -= 1

## 0x8017C400
static func itGLuckyCommonProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	dobj.translate.x += ip.item_vars.glucky.pos.x
	dobj.translate.y += ip.item_vars.glucky.pos.y

	if (dobj.anim_frame >= ITGLUCKY_EGG_SPAWN_BEGIN) and (dobj.anim_frame <= ITGLUCKY_EGG_SPAWN_END):
		itGLuckyCommonUpdateEggSpawn(item_gobj)

	if dobj.anim_wait == AOBJ_ANIM_NULL:
		Gryamabuki.grYamabukiGateSetClosedWait()

		return TRUE
	else:
		return FALSE

## 0x8017C4AC
static func itGLuckyCommonProcHit(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.attack_coll.attack_state = nGMAttackStateOff

	return FALSE

## 0x8017C4BC
static func itGLuckyDamagedProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj: DObj

	Itmain.itMainApplyGravityClampTVel(ip, ITGLUCKY_GRAVITY, ITGLUCKY_TVEL)

	dobj = DObjGetStruct(item_gobj)

	dobj.rotate.z -= ITGLUCKY_HIT_ROTATE_Z * ip.lr

	return FALSE

## 0x8017C524
static func itGLuckyDamagedProcDead(item_gobj) -> int:
	return TRUE

## 0x8017C530
static func itGLuckyCommonProcDamage(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	if ip.damage_knockback >= ITGLUCKY_NDAMAGE_KNOCKBACK_MIN:
		var angle: float = Ftcommondamage.ftCommonDamageGetKnockbackAngle(ip.damage_angle, ip.ga, ip.damage_knockback)

		ip.physics.vel_air.x = (__cosf(angle) * ip.damage_knockback * -ip.damage_lr)
		ip.physics.vel_air.y = (__sinf(angle) * ip.damage_knockback)

		ip.attack_coll.attack_state = nGMAttackStateOff
		ip.damage_coll.hitstatus = nGMHitStatusNone

		dobj.anim_wait = AOBJ_ANIM_NULL

		Gryamabuki.grYamabukiGateClearMonsterGObj()
		itGLuckyDamagedSetStatus(item_gobj)

	return FALSE

## 0x8017C5F4
static func itGLuckyMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITGLuckyItemDesc, pos, vel, flags)

	if item_gobj != null:
		var ip := itGetStruct(item_gobj)

		ip.attack_coll.interact_mask = GMHITCOLLISION_FLAG_FIGHTER

		ip.item_vars.glucky.pos = pos

		ip.is_allow_knockback = TRUE

		ip.multi = 0

		ip.item_vars.glucky.egg_spawn_count = ITGLUCKY_EGG_SPAWN_COUNT

		Snd.func_800269C0_275C0(nSYAudioVoiceYamabukiLucky)

	return item_gobj
