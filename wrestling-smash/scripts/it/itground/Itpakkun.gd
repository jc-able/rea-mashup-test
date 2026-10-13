## 1:1 port of src/it/itground/itpakkun.c (Mushroom Kingdom Piranha Plant).
##
## Port notes:
##   * ITDesc / ITStatusDesc -> Dictionaries with the C field names; p_file/o_attributes cannot be
##     dereferenced in the port, "attributes" carries the ITAttributes they point at.
##   * lbRelocGetFileData(AObjEvent32*, gGRCommonStruct.inishie.map_head, &llGRInishieMap...) points into
##     StageInishieFile3 (relocData file 155, map_head = map_nodes - 0x5F0). The appear AnimJoint moves the
##     plant in and out of its pipe (gameplay: hurtbox/hitbox position, appear timing), so it is
##     transcribed word for word as an AnimStream; the two MatAnimJoints only animate the mouth texture
##     (render-only) and are transcribed for completeness and passed to the material stubs.
##   * dobj->mobj / dobj->xobjs[1]: core DObj has neither; MObjs live in the DObj's "mobjs" metadata and
##     XObj matrix kinds in its "xobjs" metadata (as Grdisplay keeps them); both are render-only state.
##   * multi (u16) wraps like C.
class_name Itpakkun
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## relocData offsets (tools/relocFileDescriptions.us.txt [260] GRInishieMap; ItemAttributes relative to
## item_head = GRInishieMap, AnimJoints relative to map_head = StageInishieFile3)
const llGRInishieMapPakkunItemAttributes := 0x120
const llGRInishieMapPakkunAppearAnimJoint := 0xCC8
const llGRInishieMapPakkunAppearMatAnimJoint := 0xCF8
const llGRInishieMapPakkunDamagedMatAnimJoint := 0xE04

## AObjEvent32 scripts, src/relocData/155_StageInishieFile3.c (aobjEvent32* macros of src/sys/objdef.h
## expanded to the raw u32 words).
## dStageInishieFile3_AnimJoint_0x0CC8 (llGRInishieMapPakkunAppearAnimJoint): rise / wait / retract.
const dStageInishieFile3_AnimJoint_0x0CC8: Array = [
	0x06100000, 0x00000000, 0x0610001D, 0x44151999, 0x06100040, 0x44151999, 0x0610002F, 0x00000000,
	0x00000000,
]

## dStageInishieFile3_AnimJoint_0x0CF8 (llGRInishieMapPakkunAppearMatAnimJoint): mouth texture frames.
const dStageInishieFile3_AnimJoint_0x0CF8: Array = [
	0x14008000, 0x00000000, 0x14008005, 0x3F800000, 0x14008005, 0x40000000, 0x14008005, 0x3F800000,
	0x14008005, 0x00000000, 0x14008005, 0x3F800000, 0x14008005, 0x40000000, 0x14008005, 0x3F800000,
	0x14008005, 0x00000000, 0x14008005, 0x3F800000, 0x14008005, 0x40000000, 0x14008005, 0x3F800000,
	0x14008005, 0x00000000, 0x14008005, 0x3F800000, 0x14008005, 0x40000000, 0x14008005, 0x3F800000,
	0x14008005, 0x00000000, 0x14008005, 0x3F800000, 0x14008005, 0x40000000, 0x14008005, 0x3F800000,
	0x14008005, 0x00000000, 0x14008004, 0x3F800000, 0x14008005, 0x40000000, 0x14008005, 0x3F800000,
	0x14008005, 0x00000000, 0x14008005, 0x3F800000, 0x14008005, 0x40000000, 0x14008005, 0x3F800000,
	0x14008005, 0x00000000, 0x16008005, 0x3F800000, 0x04000001, 0x00000000,
]

## dStageInishieFile3_AnimJoint_0x0E04 (llGRInishieMapPakkunDamagedMatAnimJoint): looping mouth texture
## frames; word 11 is the aobjEvent32SetAnim target (the script itself, word 0).
const dStageInishieFile3_AnimJoint_0x0E04: Array = [
	0x14008000, 0x00000000, 0x14008005, 0x3F800000, 0x14008005, 0x40000000, 0x14008005, 0x3F800000,
	0x14008005, 0x00000000, 0x1C000000, 0x00000000,
]

static var sITPakkunAppearAnimJoint: AnimStream = AnimStream.from_u32(dStageInishieFile3_AnimJoint_0x0CC8, "dStageInishieFile3_AnimJoint_0x0CC8")
static var sITPakkunAppearMatAnimJoint: AnimStream = AnimStream.from_u32(dStageInishieFile3_AnimJoint_0x0CF8, "dStageInishieFile3_AnimJoint_0x0CF8")
static var sITPakkunDamagedMatAnimJoint: AnimStream = _itPakkunMakeLoopStream(dStageInishieFile3_AnimJoint_0x0E04, "dStageInishieFile3_AnimJoint_0x0E04", 11)

## ITAttributes at gGRCommonStruct.inishie.item_head + llGRInishieMapPakkunItemAttributes (0x120):
## src/relocData/260_GRInishieMap.c dGRInishieMap_Pakkun_ItemAttributes (US FGM enum values).
## data -> 155_StageInishieFile3.c dStageInishieFile3_DObjDesc_0x0C30;
## p_mobjsubs -> dStageInishieFile3_mobjlink_0x0A68 (material, render-only: not transcribed).
const dGRInishieMap_Pakkun_ItemAttributes := {
	"data": [
		{"id": 0, "dl": null, "translate": Vector3(0.0, 15.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 1, "dl": "dStageInishieFile3_DL_0x0B40", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
	],
	"p_mobjsubs": null,                 # dStageInishieFile3_mobjlink_0x0A68 (render-only)
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,                        # Heavy = 0, Light = 1
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(450, 490, 450),
	"map_coll_top": 110,
	"map_coll_center": 0,
	"map_coll_bottom": -110,
	"map_coll_width": 159,
	"size": 200,
	"angle": 80,
	"knockback_scale": 80,
	"damage": 5,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 1,
	"hit_sfx": nSYAudioFGMPunchL,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 1,
	"can_hop": 0,
	"can_reflect": 0,
	"can_shield": 1,
	"knockback_base": 80,
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

static var dITPakkunItemDesc := {
	"kind": nITKindPakkun,                                      # Item Kind
	"p_file": null,                                             # &gGRCommonStruct.inishie.item_head
	"o_attributes": llGRInishieMapPakkunItemAttributes,         # Offset of item attributes in file
	"attributes": dGRInishieMap_Pakkun_ItemAttributes,
	"transform_types": {"tk1": nGCMatrixKindTra, "tk2": 0x30, "tk3": 0},
	"attack_state": nGMAttackStateOff,                          # Hitbox Update State
	"proc_update": Callable(Itpakkun, &"itPakkunWaitProcUpdate"),
	"proc_map": Callable(),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
	"visual_kind": "ground_pakkun",                             # port-only (placeholder visual id)
}

static var dITPakkunStatusDescs: Array = [
	# Status 0 (Dokan Wait)
	{
		"proc_update": Callable(Itpakkun, &"itPakkunWaitProcUpdate"),
		"proc_map": Callable(),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
	},
	# Status 1 (Dokan Appear)
	{
		"proc_update": Callable(Itpakkun, &"itPakkunAppearProcUpdate"),
		"proc_map": Callable(),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(Itpakkun, &"itPakkunAppearProcDamage"),
	},
	# Status 2 (Neutral Damage)
	{
		"proc_update": Callable(Itpakkun, &"itPakkunDamagedProcUpdate"),
		"proc_map": Callable(),
		"proc_hit": Callable(),
		"proc_shield": Callable(),
		"proc_hop": Callable(),
		"proc_setoff": Callable(),
		"proc_reflector": Callable(),
		"proc_damage": Callable(),
	},
]

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itPakkunStatus
const nITPakkunStatusWait = 0
const nITPakkunStatusAppear = 1
const nITPakkunStatusDamaged = 2
const nITPakkunStatusEnumCount = 3

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8017CF20
static func itPakkunWaitSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITPakkunStatusDescs, nITPakkunStatusWait)

	itGetStruct(item_gobj).proc_dead = Callable()

## 0x8017CF58
static func itPakkunAppearSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITPakkunStatusDescs, nITPakkunStatusAppear)

## 0x8017CF80
static func itPakkunDamagedSetStatus(item_gobj) -> void:
	Itmain.itMainSetStatus(item_gobj, dITPakkunStatusDescs, nITPakkunStatusDamaged)

	itGetStruct(item_gobj).proc_dead = Callable(Itpakkun, &"itPakkunDamagedProcDead")

## 0x8017CFC0
static func itPakkunCommonSetWaitFighter(item_gobj) -> void:
	if item_gobj != null:
		var ip := itGetStruct(item_gobj)

		ip.item_vars.pakkun.is_wait_fighter = TRUE

## 0x8017CFDC
static func itPakkunCommonCheckNoFighter(item_gobj) -> int:
	if item_gobj != null:
		var ip := itGetStruct(item_gobj)
		var it_pos_x: float = ip.item_vars.pakkun.pos.x
		var it_pos_y: float = ip.item_vars.pakkun.pos.y

		for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
			var fp := ftGetStruct(fighter_gobj)
			var dobj: DObj = fp.joints[nFTPartsJointTopN]
			var dist_x: float
			var ft_pos_y: float

			if dobj.translate.x < it_pos_x:
				dist_x = f32(-(dobj.translate.x - it_pos_x))
			else:
				dist_x = f32(dobj.translate.x - it_pos_x)

			ft_pos_y = dobj.translate.y

			if (dist_x < ITPAKKUN_DETECT_SIZE_WIDTH) and (ft_pos_y > f32(it_pos_y + ITPAKKUN_DETECT_SIZE_BOTTOM)) and (ft_pos_y < f32(it_pos_y + ITPAKKUN_DETECT_SIZE_TOP)):
				return FALSE

	return TRUE

## 0x8017D0A4
static func itPakkunWaitProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.item_vars.pakkun.is_wait_fighter != FALSE:
		ip.multi = ITPAKKUN_APPEAR_WAIT
		ip.item_vars.pakkun.is_wait_fighter = FALSE

	ip.multi = (ip.multi - 1) & 0xFFFF # --multi (u16)

	if ip.multi == 0:
		if itPakkunCommonCheckNoFighter(item_gobj) != FALSE:
			var dobj := DObjGetStruct(item_gobj)

			# lbRelocGetFileData(AObjEvent32*, gGRCommonStruct.inishie.map_head, &llGRInishieMapPakkunAppearAnimJoint)
			ObjAnim.gcAddDObjAnimJoint(dobj, sITPakkunAppearAnimJoint, 0.0)
			# lbRelocGetFileData(AObjEvent32*, gGRCommonStruct.inishie.map_head, &llGRInishieMapPakkunAppearMatAnimJoint)
			ObjAnim.gcAddMObjMatAnimJoint(_itPakkunGetMObj(dobj), sITPakkunAppearMatAnimJoint, 0.0)
			ObjAnim.gcPlayAnimAll(item_gobj)

			dobj.translate.y += ip.item_vars.pakkun.pos.y

			itPakkunAppearSetStatus(item_gobj)
		else:
			ip.multi = ITPAKKUN_APPEAR_WAIT

	return FALSE

## 0x8017D190
static func itPakkunWaitInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	ip.multi = ITPAKKUN_APPEAR_WAIT

	itPakkunWaitSetStatus(item_gobj)

	ip.damage_coll.hitstatus = nGMHitStatusNone
	ip.attack_coll.attack_state = nGMAttackStateOff

	DObjGetStruct(item_gobj).translate.y = ip.item_vars.pakkun.pos.y

## 0x8017D1DC
static func itPakkunAppearUpdateDamageColl(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var pos_y: float = f32(DObjGetStruct(item_gobj).translate.y - ip.item_vars.pakkun.pos.y)
	var off_y: float = f32(pos_y + ITPAKKUN_APPEAR_OFF_Y)

	if off_y <= ITPAKKUN_CLAMP_OFF_Y:
		ip.damage_coll.hitstatus = nGMHitStatusNone
		ip.attack_coll.attack_state = nGMAttackStateOff
	else:
		if ip.damage_coll.hitstatus == nGMHitStatusNone:
			ip.damage_coll.hitstatus = nGMHitStatusNormal

			Itmain.itMainRefreshAttackColl(item_gobj)

		ip.damage_coll.size.y = f32(off_y - ITPAKKUN_CLAMP_OFF_Y) * ITPAKKUN_HURT_SIZE_MUL_Y
		ip.damage_coll.offset.y = f32(ip.damage_coll.size.y + ITPAKKUN_CLAMP_OFF_Y) - pos_y

## 0x8017D298
static func itPakkunAppearProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj: DObj

	if ip.item_vars.pakkun.is_wait_fighter != FALSE:
		DObjGetStruct(item_gobj).anim_wait = AOBJ_ANIM_NULL

		itPakkunWaitInitVars(item_gobj)

		ip.item_vars.pakkun.is_wait_fighter = FALSE

	dobj = DObjGetStruct(item_gobj)

	if dobj.anim_wait == AOBJ_ANIM_NULL:
		itPakkunWaitInitVars(item_gobj)
	else:
		dobj.translate.y += ip.item_vars.pakkun.pos.y

	itPakkunAppearUpdateDamageColl(item_gobj)

	return FALSE

## 0x8017D334
static func itPakkunAppearProcDamage(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.damage_knockback >= ITPAKKUN_NDAMAGE_KNOCKBACK_MIN:
		var dobj := DObjGetStruct(item_gobj)
		var angle: float

		_itPakkunSetXObjKind(dobj, 1, 0x46) # dobj->xobjs[1]->kind = 0x46

		dobj.rotate.z = F_CST_DTOR32(180.0)

		angle = Ftcommondamage.ftCommonDamageGetKnockbackAngle(ip.damage_angle, ip.ga, ip.damage_knockback)

		ip.physics.vel_air.x = __cosf(angle) * ip.damage_knockback * -ip.damage_lr
		ip.physics.vel_air.y = __sinf(angle) * ip.damage_knockback

		ip.damage_coll.hitstatus = nGMHitStatusNone
		ip.attack_coll.attack_state = nGMAttackStateOff

		itPakkunDamagedSetStatus(item_gobj)

		dobj.anim_wait = AOBJ_ANIM_NULL

		# lbRelocGetFileData(AObjEvent32*, gGRCommonStruct.inishie.map_head, &llGRInishieMapPakkunDamagedMatAnimJoint)
		ObjAnim.gcAddMObjMatAnimJoint(_itPakkunGetMObj(dobj), sITPakkunDamagedMatAnimJoint, 0.0)
		ObjAnim.gcPlayAnimAll(item_gobj)

	return FALSE

## 0x8017D434
static func itPakkunDamagedProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITPAKKUN_GRAVITY, ITPAKKUN_TVEL)

	return FALSE

## 0x8017D460
static func itPakkunDamagedProcDead(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	dobj.translate = ip.item_vars.pakkun.pos

	ip.multi = ITPAKKUN_REBIRTH_WAIT

	ip.physics.vel_air.x = 0.0
	ip.physics.vel_air.y = 0.0
	ip.physics.vel_air.z = 0.0

	dobj.rotate.z = 0.0

	_itPakkunGetMObj(dobj).anim_wait = AOBJ_ANIM_NULL

	itPakkunWaitSetStatus(item_gobj)

	ip.item_vars.pakkun.is_wait_fighter = FALSE

	return FALSE

## 0x8017D4D8
static func itPakkunMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITPakkunItemDesc, pos, vel, flags)

	if item_gobj != null:
		var ip := itGetStruct(item_gobj)

		ip.item_vars.pakkun.pos = pos

		DObjGetStruct(item_gobj).translate = pos

		ip.multi = ITPAKKUN_APPEAR_WAIT

		ip.is_allow_knockback = TRUE

		ip.item_vars.pakkun.is_wait_fighter = FALSE

		ip.attack_coll.can_rehit_shield = TRUE

	return item_gobj

# ---------------------------------------------------------------------------------------
# Port helpers
# ---------------------------------------------------------------------------------------

## AnimStream whose word `jump_word` is the operand of an aobjEvent32SetAnim / Jump that targets the
## start of the script itself (relocData chain pointer -> AnimStream.ptr entry).
static func _itPakkunMakeLoopStream(words: Array, nm: String, jump_word: int) -> AnimStream:
	var s := AnimStream.from_u32(words, nm)

	s.ptr[jump_word] = [s, 0]

	return s

## dobj->mobj (first MObj of the joint). Core DObj has no mobj field: MObjs are kept in the DObj's
## "mobjs" metadata (as Grdisplay does). The plant's MObjSub (mouth texture) is render-only and not
## transcribed, so when the item setup attached no MObj a stand-in with the MObj fields this code uses is
## attached on first access (gcAddMObjForDObj initial values: texture ids 0, no material animation).
static func _itPakkunGetMObj(dobj: DObj):
	var mobjs: Array = dobj.get_meta(&"mobjs", [])

	if mobjs.is_empty():
		mobjs.append({"texture_id_curr": 0, "texture_id_next": 0, "palette_id": 0.0, "anim_wait": AOBJ_ANIM_NULL})
		dobj.set_meta(&"mobjs", mobjs)

	return mobjs[0]

## dobj->xobjs[index]->kind = kind. XObjs (matrix kinds, render-only) are kept as the DObj's "xobjs"
## metadata (Array of nGCMatrixKind*, as Grdisplay records them) when the item setup recorded them.
static func _itPakkunSetXObjKind(dobj: DObj, index: int, kind: int) -> void:
	var xobjs: Array = dobj.get_meta(&"xobjs", [])

	if index < xobjs.size():
		xobjs[index] = kind
		dobj.set_meta(&"xobjs", xobjs)
