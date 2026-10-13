## Port of src/it/itfighter/itnesspkfire.c (Ness PK Fire pillar item, spawned when the PK Fire spark hits).
class_name Itnesspkfire
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum ITNessPKFireStatus
const nITNessPKFireStatusWait = 0
const nITNessPKFireStatusFall = 1
const nITNessPKFireStatusEnumCount = 2

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## ITAttributes at gFTNessFileSpecial1 + llNessSpecial1PKFireItemAttributes (0x34):
## src/relocData/240_NessSpecial1.c dNessSpecial1_PKFire_ItemAttributes (US values; checked against ROM file 240).
const dNessSpecial1_PKFire_ItemAttributes := {
	"data": null,                       # dNessSpecial3_PKFireDL_DObjDescs (model; not exported)
	"p_mobjsubs": null,
	"anim_joints": null,                # dNessSpecial3_PKFireDL_script_ptrs (visual; not exported)
	"p_matanim_joints": null,
	"is_display_xlu": 1,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,                        # Heavy = 0, Light = 1
	"attack_offset0_x": 0,
	"attack_offset0_y": 100,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 350,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 200, 0),
	"damage_coll_size": Vector3(200, 400, 200),
	"map_coll_top": 400,
	"map_coll_center": 200,
	"map_coll_bottom": 0,
	"map_coll_width": 100,
	"size": 200,
	"angle": 70,
	"knockback_scale": 10,
	"damage": 3,
	"element": 1,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 2,
	"can_setoff": 0,
	"hit_sfx": nSYAudioFGMBurnM,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 1,
	"can_hop": 0,
	"can_reflect": 0,
	"can_shield": 1,
	"knockback_base": 4,
	"type": 6,
	"hitstatus": 1,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

static var dITNessPKFireItemDesc := {
	"kind": nITKindNessPKFire,                                  # Item Kind
	# p_file = &gFTNessFileSpecial1, o_attributes = &llNessSpecial1PKFireItemAttributes
	"attributes": dNessSpecial1_PKFire_ItemAttributes,
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateNew,                          # Hitbox Update State
	"proc_update": Callable(Itnesspkfire, &"itNessPKFireCommonProcUpdate"),
	"proc_map": Callable(),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
	"visual_kind": "ness_pk_fire_pillar",
}

static var dITNessPKFireStatusDescs: Array = [
	# Status 0 (Ground Wait)
	{
		"proc_update": Callable(Itnesspkfire, &"itNessPKFireWaitProcUpdate"),
		"proc_map": Callable(Itnesspkfire, &"itNessPKFireWaitProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(Itnesspkfire, &"itNessPKFireCommonProcDamage"),
	},
	# Status 1 (Air Wait Fall)
	{
		"proc_update": Callable(Itnesspkfire, &"itNessPKFireFallProcUpdate"),
		"proc_map": Callable(Itnesspkfire, &"itNessPKFireFallProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(Itnesspkfire, &"itNessPKFireCommonProcDamage"),
	},
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80185350
static func itNessPKFireCommonProcUpdate(item_gobj) -> int:
	itNessPKFireFallSetStatus(item_gobj)

	return FALSE

## 0x80185374
static func itNessPKFireCommonUpdateAllCheckDestroy(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var attr
	var half: float = 0.5
	var lifetime_scale: float = ((ip.lifetime * half) / 100.0) + half
	var xf = ip.item_vars.pkfire.xf

	DObjGetStruct(item_gobj).scale.z = lifetime_scale
	DObjGetStruct(item_gobj).scale.y = DObjGetStruct(item_gobj).scale.z
	DObjGetStruct(item_gobj).scale.x = DObjGetStruct(item_gobj).scale.y

	attr = ip.attr

	ip.attack_coll.offsets[0].x = attr.attack_offset0_x * lifetime_scale
	ip.attack_coll.offsets[0].y = attr.attack_offset0_y * lifetime_scale
	ip.attack_coll.offsets[0].z = attr.attack_offset0_z * lifetime_scale
	ip.attack_coll.offsets[1].x = attr.attack_offset1_x * lifetime_scale
	ip.attack_coll.offsets[1].y = attr.attack_offset1_y * lifetime_scale
	ip.attack_coll.offsets[1].z = attr.attack_offset1_z * lifetime_scale

	ip.attack_coll.size = attr.size * 0.5 * lifetime_scale

	ip.damage_coll.offset.x = attr.damage_coll_offset.x * lifetime_scale
	ip.damage_coll.offset.y = attr.damage_coll_offset.y * lifetime_scale
	ip.damage_coll.offset.z = attr.damage_coll_offset.z * lifetime_scale
	ip.damage_coll.size.x = attr.damage_coll_size.x * 0.5 * lifetime_scale
	ip.damage_coll.size.y = attr.damage_coll_size.y * 0.5 * lifetime_scale
	ip.damage_coll.size.z = attr.damage_coll_size.z * 0.5 * lifetime_scale

	if xf != null:
		xf.scale.x = DObjGetStruct(item_gobj).scale.x
		xf.scale.y = DObjGetStruct(item_gobj).scale.y
		xf.scale.z = DObjGetStruct(item_gobj).scale.z

		xf.translate = DObjGetStruct(item_gobj).translate

	ip.lifetime -= 1

	if ip.lifetime < 0:
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(item_gobj).translate, 1.0)

		if xf != null:
			Lbparticle.lbParticleEjectStructID(xf.generator_id, 0)

		return TRUE
	else:
		return FALSE

## 0x801855E4
static func itNessPKFireWaitProcUpdate(item_gobj) -> int:
	if itNessPKFireCommonUpdateAllCheckDestroy(item_gobj) == TRUE:
		return TRUE

	return FALSE

## 0x80185614
static func itNessPKFireFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if itNessPKFireCommonUpdateAllCheckDestroy(item_gobj) == TRUE:
		return TRUE
	else:
		Itmain.itMainApplyGravityClampTVel(ip, ITPKFIRE_GRAVITY, ITPKFIRE_TVEL)

	return FALSE

## 0x80185660
static func itNessPKFireWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itnesspkfire, &"itNessPKFireFallSetStatus"))

	return FALSE

## 0x80185688
static func itNessPKFireFallProcMap(item_gobj) -> int:
	Itmap.itMapCheckLanding(item_gobj, ITPKFIRE_MAP_REBOUND_COMMON, ITPKFIRE_MAP_REBOUND_GROUND, Callable(Itnesspkfire, &"itNessPKFireWaitSetStatus"))

	return FALSE

## 0x801856BC
static func itNessPKFireCommonProcDamage(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.lifetime > 0:
		ip.lifetime -= ip.damage_highest * ITPKFIRE_HURT_DAMAGE_MUL

	if itNessPKFireCommonUpdateAllCheckDestroy(item_gobj) == TRUE:
		return TRUE
	else:
		return FALSE

## 0x80185710
static func itNessPKFireWaitSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var stat_flags: GMStatFlags
	var stat_count: int

	Itmap.itMapSetGround(ip)

	ip.physics.vel_ground = 0.0
	ip.physics.vel_air.y = 0.0
	ip.physics.vel_air.x = ip.physics.vel_air.y

	stat_flags = ip.attack_coll.stat_flags.dup() # struct copy
	stat_count = ip.attack_coll.stat_count

	Itmain.itMainSetStatus(item_gobj, dITNessPKFireStatusDescs, nITNessPKFireStatusWait)

	ip.attack_coll.stat_flags = stat_flags
	ip.attack_coll.stat_count = stat_count

## 0x8018579C
static func itNessPKFireFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var stat_flags: GMStatFlags
	var stat_count: int

	Itmap.itMapSetAir(ip)

	ip.physics.vel_air.y = 0.0
	ip.physics.vel_air.x = ip.physics.vel_air.y

	stat_flags = ip.attack_coll.stat_flags.dup() # struct copy
	stat_count = ip.attack_coll.stat_count

	Itmain.itMainSetStatus(item_gobj, dITNessPKFireStatusDescs, nITNessPKFireStatusFall)

	ip.attack_coll.stat_flags = stat_flags
	ip.attack_coll.stat_count = stat_count

## 0x80185824
static func itNessPKFireMakeItem(weapon_gobj, pos: Vector3, vel: Vector3):
	var item_gobj
	var wp := wpGetStruct(weapon_gobj)
	var ip: Item
	var pc
	var xf

	item_gobj = Itmanager.itManagerMakeItem(weapon_gobj, dITNessPKFireItemDesc, pos, vel, (ITEM_FLAG_COLLPROJECT | ITEM_FLAG_PARENT_WEAPON))

	if item_gobj == null:
		return null

	ip = itGetStruct(item_gobj)

	ip.owner_gobj = wp.owner_gobj

	ip.is_allow_pickup = FALSE
	ip.is_hold = FALSE

	ip.team = wp.team
	ip.player = wp.player
	ip.handicap = wp.handicap
	ip.player_num = wp.player_num

	ip.attack_coll.can_rehit_shield = TRUE

	ip.attack_coll.stale = wp.attack_coll.stale
	ip.attack_coll.motion_attack_id = wp.attack_coll.motion_attack_id
	ip.attack_coll.motion_count = wp.attack_coll.motion_count
	ip.attack_coll.stat_flags = wp.attack_coll.stat_flags.dup() # struct copy
	ip.attack_coll.stat_count = wp.attack_coll.stat_count

	Itmap.itMapSetAir(ip)
	Itprocess.itProcessUpdateAttackPositions(item_gobj)

	ip.lifetime = ITPKFIRE_LIFETIME

	pc = Lbparticle.lbParticleMakeScriptID(Ftness.gFTNessParticleBankID, 0)

	if pc != null:
		xf = Lbparticle.lbParticleAddTransformForStruct(pc, nLBTransformStatusDefault)

		if xf != null:
			ip.item_vars.pkfire.xf = xf

			Lbparticle.LBParticleProcessStruct(pc)

			if xf.users_num == 0:
				ip.item_vars.pkfire.xf = null
			else:
				xf.translate = pos
		else:
			Lbparticle.lbParticleEjectStruct(pc)

			ip.item_vars.pkfire.xf = null
	else:
		ip.item_vars.pkfire.xf = null

	return item_gobj
