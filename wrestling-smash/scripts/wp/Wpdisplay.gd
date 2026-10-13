## Port of src/wp/wpdisplay.c (ssb-decomp-re): weapon display callbacks.
## Rendering itself is done by the Godot render layer; the RDP display-list commands
## (gDP*/gSP*, matrices) have no equivalent here. The decision logic of wpDisplayMain /
## wpDisplayPKThunderProcDisplay is kept 1:1 so the render layer can call the same
## proc_display Callable that wpManagerMakeWeapon installs (gcAddGObjDisplay).
class_name Wpdisplay
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x80188E10
static var dWPDisplayPKThunderPrimColors: Array = [Color8(0x5E, 0xA3, 0xFF), Color8(0x98, 0xBD, 0xFF), Color8(0xC2, 0xD9, 0xFF), Color8(0xB3, 0xF1, 0xFF)]

## 0x80188E1C
static var dWPDisplayPKThunderEnvColors: Array = [Color8(0x3A, 0x00, 0x83), Color8(0x5B, 0x00, 0xB2), Color8(0x86, 0x33, 0xD9), Color8(0xA7, 0x74, 0xF8)]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80166E80
## Render weapon hitboxes (debug display modes): display-list output only.
static func wpDisplayHitCollisions(weapon_gobj = null) -> void:
	StubLog.hit("Wpdisplay.wpDisplayHitCollisions")

## 0x801671F0
## Render weapon map collision diamond (debug display mode): display-list output only.
static func wpDisplayMapCollisions(weapon_gobj = null) -> void:
	StubLog.hit("Wpdisplay.wpDisplayMapCollisions")

## 0x80167454
static func wpDisplayDrawNormal() -> void:
	# gDPPipeSync / gSPClearGeometryMode(G_ZBUFFER) / gDPSetRenderMode(G_RM_AA_XLU_SURF, G_RM_AA_XLU_SURF2)
	pass

## 0x801674B8
static func wpDisplayDrawZBuffer() -> void:
	# gDPPipeSync / gSPSetGeometryMode(G_ZBUFFER) / gDPSetRenderMode(G_RM_AA_ZB_XLU_SURF, G_RM_AA_ZB_XLU_SURF2)
	pass

## 0x80167520
static func wpDisplayMain(weapon_gobj = null, proc_display = null) -> void:
	var wp := wpGetStruct(weapon_gobj)

	if wp.display_mode == nDBDisplayModeMapCollision:
		wpDisplayDrawNormal()

		proc_display.call(weapon_gobj)

		wpDisplayDrawZBuffer()

		wpDisplayMapCollisions(weapon_gobj)

	elif (wp.display_mode == nDBDisplayModeMaster) or (wp.attack_coll.attack_state == nGMAttackStateOff):
		wpDisplayDrawNormal()

		proc_display.call(weapon_gobj)

		wpDisplayDrawZBuffer()

	else:
		wpDisplayHitCollisions(weapon_gobj)

## 0x801675D0
static func wpDisplayDLHead1(weapon_gobj = null) -> void:
	wpDisplayMain(weapon_gobj, Callable(Objdisplay, &"gcDrawDObjDLHead1"))

## 0x801675F4
static func wpDisplayDObjDLLinks(weapon_gobj = null) -> void:
	wpDisplayMain(weapon_gobj, Callable(Objdisplay, &"gcDrawDObjDLLinksForGObj"))

## 0x80167618
static func func_ovl3_80167618(weapon_gobj = null) -> void:
	wpDisplayMain(weapon_gobj, Callable(Lbcommon, &"lbCommonDObjScaleXProcDisplay")) # Unused?

## 0x8016763C
static func wpDisplayDObjTreeDLLinks(weapon_gobj = null) -> void:
	wpDisplayMain(weapon_gobj, Callable(Objdisplay, &"gcDrawDObjTreeDLLinksForGObj"))

## 0x80167660
## Render PK Thunder specifically because life is short
static func wpDisplayPKThunderProcDisplay(weapon_gobj = null) -> void:
	var wp := wpGetStruct(weapon_gobj)
	var index: int = wp.weapon_vars.pkthunder_trail.trail_id

	if wp.display_mode == nDBDisplayModeMapCollision:
		wpDisplayDrawNormal()

		# gDPPipeSync / gDPSetPrimColor(dWPDisplayPKThunderPrimColors[index]) / gDPSetEnvColor(dWPDisplayPKThunderEnvColors[index])
		var _prim_color: Color = dWPDisplayPKThunderPrimColors[index]
		var _env_color: Color = dWPDisplayPKThunderEnvColors[index]

		Objdisplay.gcDrawDObjDLLinksForGObj(weapon_gobj)

		wpDisplayDrawZBuffer()

		wpDisplayMapCollisions(weapon_gobj)

	elif (wp.display_mode == nDBDisplayModeMaster) or (wp.attack_coll.attack_state == nGMAttackStateOff):
		wpDisplayDrawNormal()

		# gDPPipeSync / gDPSetPrimColor(dWPDisplayPKThunderPrimColors[index]) / gDPSetEnvColor(dWPDisplayPKThunderEnvColors[index])
		var _prim_color2: Color = dWPDisplayPKThunderPrimColors[index]
		var _env_color2: Color = dWPDisplayPKThunderEnvColors[index]

		Objdisplay.gcDrawDObjDLLinksForGObj(weapon_gobj)

		wpDisplayDrawZBuffer()

	else:
		wpDisplayHitCollisions(weapon_gobj)
