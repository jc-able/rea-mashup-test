## 1:1 port of src/it/itcommon/itsword.c (ssb-decomp-re): Beam Sword (swing item; the swing hitboxes are
## the fighter's, see Ftcommonitemswing).
##
## Data conventions: see Itbox (ITDesc / ITStatusDesc Dictionaries with the C field names; the ITAttributes
## and DObjDesc tree come from the ITCommonData tables in Itmanager.gd).
class_name Itsword
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itSwordStatus
const nITSwordStatusWait = 0
const nITSwordStatusFall = 1
const nITSwordStatusHold = 2
const nITSwordStatusThrown = 3
const nITSwordStatusDropped = 4
const nITSwordStatusEnumCount = 5

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

static var dITSwordItemDesc := {
	"kind": nITKindSword,                                     # Item Kind
	"p_file": "gITManagerCommonData",                         # Pointer to item file data?
	"o_attributes": "llITCommonDataSwordItemAttributes",      # Offset of item attributes in file? (resolved by Itmanager)
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                        # Hitbox Update State
	"proc_update": Callable(Itsword, &"itSwordFallProcUpdate"),
	"proc_map": Callable(Itsword, &"itSwordFallProcMap"),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
}

static var dITSwordStatusDescs: Array = [
	# Status 0 (Ground Wait)
	{"proc_update": Callable(), "proc_map": Callable(Itsword, &"itSwordWaitProcMap"), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 1 (Air Wait Fall)
	{"proc_update": Callable(Itsword, &"itSwordFallProcUpdate"), "proc_map": Callable(Itsword, &"itSwordFallProcMap"), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 2 (Fighter Hold)
	{"proc_update": Callable(), "proc_map": Callable(), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 3 (Fighter Throw)
	{"proc_update": Callable(Itsword, &"itSwordFallProcUpdate"), "proc_map": Callable(Itsword, &"itSwordThrownProcMap"), "proc_hit": Callable(Itsword, &"itSwordThrownProcHit"), "proc_shield": Callable(Itsword, &"itSwordThrownProcHit"), "proc_hop": Callable(Itmain, &"itMainCommonProcHop"), "proc_setoff": Callable(Itsword, &"itSwordThrownProcHit"), "proc_reflector": Callable(Itmain, &"itMainCommonProcReflector"), "proc_damage": Callable()},
	# Status 4 (Fighter Drop)
	{"proc_update": Callable(Itsword, &"itSwordFallProcUpdate"), "proc_map": Callable(Itsword, &"itSwordDroppedProcMap"), "proc_hit": Callable(Itsword, &"itSwordThrownProcHit"), "proc_shield": Callable(Itsword, &"itSwordThrownProcHit"), "proc_hop": Callable(Itmain, &"itMainCommonProcHop"), "proc_setoff": Callable(Itsword, &"itSwordThrownProcHit"), "proc_reflector": Callable(Itmain, &"itMainCommonProcReflector"), "proc_damage": Callable()},
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80174B50
static func itSwordFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITSWORD_GRAVITY, ITSWORD_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x80174B8C
static func itSwordWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itsword, &"itSwordFallSetStatus"))

	return FALSE

## 0x80174BB4
static func itSwordFallProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITSWORD_MAP_REBOUND_COMMON, ITSWORD_MAP_REBOUND_GROUND, Callable(Itsword, &"itSwordWaitSetStatus"))

## 0x80174BE4
static func itSwordWaitSetStatus(item_gobj) -> void:
	Itmain.itMainSetGroundAllowPickup(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITSwordStatusDescs, nITSwordStatusWait)

## 0x80174C18
static func itSwordFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITSwordStatusDescs, nITSwordStatusFall)

## 0x80174C5C
static func itSwordHoldSetStatus(item_gobj) -> void:
	DObjGetStruct(item_gobj).rotate.y = F_CST_DTOR32(0.0)

	Itmain.itMainSetStatus(item_gobj, dITSwordStatusDescs, nITSwordStatusHold)

## 0x80174C90
static func itSwordThrownProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITSWORD_MAP_REBOUND_COMMON, ITSWORD_MAP_REBOUND_GROUND, Callable(Itsword, &"itSwordWaitSetStatus"))

## 0x80174CC0
static func itSwordThrownProcHit(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.attack_coll.attack_state = nGMAttackStateOff

	Itmain.itMainVelSetRebound(item_gobj)

	return FALSE

## 0x80174CE8
static func itSwordThrownSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITSwordStatusDescs, nITSwordStatusThrown)

	DObjGetStruct(item_gobj).child.rotate.y = F_CST_DTOR32(90.0)

## 0x80174D2C
static func itSwordDroppedProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITSWORD_MAP_REBOUND_COMMON, ITSWORD_MAP_REBOUND_GROUND, Callable(Itsword, &"itSwordWaitSetStatus"))

## 0x80174D5C
static func itSwordDroppedSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITSwordStatusDescs, nITSwordStatusDropped)

	DObjGetStruct(item_gobj).child.rotate.y = F_CST_DTOR32(90.0)

## 0x80174DA0
static func itSwordMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITSwordItemDesc, pos, vel, flags)

	if item_gobj != null:
		var ip := itGetStruct(item_gobj)

		DObjGetStruct(item_gobj).rotate.y = F_CST_DTOR32(90.0)

		ip.is_unused_item_bool = TRUE

		ip.arrow_gobj = Ifcommon.ifCommonItemArrowMakeInterface(ip)

	return item_gobj
