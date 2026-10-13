## 1:1 port of src/it/itvisuals.c (ssb-decomp-re): item colour animation and spin updates.
class_name Itvisuals
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801713B0
static func itVisualsUpdateColAnim(item_gobj = null) -> void:
	var ip := itGetStruct(item_gobj)

	if Ftmain.ftMainUpdateColAnim(ip.colanim, item_gobj, FALSE, FALSE) != FALSE:
		Itmain.itMainClearColAnim(item_gobj)

## 0x801713F4
static func itVisualsUpdateSpin(item_gobj = null) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	dobj.rotate.z += ip.spin_step
