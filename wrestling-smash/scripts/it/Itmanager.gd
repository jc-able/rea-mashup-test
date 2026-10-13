## 1:1 port of src/it/itmanager.c (ssb-decomp-re): item struct pool, item creation
## (itManagerMakeItem), the VS-mode random item spawner ("appear actor"), container drop
## weights, Poké Ball monster bookkeeping, plus the ITCommonData (relocData file 251) tables.
##
## ---------------------------------------------------------------------------------------
## CALLING CONVENTION (used by every item kind port: it/itcommon, itground, itmonster, itfighter)
## ---------------------------------------------------------------------------------------
##   var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, item_desc, pos, vel, flags)
##     parent_gobj : Fighter / Weapon / Item that spawns the item (null for stage / spawner items)
##     item_desc   : Dictionary (C ITDesc, see below)
##     pos, vel    : Vector3 (C: Vec3f *pos, Vec3f *vel - both read only)
##     flags       : int, ITEM_FLAG_PARENT_* | optional ITEM_FLAG_COLLPROJECT
##     returns     : the new Item (== item_gobj == itGetStruct(item_gobj)) or null when all
##                   ITEM_ALLOC_MAX (16) item structs are in use (exactly like the C NULL return).
##
##   item_desc = {
##     "kind": int,                          # nITKind*
##     "attributes": Dictionary,             # C ITAttributes (src/it/ittypes.h field names); see below
##     "transform_types": {"tk1": int, "tk2": int, "tk3": int},   # or [tk1, tk2, tk3]
##     "attack_state": int,                  # nGMAttackState*
##     "proc_update": Callable, "proc_map": Callable, "proc_hit": Callable,
##     "proc_shield": Callable, "proc_hop": Callable, "proc_setoff": Callable,
##     "proc_reflector": Callable, "proc_damage": Callable,    # Callable() or null == NULL
##   }
##   C ITDesc {p_file, o_attributes} -> attributes are resolved by _itManagerGetDescAttributes():
##     1. item_desc.attributes (or .attr / .o_attributes given as a Dictionary);
##     2. item_desc.o_attributes given as the linker symbol name, e.g. "llITCommonDataBoxItemAttributes"
##        (looked up in gITManagerCommonData == relocData file 251, ITCommonData);
##     3. otherwise the ITCommonData attributes of item_desc.kind (dITManagerCommonItemAttributes).
##     For kinds whose ITAttributes live in ITCommonData, a supplied attribute Dictionary without a
##     DObjDesc tree ("data" not an Array) is replaced by the ROM-verified table of this file, so the
##     joint tree (DObjGetStruct(item_gobj)->child ...) is built exactly like the C.
##   Procs are called as proc.call(item_gobj) and return sb32 (TRUE destroys the item).
##   ITStatusDesc tables (Itmain.itMainSetStatus) are Arrays of Dictionaries with the same proc_* keys.
##   ITAttackEvent tables (Itmain.itMainUpdateAttackEvent) are Arrays of {timer, angle, damage, size}.
##
##   Itmanager.itManagerMakeItemSetupCommon(parent_gobj, kind, pos, vel, flags) / itManagerMakeItemKind
##   dispatch through dITManagerProcMakeList (Callable(<Itkind class>, &"it<Kind>MakeItem")), whose
##   targets have the signature (parent_gobj, pos: Vector3, vel: Vector3, flags: int) -> item_gobj or null.
##
## Port notes:
##   * ITStruct and its GObj are the same Item object: itManagerMakeItem registers it with
##     Sim.add_gobj(item, nGCCommonLinkIDItem) instead of gcMakeGObjSPAfter (cannot fail).
##   * The C struct pool (ITEM_ALLOC_MAX ITStructs on a free list) is kept as the same LIFO free
##     list of pool slot indices; a struct taken from it is a fresh Item.new(). Fields that
##     itManagerMakeItem does not initialise therefore start from Item defaults instead of the
##     stale contents of the reused C struct (that memory state is not reproducible).
##   * item.visual_kind (port-only) is set from dITManagerVisualKinds[kind] for the render layer.
##   * Model data: DObjDesc trees are built like gcSetupCustomDObjsWithMObj / itManagerSetupItemDObjs;
##     XObj matrix kinds and MObj materials are render-only (Objman/ObjAnim calls kept, no state).
##     AnimJoint tables given as AnimStream Arrays are attached like gcAddAnimAll; a table that is
##     only referenced by symbol name (String) keeps the C control flow but attaches nothing.
class_name Itmanager
extends Port

# // // // // // // // // // // // //
# //            STRUCTS            //
# // // // // // // // // // // // //

## ITRandomWeights (src/it/ittypes.h) - random item drop table
class ITRandomWeights:
	var unused: Array = [0, 0, 0, 0, 0, 0, 0, 0]    # u8 unused[0x8]
	var valids_num: int = 0                         # u8: number of entries in kinds / blocks
	var kinds: Array = []                           # u8 *: item kinds that can be spawned
	var weights_sum: int = 0                        # u16: sum of all toggled items' weights
	var blocks: Array = []                          # u16 *: cumulative weight block starts

## ITAppearActor (src/it/ittypes.h) - VS-mode random item spawner state
class ITAppearActor:
	var mapobjs_num: int = 0                        # u8: number of item spawn points
	var mapobjs: Array = []                         # u8 *: item spawn point map object IDs
	var spawn_wait: int = 0                         # u32: spawn a random item when this reaches 0
	var weights: ITRandomWeights = ITRandomWeights.new()

## ITMonsterData (src/it/ittypes.h) - Poké Ball monster selection state
class ITMonsterData:
	var monster_curr: int = 0                       # u8
	var monster_prev: int = 0                       # u8
	var monster_id: Array = []                      # u8 monster_id[44]
	var monsters_num: int = 0                       # u8

	func _init() -> void:
		monster_id.resize(44)
		monster_id.fill(0)

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x80189450 - 0 spawns random, non-0 spawns Pokémon item ID of dITManagerForceMonsterKind + (nITMBallMonsterStart - 1)
static var dITManagerForceMonsterKind: int = 0

## 0x80189454 - u16, indexed by gSCManagerBattleState->item_appearance_rate (I_SEC_TO_TICS(q) == q * 60)
static var dITManagerAppearanceRatesMin: Array = [
	0 * 60,
	30 * 60,
	25 * 60,
	20 * 60,
	15 * 60,
	10 * 60,
]

## 0x80189460
static var dITManagerAppearanceRatesMax: Array = [
	0 * 60,
	(30 * 60) + 90,
	(25 * 60) + 75,
	(20 * 60) + 60,
	(15 * 60) + 45,
	(10 * 60) + 30,
]

## 0x8018946C - GObj* (*)(GObj *parent_gobj, Vec3f *pos, Vec3f *vel, u32 flags), indexed by nITKind*
static var dITManagerProcMakeList: Array = [
	# Containers
	Callable(Itbox, &"itBoxMakeItem"),                    # Box
	Callable(Ittaru, &"itTaruMakeItem"),                  # Barrel
	Callable(Itcapsule, &"itCapsuleMakeItem"),            # Capsule
	Callable(Itegg, &"itEggMakeItem"),                    # Egg

	# Usable items
	Callable(Ittomato, &"itTomatoMakeItem"),              # Maxim Tomato
	Callable(Itheart, &"itHeartMakeItem"),                # Heart Container
	Callable(Itstar, &"itStarMakeItem"),                  # Star Man
	Callable(Itsword, &"itSwordMakeItem"),                # Beam Sword
	Callable(Itbat, &"itBatMakeItem"),                    # Home Run Bat
	Callable(Itharisen, &"itHarisenMakeItem"),            # Fan
	Callable(Itstarrod, &"itStarRodMakeItem"),            # Star Rod
	Callable(Itlgun, &"itLGunMakeItem"),                  # Ray Gun
	Callable(Itfflower, &"itFFlowerMakeItem"),            # Fire Flower
	Callable(Ithammer, &"itHammerMakeItem"),              # Hammer
	Callable(Itmsbomb, &"itMSBombMakeItem"),              # Motion-sensor Bomb
	Callable(Itbombhei, &"itBombHeiMakeItem"),            # Bob-omb
	Callable(Itnbumper, &"itNBumperMakeItem"),            # Normal Bumper
	Callable(Itgshell, &"itGShellMakeItem"),              # Green Shell
	Callable(Itrshell, &"itRShellMakeItem"),              # Red Shell
	Callable(Itmball, &"itMBallMakeItem"),                # Poké Ball

	# Fighter items
	Callable(),                                           # Ness' PK Fire
	Callable(),                                           # Link's Bomb

	# Stage items
	Callable(Itpowerblock, &"itPowerBlockMakeItem"),      # Mushroom Kingdom POW Block
	Callable(Itgbumper, &"itGBumperMakeItem"),            # Common Stage Bumper
	Callable(Itpakkun, &"itPakkunMakeItem"),              # Mushroom Kingdom Piranha Plant
	Callable(Ittarget, &"itTargetMakeItem"),              # Bonus Stage Target
	Callable(Ittarubomb, &"itTaruBombMakeItem"),          # Race to the Finish Bomb
	Callable(Itglucky, &"itGLuckyMakeItem"),              # Saffron City Chansey
	Callable(Itmarumine, &"itMarumineMakeItem"),          # Saffron City Electrode
	Callable(Ithitokage, &"itHitokageMakeItem"),          # Saffron City Charmander
	Callable(Itfushigibana, &"itFushigibanaMakeItem"),    # Saffron City Venusaur
	Callable(Itporygon, &"itPorygonMakeItem"),            # Saffron City Porygon

	# Pokémon items
	Callable(Itiwark, &"itIwarkMakeItem"),                # Poké Ball Onix
	Callable(Itkabigon, &"itKabigonMakeItem"),            # Poké Ball Snorlax
	Callable(Ittosakinto, &"itTosakintoMakeItem"),        # Poké Ball Goldeen
	Callable(Itnyars, &"itNyarsMakeItem"),                # Poké Ball Meowth
	Callable(Itlizardon, &"itLizardonMakeItem"),          # Poké Ball Charizard
	Callable(Itspear, &"itSpearMakeItem"),                # Poké Ball Beedrill
	Callable(Itkamex, &"itKamexMakeItem"),                # Poké Ball Blastoise
	Callable(Itmlucky, &"itMLuckyMakeItem"),              # Poké Ball Chansey
	Callable(Itstarmie, &"itStarmieMakeItem"),            # Poké Ball Starmie
	Callable(Itsawamura, &"itSawamuraMakeItem"),          # Poké Ball Hitmonlee
	Callable(Itdogas, &"itDogasMakeItem"),                # Poké Ball Koffing
	Callable(Itpippi, &"itPippiMakeItem"),                # Poké Ball Clefairy
	Callable(Itmew, &"itMewMakeItem"),                    # Poké Ball Mew
]

## Port-only: item.visual_kind per nITKind* (placeholder model id for the render layer).
const dITManagerVisualKinds: Array = [
	"box", "taru", "capsule", "egg",
	"tomato", "heart", "star", "sword", "bat", "harisen", "starrod", "lgun", "fflower", "hammer",
	"msbomb", "bombhei", "nbumper", "gshell", "rshell", "mball",
	"nesspkfire", "linkbomb",
	"powerblock", "gbumper", "pakkun", "target", "tarubomb",
	"glucky", "marumine", "hitokage", "fushigibana", "porygon",
	"iwark", "kabigon", "tosakinto", "nyars", "lizardon", "spear", "kamex", "mlucky",
	"starmie", "sawamura", "dogas", "pippi", "mew",
]

# // // // // // // // // // // // //
# //   GLOBAL / STATIC VARIABLES   //
# // // // // // // // // // // // //

## 0x8018D040 - the loaded ITCommonData file (relocData 251). Port: linker symbol -> table of this
## file, i.e. lbRelocGetFileData(T, gITManagerCommonData, &llX) == gITManagerCommonData["llX"]
## (see itManagerGetCommonData). Set up by itManagerInitItems.
static var gITManagerCommonData: Dictionary = {}

## 0x8018D044
static var gITManagerParticleBankID: int = 0

## 0x8018D048
static var gITManagerRandomWeights: ITRandomWeights = ITRandomWeights.new()

## 0x8018D060
static var gITManagerMonsterData: ITMonsterData = ITMonsterData.new()

## 0x8018D090
static var gITManagerDisplayMode: int = nDBDisplayModeMaster

## 0x8018D094 - points to next available item struct.
## Port: the C free list as a LIFO stack of ITStruct pool slot indices (list head == last element).
## It starts in the state itManagerInitItems() leaves it in; scenes call itManagerInitItems() at
## battle start exactly like the C scenes.
static var gITManagerStructsAllocFree: Array = _itManagerMakeStructsAllocFree()

## 0x8018D098
static var gITManagerAppearActor: ITAppearActor = ITAppearActor.new()

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8016DEA0
static func itManagerInitItems() -> void: # Many linker things here
	# gITManagerStructsAllocFree = ip = syTaskmanMalloc(sizeof(ITStruct) * ITEM_ALLOC_MAX, 0x8);
	# ip[i].next = &ip[i + 1]; ip[ITEM_ALLOC_MAX - 1].next = NULL;
	gITManagerStructsAllocFree = _itManagerMakeStructsAllocFree()

	# gITManagerCommonData = lbRelocGetExternHeapFile(&llITCommonDataFileID, ...);
	gITManagerCommonData = _itManagerMakeCommonData()

	gITManagerParticleBankID = int(_itManagerInt(Efparticle.efParticleGetLoadBankID
	(
		&"lITManagerParticleScriptBankLo",
		&"lITManagerParticleScriptBankHi",
		&"lITManagerParticleTextureBankLo",
		&"lITManagerParticleTextureBankHi"
	)))
	itManagerSetupContainerDrops()
	itManagerInitMonsterVars()
	Ifcommon.ifCommonItemArrowSetAttr()

	gITManagerDisplayMode = nDBDisplayModeMaster

## 0x8016DFAC
static func itManagerGetNextStructAlloc(): # Set global Item user_data link pointer to next member
	var new_item: Item
	var slot: int

	if gITManagerStructsAllocFree.is_empty():
		return null

	slot = gITManagerStructsAllocFree.pop_back()

	new_item = Item.new()
	new_item.set_meta(&"it_struct_slot", slot)

	return new_item

## 0x8016DFDC
static func itManagerSetPrevStructAlloc(ip = null) -> void: # Set global Item user_data link pointer to previous member
	# ip->next = gITManagerStructsAllocFree; gITManagerStructsAllocFree = ip;
	# Port guard: a struct can only be put back on the free list once (C would corrupt its list).
	if (ip == null) or not ip.has_meta(&"it_struct_slot") or ip.has_meta(&"it_struct_freed"):
		return
	ip.set_meta(&"it_struct_freed", true)

	gITManagerStructsAllocFree.push_back(int(ip.get_meta(&"it_struct_slot")))

## 0x8016DFF4
## dobjdesc: Array of DObjDesc Dictionaries {id, dl, translate, rotate, scale} (ends at id DOBJ_ARRAY_MAX).
## dobjs (C: DObj **dobjs, may be NULL): an Array filled in place in DObjDesc order; it is also returned.
static func itManagerSetupItemDObjs(gobj = null, dobjdesc = null, dobjs = null, transform_kind = null):
	var i: int
	var id: int
	var dobj: DObj
	var array_dobjs: Array = []

	array_dobjs.resize(DOBJ_ARRAY_MAX)

	for j in array_dobjs.size():
		array_dobjs[j] = null

	transform_kind = int(transform_kind) & 0xFF if transform_kind != null else nGCMatrixKindNull

	i = 0

	while (i < dobjdesc.size()) and (int(dobjdesc[i].id) != array_dobjs.size()):
		var desc: Dictionary = dobjdesc[i]

		id = int(desc.id) & 0xFFF

		if id != 0:
			dobj = Objman.gcAddChildForDObj(array_dobjs[id - 1], desc.get("dl", null))
			array_dobjs[id] = dobj
		else:
			dobj = Objman.gcAddDObjForGObj(gobj, desc.get("dl", null))
			array_dobjs[0] = dobj

		if i == 1:
			ObjAnim.gcDecideDObj3TransformsKind(dobj, transform_kind, nGCMatrixKindNull, nGCMatrixKindNull, nGCMatrixKindNull)

		elif transform_kind != nGCMatrixKindNull:
			Objman.gcAddXObjForDObjFixed(dobj, transform_kind, nGCMatrixKindNull)

		dobj.translate = desc.translate
		dobj.rotate = desc.rotate
		dobj.scale = desc.scale

		if dobjs is Array:
			if i < dobjs.size():
				dobjs[i] = dobj
			else:
				dobjs.append(dobj)
		i += 1

	return dobjs

## 0x8016E174
static func itManagerMakeItem(parent_gobj = null, item_desc = null, pos = null, vel = null, flags = null):
	var ip = itManagerGetNextStructAlloc()
	var item_gobj
	var attr: Dictionary
	var proc_display: Callable
	var tk: Array
	var spawn_flags: int = int(flags) if flags != null else 0

	if ip == null:
		return null

	# item_gobj = gcMakeGObjSPAfter(nGCCommonKindItem, NULL, nGCCommonLinkIDItem, GOBJ_PRIORITY_DEFAULT);
	item_gobj = ip
	item_gobj.gobj_kind = nGCCommonKindItem
	Sim.add_gobj(item_gobj, nGCCommonLinkIDItem)

	# if (item_gobj == NULL) { itManagerSetPrevStructAlloc(ip); return NULL; } - cannot fail in this port

	attr = _itManagerGetDescAttributes(item_desc)

	if B(attr.get("is_display_colanim", 0)):
		proc_display = Callable(Itdisplay, &"itDisplayColAnimXLUProcDisplay") if B(attr.get("is_display_xlu", 0)) else Callable(Itdisplay, &"itDisplayColAnimOPAProcDisplay")
	else:
		proc_display = Callable(Itdisplay, &"itDisplayXLUProcDisplay") if B(attr.get("is_display_xlu", 0)) else Callable(Itdisplay, &"itDisplayOPAProcDisplay")

	Objman.gcAddGObjDisplay(item_gobj, proc_display, 11, GOBJ_PRIORITY_DEFAULT, ~0)

	item_gobj.user_data = ip

	ip.item_gobj = item_gobj
	ip.owner_gobj = null

	ip.kind = int(item_desc.get("kind", 0))
	ip.type = int(attr.get("type", 0))

	# Port-only: placeholder model id for the render layer
	ip.visual_kind = dITManagerVisualKinds[ip.kind] if (ip.kind >= 0) and (ip.kind < dITManagerVisualKinds.size()) else ""
	item_gobj.debug_name = ip.visual_kind

	ip.physics.vel_air = vel
	ip.physics.vel_ground = 0.0

	ip.attr = attr

	Itmain.itMainSetSpinVelLR(item_gobj)
	Itmain.itMainResetPlayerVars(item_gobj)

	ip.is_allow_pickup = FALSE
	ip.is_hold = FALSE
	ip.is_allow_knockback = FALSE
	ip.is_unused_item_bool = FALSE
	ip.is_static_damage = FALSE

	ip.pickup_wait = ITEM_PICKUP_WAIT_DEFAULT

	ip.percent_damage = 0
	ip.hitlag_tics = 0
	ip.damage_highest = 0
	ip.damage_knockback = 0.0
	ip.damage_queue = 0
	ip.damage_lag = 0

	ip.times_landed = 0
	ip.times_thrown = 0

	ip.weight = int(attr.get("weight", 0)) & 1
	ip.is_hitlag_victim = int(attr.get("is_give_hitlag", 0)) & 1
	ip.drop_sfx = int(attr.get("drop_sfx", 0)) & 0xFFFF
	ip.throw_sfx = int(attr.get("throw_sfx", 0)) & 0xFFFF
	ip.smash_sfx = int(attr.get("smash_sfx", 0)) & 0xFFFF

	ip.vel_scale = f32(int(attr.get("vel_scale", 0)) * f32(0.01)) # F_PCT_TO_DEC(attr->vel_scale)

	ip.is_damage_all = FALSE
	ip.is_thrown = FALSE # Applies magnitude and stale multiplier if TRUE and hitbox is active?
	ip.is_attach_surface = FALSE

	ip.spin_step = 0.0

	ip.arrow_gobj = null
	ip.arrow_timer = 0

	ip.attack_coll.attack_state = int(item_desc.get("attack_state", nGMAttackStateOff))
	ip.attack_coll.damage = int(attr.get("damage", 0))
	ip.attack_coll.throw_mul = 1.0
	ip.attack_coll.stale = 1.0
	ip.attack_coll.element = int(attr.get("element", 0))
	ip.attack_coll.offsets[0] = Vector3(int(attr.get("attack_offset0_x", 0)), int(attr.get("attack_offset0_y", 0)), int(attr.get("attack_offset0_z", 0)))
	ip.attack_coll.offsets[1] = Vector3(int(attr.get("attack_offset1_x", 0)), int(attr.get("attack_offset1_y", 0)), int(attr.get("attack_offset1_z", 0)))
	ip.attack_coll.size = int(attr.get("size", 0)) * 0.5
	ip.attack_coll.angle = int(attr.get("angle", 0))
	ip.attack_coll.knockback_scale = int(attr.get("knockback_scale", 0))
	ip.attack_coll.knockback_weight = int(attr.get("knockback_weight", 0))
	ip.attack_coll.knockback_base = int(attr.get("knockback_base", 0))
	ip.attack_coll.can_setoff = int(attr.get("can_setoff", 0)) & 1
	ip.attack_coll.shield_damage = int(attr.get("shield_damage", 0))
	ip.attack_coll.fgm_id = int(attr.get("hit_sfx", 0)) & 0xFFFF
	ip.attack_coll.priority = int(attr.get("priority", 0))
	ip.attack_coll.can_rehit_item = int(attr.get("can_rehit_item", 0)) & 1
	ip.attack_coll.can_rehit_fighter = int(attr.get("can_rehit_fighter", 0)) & 1
	ip.attack_coll.can_rehit_shield = FALSE
	ip.attack_coll.can_hop = int(attr.get("can_hop", 0)) & 1
	ip.attack_coll.can_reflect = int(attr.get("can_reflect", 0)) & 1
	ip.attack_coll.can_shield = int(attr.get("can_shield", 0)) & 1
	ip.attack_coll.attack_count = int(attr.get("attack_count", 0))
	ip.attack_coll.interact_mask = GMHITCOLLISION_FLAG_ALL

	ip.attack_coll.motion_attack_id = nFTMotionAttackIDNone
	ip.attack_coll.motion_count = Ftparam.ftParamGetMotionCount()
	ip.attack_coll.stat_flags.attack_id = nFTStatusAttackIDNull
	ip.attack_coll.stat_flags.is_projectile = 0
	ip.attack_coll.stat_flags.ga = 0
	ip.attack_coll.stat_flags.is_smash_attack = 0
	ip.attack_coll.stat_count = Ftparam.ftParamGetStatUpdateCount()

	Itmain.itMainClearAttackRecord(ip)

	var damage_coll_offset: Vector3 = attr.get("damage_coll_offset", Vector3.ZERO)
	var damage_coll_size: Vector3 = attr.get("damage_coll_size", Vector3.ZERO)

	ip.damage_coll.hitstatus = int(attr.get("hitstatus", 0))
	ip.damage_coll.offset.x = damage_coll_offset.x
	ip.damage_coll.offset.y = damage_coll_offset.y
	ip.damage_coll.offset.z = damage_coll_offset.z
	ip.damage_coll.size.x = damage_coll_size.x * 0.5
	ip.damage_coll.size.y = damage_coll_size.y * 0.5
	ip.damage_coll.size.z = damage_coll_size.z * 0.5
	ip.damage_coll.interact_mask = GMHITCOLLISION_FLAG_ALL

	ip.shield_collide_angle = 0.0
	ip.shield_collide_dir.x = 0.0
	ip.shield_collide_dir.y = 0.0
	ip.shield_collide_dir.z = 0.0

	ip.hit_normal_damage = 0
	ip.hit_refresh_damage = 0
	ip.hit_attack_damage = 0
	ip.hit_shield_damage = 0

	ip.reflect_gobj = null

	tk = _itManagerGetTransformTypes(item_desc.get("transform_types", null))

	var data = attr.get("data", null)

	if data != null:
		if data is Array:
			if not B(attr.get("is_item_dobjs", 0)):
				_itManagerSetupCustomDObjsWithMObj(item_gobj, data, attr.get("p_mobjsubs", null), null, tk[0], tk[1], tk[2])
			else:
				itManagerSetupItemDObjs(item_gobj, data, null, tk[0])

				if attr.get("p_mobjsubs", null) != null:
					_itManagerAddMObjAll(item_gobj, attr.get("p_mobjsubs", null))

			if (attr.get("anim_joints", null) != null) or (attr.get("p_matanim_joints", null) != null):
				_itManagerAddAnimAll(item_gobj, attr.get("anim_joints", null), attr.get("p_matanim_joints", null), 0.0)
				ObjAnim.gcPlayAnimAll(item_gobj)

			Lbcommon.lbCommonEjectTreeDObj(DObjGetStruct(item_gobj))
		else:
			# Port: model referenced without an exported DObjDesc tree -> a single root joint
			# (the C builds the DObjDesc tree and ejects its dummy root here).
			Objman.gcAddDObjForGObj(item_gobj, data)

			if (attr.get("anim_joints", null) != null) or (attr.get("p_matanim_joints", null) != null):
				_itManagerAddAnimAll(item_gobj, attr.get("anim_joints", null), attr.get("p_matanim_joints", null), 0.0)
				ObjAnim.gcPlayAnimAll(item_gobj)
	else:
		Objman.gcAddDObjForGObj(item_gobj, null)

	# ip->coll_data.p_translate = &DObjGetStruct(item_gobj)->translate.vec.f; ip->coll_data.p_lr = &ip->lr;
	# (MPCollData.p_translate / p_lr are bound to their owner: ip.coll_data.owner == ip.)
	ip.coll_data.owner = ip
	ip.coll_data.map_coll.top = int(attr.get("map_coll_top", 0))
	ip.coll_data.map_coll.center = int(attr.get("map_coll_center", 0))
	ip.coll_data.map_coll.bottom = int(attr.get("map_coll_bottom", 0))
	ip.coll_data.map_coll.width = int(attr.get("map_coll_width", 0))
	ip.coll_data.p_map_coll = ip.coll_data.map_coll
	ip.coll_data.ignore_line_id = -1
	ip.coll_data.update_tic = Mpcollision.gMPCollisionUpdateTic
	ip.coll_data.mask_curr = 0
	ip.coll_data.vel_push.x = 0.0
	ip.coll_data.vel_push.y = 0.0
	ip.coll_data.vel_push.z = 0.0

	Objman.gcAddGObjProcess(item_gobj, Callable(Itprocess, &"itProcessProcItemMain"), nGCProcessKindFunc, 3)
	Objman.gcAddGObjProcess(item_gobj, Callable(Itprocess, &"itProcessProcSearchHitAll"), nGCProcessKindFunc, 1)
	Objman.gcAddGObjProcess(item_gobj, Callable(Itprocess, &"itProcessProcHitCollisions"), nGCProcessKindFunc, 0)

	ip.proc_update = _itManagerGetDescProc(item_desc, "proc_update")
	ip.proc_map = _itManagerGetDescProc(item_desc, "proc_map")
	ip.proc_hit = _itManagerGetDescProc(item_desc, "proc_hit")
	ip.proc_shield = _itManagerGetDescProc(item_desc, "proc_shield")
	ip.proc_hop = _itManagerGetDescProc(item_desc, "proc_hop")
	ip.proc_setoff = _itManagerGetDescProc(item_desc, "proc_setoff")
	ip.proc_reflector = _itManagerGetDescProc(item_desc, "proc_reflector")
	ip.proc_damage = _itManagerGetDescProc(item_desc, "proc_damage")
	ip.proc_dead = Callable()

	DObjGetStruct(item_gobj).translate = pos
	ip.coll_data.pos_prev = DObjGetStruct(item_gobj).translate

	if spawn_flags & ITEM_FLAG_COLLPROJECT:
		match spawn_flags & ITEM_MASK_PARENT:
			ITEM_FLAG_PARENT_GROUND, ITEM_FLAG_PARENT_DEFAULT: # Default?
				pass

			ITEM_FLAG_PARENT_FIGHTER:
				Mpcommon.mpCommonRunItemCollisionDefault(item_gobj, ftGetStruct(parent_gobj).coll_data.p_translate, ftGetStruct(parent_gobj).coll_data)

			ITEM_FLAG_PARENT_WEAPON:
				Mpcommon.mpCommonRunItemCollisionDefault(item_gobj, wpGetStruct(parent_gobj).coll_data.p_translate, wpGetStruct(parent_gobj).coll_data)

			ITEM_FLAG_PARENT_ITEM:
				Mpcommon.mpCommonRunItemCollisionDefault(item_gobj, itGetStruct(parent_gobj).coll_data.p_translate, itGetStruct(parent_gobj).coll_data)

			_:
				pass

	ip.ga = nMPKineticsAir

	Itprocess.itProcessUpdateAttackPositions(item_gobj)
	Itmain.itMainClearColAnim(item_gobj)

	return item_gobj

## 0x8016EA78
static func itManagerMakeItemSetupCommon(parent_gobj = null, index = null, pos = null, vel = null, spawn_flags = null):
	var item_gobj = _itManagerCallMakeProc(int(index), parent_gobj, pos, vel, spawn_flags)

	if item_gobj != null:
		if int(index) <= nITKindCommonEnd:
			Efmanager.efManagerItemSpawnSwirlMakeEffect(pos)
			Itmain.itMainSetAppearSpin(item_gobj, FALSE)

	return item_gobj

## 0x8016EB00 - C returns the free-list head (NULL when every item struct is in use).
## Port: the head pool slot index, or null.
static func itManagerGetCurrentAlloc():
	if gITManagerStructsAllocFree.is_empty():
		return null

	return gITManagerStructsAllocFree.back()

## 0x8016EB0C
static func itManagerSetItemSpawnWait() -> void:
	var rate: int = G.gSCManagerBattleState.item_appearance_rate

	gITManagerAppearActor.spawn_wait = (
		int(dITManagerAppearanceRatesMin[rate]) +
		syUtilsRandIntRange
		(
			int(dITManagerAppearanceRatesMax[rate]) - int(dITManagerAppearanceRatesMin[rate])
		)
	) & 0xFFFFFFFF

## 0x8016EB78
static func itManagerAppearActorProcUpdate(item_gobj = null) -> void:
	var kind: int
	var pos: Vector3
	var vel: Vector3

	if G.gSCManagerBattleState.game_status != nSCBattleGameStatusWait:
		if gITManagerAppearActor.spawn_wait > 0:
			gITManagerAppearActor.spawn_wait -= 1

			return

		if itManagerGetCurrentAlloc() != null:
			kind = Itmain.itMainGetWeightedItemKind(gITManagerAppearActor.weights)

			pos = Mpcollision.mpCollisionGetMapObjPositionID(gITManagerAppearActor.mapobjs[syUtilsRandIntRange(gITManagerAppearActor.mapobjs_num)])

			vel.x = 0.0
			vel.y = 0.0
			vel.z = 0.0

			Snd.func_800269C0_275C0(nSYAudioFGMItemSpawn1)

			itManagerMakeItemSetupCommon(null, kind, pos, vel, ITEM_FLAG_PARENT_DEFAULT)

		itManagerSetItemSpawnWait()

## 0x8016EC40 - create item spawner GObj
static func itManagerMakeAppearActor():
	var gobj
	var i: int
	var item_any_weights: int       # Sum of all toggled item weights of ANY value
	var p_any_weights               # MPItemWeights *
	var weights_sum: int
	var mapobjs_num: int
	var item_mapobj_ids: Array = [] # s32 item_mapobj_ids[30]
	var item_valid_weights: int     # Sum of all toggled NON-ZERO item weights
	var item_valid_toggles: int
	var p_valid_weights             # MPItemWeights *
	var item_any_toggles: int
	var ground_data = Mpcollision.gMPCollisionGroundData

	item_mapobj_ids.resize(30)
	item_mapobj_ids.fill(0)

	if G.gSCManagerBattleState.item_appearance_rate != nSCBattleItemSwitchNone:
		if G.gSCManagerBattleState.item_toggles != 0:
			if (ground_data != null) and (ground_data.get("item_weights") != null): # port guard: no stage loaded
				p_any_weights = ground_data.item_weights
				item_any_toggles = G.gSCManagerBattleState.item_toggles & 0xFFFFFFFF

				item_any_weights = 0

				i = nITKindCommonStart

				while i <= nITKindCommonEnd:
					if item_any_toggles & 1:
						item_any_weights += int(p_any_weights.values[i])
					i += 1
					item_any_toggles >>= 1

				if item_any_weights == 0:
					return null

				gITManagerAppearActor.weights.weights_sum = item_any_weights & 0xFFFF

				mapobjs_num = Mpcollision.mpCollisionGetMapObjCountKind(nMPMapObjKindItem)

				if mapobjs_num == 0:
					return null

				if mapobjs_num > item_mapobj_ids.size():
					# while (TRUE) { syDebugPrintf("Item positions are over %d!\n", 30); scManagerRunPrintGObjStatus(); }
					Debug.syDebugPrintf("Item positions are over %d!\n" % item_mapobj_ids.size())
					push_error("Itmanager: Item positions are over %d!" % item_mapobj_ids.size())
					return null

				gITManagerAppearActor.mapobjs_num = mapobjs_num & 0xFF
				gITManagerAppearActor.mapobjs = [] # syTaskmanMalloc(mapobjs_num * sizeof(u8), 0)
				gITManagerAppearActor.mapobjs.resize(mapobjs_num)

				item_mapobj_ids = Mpcollision.mpCollisionGetMapObjIDsKind(nMPMapObjKindItem, item_mapobj_ids)

				for j in mapobjs_num:
					gITManagerAppearActor.mapobjs[j] = int(item_mapobj_ids[j]) & 0xFF

				gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindItem, null, nGCCommonLinkIDItemActor, GOBJ_PRIORITY_DEFAULT)

				Objman.gcAddGObjProcess(gobj, Callable(Itmanager, &"itManagerAppearActorProcUpdate"), nGCProcessKindFunc, 3)

				item_valid_toggles = G.gSCManagerBattleState.item_toggles & 0xFFFFFFFF
				p_valid_weights = ground_data.item_weights

				i = nITKindCommonStart
				item_valid_weights = 0

				while i <= nITKindCommonEnd:
					if (item_valid_toggles & 1) and (int(p_valid_weights.values[i]) != 0):
						item_valid_weights += 1
					i += 1
					item_valid_toggles >>= 1

				gITManagerAppearActor.weights.valids_num = item_valid_weights & 0xFF
				gITManagerAppearActor.weights.kinds = [] # syTaskmanMalloc(item_valid_weights * sizeof(u8), 0x0)
				gITManagerAppearActor.weights.kinds.resize(item_valid_weights)
				gITManagerAppearActor.weights.kinds.fill(0)
				gITManagerAppearActor.weights.blocks = [] # syTaskmanMalloc(item_valid_weights * sizeof(u16), 0x2)
				gITManagerAppearActor.weights.blocks.resize(item_valid_weights)
				gITManagerAppearActor.weights.blocks.fill(0)

				item_valid_toggles = G.gSCManagerBattleState.item_toggles & 0xFFFFFFFF
				weights_sum = 0

				i = nITKindCommonStart
				item_valid_weights = 0

				while i <= nITKindCommonEnd:
					if (item_valid_toggles & 1) and (int(p_valid_weights.values[i]) != 0):
						gITManagerAppearActor.weights.kinds[item_valid_weights] = i
						gITManagerAppearActor.weights.blocks[item_valid_weights] = weights_sum & 0xFFFF
						weights_sum += int(p_valid_weights.values[i])

						item_valid_weights += 1
					i += 1
					item_valid_toggles >>= 1

				itManagerSetItemSpawnWait()

				return gobj
	return null

## 0x8016EF40
static func itManagerSetupContainerDrops() -> void:
	var item_tenth_round: int
	var item_tenth_floor: int
	var item_any_weights: int       # Sum of all toggled item weights of ANY value
	var item_any_toggles: int
	var item_valid_toggles: int
	var item_valid_weights: int     # Sum of all toggled NON-ZERO item weights
	var weights_sum: int
	var p_any_weights               # MPItemWeights *
	var p_valid_weights             # MPItemWeights *
	var i: int
	var ground_data = Mpcollision.gMPCollisionGroundData

	if (G.gSCManagerBattleState.item_appearance_rate != nSCBattleItemSwitchNone) and (G.gSCManagerBattleState.item_toggles != 0) and (ground_data != null) and (ground_data.get("item_weights") != null):
		item_any_toggles = (G.gSCManagerBattleState.item_toggles & 0xFFFFFFFF) >> nITKindUtilityStart
		p_any_weights = ground_data.item_weights

		item_any_weights = 0

		i = nITKindUtilityStart

		while i <= nITKindUtilityEnd:
			if item_any_toggles & 1:
				item_any_weights += int(p_any_weights.values[i])
			i += 1
			item_any_toggles >>= 1

		gITManagerRandomWeights.weights_sum = item_any_weights & 0xFFFF

		if item_any_weights != 0:
			item_valid_toggles = (G.gSCManagerBattleState.item_toggles & 0xFFFFFFFF) >> nITKindUtilityStart
			p_valid_weights = ground_data.item_weights

			item_valid_weights = 0
			i = nITKindUtilityStart

			while i <= nITKindUtilityEnd:
				if (item_valid_toggles & 1) and (int(p_valid_weights.values[i]) != 0):
					item_valid_weights += 1
				i += 1
				item_valid_toggles >>= 1

			item_valid_weights += 1
			gITManagerRandomWeights.valids_num = item_valid_weights & 0xFF
			gITManagerRandomWeights.kinds = [] # syTaskmanMalloc(item_valid_weights * sizeof(u8), 0x0)
			gITManagerRandomWeights.kinds.resize(item_valid_weights)
			gITManagerRandomWeights.kinds.fill(0)
			gITManagerRandomWeights.blocks = [] # syTaskmanMalloc(item_valid_weights * sizeof(u16), 0x2)
			gITManagerRandomWeights.blocks.resize(item_valid_weights)
			gITManagerRandomWeights.blocks.fill(0)

			item_valid_toggles = (G.gSCManagerBattleState.item_toggles & 0xFFFFFFFF) >> nITKindUtilityStart
			weights_sum = 0

			item_valid_weights = 0
			i = nITKindUtilityStart

			while i <= nITKindUtilityEnd:
				if (item_valid_toggles & 1) and (int(p_valid_weights.values[i]) != 0):
					gITManagerRandomWeights.kinds[item_valid_weights] = i
					gITManagerRandomWeights.blocks[item_valid_weights] = weights_sum & 0xFFFF

					weights_sum += int(p_valid_weights.values[i])
					item_valid_weights += 1
				i += 1
				item_valid_toggles >>= 1

			gITManagerRandomWeights.kinds[item_valid_weights] = nITKindMBallMonsterStart
			gITManagerRandomWeights.blocks[item_valid_weights] = weights_sum & 0xFFFF

			# item_tenth_round = (gITManagerRandomWeights.weights_sum * 0.1F); (f32 multiply, truncated)
			item_tenth_round = int(f32(gITManagerRandomWeights.weights_sum * f32(0.1)))

			if item_tenth_round != 0:
				item_tenth_floor = item_tenth_round
			else:
				item_tenth_floor = 1

			gITManagerRandomWeights.weights_sum = (gITManagerRandomWeights.weights_sum + item_tenth_floor) & 0xFFFF
	else:
		gITManagerRandomWeights.weights_sum = 0

## 0x8016F218
static func itManagerInitMonsterVars() -> void:
	gITManagerMonsterData.monster_prev = U8_MAX
	gITManagerMonsterData.monster_curr = gITManagerMonsterData.monster_prev
	gITManagerMonsterData.monsters_num = (nITKindMBallMonsterEnd - nITKindMBallMonsterStart) & 0xFF

## 0x8016F238
static func itManagerMakeItemKind(parent_gobj = null, kind = null, pos = null, vel = null, flags = null):
	return _itManagerCallMakeProc(int(kind), parent_gobj, pos, vel, flags)

# // // // // // // // // // // // //
# //         PORT HELPERS          //
# // // // // // // // // // // // //

## lbRelocGetFileData(T, gITManagerCommonData, &symbol): the table of relocData file 251 named by
## its linker symbol (e.g. "llITCommonDataBoxAttackEvents"), or null.
static func itManagerGetCommonData(symbol):
	if gITManagerCommonData.is_empty():
		gITManagerCommonData = _itManagerMakeCommonData()

	return gITManagerCommonData.get(StringName(str(symbol)), null)

## C: dITManagerProcMakeList[index](parent_gobj, pos, vel, flags) - a NULL entry (PK Fire / Link Bomb)
## would jump to address 0 on the N64; the port reports it and returns NULL.
static func _itManagerCallMakeProc(index: int, parent_gobj, pos, vel, flags):
	if (index < 0) or (index >= dITManagerProcMakeList.size()) or not dITManagerProcMakeList[index].is_valid():
		push_error("Itmanager: no item maker for item kind %d" % index)
		return null

	return dITManagerProcMakeList[index].call(parent_gobj, pos, vel, flags)

## gITManagerStructsAllocFree after itManagerInitItems: ip[0] -> ip[1] -> ... -> ip[15] -> NULL
static func _itManagerMakeStructsAllocFree() -> Array:
	var free_list: Array = []

	for i in range(ITEM_ALLOC_MAX - 1, -1, -1):
		free_list.append(i)

	return free_list

## Port: values returned by unported stubs may be null.
static func _itManagerInt(v) -> int:
	if (v is int) or (v is float) or (v is bool):
		return int(v)
	return 0

## ITDesc {p_file, o_attributes} -> ITAttributes (see the header).
static func _itManagerGetDescAttributes(item_desc) -> Dictionary:
	var attr = null
	var common = null
	var kind: int = int(item_desc.get("kind", -1))
	var o_attributes = item_desc.get("o_attributes", null)

	if item_desc.get("attributes", null) is Dictionary:
		attr = item_desc.get("attributes")
	elif item_desc.get("attr", null) is Dictionary:
		attr = item_desc.get("attr")
	elif o_attributes is Dictionary:
		attr = o_attributes

	if (o_attributes is String) or (o_attributes is StringName):
		common = itManagerGetCommonData(o_attributes)
	if not (common is Dictionary):
		common = dITManagerCommonItemAttributes.get(kind, null)

	if attr == null:
		if common is Dictionary:
			return common
		push_error("Itmanager: no ITAttributes for item kind %d" % kind)
		return {}
	if (common is Dictionary) and not (attr.get("data", null) is Array):
		return common # ROM-verified ITCommonData table with the item's DObjDesc tree

	return attr

## ITDesc proc pointer -> Callable (NULL == Callable())
static func _itManagerGetDescProc(item_desc, key: String) -> Callable:
	var proc = item_desc.get(key, null)

	if proc is Callable:
		return proc

	return Callable()

## ITDesc.transform_types {tk1, tk2, tk3} (Dictionary or Array) -> [tk1, tk2, tk3]
static func _itManagerGetTransformTypes(transform_types) -> Array:
	if transform_types is Dictionary:
		return [int(transform_types.get("tk1", nGCMatrixKindNull)), int(transform_types.get("tk2", nGCMatrixKindNull)), int(transform_types.get("tk3", nGCMatrixKindNull))]
	if transform_types is Array:
		var tk: Array = [nGCMatrixKindNull, nGCMatrixKindNull, nGCMatrixKindNull]

		for i in mini(3, transform_types.size()):
			tk[i] = int(transform_types[i])
		return tk
	return [nGCMatrixKindNull, nGCMatrixKindNull, nGCMatrixKindNull]

## gcAddDObj3TransformsKind (src/sys/objanim.c): XObj matrix kinds are render-only.
static func _itManagerAddDObj3TransformsKind(dobj: DObj, tk1: int, tk2: int, tk3: int) -> void:
	if tk1 != nGCMatrixKindNull:
		Objman.gcAddXObjForDObjFixed(dobj, tk1, 0)
	if tk2 != nGCMatrixKindNull:
		Objman.gcAddXObjForDObjFixed(dobj, tk2, 0)
	if tk3 != nGCMatrixKindNull:
		Objman.gcAddXObjForDObjFixed(dobj, tk3, 0)

## gcSetupCustomDObjsWithMObj (src/sys/objanim.c 0x8000F720) for item DObjDesc trees.
## MObj materials (p_mobjsubs) are render-only and not modelled by this port's DObj.
static func _itManagerSetupCustomDObjsWithMObj(gobj, dobjdesc: Array, p_mobjsubs, dobjs, tk1: int, tk2: int, tk3: int) -> void:
	var array_dobjs: Array = []
	var dobj: DObj
	var id: int

	array_dobjs.resize(DOBJ_ARRAY_MAX)

	for i in array_dobjs.size():
		array_dobjs[i] = null

	for desc in dobjdesc:
		var desc_id: int = int(desc.id)

		if desc_id == array_dobjs.size():
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
			_itManagerAddDObj3TransformsKind(dobj, tk1, tk2, tk3)

		dobj.translate = desc.translate
		dobj.rotate = desc.rotate
		dobj.scale = desc.scale

		# if (p_mobjsubs != NULL) { ... gcAddMObjForDObj(dobj, mobjsub) ... } - render-only

		if dobjs is Array:
			dobjs.append(dobj)

## gcAddMObjAll (src/sys/objanim.c): MObj materials are render-only.
static func _itManagerAddMObjAll(gobj, p_mobjsubs) -> void:
	if p_mobjsubs is Array:
		ObjAnim.gcAddMObjAll(gobj, p_mobjsubs)

## gcAddAnimAll (src/sys/objanim.c 0x8000BED8): attach AnimJoint scripts (AnimStream, one per
## joint in tree pre-order) to the item's DObj tree. Material animations are render-only.
## A table referenced only by its symbol name (String) has no exported scripts: every joint
## gets AOBJ_ANIM_NULL like a NULL table entry.
static func _itManagerAddAnimAll(gobj, anim_joints, p_matanim_joints, anim_frame: float) -> void:
	var dobj: DObj = DObjGetStruct(gobj)
	var is_anim_root: bool = true
	var anim_index: int = 0

	gobj.anim_frame = anim_frame

	while dobj != null:
		if anim_joints != null:
			var anim_joint = null

			if (anim_joints is Array) and (anim_index < anim_joints.size()):
				anim_joint = anim_joints[anim_index]

			if anim_joint is AnimStream:
				ObjAnim.gcAddDObjAnimJoint(dobj, anim_joint, anim_frame)
				dobj.is_anim_root = is_anim_root
				is_anim_root = false
			else:
				dobj.anim_wait = AOBJ_ANIM_NULL
				dobj.is_anim_root = false

			anim_index += 1

		# if (p_matanim_joints != NULL) { ... gcAddMObjMatAnimJoint(mobj, ...) ... } - render-only

		dobj = ObjAnim.gcGetTreeDObjNext(dobj)

## gcSetDObjTransformsForGObj (src/sys/objanim.c): reset the joint transforms of gobj's DObj tree
## (pre-order) from a DObjDesc list. Used by Itmain.itMainSetFighterHold.
static func _itManagerSetDObjTransformsForGObj(gobj, dobjdesc) -> void:
	var dobj: DObj = DObjGetStruct(gobj)
	var i: int = 0

	if not (dobjdesc is Array):
		return # Port: no exported DObjDesc tree for this model

	while (dobj != null) and (i < dobjdesc.size()) and (int(dobjdesc[i].id) != DOBJ_ARRAY_MAX):
		dobj.translate = dobjdesc[i].translate
		dobj.rotate = dobjdesc[i].rotate
		dobj.scale = dobjdesc[i].scale

		i += 1

		dobj = ObjAnim.gcGetTreeDObjNext(dobj)

## gITManagerCommonData: linker symbol -> table (relocData file 251, ITCommonData)
static func _itManagerMakeCommonData() -> Dictionary:
	return {
		&"llITCommonDataContainerVelocitiesY": dITCommonData_Container_VelocitiesY,
		&"llITCommonDataFFlowerFlameAngles": dITCommonData_FFlowerFlame_Angles,

		&"llITCommonDataCapsuleItemAttributes": dITCommonData_Capsule_ItemAttributes,
		&"llITCommonDataTomatoItemAttributes": dITCommonData_Tomato_ItemAttributes,
		&"llITCommonDataHeartItemAttributes": dITCommonData_Heart_ItemAttributes,
		&"llITCommonDataStarItemAttributes": dITCommonData_Star_ItemAttributes,
		&"llITCommonDataSwordItemAttributes": dITCommonData_Sword_ItemAttributes,
		&"llITCommonDataBatItemAttributes": dITCommonData_Bat_ItemAttributes,
		&"llITCommonDataHarisenItemAttributes": dITCommonData_Harisen_ItemAttributes,
		&"llITCommonDataLGunItemAttributes": dITCommonData_LGun_ItemAttributes,
		&"llITCommonDataFFlowerItemAttributes": dITCommonData_FFlower_ItemAttributes,
		&"llITCommonDataHammerItemAttributes": dITCommonData_Hammer_ItemAttributes,
		&"llITCommonDataMSBombItemAttributes": dITCommonData_MSBomb_ItemAttributes,
		&"llITCommonDataBombHeiItemAttributes": dITCommonData_BombHei_ItemAttributes,
		&"llITCommonDataStarRodItemAttributes": dITCommonData_StarRod_ItemAttributes,
		&"llITCommonDataGShellItemAttributes": dITCommonData_GShell_ItemAttributes,
		&"llITCommonDataRShellItemAttributes": dITCommonData_RShell_ItemAttributes,
		&"llITCommonDataBoxItemAttributes": dITCommonData_Box_ItemAttributes,
		&"llITCommonDataTaruItemAttributes": dITCommonData_Taru_ItemAttributes,
		&"llITCommonDataNBumperItemAttributes": dITCommonData_NBumper_ItemAttributes,
		&"llITCommonDataMBallItemAttributes": dITCommonData_MBall_ItemAttributes,
		&"llITCommonDataWarkItemAttributes": dITCommonData_Wark_ItemAttributes,
		&"llITCommonDataKabigonItemAttributes": dITCommonData_Kabigon_ItemAttributes,
		&"llITCommonDataTosakintoItemAttributes": dITCommonData_Tosakinto_ItemAttributes,
		&"llITCommonDataMewItemAttributes": dITCommonData_Mew_ItemAttributes,
		&"llITCommonDataNyarsItemAttributes": dITCommonData_Nyars_ItemAttributes,
		&"llITCommonDataLizardonItemAttributes": dITCommonData_Lizardon_ItemAttributes,
		&"llITCommonDataSpearItemAttributes": dITCommonData_Spear_ItemAttributes,
		&"llITCommonDataKamexItemAttributes": dITCommonData_Kamex_ItemAttributes,
		&"llITCommonDataMLuckyItemAttributes": dITCommonData_MLucky_ItemAttributes,
		&"llITCommonDataEggItemAttributes": dITCommonData_Egg_ItemAttributes,
		&"llITCommonDataStarmieItemAttributes": dITCommonData_Starmie_ItemAttributes,
		&"llITCommonDataSawamuraItemAttributes": dITCommonData_Sawamura_ItemAttributes,
		&"llITCommonDataDogasItemAttributes": dITCommonData_Dogas_ItemAttributes,
		&"llITCommonDataPippiItemAttributes": dITCommonData_Pippi_ItemAttributes,
		&"llITCommonDataGBumperItemAttributes": dITCommonData_GBumper_ItemAttributes,

		&"llITCommonDataLGunAmmoWeaponAttributes": dITCommonData_LGunAmmo_WeaponAttributes,
		&"llITCommonDataFFlowerFlameWeaponAttributes": dITCommonData_FFlowerFlame_WeaponAttributes,
		&"llITCommonDataStarRodWeaponAttributes": dITCommonData_StarRod_WeaponAttributes,
		&"llITCommonDataStarRodSmashWeaponAttributes": dITCommonData_StarRodSmash_WeaponAttributes,
		&"llITCommonDataWarkRockWeaponAttributes": dITCommonData_WarkRock_WeaponAttributes,
		&"llITCommonDataNyarsCoinWeaponAttributes": dITCommonData_NyarsCoin_WeaponAttributes,
		&"llITCommonDataLizardonFlameWeaponAttributes": dITCommonData_LizardonFlame_WeaponAttributes,
		&"llITCommonDataSpearSwarmWeaponAttributes": dITCommonData_SpearSwarm_WeaponAttributes,
		&"llITCommonDataKamexHydroWeaponAttributes": dITCommonData_KamexHydro_WeaponAttributes,
		&"llITCommonDataStarmieSwiftWeaponAttributes": dITCommonData_StarmieSwift_WeaponAttributes,
		&"llITCommonDataDogasSmogWeaponAttributes": dITCommonData_DogasSmog_WeaponAttributes,
		&"llITCommonDataPippiSwarmWeaponAttributes": dITCommonData_PippiSwarm_WeaponAttributes,

		&"llITCommonDataCapsuleAttackEvents": dITCommonData_Capsule_AttackEvents,
		&"llITCommonDataMSBombAttackEvents": dITCommonData_MSBomb_AttackEvents,
		&"llITCommonDataBombHeiAttackEvents": dITCommonData_BombHei_AttackEvents,
		&"llITCommonDataBoxAttackEvents": dITCommonData_Box_AttackEvents,
		&"llITCommonDataTaruAttackEvents": dITCommonData_Taru_AttackEvents,
		&"llITCommonDataEggAttackEvents": dITCommonData_Egg_AttackEvents,
	}

# // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //
# //  RELOC DATA: src/relocData/251_ITCommonData.c (+ DObjDesc trees from 86_ITCommonObject.c)  //
# // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

## src/relocData/251_ITCommonData.c : dITCommonData_Container_VelocitiesY (llITCommonDataContainerVelocitiesY,
## file offset 0x0000) - container drop launch Y velocity per common item kind (itMainMakeContainerItem).
const dITCommonData_Container_VelocitiesY: Array = [26.0, 26.0, 26.0, 26.0, 26.0, 26.0, 26.0, 40.0, 26.0, 26.0, 26.0, 26.0, 26.0, 26.0, 26.0, 26.0, 26.0, 26.0, 26.0, 26.0]

## src/relocData/251_ITCommonData.c : dITCommonData_FFlowerFlame_Angles (llITCommonDataFFlowerFlameAngles, @ 0x0360)
## F_CST_DTOR32(-15, -7.5, 0, 7.5, 15) as stored in the ROM (f32).
const dITCommonData_FFlowerFlame_Angles: Array = [-0.2617993950843811, -0.13089969754219055, 0.0, 0.13089969754219055, 0.2617993950843811]

## src/relocData/251_ITCommonData.c : dITCommonData_LizardonFlame_AngleSpread (@ 0x0978, radians, f32)
const dITCommonData_LizardonFlame_AngleSpread: Array = [-0.2617993950843811, -0.13089969754219055, 0.0, 0.13089969754219055, 0.2617993950843811]

# ---------------------------------------------------------------------------------------
# DObjDesc trees of the common item / item-weapon models (src/relocData/86_ITCommonObject.c).
# {id, dl, translate, rotate, scale}; "dl" is the display-list symbol (render layer only).
# The list ends with the {id: DOBJ_ARRAY_MAX} terminator exactly like the C arrays.
# ---------------------------------------------------------------------------------------
## src/relocData/86_ITCommonObject.c : dITCommonObject_Capsule_Item_data_DObjDesc (@ 0x00670)
const dITCommonObject_Capsule_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, -90.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0x03E0", "translate": Vector3(0.0, 90.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 16386, "dl": "dITCommonObject_Gfx_0x0540", "translate": Vector3(0.0, 45.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 16386, "dl": "dITCommonObject_Gfx_0x05E0", "translate": Vector3(0.0, -45.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Tomato_Item_data_DObjDesc (@ 0x00AB0)
const dITCommonObject_Tomato_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(390.0, -75.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0x09C0", "translate": Vector3(0.0, 75.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Heart_Item_data_DObjDesc (@ 0x01158)
const dITCommonObject_Heart_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Heart_Item_DLLink", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Star_Item_data_DObjDesc (@ 0x01560)
const dITCommonObject_Star_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0x1440", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Sword_Item_data_DObjDesc (@ 0x01918)
const dITCommonObject_Sword_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Sword_Item_DLLink_0x18F8", "translate": Vector3(0.0, 360.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 2, "dl": "dITCommonObject_Sword_Item_DLLink_0x1908", "translate": Vector3(0.0, -267.0000305175781, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Bat_Item_data_DObjDesc (@ 0x01E00)
const dITCommonObject_Bat_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0x1BF0", "translate": Vector3(0.0, 139.58062744140625, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 16386, "dl": "dITCommonObject_Gfx_0x1D48", "translate": Vector3(9.999999974752427e-07, -198.36004638671875, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Harisen_Item_data_DObjDesc (@ 0x02198)
const dITCommonObject_Harisen_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": null, "translate": Vector3(0.0, 158.99996948242188, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 2, "dl": "dITCommonObject_Gfx_0x20A0", "translate": Vector3(0.0, -209.99996948242188, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_LGun_Item_data_DObjDesc (@ 0x03F50)
const dITCommonObject_LGun_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0x3DB0", "translate": Vector3(0.0, 39.89999771118164, 78.00001525878906), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_FFlower_Item_data_DObjDesc (@ 0x046B0)
const dITCommonObject_FFlower_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, -105.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0x4520", "translate": Vector3(0.0, 105.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 16386, "dl": "dITCommonObject_Gfx_0x4608", "translate": Vector3(0.0, 37.499977111816406, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Hammer_Item_data_DObjDesc (@ 0x02750)
const dITCommonObject_Hammer_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0x25F0", "translate": Vector3(0.0, 239.9998779296875, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_MSBomb_Item_data_DObjDesc (@ 0x039A0)
const dITCommonObject_MSBomb_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(-9.999999974752427e-07, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": null, "translate": Vector3(9.999999974752427e-07, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 2, "dl": "dITCommonObject_Gfx_0x37A0", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 2, "dl": "dITCommonObject_Gfx_0x38B0", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_BombHei_Item_data_DObjDesc (@ 0x033F8)
const dITCommonObject_BombHei_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0x3310", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_StarRod_Item_data_DObjDesc (@ 0x04B60)
const dITCommonObject_StarRod_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0x49B0", "translate": Vector3(0.0, 157.5, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 16386, "dl": "dITCommonObject_Gfx_0x4AA0", "translate": Vector3(0.0, 105.44328308105469, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_GShell_Item_data_DObjDesc (@ 0x05F88)
const dITCommonObject_GShell_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0x5EC0", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Box_Item_data_DObjDesc (@ 0x06778)
const dITCommonObject_Box_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 9.999999974752427e-07, -225.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0x6630", "translate": Vector3(0.0, -9.999999974752427e-07, 224.99998474121094), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Taru_Item_data_DObjDesc (@ 0x071A8)
const dITCommonObject_Taru_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, -210.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0x7000", "translate": Vector3(0.0, 0.0, 210.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_NBumper_Item_data_DObjDesc (@ 0x07648)
const dITCommonObject_NBumper_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0x7558", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_MBall_Item_data_DObjDesc (@ 0x09430)
const dITCommonObject_MBall_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 2, "dl": "dITCommonObject_Gfx_0x9250", "translate": Vector3(-75.0, 9.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 2, "dl": "dITCommonObject_Gfx_0x9340", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Wark_Item_data_DObjDesc (@ 0x0A140)
const dITCommonObject_Wark_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0xA050", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_WarkRock_Weapon_data_DObjDesc (@ 0x0AB98)
const dITCommonObject_WarkRock_Weapon_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0xAAA8", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Kabigon_Item_data_DObjDesc (@ 0x0B158)
const dITCommonObject_Kabigon_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0xB070", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Tosakinto_Item_data_DObjDesc (@ 0x0B708)
const dITCommonObject_Tosakinto_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 2, "dl": "dITCommonObject_Gfx_0xB618", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Mew_Item_data_DObjDesc (@ 0x0BCC0)
const dITCommonObject_Mew_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0xBBD0", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Nyars_Item_data_DObjDesc (@ 0x0C130)
const dITCommonObject_Nyars_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0xC040", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_NyarsCoin_Weapon_data_DObjDesc (@ 0x0C520)
const dITCommonObject_NyarsCoin_Weapon_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0xC430", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Lizardon_Item_data_DObjDesc (@ 0x0D5C0)
const dITCommonObject_Lizardon_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 9.999999974752427e-07, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0xD4E0", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, -3.1415929794311523, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Spear_Item_data_DObjDesc (@ 0x0DF38)
const dITCommonObject_Spear_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 2, "dl": "dITCommonObject_Gfx_0xDE48", "translate": Vector3(-135.0, -135.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_SpearSwarm_Weapon_data_DObjDesc (@ 0x0E4A8)
const dITCommonObject_SpearSwarm_Weapon_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 2, "dl": "dITCommonObject_Gfx_0xE3B8", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Kamex_Item_data_DObjDesc (@ 0x0EA60)
const dITCommonObject_Kamex_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0xE970", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_KamexHydro_Weapon_data_DObjDesc (@ 0x0F9D8)
const dITCommonObject_KamexHydro_Weapon_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0xF848", "translate": Vector3(4391.25, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 9.999999747378752e-06, 1.0)},
	{"id": 2, "dl": "dITCommonObject_Gfx_0xF920", "translate": Vector3(-4481.25, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_MLucky_Item_data_DObjDesc (@ 0x10000)
const dITCommonObject_MLucky_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 2, "dl": "dITCommonObject_Gfx_0xFF10", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Egg_Item_data_DObjDesc (@ 0x104A0)
const dITCommonObject_Egg_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 2, "dl": "dITCommonObject_Gfx_0x103B0", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Starmie_Item_data_DObjDesc (@ 0x112A0)
const dITCommonObject_Starmie_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0x111B0", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_StarmieSwift_Weapon_data_DObjDesc (@ 0x119D8)
const dITCommonObject_StarmieSwift_Weapon_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Starmie_Item_data_remainder_sub_0x6A4", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Sawamura_Item_data_DObjDesc (@ 0x11F40)
const dITCommonObject_Sawamura_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_Gfx_0x11E50", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Dogas_Item_data_DObjDesc (@ 0x12820)
const dITCommonObject_Dogas_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 2, "dl": "dITCommonObject_Gfx_0x12730", "translate": Vector3(0.0, -5.439370155334473, 0.0), "rotate": Vector3(0.0, 0.0, 0.0866909995675087), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_DogasSmog_Weapon_data_DObjDesc (@ 0x13100)
const dITCommonObject_DogasSmog_Weapon_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_DogasSmog_Weapon_mobjsubs_sub_0x178", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(5.5, 5.5, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

## src/relocData/86_ITCommonObject.c : dITCommonObject_Pippi_Item_data_DObjDesc (@ 0x13598)
const dITCommonObject_Pippi_Item_data_DObjDesc: Array = [
	{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 1, "dl": "dITCommonObject_DogasSmog_Weapon_matanimjoints_trailing_DL", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
	{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
]

# ---------------------------------------------------------------------------------------
# ITAttributes (src/it/ittypes.h field names) - src/relocData/251_ITCommonData.c, REGION_US.
# Every value was cross-checked against the ROM file 251 (ITCommonData) bitfield layout.
# data: DObjDesc tree (above). p_mobjsubs / anim_joints / p_matanim_joints are model, texture
# and animation tables that only the renderer uses: a non-NULL C pointer is kept as its symbol
# name (String) so that the C NULL tests take the same branches; nothing is attached for them.
# ---------------------------------------------------------------------------------------
## src/relocData/251_ITCommonData.c : dITCommonData_Capsule_ItemAttributes (llITCommonDataCapsuleItemAttributes, @ 0x0050)
const dITCommonData_Capsule_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Capsule_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 120,
	"map_coll_center": 0,
	"map_coll_bottom": -100,
	"map_coll_width": 60,
	"size": 200,
	"angle": 361,
	"knockback_scale": 80,
	"damage": 5,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 1,
	"hit_sfx": nSYAudioFGMPunchL,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_shield": 1,
	"knockback_base": 20,
	"type": 3,
	"hitstatus": 1,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 80,
	"spin_speed": 120,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Tomato_ItemAttributes (llITCommonDataTomatoItemAttributes, @ 0x00B8)
const dITCommonData_Tomato_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Tomato_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 180,
	"map_coll_center": 0,
	"map_coll_bottom": -180,
	"map_coll_width": 180,
	"size": 200,
	"angle": 361,
	"knockback_scale": 100,
	"damage": 1,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 1,
	"hit_sfx": nSYAudioFGMPunchS,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_shield": 1,
	"knockback_base": 0,
	"type": 5,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 100,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Heart_ItemAttributes (llITCommonDataHeartItemAttributes, @ 0x0100)
const dITCommonData_Heart_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Heart_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 1,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 165,
	"map_coll_center": 0,
	"map_coll_bottom": -165,
	"map_coll_width": 180,
	"size": 200,
	"angle": 361,
	"knockback_scale": 100,
	"damage": 1,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 1,
	"hit_sfx": nSYAudioFGMPunchS,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_shield": 1,
	"knockback_base": 0,
	"type": 5,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Star_ItemAttributes (llITCommonDataStarItemAttributes, @ 0x0148)
const dITCommonData_Star_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Star_Item_data_DObjDesc,
	"p_mobjsubs": "dITCommonObject_Star_Item_mobjsubs_gap_0x12B8",
	"anim_joints": null,
	"p_matanim_joints": "dITCommonObject_Star_Item_matanimjoints",
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 30,
	"map_coll_center": 0,
	"map_coll_bottom": -30,
	"map_coll_width": 30,
	"size": 200,
	"angle": 361,
	"knockback_scale": 100,
	"damage": 1,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 0,
	"hit_sfx": nSYAudioFGMPunchL,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 0,
	"can_reflect": 0,
	"can_shield": 0,
	"knockback_base": 0,
	"type": 4,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Sword_ItemAttributes (llITCommonDataSwordItemAttributes, @ 0x0190)
const dITCommonData_Sword_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Sword_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 1,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 700, 150),
	"map_coll_top": 422,
	"map_coll_center": 0,
	"map_coll_bottom": -422,
	"map_coll_width": 72,
	"size": 300,
	"angle": 361,
	"knockback_scale": 80,
	"damage": 10,
	"element": 3,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 1,
	"hit_sfx": nSYAudioFGMSlashL,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_shield": 1,
	"knockback_base": 60,
	"type": 1,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 100,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Bat_ItemAttributes (llITCommonDataBatItemAttributes, @ 0x01D8)
const dITCommonData_Bat_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Bat_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 240,
	"map_coll_center": 0,
	"map_coll_bottom": -240,
	"map_coll_width": 27,
	"size": 200,
	"angle": 361,
	"knockback_scale": 80,
	"damage": 12,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 1,
	"hit_sfx": nSYAudioFGMPunchL,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_shield": 1,
	"knockback_base": 60,
	"type": 1,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 110,
	"spin_speed": 100,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Harisen_ItemAttributes (llITCommonDataHarisenItemAttributes, @ 0x0220)
const dITCommonData_Harisen_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Harisen_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 210,
	"map_coll_center": 0,
	"map_coll_bottom": -210,
	"map_coll_width": 90,
	"size": 200,
	"angle": 96,
	"knockback_scale": 100,
	"damage": 1,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 1,
	"hit_sfx": nSYAudioFGMHarisenHit,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_shield": 1,
	"knockback_base": 70,
	"type": 1,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 70,
	"spin_speed": 50,
}

## src/relocData/251_ITCommonData.c : dITCommonData_LGun_ItemAttributes (llITCommonDataLGunItemAttributes, @ 0x0268)
const dITCommonData_LGun_ItemAttributes: Dictionary = {
	"data": dITCommonObject_LGun_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(60, 60, 60),
	"map_coll_top": 100,
	"map_coll_center": 0,
	"map_coll_bottom": -100,
	"map_coll_width": 100,
	"size": 200,
	"angle": 361,
	"knockback_scale": 110,
	"damage": 2,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 1,
	"hit_sfx": nSYAudioFGMKickM,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_shield": 1,
	"knockback_base": 10,
	"type": 2,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 140,
}

## src/relocData/251_ITCommonData.c : dITCommonData_FFlower_ItemAttributes (llITCommonDataFFlowerItemAttributes, @ 0x02E4)
const dITCommonData_FFlower_ItemAttributes: Dictionary = {
	"data": dITCommonObject_FFlower_Item_data_DObjDesc,
	"p_mobjsubs": "dITCommonObject_FFlower_Item_mobjsubs_gap_0x4388",
	"anim_joints": null,
	"p_matanim_joints": "dITCommonObject_FFlower_Item_matanimjoints",
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(60, 60, 60),
	"map_coll_top": 127,
	"map_coll_center": 0,
	"map_coll_bottom": -107,
	"map_coll_width": 107,
	"size": 200,
	"angle": 361,
	"knockback_scale": 100,
	"damage": 2,
	"element": 1,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 1,
	"hit_sfx": nSYAudioFGMBurnM,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_shield": 1,
	"knockback_base": 30,
	"type": 2,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 80,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Hammer_ItemAttributes (llITCommonDataHammerItemAttributes, @ 0x0374)
const dITCommonData_Hammer_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Hammer_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 1,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 258,
	"map_coll_center": 0,
	"map_coll_bottom": -249,
	"map_coll_width": 105,
	"size": 200,
	"angle": 361,
	"knockback_scale": 100,
	"damage": 10,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 1,
	"hit_sfx": nSYAudioFGMPunchS,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 0,
	"can_shield": 1,
	"knockback_base": 30,
	"type": 5,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_MSBomb_ItemAttributes (llITCommonDataMSBombItemAttributes, @ 0x03BC)
const dITCommonData_MSBomb_ItemAttributes: Dictionary = {
	"data": dITCommonObject_MSBomb_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 60,
	"map_coll_center": 0,
	"map_coll_bottom": -60,
	"map_coll_width": 60,
	"size": 200,
	"angle": 361,
	"knockback_scale": 100,
	"damage": 5,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 1,
	"hit_sfx": nSYAudioFGMPunchS,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_shield": 1,
	"knockback_base": 10,
	"type": 3,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 90,
	"spin_speed": 120,
}

## src/relocData/251_ITCommonData.c : dITCommonData_BombHei_ItemAttributes (llITCommonDataBombHeiItemAttributes, @ 0x0424)
const dITCommonData_BombHei_ItemAttributes: Dictionary = {
	"data": dITCommonObject_BombHei_Item_data_DObjDesc,
	"p_mobjsubs": "dITCommonObject_BombHei_Item_mobjsubs_gap_0x3230",
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 1,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 150,
	"map_coll_center": 0,
	"map_coll_bottom": -150,
	"map_coll_width": 150,
	"size": 200,
	"angle": 361,
	"knockback_scale": 100,
	"damage": 1,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 1,
	"hit_sfx": nSYAudioFGMExplodeL,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_shield": 1,
	"knockback_base": 30,
	"type": 3,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_StarRod_ItemAttributes (llITCommonDataStarRodItemAttributes, @ 0x048C)
const dITCommonData_StarRod_ItemAttributes: Dictionary = {
	"data": dITCommonObject_StarRod_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(60, 60, 60),
	"map_coll_top": 195,
	"map_coll_center": 0,
	"map_coll_bottom": -195,
	"map_coll_width": 90,
	"size": 200,
	"angle": 0,
	"knockback_scale": 70,
	"damage": 6,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 1,
	"hit_sfx": nSYAudioFGMPunchL,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_shield": 1,
	"knockback_base": 20,
	"type": 1,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 110,
}

## src/relocData/251_ITCommonData.c : dITCommonData_GShell_ItemAttributes (llITCommonDataGShellItemAttributes, @ 0x053C)
const dITCommonData_GShell_ItemAttributes: Dictionary = {
	"data": dITCommonObject_GShell_Item_data_DObjDesc,
	"p_mobjsubs": "dITCommonObject_GShell_Item_mobjsubs_gap_0x5DE0",
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 150,
	"map_coll_center": 0,
	"map_coll_bottom": -150,
	"map_coll_width": 150,
	"size": 200,
	"angle": 361,
	"knockback_scale": 80,
	"damage": 18,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 0,
	"hit_sfx": nSYAudioFGMShellHit,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_shield": 1,
	"knockback_base": 60,
	"type": 3,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_RShell_ItemAttributes (llITCommonDataRShellItemAttributes, @ 0x0584)
const dITCommonData_RShell_ItemAttributes: Dictionary = {
	"data": dITCommonObject_GShell_Item_data_DObjDesc,
	"p_mobjsubs": "dITCommonObject_GShell_Item_mobjsubs_gap_0x5DE0",
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 150,
	"map_coll_center": 0,
	"map_coll_bottom": -150,
	"map_coll_width": 150,
	"size": 200,
	"angle": 361,
	"knockback_scale": 80,
	"damage": 10,
	"element": 0,
	"knockback_weight": 90,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 0,
	"hit_sfx": nSYAudioFGMShellHit,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 1,
	"can_hop": 1,
	"can_reflect": 1,
	"can_shield": 1,
	"knockback_base": 60,
	"type": 3,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Box_ItemAttributes (llITCommonDataBoxItemAttributes, @ 0x05CC)
const dITCommonData_Box_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Box_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 0,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(450, 450, 450),
	"map_coll_top": 225,
	"map_coll_center": 0,
	"map_coll_bottom": -225,
	"map_coll_width": 225,
	"size": 200,
	"angle": 361,
	"knockback_scale": 100,
	"damage": 15,
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
	"knockback_base": 40,
	"type": 0,
	"hitstatus": 1,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 40,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Taru_ItemAttributes (llITCommonDataTaruItemAttributes, @ 0x0634)
const dITCommonData_Taru_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Taru_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 0,
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
	"angle": 361,
	"knockback_scale": 100,
	"damage": 12,
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
	"knockback_base": 40,
	"type": 0,
	"hitstatus": 1,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_NBumper_ItemAttributes (llITCommonDataNBumperItemAttributes, @ 0x069C)
const dITCommonData_NBumper_ItemAttributes: Dictionary = {
	"data": dITCommonObject_NBumper_Item_data_DObjDesc,
	"p_mobjsubs": "dITCommonObject_NBumper_Item_mobjsubs_gap_0x7488",
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 180,
	"map_coll_center": 0,
	"map_coll_bottom": -180,
	"map_coll_width": 180,
	"size": 200,
	"angle": 362,
	"knockback_scale": 50,
	"damage": 1,
	"element": 0,
	"knockback_weight": 250,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 0,
	"hit_sfx": nSYAudioFGMBumperHit,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 1,
	"can_hop": 1,
	"can_reflect": 1,
	"can_shield": 1,
	"knockback_base": 0,
	"type": 3,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 70,
}

## src/relocData/251_ITCommonData.c : dITCommonData_MBall_ItemAttributes (llITCommonDataMBallItemAttributes, @ 0x06E4)
const dITCommonData_MBall_ItemAttributes: Dictionary = {
	"data": dITCommonObject_MBall_Item_data_DObjDesc,
	"p_mobjsubs": "dITCommonObject_MBall_Item_mobjsubs_gap_0x9120",
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 1,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 109,
	"map_coll_center": 0,
	"map_coll_bottom": -109,
	"map_coll_width": 164,
	"size": 200,
	"angle": 361,
	"knockback_scale": 80,
	"damage": 12,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 1,
	"hit_sfx": nSYAudioFGMPunchL,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_shield": 1,
	"knockback_base": 60,
	"type": 3,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 80,
	"spin_speed": 20,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Wark_ItemAttributes (llITCommonDataWarkItemAttributes, @ 0x072C)
const dITCommonData_Wark_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Wark_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 324,
	"map_coll_center": 0,
	"map_coll_bottom": -324,
	"map_coll_width": 459,
	"size": 600,
	"angle": 90,
	"knockback_scale": 100,
	"damage": 21,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 0,
	"hit_sfx": nSYAudioFGMPunchL,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 0,
	"can_reflect": 0,
	"can_shield": 1,
	"knockback_base": 60,
	"type": 6,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Kabigon_ItemAttributes (llITCommonDataKabigonItemAttributes, @ 0x07A8)
const dITCommonData_Kabigon_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Kabigon_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 1,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(580, 580, 780),
	"map_coll_top": 585,
	"map_coll_center": 0,
	"map_coll_bottom": -585,
	"map_coll_width": 780,
	"size": 800,
	"angle": 361,
	"knockback_scale": 70,
	"damage": 22,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 0,
	"hit_sfx": nSYAudioFGMExplodeL,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 0,
	"can_reflect": 0,
	"can_shield": 1,
	"knockback_base": 60,
	"type": 6,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Tosakinto_ItemAttributes (llITCommonDataTosakintoItemAttributes, @ 0x07F0)
const dITCommonData_Tosakinto_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Tosakinto_Item_data_DObjDesc,
	"p_mobjsubs": "dITCommonObject_Tosakinto_Item_mobjsubs_gap_0xB540",
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 135,
	"map_coll_center": 0,
	"map_coll_bottom": -135,
	"map_coll_width": 195,
	"size": 200,
	"angle": 361,
	"knockback_scale": 80,
	"damage": 12,
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
	"knockback_base": 60,
	"type": 6,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Mew_ItemAttributes (llITCommonDataMewItemAttributes, @ 0x0838)
const dITCommonData_Mew_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Mew_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 1,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 218,
	"map_coll_center": 0,
	"map_coll_bottom": -218,
	"map_coll_width": 218,
	"size": 300,
	"angle": 361,
	"knockback_scale": 80,
	"damage": 12,
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
	"knockback_base": 60,
	"type": 6,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Nyars_ItemAttributes (llITCommonDataNyarsItemAttributes, @ 0x0880)
const dITCommonData_Nyars_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Nyars_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 244,
	"map_coll_center": 0,
	"map_coll_bottom": -244,
	"map_coll_width": 244,
	"size": 300,
	"angle": 361,
	"knockback_scale": 80,
	"damage": 12,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 0,
	"hit_sfx": nSYAudioFGMPunchL,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 1,
	"can_hop": 0,
	"can_reflect": 0,
	"can_shield": 1,
	"knockback_base": 60,
	"type": 6,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Lizardon_ItemAttributes (llITCommonDataLizardonItemAttributes, @ 0x08FC)
const dITCommonData_Lizardon_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Lizardon_Item_data_DObjDesc,
	"p_mobjsubs": "dITCommonObject_Lizardon_Item_mobjsubs_gap_0xD410",
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 400,
	"map_coll_center": 0,
	"map_coll_bottom": -390,
	"map_coll_width": 420,
	"size": 600,
	"angle": 361,
	"knockback_scale": 80,
	"damage": 18,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 0,
	"hit_sfx": nSYAudioFGMPunchL,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 1,
	"can_hop": 0,
	"can_reflect": 0,
	"can_shield": 1,
	"knockback_base": 60,
	"type": 6,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Spear_ItemAttributes (llITCommonDataSpearItemAttributes, @ 0x098C)
const dITCommonData_Spear_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Spear_Item_data_DObjDesc,
	"p_mobjsubs": "dITCommonObject_Spear_Item_mobjsubs_gap_0xDD70",
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 244,
	"map_coll_center": 0,
	"map_coll_bottom": -244,
	"map_coll_width": 244,
	"size": 300,
	"angle": 90,
	"knockback_scale": 100,
	"damage": 18,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 0,
	"hit_sfx": nSYAudioFGMPunchL,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 0,
	"can_reflect": 0,
	"can_shield": 1,
	"knockback_base": 60,
	"type": 6,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Kamex_ItemAttributes (llITCommonDataKamexItemAttributes, @ 0x0A08)
const dITCommonData_Kamex_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Kamex_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 317,
	"map_coll_center": 0,
	"map_coll_bottom": -300,
	"map_coll_width": 300,
	"size": 400,
	"angle": 130,
	"knockback_scale": 60,
	"damage": 13,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 0,
	"hit_sfx": nSYAudioFGMPunchL,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 1,
	"can_hop": 0,
	"can_reflect": 0,
	"can_shield": 1,
	"knockback_base": 60,
	"type": 6,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_MLucky_ItemAttributes (llITCommonDataMLuckyItemAttributes, @ 0x0A84)
const dITCommonData_MLucky_ItemAttributes: Dictionary = {
	"data": dITCommonObject_MLucky_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(250, 250, 250),
	"map_coll_top": 300,
	"map_coll_center": 0,
	"map_coll_bottom": -200,
	"map_coll_width": 240,
	"size": 500,
	"angle": 361,
	"knockback_scale": 80,
	"damage": 12,
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
	"knockback_base": 60,
	"type": 6,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Egg_ItemAttributes (llITCommonDataEggItemAttributes, @ 0x0ACC)
const dITCommonData_Egg_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Egg_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": "dITCommonObject_Egg_Item_animjoints",
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 200,
	"map_coll_center": 0,
	"map_coll_bottom": -140,
	"map_coll_width": 280,
	"size": 200,
	"angle": 361,
	"knockback_scale": 80,
	"damage": 3,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 1,
	"hit_sfx": nSYAudioFGMPunchL,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_shield": 1,
	"knockback_base": 60,
	"type": 3,
	"hitstatus": 1,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 100,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Starmie_ItemAttributes (llITCommonDataStarmieItemAttributes, @ 0x0B34)
const dITCommonData_Starmie_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Starmie_Item_data_DObjDesc,
	"p_mobjsubs": "dITCommonObject_Starmie_Item_mobjsubs_gap_0x110E0",
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 300,
	"map_coll_center": 0,
	"map_coll_bottom": -220,
	"map_coll_width": 300,
	"size": 400,
	"angle": 361,
	"knockback_scale": 80,
	"damage": 12,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 0,
	"hit_sfx": nSYAudioFGMPunchL,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 1,
	"can_hop": 0,
	"can_reflect": 0,
	"can_shield": 1,
	"knockback_base": 60,
	"type": 6,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Sawamura_ItemAttributes (llITCommonDataSawamuraItemAttributes, @ 0x0BB0)
const dITCommonData_Sawamura_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Sawamura_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 317,
	"map_coll_center": 0,
	"map_coll_bottom": -317,
	"map_coll_width": 195,
	"size": 300,
	"angle": 90,
	"knockback_scale": 100,
	"damage": 24,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 30,
	"attack_count": 1,
	"can_setoff": 0,
	"hit_sfx": nSYAudioFGMPunchL,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 0,
	"can_reflect": 0,
	"can_shield": 1,
	"knockback_base": 20,
	"type": 6,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Dogas_ItemAttributes (llITCommonDataDogasItemAttributes, @ 0x0BF8)
const dITCommonData_Dogas_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Dogas_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 240,
	"map_coll_center": 0,
	"map_coll_bottom": -240,
	"map_coll_width": 240,
	"size": 50,
	"angle": 361,
	"knockback_scale": 80,
	"damage": 12,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 0,
	"hit_sfx": nSYAudioFGMPunchL,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 1,
	"can_hop": 0,
	"can_reflect": 0,
	"can_shield": 1,
	"knockback_base": 60,
	"type": 6,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_Pippi_ItemAttributes (llITCommonDataPippiItemAttributes, @ 0x0C74)
const dITCommonData_Pippi_ItemAttributes: Dictionary = {
	"data": dITCommonObject_Pippi_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 0,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 192,
	"map_coll_center": 0,
	"map_coll_bottom": -192,
	"map_coll_width": 192,
	"size": 300,
	"angle": 361,
	"knockback_scale": 80,
	"damage": 12,
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
	"knockback_base": 60,
	"type": 6,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_GBumper_ItemAttributes (llITCommonDataGBumperItemAttributes, @ 0x0CF0)
const dITCommonData_GBumper_ItemAttributes: Dictionary = {
	"data": dITCommonObject_NBumper_Item_data_DObjDesc,
	"p_mobjsubs": "dITCommonObject_NBumper_Item_mobjsubs_gap_0x7488",
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 1,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 180,
	"map_coll_center": 0,
	"map_coll_bottom": -180,
	"map_coll_width": 180,
	"size": 250,
	"angle": 362,
	"knockback_scale": 50,
	"damage": 1,
	"element": 0,
	"knockback_weight": 200,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 0,
	"hit_sfx": nSYAudioFGMBumperHit,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 1,
	"can_hop": 0,
	"can_reflect": 0,
	"can_shield": 1,
	"knockback_base": 0,
	"type": 3,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

# ---------------------------------------------------------------------------------------
# WPAttributes of the item weapons (src/wp/wptypes.h field names, Wpmanager dictionary format)
# - src/relocData/251_ITCommonData.c, REGION_US, cross-checked against ROM file 251.
# data: DObjDesc tree when the C points at a DObjDesc, else the display-list symbol; the
# model/animation tables (p_mobjsubs / anim_joints / p_matanim_joints) are render-only and null.
# ---------------------------------------------------------------------------------------
## src/relocData/251_ITCommonData.c : dITCommonData_LGunAmmo_WeaponAttributes (llITCommonDataLGunAmmoWeaponAttributes, @ 0x02B0)
const dITCommonData_LGunAmmo_WeaponAttributes: Dictionary = {
	"data": "dITCommonObject_LGunAmmo_Weapon_data",
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(-5, 0, 0)],
	"map_coll_top": 10,
	"map_coll_center": 0,
	"map_coll_bottom": -10,
	"map_coll_width": 10,
	"size": 120,
	"angle": 70,
	"knockback_scale": 40,
	"damage": 10,
	"element": 2,
	"knockback_weight": 0,
	"shield_damage": -8,
	"attack_count": 2,
	"can_setoff": 0,
	"sfx": 2,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_absorb": 1,
	"can_shield": 1,
	"unused_0x2F_b6": 0,
	"unused_0x2F_b7": 0,
	"knockback_base": 50,
}

## src/relocData/251_ITCommonData.c : dITCommonData_FFlowerFlame_WeaponAttributes (llITCommonDataFFlowerFlameWeaponAttributes, @ 0x032C)
const dITCommonData_FFlowerFlame_WeaponAttributes: Dictionary = {
	"data": null,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 50,
	"map_coll_center": 0,
	"map_coll_bottom": -50,
	"map_coll_width": 50,
	"size": 270,
	"angle": 0,
	"knockback_scale": 100,
	"damage": 3,
	"element": 1,
	"knockback_weight": 3,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 0,
	"sfx": 28,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 0,
	"can_reflect": 1,
	"can_absorb": 1,
	"can_shield": 1,
	"unused_0x2F_b6": 0,
	"unused_0x2F_b7": 0,
	"knockback_base": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_StarRod_WeaponAttributes (llITCommonDataStarRodWeaponAttributes, @ 0x04D4)
const dITCommonData_StarRod_WeaponAttributes: Dictionary = {
	"data": "dITCommonObject_StarRod_Weapon_data",
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 10,
	"map_coll_center": -10,
	"map_coll_bottom": -10,
	"map_coll_width": 10,
	"size": 200,
	"angle": 361,
	"knockback_scale": 100,
	"damage": 8,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 1,
	"sfx": nSYAudioFGMPunchM,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_absorb": 1,
	"can_shield": 1,
	"unused_0x2F_b6": 0,
	"unused_0x2F_b7": 0,
	"knockback_base": 10,
}

## src/relocData/251_ITCommonData.c : dITCommonData_StarRodSmash_WeaponAttributes (llITCommonDataStarRodSmashWeaponAttributes, @ 0x0508)
const dITCommonData_StarRodSmash_WeaponAttributes: Dictionary = {
	"data": "dITCommonObject_StarRod_Weapon_data",
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 10,
	"map_coll_center": -10,
	"map_coll_bottom": -10,
	"map_coll_width": 10,
	"size": 200,
	"angle": 361,
	"knockback_scale": 100,
	"damage": 12,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 1,
	"sfx": nSYAudioFGMPunchL,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_absorb": 1,
	"can_shield": 1,
	"unused_0x2F_b6": 0,
	"unused_0x2F_b7": 0,
	"knockback_base": 10,
}

## src/relocData/251_ITCommonData.c : dITCommonData_WarkRock_WeaponAttributes (llITCommonDataWarkRockWeaponAttributes, @ 0x0774)
const dITCommonData_WarkRock_WeaponAttributes: Dictionary = {
	"data": dITCommonObject_WarkRock_Weapon_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 210,
	"map_coll_center": 0,
	"map_coll_bottom": -210,
	"map_coll_width": 210,
	"size": 360,
	"angle": 80,
	"knockback_scale": 80,
	"damage": 8,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 1,
	"sfx": 2,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 0,
	"can_absorb": 0,
	"can_shield": 1,
	"unused_0x2F_b6": 0,
	"unused_0x2F_b7": 0,
	"knockback_base": 30,
}

## src/relocData/251_ITCommonData.c : dITCommonData_NyarsCoin_WeaponAttributes (llITCommonDataNyarsCoinWeaponAttributes, @ 0x08C8)
const dITCommonData_NyarsCoin_WeaponAttributes: Dictionary = {
	"data": dITCommonObject_NyarsCoin_Weapon_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 113,
	"map_coll_center": 0,
	"map_coll_bottom": -113,
	"map_coll_width": 94,
	"size": 200,
	"angle": 90,
	"knockback_scale": 60,
	"damage": 6,
	"element": 4,
	"knockback_weight": 0,
	"shield_damage": 2,
	"attack_count": 1,
	"can_setoff": 1,
	"sfx": nSYAudioFGMMarioSpecialHiCoin,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_absorb": 1,
	"can_shield": 1,
	"unused_0x2F_b6": 0,
	"unused_0x2F_b7": 0,
	"knockback_base": 30,
}

## src/relocData/251_ITCommonData.c : dITCommonData_LizardonFlame_WeaponAttributes (llITCommonDataLizardonFlameWeaponAttributes, @ 0x0944)
const dITCommonData_LizardonFlame_WeaponAttributes: Dictionary = {
	"data": null,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 4,
	"map_coll_center": 0,
	"map_coll_bottom": -4,
	"map_coll_width": 4,
	"size": 320,
	"angle": 0,
	"knockback_scale": 100,
	"damage": 4,
	"element": 1,
	"knockback_weight": 8,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 0,
	"sfx": 28,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 0,
	"can_reflect": 1,
	"can_absorb": 1,
	"can_shield": 1,
	"unused_0x2F_b6": 0,
	"unused_0x2F_b7": 0,
	"knockback_base": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_SpearSwarm_WeaponAttributes (llITCommonDataSpearSwarmWeaponAttributes, @ 0x09D4)
const dITCommonData_SpearSwarm_WeaponAttributes: Dictionary = {
	"data": dITCommonObject_SpearSwarm_Weapon_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 244,
	"map_coll_center": 0,
	"map_coll_bottom": -244,
	"map_coll_width": 244,
	"size": 300,
	"angle": 80,
	"knockback_scale": 100,
	"damage": 12,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 1,
	"sfx": 2,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 0,
	"can_reflect": 0,
	"can_absorb": 0,
	"can_shield": 1,
	"unused_0x2F_b6": 0,
	"unused_0x2F_b7": 0,
	"knockback_base": 40,
}

## src/relocData/251_ITCommonData.c : dITCommonData_KamexHydro_WeaponAttributes (llITCommonDataKamexHydroWeaponAttributes, @ 0x0A50)
const dITCommonData_KamexHydro_WeaponAttributes: Dictionary = {
	"data": dITCommonObject_KamexHydro_Weapon_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 213,
	"map_coll_center": 0,
	"map_coll_bottom": -213,
	"map_coll_width": 180,
	"size": 200,
	"angle": 0,
	"knockback_scale": 30,
	"damage": 6,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 1,
	"sfx": 2,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 0,
	"can_reflect": 0,
	"can_absorb": 0,
	"can_shield": 1,
	"unused_0x2F_b6": 0,
	"unused_0x2F_b7": 0,
	"knockback_base": 78,
}

## src/relocData/251_ITCommonData.c : dITCommonData_StarmieSwift_WeaponAttributes (llITCommonDataStarmieSwiftWeaponAttributes, @ 0x0B7C)
const dITCommonData_StarmieSwift_WeaponAttributes: Dictionary = {
	"data": dITCommonObject_StarmieSwift_Weapon_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 113,
	"map_coll_center": 0,
	"map_coll_bottom": -113,
	"map_coll_width": 309,
	"size": 200,
	"angle": 100,
	"knockback_scale": 20,
	"damage": 3,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 1,
	"sfx": nSYAudioFGMKickM,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_absorb": 1,
	"can_shield": 1,
	"unused_0x2F_b6": 0,
	"unused_0x2F_b7": 0,
	"knockback_base": 40,
}

## src/relocData/251_ITCommonData.c : dITCommonData_DogasSmog_WeaponAttributes (llITCommonDataDogasSmogWeaponAttributes, @ 0x0C40)
const dITCommonData_DogasSmog_WeaponAttributes: Dictionary = {
	"data": dITCommonObject_DogasSmog_Weapon_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 75,
	"map_coll_center": 0,
	"map_coll_bottom": -75,
	"map_coll_width": 75,
	"size": 50,
	"angle": 150,
	"knockback_scale": 100,
	"damage": 3,
	"element": 0,
	"knockback_weight": 60,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 1,
	"sfx": 2,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 0,
	"can_reflect": 0,
	"can_absorb": 0,
	"can_shield": 0,
	"unused_0x2F_b6": 0,
	"unused_0x2F_b7": 0,
	"knockback_base": 0,
}

## src/relocData/251_ITCommonData.c : dITCommonData_PippiSwarm_WeaponAttributes (llITCommonDataPippiSwarmWeaponAttributes, @ 0x0CBC)
const dITCommonData_PippiSwarm_WeaponAttributes: Dictionary = {
	"data": dITCommonObject_Pippi_Item_data_DObjDesc,
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 192,
	"map_coll_center": 0,
	"map_coll_bottom": -192,
	"map_coll_width": 192,
	"size": 200,
	"angle": 80,
	"knockback_scale": 100,
	"damage": 12,
	"element": 0,
	"knockback_weight": 0,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 1,
	"sfx": 2,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 1,
	"can_hop": 0,
	"can_reflect": 0,
	"can_absorb": 0,
	"can_shield": 1,
	"unused_0x2F_b6": 0,
	"unused_0x2F_b7": 0,
	"knockback_base": 40,
}

# ---------------------------------------------------------------------------------------
# ITAttackEvent tables {timer, angle, damage, size} - src/relocData/251_ITCommonData.c,
# cross-checked against ROM file 251 (itMainUpdateAttackEvent).
# ---------------------------------------------------------------------------------------
## src/relocData/251_ITCommonData.c : dITCommonData_Capsule_AttackEvents (llITCommonDataCapsuleAttackEvents, @ 0x0098)
const dITCommonData_Capsule_AttackEvents: Array = [
	{"timer": 0, "angle": 361, "damage": 30, "size": 350},
	{"timer": 2, "angle": 361, "damage": 30, "size": 250},
	{"timer": 4, "angle": 361, "damage": 20, "size": 150},
	{"timer": 6, "angle": 361, "damage": 1, "size": 0},
]

## src/relocData/251_ITCommonData.c : dITCommonData_MSBomb_AttackEvents (llITCommonDataMSBombAttackEvents, @ 0x0404)
const dITCommonData_MSBomb_AttackEvents: Array = [
	{"timer": 0, "angle": 361, "damage": 30, "size": 360},
	{"timer": 4, "angle": 361, "damage": 30, "size": 300},
	{"timer": 8, "angle": 361, "damage": 20, "size": 200},
	{"timer": 16, "angle": 361, "damage": 1, "size": 0},
]

## src/relocData/251_ITCommonData.c : dITCommonData_BombHei_AttackEvents (llITCommonDataBombHeiAttackEvents, @ 0x046C)
const dITCommonData_BombHei_AttackEvents: Array = [
	{"timer": 0, "angle": 361, "damage": 30, "size": 350},
	{"timer": 2, "angle": 361, "damage": 30, "size": 250},
	{"timer": 4, "angle": 361, "damage": 20, "size": 150},
	{"timer": 6, "angle": 361, "damage": 1, "size": 0},
]

## src/relocData/251_ITCommonData.c : dITCommonData_Box_AttackEvents (llITCommonDataBoxAttackEvents, @ 0x0614)
const dITCommonData_Box_AttackEvents: Array = [
	{"timer": 0, "angle": 361, "damage": 20, "size": 350},
	{"timer": 4, "angle": 361, "damage": 15, "size": 250},
	{"timer": 6, "angle": 361, "damage": 10, "size": 150},
	{"timer": 8, "angle": 361, "damage": 1, "size": 0},
]

## src/relocData/251_ITCommonData.c : dITCommonData_Taru_AttackEvents (llITCommonDataTaruAttackEvents, @ 0x067C)
const dITCommonData_Taru_AttackEvents: Array = [
	{"timer": 0, "angle": 361, "damage": 20, "size": 350},
	{"timer": 4, "angle": 361, "damage": 15, "size": 250},
	{"timer": 6, "angle": 361, "damage": 10, "size": 150},
	{"timer": 8, "angle": 361, "damage": 1, "size": 0},
]

## src/relocData/251_ITCommonData.c : dITCommonData_Egg_AttackEvents (llITCommonDataEggAttackEvents, @ 0x0B14)
const dITCommonData_Egg_AttackEvents: Array = [
	{"timer": 0, "angle": 361, "damage": 30, "size": 350},
	{"timer": 4, "angle": 361, "damage": 30, "size": 250},
	{"timer": 6, "angle": 361, "damage": 20, "size": 150},
	{"timer": 8, "angle": 361, "damage": 1, "size": 0},
]


## ITCommonData ITAttributes per item kind (the attributes every ITDesc of these kinds points at).
const dITManagerCommonItemAttributes: Dictionary = {
	nITKindBox: dITCommonData_Box_ItemAttributes,
	nITKindTaru: dITCommonData_Taru_ItemAttributes,
	nITKindCapsule: dITCommonData_Capsule_ItemAttributes,
	nITKindEgg: dITCommonData_Egg_ItemAttributes,
	nITKindTomato: dITCommonData_Tomato_ItemAttributes,
	nITKindHeart: dITCommonData_Heart_ItemAttributes,
	nITKindStar: dITCommonData_Star_ItemAttributes,
	nITKindSword: dITCommonData_Sword_ItemAttributes,
	nITKindBat: dITCommonData_Bat_ItemAttributes,
	nITKindHarisen: dITCommonData_Harisen_ItemAttributes,
	nITKindStarRod: dITCommonData_StarRod_ItemAttributes,
	nITKindLGun: dITCommonData_LGun_ItemAttributes,
	nITKindFFlower: dITCommonData_FFlower_ItemAttributes,
	nITKindHammer: dITCommonData_Hammer_ItemAttributes,
	nITKindMSBomb: dITCommonData_MSBomb_ItemAttributes,
	nITKindBombHei: dITCommonData_BombHei_ItemAttributes,
	nITKindNBumper: dITCommonData_NBumper_ItemAttributes,
	nITKindGShell: dITCommonData_GShell_ItemAttributes,
	nITKindRShell: dITCommonData_RShell_ItemAttributes,
	nITKindMBall: dITCommonData_MBall_ItemAttributes,
	nITKindGBumper: dITCommonData_GBumper_ItemAttributes,
	nITKindIwark: dITCommonData_Wark_ItemAttributes,
	nITKindKabigon: dITCommonData_Kabigon_ItemAttributes,
	nITKindTosakinto: dITCommonData_Tosakinto_ItemAttributes,
	nITKindNyars: dITCommonData_Nyars_ItemAttributes,
	nITKindLizardon: dITCommonData_Lizardon_ItemAttributes,
	nITKindSpear: dITCommonData_Spear_ItemAttributes,
	nITKindKamex: dITCommonData_Kamex_ItemAttributes,
	nITKindMLucky: dITCommonData_MLucky_ItemAttributes,
	nITKindStarmie: dITCommonData_Starmie_ItemAttributes,
	nITKindSawamura: dITCommonData_Sawamura_ItemAttributes,
	nITKindDogas: dITCommonData_Dogas_ItemAttributes,
	nITKindPippi: dITCommonData_Pippi_ItemAttributes,
	nITKindMew: dITCommonData_Mew_ItemAttributes,
}
