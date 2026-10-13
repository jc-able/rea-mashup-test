## 1:1 port of src/it/itmonster/itiwark.c (ssb-decomp-re): Poké Ball Onix and its Rock Slide weapon
## (nWPKindIwarkRock; the weapon code lives in this C file, not in src/wp).
##
## Make function (dITManagerProcMakeList entry, called through itManagerMakeItemKind):
##   Itiwark.itIwarkMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int) -> item_gobj or null
## Shared conventions of the itmonster ports (descs, DObjDesc data, AnimJoints, u16 wrap): see Itpippi.gd.
## ITAttributes: llITCommonDataWarkItemAttributes (251_ITCommonData.c @ 0x072C); WPAttributes:
## llITCommonDataWarkRockWeaponAttributes (@ 0x0774), from the item core's ROM-verified tables.
class_name Itiwark
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itIwarkStatus
const nITIwarkStatusFly = 0
const nITIwarkStatusAttack = 1
const nITIwarkStatusEnumCount = 2

# llITCommonData* linker offsets used by this file (tools/relocFileDescriptions.us.txt)
const llITCommonDataWarkDataStart = 0xA140
const llITCommonDataWarkDisplayList = 0xA640

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8018AA90
static var dITIwarkItemDesc := {
	"kind": nITKindIwark,                                       # Item Kind
	"o_attributes": "llITCommonDataWarkItemAttributes",         # &gITManagerCommonData, &llITCommonDataWarkItemAttributes

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindNull,                               # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"attack_state": nGMAttackStateNew,                          # Hitbox Update State
	"proc_update": Callable(Itiwark, &"itIwarkCommonProcUpdate"),   # Proc Update
	"proc_map": Callable(Itiwark, &"itIwarkCommonProcMap"),         # Proc Map
	"proc_hit": Callable(),                                     # Proc Hit
	"proc_shield": Callable(),                                  # Proc Shield
	"proc_hop": Callable(),                                     # Proc Hop
	"proc_setoff": Callable(),                                  # Proc Set-Off
	"proc_reflector": Callable(),                               # Proc Reflector
	"proc_damage": Callable(),                                  # Proc Damage
}

## 0x8018AAC4
static var dITIwarkStatusDescs: Array = [
	# Status 0 (Neutral Fly)
	{
		"proc_update": Callable(Itiwark, &"itIwarkFlyProcUpdate"),
		"proc_map": Callable(), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},

	# Status 1 (Neutral Attack)
	{
		"proc_update": Callable(Itiwark, &"itIwarkAttackProcUpdate"),
		"proc_map": Callable(), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},
]

## 0x8018AB04
## "attributes" (&gITManagerCommonData + llITCommonDataWarkRockWeaponAttributes) is resolved on
## first use by _itIwarkGetWeaponRockWeaponDesc().
static var dITIwarkWeaponRockWeaponDesc := {
	"flags": 0x01,                                              # Render flags? (WEAPON_FLAG_DOBJDESC)
	"kind": nWPKindIwarkRock,                                   # Weapon Kind
	"attributes": null,

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindNull,                               # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"proc_update": Callable(Itiwark, &"itIwarkWeaponRockProcUpdate"),       # Proc Update
	"proc_map": Callable(Itiwark, &"itIwarkWeaponRockProcMap"),             # Proc Map
	"proc_hit": Callable(),                                                 # Proc Hit
	"proc_shield": Callable(),                                              # Proc Shield
	"proc_hop": Callable(Itiwark, &"itIwarkWeaponRockProcHop"),             # Proc Hop
	"proc_setoff": Callable(),                                              # Proc Set-Off
	"proc_reflector": Callable(Itiwark, &"itIwarkWeaponRockProcReflector"), # Proc Reflector
	"proc_absorb": Callable(),                                              # Proc Absorb

	"visual_kind": "iwark_rock",
}

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8017D740
static func itIwarkAttackUpdateRock(iwark_gobj) -> void:
	var ip := itGetStruct(iwark_gobj)
	var dobj := DObjGetStruct(iwark_gobj)

	if ip.item_vars.iwark.rock_spawn_wait <= 0:
		var wp: Weapon
		var rock_gobj
		var pos: Vector3 = dobj.translate

		pos.x += (ITIWARK_ROCK_SPAWN_OFF_X_MUL * syUtilsRandFloat()) + ITIWARK_ROCK_SPAWN_OFF_X_ADD

		rock_gobj = itIwarkWeaponRockMakeWeapon(iwark_gobj, pos, syUtilsRandIntRange(WPIWARK_ROCK_RANDOM_VEL_MAX))

		if rock_gobj != null:
			wp = wpGetStruct(rock_gobj)

			# #if !defined (DAIRANTOU_OPT0)
			wp.weapon_vars.rock.unk_0xC = ip.item_vars.iwark.rock_spawn_max - ip.item_vars.iwark.rock_spawn_remain

			ip.item_vars.iwark.rock_spawn_remain = (ip.item_vars.iwark.rock_spawn_remain - 1) & 0xFFFF # u16

			# #if !defined (DAIRANTOU_OPT0)
			if ip.item_vars.iwark.rock_spawn_remain == 0:
				wp.weapon_vars.rock.unk_0xC = -1

			ip.item_vars.iwark.rock_spawn_wait = syUtilsRandIntRange(ITIWARK_ROCK_SPAWN_WAIT_MAX) + ITIWARK_ROCK_SPAWN_WAIT_MIN

## 0x8017D820
static func itIwarkAttackProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)
	# REGION_US
	var pos_y: float = Mpcollision.gMPCollisionGroundData.map_bound_top - ITIWARK_FLY_STOP_Y

	if dobj.translate.y >= pos_y:
		dobj.translate.y = pos_y

		ip.physics.vel_air.y = 0.0

		if ip.item_vars.iwark.rock_spawn_remain != 0:
			itIwarkAttackUpdateRock(item_gobj)

		elif ip.item_vars.iwark.rock_spawn_count == ip.item_vars.iwark.rock_spawn_max:
			return TRUE

		if (ip.item_vars.iwark.rumble_wait == 0) and (ip.item_vars.iwark.rumble_frame != 0):
			Efmanager.efManagerQuakeMakeEffect(0)

			ip.item_vars.iwark.rumble_wait = ITIWARK_ROCK_RUMBLE_WAIT

		if ip.item_vars.iwark.rumble_frame != 0:
			ip.item_vars.iwark.rumble_wait = (ip.item_vars.iwark.rumble_wait - 1) & 0xFFFF # u16

		ip.item_vars.iwark.rock_spawn_wait -= 1

	if ip.multi == ITIWARK_MODEL_ROTATE_WAIT:
		dobj.rotate.y += F_CST_DTOR32(180.0)

		ip.multi = 0

	ip.multi = (ip.multi + 1) & 0xFFFF # u16

	return FALSE

## 0x8017D948
static func itIwarkAttackInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)
	var dl
	var pos: Vector3

	# REGION_US
	ip.ga = nMPKineticsAir

	ip.physics.vel_air.y = ITIWARK_FLY_VEL_Y

	ip.item_vars.iwark.rock_spawn_remain = (syUtilsRandIntRange(ITIWARK_ROCK_SPAWN_COUNT_RANDOM) + ITIWARK_ROCK_SPAWN_COUNT_MIN) & 0xFFFF # u16
	ip.item_vars.iwark.rock_spawn_max = ip.item_vars.iwark.rock_spawn_remain
	ip.item_vars.iwark.rock_spawn_count = 0
	ip.item_vars.iwark.rock_spawn_wait = 0
	ip.item_vars.iwark.rumble_frame = 0
	ip.item_vars.iwark.rumble_wait = 0

	ip.multi = 0

	pos = dobj.translate

	if ip.kind == nITKindIwark:
		# itGetPData(ip, &llITCommonDataWarkDataStart, &llITCommonDataWarkDisplayList) == ITCommonObject + 0xA640
		dl = "dITCommonObject_Wark_Item_data_remainder_gap_0xA1C4_sub_0x47C"
		dobj.dl = dl

		pos.y += ITIWARK_IWARK_ADD_POS_Y

	else:
		pos.y += ITIWARK_OTHER_ADD_POS_Y

	Efmanager.efManagerDustHeavyDoubleMakeEffect(pos, -1, 1.0)

	if ip.kind == nITKindIwark:
		Snd.func_800269C0_275C0(nSYAudioVoiceMBallIwarkAppear)

## 0x8017DA60
static func itIwarkAttackSetStatus(item_gobj) -> void:
	itIwarkAttackInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITIwarkStatusDescs, nITIwarkStatusAttack)

## 0x8017DA94
static func itIwarkFlyProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		itIwarkAttackSetStatus(item_gobj)

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x8017DAD8
static func itIwarkFlySetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.multi = ITIWARK_FLY_WAIT

	ip.physics.vel_air.y = 0.0
	ip.physics.vel_air.x = ip.physics.vel_air.y

	Itmain.itMainSetStatus(item_gobj, dITIwarkStatusDescs, nITIwarkStatusFly)

## 0x8017DB18
static func itIwarkCommonProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		itIwarkFlySetStatus(item_gobj)

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x8017DB5C
static func itIwarkCommonProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if B(Itmap.itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_FLOOR)):
		ip.physics.vel_air.y = 0.0

		Itmap.itMapSetGround(ip)

	return FALSE

## 0x8017DBA0
static func itIwarkMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITIwarkItemDesc, pos, vel, flags)
	var dobj: DObj
	var ip: Item

	if item_gobj != null:
		Itmain.itMainClearOwnerStats(item_gobj)

		dobj = DObjGetStruct(item_gobj)

		Objman.gcAddXObjForDObjFixed(dobj, nGCMatrixKindTraRotRpyR, 0)
		Objman.gcAddXObjForDObjFixed(dobj, 0x48, 0)

		dobj.translate = pos

		ip = itGetStruct(item_gobj)

		ip.multi = ITMONSTER_RISE_STOP_WAIT

		ip.attack_coll.interact_mask = GMHITCOLLISION_FLAG_FIGHTER

		ip.physics.vel_air.z = 0.0
		ip.physics.vel_air.x = ip.physics.vel_air.z
		ip.physics.vel_air.y = ITMONSTER_RISE_VEL_Y

		dobj.translate.y -= ip.attr.map_coll_bottom

		# itGetMonsterAnimNode(ip, &llITCommonDataWarkDataStart) == ITCommonObject + 0x13624
		ObjAnim.gcAddDObjAnimJoint(dobj, Itpippi.dITCommonObjectMonsterAnimBank, 0.0)

	return item_gobj

## 0x8017DCAC
## Port note: if Onix was already destroyed, C increments a freed (possibly reused) ITStruct;
## here the stale Item object is incremented instead (no other item is affected).
static func itIwarkWeaponRockProcDead(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var ip := itGetStruct(wp.weapon_vars.rock.owner_gobj)

	ip.item_vars.iwark.rock_spawn_count = (ip.item_vars.iwark.rock_spawn_count + 1) & 0xFFFF # u16

	return TRUE

## 0x8017DCCC
static func itIwarkWeaponRockProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var dobj: DObj

	Wpmain.wpMainApplyGravityClampTVel(wp, WPIWARK_ROCK_GRAVITY, WPIWARK_ROCK_TVEL)

	dobj = DObjGetStruct(weapon_gobj)

	dobj.rotate.z += WPIWARK_ROCK_ROTATE_STEP

	return FALSE

## 0x8017DD18
static func itIwarkWeaponRockProcMap(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var ip := itGetStruct(wp.weapon_vars.rock.owner_gobj)
	var coll_data: MPCollData = wp.coll_data
	var pos: Vector3 = DObjGetStruct(weapon_gobj).translate
	var line_id: int = wp.weapon_vars.rock.floor_line_id

	Wpmap.wpMapTestAllCheckCollEnd(weapon_gobj)

	if coll_data.mask_curr & MAP_FLAG_FLOOR:
		if line_id != coll_data.floor_line_id:
			wp.physics.vel_air = Lbcommon.lbCommonReflect2D(wp.physics.vel_air, coll_data.floor_angle)
			wp.physics.vel_air = Lbcommon.lbCommonScale2D(wp.physics.vel_air, WPIWARK_ROCK_COLLIDE_MUL_VEL_Y)

			wp.weapon_vars.rock.floor_line_id = coll_data.floor_line_id

			Snd.func_800269C0_275C0(nSYAudioFGMIwarkRockMake)

			pos.y += WPIWARK_ROCK_COLLIDE_ADD_VEL_Y

			Efmanager.efManagerDustLightMakeEffect(pos, wp.lr, 1.0)

			wp.lr = -wp.lr

			ip.item_vars.iwark.rumble_frame = (ip.item_vars.iwark.rumble_frame + 1) & 0xFFFF # u16

	return FALSE

## 0x8017DE10
static func itIwarkWeaponRockProcHop(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	wp.physics.vel_air = syVectorRotateAbout3D(wp.physics.vel_air, wp.shield_collide_dir, wp.shield_collide_angle * 2)

	DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x)
	DObjGetStruct(weapon_gobj).scale.x = 1.0

	if wp.physics.vel_air.x > 0.0:
		wp.lr = +1

	else:
		wp.lr = -1

	return FALSE

## 0x8017DEB8
static func itIwarkWeaponRockProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)

	Wpmain.wpMainReflectorSetLR(wp, fp)

	DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x)
	DObjGetStruct(weapon_gobj).scale.x = 1.0

	wp.lr = -wp.lr

	return FALSE

## 0x8017DF28
static func itIwarkWeaponRockMakeWeapon(parent_gobj, pos: Vector3, random: int):
	var random32: int
	var weapon_gobj = Wpmanager.wpManagerMakeWeapon(parent_gobj, _itIwarkGetWeaponRockWeaponDesc(), pos, WEAPON_FLAG_PARENT_ITEM)
	var dobj: DObj
	var vel_y: float
	var wp: Weapon
	var mobj

	random = random & 0xFF # u8

	if weapon_gobj == null:
		return null

	wp = wpGetStruct(weapon_gobj)

	wp.weapon_vars.rock.floor_line_id = -1

	random32 = random

	if random32 == 0:
		wp.physics.vel_air.y = WPIWARK_ROCK_VEL_Y_START_A

	else:
		vel_y = WPIWARK_ROCK_VEL_Y_START_B if (random32 == 1) else WPIWARK_ROCK_VEL_Y_START_C
		wp.physics.vel_air.y = vel_y

	if syUtilsRandIntRange(2) == 0:
		wp.lr = -1

	else:
		wp.lr = +1

	dobj = DObjGetStruct(weapon_gobj)

	Objman.gcAddXObjForDObjFixed(dobj, nGCMatrixKindTraRotRpyR, 0)
	Objman.gcAddXObjForDObjFixed(dobj, 0x46, 0)

	dobj.translate = pos

	# dobj->child->mobj->texture_id_curr = random; (rock texture variant: render only, see Itpippi.gd)
	mobj = _itIwarkGetMObj(dobj.child)

	if mobj != null:
		mobj.texture_id_curr = random

	wp.weapon_vars.rock.owner_gobj = parent_gobj

	wp.is_hitlag_victim = TRUE

	wp.proc_dead = Callable(Itiwark, &"itIwarkWeaponRockProcDead")

	return weapon_gobj

# ---------------------------------------------------------------------------------------
# Port helpers
# ---------------------------------------------------------------------------------------

## dITIwarkWeaponRockWeaponDesc with lbRelocGetFileData(WPAttributes*, gITManagerCommonData,
## &llITCommonDataWarkRockWeaponAttributes) resolved (item core table).
static func _itIwarkGetWeaponRockWeaponDesc() -> Dictionary:
	if dITIwarkWeaponRockWeaponDesc.attributes == null:
		dITIwarkWeaponRockWeaponDesc.attributes = Itmanager.itManagerGetCommonData("llITCommonDataWarkRockWeaponAttributes")

	return dITIwarkWeaponRockWeaponDesc

## dobj->mobj (first MObj of the joint); MObjs are render-only in this port (see Itpippi.gd).
static func _itIwarkGetMObj(dobj: DObj):
	if dobj == null:
		return null
	var mobjs: Array = dobj.get_meta(&"mobjs", [])

	return mobjs[0] if not mobjs.is_empty() else null
