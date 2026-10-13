## 1:1 port of src/ft/ftparam.c (ssb-decomp-re): fighter parameter helpers - knockback,
## hitlag, hitstun, staling, damage, hurtbox states, colour-animation priority, animation key
## playback, anim locks. Purely visual helpers (model/texture parts, effects, colours) keep
## their bookkeeping for the renderer and forward visuals to Efmanager/Fx.
class_name Ftparam
extends Port

## dFTParamShuffleFrameIndexMax
const dFTParamShuffleFrameIndexMax := [4, 3]

## dFTParamSkeletonColAnimIDs (per FTKind)
const dFTParamSkeletonColAnimIDs := [0x14, 0x14, 0x14, 0x1C, 0x14, 0x14, 0x14, 0x14, 0x18, 0x14, 0x18, 0x14, 0x10,
	0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10]

## dFTParamStaleTable
const dFTParamStaleTable := [0.75, 0.82, 0.89, 0.96]

## dGMColScriptsDescs[] priority / is_unlocked (src/gm/gmcolscripts.c, REGION_US)
const dGMColScriptsPriority := [0, 1, 30, 30, 30, 100, 10, 60, 60, 15, 11, 10, 100, 100, 100, 100, 100, 100, 100, 100,
	100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 60, 60, 60, 60,
	60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60,
	60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 12, 100, 10, 60, 60, 60,
	60, 60, 60, 60, 60, 60, 60]
const dGMColScriptsUnlocked := [0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1]

static func ftParamIsColAnimUnlocked(colanim_id: int) -> bool:
	return colanim_id >= 0 and colanim_id < dGMColScriptsUnlocked.size() and dGMColScriptsUnlocked[colanim_id] != 0

static func _colanim_priority(colanim_id: int) -> int:
	if colanim_id < 0 or colanim_id >= dGMColScriptsPriority.size():
		return 0
	return dGMColScriptsPriority[colanim_id]

# ---------------------------------------------------------------------------
# Item music
# ---------------------------------------------------------------------------
## 0x800E7AD0
static func ftParamGetItemMusicLength(bgm_id: int) -> int:
	match bgm_id:
		nSYAudioBGMStar:
			return ITHAMMER_BGM_DURATION
		nSYAudioBGMHammer:
			return ITSTAR_BGM_DURATION
	return 0

## 0x800E7AFC
static func ftParamTryPlayItemMusic(bgm_id: int) -> void:
	if ftParamGetItemMusicLength(bgm_id) >= ftParamGetItemMusicLength(Mpcollision.gMPCollisionBGMCurrent):
		Mpcollision.gMPCollisionBGMCurrent = bgm_id

## 0x800E7B54
static func ftParamTryUpdateItemMusic() -> void:
	var bgm_play: int = Mpcollision.gMPCollisionBGMDefault
	var length: int = ftParamGetItemMusicLength(bgm_play)
	for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		var fp := ftGetStruct(fighter_gobj)
		var bgm_id: int = Mpcollision.gMPCollisionBGMDefault
		if (fp.item_gobj != null) and (itGetStruct(fp.item_gobj).kind == nITKindHammer):
			bgm_id = nSYAudioBGMHammer
		if fp.star_invincible_tics > ITSTAR_WARN_BEGIN_FRAME:
			bgm_id = nSYAudioBGMStar
		var length_new: int = ftParamGetItemMusicLength(bgm_id)
		if length < length_new:
			length = length_new
			bgm_play = bgm_id
	if bgm_play != Mpcollision.gMPCollisionBGMCurrent:
		Mpcollision.gMPCollisionBGMCurrent = bgm_play

# ---------------------------------------------------------------------------
# Battle stats / control
# ---------------------------------------------------------------------------
## 0x800E7C4C
static func ftParamInitPlayerBattleStats(player: int, fighter_gobj) -> void:
	var pl = G.gSCManagerBattleState.players[player]
	pl.place = 0
	pl.falls = 0
	pl.score = 0
	for i in 4:
		pl.total_kos_players[i] = 0
		pl.total_damage_players[i] = 0
	pl.unk_pblock_0x28 = 0
	pl.unk_pblock_0x2C = 0
	pl.total_selfdestructs = 0
	pl.total_damage_given = 0
	pl.total_damage_all = 0
	pl.combo_damage_foe = 0
	pl.combo_count_foe = 0
	pl.fighter_gobj = fighter_gobj
	pl.stale_id = 0
	for i in pl.stale_info.size():
		pl.stale_info[i].attack_id = 0
		pl.stale_info[i].motion_count = 0

## 0x800E7ED4
static func ftParamGetPlayerNumGObj(player_num: int):
	for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		if player_num == ftGetStruct(fighter_gobj).player_num:
			return fighter_gobj
	return null

## 0x800E7F14
static func ftParamLockPlayerControl(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	fp.input.pl.button_hold = 0
	fp.input.pl.button_tap = 0
	fp.input.cp.button_inputs = 0
	fp.input.pl.stick_range = Vector2i.ZERO
	fp.input.pl.stick_prev = Vector2i.ZERO
	fp.input.cp.stick_range = Vector2i.ZERO
	fp.tap_stick_x = FTINPUT_STICKBUFFER_TICS_MAX
	fp.tap_stick_y = FTINPUT_STICKBUFFER_TICS_MAX
	fp.hold_stick_x = FTINPUT_STICKBUFFER_TICS_MAX
	fp.hold_stick_y = FTINPUT_STICKBUFFER_TICS_MAX
	fp.is_control_disable = TRUE

## 0x800E7F68
static func ftParamUnlockPlayerControl(fighter_gobj) -> void:
	ftGetStruct(fighter_gobj).is_control_disable = FALSE

## 0x800E7F7C
static func ftParamSetPlayerTagWait(fighter_gobj, playertag_wait: int) -> void:
	ftGetStruct(fighter_gobj).playertag_wait = playertag_wait

## 0x800E7F88
static func ftParamSetDamageShuffle(fp: Fighter, is_electric: int, damage: int, status_id: int, hitlag_mul: float) -> void:
	var shuffle_tics: int = int(ftParamGetHitLag(damage, status_id, hitlag_mul) * FTCOMMON_DAMAGE_SHUFFLE_MUL)
	fp.shuffle_tics = shuffle_tics
	fp.shuffle_frame_index = 0
	fp.is_shuffle_electric = is_electric
	fp.shuffle_index_max = dFTParamShuffleFrameIndexMax[1 if B(is_electric) else 0]

## 0x800E8000
static func ftParamGetStickAngleRads(fp: Fighter) -> float:
	return syUtilsArcTan2(fp.input.pl.stick_range.y, ABS(fp.input.pl.stick_range.x))

## 0x800E8044
static func ftParamSetStickLR(fp: Fighter) -> void:
	fp.lr = 1 if (fp.input.pl.stick_range.x >= 0) else -1

## 0x800E806C
static func ftParamMakeRumble(fp: Fighter, rumble_id: int, length: int) -> void:
	if fp.pkind == nFTPlayerKindMan:
		Gmrumble.gmRumbleSetPlayerRumbleParams(fp.player, rumble_id, length)

## 0x800E8098
static func ftParamSetCaptureImmuneMask(fp: Fighter, capture_immune_mask: int) -> void:
	fp.capture_immune_mask = capture_immune_mask & 0xFF

## 0x800E80A4
static func ftParamSetCatchParams(fp: Fighter, catch_mask: int, proc_catch: Callable, proc_capture: Callable) -> void:
	fp.is_catchstatus = TRUE
	fp.catch_mask = catch_mask & 0xFF
	fp.proc_catch = proc_catch
	fp.proc_capture = proc_capture

## 0x800E80C4
static func ftParamSetThrowParams(this_fp: Fighter, throw_gobj) -> void:
	var throw_fp := ftGetStruct(throw_gobj)
	this_fp.throw_gobj = throw_gobj
	this_fp.throw_fkind = throw_fp.fkind
	this_fp.throw_player = throw_fp.player
	this_fp.throw_player_num = throw_fp.player_num
	this_fp.throw_team = throw_fp.team

## 0x800E80F0
static func ftParamPlayVoice(fp: Fighter, voice_id: int) -> void:
	fp.p_voice = Snd.func_800269C0_275C0(voice_id)
	fp.voice_id = fp.p_voice.sfx_id if fp.p_voice != null else 0

## 0x800E8138
static func ftParamStopVoice(fp: Fighter) -> void:
	if fp.p_voice != null:
		if (fp.p_voice.sfx_id != 0) and (fp.p_voice.sfx_id == fp.voice_id):
			Snd.func_80026738_27338(fp.p_voice)
	fp.p_voice = null
	fp.voice_id = 0

## 0x800E8190
static func ftParamPlayLoopSFX(fp: Fighter, sfx_id: int) -> void:
	if fp.p_loop_sfx == null:
		fp.p_loop_sfx = Snd.func_800269C0_275C0(sfx_id)
		fp.loop_sfx_id = fp.p_loop_sfx.sfx_id if fp.p_loop_sfx != null else 0

## 0x800E81E4
static func ftParamStopLoopSFX(fp: Fighter) -> void:
	if fp.p_loop_sfx != null:
		if (fp.p_loop_sfx.sfx_id != 0) and (fp.p_loop_sfx.sfx_id == fp.loop_sfx_id):
			Snd.func_80026738_27338(fp.p_loop_sfx)
	fp.p_loop_sfx = null
	fp.loop_sfx_id = 0

## 0x800E823C
static func ftParamStopVoiceRunProcDamage(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	ftParamStopVoice(fp)
	if fp.proc_damage.is_valid():
		fp.proc_damage.call(fighter_gobj)

## 0x800E827C
static func ftParamMoveDLLink(fighter_gobj, dl_link: int) -> void:
	ftGetStruct(fighter_gobj).dl_link = dl_link

## 0x800E82B8
static func ftParamUpdateAnimKeys(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var is_joint: bool = fp.anim_flag_is_anim_joint()
	if fp.motion_id != -2:
		if B(fp.is_have_translate_scale):
			var translate_scales: Array = fp.attr.translate_scales
			for i in fp.joints.size():
				var joint: DObj = fp.joints[i]
				if joint != null:
					if is_joint:
						ObjAnim.gcParseDObjAnimJoint(joint)
					else:
						ObjAnim.ftAnimParseDObjFigatree(joint)
					ObjAnim.lbCommonPlayTranslateScaledDObjAnim(joint, translate_scales[i] if i < translate_scales.size() else Vector3.ONE)
		else:
			for i in fp.joints.size():
				var joint: DObj = fp.joints[i]
				if joint != null:
					if is_joint:
						ObjAnim.gcParseDObjAnimJoint(joint)
					else:
						ObjAnim.ftAnimParseDObjFigatree(joint)
					ObjAnim.gcPlayDObjAnimJoint(joint)
	elif B(fp.is_have_translate_scale):
		var translate_scales2: Array = fp.attr.translate_scales
		for i in fp.joints.size():
			var joint: DObj = fp.joints[i]
			if joint != null:
				var parts = joint.user_data
				if (parts != null) and parts.is_have_anim:
					var anim_wait_bak: float = joint.anim_wait
					joint.anim_wait = AOBJ_ANIM_END
					ObjAnim.lbCommonPlayTranslateScaledDObjAnim(joint, translate_scales2[i] if i < translate_scales2.size() else Vector3.ONE)
					joint.anim_wait = anim_wait_bak
	else:
		for i in fp.joints.size():
			var joint: DObj = fp.joints[i]
			if joint != null:
				var parts = joint.user_data
				if (parts != null) and parts.is_have_anim:
					var anim_wait_bak: float = joint.anim_wait
					joint.anim_wait = AOBJ_ANIM_END
					ObjAnim.gcPlayDObjAnimJoint(joint)
					joint.anim_wait = anim_wait_bak

## 0x800E8518
static func ftParamClearAttackCollAll(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	for attack_coll in fp.attack_colls:
		attack_coll.attack_state = nGMAttackStateOff
	fp.is_attack_active = FALSE

## 0x800E853C
static func ftParamClearAttackRecordID(fp: Fighter, attack_id: int) -> void:
	for record in fp.attack_colls[attack_id].attack_records:
		record.victim_gobj = null
		record.victim_flags.is_interact_hurt = FALSE
		record.victim_flags.is_interact_shield = FALSE
		record.victim_flags.timer_rehit = 0
		record.victim_flags.group_id = 7

## 0x800E8668
static func ftParamRefreshAttackCollID(fighter_gobj, attack_id: int) -> void:
	var fp := ftGetStruct(fighter_gobj)
	fp.attack_colls[attack_id].attack_state = nGMAttackStateNew
	fp.is_attack_active = TRUE
	ftParamClearAttackRecordID(fp, attack_id)

## 0x800E86B4
static func ftParamSetVelPush(fighter_gobj, vel_push: Vector3) -> void:
	ftGetStruct(fighter_gobj).coll_data.vel_push = vel_push

## 0x800E86D4
static func ftParamGetJointID(fp: Fighter, joint_id: int) -> int:
	if joint_id == -2:
		joint_id = fp.attr.joint_itemlight_id
	return joint_id

## 0x800E86F0
static func ftParamLinkResetShieldModelParts(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	if (fp.fkind == nFTKindLink) or (fp.fkind == nFTKindNLink):
		ftParamSetModelPartDefaultID(fighter_gobj, 21, 0)
		ftParamSetModelPartDefaultID(fighter_gobj, 19, -1)

## 0x800E8744
static func ftParamSetHammerParams(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	if (fp.fkind == nFTKindLink) or (fp.fkind == nFTKindNLink):
		ftParamSetModelPartDefaultID(fighter_gobj, 21, -1)
		ftParamSetModelPartDefaultID(fighter_gobj, 19, 0)
	ftParamTryUpdateItemMusic()

## 0x800E87A0
static func ftParamSetHitStatusColAnim(fighter_gobj, hitstatus: int) -> void:
	match hitstatus:
		nGMHitStatusNormal:
			ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterHitStatusNormal, 0)
		nGMHitStatusInvincible:
			ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterHitStatusInvincible, 0)
		nGMHitStatusIntangible:
			ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterHitStatusIntangible, 0)

## 0x800E880C
static func ftParamSetHitStatusPartAll(fighter_gobj, hitstatus: int) -> void:
	var fp := ftGetStruct(fighter_gobj)
	for damage_coll in fp.damage_colls:
		if damage_coll.hitstatus != nGMHitStatusNone:
			damage_coll.hitstatus = hitstatus
	fp.is_hitstatus_nodamage = FALSE if (hitstatus == nGMHitStatusNormal) else TRUE
	ftParamSetHitStatusColAnim(fighter_gobj, hitstatus)

## 0x800E8884
static func ftParamSetHitStatusPartID(fighter_gobj, joint_id: int, hitstatus: int) -> void:
	var fp := ftGetStruct(fighter_gobj)
	for damage_coll in fp.damage_colls:
		if (damage_coll.hitstatus != nGMHitStatusNone) and (joint_id == damage_coll.joint_id):
			damage_coll.hitstatus = hitstatus
			if damage_coll.hitstatus != nGMHitStatusNormal:
				fp.is_hitstatus_nodamage = TRUE
			return

## 0x800E8A24
static func ftParamSetHitStatusAll(fighter_gobj, hitstatus: int) -> void:
	var fp := ftGetStruct(fighter_gobj)
	fp.hitstatus = hitstatus
	ftParamSetHitStatusColAnim(fighter_gobj, hitstatus)

## 0x800E8A48
static func ftParamGetBestHitStatusPart(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var hitstatus_base: int = fp.hitstatus
	var hitstatus_best: int = fp.damage_colls[0].hitstatus
	if hitstatus_best != nGMHitStatusNormal:
		for i in range(1, fp.damage_colls.size()):
			var damage_coll: FTDamageColl = fp.damage_colls[i]
			if damage_coll.hitstatus == nGMHitStatusNone:
				break
			elif hitstatus_best > damage_coll.hitstatus:
				hitstatus_best = damage_coll.hitstatus
	if hitstatus_base < hitstatus_best:
		hitstatus_base = hitstatus_best
	return hitstatus_base

## 0x800E8AAC
static func ftParamGetBestHitStatusAll(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var hitstatus_best: int = ftParamGetBestHitStatusPart(fighter_gobj)
	if hitstatus_best < fp.star_hitstatus:
		hitstatus_best = fp.star_hitstatus
	if hitstatus_best < fp.special_hitstatus:
		hitstatus_best = fp.special_hitstatus
	return hitstatus_best

## 0x800E8B00
static func ftParamResetFighterDamageCollsAll(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var descs: Array = fp.attr.damage_coll_descs
	var n: int = (fp.damage_colls.size() + 11) / 2
	for i in n:
		if i >= descs.size():
			break
		var damage_coll_desc = descs[i]
		if damage_coll_desc.joint_id != -1:
			var damage_coll: FTDamageColl = fp.damage_colls[i]
			damage_coll.joint_id = damage_coll_desc.joint_id
			damage_coll.joint = fp.joints[damage_coll.joint_id]
			damage_coll.placement = damage_coll_desc.placement
			damage_coll.is_grabbable = damage_coll_desc.is_grabbable
			damage_coll.offset = damage_coll_desc.offset
			damage_coll.size = damage_coll_desc.size * 0.5
	fp.is_damage_coll_modify = FALSE

## 0x800E8BC8
static func ftParamModifyDamageCollID(fighter_gobj, joint_id: int, offset: Vector3, size: Vector3) -> void:
	var fp := ftGetStruct(fighter_gobj)
	for damage_coll in fp.damage_colls:
		if joint_id == damage_coll.joint_id:
			damage_coll.offset = offset
			damage_coll.size = size * 0.5
			fp.is_damage_coll_modify = TRUE
			return

# ---------------------------------------------------------------------------
# Model / texture parts (visual bookkeeping read by the renderer)
# ---------------------------------------------------------------------------
## 0x800E8C70
static func ftParamSetModelPartID(fighter_gobj, joint_id: int, modelpart_id: int) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var idx: int = joint_id - nFTPartsJointCommonStart
	if idx < 0 or idx >= fp.modelpart_status.size():
		return
	var ms = fp.modelpart_status[idx]
	if modelpart_id == -1:
		ms.modelpart_id_curr = -1
	else:
		ms.modelpart_id_curr = modelpart_id
	fp.is_modelpart_modify = TRUE

## 0x800E8EAC
static func ftParamSetModelPartDefaultID(fighter_gobj, joint_id: int, modelpart_id: int) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var idx: int = joint_id - nFTPartsJointCommonStart
	if idx < 0 or idx >= fp.modelpart_status.size():
		return
	fp.modelpart_status[idx].modelpart_id_base = modelpart_id
	ftParamSetModelPartID(fighter_gobj, joint_id, modelpart_id)
	fp.is_modelpart_modify = TRUE

## 0x800E8ECC
static func ftParamResetModelPartAll(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	for ms in fp.modelpart_status:
		ms.modelpart_id_curr = ms.modelpart_id_base
	fp.is_modelpart_modify = FALSE

## 0x800E8FC4
static func ftParamHideModelPartAll(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	for ms in fp.modelpart_status:
		ms.modelpart_id_curr = -1
	fp.is_modelpart_modify = TRUE

## 0x800E9038
static func ftParamSetModelPartDetailAll(fighter_gobj, detail: int) -> void:
	var fp := ftGetStruct(fighter_gobj)
	if detail != fp.detail_curr:
		fp.detail_curr = detail
		for i in range(nFTPartsJointCommonStart, fp.joints.size()):
			var joint: DObj = fp.joints[i]
			if joint != null:
				var modelpart_id: int = fp.modelpart_status[i - nFTPartsJointCommonStart].modelpart_id_curr
				if modelpart_id == -1:
					continue
				else:
					fp.modelpart_status[i - nFTPartsJointCommonStart].modelpart_id_curr = -1
					ftParamSetModelPartID(fighter_gobj, i, modelpart_id)
		ftParamInitTexturePartAll(fighter_gobj)

## 0x800E90F8
static func ftParamInitAllParts(fighter_gobj, costume: int, shade: int) -> void:
	pass

## 0x800E9248
static func ftParamInitTexturePartAll(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	for t in fp.texturepart_status:
		t.texture_id_curr = t.texture_id_base

## 0x800E92E4
static func ftParamSetTexturePartID(fighter_gobj, texturepart_id: int, texture_id: int) -> void:
	var fp := ftGetStruct(fighter_gobj)
	if texturepart_id >= 0 and texturepart_id < fp.texturepart_status.size():
		fp.texturepart_status[texturepart_id].texture_id_curr = texture_id
		fp.is_texturepart_modify = TRUE

## 0x800E9380
static func ftParamResetTexturePartAll(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	for t in fp.texturepart_status:
		t.texture_id_curr = t.texture_id_base
	fp.is_texturepart_modify = FALSE

# ---------------------------------------------------------------------------
# Colour animations (priority logic is gameplay-visible through colanim_id checks)
# ---------------------------------------------------------------------------
## 0x800E974C
static func ftParamCheckSetColAnimID(colanim, colanim_id: int, length: int) -> int:
	if _colanim_priority(colanim_id) >= _colanim_priority(colanim.colanim_id):
		colanim.colanim_id = colanim_id
		colanim.length = length
		var nm = Gmcolscripts.DESCS[colanim_id][0] if (colanim_id >= 0 and colanim_id < Gmcolscripts.DESCS.size()) else null
		colanim.cs[0].p_script = [nm, 0] if nm != null else null
		colanim.cs[0].color_event_timer = 0
		colanim.cs[0].script_id = 0
		for i in range(1, colanim.cs.size()):
			colanim.cs[i].p_script = null
		colanim.is_use_color1 = 0
		colanim.is_use_light = 0
		colanim.is_use_color2 = 0
		colanim.skeleton_id = 0
		return TRUE
	return FALSE

## 0x800E9814
static func ftParamCheckSetFighterColAnimID(fighter_gobj, colanim_id: int, length: int) -> int:
	return ftParamCheckSetColAnimID(ftGetStruct(fighter_gobj).colanim, colanim_id, length)

## 0x800E9838
static func ftParamResetColAnim(colanim) -> void:
	for i in colanim.cs.size():
		colanim.cs[i].p_script = null
	colanim.length = 0
	colanim.colanim_id = 0
	colanim.is_use_color1 = 0
	colanim.is_use_light = 0
	colanim.is_use_color2 = 0
	colanim.skeleton_id = 0

## 0x800E98B0
static func ftParamResetFighterColAnim(fighter_gobj) -> void:
	ftParamResetColAnim(ftGetStruct(fighter_gobj).colanim)

## 0x800E98D4
static func ftParamResetStatUpdateColAnim(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	ftParamResetFighterColAnim(fighter_gobj)
	match ftParamGetBestHitStatusPart(fighter_gobj):
		nGMHitStatusInvincible:
			ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterHitStatusInvincible, 0)
		nGMHitStatusIntangible:
			ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterHitStatusIntangible, 0)
	match fp.fkind:
		nFTKindDonkey, nFTKindNDonkey, nFTKindGDonkey:
			if fp.passive_vars.donkey.charge_level == FTDONKEY_GIANTPUNCH_CHARGE_MAX:
				ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterCommonSpecialNCharge, 0)
		nFTKindSamus, nFTKindNSamus:
			if fp.passive_vars.samus.charge_level == FTSAMUS_CHARGE_MAX:
				ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterCommonSpecialNCharge, 0)
		nFTKindKirby:
			if (fp.passive_vars.kirby.copy_id == nFTKindSamus) or (fp.passive_vars.kirby.copy_id == nFTKindNSamus):
				if fp.passive_vars.kirby.copysamus_charge_level == FTKIRBY_COPYSAMUS_CHARGE_MAX:
					ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterCommonSpecialNCharge, 0)
			if (fp.passive_vars.kirby.copy_id == nFTKindDonkey) or (fp.passive_vars.kirby.copy_id == nFTKindNDonkey) or (fp.passive_vars.kirby.copy_id == nFTKindGDonkey):
				if fp.passive_vars.kirby.copydonkey_charge_level == FTKIRBY_COPYDONKEY_GIANTPUNCH_CHARGE_MAX:
					ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterCommonSpecialNCharge, 0)
		nFTKindNess, nFTKindNNess:
			if B(fp.is_absorb):
				ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterNessSpecialLwHold, 0)
	if fp.damage_heal != 0:
		ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterHeal, 0)
	if fp.star_invincible_tics != 0:
		ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterStar, 0)
	if (fp.invincible_tics != 0) or (fp.intangible_tics != 0):
		ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterNoDamage, 0)
	if Fthammer.ftHammerCheckStatusHammerAll(fighter_gobj) != FALSE:
		ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterHammer, 0)

## 0x800E9AF4
static func ftParamCheckSetSkeletonColAnimID(fighter_gobj, damage_level: int) -> int:
	var fp := ftGetStruct(fighter_gobj)
	return ftParamCheckSetFighterColAnimID(fighter_gobj, dFTParamSkeletonColAnimIDs[fp.fkind] + damage_level, 0)

## 0x800E9B30
static func ftParamSetKey(fighter_gobj, script) -> void:
	var fp := ftGetStruct(fighter_gobj)
	fp.key.input_wait = 0
	fp.key.key_script = script
	fp.key.script_index = 0

## 0x800E9B40
static func ftParamCheckHaveKey(fighter_gobj) -> int:
	return TRUE if ftGetStruct(fighter_gobj).key.key_script != null else FALSE

# ---------------------------------------------------------------------------
# Effects attached to the fighter (visual)
# ---------------------------------------------------------------------------
static func ftParamRunProcEffect(fighter_gobj, proc: Callable) -> void:
	pass

static func ftParamStopEffect(effect_gobj, ep) -> void:
	pass

## 0x800E9C3C
static func ftParamProcStopEffect(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	fp.is_effect_attach = FALSE

static func ftParamPauseEffect(effect_gobj, ep) -> void:
	pass

static func ftParamProcPauseEffect(effect_gobj) -> void:
	pass

static func ftParamResumeEffect(effect_gobj, ep) -> void:
	pass

static func ftParamProcResumeEffect(fighter_gobj) -> void:
	pass

# ---------------------------------------------------------------------------
# Damage / knockback core
# ---------------------------------------------------------------------------
## 0x800E9CE8
static func ftParamVelDamageTransferGround(fp: Fighter) -> void:
	if fp.ga == nMPKineticsGround:
		var floor_angle: Vector3 = fp.coll_data.floor_angle
		if fp.physics.vel_damage_ground == 0.0:
			fp.physics.vel_damage_ground = fp.physics.vel_damage_air.x
			if fp.physics.vel_damage_ground > 250.0:
				fp.physics.vel_damage_ground = 250.0
			if fp.physics.vel_damage_ground < -250.0:
				fp.physics.vel_damage_ground = -250.0
			fp.physics.vel_damage_air.x = floor_angle.y * fp.physics.vel_damage_ground
			fp.physics.vel_damage_air.y = -floor_angle.x * fp.physics.vel_damage_ground

static func _handicap(handicap: int, col: int) -> float:
	return Ftcommondata.dFTCommonDataHandicapTable[handicap - 1][col]

## Knockback core evaluated exactly like the IDO single-precision code: every * and + rounds to f32,
## left to right (verified against the shipped PC-port binary with REA: BattleShip.exe FUN_1400a5430).
static func _ftParamKnockbackCore(percent_damage: int, recent_damage: int, hit_damage: int, knockback_weight: int, knockback_scale: int, knockback_base: int, weight: float, damage_ratio_term: float, attack_handicap: int, defend_handicap: int) -> float:
	var kb: float
	if knockback_weight != 0:
		kb = f32(f32(10.0 * knockback_weight) * f32(0.05))
		kb = f32(1.0 + kb)
	else:
		var damage_add: float = f32(float(percent_damage + recent_damage))
		var a: float = f32(damage_add * f32(0.1))
		var b: float = f32(f32(damage_add * float(hit_damage)) * f32(0.05))
		kb = f32(a + b)
	kb = f32(f32(kb * weight) * f32(1.4))
	kb = f32(kb + 18.0)
	kb = f32(kb * f32(float(knockback_scale) * f32(0.01)))
	kb = f32(kb + float(knockback_base))
	kb = f32(kb * damage_ratio_term)
	kb = f32(kb * _handicap(attack_handicap, 0))
	kb = f32(kb * _handicap(defend_handicap, 1))
	return kb

## 0x800E9D78
static func ftParamGetCommonKnockback(percent_damage: int, recent_damage: int, hit_damage: int, knockback_weight: int, knockback_scale: int, knockback_base: int, weight: float, attack_handicap: int, defend_handicap: int) -> float:
	var damage_ratio_term: float = f32(float(G.gSCManagerBattleState.damage_ratio) * f32(0.01))
	var knockback: float = _ftParamKnockbackCore(percent_damage, recent_damage, hit_damage, knockback_weight, knockback_scale, knockback_base, weight, damage_ratio_term, attack_handicap, defend_handicap)
	if knockback >= 2500.0:
		knockback = 2500.0
	if G.gSCManagerBackupData.error_flags & LBBACKUP_ERROR_RANDOMKNOCKBACK:
		knockback = f32(syUtilsRandFloat() * 200.0)
	return knockback

## 0x800E9FC0 - Used by Barrel Cannon on Kongo Jungle (REGION_US): same formula with a damage ratio of 1
static func ftParamGetGroundHazardKnockback(percent_damage: int, recent_damage: int, hit_damage: int, knockback_weight: int, knockback_scale: int, knockback_base: int, weight: float, attack_handicap: int, defend_handicap: int) -> float:
	var knockback: float = _ftParamKnockbackCore(percent_damage, recent_damage, hit_damage, knockback_weight, knockback_scale, knockback_base, weight, 1.0, attack_handicap, defend_handicap)
	if knockback >= 2500.0:
		knockback = 2500.0
	if G.gSCManagerBackupData.error_flags & LBBACKUP_ERROR_RANDOMKNOCKBACK:
		knockback = f32(syUtilsRandFloat() * 200.0)
	return knockback

## 0x800EA1B0
static func ftParamGetHitStun(knockback: float) -> float:
	return f32(knockback / 1.875)

## 0x800EA1C0 (REGION_US: +5)
static func ftParamGetHitLag(damage: int, status_id: int, hitlag_mul: float) -> int:
	var hitlag_tics: int = int(int((damage * (1.0 / 3.0)) + 5.0) * hitlag_mul)
	if (status_id == nFTCommonStatusSquat) or (status_id == nFTCommonStatusSquatWait):
		hitlag_tics = int(hitlag_tics * (2.0 / 3.0))
	return hitlag_tics

## 0x800EA248
static func ftParamUpdateDamage(fp: Fighter, damage: int) -> void:
	fp.percent_damage += damage
	G.gSCManagerBattleState.players[fp.player].total_damage_all += damage
	if fp.percent_damage > 999:
		fp.percent_damage = 999
	G.gSCManagerBattleState.players[fp.player].stock_damage_all = fp.percent_damage
	if fp.item_gobj != null:
		if (fp.damage_knockback != 0.0) and ((fp.hitlag_tics == 0) or not B(fp.is_knockback_paused) or not (fp.damage_knockback < (fp.damage_knockback_stack + 30.0))):
			var ip := itGetStruct(fp.item_gobj)
			if (ip.weight != nITWeightHeavy) or ((fp.fkind != nFTKindDonkey) and (fp.fkind != nFTKindNDonkey) and (fp.fkind != nFTKindGDonkey)):
				if (damage > syUtilsRandIntRange(60)) or ((Itmain.itMainCheckShootNoAmmo(fp.item_gobj) != FALSE) and (syUtilsRandIntRange(2) == 0)):
					# ftSetupDropItem(fp)
					Itmain.itMainSetFighterDrop(fp.item_gobj, Vector3.ZERO, 1.0)

## 0x800EA3D4
static func ftParamSetHealDamage(fp: Fighter, heal: int) -> void:
	fp.damage_heal += heal
	ftParamCheckSetFighterColAnimID(fp.fighter_gobj, nGMColAnimFighterHeal, 0)

## 0x800EA40C - If fighter is grabbed, halve damage received
static func ftParamGetCapturedDamage(fp: Fighter, damage: int) -> int:
	if fp.capture_gobj != null:
		damage = int((damage * 0.5) + 0.999)
	return int((damage * fp.damage_mul) + 0.999)

## 0x800EA470
static func ftParamGetStale(player: int, attack_id: int, motion_count: int) -> float:
	var pl = G.gSCManagerBattleState.players[player]
	var stale_id: int = pl.stale_id
	if attack_id != nFTMotionAttackIDNone:
		var n: int = pl.stale_info.size()
		var start_array_id: int = (stale_id - 1) if (stale_id != 0) else (n - 1)
		var current_array_id: int = start_array_id
		var i := 0
		while i < dFTParamStaleTable.size():
			if attack_id == pl.stale_info[current_array_id].attack_id:
				if motion_count != pl.stale_info[current_array_id].motion_count:
					return dFTParamStaleTable[i]
				elif current_array_id == start_array_id:
					i -= 1
			current_array_id = (current_array_id - 1) if (current_array_id != 0) else (n - 1)
			i += 1
	return 1.0

## 0x800EA54C
static func ftParamGetStaledDamage(player: int, damage: int, attack_id: int, motion_count: int) -> int:
	var stale: float = ftParamGetStale(player, attack_id, motion_count)
	if stale != 1.0:
		damage = int((damage * stale) + 0.999)
	return damage

## 0x800EA5BC
static func ftParamGetMotionCount() -> int:
	var motion_count: int = Ftmanager.gFTManagerMotionCount
	Ftmanager.gFTManagerMotionCount = (Ftmanager.gFTManagerMotionCount + 1) & 0xFFFF
	if Ftmanager.gFTManagerMotionCount == 0:
		Ftmanager.gFTManagerMotionCount = 1
	return motion_count

## 0x800EA5E8
static func ftParamSetMotionID(fp: Fighter, attack_id: int) -> void:
	fp.motion_attack_id = attack_id
	fp.motion_count = ftParamGetMotionCount()

## 0x800EA614
static func ftParamUpdateStaleQueue(attack_player: int, defend_player: int, attack_id: int, motion_count: int) -> void:
	if (attack_player != G.gSCManagerBattleState.players.size()) and (attack_player != defend_player):
		var pl = G.gSCManagerBattleState.players[attack_player]
		var stale_id: int = pl.stale_id
		for i in pl.stale_info.size():
			if (attack_id == pl.stale_info[i].attack_id) and (motion_count == pl.stale_info[i].motion_count):
				return
		pl.stale_info[stale_id].attack_id = attack_id
		pl.stale_info[stale_id].motion_count = motion_count
		if stale_id == (pl.stale_info.size() - 1):
			pl.stale_id = 0
		else:
			pl.stale_id = stale_id + 1

## 0x800EA74C
static func ftParamGetStatUpdateCount() -> int:
	var update_count: int = Ftmanager.gFTManagerStatUpdateCount
	Ftmanager.gFTManagerStatUpdateCount = (Ftmanager.gFTManagerStatUpdateCount + 1) & 0xFFFF
	if Ftmanager.gFTManagerStatUpdateCount == 0:
		Ftmanager.gFTManagerStatUpdateCount = 1
	return update_count

## 0x800EA778
static func ftParamSetStatUpdate(fp: Fighter, flags: int) -> void:
	fp.stat_flags = GMStatFlags.from_halfword(flags)
	fp.stat_count = ftParamGetStatUpdateCount()

## 0x800EA7B0 - 1P Game bonus statistics (no effect in VS mode)
static func ftParamUpdate1PGameAttackStats(fp: Fighter, flags: int) -> void:
	var stat_flags := GMStatFlags.from_halfword(flags)
	if (fp.pkind != nFTPlayerKindDemo) and (G.gSCManagerBattleState.game_type == nSCBattleGameType1PGame) and (fp.player == G.gSCManagerSceneData.player):
		if (fp.stat_flags.attack_id != nFTStatusAttackIDNone) and (fp.stat_flags.attack_id != stat_flags.attack_id):
			if fp.stat_flags.attack_id < G.gSC1PGameBonusAttackIDCount.size():
				G.gSC1PGameBonusAttackIDCount[fp.stat_flags.attack_id] += 1
			G.gSC1PGameBonusAttackIsSmashCount[fp.stat_flags.is_smash_attack] += 1
			G.gSC1PGameBonusAttackGroundAirCount[fp.stat_flags.ga] += 1
			G.gSC1PGameBonusAttackIsProjectileCount[fp.stat_flags.is_projectile] += 1

## 0x800EA8B0
static func ftParamSetStarHitStatusInvincible(fp: Fighter, star_invincible_tics: int) -> void:
	fp.star_hitstatus = nGMHitStatusInvincible
	fp.star_invincible_tics = star_invincible_tics
	ftParamCheckSetFighterColAnimID(fp.fighter_gobj, nGMColAnimFighterStar, 0)

## 0x800EA8EC
static func ftParamSetTimedHitStatusInvincible(fp: Fighter, invincible_tics: int) -> void:
	if fp.invincible_tics < invincible_tics:
		fp.invincible_tics = invincible_tics
	if fp.intangible_tics != 0:
		fp.special_hitstatus = nGMHitStatusIntangible
	else:
		fp.special_hitstatus = nGMHitStatusInvincible
	ftParamCheckSetFighterColAnimID(fp.fighter_gobj, nGMColAnimFighterNoDamage, 0)

## 0x800EA948
static func ftParamSetTimedHitStatusIntangible(fp: Fighter, intangible_tics: int) -> void:
	if fp.intangible_tics < intangible_tics:
		fp.intangible_tics = intangible_tics
	fp.special_hitstatus = nGMHitStatusIntangible
	ftParamCheckSetFighterColAnimID(fp.fighter_gobj, nGMColAnimFighterNoDamage, 0)

## 0x800EA98C
static func ftParamUpdatePlayerBattleStats(attack_player: int, defend_player: int, attack_damage: int) -> void:
	if (attack_player != GMCOMMON_PLAYERS_MAX) and (attack_player != defend_player):
		var bs = G.gSCManagerBattleState
		bs.players[attack_player].total_damage_given += attack_damage
		bs.players[defend_player].total_damage_players[attack_player] += attack_damage
		bs.players[defend_player].combo_damage_foe += attack_damage
		bs.players[defend_player].combo_count_foe += 1

## 0x800EAA2C
static func ftParamUpdate1PGameDamageStats(fp: Fighter, damage_player: int, damage_object_class: int, damage_object_kind: int, flags: int, damage_stat_count: int) -> void:
	fp.damage_player = damage_player
	fp.damage_object_class = damage_object_class
	fp.damage_object_kind = damage_object_kind
	fp.damage_count = (fp.damage_count + 1) & 0xFFFF
	if (damage_stat_count == 0) or (fp.damage_stat_count != damage_stat_count):
		fp.damage_stat_flags = GMStatFlags.from_halfword(flags)
		fp.damage_stat_count = damage_stat_count
		if G.gSCManagerBattleState.game_type == nSCBattleGameType1PGame:
			if (G.gSCManagerSceneData.player == damage_player) and (fp.damage_stat_flags.attack_id != nFTStatusAttackIDNone):
				if fp.damage_stat_flags.attack_id < G.gSC1PGameBonusDefendIDCount.size():
					G.gSC1PGameBonusDefendIDCount[fp.damage_stat_flags.attack_id] += 1
				G.gSC1PGameBonusDefendIsSmashCount[fp.damage_stat_flags.is_smash_attack] += 1
				G.gSC1PGameBonusDefendGroundAirCount[fp.damage_stat_flags.ga] += 1
				G.gSC1PGameBonusDefendIsProjectileCount[fp.damage_stat_flags.is_projectile] += 1

## 0x800EAB40
static func ftParamGetEffectJointPosition(fp: Fighter) -> Vector3:
	var attr = fp.attr
	fp.effect_joint_array_id += 1
	if fp.effect_joint_array_id == attr.effect_joint_ids.size():
		fp.effect_joint_array_id = 0
	return Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[attr.effect_joint_ids[fp.effect_joint_array_id]], Vector3.ZERO)

## Visual effect sink: Callable(fighter_gobj, effect_id, joint_id, world_pos, scatter, lr, flag) -> effect or null
static var effect_hook: Callable = Callable()

## 0x800EABDC - effects are visual: compute the world position like C and hand it to the effect layer.
static func ftParamMakeEffect(fighter_gobj, effect_id: int, joint_id: int, effect_pos = null, effect_scatter = null, lr: int = 0, is_scale_pos: int = 0, arg7: int = 0):
	# effect_pos / effect_scatter: Vector3 or null (C: Vec3f* that may be NULL)
	var fp := ftGetStruct(fighter_gobj)
	var pos := Vector3.ZERO
	var effect = null
	if effect_id == nEFKindChargeSparkle:
		match fp.fkind:
			nFTKindSamus:
				joint_id = FTSAMUS_CHARGE_EFFECT_JOINT
				effect_pos = Vector3(180.0, 0.0, 0.0)
			nFTKindDonkey:
				joint_id = FTDONKEY_CHARGE_EFFECT_JOINT
				effect_pos = Vector3(100.0, 0.0, 0.0)
			nFTKindKirby:
				joint_id = FTKIRBY_CHARGE_EFFECT_JOINT
				effect_pos = Vector3(50.0, 0.0, 0.0)
			nFTKindGDonkey:
				joint_id = FTDONKEY_CHARGE_EFFECT_JOINT
				effect_pos = Vector3(100.0, 0.0, 0.0)
			_:
				# C: effect_pos = &effect_pos_mod (uninitialised local) for other fighters
				effect_pos = Vector3.ZERO
	if joint_id != -1:
		if effect_pos != null:
			pos = effect_pos
		else:
			pos = Vector3.ZERO
		if effect_scatter != null:
			if effect_scatter.x != 0:
				pos.x += (syUtilsRandFloat() - 0.5) * (effect_scatter.x * 2.0)
			if effect_scatter.y != 0:
				pos.y += (syUtilsRandFloat() - 0.5) * (effect_scatter.y * 2.0)
			if effect_scatter.z != 0:
				pos.z += (syUtilsRandFloat() - 0.5) * (effect_scatter.z * 2.0)
		if is_scale_pos != FALSE:
			var scale: float = 1.0 / fp.attr.size
			pos.x *= scale
			pos.y *= scale
			pos.z *= scale
		pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[joint_id], pos)
	match effect_id:
		nEFKindDamageNormal:
			pos = ftParamGetEffectJointPosition(fp)
			effect = Efmanager.efManagerDamageNormalLightMakeEffect(pos, fp.player, 10, FALSE)
		nEFKindFlameLR:
			pos = ftParamGetEffectJointPosition(fp)
			effect = Efmanager.efManagerFlameLRMakeEffect(pos, lr)
		nEFKindFlameRandom:
			pos = ftParamGetEffectJointPosition(fp)
			effect = Efmanager.efManagerFlameRandomMakeEffect(pos)
		nEFKindFlameStatic:
			pos = ftParamGetEffectJointPosition(fp)
			effect = Efmanager.efManagerFlameStaticMakeEffect(pos)
		nEFKindShockSmall:
			pos = ftParamGetEffectJointPosition(fp)
			effect = Efmanager.efManagerShockSmallMakeEffect(pos)
		nEFKindDustLight:
			effect = Efmanager.efManagerDustLightMakeEffect(pos, lr, 1.0)
		nEFKindDustLightRapid:
			effect = Efmanager.efManagerDustLightMakeEffect(pos, lr, 2.0)
		nEFKindDustHeavyDouble:
			effect = Efmanager.efManagerDustHeavyDoubleMakeEffect(pos, lr, 1.0)
		nEFKindDustHeavyDoubleRapid:
			effect = Efmanager.efManagerDustHeavyDoubleMakeEffect(pos, lr, 1.7)
		nEFKindDustHeavy:
			effect = Efmanager.efManagerDustHeavyMakeEffect(pos, lr)
		nEFKindDustHeavyReverse:
			effect = Efmanager.efManagerDustHeavyMakeEffect(pos, -lr)
		nEFKindDustExpandLarge:
			pos.x += ((syUtilsRandFloat() * 160.0) - 80.0)
			pos.y += ((syUtilsRandFloat() * 160.0) - 80.0)
			effect = Efmanager.efManagerDustExpandLargeMakeEffect(pos)
		nEFKindDustExpandSmall:
			effect = Efmanager.efManagerDustExpandSmallMakeEffect(pos, 1.0)
		nEFKindDustDashSmall:
			effect = Efmanager.efManagerDustDashMakeEffect(pos, lr, 1.0)
		nEFKindDustDashLarge:
			effect = Efmanager.efManagerDustDashMakeEffect(pos, lr, 1.5)
		nEFKindDamageFlyOrbs:
			effect = Efmanager.efManagerDamageSpawnOrbsMakeEffect(pos)
		nEFKindImpactWave:
			if (fp.ga == nMPKineticsGround) and (fp.coll_data.floor_line_id != -1) and (fp.coll_data.floor_line_id != -2):
				effect = Efmanager.efManagerImpactWaveMakeEffect(pos, 4, syUtilsArcTan2(-fp.coll_data.floor_angle.x, fp.coll_data.floor_angle.y))
			else:
				effect = Efmanager.efManagerImpactAirWaveMakeEffect(pos, 4)
		nEFKindStarRodSpark:
			effect = Efmanager.efManagerStarRodSparkMakeEffect(pos, -lr)
		nEFKindDamageFlySparks:
			effect = Efmanager.efManagerDamageSpawnSparksMakeEffect(pos, lr)
		nEFKindDamageFlySparksReverse:
			effect = Efmanager.efManagerDamageSpawnSparksMakeEffect(pos, -lr)
		nEFKindDamageFlyMDust:
			effect = Efmanager.efManagerDamageSpawnMDustMakeEffect(pos, lr)
		nEFKindDamageFlyMDustReverse:
			effect = Efmanager.efManagerDamageSpawnMDustMakeEffect(pos, -lr)
		nEFKindSparkleWhite:
			effect = Efmanager.efManagerSparkleWhiteMakeEffect(pos)
		nEFKindSparkleWhiteMultiExplode:
			effect = Efmanager.efManagerSparkleWhiteMultiExplodeMakeEffect(pos)
		nEFKindSparkleWhiteMulti:
			effect = Efmanager.efManagerSparkleWhiteMultiMakeEffect(pos)
		nEFKindSparkleWhiteScale:
			effect = Efmanager.efManagerSparkleWhiteScaleMakeEffect(pos, 1.0)
		nEFKindQuakeMag0:
			if fp.pkind != nFTPlayerKindDemo:
				effect = Efmanager.efManagerQuakeMakeEffect(0)
		nEFKindQuakeMag1:
			if fp.pkind != nFTPlayerKindDemo:
				effect = Efmanager.efManagerQuakeMakeEffect(1)
		nEFKindQuakeMag2:
			if fp.pkind != nFTPlayerKindDemo:
				effect = Efmanager.efManagerQuakeMakeEffect(2)
		nEFKindPsionic:
			effect = Efmanager.efManagerPsionicMakeEffect(pos)
		nEFKindFlashSmall:
			effect = Efmanager.efManagerFlashSmallMakeEffect(pos)
		nEFKindFlashMiddle:
			effect = Efmanager.efManagerFlashMiddleMakeEffect(pos)
		nEFKindFlashLarge:
			effect = Efmanager.efManagerFlashLargeMakeEffect(pos)
		nEFKindFuraSparkle:
			effect = Efmanager.efManagerFuraSparkleMakeEffect(pos)
		nEFKindKirbyStar:
			effect = Efmanager.efManagerKirbyStarMakeEffect(pos)
		nEFKindCrashTheGame:
			effect = Efmanager.func_ovl2_8010183C(pos, arg7)
		nEFKindChargeSparkle:
			var pc = Efmanager.efManagerSparkleWhiteScaleMakeEffect(pos, 0.7)
			if pc != null and pc is Object and "primcolor" in pc:
				pc.primcolor.a = 0xC0
		nEFKindThunderAmp:
			effect = Efmanager.efManagerThunderAmpMakeEffect(pos)
		nEFKindRipple:
			effect = Efmanager.efManagerRippleMakeEffect(pos)
		0x4C:
			effect = Efmanager.func_ovl2_801031E0(pos)
		0x4D:
			effect = Efmanager.func_ovl2_80103280(pos)
		nEFKindHealSparkles:
			effect = Efmanager.efManagerHealSparklesMakeEffect(pos)
		nEFKindBoxSmash:
			Itbox.itBoxContainerSmashMakeEffect(pos)
		nEFKindMusicNote:
			Efmanager.efManagerMusicNoteMakeEffect(pos)
		nEFKindEggBreak:
			Efmanager.efManagerEggBreakMakeEffect(pos)
		nEFKindYoshiEggEscape:
			if fp.fkind == nFTKindYoshi:
				Efmanager.efManagerYoshiEggEscapeMakeEffect(fighter_gobj)
		nEFKindFireSpark:
			Efmanager.efManagerFireSparkMakeEffect(fighter_gobj)
	# Port-only visual hook (render/EffectLayer); never alters game state.
	if effect_hook.is_valid():
		effect_hook.call(fighter_gobj, effect_id, joint_id, pos, effect_scatter, lr, arg7)
	return effect

## 0x800EB0E8 - Kirby star trail on landing (visual)
static func ftParamKirbyTryMakeMapStarEffect(fighter_gobj) -> void:
	pass

# ---------------------------------------------------------------------------
# Transform caches
# ---------------------------------------------------------------------------
static func _next_from_root(current: DObj, root_dobj: DObj) -> DObj:
	if current.child != null:
		return current.child
	elif current == root_dobj:
		return null
	elif current.sib_next != null:
		return current.sib_next
	while true:
		var parent: DObj = current.parent
		if root_dobj == parent:
			return null
		elif parent.sib_next != null:
			return parent.sib_next
		current = parent
	return null

## 0x800EB528
static func ftParamsUpdateFighterPartsTransformAll(root_dobj: DObj) -> void:
	var parts = root_dobj.user_data
	if parts != null:
		if parts.transform_update_mode == 1:
			parts.transform_update_mode = 0
		parts.clear_word()
	var current: DObj = root_dobj.child
	while current != null:
		var current_parts = current.user_data
		if current_parts != null:
			current_parts.clear_word()
		current = _next_from_root(current, root_dobj)

## 0x800EB648
static func ftParamsUpdateFighterPartsTransform(root_dobj: DObj) -> void:
	var current: DObj = root_dobj
	while current != null:
		var parts = current.user_data
		if parts != null:
			if parts.transform_update_mode == 1:
				parts.transform_update_mode = 0
			parts.clear_word()
		current = _next_from_root(current, root_dobj)

## 0x800EB6EC
static func ftParamSetAnimLocks(fp: Fighter) -> void:
	var animlock: Array = fp.attr.animlock
	var flags0: int = int(animlock[0]) & 0xFFFFFFFF
	var flags1: int = int(animlock[1]) & 0xFFFFFFFF
	var i: int = nFTPartsJointCommonStart
	while (flags0 != 0) or (flags1 != 0):
		var current_flags: int = flags0 if (i < (fp.joints.size() - 1)) else flags1
		if current_flags & (1 << 31):
			if i < fp.joints.size() and fp.joints[i] != null:
				var parts = fp.joints[i].user_data
				if parts != null:
					parts.unk_dobjtrans_0x10 = Gmcollision.gmCollisionTransformMatrixAll(fp.joints[i], parts, parts.unk_dobjtrans_0x10)
					parts.transform_update_mode = 3
					fp.joints[i].xobj_unk05 = 1
		if i < fp.joints.size() - 1:
			flags0 = (flags0 << 1) & 0xFFFFFFFF
		else:
			flags1 = (flags1 << 1) & 0xFFFFFFFF
		i += 1
		if i > 64:
			break

## 0x800EB7F4
static func ftParamClearAnimLocks(fp: Fighter) -> void:
	for joint in fp.joints:
		if joint != null:
			var parts = joint.user_data
			if parts != null:
				if parts.transform_update_mode == 3:
					parts.transform_update_mode = 0
					joint.xobj_unk05 = 0

# ---------------------------------------------------------------------------
# Camera projection helpers (magnifying glass) and costumes - render side
# ---------------------------------------------------------------------------
## 0x800EB924 - project a world position to screen space with the camera matrix (Mtx44f as
## 16 floats row-major mtx[r][c] = mtx[r * 4 + c]). Returns {"rx", "ry"}.
static func func_ovl2_800EB924(cobj, mtx, vec, rx = null, ry = null):
	var x: float = vec.x
	var y: float = vec.y
	var z: float = vec.z
	var tempx: float = ((mtx[0] * x) + (mtx[4] * y) + (mtx[8] * z)) + mtx[12]
	var tempy: float = ((mtx[1] * x) + (mtx[5] * y) + (mtx[9] * z)) + mtx[13]
	var scale: float = ((mtx[3] * x) + (mtx[7] * y) + (mtx[11] * z)) + mtx[15]
	if ABSF(scale) < 0.1:
		scale = -0.1 if (scale < 0.0) else 0.1
	scale = 1.0 / scale
	var vscale: Array = cobj.viewport.vp.vscale
	return {
		"rx": (float(int(vscale[0]) / 4)) * (tempx * scale),
		"ry": (float(int(vscale[1]) / 4)) * (tempy * scale),
	}

## 0x800EBA6C - removes arg1's direction component from arg0 (in place) and returns |arg0|^2.
## Returns {"ret": f32, "arg0": Vector3}.
static func func_ovl2_800EBA6C(arg0, arg1):
	var sp1C: Vector3 = syVectorNorm3D(arg1)
	var scale: float = (arg0.x * sp1C.x) + (sp1C.y * arg0.y) + (sp1C.z * arg0.z)
	sp1C = Vector3(sp1C.x * scale, sp1C.y * scale, sp1C.z * scale)
	var a: Vector3 = arg0
	a.x -= sp1C.x
	a.y -= sp1C.y
	a.z -= sp1C.z
	return {"ret": SQUARE(a.x) + SQUARE(a.y) + SQUARE(a.z), "arg0": a}

## 0x800EBB3C - signed angle between arg0 and arg1 around arg2 (both projected onto arg2's
## normal plane first, in place). Returns the f32 angle.
static func func_ovl2_800EBB3C(arg0, arg1, arg2):
	var r = func_ovl2_800EBA6C(arg0, arg2)
	arg0 = r.arg0
	if r.ret < 0.0004:
		return 0.0
	r = func_ovl2_800EBA6C(arg1, arg2)
	arg1 = r.arg0
	if r.ret < 0.0004:
		return 0.0
	var sp1C: Vector3 = Lbcommon.lbCommonCross3D(arg0, arg1)
	if Lbcommon.lbCommonSim3D(sp1C, arg2) < 0.0:
		return -syVectorAngleDiff3D(arg1, arg0)
	else:
		return syVectorAngleDiff3D(arg1, arg0)

## 0x800EBC0C - foot position / leg roll for slope contour. Returns {"arg1": Vector3, "arg2": f32}.
static func func_ovl2_800EBC0C(arg0, arg1, arg2, arg3, dobj):
	var sp50 := Vector3(arg3, 0.0, 0.0)
	sp50 = Gmcollision.gmCollisionGetFighterPartsWorldPosition(dobj.child.child, sp50)
	var out_arg1: Vector3 = sp50
	sp50 = Gmcollision.func_ovl2_800EE018(dobj, sp50)
	var sp2C := Vector3(0.0, 1.0, 0.0)
	var sp44 = syVectorNormCross3D(sp50, sp2C)
	if sp44 == null:
		sp44 = Vector3.ZERO   # C leaves sp44 uninitialised when the cross product is zero
	var parts: FtParts = dobj.child.user_data
	var m: PackedFloat32Array = parts.unk_dobjtrans_0x10
	var sp38 := Vector3(m[6], m[7], m[8])   # unk_dobjtrans_0x10[2][0..2]
	sp44 = syVectorNorm3D(sp44)
	sp38 = syVectorNorm3D(sp38)
	sp50 = syVectorNorm3D(sp50)
	return {"arg1": out_arg1, "arg2": func_ovl2_800EBB3C(sp44, sp38, sp50)}

## 0x800EBD08 - two-bone leg IK (hip/knee rotations) toward vec, used by mpCommon slope contour.
static func func_ovl2_800EBD08(root_dobj, arg1, vec, arg3):
	var child1_dobj: DObj = root_dobj.child
	var child2_dobj: DObj = child1_dobj.child
	var trax: float = child2_dobj.translate.x
	var square_xy: float = SQUARE(vec.x) + SQUARE(vec.y)
	var sqrtxyz: float = sqrtf((vec.z * vec.z) + square_xy)
	square_xy = sqrtf(square_xy)
	var sin_arg3: float = lbCommonSin(arg3)
	var cos_arg3: float = lbCommonCos(arg3)
	var sp50: float = sqrtxyz * sqrtxyz
	var square_trax: float = SQUARE(trax)
	var square_arg1: float = SQUARE(arg1)
	var normal: float = ((SQUARE(sqrtxyz) + square_trax) - square_arg1) / (2.0 * sqrtxyz * trax)
	if normal < 0.0:
		normal = 0.0
	if normal > 1.0:
		normal = 1.0
	var sp38: float = -sqrtf(1.0 - SQUARE(normal))
	if sqrtxyz == 0.0:
		sqrtxyz = 0.00000001
	var inverse_xy_3: float = normal
	var inverse_xyz: float = 1.0 / sqrtxyz
	if square_xy == 0.0:
		square_xy = 0.00000001
	var inverse_xy: float = 1.0 / square_xy
	var xmul: float = vec.x * inverse_xyz
	var ymul: float = vec.y * inverse_xyz
	var zmul: float = vec.z * inverse_xyz
	var sp58: float = (-xmul * vec.z * sin_arg3 * inverse_xy) - (vec.y * cos_arg3 * inverse_xy)
	var zmulnorm: float = zmul * inverse_xy_3
	sp50 = (-ymul * vec.z * sin_arg3 * inverse_xy) + (vec.x * cos_arg3 * inverse_xy)
	var imbadatmathhelp: float = square_xy * sin_arg3 * inverse_xyz
	var new_var: float = imbadatmathhelp * sp38
	var inverse_xy_2: float = f32(zmulnorm + new_var)
	if (inverse_xy_2 == -1.0) or (inverse_xy_2 == 1.0):
		if inverse_xy_2 == -1.0:
			child1_dobj.rotate.y = F_CLC_DTOR32(90.0)
			child1_dobj.rotate.x = syUtilsArcTan2((-sp38 * xmul) + (sp58 * normal), (-sp38 * ymul) + (sp50 * normal))
		else:
			child1_dobj.rotate.y = F_CLC_DTOR32(-90.0)
			child1_dobj.rotate.x = syUtilsArcTan2(-((-sp38 * xmul) + (sp58 * normal)), (-sp38 * ymul) + (sp50 * normal))
		child1_dobj.rotate.z = 0.0
	else:
		child1_dobj.rotate.y = syUtilsArcSin(-inverse_xy_2)
		child1_dobj.rotate.x = syUtilsArcTan2((-sp38 * zmul) + (imbadatmathhelp * normal), square_xy * cos_arg3 * inverse_xyz)
		child1_dobj.rotate.z = syUtilsArcTan2((ymul * normal) + (sp50 * sp38), (xmul * normal) + (sp58 * sp38))
	child2_dobj.rotate.z = syUtilsArcCos(((SQUARE(sqrtxyz) - square_trax) - square_arg1) / (2.0 * trax * arg1))
	ftParamsUpdateFighterPartsTransformAll(child1_dobj)
	ftParamsUpdateFighterPartsTransformAll(child2_dobj)

static func ftParamGetCostumeCommonID(fkind: int, color: int) -> int:
	return color

static func ftParamGetCostumeTeamID(fkind: int, color: int) -> int:
	return color

static func ftParamGetCostumeDebug(fkind: int) -> int:
	return 0

## 0x800EC130
static func ftParamInitGame() -> void:
	# 0x800EC130
	Ftmain.ftMainClearGroundElementsAll()
	Ifcommon.ifCommonBattleInitPlacement()
