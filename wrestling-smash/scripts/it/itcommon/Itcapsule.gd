## 1:1 port of src/it/itcommon/itcapsule.c (ssb-decomp-re): Capsule container item (drops an item when
## broken or explodes when empty).
##
## Data conventions: see Itbox (ITDesc / ITStatusDesc Dictionaries with the C field names; the ITAttributes,
## DObjDesc tree and attack events come from the ITCommonData tables in Itmanager.gd).
class_name Itcapsule
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itCapsuleStatus
const nITCapsuleStatusWait = 0
const nITCapsuleStatusFall = 1
const nITCapsuleStatusHold = 2
const nITCapsuleStatusThrown = 3
const nITCapsuleStatusDropped = 4
const nITCapsuleStatusExplode = 5
const nITCapsuleStatusEnumCount = 6

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

static var dITCapsuleItemDesc := {
	"kind": nITKindCapsule,                                   # Item Kind
	"p_file": "gITManagerCommonData",                       # Pointer to item file data?
	"o_attributes": "llITCommonDataCapsuleItemAttributes",      # Offset of item attributes in file? (src/relocData/251_ITCommonData.c, resolved by Itmanager)
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyR, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                        # Hitbox Update State
	"proc_update": Callable(Itcapsule, &"itCapsuleFallProcUpdate"),
	"proc_map": Callable(Itcapsule, &"itCapsuleFallProcMap"),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(Itcapsule, &"itCapsuleCommonProcHit"),
	"visual_kind": "capsule",
}

static var dITCapsuleStatusDescs: Array = [
	# Status 0 (Ground Wait)
	{
		"proc_update": Callable(),
		"proc_map": Callable(Itcapsule, &"itCapsuleWaitProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(Itcapsule, &"itCapsuleCommonProcHit"),
	},
	# Status 1 (Air Fall Wait)
	{
		"proc_update": Callable(Itcapsule, &"itCapsuleFallProcUpdate"),
		"proc_map": Callable(Itcapsule, &"itCapsuleFallProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(Itcapsule, &"itCapsuleCommonProcHit"),
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
		"proc_update": Callable(Itcapsule, &"itCapsuleThrownProcUpdate"),
		"proc_map": Callable(Itcapsule, &"itCapsuleThrownProcMap"),
		"proc_hit": Callable(Itcapsule, &"itCapsuleCommonProcHit"),
		"proc_shield": Callable(Itcapsule, &"itCapsuleCommonProcHit"),
		"proc_hop": Callable(Itmain, &"itMainCommonProcHop"),
		"proc_setoff": Callable(Itcapsule, &"itCapsuleCommonProcHit"),
		"proc_reflector": Callable(Itcapsule, &"itCapsuleCommonProcHit"),
		"proc_damage": Callable(Itcapsule, &"itCapsuleCommonProcHit"),
	},
	# Status 4 (Fighter Drop)
	{
		"proc_update": Callable(Itcapsule, &"itCapsuleFallProcUpdate"),
		"proc_map": Callable(Itcapsule, &"itCapsuleDroppedProcMap"),
		"proc_hit": Callable(Itcapsule, &"itCapsuleCommonProcHit"),
		"proc_shield": Callable(Itcapsule, &"itCapsuleCommonProcHit"),
		"proc_hop": Callable(Itmain, &"itMainCommonProcHop"),
		"proc_setoff": Callable(Itcapsule, &"itCapsuleCommonProcHit"),
		"proc_reflector": Callable(Itcapsule, &"itCapsuleCommonProcHit"),
		"proc_damage": Callable(Itcapsule, &"itCapsuleCommonProcHit"),
	},
	# Status 5 (Fighter Hold) [sic - Neutral Explosion]
	{
		"proc_update": Callable(Itcapsule, &"itCapsuleExplodeProcUpdate"),
		"proc_map": Callable(),
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

## 0x80173F90
static func itCapsuleFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITCAPSULE_GRAVITY, ITCAPSULE_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x80173FCC
static func itCapsuleWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itcapsule, &"itCapsuleFallSetStatus"))

	return FALSE

## 0x80173FF4
static func itCapsuleCommonProcHit(item_gobj) -> int:
	if B(Itmain.itMainMakeContainerItem(item_gobj)):
		return TRUE
	else:
		itCapsuleExplodeMakeEffectGotoSetStatus(item_gobj)

	return FALSE

## 0x80174030
static func itCapsuleFallProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITCAPSULE_MAP_REBOUND_COMMON, ITCAPSULE_MAP_REBOUND_GROUND, Callable(Itcapsule, &"itCapsuleWaitSetStatus"))

## 0x80174064
static func itCapsuleWaitSetStatus(item_gobj) -> void:
	Itmain.itMainSetGroundAllowPickup(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITCapsuleStatusDescs, nITCapsuleStatusWait)

## 0x80174098
static func itCapsuleFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	Itmap.itMapSetAir(ip)

	ip.is_damage_all = TRUE

	ip.damage_coll.hitstatus = nGMHitStatusNormal

	Itmain.itMainSetStatus(item_gobj, dITCapsuleStatusDescs, nITCapsuleStatusFall)

## 0x801740FC
static func itCapsuleHoldSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITCapsuleStatusDescs, nITCapsuleStatusHold)

## 0x80174124
static func itCapsuleThrownProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITCAPSULE_GRAVITY, ITCAPSULE_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x80174160
static func itCapsuleThrownProcMap(item_gobj) -> int:
	if B(Itmap.itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_MAIN_MASK)):
		if B(Itmain.itMainMakeContainerItem(item_gobj)):
			return TRUE
		else:
			itCapsuleExplodeMakeEffectGotoSetStatus(item_gobj)
	return FALSE

## 0x801741B0
static func itCapsuleThrownSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_damage_all = TRUE

	ip.damage_coll.hitstatus = nGMHitStatusNormal

	Itmain.itMainSetStatus(item_gobj, dITCapsuleStatusDescs, nITCapsuleStatusThrown)

## 0x801741F0 - Unused
static func func_ovl3_801741F0(item_gobj) -> int:
	Itmain.itMainVelSetRebound(item_gobj)

	return FALSE

## 0x80174214
static func itCapsuleDroppedProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITCAPSULE_MAP_REBOUND_COMMON, ITCAPSULE_MAP_REBOUND_GROUND, Callable(Itcapsule, &"itCapsuleWaitSetStatus"))

## 0x80174248
static func itCapsuleDroppedSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITCapsuleStatusDescs, nITCapsuleStatusDropped)

## 0x80174270
static func itCapsuleExplodeProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.multi = (ip.multi + 1) & 0xFFFF # u16

	if ip.multi == ITCAPSULE_EXPLODE_FRAME_END:
		return TRUE

	# itGetAttackEvent(dITCapsuleItemDesc, &llITCommonDataCapsuleAttackEvents)
	Itmain.itMainUpdateAttackEvent(item_gobj, Itmanager.itManagerGetCommonData(&"llITCommonDataCapsuleAttackEvents"))

	return FALSE

## (no address comment in the C source; between 0x80174270 and 0x80174340)
static func itCapsuleMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITCapsuleItemDesc, pos, vel, flags)

	if item_gobj != null:
		var ip := itGetStruct(item_gobj)

		ip.is_unused_item_bool = TRUE

		ip.arrow_gobj = Ifcommon.ifCommonItemArrowMakeInterface(ip)

	return item_gobj

## 0x80174340
static func itCapsuleExplodeInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.multi = 0
	ip.event_id = 0
	ip.attack_coll.fgm_id = nSYAudioFGMExplodeL
	ip.attack_coll.throw_mul = ITEM_THROW_DEFAULT

	Snd.func_800269C0_275C0(nSYAudioFGMExplodeL)

	ip.attack_coll.can_rehit_item = TRUE
	ip.attack_coll.can_hop = FALSE
	ip.attack_coll.can_reflect = FALSE

	ip.attack_coll.element = nGMHitElementFire

	ip.attack_coll.can_setoff = FALSE

	ip.damage_coll.hitstatus = nGMHitStatusNone

	Itmain.itMainClearOwnerStats(item_gobj)
	Itmain.itMainRefreshAttackColl(item_gobj)

	Itmain.itMainUpdateAttackEvent(item_gobj, Itmanager.itManagerGetCommonData(&"llITCommonDataCapsuleAttackEvents"))

## 0x801743F4
static func itCapsuleExplodeSetStatus(item_gobj) -> void:
	itCapsuleExplodeInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITCapsuleStatusDescs, nITCapsuleStatusExplode)

## 0x80174428
static func itCapsuleExplodeMakeEffectGotoSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj: DObj = DObjGetStruct(item_gobj)
	var ep

	ip.attack_coll.attack_state = nGMAttackStateOff

	ip.physics.vel_air.x = 0.0
	ip.physics.vel_air.y = 0.0
	ip.physics.vel_air.z = 0.0

	ep = Efmanager.efManagerSparkleWhiteMultiExplodeMakeEffect(dobj.translate)

	if ep != null:
		ep.xf.scale.z = ITCAPSULE_EXPLODE_SCALE
		ep.xf.scale.y = ITCAPSULE_EXPLODE_SCALE
		ep.xf.scale.x = ITCAPSULE_EXPLODE_SCALE

	Efmanager.efManagerQuakeMakeEffect(1)

	DObjGetStruct(item_gobj).flags = DOBJ_FLAG_HIDDEN

	itCapsuleExplodeSetStatus(item_gobj)
