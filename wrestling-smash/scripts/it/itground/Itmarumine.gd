## 1:1 port of src/it/itground/itmarumine.c (Saffron City Electrode).
##
## Port notes:
##   * ITDesc / ITStatusDesc -> Dictionaries with the C field names; p_file/o_attributes cannot be
##     dereferenced in the port, "attributes" carries the ITAttributes they point at.
##   * The AnimJoint script (relocData file 159) drives the Electrode's position and the moment it
##     explodes (anim_wait == AOBJ_ANIM_NULL), so it is transcribed word for word as an AnimStream.
##   * itGetAttackEvent(dITMarumineItemDesc, &llGRYamabukiMapMarumineAttackEvents) resolves to the
##     ITAttackEvent table transcribed below (Array of Dictionaries with the C field names).
##   * LBParticle *pc returned by efManagerSparkleWhiteMultiExplodeMakeEffect: pc->xf->scale is
##     written through the returned object when the effect port returns one (stub returns null).
class_name Itmarumine
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## relocData offsets (tools/relocFileDescriptions.us.txt [264] GRYamabukiMap, relative to item_head)
const llGRYamabukiMapMarumineItemAttributes := 0x104
const llGRYamabukiMapMarumineAttackEvents := 0x14C

## AObjEvent32 script, src/relocData/159_StageYamabukiFile3.c dStageYamabukiFile3_AnimJoint_0x0828
## (aobjEvent32* macros of src/sys/objdef.h expanded to the raw u32 words).
const dStageYamabukiFile3_AnimJoint_0x0828: Array = [
	0x0C180000, 0x00000000, 0xC1A2FA9A, 0x00000000, 0x429FDED9, 0x06020000, 0x00000000, 0x0802001D,
	0x4183F267, 0x0C080046, 0xC41675C4, 0xBF66646C, 0x1010000A, 0x43A1694C, 0x0A100013, 0x00000000,
	0xC25109EF, 0x0E100000, 0x4215A692, 0x0802001F, 0x4196CBE4, 0x1010000B, 0x43263782, 0x0A100014,
	0x00000000, 0xC1B0DDE3, 0x0E100000, 0x416F2089, 0x1210000B, 0x42AB5A77, 0x0602000A, 0x4196CBE4,
	0x08080002, 0xC413AAD7, 0x08020032, 0x4196CBE4, 0x04000001, 0x0C100013, 0x00000000, 0xC12ABCE1,
	0x04000001, 0x06080002, 0xC4172B10, 0x06080002, 0xC41365E6, 0x06080002, 0xC417C867, 0x06080002,
	0xC4125223, 0x06080002, 0xC4172B10, 0x06080002, 0xC411C842, 0x06080002, 0xC4183ED3, 0x06080002,
	0xC4106F8E, 0x06080002, 0xC41883C3, 0x0E100000, 0x40C64CDB, 0x0C100007, 0x41F0BB6F, 0x3EA2B337,
	0x06080002, 0xC40FA0BC, 0x06080002, 0xC418C8B4, 0x06080002, 0xC40EFE04, 0x08080002, 0xC41883C3,
	0x04000001, 0x08100006, 0x4115AF96, 0x04000001, 0x06080002, 0xC40CFCBC, 0x06080002, 0xC418C8B4,
	0x08080002, 0xC40BBBEE, 0x04000001, 0x08100002, 0x41C155D2, 0x04000001, 0x08080002, 0xC41A8562,
	0x04000001, 0x08100002, 0xC0AE98F1, 0x04000001, 0x08080002, 0xC40B3B9C, 0x04000001, 0x08100002,
	0x41F0BB6F, 0x04000001, 0x08080002, 0xC41BC62F, 0x04000001, 0x08100002, 0xC13617B2, 0x04000001,
	0x08080002, 0xC40BBBEE, 0x04000001, 0x08100002, 0x4221D6A0, 0x04000001, 0x08080002, 0xC41BC62F,
	0x04000001, 0x08100002, 0xC14DCA7F, 0x04000001, 0x08080002, 0xC40BBBEE, 0x04000001, 0x08100002,
	0x4239896F, 0x04000001, 0x08080002, 0xC41BC62F, 0x04000001, 0x08100002, 0xC0428A0C, 0x04000001,
	0x08080002, 0xC411FBFE, 0x04000001, 0x06100001, 0x00000000, 0x00000000,
]

## ITAttributes at gGRCommonStruct.yamabuki.item_head + llGRYamabukiMapMarumineItemAttributes (0x104):
## src/relocData/264_GRYamabukiMap.c dGRYamabukiMap_Marumine_ItemAttributes (US FGM enum values).
## data -> 159_StageYamabukiFile3.c dStageYamabukiFile3_DObjDesc_0x0790;
## anim_joints -> dStageYamabukiFile3_mobjlink_0x0820 = { NULL, dStageYamabukiFile3_AnimJoint_0x0828 }.
static var dGRYamabukiMap_Marumine_ItemAttributes := {
	"data": [
		{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 1, "dl": "dStageYamabukiFile3_DL_0x06A0", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
	],
	"p_mobjsubs": null,
	"anim_joints": [null, AnimStream.from_u32(dStageYamabukiFile3_AnimJoint_0x0828, "dStageYamabukiFile3_AnimJoint_0x0828")],
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
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
	"map_coll_top": 225,
	"map_coll_center": 0,
	"map_coll_bottom": -225,
	"map_coll_width": 248,
	"size": 400,
	"angle": 361,
	"knockback_scale": 100,
	"damage": 10,
	"element": 1,
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
	"knockback_base": 40,
	"type": 6,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## ITAttackEvent[4] at item_head + llGRYamabukiMapMarumineAttackEvents (0x14C):
## src/relocData/264_GRYamabukiMap.c dGRYamabukiMap_Marumine_AttackEvents.
const dGRYamabukiMap_Marumine_AttackEvents: Array = [
	{"timer": 0, "angle": 361, "damage": 30, "size": 700},
	{"timer": 2, "angle": 361, "damage": 30, "size": 350},
	{"timer": 4, "angle": 361, "damage": 20, "size": 300},
	{"timer": 6, "angle": 361, "damage": 10, "size": 200},
]

static var dITMarumineItemDesc := {
	"kind": nITKindMarumine,                                    # Item Kind
	"p_file": null,                                             # &gGRCommonStruct.yamabuki.item_head
	"o_attributes": llGRYamabukiMapMarumineItemAttributes,      # Offset of item attributes in file
	"attributes": dGRYamabukiMap_Marumine_ItemAttributes,
	"transform_types": {"tk1": nGCMatrixKindTra, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                          # Hitbox Update State
	"proc_update": Callable(Itmarumine, &"itMarumineCommonProcUpdate"),
	"proc_map": Callable(),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
	"visual_kind": "ground_marumine",                           # port-only (placeholder visual id)
}

static var dITMarumineStatusDescs: Array = [
	# Status 0 (Neutral Explosion)
	{
		"proc_update": Callable(Itmarumine, &"itMarumineExplodeProcUpdate"),
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

# enum itMarumineStatus
const nITMarumineStatusExplode = 0
const nITMarumineStatusEnumCount = 1

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801837A0
static func itMarumineExplodeMakeEffectGotoSetStatus(item_gobj) -> void:
	var pc
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	ip.damage_coll.hitstatus = nGMHitStatusNone

	pc = Efmanager.efManagerSparkleWhiteMultiExplodeMakeEffect(dobj.translate)

	if pc != null:
		pc.xf.scale.x = ITMARUMINE_EXPLODE_EFFECT_SCALE
		pc.xf.scale.y = ITMARUMINE_EXPLODE_EFFECT_SCALE
		pc.xf.scale.z = ITMARUMINE_EXPLODE_EFFECT_SCALE

	Efmanager.efManagerQuakeMakeEffect(1)

	DObjGetStruct(item_gobj).flags = DOBJ_FLAG_HIDDEN

	ip.attack_coll.fgm_id = nSYAudioFGMExplodeL

	Itmain.itMainRefreshAttackColl(item_gobj)
	itMarumineExplodeSetStatus(item_gobj)

## 0x80183830
static func itMarumineExplodeUpdateAttackEvent(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var ev: Array = dGRYamabukiMap_Marumine_AttackEvents # itGetAttackEvent(dITMarumineItemDesc, &llGRYamabukiMapMarumineAttackEvents)

	if ip.multi == ev[ip.event_id].timer:
		ip.attack_coll.angle  = ev[ip.event_id].angle
		ip.attack_coll.damage = ev[ip.event_id].damage
		ip.attack_coll.size   = ev[ip.event_id].size

		ip.attack_coll.can_reflect = FALSE
		ip.attack_coll.can_shield = FALSE

		ip.attack_coll.element = nGMHitElementFire

		ip.attack_coll.can_setoff = FALSE

		ip.event_id = (ip.event_id + 1) & 0xF # u32 event_id : 4

		if ip.event_id == 4:
			ip.event_id = 3

## 0x80183914
static func itMarumineCommonProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	dobj.translate.x += ip.item_vars.marumine.offset.x
	dobj.translate.y += ip.item_vars.marumine.offset.y

	if dobj.anim_wait == AOBJ_ANIM_NULL:
		Itmain.itMainRefreshAttackColl(item_gobj)
		Itmain.itMainClearOwnerStats(item_gobj)

		ip.item_vars.marumine.offset.x = 0.0
		ip.item_vars.marumine.offset.y = 0.0

		itMarumineExplodeMakeEffectGotoSetStatus(item_gobj)
		Snd.func_800269C0_275C0(nSYAudioFGMExplodeL)

	return FALSE

## 0x801839A8
static func itMarumineExplodeProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	dobj.translate.x += ip.item_vars.marumine.offset.x
	dobj.translate.y += ip.item_vars.marumine.offset.y

	itMarumineExplodeUpdateAttackEvent(item_gobj)

	ip.multi = (ip.multi + 1) & 0xFFFF # u16

	if ip.multi == ITMARUMINE_EXPLODE_LIFETIME:
		Gryamabuki.grYamabukiGateSetClosedWait()

		return TRUE
	else:
		return FALSE

## 0x80183A20
static func itMarumineExplodeSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.multi = 0

	ip.attack_coll.throw_mul = 1.0

	ip.event_id = 0

	itMarumineExplodeUpdateAttackEvent(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITMarumineStatusDescs, nITMarumineStatusExplode)

## 0x80183A74
static func itMarumineMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITMarumineItemDesc, pos, vel, flags)

	if item_gobj != null:
		var ip := itGetStruct(item_gobj)
		var dobj := DObjGetStruct(item_gobj)

		ip.item_vars.marumine.offset = pos

		ip.is_allow_knockback = TRUE

		Objman.gcAddXObjForDObjFixed(dobj, 0x46, 0)
		Snd.func_800269C0_275C0(nSYAudioVoiceYamabukiMarumine)

	return item_gobj
