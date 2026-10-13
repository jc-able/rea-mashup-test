## 1:1 port of src/gr/grcommonsetup.c
class_name Grcommonsetup
extends Port

# // // // // // // // // // // // //
# //   GLOBAL / STATIC VARIABLES   //
# // // // // // // // // // // // //

## 0x801313E0
static var gGRCommonLayerGObjs: Array = [null, null, null, null]

## 0x801313F0 - GRStruct union (src/gr/grtypes.h): one Dictionary per member, C field names
## (SSBStructs.make_GR*GroundVars*). Like the C BSS union it is never cleared between battles; every
## field the stage code reads is written by that stage's init first.
static var gGRCommonStruct: Dictionary = {
	# Common stages
	"pupupu": SSBStructs.make_GRCommonGroundVarsPupupu(),
	"sector": SSBStructs.make_GRCommonGroundVarsSector(),
	"zebes": SSBStructs.make_GRCommonGroundVarsZebes(),
	"yoster": SSBStructs.make_GRCommonGroundVarsYoster(),
	"inishie": SSBStructs.make_GRCommonGroundVarsInishie(),
	"jungle": SSBStructs.make_GRCommonGroundVarsJungle(),
	"hyrule": SSBStructs.make_GRCommonGroundVarsHyrule(),
	"yamabuki": SSBStructs.make_GRCommonGroundVarsYamabuki(),
	"castle": SSBStructs.make_GRCommonGroundVarsCastle(),
	# Bonus stages
	"bonus1": SSBStructs.make_GRBonusGroundVarsBonus1(),
	"bonus2": SSBStructs.make_GRBonusGroundVarsBonus2(),
	"bonus3": SSBStructs.make_GRBonusGroundVarsBonus3(),
}

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80105600
static func grCommonSetupInitAll() -> void:
	var gMPCollisionGroundData: Dictionary = Grdisplay.grDisplayGetGroundData()

	gGRCommonLayerGObjs[0] = Grdisplay.grDisplayMakeGeometryLayer(gMPCollisionGroundData.gr_desc[0], 0, null)
	gGRCommonLayerGObjs[1] = Grdisplay.grDisplayMakeGeometryLayer(gMPCollisionGroundData.gr_desc[1], 1, Grdisplay.grDisplayGetYakumonoDObjs())
	gGRCommonLayerGObjs[2] = Grdisplay.grDisplayMakeGeometryLayer(gMPCollisionGroundData.gr_desc[2], 2, null)
	gGRCommonLayerGObjs[3] = Grdisplay.grDisplayMakeGeometryLayer(gMPCollisionGroundData.gr_desc[3], 3, null)

	Mpcollision.mpCollisionClearYakumonoAll()
	Grmainsetup.grMainSetupMakeGround()
	Mpcollision.mpCollisionInitYakumonoAll()
	Itmanager.itManagerMakeAppearActor()
	Efground.efGroundMakeAppearActor()
