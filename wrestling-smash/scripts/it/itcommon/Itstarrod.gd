## 1:1 port of src/it/itcommon/itstarrod.c (ssb-decomp-re): Star Rod item and its Star projectile (weapon).
##
## Data conventions: see Itbox (ITDesc / ITStatusDesc Dictionaries with the C field names; the ITAttributes
## and DObjDesc tree come from the ITCommonData tables in Itmanager.gd). The WPDesc is a Wpmanager
## Dictionary whose "attributes" are Itmanager's dITCommonData_StarRod(Smash)_WeaponAttributes
## (src/relocData/251_ITCommonData.c).
##
## C quirk kept: itStarRodWeaponStarMakeWeapon permanently switches dITStarRodWeaponStarWeaponDesc to the
## smash attributes after the first smash star (it is never switched back). In the original the overlay
## .data is reloaded from ROM at every battle scene start; a scene port that reproduces that reload can
## call _itStarRodReloadOverlayData().
class_name Itstarrod
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itStarRodStatus
const nITStarRodStatusWait = 0
const nITStarRodStatusFall = 1
const nITStarRodStatusHold = 2
const nITStarRodStatusThrown = 3
const nITStarRodStatusDropped = 4
const nITStarRodStatusEnumCount = 5

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

static var dITStarRodItemDesc := {
	"kind": nITKindStarRod,                                   # Item Kind
	"p_file": "gITManagerCommonData",                         # Pointer to item file data?
	"o_attributes": "llITCommonDataStarRodItemAttributes",    # Offset of item attributes in file? (resolved by Itmanager)
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyR, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                        # Hitbox Update State
	"proc_update": Callable(Itstarrod, &"itStarRodFallProcUpdate"),
	"proc_map": Callable(Itstarrod, &"itStarRodFallProcMap"),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
}

static var dITStarRodStatusDescs: Array = [
	# Status 0 (Ground Wait)
	{"proc_update": Callable(), "proc_map": Callable(Itstarrod, &"itStarRodWaitProcMap"), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 1 (Air Wait Fall)
	{"proc_update": Callable(Itstarrod, &"itStarRodFallProcUpdate"), "proc_map": Callable(Itstarrod, &"itStarRodFallProcMap"), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 2 (Fighter Hold)
	{"proc_update": Callable(), "proc_map": Callable(), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 3 (Fighter Throw)
	{"proc_update": Callable(Itstarrod, &"itStarRodThrownProcUpdate"), "proc_map": Callable(Itstarrod, &"itStarRodThrownProcMap"), "proc_hit": Callable(Itstarrod, &"itStarRodThrownProcHit"), "proc_shield": Callable(Itstarrod, &"itStarRodThrownProcHit"), "proc_hop": Callable(Itmain, &"itMainCommonProcHop"), "proc_setoff": Callable(Itstarrod, &"itStarRodThrownProcHit"), "proc_reflector": Callable(Itmain, &"itMainCommonProcReflector"), "proc_damage": Callable()},
	# Status 4 (Fighter Drop)
	{"proc_update": Callable(Itstarrod, &"itStarRodFallProcUpdate"), "proc_map": Callable(Itstarrod, &"itStarRodDroppedProcMap"), "proc_hit": Callable(Itstarrod, &"itStarRodThrownProcHit"), "proc_shield": Callable(Itstarrod, &"itStarRodThrownProcHit"), "proc_hop": Callable(Itmain, &"itMainCommonProcHop"), "proc_setoff": Callable(Itstarrod, &"itStarRodThrownProcHit"), "proc_reflector": Callable(Itmain, &"itMainCommonProcReflector"), "proc_damage": Callable()},
]

static var dITStarRodWeaponStarWeaponDesc: Dictionary = _itStarRodMakeWeaponStarWeaponDesc()

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80177E80
static func itStarRodFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITSTARROD_GRAVITY, ITSTARROD_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x80177EBC
static func itStarRodWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itstarrod, &"itStarRodFallSetStatus"))

	return FALSE

## 0x80177EE4 - (sic) ignores itMapCheckDestroyDropped's result
static func itStarRodFallProcMap(item_gobj) -> int:
	Itmap.itMapCheckDestroyDropped(item_gobj, ITSTARROD_MAP_REBOUND_COMMON, ITSTARROD_MAP_REBOUND_GROUND, Callable(Itstarrod, &"itStarRodWaitSetStatus"))

	return FALSE

## 0x80177F18
static func itStarRodWaitSetStatus(item_gobj) -> void:
	Itmain.itMainSetGroundAllowPickup(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITStarRodStatusDescs, nITStarRodStatusWait)

## 0x80177F4C
static func itStarRodFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITStarRodStatusDescs, nITStarRodStatusFall)

## 0x80177F90
static func itStarRodHoldSetStatus(item_gobj) -> void:
	DObjGetStruct(item_gobj).rotate.y = F_CST_DTOR32(0.0)

	Itmain.itMainSetStatus(item_gobj, dITStarRodStatusDescs, nITStarRodStatusHold)

## 0x80177FC4
static func itStarRodThrownProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITSTARROD_GRAVITY, ITSTARROD_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x80178000
static func itStarRodThrownProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITSTARROD_MAP_REBOUND_COMMON, ITSTARROD_MAP_REBOUND_GROUND, Callable(Itstarrod, &"itStarRodWaitSetStatus"))

## 0x80178030
static func itStarRodThrownProcHit(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.attack_coll.attack_state = nGMAttackStateOff

	Itmain.itMainVelSetRebound(item_gobj)

	return FALSE

## 0x80178058
static func itStarRodThrownSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITStarRodStatusDescs, nITStarRodStatusThrown)
	DObjGetStruct(item_gobj).child.rotate.y = F_CST_DTOR32(90.0)

## 0x8017809C
static func itStarRodDroppedProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		return Itmap.itMapCheckDestroyLanding(item_gobj, ITSTARROD_MAP_REBOUND_COMMON)
	else:
		return Itmap.itMapCheckDestroyDropped(item_gobj, ITSTARROD_MAP_REBOUND_COMMON, ITSTARROD_MAP_REBOUND_GROUND, Callable(Itstarrod, &"itStarRodWaitSetStatus"))

## 0x801780F0
static func itStarRodDroppedSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITStarRodStatusDescs, nITStarRodStatusDropped)
	DObjGetStruct(item_gobj).child.rotate.y = F_CST_DTOR32(90.0)

## 0x80178134
static func itStarRodMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITStarRodItemDesc, pos, vel, flags)

	if item_gobj != null:
		var ip := itGetStruct(item_gobj)

		ip.multi = ITSTARROD_AMMO_MAX

		ip.is_unused_item_bool = TRUE

		ip.arrow_gobj = Ifcommon.ifCommonItemArrowMakeInterface(ip)

	return item_gobj

## 0x801781B0
static func itStarRodWeaponStarProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var pos: Vector3
	var dobj: DObj

	if wp.weapon_vars.star.lifetime == 0:
		DObjGetStruct(weapon_gobj).flags = DOBJ_FLAG_HIDDEN

		Efmanager.efManagerSparkleWhiteScaleMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

		return TRUE

	wp.weapon_vars.star.lifetime -= 1

	dobj = DObjGetStruct(weapon_gobj)

	dobj.rotate.z += (-0.2 * wp.lr)

	if (wp.weapon_vars.star.lifetime % 2) != 0:
		pos.x = DObjGetStruct(weapon_gobj).translate.x
		pos.y = syUtilsRandIntRange(250) + (DObjGetStruct(weapon_gobj).translate.y - 125.0)
		pos.z = 0.0

		Efmanager.efManagerStarRodSparkMakeEffect(pos, wp.lr * -1.0)

	return FALSE

## 0x801782D4
static func itStarRodWeaponStarProcMap(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if B(Wpmap.wpMapTestAllCheckCollEnd(weapon_gobj)):
		Efmanager.efManagerStarSplashMakeEffect(DObjGetStruct(weapon_gobj).translate, wp.lr)

		Snd.func_800269C0_275C0(nSYAudioFGMStarMapCollide)

		return TRUE
	else:
		return FALSE

## 0x8017832C
static func itStarRodWeaponStarProcHit(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	Efmanager.efManagerStarSplashMakeEffect(DObjGetStruct(weapon_gobj).translate, wp.lr)

	return TRUE

## 0x8017835C
static func itStarRodWeaponStarProcHop(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	wp.physics.vel_air = syVectorRotateAbout3D(wp.physics.vel_air, wp.shield_collide_dir, wp.shield_collide_angle * 2)

	DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x)
	DObjGetStruct(weapon_gobj).scale.x = 1.0

	if wp.physics.vel_air.x > 0.0:
		wp.lr = +1
	else:
		wp.lr = -1

	return FALSE

## 0x80178404
static func itStarRodWeaponStarProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)

	Wpmain.wpMainReflectorSetLR(wp, fp)

	DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x)
	DObjGetStruct(weapon_gobj).scale.x = 1.0

	wp.lr = -wp.lr

	return FALSE

## 0x80178474
static func itStarRodWeaponStarMakeWeapon(fighter_gobj, pos: Vector3, is_smash: int):
	var weapon_gobj
	var dobj: DObj
	var wp: Weapon

	if is_smash == TRUE:
		# Set attribute data on smash input - never restored (C: dITStarRodWeaponStarWeaponDesc.o_attributes = &llITCommonDataStarRodSmashWeaponAttributes)
		dITStarRodWeaponStarWeaponDesc.attributes = Itmanager.dITCommonData_StarRodSmash_WeaponAttributes

	weapon_gobj = Wpmanager.wpManagerMakeWeapon(fighter_gobj, dITStarRodWeaponStarWeaponDesc, pos, (WEAPON_FLAG_COLLPROJECT | WEAPON_FLAG_PARENT_FIGHTER))

	if weapon_gobj == null:
		return null

	dobj = DObjGetStruct(weapon_gobj)
	wp = wpGetStruct(weapon_gobj)

	wp.physics.vel_air.x = (ITSTARROD_AMMO_TILTVEL_X if not B(is_smash) else ITSTARROD_AMMO_SMASH_VEL_X) * wp.lr

	wp.weapon_vars.star.lifetime = int(ITSTARROD_AMMO_TILT_LIFETIME if not B(is_smash) else ITSTARROD_AMMO_SMASH_LIFETIME) # Why float lol

	Objman.gcAddXObjForDObjFixed(dobj, 0x2E, 0)

	dobj.translate = pos
	dobj.translate.z = 0.0

	return weapon_gobj

## 0x80178594
static func itStarRodMakeStar(fighter_gobj, pos: Vector3, is_smash: int) -> void:
	var ip := itGetStruct(ftGetStruct(fighter_gobj).item_gobj)

	itStarRodWeaponStarMakeWeapon(fighter_gobj, pos, is_smash)

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

# // // // // // // // // // // // //
# //         PORT HELPERS          //
# // // // // // // // // // // // //

## dITStarRodWeaponStarWeaponDesc as stored in the overlay's .data (WPDesc, see Wpmanager).
static func _itStarRodMakeWeaponStarWeaponDesc() -> Dictionary:
	return {
		"flags": 0x00,                                    # Render flags?
		"kind": nWPKindStarRodStar,                       # Weapon Kind
		# p_weapon = &gITManagerCommonData, o_attributes = &llITCommonDataStarRodWeaponAttributes
		"attributes": Itmanager.dITCommonData_StarRod_WeaponAttributes,
		"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0},
		"proc_update": Callable(Itstarrod, &"itStarRodWeaponStarProcUpdate"),
		"proc_map": Callable(Itstarrod, &"itStarRodWeaponStarProcMap"),
		"proc_hit": Callable(Itstarrod, &"itStarRodWeaponStarProcHit"),
		"proc_shield": Callable(Itstarrod, &"itStarRodWeaponStarProcHit"),
		"proc_hop": Callable(Itstarrod, &"itStarRodWeaponStarProcHop"),
		"proc_setoff": Callable(Itstarrod, &"itStarRodWeaponStarProcHit"),
		"proc_reflector": Callable(Itstarrod, &"itStarRodWeaponStarProcReflector"),
		"proc_absorb": Callable(Itstarrod, &"itStarRodWeaponStarProcHit"),
		"visual_kind": "star_rod_star",
	}

## Port-only: restore the overlay .data that the C reloads from ROM when a battle scene loads its
## overlays (undoes the smash-attribute switch of itStarRodWeaponStarMakeWeapon).
static func _itStarRodReloadOverlayData() -> void:
	dITStarRodWeaponStarWeaponDesc = _itStarRodMakeWeaponStarWeaponDesc()
