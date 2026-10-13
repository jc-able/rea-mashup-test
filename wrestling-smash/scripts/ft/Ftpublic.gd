## 1:1 port of src/ft/ftpublic.c (ssb-decomp-re): audience ("public") reactions, fighter name chants
## and the queued "<player> defeated" announcer voices. Sound only (no gameplay state), but kept exact.
## Sound handles are Snd.SndHandle (sfx_id); the C detects a finished sound by its handle's sfx_id
## changing / becoming 0 - the audio layer must clear handle.sfx_id when a sound stops.
class_name Ftpublic
extends Port

# // // // // // // // // // // // //
# //   GLOBAL / STATIC VARIABLES   //
# // // // // // // // // // // // //

static var sFTPublicCommonTicsPast: int = 0              # 0x8018CF90
static var sFTPublicCommonPlayerNum: int = 0             # 0x8018CF94
static var sFTPublicCommonKnockback: float = 0.0         # 0x8018CF98
static var sFTPublicCommonALSound = null                 # 0x8018CF9C
static var sFTPublicCommonOrder: int = 0                 # 0x8018CFA0 u16
static var sFTPublicCallIsInterrupt: int = 0             # 0x8018CFA4
static var sFTPublicCallWait: int = 0                    # 0x8018CFA8
static var sFTPublicCallPlayerNum: int = 0               # 0x8018CFAC
static var sFTPublicCallALSound = null                   # 0x8018CFB0
static var sFTPublicCallOrder: int = 0                   # 0x8018CFB4 u16
static var sFTPublicCallCount: int = 0                   # 0x8018CFB8
static var sFTPublicCallID: int = 0                      # 0x8018CFBC
static var sFTPublicPlayersDown: int = 0                 # 0x8018CFC0
static var sFTPublicDefeatedVoiceIDs: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]   # 0x8018CFC8 u16[10]
static var sFTPublicDefeatedQueueCurrent: int = 0        # 0x8018CFDC
static var sFTPublicDefeatedQueueEnd: int = 0            # 0x8018CFE0
static var sFTPublicDefeatedALSound = null               # 0x8018CFE4
static var sFTPublicDefeatedCurrentOrder: int = 0        # 0x8018CFE8 u16

## port-only: overlay BSS clear at VS battle scene start.
static func port_reset_bss() -> void:
	sFTPublicCommonTicsPast = 0
	sFTPublicCommonPlayerNum = 0
	sFTPublicCommonKnockback = 0.0
	sFTPublicCommonALSound = null
	sFTPublicCommonOrder = 0
	sFTPublicCallIsInterrupt = 0
	sFTPublicCallWait = 0
	sFTPublicCallPlayerNum = 0
	sFTPublicCallALSound = null
	sFTPublicCallOrder = 0
	sFTPublicCallCount = 0
	sFTPublicCallID = 0
	sFTPublicPlayersDown = 0
	sFTPublicDefeatedVoiceIDs = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	sFTPublicDefeatedQueueCurrent = 0
	sFTPublicDefeatedQueueEnd = 0
	sFTPublicDefeatedALSound = null
	sFTPublicDefeatedCurrentOrder = 0

static func _sfx_id(handle) -> int:
	return (handle.sfx_id & 0xFFFF) if handle != null else 0

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80164AB0
static func ftPublicTryStartCall(gobj, knockback: float, player_num: int) -> int:
	var fighter_gobj = Ftparam.ftParamGetPlayerNumGObj(player_num)
	var sfx_id: int

	if fighter_gobj == null:
		return FALSE
	elif (ftGetStruct(fighter_gobj).percent_damage < 100) or (sFTPublicCallWait < 1200):
		return FALSE
	elif player_num == sFTPublicCallPlayerNum:
		return FALSE
	else:
		sFTPublicCallID = Ftcommondata.dFTCommonDataPublicFighterCallFGMs[ftGetStruct(fighter_gobj).fkind]

	if sFTPublicCallID == nSYAudioFGMVoiceEnd:
		return FALSE
	if sFTPublicCallALSound != null:
		sfx_id = _sfx_id(sFTPublicCallALSound)

		if (sfx_id != 0) and (sfx_id == sFTPublicCallOrder):
			Snd.func_80026738_27338(sFTPublicCallALSound)
	sFTPublicCallALSound = Snd.func_800269C0_275C0(nSYAudioVoicePublicCheer if (knockback >= 160.0) else nSYAudioVoicePublicAmazed)

	if sFTPublicCallALSound != null:
		sFTPublicCallOrder = _sfx_id(sFTPublicCallALSound)
		sFTPublicCallPlayerNum = player_num
		sFTPublicCallCount = 0

		return TRUE
	return FALSE

## 0x80164C18
static func ftPublicTryInterruptCall() -> void:
	if (sFTPublicCallCount < 9) and (sFTPublicCallCount >= 3):
		sFTPublicCallIsInterrupt = TRUE

## 0x80164C44
static func ftPublicPlayCommon(new_sfx: int) -> void:
	if sFTPublicCommonALSound != null:
		var current_sfx: int = _sfx_id(sFTPublicCommonALSound)

		if (current_sfx != 0) and (current_sfx == sFTPublicCommonOrder):
			Snd.func_80026738_27338(sFTPublicCommonALSound)
	sFTPublicCommonALSound = Snd.func_800269C0_275C0(new_sfx)

	if sFTPublicCommonALSound != null:
		sFTPublicCommonOrder = _sfx_id(sFTPublicCommonALSound)

## 0x80164CBC
static func ftPublicCommonStop() -> void:
	if sFTPublicCommonALSound != null:
		var sfx_id: int = _sfx_id(sFTPublicCommonALSound)

		if (sfx_id != 0) and (sfx_id == sFTPublicCommonOrder):
			Snd.func_80026738_27338(sFTPublicCommonALSound)

## 0x80164D08
static func ftPublicDecideCall(gobj, player_num: int, knockback: float) -> void:
	if knockback >= 130.0:
		if ftPublicTryStartCall(gobj, knockback, player_num) != FALSE:
			ftPublicCommonStop()
			return
		elif knockback >= 160.0:
			ftPublicTryInterruptCall()
			ftPublicPlayCommon(nSYAudioVoicePublicCheer)
			return
		elif player_num == sFTPublicCallPlayerNum:
			ftPublicTryInterruptCall()
		ftPublicPlayCommon(nSYAudioVoicePublicAmazed)
	elif knockback >= 100.0:
		ftPublicPlayCommon(nSYAudioVoicePublicGaspClap)

## 0x80164DD4
static func ftPublicDecideCommon(fighter_gobj, player_num: int, knockback: float, is_force_curr_knockback) -> void:
	if B(is_force_curr_knockback):
		ftPublicDecideCall(fighter_gobj, player_num, knockback)
	elif (player_num == sFTPublicCommonPlayerNum) and (sFTPublicCommonTicsPast < 60):
		ftPublicDecideCall(fighter_gobj, player_num, knockback if (knockback > sFTPublicCommonKnockback) else sFTPublicCommonKnockback)
	elif knockback >= 160.0:
		ftPublicTryInterruptCall()
		ftPublicPlayCommon(nSYAudioVoicePublicDamageL)
	elif knockback >= 130.0:
		if player_num == sFTPublicCallPlayerNum:
			ftPublicTryInterruptCall()
		ftPublicPlayCommon(nSYAudioVoicePublicDamageM)
	elif knockback >= 100.0:
		ftPublicPlayCommon(nSYAudioVoicePublicDamageS)
	sFTPublicCommonTicsPast = 0
	sFTPublicCommonPlayerNum = player_num
	sFTPublicCommonKnockback = knockback

## 0x80164F2C
static func ftPublicCommonCheck(fighter_gobj, knockback: float, is_force_curr_knockback) -> void:
	var fp = ftGetStruct(fighter_gobj)

	if knockback >= 100.0:
		ftPublicDecideCommon(fighter_gobj, fp.damage_player_num, knockback, is_force_curr_knockback)

## 0x80164F70 - audience gasp when a fighter recovers to the ledge
static func ftPublicPlayCliffReact(fighter_gobj, knockback: float) -> void:
	var fp = ftGetStruct(fighter_gobj)

	if sFTPublicCallPlayerNum == fp.player_num:
		ftPublicTryInterruptCall()
	if knockback >= 160.0:
		ftPublicPlayCommon(nSYAudioVoicePublicGaspL)
	elif knockback >= 130.0:
		ftPublicPlayCommon(nSYAudioVoicePublicGaspM)
	elif knockback >= 100.0:
		ftPublicPlayCommon(nSYAudioVoicePublicGaspS)

## 0x80165024
static func ftPublicTryPlayFallSpecialReact(fighter_gobj) -> void:
	var fp = ftGetStruct(fighter_gobj)
	var pos_y: float = fp.joints[nFTPartsJointTopN].translate.y

	if (pos_y >= Mpcollision.gMPCollisionBounds.current.bottom) or (pos_y < -2400.0):
		return
	elif pos_y >= -300.0:
		ftPublicPlayCommon(nSYAudioVoicePublicGaspL)
	elif pos_y >= -900.0:
		ftPublicPlayCommon(nSYAudioVoicePublicGaspM)
	else:
		ftPublicPlayCommon(nSYAudioVoicePublicGaspS)

	if sFTPublicCallPlayerNum == fp.player_num:
		ftPublicTryInterruptCall()

## 0x801650F8
static func ftPublicDefeatedAddID(sfx_id) -> void:
	sFTPublicDefeatedVoiceIDs[sFTPublicDefeatedQueueEnd] = int(sfx_id) & 0xFFFF

	sFTPublicDefeatedQueueEnd += 1

	if sFTPublicDefeatedQueueEnd == sFTPublicDefeatedVoiceIDs.size():
		sFTPublicDefeatedQueueEnd = 0

## 0x80165134
static func ftPublicProcUpdate(public_gobj) -> void:
	var players_down_bak: int
	var down_gobj = null

	if sFTPublicCommonTicsPast < (U16_MAX + 1):
		sFTPublicCommonTicsPast += 1
	players_down_bak = sFTPublicPlayersDown
	sFTPublicPlayersDown = 0

	for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		var fp = ftGetStruct(fighter_gobj)

		if not (G.gSCManagerBattleState.game_rules & SCBATTLE_GAMERULE_STOCK) or (fp.stock_count != -1):
			if DObjGetStruct(fighter_gobj).translate.y < (Mpcollision.gMPCollisionBounds.current.bottom - 100.0):
				sFTPublicPlayersDown += 1
			else:
				down_gobj = fighter_gobj
	if (players_down_bak < 3) and (sFTPublicPlayersDown >= 3):
		ftPublicPlayCommon(nSYAudioVoicePublicGaspL)

		if (down_gobj != null) and (sFTPublicCallPlayerNum == ftGetStruct(down_gobj).player_num):
			ftPublicTryInterruptCall()
	if sFTPublicCallCount < 9:
		if (sFTPublicCallALSound == null) or (_sfx_id(sFTPublicCallALSound) == 0) or (_sfx_id(sFTPublicCallALSound) != sFTPublicCallOrder):
			sFTPublicCallCount += 1

			if sFTPublicCallCount < 9:
				if sFTPublicCallIsInterrupt != FALSE:
					sFTPublicCallIsInterrupt = FALSE
					sFTPublicCallWait = 0
					sFTPublicCallCount = 9
				else:
					sFTPublicCallALSound = Snd.func_800269C0_275C0(sFTPublicCallID)

					if sFTPublicCallALSound != null:
						sFTPublicCallOrder = _sfx_id(sFTPublicCallALSound)
			else:
				sFTPublicCallWait = 0

				ftPublicPlayCommon(nSYAudioVoicePublicCheer)
	elif sFTPublicCallWait < 1200:
		sFTPublicCallWait += 1
	if sFTPublicDefeatedQueueCurrent != sFTPublicDefeatedQueueEnd:
		if (sFTPublicDefeatedALSound == null) or (sFTPublicDefeatedCurrentOrder == 0) or (_sfx_id(sFTPublicDefeatedALSound) != sFTPublicDefeatedCurrentOrder):
			sFTPublicDefeatedALSound = Snd.func_800269C0_275C0(sFTPublicDefeatedVoiceIDs[sFTPublicDefeatedQueueCurrent])

			if sFTPublicDefeatedALSound != null:
				sFTPublicDefeatedCurrentOrder = _sfx_id(sFTPublicDefeatedALSound)
			else:
				sFTPublicDefeatedCurrentOrder = 0

			sFTPublicDefeatedQueueCurrent += 1

			if sFTPublicDefeatedQueueCurrent == sFTPublicDefeatedVoiceIDs.size():
				sFTPublicDefeatedQueueCurrent = 0

## 0x801653E0
static func ftPublicMakeActor() -> void:
	var gobj := GObj.new()            # gcMakeGObjSPAfter(nGCCommonKindPublic, NULL, 13, GOBJ_PRIORITY_DEFAULT)
	gobj.gobj_kind = nGCCommonKindPublic
	Sim.add_gobj(gobj, 13)
	Objman.gcAddGObjProcess(gobj, Callable(Ftpublic, &"ftPublicProcUpdate"), nGCProcessKindFunc, 0)

	sFTPublicCommonTicsPast = U16_MAX + 1
	sFTPublicCommonPlayerNum = -1
	sFTPublicCommonKnockback = 0.0
	sFTPublicCommonALSound = null
	sFTPublicCommonOrder = 0
	sFTPublicCallIsInterrupt = 0
	sFTPublicCallWait = 1200
	sFTPublicCallPlayerNum = -1
	sFTPublicCallCount = 9
	sFTPublicPlayersDown = 0
	sFTPublicDefeatedALSound = null
	sFTPublicDefeatedCurrentOrder = 0
	sFTPublicDefeatedQueueCurrent = 0
	sFTPublicDefeatedQueueEnd = 0
