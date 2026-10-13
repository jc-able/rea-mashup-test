## 1:1 port of src/if/ifscreenflash.c (ssb-decomp-re): full-screen colour flash (explosions,
## fire/electric/ice hits). The GBI fill-rectangle of ifScreenFlashProcDisplay is replaced by the
## HUD model: Ifcommon.ui.screen_flash = port_display_color (see Ifcommon.gd header).
class_name Ifscreenflash
extends Port

# // // // // // // // // // // // //
# //   GLOBAL / STATIC VARIABLES   //
# // // // // // // // // // // // //

## 0x80131A40
static var sIFScreenFlashColAnim: GMColAnim = GMColAnim.new()

## 0x80131AA4
static var sIFScreenFlashAlpha: int = 0                 # u8

## port-only: what ifScreenFlashProcDisplay drew this frame
## {active, r, g, b, a (0..255), rect: [10, 10, 310, 230], colanim_id, length}
static var port_display_color: Dictionary = {}

## port-only: overlay BSS clear (syDmaLoadOverlay bzero) at VS battle scene start.
static func port_reset_bss() -> void:
	sIFScreenFlashColAnim = GMColAnim.new()
	sIFScreenFlashAlpha = 0
	port_display_color = {"active": false, "r": 0, "g": 0, "b": 0, "a": 0, "rect": [10, 10, 310, 230], "colanim_id": 0, "length": 0}

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80115BF0
static func ifScreenFlashSetColAnimID(colanim_id = 0, colanim_duration = 0) -> void:
	Ftparam.ftParamCheckSetColAnimID(sIFScreenFlashColAnim, colanim_id, colanim_duration)

## 0x80115C20
static func ifScreenFlashProcDisplay(gobj = null) -> void:
	var ca: GMColAnim = sIFScreenFlashColAnim
	var alpha: int

	port_display_color = {"active": false, "r": 0, "g": 0, "b": 0, "a": 0, "rect": [10, 10, 310, 230], "colanim_id": ca.colanim_id, "length": ca.length}

	if ca.is_use_color1:
		# gDPSetCombineMode(G_CC_PRIMITIVE) / G_RM_AA_XLU_SURF ...
		alpha = (int(ca.color1.a) * sIFScreenFlashAlpha) / 0xFF

		# gDPSetPrimColor(0, 0, r, g, b, alpha); gDPFillRectangle(10, 10, 310, 230)
		port_display_color.active = true
		port_display_color.r = ca.color1.r
		port_display_color.g = ca.color1.g
		port_display_color.b = ca.color1.b
		port_display_color.a = alpha

## 0x80115DA8
static func ifScreenFlashProcUpdate(fighter_gobj = null) -> void:
	if Ftmain.ftMainUpdateColAnim(sIFScreenFlashColAnim, fighter_gobj, FALSE, FALSE) != FALSE:
		Ftparam.ftParamResetColAnim(sIFScreenFlashColAnim)

## 0x80115DE8
static func ifScreenFlashMakeInterface(alpha = 0xFF) -> void:
	sIFScreenFlashAlpha = alpha & 0xFF

	Ftparam.ftParamResetColAnim(sIFScreenFlashColAnim)

	if G.gSCManagerBackupData.is_allow_screenflash != FALSE:
		var interface_gobj = Ifcommon._gcMakeGObjSPAfter(nGCCommonKindInterface, Callable(), nGCCommonLinkIDInterface, GOBJ_PRIORITY_DEFAULT)

		Ifcommon._gcAddGObjDisplay(interface_gobj, Callable(Ifscreenflash, &"ifScreenFlashProcDisplay"), 22, GOBJ_PRIORITY_DEFAULT, ~0)
		Objman.gcAddGObjProcess(interface_gobj, Callable(Ifscreenflash, &"ifScreenFlashProcUpdate"), nGCProcessKindFunc, 1)
