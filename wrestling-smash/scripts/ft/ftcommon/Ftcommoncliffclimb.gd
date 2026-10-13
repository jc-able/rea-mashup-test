## 1:1 port of src/ft/ftcommon/ftcommoncliffclimb.c (ssb-decomp-re): CliffQuick / CliffSlow (ledge action
## start-up), CliffClimbQuick1/2, CliffClimbSlow1/2 and the shared second-half ("Common2") routines that
## are also used by the ledge attack and ledge roll statuses.
class_name Ftcommoncliffclimb
extends Port

## fp->attr->cliff_status_ga[status_id], reproducing the original out-of-bounds read:
## FTAttributes declares `sb32 cliff_status_ga[5]` (offsets 0x2B8..0x2CB) but there are six cliff
## kinds, so nFTCommonCliffKindEscapeSlow (5) reads the next field, `s32 unused_0x2CC` (0x2CC).
static func _ftCommonCliffGetStatusGA(fp: Fighter, status_id: int) -> int:
	if status_id < fp.attr.cliff_status_ga.size():
		return fp.attr.cliff_status_ga[status_id]
	return fp.attr.unused_0x2CC   # cliff_status_ga[5]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80144EE0
static func ftCommonCliffQuickProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fighter_gobj.anim_frame <= 0.0:
		match fp.status_vars.common.cliffmotion.status_id:
			nFTCommonCliffKindClimbQuick:
				ftCommonCliffClimbQuick1SetStatus(fighter_gobj)

			nFTCommonCliffKindAttackQuick:
				Ftcommoncliffattack.ftCommonCliffAttackQuick1SetStatus(fighter_gobj)

			nFTCommonCliffKindEscapeQuick:
				Ftcommoncliffescape.ftCommonCliffEscapeQuick1SetStatus(fighter_gobj)

## 0x80144F64
static func ftCommonCliffSlowProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fighter_gobj.anim_frame <= 0.0:
		match fp.status_vars.common.cliffmotion.status_id:
			nFTCommonCliffKindClimbSlow:
				ftCommonCliffClimbSlow1SetStatus(fighter_gobj)

			nFTCommonCliffKindAttackSlow:
				Ftcommoncliffattack.ftCommonCliffAttackSlow1SetStatus(fighter_gobj)

			nFTCommonCliffKindEscapeSlow:
				Ftcommoncliffescape.ftCommonCliffEscapeSlow1SetStatus(fighter_gobj)

## 0x80144FE8
static func ftCommonCliffQuickOrSlowSetStatus(fighter_gobj, status_input: int) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int
	var status_queue: int

	if fp.percent_damage < FTCOMMON_CLIFF_DAMAGE_HIGH:
		status_id = nFTCommonStatusCliffQuick
		status_queue = nFTCommonCliffKindClimbQuick
	else:
		status_id = nFTCommonStatusCliffSlow
		status_queue = nFTCommonCliffKindClimbSlow

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.status_vars.common.cliffmotion.status_id = status_input + status_queue
	fp.status_vars.common.cliffmotion.cliff_id = fp.coll_data.cliff_id

	fp.is_cliff_hold = TRUE

	fp.proc_damage = Callable(Ftcommoncliffcatchwait, &"ftCommonCliffCommonProcDamage")

## 0x80145084
static func ftCommonCliffClimbOrFallCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if (ABS(fp.input.pl.stick_range.x) >= FTCOMMON_CLIFF_MOTION_STICK_RANGE_MIN) or (ABS(fp.input.pl.stick_range.y) >= FTCOMMON_CLIFF_MOTION_STICK_RANGE_MIN):
		var angle: float = Ftparam.ftParamGetStickAngleRads(fp)

		if (angle > F_CST_DTOR32(50.0)) or ((angle > F_CST_DTOR32(-50.0)) and ((fp.input.pl.stick_range.x * fp.lr) >= 0)):
			if fp.status_vars.common.cliffwait.is_allow_interrupt != FALSE:
				ftCommonCliffQuickOrSlowSetStatus(fighter_gobj, 0)

				return TRUE
			else:
				return FALSE
		elif fp.status_vars.common.cliffwait.is_allow_interrupt != FALSE:
			fp.cliffcatch_wait = FTCOMMON_CLIFF_CATCH_WAIT

			Ftcommoncliffcatchwait.ftCommonCliffCommonProcDamage(fighter_gobj)
			Ftcommonfall.ftCommonFallSetStatus(fighter_gobj)

			return TRUE
		else:
			return FALSE
	else:
		fp.status_vars.common.cliffwait.is_allow_interrupt = TRUE

	return FALSE

## 0x801451A8
static func ftCommonCliffClimbQuick1ProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommoncliffclimb, &"ftCommonCliffClimbQuick2SetStatus"))

## 0x801451CC
static func ftCommonCliffClimbSlow1ProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommoncliffclimb, &"ftCommonCliffClimbSlow2SetStatus"))

## 0x801451F0
static func ftCommonCliffClimbQuick1SetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCliffClimbQuick1, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.is_cliff_hold = TRUE

	fp.proc_damage = Callable(Ftcommoncliffcatchwait, &"ftCommonCliffCommonProcDamage")

## 0x80145240
static func ftCommonCliffClimbSlow1SetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCliffClimbSlow1, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.is_cliff_hold = TRUE

	fp.proc_damage = Callable(Ftcommoncliffcatchwait, &"ftCommonCliffCommonProcDamage")

## 0x80145290
static func ftCommonCliffCommon2ProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Mpcommon, &"mpCommonSetFighterWaitOrFall"))

## 0x801452B4
static func ftCommonCliffCommon2ProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3
	var vel = Vector3.ZERO     # C: uninitialized; .y is never read before mpCollisionGetSpeedLineID overwrites it
	var y: float

	if fp.ga == nMPKineticsGround:
		Ftphysics.ftPhysicsApplyGroundVelTransN(fighter_gobj)
	else:
		# Vec3f *translate = &DObjGetStruct(fighter_gobj)->translate.vec.f;  (read through DObjGetStruct(...).translate)
		pos = DObjGetStruct(fighter_gobj).translate

		# ftPhysicsGetAirVelTransN(fp, &vel.x, NULL, &vel.z); C signature (fp, f32 *z, f32 *y, f32 *x)
		var r = Ftphysics.ftPhysicsGetAirVelTransN(fp)
		vel.x = r.z
		vel.z = r.x

		pos.x += vel.x
		pos.z += vel.z

		# mpCollisionGetSpeedLineID(line_id, &vel): vel is a pure output (whole Vec3f overwritten)
		vel = Mpcollision.mpCollisionGetSpeedLineID(fp.status_vars.common.cliffmotion.cliff_id)

		pos.x += vel.x

		# mpCollisionGetFCCommonFloor(line_id, &pos, &y, NULL, NULL): pos is an input, y is an output
		var fc = Mpcollision.mpCollisionGetFCCommonFloor(fp.status_vars.common.cliffmotion.cliff_id, pos)

		if fc.ret:
			y = fc.dist

			pos.y += y

			pos.y += fp.joints[nFTPartsJointTransN].translate.y

			fp.physics.vel_air.x = pos.x - DObjGetStruct(fighter_gobj).translate.x
			fp.physics.vel_air.y = pos.y - DObjGetStruct(fighter_gobj).translate.y
			fp.physics.vel_air.z = pos.z - DObjGetStruct(fighter_gobj).translate.z
		else:
			Ftphysics.ftPhysicsApplyAirVelTransNAll(fighter_gobj)

## 0x801453F0
static func ftCommonCliffClimbCommon2ProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsGround:
		Mpcommon.mpCommonSetFighterFallOnGroundBreak(fighter_gobj)
	elif Mpcommon.mpCommonCheckFighterLanding(fighter_gobj):
		Mpcommon.mpCommonSetFighterGround(fp)

## 0x80145440
static func ftCommonCliffAttackEscape2ProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsGround:
		Mpcommon.mpCommonSetFighterFallOnEdgeBreak(fighter_gobj)
	elif Mpcommon.mpCommonCheckFighterLanding(fighter_gobj):
		Mpcommon.mpCommonSetFighterGround(fp)

## 0x80145490
static func ftCommonCliffCommon2UpdateCollData(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var coll_data: MPCollData = fp.coll_data
	# Vec3f *translate = &DObjGetStruct(fighter_gobj)->translate.vec.f;  -> writes go to DObjGetStruct(fighter_gobj).translate

	if _ftCommonCliffGetStatusGA(fp, fp.status_vars.common.cliffmotion.status_id) == nMPKineticsGround:
		Mpcommon.mpCommonSetFighterGround(fp)
	if fp.lr == +1:
		DObjGetStruct(fighter_gobj).translate = Mpcollision.mpCollisionGetFloorEdgeL(coll_data.cliff_id)

		DObjGetStruct(fighter_gobj).translate.x += 5.0
	else:
		DObjGetStruct(fighter_gobj).translate = Mpcollision.mpCollisionGetFloorEdgeR(coll_data.cliff_id)

		DObjGetStruct(fighter_gobj).translate.x -= 5.0
	coll_data.floor_line_id = coll_data.cliff_id

	# mpCollisionGetFCCommonFloor(line_id, translate, &coll_data->floor_dist, &coll_data->floor_flags, &coll_data->floor_angle);
	# The outputs are only written by the callee when it returns TRUE (otherwise the fields keep their values).
	var fc = Mpcollision.mpCollisionGetFCCommonFloor(coll_data.floor_line_id, DObjGetStruct(fighter_gobj).translate)
	if fc.ret:
		coll_data.floor_dist = fc.dist
		coll_data.floor_flags = fc.flags
		coll_data.floor_angle = fc.angle

	DObjGetStruct(fighter_gobj).translate.y += coll_data.floor_dist

	coll_data.floor_dist = 0.0

## 0x8014557C
static func ftCommonCliffCommon2InitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsGround:
		fp.is_jostle_ignore = TRUE

## 0x801455A0
static func ftCommonCliffClimbQuick2SetStatus(fighter_gobj) -> void:
	ftCommonCliffCommon2UpdateCollData(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCliffClimbQuick2, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftCommonCliffCommon2InitStatusVars(fighter_gobj)

## 0x801455E0
static func ftCommonCliffClimbSlow2SetStatus(fighter_gobj) -> void:
	ftCommonCliffCommon2UpdateCollData(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCliffClimbSlow2, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftCommonCliffCommon2InitStatusVars(fighter_gobj)
