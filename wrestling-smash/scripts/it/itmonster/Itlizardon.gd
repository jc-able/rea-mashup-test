## 1:1 port of src/it/itmonster/itlizardon.c (ssb-decomp-re): Poké Ball Charizard and its
## Flamethrower weapon (nWPKindLizardonFlame; the weapon code lives in this C file, not in src/wp).
##
## Make function (dITManagerProcMakeList entry, called through itManagerMakeItemKind):
##   Itlizardon.itLizardonMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int) -> item_gobj or null
## Shared conventions of the itmonster ports (descs, DObjDesc data, AnimJoints, u16 wrap): see Itpippi.gd.
## ITAttributes: llITCommonDataLizardonItemAttributes (251_ITCommonData.c @ 0x08FC); WPAttributes:
## llITCommonDataLizardonFlameWeaponAttributes (@ 0x0944), from the item core's ROM-verified tables.
class_name Itlizardon
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itLizardonStatus
const nITLizardonStatusFallUnused = 0   # Unused
const nITLizardonStatusFall = 1
const nITLizardonStatusAttack = 2
const nITLizardonStatusEnumCount = 3

# llITCommonData* linker offsets used by this file (tools/relocFileDescriptions.us.txt)
const llITCommonDataLizardonDataStart = 0xD5C0
const llITCommonDataLizardonAnimJoint = 0xD658
const llITCommonDataLizardonMatAnimJoint = 0xD688

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8018AD30
static var dITLizardonItemDesc := {
	"kind": nITKindLizardon,                                    # Item Kind
	"o_attributes": "llITCommonDataLizardonItemAttributes",     # &gITManagerCommonData, &llITCommonDataLizardonItemAttributes

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindNull,                               # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"attack_state": nGMAttackStateNew,                          # Hitbox Update State
	"proc_update": Callable(Itlizardon, &"itLizardonCommonProcUpdate"),     # Proc Update
	"proc_map": Callable(Itlizardon, &"itLizardonCommonProcMap"),           # Proc Map
	"proc_hit": Callable(),                                     # Proc Hit
	"proc_shield": Callable(),                                  # Proc Shield
	"proc_hop": Callable(),                                     # Proc Hop
	"proc_setoff": Callable(),                                  # Proc Set-Off
	"proc_reflector": Callable(),                               # Proc Reflector
	"proc_damage": Callable(),                                  # Proc Damage
}

## 0x8018AD64
static var dITLizardonStatusDescs: Array = [
	# Status 0 (Unused Fall)
	{
		"proc_update": Callable(Itlizardon, &"itLizardonFallUnusedProcUpdate"),
		"proc_map": Callable(Itlizardon, &"itLizardonFallUnusedProcMap"),
		"proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},

	# Status 1 (Air Fall)
	{
		"proc_update": Callable(Itlizardon, &"itLizardonFallProcUpdate"),
		"proc_map": Callable(Itlizardon, &"itLizardonFallProcMap"),
		"proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},

	# Status 2 (Neutral Attack)
	{
		"proc_update": Callable(Itlizardon, &"itLizardonAttackProcUpdate"),
		"proc_map": Callable(Itlizardon, &"itLizardonAttackProcMap"),
		"proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},
]

## 0x8018ADC4
## "attributes" (&gITManagerCommonData + llITCommonDataLizardonFlameWeaponAttributes) is resolved on
## first use by _itLizardonGetWeaponFlameWeaponDesc().
static var dITLizardonWeaponFlameWeaponDesc := {
	"flags": 0x00,                                              # Render flags?
	"kind": nWPKindLizardonFlame,                               # Weapon Kind
	"attributes": null,

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindTraRotRpyRSca,                      # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"proc_update": Callable(Itlizardon, &"itLizardonWeaponFlameProcUpdate"),        # Proc Update
	"proc_map": Callable(Itlizardon, &"itLizardonWeaponFlameProcMap"),              # Proc Map
	"proc_hit": Callable(Itlizardon, &"itLizardonWeaponFlameProcHit"),              # Proc Hit
	"proc_shield": Callable(Itlizardon, &"itLizardonWeaponFlameProcHit"),           # Proc Shield
	"proc_hop": Callable(),                                                         # Proc Hop
	"proc_setoff": Callable(Itlizardon, &"itLizardonWeaponFlameProcHit"),           # Proc Set-Off
	"proc_reflector": Callable(Itlizardon, &"itLizardonWeaponFlameProcReflector"),  # Proc Reflector
	"proc_absorb": Callable(),                                                      # Proc Absorb

	"visual_kind": "lizardon_flame",
}

## AObjEvent32 script dITCommonObject_Lizardon_Item_data_remainder_gap_0xD644_sub_0x14
## (86_ITCommonObject.c @ 0xD658 == llITCommonDataLizardonAnimJoint): Charizard's turn loop
## (model RotY, render only). 11 words, identical to ROM file 86.
static var dITCommonObjectLizardonAnimJoint: AnimStream = _itLizardonMakeAnimJoint()

static func _itLizardonMakeAnimJoint() -> AnimStream:
	var anim_joint := AnimStream.from_u32([
		0x14038000, 0x00000000, 0x00000000, 0x00000000, # [0] aobjEvent32SetValAfterBlock(AOBJ_FLAG_ROTX | AOBJ_FLAG_ROTY | AOBJ_FLAG_ROTZ, 0): 0, 0, 0
		0x1401001A, 0xC0490FDB, # [4] aobjEvent32SetValAfterBlock(AOBJ_FLAG_ROTY, 26): -3.14159274
		0x1401001A, 0xC0490FDB, # [6] aobjEvent32SetValAfterBlock(AOBJ_FLAG_ROTY, 26): -3.14159274
		0x1C000000, # [8] aobjEvent32SetAnim(0x000, 0)
		0x00000000, # [9] (u32)dITCommonObject_Lizardon_Item_data_remainder_gap_0xD644_sub_0x14
		0x00000000, # [10] aobjEvent32End()
	], "dITCommonObject_Lizardon_Item_data_remainder_gap_0xD644_sub_0x14")
	anim_joint.ptr[9] = [anim_joint, 0] # SetAnim target: the start of this same script

	return anim_joint

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8017F470
static func itLizardonFallUnusedProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITLIZARDON_GRAVITY, ITLIZARDON_TVEL)

	return FALSE

## 0x8017F49C
static func itLizardonFallUnusedProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmap.itMapCheckLanding(item_gobj, ITLIZARDON_MAP_REBOUND_COMMON, ITLIZARDON_MAP_REBOUND_GROUND, Callable(Itlizardon, &"itLizardonAttackSetStatus"))

	if ip.coll_data.mask_curr & MAP_FLAG_FLOOR:
		ip.physics.vel_air.y = 0.0

	return FALSE

## 0x8017F49C - Unused. The C declares sb32 but has no return statement (undefined value); FALSE here.
static func itLizardonFallUnusedSetStatus(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITLizardonStatusDescs, nITLizardonStatusFallUnused)

	return FALSE

## 0x8017F53C
static func itLizardonFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITLIZARDON_GRAVITY, ITLIZARDON_TVEL)

	return FALSE

## 0x8017F568
static func itLizardonFallProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmap.itMapTestAllCheckCollEnd(item_gobj)

	if ip.coll_data.mask_curr & MAP_FLAG_FLOOR:
		ip.physics.vel_air.y = 0.0

		itLizardonAttackSetStatus(item_gobj)
		itLizardonAttackInitVars(item_gobj)

	return FALSE

## 0x8017F5C4
static func itLizardonFallSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITLizardonStatusDescs, nITLizardonStatusFall)

## 0x8017F5EC
static func itLizardonAttackProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)
	var pos: Vector3 = dobj.translate

	if ip.kind == nITKindLizardon:
		pos.y += ITLIZARDON_LIZARDON_FLAME_OFF_Y

		pos.x += (ITLIZARDON_LIZARDON_FLAME_OFF_X * ip.lr)

	else:
		pos.x += (ITLIZARDON_OTHER_FLAME_OFF_X * ip.lr)

	if ip.item_vars.lizardon.flame_spawn_wait == 0:
		itLizardonAttackMakeFlame(item_gobj, pos, ip.lr)

		ip.item_vars.lizardon.flame_spawn_wait = ITLIZARDON_FLAME_SPAWN_WAIT

	ip.item_vars.lizardon.flame_spawn_wait = (ip.item_vars.lizardon.flame_spawn_wait - 1) & 0xFFFF # u16

	if ip.multi == 0:
		return TRUE

	if ip.item_vars.lizardon.turn_wait == 0:
		ip.item_vars.lizardon.turn_wait = ITLIZARDON_TURN_WAIT

		ip.lr = -ip.lr

		pos = dobj.translate

		pos.y += ip.attr.map_coll_bottom

		pos.x += (ip.attr.map_coll_width + ITLIZARDON_DUST_OFF_X) * -ip.lr

		Efmanager.efManagerDustHeavyMakeEffect(pos, -ip.lr)

		if ip.kind == nITKindPippi:
			dobj.rotate.y += F_CST_DTOR32(180.0)

	ip.item_vars.lizardon.turn_wait = (ip.item_vars.lizardon.turn_wait - 1) & 0xFFFF # u16

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x8017F7E8
static func itLizardonAttackProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itlizardon, &"itLizardonFallSetStatus"))

	return FALSE

## 0x8017F810
static func itLizardonAttackInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)
	var pos: Vector3

	ip.item_vars.lizardon.turn_wait = ITLIZARDON_TURN_WAIT

	pos = dobj.translate

	ip.item_vars.lizardon.pos = pos
	ip.item_vars.lizardon.flame_spawn_wait = 0

	ip.lr = -1

	if ip.kind == nITKindLizardon:
		# addr = (void*)((uintptr_t)ip->attr->data - (intptr_t)&llITCommonDataLizardonDataStart) == ITCommonObject
		# lbRelocGetFileData(AObjEvent32*, addr, &llITCommonDataLizardonAnimJoint) == ITCommonObject + 0xD658
		ObjAnim.gcAddDObjAnimJoint(dobj, dITCommonObjectLizardonAnimJoint, 0.0)
		# lbRelocGetFileData(AObjEvent32*, addr, &llITCommonDataLizardonMatAnimJoint) == ITCommonObject + 0xD688
		# (dITCommonObject_Lizardon_Item_data_remainder_gap_0xD644_sub_0x44: material animation, render only)
		ObjAnim.gcAddMObjMatAnimJoint(_itLizardonGetMObj(dobj), null, 0.0)
		ObjAnim.gcPlayAnimAll(item_gobj)

## 0x8017F8E4
static func itLizardonAttackSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITLizardonStatusDescs, nITLizardonStatusAttack)

## 0x8017F90C
static func itLizardonCommonProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		ip.multi = ITLIZARDON_LIFETIME

		ip.physics.vel_air.y = 0.0

		if ip.kind == nITKindLizardon:
			Snd.func_800269C0_275C0(nSYAudioVoiceMBallLizardonAppear)

		itLizardonFallSetStatus(item_gobj)

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x8017F98C
static func itLizardonCommonProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if B(Itmap.itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_FLOOR)):
		ip.physics.vel_air.y = 0.0

	return FALSE

## 0x8017F9CC
static func itLizardonMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITLizardonItemDesc, pos, vel, flags)
	var dobj: DObj
	var ip: Item

	if item_gobj != null:
		dobj = DObjGetStruct(item_gobj)

		Objman.gcAddXObjForDObjFixed(dobj, nGCMatrixKindTraRotRpyR, 0)
		Objman.gcAddXObjForDObjFixed(dobj, 0x48, 0)

		dobj.translate = pos

		ip = itGetStruct(item_gobj)

		ip.multi = ITMONSTER_RISE_STOP_WAIT

		ip.physics.vel_air.z = 0.0
		ip.physics.vel_air.x = ip.physics.vel_air.z
		ip.physics.vel_air.y = ITMONSTER_RISE_VEL_Y

		dobj.translate.y -= ip.attr.map_coll_bottom

		# itGetMonsterAnimNode(ip, &llITCommonDataLizardonDataStart) == ITCommonObject + 0x13624
		ObjAnim.gcAddDObjAnimJoint(dobj, Itpippi.dITCommonObjectMonsterAnimBank, 0.0)

	return item_gobj

## 0x8017FACC
static func itLizardonWeaponFlameProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if B(Wpmain.wpMainDecLifeCheckExpire(wp)):
		return TRUE

	else:
		return FALSE

## 0x8017FAF8
static func itLizardonWeaponFlameProcMap(weapon_gobj) -> int:
	if B(Wpmap.wpMapTestAllCheckCollEnd(weapon_gobj)):
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

		return TRUE

	else:
		return FALSE

## 0x8017FB3C
static func itLizardonWeaponFlameProcHit(weapon_gobj) -> int:
	Snd.func_800269C0_275C0(nSYAudioFGMExplodeS)
	Efmanager.efManagerSparkleWhiteMakeEffect(DObjGetStruct(weapon_gobj).translate)

	return FALSE

## 0x8017FB74
static func itLizardonWeaponFlameProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)
	var translate: Vector3

	wp.lifetime = ITLIZARDON_FLAME_LIFETIME

	Wpmain.wpMainReflectorSetLR(wp, fp)

	translate = DObjGetStruct(weapon_gobj).translate

	# gITManagerParticleBankID | LBPARTICLE_MASK_GENLINK(0) (== ((0 + 1) * 8))
	Lbparticle.lbParticleMakePosVel(Itmanager.gITManagerParticleBankID | ((0 + 1) * 8), 2, translate.x, translate.y, 0.0, wp.physics.vel_air.x, wp.physics.vel_air.y, 0.0)
	Lbparticle.lbParticleMakePosVel(Itmanager.gITManagerParticleBankID | ((0 + 1) * 8), 0, translate.x, translate.y, 0.0, wp.physics.vel_air.x, wp.physics.vel_air.y, 0.0)

	return FALSE

## 0x8017FC38
static func itLizardonWeaponFlameMakeWeapon(item_gobj, pos: Vector3, vel: Vector3):
	var weapon_gobj = Wpmanager.wpManagerMakeWeapon(item_gobj, _itLizardonGetWeaponFlameWeaponDesc(), pos, WEAPON_FLAG_PARENT_ITEM)
	var ip: Weapon

	if weapon_gobj == null:
		return null

	ip = wpGetStruct(weapon_gobj)

	ip.physics.vel_air = vel

	ip.lifetime = ITLIZARDON_FLAME_LIFETIME

	Lbparticle.lbParticleMakePosVel(Itmanager.gITManagerParticleBankID | ((0 + 1) * 8), 2, pos.x, pos.y, 0.0, ip.physics.vel_air.x, ip.physics.vel_air.y, 0.0) # This needs to return something in v0 to match
	Lbparticle.lbParticleMakePosVel(Itmanager.gITManagerParticleBankID | ((0 + 1) * 8), 0, pos.x, pos.y, 0.0, ip.physics.vel_air.x, ip.physics.vel_air.y, 0.0)

	return weapon_gobj

## 0x8017FD2C
static func itLizardonAttackMakeFlame(item_gobj, pos: Vector3, lr: int) -> void:
	var _ip := itGetStruct(item_gobj)
	var vel: Vector3

	vel.x = __cosf(ITLIZARDON_FLAME_ANGLE) * ITLIZARDON_FLAME_VEL * lr
	vel.y = __sinf(ITLIZARDON_FLAME_ANGLE) * ITLIZARDON_FLAME_VEL
	vel.z = 0.0

	itLizardonWeaponFlameMakeWeapon(item_gobj, pos, vel)

	Snd.func_800269C0_275C0(nSYAudioFGMLizardonFlame)

# ---------------------------------------------------------------------------------------
# Port helpers
# ---------------------------------------------------------------------------------------

## dITLizardonWeaponFlameWeaponDesc with lbRelocGetFileData(WPAttributes*, gITManagerCommonData,
## &llITCommonDataLizardonFlameWeaponAttributes) resolved (item core table).
static func _itLizardonGetWeaponFlameWeaponDesc() -> Dictionary:
	if dITLizardonWeaponFlameWeaponDesc.attributes == null:
		dITLizardonWeaponFlameWeaponDesc.attributes = Itmanager.itManagerGetCommonData("llITCommonDataLizardonFlameWeaponAttributes")

	return dITLizardonWeaponFlameWeaponDesc

## dobj->mobj (first MObj of the joint); MObjs are render-only in this port (see Itpippi.gd).
static func _itLizardonGetMObj(dobj: DObj):
	if dobj == null:
		return null
	var mobjs: Array = dobj.get_meta(&"mobjs", [])

	return mobjs[0] if not mobjs.is_empty() else null
