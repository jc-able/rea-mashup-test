## 1:1 port of src/it/itmonster/itnyars.c (ssb-decomp-re): Poké Ball Meowth and its Pay Day coin
## weapon (nWPKindNyarsCoin; the weapon code lives in this C file, not in src/wp).
##
## Make function (dITManagerProcMakeList entry, called through itManagerMakeItemKind):
##   Itnyars.itNyarsMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int) -> item_gobj or null
## Shared conventions of the itmonster ports (descs, DObjDesc data, AnimJoints, u16 wrap): see Itpippi.gd.
class_name Itnyars
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itNyarsStatus
const nITNyarsStatusAttack = 0
const nITNyarsStatusEnumCount = 1

# llITCommonData* linker offsets used by this file (tools/relocFileDescriptions.us.txt)
const llITCommonDataNyarsAnimJoint = 0xC130   # == offset of Meowth's DObjDesc (its attr->data)

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8018ACA0
static var dITNyarsItemDesc := {
	"kind": nITKindNyars,                                       # Item Kind
	"o_attributes": "llITCommonDataNyarsItemAttributes",        # &gITManagerCommonData, &llITCommonDataNyarsItemAttributes (item core table)

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindTraRotRpyRSca,                      # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"attack_state": nGMAttackStateNew,                          # Hitbox Update State
	"proc_update": Callable(Itnyars, &"itNyarsCommonProcUpdate"),   # Proc Update
	"proc_map": Callable(Itnyars, &"itNyarsCommonProcMap"),         # Proc Map
	"proc_hit": Callable(),                                     # Proc Hit
	"proc_shield": Callable(),                                  # Proc Shield
	"proc_hop": Callable(),                                     # Proc Hop
	"proc_setoff": Callable(),                                  # Proc Set-Off
	"proc_reflector": Callable(),                               # Proc Reflector
	"proc_damage": Callable(),                                  # Proc Damage

	"visual_kind": "monster_nyars",
}

## 0x8018ACD4
static var dITNyarsStatusDescs: Array = [
	# Status 0 (Neutral Attack)
	{
		"proc_update": Callable(Itnyars, &"itNyarsAttackProcUpdate"),   # Proc Update
		"proc_map": Callable(),                                 # Proc Map
		"proc_hit": Callable(),                                 # Proc Hit
		"proc_shield": Callable(),                              # Proc Shield
		"proc_hop": Callable(),                                 # Proc Hop
		"proc_setoff": Callable(),                              # Proc Set-Off
		"proc_reflector": Callable(),                           # Proc Reflector
		"proc_damage": Callable(),                              # Proc Damage
	},
]

## 0x8018ACF4
static var dITNyarsWeaponCoinWeaponDesc := {
	"flags": 0x01,                                              # Render flags? (WEAPON_FLAG_DOBJDESC)
	"kind": nWPKindNyarsCoin,                                   # Weapon Kind
	# p_weapon = &gITManagerCommonData, o_attributes = &llITCommonDataNyarsCoinWeaponAttributes:
	# resolved on first use by _itNyarsGetWeaponCoinWeaponDesc() (item core table)
	"attributes": null,

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindNull,                               # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"proc_update": Callable(Itnyars, &"itNyarsWeaponCoinProcUpdate"),       # Proc Update
	"proc_map": Callable(),                                                 # Proc Map
	"proc_hit": Callable(Itnyars, &"itNyarsWeaponCoinProcHit"),             # Proc Hit
	"proc_shield": Callable(Itnyars, &"itNyarsWeaponCoinProcHit"),          # Proc Shield
	"proc_hop": Callable(Itnyars, &"itNyarsWeaponCoinProcHop"),             # Proc Hop
	"proc_setoff": Callable(Itnyars, &"itNyarsWeaponCoinProcHit"),          # Proc Set-Off
	"proc_reflector": Callable(Itnyars, &"itNyarsWeaponCoinProcReflector"), # Proc Reflector
	"proc_absorb": Callable(Itnyars, &"itNyarsWeaponCoinProcHit"),          # Proc Absorb

	"visual_kind": "nyars_coin",
}

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8017EEB0
static func itNyarsAttackProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	if ip.multi == 0:
		return TRUE

	if ip.multi == ip.item_vars.nyars.coin_spawn_wait:
		itNyarsAttackMakeCoin(item_gobj, ip.item_vars.nyars.coin_rotate_step * ITNYARS_COIN_ANGLE_STEP)

		ip.item_vars.nyars.coin_rotate_step = (ip.item_vars.nyars.coin_rotate_step + 1) & 0xFFFF # u16
		ip.item_vars.nyars.coin_spawn_wait = (ip.multi - ITNYARS_COIN_SPAWN_WAIT) & 0xFFFF       # u16

		Snd.func_800269C0_275C0(nSYAudioFGMNyarsCoin)

	if ip.item_vars.nyars.model_rotate_wait == 0:
		dobj.rotate.y += F_CST_DTOR32(180.0)

		ip.item_vars.nyars.model_rotate_wait = ITNYARS_MODEL_ROTATE_WAIT

	ip.item_vars.nyars.model_rotate_wait = (ip.item_vars.nyars.model_rotate_wait - 1) & 0xFFFF # u16

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x8017EFA0
static func itNyarsAttackInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.multi = ITNYARS_LIFETIME

	@warning_ignore("integer_division")
	ip.item_vars.nyars.coin_spawn_wait = (ip.multi - (ITNYARS_COIN_SPAWN_WAIT / 2)) & 0xFFFF # u16
	ip.item_vars.nyars.coin_rotate_step = 0
	ip.item_vars.nyars.model_rotate_wait = ITNYARS_MODEL_ROTATE_WAIT

## 0x8017EFC4
static func itNyarsAttackSetStatus(item_gobj) -> void:
	itNyarsAttackInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITNyarsStatusDescs, nITNyarsStatusAttack)

## 0x8017EFF8
static func itNyarsCommonProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		ip.physics.vel_air.y = 0.0
		ip.physics.vel_air.x = ip.physics.vel_air.y

		itNyarsAttackSetStatus(item_gobj)

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x8017F04C
static func itNyarsCommonProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if B(Itmap.itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_FLOOR)):
		ip.physics.vel_air.y = 0.0

	return FALSE

## 0x8017F08C
static func itNyarsMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITNyarsItemDesc, pos, vel, flags)
	var dobj: DObj
	var ip: Item

	if item_gobj != null:
		dobj = DObjGetStruct(item_gobj)

		Objman.gcAddXObjForDObjFixed(dobj, 0x48, 0)

		dobj.translate = pos

		ip = itGetStruct(item_gobj)

		ip.multi = ITMONSTER_RISE_STOP_WAIT

		ip.physics.vel_air.z = 0.0
		ip.physics.vel_air.x = ip.physics.vel_air.z
		ip.physics.vel_air.y = ITMONSTER_RISE_VEL_Y

		dobj.translate.y -= ip.attr.map_coll_bottom

		# itGetMonsterAnimNode(ip, &llITCommonDataNyarsAnimJoint) == ITCommonObject + 0x13624
		ObjAnim.gcAddDObjAnimJoint(dobj, Itpippi.dITCommonObjectMonsterAnimBank, 0.0)

	return item_gobj

## 0x8017F17C
static func itNyarsWeaponCoinProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if wp.weapon_vars.coin.lifetime == 0:
		return TRUE

	wp.weapon_vars.coin.lifetime -= 1

	return FALSE

## 0x8017F1A4
static func itNyarsWeaponCoinProcHit(weapon_gobj) -> int:
	Efmanager.efManagerDamageCoinMakeEffect(DObjGetStruct(weapon_gobj).translate)

	return TRUE

## 0x8017F1CC
static func itNyarsWeaponCoinProcHop(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	wp.physics.vel_air = syVectorRotateAbout3D(wp.physics.vel_air, wp.shield_collide_dir, wp.shield_collide_angle * 2)

	DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x)
	DObjGetStruct(weapon_gobj).scale.x = 1.0

	if wp.physics.vel_air.x > 0.0:
		wp.lr = +1

	else:
		wp.lr = -1

	return FALSE

## 0x8017F274
static func itNyarsWeaponCoinProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)

	Wpmain.wpMainReflectorSetLR(wp, fp)

	DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x)
	DObjGetStruct(weapon_gobj).scale.x = 1.0

	wp.lr = -wp.lr

	return FALSE

## 0x8017F2E4
static func itNyarsWeaponCoinMakeWeapon(item_gobj, coin_number: int, rotate_angle: float):
	var wp: Weapon
	var weapon_gobj = Wpmanager.wpManagerMakeWeapon(item_gobj, _itNyarsGetWeaponCoinWeaponDesc(), DObjGetStruct(item_gobj).translate, WEAPON_FLAG_PARENT_ITEM)
	var dobj: DObj

	coin_number = coin_number & 0xFF # u8

	if weapon_gobj == null:
		return null

	wp = wpGetStruct(weapon_gobj)

	wp.weapon_vars.coin.lifetime = ITNYARS_COIN_LIFETIME

	wp.physics.vel_air.z = 0.0
	wp.physics.vel_air.y = wp.physics.vel_air.z
	wp.physics.vel_air.x = ITNYARS_COIN_VEL_X

	wp.physics.vel_air = syVectorRotate3D(wp.physics.vel_air, SYVECTOR_AXIS_Z, F_CLC_DTOR32((coin_number * ITNYARS_COIN_ANGLE_DIFF) + rotate_angle))

	dobj = DObjGetStruct(weapon_gobj)

	Objman.gcAddXObjForDObjFixed(dobj, nGCMatrixKindTraRotRpyRSca, 0)
	Objman.gcAddXObjForDObjFixed(dobj, 0x46, 0)

	dobj.translate = DObjGetStruct(item_gobj).translate

	return weapon_gobj

## 0x8017F408
static func itNyarsAttackMakeCoin(item_gobj, angle: float) -> void:
	var coin_count: int = 0

	while coin_count < ITNYARS_COIN_SPAWN_MAX:
		itNyarsWeaponCoinMakeWeapon(item_gobj, coin_count, angle)

		coin_count += 1

# ---------------------------------------------------------------------------------------
# Port helper
# ---------------------------------------------------------------------------------------

## dITNyarsWeaponCoinWeaponDesc with lbRelocGetFileData(WPAttributes*, gITManagerCommonData,
## &llITCommonDataNyarsCoinWeaponAttributes) resolved (item core table).
static func _itNyarsGetWeaponCoinWeaponDesc() -> Dictionary:
	if dITNyarsWeaponCoinWeaponDesc.attributes == null:
		dITNyarsWeaponCoinWeaponDesc.attributes = Itmanager.itManagerGetCommonData("llITCommonDataNyarsCoinWeaponAttributes")

	return dITNyarsWeaponCoinWeaponDesc
