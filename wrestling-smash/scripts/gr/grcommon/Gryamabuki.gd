## 1:1 port of src/gr/grcommon/gryamabuki.c (Saffron City Poke-center gate and Pokemon).
## The elevators are yakumono DObjs animated by the layer-1 GObj (Grdisplay/Mpcollision); the gate's
## collision is yakumono 3, positioned by this code.
class_name Gryamabuki
extends Port

## relocData symbols (tools/relocFileDescriptions.us.txt [264] GRYamabukiMap)
const llGRYamabukiMapMapHeader := 0x14
const llGRYamabukiMapItemHead := 0x14
const llGRYamabukiMapMapHead := 0x8A0
const llGRYamabukiMapGateOpenAnimJoint := 0x9B0
const llGRYamabukiMapGateCloseAnimJoint := 0xA20

# GRYAMABUKI_MONSTER_WEAPON_* (grvars.h) come from SSBDefs.

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8012EB60
static var dGRYamabukiMonsterAttackKind: int = GRYAMABUKI_MONSTER_WEAPON_MAX

## 0x8012EB64
static var dGRYamabukiMonsterMapObjKinds: Array = [
	nMPMapObjKindMonster,
	nMPMapObjKindMonsterUnused2,
	nMPMapObjKindMonsterUnused3,
	nMPMapObjKindMonsterUnused4,
	nMPMapObjKindMonsterUnused1,
]

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

const nGRYamabukiGateStatusSleep := 0
const nGRYamabukiGateStatusWait := 1    # The gates open + lights on state is still considered Gate_Wait
const nGRYamabukiGateStatusOpen := 2    # Fully open when a Pokemon appears

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## dITManagerForceMonsterKind (src/it/itmanager.c; 0 while Itmanager does not declare it)
static func _grYamabukiGetForceMonsterKind() -> int:
	var s: Object = Itmanager
	var v = s.get("dITManagerForceMonsterKind")
	return int(v) if v != null else 0

## gMPCollisionYakumonoDObjs->dobjs[3]->translate.vec.f.y
static func _grYamabukiGetGateYakumonoY() -> float:
	var dobj: DObj = Grdisplay.grDisplayGetYakumonoDObj(3)
	return dobj.translate.y if dobj != null else 0.0

## 0x8010ACD0
static func grYamabukiGateUpdateSleep() -> void:
	var yamabuki: Dictionary = Grcommonsetup.gGRCommonStruct.yamabuki

	if G.gSCManagerBattleState.game_status != nSCBattleGameStatusWait:
		yamabuki.gate_status = nGRYamabukiGateStatusWait
		yamabuki.monster_wait = syUtilsRandIntRange(1000) + 1000

## 0x8010AD18
static func grYamabukiGateCheckPlayersNear() -> int:
	for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		var fp := ftGetStruct(fighter_gobj)

		if (fp.ga == nMPKineticsGround) and ((fp.coll_data.floor_flags & MAP_VERTEX_MAT_MASK) == nMPMaterialDetect):
			return TRUE

	return FALSE

## 0x8010AD70
static func grYamabukiGateMakeMonster() -> void:
	var pos: Vector3
	var vel: Vector3
	var mapobj: int
	var item_id: int
	var yamabuki: Dictionary = Grcommonsetup.gGRCommonStruct.yamabuki
	var force_kind := _grYamabukiGetForceMonsterKind()

	yamabuki.gate_status = nGRYamabukiGateStatusOpen
	yamabuki.gate_noentry = FALSE

	mapobj = Grdisplay.grDisplayGetMapObjIDsKind(dGRYamabukiMonsterMapObjKinds[0])[0]
	pos = Grdisplay.grDisplayGetMapObjPositionID(mapobj)

	vel.x = 0.0
	vel.y = 0.0
	vel.z = 0.0

	if (force_kind == 0) or (force_kind > (nITKindGroundMonsterEnd - nITKindGroundMonsterStart + 1)):
		item_id = syUtilsRandIntRange(nITKindGroundMonsterEnd - nITKindGroundMonsterStart + 1)

		if item_id == yamabuki.monster_id_prev:
			item_id = 0 if (item_id == (nITKindGroundMonsterEnd - nITKindGroundMonsterStart)) else item_id + 1

		yamabuki.monster_id_prev = item_id & 0xFF   # u8
	else:
		item_id = force_kind - 1

	yamabuki.monster_gobj = Itmanager.itManagerMakeItemSetupCommon(null, item_id + nITKindGroundMonsterStart, pos, vel, ITEM_FLAG_PARENT_GROUND)

## 0x8010AE3C
static func grYamabukiGateSetPositionFar() -> void:
	var yamabuki: Dictionary = Grcommonsetup.gGRCommonStruct.yamabuki

	yamabuki.gate_pos.x = 1600.0
	yamabuki.gate_pos.y = _grYamabukiGetGateYakumonoY()

## 0x8010AE68
static func grYamabukiGateSetPositionNear() -> void:
	var yamabuki: Dictionary = Grcommonsetup.gGRCommonStruct.yamabuki

	yamabuki.gate_pos.x = 960.0
	yamabuki.gate_pos.y = _grYamabukiGetGateYakumonoY()

## 0x8010AE94
static func grYamabukiGateAddAnimOffset(offset = null) -> void:
	var yamabuki: Dictionary = Grcommonsetup.gGRCommonStruct.yamabuki

	Grdisplay.gcAddAnimJointAll(yamabuki.gate_gobj, Grdisplay.grDisplayPtrAdd(yamabuki.map_head, offset), 0.0)
	Grdisplay.gcPlayAnimAll(yamabuki.gate_gobj)

## 0x8010AED8
static func grYamabukiGateAddAnimOpen() -> void:
	grYamabukiGateAddAnimOffset(llGRYamabukiMapGateOpenAnimJoint)

## 0x8010AEFC
static func grYamabukiGateAddAnimClose() -> void:
	grYamabukiGateAddAnimOffset(llGRYamabukiMapGateCloseAnimJoint)

## 0x8010AF20 - Allow entry inside Pokemon spawn hub?
static func grYamabukiGateAddAnimOpenEntry() -> void:
	grYamabukiGateAddAnimOpen()
	grYamabukiGateSetPositionFar()

## 0x8010AF48
static func grYamabukiGateUpdateWait() -> void:
	var yamabuki: Dictionary = Grcommonsetup.gGRCommonStruct.yamabuki

	if yamabuki.gate_wait == 0:
		if grYamabukiGateCheckPlayersNear() != FALSE:
			grYamabukiGateMakeMonster()

			return
	else:
		yamabuki.gate_wait = (yamabuki.gate_wait - 1) & 0xFFFF   # --gate_wait (u16)

		if yamabuki.gate_wait == 0:
			grYamabukiGateAddAnimOpenEntry()
			Snd.func_800269C0_275C0(nSYAudioFGMYamabukiGate)

	yamabuki.monster_wait = (yamabuki.monster_wait - 1) & 0xFFFF   # u16

	if yamabuki.monster_wait == 0:
		if yamabuki.gate_wait != 0:
			grYamabukiGateAddAnimOpen()
			Snd.func_800269C0_275C0(nSYAudioFGMYamabukiGate)

		grYamabukiGateMakeMonster()

## 0x8010AFF4
static func grYamabukiGateUpdateOpen() -> void:
	var yamabuki: Dictionary = Grcommonsetup.gGRCommonStruct.yamabuki

	if yamabuki.monster_gobj == null:
		grYamabukiGateSetClosedWait()
	elif yamabuki.gate_noentry == FALSE:
		var ip := itGetStruct(yamabuki.monster_gobj)

		yamabuki.gate_pos.x = DObjGetStruct(yamabuki.monster_gobj).translate.x - ip.coll_data.map_coll.width
		yamabuki.gate_pos.y = _grYamabukiGetGateYakumonoY()

		if yamabuki.gate_pos.x < 960.0:
			yamabuki.gate_pos.x = 960.0

			yamabuki.gate_noentry = TRUE
		elif yamabuki.gate_pos.x > 1600.0:
			yamabuki.gate_pos.x = 1600.0

## 0x8010B0AC
static func grYamabukiGateClearMonsterGObj() -> void:
	Grcommonsetup.gGRCommonStruct.yamabuki.monster_gobj = null

## 0x8010B0B8
static func grYamabukiGateSetClosedWait() -> void:
	var yamabuki: Dictionary = Grcommonsetup.gGRCommonStruct.yamabuki

	yamabuki.gate_status = nGRYamabukiGateStatusWait
	yamabuki.gate_wait = 1000

	yamabuki.monster_wait = syUtilsRandIntRange(1000) + 1000

	grYamabukiGateSetPositionNear()
	grYamabukiGateAddAnimClose()

## 0x8010B108
static func grYamabukiGateUpdateYakumonoPos() -> void:
	Mpcollision.mpCollisionSetYakumonoPosID(3, Grcommonsetup.gGRCommonStruct.yamabuki.gate_pos)

## 0x8010B130
static func grYamabukiGateProcUpdate(ground_gobj = null) -> void:
	match Grcommonsetup.gGRCommonStruct.yamabuki.gate_status:
		nGRYamabukiGateStatusSleep:
			grYamabukiGateUpdateSleep()
		nGRYamabukiGateStatusWait:
			grYamabukiGateUpdateWait()
			grYamabukiGateUpdateYakumonoPos()
		nGRYamabukiGateStatusOpen:
			grYamabukiGateUpdateOpen()
			grYamabukiGateUpdateYakumonoPos()

## (no address in the decomp)
static func grYamabukiMakeGate() -> void:
	var gate_gobj
	var yamabuki: Dictionary = Grcommonsetup.gGRCommonStruct.yamabuki

	gate_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindGround, null, nGCCommonLinkIDGround, GOBJ_PRIORITY_DEFAULT)
	yamabuki.gate_gobj = gate_gobj

	Objman.gcAddGObjDisplay(gate_gobj, Callable(Objdisplay, &"gcDrawDObjTreeDLLinksForGObj"), 6, GOBJ_PRIORITY_DEFAULT, ~0)
	Grdisplay.gcSetupCustomDObjs(
		gate_gobj,
		Grdisplay.grDisplayPtrAdd(yamabuki.map_head, llGRYamabukiMapMapHead),
		null,
		nGCMatrixKindTraRotRpyR,
		nGCMatrixKindNull,
		nGCMatrixKindNull
	)
	Objman.gcAddGObjProcess(gate_gobj, Callable(Grdisplay, &"gcPlayAnimAll"), nGCProcessKindFunc, 5)
	grYamabukiGateAddAnimClose()

## 0x8010B250
static func grYamabukiInitGroundVars() -> void:
	var yamabuki: Dictionary = Grcommonsetup.gGRCommonStruct.yamabuki
	var gMPCollisionGroundData: Dictionary = Grdisplay.grDisplayGetGroundData()

	yamabuki.map_head = Grdisplay.grDisplayPtrAdd(gMPCollisionGroundData.map_nodes, -llGRYamabukiMapMapHead)

	Mpcollision.mpCollisionSetYakumonoOnID(3)

	yamabuki.gate_wait = 1
	yamabuki.item_head = Grdisplay.grDisplayPtrAdd(gMPCollisionGroundData.header, -llGRYamabukiMapItemHead)

	dGRYamabukiMonsterAttackKind = GRYAMABUKI_MONSTER_WEAPON_MAX

	yamabuki.monster_id_prev = (nITKindGroundMonsterEnd - nITKindGroundMonsterStart) + 1
	yamabuki.gate_pos.z = 0.0

	grYamabukiGateSetPositionNear()
	grYamabukiMakeGate()
	grYamabukiGateUpdateYakumonoPos()

	yamabuki.gate_status = 0

## 0x8010B2EC
static func grYamabukiMakeGround():
	var ground_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindGround, null, nGCCommonLinkIDGround, GOBJ_PRIORITY_DEFAULT)

	Objman.gcAddGObjProcess(ground_gobj, Callable(Gryamabuki, &"grYamabukiGateProcUpdate"), nGCProcessKindFunc, 4)
	grYamabukiInitGroundVars()

	return ground_gobj

# BEGIN GENERATED FILE IMAGES (tools/port/gr/gen_gr_file_images.py - do not edit by hand)
## relocData words read by the ground code, from baserom.us.z64 (US v1.0, SHA-1 e2929e10fccc0aa84e5776227e798abc07cedabf).
## Same bytes as the typed C in sources/ssb-decomp-re/src/relocData/<file>.c. "w": {byte_offset: [u32 words]},
## "p": relocated pointer slots {byte_offset: [file_id, byte_offset, kind]} (kind 1 AObjEvent32, 2 SYInterpDesc, 0 other).
const dGRYamabukiFileImages: Array = [
	{"fid": 112, "name": "StageYamabukiFile2", "w": {
		0x5058: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000,
			0xC53BAB6F, 0x42E62CCE, 0xC54A9CBF, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00008003, 0x00000000, 0x409F8B20, 0x453EEAB9, 0x4158FAE0, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002002,
			0x00000000, 0x4466D999, 0x44AB3B05, 0xC5188E94, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x51C0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x6A70: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002002, 0x00000000,
			0x44DF0CCD, 0x44488346, 0xC3D563A0, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000001, 0x00000000, 0x44D98000, 0x43B40000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001,
			0x00000000, 0xC5115999, 0x44520000, 0xC2980B41, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x00002002, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0xC5826B3B,
			0xC4610000, 0xC2980B41, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000,
			0x00002002, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x6EB0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000],
		0x8718: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000012, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000],
		}, "p": {
		0x5088: [112, 0x45D8, 0],
		0x50B4: [112, 0x4810, 0],
		0x50E0: [112, 0x4938, 0],
		0x510C: [112, 0x49C0, 0],
		0x5138: [112, 0x4BB8, 0],
		0x5164: [112, 0x4C50, 0],
		0x51C8: [112, 0x51DC, 1],
		0x6AA0: [112, 0x69F0, 0],
		0x6ACC: [112, 0x6A00, 0],
		0x6B24: [112, 0x6A10, 0],
		0x6B50: [112, 0x6A20, 0],
		0x6B7C: [112, 0x6A38, 0],
		0x6BA8: [112, 0x6A48, 0],
		0x6BD4: [112, 0x6A60, 0],
		0x6EC4: [112, 0x6ED4, 1],
		0x6ECC: [112, 0x6F8C, 1],
		0x8748: [112, 0x86F8, 0],
		0x8774: [112, 0x8708, 0],
		}},
	{"fid": 160, "name": "StageYamabukiFile4", "w": {
		0x08A0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x44804BC1, 0x43C18807, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0x44804BC1, 0x43C30000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000001, 0x00000000, 0x44804BC1, 0x43C18807, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x444A8000, 0x43D6EB89,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000],
		0x09B0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x10200000, 0x00000000, 0x0A20000A,
			0x43A50000, 0x3F97F144, 0x00000000, 0x10100000, 0x43C30000, 0x0A10000A, 0xC1F00000, 0xBFC1619D,
			0x00000000, 0x10200000, 0x00000000, 0x0A20000A, 0xC3A50000, 0xBF97F144, 0x00000000, 0x1E008004,
			0x1E000006, 0x00000000],
		0x0A20: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x0A200000, 0x43A50000, 0xBF97F144,
			0x1020000A, 0x00000000, 0x00000000, 0x0A100000, 0xC1F00000, 0x3FC1619D, 0x1010000A, 0x43C30000,
			0x00000000, 0x0A200000, 0xC3A50000, 0x3F97F144, 0x1020000A, 0x00000000, 0x00000000, 0x04000007,
			0x1E008003, 0x00000000],
		}, "p": {
		0x08D0: [160, 0x0860, 0],
		0x08FC: [160, 0x0870, 0],
		0x0928: [160, 0x0880, 0],
		0x0954: [160, 0x0890, 0],
		0x09B4: [160, 0x09C4, 1],
		0x09B8: [160, 0x09DC, 1],
		0x09BC: [160, 0x09F4, 1],
		0x09C0: [160, 0x0A0C, 1],
		0x0A24: [160, 0x0A34, 1],
		0x0A28: [160, 0x0A4C, 1],
		0x0A2C: [160, 0x0A64, 1],
		0x0A30: [160, 0x0A7C, 1],
		}},
]
# END GENERATED FILE IMAGES
