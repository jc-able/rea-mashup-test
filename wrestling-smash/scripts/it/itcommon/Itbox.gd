## 1:1 port of src/it/itcommon/itbox.c (ssb-decomp-re): Crate (Box) container item, its smash pieces
## effect and its explosion.
##
## ITDesc / ITStatusDesc are Dictionaries with the C field names (Itmanager conventions). The C pair
## {p_file, o_attributes} is kept as {"p_file", "o_attributes": linker symbol}; Itmanager resolves the
## symbol to the ITCommonData table (src/relocData/251_ITCommonData.c, transcribed in Itmanager.gd, with
## the DObjDesc tree of 86_ITCommonObject.c). itGetAttackEvent(desc, &llITCommonData...AttackEvents) is
## Itmanager.itManagerGetCommonData(&"llITCommonData...AttackEvents") (Array of {timer, angle, damage, size}).
## The item manager ejects the top DObjDesc joint (lbCommonEjectTreeDObj) and itMainSetFighterHold
## re-inserts an attach joint above the model joint, which is why Hold/Thrown/Dropped write to ->child.
class_name Itbox
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itBoxStatus
const nITBoxStatusWait = 0
const nITBoxStatusFall = 1
const nITBoxStatusHold = 2
const nITBoxStatusThrown = 3
const nITBoxStatusDropped = 4
const nITBoxStatusExplode = 5
const nITBoxStatusEnumCount = 6

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## llITCommonDataBoxEffectDisplayList: display list of one smash piece (render-only, kept as its symbol).
const llITCommonDataBoxEffectDisplayList := "llITCommonDataBoxEffectDisplayList"


## 0x8018A320 (Vec2f)
const dITBoxItemSpawnVelocities: Array = [
	Vector2(0.0, 48.0),
	Vector2(-2.0, 48.0),
	Vector2(2.0, 48.0),
	Vector2(-5.0, 48.2),
	Vector2(0.0, 48.2),
	Vector2(5.2, 48.2),
]

## 0x8018A350
static var dITBoxItemDesc := {
	"kind": nITKindBox,                                       # Item Kind
	"p_file": "gITManagerCommonData",                       # Pointer to item file data?
	"o_attributes": "llITCommonDataBoxItemAttributes",      # Offset of item attributes in file? (src/relocData/251_ITCommonData.c, resolved by Itmanager)
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyR, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                        # Hitbox Update State
	"proc_update": Callable(Itbox, &"itBoxFallProcUpdate"),
	"proc_map": Callable(Itbox, &"itBoxFallProcMap"),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
	"visual_kind": "box",
}

## 0x8018A384
static var dITBoxStatusDescs: Array = [
	# Status 0 (Ground Wait)
	{
		"proc_update": Callable(),
		"proc_map": Callable(Itbox, &"itBoxWaitProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(Itbox, &"itBoxCommonProcDamage"),
	},
	# Status 1 (Air Wait Fall)
	{
		"proc_update": Callable(Itbox, &"itBoxFallProcUpdate"),
		"proc_map": Callable(Itbox, &"itBoxFallProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
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
		"proc_update": Callable(Itbox, &"itBoxFallProcUpdate"),
		"proc_map": Callable(Itbox, &"itBoxThrownProcMap"),
		"proc_hit": Callable(Itbox, &"itBoxCommonProcHit"),
		"proc_shield": Callable(Itbox, &"itBoxCommonProcHit"),
		"proc_hop": Callable(),
		"proc_setoff": Callable(Itbox, &"itBoxCommonProcHit"),
		"proc_reflector": Callable(Itbox, &"itBoxCommonProcHit"),
		"proc_damage": Callable(Itbox, &"itBoxCommonProcDamage"),
	},
	# Status 4 (Fighter Drop)
	{
		"proc_update": Callable(Itbox, &"itBoxFallProcUpdate"),
		"proc_map": Callable(Itbox, &"itBoxDroppedProcMap"),
		"proc_hit": Callable(Itbox, &"itBoxCommonProcHit"),
		"proc_shield": Callable(Itbox, &"itBoxCommonProcHit"),
		"proc_hop": Callable(),
		"proc_setoff": Callable(Itbox, &"itBoxCommonProcHit"),
		"proc_reflector": Callable(Itbox, &"itBoxCommonProcHit"),
		"proc_damage": Callable(Itbox, &"itBoxCommonProcDamage"),
	},
	# Status 5 (Neutral Explosion)
	{
		"proc_update": Callable(Itbox, &"itBoxExplodeProcUpdate"),
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

## 0x80179120 - Barrel/Crate smash GFX process
static func itBoxContainerSmashUpdateEffect(effect_gobj) -> void:
	var ep = _efGetStruct(effect_gobj)
	var dobj: DObj = DObjGetStruct(effect_gobj)

	ep.effect_vars.container.lifetime -= 1

	if ep.effect_vars.container.lifetime == 0:
		Efmanager.efManagerSetPrevStructAlloc(ep)
		Objman.gcEjectGObj(effect_gobj)
	else:
		while dobj != null:
			dobj.scale.y -= 1.3

			dobj.translate.x += dobj.scale.x # This makes no sense, seems this custom effect is very... custom
			dobj.translate.y += dobj.scale.y
			dobj.translate.z += dobj.scale.z

			dobj.rotate.x += dobj.anim_wait # ??? Seems to be rotation step, but only in this case? Otherwise -FLOAT32_MAX?
			dobj.rotate.y += dobj.anim_speed
			dobj.rotate.z += dobj.anim_frame

			dobj = dobj.sib_next

## 0x801791F4
static func itBoxContainerSmashMakeEffect(pos: Vector3) -> void:
	var effect_gobj
	var ep = _efManagerGetEffectNoForce()
	var dobj: DObj
	var dl

	if ep != null:
		effect_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindEffect, null, nGCCommonLinkIDEffect, GOBJ_PRIORITY_DEFAULT)

		if effect_gobj != null:
			Objman.gcAddGObjDisplay(effect_gobj, Callable(Objdisplay, &"gcDrawDObjTreeForGObj"), 11, GOBJ_PRIORITY_DEFAULT, ~0)

			# dl = attr->data - &llITCommonDataBoxDataStart + &llITCommonDataBoxEffectDisplayList
			dl = llITCommonDataBoxEffectDisplayList

			for i in ITCONTAINER_EFFECT_COUNT:
				dobj = Objman.gcAddDObjForGObj(effect_gobj, dl)

				Objman.gcAddXObjForDObjFixed(dobj, nGCMatrixKindTraRotRpyR, 0)

				dobj.translate = pos

				dobj.scale.x = (syUtilsRandFloat() * 48.0) + -24.0
				dobj.scale.y = (syUtilsRandFloat() * 50.0) + 10.0
				dobj.scale.z = (syUtilsRandFloat() * 32.0) + -16.0

				dobj.anim_wait = F_CLC_DTOR32((syUtilsRandFloat() * 100.0) + -50.0)
				dobj.anim_speed = F_CLC_DTOR32((syUtilsRandFloat() * 100.0) + -50.0)
				dobj.anim_frame = F_CLC_DTOR32((syUtilsRandFloat() * 100.0) + -50.0)

			ep.effect_vars.container.lifetime = ITCONTAINER_GFX_LIFETIME

			effect_gobj.user_data = ep # effect_gobj->user_data.p = ep;

			Objman.gcAddGObjProcess(effect_gobj, Callable(Itbox, &"itBoxContainerSmashUpdateEffect"), 1, 3)

## 0x80179424
static func itBoxCommonCheckSpawnItems(item_gobj) -> int:
	var random: int
	var spawn_item_num: int
	var kind: int
	var spawn_pos: int # &dITBoxItemSpawnVelocities[spawn_pos] (index of the first velocity used)
	var vel_identical: Vector3
	var weights_sum: int
	var item_count: int
	var vel_different: Vector3
	var weights: Itmanager.ITRandomWeights = Itmanager.gITManagerRandomWeights # &gITManagerRandomWeights

	Snd.func_800269C0_275C0(nSYAudioFGMContainerSmash)

	itBoxContainerSmashMakeEffect(DObjGetStruct(item_gobj).translate)

	if weights.weights_sum != 0:
		kind = Itmain.itMainGetWeightedItemKind(weights)

		if kind <= nITKindCommonEnd:
			random = syUtilsRandIntRange(5)

			if random < 2:
				spawn_item_num = 1

				spawn_pos = 0
			elif random < 3:
				spawn_item_num = 2

				spawn_pos = 1
			else:
				spawn_item_num = 3

				spawn_pos = 3

			if syUtilsRandIntRange(32) == 0: # 1 in 32 chance to spawn identical items
				vel_identical.z = 0.0

				for i in spawn_item_num:
					vel_identical.x = dITBoxItemSpawnVelocities[spawn_pos + i].x
					vel_identical.y = dITBoxItemSpawnVelocities[spawn_pos + i].y

					Itmanager.itManagerMakeItemSetupCommon(item_gobj, kind, DObjGetStruct(item_gobj).translate, vel_identical, (ITEM_FLAG_COLLPROJECT | ITEM_FLAG_PARENT_ITEM))
			else:
				weights_sum = weights.weights_sum
				item_count = weights.valids_num - 1

				weights.weights_sum = int(weights.blocks[item_count]) & 0xFFFF
				weights.valids_num = (weights.valids_num - 1) & 0xFF

				vel_different.z = 0.0

				for j in spawn_item_num:
					if j != 0:
						kind = Itmain.itMainGetWeightedItemKind(weights)

					vel_different.x = dITBoxItemSpawnVelocities[spawn_pos + j].x
					vel_different.y = dITBoxItemSpawnVelocities[spawn_pos + j].y

					Itmanager.itManagerMakeItemSetupCommon(item_gobj, kind, DObjGetStruct(item_gobj).translate, vel_different, (ITEM_FLAG_COLLPROJECT | ITEM_FLAG_PARENT_ITEM))

				weights.valids_num = (weights.valids_num + 1) & 0xFF
				weights.weights_sum = weights_sum & 0xFFFF

			Snd.func_800269C0_275C0(nSYAudioFGMFireFlowerShoot)

			return TRUE
	return FALSE

## 0x8017963C
static func itBoxFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITBOX_GRAVITY, ITBOX_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x80179674
static func itBoxWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itbox, &"itBoxFallSetStatus"))

	return FALSE

## 0x8017969C
static func itBoxCommonProcHit(item_gobj) -> int:
	if itBoxCommonCheckSpawnItems(item_gobj) != FALSE:
		return TRUE
	else:
		itBoxExplodeMakeEffectGotoSetStatus(item_gobj)

	return FALSE

## 0x801796D8
static func itBoxCommonProcDamage(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.percent_damage >= ITBOX_HEALTH_MAX:
		return itBoxCommonProcHit(item_gobj)
	else:
		return FALSE

## 0x80179718
static func itBoxFallProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITBOX_MAP_REBOUND_COMMON, ITBOX_MAP_REBOUND_GROUND, Callable(Itbox, &"itBoxWaitSetStatus"))

## 0x80179748
static func itBoxWaitSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	DObjGetStruct(item_gobj).rotate.z = syUtilsArcTan2(ip.coll_data.floor_angle.y, ip.coll_data.floor_angle.x) - F_CST_DTOR32(90.0)

	Itmain.itMainSetGroundAllowPickup(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITBoxStatusDescs, nITBoxStatusWait)

## 0x801797A4
static func itBoxFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITBoxStatusDescs, nITBoxStatusFall)

## 0x801797E8
static func itBoxHoldSetStatus(item_gobj) -> void:
	DObjGetStruct(item_gobj).child.rotate.z = 0.0
	DObjGetStruct(item_gobj).child.rotate.y = 0.0

	Itmain.itMainSetStatus(item_gobj, dITBoxStatusDescs, nITBoxStatusHold)

## 0x8017982C
static func itBoxThrownProcMap(item_gobj) -> int:
	if B(Itmap.itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_MAIN_MASK)):
		if itBoxCommonCheckSpawnItems(item_gobj) != FALSE:
			return TRUE
		else:
			itBoxExplodeMakeEffectGotoSetStatus(item_gobj)
	return FALSE

## 0x8017987C
static func itBoxThrownSetStatus(item_gobj) -> void:
	DObjGetStruct(item_gobj).child.rotate.y = F_CST_DTOR32(90.0)

	Itmain.itMainSetStatus(item_gobj, dITBoxStatusDescs, nITBoxStatusThrown)

## 0x801798B8 - Unused
static func func_ovl3_801798B8(item_gobj) -> int:
	Itmain.itMainVelSetRebound(item_gobj)

	return FALSE

## 0x801798DC
static func itBoxDroppedProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITBOX_MAP_REBOUND_COMMON, ITBOX_MAP_REBOUND_GROUND, Callable(Itbox, &"itBoxWaitSetStatus"))

## 0x8017990C
static func itBoxDroppedSetStatus(item_gobj) -> void:
	DObjGetStruct(item_gobj).child.rotate.y = F_CST_DTOR32(90.0)

	Itmain.itMainSetStatus(item_gobj, dITBoxStatusDescs, nITBoxStatusDropped)

## 0x80179948
static func itBoxExplodeProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.multi = (ip.multi + 1) & 0xFFFF # u16

	if ip.multi == ITBOX_EXPLODE_FRAME_END:
		return TRUE
	else:
		# itGetAttackEvent(dITBoxItemDesc, &llITCommonDataBoxAttackEvents)
		Itmain.itMainUpdateAttackEvent(item_gobj, Itmanager.itManagerGetCommonData(&"llITCommonDataBoxAttackEvents"))

	return FALSE

## 0x801799A4
static func itBoxMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITBoxItemDesc, pos, vel, flags)

	if item_gobj != null:
		var ip := itGetStruct(item_gobj)

		DObjGetStruct(item_gobj).rotate.y = F_CST_DTOR32(90.0)

		ip.is_damage_all = TRUE
		ip.is_unused_item_bool = TRUE

		ip.arrow_gobj = Ifcommon.ifCommonItemArrowMakeInterface(ip)

	return item_gobj

## 0x80179A34
static func itBoxExplodeInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.event_id = 0
	ip.multi = 0

	ip.attack_coll.fgm_id = nSYAudioFGMExplodeL

	ip.attack_coll.can_rehit_item = TRUE
	ip.attack_coll.can_hop = FALSE
	ip.attack_coll.can_reflect = FALSE

	ip.attack_coll.throw_mul = ITEM_THROW_DEFAULT
	ip.attack_coll.element = nGMHitElementFire

	ip.attack_coll.can_setoff = FALSE

	ip.damage_coll.hitstatus = nGMHitStatusNone

	Itmain.itMainClearOwnerStats(item_gobj)
	Itmain.itMainRefreshAttackColl(item_gobj)
	Itmain.itMainUpdateAttackEvent(item_gobj, Itmanager.itManagerGetCommonData(&"llITCommonDataBoxAttackEvents"))

## 0x80179AD4
static func itBoxExplodeSetStatus(item_gobj) -> void:
	itBoxExplodeInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITBoxStatusDescs, nITBoxStatusExplode)

## 0x80179B08
static func itBoxExplodeMakeEffectGotoSetStatus(item_gobj) -> void:
	var pc
	var ip := itGetStruct(item_gobj)
	var dobj: DObj = DObjGetStruct(item_gobj)

	ip.attack_coll.attack_state = nGMAttackStateOff

	ip.physics.vel_air.x = 0.0
	ip.physics.vel_air.y = 0.0
	ip.physics.vel_air.z = 0.0

	pc = Efmanager.efManagerSparkleWhiteMultiExplodeMakeEffect(dobj.translate)

	if pc != null:
		pc.xf.scale.z = ITBOX_EXPLODE_SCALE
		pc.xf.scale.y = ITBOX_EXPLODE_SCALE
		pc.xf.scale.x = ITBOX_EXPLODE_SCALE

	Efmanager.efManagerQuakeMakeEffect(1)

	DObjGetStruct(item_gobj).flags = DOBJ_FLAG_HIDDEN

	itBoxExplodeSetStatus(item_gobj)

# // // // // // // // // // // // //
# //         PORT HELPERS          //
# // // // // // // // // // // // //

## efGetStruct(effect_gobj): (EFStruct*)effect_gobj->user_data.p
static func _efGetStruct(effect_gobj):
	if effect_gobj.user_data != null:
		return effect_gobj.user_data
	return effect_gobj

## Port stand-in for the EFStruct that efManagerGetEffectNoForce() hands out, used only while
## src/ef/efmanager.c is still an unported stub (the stub returns NULL). In the original the smash
## pieces are only skipped when the effect pool is exhausted; skipping them here would also skip their
## 6 * ITCONTAINER_EFFECT_COUNT syUtilsRandFloat() calls and desynchronise the global RNG.
class ITContainerStandInEffect:
	var effect_vars := {"container": {"lifetime": 0}}

static func _efManagerGetEffectNoForce():
	var ep = Efmanager.efManagerGetEffectNoForce()

	if (ep == null) and StubLog.seen.has("Efmanager.efManagerGetEffectNoForce"):
		ep = ITContainerStandInEffect.new()
	return ep
