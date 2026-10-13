## 1:1 port of src/it/itcommon/itfflower.c (ssb-decomp-re): Fire Flower item and its flame projectile (weapon).
##
## Data conventions: see Itbox (ITDesc / ITStatusDesc Dictionaries with the C field names; the ITAttributes
## and DObjDesc tree come from the ITCommonData tables in Itmanager.gd). The WPDesc is a Wpmanager
## Dictionary whose "attributes" are Itmanager's dITCommonData_FFlowerFlame_WeaponAttributes and the flame
## angles are llITCommonDataFFlowerFlameAngles (src/relocData/251_ITCommonData.c).
class_name Itfflower
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itFFlowerStatus
const nITFFlowerStatusWait = 0
const nITFFlowerStatusFall = 1
const nITFFlowerStatusHold = 2
const nITFFlowerStatusThrown = 3
const nITFFlowerStatusDropped = 4
const nITFFlowerStatusEnumCount = 5

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

static var dITFFlowerItemDesc := {
	"kind": nITKindFFlower,                                   # Item Kind
	"p_file": "gITManagerCommonData",                         # Pointer to item file data?
	"o_attributes": "llITCommonDataFFlowerItemAttributes",    # Offset of item attributes in file? (resolved by Itmanager)
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyR, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                        # Hitbox Update State
	"proc_update": Callable(Itfflower, &"itFFlowerFallProcUpdate"),
	"proc_map": Callable(Itfflower, &"itFFlowerFallProcMap"),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
}

static var dITFFlowerStatusDescs: Array = [
	# Status 0 (Ground Wait)
	{"proc_update": Callable(), "proc_map": Callable(Itfflower, &"itFFlowerWaitProcMap"), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 1 (Air Wait Fall)
	{"proc_update": Callable(Itfflower, &"itFFlowerFallProcUpdate"), "proc_map": Callable(Itfflower, &"itFFlowerFallProcMap"), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 2 (Fighter Hold)
	{"proc_update": Callable(), "proc_map": Callable(), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(), "proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable()},
	# Status 3 (Fighter Throw)
	{"proc_update": Callable(Itfflower, &"itFFlowerFallProcUpdate"), "proc_map": Callable(Itfflower, &"itFFlowerThrownProcMap"), "proc_hit": Callable(Itfflower, &"itFFlowerCommonProcHit"), "proc_shield": Callable(Itfflower, &"itFFlowerCommonProcHit"), "proc_hop": Callable(Itmain, &"itMainCommonProcHop"), "proc_setoff": Callable(Itfflower, &"itFFlowerCommonProcHit"), "proc_reflector": Callable(Itmain, &"itMainCommonProcReflector"), "proc_damage": Callable()},
	# Status 4 (Fighter Drop)
	{"proc_update": Callable(Itfflower, &"itFFlowerFallProcUpdate"), "proc_map": Callable(Itfflower, &"itFFlowerDroppedProcMap"), "proc_hit": Callable(Itfflower, &"itFFlowerCommonProcHit"), "proc_shield": Callable(Itfflower, &"itFFlowerCommonProcHit"), "proc_hop": Callable(Itmain, &"itMainCommonProcHop"), "proc_setoff": Callable(Itfflower, &"itFFlowerCommonProcHit"), "proc_reflector": Callable(Itmain, &"itMainCommonProcReflector"), "proc_damage": Callable()},
]

static var dITFFlowerWeaponFlameWeaponDesc := {
	"flags": 0x00,                                            # Render flags?
	"kind": nWPKindFFlowerFlame,                              # Weapon Kind
	# p_weapon = &gITManagerCommonData, o_attributes = &llITCommonDataFFlowerFlameWeaponAttributes
	"attributes": Itmanager.dITCommonData_FFlowerFlame_WeaponAttributes,
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0},
	"proc_update": Callable(Itfflower, &"itFFlowerWeaponFlameProcUpdate"),
	"proc_map": Callable(Itfflower, &"itFFlowerWeaponFlameProcMap"),
	"proc_hit": Callable(Itfflower, &"itFFlowerWeaponFlameProcHit"),
	"proc_shield": Callable(Itfflower, &"itFFlowerWeaponFlameProcHit"),
	"proc_hop": Callable(),
	"proc_setoff": Callable(Itfflower, &"itFFlowerWeaponFlameProcHit"),
	"proc_reflector": Callable(Itfflower, &"itFFlowerWeaponFlameProcReflector"),
	"proc_absorb": Callable(),
	"visual_kind": "fflower_flame",
}

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80175B20
static func itFFlowerFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITFFLOWER_GRAVITY, ITFFLOWER_TVEL)
	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x80175B5C
static func itFFlowerWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itfflower, &"itFFlowerFallSetStatus"))

	return FALSE

## 0x80175B84
static func itFFlowerFallProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITFFLOWER_MAP_REBOUND_COMMON, ITFFLOWER_MAP_REBOUND_GROUND, Callable(Itfflower, &"itFFlowerWaitSetStatus"))

## 0x80175BB0
static func itFFlowerWaitSetStatus(item_gobj) -> void:
	Itmain.itMainSetGroundAllowPickup(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITFFlowerStatusDescs, nITFFlowerStatusWait)

## 0x80175BE4
static func itFFlowerFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITFFlowerStatusDescs, nITFFlowerStatusFall)

## 0x80175C28
static func itFFlowerHoldSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITFFlowerStatusDescs, nITFFlowerStatusHold)

## 0x80175C50
static func itFFlowerThrownProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		return Itmap.itMapCheckDestroyLanding(item_gobj, ITFFLOWER_MAP_REBOUND_COMMON)
	else:
		return Itmap.itMapCheckDestroyDropped(item_gobj, ITFFLOWER_MAP_REBOUND_COMMON, ITFFLOWER_MAP_REBOUND_GROUND, Callable(Itfflower, &"itFFlowerWaitSetStatus"))

## 0x80175C9C
static func itFFlowerCommonProcHit(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.attack_coll.attack_state = nGMAttackStateOff

	Itmain.itMainVelSetRebound(item_gobj)

	return FALSE

## 0x80175CC4
static func itFFlowerThrownSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITFFlowerStatusDescs, nITFFlowerStatusThrown)

## 0x80175CEC
static func itFFlowerDroppedProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		return Itmap.itMapCheckDestroyLanding(item_gobj, ITFFLOWER_MAP_REBOUND_COMMON)
	else:
		return Itmap.itMapCheckDestroyDropped(item_gobj, ITFFLOWER_MAP_REBOUND_COMMON, ITFFLOWER_MAP_REBOUND_GROUND, Callable(Itfflower, &"itFFlowerWaitSetStatus"))

## 0x80175D38
static func itFFlowerDroppedSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITFFlowerStatusDescs, nITFFlowerStatusDropped)

## 0x80175D60
static func itFFlowerMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITFFlowerItemDesc, pos, vel, flags)

	if item_gobj != null:
		var ip := itGetStruct(item_gobj)

		ip.multi = ITFFLOWER_AMMO_MAX

		ip.is_unused_item_bool = TRUE

		ip.arrow_gobj = Ifcommon.ifCommonItemArrowMakeInterface(ip)

	return item_gobj

## 0x80175DDC
static func itFFlowerWeaponFlameProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if B(Wpmain.wpMainDecLifeCheckExpire(wp)):
		return TRUE
	else:
		return FALSE

## 0x801750E8 (sic)
static func itFFlowerWeaponFlameProcMap(weapon_gobj) -> int:
	if B(Wpmap.wpMapTestAllCheckCollEnd(weapon_gobj)):
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

		return TRUE
	else:
		return FALSE

## 0x80175E4C - (sic) returns FALSE: the flame is not destroyed when it hits
static func itFFlowerWeaponFlameProcHit(weapon_gobj) -> int:
	Snd.func_800269C0_275C0(nSYAudioFGMExplodeS)
	Efmanager.efManagerSparkleWhiteMakeEffect(DObjGetStruct(weapon_gobj).translate)

	return FALSE

## 0x80175E84
static func itFFlowerWeaponFlameProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)
	var translate: Vector3

	wp.lifetime = ITFFLOWER_AMMO_LIFETIME

	Wpmain.wpMainReflectorSetLR(wp, fp)

	translate = DObjGetStruct(weapon_gobj).translate

	Lbparticle.lbParticleMakePosVel(Itmanager.gITManagerParticleBankID | LBPARTICLE_MASK_GENLINK(0), 2, translate.x, translate.y, 0.0, wp.physics.vel_air.x, wp.physics.vel_air.y, 0.0)
	Lbparticle.lbParticleMakePosVel(Itmanager.gITManagerParticleBankID | LBPARTICLE_MASK_GENLINK(0), 0, translate.x, translate.y, 0.0, wp.physics.vel_air.x, wp.physics.vel_air.y, 0.0)

	return FALSE

## 0x80175F48
static func itFFlowerWeaponFlameMakeWeapon(fighter_gobj, pos: Vector3, vel: Vector3):
	var weapon_gobj = Wpmanager.wpManagerMakeWeapon(fighter_gobj, dITFFlowerWeaponFlameWeaponDesc, pos, (WEAPON_FLAG_COLLPROJECT | WEAPON_FLAG_PARENT_FIGHTER))
	var wp: Weapon

	if weapon_gobj == null:
		return null

	wp = wpGetStruct(weapon_gobj)

	wp.physics.vel_air.x = vel.x * wp.lr
	wp.physics.vel_air.y = vel.y
	wp.physics.vel_air.z = vel.z

	wp.lifetime = ITFFLOWER_AMMO_LIFETIME

	Lbparticle.lbParticleMakePosVel(Itmanager.gITManagerParticleBankID | LBPARTICLE_MASK_GENLINK(0), 2, pos.x, pos.y, 0.0, wp.physics.vel_air.x, wp.physics.vel_air.y, 0.0)
	Lbparticle.lbParticleMakePosVel(Itmanager.gITManagerParticleBankID | LBPARTICLE_MASK_GENLINK(0), 0, pos.x, pos.y, 0.0, wp.physics.vel_air.x, wp.physics.vel_air.y, 0.0)

	return weapon_gobj

## 0x8017604C
static func itFFlowerShootFlame(fighter_gobj, pos: Vector3, index: int, ammo_sub: int) -> void:
	var ip := itGetStruct(ftGetStruct(fighter_gobj).item_gobj)
	var vel: Vector3
	var angle: Array = Itmanager.itManagerGetCommonData(&"llITCommonDataFFlowerFlameAngles") # (f32*) (file + &llITCommonDataFFlowerFlameAngles)

	vel.x = __cosf(angle[index]) * ITFFLOWER_AMMO_VEL
	vel.y = __sinf(angle[index]) * ITFFLOWER_AMMO_VEL
	vel.z = 0.0

	itFFlowerWeaponFlameMakeWeapon(fighter_gobj, pos, vel)

	ip.multi = (ip.multi - ammo_sub) & 0xFFFF # u16

# // // // // // // // // // // // //
# //         PORT HELPERS          //
# // // // // // // // // // // // //

## src/lb/lbdef.h LBPARTICLE_MASK_GENLINK(id)
static func LBPARTICLE_MASK_GENLINK(id: int) -> int:
	return (id + 1) * 8
