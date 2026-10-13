## 1:1 port of src/gr/grcommon/gryoster.c (Yoshi's Island evaporating clouds).
## The cloud collision lines are yakumono 1-3; the cloud solidity timing depends on the clouds'
## material (MObj) animations, run by Grdisplay.gcPlayAnimAll.
class_name Gryoster
extends Port

## relocData symbols (tools/relocFileDescriptions.us.txt [263] GRYosterMap)
const llGRYosterMapMapHead := 0x100
const llGRYosterMap_1E0_AnimJoint := 0x1E0
const llGRYosterMap_4B8_MObjSub := 0x4B8
const llGRYosterMapCloudDisplayList := 0x580
const llGRYosterMapCloudSolidMatAnimJoint := 0x670
const llGRYosterMapCloudEvaporateMatAnimJoint := 0x690

## Particle bank ROM addresses (src/gr/grcommon/gryoster.h)
const lGRYosterParticleScriptBankLo := 0x00B22980
const lGRYosterParticleScriptBankHi := 0x00B22A00
const lGRYosterParticleTextureBankLo := 0x00B22A00
const lGRYosterParticleTextureBankHi := 0x00B22C30

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8012EB20
static var dGRYosterCloudMatAnimJoints: Array = [llGRYosterMapCloudSolidMatAnimJoint, llGRYosterMapCloudEvaporateMatAnimJoint]

## 0x8012EB28
static var dGRYosterCloudLineIDs: Array = [0x1, 0x2, 0x3]

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

const nGRYosterCloudStatusSolid := 0
const nGRYosterCloudStatusEvaporate := 1

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80108550 - pos: Vector3 (read only); returns the LBGenerator or null
static func grYosterCloudVaporMakeEffect(pos = null):
	var gn = Grdisplay.lbParticleMakeGenerator(Grcommonsetup.gGRCommonStruct.yoster.particle_bank_id, 0)

	if gn != null:
		gn.pos.x = pos.x
		gn.pos.y = pos.y
		gn.pos.z = pos.z

	return gn

## 0x801085A8
static func grYosterCheckFighterCloudStand(cloud_id = null) -> int:
	var line_id: int = dGRYosterCloudLineIDs[cloud_id]

	for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		var fp := ftGetStruct(fighter_gobj)

		if fp.ga == nMPKineticsGround:
			if (fp.coll_data.floor_line_id != -2) and (Mpcollision.mpCollisionSetDObjNoID(fp.coll_data.floor_line_id) == line_id):
				return TRUE

	return FALSE

## 0x80108634
static func grYosterUpdateCloudSolid(cloud_id = null) -> void:
	var pos: Vector3
	var dobj: DObj
	var cloud: Dictionary = Grcommonsetup.gGRCommonStruct.yoster.clouds[cloud_id]

	# clouds[cloud_id].dobj[0]->mobj->anim_wait
	var mobjs: Array = Grdisplay.grDisplayGetMObjs(cloud.dobj[0])
	var mobj_anim_wait: float = mobjs[0].anim_wait if not mobjs.is_empty() else AOBJ_ANIM_NULL

	if mobj_anim_wait == AOBJ_ANIM_NULL:
		if cloud.is_cloud_line_active == FALSE:
			Mpcollision.mpCollisionSetYakumonoOnID(dGRYosterCloudLineIDs[cloud_id])

			cloud.is_cloud_line_active = TRUE

		if cloud.pressure_timer == 0:
			cloud.status = nGRYosterCloudStatusEvaporate
			cloud.anim_id = nGRYosterCloudStatusEvaporate
			cloud.evaporate_wait = 180

			pos = DObjGetStruct(cloud.gobj).translate

			pos.x += (-750.0)
			pos.y += (-350.0)

			grYosterCloudVaporMakeEffect(pos)

			Snd.func_800269C0_275C0(nSYAudioFGMYosterCloudVapor)
		else:
			if grYosterCheckFighterCloudStand(cloud_id) != FALSE:
				if cloud.pressure_timer == -1:
					cloud.pressure_timer = 120

				cloud.pressure += 5.0

				if cloud.pressure > 180.0:
					cloud.pressure = 180.0
			else:
				cloud.pressure_timer = -1
				cloud.pressure -= 5.0

				if cloud.pressure < 0.0:
					cloud.pressure = 0.0

			if cloud.pressure_timer > 0:
				cloud.pressure_timer -= 1   # s8

	dobj = DObjGetStruct(cloud.gobj)
	dobj.translate.y = cloud.altitude - cloud.pressure

	Mpcollision.mpCollisionSetYakumonoPosID(dGRYosterCloudLineIDs[cloud_id], dobj.translate)

## 0x80108814
static func grYosterUpdateCloudEvaporate(cloud_id = null) -> void:
	var cloud: Dictionary = Grcommonsetup.gGRCommonStruct.yoster.clouds[cloud_id]

	if cloud.is_cloud_line_active != FALSE:
		Mpcollision.mpCollisionSetYakumonoOffID(dGRYosterCloudLineIDs[cloud_id])

		cloud.is_cloud_line_active = FALSE

	if cloud.evaporate_wait == 0:
		cloud.status = nGRYosterCloudStatusSolid
		cloud.anim_id = nGRYosterCloudStatusSolid
		cloud.pressure_timer = -1
		cloud.pressure = 0.0
	else:
		cloud.evaporate_wait = (cloud.evaporate_wait - 1) & 0xFF   # u8

## 0x80108890
static func grYosterUpdateCloudAnim(cloud_id = null) -> void:
	var cloud: Dictionary = Grcommonsetup.gGRCommonStruct.yoster.clouds[cloud_id]
	var anim_id: int = cloud.anim_id

	if anim_id != -1:
		var map_head = Grcommonsetup.gGRCommonStruct.yoster.map_head

		for i in cloud.dobj.size():
			var dobj: DObj = cloud.dobj[i]

			Grdisplay.lbCommonAddTreeDObjsAnimAll(dobj, null, Grdisplay.grDisplayPtrAdd(map_head, dGRYosterCloudMatAnimJoints[anim_id]), 0.0)
			Grdisplay.gcPlayDObjAnimJoint(dobj)

		cloud.anim_id = -1

## 0x80108960
static func grYosterProcUpdate(ground_gobj = null) -> void:
	var clouds: Array = Grcommonsetup.gGRCommonStruct.yoster.clouds

	for i in clouds.size():
		match clouds[i].status:
			nGRYosterCloudStatusSolid:
				grYosterUpdateCloudSolid(i)
			nGRYosterCloudStatusEvaporate:
				grYosterUpdateCloudEvaporate(i)

		grYosterUpdateCloudAnim(i)

## 0x801089F4
static func grYosterInitAll() -> void:
	var cloud_dobj: DObj
	var map_gobj
	var coll_dobj: DObj
	var map_head
	var yoster: Dictionary = Grcommonsetup.gGRCommonStruct.yoster
	var gMPCollisionGroundData: Dictionary = Grdisplay.grDisplayGetGroundData()

	map_head = Grdisplay.grDisplayPtrAdd(gMPCollisionGroundData.map_nodes, -llGRYosterMapMapHead)
	yoster.map_head = map_head

	for i in yoster.clouds.size():
		var cloud: Dictionary = yoster.clouds[i]

		map_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindGround, null, nGCCommonLinkIDGround, GOBJ_PRIORITY_DEFAULT)

		cloud.gobj = map_gobj

		Objman.gcAddGObjDisplay(map_gobj, Callable(Objdisplay, &"gcDrawDObjTreeForGObj"), 6, GOBJ_PRIORITY_DEFAULT, ~0)
		Grdisplay.gcSetupCustomDObjs(
			map_gobj,
			Grdisplay.grDisplayPtrAdd(map_head, llGRYosterMapMapHead),
			null,
			nGCMatrixKindTra,    # Make this nGCMatrixKindTraRotRpyRSca to see cloud scale animation
			nGCMatrixKindNull,
			nGCMatrixKindNull
		)
		Objman.gcAddGObjProcess(map_gobj, Callable(Grdisplay, &"gcPlayAnimAll"), nGCProcessKindFunc, 5)

		Grdisplay.gcAddAnimJointAll(map_gobj, Grdisplay.grDisplayPtrAdd(map_head, llGRYosterMap_1E0_AnimJoint), 0)

		coll_dobj = DObjGetStruct(map_gobj)
		if coll_dobj == null:
			push_error("grYosterInitAll: cloud DObjDesc data missing (StageYosterFile3 MapHead)")
			return
		var yakumono_dobj: DObj = Grdisplay.grDisplayGetYakumonoDObj(dGRYosterCloudLineIDs[i])
		if yakumono_dobj != null:
			coll_dobj.translate = yakumono_dobj.translate   # gMPCollisionYakumonoDObjs->dobjs[line]->translate

		cloud.altitude = coll_dobj.translate.y

		coll_dobj = coll_dobj.child

		for j in cloud.dobj.size():
			cloud_dobj = Objman.gcAddChildForDObj(coll_dobj, Grdisplay.grDisplayPtrAdd(map_head, llGRYosterMapCloudDisplayList))
			cloud.dobj[j] = cloud_dobj

			Grdisplay.grDisplayAddXObj(cloud_dobj, nGCMatrixKindTra, 0)
			Grdisplay.grDisplayAddXObj(cloud_dobj, nGCMatrixKind48, 0)
			Grdisplay.lbCommonAddMObjForTreeDObjs(cloud_dobj, Grdisplay.grDisplayPtrAdd(map_head, llGRYosterMap_4B8_MObjSub))

			coll_dobj = coll_dobj.sib_next

		Grdisplay.gcPlayAnimAll(map_gobj)

		cloud.status = nGRYosterCloudStatusSolid
		cloud.anim_id = nGRYosterCloudStatusSolid
		cloud.pressure_timer = -1
		cloud.is_cloud_line_active = FALSE
		cloud.pressure = 0.0

		Mpcollision.mpCollisionSetYakumonoOnID(dGRYosterCloudLineIDs[i])

	yoster.particle_bank_id = Grdisplay.efParticleGetLoadBankID(lGRYosterParticleScriptBankLo, lGRYosterParticleScriptBankHi, lGRYosterParticleTextureBankLo, lGRYosterParticleTextureBankHi)

## 0x80108C80
static func grYosterMakeGround():
	var ground_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindGround, null, nGCCommonLinkIDGround, GOBJ_PRIORITY_DEFAULT)

	grYosterInitAll()
	Objman.gcAddGObjProcess(ground_gobj, Callable(Gryoster, &"grYosterProcUpdate"), nGCProcessKindFunc, 4)

	return ground_gobj

# BEGIN GENERATED FILE IMAGES (tools/port/gr/gen_gr_file_images.py - do not edit by hand)
## relocData words read by the ground code, from baserom.us.z64 (US v1.0, SHA-1 e2929e10fccc0aa84e5776227e798abc07cedabf).
## Same bytes as the typed C in sources/ssb-decomp-re/src/relocData/<file>.c. "w": {byte_offset: [u32 words]},
## "p": relocated pointer slots {byte_offset: [file_id, byte_offset, kind]} (kind 1 AObjEvent32, 2 SYInterpDesc, 0 other).
const dGRYosterFileImages: Array = [
	{"fid": 111, "name": "StageYosterFile2", "w": {
		0x0E00: [0x00000000, 0x00000000, 0x38EF1349, 0x00000000, 0x38EF1349, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x445DD99D, 0x44870000, 0xC4E0FFFF,
			0x00000000, 0x00000000, 0x40C90FDA, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0xC4BB8003, 0x42700004, 0xC4C60009, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x39345AE6, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x430AB0AB, 0x4461E669,
			0xC4696663, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x42266DBD, 0x4390DB3B, 0xC4514D6F, 0x00000000,
			0x00000000, 0x403DE450, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x44262E96,
			0x43DCAF95, 0xC4514D6F, 0x00000000, 0x00000000, 0x407B53D2, 0x3F800000, 0x3F800000, 0x3F800000,
			0x00000001, 0x00000000, 0xC3E759E3, 0x43FFF7C5, 0xC4514D70, 0x00000000, 0x00000000, 0x4016CBE2,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x44451326, 0x446D8338, 0xC4514D70,
			0x00000000, 0x00000000, 0x4096CBE4, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0xC404DD0F, 0x446D8338, 0xC4514D70, 0x00000000, 0x00000000, 0x3FC90FD8, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000001, 0x00000000, 0x44262E96, 0x44B0366E, 0xC4514D70, 0x00000000, 0x00000000,
			0x40AFEDDF, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0xC3DEA4EF, 0x44B0DA50,
			0xC4514D70, 0x00000000, 0x00000000, 0x3F490FD8, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001,
			0x00000000, 0x42AF9F22, 0x44C39732, 0xC4514D70, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0xC571E002, 0x44E4C000, 0xC3F0000B, 0x00000000,
			0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000, 0x00000000,
			0x3A15F245, 0xB86F1349, 0x00000000, 0x00000000, 0x00000000, 0x3F888BFC, 0x3FA633F0, 0x3F888BFC,
			0x00000001, 0x00000000, 0x456E2000, 0x453B7FFF, 0xC3EFFFFD, 0x00000000, 0x00000000, 0x00000000,
			0x3F933333, 0x3F933333, 0x3F800000, 0x00000002, 0x00000000, 0xBA3417CA, 0x3A3417CA, 0xB86F1349,
			0x00000000, 0x00000000, 0x00000000, 0x3F888BFC, 0x3FA633F0, 0x3F888BFC, 0x00000012, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000],
		0x1150: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000],
		0x4E78: [0x00000000, 0x00000000, 0x38EF1349, 0x00000000, 0x3995F245, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x45E53800, 0xC2700170, 0x00000000,
			0x358637BD, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0x4570F000, 0x44EFFFF7, 0x00000000, 0x358637BD, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000001, 0x00000000, 0xC5778036, 0x4442FFF8, 0x00000000, 0x358637BD, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000],
		0x5448: [0x00000000, 0x00000000, 0x38EF1349, 0x00000000, 0x38EF1349, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000],
		0x5C38: [0x00000000, 0x00000000, 0x38EF1349, 0x00000000, 0x3995F245, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000012, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000],
		}, "p": {
		0x0E30: [111, 0x0558, 0],
		0x0E5C: [111, 0x0618, 0],
		0x0E88: [111, 0x0640, 0],
		0x0EB4: [111, 0x08A0, 0],
		0x0EE0: [111, 0x0938, 0],
		0x0F0C: [111, 0x0A90, 0],
		0x0F38: [111, 0x0B10, 0],
		0x0F64: [111, 0x0B30, 0],
		0x0F90: [111, 0x0B58, 0],
		0x0FBC: [111, 0x0B78, 0],
		0x0FE8: [111, 0x0B98, 0],
		0x1014: [111, 0x0BB8, 0],
		0x1040: [111, 0x0BD8, 0],
		0x1098: [111, 0x0C20, 0],
		0x10F0: [111, 0x0D10, 0],
		0x1154: [111, 0x1198, 1],
		0x1158: [111, 0x11B0, 1],
		0x1160: [111, 0x11C8, 1],
		0x1168: [111, 0x1238, 1],
		0x116C: [111, 0x160C, 1],
		0x1170: [111, 0x1A28, 1],
		0x1174: [111, 0x1DFC, 1],
		0x1178: [111, 0x2094, 1],
		0x117C: [111, 0x233C, 1],
		0x1180: [111, 0x2728, 1],
		0x1184: [111, 0x2AFC, 1],
		0x1188: [111, 0x2DA4, 1],
		0x118C: [111, 0x2E48, 1],
		0x1190: [111, 0x3290, 1],
		0x1194: [111, 0x3334, 1],
		0x4F2C: [111, 0x49A0, 0],
		0x5478: [111, 0x52F0, 0],
		0x5C68: [111, 0x58C0, 0],
		0x5C94: [111, 0x5A08, 0],
		}},
	{"fid": 154, "name": "StageYosterFile3", "w": {
		0x0100: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0xC3C30000, 0xC3960016, 0xB91F6230,
			0x358637BD, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0x43C30000, 0xC3A50017, 0xB90B75EA, 0x358637BD, 0x00000000, 0x00000000, 0x3F8BE76D, 0x3F8BE76D,
			0x3F800000, 0x00000001, 0x00000000, 0x41EFFFF8, 0xC3C30017, 0x426FFFD4, 0x358637BD, 0x00000000,
			0x00000000, 0x3F8BE76D, 0x3F8BE76D, 0x3F800000, 0x00000012, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x01E0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x10C00000, 0x3F800000, 0x3F800000, 0x10C00017,
			0x3F9080F3, 0x3F9080F3, 0x10C00016, 0x3F800000, 0x3F800000, 0x1C000000, 0x00000000, 0x0AC00000,
			0x3F8BE76D, 0x3C080406, 0x3F8BE76D, 0x3C080406, 0x10C00007, 0x3F9080F3, 0x3F9080F3, 0x10C00017,
			0x3F800000, 0x3F800000, 0x0AC0000F, 0x3F8BE76D, 0x3BF9F44D, 0x3F8BE76D, 0x3BF9F44D, 0x1C000000,
			0x00000000, 0x0AC00000, 0x3F8BE76D, 0xBC3B8DCA, 0x3F8BE76D, 0xBC412490, 0x10C0000E, 0x3F800000,
			0x3F800000, 0x10C00017, 0x3F9080F3, 0x3F9080F3, 0x0AC00008, 0x3F8BE76D, 0xBBF9F44D, 0x3F8BE76D,
			0xBBF9F44D, 0x1C000000, 0x00000000],
		0x04B8: [0x00000000],
		0x04C0: [0x00000402, 0x00000000, 0x00200000, 0x00400040, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x00000000, 0x3F800000, 0x00000000, 0x02000400, 0x00200020, 0x00400040, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00002205, 0xFFFFFF00, 0x00000000, 0x0000FFFF, 0x00000008,
			0xFFFFFF00, 0x26262600, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x0670: [0x00000000, 0x28008000, 0xFFFFFF00, 0x28008064, 0xFFFFFFFF, 0x00000000, 0x00000000],
		0x0690: [0x00000000, 0x28008000, 0xFFFFFFFF, 0x28008064, 0xFFFFFF00, 0x00000000, 0x00000000],
		}, "p": {
		0x01E4: [154, 0x01F0, 1],
		0x01E8: [154, 0x021C, 1],
		0x01EC: [154, 0x0264, 1],
		0x0218: [154, 0x01F0, 1],
		0x0260: [154, 0x021C, 1],
		0x02A8: [154, 0x0264, 1],
		0x04B8: [154, 0x0538, 0],
		0x0538: [154, 0x04C0, 0],
		0x0670: [154, 0x0688, 0],
		0x0688: [154, 0x0674, 1],
		0x0690: [154, 0x06A8, 0],
		0x06A8: [154, 0x0694, 1],
		}},
]
# END GENERATED FILE IMAGES
