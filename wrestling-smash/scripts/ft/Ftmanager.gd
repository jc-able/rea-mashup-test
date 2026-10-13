## 1:1 port of src/ft/ftmanager.c (ssb-decomp-re): fighter allocation, file setup and creation
## (ftManagerMakeFighter / ftManagerInitFighter).
## Memory pools (struct/parts free lists, figatree heaps, reloc file buffers) are replaced by
## object allocation and the SSBData loader; everything that touches game state is kept verbatim.
class_name Ftmanager
extends Port

# 0x80130D90
static var gFTManagerPlayersNum: int = 1
# 0x80130D94
static var gFTManagerMotionCount: int = 1
# 0x80130D96
static var gFTManagerStatUpdateCount: int = 1
# 0x80130D98 (FTManagerCommon file: effect textures; loaded by the renderer)
static var gFTManagerCommonFile = null
# 0x80130D9C
static var gFTManagerFigatreeHeapSize: int = 0

## dFTManagerDefaultFighterDesc (src/ft/ftdata.c) as an FTDesc dictionary.
## copy_kind = nFTKindKirby (no copy ability), pkind = nFTPlayerKindDemo, controller = NULL,
## button masks A/B/Z/L; callers (scenes) fill in the rest.
static func default_desc() -> Dictionary:
	return {
		"fkind": nFTKindNull,
		"pos": Vector3.ZERO,
		"lr": 1,
		"team": 0,
		"player": 0,
		"detail": nFTPartsDetailHigh,
		"costume": 0,
		"shade": 0,
		"handicap": 9,
		"level": 3,
		"stock_count": 0,
		"unk_rebirth_0x1C": 0,
		"unk_rebirth_0x1D": 3,
		"team_order": 0,
		"is_skip_entry": FALSE,
		"is_skip_shadow_setup": FALSE,
		"is_magnify_ignore": FALSE,
		"copy_kind": nFTKindKirby,
		"damage": 0,
		"pkind": nFTPlayerKindDemo,
		"controller": null,
		"button_mask_a": A_BUTTON,
		"button_mask_b": B_BUTTON,
		"button_mask_z": Z_TRIG,
		"button_mask_l": L_TRIG,
		"figatree_heap": null,
		"proc_display": Callable(),
	}

## 0x800D6FE0 - file sizes are only needed for the N64 heap layout.
static func ftManagerSetupFileSize():
	gFTManagerFigatreeHeapSize = 0

## 0x800D7194
static func ftManagerAllocFighter(data_flags = null, allocs_num = null):
	gFTManagerPlayersNum = 1
	gFTManagerMotionCount = 1
	gFTManagerStatUpdateCount = 1
	# gFTManagerCommonFile / FTCommonMoveset (file 201): loaded through SSBData.
	SSBData.damage_script_table()

## 0x800D7594
static func ftManagerGetNextStructAlloc():
	return Fighter.new()

## 0x800D75EC
static func ftManagerSetPrevStructAlloc(fp = null):
	pass

## 0x800D7604
static func ftManagerGetNextPartsAlloc():
	var new_part := FtParts.new()
	new_part.transform_update_mode = 0
	new_part.unk_dobjtrans_0x5 = 0
	new_part.unk_dobjtrans_0x7 = 0
	new_part.unk_dobjtrans_0x6 = 0
	new_part.gobj = null
	new_part.is_have_anim = false
	return new_part

## 0x800D767C
static func ftManagerSetPrevPartsAlloc(parts = null):
	pass

## 0x800D7694
static func ftManagerSetupFilesMainKind(fkind = null):
	SSBData.get_fighter(fkind)

## 0x800D7710
static func ftManagerSetupFilesKind(fkind = null):
	SSBData.get_fighter(fkind)

## 0x800D782C
static func ftManagerSetupFilesPlayablesAll():
	for i in range(0, nFTKindPlayableEnd + 1):
		ftManagerSetupFilesKind(i)

## 0x800D786C
static func ftManagerSetupFilesAllKind(fkind = null):
	ftManagerSetupFilesMainKind(fkind)
	ftManagerSetupFilesKind(fkind)

## 0x800D78B4 - figatrees are shared AnimStream tables; no per-fighter heap needed.
static func ftManagerAllocFigatreeHeapKind(fkind = null):
	return null

## 0x800D78E8
static func ftManagerDestroyFighter(fighter_gobj = null):
	var fp: Fighter = ftGetStruct(fighter_gobj)
	if B(fp.is_effect_attach):
		Ftparam.ftParamProcStopEffect(fighter_gobj)
	for i in fp.joints.size():
		if fp.joints[i] != null:
			var parts = fp.joints[i].user_data
			if parts != null and parts.gobj != null:
				Objman.gcEjectGObj(parts.gobj)
			ftManagerSetPrevPartsAlloc(parts)
	ftManagerSetPrevStructAlloc(fp)
	Objman.gcEjectGObj(fighter_gobj)

## 0x800D7994
static func ftManagerDestroyFighterWeapons(fighter_gobj = null):
	var fp: Fighter = ftGetStruct(fighter_gobj)
	match fp.fkind:
		nFTKindKirby, nFTKindNKirby:
			Ftkirbycopylinkspecialn.ftKirbyCopyLinkSpecialNDestroyBoomerang(fighter_gobj)
		nFTKindLink, nFTKindNLink:
			Ftlinkspecialn.ftLinkSpecialNDestroyBoomerang(fighter_gobj)

## dKirbyMainMotion_0x0000 (src/relocData/228_KirbyMainMotion.c): FTKirbyCopy[27]
## {copy_id, copy_modelpart_id, effect_scale, star_damage}; only copy_modelpart_id is read here.
const _KIRBY_COPY_MODELPART_ID := [12, 7, 4, 8, 11, 10, 5, 9, 0, 6, 3, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4]

## 0x800D79F0
static func ftManagerInitFighter(fighter_gobj = null, desc = null):
	var fp: Fighter = ftGetStruct(fighter_gobj)
	var attr = fp.attr

	fp.lr = desc.lr
	fp.percent_damage = desc.damage

	if fp.pkind != nFTPlayerKindDemo:
		G.gSCManagerBattleState.players[fp.player].stock_damage_all = fp.percent_damage
	fp.shield_health = 55 if (fp.fkind == nFTKindYoshi) else 55

	fp.unk_ft_0x38 = 0.0
	fp.hitlag_tics = 0
	fp.is_knockback_paused = FALSE

	Ftphysics.ftPhysicsStopVelAll(fighter_gobj)

	fp.jumps_used = 0
	fp.is_reflect = FALSE
	fp.is_absorb = FALSE
	fp.is_shield = FALSE
	fp.is_effect_attach = FALSE
	fp.is_jostle_ignore = FALSE

	fp.cliffcatch_wait = 0
	fp.tics_since_last_z = 0

	fp.acid_wait = 0
	fp.twister_wait = 0
	fp.tarucann_wait = 0
	fp.damagefloor_wait = 0

	fp.unk_ft_0x7AC = 0
	fp.attack_damage = 0
	fp.attack_count = 0
	fp.attack_shield_push = 0
	fp.shield_damage = 0
	fp.damage_lag = 0
	fp.damage_queue = 0
	fp.damage_player = -1
	fp.damage_object_class = 0
	fp.damage_object_kind = 0
	fp.damage_count = 0
	fp.damage_kind = nFTDamageKindDefault
	fp.damage_heal = 0
	fp.damage_joint_id = 0
	fp.invincible_tics = 0
	fp.intangible_tics = 0
	fp.star_invincible_tics = 0

	fp.hitstatus = nGMHitStatusNormal
	fp.star_hitstatus = nGMHitStatusNormal
	fp.special_hitstatus = nGMHitStatusNormal

	fp.throw_gobj = null
	fp.catch_gobj = null
	fp.capture_gobj = null
	fp.is_catch_or_capture = FALSE

	fp.item_gobj = null

	fp.reflect_lr = 0
	fp.absorb_lr = 0

	fp.reflect_damage = 0

	fp.special_coll = null

	fp.attack1_followup_frames = 0.0
	fp.unk_ft_0x7A0 = 0.0
	fp.attack_knockback = 0.0
	fp.attack_rebound = 0.0
	fp.damage_knockback_stack = 0.0
	fp.knockback_resist_status = 0.0
	fp.knockback_resist_passive = 0.0
	fp.damage_knockback = 0.0
	fp.hitlag_mul = 1.0
	fp.shield_heal_wait = 10.0

	fp.is_fastfall = FALSE

	fp.player_num = gFTManagerPlayersNum
	gFTManagerPlayersNum += 1

	fp.public_knockback = 0.0

	fp.is_hitstun = FALSE
	fp.is_use_animlocks = FALSE

	fp.shuffle_frame_index = 0
	fp.shuffle_index_max = 0

	fp.is_use_fogcolor = FALSE

	fp.is_shuffle_electric = FALSE
	fp.shuffle_tics = 0

	fp.motion_attack_id = nFTMotionAttackIDNone
	fp.motion_count = 0
	fp.stat_flags.attack_id = nFTStatusAttackIDNone
	fp.stat_flags.ga = 0
	fp.stat_flags.is_smash_attack = 0
	fp.stat_flags.is_projectile = 0

	fp.stat_count = 0
	fp.damage_stat_count = 0
	fp.damage_stat_flags = fp.stat_flags.dup()

	fp.afterimage.desc_id = 0

	DObjGetStruct(fighter_gobj).translate = desc.pos
	DObjGetStruct(fighter_gobj).scale = Vector3(attr.size, attr.size, attr.size)

	if fp.pkind != nFTPlayerKindDemo:
		var r = Mpcollision.mpCollisionCheckProjectFloor(DObjGetStruct(fighter_gobj).translate)
		var is_collide_floor: int = r.ret
		fp.coll_data.floor_line_id = r.project_line_id
		fp.coll_data.floor_dist = r.ga_dist
		fp.coll_data.floor_flags = r.stand_coll_flags
		fp.coll_data.floor_angle = r.angle

		if is_collide_floor == FALSE:
			fp.coll_data.floor_line_id = -1
		if (is_collide_floor != FALSE) and (fp.coll_data.floor_dist > -300.0) and (fp.fkind != nFTKindBoss):
			fp.ga = nMPKineticsGround
			var t: Vector3 = DObjGetStruct(fighter_gobj).translate
			t.y += fp.coll_data.floor_dist
			DObjGetStruct(fighter_gobj).translate = t
			fp.coll_data.floor_dist = 0
		else:
			fp.ga = nMPKineticsAir
			fp.jumps_used = 1
	else:
		fp.ga = nMPKineticsAir
		fp.jumps_used = 1
	fp.coll_data.pos_prev = DObjGetStruct(fighter_gobj).translate

	match fp.fkind:
		nFTKindMMario:
			fp.knockback_resist_passive = 30.0
			fp.passive_vars.mario.is_expend_tornado = FALSE
		nFTKindMario, nFTKindNMario:
			fp.passive_vars.mario.is_expend_tornado = FALSE
		nFTKindGDonkey:
			fp.knockback_resist_passive = 48.0
			fp.passive_vars.donkey.charge_level = 0
		nFTKindDonkey, nFTKindNDonkey:
			fp.passive_vars.donkey.charge_level = 0
		nFTKindSamus, nFTKindNSamus:
			fp.passive_vars.samus.charge_level = 0
			fp.passive_vars.samus.charge_recoil = 0
		nFTKindLuigi, nFTKindNLuigi:
			fp.passive_vars.mario.is_expend_tornado = FALSE
		nFTKindCaptain, nFTKindNCaptain:
			fp.passive_vars.captain.falcon_punch_unk = 0
		nFTKindKirby, nFTKindNKirby:
			fp.passive_vars.kirby.copy_id = desc.copy_kind
			fp.passive_vars.kirby.copysamus_charge_level = 0
			fp.passive_vars.kirby.copysamus_charge_recoil = 0
			fp.passive_vars.kirby.copydonkey_charge_level = 0
			fp.passive_vars.kirby.copycaptain_falcon_punch_unk = 0
			fp.passive_vars.kirby.copypurin_unk = 0
			fp.passive_vars.kirby.copylink_boomerang_gobj = null
			if desc.copy_kind == nFTKindKirby:
				fp.passive_vars.kirby.is_ignore_losecopy = FALSE
			else:
				fp.passive_vars.kirby.is_ignore_losecopy = TRUE
			if fp.fkind == nFTKindKirby:
				Ftparam.ftParamSetModelPartDefaultID(fighter_gobj, FTKIRBY_COPY_MODELPARTS_JOINT, _KIRBY_COPY_MODELPART_ID[fp.passive_vars.kirby.copy_id])
		nFTKindLink, nFTKindNLink:
			fp.passive_vars.link.boomerang_gobj = null
			Ftparam.ftParamSetModelPartDefaultID(fighter_gobj, 21, -1)
			Ftparam.ftParamSetModelPartDefaultID(fighter_gobj, 19, 0)
		nFTKindPurin, nFTKindNPurin:
			fp.passive_vars.purin.unk_0x0 = 0
	# nFTKindBoss (1P final stage only) is not part of this port's VS mode.
	Ftparam.ftParamClearAttackCollAll(fighter_gobj)
	Ftparam.ftParamSetHitStatusPartAll(fighter_gobj, nGMHitStatusNormal)
	Ftparam.ftParamResetFighterColAnim(fighter_gobj)

## 0x800D7F3C - Create fighter
static func ftManagerMakeFighter(desc = null):
	# fighter_gobj = gcMakeGObjSPAfter(nGCCommonKindFighter, NULL, nGCCommonLinkIDFighter, GOBJ_PRIORITY_DEFAULT);
	# (the GObj and its FTStruct are one object in this port, see PORTING.md section 2)
	var fp: Fighter = ftManagerGetNextStructAlloc()
	var fighter_gobj = fp
	fp.gobj_kind = nGCCommonKindFighter
	Sim.add_gobj(fp, nGCCommonLinkIDFighter)
	Objman.gcAddGObjDisplay(fighter_gobj, desc.proc_display, FTDISPLAY_DLLINK_DEFAULT, GOBJ_PRIORITY_DEFAULT, ~0)

	fighter_gobj.user_data = fp
	fp.pkind = desc.pkind
	fp.fighter_gobj = fighter_gobj
	fp.fkind = desc.fkind
	fp.data = SSBData.get_fighter(fp.fkind)
	fp.name_key = fp.data.kind
	var attr = fp.data.attr
	fp.attr = attr
	fp.figatree_heap = desc.figatree_heap
	fp.team = desc.team
	fp.player = desc.player
	fp.stock_count = desc.stock_count

	if fp.pkind != nFTPlayerKindDemo:
		G.gSCManagerBattleState.players[fp.player].stock_count = desc.stock_count
	fp.detail_curr = desc.detail
	fp.detail_base = desc.detail

	fp.costume = desc.costume
	fp.shade = desc.shade

	if fp.shade > 0:
		var sc: Dictionary = attr.shade_color[fp.shade - 1]
		fp.shade_color = Color8((sc.r * sc.a) / 0xFF, (sc.g * sc.a) / 0xFF, (sc.b * sc.a) / 0xFF, 0xFF)

	fp.handicap = desc.handicap
	fp.level = desc.level

	fp.card_anim_frame_id = 0
	fp.unk_ft_0x3C = 0
	fp.anim_desc = 0

	fp.p_sfx = null
	fp.sfx_id = 0
	fp.p_voice = null
	fp.voice_id = 0
	fp.p_loop_sfx = null
	fp.loop_sfx_id = 0

	fp.effect_joint_array_id = 0

	fp.is_invisible = FALSE
	fp.is_shadow_hide = FALSE

	fp.display_mode = nDBDisplayModeMaster

	fp.is_muted = FALSE
	fp.is_events_forward = FALSE

	fp.proc_status = Callable()

	fp.unk_ft_0x149 = desc.unk_rebirth_0x1C
	fp.team_order = desc.team_order
	fp.dl_link = FTDISPLAY_DLLINK_DEFAULT

	fp.is_magnify_ignore = desc.is_magnify_ignore

	fp.status_total_tics = 0

	fp.camera_zoom_frame = attr.camera_zoom
	fp.camera_zoom_range = 1.0

	fp.is_playertag_bossend = FALSE
	fp.is_limit_map_bounds = FALSE

	fp.is_have_translate_scale = TRUE if (attr.translate_scales != null) else FALSE

	for i in fp.joints.size():
		fp.joints[i] = null
	var topn_joint: DObj = Objman.gcAddDObjForGObj(fighter_gobj, null)
	fp.joints[nFTPartsJointTopN] = topn_joint
	topn_joint.debug_name = "TopN"

	Lbcommon.lbCommonInitDObj3Transforms(topn_joint, 0x4B, nGCMatrixKindNull, nGCMatrixKindNull)

	fp.joints[nFTPartsJointTopN].xobj_unk05 = desc.unk_rebirth_0x1D

	Lbcommon.lbCommonSetupFighterPartsDObjs(
		DObjGetStruct(fighter_gobj),
		fp.data.commonparts,
		fp.detail_curr,
		fp.joints,
		attr.setup_parts,
		0x4B,
		nGCMatrixKindNull,
		nGCMatrixKindNull,
		fp.costume,
		fp.unk_ft_0x149
	)
	for i in fp.joints.size():
		if fp.joints[i] != null:
			var parts: FtParts = ftManagerGetNextPartsAlloc()
			fp.joints[i].user_data = parts
			parts.flags = attr.commonparts_container.commonparts[fp.detail_curr - nFTPartsDetailStart].flags
			parts.joint_id = i
			if i >= nFTPartsJointCommonStart and fp.joints[i].debug_name == "":
				fp.joints[i].debug_name = "joint%d" % i
			# Costume accessory parts (Pikachu hat / Purin bow) are display-only.
	for i in range(nFTPartsJointCommonStart, fp.joints.size()):
		if fp.joints[i] != null:
			var ms: Dictionary = fp.modelpart_status[i - nFTPartsJointCommonStart]
			ms.modelpart_id_base = 0 if (fp.joints[i].dl != null) else -1
			ms.modelpart_id_curr = ms.modelpart_id_base
	for i in fp.texturepart_status.size():
		fp.texturepart_status[i].texture_id_base = 0
		fp.texturepart_status[i].texture_id_curr = 0
	Ftparam.ftParamSetAnimLocks(fp)

	fp.input.pl.stick_range = Vector2i.ZERO
	fp.input.pl.stick_prev = Vector2i.ZERO
	fp.input.cp.stick_range = Vector2i.ZERO
	fp.input.pl.button_hold = 0
	fp.input.pl.button_tap = 0
	fp.input.cp.button_inputs = 0

	fp.input.controller = desc.controller

	fp.input.button_mask_a = desc.button_mask_a
	fp.input.button_mask_b = desc.button_mask_b
	fp.input.button_mask_z = desc.button_mask_z
	fp.input.button_mask_l = desc.button_mask_l

	fp.tap_stick_x = FTINPUT_STICKBUFFER_TICS_MAX
	fp.tap_stick_y = FTINPUT_STICKBUFFER_TICS_MAX
	fp.hold_stick_x = FTINPUT_STICKBUFFER_TICS_MAX
	fp.hold_stick_y = FTINPUT_STICKBUFFER_TICS_MAX

	for i in fp.damage_colls.size():
		var dc: FTDamageColl = fp.damage_colls[i]
		var dd: Dictionary = attr.damage_coll_descs[i]
		if dd.joint_id != -1:
			dc.hitstatus = nGMHitStatusNormal
			dc.joint_id = dd.joint_id
			dc.joint = fp.joints[dc.joint_id]
			dc.placement = dd.placement
			dc.is_grabbable = dd.is_grabbable
			dc.offset = dd.offset
			dc.size = dd.size
			dc.size.x *= 0.5
			dc.size.y *= 0.5
			dc.size.z *= 0.5
		else:
			dc.hitstatus = nGMHitStatusNone
	# coll_data.p_translate / p_lr resolve through coll_data.owner (see MPCollData.gd)
	fp.coll_data.owner = fp
	fp.coll_data.map_coll = attr.map_coll.dup()
	fp.coll_data.p_map_coll = fp.coll_data.map_coll
	fp.coll_data.cliffcatch_coll = attr.cliffcatch_coll
	fp.coll_data.ignore_line_id = -1
	fp.coll_data.update_tic = Mpcollision.gMPCollisionUpdateTic
	fp.coll_data.mask_curr = 0

	if fp.pkind != nFTPlayerKindDemo:
		Objman.gcAddGObjProcess(fighter_gobj, Callable(Ftmain, &"ftMainProcUpdateInterrupt"), nGCProcessKindFunc, 5)
		Objman.gcAddGObjProcess(fighter_gobj, Callable(Ftmain, &"ftMainProcPhysicsMapDefault"), nGCProcessKindFunc, 4)
		Objman.gcAddGObjProcess(fighter_gobj, Callable(Ftmain, &"ftMainProcPhysicsMapCapture"), nGCProcessKindFunc, 3)
		Objman.gcAddGObjProcess(fighter_gobj, Callable(Ftmain, &"ftMainProcSearchCatch"), nGCProcessKindFunc, 2)
		Objman.gcAddGObjProcess(fighter_gobj, Callable(Ftmain, &"ftMainProcSearchHitAll"), nGCProcessKindFunc, 1)
		Objman.gcAddGObjProcess(fighter_gobj, Callable(Ftmain, &"ftMainProcParams"), nGCProcessKindFunc, 0)
	# nFTPlayerKindDemo (character select / results podium) fighters are not used by this port.

	ftManagerInitFighter(fighter_gobj, desc)

	if fp.pkind == nFTPlayerKindCom:
		Ftcomputer.ftComputerSetupAll(fighter_gobj)
	if (fp.pkind == nFTPlayerKindKey) or (fp.pkind == nFTPlayerKindGameKey):
		fp.key.key_script = null
		fp.key.input_wait = 0
	match fp.pkind:
		nFTPlayerKindDemo:
			pass
		nFTPlayerKindKey:
			Mpcommon.mpCommonSetFighterWaitOrFall(fighter_gobj)
		_:
			if B(desc.is_skip_entry):
				Mpcommon.mpCommonSetFighterWaitOrFall(fighter_gobj)
				Ftparam.ftParamLockPlayerControl(fighter_gobj)
			else:
				Ftcommonentry.ftCommonEntrySetStatus(fighter_gobj)
				Ftparam.ftParamLockPlayerControl(fighter_gobj)
	if (fp.pkind == nFTPlayerKindMan) or (fp.pkind == nFTPlayerKindCom):
		Ftcomputer.ftComputerSetFighterDamageDetectSize(fighter_gobj)
	if (fp.pkind != nFTPlayerKindDemo) and not B(desc.is_skip_shadow_setup):
		Ftshadow.ftShadowMakeShadow(fighter_gobj)
	return fighter_gobj
