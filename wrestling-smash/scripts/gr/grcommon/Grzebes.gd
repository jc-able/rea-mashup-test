## 1:1 port of src/gr/grcommon/grzebes.c (Planet Zebes rising acid).
class_name Grzebes
extends Port

## relocData symbols (tools/relocFileDescriptions.us.txt [257] GRZebesMap)
const llGRZebesMapMapHeader := 0x14
const llGRZebesMapAcidGRAttackColl := 0xBC
const llGRZebesMapAcidMObjSub := 0x8C0
const llGRZebesMapAcidDObjDesc := 0xB08
const llGRZebesMapAcidAnimJoint := 0xB90
const llGRZebesMapAcidMatAnimJoint := 0xBD0

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8012EA60 - GRZebesAcid {acid_wait_base, acid_random_min, acid_random_max, acid_level}
static var dGRZebesAcidAttributes: Array = [
	{"acid_wait_base": 1200, "acid_random_min": 60, "acid_random_max": 70, "acid_level": -3600.0},
	{"acid_wait_base": 180, "acid_random_min": 60, "acid_random_max": 70, "acid_level": -1000.0},
	{"acid_wait_base": 60, "acid_random_min": 60, "acid_random_max": 70, "acid_level": -200.0},
	{"acid_wait_base": 60, "acid_random_min": 60, "acid_random_max": 70, "acid_level": 1800.0},
	{"acid_wait_base": 60, "acid_random_min": 60, "acid_random_max": 70, "acid_level": -3600.0},
	{"acid_wait_base": 120, "acid_random_min": 0, "acid_random_max": 0, "acid_level": 2600.0},
	{"acid_wait_base": 30, "acid_random_min": 0, "acid_random_max": 0, "acid_level": -1000.0},
	{"acid_wait_base": 1200, "acid_random_min": 60, "acid_random_max": 70, "acid_level": -500.0},
	{"acid_wait_base": 600, "acid_random_min": 60, "acid_random_max": 70, "acid_level": -400.0},
	{"acid_wait_base": 100, "acid_random_min": 60, "acid_random_max": 70, "acid_level": 800.0},
	{"acid_wait_base": 1200, "acid_random_min": 60, "acid_random_max": 70, "acid_level": 1200.0},
	{"acid_wait_base": 60, "acid_random_min": 0, "acid_random_max": 0, "acid_level": -1000.0},
	{"acid_wait_base": 60, "acid_random_min": 60, "acid_random_max": 70, "acid_level": 0.0},
	{"acid_wait_base": 60, "acid_random_min": 60, "acid_random_max": 70, "acid_level": -1000.0},
	{"acid_wait_base": 120, "acid_random_min": 60, "acid_random_max": 70, "acid_level": 500.0},
	{"acid_wait_base": 200, "acid_random_min": 60, "acid_random_max": 70, "acid_level": -3000.0},
]

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

const nGRZebesAcidStatusWait := 0
const nGRZebesAcidStatusNormal := 1
const nGRZebesAcidStatusShake := 2
const nGRZebesAcidStatusRise := 3

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80108020
static func grZebesAcidSetLevelStep() -> void:
	var zebes: Dictionary = Grcommonsetup.gGRCommonStruct.zebes

	zebes.acid_level_step = ((dGRZebesAcidAttributes[zebes.acid_attr_id].acid_level + (syUtilsRandFloat() * 250.0)) - zebes.acid_level_curr) / 240.0

## 0x80108088
static func grZebesAcidSetRandomWait() -> void:
	var zebes: Dictionary = Grcommonsetup.gGRCommonStruct.zebes
	var index: int = zebes.acid_attr_id

	zebes.acid_level_wait = (dGRZebesAcidAttributes[index].acid_wait_base +
			dGRZebesAcidAttributes[index].acid_random_min +
			syUtilsRandIntRange(dGRZebesAcidAttributes[index].acid_random_max - dGRZebesAcidAttributes[index].acid_random_min)) & 0xFFFF

## 0x801080EC
static func grZebesMakeAcid():
	var map_gobj
	var map_head
	var zebes: Dictionary = Grcommonsetup.gGRCommonStruct.zebes
	var gMPCollisionGroundData: Dictionary = Grdisplay.grDisplayGetGroundData()

	map_head = Grdisplay.grDisplayPtrAdd(gMPCollisionGroundData.map_nodes, -llGRZebesMapAcidDObjDesc)
	zebes.map_head = map_head

	map_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindGround, null, nGCCommonLinkIDGround, GOBJ_PRIORITY_DEFAULT)
	zebes.map_gobj = map_gobj

	Objman.gcAddGObjDisplay(map_gobj, Callable(Objdisplay, &"gcDrawDObjTreeDLLinksForGObj"), 12, GOBJ_PRIORITY_DEFAULT, ~0)
	Grdisplay.gcSetupCustomDObjs(
		map_gobj,
		Grdisplay.grDisplayPtrAdd(map_head, llGRZebesMapAcidDObjDesc),
		null,
		nGCMatrixKindTra,
		nGCMatrixKindNull,
		nGCMatrixKindNull
	)
	Grdisplay.gcAddMObjAll(map_gobj, Grdisplay.grDisplayPtrAdd(map_head, llGRZebesMapAcidMObjSub))
	Objman.gcAddGObjProcess(map_gobj, Callable(Grdisplay, &"gcPlayAnimAll"), nGCProcessKindFunc, 5)
	Grdisplay.gcAddAnimAll(
		map_gobj,
		Grdisplay.grDisplayPtrAdd(map_head, llGRZebesMapAcidAnimJoint),
		Grdisplay.grDisplayPtrAdd(map_head, llGRZebesMapAcidMatAnimJoint),
		0.0
	)
	Grdisplay.gcPlayAnimAll(map_gobj)

	zebes.acid_status = nGRZebesAcidStatusWait
	zebes.acid_level_curr = dGRZebesAcidAttributes[dGRZebesAcidAttributes.size() - 1].acid_level
	zebes.acid_attr_id = 0

	# lbRelocGetFileData(GRAttackColl*, (uintptr_t)gMPCollisionGroundData - &llGRZebesMapMapHeader, &llGRZebesMapAcidGRAttackColl)
	zebes.attack_coll = Grdisplay.grDisplayGetAttackColl(Grdisplay.grDisplayPtrAdd(gMPCollisionGroundData.header, llGRZebesMapAcidGRAttackColl - llGRZebesMapMapHeader))

	grZebesAcidSetRandomWait()

	DObjGetStruct(map_gobj).translate.y = zebes.acid_level_curr

	return map_gobj

## 0x80108240
static func grZebesAcidUpdateWait() -> void:
	if G.gSCManagerBattleState.game_status != nSCBattleGameStatusWait:
		Grcommonsetup.gGRCommonStruct.zebes.acid_status = nGRZebesAcidStatusNormal

## 0x80108268
static func grZebesAcidUpdateRumble() -> void:
	var zebes: Dictionary = Grcommonsetup.gGRCommonStruct.zebes

	if zebes.rumble_wait == 0:
		Efmanager.efManagerQuakeMakeEffect(0)

		zebes.rumble_wait = 18

	zebes.rumble_wait = (zebes.rumble_wait - 1) & 0xFF   # u8

## 0x801082B4
static func grZebesAcidUpdateNormal() -> void:
	var zebes: Dictionary = Grcommonsetup.gGRCommonStruct.zebes

	zebes.acid_level_wait = (zebes.acid_level_wait - 1) & 0xFFFF   # u16

	if zebes.acid_level_wait == 0:
		zebes.acid_status = nGRZebesAcidStatusShake
		zebes.acid_level_wait = 18
		zebes.rumble_wait = 0

## 0x801082EC
static func grZebesAcidUpdateShake() -> void:
	var zebes: Dictionary = Grcommonsetup.gGRCommonStruct.zebes

	zebes.acid_level_wait = (zebes.acid_level_wait - 1) & 0xFFFF

	if zebes.acid_level_wait == 0:
		zebes.acid_status = nGRZebesAcidStatusRise
		zebes.acid_level_wait = 240

		grZebesAcidSetLevelStep()

	grZebesAcidUpdateRumble()

## 0x8010833C
static func grZebesAcidUpdateRise() -> void:
	var zebes: Dictionary = Grcommonsetup.gGRCommonStruct.zebes

	zebes.acid_level_curr += zebes.acid_level_step

	DObjGetStruct(zebes.map_gobj).translate.y = zebes.acid_level_curr

	zebes.acid_level_wait = (zebes.acid_level_wait - 1) & 0xFFFF

	if zebes.acid_level_wait == 0:
		zebes.acid_status = nGRZebesAcidStatusNormal
		zebes.acid_attr_id = (zebes.acid_attr_id + 1) & 0xFF   # u8

		if zebes.acid_attr_id >= dGRZebesAcidAttributes.size():
			zebes.acid_attr_id = 0

		grZebesAcidSetRandomWait()

	grZebesAcidUpdateRumble()

## 0x801083C4
static func grZebesProcUpdate(ground_gobj = null) -> void:
	match Grcommonsetup.gGRCommonStruct.zebes.acid_status:
		nGRZebesAcidStatusWait:
			grZebesAcidUpdateWait()
		nGRZebesAcidStatusNormal:
			grZebesAcidUpdateNormal()
		nGRZebesAcidStatusShake:
			grZebesAcidUpdateShake()
		nGRZebesAcidStatusRise:
			grZebesAcidUpdateRise()

## 0x80108448
static func grZebesMakeGround():
	var ground_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindGround, null, nGCCommonLinkIDGround, GOBJ_PRIORITY_DEFAULT)
	var acid_gobj = grZebesMakeAcid()

	Objman.gcAddGObjProcess(ground_gobj, Callable(Grzebes, &"grZebesProcUpdate"), nGCProcessKindFunc, 4)
	Ftmain.ftMainCheckAddGroundHazard(acid_gobj, Callable(Grzebes, &"grZebesAcidCheckGetDamageKind"))

	return ground_gobj

## 0x801084AC - hazard proc_update: returns {"ret": sb32, "gr_attack_coll": GRAttackColl, "kind": s32} (Ftmain convention)
static func grZebesAcidCheckGetDamageKind(ground_gobj = null, fighter_gobj = null) -> Dictionary:
	var fp := ftGetStruct(fighter_gobj)

	if fp.acid_wait == 0:
		var dobj: DObj = DObjGetStruct(ground_gobj)

		if DObjGetStruct(fighter_gobj).translate.y < (dobj.translate.y + dobj.child.translate.y):
			return {"ret": TRUE, "gr_attack_coll": Grcommonsetup.gGRCommonStruct.zebes.attack_coll, "kind": nGMHitEnvironmentAcid}

	return {"ret": FALSE, "gr_attack_coll": null, "kind": 0}

## 0x8010850C - void, two out-params -> {"current": f32, "step": f32}
static func grZebesAcidGetLevelInfo(current = null, step = null) -> Dictionary:
	var zebes: Dictionary = Grcommonsetup.gGRCommonStruct.zebes

	return {
		"current": zebes.acid_level_curr,
		"step": zebes.acid_level_step if (zebes.acid_status == nGRZebesAcidStatusRise) else 0.0,
	}

# BEGIN GENERATED FILE IMAGES (tools/port/gr/gen_gr_file_images.py - do not edit by hand)
## relocData words read by the ground code, from baserom.us.z64 (US v1.0, SHA-1 e2929e10fccc0aa84e5776227e798abc07cedabf).
## Same bytes as the typed C in sources/ssb-decomp-re/src/relocData/<file>.c. "w": {byte_offset: [u32 words]},
## "p": relocated pointer slots {byte_offset: [file_id, byte_offset, kind]} (kind 1 AObjEvent32, 2 SYInterpDesc, 0 other).
const dGRZebesFileImages: Array = [
	{"fid": 105, "name": "StageZebesFile2", "w": {
		0x5AC0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0x453AC004, 0x43B5A496, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002,
			0x00000000, 0x448E8000, 0xC262DB50, 0xC40E8000, 0x00000000, 0xBED6BB56, 0x00000000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x00000002, 0x00000000, 0xC5034000, 0x4430524D, 0xC3E88000, 0x00000000,
			0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000, 0xC4D38000,
			0x4410124D, 0xC3E70003, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000,
			0x00000002, 0x00000000, 0xC51C6000, 0x4426924D, 0xC3E70003, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000, 0x44BA0000, 0xC1A5B694, 0xC3D08003,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002002, 0x00000000,
			0xC0402C45, 0x44089252, 0xC3CA801F, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F884BB2,
			0x3F800000, 0x00002002, 0x00000000, 0xC0400071, 0x440E8004, 0xC3C77FEC, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002002, 0x00000000, 0xC0402C45, 0x439C24A0,
			0xC3C4801D, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002002, 0x00000000, 0x44D80000,
			0xC3FA5B69, 0x4380FFFD, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000,
			0x00002002, 0x00000000, 0xC4EBE000, 0x40C9259E, 0x43B57FFD, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00002002, 0x00000000, 0xC52C5000, 0x43992498, 0x43D37FFD,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000,
			0xC3BA0002, 0x4301492E, 0x43D37FFD, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00002002, 0x00000000, 0xC5088002, 0x44005248, 0x43F17FF0, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F8CD1B7, 0x3F800000, 0x00002002, 0x00000000, 0xC5087FFE, 0x44064004,
			0x43F48016, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002002,
			0x00000000, 0xC5088002, 0x43BA2484, 0x43F5FFF1, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x00002002, 0x00000000, 0xC506D000, 0x40C9259E, 0x440F3FFE, 0x00000000,
			0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002002, 0x00000000, 0x4412FFFF,
			0xC4086DB5, 0x441E3FFE, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000,
			0x00002002, 0x00000000, 0x43E9FF9F, 0x43074942, 0x4443BFFC, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00002002, 0x00000000, 0x43E9FFFE, 0x4327FFF7, 0x4445400B,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002002, 0x00000000,
			0x43E9FF9F, 0x4205250E, 0x4445FFFD, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000002, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x6180: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000],
		}, "p": {
		0x5AF0: [105, 0x5930, 0],
		0x5B1C: [105, 0x5940, 0],
		0x5B74: [105, 0x5950, 0],
		0x5BA0: [105, 0x5960, 0],
		0x5BCC: [105, 0x5970, 0],
		0x5BF8: [105, 0x5980, 0],
		0x5C24: [105, 0x5990, 0],
		0x5C50: [105, 0x59A0, 0],
		0x5C7C: [105, 0x59B0, 0],
		0x5CA8: [105, 0x59C0, 0],
		0x5CD4: [105, 0x59D0, 0],
		0x5D00: [105, 0x59E0, 0],
		0x5D58: [105, 0x59F0, 0],
		0x5D84: [105, 0x5A00, 0],
		0x5DB0: [105, 0x5A10, 0],
		0x5DDC: [105, 0x5A20, 0],
		0x5E08: [105, 0x5A30, 0],
		0x5E34: [105, 0x5A40, 0],
		0x5E60: [105, 0x5A50, 0],
		0x5E8C: [105, 0x5A60, 0],
		0x5EB8: [105, 0x5A70, 0],
		0x5EE4: [105, 0x5A80, 0],
		0x5F10: [105, 0x5A90, 0],
		0x5F3C: [105, 0x5AA0, 0],
		0x5F68: [105, 0x5AB0, 0],
		0x6188: [105, 0x61F0, 1],
		0x61A8: [105, 0x6224, 1],
		0x61CC: [105, 0x62CC, 1],
		0x61E0: [105, 0x6374, 1],
		}},
	{"fid": 157, "name": "StageZebesFile3", "w": {
		0x08C0: [0x00000000, 0x00000000],
		0x08D8: [0x00000202, 0x00000000, 0x00200180, 0x01800180, 0x00000000, 0xBF000000, 0xBF000000, 0x40000000,
			0x40000000, 0xBF000000, 0x40000000, 0x00000000, 0x006B0200, 0x00200020, 0x01800180, 0xBF000000,
			0xBF000000, 0xBF000000, 0x00000000, 0x00002205, 0xFFFFFFFF, 0xF3000000, 0x000000FF, 0x00000008,
			0xFFFFFF00, 0x80808000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x0B08: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0xC38D5CD2, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000],
		0x0B90: [0x00000000, 0x00000000, 0x10100000, 0xC3870000, 0x1010003B, 0x43340000, 0x10100078, 0xC4340000,
			0x0C10003D, 0xC3870000, 0x3DDA9542, 0x04000037, 0x1C000000, 0x00000000],
		0x0BD0: [0x00000000, 0x00000000, 0x16108000, 0x00000000, 0x3F800000, 0x12800000, 0x3F733333, 0x06630000,
			0x00000000, 0x00000000, 0xBF800000, 0x00000000, 0x16008036, 0x00000000, 0x1280003A, 0x3F59999A,
			0x086300EA, 0xBF000000, 0xBF000000, 0xBF000000, 0xBF000000, 0x14100006, 0x40000000, 0x14100006,
			0x40400000, 0x14100006, 0x3F800000, 0x14100006, 0x40000000, 0x14100006, 0x40400000, 0x14100006,
			0x3F800000, 0x14100006, 0x40000000, 0x14100006, 0x40400000, 0x14100006, 0x3F800000, 0x16100006,
			0x40000000, 0x16008038, 0x00000000, 0x04000004, 0x1280003B, 0x3F733333, 0x04000002, 0x14100006,
			0x40400000, 0x14100006, 0x3F800000, 0x14100006, 0x40000000, 0x14100006, 0x40400000, 0x14100006,
			0x3F800000, 0x14100006, 0x40000000, 0x14100006, 0x40400000, 0x14100006, 0x3F800000, 0x16100006,
			0x40000000, 0x04000002, 0x16008037, 0x00000000, 0x04000004, 0x16100006, 0x40400000, 0x04000003,
			0x1280003B, 0x3F59999A, 0x04000003, 0x14100006, 0x3F800000, 0x14100006, 0x40000000, 0x14100006,
			0x40400000, 0x14100006, 0x3F800000, 0x14100006, 0x40000000, 0x14100006, 0x40400000, 0x14100006,
			0x3F800000, 0x16100006, 0x40000000, 0x04000003, 0x16008038, 0x00000000, 0x04000003, 0x14100006,
			0x40400000, 0x16100006, 0x3F800000, 0x04000002, 0x1280003A, 0x3F733333, 0x04000004, 0x14100006,
			0x40000000, 0x14100006, 0x40400000, 0x14100006, 0x3F800000, 0x14100006, 0x40000000, 0x14100006,
			0x40400000, 0x14100006, 0x3F800000, 0x14100006, 0x40000000, 0x14100006, 0x40400000, 0x161000A9,
			0x3F800000, 0x04000006, 0x1C000000, 0x00000000, 0x00000000],
		}, "p": {
		0x08C4: [157, 0x0950, 0],
		0x08DC: [157, 0x08C8, 0],
		0x0950: [157, 0x08D8, 0],
		0x0B38: [157, 0x0AF8, 0],
		0x0B94: [157, 0x0B98, 1],
		0x0BC4: [157, 0x0B98, 1],
		0x0BD4: [157, 0x0DC0, 0],
		0x0DBC: [157, 0x0BD8, 1],
		0x0DC0: [157, 0x0BD8, 1],
		}},
	{"fid": 257, "name": "GRZebesMap", "w": {
		0x00BC: [0x00000000, 0x00000010, 0x00000050, 0x00000082, 0x00000000, 0x0000001E, 0x00000001],
		}, "p": {
		}},
]
# END GENERATED FILE IMAGES
