## 1:1 port of src/gr/grcommon/grhyrule.c (Hyrule Castle tornado).
class_name Grhyrule
extends Port

## Particle bank ROM addresses (src/gr/grcommon/grhyrule.h)
const lGRHyruleParticleScriptBankLo := 0x00B1F960
const lGRHyruleParticleScriptBankHi := 0x00B1FC80
const lGRHyruleParticleTextureBankLo := 0x00B1FC80
const lGRHyruleParticleTextureBankHi := 0x00B22980

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

const nGRHyruleTwisterStatusSleep := 0
const nGRHyruleTwisterStatusWait := 1
const nGRHyruleTwisterStatusSummon := 2
const nGRHyruleTwisterStatusMove := 3
const nGRHyruleTwisterStatusTurn := 4
const nGRHyruleTwisterStatusStop := 5
const nGRHyruleTwisterStatusSubside := 6

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8010A140 - pos: Vector3 (read only); returns the LBParticle or null
static func grHyruleTwisterMakeEffect(pos = null, effect_id = null):
	var pc = Grdisplay.lbParticleMakeScriptID(Grcommonsetup.gGRCommonStruct.hyrule.particle_bank_id | Grdisplay.LBPARTICLE_MASK_GENLINK(0), effect_id)

	if pc != null:
		var xf = Grdisplay.lbParticleAddTransformForStruct(pc, nLBTransformStatusDefault)

		if xf == null:
			Grdisplay.lbParticleEjectStruct(pc)

			return null

		Grdisplay.LBParticleProcessStruct(pc)

		if xf.users_num == 0:
			return null

		xf.translate = pos

	return pc

## 0x8010A1E4 - pos: Vector3 (read only)
static func grHyruleMakeTwister(pos = null):
	var line_id: int
	var floor_dist: float
	var twister_gobj
	var twister_dobj: DObj
	var pc
	var edge_pos: Vector3
	var edge_under: int
	var hyrule: Dictionary = Grcommonsetup.gGRCommonStruct.hyrule

	var r = Mpcollision.mpCollisionCheckProjectFloor(pos)   # (pos, &line_id, &floor_dist, NULL, NULL)

	if (r == null) or (r.ret == FALSE):
		return null

	line_id = r.project_line_id
	floor_dist = r.ga_dist

	twister_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindGround, null, nGCCommonLinkIDGround, GOBJ_PRIORITY_DEFAULT)

	if twister_gobj != null:
		twister_dobj = Objman.gcAddDObjForGObj(twister_gobj, null)

		twister_dobj.translate = pos

		twister_dobj.translate.y += floor_dist

		pc = grHyruleTwisterMakeEffect(twister_dobj.translate, 3)

		if pc == null:
			hyrule.twister_xf = null

			Objman.gcEjectGObj(twister_gobj)

			return null

		hyrule.twister_line_id = line_id & 0xFFFF   # u16

		edge_pos = Grdisplay.grDisplayVec3(Mpcollision.mpCollisionGetFloorEdgeL(line_id))

		edge_under = Mpcollision.mpCollisionGetEdgeUnderLLineID(line_id)

		if (edge_under == -1) or (Mpcollision.mpCollisionGetLineTypeID(edge_under) != nMPLineKindRWall):
			hyrule.twister_leftedge_x = edge_pos.x
		else:
			hyrule.twister_leftedge_x = edge_pos.x + 300.0

		edge_pos = Grdisplay.grDisplayVec3(Mpcollision.mpCollisionGetFloorEdgeR(line_id))

		edge_under = Mpcollision.mpCollisionGetEdgeUnderRLineID(line_id)

		if (edge_under == -1) or (Mpcollision.mpCollisionGetLineTypeID(edge_under) != nMPLineKindLWall):
			hyrule.twister_rightedge_x = edge_pos.x
		else:
			hyrule.twister_rightedge_x = edge_pos.x - 300.0

		hyrule.twister_xf = pc.xf

	return twister_gobj

## 0x8010A36C
static func grHyruleTwisterUpdateSleep() -> void:
	var hyrule: Dictionary = Grcommonsetup.gGRCommonStruct.hyrule

	if G.gSCManagerBattleState.game_status != nSCBattleGameStatusWait:
		hyrule.twister_status = nGRHyruleTwisterStatusWait
		hyrule.twister_wait = syUtilsRandIntRange(1200) + 1600

## 0x8010A3B4
static func grHyruleTwisterUpdateWait() -> void:
	var pos: Vector3
	var twister_gobj
	var hyrule: Dictionary = Grcommonsetup.gGRCommonStruct.hyrule

	hyrule.twister_wait = (hyrule.twister_wait - 1) & 0xFFFF   # u16

	if hyrule.twister_wait == 0:
		pos = Grdisplay.grDisplayGetMapObjPositionID(hyrule.twister_pos_ids[syUtilsRandIntRange(hyrule.twister_pos_count)])

		twister_gobj = grHyruleMakeTwister(pos)

		if twister_gobj == null:
			hyrule.twister_wait = syUtilsRandIntRange(1200) + 1600
		else:
			hyrule.twister_wait = 80
			hyrule.twister_gobj = twister_gobj
			hyrule.twister_status = nGRHyruleTwisterStatusSummon

## 0x8010A444
static func grHyruleTwisterUpdateSummon() -> void:
	var lr: int
	var hyrule: Dictionary = Grcommonsetup.gGRCommonStruct.hyrule

	hyrule.twister_wait = (hyrule.twister_wait - 1) & 0xFFFF

	if hyrule.twister_wait == 0:
		hyrule.twister_status = nGRHyruleTwisterStatusMove
		hyrule.twister_wait = syUtilsRandIntRange(600) + 520

		lr = +1 if ((syUtilsRandUShort() % 2) != 0) else -1

		hyrule.twister_turn_wait = 0
		hyrule.twister_vel = lr * 10.0
		hyrule.twister_speed_wait = syUtilsRandIntRange(120) + 180

		Ftmain.ftMainCheckAddGroundObstacle(hyrule.twister_gobj, Callable(Grhyrule, &"grHyruleTwisterCheckGetDamageKind"))

		Snd.func_800269C0_275C0(nSYAudioFGMHyruleTwisterAppear)

## 0x8010A4F4
static func grHyruleTwisterDecLifetimeCheckStop() -> int:
	var hyrule: Dictionary = Grcommonsetup.gGRCommonStruct.hyrule

	hyrule.twister_wait = (hyrule.twister_wait - 1) & 0xFFFF

	if hyrule.twister_wait == 0:
		hyrule.twister_status = nGRHyruleTwisterStatusStop

		return TRUE
	else:
		return FALSE

## 0x8010A52C
static func grHyruleTwisterGetLR() -> int:
	var players_rside := 0
	var players_lside := 0
	var hyrule: Dictionary = Grcommonsetup.gGRCommonStruct.hyrule
	var twister_pos_x: float = DObjGetStruct(hyrule.twister_gobj).translate.x

	for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		var fp := ftGetStruct(fighter_gobj)

		if (fp.ga == nMPKineticsGround) and (fp.coll_data.floor_line_id == hyrule.twister_line_id):
			if fp.joints[nFTPartsJointTopN].translate.x > twister_pos_x:
				players_rside += 1
			else:
				players_lside += 1

	if (players_lside != 0) or (players_rside != 0):
		if players_lside == players_rside:
			return -1 if ((syUtilsRandUShort() % 2) != 0) else +1
		elif players_rside < players_lside:
			return -1
		else:
			return +1
	else:
		return 0

## 0x8010A610
static func grHyruleTwisterUpdateMove() -> void:
	var hyrule: Dictionary = Grcommonsetup.gGRCommonStruct.hyrule
	var twister_dobj: DObj = DObjGetStruct(hyrule.twister_gobj)   # Vec3f *pos = &...->translate
	var ground_level: float
	var pos_x: float
	var lr: int

	if grHyruleTwisterDecLifetimeCheckStop() == FALSE:
		if hyrule.twister_turn_wait != 0:
			hyrule.twister_turn_wait = (hyrule.twister_turn_wait - 1) & 0xFFFF

			if hyrule.twister_turn_wait == 0:
				if hyrule.twister_vel < 0.0:
					hyrule.twister_vel = -10.0
				else:
					hyrule.twister_vel = 10.0
		else:
			hyrule.twister_speed_wait = (hyrule.twister_speed_wait - 1) & 0xFFFF

			if hyrule.twister_speed_wait == 0:
				lr = grHyruleTwisterGetLR()

				if (lr != 0) and (syUtilsRandIntRange(5) == 0):
					hyrule.twister_turn_wait = syUtilsRandIntRange(180) + 300
					hyrule.twister_vel = lr * 50.0

		pos_x = twister_dobj.translate.x + hyrule.twister_vel

		if (hyrule.twister_rightedge_x < pos_x) or (pos_x < hyrule.twister_leftedge_x):
			if hyrule.twister_rightedge_x < pos_x:
				twister_dobj.translate.x = hyrule.twister_rightedge_x - 10.0
			else:
				twister_dobj.translate.x = hyrule.twister_leftedge_x + 10.0

			hyrule.twister_status = nGRHyruleTwisterStatusTurn
			hyrule.twister_turn_wait = 120
		else:
			twister_dobj.translate.x = pos_x

		# mpCollisionGetFCCommonFloor(twister_line_id, pos, &ground_level, NULL, NULL)
		var r = Mpcollision.mpCollisionGetFCCommonFloor(hyrule.twister_line_id, twister_dobj.translate)
		ground_level = r.dist if (r is Dictionary and r.has("dist")) else 0.0

		twister_dobj.translate.y += ground_level

		hyrule.twister_xf.translate = twister_dobj.translate

## 0x8010A7CC
static func grHyruleTwisterUpdateTurn() -> void:
	var hyrule: Dictionary = Grcommonsetup.gGRCommonStruct.hyrule

	if grHyruleTwisterDecLifetimeCheckStop() == FALSE:
		hyrule.twister_turn_wait = (hyrule.twister_turn_wait - 1) & 0xFFFF

		if hyrule.twister_turn_wait == 0:
			hyrule.twister_status = nGRHyruleTwisterStatusMove
			hyrule.twister_turn_wait = 0
			hyrule.twister_vel = -hyrule.twister_vel

## 0x8010A824
static func grHyruleTwisterUpdateStop() -> void:
	var hyrule: Dictionary = Grcommonsetup.gGRCommonStruct.hyrule

	for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		var fp := ftGetStruct(fighter_gobj)

		if fp.status_id == nFTCommonStatusTwister:
			return

	hyrule.twister_status = nGRHyruleTwisterStatusSubside
	hyrule.twister_wait = 32

	Ftmain.ftMainClearGroundObstacle(hyrule.twister_gobj)

	if hyrule.twister_xf != null:
		grHyruleTwisterMakeEffect(hyrule.twister_xf.translate, 7)

	Objman.gcEjectGObj(hyrule.twister_gobj)

## 0x8010A8B4
static func grHyruleTwisterUpdateSubside() -> void:
	var hyrule: Dictionary = Grcommonsetup.gGRCommonStruct.hyrule

	hyrule.twister_wait = (hyrule.twister_wait - 1) & 0xFFFF

	if hyrule.twister_wait == 0:
		hyrule.twister_status = nGRHyruleTwisterStatusWait
		hyrule.twister_wait = syUtilsRandIntRange(1200) + 1600

		if hyrule.twister_xf != null:
			Grdisplay.lbParticleEjectStructID(hyrule.twister_xf.generator_id, 1)

## 0x8010A91C
static func grHyruleTwisterProcUpdate(ground_gobj = null) -> void:
	match Grcommonsetup.gGRCommonStruct.hyrule.twister_status:
		nGRHyruleTwisterStatusSleep:
			grHyruleTwisterUpdateSleep()
		nGRHyruleTwisterStatusWait:
			grHyruleTwisterUpdateWait()
		nGRHyruleTwisterStatusSummon:
			grHyruleTwisterUpdateSummon()
		nGRHyruleTwisterStatusMove:
			grHyruleTwisterUpdateMove()
		nGRHyruleTwisterStatusTurn:
			grHyruleTwisterUpdateTurn()
		nGRHyruleTwisterStatusStop:
			grHyruleTwisterUpdateStop()
		nGRHyruleTwisterStatusSubside:
			grHyruleTwisterUpdateSubside()

## 0x8010A9C8
static func grHyruleTwisterInitVars() -> void:
	var i: int
	var pos_count: int
	var pos_ids: Array
	var hyrule: Dictionary = Grcommonsetup.gGRCommonStruct.hyrule

	var count_r = Mpcollision.mpCollisionGetMapObjCountKind(nMPMapObjKindTwister)
	pos_count = int(count_r) if count_r != null else 0
	hyrule.twister_pos_count = pos_count & 0xFF   # u8

	if (pos_count == 0) or (pos_count > 10):    # ARRAY_COUNT(pos_ids)
		# while (TRUE) { syDebugPrintf("Twister positions are error!\n"); scManagerRunPrintGObjStatus(); }
		Debug.syDebugPrintf("Twister positions are error!\n")
		push_error("grHyruleTwisterInitVars: Twister positions are error! (count %d)" % pos_count)
		hyrule.twister_pos_ids = [0]
	else:
		hyrule.twister_pos_ids = []   # syTaskmanMalloc(pos_count * sizeof(u8), 0x0)
		hyrule.twister_pos_ids.resize(pos_count)

		pos_ids = Grdisplay.grDisplayGetMapObjIDsKind(nMPMapObjKindTwister)

		for j in pos_count:
			i = j
			hyrule.twister_pos_ids[i] = (pos_ids[i] if i < pos_ids.size() else 0) & 0xFF

	hyrule.twister_status = nGRHyruleTwisterStatusSleep
	hyrule.particle_bank_id = Grdisplay.efParticleGetLoadBankID(lGRHyruleParticleScriptBankLo, lGRHyruleParticleScriptBankHi, lGRHyruleParticleTextureBankLo, lGRHyruleParticleTextureBankHi)

## 0x8010AB20
static func grHyruleMakeGround():
	var ground_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindGround, null, nGCCommonLinkIDGround, GOBJ_PRIORITY_DEFAULT)

	Objman.gcAddGObjProcess(ground_gobj, Callable(Grhyrule, &"grHyruleTwisterProcUpdate"), nGCProcessKindFunc, 4)
	grHyruleTwisterInitVars()

	return ground_gobj

## 0x8010AB74 - obstacle proc_update: returns {"ret": sb32, "kind": s32} (Ftmain convention)
static func grHyruleTwisterCheckGetDamageKind(ground_gobj = null, fighter_gobj = null) -> Dictionary:
	var fp := ftGetStruct(fighter_gobj)
	var dist_y: float
	var dist_x: float

	if (
		(fp.twister_wait == 0) and
		(fp.status_id != nFTCommonStatusTwister) and
		not (fp.capture_immune_mask & FTCATCHKIND_MASK_TWISTER) and
		(Ftparam.ftParamGetBestHitStatusAll(fighter_gobj) == nGMHitStatusNormal)
	):
		var gr_dobj: DObj = DObjGetStruct(ground_gobj)
		var ft_dobj: DObj = DObjGetStruct(fighter_gobj)

		if gr_dobj.translate.x < ft_dobj.translate.x:
			dist_x = -(gr_dobj.translate.x - ft_dobj.translate.x)
		else:
			dist_x = gr_dobj.translate.x - ft_dobj.translate.x

		dist_y = ft_dobj.translate.y - gr_dobj.translate.y

		if (dist_x < 300.0) and (dist_y < 600.0) and (dist_y > -300.0):
			return {"ret": TRUE, "kind": nGMHitEnvironmentTwister}

	return {"ret": FALSE, "kind": 0}

## 0x8010AC70 - sb32 + one out-param -> {"ret": sb32, "pos": Vector3}
static func grHyruleTwisterCheckGetPosition(pos = null) -> Dictionary:
	var hyrule: Dictionary = Grcommonsetup.gGRCommonStruct.hyrule

	if (hyrule.twister_status == nGRHyruleTwisterStatusMove) or (hyrule.twister_status == nGRHyruleTwisterStatusTurn):
		return {"ret": TRUE, "pos": DObjGetStruct(hyrule.twister_gobj).translate}
	else:
		return {"ret": FALSE, "pos": pos if pos is Vector3 else Vector3.ZERO}

# BEGIN GENERATED FILE IMAGES (tools/port/gr/gen_gr_file_images.py - do not edit by hand)
## relocData words read by the ground code, from baserom.us.z64 (US v1.0, SHA-1 e2929e10fccc0aa84e5776227e798abc07cedabf).
## Same bytes as the typed C in sources/ssb-decomp-re/src/relocData/<file>.c. "w": {byte_offset: [u32 words]},
## "p": relocated pointer slots {byte_offset: [file_id, byte_offset, kind]} (kind 1 AObjEvent32, 2 SYInterpDesc, 0 other).
const dGRHyruleFileImages: Array = [
	{"fid": 113, "name": "StageHyruleFile2", "w": {
		0x4588: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x5700: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000002, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x66A8: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000,
			0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000],
		}, "p": {
		0x45B8: [113, 0x4550, 0],
		0x45E4: [113, 0x4560, 0],
		0x4610: [113, 0x4570, 0],
		0x5730: [113, 0x5020, 0],
		0x5788: [113, 0x55C0, 0],
		0x66D8: [113, 0x6010, 0],
		0x6704: [113, 0x61F0, 0],
		0x6730: [113, 0x63D8, 0],
		0x675C: [113, 0x6478, 0],
		0x6788: [113, 0x64C0, 0],
		0x67B4: [113, 0x6548, 0],
		0x67E0: [113, 0x65C0, 0],
		0x680C: [113, 0x6638, 0],
		0x6838: [113, 0x6658, 0],
		}},
]
# END GENERATED FILE IMAGES
