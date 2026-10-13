## 1:1 port of src/wp/wpmanager.c (ssb-decomp-re): weapon (projectile) struct pool and
## wpManagerMakeWeapon.
##
## ---------------------------------------------------------------------------------------
## CALLING CONVENTION (used by every character / item / stage weapon port)
## ---------------------------------------------------------------------------------------
##   var weapon_gobj = Wpmanager.wpManagerMakeWeapon(parent_gobj, wp_desc, spawn_pos, flags)
##     parent_gobj : Fighter / Weapon / Item that spawns the weapon (null for stage weapons)
##     wp_desc     : Dictionary (C WPDesc, see below)
##     spawn_pos   : Vector3 (C: Vec3f *spawn_pos, read only)
##     flags       : int, WEAPON_FLAG_PARENT_* | optional WEAPON_FLAG_COLLPROJECT
##     returns     : the new Weapon (== weapon_gobj == wpGetStruct(weapon_gobj)) or null when
##                   the 32-slot weapon pool is exhausted (exactly like the C NULL return).
##
##   wp_desc = {
##     "flags": int,                       # WPDesc.flags: WEAPON_FLAG_DOBJDESC | WEAPON_FLAG_DOBJLINKS
##     "kind": int,                        # nWPKind*
##     "transform_types": {"tk1": int, "tk2": int, "tk3": int},   # or [tk1, tk2, tk3]
##     "proc_update": Callable, "proc_map": Callable, "proc_hit": Callable,
##     "proc_shield": Callable, "proc_hop": Callable, "proc_setoff": Callable,
##     "proc_reflector": Callable, "proc_absorb": Callable,       # Callable() or null == NULL
##     "attributes": {                     # C WPAttributes, same field names
##        "data": ...,                     # WEAPON_FLAG_DOBJDESC: Array of DObjDesc Dictionaries
##                                         #   {"id": int, "translate": Vector3, "rotate": Vector3,
##                                         #    "scale": Vector3, "dl": optional} (ends at id 18 or
##                                         #   at the end of the Array); otherwise the display list
##                                         #   (any value, stored in the root DObj's .dl) or null.
##        "p_mobjsubs": null, "anim_joints": Array[AnimStream] (tree pre-order, null entries
##        allowed) or null, "p_matanim_joints": null,
##        "attack_offsets": [Vector3, Vector3],
##        "map_coll_top", "map_coll_center", "map_coll_bottom", "map_coll_width",
##        "size", "angle", "knockback_scale", "damage", "element", "knockback_weight",
##        "shield_damage", "attack_count", "can_setoff", "sfx", "priority",
##        "can_rehit_item", "can_rehit_fighter", "can_hop", "can_reflect", "can_absorb",
##        "can_shield", "knockback_base"
##     },
##     "visual_kind": String               # port-only, copied to weapon.visual_kind
##   }
##   Weapon procs are called as proc.call(weapon_gobj) and return sb32 (TRUE destroys the weapon).
##
## Port notes:
##   * The C struct pool (WEAPON_ALLOC_MAX structs on a free list) is kept as a count of free
##     structs; wpManagerGetNextStructAlloc() returns a fresh Weapon.new() while one is free.
##     The statics start in the state wpManagerAllocWeapons() leaves them in; scenes still call
##     wpManagerAllocWeapons() at battle start to reset the pool exactly like the C scenes do.
##   * The GObj and the WPStruct are the same Weapon object (registered with
##     Sim.add_gobj(weapon, nGCCommonLinkIDWeapon) instead of gcMakeGObjSPAfter).
##   * wpManagerGetGroupID() accepts (and ignores) two arguments because PK Thunder calls it with
##     two unused arguments in the C source.
class_name Wpmanager
extends Port

# // // // // // // // // // // // //
# //   GLOBAL / STATIC VARIABLES   //
# // // // // // // // // // // // //

## 0x8018CFF0 - Points to next available weapon struct.
## Port: number of free WPStruct slots left in the pool (the C free-list head pointer).
static var sWPManagerStructsAllocFree: int = WEAPON_ALLOC_MAX

## 0x8018CFF4
static var sWPManagerDisplayMode: int = nDBDisplayModeMaster

## 0x8018CFF8
static var sWPManagerGroupID: int = 1

## 0x8018CFFC
static var sWPManagerPad0x8018CFFC: PackedByteArray = PackedByteArray([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801654B0
static func wpManagerAllocWeapons() -> void:
	# sWPManagerStructsAllocFree = wp = syTaskmanMalloc(sizeof(WPStruct) * WEAPON_ALLOC_MAX, 0x8);
	# wp[i].next = &wp[i + 1] for every struct, the last one ends the list.
	sWPManagerStructsAllocFree = WEAPON_ALLOC_MAX
	sWPManagerGroupID = 1
	sWPManagerDisplayMode = nDBDisplayModeMaster

## 0x80165558
## Returns a new weapon struct (Weapon) or null when every struct of the pool is in use.
static func wpManagerGetNextStructAlloc():
	if sWPManagerStructsAllocFree <= 0:
		return null
	var get_weapon := Weapon.new()

	sWPManagerStructsAllocFree -= 1

	return get_weapon

## 0x80165588
static func wpManagerSetPrevStructAlloc(wp = null) -> void:
	# Port guard: a struct can only be put back on the free list once (C would corrupt its list).
	if wp != null:
		if wp.has_meta(&"wp_struct_freed"):
			return
		wp.set_meta(&"wp_struct_freed", true)
	sWPManagerStructsAllocFree += 1

## 0x801655A0 - WARNING: Do NOT declare this with a void argument! PK Thunder passes unused arguments to this function.
static func wpManagerGetGroupID(_unused_arg0 = null, _unused_arg1 = null) -> int:
	var group_id: int = sWPManagerGroupID

	sWPManagerGroupID = (sWPManagerGroupID + 1) & 0xFFFFFFFF

	if sWPManagerGroupID == 0:
		sWPManagerGroupID += 1

	return group_id

## 0x801655C8
static func wpManagerMakeWeapon(parent_gobj, wp_desc: Dictionary, spawn_pos: Vector3, flags: int):
	var weapon_gobj
	var proc_display: Callable
	var attr: Dictionary
	var wp
	var owner_wp
	var ip
	var fp

	wp = wpManagerGetNextStructAlloc()

	if wp == null:
		return null

	# weapon_gobj = gcMakeGObjSPAfter(nGCCommonKindWeapon, NULL, nGCCommonLinkIDWeapon, GOBJ_PRIORITY_DEFAULT);
	weapon_gobj = wp
	weapon_gobj.gobj_kind = nGCCommonKindWeapon
	Sim.add_gobj(weapon_gobj, nGCCommonLinkIDWeapon)

	# attr = lbRelocGetFileData(WPAttributes*, *wp_desc->p_weapon, wp_desc->o_attributes);
	attr = wp_desc.get("attributes", {})
	weapon_gobj.user_data = wp
	wp.weapon_gobj = weapon_gobj
	wp.kind = int(wp_desc.get("kind", 0))
	wp.attr = attr
	wp.visual_kind = str(wp_desc.get("visual_kind", ""))
	weapon_gobj.debug_name = wp.visual_kind

	match flags & WEAPON_MASK_PARENT:
		WEAPON_FLAG_PARENT_FIGHTER: # Weapons spawned by fighters
			fp = ftGetStruct(parent_gobj)
			wp.owner_gobj = parent_gobj
			wp.team = fp.team
			wp.player = fp.player
			wp.handicap = fp.handicap
			wp.player_num = fp.player_num
			wp.lr = fp.lr

			wp.display_mode = fp.display_mode

			wp.attack_coll.stale = Ftparam.ftParamGetStale(fp.player, fp.motion_attack_id, fp.motion_count)
			wp.attack_coll.motion_attack_id = fp.motion_attack_id & 0x3F # u32 motion_attack_id : 6
			wp.attack_coll.motion_count = fp.motion_count & 0xFFFF
			wp.attack_coll.stat_flags = fp.stat_flags.dup()
			wp.attack_coll.stat_count = fp.stat_count & 0xFFFF

		WEAPON_FLAG_PARENT_WEAPON: # Weapons spawned by other weapons
			owner_wp = wpGetStruct(parent_gobj)
			wp.owner_gobj = owner_wp.owner_gobj
			wp.team = owner_wp.team
			wp.player = owner_wp.player
			wp.handicap = owner_wp.handicap
			wp.player_num = owner_wp.player_num
			wp.lr = owner_wp.lr

			wp.display_mode = owner_wp.display_mode

			wp.attack_coll.stale = owner_wp.attack_coll.stale
			wp.attack_coll.motion_attack_id = owner_wp.attack_coll.motion_attack_id
			wp.attack_coll.motion_count = owner_wp.attack_coll.motion_count
			wp.attack_coll.stat_flags = owner_wp.attack_coll.stat_flags.dup()
			wp.attack_coll.stat_count = owner_wp.attack_coll.stat_count

		WEAPON_FLAG_PARENT_ITEM: # Weapons spawned by items
			ip = itGetStruct(parent_gobj)
			wp.owner_gobj = ip.owner_gobj
			wp.team = ip.team
			wp.player = ip.player
			wp.handicap = ip.handicap
			wp.player_num = ip.player_num
			wp.lr = ip.lr

			wp.display_mode = ip.display_mode

			wp.attack_coll.stale = ip.attack_coll.stale
			wp.attack_coll.motion_attack_id = ip.attack_coll.motion_attack_id & 0x3F
			wp.attack_coll.motion_count = ip.attack_coll.motion_count & 0xFFFF
			wp.attack_coll.stat_flags = ip.attack_coll.stat_flags.dup()
			wp.attack_coll.stat_count = ip.attack_coll.stat_count & 0xFFFF

		_: # Weapons spawned independently (default: / case WEAPON_FLAG_PARENT_GROUND:)
			wp.owner_gobj = null
			wp.team = WEAPON_TEAM_DEFAULT
			wp.player = WEAPON_PORT_DEFAULT
			wp.handicap = WEAPON_HANDICAP_DEFAULT
			wp.player_num = 0
			wp.lr = +1

			wp.display_mode = sWPManagerDisplayMode

			wp.attack_coll.motion_attack_id = nFTMotionAttackIDNone
			wp.attack_coll.stale = WEAPON_STALE_DEFAULT
			wp.attack_coll.motion_count = Ftparam.ftParamGetMotionCount()
			wp.attack_coll.stat_flags.attack_id = nFTStatusAttackIDNone
			wp.attack_coll.stat_flags.is_projectile = 0
			wp.attack_coll.stat_flags.ga = 0
			wp.attack_coll.stat_flags.is_smash_attack = 0
			wp.attack_coll.stat_count = Ftparam.ftParamGetStatUpdateCount()

	wp.attack_coll.attack_state = nGMAttackStateNew

	wp.physics.vel_air.x = 0.0
	wp.physics.vel_air.y = 0.0
	wp.physics.vel_air.z = 0.0
	wp.physics.vel_ground = 0.0

	wp.attack_coll.damage = int(attr.get("damage", 0))
	wp.attack_coll.element = int(attr.get("element", 0))

	var attack_offsets: Array = attr.get("attack_offsets", [Vector3.ZERO, Vector3.ZERO])
	wp.attack_coll.offsets[0] = Vector3(attack_offsets[0].x, attack_offsets[0].y, attack_offsets[0].z)
	wp.attack_coll.offsets[1] = Vector3(attack_offsets[1].x, attack_offsets[1].y, attack_offsets[1].z)

	wp.attack_coll.size = int(attr.get("size", 0)) * 0.5

	wp.attack_coll.angle = int(attr.get("angle", 0))

	wp.attack_coll.knockback_scale = int(attr.get("knockback_scale", 0))
	wp.attack_coll.knockback_weight = int(attr.get("knockback_weight", 0))
	wp.attack_coll.knockback_base = int(attr.get("knockback_base", 0))

	wp.attack_coll.can_setoff = int(attr.get("can_setoff", 0))

	wp.attack_coll.shield_damage = int(attr.get("shield_damage", 0))

	wp.attack_coll.fgm_id = int(attr.get("sfx", 0))

	wp.attack_coll.priority = int(attr.get("priority", 0))

	wp.attack_coll.can_rehit_item = int(attr.get("can_rehit_item", 0))
	wp.attack_coll.can_rehit_fighter = int(attr.get("can_rehit_fighter", 0))
	wp.attack_coll.can_rehit_shield = FALSE

	wp.attack_coll.can_hop = int(attr.get("can_hop", 0))
	wp.attack_coll.can_reflect = int(attr.get("can_reflect", 0))
	wp.attack_coll.can_absorb = int(attr.get("can_absorb", 0))
	wp.attack_coll.can_not_heal = FALSE
	wp.attack_coll.can_shield = int(attr.get("can_shield", 0))

	wp.attack_coll.attack_count = int(attr.get("attack_count", 0))

	wp.attack_coll.interact_mask = GMHITCOLLISION_FLAG_ALL

	Wpmain.wpMainClearAttackRecord(wp)

	wp.hit_normal_damage = 0
	wp.hit_refresh_damage = 0
	wp.hit_attack_damage = 0
	wp.hit_shield_damage = 0
	wp.reflect_gobj = null
	wp.absorb_gobj = null

	wp.is_hitlag_victim = FALSE
	wp.is_hitlag_weapon = FALSE
	wp.is_camera_follow = FALSE

	wp.group_id = 0

	wp.is_static_damage = FALSE

	wp.p_sfx = null
	wp.sfx_id = 0

	wp.shield_collide_angle = 0.0

	wp.shield_collide_dir.x = 0.0
	wp.shield_collide_dir.y = 0.0
	wp.shield_collide_dir.z = 0.0

	var desc_flags: int = int(wp_desc.get("flags", 0))
	var tk := _wpManagerGetTransformTypes(wp_desc.get("transform_types", null))

	if desc_flags & WEAPON_FLAG_DOBJDESC:
		_wpManagerSetupCustomDObjs(weapon_gobj, attr.get("data", null), tk[0], tk[1], tk[2])

		proc_display = Callable(Wpdisplay, &"wpDisplayDObjTreeDLLinks") if (desc_flags & WEAPON_FLAG_DOBJLINKS) else Callable(Wpdisplay, &"func_ovl3_80167618")
	else:
		Lbcommon.lbCommonInitDObj3Transforms(Objman.gcAddDObjForGObj(weapon_gobj, attr.get("data", null)), tk[0], tk[1], tk[2])

		proc_display = Callable(Wpdisplay, &"wpDisplayDObjDLLinks") if (desc_flags & WEAPON_FLAG_DOBJLINKS) else Callable(Wpdisplay, &"wpDisplayDLHead1")

	Objman.gcAddGObjDisplay(weapon_gobj, proc_display, 14, GOBJ_PRIORITY_DEFAULT, ~0)

	if attr.get("p_mobjsubs", null) != null:
		ObjAnim.gcAddMObjAll(weapon_gobj, attr.get("p_mobjsubs", null))

	if (attr.get("anim_joints", null) != null) or (attr.get("p_matanim_joints", null) != null):
		_wpManagerAddAnimAll(weapon_gobj, attr.get("anim_joints", null), attr.get("p_matanim_joints", null), 0.0)

	# wp->coll_data.p_translate = &DObjGetStruct(weapon_gobj)->translate.vec.f;
	# wp->coll_data.p_lr = &wp->lr;
	# (MPCollData.p_translate / p_lr are bound to their owner: wp.coll_data.owner == wp.)
	wp.coll_data.owner = wp

	wp.coll_data.map_coll.top = float(attr.get("map_coll_top", 0))
	wp.coll_data.map_coll.center = float(attr.get("map_coll_center", 0))
	wp.coll_data.map_coll.bottom = float(attr.get("map_coll_bottom", 0))
	wp.coll_data.map_coll.width = float(attr.get("map_coll_width", 0))
	wp.coll_data.p_map_coll = wp.coll_data.map_coll

	wp.coll_data.ignore_line_id = -1
	wp.coll_data.floor_line_id = -1
	wp.coll_data.ceil_line_id = -1
	wp.coll_data.lwall_line_id = -1
	wp.coll_data.rwall_line_id = -1

	wp.coll_data.update_tic = Mpcollision.gMPCollisionUpdateTic
	wp.coll_data.mask_curr = 0

	wp.coll_data.vel_push.x = 0.0
	wp.coll_data.vel_push.y = 0.0
	wp.coll_data.vel_push.z = 0.0

	Objman.gcAddGObjProcess(weapon_gobj, Callable(Wpprocess, &"wpProcessProcWeaponMain"), nGCProcessKindFunc, 3)
	Objman.gcAddGObjProcess(weapon_gobj, Callable(Wpprocess, &"wpProcessProcSearchHitWeapon"), nGCProcessKindFunc, 1)
	Objman.gcAddGObjProcess(weapon_gobj, Callable(Wpprocess, &"wpProcessProcHitCollisions"), nGCProcessKindFunc, 0)

	wp.proc_update = _wpManagerGetDescProc(wp_desc, "proc_update")
	wp.proc_map = _wpManagerGetDescProc(wp_desc, "proc_map")
	wp.proc_hit = _wpManagerGetDescProc(wp_desc, "proc_hit")
	wp.proc_shield = _wpManagerGetDescProc(wp_desc, "proc_shield")
	wp.proc_hop = _wpManagerGetDescProc(wp_desc, "proc_hop")
	wp.proc_setoff = _wpManagerGetDescProc(wp_desc, "proc_setoff")
	wp.proc_reflector = _wpManagerGetDescProc(wp_desc, "proc_reflector")
	wp.proc_absorb = _wpManagerGetDescProc(wp_desc, "proc_absorb")
	wp.proc_dead = Callable()

	DObjGetStruct(weapon_gobj).translate = spawn_pos
	wp.coll_data.pos_prev = spawn_pos

	if flags & WEAPON_FLAG_COLLPROJECT:
		match flags & WEAPON_MASK_PARENT:
			WEAPON_FLAG_PARENT_FIGHTER:
				Mpcommon.mpCommonRunWeaponCollisionDefault(weapon_gobj, ftGetStruct(parent_gobj).coll_data.p_translate, ftGetStruct(parent_gobj).coll_data)

			WEAPON_FLAG_PARENT_WEAPON:
				Mpcommon.mpCommonRunWeaponCollisionDefault(weapon_gobj, wpGetStruct(parent_gobj).coll_data.p_translate, wpGetStruct(parent_gobj).coll_data)

			WEAPON_FLAG_PARENT_ITEM:
				Mpcommon.mpCommonRunWeaponCollisionDefault(weapon_gobj, itGetStruct(parent_gobj).coll_data.p_translate, itGetStruct(parent_gobj).coll_data)

			_: # default: / case WEAPON_FLAG_PARENT_GROUND:
				pass

	wp.ga = nMPKineticsAir

	Wpprocess.wpProcessUpdateHitPositions(weapon_gobj)

	return weapon_gobj

# ---------------------------------------------------------------------------------------
# Port helpers (inlined engine routines that wpManagerMakeWeapon relies on)
# ---------------------------------------------------------------------------------------

## WPDesc.transform_types {tk1, tk2, tk3} (Dictionary or Array) -> [tk1, tk2, tk3]
static func _wpManagerGetTransformTypes(transform_types) -> Array:
	if transform_types is Dictionary:
		return [int(transform_types.get("tk1", nGCMatrixKindNull)), int(transform_types.get("tk2", nGCMatrixKindNull)), int(transform_types.get("tk3", nGCMatrixKindNull))]
	if transform_types is Array:
		var tk: Array = [nGCMatrixKindNull, nGCMatrixKindNull, nGCMatrixKindNull]
		for i in mini(3, transform_types.size()):
			tk[i] = int(transform_types[i])
		return tk
	return [nGCMatrixKindNull, nGCMatrixKindNull, nGCMatrixKindNull]

## WPDesc proc pointer -> Callable (NULL == Callable())
static func _wpManagerGetDescProc(wp_desc: Dictionary, key: String) -> Callable:
	var proc = wp_desc.get(key, null)
	if proc is Callable:
		return proc
	return Callable()

## gcAddDObj3TransformsKind (src/sys/objanim.c 0x8000F2FC): matrix XObjs are render-only.
static func _wpManagerAddDObj3TransformsKind(dobj: DObj, tk1: int, tk2: int, tk3: int) -> void:
	if tk1 != nGCMatrixKindNull:
		Objman.gcAddXObjForDObjFixed(dobj, tk1, 0)
	if tk2 != nGCMatrixKindNull:
		Objman.gcAddXObjForDObjFixed(dobj, tk2, 0)
	if tk3 != nGCMatrixKindNull:
		Objman.gcAddXObjForDObjFixed(dobj, tk3, 0)

## gcSetupCustomDObjs (src/sys/objanim.c 0x8000F590) for weapon DObjDesc trees.
## dobjdesc: Array of {"id", "translate", "rotate", "scale", "dl"(optional)}; a DObjDesc with
## id == DOBJ_ARRAY_MAX (18) terminates the list. When no DObjDesc data was supplied the root
## DObj is still created (gcAddDObjForGObj) with default transforms.
static func _wpManagerSetupCustomDObjs(gobj, dobjdesc, tk1: int, tk2: int, tk3: int) -> void:
	if not (dobjdesc is Array) or dobjdesc.is_empty():
		Lbcommon.lbCommonInitDObj3Transforms(Objman.gcAddDObjForGObj(gobj, null), tk1, tk2, tk3)
		return

	var array_dobjs: Array = []
	var dobj: DObj
	var id: int

	array_dobjs.resize(DOBJ_ARRAY_MAX)

	for i in array_dobjs.size():
		array_dobjs[i] = null

	for desc in dobjdesc:
		var desc_id: int = int(desc.get("id", DOBJ_ARRAY_MAX))

		if desc_id == DOBJ_ARRAY_MAX:
			break

		id = desc_id & 0xFFF

		if id != 0:
			dobj = Objman.gcAddChildForDObj(array_dobjs[id - 1], desc.get("dl", null))
			array_dobjs[id] = dobj
		else:
			dobj = Objman.gcAddDObjForGObj(gobj, desc.get("dl", null))
			array_dobjs[0] = dobj

		if desc_id & 0xF000:
			ObjAnim.gcDecideDObj3TransformsKind(dobj, tk1, tk2, tk3, desc_id & 0xF000)
		else:
			_wpManagerAddDObj3TransformsKind(dobj, tk1, tk2, tk3)

		dobj.translate = desc.get("translate", Vector3.ZERO)
		dobj.rotate = desc.get("rotate", Vector3.ZERO)
		dobj.scale = desc.get("scale", Vector3.ONE)

## gcAddAnimAll (src/sys/objanim.c 0x8000BED8): attach AnimJoint scripts to the DObj tree
## in pre-order. MObj material animations are visual only (no MObjs exist in this port).
static func _wpManagerAddAnimAll(gobj, anim_joints, p_matanim_joints, anim_frame: float) -> void:
	var dobj: DObj = DObjGetStruct(gobj)
	var is_anim_root := true
	var anim_index := 0

	gobj.anim_frame = anim_frame

	while dobj != null:
		if anim_joints != null:
			var anim_joint = anim_joints[anim_index] if anim_index < anim_joints.size() else null

			if anim_joint != null:
				ObjAnim.gcAddDObjAnimJoint(dobj, anim_joint, anim_frame)
				dobj.is_anim_root = is_anim_root
				is_anim_root = false
			else:
				dobj.anim_wait = AOBJ_ANIM_NULL
				dobj.is_anim_root = false

			anim_index += 1

		if p_matanim_joints != null:
			pass # dobj->mobj material animations (render only)

		dobj = ObjAnim.gcGetTreeDObjNext(dobj)
