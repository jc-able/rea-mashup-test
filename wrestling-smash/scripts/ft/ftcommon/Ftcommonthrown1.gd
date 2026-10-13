## 1:1 port of src/ft/ftcommon/ftcommonthrown1.c (ssb-decomp-re): Thrown statuses (victim side) -
## following the thrower's hand joint and switching to the queued thrown status.
class_name Ftcommonthrown1
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8014AAF0
static func ftCommonThrownProcUpdate(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)

	if fighter_gobj.anim_frame <= 0.0:
		var capture_fp := ftGetStruct(this_fp.capture_gobj)

		if (
			((capture_fp.fkind != nFTKindDonkey) and
			(capture_fp.fkind != nFTKindNDonkey) and
			(capture_fp.fkind != nFTKindGDonkey)) or
			(capture_fp.status_id != nFTCommonStatusThrowF)
		):
			ftCommonThrownSetStatusImmediate(fighter_gobj, this_fp.status_vars.common.thrown.status_id)

## 0x8014AB64
static func ftCommonThrownProcPhysics(fighter_gobj) -> void:
	var joint := DObjGetStruct(fighter_gobj)
	# ftCommonCapturePulledRotateScale(fighter_gobj, &joint->translate, &joint->rotate): both are pure outputs
	var r: Dictionary = Ftcommoncapturepulled.ftCommonCapturePulledRotateScale(fighter_gobj)

	joint.rotate = r.rotate
	joint.translate = r.this_pos

## 0x8014AB8C
static func ftCommonThrownProcMap(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var capture_gobj = this_fp.capture_gobj
	var capture_fp := ftGetStruct(capture_gobj)
	var this_dobj := DObjGetStruct(fighter_gobj)    # Vec3f *this_pos = &this_dobj->translate
	var dist_y: float

	if capture_fp.coll_data.floor_line_id != -1:
		# mpCollisionGetFCCommonFloor(line_id, this_pos, &dist_y, &floor_flags, &floor_angle)
		var r = Mpcollision.mpCollisionGetFCCommonFloor(capture_fp.coll_data.floor_line_id, this_dobj.translate)

		if B(r.ret):
			dist_y = r.dist
			this_fp.coll_data.floor_flags = r.flags
			this_fp.coll_data.floor_angle = r.angle

			this_fp.coll_data.floor_line_id = capture_fp.coll_data.floor_line_id

			return
	Mpcommon.mpCommonSetFighterProjectFloor(fighter_gobj)

## 0x8014AC0C
static func ftCommonThrownSetStatusQueue(fighter_gobj, status_id_new, status_id_queue) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var capture_fp := ftGetStruct(this_fp.capture_gobj)

	this_fp.ga = nMPKineticsAir
	this_fp.jumps_used = 1

	Ftmain.ftMainSetStatus(fighter_gobj, status_id_new, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	if (capture_fp.fkind == nFTKindYoshi) or (capture_fp.fkind == nFTKindNYoshi):
		this_fp.is_invisible = TRUE

		Ftparam.ftParamSetHitStatusAll(fighter_gobj, nGMHitStatusIntangible)
	Ftparam.ftParamSetCaptureImmuneMask(this_fp, FTCATCHKIND_MASK_ALL)

	this_fp.status_vars.common.thrown.status_id = status_id_queue

## 0x8014ACB4
static func ftCommonThrownSetStatusImmediate(fighter_gobj, status_id) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var capture_fp := ftGetStruct(this_fp.capture_gobj)

	this_fp.ga = nMPKineticsAir
	this_fp.jumps_used = 1

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	if (capture_fp.fkind == nFTKindYoshi) or (capture_fp.fkind == nFTKindNYoshi):
		this_fp.is_invisible = TRUE

		Ftparam.ftParamSetHitStatusAll(fighter_gobj, nGMHitStatusIntangible)
	Ftparam.ftParamSetCaptureImmuneMask(this_fp, FTCATCHKIND_MASK_ALL)

	if (
		(capture_fp.fkind == nFTKindMario) or
		(capture_fp.fkind == nFTKindMMario) or
		(capture_fp.fkind == nFTKindLuigi) or
		(capture_fp.fkind == nFTKindNMario) or
		(capture_fp.fkind == nFTKindNLuigi)
	):
		if capture_fp.status_id == nFTCommonStatusThrowB:
			Ftparam.ftParamMakeRumble(this_fp, 7, 0)
