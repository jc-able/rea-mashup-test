## 1:1 port of src/it/itmonster/itsawamura.c (ssb-decomp-re): Poké Ball Hitmonlee (flying kick).
##
## Make function (dITManagerProcMakeList entry, called through itManagerMakeItemKind):
##   Itsawamura.itSawamuraMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int) -> item_gobj or null
## Shared conventions of the itmonster ports (descs, DObjDesc data, AnimJoints, u16 wrap): see Itpippi.gd.
## ITAttributes: llITCommonDataSawamuraItemAttributes (251_ITCommonData.c @ 0x0BB0, shield_damage 30
## as in the ROM), from the item core's ROM-verified table.
class_name Itsawamura
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itSawamuraStatus
const nITSawamuraStatusFall = 0
const nITSawamuraStatusWait = 1
const nITSawamuraStatusAttack = 2
const nITSawamuraStatusEnumCount = 3

# llITCommonData* linker offsets used by this file (tools/relocFileDescriptions.us.txt)
const llITCommonDataSawamuraDataStart = 0x11F40
const llITCommonDataSawamuraDisplayList = 0x12340

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8018B220
static var dITSawamuraItemDesc := {
	"kind": nITKindSawamura,                                    # Item Kind
	"o_attributes": "llITCommonDataSawamuraItemAttributes",     # &gITManagerCommonData, &llITCommonDataSawamuraItemAttributes

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindTraRotRpyR,                         # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"attack_state": nGMAttackStateNew,                          # Hitbox Update State
	"proc_update": Callable(Itsawamura, &"itSawamuraCommonProcUpdate"), # Proc Update
	"proc_map": Callable(Itsawamura, &"itSawamuraCommonProcMap"),       # Proc Map
	"proc_hit": Callable(),                                     # Proc Hit
	"proc_shield": Callable(),                                  # Proc Shield
	"proc_hop": Callable(),                                     # Proc Hop
	"proc_setoff": Callable(),                                  # Proc Set-Off
	"proc_reflector": Callable(),                               # Proc Reflector
	"proc_damage": Callable(),                                  # Proc Damage
}

## 0x8018B254
static var dITSawamuraStatusDescs: Array = [
	# Status 0 (Air Fall)
	{
		"proc_update": Callable(Itsawamura, &"itSawamuraFallProcUpdate"),
		"proc_map": Callable(Itsawamura, &"itSawamuraFallProcMap"),
		"proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},

	# Status 1 (Air Fall)
	{
		"proc_update": Callable(Itsawamura, &"itSawamuraWaitProcUpdate"),
		"proc_map": Callable(Itsawamura, &"itSawamuraWaitProcMap"),
		"proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},

	# Status 2 (Neutral Attack)
	{
		"proc_update": Callable(Itsawamura, &"itSawamuraAttackProcUpdate"),
		"proc_map": Callable(), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80182630
static func itSawamuraFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITSAWAMURA_GRAVITY, ITSAWAMURA_TVEL)

	return FALSE

## 0x80182660
static func itSawamuraFallProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if B(Itmap.itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_FLOOR)):
		ip.physics.vel_air.y = 0.0

		itSawamuraWaitSetStatus(item_gobj)

	return FALSE

## 0x801826A8
static func itSawamuraFallSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITSawamuraStatusDescs, nITSawamuraStatusFall)

## 0x801826D0
static func itSawamuraWaitProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		itSawamuraAttackSetStatus(item_gobj)

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x80182714
static func itSawamuraWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itsawamura, &"itSawamuraFallSetStatus"))

	return FALSE

## 0x8018273C
static func itSawamuraWaitSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITSawamuraStatusDescs, nITSawamuraStatusWait)

## 0x80182764
static func itSawamuraAttackProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITSAWAMURA_GRAVITY, ITSAWAMURA_TVEL)

	if (ip.lr == +1) and (dobj.translate.x >= (Mpcollision.gMPCollisionGroundData.map_bound_right - ITSAWAMURA_DESPAWN_OFF_X)):
		return TRUE

	elif (ip.lr == -1) and (dobj.translate.x <= (Mpcollision.gMPCollisionGroundData.map_bound_left + ITSAWAMURA_DESPAWN_OFF_X)):
		return TRUE

	elif ip.multi == 0:
		return TRUE

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x8018285C
static func itSawamuraAttackSetFollowPlayerLR(item_gobj, fighter_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var fp := ftGetStruct(fighter_gobj)
	var ij := DObjGetStruct(item_gobj)
	var fj := DObjGetStruct(fighter_gobj)
	var dist: Vector3
	var target_pos: Vector3

	target_pos = fj.translate

	target_pos.y += ITSAWAMURA_TARGET_POS_OFF_Y - fp.coll_data.map_coll.bottom

	dist = target_pos - ij.translate # syVectorDiff3D(&dist, &target_pos, &ij->translate.vec.f)

	ip.physics.vel_air.z = 0.0
	ip.physics.vel_air.y = ip.physics.vel_air.z
	ip.physics.vel_air.x = ITSAWAMURA_KICK_VEL_X

	ip.physics.vel_air = syVectorRotate3D(ip.physics.vel_air, SYVECTOR_AXIS_Z, syUtilsArcTan2(dist.y, dist.x))

	ip.lr = -1 if (dist.x < 0.0) else +1

	if ip.lr == +1:
		ij.rotate.y = F_CST_DTOR32(180.0)

## 0x80182958
## Port note: like C, victim_gobj is only set when an enemy fighter exists (C reads an
## uninitialised local otherwise; this port would fail on the null victim).
static func itSawamuraAttackInitVars(item_gobj) -> void:
	# REGION_US
	var ip := itGetStruct(item_gobj)
	var victim_gobj = null
	var dobj := DObjGetStruct(item_gobj)
	var square_xy: float
	var dist_xy: float = 0.0
	var dist: Vector3
	var players: int = 0

	for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		var fp := ftGetStruct(fighter_gobj)

		# REGION_US
		if (fighter_gobj != ip.owner_gobj) and (fp.team != ip.team):
			dist = DObjGetStruct(fighter_gobj).translate - dobj.translate # syVectorDiff3D

			if players == 0:
				dist_xy = SQUARE(dist.x) + SQUARE(dist.y)

			players += 1

			square_xy = SQUARE(dist.x) + SQUARE(dist.y)

			if square_xy <= dist_xy:
				dist_xy = square_xy

				victim_gobj = fighter_gobj

	itSawamuraAttackSetFollowPlayerLR(item_gobj, victim_gobj)

	if ip.kind == nITKindSawamura:
		# itGetPData(ip, &llITCommonDataSawamuraDataStart, &llITCommonDataSawamuraDisplayList) == ITCommonObject + 0x12340
		var dl = "dITCommonObject_Sawamura_Item_data_remainder_gap_0x11FC4_sub_0x37C"

		dobj.dl = dl

		Snd.func_800269C0_275C0(nSYAudioVoiceMBallSawamuraKick)

	ip.multi = ITSAWAMURA_LIFETIME

	ip.attack_coll.size = ITSAWAMURA_KICK_SIZE

## 0x80182AAC
static func itSawamuraAttackSetStatus(item_gobj) -> void:
	itSawamuraAttackInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITSawamuraStatusDescs, nITSawamuraStatusAttack)

## 0x80182AE0
static func itSawamuraCommonProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		ip.multi = ITSAWAMURA_KICK_WAIT

		ip.physics.vel_air.y = 0.0

		itSawamuraFallSetStatus(item_gobj)

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x80182B34
static func itSawamuraCommonProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if B(Itmap.itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_FLOOR)):
		ip.physics.vel_air.y = 0.0

	return FALSE

## 0x80182B74
static func itSawamuraMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITSawamuraItemDesc, pos, vel, flags)

	if item_gobj != null:
		var dobj := DObjGetStruct(item_gobj)
		var ip := itGetStruct(item_gobj)

		ip.multi = ITMONSTER_RISE_STOP_WAIT

		ip.physics.vel_air.z = 0.0
		ip.physics.vel_air.x = ip.physics.vel_air.z
		ip.physics.vel_air.y = ITMONSTER_RISE_VEL_Y

		Objman.gcAddXObjForDObjFixed(dobj, 0x48, 0)

		dobj.translate = pos

		dobj.translate.y -= ip.attr.map_coll_bottom

		# itGetMonsterAnimNode(ip, &llITCommonDataSawamuraDataStart) == ITCommonObject + 0x13624
		ObjAnim.gcAddDObjAnimJoint(dobj, Itpippi.dITCommonObjectMonsterAnimBank, 0.0)

		Snd.func_800269C0_275C0(nSYAudioVoiceMBallSawamuraAppear)

		# item_gobj->dl_link_priority: itManagerMakeItem registers every item display with GOBJ_PRIORITY_DEFAULT
		Objman.gcMoveGObjDLHead(item_gobj, 18, GOBJ_PRIORITY_DEFAULT)

	return item_gobj
