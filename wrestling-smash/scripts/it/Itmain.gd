## 1:1 port of src/it/itmain.c (ssb-decomp-re): generic item helpers (spin, gravity, ownership,
## damage output, fighter pickup / drop / throw, status changes, random weights, container drops,
## Poké Ball monsters, default hop / reflector procs).
##
## Conventions (PORTING.md):
##   * vel parameters (C: Vec3f *vel, read only) are Vector3 values.
##   * itMainSetStatus(item_gobj, status_desc, status_id): status_desc is an Array of ITStatusDesc
##     Dictionaries {proc_update, proc_map, proc_hit, proc_shield, proc_hop, proc_setoff,
##     proc_reflector, proc_damage} (Callable, Callable() or null == NULL).
##   * itMainUpdateAttackEvent(item_gobj, ev): ev is an Array of {timer, angle, damage, size}.
##   * weights arguments are Itmanager.ITRandomWeights objects (gITManagerRandomWeights, ...).
##   * itMainSetFighterRelease(item_gobj, vel, throw_mul, stat_flags = null, stat_count = null):
##     stat_flags is the u16 GMStatFlags halfword. Link's Bomb calls it with only 3 arguments (an
##     erroneous C declaration: the last two are register / stack garbage in the original); the
##     port then uses 0 / 0.
##   * C f32 arithmetic whose result is truncated to an integer is evaluated in single precision
##     (Port.f32) so the truncation sees the same value as the N64.
class_name Itmain
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x80189520 - indexed by item kind (common + fighter items)
static var dITMainProcDroppedList: Array = [
	# Containers
	Callable(Itbox, &"itBoxDroppedSetStatus"),            # Box
	Callable(Ittaru, &"itTaruDroppedSetStatus"),          # Barrel
	Callable(Itcapsule, &"itCapsuleDroppedSetStatus"),    # Capsule
	Callable(Itegg, &"itEggDroppedSetStatus"),            # Egg

	# Usable items
	Callable(Ittomato, &"itTomatoDroppedSetStatus"),      # Maxim Tomato
	Callable(Itheart, &"itHeartDroppedSetStatus"),        # Heart Container
	Callable(),                                           # Star Man
	Callable(Itsword, &"itSwordDroppedSetStatus"),        # Beam Sword
	Callable(Itbat, &"itBatDroppedSetStatus"),            # Home Run Bat
	Callable(Itharisen, &"itHarisenDroppedSetStatus"),    # Fan
	Callable(Itstarrod, &"itStarRodDroppedSetStatus"),    # Star Rod
	Callable(Itlgun, &"itLGunDroppedSetStatus"),          # Ray Gun
	Callable(Itfflower, &"itFFlowerDroppedSetStatus"),    # Fire Flower
	Callable(Ithammer, &"itHammerDroppedSetStatus"),      # Hammer
	Callable(Itmsbomb, &"itMSBombDroppedSetStatus"),      # Motion-sensor Bomb
	Callable(Itbombhei, &"itBombHeiDroppedSetStatus"),    # Bob-omb
	Callable(Itnbumper, &"itNBumperDroppedSetStatus"),    # Normal Bumper
	Callable(Itgshell, &"itGShellDroppedSetStatus"),      # Green Shell
	Callable(Itrshell, &"itRShellDroppedSetStatus"),      # Red Shell
	Callable(Itmball, &"itMBallDroppedSetStatus"),        # Poké Ball

	# Fighter items
	Callable(),                                           # Ness PK Fire
	Callable(Itlinkbomb, &"itLinkBombDroppedSetStatus"),  # Link Bomb
]

## 0x80189578
static var dITMainProcThrownList: Array = [
	# Containers
	Callable(Itbox, &"itBoxThrownSetStatus"),             # Box
	Callable(Ittaru, &"itTaruThrownSetStatus"),           # Barrel
	Callable(Itcapsule, &"itCapsuleThrownSetStatus"),     # Capsule
	Callable(Itegg, &"itEggThrownSetStatus"),             # Egg

	# Usable items
	Callable(),                                           # Maxim Tomato
	Callable(),                                           # Heart Container
	Callable(),                                           # Star Man
	Callable(Itsword, &"itSwordThrownSetStatus"),         # Beam Sword
	Callable(Itbat, &"itBatThrownSetStatus"),             # Home Run Bat
	Callable(Itharisen, &"itHarisenThrownSetStatus"),     # Fan
	Callable(Itstarrod, &"itStarRodThrownSetStatus"),     # Star Rod
	Callable(Itlgun, &"itLGunThrownSetStatus"),           # Ray Gun
	Callable(Itfflower, &"itFFlowerThrownSetStatus"),     # Fire Flower
	Callable(Ithammer, &"itHammerThrownSetStatus"),       # Hammer
	Callable(Itmsbomb, &"itMSBombThrownSetStatus"),       # Motion-sensor Bomb
	Callable(Itbombhei, &"itBombHeiThrownSetStatus"),     # Bob-omb
	Callable(Itnbumper, &"itNBumperThrownSetStatus"),     # Normal Bumper
	Callable(Itgshell, &"itGShellThrownSetStatus"),       # Green Shell
	Callable(Itrshell, &"itRShellThrownSetStatus"),       # Red Shell
	Callable(Itmball, &"itMBallThrownSetStatus"),         # Poké Ball

	# Fighter items
	Callable(),                                           # Ness PK Fire
	Callable(Itlinkbomb, &"itLinkBombThrownSetStatus"),   # Link Bomb
]

## 0x801895D0
static var dITMainProcHoldList: Array = [
	# Containers
	Callable(Itbox, &"itBoxHoldSetStatus"),               # Box
	Callable(Ittaru, &"itTaruHoldSetStatus"),             # Barrel
	Callable(Itcapsule, &"itCapsuleHoldSetStatus"),       # Capsule
	Callable(Itegg, &"itEggHoldSetStatus"),               # Egg

	# Usable items
	Callable(),                                           # Maxim Tomato
	Callable(),                                           # Heart Container
	Callable(),                                           # Star Man
	Callable(Itsword, &"itSwordHoldSetStatus"),           # Beam Sword
	Callable(Itbat, &"itBatHoldSetStatus"),               # Home Run Bat
	Callable(Itharisen, &"itHarisenHoldSetStatus"),       # Fan
	Callable(Itstarrod, &"itStarRodHoldSetStatus"),       # Star Rod
	Callable(Itlgun, &"itLGunHoldSetStatus"),             # Ray Gun
	Callable(Itfflower, &"itFFlowerHoldSetStatus"),       # Fire Flower
	Callable(Ithammer, &"itHammerHoldSetStatus"),         # Hammer
	Callable(Itmsbomb, &"itMSBombHoldSetStatus"),         # Motion-sensor Bomb
	Callable(Itbombhei, &"itBombHeiHoldSetStatus"),       # Bob-omb
	Callable(Itnbumper, &"itNBumperHoldSetStatus"),       # Normal Bumper
	Callable(Itgshell, &"itGShellHoldSetStatus"),         # Green Shell
	Callable(Itrshell, &"itRShellHoldSetStatus"),         # Red Shell
	Callable(Itmball, &"itMBallHoldSetStatus"),           # Poké Ball

	# Fighter items
	Callable(),                                           # Ness PK Fire
	Callable(Itlinkbomb, &"itLinkBombHoldSetStatus"),     # Link Bomb
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80172310
static func itMainSetCommonSpin(item_gobj = null) -> void:
	var ip := itGetStruct(item_gobj)

	ip.spin_step = f32(_itMainPctToDec(ip.attr.spin_speed) * ITEM_SPIN_SPEED_COMMON) if (int(ip.attr.spin_speed) != 0) else 0.0

	if ip.lr == -1:
		ip.spin_step = -ip.spin_step

## 0x80172394
static func itMainSetAppearSpin(item_gobj = null, slow_or_fast = null) -> void:
	# slow_or_fast = 0 if slow, 1 if fast

	var ip := itGetStruct(item_gobj)

	if int(slow_or_fast) == 0:
		if int(ip.attr.spin_speed) != 0:
			ip.spin_step = f32(_itMainPctToDec(ip.attr.spin_speed) * ITEM_SPIN_SPEED_APPEAR_SLOW)
		else:
			ip.spin_step = 0.0

	elif int(ip.attr.spin_speed) != 0:
		ip.spin_step = f32(_itMainPctToDec(ip.attr.spin_speed) * ITEM_SPIN_SPEED_APPEAR_FAST)

	else:
		ip.spin_step = 0.0

## 0x8017245C
static func itMainSetThrownSpin(item_gobj = null, vel = null, is_smash_throw = null) -> void:
	var ip := itGetStruct(item_gobj)

	ip.spin_step = ITEM_SPIN_SPEED_SMASH_THROW if (int(is_smash_throw) != FALSE) else ITEM_SPIN_SPEED_NORMAL_THROW

	if vel.x < 0: # Facing direction, sort of
		ip.spin_step = -ip.spin_step

	ip.spin_step = f32(_itMainPctToDec(ip.attr.spin_speed) * ip.spin_step) if (int(ip.attr.spin_speed) != 0) else 0.0

## 0x80172508
static func itMainSetSpinVelLR(item_gobj = null) -> void:
	var ip := itGetStruct(item_gobj)

	ip.lr = +1 if (ip.physics.vel_air.x >= 0.0) else -1

	itMainSetCommonSpin(item_gobj)

## 0x80172558
static func itMainApplyGravityClampTVel(ip = null, gravity = null, terminal_velocity = null) -> void:
	gravity = f32(gravity)                      # f32 parameters
	terminal_velocity = f32(terminal_velocity)

	ip.physics.vel_air.y -= gravity

	if Lbcommon.lbCommonMag2D(ip.physics.vel_air) > terminal_velocity:
		ip.physics.vel_air = Lbcommon.lbCommonNormDist2D(ip.physics.vel_air).vec
		ip.physics.vel_air = Lbcommon.lbCommonScale2D(ip.physics.vel_air, terminal_velocity)

## 0x801725BC
static func itMainResetPlayerVars(item_gobj = null) -> void:
	var ip := itGetStruct(item_gobj)

	ip.owner_gobj = null
	ip.team = ITEM_TEAM_DEFAULT
	ip.player = ITEM_PORT_DEFAULT
	ip.handicap = ITEM_HANDICAP_DEFAULT
	ip.player_num = 0
	ip.attack_coll.throw_mul = ITEM_THROW_DEFAULT

	ip.display_mode = Itmanager.gITManagerDisplayMode

## 0x801725F8
static func itMainClearAttackRecord(ip = null) -> void:
	for i in ip.attack_coll.attack_records.size():
		var record: GMAttackRecord = ip.attack_coll.attack_records[i]

		record.victim_gobj = null

		record.victim_flags.is_interact_hurt = FALSE
		record.victim_flags.is_interact_shield = FALSE
		record.victim_flags.is_interact_reflect = FALSE

		record.victim_flags.timer_rehit = 0

		record.victim_flags.group_id = 7

## 0x8017275C
static func itMainRefreshAttackColl(item_gobj = null) -> void:
	var ip := itGetStruct(item_gobj)

	itMainClearAttackRecord(ip)

	ip.attack_coll.attack_state = nGMAttackStateNew

	Itprocess.itProcessUpdateAttackPositions(item_gobj)

## 0x8017279C
static func itMainClearOwnerStats(item_gobj = null) -> void:
	var ip := itGetStruct(item_gobj)

	ip.is_damage_all = TRUE

	ip.owner_gobj = null

	ip.team = ITEM_TEAM_DEFAULT

## 0x801727BC
static func itMainCopyDamageStats(item_gobj = null) -> void:
	var ip := itGetStruct(item_gobj)

	ip.owner_gobj = ip.damage_gobj
	ip.team = ip.damage_team
	ip.player = ip.damage_port
	ip.player_num = ip.player_num # Could potentially cause a bug? Didn't they mean damage_player_num?
	ip.handicap = ip.damage_handicap
	ip.display_mode = ip.damage_display_mode

## 0x801727F4
static func itMainGetDamageOutput(ip = null) -> int:
	var damage: int

	if B(ip.is_thrown):
		var mag: float = f32(_itMainVecMag3D(ip.physics.vel_air) * f32(0.1))

		damage = int(f32(f32(ip.attack_coll.damage + mag) * f32(ip.attack_coll.throw_mul)))
	else:
		damage = ip.attack_coll.damage

	return int(f32(f32(damage * f32(ip.attack_coll.stale)) + f32(0.999)))

## 0x80172890
static func itMainCheckShootNoAmmo(item_gobj = null) -> int:
	var ip := itGetStruct(item_gobj)

	if ((ip.kind == nITKindStarRod) or (ip.kind == nITKindLGun) or (ip.kind == nITKindFFlower)) and (ip.multi == 0):
		return TRUE
	else:
		return FALSE

## 0x801728D4
static func itMainDestroyItem(item_gobj = null) -> void:
	var ip := itGetStruct(item_gobj)

	if B(ip.is_hold) and (ip.owner_gobj != null):
		var fp := ftGetStruct(ip.owner_gobj)

		fp.item_gobj = null

		Ftparam.ftParamSetHammerParams(ip.owner_gobj)

	elif (ip.kind < nITKindGroundMonsterStart) or (ip.kind > nITKindGroundMonsterEnd):
		Efmanager.efManagerDustExpandLargeMakeEffect(DObjGetStruct(item_gobj).translate)

	if ip.arrow_gobj != null:
		Objman.gcEjectGObj(ip.arrow_gobj)

	Itmanager.itManagerSetPrevStructAlloc(ip)
	Objman.gcEjectGObj(item_gobj)

## 0x80172984 - Link's Bomb erroneously redeclares this without stat_flags and stat_count
static func itMainSetFighterRelease(item_gobj = null, vel = null, throw_mul = null, stat_flags = null, stat_count = null) -> void:
	var ip := itGetStruct(item_gobj)
	var fighter_gobj = ip.owner_gobj
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3
	var joint_id: int

	Lbcommon.lbCommonEjectTreeDObj(DObjGetStruct(item_gobj))

	pos.x = 0.0
	pos.y = 0.0
	pos.z = 0.0

	joint_id = fp.attr.joint_itemheavy_id if (ip.weight == nITWeightHeavy) else fp.attr.joint_itemlight_id

	pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[joint_id], pos)

	DObjGetStruct(item_gobj).translate.x = pos.x
	DObjGetStruct(item_gobj).translate.y = pos.y
	DObjGetStruct(item_gobj).translate.z = 0.0

	Mpcommon.mpCommonRunItemCollisionDefault(item_gobj, fp.coll_data.p_translate, fp.coll_data)

	fp.item_gobj = null

	ip.is_hold = FALSE

	ip.physics.vel_air = vel

	ip.physics.vel_air = _itMainVecScale3D(ip.physics.vel_air, ip.vel_scale) # syVectorScale3D

	ip.times_thrown = (ip.times_thrown + 1) & 0x7 # u32 times_thrown : 3
	ip.is_thrown = TRUE

	ip.attack_coll.throw_mul = f32(throw_mul)

	ip.attack_coll.stat_flags = GMStatFlags.from_halfword(int(stat_flags) if stat_flags != null else 0) # *(GMStatFlags*)&stat_flags
	ip.attack_coll.stat_count = (int(stat_count) if stat_count != null else 0) & 0xFFFF

	Ftparam.ftParamSetHammerParams(fighter_gobj)
	itMainRefreshAttackColl(item_gobj)

## 0x80172AEC
static func itMainSetFighterDrop(item_gobj = null, vel = null, throw_mul = null) -> void:
	var ip := itGetStruct(item_gobj)
	var owner_gobj = ip.owner_gobj
	var fp := ftGetStruct(owner_gobj)

	if dITMainProcDroppedList[ip.kind].is_valid():
		dITMainProcDroppedList[ip.kind].call(item_gobj)

	itMainSetFighterRelease(item_gobj, vel, throw_mul, nFTStatusAttackIDItemThrow, fp.stat_count)

	Snd.func_800269C0_275C0(ip.drop_sfx)

## 0x80172B78
static func itMainSetFighterThrow(item_gobj = null, vel = null, throw_mul = null, is_smash_throw = null) -> void:
	var ip := itGetStruct(item_gobj)
	var owner_gobj = ip.owner_gobj
	var fp := ftGetStruct(owner_gobj)

	if ip.weight == nITWeightLight:
		if int(is_smash_throw) != FALSE:
			Ftparam.ftParamMakeRumble(fp, 6, 0)
	else:
		Ftparam.ftParamMakeRumble(fp, 9 if (int(is_smash_throw) != FALSE) else 6, 0)

	if dITMainProcThrownList[ip.kind].is_valid():
		dITMainProcThrownList[ip.kind].call(item_gobj)

	itMainSetFighterRelease(item_gobj, vel, throw_mul, fp.stat_flags.halfword, fp.stat_count)

	Efmanager.efManagerSparkleWhiteScaleMakeEffect(DObjGetStruct(item_gobj).translate, 1.0)

	Snd.func_800269C0_275C0(ip.smash_sfx if (int(is_smash_throw) != FALSE) else ip.throw_sfx)

	itMainSetThrownSpin(item_gobj, vel, is_smash_throw)

## 0x80172CA4
static func itMainSetFighterHold(item_gobj = null, fighter_gobj = null) -> void:
	var ip := itGetStruct(item_gobj)
	var fp := ftGetStruct(fighter_gobj)
	var joint: DObj
	var pos: Vector3
	var joint_id: int

	fp.item_gobj = item_gobj
	ip.owner_gobj = fighter_gobj

	ip.is_allow_pickup = FALSE
	ip.is_hold = TRUE

	ip.team = fp.team
	ip.player = fp.player
	ip.handicap = fp.handicap
	ip.player_num = fp.player_num

	ip.physics.vel_air.x = 0.0
	ip.physics.vel_air.y = 0.0
	ip.physics.vel_air.z = 0.0

	ip.display_mode = fp.display_mode

	Itmap.itMapSetAir(ip)

	joint = Objman.gcAddDObjForGObj(item_gobj, null)

	joint.sib_prev.sib_next = null
	joint.sib_prev = null
	joint.child = DObjGetStruct(item_gobj)

	DObjGetStruct(item_gobj).parent = joint

	item_gobj.dobj = joint # item_gobj->obj = joint;

	Objman.gcAddXObjForDObjFixed(joint, 0x52, 0) # REGION_US

	joint_id = fp.attr.joint_itemheavy_id if (ip.weight == nITWeightHeavy) else fp.attr.joint_itemlight_id

	joint.user_data = fp.joints[joint_id] # joint->user_data.p = fp->joints[joint_id]; (render: follows the hand joint)

	pos.x = 0.0
	pos.y = 0.0
	pos.z = 0.0

	pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[joint_id], pos)
	Efmanager.efManagerItemGetSwirlProcUpdate(pos)
	Itmanager._itManagerSetDObjTransformsForGObj(item_gobj, ip.attr.data) # gcSetDObjTransformsForGObj

	if dITMainProcHoldList[ip.kind].is_valid():
		dITMainProcHoldList[ip.kind].call(item_gobj)

	Ftparam.ftParamLinkResetShieldModelParts(fighter_gobj)

	if ip.weight == nITWeightLight:
		Snd.func_800269C0_275C0(nSYAudioFGMItemGet)

	elif int(fp.attr.heavyget_sfx) != nSYAudioFGMVoiceEnd:
		Snd.func_800269C0_275C0(fp.attr.heavyget_sfx)

	Ftparam.ftParamMakeRumble(fp, 6, 0)

	ip.pickup_wait = ITEM_PICKUP_WAIT_DEFAULT

## 0x80172E74
static func itMainSetGroundAllowPickup(item_gobj = null) -> void: # Airborne item becomes grounded?
	var ip := itGetStruct(item_gobj)

	ip.attack_coll.attack_state = nGMAttackStateOff

	ip.physics.vel_air.x = 0.0
	ip.physics.vel_air.y = 0.0
	ip.physics.vel_air.z = 0.0

	ip.is_allow_pickup = TRUE

	ip.times_landed = 0

	itMainResetPlayerVars(item_gobj)
	Itmap.itMapSetGround(ip)

## 0x80172EC8
static func itMainSetStatus(item_gobj = null, status_desc = null, status_id = null) -> void:
	var ip := itGetStruct(item_gobj)
	var desc = status_desc[status_id]

	ip.proc_update = _itMainGetProc(desc, "proc_update")
	ip.proc_map = _itMainGetProc(desc, "proc_map")
	ip.proc_hit = _itMainGetProc(desc, "proc_hit")
	ip.proc_shield = _itMainGetProc(desc, "proc_shield")
	ip.proc_hop = _itMainGetProc(desc, "proc_hop")
	ip.proc_setoff = _itMainGetProc(desc, "proc_setoff")
	ip.proc_reflector = _itMainGetProc(desc, "proc_reflector")
	ip.proc_damage = _itMainGetProc(desc, "proc_damage")

	ip.is_thrown = FALSE

	ip.attack_coll.stat_flags.attack_id = nFTStatusAttackIDNull
	ip.attack_coll.stat_flags.is_projectile = FALSE
	ip.attack_coll.stat_flags.ga = FALSE
	ip.attack_coll.stat_flags.is_smash_attack = FALSE

	ip.attack_coll.stat_count = Ftparam.ftParamGetStatUpdateCount()

## 0x80172F98
static func itMainCheckSetColAnimID(item_gobj = null, colanim_id = null, duration = null) -> int:
	var ip := itGetStruct(item_gobj)

	return Ftparam.ftParamCheckSetColAnimID(ip.colanim, colanim_id, duration)

## 0x80172FBC
static func itMainClearColAnim(item_gobj = null) -> void:
	var ip := itGetStruct(item_gobj)

	Ftparam.ftParamResetColAnim(ip.colanim)

## 0x80172FE0
static func itMainVelSetRebound(item_gobj = null) -> void:
	var ip := itGetStruct(item_gobj)

	ip.physics.vel_air.x = f32(ip.physics.vel_air.x * f32(-0.06))
	ip.physics.vel_air.y = f32(f32(ip.physics.vel_air.y * f32(-0.3)) + 25.0)

## 0x8017301C - Binary search function to get item ID for container drop? Recursive!
## C discards the results of its recursive calls but nothing clobbers v0 afterwards, so the
## function returns the recursive result. blocks[avg + 1] may read one past the table when
## avg + 1 == max; both following branches then yield avg, so the port bounds-checks it.
static func itMainSearchRandomWeight(random = null, weights = null, min_ = null, max_ = null) -> int:
	if max_ == (min_ + 1):
		return min_
	else:
		var avg: int = int((min_ + max_) / 2)

		if random < weights.blocks[avg]:
			return itMainSearchRandomWeight(random, weights, min_, avg)

		elif ((avg + 1) < weights.blocks.size()) and (random < weights.blocks[avg + 1]):
			return avg

		else:
			return itMainSearchRandomWeight(random, weights, avg, max_)

## 0x80173090
static func itMainGetWeightedItemKind(weights = null) -> int:
	return weights.kinds[itMainSearchRandomWeight(syUtilsRandIntRange(weights.weights_sum), weights, 0, weights.valids_num)]

## 0x801730D4
static func itMainMakeContainerItem(parent_gobj = null) -> int:
	var kind: int
	var vel: Vector3 # Item's spawn velocity when falling out of a container

	if Itmanager.gITManagerRandomWeights.weights_sum != 0:
		kind = itMainGetWeightedItemKind(Itmanager.gITManagerRandomWeights)

		if kind <= nITKindCommonEnd:
			vel.x = 0.0

			# Quite ridiculous especially since llITCommonDataContainerVelocitiesY is 0
			vel.y = Itmanager.dITCommonData_Container_VelocitiesY[kind]
			vel.z = 0

			if Itmanager.itManagerMakeItemSetupCommon(parent_gobj, kind, DObjGetStruct(parent_gobj).translate, vel, (ITEM_FLAG_COLLPROJECT | ITEM_FLAG_PARENT_ITEM)) != null:
				itMainSetAppearSpin(parent_gobj, TRUE)

			return TRUE

	return FALSE

## 0x80173180
static func itMainUpdateAttackEvent(item_gobj = null, ev = null) -> void:
	var ip := itGetStruct(item_gobj)

	if ip.multi == int(ev[ip.event_id].timer):
		ip.attack_coll.angle = int(ev[ip.event_id].angle)
		ip.attack_coll.damage = int(ev[ip.event_id].damage)
		ip.attack_coll.size = int(ev[ip.event_id].size)

		ip.event_id = (ip.event_id + 1) & 0xF # u32 event_id : 4

		if ip.event_id == 4:
			ip.event_id = 3

## 0x80173228
static func itMainMakeMonster(item_gobj = null):
	var ip := itGetStruct(item_gobj)
	var monster_gobj
	var mp: Item
	var i: int
	var j: int
	var index: int
	var vel: Vector3
	var monster_data = Itmanager.gITManagerMonsterData

	vel.x = 0.0
	vel.y = 16.0
	vel.z = 0.0

	# Is this checking to spawn Mew? Can only spawn once at least one character has been unlocked.
	if (
		(_itMainGetUnlockMask() & LBBACKUP_UNLOCK_MASK_NEWCOMERS) and
		(syUtilsRandIntRange(151) == 0) and
		(monster_data.monster_curr != nITKindMew) and
		(monster_data.monster_prev != nITKindMew)
	):
		index = nITKindMew
	else:
		i = nITKindMBallCommonStart
		j = i

		while i <= nITKindMBallCommonEnd: # Pokémon IDs
			if (i != monster_data.monster_curr) and (i != monster_data.monster_prev):
				monster_data.monster_id[j - nITKindMBallMonsterStart] = i & 0xFF
				j += 1
			i += 1

		index = monster_data.monster_id[syUtilsRandIntRange(monster_data.monsters_num)]

	if monster_data.monsters_num != 10:
		monster_data.monsters_num = (monster_data.monsters_num - 1) & 0xFF

	monster_data.monster_prev = monster_data.monster_curr
	monster_data.monster_curr = index & 0xFF

	monster_gobj = Itmanager.itManagerMakeItemKind(item_gobj, index, DObjGetStruct(item_gobj).translate, vel, (ITEM_FLAG_COLLPROJECT | ITEM_FLAG_PARENT_ITEM))

	if monster_gobj != null:
		mp = itGetStruct(monster_gobj)

		mp.owner_gobj = ip.owner_gobj
		mp.team = ip.team
		mp.player = ip.player
		mp.handicap = ip.handicap
		mp.player_num = ip.player_num
		mp.display_mode = ip.display_mode

		if G.gSCManagerBattleState.game_type == nSCBattleGameType1PGame:
			if (mp.player == G.gSCManagerSceneData.player) and (mp.kind == nITKindMew):
				G.gSC1PGameBonusMewCatcher = TRUE

	return monster_gobj

## 0x801733E4
static func itMainCommonProcHop(item_gobj = null) -> int:
	var ip := itGetStruct(item_gobj)

	ip.physics.vel_air = syVectorRotateAbout3D(ip.physics.vel_air, ip.shield_collide_dir, f32(ip.shield_collide_angle * 2))
	itMainSetSpinVelLR(item_gobj)

	return FALSE

## 0x80173434
static func itMainCommonProcReflector(item_gobj = null) -> int:
	var ip := itGetStruct(item_gobj)
	var fp := ftGetStruct(ip.owner_gobj)

	if (ip.physics.vel_air.x * fp.lr) < 0.0:
		ip.physics.vel_air.x = -ip.physics.vel_air.x

	return FALSE

# // // // // // // // // // // // //
# //         PORT HELPERS          //
# // // // // // // // // // // // //

## F_PCT_TO_DEC(x): ((float)((x) * 0.01F))
static func _itMainPctToDec(x) -> float:
	return f32(int(x) * f32(0.01))

## syVectorMag3D (src/sys/vector.c) in single precision: sqrtf(x*x + y*y + z*z)
static func _itMainVecMag3D(v: Vector3) -> float:
	return f32(sqrt(f32(f32(f32(v.x * v.x) + f32(v.y * v.y)) + f32(v.z * v.z))))

## syVectorScale3D (src/sys/vector.c): dst *= scale (returns the new dst)
static func _itMainVecScale3D(dst: Vector3, scale: float) -> Vector3:
	dst.x *= scale
	dst.y *= scale
	dst.z *= scale

	return dst

## ITStatusDesc proc pointer -> Callable (NULL == Callable())
static func _itMainGetProc(desc, key: String) -> Callable:
	var proc = desc.get(key, null) if (desc is Dictionary) else desc.get(key)

	if proc is Callable:
		return proc

	return Callable()

## gSCManagerBackupData.unlock_mask. Port: G.LBBackupData does not carry the save's unlock mask
## yet; until it does, everything is treated as unlocked (LBBACKUP_UNLOCK_MASK_ALL).
static func _itMainGetUnlockMask() -> int:
	var unlock_mask = G.gSCManagerBackupData.get(&"unlock_mask")

	if unlock_mask == null:
		return LBBACKUP_UNLOCK_MASK_ALL

	return int(unlock_mask)
