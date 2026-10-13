## 1:1 port of src/it/itcommon/itlgun.c (ssb-decomp-re): Ray Gun item and its ammo projectile (weapon).
##
## Data conventions: see Itbox (ITDesc / ITStatusDesc Dictionaries with the C field names; the ITAttributes
## and DObjDesc tree come from the ITCommonData tables in Itmanager.gd). The WPDesc is a Wpmanager
## Dictionary whose "attributes" are Itmanager's dITCommonData_LGunAmmo_WeaponAttributes
## (src/relocData/251_ITCommonData.c).
class_name Itlgun
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itLGunStatus
const nITLGunStatusWait = 0
const nITLGunStatusFall = 1
const nITLGunStatusHold = 2
const nITLGunStatusThrown = 3
const nITLGunStatusDropped = 4
const nITLGunStatusEnumCount = 5

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

static var dITLGunItemDesc := {
	"kind": nITKindLGun,                                      # Item Kind
	"p_file": "gITManagerCommonData",                         # Pointer to item file data?
	"o_attributes": "llITCommonDataLGunItemAttributes",       # Offset of item attributes in file? (resolved by Itmanager)
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyR, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                        # Hitbox Update State
	"proc_update": Callable(Itlgun, &"itLGunFallProcUpdate"),
	"proc_map": Callable(Itlgun, &"itLGunFallProcMap"),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
}

static var dITLGunStatusDescs: Array = [
	# Status 0 (Ground Wait)
	{"proc_update": Callable(), "proc_map": Callable(Itlgun, &"itLGunWaitProcMap"), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 1 (Air Wait Fall)
	{"proc_update": Callable(Itlgun, &"itLGunFallProcUpdate"), "proc_map": Callable(Itlgun, &"itLGunFallProcMap"), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 2 (Fighter Hold)
	{"proc_update": Callable(), "proc_map": Callable(), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 3 (Fighter Throw)
	{"proc_update": Callable(Itlgun, &"itLGunFallProcUpdate"), "proc_map": Callable(Itlgun, &"itLGunThrownProcMap"), "proc_hit": Callable(Itlgun, &"itLGunCommonProcHit"), "proc_shield": Callable(Itlgun, &"itLGunCommonProcHit"), "proc_hop": Callable(Itmain, &"itMainCommonProcHop"), "proc_setoff": Callable(Itlgun, &"itLGunCommonProcHit"), "proc_reflector": Callable(Itmain, &"itMainCommonProcReflector"), "proc_damage": Callable()},
	# Status 4 (Fighter Drop)
	{"proc_update": Callable(Itlgun, &"itLGunFallProcUpdate"), "proc_map": Callable(Itlgun, &"itLGunDroppedProcMap"), "proc_hit": Callable(Itlgun, &"itLGunCommonProcHit"), "proc_shield": Callable(Itlgun, &"itLGunCommonProcHit"), "proc_hop": Callable(Itmain, &"itMainCommonProcHop"), "proc_setoff": Callable(Itlgun, &"itLGunCommonProcHit"), "proc_reflector": Callable(Itmain, &"itMainCommonProcReflector"), "proc_damage": Callable()},
]

static var dITLGunAmmoWeaponDesc := {
	"flags": 0x00,                                            # Render flags?
	"kind": nWPKindLGunAmmo,                                  # Weapon Kind
	# p_weapon = &gITManagerCommonData, o_attributes = &llITCommonDataLGunAmmoWeaponAttributes
	"attributes": Itmanager.dITCommonData_LGunAmmo_WeaponAttributes,
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0},
	"proc_update": Callable(Itlgun, &"itLGunWeaponAmmoProcUpdate"),
	"proc_map": Callable(Itlgun, &"itLGunWeaponAmmoProcMap"),
	"proc_hit": Callable(Itlgun, &"itLGunWeaponAmmoProcHit"),
	"proc_shield": Callable(Itlgun, &"itLGunWeaponAmmoProcHit"),
	"proc_hop": Callable(Itlgun, &"itLGunWeaponAmmoProcHop"),
	"proc_setoff": Callable(Itlgun, &"itLGunWeaponAmmoProcHit"),
	"proc_reflector": Callable(Itlgun, &"itLGunWeaponAmmoProcReflector"),
	"proc_absorb": Callable(Itlgun, &"itLGunWeaponAmmoProcHit"),
	"visual_kind": "lgun_ammo",
}

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801754F0
static func itLGunFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITLGUN_GRAVITY, ITLGUN_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x80175528
static func itLGunWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itlgun, &"itLGunFallSetStatus"))

	return FALSE

## 0x80175550
static func itLGunFallProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITLGUN_MAP_REBOUND_COMMON, ITLGUN_MAP_REBOUND_GROUND, Callable(Itlgun, &"itLGunWaitSetStatus"))

## 0x80175584
static func itLGunWaitSetStatus(item_gobj) -> void:
	Itmain.itMainSetGroundAllowPickup(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITLGunStatusDescs, nITLGunStatusWait)

## 0x801755B8
static func itLGunFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITLGunStatusDescs, nITLGunStatusFall)

## 0x801755FC
static func itLGunHoldSetStatus(item_gobj) -> void:
	DObjGetStruct(item_gobj).rotate.y = F_CST_DTOR32(0.0)

	Itmain.itMainSetStatus(item_gobj, dITLGunStatusDescs, nITLGunStatusHold)

## 0x80175630
static func itLGunThrownProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		return Itmap.itMapCheckDestroyLanding(item_gobj, ITLGUN_MAP_REBOUND_COMMON)
	else:
		return Itmap.itMapCheckDestroyDropped(item_gobj, ITLGUN_MAP_REBOUND_COMMON, ITLGUN_MAP_REBOUND_GROUND, Callable(Itlgun, &"itLGunWaitSetStatus"))

## 0x80175684
static func itLGunCommonProcHit(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.attack_coll.attack_state = nGMAttackStateOff

	Itmain.itMainVelSetRebound(item_gobj)

	return FALSE

## 0x801756AC
static func itLGunThrownSetStatus(item_gobj) -> void:
	var lr: int = ftGetStruct(itGetStruct(item_gobj).owner_gobj).lr

	Itmain.itMainSetStatus(item_gobj, dITLGunStatusDescs, nITLGunStatusThrown)

	DObjGetStruct(item_gobj).child.rotate.y = F_CST_DTOR32(-90.0) if (lr == -1) else F_CST_DTOR32(90.0)

## 0x8017572C
static func itLGunDroppedProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		return Itmap.itMapCheckDestroyLanding(item_gobj, ITLGUN_MAP_REBOUND_COMMON)
	else:
		return Itmap.itMapCheckDestroyDropped(item_gobj, ITLGUN_MAP_REBOUND_COMMON, ITLGUN_MAP_REBOUND_GROUND, Callable(Itlgun, &"itLGunWaitSetStatus"))

## 0x80175780
static func itLGunDroppedSetStatus(item_gobj) -> void:
	var lr: int = ftGetStruct(itGetStruct(item_gobj).owner_gobj).lr

	Itmain.itMainSetStatus(item_gobj, dITLGunStatusDescs, nITLGunStatusDropped)

	DObjGetStruct(item_gobj).child.rotate.y = F_CST_DTOR32(-90.0) if (lr == -1) else F_CST_DTOR32(90.0)

## 0x80175800
static func itLGunMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITLGunItemDesc, pos, vel, flags)

	if item_gobj != null:
		var ip := itGetStruct(item_gobj)

		ip.multi = ITLGUN_AMMO_MAX

		DObjGetStruct(item_gobj).rotate.y = F_CST_DTOR32(90.0) if ((syUtilsRandUShort() % 2) != 0) else F_CST_DTOR32(-90.0)

		ip.is_unused_item_bool = TRUE

		ip.arrow_gobj = Ifcommon.ifCommonItemArrowMakeInterface(ip)

	return item_gobj

## Ray Gun ammo functions (no address comment in the C source; precedes 0x80175914)
static func itLGunWeaponAmmoProcUpdate(weapon_gobj) -> int:
	var dobj: DObj = DObjGetStruct(weapon_gobj)

	if dobj.scale.x < ITLGUN_AMMO_CLAMP_SCALE_X:
		dobj.scale.x += ITLGUN_AMMO_STEP_SCALE_X

		dobj = DObjGetStruct(weapon_gobj) # Y tho lol (!DAIRANTOU_OPT0)

		if dobj.scale.x > ITLGUN_AMMO_CLAMP_SCALE_X:
			dobj.scale.x = ITLGUN_AMMO_CLAMP_SCALE_X

	return FALSE

## 0x80175914
static func itLGunWeaponAmmoProcMap(weapon_gobj) -> int:
	if B(Wpmap.wpMapTestAllCheckCollEnd(weapon_gobj)):
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

		return TRUE
	else:
		return FALSE

## 0x80175958
static func itLGunWeaponAmmoProcHit(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	Efmanager.efManagerImpactShockMakeEffect(DObjGetStruct(weapon_gobj).translate, wp.attack_coll.damage)

	return TRUE

## 0x80175988
static func itLGunWeaponAmmoProcHop(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	wp.physics.vel_air = syVectorRotateAbout3D(wp.physics.vel_air, wp.shield_collide_dir, wp.shield_collide_angle * 2)

	DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x)
	DObjGetStruct(weapon_gobj).scale.x = 1.0

	return FALSE

## 0x80175A00
static func itLGunWeaponAmmoProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)

	Wpmain.wpMainReflectorSetLR(wp, fp)

	DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x)
	DObjGetStruct(weapon_gobj).scale.x = 1.0

	return FALSE

## 0x80175A60
static func itLGunWeaponAmmoMakeWeapon(fighter_gobj, pos: Vector3):
	var weapon_gobj = Wpmanager.wpManagerMakeWeapon(fighter_gobj, dITLGunAmmoWeaponDesc, pos, (WEAPON_FLAG_COLLPROJECT | WEAPON_FLAG_PARENT_FIGHTER))
	var wp: Weapon

	if weapon_gobj == null:
		return null

	wp = wpGetStruct(weapon_gobj)

	wp.physics.vel_air.x = wp.lr * ITLGUN_AMMO_VEL_X

	DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x)

	return weapon_gobj

## 0x80175AD8
static func itLGunMakeAmmo(fighter_gobj, pos: Vector3) -> void:
	var ip := itGetStruct(ftGetStruct(fighter_gobj).item_gobj)

	itLGunWeaponAmmoMakeWeapon(fighter_gobj, pos)

	ip.multi = (ip.multi - 1) & 0xFFFF # u16
