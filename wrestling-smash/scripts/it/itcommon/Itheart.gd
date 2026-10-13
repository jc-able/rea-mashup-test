## 1:1 port of src/it/itcommon/itheart.c (ssb-decomp-re): Heart Container (healing item; the heal itself is
## applied by the fighter-side pickup code).
##
## Data conventions: see Itbox (ITDesc / ITStatusDesc Dictionaries with the C field names; the ITAttributes,
## DObjDesc tree and attack events come from the ITCommonData tables in Itmanager.gd).
class_name Itheart
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itHeartStatus
const nITHeartStatusWait = 0
const nITHeartStatusFall = 1
const nITHeartStatusDropped = 2
const nITHeartStatusEnumCount = 3

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

static var dITHeartItemDesc := {
	"kind": nITKindHeart,                                     # Item Kind
	"p_file": "gITManagerCommonData",                       # Pointer to item file data?
	"o_attributes": "llITCommonDataHeartItemAttributes",      # Offset of item attributes in file? (src/relocData/251_ITCommonData.c, resolved by Itmanager)
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyR, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                        # Hitbox Update State
	"proc_update": Callable(Itheart, &"itHeartFallProcUpdate"),
	"proc_map": Callable(Itheart, &"itHeartFallProcMap"),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
	"visual_kind": "heart",
}

static var dITHeartStatusDescs: Array = [
	# Status 0 (Ground Wait)
	{
		"proc_update": Callable(),
		"proc_map": Callable(Itheart, &"itHeartWaitProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
	},
	# Status 1 (Air Wait Fall)
	{
		"proc_update": Callable(Itheart, &"itHeartFallProcUpdate"),
		"proc_map": Callable(Itheart, &"itHeartFallProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
	},
	# Status 2 (Fighter Drop)
	{
		"proc_update": Callable(Itheart, &"itHeartFallProcUpdate"),
		"proc_map": Callable(Itheart, &"itHeartDroppedProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
	},
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801746F0
static func itHeartFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITHEART_GRAVITY, ITHEART_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x80174728
static func itHeartWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itheart, &"itHeartFallSetStatus"))

	return FALSE

## 0x80174750
static func itHeartFallProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITHEART_MAP_REBOUND_COMMON, ITHEART_MAP_REBOUND_GROUND, Callable(Itheart, &"itHeartWaitSetStatus"))

## 0x80174780
static func itHeartWaitSetStatus(item_gobj) -> void:
	Itmain.itMainSetGroundAllowPickup(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITHeartStatusDescs, nITHeartStatusWait)

## 0x801747B4
static func itHeartFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITHeartStatusDescs, nITHeartStatusFall)

## 0x801747F8
static func itHeartDroppedProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITHEART_MAP_REBOUND_COMMON, ITHEART_MAP_REBOUND_GROUND, Callable(Itheart, &"itHeartWaitSetStatus"))

## 0x80174828
static func itHeartDroppedSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITHeartStatusDescs, nITHeartStatusDropped)

## 0x80174850
static func itHeartMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITHeartItemDesc, pos, vel, flags)
	var dobj: DObj
	var translate: Vector3 # REGION_US
	var ip: Item

	if item_gobj != null:
		# REGION_US
		dobj = DObjGetStruct(item_gobj)
		ip = itGetStruct(item_gobj)
		translate = dobj.translate

		Objman.gcAddXObjForDObjFixed(dobj, 0x2E, 0)

		dobj.translate = translate

		dobj.rotate.z = 0.0

		ip.is_unused_item_bool = TRUE

		ip.arrow_gobj = Ifcommon.ifCommonItemArrowMakeInterface(ip)

	return item_gobj
