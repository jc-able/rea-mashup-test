## 1:1 port of src/it/itcommon/ithammer.c (ssb-decomp-re): Hammer item (the hammer-wielding fighter
## statuses live in Fthammer / Ftcommonhammer*).
##
## Data conventions: see Itbox (ITDesc / ITStatusDesc Dictionaries with the C field names; the ITAttributes
## and DObjDesc tree come from the ITCommonData tables in Itmanager.gd).
class_name Ithammer
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itHammerStatus
const nITHammerStatusWait = 0
const nITHammerStatusFall = 1
const nITHammerStatusHold = 2
const nITHammerStatusThrown = 3
const nITHammerStatusDropped = 4
const nITHammerStatusEnumCount = 5

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

static var dITHammerItemDesc := {
	"kind": nITKindHammer,                                    # Item Kind
	"p_file": "gITManagerCommonData",                         # Pointer to item file data?
	"o_attributes": "llITCommonDataHammerItemAttributes",     # Offset of item attributes in file? (resolved by Itmanager)
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyR, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                        # Hitbox Update State
	"proc_update": Callable(Ithammer, &"itHammerFallProcUpdate"),
	"proc_map": Callable(Ithammer, &"itHammerFallProcMap"),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
}

static var dITHammerStatusDescs: Array = [
	# Status 0 (Ground Wait)
	{"proc_update": Callable(), "proc_map": Callable(Ithammer, &"itHammerWaitProcMap"), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 1 (Air Wait Fall)
	{"proc_update": Callable(Ithammer, &"itHammerFallProcUpdate"), "proc_map": Callable(Ithammer, &"itHammerFallProcMap"), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 2 (Fighter Hold)
	{"proc_update": Callable(), "proc_map": Callable(), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 3 (Fighter Throw)
	{"proc_update": Callable(Ithammer, &"itHammerThrownProcUpdate"), "proc_map": Callable(Ithammer, &"itHammerThrownProcMap"), "proc_hit": Callable(Ithammer, &"itHammerCommonProcHit"), "proc_shield": Callable(Ithammer, &"itHammerCommonProcHit"), "proc_hop": Callable(), "proc_setoff": Callable(Ithammer, &"itHammerCommonProcHit"), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 4 (Fighter Drop)
	{"proc_update": Callable(Ithammer, &"itHammerFallProcUpdate"), "proc_map": Callable(Ithammer, &"itHammerDroppedProcMap"), "proc_hit": Callable(Ithammer, &"itHammerCommonProcHit"), "proc_shield": Callable(Ithammer, &"itHammerCommonProcHit"), "proc_hop": Callable(), "proc_setoff": Callable(Ithammer, &"itHammerCommonProcHit"), "proc_reflector": Callable(), "proc_damage": Callable()},
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80176110
static func itHammerCommonSetColAnim(item_gobj) -> void:
	Itmain.itMainCheckSetColAnimID(item_gobj, nGMColAnimItemHammerEnd, 0)

## 0x80176134
static func itHammerFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITHAMMER_GRAVITY, ITHAMMER_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x8017616C
static func itHammerWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Ithammer, &"itHammerFallSetStatus"))

	return FALSE

## 0x80176194
static func itHammerFallProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITHAMMER_MAP_REBOUND_COMMON, ITHAMMER_MAP_REBOUND_GROUND, Callable(Ithammer, &"itHammerWaitSetStatus"))

## 0x801761C4
static func itHammerWaitSetStatus(item_gobj) -> void:
	Itmain.itMainSetGroundAllowPickup(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITHammerStatusDescs, nITHammerStatusWait)

## 0x801761F8
static func itHammerFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITHammerStatusDescs, nITHammerStatusFall)

## 0x8017623C
static func itHammerHoldSetStatus(item_gobj) -> void:
	DObjGetStruct(item_gobj).rotate.y = F_CST_DTOR32(0.0)

	Itmain.itMainSetStatus(item_gobj, dITHammerStatusDescs, nITHammerStatusHold)

## 0x80176270
static func itHammerThrownProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITHAMMER_GRAVITY, ITHAMMER_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x801762A8
static func itHammerThrownProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITHAMMER_MAP_REBOUND_COMMON, ITHAMMER_MAP_REBOUND_GROUND, Callable(Ithammer, &"itHammerWaitSetStatus"))

## 0x801762D8
static func itHammerCommonProcHit(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.attack_coll.attack_state = nGMAttackStateOff

	Itmain.itMainVelSetRebound(item_gobj)

	return FALSE

## 0x80176300
static func itHammerThrownSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITHammerStatusDescs, nITHammerStatusThrown)

	DObjGetStruct(item_gobj).child.rotate.y = F_CST_DTOR32(90.0)

	Ftparam.ftParamTryUpdateItemMusic()

## 0x80176348
static func itHammerDroppedProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITHAMMER_MAP_REBOUND_COMMON, ITHAMMER_MAP_REBOUND_GROUND, Callable(Ithammer, &"itHammerWaitSetStatus"))

## 0x80176378
static func itHammerDroppedSetStatus(item_gobj) -> void:
	Itmain.itMainClearColAnim(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITHammerStatusDescs, nITHammerStatusDropped)

	DObjGetStruct(item_gobj).child.rotate.y = F_CST_DTOR32(90.0)

	Ftparam.ftParamTryUpdateItemMusic()

## 0x8017633C8 (sic)
static func itHammerMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITHammerItemDesc, pos, vel, flags)

	if item_gobj != null:
		var ip := itGetStruct(item_gobj)

		DObjGetStruct(item_gobj).rotate.y = F_CST_DTOR32(90.0)

		ip.is_unused_item_bool = TRUE

		ip.arrow_gobj = Ifcommon.ifCommonItemArrowMakeInterface(ip)

	return item_gobj
