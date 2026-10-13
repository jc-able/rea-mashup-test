## Port of src/it/itcommon/itrshell.c (Red Shell).
##
## * ITDesc: {p_file = &gITManagerCommonData, o_attributes = &llITCommonDataRShellItemAttributes} is given as
##   the linker symbol name; Itmanager resolves it to its ROM-verified transcription of
##   src/relocData/251_ITCommonData.c dITCommonData_RShell_ItemAttributes (file 251 @ 0x0584; same model as GShell).
## * Integer fields keep their C widths: item_vars.shell.{damage_all_delay, dust_effect_int, health, interact}
##   are u8 (`damage_all_delay != -1` is always TRUE; `interact--` from 0 wraps to 255), shell.vel_x is f32.
## * f32 arithmetic whose result is stored or compared is rounded with Port.f32 (incl. the 0.7F / 1.2F constants).
## * The spin AnimJoint is the shell one (Itgshell.itGShellPortGetShellAnimJoint, ITCommonObject @ 0x6018).
class_name Itrshell
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itRShellStatus
const nITRShellStatusWait = 0
const nITRShellStatusFall = 1
const nITRShellStatusHold = 2
const nITRShellStatusThrown = 3
const nITRShellStatusDropped = 4
const nITRShellStatusSpin = 5
const nITRShellStatusSpinAir = 6
const nITRShellStatusEnumCount = 7

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

static var dITRShellItemDesc := {
	"kind": nITKindRShell,                                      # Item Kind
	"o_attributes": "llITCommonDataRShellItemAttributes",       # p_file = &gITManagerCommonData
	"transform_types": {"tk1": nGCMatrixKindNull, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                          # Hitbox Update State
	"proc_update": Callable(Itrshell, &"itRShellFallProcUpdate"),
	"proc_map": Callable(Itrshell, &"itRShellFallProcMap"),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(Itrshell, &"itRShellCommonProcDamage"),
}

static var dITRShellStatusDescs: Array = [
	# Status 0 (Ground Wait)
	{
		"proc_update": Callable(),
		"proc_map": Callable(Itrshell, &"itRShellWaitProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(Itrshell, &"itRShellCommonProcDamage"),
	},
	# Status 1 (Air Wait Fall)
	{
		"proc_update": Callable(Itrshell, &"itRShellFallProcUpdate"),
		"proc_map": Callable(Itrshell, &"itRShellFallProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
	},
	# Status 2 (Fighter Hold)
	{
		"proc_update": Callable(),
		"proc_map": Callable(),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
	},
	# Status 3 (Fighter Throw)
	{
		"proc_update": Callable(Itrshell, &"itRShellFallProcUpdate"),
		"proc_map": Callable(Itrshell, &"itRShellThrownProcMap"),
		"proc_hit": Callable(Itrshell, &"itRShellCommonProcHit"),
		"proc_shield": Callable(Itrshell, &"itRShellCommonProcShield"),
		"proc_hop": Callable(Itmain, &"itMainCommonProcHop"),
		"proc_setoff": Callable(Itrshell, &"itRShellCommonProcShield"),
		"proc_reflector": Callable(Itrshell, &"itRShellCommonProcReflector"),
		"proc_damage": Callable(Itrshell, &"itRShellCommonProcDamage"),
	},
	# Status 4 (Fighter Drop)
	{
		"proc_update": Callable(Itrshell, &"itRShellFallProcUpdate"),
		"proc_map": Callable(Itrshell, &"itRShellThrownProcMap"),
		"proc_hit": Callable(Itrshell, &"itRShellCommonProcHit"),
		"proc_shield": Callable(Itrshell, &"itRShellCommonProcShield"),
		"proc_hop": Callable(Itmain, &"itMainCommonProcHop"),
		"proc_setoff": Callable(Itrshell, &"itRShellCommonProcShield"),
		"proc_reflector": Callable(Itrshell, &"itRShellCommonProcReflector"),
		"proc_damage": Callable(Itrshell, &"itRShellCommonProcDamage"),
	},
	# Status 5 (Ground Spin)
	{
		"proc_update": Callable(Itrshell, &"itRShellSpinProcUpdate"),
		"proc_map": Callable(Itrshell, &"itRShellSpinProcMap"),
		"proc_hit": Callable(Itrshell, &"itRShellCommonProcHit"),
		"proc_shield": Callable(Itrshell, &"itRShellCommonProcHit"),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(Itrshell, &"itRShellCommonProcReflector"),
		"proc_damage": Callable(Itrshell, &"itRShellSpinProcDamage"),
	},
	# Status 6 (Air Spin)
	{
		"proc_update": Callable(Itrshell, &"itRShellFallProcUpdate"),
		"proc_map": Callable(Itrshell, &"itRShellThrownProcMap"),
		"proc_hit": Callable(Itrshell, &"itRShellCommonProcHit"),
		"proc_shield": Callable(Itrshell, &"itRShellCommonProcHit"),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(Itrshell, &"itRShellCommonProcReflector"),
		"proc_damage": Callable(Itrshell, &"itRShellCommonProcDamage"),
	},
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8017A3A0
static func itRShellSpinUpdateFollowPlayer(item_gobj, fighter_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var vel_x: float
	var dist_x: float
	var lr_vel: int
	var lr_dist: int

	if ip.ga == nMPKineticsGround:
		dist_x = f32(DObjGetStruct(fighter_gobj).translate.x - DObjGetStruct(item_gobj).translate.x)

		lr_dist = -1 if (dist_x < 0.0) else +1

		vel_x = f32(lr_dist * f32(ITRSHELL_MUL_VEL_X))

		ip.item_vars.shell.vel_x = vel_x

		ip.physics.vel_air.x += vel_x

		lr_vel = -1 if (ip.physics.vel_air.x < 0.0) else +1

		lr_dist = -1 if (ip.item_vars.shell.vel_x < 0.0) else +1

		if lr_dist == lr_vel:
			if ABSF(ip.physics.vel_air.x) > ITRSHELL_CLAMP_VEL_X:
				ip.physics.vel_air.x = ip.lr * ITRSHELL_CLAMP_VEL_X
		if ip.attack_coll.attack_state == nGMAttackStateOff:
			if ABSF(ip.physics.vel_air.x) <= ITRSHELL_HIT_INITVEL_X:
				ip.attack_coll.attack_state = nGMAttackStateNew

				Itprocess.itProcessUpdateAttackPositions(item_gobj)
		ip.lr = -1 if (ip.physics.vel_air.x < 0.0) else +1

## 0x8017A534
static func itRShellSpinSearchFollowPlayer(item_gobj) -> void:
	var nearest_gobj = null                   # (uninitialised in C; there is always a fighter)
	var dobj := DObjGetStruct(item_gobj)
	var translate: Vector3 = dobj.translate
	var ft_count: int = 0
	var next_dist: float
	var nearest_dist: float = 0.0
	var dist: Vector3

	for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		dist = DObjGetStruct(fighter_gobj).translate - translate   # syVectorDiff3D(&dist, &fighter translate, translate)

		if ft_count == 0:
			nearest_dist = f32(f32(SQUARE(dist.x)) + f32(SQUARE(dist.y)))
		next_dist = f32(f32(SQUARE(dist.x)) + f32(SQUARE(dist.y)))

		if nearest_dist >= next_dist:
			nearest_dist = next_dist

			nearest_gobj = fighter_gobj
		ft_count += 1

	itRShellSpinUpdateFollowPlayer(item_gobj, nearest_gobj)

## 0x8017A610
static func itRShellSpinUpdateGFX(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	if ip.item_vars.shell.dust_effect_int == 0:
		var pos: Vector3 = dobj.translate

		pos.y += ip.attr.map_coll_bottom

		Efmanager.efManagerDustLightMakeEffect(pos, ip.lr, 1.0)

		ip.item_vars.shell.dust_effect_int = ITRSHELL_EFFECT_SPAWN_INT
	ip.item_vars.shell.dust_effect_int = (ip.item_vars.shell.dust_effect_int - 1) & 0xFF   # u8

## 0x8017A6A0
static func itRShellSpinAddAnim(item_gobj) -> void: # Identical to Green Shell function
	var dobj := DObjGetStruct(item_gobj)

	ObjAnim.gcAddDObjAnimJoint(dobj, Itgshell.itGShellPortGetShellAnimJoint(), 0.0)  # itGetPData(ip, &llITCommonDataShellDataStart, &llITCommonDataShellAnimJoint)
	ObjAnim.gcAddMObjMatAnimJoint(Itmball.itPortGetDObjMObj(dobj), Itgshell.llITCommonDataShellMatAnimJoint, 0.0)
	ObjAnim.gcPlayAnimAll(item_gobj)

## 0x8017A734
static func itRShellCommonClearAnim(item_gobj) -> void:
	Itmball.itPortGetDObjMObj(DObjGetStruct(item_gobj)).anim_pos = -1   # mobj->matanim_joint.event32 = NULL
	DObjGetStruct(item_gobj).anim_pos = -1                               # anim_joint.event32 = NULL

## 0x8017A74C
static func itRShellFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITRSHELL_GRAVITY, ITRSHELL_TVEL)

	if not ip.item_vars.shell.damage_all_delay:
		Itmain.itMainClearOwnerStats(item_gobj)

		ip.item_vars.shell.damage_all_delay = -1 & 0xFF          # u8: 0xFF
	if ip.item_vars.shell.damage_all_delay != -1:                # u8 vs -1: always TRUE (ROM behaviour)
		ip.item_vars.shell.damage_all_delay = (ip.item_vars.shell.damage_all_delay - 1) & 0xFF

	return FALSE

## 0x8017A7C4
static func itRShellWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itrshell, &"itRShellFallSetStatus"))

	return FALSE

## 0x8017A7EC
static func itRShellFallProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.item_vars.shell.health == 0:
		return Itmap.itMapCheckDestroyLanding(item_gobj, ITRSHELL_MAP_REBOUND_COMMON)

	Itmap.itMapCheckDestroyDropped(item_gobj, ITRSHELL_MAP_REBOUND_COMMON, ITRSHELL_MAP_REBOUND_GROUND, Callable(Itrshell, &"itRShellCommonProcStatusWaitOrSpin"))  # return value ignored (C)

	return FALSE

## 0x8017A83C
static func itRShellCommonSetStatusWaitOrSpin(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	Itmap.itMapSetGround(ip)

	if ABSF(ip.physics.vel_air.x) < ITRSHELL_STOP_VEL_X:
		Itmain.itMainSetGroundAllowPickup(item_gobj)

		ip.item_vars.shell.is_damage = FALSE
		ip.physics.vel_air.x = 0.0

		Itmain.itMainClearOwnerStats(item_gobj)

		ip.damage_coll.hitstatus = nGMHitStatusNormal
		ip.attack_coll.attack_state = nGMAttackStateOff

		itRShellCommonClearAnim(item_gobj)
		Itmain.itMainSetStatus(item_gobj, dITRShellStatusDescs, nITRShellStatusWait)

	elif ip.item_vars.shell.is_damage != FALSE:
		ip.attack_coll.attack_state = nGMAttackStateNew

		Itprocess.itProcessUpdateAttackPositions(item_gobj)
		itRShellSpinSetStatus(item_gobj)
	else:
		Itmain.itMainSetGroundAllowPickup(item_gobj)

		ip.physics.vel_air.x = 0.0

		Itmain.itMainClearOwnerStats(item_gobj)

		ip.damage_coll.hitstatus = nGMHitStatusNormal
		ip.attack_coll.attack_state = nGMAttackStateOff

		itRShellCommonClearAnim(item_gobj)
		Itmain.itMainSetStatus(item_gobj, dITRShellStatusDescs, nITRShellStatusWait)

## 0x8017A964
static func itRShellCommonProcStatusWaitOrSpin(item_gobj) -> void:
	itRShellCommonSetStatusWaitOrSpin(item_gobj)

## 0x8017A984
static func itRShellFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	ip.damage_coll.hitstatus = nGMHitStatusNormal

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITRShellStatusDescs, nITRShellStatusFall)

## 0x8017A9D0
static func itRShellCommonProcDamage(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.physics.vel_air.x = ip.damage_queue * ITRSHELL_DAMAGE_MUL_NORMAL * (-ip.damage_lr)

	if ABSF(ip.physics.vel_air.x) > ITRSHELL_STOP_VEL_X:
		ip.item_vars.shell.is_damage = TRUE

		ip.attack_coll.attack_state = nGMAttackStateNew

		Itprocess.itProcessUpdateAttackPositions(item_gobj)
		Itmain.itMainCopyDamageStats(item_gobj)

		if ip.ga != nMPKineticsGround:
			itRShellSpinAirSetStatus(item_gobj)
		else:
			itRShellSpinSetStatus(item_gobj)
	else:
		ip.physics.vel_air.x = 0.0

		ip.attack_coll.attack_state = nGMAttackStateOff

	return FALSE

## 0x8017AABC
static func itRShellHoldSetStatus(item_gobj) -> void:
	DObjGetStruct(item_gobj).rotate.y = F_CST_DTOR32(0.0)

	Itmain.itMainSetStatus(item_gobj, dITRShellStatusDescs, nITRShellStatusHold)

## 0x8017AAF0
static func itRShellThrownSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.item_vars.shell.health = 1
	ip.item_vars.shell.is_damage = TRUE
	ip.item_vars.shell.damage_all_delay = ITRSHELL_DAMAGE_ALL_WAIT

	ip.times_thrown = 0

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITRShellStatusDescs, nITRShellStatusThrown)

## 0x8017AB48
static func itRShellDroppedSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.item_vars.shell.health = 1
	ip.item_vars.shell.is_damage = TRUE
	ip.item_vars.shell.damage_all_delay = ITRSHELL_DAMAGE_ALL_WAIT

	ip.times_thrown = 0

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITRShellStatusDescs, nITRShellStatusDropped)

## 0x8017ABA0
static func itRShellThrownProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if Itmap.itMapCheckLanding(item_gobj, 0.25, 0.5, Callable(Itrshell, &"itRShellSpinSetStatus")) != FALSE:
		if ip.physics.vel_air.x < 0.0:
			ip.lr = -1
		else:
			ip.lr = +1

		ip.physics.vel_air.x = f32(f32((ip.lr * -8.0) + -10.0) * f32(0.7))

	return FALSE

## 0x8017AC40 - 0 = left, 1 = right
static func itRShellSpinEdgeInvertVelLR(item_gobj, lr: int) -> void:
	var ip := itGetStruct(item_gobj)

	ip.physics.vel_air.x = -ip.physics.vel_air.x

	ip.item_vars.shell.vel_x = -ip.item_vars.shell.vel_x

	if lr != 0:
		ip.lr = +1
	else:
		ip.lr = -1

## 0x8017AC84
static func itRShellSpinCheckCollisionEdge(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var attr = ip.attr
	var joint := DObjGetStruct(item_gobj)
	var pos: Vector3

	if Mpcollision.mpCollisionCheckExistLineID(ip.coll_data.floor_line_id) != FALSE:
		if ip.lr == -1:
			pos = Mpcollision.mpCollisionGetFloorEdgeL(ip.coll_data.floor_line_id)

			if pos.x >= f32(joint.translate.x - attr.map_coll_width):
				itRShellSpinEdgeInvertVelLR(item_gobj, 1)
		else:
			pos = Mpcollision.mpCollisionGetFloorEdgeR(ip.coll_data.floor_line_id)

			if pos.x <= f32(joint.translate.x + attr.map_coll_width):
				itRShellSpinEdgeInvertVelLR(item_gobj, 0)

## 0x8017AD7C
static func itRShellSpinProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	itRShellSpinUpdateGFX(item_gobj)
	itRShellSpinSearchFollowPlayer(item_gobj)
	itRShellSpinCheckCollisionEdge(item_gobj)

	if ip.lifetime == 0:
		return TRUE
	else:
		ip.lifetime -= 1

	return FALSE

## 0x8017ADD4
static func itRShellSpinProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if (Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itrshell, &"itRShellSpinAirSetStatus")) != FALSE) and (ip.coll_data.mask_curr & (MAP_FLAG_RWALL | MAP_FLAG_LWALL)):
		ip.physics.vel_air.x = -ip.physics.vel_air.x

		Itmain.itMainSetSpinVelLR(item_gobj)
		Itmain.itMainClearOwnerStats(item_gobj)

		ip.item_vars.shell.vel_x = -ip.item_vars.shell.vel_x

	return FALSE

## 0x8017AE48
static func itRShellCommonProcHit(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.item_vars.shell.interact = (ip.item_vars.shell.interact - 1) & 0xFF   # u8

	if ip.item_vars.shell.interact == 0:
		return TRUE
	ip.damage_coll.hitstatus = nGMHitStatusNormal

	ip.item_vars.shell.health = syUtilsRandIntRange(ITRSHELL_HEALTH_MAX)

	ip.physics.vel_air.x = f32(f32((ip.physics.vel_air.x * -1.0) + (ITRSHELL_RECOIL_VEL_X * ip.hit_lr)) * f32(ITRSHELL_RECOIL_MUL_X))

	itRShellCommonClearAnim(item_gobj)

	if ip.ga != nMPKineticsGround:
		itRShellSpinAirSetStatus(item_gobj)
	else:
		itRShellSpinSetStatus(item_gobj)

	return FALSE

## 0x8017AF18
static func itRShellSpinProcDamage(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.item_vars.shell.interact = (ip.item_vars.shell.interact - 1) & 0xFF   # u8

	if ip.item_vars.shell.interact == 0:
		return TRUE
	ip.physics.vel_air.x += (ip.damage_queue * 2.0) * -ip.damage_lr

	if ABSF(ip.physics.vel_air.x) > ITRSHELL_STOP_VEL_X:
		ip.attack_coll.attack_state = nGMAttackStateNew

		Itprocess.itProcessUpdateAttackPositions(item_gobj)
		Itmain.itMainCopyDamageStats(item_gobj)
		itRShellSpinSetStatus(item_gobj)
	else:
		ip.attack_coll.attack_state = nGMAttackStateOff

	return FALSE

## 0x8017AFEC
static func itRShellSpinInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE
	ip.pickup_wait = ITEM_PICKUP_WAIT_DEFAULT

	if ip.physics.vel_air.x > ITRSHELL_CLAMP_VEL_X:
		ip.physics.vel_air.x = ITRSHELL_CLAMP_VEL_X
	if ip.physics.vel_air.x < -ITRSHELL_CLAMP_VEL_X:
		ip.physics.vel_air.x = -ITRSHELL_CLAMP_VEL_X
	ip.physics.vel_air.y = 0.0

	if ip.physics.vel_air.x < 0.0:
		ip.lr = -1
	else:
		ip.lr = +1

	if ip.item_vars.shell.is_setup_vars == FALSE:
		ip.lifetime = ITRSHELL_LIFETIME

		ip.item_vars.shell.is_setup_vars = TRUE

		ip.item_vars.shell.interact = ITRSHELL_INTERACT_MAX
	ip.item_vars.shell.dust_effect_int = ITRSHELL_EFFECT_SPAWN_INT

	itRShellSpinAddAnim(item_gobj)
	Snd.func_800269C0_275C0(nSYAudioFGMBombHeiWalkStart)
	Itmain.itMainClearOwnerStats(item_gobj)
	Itmap.itMapSetGround(ip)

## 0x8017B0D4
static func itRShellSpinSetStatus(item_gobj) -> void:
	itRShellSpinInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITRShellStatusDescs, nITRShellStatusSpin)

## 0x8017B108
static func itRShellSpinAirInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	if ip.physics.vel_air.x > ITRSHELL_CLAMP_AIR_X:
		ip.physics.vel_air.x = ITRSHELL_CLAMP_AIR_X
	if ip.physics.vel_air.x < -ITRSHELL_CLAMP_AIR_X:
		ip.physics.vel_air.x = -ITRSHELL_CLAMP_AIR_X
	if ip.physics.vel_air.x < 0.0:
		ip.lr = -1
	else:
		ip.lr = +1

	Itmain.itMainClearOwnerStats(item_gobj)
	Itmap.itMapSetAir(ip)

## 0x8017B1A4
static func itRShellSpinAirSetStatus(item_gobj) -> void:
	itRShellSpinAirInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITRShellStatusDescs, nITRShellStatusSpinAir)

## 0x8017B1D8
static func itRShellMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITRShellItemDesc, pos, vel, flags)

	if item_gobj != null:
		var dobj := DObjGetStruct(item_gobj)
		var ip: Item
		var translate: Vector3 = dobj.translate   # REGION_US

		dobj.rotate.y = F_CST_DTOR32(90.0)

		Objman.gcAddXObjForDObjFixed(dobj, nGCMatrixKindTraRotRpyR, 0)
		Objman.gcAddXObjForDObjFixed(dobj, 0x48, 0)

		dobj.translate = translate                # REGION_US

		Itmball.itPortGetDObjMObj(dobj).palette_id = 0.0

		ip = itGetStruct(item_gobj)

		ip.attack_coll.can_rehit_shield = TRUE

		ip.item_vars.shell.health = 1
		ip.item_vars.shell.is_setup_vars = FALSE
		ip.item_vars.shell.is_damage = FALSE
		ip.item_vars.shell.damage_all_delay = -1 & 0xFF   # u8: 0xFF
		ip.item_vars.shell.vel_x = 0.0

		ip.is_unused_item_bool = TRUE

		ip.arrow_gobj = Ifcommon.ifCommonItemArrowMakeInterface(ip)

	return item_gobj

## 0x8017B2F8
static func itRShellCommonProcShield(item_gobj) -> int:
	Itmain.itMainVelSetRebound(item_gobj)

	return FALSE

## 0x8017B31C
static func itRShellCommonProcReflector(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var item_dobj := DObjGetStruct(item_gobj)
	var fighter_dobj := DObjGetStruct(ip.owner_gobj)

	ip.item_vars.shell.interact = (ip.item_vars.shell.interact - 1) & 0xFF   # u8

	if ip.item_vars.shell.interact == 0:
		return TRUE

	if item_dobj.translate.x < fighter_dobj.translate.x:
		ip.lr = -1

		if ip.physics.vel_air.x >= 0.0:
			ip.physics.vel_air.x = -ip.physics.vel_air.x
			ip.item_vars.shell.vel_x = -ip.item_vars.shell.vel_x
	else:
		ip.lr = +1

		if ip.physics.vel_air.x < 0.0:
			ip.physics.vel_air.x = -ip.physics.vel_air.x
			ip.item_vars.shell.vel_x = -ip.item_vars.shell.vel_x
	ip.physics.vel_air.x += (ITRSHELL_ADD_VEL_X * ip.lr)

	Itmain.itMainClearOwnerStats(item_gobj)

	return FALSE
