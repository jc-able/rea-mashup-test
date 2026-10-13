## 1:1 port of src/it/itmonster/itmlucky.c (ssb-decomp-re): Poké Ball Chansey (lays eggs).
##
## Make function (dITManagerProcMakeList entry, called through itManagerMakeItemKind):
##   Itmlucky.itMLuckyMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int) -> item_gobj or null
## Shared conventions of the itmonster ports (descs, DObjDesc data, AnimJoints, u16 wrap): see Itpippi.gd.
## ITAttributes: llITCommonDataMLuckyItemAttributes (251_ITCommonData.c @ 0x0A84), from the item
## core's ROM-verified table.
class_name Itmlucky
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itMLuckyStatus
const nITMLuckyStatusFall = 0
const nITMLuckyStatusAppear = 1
const nITMLuckyStatusMakeEgg = 2
const nITMLuckyStatusDisappear = 3
const nITMLuckyStatusEnumCount = 4

# llITCommonData* linker offsets used by this file (tools/relocFileDescriptions.us.txt)
const llITCommonDataLuckyDataStart = 0x10000
const llITCommonDataLuckyAnimJoint = 0x100BC

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8018AFB0
static var dITMLuckyItemDesc := {
	"kind": nITKindMLucky,                                      # Item Kind
	"o_attributes": "llITCommonDataMLuckyItemAttributes",       # &gITManagerCommonData, &llITCommonDataMLuckyItemAttributes

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindTraRotRpyR,                         # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"attack_state": nGMAttackStateOff,                          # Hitbox Update State
	"proc_update": Callable(Itmlucky, &"itMLuckyCommonProcUpdate"), # Proc Update
	"proc_map": Callable(Itmlucky, &"itMLuckyCommonProcMap"),       # Proc Map
	"proc_hit": Callable(),                                     # Proc Hit
	"proc_shield": Callable(),                                  # Proc Shield
	"proc_hop": Callable(),                                     # Proc Hop
	"proc_setoff": Callable(),                                  # Proc Set-Off
	"proc_reflector": Callable(),                               # Proc Reflector
	"proc_damage": Callable(),                                  # Proc Damage
}

## 0x8018AFE4
static var dITMLuckyStatusDescs: Array = [
	# Status 0 (Air Fall)
	{
		"proc_update": Callable(Itmlucky, &"itMLuckyFallProcUpdate"),
		"proc_map": Callable(Itmlucky, &"itMLuckyFallProcMap"),
		"proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},

	# Status 1 (Neutral Appear)
	{
		"proc_update": Callable(Itmlucky, &"itMLuckyAppearProcUpdate"),
		"proc_map": Callable(Itmlucky, &"itMLuckyAppearProcMap"),
		"proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},

	# Status 2 (Neutral Egg Spawn)
	{
		"proc_update": Callable(Itmlucky, &"itMLuckyMakeEggProcUpdate"),
		"proc_map": Callable(Itmlucky, &"itMLuckyMakeEggProcMap"),
		"proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(),
		"proc_damage": Callable(Itmlucky, &"itMLuckyMakeEggProcDamage"),
	},

	# Status 3 (Neutral Disappear)
	{
		"proc_update": Callable(Itmlucky, &"itMLuckyDisappearProcUpdate"),
		"proc_map": Callable(Itmlucky, &"itMLuckyMakeEggProcMap"),
		"proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},
]

## AObjEvent32 script dITCommonObject_MLucky_Item_data_remainder_gap_0x100B0_sub_0xC
## (86_ITCommonObject.c @ 0x100BC == llITCommonDataLuckyAnimJoint): Chansey's egg-laying bob on the
## model joint (render only). 36 words, identical to ROM file 86.
static var dITCommonObjectLuckyAnimJoint: AnimStream = _itMLuckyMakeAnimJoint()

static func _itMLuckyMakeAnimJoint() -> AnimStream:
	var anim_joint := AnimStream.from_u32([
		0x0CD00000, 0x00000000, 0x3F745303, 0x3F800000, 0xBB9461C7, 0x3F800000, 0x3B9E7784, # [0] aobjEvent32SetValRate(AOBJ_FLAG_TRAY | AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 0): 0, 0.954391658, 1, -0.00452825753, 1, 0.00483602472
		0x15280000, 0x00000000, 0x00000000, 0x3F800000, # [7] aobjEvent32SetValAfterBlock(AOBJ_FLAG_TRAX | AOBJ_FLAG_TRAZ | AOBJ_FLAG_SCAZ, 0): 0, 0, 1
		0x10D00010, 0x411C0000, 0x3F733333, 0x3F866666, # [11] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_TRAY | AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 16): 9.75, 0.949999988, 1.04999995
		0x0AD00010, 0x00000000, 0xBF617C7F, 0x3F800000, 0x3B95F5F2, 0x3F800000, 0xBB88762C, # [15] aobjEvent32SetValRateBlock(AOBJ_FLAG_TRAY | AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 16): 0, -0.88080591, 1, 0.00457643811, 1, -0.00416447781
		0x10D00010, 0xC11C0000, 0x3F866666, 0x3F733333, # [22] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_TRAY | AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 16): -9.75, 1.04999995, 0.949999988
		0x0AD00010, 0x00000000, 0x3F5D419A, 0x3F800000, 0xBB916343, 0x3F800000, 0x3B8E06C2, # [26] aobjEvent32SetValRateBlock(AOBJ_FLAG_TRAY | AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 16): 0, 0.86428225, 1, -0.00443688175, 1, 0.00433430169
		0x1C000000, # [33] aobjEvent32SetAnim(0x000, 0)
		0x00000000, # [34] (u32)dITCommonObject_MLucky_Item_data_remainder_gap_0x100B0_sub_0xC
		0x00000000, # [35] aobjEvent32End()
	], "dITCommonObject_MLucky_Item_data_remainder_gap_0x100B0_sub_0xC")
	anim_joint.ptr[34] = [anim_joint, 0] # SetAnim target: the start of this same script

	return anim_joint

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80180FC0
static func itMLuckyMakeEggInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	if ip.kind == nITKindMLucky:
		# itGetPData(ip, &llITCommonDataLuckyDataStart, &llITCommonDataLuckyAnimJoint) == ITCommonObject + 0x100BC
		ObjAnim.gcAddDObjAnimJoint(dobj.child, dITCommonObjectLuckyAnimJoint, 0.0)
		ObjAnim.gcPlayAnimAll(item_gobj)

	ip.damage_coll.hitstatus = nGMHitStatusNormal

	ip.item_vars.mlucky.egg_spawn_wait = ITMLUCKY_EGG_SPAWN_WAIT_CONST

	ip.multi = ITMLUCKY_EGG_SPAWN_COUNT

## 0x80181048
static func itMLuckyFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITMLUCKY_GRAVITY, ITMLUCKY_TVEL)

	return FALSE

## 0x80181074
static func itMLuckyFallProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmap.itMapTestAllCheckCollEnd(item_gobj)

	if ip.coll_data.mask_curr & MAP_FLAG_FLOOR:
		ip.physics.vel_air.y = 0.0

		if ip.multi != 0:
			itMLuckyMakeEggSetStatus(item_gobj)

		else:
			itMLuckyDisappearSetStatus(item_gobj)

	return FALSE

## 0x801810E0
static func itMLuckyFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITMLuckyStatusDescs, nITMLuckyStatusFall)

## 0x80181124
static func itMLuckyAppearProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITMLUCKY_GRAVITY, ITMLUCKY_TVEL)

	return FALSE

## 0x80181150
static func itMLuckyAppearProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmap.itMapTestAllCheckCollEnd(item_gobj)

	if ip.coll_data.mask_curr & MAP_FLAG_FLOOR:
		ip.physics.vel_air.y = 0.0

		itMLuckyMakeEggSetStatus(item_gobj)

		itMLuckyMakeEggInitVars(item_gobj)

	return FALSE

## 0x801811AC
static func itMLuckyAppearSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	if ip.kind == nITKindMLucky:
		Snd.func_800269C0_275C0(nSYAudioVoiceMBallLuckyAppear)

	Itmain.itMainSetStatus(item_gobj, dITMLuckyStatusDescs, nITMLuckyStatusAppear)

## 0x80181200
static func itMLuckyMakeEggProcUpdate(lucky_gobj) -> int:
	var lucky_ip := itGetStruct(lucky_gobj)
	var egg_ip: Item
	var dobj := DObjGetStruct(lucky_gobj)
	var egg_gobj
	var pos: Vector3
	var vel: Vector3

	if lucky_ip.multi == 0:
		itMLuckyDisappearSetStatus(lucky_gobj)

		return FALSE

	else:
		if lucky_ip.item_vars.mlucky.egg_spawn_wait == 0:
			if (G.gSCManagerBattleState.item_toggles & (1 << nITKindEgg)) and (G.gSCManagerBattleState.item_appearance_rate != nSCBattleItemSwitchNone): # ITEM_TOGGLE_MASK_KIND(nITKindEgg)
				pos = dobj.translate

				vel.x = (syUtilsRandFloat() * ITMLUCKY_EGG_SPAWN_BASE_VEL) + ITMLUCKY_EGG_SPAWN_ADD_VEL_X
				vel.y = (syUtilsRandFloat() * ITMLUCKY_EGG_SPAWN_BASE_VEL) + ITMLUCKY_EGG_SPAWN_ADD_VEL_Y
				vel.z = 0.0

				egg_gobj = Itmanager.itManagerMakeItemSetupCommon(lucky_gobj, nITKindEgg, pos, vel, (ITEM_FLAG_COLLPROJECT | ITEM_FLAG_PARENT_ITEM))

				if egg_gobj != null:
					egg_ip = itGetStruct(egg_gobj)

					Snd.func_800269C0_275C0(nSYAudioFGMKirbySpecialLwStart)

					lucky_ip.item_vars.mlucky.egg_spawn_wait = ITMLUCKY_EGG_SPAWN_WAIT_CONST
					lucky_ip.multi = (lucky_ip.multi - 1) & 0xFFFF # u16

					Efmanager.efManagerDustLightMakeEffect(pos, egg_ip.lr, 1.0)

			else:
				lucky_ip.item_vars.mlucky.egg_spawn_wait = ITMLUCKY_EGG_SPAWN_WAIT_CONST
				lucky_ip.multi = (lucky_ip.multi - 1) & 0xFFFF # u16

		if lucky_ip.item_vars.mlucky.egg_spawn_wait > 0:
			lucky_ip.item_vars.mlucky.egg_spawn_wait = (lucky_ip.item_vars.mlucky.egg_spawn_wait - 1) & 0xFFFF # u16

	return FALSE

## 0x80181368
static func itMLuckyMakeEggProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itmlucky, &"itMLuckyFallSetStatus"))

	return FALSE

## 0x80181390
static func itMLuckyMakeEggProcDamage(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.item_vars.mlucky.egg_spawn_wait = (ip.item_vars.mlucky.egg_spawn_wait + ITMLUCKY_EGG_SPAWN_WAIT_ADD) & 0xFFFF # u16

	return FALSE

## 0x801813A8
static func itMLuckyMakeEggSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITMLuckyStatusDescs, nITMLuckyStatusMakeEgg)

## 0x801813D0
static func itMLuckyDisappearProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.item_vars.mlucky.lifetime == 0:
		return TRUE

	ip.item_vars.mlucky.lifetime = (ip.item_vars.mlucky.lifetime - 1) & 0xFFFF # u16

	return FALSE

## 0x801813F8
static func itMLuckyDisappearSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.item_vars.mlucky.lifetime = ITMLUCKY_LIFETIME

	ip.damage_coll.hitstatus = nGMHitStatusNone

	Itmain.itMainSetStatus(item_gobj, dITMLuckyStatusDescs, nITMLuckyStatusDisappear)

## 0x80181430
static func itMLuckyCommonProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		ip.physics.vel_air.y = 0.0

		itMLuckyAppearSetStatus(item_gobj)

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x80181480
static func itMLuckyCommonProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if B(Itmap.itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_FLOOR)):
		ip.physics.vel_air.y = 0.0

	return FALSE

## 0x801814C0
static func itMLuckyMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITMLuckyItemDesc, pos, vel, flags)
	var dobj: DObj
	var ip: Item

	if item_gobj != null:
		dobj = DObjGetStruct(item_gobj)

		Objman.gcAddXObjForDObjFixed(dobj.child, 0x2C, 0)

		dobj.translate = pos

		ip = itGetStruct(item_gobj)

		ip.multi = ITMONSTER_RISE_STOP_WAIT

		ip.physics.vel_air.z = 0.0
		ip.physics.vel_air.x = ip.physics.vel_air.z
		ip.physics.vel_air.y = ITMONSTER_RISE_VEL_Y

		dobj.translate.y -= ip.attr.map_coll_bottom

		# itGetMonsterAnimNode(ip, &llITCommonDataLuckyDataStart) == ITCommonObject + 0x13624
		ObjAnim.gcAddDObjAnimJoint(dobj.child, Itpippi.dITCommonObjectMonsterAnimBank, 0.0)

	return item_gobj
