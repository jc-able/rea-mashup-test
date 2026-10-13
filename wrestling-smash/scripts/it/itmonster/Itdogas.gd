## 1:1 port of src/it/itmonster/itdogas.c (ssb-decomp-re): Poké Ball Koffing and its Smog weapon
## (nWPKindDogasSmog; the weapon code lives in this C file, not in src/wp).
##
## Make function (dITManagerProcMakeList entry, called through itManagerMakeItemKind):
##   Itdogas.itDogasMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int) -> item_gobj or null
## Shared conventions of the itmonster ports (descs, DObjDesc data, AnimJoints, u16 wrap): see Itpippi.gd.
## ITAttributes: llITCommonDataDogasItemAttributes (251_ITCommonData.c @ 0x0BF8); WPAttributes:
## llITCommonDataDogasSmogWeaponAttributes (@ 0x0C40), both from the item core's ROM-verified
## ITCommonData tables (Itmanager.itManagerGetCommonData) - the Smog table gets its AnimJoint
## (gameplay: the cloud's hitbox size follows the animated joint scale) attached here.
class_name Itdogas
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itDogasStatus
const itDogasStatusAttack = 0
const itDogasStatusDisappear = 1
const itDogasStatusEnumCount = 2

# llITCommonData* linker offsets used by this file (tools/relocFileDescriptions.us.txt)
const llITCommonDataDogasDataStart = 0x12820
const llITCommonDataDogasAnimJoint = 0x128DC

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8018B2C0
static var dITDogasItemDesc := {
	"kind": nITKindDogas,                                       # Item Kind
	"o_attributes": "llITCommonDataDogasItemAttributes",        # &gITManagerCommonData, &llITCommonDataDogasItemAttributes

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindNull,                               # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"attack_state": nGMAttackStateOff,                          # Hitbox Update State
	"proc_update": Callable(Itdogas, &"itDogasCommonProcUpdate"),   # Proc Update
	"proc_map": Callable(Itdogas, &"itDogasCommonProcMap"),         # Proc Map
	"proc_hit": Callable(),                                     # Proc Hit
	"proc_shield": Callable(),                                  # Proc Shield
	"proc_hop": Callable(),                                     # Proc Hop
	"proc_setoff": Callable(),                                  # Proc Set-Off
	"proc_reflector": Callable(),                               # Proc Reflector
	"proc_damage": Callable(),                                  # Proc Damage
}

## 0x80182BF4
static var dITDogasStatusDescs: Array = [
	# Status 0 (Neutral Active)
	{
		"proc_update": Callable(Itdogas, &"itDogasAttackProcUpdate"),
		"proc_map": Callable(), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},

	# Status 1 (Neutral Disappear)
	{
		"proc_update": Callable(Itdogas, &"itDogasDisappearProcUpdate"),
		"proc_map": Callable(), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},
]

## 0x8018B334
## "attributes" (&gITManagerCommonData + llITCommonDataDogasSmogWeaponAttributes) is resolved on
## first use by _itDogasGetWeaponSmogWeaponDesc() (the item core table + the Smog AnimJoint).
static var dITDogasWeaponSmogWeaponDesc := {
	"flags": 0x03,                                              # Render flags? (WEAPON_FLAG_DOBJDESC | WEAPON_FLAG_DOBJLINKS)
	"kind": nWPKindDogasSmog,                                   # Weapon Kind
	"attributes": null,

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindTraRotRpyR,                         # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"proc_update": Callable(Itdogas, &"itDogasWeaponSmogProcUpdate"),   # Proc Update
	"proc_map": Callable(),                                     # Proc Map
	"proc_hit": Callable(),                                     # Proc Hit
	"proc_shield": Callable(),                                  # Proc Shield
	"proc_hop": Callable(),                                     # Proc Hop
	"proc_setoff": Callable(),                                  # Proc Set-Off
	"proc_reflector": Callable(),                               # Proc Reflector
	"proc_absorb": Callable(),                                  # Proc Absorb

	"visual_kind": "dogas_smog",
}

## AObjEvent32 script dITCommonObject_Dogas_Item_data_remainder_sub_0xC
## (86_ITCommonObject.c @ 0x128DC == llITCommonDataDogasAnimJoint): Koffing's hover loop on the model
## joint (render only). 31 words, identical to ROM file 86.
static var dITCommonObjectDogasAnimJoint: AnimStream = _itDogasMakeAnimJoint()

static func _itDogasMakeAnimJoint() -> AnimStream:
	var anim_joint := AnimStream.from_u32([
		0x12020000, 0x3DB2B8C2, # [0] aobjEvent32SetVal0Rate(AOBJ_FLAG_ROTZ, 0): 0.0872664601
		0x0C100000, 0x00000000, 0x40B3661E, # [2] aobjEvent32SetValRate(AOBJ_FLAG_TRAY, 0): 0, 5.60621548
		0x14280000, 0x00000000, 0x00000000, # [5] aobjEvent32SetValAfterBlock(AOBJ_FLAG_TRAX | AOBJ_FLAG_TRAZ, 0): 0, 0
		0x0C020010, 0x00000000, 0xBBFD4A3F, # [8] aobjEvent32SetValRate(AOBJ_FLAG_ROTZ, 16): 0, -0.00772979809
		0x10100010, 0x42700000, # [11] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_TRAY, 16): 60
		0x0C100010, 0x00000000, 0xC09E6030, # [13] aobjEvent32SetValRate(AOBJ_FLAG_TRAY, 16): 0, -4.94924164
		0x10020010, 0xBDB2B8C2, # [16] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_ROTZ, 16): -0.0872664601
		0x0C020010, 0x00000000, 0x3BE270EF, # [18] aobjEvent32SetValRate(AOBJ_FLAG_ROTZ, 16): 0, 0.00691043539
		0x10100010, 0xC2700000, # [21] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_TRAY, 16): -60
		0x0C100010, 0x00000000, 0x40AD81C2, # [23] aobjEvent32SetValRate(AOBJ_FLAG_TRAY, 16): 0, 5.42208958
		0x10020010, 0x3DB2B8C2, # [26] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_ROTZ, 16): 0.0872664601
		0x1C000000, # [28] aobjEvent32SetAnim(0x000, 0)
		0x00000000, # [29] (u32)dITCommonObject_Dogas_Item_data_remainder_sub_0xC
		0x00000000, # [30] aobjEvent32End()
	], "dITCommonObject_Dogas_Item_data_remainder_sub_0xC")
	anim_joint.ptr[29] = [anim_joint, 0] # SetAnim target: the start of this same script

	return anim_joint

## AObjEvent32 script dITCommonObject_DogasSmog_Weapon_animjoints_0x13198 (86_ITCommonObject.c
## @ 0x13198; WPAttributes.anim_joints = dITCommonObject_DogasSmog_Weapon_animjoints = {NULL, this}):
## Smog cloud joint scale (ScaX drives the hitbox size). 17 words, identical to ROM file 86.
static var dITCommonObjectDogasSmogAnimJoint: AnimStream = AnimStream.from_u32([
	0x12C00000, 0x3F800000, 0x3F800000, # [0] aobjEvent32SetVal0Rate(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 0): 1, 1
	0x15000000, 0x3F800000, # [3] aobjEvent32SetValAfterBlock(AOBJ_FLAG_SCAZ, 0): 1
	0x0AC00001, 0x3F800000, 0x3F38B996, 0x3F800000, 0x3F38A6F3, # [5] aobjEvent32SetValRateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 1): 1, 0.721581817, 1, 0.721297443
	0x10C0000F, 0x40B00000, 0x40B00000, # [10] aobjEvent32SetVal0RateBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 15): 5.5, 5.5
	0x06C00030, 0x40B00000, 0x40B00000, # [13] aobjEvent32SetValBlock(AOBJ_FLAG_SCAX | AOBJ_FLAG_SCAY, 48): 5.5, 5.5
	0x00000000, # [16] aobjEvent32End()
], "dITCommonObject_DogasSmog_Weapon_animjoints_0x13198")

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80182C80
static func itDogasDisappearProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		return TRUE

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x80182CA8
static func itDogasDisappearSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.multi = ITDOGAS_DESPAWN_WAIT

	Itmain.itMainSetStatus(item_gobj, dITDogasStatusDescs, itDogasStatusDisappear)

## 0x80182CDC
static func itDogasAttackUpdateSmog(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)
	var pos: Vector3
	var vel: Vector3

	if ip.item_vars.dogas.smog_spawn_wait <= 0:
		vel.x = ITDOGAS_SMOG_VEL
		vel.y = ITDOGAS_SMOG_VEL
		vel.z = 0.0

		pos = dobj.translate

		pos.x += (syUtilsRandFloat() * ITDOGAS_SMOG_MUL_OFF_X) - ITDOGAS_SMOG_SUB_OFF_X
		pos.y += (syUtilsRandFloat() * ITDOGAS_SMOG_MUL_OFF_Y) - ITDGOAS_SMOG_SUB_OFF_Y

		if pos.x < dobj.translate.x:
			vel.x = -vel.x

		if pos.y < dobj.translate.y:
			vel.y = -vel.y

		itDogasWeaponSmogMakeWeapon(item_gobj, pos, vel)
		Snd.func_800269C0_275C0(nSYAudioFGMDogasSmog)

		ip.item_vars.dogas.smog_spawn_wait = ITDOGAS_SMOG_SPAWN_WAIT

		ip.multi = (ip.multi - 1) & 0xFFFF # u16

## 0x80182E1C
static func itDogasAttackProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	itDogasAttackUpdateSmog(item_gobj)

	if ip.multi == 0:
		itDogasDisappearSetStatus(item_gobj)

		return FALSE

	ip.item_vars.dogas.smog_spawn_wait -= 1

	return FALSE

## 0x80182E78
static func itDogasAttackInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	ip.multi = ITDOGAS_SMOG_SPAWN_COUNT

	ip.item_vars.dogas.smog_spawn_wait = 0

	if ip.kind == nITKindDogas:
		ip.item_vars.dogas.pos = dobj.translate

		# itGetPData(ip, &llITCommonDataDogasDataStart, &llITCommonDataDogasAnimJoint) == ITCommonObject + 0x128DC
		ObjAnim.gcAddDObjAnimJoint(dobj.child, dITCommonObjectDogasAnimJoint, 0.0)

		ObjAnim.gcPlayAnimAll(item_gobj)
		Snd.func_800269C0_275C0(nSYAudioVoiceMBallDogasAppear)

## 0x80182F0C
static func itDogasAttackSetStatus(item_gobj) -> void:
	itDogasAttackInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITDogasStatusDescs, itDogasStatusAttack)

## 0x80182F40
static func itDogasCommonProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		ip.physics.vel_air.y = 0.0
		ip.physics.vel_air.x = ip.physics.vel_air.y

		itDogasAttackSetStatus(item_gobj)

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x80182F94
static func itDogasCommonProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if B(Itmap.itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_FLOOR)):
		ip.physics.vel_air.y = 0.0

	return FALSE

## 0x80182FD4
static func itDogasMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITDogasItemDesc, pos, vel, flags)
	var dobj: DObj
	var ip: Item

	if item_gobj != null:
		dobj = DObjGetStruct(item_gobj)

		Objman.gcAddXObjForDObjFixed(dobj, 0x28, 0)
		Objman.gcAddXObjForDObjFixed(dobj.child, nGCMatrixKindTraRotRpyRSca, 0)

		dobj.translate = pos

		ip = itGetStruct(item_gobj)

		dobj.translate.y -= ip.attr.map_coll_bottom

		ip.multi = ITMONSTER_RISE_STOP_WAIT

		ip.physics.vel_air.x = 0.0
		ip.physics.vel_air.z = 0.0
		ip.physics.vel_air.y = ITMONSTER_RISE_VEL_Y

		# itGetMonsterAnimNode(ip, &llITCommonDataDogasDataStart) == ITCommonObject + 0x13624
		ObjAnim.gcAddDObjAnimJoint(dobj.child, Itpippi.dITCommonObjectMonsterAnimBank, 0.0)

	return item_gobj

## 0x801830DC
static func itDogasWeaponSmogProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var dobj: DObj = DObjGetStruct(weapon_gobj).child

	wp.attack_coll.size = dobj.scale.x * wp.weapon_vars.smog.attr.size

	if B(Wpmain.wpMainDecLifeCheckExpire(wp)):
		return TRUE

	else:
		return FALSE

## 0x80183144
static func itDogasWeaponSmogMakeWeapon(item_gobj, pos: Vector3, vel: Vector3):
	var weapon_desc: Dictionary = _itDogasGetWeaponSmogWeaponDesc()
	var weapon_gobj = Wpmanager.wpManagerMakeWeapon(item_gobj, weapon_desc, pos, WEAPON_FLAG_PARENT_ITEM)
	var dobj: DObj
	var wp: Weapon

	if weapon_gobj == null:
		return null

	wp = wpGetStruct(weapon_gobj)

	wp.lifetime = ITDOGAS_SMOG_LIFETIME

	# (WPAttributes*)((uintptr_t)*weapon_desc->p_weapon + (intptr_t)weapon_desc->o_attributes)
	wp.weapon_vars.smog.attr = weapon_desc.attributes # Dude I had a stroke trying to match this

	dobj = DObjGetStruct(weapon_gobj)

	wp.physics.vel_air = vel

	Objman.gcAddXObjForDObjFixed(dobj.child, 0x2C, 0)

	dobj.translate = pos

	return weapon_gobj

# ---------------------------------------------------------------------------------------
# Port helper
# ---------------------------------------------------------------------------------------

## dITDogasWeaponSmogWeaponDesc with its attributes resolved: lbRelocGetFileData(WPAttributes*,
## gITManagerCommonData, &llITCommonDataDogasSmogWeaponAttributes) (item core table) whose
## anim_joints table dITCommonObject_DogasSmog_Weapon_animjoints = {NULL, 0x13198} is attached here.
static func _itDogasGetWeaponSmogWeaponDesc() -> Dictionary:
	if dITDogasWeaponSmogWeaponDesc.attributes == null:
		var attr: Dictionary = Itmanager.itManagerGetCommonData("llITCommonDataDogasSmogWeaponAttributes").duplicate()

		attr["anim_joints"] = [null, dITCommonObjectDogasSmogAnimJoint]

		dITDogasWeaponSmogWeaponDesc.attributes = attr

	return dITDogasWeaponSmogWeaponDesc
