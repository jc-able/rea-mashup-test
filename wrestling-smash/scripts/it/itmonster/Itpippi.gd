## 1:1 port of src/it/itmonster/itpippi.c (ssb-decomp-re): Poké Ball Clefairy. Clefairy's
## "Metronome" picks one of the other Poké Ball Pokémon's attack statuses at random and runs it on
## its own ITStruct (dITPippiStatusProcList).
##
## Make function (dITManagerProcMakeList entry, called through itManagerMakeItemKind):
##   Itpippi.itPippiMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int) -> item_gobj or null
##
## Conventions shared by every src/it/itmonster/*.c port (Itiwark ... Itmew):
##   * ITDesc / ITStatusDesc / WPDesc are Dictionaries with the C field names (same layout as
##     Itnesspkfire / Wpmanager): ITDesc = {kind, attributes, transform_types {tk1, tk2, tk3},
##     attack_state, proc_update .. proc_damage (Callable, Callable() == NULL), visual_kind};
##     WPDesc = {flags, kind, attributes, transform_types, proc_update .. proc_absorb, visual_kind}.
##   * ITAttributes / WPAttributes (src/relocData/251_ITCommonData.c) are the item core's ROM-verified
##     ITCommonData tables (Itmanager), referenced by linker symbol: ITDesc.o_attributes =
##     "llITCommonData<X>ItemAttributes" (resolved by itManagerMakeItem) and, for weapons,
##     Itmanager.itManagerGetCommonData("llITCommonData<X>WeaponAttributes") on first use (every
##     monster entry was also re-decoded from ROM file 251 and matches). Their `data` field is the
##     DObjDesc tree of src/relocData/86_ITCommonObject.c; the item core builds it and ejects the
##     dummy root (lbCommonEjectTreeDObj), so `dobj->child` exists exactly where the C uses it.
##   * AnimJoint (AObjEvent32) scripts are transcribed word-for-word from 86_ITCommonObject.c
##     (cross-checked against ROM file 86) into AnimStream objects; SetAnim self-loops are patched
##     through AnimStream.ptr. Gameplay depends on three of them: the Beedrill AnimJoint (its
##     anim_frame reaching ITSPEAR_SWARM_CALL_WAIT starts the swarm call), the Hydro Pump
##     AnimJoint (hitbox X offset) and the Smog AnimJoint (hitbox size).
##   * itGetMonsterAnimNode(ip, &llITCommonData<X>DataStart) (item.h) is
##     (attr->data - <X>DataStart) + llITCommonDataMonsterAnimBankStart. Every Pokémon's
##     attr->data points at its own <X>DataStart (US offsets: Wark 0xA140, Kabigon 0xB158,
##     Tosakinto 0xB708, Mew 0xBCC0, Nyars 0xC130, Lizardon 0xD5C0, Spear 0xDF38, Kamex 0xEA60,
##     Lucky 0x10000, Starmie 0x112A0, Sawamura 0x11F40, Dogas 0x12820, Pippi 0x13598), so the
##     node is always ITCommonObject + 0x13624: Itpippi.dITCommonObjectMonsterAnimBank below.
##   * itGetPData(ip, &<X>DataStart, &<X><Block>) is only evaluated when ip->kind == <X> (so
##     attr->data == <X>DataStart) and therefore resolves to ITCommonObject + <Block>; the ports
##     reference that block directly (offset given in the comment).
##   * MObjs (dobj->mobj: material animations, texture ids) and display lists are render-only;
##     the gcAddMObjMatAnimJoint / gcDrawDObjTreeForGObj / gDP* calls are kept where C makes them
##     (stubs / comments). No MObjs exist for items/weapons in this port (gcAddMObjAll is a stub),
##     so dobj->mobj resolves to the first DObj meta "mobjs" entry (Grdisplay convention) or null.
##   * ip->multi and every u16 item_vars field wrap like the C u16 (& 0xFFFF).
class_name Itpippi
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# llITCommonData* linker offsets used by this file (tools/relocFileDescriptions.us.txt, file 251/86)
const llITCommonDataPippiDataStart = 0x13598
const llITCommonDataMonsterAnimBankStart = 0x13624

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## AObjEvent32 script dITCommonObject_Pippi_Item_data_remainder_sub_0x8
## (src/relocData/86_ITCommonObject.c @ 0x13624 == llITCommonDataMonsterAnimBankStart): the shared
## "appear" scale AnimJoint every Poké Ball Pokémon attaches through itGetMonsterAnimNode().
## 47 words, identical to ROM file 86.
static var dITCommonObjectMonsterAnimBank: AnimStream = _itPippiMakeMonsterAnimBank()

static func _itPippiMakeMonsterAnimBank() -> AnimStream:
	return AnimStream.from_u32([
		0x0CC00000, 0x3ECB5FEB, 0x3C46F69E, 0x3ED1DF43, 0x3F4A6EA4, # [0] aobjEvent32SetValRate(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 0): 0.397216171, 0.0121437591, 0.409906477, 0.790750742
		0x07000000, 0x3727C5AC, # [5] aobjEvent32SetValBlock(AOBJ_FLAG_SCAZ, 0): 9.99999975e-06
		0x09000005, 0x3F800000, # [7] aobjEvent32SetVal(AOBJ_FLAG_SCAZ, 5): 1
		0x0C400008, 0x3FA3BC8B, 0x3EC4A971, # [9] aobjEvent32SetValRate(AOBJ_FLAG_SCAX, 8): 1.27919137, 0.384105235
		0x10800004, 0x3FFEB354, # [12] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAY, 4): 1.98984766
		0x0C800004, 0x3F89BF2D, 0xBF078A89, # [14] aobjEvent32SetValRate(AOBJ_FLAG_SCAY, 4): 1.07614672, -0.529457629
		0x04000001, # [17] aobjEvent32Wait(1)
		0x09000005, 0x3F800000, # [18] aobjEvent32SetVal(AOBJ_FLAG_SCAZ, 5): 1
		0x04000003, # [20] aobjEvent32Wait(3)
		0x0C400002, 0x4004A121, 0xBABB38B9, # [21] aobjEvent32SetValRate(AOBJ_FLAG_SCAX, 2): 2.07233453, -0.00142838724
		0x10800002, 0x3E53D395, # [24] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAY, 2): 0.206861809
		0x0900000B, 0x3F800000, # [26] aobjEvent32SetVal(AOBJ_FLAG_SCAZ, 11): 1
		0x0AC00003, 0x3FB32AFB, 0xBF0034D0, 0x3F29E90C, 0x3EC6D60F, # [28] aobjEvent32SetValRateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 3): 1.39974916, -0.500805855, 0.663712263, 0.388351887
		0x0C400002, 0x3F3BC73D, 0xBD6E3D39, # [33] aobjEvent32SetValRate(AOBJ_FLAG_SCAX, 2): 0.733508885, -0.0581638552
		0x10800002, 0x3F9FACF4, # [36] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAY, 2): 1.24746561
		0x0AC00004, 0x3F867F81, 0x3B850433, 0x3F6C824D, 0xBC5198EB, # [38] aobjEvent32SetValRateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 4): 1.05076611, 0.00405933848, 0.923863232, -0.0127928061
		0x10C00002, 0x3F800000, 0x3F800000, # [43] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 2): 1, 1
		0x00000000, # [46] aobjEvent32End()
	], "dITCommonObject_Pippi_Item_data_remainder_sub_0x8")

## 0x8018B370
static var dITPippiStatusProcList: Array = [
	Callable(Itiwark, &"itIwarkAttackSetStatus"),
	Callable(Itkabigon, &"itKabigonJumpSetStatus"),
	Callable(Ittosakinto, &"itTosakintoAppearSetStatus"),
	Callable(Itnyars, &"itNyarsAttackSetStatus"),
	Callable(Itlizardon, &"itLizardonFallSetStatus"),
	Callable(Itspear, &"itSpearFlySetStatus"),
	Callable(Itkamex, &"itKamexAppearSetStatus"),
	Callable(Itmlucky, &"itMLuckyAppearSetStatus"),
	Callable(Itstarmie, &"itStarmieNFollowSetStatus"),
	Callable(Itsawamura, &"itSawamuraFallSetStatus"),
	Callable(Itdogas, &"itDogasAttackSetStatus"),
	Callable(Itmew, &"itMewFlySetStatus"),
]

## 0x8018B3A0
static var dITPippiItemDesc := {
	"kind": nITKindPippi,                                       # Item Kind
	"o_attributes": "llITCommonDataPippiItemAttributes",        # &gITManagerCommonData, &llITCommonDataPippiItemAttributes (item core table)

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindTraRotRpyR,                         # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"attack_state": nGMAttackStateNew,                          # Hitbox Update State
	"proc_update": Callable(Itpippi, &"itPippiCommonProcUpdate"),   # Proc Update
	"proc_map": Callable(Itpippi, &"itPippiCommonProcMap"),         # Proc Map
	"proc_hit": Callable(),                                     # Proc Hit
	"proc_shield": Callable(),                                  # Proc Shield
	"proc_hop": Callable(),                                     # Proc Hop
	"proc_setoff": Callable(),                                  # Proc Set-Off
	"proc_reflector": Callable(),                               # Proc Reflector
	"proc_damage": Callable(),                                  # Proc Damage

	"visual_kind": "monster_pippi",
}

## 0x8018B3D4 - why (#if !defined(DAIRANTOU_OPT0); never referenced)
static var dITPippiStatusDesc := {
	"proc_update": Callable(),
	"proc_map": Callable(),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
}

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80183210
static func itPippiCommonSelectMonster(item_gobj) -> void:
	var kind: int
	var index: int
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	index = syUtilsRandIntRange(dITPippiStatusProcList.size())

	kind = index + nITKindMBallMonsterStart

	if (kind == nITKindSpear) or (kind == nITKindKamex):
		if syUtilsRandIntRange(2) == 0:
			dobj.rotate.y = F_CST_DTOR32(180.0)

			ip.lr = +1

		else:
			ip.lr = -1

	if (kind == nITKindPippi) or (kind == nITKindTosakinto) or (kind == nITKindMLucky):
		ip.attack_coll.attack_state = nGMAttackStateOff

	if kind == nITKindSawamura:
		ip.multi = ITSAWAMURA_KICK_WAIT

	if (kind == nITKindSawamura) or (kind == nITKindStarmie):
		item_gobj.display_proc = Callable(Itpippi, &"itPippiCommonMoveDLProcDisplay") # item_gobj->proc_display

		# item_gobj->dl_link_priority: itManagerMakeItem registers every item display with GOBJ_PRIORITY_DEFAULT
		Objman.gcMoveGObjDLHead(item_gobj, 18, GOBJ_PRIORITY_DEFAULT)

	if kind == nITKindLizardon:
		ip.multi = ITLIZARDON_LIFETIME

	dITPippiStatusProcList[index].call(item_gobj)

## 0x80183344
static func itPippiCommonProcDisplay(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	# gDPPipeSync(gSYTaskmanDLHeads[0]++);

	if B(Itdisplay.itDisplayCheckItemVisible(ip)):
		if (ip.display_mode == nDBDisplayModeMaster) or B(ip.is_hold):
			# gDPSetRenderMode(gSYTaskmanDLHeads[0]++, G_RM_AA_ZB_TEX_EDGE, G_RM_AA_ZB_TEX_EDGE2);

			Objdisplay.gcDrawDObjTreeForGObj(item_gobj)

		elif ip.display_mode == nDBDisplayModeMapCollision:
			# gDPSetRenderMode(gSYTaskmanDLHeads[0]++, G_RM_AA_ZB_TEX_EDGE, G_RM_AA_ZB_TEX_EDGE2);

			Objdisplay.gcDrawDObjTreeForGObj(item_gobj)
			Itdisplay.itDisplayMapCollisions(item_gobj)

		elif (ip.damage_coll.hitstatus == nGMHitStatusNone) and (ip.attack_coll.attack_state == nGMAttackStateOff):
			# gDPSetRenderMode(gSYTaskmanDLHeads[0]++, G_RM_AA_ZB_TEX_EDGE, G_RM_AA_ZB_TEX_EDGE2);

			Objdisplay.gcDrawDObjTreeForGObj(item_gobj)

		else:
			Itdisplay.itDisplayHitCollisions(item_gobj)

	# gDPPipeSync(gSYTaskmanDLHeads[0]++);

## 0x801834A0 - Render routine of Hitmonlee / Starmie metronome abilities
static func itPippiCommonMoveDLProcDisplay(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	# gDPPipeSync(gSYTaskmanDLHeads[0]++);

	if B(Itdisplay.itDisplayCheckItemVisible(ip)):
		if (ip.display_mode == nDBDisplayModeMaster) or B(ip.is_hold):
			# gDPSetRenderMode(gSYTaskmanDLHeads[0]++, G_RM_AA_XLU_SURF, G_RM_AA_XLU_SURF2);

			Objdisplay.gcDrawDObjTreeForGObj(item_gobj)

		elif ip.display_mode == nDBDisplayModeMapCollision:
			# gDPSetRenderMode(gSYTaskmanDLHeads[0]++, G_RM_AA_XLU_SURF, G_RM_AA_XLU_SURF2);

			Objdisplay.gcDrawDObjTreeForGObj(item_gobj)
			Itdisplay.itDisplayMapCollisions(item_gobj)

		elif (ip.damage_coll.hitstatus == nGMHitStatusNone) and (ip.attack_coll.attack_state == nGMAttackStateOff):
			# gDPSetRenderMode(gSYTaskmanDLHeads[0]++, G_RM_AA_XLU_SURF, G_RM_AA_XLU_SURF2);

			Objdisplay.gcDrawDObjTreeForGObj(item_gobj)

		else:
			Itdisplay.itDisplayHitCollisions(item_gobj)

	# gDPPipeSync(gSYTaskmanDLHeads[0]++);

## 0x801835FC
static func itPippiCommonProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		ip.physics.vel_air.y = 0.0
		ip.physics.vel_air.x = ip.physics.vel_air.y

		itPippiCommonSelectMonster(item_gobj)

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x80183650
static func itPippiCommonProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if B(Itmap.itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_FLOOR)):
		ip.physics.vel_air.y = 0.0

	return FALSE

## 0x80183690
static func itPippiMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITPippiItemDesc, pos, vel, flags)

	if item_gobj != null:
		var dobj := DObjGetStruct(item_gobj)
		var ip := itGetStruct(item_gobj)

		ip.multi = ITMONSTER_RISE_STOP_WAIT

		ip.physics.vel_air.z = 0.0
		ip.physics.vel_air.x = ip.physics.vel_air.z
		ip.physics.vel_air.y = ITMONSTER_RISE_VEL_Y

		Objman.gcAddXObjForDObjFixed(dobj, 0x48, 0)

		dobj.translate = pos

		dobj.translate.y -= ip.attr.map_coll_bottom

		# itGetMonsterAnimNode(ip, &llITCommonDataPippiDataStart) == ITCommonObject + 0x13624
		ObjAnim.gcAddDObjAnimJoint(dobj, dITCommonObjectMonsterAnimBank, 0.0)
		Snd.func_800269C0_275C0(nSYAudioVoiceMBallPippiAppear)

		item_gobj.display_proc = Callable(Itpippi, &"itPippiCommonProcDisplay") # item_gobj->proc_display

	return item_gobj
