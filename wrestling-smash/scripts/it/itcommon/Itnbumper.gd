## Port of src/it/itcommon/itnbumper.c (Bumper).
##
## * ITDesc: {p_file = &gITManagerCommonData, o_attributes = &llITCommonDataNBumperItemAttributes} is given as
##   the linker symbol name; Itmanager resolves it to its ROM-verified transcription of
##   src/relocData/251_ITCommonData.c dITCommonData_NBumper_ItemAttributes (file 251 @ 0x069C).
## * item_vars.bumper.{hit_anim_length, damage_all_delay} are u16 (`damage_all_delay != -1` is always TRUE and
##   `hit_anim_length--` wraps), ip->multi is u16, ip->attach_line_id is u16.
## * dobj->mobj->palette_id gates hit_anim_length, so it is kept on the MObj stand-in (Itmball.itPortGetDObjMObj).
##   gcRemoveMObjAll + gcAddMObjForDObj (render stubs) are followed by the stand-in reset to a fresh MObj.
## * itGetPData(ip, &llITCommonDataNBumperDataStart, &X) == ITCommonObject (file 86) offset X: the wait display
##   list (0x7AF8) and MObjSub (0x7A38) are render-only symbolic markers (86_ITCommonObject.c symbol names).
class_name Itnbumper
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itNBumperStatus
const nITNBumperStatusWait = 0          # Ground neutral
const nITNBumperStatusFall = 1          # Airborne neutral
const nITNBumperStatusHold = 2          # Fighter hold
const nITNBumperStatusThrown = 3        # Fighter throw
const nITNBumperStatusDropped = 4       # Fighter drop
const nITNBumperStatusAttached = 5      # Ground active
const nITNBumperStatusHitAir = 6        # Airborne hit
const nITNBumperStatusGDisappear = 7    # Ground despawn
const nITNBumperStatusEnumCount = 8

# // // // // // // // // // // // //
# //      RELOC DATA (markers)     //
# // // // // // // // // // // // //

## llITCommonDataNBumperWaitDisplayList (file 86 @ 0x7AF8)
const llITCommonDataNBumperWaitDisplayList := "dITCommonObject_NBumper_Item_data_remainder_gap_0x76CC_sub_0x42C"
## llITCommonDataNBumperWaitMObjSub (file 86 @ 0x7A38)
const llITCommonDataNBumperWaitMObjSub := "dITCommonObject_NBumper_Item_data_remainder_gap_0x76CC_sub_0x36C"

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8018A690
static var dITNBumperItemDesc := {
	"kind": nITKindNBumper,                                     # Item Kind
	"o_attributes": "llITCommonDataNBumperItemAttributes",      # p_file = &gITManagerCommonData
	"transform_types": {"tk1": nGCMatrixKindTra, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                          # Hitbox Update State
	"proc_update": Callable(Itnbumper, &"itNBumperFallProcUpdate"),
	"proc_map": Callable(Itnbumper, &"itNBumperFallProcMap"),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
}

## 0x8018A6C4
static var dITNBumperStatusDescs: Array = [
	# Status 0 (Ground Wait)
	{
		"proc_update": Callable(),
		"proc_map": Callable(Itnbumper, &"itNBumperWaitProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
	},
	# Status 1 (Air Wait Fall)
	{
		"proc_update": Callable(Itnbumper, &"itNBumperFallProcUpdate"),
		"proc_map": Callable(Itnbumper, &"itNBumperFallProcMap"),
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
		"proc_update": Callable(Itnbumper, &"itNBumperThrownProcUpdate"),
		"proc_map": Callable(Itnbumper, &"itNBumperThrownProcMap"),
		"proc_hit": Callable(Itnbumper, &"itNBumperThrownProcHit"),
		"proc_shield": Callable(Itnbumper, &"itNBumperThrownProcShield"),
		"proc_hop": Callable(Itmain, &"itMainCommonProcHop"),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(Itnbumper, &"itNBumperThrownProcReflector"),
		"proc_damage": Callable(),
	},
	# Status 4 (Fighter Drop)
	{
		"proc_update": Callable(Itnbumper, &"itNBumperThrownProcUpdate"),
		"proc_map": Callable(Itnbumper, &"itNBumperThrownProcMap"),
		"proc_hit": Callable(Itnbumper, &"itNBumperThrownProcHit"),
		"proc_shield": Callable(Itnbumper, &"itNBumperThrownProcShield"),
		"proc_hop": Callable(Itmain, &"itMainCommonProcHop"),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(Itnbumper, &"itNBumperThrownProcReflector"),
		"proc_damage": Callable(),
	},
	# Status 5 (Ground Active Wait)
	{
		"proc_update": Callable(Itnbumper, &"itNBumperAttachedProcUpdate"),
		"proc_map": Callable(Itnbumper, &"itNBumperAttachedProcMap"),
		"proc_hit": Callable(Itnbumper, &"itNBumperAttachedProcHit"),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(Itnbumper, &"itNBumperAttachedProcReflector"),
		"proc_damage": Callable(),
	},
	# Status 6 (Airborne after Ground Active Wait)
	{
		"proc_update": Callable(Itnbumper, &"itNBumperHitAirProcUpdate"),
		"proc_map": Callable(Itnbumper, &"itNBumperThrownProcMap"),
		"proc_hit": Callable(Itnbumper, &"itNBumperThrownProcHit"),
		"proc_shield": Callable(Itnbumper, &"itNBumperThrownProcShield"),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(Itnbumper, &"itNBumperThrownProcReflector"),
		"proc_damage": Callable(),
	},
	# Status 7 (Despawn)
	{
		"proc_update": Callable(Itnbumper, &"itNBumperGDisappearProcUpdate"),
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

## (2.0F - (10 - multi) * 0.1F) in single precision
static func _itNBumperGetHitScale(multi: int) -> float:
	return f32(2.0 - f32((10 - multi) * f32(0.1)))

## 0x8017B430
static func itNBumperFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITBUMPER_GRAVITY_NORMAL, ITBUMPER_TVEL)

	if ip.multi != 0:
		var s: float = _itNBumperGetHitScale(ip.multi)

		dobj.scale = Vector3(s, s, s)

		ip.multi = (ip.multi - 1) & 0xFFFF   # u16 multi
	else:
		dobj.scale = Vector3(1.0, 1.0, 1.0)

	if not ip.item_vars.bumper.damage_all_delay:
		Itmain.itMainClearOwnerStats(item_gobj)

		ip.item_vars.bumper.damage_all_delay = -1 & 0xFFFF       # u16: 0xFFFF
	if ip.item_vars.bumper.damage_all_delay != -1:               # u16 vs -1: always TRUE (ROM behaviour)
		ip.item_vars.bumper.damage_all_delay = (ip.item_vars.bumper.damage_all_delay - 1) & 0xFFFF
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x8017B520
static func itNBumperWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itnbumper, &"itNBumperFallSetStatus"))

	return FALSE

## 0x8017B548
static func itNBumperFallProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITBUMPER_MAP_REBOUND_COMMON, ITBUMPER_MAP_REBOUND_GROUND, Callable(Itnbumper, &"itNBumperWaitSetStatus"))

## 0x8017B57C
static func itNBumperThrownProcHit(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	dobj.scale.x = 2.0
	dobj.scale.y = 2.0
	dobj.scale.z = 2.0

	ip.item_vars.bumper.hit_anim_length = ITBUMPER_HIT_ANIM_LENGTH

	Itmball.itPortGetDObjMObj(dobj).palette_id = 1.0

	ip.physics.vel_air.x = ITBUMPER_REBOUND_AIR_X * ip.hit_lr
	ip.physics.vel_air.y = ITBUMPER_REBOUND_AIR_Y

	ip.multi = ITBUMPER_HIT_SCALE

	itNBumperHitAirSetStatus(item_gobj)

	return FALSE

## 0x8017B600
static func itNBumperWaitSetStatus(item_gobj) -> void:
	Itmain.itMainSetGroundAllowPickup(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITNBumperStatusDescs, nITNBumperStatusWait)

## 0x8017B634
static func itNBumperFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITNBumperStatusDescs, nITNBumperStatusFall)

## 0x8017B678
static func itNBumperHoldSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITNBumperStatusDescs, nITNBumperStatusHold)

## 0x8017B6A0
static func itNBumperThrownProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITBUMPER_GRAVITY_NORMAL, ITBUMPER_TVEL)

	if not ip.item_vars.bumper.damage_all_delay:
		Itmain.itMainClearOwnerStats(item_gobj)

		ip.item_vars.bumper.damage_all_delay = -1 & 0xFFFF       # u16: 0xFFFF
	if ip.item_vars.bumper.damage_all_delay != -1:               # u16 vs -1: always TRUE (ROM behaviour)
		ip.item_vars.bumper.damage_all_delay = (ip.item_vars.bumper.damage_all_delay - 1) & 0xFFFF
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x8017B720
static func itNBumperThrownProcMap(item_gobj) -> int:
	return Itmap.itMapCheckMapReboundProcNoFloor(item_gobj, 0.8, Callable(Itnbumper, &"itNBumperAttachedSetStatus"))

## 0x8017B74C
static func itNBumperThrownProcShield(item_gobj) -> int:
	Itmain.itMainVelSetRebound(item_gobj)
	Itmain.itMainClearOwnerStats(item_gobj)

	return FALSE

## 0x8017B778
static func itNBumperThrownProcReflector(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var fp := ftGetStruct(ip.owner_gobj)

	if (ip.physics.vel_air.x * fp.lr) < 0.0:
		ip.physics.vel_air.x = -ip.physics.vel_air.x
	Itmain.itMainClearOwnerStats(item_gobj)

	return FALSE

## 0x8017B7DC
static func itNBumperThrownSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.item_vars.bumper.damage_all_delay = ITBUMPER_DAMAGE_ALL_WAIT

	ip.coll_data.map_coll.top = ITBUMPER_COLL_SIZE
	ip.coll_data.map_coll.bottom = -ITBUMPER_COLL_SIZE

	Itmain.itMainSetStatus(item_gobj, dITNBumperStatusDescs, nITNBumperStatusThrown)

## 0x8017B828
static func itNBumperDroppedSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.item_vars.bumper.damage_all_delay = ITBUMPER_DAMAGE_ALL_WAIT

	ip.coll_data.map_coll.top = ITBUMPER_COLL_SIZE
	ip.coll_data.map_coll.bottom = -ITBUMPER_COLL_SIZE

	Itmain.itMainSetStatus(item_gobj, dITNBumperStatusDescs, nITNBumperStatusDropped)

## 0x8017B874
static func itNBumperAttachedSetModelPitch(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var floor_angle: Vector3
	var dobj := DObjGetStruct(item_gobj)

	floor_angle = ip.coll_data.floor_angle

	ip.attach_line_id = ip.coll_data.floor_line_id & 0xFFFF   # u16 attach_line_id

	dobj.rotate.z = syUtilsArcTan2(floor_angle.y, floor_angle.x) - F_CLC_DTOR32(90.0)

## 0x8017B8DC
static func itNBumperAttachedInitVars(item_gobj) -> void:
	var dobj: DObj
	var ip: Item
	var mobjsub
	var dl

	ip = itGetStruct(item_gobj)
	dobj = DObjGetStruct(item_gobj)

	ip.physics.vel_air.x = 0.0
	ip.physics.vel_air.y = 0.0
	ip.physics.vel_air.z = 0.0

	dl = llITCommonDataNBumperWaitDisplayList     # itGetPData(ip, &llITCommonDataNBumperDataStart, &llITCommonDataNBumperWaitDisplayList)

	dobj.dl = dl

	mobjsub = llITCommonDataNBumperWaitMObjSub    # itGetPData(ip, &llITCommonDataNBumperDataStart, &llITCommonDataNBumperWaitMObjSub)

	Objman.gcRemoveMObjAll(dobj)
	Objman.gcAddMObjForDObj(dobj, mobjsub)
	# Port: the two calls above are render stubs; the new MObj starts as gcAddMObjForDObj leaves it
	# (palette_id = 0, no MatAnimJoint), which is what the stand-in models.
	if dobj.has_meta(&"port_mobj"):
		dobj.remove_meta(&"port_mobj")

	dobj.scale = Vector3(1.0, 1.0, 1.0)

	ip.coll_data.map_coll.top = ITBUMPER_COLL_SIZE
	ip.coll_data.map_coll.bottom = -ITBUMPER_COLL_SIZE

	itNBumperAttachedSetModelPitch(item_gobj)

	ip.is_attach_surface = TRUE

	ip.lifetime = ITBUMPER_LIFETIME

	Itmain.itMainClearOwnerStats(item_gobj)

## 0x8017B9C8
static func itNBumperAttachedProcHit(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	dobj.scale.x = 2.0
	dobj.scale.z = 2.0

	ip.item_vars.bumper.hit_anim_length = ITBUMPER_HIT_ANIM_LENGTH

	Itmball.itPortGetDObjMObj(dobj).palette_id = 1.0

	ip.lr = -ip.hit_lr

	ip.physics.vel_air.x = ip.hit_lr * ITBUMPER_REBOUND_VEL_X

	ip.multi = ITBUMPER_HIT_SCALE

	return FALSE

## 0x8017BA2C
static func itNBumperAttachedProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var attr = ip.attr
	var dobj := DObjGetStruct(item_gobj)
	var edge_pos: Vector3

	if (ip.item_vars.bumper.hit_anim_length == 0) and (Itmball.itPortGetDObjMObj(dobj).palette_id == 1.0):
		Itmball.itPortGetDObjMObj(dobj).palette_id = 0.0
	else:
		ip.item_vars.bumper.hit_anim_length = (ip.item_vars.bumper.hit_anim_length - 1) & 0xFFFF   # u16

	if Mpcollision.mpCollisionCheckExistLineID(ip.coll_data.floor_line_id) != FALSE:
		if ip.lr == -1:
			edge_pos = Mpcollision.mpCollisionGetFloorEdgeL(ip.coll_data.floor_line_id)

			if edge_pos.x >= f32(dobj.translate.x - attr.map_coll_width):
				ip.physics.vel_air.x = 0.0
		else:
			edge_pos = Mpcollision.mpCollisionGetFloorEdgeR(ip.coll_data.floor_line_id)

			if edge_pos.x <= f32(dobj.translate.x + attr.map_coll_width):
				ip.physics.vel_air.x = 0.0

	if ip.multi < ITBUMPER_STOPVEL_WAIT:
		ip.physics.vel_air.x = 0.0

	if ip.multi != 0:
		var s: float = _itNBumperGetHitScale(ip.multi)

		dobj.scale.z = s
		dobj.scale.x = s

		ip.multi = (ip.multi - 1) & 0xFFFF   # u16 multi
	else:
		dobj.scale = Vector3(1.0, 1.0, 1.0)

	if ip.lifetime == 0:
		itNBumperGDisappearSetStatus(item_gobj)

	ip.lifetime -= 1

	return FALSE

## 0x8017BBFC
static func itNBumperAttachedProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var joint := DObjGetStruct(item_gobj)

	if Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itnbumper, &"itNBumperDroppedSetStatus")) != FALSE:
		if Mpcollision.mpCollisionCheckExistLineID(ip.attach_line_id) == FALSE:
			ip.is_attach_surface = FALSE

			itNBumperDroppedSetStatus(item_gobj)

			# REGION_US
			joint.scale = Vector3(1.0, 1.0, 1.0)

			Itmball.itPortGetDObjMObj(joint).palette_id = 0.0

		elif ip.multi == 0:
			itNBumperAttachedSetModelPitch(item_gobj)

	return FALSE

## 0x8017BCC0
static func itNBumperAttachedProcReflector(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var fp := ftGetStruct(ip.owner_gobj)
	var dobj := DObjGetStruct(item_gobj)

	dobj.scale.x = 2.0
	dobj.scale.z = 2.0

	ip.item_vars.bumper.hit_anim_length = 3

	Itmball.itPortGetDObjMObj(dobj).palette_id = 1.0

	ip.physics.vel_air.x = (-fp.lr * ITBUMPER_REBOUND_VEL_X)

	ip.lr = fp.lr

	ip.multi = ITBUMPER_HIT_SCALE

	Itmain.itMainClearOwnerStats(item_gobj)

	return FALSE

## 0x8017BD4C
static func itNBumperAttachedSetStatus(item_gobj) -> void:
	itNBumperAttachedInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITNBumperStatusDescs, nITNBumperStatusAttached)

## 0x8017BD80
static func itNBumperHitAirProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	if (ip.item_vars.bumper.hit_anim_length == 0) and (Itmball.itPortGetDObjMObj(dobj).palette_id == 1.0):
		Itmball.itPortGetDObjMObj(dobj).palette_id = 0.0
	else:
		ip.item_vars.bumper.hit_anim_length = (ip.item_vars.bumper.hit_anim_length - 1) & 0xFFFF   # u16

	Itmain.itMainApplyGravityClampTVel(ip, ITBUMPER_GRAVITY_HIT, ITBUMPER_TVEL)

	if ip.multi != 0:
		var s: float = _itNBumperGetHitScale(ip.multi)

		dobj.scale = Vector3(s, s, s)

		ip.multi = (ip.multi - 1) & 0xFFFF   # u16 multi
	else:
		dobj.scale = Vector3(1.0, 1.0, 1.0)

	if not ip.item_vars.bumper.damage_all_delay:
		Itmain.itMainClearOwnerStats(item_gobj)

		ip.item_vars.bumper.damage_all_delay = -1 & 0xFFFF       # u16: 0xFFFF
	if ip.item_vars.bumper.damage_all_delay != -1:               # u16 vs -1: always TRUE (ROM behaviour)
		ip.item_vars.bumper.damage_all_delay = (ip.item_vars.bumper.damage_all_delay - 1) & 0xFFFF

	return FALSE

## 0x8017BEA0
static func itNBumperHitAirSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.item_vars.bumper.damage_all_delay = ITBUMPER_DAMAGE_ALL_WAIT

	Itmain.itMainSetStatus(item_gobj, dITNBumperStatusDescs, nITNBumperStatusHitAir)

## 0x8017BED4
static func itNBumperGDisappearProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.lifetime == 0:
		return TRUE
	elif (ip.lifetime % 2) != 0:
		var dobj := DObjGetStruct(item_gobj)

		dobj.flags ^= DOBJ_FLAG_HIDDEN

	ip.lifetime -= 1

	return FALSE

## 0x8017BF1C
static func itNBumperGDisappearSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	Itmball.itPortGetDObjMObj(dobj).palette_id = 0

	dobj.scale.x = 1.0
	dobj.scale.y = 1.0
	dobj.scale.z = 1.0

	ip.lifetime = ITBUMPER_DESPAWN_TIMER

	dobj.flags = DOBJ_FLAG_NONE

	ip.attack_coll.attack_state = nGMAttackStateOff

	ip.physics.vel_air.x = 0.0
	ip.physics.vel_air.y = 0.0
	ip.physics.vel_air.z = 0.0

	Itmain.itMainSetStatus(item_gobj, dITNBumperStatusDescs, nITNBumperStatusGDisappear)

## 0x8017BF8C
static func itNBumperMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITNBumperItemDesc, pos, vel, flags)

	if item_gobj != null:
		var dobj := DObjGetStruct(item_gobj)
		var ip: Item
		var translate: Vector3 = dobj.translate   # REGION_US

		ip = itGetStruct(item_gobj)

		ip.multi = 0

		ip.attack_coll.interact_mask = GMHITCOLLISION_FLAG_FIGHTER

		ip.attack_coll.can_rehit_shield = TRUE

		Itmball.itPortGetDObjMObj(dobj).palette_id = 0.0

		Objman.gcAddXObjForDObjFixed(dobj, 0x2E, 0)

		dobj.translate = translate                # REGION_US

		dobj.rotate.z = 0.0

		ip.is_unused_item_bool = TRUE

		ip.arrow_gobj = Ifcommon.ifCommonItemArrowMakeInterface(ip)

	return item_gobj
