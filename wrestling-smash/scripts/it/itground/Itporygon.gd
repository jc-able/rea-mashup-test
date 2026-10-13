## 1:1 port of src/it/itground/itporygon.c (Saffron City Porygon).
##
## Port notes:
##   * ITDesc -> Dictionary with the C field names; p_file/o_attributes cannot be dereferenced in the
##     port, "attributes" carries the ITAttributes they point at (Itnesspkfire / Wpmanager convention).
##   * The AnimJoint script (relocData file 159) drives the Porygon's position and its lifetime
##     (anim_wait == AOBJ_ANIM_NULL ends it), so it is transcribed word for word as an AnimStream.
##   * itGetMonsterEvent(dITPorygonItemDesc, &llGRYamabukiMapPorygonHitParties) resolves to the
##     ITMonsterEvent table transcribed below (Array of Dictionaries with the C field names).
##   * multi (u16) and event_id (u32 : 4) wrap like C.
class_name Itporygon
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## relocData offsets (tools/relocFileDescriptions.us.txt [264] GRYamabukiMap, relative to item_head)
const llGRYamabukiMapPorygonItemAttributes := 0x16C
const llGRYamabukiMapPorygonHitParties := 0x1B4

## AObjEvent32 script, src/relocData/159_StageYamabukiFile3.c dStageYamabukiFile3_AnimJoint_0x0F38
## (aobjEvent32* macros of src/sys/objdef.h expanded to the raw u32 words).
const dStageYamabukiFile3_AnimJoint_0x0F38: Array = [
	0x08180000, 0x00000000, 0x00000000, 0x16200000, 0x00000000, 0x08080008, 0xC424DDAA, 0x06100007,
	0x3F566BD9, 0x08100002, 0x421EB6FF, 0x04000001, 0x08080035, 0xC4250000, 0x04000001, 0x06100002,
	0xC1D3DDEA, 0x06100002, 0x42087467, 0x06100002, 0xC1C506DA, 0x06100002, 0x41D58C8F, 0x06100002,
	0xC1B62FC9, 0x06100002, 0x41A9075E, 0x06100002, 0xC19D7404, 0x06100002, 0x41ADF9BA, 0x06100002,
	0xC19881A9, 0x06100002, 0x419F22A9, 0x06100002, 0x3DD7526E, 0x08100058, 0x00000000, 0x0400001E,
	0x0608003A, 0x00000000, 0x00000000,
]

## ITAttributes at gGRCommonStruct.yamabuki.item_head + llGRYamabukiMapPorygonItemAttributes (0x16C):
## src/relocData/264_GRYamabukiMap.c dGRYamabukiMap_Porygon_ItemAttributes (US FGM enum values).
## data -> 159_StageYamabukiFile3.c dStageYamabukiFile3_DObjDesc_0x0EA0;
## anim_joints -> dStageYamabukiFile3_mobjlink_0x0F30 = { NULL, dStageYamabukiFile3_AnimJoint_0x0F38 }.
static var dGRYamabukiMap_Porygon_ItemAttributes := {
	"data": [
		{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 1, "dl": "dStageYamabukiFile3_DL_0x0DB0", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
	],
	"p_mobjsubs": null,
	"anim_joints": [null, AnimStream.from_u32(dStageYamabukiFile3_AnimJoint_0x0F38, "dStageYamabukiFile3_AnimJoint_0x0F38")],
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
	"map_coll_top": 300,
	"map_coll_center": 0,
	"map_coll_bottom": -300,
	"map_coll_width": 360,
	"size": 200,
	"angle": 361,
	"knockback_scale": 40,
	"damage": 16,
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
	"knockback_base": 80,
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

## ITMonsterEvent[2] at item_head + llGRYamabukiMapPorygonHitParties (0x1B4):
## src/relocData/264_GRYamabukiMap.c dGRYamabukiMap_Porygon_HitParties.
const dGRYamabukiMap_Porygon_HitParties: Array = [
	{"timer": 0, "angle": 40, "damage": 18, "size": 300, "knockback_scale": 40, "knockback_weight": 0, "knockback_base": 70, "element": 0, "can_setoff": 0, "shield_damage": 0, "fgm_id": nSYAudioFGMPunchL},
	{"timer": 8, "angle": 40, "damage": 8, "size": 300, "knockback_scale": 70, "knockback_weight": 0, "knockback_base": 40, "element": 0, "can_setoff": 0, "shield_damage": 0, "fgm_id": nSYAudioFGMPunchL},
]

static var dITPorygonItemDesc := {
	"kind": nITKindPorygon,                                     # Item Kind
	"p_file": null,                                             # &gGRCommonStruct.yamabuki.item_head
	"o_attributes": llGRYamabukiMapPorygonItemAttributes,       # Offset of item attributes in file
	"attributes": dGRYamabukiMap_Porygon_ItemAttributes,
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyR, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateNew,                          # Hitbox Update State
	"proc_update": Callable(Itporygon, &"itPorygonCommonProcUpdate"),
	"proc_map": Callable(),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
	"visual_kind": "ground_porygon",                            # port-only (placeholder visual id)
}

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80183B10
static func itPorygonCommonUpdateMonsterEvent(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var ev: Array = dGRYamabukiMap_Porygon_HitParties # itGetMonsterEvent(dITPorygonItemDesc, &llGRYamabukiMapPorygonHitParties)

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

	if ip.multi == ITPORYGON_SHAKE_STOP_WAIT:
		var pos: Vector3 = DObjGetStruct(item_gobj).translate

		pos.y = 0.0

		Efmanager.efManagerDustLightMakeEffect(pos, -1, 1.0)

## 0x80183C84
static func itPorygonCommonProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	dobj.translate.x += ip.item_vars.porygon.offset.x
	dobj.translate.y += ip.item_vars.porygon.offset.y

	itPorygonCommonUpdateMonsterEvent(item_gobj)

	if dobj.anim_wait == AOBJ_ANIM_NULL:
		Gryamabuki.grYamabukiGateSetClosedWait()

		return TRUE
	else:
		return FALSE

## 0x80183D00
static func itPorygonMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITPorygonItemDesc, pos, vel, flags)

	if item_gobj != null:
		var ip := itGetStruct(item_gobj)

		ip.item_vars.porygon.offset = pos

		ip.is_allow_knockback = TRUE

		ip.multi = 0

		ip.event_id = 0

		Snd.func_800269C0_275C0(nSYAudioVoiceYamabukiPorygon)

	return item_gobj
