## 1:1 port of src/ft/ftcommon/ftcommondokan.c (ssb-decomp-re): DokanStart / DokanWait / DokanEnd /
## DokanWalk (entering and exiting the pipes on Peach's Castle / Mushroom Kingdom).
class_name Ftcommondokan
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80141FF0
static func ftCommonDokanStartUpdateModelYaw(fp) -> void:
	if fp.status_vars.common.dokan.turn_stop_wait != 0:
		fp.status_vars.common.dokan.turn_stop_wait -= 1

		fp.joints[nFTPartsJointTopN].rotate.y += (-FTCOMMON_DOKAN_TURN_STEP * fp.lr)

		Ftparam.ftParamsUpdateFighterPartsTransformAll(fp.joints[nFTPartsJointTopN])

## 0x8014204C
static func ftCommonDokanStartProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftCommonDokanStartUpdateModelYaw(fp)
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommondokan, &"ftCommonDokanWaitSetStatus"))

## 0x80142080
static func ftCommonDokanStartProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var dokan_pos: Vector3
	var translate_dobj := DObjGetStruct(fighter_gobj)    # Vec3f *translate = &translate_dobj->translate
	var floor_line_id: int = 0    # C: uninitialized s32, written through &floor_line_id

	floor_line_id = Mpcollision.mpCollisionGetMapObjIDsKind(
		nMPMapObjKindDokanL if (fp.status_vars.common.dokan.material == nMPMaterialDokanL) else nMPMapObjKindDokanR,
		floor_line_id
	)
	dokan_pos = Mpcollision.mpCollisionGetMapObjPositionID(floor_line_id)

	if translate_dobj.translate.x > dokan_pos.x:
		translate_dobj.translate.x -= FTCOMMON_DOKAN_POS_ADJUST

		if translate_dobj.translate.x <= dokan_pos.x:
			translate_dobj.translate.x = dokan_pos.x
	elif translate_dobj.translate.x < dokan_pos.x:
		translate_dobj.translate.x += FTCOMMON_DOKAN_POS_ADJUST

		if translate_dobj.translate.x >= dokan_pos.x:
			translate_dobj.translate.x = dokan_pos.x

## 0x80142164
static func ftCommonDokanStartSetStatus(fighter_gobj, material) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var new_point_id: int = 0    # C: uninitialized s32, written through &new_point_id

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusDokanStart, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.tap_stick_y = FTINPUT_STICKBUFFER_TICS_MAX

	Ftphysics.ftPhysicsStopVelAll(fighter_gobj)

	fp.is_jostle_ignore = TRUE

	fp.status_vars.common.dokan.material = material

	new_point_id = Mpcollision.mpCollisionGetMapObjIDsKind(
		nMPMapObjKindDokanL if (fp.status_vars.common.dokan.material == nMPMaterialDokanL) else nMPMapObjKindDokanR,
		new_point_id
	)
	fp.status_vars.common.dokan.pos_curr = Mpcollision.mpCollisionGetMapObjPositionID(new_point_id)

	Snd.func_800269C0_275C0(nSYAudioFGMMarioDokan)
	Ftparam.ftParamSetPlayerTagWait(fighter_gobj, 1)

	if (
		(fp.fkind == nFTKindMario) or (fp.fkind == nFTKindMMario) or (fp.fkind == nFTKindNMario) or
		(fp.fkind == nFTKindLuigi) or (fp.fkind == nFTKindNLuigi)
	):
		fp.status_vars.common.dokan.turn_stop_wait = 0
	else:
		fp.status_vars.common.dokan.turn_stop_wait = FTCOMMON_DOKAN_TURN_STOP_WAIT_DEFAULT

	ftCommonDokanStartUpdateModelYaw(fp)
	Grinishie.grInishiePakkunSetWaitFighter()

## 0x80142258
static func ftCommonDokanStartCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3
	var floor_line_id: int = 0    # C: uninitialized s32, written through &floor_line_id
	var dist_x: float

	if (fp.input.pl.stick_range.y <= FTCOMMON_DOKAN_STICK_RANGE_MIN) and (fp.tap_stick_y < FTCOMMON_DOKAN_BUFFER_TICS_MAX):
		if (fp.coll_data.floor_flags & MAP_VERTEX_MAT_MASK) == nMPMaterialDokanL:
			floor_line_id = Mpcollision.mpCollisionGetMapObjIDsKind(nMPMapObjKindDokanL, floor_line_id)
			pos = Mpcollision.mpCollisionGetMapObjPositionID(floor_line_id)

			if pos.x < DObjGetStruct(fighter_gobj).translate.x:
				dist_x = -(pos.x - DObjGetStruct(fighter_gobj).translate.x)
			else:
				dist_x = pos.x - DObjGetStruct(fighter_gobj).translate.x

			if dist_x <= FTCOMMON_DOKAN_DETECT_WIDTH:
				ftCommonDokanStartSetStatus(fighter_gobj, nMPMaterialDokanL)

				return TRUE
		elif (fp.coll_data.floor_flags & MAP_VERTEX_MAT_MASK) == nMPMaterialDokanR:
			floor_line_id = Mpcollision.mpCollisionGetMapObjIDsKind(nMPMapObjKindDokanR, floor_line_id)
			pos = Mpcollision.mpCollisionGetMapObjPositionID(floor_line_id)

			if pos.x < DObjGetStruct(fighter_gobj).translate.x:
				dist_x = -(pos.x - DObjGetStruct(fighter_gobj).translate.x)
			else:
				dist_x = pos.x - DObjGetStruct(fighter_gobj).translate.x

			if dist_x <= FTCOMMON_DOKAN_DETECT_WIDTH:
				ftCommonDokanStartSetStatus(fighter_gobj, nMPMaterialDokanR)

				return TRUE
	return FALSE

## 0x801423B4
static func ftCommonDokanWaitProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.common.dokan.pos_adjust_wait += 1

	if fp.status_vars.common.dokan.pos_adjust_wait == FTCOMMON_DOKAN_POS_ADJUST_WAIT:
		if fp.status_vars.common.dokan.mapobj_kind == nMPMapObjKindDokanWall:
			ftCommonDokanWalkSetStatus(fighter_gobj)
		else:
			ftCommonDokanEndSetStatus(fighter_gobj)

## 0x80142424
static func ftCommonDokanWaitProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	DObjGetStruct(fighter_gobj).translate.x = ObjAnim.gcGetInterpValueCubic(0.033333335, float(fp.status_vars.common.dokan.pos_adjust_wait), fp.status_vars.common.dokan.pos_curr.x, fp.status_vars.common.dokan.target_pos.x, 0.0, 0.0)
	DObjGetStruct(fighter_gobj).translate.y = ObjAnim.gcGetInterpValueCubic(0.033333335, float(fp.status_vars.common.dokan.pos_adjust_wait), fp.status_vars.common.dokan.pos_curr.y, fp.status_vars.common.dokan.target_pos.y, 0.0, 0.0)

## 0x801424BC
static func ftCommonDokanWaitSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var target_pos_x: float
	var line_id: int = 0    # C: uninitialized s32, written through &line_id

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusDokanWait, 0.0, 1.0, FTSTATUS_PRESERVE_HITSTATUS)

	fp.is_invisible = TRUE
	fp.is_playertag_hide = TRUE
	fp.is_effect_skip = TRUE

	fp.status_vars.common.dokan.pos_adjust_wait = 0

	fp.is_menu_ignore = TRUE

	if fp.status_vars.common.dokan.material == nMPMaterialDokanL:
		fp.status_vars.common.dokan.mapobj_kind = nMPMapObjKindDokanR
	else:
		fp.status_vars.common.dokan.mapobj_kind = nMPMapObjKindDokanL

	line_id = Mpcollision.mpCollisionGetMapObjIDsKind(fp.status_vars.common.dokan.mapobj_kind, line_id)

	fp.status_vars.common.dokan.target_pos = Mpcollision.mpCollisionGetMapObjPositionID(line_id)

	if syUtilsRandFloat() <= 0.25:
		fp.status_vars.common.dokan.mapobj_kind = nMPMapObjKindDokanWall

		line_id = Mpcollision.mpCollisionGetMapObjIDsKind(nMPMapObjKindDokanWall, line_id)
		fp.status_vars.common.dokan.target_pos = Mpcollision.mpCollisionGetMapObjPositionID(line_id)

		# mpCollisionCheckProjectRWall(&target_pos, NULL, &target_pos_x, NULL, NULL)
		var r = Mpcollision.mpCollisionCheckProjectRWall(fp.status_vars.common.dokan.target_pos)

		if B(r.ret):
			target_pos_x = r.ga_dist

			fp.status_vars.common.dokan.target_pos.x += target_pos_x + fp.coll_data.map_coll.width

## 0x801425E4
static func ftCommonDokanEndUpdateModelYaw(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fighter_gobj.anim_frame >= FTCOMMON_DOKAN_EXIT_WAIT:
		if fp.status_vars.common.dokan.turn_stop_wait != 0:
			fp.status_vars.common.dokan.turn_stop_wait -= 1

			fp.joints[nFTPartsJointTopN].rotate.y += (FTCOMMON_DOKAN_TURN_STEP * fp.lr)

			Ftparam.ftParamsUpdateFighterPartsTransformAll(fp.joints[nFTPartsJointTopN])

## 0x80142660
static func ftCommonDokanEndUpdatePlayerTag(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.common.dokan.playertag_wait != 0:
		fp.status_vars.common.dokan.playertag_wait -= 1

		if fp.status_vars.common.dokan.playertag_wait == 0:
			Ftparam.ftParamSetPlayerTagWait(fighter_gobj, 1)

## 0x80142698
static func ftCommonDokanEndProcUpdate(fighter_gobj) -> void:
	ftCommonDokanEndUpdatePlayerTag(fighter_gobj)
	ftCommonDokanEndUpdateModelYaw(fighter_gobj)
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Mpcommon, &"mpCommonSetFighterWaitOrFall"))

## 0x801426D0
static func ftCommonDokanEndSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusDokanEnd, 0.0, 1.0, FTSTATUS_PRESERVE_HITSTATUS)

	DObjGetStruct(fighter_gobj).translate = fp.status_vars.common.dokan.target_pos

	# mpCollisionCheckProjectFloor(&translate, &floor_line_id, &floor_dist, &floor_flags, &floor_angle)
	# (outputs are written only when a floor is found)
	var r = Mpcollision.mpCollisionCheckProjectFloor(DObjGetStruct(fighter_gobj).translate)

	if B(r.ret):
		fp.coll_data.floor_line_id = r.project_line_id
		fp.coll_data.floor_dist = r.ga_dist
		fp.coll_data.floor_flags = r.stand_coll_flags
		fp.coll_data.floor_angle = r.angle

	fp.is_jostle_ignore = TRUE
	fp.status_vars.common.dokan.playertag_wait = FTCOMMON_DOKAN_PLAYERTAG_WAIT

	if (fp.fkind != nFTKindMario) and (fp.fkind != nFTKindMMario) and (fp.fkind != nFTKindNMario) and (fp.fkind != nFTKindLuigi) and (fp.fkind != nFTKindNLuigi):
		fp.status_vars.common.dokan.turn_stop_wait = FTCOMMON_DOKAN_TURN_STOP_WAIT_DEFAULT
		fp.joints[nFTPartsJointTopN].rotate.y = 0.0

		Ftparam.ftParamsUpdateFighterPartsTransformAll(fp.joints[nFTPartsJointTopN])
	else:
		fp.status_vars.common.dokan.turn_stop_wait = 0

	Snd.func_800269C0_275C0(nSYAudioFGMMarioDokan)

## 0x801427CC
static func ftCommonDokanWalkSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)

	fp.lr = +1

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusDokanWalk, 0.0, 1.0, FTSTATUS_PRESERVE_HITSTATUS)

	DObjGetStruct(fighter_gobj).translate = fp.status_vars.common.dokan.target_pos

	fp.status_vars.common.dokan.playertag_wait = FTCOMMON_DOKAN_PLAYERTAG_WAIT

	Snd.func_800269C0_275C0(nSYAudioFGMMarioDokan)
