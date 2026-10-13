## 1:1 port of src/gr/grcommon/grjungle.c (Congo Jungle barrel cannon).
## The moving platforms are yakumono DObjs animated by the layer-1 GObj (Grdisplay/Mpcollision).
class_name Grjungle
extends Port

## relocData symbols (tools/relocFileDescriptions.us.txt [261] GRJungleMap)
const llGRJungleMapMapHead := 0xA98
const llGRJungleMapTaruCannDefaultAnimJoint := 0xB20
const llGRJungleMapTaruCannFillAnimJoint := 0xB68
const llGRJungleMapTaruCannShootAnimJoint := 0xBF8

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8012EB50
static var dGRJungleTaruCannTransformKinds: Array = [
	{"tk1": 0x28, "tk2": nGCMatrixKindRotRpyR, "tk3": 0x00},
	{"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0x00},
]

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

const nGRJungleTaruCannStatusMove := 0
const nGRJungleTaruCannStatusRotate := 1

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80109CB0
static func grJungleTaruCannAddAnimOffset(ground_gobj = null, offset = null) -> void:
	var dobj: DObj = DObjGetStruct(ground_gobj).child

	Grdisplay.gcAddDObjAnimJoint(dobj, Grdisplay.grDisplayPtrAdd(Grcommonsetup.gGRCommonStruct.jungle.map_head, offset), 0.0)
	ObjAnim.gcParseDObjAnimJoint(dobj)
	Grdisplay.gcPlayDObjAnimJoint(dobj)

## 0x80109CFC
static func grJungleTaruCannAddAnimFill(ground_gobj = null) -> void:
	grJungleTaruCannAddAnimOffset(ground_gobj, llGRJungleMapTaruCannFillAnimJoint)

## 0x80109D20
static func grJungleTaruCannAddAnimShoot(ground_gobj = null) -> void:
	grJungleTaruCannAddAnimOffset(ground_gobj, llGRJungleMapTaruCannShootAnimJoint)

## 0x80109D44
static func grJungleTaruCannUpdateMove(ground_gobj = null) -> void:
	var jungle: Dictionary = Grcommonsetup.gGRCommonStruct.jungle

	jungle.tarucann_wait = (jungle.tarucann_wait - 1) & 0xFFFF   # u16

	if jungle.tarucann_wait == 0:
		jungle.tarucann_status = nGRJungleTaruCannStatusRotate

		jungle.tarucann_rotate_step = 0.07 if ((syUtilsRandUShort() % 2) != 0) else -0.07

		jungle.tarucann_wait = 90

## 0x80109DBC
static func grJungleTaruCannUpdateRotate(ground_gobj = null) -> void:
	var jungle: Dictionary = Grcommonsetup.gGRCommonStruct.jungle
	var dobj: DObj = DObjGetStruct(ground_gobj)

	jungle.tarucann_wait = (jungle.tarucann_wait - 1) & 0xFFFF   # u16

	if jungle.tarucann_wait == 0:
		jungle.tarucann_status = nGRJungleTaruCannStatusMove

		jungle.tarucann_wait = syUtilsRandIntRange(180) + 180

		dobj.rotate.z = F_CST_DTOR32(0.0)
	else:
		dobj.rotate.z += jungle.tarucann_rotate_step

## 0x80109E34
static func grJungleTaruCannProcUpdate(ground_gobj = null) -> void:
	match Grcommonsetup.gGRCommonStruct.jungle.tarucann_status:
		nGRJungleTaruCannStatusMove:
			grJungleTaruCannUpdateMove(ground_gobj)
		nGRJungleTaruCannStatusRotate:
			grJungleTaruCannUpdateRotate(ground_gobj)

## 0x80109E84
static func grJungleMakeTaruCann() -> void:
	var map_head
	var tarucann_gobj
	var jungle: Dictionary = Grcommonsetup.gGRCommonStruct.jungle
	var gMPCollisionGroundData: Dictionary = Grdisplay.grDisplayGetGroundData()

	map_head = Grdisplay.grDisplayPtrAdd(gMPCollisionGroundData.map_nodes, -llGRJungleMapMapHead)
	jungle.map_head = map_head

	tarucann_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindGround, null, nGCCommonLinkIDGround, GOBJ_PRIORITY_DEFAULT)
	jungle.tarucann_gobj = tarucann_gobj

	Objman.gcAddGObjDisplay(tarucann_gobj, Callable(Objdisplay, &"gcDrawDObjTreeForGObj"), 6, GOBJ_PRIORITY_DEFAULT, ~0)

	Grmodelsetup.grModelSetupGroundDObjs(tarucann_gobj, Grdisplay.grDisplayPtrAdd(map_head, llGRJungleMapMapHead), null, dGRJungleTaruCannTransformKinds)
	Objman.gcAddGObjProcess(tarucann_gobj, Callable(Grdisplay, &"gcPlayAnimAll"), nGCProcessKindFunc, 5)

	Grdisplay.gcAddAnimJointAll(tarucann_gobj, Grdisplay.grDisplayPtrAdd(map_head, llGRJungleMapTaruCannDefaultAnimJoint), 0.0)
	Grdisplay.gcPlayAnimAll(tarucann_gobj)

	Objman.gcAddGObjProcess(tarucann_gobj, Callable(Grjungle, &"grJungleTaruCannProcUpdate"), nGCProcessKindFunc, 4)
	Ftmain.ftMainCheckAddGroundObstacle(tarucann_gobj, Callable(Grjungle, &"grJungleTaruCannCheckGetDamageKind"))

	jungle.tarucann_status = nGRJungleTaruCannStatusMove
	jungle.tarucann_wait = syUtilsRandIntRange(180) + 180
	jungle.tarucann_rotate_step = F_CST_DTOR32(0.0)

## 0x80109FB4
static func grJungleMakeGround():
	grJungleMakeTaruCann()

	return null

## 0x80109FD8 - obstacle proc_update: returns {"ret": sb32, "kind": s32} (Ftmain convention)
static func grJungleTaruCannCheckGetDamageKind(ground_gobj = null, fighter_gobj = null) -> Dictionary:
	var this_fp := ftGetStruct(fighter_gobj)
	var dist_x: float
	var dist_y: float

	if (this_fp.tarucann_wait == 0) and (this_fp.status_id != nFTCommonStatusTaruCann) and not (this_fp.capture_immune_mask & FTCATCHKIND_MASK_TARUCANN):
		var gr_dobj: DObj = DObjGetStruct(ground_gobj)
		var ft_dobj: DObj = DObjGetStruct(fighter_gobj)

		if gr_dobj.translate.x < ft_dobj.translate.x:
			dist_x = -(gr_dobj.translate.x - ft_dobj.translate.x)
		else:
			dist_x = gr_dobj.translate.x - ft_dobj.translate.x

		if gr_dobj.translate.y < ft_dobj.translate.y:
			dist_y = -(gr_dobj.translate.y - ft_dobj.translate.y)
		else:
			dist_y = gr_dobj.translate.y - ft_dobj.translate.y

		if (dist_x < 280.0) and (dist_y < 280.0):
			for other_gobj in Sim.get_link(nGCCommonLinkIDFighter):
				if other_gobj != fighter_gobj:
					var other_fp := ftGetStruct(other_gobj)

					if (other_fp.status_id == nFTCommonStatusTaruCann) and (ground_gobj == other_fp.status_vars.common.tarucann.tarucann_gobj):
						return {"ret": FALSE, "kind": 0}

			grJungleTaruCannAddAnimFill(ground_gobj)

			return {"ret": TRUE, "kind": nGMHitEnvironmentTaruCann}

	return {"ret": FALSE, "kind": 0}

## 0x8010A104 - void, one out-param (pos) -> returns the position
static func grJungleTaruCannGetPosition(pos = null) -> Vector3:
	return DObjGetStruct(Grcommonsetup.gGRCommonStruct.jungle.tarucann_gobj).translate

## 0x8010A12C
static func grJungleTaruCannGetRotate() -> float:
	return DObjGetStruct(Grcommonsetup.gGRCommonStruct.jungle.tarucann_gobj).rotate.z

# BEGIN GENERATED FILE IMAGES (tools/port/gr/gen_gr_file_images.py - do not edit by hand)
## relocData words read by the ground code, from baserom.us.z64 (US v1.0, SHA-1 e2929e10fccc0aa84e5776227e798abc07cedabf).
## Same bytes as the typed C in sources/ssb-decomp-re/src/relocData/<file>.c. "w": {byte_offset: [u32 words]},
## "p": relocated pointer slots {byte_offset: [file_id, byte_offset, kind]} (kind 1 AObjEvent32, 2 SYInterpDesc, 0 other).
const dGRJungleFileImages: Array = [
	{"fid": 108, "name": "StageJungleFile2", "w": {
		0x8B18: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00002001, 0x00000000, 0x445FF2DF, 0xC3010001, 0xC48678BB, 0x00000000, 0x00000000,
			0x3EB2B8C7, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002001, 0x00000000, 0xC4568B06, 0xC3040001,
			0xC481AF11, 0x00000000, 0x00000000, 0xBEB2B8C7, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002001,
			0x00000000, 0x43A115EA, 0xC390FC76, 0xC47DC68A, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x00002001, 0x00000000, 0xC3906861, 0xC3960003, 0xC466D6EE, 0x00000000,
			0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002001, 0x00000000, 0x4309E44E,
			0xC3960000, 0xC44A3616, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000,
			0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0xC4D22DA4, 0x410896CE, 0xC445B46A,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0x44D1D25C, 0x410896CE, 0xC445B46A, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00002001, 0x00000000, 0xC4D2267F, 0x00000000, 0xC4459290, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002001, 0x00000000, 0x44D1D981, 0x00000000,
			0xC4459290, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002001,
			0x00000000, 0xC4D1FFDA, 0xB894E5D6, 0xC4452DE5, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x00002001, 0x00000000, 0x44D25FFE, 0xB81F6230, 0xC4458342, 0x00000000,
			0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0xC4D26BF5,
			0xBEA81451, 0xC4283A88, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000,
			0x00000001, 0x00000000, 0x44D25401, 0xBEA81451, 0xC4283A88, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000],
		0x9878: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x43B70001, 0x44AD9829, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0xC3B70001, 0x44AD6382, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x9B20: [0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0xC7D8: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000012, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0xD188: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00002001, 0x00000000, 0xC4C1E2D5, 0x404000B4, 0x4447C238,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002001, 0x00000000,
			0x44C66005, 0x360637BD, 0x4460F151, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000001, 0x00000000, 0x3E5DE58E, 0xC3960002, 0x44735612, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002001, 0x00000000, 0xC4AAFFFB, 0xB84D8559,
			0x4475B74E, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002001,
			0x00000000, 0x44DEBFEF, 0xB60637BD, 0x4482D8A5, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x00002001, 0x00000000, 0xC4CA2000, 0x385A1A93, 0x448698AB, 0x00000000,
			0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002001, 0x00000000, 0x44AB6004,
			0x00000000, 0x448A58A1, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000,
			0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		}, "p": {
		0x8B48: [108, 0x7E90, 0],
		0x8B74: [108, 0x80D8, 0],
		0x8BA0: [108, 0x8228, 0],
		0x8BCC: [108, 0x82B8, 0],
		0x8BF8: [108, 0x82D8, 0],
		0x8C24: [108, 0x8338, 0],
		0x8C50: [108, 0x83A8, 0],
		0x8C7C: [108, 0x8418, 0],
		0x8CA8: [108, 0x84B8, 0],
		0x8CD4: [108, 0x8548, 0],
		0x8D00: [108, 0x8568, 0],
		0x8D2C: [108, 0x8600, 0],
		0x8D58: [108, 0x8638, 0],
		0x8D84: [108, 0x87E0, 0],
		0x8DB0: [108, 0x8960, 0],
		0x8DDC: [108, 0x8A08, 0],
		0x8E08: [108, 0x8A50, 0],
		0x98A8: [108, 0x9360, 0],
		0x98D4: [108, 0x94C8, 0],
		0x9900: [108, 0x95D8, 0],
		0x9B24: [108, 0x9B30, 1],
		0x9B28: [108, 0xAF18, 1],
		0xC808: [108, 0xC480, 0],
		0xC834: [108, 0xC718, 0],
		0xD1B8: [108, 0xCC90, 0],
		0xD1E4: [108, 0xCD68, 0],
		0xD210: [108, 0xCDD8, 0],
		0xD23C: [108, 0xCED0, 0],
		0xD268: [108, 0xCF50, 0],
		0xD294: [108, 0xCFC0, 0],
		0xD2C0: [108, 0xD020, 0],
		0xD2EC: [108, 0xD080, 0],
		}},
	{"fid": 158, "name": "StageJungleFile3", "w": {
		0x0A98: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00004001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000],
		0x0B20: [0x00000000, 0x00000000, 0x12080000, 0x455D4000, 0x14300000, 0xC4C7B000, 0x00000000, 0x100800F9,
			0xC55D4000, 0x100800FA, 0x455D4000, 0x1C000000, 0x00000000],
		0x0B68: [0x12C00000, 0x3F800000, 0x3F800000, 0x06120000, 0x00000000, 0x00000000, 0x12C00003, 0x3F8A305A,
			0x3F5EC79D, 0x08020024, 0x00000000, 0x06100003, 0xC3520000, 0x0CC00003, 0x3F800000, 0xBABA4F93,
			0x3F800000, 0x3B17DD33, 0x06100003, 0x43070000, 0x08C00035, 0x3F800000, 0x3F800000, 0x06100003,
			0xC2B40000, 0x06100003, 0x42100000, 0x06100002, 0xC1C00000, 0x06100002, 0x00000000, 0x00000000],
		0x0BF8: [0x14020000, 0xC0C90FDB, 0x0AD00000, 0x00000000, 0xC31113ED, 0x3F800000, 0x3C9B5D92, 0x3F800000,
			0xBB550F50, 0x0AD00004, 0xC3A50000, 0x3FB974BC, 0x40066666, 0xBD5E9239, 0x3F4FBA88, 0x3D9F49F7,
			0x08100005, 0x43E10000, 0x0C800005, 0x3FD9999A, 0x3C32A7A1, 0x0A400001, 0x3F333333, 0xBBAEBF0D,
			0x0A400004, 0x3F99999A, 0x3D98F164, 0x08100004, 0xC32E0000, 0x0AC00003, 0x3F56703B, 0xBC0DB10B,
			0x3F660F7C, 0xBD945183, 0x0C400002, 0x3FC00000, 0x3D806344, 0x0C800005, 0x3F8FB54D, 0x3C4F8421,
			0x04000001, 0x08100005, 0x43070000, 0x04000001, 0x0A400003, 0x3F834939, 0xBE58BC8D, 0x0CC00003,
			0x3F800000, 0xB986987B, 0x3F800000, 0xBAA0CE3F, 0x04000001, 0x08100003, 0xC2960000, 0x04000002,
			0x00000000],
		}, "p": {
		0x0AC8: [158, 0x0A08, 0],
		0x0B20: [158, 0x0B28, 1],
		0x0B50: [158, 0x0B28, 1],
		}},
]
# END GENERATED FILE IMAGES
