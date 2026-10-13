## Drives one VS battle of the ported SSB64 engine at a fixed 60 Hz:
##   InputMapper (Godot input -> raw N64 pads) -> Controller (port of sys/controller.c)
##   -> Scvsbattle.port_update_frame() (= scVSBattleFuncUpdate -> ifCommonBattleUpdateInterfaceAll -> gcRunAll)
## The runner owns no gameplay logic: everything that moves is the ported C code.
class_name BattleRunner
extends RefCounted

## Battle configuration from the menus:
## {gkind, stocks, time_limit (minutes, 0 = infinite / SCBATTLE_TIMELIMIT_INFINITE), is_stock (bool),
##  items_on (bool), item_rate, is_team_battle, damage_ratio, handicap,
##  players: [ {pkind, fkind, level, handicap, costume, team, device} x4 ]}
var config: Dictionary = {}
var frame: int = 0
var started: bool = false
var paused_by_debug: bool = false

static func default_config() -> Dictionary:
	return {
		"gkind": SSBDefs.nGRKindCastle,
		"is_stock": true,
		"stocks": 3,
		"time_limit": 2,
		"items_on": true,
		"item_rate": 2,
		"is_team_battle": false,
		"damage_ratio": 100,
		"players": [
			{"pkind": SSBDefs.nFTPlayerKindMan, "fkind": SSBDefs.nFTKindMario, "level": 3, "handicap": 9, "costume": 0, "team": 0},
			{"pkind": SSBDefs.nFTPlayerKindCom, "fkind": SSBDefs.nFTKindDonkey, "level": 3, "handicap": 9, "costume": 0, "team": 1},
			{"pkind": SSBDefs.nFTPlayerKindNot, "fkind": SSBDefs.nFTKindFox, "level": 3, "handicap": 9, "costume": 0, "team": 2},
			{"pkind": SSBDefs.nFTPlayerKindNot, "fkind": SSBDefs.nFTKindSamus, "level": 3, "handicap": 9, "costume": 0, "team": 3},
		],
	}

## Fill the battle state exactly like the VS menus do (ported mnPlayersVSSetSceneData + options:
## Scvsbattle.port_make_vs_battle_state).
func apply_config_to_battle_state() -> void:
	var is_stock: bool = config.get("is_stock", true)
	var slots := []
	for i in 4:
		var p: Dictionary = config.players[i]
		slots.append({
			"fkind": p.fkind, "pkind": p.pkind, "costume": p.get("costume", 0), "shade": p.get("shade", 0),
			"team": p.get("team", 0), "cpu_level": p.get("level", 3), "handicap": p.get("handicap", 9),
		})
	var items_on: bool = config.get("items_on", true)
	var cfg := {
		"gkind": config.gkind,
		"game_rules": SSBDefs.SCBATTLE_GAMERULE_STOCK if is_stock else SSBDefs.SCBATTLE_GAMERULE_TIME,
		"time_limit": SSBDefs.SCBATTLE_TIMELIMIT_INFINITE if is_stock else int(config.get("time_limit", 2)),
		"stocks": maxi(int(config.get("stocks", 3)) - 1, 0),
		"is_team_battle": 1 if config.get("is_team_battle", false) else 0,
		"handicap": SSBDefs.nSCBattleHandicapOff,
		"is_team_attack": 0,
		"is_stage_select": 1,
		"damage_ratio": int(config.get("damage_ratio", 100)),
		"item_toggles": 0xFFFFFFFF if items_on else 0,
		"item_appearance_rate": int(config.get("item_rate", SSBDefs.nSCBattleItemSwitchMiddle)) if items_on else SSBDefs.nSCBattleItemSwitchNone,
		"is_show_score": 1,
		"slots": slots,
	}
	Scvsbattle.port_make_vs_battle_state(cfg)

## Per-battle reload of module data that the N64 re-reads with each overlay load.
static func reset_overlay_data() -> void:
	Itstarrod._itStarRodReloadOverlayData()

func start(cfg: Dictionary) -> void:
	config = cfg
	apply_config_to_battle_state()
	reset_overlay_data()
	Controller.syControllerInitDevices()
	Scvsbattle.port_start_battle()
	started = true
	frame = 0

func is_finished() -> bool:
	return Scvsbattle.port_phase == Scvsbattle.PORT_PHASE_FINISHED

func results() -> Dictionary:
	return Scvsbattle.port_results

## One 60 Hz game frame.
func step() -> void:
	if not started:
		return
	InputMapper.poll()
	Controller.port_poll_frame()
	Scvsbattle.port_update_frame()
	Snd.port_tick()
	frame += 1
