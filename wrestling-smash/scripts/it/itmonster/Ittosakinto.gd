## 1:1 port of src/it/itmonster/ittosakinto.c (ssb-decomp-re): Poké Ball Goldeen.
##
## Make function (dITManagerProcMakeList entry, called through itManagerMakeItemKind):
##   Ittosakinto.itTosakintoMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int) -> item_gobj or null
## Shared conventions of the itmonster ports (descs, DObjDesc data, AnimJoints, u16 wrap): see Itpippi.gd.
class_name Ittosakinto
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itTosakintoStatus
const nITTosakintoStatusAppear = 0
const nITTosakintoStatusBounce = 1
const nITTosakintoStatusEnumCount = 2

# llITCommonData* linker offsets used by this file (tools/relocFileDescriptions.us.txt)
const llITCommonDataTosakintoDataStart = 0xB708
const llITCommonDataTosakintoAnimJoint = 0xB7CC
const llITCommonDataTosakintoMatAnimJoint = 0xB90C

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## AObjEvent32 script dITCommonObject_Tosakinto_Item_data_remainder_gap_0xB7B8_sub_0x14
## (86_ITCommonObject.c @ 0xB7CC == llITCommonDataTosakintoAnimJoint): Goldeen's flop loop on the
## model joint (child TraY / ScaX / ScaY). 75 words, identical to ROM file 86.
static var dITCommonObjectTosakintoAnimJoint: AnimStream = _itTosakintoMakeAnimJoint()

static func _itTosakintoMakeAnimJoint() -> AnimStream:
	var anim_joint := AnimStream.from_u32([
		0x12D00000, 0x00000000, 0x3F800000, 0x3F800000, # [0] aobjEvent32SetVal0Rate(AOBJ_FLAG_TRAY | AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 0): 0, 1, 1
		0x15280000, 0x00000000, 0x00000000, 0x3F800000, # [4] aobjEvent32SetValAfterBlock(AOBJ_FLAG_TRAX | AOBJ_FLAG_TRAZ | AOBJ_FLAG_SCAZ, 0): 0, 0, 1
		0x12100008, 0x41F00000, # [8] aobjEvent32SetVal0Rate(AOBJ_FLAG_TRAY, 8): 30
		0x10C00004, 0x3F666666, 0x3F8CCCCD, # [10] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 4): 0.899999976, 1.10000002
		0x10C00004, 0x3F800000, 0x3F800000, # [13] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 4): 1, 1
		0x12100008, 0x00000000, # [16] aobjEvent32SetVal0Rate(AOBJ_FLAG_TRAY, 8): 0
		0x10C00004, 0x3F666666, 0x3F8CCCCD, # [18] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 4): 0.899999976, 1.10000002
		0x10C00004, 0x3F800000, 0x3F800000, # [21] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 4): 1, 1
		0x12100008, 0x41F00000, # [24] aobjEvent32SetVal0Rate(AOBJ_FLAG_TRAY, 8): 30
		0x10C00004, 0x3F666666, 0x3F8CCCCD, # [26] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 4): 0.899999976, 1.10000002
		0x10C00004, 0x3F800000, 0x3F800000, # [29] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 4): 1, 1
		0x12100008, 0x00000000, # [32] aobjEvent32SetVal0Rate(AOBJ_FLAG_TRAY, 8): 0
		0x10C00004, 0x3F666666, 0x3F8CCCCD, # [34] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 4): 0.899999976, 1.10000002
		0x10C00004, 0x3F800000, 0x3F800000, # [37] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 4): 1, 1
		0x12100008, 0x41F00000, # [40] aobjEvent32SetVal0Rate(AOBJ_FLAG_TRAY, 8): 30
		0x10C00004, 0x3F666666, 0x3F8CCCCD, # [42] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 4): 0.899999976, 1.10000002
		0x10C00004, 0x3F800000, 0x3F800000, # [45] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 4): 1, 1
		0x12100008, 0x00000000, # [48] aobjEvent32SetVal0Rate(AOBJ_FLAG_TRAY, 8): 0
		0x10C00004, 0x3F666666, 0x3F8CCCCD, # [50] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 4): 0.899999976, 1.10000002
		0x10C00004, 0x3F800000, 0x3F800000, # [53] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 4): 1, 1
		0x12100008, 0x41F00000, # [56] aobjEvent32SetVal0Rate(AOBJ_FLAG_TRAY, 8): 30
		0x10C00004, 0x3F666666, 0x3F8CCCCD, # [58] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 4): 0.899999976, 1.10000002
		0x10C00004, 0x3F800000, 0x3F800000, # [61] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 4): 1, 1
		0x12100008, 0x00000000, # [64] aobjEvent32SetVal0Rate(AOBJ_FLAG_TRAY, 8): 0
		0x10C00004, 0x3F666666, 0x3F8CCCCD, # [66] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 4): 0.899999976, 1.10000002
		0x10C00004, 0x3F800000, 0x3F800000, # [69] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 4): 1, 1
		0x1C000000, # [72] aobjEvent32SetAnim(0x000, 0)
		0x00000000, # [73] (u32)dITCommonObject_Tosakinto_Item_data_remainder_gap_0xB7B8_sub_0x14
		0x00000000, # [74] aobjEvent32End()
	], "dITCommonObject_Tosakinto_Item_data_remainder_gap_0xB7B8_sub_0x14")
	anim_joint.ptr[73] = [anim_joint, 0] # SetAnim target: the start of this same script

	return anim_joint

## 0x8018ABC0
static var dITTosakintoItemDesc := {
	"kind": nITKindTosakinto,                                   # Item Kind
	"o_attributes": "llITCommonDataTosakintoItemAttributes",        # &gITManagerCommonData, &llITCommonDataTosakintoItemAttributes (item core table)

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindNull,                               # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"attack_state": nGMAttackStateOff,                          # Hitbox Update State
	"proc_update": Callable(Ittosakinto, &"itTosakintoCommonProcUpdate"),   # Proc Update
	"proc_map": Callable(Ittosakinto, &"itTosakintoCommonProcMap"),         # Proc Map
	"proc_hit": Callable(),                                     # Proc Hit
	"proc_shield": Callable(),                                  # Proc Shield
	"proc_hop": Callable(),                                     # Proc Hop
	"proc_setoff": Callable(),                                  # Proc Set-Off
	"proc_reflector": Callable(),                               # Proc Reflector
	"proc_damage": Callable(),                                  # Proc Damage

	"visual_kind": "monster_tosakinto",
}

## 0x8018ABF4
static var dITTosakintoStatusDescs: Array = [
	# Status 0 (Neutral Appear)
	{
		"proc_update": Callable(Ittosakinto, &"itTosakintoAppearProcUpdate"),   # Proc Update
		"proc_map": Callable(Ittosakinto, &"itTosakintoAppearProcMap"),         # Proc Map
		"proc_hit": Callable(),                                 # Proc Hit
		"proc_shield": Callable(),                              # Proc Shield
		"proc_hop": Callable(),                                 # Proc Hop
		"proc_setoff": Callable(),                              # Proc Set-Off
		"proc_reflector": Callable(),                           # Proc Reflector
		"proc_damage": Callable(),                              # Proc Damage
	},

	# Status 1 (Neutral Splash)
	{
		"proc_update": Callable(Ittosakinto, &"itTosakintoBounceProcUpdate"),   # Proc Update
		"proc_map": Callable(Ittosakinto, &"itTosakintoBounceProcMap"),         # Proc Map
		"proc_hit": Callable(),                                 # Proc Hit
		"proc_shield": Callable(),                              # Proc Shield
		"proc_hop": Callable(),                                 # Proc Hop
		"proc_setoff": Callable(),                              # Proc Set-Off
		"proc_reflector": Callable(),                           # Proc Reflector
		"proc_damage": Callable(),                              # Proc Damage
	},
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8017E7A0
static func itTosakintoAppearProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITTOSAKINTO_GRAVITY, ITTOSAKINTO_TVEL)

	return FALSE

## 0x8017E7CC
static func itTosakintoAppearProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmap.itMapTestAllCheckCollEnd(item_gobj)

	if ip.coll_data.mask_curr & MAP_FLAG_FLOOR:
		ip.physics.vel_air.y = ITTOSAKINTO_FLAP_VEL_Y

		itTosakintoBounceSetStatus(item_gobj)

		Snd.func_800269C0_275C0(nSYAudioFGMTosakintoSplash)

	return FALSE

## 0x8017E828
static func itTosakintoAppearSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.multi = ITTOSAKINTO_LIFETIME

	if ip.kind == nITKindTosakinto:
		Snd.func_800269C0_275C0(nSYAudioVoiceMBallTosakintoAppear)

	Itmain.itMainSetStatus(item_gobj, dITTosakintoStatusDescs, nITTosakintoStatusAppear)

## 0x8017E880
static func itTosakintoBounceProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITTOSAKINTO_GRAVITY, ITTOSAKINTO_TVEL)

	if ip.multi == 0:
		return TRUE

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x8017E8CC
static func itTosakintoBounceProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmap.itMapTestAllCheckCollEnd(item_gobj)

	if ip.coll_data.mask_curr & MAP_FLAG_FLOOR:
		ip.physics.vel_air.y = ITTOSAKINTO_FLAP_VEL_Y

		if syUtilsRandIntRange(2) != 0:
			ip.physics.vel_air.x = -ip.physics.vel_air.x

		Snd.func_800269C0_275C0(nSYAudioFGMTosakintoSplash)

	return FALSE

## 0x8017E93C
static func itTosakintoBounceInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)
	var anim_joint
	var matanim_joint

	ip.item_vars.tosakinto.pos = dobj.translate

	ip.physics.vel_air.y = ITTOSAKINTO_FLAP_VEL_Y
	ip.physics.vel_air.x = ITTOSAKINTO_FLAP_VEL_X

	if ip.kind == nITKindTosakinto:
		# itGetPData(ip, &llITCommonDataTosakintoDataStart, &llITCommonDataTosakintoAnimJoint) == ITCommonObject + 0xB7CC
		anim_joint = dITCommonObjectTosakintoAnimJoint

		ObjAnim.gcAddDObjAnimJoint(dobj.child, anim_joint, 0.0)

		# itGetPData(ip, &llITCommonDataTosakintoDataStart, &llITCommonDataTosakintoMatAnimJoint) == ITCommonObject + 0xB90C
		# (MatAnimJoint dITCommonObject_Tosakinto_Item_data_remainder_gap_0xB7B8_sub_0x154: material/texture animation, render only)
		matanim_joint = null

		ObjAnim.gcAddMObjMatAnimJoint(_itTosakintoGetMObj(dobj.child), matanim_joint, 0.0)

		ObjAnim.gcPlayAnimAll(item_gobj)

## 0x8017EA14
static func itTosakintoBounceSetStatus(item_gobj) -> void:
	itTosakintoBounceInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITTosakintoStatusDescs, nITTosakintoStatusBounce)

## 0x8017EA48
static func itTosakintoCommonProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		ip.physics.vel_air.y = 0.0

		itTosakintoAppearSetStatus(item_gobj)

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x8017EA98
static func itTosakintoCommonProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if B(Itmap.itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_FLOOR)):
		ip.physics.vel_air.y = 0.0

	return FALSE

## 0x8017EAD8
static func itTosakintoMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITTosakintoItemDesc, pos, vel, flags)
	var dobj: DObj
	var ip: Item

	if item_gobj != null:
		Itmain.itMainClearOwnerStats(item_gobj)

		dobj = DObjGetStruct(item_gobj)

		Objman.gcAddXObjForDObjFixed(dobj, nGCMatrixKindTraRotRpyR, 0)
		Objman.gcAddXObjForDObjFixed(dobj, 0x48, 0)

		dobj.translate = pos

		ip = itGetStruct(item_gobj)

		ip.multi = ITMONSTER_RISE_STOP_WAIT

		ip.physics.vel_air.z = 0.0
		ip.physics.vel_air.x = ip.physics.vel_air.z
		ip.physics.vel_air.y = ITMONSTER_RISE_VEL_Y

		dobj.translate.y -= ip.attr.map_coll_bottom

		# itGetMonsterAnimNode(ip, &llITCommonDataTosakintoDataStart) == ITCommonObject + 0x13624
		ObjAnim.gcAddDObjAnimJoint(dobj, Itpippi.dITCommonObjectMonsterAnimBank, 0.0)

	return item_gobj

# ---------------------------------------------------------------------------------------
# Port helper
# ---------------------------------------------------------------------------------------

## dobj->mobj (first MObj of the joint). MObjs are render-only in this port: none are created
## for items, a render layer may attach them as DObj meta "mobjs" (Grdisplay convention).
static func _itTosakintoGetMObj(dobj: DObj):
	if dobj == null:
		return null
	var mobjs: Array = dobj.get_meta(&"mobjs", [])

	return mobjs[0] if not mobjs.is_empty() else null
