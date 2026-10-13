## 1:1 port of src/gr/grcommon/grinishie.c (Mushroom Kingdom: balance-scale platforms, Piranha Plants, POW block).
class_name Grinishie
extends Port

## relocData symbols (tools/relocFileDescriptions.us.txt [260] GRInishieMap)
const llGRInishieMapMapHeader := 0x14
const llGRInishieMapScaleDObjDesc := 0x380
const llGRInishieMapMapHead := 0x5F0
const llGRInishieMapScaleRetractAnimJoint := 0x734
const llGRInishieMapPowerBlockGRAttackColl := 0x0BC

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8012EB30
static var dGRInishieScaleMapObjKinds: Array = [nMPMapObjKindScaleL, nMPMapObjKindScaleR]

## 0x8012EB34
static var dGRInishieScaleLineGroups: Array = [0x01, 0x02]

## 0x8012EB38
static var dGRInishieScaleTransformKinds: Array = [
	{"tk1": nGCMatrixKindTra, "tk2": nGCMatrixKindNull, "tk3": 0x01},
	{"tk1": nGCMatrixKindTra, "tk2": nGCMatrixKindNull, "tk3": 0x01},
	{"tk1": nGCMatrixKindTra, "tk2": nGCMatrixKindNull, "tk3": 0x00},
	{"tk1": nGCMatrixKindTra, "tk2": nGCMatrixKindNull, "tk3": 0x01},
	{"tk1": nGCMatrixKindTra, "tk2": nGCMatrixKindNull, "tk3": 0x00},
]

## 0xx8012EB48
static var dGRInishiePakkunMapObjKinds: Array = [nMPMapObjKindPakkunL, nMPMapObjKindPakkunR]

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

const nGRInishieScaleStatusWait := 0
const nGRInishieScaleStatusFall := 1
const nGRInishieScaleStatusSleep := 2
const nGRInishieScaleStatusRetract := 3

const nGRInishiePowerBlockStatusWait := 0
const nGRInishiePowerBlockStatusMake := 1
const nGRInishiePowerBlockStatusSleep := 2
const nGRInishiePowerBlockStatusDamage := 3

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80108CD0
static func grInishieScaleUpdateFighterStatsGA() -> void:
	var inishie: Dictionary = Grcommonsetup.gGRCommonStruct.inishie

	for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		var fp := ftGetStruct(fighter_gobj)
		var player: int = fp.player

		if fp.ga == nMPKineticsGround:
			if inishie.players_ga[player] != nMPKineticsGround:
				inishie.players_tt[player] = 1
			elif inishie.players_tt[player] != 0:
				inishie.players_tt[player] = (inishie.players_tt[player] - 1) & 0xFF   # u8
		else:
			inishie.players_tt[player] = 0

		inishie.players_ga[player] = fp.ga

## 0x80108D50
static func grInishieScaleGetPressure(line_id = null) -> float:
	var inishie: Dictionary = Grcommonsetup.gGRCommonStruct.inishie
	var pressure := 0.0

	for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		var fp := ftGetStruct(fighter_gobj)

		if fp.ga == nMPKineticsGround:
			if (fp.coll_data.floor_line_id != -2) and (Mpcollision.mpCollisionSetDObjNoID(fp.coll_data.floor_line_id) == line_id):
				var weight: float = (1.0 - fp.attr.weight) + 1.4

				if inishie.players_tt[fp.player] != 0:
					pressure += (weight * 8.0)
				else:
					pressure += weight

	return pressure

## 0x801085E0
static func grInishieScaleUpdateWait() -> void:
	var inishie: Dictionary = Grcommonsetup.gGRCommonStruct.inishie
	var l_dobj: DObj
	var r_dobj: DObj
	var l_weight: float
	var r_weight: float
	var alt: float
	var ud: int

	grInishieScaleUpdateFighterStatsGA()

	l_weight = grInishieScaleGetPressure(dGRInishieScaleLineGroups[0])
	r_weight = grInishieScaleGetPressure(dGRInishieScaleLineGroups[1])

	if (l_weight == 0.0) and (r_weight == 0.0):
		if inishie.splat_alt != 0.0:
			if inishie.splat_alt < 0.0:
				inishie.splat_alt += 8.0

				if inishie.splat_alt > 0.0:
					inishie.splat_alt = 0.0
			else:
				inishie.splat_alt -= 8.0

				if inishie.splat_alt < 0.0:
					inishie.splat_alt = 0.0

		inishie.splat_accelerate = 0.0
	else:
		inishie.splat_accelerate += (r_weight - l_weight)

		if (l_weight != 0.0) and (r_weight != 0.0) and (inishie.splat_accelerate != 0.0):
			inishie.splat_accelerate *= 0.93
		elif inishie.splat_accelerate > 0.0:
			inishie.splat_accelerate -= 0.9

			if inishie.splat_accelerate < 0.0:
				inishie.splat_accelerate = 0.0
		elif inishie.splat_accelerate < 0.0:
			inishie.splat_accelerate += 0.9

			if inishie.splat_accelerate > 0.0:
				inishie.splat_accelerate = 0.0

		inishie.splat_alt += inishie.splat_accelerate

	alt = ABSF(inishie.splat_alt)

	l_dobj = inishie.scale[0].platform_dobj
	r_dobj = inishie.scale[1].platform_dobj

	if alt > 1100.0:
		ud = 0

		if inishie.splat_alt < 0.0:
			ud = 1

			if inishie.splat_accelerate != 0.0:
				pass   # ??? The permuter found this but I really can't match it otherwise

		inishie.splat_accelerate = 0.0

		if ud != 0:
			inishie.splat_alt = -1100.0
		else:
			inishie.splat_alt = 1100.0

		inishie.splat_status = nGRInishieScaleStatusFall

		Efmanager.efManagerSparkleWhiteScaleMakeEffect(l_dobj.translate, 1.0)
		Efmanager.efManagerSparkleWhiteScaleMakeEffect(r_dobj.translate, 1.0)

	l_dobj.translate.y = inishie.scale[0].platform_base_y + inishie.splat_alt
	r_dobj.translate.y = inishie.scale[1].platform_base_y - inishie.splat_alt

	inishie.scale[0].string_dobj.translate.y = l_dobj.translate.y - inishie.scale[0].string_length
	inishie.scale[1].string_dobj.translate.y = r_dobj.translate.y - inishie.scale[1].string_length

## 0x80109118
static func grInishieScaleUpdateFall() -> void:
	var inishie: Dictionary = Grcommonsetup.gGRCommonStruct.inishie
	var deadzone: float

	inishie.splat_accelerate += 3.0

	if inishie.splat_accelerate > 70.0:
		inishie.splat_accelerate = 70.0

	inishie.scale[0].platform_dobj.translate.y -= inishie.splat_accelerate
	inishie.scale[1].platform_dobj.translate.y -= inishie.splat_accelerate

	deadzone = Grdisplay.grDisplayGetGroundData().map_bound_bottom + (-1000.0)

	if (inishie.scale[0].platform_dobj.translate.y < deadzone) and (inishie.scale[1].platform_dobj.translate.y < deadzone):
		inishie.splat_status = nGRInishieScaleStatusSleep
		inishie.splat_accelerate = 0.0

		Mpcollision.mpCollisionSetYakumonoOffID(dGRInishieScaleLineGroups[0])
		Mpcollision.mpCollisionSetYakumonoOffID(dGRInishieScaleLineGroups[1])

		inishie.splat_wait = 180

## 0x80109220
static func grInishieScaleUpdateStep() -> void:
	var inishie: Dictionary = Grcommonsetup.gGRCommonStruct.inishie

	inishie.splat_wait = (inishie.splat_wait - 1) & 0xFFFF   # u16

	if inishie.splat_wait == 0:
		inishie.splat_status = nGRInishieScaleStatusRetract

		Grdisplay.gcAddDObjAnimJoint(inishie.scale[0].platform_dobj, Grdisplay.grDisplayPtrAdd(inishie.map_head, llGRInishieMapScaleRetractAnimJoint), 0.0)
		Grdisplay.gcAddDObjAnimJoint(inishie.scale[1].platform_dobj, Grdisplay.grDisplayPtrAdd(inishie.map_head, llGRInishieMapScaleRetractAnimJoint), 0.0)

## 0x8010929C
static func grInishieScaleUpdateRetract() -> void:
	var inishie: Dictionary = Grcommonsetup.gGRCommonStruct.inishie
	var l_dobj: DObj
	var r_dobj: DObj
	var is_complete := FALSE

	if inishie.splat_alt != 0.0:
		if inishie.splat_alt < 0.0:
			inishie.splat_alt += 10.0

			if inishie.splat_alt >= 0.0:
				is_complete = TRUE
		else:
			inishie.splat_alt -= 10.0

			if inishie.splat_alt <= 0.0:
				is_complete = TRUE

	l_dobj = inishie.scale[0].platform_dobj
	r_dobj = inishie.scale[1].platform_dobj

	if is_complete != FALSE:
		inishie.splat_alt = 0.0

		l_dobj.anim_wait = AOBJ_ANIM_NULL
		l_dobj.flags = DOBJ_FLAG_NONE

		Mpcollision.mpCollisionSetYakumonoOnID(dGRInishieScaleLineGroups[0])

		r_dobj.anim_wait = AOBJ_ANIM_NULL
		r_dobj.flags = DOBJ_FLAG_NONE

		Mpcollision.mpCollisionSetYakumonoOnID(dGRInishieScaleLineGroups[1])

		inishie.splat_status = nGRInishieScaleStatusWait

	l_dobj.translate.y = inishie.scale[0].platform_base_y + inishie.splat_alt
	r_dobj.translate.y = inishie.scale[1].platform_base_y - inishie.splat_alt

	inishie.scale[0].string_dobj.translate.y = l_dobj.translate.y - inishie.scale[0].string_length
	inishie.scale[1].string_dobj.translate.y = r_dobj.translate.y - inishie.scale[1].string_length

## 0x801093EC
static func grInishieScaleProcUpdate(ground_gobj = null) -> void:
	var inishie: Dictionary = Grcommonsetup.gGRCommonStruct.inishie

	match inishie.splat_status:
		nGRInishieScaleStatusWait:
			grInishieScaleUpdateWait()
		nGRInishieScaleStatusFall:
			grInishieScaleUpdateFall()
		nGRInishieScaleStatusSleep:
			grInishieScaleUpdateStep()
		nGRInishieScaleStatusRetract:
			grInishieScaleUpdateRetract()

	Mpcollision.mpCollisionSetYakumonoPosID(dGRInishieScaleLineGroups[0], inishie.scale[0].platform_dobj.translate)
	Mpcollision.mpCollisionSetYakumonoPosID(dGRInishieScaleLineGroups[1], inishie.scale[1].platform_dobj.translate)

## 0x801094A0
static func grInishieMakeScale() -> void:
	var map_head
	var ground_gobj
	var map_dobjs: Array = [null, null, null, null, null]   # DObj *map_dobjs[5]
	var platform_dobj: DObj
	var mapobj: int
	var yakumono_pos: Vector3
	var inishie: Dictionary = Grcommonsetup.gGRCommonStruct.inishie

	map_head = inishie.map_head
	ground_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindGround, null, nGCCommonLinkIDGround, GOBJ_PRIORITY_DEFAULT)

	Objman.gcAddGObjDisplay(ground_gobj, Callable(Objdisplay, &"gcDrawDObjTreeForGObj"), 6, GOBJ_PRIORITY_DEFAULT, ~0)
	Grmodelsetup.grModelSetupGroundDObjs(ground_gobj, Grdisplay.grDisplayPtrAdd(map_head, llGRInishieMapScaleDObjDesc), map_dobjs, dGRInishieScaleTransformKinds)

	inishie.scale[0].string_dobj = map_dobjs[4]
	inishie.scale[0].string_length = map_dobjs[0].translate.y + map_dobjs[3].translate.y

	inishie.scale[1].string_dobj = map_dobjs[2]
	inishie.scale[1].string_length = map_dobjs[0].translate.y + map_dobjs[1].translate.y

	for i in inishie.scale.size():
		ground_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindGround, null, nGCCommonLinkIDGround, GOBJ_PRIORITY_DEFAULT)
		Objman.gcAddGObjDisplay(ground_gobj, Callable(Objdisplay, &"gcDrawDObjDLHead0"), 6, GOBJ_PRIORITY_DEFAULT, ~0)

		platform_dobj = Objman.gcAddDObjForGObj(ground_gobj, Grdisplay.grDisplayPtrAdd(map_head, llGRInishieMapMapHead))
		inishie.scale[i].platform_dobj = platform_dobj

		Grdisplay.grDisplayAddXObj(platform_dobj, nGCMatrixKindTra, 0)
		Objman.gcAddGObjProcess(ground_gobj, Callable(Grdisplay, &"gcPlayAnimAll"), nGCProcessKindFunc, 5)

		mapobj = Grdisplay.grDisplayGetMapObjIDsKind(dGRInishieScaleMapObjKinds[i])[0]
		yakumono_pos = Grdisplay.grDisplayGetMapObjPositionID(mapobj)

		platform_dobj.translate = yakumono_pos

		inishie.scale[i].platform_base_y = yakumono_pos.y

		Mpcollision.mpCollisionSetYakumonoOnID(dGRInishieScaleLineGroups[i])

	# Added to the last platform GObj (ground_gobj of the loop's final iteration), as in the C.
	Objman.gcAddGObjProcess(ground_gobj, Callable(Grinishie, &"grInishieScaleProcUpdate"), nGCProcessKindFunc, 4)

	inishie.splat_status = nGRInishieScaleStatusWait
	inishie.splat_alt = 0.0
	inishie.splat_accelerate = 0.0

	for i in (inishie.players_ga.size() + inishie.players_tt.size()) / 2:
		inishie.players_tt[i] = 0
		inishie.players_ga[i] = 0

## 0x8010972C
static func grInishiePakkunSetWaitFighter() -> void:
	var inishie: Dictionary = Grcommonsetup.gGRCommonStruct.inishie

	for i in inishie.pakkun_gobj.size():
		Itpakkun.itPakkunCommonSetWaitFighter(inishie.pakkun_gobj[i])

## 0x80109774
static func grInishieMakePakkun() -> void:
	var pos: Vector3
	var vel: Vector3
	var mapobj: int
	var inishie: Dictionary = Grcommonsetup.gGRCommonStruct.inishie

	for i in inishie.pakkun_gobj.size():
		mapobj = Grdisplay.grDisplayGetMapObjIDsKind(dGRInishiePakkunMapObjKinds[i])[0]
		pos = Grdisplay.grDisplayGetMapObjPositionID(mapobj)

		vel.x = 0.0
		vel.y = 0.0
		vel.z = 0.0

		inishie.pakkun_gobj[i] = Itmanager.itManagerMakeItemSetupCommon(null, nITKindPakkun, pos, vel, ITEM_FLAG_PARENT_GROUND)

## 0x80109838
static func grInishiePowerBlockUpdateWait() -> void:
	var inishie: Dictionary = Grcommonsetup.gGRCommonStruct.inishie

	if G.gSCManagerBattleState.game_status != nSCBattleGameStatusWait:
		inishie.pblock_status = nGRInishiePowerBlockStatusMake
		inishie.pblock_appear_wait = 1800

## 0x8010986C
static func grInishiePowerBlockSetWait() -> void:
	var inishie: Dictionary = Grcommonsetup.gGRCommonStruct.inishie

	inishie.pblock_status = nGRInishiePowerBlockStatusMake
	inishie.pblock_appear_wait = 1800

## 0x80109888
static func grInishiePowerBlockUpdateMake() -> void:
	var pblock_gobj
	var pos: Vector3
	var vel: Vector3
	var inishie: Dictionary = Grcommonsetup.gGRCommonStruct.inishie

	inishie.pblock_appear_wait = (inishie.pblock_appear_wait - 1) & 0xFFFF   # u16

	if inishie.pblock_appear_wait == 0:
		var pblock_pos_id: int = inishie.pblock_pos_ids[syUtilsRandIntRange(inishie.pblock_pos_count)]

		pos = Grdisplay.grDisplayGetMapObjPositionID(pblock_pos_id)

		vel.x = 0.0
		vel.y = 0.0
		vel.z = 0.0

		pblock_gobj = Itmanager.itManagerMakeItemSetupCommon(null, nITKindPowerBlock, pos, vel, ITEM_FLAG_PARENT_GROUND)

		if pblock_gobj != null:
			inishie.pblock_gobj = pblock_gobj
			inishie.pblock_status = nGRInishiePowerBlockStatusSleep
		else:
			grInishiePowerBlockSetWait()

## 0x8010992C
static func grInishiePowerBlockUpdateDamage() -> void:
	var inishie: Dictionary = Grcommonsetup.gGRCommonStruct.inishie

	inishie.pblock_appear_wait = (inishie.pblock_appear_wait - 1) & 0xFFFF

	if inishie.pblock_appear_wait == 0:
		Ftmain.ftMainClearHazard(inishie.pblock_gobj)

## 0x80109968
static func grInishiePowerBlockProcUpdate(ground_gobj = null) -> void:
	match Grcommonsetup.gGRCommonStruct.inishie.pblock_status:
		nGRInishiePowerBlockStatusWait:
			grInishiePowerBlockUpdateWait()
		nGRInishiePowerBlockStatusMake:
			grInishiePowerBlockUpdateMake()
		nGRInishiePowerBlockStatusDamage:
			grInishiePowerBlockUpdateDamage()

## 0x801099D4
static func grInishieMakePowerBlock() -> void:
	var pos_count: int
	var pos_ids: Array
	var inishie: Dictionary = Grcommonsetup.gGRCommonStruct.inishie
	var gMPCollisionGroundData: Dictionary = Grdisplay.grDisplayGetGroundData()

	Objman.gcAddGObjProcess(Objman.gcMakeGObjSPAfter(nGCCommonKindGround, null, nGCCommonLinkIDGround, GOBJ_PRIORITY_DEFAULT), Callable(Grinishie, &"grInishiePowerBlockProcUpdate"), nGCProcessKindFunc, 4)

	var count_r = Mpcollision.mpCollisionGetMapObjCountKind(nMPMapObjKindPowerBlock)
	pos_count = int(count_r) if count_r != null else 0
	inishie.pblock_pos_count = pos_count & 0xFF   # u8

	if (pos_count == 0) or (pos_count > 10):   # ARRAY_COUNT(pos_ids)
		# while (TRUE) { syDebugPrintf("PowerBlock positions are error!\n"); scManagerRunPrintGObjStatus(); }
		Debug.syDebugPrintf("PowerBlock positions are error!\n")
		push_error("grInishieMakePowerBlock: PowerBlock positions are error! (count %d)" % pos_count)
		inishie.pblock_pos_ids = [0]
	else:
		inishie.pblock_pos_ids = []   # syTaskmanMalloc(pos_count * sizeof(u8), 0x0)
		inishie.pblock_pos_ids.resize(pos_count)

		pos_ids = Grdisplay.grDisplayGetMapObjIDsKind(nMPMapObjKindPowerBlock)

		for i in pos_count:
			inishie.pblock_pos_ids[i] = (pos_ids[i] if i < pos_ids.size() else 0) & 0xFF

	inishie.pblock_status = nGRInishiePowerBlockStatusWait
	# (GRAttackColl*) (((uintptr_t)gMPCollisionGroundData - &llGRInishieMapMapHeader) + &llGRInishieMapPowerBlockGRAttackColl)
	inishie.attack_coll = Grdisplay.grDisplayGetAttackColl(Grdisplay.grDisplayPtrAdd(gMPCollisionGroundData.header, llGRInishieMapPowerBlockGRAttackColl - llGRInishieMapMapHeader))

## 0x80109B4C
static func grInishiePowerBlockSetDamage() -> void:
	var inishie: Dictionary = Grcommonsetup.gGRCommonStruct.inishie

	Ftmain.ftMainCheckAddGroundHazard(inishie.pblock_gobj, Callable(Grinishie, &"grInishiePowerBlockCheckGetDamageKind"))

	inishie.pblock_appear_wait = 2
	inishie.pblock_status = nGRInishiePowerBlockStatusDamage

## 0x80109B8C - hazard proc_update: returns {"ret": sb32, "gr_attack_coll": GRAttackColl, "kind": s32} (Ftmain convention)
static func grInishiePowerBlockCheckGetDamageKind(item_gobj = null, fighter_gobj = null) -> Dictionary:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsGround:
		var ip := itGetStruct(item_gobj)

		if fighter_gobj != ip.damage_gobj:
			return {"ret": TRUE, "gr_attack_coll": Grcommonsetup.gGRCommonStruct.inishie.attack_coll, "kind": nGMHitEnvironmentPowerBlock}

	return {"ret": FALSE, "gr_attack_coll": null, "kind": 0}

## 0x80109BD4
static func grInishieInitHeaders() -> void:
	var inishie: Dictionary = Grcommonsetup.gGRCommonStruct.inishie
	var gMPCollisionGroundData: Dictionary = Grdisplay.grDisplayGetGroundData()

	inishie.map_head = Grdisplay.grDisplayPtrAdd(gMPCollisionGroundData.map_nodes, -llGRInishieMapMapHead)
	inishie.item_head = Grdisplay.grDisplayPtrAdd(gMPCollisionGroundData.header, -llGRInishieMapMapHeader)

## 0x80109C0C
static func grInishieMakeGround():
	grInishieInitHeaders()
	grInishieMakeScale()
	grInishieMakePakkun()
	grInishieMakePowerBlock()

	return null

## 0x80109C48 - Unused?  void, two out-params -> {"alt": f32, "accel": f32}
static func grInishieScaleGetPlatformInfo(alt = null, accel = null) -> Dictionary:
	var inishie: Dictionary = Grcommonsetup.gGRCommonStruct.inishie

	return {
		"alt": 1100.0 - (-inishie.splat_alt if (inishie.splat_alt < 0.0) else inishie.splat_alt),
		"accel": -inishie.splat_accelerate if (inishie.splat_accelerate < 0.0) else inishie.splat_accelerate,
	}

# BEGIN GENERATED FILE IMAGES (tools/port/gr/gen_gr_file_images.py - do not edit by hand)
## relocData words read by the ground code, from baserom.us.z64 (US v1.0, SHA-1 e2929e10fccc0aa84e5776227e798abc07cedabf).
## Same bytes as the typed C in sources/ssb-decomp-re/src/relocData/<file>.c. "w": {byte_offset: [u32 words]},
## "p": relocated pointer slots {byte_offset: [file_id, byte_offset, kind]} (kind 1 AObjEvent32, 2 SYInterpDesc, 0 other).
const dGRInishieFileImages: Array = [
	{"fid": 107, "name": "StageInishieFile2", "w": {
		0x4A48: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0xC52D7000, 0x449BA000, 0xC5CE4000, 0x00000000, 0xC0490FDC, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000001, 0x00000000, 0xC52D7000, 0x45529550, 0xC5CE4000, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001,
			0x00000000, 0x445A619A, 0x43AC8000, 0xC5B31000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x4559B399,
			0x451BA000, 0xC59AB000, 0x00000000, 0xC0490FDC, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000,
			0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000],
		0x4C30: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000],
		0x6320: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00002001, 0x00000000, 0x4535E000, 0xC2F00000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002001, 0x00000000, 0xC52C8000, 0x44E6A000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x00000012, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x6820: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000],
		0x6C00: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000],
		}, "p": {
		0x4A78: [107, 0x49A0, 0],
		0x4AA4: [107, 0x49B8, 0],
		0x4AD0: [107, 0x49C8, 0],
		0x4AFC: [107, 0x49D8, 0],
		0x4B28: [107, 0x49E8, 0],
		0x4B54: [107, 0x49F8, 0],
		0x4B80: [107, 0x4A08, 0],
		0x4BAC: [107, 0x4A18, 0],
		0x4BD8: [107, 0x4A30, 0],
		0x4C3C: [107, 0x4C58, 1],
		0x4C44: [107, 0x4DD0, 1],
		0x4C4C: [107, 0x4E04, 1],
		0x63A8: [107, 0x5C70, 0],
		0x63D4: [107, 0x5E40, 0],
		0x6400: [107, 0x6008, 0],
		0x6850: [107, 0x6740, 0],
		0x6C30: [107, 0x6A30, 0],
		}},
	{"fid": 155, "name": "StageInishieFile3", "w": {
		0x0380: [0x00000000, 0x00000000, 0x00000000, 0x44FB4000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x43D20000, 0xC2670108, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000,
			0x00000000, 0xC4C6C000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000001, 0x00000000, 0xC3D20000, 0xC2670018, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000, 0x00000000, 0xC4C6C000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000],
		0x0734: [0x1E010002, 0x1E000002, 0x1C000000, 0x00000000],
		}, "p": {
		0x0384: [155, 0x01C8, 0],
		0x03B0: [155, 0x02E8, 0],
		0x03DC: [155, 0x0300, 0],
		0x0408: [155, 0x0328, 0],
		0x0434: [155, 0x0340, 0],
		0x0740: [155, 0x0734, 1],
		}},
	{"fid": 260, "name": "GRInishieMap", "w": {
		0x00BC: [0x00000001, 0x00000014, 0x0000005A, 0x00000082, 0x00000000, 0x0000001E, 0x00000000],
		}, "p": {
		}},
]
# END GENERATED FILE IMAGES
