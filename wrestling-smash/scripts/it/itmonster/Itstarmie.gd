## 1:1 port of src/it/itmonster/itstarmie.c (ssb-decomp-re): Poké Ball Starmie and its Swift weapon
## (nWPKindStarmieSwift; the weapon code lives in this C file, not in src/wp).
##
## Make function (dITManagerProcMakeList entry, called through itManagerMakeItemKind):
##   Itstarmie.itStarmieMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int) -> item_gobj or null
## Shared conventions of the itmonster ports (descs, DObjDesc data, AnimJoints, u16 wrap): see Itpippi.gd.
## ITAttributes: llITCommonDataStarmieItemAttributes (251_ITCommonData.c @ 0x0B34); WPAttributes:
## llITCommonDataStarmieSwiftWeaponAttributes (@ 0x0B7C), from the item core's ROM-verified tables.
class_name Itstarmie
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itStarmieStatus
const nITStarmieStatusNFollow = 0
const nITStarmieStatusAttack = 1
const nITStarmieStatusEnumCount = 2

# llITCommonData* linker offsets used by this file (tools/relocFileDescriptions.us.txt)
const llITCommonDataStarmieDataStart = 0x112A0
const llITCommonDataStarmieMatAnimJoint = 0x11338

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8018B170
static var dITStarmieItemDesc := {
	"kind": nITKindStarmie,                                     # Item Kind
	"o_attributes": "llITCommonDataStarmieItemAttributes",      # &gITManagerCommonData, &llITCommonDataStarmieItemAttributes

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindTraRotRpyR,                         # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"attack_state": nGMAttackStateNew,                          # Hitbox Update State
	"proc_update": Callable(Itstarmie, &"itStarmieCommonProcUpdate"),   # Proc Update
	"proc_map": Callable(Itstarmie, &"itStarmieCommonProcMap"),         # Proc Map
	"proc_hit": Callable(),                                     # Proc Hit
	"proc_shield": Callable(),                                  # Proc Shield
	"proc_hop": Callable(),                                     # Proc Hop
	"proc_setoff": Callable(),                                  # Proc Set-Off
	"proc_reflector": Callable(),                               # Proc Reflector
	"proc_damage": Callable(),                                  # Proc Damage
}

## 0x8018B1A4
static var dITStarmieStatusDescs: Array = [
	# Status 0 (Neutral Follow)
	{
		"proc_update": Callable(Itstarmie, &"itStarmieNFollowProcUpdate"),
		"proc_map": Callable(), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},

	# Status 1 (Neutral Attack)
	{
		"proc_update": Callable(Itstarmie, &"itStarmieAttackProcUpdate"),
		"proc_map": Callable(), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},
]

## 0x8018B1E4
## "attributes" (&gITManagerCommonData + llITCommonDataStarmieSwiftWeaponAttributes) is resolved on
## first use by _itStarmieGetWeaponSwiftWeaponDesc().
static var dITStarmieWeaponSwiftWeaponDesc := {
	"flags": 0x03,                                              # Render flags? (WEAPON_FLAG_DOBJDESC | WEAPON_FLAG_DOBJLINKS)
	"kind": nWPKindStarmieSwift,                                # Weapon Kind
	"attributes": null,

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindTraRotRpyRSca,                      # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"proc_update": Callable(Itstarmie, &"itStarmieWeaponSwiftProcUpdate"),          # Proc Update
	"proc_map": Callable(),                                                         # Proc Map
	"proc_hit": Callable(Itstarmie, &"itStarmieWeaponSwiftProcHit"),                # Proc Hit
	"proc_shield": Callable(Itstarmie, &"itStarmieWeaponSwiftProcHit"),             # Proc Shield
	"proc_hop": Callable(Itstarmie, &"itStarmieWeaponSwiftProcHop"),                # Proc Hop
	"proc_setoff": Callable(Itstarmie, &"itStarmieWeaponSwiftProcHit"),             # Proc Set-Off
	"proc_reflector": Callable(Itstarmie, &"itStarmieWeaponSwiftProcReflector"),    # Proc Reflector
	"proc_absorb": Callable(Itstarmie, &"itStarmieWeaponSwiftProcHit"),             # Proc Absorb

	"visual_kind": "starmie_swift",
}

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80181C20
static func itStarmieAttackUpdateSwift(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	if ip.item_vars.starmie.swift_spawn_wait <= 0:
		var pos: Vector3 = dobj.translate

		if ip.kind == nITKindStarmie:
			pos.x += ITSTARMIE_STARMIE_SWIFT_SPAWN_OFF_X * ip.lr
			pos.y += ITSTARMIE_STARMIE_SWIFT_SPAWN_OFF_Y

		else:
			pos.x += ITSTARMIE_OTHER_SWIFT_SPAWN_OFF_X * ip.lr

		itStarmieAttackMakeSwift(item_gobj, pos)

		Snd.func_800269C0_275C0(nSYAudioFGMMonsterShoot)

		ip.item_vars.starmie.swift_spawn_wait = (syUtilsRandIntRange(ITSTARMIE_SWIFT_SPAWN_WAIT_RANDOM) + ITSTARMIE_SWIFT_SPAWN_WAIT_CONST)

		ip.physics.vel_air.x = -ip.lr * ITSTARMIE_PUSH_VEL_X

## 0x80181D24
static func itStarmieAttackProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		return TRUE

	itStarmieAttackUpdateSwift(item_gobj)

	ip.item_vars.starmie.swift_spawn_wait -= 1

	ip.physics.vel_air.x += ip.item_vars.starmie.add_vel_x

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x80181D8C
static func itStarmieAttackInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)
	var lr_bak: int = ip.lr

	ip.lr = -1 if (ip.item_vars.starmie.victim_pos.x < dobj.translate.x) else +1

	if ip.lr != lr_bak:
		dobj.rotate.y += F_CST_DTOR32(180.0)

	ip.multi = ITSTARMIE_LIFETIME

	ip.item_vars.starmie.swift_spawn_wait = 0
	ip.item_vars.starmie.add_vel_x = ip.lr * ITSTARMIE_ADD_VEL_X

## 0x80181E0C
static func itStarmieAttackSetStatus(item_gobj) -> void:
	itStarmieAttackInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITStarmieStatusDescs, nITStarmieStatusAttack)

## 0x80181E40
static func itStarmieNFollowProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	if (ip.lr == +1) and (dobj.translate.x >= ip.item_vars.starmie.target_pos.x):
		ip.physics.vel_air.x = 0.0
		ip.physics.vel_air.y = 0.0

		itStarmieAttackSetStatus(item_gobj)

	if (ip.lr == -1) and (dobj.translate.x <= ip.item_vars.starmie.target_pos.x):
		ip.physics.vel_air.x = 0.0
		ip.physics.vel_air.y = 0.0

		itStarmieAttackSetStatus(item_gobj)

	return FALSE

## 0x80181EF4
static func itStarmieNFollowFindFollowPlayerLR(item_gobj, fighter_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var fp := ftGetStruct(fighter_gobj)
	var item_dobj := DObjGetStruct(item_gobj)
	var fighter_dobj := DObjGetStruct(fighter_gobj)
	var dist: Vector3
	var target_pos: Vector3

	target_pos = fighter_dobj.translate

	dist.x = fighter_dobj.translate.x - item_dobj.translate.x

	target_pos.y += ITSTARMIE_TARGET_POS_OFF_Y - fp.coll_data.map_coll.bottom

	target_pos.x -= (fp.coll_data.map_coll.width + ITSTARMIE_TARGET_POS_OFF_X) * (-1 if (dist.x < 0.0) else +1)

	# victim_pos = &fighter_dobj->translate.vec.f; (dereferenced below, unchanged in between)

	dist = target_pos - item_dobj.translate # syVectorDiff3D(&dist, &target_pos, &item_dobj->translate.vec.f)

	ip.physics.vel_air.z = 0.0
	ip.physics.vel_air.y = ip.physics.vel_air.z
	ip.physics.vel_air.x = ITSTARMIE_FOLLOW_VEL_X

	ip.physics.vel_air = syVectorRotate3D(ip.physics.vel_air, SYVECTOR_AXIS_Z, syUtilsArcTan2(dist.y, dist.x))

	ip.item_vars.starmie.target_pos = target_pos

	ip.item_vars.starmie.victim_pos = fighter_dobj.translate # *victim_pos

	ip.lr = -1 if (dist.x < 0.0) else +1

	if ip.lr == +1:
		item_dobj.rotate.y = F_CST_DTOR32(180.0)

	if ip.kind == nITKindStarmie:
		# itGetPData(ip, &llITCommonDataStarmieDataStart, &llITCommonDataStarmieMatAnimJoint) == ITCommonObject + 0x11338
		# (dITCommonObject_Starmie_Item_data_remainder_sub_0x14: material animation, render only)
		ObjAnim.gcAddMObjMatAnimJoint(_itStarmieGetMObj(item_dobj), null, 0)

		ObjAnim.gcPlayAnimAll(item_gobj)

## 0x801820CC
## Port note: like C, victim_gobj is only set when an enemy fighter exists (C reads an
## uninitialised local otherwise; this port would fail on the null victim).
static func itStarmieNFollowInitVars(item_gobj) -> void:
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

	itStarmieNFollowFindFollowPlayerLR(item_gobj, victim_gobj)

	if ip.kind == nITKindStarmie:
		Snd.func_800269C0_275C0(nSYAudioVoiceMBallStarmieAppear)

## 0x801821E8
static func itStarmieNFollowSetStatus(item_gobj) -> void:
	itStarmieNFollowInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITStarmieStatusDescs, nITStarmieStatusNFollow)

## 0x8018221C
static func itStarmieCommonProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		ip.physics.vel_air.y = 0.0
		ip.physics.vel_air.x = ip.physics.vel_air.y

		itStarmieNFollowSetStatus(item_gobj)

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x80182270
static func itStarmieCommonProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if B(Itmap.itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_FLOOR)):
		ip.physics.vel_air.y = 0.0

	return FALSE

## 0x801822B0
static func itStarmieMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITStarmieItemDesc, pos, vel, flags)

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

		# itGetMonsterAnimNode(ip, &llITCommonDataStarmieDataStart) == ITCommonObject + 0x13624
		ObjAnim.gcAddDObjAnimJoint(dobj, Itpippi.dITCommonObjectMonsterAnimBank, 0.0)

		# item_gobj->dl_link_priority: itManagerMakeItem registers every item display with GOBJ_PRIORITY_DEFAULT
		Objman.gcMoveGObjDLHead(item_gobj, 18, GOBJ_PRIORITY_DEFAULT)

	return item_gobj

## 0x801823B4
static func itStarmieWeaponSwiftProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	wp.physics.vel_air.x = wp.physics.vel_air.x # Bruh

	if B(Wpmain.wpMainDecLifeCheckExpire(wp)):
		return TRUE

	else:
		return FALSE

## 0x801823E8
static func itStarmieWeaponSwiftProcHit(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	Efmanager.efManagerStarSplashMakeEffect(DObjGetStruct(weapon_gobj).translate, wp.lr)

	return TRUE

## 0x80182418
static func itStarmieWeaponSwiftProcHop(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	wp.physics.vel_air = syVectorRotateAbout3D(wp.physics.vel_air, wp.shield_collide_dir, wp.shield_collide_angle * 2)

	DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x)
	DObjGetStruct(weapon_gobj).scale.x = 1.0

	if wp.physics.vel_air.x > 0.0:
		wp.lr = +1

	else:
		wp.lr = -1

	return FALSE

## 0x801824C0
static func itStarmieWeaponSwiftProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)

	Wpmain.wpMainReflectorSetLR(wp, fp)

	DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x)
	DObjGetStruct(weapon_gobj).scale.x = 1.0

	wp.lr = -wp.lr

	return FALSE

## 0x80182530
static func itStarmieWeaponSwiftMakeWeapon(item_gobj, pos: Vector3):
	var ip := itGetStruct(item_gobj)
	var weapon_gobj = Wpmanager.wpManagerMakeWeapon(item_gobj, _itStarmieGetWeaponSwiftWeaponDesc(), pos, WEAPON_FLAG_PARENT_ITEM)
	var dobj: DObj
	var wp: Weapon

	if weapon_gobj == null:
		return null

	wp = wpGetStruct(weapon_gobj)

	wp.lr = ip.lr

	wp.physics.vel_air.x = wp.lr * ITSTARMIE_SWIFTVEL_X

	dobj = DObjGetStruct(weapon_gobj)

	dobj.translate = pos

	Efmanager.efManagerSparkleWhiteScaleMakeEffect(dobj.translate, 1.0)

	wp.lifetime = ITSTARMIE_SWIFT_LIFETIME

	if wp.lr == +1:
		dobj.rotate.y = F_CST_DTOR32(180.0)

	return weapon_gobj

## 0x80182608
static func itStarmieAttackMakeSwift(item_gobj, pos: Vector3) -> void:
	itStarmieWeaponSwiftMakeWeapon(item_gobj, pos)

# ---------------------------------------------------------------------------------------
# Port helpers
# ---------------------------------------------------------------------------------------

## dITStarmieWeaponSwiftWeaponDesc with lbRelocGetFileData(WPAttributes*, gITManagerCommonData,
## &llITCommonDataStarmieSwiftWeaponAttributes) resolved (item core table).
static func _itStarmieGetWeaponSwiftWeaponDesc() -> Dictionary:
	if dITStarmieWeaponSwiftWeaponDesc.attributes == null:
		dITStarmieWeaponSwiftWeaponDesc.attributes = Itmanager.itManagerGetCommonData("llITCommonDataStarmieSwiftWeaponAttributes")

	return dITStarmieWeaponSwiftWeaponDesc

## dobj->mobj (first MObj of the joint); MObjs are render-only in this port (see Itpippi.gd).
static func _itStarmieGetMObj(dobj: DObj):
	if dobj == null:
		return null
	var mobjs: Array = dobj.get_meta(&"mobjs", [])

	return mobjs[0] if not mobjs.is_empty() else null
