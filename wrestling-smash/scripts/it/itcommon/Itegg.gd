## 1:1 port of src/it/itcommon/itegg.c (ssb-decomp-re): Egg container item (laid by Chansey; drops an
## item when broken or explodes when empty).
##
## Data conventions: see Itbox (ITDesc / ITStatusDesc Dictionaries with the C field names; the ITAttributes,
## DObjDesc tree and attack events come from the ITCommonData tables in Itmanager.gd).
class_name Itegg
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itEggStatus
const nITEggStatusWait = 0
const nITEggStatusFall = 1
const nITEggStatusHold = 2
const nITEggStatusThrown = 3
const nITEggStatusDropped = 4
const nITEggStatusExplode = 5
const nITEggStatusEnumCount = 6

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

static var dITEggItemDesc := {
	"kind": nITKindEgg,                                       # Item Kind
	"p_file": "gITManagerCommonData",                       # Pointer to item file data?
	"o_attributes": "llITCommonDataEggItemAttributes",      # Offset of item attributes in file? (src/relocData/251_ITCommonData.c, resolved by Itmanager)
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                        # Hitbox Update State
	"proc_update": Callable(Itegg, &"itEggFallProcUpdate"),
	"proc_map": Callable(Itegg, &"itEggFallProcMap"),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(Itegg, &"itEggCommonProcHit"),
	"visual_kind": "egg",
}

static var dITEggStatusDescs: Array = [
	# Status 0 (Ground Wait)
	{
		"proc_update": Callable(),
		"proc_map": Callable(Itegg, &"itEggWaitProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(Itegg, &"itEggCommonProcHit"),
	},
	# Status 1 (Air Fall Wait)
	{
		"proc_update": Callable(Itegg, &"itEggFallProcUpdate"),
		"proc_map": Callable(Itegg, &"itEggFallProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(Itegg, &"itEggCommonProcHit"),
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
		"proc_update": Callable(Itegg, &"itEggThrownProcUpdate"),
		"proc_map": Callable(Itegg, &"itEggThrownProcMap"),
		"proc_hit": Callable(Itegg, &"itEggCommonProcHit"),
		"proc_shield": Callable(Itegg, &"itEggCommonProcHit"),
		"proc_hop": Callable(Itmain, &"itMainCommonProcHop"),
		"proc_setoff": Callable(Itegg, &"itEggCommonProcHit"),
		"proc_reflector": Callable(Itegg, &"itEggCommonProcHit"),
		"proc_damage": Callable(Itegg, &"itEggCommonProcHit"),
	},
	# Status 4 (Fighter Drop)
	{
		"proc_update": Callable(Itegg, &"itEggFallProcUpdate"),
		"proc_map": Callable(Itegg, &"itEggDroppedProcMap"),
		"proc_hit": Callable(Itegg, &"itEggCommonProcHit"),
		"proc_shield": Callable(Itegg, &"itEggCommonProcHit"),
		"proc_hop": Callable(Itmain, &"itMainCommonProcHop"),
		"proc_setoff": Callable(Itegg, &"itEggCommonProcHit"),
		"proc_reflector": Callable(Itegg, &"itEggCommonProcHit"),
		"proc_damage": Callable(Itegg, &"itEggCommonProcHit"),
	},
	# Status 5 (Neutral Explosion)
	{
		"proc_update": Callable(Itegg, &"itEggExplodeProcUpdate"),
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

## 0x801815C0
static func itEggFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj: DObj = DObjGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITEGG_GRAVITY, ITEGG_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	dobj.child.rotate.z = dobj.rotate.z

	return FALSE

## 0x80181618
static func itEggWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itegg, &"itEggFallSetStatus"))

	return FALSE

## 0x80181640
static func itEggCommonProcHit(item_gobj) -> int:
	if B(Itmain.itMainMakeContainerItem(item_gobj)):
		Efmanager.efManagerEggBreakMakeEffect(DObjGetStruct(item_gobj).translate)

		return TRUE
	else:
		itEggExplodeMakeEffectGotoSetStatus(item_gobj)

	return FALSE

## 0x80181688
static func itEggFallProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITEGG_MAP_REBOUND_COMMON, ITEGG_MAP_REBOUND_GROUND, Callable(Itegg, &"itEggWaitSetStatus"))

## 0x801816B8
static func itEggWaitSetModelVars(item_gobj) -> void:
	var dobj: DObj = DObjGetStruct(item_gobj)

	dobj.scale.z = 1.0
	dobj.scale.y = 1.0
	dobj.scale.x = 1.0

	dobj.child.rotate.z = dobj.rotate.z

## 0x801816E0
static func itEggWaitSetStatus(item_gobj) -> void:
	Itmain.itMainSetGroundAllowPickup(item_gobj)
	itEggWaitSetModelVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITEggStatusDescs, nITEggStatusWait)

## 0x8018171C
static func itEggFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	ip.damage_coll.hitstatus = nGMHitStatusNormal
	ip.attack_coll.attack_state = nGMAttackStateOff

	ip.is_damage_all = TRUE

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITEggStatusDescs, nITEggStatusFall)

## 0x80181778
static func itEggHoldSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITEggStatusDescs, nITEggStatusHold)

## 0x801817A0
static func itEggThrownProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj: DObj = DObjGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITEGG_GRAVITY, ITEGG_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	dobj.child.rotate.z = dobj.rotate.z

	return FALSE

## 0x801817F8
static func itEggThrownProcMap(item_gobj) -> int:
	if B(Itmap.itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_MAIN_MASK)):
		if B(Itmain.itMainMakeContainerItem(item_gobj)):
			Efmanager.efManagerEggBreakMakeEffect(DObjGetStruct(item_gobj).translate)

			return TRUE
		else:
			itEggExplodeMakeEffectGotoSetStatus(item_gobj)
	return FALSE

## 0x80181854
static func itEggThrownSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_damage_all = TRUE

	ip.damage_coll.hitstatus = nGMHitStatusNormal

	Itmain.itMainSetStatus(item_gobj, dITEggStatusDescs, nITEggStatusThrown)

## 0x80181894 - Unused
static func func_ovl3_80181894(item_gobj) -> int:
	Itmain.itMainVelSetRebound(item_gobj)

	return FALSE

## 0x801818B8
static func itEggDroppedProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITEGG_MAP_REBOUND_COMMON, ITEGG_MAP_REBOUND_GROUND, Callable(Itegg, &"itEggWaitSetStatus"))

## 0x801818E8
static func itEggDroppedSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_damage_all = TRUE

	ip.damage_coll.hitstatus = nGMHitStatusNormal

	Itmain.itMainSetStatus(item_gobj, dITEggStatusDescs, nITEggStatusDropped)

## 0x80181928
static func itEggExplodeProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.multi = (ip.multi + 1) & 0xFFFF # u16

	if ip.multi == ITEGG_EXPLODE_EFFECT_WAIT:
		Efmanager.efManagerEggBreakMakeEffect(DObjGetStruct(item_gobj).translate)

		return TRUE

	# itGetAttackEvent(dITEggItemDesc, &llITCommonDataEggAttackEvents)
	Itmain.itMainUpdateAttackEvent(item_gobj, Itmanager.itManagerGetCommonData(&"llITCommonDataEggAttackEvents"))

	return FALSE

## 0x80181998
static func itEggMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITEggItemDesc, pos, vel, flags)

	if item_gobj != null:
		var dobj: DObj = DObjGetStruct(item_gobj)
		var egg_ip := itGetStruct(item_gobj)

		egg_ip.is_unused_item_bool = TRUE

		egg_ip.arrow_gobj = Ifcommon.ifCommonItemArrowMakeInterface(egg_ip)

		Objman.gcAddXObjForDObjFixed(dobj.child, 0x2E, 0)

		dobj.translate = pos

		if flags & ITEM_FLAG_PARENT_ITEM: # (sic) a bit test of the parent kind value 3
			var spawn_ip := itGetStruct(parent_gobj)

			if (spawn_ip.kind == nITKindMLucky) and (syUtilsRandIntRange(2) == 0):
				dobj.child.rotate.y = F_CST_DTOR32(180.0)

				egg_ip.physics.vel_air.x = -egg_ip.physics.vel_air.x

				egg_ip.lr = -egg_ip.lr

	return item_gobj

## 0x80181AA8
static func itEggExplodeInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.multi = 0

	ip.event_id = 0

	ip.attack_coll.fgm_id = nSYAudioFGMExplodeL
	ip.attack_coll.throw_mul = ITEM_THROW_DEFAULT

	Snd.func_800269C0_275C0(nSYAudioFGMExplodeL)

	ip.attack_coll.can_rehit_item = TRUE
	ip.attack_coll.can_hop = FALSE
	ip.attack_coll.can_reflect = FALSE
	ip.attack_coll.can_setoff = FALSE
	ip.attack_coll.element = nGMHitElementFire

	ip.damage_coll.hitstatus = nGMHitStatusNone

	Itmain.itMainClearOwnerStats(item_gobj)
	Itmain.itMainRefreshAttackColl(item_gobj)
	# itGetAttackEvent(dITEggItemDesc, &llITCommonDataCapsuleAttackEvents) - Should this be llITCommonDataEggAttackEvents?
	Itmain.itMainUpdateAttackEvent(item_gobj, Itmanager.itManagerGetCommonData(&"llITCommonDataCapsuleAttackEvents"))

## 0x80181B5C
static func itEggExplodeSetStatus(item_gobj) -> void:
	itEggExplodeInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITEggStatusDescs, nITEggStatusExplode)

## 0x80181B90
static func itEggExplodeMakeEffectGotoSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj: DObj = DObjGetStruct(item_gobj)
	var ep

	ip.attack_coll.attack_state = nGMAttackStateOff

	ip.physics.vel_air.x = 0.0
	ip.physics.vel_air.y = 0.0
	ip.physics.vel_air.z = 0.0

	ep = Efmanager.efManagerSparkleWhiteMultiExplodeMakeEffect(dobj.translate)

	if ep != null:
		ep.xf.scale.z = ITEGG_EXPLODE_EFFECT_SCALE
		ep.xf.scale.y = ITEGG_EXPLODE_EFFECT_SCALE
		ep.xf.scale.x = ITEGG_EXPLODE_EFFECT_SCALE

	Efmanager.efManagerQuakeMakeEffect(1)

	DObjGetStruct(item_gobj).flags = DOBJ_FLAG_HIDDEN

	itEggExplodeSetStatus(item_gobj)
