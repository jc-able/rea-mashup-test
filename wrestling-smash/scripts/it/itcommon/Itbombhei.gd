## Port of src/it/itcommon/itbombhei.c (Bob-omb).
##
## * ITDesc: {p_file = &gITManagerCommonData, o_attributes = &llITCommonDataBombHeiItemAttributes} is given as
##   the linker symbol name; Itmanager resolves it to its ROM-verified transcription of
##   src/relocData/251_ITCommonData.c dITCommonData_BombHei_ItemAttributes (file 251 @ 0x0424).
## * itGetAttackEvent(dITBombHeiItemDesc, &llITCommonDataBombHeiAttackEvents) ==
##   Itmanager.itManagerGetCommonData("llITCommonDataBombHeiAttackEvents") (251_ITCommonData.c
##   dITCommonData_BombHei_AttackEvents @ 0x046C: {0,361,30,350} {2,361,30,250} {4,361,20,150} {6,361,1,0}).
## * itGetPData(ip, &llITCommonDataBombHeiDataStart, &X) == ITCommonObject (file 86) offset X. The walk
##   direction display lists (dobj->dl) are kept as the 86_ITCommonObject.c symbol names (as Itmanager's
##   DObjDesc "dl" markers); the walk MatAnimJoint is a render-only marker.
## * ip->multi is u16 (its ++ after an explosion was started is kept), event_id is u32:4,
##   item_vars.bombhei.smoke_delay is u16.
class_name Itbombhei
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itBombHeiStatus
const nITBombHeiStatusWait = 0
const nITBombHeiStatusFall = 1
const nITBombHeiStatusHold = 2
const nITBombHeiStatusThrown = 3
const nITBombHeiStatusDropped = 4
const nITBombHeiStatusWalk = 5
const nITBombHeiStatusExplodeMap = 6        # Explode on map collision
const nITBombHeiStatusExplode = 7           # Neutral explosion
const nITBombHeiStatusExplodeWait = 8       # Stall until explosion
const nITBombHeiStatusEnumCount = 9

# // // // // // // // // // // // //
# //      RELOC DATA (markers)     //
# // // // // // // // // // // // //

## llITCommonDataBombHeiWalkRightDisplayList (file 86 @ 0x3310; also the model's default DObjDesc dl)
const llITCommonDataBombHeiWalkRightDisplayList := "dITCommonObject_Gfx_0x3310"
## llITCommonDataBombHeiWalkLeftDisplayList (file 86 @ 0x34C0)
const llITCommonDataBombHeiWalkLeftDisplayList := "dITCommonObject_Gfx_0x34C0"
## llITCommonDataBombHeiWalkMatAnimJoint (file 86 @ 0x35B8, render-only)
const llITCommonDataBombHeiWalkMatAnimJoint := {"file": 86, "offset": 0x35B8, "name": "BombHeiWalkMatAnimJoint"}

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x80189F90 - unused?
static var dITBombHeiDisplayListOffsets: Array = [
	llITCommonDataBombHeiWalkRightDisplayList,
	llITCommonDataBombHeiWalkLeftDisplayList,
]

## 0x80189F98
static var dITBombHeiItemDesc := {
	"kind": nITKindBombHei,                                     # Item Kind
	"o_attributes": "llITCommonDataBombHeiItemAttributes",      # p_file = &gITManagerCommonData
	"transform_types": {"tk1": nGCMatrixKindTra, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                          # Hitbox Update State
	"proc_update": Callable(Itbombhei, &"itBombHeiFallProcUpdate"),
	"proc_map": Callable(Itbombhei, &"itBombHeiFallProcMap"),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
}

## 0x80189FCC
static var dITBombHeiStatusDescs: Array = [
	# Status 0 (Ground Wait)
	{
		"proc_update": Callable(Itbombhei, &"itBombHeiWaitProcUpdate"),
		"proc_map": Callable(Itbombhei, &"itBombHeiWaitProcMap"),
		"proc_hit": Callable(Itbombhei, &"itBombHeiCommonProcHit"),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(Itbombhei, &"itBombHeiCommonProcHit"),
	},
	# Status 1 (Air Wait Fall)
	{
		"proc_update": Callable(Itbombhei, &"itBombHeiFallProcUpdate"),
		"proc_map": Callable(Itbombhei, &"itBombHeiFallProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(Itbombhei, &"itBombHeiCommonProcHit"),
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
		"proc_update": Callable(Itbombhei, &"itBombHeiThrownProcUpdate"),
		"proc_map": Callable(Itbombhei, &"itBombHeiThrownProcMap"),
		"proc_hit": Callable(Itbombhei, &"itBombHeiCommonProcHit"),
		"proc_shield": Callable(Itbombhei, &"itBombHeiCommonProcHit"),
		"proc_hop": Callable(Itmain, &"itMainCommonProcHop"),
		"proc_setoff": Callable(Itbombhei, &"itBombHeiCommonProcHit"),
		"proc_reflector": Callable(Itmain, &"itMainCommonProcReflector"),
		"proc_damage": Callable(Itbombhei, &"itBombHeiCommonProcHit"),
	},
	# Status 4 (Fighter Throw)
	{
		"proc_update": Callable(Itbombhei, &"itBombHeiFallProcUpdate"),
		"proc_map": Callable(Itbombhei, &"itBombHeiDroppedProcMap"),
		"proc_hit": Callable(Itbombhei, &"itBombHeiCommonProcHit"),
		"proc_shield": Callable(Itbombhei, &"itBombHeiCommonProcHit"),
		"proc_hop": Callable(Itmain, &"itMainCommonProcHop"),
		"proc_setoff": Callable(Itbombhei, &"itBombHeiCommonProcHit"),
		"proc_reflector": Callable(Itmain, &"itMainCommonProcReflector"),
		"proc_damage": Callable(Itbombhei, &"itBombHeiCommonProcHit"),
	},
	# Status 5 (Ground Walk)
	{
		"proc_update": Callable(Itbombhei, &"itBombHeiWalkProcUpdate"),
		"proc_map": Callable(Itbombhei, &"itBombHeiWalkProcMap"),
		"proc_hit": Callable(Itbombhei, &"itBombHeiExplodeCommonProcHit"),
		"proc_shield": Callable(Itbombhei, &"itBombHeiExplodeCommonProcHit"),
		"proc_hop": Callable(),
		"proc_setoff": Callable(Itbombhei, &"itBombHeiExplodeCommonProcHit"),
		"proc_reflector": Callable(Itbombhei, &"itBombHeiExplodeCommonProcHit"),
		"proc_damage": Callable(Itbombhei, &"itBombHeiExplodeCommonProcHit"),
	},
	# Status 6 (Map Collision Explosion)
	{
		"proc_update": Callable(Itbombhei, &"itBombHeiExplodeMapProcUpdate"),
		"proc_map": Callable(),
		"proc_hit": Callable(Itbombhei, &"itBombHeiExplodeMapProcUpdate"),
		"proc_shield": Callable(Itbombhei, &"itBombHeiExplodeMapProcUpdate"),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(Itbombhei, &"itBombHeiExplodeMapProcUpdate"),
		"proc_damage": Callable(Itbombhei, &"itBombHeiExplodeMapProcUpdate"),
	},
	# Status 7 (Neutral / Hit Explosion)
	{
		"proc_update": Callable(Itbombhei, &"itBombHeiExplodeProcUpdate"),
		"proc_map": Callable(),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
	},
	# Status 8 (Ground Walk Explosion Stall)
	{
		"proc_update": Callable(Itbombhei, &"itBombHeiExplodeWaitProcUpdate"),
		"proc_map": Callable(Itbombhei, &"itBombHeiExplodeWaitProcMap"),
		"proc_hit": Callable(Itbombhei, &"itBombHeiExplodeCommonProcHit"),
		"proc_shield": Callable(Itbombhei, &"itBombHeiExplodeCommonProcHit"),
		"proc_hop": Callable(),
		"proc_setoff": Callable(Itbombhei, &"itBombHeiExplodeCommonProcHit"),
		"proc_reflector": Callable(Itbombhei, &"itBombHeiExplodeCommonProcHit"),
		"proc_damage": Callable(Itbombhei, &"itBombHeiExplodeCommonProcHit"),
	},
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80177060
static func itBombHeiCommonSetExplode(item_gobj, unused_arg: int) -> void:
	var dobj := DObjGetStruct(item_gobj)
	var ip := itGetStruct(item_gobj)
	var pc

	itBombHeiCommonSetHitStatusNone(item_gobj)

	pc = Efmanager.efManagerSparkleWhiteMultiExplodeMakeEffect(dobj.translate)

	if pc != null:
		pc.xf.scale.x = ITBOMBHEI_EXPLODE_SCALE
		pc.xf.scale.y = ITBOMBHEI_EXPLODE_SCALE
		pc.xf.scale.z = ITBOMBHEI_EXPLODE_SCALE

	Efmanager.efManagerQuakeMakeEffect(1)

	DObjGetStruct(item_gobj).flags = DOBJ_FLAG_HIDDEN

	ip.attack_coll.fgm_id = nSYAudioFGMExplodeL

	Itmain.itMainRefreshAttackColl(item_gobj)
	Itmain.itMainClearOwnerStats(item_gobj)
	itBombHeiExplodeSetStatus(item_gobj)

## 0x80177104
static func itBombHeiCommonSetWalkLR(item_gobj, lr: int) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)
	var dll = llITCommonDataBombHeiWalkLeftDisplayList    # itGetPData(ip, &llITCommonDataBombHeiDataStart, &llITCommonDataBombHeiWalkLeftDisplayList)
	var dlr = llITCommonDataBombHeiWalkRightDisplayList   # itGetPData(ip, &llITCommonDataBombHeiDataStart, &llITCommonDataBombHeiWalkRightDisplayList)

	if lr != 0:
		ip.lr = +1
		ip.physics.vel_air.x = ITBOMBHEI_WALK_VEL_X

		dobj.dl = dlr
	else:
		ip.lr = -1
		ip.physics.vel_air.x = -ITBOMBHEI_WALK_VEL_X

		dobj.dl = dll

## 0x80177180
static func itBombHeiCommonCheckMakeDustEffect(item_gobj, override: int) -> void:
	var ip := itGetStruct(item_gobj)
	var attr = ip.attr
	var dobj := DObjGetStruct(item_gobj)

	if (ip.coll_data.mask_curr & MAP_FLAG_FLOOR) or (override != FALSE):
		var pos: Vector3 = dobj.translate

		pos.y += attr.map_coll_bottom

		Efmanager.efManagerDustHeavyDoubleMakeEffect(pos, ip.lr, 1.0)

## 0x80177208
static func itBombHeiCommonSetHitStatusNormal(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.damage_coll.hitstatus = nGMHitStatusNormal

## 0x80177218
static func itBombHeiCommonSetHitStatusNone(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.damage_coll.hitstatus = nGMHitStatusNone

## 0x80177224
static func itBombHeiFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITBOMBHEI_GRAVITY, ITBOMBHEI_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x80177260
static func itBombHeiWalkGetLR(item_gobj) -> int:
	var translate: Vector3
	var lr: int
	var ret_lr: int = 0
	var dist: Vector3
	var item_dobj := DObjGetStruct(item_gobj)
	var fighter_dobj: DObj

	for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		translate = item_dobj.translate

		fighter_dobj = DObjGetStruct(fighter_gobj)

		dist = translate - fighter_dobj.translate   # syVectorDiff3D(&dist, translate, &fighter_dobj->translate.vec.f)

		lr = -1 if (dist.x < 0.0) else +1

		ret_lr += lr

	return ret_lr # I assume this is getting the number of players on either side of the Bob-Omb so it starts moving towards the most crowded area

## 0x80177304
static func itBombHeiWaitProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)
	var dll = llITCommonDataBombHeiWalkLeftDisplayList    # itGetPData(ip, &llITCommonDataBombHeiDataStart, &llITCommonDataBombHeiWalkLeftDisplayList)
	var lr: int

	if ip.multi == ITBOMBHEI_WALK_WAIT:
		lr = itBombHeiWalkGetLR(item_gobj)

		if lr == 0:
			lr = syUtilsRandIntRange(2) - 1
		if lr < 0:
			ip.lr = +1
			ip.physics.vel_air.x = ITBOMBHEI_WALK_VEL_X
		else:
			ip.physics.vel_air.x = -ITBOMBHEI_WALK_VEL_X

			dobj.dl = dll

			ip.lr = -1
		itBombHeiWalkSetStatus(item_gobj)

	ip.multi = (ip.multi + 1) & 0xFFFF   # u16 multi

	return FALSE

## 0x801773F4
static func itBombHeiWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itbombhei, &"itBombHeiFallSetStatus"))

	return FALSE

## 0x8017741C
static func itBombHeiCommonProcHit(item_gobj) -> int:
	itBombHeiCommonClearVelSetExplode(item_gobj, TRUE)

	return FALSE

## 0x80177440
static func itBombHeiFallProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITBOMBHEI_MAP_REBOUND_COMMON, ITBOMBHEI_MAP_REBOUND_GROUND, Callable(Itbombhei, &"itBombHeiWaitSetStatus"))

## 0x80177474
static func itBombHeiWaitSetStatus(item_gobj) -> void:
	Itmain.itMainSetGroundAllowPickup(item_gobj)
	itBombHeiCommonSetHitStatusNormal(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITBombHeiStatusDescs, nITBombHeiStatusWait)

## 0x801774B0
static func itBombHeiFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	Itmap.itMapSetAir(ip)
	itBombHeiCommonSetHitStatusNormal(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITBombHeiStatusDescs, nITBombHeiStatusFall)

## 0x801774FC
static func itBombHeiHoldSetStatus(item_gobj) -> void:
	itBombHeiCommonSetHitStatusNone(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITBombHeiStatusDescs, nITBombHeiStatusHold)

## 0x80177530
static func itBombHeiThrownProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITBOMBHEI_GRAVITY, ITBOMBHEI_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x8017756C
static func itBombHeiThrownProcMap(item_gobj) -> int:
	return Itmap.itMapCheckMapProcAll(item_gobj, Callable(Itbombhei, &"itBombHeiExplodeMapSetStatus"))

## 0x80177590
static func itBombHeiThrownSetStatus(item_gobj) -> void:
	itBombHeiCommonSetHitStatusNormal(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITBombHeiStatusDescs, nITBombHeiStatusThrown)

## 0x801775C4
static func itBombHeiDroppedProcMap(item_gobj) -> int:
	return Itmap.itMapCheckMapProcAll(item_gobj, Callable(Itbombhei, &"itBombHeiExplodeMapSetStatus"))

## 0x801775E8
static func itBombHeiDroppedSetStatus(item_gobj) -> void:
	itBombHeiCommonSetHitStatusNormal(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITBombHeiStatusDescs, nITBombHeiStatusDropped)

## 0x8017761C
static func itBombHeiWalkUpdateEffect(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	if ip.item_vars.bombhei.smoke_delay == 0:
		var pos: Vector3 = dobj.translate

		pos.y += 120.0

		Efmanager.efManagerDustLightMakeEffect(pos, ip.lr, 1.0)

		ip.item_vars.bombhei.smoke_delay = ITBOMBHEI_SMOKE_WAIT
	ip.item_vars.bombhei.smoke_delay = (ip.item_vars.bombhei.smoke_delay - 1) & 0xFFFF   # u16

## 0x801776A0
static func itBombHeiWalkProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var attr = ip.attr
	var dobj := DObjGetStruct(item_gobj)
	var pos: Vector3

	itBombHeiWalkUpdateEffect(item_gobj)

	if Mpcollision.mpCollisionCheckExistLineID(ip.coll_data.floor_line_id) != FALSE:
		if ip.lr == -1:
			pos = Mpcollision.mpCollisionGetFloorEdgeL(ip.coll_data.floor_line_id)

			if pos.x >= f32(dobj.translate.x - attr.map_coll_width):
				itBombHeiCommonSetWalkLR(item_gobj, 1)
		else:
			pos = Mpcollision.mpCollisionGetFloorEdgeR(ip.coll_data.floor_line_id)

			if pos.x <= f32(dobj.translate.x + attr.map_coll_width):
				itBombHeiCommonSetWalkLR(item_gobj, 0)

	if ip.multi == ITBOMBHEI_FLASH_WAIT:
		ip.physics.vel_air.z = 0.0
		ip.physics.vel_air.y = ip.physics.vel_air.z
		ip.physics.vel_air.x = ip.physics.vel_air.y

		itBombHeiExplodeWaitSetStatus(item_gobj)

	ip.multi = (ip.multi + 1) & 0xFFFF   # u16 multi

	return FALSE

## 0x801777D8
static func itBombHeiWalkProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itbombhei, &"itBombHeiDroppedSetStatus"))

	if ip.coll_data.mask_curr & MAP_FLAG_LWALL:
		itBombHeiCommonSetWalkLR(item_gobj, 0)
	if ip.coll_data.mask_curr & MAP_FLAG_RWALL:
		itBombHeiCommonSetWalkLR(item_gobj, 1)

	return FALSE

## 0x80177848
static func itBombHeiWalkInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var attr = ip.attr
	var dobj := DObjGetStruct(item_gobj)
	var matanim_joint
	var pos: Vector3

	ip.is_allow_pickup = FALSE

	ip.multi = 0

	ip.item_vars.bombhei.smoke_delay = ITBOMBHEI_SMOKE_WAIT

	Itmain.itMainRefreshAttackColl(item_gobj)

	matanim_joint = llITCommonDataBombHeiWalkMatAnimJoint  # itGetPData(ip, &llITCommonDataBombHeiDataStart, &llITCommonDataBombHeiWalkMatAnimJoint)

	ObjAnim.gcAddMObjMatAnimJoint(Itmball.itPortGetDObjMObj(dobj), matanim_joint, 0.0)
	ObjAnim.gcPlayAnimAll(item_gobj)

	if Mpcollision.mpCollisionCheckExistLineID(ip.coll_data.floor_line_id) != FALSE:
		if ip.lr == -1:
			pos = Mpcollision.mpCollisionGetFloorEdgeL(ip.coll_data.floor_line_id)

			if pos.x >= f32(dobj.translate.x - attr.map_coll_width):
				itBombHeiCommonSetWalkLR(item_gobj, 1)
		else:
			pos = Mpcollision.mpCollisionGetFloorEdgeR(ip.coll_data.floor_line_id)

			if pos.x <= f32(dobj.translate.x + attr.map_coll_width):
				itBombHeiCommonSetWalkLR(item_gobj, 0)

	Itmain.itMainClearOwnerStats(item_gobj)

	Snd.func_800269C0_275C0(nSYAudioFGMBombHeiFuse)

## 0x801779A8
static func itBombHeiWalkSetStatus(item_gobj) -> void:
	itBombHeiCommonSetHitStatusNormal(item_gobj)
	itBombHeiWalkInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITBombHeiStatusDescs, nITBombHeiStatusWalk)

## 0x801779E4
static func itBombHeiCommonClearVelSetExplode(item_gobj, unused: int) -> void:
	var ip := itGetStruct(item_gobj)

	ip.physics.vel_air.z = 0.0
	ip.physics.vel_air.y = ip.physics.vel_air.z
	ip.physics.vel_air.x = ip.physics.vel_air.y

	itBombHeiCommonSetExplode(item_gobj, unused)

	Snd.func_800269C0_275C0(nSYAudioFGMExplodeL)

## 0x80177A24
static func itBombHeiCommonUpdateAttackEvent(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var ev: Array = Itmanager.itManagerGetCommonData("llITCommonDataBombHeiAttackEvents")  # itGetAttackEvent(dITBombHeiItemDesc, &llITCommonDataBombHeiAttackEvents)

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

## 0x80177B10
static func itBombHeiExplodeMapProcUpdate(item_gobj) -> int:
	itBombHeiCommonCheckMakeDustEffect(item_gobj, FALSE)
	itBombHeiCommonClearVelSetExplode(item_gobj, TRUE)

	return FALSE

## 0x80177B44
static func itBombHeiExplodeCommonProcHit(item_gobj) -> int:
	itBombHeiCommonCheckMakeDustEffect(item_gobj, TRUE)
	itBombHeiCommonClearVelSetExplode(item_gobj, FALSE)

	return FALSE

## 0x80177B78
static func itBombHeiExplodeMapSetStatus(item_gobj) -> void:
	itBombHeiCommonSetHitStatusNormal(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITBombHeiStatusDescs, nITBombHeiStatusExplodeMap)

## 0x80177BAC
static func itBombHeiExplodeInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.multi = 0

	ip.attack_coll.throw_mul = ITEM_THROW_DEFAULT

	ip.event_id = 0

	itBombHeiCommonUpdateAttackEvent(item_gobj)

## 0x80177BE8
static func itBombHeiExplodeProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	itBombHeiCommonUpdateAttackEvent(item_gobj)

	ip.multi = (ip.multi + 1) & 0xFFFF   # u16 multi

	if ip.multi == ITBOMBHEI_EXPLODE_LIFETIME:
		return TRUE
	else:
		return FALSE

## 0x80177C30
static func itBombHeiExplodeSetStatus(item_gobj) -> void:
	itBombHeiExplodeInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITBombHeiStatusDescs, nITBombHeiStatusExplode)

## 0x80177C64
static func itBombHeiExplodeWaitProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	itBombHeiWalkUpdateEffect(item_gobj)

	if ip.multi == ITBOMBHEI_EXPLODE_WAIT:   # (u16 compared with the float 90.0F)
		itBombHeiCommonCheckMakeDustEffect(item_gobj, TRUE)
		itBombHeiCommonClearVelSetExplode(item_gobj, 0)
		Snd.func_800269C0_275C0(nSYAudioFGMExplodeL)

	ip.multi = (ip.multi + 1) & 0xFFFF   # u16 multi (also after the explosion status was entered)

	return FALSE

## 0x80177D00
static func itBombHeiExplodeWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itbombhei, &"itBombHeiDroppedSetStatus"))

	return FALSE

## 0x80177D28
static func itBombHeiExplodeWaitInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	ip.multi = 0

	Itmball.itPortGetDObjMObj(dobj).anim_pos = -1   # dobj->mobj->matanim_joint.event32 = NULL

	Itmain.itMainCheckSetColAnimID(item_gobj, nGMColAnimItemBombHeiCritical, ITBOMBHEI_EXPLODE_COLANIM_DURATION)

## 0x80177D60
static func itBombHeiExplodeWaitSetStatus(item_gobj) -> void:
	itBombHeiCommonSetHitStatusNormal(item_gobj)
	itBombHeiExplodeWaitInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITBombHeiStatusDescs, nITBombHeiStatusExplodeWait)

## 0x80177D9C
static func itBombHeiMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITBombHeiItemDesc, pos, vel, flags)
	var dobj: DObj
	var ip: Item
	var translate: Vector3                  # REGION_US

	if item_gobj != null:
		dobj = DObjGetStruct(item_gobj)

		translate = dobj.translate          # REGION_US

		ip = itGetStruct(item_gobj)

		ip.multi = 0

		Itmain.itMainClearOwnerStats(item_gobj)

		Objman.gcAddXObjForDObjFixed(dobj, 0x2E, 0)

		dobj.translate = translate          # REGION_US

		ip.is_unused_item_bool = TRUE

		dobj.rotate.z = 0.0

		ip.arrow_gobj = Ifcommon.ifCommonItemArrowMakeInterface(ip)

	return item_gobj
