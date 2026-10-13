## 1:1 port of src/it/itmonster/itmew.c (ssb-decomp-re): Poké Ball Mew.
##
## Make function (dITManagerProcMakeList entry, called through itManagerMakeItemKind):
##   Itmew.itMewMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int) -> item_gobj or null
## Shared conventions of the itmonster ports (descs, DObjDesc data, AnimJoints, u16 wrap): see Itpippi.gd.
class_name Itmew
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itMewStatus
const nITMewStatusFly = 0
const nITMewStatusEnumCount = 1

# llITCommonData* linker offsets used by this file (tools/relocFileDescriptions.us.txt)
const llITCommonDataMewDataStart = 0xBCC0

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8018AC40
static var dITMewItemDesc := {
	"kind": nITKindMew,                                         # Item Kind
	"o_attributes": "llITCommonDataMewItemAttributes",        # &gITManagerCommonData, &llITCommonDataMewItemAttributes (item core table)

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindTraRotRpyRSca,                      # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"attack_state": nGMAttackStateOff,                          # Hitbox Update State
	"proc_update": Callable(Itmew, &"itMewCommonProcUpdate"),   # Proc Update
	"proc_map": Callable(Itmew, &"itMewCommonProcMap"),         # Proc Map
	"proc_hit": Callable(),                                     # Proc Hit
	"proc_shield": Callable(),                                  # Proc Shield
	"proc_hop": Callable(),                                     # Proc Hop
	"proc_setoff": Callable(),                                  # Proc Set-Off
	"proc_reflector": Callable(),                               # Proc Reflector
	"proc_damage": Callable(),                                  # Proc Damage

	"visual_kind": "monster_mew",
}

## 0x8018AC74
static var dITMewStatusDescs: Array = [
	# Status 0 (Neutral FLy)
	{
		"proc_update": Callable(Itmew, &"itMewFlyProcUpdate"),  # Proc Update
		"proc_map": Callable(),                                 # Proc Map
		"proc_hit": Callable(),                                 # Proc Hit
		"proc_shield": Callable(),                              # Proc Shield
		"proc_hop": Callable(),                                 # Proc Hop
		"proc_setoff": Callable(),                              # Proc Set-Off
		"proc_reflector": Callable(),                           # Proc Reflector
		"proc_damage": Callable(),                              # Proc Damage
	},
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8017EBE0
static func itMewFlyProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var pos: Vector3 = DObjGetStruct(item_gobj).translate

	if ip.multi == 0:
		return TRUE

	if ip.item_vars.mew.esper_gfx_int == 0:
		ip.item_vars.mew.esper_gfx_int = ITMEW_EFFECT_SPAWN_INT

		Efmanager.efManagerHealSparklesMakeEffect(pos)

	ip.item_vars.mew.esper_gfx_int -= 1

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	ip.physics.vel_air.y += ITMEW_FLY_ADD_VEL_Y

	return FALSE

## 0x8017EC84
static func itMewFlyInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.multi = ITMEW_LIFETIME

	if syUtilsRandIntRange(2) != 0:
		ip.physics.vel_air.x = ITMEW_STARTVEL_X

	else:
		ip.physics.vel_air.x = -ITMEW_STARTVEL_X

	ip.physics.vel_air.y = ITMEW_STARTVEL_Y

	Snd.func_800269C0_275C0(nSYAudioFGMMewFly)

	if ip.kind == nITKindMew:
		Snd.func_800269C0_275C0(nSYAudioVoiceMBallMewAppear)

	Efmanager.efManagerRippleMakeEffect(DObjGetStruct(item_gobj).translate)

	ip.item_vars.mew.esper_gfx_int = 0

## 0x8017ED20
static func itMewFlySetStatus(item_gobj) -> void:
	itMewFlyInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITMewStatusDescs, nITMewStatusFly)

## 0x8017ED54
static func itMewCommonProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		ip.physics.vel_air.y = 0.0

		itMewFlySetStatus(item_gobj)

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x8017EDA4
static func itMewCommonProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if B(Itmap.itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_FLOOR)):
		ip.physics.vel_air.y = 0.0

	return FALSE

## 0x8017EDE4
static func itMewMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITMewItemDesc, pos, vel, flags)

	if item_gobj != null:
		var dobj := DObjGetStruct(item_gobj)
		var ip := itGetStruct(item_gobj)

		ip.multi = ITMONSTER_RISE_STOP_WAIT

		ip.physics.vel_air.z = 0.0
		ip.physics.vel_air.x = ip.physics.vel_air.z
		ip.physics.vel_air.y = ITMONSTER_RISE_VEL_Y # Starting to think this is a macro

		dobj.translate.y -= ip.attr.map_coll_bottom

		# This ptr stuff is likely also a macro
		# itGetMonsterAnimNode(ip, &llITCommonDataMewDataStart) == ITCommonObject + 0x13624
		ObjAnim.gcAddDObjAnimJoint(dobj, Itpippi.dITCommonObjectMonsterAnimBank, 0.0)

	return item_gobj
