## 1:1 port of src/ft/ftcommon/ftcommoncliffcatchwait.c (ssb-decomp-re): CliffCatch / CliffWait (ledge hang).
class_name Ftcommoncliffcatchwait
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80144B30
static func ftCommonCliffCatchProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommoncliffcatchwait, &"ftCommonCliffWaitSetStatus"))

## 0x80144B54
static func ftCommonCliffCommonProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var topn_joint: DObj = fp.joints[nFTPartsJointTopN]
	var transn_joint: DObj = fp.joints[nFTPartsJointTransN]
	var vel     # Vec3f

	# mpCollisionGetFloorEdge{L,R}(line_id, &vel): vel is a pure output
	if fp.lr == +1:
		vel = Mpcollision.mpCollisionGetFloorEdgeL(fp.coll_data.cliff_id)
	else:
		vel = Mpcollision.mpCollisionGetFloorEdgeR(fp.coll_data.cliff_id)

	topn_joint.translate.x = ((transn_joint.translate.z * fp.lr * topn_joint.scale.x) + vel.x)
	topn_joint.translate.y = ((transn_joint.translate.y * topn_joint.scale.y) + vel.y)

## 0x80144C1C
static func ftCommonCliffCommonProcMap(fighter_gobj) -> void:
	return

## 0x80144C24
static func ftCommonCliffCatchSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos     # Vec3f

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCliffCatch, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	Mpcommon.mpCommonSetFighterAir(fp)
	Ftphysics.ftPhysicsStopVelAll(fighter_gobj)

	fp.coll_data.floor_line_id = -1

	ftCommonCliffCommonProcPhysics(fighter_gobj)

	fp.is_cliff_hold = TRUE

	if fp.lr == +1:
		pos = Mpcollision.mpCollisionGetFloorEdgeL(fp.coll_data.cliff_id)
	else:
		pos = Mpcollision.mpCollisionGetFloorEdgeR(fp.coll_data.cliff_id)

	Efmanager.efManagerFlashMiddleMakeEffect(pos)

	fp.proc_damage = Callable(Ftcommoncliffcatchwait, &"ftCommonCliffCommonProcDamage")

	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_TARUCANN)

## 0x80144CF8
static func ftCommonCliffCommonProcDamage(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var map_coll: MPObjectColl = fp.coll_data.map_coll
	var pos     # Vec3f

	if fp.lr == +1:
		pos = Mpcollision.mpCollisionGetFloorEdgeL(fp.coll_data.cliff_id)
	else:
		pos = Mpcollision.mpCollisionGetFloorEdgeR(fp.coll_data.cliff_id)

	pos.x -= ((map_coll.width + 30.0) * fp.lr)
	pos.y -= map_coll.center

	Mpcommon.mpCommonRunFighterCollisionDefault(fighter_gobj, pos, fp.coll_data)

## 0x80144DA4
static func ftCommonCliffWaitProcInterrupt(fighter_gobj) -> void:
	if (
		(not Ftcommoncliffattack.ftCommonCliffAttackCheckInterruptCommon(fighter_gobj)) and
		(not Ftcommoncliffescape.ftCommonCliffEscapeCheckInterruptCommon(fighter_gobj)) and
		(not Ftcommoncliffclimb.ftCommonCliffClimbOrFallCheckInterruptCommon(fighter_gobj))
	):
		ftCommonCliffWaitCheckFall(fighter_gobj)

## 0x80144DF4
static func ftCommonCliffWaitSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCliffWait, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.status_vars.common.cliffwait.is_allow_interrupt = FALSE

	if fp.percent_damage < FTCOMMON_CLIFF_DAMAGE_HIGH:
		fp.status_vars.common.cliffwait.fall_wait = FTCOMMON_CLIFF_FALL_WAIT_DAMAGE_LOW
	else:
		fp.status_vars.common.cliffwait.fall_wait = FTCOMMON_CLIFF_FALL_WAIT_DAMAGE_HIGH

	fp.is_cliff_hold = TRUE

	Ftparam.ftParamSetPlayerTagWait(fighter_gobj, 120)

	fp.proc_damage = Callable(Ftcommoncliffcatchwait, &"ftCommonCliffCommonProcDamage")

	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_TARUCANN)

## 0x80144E84
static func ftCommonCliffWaitCheckFall(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.common.cliffwait.fall_wait -= 1

	if fp.status_vars.common.cliffwait.fall_wait == 0:
		fp.cliffcatch_wait = FTCOMMON_CLIFF_CATCH_WAIT

		ftCommonCliffCommonProcDamage(fighter_gobj)
		Ftcommondamagefall.ftCommonDamageFallSetStatusFromCliffWait(fighter_gobj)

		return TRUE
	else:
		return FALSE
