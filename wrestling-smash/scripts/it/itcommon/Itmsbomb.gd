## Port of src/it/itcommon/itmsbomb.c (Motion-Sensor Bomb).
##
## * ITDesc: {p_file = &gITManagerCommonData, o_attributes = &llITCommonDataMSBombItemAttributes} is given as
##   the linker symbol name; Itmanager resolves it to its ROM-verified transcription of
##   src/relocData/251_ITCommonData.c dITCommonData_MSBomb_ItemAttributes (file 251 @ 0x03BC) whose DObjDesc
##   tree (86_ITCommonObject.c dITCommonObject_MSBomb_Item_data_DObjDesc) gives dobj->child (attached model)
##   and dobj->child->sib_next (free model).
## * itGetAttackEvent(dITMSBombItemDesc, &llITCommonDataMSBombAttackEvents) ==
##   Itmanager.itManagerGetCommonData("llITCommonDataMSBombAttackEvents") (251_ITCommonData.c
##   dITCommonData_MSBomb_AttackEvents @ 0x0404: {0,361,30,360} {4,361,30,300} {8,361,20,200} {16,361,1,0}).
## * ip->multi is u16, ip->event_id is u32:4, ip->attach_line_id is u16.
class_name Itmsbomb
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itMSBombStatus
const nITMSBombStatusWait = 0
const nITMSBombStatusFall = 1
const nITMSBombStatusHold = 2
const nITMSBombStatusThrown = 3
const nITMSBombStatusDropped = 4
const nITMSBombStatusAttached = 5
const nITMSBombStatusDetached = 6
const nITMSBombStatusExplode = 7
const nITMSBombStatusEnumCount = 8

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

static var dITMSBombItemDesc := {
	"kind": nITKindMSBomb,                                      # Item Kind
	"o_attributes": "llITCommonDataMSBombItemAttributes",       # p_file = &gITManagerCommonData
	"transform_types": {"tk1": nGCMatrixKindNull, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                          # Hitbox Update State
	"proc_update": Callable(Itmsbomb, &"itMSBombFallProcUpdate"),
	"proc_map": Callable(Itmsbomb, &"itMSBombFallProcMap"),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
}

static var dITMSBombStatusDescs: Array = [
	# Status 0 (Ground Wait)
	{
		"proc_update": Callable(),
		"proc_map": Callable(Itmsbomb, &"itMSBombWaitProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
	},
	# Status 1 (Air Wait Fall)
	{
		"proc_update": Callable(Itmsbomb, &"itMSBombFallProcUpdate"),
		"proc_map": Callable(Itmsbomb, &"itMSBombFallProcMap"),
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
		"proc_update": Callable(Itmsbomb, &"itMSBombThrownProcUpdate"),
		"proc_map": Callable(Itmsbomb, &"itMSBombThrownProcMap"),
		"proc_hit": Callable(Itmsbomb, &"itMSBombCommonProcHit"),
		"proc_shield": Callable(Itmsbomb, &"itMSBombCommonProcHit"),
		"proc_hop": Callable(Itmain, &"itMainCommonProcHop"),
		"proc_setoff": Callable(Itmsbomb, &"itMSBombCommonProcHit"),
		"proc_reflector": Callable(Itmain, &"itMainCommonProcReflector"),
		"proc_damage": Callable(),
	},
	# Status 4 (Fighter Drop)
	{
		"proc_update": Callable(Itmsbomb, &"itMSBombFallProcUpdate"),
		"proc_map": Callable(Itmsbomb, &"itMSBombDroppedProcMap"),
		"proc_hit": Callable(Itmsbomb, &"itMSBombCommonProcHit"),
		"proc_shield": Callable(Itmsbomb, &"itMSBombCommonProcHit"),
		"proc_hop": Callable(Itmain, &"itMainCommonProcHop"),
		"proc_setoff": Callable(Itmsbomb, &"itMSBombCommonProcHit"),
		"proc_reflector": Callable(Itmain, &"itMainCommonProcReflector"),
		"proc_damage": Callable(),
	},
	# Status 5 (Ground Attach)
	{
		"proc_update": Callable(Itmsbomb, &"itMSBombAttachedProcUpdate"),
		"proc_map": Callable(Itmsbomb, &"itMSBombAttachedProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(Itmsbomb, &"itMSBombCommonProcDamage"),
	},
	# Status 6 (Air Detach from Surface)
	{
		"proc_update": Callable(Itmsbomb, &"itMSBombDetachedProcUpdate"),
		"proc_map": Callable(Itmsbomb, &"itMSBombDroppedProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(Itmsbomb, &"itMSBombCommonProcDamage"),
	},
	# Status 7 (Neutral Explosion)
	{
		"proc_update": Callable(Itmsbomb, &"itMSBombExplodeProcUpdate"),
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

## 0x80176450
static func itMSBombFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITMSBOMB_GRAVITY, ITMSBOMB_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	dobj.child.sib_next.rotate.z = dobj.rotate.z

	return FALSE

## 0x801764A8
static func itMSBombWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itmsbomb, &"itMSBombFallSetStatus"))

	return FALSE

## 0x801764D0
static func itMSBombFallProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITMSBOMB_MAP_REBOUND_COMMON, ITMSBOMB_MAP_REBOUND_GROUND, Callable(Itmsbomb, &"itMSBombWaitSetStatus"))

## 0x80176504
static func itMSBombWaitSetStatus(item_gobj) -> void:
	Itmain.itMainSetGroundAllowPickup(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITMSBombStatusDescs, nITMSBombStatusWait)

## 0x80176538
static func itMSBombFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITMSBombStatusDescs, nITMSBombStatusFall)

## 0x8017657C
static func itMSBombHoldSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITMSBombStatusDescs, nITMSBombStatusHold)

## 0x801765A4
static func itMSBombThrownProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITMSBOMB_GRAVITY, ITMSBOMB_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	dobj.child.sib_next.rotate.z = dobj.rotate.z

	return FALSE

## 0x801765FC
static func itMSBombThrownProcMap(item_gobj) -> int:
	return Itmap.itMapCheckMapProcAll(item_gobj, Callable(Itmsbomb, &"itMSBombAttachedSetStatus"))

## 0x80176620
static func itMSBombCommonProcHit(item_gobj) -> int:
	Itmain.itMainVelSetRebound(item_gobj)

	return FALSE

## 0x80176644
static func itMSBombThrownSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.coll_data.map_coll.top = ITMSBOMB_COLL_SIZE
	ip.coll_data.map_coll.center = 0.0
	ip.coll_data.map_coll.bottom = -ITMSBOMB_COLL_SIZE
	ip.coll_data.map_coll.width = ITMSBOMB_COLL_SIZE

	Itmain.itMainSetStatus(item_gobj, dITMSBombStatusDescs, nITMSBombStatusThrown)

## 0x80176694
static func itMSBombDroppedProcMap(item_gobj) -> int:
	return Itmap.itMapCheckMapProcAll(item_gobj, Callable(Itmsbomb, &"itMSBombAttachedSetStatus"))

## 0x801766B8
static func itMSBombDroppedSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.coll_data.map_coll.top = ITMSBOMB_COLL_SIZE
	ip.coll_data.map_coll.center = 0.0
	ip.coll_data.map_coll.bottom = -ITMSBOMB_COLL_SIZE
	ip.coll_data.map_coll.width = ITMSBOMB_COLL_SIZE

	Itmain.itMainSetStatus(item_gobj, dITMSBombStatusDescs, nITMSBombStatusDropped)

## 0x80176708
static func itMSBombAttachedUpdateSurface(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var coll_data: MPCollData = ip.coll_data
	var angle: Vector3 = Vector3.ZERO     # (uninitialised in C if no surface flag is set; never happens: proc_all only fires on a collision)
	var dobj := DObjGetStruct(item_gobj)

	if (coll_data.mask_curr & MAP_FLAG_CEIL) or (coll_data.mask_curr & MAP_FLAG_FLOOR):
		if coll_data.mask_curr & MAP_FLAG_CEIL:
			angle = coll_data.ceil_angle

			ip.attach_line_id = coll_data.ceil_line_id & 0xFFFF     # u16 attach_line_id
		if coll_data.mask_curr & MAP_FLAG_FLOOR:
			angle = coll_data.floor_angle

			ip.attach_line_id = coll_data.floor_line_id & 0xFFFF
	else:
		if coll_data.mask_curr & MAP_FLAG_LWALL:
			angle = coll_data.lwall_angle

			ip.attach_line_id = coll_data.lwall_line_id & 0xFFFF
		if coll_data.mask_curr & MAP_FLAG_RWALL:
			angle = coll_data.rwall_angle

			ip.attach_line_id = coll_data.rwall_line_id & 0xFFFF
	dobj.rotate.z = syUtilsArcTan2(angle.y, angle.x) - F_CST_DTOR32(90.0)

## 0x80176840
static func itMSBombAttachedInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	ip.coll_data.map_coll.top = ITMSBOMB_COLL_SIZE
	ip.coll_data.map_coll.center = 0.0
	ip.coll_data.map_coll.bottom = -ITMSBOMB_COLL_SIZE
	ip.coll_data.map_coll.width = ITMSBOMB_COLL_SIZE

	ip.physics.vel_air.z = 0
	ip.physics.vel_air.y = ip.physics.vel_air.z
	ip.physics.vel_air.x = ip.physics.vel_air.y

	dobj.child.flags = DOBJ_FLAG_NONE
	dobj.child.sib_next.flags = DOBJ_FLAG_HIDDEN

	itMSBombAttachedUpdateSurface(item_gobj)

	ip.is_attach_surface = TRUE

	ip.damage_coll.hitstatus = nGMHitStatusNormal

	ip.attack_coll.attack_state = nGMAttackStateOff

	if (ip.player != -1) and (ip.player != GMCOMMON_PLAYERS_MAX):   # (u8 player: != -1 is always TRUE)
		var fighter_gobj = G.gSCManagerBattleState.players[ip.player].fighter_gobj

		if fighter_gobj != null:
			Ftparam.ftParamMakeRumble(ftGetStruct(fighter_gobj), 6, 0)

	Snd.func_800269C0_275C0(nSYAudioFGMMSBombAttach)

	Itmain.itMainClearOwnerStats(item_gobj)

## 0x80176934
static func itMSBombExplodeMakeEffect(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var attr = ip.attr
	var dobj := DObjGetStruct(item_gobj)

	if ip.coll_data.mask_curr & MAP_FLAG_FLOOR:
		var translate: Vector3 = dobj.translate

		translate.y += attr.map_coll_bottom

		Efmanager.efManagerDustHeavyDoubleMakeEffect(translate, ip.lr, 1.0)

## 0x801769AC
static func itMSBombExplodeInitStatusVars(item_gobj, is_make_effect: int) -> void:
	var pc
	var dobj := DObjGetStruct(item_gobj)

	if is_make_effect != FALSE:
		itMSBombExplodeMakeEffect(item_gobj)

	pc = Efmanager.efManagerSparkleWhiteMultiExplodeMakeEffect(dobj.translate)

	if pc != null:
		pc.xf.scale.x = ITMSBOMB_EXPLODE_SCALE
		pc.xf.scale.y = ITMSBOMB_EXPLODE_SCALE
		pc.xf.scale.z = ITMSBOMB_EXPLODE_SCALE

	Efmanager.efManagerQuakeMakeEffect(1)
	Itmain.itMainRefreshAttackColl(item_gobj)
	itMSBombExplodeSetStatus(item_gobj)

	DObjGetStruct(item_gobj).flags = DOBJ_FLAG_HIDDEN

## 0x80176A34
static func itMSBombCommonProcDamage(item_gobj) -> int:
	Snd.func_800269C0_275C0(nSYAudioFGMExplodeL)
	itMSBombExplodeInitStatusVars(item_gobj, FALSE)

	return FALSE

## 0x80176A68
static func itMSBombAttachedProcUpdate(item_gobj) -> int:
	var translate: Vector3
	var dist: Vector3
	var fighter_pos: Vector3
	var item_dobj := DObjGetStruct(item_gobj)
	var ip := itGetStruct(item_gobj)

	if ip.multi < ITMSBOMB_DETECT_FIGHTER_DELAY:
		ip.multi = (ip.multi + 1) & 0xFFFF   # u16 multi
	else:
		translate = item_dobj.translate   # (the bomb does not move during the loop)

		for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
			var fp := ftGetStruct(fighter_gobj)
			var fighter_dobj := DObjGetStruct(fighter_gobj)
			var v: float = f32(fp.attr.map_coll.top * 0.5)

			fighter_pos = fighter_dobj.translate

			fighter_pos.y += v

			dist = fighter_pos - translate   # syVectorDiff3D(&dist, &fighter_pos, translate)

			if f32(f32(f32(SQUARE(dist.x)) + f32(SQUARE(dist.y))) + f32(SQUARE(dist.z))) < ITMSBOMB_DETECT_FIGHTER_RADIUS:
				itMSBombExplodeInitStatusVars(item_gobj, TRUE) # We might want to break out of the loop here (C does not)

	return FALSE

## 0x80176B94
static func itMSBombAttachedSetStatus(item_gobj) -> void:
	itMSBombAttachedInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITMSBombStatusDescs, nITMSBombStatusAttached)

## 0x80176BC8
static func itMSBombAttachedProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if Mpcollision.mpCollisionCheckExistLineID(ip.attach_line_id) == FALSE:
		ip.is_attach_surface = FALSE

		itMSBombDetachedSetStatus(item_gobj)

	return FALSE

## 0x80176C14 (symbols/symbols_us.txt; no address comment in the decomp)
static func itMSBombExplodeUpdateAttackEvent(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var ev: Array = Itmanager.itManagerGetCommonData("llITCommonDataMSBombAttackEvents")  # itGetAttackEvent(dITMSBombItemDesc, &llITCommonDataMSBombAttackEvents)

	if ip.multi == ev[ip.event_id].timer:
		ip.attack_coll.angle = ev[ip.event_id].angle
		ip.attack_coll.damage = ev[ip.event_id].damage
		ip.attack_coll.size = ev[ip.event_id].size

		ip.attack_coll.can_rehit_item = TRUE
		ip.attack_coll.can_hop = FALSE
		ip.attack_coll.can_reflect = FALSE
		ip.attack_coll.can_setoff = FALSE

		ip.attack_coll.element = nGMHitElementFire

		ip.event_id = (ip.event_id + 1) & 0xF   # u32 event_id : 4

		if ip.event_id == 4:
			ip.event_id = 3

## 0x80176D00
static func itMSBombDetachedInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.damage_coll.hitstatus = nGMHitStatusNormal
	ip.attack_coll.attack_state = nGMAttackStateOff

	Itmain.itMainClearOwnerStats(item_gobj)

## 0x80176D2C
static func itMSBombDetachedProcUpdate(item_gobj) -> int:
	var translate: Vector3
	var dist: Vector3
	var fighter_pos: Vector3
	var item_dobj := DObjGetStruct(item_gobj)
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITMSBOMB_GRAVITY, ITMSBOMB_TVEL)

	if ip.multi < ITMSBOMB_DETECT_FIGHTER_DELAY:
		ip.multi = (ip.multi + 1) & 0xFFFF   # u16 multi
	else:
		translate = item_dobj.translate

		for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
			var fp := ftGetStruct(fighter_gobj)
			var fighter_dobj := DObjGetStruct(fighter_gobj)
			var offset_y: float = f32(fp.attr.map_coll.top * 0.5)

			fighter_pos = fighter_dobj.translate

			fighter_pos.y += offset_y

			dist = fighter_pos - translate   # syVectorDiff3D(&dist, &fighter_pos, translate)

			if f32(f32(f32(SQUARE(dist.x)) + f32(SQUARE(dist.y))) + f32(SQUARE(dist.z))) < ITMSBOMB_DETECT_FIGHTER_RADIUS:
				itMSBombExplodeInitStatusVars(item_gobj, FALSE) # We might want to break out of the loop here (C does not)

	return FALSE

## 0x80176E68
static func itMSBombDetachedSetStatus(item_gobj) -> void:
	itMSBombDetachedInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITMSBombStatusDescs, nITMSBombStatusDetached)

## 0x80176E9C
static func itMSBombExplodeInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.multi = 0

	ip.event_id = 0

	ip.attack_coll.throw_mul = ITEM_THROW_DEFAULT
	ip.attack_coll.fgm_id = nSYAudioFGMExplodeL

	ip.damage_coll.hitstatus = nGMHitStatusNone

	itMSBombExplodeUpdateAttackEvent(item_gobj)

## 0x80176EE4
static func itMSBombExplodeProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	itMSBombExplodeUpdateAttackEvent(item_gobj)

	ip.multi = (ip.multi + 1) & 0xFFFF   # u16 multi

	if ip.multi == ITMSBOMB_EXPLODE_LIFETIME:
		return TRUE
	else:
		return FALSE

## 0x80176F2C
static func itMSBombExplodeSetStatus(item_gobj) -> void:
	itMSBombExplodeInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITMSBombStatusDescs, nITMSBombStatusExplode)

## 0x80176F60
static func itMSBombMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITMSBombItemDesc, pos, vel, flags)
	var dobj: DObj
	var ip: Item
	var translate: Vector3                  # REGION_US

	if item_gobj != null:
		dobj = DObjGetStruct(item_gobj)

		dobj.child.flags = DOBJ_FLAG_HIDDEN
		dobj.child.sib_next.flags = DOBJ_FLAG_NONE

		translate = dobj.translate          # REGION_US

		Objman.gcAddXObjForDObjFixed(dobj, nGCMatrixKindTraRotRpyR, 0)
		Objman.gcAddXObjForDObjFixed(dobj.child.sib_next, 0x46, 0)

		dobj.translate = translate          # REGION_US

		ip = itGetStruct(item_gobj)

		ip.multi = 0

		ip.is_unused_item_bool = TRUE

		ip.arrow_gobj = Ifcommon.ifCommonItemArrowMakeInterface(ip)

		dobj.rotate.z = 0.0

	return item_gobj
