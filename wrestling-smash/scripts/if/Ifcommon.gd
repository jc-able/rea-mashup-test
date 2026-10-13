## 1:1 port of src/if/ifcommon.c (ssb-decomp-re): the battle interface - damage meters, stock
## icons, player tags, magnifiers, off-screen arrows, timer, 3-2-1-GO countdown, announcements,
## pause menu and the battle game_status state machine (ifCommonBattleUpdateInterfaceAll).
##
## ---------------------------------------------------------------------------------------------
## HUD DATA MODEL  (Ifcommon.ui, rebuilt by port_update_ui() after every port frame)
## Screen space is the N64 320x240 frame, origin top-left, +y down (like SObj positions).
## Sprites are not loaded from the ROM: every SObj sprite has width = height = 0, so the C position
## math yields the sprite's ANCHOR point (the HUD draws its own art around it):
##   damage digits / emblem / stock icons / timer digits / stock steal: CENTRE
##   announcement letters, countdown traffic light, pause decals: TOP-LEFT
##   player tags / item arrows: BOTTOM-CENTRE
## ui = {
##   frame: int (port frames since the scene started), game_status: nSCBattleGameStatus*,
##   players[0..3]: {
##     active (pkind != Not), pkind, fkind, costume, team, player_color_index (SCPlayerData.color:
##     0-3 = 1P-4P colours, 4 = CPU), name_tag ("1P","2P","3P","4P","CP","ALLY"), tag_visible,
##     tag_pos (Vector2 bottom-centre), tag_color (Color),
##     damage (int shown: min(999, stock_damage_all); boss: hit points), damage_visible,
##     damage_scale (pop-out scale: 1 + dmg/300 on hit, shrinks 0.05/frame after 4 frames),
##     damage_color (Color: darkens towards 0x64,0x14,0x14 as damage -> 300%), damage_flash
##     (white flash frame), damage_snap (C truncates digit positions to whole pixels),
##     damage_chars [{glyph 0-9 / 10 '%' / 11 'HP', pos (centre), visible, falling}] (KO break
##     animation: falling chars move with their own velocity), is_damage_breaking,
##     emblem_visible, emblem_pos (centre), emblem_color,
##     stocks (stock_count, -1 = out), is_stock_visible, is_single_stockicon,
##     stock_icons [Vector2 centres] (<= 6 stocks), stock_number (-1 or count when > 6, drawn as
##     icon "x" digits: stock_number_icon_pos / stock_number_digit_pos[]) },
##   timer: {visible, frames_remaining (time_remain, 60 per second), frames_passed,
##           digits [min10, min1, sec10, sec1] (as the C displays them: rounded up), seconds_remaining},
##   announce: {kind: ""/"ready"(traffic-light countdown)/"go"/"game"/"timeup"/"suddendeath"/
##              "failure"/"complete", frame (frames since it appeared)}, announcements: [same...],
##   countdown: {visible, t (thread tic since it appeared), lamp (6=3, 7=2, 8=1, 9=GO, -1 none)},
##   pause: {active, player, kind (0 player n/a, 1 default zoom, 2 bonus), show_retry},
##   magnify[0..3]: {visible, screen_pos (centre), rel_pos (from viewport centre, +y up),
##           world_pos, angle (radians, DObj rotate.z), scale, color, fog_color, rect [ulx,uly,lrx,lry],
##           viewport_rect [ulx,uly,lrx,lry], fighter_gobj},
##   arrows: {left: {visible, status, anim_frame, pos}, right: {...}, color (red, alpha 0x80)},
##   item_arrows: [{pos, item_gobj}], stock_steals: [{thief, pos, fkind, costume}],
##   screen_flash: {active, r, g, b, a (0-255), rect, colanim_id, length} (Ifscreenflash),
##   draw: [{name (C sprite symbol), pos, anchor, scale, color, env, attr, LUT, fkind, dl_link, kind}]
##         = every interface sprite the C would draw this frame, in C draw order.
## }
##
## PORT ADAPTATIONS
##  * gcRunAll (src/sys/objman.c): now implemented by the core scheduler Sim.run_frame() (moved there from
##    this file so every scene uses it). Original notes: func_run pass (link order, skipped
##    when GOBJ_FLAG_NORUN) then process priorities 5..0 with the C live-queue semantics (processes
##    added behind the running one run in the same frame; gcEjectGObj(NULL/current) is deferred
##    until the process returns). Sim.run_frame() has no func_run pass (needed by the timer).
##    func_run = property `func_run` (IFGObj) or meta "func_run" on any GObj.
##  * nGCProcessKindThread processes are explicit state machines (gobj.thread): gcSleepCurrentGObjThread(n)
##    resumes the code after it n process runs later, exactly like the N64 GObjThreads.
##  * TIMING: the timer reads sySchedulerGetTicCount() = the VI-retrace counter (60 Hz NTSC, counts
##    real retraces even on lag frames). Here one retrace == one port frame: Scvsbattle.port_update_frame
##    calls port_vi_retrace() before each update, so time_remain decreases by exactly 1 per frame while
##    game_status == Go (counting starts the frame after GO, paused frames are not counted).
##  * Display procs (SObj sprites, GBI) fill `ui` instead of display lists (port_update_ui = gcDrawAll
##    of the interface/magnify/arrows/screen-flash cameras).
class_name Ifcommon
extends Port

# include/PR/sp.h sprite attributes (not in SSBDefs)
const SP_TRANSPARENT := 0x00000001
const SP_CUTOUT := 0x00000002
const SP_HIDDEN := 0x00000004
const SP_FASTCOPY := 0x00000020
const SP_TEXSHUF := 0x00000200
const SP_CLOUD := 0x00001000

# src/sys/objman.c sGCRunStatus
const _GC_RUN_STATUS_DEFAULT := 0
const _GC_RUN_STATUS_END := 1
const _GC_RUN_STATUS_EJECT := 2

# include/macros.h
static func I_SEC_TO_TICS(q) -> int:
	return int(q * 60)

static func I_MIN_TO_TICS(q) -> int:
	return int(q * 3600)

static func F_SEC_TO_TICS(q) -> float:
	return float(q * 60)

# // // // // // // // // // // // //
# //            STRUCTS            //
# // // // // // // // // // // // //

## IFPlayerCommon (src/if/iftypes.h)
class IFPlayerCommon:
	var is_magnify_display: int = 0
	var magnify_mode: int = 0
	var magnify_scale: float = 0.0
	var player_pos_x = null          # s32* -> Array (dIFCommonPlayerDamagePositionOffsetsX)
	var player_pos_y: int = 0        # u16
	var arrows_flags: int = 0
	var arrows_left_status: int = 0
	var arrows_right_status: int = 0

## IFDCharacter
class IFDCharacter:
	var pos: Vector2 = Vector2.ZERO
	var vel: Vector2 = Vector2.ZERO
	var image_id: int = 0
	var is_lock_movement: int = 0

## IFPlayerDamage
class IFPlayerDamage:
	var damage: int = 0
	var pos_adjust_wait: int = 0
	var flash_reset_wait: int = 0
	var scale: float = 0.0
	var chars: Array = [IFDCharacter.new(), IFDCharacter.new(), IFDCharacter.new(), IFDCharacter.new()]
	var interface_gobj = null
	var color_id: int = 0
	var is_update_anim: int = 0
	var char_display_count: int = 0
	var break_anim_frame: int = 0
	var dead_stopupdate_wait: int = 0
	var is_show_interface: int = 0

## IFPlayerSteal
class IFPlayerSteal:
	var anim_frames: int = 0         # u8
	var steal_pos_x: int = 0         # u16
	var steal_pos_y: int = 0         # u16
	var target_pos_x: int = 0        # u16

## IFPlayerMagnify (+ port render output)
class IFPlayerMagnify:
	var pos: Vector2 = Vector2.ZERO
	var viewport: Dictionary = {"vp": {"vscale": [0, 0, 0, 0], "vtrans": [0, 0, 0, 0]}}
	var interface_gobj = null
	var color_id: int = 0
	var port_frame_drawn: int = -1
	var port_rect: Array = [0, 0, 0, 0]
	var port_viewport_rect: Array = [0, 0, 0, 0]
	var port_screen_pos: Vector2 = Vector2.ZERO

## Sprite (PR/sp.h) - the fields the interface code reads/writes. name = C symbol of the ROM sprite.
class Sprite:
	var name: String = ""
	var width: int = 0
	var height: int = 0
	var attr: int = 0
	var red: int = 0xFF
	var green: int = 0xFF
	var blue: int = 0xFF
	var alpha: int = 0xFF
	var scalex: float = 1.0
	var scaley: float = 1.0
	var LUT = null
	var fkind: int = -1
	func copy_from(o) -> void:
		name = o.name
		width = o.width
		height = o.height
		attr = o.attr
		red = o.red
		green = o.green
		blue = o.blue
		alpha = o.alpha
		scalex = o.scalex
		scaley = o.scaley
		LUT = o.LUT
		fkind = o.fkind

## SObj (src/sys/objtypes.h)
class SObj:
	var next = null
	var prev = null
	var parent_gobj = null
	var sprite: Sprite = Sprite.new()
	var pos: Vector2 = Vector2.ZERO
	var envcolor: Dictionary = {"r": 0, "g": 0, "b": 0, "a": 0}
	var user_data = null

## Interface GObj: GObj + C fields the port GObj lacks (func_run, obj = SObj list, dl link, thread).
class IFGObj extends GObj:
	# func_run is inherited from GObj
	var sobj = null
	var dl_link: int = -1
	var thread: Dictionary = {}
	var port_kind: String = ""
	var port_frame_made: int = 0

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8012EBF0
const dIFCommonPlayerDamageDigitWidths: Array = [14, 9, 15, 14, 15, 13, 15, 14, 15, 15, 17, 20]
## 0x8012EC20
const dIFCommonPlayerDamageDigitColorsR: Array = [0xFF, 0xF0, 0xF0, 0xFF, 0xFF]
const dIFCommonPlayerDamageDigitColorsG: Array = [0xF0, 0xFF, 0xF0, 0xFF, 0xFF]
const dIFCommonPlayerDamageDigitColorsB: Array = [0xF0, 0xF0, 0xFF, 0xFF, 0xFF]
## 0x8012EC38
const dIFCommonPlayerDamagePositionOffsetsX: Array = [55, 125, 195, 265]
const dIFCommonPlayerScorePositionOffsetsX: Array = [0, 0, 0, 0]
const dIFCommonPlayerDamageEmblemOffsetsX: Array = [3, 3, 3, 3]
const dIFCommonPlayerDamageEmblemOffsetsY: Array = [-3, -3, -3, -3]
const dIFCommonPlayerDamageEmblemScales: Array = [1.0, 1.0, 1.0, 1.0]
const dIFCommonPlayerStocksIconOffsetsX: Array = [-24, -24, -24, -24]
const dIFCommonPlayerStocksDigitOffsetsX: Array = [4, 4, 4, 4]
## 0x8012ECA8
const dIFCommonTrafficSpriteColorsR: Array = [0xFE, 0xFF, 0x4B, 0xFF, 0xFF, 0x22, 0xFF, 0xFF, 0xFF]
const dIFCommonTrafficSpriteColorsG: Array = [0x0C, 0xA2, 0x64, 0x38, 0xA2, 0x66, 0xFF, 0xFF, 0xFF]
const dIFCommonTrafficSpriteColorsB: Array = [0x0C, 0x00, 0xFF, 0x38, 0x00, 0xFE, 0xFF, 0xFF, 0xFF]
const dIFCommonTrafficGoBacklightR: Array = [0x00, 0x6A]
const dIFCommonTrafficGoBacklightG: Array = [0x00, 0x6A]
const dIFCommonTrafficGoBacklightB: Array = [0x00, 0x95]
const dIFCommonTrafficGoShadowR: Array = [0x00, 0x12]
const dIFCommonTrafficGoShadowG: Array = [0x00, 0x12]
const dIFCommonTrafficGoShadowB: Array = [0x00, 0x2E]
## 0x8012ECE4 IFTraffic {pos, color_id}
const dIFCommonTrafficSpriteData: Array = [
	[123, -13, 0x00], [140, -11, 0x01], [153, -11, 0x01], [166, -11, 0x01], [180, -15, 0x02],
	[107, -33, 0x03], [119, 21, 0x04], [132, 21, 0x04], [145, 21, 0x04], [162, 20, 0x05],
	[115, -26, 0x06], [131, 32, 0x07], [144, 32, 0x07], [157, 32, 0x07], [167, 23, 0x08]
]
## 0x8012ED40
const dIFCommonTrafficSpriteOffsets: Array = [
	"llIFCommonGameStatusLampRedDimSprite", "llIFCommonGameStatusLampYellowDimSprite", "llIFCommonGameStatusLampBlueDimSprite",
	"llIFCommonGameStatusLampRedContourSprite", "llIFCommonGameStatusLampYellowContourSprite", "llIFCommonGameStatusLampBlueContourSprite",
	"llIFCommonGameStatusLampRedLightSprite", "llIFCommonGameStatusLampYellowLightSprite", "llIFCommonGameStatusLampBlueLightSprite"
]
## 0x8012ED64 IFACharacter {x, y, offset}
const dIFCommonAnnounceGoSpriteData: Array = [
	[82, 93, "llIFCommonGameStatusOrangeLetterGSprite"], [144, 93, "llIFCommonGameStatusOrangeLetterOSprite"],
	[214, 93, "llIFCommonGameStatusOrangeExclamationMarkSprite"]
]
const dIFCommonAnnounceSuddenDeathSpriteData: Array = [
	[74, 67, "llIFCommonAnnounceCommonLetterSSprite"], [102, 67, "llIFCommonAnnounceCommonLetterUSprite"],
	[132, 67, "llIFCommonAnnounceCommonLetterDSprite"], [163, 67, "llIFCommonAnnounceCommonLetterDSprite"],
	[193, 67, "llIFCommonAnnounceCommonLetterESprite"], [217, 67, "llIFCommonAnnounceCommonLetterNSprite"],
	[83, 113, "llIFCommonAnnounceCommonLetterDSprite"], [113, 113, "llIFCommonAnnounceCommonLetterESprite"],
	[135, 113, "llIFCommonAnnounceCommonLetterASprite"], [165, 113, "llIFCommonAnnounceCommonLetterTSprite"],
	[192, 113, "llIFCommonAnnounceCommonLetterHSprite"], [227, 113, "llIFCommonAnnounceCommonSymbolExclaimSprite"]
]
const dIFCommonAnnounceSuddenDeathSpriteColors: Dictionary = {"prim": {"r": 0xFF, "g": 0xFF, "b": 0xFF}, "env": {"r": 0x00, "g": 0x00, "b": 0x00}}
const dIFCommonAnnounceTimeUpSpriteData: Array = [
	[45, 95, "llIFCommonGameStatusBlueLetterTSprite"], [82, 95, "llIFCommonGameStatusBlueLetterISprite"],
	[100, 95, "llIFCommonGameStatusBlueLetterMSprite"], [151, 95, "llIFCommonGameStatusBlueLetterESprite"],
	[195, 95, "llIFCommonGameStatusBlueLetterUSprite"], [238, 95, "llIFCommonGameStatusBlueLetterPSprite"]
]
const dIFCommonAnnounceGameSetSpriteData: Array = [
	[22, 95, "llIFCommonGameStatusBlueLetterGSprite"], [62, 95, "llIFCommonGameStatusBlueLetterASprite"],
	[104, 95, "llIFCommonGameStatusBlueLetterMSprite"], [154, 95, "llIFCommonGameStatusBlueLetterESprite"],
	[191, 95, "llIFCommonGameStatusBlueLetterSSprite"], [230, 95, "llIFCommonGameStatusBlueLetterESprite"],
	[262, 95, "llIFCommonGameStatusBlueLetterTSprite"]
]
## 0x8012EE4C
const dIFCommonEntryFocusSleepTics: Array = [22, 15, 60]
## 0x8012EE54
const dIFCommonTimerDigitsSpritePositionsX: Array = [232, 247, 273, 288]
## 0x8012EE64
const dIFCommonPlayerDamageDigitSpriteOffsets: Array = [
	"llIFCommonPlayerDamageDigit0Sprite", "llIFCommonPlayerDamageDigit1Sprite", "llIFCommonPlayerDamageDigit2Sprite",
	"llIFCommonPlayerDamageDigit3Sprite", "llIFCommonPlayerDamageDigit4Sprite", "llIFCommonPlayerDamageDigit5Sprite",
	"llIFCommonPlayerDamageDigit6Sprite", "llIFCommonPlayerDamageDigit7Sprite", "llIFCommonPlayerDamageDigit8Sprite",
	"llIFCommonPlayerDamageDigit9Sprite", "llIFCommonPlayerDamageSymbolPercentSprite", "llIFCommonPlayerDamageSymbolHPSprite"
]
## 0x8012EE94
const dIFCommonTimerDigitSpriteOffsets: Array = [
	"llIFCommonTimerDigit0Sprite", "llIFCommonTimerDigit1Sprite", "llIFCommonTimerDigit2Sprite", "llIFCommonTimerDigit3Sprite",
	"llIFCommonTimerDigit4Sprite", "llIFCommonTimerDigit5Sprite", "llIFCommonTimerDigit6Sprite", "llIFCommonTimerDigit7Sprite",
	"llIFCommonTimerDigit8Sprite", "llIFCommonTimerDigit9Sprite", "llIFCommonTimerSymbolColonSprite",
	"llIFCommonTimerSymbolSecSprite", "llIFCommonTimerSymbolCSecSprite"
]
## 0x8012EEC8
const dIFCommonPlayerStockDigitSpriteOffsets: Array = [
	"llIFCommonDigits0Sprite", "llIFCommonDigits1Sprite", "llIFCommonDigits2Sprite", "llIFCommonDigits3Sprite",
	"llIFCommonDigits4Sprite", "llIFCommonDigits5Sprite", "llIFCommonDigits6Sprite", "llIFCommonDigits7Sprite",
	"llIFCommonDigits8Sprite", "llIFCommonDigits9Sprite", "llIFCommonDigitsCrossSprite"
]
## 0x8012EEF8 gsDPSetPrimColor(0, 0, 0xFF, 0x00, 0x00, 0x80) - arrows colour
const dIFCommonPlayerArrowsDisplayList: Dictionary = {"prim": {"r": 0xFF, "g": 0x00, "b": 0x00, "a": 0x80}}
## 0x8012EF38 (minute tens, minute ones, second tens, second ones)
const dIFCommonTimerDigitsUnitLengths: Array = [36000, 3600, 600, 60]
## 0x8012EF40
const dIFCommonPlayerTeamColorIDs: Array = [0, 1, 3, 4, 0]
## 0x8012EF48
const dIFCommonAnnounceTimerVoiceIDs: Array = [
	nSYAudioVoiceAnnounceOne, nSYAudioVoiceAnnounceTwo, nSYAudioVoiceAnnounceThree, nSYAudioVoiceAnnounceFour, nSYAudioVoiceAnnounceFive
]
## 0x8012EF54
const dIFCommonBattlePausePlayerNumSpriteOffsets: Array = [
	"llIFCommonBattlePausePlayerNum1PSprite", "llIFCommonBattlePausePlayerNum2PSprite",
	"llIFCommonBattlePausePlayerNum3PSprite", "llIFCommonBattlePausePlayerNum4PSprite"
]
## 0x8012EF64
const dIFCommonPlayerMagnifyColorsR: Array = [0xEF, 0x00, 0xFF, 0x00, 0xFF]
const dIFCommonPlayerMagnifyColorsG: Array = [0x0D, 0x00, 0xE1, 0xFF, 0xFF]
const dIFCommonPlayerMagnifyColorsB: Array = [0x17, 0xFF, 0x00, 0x00, 0xFF]
## 0x8012EF7C
const dIFCommonPlayerTagPrimColorsR: Array = [0xED, 0x4E, 0xFF, 0x4E, 0xAC]
const dIFCommonPlayerTagPrimColorsG: Array = [0x36, 0x4E, 0xDF, 0xB9, 0xAC]
const dIFCommonPlayerTagPrimColorsB: Array = [0x36, 0xE9, 0x1A, 0x4E, 0xAC]
const dIFCommonPlayerTagEnvColorsR: Array = [0x00, 0x00, 0x00, 0x00, 0x00]
const dIFCommonPlayerTagEnvColorsG: Array = [0x00, 0x00, 0x00, 0x00, 0x00]
const dIFCommonPlayerTagEnvColorsB: Array = [0x00, 0x00, 0x00, 0x00, 0x00]
## 0x8012EFAC
const dIFCommonPlayerTagSpriteOffsets: Array = [
	"llIFCommonPlayerTags1PSprite", "llIFCommonPlayerTags2PSprite", "llIFCommonPlayerTags3PSprite",
	"llIFCommonPlayerTags4PSprite", "llIFCommonPlayerTagsCPSprite", "llIFCommonPlayerTagsAllySprite"
]
const _PORT_TAG_NAMES: Array = ["1P", "2P", "3P", "4P", "CP", "ALLY"]
## 0x8012EFC4 IFPauseDecal {offset, x, y, prim rgb, env rgb}
const dIFCommonBattlePauseDecalsSpriteData: Array = [
	["llIFCommonBattlePauseDecalPauseSprite", 232, 191, [0xFF, 0xFF, 0xFF], [0x00, 0x00, 0x00]],
	["llIFCommonBattlePauseDecalAButtonSprite", 99, 203, [0x00, 0x95, 0xFF], [0x00, 0x05, 0xC7]],
	["llIFCommonBattlePauseDecalBButtonSprite", 122, 203, [0x36, 0xBF, 0x00], [0x00, 0x30, 0x00]],
	["llIFCommonBattlePauseDecalZTriggerSprite", 145, 202, [0x80, 0x80, 0x80], [0x21, 0x21, 0x21]],
	["llIFCommonBattlePauseDecalRTriggerSprite", 164, 203, [0x80, 0x80, 0x80], [0x21, 0x21, 0x21]],
	["llIFCommonBattlePauseDecalPlusSprite", 113, 206, [0xFF, 0xFF, 0xFF], [0x00, 0x00, 0x00]],
	["llIFCommonBattlePauseDecalPlusSprite", 136, 206, [0xFF, 0xFF, 0xFF], [0x00, 0x00, 0x00]],
	["llIFCommonBattlePauseDecalPlusSprite", 155, 206, [0xFF, 0xFF, 0xFF], [0x00, 0x00, 0x00]],
	["llIFCommonBattlePauseDecalResetSprite", 182, 205, [0xFF, 0xFF, 0xFF], [0x00, 0x00, 0x00]],
	["llIFCommonBattlePauseDecalSmashBallSprite", 198, 191, [0xFF, 0xFF, 0xFF], [0x00, 0x00, 0x00]],
	["llIFCommonBattlePauseDecalArrowsSprite", 21, 19, [0xFF, 0x00, 0x00], [0x00, 0x00, 0x00]],
	["llIFCommonBattlePauseDecalControlStickSprite", 31, 29, [0xFF, 0xFF, 0xFF], [0x14, 0x18, 0x11]],
	["llIFCommonBattlePauseDecalLTriggerSprite", 34, 203, [0x80, 0x80, 0x80], [0x21, 0x21, 0x21]],
	["llIFCommonBattlePauseDecalRetrySprite", 51, 205, [0xFF, 0xFF, 0xFF], [0x00, 0x00, 0x00]]
]
## 0x8012F0A4 SYRectangle {ulx, uly, lrx, lry}
const dIFCommonBattlePauseBorderRectangle: Array = [
	[26, 24, 294, 26], [26, 24, 28, 199], [26, 197, 190, 199], [292, 24, 294, 199], [279, 197, 294, 199]
]
const dIFCommonAnnounceFailureSpriteData: Array = [
	[77, 101, "llIFCommonAnnounceCommonLetterFSprite"], [97, 101, "llIFCommonAnnounceCommonLetterASprite"],
	[130, 101, "llIFCommonAnnounceCommonLetterISprite"], [145, 101, "llIFCommonAnnounceCommonLetterLSprite"],
	[167, 101, "llIFCommonAnnounceCommonLetterUSprite"], [197, 101, "llIFCommonAnnounceCommonLetterRSprite"],
	[225, 101, "llIFCommonAnnounceCommonLetterESprite"]
]
const dIFCommonAnnounceFailureSpriteColors: Dictionary = {"prim": {"r": 0xFF, "g": 0xFF, "b": 0xFF}, "env": {"r": 0x00, "g": 0x00, "b": 0xFF}}
const dIFCommonAnnounceCompleteSpriteData: Array = [
	[46, 101, "llIFCommonAnnounceCommonLetterCSprite"], [71, 101, "llIFCommonAnnounceCommonLetterOSprite"],
	[104, 100, "llIFCommonAnnounceCommonLetterMSprite"], [143, 101, "llIFCommonAnnounceCommonLetterPSprite"],
	[168, 101, "llIFCommonAnnounceCommonLetterLSprite"], [189, 101, "llIFCommonAnnounceCommonLetterESprite"],
	[212, 101, "llIFCommonAnnounceCommonLetterTSprite"], [237, 101, "llIFCommonAnnounceCommonLetterESprite"],
	[267, 101, "llIFCommonAnnounceCommonSymbolExclaimSprite"]
]
const dIFCommonAnnounceCompleteSpriteColors: Dictionary = {"prim": {"r": 0xFF, "g": 0xFF, "b": 0xFF}, "env": {"r": 0xFF, "g": 0x00, "b": 0x00}}
## 0x8012F184
const dIFCommonAnnounceDefeatedVoiceIDs: Array = [
	nSYAudioVoiceAnnouncePlayer1, nSYAudioVoiceAnnouncePlayer2, nSYAudioVoiceAnnouncePlayer3, nSYAudioVoiceAnnouncePlayer4
]

# // // // // // // // // // // // //
# //   GLOBAL / STATIC VARIABLES   //
# // // // // // // // // // // // //

static var gIFCommonPlayerInterface: IFPlayerCommon = IFPlayerCommon.new()        # 0x80131580
static var sIFCommonPlayerDamageInterface: Array = _port_make(0)                 # 0x80131598
static var sIFCommonPlayerMagnifyInterface: Array = _port_make(1)                # 0x80131748
static var sIFCommonTimerDigitsInterface: Array = [0, 0, 0, 0]                    # 0x801317C8 u8
static var sIFCommonPlayerStocksNum: Array = [0, 0, 0, 0]                         # 0x801317CC s8
static var sIFCommonPlayerStocksGObj: Array = [null, null, null, null]           # 0x801317D0
static var sIFCommonTimerLimit: int = 0                                           # 0x801317E0 u32
static var sIFCommonBattlePausePlayer: int = 0                                    # 0x801317E4 u8
static var sIFCommonBattlePausePlayerDetail: int = 0                              # 0x801317E5 u8
static var sIFCommonBattlePauseCameraRestoreWait: int = 0                         # 0x801317E6 u16
static var sIFCommonBattlePauseCameraEyeXOrigin: float = 0.0                      # 0x801317E8
static var sIFCommonBattlePauseCameraEyeYOrigin: float = 0.0                      # 0x801317EC
static var sIFCommonItemArrowSprite = null                                        # 0x801317F0
static var sIFCommonBattlePlace: int = 0                                          # 0x801317F4
static var sIFCommonTimerStamp: int = 0                                           # 0x801317FC u32
static var sIFCommonTimerIsStarted: int = 0                                       # 0x80131800
static var sIFCommonBattleEndSoundsQueue: Array = _port_zeros(16)                 # 0x80131808 u16
static var sIFCommonBattlePauseKindInterface: int = 0                             # 0x80131828 u8
static var sIFCommonBattleEndSoundsNum: int = 0                                   # 0x80131829 u8
static var sIFCommonBattleInterfaceProcUpdate: Callable = Callable()              # 0x8013182C
static var sIFCommonBattleInterfaceProcSet: Callable = Callable()                 # 0x80131830
static var sIFCommonPlayerStealInterface: Array = _port_make(2)                   # 0x80131838
static var sIFCommonPlayerMagnifySoundWait: int = 0                               # 0x80131858 u8
static var dIFCommonBattleBossUpdateInterval: int = 0                             # 0x80131859 u8
static var dIFCommonBattleBossUpdateWait: int = 0                                 # 0x8013185A u8
static var sIFCommonIsAnnouncedSecond: Array = [0, 0, 0, 0, 0]                    # 0x8013185C

# --- port-only state ---------------------------------------------------------------------------
static var ui: Dictionary = {}
static var port_frame: int = 0                     # port frames since the scene task started
static var port_sySchedulerTicCount: int = 0       # sSYSchedulerTicCount (src/sys/scheduler.c)
static var port_load_scene_requested: bool = false # syTaskmanSetLoadScene() was called
static var port_hud_computes_magnify: bool = true  # run ftDisplayMainProcDisplay's magnifier part here
static var _gc_current_gobj = null                 # gGCCurrentCommon during _gcRunAll
static var _gc_run_status: int = 0                 # sGCRunStatus
static var _port_sprites: Dictionary = {}          # loaded ROM sprites (name -> Sprite)
static var _port_dl_links: Dictionary = {}         # dl_link -> Array[GObj] (gcAddGObjDisplay order)
static var _port_draw: Array = []

static func _port_zeros(n: int) -> Array:
	var a := []
	a.resize(n)
	a.fill(0)
	return a

static func _port_make(kind: int) -> Array:
	var a := []
	for i in 4:
		match kind:
			0: a.append(IFPlayerDamage.new())
			1: a.append(IFPlayerMagnify.new())
			_: a.append(IFPlayerSteal.new())
	return a

## Overlay load (syDmaLoadOverlay zeroes ovl2 BSS) at the start of each VS battle scene.
static func port_reset_bss() -> void:
	gIFCommonPlayerInterface = IFPlayerCommon.new()
	sIFCommonPlayerDamageInterface = _port_make(0)
	sIFCommonPlayerMagnifyInterface = _port_make(1)
	sIFCommonTimerDigitsInterface = [0, 0, 0, 0]
	sIFCommonPlayerStocksNum = [0, 0, 0, 0]
	sIFCommonPlayerStocksGObj = [null, null, null, null]
	sIFCommonTimerLimit = 0
	sIFCommonBattlePausePlayer = 0
	sIFCommonBattlePausePlayerDetail = 0
	sIFCommonBattlePauseCameraRestoreWait = 0
	sIFCommonBattlePauseCameraEyeXOrigin = 0.0
	sIFCommonBattlePauseCameraEyeYOrigin = 0.0
	sIFCommonItemArrowSprite = null
	sIFCommonBattlePlace = 0
	sIFCommonTimerStamp = 0
	sIFCommonTimerIsStarted = 0
	sIFCommonBattleEndSoundsQueue = _port_zeros(16)
	sIFCommonBattlePauseKindInterface = 0
	sIFCommonBattleEndSoundsNum = 0
	sIFCommonBattleInterfaceProcUpdate = Callable()
	sIFCommonBattleInterfaceProcSet = Callable()
	sIFCommonPlayerStealInterface = _port_make(2)
	sIFCommonPlayerMagnifySoundWait = 0
	dIFCommonBattleBossUpdateInterval = 0
	dIFCommonBattleBossUpdateWait = 0
	sIFCommonIsAnnouncedSecond = [0, 0, 0, 0, 0]
	ui = {}

## Taskman task start (syTaskmanStartTask): fresh object manager for the scene.
static func port_task_start() -> void:
	Sim.reset()
	_port_dl_links = {}
	_gc_current_gobj = null
	_gc_run_status = _GC_RUN_STATUS_DEFAULT
	port_load_scene_requested = false
	port_frame = 0

## Reloaded sprite files (lbRelocLoadFilesListed): ROM sprite attributes start from scratch.
static func port_reload_sprite_files() -> void:
	_port_sprites = {}

## One NTSC vertical retrace (sySchedulerVRetrace: sSYSchedulerTicCount++), before each update.
static func port_vi_retrace() -> void:
	port_sySchedulerTicCount = (port_sySchedulerTicCount + 1) & 0xFFFFFFFF

static func _sySchedulerGetTicCount() -> int:
	return port_sySchedulerTicCount

static func _sySchedulerSetTicCount(tics: int) -> void:
	port_sySchedulerTicCount = tics & 0xFFFFFFFF

static func _syTaskmanSetLoadScene() -> void:
	port_load_scene_requested = true
	Taskman.syTaskmanSetLoadScene()

# --- audio library entry points that have no port module (libultra n_audio) ----------------------
static func _func_80026594_27194() -> void:     # pause all sound effects
	StubLog.hit("func_80026594_27194")

static func _func_800264A4_270A4() -> void:     # resume all sound effects
	StubLog.hit("func_800264A4_270A4")

# --- object manager helpers (src/sys/objman.c / objhelper.c semantics on top of Sim) -------------
static func _gcMakeGObjSPAfter(id: int, func_run, link: int, priority) -> IFGObj:
	var gobj := IFGObj.new()
	gobj.gobj_kind = id
	gobj.func_run = func_run if func_run is Callable else Callable()
	gobj.gobj_flags = GOBJ_FLAG_NONE
	gobj.user_data = null
	gobj.port_frame_made = port_frame
	Sim.add_gobj(gobj, link)
	return gobj

static func _gcAddGObjDisplay(gobj, proc_display: Callable, dl_link: int, priority, cobj_mask) -> void:
	Objman.gcAddGObjDisplay(gobj, proc_display, dl_link, priority, cobj_mask)
	if gobj is IFGObj:
		gobj.dl_link = dl_link
	if not _port_dl_links.has(dl_link):
		_port_dl_links[dl_link] = []
	_port_dl_links[dl_link].append(gobj)

## gcEjectGObj: NULL / the running GObj -> deferred until its process/func_run returns.
static func _gcEjectGObj(gobj) -> void:
	if (gobj == null) or (gobj == Sim.current_gobj):
		Sim.run_status = Sim.RUN_STATUS_EJECT
		return
	_port_eject_now(gobj)

static func _port_eject_now(gobj) -> void:
	if gobj is IFGObj:
		gobj.sobj = null
	Objman.gcEjectGObj(gobj)

static func _port_get_func_run(gobj) -> Callable:
	if gobj is IFGObj:
		return gobj.func_run
	var fr = gobj.get(&"func_run")
	if fr is Callable:
		return fr
	if gobj.has_meta(&"func_run"):
		return gobj.get_meta(&"func_run")
	return Callable()

static func _port_resume_index(lst: Array, preds: Array) -> int:
	var i := preds.size() - 1
	while i >= 0:
		var at := lst.find(preds[i])
		if at >= 0:
			return at + 1
		i -= 1
	return 0

static func _port_link_next(lst: Array, gobj):
	var at := lst.find(gobj)
	if (at >= 0) and (at + 1 < lst.size()):
		return lst[at + 1]
	return null

## Port of gcRunAll (src/sys/objman.c 0x8000A5E4) incl. gcRunGObj / gcRunGObjProcess.
static func _gcRunAll() -> void:
	# gcRunAll is implemented by the core scheduler (Sim.run_frame) with the same C semantics.
	Sim.run_frame()

## gcFuncGObjByLink / gcFuncGObjAll (src/sys/objhelper.c)
static func _gcFuncGObjByLink(link: int, func_: Callable, param) -> void:
	for gobj in Sim.get_link(link).duplicate():
		if gobj.is_alive:
			func_.call(gobj, param)

static func _gcFuncGObjAll(func_: Callable, param) -> void:
	for link in Sim.LINKS_NUM:
		_gcFuncGObjByLink(link, func_, param)

# --- thread helpers (gcSleepCurrentGObjThread) ----------------------------------------------------
static func _th_wake(th: Dictionary) -> bool:
	if th.wait > 0:
		th.wait -= 1
		if th.wait > 0:
			return false
	return true

static func _th_sleep(th: Dictionary, tics: int, pc: int) -> void:
	th.wait = tics
	th.pc = pc

static func _th_state(gobj) -> Dictionary:
	if gobj.thread.is_empty():
		gobj.thread["pc"] = 0
		gobj.thread["wait"] = 0
	return gobj.thread

# --- SObj helpers (gcAddSObjForGObj / gcEjectSObj / lbCommonMakeSObjForGObj / lbCommonDrawSObjAttr) --
static func _port_sprite(name: String) -> Sprite:
	if not _port_sprites.has(name):
		var s := Sprite.new()
		s.name = name
		_port_sprites[name] = s
	return _port_sprites[name]

## fp->attr->sprites->stock_sprite / ->emblem (fighter main file sprites, one per fkind)
static func _port_ft_sprite(fp, what: String) -> Sprite:
	var s := _port_sprite("FTSprites.%s.%d" % [what, fp.fkind])
	s.fkind = fp.fkind
	return s

static func _port_ft_sprites(fp):
	if (fp == null) or (fp.attr == null):
		return null
	return fp.attr.get("sprites", null)

static func SObjGetStruct(gobj):
	if gobj is IFGObj:
		return gobj.sobj
	return null

static func _gcAddSObjForGObj(gobj, sprite) -> SObj:
	var new_sobj := SObj.new()
	if SObjGetStruct(gobj) != null:
		var tail_sobj = SObjGetStruct(gobj)
		while tail_sobj.next != null:
			tail_sobj = tail_sobj.next
		tail_sobj.next = new_sobj
		new_sobj.prev = tail_sobj
	else:
		gobj.sobj = new_sobj
		new_sobj.prev = null
	new_sobj.parent_gobj = gobj
	new_sobj.next = null
	if sprite != null:
		new_sobj.sprite.copy_from(sprite)
	new_sobj.user_data = null
	return new_sobj

static func _gcEjectSObj(sobj) -> void:
	if sobj == SObjGetStruct(sobj.parent_gobj):
		sobj.parent_gobj.sobj = sobj.next
	if sobj.prev != null:
		sobj.prev.next = sobj.next
	if sobj.next != null:
		sobj.next.prev = sobj.prev

static func _lbCommonMakeSObjForGObj(gobj, sprite) -> SObj:
	var sobj := _gcAddSObjForGObj(gobj, sprite)
	sobj.envcolor = {"r": 0, "g": 0, "b": 0, "a": 0}
	sobj.pos = Vector2(0.0, 0.0)
	return sobj

static func _port_anchor(gobj) -> String:
	var kind: String = gobj.port_kind if (gobj is IFGObj) else ""
	if kind in ["tag", "item_arrow"]:
		return "bottom_center"
	if kind in ["damage", "stock", "timer", "steal"]:
		return "center"
	return "top_left"

static func _port_draw_sobj(sobj, gobj) -> void:
	if sobj.sprite.attr & SP_HIDDEN:
		return
	var s: Sprite = sobj.sprite
	_port_draw.append({
		"name": s.name, "pos": sobj.pos, "anchor": _port_anchor(gobj), "scale": Vector2(s.scalex, s.scaley),
		"color": Color8(s.red & 0xFF, s.green & 0xFF, s.blue & 0xFF, s.alpha & 0xFF),
		"env": Color8(sobj.envcolor.r & 0xFF, sobj.envcolor.g & 0xFF, sobj.envcolor.b & 0xFF, 0xFF),
		"attr": s.attr, "LUT": s.LUT, "fkind": s.fkind,
		"dl_link": gobj.dl_link if (gobj is IFGObj) else -1, "kind": gobj.port_kind if (gobj is IFGObj) else ""
	})

## lbCommonDrawSObjAttr (src/lb/lbcommon.c) as a display proc
static func lbCommonDrawSObjAttr(gobj) -> void:
	var sobj = SObjGetStruct(gobj)
	while sobj != null:
		if not (sobj.sprite.attr & SP_HIDDEN):
			_port_draw_sobj(sobj, gobj)
		sobj = sobj.next

static func ifGetPlayer(interface_gobj) -> int:
	return interface_gobj.user_data

static func ifSetPlayer(interface_gobj, player: int) -> void:
	interface_gobj.user_data = player

static func ifGetSObj(interface_gobj):
	return interface_gobj.user_data

static func ifSetSObj(interface_gobj, sobj) -> void:
	interface_gobj.user_data = sobj

static func ifGetProc(interface_gobj) -> Callable:
	return interface_gobj.user_data

static func ifSetProc(interface_gobj, proc: Callable) -> void:
	interface_gobj.user_data = proc

static func _port_ground_color(field: String, index: int = -1) -> Dictionary:
	var gd = Mpcollision.gMPCollisionGroundData
	if gd == null:
		return {"r": 0xFF, "g": 0xFF, "b": 0xFF}
	var c = gd.get(field)
	if index >= 0:
		c = c[index] if (c != null) and (index < c.size()) else null
	if c == null:
		return {"r": 0xFF, "g": 0xFF, "b": 0xFF}
	return c

## func_ovl2_800EB924 (src/ft/ftparam.c) world -> viewport projection. Ftparam's port is a render-side
## stub, Gmcamera._gmCameraProjectScreen is the same routine.
static func _port_project(pos: Vector3) -> Vector2:
	var cobj = Gmcamera.CObjGetStruct(Gmcamera.gGMCameraGObj)
	if cobj == null:
		return Vector2(1.0e9, 1.0e9)
	return Gmcamera._gmCameraProjectScreen(cobj, Gmcamera.gGMCameraMatrix, pos)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8010E690
static func ifCommonPlayerDamageSetShowInterface() -> void:
	for i in range(sIFCommonPlayerDamageInterface.size()):
		if sIFCommonPlayerDamageInterface[i].interface_gobj != null:
			sIFCommonPlayerDamageInterface[i].is_show_interface = TRUE

## 0x8010E700 - digits (u8*) is an out-parameter: returns {"ret": count, "digits": Array}.
static func ifCommonPlayerDamageGetSpecialArrayID(damage: int, digits = null) -> Dictionary:
	if digits == null:
		digits = [0, 0, 0, 0]
	var count := 0
	var digit_update := 1

	if damage >= 10:
		while true:
			digit_update *= 10
			if not ((damage / digit_update) >= 10):
				break
	while true:
		digits[count] = (damage / digit_update) & 0xFF
		count += 1
		damage %= digit_update
		digit_update /= 10
		if digit_update == 0:
			break
	return {"ret": count, "digits": digits}

## 0x8010E7D4
static func ifCommonPlayerDamageGetPercentArrayID(damage: int, digits = null) -> Dictionary:
	var r := ifCommonPlayerDamageGetSpecialArrayID(damage, digits)
	var id: int = r.ret
	r.digits[id] = 0xA
	return {"ret": id + 1, "digits": r.digits}

## 0x8010E808
static func ifCommonPlayerDamageGetHitPointsArrayID(damage: int, digits = null) -> Dictionary:
	var r := ifCommonPlayerDamageGetSpecialArrayID(damage, digits)
	var id: int = r.ret
	r.digits[id] = 0xB
	return {"ret": id + 1, "digits": r.digits}

## 0x8010E83C
static func ifCommonPlayerDamageGetDigitOffset(digit_count: int, digit_ids: Array) -> int:
	var offset := 0
	for i in range(digit_count):
		offset += dIFCommonPlayerDamageDigitWidths[digit_ids[i]]
	return offset

## 0x8010E8F4
static func ifCommonPlayerDamageUpdateDigits(interface_gobj) -> void:
	var player: int = ifGetPlayer(interface_gobj)
	var s: IFPlayerDamage = sIFCommonPlayerDamageInterface[player]
	var damage: int
	var start_damage: int
	var scale: float
	var damage_scale: int
	var pos_adjust_wait: int
	var flash_reset_wait: int
	var color_id: int
	var char_count: int
	var digits: Array = [0, 0, 0, 0]
	var r: Dictionary
	var pos_x: float
	var digit_id: int
	var sobj
	var offset: float

	start_damage = G.gSCManagerBattleState.players[player].stock_damage_all
	damage = start_damage

	if damage > 999:
		damage = 999
	scale = s.scale
	damage_scale = start_damage - s.damage

	if damage_scale == 0:
		if scale == 1.0:
			return
	elif damage_scale < 0:
		scale = 1.0
	else:
		s.pos_adjust_wait = 4
		s.flash_reset_wait = 1

		scale = (damage_scale / 300.0) + 1.0
	pos_adjust_wait = s.pos_adjust_wait
	flash_reset_wait = s.flash_reset_wait

	if flash_reset_wait != 0:
		color_id = GMCOMMON_PLAYERS_MAX
	else:
		color_id = player

	if G.gSCManagerBattleState.players[player].fkind == nFTKindBoss:
		var hitpoints: int = 300 - damage

		if hitpoints < 0:
			hitpoints = 0
		r = ifCommonPlayerDamageGetHitPointsArrayID(hitpoints, digits)
	else:
		r = ifCommonPlayerDamageGetPercentArrayID(damage, digits)
	char_count = r.ret
	s.char_display_count = char_count & 0xFF

	pos_x = (ifCommonPlayerDamageGetDigitOffset(char_count, digits) * scale * 0.5)

	pos_x = gIFCommonPlayerInterface.player_pos_x[player] + pos_x

	if (scale > 1.0) and (pos_adjust_wait == 0):
		scale -= 0.05

		if scale < 1.0:
			scale = 1.0
	digit_id = char_count - 1

	sobj = SObjGetStruct(interface_gobj).next

	while sobj != null:
		if digit_id < 0:
			sobj.sprite.attr |= SP_HIDDEN
		else:
			var sprite_id: int = digits[digit_id]
			var ifchar: IFDCharacter = sobj.user_data

			ifchar.image_id = sprite_id

			offset = dIFCommonPlayerDamageDigitWidths[sprite_id] * scale

			ifchar.pos.x = (pos_x - (offset * 0.5))
			ifchar.pos.y = gIFCommonPlayerInterface.player_pos_y

			pos_x -= offset

			sobj.sprite.attr &= ~SP_HIDDEN
		sobj = sobj.next

		digit_id -= 1
	if pos_adjust_wait > 0:
		pos_adjust_wait -= 1
	if flash_reset_wait > 0:
		flash_reset_wait -= 1
	s.damage = start_damage
	s.scale = scale
	s.color_id = color_id & 0xFF

	s.pos_adjust_wait = pos_adjust_wait
	s.flash_reset_wait = flash_reset_wait

## 0x8010EC50
static func ifCommonPlayerDamageUpdateAnim(interface_gobj) -> void:
	var player: int = ifGetPlayer(interface_gobj)
	var s: IFPlayerDamage = sIFCommonPlayerDamageInterface[player]
	var sobj

	if s.break_anim_frame < 19:
		var modulo: int = s.break_anim_frame / 6

		if not (s.break_anim_frame - modulo * 6):
			var char_id: int = s.char_display_count - modulo

			if char_id > 0:
				var random: int = syUtilsRandIntRange(char_id)
				var i := 0
				var j := 0

				while i < s.char_display_count:
					if s.chars[i].is_lock_movement == FALSE:
						if j == random:
							break
						else:
							j += 1
					i += 1
				s.chars[i].is_lock_movement = TRUE
		s.break_anim_frame = (s.break_anim_frame + 1) & 0xFF
	sobj = SObjGetStruct(interface_gobj).next

	while sobj != null:
		if not (sobj.sprite.attr & SP_HIDDEN):
			var ifchar: IFDCharacter = sobj.user_data

			if ifchar.is_lock_movement != FALSE:
				ifchar.vel.y += 1

				ifchar.pos.x += ifchar.vel.x
				ifchar.pos.y += ifchar.vel.y
		sobj = sobj.next

## 0x8010EE18
static func ifCommonPlayerDamageProcUpdate(interface_gobj) -> void:
	var player: int = ifGetPlayer(interface_gobj)
	var s: IFPlayerDamage = sIFCommonPlayerDamageInterface[player]

	if G.gSCManagerBattleState.players[player].stock_count == -1:
		if s.dead_stopupdate_wait != 0:
			if s.is_update_anim != FALSE:
				ifCommonPlayerDamageUpdateAnim(interface_gobj)
			s.dead_stopupdate_wait = (s.dead_stopupdate_wait - 1) & 0xFF
	elif s.is_update_anim != FALSE:
		ifCommonPlayerDamageUpdateAnim(interface_gobj)
	else:
		ifCommonPlayerDamageUpdateDigits(interface_gobj)

## 0x8010EEFC
static func ifCommonPlayerDamageProcDisplay(interface_gobj) -> void:
	var sobj = SObjGetStruct(interface_gobj)
	var player: int
	var s: IFPlayerDamage

	# lbCommonPrepSObjAttr / lbCommonPrepSObjDraw (emblem) / lbCommonSetExternSpriteParams
	_port_draw_sobj(sobj, interface_gobj)

	player = ifGetPlayer(interface_gobj)
	s = sIFCommonPlayerDamageInterface[player]

	if (s.is_show_interface != FALSE) and ((G.gSCManagerBattleState.players[player].stock_count >= 0) or (s.dead_stopupdate_wait != 0)):
		var color_id: int = s.color_id
		var scale: float = s.scale
		var color_r: int
		var color_g: int
		var color_b: int
		var ifchar: IFDCharacter

		if color_id == GMCOMMON_PLAYERS_MAX:
			color_r = dIFCommonPlayerDamageDigitColorsR[color_id]
			color_g = dIFCommonPlayerDamageDigitColorsG[color_id]
			color_b = dIFCommonPlayerDamageDigitColorsB[color_id]
		else:
			var damage_scale: float = 1.0 - (s.damage / 300.0)

			if damage_scale < 0.0:
				damage_scale = 0.0
			color_r = (int((dIFCommonPlayerDamageDigitColorsR[color_id] - 0x64) * damage_scale) + 0x64) & 0xFF
			color_g = (int((dIFCommonPlayerDamageDigitColorsG[color_id] - 0x14) * damage_scale) + 0x14) & 0xFF
			color_b = (int((dIFCommonPlayerDamageDigitColorsB[color_id] - 0x14) * damage_scale) + 0x14) & 0xFF
		sobj = sobj.next
		ifchar = sobj.user_data

		sobj.sprite.copy_from(_port_sprite(dIFCommonPlayerDamageDigitSpriteOffsets[ifchar.image_id]))

		sobj.pos.x = (ifchar.pos.x - (sobj.sprite.width * 0.5 * scale))
		sobj.pos.y = (ifchar.pos.y - (sobj.sprite.height * 0.5 * scale))

		sobj.sprite.scalex = scale
		sobj.sprite.scaley = scale

		sobj.sprite.red = color_r
		sobj.sprite.green = color_g
		sobj.sprite.blue = color_b

		# lbCommonPrepSObjAttr; (color_id == 4: white combiner); lbCommonPrepSObjDraw
		_port_draw_sobj(sobj, interface_gobj)

		sobj = sobj.next

		while sobj != null:
			if not (sobj.sprite.attr & SP_HIDDEN):
				ifchar = sobj.user_data

				sobj.sprite.copy_from(_port_sprite(dIFCommonPlayerDamageDigitSpriteOffsets[ifchar.image_id]))

				var pos_x: float = ifchar.pos.x - (sobj.sprite.width * 0.5 * scale)
				var pos_y: float = ifchar.pos.y - (sobj.sprite.height * 0.5 * scale)

				if (scale == 1.0) and (s.is_update_anim == FALSE):
					sobj.pos.x = int(pos_x)
					sobj.pos.y = int(pos_y)
				else:
					sobj.pos.x = pos_x
					sobj.pos.y = pos_y
				sobj.sprite.scalex = scale
				sobj.sprite.scaley = scale

				# the prim colour set by the first digit is still active (RDP state)
				sobj.sprite.red = color_r
				sobj.sprite.green = color_g
				sobj.sprite.blue = color_b
				_port_draw_sobj(sobj, interface_gobj)
			sobj = sobj.next
		# lbCommonClearExternSpriteParams()

## 0x8010F334
static func ifCommonPlayerDamageSetDigitAttr() -> void:
	for i in range(dIFCommonPlayerDamageDigitSpriteOffsets.size()):
		_port_sprite(dIFCommonPlayerDamageDigitSpriteOffsets[i]).attr = SP_TEXSHUF | SP_TRANSPARENT

## 0x8010F3A0
static func ifCommonPlayerDamageSetDigitPositions() -> void:
	gIFCommonPlayerInterface.player_pos_x = dIFCommonPlayerDamagePositionOffsetsX
	gIFCommonPlayerInterface.player_pos_y = 210

## 0x8010F3C0
static func ifCommonPlayerDamageInitInterface() -> void:
	ifCommonPlayerDamageSetDigitAttr()

	for player in range(sIFCommonPlayerDamageInterface.size()):
		var s: IFPlayerDamage = sIFCommonPlayerDamageInterface[player]

		if G.gSCManagerBattleState.players[player].pkind == nFTPlayerKindNot:
			s.interface_gobj = null
		else:
			var interface_gobj := _gcMakeGObjSPAfter(nGCCommonKindInterface, null, nGCCommonLinkIDInterface, GOBJ_PRIORITY_DEFAULT)
			var fp = ftGetStruct(G.gSCManagerBattleState.players[player].fighter_gobj)
			var ft_sprites = _port_ft_sprites(fp)

			interface_gobj.port_kind = "damage"
			s.interface_gobj = interface_gobj

			_gcAddGObjDisplay(interface_gobj, Callable(Ifcommon, &"ifCommonPlayerDamageProcDisplay"), 23, GOBJ_PRIORITY_DEFAULT, ~0)

			if ft_sprites != null:      # (ft_sprites != NULL) && (ft_sprites->emblem != NULL)
				var sobj := _lbCommonMakeSObjForGObj(interface_gobj, _port_ft_sprite(fp, "emblem"))
				var emblem: int
				var c: Dictionary

				sobj.pos.x = int((gIFCommonPlayerInterface.player_pos_x[player] - (sobj.sprite.width * dIFCommonPlayerDamageEmblemScales[player] * 0.5)) + dIFCommonPlayerDamageEmblemOffsetsX[player])
				sobj.pos.y = int((gIFCommonPlayerInterface.player_pos_y - (sobj.sprite.height * dIFCommonPlayerDamageEmblemScales[player] * 0.5)) + dIFCommonPlayerDamageEmblemOffsetsY[player])

				sobj.sprite.scalex = dIFCommonPlayerDamageEmblemScales[player]
				sobj.sprite.scaley = dIFCommonPlayerDamageEmblemScales[player]

				emblem = G.gSCManagerBattleState.players[player].color
				c = _port_ground_color("emblem_colors", emblem)

				sobj.sprite.red = c.r
				sobj.sprite.green = c.g
				sobj.sprite.blue = c.b

				sobj.sprite.attr = SP_TEXSHUF | SP_TRANSPARENT
			else:
				_gcAddSObjForGObj(interface_gobj, null).sprite.attr = SP_HIDDEN

			for i in 4:
				_lbCommonMakeSObjForGObj(interface_gobj, _port_sprite("llIFCommonPlayerDamageDigit0Sprite")).user_data = s.chars[i]

			s.damage = G.gSCManagerBattleState.players[player].stock_damage_all
			s.pos_adjust_wait = 0
			s.flash_reset_wait = 0
			s.scale = 1.04
			s.is_update_anim = FALSE
			s.dead_stopupdate_wait = 180
			s.is_show_interface = FALSE

			ifSetPlayer(interface_gobj, player)

			ifCommonPlayerDamageProcUpdate(interface_gobj)
			Objman.gcAddGObjProcess(interface_gobj, Callable(Ifcommon, &"ifCommonPlayerDamageProcUpdate"), nGCProcessKindFunc, 0)

## 0x8010F76C
static func ifCommonPlayerDamageStartBreakAnim(fp) -> void:
	var player: int = fp.player
	var s: IFPlayerDamage = sIFCommonPlayerDamageInterface[player]

	for i in range(s.char_display_count):
		s.chars[i].vel.x = (syUtilsRandFloat() * 2) + (-1.0)
		s.chars[i].vel.y = -10.0

		s.chars[i].is_lock_movement = FALSE
	s.break_anim_frame = 0
	s.is_update_anim = TRUE

## 0x8010F840
static func ifCommonPlayerDamageStopBreakAnim(fp) -> void:
	var player: int = fp.player

	sIFCommonPlayerDamageInterface[player].is_update_anim = FALSE
	sIFCommonPlayerDamageInterface[player].scale = 1.04

## 0x8010F878
static func ifCommonPlayerStockMultiProcDisplay(interface_gobj) -> void:
	var player: int = ifGetPlayer(interface_gobj)
	var stock_count: int = G.gSCManagerBattleState.players[player].stock_count
	var fp = ftGetStruct(G.gSCManagerBattleState.players[player].fighter_gobj)

	if stock_count >= 0:
		stock_count += 1

		if stock_count != sIFCommonPlayerStocksNum[player]:
			if stock_count <= 6:
				var stock_order := 0
				var lt_sobj = SObjGetStruct(interface_gobj)

				while lt_sobj != null:
					if stock_order < stock_count:
						lt_sobj.sprite.copy_from(_port_ft_sprite(fp, "stock_sprite"))

						lt_sobj.sprite.LUT = fp.costume      # stock_luts[fp->costume]

						lt_sobj.pos.x = ((gIFCommonPlayerInterface.player_pos_x[player] + dIFCommonPlayerStocksIconOffsetsX[player] + (stock_order * 10)) - (lt_sobj.sprite.width * 0.5))
						lt_sobj.pos.y = ((gIFCommonPlayerInterface.player_pos_y - int(lt_sobj.sprite.height * 0.5)) - 20)

						lt_sobj.sprite.attr &= ~SP_HIDDEN
					else:
						lt_sobj.sprite.attr |= SP_HIDDEN

					lt_sobj = lt_sobj.next

					stock_order += 1
			else:
				var r := ifCommonPlayerDamageGetSpecialArrayID(stock_count, [0, 0, 0])
				var digit_count: int = r.ret
				var digits: Array = r.digits
				var trunc_pos_x: int = gIFCommonPlayerInterface.player_pos_x[player] + dIFCommonPlayerStocksDigitOffsetsX[player]
				var gt_sobj = SObjGetStruct(interface_gobj)
				var digit_order := 0

				gt_sobj.sprite.copy_from(_port_ft_sprite(fp, "stock_sprite"))

				gt_sobj.sprite.LUT = fp.costume

				gt_sobj.pos.x = ((trunc_pos_x - 22) - (gt_sobj.sprite.width * 0.5))
				gt_sobj.pos.y = ((gIFCommonPlayerInterface.player_pos_y - int(gt_sobj.sprite.height * 0.5)) - 20)

				gt_sobj.sprite.attr &= ~SP_HIDDEN

				gt_sobj = gt_sobj.next

				gt_sobj.sprite.copy_from(_port_sprite(dIFCommonPlayerStockDigitSpriteOffsets[10]))

				gt_sobj.pos.x = ((trunc_pos_x + -10.5) - (gt_sobj.sprite.width * 0.5))
				gt_sobj.pos.y = ((gIFCommonPlayerInterface.player_pos_y - 20) - (gt_sobj.sprite.height * 0.5))

				gt_sobj.sprite.attr &= ~SP_HIDDEN

				gt_sobj = gt_sobj.next

				while gt_sobj != null:
					if digit_order < digit_count:
						gt_sobj.sprite.copy_from(_port_sprite(dIFCommonPlayerStockDigitSpriteOffsets[digits[digit_order]]))

						gt_sobj.pos.x = ((trunc_pos_x + (digit_order * 8)) - (gt_sobj.sprite.width * 0.5))
						gt_sobj.pos.y = ((gIFCommonPlayerInterface.player_pos_y - 20) - (gt_sobj.sprite.height * 0.5))

						gt_sobj.sprite.attr &= ~SP_HIDDEN
					else:
						gt_sobj.sprite.attr |= SP_HIDDEN

					gt_sobj = gt_sobj.next

					digit_order += 1
			# s8 store
			var v: int = stock_count & 0xFF
			sIFCommonPlayerStocksNum[player] = v - 0x100 if v >= 0x80 else v
		lbCommonDrawSObjAttr(interface_gobj)

## 0x8010FD2C
static func ifCommonPlayerStockSetIconAttr() -> void:
	for i in range(dIFCommonPlayerStockDigitSpriteOffsets.size()):
		_port_sprite(dIFCommonPlayerStockDigitSpriteOffsets[i]).attr = SP_TEXSHUF | SP_TRANSPARENT

## 0x8010FDD4
static func ifCommonPlayerStockMultiMakeInterface(player: int) -> void:
	var fp = ftGetStruct(G.gSCManagerBattleState.players[player].fighter_gobj)

	if _port_ft_sprites(fp) != null:   # (sprites != NULL) && (stock_sprite != NULL)
		var interface_gobj := _gcMakeGObjSPAfter(nGCCommonKindInterface, null, nGCCommonLinkIDInterface, GOBJ_PRIORITY_DEFAULT)
		var sprite: Sprite

		interface_gobj.port_kind = "stock"
		_gcAddGObjDisplay(interface_gobj, Callable(Ifcommon, &"ifCommonPlayerStockMultiProcDisplay"), 23, GOBJ_PRIORITY_DEFAULT, ~0)

		for i in 6:
			_lbCommonMakeSObjForGObj(interface_gobj, _port_sprite("llIFCommonDigits0Sprite"))

		sIFCommonPlayerStocksNum[player] = S8_MAX

		sprite = _port_ft_sprite(fp, "stock_sprite")
		sprite.attr = SP_TEXSHUF | SP_TRANSPARENT

		ifSetPlayer(interface_gobj, player)

## 0x8010FF24
static func ifCommonPlayerStockSingleProcDisplay(interface_gobj) -> void:
	var player: int = ifGetPlayer(interface_gobj)
	var stocks: int = G.gSCManagerBattleState.players[player].stock_count

	if stocks != -1:
		lbCommonDrawSObjAttr(interface_gobj)

## 0x8010FF78
static func ifCommonPlayerStockSetLUT(player: int, lut_id: int, attr = null) -> void:
	SObjGetStruct(sIFCommonPlayerStocksGObj[player]).sprite.LUT = lut_id   # attr->sprites->stock_luts[lut_id]

## 0x8010FFA8
static func ifCommonPlayerStockSingleMakeInterface(player: int) -> void:
	var fp = ftGetStruct(G.gSCManagerBattleState.players[player].fighter_gobj)

	if _port_ft_sprites(fp) != null:
		var interface_gobj := _gcMakeGObjSPAfter(nGCCommonKindInterface, null, nGCCommonLinkIDInterface, GOBJ_PRIORITY_DEFAULT)
		var sobj: SObj

		sIFCommonPlayerStocksGObj[player] = interface_gobj
		interface_gobj.port_kind = "stock"

		_gcAddGObjDisplay(interface_gobj, Callable(Ifcommon, &"ifCommonPlayerStockSingleProcDisplay"), 23, GOBJ_PRIORITY_DEFAULT, ~0)

		sobj = _lbCommonMakeSObjForGObj(interface_gobj, _port_ft_sprite(fp, "stock_sprite"))

		sobj.sprite.attr = SP_TEXSHUF | SP_TRANSPARENT
		sobj.sprite.LUT = fp.costume

		sobj.pos.x = ((gIFCommonPlayerInterface.player_pos_x[player] + dIFCommonPlayerStocksIconOffsetsX[player]) - int(sobj.sprite.width * 0.5))
		sobj.pos.y = ((gIFCommonPlayerInterface.player_pos_y - int(sobj.sprite.height * 0.5)) - 20)

		ifSetPlayer(interface_gobj, player)

## 0x80110138
static func ifCommonPlayerStockStealProcUpdate(interface_gobj) -> void:
	var s_steal: IFPlayerSteal = sIFCommonPlayerStealInterface[ifGetPlayer(interface_gobj)]
	var sobj
	var dist_x: float
	var vel_x: float
	var vel_y: float

	s_steal.anim_frames = (s_steal.anim_frames - 1) & 0xFF

	if s_steal.anim_frames == 0:
		Efmanager.efManagerStockStealEndMakeEffect(
			gIFCommonPlayerInterface.player_pos_x[ifGetPlayer(interface_gobj)] + dIFCommonPlayerStocksIconOffsetsX[ifGetPlayer(interface_gobj)],
			gIFCommonPlayerInterface.player_pos_y - 20
		)
		_gcEjectGObj(interface_gobj)
		return
	sobj = SObjGetStruct(interface_gobj)

	dist_x = (s_steal.steal_pos_x - s_steal.target_pos_x)

	vel_x = (s_steal.anim_frames * dist_x) / 30.0

	if vel_x < (dist_x * 0.5):
		vel_y = -(vel_x - (dist_x * 0.5))
	else:
		vel_y = (vel_x - (dist_x * 0.5))

	sobj.pos.x = (s_steal.target_pos_x + vel_x)
	sobj.pos.y = ((s_steal.steal_pos_y + ((15.0 / SQUARE(dist_x * 0.5)) * vel_y * vel_y)) - 15.0)

## 0x801102B0
static func ifCommonPlayerStockStealMakeInterface(thief: int, stolen: int) -> void:
	var fp = ftGetStruct(G.gSCManagerBattleState.players[stolen].fighter_gobj)
	var interface_gobj := _gcMakeGObjSPAfter(nGCCommonKindInterface, null, nGCCommonLinkIDInterface, GOBJ_PRIORITY_DEFAULT)

	if interface_gobj != null:
		var check_sobj
		var sobj
		var st: IFPlayerSteal = sIFCommonPlayerStealInterface[thief]

		interface_gobj.port_kind = "steal"
		_gcAddGObjDisplay(interface_gobj, Callable(Ifcommon, &"lbCommonDrawSObjAttr"), 23, GOBJ_PRIORITY_DEFAULT, ~0)
		Objman.gcAddGObjProcess(interface_gobj, Callable(Ifcommon, &"ifCommonPlayerStockStealProcUpdate"), nGCProcessKindFunc, 0)

		check_sobj = _lbCommonMakeSObjForGObj(interface_gobj, _port_ft_sprite(fp, "stock_sprite"))

		if check_sobj == null:
			_gcEjectGObj(interface_gobj)
			return
		else:
			sobj = check_sobj

			sobj.sprite.attr = SP_TEXSHUF | SP_TRANSPARENT
			sobj.sprite.LUT = fp.costume

			st.steal_pos_x = ((gIFCommonPlayerInterface.player_pos_x[stolen] + dIFCommonPlayerStocksIconOffsetsX[stolen]) - int(sobj.sprite.width * 0.5)) & 0xFFFF
			st.steal_pos_y = ((gIFCommonPlayerInterface.player_pos_y - int(sobj.sprite.height * 0.5)) - 20) & 0xFFFF

			st.target_pos_x = ((gIFCommonPlayerInterface.player_pos_x[thief] + dIFCommonPlayerStocksIconOffsetsX[thief]) - int(sobj.sprite.width * 0.5)) & 0xFFFF

			sobj.pos.x = st.steal_pos_x
			sobj.pos.y = st.steal_pos_y

			st.anim_frames = 30

			ifSetPlayer(interface_gobj, thief)

			Efmanager.efManagerStockStealStartMakeEffect(gIFCommonPlayerInterface.player_pos_x[stolen] + dIFCommonPlayerStocksIconOffsetsX[stolen], gIFCommonPlayerInterface.player_pos_y - 20)

## 0x80110514
static func ifCommonPlayerStockInitInterface() -> void:
	ifCommonPlayerStockSetIconAttr()

	for player in range(G.gSCManagerBattleState.players.size()):
		if G.gSCManagerBattleState.players[player].pkind != nFTPlayerKindNot:
			var single: int = int(G.gSCManagerBattleState.players[player].is_single_stockicon)
			if single == FALSE:
				ifCommonPlayerStockMultiMakeInterface(player)
			elif single == TRUE:
				ifCommonPlayerStockSingleMakeInterface(player)

## 0x801105CC - magnify_pos (Vec2f*) out-parameter -> returns the Vector2
static func ifCommonPlayerMagnifyGetPosition(player_pos_x: float, player_pos_y: float, magnify_pos: Vector2 = Vector2.ZERO) -> Vector2:
	var cam = Gmcamera.gGMCameraStruct
	var scale: float = gIFCommonPlayerInterface.magnify_scale
	var left: float = (-cam.viewport_width / 2) + (20 * scale) + 5
	var right: float = (+cam.viewport_width / 2) - (20 * scale) - 5
	var bak_right: float = right
	var up: float = (+cam.viewport_height / 2) - (20 * scale)
	var bak_up: float = up
	var down: float = (-cam.viewport_height / 2) + (20 * scale)

	if player_pos_x == 0.0:
		up = bak_up

		if player_pos_y > 0.0:
			magnify_pos.y = up
		else:
			magnify_pos.y = down

		magnify_pos.x = 0.0
	else:
		var div_xy: float = player_pos_y / player_pos_x

		if ((up / right) < div_xy) or (-(up / right) > div_xy):
			up = bak_up

			if player_pos_y > 0.0:
				magnify_pos.y = up
			else:
				magnify_pos.y = down

			var diag_hz: float = (magnify_pos.y * player_pos_x) / player_pos_y

			right = bak_right

			if diag_hz < left:
				magnify_pos.x = left
			elif diag_hz > right:
				magnify_pos.x = right
			else:
				magnify_pos.x = diag_hz
		else:
			right = bak_right

			if player_pos_x > 0.0:
				magnify_pos.x = right
			else:
				magnify_pos.x = left

			var diag_vt: float = (magnify_pos.x * player_pos_y) / player_pos_x

			up = bak_up

			if diag_vt < down:
				magnify_pos.y = down
			elif diag_vt > up:
				magnify_pos.y = up
			else:
				magnify_pos.y = diag_vt
	return magnify_pos

## 0x801107F0 - GBI texture rectangles of the magnifier background; returns the port render rect.
static func ifCommonPlayerMagnifyUpdateRender(dls, color_id: int, ulx: float, uly: float) -> Array:
	var cam = Gmcamera.gGMCameraStruct
	var temp_f0: float = int((1024.0 / gIFCommonPlayerInterface.magnify_scale) + 0.5) if gIFCommonPlayerInterface.magnify_scale != 0.0 else 0.0
	var var_ulx: int = int(ulx)
	var var_uly: int = int(uly)
	var var_lrx: int = (0 if (ulx == var_ulx) else 1) + int(ulx + (32.0 * gIFCommonPlayerInterface.magnify_scale))
	var var_lry: int = (0 if (uly == var_uly) else 1) + int(uly + (32.0 * gIFCommonPlayerInterface.magnify_scale))

	if var_ulx < cam.viewport_ulx:
		var_ulx = cam.viewport_ulx
	elif var_lrx >= cam.viewport_lrx:
		var_lrx = cam.viewport_lrx - 1
	if var_uly < cam.viewport_uly:
		var_uly = cam.viewport_uly
	elif var_lry >= cam.viewport_lry:
		var_lry = cam.viewport_lry - 1
	# gSPTextureRectangle(var_ulx*4, var_uly*4, var_lrx*4, var_lry*4, s, t, temp_f0, temp_f0) x2
	# (fog colour prim + dIFCommonPlayerMagnifyColors env)
	return [var_ulx, var_uly, var_lrx, var_lry]

## 0x80110DD4
static func ifCommonPlayerMagnifyUpdateViewport(dls, fp) -> void:
	if gIFCommonPlayerInterface.is_magnify_display != FALSE:
		var cam = Gmcamera.gGMCameraStruct
		var ifmag: IFPlayerMagnify = sIFCommonPlayerMagnifyInterface[fp.player]
		var magnify_x: float = fp.magnify_pos.x
		var magnify_y: float = fp.magnify_pos.y
		var scale: float
		var ulx: int
		var uly: int
		var lrx: int
		var lry: int

		ifmag.pos = ifCommonPlayerMagnifyGetPosition(magnify_x, magnify_y, ifmag.pos)

		magnify_x = ifmag.pos.x + cam.viewport_center_x
		magnify_y = cam.viewport_center_y - ifmag.pos.y

		# gSPMatrix(projection)
		if gIFCommonPlayerInterface.magnify_mode != 1:
			pass    # gSPViewport / gDPSetScissor (main camera viewport)
		else:
			gIFCommonPlayerInterface.magnify_mode = 2

		scale = (16.0 * gIFCommonPlayerInterface.magnify_scale)

		ifmag.port_rect = ifCommonPlayerMagnifyUpdateRender(dls, ifmag.color_id, magnify_x - scale, magnify_y - scale)
		ifmag.port_screen_pos = Vector2(magnify_x, magnify_y)

		scale = (18.0 * gIFCommonPlayerInterface.magnify_scale)

		magnify_x -= (scale / 2)
		magnify_y -= (scale / 2)

		_port_syRdpSetViewport(ifmag.viewport, magnify_x, magnify_y, scale + magnify_x, scale + magnify_y)

		ulx = (ifmag.viewport.vp.vtrans[0] / 4) - (ifmag.viewport.vp.vscale[0] / 4)
		uly = (ifmag.viewport.vp.vtrans[1] / 4) - (ifmag.viewport.vp.vscale[1] / 4)
		lrx = (ifmag.viewport.vp.vtrans[0] / 4) + (ifmag.viewport.vp.vscale[0] / 4)
		lry = (ifmag.viewport.vp.vtrans[1] / 4) + (ifmag.viewport.vp.vscale[1] / 4)

		if ulx < cam.viewport_ulx:
			ulx = cam.viewport_ulx
		if lrx > cam.viewport_lrx:
			lrx = cam.viewport_lrx
		if uly < cam.viewport_uly:
			uly = cam.viewport_uly
		elif lry > cam.viewport_lry:
			lry = cam.viewport_lry
		ifmag.port_viewport_rect = [ulx, uly, lrx, lry]   # gDPSetScissor

## syRdpSetViewport (src/sys/rdp.c; Vp_t shorts)
static func _port_syRdpSetViewport(viewport: Dictionary, ulx: float, uly: float, lrx: float, lry: float) -> void:
	var h: float = (ulx + lrx) / 2.0
	var v: float = (uly + lry) / 2.0
	viewport.vp.vscale[0] = _s16(int((lrx - h) * 4.0) & 0xFFFF)
	viewport.vp.vscale[1] = _s16(int((lry - v) * 4.0) & 0xFFFF)
	viewport.vp.vtrans[0] = _s16(int(h * 4.0) & 0xFFFF)
	viewport.vp.vtrans[1] = _s16(int(v * 4.0) & 0xFFFF)
	viewport.vp.vscale[2] = 0x3FF / 2
	viewport.vp.vtrans[2] = 0x3FF / 2

static func _s16(v: int) -> int:
	v &= 0xFFFF
	return v - 0x10000 if v >= 0x8000 else v

## 0x801111A0
static func ifCommonPlayerMagnifyProcDisplay(fp) -> void:
	if gIFCommonPlayerInterface.is_magnify_display != FALSE:
		var ifmag: IFPlayerMagnify = sIFCommonPlayerMagnifyInterface[fp.player]
		var interface_gobj = ifmag.interface_gobj
		var dobj: DObj = DObjGetStruct(interface_gobj)

		dobj.translate.x = ifmag.pos.x
		dobj.translate.y = ifmag.pos.y

		dobj.rotate.z = syUtilsArcTan2(fp.magnify_pos.y, fp.magnify_pos.x) - F_CST_DTOR32(90.0)

		dobj.scale.x = gIFCommonPlayerInterface.magnify_scale * 0.5
		dobj.scale.y = gIFCommonPlayerInterface.magnify_scale * 0.5

		# gSPViewport / gDPSetScissor / gDPSetPrimColor(dIFCommonPlayerMagnifyColors[color_id]); gcDrawDObjDLHead0
		ifmag.port_frame_drawn = port_frame

## 0x80111440
static func ifCommonPlayerMagnifyMakeInterface() -> void:
	for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter).duplicate():
		var fp = ftGetStruct(fighter_gobj)
		var interface_gobj := _gcMakeGObjSPAfter(nGCCommonKindInterface, null, nGCCommonLinkIDMagnify, GOBJ_PRIORITY_DEFAULT)

		interface_gobj.port_kind = "magnify"
		Objman.gcAddXObjForDObjFixed(Objman.gcAddDObjForGObj(interface_gobj, "llIFCommonPlayerMagnifyDisplayList"), nGCMatrixKindTraRotRpyRSca, 0)

		sIFCommonPlayerMagnifyInterface[fp.player].interface_gobj = interface_gobj
		sIFCommonPlayerMagnifyInterface[fp.player].color_id = G.gSCManagerBattleState.players[fp.player].color
	gIFCommonPlayerInterface.is_magnify_display = FALSE

## 0x80111554
static func ifCommonPlayerArrowsLeftProcDisplay(interface_gobj) -> void:
	if gIFCommonPlayerInterface.arrows_flags & 1:
		interface_gobj.thread["port_drawn"] = port_frame     # gcDrawDObjTreeForGObj

## 0x80111588
static func ifCommonPlayerArrowsRightProcDisplay(interface_gobj) -> void:
	if gIFCommonPlayerInterface.arrows_flags & 2:
		interface_gobj.thread["port_drawn"] = port_frame

## 0x801115BC - gcAddAnimJointAll(llIFCommonPlayerArrowsAnimJoint, 0.0) + gcPlayAnimAll.
## The arrows AnimJoint is ROM data (visual bounce); the port keeps its frame counter only.
static func ifCommonPlayerArrowsAddAnim(interface_gobj) -> void:
	interface_gobj.anim_frame = 0.0
	_port_arrows_play_anim(interface_gobj)

static func _port_arrows_play_anim(interface_gobj) -> void:
	interface_gobj.anim_frame += 1.0

## 0x801115FC
static func ifCommonPlayerArrowsLeftProcUpdate(interface_gobj) -> void:
	match gIFCommonPlayerInterface.arrows_left_status:
		0:
			pass
		1:
			ifCommonPlayerArrowsAddAnim(interface_gobj)
			_port_arrows_play_anim(interface_gobj)     # fallthrough
		_:
			_port_arrows_play_anim(interface_gobj)

## 0x80111640
static func ifCommonPlayerArrowsRightProcUpdate(interface_gobj) -> void:
	match gIFCommonPlayerInterface.arrows_right_status:
		0:
			pass
		1:
			ifCommonPlayerArrowsAddAnim(interface_gobj)
			_port_arrows_play_anim(interface_gobj)     # fallthrough
		_:
			_port_arrows_play_anim(interface_gobj)

## 0x80111684
static func ifCommonPlayerArrowsMakeInterface(proc_display: Callable, proc_update: Callable) -> IFGObj:
	var interface_gobj := _gcMakeGObjSPAfter(nGCCommonKindInterface, null, nGCCommonLinkIDInterface, GOBJ_PRIORITY_DEFAULT)

	interface_gobj.port_kind = "arrow"
	_gcAddGObjDisplay(interface_gobj, proc_display, 8, GOBJ_PRIORITY_DEFAULT, ~0)
	# gcSetupCustomDObjs(llIFCommonPlayerArrowsDObjDesc, nGCMatrixKindTraRotRpyR)
	Objman.gcAddDObjForGObj(interface_gobj, "llIFCommonPlayerArrowsDObjDesc")
	Objman.gcAddGObjProcess(interface_gobj, proc_update, nGCProcessKindFunc, 5)

	return interface_gobj

## 0x8011171C
static func ifCommonPlayerArrowsFuncRun(interface_gobj) -> void:
	var lr_right := FALSE
	var lr_left := FALSE

	if gIFCommonPlayerInterface.is_magnify_display != FALSE:
		for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
			var fp = ftGetStruct(fighter_gobj)

			if not B(fp.is_magnify_ignore) and not B(fp.is_rebirth) and B(fp.is_magnify_show):
				if ABSF(fp.magnify_pos.x) > ABSF(fp.magnify_pos.y):
					if fp.magnify_pos.x < 0.0:
						lr_left = TRUE
					else:
						lr_right = TRUE
		if lr_left == FALSE:
			gIFCommonPlayerInterface.arrows_left_status = 0
		elif gIFCommonPlayerInterface.arrows_left_status == 0:
			gIFCommonPlayerInterface.arrows_left_status = 1
		else:
			gIFCommonPlayerInterface.arrows_left_status = 2

		if lr_right == FALSE:
			gIFCommonPlayerInterface.arrows_right_status = 0
		elif gIFCommonPlayerInterface.arrows_right_status == 0:
			gIFCommonPlayerInterface.arrows_right_status = 1
		else:
			gIFCommonPlayerInterface.arrows_right_status = 2
	if (lr_left != FALSE) or (lr_right != FALSE):
		if sIFCommonPlayerMagnifySoundWait == 0:
			Snd.func_800269C0_275C0(nSYAudioFGMMagnify)

			sIFCommonPlayerMagnifySoundWait = 30
		sIFCommonPlayerMagnifySoundWait = (sIFCommonPlayerMagnifySoundWait - 1) & 0xFF
	else:
		sIFCommonPlayerMagnifySoundWait = 0

## 0x801118B4
static func ifCommonPlayerArrowsMainProcDisplay(interface_gobj) -> void:
	pass    # gSPDisplayList(dIFCommonPlayerArrowsDisplayList): red, alpha 0x80

## 0x801118E4
static func ifCommonPlayerArrowsInitInterface() -> void:
	var main_gobj := _gcMakeGObjSPAfter(nGCCommonKindInterface, Callable(Ifcommon, &"ifCommonPlayerArrowsFuncRun"), nGCCommonLinkIDInterface, GOBJ_PRIORITY_DEFAULT)
	var dobj: DObj

	_gcAddGObjDisplay(main_gobj, Callable(Ifcommon, &"ifCommonPlayerArrowsMainProcDisplay"), 8, GOBJ_PRIORITY_DEFAULT, ~0)

	var left_gobj := ifCommonPlayerArrowsMakeInterface(Callable(Ifcommon, &"ifCommonPlayerArrowsLeftProcDisplay"), Callable(Ifcommon, &"ifCommonPlayerArrowsLeftProcUpdate"))
	left_gobj.port_kind = "arrow_left"
	dobj = DObjGetStruct(left_gobj)

	dobj.translate.x = -134.0
	dobj.translate.y = 0.0

	gIFCommonPlayerInterface.arrows_left_status = 0

	var right_gobj := ifCommonPlayerArrowsMakeInterface(Callable(Ifcommon, &"ifCommonPlayerArrowsRightProcDisplay"), Callable(Ifcommon, &"ifCommonPlayerArrowsRightProcUpdate"))
	right_gobj.port_kind = "arrow_right"
	dobj = DObjGetStruct(right_gobj)

	dobj.translate.x = 134.0
	dobj.translate.y = 0.0
	dobj.rotate.z = F_CST_DTOR32(180.0)

	gIFCommonPlayerInterface.arrows_right_status = 0

	sIFCommonPlayerMagnifySoundWait = 0

## 0x801119AC
static func ifCommonPlayerArrowsUpdateFlags(x: float, y: float) -> void:
	if ABSF(x) > ABSF(y):
		if x > 0.0:
			gIFCommonPlayerInterface.arrows_flags |= IFCOMMON_PLAYERARROWS_MASK_RIGHT
		else:
			gIFCommonPlayerInterface.arrows_flags |= IFCOMMON_PLAYERARROWS_MASK_LEFT

## 0x80111A3C
static func ifCommonPlayerTagProcDisplay(interface_gobj) -> void:
	var player: int = ifGetPlayer(interface_gobj)
	var fp = ftGetStruct(G.gSCManagerBattleState.players[player].fighter_gobj)

	if not B(fp.is_playertag_bossend) and not B(fp.is_playertag_hide):
		var cobj = Gmcamera.CObjGetStruct(Gmcamera.gGMCameraGObj)

		if (fp.playertag_wait == 1) or ((cobj != null) and (cobj.vec.eye.z > 6000.0)):
			var pos: Vector3 = fp.joints[nFTPartsJointTopN].translate
			var xy: Vector2

			pos.y += fp.attr.camera_zoom_base

			xy = _port_project(pos)

			if Gmcamera.gmCameraCheckTargetInBounds(xy.x, xy.y) != FALSE:
				var sobj = SObjGetStruct(interface_gobj)
				sobj.pos.x = int((Gmcamera.gGMCameraStruct.viewport_center_x + xy.x) - (sobj.sprite.width * 0.5))
				sobj.pos.y = int((Gmcamera.gGMCameraStruct.viewport_center_y - xy.y) - sobj.sprite.height)

				lbCommonDrawSObjAttr(interface_gobj)
				interface_gobj.thread["port_drawn"] = port_frame

## 0x80111BE4
static func ifCommonPlayerTagMakeInterface() -> void:
	for player in range(G.gSCManagerBattleState.players.size()):
		if G.gSCManagerBattleState.players[player].pkind != nFTPlayerKindNot:
			var interface_gobj := _gcMakeGObjSPAfter(nGCCommonKindInterface, null, nGCCommonLinkIDInterface, GOBJ_PRIORITY_DEFAULT)
			var sobj: SObj
			var color_id: int

			interface_gobj.port_kind = "tag"
			_gcAddGObjDisplay(interface_gobj, Callable(Ifcommon, &"ifCommonPlayerTagProcDisplay"), 23, GOBJ_PRIORITY_DEFAULT, ~0)

			sobj = _lbCommonMakeSObjForGObj(interface_gobj, _port_sprite(dIFCommonPlayerTagSpriteOffsets[G.gSCManagerBattleState.players[player].tag]))

			sobj.sprite.attr = SP_TEXSHUF | SP_TRANSPARENT

			color_id = G.gSCManagerBattleState.players[player].color & 0xFF

			sobj.sprite.red = dIFCommonPlayerTagPrimColorsR[color_id]
			sobj.sprite.green = dIFCommonPlayerTagPrimColorsG[color_id]
			sobj.sprite.blue = dIFCommonPlayerTagPrimColorsB[color_id]

			sobj.envcolor.r = dIFCommonPlayerTagEnvColorsR[color_id]
			sobj.envcolor.g = dIFCommonPlayerTagEnvColorsG[color_id]
			sobj.envcolor.b = dIFCommonPlayerTagEnvColorsB[color_id]

			ifSetPlayer(interface_gobj, player)

## 0x80111D64
static func ifCommonItemArrowProcDisplay(interface_gobj) -> void:
	var ip = interface_gobj.user_data       # itGetStruct(interface_gobj)

	if B(ip.is_allow_pickup) and (ip.arrow_timer >= 15):
		var sobj = SObjGetStruct(interface_gobj)
		var pos: Vector3 = DObjGetStruct(ip.item_gobj).translate
		var xy: Vector2

		pos.y += ip.coll_data.map_coll.top + 100.0

		xy = _port_project(pos)

		if Gmcamera.gmCameraCheckTargetInBounds(xy.x, xy.y) != FALSE:
			sobj.pos.x = int((Gmcamera.gGMCameraStruct.viewport_center_x + xy.x) - (sobj.sprite.width * 0.5))
			sobj.pos.y = int((Gmcamera.gGMCameraStruct.viewport_center_y - xy.y) - sobj.sprite.height)

			lbCommonDrawSObjAttr(interface_gobj)

## 0x80111EC0
static func ifCommonItemArrowMakeInterface(ip):
	var interface_gobj := _gcMakeGObjSPAfter(nGCCommonKindInterface, null, nGCCommonLinkIDInterface, GOBJ_PRIORITY_DEFAULT)

	if interface_gobj != null:
		interface_gobj.port_kind = "item_arrow"
		_gcAddGObjDisplay(interface_gobj, Callable(Ifcommon, &"ifCommonItemArrowProcDisplay"), 23, GOBJ_PRIORITY_DEFAULT, ~0)

		if sIFCommonItemArrowSprite == null:
			ifCommonItemArrowSetAttr()       # port: the sprite is loaded by itManagerInitItems in C
		if _lbCommonMakeSObjForGObj(interface_gobj, sIFCommonItemArrowSprite) != null:
			interface_gobj.user_data = ip

			if (G.gSCManagerSceneData.scene_curr == nSCKind1PTrainingMode) and (G.gSCManagerBattleState.game_status == nSCBattleGameStatusPause):
				interface_gobj.gobj_flags = GOBJ_FLAG_HIDDEN
			return interface_gobj
		else:
			_gcEjectGObj(interface_gobj)
	return null

## 0x80111F80
static func ifCommonItemArrowSetAttr() -> void:
	# lbRelocGetExternHeapFile(llIFCommonItemFileID) -> llIFCommonItemArrowSprite
	var sprite := _port_sprite("llIFCommonItemArrowSprite")
	sIFCommonItemArrowSprite = sprite

	sprite.attr = SP_TEXSHUF | SP_TRANSPARENT

	sprite.red = 0xFF
	sprite.green = 0x00
	sprite.blue = 0x00

## 0x80111FF0
static func ifCommonAnnounceThread(interface_gobj) -> void:
	var th := _th_state(interface_gobj)
	if not _th_wake(th):
		return
	match th.pc:
		0:
			_th_sleep(th, 60, 1)
		1:
			_gcEjectGObj(null)
			_th_sleep(th, 1, 2)

## 0x80112024
static func ifCommonAnnounceSetAttr(interface_gobj, file_id: int, character: Array, sprite_count: int) -> void:
	for i in range(sprite_count):
		var sobj := _lbCommonMakeSObjForGObj(interface_gobj, _port_sprite(character[i][2]))

		sobj.sprite.attr = SP_TEXSHUF | SP_TRANSPARENT

		sobj.pos.x = character[i][0]
		sobj.pos.y = character[i][1]

## 0x801120D4
static func ifCommonAnnounceGoMakeInterface() -> void:
	var interface_gobj := _gcMakeGObjSPAfter(nGCCommonKindInterface, null, nGCCommonLinkIDInterface, GOBJ_PRIORITY_DEFAULT)

	interface_gobj.port_kind = "go"
	_gcAddGObjDisplay(interface_gobj, Callable(Ifcommon, &"lbCommonDrawSObjAttr"), 23, GOBJ_PRIORITY_DEFAULT, ~0)
	Objman.gcAddGObjProcess(interface_gobj, Callable(Ifcommon, &"ifCommonAnnounceThread"), nGCProcessKindThread, 5)

	for i in range(dIFCommonAnnounceGoSpriteData.size()):
		var sobj := _lbCommonMakeSObjForGObj(interface_gobj, _port_sprite(dIFCommonAnnounceGoSpriteData[i][2]))

		sobj.sprite.attr = SP_CLOUD | SP_TEXSHUF

		sobj.pos.x = dIFCommonAnnounceGoSpriteData[i][0]
		sobj.pos.y = dIFCommonAnnounceGoSpriteData[i][1]

## 0x801121C4
static func ifCommonAnnounceGoSetStatus() -> void:
	for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter).duplicate():
		var fp = ftGetStruct(fighter_gobj)

		Ftparam.ftParamUnlockPlayerControl(fighter_gobj)

		fp.camera_mode = nFTCameraModeDefault
	G.gSCManagerBattleState.game_status = nSCBattleGameStatusGo

	gIFCommonPlayerInterface.is_magnify_display = TRUE

## 0x80112234
static func ifCommonTrafficMakeSObj(interface_gobj, id: int) -> SObj:
	var color_id: int = dIFCommonTrafficSpriteData[id][2]
	var sobj := _lbCommonMakeSObjForGObj(interface_gobj, _port_sprite(dIFCommonTrafficSpriteOffsets[color_id]))

	sobj.sprite.attr = SP_CLOUD | SP_TEXSHUF

	sobj.pos.x = dIFCommonTrafficSpriteData[id][0]
	sobj.pos.y = dIFCommonTrafficSpriteData[id][1]

	sobj.sprite.red = dIFCommonTrafficSpriteColorsR[color_id]
	sobj.sprite.green = dIFCommonTrafficSpriteColorsG[color_id]
	sobj.sprite.blue = dIFCommonTrafficSpriteColorsB[color_id]

	return sobj

## 0x801122F4 - GObjThread as a state machine (pc = resume point after each gcSleepCurrentGObjThread)
static func ifCommonCountdownThread(interface_gobj) -> void:
	var th := _th_state(interface_gobj)
	if not th.has("timer"):
		th["timer"] = 0
		th["main_status"] = -1
		th["lamp_status"] = -1
		th["scale"] = 0.0
		th["sobj"] = null
		th["child_sobj"] = null
	if not _th_wake(th):
		return
	while true:
		var pc: int = th.pc
		if pc == 0:                                 # for (timer = 0; timer < 60; timer++)
			if th.timer < 60:
				var sobj = SObjGetStruct(interface_gobj)
				while sobj != null:
					sobj.pos.y += 0.8833333
					sobj = sobj.next
				_th_sleep(th, 1, 1)
				return
			th.pc = 2
		elif pc == 1:
			th.timer += 1
			th.pc = 0
		elif pc == 2:
			th.sobj = ifGetSObj(interface_gobj)
			th.main_status = -1
			th.lamp_status = -1
			th.child_sobj = th.sobj.next.next
			th.pc = 3
		elif pc == 3:                               # while (TRUE)
			var timer: int = th.timer
			if timer == I_SEC_TO_TICS(2):
				th.main_status = 6
				th.lamp_status = 6
				Snd.func_800269C0_275C0(nSYAudioVoiceAnnounceThree)
			elif timer == I_SEC_TO_TICS(3):
				th.main_status = 7
				th.lamp_status = 7
				Snd.func_800269C0_275C0(nSYAudioVoiceAnnounceTwo)
			elif timer == I_SEC_TO_TICS(4):
				th.main_status = 8
				th.lamp_status = 8
				Snd.func_800269C0_275C0(nSYAudioVoiceAnnounceOne)
			elif timer == I_SEC_TO_TICS(5):
				ifCommonAnnounceGoMakeInterface()
				ifCommonAnnounceGoSetStatus()
				ifCommonPlayerDamageSetShowInterface()

				th.main_status = 9
				th.lamp_status = 9

				Snd.func_800269C0_275C0(nSYAudioVoiceAnnounceGo)
			elif timer == I_SEC_TO_TICS(6):
				th.pc = 5                           # goto finish
				continue
			if th.lamp_status != -1:
				var lamp_status: int = th.lamp_status
				if th.main_status != -1:
					_gcEjectSObj(th.sobj.next)
					_gcEjectSObj(th.sobj)

					th.sobj = ifCommonTrafficMakeSObj(interface_gobj, lamp_status)
					th.scale = 3.0
					th.sobj.sprite.scalex = 3.0
					th.sobj.sprite.scaley = 3.0

					var new_sobj := ifCommonTrafficMakeSObj(interface_gobj, lamp_status + 5)

					if lamp_status == 9:
						var child_sobj = th.child_sobj
						var other_sobj = child_sobj.prev

						child_sobj.sprite.red = dIFCommonTrafficGoBacklightR[1]
						child_sobj.sprite.green = dIFCommonTrafficGoBacklightG[1]
						child_sobj.sprite.blue = dIFCommonTrafficGoBacklightB[1]

						child_sobj.envcolor.r = dIFCommonTrafficGoShadowR[1]
						child_sobj.envcolor.g = dIFCommonTrafficGoShadowG[1]
						child_sobj.envcolor.b = dIFCommonTrafficGoShadowB[1]

						if other_sobj != null:
							other_sobj.next = child_sobj.next
						other_sobj = child_sobj.next

						if other_sobj != null:
							other_sobj.prev = child_sobj.prev
						new_sobj.next = child_sobj

						child_sobj.prev = new_sobj
						child_sobj.next = null
				if th.scale != 1.0:
					var rscale: float

					th.scale -= 0.2

					if th.scale < 1.0:
						th.scale = 1.0
					th.sobj.sprite.scalex = th.scale
					th.sobj.sprite.scaley = th.scale

					rscale = (th.scale - 1.0) * 0.5

					th.sobj.pos.x = dIFCommonTrafficSpriteData[lamp_status][0] - (rscale * th.sobj.sprite.width)
					th.sobj.pos.y = dIFCommonTrafficSpriteData[lamp_status][1] - (rscale * th.sobj.sprite.height)
			th.timer += 1
			_th_sleep(th, 1, 4)
			return
		elif pc == 4:
			th.main_status = -1
			th.pc = 3
		elif pc == 5:                               # finish: for (; timer < I_SEC_TO_TICS(7); timer++)
			if th.timer < I_SEC_TO_TICS(7):
				var sobj = SObjGetStruct(interface_gobj)
				while sobj != null:
					sobj.pos.y += (-0.8833333)
					sobj = sobj.next
				_th_sleep(th, 1, 6)
				return
			_gcEjectGObj(null)
			_th_sleep(th, 1, 7)
			return
		elif pc == 6:
			th.timer += 1
			th.pc = 5
		else:
			return

## 0x80112668
static func ifCommonCountdownMakeInterface() -> SObj:
	var interface_gobj := _gcMakeGObjSPAfter(nGCCommonKindInterface, null, nGCCommonLinkIDInterface, GOBJ_PRIORITY_DEFAULT)
	var sobj: SObj

	interface_gobj.port_kind = "ready"
	_gcAddGObjDisplay(interface_gobj, Callable(Ifcommon, &"lbCommonDrawSObjAttr"), 23, GOBJ_PRIORITY_DEFAULT, ~0)
	Objman.gcAddGObjProcess(interface_gobj, Callable(Ifcommon, &"ifCommonCountdownThread"), nGCProcessKindThread, 5)

	sobj = _lbCommonMakeSObjForGObj(interface_gobj, _port_sprite("llIFCommonGameStatusRodSprite"))

	sobj.sprite.attr = SP_TEXSHUF | SP_TRANSPARENT

	sobj.pos.x = 103.0
	sobj.pos.y = -57.0

	sobj = _lbCommonMakeSObjForGObj(interface_gobj, _port_sprite("llIFCommonGameStatusFrameSprite"))

	sobj.sprite.attr = SP_TEXSHUF | SP_TRANSPARENT

	sobj.pos.x = 111.0
	sobj.pos.y = -23.0

	for i in 6:
		sobj = ifCommonTrafficMakeSObj(interface_gobj, i)
	ifSetSObj(interface_gobj, sobj)

	ifCommonTrafficMakeSObj(interface_gobj, 10)

	sobj = _lbCommonMakeSObjForGObj(interface_gobj, _port_sprite("llIFCommonGameStatusRodShadowSprite"))

	sobj.sprite.attr = SP_TEXSHUF | SP_TRANSPARENT

	sobj.pos.x = 182.0
	sobj.pos.y = -11.0

	sobj.sprite.red = dIFCommonTrafficGoBacklightR[0]
	sobj.sprite.green = dIFCommonTrafficGoBacklightG[0]
	sobj.sprite.blue = dIFCommonTrafficGoBacklightB[0]
	sobj.envcolor.r = dIFCommonTrafficGoShadowR[0]
	sobj.envcolor.g = dIFCommonTrafficGoShadowG[0]
	sobj.envcolor.b = dIFCommonTrafficGoShadowB[0]

	return sobj

## 0x80112814
static func ifCommonAnnounceTimeUpMakeInterface() -> IFGObj:
	var interface_gobj := _gcMakeGObjSPAfter(nGCCommonKindInterface, null, nGCCommonLinkIDInterface, GOBJ_PRIORITY_DEFAULT)

	interface_gobj.port_kind = "timeup"
	_gcAddGObjDisplay(interface_gobj, Callable(Ifcommon, &"lbCommonDrawSObjAttr"), 23, GOBJ_PRIORITY_DEFAULT, ~0)

	ifCommonAnnounceSetAttr(interface_gobj, 1, dIFCommonAnnounceTimeUpSpriteData, dIFCommonAnnounceTimeUpSpriteData.size())

	return interface_gobj

## 0x80112880
static func ifCommonEntryFocusThread(interface_gobj) -> void:
	var th := _th_state(interface_gobj)
	if not _th_wake(th):
		return
	while true:
		var pc: int = th.pc
		if pc == 0:
			th["id"] = interface_gobj.user_data
			th["sleep_tics"] = dIFCommonEntryFocusSleepTics[th.id]
			th["fighter_gobj"] = null
			if th.id == 1:
				_th_sleep(th, 90, 1)
				return
			th.pc = 1
		elif pc == 1:
			var count: int = G.gSCManagerBattleState.pl_count + G.gSCManagerBattleState.cp_count

			if count < 3:
				_th_sleep(th, th.sleep_tics, 2)
				return
			th.pc = 2
		elif pc == 2:
			var lst: Array = Sim.get_link(nGCCommonLinkIDFighter)
			th.fighter_gobj = lst[0] if lst.size() > 0 else null
			th.pc = 3
		elif pc == 3:                               # while (fighter_gobj != NULL)
			if th.fighter_gobj == null:
				th.pc = 6
				continue
			Ftcommonentry.ftCommonAppearSetStatus(th.fighter_gobj)

			if th.id == 2:
				_th_sleep(th, 30, 4)
			else:
				_th_sleep(th, th.sleep_tics, 5)
			return
		elif pc == 4:
			Gmcamera.gmCameraSetStatusPlayerZoom(th.fighter_gobj, 0.0, 0.0, ftGetStruct(th.fighter_gobj).attr.closeup_camera_zoom, 0.1, 28.0)
			_th_sleep(th, th.sleep_tics - 30, 5)
			return
		elif pc == 5:
			th.fighter_gobj = _port_link_next(Sim.get_link(nGCCommonLinkIDFighter), th.fighter_gobj)
			th.pc = 3
		elif pc == 6:
			if th.id == 2:
				_th_sleep(th, 30, 7)
				return
			th.pc = 8
		elif pc == 7:
			Gmcamera.gmCameraSetStatusDefault()
			th.pc = 8
		elif pc == 8:
			_gcEjectGObj(null)
			_th_sleep(th, 1, 9)
			return
		else:
			return

## 0x801129DC
static func ifCommonEntryFocusMakeInterface(id: int) -> void:
	var interface_gobj := _gcMakeGObjSPAfter(nGCCommonKindInterface, null, nGCCommonLinkIDInterfaceActor, GOBJ_PRIORITY_DEFAULT)

	interface_gobj.port_kind = "entry_focus"
	Objman.gcAddGObjProcess(interface_gobj, Callable(Ifcommon, &"ifCommonEntryFocusThread"), nGCProcessKindThread, 5)

	interface_gobj.user_data = id

## 0x80112A34
static func ifCommonEntryAllThread(interface_gobj) -> void:
	var th := _th_state(interface_gobj)
	if not _th_wake(th):
		return
	match th.pc:
		0:
			_th_sleep(th, 90, 1)
		1:
			ifCommonCountdownMakeInterface()
			ifCommonEntryFocusMakeInterface(syUtilsRandIntRange(3))
			_gcEjectGObj(null)
			_th_sleep(th, 1, 2)

## 0x80112A80
static func ifCommonEntryAllMakeInterface() -> void:
	var interface_gobj := _gcMakeGObjSPAfter(nGCCommonKindInterface, null, nGCCommonLinkIDInterfaceActor, GOBJ_PRIORITY_DEFAULT)
	interface_gobj.port_kind = "entry_all"
	Objman.gcAddGObjProcess(interface_gobj, Callable(Ifcommon, &"ifCommonEntryAllThread"), nGCProcessKindThread, 5)

	G.gSCManagerBattleState.game_status = nSCBattleGameStatusWait

## 0x80112AD0
static func ifCommonSuddenDeathThread(interface_gobj) -> void:
	var th := _th_state(interface_gobj)
	if not _th_wake(th):
		return
	match th.pc:
		0:
			_th_sleep(th, 90, 1)
		1:
			ifCommonAnnounceGoMakeInterface()
			ifCommonPlayerDamageSetShowInterface()
			ifCommonAnnounceGoSetStatus()
			Snd.func_800269C0_275C0(nSYAudioVoiceAnnounceGo)
			_gcEjectGObj(null)
			_th_sleep(th, 1, 2)

## 0x80112B24
static func ifCommonAnnounceSetColors(interface_gobj, colors: Dictionary) -> void:
	var sobj = SObjGetStruct(interface_gobj)

	while sobj != null:
		sobj.sprite.red = colors.prim.r
		sobj.sprite.green = colors.prim.g
		sobj.sprite.blue = colors.prim.b
		sobj.envcolor.r = colors.env.r
		sobj.envcolor.g = colors.env.g
		sobj.envcolor.b = colors.env.b

		sobj = sobj.next

## 0x80112B74
static func ifCommonSuddenDeathMakeInterface() -> void:
	var interface_gobj := _gcMakeGObjSPAfter(nGCCommonKindInterface, null, nGCCommonLinkIDInterface, GOBJ_PRIORITY_DEFAULT)

	interface_gobj.port_kind = "suddendeath"
	_gcAddGObjDisplay(interface_gobj, Callable(Ifcommon, &"lbCommonDrawSObjAttr"), 23, GOBJ_PRIORITY_DEFAULT, ~0)
	Objman.gcAddGObjProcess(interface_gobj, Callable(Ifcommon, &"ifCommonSuddenDeathThread"), nGCProcessKindThread, 5)
	ifCommonAnnounceSetAttr(interface_gobj, 7, dIFCommonAnnounceSuddenDeathSpriteData, dIFCommonAnnounceSuddenDeathSpriteData.size())
	ifCommonAnnounceSetColors(interface_gobj, dIFCommonAnnounceSuddenDeathSpriteColors)
	Snd.func_800269C0_275C0(nSYAudioVoiceAnnounceSuddenDeath)

	G.gSCManagerBattleState.game_status = nSCBattleGameStatusWait

## 0x80112C18
static func ifCommonTimerProcDisplay(interface_gobj) -> void:
	var sobj = SObjGetStruct(interface_gobj)

	if G.gSCManagerBattleState.time_remain == 0:
		sobj = sobj.next.next.next

		sobj.sprite.copy_from(_port_sprite(dIFCommonTimerDigitSpriteOffsets[0]))

		sobj.pos.x = int(dIFCommonTimerDigitsSpritePositionsX[3] - (sobj.sprite.width * 0.5))
		sobj.pos.y = int(30.0 - (sobj.sprite.height * 0.5))
	else:
		var time: int

		if G.gSCManagerBattleState.time_remain == sIFCommonTimerLimit:
			time = G.gSCManagerBattleState.time_remain
		else:
			time = G.gSCManagerBattleState.time_remain + 59

		for i in range(sIFCommonTimerDigitsInterface.size()):
			var digit: int = time / dIFCommonTimerDigitsUnitLengths[i]

			time -= (digit * dIFCommonTimerDigitsUnitLengths[i])

			if sIFCommonTimerDigitsInterface[i] != digit:
				sobj.sprite.copy_from(_port_sprite(dIFCommonTimerDigitSpriteOffsets[digit]))

				sobj.pos.x = int(dIFCommonTimerDigitsSpritePositionsX[i] - (sobj.sprite.width * 0.5))
				sobj.pos.y = int(30.0 - (sobj.sprite.height * 0.5))

				sIFCommonTimerDigitsInterface[i] = digit & 0xFF
			sobj = sobj.next
	lbCommonDrawSObjAttr(interface_gobj)

## 0x80112EBC
static func ifCommonTimerSetAttr() -> void:
	for i in range(dIFCommonTimerDigitSpriteOffsets.size()):
		_port_sprite(dIFCommonTimerDigitSpriteOffsets[i]).attr = SP_TEXSHUF | SP_TRANSPARENT

## 0x80112F3C
static func ifCommonTimerInitAnnouncedSeconds() -> void:
	for i in range(sIFCommonIsAnnouncedSecond.size()):
		sIFCommonIsAnnouncedSecond[i] = FALSE

## 0x80112F68
static func ifCommonTimerMakeDigits():
	var interface_gobj: IFGObj
	var sobj: SObj

	if not (G.gSCManagerBattleState.game_rules & SCBATTLE_GAMERULE_TIME) or (G.gSCManagerBattleState.time_limit == SCBATTLE_TIMELIMIT_INFINITE):
		return null

	ifCommonTimerSetAttr()

	interface_gobj = _gcMakeGObjSPAfter(nGCCommonKindInterface, null, nGCCommonLinkIDInterface, GOBJ_PRIORITY_DEFAULT)
	interface_gobj.port_kind = "timer"

	_gcAddGObjDisplay(interface_gobj, Callable(Ifcommon, &"ifCommonTimerProcDisplay"), 23, GOBJ_PRIORITY_DEFAULT, ~0)

	for i in 4:
		_lbCommonMakeSObjForGObj(interface_gobj, _port_sprite("llIFCommonTimerDigit0Sprite"))

	sobj = _lbCommonMakeSObjForGObj(interface_gobj, _port_sprite("llIFCommonTimerSymbolColonSprite"))

	sobj.pos.x = int(260.0 - (sobj.sprite.width * 0.5))
	sobj.pos.y = int(30.0 - (sobj.sprite.height * 0.5))

	sIFCommonTimerDigitsInterface = [10, 10, 10, 10]

	return sobj

## 0x80113104 - func_run of the timer GObj (gcRunAll func_run pass)
static func ifCommonTimerFuncRun(interface_gobj) -> void:
	var bs = G.gSCManagerBattleState

	if sIFCommonTimerIsStarted != FALSE:
		var time_update: int = _sySchedulerGetTicCount()
		var time_delta: int = (time_update - sIFCommonTimerStamp) & 0xFFFFFFFF

		if time_delta != 0:
			sIFCommonTimerStamp = time_update
			bs.time_passed = (bs.time_passed + time_delta) & 0xFFFFFFFF

			if (bs.game_rules & SCBATTLE_GAMERULE_TIME) and (bs.time_limit != SCBATTLE_TIMELIMIT_INFINITE):
				if bs.time_remain != 0:
					if bs.time_remain < time_delta:
						bs.time_remain = 0
					else:
						bs.time_remain -= time_delta

					if (bs.gkind == nGRKindInishie) and (bs.time_remain <= I_SEC_TO_TICS(30)) and (Mpcollision.gMPCollisionBGMDefault != nSYAudioBGMInishieHurry):
						Mpcollision.gMPCollisionBGMDefault = nSYAudioBGMInishieHurry
						Ftparam.ftParamTryUpdateItemMusic()
					if bs.time_remain <= I_SEC_TO_TICS(5):
						if bs.time_remain == 0:
							ifGetProc(interface_gobj).call()

							_gcEjectGObj(null)
						else:
							for i in range(sIFCommonIsAnnouncedSecond.size()):
								if (sIFCommonIsAnnouncedSecond[i] == FALSE) and (bs.time_remain <= (I_SEC_TO_TICS(i) + I_SEC_TO_TICS(1))):
									Snd.func_800269C0_275C0(dIFCommonAnnounceTimerVoiceIDs[i])

									sIFCommonIsAnnouncedSecond[i] = TRUE
						Audio.syAudioSetBGMVolume(0, int(((bs.time_remain / F_SEC_TO_TICS(5)) * 20480.0) + 10240.0))

## 0x80113398
static func ifCommonTimerMakeInterface(proc: Callable) -> void:
	var interface_gobj: IFGObj

	sIFCommonTimerLimit = I_MIN_TO_TICS(G.gSCManagerBattleState.time_limit)
	G.gSCManagerBattleState.time_remain = sIFCommonTimerLimit
	G.gSCManagerBattleState.time_passed = 0

	sIFCommonTimerIsStarted = FALSE

	ifCommonTimerInitAnnouncedSeconds()
	interface_gobj = _gcMakeGObjSPAfter(nGCCommonKindInterface, Callable(Ifcommon, &"ifCommonTimerFuncRun"), nGCCommonLinkIDInterfaceActor, GOBJ_PRIORITY_DEFAULT)
	interface_gobj.port_kind = "timer_actor"
	ifSetProc(interface_gobj, proc)

## 0x8011341C
static func ifCommonAnnounceGameSetMakeInterface() -> IFGObj:
	var interface_gobj := _gcMakeGObjSPAfter(nGCCommonKindInterface, null, nGCCommonLinkIDInterface, GOBJ_PRIORITY_DEFAULT)

	interface_gobj.port_kind = "game"
	_gcAddGObjDisplay(interface_gobj, Callable(Ifcommon, &"lbCommonDrawSObjAttr"), 23, GOBJ_PRIORITY_DEFAULT, ~0)

	ifCommonAnnounceSetAttr(interface_gobj, 1, dIFCommonAnnounceGameSetSpriteData, dIFCommonAnnounceGameSetSpriteData.size())

	return interface_gobj

## 0x80113488 (called by ftParamInitGame)
static func ifCommonBattleInitPlacement() -> void:
	var members: Array = [0, 0, 0, 0, 0]
	var teams := 0

	if int(G.gSCManagerBattleState.is_team_battle) == FALSE:
		for i in range(G.gSCManagerBattleState.players.size()):
			if G.gSCManagerBattleState.players[i].pkind != nFTPlayerKindNot:
				members[i] += 1
	elif int(G.gSCManagerBattleState.is_team_battle) == TRUE:
		for i in range(G.gSCManagerBattleState.players.size()):
			if G.gSCManagerBattleState.players[i].pkind != nFTPlayerKindNot:
				members[G.gSCManagerBattleState.players[i].team] += 1
	for i in range(members.size()):
		if members[i] != 0:
			teams += 1
	sIFCommonBattlePlace = teams - 1

## 0x80113638
static func ifCommonBattleInterfacePauseGObj(interface_gobj, unused = 0) -> void:
	Objhelper.gcPauseGObjProcessAll(interface_gobj)

	interface_gobj.gobj_flags |= GOBJ_FLAG_NORUN

## 0x8011366C
static func ifCommonBattleInterfaceResumeGObj(interface_gobj, unused = 0) -> void:
	Objhelper.gcResumeGObjProcessAll(interface_gobj)

	interface_gobj.gobj_flags &= ~GOBJ_FLAG_NORUN

## gEFParticleStructsGObj / gEFParticleGeneratorsGObj (efparticle.c; module not ported yet)
static func _port_particle_gobj(name: String):
	var scr: Object = Efparticle
	return scr.get(name)

## 0x801136A4
static func ifCommonBattleInterfaceProcUpdate() -> void:
	_gcFuncGObjAll(Callable(Ifcommon, &"ifCommonBattleInterfacePauseGObj"), 0)

	_gcFuncGObjByLink(nGCCommonLinkIDSpecialEffect, Callable(Ifcommon, &"ifCommonBattleInterfaceResumeGObj"), 0)
	_gcFuncGObjByLink(nGCCommonLinkIDInterface, Callable(Ifcommon, &"ifCommonBattleInterfaceResumeGObj"), 0)
	Gmrumble.gmRumbleResumeProcessAll()
	var structs_gobj = _port_particle_gobj("gEFParticleStructsGObj")
	if structs_gobj != null:
		ifCommonBattleInterfaceResumeGObj(structs_gobj, 0)
	var generators_gobj = _port_particle_gobj("gEFParticleGeneratorsGObj")
	if generators_gobj != null:
		ifCommonBattleInterfaceResumeGObj(generators_gobj, 0)
	Efparticle.efParticleGObjSetSkipAll()
	Efparticle.efParticleGObjClearSkipID(2)
	Efparticle.efParticleGObjClearSkipID(3)
	Snd.func_800266A0_272A0()
	ifCommonBattleEndPlaySoundQueue()

## 0x80113744 - Unused?
static func func_ovl2_80113744(fighter_gobj, unused = 0) -> void:
	var fp = ftGetStruct(fighter_gobj)

	if fp.fkind == nFTKindBoss:
		Objhelper.gcResumeGObjProcessAll(fighter_gobj)

		fighter_gobj.gobj_flags &= ~GOBJ_FLAG_NORUN

## 0x80113790
static func ifCommonBattleEndInitSoundNum() -> void:
	sIFCommonBattleEndSoundsNum = 0

## 0x8011379C
static func ifCommonBattleEndPlaySoundQueue() -> void:
	for i in range(sIFCommonBattleEndSoundsNum):
		Snd.func_800269C0_275C0(sIFCommonBattleEndSoundsQueue[i])

## 0x80113804
static func ifCommonBattleEndAddSoundQueueID(sfx_id) -> void:
	if (G.gSCManagerBattleState.game_status == nSCBattleGameStatusEnd) and (sIFCommonBattleEndSoundsNum < sIFCommonBattleEndSoundsQueue.size()):
		sIFCommonBattleEndSoundsQueue[sIFCommonBattleEndSoundsNum] = int(sfx_id) & 0xFFFF
		sIFCommonBattleEndSoundsNum += 1

## 0x80113854
static func ifCommonBattleEndSetBossDefeat() -> void:
	StubLog.hit("func_ovl65_8018F6DC")      # src/sc/sc1pmode/sc1pgameboss.c (1P mode, not in the port map)

	G.gSCManagerBattleState.game_status = nSCBattleGameStatusBossDefeat
	sIFCommonBattlePauseCameraRestoreWait = 0

## 0x8011388C
static func ifCommonBattleUpdateScoreStocks(fp) -> void:
	var teammates_remain := 0
	var current_team := 0
	var team: int = fp.team
	var bs = G.gSCManagerBattleState

	for i in range(bs.players.size()):
		if bs.players[i].pkind == nFTPlayerKindNot:
			continue
		if int(bs.is_team_battle) == FALSE:
			current_team = i
		elif int(bs.is_team_battle) == TRUE:
			current_team = bs.players[i].team
		if (current_team == team) and (bs.players[i].stock_count != -1):
			teammates_remain += 1
	if teammates_remain == 0:
		if int(bs.is_team_battle) == FALSE:
			bs.players[team].place = sIFCommonBattlePlace & 0xFF
		elif int(bs.is_team_battle) == TRUE:
			for i in range(bs.players.size()):
				if bs.players[i].pkind == nFTPlayerKindNot:
					continue
				if bs.players[i].team == team:
					bs.players[i].place = sIFCommonBattlePlace & 0xFF
		sIFCommonBattlePlace -= 1

		if sIFCommonBattlePlace == 0:
			ifCommonAnnounceEndMessage()
	if (sIFCommonBattlePlace != 0) and (fp.stock_count == -1):
		if fp.pkind == nFTPlayerKindMan:
			Ftpublic.ftPublicDefeatedAddID(dIFCommonAnnounceDefeatedVoiceIDs[fp.player])
		else:
			Ftpublic.ftPublicDefeatedAddID(nSYAudioVoiceAnnounceComputerPlayer)

		Ftpublic.ftPublicDefeatedAddID(nSYAudioVoiceAnnounceDefeated)

## 0x80113AA8 - white border of the pause frame (GPACK_RGBA5551(0xFF, 0xFF, 0xFF, 1) fill rectangles)
static func ifCommonBattlePauseProcDisplay(interface_gobj) -> void:
	for i in range(dIFCommonBattlePauseBorderRectangle.size()):
		var r: Array = dIFCommonBattlePauseBorderRectangle[i]
		_port_draw.append({"name": "rect", "rect": [r[0], r[1], r[2], r[3]], "color": Color8(0xFF, 0xFF, 0xFF, 0xFF), "dl_link": 24, "kind": "pause_border"})

## 0x80113CF8
static func ifCommonBattlePausePlayerNumMakeSObj(interface_gobj, player: int) -> void:
	var sobj := _lbCommonMakeSObjForGObj(interface_gobj, _port_sprite(dIFCommonBattlePausePlayerNumSpriteOffsets[player]))

	sobj.sprite.red = 0xFF
	sobj.sprite.green = 0xFF
	sobj.sprite.blue = 0xFF

	sobj.sprite.attr = SP_TEXSHUF | SP_TRANSPARENT

	sobj.pos.x = 213.0
	sobj.pos.y = 191.0

## 0x80113D60
static func ifCommonBattlePauseDecalMakeSObjID(interface_gobj, id: int) -> void:
	var d: Array = dIFCommonBattlePauseDecalsSpriteData[id]
	var sobj := _lbCommonMakeSObjForGObj(interface_gobj, _port_sprite(d[0]))

	sobj.pos.x = d[1]
	sobj.pos.y = d[2]

	sobj.sprite.red = d[3][0]
	sobj.sprite.green = d[3][1]
	sobj.sprite.blue = d[3][2]

	sobj.envcolor.r = d[4][0]
	sobj.envcolor.g = d[4][1]
	sobj.envcolor.b = d[4][2]

	sobj.sprite.attr = SP_TEXSHUF | SP_TRANSPARENT

## 0x80113E04
static func ifCommonBattlePauseMakeSObjsAll(interface_gobj) -> void:
	var draw_count: int = 10 if (sIFCommonBattlePauseKindInterface != nIFPauseKindDefault) else 12

	for i in range(draw_count):
		ifCommonBattlePauseDecalMakeSObjID(interface_gobj, i)
	# Bonus Practice: "L: RETRY"
	if (G.gSCManagerSceneData.scene_curr == nSCKind1PBonusStage) and (G.gSCManagerSceneData.scene_prev != nSCKind1PGame):
		for i in range(12, dIFCommonBattlePauseDecalsSpriteData.size()):
			ifCommonBattlePauseDecalMakeSObjID(interface_gobj, i)

## 0x80113EB4
static func ifCommonBattlePauseMakeInterface(player: int) -> void:
	var interface_gobj := _gcMakeGObjSPAfter(nGCCommonKindPauseMenu, null, nGCCommonLinkIDPauseMenu, GOBJ_PRIORITY_DEFAULT)

	interface_gobj.port_kind = "pause"
	_gcAddGObjDisplay(interface_gobj, Callable(Ifcommon, &"ifCommonBattlePauseProcDisplay"), 24, GOBJ_PRIORITY_DEFAULT, ~0)

	interface_gobj = _gcMakeGObjSPAfter(nGCCommonKindPauseMenu, null, nGCCommonLinkIDPauseMenu, GOBJ_PRIORITY_DEFAULT)

	interface_gobj.port_kind = "pause"
	_gcAddGObjDisplay(interface_gobj, Callable(Ifcommon, &"lbCommonDrawSObjAttr"), 24, GOBJ_PRIORITY_DEFAULT, ~0)

	ifCommonBattlePausePlayerNumMakeSObj(interface_gobj, player)
	ifCommonBattlePauseMakeSObjsAll(interface_gobj)

## 0x80113F50 - lbCommonEjectGObjLinkedList(gGCCommonLinks[nGCCommonLinkIDPauseMenu])
static func ifCommonBattlePauseEjectGObjs() -> void:
	var lst: Array = Sim.get_link(nGCCommonLinkIDPauseMenu).duplicate()
	var i := lst.size() - 1
	while i >= 0:
		_gcEjectGObj(lst[i])
		i -= 1

## 0x80113F74
static func ifCommonInterfaceSetGObjFlagsAll(flags: int) -> void:
	for interface_gobj in Sim.get_link(nGCCommonLinkIDInterface):
		interface_gobj.gobj_flags = flags

## 0x80113F9C
static func ifCommonBattlePauseSetGObjFlagsAll(flags: int) -> void:
	for gobj in Sim.get_link(nGCCommonLinkIDPauseMenu):
		gobj.gobj_flags = flags

## 0x80113FC4
static func ifCommonBattlePauseInitInterface(player: int) -> void:
	ifCommonInterfaceSetGObjFlagsAll(GOBJ_FLAG_HIDDEN)
	Gmrumble.gmRumbleInitPlayers()
	Grwallpaper.grWallpaperPausePerspUpdate()

	gIFCommonPlayerInterface.is_magnify_display = FALSE
	G.gSCManagerBattleState.game_status = nSCBattleGameStatusPause

	sIFCommonBattlePausePlayer = player & 0xFF

	_func_80026594_27194()
	Snd.func_800269C0_275C0(nSYAudioFGMGamePause)
	Audio.syAudioSetBGMVolume(0, 0x3C00)
	ifCommonBattlePauseMakeInterface(player)

## 0x8011403C
static func ifCommonBattleGoUpdateInterface() -> void:
	var bs = G.gSCManagerBattleState

	for player in range((bs.players.size() + Controller.gSYControllerDevices.size()) / 2):
		if Controller.gSYControllerDevices[player].button_tap & START_BUTTON:
			if bs.players[player].pkind != nFTPlayerKindNot:
				if (bs.gkind != nGRKindBonus3) or (bs.players[player].pkind != nFTPlayerKindCom):
					var fighter_gobj = bs.players[player].fighter_gobj
					var fp = ftGetStruct(fighter_gobj)

					if (fp.status_id == nFTCommonStatusSleep) and (Ftcommonsleep.ftCommonSleepCheckIgnorePauseMenu(fighter_gobj) != FALSE):
						continue
					if not B(fp.is_menu_ignore):
						if bs.game_type == nSCBattleGameTypeBonus:
							var gd = Mpcollision.gMPCollisionGroundData
							var sp68: Vector3 = gd.zoom_start
							var sp5C: Vector3 = gd.zoom_end

							Gmcamera.gmCameraSetStatusMapZoom(sp68, sp5C)

							sIFCommonBattlePauseKindInterface = nIFPauseKindBonus
						elif Gmcamera.gmCameraCheckPausePlayerOutBounds(DObjGetStruct(fighter_gobj).translate) != FALSE:
							sIFCommonBattlePauseKindInterface = nIFPauseKindPlayerNA
						else:
							Gmcamera.gmCameraSetStatusPlayerZoom(fighter_gobj, 0.0, 0.0, ftGetStruct(fighter_gobj).attr.closeup_camera_zoom, 0.1, 29.0)

							sIFCommonBattlePauseCameraEyeXOrigin = Gmcamera.gGMCameraPauseCameraEyeX
							sIFCommonBattlePauseCameraEyeYOrigin = Gmcamera.gGMCameraPauseCameraEyeY

							sIFCommonBattlePauseKindInterface = nIFPauseKindDefault

							sIFCommonBattlePausePlayerDetail = fp.detail_curr & 0xFF

							Ftparam.ftParamSetModelPartDetailAll(fighter_gobj, nFTPartsDetailHigh)
						ifCommonBattlePauseInitInterface(player)
						return
			sIFCommonBattlePauseKindInterface = 0

			ifCommonBattlePauseInitInterface(player)
			return
	_gcRunAll()

## 0x801142B4
static func ifCommonBattleInterfaceProcSet() -> void:
	ifCommonInterfaceSetGObjFlagsAll(GOBJ_FLAG_HIDDEN)

	G.gSCManagerBattleState.game_status = nSCBattleGameStatusSet

	sIFCommonBattlePauseCameraRestoreWait = 3

## 0x801142EC
static func ifCommonBattlePauseUpdateInterface() -> void:
	var dev = Controller.gSYControllerDevices[sIFCommonBattlePausePlayer]
	var button_tap: int = dev.button_tap & 0xFFFF
	var button_hold: int = dev.button_hold & 0xFFFF

	if sIFCommonBattlePauseKindInterface == nIFPauseKindDefault:
		var stick_x: int = dev.stick_range.x
		var stick_y: int = dev.stick_range.y

		if ABS(stick_x) > 8.0:
			Gmcamera.gGMCameraPauseCameraEyeX += (stick_x * 0.000333)

			if Gmcamera.gGMCameraPauseCameraEyeX > F_CLC_DTOR32(50.0):
				Gmcamera.gGMCameraPauseCameraEyeX = F_CLC_DTOR32(50.0)
			elif Gmcamera.gGMCameraPauseCameraEyeX < F_CLC_DTOR32(-50.0):
				Gmcamera.gGMCameraPauseCameraEyeX = F_CLC_DTOR32(-50.0)
		if ABS(stick_y) > 8.0:
			Gmcamera.gGMCameraPauseCameraEyeY -= (stick_y * 0.000333)

			if Gmcamera.gGMCameraPauseCameraEyeY > F_CLC_DTOR32(20.0):
				Gmcamera.gGMCameraPauseCameraEyeY = F_CLC_DTOR32(20.0)
			elif Gmcamera.gGMCameraPauseCameraEyeY < F_CLC_DTOR32(-20.0):
				Gmcamera.gGMCameraPauseCameraEyeY = F_CLC_DTOR32(-20.0)
	if button_tap:
		if button_tap & START_BUTTON:
			if sIFCommonBattlePauseKindInterface != nIFPauseKindPlayerNA:
				Gmcamera.gmCameraSetStatusPrev()

				sIFCommonBattlePauseCameraRestoreWait = 20
			else:
				sIFCommonBattlePauseCameraRestoreWait = 0

			G.gSCManagerBattleState.game_status = nSCBattleGameStatusUnpause

			return
		else:
			button_hold = dev.button_hold & 0xFFFF

		if (button_hold & A_BUTTON) and (button_hold & B_BUTTON) and (button_hold & R_TRIG) and (button_hold & Z_TRIG):
			G.gSCManagerSceneData.is_reset = TRUE

			_gcFuncGObjAll(Callable(Ifcommon, &"ifCommonBattleInterfacePauseGObj"), 0)
			Snd.func_800266A0_272A0()
			Gmrumble.gmRumbleInitPlayers()
			ifCommonBattlePauseSetGObjFlagsAll(GOBJ_FLAG_HIDDEN)
			ifCommonBattleInterfaceProcSet()

			return
		if (button_tap & L_TRIG) and (G.gSCManagerSceneData.scene_curr == nSCKind1PBonusStage) and (G.gSCManagerSceneData.scene_prev != nSCKind1PGame):
			Snd.func_800266A0_272A0()
			Gmrumble.gmRumbleInitPlayers()
			_syTaskmanSetLoadScene()

			return
	if sIFCommonBattlePauseKindInterface != nIFPauseKindPlayerNA:
		Gmcamera.gmCameraRunFuncCamera(Gmcamera.gGMCameraGObj)
		Grwallpaper.grWallpaperRunProcessAll()

## 0x80114588
static func ifCommonBattlePauseRestoreInterfaceAll() -> void:
	if sIFCommonBattlePauseCameraRestoreWait != 0:
		sIFCommonBattlePauseCameraRestoreWait -= 1

		Gmcamera.gGMCameraPauseCameraEyeX += (sIFCommonBattlePauseCameraEyeXOrigin - Gmcamera.gGMCameraPauseCameraEyeX) * 0.1
		Gmcamera.gGMCameraPauseCameraEyeY += (sIFCommonBattlePauseCameraEyeYOrigin - Gmcamera.gGMCameraPauseCameraEyeY) * 0.1

		Gmcamera.gmCameraRunFuncCamera(Gmcamera.gGMCameraGObj)
		Grwallpaper.grWallpaperRunProcessAll()

		return
	ifCommonBattlePauseEjectGObjs()
	ifCommonInterfaceSetGObjFlagsAll(0)
	Grwallpaper.grWallpaperResumePerspUpdate()

	gIFCommonPlayerInterface.is_magnify_display = TRUE

	G.gSCManagerBattleState.game_status = nSCBattleGameStatusGo

	Gmcamera.gGMCameraPauseCameraEyeX = sIFCommonBattlePauseCameraEyeXOrigin
	Gmcamera.gGMCameraPauseCameraEyeY = sIFCommonBattlePauseCameraEyeYOrigin

	_func_800264A4_270A4()
	Audio.syAudioSetBGMVolume(0, 0x7800)

	if sIFCommonBattlePauseKindInterface == nIFPauseKindDefault:
		Ftparam.ftParamSetModelPartDetailAll(G.gSCManagerBattleState.players[sIFCommonBattlePausePlayer].fighter_gobj, sIFCommonBattlePausePlayerDetail)
	_gcRunAll()

## 0x801146DC
static func ifCommonBattleEndUpdateInterface() -> void:
	sIFCommonBattleInterfaceProcUpdate.call()

	G.gSCManagerBattleState.game_status = nSCBattleGameStatusBossDefeat

	dIFCommonBattleBossUpdateWait = 0
	dIFCommonBattleBossUpdateInterval = 0

## 0x80114724
static func ifCommonBattleBossDefeatUpdateInterface() -> void:
	if sIFCommonBattlePauseCameraRestoreWait != 0:
		sIFCommonBattlePauseCameraRestoreWait -= 1
	else:
		sIFCommonBattleInterfaceProcSet.call()

	if dIFCommonBattleBossUpdateWait == 0:
		_gcRunAll()

		dIFCommonBattleBossUpdateWait = dIFCommonBattleBossUpdateInterval
	else:
		Gmcamera.gmCameraRunFuncCamera(Gmcamera.gGMCameraGObj)
		Grwallpaper.grWallpaperRunProcessAll()

		dIFCommonBattleBossUpdateWait -= 1

## 0x801147BC
static func ifCommonBattleSetUpdateInterface() -> void:
	if sIFCommonBattlePauseCameraRestoreWait != 0:
		sIFCommonBattlePauseCameraRestoreWait -= 1
	else:
		_syTaskmanSetLoadScene()

	_gcRunAll()

## 0x80114800 - (port: no N64 heap; free space is never < 25 KB, so the GObj cap is never set)
static func ifCommonSetMaxNumGObj() -> void:
	var free_space: int = 0x7FFFFFFF      # gSYTaskmanGeneralHeap.end - gSYTaskmanGeneralHeap.ptr

	if (free_space < 25 * 1024) and (Objman.gcGetMaxNumGObj() == -1):
		Objman.gcSetMaxNumGObj(Objman.gcGetGObjsActiveNum())

## 0x8011485C - scene update (scVSBattleFuncUpdate): the battle game_status state machine
static func ifCommonBattleUpdateInterfaceAll() -> void:
	var bs = G.gSCManagerBattleState

	if bs.game_status != nSCBattleGameStatusGo:
		sIFCommonTimerIsStarted = FALSE
	elif sIFCommonTimerIsStarted == FALSE:
		sIFCommonTimerIsStarted = TRUE
		sIFCommonTimerStamp = 0

		_sySchedulerSetTicCount(0)

	var status: int = bs.game_status

	if status == nSCBattleGameStatusWait:
		_gcRunAll()
	elif status == nSCBattleGameStatusGo:
		ifCommonBattleGoUpdateInterface()
	elif status == nSCBattleGameStatusPause:
		ifCommonBattlePauseUpdateInterface()
	elif status == nSCBattleGameStatusUnpause:
		ifCommonBattlePauseRestoreInterfaceAll()
	elif status == nSCBattleGameStatusEnd:
		ifCommonBattleEndUpdateInterface()
		ifCommonBattleBossDefeatUpdateInterface()       # fallthrough
	elif status == nSCBattleGameStatusBossDefeat:
		ifCommonBattleBossDefeatUpdateInterface()
	elif status == nSCBattleGameStatusSet:
		ifCommonBattleSetUpdateInterface()
	ifCommonSetMaxNumGObj()

## 0x80114958
static func ifCommonBattleSetGameStatusWait() -> void:
	G.gSCManagerBattleState.game_status = nSCBattleGameStatusWait

## 0x80114968
static func ifCommonPlayerStockMakeStockSnap(fp) -> void:
	Efmanager.efManagerStockSnapMakeEffect(gIFCommonPlayerInterface.player_pos_x[fp.player], gIFCommonPlayerInterface.player_pos_y)

## 0x801149CC
static func ifCommonPlayerScoreMakeEffect(fp, score: int) -> void:
	var pos := Vector3()

	pos.x = ((gIFCommonPlayerInterface.player_pos_x[fp.player] + dIFCommonPlayerScorePositionOffsetsX[fp.player]) << 2)
	pos.y = ((gIFCommonPlayerInterface.player_pos_y + 13) << 2)
	pos.z = 0.0

	Efmanager.efManagerBattleScoreMakeEffect(pos, score)

## 0x80114A48
static func ifCommonAnnounceFailureMakeInterface() -> IFGObj:
	var interface_gobj := _gcMakeGObjSPAfter(nGCCommonKindInterface, null, nGCCommonLinkIDInterface, GOBJ_PRIORITY_DEFAULT)

	interface_gobj.port_kind = "failure"
	_gcAddGObjDisplay(interface_gobj, Callable(Ifcommon, &"lbCommonDrawSObjAttr"), 23, GOBJ_PRIORITY_DEFAULT, ~0)
	ifCommonAnnounceSetAttr(interface_gobj, 7, dIFCommonAnnounceFailureSpriteData, dIFCommonAnnounceFailureSpriteData.size())
	ifCommonAnnounceSetColors(interface_gobj, dIFCommonAnnounceFailureSpriteColors)

	return interface_gobj

## 0x80114AC4
static func ifCommonAnnounceCompleteMakeInterface() -> IFGObj:
	var interface_gobj := _gcMakeGObjSPAfter(nGCCommonKindInterface, null, nGCCommonLinkIDInterface, GOBJ_PRIORITY_DEFAULT)

	interface_gobj.port_kind = "complete"
	_gcAddGObjDisplay(interface_gobj, Callable(Ifcommon, &"lbCommonDrawSObjAttr"), 23, GOBJ_PRIORITY_DEFAULT, ~0)
	ifCommonAnnounceSetAttr(interface_gobj, 7, dIFCommonAnnounceCompleteSpriteData, dIFCommonAnnounceCompleteSpriteData.size())
	ifCommonAnnounceSetColors(interface_gobj, dIFCommonAnnounceCompleteSpriteColors)

	return interface_gobj

## 0x80114B40
static func ifCommonBonusInterfaceProcUpdate() -> void:
	_gcFuncGObjAll(Callable(Ifcommon, &"ifCommonBattleInterfacePauseGObj"), 0)
	Gmrumble.gmRumbleInitPlayers()
	Snd.func_800266A0_272A0()
	ifCommonBattleEndPlaySoundQueue()

## 0x80114B80
static func ifCommonBattleSetInterface(proc_update: Callable, proc_set: Callable, sfx_id: int, restore_wait: int) -> void:
	G.gSCManagerBattleState.game_status = nSCBattleGameStatusEnd
	sIFCommonBattlePauseCameraRestoreWait = restore_wait & 0xFFFF

	sIFCommonBattleInterfaceProcUpdate = proc_update
	sIFCommonBattleInterfaceProcSet = proc_set

	ifCommonBattleEndInitSoundNum()

	if sfx_id != nSYAudioFGMVoiceEnd:
		ifCommonBattleEndAddSoundQueueID(sfx_id)

## 0x80114BE4
static func ifCommonBattleBossDefeatSetGameStatus() -> void:
	G.gSCManagerBattleState.game_status = nSCBattleGameStatusBossDefeat

	sIFCommonBattlePauseCameraRestoreWait = U16_MAX

	sIFCommonBattleInterfaceProcSet = Callable(Ifcommon, &"ifCommonBattleInterfaceProcSet")
	dIFCommonBattleBossUpdateInterval = 2

## 0x80114C20
static func ifCommon1PGameInterfaceProcSet() -> void:
	_gcFuncGObjByLink(nGCCommonLinkIDCamera, Callable(Ifcommon, &"ifCommonBattleInterfaceResumeGObj"), 0)
	Grwallpaper.grWallpaperResumeProcessAll()
	ifCommonInterfaceSetGObjFlagsAll(GOBJ_FLAG_HIDDEN)

	G.gSCManagerBattleState.game_status = nSCBattleGameStatusSet

	sIFCommonBattlePauseCameraRestoreWait = 45

	StubLog.hit("sc1PGameSetCameraZoom")    # src/sc/sc1pmode/sc1pgame.c (1P mode, not in the port map)

	gIFCommonPlayerInterface.is_magnify_display = FALSE

## 0x80114C80
static func ifCommonAnnounceEndMessage() -> void:
	if G.gSCManagerBattleState.gkind >= nGRKindBonusStageStart:
		ifCommonBattleSetInterface(Callable(Ifcommon, &"ifCommonBattleInterfaceProcUpdate"), Callable(Ifcommon, &"ifCommonBattleInterfaceProcSet"), nSYAudioVoiceAnnounceFailure, 90)
		ifCommonAnnounceFailureMakeInterface()
	else:
		if (G.gSCManagerBattleState.game_type == nSCBattleGameType1PGame) and (G.gSCManagerBattleState.players[G.gSCManagerSceneData.player].stock_count != -1):
			ifCommonBattleSetInterface(Callable(Ifcommon, &"ifCommonBattleInterfaceProcUpdate"), Callable(Ifcommon, &"ifCommon1PGameInterfaceProcSet"), nSYAudioVoiceAnnounceGameSet, 90)
		else:
			ifCommonBattleSetInterface(Callable(Ifcommon, &"ifCommonBattleInterfaceProcUpdate"), Callable(Ifcommon, &"ifCommonBattleInterfaceProcSet"), nSYAudioVoiceAnnounceGameSet, 90)

		ifCommonAnnounceGameSetMakeInterface()

## 0x80114D58
static func ifCommonAnnounceCompleteInitInterface(sfx_id: int) -> void:
	ifCommonBattleSetInterface(Callable(Ifcommon, &"ifCommonBonusInterfaceProcUpdate"), Callable(Ifcommon, &"ifCommonBattleInterfaceProcSet"), sfx_id, 90)
	ifCommonAnnounceCompleteMakeInterface()

## 0x80114D98
static func ifCommonAnnounceTimeUpInitInterface() -> void:
	ifCommonBattleSetInterface(Callable(Ifcommon, &"ifCommonBonusInterfaceProcUpdate"), Callable(Ifcommon, &"ifCommonBattleInterfaceProcSet"), nSYAudioVoiceAnnounceTimeUp, 90)
	ifCommonAnnounceTimeUpMakeInterface()

## 0x80114DD4
static func ifCommonAnnounceFailureInitInterface() -> void:
	# REGION_US
	if G.gSCManagerBattleState.game_status != nSCBattleGameStatusEnd:
		ifCommonBattleSetInterface(Callable(Ifcommon, &"ifCommonBonusInterfaceProcUpdate"), Callable(Ifcommon, &"ifCommonBattleInterfaceProcSet"), nSYAudioVoiceAnnounceFailure, 90)
		ifCommonAnnounceFailureMakeInterface()

# // // // // // // // // // // // //
# //    PORT: DISPLAY PASS / UI    //
# // // // // // // // // // // // //

## ftDisplayMainProcDisplay (src/ft/ftdisplaymain.c) main-camera magnifier test (AVOID_UB variant):
## sets fp->is_magnify_show / fp->magnify_pos, magnify_mode and the arrow flags.
static func _port_ftDisplayMainMagnify(fighter_gobj) -> void:
	var fp = ftGetStruct(fighter_gobj)

	if B(fp.is_invisible) and (fp.display_mode == nDBDisplayModeMaster):
		fp.is_magnify_show = FALSE
		return
	if (fp.pkind == nFTPlayerKindMan) or (fp.pkind == nFTPlayerKindCom) or (fp.pkind == nFTPlayerKindGameKey):
		if (fp.status_id == nFTCommonStatusDeadUpStar) or (fp.status_id == nFTCommonStatusDeadUpFall):
			fp.is_magnify_show = FALSE
			return
		if (fp.joints.size() == 0) or (fp.joints[nFTPartsJointTopN] == null):
			return
		var cobj = Gmcamera.CObjGetStruct(Gmcamera.gGMCameraGObj)
		var ft_pos: Vector3 = fp.joints[nFTPartsJointTopN].translate
		var dist: Vector3
		var cam: Vector2

		ft_pos.y += fp.attr.cam_offset_y
		dist = cobj.vec.at - ft_pos

		if fp.attr.cam_offset_y < syVectorMag3D(dist):
			dist = syVectorNorm3D(dist) * fp.attr.cam_offset_y
			ft_pos += dist
		cam = _port_project(ft_pos)

		if Gmcamera.gmCameraCheckTargetInBounds(cam.x, cam.y) == FALSE:
			ft_pos = fp.joints[nFTPartsJointTopN].translate
			ft_pos.y += 300.0

			fp.magnify_pos = _port_project(ft_pos)

			fp.is_magnify_show = TRUE

			if gIFCommonPlayerInterface.is_magnify_display != FALSE:
				if not B(fp.is_magnify_ignore) and not B(fp.is_rebirth):
					gIFCommonPlayerInterface.magnify_mode = 1

					ifCommonPlayerArrowsUpdateFlags(cam.x, cam.y)
		else:
			fp.is_magnify_show = FALSE

static func _port_display_link(dl_link: int) -> void:
	if not _port_dl_links.has(dl_link):
		return
	var lst: Array = _port_dl_links[dl_link]
	var alive: Array = []
	for gobj in lst:
		if gobj.is_alive:
			alive.append(gobj)
	_port_dl_links[dl_link] = alive
	for gobj in alive.duplicate():
		if not (gobj.gobj_flags & GOBJ_FLAG_HIDDEN) and gobj.display_proc.is_valid():
			gobj.display_proc.call(gobj)

## The interface part of gcDrawAll (scManagerFuncDraw): main camera magnifier test, magnifier
## camera, arrows camera (DL 8), screen-flash camera (DL 22), interface camera (DL 23, 24); then `ui`.
static func port_update_ui() -> void:
	_port_draw = []

	var camera_gobj = Gmcamera.gGMCameraGObj
	if camera_gobj != null:
		var cobj = Gmcamera.CObjGetStruct(camera_gobj)
		Gmcamera.gmCameraLookAtFuncMatrix(null, cobj, null)     # gGMCameraMatrix of this frame
		gIFCommonPlayerInterface.magnify_mode = 0                # gmCameraDefaultProcDisplay
		gIFCommonPlayerInterface.arrows_flags = 0
		if port_hud_computes_magnify:
			for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
				if not (fighter_gobj.gobj_flags & GOBJ_FLAG_HIDDEN):
					_port_ftDisplayMainMagnify(fighter_gobj)
		if gIFCommonPlayerInterface.magnify_mode != 0:           # gmCameraPlayerMagnifyProcDisplay
			Gmcamera.gmCameraPlayerMagnifyFuncMatrix(null, cobj, null)
			for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
				var fp = ftGetStruct(fighter_gobj)
				if (fp.pkind == nFTPlayerKindMan) or (fp.pkind == nFTPlayerKindCom) or (fp.pkind == nFTPlayerKindGameKey):
					if not B(fp.is_magnify_ignore) and not B(fp.is_rebirth) and B(fp.is_magnify_show):
						ifCommonPlayerMagnifyUpdateViewport(null, fp)
						ifCommonPlayerMagnifyProcDisplay(fp)
	if gIFCommonPlayerInterface.arrows_flags != 0:              # gmCameraPlayerArrowsProcDisplay
		_port_display_link(8)
	_port_display_link(22)
	_port_display_link(23)
	_port_display_link(24)
	_port_build_ui()

static func _port_color8(r: int, g: int, b: int, a: int = 0xFF) -> Color:
	return Color8(r & 0xFF, g & 0xFF, b & 0xFF, a & 0xFF)

static func _port_build_ui() -> void:
	var bs = G.gSCManagerBattleState
	var players: Array = []
	var announcements: Array = []
	var countdown := {"visible": false, "t": 0, "lamp": -1}
	var item_arrows: Array = []
	var steals: Array = []
	var pause := {"active": false, "player": sIFCommonBattlePausePlayer, "kind": sIFCommonBattlePauseKindInterface,
		"show_retry": (G.gSCManagerSceneData.scene_curr == nSCKind1PBonusStage) and (G.gSCManagerSceneData.scene_prev != nSCKind1PGame)}
	var timer := {"visible": false, "frames_remaining": bs.time_remain, "frames_passed": bs.time_passed,
		"digits": sIFCommonTimerDigitsInterface.duplicate(), "seconds_remaining": (bs.time_remain + 59) / 60}

	for gobj in Sim.get_link(nGCCommonLinkIDInterface):
		if not (gobj is IFGObj):
			continue
		var shown: bool = not (gobj.gobj_flags & GOBJ_FLAG_HIDDEN)
		match gobj.port_kind:
			"ready", "go", "game", "timeup", "suddendeath", "failure", "complete":
				if shown:
					announcements.append({"kind": gobj.port_kind, "frame": port_frame - gobj.port_frame_made})
				if gobj.port_kind == "ready":
					var th: Dictionary = gobj.thread
					countdown = {"visible": shown, "t": port_frame - gobj.port_frame_made, "lamp": th.get("lamp_status", -1)}
			"item_arrow":
				if shown and (gobj.user_data != null):
					var sobj = SObjGetStruct(gobj)
					var ip = gobj.user_data
					if (sobj != null) and B(ip.is_allow_pickup) and (ip.arrow_timer >= 15):
						item_arrows.append({"pos": sobj.pos, "item_gobj": ip})
			"steal":
				var sobj = SObjGetStruct(gobj)
				if shown and (sobj != null):
					steals.append({"thief": gobj.user_data, "pos": sobj.pos, "fkind": sobj.sprite.fkind, "costume": sobj.sprite.LUT})
			"timer":
				timer.visible = shown
	for gobj in Sim.get_link(nGCCommonLinkIDPauseMenu):
		if (gobj is IFGObj) and not (gobj.gobj_flags & GOBJ_FLAG_HIDDEN):
			pause.active = true

	for player in range(bs.players.size()):
		var pd = bs.players[player]
		var s: IFPlayerDamage = sIFCommonPlayerDamageInterface[player]
		var e := {"active": pd.pkind != nFTPlayerKindNot, "pkind": pd.pkind, "fkind": pd.fkind, "costume": pd.costume, "team": pd.team,
			"player_color_index": pd.color, "name_tag": _PORT_TAG_NAMES[pd.tag] if (pd.tag >= 0) and (pd.tag < _PORT_TAG_NAMES.size()) else "",
			"tag_visible": false, "tag_pos": Vector2.ZERO,
			"tag_color": _port_color8(dIFCommonPlayerTagPrimColorsR[pd.color % 5], dIFCommonPlayerTagPrimColorsG[pd.color % 5], dIFCommonPlayerTagPrimColorsB[pd.color % 5]),
			"damage": mini(pd.stock_damage_all, 999), "damage_visible": false, "damage_scale": s.scale, "damage_color": Color.WHITE,
			"damage_flash": s.color_id == GMCOMMON_PLAYERS_MAX, "damage_snap": false, "damage_chars": [], "is_damage_breaking": s.is_update_anim != FALSE,
			"emblem_visible": false, "emblem_pos": Vector2.ZERO, "emblem_color": Color.WHITE,
			"stocks": pd.stock_count, "is_stock_visible": false, "is_single_stockicon": B(pd.is_single_stockicon),
			"stock_icons": [], "stock_number": -1, "stock_number_icon_pos": Vector2.ZERO, "stock_number_digit_pos": []}
		if pd.fkind == nFTKindBoss:
			e.damage = maxi(300 - mini(pd.stock_damage_all, 999), 0)
		var dgobj = s.interface_gobj
		if e.active and (dgobj != null) and dgobj.is_alive:
			var shown: bool = not (dgobj.gobj_flags & GOBJ_FLAG_HIDDEN)
			var sobj = SObjGetStruct(dgobj)
			if sobj != null:
				e.emblem_visible = shown and not (sobj.sprite.attr & SP_HIDDEN)
				e.emblem_pos = sobj.pos
				e.emblem_color = _port_color8(sobj.sprite.red, sobj.sprite.green, sobj.sprite.blue)
				e.damage_visible = shown and (s.is_show_interface != FALSE) and ((pd.stock_count >= 0) or (s.dead_stopupdate_wait != 0))
				var first = sobj.next
				if first != null:
					e.damage_color = _port_color8(first.sprite.red, first.sprite.green, first.sprite.blue)
				e.damage_snap = (s.scale == 1.0) and (s.is_update_anim == FALSE)
				var c = first
				while c != null:
					var ch: IFDCharacter = c.user_data
					e.damage_chars.append({"glyph": ch.image_id, "pos": ch.pos, "visible": not (c.sprite.attr & SP_HIDDEN), "falling": (s.is_update_anim != FALSE) and (ch.is_lock_movement != FALSE)})
					c = c.next
		players.append(e)
	for gobj in Sim.get_link(nGCCommonLinkIDInterface):
		if not (gobj is IFGObj):
			continue
		var shown: bool = not (gobj.gobj_flags & GOBJ_FLAG_HIDDEN)
		if gobj.port_kind == "stock":
			var player: int = gobj.user_data
			var e: Dictionary = players[player]
			e.is_stock_visible = shown and (G.gSCManagerBattleState.players[player].stock_count >= 0)
			var sobj = SObjGetStruct(gobj)
			if B(G.gSCManagerBattleState.players[player].is_single_stockicon):
				if sobj != null:
					e.stock_icons = [sobj.pos]
			elif sIFCommonPlayerStocksNum[player] <= 6:
				while sobj != null:
					if not (sobj.sprite.attr & SP_HIDDEN):
						e.stock_icons.append(sobj.pos)
					sobj = sobj.next
			elif sobj != null:
				e.stock_number = sIFCommonPlayerStocksNum[player]
				e.stock_icons = [sobj.pos]
				e.stock_number_icon_pos = sobj.next.pos
				var d = sobj.next.next
				while d != null:
					if not (d.sprite.attr & SP_HIDDEN):
						e.stock_number_digit_pos.append(d.pos)
					d = d.next
		elif gobj.port_kind == "tag":
			var player: int = gobj.user_data
			var e: Dictionary = players[player]
			e.tag_visible = shown and (gobj.thread.get("port_drawn", -1) == port_frame)
			e.tag_pos = SObjGetStruct(gobj).pos
	var magnify: Array = []
	for player in 4:
		var ifmag: IFPlayerMagnify = sIFCommonPlayerMagnifyInterface[player]
		var vis: bool = ifmag.port_frame_drawn == port_frame
		var mc := _port_color8(dIFCommonPlayerMagnifyColorsR[ifmag.color_id % 5], dIFCommonPlayerMagnifyColorsG[ifmag.color_id % 5], dIFCommonPlayerMagnifyColorsB[ifmag.color_id % 5])
		var fog := _port_ground_color("fog_color")
		var fgobj = bs.players[player].fighter_gobj if bs.players[player].pkind != nFTPlayerKindNot else null
		var dobj = DObjGetStruct(ifmag.interface_gobj) if ifmag.interface_gobj != null else null
		magnify.append({"visible": vis, "screen_pos": ifmag.port_screen_pos, "rel_pos": ifmag.pos,
			"world_pos": fgobj.joints[nFTPartsJointTopN].translate if (fgobj != null) and (fgobj.joints.size() > 0) and (fgobj.joints[0] != null) else Vector3.ZERO,
			"angle": dobj.rotate.z if dobj != null else 0.0, "scale": gIFCommonPlayerInterface.magnify_scale, "color": mc,
			"fog_color": _port_color8(fog.get("r", 0), fog.get("g", 0), fog.get("b", 0)), "rect": ifmag.port_rect,
			"viewport_rect": ifmag.port_viewport_rect, "fighter_gobj": fgobj})
	var arrows := {"left": {"visible": false, "status": gIFCommonPlayerInterface.arrows_left_status, "anim_frame": 0.0, "pos": Vector2(-134.0, 0.0)},
		"right": {"visible": false, "status": gIFCommonPlayerInterface.arrows_right_status, "anim_frame": 0.0, "pos": Vector2(134.0, 0.0)},
		"color": _port_color8(0xFF, 0x00, 0x00, 0x80)}
	for gobj in Sim.get_link(nGCCommonLinkIDInterface):
		if (gobj is IFGObj) and ((gobj.port_kind == "arrow_left") or (gobj.port_kind == "arrow_right")):
			var side: String = "left" if gobj.port_kind == "arrow_left" else "right"
			arrows[side].visible = (gobj.thread.get("port_drawn", -1) == port_frame) and not (gobj.gobj_flags & GOBJ_FLAG_HIDDEN)
			arrows[side].anim_frame = gobj.anim_frame
			var cam = Gmcamera.gGMCameraStruct
			arrows[side].pos = Vector2(cam.viewport_center_x + DObjGetStruct(gobj).translate.x, cam.viewport_center_y - DObjGetStruct(gobj).translate.y)
	var announce := {"kind": "", "frame": 0}
	if announcements.size() > 0:
		announce = announcements[announcements.size() - 1]
	ui = {
		"frame": port_frame,
		"game_status": bs.game_status,
		"players": players,
		"timer": timer,
		"announce": announce,
		"announcements": announcements,
		"countdown": countdown,
		"pause": pause,
		"magnify": magnify,
		"arrows": arrows,
		"item_arrows": item_arrows,
		"stock_steals": steals,
		"screen_flash": Ifscreenflash.port_display_color.duplicate(),
		"draw": _port_draw,
	}
