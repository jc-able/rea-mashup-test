## 1:1 port of src/it/itmonster/itspear.c (ssb-decomp-re): Poké Ball Beedrill and the swarm weapon
## (nWPKindSpearSwarm; also used by Clefairy's Metronome as a Clefairy swarm). The weapon code lives
## in this C file, not in src/wp.
##
## Make function (dITManagerProcMakeList entry, called through itManagerMakeItemKind):
##   Itspear.itSpearMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int) -> item_gobj or null
## Shared conventions of the itmonster ports (descs, DObjDesc data, AnimJoints, u16 wrap): see Itpippi.gd.
## ITAttributes: llITCommonDataSpearItemAttributes (251_ITCommonData.c @ 0x098C); WPAttributes:
## llITCommonDataSpearSwarmWeaponAttributes (@ 0x09D4) / llITCommonDataPippiSwarmWeaponAttributes
## (@ 0x0CBC), from the item core's ROM-verified tables.
## Gameplay timing: the swarm call starts when the leader's AnimJoint brings item_gobj->anim_frame to
## ITSPEAR_SWARM_CALL_WAIT, so the Beedrill AnimJoint is transcribed below (13 x 4 frames, then End).
class_name Itspear
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itSpearStatus
const nITSpearStatusAppear = 0
const nITSpearStatusFly = 1
const nITSpearStatusEnumCount = 2

# llITCommonData* linker offsets used by this file (tools/relocFileDescriptions.us.txt)
const llITCommonDataSpearDataStart = 0xDF38
const llITCommonDataSpearAnimJoint = 0xDFFC
const llITCommonDataSpearMatAnimJoint = 0xE12C

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8018AE00
static var dITSpearItemDesc := {
	"kind": nITKindSpear,                                       # Item Kind
	"o_attributes": "llITCommonDataSpearItemAttributes",        # &gITManagerCommonData, &llITCommonDataSpearItemAttributes

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindTraRotRpyR,                         # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"attack_state": nGMAttackStateNew,                          # Hitbox Update State
	"proc_update": Callable(Itspear, &"itSpearCommonProcUpdate"),   # Proc Update
	"proc_map": Callable(Itspear, &"itSpearCommonProcMap"),         # Proc Map
	"proc_hit": Callable(),                                     # Proc Hit
	"proc_shield": Callable(),                                  # Proc Shield
	"proc_hop": Callable(),                                     # Proc Hop
	"proc_setoff": Callable(),                                  # Proc Set-Off
	"proc_reflector": Callable(),                               # Proc Reflector
	"proc_damage": Callable(),                                  # Proc Damage
}

## 0x8018AE34
static var dITSpearStatusDescs: Array = [
	# Status 0 (Neutral Appear)
	{
		"proc_update": Callable(Itspear, &"itSpearAppearProcUpdate"),
		"proc_map": Callable(), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},

	# Status 1 (Neutral Fly)
	{
		"proc_update": Callable(Itspear, &"itSpearFlyProcUpdate"),
		"proc_map": Callable(), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},
]

## 0x8018AE74
## "attributes" (&gITManagerCommonData + llITCommonDataSpearSwarmWeaponAttributes) is resolved on
## first use by _itSpearGetWeaponDesc().
static var dITSpearWeaponSwarmWeaponDesc := {
	"flags": 0x01,                                              # Render flags? (WEAPON_FLAG_DOBJDESC)
	"kind": nWPKindSpearSwarm,                                  # Weapon Kind
	"attributes": null,

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindTraRotRpyR,                         # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"proc_update": Callable(Itspear, &"itSpearWeaponSwarmProcUpdate"),  # Proc Update
	"proc_map": Callable(),                                     # Proc Map
	"proc_hit": Callable(),                                     # Proc Hit
	"proc_shield": Callable(),                                  # Proc Shield
	"proc_hop": Callable(),                                     # Proc Hop
	"proc_setoff": Callable(),                                  # Proc Set-Off
	"proc_reflector": Callable(),                               # Proc Reflector
	"proc_absorb": Callable(),                                  # Proc Absorb

	"visual_kind": "spear_swarm",
}

## 0x8018AEA8
## "attributes" (&gITManagerCommonData + llITCommonDataPippiSwarmWeaponAttributes) is resolved on
## first use by _itSpearGetWeaponDesc().
static var dITPippiWeaponSwarmWeaponDesc := {
	"flags": 0x01,                                              # Render flags? (WEAPON_FLAG_DOBJDESC)
	"kind": nWPKindSpearSwarm,                                  # Weapon Kind
	"attributes": null,

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindTraRotRpyR,                         # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"proc_update": Callable(Itspear, &"itSpearWeaponSwarmProcUpdate"),  # Proc Update
	"proc_map": Callable(),                                     # Proc Map
	"proc_hit": Callable(),                                     # Proc Hit
	"proc_shield": Callable(),                                  # Proc Shield
	"proc_hop": Callable(),                                     # Proc Hop
	"proc_setoff": Callable(),                                  # Proc Set-Off
	"proc_reflector": Callable(),                               # Proc Reflector
	"proc_absorb": Callable(),                                  # Proc Absorb

	"visual_kind": "pippi_swarm",
}

## AObjEvent32 script dITCommonObject_Spear_Item_data_remainder_sub_0x14
## (86_ITCommonObject.c @ 0xDFFC == llITCommonDataSpearAnimJoint): Beedrill's circling on the model
## joint (child TraX / TraY); its frame counter times the swarm call. 73 words, identical to ROM file 86.
static var dITCommonObjectSpearAnimJoint: AnimStream = AnimStream.from_u32([
	0x0C180000, 0x00000000, 0x42087FFF, 0x43430000, 0x3EC003EE, # [0] aobjEvent32SetValRate(AOBJ_FLAG_TRAX | AOBJ_FLAG_TRAY, 0): 0, 34.1249962, 195, 0.375029981
	0x14200000, 0x00000000, # [5] aobjEvent32SetValAfterBlock(AOBJ_FLAG_TRAZ, 0): 0
	0x0A180004, 0x430A0000, 0x41C2FFFF, 0x430A0010, 0xC1C2FFFF, # [7] aobjEvent32SetValRateBlock(AOBJ_FLAG_TRAX | AOBJ_FLAG_TRAY, 4): 138, 24.3749981, 138.000244, -24.3749981
	0x0A180004, 0x43430000, 0xBEBFFFF5, 0x00000000, 0xC2088008, # [12] aobjEvent32SetValRateBlock(AOBJ_FLAG_TRAX | AOBJ_FLAG_TRAY, 4): 195, -0.374999672, 0, -34.1250305
	0x0A180004, 0x43070000, 0xC1C30003, 0xC3070000, 0xC1C30003, # [17] aobjEvent32SetValRateBlock(AOBJ_FLAG_TRAX | AOBJ_FLAG_TRAY, 4): 135, -24.3750057, -135, -24.3750057
	0x0C080004, 0xB8700000, 0xC2070000, # [22] aobjEvent32SetValRate(AOBJ_FLAG_TRAX, 4): -5.7220459e-05, -33.75
	0x10100004, 0xC3430004, # [25] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_TRAY, 4): -195.000061
	0x0A180004, 0xC3070000, 0xC1C2FFFD, 0xC3070000, 0x41C30005, # [27] aobjEvent32SetValRateBlock(AOBJ_FLAG_TRAX | AOBJ_FLAG_TRAY, 4): -135, -24.3749943, -135, 24.3750095
	0x0C100004, 0x00000000, 0x42070001, # [32] aobjEvent32SetValRate(AOBJ_FLAG_TRAY, 4): 0, 33.7500038
	0x10080004, 0xC3430000, # [35] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_TRAX, 4): -195
	0x0A180004, 0xC3070000, 0x41C2FFFE, 0x43070000, 0x41C30000, # [37] aobjEvent32SetValRateBlock(AOBJ_FLAG_TRAX | AOBJ_FLAG_TRAY, 4): -135, 24.3749962, 135, 24.375
	0x0A180004, 0x00000000, 0x42087FFF, 0x43430002, 0x3EC003EE, # [42] aobjEvent32SetValRateBlock(AOBJ_FLAG_TRAX | AOBJ_FLAG_TRAY, 4): 0, 34.1249962, 195.000031, 0.375029981
	0x0A180004, 0x430A0000, 0x41C2FFFB, 0x430A0010, 0xC1C2FFFD, # [47] aobjEvent32SetValRateBlock(AOBJ_FLAG_TRAX | AOBJ_FLAG_TRAY, 4): 138, 24.3749905, 138.000244, -24.3749943
	0x0A180004, 0x43430000, 0xBEBFFFF5, 0x00000000, 0xC2088008, # [52] aobjEvent32SetValRateBlock(AOBJ_FLAG_TRAX | AOBJ_FLAG_TRAY, 4): 195, -0.374999672, 0, -34.1250305
	0x0A180004, 0x43070000, 0xC1C30005, 0xC3070000, 0xC1C30005, # [57] aobjEvent32SetValRateBlock(AOBJ_FLAG_TRAX | AOBJ_FLAG_TRAY, 4): 135, -24.3750095, -135, -24.3750095
	0x0C080004, 0xB8700000, 0xC2070001, # [62] aobjEvent32SetValRate(AOBJ_FLAG_TRAX, 4): -5.7220459e-05, -33.7500038
	0x10100004, 0xC3430004, # [65] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_TRAY, 4): -195.000061
	0x0A180004, 0xC3070000, 0xC1C2FFFD, 0xC3070000, 0x41C30005, # [67] aobjEvent32SetValRateBlock(AOBJ_FLAG_TRAX | AOBJ_FLAG_TRAY, 4): -135, -24.3749943, -135, 24.3750095
	0x00000000, # [72] aobjEvent32End()
], "dITCommonObject_Spear_Item_data_remainder_sub_0x14")

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8017FDC0
static func itSpearFlyCallSwarmMember(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	if ip.item_vars.spear.spear_spawn_wait <= 0:
		var pos: Vector3 = dobj.translate

		pos.y = ip.item_vars.spear.spear_spawn_pos_y

		pos.y += (ITSPEAR_SPAWN_OFF_Y_MUL * syUtilsRandFloat()) + ITSPEAR_SPAWN_OFF_Y_ADD

		itSpearFlyMakeSwarm(item_gobj, pos, ip.kind)

		ip.item_vars.spear.spear_spawn_count = (ip.item_vars.spear.spear_spawn_count - 1) & 0xFFFF # u16
		ip.item_vars.spear.spear_spawn_wait = syUtilsRandIntRange(ITSPEAR_SPAWN_WAIT_RANDOM) + ITSPEAR_SPAWN_WAIT_CONST

## 0x8017FE70
static func itSpearAppearProcUpdate(item_gobj) -> int:
	var dobj := DObjGetStruct(item_gobj)

	if item_gobj.anim_frame == ITSPEAR_SWARM_CALL_WAIT:
		dobj.child.anim_pos = -1 # dobj->child->anim_joint.event32 = NULL;

		itSpearFlySetStatus(item_gobj)

	return FALSE

## 0x8017FEB8
static func itSpearAppearInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	ip.multi = 0

	ip.physics.vel_air.y = 0

	if ip.kind == nITKindSpear:
		var anim_joint
		var matanim_joint

		# itGetPData(ip, &llITCommonDataSpearDataStart, &llITCommonDataSpearAnimJoint) == ITCommonObject + 0xDFFC
		anim_joint = dITCommonObjectSpearAnimJoint

		ObjAnim.gcAddDObjAnimJoint(dobj.child, anim_joint, 0.0)

		# itGetPData(ip, &llITCommonDataSpearDataStart, &llITCommonDataSpearMatAnimJoint) == ITCommonObject + 0xE12C
		# (dITCommonObject_Spear_Item_data_remainder_sub_0x144: material animation, render only)
		matanim_joint = null

		ObjAnim.gcAddMObjMatAnimJoint(_itSpearGetMObj(dobj.child), matanim_joint, 0.0)
		ObjAnim.gcPlayAnimAll(item_gobj)
		Snd.func_800269C0_275C0(nSYAudioVoiceMBallSpearAppear)

## 0x8017FF74
static func itSpearAppearSetStatus(item_gobj) -> void:
	itSpearAppearInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITSpearStatusDescs, nITSpearStatusAppear)

## 0x8017FFA8
static func itSpearFlyProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITSPEAR_GRAVITY, ITSPEAR_TVEL)

	ip.physics.vel_air.x += ITSPEAR_SWARM_CALL_VEL_X * ip.lr

	if ip.lr == +1:
		if dobj.translate.x >= (Mpcollision.gMPCollisionGroundData.map_bound_right - ITSPEAR_SWARM_CALL_OFF_X):
			ip.physics.vel_air.x = 0.0
			ip.physics.vel_air.y = 0.0

			if ip.item_vars.spear.spear_spawn_count != 0:
				itSpearFlyCallSwarmMember(item_gobj)

			else:
				return TRUE

			ip.item_vars.spear.spear_spawn_wait -= 1

	if ip.lr == -1:
		if dobj.translate.x <= (Mpcollision.gMPCollisionGroundData.map_bound_left + ITSPEAR_SWARM_CALL_OFF_X):
			ip.physics.vel_air.x = 0.0
			ip.physics.vel_air.y = 0.0

			if ip.item_vars.spear.spear_spawn_count != 0:
				itSpearFlyCallSwarmMember(item_gobj)

			else:
				return TRUE

			ip.item_vars.spear.spear_spawn_wait -= 1

	return FALSE

## 0x8018010C
static func itSpearFlyInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.physics.vel_air.y = ITSPEAR_SWARM_CALL_VEL_Y

	ip.item_vars.spear.spear_spawn_pos_y = DObjGetStruct(item_gobj).translate.y
	ip.item_vars.spear.spear_spawn_wait = 0
	ip.item_vars.spear.spear_spawn_count = ITSPEAR_SPAWN_COUNT

	if ip.kind == nITKindSpear:
		Snd.func_800269C0_275C0(nSYAudioVoiceMBallSpearSwarm)

## 0x80180160
static func itSpearFlySetStatus(item_gobj) -> void:
	itSpearFlyInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITSpearStatusDescs, nITSpearStatusFly)

## 0x80180194
static func itSpearCommonProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		itSpearAppearSetStatus(item_gobj)

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x801801D8
static func itSpearCommonProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if B(Itmap.itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_FLOOR)):
		ip.physics.vel_air.y = 0.0

	return FALSE

## 0x80180218
static func itSpearMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITSpearItemDesc, pos, vel, flags)
	var dobj: DObj
	var ip: Item

	if item_gobj != null:
		ip = itGetStruct(item_gobj)

		Itmain.itMainClearOwnerStats(item_gobj)

		dobj = DObjGetStruct(item_gobj)

		Objman.gcAddXObjForDObjFixed(dobj.child, 0x48, 0)

		dobj.translate = pos

		if syUtilsRandIntRange(2) == 0:
			dobj.child.rotate.y = F_CST_DTOR32(180.0)

			ip.lr = -1

		else:
			ip.lr = +1

		ip.multi = ITMONSTER_RISE_STOP_WAIT

		ip.attack_coll.interact_mask = GMHITCOLLISION_FLAG_FIGHTER

		ip.physics.vel_air.z = 0.0
		ip.physics.vel_air.x = ip.physics.vel_air.z
		ip.physics.vel_air.y = ITMONSTER_RISE_VEL_Y

		dobj.translate.y -= ip.attr.map_coll_bottom

		# itGetMonsterAnimNode(ip, &llITCommonDataSpearDataStart) == ITCommonObject + 0x13624
		ObjAnim.gcAddDObjAnimJoint(dobj.child, Itpippi.dITCommonObjectMonsterAnimBank, 0.0)

	return item_gobj

## 0x80180354
static func itSpearWeaponSwarmProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var dobj := DObjGetStruct(weapon_gobj)

	if (wp.lr == +1) and (dobj.translate.x >= (Mpcollision.gMPCollisionGroundData.map_bound_right - ITSPEAR_SWARM_CALL_OFF_X)):
		return TRUE

	elif (wp.lr == -1) and (dobj.translate.x <= (Mpcollision.gMPCollisionGroundData.map_bound_left + ITSPEAR_SWARM_CALL_OFF_X)):
		return TRUE

	else:
		return FALSE

## 0x80180400
static func itPippiWeaponSwarmRenderSwarm(item_gobj) -> void:
	# gDPPipeSync(gSYTaskmanDLHeads[0]++);

	# gDPSetRenderMode(gSYTaskmanDLHeads[0]++, G_RM_AA_XLU_SURF, G_RM_AA_XLU_SURF2);

	Objdisplay.gcDrawDObjTreeForGObj(item_gobj)

	# gDPPipeSync(gSYTaskmanDLHeads[0]++);

## 0x80180480
static func itPippiWeaponSwarmProcDisplay(item_gobj) -> void:
	Wpdisplay.wpDisplayMain(item_gobj, Callable(Itspear, &"itPippiWeaponSwarmRenderSwarm"))

## 0x801804A4
static func itSpearWeaponSwarmMakeWeapon(item_gobj, pos: Vector3, kind: int):
	var ip := itGetStruct(item_gobj)
	var weapon_gobj = Wpmanager.wpManagerMakeWeapon(item_gobj, (_itSpearGetWeaponDesc(dITSpearWeaponSwarmWeaponDesc, "llITCommonDataSpearSwarmWeaponAttributes") if (kind == nITKindSpear) else _itSpearGetWeaponDesc(dITPippiWeaponSwarmWeaponDesc, "llITCommonDataPippiSwarmWeaponAttributes")), pos, WEAPON_FLAG_PARENT_ITEM)
	var dobj: DObj
	var wp: Weapon

	if weapon_gobj == null:
		return null

	wp = wpGetStruct(weapon_gobj)

	wp.lr = -ip.lr

	wp.physics.vel_air.x = wp.lr * ITSPEAR_SWARM_FLY_VEL_X

	dobj = DObjGetStruct(weapon_gobj)

	if kind == nITKindSpear:
		Objman.gcAddXObjForDObjFixed(dobj.child.child, 0x48, 0)

		if wp.lr == -1:
			dobj.child.child.rotate.y = F_CST_DTOR32(180.0)

	else:
		weapon_gobj.display_proc = Callable(Itspear, &"itPippiWeaponSwarmProcDisplay") # weapon_gobj->proc_display

		Objman.gcAddXObjForDObjFixed(dobj.child, 0x48, 0)

		if wp.lr == +1:
			dobj.child.rotate.y = F_CST_DTOR32(180.0)

	dobj.translate = pos

	wp.is_hitlag_victim = TRUE

	return weapon_gobj

## 0x80180608
static func itSpearFlyMakeSwarm(item_gobj, pos: Vector3, kind: int) -> void:
	itSpearWeaponSwarmMakeWeapon(item_gobj, pos, kind)

# ---------------------------------------------------------------------------------------
# Port helpers
# ---------------------------------------------------------------------------------------

## WPDesc with lbRelocGetFileData(WPAttributes*, gITManagerCommonData, &o_attributes) resolved
## (item core table).
static func _itSpearGetWeaponDesc(wp_desc: Dictionary, o_attributes: String) -> Dictionary:
	if wp_desc.attributes == null:
		wp_desc.attributes = Itmanager.itManagerGetCommonData(o_attributes)

	return wp_desc

## dobj->mobj (first MObj of the joint); MObjs are render-only in this port (see Itpippi.gd).
static func _itSpearGetMObj(dobj: DObj):
	if dobj == null:
		return null
	var mobjs: Array = dobj.get_meta(&"mobjs", [])

	return mobjs[0] if not mobjs.is_empty() else null
