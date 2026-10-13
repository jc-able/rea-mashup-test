## 1:1 port of src/ft/ftcommon/ftcommondead.c (ssb-decomp-re): blast-zone KOs (DeadDown /
## DeadLeftRight / DeadUpStar / DeadUpFall), score + stock bookkeeping and the rebirth decision.
class_name Ftcommondead
extends Port

## (1.0F / 6.0F) as an exact f32 value (DeadUpFall vs DeadUpStar chance).
const FTCOMMON_DEAD_UPFALL_CHANCE_F32 := 0.1666666716337204

# // // // // // // // // // // // //
# //         PORT HELPERS          //
# // // // // // // // // // // // //

## CObjGetStruct(gGMCameraGObj)->vec.eye. In a real battle the battle camera always exists (the
## scene creates it before any fighter can be KO'd), so C never sees NULL here. Port-only: when no
## camera GObj/CObj has been made (headless runs), the origin is used so the KO sequence (score,
## stocks, rebirth) still completes; the camera only places the falling fighter on screen.
static func _ftCommonDeadGetCameraEye() -> Vector3:
	var cobj = Gmcamera.CObjGetStruct(Gmcamera.gGMCameraGObj)

	if cobj == null:
		StubLog.hit("Ftcommondead: gGMCameraGObj has no CObj (no battle camera)")
		return Vector3.ZERO
	return cobj.vec.eye

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8013BC60
static func ftCommonDeadAddDeadSFXSoundQueue(sfx_id) -> void:
	Snd.func_800269C0_275C0(sfx_id)
	Ifcommon.ifCommonBattleEndAddSoundQueueID(sfx_id)

## 0x8013BC8C
static func ftCommonDeadUpdateRumble(this_fp) -> void:
	Ftparam.ftParamMakeRumble(this_fp, 0, 30)

	for i in range(G.gSCManagerBattleState.players.size()):
		if (i != this_fp.player) and (G.gSCManagerBattleState.players[i].pkind == nFTPlayerKindMan):
			var fighter_gobj = G.gSCManagerBattleState.players[i].fighter_gobj

			if fighter_gobj != null:
				var other_fp := ftGetStruct(fighter_gobj)

				if (not (G.gSCManagerBattleState.game_rules & SCBATTLE_GAMERULE_STOCK)) or (other_fp.stock_count != -1):
					Ftparam.ftParamMakeRumble(other_fp, 1, 15)
				else:
					continue

## 0x8013BD64
static func ftCommonDeadUpdateScore(this_fp) -> void:
	Ifcommon.ifCommonPlayerDamageStartBreakAnim(this_fp)
	Ifcommon.ifCommonPlayerStockMakeStockSnap(this_fp)

	G.gSCManagerBattleState.players[this_fp.player].falls += 1

	if G.gSCManagerBattleState.is_show_score:
		Ifcommon.ifCommonPlayerScoreMakeEffect(this_fp, -1)
	if (this_fp.damage_player != -1) and (this_fp.damage_player != GMCOMMON_PLAYERS_MAX):
		G.gSCManagerBattleState.players[this_fp.damage_player].score += 1

		G.gSCManagerBattleState.players[this_fp.damage_player].total_kos_players[this_fp.player] += 1

		if G.gSCManagerBattleState.is_show_score:
			Ifcommon.ifCommonPlayerScoreMakeEffect(ftGetStruct(G.gSCManagerBattleState.players[this_fp.damage_player].fighter_gobj), 1)
	else:
		G.gSCManagerBattleState.players[this_fp.player].total_selfdestructs += 1

	if G.gSCManagerBattleState.game_rules & SCBATTLE_GAMERULE_STOCK:
		this_fp.stock_count -= 1

		G.gSCManagerBattleState.players[this_fp.player].stock_count -= 1

		Ifcommon.ifCommonBattleUpdateScoreStocks(this_fp)
	if G.gSCManagerBattleState.game_rules & SCBATTLE_GAMERULE_1PGAME:
		this_fp.stock_count -= 1

		G.gSCManagerBattleState.players[this_fp.player].stock_count -= 1

		# sc1PGameSetPlayerDefeatStats(this_fp->player, this_fp->team_order): src/sc/sc1pmode/sc1pgame.c
		# (1P mode scene) has no GDScript module in the port map.
		StubLog.hit("sc1PGameSetPlayerDefeatStats")
	if G.gSCManagerBattleState.game_rules & SCBATTLE_GAMERULE_BONUS:
		Ifcommon.ifCommonAnnounceEndMessage()

## 0x8013BF94
static func ftCommonDeadCheckRebirth(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if G.gSCManagerBattleState.game_rules & SCBATTLE_GAMERULE_STOCK:
		if fp.stock_count == -1:
			Ftcommonsleep.ftCommonSleepSetStatus(fighter_gobj)
			return
	elif G.gSCManagerBattleState.game_rules & SCBATTLE_GAMERULE_1PGAME:
		if G.gSCManagerBattleState.players[fp.player].is_spgame_enemy != FALSE:
			# sc1PGameSpawnEnemyTeamNext(fighter_gobj): src/sc/sc1pmode/sc1pgame.c (1P mode scene)
			# has no GDScript module in the port map.
			StubLog.hit("sc1PGameSpawnEnemyTeamNext")
			return
		elif fp.stock_count == -1:
			Ftcommonsleep.ftCommonSleepSetStatus(fighter_gobj)
			return
	Ftcommonrebirth.ftCommonRebirthDownSetStatus(fighter_gobj)

## 0x8013C050
static func ftCommonDeadResetCommonVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftparam.ftParamStopVoiceRunProcDamage(fighter_gobj)
	Ftmanager.ftManagerDestroyFighterWeapons(fighter_gobj)
	Ftcommonthrown2.ftCommonThrownDecideDeadResult(fighter_gobj)

	fp.ga = nMPKineticsAir
	fp.coll_data.floor_line_id = -1

	if fp.item_gobj != null:
		Itmain.itMainDestroyItem(fp.item_gobj)

## 0x8013C0B0
static func ftCommonDeadResetSpecialStats(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.star_invincible_tics = 0
	fp.is_ghost = TRUE
	fp.is_shadow_hide = TRUE

	Ftparam.ftParamTryUpdateItemMusic()

## 0x8013C0EC
static func ftCommonDeadCommonProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.common.dead.wait -= 1

	if fp.status_vars.common.dead.wait == 0:
		ftCommonDeadCheckRebirth(fighter_gobj)

## 0x8013C120
static func ftCommonDeadInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.common.dead.wait = FTCOMMON_DEAD_WAIT

	Ftphysics.ftPhysicsStopVelAll(fighter_gobj)

	fp.is_invisible = TRUE
	fp.is_menu_ignore = TRUE
	fp.is_playertag_hide = TRUE

	Efmanager.efManagerQuakeMakeEffect(2)
	ftCommonDeadUpdateRumble(fp)
	ftCommonDeadUpdateScore(fp)

	if fp.attr.dead_fgm_ids[0] != nSYAudioFGMVoiceEnd:
		ftCommonDeadAddDeadSFXSoundQueue(fp.attr.dead_fgm_ids[0])
	if fp.attr.dead_fgm_ids[1] != nSYAudioFGMVoiceEnd:
		ftCommonDeadAddDeadSFXSoundQueue(fp.attr.dead_fgm_ids[1])

## 0x8013C1C4
static func ftCommonDeadDownSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3
	var sfx_id: int
	var gd = Mpcollision.gMPCollisionGroundData

	ftCommonDeadResetCommonVars(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusDeadDown, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftCommonDeadResetSpecialStats(fighter_gobj)
	ftCommonDeadInitStatusVars(fighter_gobj)

	pos = DObjGetStruct(fighter_gobj).translate

	if G.gSCManagerBattleState.game_type != nSCBattleGameTypeBonus:
		if pos.x > gd.camera_bound_right:
			pos.x = gd.camera_bound_right
		if pos.x < gd.camera_bound_left:
			pos.x = gd.camera_bound_left
	Efmanager.efManagerDeadExplodeMakeEffect(pos, fp.player, 0)
	Ifscreenflash.ifScreenFlashSetColAnimID(nGMColAnimScreenFlashDeadExplode, 0)

	if (
		((G.gSCManagerBattleState.gkind >= nGRKindBonus1Start) and (G.gSCManagerBattleState.gkind <= nGRKindBonus1End)) or
		((G.gSCManagerBattleState.gkind >= nGRKindBonus2Start) and (G.gSCManagerBattleState.gkind <= nGRKindBonus2End))
	):
		sfx_id = nSYAudioFGMDeadExplodeS
	else:
		sfx_id = nSYAudioFGMDeadExplodeL

	ftCommonDeadAddDeadSFXSoundQueue(sfx_id)

## 0x8013C30C
static func ftCommonDeadRightSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3
	var sfx_id: int
	var gd = Mpcollision.gMPCollisionGroundData

	ftCommonDeadResetCommonVars(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusDeadLeftRight, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftCommonDeadResetSpecialStats(fighter_gobj)
	ftCommonDeadInitStatusVars(fighter_gobj)

	pos = DObjGetStruct(fighter_gobj).translate

	if G.gSCManagerBattleState.game_type != nSCBattleGameTypeBonus:
		if pos.y > gd.camera_bound_top:
			pos.y = gd.camera_bound_top

		if pos.y < gd.camera_bound_bottom:
			pos.y = gd.camera_bound_bottom
	Efmanager.efManagerDeadExplodeMakeEffect(pos, fp.player, 1)
	Ifscreenflash.ifScreenFlashSetColAnimID(nGMColAnimScreenFlashDeadExplode, 0)

	if (
		((G.gSCManagerBattleState.gkind >= nGRKindBonus1Start) and (G.gSCManagerBattleState.gkind <= nGRKindBonus1End)) or
		((G.gSCManagerBattleState.gkind >= nGRKindBonus2Start) and (G.gSCManagerBattleState.gkind <= nGRKindBonus2End))
	):
		sfx_id = nSYAudioFGMDeadExplodeS
	else:
		sfx_id = nSYAudioFGMDeadExplodeL

	ftCommonDeadAddDeadSFXSoundQueue(sfx_id)

## 0x8013C454
static func ftCommonDeadLeftSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3
	var sfx_id: int
	var gd = Mpcollision.gMPCollisionGroundData

	ftCommonDeadResetCommonVars(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusDeadLeftRight, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftCommonDeadResetSpecialStats(fighter_gobj)
	ftCommonDeadInitStatusVars(fighter_gobj)

	pos = DObjGetStruct(fighter_gobj).translate

	if G.gSCManagerBattleState.game_type != nSCBattleGameTypeBonus:
		if pos.y > gd.camera_bound_top:
			pos.y = gd.camera_bound_top
		if pos.y < gd.camera_bound_bottom:
			pos.y = gd.camera_bound_bottom
	Efmanager.efManagerDeadExplodeMakeEffect(pos, fp.player, 3)
	Ifscreenflash.ifScreenFlashSetColAnimID(nGMColAnimScreenFlashDeadExplode, 0)

	if (
		((G.gSCManagerBattleState.gkind >= nGRKindBonus1Start) and (G.gSCManagerBattleState.gkind <= nGRKindBonus1End)) or
		((G.gSCManagerBattleState.gkind >= nGRKindBonus2Start) and (G.gSCManagerBattleState.gkind <= nGRKindBonus2End))
	):
		sfx_id = nSYAudioFGMDeadExplodeS
	else:
		sfx_id = nSYAudioFGMDeadExplodeL

	ftCommonDeadAddDeadSFXSoundQueue(sfx_id)

## 0x8013C59C
static func ftCommonDeadUpStarProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var gd = Mpcollision.gMPCollisionGroundData

	match fp.motion_vars.flags.flag1:
		1:
			# GMColKeys.a is a u8 (0..255) in C; the port stores the C value in the Color channel.
			fp.colanim.color1.a = 128 - ((fp.status_vars.common.dead.wait * 128) / FTCOMMON_DEADUP_WAIT)

		_:
			pass

	if fp.status_vars.common.dead.wait != 0:
		fp.status_vars.common.dead.wait -= 1
	if fp.status_vars.common.dead.wait == 0:
		match fp.motion_vars.flags.flag1:
			0:
				fp.physics.vel_air.y = ((gd.camera_bound_top * 0.6) - DObjGetStruct(fighter_gobj).translate.y) / FTCOMMON_DEADUP_WAIT
				fp.physics.vel_air.z = FTCOMMON_DEADUPSTAR_VEL_Z

				fp.colanim.is_use_color1 = TRUE

				fp.colanim.color1.r = gd.fog_color.r
				fp.colanim.color1.g = gd.fog_color.g
				fp.colanim.color1.b = gd.fog_color.b
				fp.colanim.color1.a = 0

				fp.status_vars.common.dead.wait = FTCOMMON_DEADUP_WAIT

				fp.motion_vars.flags.flag1 += 1

			1:
				Ftphysics.ftPhysicsStopVelAll(fighter_gobj)
				Efmanager.efManagerSparkleWhiteDeadMakeEffect(fp.joints[nFTPartsJointTopN].translate, 5.0)

				fp.is_invisible = TRUE
				fp.is_menu_ignore = TRUE

				ftCommonDeadUpdateScore(fp)
				ftCommonDeadAddDeadSFXSoundQueue(nSYAudioFGMDeadUpStar)

				fp.is_playertag_hide = TRUE
				fp.colanim.is_use_color1 = FALSE

				fp.status_vars.common.dead.wait = FTCOMMON_DEAD_WAIT

				fp.motion_vars.flags.flag1 += 1

			2:
				ftCommonDeadCheckRebirth(fighter_gobj)

			_:
				pass

## 0x8013C740
static func ftCommonDeadUpStarSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftCommonDeadResetCommonVars(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusDeadUpStar, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftphysics.ftPhysicsStopVelAll(fighter_gobj)

	fp.status_vars.common.dead.pos = DObjGetStruct(fighter_gobj).translate

	fp.camera_mode = nFTCameraModeDeadUp

	fp.status_vars.common.dead.wait = 1

	fp.motion_vars.flags.flag1 = 0

	ftCommonDeadResetSpecialStats(fighter_gobj)
	Ftparam.ftParamSetPlayerTagWait(fighter_gobj, 1)

	if fp.attr.deadup_sfx != nSYAudioFGMVoiceEnd:
		Snd.func_800269C0_275C0(fp.attr.deadup_sfx)
	Ftparam.ftParamMoveDLLink(fighter_gobj, 1)
	Ftparam.ftParamResetFighterColAnim(fighter_gobj)

## 0x8013C80C
static func ftCommonDeadUpFallProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var sfx_id: int
	var gd = Mpcollision.gMPCollisionGroundData

	match fp.motion_vars.flags.flag1:
		1:
			if DObjGetStruct(fighter_gobj).translate.y < gd.map_bound_bottom:
				fp.physics.vel_air.y = 0.0

		_:
			pass

	if fp.status_vars.common.dead.wait != 0:
		fp.status_vars.common.dead.wait -= 1
	if fp.status_vars.common.dead.wait == 0:
		match fp.motion_vars.flags.flag1:
			0:
				fp.physics.vel_air.y = (gd.camera_bound_bottom - DObjGetStruct(fighter_gobj).translate.y) / FTCOMMON_DEADUP_WAIT

				DObjGetStruct(fighter_gobj).translate.z = _ftCommonDeadGetCameraEye().z - 3000.0

				if DObjGetStruct(fighter_gobj).translate.z < 2000.0:
					DObjGetStruct(fighter_gobj).translate.z = 2000.0
				DObjGetStruct(fighter_gobj).translate.x = _ftCommonDeadGetCameraEye().x
				DObjGetStruct(fighter_gobj).translate.y = _ftCommonDeadGetCameraEye().y + 3000.0

				if DObjGetStruct(fighter_gobj).translate.y > gd.map_bound_top:
					DObjGetStruct(fighter_gobj).translate.y = gd.map_bound_top
				fp.status_vars.common.dead.wait = FTCOMMON_DEADUP_WAIT

				fp.motion_vars.flags.flag1 += 1

			1:
				Ftphysics.ftPhysicsStopVelAll(fighter_gobj)
				Ifscreenflash.ifScreenFlashSetColAnimID(nGMColAnimScreenFlashDeadExplode, 0)
				Efmanager.efManagerQuakeMakeEffect(2)
				ftCommonDeadUpdateRumble(fp)

				fp.is_playertag_hide = TRUE
				fp.is_invisible = TRUE
				fp.is_menu_ignore = TRUE

				ftCommonDeadUpdateScore(fp)

				if (
					((G.gSCManagerBattleState.gkind >= nGRKindBonus1Start) and (G.gSCManagerBattleState.gkind <= nGRKindBonus1End)) or
					((G.gSCManagerBattleState.gkind >= nGRKindBonus2Start) and (G.gSCManagerBattleState.gkind <= nGRKindBonus2End))
				):
					sfx_id = nSYAudioFGMDeadExplodeS
				else:
					sfx_id = nSYAudioFGMDeadExplodeL

				ftCommonDeadAddDeadSFXSoundQueue(sfx_id)

				if fp.attr.dead_fgm_ids[0] != nSYAudioFGMVoiceEnd:
					ftCommonDeadAddDeadSFXSoundQueue(fp.attr.dead_fgm_ids[0])
				if fp.attr.dead_fgm_ids[1] != nSYAudioFGMVoiceEnd:
					ftCommonDeadAddDeadSFXSoundQueue(fp.attr.dead_fgm_ids[1])
				fp.status_vars.common.dead.wait = FTCOMMON_DEAD_WAIT
				fp.motion_vars.flags.flag1 += 1

			2:
				ftCommonDeadCheckRebirth(fighter_gobj)

			_:
				pass

## 0x8013CAAC
static func ftCommonDeadUpFallSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftCommonDeadResetCommonVars(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusDeadUpFall, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftphysics.ftPhysicsStopVelAll(fighter_gobj)

	fp.status_vars.common.dead.pos = DObjGetStruct(fighter_gobj).translate

	fp.camera_mode = nFTCameraModeDeadUp

	fp.status_vars.common.dead.wait = 1

	fp.motion_vars.flags.flag1 = 0

	ftCommonDeadResetSpecialStats(fighter_gobj)
	Ftparam.ftParamSetPlayerTagWait(fighter_gobj, 1)

	if fp.attr.deadup_sfx != nSYAudioFGMVoiceEnd:
		Snd.func_800269C0_275C0(fp.attr.deadup_sfx)
	Ftparam.ftParamMoveDLLink(fighter_gobj, 19)
	Ftparam.ftParamSetModelPartDetailAll(fighter_gobj, nFTPartsDetailHigh)

## 0x8013CB7C
static func ftCommonDeadCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	# Vec3f *pos = &fp->joints[nFTPartsJointTopN]->translate.vec.f; (written through below)
	var pos_joint: DObj = fp.joints[nFTPartsJointTopN]
	var gd = Mpcollision.gMPCollisionGroundData

	if fp.fkind == nFTKindBoss:
		return FALSE
	if fp.is_ignore_dead:
		return FALSE
	if fp.is_limit_map_bounds:
		if pos_joint.translate.y < gd.map_bound_bottom:
			pos_joint.translate.y = gd.map_bound_bottom + 500.0

			fp.physics.vel_air.x = 0.0
			fp.physics.vel_air.y = 0.0
			fp.physics.vel_air.z = 0.0
		elif pos_joint.translate.y > gd.map_bound_top:
			pos_joint.translate.y = gd.map_bound_top - 500.0

			fp.physics.vel_air.x = 0.0
			fp.physics.vel_air.y = 0.0
			fp.physics.vel_air.z = 0.0
		if pos_joint.translate.x > gd.map_bound_right:
			pos_joint.translate.x = gd.map_bound_right - 500.0

			fp.physics.vel_air.x = 0.0
			fp.physics.vel_air.y = 0.0
			fp.physics.vel_air.z = 0.0
		elif pos_joint.translate.x < gd.map_bound_left:
			pos_joint.translate.x = gd.map_bound_left + 500.0

			fp.physics.vel_air.x = 0.0
			fp.physics.vel_air.y = 0.0
			fp.physics.vel_air.z = 0.0
		return FALSE
	elif not fp.is_ghost:
		if (G.gSCManagerBattleState.game_type == nSCBattleGameType1PGame) and (G.gSCManagerBattleState.players[fp.player].is_spgame_enemy != FALSE):
			if pos_joint.translate.y < gd.map_bound_team_bottom:
				ftCommonDeadDownSetStatus(fighter_gobj)

				return TRUE
			if pos_joint.translate.x > gd.map_bound_team_right:
				ftCommonDeadRightSetStatus(fighter_gobj)

				return TRUE
			if pos_joint.translate.x < gd.map_bound_team_left:
				ftCommonDeadLeftSetStatus(fighter_gobj)

				return TRUE
			if pos_joint.translate.y > gd.map_bound_team_top:
				if syUtilsRandFloat() < FTCOMMON_DEAD_UPFALL_CHANCE_F32:
					ftCommonDeadUpFallSetStatus(fighter_gobj)

					return TRUE
				else:
					ftCommonDeadUpStarSetStatus(fighter_gobj)

				return TRUE
		elif pos_joint.translate.y < gd.map_bound_bottom:
			ftCommonDeadDownSetStatus(fighter_gobj)

			return TRUE
		elif pos_joint.translate.x > gd.map_bound_right:
			ftCommonDeadRightSetStatus(fighter_gobj)

			return TRUE
		elif pos_joint.translate.x < gd.map_bound_left:
			ftCommonDeadLeftSetStatus(fighter_gobj)

			return TRUE
		elif pos_joint.translate.y > gd.map_bound_top:
			if syUtilsRandFloat() < FTCOMMON_DEAD_UPFALL_CHANCE_F32:
				ftCommonDeadUpFallSetStatus(fighter_gobj)
			else:
				ftCommonDeadUpStarSetStatus(fighter_gobj)

			return TRUE
	return FALSE
