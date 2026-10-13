## Port of src/mp/mpcommon.c: the map collision procedures used by fighters (ground / air /
## ledge / pass-through / damage), plus the default collision used by items and weapons.
##
## Function pointers are Callables: proc_map arguments are Callable(fighter_gobj); the collision
## procs handed to Mpprocess.mpProcessUpdateMain are Callable(coll_data, gobj, flags) -> sb32.
class_name Mpcommon
extends Port

# // // // // // // // // // // // //
#    GLOBAL / STATIC VARIABLES
# // // // // // // // // // // // //

## 0x80130E20 - sb32 (*)(GObj*)
static var sMPCommonProcPass: Callable = Callable()

# // // // // // // // // // // // //
#        PORT HELPERS
# // // // // // // // // // // // //

## Value-returning out-parameter helpers of other modules may still be stubs returning null.
static func _port_v3(v, fallback: Vector3) -> Vector3:
	return v if (v is Vector3) else fallback

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x800DD820 - new file?
static func mpCommonCheckSetFighterCliffEdge(fighter_gobj, floor_line_id: int) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var map_coll: MPObjectColl = fp.coll_data.map_coll
	var edge_pos := Vector3.ZERO
	var sp4C := Vector3.ZERO
	var angle := Vector3.ZERO     # uninitialised in C if mpCollisionGetFCCommonFloor fails
	var flags: int = 0
	var floor_dist: float = 0.0
	var is_setground: bool = false
	var r: Dictionary

	if Mpcollision.mpCollisionCheckExistLineID(floor_line_id) == FALSE:
		return FALSE
	else:
		edge_pos = Mpcollision.mpCollisionGetFloorEdgeL(floor_line_id)

		if fp.coll_data.p_translate.x <= edge_pos.x:
			if (fp.lr == -1) and (fp.input.pl.stick_range.x > -60):
				edge_pos.x += 40.0

				r = Mpcollision.mpCollisionGetFCCommonFloor(floor_line_id, edge_pos, floor_dist, flags, angle)
				floor_dist = r.dist
				flags = r.flags
				angle = r.angle

				edge_pos.y += floor_dist
				sp4C.x = map_coll.width + edge_pos.x
				sp4C.y = (map_coll.center + edge_pos.y) - map_coll.bottom

				if Mpcollision.mpCollisionCheckLWallLineCollisionSame(edge_pos, sp4C).ret == FALSE:
					fp.lr = -1

					is_setground = true # goto setground;
		elif (fp.lr == +1) and (fp.input.pl.stick_range.x < 60):
			edge_pos = Mpcollision.mpCollisionGetFloorEdgeR(floor_line_id)

			edge_pos.x -= 40.0

			r = Mpcollision.mpCollisionGetFCCommonFloor(floor_line_id, edge_pos, floor_dist, flags, angle)
			floor_dist = r.dist
			flags = r.flags
			angle = r.angle

			edge_pos.y += floor_dist
			sp4C.x = edge_pos.x - map_coll.width
			sp4C.y = (map_coll.center + edge_pos.y) - map_coll.bottom

			if Mpcollision.mpCollisionCheckRWallLineCollisionSame(edge_pos, sp4C).ret == FALSE:
				fp.lr = +1

				is_setground = true # goto setground;
	if not is_setground:
		return FALSE

	# setground: // ???
	fp.coll_data.p_translate = edge_pos # This is what causes the infamous Dream Land teleport

	fp.coll_data.floor_line_id = floor_line_id
	fp.coll_data.floor_flags = flags
	fp.coll_data.floor_angle = angle
	fp.coll_data.floor_dist = 0.0

	fp.coll_data.mask_stat |= MAP_FLAG_FLOOREDGE

	return TRUE

## 0x800DDA6C
static func mpCommonCheckSetFighterEdge(fighter_gobj, floor_line_id: int) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var map_coll: MPObjectColl = fp.coll_data.map_coll
	var edge_pos := Vector3.ZERO
	var sp4C := Vector3.ZERO
	var sp40 := Vector3.ZERO
	var angle := Vector3.ZERO     # uninitialised in C if mpCollisionGetFCCommonFloor fails
	var flags: int = 0
	var floor_dist: float = 0.0
	var is_setground: bool = false
	var r: Dictionary

	if Mpcollision.mpCollisionCheckExistLineID(floor_line_id) == FALSE:
		return FALSE
	else:
		edge_pos = Mpcollision.mpCollisionGetFloorEdgeL(floor_line_id)

		if fp.coll_data.p_translate.x <= edge_pos.x:
			r = Mpcollision.mpCollisionGetFCCommonFloor(floor_line_id, edge_pos, floor_dist, flags, angle) # if (...);
			floor_dist = r.dist
			flags = r.flags
			angle = r.angle

			sp4C.x = edge_pos.x + 1.0
			sp4C.y = edge_pos.y + 1.0

			sp40.x = map_coll.width + edge_pos.x
			sp40.y = (map_coll.center + edge_pos.y) - map_coll.bottom

			if Mpcollision.mpCollisionCheckLWallLineCollisionSame(sp4C, sp40).ret == FALSE:
				is_setground = true # if (TRUE) goto setground;
		else:
			edge_pos = Mpcollision.mpCollisionGetFloorEdgeR(floor_line_id)

			r = Mpcollision.mpCollisionGetFCCommonFloor(floor_line_id, edge_pos, floor_dist, flags, angle) # if (...);
			floor_dist = r.dist
			flags = r.flags
			angle = r.angle

			sp4C.x = edge_pos.x - 1.0
			sp4C.y = edge_pos.y + 1.0

			sp40.x = edge_pos.x - map_coll.width
			sp40.y = (map_coll.center + edge_pos.y) - map_coll.bottom

			if Mpcollision.mpCollisionCheckRWallLineCollisionSame(sp4C, sp40).ret == FALSE:
				is_setground = true # if (TRUE) goto setground;
	if not is_setground:
		return FALSE

	# setground: // Absolutely ridiculous match
	fp.coll_data.p_translate = edge_pos

	fp.coll_data.floor_line_id = floor_line_id
	fp.coll_data.floor_flags = flags
	fp.coll_data.floor_angle = angle
	fp.coll_data.floor_dist = 0.0

	return TRUE

## 0x800DDC50
static func mpCommonRunFighterAllCollisions(coll_data: MPCollData, fighter_gobj, flags: int) -> int:
	var floor_line_id: int = coll_data.floor_line_id   # Floor collision line ID
	var is_floor: int = FALSE                          # Whether fighter is making contact with a floor collision

	if Mpprocess.mpProcessCheckTestLWallCollision(coll_data) != FALSE:
		Mpprocess.mpProcessRunLWallCollision(coll_data)

		coll_data.is_coll_end = TRUE
	if Mpprocess.mpProcessCheckTestRWallCollision(coll_data) != FALSE:
		Mpprocess.mpProcessRunRWallCollision(coll_data)

		coll_data.is_coll_end = TRUE
	if Mpprocess.mpProcessCheckTestFloorCollisionNew(coll_data) != FALSE:
		if coll_data.mask_stat & MAP_FLAG_FLOOR:
			Mpprocess.mpProcessRunFloorEdgeAdjust(coll_data)

			is_floor = TRUE
	elif flags & MAP_PROC_TYPE_CLIFFEDGE:
		mpCommonCheckSetFighterCliffEdge(fighter_gobj, floor_line_id)

		coll_data.is_coll_end = TRUE
	elif flags & MAP_PROC_TYPE_STOPEDGE:
		if mpCommonCheckSetFighterEdge(fighter_gobj, floor_line_id) != FALSE:
			is_floor = TRUE
		else:
			coll_data.is_coll_end = TRUE
	else:
		coll_data.is_coll_end = TRUE

	if Mpprocess.mpProcessCheckTestFloorCollision(coll_data, floor_line_id) != FALSE:
		Mpprocess.mpProcessSetLandingFloor(coll_data)

		if coll_data.mask_stat & MAP_FLAG_FLOOR:
			Mpprocess.mpProcessRunFloorEdgeAdjust(coll_data)

			is_floor = TRUE
		coll_data.mask_stat &= ~MAP_FLAG_FLOOREDGE
		coll_data.is_coll_end = FALSE
	return is_floor

## 0x800DDDA8
static func mpCommonCheckFighterOnFloor(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	return Mpprocess.mpProcessUpdateMain(fp.coll_data, Callable(Mpcommon, &"mpCommonRunFighterAllCollisions"), fighter_gobj, MAP_PROC_TYPE_DEFAULT)

## 0x800DDDDC
static func mpCommonProcFighterOnFloor(fighter_gobj, proc_map: Callable) -> int:
	if mpCommonCheckFighterOnFloor(fighter_gobj) == FALSE:
		proc_map.call(fighter_gobj)

		return FALSE
	return TRUE

## 0x800DDE1C
static func mpCommonCheckFighterOnCliffEdge(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	return Mpprocess.mpProcessUpdateMain(fp.coll_data, Callable(Mpcommon, &"mpCommonRunFighterAllCollisions"), fighter_gobj, MAP_PROC_TYPE_CLIFFEDGE)

## 0x800DDE50
static func mpCommonCheckFighterOnEdge(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	return Mpprocess.mpProcessUpdateMain(fp.coll_data, Callable(Mpcommon, &"mpCommonRunFighterAllCollisions"), fighter_gobj, MAP_PROC_TYPE_STOPEDGE)

## 0x800DDE84
static func mpCommonProcFighterOnEdge(fighter_gobj, proc_map: Callable) -> int:
	if mpCommonCheckFighterOnEdge(fighter_gobj) == FALSE:
		proc_map.call(fighter_gobj)

		return FALSE
	return TRUE

## 0x800DDEC4
static func mpCommonSetFighterFallOnGroundBreak(fighter_gobj) -> void:
	mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftcommonfall, &"ftCommonFallSetStatus"))

## 0x800DDEE8
static func mpCommonProcFighterOnCliffEdge(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if mpCommonCheckFighterOnCliffEdge(fighter_gobj) == FALSE:
		if fp.coll_data.mask_stat & MAP_FLAG_FLOOREDGE:
			Ftcommonottotto.ftCommonOttottoSetStatus(fighter_gobj)
		else:
			Ftcommonfall.ftCommonFallSetStatus(fighter_gobj)

## 0x800DDF44
static func mpCommonSetFighterFallOnEdgeBreak(fighter_gobj) -> void:
	if mpCommonCheckFighterOnEdge(fighter_gobj) == FALSE:
		Ftcommonfall.ftCommonFallSetStatus(fighter_gobj)

## 0x800DDF74
## C: sb32 func_ovl2_800DDF74(GObj *fighter_gobj, FTStruct *fp, FTAttributes *attr, DObj *target_joint, Vec3f *vec)
## vec is in-out: returns {"ret", "vec"}.
static func func_ovl2_800DDF74(fighter_gobj, fp, attr, target_joint, vec: Vector3) -> Dictionary:
	var vec_translate := Vector3.ZERO
	var sp4C := Vector3.ZERO
	var sp48: float
	var joint: DObj
	var tangent: float
	var ternary: float
	var translate_y: float
	var r: Dictionary

	r = Mpcollision.mpCollisionGetFCCommonFloor(fp.coll_data.floor_line_id, vec)

	if r.ret != FALSE:
		sp48 = r.dist

		translate_y = (vec.y + sp48) - DObjGetStruct(fighter_gobj).translate.y
	else:
		vec_translate = Mpcollision.mpCollisionGetFloorEdgeL(fp.coll_data.floor_line_id)

		if vec_translate.x < vec.x:
			vec_translate = Mpcollision.mpCollisionGetFloorEdgeR(fp.coll_data.floor_line_id)
		translate_y = vec_translate.y - DObjGetStruct(fighter_gobj).translate.y

	ternary = ABSF(translate_y)

	if ternary < 0.0001:
		return {"ret": FALSE, "vec": vec}

	vec.y += translate_y

	joint = DObjGetStruct(fighter_gobj)

	if vec.y < joint.translate.y:
		ternary = (-(joint.translate.x - vec.x) if (joint.translate.x < vec.x) else (joint.translate.x - vec.x))

		tangent = DObjGetStruct(fighter_gobj).translate.y - ternary * syUtilsTan(attr.unk_0x320)

		if vec.y < tangent:
			vec.y = tangent

	sp4C.z = 0
	sp4C.y = 0
	sp4C.x = 0

	sp4C = _port_v3(Gmcollision.gmCollisionGetFighterPartsWorldPosition(target_joint, sp4C), sp4C)

	if vec.y > sp4C.y - attr.unk_0x31C:
		vec.y = sp4C.y - attr.unk_0x31C
	return {"ret": TRUE, "vec": vec}

## Ftparam.func_ovl2_800EBC0C(s32 arg0, Vec3f *arg1, f32 *arg2, f32 arg3, DObj *dobj): arg1/arg2 are
## pure outputs (PORTING.md: omitted, returned as {"arg1", "arg2"}). Accepts both the convention
## signature (arg0, arg3, dobj) and the full C parameter list of the current Ftparam port.
static func _port_func_ovl2_800EBC0C(fp, arg1: Vector3, arg2: float, arg3: float, dobj) -> Dictionary:
	var proc := Callable(Ftparam, &"func_ovl2_800EBC0C")
	var r

	if proc.get_argument_count() >= 5:
		r = proc.call(fp, arg1, arg2, arg3, dobj)
	else:
		r = proc.call(fp, arg3, dobj)
	if r is Dictionary:
		return {"arg1": _port_v3(r.get("arg1"), arg1), "arg2": float(r.get("arg2", arg2))}
	return {"arg1": arg1, "arg2": arg2}

## 0x800DE150
static func mpCommonUpdateFighterSlopeContour(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr
	var joint: DObj
	var sp30 := Vector3.ZERO
	var sp2C: float = 0.0
	var r: Dictionary

	if fp.ga == nMPKineticsGround:
		if (fp.coll_data.floor_line_id != -1) and (fp.coll_data.floor_line_id != -2) and (fp.hitlag_tics <= 0):
			if fp.slope_contour & FTSLOPECONTOUR_FLAG_RFOOT:
				joint = fp.joints[attr.joint_rfoot_id]

				r = _port_func_ovl2_800EBC0C(fp, sp30, sp2C, attr.joint_rfoot_rotate, joint)
				sp30 = r.arg1
				sp2C = r.arg2

				r = func_ovl2_800DDF74(fighter_gobj, fp, attr, joint, sp30)
				sp30 = r.vec

				if r.ret != FALSE:
					sp30 = _port_v3(Gmcollision.func_ovl2_800EE018(fp.joints[attr.joint_rfoot_id], sp30), sp30)
					Ftparam.func_ovl2_800EBD08(fp.joints[attr.joint_rfoot_id], attr.joint_rfoot_rotate, sp30, sp2C)
			if fp.slope_contour & FTSLOPECONTOUR_FLAG_LFOOT:
				joint = fp.joints[attr.joint_lfoot_id]

				r = _port_func_ovl2_800EBC0C(fp, sp30, sp2C, attr.joint_lfoot_rotate, joint)
				sp30 = r.arg1
				sp2C = r.arg2

				r = func_ovl2_800DDF74(fighter_gobj, fp, attr, joint, sp30)
				sp30 = r.vec

				if r.ret != FALSE:
					sp30 = _port_v3(Gmcollision.func_ovl2_800EE018(fp.joints[attr.joint_lfoot_id], sp30), sp30)
					Ftparam.func_ovl2_800EBD08(fp.joints[attr.joint_lfoot_id], attr.joint_lfoot_rotate, sp30, sp2C)
			if fp.slope_contour & FTSLOPECONTOUR_FLAG_FULL:
				DObjGetStruct(fighter_gobj).rotate.x = (syUtilsArcTan2(fp.coll_data.floor_angle.x, fp.coll_data.floor_angle.y) * fp.lr)
	else:
		return

## 0x800DE324
static func mpCommonSetFighterProjectFloor(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpprocess.mpProcessSetCollProjectFloorID(fp.coll_data)

## 0x800DE348
static func mpCommonUpdateFighterProjectFloor(fighter_gobj) -> void:
	mpCommonSetFighterProjectFloor(fighter_gobj)

## 0x800DE368
static func mpCommonSetFighterLandingParams(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.public_knockback != 0.0:
		if fp.public_knockback >= 100.0:
			if (
				(fp.joints[nFTPartsJointTopN].translate.x < (Mpcollision.gMPCollisionBounds.current.left + 450.0)) or
				(fp.joints[nFTPartsJointTopN].translate.x > (Mpcollision.gMPCollisionBounds.current.right - 450.0))
			):
				Ftpublic.ftPublicPlayCliffReact(fighter_gobj, fp.public_knockback)
		fp.public_knockback = 0.0
	match fp.fkind:
		nFTKindMario, nFTKindMMario, nFTKindNMario:
			fp.passive_vars.mario.is_expend_tornado = FALSE

		nFTKindSamus, nFTKindNSamus:
			fp.passive_vars.samus.charge_recoil = 0
			return

		nFTKindLuigi, nFTKindNLuigi:
			fp.passive_vars.mario.is_expend_tornado = FALSE

		nFTKindCaptain, nFTKindNCaptain:
			fp.passive_vars.captain.falcon_punch_unk = FALSE

		nFTKindPurin, nFTKindNPurin:
			fp.passive_vars.purin.unk_0x0 = FALSE

## 0x800DE45C
static func mpCommonRunFighterSpecialCollisions(coll_data: MPCollData, fighter_gobj, flags: int) -> int:
	var this_fp := ftGetStruct(fighter_gobj)
	var cliffcatch_fp: Fighter
	var is_ceilstop: int = FALSE
	var is_collide: int

	if Mpprocess.mpProcessCheckTestLWallCollisionAdjNew(coll_data) != FALSE:
		Mpprocess.mpProcessRunLWallCollisionAdjNew(coll_data)
	if Mpprocess.mpProcessCheckTestRWallCollisionAdjNew(coll_data) != FALSE:
		Mpprocess.mpProcessRunRWallCollisionAdjNew(coll_data)
	if Mpprocess.mpProcessCheckTestCeilCollisionAdjNew(coll_data) != FALSE:
		Mpprocess.mpProcessRunCeilCollisionAdjNew(coll_data)

		if coll_data.mask_stat & MAP_FLAG_CEIL:
			Mpprocess.mpProcessRunCeilEdgeAdjust(coll_data)
		if (flags & MAP_PROC_TYPE_CEILHEAVY) and (this_fp.physics.vel_air.y >= 30.0):
			coll_data.mask_curr |= MAP_FLAG_CEILHEAVY

			is_ceilstop = TRUE

			coll_data.is_coll_end = TRUE
	is_collide = Mpprocess.mpProcessCheckTestFloorCollisionAdjNew(coll_data, sMPCommonProcPass, fighter_gobj) if (flags & MAP_PROC_TYPE_PASS) else Mpprocess.mpProcessRunFloorCollisionAdjNewNULL(coll_data)

	if is_collide != FALSE:
		if flags & MAP_PROC_TYPE_PROJECT:
			Mpprocess.mpProcessSetCollideFloor(coll_data)

			if coll_data.mask_stat & MAP_FLAG_FLOOR:
				Mpprocess.mpProcessRunFloorEdgeAdjust(coll_data)
			else:
				Mpprocess.mpProcessSetCollProjectFloorID(coll_data)
		else:
			Mpprocess.mpProcessSetLandingFloor(coll_data)
			mpCommonSetFighterLandingParams(fighter_gobj)

			if coll_data.mask_stat & MAP_FLAG_FLOOR:
				Mpprocess.mpProcessRunFloorEdgeAdjust(coll_data)

				coll_data.is_coll_end = TRUE

				return TRUE
	else:
		Mpprocess.mpProcessSetCollProjectFloorID(coll_data)

	if (flags & MAP_PROC_TYPE_CLIFF) and (this_fp.cliffcatch_wait == 0):
		if (Mpprocess.mpProcessCheckTestLCliffCollision(coll_data) != FALSE) or (Mpprocess.mpProcessCheckTestRCliffCollision(coll_data) != FALSE):
			# cliffcatch_gobj = gGCCommonLinks[nGCCommonLinkIDFighter]; ... cliffcatch_gobj->link_next
			for cliffcatch_gobj in Sim.get_link(nGCCommonLinkIDFighter):
				if cliffcatch_gobj != fighter_gobj:
					cliffcatch_fp = ftGetStruct(cliffcatch_gobj)

					if (cliffcatch_fp.is_cliff_hold) and (this_fp.coll_data.cliff_id == cliffcatch_fp.coll_data.cliff_id) and (this_fp.lr == cliffcatch_fp.lr):
						return is_ceilstop
					else:
						continue # goto next_gobj; // Bruh
				# next_gobj:
			mpCommonSetFighterLandingParams(fighter_gobj)

			coll_data.is_coll_end = TRUE

			return TRUE
	return is_ceilstop

## 0x800DE6B0
static func mpCommonCheckFighterLanding(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	return Mpprocess.mpProcessUpdateMain(fp.coll_data, Callable(Mpcommon, &"mpCommonRunFighterSpecialCollisions"), fighter_gobj, MAP_PROC_TYPE_DEFAULT)

## 0x800DE6E4
static func mpCommonProcFighterLanding(fighter_gobj, proc_map: Callable) -> int:
	if mpCommonCheckFighterLanding(fighter_gobj) != FALSE:
		proc_map.call(fighter_gobj)

		return TRUE
	return FALSE

## 0x800DE724 - keep fighter airborne but project onto ground?
static func mpCommonCheckFighterProject(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	return Mpprocess.mpProcessUpdateMain(fp.coll_data, Callable(Mpcommon, &"mpCommonRunFighterSpecialCollisions"), fighter_gobj, MAP_PROC_TYPE_PROJECT)

## 0x800DE758
## proc_map: Callable(fighter_gobj) -> sb32 (pass-through floor test)
static func mpCommonCheckFighterPass(fighter_gobj, proc_map) -> int:
	var fp := ftGetStruct(fighter_gobj)

	sMPCommonProcPass = proc_map if (proc_map is Callable) else Callable() # NULL -> Callable()

	return Mpprocess.mpProcessUpdateMain(fp.coll_data, Callable(Mpcommon, &"mpCommonRunFighterSpecialCollisions"), fighter_gobj, MAP_PROC_TYPE_PASS)

## 0x800DE798
static func mpCommonCheckFighterPassCliff(fighter_gobj, proc_map) -> int:
	var fp := ftGetStruct(fighter_gobj)

	sMPCommonProcPass = proc_map if (proc_map is Callable) else Callable() # NULL -> Callable()

	return Mpprocess.mpProcessUpdateMain(fp.coll_data, Callable(Mpcommon, &"mpCommonRunFighterSpecialCollisions"), fighter_gobj, MAP_PROC_TYPE_PASS | MAP_PROC_TYPE_CLIFF)

## 0x800DE7D8
static func mpCommonCheckFighterCliff(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	return Mpprocess.mpProcessUpdateMain(fp.coll_data, Callable(Mpcommon, &"mpCommonRunFighterSpecialCollisions"), fighter_gobj, MAP_PROC_TYPE_CLIFF)

## Check if fighter becomes grounded, allow CliffCatch interrupt
static func mpCommonProcFighterCliff(fighter_gobj, proc_map: Callable) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if mpCommonCheckFighterCliff(fighter_gobj) != FALSE:
		if fp.coll_data.mask_stat & MAP_FLAG_CLIFF_MASK:
			Ftcommoncliffcatchwait.ftCommonCliffCatchSetStatus(fighter_gobj)

			return TRUE
		else:
			proc_map.call(fighter_gobj)

		return TRUE
	return FALSE

## 0x800DE87C
static func mpCommonCheckFighterCeilHeavyCliff(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	return Mpprocess.mpProcessUpdateMain(fp.coll_data, Callable(Mpcommon, &"mpCommonRunFighterSpecialCollisions"), fighter_gobj, MAP_PROC_TYPE_CEILHEAVY | MAP_PROC_TYPE_CLIFF)

## 0x800DE8B0
static func mpCommonCheckFighterCeilHeavy(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	return Mpprocess.mpProcessUpdateMain(fp.coll_data, Callable(Mpcommon, &"mpCommonRunFighterSpecialCollisions"), fighter_gobj, MAP_PROC_TYPE_CEILHEAVY)

## 0x800DE8E4
static func mpCommonSetFighterWaitOrLanding(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.physics.vel_air.y > FTCOMMON_ATTACKAIR_SKIPLANDING_VEL_Y_MAX:
		Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)
	else:
		Ftcommonlanding.ftCommonLandingSetStatus(fighter_gobj)

## 0x800DE934
static func mpCommonProcFighterWaitOrLanding(fighter_gobj) -> void:
	mpCommonProcFighterLanding(fighter_gobj, Callable(Mpcommon, &"mpCommonSetFighterWaitOrLanding"))

## 0x800DE958
static func mpCommonProcFighterProject(fighter_gobj) -> void:
	mpCommonCheckFighterProject(fighter_gobj)

## 0x800DE978
static func mpCommonProcFighterCliffWaitOrLanding(fighter_gobj) -> void:
	mpCommonProcFighterCliff(fighter_gobj, Callable(Mpcommon, &"mpCommonSetFighterWaitOrLanding"))

## 0x800DE99C
static func mpCommonProcFighterCliffFloorCeil(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if mpCommonCheckFighterCeilHeavyCliff(fighter_gobj) != FALSE:
		if fp.coll_data.mask_stat & MAP_FLAG_CLIFF_MASK:
			Ftcommoncliffcatchwait.ftCommonCliffCatchSetStatus(fighter_gobj)
		elif fp.coll_data.mask_stat & MAP_FLAG_FLOOR:
			mpCommonSetFighterWaitOrLanding(fighter_gobj)
		elif fp.coll_data.mask_curr & MAP_FLAG_CEILHEAVY: # Enter ceiling bonk if true?
			Ftcommonstopceil.ftCommonStopCeilSetStatus(fighter_gobj)

## 0x800DEA20
static func mpCommonProcFighterDamage(coll_data: MPCollData, fighter_gobj, flags: int) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var is_collide: int = FALSE

	if Mpprocess.mpProcessCheckTestLWallCollisionAdjNew(coll_data) != FALSE:
		Mpprocess.mpProcessRunLWallCollisionAdjNew(coll_data)

		if not (fp.status_vars.common.damage.coll_mask_prev & MAP_FLAG_LWALL) and (Lbcommon.lbCommonMag2D(coll_data.pos_diff) > 30.0) and (syVectorAngleDiff3D(coll_data.pos_diff, coll_data.lwall_angle) > F_CLC_DTOR32(110.0)): # 1.9198622F
			fp.status_vars.common.damage.coll_mask_curr |= MAP_FLAG_LWALL

			is_collide = TRUE

			coll_data.is_coll_end = TRUE
		elif not (coll_data.mask_prev & MAP_FLAG_LWALL):
			fp.status_vars.common.damage.coll_mask_ignore |= MAP_FLAG_LWALL
	if Mpprocess.mpProcessCheckTestRWallCollisionAdjNew(coll_data) != FALSE:
		Mpprocess.mpProcessRunRWallCollisionAdjNew(coll_data)

		if not (fp.status_vars.common.damage.coll_mask_prev & MAP_FLAG_RWALL) and (Lbcommon.lbCommonMag2D(coll_data.pos_diff) > 30.0) and (syVectorAngleDiff3D(coll_data.pos_diff, coll_data.rwall_angle) > F_CLC_DTOR32(110.0)): # 1.9198622F
			fp.status_vars.common.damage.coll_mask_curr |= MAP_FLAG_RWALL

			is_collide = TRUE

			coll_data.is_coll_end = TRUE
		elif not (coll_data.mask_prev & MAP_FLAG_RWALL):
			fp.status_vars.common.damage.coll_mask_ignore |= MAP_FLAG_RWALL
	if Mpprocess.mpProcessCheckTestCeilCollisionAdjNew(coll_data) != FALSE:
		Mpprocess.mpProcessRunCeilCollisionAdjNew(coll_data)

		if coll_data.mask_stat & MAP_FLAG_CEIL:
			Mpprocess.mpProcessRunCeilEdgeAdjust(coll_data)
		if not (fp.status_vars.common.damage.coll_mask_prev & MAP_FLAG_CEIL) and (Lbcommon.lbCommonMag2D(coll_data.pos_diff) > 30.0) and (syVectorAngleDiff3D(coll_data.pos_diff, coll_data.ceil_angle) > F_CLC_DTOR32(110.0)):
			fp.status_vars.common.damage.coll_mask_curr |= MAP_FLAG_CEIL

			is_collide = TRUE

			coll_data.is_coll_end = TRUE
		elif not (coll_data.mask_prev & MAP_FLAG_CEIL):
			fp.status_vars.common.damage.coll_mask_ignore |= MAP_FLAG_CEIL
	if Mpprocess.mpProcessRunFloorCollisionAdjNewNULL(coll_data) != FALSE:
		if fp.hitlag_tics > 0:
			Mpprocess.mpProcessSetCollideFloor(coll_data)

			if coll_data.mask_stat & MAP_FLAG_FLOOR:
				Mpprocess.mpProcessRunFloorEdgeAdjust(coll_data)
			else:
				Mpprocess.mpProcessSetCollProjectFloorID(coll_data)
		else:
			if syVectorAngleDiff3D(coll_data.pos_diff, coll_data.floor_angle) > F_CLC_DTOR32(110.0):
				Mpprocess.mpProcessSetLandingFloor(coll_data)
				mpCommonSetFighterLandingParams(fighter_gobj)

				if coll_data.mask_stat & MAP_FLAG_FLOOR:
					Mpprocess.mpProcessRunFloorEdgeAdjust(coll_data)

					fp.status_vars.common.damage.coll_mask_curr |= MAP_FLAG_FLOOR

					is_collide = TRUE

					coll_data.is_coll_end = TRUE
			else:
				Mpprocess.mpProcessSetCollideFloor(coll_data)

				if coll_data.mask_stat & MAP_FLAG_FLOOR:
					Mpprocess.mpProcessRunFloorEdgeAdjust(coll_data)

					if not (coll_data.mask_prev & MAP_FLAG_FLOOR):
						fp.status_vars.common.damage.coll_mask_ignore |= MAP_FLAG_FLOOR

						fp.status_vars.common.damage.wall_collide_angle = coll_data.floor_angle
				else:
					Mpprocess.mpProcessSetCollProjectFloorID(coll_data)
	else:
		Mpprocess.mpProcessSetCollProjectFloorID(coll_data)

	return is_collide

## 0x800DEDAC
static func mpCommonCheckFighterDamageCollision(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.common.damage.coll_mask_prev = fp.status_vars.common.damage.coll_mask_curr
	fp.status_vars.common.damage.coll_mask_curr = 0
	fp.status_vars.common.damage.coll_mask_ignore = 0

	return Mpprocess.mpProcessUpdateMain(fp.coll_data, Callable(Mpcommon, &"mpCommonProcFighterDamage"), fighter_gobj, MAP_PROC_TYPE_DEFAULT)

## 0x800DEDF0
static func mpCommonUpdateFighterKinetics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsAir:
		if mpCommonCheckFighterLanding(fighter_gobj) != FALSE:
			mpCommonSetFighterGround(fp)
	elif mpCommonCheckFighterOnFloor(fighter_gobj) == FALSE:
		mpCommonSetFighterAir(fp)

## 0x800DEE54
static func mpCommonSetFighterWaitOrFall(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsAir:
		Ftcommonfall.ftCommonFallSetStatus(fighter_gobj)
	else:
		Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)

## 0x800DEE98
static func mpCommonSetFighterGround(fp) -> void:
	fp.physics.vel_ground.x = fp.physics.vel_air.x * fp.lr

	fp.ga = nMPKineticsGround

	fp.jumps_used = 0

	fp.stat_flags.ga = nMPKineticsGround

## 0x800DEEC8
static func mpCommonSetFighterAir(fp) -> void:
	fp.ga = nMPKineticsAir

	fp.joints[nFTPartsJointTopN].translate.z = 0.0
	fp.physics.vel_air.z = 0.0

	fp.jumps_used = 1

## 0x800DEEF4
static func mpCommonRunDefaultCollision(coll_data: MPCollData, gobj, flags: int) -> void:
	if Mpprocess.mpProcessCheckTestLWallCollisionAdjNew(coll_data) != FALSE:
		Mpprocess.mpProcessRunLWallCollisionAdjNew(coll_data)
	if Mpprocess.mpProcessCheckTestRWallCollisionAdjNew(coll_data) != FALSE:
		Mpprocess.mpProcessRunRWallCollisionAdjNew(coll_data)
	if Mpprocess.mpProcessCheckTestCeilCollisionAdjNew(coll_data) != FALSE:
		Mpprocess.mpProcessRunCeilCollisionAdjNew(coll_data)

		if coll_data.mask_stat & MAP_FLAG_CEIL:
			Mpprocess.mpProcessRunCeilEdgeAdjust(coll_data)
	if Mpprocess.mpProcessRunFloorCollisionAdjNewNULL(coll_data) != FALSE:
		Mpprocess.mpProcessSetCollideFloor(coll_data)

		if coll_data.mask_stat & MAP_FLAG_FLOOR:
			Mpprocess.mpProcessRunFloorEdgeAdjust(coll_data)
	else:
		Mpprocess.mpProcessSetCollProjectFloorID(coll_data)

## 0x800DEFBC
## pos: Vec3f* (input)
static func mpCommonCopyCollDataStats(this_coll_data: MPCollData, pos: Vector3, other_coll_data: MPCollData) -> void:
	this_coll_data.pos_prev = pos

	this_coll_data.p_map_coll = other_coll_data.map_coll
	this_coll_data.mask_curr = 0
	this_coll_data.mask_unk = 0
	this_coll_data.mask_stat = 0
	this_coll_data.is_coll_end = FALSE
	this_coll_data.update_tic = other_coll_data.update_tic

## 0x800DEFF8
static func mpCommonResetCollDataStats(coll_data: MPCollData) -> void:
	coll_data.p_map_coll = coll_data.map_coll

	coll_data.update_tic = Mpcollision.gMPCollisionUpdateTic
	coll_data.mask_curr = 0

## 0x800DF014
static func mpCommonRunFighterCollisionDefault(fighter_gobj, pos: Vector3, coll_data: MPCollData) -> void:
	var fp := ftGetStruct(fighter_gobj)

	mpCommonCopyCollDataStats(fp.coll_data, pos, coll_data)
	mpCommonRunDefaultCollision(fp.coll_data, fighter_gobj, MAP_PROC_TYPE_DEFAULT)
	mpCommonResetCollDataStats(fp.coll_data)

## 0x800DF058
static func mpCommonRunItemCollisionDefault(item_gobj, pos: Vector3, coll_data: MPCollData) -> void:
	var ip := itGetStruct(item_gobj)

	mpCommonCopyCollDataStats(ip.coll_data, pos, coll_data)
	mpCommonRunDefaultCollision(ip.coll_data, item_gobj, MAP_PROC_TYPE_DEFAULT)
	mpCommonResetCollDataStats(ip.coll_data)

## 0x800DF09C
static func mpCommonRunWeaponCollisionDefault(weapon_gobj, pos: Vector3, coll_data: MPCollData) -> void:
	var wp := wpGetStruct(weapon_gobj)

	mpCommonCopyCollDataStats(wp.coll_data, pos, coll_data)
	mpCommonRunDefaultCollision(wp.coll_data, weapon_gobj, MAP_PROC_TYPE_DEFAULT)
	mpCommonResetCollDataStats(wp.coll_data)
