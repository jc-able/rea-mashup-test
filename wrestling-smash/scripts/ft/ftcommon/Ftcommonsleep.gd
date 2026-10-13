## 1:1 port of src/ft/ftcommon/ftcommonsleep.c (ssb-decomp-re): out of stocks (Sleep), incl. the
## team-battle stock steal (START) and the pause-menu check.
class_name Ftcommonsleep
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8013D580
static func ftCommonSleepCheckIgnorePauseMenu(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var steal_from_player: Array = [0, 0, 0, 0] # s32 [GMCOMMON_PLAYERS_MAX]
	var active_teammate_count: int
	var player: int
	var stock_count: int

	if (G.gSCManagerBattleState.game_rules & SCBATTLE_GAMERULE_STOCK) and (int(G.gSCManagerBattleState.is_team_battle) == TRUE) and (fp.status_id == nFTCommonStatusSleep):
		if fp.status_vars.common.sleep.stock_steal_wait == 0:
			active_teammate_count = 0
			stock_count = 0
			player = 0

			while player < G.gSCManagerBattleState.players.size():
				# Note: compares fp->team against the slot's `player` field, exactly as the C does.
				if (player != fp.player) and (G.gSCManagerBattleState.players[player].pkind != nFTPlayerKindNot) and (fp.team == G.gSCManagerBattleState.players[player].player):
					if G.gSCManagerBattleState.players[player].stock_count > 0:
						if stock_count < G.gSCManagerBattleState.players[player].stock_count:
							active_teammate_count = 0
							stock_count = G.gSCManagerBattleState.players[player].stock_count
						steal_from_player[active_teammate_count] = player

						active_teammate_count += 1
				player += 1
			if active_teammate_count != 0:
				return TRUE # Do not bring up pause menu
	return FALSE # Bring up pause menu

## 0x8013D6D0
static func ftCommonSleepProcUpdate(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var steal_gobj
	var active_teammate_count: int
	var steal_from_player: Array = [0, 0, 0, 0] # s32 [GMCOMMON_PLAYERS_MAX]
	var player: int
	var random_steal_target: int
	var stock_count: int

	if (G.gSCManagerBattleState.game_rules & SCBATTLE_GAMERULE_STOCK) and (int(G.gSCManagerBattleState.is_team_battle) == TRUE):
		if this_fp.status_vars.common.sleep.stock_steal_wait != 0:
			this_fp.status_vars.common.sleep.stock_steal_wait -= 1

			if this_fp.status_vars.common.sleep.stock_steal_wait == 0:
				this_fp.stock_count = 0
				G.gSCManagerBattleState.players[this_fp.player].stock_count = 0

				Ftcommonrebirth.ftCommonRebirthDownSetStatus(fighter_gobj)
		else:
			if this_fp.input.pl.button_tap & START_BUTTON:
				active_teammate_count = 0
				stock_count = 0
				player = 0

				while player < G.gSCManagerBattleState.players.size():
					# Note: compares this_fp->team against the slot's `player` field, exactly as the C does.
					if (player != this_fp.player) and (G.gSCManagerBattleState.players[player].pkind != nFTPlayerKindNot) and (this_fp.team == G.gSCManagerBattleState.players[player].player):
						if G.gSCManagerBattleState.players[player].stock_count > 0:
							if stock_count < G.gSCManagerBattleState.players[player].stock_count:
								active_teammate_count = 0
								stock_count = G.gSCManagerBattleState.players[player].stock_count
							steal_from_player[active_teammate_count] = player
							active_teammate_count += 1
					player += 1
				if active_teammate_count != 0:
					random_steal_target = syUtilsRandIntRange(active_teammate_count)

					G.gSCManagerBattleState.players[steal_from_player[random_steal_target]].stock_count -= 1

					steal_gobj = G.gSCManagerBattleState.players[steal_from_player[random_steal_target]].fighter_gobj

					ftGetStruct(steal_gobj).stock_count -= 1

					this_fp.stock_count = -2

					G.gSCManagerBattleState.players[this_fp.player].stock_count = -2

					this_fp.status_vars.common.sleep.stock_steal_wait = FTCOMMON_SLEEP_STOCK_STEAL_WAIT

					Ifcommon.ifCommonPlayerStockStealMakeInterface(this_fp.player, steal_from_player[random_steal_target])

					Snd.func_800269C0_275C0(nSYAudioFGMStockSteal)

## 0x8013D8B0
static func ftCommonSleepSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusSleep, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.is_invisible = TRUE
	fp.is_shadow_hide = TRUE
	fp.is_ghost = TRUE
	fp.is_menu_ignore = TRUE

	fp.status_vars.common.sleep.stock_steal_wait = 0

	fp.camera_mode = nFTCameraModeGhost

	fp.is_playertag_hide = TRUE
