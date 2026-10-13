## Port of src/mp/mpprocess.c: per-object map collision resolution (walls, floor, ceiling,
## ledges, floor/ceiling edge adjustment) and the collision update driver mpProcessUpdateMain.
##
## coll_data is an MPCollData (reference); *coll_data->p_translate is accessed through the
## coll_data.p_translate property (owner's TopN translate) and written component-wise.
## Calls into Mpcollision follow its out-parameter convention: outputs that C writes only on a hit
## (e.g. &coll_data->floor_flags) are passed in as their current value and assigned back from the
## returned Dictionary, which reproduces the C pointer semantics exactly.
class_name Mpprocess
extends Port

# // // // // // // // // // // // //
#    GLOBAL / STATIC VARIABLES
# // // // // // // // // // // // //

## 0x80130DE0
static var sMPProcessMultiWallCollidesNum: int = 0
## 0x80130DE4
static var sMPProcessPad0x80130DE4: int = 0
## 0x80130DE8 - Simultaneous wall collisions
static var sMPProcessMultiWallCollideLineIDs: Array = [0, 0, 0, 0, 0]
## 0x80130DFC - Position where latest wall collision was detected
static var sMPProcessLastWallCollidePosition: float = 0.0
## 0x80130E00 - Line ID of latest wall collided with
static var sMPProcessLastWallLineID: int = 0
## 0x80130E04
static var sMPProcessLastWallFlags: int = 0
## 0x80130E08
static var sMPProcessLastWallAngle: Vector3 = Vector3.ZERO

# // // // // // // // // // // // //
#        PORT HELPERS
# // // // // // // // // // // // //

## C NULL test for a function-pointer argument (Callable() or null).
static func _is_null_proc(proc) -> bool:
	return (proc == null) or ((proc is Callable) and not proc.is_valid())

## sb32 value returned through a function pointer (ported procs may return bool or int).
static func _sb32(v) -> int:
	if v == null:
		return FALSE
	if v is bool:
		return TRUE if v else FALSE
	return int(v)

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x800D9510
static func mpProcessResetMultiWallCount() -> void:
	sMPProcessMultiWallCollidesNum = 0

## 0x800D951C
static func mpProcessSetMultiWallLineID(line_id: int) -> void:
	for i in range(sMPProcessMultiWallCollidesNum):
		if line_id == sMPProcessMultiWallCollideLineIDs[i]:
			return
	if sMPProcessMultiWallCollidesNum != sMPProcessMultiWallCollideLineIDs.size():
		sMPProcessMultiWallCollideLineIDs[sMPProcessMultiWallCollidesNum] = line_id
		sMPProcessMultiWallCollidesNum += 1

## 0x800D957C
static func mpProcessSetLastWallCollideLeft() -> void:
	sMPProcessLastWallCollidePosition = -65536.0

## 0x800D9590
static func mpProcessSetLastWallCollideRight() -> void:
	sMPProcessLastWallCollidePosition = 65536.0

## 0x800D95A4
static func mpProcessSetLastWallCollideStats(pos: float, line_id: int, flags: int, angle: Vector3) -> void:
	sMPProcessLastWallCollidePosition = pos
	sMPProcessLastWallLineID          = line_id
	sMPProcessLastWallFlags           = flags
	sMPProcessLastWallAngle           = angle

## 0x800D95E0
## C: void mpProcessGetLastWallCollideStats(f32 *pos, s32 *line_id, u32 *flags, Vec3f *angle)
## Returns {"pos", "line_id", "flags", "angle"} (all pure outputs; arguments are ignored).
static func mpProcessGetLastWallCollideStats(pos = null, line_id = null, flags = null, angle = null) -> Dictionary:
	return {
		"pos": sMPProcessLastWallCollidePosition,
		"line_id": sMPProcessLastWallLineID,
		"flags": sMPProcessLastWallFlags,
		"angle": sMPProcessLastWallAngle,
	}

## 0x800D9628
static func mpProcessCheckCeilEdgeCollisionL(coll_data: MPCollData) -> int:
	var map_coll: MPObjectColl = coll_data.map_coll
	var b := Vector3.ZERO
	var a := Vector3.ZERO
	var sp2C: int = 0
	var sp28: int
	var r: Dictionary

	sp28 = Mpcollision.mpCollisionGetEdgeUpperRLineID(coll_data.ceil_line_id)

	b.x = coll_data.p_translate.x
	b.y = coll_data.p_translate.y + map_coll.top
	a.x = coll_data.p_translate.x + map_coll.width
	a.y = coll_data.p_translate.y + map_coll.center

	r = Mpcollision.mpCollisionCheckLWallLineCollisionSame(b, a, Vector3.ZERO, sp2C)
	sp2C = r.stand_line_id

	if (r.ret != FALSE) and (sp2C != sp28):
		return TRUE
	return FALSE

## 0x800D96D8
static func mpProcessCeilEdgeAdjustLeft(coll_data: MPCollData) -> void:
	var map_coll: MPObjectColl = coll_data.map_coll
	var sp3C := Vector3.ZERO
	var object_pos := Vector3.ZERO
	var ceil_dist: float
	var r: Dictionary

	object_pos.x = coll_data.p_translate.x + map_coll.width
	sp3C.x = object_pos.x

	object_pos.y = coll_data.p_translate.y + map_coll.center
	sp3C.y = object_pos.y

	sp3C.x += (2.0 * (coll_data.ceil_angle.y * map_coll.width))
	sp3C.y += (2.0 * (-coll_data.ceil_angle.x * map_coll.width))

	r = Mpcollision.mpCollisionCheckLWallLineCollisionSame(sp3C, object_pos, coll_data.line_coll_dist)
	coll_data.line_coll_dist = r.ga_last

	if r.ret != FALSE:
		object_pos.x = coll_data.line_coll_dist.x - map_coll.width
		object_pos.y = coll_data.p_translate.y + map_coll.top

		r = Mpcollision.mpCollisionGetFCCommonCeil(coll_data.ceil_line_id, object_pos, 0.0, coll_data.ceil_flags, coll_data.ceil_angle)
		coll_data.ceil_flags = r.flags
		coll_data.ceil_angle = r.angle

		if r.ret != FALSE:
			ceil_dist = r.dist

			coll_data.p_translate.y += ceil_dist
			coll_data.p_translate.x = object_pos.x

## 0x800D97F0
static func mpProcessCheckCeilEdgeCollisionR(coll_data: MPCollData) -> int:
	var map_coll: MPObjectColl = coll_data.map_coll
	var b := Vector3.ZERO
	var a := Vector3.ZERO
	var sp2C: int = 0
	var sp28: int
	var r: Dictionary

	sp28 = Mpcollision.mpCollisionGetEdgeUpperLLineID(coll_data.ceil_line_id)

	b.x = coll_data.p_translate.x
	b.y = coll_data.p_translate.y + map_coll.top
	a.x = coll_data.p_translate.x - map_coll.width
	a.y = coll_data.p_translate.y + map_coll.center

	r = Mpcollision.mpCollisionCheckRWallLineCollisionSame(b, a, Vector3.ZERO, sp2C)
	sp2C = r.stand_line_id

	if (r.ret != FALSE) and (sp2C != sp28):
		return TRUE
	return FALSE

## 0x800D98A0
static func mpProcessCeilEdgeAdjustRight(coll_data: MPCollData) -> void:
	var map_coll: MPObjectColl = coll_data.map_coll
	var sp3C := Vector3.ZERO
	var object_pos := Vector3.ZERO
	var ceil_dist: float
	var r: Dictionary

	object_pos.x = coll_data.p_translate.x - map_coll.width
	sp3C.x = object_pos.x

	object_pos.y = coll_data.p_translate.y + map_coll.center
	sp3C.y = object_pos.y

	sp3C.x += (2.0 * (-coll_data.ceil_angle.y * map_coll.width))
	sp3C.y += (2.0 * (coll_data.ceil_angle.x * map_coll.width))

	r = Mpcollision.mpCollisionCheckRWallLineCollisionSame(sp3C, object_pos, coll_data.line_coll_dist)
	coll_data.line_coll_dist = r.ga_last

	if r.ret != 0:
		object_pos.x = coll_data.line_coll_dist.x + map_coll.width
		object_pos.y = coll_data.p_translate.y + map_coll.top

		r = Mpcollision.mpCollisionGetFCCommonCeil(coll_data.ceil_line_id, object_pos, 0.0, coll_data.ceil_flags, coll_data.ceil_angle)
		coll_data.ceil_flags = r.flags
		coll_data.ceil_angle = r.angle

		if r.ret != FALSE:
			ceil_dist = r.dist

			coll_data.p_translate.y += ceil_dist
			coll_data.p_translate.x = object_pos.x

## 0x800D99B8
static func mpProcessRunCeilEdgeAdjust(coll_data: MPCollData) -> void:
	if mpProcessCheckCeilEdgeCollisionL(coll_data) != FALSE:
		mpProcessCeilEdgeAdjustLeft(coll_data)
	if mpProcessCheckCeilEdgeCollisionR(coll_data) != FALSE:
		mpProcessCeilEdgeAdjustRight(coll_data)

## 0x800D9A00
static func mpProcessCheckFloorEdgeCollisionL(coll_data: MPCollData) -> int:
	var map_coll: MPObjectColl = coll_data.map_coll
	var b := Vector3.ZERO
	var a := Vector3.ZERO
	var sp2C: int = Mpcollision.mpCollisionGetEdgeUnderLLineID(coll_data.floor_line_id)
	var r: Dictionary

	b.x = coll_data.p_translate.x
	b.y = coll_data.p_translate.y + map_coll.bottom
	a.x = coll_data.p_translate.x + map_coll.width
	a.y = coll_data.p_translate.y + map_coll.center

	r = Mpcollision.mpCollisionCheckLWallLineCollisionSame(b, a, Vector3.ZERO, coll_data.ewall_line_id)
	coll_data.ewall_line_id = r.stand_line_id

	if (r.ret != FALSE) and (sp2C != coll_data.ewall_line_id):
		return TRUE
	return FALSE

## 0x800D9AB0
static func mpProcessFloorEdgeLAdjust(coll_data: MPCollData) -> void:
	var map_coll: MPObjectColl = coll_data.map_coll
	var sp44 := Vector3.ZERO
	var sp38 := Vector3.ZERO
	var sp34: float
	var r: Dictionary

	sp38.x = coll_data.p_translate.x + map_coll.width
	sp38.y = coll_data.p_translate.y + map_coll.center

	if Mpcollision.mpCollisionGetLRCommonLWall(coll_data.ewall_line_id, sp38).ret != FALSE:
		sp38.x = coll_data.p_translate.x + map_coll.width
		sp44.x = sp38.x
		sp38.y = coll_data.p_translate.y + map_coll.center
		sp44.y = sp38.y

		sp44.x += (2.0 * (-coll_data.floor_angle.y * map_coll.width))
		sp44.y += (2.0 * (coll_data.floor_angle.x * map_coll.width))

		r = Mpcollision.mpCollisionCheckLWallLineCollisionSame(sp44, sp38, coll_data.line_coll_dist)
		coll_data.line_coll_dist = r.ga_last

		if r.ret != FALSE:
			sp38.x = coll_data.line_coll_dist.x - map_coll.width
			sp38.y = coll_data.p_translate.y + map_coll.bottom

			r = Mpcollision.mpCollisionGetFCCommonFloor(coll_data.floor_line_id, sp38, 0.0, coll_data.floor_flags, coll_data.floor_angle)
			coll_data.floor_flags = r.flags
			coll_data.floor_angle = r.angle

			if r.ret != FALSE:
				sp34 = r.dist

				coll_data.p_translate.y += sp34
				coll_data.p_translate.x = sp38.x
	else:
		sp44 = Mpcollision.mpCollisionGetLWallEdgeU(coll_data.ewall_line_id)

		sp44.x -= 2.0
		sp38.x = sp44.x - (2.0 * map_coll.width)
		sp38.y = sp44.y - (2.0 * (map_coll.center - map_coll.bottom))

		r = Mpcollision.mpCollisionCheckFloorLineCollisionSame(sp44, sp38, coll_data.line_coll_dist)
		coll_data.line_coll_dist = r.ga_last

		if r.ret != FALSE:
			sp38.x = coll_data.line_coll_dist.x
			sp38.y = coll_data.p_translate.y

			r = Mpcollision.mpCollisionGetFCCommonFloor(coll_data.floor_line_id, sp38, 0.0, coll_data.floor_flags, coll_data.floor_angle)
			coll_data.floor_flags = r.flags
			coll_data.floor_angle = r.angle

			if r.ret != FALSE:
				sp34 = r.dist

				coll_data.p_translate.y += sp34
				coll_data.p_translate.x = sp38.x

## 0x800D9CC0
static func mpProcessCheckFloorEdgeCollisionR(coll_data: MPCollData) -> int:
	var map_coll: MPObjectColl = coll_data.map_coll
	var b := Vector3.ZERO
	var a := Vector3.ZERO
	var sp2C: int = Mpcollision.mpCollisionGetEdgeUnderRLineID(coll_data.floor_line_id)
	var r: Dictionary

	b.x = coll_data.p_translate.x
	b.y = coll_data.p_translate.y + map_coll.bottom
	a.x = coll_data.p_translate.x - map_coll.width
	a.y = coll_data.p_translate.y + map_coll.center

	r = Mpcollision.mpCollisionCheckRWallLineCollisionSame(b, a, Vector3.ZERO, coll_data.ewall_line_id)
	coll_data.ewall_line_id = r.stand_line_id

	if (r.ret != FALSE) and (sp2C != coll_data.ewall_line_id):
		return TRUE
	return FALSE

## 0x800D9D70
static func mpProcessFloorEdgeRAdjust(coll_data: MPCollData) -> void:
	var map_coll: MPObjectColl = coll_data.map_coll
	var sp44 := Vector3.ZERO
	var sp38 := Vector3.ZERO
	var floor_dist: float
	var r: Dictionary

	sp38.x = coll_data.p_translate.x - map_coll.width
	sp38.y = coll_data.p_translate.y + map_coll.center

	if Mpcollision.mpCollisionGetLRCommonRWall(coll_data.ewall_line_id, sp38).ret != FALSE:
		sp38.x = coll_data.p_translate.x - map_coll.width
		sp44.x = sp38.x
		sp38.y = coll_data.p_translate.y + map_coll.center
		sp44.y = sp38.y

		sp44.x += (2.0 * (coll_data.floor_angle.y * map_coll.width))
		sp44.y += (2.0 * (-coll_data.floor_angle.x * map_coll.width))

		r = Mpcollision.mpCollisionCheckRWallLineCollisionSame(sp44, sp38, coll_data.line_coll_dist)
		coll_data.line_coll_dist = r.ga_last

		if r.ret != FALSE:
			sp38.x = coll_data.line_coll_dist.x + map_coll.width
			sp38.y = coll_data.p_translate.y + map_coll.bottom

			r = Mpcollision.mpCollisionGetFCCommonFloor(coll_data.floor_line_id, sp38, 0.0, coll_data.floor_flags, coll_data.floor_angle)
			coll_data.floor_flags = r.flags
			coll_data.floor_angle = r.angle

			if r.ret != FALSE:
				floor_dist = r.dist

				coll_data.p_translate.y += floor_dist
				coll_data.p_translate.x = sp38.x
	else:
		sp44 = Mpcollision.mpCollisionGetRWallEdgeU(coll_data.ewall_line_id)

		# NOTE: unlike mpProcessFloorEdgeLAdjust, the matched C overwrites sp44 from sp38 here
		# (sp38 still holds translate - width / translate + center from above). Kept as is.
		sp44.x += 2.0
		sp44.x = sp38.x + (2.0 * map_coll.width)
		sp44.y = sp38.y - (2.0 * (map_coll.center - map_coll.bottom))

		r = Mpcollision.mpCollisionCheckFloorLineCollisionSame(sp44, sp38, coll_data.line_coll_dist)
		coll_data.line_coll_dist = r.ga_last

		if r.ret != FALSE:
			sp38.x = coll_data.line_coll_dist.x
			sp38.y = coll_data.p_translate.y

			r = Mpcollision.mpCollisionGetFCCommonFloor(coll_data.floor_line_id, sp38, 0.0, coll_data.floor_flags, coll_data.floor_angle)
			coll_data.floor_flags = r.flags
			coll_data.floor_angle = r.angle

			if r.ret != FALSE:
				floor_dist = r.dist

				coll_data.p_translate.y += floor_dist
				coll_data.p_translate.x = sp38.x

## 0x800D9F84
static func mpProcessRunFloorEdgeAdjust(coll_data: MPCollData) -> void:
	if mpProcessCheckFloorEdgeCollisionL(coll_data) != FALSE:
		mpProcessFloorEdgeLAdjust(coll_data)
	if mpProcessCheckFloorEdgeCollisionR(coll_data) != FALSE:
		mpProcessFloorEdgeRAdjust(coll_data)

## 0x800D9FCC - Check if object is above ground while airborne
static func mpProcessSetCollProjectFloorID(coll_data: MPCollData) -> void:
	var map_coll: MPObjectColl = coll_data.map_coll
	var sp2C := Vector3.ZERO
	var r: Dictionary

	sp2C.x = coll_data.p_translate.x
	sp2C.y = coll_data.p_translate.y + map_coll.bottom

	r = Mpcollision.mpCollisionCheckProjectFloor(sp2C, coll_data.floor_line_id, coll_data.floor_dist, coll_data.floor_flags, coll_data.floor_angle)
	coll_data.floor_line_id = r.project_line_id
	coll_data.floor_dist = r.ga_dist
	coll_data.floor_flags = r.stand_coll_flags
	coll_data.floor_angle = r.angle

	if r.ret == FALSE:
		coll_data.floor_line_id = -1

## 0x800DA034
## C: sb32 mpProcessUpdateMain(MPCollData *coll_data, sb32 (*proc_coll)(MPCollData*, GObj*, u32), GObj *gobj, u32 flags)
## proc_coll: Callable(coll_data, gobj, flags) -> sb32
static func mpProcessUpdateMain(coll_data: MPCollData, proc_coll: Callable, gobj, flags: int) -> int:
	var diff := Vector2.ZERO        # Distance between current and previous positions (Vec2f)
	var add_x: float                # Position difference added to X-Position on each iteration
	var add_y: float                # Position difference added to Y-Position on each iteration
	var add_z: float                # Position difference added to Z-Position on each iteration
	var i: int                      # Collision update iterator
	var update_count: int           # Up to 10 updates in a single tic
	var result: int = FALSE         # Result of collision test (uninitialised in C if no update runs)

	if coll_data.p_translate.x < coll_data.pos_prev.x:
		diff.x = -(coll_data.p_translate.x - coll_data.pos_prev.x)
	else:
		diff.x = coll_data.p_translate.x - coll_data.pos_prev.x

	if coll_data.p_translate.y < coll_data.pos_prev.y:
		diff.y = -(coll_data.p_translate.y - coll_data.pos_prev.y)
	else:
		diff.y = coll_data.p_translate.y - coll_data.pos_prev.y

	if (diff.x > 250.0) or (diff.y > 250.0):
		# Divide by 250.0 if either difference is greater than it (this is essentially 1/10th of maximum knockback velocity, which is 2500.0).
		update_count = int(Mpcollision._f32(diff.x / 250.0)) if (diff.x > diff.y) else int(Mpcollision._f32(diff.y / 250.0))
		update_count += 1

		add_x = Mpcollision._f32(coll_data.pos_diff.x / update_count)
		add_y = Mpcollision._f32(coll_data.pos_diff.y / update_count)
		add_z = Mpcollision._f32(coll_data.pos_diff.z / update_count)
	else:
		update_count = 1

		add_x = coll_data.pos_diff.x
		add_y = coll_data.pos_diff.y
		add_z = coll_data.pos_diff.z
	coll_data.p_translate = coll_data.pos_prev

	i = 0
	while (i < update_count) and (coll_data.is_coll_end == FALSE):
		coll_data.pos_prev = coll_data.p_translate

		# Velocity from stage elements is applied only on the first update.
		if i == 0:
			coll_data.p_translate.x += coll_data.vel_speed.x + coll_data.vel_push.x
			coll_data.p_translate.y += coll_data.vel_speed.y + coll_data.vel_push.y
			coll_data.p_translate.z += coll_data.vel_speed.z + coll_data.vel_push.z
		# Add position difference between current and previous positions to current position.
		coll_data.p_translate.x += add_x
		coll_data.p_translate.y += add_y
		coll_data.p_translate.z += add_z

		result = _sb32(proc_coll.call(coll_data, gobj, flags))
		i += 1
	coll_data.update_tic = Mpcollision.gMPCollisionUpdateTic

	return result

## 0x800DA294
static func mpProcessCheckTestLWallCollision(coll_data: MPCollData) -> int:
	var map_coll: MPObjectColl = coll_data.map_coll
	var p_map_coll: MPObjectColl = coll_data.p_map_coll
	var sp4C := Vector3.ZERO
	var sp40 := Vector3.ZERO
	var is_collide_lwall: int = FALSE
	var test_line_id: int = 0
	var floor_line_id: int
	var wall_collide: int
	var r: Dictionary

	mpProcessResetMultiWallCount()

	floor_line_id = Mpcollision.mpCollisionGetEdgeUnderLLineID(coll_data.floor_line_id) if (Mpcollision.mpCollisionCheckExistLineID(coll_data.floor_line_id) != FALSE) else -1

	sp4C.x = coll_data.pos_prev.x + p_map_coll.width
	sp4C.y = coll_data.pos_prev.y + p_map_coll.center
	sp40.x = coll_data.p_translate.x + map_coll.width
	sp40.y = coll_data.p_translate.y + map_coll.center

	r = Mpcollision.mpCollisionCheckLWallLineCollisionDiff(sp4C, sp40, Vector3.ZERO, test_line_id) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckLWallLineCollisionSame(sp4C, sp40, Vector3.ZERO, test_line_id)
	wall_collide = r.ret
	test_line_id = r.stand_line_id

	if (wall_collide != FALSE) and (test_line_id != floor_line_id):
		mpProcessSetMultiWallLineID(test_line_id)

		is_collide_lwall = TRUE
	sp4C.x = coll_data.pos_prev.x
	sp4C.y = coll_data.pos_prev.y + p_map_coll.bottom
	sp40.x = coll_data.p_translate.x
	sp40.y = coll_data.p_translate.y + map_coll.bottom

	r = Mpcollision.mpCollisionCheckLWallLineCollisionDiff(sp4C, sp40, Vector3.ZERO, test_line_id) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckLWallLineCollisionSame(sp4C, sp40, Vector3.ZERO, test_line_id)
	wall_collide = r.ret
	test_line_id = r.stand_line_id

	if (wall_collide != FALSE) and (test_line_id != floor_line_id):
		mpProcessSetMultiWallLineID(test_line_id)

		is_collide_lwall = TRUE
	sp4C.x = coll_data.pos_prev.x
	sp4C.y = coll_data.pos_prev.y + p_map_coll.top
	sp40.x = coll_data.p_translate.x
	sp40.y = coll_data.p_translate.y + map_coll.top

	r = Mpcollision.mpCollisionCheckLWallLineCollisionDiff(sp4C, sp40, Vector3.ZERO, test_line_id) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckLWallLineCollisionSame(sp4C, sp40, Vector3.ZERO, test_line_id)
	wall_collide = r.ret
	test_line_id = r.stand_line_id

	if (wall_collide != FALSE) and (test_line_id != floor_line_id):
		mpProcessSetMultiWallLineID(test_line_id)

		is_collide_lwall = TRUE
	sp4C.x = coll_data.p_translate.x
	sp4C.y = coll_data.p_translate.y + map_coll.bottom
	sp40.x = coll_data.p_translate.x + map_coll.width
	sp40.y = coll_data.p_translate.y + map_coll.center

	r = Mpcollision.mpCollisionCheckLWallLineCollisionSame(sp4C, sp40, Vector3.ZERO, test_line_id)
	test_line_id = r.stand_line_id

	if (r.ret != FALSE) and (test_line_id != floor_line_id):
		mpProcessSetMultiWallLineID(test_line_id)

		is_collide_lwall = TRUE
	sp4C.x = coll_data.p_translate.x
	sp4C.y = coll_data.p_translate.y + map_coll.top
	sp40.x = coll_data.p_translate.x + map_coll.width
	sp40.y = coll_data.p_translate.y + map_coll.center

	r = Mpcollision.mpCollisionCheckLWallLineCollisionSame(sp4C, sp40, Vector3.ZERO, test_line_id)
	test_line_id = r.stand_line_id

	if (r.ret != FALSE) and (test_line_id != floor_line_id):
		mpProcessSetMultiWallLineID(test_line_id)

		is_collide_lwall = TRUE
	if is_collide_lwall != FALSE:
		coll_data.mask_curr |= MAP_FLAG_LWALL
	return is_collide_lwall

## Shared body of mpProcessRunLWallCollision / mpProcessRunLWallCollisionAdjNew (identical C loops)
## up to mpProcessGetLastWallCollideStats. Returns last_wall_x.
static func _mpProcessRunLWallCollisionLoop(coll_data: MPCollData) -> float:
	var map_coll: MPObjectColl = coll_data.map_coll
	var wall_pos := Vector3.ZERO
	var wall_angle := Vector3.ZERO
	var vertex_pos := Vector3.ZERO
	var vertex_count: int
	var wall_flags: int = 0
	var wall_line_id: int
	var last_wall_x: float = 0.0
	var r: Dictionary
	var stats: Dictionary

	mpProcessSetLastWallCollideRight()

	for i in range(sMPProcessMultiWallCollidesNum):
		wall_line_id = sMPProcessMultiWallCollideLineIDs[i]

		wall_pos = Mpcollision.mpCollisionGetLWallEdgeU(wall_line_id)

		if wall_pos.y < (coll_data.p_translate.y + map_coll.bottom):
			if wall_pos.x < sMPProcessLastWallCollidePosition:
				r = Mpcollision.mpCollisionGetLRCommonLWall(wall_line_id, wall_pos, 0.0, wall_flags, wall_angle)
				wall_flags = r.flags
				wall_angle = r.angle

				if r.ret != FALSE:
					mpProcessSetLastWallCollideStats(wall_pos.x, wall_line_id, wall_flags, wall_angle)
		else:
			wall_pos = Mpcollision.mpCollisionGetLWallEdgeD(wall_line_id)

			if (coll_data.p_translate.y + map_coll.top) < wall_pos.y:
				if wall_pos.x < sMPProcessLastWallCollidePosition:
					r = Mpcollision.mpCollisionGetLRCommonLWall(wall_line_id, wall_pos, 0.0, wall_flags, wall_angle)
					wall_flags = r.flags
					wall_angle = r.angle

					if r.ret != FALSE:
						mpProcessSetLastWallCollideStats(wall_pos.x, wall_line_id, wall_flags, wall_angle)
			else:
				wall_pos.x = coll_data.p_translate.x
				wall_pos.y = coll_data.p_translate.y + map_coll.bottom

				r = Mpcollision.mpCollisionGetLRCommonLWall(wall_line_id, wall_pos, last_wall_x, wall_flags, wall_angle)
				last_wall_x = r.dist
				wall_flags = r.flags
				wall_angle = r.angle

				if r.ret != FALSE:
					if (coll_data.p_translate.x + last_wall_x) < sMPProcessLastWallCollidePosition:
						mpProcessSetLastWallCollideStats((coll_data.p_translate.x + last_wall_x), wall_line_id, wall_flags, wall_angle)
				wall_pos.x = coll_data.p_translate.x + map_coll.width
				wall_pos.y = coll_data.p_translate.y + map_coll.center

				r = Mpcollision.mpCollisionGetLRCommonLWall(wall_line_id, wall_pos, last_wall_x, wall_flags, wall_angle)
				last_wall_x = r.dist
				wall_flags = r.flags
				wall_angle = r.angle

				if r.ret != FALSE:
					if (coll_data.p_translate.x + last_wall_x) < sMPProcessLastWallCollidePosition:
						mpProcessSetLastWallCollideStats((coll_data.p_translate.x + last_wall_x), wall_line_id, wall_flags, wall_angle)
				wall_pos.x = coll_data.p_translate.x
				wall_pos.y = coll_data.p_translate.y + map_coll.top

				r = Mpcollision.mpCollisionGetLRCommonLWall(wall_line_id, wall_pos, last_wall_x, wall_flags, wall_angle)
				last_wall_x = r.dist
				wall_flags = r.flags
				wall_angle = r.angle

				if r.ret != FALSE:
					if (coll_data.p_translate.x + last_wall_x) < sMPProcessLastWallCollidePosition:
						mpProcessSetLastWallCollideStats((coll_data.p_translate.x + last_wall_x), wall_line_id, wall_flags, wall_angle)
				vertex_count = Mpcollision.mpCollisionGetVertexCountLineID(wall_line_id)

				for j in range(vertex_count):
					var is_next: bool = false

					vertex_pos = Mpcollision.mpCollisionGetVertexPositionID(wall_line_id, j)

					if ((coll_data.p_translate.y + map_coll.bottom) <= vertex_pos.y) and (vertex_pos.y <= (coll_data.p_translate.y + map_coll.center)):
						last_wall_x = vertex_pos.x - (((vertex_pos.y - (coll_data.p_translate.y + map_coll.bottom)) * map_coll.width) / (map_coll.center - map_coll.bottom))

						is_next = true # goto next;
					elif ((coll_data.p_translate.y + map_coll.center) <= vertex_pos.y) and (vertex_pos.y <= (coll_data.p_translate.y + map_coll.top)):
						last_wall_x = vertex_pos.x - ((((coll_data.p_translate.y + map_coll.top) - vertex_pos.y) * map_coll.width) / (map_coll.top - map_coll.center))

						is_next = true
					if is_next: # next:
						if last_wall_x < sMPProcessLastWallCollidePosition:
							r = Mpcollision.mpCollisionGetLRCommonLWall(wall_line_id, vertex_pos, 0.0, wall_flags, wall_angle)
							wall_flags = r.flags
							wall_angle = r.angle

							if r.ret != FALSE:
								mpProcessSetLastWallCollideStats(last_wall_x, wall_line_id, wall_flags, wall_angle)
		continue
	stats = mpProcessGetLastWallCollideStats()
	last_wall_x = stats.pos
	coll_data.lwall_line_id = stats.line_id
	coll_data.lwall_flags = stats.flags
	coll_data.lwall_angle = stats.angle

	return last_wall_x

## 0x800DA658
static func mpProcessRunLWallCollision(coll_data: MPCollData) -> void:
	var last_wall_x: float = _mpProcessRunLWallCollisionLoop(coll_data)

	if coll_data.p_translate.x > last_wall_x:
		coll_data.p_translate.x = last_wall_x

## 0x800DAAA8
static func mpProcessCheckTestRWallCollision(coll_data: MPCollData) -> int:
	var map_coll: MPObjectColl = coll_data.map_coll
	var p_map_coll: MPObjectColl = coll_data.p_map_coll
	var sp4C := Vector3.ZERO
	var sp40 := Vector3.ZERO
	var is_collide_rwall: int = FALSE
	var test_line_id: int = 0
	var floor_line_id: int
	var wall_collide: int
	var r: Dictionary

	mpProcessResetMultiWallCount()

	floor_line_id = Mpcollision.mpCollisionGetEdgeUnderRLineID(coll_data.floor_line_id) if (Mpcollision.mpCollisionCheckExistLineID(coll_data.floor_line_id) != FALSE) else -1

	sp4C.x = coll_data.pos_prev.x - p_map_coll.width
	sp4C.y = coll_data.pos_prev.y + p_map_coll.center
	sp40.x = coll_data.p_translate.x - map_coll.width
	sp40.y = coll_data.p_translate.y + map_coll.center

	r = Mpcollision.mpCollisionCheckRWallLineCollisionDiff(sp4C, sp40, Vector3.ZERO, test_line_id) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckRWallLineCollisionSame(sp4C, sp40, Vector3.ZERO, test_line_id)
	wall_collide = r.ret
	test_line_id = r.stand_line_id

	if (wall_collide != FALSE) and (test_line_id != floor_line_id):
		mpProcessSetMultiWallLineID(test_line_id)

		is_collide_rwall = TRUE
	sp4C.x = coll_data.pos_prev.x
	sp4C.y = coll_data.pos_prev.y + p_map_coll.bottom
	sp40.x = coll_data.p_translate.x
	sp40.y = coll_data.p_translate.y + map_coll.bottom

	r = Mpcollision.mpCollisionCheckRWallLineCollisionDiff(sp4C, sp40, Vector3.ZERO, test_line_id) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckRWallLineCollisionSame(sp4C, sp40, Vector3.ZERO, test_line_id)
	wall_collide = r.ret
	test_line_id = r.stand_line_id

	if (wall_collide != FALSE) and (test_line_id != floor_line_id):
		mpProcessSetMultiWallLineID(test_line_id)

		is_collide_rwall = TRUE
	sp4C.x = coll_data.pos_prev.x
	sp4C.y = coll_data.pos_prev.y + p_map_coll.top
	sp40.x = coll_data.p_translate.x
	sp40.y = coll_data.p_translate.y + map_coll.top

	r = Mpcollision.mpCollisionCheckRWallLineCollisionDiff(sp4C, sp40, Vector3.ZERO, test_line_id) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckRWallLineCollisionSame(sp4C, sp40, Vector3.ZERO, test_line_id)
	wall_collide = r.ret
	test_line_id = r.stand_line_id

	if (wall_collide != FALSE) and (test_line_id != floor_line_id):
		mpProcessSetMultiWallLineID(test_line_id)

		is_collide_rwall = TRUE
	sp4C.x = coll_data.p_translate.x
	sp4C.y = coll_data.p_translate.y + map_coll.bottom
	sp40.x = coll_data.p_translate.x - map_coll.width
	sp40.y = coll_data.p_translate.y + map_coll.center

	r = Mpcollision.mpCollisionCheckRWallLineCollisionSame(sp4C, sp40, Vector3.ZERO, test_line_id)
	test_line_id = r.stand_line_id

	if (r.ret != FALSE) and (test_line_id != floor_line_id):
		mpProcessSetMultiWallLineID(test_line_id)

		is_collide_rwall = TRUE
	sp4C.x = coll_data.p_translate.x
	sp4C.y = coll_data.p_translate.y + map_coll.top
	sp40.x = coll_data.p_translate.x - map_coll.width
	sp40.y = coll_data.p_translate.y + map_coll.center

	r = Mpcollision.mpCollisionCheckRWallLineCollisionSame(sp4C, sp40, Vector3.ZERO, test_line_id)
	test_line_id = r.stand_line_id

	if (r.ret != FALSE) and (test_line_id != floor_line_id):
		mpProcessSetMultiWallLineID(test_line_id)

		is_collide_rwall = TRUE
	if is_collide_rwall != FALSE:
		coll_data.mask_curr |= MAP_FLAG_RWALL
	return is_collide_rwall

## Shared body of mpProcessRunRWallCollision / mpProcessRunRWallCollisionAdjNew (identical C loops)
## up to mpProcessGetLastWallCollideStats. Returns last_wall_x.
static func _mpProcessRunRWallCollisionLoop(coll_data: MPCollData) -> float:
	var map_coll: MPObjectColl = coll_data.map_coll
	var wall_pos := Vector3.ZERO
	var wall_angle := Vector3.ZERO
	var vertex_pos := Vector3.ZERO
	var vertex_count: int
	var wall_flags: int = 0
	var wall_line_id: int
	var last_wall_x: float = 0.0
	var r: Dictionary
	var stats: Dictionary

	mpProcessSetLastWallCollideLeft()

	for i in range(sMPProcessMultiWallCollidesNum):
		wall_line_id = sMPProcessMultiWallCollideLineIDs[i]

		wall_pos = Mpcollision.mpCollisionGetRWallEdgeU(wall_line_id)

		if wall_pos.y < (coll_data.p_translate.y + map_coll.bottom):
			if sMPProcessLastWallCollidePosition < wall_pos.x:
				r = Mpcollision.mpCollisionGetLRCommonRWall(wall_line_id, wall_pos, 0.0, wall_flags, wall_angle)
				wall_flags = r.flags
				wall_angle = r.angle

				if r.ret != FALSE:
					mpProcessSetLastWallCollideStats(wall_pos.x, wall_line_id, wall_flags, wall_angle)
		else:
			wall_pos = Mpcollision.mpCollisionGetRWallEdgeD(wall_line_id)

			if (coll_data.p_translate.y + map_coll.top) < wall_pos.y:
				if sMPProcessLastWallCollidePosition < wall_pos.x:
					r = Mpcollision.mpCollisionGetLRCommonRWall(wall_line_id, wall_pos, 0.0, wall_flags, wall_angle)
					wall_flags = r.flags
					wall_angle = r.angle

					if r.ret != FALSE:
						mpProcessSetLastWallCollideStats(wall_pos.x, wall_line_id, wall_flags, wall_angle)
			else:
				wall_pos.x = coll_data.p_translate.x
				wall_pos.y = coll_data.p_translate.y + map_coll.bottom

				r = Mpcollision.mpCollisionGetLRCommonRWall(wall_line_id, wall_pos, last_wall_x, wall_flags, wall_angle)
				last_wall_x = r.dist
				wall_flags = r.flags
				wall_angle = r.angle

				if r.ret != FALSE:
					if (coll_data.p_translate.x + last_wall_x) > sMPProcessLastWallCollidePosition:
						mpProcessSetLastWallCollideStats((coll_data.p_translate.x + last_wall_x), wall_line_id, wall_flags, wall_angle)
				wall_pos.x = coll_data.p_translate.x - map_coll.width
				wall_pos.y = coll_data.p_translate.y + map_coll.center

				r = Mpcollision.mpCollisionGetLRCommonRWall(wall_line_id, wall_pos, last_wall_x, wall_flags, wall_angle)
				last_wall_x = r.dist
				wall_flags = r.flags
				wall_angle = r.angle

				if r.ret != FALSE:
					if (coll_data.p_translate.x + last_wall_x) > sMPProcessLastWallCollidePosition:
						mpProcessSetLastWallCollideStats((coll_data.p_translate.x + last_wall_x), wall_line_id, wall_flags, wall_angle)
				wall_pos.x = coll_data.p_translate.x
				wall_pos.y = coll_data.p_translate.y + map_coll.top

				r = Mpcollision.mpCollisionGetLRCommonRWall(wall_line_id, wall_pos, last_wall_x, wall_flags, wall_angle)
				last_wall_x = r.dist
				wall_flags = r.flags
				wall_angle = r.angle

				if r.ret != FALSE:
					if (coll_data.p_translate.x + last_wall_x) > sMPProcessLastWallCollidePosition:
						mpProcessSetLastWallCollideStats((coll_data.p_translate.x + last_wall_x), wall_line_id, wall_flags, wall_angle)
				vertex_count = Mpcollision.mpCollisionGetVertexCountLineID(wall_line_id)

				for j in range(vertex_count):
					var is_next: bool = false

					vertex_pos = Mpcollision.mpCollisionGetVertexPositionID(wall_line_id, j)

					if ((coll_data.p_translate.y + map_coll.bottom) <= vertex_pos.y) and (vertex_pos.y <= (coll_data.p_translate.y + map_coll.center)):
						last_wall_x = vertex_pos.x + (((vertex_pos.y - (coll_data.p_translate.y + map_coll.bottom)) * map_coll.width) / (map_coll.center - map_coll.bottom))

						is_next = true # goto next;
					elif ((coll_data.p_translate.y + map_coll.center) <= vertex_pos.y) and (vertex_pos.y <= (coll_data.p_translate.y + map_coll.top)):
						last_wall_x = vertex_pos.x + ((((coll_data.p_translate.y + map_coll.top) - vertex_pos.y) * map_coll.width) / (map_coll.top - map_coll.center))

						is_next = true
					if is_next: # next:
						if sMPProcessLastWallCollidePosition < last_wall_x:
							r = Mpcollision.mpCollisionGetLRCommonRWall(wall_line_id, vertex_pos, 0.0, wall_flags, wall_angle)
							wall_flags = r.flags
							wall_angle = r.angle

							if r.ret != FALSE:
								mpProcessSetLastWallCollideStats(last_wall_x, wall_line_id, wall_flags, wall_angle)
		continue
	stats = mpProcessGetLastWallCollideStats()
	last_wall_x = stats.pos
	coll_data.rwall_line_id = stats.line_id
	coll_data.rwall_flags = stats.flags
	coll_data.rwall_angle = stats.angle

	return last_wall_x

## 0x800DAE6C
static func mpProcessRunRWallCollision(coll_data: MPCollData) -> void:
	var last_wall_x: float = _mpProcessRunRWallCollisionLoop(coll_data)

	if coll_data.p_translate.x < last_wall_x:
		coll_data.p_translate.x = last_wall_x

## 0x800DB2BC
static func mpProcessCheckTestFloorCollisionNew(coll_data: MPCollData) -> int:
	var wall_line_id: int
	var object_pos := Vector3.ZERO
	var is_wall_edge: int
	var floor_dist: float
	var r: Dictionary

	coll_data.mask_stat &= ~MAP_FLAG_FLOOR

	object_pos.x = coll_data.p_translate.x
	object_pos.y = coll_data.p_translate.y + coll_data.map_coll.bottom

	if Mpcollision.mpCollisionCheckExistLineID(coll_data.floor_line_id) == FALSE:
		mpProcessSetCollProjectFloorID(coll_data)

		return FALSE
	r = Mpcollision.mpCollisionGetFCCommonFloor(coll_data.floor_line_id, object_pos, 0.0, coll_data.floor_flags, coll_data.floor_angle)
	coll_data.floor_flags = r.flags
	coll_data.floor_angle = r.angle

	if r.ret != FALSE:
		floor_dist = r.dist

		coll_data.p_translate.y += floor_dist

		coll_data.floor_dist = 0.0
		coll_data.mask_stat |= MAP_FLAG_FLOOR

		return TRUE
	is_wall_edge = FALSE

	object_pos = Mpcollision.mpCollisionGetFloorEdgeL(coll_data.floor_line_id)

	if coll_data.p_translate.x <= object_pos.x:
		wall_line_id = Mpcollision.mpCollisionGetEdgeUnderLLineID(coll_data.floor_line_id)

		if (wall_line_id != -1) and (Mpcollision.mpCollisionGetLineTypeID(wall_line_id) == nMPLineKindRWall):
			is_wall_edge = TRUE
	else:
		object_pos = Mpcollision.mpCollisionGetFloorEdgeR(coll_data.floor_line_id)

		wall_line_id = Mpcollision.mpCollisionGetEdgeUnderRLineID(coll_data.floor_line_id)

		if (wall_line_id != -1) and (Mpcollision.mpCollisionGetLineTypeID(wall_line_id) == nMPLineKindLWall):
			is_wall_edge = TRUE
	coll_data.p_translate.y = object_pos.y - coll_data.map_coll.bottom

	if is_wall_edge != FALSE:
		coll_data.p_translate.x = object_pos.x

		r = Mpcollision.mpCollisionGetFCCommonFloor(coll_data.floor_line_id, object_pos, 0.0, coll_data.floor_flags, coll_data.floor_angle)
		coll_data.floor_flags = r.flags
		coll_data.floor_angle = r.angle

		coll_data.mask_stat |= MAP_FLAG_FLOOR
		coll_data.floor_dist = 0.0

		return TRUE
	mpProcessSetCollProjectFloorID(coll_data)

	return FALSE

## 0x800DB474
static func mpProcessCheckTestFloorCollision(coll_data: MPCollData, line_id: int) -> int:
	var p_map_coll: MPObjectColl = coll_data.p_map_coll
	var map_coll: MPObjectColl = coll_data.map_coll
	var is_collide_floor: int
	var sp4C := Vector3.ZERO
	var sp40 := Vector3.ZERO
	var floor_line_id: int
	var floor_flags: int
	var floor_angle: Vector3
	var r: Dictionary

	sp4C.x = coll_data.pos_prev.x
	sp4C.y = coll_data.pos_prev.y + p_map_coll.bottom
	sp40.x = coll_data.p_translate.x
	sp40.y = coll_data.p_translate.y + map_coll.bottom

	r = Mpcollision.mpCollisionCheckFloorLineCollisionDiff(sp4C, sp40, coll_data.line_coll_dist) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckFloorLineCollisionSame(sp4C, sp40, coll_data.line_coll_dist)
	is_collide_floor = r.ret
	coll_data.line_coll_dist = r.ga_last
	floor_line_id = r.stand_line_id
	floor_flags = r.stand_coll_flags
	floor_angle = r.angle

	if (is_collide_floor != FALSE) and (floor_line_id != line_id):
		coll_data.mask_curr |= MAP_FLAG_FLOOR
		coll_data.floor_line_id = floor_line_id
		coll_data.floor_flags = floor_flags
		coll_data.floor_angle = floor_angle

		return TRUE
	return FALSE

## 0x800DB590
static func mpProcessCheckTestLCliffCollision(coll_data: MPCollData) -> int:
	var cliffcatch_coll: Vector2 = coll_data.cliffcatch_coll
	var sp48 := Vector3.ZERO
	var object_pos := Vector3.ZERO
	var floor_flags: int = 0
	var is_collide_floor: int
	var r: Dictionary

	if coll_data.p_lr != +1:
		return FALSE

	sp48.x = coll_data.pos_prev.x + cliffcatch_coll.x
	sp48.y = coll_data.pos_prev.y + cliffcatch_coll.y
	object_pos.x = coll_data.p_translate.x + cliffcatch_coll.x
	object_pos.y = coll_data.p_translate.y + cliffcatch_coll.y

	r = Mpcollision.mpCollisionCheckFloorLineCollisionDiff(sp48, object_pos, coll_data.line_coll_dist, coll_data.cliff_id, floor_flags) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckFloorLineCollisionSame(sp48, object_pos, coll_data.line_coll_dist, coll_data.cliff_id, floor_flags)
	is_collide_floor = r.ret
	coll_data.line_coll_dist = r.ga_last
	coll_data.cliff_id = r.stand_line_id
	floor_flags = r.stand_coll_flags

	if (is_collide_floor != FALSE) and (floor_flags & MAP_VERTEX_COLL_CLIFF) and ((floor_flags & MAP_VERTEX_MAT_MASK) != nMPMaterial4):
		object_pos = Mpcollision.mpCollisionGetFloorEdgeL(coll_data.cliff_id)

		if (coll_data.line_coll_dist.x - object_pos.x) < 800.0:
			coll_data.mask_curr |= MAP_FLAG_LCLIFF
			coll_data.mask_stat |= MAP_FLAG_LCLIFF

			return TRUE
	return FALSE

## 0x800DB6F0
static func mpProcessCheckTestRCliffCollision(coll_data: MPCollData) -> int:
	var cliffcatch_coll: Vector2 = coll_data.cliffcatch_coll
	var sp48 := Vector3.ZERO
	var object_pos := Vector3.ZERO
	var floor_flags: int = 0
	var is_collide_floor: int
	var r: Dictionary

	if coll_data.p_lr != -1:
		return FALSE

	sp48.x = coll_data.pos_prev.x - cliffcatch_coll.x
	sp48.y = coll_data.pos_prev.y + cliffcatch_coll.y
	object_pos.x = coll_data.p_translate.x - cliffcatch_coll.x
	object_pos.y = coll_data.p_translate.y + cliffcatch_coll.y

	r = Mpcollision.mpCollisionCheckFloorLineCollisionDiff(sp48, object_pos, coll_data.line_coll_dist, coll_data.cliff_id, floor_flags) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckFloorLineCollisionSame(sp48, object_pos, coll_data.line_coll_dist, coll_data.cliff_id, floor_flags)
	is_collide_floor = r.ret
	coll_data.line_coll_dist = r.ga_last
	coll_data.cliff_id = r.stand_line_id
	floor_flags = r.stand_coll_flags

	if (is_collide_floor != FALSE) and (floor_flags & MAP_VERTEX_COLL_CLIFF):
		object_pos = Mpcollision.mpCollisionGetFloorEdgeR(coll_data.cliff_id)

		if (object_pos.x - coll_data.line_coll_dist.x) < 800.0:
			coll_data.mask_curr |= MAP_FLAG_RCLIFF
			coll_data.mask_stat |= MAP_FLAG_RCLIFF

			return TRUE
	return FALSE

## 0x800DB838
static func mpProcessCheckTestLWallCollisionAdjNew(coll_data: MPCollData) -> int:
	var map_coll: MPObjectColl = coll_data.map_coll
	var p_map_coll: MPObjectColl = coll_data.p_map_coll
	var sp54 := Vector3.ZERO
	var sp48 := Vector3.ZERO
	var is_collide_lwall: int
	var test_line_id: int = 0
	var ud_line_id: int = 0
	var edge_line_id: int
	var floor_flags: int = 0
	var line_collide: int
	var r: Dictionary

	is_collide_lwall = FALSE

	coll_data.mask_unk &= ~MAP_FLAG_LWALL
	coll_data.mask_stat &= ~MAP_FLAG_LWALL

	mpProcessResetMultiWallCount()

	sp54.x = coll_data.pos_prev.x + p_map_coll.width
	sp54.y = coll_data.pos_prev.y + p_map_coll.center
	sp48.x = coll_data.p_translate.x + map_coll.width
	sp48.y = coll_data.p_translate.y + map_coll.center

	r = Mpcollision.mpCollisionCheckLWallLineCollisionDiff(sp54, sp48, Vector3.ZERO, test_line_id) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckLWallLineCollisionSame(sp54, sp48, Vector3.ZERO, test_line_id)
	line_collide = r.ret
	test_line_id = r.stand_line_id

	if line_collide != FALSE:
		mpProcessSetMultiWallLineID(test_line_id)

		is_collide_lwall = TRUE
	sp54.x = coll_data.pos_prev.x
	sp54.y = coll_data.pos_prev.y + p_map_coll.bottom
	sp48.x = coll_data.p_translate.x
	sp48.y = coll_data.p_translate.y + map_coll.bottom

	r = Mpcollision.mpCollisionCheckLWallLineCollisionDiff(sp54, sp48, Vector3.ZERO, test_line_id) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckLWallLineCollisionSame(sp54, sp48, Vector3.ZERO, test_line_id)
	line_collide = r.ret
	test_line_id = r.stand_line_id

	if line_collide != FALSE:
		mpProcessSetMultiWallLineID(test_line_id)

		is_collide_lwall = TRUE
	sp54.x = coll_data.pos_prev.x
	sp54.y = coll_data.pos_prev.y + p_map_coll.top
	sp48.x = coll_data.p_translate.x
	sp48.y = coll_data.p_translate.y + map_coll.top

	r = Mpcollision.mpCollisionCheckLWallLineCollisionDiff(sp54, sp48, Vector3.ZERO, test_line_id) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckLWallLineCollisionSame(sp54, sp48, Vector3.ZERO, test_line_id)
	line_collide = r.ret
	test_line_id = r.stand_line_id

	if line_collide != FALSE:
		mpProcessSetMultiWallLineID(test_line_id)

		is_collide_lwall = TRUE
	sp54.x = coll_data.p_translate.x
	sp54.y = coll_data.p_translate.y + map_coll.bottom
	sp48.x = coll_data.p_translate.x + map_coll.width
	sp48.y = coll_data.p_translate.y + map_coll.center

	r = Mpcollision.mpCollisionCheckLWallLineCollisionSame(sp54, sp48, Vector3.ZERO, test_line_id)
	test_line_id = r.stand_line_id

	if r.ret != FALSE:
		mpProcessSetMultiWallLineID(test_line_id)

		is_collide_lwall = TRUE
	sp54.x = coll_data.p_translate.x
	sp54.y = coll_data.p_translate.y + map_coll.top
	sp48.x = coll_data.p_translate.x + map_coll.width
	sp48.y = coll_data.p_translate.y + map_coll.center

	r = Mpcollision.mpCollisionCheckLWallLineCollisionSame(sp54, sp48, Vector3.ZERO, test_line_id)
	test_line_id = r.stand_line_id

	if r.ret != FALSE:
		mpProcessSetMultiWallLineID(test_line_id)

		is_collide_lwall = TRUE
	sp54.x = coll_data.pos_prev.x + p_map_coll.width
	sp54.y = coll_data.pos_prev.y + p_map_coll.center
	sp48.x = coll_data.p_translate.x + map_coll.width
	sp48.y = coll_data.p_translate.y + map_coll.center

	r = Mpcollision.mpCollisionCheckCeilLineCollisionDiff(sp54, sp48, Vector3.ZERO, test_line_id) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckCeilLineCollisionSame(sp54, sp48, Vector3.ZERO, test_line_id)
	line_collide = r.ret
	test_line_id = r.stand_line_id

	if line_collide != FALSE:
		edge_line_id = Mpcollision.mpCollisionGetEdgeUpperLLineID(test_line_id)

		if edge_line_id != -1:
			if Mpcollision.mpCollisionGetLineTypeID(edge_line_id) == nMPLineKindLWall:
				sp54.x = coll_data.pos_prev.x
				sp54.y = coll_data.pos_prev.y + p_map_coll.top
				sp48.x = coll_data.p_translate.x
				sp48.y = coll_data.p_translate.y + map_coll.top

				r = Mpcollision.mpCollisionCheckCeilLineCollisionDiff(sp54, sp48, Vector3.ZERO, ud_line_id) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckCeilLineCollisionSame(sp54, sp48, Vector3.ZERO, ud_line_id)
				line_collide = r.ret
				ud_line_id = r.stand_line_id

				if (line_collide == FALSE) or (test_line_id != ud_line_id):
					sp54.x = coll_data.p_translate.x
					sp54.y = coll_data.p_translate.y + map_coll.top
					sp48.x = coll_data.p_translate.x + map_coll.width
					sp48.y = coll_data.p_translate.y + map_coll.center

					r = Mpcollision.mpCollisionCheckCeilLineCollisionSame(sp54, sp48, Vector3.ZERO, ud_line_id)
					ud_line_id = r.stand_line_id

					if (r.ret == FALSE) or (test_line_id != ud_line_id):
						mpProcessSetMultiWallLineID(edge_line_id)

						is_collide_lwall = TRUE
	sp54.x = coll_data.pos_prev.x + p_map_coll.width
	sp54.y = coll_data.pos_prev.y + p_map_coll.center
	sp48.x = coll_data.p_translate.x + map_coll.width
	sp48.y = coll_data.p_translate.y + map_coll.center

	r = Mpcollision.mpCollisionCheckFloorLineCollisionDiff(sp54, sp48, Vector3.ZERO, test_line_id, floor_flags) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckFloorLineCollisionSame(sp54, sp48, Vector3.ZERO, test_line_id, floor_flags)
	line_collide = r.ret
	test_line_id = r.stand_line_id
	floor_flags = r.stand_coll_flags

	if (line_collide != FALSE) and not (floor_flags & MAP_VERTEX_COLL_PASS): # 0x4000
		edge_line_id = Mpcollision.mpCollisionGetEdgeUnderLLineID(test_line_id)

		if edge_line_id != -1:
			if Mpcollision.mpCollisionGetLineTypeID(edge_line_id) == nMPLineKindLWall:
				sp54.x = coll_data.pos_prev.x
				sp54.y = coll_data.pos_prev.y + p_map_coll.bottom
				sp48.x = coll_data.p_translate.x
				sp48.y = coll_data.p_translate.y + map_coll.bottom

				r = Mpcollision.mpCollisionCheckFloorLineCollisionDiff(sp54, sp48, Vector3.ZERO, ud_line_id) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckFloorLineCollisionSame(sp54, sp48, Vector3.ZERO, ud_line_id)
				line_collide = r.ret
				ud_line_id = r.stand_line_id

				if (line_collide == FALSE) or (test_line_id != ud_line_id):
					sp54.x = coll_data.p_translate.x
					sp54.y = coll_data.p_translate.y + map_coll.bottom
					sp48.x = coll_data.p_translate.x + map_coll.width
					sp48.y = coll_data.p_translate.y + map_coll.center

					r = Mpcollision.mpCollisionCheckFloorLineCollisionSame(sp54, sp48, Vector3.ZERO, ud_line_id)
					ud_line_id = r.stand_line_id

					if (r.ret == FALSE) or (test_line_id != ud_line_id):
						mpProcessSetMultiWallLineID(edge_line_id)

						is_collide_lwall = TRUE
	if is_collide_lwall != FALSE:
		coll_data.mask_curr |= MAP_FLAG_LWALL
	return is_collide_lwall

## 0x800DBF58
static func mpProcessRunLWallCollisionAdjNew(coll_data: MPCollData) -> void:
	var last_wall_x: float = _mpProcessRunLWallCollisionLoop(coll_data)

	if coll_data.p_translate.x > last_wall_x:
		coll_data.p_translate.x = last_wall_x

		coll_data.mask_stat |= MAP_FLAG_LWALL
	coll_data.mask_unk |= MAP_FLAG_LWALL

## 0x800DC3C8
static func mpProcessCheckTestRWallCollisionAdjNew(coll_data: MPCollData) -> int:
	var map_coll: MPObjectColl = coll_data.map_coll
	var p_map_coll: MPObjectColl = coll_data.p_map_coll
	var sp54 := Vector3.ZERO
	var sp48 := Vector3.ZERO
	var is_collide_rwall: int
	var test_line_id: int = 0
	var ud_line_id: int = 0
	var edge_line_id: int
	var floor_flags: int = 0
	var line_collide: int
	var r: Dictionary

	is_collide_rwall = FALSE

	coll_data.mask_unk &= ~MAP_FLAG_RWALL
	coll_data.mask_stat &= ~MAP_FLAG_RWALL

	mpProcessResetMultiWallCount()

	sp54.x = coll_data.pos_prev.x - p_map_coll.width
	sp54.y = coll_data.pos_prev.y + p_map_coll.center
	sp48.x = coll_data.p_translate.x - map_coll.width
	sp48.y = coll_data.p_translate.y + map_coll.center

	r = Mpcollision.mpCollisionCheckRWallLineCollisionDiff(sp54, sp48, Vector3.ZERO, test_line_id) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckRWallLineCollisionSame(sp54, sp48, Vector3.ZERO, test_line_id)
	line_collide = r.ret
	test_line_id = r.stand_line_id

	if line_collide != FALSE:
		mpProcessSetMultiWallLineID(test_line_id)

		is_collide_rwall = TRUE
	sp54.x = coll_data.pos_prev.x
	sp54.y = coll_data.pos_prev.y + p_map_coll.bottom
	sp48.x = coll_data.p_translate.x
	sp48.y = coll_data.p_translate.y + map_coll.bottom

	r = Mpcollision.mpCollisionCheckRWallLineCollisionDiff(sp54, sp48, Vector3.ZERO, test_line_id) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckRWallLineCollisionSame(sp54, sp48, Vector3.ZERO, test_line_id)
	line_collide = r.ret
	test_line_id = r.stand_line_id

	if line_collide != FALSE:
		mpProcessSetMultiWallLineID(test_line_id)

		is_collide_rwall = TRUE
	sp54.x = coll_data.pos_prev.x
	sp54.y = coll_data.pos_prev.y + p_map_coll.top
	sp48.x = coll_data.p_translate.x
	sp48.y = coll_data.p_translate.y + map_coll.top

	r = Mpcollision.mpCollisionCheckRWallLineCollisionDiff(sp54, sp48, Vector3.ZERO, test_line_id) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckRWallLineCollisionSame(sp54, sp48, Vector3.ZERO, test_line_id)
	line_collide = r.ret
	test_line_id = r.stand_line_id

	if line_collide != FALSE:
		mpProcessSetMultiWallLineID(test_line_id)

		is_collide_rwall = TRUE
	sp54.x = coll_data.p_translate.x
	sp54.y = coll_data.p_translate.y + map_coll.bottom
	sp48.x = coll_data.p_translate.x - map_coll.width
	sp48.y = coll_data.p_translate.y + map_coll.center

	r = Mpcollision.mpCollisionCheckRWallLineCollisionSame(sp54, sp48, Vector3.ZERO, test_line_id)
	test_line_id = r.stand_line_id

	if r.ret != FALSE:
		mpProcessSetMultiWallLineID(test_line_id)

		is_collide_rwall = TRUE
	sp54.x = coll_data.p_translate.x
	sp54.y = coll_data.p_translate.y + map_coll.top
	sp48.x = coll_data.p_translate.x - map_coll.width
	sp48.y = coll_data.p_translate.y + map_coll.center

	r = Mpcollision.mpCollisionCheckRWallLineCollisionSame(sp54, sp48, Vector3.ZERO, test_line_id)
	test_line_id = r.stand_line_id

	if r.ret != FALSE:
		mpProcessSetMultiWallLineID(test_line_id)

		is_collide_rwall = TRUE
	sp54.x = coll_data.pos_prev.x - p_map_coll.width
	sp54.y = coll_data.pos_prev.y + p_map_coll.center
	sp48.x = coll_data.p_translate.x - map_coll.width
	sp48.y = coll_data.p_translate.y + map_coll.center

	r = Mpcollision.mpCollisionCheckCeilLineCollisionDiff(sp54, sp48, Vector3.ZERO, test_line_id) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckCeilLineCollisionSame(sp54, sp48, Vector3.ZERO, test_line_id)
	line_collide = r.ret
	test_line_id = r.stand_line_id

	if line_collide != FALSE:
		edge_line_id = Mpcollision.mpCollisionGetEdgeUpperRLineID(test_line_id)

		if edge_line_id != -1:
			if Mpcollision.mpCollisionGetLineTypeID(edge_line_id) == nMPLineKindRWall:
				sp54.x = coll_data.pos_prev.x
				sp54.y = coll_data.pos_prev.y + p_map_coll.top
				sp48.x = coll_data.p_translate.x
				sp48.y = coll_data.p_translate.y + map_coll.top

				r = Mpcollision.mpCollisionCheckCeilLineCollisionDiff(sp54, sp48, Vector3.ZERO, ud_line_id) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckCeilLineCollisionSame(sp54, sp48, Vector3.ZERO, ud_line_id)
				line_collide = r.ret
				ud_line_id = r.stand_line_id

				if (line_collide == FALSE) or (test_line_id != ud_line_id):
					sp54.x = coll_data.p_translate.x
					sp54.y = coll_data.p_translate.y + map_coll.top
					sp48.x = coll_data.p_translate.x - map_coll.width
					sp48.y = coll_data.p_translate.y + map_coll.center

					r = Mpcollision.mpCollisionCheckCeilLineCollisionSame(sp54, sp48, Vector3.ZERO, ud_line_id)
					ud_line_id = r.stand_line_id

					if (r.ret == 0) or (test_line_id != ud_line_id):
						mpProcessSetMultiWallLineID(edge_line_id)

						is_collide_rwall = TRUE
	sp54.x = coll_data.pos_prev.x - p_map_coll.width
	sp54.y = coll_data.pos_prev.y + p_map_coll.center
	sp48.x = coll_data.p_translate.x - map_coll.width
	sp48.y = coll_data.p_translate.y + map_coll.center

	r = Mpcollision.mpCollisionCheckFloorLineCollisionDiff(sp54, sp48, Vector3.ZERO, test_line_id, floor_flags) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckFloorLineCollisionSame(sp54, sp48, Vector3.ZERO, test_line_id, floor_flags)
	line_collide = r.ret
	test_line_id = r.stand_line_id
	floor_flags = r.stand_coll_flags

	if (line_collide != FALSE) and not (floor_flags & MAP_VERTEX_COLL_PASS):
		edge_line_id = Mpcollision.mpCollisionGetEdgeUnderRLineID(test_line_id)

		if edge_line_id != -1:
			if Mpcollision.mpCollisionGetLineTypeID(edge_line_id) == nMPLineKindRWall:
				sp54.x = coll_data.pos_prev.x
				sp54.y = coll_data.pos_prev.y + p_map_coll.bottom
				sp48.x = coll_data.p_translate.x
				sp48.y = coll_data.p_translate.y + map_coll.bottom

				r = Mpcollision.mpCollisionCheckFloorLineCollisionDiff(sp54, sp48, Vector3.ZERO, ud_line_id) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckFloorLineCollisionSame(sp54, sp48, Vector3.ZERO, ud_line_id)
				line_collide = r.ret
				ud_line_id = r.stand_line_id

				if (line_collide == FALSE) or (test_line_id != ud_line_id):
					sp54.x = coll_data.p_translate.x
					sp54.y = coll_data.p_translate.y + map_coll.bottom
					sp48.x = coll_data.p_translate.x - map_coll.width
					sp48.y = coll_data.p_translate.y + map_coll.center

					r = Mpcollision.mpCollisionCheckFloorLineCollisionSame(sp54, sp48, Vector3.ZERO, ud_line_id)
					ud_line_id = r.stand_line_id

					if (r.ret == FALSE) or (test_line_id != ud_line_id):
						mpProcessSetMultiWallLineID(edge_line_id)

						is_collide_rwall = TRUE
	if is_collide_rwall != FALSE:
		coll_data.mask_curr |= MAP_FLAG_RWALL
	return is_collide_rwall

## 0x800DCAE8
static func mpProcessRunRWallCollisionAdjNew(coll_data: MPCollData) -> void:
	var last_wall_x: float = _mpProcessRunRWallCollisionLoop(coll_data)

	if coll_data.p_translate.x < last_wall_x:
		coll_data.p_translate.x = last_wall_x

		coll_data.mask_stat |= MAP_FLAG_RWALL
	coll_data.mask_unk |= MAP_FLAG_RWALL

## 0x800DCF58
static func mpProcessCheckTestCeilCollisionAdjNew(coll_data: MPCollData) -> int:
	var map_coll: MPObjectColl = coll_data.map_coll
	var p_map_coll: MPObjectColl = coll_data.p_map_coll
	var sp4C := Vector3.ZERO
	var sp40 := Vector3.ZERO
	var ceil_collide: int
	var ceil_dist: float
	var line_id: int
	var r: Dictionary

	coll_data.mask_stat &= ~MAP_FLAG_CEIL

	sp4C.x = coll_data.pos_prev.x
	sp4C.y = coll_data.pos_prev.y + p_map_coll.top

	sp40.x = coll_data.p_translate.x
	sp40.y = coll_data.p_translate.y + map_coll.top

	r = Mpcollision.mpCollisionCheckCeilLineCollisionDiff(sp4C, sp40, coll_data.line_coll_dist, coll_data.ceil_line_id, coll_data.ceil_flags, coll_data.ceil_angle) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckCeilLineCollisionSame(sp4C, sp40, coll_data.line_coll_dist, coll_data.ceil_line_id, coll_data.ceil_flags, coll_data.ceil_angle)
	ceil_collide = r.ret
	coll_data.line_coll_dist = r.ga_last
	coll_data.ceil_line_id = r.stand_line_id
	coll_data.ceil_flags = r.stand_coll_flags
	coll_data.ceil_angle = r.angle

	if ceil_collide != FALSE:
		coll_data.mask_curr |= MAP_FLAG_CEIL

		return TRUE
	if coll_data.mask_unk & MAP_FLAG_LWALL:
		line_id = Mpcollision.mpCollisionGetEdgeRightULineID(coll_data.lwall_line_id)

		if (line_id != -1) and (Mpcollision.mpCollisionGetLineTypeID(line_id) == nMPLineKindCeil):
			r = Mpcollision.mpCollisionGetFCCommonCeil(line_id, sp40, 0.0, coll_data.ceil_flags, coll_data.ceil_angle)
			coll_data.ceil_flags = r.flags
			coll_data.ceil_angle = r.angle

			if r.ret != FALSE:
				ceil_dist = r.dist

				if ceil_dist < 0.0:
					coll_data.ceil_line_id = line_id
					coll_data.mask_curr |= MAP_FLAG_CEIL

					return TRUE
	elif coll_data.mask_unk & MAP_FLAG_RWALL:
		line_id = Mpcollision.mpCollisionGetEdgeLeftULineID(coll_data.rwall_line_id)

		if (line_id != -1) and (Mpcollision.mpCollisionGetLineTypeID(line_id) == nMPLineKindCeil):
			r = Mpcollision.mpCollisionGetFCCommonCeil(line_id, sp40, 0.0, coll_data.ceil_flags, coll_data.ceil_angle)
			coll_data.ceil_flags = r.flags
			coll_data.ceil_angle = r.angle

			if r.ret != FALSE:
				ceil_dist = r.dist

				if ceil_dist < 0.0:
					coll_data.ceil_line_id = line_id
					coll_data.mask_curr |= MAP_FLAG_CEIL

					return TRUE
	return FALSE

## 0x800DD160
static func mpProcessRunCeilCollisionAdjNew(coll_data: MPCollData) -> void:
	var map_coll: MPObjectColl = coll_data.map_coll
	var object_pos := Vector3.ZERO
	var line_id: int
	var is_collide_ceil: int
	var ceil_dist: float
	var r: Dictionary

	object_pos.x = coll_data.p_translate.x
	object_pos.y = coll_data.p_translate.y + map_coll.top

	r = Mpcollision.mpCollisionGetFCCommonCeil(coll_data.ceil_line_id, object_pos, 0.0, coll_data.ceil_flags, coll_data.ceil_angle)
	coll_data.ceil_flags = r.flags
	coll_data.ceil_angle = r.angle

	if r.ret != FALSE:
		ceil_dist = r.dist

		coll_data.p_translate.y += ceil_dist
		coll_data.mask_stat |= MAP_FLAG_CEIL

		return
	is_collide_ceil = FALSE

	object_pos = Mpcollision.mpCollisionGetCeilEdgeL(coll_data.ceil_line_id)

	if coll_data.p_translate.x <= object_pos.x:
		line_id = Mpcollision.mpCollisionGetEdgeUpperLLineID(coll_data.ceil_line_id)

		if (line_id != -1) and (Mpcollision.mpCollisionGetLineTypeID(line_id) == nMPLineKindRWall):
			is_collide_ceil = TRUE
	else:
		object_pos = Mpcollision.mpCollisionGetCeilEdgeR(coll_data.ceil_line_id)

		line_id = Mpcollision.mpCollisionGetEdgeUpperRLineID(coll_data.ceil_line_id)

		if (line_id != -1) and (Mpcollision.mpCollisionGetLineTypeID(line_id) == nMPLineKindLWall):
			is_collide_ceil = TRUE
	coll_data.p_translate.y = object_pos.y - map_coll.top

	if is_collide_ceil != FALSE:
		coll_data.p_translate.x = object_pos.x

		r = Mpcollision.mpCollisionGetFCCommonCeil(coll_data.ceil_line_id, object_pos, 0.0, coll_data.ceil_flags, coll_data.ceil_angle)
		coll_data.ceil_flags = r.flags
		coll_data.ceil_angle = r.angle

		coll_data.mask_stat |= MAP_FLAG_CEIL

## 0x800DD2C8
## C: sb32 mpProcessCheckTestFloorCollisionAdjNew(MPCollData *coll_data, sb32 (*proc_map)(GObj*), GObj *gobj)
## proc_map: Callable(gobj) -> sb32, or null / Callable() for NULL.
static func mpProcessCheckTestFloorCollisionAdjNew(coll_data: MPCollData, proc_map, gobj) -> int:
	var p_map_coll: MPObjectColl = coll_data.p_map_coll
	var map_coll: MPObjectColl = coll_data.map_coll
	var sp4C := Vector3.ZERO
	var sp40 := Vector3.ZERO
	var line_id: int
	var floor_dist: float
	var var_v0: int
	var r: Dictionary

	coll_data.mask_stat &= ~MAP_FLAG_FLOOR

	sp4C.x = coll_data.pos_prev.x
	sp4C.y = coll_data.pos_prev.y + p_map_coll.bottom

	sp40.x = coll_data.p_translate.x
	sp40.y = coll_data.p_translate.y + map_coll.bottom

	r = Mpcollision.mpCollisionCheckFloorLineCollisionDiff(sp4C, sp40, coll_data.line_coll_dist, coll_data.floor_line_id, coll_data.floor_flags, coll_data.floor_angle) if (coll_data.update_tic != Mpcollision.gMPCollisionUpdateTic) else Mpcollision.mpCollisionCheckFloorLineCollisionSame(sp4C, sp40, coll_data.line_coll_dist, coll_data.floor_line_id, coll_data.floor_flags, coll_data.floor_angle)
	var_v0 = r.ret
	coll_data.line_coll_dist = r.ga_last
	coll_data.floor_line_id = r.stand_line_id
	coll_data.floor_flags = r.stand_coll_flags
	coll_data.floor_angle = r.angle

	if (var_v0 != 0) and (not (coll_data.floor_flags & MAP_VERTEX_COLL_PASS) or (coll_data.floor_line_id != coll_data.ignore_line_id)) and (_is_null_proc(proc_map) or (_sb32(proc_map.call(gobj)) != FALSE)):
		coll_data.mask_curr |= MAP_FLAG_FLOOR

		return TRUE
	if coll_data.mask_unk & MAP_FLAG_LWALL:
		line_id = Mpcollision.mpCollisionGetEdgeRightDLineID(coll_data.lwall_line_id)

		if line_id != -1:
			if Mpcollision.mpCollisionGetLineTypeID(line_id) == nMPLineKindFloor:
				r = Mpcollision.mpCollisionGetFCCommonFloor(line_id, sp40, 0.0, coll_data.floor_flags, coll_data.floor_angle)
				coll_data.floor_flags = r.flags
				coll_data.floor_angle = r.angle

				if r.ret != 0:
					floor_dist = r.dist

					if floor_dist > 0.0:
						coll_data.floor_line_id = line_id

						if not (coll_data.floor_flags & MAP_VERTEX_COLL_PASS) or (coll_data.floor_line_id != coll_data.ignore_line_id):
							if _is_null_proc(proc_map) or (_sb32(proc_map.call(gobj)) != FALSE):
								coll_data.mask_curr |= MAP_FLAG_FLOOR

								return TRUE
	elif coll_data.mask_unk & MAP_FLAG_RWALL:
		line_id = Mpcollision.mpCollisionGetEdgeLeftDLineID(coll_data.rwall_line_id)

		if line_id != -1:
			if Mpcollision.mpCollisionGetLineTypeID(line_id) == nMPLineKindFloor:
				r = Mpcollision.mpCollisionGetFCCommonFloor(line_id, sp40, 0.0, coll_data.floor_flags, coll_data.floor_angle)
				coll_data.floor_flags = r.flags
				coll_data.floor_angle = r.angle

				if r.ret != 0:
					floor_dist = r.dist

					if floor_dist > 0.0:
						coll_data.floor_line_id = line_id

						if not (coll_data.floor_flags & MAP_VERTEX_COLL_PASS) or (coll_data.floor_line_id != coll_data.ignore_line_id):
							if _is_null_proc(proc_map) or (_sb32(proc_map.call(gobj)) != FALSE):
								coll_data.mask_curr |= MAP_FLAG_FLOOR

								return TRUE
	return FALSE

## 0x800DD578
static func mpProcessRunFloorCollisionAdjNewNULL(coll_data: MPCollData) -> int:
	return mpProcessCheckTestFloorCollisionAdjNew(coll_data, null, null)

## 0x800DD59C
static func mpProcessSetLandingFloor(coll_data: MPCollData) -> void:
	var map_coll: MPObjectColl = coll_data.map_coll
	var object_pos := Vector3.ZERO
	var floor_dist: float
	var r: Dictionary

	object_pos.x = coll_data.p_translate.x
	object_pos.y = coll_data.p_translate.y + map_coll.bottom

	r = Mpcollision.mpCollisionGetFCCommonFloor(coll_data.floor_line_id, object_pos, 0.0, coll_data.floor_flags, coll_data.floor_angle)
	coll_data.floor_flags = r.flags
	coll_data.floor_angle = r.angle

	if r.ret != FALSE:
		floor_dist = r.dist

		coll_data.p_translate.y += floor_dist
	else:
		object_pos = Mpcollision.mpCollisionGetFloorEdgeL(coll_data.floor_line_id)

		if object_pos.x <= coll_data.p_translate.x:
			object_pos = Mpcollision.mpCollisionGetFloorEdgeR(coll_data.floor_line_id)
		coll_data.p_translate.y = object_pos.y - map_coll.bottom
		coll_data.p_translate.x = object_pos.x

		r = Mpcollision.mpCollisionGetFCCommonFloor(coll_data.floor_line_id, object_pos, 0.0, coll_data.floor_flags, coll_data.floor_angle)
		coll_data.floor_flags = r.flags
		coll_data.floor_angle = r.angle
	coll_data.mask_stat |= MAP_FLAG_FLOOR
	coll_data.floor_dist = 0.0

## 0x800DD6A8
static func mpProcessSetCollideFloor(coll_data: MPCollData) -> void:
	var map_coll: MPObjectColl = coll_data.map_coll
	var object_pos := Vector3.ZERO
	var edge_line_id: int
	var is_collide_floor: int
	var floor_dist: float
	var r: Dictionary

	object_pos.x = coll_data.p_translate.x
	object_pos.y = coll_data.p_translate.y + map_coll.bottom

	r = Mpcollision.mpCollisionGetFCCommonFloor(coll_data.floor_line_id, object_pos, 0.0, coll_data.floor_flags, coll_data.floor_angle)
	coll_data.floor_flags = r.flags
	coll_data.floor_angle = r.angle

	if r.ret != FALSE:
		floor_dist = r.dist

		coll_data.p_translate.y += floor_dist

		coll_data.mask_stat |= MAP_FLAG_FLOOR
		coll_data.floor_dist = 0.0

		return
	is_collide_floor = FALSE

	object_pos = Mpcollision.mpCollisionGetFloorEdgeL(coll_data.floor_line_id)

	if coll_data.p_translate.x <= object_pos.x:
		edge_line_id = Mpcollision.mpCollisionGetEdgeUnderLLineID(coll_data.floor_line_id)

		if (edge_line_id != -1) and (Mpcollision.mpCollisionGetLineTypeID(edge_line_id) == nMPLineKindRWall):
			is_collide_floor = TRUE
	else:
		object_pos = Mpcollision.mpCollisionGetFloorEdgeR(coll_data.floor_line_id)

		edge_line_id = Mpcollision.mpCollisionGetEdgeUnderRLineID(coll_data.floor_line_id)

		if (edge_line_id != -1) and (Mpcollision.mpCollisionGetLineTypeID(edge_line_id) == nMPLineKindLWall):
			is_collide_floor = TRUE
	coll_data.p_translate.y = object_pos.y - map_coll.bottom

	if is_collide_floor != FALSE:
		coll_data.p_translate.x = object_pos.x

		r = Mpcollision.mpCollisionGetFCCommonFloor(coll_data.floor_line_id, object_pos, 0.0, coll_data.floor_flags, coll_data.floor_angle)
		coll_data.floor_flags = r.flags
		coll_data.floor_angle = r.angle

		coll_data.mask_stat |= MAP_FLAG_FLOOR
		coll_data.floor_dist = 0.0
