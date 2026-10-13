## 1:1 port of src/sc/sccommon/scvsbattle.c (ssb-decomp-re): the VS battle scene (normal battle +
## sudden death) and, for the results screen, the ranking logic of src/mn/mnvsmode/mnvsresults.c.
##
## ENTRY POINTS (Godot side, 60 Hz):
##   Scvsbattle.port_start_battle()      scene start (overlay BSS clear + scVSBattleStartScene prologue +
##                                       task start = scVSBattleStartBattle). Reads G.gSCManagerBattleState.
##   Scvsbattle.port_update_frame()      one task frame: VI retrace tic, scVSBattleFuncUpdate
##                                       (= Ifcommon.ifCommonBattleUpdateInterfaceAll -> gcRunAll), then the
##                                       HUD model (Ifcommon.ui). Read the controllers BEFORE calling it.
##                                       Returns port_phase. When the battle task ends (syTaskmanSetLoadScene)
##                                       the rest of scVSBattleStartScene runs: sudden death check/start, or
##                                       scene_curr = nSCKindVSResults + port_results.
##   Scvsbattle.port_phase               PORT_PHASE_BATTLE / _SUDDENDEATH / _FINISHED
##   Scvsbattle.port_results             (valid when FINISHED) see port_compute_results()
##   Scvsbattle.port_results_exit()      the results screen's exit (mnVSResultsFuncRun): next scene + unlocks
##   Scvsbattle.port_make_vs_battle_state(cfg) fills G.gSCManagerTransferBattleState like the VS menus.
##
## BATTLE STATE FIELDS (G.SCBattleState, filled by the menus = mnPlayersVSSetSceneData / mnVSOptions /
## mnVSItemSwitch / mnMaps):  game_type (set to Royal here), gkind (from gSCManagerSceneData.gkind),
##   is_team_battle, game_rules (SCBATTLE_GAMERULE_TIME 1 / _STOCK 2), pl_count, cp_count,
##   time_limit (minutes, SCBATTLE_TIMELIMIT_INFINITE = 100), stocks (lives - 1), handicap (0 off/1 on/2 auto),
##   is_team_attack, is_stage_select, damage_ratio (%), item_toggles (bit mask), item_appearance_rate,
##   is_show_score, is_not_teamshadows; players[i]: pkind (Man/Com/Not), fkind, level (CPU 1-9),
##   handicap (1-9), team (0 red, 1 blue, 2 green), player (= i, or = team in team battles), costume,
##   shade, color (FFA: i for humans, 4 for CPUs; teams: dIFCommonPlayerTeamColorIDs[team]),
##   tag (i for humans, 4 = "CP"), is_single_stockicon (TRUE in time battles).
class_name Scvsbattle
extends Port

const PORT_PHASE_IDLE := 0
const PORT_PHASE_BATTLE := 1
const PORT_PHASE_SUDDENDEATH := 2
const PORT_PHASE_FINISHED := 3

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8018E3D0
static var dSCVSBattleCommonFadeColor: Dictionary = {"r": 0x00, "g": 0x00, "b": 0x00, "a": 0x00}
## 0x8018E3D4
static var dSCVSBattleSuddenDeathFadeColor: Dictionary = {"r": 0x00, "g": 0x00, "b": 0x00, "a": 0x00}
## 0x8018E3D8 SYVIDEO_SETUP_DEFAULT()
static var dSCVSBattleVideoSetup: Dictionary = {"framebuffers": [0, 1, 2], "zbuffer": null, "width": 320, "height": 240, "flags": 0}
## 0x8018E3F4
static var dSCVSBattleTaskmanSetup: Dictionary = {
	"scene_setup": {"func_update": Callable(Scvsbattle, &"scVSBattleFuncUpdate"), "func_lights": Callable(Scvsbattle, &"scVSBattleFuncLights"), "arena_size": 0},
	"func_start": Callable(Scvsbattle, &"scVSBattleStartBattle"),
}

# --- port-only ----------------------------------------------------------------------------------
static var port_phase: int = PORT_PHASE_IDLE
static var port_results: Dictionary = {}

# mnvsresults.c statics used by the ranking (0x80139B80 ...)
static var sMNVSResultsKOs: Array = [0, 0, 0, 0]
static var sMNVSResultsTKO: Array = [0, 0, 0, 0]
static var sMNVSResultsPoints: Array = [0, 0, 0, 0]
static var sMNVSResultsPlaces: Array = [0, 0, 0, 0]
static var sMNVSResultsIsPresent: Array = [0, 0, 0, 0]
static var sMNVSResultsFighterKinds: Array = [0, 0, 0, 0]
static var sMNVSResultsKind: int = 0
static var sMNVSResultsIsTeamBattle: int = 0
static var sMNVSResultsAllowExitWait: int = 0
static var sMNVSResultsIsSharedWinner: Array = [0, 0, 0, 0]
static var sMNVSResultsDrawWallpaperTic: int = 0
static var sMNVSResultsMakeResultsTic: int = 0
static var sMNVSResultsInitFightersAllTic: int = 0

# src/mn/mndef.h MNVSResultsKind
const nMNVSResultsKindTimeRoyal := 0
const nMNVSResultsKindStockRoyal := 1
const nMNVSResultsKindTimeTeam := 2
const nMNVSResultsKindStockTeam := 3
const nMNVSResultsKindNoContest := 4
# src/lb/lbdef.h
const LBBACKUP_GROUND_MASK_ALL := 0xFF
const LBBACKUP_CHARACTER_MASK_STARTER := 0xFFF & ~0xC90
const _PORT_TRANSITIONS_NUM := 11      # ARRAY_COUNT(dLBTransitionDescs) (src/lb/lbtransition.c)

# // // // // // // // // // // // //
# //        PORT ENTRY POINTS      //
# // // // // // // // // // // // //

## scManagerRunLoop case nSCKindVSBattle: syDmaLoadOverlay(2, 3, 4) (BSS cleared) + scVSBattleStartScene().
static func port_start_battle() -> void:
	Ifcommon.port_reset_bss()
	Ifscreenflash.port_reset_bss()
	Ftpublic.port_reset_bss()
	port_results = {}
	G.gSCManagerSceneData.scene_curr = nSCKindVSBattle
	scVSBattleStartScene()

## One 60 Hz frame of the running battle task (syTaskmanRunTask loop body).
static func port_update_frame() -> int:
	if (port_phase != PORT_PHASE_BATTLE) and (port_phase != PORT_PHASE_SUDDENDEATH):
		return port_phase
	Ifcommon.port_vi_retrace()
	Ifcommon.port_frame += 1
	dSCVSBattleTaskmanSetup.scene_setup.func_update.call()

	if Ifcommon.port_load_scene_requested:          # syTaskmanCheckBreakLoop
		_port_on_task_end()
	else:
		Ifcommon.port_update_ui()                   # task_draw (scManagerFuncDraw)
	return port_phase

static func port_is_finished() -> bool:
	return port_phase == PORT_PHASE_FINISHED

## scManagerFuncUpdate (src/sc/scmanager.c) -> syTaskmanStartTask: fresh object manager, func_start.
static func scManagerFuncUpdate(setup: Dictionary) -> void:
	Ifcommon.port_task_start()
	setup.func_start.call()
	Ifcommon.port_update_ui()

static func _port_after_task() -> void:
	Audio.syAudioStopBGMAll()

	while B(Audio.syAudioCheckBGMPlaying(0)):
		pass
	Audio.syAudioSetBGMVolume(0, 0x7800)
	Snd.func_800266A0_272A0()
	Gmrumble.gmRumbleInitPlayers()

## Continuation of scVSBattleStartScene after a scManagerFuncUpdate() returned.
static func _port_on_task_end() -> void:
	_port_after_task()

	if port_phase == PORT_PHASE_BATTLE:
		if not B(G.gSCManagerSceneData.is_reset) and (scVSBattleSetScoreCheckSuddenDeath() != FALSE):
			G.gSCManagerBattleState = G.gSCManagerVSBattleState

			G.gSCManagerBattleState.game_type = nSCBattleGameTypeRoyal

			dSCVSBattleTaskmanSetup.func_start = Callable(Scvsbattle, &"scVSBattleStartSuddenDeath")

			port_phase = PORT_PHASE_SUDDENDEATH
			scManagerFuncUpdate(dSCVSBattleTaskmanSetup)
			return
	G.gSCManagerSceneData.scene_prev = G.gSCManagerSceneData.scene_curr
	G.gSCManagerSceneData.scene_curr = nSCKindVSResults

	port_phase = PORT_PHASE_FINISHED
	port_compute_results()

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8018D0C0
static func scVSBattleFuncUpdate() -> void:
	Ifcommon.ifCommonBattleUpdateInterfaceAll()

## 0x8018D0E0 - player's initial facing direction
static func scVSBattleGetStartPlayerLR(this_player: int) -> int:
	var near_dist: float = 65536.0
	var near_spawn: float = 0.0
	var this_spawn_pos: Vector3 = Mpcollision.mpCollisionGetPlayerMapObjPosition(this_player, Vector3.ZERO)
	var bs = G.gSCManagerBattleState

	for loop_player in range(bs.players.size()):
		if loop_player == this_player:
			continue
		elif bs.players[loop_player].pkind == nFTPlayerKindNot:
			continue
		elif bs.players[loop_player].player != bs.players[this_player].player:
			var loop_spawn_pos: Vector3 = Mpcollision.mpCollisionGetPlayerMapObjPosition(loop_player, Vector3.ZERO)
			var distx: float = -(loop_spawn_pos.x - this_spawn_pos.x) if (loop_spawn_pos.x < this_spawn_pos.x) else (loop_spawn_pos.x - this_spawn_pos.x)

			if near_dist > distx:
				near_dist = distx
				near_spawn = loop_spawn_pos.x - this_spawn_pos.x
	return +1 if (near_spawn >= 0.0) else -1

## ftParamInitGame (src/ft/ftparam.c 0x800EC130) = ftMainClearGroundElementsAll() + ifCommonBattleInitPlacement()
## (Ftparam now makes both calls itself).
static func _port_ftParamInitGame() -> void:
	Ftparam.ftParamInitGame()

## Shared fighter creation loop of StartBattle / StartSuddenDeath.
static func _port_make_fighters(is_suddendeath: bool) -> void:
	var bs = G.gSCManagerBattleState

	for player in range(bs.players.size()):
		var desc: Dictionary = Ftmanager.default_desc()
		var fighter_gobj

		if bs.players[player].pkind == nFTPlayerKindNot:
			continue
		Ftmanager.ftManagerSetupFilesAllKind(bs.players[player].fkind)

		desc.fkind = bs.players[player].fkind

		desc.pos = Mpcollision.mpCollisionGetPlayerMapObjPosition(player, desc.pos)

		desc.lr = scVSBattleGetStartPlayerLR(player)

		desc.team = bs.players[player].player
		desc.player = player

		desc.detail = nFTPartsDetailHigh if ((bs.pl_count + bs.cp_count) < 3) else nFTPartsDetailLow

		desc.costume = bs.players[player].costume
		desc.shade = bs.players[player].shade
		desc.handicap = bs.players[player].handicap
		desc.level = bs.players[player].level
		if is_suddendeath:
			desc.stock_count = 0
			desc.damage = 300
			desc.is_skip_entry = TRUE
		else:
			desc.stock_count = bs.stocks
			desc.damage = 0
		desc.pkind = bs.players[player].pkind
		desc.controller = Controller.gSYControllerDevices[player]

		desc.figatree_heap = Ftmanager.ftManagerAllocFigatreeHeapKind(bs.players[player].fkind)

		fighter_gobj = Ftmanager.ftManagerMakeFighter(desc)

		Ftparam.ftParamInitPlayerBattleStats(player, fighter_gobj)

		if is_suddendeath:
			bs.players[player].is_single_stockicon = FALSE

## 0x8018D228
static func scVSBattleStartBattle() -> void:
	G.gSCManagerSceneData.is_reset = FALSE
	G.gSCManagerSceneData.is_suddendeath = FALSE

	Scvsbattlefiles.scVSBattleSetupFiles()

	if not (G.gSCManagerBackupData.error_flags & LBBACKUP_ERROR_1PGAMEMARIO) and (G.gSCManagerBackupData.boot > 68):
		# llSYKseg1Validate anti-tamper routine loaded from the ROM: a genuine cartridge passes
		# (func_kseg1() != FALSE), so LBBACKUP_ERROR_1PGAMEMARIO is not set.
		pass
	Objhelper.gcMakeDefaultCameraGObj(nGCCommonLinkIDCamera, GOBJ_PRIORITY_DEFAULT, 100, COBJ_FLAG_ZBUFFER, 0x000000FF)
	Efparticle.efParticleInitAll()
	_port_ftParamInitGame()
	Mpcollision.mpCollisionInitGroundData()
	Gmcamera.gmCameraSetViewportDimensions(10, 10, 310, 230)
	Gmcamera.gmCameraMakeWallpaperCamera()
	Grwallpaper.grWallpaperMakeDecideKind()
	Gmcamera.gmCameraMakeBattleCamera()
	Itmanager.itManagerInitItems()
	Grcommonsetup.grCommonSetupInitAll()
	Ftmanager.ftManagerAllocFighter(FTDATA_FLAG_MAINMOTION, GMCOMMON_PLAYERS_MAX)
	Wpmanager.wpManagerAllocWeapons()
	Efmanager.efManagerInitEffects()
	Ifscreenflash.ifScreenFlashMakeInterface(0xFF)
	Gmrumble.gmRumbleMakeActor()
	Ftpublic.ftPublicMakeActor()

	_port_make_fighters(false)

	Ftmanager.ftManagerSetupFilesPlayablesAll()
	Ifcommon.ifCommonBattleSetGameStatusWait()
	Gmcamera.gmCameraMakePlayerArrowsCamera()
	Ifcommon.ifCommonPlayerArrowsInitInterface()
	Gmcamera.gmCameraMakePlayerMagnifyCamera()
	Ifcommon.ifCommonPlayerMagnifyMakeInterface()
	Gmcamera.gmCameraScreenFlashMakeCamera()
	Gmcamera.gmCameraMakeInterfaceCamera()
	Gmcamera.gmCameraMakeEffectCamera()
	Ifcommon.ifCommonPlayerTagMakeInterface()
	Ifcommon.ifCommonPlayerDamageSetDigitPositions()
	Ifcommon.ifCommonPlayerDamageInitInterface()
	Ifcommon.ifCommonPlayerStockInitInterface()
	Ifcommon.ifCommonEntryAllMakeInterface()
	Mpcollision.mpCollisionSetPlayBGM()
	Snd.func_800269C0_275C0(nSYAudioVoicePublicExcited)
	Ifcommon.ifCommonTimerMakeInterface(Callable(Ifcommon, &"ifCommonAnnounceTimeUpInitInterface"))
	Ifcommon.ifCommonTimerMakeDigits()

	Lbfade.lbFadeMakeActor(nGCCommonKindTransition, nGCCommonLinkIDTransition, 10, dSCVSBattleCommonFadeColor.duplicate(), 12, TRUE, null)

## 0x8018D5E0 - sort time-battle results; TRUE (and gSCManagerVSBattleState set up) if sudden death
static func scVSBattleSetScoreCheckSuddenDeath() -> int:
	var bs = G.gSCManagerBattleState
	var vs = G.gSCManagerVSBattleState
	var result_count := 0
	var tied_players := 0
	var player_results: Array = []

	if not (bs.game_rules & SCBATTLE_GAMERULE_TIME):
		return FALSE
	for i in 4:
		player_results.append({"tko": 0, "kos": 0, "player_or_team": 0, "unk_battleres_0x9": 0, "is_human": 0})

	vs.copy_from(G.gSCManagerTransferBattleState)
	vs.pl_count = 0
	vs.cp_count = 0

	for i in range(vs.players.size()):
		vs.players[i].pkind = nFTPlayerKindNot

	if int(bs.is_team_battle) == FALSE:
		for i in range(bs.players.size()):
			if bs.players[i].pkind == nFTPlayerKindNot:
				continue
			player_results[result_count].tko = bs.players[i].score - bs.players[i].falls
			player_results[result_count].kos = bs.players[i].score
			player_results[result_count].player_or_team = i
			player_results[result_count].unk_battleres_0x9 = FALSE
			player_results[result_count].is_human = TRUE if (bs.players[i].pkind == nFTPlayerKindMan) else FALSE

			result_count += 1
		_port_sort_results(player_results, result_count)

		player_results[0].unk_battleres_0x9 = TRUE

		tied_players = 1
		for i in range(1, result_count):
			if player_results[0].tko == player_results[i].tko:
				player_results[i].unk_battleres_0x9 = TRUE
				tied_players += 1
		if tied_players < 2:
			return FALSE
		for i in range(tied_players):
			var pot: int = player_results[i].player_or_team
			vs.players[pot].pkind = bs.players[pot].pkind

			if vs.players[pot].pkind == nFTPlayerKindMan:
				vs.pl_count += 1
			elif vs.players[pot].pkind == nFTPlayerKindCom:
				vs.cp_count += 1
	elif int(bs.is_team_battle) == TRUE:
		for i in range(bs.players.size()):
			if bs.players[i].pkind == nFTPlayerKindNot:
				continue
			var found := false
			for j in range(result_count):
				if bs.players[i].team == player_results[j].player_or_team:
					player_results[j].tko += bs.players[i].score - bs.players[i].falls
					player_results[j].kos += bs.players[i].score

					if B(player_results[j].is_human) or (bs.players[i].pkind == nFTPlayerKindMan):
						player_results[j].is_human = TRUE
					else:
						player_results[j].is_human = FALSE
					found = true
					break           # goto l_continue
			if found:
				continue
			player_results[result_count].tko = bs.players[i].score - bs.players[i].falls
			player_results[result_count].kos = bs.players[i].score
			player_results[result_count].player_or_team = bs.players[i].team
			player_results[result_count].unk_battleres_0x9 = FALSE

			if B(player_results[result_count].is_human) or (bs.players[i].pkind == nFTPlayerKindMan):
				player_results[result_count].is_human = TRUE
			else:
				player_results[result_count].is_human = FALSE

			result_count += 1
		_port_sort_results(player_results, result_count)

		player_results[0].unk_battleres_0x9 = TRUE

		tied_players = 1
		for i in range(1, result_count):
			if player_results[0].tko == player_results[i].tko:
				player_results[i].unk_battleres_0x9 = TRUE
				tied_players += 1
		if tied_players < 2:
			return FALSE
		for i in range(tied_players):
			for j in range(bs.players.size()):
				if bs.players[j].pkind == nFTPlayerKindNot:
					continue
				if bs.players[j].team == player_results[i].player_or_team:
					vs.players[j].pkind = bs.players[j].pkind

					if vs.players[j].pkind == nFTPlayerKindMan:
						vs.pl_count += 1
					elif vs.players[j].pkind == nFTPlayerKindCom:
						vs.cp_count += 1
	vs.game_rules = SCBATTLE_GAMERULE_STOCK
	vs.is_show_score = FALSE

	G.gSCManagerSceneData.is_suddendeath = TRUE

	return TRUE

## the selection-style swap sort of scVSBattleSetScoreCheckSuddenDeath (struct swaps)
static func _port_sort_results(player_results: Array, result_count: int) -> void:
	for i in range(result_count):
		for j in range(i + 1, result_count):
			if player_results[i].tko < player_results[j].tko:
				var winner_results: Dictionary = player_results[i]
				player_results[i] = player_results[j]
				player_results[j] = winner_results

## 0x8018DE20 - Start sudden death
static func scVSBattleStartSuddenDeath() -> void:
	G.gSCManagerSceneData.is_reset = FALSE

	Scvsbattlefiles.scVSBattleSetupFiles()
	Objhelper.gcMakeDefaultCameraGObj(nGCCommonLinkIDCamera, GOBJ_PRIORITY_DEFAULT, 100, COBJ_FLAG_ZBUFFER, 0x000000FF)
	Efparticle.efParticleInitAll()
	_port_ftParamInitGame()
	Mpcollision.mpCollisionInitGroundData()
	Gmcamera.gmCameraSetViewportDimensions(10, 10, 310, 230)
	Gmcamera.gmCameraMakeWallpaperCamera()
	Grwallpaper.grWallpaperMakeDecideKind()
	Gmcamera.gmCameraMakeBattleCamera()
	Itmanager.itManagerInitItems()
	Grcommonsetup.grCommonSetupInitAll()
	Ftmanager.ftManagerAllocFighter(2, GMCOMMON_PLAYERS_MAX)
	Wpmanager.wpManagerAllocWeapons()
	Efmanager.efManagerInitEffects()
	Ifscreenflash.ifScreenFlashMakeInterface(0xFF)
	Gmrumble.gmRumbleMakeActor()
	Ftpublic.ftPublicMakeActor()

	_port_make_fighters(true)

	Ftmanager.ftManagerSetupFilesPlayablesAll()
	Ifcommon.ifCommonBattleSetGameStatusWait()
	Gmcamera.gmCameraMakePlayerArrowsCamera()
	Ifcommon.ifCommonPlayerArrowsInitInterface()
	Gmcamera.gmCameraMakePlayerMagnifyCamera()
	Ifcommon.ifCommonPlayerMagnifyMakeInterface()
	Gmcamera.gmCameraScreenFlashMakeCamera()
	Gmcamera.gmCameraMakeInterfaceCamera()
	Gmcamera.gmCameraMakeEffectCamera()
	Ifcommon.ifCommonPlayerTagMakeInterface()
	Ifcommon.ifCommonPlayerDamageSetDigitPositions()
	Ifcommon.ifCommonPlayerDamageInitInterface()
	Ifcommon.ifCommonPlayerStockInitInterface()
	Ifcommon.ifCommonSuddenDeathMakeInterface()
	Mpcollision.mpCollisionSetPlayBGM()
	Snd.func_800269C0_275C0(nSYAudioVoicePublicExcited)
	Ifcommon.ifCommonTimerMakeInterface(Callable(Ifcommon, &"ifCommonAnnounceTimeUpInitInterface"))
	Ifcommon.ifCommonTimerMakeDigits()

	Lbfade.lbFadeMakeActor(nGCCommonKindTransition, nGCCommonLinkIDTransition, 10, dSCVSBattleSuddenDeathFadeColor.duplicate(), 12, TRUE, null)

## 0x8018E144 - pre-render function (render side)
static func scVSBattleFuncLights(dls = null) -> void:
	# gSPSetGeometryMode(dls[0]++, G_LIGHTING)
	Ftdisplaylights.ftDisplayLightsDrawReflect(dls, Mpcollision.gMPCollisionLightAngleX, Mpcollision.gMPCollisionLightAngleY)

## 0x8018E190 - up to the first scManagerFuncUpdate; the rest is _port_on_task_end().
static func scVSBattleStartScene() -> void:
	# The port's menus fill G.gSCManagerBattleState: it is the transfer state of this battle.
	G.gSCManagerTransferBattleState = G.gSCManagerBattleState

	G.gSCManagerBattleState = G.gSCManagerTransferBattleState
	G.gSCManagerBattleState.game_type = nSCBattleGameTypeRoyal
	G.gSCManagerBattleState.gkind = G.gSCManagerSceneData.gkind

	if G.gSCManagerBackupData.error_flags & LBBACKUP_ERROR_VSBATTLECASTLE:
		G.gSCManagerBattleState.gkind = nGRKindCastle
	dSCVSBattleVideoSetup.zbuffer = "SYVIDEO_ZBUFFER_START(320, 240, 0, 10, u16)"
	Video.syVideoInit(dSCVSBattleVideoSetup)

	dSCVSBattleTaskmanSetup.scene_setup.arena_size = 0
	dSCVSBattleTaskmanSetup.func_start = Callable(Scvsbattle, &"scVSBattleStartBattle")
	port_phase = PORT_PHASE_BATTLE
	scManagerFuncUpdate(dSCVSBattleTaskmanSetup)

# // // // // // // // // // // // // // // // // // // //
# //  VS RESULTS RANKING (src/mn/mnvsmode/mnvsresults.c) //
# // // // // // // // // // // // // // // // // // // //

## 0x80131B78
static func mnVSResultsGetPlayerCount() -> int:
	return G.gSCManagerTransferBattleState.pl_count + G.gSCManagerTransferBattleState.cp_count

## 0x80131B90 - VS records (lbBackupWrite: save is the Godot side's job)
static func mnVSResultsSaveBackup() -> void:
	var bk = G.gSCManagerBackupData
	var ts = G.gSCManagerTransferBattleState

	bk.vs_total_battles = (bk.vs_total_battles + 1) & 0xFFFF
	bk.ground_mask = (bk.ground_mask | (1 << ts.gkind)) & 0xFFFF

	if bk.vs_itemswitch_battles < 0xFF:
		bk.vs_itemswitch_battles += 1
	for i in range(ts.players.size()):
		if ts.players[i].pkind != nFTPlayerKindNot:
			var this_fkind: int = ts.players[i].fkind & 0xFF
			var rec = bk.vs_records[this_fkind]

			rec.time_used += (ts.time_passed / UPDATE_INTERVAL)

			if rec.time_used > Ifcommon.I_MIN_TO_TICS(1000) - 1:
				rec.time_used = Ifcommon.I_MIN_TO_TICS(1000) - 1
			rec.damage_given += ts.players[i].total_damage_given

			if rec.damage_given > 999999:
				rec.damage_given = 999999
			rec.damage_taken += ts.players[i].total_damage_all

			if rec.damage_taken > 999999:
				rec.damage_taken = 999999
			rec.selfdestructs += ts.players[i].total_selfdestructs

			if rec.selfdestructs > 9999:
				rec.selfdestructs = 9999
			rec.games_played = (rec.games_played + 1) & 0xFFFF
			rec.player_count_tally = (rec.player_count_tally + mnVSResultsGetPlayerCount()) & 0xFFFF

			for j in range(ts.players.size()):
				if (i != j) and (ts.players[j].pkind != nFTPlayerKindNot):
					var vs_fkind: int = ts.players[j].fkind & 0xFF

					rec.ko_count[vs_fkind] += ts.players[i].total_kos_players[j]

					if rec.ko_count[vs_fkind] > 9999:
						rec.ko_count[vs_fkind] = 9999
					rec.player_count_tallies[vs_fkind] = (rec.player_count_tallies[vs_fkind] + mnVSResultsGetPlayerCount()) & 0xFFFF
					rec.played_against[vs_fkind] = (rec.played_against[vs_fkind] + 1) & 0xFFFF
	Lbbackup.lbBackupWrite()

## 0x8013205C
static func mnVSResultsGetPresentCount() -> int:
	var sum := 0
	for i in range(sMNVSResultsIsPresent.size()):
		if sMNVSResultsIsPresent[i] == TRUE:
			sum += 1
	return sum

## 0x801320B8
static func mnVSResultsGetPresentLowerCount(player: int) -> int:
	var sum := 0
	for i in range(sMNVSResultsIsPresent.size()):
		if player != i:
			if sMNVSResultsIsPresent[i] == TRUE:
				sum += 1
		else:
			break
	return sum

## 0x80132100
static func mnVSResultsGetPlacePlayer(place: int) -> int:
	for i in range(sMNVSResultsIsPresent.size()):
		if (sMNVSResultsIsPresent[i] != FALSE) and (place == sMNVSResultsPlaces[i]):
			return i
	return -1

## 0x801321AC
static func mnVSResultsGetPlayerDistanceID(player: int) -> int:
	var foes: int = mnVSResultsGetPresentLowerCount(player)

	if mnVSResultsGetPlayerCountPlace(0) == 1:
		match mnVSResultsGetPresentCount():
			2:
				pass
			3:
				if sMNVSResultsPlaces[player] == 0:
					match mnVSResultsGetPresentLowerCount(player):
						0:
							foes = 1
						2:
							foes = 1
				elif mnVSResultsGetPresentLowerCount(player) == 1:
					foes = mnVSResultsGetPresentLowerCount(mnVSResultsGetPlacePlayer(0))
			_:
				match player:
					0:
						if (sMNVSResultsPlaces[0] == 0) and (sMNVSResultsPlaces[1] != 0):
							foes = 1
					1:
						if (sMNVSResultsPlaces[0] == 0) and (sMNVSResultsPlaces[1] != 0):
							foes = 0
					2:
						if (sMNVSResultsPlaces[3] == 0) and (sMNVSResultsPlaces[2] != 0):
							foes = 3
					3:
						if (sMNVSResultsPlaces[3] == 0) and (sMNVSResultsPlaces[2] != 0):
							foes = 2
	return foes

## 0x8013234C (sMNVSResultsKind compared with nSCBattleGameRuleTime/Stock = Time/StockRoyal, as in C)
static func mnVSResultsGetWinPlayer() -> int:
	var winners_possible: Array = [0, 0, 0, 0]
	var score: Array = [0, 0, 0, 0]
	var win_player := 666
	var winners_multi: Array = [0, 0, 0, 0]
	var is_winners_multi := FALSE

	if (sMNVSResultsKind == nSCBattleGameRuleTime) or (sMNVSResultsKind == nSCBattleGameRuleStock):
		for i in 4:
			if (sMNVSResultsIsPresent[i] == TRUE) and (sMNVSResultsPlaces[i] == 0):
				return i
		return -1       # (C falls off the end: undefined)
	for i in 4:
		score[i] = mnVSResultsGetPointsDirect(i)
	for i in 4:
		if (sMNVSResultsIsPresent[i] != FALSE) and (sMNVSResultsPlaces[i] == 0):
			if win_player == 666:
				win_player = i
			winners_possible[i] = TRUE
		else:
			winners_possible[i] = FALSE
	for i in 4:
		winners_multi[i] = FALSE
	for i in range(win_player + 1, 4):
		if (winners_possible[i] != FALSE) and (score[win_player] < score[i]):
			win_player = i
	is_winners_multi = FALSE

	for i in range(win_player + 1, 4):
		if (winners_possible[i] != FALSE) and (score[win_player] == score[i]):
			winners_multi[win_player] = TRUE
			winners_multi[i] = TRUE
			is_winners_multi = TRUE
	if is_winners_multi != FALSE:
		for i in range(win_player + 1, 4):
			if B(winners_multi[i]) and (sMNVSResultsKOs[win_player] < sMNVSResultsKOs[i]):
				win_player = i
		for i in 4:
			sMNVSResultsIsSharedWinner[i] = FALSE
		for i in range(win_player + 1, 4):
			if sMNVSResultsKOs[win_player] == sMNVSResultsKOs[i]:
				sMNVSResultsIsSharedWinner[i] = TRUE
				sMNVSResultsIsSharedWinner[win_player] = TRUE
	return win_player

## 0x80132A2C
static func mnVSResultsGetWinTeam() -> int:
	return G.gSCManagerTransferBattleState.players[mnVSResultsGetWinPlayer()].team

## 0x80133134
static func mnVSResultsGetPlace(player: int) -> int:
	return sMNVSResultsPlaces[player]

## 0x80133148
static func mnVSResultsGetFighterKind(player: int) -> int:
	return sMNVSResultsFighterKinds[player]

## 0x8013315C
static func mnVSResultsSetFighterKindAll() -> void:
	for i in 4:
		if sMNVSResultsIsPresent[i] != FALSE:
			sMNVSResultsFighterKinds[i] = G.gSCManagerTransferBattleState.players[i].fkind

## 0x801331DC - results stage position of a fighter (returns the DObj translate)
static func mnVSResultsSetFighterPosition(player: int, place: int) -> Vector3:
	var pos_x_2p: Array = [[-150.0, -350.0, -700.0, -1000.0], [100.0, 250.0, 600.0, 1000.0]]
	var pos_x_3p: Array = [[-450.0, -900.0, -2000.0, -3000.0], [0.0, 0.0, 0.0, 0.0], [400.0, 800.0, 1800.0, 2800.0]]
	var pos_x_4p: Array = [[-450.0, -900.0, -2000.0, -3000.0], [-150.0, -350.0, -700.0, -1000.0], [150.0, 300.0, 700.0, 1000.0], [400.0, 800.0, 1800.0, 2800.0]]
	var pos_yz: Array = [[-350.0, 0.0], [-450.0, -2000.0], [-700.0, -5000.0], [-900.0, -9000.0]]
	var x: float

	match mnVSResultsGetPresentCount():
		2:
			x = pos_x_2p[mnVSResultsGetPlayerDistanceID(player)][place]
		3:
			x = pos_x_3p[mnVSResultsGetPlayerDistanceID(player)][place]
		_:
			x = pos_x_4p[mnVSResultsGetPlayerDistanceID(player)][place]
	return Vector3(x, pos_yz[place][0], pos_yz[place][1])

## 0x8013345C (RNG)
static func mnVSResultsGetStatusWin(fkind: int) -> int:
	var status_ids: Array = [nFTDemoStatusWin1, nFTDemoStatusWin2, nFTDemoStatusWin3]

	if fkind == nFTKindKirby:
		return status_ids[syUtilsRandIntRange(2)]
	else:
		return status_ids[syUtilsRandIntRange(3)]

## 0x801334CC
static func mnVSResultsGetStatusLose(fkind: int) -> int:
	return nFTDemoStatusLose

## 0x801334DC - returns the status scSubsysFighterSetStatus would get
static func mnVSResultsSetFighterStatus(player: int) -> int:
	if sMNVSResultsKind == nMNVSResultsKindNoContest:
		return mnVSResultsGetStatusLose(mnVSResultsGetFighterKind(player))
	match mnVSResultsGetPresentCount():
		2:
			match sMNVSResultsPlaces[player]:
				0:
					return mnVSResultsGetStatusWin(mnVSResultsGetFighterKind(player))
				1:
					return mnVSResultsGetStatusLose(mnVSResultsGetFighterKind(player))
			return -1
		_:
			if sMNVSResultsPlaces[player] == 0:
				return mnVSResultsGetStatusWin(mnVSResultsGetFighterKind(player))
			return mnVSResultsGetStatusLose(mnVSResultsGetFighterKind(player))

## 0x80133684
static func mnVSResultsGetPlayerCountPlace(place: int) -> int:
	var num := 0
	for i in 4:
		if (sMNVSResultsIsPresent[i] != FALSE) and (place == sMNVSResultsPlaces[i]):
			num += 1
	return num

## 0x80133718
static func mnVSResultsGetPlayerCountAhead(player: int) -> int:
	var num := 0
	for i in 4:
		if (player != i) and (sMNVSResultsIsPresent[i] != FALSE) and (sMNVSResultsPlaces[i] < sMNVSResultsPlaces[player]):
			num += 1
	return num

## 0x80133810
static func mnVSResultsGetSpot(player: int) -> int:
	var aheads: Array = [0, 0, 1, 1]
	var places: Array = [0, 0, 1, 1, 1]

	return sMNVSResultsPlaces[player] + aheads[sMNVSResultsPlaces[player] - mnVSResultsGetPlayerCountAhead(player)] + places[mnVSResultsGetPlayerCountPlace(sMNVSResultsPlaces[player])]

## 0x80135670
static func mnVSResultsGetKOs(player: int) -> int:
	return 999 if sMNVSResultsKOs[player] > 999 else sMNVSResultsKOs[player]

## 0x801358C4
static func mnVSResultsGetTKO(player: int) -> int:
	return 999 if sMNVSResultsTKO[player] > 999 else sMNVSResultsTKO[player]

## 0x80135DB8
static func mnVSResultsGetPoints(player: int) -> int:
	return sMNVSResultsPoints[player]

## 0x8013607C
static func mnVSResultsGetDisplayPlace(player: int) -> int:
	if (mnVSResultsGetPresentCount() == GMCOMMON_PLAYERS_MAX) and (sMNVSResultsIsTeamBattle == FALSE) and (mnVSResultsGetPlayerCountPlace(1) == 2) and (sMNVSResultsPlaces[player] == 2):
		return GMCOMMON_PLAYERS_MAX
	return sMNVSResultsPlaces[player] + 1

## 0x80136A9C
static func mnVSResultsSetKOs() -> void:
	for i in 4:
		if sMNVSResultsIsPresent[i] != FALSE:
			sMNVSResultsKOs[i] = G.gSCManagerTransferBattleState.players[i].score

## 0x80136B1C
static func mnVSResultsSetTKO() -> void:
	for i in 4:
		if sMNVSResultsIsPresent[i] != FALSE:
			sMNVSResultsTKO[i] = G.gSCManagerTransferBattleState.players[i].falls

## 0x80136B9C
static func mnVSResultsSetPoints() -> void:
	for i in 4:
		sMNVSResultsPoints[i] = mnVSResultsGetKOs(i) - mnVSResultsGetTKO(i)

## 0x80136C08
static func mnVSResultsGetPointsDirect(player: int) -> int:
	return sMNVSResultsKOs[player] - sMNVSResultsTKO[player]

## 0x80136C2C
static func mnVSResultsOrderResults(results: Array, players_num: int) -> void:
	for i in range(players_num):
		for j in range(i + 1, players_num):
			if (results[i].score < results[j].score) or (B(G.gSCManagerSceneData.is_suddendeath) and (results[i].score == results[j].score) and (results[j].place < results[i].place)):
				var temp: Dictionary = results[i]
				results[i] = results[j]
				results[j] = temp

## 0x80136D28
static func mnVSResultsSetRoyalPlace() -> void:
	var results: Array = []
	var players_num := 0

	for i in 4:
		if B(sMNVSResultsIsPresent[i]):
			results.append({"score": mnVSResultsGetPointsDirect(i), "place": G.gSCManagerVSBattleState.players[i].place, "player": i})
			players_num += 1
	mnVSResultsOrderResults(results, players_num)

	if players_num == 0:
		return
	var place := 0
	var score: int = results[0].score
	var winner: int = results[0].place
	for i in range(players_num):
		if (score != results[i].score) or (B(G.gSCManagerSceneData.is_suddendeath) and (winner != results[i].place)):
			place += 1
			score = results[i].score
			winner = results[i].place
		sMNVSResultsPlaces[results[i].player] = place

## 0x80136FB8
static func mnVSResultsGetTeamTotalPoints(team: int) -> int:
	var total := 0
	for i in 4:
		if (sMNVSResultsIsPresent[i] != FALSE) and (team == G.gSCManagerTransferBattleState.players[i].team):
			total += mnVSResultsGetPointsDirect(i)
	return total

## 0x80137068
static func mnVSResultsSetTeamPlace(team: int, place: int) -> void:
	for i in 4:
		if (sMNVSResultsIsPresent[i] != FALSE) and (team == G.gSCManagerTransferBattleState.players[i].team):
			sMNVSResultsPlaces[i] = place

## 0x80137108
static func mnVSResultsGetTeamFirstPlayer(team: int) -> int:
	for i in 4:
		if (team == G.gSCManagerTransferBattleState.players[i].team) and (G.gSCManagerTransferBattleState.players[i].pkind != nFTPlayerKindNot):
			return i + 1
	return 0

## 0x801371B8
static func mnVSResultsSetTeamPlaceAll() -> void:
	var results: Array = []
	var players := 0

	for i in range(nSCBattleTeamIDBattleStart, nSCBattleTeamIDBattleEnd + 1):
		var j: int = mnVSResultsGetTeamFirstPlayer(i)

		if j != 0:
			results.append({"score": mnVSResultsGetTeamTotalPoints(i), "place": G.gSCManagerVSBattleState.players[j - 1].place, "player": i})
			players += 1
	mnVSResultsOrderResults(results, players)

	if players == 0:
		return
	var place := 0
	var score: int = results[0].score
	var winner: int = results[0].place
	for i in range(players):
		if (score != results[i].score) or (B(G.gSCManagerSceneData.is_suddendeath) and (winner != results[i].place)):
			place += 1
			score = results[i].score
			winner = results[i].place
		mnVSResultsSetTeamPlace(results[i].player, place)

## 0x801372F4
static func mnVSResultsSetPlaceTime() -> void:
	if sMNVSResultsIsTeamBattle == FALSE:
		mnVSResultsSetRoyalPlace()
	else:
		mnVSResultsSetTeamPlaceAll()

## 0x80137334
static func mnVSResultsSetPlaceStock() -> void:
	for i in 4:
		if sMNVSResultsIsPresent[i] != FALSE:
			sMNVSResultsPlaces[i] = G.gSCManagerTransferBattleState.players[i].place

## 0x801373B4
static func mnVSResultsInitRankings() -> void:
	mnVSResultsSetKOs()
	mnVSResultsSetTKO()
	mnVSResultsSetPoints()

	if G.gSCManagerTransferBattleState.game_rules == SCBATTLE_GAMERULE_STOCK:
		mnVSResultsSetPlaceStock()
	else:
		mnVSResultsSetPlaceTime()
	if sMNVSResultsKind == nMNVSResultsKindNoContest:
		for i in 4:
			sMNVSResultsPlaces[i] = 0
	mnVSResultsSetFighterKindAll()

## 0x80137454
static func mnVSResultsSetIsPresent() -> void:
	for i in 4:
		sMNVSResultsIsPresent[i] = FALSE if (G.gSCManagerTransferBattleState.players[i].pkind == nFTPlayerKindNot) else TRUE

## 0x80137698
static func mnVSResultsInitVars() -> void:
	sMNVSResultsIsTeamBattle = int(G.gSCManagerTransferBattleState.is_team_battle)

	for i in 4:
		sMNVSResultsIsSharedWinner[i] = FALSE
	if G.gSCManagerTransferBattleState.game_rules == SCBATTLE_GAMERULE_TIME:
		sMNVSResultsKind = nMNVSResultsKindTimeRoyal if (sMNVSResultsIsTeamBattle == FALSE) else nMNVSResultsKindTimeTeam
		sMNVSResultsAllowExitWait = 410
	else:
		sMNVSResultsKind = nMNVSResultsKindStockRoyal if (sMNVSResultsIsTeamBattle == FALSE) else nMNVSResultsKindStockTeam
		sMNVSResultsAllowExitWait = 370
	if G.gSCManagerSceneData.is_reset != FALSE:
		sMNVSResultsKind = nMNVSResultsKindNoContest
		sMNVSResultsAllowExitWait = 200

		sMNVSResultsDrawWallpaperTic = 1
		sMNVSResultsMakeResultsTic = 1
		sMNVSResultsInitFightersAllTic = 1
	else:
		sMNVSResultsDrawWallpaperTic = 80
		sMNVSResultsMakeResultsTic = 120
		sMNVSResultsInitFightersAllTic = 120

## 0x801379C4
static func mnVSResultsGetManCount() -> int:
	var total := 0
	for i in 4:
		if G.gSCManagerTransferBattleState.players[i].pkind == nFTPlayerKindMan:
			total += 1
	return total

static func _port_is_human() -> Array:
	var is_human: Array = []
	for i in 4:
		is_human.append(TRUE if (G.gSCManagerTransferBattleState.players[i].pkind == nFTPlayerKindMan) else FALSE)
	return is_human

## 0x80137A1C
static func mnVSResultsGetBestMan() -> int:
	var is_human := _port_is_human()
	var first_man := 0
	var tie_exists := FALSE

	for i in 4:
		if is_human[i] != FALSE:
			first_man = i
			break
	for i in range(first_man, 4):
		if is_human[i] != FALSE:
			if sMNVSResultsPoints[first_man] == sMNVSResultsPoints[i]:
				tie_exists = TRUE
			if sMNVSResultsPoints[first_man] < sMNVSResultsPoints[i]:
				first_man = i
	if tie_exists != FALSE:
		for i in range(first_man, 4):
			if (is_human[i] != FALSE) and (sMNVSResultsPoints[first_man] == sMNVSResultsPoints[i]) and (G.gSCManagerTransferBattleState.players[first_man].handicap < G.gSCManagerTransferBattleState.players[i].handicap):
				first_man = i
	return first_man

## 0x80137E34 (first_man is read uninitialised in C; the stack slot is 0 in practice -> 0 here)
static func mnVSResultsGetBestManExcept(player: int) -> int:
	var is_human := _port_is_human()
	var first_man := 0
	var found: int

	for i in range(first_man, 4):
		if (is_human[i] != FALSE) and (player != i) and (sMNVSResultsPoints[player] == sMNVSResultsPoints[i]):
			return i
	found = 666

	for i in 4:
		if (is_human[i] != FALSE) and (player != i):
			found = i
	if found == 666:
		return 666
	for i in 4:
		if (is_human[i] != FALSE) and (player != i) and (found != i) and (sMNVSResultsPoints[found] < sMNVSResultsPoints[i]):
			found = i
	return found

## 0x80138130
static func mnVSResultsGetWorstMan() -> int:
	var is_human := _port_is_human()
	var first_man := 0
	var tie_exists := FALSE

	for i in 4:
		if is_human[i] != FALSE:
			first_man = i
			break
	for i in range(first_man, 4):
		if is_human[i] != FALSE:
			if sMNVSResultsPoints[first_man] == sMNVSResultsPoints[i]:
				tie_exists = TRUE
			if sMNVSResultsPoints[first_man] > sMNVSResultsPoints[i]:
				first_man = i
	if tie_exists != FALSE:
		for i in range(first_man, 4):
			if (is_human[i] != FALSE) and (sMNVSResultsPoints[first_man] == sMNVSResultsPoints[i]) and (G.gSCManagerTransferBattleState.players[first_man].handicap > G.gSCManagerTransferBattleState.players[i].handicap):
				first_man = i
	return first_man

## 0x80138548
static func mnVSResultsSetAutoHandicaps(best: int, worst: int) -> void:
	var ts = G.gSCManagerTransferBattleState
	var handicap_best: int = ts.players[best].handicap
	var handicap_worst: int = ts.players[worst].handicap
	var other: int

	if (handicap_best == 1) and (handicap_worst == 9):
		return
	elif (handicap_best > 1) and (handicap_worst < 9):
		ts.players[best].handicap -= 1
		ts.players[worst].handicap += 1
	elif (handicap_best == 1) and (handicap_worst < 8):
		ts.players[worst].handicap += 2
	elif (handicap_best > 2) and (handicap_worst == 9):
		ts.players[best].handicap -= 2
	elif (handicap_best == 1) and (handicap_worst == 8):
		other = mnVSResultsGetBestManExcept(best)

		if other != 666:
			ts.players[other].handicap -= 1
			ts.players[worst].handicap += 1
	elif (handicap_best == 2) and (handicap_worst == 9):
		other = mnVSResultsGetBestManExcept(best)

		if other != 666:
			ts.players[best].handicap -= 1
			ts.players[other].handicap -= 1

## 0x801386BC
static func mnVSResultsUpdateAutoHandicap() -> void:
	if (sMNVSResultsKind != nMNVSResultsKindNoContest) and (mnVSResultsGetManCount() >= 2):
		mnVSResultsSetAutoHandicaps(mnVSResultsGetBestMan(), mnVSResultsGetWorstMan())

## 0x80138714
static func mnVSResultsGetWinBGM(fkind: int) -> int:
	match fkind:
		nFTKindMario, nFTKindLuigi:
			return nSYAudioBGMWinMario
		nFTKindFox:
			return nSYAudioBGMWinFox
		nFTKindDonkey:
			return nSYAudioBGMWinDonkey
		nFTKindSamus:
			return nSYAudioBGMWinMetroid
		nFTKindLink:
			return nSYAudioBGMWinZelda
		nFTKindYoshi:
			return nSYAudioBGMWinYoshi
		nFTKindCaptain:
			return nSYAudioBGMWinFZero
		nFTKindPikachu, nFTKindPurin:
			return nSYAudioBGMWinPMonsters
		nFTKindKirby:
			return nSYAudioBGMWinKirby
		nFTKindNess:
			return nSYAudioBGMWinMother
	return nSYAudioBGMWinDefault

## mnVSResultsAnnounceWinner (0x80131EB0) as a schedule [{tic, sfx_id}] of the results screen.
static func _port_announce_schedule(win_player: int) -> Array:
	var announce_names: Array = [nSYAudioVoiceAnnounceMario, nSYAudioVoiceAnnounceFox, nSYAudioVoiceAnnounceDonkey, nSYAudioVoiceAnnounceSamus,
		nSYAudioVoiceAnnounceLuigi, nSYAudioVoiceAnnounceLink, nSYAudioVoiceAnnounceYoshi, nSYAudioVoiceAnnounceCaptain,
		nSYAudioVoiceAnnounceKirby, nSYAudioVoiceAnnouncePikachu, nSYAudioVoiceAnnouncePurin, nSYAudioVoiceAnnounceNess]
	var announcer_teams: Array = [nSYAudioVoiceAnnounceRedTeam, nSYAudioVoiceAnnounceBlueTeam, nSYAudioVoiceAnnounceGreenTeam]

	if sMNVSResultsKind == nMNVSResultsKindNoContest:
		return [{"tic": 2, "sfx_id": nSYAudioVoiceAnnounceNoContest}, {"tic": 71, "sfx_id": nSYAudioVoicePublicNoContest}]
	elif sMNVSResultsIsTeamBattle == FALSE:
		var fkind: int = mnVSResultsGetFighterKind(win_player) if win_player >= 0 else 0
		return [{"tic": 81, "sfx_id": nSYAudioVoiceAnnounceWinnerIs},
			{"tic": 210, "sfx_id": announce_names[fkind] if (fkind >= 0) and (fkind < announce_names.size()) else nSYAudioVoiceAnnounceWinnerIs},
			{"tic": 270, "sfx_id": nSYAudioVoicePublicExcited}]
	var team: int = G.gSCManagerTransferBattleState.players[win_player].team if win_player >= 0 else 0
	return [{"tic": 81, "sfx_id": announcer_teams[team] if (team >= 0) and (team < 3) else nSYAudioVoiceAnnounceRedTeam},
		{"tic": 130, "sfx_id": nSYAudioVoiceAnnounceWins}, {"tic": 150, "sfx_id": nSYAudioVoicePublicExcited}]

## The computations of mnVSResultsFuncStart / mnVSResultsInitFightersAll for the results screen
## (in C order, incl. their RNG calls: transition pick and the winners' win poses).
static func port_compute_results() -> void:
	var ts = G.gSCManagerTransferBattleState
	var transition_id := -1
	var win_player := -1
	var statuses: Array = [-1, -1, -1, -1]
	var players: Array = []

	mnVSResultsSaveBackup()
	mnVSResultsInitVars()
	mnVSResultsSetIsPresent()
	mnVSResultsInitRankings()

	if ts.handicap == nSCBattleHandicapAuto:
		mnVSResultsUpdateAutoHandicap()
	if sMNVSResultsKind != nMNVSResultsKindNoContest:
		transition_id = syUtilsRandIntRange(_PORT_TRANSITIONS_NUM)
		win_player = mnVSResultsGetWinPlayer()
	for i in 4:                                     # mnVSResultsInitFightersAll (player order)
		if sMNVSResultsIsPresent[i] != FALSE:
			statuses[i] = mnVSResultsSetFighterStatus(i)
	for i in 4:
		var p = ts.players[i]
		var present: bool = sMNVSResultsIsPresent[i] != FALSE
		players.append({
			"present": present, "pkind": p.pkind, "fkind": p.fkind, "costume": p.costume, "color": p.color, "team": p.team,
			"place": sMNVSResultsPlaces[i], "display_place": mnVSResultsGetDisplayPlace(i) if present else 0,
			"kos": mnVSResultsGetKOs(i), "tko": mnVSResultsGetTKO(i), "points": mnVSResultsGetPoints(i),
			"is_shared_winner": sMNVSResultsIsSharedWinner[i] != FALSE,
			"falls": p.falls, "score": p.score, "total_kos_players": p.total_kos_players.duplicate(),
			"total_selfdestructs": p.total_selfdestructs, "total_damage_given": p.total_damage_given,
			"total_damage_all": p.total_damage_all, "handicap": p.handicap,
			"status_id": statuses[i], "spot": mnVSResultsGetSpot(i) if present else -1,
			"stage_pos": mnVSResultsSetFighterPosition(i, mnVSResultsGetSpot(i)) if present else Vector3.ZERO,
		})
	port_results = {
		"kind": sMNVSResultsKind,
		"kind_name": ["time_royal", "stock_royal", "time_team", "stock_team", "no_contest"][sMNVSResultsKind],
		"is_team_battle": sMNVSResultsIsTeamBattle != FALSE,
		"is_no_contest": sMNVSResultsKind == nMNVSResultsKindNoContest,
		"is_suddendeath": B(G.gSCManagerSceneData.is_suddendeath),
		"win_player": win_player,
		"win_team": ts.players[win_player].team if win_player >= 0 else -1,
		"win_fkind": mnVSResultsGetFighterKind(win_player) if win_player >= 0 else -1,
		"win_bgm": mnVSResultsGetWinBGM(mnVSResultsGetFighterKind(win_player)) if win_player >= 0 else -1,
		"players": players,
		"allow_exit_wait": sMNVSResultsAllowExitWait,
		"draw_wallpaper_tic": sMNVSResultsDrawWallpaperTic,
		"make_results_tic": sMNVSResultsMakeResultsTic,
		"init_fighters_tic": sMNVSResultsInitFightersAllTic,
		"announce": _port_announce_schedule(win_player),
		"transition_id": transition_id,
		"time_passed": ts.time_passed,
	}

## mnVSResultsFuncRun exit (START after allow_exit_wait): unlock messages and the next scene.
static func port_results_exit() -> Dictionary:
	var bk = G.gSCManagerBackupData
	var unlocks_num := 0
	var unlocks: Array = []

	if not (bk.unlock_mask & LBBACKUP_UNLOCK_MASK_ITEMSWITCH) and (bk.vs_itemswitch_battles >= 100):
		G.gSCManagerSceneData.unlock_messages[unlocks_num] = nLBBackupUnlockItemSwitch
		unlocks.append(nLBBackupUnlockItemSwitch)
		unlocks_num = 1
	if not (bk.unlock_mask & LBBACKUP_UNLOCK_MASK_INISHIE):
		if (bk.ground_mask & LBBACKUP_GROUND_MASK_ALL) == LBBACKUP_GROUND_MASK_ALL:
			var spgame_complete_mask := 0
			for i in range(nFTKindPlayableStart, nFTKindPlayableEnd + 1):
				if B(bk.spgame_records[i].is_spgame_complete):
					spgame_complete_mask |= (1 << i)
			if (spgame_complete_mask & LBBACKUP_CHARACTER_MASK_STARTER) == LBBACKUP_CHARACTER_MASK_STARTER:
				G.gSCManagerSceneData.unlock_messages[unlocks_num] = nLBBackupUnlockInishie
				unlocks.append(nLBBackupUnlockInishie)
				unlocks_num += 1
	G.gSCManagerSceneData.scene_prev = G.gSCManagerSceneData.scene_curr
	G.gSCManagerSceneData.scene_curr = nSCKindMessage if (unlocks_num != 0) else nSCKindPlayersVS
	Snd.func_800266A0_272A0()
	Audio.syAudioStopBGMAll()
	return {"next_scene": G.gSCManagerSceneData.scene_curr, "unlocks": unlocks}

## mnPlayersVSSetSceneData (src/mn/mnplayers/mnplayersvs.c 0x8013A664) + VS options, for the Godot menus.
## cfg = {time_limit (minutes, 100 = inf), stocks (lives - 1), is_team_battle, game_rules,
##        handicap, is_team_attack, damage_ratio, item_toggles, item_appearance_rate, gkind,
##        slots: [{fkind, pkind, costume, shade, team, cpu_level, handicap} x4]}
## Returns the state, which also becomes G.gSCManagerTransferBattleState / G.gSCManagerBattleState.
static func port_make_vs_battle_state(cfg: Dictionary):
	var ts = G.gSCManagerTransferBattleState

	for key in ["handicap", "is_team_attack", "is_stage_select", "damage_ratio", "item_toggles", "item_appearance_rate", "is_show_score"]:
		if cfg.has(key):
			ts.set(key, cfg[key])
	ts.time_limit = cfg.get("time_limit", ts.time_limit)
	ts.stocks = cfg.get("stocks", ts.stocks)
	ts.is_team_battle = cfg.get("is_team_battle", ts.is_team_battle)
	ts.game_rules = cfg.get("game_rules", ts.game_rules)

	for i in range(ts.players.size()):
		var slot: Dictionary = cfg.slots[i]

		if int(ts.is_team_battle) == FALSE:
			ts.players[i].player = i
		else:
			ts.players[i].player = slot.get("team", 0)
			ts.players[i].team = slot.get("team", 0)
		ts.players[i].fkind = slot.get("fkind", nFTKindMario)
		ts.players[i].pkind = slot.get("pkind", nFTPlayerKindNot)
		ts.players[i].costume = slot.get("costume", 0)
		ts.players[i].shade = slot.get("shade", 0)

		if ts.players[i].pkind == nFTPlayerKindMan:
			ts.players[i].color = i if (int(ts.is_team_battle) == FALSE) else Ifcommon.dIFCommonPlayerTeamColorIDs[ts.players[i].team]
		elif int(ts.is_team_battle) == FALSE:
			ts.players[i].color = GMCOMMON_PLAYERS_MAX
		else:
			ts.players[i].color = Ifcommon.dIFCommonPlayerTeamColorIDs[ts.players[i].team]

		ts.players[i].tag = i if (ts.players[i].pkind == nFTPlayerKindMan) else GMCOMMON_PLAYERS_MAX

		ts.players[i].is_single_stockicon = TRUE if (ts.game_rules & SCBATTLE_GAMERULE_TIME) else FALSE

		if ts.players[i].pkind == nFTPlayerKindCom:
			ts.players[i].level = slot.get("cpu_level", 3)
		else:
			ts.players[i].handicap = slot.get("handicap", 9)
	ts.pl_count = 0
	ts.cp_count = 0

	for i in range(ts.players.size()):
		if ts.players[i].pkind == nFTPlayerKindMan:
			ts.pl_count += 1
		elif ts.players[i].pkind == nFTPlayerKindCom:
			ts.cp_count += 1
	if cfg.has("gkind"):
		G.gSCManagerSceneData.gkind = cfg.gkind
	G.gSCManagerBattleState = ts
	return ts
