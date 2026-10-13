## Port of src/it/itcommon/itgshell.c (Green Shell).
##
## * ITDesc: {p_file = &gITManagerCommonData, o_attributes = &llITCommonDataGShellItemAttributes} is given as
##   the linker symbol name; Itmanager resolves it to its ROM-verified transcription of
##   src/relocData/251_ITCommonData.c dITCommonData_GShell_ItemAttributes (file 251 @ 0x053C).
## * Integer fields keep their C widths: item_vars.shell.{damage_all_delay, dust_effect_int, health, interact}
##   are u8 (so `damage_all_delay != -1` is always TRUE, as in the ROM), ip->multi is u16.
## * The shell spin AnimJoint (ITCommonObject @ 0x6018) is attached for real (rotates the root joint);
##   material animations / palettes are render-only (MObj stand-in: Itmball.itPortGetDObjMObj).
class_name Itgshell
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itGShellStatus
const nITGShellStatusWait = 0
const nITGShellStatusFall = 1
const nITGShellStatusHold = 2
const nITGShellStatusThrown = 3
const nITGShellStatusDropped = 4
const nITGShellStatusSpin = 5
const nITGShellStatusSpinAir = 6
const nITGShellStatusEnumCount = 7

# // // // // // // // // // // // //
# //      RELOC DATA (US ROM)      //
# // // // // // // // // // // // //

## itGetPData(ip, &llITCommonDataShellDataStart, &llITCommonDataShellAnimJoint): ITCommonObject (file 86) @ 0x6018,
## src/relocData/86_ITCommonObject.c dITCommonObject_GShell_Item_data_remainder_gap_0x600C_sub_0xC (ROM-checked):
##   SetValAfterBlock(ROTY, 0) 0.0f; SetValAfter(ROTY, 6) PI; Wait(12); SetAnim(0, 0) -> itself; End
const dITCommonObject_Shell_AnimJointWords: Array = [0x14010000, 0x00000000, 0x16010006, 0x40490FDB, 0x0400000C, 0x1C000000, 0x00000000, 0x00000000]

## itGetPData(ip, &llITCommonDataShellDataStart, &llITCommonDataShellMatAnimJoint): file 86 @ 0x6048 (render-only marker)
const llITCommonDataShellMatAnimJoint := {"file": 86, "offset": 0x6048, "name": "ShellMatAnimJoint"}

static var _shell_anim_joint: AnimStream = null

## Port-only: the shell AnimJoint as an AnimStream (shared with Itrshell, same ROM address).
static func itGShellPortGetShellAnimJoint() -> AnimStream:
	if _shell_anim_joint == null:
		_shell_anim_joint = AnimStream.from_u32(dITCommonObject_Shell_AnimJointWords, "ITCommonObject_Shell_AnimJoint")
		_shell_anim_joint.ptr[6] = [_shell_anim_joint, 0]  # SetAnim target: the script itself (0x6018)
	return _shell_anim_joint

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

static var dITGShellItemDesc := {
	"kind": nITKindGShell,                                      # Item Kind
	"o_attributes": "llITCommonDataGShellItemAttributes",       # p_file = &gITManagerCommonData
	"transform_types": {"tk1": nGCMatrixKindNull, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                          # Hitbox Update State
	"proc_update": Callable(Itgshell, &"itGShellFallProcUpdate"),
	"proc_map": Callable(Itgshell, &"itGShellFallProcMap"),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
}

static var dITGShellStatusDescs: Array = [
	# Status 0 (Ground Wait)
	{
		"proc_update": Callable(),
		"proc_map": Callable(Itgshell, &"itGShellWaitProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(Itgshell, &"itGShellCommonProcDamage"),
	},
	# Status 1 (Air Wait Fall)
	{
		"proc_update": Callable(Itgshell, &"itGShellFallProcUpdate"),
		"proc_map": Callable(Itgshell, &"itGShellFallProcMap"),
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
		"proc_update": Callable(Itgshell, &"itGShellThrownProcUpdate"),
		"proc_map": Callable(Itgshell, &"itGShellThrownProcMap"),
		"proc_hit": Callable(Itgshell, &"itGShellCommonProcHit"),
		"proc_shield": Callable(Itgshell, &"itGShellCommonProcShield"),
		"proc_hop": Callable(Itmain, &"itMainCommonProcHop"),
		"proc_setoff": Callable(Itgshell, &"itGShellCommonProcShield"),
		"proc_reflector": Callable(Itmain, &"itMainCommonProcReflector"),
		"proc_damage": Callable(Itgshell, &"itGShellCommonProcDamage"),
	},
	# Status 4 (Fighter Drop)
	{
		"proc_update": Callable(Itgshell, &"itGShellFallProcUpdate"),
		"proc_map": Callable(Itgshell, &"itGShellThrownProcMap"),
		"proc_hit": Callable(Itgshell, &"itGShellCommonProcHit"),
		"proc_shield": Callable(Itgshell, &"itGShellCommonProcShield"),
		"proc_hop": Callable(Itmain, &"itMainCommonProcHop"),
		"proc_setoff": Callable(Itgshell, &"itGShellCommonProcShield"),
		"proc_reflector": Callable(Itmain, &"itMainCommonProcReflector"),
		"proc_damage": Callable(Itgshell, &"itGShellCommonProcDamage"),
	},
	# Status 5 (Ground Spin)
	{
		"proc_update": Callable(Itgshell, &"itGShellSpinProcUpdate"),
		"proc_map": Callable(Itgshell, &"itGShellSpinProcMap"),
		"proc_hit": Callable(Itgshell, &"itGShellCommonProcHit"),
		"proc_shield": Callable(Itgshell, &"itGShellCommonProcHit"),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(Itmain, &"itMainCommonProcReflector"),
		"proc_damage": Callable(Itgshell, &"itGShellSpinProcDamage"),
	},
	# Status 6 (Air Spin)
	{
		"proc_update": Callable(Itgshell, &"itGShellFallProcUpdate"),
		"proc_map": Callable(Itgshell, &"itGShellThrownProcMap"),
		"proc_hit": Callable(Itgshell, &"itGShellCommonProcHit"),
		"proc_shield": Callable(Itgshell, &"itGShellCommonProcHit"),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(Itmain, &"itMainCommonProcReflector"),
		"proc_damage": Callable(Itgshell, &"itGShellSpinProcDamage"),
	},
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801785E0
static func itGShellSpinUpdateEffect(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)
	var pos: Vector3

	if ip.item_vars.shell.dust_effect_int == 0:
		pos = dobj.translate

		pos.y += ip.attr.map_coll_bottom

		Efmanager.efManagerDustLightMakeEffect(pos, ip.lr, 1.0)

		ip.item_vars.shell.dust_effect_int = ITGSHELL_EFFECT_SPAWN_INT
	ip.item_vars.shell.dust_effect_int = (ip.item_vars.shell.dust_effect_int - 1) & 0xFF   # u8

## 0x80178670
static func itGShellSpinAddAnim(item_gobj) -> void:
	var dobj := DObjGetStruct(item_gobj)

	ObjAnim.gcAddDObjAnimJoint(dobj, itGShellPortGetShellAnimJoint(), 0.0)  # itGetPData(ip, &llITCommonDataShellDataStart, &llITCommonDataShellAnimJoint)
	ObjAnim.gcAddMObjMatAnimJoint(Itmball.itPortGetDObjMObj(dobj), llITCommonDataShellMatAnimJoint, 0.0)
	ObjAnim.gcPlayAnimAll(item_gobj)

## 0x80178704
static func itGShellCommonClearAnim(item_gobj) -> void:
	Itmball.itPortGetDObjMObj(DObjGetStruct(item_gobj)).anim_pos = -1   # mobj->matanim_joint.event32 = NULL
	DObjGetStruct(item_gobj).anim_pos = -1                               # anim_joint.event32 = NULL

## 0x8017871C
static func itGShellFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITGSHELL_GRAVITY, ITGSHELL_TVEL)

	return FALSE

## 0x8017874C
static func itGShellWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itgshell, &"itGShellFallSetStatus"))

	return FALSE

## 0x80178774
static func itGShellFallProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.item_vars.shell.health == 0:
		return Itmap.itMapCheckDestroyLanding(item_gobj, ITGSHELL_MAP_REBOUND_COMMON)
	else:
		Itmap.itMapCheckDestroyDropped(item_gobj, ITGSHELL_MAP_REBOUND_COMMON, ITGSHELL_MAP_REBOUND_GROUND, Callable(Itgshell, &"itGShellWaitSetStatus"))  # return value ignored (C)

	return FALSE

## 0x801787CC
static func itGShellWaitInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	Itmap.itMapSetGround(ip)

	if ABSF(ip.physics.vel_air.x) < ITGSHELL_STOP_VEL_X:
		Itmain.itMainSetGroundAllowPickup(item_gobj)

		ip.item_vars.shell.is_damage = FALSE

		ip.is_damage_all = TRUE

		ip.damage_coll.hitstatus = nGMHitStatusNormal
		ip.attack_coll.attack_state = nGMAttackStateOff

		ip.physics.vel_air.x = 0.0

		itGShellCommonClearAnim(item_gobj)
		Itmain.itMainSetStatus(item_gobj, dITGShellStatusDescs, nITGShellStatusWait)

	elif ip.item_vars.shell.is_damage != FALSE:
		ip.attack_coll.attack_state = nGMAttackStateNew

		Itprocess.itProcessUpdateAttackPositions(item_gobj)
		itGShellSpinSetStatus(item_gobj)
	else:
		Itmain.itMainSetGroundAllowPickup(item_gobj)

		ip.is_damage_all = TRUE

		ip.damage_coll.hitstatus = nGMHitStatusNormal
		ip.attack_coll.attack_state = nGMAttackStateOff

		ip.physics.vel_air.x = 0.0

		itGShellCommonClearAnim(item_gobj)
		Itmain.itMainSetStatus(item_gobj, dITGShellStatusDescs, nITGShellStatusWait)

## 0x80178910
static func itGShellWaitSetStatus(item_gobj) -> void:
	itGShellWaitInitVars(item_gobj)

## 0x80178930
static func itGShellFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.damage_coll.hitstatus = nGMHitStatusNone

	ip.attack_coll.attack_state = nGMAttackStateOff

	ip.is_allow_pickup = FALSE

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITGShellStatusDescs, nITGShellStatusFall)

## 0x8017897C
static func itGShellCommonProcDamage(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.physics.vel_air.x = (ip.damage_queue * ITGSHELL_DAMAGE_MUL_NORMAL * -ip.damage_lr)

	if ABSF(ip.physics.vel_air.x) > ITGSHELL_STOP_VEL_X:
		ip.item_vars.shell.is_damage = TRUE

		ip.attack_coll.attack_state = nGMAttackStateNew

		Itprocess.itProcessUpdateAttackPositions(item_gobj)

		ip.damage_coll.hitstatus = nGMHitStatusNone

		Itmain.itMainCopyDamageStats(item_gobj)

		if ip.ga != nMPKineticsGround:
			itGShellSpinAirSetStatus(item_gobj)
		else:
			itGShellSpinSetStatus(item_gobj)
	else:
		ip.physics.vel_air.x = 0.0

		if ip.ga != nMPKineticsGround:
			itGShellFallSetStatus(item_gobj)
		else:
			itGShellWaitSetStatus(item_gobj)

	return FALSE

## 0x80178A90
static func itGShellHoldSetStatus(item_gobj) -> void:
	DObjGetStruct(item_gobj).rotate.y = 0.0

	Itmain.itMainSetStatus(item_gobj, dITGShellStatusDescs, nITGShellStatusHold)

## 0x80178AC4
static func itGShellThrownProcMap(item_gobj) -> int:
	Itmap.itMapCheckLanding(item_gobj, ITGSHELL_MAP_REBOUND_COMMON, ITGSHELL_MAP_REBOUND_GROUND, Callable(Itgshell, &"itGShellWaitSetStatus"))

	return FALSE

## 0x80178AF8
static func itGShellThrownProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITGSHELL_GRAVITY, ITGSHELL_TVEL)

	return FALSE

## 0x80178B28
static func itGShellThrownSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.item_vars.shell.health = 1
	ip.item_vars.shell.is_damage = TRUE

	Itmain.itMainSetStatus(item_gobj, dITGShellStatusDescs, nITGShellStatusThrown)

## 0x80178B60
static func itGShellDroppedSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.item_vars.shell.health = 1
	ip.item_vars.shell.is_damage = TRUE

	Itmain.itMainSetStatus(item_gobj, dITGShellStatusDescs, nITGShellStatusDropped)

## 0x80178B98
static func itGShellSpinProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	itGShellSpinUpdateEffect(item_gobj)

	if not ip.item_vars.shell.damage_all_delay:
		ip.is_damage_all = TRUE

		ip.item_vars.shell.damage_all_delay = -1 & 0xFF          # u8: 0xFF
	if ip.item_vars.shell.damage_all_delay != -1:                # u8 vs -1: always TRUE (ROM behaviour)
		ip.item_vars.shell.damage_all_delay = (ip.item_vars.shell.damage_all_delay - 1) & 0xFF

	if ip.lifetime == 0:
		return TRUE
	else:
		ip.lifetime -= 1

	return FALSE

## 0x80178C10
static func itGShellSpinProcMap(item_gobj) -> int:
	# OVERSIGHT (?): This sets the state of the shell to "Fall" when transitioning from the grounded spinning state,
	# causing the shell's hitbox to deactivate when flying off platforms.
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Itgshell, &"itGShellFallSetStatus"))

	if Itmap.itMapCheckCollideAllRebound(item_gobj, (MAP_FLAG_CEIL | MAP_FLAG_RWALL | MAP_FLAG_LWALL), 0.2).ret != FALSE:
		Itmain.itMainSetSpinVelLR(item_gobj)
		Itmain.itMainClearOwnerStats(item_gobj)

	return FALSE

## 0x80178C6C
static func itGShellCommonProcHit(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.damage_coll.hitstatus = nGMHitStatusNormal

	ip.item_vars.shell.health = syUtilsRandIntRange(ITGSHELL_HEALTH_MAX)

	ip.physics.vel_air.y = ITGSHELL_REBOUND_VEL_Y

	ip.physics.vel_air.x = syUtilsRandFloat() * (-ip.physics.vel_air.x * ITGSHELL_REBOUND_MUL_X)

	Itmain.itMainClearOwnerStats(item_gobj)
	itGShellCommonClearAnim(item_gobj)
	itGShellFallSetStatus(item_gobj)

	return FALSE

## 0x80178CF8
static func itGShellSpinProcDamage(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.physics.vel_air.x += (ip.damage_queue * ITGSHELL_DAMAGE_MUL_ADD * -ip.damage_lr)

	if ABSF(ip.physics.vel_air.x) > ITGSHELL_STOP_VEL_X:
		ip.attack_coll.attack_state = nGMAttackStateNew

		Itprocess.itProcessUpdateAttackPositions(item_gobj)
		Itmain.itMainCopyDamageStats(item_gobj)

		if ip.ga != nMPKineticsGround:
			itGShellSpinAirSetStatus(item_gobj)
		else:
			itGShellSpinSetStatus(item_gobj)
	else:
		ip.physics.vel_air.x = 0.0

		if ip.ga != nMPKineticsGround:
			itGShellFallSetStatus(item_gobj)
		else:
			itGShellWaitSetStatus(item_gobj)

	return FALSE

## 0x80178E04
static func itGShellSpinInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	ip.pickup_wait = ITEM_PICKUP_WAIT_DEFAULT

	if ip.physics.vel_air.x > ITGSHELL_CLAMP_VEL_X:
		ip.physics.vel_air.x = ITGSHELL_CLAMP_VEL_X
	if ip.physics.vel_air.x < -ITGSHELL_CLAMP_VEL_X:
		ip.physics.vel_air.x = -ITGSHELL_CLAMP_VEL_X
	ip.physics.vel_air.y = 0.0

	if ip.physics.vel_air.x < 0.0:
		ip.lr = -1
	else:
		ip.lr = +1

	ip.item_vars.shell.dust_effect_int = ITGSHELL_EFFECT_SPAWN_INT
	ip.item_vars.shell.damage_all_delay = ITGSHELL_DAMAGE_ALL_WAIT

	itGShellSpinAddAnim(item_gobj)

	ip.is_damage_all = FALSE

	Itmain.itMainRefreshAttackColl(item_gobj)
	Snd.func_800269C0_275C0(nSYAudioFGMBombHeiWalkStart)

## 0x80178EDC
static func itGShellSpinSetStatus(item_gobj) -> void:
	itGShellSpinInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITGShellStatusDescs, nITGShellStatusSpin)

## 0x80178F10
static func itGShellSpinAirInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	if ip.physics.vel_air.x > ITGSHELL_CLAMP_VEL_X:
		ip.physics.vel_air.x = ITGSHELL_CLAMP_VEL_X
	if ip.physics.vel_air.x < -ITGSHELL_CLAMP_VEL_X:
		ip.physics.vel_air.x = -ITGSHELL_CLAMP_VEL_X
	if ip.physics.vel_air.x < 0.0:
		ip.lr = -1
	else:
		ip.lr = +1

	ip.is_damage_all = FALSE

	Itmain.itMainRefreshAttackColl(item_gobj)

## 0x80178FA8
static func itGShellSpinAirSetStatus(item_gobj) -> void:
	itGShellSpinAirInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITGShellStatusDescs, nITGShellStatusSpinAir)

## 0x80178FDC
static func itGShellMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITGShellItemDesc, pos, vel, flags)

	if item_gobj != null:
		var dobj := DObjGetStruct(item_gobj)
		var ip: Item
		var translate: Vector3 = dobj.translate   # REGION_US

		dobj.rotate.y = F_CST_DTOR32(90.0)

		Objman.gcAddXObjForDObjFixed(dobj, nGCMatrixKindTraRotRpyR, 0)
		Objman.gcAddXObjForDObjFixed(dobj, 0x48, 0)

		dobj.translate = translate                # REGION_US

		Itmball.itPortGetDObjMObj(dobj).palette_id = 1.0

		ip = itGetStruct(item_gobj)

		ip.attack_coll.can_rehit_shield = TRUE

		ip.item_vars.shell.health = 1
		ip.item_vars.shell.is_damage = FALSE

		ip.is_unused_item_bool = TRUE

		ip.arrow_gobj = Ifcommon.ifCommonItemArrowMakeInterface(ip)

		ip.lifetime = ITGSHELL_LIFETIME

	return item_gobj

## 0x801790F4
static func itGShellCommonProcShield(item_gobj) -> int:
	Itmain.itMainVelSetRebound(item_gobj)

	return FALSE
