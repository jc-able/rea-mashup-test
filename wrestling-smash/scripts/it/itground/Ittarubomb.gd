## 1:1 port of src/it/itground/ittarubomb.c (Race to the Finish rolling barrel bomb).
##
## Port notes:
##   * ITDesc / ITStatusDesc -> Dictionaries with the C field names; p_file/o_attributes cannot be
##     dereferenced in the port, "attributes" carries the ITAttributes they point at.
##   * itGetAttackEvent(dITTaruBombItemDesc, &llGRBonus3MapTaruBombAttackEvents) resolves to the
##     ITAttackEvent table transcribed below (Array of Dictionaries with the C field names), passed to
##     Itmain.itMainUpdateAttackEvent.
##   * Container smash effect: the effect GObj and its 7 DObjs are made exactly like C (including the 6
##     syUtilsRandFloat calls per piece, which only happen when efManagerGetEffectNoForce returns an
##     EFStruct). efGetStruct(effect_gobj) is effect_gobj.user_data (= ep). The display list
##     ((attr->data - &llGRBonus3MapTaruBombDataStart) + &llGRBonus3MapTaruBombEffectDisplayList =
##     GRBonus3File3 + 0x8A0) is render-only: the DObjs carry its symbol name.
##   * itMapCheckCollideAllRebound follows the PORTING.md out-parameter convention (pos is a pure
##     output, C passes NULL): it returns {"ret", "pos"}; _itTaruBombRet reads "ret".
##   * multi (u16) wraps like C.
class_name Ittarubomb
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## relocData offsets (tools/relocFileDescriptions.us.txt [295] GRBonus3Map; ItemAttributes/AttackEvents
## relative to item_head = GRBonus3Map, DataStart/DisplayList relative to GRBonus3File3)
const llGRBonus3MapTaruBombItemAttributes := 0xA8
const llGRBonus3MapTaruBombAttackEvents := 0xF0
const llGRBonus3MapTaruBombDataStart := 0x788
const llGRBonus3MapTaruBombEffectDisplayList := 0x8A0

## ITAttributes at gGRCommonStruct.bonus3.item_head + llGRBonus3MapTaruBombItemAttributes (0xA8):
## src/relocData/295_GRBonus3Map.c dGRBonus3Map_TaruBomb_ItemAttributes (US FGM enum values).
## data -> 162_GRBonus3File3.c dGRBonus3File3_DObjDesc_0x0788 (joint ids 1 and 0x4002 draw the
## dGRBonus3File3_DLLink_0x0768 / _0x0778 DObjDLLinks; models are render-only, "dl" names the C symbol).
const dGRBonus3Map_TaruBomb_ItemAttributes := {
	"data": [
		{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, -210.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 1, "dl": "dGRBonus3File3_DLLink_0x0768", "translate": Vector3(0.0, 0.0, 210.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 16386, "dl": "dGRBonus3File3_DLLink_0x0778", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
	],
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 1,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 0,                        # Heavy = 0, Light = 1
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(294, 316, 294),
	"map_coll_top": 236,
	"map_coll_center": 0,
	"map_coll_bottom": -236,
	"map_coll_width": 221,
	"size": 290,
	"angle": 70,
	"knockback_scale": 20,
	"damage": 10,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 1,
	"hit_sfx": nSYAudioFGMPunchL,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 0,
	"can_reflect": 1,
	"can_shield": 1,
	"knockback_base": 90,
	"type": 6,
	"hitstatus": 1,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## ITAttackEvent[4] at item_head + llGRBonus3MapTaruBombAttackEvents (0xF0):
## src/relocData/295_GRBonus3Map.c dGRBonus3Map_TaruBomb_AttackEvents.
const dGRBonus3Map_TaruBomb_AttackEvents: Array = [
	{"timer": 0, "angle": 361, "damage": 16, "size": 350},
	{"timer": 2, "angle": 361, "damage": 11, "size": 250},
	{"timer": 4, "angle": 361, "damage": 8, "size": 150},
	{"timer": 6, "angle": 361, "damage": 1, "size": 0},
]

static var dITTaruBombItemDesc := {
	"kind": nITKindTaruBomb,                                    # Item Kind
	"p_file": null,                                             # &gGRCommonStruct.bonus3.item_head
	"o_attributes": llGRBonus3MapTaruBombItemAttributes,        # Offset of item attributes in file
	"attributes": dGRBonus3Map_TaruBomb_ItemAttributes,
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyR, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateNew,                          # Hitbox Update State
	"proc_update": Callable(Ittarubomb, &"itTaruBombFallProcUpdate"),
	"proc_map": Callable(Ittarubomb, &"itTaruBombFallProcMap"),
	"proc_hit": Callable(Ittarubomb, &"itTaruBombCommonProcHit"),
	"proc_shield": Callable(Ittarubomb, &"itTaruBombCommonProcHit"),
	"proc_hop": Callable(),
	"proc_setoff": Callable(Ittarubomb, &"itTaruBombCommonProcHit"),
	"proc_reflector": Callable(Ittarubomb, &"itTaruBombCommonProcHit"),
	"proc_damage": Callable(Ittarubomb, &"itTaruBombCommonProcDamage"),
	"visual_kind": "ground_tarubomb",                           # port-only (placeholder visual id)
}

static var dITTaruBombStatusDescs: Array = [
	# Status 0 (Air Wait Fall)
	{
		"proc_update": Callable(Ittarubomb, &"itTaruBombFallProcUpdate"),
		"proc_map": Callable(Ittarubomb, &"itTaruBombFallProcMap"),
		"proc_hit": Callable(Ittarubomb, &"itTaruBombCommonProcHit"),
		"proc_shield": Callable(Ittarubomb, &"itTaruBombCommonProcHit"),
		"proc_hop": Callable(),
		"proc_setoff": Callable(Ittarubomb, &"itTaruBombCommonProcHit"),
		"proc_reflector": Callable(Ittarubomb, &"itTaruBombCommonProcHit"),
		"proc_damage": Callable(Ittarubomb, &"itTaruBombCommonProcDamage"),
	},
	# Status 1 (Neutral Explosion)
	{
		"proc_update": Callable(Ittarubomb, &"itTaruBombExplodeProcUpdate"),
		"proc_map": Callable(),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
	},
	# Status 2 (Ground Roll)
	{
		"proc_update": Callable(Ittarubomb, &"itTaruBombRollProcUpdate"),
		"proc_map": Callable(Ittarubomb, &"itTaruBombRollProcMap"),
		"proc_hit": Callable(Ittarubomb, &"itTaruBombCommonProcHit"),
		"proc_shield": Callable(Ittarubomb, &"itTaruBombCommonProcHit"),
		"proc_hop": Callable(),
		"proc_setoff": Callable(Ittarubomb, &"itTaruBombCommonProcHit"),
		"proc_reflector": Callable(Ittarubomb, &"itTaruBombCommonProcHit"),
		"proc_damage": Callable(Ittarubomb, &"itTaruBombCommonProcDamage"),
	},
]

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itTaruBombStatus
const nITTaruBombStatusFall = 0
const nITTaruBombStatusExplode = 1
const nITTaruBombStatusRoll = 2
const nITTaruBombStatusEnumCount = 3

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80184A70
static func itTaruBombContainerSmashUpdateEffect(effect_gobj) -> void: # RTTF bomb explode GFX process
	var ep = effect_gobj.user_data # efGetStruct(effect_gobj)
	var dobj: DObj = DObjGetStruct(effect_gobj)

	ep.effect_vars.container.lifetime -= 1

	if ep.effect_vars.container.lifetime == 0:
		Efmanager.efManagerSetPrevStructAlloc(ep)
		Objman.gcEjectGObj(effect_gobj)
	else:
		while dobj != null:
			dobj.scale.y -= 1.3

			dobj.translate.x += dobj.scale.x # This makes no sense, seems this custom effect is very... custom
			dobj.translate.y += dobj.scale.y
			dobj.translate.z += dobj.scale.z

			dobj.rotate.x += dobj.anim_wait # ??? Seems to be rotation step, but only in this case? Otherwise -FLOAT32_MAX?
			dobj.rotate.y += dobj.anim_speed
			dobj.rotate.z += dobj.anim_frame

			dobj = dobj.sib_next

## 0x80184B44
static func itTaruBombContainerSmashMakeEffect(pos: Vector3) -> void:
	var effect_gobj
	var ep = Efmanager.efManagerGetEffectNoForce()
	var dobj: DObj
	var dl

	if ep != null:
		effect_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindEffect, null, nGCCommonLinkIDEffect, GOBJ_PRIORITY_DEFAULT)

		if effect_gobj != null:
			Objman.gcAddGObjDisplay(effect_gobj, Callable(Objdisplay, &"gcDrawDObjTreeForGObj"), 11, GOBJ_PRIORITY_DEFAULT, ~0)

			# dl = (*(uintptr_t*)(*dITTaruBombItemDesc.p_file + dITTaruBombItemDesc.o_attributes) - &llGRBonus3MapTaruBombDataStart) + &llGRBonus3MapTaruBombEffectDisplayList
			dl = "dGRBonus3File3_DL_0x08A0"

			for i in ITTARUBOMB_EFFECT_COUNT:
				dobj = Objman.gcAddDObjForGObj(effect_gobj, dl)

				Objman.gcAddXObjForDObjFixed(dobj, nGCMatrixKindTraRotRpyR, 0)

				dobj.translate = pos

				dobj.scale.x = (syUtilsRandFloat() * 48.0) + -24.0
				dobj.scale.y = (syUtilsRandFloat() * 50.0) + 10.0
				dobj.scale.z = (syUtilsRandFloat() * 32.0) + -16.0

				dobj.anim_wait = F_CLC_DTOR32((syUtilsRandFloat() * 100.0) + -50.0)
				dobj.anim_speed = F_CLC_DTOR32((syUtilsRandFloat() * 100.0) + -50.0)
				dobj.anim_frame = F_CLC_DTOR32((syUtilsRandFloat() * 100.0) + -50.0)

			ep.effect_vars.container.lifetime = ITTARUBOMB_GFX_LIFETIME

			effect_gobj.user_data = ep

			Objman.gcAddGObjProcess(effect_gobj, Callable(Ittarubomb, &"itTaruBombContainerSmashUpdateEffect"), 1, 3) # 1 = nGCProcessKindFunc

## 0x80184D74
static func itTaruBombFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj: DObj

	Itmain.itMainApplyGravityClampTVel(ip, ITTARUBOMB_GRAVITY, ITTARUBOMB_TVEL)

	dobj = DObjGetStruct(item_gobj)
	dobj.rotate.z += ip.item_vars.tarubomb.roll_rotate_step

	return FALSE

## 0x80184DC4
static func itTaruBombCommonProcHit(item_gobj) -> int:
	Snd.func_800269C0_275C0(nSYAudioFGMTaruBombHit)
	itTaruBombContainerSmashMakeEffect(DObjGetStruct(item_gobj).translate)
	itTaruBombExplodeMakeEffectGotoSetStatus(item_gobj)

	return FALSE

## 0x80184E04
static func itTaruBombCommonProcDamage(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.percent_damage >= ITTARUBOMB_HEALTH_MAX:
		return itTaruBombCommonProcHit(item_gobj)

	return FALSE

## 0x80184E44
static func itTaruBombRollSetStatus(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.physics.vel_air.y = 0.0

	Itmain.itMainSetStatus(item_gobj, dITTaruBombStatusDescs, nITTaruBombStatusRoll)

## 0x80184E78
static func itTaruBombFallCheckCollideGround(item_gobj, common_rebound: float) -> int:
	var is_collide_floor: int = Itmap.itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_FLOOR)

	if _itTaruBombRet(Itmap.itMapCheckCollideAllRebound(item_gobj, (MAP_FLAG_CEIL | MAP_FLAG_RWALL | MAP_FLAG_LWALL), common_rebound)) != FALSE:
		Itmain.itMainSetSpinVelLR(item_gobj)

	if is_collide_floor != FALSE:
		return TRUE
	else:
		return FALSE

## 0x80184EDC
static func itTaruBombFallProcMap(item_gobj) -> int:
	if itTaruBombFallCheckCollideGround(item_gobj, ITTARUBOMB_MAP_REBOUND_COMMON) != FALSE:
		var ip := itGetStruct(item_gobj)

		if ip.physics.vel_air.y >= 90.0: # Is it even possible to meet this condition? Didn't they mean <= inverse of this value?
			itTaruBombCommonProcHit(item_gobj) # This causes the bomb to smash on impact when landing from too high; doesn't seem possible to trigger

			return TRUE
		elif ip.physics.vel_air.y < 30.0:
			itTaruBombRollSetStatus(item_gobj)
		else:
			ip.physics.vel_air = Lbcommon.lbCommonReflect2D(ip.physics.vel_air, ip.coll_data.floor_angle)

			ip.physics.vel_air.y *= f32(0.2) # 0.2F

			Itmain.itMainSetSpinVelLR(item_gobj)

		Snd.func_800269C0_275C0(nSYAudioFGMTaruBombMap)
		Itmain.itMainClearOwnerStats(item_gobj)

	return FALSE

## 0x80184FAC
static func itTaruBombCommonSetMapCollisionBox(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	DObjGetStruct(item_gobj).rotate.x = F_CLC_DTOR32(90.0)

	ip.coll_data.map_coll.top = ip.coll_data.map_coll.width
	ip.coll_data.map_coll.bottom = -ip.coll_data.map_coll.width

## 0x80184FD4
static func itTaruBombExplodeProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	ip.multi = (ip.multi + 1) & 0xFFFF # u16

	if ip.multi == ITTARUBOMB_EXPLODE_LIFETIME:
		return TRUE
	else:
		Itmain.itMainUpdateAttackEvent(item_gobj, dGRBonus3Map_TaruBomb_AttackEvents) # itGetAttackEvent(dITTaruBombItemDesc, &llGRBonus3MapTaruBombAttackEvents)

	return FALSE

## 0x80185030
static func itTaruBombRollProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var roll_rotate_step: float
	var sqrt_vel: float

	# vel_air.x += (-(syUtilsArcTan2(floor_angle.y, floor_angle.x) - F_CLC_DTOR32(90.0F) /*HALF_PI32*/) * ITTARUBOMB_MUL_VEL_X), single precision steps
	ip.physics.vel_air.x += f32(-f32(syUtilsArcTan2(ip.coll_data.floor_angle.y, ip.coll_data.floor_angle.x) - F_CLC_DTOR32(90.0)) * f32(ITTARUBOMB_MUL_VEL_X))

	ip.lr = +1 if (ip.physics.vel_air.x >= 0.0) else -1

	sqrt_vel = f32(sqrtf(f32(SQUARE(ip.physics.vel_air.x) + SQUARE(ip.physics.vel_air.y))))

	roll_rotate_step = f32((f32(ITTARUBOMB_ROLL_ROTATE_MUL) if (ip.lr == -1) else -f32(ITTARUBOMB_ROLL_ROTATE_MUL)) * sqrt_vel)

	ip.item_vars.tarubomb.roll_rotate_step = roll_rotate_step

	DObjGetStruct(item_gobj).rotate.z += roll_rotate_step

	return FALSE

## 0x8018511C
static func itTaruBombRollProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if Itmap.itMapTestLRWallCheckFloor(item_gobj) == FALSE:
		Itmain.itMainSetStatus(item_gobj, dITTaruBombStatusDescs, nITTaruBombStatusFall)
	elif ip.coll_data.mask_curr & (MAP_FLAG_RWALL | MAP_FLAG_LWALL):
		return itTaruBombCommonProcHit(item_gobj)

	return FALSE

## 0x8018518C
static func itTaruBombMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITTaruBombItemDesc, pos, vel, flags)

	if item_gobj != null:
		var ip := itGetStruct(item_gobj)

		ip.item_vars.tarubomb.roll_rotate_step = 0.0

		itTaruBombCommonSetMapCollisionBox(item_gobj)

	return item_gobj

## 0x801851F4
static func itTaruBombExplodeInitVars(item_gobj) -> void:
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

	Itmain.itMainRefreshAttackColl(item_gobj)
	Itmain.itMainUpdateAttackEvent(item_gobj, dGRBonus3Map_TaruBomb_AttackEvents) # itGetAttackEvent(dITTaruBombItemDesc, &llGRBonus3MapTaruBombAttackEvents)

## 0x80185284
static func itTaruBombExplodeSetStatus(item_gobj) -> void:
	itTaruBombExplodeInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITTaruBombStatusDescs, nITTaruBombStatusExplode)

## 0x801852B8
static func itTaruBombExplodeMakeEffectGotoSetStatus(item_gobj) -> void:
	var pc
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	ip.attack_coll.attack_state = nGMAttackStateOff

	ip.physics.vel_air.x = 0.0
	ip.physics.vel_air.y = 0.0
	ip.physics.vel_air.z = 0.0

	pc = Efmanager.efManagerSparkleWhiteMultiExplodeMakeEffect(dobj.translate)

	if pc != null:
		pc.xf.scale.z = ITTARUBOMB_EXPLODE_EFFECT_SCALE
		pc.xf.scale.y = pc.xf.scale.z
		pc.xf.scale.x = pc.xf.scale.y

	Efmanager.efManagerQuakeMakeEffect(1)

	DObjGetStruct(item_gobj).flags = DOBJ_FLAG_HIDDEN

	itTaruBombExplodeSetStatus(item_gobj)

# ---------------------------------------------------------------------------------------
# Port helpers
# ---------------------------------------------------------------------------------------

## C return value of a callee that follows the PORTING.md out-parameter convention
## ({"ret": ..., "<out>": ...}); a plain value is returned as is.
static func _itTaruBombRet(r) -> int:
	if r is Dictionary:
		return int(r.get("ret", FALSE))

	return int(r) if r != null else FALSE
