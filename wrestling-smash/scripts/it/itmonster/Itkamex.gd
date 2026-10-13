## 1:1 port of src/it/itmonster/itkamex.c (ssb-decomp-re): Poké Ball Blastoise and its Hydro Pump
## weapon (nWPKindKamexHydro; the weapon code lives in this C file, not in src/wp).
##
## Make function (dITManagerProcMakeList entry, called through itManagerMakeItemKind):
##   Itkamex.itKamexMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int) -> item_gobj or null
## Shared conventions of the itmonster ports (descs, DObjDesc data, AnimJoints, u16 wrap): see Itpippi.gd.
## ITAttributes: llITCommonDataKamexItemAttributes (251_ITCommonData.c @ 0x0A08, US angle 130);
## WPAttributes: llITCommonDataKamexHydroWeaponAttributes (@ 0x0A50, US values), both from the item
## core's ROM-verified tables; the Hydro Pump AnimJoints are attached here (gameplay: the hitbox X
## offset follows the animated translation of the stream joint).
class_name Itkamex
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itKamexStatus
const nITKamexStatusFall = 0
const nITKamexStatusAppear = 1
const nITKamexStatusAttack = 2

# llITCommonData* linker offsets used by this file (tools/relocFileDescriptions.us.txt)
const llITCommonDataKamexDataStart = 0xEA60
const llITCommonDataKamexDisplayList = 0xED60

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8018AEE0
static var dITKamexItemDesc := {
	"kind": nITKindKamex,                                       # Item Kind
	"o_attributes": "llITCommonDataKamexItemAttributes",        # &gITManagerCommonData, &llITCommonDataKamexItemAttributes

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindTraRotRpyR,                         # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"attack_state": nGMAttackStateNew,                          # Hitbox Update State
	"proc_update": Callable(Itkamex, &"itKamexCommonProcUpdate"),   # Proc Update
	"proc_map": Callable(Itkamex, &"itKamexCommonProcMap"),         # Proc Map
	"proc_hit": Callable(),                                     # Proc Hit
	"proc_shield": Callable(),                                  # Proc Shield
	"proc_hop": Callable(),                                     # Proc Hop
	"proc_setoff": Callable(),                                  # Proc Set-Off
	"proc_reflector": Callable(),                               # Proc Reflector
	"proc_damage": Callable(),                                  # Proc Damage
}

## 0x8018AF14
static var dITKamexStatusDescs: Array = [
	# Status 0 (Air Fall)
	{
		"proc_update": Callable(Itkamex, &"itKamexFallProcUpdate"),
		"proc_map": Callable(Itkamex, &"itKamexFallProcMap"),
		"proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},

	# Status 1 (Neutral Appear)
	{
		"proc_update": Callable(Itkamex, &"itKamexAppearProcUpdate"),
		"proc_map": Callable(Itkamex, &"itKamexAppearProcMap"),
		"proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},

	# Status 2 (Neutral Attack)
	{
		"proc_update": Callable(Itkamex, &"itKamexAttackProcUpdate"),
		"proc_map": Callable(Itkamex, &"itKamexAttackProcMap"),
		"proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},
]

## 0x8018AF74
## "attributes" (&gITManagerCommonData + llITCommonDataKamexHydroWeaponAttributes) is resolved on
## first use by _itKamexGetWeaponHydroWeaponDesc() (the item core table + the Hydro AnimJoints).
static var dITKamexWeaponHydroWeaponDesc := {
	"flags": 0x01,                                              # Render flags? (WEAPON_FLAG_DOBJDESC)
	"kind": nWPKindKamexHydro,                                  # Weapon Kind
	"attributes": null,

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindTraRotRpyRSca,                      # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"proc_update": Callable(Itkamex, &"itKamexWeaponHydroProcUpdate"),          # Proc Update
	"proc_map": Callable(),                                                     # Proc Map
	"proc_hit": Callable(Itkamex, &"itKamexWeaponHydroProcHit"),                # Proc Hit
	"proc_shield": Callable(Itkamex, &"itKamexWeaponHydroProcHit"),             # Proc Shield
	"proc_hop": Callable(),                                                     # Proc Hop
	"proc_setoff": Callable(Itkamex, &"itKamexWeaponHydroProcHit"),             # Proc Set-Off
	"proc_reflector": Callable(Itkamex, &"itKamexWeaponHydroProcReflector"),    # Proc Reflector
	"proc_absorb": Callable(Itkamex, &"itKamexWeaponHydroProcHit"),             # Proc Absorb

	"visual_kind": "kamex_hydro",
}

## AObjEvent32 scripts of dITCommonObject_KamexHydro_Weapon_animjoints = {NULL, 0xFA9C, 0xFB4C}
## (86_ITCommonObject.c @ 0xFA90); words identical to ROM file 86.
## 0xFA9C drives joint 1 (TraX 60 -> 4680 over 32 frames: itKamexWeaponHydroProcUpdate's hitbox offset).
static var dITCommonObjectKamexHydroAnimJoint1: AnimStream = _itKamexMakeAnimJoint1()

## 0xFB4C drives joint 2 (render only).
static var dITCommonObjectKamexHydroAnimJoint2: AnimStream = _itKamexMakeAnimJoint2()

static func _itKamexMakeAnimJoint1() -> AnimStream:
	var anim_joint := AnimStream.from_u32([
		0x17700000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, # [0] aobjEvent32SetValAfter(AOBJ_FLAG_TRAY | AOBJ_FLAG_TRAZ | AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAZ, 0): 0, 0, 1, 1
		0x0C800000, 0x3F800000, 0x3F80B307, # [5] aobjEvent32SetValRate(AOBJ_FLAG_SCAY, 0): 1, 1.00546348
		0x06080000, 0x42700000, # [8] aobjEvent32SetValBlock(AOBJ_FLAG_TRAX, 0): 60
		0x08080020, 0x45924000, # [10] aobjEvent32SetVal(AOBJ_FLAG_TRAX, 32): 4680
		0x10800004, 0x40800000, # [12] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAY, 4): 4
		0x10800005, 0x3F800000, # [14] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAY, 5): 1
		0x10800002, 0x40000000, # [16] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAY, 2): 2
		0x10800002, 0x3F800000, # [18] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAY, 2): 1
		0x10800002, 0x40000000, # [20] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAY, 2): 2
		0x0A800002, 0x3F800000, 0xB923704A, # [22] aobjEvent32SetValRateBlock(AOBJ_FLAG_SCAY, 2): 1, -0.000155867223
		0x10800002, 0x40000000, # [25] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAY, 2): 2
		0x10800002, 0x3F800000, # [27] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAY, 2): 1
		0x0A800002, 0x40000000, 0x39400277, # [29] aobjEvent32SetValRateBlock(AOBJ_FLAG_SCAY, 2): 2, 0.000183114651
		0x10800002, 0x3F800000, # [32] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAY, 2): 1
		0x0A800001, 0x40000000, 0xBA02A295, # [34] aobjEvent32SetValRateBlock(AOBJ_FLAG_SCAY, 1): 2, -0.000498333306
		0x0A800004, 0x00000000, 0xBEE77244, # [37] aobjEvent32SetValRateBlock(AOBJ_FLAG_SCAY, 4): 0, -0.452043653
		0x06800002, 0x00000000, # [40] aobjEvent32SetValBlock(AOBJ_FLAG_SCAY, 2): 0
		0x1C000000, # [42] aobjEvent32SetAnim(0x000, 0)
		0x00000000, # [43] (u32)(dITCommonObject_KamexHydro_Weapon_animjoints_0xFA9C)
	], "dITCommonObject_KamexHydro_Weapon_animjoints_0xFA9C")
	anim_joint.ptr[43] = [anim_joint, 0] # SetAnim target: the start of this same script

	return anim_joint

static func _itKamexMakeAnimJoint2() -> AnimStream:
	var anim_joint := AnimStream.from_u32([
		0x08080000, 0xC3160000, # [0] aobjEvent32SetVal(AOBJ_FLAG_TRAX, 0): -150
		0x16300000, 0x00000000, 0x00000000, # [2] aobjEvent32SetValAfter(AOBJ_FLAG_TRAY | AOBJ_FLAG_TRAZ, 0): 0, 0
		0x06080020, 0xC5951000, # [5] aobjEvent32SetValBlock(AOBJ_FLAG_TRAX, 32): -4770
		0x1C000000, # [7] aobjEvent32SetAnim(0x000, 0)
		0x00000000, # [8] (u32)(dITCommonObject_KamexHydro_Weapon_animjoints_0xFB4C)
	], "dITCommonObject_KamexHydro_Weapon_animjoints_0xFB4C")
	anim_joint.ptr[8] = [anim_joint, 0] # SetAnim target: the start of this same script

	return anim_joint

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80180630
static func itKamexAttackUpdateHydro(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	if ip.item_vars.kamex.hydro_spawn_wait <= 0:
		var pos: Vector3 = dobj.translate

		if ip.kind == nITKindKamex:
			pos.x += ITKAMEX_KAMEX_HYDRO_SPAWN_OFF_X * ip.lr
			pos.y += ITKAMEX_KAMEX_HYDRO_SPAWN_OFF_Y

		else:
			pos.x += ITKAMEX_OTHER_HYDRO_SPAWN_OFF_X * ip.lr

		itKamexAttackMakeHydro(item_gobj, pos)
		Efmanager.efManagerDamageSpawnSparksMakeEffect(pos, ip.lr)
		Snd.func_800269C0_275C0(nSYAudioFGMKamexHydro)

		ip.item_vars.kamex.hydro_spawn_wait = syUtilsRandIntRange(ITKAMEX_HYDRO_SPAWN_WAIT_RANDOM) + ITKAMEX_HYDRO_SPAWN_WAIT_CONST

		pos = dobj.translate

		pos.y += ip.attr.map_coll_bottom

		if ip.kind == nITKindKamex:
			pos.x += (ip.attr.map_coll_width + ITKAMEX_DUST_SPAWN_OFF_X) * -ip.lr

		ip.item_vars.kamex.is_apply_push = TRUE

		ip.physics.vel_air.x = -ip.lr * ITKAMEX_CONSTVEL_X

		Efmanager.efManagerDustHeavyMakeEffect(pos, -ip.lr)

## 0x801807DC
static func itKamexFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITKAMEX_GRAVITY, ITKAMEX_TVEL)

	return FALSE

## 0x80180808
static func itKamexFallProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmap.itMapTestAllCollisionFlag(item_gobj, (MAP_FLAG_CEIL | MAP_FLAG_RWALL | MAP_FLAG_LWALL))

	if ip.coll_data.mask_curr & MAP_FLAG_FLOOR:
		itKamexAttackInitVars(item_gobj, TRUE)
		itKamexAttackSetStatus(item_gobj)

	return FALSE

## 0x80180860
static func itKamexFallInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	Itmap.itMapSetAir(ip)

	ip.physics.vel_air.y = 0.0
	ip.physics.vel_air.x = ip.physics.vel_air.y

	ip.is_allow_pickup = FALSE

	ip.item_vars.kamex.hydro_push_vel_x = 0.0

## 0x801808A4
static func itKamexFallSetStatus(item_gobj) -> void:
	itKamexFallInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITKamexStatusDescs, nITKamexStatusFall)

## 0x801808D8
static func itKamexAppearProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITKAMEX_GRAVITY, ITKAMEX_TVEL)

	return FALSE

## 0x80180904
static func itKamexAppearProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmap.itMapTestAllCollisionFlag(item_gobj, (MAP_FLAG_CEIL | MAP_FLAG_RWALL | MAP_FLAG_LWALL))

	if ip.coll_data.mask_curr & MAP_FLAG_FLOOR:
		ip.physics.vel_air.y = 0.0

		itKamexAttackInitVars(item_gobj, FALSE)
		itKamexAttackSetStatus(item_gobj)

	return FALSE

## 0x80180964
static func itKamexAppearSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.multi = ITKAMEX_LIFETIME

	if ip.kind == nITKindKamex:
		Snd.func_800269C0_275C0(nSYAudioVoiceMBallKamexAppear)

	Itmain.itMainSetStatus(item_gobj, dITKamexStatusDescs, nITKamexStatusAppear)

## 0x801809BC
static func itKamexAttackProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		return TRUE

	itKamexAttackUpdateHydro(item_gobj)

	if ip.item_vars.kamex.is_apply_push != FALSE:
		ip.physics.vel_air.x += ip.item_vars.kamex.hydro_push_vel_x

	ip.item_vars.kamex.hydro_spawn_wait -= 1

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x80180A30
static func itKamexAttackProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itkamex, &"itKamexFallSetStatus"))

	return FALSE

## 0x80180A58
static func itKamexAttackInitVars(item_gobj, is_ignore_setup: int) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	if is_ignore_setup == FALSE:
		ip.multi = ITKAMEX_LIFETIME

		if ip.kind == nITKindKamex:
			# itGetPData(ip, &llITCommonDataKamexDataStart, &llITCommonDataKamexDisplayList) == ITCommonObject + 0xED60
			var dl = "dITCommonObject_Kamex_Item_data_remainder_gap_0xEAE4_sub_0x27C"

			dobj.dl = dl

			ip.coll_data.map_coll.top = ITKAMEX_COLL_SIZE
			ip.coll_data.map_coll.center = 0.0
			ip.coll_data.map_coll.bottom = -ITKAMEX_COLL_SIZE
			ip.coll_data.map_coll.width = ITKAMEX_COLL_SIZE

	ip.physics.vel_air.y = 0
	ip.physics.vel_air.x = ip.physics.vel_air.y

	ip.item_vars.kamex.hydro_push_vel_x = ip.lr * ITKAMEX_PUSH_VEL_X
	ip.item_vars.kamex.hydro_spawn_wait = 0
	ip.item_vars.kamex.is_apply_push = FALSE

## 0x80180AF4
static func itKamexAttackSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITKamexStatusDescs, nITKamexStatusAttack)

## 0x80180B1C
static func itKamexCommonProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		ip.physics.vel_air.y = 0.0

		itKamexAppearSetStatus(item_gobj)

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x80180B6C
static func itKamexCommonProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if B(Itmap.itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_FLOOR)):
		ip.physics.vel_air.y = 0.0

	return FALSE

## 0x80180BAC - Turn Blastoise towards the side with the most enemy players
## Port note: like C, victim_gobj is only set when an enemy fighter exists (C reads an
## uninitialised local otherwise; this port would fail on the null victim).
static func itKamexCommonFindTargetsSetLR(item_gobj) -> void:
	var victim_gobj = null
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)
	var dist_xy: float = 0.0
	var dist_x: float
	var dist: Vector3
	var square_xy: float
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

	dist_x = DObjGetStruct(victim_gobj).translate.x - dobj.translate.x

	ip.lr = -1 if (dist_x < 0.0) else +1

## 0x80180CDC
static func itKamexMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITKamexItemDesc, pos, vel, flags)
	var dobj: DObj
	var kamex_ip: Item
	var mball_ip: Item

	if item_gobj != null:
		dobj = DObjGetStruct(item_gobj)

		Objman.gcAddXObjForDObjFixed(dobj, 0x48, 0)

		dobj.translate = pos

		kamex_ip = itGetStruct(item_gobj)

		kamex_ip.multi = ITMONSTER_RISE_STOP_WAIT

		kamex_ip.physics.vel_air.z = 0.0
		kamex_ip.physics.vel_air.x = kamex_ip.physics.vel_air.z
		kamex_ip.physics.vel_air.y = ITMONSTER_RISE_VEL_Y

		mball_ip = itGetStruct(parent_gobj)

		kamex_ip.owner_gobj = mball_ip.owner_gobj
		# REGION_US
		kamex_ip.team = mball_ip.team

		itKamexCommonFindTargetsSetLR(item_gobj)

		if kamex_ip.lr == -1:
			dobj.rotate.y = F_CST_DTOR32(180.0)

		dobj.translate.y -= kamex_ip.attr.map_coll_bottom

		# itGetMonsterAnimNode(kamex_ip, &llITCommonDataKamexDataStart) == ITCommonObject + 0x13624
		ObjAnim.gcAddDObjAnimJoint(dobj, Itpippi.dITCommonObjectMonsterAnimBank, 0.0)

	return item_gobj

## 0x80180E10
static func itKamexWeaponHydroProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var dobj := DObjGetStruct(weapon_gobj)

	wp.attack_coll.offsets[0].x = dobj.child.translate.x * wp.lr

	if B(Wpmain.wpMainDecLifeCheckExpire(wp)):
		return TRUE

	else:
		return FALSE

## 0x80180E60
static func itKamexWeaponHydroProcHit(_weapon_gobj) -> int:
	return FALSE

## 0x80180E6C
static func itKamexWeaponHydroProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)

	Wpmain.wpMainReflectorSetLR(wp, fp)

	DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x)
	DObjGetStruct(weapon_gobj).scale.x = 1.0

	wp.lr = -wp.lr

	return FALSE

## 0x80180EDC
static func itKamexWeaponHydroMakeWeapon(item_gobj, pos: Vector3):
	var ip := itGetStruct(item_gobj)
	var weapon_gobj = Wpmanager.wpManagerMakeWeapon(item_gobj, _itKamexGetWeaponHydroWeaponDesc(), pos, WEAPON_FLAG_PARENT_ITEM)
	var dobj: DObj
	var wp: Weapon
	var translate: Vector3

	if weapon_gobj == null:
		return null

	wp = wpGetStruct(weapon_gobj)

	wp.lr = ip.lr

	dobj = DObjGetStruct(weapon_gobj)

	translate = dobj.translate

	Efmanager.efManagerSparkleWhiteScaleMakeEffect(translate, 1.0)

	if wp.lr == -1:
		dobj.rotate.y = F_CST_DTOR32(180.0)

	wp.weapon_vars.hydro.unk_0x0 = 0 # Set but never used?
	wp.weapon_vars.hydro.unk_0x4 = 0 # Set but never used?

	wp.lifetime = ITKAMEX_HYDRO_LIFETIME

	return weapon_gobj

## 0x80180F9C
static func itKamexAttackMakeHydro(item_gobj, pos: Vector3) -> void:
	itKamexWeaponHydroMakeWeapon(item_gobj, pos)

# ---------------------------------------------------------------------------------------
# Port helper
# ---------------------------------------------------------------------------------------

## dITKamexWeaponHydroWeaponDesc with lbRelocGetFileData(WPAttributes*, gITManagerCommonData,
## &llITCommonDataKamexHydroWeaponAttributes) resolved (item core table) and its anim_joints table
## dITCommonObject_KamexHydro_Weapon_animjoints = {NULL, 0xFA9C, 0xFB4C} attached.
static func _itKamexGetWeaponHydroWeaponDesc() -> Dictionary:
	if dITKamexWeaponHydroWeaponDesc.attributes == null:
		var attr: Dictionary = Itmanager.itManagerGetCommonData("llITCommonDataKamexHydroWeaponAttributes").duplicate()

		attr["anim_joints"] = [null, dITCommonObjectKamexHydroAnimJoint1, dITCommonObjectKamexHydroAnimJoint2]

		dITKamexWeaponHydroWeaponDesc.attributes = attr

	return dITKamexWeaponHydroWeaponDesc
