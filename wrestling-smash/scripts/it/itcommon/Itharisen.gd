## 1:1 port of src/it/itcommon/itharisen.c (ssb-decomp-re): Fan (Harisen) swing item.
##
## Data conventions: see Itbox (ITDesc / ITStatusDesc Dictionaries with the C field names; the ITAttributes
## and DObjDesc tree come from the ITCommonData tables in Itmanager.gd).
class_name Itharisen
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itHarisenStatus
const nITHarisenStatusWait = 0
const nITHarisenStatusFall = 1
const nITHarisenStatusHold = 2
const nITHarisenStatusThrown = 3
const nITHarisenStatusDropped = 4
const nITHarisenStatusEnumCount = 5

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x80189A70 - offsets of the fan's two AnimJoint tables relative to llITCommonDataHarisenDataStart
const dITHarisenAnimJoint: Array = [0x2250, 0x2270]

static var dITHarisenItemDesc := {
	"kind": nITKindHarisen,                                   # Item Kind
	"p_file": "gITManagerCommonData",                         # Pointer to item file data?
	"o_attributes": "llITCommonDataHarisenItemAttributes",    # Offset of item attributes in file? (resolved by Itmanager)
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                        # Hitbox Update State
	"proc_update": Callable(Itharisen, &"itHarisenFallProcUpdate"),
	"proc_map": Callable(Itharisen, &"itHarisenFallProcMap"),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
}

static var dITHarisenStatusDescs: Array = [
	# Status 0 (Ground Wait)
	{"proc_update": Callable(), "proc_map": Callable(Itharisen, &"itHarisenWaitProcMap"), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 1 (Air Wait Fall)
	{"proc_update": Callable(Itharisen, &"itHarisenFallProcUpdate"), "proc_map": Callable(Itharisen, &"itHarisenFallProcMap"), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 2 (Fighter Hold)
	{"proc_update": Callable(), "proc_map": Callable(), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 3 (Fighter Throw)
	{"proc_update": Callable(Itharisen, &"itHarisenThrownProcUpdate"), "proc_map": Callable(Itharisen, &"itHarisenThrownProcMap"), "proc_hit": Callable(Itharisen, &"itHarisenCommonProcHit"), "proc_shield": Callable(Itharisen, &"itHarisenCommonProcHit"), "proc_hop": Callable(Itmain, &"itMainCommonProcHop"), "proc_setoff": Callable(Itharisen, &"itHarisenCommonProcHit"), "proc_reflector": Callable(Itmain, &"itMainCommonProcReflector"), "proc_damage": Callable()},
	# Status 4 (Fighter Drop)
	{"proc_update": Callable(Itharisen, &"itHarisenFallProcUpdate"), "proc_map": Callable(Itharisen, &"itHarisenDroppedProcMap"), "proc_hit": Callable(Itharisen, &"itHarisenCommonProcHit"), "proc_shield": Callable(Itharisen, &"itHarisenCommonProcHit"), "proc_hop": Callable(Itmain, &"itMainCommonProcHop"), "proc_setoff": Callable(Itharisen, &"itHarisenCommonProcHit"), "proc_reflector": Callable(Itmain, &"itMainCommonProcReflector"), "proc_damage": Callable()},
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80175140
static func itHarisenCommonSetScale(item_gobj, scale: float) -> void:
	DObjGetStruct(item_gobj).scale.x = scale
	DObjGetStruct(item_gobj).scale.y = scale
	DObjGetStruct(item_gobj).scale.z = scale

## 0x80175160
static func itHarisenFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITHARISEN_GRAVITY, ITHARISEN_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x80175198
static func itHarisenWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itharisen, &"itHarisenFallSetStatus"))

	return FALSE

## 0x801751C0 - (sic) ignores itMapCheckDestroyDropped's result
static func itHarisenFallProcMap(item_gobj) -> int:
	Itmap.itMapCheckDestroyDropped(item_gobj, ITHARISEN_MAP_REBOUND_COMMON, ITHARISEN_MAP_REBOUND_GROUND, Callable(Itharisen, &"itHarisenWaitSetStatus"))

	return FALSE

## 0x801751F4
static func itHarisenWaitSetStatus(item_gobj) -> void:
	Itmain.itMainSetGroundAllowPickup(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITHarisenStatusDescs, nITHarisenStatusWait)

## 0x80175228
static func itHarisenFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITHarisenStatusDescs, nITHarisenStatusFall)

## 0x8017526C
static func itHarisenHoldSetStatus(item_gobj) -> void:
	var dobj: DObj = DObjGetStruct(item_gobj)

	Objman.gcAddXObjForDObjFixed(dobj, nGCMatrixKindSca, 0)

	dobj.rotate.y = 0.0

	Itmain.itMainSetStatus(item_gobj, dITHarisenStatusDescs, nITHarisenStatusHold)

## 0x801752C0
static func itHarisenThrownProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITHARISEN_GRAVITY, ITHARISEN_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x801752F8
static func itHarisenThrownProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITHARISEN_MAP_REBOUND_COMMON, ITHARISEN_MAP_REBOUND_GROUND, Callable(Itharisen, &"itHarisenWaitSetStatus"))

## 0x80175328
static func itHarisenCommonProcHit(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.attack_coll.attack_state = nGMAttackStateOff

	Itmain.itMainVelSetRebound(item_gobj)

	return FALSE

## 0x80175350
static func itHarisenThrownSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITHarisenStatusDescs, nITHarisenStatusThrown)

	DObjGetStruct(item_gobj).child.rotate.y = F_CST_DTOR32(-90.0)

## 0x80175394
static func itHarisenDroppedProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITHARISEN_MAP_REBOUND_COMMON, ITHARISEN_MAP_REBOUND_GROUND, Callable(Itharisen, &"itHarisenWaitSetStatus"))

## 0x801753C4
static func itHarisenDroppedSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITHarisenStatusDescs, nITHarisenStatusDropped)

	DObjGetStruct(item_gobj).child.rotate.y = F_CST_DTOR32(-90.0)

## 0x80175408 - Unused
static func func_ovl3_80175408(item_gobj, index: int) -> void:
	var ip := itGetStruct(item_gobj)

	# (ip->attr->data + dITHarisenAnimJoint[index]) - &llITCommonDataHarisenDataStart
	ObjAnim.gcAddAnimJointAll(item_gobj, _itHarisenGetAnimJoint(ip, dITHarisenAnimJoint[index]), 0.0)
	ObjAnim.gcPlayAnimAll(item_gobj)

## 0x80175460
static func itHarisenMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITHarisenItemDesc, pos, vel, flags)

	if item_gobj != null:
		var ip := itGetStruct(item_gobj)

		DObjGetStruct(item_gobj).rotate.y = F_CST_DTOR32(-90.0)

		ip.is_unused_item_bool = TRUE

		ip.arrow_gobj = Ifcommon.ifCommonItemArrowMakeInterface(ip)

	return item_gobj

# // // // // // // // // // // // //
# //         PORT HELPERS          //
# // // // // // // // // // // // //

## The fan's AnimJoint tables in src/relocData/86_ITCommonObject.c (Harisen data remainder): the table at
## 0x2250 is {NULL, NULL, script @ 0x225C} (ScaZ 1.0 -> 2.5, open) and the table at 0x2270 is
## {NULL, NULL, script @ 0x227C} (ScaZ 2.5 -> ... -> 1.0, close); AObjEvent32 words
## (opcode << 25 | flags << 15 | payload, AOBJ_FLAG_SCAZ = 0x200) + raw f32 words.
static var _sITHarisenAnimJoints: Dictionary = {}

static func _itHarisenGetAnimJoint(ip, offset: int) -> Array:
	if _sITHarisenAnimJoints.is_empty():
		_sITHarisenAnimJoints[0x2250] = [null, null, AnimStream.from_u32([
			0x11000000, 0x3F800000,                 # SetVal0RateBlock(ScaZ, 0) 1.0
			0x11000005, 0x40200000,                 # SetVal0RateBlock(ScaZ, 5) 2.5
			0x00000000,                             # End
		], "dITCommonObject_Harisen_Item_data_remainder_gap_0x2248_sub_0x14")]
		_sITHarisenAnimJoints[0x2270] = [null, null, AnimStream.from_u32([
			0x11000000, 0x40200000,                 # SetVal0RateBlock(ScaZ, 0) 2.5
			0x0B000001, 0x3DCCCCCD, 0xBE2932A2,     # SetValRateBlock(ScaZ, 1) 0.1, -0.16523221
			0x11000001, 0x00000000,                 # SetVal0RateBlock(ScaZ, 1) 0.0
			0x0B000001, 0x3DCCCCCD, 0x3E974EE0,     # SetValRateBlock(ScaZ, 1) 0.1, 0.29552364
			0x0B000002, 0x3FA00000, 0x3E03A83B,     # SetValRateBlock(ScaZ, 2) 1.25, 0.12857144
			0x11000005, 0x3F800000,                 # SetVal0RateBlock(ScaZ, 5) 1.0
			0x00000000,                             # End
		], "dITCommonObject_Harisen_Item_data_remainder_gap_0x2248_sub_0x34")]
	return _sITHarisenAnimJoints.get(offset, [])
