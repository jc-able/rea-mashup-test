## 1:1 port of src/ft/ftcommon/ftcommoncapturewait.c (ssb-decomp-re): CaptureWait (victim held).
class_name Ftcommoncapturewait
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8014A980
static func ftCommonCaptureWaitProcMap(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var capture_gobj = this_fp.capture_gobj
	var capture_fp := ftGetStruct(capture_gobj)
	var this_dobj := DObjGetStruct(fighter_gobj)    # Vec3f *this_pos = &this_dobj->translate
	var capture_pos: Vector3
	var dist_y: float

	# mpCollisionGetFCCommonFloor(line_id, this_pos, &dist_y, &floor_flags, &floor_angle)
	var r = Mpcollision.mpCollisionGetFCCommonFloor(capture_fp.coll_data.floor_line_id, this_dobj.translate)

	if B(r.ret):
		dist_y = r.dist
		this_fp.coll_data.floor_flags = r.flags
		this_fp.coll_data.floor_angle = r.angle

		this_fp.coll_data.floor_line_id = capture_fp.coll_data.floor_line_id

		this_dobj.translate.y += dist_y

		this_fp.ga = nMPKineticsGround
		this_fp.jumps_used = 0
	else:
		if capture_fp.lr == +1:
			capture_pos = Mpcollision.mpCollisionGetFloorEdgeR(capture_fp.coll_data.floor_line_id)
		else:
			capture_pos = Mpcollision.mpCollisionGetFloorEdgeL(capture_fp.coll_data.floor_line_id)

		this_dobj.translate.y = capture_pos.y

		Mpcommon.mpCommonSetFighterProjectFloor(fighter_gobj)

		this_fp.ga = nMPKineticsAir
		this_fp.jumps_used = 1

## 0x8014AA58
static func ftCommonCaptureWaitSetStatus(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var capture_fp := ftGetStruct(this_fp.capture_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCaptureWait, 0.0, 1.0, (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_MODELPART))

	if (capture_fp.fkind == nFTKindYoshi) or (capture_fp.fkind == nFTKindNYoshi):
		this_fp.is_invisible = TRUE

		Ftparam.ftParamSetHitStatusAll(fighter_gobj, nGMHitStatusIntangible)
	Ftparam.ftParamSetCaptureImmuneMask(this_fp, FTCATCHKIND_MASK_ALL)
