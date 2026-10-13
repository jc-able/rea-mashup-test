## Port of src/it/itcommon/itmball.c (Poké Ball).
##
## The random Pokémon selection itself lives in itMainMakeMonster (src/it/itmain.c -> Itmain); this file
## only calls it (or itManagerMakeItemKind when dITManagerForceMonsterKind is set), in the C order.
##
## Port conventions used here (see PORTING.md):
## * ITDesc / ITStatusDesc are Dictionaries with the C field names (Itmanager header). The C pair
##   {p_file = &gITManagerCommonData, o_attributes = &llITCommonDataMBallItemAttributes} is given as the
##   linker symbol name: Itmanager resolves it to its ROM-verified transcription of
##   src/relocData/251_ITCommonData.c dITCommonData_MBall_ItemAttributes (file 251 @ 0x06E4), whose
##   DObjDesc tree (86_ITCommonObject.c dITCommonObject_MBall_Item_data_DObjDesc: id0 -> id1 -> {id2, id2},
##   id0 ejected) gives dobj->child = open ball, dobj->child->sib_next = closed ball.
## * itGetPData(ip, &llITCommonDataMBallDataStart, &X) resolves to ITCommonObject (file 86) offset X; the
##   render-only targets (MatAnimJoint) are kept as symbolic markers.
class_name Itmball
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itMBallStatus
const nITMBallStatusWait = 0
const nITMBallStatusFall = 1
const nITMBallStatusHold = 2
const nITMBallStatusThrown = 3
const nITMBallStatusDropped = 4
const nITMBallStatusOpen = 5
const nITMBallStatusOpenAir = 6
const nITMBallStatusEnumCount = 7

# // // // // // // // // // // // //
# //      RELOC DATA (US ROM)      //
# // // // // // // // // // // // //

## itGetPData(ip, &llITCommonDataMBallDataStart, &llITCommonDataMBallMatAnimJoint): ITCommonObject @ 0x9520
## (tools/relocFileDescriptions.us.txt). Material animation is render-only: symbolic marker.
const llITCommonDataMBallMatAnimJoint := {"file": 86, "offset": 0x9520, "name": "MBallMatAnimJoint"}

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

static var dITMBallItemDesc := {
	"kind": nITKindMBall,                                       # Item Kind
	"o_attributes": "llITCommonDataMBallItemAttributes",       # p_file = &gITManagerCommonData
	"transform_types": {"tk1": nGCMatrixKindNull, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                          # Hitbox Update State
	"proc_update": Callable(Itmball, &"itMBallFallProcUpdate"),
	"proc_map": Callable(Itmball, &"itMBallFallProcMap"),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
	"visual_kind": "mball",
}

static var dITMBallStatusDescs: Array = [
	# Status 0 (Ground Wait)
	{
		"proc_update": Callable(),
		"proc_map": Callable(Itmball, &"itMBallWaitProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
	},
	# Status 1 (Air Wait Fall)
	{
		"proc_update": Callable(Itmball, &"itMBallFallProcUpdate"),
		"proc_map": Callable(Itmball, &"itMBallFallProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
	},
	# Status 2 (Fighter Hold)
	{
		"proc_update": Callable(),
		"proc_map": Callable(),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
	},
	# Status 3 (Fighter Throw)
	{
		"proc_update": Callable(Itmball, &"itMBallThrownProcUpdate"),
		"proc_map": Callable(Itmball, &"itMBallThrownProcMap"),
		"proc_hit": Callable(Itmball, &"itMBallCommonProcHit"),
		"proc_shield": Callable(Itmball, &"itMBallCommonProcHit"),
		"proc_hop": Callable(Itmain, &"itMainCommonProcHop"),
		"proc_setoff": Callable(Itmball, &"itMBallCommonProcHit"),
		"proc_reflector": Callable(Itmball, &"itMBallCommonProcReflector"),
		"proc_damage": Callable(),
	},
	# Status 4 (Fighter Drop)
	{
		"proc_update": Callable(Itmball, &"itMBallFallProcUpdate"),
		"proc_map": Callable(Itmball, &"itMBallThrownProcMap"),
		"proc_hit": Callable(Itmball, &"itMBallCommonProcHit"),
		"proc_shield": Callable(Itmball, &"itMBallCommonProcHit"),
		"proc_hop": Callable(Itmain, &"itMainCommonProcHop"),
		"proc_setoff": Callable(Itmball, &"itMBallCommonProcHit"),
		"proc_reflector": Callable(Itmball, &"itMBallCommonProcReflector"),
		"proc_damage": Callable(),
	},
	# Status 5 (Ground Open)
	{
		"proc_update": Callable(Itmball, &"itMBallOpenProcUpdate"),
		"proc_map": Callable(Itmball, &"itMBallOpenProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
	},
	# Status 6 (Air Open)
	{
		"proc_update": Callable(Itmball, &"itMBallOpenAirProcUpdate"),
		"proc_map": Callable(Itmball, &"itMBallOpenAirProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(Itmball, &"itMBallCommonProcReflector"),
		"proc_damage": Callable(),
	},
]

# // // // // // // // // // // // //
# //        PORT-ONLY HELPERS      //
# // // // // // // // // // // // //

## Port-only (shared by the itcommon B ports). C `dobj->mobj` (first material of a DObj). Item MObjSubs are render-only data the port does not export,
## so no MObjs are attached by the item manager: use the first MObj in DObj metadata "mobjs" (Grdisplay's
## convention) if one exists, else a per-DObj stand-in holding the MObj fields item code touches,
## initialised like gcAddMObjForDObj (palette_id = 0, matanim_joint.event32 = NULL i.e. anim_pos = -1).
static func itPortGetDObjMObj(dobj: DObj):
	if dobj == null:
		return null
	var mobjs: Array = dobj.get_meta(&"mobjs", [])
	if not mobjs.is_empty():
		return mobjs[0]
	if not dobj.has_meta(&"port_mobj"):
		dobj.set_meta(&"port_mobj", {"palette_id": 0.0, "anim_data": null, "anim_pos": -1})
	return dobj.get_meta(&"port_mobj")

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8017C690
static func itMBallOpenAddAnim(item_gobj) -> void:
	var dobj := DObjGetStruct(item_gobj)
	var matanim_joint = llITCommonDataMBallMatAnimJoint  # itGetPData(ip, &llITCommonDataMBallDataStart, &llITCommonDataMBallMatAnimJoint)
	var mobj = null

	# C: gcAddMObjMatAnimJoint(dobj->child->child->sib_next->mobj, matanim_joint, 0.0F). With the ROM model
	# tree (DObjDesc ids 0, 1, 2, 2; id0 ejected) dobj->child->child is NULL; this material animation is
	# render-only, so the port passes no MObj instead of dereferencing NULL.
	if dobj.child.child != null:
		mobj = itPortGetDObjMObj(dobj.child.child.sib_next)

	ObjAnim.gcAddMObjMatAnimJoint(mobj, matanim_joint, 0.0)
	ObjAnim.gcPlayAnimAll(item_gobj)

## 0x8017C6F8
static func itMBallOpenClearAnim(item_gobj) -> void:
	var dobj := DObjGetStruct(item_gobj)

	itPortGetDObjMObj(dobj.child.sib_next).anim_pos = -1   # dobj->child->sib_next->mobj->matanim_joint.event32 = NULL

## 0x8017C710
static func itMBallFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITMBALL_GRAVITY, ITMBALL_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	dobj.child.sib_next.rotate.z = dobj.rotate.z

	return FALSE

## 0x8017C768
static func itMBallWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itmball, &"itMBallFallSetStatus"))

	return FALSE

## 0x8017C790
static func itMBallFallProcMap(item_gobj) -> int:
	Itmap.itMapCheckDestroyDropped(item_gobj, ITMBALL_MAP_REBOUND_COMMON, ITMBALL_MAP_REBOUND_GROUND, Callable(Itmball, &"itMBallWaitSetStatus"))

	return FALSE

## 0x8017C7C8
static func itMBallWaitSetStatus(item_gobj) -> void:
	Itmain.itMainSetGroundAllowPickup(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITMBallStatusDescs, nITMBallStatusWait)

## 0x8017C7FC
static func itMBallFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITMBallStatusDescs, nITMBallStatusFall)

## 0x8017C840
static func itMBallHoldSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	DObjGetStruct(item_gobj).rotate.y = 0.0

	ip.item_vars.mball.owner_gobj = ip.owner_gobj

	Itmain.itMainSetStatus(item_gobj, dITMBallStatusDescs, nITMBallStatusHold)

## 0x8017C880
static func itMBallThrownProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITMBALL_GRAVITY, ITMBALL_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	dobj.child.sib_next.rotate.z = dobj.rotate.z

	return FALSE

## 0x8017C8D8
static func itMBallThrownProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.item_vars.mball.is_rebound != FALSE:
		Itmap.itMapCheckLanding(item_gobj, ITMBALL_MAP_REBOUND_COMMON, ITMBALL_MAP_REBOUND_GROUND, Callable(Itmball, &"itMBallOpenSetStatus"))
	else:
		Itmap.itMapCheckDestroyDropped(item_gobj, ITMBALL_MAP_REBOUND_COMMON, ITMBALL_MAP_REBOUND_GROUND, Callable(Itmball, &"itMBallOpenSetStatus"))

	return FALSE

## 0x8017C94C
static func itMBallCommonProcHit(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.attack_coll.attack_state = nGMAttackStateOff

	ip.item_vars.mball.is_rebound = TRUE

	Itmain.itMainVelSetRebound(item_gobj)

	return FALSE

## 0x8017C97C
static func itMBallCommonProcReflector(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var fp: Fighter
	var fighter_gobj

	ip.attack_coll.attack_state = nGMAttackStateOff

	ip.item_vars.mball.is_rebound = TRUE

	Itmain.itMainVelSetRebound(item_gobj)

	fighter_gobj = ip.item_vars.mball.owner_gobj
	ip.owner_gobj = fighter_gobj
	fp = ftGetStruct(fighter_gobj)

	ip.team = fp.team
	ip.player = fp.player
	ip.player_num = fp.player_num
	ip.handicap = fp.handicap

	return FALSE

## 0x8017C9E0
static func itMBallThrownSetStatus(item_gobj) -> void:
	itMBallOpenAddAnim(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITMBallStatusDescs, nITMBallStatusThrown)

## 0x8017CA14
static func itMBallDroppedSetStatus(item_gobj) -> void:
	itMBallOpenAddAnim(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITMBallStatusDescs, nITMBallStatusDropped)

## 0x8017CA48
static func itMBallOpenProcUpdate(mball_gobj) -> int:
	var mball_ip := itGetStruct(mball_gobj)
	var monster_ip: Item
	var monster_gobj
	var vel: Vector3

	if mball_ip.multi == 0:
		vel.z = 0.0
		vel.y = vel.z
		vel.x = vel.y

		if Itmanager.dITManagerForceMonsterKind == 0:
			Itmain.itMainMakeMonster(mball_gobj)

			return TRUE
		monster_gobj = Itmanager.itManagerMakeItemKind(mball_gobj, Itmanager.dITManagerForceMonsterKind + (nITKindMBallMonsterStart - 1), DObjGetStruct(mball_gobj).translate, vel, (ITEM_FLAG_COLLPROJECT | ITEM_FLAG_PARENT_ITEM))

		if monster_gobj != null:
			monster_ip = itGetStruct(monster_gobj)

			monster_ip.owner_gobj = mball_ip.owner_gobj
			monster_ip.team = mball_ip.team
			monster_ip.player = mball_ip.player
			monster_ip.handicap = mball_ip.handicap
			monster_ip.player_num = mball_ip.player_num
			monster_ip.display_mode = mball_ip.display_mode

		return TRUE
	mball_ip.multi = (mball_ip.multi - 1) & 0xFFFF     # u16 multi

	if mball_ip.item_vars.mball.effect_gobj != null:
		var effect_dobj := DObjGetStruct(mball_ip.item_vars.mball.effect_gobj)

		# Port: an ejected effect GObj may have no DObj left (C writes into the stale DObj).
		if effect_dobj != null:
			effect_dobj.translate = DObjGetStruct(mball_gobj).translate

	return FALSE

## 0x8017CB38
static func itMBallOpenProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if Mpcollision.mpCollisionCheckExistLineID(ip.attach_line_id) == FALSE:
		ip.is_attach_surface = FALSE

		itMBallOpenAirSetStatus(item_gobj)

	return FALSE

## 0x8017CB84
static func itMBallOpenInitVars(item_gobj) -> void:
	var dobj := DObjGetStruct(item_gobj)
	var ip := itGetStruct(item_gobj)
	var child: DObj
	var sibling: DObj

	ip.physics.vel_air.x = 0.0
	ip.physics.vel_air.y = 0.0
	ip.physics.vel_air.z = 0.0

	child = dobj.child
	child.flags ^= DOBJ_FLAG_HIDDEN

	sibling = dobj.child.sib_next
	sibling.flags ^= DOBJ_FLAG_HIDDEN

	Snd.func_800269C0_275C0(nSYAudioFGMMBallOpen)

	ip.attach_line_id = ip.coll_data.floor_line_id & 0xFFFF   # u16 attach_line_id

	ip.is_attach_surface = TRUE

	if (ip.player != -1) and (ip.player != GMCOMMON_PLAYERS_MAX):   # (u8 player: != -1 is always TRUE)
		var fighter_gobj = G.gSCManagerBattleState.players[ip.player].fighter_gobj

		if fighter_gobj != null:
			var fp := ftGetStruct(fighter_gobj)

			Ftparam.ftParamMakeRumble(fp, 8, 20)

	ip.item_vars.mball.effect_gobj = Efmanager.efManagerMBallRaysMakeEffect(dobj.translate)

	itMBallOpenClearAnim(item_gobj)

	ip.attack_coll.attack_state = nGMAttackStateOff
	ip.attack_coll.can_reflect = FALSE

## 0x8017CC88
static func itMBallOpenSetStatus(item_gobj) -> void:
	itMBallOpenInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITMBallStatusDescs, nITMBallStatusOpen)

## 0x8017CCBC
static func itMBallOpenAirProcUpdate(mball_gobj) -> int:
	var mball_ip := itGetStruct(mball_gobj)
	var monster_ip: Item
	var monster_gobj
	var vel: Vector3

	if mball_ip.multi == 0:
		vel.z = 0.0
		vel.y = vel.z
		vel.x = vel.y

		if Itmanager.dITManagerForceMonsterKind == 0:
			Itmain.itMainMakeMonster(mball_gobj)

			return TRUE
		monster_gobj = Itmanager.itManagerMakeItemKind(mball_gobj, Itmanager.dITManagerForceMonsterKind + (nITKindMBallMonsterStart - 1), DObjGetStruct(mball_gobj).translate, vel, (ITEM_FLAG_COLLPROJECT | ITEM_FLAG_PARENT_ITEM))

		if monster_gobj != null:
			monster_ip = itGetStruct(monster_gobj)

			monster_ip.owner_gobj = mball_ip.owner_gobj
			monster_ip.team = mball_ip.team
			monster_ip.player = mball_ip.player
			monster_ip.handicap = mball_ip.handicap
			monster_ip.player_num = mball_ip.player_num
			monster_ip.display_mode = mball_ip.display_mode

		return TRUE
	mball_ip.multi = (mball_ip.multi - 1) & 0xFFFF     # u16 multi

	if mball_ip.item_vars.mball.effect_gobj != null:
		var effect_dobj := DObjGetStruct(mball_ip.item_vars.mball.effect_gobj)

		# Port: an ejected effect GObj may have no DObj left (C writes into the stale DObj).
		if effect_dobj != null:
			effect_dobj.translate = DObjGetStruct(mball_gobj).translate

	return FALSE

## 0x8017CDAC
static func itMBallOpenAirProcMap(item_gobj) -> int:
	Itmap.itMapCheckDestroyDropped(item_gobj, ITMBALL_MAP_REBOUND_COMMON, ITMBALL_MAP_REBOUND_GROUND, Callable(Itmball, &"itMBallOpenSetStatus"))

	return FALSE

## 0x8017CDE4
static func itMBallOpenAirSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITMBallStatusDescs, nITMBallStatusOpenAir)

## 0x8017CE0C
static func itMBallMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITMBallItemDesc, pos, vel, flags)

	if item_gobj != null:
		var dobj := DObjGetStruct(item_gobj)
		var ip := itGetStruct(item_gobj)
		var translate: Vector3 = dobj.translate   # REGION_US

		dobj.child.flags = DOBJ_FLAG_HIDDEN
		dobj.child.sib_next.flags = DOBJ_FLAG_NONE

		Objman.gcAddXObjForDObjFixed(dobj, nGCMatrixKindTraRotRpyR, 0)
		Objman.gcAddXObjForDObjFixed(dobj.child.sib_next, 0x46, 0)

		dobj.translate = translate                # REGION_US

		ip.multi = ITMBALL_SPAWN_WAIT

		ip.item_vars.mball.is_rebound = FALSE

		ip.is_unused_item_bool = TRUE

		dobj.rotate.z = 0.0

		ip.arrow_gobj = Ifcommon.ifCommonItemArrowMakeInterface(ip)

	return item_gobj
