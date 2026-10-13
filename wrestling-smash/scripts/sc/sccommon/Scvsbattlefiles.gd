## 1:1 port of src/sc/sccommon/scvsbattlefiles.c: reloc file setup of the VS battle scene.
## The ROM file system is replaced by the JSON data (SSBData); the Lbreloc calls are kept (stubs) and
## the interface sprite "files" (Ifcommon sprite templates) are reloaded like the C reloads them.
class_name Scvsbattlefiles
extends Port

## 0x8018E480 / 0x8018E7A0 (LBFileNode buffers)
static var sSCVSBattleStatusBuffer: Array = []
static var sSCVSBattleForceStatusBuffer: Array = []

## gmcommon.c dGMCommonFileIDs (IFCommonPlayer, GameStatus, PlayerDamage, Timer, Digits, BattlePause,
## PlayerTags, AnnounceCommon) / gGMCommonFiles
const dGMCommonFileIDs: Array = ["llIFCommonPlayerFileID", "llIFCommonGameStatusFileID", "llIFCommonPlayerDamageFileID",
	"llIFCommonTimerFileID", "llIFCommonDigitsFileID", "llIFCommonBattlePauseFileID", "llIFCommonPlayerTagsFileID",
	"llIFCommonAnnounceCommonFileID"]
static var gGMCommonFiles: Array = [null, null, null, null, null, null, null, null]

## 0x8018E330
static func scVSBattleSetupFiles() -> void:
	var rl_setup := {
		"table_addr": "lLBRelocTableAddr",
		"table_files_num": "llRelocFileCount",
		"file_heap": null,
		"file_heap_size": 0,
		"status_buffer": sSCVSBattleStatusBuffer,
		"status_buffer_size": 100,
		"force_status_buffer": sSCVSBattleForceStatusBuffer,
		"force_status_buffer_size": 7,
	}
	Lbreloc.lbRelocInitSetup(rl_setup)
	# lbRelocLoadFilesListed(dGMCommonFileIDs, gGMCommonFiles)
	Lbreloc.lbRelocLoadFilesExtern(dGMCommonFileIDs, dGMCommonFileIDs.size(), gGMCommonFiles, null)
	Ifcommon.port_reload_sprite_files()
