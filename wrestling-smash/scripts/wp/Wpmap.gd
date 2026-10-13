## 1:1 port of src/wp/wpmap.c (ssb-decomp-re): weapon map-collision procs.
##
## Pointer conventions:
##   wpMapCheckAllRebound(weapon_gobj, check_flags, mod_vel, pos = null) -> {"ret": sb32, "pos": Vector3}
##     (C: sb32 wpMapCheckAllRebound(GObj*, u32, f32, Vec3f *pos); pos is written only when ret
##     is TRUE, otherwise the passed-in value (default null) is returned unchanged. Callers that
##     pass NULL in C simply ignore "pos".)
##   The wpMapProc* collision callbacks are handed to Mpprocess.mpProcessUpdateMain as Callables
##   and receive (coll_data, weapon_gobj, flags).
class_name Wpmap
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80167880
static func wpMapProcLRWallCheckFloor(coll_data = null, weapon_gobj = null, flags = null) -> int:
	var floor_line_id: int = coll_data.floor_line_id
	var is_collide_floor := FALSE

	if B(Mpprocess.mpProcessCheckTestLWallCollision(coll_data)):
		Mpprocess.mpProcessRunLWallCollision(coll_data)

		coll_data.is_coll_end = TRUE

	if B(Mpprocess.mpProcessCheckTestRWallCollision(coll_data)):
		Mpprocess.mpProcessRunRWallCollision(coll_data)

		coll_data.is_coll_end = TRUE

	if B(Mpprocess.mpProcessCheckTestFloorCollisionNew(coll_data)):
		if coll_data.mask_stat & MAP_FLAG_FLOOR:
			Mpprocess.mpProcessRunFloorEdgeAdjust(coll_data)

			is_collide_floor = TRUE
	else:
		coll_data.is_coll_end = TRUE

	if B(Mpprocess.mpProcessCheckTestFloorCollision(coll_data, floor_line_id)):
		Mpprocess.mpProcessSetLandingFloor(coll_data)

		if coll_data.mask_stat & MAP_FLAG_FLOOR:
			Mpprocess.mpProcessRunFloorEdgeAdjust(coll_data)

			is_collide_floor = TRUE

		coll_data.is_coll_end = FALSE

	return is_collide_floor

## 0x8016796C
static func wpMapTestLRWallCheckFloor(weapon_gobj = null):
	return Mpprocess.mpProcessUpdateMain(wpGetStruct(weapon_gobj).coll_data, Callable(Wpmap, &"wpMapProcLRWallCheckFloor"), weapon_gobj, 0)

## 0x801679A0
static func wpMapProcAll(coll_data = null, weapon_gobj = null, flags = null) -> int:
	if B(Mpprocess.mpProcessCheckTestLWallCollisionAdjNew(coll_data)):
		Mpprocess.mpProcessRunLWallCollisionAdjNew(coll_data)

	if B(Mpprocess.mpProcessCheckTestRWallCollisionAdjNew(coll_data)):
		Mpprocess.mpProcessRunRWallCollisionAdjNew(coll_data)

	if B(Mpprocess.mpProcessCheckTestCeilCollisionAdjNew(coll_data)):
		Mpprocess.mpProcessRunCeilCollisionAdjNew(coll_data)

		if coll_data.mask_stat & MAP_FLAG_CEIL:
			Mpprocess.mpProcessRunCeilEdgeAdjust(coll_data)

	if B(Mpprocess.mpProcessRunFloorCollisionAdjNewNULL(coll_data)):
		Mpprocess.mpProcessSetCollideFloor(coll_data)

		if coll_data.mask_stat & MAP_FLAG_FLOOR:
			Mpprocess.mpProcessRunFloorEdgeAdjust(coll_data)

	return FALSE

## 0x80167A58
static func wpMapTestAll(weapon_gobj = null):
	return Mpprocess.mpProcessUpdateMain(wpGetStruct(weapon_gobj).coll_data, Callable(Wpmap, &"wpMapProcAll"), weapon_gobj, 0)

## 0x80167A8C
static func wpMapProcAllCheckFloor(coll_data = null, weapon_gobj = null, flags = null) -> int:
	if B(Mpprocess.mpProcessCheckTestLWallCollisionAdjNew(coll_data)):
		Mpprocess.mpProcessRunLWallCollisionAdjNew(coll_data)

	if B(Mpprocess.mpProcessCheckTestRWallCollisionAdjNew(coll_data)):
		Mpprocess.mpProcessRunRWallCollisionAdjNew(coll_data)

	if B(Mpprocess.mpProcessCheckTestCeilCollisionAdjNew(coll_data)):
		Mpprocess.mpProcessRunCeilCollisionAdjNew(coll_data)

		if coll_data.mask_stat & MAP_FLAG_CEIL:
			Mpprocess.mpProcessRunCeilEdgeAdjust(coll_data)

	if B(Mpprocess.mpProcessRunFloorCollisionAdjNewNULL(coll_data)):
		Mpprocess.mpProcessSetLandingFloor(coll_data)

		if coll_data.mask_stat & MAP_FLAG_FLOOR:
			Mpprocess.mpProcessRunFloorEdgeAdjust(coll_data)

			coll_data.is_coll_end = TRUE

			return TRUE

	return FALSE

## 0x80167B58
static func wpMapTestAllCheckFloor(weapon_gobj = null):
	return Mpprocess.mpProcessUpdateMain(wpGetStruct(weapon_gobj).coll_data, Callable(Wpmap, &"wpMapProcAllCheckFloor"), weapon_gobj, 0)

## 0x80167B8C
static func wpMapProcAllCheckCollEnd(coll_data = null, weapon_gobj = null, flags = null) -> int:
	if B(Mpprocess.mpProcessCheckTestLWallCollisionAdjNew(coll_data)):
		coll_data.is_coll_end = TRUE

	if B(Mpprocess.mpProcessCheckTestRWallCollisionAdjNew(coll_data)):
		coll_data.is_coll_end = TRUE

	if B(Mpprocess.mpProcessCheckTestCeilCollisionAdjNew(coll_data)):
		coll_data.is_coll_end = TRUE

	if B(Mpprocess.mpProcessRunFloorCollisionAdjNewNULL(coll_data)):
		coll_data.is_coll_end = TRUE

	return coll_data.is_coll_end

## 0x80167C04
static func wpMapTestAllCheckCollEnd(weapon_gobj = null):
	return Mpprocess.mpProcessUpdateMain(wpGetStruct(weapon_gobj).coll_data, Callable(Wpmap, &"wpMapProcAllCheckCollEnd"), weapon_gobj, 0)

## 0x80167C38
## Modify velocity based on angle of collision. Returns {"ret": sb32, "pos": Vec3f}.
static func wpMapCheckAllRebound(weapon_gobj = null, check_flags = null, mod_vel = null, pos = null) -> Dictionary:
	var wp := wpGetStruct(weapon_gobj)
	var coll_data: MPCollData = wp.coll_data
	var return_bool := FALSE
	var mod_pos := Vector3.ZERO
	var translate: Vector3 = DObjGetStruct(weapon_gobj).translate
	var coll_flags: int = ((wp.coll_data.mask_prev ^ wp.coll_data.mask_curr) & wp.coll_data.mask_curr & MAP_FLAG_MAIN_MASK) & 0xFFFF

	if coll_flags & check_flags & MAP_FLAG_LWALL:
		if Lbcommon.lbCommonSim2D(wp.physics.vel_air, coll_data.lwall_angle) < 0.0:
			wp.physics.vel_air = Lbcommon.lbCommonReflect2D(wp.physics.vel_air, coll_data.lwall_angle)

			return_bool = TRUE

			mod_pos.x = translate.x + coll_data.map_coll.width
			mod_pos.y = translate.y + coll_data.map_coll.center

	if coll_flags & check_flags & MAP_FLAG_RWALL:
		if Lbcommon.lbCommonSim2D(wp.physics.vel_air, coll_data.rwall_angle) < 0.0:
			return_bool = TRUE

			wp.physics.vel_air = Lbcommon.lbCommonReflect2D(wp.physics.vel_air, coll_data.rwall_angle)

			mod_pos.x = translate.x - coll_data.map_coll.width
			mod_pos.y = translate.y + coll_data.map_coll.center

	if coll_flags & check_flags & MAP_FLAG_CEIL:
		if Lbcommon.lbCommonSim2D(wp.physics.vel_air, coll_data.ceil_angle) < 0.0:
			return_bool = TRUE

			wp.physics.vel_air = Lbcommon.lbCommonReflect2D(wp.physics.vel_air, coll_data.ceil_angle)

			mod_pos.x = translate.x
			mod_pos.y = translate.y + coll_data.map_coll.top

	if coll_flags & check_flags & MAP_FLAG_FLOOR:
		if Lbcommon.lbCommonSim2D(wp.physics.vel_air, coll_data.floor_angle) < 0.0:
			return_bool = TRUE

			wp.physics.vel_air = Lbcommon.lbCommonReflect2D(wp.physics.vel_air, coll_data.floor_angle)

			mod_pos.x = translate.x
			mod_pos.y = translate.y + coll_data.map_coll.bottom

	if return_bool != FALSE:
		wp.physics.vel_air = Lbcommon.lbCommonScale2D(wp.physics.vel_air, mod_vel)

		pos = Vector3(mod_pos.x, mod_pos.y, translate.z) # if (pos != NULL) { pos->x/y/z = ... }

	return {"ret": return_bool, "pos": pos}

## 0x80167E78
static func wpMapSetGround(wp = null) -> void: # Make weapon grounded
	wp.ga = nMPKineticsGround
	wp.physics.vel_ground = wp.physics.vel_air.x * wp.lr

## 0x80167E9C
static func wpMapSetAir(wp = null) -> void: # Make item airborne
	wp.ga = nMPKineticsAir
