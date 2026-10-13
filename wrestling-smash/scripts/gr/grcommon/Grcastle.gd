## 1:1 port of src/gr/grcommon/grcastle.c (Peach's Castle: bumper riding the moving top platform).
## The moving platforms themselves are yakumono DObjs animated by the layer-1 GObj (Grdisplay/Mpcollision).
class_name Grcastle
extends Port

## relocData symbol (tools/relocFileDescriptions.us.txt [259] GRCastleMap)
const llGRCastleMapMapHead := 0x0

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8010B340
static func grCastleBumperProcUpdate(ground_gobj = null) -> void:
	var castle: Dictionary = Grcommonsetup.gGRCommonStruct.castle
	var ground_pos: Vector3 = DObjGetStruct(ground_gobj).translate

	if castle.bumper_gobj != null:
		# Vec3f *bumper_pos = &DObjGetStruct(bumper_gobj)->translate.vec.f;
		DObjGetStruct(castle.bumper_gobj).translate.x = ground_pos.x + castle.bumper_pos.x

## 0x8010B378
static func grCastleInitAll() -> void:
	var map_head
	var ground_gobj
	var yakumono_pos: Vector3
	var vel: Vector3
	var pos_id: int
	var dobj: DObj
	var castle: Dictionary = Grcommonsetup.gGRCommonStruct.castle
	var gMPCollisionGroundData: Dictionary = Grdisplay.grDisplayGetGroundData()

	map_head = Grdisplay.grDisplayPtrAdd(gMPCollisionGroundData.map_nodes, -llGRCastleMapMapHead)
	castle.map_head = map_head

	ground_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindGround, null, nGCCommonLinkIDGround, GOBJ_PRIORITY_DEFAULT)

	Objman.gcAddGObjProcess(ground_gobj, Callable(Grcastle, &"grCastleBumperProcUpdate"), nGCProcessKindFunc, 4)

	dobj = Objman.gcAddDObjForGObj(ground_gobj, null)
	dobj.translate.x = 0.0
	dobj.translate.y = 0.0
	dobj.translate.z = 0.0

	Objman.gcAddGObjProcess(ground_gobj, Callable(Grdisplay, &"gcPlayAnimAll"), nGCProcessKindFunc, 5)

	Grdisplay.gcAddAnimJointAll(ground_gobj, gMPCollisionGroundData.map_nodes, 0.0)
	Grdisplay.gcPlayAnimAll(ground_gobj)

	pos_id = Grdisplay.grDisplayGetMapObjIDsKind(nMPMapObjKindBumper)[0]   # mpCollisionGetMapObjIDsKind(nMPMapObjKindBumper, &pos_id)
	yakumono_pos = Grdisplay.grDisplayGetMapObjPositionID(pos_id)

	castle.bumper_pos = yakumono_pos

	vel.x = 0.0
	vel.y = 0.0
	vel.z = 0.0

	castle.bumper_gobj = Itmanager.itManagerMakeItemSetupCommon(null, nITKindGBumper, yakumono_pos, vel, ITEM_FLAG_PARENT_GROUND)

## 0x8010B4AC
static func grCastleMakeGround():
	grCastleInitAll()

	return null

# BEGIN GENERATED FILE IMAGES (tools/port/gr/gen_gr_file_images.py - do not edit by hand)
## relocData words read by the ground code, from baserom.us.z64 (US v1.0, SHA-1 e2929e10fccc0aa84e5776227e798abc07cedabf).
## Same bytes as the typed C in sources/ssb-decomp-re/src/relocData/<file>.c. "w": {byte_offset: [u32 words]},
## "p": relocated pointer slots {byte_offset: [file_id, byte_offset, kind]} (kind 1 AObjEvent32, 2 SYInterpDesc, 0 other).
const dGRCastleFileImages: Array = [
	{"fid": 106, "name": "StageCastleFile2", "w": {
		0x1850: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002001, 0x00000000,
			0x43F00000, 0x43FA8001, 0xC4070000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00002001, 0x00000000, 0xC3F00000, 0x43FA8001, 0xC4070000, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x44E2E000,
			0xC4520000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x00000012, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x2A08: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0x44529997, 0xC3610000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000001, 0x00000000, 0x4571D4B8, 0x455539F5, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0xC571D4B8, 0x45553B66,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000],
		0x2D80: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x3218: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0xC3960000, 0x44430000,
			0x00000000, 0x00000000, 0x3FD5EE13, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000012, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x32D0: [0x00000000, 0x00000000, 0x00000000],
		0x3600: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000],
		}, "p": {
		0x1880: [106, 0x1190, 0],
		0x18AC: [106, 0x14E8, 0],
		0x18D8: [106, 0x15D8, 0],
		0x1904: [106, 0x1698, 0],
		0x1930: [106, 0x1760, 0],
		0x2A38: [106, 0x2240, 0],
		0x2A64: [106, 0x2758, 0],
		0x2A90: [106, 0x2808, 0],
		0x2ABC: [106, 0x28F8, 0],
		0x2D88: [106, 0x2D94, 1],
		0x2D8C: [106, 0x2DE4, 1],
		0x2D90: [106, 0x2E1C, 1],
		0x3248: [106, 0x3010, 0],
		0x3274: [106, 0x3148, 0],
		0x32D4: [106, 0x32DC, 1],
		0x3630: [106, 0x3470, 0],
		}},
	{"fid": 156, "name": "StageCastleFile3", "w": {
		0x0000: [0x00000000, 0x06080000, 0x00000000, 0x06080257, 0xC4834000, 0x060804B0, 0x44834000, 0x06080258,
			0x00000000, 0x06080960, 0x00000000, 0x1C000000, 0x00000000],
		}, "p": {
		0x0000: [156, 0x0004, 1],
		0x0030: [156, 0x0004, 1],
		}},
]
# END GENERATED FILE IMAGES
