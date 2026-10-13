## Scene-level globals of the original game that gameplay code reads (src/sc/scmanager.c,
## src/sys/objman.c, ...). Names are the original C identifiers.
## gGCCommonLinks[link] linked lists are replaced by Sim.get_link(link) arrays.
class_name G
extends RefCounted

class SCPlayerStale:
	var attack_id: int = 0
	var motion_count: int = 0

class SCPlayerData:
	var level: int = 0
	var handicap: int = 9
	var pkind: int = SSBDefs.nFTPlayerKindNot
	var fkind: int = 0
	var team: int = 0
	var player: int = 0
	var costume: int = 0
	var shade: int = 0
	var color: int = 0
	var is_single_stockicon: int = 0
	var tag: int = 0
	var stock_count: int = 0
	var is_spgame_enemy: int = 0
	var place: int = 0
	var falls: int = 0
	var score: int = 0
	var total_kos_players: Array = [0, 0, 0, 0]
	var unk_pblock_0x28: int = 0
	var unk_pblock_0x2C: int = 0
	var total_selfdestructs: int = 0
	var total_damage_given: int = 0
	var total_damage_all: int = 0
	var total_damage_players: Array = [0, 0, 0, 0]
	var stock_damage_all: int = 0
	var combo_damage_foe: int = 0
	var combo_count_foe: int = 0
	var fighter_gobj = null
	var stale_id: int = 0
	var stale_info: Array = []
	func _init() -> void:
		for i in 5:
			stale_info.append(SCPlayerStale.new())
	## C struct copy (SCPlayerData a = b;) - added for scVSBattleSetScoreCheckSuddenDeath.
	func copy_from(o) -> void:
		for p in ["level", "handicap", "pkind", "fkind", "team", "player", "costume", "shade", "color",
				"is_single_stockicon", "tag", "stock_count", "is_spgame_enemy", "place", "falls", "score",
				"unk_pblock_0x28", "unk_pblock_0x2C", "total_selfdestructs", "total_damage_given",
				"total_damage_all", "stock_damage_all", "combo_damage_foe", "combo_count_foe", "fighter_gobj", "stale_id"]:
			set(p, o.get(p))
		total_kos_players = o.total_kos_players.duplicate()
		total_damage_players = o.total_damage_players.duplicate()
		for i in stale_info.size():
			stale_info[i].attack_id = o.stale_info[i].attack_id
			stale_info[i].motion_count = o.stale_info[i].motion_count

class SCBattleState:
	var game_type: int = SSBDefs.nSCBattleGameTypeRoyal
	var gkind: int = 0
	var is_team_battle: int = 0
	var game_rules: int = 0
	var pl_count: int = 0
	var cp_count: int = 0
	var time_limit: int = 0
	var stocks: int = 0
	var handicap: int = 0
	var is_team_attack: int = 0
	var is_stage_select: int = 0
	var damage_ratio: int = 100
	var item_toggles: int = 0
	var is_reset_players: int = 0
	var game_status: int = 0
	var time_remain: int = 0
	var time_passed: int = 0
	var item_appearance_rate: int = 0
	var is_show_score: int = 0
	var is_not_teamshadows: int = 0
	var players: Array = []
	func _init() -> void:
		for i in 4:
			players.append(SCPlayerData.new())
	## C struct copy (SCBattleState a = b;) - added for scVSBattleSetScoreCheckSuddenDeath.
	func copy_from(o) -> void:
		for p in ["game_type", "gkind", "is_team_battle", "game_rules", "pl_count", "cp_count", "time_limit",
				"stocks", "handicap", "is_team_attack", "is_stage_select", "damage_ratio", "item_toggles",
				"is_reset_players", "game_status", "time_remain", "time_passed", "item_appearance_rate",
				"is_show_score", "is_not_teamshadows"]:
			set(p, o.get(p))
		for i in players.size():
			players[i].copy_from(o.players[i])

class SCCommonData:
	var scene_curr: int = 0
	var scene_prev: int = 0
	var gkind: int = 0
	var is_suddendeath: int = 0
	var player: int = 0
	var fkind: int = 0
	var spgame_stage: int = 0
	# added (src/sc/sctypes.h SCCommonData, defaults of dSCManagerDefaultSceneData)
	var unlock_messages: Array = [7, 7, 7, 7, 7, 7, 7]   # nLBBackupUnlockEnumCount
	var is_continue: int = 0
	var is_reset: int = 0                                # A + B + R + Z done in the pause menu
	var maps_vsmode_gkind: int = 0                       # nGRKindCastle

## LBBackupVSRecord (src/lb/lbtypes.h)
class LBBackupVSRecord:
	var ko_count: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	var time_used: int = 0
	var damage_given: int = 0
	var damage_taken: int = 0
	var unk: int = 0
	var selfdestructs: int = 0
	var games_played: int = 0
	var player_count_tally: int = 0
	var player_count_tallies: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	var played_against: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

class LBBackupData:
	var error_flags: int = 0
	# added (src/lb/lbtypes.h LBBackupData, defaults of dSCManagerDefaultBackupData)
	var vs_records: Array = []
	var is_allow_screenflash: int = 1
	var unlock_mask: int = SSBDefs.LBBACKUP_UNLOCK_MASK_ALL   # fully unlocked save: all 12 fighters, Mushroom Kingdom, item switch
	var fighter_mask: int = 0xFFF
	var spgame_records: Array = []        # [{is_spgame_complete}] (only the field VS results read)
	var ground_mask: int = 0
	var vs_itemswitch_battles: int = 0
	var vs_total_battles: int = 0
	var boot: int = 0
	func _init() -> void:
		for i in 12:
			vs_records.append(LBBackupVSRecord.new())
			spgame_records.append({"is_spgame_complete": 0})

static var gSCManagerBattleState: SCBattleState = SCBattleState.new()
## scmanager.c battle states (gSCManagerBattleState points at one of them in C).
static var gSCManagerTransferBattleState: SCBattleState = gSCManagerBattleState
static var gSCManagerVSBattleState: SCBattleState = SCBattleState.new()
static var gSCManager1PGameBattleState: SCBattleState = SCBattleState.new()
static var gSCManagerSceneData: SCCommonData = SCCommonData.new()
static var gSCManagerBackupData: LBBackupData = LBBackupData.new()

# 1P-game bonus counters (VS mode never reads them; kept so ported code can write them)
static var gSC1PGameBonusGiantImpact: int = 0
static var gSC1PGameBonusTomatoCount: int = 0
static var gSC1PGameBonusStarCount: int = 0
static var gSC1PGameBonusHeartCount: int = 0
static var gSC1PGameBonusShieldBreaker: int = 0
static var gSC1PGameBonusMewCatcher: int = 0
static var gSC1PGameBonusAttackIDCount: Array = []
static var gSC1PGameBonusAttackIsSmashCount: Array = [0, 0]
static var gSC1PGameBonusAttackGroundAirCount: Array = [0, 0]
static var gSC1PGameBonusAttackIsProjectileCount: Array = [0, 0]
static var gSC1PGameBonusDefendIDCount: Array = []
static var gSC1PGameBonusDefendIsSmashCount: Array = [0, 0]
static var gSC1PGameBonusDefendGroundAirCount: Array = [0, 0]
static var gSC1PGameBonusDefendIsProjectileCount: Array = [0, 0]

static func reset_battle(state: SCBattleState) -> void:
	gSCManagerBattleState = state
	gSC1PGameBonusAttackIDCount.resize(1024)
	gSC1PGameBonusAttackIDCount.fill(0)
	gSC1PGameBonusDefendIDCount.resize(1024)
	gSC1PGameBonusDefendIDCount.fill(0)
