## 1:1 port of src/it/itprocess.c (ssb-decomp-re): the item GObj processes.
##   itProcessProcItemMain      (priority 3) hitlag, animation, proc_update, pickup timer / flashing,
##                               movement, stage speed, blast-zone check, proc_map, hitbox positions
##   itProcessProcSearchHitAll  (priority 1) item hurtbox vs fighter / item / weapon hitboxes and
##                               item-vs-item / item-vs-weapon hitbox clashes (set-off)
##   itProcessProcHitCollisions (priority 0) applies the frame's results: proc_damage, proc_hit,
##                               shield hop / proc_shield, proc_setoff, reflect, hitlag
##
## gGCCommonLinks[link] lists are iterated as Sim.get_link(link) (same order). C `goto` flow is kept
## with explicit flags. Effects / sounds are called exactly where the C calls them.
class_name Itprocess
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8016F280
static func itProcessUpdateAttackPositions(item_gobj = null) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	for i in ip.attack_coll.attack_count:
		var attack_pos: ITAttackColl.ITAttackPos = ip.attack_coll.attack_pos[i]
		var offset: Vector3 = ip.attack_coll.offsets[i]

		match ip.attack_coll.attack_state:
			nGMAttackStateOff:
				pass

			nGMAttackStateNew:
				attack_pos.pos_curr.x = offset.x + dobj.translate.x
				attack_pos.pos_curr.y = offset.y + dobj.translate.y
				attack_pos.pos_curr.z = offset.z + dobj.translate.z

				ip.attack_coll.attack_state = nGMAttackStateTransfer

				attack_pos.unk_ithitpos_0x18 = FALSE
				attack_pos.unk_ithitpos_0x5C = 0

			nGMAttackStateTransfer, nGMAttackStateInterpolate:
				if ip.attack_coll.attack_state == nGMAttackStateTransfer:
					ip.attack_coll.attack_state = nGMAttackStateInterpolate

					# fallthrough

				attack_pos.pos_prev = attack_pos.pos_curr

				attack_pos.pos_curr.x = offset.x + dobj.translate.x
				attack_pos.pos_curr.y = offset.y + dobj.translate.y
				attack_pos.pos_curr.z = offset.z + dobj.translate.z

				attack_pos.unk_ithitpos_0x18 = FALSE
				attack_pos.unk_ithitpos_0x5C = 0

## 0x8016F3D4
static func itProcessUpdateAttackRecords(item_gobj = null) -> void:
	var ip := itGetStruct(item_gobj)
	var record: GMAttackRecord
	var it_attack_coll: ITAttackColl

	it_attack_coll = ip.attack_coll

	if it_attack_coll.attack_state != nGMAttackStateOff:
		for i in ip.attack_coll.attack_records.size():
			record = it_attack_coll.attack_records[i]

			if record.victim_gobj != null:
				if record.victim_flags.timer_rehit > 0:
					record.victim_flags.timer_rehit -= 1

					if record.victim_flags.timer_rehit <= 0:
						record.victim_gobj = null

						record.victim_flags.is_interact_hurt = FALSE
						record.victim_flags.is_interact_shield = FALSE
						record.victim_flags.is_interact_reflect = FALSE

						record.victim_flags.group_id = 7

## 0x8016F534
static func itProcessProcItemMain(item_gobj = null) -> void:
	var ip := itGetStruct(item_gobj)

	if ip.hitlag_tics > 0:
		ip.hitlag_tics -= 1

	if ip.hitlag_tics <= 0:
		ObjAnim.gcPlayAnimAll(item_gobj)

	if ip.hitlag_tics <= 0:
		if ip.proc_update.is_valid():
			if B(ip.proc_update.call(item_gobj)):
				Itmain.itMainDestroyItem(item_gobj)
				return

	if B(ip.is_allow_pickup):
		ip.pickup_wait = (ip.pickup_wait - 1) & 0xFFF # u32 pickup_wait : 12

		if ip.pickup_wait <= ITEM_DESPAWN_FLASH_BEGIN_DEFAULT:
			if ip.pickup_wait == 0:
				Efmanager.efManagerSparkleWhiteScaleMakeEffect(DObjGetStruct(item_gobj).translate, 1.0)

				Itmain.itMainDestroyItem(item_gobj)
				return

			if (ip.pickup_wait % 2) != 0: # Make item invisible on odd frames; when in doubt, simply do "& 1"
				item_gobj.gobj_flags ^= GOBJ_FLAG_HIDDEN

		if ip.arrow_timer == 0:
			ip.arrow_timer = ITEM_ARROW_FLASH_INT_DEFAULT

		ip.arrow_timer = (ip.arrow_timer - 1) & 0xFF
	else:
		item_gobj.gobj_flags = GOBJ_FLAG_NONE

	if not B(ip.is_hold):
		var translate: DObj = DObjGetStruct(item_gobj) # Vec3f *translate = &DObjGetStruct(item_gobj)->translate.vec.f;
		var ground_data = Mpcollision.gMPCollisionGroundData

		ip.coll_data.pos_prev = translate.translate

		if ip.hitlag_tics == 0:
			translate.translate.x += ip.physics.vel_air.x
			translate.translate.y += ip.physics.vel_air.y
			translate.translate.z += ip.physics.vel_air.z

		ip.coll_data.pos_diff.x = translate.translate.x - ip.coll_data.pos_prev.x
		ip.coll_data.pos_diff.y = translate.translate.y - ip.coll_data.pos_prev.y
		ip.coll_data.pos_diff.z = translate.translate.z - ip.coll_data.pos_prev.z

		if B(ip.is_attach_surface) and (Mpcollision.mpCollisionCheckExistLineID(ip.attach_line_id & 0xFFFF) != FALSE):
			var coll_data: MPCollData = ip.coll_data

			ip.coll_data.vel_speed = Mpcollision.mpCollisionGetSpeedLineID(ip.attach_line_id & 0xFFFF)

			translate.translate.x += coll_data.vel_speed.x
			translate.translate.y += coll_data.vel_speed.y
			translate.translate.z += coll_data.vel_speed.z

		elif (ip.ga == nMPKineticsGround) and (ip.coll_data.floor_line_id != -1) and (ip.coll_data.floor_line_id != -2) and (Mpcollision.mpCollisionCheckExistLineID(ip.coll_data.floor_line_id) != FALSE):
			ip.coll_data.vel_speed = Mpcollision.mpCollisionGetSpeedLineID(ip.coll_data.floor_line_id)

			translate.translate.x += ip.coll_data.vel_speed.x
			translate.translate.y += ip.coll_data.vel_speed.y
			translate.translate.z += ip.coll_data.vel_speed.z
		else:
			ip.coll_data.vel_speed.x = 0.0
			ip.coll_data.vel_speed.y = 0.0
			ip.coll_data.vel_speed.z = 0.0

		if (ground_data != null) and ( # port guard: no stage collision loaded
			(translate.translate.y < ground_data.map_bound_bottom) or
			(translate.translate.x > ground_data.map_bound_right) or
			(translate.translate.x < ground_data.map_bound_left) or
			(translate.translate.y > ground_data.map_bound_top)
		):
			if (not ip.proc_dead.is_valid()) or B(ip.proc_dead.call(item_gobj)):
				Itmain.itMainDestroyItem(item_gobj)
				return

		if ip.proc_map.is_valid():
			ip.coll_data.mask_prev = ip.coll_data.mask_curr
			ip.coll_data.mask_curr = 0
			ip.coll_data.is_coll_end = FALSE
			ip.coll_data.mask_stat = 0
			ip.coll_data.mask_unk = 0

			if B(ip.proc_map.call(item_gobj)):
				Itmain.itMainDestroyItem(item_gobj)
				return

		itProcessUpdateAttackPositions(item_gobj)
		itProcessUpdateAttackRecords(item_gobj)

	Itvisuals.itVisualsUpdateColAnim(item_gobj)

## 0x8016F930
static func itProcessSetHitInteractStats(it_attack_coll = null, victim_gobj = null, attack_type = null, group_id = null) -> void:
	var i: int = 0
	var records_num: int = it_attack_coll.attack_records.size()

	while i < records_num:
		if victim_gobj == it_attack_coll.attack_records[i].victim_gobj: # Run this if the victim we're checking has already been hit
			_itProcessApplyHitType(it_attack_coll.attack_records[i].victim_flags, attack_type, group_id)
			break
		i += 1

	if i == records_num: # Check if all victim slots have been filled
		i = 0

		while i < records_num: # Reset hit count and increment until there is an empty slot
			if it_attack_coll.attack_records[i].victim_gobj == null:
				break
			i += 1

		if i == records_num:
			i = 0 # Reset hit count again if all victim slots are full

		it_attack_coll.attack_records[i].victim_gobj = victim_gobj # Store victim's pointer to slot

		_itProcessApplyHitType(it_attack_coll.attack_records[i].victim_flags, attack_type, group_id)

## 0x8016FB18 - Item's hurtbox gets hit by a fighter
static func itProcessUpdateDamageStatFighter(fp = null, attack_coll = null, ip = null, damage_coll = null, fighter_gobj = null, item_gobj = null) -> void:
	var damage: int
	var damage_knockback: float
	var pos: Vector3

	Ftmain.ftMainSetHitInteractStats(fp, attack_coll.group_id, item_gobj, nGMHitTypeDamage, 0, FALSE)

	damage = attack_coll.damage

	if fp.attack_damage < damage:
		fp.attack_damage = damage

	if damage_coll.hitstatus == nGMHitStatusNormal:
		ip.damage_queue += damage

		if ip.damage_highest < damage:
			ip.damage_highest = damage
			ip.damage_angle = attack_coll.angle
			ip.damage_element = attack_coll.element

			ip.damage_lr = +1 if (DObjGetStruct(item_gobj).translate.x < DObjGetStruct(fighter_gobj).translate.x) else -1

			ip.damage_gobj = fighter_gobj
			ip.damage_team = fp.team
			ip.damage_port = fp.player
			ip.damage_player_num = fp.player_num
			ip.damage_handicap = fp.handicap
			ip.damage_display_mode = fp.display_mode

		if B(ip.is_allow_knockback):
			damage_knockback = Ftparam.ftParamGetCommonKnockback(
				ip.percent_damage,
				ip.damage_queue,
				damage,
				attack_coll.knockback_weight,
				attack_coll.knockback_scale,
				attack_coll.knockback_base,
				1.0,
				fp.handicap,
				ip.handicap
			)
			if ip.damage_knockback < damage_knockback:
				ip.damage_knockback = damage_knockback

		pos = Gmcollision.gmCollisionGetFighterAttackItemDamagePosition(attack_coll, damage_coll, item_gobj)

		match attack_coll.element:
			nGMHitElementFire:
				Efmanager.efManagerDamageFireMakeEffect(pos, attack_coll.damage)

			nGMHitElementElectric:
				Efmanager.efManagerDamageElectricMakeEffect(pos, attack_coll.damage)

			nGMHitElementCoin:
				Efmanager.efManagerDamageCoinMakeEffect(pos)

			nGMHitElementSlash:
				Efmanager.efManagerDamageSlashMakeEffect(pos, attack_coll.damage, Gmcollision.gmCollisionGetDamageSlashRotation(fp, attack_coll))

			_:
				Efmanager.efManagerDamageNormalLightMakeEffect(pos, fp.player, attack_coll.damage, 0)

	Ftmain.ftMainPlayHitSFX(fp, attack_coll)

## 0x8016FD4C
static func itProcessUpdateAttackStatItem(this_ip = null, this_hit = null, this_attack_id = null, victim_ip = null, victim_hit = null, victim_attack_id = null, this_gobj = null, victim_gobj = null) -> void:
	var victim_hit_damage: int = Itmain.itMainGetDamageOutput(victim_ip)
	var this_hit_damage: int = Itmain.itMainGetDamageOutput(this_ip)
	var pos: Vector3
	var highest_priority: int

	pos = Gmcollision.gmCollisionGetItemAttackItemAttackPosition(victim_hit, victim_attack_id, this_hit, this_attack_id)

	highest_priority = this_hit.priority

	if victim_hit.priority <= highest_priority:
		itProcessSetHitInteractStats(victim_hit, this_gobj, nGMHitTypeAttack, 0)

		if victim_ip.hit_attack_damage < victim_hit_damage:
			victim_ip.hit_attack_damage = victim_hit_damage

		Efmanager.efManagerSetOffMakeEffect(pos, victim_hit_damage)

	highest_priority = victim_hit.priority

	if this_hit.priority <= highest_priority:
		itProcessSetHitInteractStats(this_hit, victim_gobj, nGMHitTypeAttack, 0)

		if this_ip.hit_attack_damage < this_hit_damage:
			this_ip.hit_attack_damage = this_hit_damage

		Efmanager.efManagerSetOffMakeEffect(pos, this_hit_damage)

## 0x8016FE4C
static func itProcessUpdateAttackStatWeapon(wp = null, wp_attack_coll = null, wp_attack_id = null, ip = null, it_attack_coll = null, it_attack_id = null, weapon_gobj = null, item_gobj = null) -> void:
	var wp_attack_coll_damage: int = Wpmain.wpMainGetStaledDamage(wp)
	var it_attack_coll_damage: int = Itmain.itMainGetDamageOutput(ip)
	var pos: Vector3
	var highest_priority: int

	pos = Gmcollision.gmCollisionGetWeaponAttackItemAttackPosition(wp_attack_coll, wp_attack_id, it_attack_coll, it_attack_id)

	highest_priority = wp_attack_coll.priority

	if it_attack_coll.priority <= highest_priority:
		itProcessSetHitInteractStats(it_attack_coll, weapon_gobj, nGMHitTypeAttack, 0)

		if ip.hit_attack_damage < it_attack_coll_damage:
			ip.hit_attack_damage = it_attack_coll_damage

		Efmanager.efManagerSetOffMakeEffect(pos, it_attack_coll_damage)

	highest_priority = it_attack_coll.priority

	if wp_attack_coll.priority <= highest_priority:
		Wpprocess.wpProcessUpdateHitInteractStats(wp, wp_attack_coll, item_gobj, nGMHitTypeAttack, 0)

		if wp.hit_attack_damage < wp_attack_coll_damage:
			wp.hit_attack_damage = wp_attack_coll_damage

		Efmanager.efManagerSetOffMakeEffect(pos, wp_attack_coll_damage)

## 0x8016FF4C - Item's hurtbox gets hit by another item
static func itProcessUpdateDamageStatItem(attack_ip = null, attack_coll = null, attack_id = null, defend_ip = null, damage_coll = null, attack_gobj = null, defend_gobj = null) -> void:
	var damage: int
	var knockback: float
	var is_rehit: int
	var vel: float
	var pos: Vector3
	var lr: int

	damage = Itmain.itMainGetDamageOutput(attack_ip)

	is_rehit = TRUE if ((defend_ip.type == nITTypeDamage) and B(attack_coll.can_rehit_item)) else FALSE

	itProcessSetHitInteractStats(attack_coll, defend_gobj, nGMHitTypeDamageRehit if (is_rehit != FALSE) else nGMHitTypeDamage, 0)

	if is_rehit != FALSE:
		if attack_ip.hit_refresh_damage < damage:
			attack_ip.hit_refresh_damage = damage

	elif attack_ip.hit_normal_damage < damage:
		attack_ip.hit_normal_damage = damage

	vel = -attack_ip.physics.vel_air.x if (attack_ip.physics.vel_air.x < 0.0) else attack_ip.physics.vel_air.x

	if vel < 5.0:
		lr = -1 if (DObjGetStruct(defend_gobj).translate.x < DObjGetStruct(attack_gobj).translate.x) else +1
		attack_ip.hit_lr = lr
	else:
		lr = -1 if (attack_ip.physics.vel_air.x < 0) else +1

		attack_ip.hit_lr = lr

	if damage_coll.hitstatus == nGMHitStatusNormal:
		defend_ip.damage_queue += damage

		if defend_ip.damage_highest < damage:
			defend_ip.damage_highest = damage # Last source of damage?
			defend_ip.damage_angle = attack_coll.angle
			defend_ip.damage_element = attack_coll.element

			vel = -attack_ip.physics.vel_air.x if (attack_ip.physics.vel_air.x < 0.0) else attack_ip.physics.vel_air.x

			if vel < 5.0:
				lr = +1 if (DObjGetStruct(defend_gobj).translate.x < DObjGetStruct(attack_gobj).translate.x) else -1
				defend_ip.damage_lr = lr
			else:
				lr = +1 if (attack_ip.physics.vel_air.x < 0) else -1

				defend_ip.damage_lr = lr

			defend_ip.damage_gobj = attack_ip.owner_gobj
			defend_ip.damage_team = attack_ip.team
			defend_ip.damage_port = attack_ip.player
			defend_ip.damage_player_num = attack_ip.player_num
			defend_ip.damage_handicap = attack_ip.handicap
			defend_ip.damage_display_mode = attack_ip.display_mode

		if B(defend_ip.is_allow_knockback):
			knockback = Ftparam.ftParamGetCommonKnockback(
				defend_ip.percent_damage,
				defend_ip.damage_queue,
				damage,
				attack_coll.knockback_weight,
				attack_coll.knockback_scale,
				attack_coll.knockback_base,
				1.0,
				attack_ip.handicap,
				defend_ip.handicap
			)
			if defend_ip.damage_knockback < knockback:
				defend_ip.damage_knockback = knockback

		if B(attack_ip.is_hitlag_victim):
			pos = Gmcollision.gmCollisionGetItemAttackItemDamagePosition(attack_coll, attack_id, damage_coll, defend_gobj)

			match attack_coll.element:
				nGMHitElementFire:
					Efmanager.efManagerDamageFireMakeEffect(pos, damage)

				nGMHitElementElectric:
					Efmanager.efManagerDamageElectricMakeEffect(pos, damage)

				nGMHitElementCoin:
					Efmanager.efManagerDamageCoinMakeEffect(pos)

				_:
					Efmanager.efManagerDamageNormalLightMakeEffect(pos, attack_ip.player, damage, 0)

	Snd.func_800269C0_275C0(attack_coll.fgm_id)

## 0x801702C8 - Item's hurtbox gets hit by a weapon
static func itProcessUpdateDamageStatWeapon(wp = null, attack_coll = null, attack_id = null, ip = null, damage_coll = null, weapon_gobj = null, item_gobj = null) -> void:
	var damage: int
	var is_rehit: int
	var knockback: float
	var pos: Vector3
	var vel: float
	var lr: int

	damage = Wpmain.wpMainGetStaledDamage(wp)

	is_rehit = TRUE if ((ip.type == nITTypeDamage) and B(attack_coll.can_rehit_item)) else FALSE

	Wpprocess.wpProcessUpdateHitInteractStats(wp, attack_coll, item_gobj, nGMHitTypeDamageRehit if (is_rehit != FALSE) else nGMHitTypeDamage, 0)

	if is_rehit != FALSE:
		if wp.hit_refresh_damage < damage:
			wp.hit_refresh_damage = damage

	elif wp.hit_normal_damage < damage:
		wp.hit_normal_damage = damage

	if damage_coll.hitstatus == nGMHitStatusNormal:
		ip.damage_queue += damage

		if ip.damage_highest < damage:
			ip.damage_highest = damage
			ip.damage_angle = attack_coll.angle
			ip.damage_element = attack_coll.element

			vel = -wp.physics.vel_air.x if (wp.physics.vel_air.x < 0.0) else wp.physics.vel_air.x

			if vel < 5.0:
				lr = +1 if (DObjGetStruct(item_gobj).translate.x < DObjGetStruct(weapon_gobj).translate.x) else -1
				ip.damage_lr = lr
			else:
				lr = +1 if (wp.physics.vel_air.x < 0) else -1

				ip.damage_lr = lr

			ip.damage_gobj = wp.owner_gobj
			ip.damage_team = wp.team
			ip.damage_port = wp.player
			ip.damage_player_num = wp.player_num
			ip.damage_handicap = wp.handicap
			ip.damage_display_mode = wp.display_mode

		if B(ip.is_allow_knockback):
			knockback = Ftparam.ftParamGetCommonKnockback(
				ip.percent_damage,
				ip.damage_queue,
				damage,
				attack_coll.knockback_weight,
				attack_coll.knockback_scale,
				attack_coll.knockback_base,
				1.0,
				wp.handicap,
				ip.handicap
			)
			if ip.damage_knockback < knockback:
				ip.damage_knockback = knockback

		if B(wp.is_hitlag_victim):
			pos = Gmcollision.gmCollisionGetWeaponAttackItemDamagePosition(attack_coll, attack_id, damage_coll, item_gobj)

			match attack_coll.element:
				nGMHitElementFire:
					Efmanager.efManagerDamageFireMakeEffect(pos, damage)

				nGMHitElementElectric:
					Efmanager.efManagerDamageElectricMakeEffect(pos, damage)

				nGMHitElementCoin:
					Efmanager.efManagerDamageCoinMakeEffect(pos)

				_:
					Efmanager.efManagerDamageNormalLightMakeEffect(pos, wp.player, damage, 0)

	Snd.func_800269C0_275C0(attack_coll.fgm_id)

## 0x801705C4
static func itProcessSearchHitFighter(item_gobj = null) -> void: # Check fighters for hit detection
	var ip := itGetStruct(item_gobj)
	var bs = G.gSCManagerBattleState
	var k: int
	var attack_coll: FTAttackColl
	var damage_coll: ITDamageColl
	var fp: Fighter

	if ip.damage_coll.interact_mask & GMHITCOLLISION_FLAG_FIGHTER:
		for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
			if not fighter_gobj.is_alive:
				continue

			if (fighter_gobj == ip.owner_gobj) and not B(ip.is_damage_all):
				continue # goto next_gobj

			fp = ftGetStruct(fighter_gobj)

			if (bs.is_team_battle == TRUE) and (bs.is_team_attack == FALSE) and (((fp.throw_team if (fp.throw_gobj != null) else fp.team)) == ip.team) and not B(ip.is_damage_all):
				continue # goto next_gobj

			if B(fp.is_catchstatus):
				continue # goto next_gobj

			k = 0

			if (ip.owner_gobj != null) and (fp.throw_gobj != null) and (fp.throw_gobj == ip.owner_gobj):
				continue # goto next_gobj

			for i in Ftmain.gFTMainIsDamageDetect.size():
				attack_coll = fp.attack_colls[i]

				if attack_coll.attack_state != nGMAttackStateOff:
					if ((ip.ga == nMPKineticsAir) and B(attack_coll.is_hit_air)) or ((ip.ga == nMPKineticsGround) and B(attack_coll.is_hit_ground)):
						var fighter_victim_flags := _itProcessGetVictimFlags(attack_coll.attack_records, item_gobj)

						if (not B(fighter_victim_flags.is_interact_hurt)) and (not B(fighter_victim_flags.is_interact_shield)) and (fighter_victim_flags.group_id == 7):
							Ftmain.gFTMainIsDamageDetect[i] = TRUE
							k += 1

							continue

				Ftmain.gFTMainIsDamageDetect[i] = FALSE

			if k != 0:
				for i in fp.attack_colls.size():
					damage_coll = ip.damage_coll

					if Ftmain.gFTMainIsDamageDetect[i] != FALSE:
						if ip.damage_coll.hitstatus == nGMHitStatusNone:
							break

						if damage_coll.hitstatus == nGMHitStatusIntangible:
							continue

						if Gmcollision.gmCollisionCheckFighterAttackItemDamageCollide(fp.attack_colls[i], damage_coll, item_gobj) != FALSE:
							itProcessUpdateDamageStatFighter(fp, fp.attack_colls[i], ip, damage_coll, fighter_gobj, item_gobj)
			# next_gobj: fighter_gobj = fighter_gobj->link_next;

## 0x8017088C
static func itProcessSearchHitItem(this_gobj = null) -> void: # Check other items for hit detection
	var this_ip := itGetStruct(this_gobj)
	var this_hit: ITAttackColl = this_ip.attack_coll
	var other_ip: Item
	var other_hit: ITAttackColl
	var is_check_self: int
	var damage_coll: ITDamageColl
	var bs = G.gSCManagerBattleState

	if this_ip.damage_coll.interact_mask & GMHITCOLLISION_FLAG_ITEM:
		is_check_self = FALSE

		for other_gobj in Sim.get_link(nGCCommonLinkIDItem):
			if not other_gobj.is_alive:
				continue

			if other_gobj == this_gobj:
				is_check_self = TRUE
				continue

			other_ip = itGetStruct(other_gobj)
			other_hit = other_ip.attack_coll

			if (this_ip.owner_gobj == other_ip.owner_gobj) and not B(this_ip.is_damage_all):
				continue # goto next_gobj

			if (bs.is_team_battle == TRUE) and (bs.is_team_attack == FALSE) and (this_ip.team == other_ip.team) and not B(this_ip.is_damage_all):
				continue # goto next_gobj

			if other_hit.attack_state == nGMAttackStateOff:
				continue # goto next_gobj

			if not (other_hit.interact_mask & GMHITCOLLISION_FLAG_ITEM):
				continue # goto next_gobj

			var those_flags := _itProcessGetVictimFlags(other_hit.attack_records, this_gobj)

			if B(those_flags.is_interact_hurt) or B(those_flags.is_interact_shield) or (those_flags.group_id != 7):
				continue # goto next_gobj

			var is_goto_next_gobj := false

			if (is_check_self != FALSE) and B(this_hit.can_setoff) and B(other_hit.can_setoff) and (this_ip.owner_gobj != other_ip.owner_gobj):
				if (bs.is_team_battle != TRUE) or (bs.is_team_attack != FALSE) or (this_ip.team != other_ip.team):
					if this_hit.attack_state != nGMAttackStateOff:
						if this_hit.interact_mask & GMHITCOLLISION_FLAG_ITEM:
							var these_flags := _itProcessGetVictimFlags(this_hit.attack_records, other_gobj)

							if not (B(these_flags.is_interact_hurt) or B(these_flags.is_interact_shield) or (these_flags.group_id != 7)): # else goto hurtbox_check
								var is_goto_hurtbox_check := false

								for i in other_hit.attack_count:
									for j in this_hit.attack_count:
										if Gmcollision.gmCollisionCheckItemAttacksCollide(other_hit, i, this_hit, j) != FALSE:
											itProcessUpdateAttackStatItem(other_ip, other_hit, i, this_ip, this_hit, j, other_gobj, this_gobj)

											if other_ip.hit_attack_damage != 0:
												is_goto_next_gobj = true
												break

											elif this_ip.hit_attack_damage != 0:
												is_goto_hurtbox_check = true
												break
									if is_goto_next_gobj or is_goto_hurtbox_check:
										break
			if is_goto_next_gobj:
				continue # goto next_gobj

			# hurtbox_check:
			for i in other_hit.attack_count:
				damage_coll = this_ip.damage_coll

				if this_ip.damage_coll.hitstatus == nGMHitStatusNone:
					break

				if damage_coll.hitstatus == nGMHitStatusIntangible:
					continue

				if Gmcollision.gmCollisionCheckItemAttackDamageCollide(other_hit, i, damage_coll, this_gobj) != FALSE:
					itProcessUpdateDamageStatItem(other_ip, other_hit, i, this_ip, damage_coll, other_gobj, this_gobj)

					break # goto next_gobj
			# next_gobj: other_gobj = other_gobj->link_next;

## 0x80170C84
static func itProcessSearchHitWeapon(item_gobj = null) -> void: # Check weapons for hit detection
	var ip := itGetStruct(item_gobj)
	var it_attack_coll: ITAttackColl = ip.attack_coll
	var wp: Weapon
	var wp_attack_coll: WPAttackColl
	var damage_coll: ITDamageColl
	var bs = G.gSCManagerBattleState

	if ip.damage_coll.interact_mask & GMHITCOLLISION_FLAG_WEAPON:
		for weapon_gobj in Sim.get_link(nGCCommonLinkIDWeapon):
			if not weapon_gobj.is_alive:
				continue

			wp = wpGetStruct(weapon_gobj)
			wp_attack_coll = wp.attack_coll

			if (ip.owner_gobj == wp.owner_gobj) and not B(ip.is_damage_all):
				continue # goto next_gobj

			if (bs.is_team_battle == TRUE) and (bs.is_team_attack == FALSE) and (ip.team == wp.team) and not B(ip.is_damage_all):
				continue # goto next_gobj

			if wp_attack_coll.attack_state != nGMAttackStateOff:
				if wp_attack_coll.interact_mask & GMHITCOLLISION_FLAG_ITEM:
					var those_flags := _itProcessGetVictimFlags(wp_attack_coll.attack_records, item_gobj)

					if B(those_flags.is_interact_hurt) or B(those_flags.is_interact_shield) or (those_flags.group_id != 7):
						continue # goto next_gobj

					var is_goto_next_gobj := false

					if B(it_attack_coll.can_setoff) and B(wp_attack_coll.can_setoff) and (ip.owner_gobj != wp.owner_gobj):
						if (bs.is_team_battle != TRUE) or (bs.is_team_attack != FALSE) or (ip.team != wp.team):
							if it_attack_coll.attack_state != nGMAttackStateOff:
								if it_attack_coll.interact_mask & GMHITCOLLISION_FLAG_WEAPON:
									var these_flags := _itProcessGetVictimFlags(it_attack_coll.attack_records, weapon_gobj)

									if not (B(these_flags.is_interact_hurt) or B(these_flags.is_interact_shield) or (these_flags.group_id != 7)): # else goto hurtbox_check
										var is_goto_hurtbox_check := false

										for i in wp_attack_coll.attack_count:
											for j in it_attack_coll.attack_count:
												if Gmcollision.gmCollisionCheckWeaponAttackItemAttackCollide(wp_attack_coll, i, it_attack_coll, j) != FALSE:
													itProcessUpdateAttackStatWeapon(wp, wp_attack_coll, i, ip, it_attack_coll, j, weapon_gobj, item_gobj)

													if wp.hit_attack_damage != 0:
														is_goto_next_gobj = true
														break

													elif ip.hit_attack_damage != 0:
														is_goto_hurtbox_check = true
														break
											if is_goto_next_gobj or is_goto_hurtbox_check:
												break
					if is_goto_next_gobj:
						continue # goto next_gobj

					# hurtbox_check:
					for i in wp_attack_coll.attack_count:
						damage_coll = ip.damage_coll

						if ip.damage_coll.hitstatus == nGMHitStatusNone:
							break

						elif damage_coll.hitstatus == nGMHitStatusIntangible:
							continue

						elif Gmcollision.gmCollisionCheckWeaponAttackItemDamageCollide(wp_attack_coll, i, damage_coll, item_gobj) != FALSE:
							itProcessUpdateDamageStatWeapon(wp, wp_attack_coll, i, ip, damage_coll, weapon_gobj, item_gobj)

							break
			# next_gobj: weapon_gobj = weapon_gobj->link_next;

## 0x80171080
static func itProcessProcSearchHitAll(item_gobj = null) -> void:
	var ip := itGetStruct(item_gobj)

	if not B(ip.is_hold):
		itProcessSearchHitFighter(item_gobj)
		itProcessSearchHitItem(item_gobj)
		itProcessSearchHitWeapon(item_gobj)

## 0x801710C4
static func itProcessProcHitCollisions(item_gobj = null) -> void:
	var ip := itGetStruct(item_gobj)

	if ip.damage_queue != 0:
		ip.percent_damage += ip.damage_queue

		if ip.percent_damage > GMCOMMON_PERCENT_DAMAGE_MAX:
			ip.percent_damage = GMCOMMON_PERCENT_DAMAGE_MAX

		ip.damage_lag = ip.damage_queue

		if ip.proc_damage.is_valid():
			if B(ip.proc_damage.call(item_gobj)):
				Itmain.itMainDestroyItem(item_gobj)
				return

	if (ip.hit_normal_damage != 0) or (ip.hit_refresh_damage != 0):
		if ip.proc_hit.is_valid():
			if B(ip.proc_hit.call(item_gobj)):
				Itmain.itMainDestroyItem(item_gobj)
				return

	if ip.hit_shield_damage != 0:
		var is_goto_next_check := false

		if B(ip.attack_coll.can_hop) and (ip.ga == nMPKineticsAir):
			if ip.shield_collide_angle < ITEM_HOP_ANGLE_DEFAULT:
				ip.shield_collide_angle = f32(ip.shield_collide_angle - F_CST_DTOR32(90.0))

				if ip.shield_collide_angle < 0.0:
					ip.shield_collide_angle = 0.0

				if ip.proc_hop.is_valid():
					if B(ip.proc_hop.call(item_gobj)):
						Itmain.itMainDestroyItem(item_gobj)
						return

				is_goto_next_check = true # goto next_check;

		if not is_goto_next_check:
			if ip.proc_shield.is_valid():
				if B(ip.proc_shield.call(item_gobj)):
					Itmain.itMainDestroyItem(item_gobj)
					return

	# next_check:
	if ip.hit_attack_damage != 0:
		if ip.proc_setoff.is_valid():
			if B(ip.proc_setoff.call(item_gobj)):
				Itmain.itMainDestroyItem(item_gobj)
				return

	if ip.reflect_gobj != null:
		var fp: Fighter

		ip.owner_gobj = ip.reflect_gobj

		fp = ftGetStruct(ip.reflect_gobj)

		ip.team = fp.team
		ip.player = fp.player
		ip.player_num = fp.player_num
		ip.handicap = fp.handicap

		# REGION_US
		ip.attack_coll.stat_flags = ip.reflect_stat_flags.dup()
		ip.attack_coll.stat_count = ip.reflect_stat_count

		if ip.proc_reflector.is_valid():
			if B(ip.proc_reflector.call(item_gobj)):
				Itmain.itMainDestroyItem(item_gobj)
				return

		if not B(ip.is_static_damage):
			ip.attack_coll.damage = int(f32(f32(ip.attack_coll.damage * f32(ITEM_REFLECT_MUL_DEFAULT)) + f32(ITEM_REFLECT_ADD_DEFAULT)))

			if ip.attack_coll.damage > ITEM_REFLECT_MAX_DEFAULT:
				ip.attack_coll.damage = ITEM_REFLECT_MAX_DEFAULT

	if ip.damage_lag != 0:
		ip.hitlag_tics = Ftparam.ftParamGetHitLag(ip.damage_lag, nFTCommonStatusWait, 1.0) # Maybe 10 is the "none" status ID?

	ip.hit_normal_damage = 0
	ip.hit_refresh_damage = 0
	ip.hit_attack_damage = 0
	ip.hit_shield_damage = 0

	ip.reflect_gobj = null

	ip.damage_highest = 0
	ip.damage_queue = 0
	ip.damage_lag = 0
	ip.damage_knockback = 0.0

# // // // // // // // // // // // //
# //         PORT HELPERS          //
# // // // // // // // // // // // //

## The `switch (attack_type)` body shared by both halves of itProcessSetHitInteractStats.
static func _itProcessApplyHitType(victim_flags: GMHitFlags, attack_type, group_id) -> void:
	match attack_type:
		nGMHitTypeDamage:
			victim_flags.is_interact_hurt = TRUE

		nGMHitTypeShield:
			victim_flags.is_interact_shield = TRUE

		nGMHitTypeShieldRehit:
			victim_flags.is_interact_shield = TRUE
			victim_flags.timer_rehit = ITEM_REHIT_TIME_DEFAULT

		nGMHitTypeReflect:
			victim_flags.is_interact_reflect = TRUE
			victim_flags.timer_rehit = ITEM_REHIT_TIME_DEFAULT

		nGMHitTypeAttack:
			victim_flags.group_id = int(group_id) & 0x7 # u32 group_id : 3

		nGMHitTypeDamageRehit:
			victim_flags.is_interact_hurt = TRUE
			victim_flags.timer_rehit = ITEM_REHIT_TIME_DEFAULT

		_:
			pass

## GMHitFlags flags = {hurt = shield = FALSE, group_id = 7}; copied from the record whose
## victim_gobj matches (C local struct copy).
static func _itProcessGetVictimFlags(records: Array, victim_gobj) -> GMHitFlags:
	for record in records:
		if victim_gobj == record.victim_gobj:
			return record.victim_flags.dup()

	var flags := GMHitFlags.new()

	flags.is_interact_hurt = FALSE
	flags.is_interact_shield = FALSE
	flags.group_id = 7

	return flags
