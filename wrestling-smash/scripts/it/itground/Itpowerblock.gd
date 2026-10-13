## 1:1 port of src/it/itground/itpowerblock.c (Mushroom Kingdom POW block).
##
## Port notes:
##   * ITDesc / ITStatusDesc -> Dictionaries with the C field names; p_file/o_attributes cannot be
##     dereferenced in the port, "attributes" carries the ITAttributes they point at.
##   * Both AnimJoint scripts are gameplay timers (the appear animation gates the switch to the hittable
##     Wait status, the damage animation decides when the block is destroyed and the next one is
##     scheduled), so they are transcribed word for word as AnimStreams from relocData file 155.
##   * itGetPData(ip, &llGRInishieMapPowerBlockDataStart, &llGRInishieMapPowerBlockAnimJoint)
##     = attr->data - 0x11F8 + 0x1288 = StageInishieFile3 + 0x1288 (dStageInishieFile3_AnimJoint_0x1288).
class_name Itpowerblock
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## relocData offsets (tools/relocFileDescriptions.us.txt [260] GRInishieMap; ItemAttributes relative to
## item_head = GRInishieMap, DataStart/AnimJoint relative to map_head = StageInishieFile3)
const llGRInishieMapPowerBlockItemAttributes := 0xD8
const llGRInishieMapPowerBlockDataStart := 0x11F8
const llGRInishieMapPowerBlockAnimJoint := 0x1288

## AObjEvent32 scripts, src/relocData/155_StageInishieFile3.c (aobjEvent32* macros of
## src/sys/objdef.h expanded to the raw u32 words).
## dStageInishieFile3_AnimJoint_0x13B8: appear (scale-in) animation of joint 1 (anim_joints table 0x13B0).
const dStageInishieFile3_AnimJoint_0x13B8: Array = [
	0x11C00000, 0x3BA3D70B, 0x3BA3D70B, 0x3BA3D70B, 0x0BC0000A, 0x3F866666, 0x3D87D9C5, 0x3F866666,
	0x3D87D9C5, 0x3F866666, 0x3D87D9C5, 0x11C00005, 0x3F800000, 0x3F800000, 0x3F800000, 0x07C00005,
	0x3F800000, 0x3F800000, 0x3F800000, 0x00000000,
]

## dStageInishieFile3_AnimJoint_0x1288 (llGRInishieMapPowerBlockAnimJoint): hit (squash + hide) animation.
const dStageInishieFile3_AnimJoint_0x1288: Array = [
	0x13000000, 0x3F800000, 0x0CC00000, 0x3F800000, 0x3F83B6AD, 0x3F800000, 0xBEF47B65, 0x1E000000,
	0x0BC00003, 0x40200000, 0xBC4CD925, 0x3DCCCCCD, 0xBB1ACBC9, 0x3F99999A, 0xBCCA43C4, 0x0D000005,
	0x3F800000, 0x3D3B06B2, 0x0AC00001, 0x40200000, 0x382EC33E, 0x3DCCCCCD, 0xB9CE0B91, 0x0EC00000,
	0xBD6D4C33, 0x3D2E56E4, 0x0AC00003, 0x3F800000, 0xBF83ABEA, 0x3F800000, 0x3F7FC9CC, 0x0CC00002,
	0x3E4CCCCD, 0xBBC8689D, 0x400CCCCD, 0xBB937FA5, 0x04000001, 0x0D000005, 0x3F874E43, 0xBC3A59D5,
	0x04000001, 0x0AC00002, 0x3F4CCCCE, 0x3F414DBC, 0x3FB33333, 0xBF65667B, 0x0CC00003, 0x3FB33333,
	0x3A5AB72A, 0x3ECCCCCD, 0xBB11C0B7, 0x04000002, 0x0D000003, 0x3F8CCCCD, 0xBBF06AAB, 0x04000001,
	0x0C800004, 0x3F4CCCCD, 0xBAB16255, 0x0A400002, 0x3F4CCCCD, 0xBF37094D, 0x13000006, 0x3F800000,
	0x0A400002, 0x3E99999A, 0xBAECD8DC, 0x10C00004, 0x3F19999A, 0x3DCCCCCE, 0x1E010000, 0x00000000,
]

static var sITPowerBlockDamageAnimJoint: AnimStream = AnimStream.from_u32(dStageInishieFile3_AnimJoint_0x1288, "dStageInishieFile3_AnimJoint_0x1288")

## ITAttributes at gGRCommonStruct.inishie.item_head + llGRInishieMapPowerBlockItemAttributes (0xD8):
## src/relocData/260_GRInishieMap.c dGRInishieMap_PowerBlock_ItemAttributes (US FGM enum values).
## data -> 155_StageInishieFile3.c dStageInishieFile3_DObjDesc_0x11F8;
## anim_joints -> dStageInishieFile3_mobjlink_0x13B0 = { NULL, dStageInishieFile3_AnimJoint_0x13B8 }.
static var dGRInishieMap_PowerBlock_ItemAttributes := {
	"data": [
		{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 1, "dl": "dStageInishieFile3_DL_0x10D0", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.3096979856491089, 2.022897958755493, 1.058426022529602)},
		{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
	],
	"p_mobjsubs": null,
	"anim_joints": [null, AnimStream.from_u32(dStageInishieFile3_AnimJoint_0x13B8, "dStageInishieFile3_AnimJoint_0x13B8")],
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
	"damage_coll_size": Vector3(400, 300, 300),
	"map_coll_top": 110,
	"map_coll_center": 0,
	"map_coll_bottom": -110,
	"map_coll_width": 159,
	"size": 10,
	"angle": 361,
	"knockback_scale": 100,
	"damage": 5,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 1,
	"hit_sfx": nSYAudioFGMPunchL,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 0,
	"can_shield": 1,
	"knockback_base": 20,
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

static var dITPowerBlockItemDesc := {
	"kind": nITKindPowerBlock,                                  # Item Kind
	"p_file": null,                                             # &gGRCommonStruct.inishie.item_head
	"o_attributes": llGRInishieMapPowerBlockItemAttributes,     # Offset of item attributes in file
	"attributes": dGRInishieMap_PowerBlock_ItemAttributes,
	"transform_types": {"tk1": 0x44, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                          # Hitbox Update State
	"proc_update": Callable(Itpowerblock, &"itPowerBlockCommonProcUpdate"),
	"proc_map": Callable(),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
	"visual_kind": "ground_powerblock",                         # port-only (placeholder visual id)
}

static var dITPowerBlockStatusDescs: Array = [
	# Status 0 (Neutral Wait)
	{
		"proc_update": Callable(),
		"proc_map": Callable(),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(Itpowerblock, &"itPowerBlockWaitProcDamage"),
	},
]

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itPowerBlockStatus
const nITPowerBlockStatusWait = 0
const nITPowerBlockStatusEnumCount = 1

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8017C090
static func itPowerBlockCommonProcUpdate(item_gobj) -> int:
	if DObjGetStruct(item_gobj).anim_wait == AOBJ_ANIM_NULL:
		itPowerBlockWaitSetStatus(item_gobj)

	return FALSE

## 0x8017C0D4
static func itPowerBlockWaitSetStatus(item_gobj) -> void:
	var ip: Item

	Itmain.itMainSetStatus(item_gobj, dITPowerBlockStatusDescs, nITPowerBlockStatusWait)

	ip = itGetStruct(item_gobj)
	ip.damage_coll.hitstatus = nGMHitStatusNormal

## 0x8017C110
static func itPowerBlockNDamageProcUpdate(item_gobj) -> int:
	if DObjGetStruct(item_gobj).anim_wait == AOBJ_ANIM_NULL:
		Grinishie.grInishiePowerBlockSetWait()

		return TRUE
	else:
		return FALSE

## 0x8017C15C
static func itPowerBlockWaitProcDamage(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.proc_update = Callable(Itpowerblock, &"itPowerBlockNDamageProcUpdate")
	ip.damage_coll.hitstatus = nGMHitStatusNone

	# itGetPData(ip, &llGRInishieMapPowerBlockDataStart, &llGRInishieMapPowerBlockAnimJoint)
	ObjAnim.gcAddDObjAnimJoint(DObjGetStruct(item_gobj), sITPowerBlockDamageAnimJoint, 0.0)
	ObjAnim.gcPlayAnimAll(item_gobj)
	Snd.func_800269C0_275C0(nSYAudioFGMInishiePowerBlock)
	Efmanager.efManagerQuakeMakeEffect(3)
	Grinishie.grInishiePowerBlockSetDamage()

	return FALSE

## 0x8017C1E0
static func itPowerBlockMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITPowerBlockItemDesc, pos, vel, flags)

	if item_gobj != null:
		var ip := itGetStruct(item_gobj)

		ip.damage_coll.interact_mask = GMHITCOLLISION_FLAG_FIGHTER

	return item_gobj
