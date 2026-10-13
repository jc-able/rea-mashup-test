## 1:1 port of src/gr/grmainsetup.c, plus the port-side entry points the battle scene uses to build a
## stage by ground kind (see the bottom of the file).
class_name Grmainsetup
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8012E840
static var dGRMainSetupProcMakeList: Array = [
	Callable(Grcastle, &"grCastleMakeGround"),
	Callable(Grsector, &"grSectorMakeGround"),
	Callable(Grjungle, &"grJungleMakeGround"),
	Callable(Grzebes, &"grZebesMakeGround"),
	Callable(Grhyrule, &"grHyruleMakeGround"),
	Callable(Gryoster, &"grYosterMakeGround"),
	Callable(Grpupupu, &"grPupupuMakeGround"),
	Callable(Gryamabuki, &"grYamabukiMakeGround"),
	Callable(Grinishie, &"grInishieMakeGround"),
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801056C0
static func grMainSetupMakeGround() -> void:
	if G.gSCManagerBattleState.gkind <= nGRKindBattleEnd:
		dGRMainSetupProcMakeList[G.gSCManagerBattleState.gkind].call()
	elif G.gSCManagerBattleState.gkind == nGRKindBonus3:
		Grbonus3.grBonus3MakeGround()
	elif G.gSCManagerBattleState.gkind >= nGRKindBonus2Start:
		StubLog.hit("sc1PBonusStageInitBonus2")         # src/sc/sc1pmode/sc1pbonusstage.c (not ported)
	elif G.gSCManagerBattleState.gkind >= nGRKindBonus1Start:
		StubLog.hit("sc1PBonusStageMakeBonus1Ground")   # src/sc/sc1pmode/sc1pbonusstage.c (not ported)


# =====================================================================================================
#   Port entry points (not part of grmainsetup.c)
# =====================================================================================================
# The original scene (scVSBattleStartBattle, src/sc/sccommon/scvsbattle.c) builds the ground with
#     mpCollisionInitGroundData();        // Mpcollision
#     grWallpaperMakeDecideKind();        // Grwallpaper
#     itManagerInitItems();               // Itmanager
#     grCommonSetupInitAll();             // Grcommonsetup: geometry layers + grMainSetupMakeGround + yakumono init
# after ftParamInitGame() (which clears the Ftmain ground obstacles/hazards) and before the fighters are made.
# The ground port reads the relocData stage files through Grdisplay file images; grMainSetupLoadGroundFiles
# loads them (it is also called lazily by Grdisplay.grDisplayGetGroundData when gkind changed).
# grCommonSetupInitAll builds the layer-1 (yakumono) GObj and fills Mpcollision.gMPCollisionYakumonoDObjs;
# when the scene initialises collision through Mpcollision.load_stage_json() it must pass
# make_yakumono_layer = false (a second layer-1 GObj would advance gMPCollisionUpdateTic twice a frame).

## Embedded relocData images of the stage classes (const dGR<Stage>FileImages).
static func grMainSetupGetFileImages(gkind: int) -> Array:
	match gkind:
		nGRKindCastle:
			return Grcastle.dGRCastleFileImages
		nGRKindSector:
			return Grsector.dGRSectorFileImages
		nGRKindJungle:
			return Grjungle.dGRJungleFileImages
		nGRKindZebes:
			return Grzebes.dGRZebesFileImages
		nGRKindHyrule:
			return Grhyrule.dGRHyruleFileImages
		nGRKindYoster:
			return Gryoster.dGRYosterFileImages
		nGRKindPupupu:
			return Grpupupu.dGRPupupuFileImages
		nGRKindYamabuki:
			return Gryamabuki.dGRYamabukiFileImages
		nGRKindInishie:
			return Grinishie.dGRInishieFileImages
	return dGRMainSetupExtraFileImages.get(gkind, [])

## Loads the ground data of `gkind`: game/data/ssb64/stages/<key>.json (AObjEvent32 streams, MPGroundData)
## then the stage class' embedded relocData words. Returns FALSE when the stage JSON is missing.
static func grMainSetupLoadGroundFiles(gkind: int) -> int:
	return TRUE if Grdisplay.grDisplayLoadGroundFiles(gkind, grMainSetupGetFileImages(gkind)) else FALSE

## Builds the ground of `gkind` for a battle (the gr part of scVSBattleStartBattle):
##   G.gSCManagerBattleState.gkind = gkind, stage data load, grWallpaperMakeDecideKind() (optional),
##   grCommonSetupInitAll().
## Call after Mpcollision.mpCollisionInitGroundData() + Itmanager.itManagerInitItems() and
## Ftparam.ftParamInitGame(), before the fighters are created.
static func grMainSetupMakeStage(gkind: int, is_make_wallpaper: int = TRUE) -> void:
	G.gSCManagerBattleState.gkind = gkind
	grMainSetupLoadGroundFiles(gkind)
	if is_make_wallpaper != FALSE:
		Grwallpaper.grWallpaperMakeDecideKind()
	Grcommonsetup.grCommonSetupInitAll()

# BEGIN GENERATED EXTRA FILE IMAGES (tools/port/gr/gen_gr_file_images.py - do not edit by hand)
## relocData words read by the ground code, from baserom.us.z64 (US v1.0, SHA-1 e2929e10fccc0aa84e5776227e798abc07cedabf).
## Same bytes as the typed C in sources/ssb-decomp-re/src/relocData/<file>.c. "w": {byte_offset: [u32 words]},
## "p": relocated pointer slots {byte_offset: [file_id, byte_offset, kind]} (kind 1 AObjEvent32, 2 SYInterpDesc, 0 other).
const dGRMainSetupExtraFileImages: Dictionary = {
	11: [   # explain
		{"fid": 115, "name": "StageExplainFile2", "w": {
			0x0108: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000,
				0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000],
			0x0720: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000,
				0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000],
			0x09B8: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000,
				0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000],
			0x0DD0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0xC24595B6,
				0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000,
				0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000],
			}, "p": {
			0x0138: [115, 0x0040, 0],
			0x0750: [115, 0x0400, 0],
			0x09E8: [115, 0x08E0, 0],
			0x0E00: [115, 0x0C20, 0],
			}},
	],
	13: [   # metal
		{"fid": 117, "name": "StageMetalFile2", "w": {
			0x1B10: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000,
				0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000],
			0x2EE0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000,
				0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000],
			0x3468: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000,
				0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000],
			0x3DD8: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000,
				0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000],
			}, "p": {
			0x1B40: [117, 0x1708, 0],
			0x2F10: [117, 0x2950, 0],
			0x3498: [117, 0x3368, 0],
			0x3E08: [117, 0x3B50, 0],
			}},
	],
	14: [   # zako
		{"fid": 116, "name": "StageBattlefieldFile2", "w": {
			0x4170: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000,
				0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000],
			}, "p": {
			0x41A0: [116, 0x3AB0, 0],
			}},
	],
	16: [   # last
		{"fid": 114, "name": "StageLastFile2", "w": {
			0x4D48: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
				0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
				0x3F800000, 0x00000002, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000,
				0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012,
				0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
				0x00000000, 0x00000000],
			0x4F10: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
			}, "p": {
			0x4D4C: [114, 0x4078, 0],
			0x4D78: [114, 0x4230, 0],
			0x4DA4: [114, 0x45D8, 0],
			0x4DD0: [114, 0x4980, 0],
			0x4DFC: [114, 0x4D18, 0],
			0x4F1C: [114, 0x4F24, 1],
			}},
	],
}
# END GENERATED EXTRA FILE IMAGES
