## 1:1 port of src/it/itcommon/ittaru.c (ssb-decomp-re): Barrel (Taru) container item - thrown barrels
## land and roll, smash against walls and explode when they do not contain an item.
##
## Data conventions: see Itbox (ITDesc / ITStatusDesc Dictionaries with the C field names; the ITAttributes,
## DObjDesc tree and attack events come from the ITCommonData tables in Itmanager.gd). The smash pieces are
## made by Itbox.itBoxContainerSmashMakeEffect exactly like the C code.
##
## Cross-module conventions assumed: Itmap.itMapCheckCollideAllRebound(item_gobj, check_flags, mod_vel)
## returns {"ret": sb32, "pos": Vec3f} (C passes pos = NULL here, only "ret" is used; a plain int return
## is tolerated by _ret()); Lbcommon.lbCommonReflect2D(a, b) returns the reflected a.
class_name Ittaru
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itTaruStatus
const nITTaruStatusWait = 0
const nITTaruStatusFall = 1
const nITTaruStatusHold = 2
const nITTaruStatusThrown = 3
const nITTaruStatusDropped = 4
const nITTaruStatusExplode = 5
const nITTaruStatusRoll = 6
const nITTaruStatusEnumCount = 7

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

static var dITTaruItemDesc := {
	"kind": nITKindTaru,                                      # Item Kind
	"p_file": "gITManagerCommonData",                       # Pointer to item file data?
	"o_attributes": "llITCommonDataTaruItemAttributes",      # Offset of item attributes in file? (src/relocData/251_ITCommonData.c, resolved by Itmanager)
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyR, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                        # Hitbox Update State
	"proc_update": Callable(Ittaru, &"itTaruFallProcUpdate"),
	"proc_map": Callable(Ittaru, &"itTaruFallProcMap"),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
	"visual_kind": "taru",
}

static var dITTaruStatusDescs: Array = [
	# Status 0 (Ground Wait)
	{
		"proc_update": Callable(),
		"proc_map": Callable(Ittaru, &"itTaruWaitProcMap"),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(Ittaru, &"itTaruCommonProcDamage"),
	},
	# Status 1 (Air Wait Fall)
	{
		"proc_update": Callable(Ittaru, &"itTaruFallProcUpdate"),
		"proc_map": Callable(Ittaru, &"itTaruFallProcMap"),
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
		"proc_update": Callable(Ittaru, &"itTaruFallProcUpdate"),
		"proc_map": Callable(Ittaru, &"itTaruThrownProcMap"),
		"proc_hit": Callable(Ittaru, &"itTaruCommonProcHit"),
		"proc_shield": Callable(Ittaru, &"itTaruCommonProcHit"),
		"proc_hop": Callable(),
		"proc_setoff": Callable(Ittaru, &"itTaruCommonProcHit"),
		"proc_reflector": Callable(Ittaru, &"itTaruCommonProcHit"),
		"proc_damage": Callable(Ittaru, &"itTaruCommonProcDamage"),
	},
	# Status 4 (Fighter Drop)
	{
		"proc_update": Callable(Ittaru, &"itTaruFallProcUpdate"),
		"proc_map": Callable(Ittaru, &"itTaruThrownProcMap"),
		"proc_hit": Callable(Ittaru, &"itTaruCommonProcHit"),
		"proc_shield": Callable(Ittaru, &"itTaruCommonProcHit"),
		"proc_hop": Callable(),
		"proc_setoff": Callable(Ittaru, &"itTaruCommonProcHit"),
		"proc_reflector": Callable(Ittaru, &"itTaruCommonProcHit"),
		"proc_damage": Callable(Ittaru, &"itTaruCommonProcDamage"),
	},
	# Status 5 (Neutral Explosion)
	{
		"proc_update": Callable(Ittaru, &"itTaruExplodeProcUpdate"),
		"proc_map": Callable(),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
	},
	# Status 6 (Ground Roll)
	{
		"proc_update": Callable(Ittaru, &"itTaruRollProcUpdate"),
		"proc_map": Callable(Ittaru, &"itTaruRollProcMap"),
		"proc_hit": Callable(Ittaru, &"itTaruCommonProcHit"),
		"proc_shield": Callable(Ittaru, &"itTaruCommonProcHit"),
		"proc_hop": Callable(),
		"proc_setoff": Callable(Ittaru, &"itTaruCommonProcHit"),
		"proc_reflector": Callable(Ittaru, &"itTaruCommonProcHit"),
		"proc_damage": Callable(Ittaru, &"itTaruCommonProcDamage"),
	},
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80179BA0
static func itTaruFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITTARU_GRAVITY, ITTARU_TVEL)

	DObjGetStruct(item_gobj).rotate.z += ip.item_vars.taru.roll_rotate_step

	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x80179BF8
static func itTaruWaitProcMap(item_gobj) -> int:
	Itmap.itMapCheckLRWallProcNoFloor(item_gobj, Callable(Ittaru, &"itTaruFallSetStatus"))

	return FALSE

## 0x80179C20
static func itTaruCommonProcHit(item_gobj) -> int:
	Snd.func_800269C0_275C0(nSYAudioFGMContainerSmash)

	Itbox.itBoxContainerSmashMakeEffect(DObjGetStruct(item_gobj).translate)

	if B(Itmain.itMainMakeContainerItem(item_gobj)):
		return TRUE
	else:
		itTaruExplodeMakeEffectGotoSetStatus(item_gobj)

	return FALSE

## 0x80179C78
static func itTaruCommonProcDamage(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.percent_damage >= ITTARU_HEALTH_MAX:
		return itTaruCommonProcHit(item_gobj)
	else:
		return FALSE

## 0x80179CB8
static func itTaruFallProcMap(item_gobj) -> int:
	return Itmap.itMapCheckDestroyDropped(item_gobj, ITTARU_MAP_REBOUND_COMMON, ITTARU_MAP_REBOUND_GROUND, Callable(Ittaru, &"itTaruWaitSetStatus"))

## 0x80179CE8
static func itTaruWaitSetStatus(item_gobj) -> void:
	Itmain.itMainSetGroundAllowPickup(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITTaruStatusDescs, nITTaruStatusWait)

## 0x80179D1C
static func itTaruFallSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_allow_pickup = FALSE

	Itmap.itMapSetAir(ip)
	Itmain.itMainSetStatus(item_gobj, dITTaruStatusDescs, nITTaruStatusFall)

## 0x80179D60
static func itTaruHoldSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITTaruStatusDescs, nITTaruStatusHold)

## 0x80179D88
static func itTaruThrownCheckMapCollision(item_gobj, common_rebound: float) -> int:
	var is_collide_floor: int = Itmap.itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_FLOOR)

	# C passes NULL for the pos output.
	if _ret(Itmap.itMapCheckCollideAllRebound(item_gobj, (MAP_FLAG_CEIL | MAP_FLAG_RWALL | MAP_FLAG_LWALL), common_rebound)) != FALSE:
		Itmain.itMainSetSpinVelLR(item_gobj)

	if is_collide_floor != FALSE:
		return TRUE
	else:
		return FALSE

## 0x80179DEC
static func itTaruRollSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.lifetime = ITTARU_LIFETIME

	ip.physics.vel_air.y = 0.0

	Itmain.itMainSetStatus(item_gobj, dITTaruStatusDescs, nITTaruStatusRoll)

## 0x80179E28
static func itTaruThrownProcMap(item_gobj) -> int:
	if itTaruThrownCheckMapCollision(item_gobj, 0.5) != FALSE:
		var ip := itGetStruct(item_gobj)

		if ip.physics.vel_air.y >= 90.0:           # Is it even possible to meet this condition? Didn't they mean ABSF(ip->physics.vel_air.y)?
			itTaruCommonProcHit(item_gobj)         # This causes the barrel to smash on impact when landing from too high; doesn't seem possible to trigger

			return TRUE
		elif ip.physics.vel_air.y < 30.0:
			itTaruRollSetStatus(item_gobj)
		else:
			ip.physics.vel_air = Lbcommon.lbCommonReflect2D(ip.physics.vel_air, ip.coll_data.floor_angle)

			ip.physics.vel_air.y *= 0.2

			Itmain.itMainSetSpinVelLR(item_gobj)

		Itmain.itMainClearOwnerStats(item_gobj)

	return FALSE

## 0x80179EF0
static func itTaruThrownInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	DObjGetStruct(item_gobj).child.rotate.x = F_CST_DTOR32(90.0)

	ip.coll_data.map_coll.top = ip.coll_data.map_coll.width
	ip.coll_data.map_coll.bottom = -ip.coll_data.map_coll.width

## 0x80179F1C
static func itTaruThrownSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITTaruStatusDescs, nITTaruStatusThrown)
	itTaruThrownInitVars(item_gobj)

## 0x80179F50 - Unused
static func func_ovl3_80179F50(item_gobj) -> int:
	Itmain.itMainVelSetRebound(item_gobj)

	return FALSE

## 0x80179F74
static func itTaruDroppedSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITTaruStatusDescs, nITTaruStatusDropped)
	itTaruThrownInitVars(item_gobj)

## 0x80179FA8
static func itTaruExplodeProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.multi = (ip.multi + 1) & 0xFFFF # u16

	if ip.multi == ITTARU_EXPLODE_LIFETIME:
		return TRUE
	else:
		# itGetAttackEvent(dITTaruItemDesc, &llITCommonDataTaruAttackEvents)
		Itmain.itMainUpdateAttackEvent(item_gobj, Itmanager.itManagerGetCommonData(&"llITCommonDataTaruAttackEvents"))

	return FALSE

## 0x8017A004
static func itTaruRollProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var roll_rotate_step: float
	var sqrt_vel: float

	ip.physics.vel_air.x += (-(syUtilsArcTan2(ip.coll_data.floor_angle.y, ip.coll_data.floor_angle.x) - _F_CLC_DTOR32_f32(90.0)) * ITTARU_MUL_VEL_X)

	ip.lr = +1 if (ip.physics.vel_air.x >= 0.0) else -1

	sqrt_vel = sqrtf(SQUARE(ip.physics.vel_air.x) + SQUARE(ip.physics.vel_air.y))

	if sqrt_vel < ITTARU_VEL_MIN:
		ip.lifetime -= 1

		if ip.lifetime < ITTARU_DESPAWN_FLASH_START:
			if ip.lifetime == 0:
				return TRUE
			elif (ip.lifetime % 2) != 0:
				DObjGetStruct(item_gobj).flags ^= DOBJ_FLAG_HIDDEN

	roll_rotate_step = (ITTARU_ROLL_ROTATE_MUL if (ip.lr == -1) else -ITTARU_ROLL_ROTATE_MUL) * sqrt_vel

	ip.item_vars.taru.roll_rotate_step = roll_rotate_step

	DObjGetStruct(item_gobj).rotate.z += roll_rotate_step

	return FALSE

## 0x8017A148
static func itTaruRollProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if not B(Itmap.itMapTestLRWallCheckFloor(item_gobj)):
		Itmain.itMainSetStatus(item_gobj, dITTaruStatusDescs, nITTaruStatusDropped)
	elif ip.coll_data.mask_curr & (MAP_FLAG_RWALL | MAP_FLAG_LWALL):
		return itTaruCommonProcHit(item_gobj)

	return FALSE

## 0x8017A1B8
static func itTaruMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITTaruItemDesc, pos, vel, flags)

	if item_gobj != null:
		var ip := itGetStruct(item_gobj)

		ip.item_vars.taru.roll_rotate_step = 0.0

		ip.is_damage_all = TRUE

		ip.is_unused_item_bool = TRUE

		ip.arrow_gobj = Ifcommon.ifCommonItemArrowMakeInterface(ip)

	return item_gobj

## 0x8017A240
static func itTaruExplodeInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.multi = 0
	ip.event_id = 0

	ip.attack_coll.fgm_id = nSYAudioFGMExplodeL

	ip.attack_coll.can_rehit_item = TRUE
	ip.attack_coll.can_reflect = FALSE

	ip.attack_coll.throw_mul = ITEM_THROW_DEFAULT
	ip.attack_coll.element = nGMHitElementFire

	ip.attack_coll.can_setoff = FALSE

	ip.damage_coll.hitstatus = nGMHitStatusNone

	Itmain.itMainClearOwnerStats(item_gobj)
	Itmain.itMainRefreshAttackColl(item_gobj)
	Itmain.itMainUpdateAttackEvent(item_gobj, Itmanager.itManagerGetCommonData(&"llITCommonDataTaruAttackEvents"))

## 0x8017A2D8
static func itTaruExplodeSetStatus(item_gobj) -> void:
	itTaruExplodeInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITTaruStatusDescs, nITTaruStatusExplode)

## 0x8017A30C
static func itTaruExplodeMakeEffectGotoSetStatus(item_gobj) -> void:
	var pc
	var ip := itGetStruct(item_gobj)
	var dobj: DObj = DObjGetStruct(item_gobj)

	ip.attack_coll.attack_state = nGMAttackStateOff

	ip.physics.vel_air.x = 0.0
	ip.physics.vel_air.y = 0.0
	ip.physics.vel_air.z = 0.0

	pc = Efmanager.efManagerSparkleWhiteMultiExplodeMakeEffect(dobj.translate)

	if pc != null:
		pc.xf.scale.z = ITTARU_EXPLODE_SCALE
		pc.xf.scale.y = ITTARU_EXPLODE_SCALE
		pc.xf.scale.x = ITTARU_EXPLODE_SCALE

	Efmanager.efManagerQuakeMakeEffect(1)

	DObjGetStruct(item_gobj).flags = DOBJ_FLAG_HIDDEN

	itTaruExplodeSetStatus(item_gobj)

# // // // // // // // // // // // //
# //         PORT HELPERS          //
# // // // // // // // // // // // //

## sb32 return of a function that also has (pure) out-parameters: Dictionary {"ret", ...} per the
## out-parameter convention; tolerate a plain value too.
static func _ret(r) -> int:
	if r is Dictionary:
		return int(r.ret)
	return 0 if r == null else int(r)

## C float (f32) rounding.
static func _f32(x: float) -> float:
	var a := PackedFloat32Array([x])
	return a[0]

## F_CLC_DTOR32(x) exactly as the C macro evaluates it in single precision: (f32)(((x) * PI32) / 180.0F).
## The barrel's roll acceleration subtracts it from syUtilsArcTan2(floor) - on a flat floor both are the
## f32 value M_PI_F / 2 and the difference is exactly 0, so a resting barrel keeps vel_air.x == 0 (and
## lr == +1). Port.F_CLC_DTOR32 uses a rounded double factor (1.57079628 for 90) that would add a
## -1.3e-7 drift per frame and flip lr.
static func _F_CLC_DTOR32_f32(x: float) -> float:
	return _f32(_f32(_f32(x) * PI32) / 180.0)
