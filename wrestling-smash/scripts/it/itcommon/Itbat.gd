## 1:1 port of src/it/itcommon/itbat.c (ssb-decomp-re): Home-Run Bat (swing item; the swing hitboxes are the
## fighter's, see Ftcommonitemswing).
##
## Data conventions: see Itbox (ITDesc / ITStatusDesc Dictionaries with the C field names; the ITAttributes
## and DObjDesc tree come from the ITCommonData tables in Itmanager.gd).
class_name Itbat
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itBatStatus
const nITBatStatusWait = 0
const nITBatStatusFall = 1
const nITBatStatusHold = 2
const nITBatStatusThrown = 3
const nITBatStatusDropped = 4
const nITBatStatusEnumCount = 5

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x80189990
static var dITBatItemDesc := {
	"kind": nITKindBat,                                       # Item Kind
	"p_file": "gITManagerCommonData",                         # Pointer to item file data?
	"o_attributes": "llITCommonDataBatItemAttributes",        # Offset of item attributes in file? (resolved by Itmanager)
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyR, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                        # Hitbox Update State
	"proc_update": Callable(Itbat, &"itBatFallProcUpdate"),
	"proc_map": Callable(Itbat, &"itBatFallProcMap"),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
}

## 0x801899C4
static var dITBatStatusDescs: Array = [
	# Status 0 (Ground Wait)
	{"proc_update": Callable(), "proc_map": Callable(Itbat, &"itBatWaitProcMap"), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 1 (Air Wait Fall)
	{"proc_update": Callable(Itbat, &"itBatFallProcUpdate"), "proc_map": Callable(Itbat, &"itBatFallProcMap"), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 2 (Fighter Hold)
	{"proc_update": Callable(), "proc_map": Callable(), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 3 (Fighter Throw)
	{"proc_update": Callable(Itbat, &"itBatThrownProcUpdate"), "proc_map": Callable(Itbat, &"itBatThrownProcMap"), "proc_hit": Callable(Itbat, &"itBatThrownProcHit"), "proc_shield": Callable(Itbat, &"itBatThrownProcHit"), "proc_hop": Callable(Itmain, &"itMainCommonProcHop"), "proc_setoff": Callable(Itbat, &"itBatThrownProcHit"), "proc_reflector": Callable(Itmain, &"itMainCommonProcReflector"), "proc_damage": Callable()},
	# Status 4 (Fighter Drop)
	{"proc_update": Callable(Itbat, &"itBatFallProcUpdate"), "proc_map": Callable(Itbat, &"itBatDroppedProcMap"), "proc_hit": Callable(Itbat, &"itBatThrownProcHit"), "proc_shield": Callable(Itbat, &"itBatThrownProcHit"), "proc_hop": Callable(Itmain, &"itMainCommonProcHop"), "proc_setoff": Callable(Itbat, &"itBatThrownProcHit"), "proc_reflector": Callable(Itmain, &"itMainCommonProcReflector"), "proc_damage": Callable()},
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80174E30
static func itBatFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITBAT_GRAVITY, ITBAT_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x80174E68
static func itBatWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itbat, &"itBatFallSetStatus"))

	return FALSE

## 0x80174E90 - (sic) ignores itMapCheckDestroyDropped's result
static func itBatFallProcMap(item_gobj) -> int:
	Itmap.itMapCheckDestroyDropped(item_gobj, ITBAT_MAP_REBOUND_COMMON, ITBAT_MAP_REBOUND_GROUND, Callable(Itbat, &"itBatWaitSetStatus"))

	return FALSE

## 0x80174EC4
static func itBatWaitSetStatus(item_gobj) -> void:
	Itmain.itMainSetGroundAllowPickup(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITBatStatusDescs, nITBatStatusWait)

## 0x80174EF8
static func itBatFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITBatStatusDescs, nITBatStatusFall)

## 0x80174F3C
static func itBatHoldSetStatus(item_gobj) -> void:
	DObjGetStruct(item_gobj).rotate.y = F_CST_DTOR32(0.0)

	Itmain.itMainSetStatus(item_gobj, dITBatStatusDescs, nITBatStatusHold)

## 0x80174F70
static func itBatThrownProcUpdate(item_gobj) -> int:
	Itmain.itMainApplyGravityClampTVel(itGetStruct(item_gobj), ITBAT_GRAVITY, ITBAT_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x80174FA8
static func itBatThrownProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITBAT_MAP_REBOUND_COMMON, ITBAT_MAP_REBOUND_GROUND, Callable(Itbat, &"itBatWaitSetStatus"))

## 0x80174FD8
static func itBatThrownProcHit(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.attack_coll.attack_state = nGMAttackStateOff

	Itmain.itMainVelSetRebound(item_gobj)

	return FALSE

## 0x80175000
static func itBatThrownSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITBatStatusDescs, nITBatStatusThrown)

	DObjGetStruct(item_gobj).child.rotate.y = F_CST_DTOR32(90.0)

## 0x80175044
static func itBatDroppedProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITBAT_MAP_REBOUND_COMMON, ITBAT_MAP_REBOUND_GROUND, Callable(Itbat, &"itBatWaitSetStatus"))

## 0x80175074
static func itBatDroppedSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITBatStatusDescs, nITBatStatusDropped)

	DObjGetStruct(item_gobj).child.rotate.y = F_CST_DTOR32(90.0)

## 0x801750B8
static func itBatMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITBatItemDesc, pos, vel, flags)

	if item_gobj != null:
		var ip := itGetStruct(item_gobj)

		DObjGetStruct(item_gobj).rotate.y = F_CST_DTOR32(90.0)

		ip.is_unused_item_bool = TRUE

		ip.arrow_gobj = Ifcommon.ifCommonItemArrowMakeInterface(ip)

	return item_gobj
