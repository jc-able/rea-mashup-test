## 1:1 port of src/ft/ftmain.c (ssb-decomp-re): the fighter main loop.
##   - motion (hitbox/event) script interpreter
##   - per-frame input / animation / status update      (ftMainProcUpdateInterrupt, priority 5)
##   - physics + map collision + hitbox world positions  (ftMainProcPhysicsMap, priorities 4/3)
##   - grab search                                       (ftMainProcSearchCatch, priority 2)
##   - hit detection vs fighters/items/weapons/ground    (ftMainProcSearchHitAll, priority 1)
##   - damage / shield / rebound / hitlag application    (ftMainProcParams, priority 0)
##   - status changes                                    (ftMainSetStatus)
## Motion scripts are decoded ftMotionCommand words (see MotionScriptData / SSBData);
## each command is a Dictionary with the C bitfield member names and "next" (next command index).
class_name Ftmain
extends Port

## dFTMainHitCollisionFGMs[fgm_kind][fgm_level]
static var dFTMainHitCollisionFGMs: Array = [
	[nSYAudioFGMPunchS, nSYAudioFGMPunchM, nSYAudioFGMPunchL],
	[nSYAudioFGMKickS, nSYAudioFGMKickM, nSYAudioFGMKickL],
	[nSYAudioFGMMarioSpecialHiCoin, nSYAudioFGMMarioSpecialHiCoin, nSYAudioFGMMarioSpecialHiCoin],
	[nSYAudioFGMBurnS, nSYAudioFGMBurnM, nSYAudioFGMBurnL],
	[nSYAudioFGMShockS, nSYAudioFGMShockM, nSYAudioFGMShockL],
	[nSYAudioFGMSlashS, nSYAudioFGMSlashM, nSYAudioFGMSlashL],
	[nSYAudioFGMHarisenHit, nSYAudioFGMHarisenHit, nSYAudioFGMHarisenHit],
	[nSYAudioFGMPunchM, nSYAudioFGMPunchL, nSYAudioFGMBatHit],
]

## dFTMainGroundHitCollisionAttributes: GRAttackColl {kind, damage, angle, knockback_scale, knockback_weight, knockback_base, element}
## (src/gr/grtypes.h field order; values from src/ft/ftmain.c)
static var dFTMainGroundHitCollisionAttributes: Array = [
	{"kind": 4, "damage": 1, "angle": 361, "knockback_scale": 100, "knockback_weight": 100, "knockback_base": 0, "element": nGMHitElementFire},
	{"kind": 5, "damage": 10, "angle": 90, "knockback_scale": 100, "knockback_weight": 200, "knockback_base": 0, "element": nGMHitElementFire},
	{"kind": 6, "damage": 10, "angle": 90, "knockback_scale": 100, "knockback_weight": 100, "knockback_base": 0, "element": nGMHitElementFire},
	{"kind": 7, "damage": 10, "angle": 361, "knockback_scale": 100, "knockback_weight": 80, "knockback_base": 0, "element": nGMHitElementSlash},
	{"kind": 8, "damage": 1, "angle": 90, "knockback_scale": 100, "knockback_weight": 100, "knockback_base": 0, "element": nGMHitElementFire},
	{"kind": 9, "damage": 1, "angle": 90, "knockback_scale": 100, "knockback_weight": 100, "knockback_base": 0, "element": nGMHitElementFire},
]

# GLOBAL / STATIC VARIABLES
static var sFTMainGroundObstacles: Array = [{"gobj": null, "proc_update": Callable()}, {"gobj": null, "proc_update": Callable()}]
static var sFTMainGroundHazards: Array = [{"gobj": null, "proc_update": Callable()}]
static var sFTMainGroundObstaclesNum: int = 0
static var sFTMainGroundHazardsNum: int = 0
static var gFTMainIsDamageDetect: Array = [0, 0, 0, 0]
static var gFTMainIsAttackDetect: Array = [0, 0, 0, 0]
static var sFTMainHitLogID: int = 0
static var sFTMainHitLogs: Array = []

static func _hitlogs() -> Array:
	if sFTMainHitLogs.is_empty():
		for i in 10:
			sFTMainHitLogs.append({"attacker_object_class": 0, "attack_coll": null, "attack_id": 0, "attacker_gobj": null,
				"damage_coll": null, "attacker_player": 0, "attacker_player_num": 0})
	return sFTMainHitLogs

# ---------------------------------------------------------------------------
# Motion script helpers
# ---------------------------------------------------------------------------
static func _adv(ms: FTMotionScript, c: Dictionary) -> void:
	ms.p_script = MotionPtr.make(ms.p_script.scr, c.next)

static func _after(ms: FTMotionScript, c: Dictionary) -> MotionPtr:
	return MotionPtr.make(ms.p_script.scr, c.next)

## 0x800DF0F0
static func ftMainParseMotionEvent(fighter_gobj, fp: Fighter, ms: FTMotionScript, ev_kind: int) -> void:
	var c: Dictionary = ms.p_script.cmd()
	match ev_kind:
		nFTMotionEventEnd:
			ms.p_script = null

		nFTMotionEventSyncWait:
			ms.script_wait += c.value
			_adv(ms, c)

		nFTMotionEventAsyncWait:
			ms.script_wait = c.value - fighter_gobj.anim_frame
			_adv(ms, c)

		nFTMotionEventMakeAttackColl, nFTMotionEventMakeAttackCollScaled:
			if fp.pkind != nFTPlayerKindDemo:
				var attack_id: int = c.attack_id
				var attack_coll: FTAttackColl = fp.attack_colls[attack_id]
				if (attack_coll.attack_state == nGMAttackStateOff) or (attack_coll.group_id != c.group_id):
					attack_coll.group_id = c.group_id
					attack_coll.attack_state = nGMAttackStateNew
					fp.is_attack_active = TRUE
					var i := 0
					while i < fp.attack_colls.size():
						var other: FTAttackColl = fp.attack_colls[i]
						if (i != attack_id) and (other.attack_state != nGMAttackStateOff) and (attack_coll.group_id == other.group_id):
							for j in attack_coll.attack_records.size():
								attack_coll.attack_records[j].copy_from(other.attack_records[j])
							break
						i += 1
					if i == fp.attack_colls.size():
						Ftparam.ftParamClearAttackRecordID(fp, attack_id)
				attack_coll.joint_id = Ftparam.ftParamGetJointID(fp, c.joint_id)
				attack_coll.joint = fp.joints[attack_coll.joint_id]
				attack_coll.damage = c.damage
				attack_coll.can_rebound = c.can_rebound
				attack_coll.element = c.element
				attack_coll.size = c.size * 0.5
				attack_coll.offset.x = c.off_x
				attack_coll.offset.y = c.off_y
				attack_coll.offset.z = c.off_z
				attack_coll.angle = c.angle
				attack_coll.knockback_scale = c.knockback_scale
				attack_coll.knockback_weight = c.knockback_weight
				attack_coll.is_hit_air = c.is_hit_ground_air & 1
				attack_coll.is_hit_ground = (c.is_hit_ground_air & 2) >> 1
				attack_coll.shield_damage = c.shield_damage
				attack_coll.fgm_level = c.fgm_level
				attack_coll.fgm_kind = c.fgm_kind
				attack_coll.knockback_base = c.knockback_base
				_adv(ms, c)
				attack_coll.is_scale_pos = TRUE if (ev_kind == nFTMotionEventMakeAttackCollScaled) else FALSE
				attack_coll.motion_attack_id = fp.motion_attack_id
				attack_coll.motion_count = fp.motion_count
				attack_coll.damage = Ftparam.ftParamGetStaledDamage(fp.player, attack_coll.damage, attack_coll.motion_attack_id, attack_coll.motion_count)
			else:
				_adv(ms, c)

		nFTMotionEventSetAttackCollOffset:
			var attack_coll: FTAttackColl = fp.attack_colls[c.attack_id]
			attack_coll.offset.x = c.off_x
			attack_coll.offset.y = c.off_y
			attack_coll.offset.z = c.off_z
			_adv(ms, c)

		nFTMotionEventSetAttackCollDamage:
			if fp.pkind != nFTPlayerKindDemo:
				var attack_id: int = c.attack_id
				fp.attack_colls[attack_id].damage = c.damage
				_adv(ms, c)
				fp.attack_colls[attack_id].damage = Ftparam.ftParamGetStaledDamage(fp.player, fp.attack_colls[attack_id].damage, fp.attack_colls[attack_id].motion_attack_id, fp.attack_colls[attack_id].motion_count)
			else:
				_adv(ms, c)

		nFTMotionEventSetAttackCollSize:
			fp.attack_colls[c.attack_id].size = c.size * 0.5
			_adv(ms, c)

		nFTMotionEventSetAttackCollSoundLevel:
			fp.attack_colls[c.attack_id].fgm_level = c.fgm_level
			_adv(ms, c)

		nFTMotionEventRefreshAttackCollID:
			var attack_id: int = c.value
			_adv(ms, c)
			Ftparam.ftParamRefreshAttackCollID(fighter_gobj, attack_id)

		nFTMotionEventClearAttackCollID:
			var attack_id: int = c.value
			_adv(ms, c)
			fp.attack_colls[attack_id].attack_state = nGMAttackStateOff

		nFTMotionEventClearAttackCollAll:
			Ftparam.ftParamClearAttackCollAll(fighter_gobj)
			_adv(ms, c)

		nFTMotionEventSetThrow:
			fp.throw_desc = c.throw_desc
			_adv(ms, c)

		nFTMotionEventPlayFGMStoreInfo:
			if not B(fp.is_muted):
				fp.p_sfx = Snd.func_800269C0_275C0(c.value)
				fp.sfx_id = fp.p_sfx.sfx_id if fp.p_sfx != null else 0
			_adv(ms, c)

		nFTMotionEventPlayFGM:
			if not B(fp.is_muted):
				Snd.func_800269C0_275C0(c.value)
			_adv(ms, c)

		nFTMotionEventPlayLoopSFXStoreInfo:
			if not B(fp.is_muted):
				Ftparam.ftParamPlayLoopSFX(fp, c.value)
			_adv(ms, c)

		nFTMotionEventStopLoopSFX:
			Ftparam.ftParamStopLoopSFX(fp)
			_adv(ms, c)

		nFTMotionEventPlayVoiceStoreInfo:
			if not B(fp.is_muted) and B(fp.attr.is_have_voice):
				Ftparam.ftParamPlayVoice(fp, c.value)
			_adv(ms, c)

		nFTMotionEventPlayLoopVoiceStoreInfo:
			if not B(fp.is_muted) and B(fp.attr.is_have_voice):
				Ftparam.ftParamPlayLoopSFX(fp, c.value)
			_adv(ms, c)

		nFTMotionEventPlaySmashVoice:
			if not B(fp.is_muted):
				Ftparam.ftParamPlayVoice(fp, fp.attr.smash_sfx[syUtilsRandIntRange(fp.attr.smash_sfx.size())])
			_adv(ms, c)

		nFTMotionEventSetAirJumpAdd:
			fp.ga = nMPKineticsAir
			fp.physics.vel_air.z = 0.0
			DObjGetStruct(fighter_gobj).translate.z = 0.0
			fp.jumps_used += 1
			_adv(ms, c)

		nFTMotionEventSetAirJumpMax:
			fp.ga = nMPKineticsAir
			fp.physics.vel_air.z = 0.0
			DObjGetStruct(fighter_gobj).translate.z = 0.0
			fp.jumps_used = fp.attr.jumps_max
			_adv(ms, c)

		nFTMotionEventEffect, nFTMotionEventEffectItemHold:
			if not B(fp.is_effect_skip):
				var joint_id: int = Ftparam.ftParamGetJointID(fp, c.joint_id)
				var effect_offset := Vector3(c.off_x, c.off_y, c.off_z)
				var effect_scatter := Vector3(c.rng_x, c.rng_y, c.rng_z)
				_adv(ms, c)
				Ftparam.ftParamMakeEffect(fighter_gobj, c.effect_id, joint_id, effect_offset, effect_scatter, fp.lr, TRUE if (ev_kind == nFTMotionEventEffectItemHold) else FALSE, c.flag)
			else:
				_adv(ms, c)

		nFTMotionEventSetHitStatusPartAll:
			Ftparam.ftParamSetHitStatusPartAll(fighter_gobj, c.value)
			_adv(ms, c)

		nFTMotionEventSetHitStatusPartID:
			Ftparam.ftParamSetHitStatusPartID(fighter_gobj, Ftparam.ftParamGetJointID(fp, c.joint_id), c.hitstatus)
			_adv(ms, c)

		nFTMotionEventSetHitStatusAll:
			Ftparam.ftParamSetHitStatusAll(fighter_gobj, c.value)
			_adv(ms, c)

		nFTMotionEventResetDamageCollPartAll:
			Ftparam.ftParamResetFighterDamageCollsAll(fighter_gobj)
			_adv(ms, c)

		nFTMotionEventSetDamageCollPartID:
			var joint_id: int = Ftparam.ftParamGetJointID(fp, c.joint_id)
			var damage_coll_offset := Vector3(c.off_x, c.off_y, c.off_z)
			var damage_coll_size := Vector3(c.size_x, c.size_y, c.size_z)
			_adv(ms, c)
			Ftparam.ftParamModifyDamageCollID(fighter_gobj, joint_id, damage_coll_offset, damage_coll_size)

		nFTMotionEventLoopBegin:
			# p_goto[script_id] = script after this command; loop_count[script_id] = value; script_id += 2
			ms.set_goto(ms.script_id, _after(ms, c))
			ms.script_id += 1
			ms.stack[ms.script_id] = c.value      # loop_count[script_id++ - 1]
			ms.script_id += 1
			_adv(ms, c)

		nFTMotionEventLoopEnd:
			ms.stack[ms.script_id - 1] -= 1        # --loop_count[script_id - 2]
			if ms.stack[ms.script_id - 1] != 0:
				var g: MotionPtr = ms.get_goto(ms.script_id - 2)
				ms.p_script = g.dup()
			else:
				_adv(ms, c)
				ms.script_id -= 2

		nFTMotionEventSubroutine:
			ms.set_goto(ms.script_id, _after(ms, c))
			ms.script_id += 1
			ms.p_script = c.target.dup()

		nFTMotionEventSetDamageThrown:
			if fp.throw_gobj != null:
				var fkind: int = fp.throw_fkind
				var p_damage: Array = c.p_damage
				var tgt = p_damage[fp.status_vars.common.damage.script_id][fkind]
				if tgt != null:
					ms.set_goto(ms.script_id, _after(ms, c))
					ms.script_id += 1
					ms.p_script = tgt.dup()
				else:
					_adv(ms, c)
			else:
				_adv(ms, c)

		nFTMotionEventReturn:
			ms.script_id -= 1
			var g: MotionPtr = ms.get_goto(ms.script_id)
			ms.p_script = g.dup() if g != null else null

		nFTMotionEventGoto:
			ms.p_script = c.target.dup()

		nFTMotionEventSetParallelScript:
			if fp.motion_scripts[0][1].p_script == null:
				fp.motion_scripts[0][1].p_script = c.target.dup()
				fp.motion_scripts[1][1].p_script = c.target.dup()
				var w: float = DObjGetStruct(fighter_gobj).anim_speed - fighter_gobj.anim_frame
				fp.motion_scripts[0][1].script_wait = w
				fp.motion_scripts[1][1].script_wait = w
				fp.motion_scripts[0][1].script_id = 0
				fp.motion_scripts[1][1].script_id = 0
			_adv(ms, c)

		nFTMotionEventPauseScript:
			_adv(ms, c)
			ms.script_wait = F32_MAX

		nFTMotionEventSetModelPartID:
			Ftparam.ftParamSetModelPartID(fighter_gobj, Ftparam.ftParamGetJointID(fp, c.joint_id), c.modelpart_id)
			_adv(ms, c)

		nFTMotionEventResetModelPartAll:
			Ftparam.ftParamResetModelPartAll(fighter_gobj)
			_adv(ms, c)

		nFTMotionEventHideModelPartAll:
			Ftparam.ftParamHideModelPartAll(fighter_gobj)
			_adv(ms, c)

		nFTMotionEventSetTexturePartID:
			Ftparam.ftParamSetTexturePartID(fighter_gobj, c.texturepart_id, c.frame)
			_adv(ms, c)

		nFTMotionEventSetColAnim:
			Ftparam.ftParamCheckSetFighterColAnimID(fighter_gobj, c.colanim_id, c.length)
			_adv(ms, c)

		nFTMotionEventResetColAnim:
			Ftparam.ftParamResetStatUpdateColAnim(fighter_gobj)
			_adv(ms, c)

		nFTMotionEventSetFlag0:
			fp.motion_vars.flag0 = c.value
			_adv(ms, c)

		nFTMotionEventSetFlag1:
			fp.motion_vars.flag1 = c.value
			_adv(ms, c)

		nFTMotionEventSetFlag2:
			fp.motion_vars.flag2 = c.value
			_adv(ms, c)

		nFTMotionEventSetFlag3:
			fp.motion_vars.flag3 = c.value
			_adv(ms, c)

		nFTMotionEventSetSlopeContour:
			var slope_contour: int = fp.slope_contour
			fp.slope_contour = c.flags
			_adv(ms, c)
			if not (slope_contour & fp.slope_contour & FTSLOPECONTOUR_FLAG_FULL):
				DObjGetStruct(fighter_gobj).rotate.x = F_CLC_DTOR32(0.0)

		nFTMotionEventHideItem:
			fp.is_item_show = c.value
			_adv(ms, c)

		nFTMotionEventSetAfterImage:
			fp.afterimage.is_itemswing = c.is_itemswing
			fp.afterimage.drawstatus = c.drawstatus
			_adv(ms, c)

		nFTMotionEventMakeRumble:
			if fp.pkind != nFTPlayerKindDemo:
				Ftparam.ftParamMakeRumble(fp, c.rumble_id, c.length)
			_adv(ms, c)

		nFTMotionEventStopRumble:
			if fp.pkind != nFTPlayerKindDemo:
				Gmrumble.gmRumbleStopRumbleID(fp.player, c.value)
			_adv(ms, c)

		_:
			# unknown opcode: C would misbehave; treat as a 1-word no-op
			_adv(ms, c)

static func _motion_loop_prologue(fighter_gobj, ms: FTMotionScript) -> bool:
	## Shared head of the event loops: returns false when the loop must stop.
	if ms.p_script == null:
		return false
	if ms.script_wait == F32_MAX:
		if DObjGetStruct(fighter_gobj).anim_speed <= fighter_gobj.anim_frame:
			return false
		else:
			ms.script_wait = -fighter_gobj.anim_frame
	elif ms.script_wait > 0.0:
		return false
	return true

## 0x800E02A8 - Run all motion events. Effects are parsed only if events aren't queued.
static func ftMainUpdateMotionEventsAll(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	for i in 2:
		var ms: FTMotionScript = fp.motion_scripts[0][i]
		if ms.p_script != null:
			if ms.script_wait != F32_MAX:
				ms.script_wait -= DObjGetStruct(fighter_gobj).anim_speed
			while true:
				if not _motion_loop_prologue(fighter_gobj, ms):
					break
				var c: Dictionary = ms.p_script.cmd()
				var ev_kind: int = c.op
				if ((ev_kind == nFTMotionEventEffect) or (ev_kind == nFTMotionEventEffectItemHold)) and B(fp.is_events_forward):
					_adv(ms, c)
				else:
					ftMainParseMotionEvent(fighter_gobj, fp, ms, ev_kind)
	if not B(fp.is_events_forward):
		for i in 2:
			fp.motion_scripts[1][i].copy_from(fp.motion_scripts[0][i])

## 0x800E0478 - Fast-forward most fighter-specific events and update core events.
static func ftMainUpdateMotionEventsForward(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	for i in 2:
		var ms: FTMotionScript = fp.motion_scripts[0][i]
		if ms.p_script != null:
			if ms.script_wait != F32_MAX:
				ms.script_wait -= DObjGetStruct(fighter_gobj).anim_speed
			while true:
				if not _motion_loop_prologue(fighter_gobj, ms):
					break
				var c: Dictionary = ms.p_script.cmd()
				var ev_kind: int = c.op
				match ev_kind:
					nFTMotionEventClearAttackCollID, nFTMotionEventClearAttackCollAll, nFTMotionEventSetAttackCollDamage, \
					nFTMotionEventSetAttackCollSize, nFTMotionEventSetAttackCollSoundLevel, nFTMotionEventRefreshAttackCollID, \
					nFTMotionEventPlayFGM, nFTMotionEventPlayLoopSFXStoreInfo, nFTMotionEventStopLoopSFX, nFTMotionEventPlayVoiceStoreInfo, \
					nFTMotionEventPlayLoopVoiceStoreInfo, nFTMotionEventPlayFGMStoreInfo, nFTMotionEventPlaySmashVoice, \
					nFTMotionEventSetFlag0, nFTMotionEventSetFlag1, nFTMotionEventSetFlag2, nFTMotionEventSetAirJumpAdd, \
					nFTMotionEventSetAirJumpMax, nFTMotionEventSetColAnim, nFTMotionEventResetColAnim, nFTMotionEventMakeRumble, \
					nFTMotionEventStopRumble, nFTMotionEventSetAfterImage:
						_adv(ms, c)
					nFTMotionEventEffect, nFTMotionEventEffectItemHold, nFTMotionEventMakeAttackColl, \
					nFTMotionEventMakeAttackCollScaled, nFTMotionEventSetAttackCollOffset:
						_adv(ms, c)
					_:
						ftMainParseMotionEvent(fighter_gobj, fp, ms, ev_kind)
	for i in 2:
		fp.motion_scripts[1][i].copy_from(fp.motion_scripts[0][i])

## 0x800E0654 - Fast-forward all events except core, throw setup and effect spawn events.
static func ftMainUpdateMotionEventsForwardEffect(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	for i in 2:
		var ms: FTMotionScript = fp.motion_scripts[1][i]
		if ms.p_script != null:
			if ms.script_wait != F32_MAX:
				ms.script_wait -= DObjGetStruct(fighter_gobj).anim_speed
			while true:
				if not _motion_loop_prologue(fighter_gobj, ms):
					break
				var c: Dictionary = ms.p_script.cmd()
				var ev_kind: int = c.op
				match ev_kind:
					nFTMotionEventEnd, nFTMotionEventSyncWait, nFTMotionEventAsyncWait, nFTMotionEventSetDamageThrown, \
					nFTMotionEventLoopBegin, nFTMotionEventLoopEnd, nFTMotionEventSubroutine, nFTMotionEventReturn, \
					nFTMotionEventGoto, nFTMotionEventPauseScript, nFTMotionEventEffect, nFTMotionEventEffectItemHold:
						ftMainParseMotionEvent(fighter_gobj, fp, ms, ev_kind)
					_:
						_adv(ms, c)

## 0x800E07D4
static func ftMainPlayAnim(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	if fp.anim_flag_use_transn_joint():
		fp.anim_vel = fp.joints[nFTPartsJointTransN].translate
	Ftparam.ftParamUpdateAnimKeys(fighter_gobj)
	Ftparam.ftParamsUpdateFighterPartsTransform(fp.joints[nFTPartsJointTopN])

## 0x800E0830 - Play fighter animation and run motion scripts normally
static func ftMainPlayAnimEventsAll(fighter_gobj) -> void:
	ftMainPlayAnim(fighter_gobj)
	ftMainUpdateMotionEventsAll(fighter_gobj)

## 0x800E0858 - Play fighter animation and fast-forward motion scripts to current frame
static func ftMainPlayAnimEventsForward(fighter_gobj) -> void:
	ftMainPlayAnim(fighter_gobj)
	ftMainUpdateMotionEventsForward(fighter_gobj)

## 0x800E0880 - color animation script interpreter (src/ft/ftmain.c ftMainUpdateColAnim). Scripts are
## Gmcolscripts data (raw words); used by fighters, items (Itvisuals) and the screen flash (Ifscreenflash).
static func _cs_word(p: Array, k: int) -> int:
	var words: Array = Gmcolscripts.WORDS[p[0]]
	var i: int = p[1] + k
	return (int(words[i]) & 0xFFFFFFFF) if i < words.size() else 0

static func _cs_ptr(p: Array, k: int):
	var ptrs: Dictionary = Gmcolscripts.PTRS.get(p[0], {})
	var nm = ptrs.get(p[1] + k, null)
	return [nm, 0] if nm != null else null

static func _cs_s16(v: int) -> int:
	v &= 0xFFFF
	return v - 0x10000 if v >= 0x8000 else v

static func _cs_set_rgba(keys, w: int) -> void:
	keys.r = (w >> 24) & 0xFF
	keys.g = (w >> 16) & 0xFF
	keys.b = (w >> 8) & 0xFF
	keys.a = w & 0xFF

static func _cs_u8_add(v: int, d: int) -> int:
	return (v + d) & 0xFF

static func ftMainUpdateColAnim(colanim, fighter_gobj, is_muted, is_effect_skip) -> int:
	for i in colanim.cs.size():
		var cs = colanim.cs[i]
		if (cs.p_script != null) and (cs.color_event_timer != 0):
			cs.color_event_timer -= 1
		while (cs.p_script != null) and (cs.color_event_timer == 0):
			var p: Array = cs.p_script
			var w0: int = _cs_word(p, 0)
			var ev_kind: int = (w0 >> 26) & 0x3F
			match ev_kind:
				nGMColEventEnd:
					var j := 0
					while j < colanim.cs.size():
						if (j != i) and (colanim.cs[j].p_script != null):
							break
						j += 1
					if j == colanim.cs.size():
						return TRUE
					else:
						cs.p_script = null
				nGMColEventWait:
					cs.color_event_timer = (w0 & 0x3FFFFFF) & 0xFFFF
					cs.p_script = [p[0], p[1] + 1]
				nGMColEventGoto:
					cs.p_script = _cs_ptr(p, 1)
				nGMColEventLoopBegin:
					# p_subroutine[script_id++] = script after this event; (loop_count) = value
					cs.stack[cs.script_id] = [p[0], p[1] + 1]
					cs.script_id += 1
					cs.stack[cs.script_id] = w0 & 0x3FFFFFF
					cs.script_id += 1
					cs.p_script = [p[0], p[1] + 1]
				nGMColEventLoopEnd:
					# --loop_count[script_id - 2] (== stack[script_id - 1])
					cs.stack[cs.script_id - 1] -= 1
					if cs.stack[cs.script_id - 1] != 0:
						cs.p_script = cs.stack[cs.script_id - 2]
					else:
						cs.p_script = [p[0], p[1] + 1]
						cs.script_id -= 2
				nGMColEventSubroutine:
					cs.stack[cs.script_id] = [p[0], p[1] + 2]
					cs.script_id += 1
					cs.p_script = _cs_ptr(p, 1)
				nGMColEventReturn:
					cs.script_id -= 1
					cs.p_script = cs.stack[cs.script_id]
				nGMColEventSetParallelScript:
					if colanim.cs[1].p_script == null:
						colanim.cs[1].p_script = _cs_ptr(p, 1)
						colanim.cs[1].color_event_timer = 0
						colanim.cs[1].script_id = 0
					cs.p_script = [p[0], p[1] + 2]
				nGMColEventClearColorAll:
					colanim.is_use_color1 = 0
					colanim.is_use_color2 = 0
					colanim.skeleton_id = 0
					cs.p_script = [p[0], p[1] + 1]
				nGMColEventSetColor1:
					colanim.is_use_color1 = TRUE
					_cs_set_rgba(colanim.color1, _cs_word(p, 1))
					colanim.color1.ir = 0
					colanim.color1.ig = 0
					colanim.color1.ib = 0
					colanim.color1.ia = 0
					cs.p_script = [p[0], p[1] + 2]
				nGMColEventSetColor2:
					colanim.is_use_color2 = TRUE
					_cs_set_rgba(colanim.color2, _cs_word(p, 1))
					colanim.color2.ir = 0
					colanim.color2.ig = 0
					colanim.color2.ib = 0
					colanim.color2.ia = 0
					cs.p_script = [p[0], p[1] + 2]
				nGMColEventBlendColor1, nGMColEventBlendColor2:
					var keys = colanim.color1 if ev_kind == nGMColEventBlendColor1 else colanim.color2
					var blend_frames: int = w0 & 0x3FFFFFF
					var w1: int = _cs_word(p, 1)
					# (s32)(target - current) / blend_frames, C truncating division; stored as s16
					keys.ir = _cs_s16(int((((w1 >> 24) & 0xFF) - keys.r) / blend_frames))
					keys.ig = _cs_s16(int((((w1 >> 16) & 0xFF) - keys.g) / blend_frames))
					keys.ib = _cs_s16(int((((w1 >> 8) & 0xFF) - keys.b) / blend_frames))
					keys.ia = _cs_s16(int(((w1 & 0xFF) - keys.a) / blend_frames))
					cs.p_script = [p[0], p[1] + 2]
				nGMColEventEffect, nGMColEventEffectItemHoldOffset:
					if is_effect_skip == FALSE:
						var fp := ftGetStruct(fighter_gobj)
						var jraw: int = (w0 >> 19) & 0x7F
						var joint_id: int = Ftparam.ftParamGetJointID(fp, jraw - 0x80 if jraw >= 0x40 else jraw)
						var effect_id: int = (w0 >> 10) & 0x1FF
						var flag: int = w0 & 0x3FF
						var w1: int = _cs_word(p, 1)
						var w2: int = _cs_word(p, 2)
						var w3: int = _cs_word(p, 3)
						var effect_offset := Vector3(_cs_s16(w1 >> 16), _cs_s16(w1), _cs_s16(w2 >> 16))
						var effect_scatter := Vector3(_cs_s16(w2), _cs_s16(w3 >> 16), _cs_s16(w3))
						cs.p_script = [p[0], p[1] + 4]
						Ftparam.ftParamMakeEffect(fighter_gobj, effect_id, joint_id, effect_offset, effect_scatter, fp.lr, TRUE if (ev_kind == nGMColEventEffectItemHoldOffset) else FALSE, flag)
					else:
						cs.p_script = [p[0], p[1] + 4]
				nGMColEventSetLight:
					colanim.is_use_light = TRUE
					var l1: int = (w0 >> 13) & 0x1FFF
					var l2: int = w0 & 0x1FFF
					colanim.light_angle_x = float(l1 - 0x2000 if l1 >= 0x1000 else l1)
					colanim.light_angle_y = float(l2 - 0x2000 if l2 >= 0x1000 else l2)
					cs.p_script = [p[0], p[1] + 1]
				nGMColEventClearLight:
					colanim.is_use_light = FALSE
					cs.p_script = [p[0], p[1] + 1]
				nGMColEventPlayFGM:
					if is_muted == FALSE:
						Snd.func_800269C0_275C0(w0 & 0x3FFFFFF)
					cs.p_script = [p[0], p[1] + 1]
				nGMColEventSetSkeletonID:
					colanim.skeleton_id = (w0 & 0x3FFFFFF) & 0x3
					cs.p_script = [p[0], p[1] + 1]
				_:
					# C: unknown opcodes are not advanced (would hang); never present in the data
					cs.p_script = null
	if colanim.is_use_color1:
		colanim.color1.r = _cs_u8_add(colanim.color1.r, colanim.color1.ir)
		colanim.color1.g = _cs_u8_add(colanim.color1.g, colanim.color1.ig)
		colanim.color1.b = _cs_u8_add(colanim.color1.b, colanim.color1.ib)
		colanim.color1.a = _cs_u8_add(colanim.color1.a, colanim.color1.ia)
	if colanim.is_use_color2:
		colanim.color2.r = _cs_u8_add(colanim.color2.r, colanim.color2.ir)
		colanim.color2.g = _cs_u8_add(colanim.color2.g, colanim.color2.ig)
		colanim.color2.b = _cs_u8_add(colanim.color2.b, colanim.color2.ib)
		colanim.color2.a = _cs_u8_add(colanim.color2.a, colanim.color2.ia)
	if colanim.length != 0:
		colanim.length -= 1
		if colanim.length == 0:
			return TRUE
	return FALSE

## 0x800E11C8
static func ftMainRunUpdateColAnim(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	while ftMainUpdateColAnim(fp.colanim, fighter_gobj, fp.is_muted, fp.is_effect_skip) != FALSE:
		Ftparam.ftParamResetStatUpdateColAnim(fighter_gobj)

# ---------------------------------------------------------------------------
# Main update / interrupt process (priority 5)
# ---------------------------------------------------------------------------
static func _update_stick_buffers(this_fp: Fighter, pl) -> void:
	if pl.stick_range.x >= 20:
		if pl.stick_prev.x >= 20:
			this_fp.tap_stick_x += 1
			this_fp.hold_stick_x += 1
		else:
			this_fp.tap_stick_x = 1
			this_fp.hold_stick_x = 1
	elif pl.stick_range.x <= -20:
		if pl.stick_prev.x <= -20:
			this_fp.tap_stick_x += 1
			this_fp.hold_stick_x += 1
		else:
			this_fp.tap_stick_x = 1
			this_fp.hold_stick_x = 1
	else:
		this_fp.tap_stick_x = FTINPUT_STICKBUFFER_TICS_MAX
		this_fp.hold_stick_x = FTINPUT_STICKBUFFER_TICS_MAX
	if this_fp.tap_stick_x > FTINPUT_STICKBUFFER_TICS_MAX:
		this_fp.tap_stick_x = FTINPUT_STICKBUFFER_TICS_MAX
	if this_fp.hold_stick_x > FTINPUT_STICKBUFFER_TICS_MAX:
		this_fp.hold_stick_x = FTINPUT_STICKBUFFER_TICS_MAX
	if pl.stick_range.y >= 20:
		if pl.stick_prev.y >= 20:
			this_fp.tap_stick_y += 1
			this_fp.hold_stick_y += 1
		else:
			this_fp.tap_stick_y = 1
			this_fp.hold_stick_y = 1
	elif pl.stick_range.y <= -20:
		if pl.stick_prev.y <= -20:
			this_fp.tap_stick_y += 1
			this_fp.hold_stick_y += 1
		else:
			this_fp.tap_stick_y = 1
			this_fp.hold_stick_y = 1
	else:
		this_fp.tap_stick_y = FTINPUT_STICKBUFFER_TICS_MAX
		this_fp.hold_stick_y = FTINPUT_STICKBUFFER_TICS_MAX
	if this_fp.tap_stick_y > FTINPUT_STICKBUFFER_TICS_MAX:
		this_fp.tap_stick_y = FTINPUT_STICKBUFFER_TICS_MAX
	if this_fp.hold_stick_y > FTINPUT_STICKBUFFER_TICS_MAX:
		this_fp.hold_stick_y = FTINPUT_STICKBUFFER_TICS_MAX

## 0x800E1260
static func ftMainProcUpdateInterrupt(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	if not B(this_fp.is_control_disable):
		this_fp.status_total_tics += 1
	if not B(this_fp.is_control_disable):
		var pl = this_fp.input.pl
		pl.stick_prev = Vector2i(pl.stick_range.x, pl.stick_range.y)
		var button_tap_mask: int
		match this_fp.pkind:
			nFTPlayerKindMan:
				var controller = this_fp.input.controller
				var button_hold: int = controller.button_hold if controller != null else 0
				if button_hold & R_TRIG:
					button_hold |= (A_BUTTON | Z_TRIG)
				pl.stick_range = Vector2i(controller.stick_range.x, controller.stick_range.y) if controller != null else Vector2i.ZERO
				button_tap_mask = (button_hold ^ pl.button_hold) & button_hold
				pl.button_tap = (pl.button_tap | button_tap_mask) if (this_fp.hitlag_tics != 0) else button_tap_mask
				button_tap_mask = (button_hold ^ pl.button_hold) & pl.button_hold
				pl.button_release = (pl.button_release | button_tap_mask) if (this_fp.hitlag_tics != 0) else button_tap_mask
				pl.button_hold = button_hold
			nFTPlayerKindCom, nFTPlayerKindKey, nFTPlayerKindGameKey:
				if this_fp.pkind == nFTPlayerKindCom:
					Ftcomputer.ftComputerProcessAll(fighter_gobj)
				else:
					Ftkey.ftKeyProcessKeyEvents(fighter_gobj)
				var cp = this_fp.input.cp
				var button_hold_com: int = cp.button_inputs
				if button_hold_com & R_TRIG:
					button_hold_com |= (A_BUTTON | Z_TRIG)
				pl.stick_range = Vector2i(cp.stick_range.x, cp.stick_range.y)
				button_tap_mask = (button_hold_com ^ pl.button_hold) & button_hold_com
				pl.button_tap = (pl.button_tap | button_tap_mask) if (this_fp.hitlag_tics != 0) else button_tap_mask
				button_tap_mask = (button_hold_com ^ pl.button_hold) & pl.button_hold
				pl.button_release = (pl.button_release | button_tap_mask) if (this_fp.hitlag_tics != 0) else button_tap_mask
				pl.button_hold = button_hold_com
		pl.stick_range.x = clampi(pl.stick_range.x, -I_CONTROLLER_RANGE_MAX, I_CONTROLLER_RANGE_MAX)
		pl.stick_range.y = clampi(pl.stick_range.y, -I_CONTROLLER_RANGE_MAX, I_CONTROLLER_RANGE_MAX)
		if G.gSCManagerBackupData.error_flags & LBBACKUP_ERROR_HALFSTICKRANGE:
			pl.stick_range.x = int(pl.stick_range.x * 0.5)
			pl.stick_range.y = int(pl.stick_range.y * 0.5)
		_update_stick_buffers(this_fp, pl)
	if this_fp.tics_since_last_z < FTINPUT_ZTRIGLAST_TICS_MAX:
		this_fp.tics_since_last_z += 1
	if this_fp.input.pl.button_tap & this_fp.input.button_mask_z:
		this_fp.tics_since_last_z = 0
	if this_fp.hitlag_tics != 0:
		this_fp.hitlag_tics -= 1
		if this_fp.hitlag_tics == 0:
			this_fp.is_knockback_paused = FALSE
			if this_fp.proc_lagend.is_valid():
				this_fp.proc_lagend.call(fighter_gobj)
	this_fp.is_events_forward = TRUE
	if this_fp.hitlag_tics == 0:
		ftMainPlayAnimEventsAll(fighter_gobj)
	ftMainRunUpdateColAnim(fighter_gobj)
	if this_fp.intangible_tics != 0:
		this_fp.intangible_tics -= 1
		if this_fp.intangible_tics == 0:
			this_fp.special_hitstatus = nGMHitStatusInvincible if (this_fp.invincible_tics != FALSE) else nGMHitStatusNormal
			if this_fp.colanim.colanim_id == 0xA:
				Ftparam.ftParamResetStatUpdateColAnim(fighter_gobj)
	if this_fp.invincible_tics != 0:
		this_fp.invincible_tics -= 1
		if (this_fp.invincible_tics == 0) and (this_fp.intangible_tics == 0):
			this_fp.special_hitstatus = nGMHitStatusNormal
			if this_fp.colanim.colanim_id == 0xA:
				Ftparam.ftParamResetStatUpdateColAnim(fighter_gobj)
	if this_fp.star_invincible_tics != 0:
		this_fp.star_invincible_tics -= 1
		if this_fp.star_invincible_tics == 0:
			this_fp.star_hitstatus = nGMHitStatusNormal
			if this_fp.colanim.colanim_id == 0x4A:   # REGION_US
				Ftparam.ftParamResetStatUpdateColAnim(fighter_gobj)
		elif this_fp.star_invincible_tics == ITSTAR_WARN_BEGIN_FRAME:
			Ftparam.ftParamTryUpdateItemMusic()
	if this_fp.damage_heal != 0:
		this_fp.damage_heal -= 1
		if this_fp.percent_damage != 0:
			this_fp.percent_damage -= 1
			Snd.func_800269C0_275C0(nSYAudioFGMPlayerHeal)
			G.gSCManagerBattleState.players[this_fp.player].stock_damage_all = this_fp.percent_damage
		if this_fp.percent_damage == 0:
			this_fp.damage_heal = 0
		if (this_fp.damage_heal == 0) and (this_fp.colanim.colanim_id == 0x9):
			Ftparam.ftParamResetStatUpdateColAnim(fighter_gobj)
	if (this_fp.item_gobj != null) and (this_fp.status_id != nFTCommonStatusLightGet) and (itGetStruct(this_fp.item_gobj).kind == nITKindHammer):
		Fthammer.ftHammerUpdateStats(fighter_gobj)
	if this_fp.shuffle_tics != 0:
		this_fp.shuffle_tics -= 1
		this_fp.shuffle_frame_index += 1
		if this_fp.shuffle_frame_index == this_fp.shuffle_index_max:
			this_fp.shuffle_frame_index = 0
	if this_fp.proc_passive.is_valid():
		this_fp.proc_passive.call(fighter_gobj)
	if this_fp.hitlag_tics == 0:
		if (this_fp.playertag_wait > 1) and not B(this_fp.is_control_disable):
			this_fp.playertag_wait -= 1
		if this_fp.proc_update.is_valid():
			this_fp.proc_update.call(fighter_gobj)
		if this_fp.proc_interrupt.is_valid():
			this_fp.proc_interrupt.call(fighter_gobj)
		if not B(this_fp.is_hitstun):
			G.gSCManagerBattleState.players[this_fp.player].combo_damage_foe = 0
			G.gSCManagerBattleState.players[this_fp.player].combo_count_foe = 0
		var is_jostle := FALSE
		this_fp.physics.vel_jostle_x = 0.0
		this_fp.physics.vel_jostle_z = 0.0
		if (this_fp.ga == nMPKineticsGround) and not B(this_fp.is_jostle_ignore):
			var is_check_self := FALSE
			for other_gobj in Sim.get_link(nGCCommonLinkIDFighter):
				var other_fp := ftGetStruct(other_gobj)
				if (fighter_gobj != other_gobj) and (other_fp.capture_gobj == null):
					if (other_fp.ga == nMPKineticsGround) and (this_fp.coll_data.floor_line_id == other_fp.coll_data.floor_line_id):
						var this_attr = this_fp.attr
						var other_attr = other_fp.attr
						var this_jostle: float = this_fp.attr.jostle_width
						var jostle_dist_x: float = (DObjGetStruct(fighter_gobj).translate.x + (this_attr.jostle_x * this_fp.lr)) - (DObjGetStruct(other_gobj).translate.x + (other_attr.jostle_x * other_fp.lr))
						if ABSF(jostle_dist_x) < (this_jostle + other_attr.jostle_width):
							is_jostle = TRUE
							if jostle_dist_x == 0.0:
								this_fp.physics.vel_jostle_x += (6.75 * (-1 if (is_check_self != FALSE) else 1))
							else:
								this_fp.physics.vel_jostle_x += (6.75 * (-1 if (jostle_dist_x < 0.0) else 1))
							var dist_z: float = DObjGetStruct(fighter_gobj).translate.z - DObjGetStruct(other_gobj).translate.z
							if dist_z == 0.0:
								if jostle_dist_x == 0.0:
									this_fp.physics.vel_jostle_z += (3.0 * (-1 if (is_check_self != FALSE) else 1))
								else:
									this_fp.physics.vel_jostle_z += (3.0 * (1 if (jostle_dist_x < 0.0) else -1))
							else:
								this_fp.physics.vel_jostle_z += (3.0 * (-1 if (dist_z < 0.0) else 1))
				else:
					is_check_self = TRUE
			if (is_jostle == FALSE) and (DObjGetStruct(fighter_gobj).translate.z != 0.0):
				this_fp.physics.vel_jostle_z = (1 if (DObjGetStruct(fighter_gobj).translate.z < 0.0) else -1) * 3.0
	this_fp.coll_data.vel_push = Vector3.ZERO

# ---------------------------------------------------------------------------
# Ground obstacles / hazards
# ---------------------------------------------------------------------------
## 0x800E1CF0
static func ftMainClearGroundElementsAll() -> void:
	sFTMainGroundObstaclesNum = 0
	sFTMainGroundHazardsNum = 0
	for o in sFTMainGroundObstacles:
		o.gobj = null
	for h in sFTMainGroundHazards:
		h.gobj = null

## 0x800E1D48
static func ftMainCheckAddGroundObstacle(gobj, proc_update: Callable) -> int:
	for o in sFTMainGroundObstacles:
		if o.gobj == null:
			o.gobj = gobj
			o.proc_update = proc_update
			sFTMainGroundObstaclesNum += 1
			return TRUE
	return FALSE

## 0x800E1D9C
static func ftMainClearGroundObstacle(gobj) -> void:
	for o in sFTMainGroundObstacles:
		if o.gobj == gobj:
			o.gobj = null
			sFTMainGroundObstaclesNum -= 1
			break

## 0x800E1DE8
static func ftMainCheckAddGroundHazard(gobj, proc_update: Callable) -> int:
	for h in sFTMainGroundHazards:
		if h.gobj == null:
			h.gobj = gobj
			h.proc_update = proc_update
			sFTMainGroundHazardsNum += 1
			return TRUE
	return FALSE

## 0x800E1E3C
static func ftMainClearHazard(gobj) -> void:
	for h in sFTMainGroundHazards:
		if h.gobj == gobj:
			h.gobj = null
			sFTMainGroundHazardsNum -= 1
			break

## 0x800E1E88
static func ftMainSetHitHazard(gobj, fighter_gobj, fp: Fighter, kind: int) -> void:
	match kind:
		nGMHitEnvironmentTwister:
			Ftcommontwister.ftCommonTwisterSetStatus(fighter_gobj, gobj)
		nGMHitEnvironmentTaruCann:
			Ftcommontarucann.ftCommonTaruCannSetStatus(fighter_gobj, gobj)

## 0x800E1EE8 - obstacle proc_update(gobj, fighter_gobj) returns {"ret": sb32, "kind": s32}
static func ftMainSearchHitHazard(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	if not B(fp.is_ghost):
		if not B(fp.hitlag_tics):
			if B(fp.twister_wait):
				fp.twister_wait -= 1
			if B(fp.tarucann_wait):
				fp.tarucann_wait -= 1
		for i in sFTMainGroundObstaclesNum:
			var gh = sFTMainGroundObstacles[i]
			if gh.gobj != null:
				var r = gh.proc_update.call(gh.gobj, fighter_gobj)
				if r != null and B(r.ret):
					ftMainSetHitHazard(gh.gobj, fighter_gobj, fp, r.kind)

# ---------------------------------------------------------------------------
# Physics / map process (priorities 4 and 3)
# ---------------------------------------------------------------------------
## 0x800E1FE0
static func ftMainUpdateVelDamageGround(fp: Fighter, move: float) -> void:
	if fp.physics.vel_damage_ground < 0.0:
		fp.physics.vel_damage_ground += move
		if fp.physics.vel_damage_ground > 0.0:
			fp.physics.vel_damage_ground = 0.0
	else:
		fp.physics.vel_damage_ground -= move
		if fp.physics.vel_damage_ground < 0.0:
			fp.physics.vel_damage_ground = 0.0

## 0x800E2048
static func ftMainProcPhysicsMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var topn: DObj = fp.joints[nFTPartsJointTopN]
	fp.coll_data.pos_prev = topn.translate
	if fp.hitlag_tics == 0:
		if fp.cliffcatch_wait != 0:
			fp.cliffcatch_wait -= 1
		if fp.proc_physics.is_valid():
			fp.proc_physics.call(fighter_gobj)
		var vda: Vector3 = fp.physics.vel_damage_air
		if (vda.x != 0.0) or (vda.y != 0.0):
			if fp.ga == nMPKineticsAir:
				var damage_angle: float = syUtilsArcTan2(vda.y, vda.x)
				var vel_damage_new_y: float = vda.x
				var vel_damage_new_x: float = vda.y
				vda.x -= (1.7 * cos(damage_angle))
				vda.y -= (1.7 * sin(damage_angle))
				if ((vda.x * vel_damage_new_y) < 0.0) or ((vda.y * vel_damage_new_x) < 0.0):
					vda.x = 0.0
					vda.y = 0.0
				fp.physics.vel_damage_air = vda
				fp.physics.vel_damage_ground = 0.0
			else:
				if fp.physics.vel_damage_ground == 0.0:
					fp.physics.vel_damage_ground = fp.physics.vel_damage_air.x
				ftMainUpdateVelDamageGround(fp, Mpcollision.dMPCollisionMaterialFrictions[fp.coll_data.floor_flags & MAP_VERTEX_MAT_MASK] * fp.attr.traction * 0.25)
				var floor_angle: Vector3 = fp.coll_data.floor_angle
				fp.physics.vel_damage_air.x = (floor_angle.y * fp.physics.vel_damage_ground)
				fp.physics.vel_damage_air.y = (-floor_angle.x * fp.physics.vel_damage_ground)
		topn.translate += fp.physics.vel_air
		topn.translate.x += fp.physics.vel_damage_air.x
		topn.translate.y += fp.physics.vel_damage_air.y
	if fp.proc_lagupdate.is_valid():
		fp.proc_lagupdate.call(fighter_gobj)
	fp.coll_data.pos_diff = topn.translate - fp.coll_data.pos_prev
	if (fp.ga == nMPKineticsGround) and (fp.coll_data.floor_line_id != -1) and (fp.coll_data.floor_line_id != -2) and (Mpcollision.mpCollisionCheckExistLineID(fp.coll_data.floor_line_id) != FALSE):
		fp.coll_data.vel_speed = Mpcollision.mpCollisionGetSpeedLineID(fp.coll_data.floor_line_id)
		topn.translate += fp.coll_data.vel_speed
	else:
		fp.coll_data.vel_speed = Vector3.ZERO
	Ftcommondead.ftCommonDeadCheckInterruptCommon(fighter_gobj)
	var gd = Mpcollision.gMPCollisionGroundData
	if gd != null and (fp.coll_data.pos_prev.y >= gd.alt_warning) and (topn.translate.y < gd.alt_warning) and (fp.fkind != nFTKindBoss):
		Snd.func_800269C0_275C0(nSYAudioFGMAltitudeWarn)
	if fp.public_knockback != 0:
		var b = Mpcollision.gMPCollisionBounds
		if b != null and (topn.translate.x > (b.current.left + 450.0)) and (topn.translate.x < (b.current.right - 450.0)):
			fp.public_knockback = 0.0
	if fp.proc_map.is_valid():
		fp.coll_data.mask_prev = fp.coll_data.mask_curr
		fp.coll_data.mask_curr = 0
		fp.coll_data.is_coll_end = FALSE
		fp.coll_data.mask_stat = 0
		fp.coll_data.mask_unk = 0
		fp.proc_map.call(fighter_gobj)
		if fp.fkind == nFTKindKirby:
			Ftparam.ftParamKirbyTryMakeMapStarEffect(fighter_gobj)
	if fp.proc_slope.is_valid():
		fp.proc_slope.call(fighter_gobj)
	Ftparam.ftParamsUpdateFighterPartsTransformAll(fp.joints[nFTPartsJointTopN])
	if fp.hitlag_tics == 0:
		ftMainUpdateMotionEventsForwardEffect(fighter_gobj)
	if fp.hitlag_tics == 0:
		if fp.proc_accessory.is_valid():
			fp.proc_accessory.call(fighter_gobj)
	fp.is_events_forward = FALSE
	for i in fp.attack_colls.size():
		var attack_coll: FTAttackColl = fp.attack_colls[i]
		match attack_coll.attack_state:
			nGMAttackStateOff:
				pass
			nGMAttackStateNew:
				attack_coll.pos_curr = attack_coll.offset
				if B(attack_coll.is_scale_pos):
					var size_mul: float = 1.0 / fp.attr.size
					attack_coll.pos_curr *= size_mul
				attack_coll.pos_curr = Gmcollision.gmCollisionGetFighterPartsWorldPosition(attack_coll.joint, attack_coll.pos_curr)
				attack_coll.attack_state = nGMAttackStateTransfer
				attack_coll.attack_matrix_unk_fthitmtx_0x0 = FALSE
				attack_coll.attack_matrix_unk_fthitmtx_0x44 = 0.0
			nGMAttackStateTransfer, nGMAttackStateInterpolate:
				if attack_coll.attack_state == nGMAttackStateTransfer:
					attack_coll.attack_state = nGMAttackStateInterpolate
				attack_coll.pos_prev = attack_coll.pos_curr
				attack_coll.pos_curr = attack_coll.offset
				if B(attack_coll.is_scale_pos):
					var size_mul: float = 1.0 / fp.attr.size
					attack_coll.pos_curr *= size_mul
				attack_coll.pos_curr = Gmcollision.gmCollisionGetFighterPartsWorldPosition(attack_coll.joint, attack_coll.pos_curr)
				attack_coll.attack_matrix_unk_fthitmtx_0x0 = FALSE
				attack_coll.attack_matrix_unk_fthitmtx_0x44 = 0.0

## 0x800E2604
static func ftMainProcPhysicsMapDefault(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	if (fp.capture_gobj == null or B(fp.is_catch_or_capture)) and (fp.catch_gobj == null or not B(fp.is_catch_or_capture)):
		ftMainProcPhysicsMap(fighter_gobj)

## 0x800E2660
static func ftMainProcPhysicsMapCapture(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	if (fp.capture_gobj != null and not B(fp.is_catch_or_capture)) or (fp.catch_gobj != null and B(fp.is_catch_or_capture)):
		ftMainProcPhysicsMap(fighter_gobj)

# ---------------------------------------------------------------------------
# Hit interaction bookkeeping
# ---------------------------------------------------------------------------
## 0x800E26BC
static func ftMainSetHitInteractStats(fp: Fighter, attack_group_id: int, victim_gobj, attack_type: int, victim_group_id: int, ignore_damage_or_hit: int) -> void:
	for i in fp.attack_colls.size():
		var ac: FTAttackColl = fp.attack_colls[i]
		if (ac.attack_state != nGMAttackStateOff) and (attack_group_id == ac.group_id):
			var j := 0
			while j < ac.attack_records.size():
				var rec: GMAttackRecord = ac.attack_records[j]
				if victim_gobj == rec.victim_gobj:
					match attack_type:
						nGMHitTypeDamage:
							rec.victim_flags.is_interact_hurt = TRUE
						nGMHitTypeShield:
							rec.victim_flags.is_interact_shield = TRUE
						nGMHitTypeAttack:
							rec.victim_flags.group_id = victim_group_id
					break
				j += 1
			if j == ac.attack_records.size():
				j = 0
				while j < ac.attack_records.size():
					if ac.attack_records[j].victim_gobj == null:
						break
					j += 1
				if j == ac.attack_records.size():
					j = 0
				var rec2: GMAttackRecord = ac.attack_records[j]
				rec2.victim_gobj = victim_gobj
				match attack_type:
					nGMHitTypeDamage:
						rec2.victim_flags.is_interact_hurt = TRUE
					nGMHitTypeShield:
						rec2.victim_flags.is_interact_shield = TRUE
					nGMHitTypeAttack:
						rec2.victim_flags.group_id = victim_group_id
			if ignore_damage_or_hit == 0:
				gFTMainIsDamageDetect[i] = FALSE
			else:
				gFTMainIsAttackDetect[i] = FALSE

## 0x800E287C
static func ftMainSetHitRebound(attacker_gobj, fp: Fighter, attack_coll: FTAttackColl, victim_gobj) -> void:
	if fp.attack_shield_push < attack_coll.damage:
		fp.attack_shield_push = attack_coll.damage
		if B(attack_coll.can_rebound) and (fp.ga == nMPKineticsGround):
			fp.attack_rebound = (fp.attack_shield_push * 1.62) + 4.0   # REGION_US
			fp.hit_lr = 1 if (DObjGetStruct(attacker_gobj).translate.x < DObjGetStruct(victim_gobj).translate.x) else -1

## 0x800E2910
static func ftMainUpdateAttackStatFighter(other_fp: Fighter, other_hit: FTAttackColl, this_fp: Fighter, this_hit: FTAttackColl, other_gobj, this_gobj) -> void:
	var impact_pos: Vector3 = Gmcollision.gmCollisionGetFighterAttacksPosition(this_hit, other_hit)
	if (this_hit.damage - 10) < other_hit.damage:
		ftMainSetHitInteractStats(this_fp, this_hit.group_id, other_gobj, nGMHitTypeAttack, other_hit.group_id, 1)
		ftMainSetHitRebound(this_gobj, this_fp, this_hit, other_gobj)
		Efmanager.efManagerSetOffMakeEffect(impact_pos, this_hit.damage)
	if (other_hit.damage - 10) < this_hit.damage:
		ftMainSetHitInteractStats(other_fp, other_hit.group_id, this_gobj, nGMHitTypeAttack, this_hit.group_id, 0)
		ftMainSetHitRebound(other_gobj, other_fp, other_hit, this_gobj)
		Efmanager.efManagerSetOffMakeEffect(impact_pos, other_hit.damage)

## 0x800E2A90
static func ftMainUpdateShieldStatFighter(attacker_fp: Fighter, attack_coll: FTAttackColl, victim_fp: Fighter, attacker_gobj, victim_gobj) -> void:
	ftMainSetHitInteractStats(attacker_fp, attack_coll.group_id, victim_gobj, nGMHitTypeShield, 0, 0)
	if attacker_fp.attack_shield_push < attack_coll.damage:
		attacker_fp.attack_shield_push = attack_coll.damage
	victim_fp.shield_damage_total += (attack_coll.damage + attack_coll.shield_damage)
	if victim_fp.shield_damage < attack_coll.damage:
		victim_fp.shield_damage = attack_coll.damage
		victim_fp.shield_lr = 1 if (DObjGetStruct(victim_gobj).translate.x < DObjGetStruct(attacker_gobj).translate.x) else -1
		victim_fp.shield_player = attacker_fp.player
	var impact_pos: Vector3 = Gmcollision.gmCollisionGetFighterAttackShieldPosition(attack_coll, victim_gobj, victim_fp.joints[nFTPartsJointYRotN])
	Efmanager.efManagerSetOffMakeEffect(impact_pos, attack_coll.damage)

## 0x800E2B88
static func ftMainUpdateCatchStatFighter(attacker_fp: Fighter, attack_coll: FTAttackColl, victim_fp: Fighter, attacker_gobj, victim_gobj) -> void:
	ftMainSetHitInteractStats(attacker_fp, attack_coll.group_id, victim_gobj, nGMHitTypeDamage, 0, 1)
	var dist: float
	if DObjGetStruct(victim_gobj).translate.x < DObjGetStruct(attacker_gobj).translate.x:
		dist = -(DObjGetStruct(victim_gobj).translate.x - DObjGetStruct(attacker_gobj).translate.x)
	else:
		dist = DObjGetStruct(victim_gobj).translate.x - DObjGetStruct(attacker_gobj).translate.x
	if dist < attacker_fp.search_gobj_dist:
		attacker_fp.search_gobj_dist = dist
		attacker_fp.search_gobj = victim_gobj

## 0x800E2C24
static func ftMainPlayHitSFX(fp: Fighter, attack_coll: FTAttackColl) -> void:
	if (fp.p_sfx != null) and (fp.p_sfx.sfx_id != 0) and (fp.p_sfx.sfx_id == fp.sfx_id):
		Snd.func_80026738_27338(fp.p_sfx)
	fp.p_sfx = null
	fp.sfx_id = 0
	Lbcommon.lbCommonMakePositionFGM(dFTMainHitCollisionFGMs[attack_coll.fgm_kind][attack_coll.fgm_level], fp.joints[nFTPartsJointTopN].translate.x)

## 0x800E2CC0 - returns {"ret": sb32, "damage": s32}
static func ftMainCheckGetUpdateDamage(fp: Fighter, damage: int) -> Dictionary:
	if B(fp.is_damage_resist):
		fp.damage_resist -= damage
		if fp.damage_resist <= 0:
			fp.is_damage_resist = FALSE
			damage = -fp.damage_resist
	if not B(fp.is_damage_resist):
		fp.damage_queue += damage
		if fp.damage_lag < damage:
			fp.damage_lag = damage
		return {"ret": TRUE, "damage": damage}
	return {"ret": FALSE, "damage": damage}

static func _add_hitlog(cls: int, attack_coll, attack_id: int, attacker_gobj, damage_coll, attacker_player: int, attacker_player_num: int) -> void:
	var logs := _hitlogs()
	if sFTMainHitLogID < logs.size():
		var hitlog: Dictionary = logs[sFTMainHitLogID]
		hitlog.attacker_object_class = cls
		hitlog.attack_coll = attack_coll
		hitlog.attack_id = attack_id
		hitlog.attacker_gobj = attacker_gobj
		hitlog.damage_coll = damage_coll
		hitlog.attacker_player = attacker_player
		hitlog.attacker_player_num = attacker_player_num
		sFTMainHitLogID += 1

## 0x800E2D44
static func ftMainUpdateDamageStatFighter(attacker_fp: Fighter, attack_coll: FTAttackColl, victim_fp: Fighter, damage_coll: FTDamageColl, attacker_gobj, victim_gobj) -> void:
	ftMainSetHitInteractStats(attacker_fp, attack_coll.group_id, victim_gobj, nGMHitTypeDamage, 0, FALSE)
	var damage: int = Ftparam.ftParamGetCapturedDamage(victim_fp, attack_coll.damage)
	if attacker_fp.attack_damage < damage:
		attacker_fp.attack_damage = damage
	if (victim_fp.special_hitstatus == nGMHitStatusNormal) and (victim_fp.star_hitstatus == nGMHitStatusNormal) and (victim_fp.hitstatus == nGMHitStatusNormal) and (damage_coll.hitstatus == nGMHitStatusNormal):
		var r := ftMainCheckGetUpdateDamage(victim_fp, damage)
		damage = r.damage
		if B(r.ret):
			var attacker_player: int
			var attacker_player_num: int
			if attacker_fp.throw_gobj != null:
				attacker_player = attacker_fp.throw_player
				attacker_player_num = attacker_fp.throw_player_num
			else:
				attacker_player = attacker_fp.player
				attacker_player_num = attacker_fp.player_num
			_add_hitlog(nFTHitLogObjectFighter, attack_coll, 0, attacker_gobj, damage_coll, attacker_player, attacker_player_num)
			Ftparam.ftParamUpdatePlayerBattleStats(attacker_player, victim_fp.player, damage)
			Ftparam.ftParamUpdateStaleQueue(attacker_player, victim_fp.player, attack_coll.motion_attack_id, attack_coll.motion_count)
		else:
			var impact_pos: Vector3 = Gmcollision.gmCollisionGetFighterAttackDamagePosition(attack_coll, damage_coll)
			Efmanager.efManagerSetOffMakeEffect(impact_pos, damage)
	else:
		var impact_pos2: Vector3 = Gmcollision.gmCollisionGetFighterAttackDamagePosition(attack_coll, damage_coll)
		Efmanager.efManagerSetOffMakeEffect(impact_pos2, damage)
	ftMainPlayHitSFX(attacker_fp, attack_coll)

## 0x800E2F04
static func ftMainUpdateAttackStatWeapon(ip: Weapon, wp_attack_coll: WPAttackColl, index: int, fp: Fighter, ft_attack_coll: FTAttackColl, weapon_gobj, fighter_gobj) -> void:
	var damage: int = Wpmain.wpMainGetStaledDamage(ip)
	var impact_pos: Vector3 = Gmcollision.gmCollisionGetWeaponAttackFighterAttackPosition(wp_attack_coll, index, ft_attack_coll)
	if (ft_attack_coll.damage - 10) < damage:
		ftMainSetHitInteractStats(fp, ft_attack_coll.group_id, weapon_gobj, nGMHitTypeAttack, 0, TRUE)
		ftMainSetHitRebound(fighter_gobj, fp, ft_attack_coll, weapon_gobj)
		Efmanager.efManagerSetOffMakeEffect(impact_pos, ft_attack_coll.damage)
	if (damage - 10) < ft_attack_coll.damage:
		Wpprocess.wpProcessUpdateHitInteractStats(ip, wp_attack_coll, fighter_gobj, nGMHitTypeAttack, ft_attack_coll.group_id)
		if ip.hit_attack_damage < damage:
			ip.hit_attack_damage = damage
		Efmanager.efManagerSetOffMakeEffect(impact_pos, damage)

## 0x800E3048
static func ftMainUpdateShieldStatWeapon(wp: Weapon, wp_attack_coll: WPAttackColl, attack_id: int, fp: Fighter, weapon_gobj, fighter_gobj, angle: float, dir: Vector3) -> void:
	var damage: int = Wpmain.wpMainGetStaledDamage(wp)
	Wpprocess.wpProcessUpdateHitInteractStats(wp, wp_attack_coll, fighter_gobj, nGMHitTypeShieldRehit if B(wp_attack_coll.can_rehit_shield) else nGMHitTypeShield, 0)
	if wp.hit_shield_damage < damage:
		wp.hit_shield_damage = damage
		wp.shield_collide_angle = angle
		wp.shield_collide_dir = Vector3(0.0, 0.0, -dir.x if (fp.lr == 1) else dir.x)
		wp.shield_collide_dir = syVectorNorm3D(wp.shield_collide_dir)
	fp.shield_damage_total += damage + wp_attack_coll.shield_damage
	if fp.shield_damage < damage:
		fp.shield_damage = damage
		fp.shield_lr = 1 if (wp.physics.vel_air.x < 0.0) else -1
		fp.shield_player = wp.player
	var impact_pos: Vector3 = Gmcollision.gmCollisionGetWeaponAttackShieldPosition(wp_attack_coll, attack_id, fighter_gobj, fp.joints[nFTPartsJointYRotN])
	Efmanager.efManagerSetOffMakeEffect(impact_pos, wp_attack_coll.shield_damage + damage)

## 0x800E31B4
static func ftMainUpdateReflectorStatWeapon(wp: Weapon, wp_attack_coll: WPAttackColl, fp: Fighter, fighter_gobj) -> void:
	var damage: int = Wpmain.wpMainGetStaledDamage(wp)
	Wpprocess.wpProcessUpdateHitInteractStats(wp, wp_attack_coll, fighter_gobj, nGMHitTypeReflect, 0)
	if fp.special_coll.damage_resist < damage:
		if B(wp_attack_coll.can_rehit_fighter):
			if wp.hit_refresh_damage < damage:
				wp.hit_refresh_damage = damage
		elif wp.hit_normal_damage < damage:
			wp.hit_normal_damage = damage
		fp.reflect_damage = damage
		fp.reflect_lr = 1 if (DObjGetStruct(fighter_gobj).translate.x < DObjGetStruct(wp.weapon_gobj).translate.x) else -1
	else:
		wp.reflect_gobj = fighter_gobj
		# REGION_US oversight preserved: stat flags of the reflector are copied, not its attack id.
		wp.reflect_stat_flags = fp.stat_flags.dup()
		wp.reflect_stat_count = fp.stat_count
		fp.reflect_lr = 1 if (DObjGetStruct(fighter_gobj).translate.x < DObjGetStruct(wp.weapon_gobj).translate.x) else -1

## 0x800E3308
static func ftMainUpdateAbsorbStatWeapon(wp: Weapon, wp_attack_coll: WPAttackColl, fp: Fighter, fighter_gobj) -> void:
	var damage: int = Wpmain.wpMainGetStaledDamage(wp)
	Wpprocess.wpProcessUpdateHitInteractStats(wp, wp_attack_coll, fighter_gobj, nGMHitTypeAbsorb, 0)
	wp.absorb_gobj = fighter_gobj
	fp.absorb_lr = 1 if (DObjGetStruct(fighter_gobj).translate.x < DObjGetStruct(wp.weapon_gobj).translate.x) else -1
	if not B(wp_attack_coll.can_not_heal):
		fp.percent_damage -= int(damage * 2.0)
		if fp.percent_damage < 0:
			fp.percent_damage = 0
		G.gSCManagerBattleState.players[fp.player].stock_damage_all = fp.percent_damage

## 0x800E3418
static func ftMainUpdateDamageStatWeapon(wp: Weapon, wp_attack_coll: WPAttackColl, wp_attack_id: int, fp: Fighter, damage_coll: FTDamageColl, weapon_gobj, fighter_gobj) -> void:
	var temp_damage: int = Wpmain.wpMainGetStaledDamage(wp)
	Wpprocess.wpProcessUpdateHitInteractStats(wp, wp_attack_coll, fighter_gobj, nGMHitTypeDamageRehit if B(wp_attack_coll.can_rehit_fighter) else nGMHitTypeDamage, 0)
	var damage: int = Ftparam.ftParamGetCapturedDamage(fp, temp_damage)
	if B(wp_attack_coll.can_rehit_fighter):
		if wp.hit_refresh_damage < damage:
			wp.hit_refresh_damage = damage
	elif wp.hit_normal_damage < damage:
		wp.hit_normal_damage = damage
	if (fp.special_hitstatus == nGMHitStatusNormal) and (fp.star_hitstatus == nGMHitStatusNormal) and (fp.hitstatus == nGMHitStatusNormal) and (damage_coll.hitstatus == nGMHitStatusNormal):
		var r := ftMainCheckGetUpdateDamage(fp, damage)
		damage = r.damage
		if B(r.ret):
			_add_hitlog(nFTHitLogObjectWeapon, wp_attack_coll, wp_attack_id, weapon_gobj, damage_coll, wp.player, wp.player_num)
			Ftparam.ftParamUpdatePlayerBattleStats(wp.player, fp.player, damage)
			Ftparam.ftParamUpdateStaleQueue(wp.player, fp.player, wp_attack_coll.motion_attack_id, wp_attack_coll.motion_count)
	Snd.func_800269C0_275C0(wp_attack_coll.fgm_id)

## 0x800E35BC
static func ftMainUpdateAttackStatItem(ip: Item, it_attack_coll: ITAttackColl, it_attack_id: int, fp: Fighter, ft_attack_coll: FTAttackColl, item_gobj, fighter_gobj) -> void:
	var damage: int = Itmain.itMainGetDamageOutput(ip)
	var impact_pos: Vector3 = Gmcollision.gmCollisionGetItemAttackFighterAttackPosition(it_attack_coll, it_attack_id, ft_attack_coll)
	if (ft_attack_coll.damage - 10) < damage:
		ftMainSetHitInteractStats(fp, ft_attack_coll.group_id, item_gobj, nGMHitTypeAttack, 0, 1)
		ftMainSetHitRebound(fighter_gobj, fp, ft_attack_coll, item_gobj)
		Efmanager.efManagerSetOffMakeEffect(impact_pos, ft_attack_coll.damage)
	if (damage - 10) < ft_attack_coll.damage:
		Itprocess.itProcessSetHitInteractStats(it_attack_coll, fighter_gobj, nGMHitTypeAttack, ft_attack_coll.group_id)
		if ip.hit_attack_damage < damage:
			ip.hit_attack_damage = damage
		Efmanager.efManagerSetOffMakeEffect(impact_pos, damage)

## 0x800E36F8
static func ftMainUpdateShieldStatItem(ip: Item, it_attack_coll: ITAttackColl, attack_id: int, fp: Fighter, item_gobj, fighter_gobj, angle: float, vec: Vector3) -> void:
	var damage: int = Itmain.itMainGetDamageOutput(ip)
	Itprocess.itProcessSetHitInteractStats(it_attack_coll, fighter_gobj, nGMHitTypeShieldRehit if B(it_attack_coll.can_rehit_shield) else nGMHitTypeShield, 0)
	if ip.hit_shield_damage < damage:
		ip.hit_shield_damage = damage
		ip.shield_collide_angle = angle
		ip.shield_collide_dir = Vector3(0.0, 0.0, -vec.x if (fp.lr == 1) else vec.x)
		ip.shield_collide_dir = syVectorNorm3D(ip.shield_collide_dir)
	fp.shield_damage_total += damage + it_attack_coll.shield_damage
	if fp.shield_damage < damage:
		fp.shield_damage = damage
		fp.shield_lr = 1 if (ip.physics.vel_air.x < 0.0) else -1
		fp.shield_player = ip.player
	var impact_pos: Vector3 = Gmcollision.gmCollisionGetItemAttackShieldPosition(it_attack_coll, attack_id, fighter_gobj, fp.joints[nFTPartsJointYRotN])
	Efmanager.efManagerSetOffMakeEffect(impact_pos, it_attack_coll.shield_damage + damage)

## 0x800E3860
static func ftMainUpdateReflectorStatItem(ip: Item, it_attack_coll: ITAttackColl, fp: Fighter, fighter_gobj) -> void:
	var damage: int = Itmain.itMainGetDamageOutput(ip)
	Itprocess.itProcessSetHitInteractStats(it_attack_coll, fighter_gobj, nGMHitTypeReflect, 0)
	if fp.special_coll.damage_resist < damage:
		if B(it_attack_coll.can_rehit_fighter):
			if ip.hit_refresh_damage < damage:
				ip.hit_refresh_damage = damage
		elif ip.hit_normal_damage < damage:
			ip.hit_normal_damage = damage
		fp.reflect_damage = damage
		fp.reflect_lr = 1 if (DObjGetStruct(fighter_gobj).translate.x < DObjGetStruct(ip.item_gobj).translate.x) else -1
	else:
		ip.reflect_gobj = fighter_gobj
		ip.reflect_stat_flags = fp.stat_flags.dup()
		ip.reflect_stat_count = fp.stat_count
		fp.reflect_lr = 1 if (DObjGetStruct(fighter_gobj).translate.x < DObjGetStruct(ip.item_gobj).translate.x) else -1

## 0x800E39B0
static func ftMainUpdateDamageStatItem(ip: Item, it_attack_coll: ITAttackColl, attack_id: int, fp: Fighter, damage_coll: FTDamageColl, item_gobj, fighter_gobj) -> void:
	var damage_temp: int = Itmain.itMainGetDamageOutput(ip)
	Itprocess.itProcessSetHitInteractStats(it_attack_coll, fighter_gobj, nGMHitTypeDamageRehit if B(it_attack_coll.can_rehit_fighter) else nGMHitTypeDamage, 0)
	if ip.type == nITTypeTouch:
		match ip.kind:
			nITKindStar:
				it_attack_coll.attack_state = nGMAttackStateOff
				ip.hit_normal_damage = 1
				Ftparam.ftParamSetStarHitStatusInvincible(fp, ITSTAR_INVINCIBLE_TIME)
				Ftparam.ftParamTryPlayItemMusic(nSYAudioBGMStar)
				Snd.func_800269C0_275C0(nSYAudioFGMStarGet)
			nITKindGLucky:
				Ftparam.ftParamSetHealDamage(fp, it_attack_coll.damage)
	else:
		var damage: int = Ftparam.ftParamGetCapturedDamage(fp, damage_temp)
		if B(it_attack_coll.can_rehit_fighter):
			if ip.hit_refresh_damage < damage:
				ip.hit_refresh_damage = damage
		elif ip.hit_normal_damage < damage:
			ip.hit_normal_damage = damage
		if ABSF(ip.physics.vel_air.x) < 5.0:
			ip.hit_lr = -1 if (DObjGetStruct(fighter_gobj).translate.x < DObjGetStruct(item_gobj).translate.x) else 1
		else:
			ip.hit_lr = -1 if (ip.physics.vel_air.x < 0) else 1
		if (fp.special_hitstatus == nGMHitStatusNormal) and (fp.star_hitstatus == nGMHitStatusNormal) and (fp.hitstatus == nGMHitStatusNormal) and (damage_coll.hitstatus == nGMHitStatusNormal):
			var r := ftMainCheckGetUpdateDamage(fp, damage)
			damage = r.damage
			if B(r.ret):
				_add_hitlog(nFTHitLogObjectItem, it_attack_coll, attack_id, item_gobj, damage_coll, ip.player, ip.player_num)
				Ftparam.ftParamUpdatePlayerBattleStats(ip.player, fp.player, damage)
				Ftparam.ftParamUpdateStaleQueue(ip.player, fp.player, it_attack_coll.motion_attack_id, it_attack_coll.motion_count)
		Snd.func_800269C0_275C0(it_attack_coll.fgm_id)

## 0x800E3CAC
static func ftMainUpdateDamageStatGround(special_gobj, fighter_gobj, fp: Fighter, gr_attack_coll: Dictionary, kind: int) -> void:
	var damage: int = Ftparam.ftParamGetCapturedDamage(fp, gr_attack_coll.damage)
	var r := ftMainCheckGetUpdateDamage(fp, damage)
	damage = r.damage
	var is_take_damage: int = r.ret
	if (is_take_damage != FALSE) and (sFTMainHitLogID < _hitlogs().size()):
		_add_hitlog(nFTHitLogObjectGround, gr_attack_coll, 0, special_gobj, null, 0, 0)
	match kind:
		nGMHitEnvironmentAcid:
			fp.acid_wait = 30
			Snd.func_800269C0_275C0(nSYAudioFGMFloorDamageFire)
		nGMHitEnvironmentPowerBlock:
			if is_take_damage != FALSE:
				Ftparam.ftParamUpdatePlayerBattleStats(itGetStruct(special_gobj).damage_port, fp.player, damage)
		4, 5, 6, 7, 8, 9:
			fp.damagefloor_wait = 16
			if kind == 7:
				Snd.func_800269C0_275C0(nSYAudioFGMShockML)
			else:
				Snd.func_800269C0_275C0(nSYAudioFGMFloorDamageFire)

## 0x800E3DD0
static func ftMainGetBumperDamageAngle(fighter_gobj, attacker_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	if fp.damage_angle == 362:
		var dist_x: float = DObjGetStruct(fighter_gobj).translate.x - DObjGetStruct(attacker_gobj).translate.x
		fp.damage_lr = 1 if (dist_x < 0) else -1
		if dist_x < 0.0:
			dist_x = -dist_x
		var dist_y: float = (DObjGetStruct(fighter_gobj).translate.y + fp.coll_data.map_coll.center) - DObjGetStruct(attacker_gobj).translate.y
		fp.damage_angle = 0 if (dist_x == 0) else int(F_CLC_RTOD32(syUtilsArcTan(dist_y / dist_x)))

## 0x800E3EBC
static func ftMainProcessHitCollisionStatsMain(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var attr = this_fp.attr
	var knockback: float = -1.0
	var knockback_temp: float = 0.0
	var j := 0
	var logs := _hitlogs()
	for i in sFTMainHitLogID:
		var hitlog: Dictionary = logs[i]
		match hitlog.attacker_object_class:
			nFTHitLogObjectFighter:
				var ft_attack_coll: FTAttackColl = hitlog.attack_coll
				var attacker_fp := ftGetStruct(hitlog.attacker_gobj)
				knockback_temp = Ftparam.ftParamGetCommonKnockback(this_fp.percent_damage, this_fp.damage_queue, ft_attack_coll.damage, ft_attack_coll.knockback_weight, ft_attack_coll.knockback_scale, ft_attack_coll.knockback_base, attr.weight, attacker_fp.handicap, this_fp.handicap)
				var pos: Vector3 = Gmcollision.gmCollisionGetFighterAttackDamagePosition(ft_attack_coll, hitlog.damage_coll)
				match ft_attack_coll.element:
					nGMHitElementFire:
						Efmanager.efManagerDamageFireMakeEffect(pos, ft_attack_coll.damage)
					nGMHitElementElectric:
						Efmanager.efManagerDamageElectricMakeEffect(pos, ft_attack_coll.damage)
					nGMHitElementCoin:
						Efmanager.efManagerDamageCoinMakeEffect(pos)
					nGMHitElementSlash:
						Efmanager.efManagerDamageSlashMakeEffect(pos, ft_attack_coll.damage, Gmcollision.gmCollisionGetDamageSlashRotation(attacker_fp, ft_attack_coll))
					_:
						if knockback_temp < 180.0:
							Efmanager.efManagerDamageNormalLightMakeEffect(pos, hitlog.attacker_player, ft_attack_coll.damage, 0)
						else:
							Efmanager.efManagerDamageNormalHeavyMakeEffect(pos, hitlog.attacker_player, ft_attack_coll.damage)
						if ft_attack_coll.fgm_level > 0:
							Efmanager.efManagerDamageSpawnOrbsRandomMakeEffect(pos)
							if attr.is_metallic == FALSE:
								Efmanager.efManagerDamageSpawnSparksRandomMakeEffect(pos, this_fp.lr)
							else:
								Efmanager.efManagerDamageSpawnMDustRandomMakeEffect(pos, this_fp.lr)
			nFTHitLogObjectWeapon:
				var wp_attack_coll: WPAttackColl = hitlog.attack_coll
				var wp := wpGetStruct(hitlog.attacker_gobj)
				var damage: int = Wpmain.wpMainGetStaledDamage(wp)
				knockback_temp = Ftparam.ftParamGetCommonKnockback(this_fp.percent_damage, this_fp.damage_queue, damage, wp_attack_coll.knockback_weight, wp_attack_coll.knockback_scale, wp_attack_coll.knockback_base, attr.weight, wp.handicap, this_fp.handicap)
				if B(wp.is_hitlag_victim):
					var pos2: Vector3 = Gmcollision.gmCollisionGetWeaponAttackFighterDamagePosition(wp_attack_coll, hitlog.attack_id, hitlog.damage_coll)
					match wp_attack_coll.element:
						nGMHitElementFire:
							Efmanager.efManagerDamageFireMakeEffect(pos2, damage)
						nGMHitElementElectric:
							Efmanager.efManagerDamageElectricMakeEffect(pos2, damage)
						nGMHitElementCoin:
							Efmanager.efManagerDamageCoinMakeEffect(pos2)
						_:
							if knockback_temp < 180.0:
								Efmanager.efManagerDamageNormalLightMakeEffect(pos2, hitlog.attacker_player, damage, null)
							else:
								Efmanager.efManagerDamageNormalHeavyMakeEffect(pos2, hitlog.attacker_player, damage)
			nFTHitLogObjectItem:
				var it_attack_coll: ITAttackColl = hitlog.attack_coll
				var ip := itGetStruct(hitlog.attacker_gobj)
				var damage3: int = Itmain.itMainGetDamageOutput(ip)
				knockback_temp = Ftparam.ftParamGetCommonKnockback(this_fp.percent_damage, this_fp.damage_queue, damage3, it_attack_coll.knockback_weight, it_attack_coll.knockback_scale, it_attack_coll.knockback_base, attr.weight, ip.handicap, this_fp.handicap)
				if B(ip.is_hitlag_victim):
					var pos3: Vector3 = Gmcollision.gmCollisionGetItemAttackFighterDamagePosition(it_attack_coll, hitlog.attack_id, hitlog.damage_coll)
					match it_attack_coll.element:
						nGMHitElementFire:
							Efmanager.efManagerDamageFireMakeEffect(pos3, damage3)
						nGMHitElementElectric:
							Efmanager.efManagerDamageElectricMakeEffect(pos3, damage3)
						nGMHitElementCoin:
							Efmanager.efManagerDamageCoinMakeEffect(pos3)
						_:
							if knockback_temp < 180.0:
								Efmanager.efManagerDamageNormalLightMakeEffect(pos3, hitlog.attacker_player, damage3, null)
							else:
								Efmanager.efManagerDamageNormalHeavyMakeEffect(pos3, hitlog.attacker_player, damage3)
			nFTHitLogObjectGround:
				var gr_attack_coll: Dictionary = hitlog.attack_coll
				var gr_handicap: int
				if gr_attack_coll.kind == nGMHitEnvironmentPowerBlock:
					gr_handicap = itGetStruct(hitlog.attacker_gobj).damage_handicap
				else:
					gr_handicap = 9
				knockback_temp = Ftparam.ftParamGetCommonKnockback(this_fp.percent_damage, this_fp.damage_queue, gr_attack_coll.damage, gr_attack_coll.knockback_weight, gr_attack_coll.knockback_scale, gr_attack_coll.knockback_base, attr.weight, gr_handicap, this_fp.handicap)
		if knockback < knockback_temp:
			knockback = knockback_temp
			j = i
	var hl: Dictionary = logs[j]
	var attacker_gobj = hl.attacker_gobj
	match hl.attacker_object_class:
		nFTHitLogObjectFighter:
			var ft_attack_coll: FTAttackColl = hl.attack_coll
			var attacker_fp := ftGetStruct(attacker_gobj)
			this_fp.damage_angle = ft_attack_coll.angle
			this_fp.damage_element = ft_attack_coll.element
			this_fp.damage_lr = 1 if (DObjGetStruct(fighter_gobj).translate.x < DObjGetStruct(attacker_gobj).translate.x) else -1
			this_fp.damage_player_num = hl.attacker_player_num
			Ftparam.ftParamUpdate1PGameDamageStats(this_fp, hl.attacker_player, hl.attacker_object_class, attacker_fp.fkind, attacker_fp.stat_flags.halfword & ~0x400, attacker_fp.stat_count)
			this_fp.damage_joint_id = hl.damage_coll.joint_id
			this_fp.damage_index = hl.damage_coll.placement
			if this_fp.damage_element == nGMHitElementElectric:
				attacker_fp.hitlag_mul = 1.5
		nFTHitLogObjectWeapon:
			var wp_attack_coll: WPAttackColl = hl.attack_coll
			var wp := wpGetStruct(attacker_gobj)
			this_fp.damage_angle = wp_attack_coll.angle
			this_fp.damage_element = wp_attack_coll.element
			if ABSF(wp.physics.vel_air.x) < 5.0:
				this_fp.damage_lr = 1 if (DObjGetStruct(fighter_gobj).translate.x < DObjGetStruct(attacker_gobj).translate.x) else -1
			else:
				this_fp.damage_lr = 1 if (wp.physics.vel_air.x < 0) else -1
			if this_fp.player == hl.attacker_player:
				this_fp.damage_player_num = 0
				Ftparam.ftParamUpdate1PGameDamageStats(this_fp, GMCOMMON_PLAYERS_MAX, hl.attacker_object_class, wp.kind, 0, 0)
			else:
				this_fp.damage_player_num = hl.attacker_player_num
				Ftparam.ftParamUpdate1PGameDamageStats(this_fp, hl.attacker_player, hl.attacker_object_class, wp.kind, wp_attack_coll.stat_flags.halfword, wp_attack_coll.stat_count)
			this_fp.damage_joint_id = hl.damage_coll.joint_id
			this_fp.damage_index = hl.damage_coll.placement
			ftMainGetBumperDamageAngle(fighter_gobj, attacker_gobj)
		nFTHitLogObjectItem:
			var it_attack_coll: ITAttackColl = hl.attack_coll
			var ip := itGetStruct(attacker_gobj)
			this_fp.damage_angle = it_attack_coll.angle
			this_fp.damage_element = it_attack_coll.element
			if ABSF(ip.physics.vel_air.x) < 5.0:
				this_fp.damage_lr = 1 if (DObjGetStruct(fighter_gobj).translate.x < DObjGetStruct(attacker_gobj).translate.x) else -1
			else:
				this_fp.damage_lr = 1 if (ip.physics.vel_air.x < 0) else -1
			if this_fp.player == hl.attacker_player:
				this_fp.damage_player_num = 0
				Ftparam.ftParamUpdate1PGameDamageStats(this_fp, GMCOMMON_PLAYERS_MAX, hl.attacker_object_class, ip.kind, 0, 0)
			else:
				this_fp.damage_player_num = hl.attacker_player_num
				Ftparam.ftParamUpdate1PGameDamageStats(this_fp, hl.attacker_player, hl.attacker_object_class, ip.kind, it_attack_coll.stat_flags.halfword, it_attack_coll.stat_count)
			this_fp.damage_joint_id = hl.damage_coll.joint_id
			this_fp.damage_index = hl.damage_coll.placement
			ftMainGetBumperDamageAngle(fighter_gobj, attacker_gobj)
		nFTHitLogObjectGround:
			var gr_attack_coll2: Dictionary = hl.attack_coll
			this_fp.damage_angle = gr_attack_coll2.angle
			this_fp.damage_element = gr_attack_coll2.element
			this_fp.damage_lr = this_fp.lr
			match gr_attack_coll2.kind:
				nGMHitEnvironmentAcid:
					this_fp.damage_player_num = 0
					if this_fp.damage_player == -1:
						this_fp.damage_player = GMCOMMON_PLAYERS_MAX
					Ftparam.ftParamUpdate1PGameDamageStats(this_fp, this_fp.damage_player, hl.attacker_object_class, gr_attack_coll2.kind, 0, 0)
				nGMHitEnvironmentPowerBlock:
					var ip2 := itGetStruct(attacker_gobj)
					this_fp.damage_player_num = ip2.damage_player_num
					Ftparam.ftParamUpdate1PGameDamageStats(this_fp, ip2.damage_port, hl.attacker_object_class, gr_attack_coll2.kind, 0, 0)
				_:
					this_fp.damage_player_num = 0
					Ftparam.ftParamUpdate1PGameDamageStats(this_fp, GMCOMMON_PLAYERS_MAX, hl.attacker_object_class, gr_attack_coll2.kind, 0, 0)
			this_fp.damage_joint_id = 0
			this_fp.damage_index = 0
	this_fp.damage_knockback = knockback
	if this_fp.damage_element == nGMHitElementElectric:
		this_fp.hitlag_mul = 1.5

# ---------------------------------------------------------------------------
# Hit searches (priority 1)
# ---------------------------------------------------------------------------
static func _flags_for(records: Array, victim) -> GMHitFlags:
	for rec in records:
		if victim == rec.victim_gobj:
			return rec.victim_flags.dup()
	var f := GMHitFlags.new()
	f.group_id = 7
	return f

static func _is_team_battle_no_attack() -> bool:
	var bs = G.gSCManagerBattleState
	return (bs.is_team_battle == TRUE) and (bs.is_team_attack == FALSE)

## 0x800E4870
static func ftMainSearchHitFighter(this_gobj) -> void:
	var this_fp := ftGetStruct(this_gobj)
	var is_check_self := FALSE
	for other_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		if other_gobj == this_gobj:
			is_check_self = TRUE
			continue
		elif other_gobj == this_fp.capture_gobj:
			continue
		var other_fp := ftGetStruct(other_gobj)
		if _is_team_battle_no_attack() and (((other_fp.throw_team if other_fp.throw_gobj != null else other_fp.team)) == this_fp.team):
			continue
		if B(other_fp.is_catchstatus):
			continue
		if (other_fp.throw_gobj != null) and (this_gobj == other_fp.throw_gobj):
			continue
		var k := 0
		for i in other_fp.attack_colls.size():
			var other_attack_coll: FTAttackColl = other_fp.attack_colls[i]
			var set_true := false
			if other_attack_coll.attack_state != nGMAttackStateOff:
				if ((this_fp.ga == nMPKineticsAir) and B(other_attack_coll.is_hit_air)) or ((this_fp.ga == nMPKineticsGround) and B(other_attack_coll.is_hit_ground)):
					var these_flags := _flags_for(other_attack_coll.attack_records, this_gobj)
					if not B(these_flags.is_interact_hurt) and not B(these_flags.is_interact_shield) and (these_flags.group_id == 7):
						set_true = true
			if set_true:
				gFTMainIsDamageDetect[i] = TRUE
				k += 1
			else:
				gFTMainIsDamageDetect[i] = FALSE
		if k == 0:
			continue
		k = 0
		if (is_check_self != FALSE) and (this_gobj != other_fp.capture_gobj) and (other_fp.ga == nMPKineticsGround) and (this_fp.ga == nMPKineticsGround) and not B(this_fp.is_catchstatus):
			var bs = G.gSCManagerBattleState
			if (this_fp.throw_gobj == null) or ((other_gobj != this_fp.throw_gobj) and (((bs.is_team_battle != TRUE) or (bs.is_team_attack != FALSE)) or ((other_fp.throw_team if other_fp.throw_gobj != null else other_fp.team) != this_fp.throw_team))):
				var l := 0
				for i in this_fp.attack_colls.size():
					var this_attack_coll: FTAttackColl = this_fp.attack_colls[i]
					var set_true := false
					if this_attack_coll.attack_state != nGMAttackStateOff:
						if ((other_fp.ga == nMPKineticsAir) and B(this_attack_coll.is_hit_air)) or ((other_fp.ga == nMPKineticsGround) and B(this_attack_coll.is_hit_ground)):
							var those_flags := _flags_for(this_attack_coll.attack_records, other_gobj)
							if not B(those_flags.is_interact_hurt) and not B(those_flags.is_interact_shield) and (those_flags.group_id == 7):
								set_true = true
					if set_true:
						gFTMainIsAttackDetect[i] = TRUE
						l += 1
					else:
						gFTMainIsAttackDetect[i] = FALSE
				if l != 0:
					for i in other_fp.attack_colls.size():
						var other_attack_coll: FTAttackColl = other_fp.attack_colls[i]
						if gFTMainIsDamageDetect[i] == FALSE:
							continue
						for jj in this_fp.attack_colls.size():
							var this_attack_coll: FTAttackColl = this_fp.attack_colls[jj]
							if gFTMainIsAttackDetect[jj] == FALSE:
								continue
							elif Gmcollision.gmCollisionCheckFighterAttacksCollide(other_attack_coll, this_attack_coll) != FALSE:
								ftMainUpdateAttackStatFighter(other_fp, other_attack_coll, this_fp, this_attack_coll, other_gobj, this_gobj)
								if gFTMainIsDamageDetect[i] == FALSE:
									break
		for i in other_fp.attack_colls.size():
			var other_attack_coll: FTAttackColl = other_fp.attack_colls[i]
			if gFTMainIsDamageDetect[i] == FALSE:
				continue
			gFTMainIsDamageDetect[i] = Gmcollision.gmCollisionCheckFighterInFighterRange(other_attack_coll, this_gobj)
			if gFTMainIsDamageDetect[i] != FALSE:
				k += 1
		if k != 0:
			if B(this_fp.is_shield):
				for i in other_fp.attack_colls.size():
					var other_attack_coll: FTAttackColl = other_fp.attack_colls[i]
					if gFTMainIsDamageDetect[i] == FALSE:
						continue
					var r = Gmcollision.gmCollisionCheckFighterAttackShieldCollide(other_attack_coll, this_gobj, this_fp.joints[nFTPartsJointYRotN])
					if B(r.ret):
						ftMainUpdateShieldStatFighter(other_fp, other_attack_coll, this_fp, other_gobj, this_gobj)
			if (this_fp.special_hitstatus != nGMHitStatusIntangible) and (this_fp.star_hitstatus != nGMHitStatusIntangible) and (this_fp.hitstatus != nGMHitStatusIntangible):
				for i in other_fp.attack_colls.size():
					var other_attack_coll: FTAttackColl = other_fp.attack_colls[i]
					if gFTMainIsDamageDetect[i] == FALSE:
						continue
					for jj in this_fp.damage_colls.size():
						var damage_coll: FTDamageColl = this_fp.damage_colls[jj]
						if damage_coll.hitstatus == nGMHitStatusNone:
							break
						if damage_coll.hitstatus != nGMHitStatusIntangible:
							if Gmcollision.gmCollisionCheckFighterAttackDamageCollide(other_attack_coll, damage_coll) != FALSE:
								ftMainUpdateDamageStatFighter(other_fp, other_attack_coll, this_fp, damage_coll, other_gobj, this_gobj)
								break

## 0x800E4ED4
static func ftMainSearchHitWeapon(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var bs = G.gSCManagerBattleState
	for weapon_gobj in Sim.get_link(nGCCommonLinkIDWeapon):
		if not weapon_gobj.is_alive:
			continue
		var wp := wpGetStruct(weapon_gobj)
		var wp_attack_coll: WPAttackColl = wp.attack_coll
		if (fighter_gobj != wp.owner_gobj) and ((bs.is_team_battle != TRUE) or (bs.is_team_attack != FALSE) or (fp.team != wp.team)) and (wp_attack_coll.attack_state != nGMAttackStateOff):
			if wp_attack_coll.interact_mask & GMHITCOLLISION_FLAG_FIGHTER:
				var weapon_flags := _flags_for(wp_attack_coll.attack_records, fighter_gobj)
				if not B(weapon_flags.is_interact_hurt) and not B(weapon_flags.is_interact_shield) and not B(weapon_flags.is_interact_reflect) and not B(weapon_flags.is_interact_absorb) and (weapon_flags.group_id == 7):
					if B(wp_attack_coll.can_setoff) and not B(fp.is_catchstatus) and ((fp.throw_gobj == null) or ((fp.throw_gobj != wp.owner_gobj) and ((bs.is_team_battle != TRUE) or (bs.is_team_attack != FALSE) or (fp.throw_team != wp.team)))):
						if not B(fp.is_reflect) or not B(wp_attack_coll.can_reflect):
							var k := 0
							for i in fp.attack_colls.size():
								var ft_attack_coll: FTAttackColl = fp.attack_colls[i]
								var set_true := false
								if (ft_attack_coll.attack_state != nGMAttackStateOff) and (((wp.ga == nMPKineticsAir) and B(ft_attack_coll.is_hit_air)) or ((wp.ga == nMPKineticsGround) and B(ft_attack_coll.is_hit_ground))):
									var fighter_flags := _flags_for(ft_attack_coll.attack_records, weapon_gobj)
									if fighter_flags.group_id == 7:
										set_true = true
								if set_true:
									gFTMainIsAttackDetect[i] = TRUE
									k += 1
								else:
									gFTMainIsAttackDetect[i] = FALSE
							if k != 0:
								var done := false
								for i in wp_attack_coll.attack_count:
									for jj in fp.attack_colls.size():
										var ft_attack_coll: FTAttackColl = fp.attack_colls[jj]
										if gFTMainIsAttackDetect[jj] == FALSE:
											continue
										elif Gmcollision.gmCollisionCheckWeaponAttackFighterAttackCollide(wp_attack_coll, i, ft_attack_coll) != FALSE:
											ftMainUpdateAttackStatWeapon(wp, wp_attack_coll, i, fp, ft_attack_coll, weapon_gobj, fighter_gobj)
											if wp.hit_attack_damage != 0:
												done = true
												break
									if done:
										break
								if done:
									continue
					var l := 0
					for i in wp_attack_coll.attack_count:
						gFTMainIsDamageDetect[i] = Gmcollision.gmCollisionCheckWeaponInFighterRange(wp_attack_coll, i, fighter_gobj)
						if gFTMainIsDamageDetect[i] != FALSE:
							l += 1
					if l != 0:
						if B(fp.is_reflect) and B(wp_attack_coll.can_reflect):
							var hit := false
							for i in wp_attack_coll.attack_count:
								if gFTMainIsDamageDetect[i] == FALSE:
									continue
								elif Gmcollision.gmCollisionCheckWeaponAttackSpecialCollide(wp_attack_coll, i, fp, fp.special_coll) != FALSE:
									ftMainUpdateReflectorStatWeapon(wp, wp_attack_coll, fp, fighter_gobj)
									hit = true
									break
							if hit:
								continue
						if B(fp.is_absorb) and B(wp_attack_coll.can_absorb):
							var hit2 := false
							for i in wp_attack_coll.attack_count:
								if gFTMainIsDamageDetect[i] == FALSE:
									continue
								elif Gmcollision.gmCollisionCheckWeaponAttackSpecialCollide(wp_attack_coll, i, fp, fp.special_coll) != FALSE:
									ftMainUpdateAbsorbStatWeapon(wp, wp_attack_coll, fp, fighter_gobj)
									hit2 = true
									break
							if hit2:
								continue
						if B(fp.is_shield) and B(wp_attack_coll.can_shield):
							var hit3 := false
							for i in wp_attack_coll.attack_count:
								if gFTMainIsDamageDetect[i] == FALSE:
									continue
								var r = Gmcollision.gmCollisionCheckWeaponAttackShieldCollide(wp_attack_coll, i, fighter_gobj, fp.joints[nFTPartsJointYRotN])
								if B(r.ret):
									ftMainUpdateShieldStatWeapon(wp, wp_attack_coll, i, fp, weapon_gobj, fighter_gobj, r.p_angle, r.vec)
									hit3 = true
									break
							if hit3:
								continue
						if (fp.special_hitstatus != nGMHitStatusIntangible) and (fp.star_hitstatus != nGMHitStatusIntangible) and (fp.hitstatus != nGMHitStatusIntangible):
							var hit4 := false
							for i in wp_attack_coll.attack_count:
								if gFTMainIsDamageDetect[i] == FALSE:
									continue
								for jj in fp.damage_colls.size():
									var damage_coll: FTDamageColl = fp.damage_colls[jj]
									if damage_coll.hitstatus == nGMHitStatusNone:
										break
									if damage_coll.hitstatus != nGMHitStatusIntangible:
										if Gmcollision.gmCollisionCheckWeaponAttackFighterDamageCollide(wp_attack_coll, i, damage_coll) != FALSE:
											ftMainUpdateDamageStatWeapon(wp, wp_attack_coll, i, fp, damage_coll, weapon_gobj, fighter_gobj)
											hit4 = true
											break
								if hit4:
									break

## 0x800E55DC
static func ftMainSearchHitItem(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var bs = G.gSCManagerBattleState
	for item_gobj in Sim.get_link(nGCCommonLinkIDItem):
		if not item_gobj.is_alive:
			continue
		var ip := itGetStruct(item_gobj)
		var it_attack_coll: ITAttackColl = ip.attack_coll
		if (fighter_gobj != ip.owner_gobj) and ((bs.is_team_battle != TRUE) or (bs.is_team_attack != FALSE) or (fp.team != ip.team)) and (it_attack_coll.attack_state != nGMAttackStateOff):
			if it_attack_coll.interact_mask & GMHITCOLLISION_FLAG_FIGHTER:
				var item_flags := _flags_for(it_attack_coll.attack_records, fighter_gobj)
				if not B(item_flags.is_interact_hurt) and not B(item_flags.is_interact_shield) and not B(item_flags.is_interact_reflect) and (item_flags.group_id == 7):
					if B(it_attack_coll.can_setoff) and not B(fp.is_catchstatus) and ((fp.throw_gobj == null) or ((fp.throw_gobj != ip.owner_gobj) and ((bs.is_team_battle != TRUE) or (bs.is_team_attack != FALSE) or (fp.throw_team != ip.team)))):
						if not B(fp.is_reflect) or not B(it_attack_coll.can_reflect):
							var k := 0
							for i in fp.attack_colls.size():
								var ft_attack_coll: FTAttackColl = fp.attack_colls[i]
								var set_true := false
								if (ft_attack_coll.attack_state != nGMAttackStateOff) and (((ip.ga == nMPKineticsAir) and B(ft_attack_coll.is_hit_air)) or ((ip.ga == nMPKineticsGround) and B(ft_attack_coll.is_hit_ground))):
									var fighter_flags := _flags_for(ft_attack_coll.attack_records, item_gobj)
									if fighter_flags.group_id == 7:
										set_true = true
								if set_true:
									gFTMainIsAttackDetect[i] = TRUE
									k += 1
								else:
									gFTMainIsAttackDetect[i] = FALSE
							if k != 0:
								var done := false
								for i in it_attack_coll.attack_count:
									for jj in fp.attack_colls.size():
										var ft_attack_coll: FTAttackColl = fp.attack_colls[jj]
										if gFTMainIsAttackDetect[jj] == FALSE:
											continue
										elif Gmcollision.gmCollisionCheckItemAttackFighterAttackCollide(it_attack_coll, i, ft_attack_coll) != FALSE:
											ftMainUpdateAttackStatItem(ip, it_attack_coll, i, fp, ft_attack_coll, item_gobj, fighter_gobj)
											if ip.hit_attack_damage != 0:
												done = true
												break
									if done:
										break
								if done:
									continue
					var l := 0
					for i in it_attack_coll.attack_count:
						gFTMainIsDamageDetect[i] = Gmcollision.gmCollisionCheckItemInFighterRange(it_attack_coll, i, fighter_gobj)
						if gFTMainIsDamageDetect[i] != FALSE:
							l += 1
					if l != 0:
						if B(fp.is_reflect) and B(it_attack_coll.can_reflect):
							var hit := false
							for i in it_attack_coll.attack_count:
								if gFTMainIsDamageDetect[i] == FALSE:
									continue
								elif Gmcollision.gmCollisionCheckItemAttackSpecialCollide(it_attack_coll, i, fp, fp.special_coll) != FALSE:
									ftMainUpdateReflectorStatItem(ip, it_attack_coll, fp, fighter_gobj)
									hit = true
									break
							if hit:
								continue
						if B(fp.is_shield) and B(it_attack_coll.can_shield):
							var hit3 := false
							for i in it_attack_coll.attack_count:
								if gFTMainIsDamageDetect[i] == FALSE:
									continue
								var r = Gmcollision.gmCollisionCheckItemAttackShieldCollide(it_attack_coll, i, fighter_gobj, fp.joints[nFTPartsJointYRotN])
								if B(r.ret):
									ftMainUpdateShieldStatItem(ip, it_attack_coll, i, fp, item_gobj, fighter_gobj, r.p_angle, r.vec)
									hit3 = true
									break
							if hit3:
								continue
						if (fp.special_hitstatus != nGMHitStatusIntangible) and (fp.star_hitstatus != nGMHitStatusIntangible) and (fp.hitstatus != nGMHitStatusIntangible):
							var hit4 := false
							for i in it_attack_coll.attack_count:
								if gFTMainIsDamageDetect[i] == FALSE:
									continue
								for jj in fp.damage_colls.size():
									var damage_coll: FTDamageColl = fp.damage_colls[jj]
									if damage_coll.hitstatus == nGMHitStatusNone:
										break
									if damage_coll.hitstatus != nGMHitStatusIntangible:
										if Gmcollision.gmCollisionCheckItemAttackFighterDamageCollide(it_attack_coll, i, damage_coll) != FALSE:
											ftMainUpdateDamageStatItem(ip, it_attack_coll, i, fp, damage_coll, item_gobj, fighter_gobj)
											hit4 = true
											break
								if hit4:
									break

## 0x800E5C30 - returns {"ret", "p_gr_attack_coll"}
static func ftMainGetGroundHitObstacle(fp: Fighter) -> Dictionary:
	if (fp.damagefloor_wait == 0) and (fp.ga == nMPKineticsGround) and (fp.coll_data.floor_line_id != -1) and (fp.coll_data.floor_line_id != -2):
		match fp.coll_data.floor_flags & MAP_VERTEX_MAT_MASK:
			nMPMaterialFireWeakS1:
				return {"ret": TRUE, "p_gr_attack_coll": dFTMainGroundHitCollisionAttributes[0]}
			nMPMaterialFireStrongS1:
				return {"ret": TRUE, "p_gr_attack_coll": dFTMainGroundHitCollisionAttributes[1]}
			nMPMaterialFireWeakHi1:
				return {"ret": TRUE, "p_gr_attack_coll": dFTMainGroundHitCollisionAttributes[2]}
			nMPMaterialSpikes:
				return {"ret": TRUE, "p_gr_attack_coll": dFTMainGroundHitCollisionAttributes[3]}
			nMPMaterialFireWeakHi2:
				return {"ret": TRUE, "p_gr_attack_coll": dFTMainGroundHitCollisionAttributes[4]}
			nMPMaterialFireWeakHi3:
				return {"ret": TRUE, "p_gr_attack_coll": dFTMainGroundHitCollisionAttributes[5]}
	return {"ret": FALSE, "p_gr_attack_coll": null}

## 0x800E5D20 - hazard proc_update(gobj, fighter_gobj) returns {"ret", "gr_attack_coll", "kind"}
static func ftMainSearchGroundHit(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	if fp.hitlag_tics == 0:
		if fp.acid_wait != 0:
			fp.acid_wait -= 1
		if fp.damagefloor_wait != 0:
			fp.damagefloor_wait -= 1
	if Ftparam.ftParamGetBestHitStatusAll(fighter_gobj) == nGMHitStatusNormal:
		for i in sFTMainGroundHazardsNum:
			var ge = sFTMainGroundHazards[i]
			if ge.gobj != null:
				var r = ge.proc_update.call(ge.gobj, fighter_gobj)
				if r != null and B(r.ret):
					ftMainUpdateDamageStatGround(ge.gobj, fighter_gobj, fp, r.gr_attack_coll, r.kind)
		var o := ftMainGetGroundHitObstacle(fp)
		if B(o.ret):
			ftMainUpdateDamageStatGround(null, fighter_gobj, fp, o.p_gr_attack_coll, o.p_gr_attack_coll.kind)

## 0x800E5E58
static func ftMainSearchFighterCatch(this_gobj) -> void:
	var this_fp := ftGetStruct(this_gobj)
	this_fp.search_gobj = null
	this_fp.search_gobj_dist = F32_MAX
	var bs = G.gSCManagerBattleState
	for other_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		if other_gobj == this_gobj:
			continue
		var other_fp := ftGetStruct(other_gobj)
		if B(other_fp.is_ghost):
			continue
		if other_fp.fkind == nFTKindBoss:
			continue
		if (bs.is_team_battle == TRUE) and (bs.is_team_attack == FALSE) and (this_fp.team == other_fp.team):
			continue
		if other_fp.capture_immune_mask & this_fp.catch_mask:
			continue
		if (other_fp.special_hitstatus != nGMHitStatusNormal) or (other_fp.star_hitstatus != nGMHitStatusNormal) or (other_fp.hitstatus != nGMHitStatusNormal):
			continue
		var found := false
		for i in this_fp.attack_colls.size():
			var attack_coll: FTAttackColl = this_fp.attack_colls[i]
			if attack_coll.attack_state == nGMAttackStateOff:
				continue
			if ((other_fp.ga == nMPKineticsAir) and not B(attack_coll.is_hit_air)) or ((other_fp.ga == nMPKineticsGround) and not B(attack_coll.is_hit_ground)):
				continue
			var catch_mask := _flags_for(attack_coll.attack_records, other_gobj)
			if B(catch_mask.is_interact_hurt) or B(catch_mask.is_interact_shield) or (catch_mask.group_id != 7):
				continue
			for jj in other_fp.damage_colls.size():
				var damage_coll: FTDamageColl = other_fp.damage_colls[jj]
				if damage_coll.hitstatus == nGMHitStatusNone:
					break
				if (damage_coll.hitstatus != nGMHitStatusIntangible) and (damage_coll.hitstatus != nGMHitStatusInvincible):
					if B(damage_coll.is_grabbable) and (Gmcollision.gmCollisionCheckFighterAttackDamageCollide(attack_coll, damage_coll) != FALSE):
						ftMainUpdateCatchStatFighter(this_fp, attack_coll, other_fp, this_gobj, other_gobj)
						found = true
						break
			if found:
				break

## 0x800E6100
static func ftMainProcSearchCatch(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	ftMainSearchHitHazard(fighter_gobj)
	if B(fp.is_catchstatus):
		ftMainSearchFighterCatch(fighter_gobj)
		if fp.search_gobj != null:
			fp.proc_catch.call(fighter_gobj)
			fp.proc_capture.call(fp.search_gobj, fighter_gobj)

## 0x800E6178
static func ftMainProcSearchHitAll(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	if not B(fp.is_ghost):
		sFTMainHitLogID = 0
		ftMainSearchHitFighter(fighter_gobj)
		ftMainSearchHitItem(fighter_gobj)
		ftMainSearchHitWeapon(fighter_gobj)
		ftMainSearchGroundHit(fighter_gobj)
		if sFTMainHitLogID != 0:
			ftMainProcessHitCollisionStatsMain(fighter_gobj)

## 0x800E61EC
static func ftMainProcParams(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var damage := 0
	var is_shieldbreak := FALSE
	var status_id: int = fp.status_id
	var hitlag_tics: int = fp.hitlag_tics
	var is_knockback_paused := FALSE
	if fp.unk_ft_0x7AC != 0:
		fp.unk_ft_0x3C += fp.unk_ft_0x7AC
	if not B(fp.is_shield) and (fp.shield_health < 55):
		fp.shield_heal_wait -= 1
		if fp.shield_heal_wait == 0.0:
			fp.shield_health += 1
			fp.shield_heal_wait = 10.0
	fp.shield_health -= fp.shield_damage_total
	if fp.shield_health <= 0:
		fp.shield_health = 30
		is_shieldbreak = TRUE
	if fp.damage_knockback != 0.0:
		if (fp.status_id == nFTCommonStatusSquat) or (fp.status_id == nFTCommonStatusSquatWait):
			fp.damage_knockback *= (2.0 / 3.0)
		if fp.status_id == nFTCommonStatusTwister:
			fp.damage_kind = nFTDamageKindColAnim
		var knockback_resist: float
		if fp.knockback_resist_status < fp.knockback_resist_passive:
			knockback_resist = fp.knockback_resist_passive
		else:
			knockback_resist = fp.knockback_resist_status
		fp.damage_knockback -= knockback_resist
		if fp.damage_knockback <= 0:
			fp.damage_knockback = 0
		Ftparam.ftParamUpdateDamage(fp, fp.damage_queue)
		if fp.proc_trap.is_valid():
			fp.proc_trap.call(fighter_gobj)
		if fp.fkind != nFTKindBoss:
			match fp.damage_kind:
				nFTDamageKindNone:
					pass
				nFTDamageKindStatus:
					Ftparam.ftParamStopVoiceRunProcDamage(fighter_gobj)
					Ftcommondamage.ftCommonDamageGotoDamageStatus(fighter_gobj)
				nFTDamageKindColAnim:
					Ftcommondamage.ftCommonDamageSetDamageColAnim(fighter_gobj)
				nFTDamageKindCatch:
					Ftparam.ftParamStopVoiceRunProcDamage(fighter_gobj)
					Ftcommondamage.ftCommonDamageUpdateCatchResist(fighter_gobj)
				_:
					Ftcommondamage.ftCommonDamageUpdateMain(fighter_gobj)
		else:
			Ftcommondamage.ftCommonDamageSetDamageColAnim(fighter_gobj)
			Ftbosscommon.ftBossCommonUpdateDamageStats(fighter_gobj)
		damage = fp.damage_lag
		is_knockback_paused = TRUE
		Ftparam.ftParamSetDamageShuffle(fp, TRUE if (fp.damage_element == nGMHitElementElectric) else FALSE, damage, status_id, fp.hitlag_mul)
		if int((fp.damage_queue * 0.75) + 4.0) > 0:
			Ftparam.ftParamMakeRumble(fp, 0, int((fp.damage_queue * 0.75) + 4.0))
	elif fp.shield_damage != 0:
		if is_shieldbreak != FALSE:
			Ftcommonshieldbreakfly.ftCommonShieldBreakFlyCommonSetStatus(fighter_gobj)
		else:
			Ftcommonguard2.ftCommonGuardSetOffSetStatus(fighter_gobj)
		damage = fp.shield_damage
	elif fp.attack_shield_push != 0:
		if fp.proc_shield.is_valid():
			fp.proc_shield.call(fighter_gobj)
		if (fp.attack_rebound != 0) and (fp.catch_gobj == null) and (fp.capture_gobj == null):
			Ftparam.ftParamStopVoiceRunProcDamage(fighter_gobj)
			Ftcommonrebound.ftCommonReboundWaitSetStatus(fighter_gobj)
		damage = fp.attack_shield_push
	elif fp.attack_damage != 0:
		if fp.proc_hit.is_valid():
			fp.proc_hit.call(fighter_gobj)
		damage = fp.attack_damage
		if fp.stat_flags.attack_id == nFTStatusAttackIDBatSwing4:
			Ftparam.ftParamMakeRumble(fp, 10, 0)
		elif int((fp.attack_damage * 0.5) + 2.0) > 0:
			Ftparam.ftParamMakeRumble(fp, 5, int((fp.attack_damage * 0.5) + 2.0))
	elif fp.reflect_damage != 0:
		Ftcommonshieldbreakfly.ftCommonShieldBreakFlyReflectorSetStatus(fighter_gobj)
	elif fp.reflect_lr != 0:
		match fp.special_coll.kind:
			nFTSpecialCollKindFoxReflector:
				Ftfoxspeciallw.ftFoxSpecialLwHitSetStatus(fighter_gobj)
			nFTSpecialCollKindNessReflector:
				Snd.func_800269C0_275C0(nSYAudioFGMBatHit)
	elif fp.absorb_lr != 0:
		Ftnessspeciallw.ftNessSpecialLwProcAbsorb(fighter_gobj)
	if damage != 0:
		fp.hitlag_tics = Ftparam.ftParamGetHitLag(damage, status_id, fp.hitlag_mul)
		if (fp.hitlag_tics != 0) and (is_knockback_paused != FALSE):
			fp.is_knockback_paused = TRUE
		fp.input.pl.button_tap = 0
		fp.input.pl.button_release = 0
		if fp.proc_lagstart.is_valid():
			fp.proc_lagstart.call(fighter_gobj)
	fp.unk_ft_0x7AC = 0
	fp.attack_damage = 0
	fp.attack_shield_push = 0
	fp.shield_damage = 0
	fp.shield_damage_total = 0
	fp.damage_lag = 0
	fp.damage_queue = 0
	fp.damage_kind = nFTDamageKindDefault
	fp.reflect_lr = 0
	fp.reflect_damage = 0
	fp.absorb_lr = 0
	fp.unk_ft_0x7A0 = 0
	fp.attack_rebound = 0
	fp.damage_knockback = 0
	fp.hitlag_mul = 1.0
	# After-image (sword trail) bookkeeping is visual only: fp.afterimage is updated by the renderer.

# ---------------------------------------------------------------------------
# Hidden parts (joints inserted / removed per animation: TransN, XRotN, YRotN, extras)
# ---------------------------------------------------------------------------
static func _commonpart(fp: Fighter, detail: int) -> Array:
	return fp.data.commonparts[detail - nFTPartsDetailStart]

## 0x800E69C4
static func ftMainUpdateHiddenPartID(fp: Fighter, hiddenpart_id: int) -> void:
	var attr = fp.attr
	var hiddenpart = attr.hiddenparts[hiddenpart_id]
	var commonpart = null
	if hiddenpart.root_joint_id >= nFTPartsJointCommonStart:
		if fp.detail_curr == nFTPartsDetailHigh:
			commonpart = _commonpart(fp, nFTPartsDetailHigh)
		elif _commonpart(fp, nFTPartsDetailLow)[hiddenpart.root_joint_id - nFTPartsJointCommonStart].dl != null:
			commonpart = _commonpart(fp, nFTPartsDetailLow)
		else:
			commonpart = _commonpart(fp, nFTPartsDetailHigh)
	var dl = commonpart[hiddenpart.root_joint_id - nFTPartsJointCommonStart].dl if commonpart != null else null
	var root_joint: DObj = Objman.gcAddDObjForGObj(fp.fighter_gobj, dl)
	root_joint.sib_prev.sib_next = null
	root_joint.sib_prev = null
	if commonpart != null:
		var ms = fp.modelpart_status[hiddenpart.root_joint_id - nFTPartsJointCommonStart]
		ms.modelpart_id_base = 0 if dl != null else -1
		ms.modelpart_id_curr = ms.modelpart_id_base
	var parent_joint: DObj = fp.joints[hiddenpart.parent_joint_id]
	match hiddenpart.joint_kind:
		0:
			if parent_joint.child != null:
				var sibling_joint: DObj = parent_joint.child.sib_next
				var child_joint: DObj = parent_joint.child
				while sibling_joint != null:
					child_joint = sibling_joint
					sibling_joint = sibling_joint.sib_next
				child_joint.sib_next = root_joint
				root_joint.sib_prev = child_joint
			else:
				parent_joint.child = root_joint
			root_joint.parent = parent_joint
		1:
			if parent_joint.child != null:
				var child_joint: DObj = parent_joint.child
				child_joint.sib_prev = root_joint
				root_joint.sib_next = child_joint
			parent_joint.child = root_joint
			root_joint.parent = parent_joint
		2:
			var child_joint: DObj = parent_joint.child.sib_next
			child_joint.sib_prev = root_joint
			root_joint.sib_next = child_joint
			child_joint = parent_joint.child
			child_joint.sib_next = root_joint
			root_joint.parent = parent_joint
			root_joint.sib_prev = child_joint
		3:
			if parent_joint.child != null:
				var child_joint: DObj = parent_joint.child
				root_joint.child = child_joint
				while child_joint != null:
					child_joint.parent = root_joint
					child_joint = child_joint.sib_next
			parent_joint.child = root_joint
			root_joint.parent = parent_joint
	fp.joints[hiddenpart.root_joint_id] = root_joint
	var parts := FtParts.new()
	root_joint.user_data = parts
	parts.flags = 0
	parts.joint_id = hiddenpart.root_joint_id
	root_joint.debug_name = "hidden%d" % hiddenpart.root_joint_id

## 0x800E6CE0
static func ftMainAddHiddenPartID(fp: Fighter, hiddenpart_id: int) -> void:
	var hiddenpart = fp.attr.hiddenparts[hiddenpart_id]
	var root_joint: DObj = fp.joints[hiddenpart.root_joint_id]
	if hiddenpart.root_joint_id == nFTPartsJointTransN:
		var parent_joint: DObj = root_joint.parent
		var child_joint: DObj = root_joint.child
		var new_parent_joint: DObj = parent_joint
		var new_child_joint: DObj = child_joint
		if new_child_joint != null:
			var sibling_joint: DObj = root_joint.sib_prev
			new_child_joint = child_joint
			child_joint = sibling_joint
			if sibling_joint == null:
				new_parent_joint.child = new_child_joint
			else:
				child_joint.sib_next = new_child_joint
				new_child_joint.sib_prev = root_joint.sib_prev
			child_joint = new_child_joint.sib_next
			new_child_joint.parent = new_parent_joint
			while child_joint != null:
				new_child_joint = child_joint
				child_joint.parent = new_parent_joint
				child_joint = child_joint.sib_next
			new_child_joint.sib_next = root_joint.sib_next
			new_parent_joint = root_joint.sib_next
			if new_parent_joint != null:
				new_parent_joint.sib_prev = new_child_joint
		else:
			var sibling_joint2: DObj = root_joint.sib_prev
			if sibling_joint2 == null:
				new_parent_joint.child = root_joint.sib_next
			else:
				sibling_joint2.sib_next = root_joint.sib_next
			new_parent_joint = root_joint.sib_next
			if new_parent_joint != null:
				new_parent_joint.sib_prev = root_joint.sib_prev
		root_joint.child = null
		root_joint.sib_prev = null
		root_joint.sib_next = null
		root_joint.parent = null
		new_parent_joint = fp.joints[hiddenpart.parent_joint_id]
		if new_parent_joint.child != null:
			new_child_joint = new_parent_joint.child
			root_joint.child = new_parent_joint.child
			while new_child_joint != null:
				new_child_joint.parent = root_joint
				new_child_joint = new_child_joint.sib_next
		new_parent_joint.child = root_joint
		root_joint.parent = new_parent_joint

## 0x800E6E00
static func ftMainEjectHiddenPartID(fp: Fighter, hiddenpart_id: int) -> void:
	var hiddenpart = fp.attr.hiddenparts[hiddenpart_id]
	var root_joint: DObj = fp.joints[hiddenpart.root_joint_id]
	var child_joint: DObj = root_joint.child
	var parent_joint: DObj = root_joint.parent
	if child_joint != null:
		var sibling_joint: DObj = child_joint
		if root_joint.sib_prev == null:
			parent_joint.child = child_joint
		else:
			root_joint.sib_prev.sib_next = sibling_joint
			sibling_joint.sib_prev = root_joint.sib_prev
		var new_sibling_joint: DObj = sibling_joint.sib_next
		sibling_joint.parent = parent_joint
		while new_sibling_joint != null:
			sibling_joint = new_sibling_joint
			new_sibling_joint.parent = parent_joint
			new_sibling_joint = new_sibling_joint.sib_next
		sibling_joint.sib_next = root_joint.sib_next
		new_sibling_joint = root_joint.sib_next
		if new_sibling_joint != null:
			new_sibling_joint.sib_prev = sibling_joint
	else:
		if root_joint.sib_prev == null:
			parent_joint.child = root_joint.sib_next
		else:
			root_joint.sib_prev.sib_next = root_joint.sib_next
		if root_joint.sib_next != null:
			root_joint.sib_next.sib_prev = root_joint.sib_prev
	fp.joints[hiddenpart.root_joint_id] = null
	root_joint.sib_next = null
	root_joint.sib_prev = null
	root_joint.child = null
	Objman.gcEjectDObj(root_joint)

# ---------------------------------------------------------------------------
# Status change
# ---------------------------------------------------------------------------
const _ANIM_DESC_HIDDEN_MASK := ~(FTANIM_FLAG_SUBMOTION_SCRIPT | FTANIM_FLAG_ANIMJOINT | FTANIM_FLAG_TRANSLATE_SCALES | FTANIM_FLAG_SHIELDPOSE | FTANIM_FLAG_ANIMLOCKS) & 0xFFFFFFFF

## 0x800E6F24
static func ftMainSetStatus(fighter_gobj, status_id: int, frame_begin: float, anim_speed: float, flags: int) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr
	FtStatusDescs.build()
	var status_flags_half: int = fp.stat_flags.halfword
	if B(fp.is_events_forward):
		ftMainUpdateMotionEventsForwardEffect(fighter_gobj)
		if fp.proc_accessory.is_valid():
			fp.proc_accessory.call(fighter_gobj)
	fp.status_id = status_id
	if fp.detail_curr != fp.detail_base:
		Ftparam.ftParamSetModelPartDetailAll(fighter_gobj, fp.detail_base)
		fp.detail_curr = fp.detail_base
	if not (flags & FTSTATUS_PRESERVE_HIT) and B(fp.is_attack_active):
		Ftparam.ftParamClearAttackCollAll(fighter_gobj)
	if not (flags & FTSTATUS_PRESERVE_THROWPOINTER):
		fp.throw_gobj = null
	if not (flags & FTSTATUS_PRESERVE_HITSTATUS):
		if B(fp.is_hitstatus_nodamage):
			Ftparam.ftParamSetHitStatusPartAll(fighter_gobj, nGMHitStatusNormal)
		if fp.hitstatus != nGMHitStatusNormal:
			Ftparam.ftParamSetHitStatusAll(fighter_gobj, nGMHitStatusNormal)
	if B(fp.is_damage_coll_modify):
		Ftparam.ftParamResetFighterDamageCollsAll(fighter_gobj)
	if not (flags & FTSTATUS_PRESERVE_MODELPART) and B(fp.is_modelpart_modify):
		Ftparam.ftParamResetModelPartAll(fighter_gobj)
	if not (flags & FTSTATUS_PRESERVE_TEXTUREPART) and B(fp.is_texturepart_modify):
		Ftparam.ftParamResetTexturePartAll(fighter_gobj)
	if not (flags & FTSTATUS_PRESERVE_COLANIM) and Ftparam.ftParamIsColAnimUnlocked(fp.colanim.colanim_id):
		Ftparam.ftParamResetStatUpdateColAnim(fighter_gobj)
	if not (flags & FTSTATUS_PRESERVE_EFFECT) and B(fp.is_effect_attach):
		Ftparam.ftParamProcStopEffect(fighter_gobj)
	fp.is_reflect = FALSE
	fp.is_absorb = FALSE
	fp.is_shield = FALSE
	if not (flags & FTSTATUS_PRESERVE_FASTFALL):
		fp.is_fastfall = FALSE
	fp.is_invisible = FALSE
	fp.is_shadow_hide = FALSE
	fp.is_rebirth = FALSE
	fp.is_playertag_hide = FALSE
	fp.is_effect_skip = FALSE
	if fp.pkind != nFTPlayerKindDemo:
		Gmrumble.gmRumbleStopRumbleID(fp.player, 2)
		Gmrumble.gmRumbleStopRumbleID(fp.player, 3)
		if not (flags & FTSTATUS_PRESERVE_RUMBLE):
			Gmrumble.gmRumbleStopRumbleID(fp.player, 7)
		fp.joints[nFTPartsJointTopN].rotate.y = fp.lr * F_CLC_DTOR32(90.0)
		DObjGetStruct(fighter_gobj).rotate.z = 0.0
		fp.joints[nFTPartsJointTopN].rotate.x = DObjGetStruct(fighter_gobj).rotate.z
		fp.physics.vel_air.z = 0.0
		fp.physics.vel_ground.z = 0.0
	fp.is_jostle_ignore = FALSE
	fp.is_hitstun = FALSE
	fp.damage_mul = 1.0
	if (fp.ga == nMPKineticsGround) and not (flags & FTSTATUS_PRESERVE_DAMAGEPLAYER):
		fp.damage_player = -1
	if not (flags & FTSTATUS_PRESERVE_SLOPECONTOUR):
		fp.slope_contour = 0
	fp.coll_data.ignore_line_id = -1
	fp.is_item_show = TRUE
	fp.is_cliff_hold = FALSE
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_NONE)
	fp.is_ghost = FALSE
	fp.is_damage_resist = FALSE
	fp.is_menu_ignore = FALSE
	if fp.camera_mode != nFTCameraModeEntry:
		fp.camera_mode = nFTCameraModeDefault
	fp.camera_zoom_range = 1.0
	if not (flags & FTSTATUS_PRESERVE_PLAYERTAG):
		fp.playertag_wait = 0
	fp.is_special_interrupt = FALSE
	fp.is_catchstatus = FALSE
	fp.is_ignore_dead = FALSE
	if not (flags & FTSTATUS_PRESERVE_SHUFFLETIME):
		fp.shuffle_tics = 0
	if not (flags & FTSTATUS_PRESERVE_LOOPSFX):
		Ftparam.ftParamStopLoopSFX(fp)
	fp.knockback_resist_status = 0.0
	fp.damage_knockback_stack = 0.0
	if not (flags & FTSTATUS_PRESERVE_AFTERIMAGE):
		fp.afterimage.drawstatus = -1
	if (status_id != nFTCommonStatusWait) and (status_id != nFTCommonStatusWalkSlow) and (status_id != nFTCommonStatusWalkMiddle) and (status_id != nFTCommonStatusWalkFast):
		fp.attack1_followup_frames = 0.0
	if (fp.pkind != nFTPlayerKindDemo) and (fp.dl_link != FTDISPLAY_DLLINK_DEFAULT):
		Ftparam.ftParamMoveDLLink(fighter_gobj, 9)
	fp.status_total_tics = 0

	var sid: int = status_id
	if sid >= FTSTAT_CHARDATA_START:
		sid -= FTSTAT_CHARDATA_START
	var status_struct = null
	var status_struct_id := 0
	if sid >= FTSTAT_OPENING2_START:
		# Opening (1P intro / character select demo) statuses are not used in VS battles.
		push_warning("opening status %d not supported" % status_id)
		return
	elif sid >= nFTCommonStatusSpecialStart:
		status_struct = FtStatusDescs.special_table(fp.fkind)
		status_struct_id = sid - nFTCommonStatusSpecialStart
	elif sid >= nFTCommonStatusActionStart:
		status_struct = FtStatusDescs.dFTCommonActionStatusDescs
		status_struct_id = sid - nFTCommonStatusActionStart
	else:
		status_struct = FtStatusDescs.dFTCommonNullStatusDescs
		status_struct_id = sid
	var status_desc: Dictionary = status_struct[status_struct_id]
	if fp.pkind != nFTPlayerKindDemo:
		if (status_desc.motion_attack_id == nFTMotionAttackIDNone) or (status_desc.motion_attack_id != fp.motion_attack_id):
			Ftparam.ftParamSetMotionID(fp, status_desc.motion_attack_id)
		var attack_flags := GMStatFlags.from_halfword(status_desc.sflags)
		if (attack_flags.attack_id == nFTStatusAttackIDNone) or (attack_flags.attack_id != fp.stat_flags.attack_id):
			Ftparam.ftParamSetStatUpdate(fp, status_desc.sflags)
	if fp.proc_status.is_valid():
		var ps: Callable = fp.proc_status
		ps.call(fighter_gobj)
		fp.proc_status = Callable()
	Ftparam.ftParamUpdate1PGameAttackStats(fp, status_flags_half)

	var motion_id: int = status_desc.motion_id
	fp.motion_id = motion_id
	var script_array: Array = fp.data.mainmotion
	if (motion_id != -1) and (motion_id != -2):
		var motion_desc: Dictionary = script_array[motion_id]
		var anim_desc_word: int = motion_desc.anim_desc
		if anim_desc_word & FTANIM_FLAG_SHIELDPOSE:
			fp.figatree = motion_desc.shieldpose_anim
		elif motion_desc.anim_file_id != 0:
			fp.figatree = motion_desc.anim
		else:
			fp.figatree = null
		if fp.figatree != null:
			var anim_desc_bak: int = fp.anim_desc & _ANIM_DESC_HIDDEN_MASK
			fp.anim_desc = anim_desc_word
			var anim_desc_update: int = fp.anim_desc & _ANIM_DESC_HIDDEN_MASK
			var i := 0
			while (anim_desc_bak != 0) or (anim_desc_update != 0):
				if not (anim_desc_bak & (1 << 31)):
					if anim_desc_update & (1 << 31):
						ftMainUpdateHiddenPartID(fp, i)
				elif anim_desc_update & (1 << 31):
					ftMainAddHiddenPartID(fp, i)
				else:
					ftMainEjectHiddenPartID(fp, i)
				i += 1
				anim_desc_update = (anim_desc_update << 1) & 0xFFFFFFFF
				anim_desc_bak = (anim_desc_bak << 1) & 0xFFFFFFFF
			var dobjdesc: Array = _commonpart(fp, fp.detail_curr)
			var ji := nFTPartsJointCommonStart
			for d in dobjdesc:
				var joint: DObj = fp.joints[ji]
				if joint != null:
					joint.translate = d.translate
					joint.rotate = d.rotate
					joint.scale = d.scale
					joint.flags = DOBJ_FLAG_NONE
				ji += 1
			if fp.anim_flag_use_transn_joint():
				var joint: DObj = fp.joints[nFTPartsJointTransN]
				joint.translate = Vector3.ZERO
				joint.rotate.z = 0.0
				joint.flags = DOBJ_FLAG_NONE
			if fp.anim_flag_use_xrotn_joint():
				var joint: DObj = fp.joints[nFTPartsJointXRotN]
				joint.translate = Vector3.ZERO
				joint.rotate = Vector3.ZERO
				joint.scale = Vector3.ONE
				joint.flags = DOBJ_FLAG_NONE
			if fp.anim_flag_use_yrotn_joint():
				var joint: DObj = fp.joints[nFTPartsJointYRotN]
				joint.translate = Vector3.ZERO
				joint.rotate = Vector3.ZERO
				joint.scale = Vector3.ONE
				joint.flags = DOBJ_FLAG_NONE
			ObjAnim.lbCommonAddFighterPartsFigatree(fp.joints[nFTPartsJointTopN].child, fp.figatree, frame_begin)
			if anim_speed != DObjGetStruct(fighter_gobj).anim_speed:
				ObjAnim.gcSetAnimSpeed(fighter_gobj, anim_speed)
			if fp.anim_flag_use_transn_joint():
				var joint: DObj = fp.joints[nFTPartsJointTransN]
				var transn_parent: DObj = joint.parent
				var transn_child: DObj = joint.child
				transn_parent.child = transn_child
				transn_child.parent = transn_parent
				transn_child.sib_next = joint
				joint.sib_prev = transn_child
				joint.parent = transn_child.parent
				joint.child = null
			if B(fp.is_use_animlocks):
				if not fp.anim_flag_use_animlocks():
					Ftparam.ftParamSetAnimLocks(fp)
			elif fp.anim_flag_use_animlocks():
				Ftparam.ftParamClearAnimLocks(fp)
			fp.is_use_animlocks = TRUE if fp.anim_flag_use_animlocks() else FALSE
			if attr.translate_scales != null:
				if fp.anim_flag_is_have_translate_scale():
					fp.is_have_translate_scale = FALSE
				else:
					fp.is_have_translate_scale = TRUE
		var event_script_ptr: MotionPtr = null
		if fp.anim_flag_use_submotion_script():
			event_script_ptr = motion_desc.get("subscript", null)
		else:
			event_script_ptr = motion_desc.get("script", null)
		fp.motion_scripts[0][0].p_script = event_script_ptr.dup() if event_script_ptr != null else null
		fp.motion_scripts[1][0].p_script = event_script_ptr.dup() if event_script_ptr != null else null
		var anim_frame: float = DObjGetStruct(fighter_gobj).anim_speed - frame_begin
		fp.motion_scripts[0][0].script_wait = anim_frame
		fp.motion_scripts[1][0].script_wait = anim_frame
		fp.motion_scripts[0][0].script_id = 0
		fp.motion_scripts[1][0].script_id = 0
		for k in range(1, 2):
			fp.motion_scripts[0][k].p_script = null
			fp.motion_scripts[1][k].p_script = null
		if frame_begin != 0.0:
			ftMainPlayAnimEventsForward(fighter_gobj)
		else:
			ftMainPlayAnimEventsAll(fighter_gobj)
			ftMainRunUpdateColAnim(fighter_gobj)
	else:
		for k in 2:
			fp.motion_scripts[0][k].p_script = null
			fp.motion_scripts[1][k].p_script = null
	if fp.pkind != nFTPlayerKindDemo:
		fp.proc_update = status_desc.proc_update
		fp.proc_interrupt = status_desc.proc_interrupt
		fp.proc_physics = status_desc.proc_physics
		fp.proc_map = status_desc.proc_map
		fp.proc_slope = Callable(Mpcommon, &"mpCommonUpdateFighterSlopeContour")
		fp.proc_accessory = Callable()
		fp.proc_damage = Callable()
		fp.proc_trap = Callable()
		fp.proc_hit = Callable()
		fp.proc_shield = Callable()
		fp.proc_passive = Callable()
		fp.proc_lagupdate = Callable()
		fp.proc_lagstart = Callable()
		fp.proc_lagend = Callable()
	else:
		fp.proc_update = Callable()
