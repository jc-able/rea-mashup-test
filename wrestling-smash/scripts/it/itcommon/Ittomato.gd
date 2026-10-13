## 1:1 port of src/it/itcommon/ittomato.c (ssb-decomp-re): Maxim Tomato (healing item; the heal itself is
## applied by the fighter-side pickup code).
##
## Data conventions: see Itbox (ITDesc / ITStatusDesc Dictionaries with the C field names; the ITAttributes,
## DObjDesc tree and attack events come from the ITCommonData tables in Itmanager.gd).
class_name Ittomato
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itTomatoStatus
const nITTomatoStatusWait = 0
const nITTomatoStatusFall = 1
const nITTomatoStatusDropped = 2
const nITTomatoStatusEnumCount = 3

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

static var dITTomatoItemDesc := {
	"kind": nITKindTomato,                                    # Item Kind
	"p_file": "gITManagerCommonData",                       # Pointer to item file data?
	"o_attributes": "llITCommonDataTomatoItemAttributes",      # Offset of item attributes in file? (src/relocData/251_ITCommonData.c, resolved by Itmanager)
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyR, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                        # Hitbox Update State
	"proc_update": Callable(Ittomato, &"itTomatoFallProcUpdate"),
	"proc_map": Callable(Ittomato, &"itTomatoFallProcMap"),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
	"visual_kind": "tomato",
}

static var dITTomatoStatusDescs: Array = [
	# Status 0 (Ground Wait)
	{
		"proc_update": Callable(),
		"proc_map": Callable(Ittomato, &"itTomatoWaitProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
	},
	# Status 1 (Air Wait Fall)
	{
		"proc_update": Callable(Ittomato, &"itTomatoFallProcUpdate"),
		"proc_map": Callable(Ittomato, &"itTomatoFallProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
	},
	# Status 2 (Fighter Drop)
	{
		"proc_update": Callable(Ittomato, &"itTomatoFallProcUpdate"),
		"proc_map": Callable(Ittomato, &"itTomatoDroppedProcMap"),
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

## 0x801744C0
static func itTomatoFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITTOMATO_GRAVITY, ITTOMATO_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x801744FC
static func itTomatoWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Ittomato, &"itTomatoFallSetStatus"))

	return FALSE

## 0x80174524
static func itTomatoFallProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITTOMATO_MAP_REBOUND_COMMON, ITTOMATO_MAP_REBOUND_GROUND, Callable(Ittomato, &"itTomatoWaitSetStatus"))

## 0x80174554
static func itTomatoWaitSetStatus(item_gobj) -> void:
	Itmain.itMainSetGroundAllowPickup(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITTomatoStatusDescs, nITTomatoStatusWait)

## 0x80174588
static func itTomatoFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITTomatoStatusDescs, nITTomatoStatusFall)

## 0x801745CC
static func itTomatoDroppedProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITTOMATO_MAP_REBOUND_COMMON, ITTOMATO_MAP_REBOUND_GROUND, Callable(Ittomato, &"itTomatoWaitSetStatus"))

## 0x801745FC
static func itTomatoDroppedSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITTomatoStatusDescs, nITTomatoStatusDropped)

## 0x80174624
static func itTomatoMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITTomatoItemDesc, pos, vel, flags)
	var joint: DObj
	var translate: Vector3 # REGION_US
	var ip: Item

	if item_gobj != null:
		# REGION_US
		joint = DObjGetStruct(item_gobj)
		ip = itGetStruct(item_gobj)
		translate = joint.translate

		Objman.gcAddXObjForDObjFixed(joint, 0x2E, 0)

		joint.translate = translate

		ip.is_unused_item_bool = TRUE

		ip.arrow_gobj = Ifcommon.ifCommonItemArrowMakeInterface(ip)

	return item_gobj
