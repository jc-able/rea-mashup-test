## Port of src/it/itdisplay.c (ssb-decomp-re): item display callbacks (gcAddGObjDisplay procs).
## Rendering is done by the render layer (item.visual_kind placeholders): the draw primitives
## below are display stubs (StubLog). The selection logic of each proc_display and
## itDisplayCheckItemVisible are ported 1:1 (they only read item / fighter state).
class_name Itdisplay
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80171410 - debug hitbox / hurtbox display (display list only)
static func itDisplayHitCollisions(item_gobj = null) -> void:
	StubLog.hit("Itdisplay.itDisplayHitCollisions")

## 0x801719AC - debug map collision diamond display (display list only)
static func itDisplayMapCollisions(item_gobj = null) -> void:
	StubLog.hit("Itdisplay.itDisplayMapCollisions")

## 0x80171C10
static func itDisplayCheckItemVisible(ip = null) -> int:
	var fp: Fighter

	if ip.owner_gobj == null:
		return TRUE

	elif not B(ip.is_hold):
		return TRUE

	fp = ftGetStruct(ip.owner_gobj)

	if not B(fp.is_item_show):
		return FALSE

	elif B(fp.is_invisible):
		return FALSE

	else:
		return TRUE

## 0x80171C7C
static func itDisplayOPAProcDisplay(item_gobj = null) -> void:
	_itDisplayProcDisplay(item_gobj, Callable(Itdisplay, &"_itDisplayDrawDObjTree"))

## 0x80171D38
static func itDisplayXLUProcDisplay(item_gobj = null) -> void:
	_itDisplayProcDisplay(item_gobj, Callable(Itdisplay, &"_itDisplayDrawDObjTreeDLLinks"))

## 0x80171DF4 - colour-animated OPA draw (display list only)
static func itDisplayColAnimOPA(item_gobj = null) -> void:
	StubLog.hit("Itdisplay.itDisplayColAnimOPA")

## 0x80171F4C
static func itDisplayColAnimOPAProcDisplay(item_gobj = null) -> void:
	_itDisplayProcDisplay(item_gobj, Callable(Itdisplay, &"itDisplayColAnimOPA"))

## 0x80172008 - colour-animated XLU draw (display list only)
static func itDisplayColAnimXLU(item_gobj = null) -> void:
	StubLog.hit("Itdisplay.itDisplayColAnimXLU")

## 0x8017224C
static func itDisplayColAnimXLUProcDisplay(item_gobj = null) -> void:
	_itDisplayProcDisplay(item_gobj, Callable(Itdisplay, &"itDisplayColAnimXLU"))

# // // // // // // // // // // // //
# //         PORT HELPERS          //
# // // // // // // // // // // // //

## Shared body of the four proc_display callbacks (draw == the model draw routine).
static func _itDisplayProcDisplay(item_gobj, draw: Callable) -> void:
	var ip := itGetStruct(item_gobj)

	if itDisplayCheckItemVisible(ip) != FALSE:
		if (ip.display_mode == nDBDisplayModeMaster) or B(ip.is_hold):
			draw.call(item_gobj)

		elif ip.display_mode == nDBDisplayModeMapCollision:
			draw.call(item_gobj)
			itDisplayMapCollisions(item_gobj)

		elif (ip.damage_coll.hitstatus == nGMHitStatusNone) and (ip.attack_coll.attack_state == nGMAttackStateOff):
			draw.call(item_gobj)

		else:
			itDisplayHitCollisions(item_gobj)

## gcDrawDObjTreeForGObj (display list only)
static func _itDisplayDrawDObjTree(item_gobj) -> void:
	StubLog.hit("Itdisplay.gcDrawDObjTreeForGObj")

## gcDrawDObjTreeDLLinksForGObj (display list only)
static func _itDisplayDrawDObjTreeDLLinks(item_gobj) -> void:
	StubLog.hit("Itdisplay.gcDrawDObjTreeDLLinksForGObj")
