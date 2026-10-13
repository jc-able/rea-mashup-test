## 1:1 port of src/it/itmap.c (ssb-decomp-re): item map-collision procs.
##
## Conventions (PORTING.md):
##   * itMapProc* collision callbacks are handed to Mpprocess.mpProcessUpdateMain as Callables and
##     receive (coll_data, item_gobj, flags).
##   * proc_map / proc_status arguments (C: void (*)(GObj*)) are Callables (Callable() or null == NULL).
##   * itMapCheckCollideAllRebound(item_gobj, check_flags, mod_vel, pos = null) -> {"ret": sb32, "pos": Vector3}
##     (C: sb32 (..., Vec3f *pos); pos is written only when ret is TRUE and pos != NULL, otherwise the
##     passed-in value is returned unchanged. C callers that pass NULL just use "ret".)
##   * itMapSetGroundRebound(vel, floor_angle, ground_rebound) -> the new vel
##     (C: void (Vec3f *vel, Vec3f *floor_angle, f32)) - call as
##     ip.physics.vel_air = Itmap.itMapSetGroundRebound(ip.physics.vel_air, ip.coll_data.floor_angle, r)
class_name Itmap
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80173480
static func itMapProcLRWallCheckFloor(coll_data = null, item_gobj = null, flags = null) -> int:
	var floor_line_id: int = coll_data.floor_line_id
	var is_collide_floor: int = FALSE

	if Mpprocess.mpProcessCheckTestLWallCollision(coll_data) != FALSE:
		Mpprocess.mpProcessRunLWallCollision(coll_data)
		coll_data.is_coll_end = TRUE

	if Mpprocess.mpProcessCheckTestRWallCollision(coll_data) != FALSE:
		Mpprocess.mpProcessRunRWallCollision(coll_data)
		coll_data.is_coll_end = TRUE

	if Mpprocess.mpProcessCheckTestFloorCollisionNew(coll_data) != FALSE:
		if coll_data.mask_stat & MAP_FLAG_FLOOR:
			Mpprocess.mpProcessRunFloorEdgeAdjust(coll_data)
			is_collide_floor = TRUE
	else:
		coll_data.is_coll_end = TRUE

	if Mpprocess.mpProcessCheckTestFloorCollision(coll_data, floor_line_id) != FALSE:
		Mpprocess.mpProcessSetLandingFloor(coll_data)

		if coll_data.mask_stat & MAP_FLAG_FLOOR:
			Mpprocess.mpProcessRunFloorEdgeAdjust(coll_data)
			is_collide_floor = TRUE

		coll_data.is_coll_end = FALSE

	return is_collide_floor

## 0x8017356C
static func itMapTestLRWallCheckFloor(item_gobj = null) -> int:
	return Mpprocess.mpProcessUpdateMain(itGetStruct(item_gobj).coll_data, Callable(Itmap, &"itMapProcLRWallCheckFloor"), item_gobj, 0)

## 0x801735A0
static func itMapCheckLRWallProcNoFloor(item_gobj = null, proc_map = null) -> int:
	if itMapTestLRWallCheckFloor(item_gobj) == FALSE:
		proc_map.call(item_gobj)

		return FALSE
	else:
		return TRUE

## 0x801735E0
static func itMapProcAllCheckCollEnd(coll_data = null, item_gobj = null, flags = null) -> int:
	var ip := itGetStruct(item_gobj)
	var joint := DObjGetStruct(item_gobj)

	if Mpprocess.mpProcessCheckTestLWallCollisionAdjNew(coll_data) != FALSE:
		coll_data.is_coll_end = TRUE

	if Mpprocess.mpProcessCheckTestRWallCollisionAdjNew(coll_data) != FALSE:
		coll_data.is_coll_end = TRUE

	if Mpprocess.mpProcessCheckTestCeilCollisionAdjNew(coll_data) != FALSE:
		coll_data.is_coll_end = TRUE

	if Mpprocess.mpProcessRunFloorCollisionAdjNewNULL(coll_data) != FALSE:
		coll_data.is_coll_end = TRUE

		Snd.func_800269C0_275C0(nSYAudioFGMItemMapCollide)

		ip.spin_step = 0.0
		joint.rotate.z = 0.0

	return coll_data.is_coll_end

## 0x80173680
static func itMapTestAllCheckCollEnd(item_gobj = null) -> int:
	return Mpprocess.mpProcessUpdateMain(itGetStruct(item_gobj).coll_data, Callable(Itmap, &"itMapProcAllCheckCollEnd"), item_gobj, 0)

## 0x801736B4
static func itMapProcAllCheckCollisionFlag(coll_data = null, item_gobj = null, coll_flags = null) -> int:
	var ip := itGetStruct(item_gobj)
	var joint := DObjGetStruct(item_gobj)

	if Mpprocess.mpProcessCheckTestLWallCollisionAdjNew(coll_data) != FALSE:
		Mpprocess.mpProcessRunLWallCollisionAdjNew(coll_data)

	if Mpprocess.mpProcessCheckTestRWallCollisionAdjNew(coll_data) != FALSE:
		Mpprocess.mpProcessRunRWallCollisionAdjNew(coll_data)

	if Mpprocess.mpProcessCheckTestCeilCollisionAdjNew(coll_data) != FALSE:
		Mpprocess.mpProcessRunCeilCollisionAdjNew(coll_data)

		if coll_data.mask_stat & MAP_FLAG_CEIL:
			Mpprocess.mpProcessRunCeilEdgeAdjust(coll_data)

	if Mpprocess.mpProcessRunFloorCollisionAdjNewNULL(coll_data) != FALSE:
		Mpprocess.mpProcessSetLandingFloor(coll_data)

		if coll_data.mask_stat & MAP_FLAG_FLOOR:
			Mpprocess.mpProcessRunFloorEdgeAdjust(coll_data)
			Snd.func_800269C0_275C0(nSYAudioFGMItemMapCollide)

			ip.spin_step = 0.0
			joint.rotate.z = 0.0

			coll_data.is_coll_end = TRUE

	if coll_data.mask_curr & int(coll_flags):
		return TRUE
	else:
		return FALSE

## 0x801737B8
static func itMapTestAllCollisionFlag(item_gobj = null, flag = null) -> int:
	return Mpprocess.mpProcessUpdateMain(itGetStruct(item_gobj).coll_data, Callable(Itmap, &"itMapProcAllCheckCollisionFlag"), item_gobj, int(flag))

## 0x801737EC - Modify velocity based on angle of collision. Returns {"ret": sb32, "pos": pos}.
static func itMapCheckCollideAllRebound(item_gobj = null, check_flags = null, mod_vel = null, pos = null) -> Dictionary:
	var ip := itGetStruct(item_gobj)
	var coll_data: MPCollData = ip.coll_data
	var translate: DObj = DObjGetStruct(item_gobj) # Vec3f *translate = &DObjGetStruct(item_gobj)->translate.vec.f;
	var mod_pos: Vector3
	var return_bool: int = FALSE
	var coll_flags: int = ((ip.coll_data.mask_prev ^ ip.coll_data.mask_curr) & ip.coll_data.mask_curr & MAP_FLAG_MAIN_MASK) & 0xFFFF

	check_flags = int(check_flags)

	if coll_flags & check_flags & MAP_FLAG_LWALL:
		if Lbcommon.lbCommonSim2D(ip.physics.vel_air, coll_data.lwall_angle) < 0.0:
			ip.physics.vel_air = Lbcommon.lbCommonReflect2D(ip.physics.vel_air, coll_data.lwall_angle)

			mod_pos.x = translate.translate.x + coll_data.map_coll.width
			mod_pos.y = translate.translate.y + coll_data.map_coll.center

			return_bool = TRUE

			Snd.func_800269C0_275C0(nSYAudioFGMItemMapCollide)

	if coll_flags & check_flags & MAP_FLAG_RWALL:
		if Lbcommon.lbCommonSim2D(ip.physics.vel_air, coll_data.rwall_angle) < 0.0:
			ip.physics.vel_air = Lbcommon.lbCommonReflect2D(ip.physics.vel_air, coll_data.rwall_angle)

			mod_pos.x = translate.translate.x - coll_data.map_coll.width
			mod_pos.y = translate.translate.y + coll_data.map_coll.center

			return_bool = TRUE

			Snd.func_800269C0_275C0(nSYAudioFGMItemMapCollide)

	if coll_flags & check_flags & MAP_FLAG_CEIL:
		if Lbcommon.lbCommonSim2D(ip.physics.vel_air, coll_data.ceil_angle) < 0.0:
			ip.physics.vel_air = Lbcommon.lbCommonReflect2D(ip.physics.vel_air, coll_data.ceil_angle)

			mod_pos.x = translate.translate.x
			mod_pos.y = translate.translate.y + coll_data.map_coll.top

			return_bool = TRUE

	if coll_flags & check_flags & MAP_FLAG_FLOOR:
		if Lbcommon.lbCommonSim2D(ip.physics.vel_air, coll_data.floor_angle) < 0.0:
			ip.physics.vel_air = Lbcommon.lbCommonReflect2D(ip.physics.vel_air, coll_data.floor_angle)

			mod_pos.x = translate.translate.x
			mod_pos.y = translate.translate.y + coll_data.map_coll.bottom

			return_bool = TRUE

			Snd.func_800269C0_275C0(nSYAudioFGMItemMapCollide)

	if return_bool != FALSE:
		ip.physics.vel_air = Lbcommon.lbCommonScale2D(ip.physics.vel_air, f32(mod_vel))

		if pos != null:
			pos = Vector3(mod_pos.x, mod_pos.y, translate.translate.z)

	return {"ret": return_bool, "pos": pos}

## 0x80173A48 - returns the new vel (C writes *vel)
static func itMapSetGroundRebound(vel = null, floor_angle = null, ground_rebound = null) -> Vector3:
	var scale: float
	var inverse: float
	var rebound: float

	scale = f32(Lbcommon.lbCommonMag2D(vel))

	if scale != 0.0:
		inverse = f32(1.0 / scale)
		rebound = f32(f32(scale * f32(ground_rebound)) * 0.5)

		vel = Lbcommon.lbCommonReflect2D(vel, floor_angle)

		vel.x *= inverse
		vel.y *= inverse
		vel.x += floor_angle.x
		vel.y += floor_angle.y
		vel.x *= rebound
		vel.y *= rebound

	return vel

## 0x80173B24
static func itMapCheckDestroyDropped(item_gobj = null, common_rebound = null, ground_rebound = null, proc_status = null) -> int:
	var ip := itGetStruct(item_gobj)
	var is_collide_floor: int = itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_FLOOR)

	if itMapCheckCollideAllRebound(item_gobj, (MAP_FLAG_CEIL | MAP_FLAG_RWALL | MAP_FLAG_LWALL), common_rebound, null).ret != FALSE:
		Itmain.itMainSetSpinVelLR(item_gobj)

	if is_collide_floor != FALSE:
		ip.physics.vel_air = itMapSetGroundRebound(ip.physics.vel_air, ip.coll_data.floor_angle, ground_rebound)
		Itmain.itMainSetSpinVelLR(item_gobj)

		ip.times_landed = (ip.times_landed + 1) & 0x3 # u32 times_landed : 2

		if ip.times_landed == ITEM_LANDING_DESPAWN_CHECK:
			if (
				(G.gSCManagerBattleState.game_type != nSCBattleGameTypeExplain) and
				(ip.times_thrown != 0) and
				(
					(ip.times_thrown == ITEM_THROW_NUM_MAX)
					or
					(syUtilsRandIntRange(ITEM_THROW_DESPAWN_RANDOM) == 0)
				)
			):
				return TRUE

		if (ip.times_landed == ITEM_LANDING_NUM_MAX) and _itMapIsProc(proc_status):
			proc_status.call(item_gobj)

	return FALSE

## 0x80173C68
static func itMapCheckLanding(item_gobj = null, common_rebound = null, ground_rebound = null, proc_map = null) -> int:
	var ip := itGetStruct(item_gobj)
	var is_collide_floor: int = itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_FLOOR)

	if itMapCheckCollideAllRebound(item_gobj, (MAP_FLAG_CEIL | MAP_FLAG_RWALL | MAP_FLAG_LWALL), common_rebound, null).ret != FALSE:
		Itmain.itMainSetSpinVelLR(item_gobj)

	if is_collide_floor != FALSE:
		ip.physics.vel_air = Lbcommon.lbCommonReflect2D(ip.physics.vel_air, ip.coll_data.floor_angle)
		ip.physics.vel_air = Lbcommon.lbCommonScale2D(ip.physics.vel_air, f32(ground_rebound))
		Itmain.itMainSetSpinVelLR(item_gobj)

		if _itMapIsProc(proc_map):
			proc_map.call(item_gobj)

		return TRUE
	else:
		return FALSE

## 0x80173D24
static func itMapCheckMapReboundProcAll(item_gobj = null, common_rebound = null, ground_rebound = null, proc_map = null) -> int:
	var ip := itGetStruct(item_gobj)
	var coll_data: MPCollData = ip.coll_data
	var is_collide_any: int = itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_MAIN_MASK)

	if itMapCheckCollideAllRebound(item_gobj, (MAP_FLAG_CEIL | MAP_FLAG_RWALL | MAP_FLAG_LWALL), common_rebound, null).ret != FALSE:
		Itmain.itMainSetSpinVelLR(item_gobj)

	if coll_data.mask_curr & MAP_FLAG_FLOOR:
		ip.physics.vel_air = Lbcommon.lbCommonReflect2D(ip.physics.vel_air, coll_data.floor_angle)
		ip.physics.vel_air = Lbcommon.lbCommonScale2D(ip.physics.vel_air, f32(ground_rebound))
		Itmain.itMainSetSpinVelLR(item_gobj)

	if is_collide_any != FALSE:
		if _itMapIsProc(proc_map):
			proc_map.call(item_gobj)

		return TRUE
	else:
		return FALSE

## 0x80173DF4
static func itMapCheckDestroyLanding(item_gobj = null, common_rebound = null) -> int:
	var is_collide_floor: int = itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_FLOOR)

	if itMapCheckCollideAllRebound(item_gobj, (MAP_FLAG_CEIL | MAP_FLAG_RWALL | MAP_FLAG_LWALL), common_rebound, null).ret != FALSE:
		Itmain.itMainSetSpinVelLR(item_gobj)

	if is_collide_floor != FALSE:
		return TRUE
	else:
		return FALSE

## 0x80173E58
static func itMapCheckMapProcAll(item_gobj = null, proc_map = null) -> int:
	if (itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_MAIN_MASK) != FALSE) and _itMapIsProc(proc_map):
		proc_map.call(item_gobj)

	return FALSE

## 0x80173E9C - Unused
static func func_ovl3_80173E9C(item_gobj = null, proc = null) -> int:
	if itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_MAIN_MASK) != FALSE:
		if _itMapIsProc(proc):
			proc.call(item_gobj)

		return TRUE
	else:
		return FALSE

## 0x80173EE8
static func itMapCheckMapReboundProcNoFloor(item_gobj = null, common_rebound = null, proc_map = null) -> int:
	if (itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_FLOOR) != FALSE) and _itMapIsProc(proc_map):
		proc_map.call(item_gobj)

	if itMapCheckCollideAllRebound(item_gobj, (MAP_FLAG_CEIL | MAP_FLAG_RWALL | MAP_FLAG_LWALL), common_rebound, null).ret != FALSE:
		Itmain.itMainSetSpinVelLR(item_gobj)

	return FALSE

## 0x80173F54
static func itMapSetGround(ip = null) -> void:
	ip.ga = nMPKineticsGround
	ip.physics.vel_ground = ip.physics.vel_air.x * ip.lr

## 0x80173F78
static func itMapSetAir(ip = null) -> void:
	ip.ga = nMPKineticsAir

# // // // // // // // // // // // //
# //         PORT HELPERS          //
# // // // // // // // // // // // //

## C NULL test for a function pointer argument (Callable() or null == NULL)
static func _itMapIsProc(proc) -> bool:
	return (proc is Callable) and proc.is_valid()
