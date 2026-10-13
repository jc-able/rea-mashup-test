## 1:1 port of src/wp/wpprocess.c (ssb-decomp-re): the weapon GObj processes.
##   wpProcessProcWeaponMain      (priority 3) animation, proc_update, movement, stage speed,
##                                 blast-zone check, proc_map, hit positions, rehit timers
##   wpProcessProcSearchHitWeapon (priority 1) weapon-vs-weapon hitbox detection (set-off)
##   wpProcessProcHitCollisions   (priority 0) applies the frame's hit results: proc_hit,
##                                 shield hop / proc_shield, proc_setoff, reflect, absorb
##
## Pointer conventions: wpProcessUpdateHitOffsets(dobj, offset) returns the transformed offset.
## gGCCommonLinks[nGCCommonLinkIDWeapon] is iterated as Sim.get_link(nGCCommonLinkIDWeapon).
class_name Wpprocess
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80165ED0
static func wpProcessUpdateHitOffsets(dobj = null, offset = null) -> Vector3:
	offset.x *= dobj.scale.x
	offset.y *= dobj.scale.y

	offset = syVectorRotate3D(offset, SYVECTOR_AXIS_Z, dobj.rotate.z)

	offset.x += dobj.translate.x
	offset.y += dobj.translate.y
	offset.z += dobj.translate.z

	return offset

## 0x80165F60
static func wpProcessUpdateHitPositions(weapon_gobj = null) -> void: # Update hitbox(es?)
	var wp := wpGetStruct(weapon_gobj)
	var dobj := DObjGetStruct(weapon_gobj)

	for i in wp.attack_coll.attack_count:
		var positions: WPAttackColl.WPAttackPos = wp.attack_coll.attack_pos[i]
		var offset: Vector3 = wp.attack_coll.offsets[i]
		var translate: Vector3 = dobj.translate

		match wp.attack_coll.attack_state:
			nGMAttackStateOff:
				pass

			nGMAttackStateNew:
				positions.pos_curr = offset

				if (offset.x == 0.0) and (offset.y == 0.0) and (offset.z == 0.0):
					positions.pos_curr.x += translate.x
					positions.pos_curr.y += translate.y
					positions.pos_curr.z += translate.z
				else:
					positions.pos_curr = wpProcessUpdateHitOffsets(dobj, positions.pos_curr)

				wp.attack_coll.attack_state = nGMAttackStateTransfer

				positions.unk_wphitpos_0x18 = FALSE
				positions.unk_wphitpos_0x5C = 0

			nGMAttackStateTransfer, nGMAttackStateInterpolate:
				if wp.attack_coll.attack_state == nGMAttackStateTransfer:
					wp.attack_coll.attack_state = nGMAttackStateInterpolate

					# fallthrough

				positions.pos_prev = positions.pos_curr
				positions.pos_curr = offset

				if (offset.x == 0.0) and (offset.y == 0.0) and (offset.z == 0.0):
					positions.pos_curr.x += translate.x
					positions.pos_curr.y += translate.y
					positions.pos_curr.z += translate.z
				else:
					positions.pos_curr = wpProcessUpdateHitOffsets(dobj, positions.pos_curr)

				positions.unk_wphitpos_0x18 = FALSE
				positions.unk_wphitpos_0x5C = 0

## 0x801661E0
static func wpProcessUpdateAttackRecords(weapon_gobj = null) -> void: # Set hitbox victim array
	var wp := wpGetStruct(weapon_gobj)
	var record: GMAttackRecord
	var attack_coll: WPAttackColl

	attack_coll = wp.attack_coll

	if attack_coll.attack_state != nGMAttackStateOff:
		for i in wp.attack_coll.attack_records.size():
			record = attack_coll.attack_records[i]

			if record.victim_gobj != null:
				if record.victim_flags.timer_rehit > 0:
					record.victim_flags.timer_rehit -= 1

					if record.victim_flags.timer_rehit <= 0:
						record.victim_gobj = null

						record.victim_flags.is_interact_hurt = FALSE
						record.victim_flags.is_interact_shield = FALSE
						record.victim_flags.is_interact_reflect = FALSE
						record.victim_flags.is_interact_absorb = FALSE

						record.victim_flags.group_id = 7

## 0x801662BC
static func wpProcessProcWeaponMain(weapon_gobj = null) -> void: # Run item logic pass 1 (animation, physics, collision, despawn check)
	var wp := wpGetStruct(weapon_gobj)

	if not B(wp.is_hitlag_weapon):
		var dobj: DObj # Vec3f *translate = &DObjGetStruct(weapon_gobj)->translate.vec.f;

		ObjAnim.gcPlayAnimAll(weapon_gobj)

		if wp.proc_update.is_valid():
			if B(wp.proc_update.call(weapon_gobj)):
				Wpmain.wpMainDestroyWeapon(weapon_gobj)
				return

		dobj = DObjGetStruct(weapon_gobj)

		wp.coll_data.pos_prev = dobj.translate

		dobj.translate.x += wp.physics.vel_air.x
		dobj.translate.y += wp.physics.vel_air.y
		dobj.translate.z += wp.physics.vel_air.z

		wp.coll_data.pos_diff.x = dobj.translate.x - wp.coll_data.pos_prev.x
		wp.coll_data.pos_diff.y = dobj.translate.y - wp.coll_data.pos_prev.y
		wp.coll_data.pos_diff.z = dobj.translate.z - wp.coll_data.pos_prev.z

		if (
			(wp.ga == nMPKineticsGround) and
			(wp.coll_data.floor_line_id != -1) and
			(wp.coll_data.floor_line_id != -2) and
			B(Mpcollision.mpCollisionCheckExistLineID(wp.coll_data.floor_line_id))
		):
			wp.coll_data.vel_speed = Mpcollision.mpCollisionGetSpeedLineID(wp.coll_data.floor_line_id)

			dobj.translate.x += wp.coll_data.vel_speed.x
			dobj.translate.y += wp.coll_data.vel_speed.y
			dobj.translate.z += wp.coll_data.vel_speed.z
		else:
			wp.coll_data.vel_speed.x = 0.0
			wp.coll_data.vel_speed.y = 0.0
			wp.coll_data.vel_speed.z = 0.0

		var ground_data = Mpcollision.gMPCollisionGroundData

		if ground_data != null and ( # port guard: no stage collision loaded
			(dobj.translate.y < ground_data.map_bound_bottom) or
			(dobj.translate.x > ground_data.map_bound_right) or
			(dobj.translate.x < ground_data.map_bound_left) or
			(dobj.translate.y > ground_data.map_bound_top) or
			(dobj.translate.z < -20000.0) or
			(dobj.translate.z > 20000.0)
		):
			if (not wp.proc_dead.is_valid()) or B(wp.proc_dead.call(weapon_gobj)):
				Wpmain.wpMainDestroyWeapon(weapon_gobj)
				return

		if wp.proc_map.is_valid():
			wp.coll_data.mask_prev = wp.coll_data.mask_curr
			wp.coll_data.mask_curr = 0
			wp.coll_data.is_coll_end = FALSE
			wp.coll_data.mask_stat = 0
			wp.coll_data.mask_unk = 0

			if B(wp.proc_map.call(weapon_gobj)):
				Wpmain.wpMainDestroyWeapon(weapon_gobj)
				return

		wpProcessUpdateHitPositions(weapon_gobj)
		wpProcessUpdateAttackRecords(weapon_gobj)

## 0x80166594
static func wpProcessSetHitInteractStats(attack_coll = null, victim_gobj = null, attack_type = null, attack_group_id = null) -> void:
	var i := 0
	var records_num: int = attack_coll.attack_records.size()

	while i < records_num:
		if victim_gobj == attack_coll.attack_records[i].victim_gobj: # Run this if the victim we're checking has already been hit
			_wpProcessApplyHitType(attack_coll.attack_records[i].victim_flags, attack_type, attack_group_id)
			break
		i += 1

	if i == records_num: # Check if all victim slots have been filled
		i = 0
		while i < records_num: # Reset hit count and increment until there is an empty slot
			if attack_coll.attack_records[i].victim_gobj == null:
				break
			i += 1

		if i == records_num:
			i = 0 # Reset hit count again if all victim slots are full

		attack_coll.attack_records[i].victim_gobj = victim_gobj # Store victim's pointer to slot

		_wpProcessApplyHitType(attack_coll.attack_records[i].victim_flags, attack_type, attack_group_id)

## The `switch (attack_type)` body shared by both halves of wpProcessSetHitInteractStats.
static func _wpProcessApplyHitType(victim_flags: GMHitFlags, attack_type, attack_group_id) -> void:
	match attack_type:
		nGMHitTypeDamage:
			victim_flags.is_interact_hurt = TRUE

		nGMHitTypeShield:
			victim_flags.is_interact_shield = TRUE

		nGMHitTypeShieldRehit:
			victim_flags.is_interact_shield = TRUE
			victim_flags.timer_rehit = WEAPON_REHIT_TIME_DEFAULT

		nGMHitTypeReflect:
			victim_flags.is_interact_reflect = TRUE
			victim_flags.timer_rehit = WEAPON_REHIT_TIME_DEFAULT

		nGMHitTypeAbsorb:
			victim_flags.is_interact_absorb = TRUE

		nGMHitTypeAttack:
			victim_flags.group_id = int(attack_group_id) & 0x7 # u32 group_id : 3

		nGMHitTypeDamageRehit:
			victim_flags.is_interact_hurt = TRUE
			victim_flags.timer_rehit = WEAPON_REHIT_TIME_DEFAULT

		_:
			pass

## 0x8016679C
static func wpProcessUpdateHitInteractStats(this_wp = null, attack_coll = null, victim_gobj = null, attack_type = null, attack_group_id = null) -> void:
	if this_wp.group_id != 0:
		for other_gobj in Sim.get_link(nGCCommonLinkIDWeapon):
			var other_wp := wpGetStruct(other_gobj)

			if other_wp.group_id == this_wp.group_id:
				wpProcessSetHitInteractStats(other_wp.attack_coll, victim_gobj, attack_type, attack_group_id)
	else:
		wpProcessSetHitInteractStats(attack_coll, victim_gobj, attack_type, attack_group_id)

## 0x80166854
static func wpProcessUpdateAttackStatWeapon(this_wp = null, this_attack_coll = null, this_attack_id = null, victim_wp = null, victim_attack_coll = null, victim_attack_id = null, this_gobj = null, victim_gobj = null) -> void:
	var this_attack_coll_damage: int = Wpmain.wpMainGetStaledDamage(this_wp)
	var victim_attack_coll_damage: int = Wpmain.wpMainGetStaledDamage(victim_wp)
	var pos
	var priority_high: int

	pos = Gmcollision.gmCollisionGetWeaponAttacksPosition(victim_attack_coll, victim_attack_id, this_attack_coll, this_attack_id)

	priority_high = this_attack_coll.priority

	if victim_attack_coll.priority <= priority_high:
		wpProcessUpdateHitInteractStats(victim_wp, victim_attack_coll, this_gobj, nGMHitTypeAttack, 0)

		if victim_wp.hit_attack_damage < victim_attack_coll_damage:
			victim_wp.hit_attack_damage = victim_attack_coll_damage

		Efmanager.efManagerSetOffMakeEffect(pos, victim_attack_coll_damage)

	priority_high = victim_attack_coll.priority

	if this_attack_coll.priority <= priority_high:
		wpProcessUpdateHitInteractStats(this_wp, this_attack_coll, victim_gobj, nGMHitTypeAttack, 0)

		if this_wp.hit_attack_damage < this_attack_coll_damage:
			this_wp.hit_attack_damage = this_attack_coll_damage

		Efmanager.efManagerSetOffMakeEffect(pos, this_attack_coll_damage)

## 0x80166954
static func wpProcessProcSearchHitWeapon(this_gobj = null) -> void: # Scan for hitbox collision with other items
	var other_wp
	var this_wp
	var other_hit: WPAttackColl
	var this_attack_coll: WPAttackColl
	var these_flags_group_id: int
	var those_flags_group_id: int
	var is_check_self: int

	this_wp = wpGetStruct(this_gobj)
	this_attack_coll = this_wp.attack_coll

	if B(this_attack_coll.can_setoff) and (this_attack_coll.attack_state != nGMAttackStateOff) and (this_attack_coll.interact_mask & GMHITCOLLISION_FLAG_WEAPON):
		is_check_self = FALSE

		for other_gobj in Sim.get_link(nGCCommonLinkIDWeapon):
			other_wp = wpGetStruct(other_gobj)
			other_hit = other_wp.attack_coll

			if other_gobj == this_gobj:
				is_check_self = TRUE # Not really sure what to name this

			elif is_check_self != FALSE:
				if this_wp.owner_gobj == other_wp.owner_gobj:
					continue # goto next_gobj

				if (G.gSCManagerBattleState.is_team_battle == TRUE) and (G.gSCManagerBattleState.is_team_attack == FALSE) and (this_wp.team == other_wp.team):
					continue # goto next_gobj

				if (other_hit.attack_state != nGMAttackStateOff) and B(other_hit.can_setoff):
					if other_hit.interact_mask & GMHITCOLLISION_FLAG_WEAPON:
						those_flags_group_id = 7

						for m in other_hit.attack_records.size():
							if this_gobj == other_hit.attack_records[m].victim_gobj:
								those_flags_group_id = other_hit.attack_records[m].victim_flags.group_id # those_flags = victim_flags
								break

						if those_flags_group_id == 7:
							these_flags_group_id = 7

							for n in this_attack_coll.attack_records.size():
								if other_gobj == this_attack_coll.attack_records[n].victim_gobj:
									these_flags_group_id = this_attack_coll.attack_records[n].victim_flags.group_id # these_flags = victim_flags
									break

							if these_flags_group_id == 7:
								var is_hit := false

								for i in other_hit.attack_count:
									for j in this_attack_coll.attack_count:
										if B(Gmcollision.gmCollisionCheckWeaponAttacksCollide(other_hit, i, this_attack_coll, j)):
											wpProcessUpdateAttackStatWeapon(other_wp, other_hit, i, this_wp, this_attack_coll, j, other_gobj, this_gobj)

											is_hit = true # goto next_gobj
											break
									if is_hit:
										break
			# next_gobj: other_gobj = other_gobj->link_next;

## 0x80166BE4
static func wpProcessProcHitCollisions(weapon_gobj = null) -> void:
	var wp := wpGetStruct(weapon_gobj)

	if (wp.hit_normal_damage != 0) or (wp.hit_refresh_damage != 0):
		if wp.proc_hit.is_valid():
			if B(wp.proc_hit.call(weapon_gobj)):
				Wpmain.wpMainDestroyWeapon(weapon_gobj)
				return

	if wp.hit_shield_damage != 0:
		var is_goto_next_check := false

		if B(wp.attack_coll.can_hop) and (wp.ga == nMPKineticsAir):
			if wp.shield_collide_angle < WEAPON_HOP_ANGLE_DEFAULT:
				wp.shield_collide_angle -= F_CST_DTOR32(90.0)

				if wp.shield_collide_angle < 0.0:
					wp.shield_collide_angle = 0.0

				if wp.proc_hop.is_valid():
					if B(wp.proc_hop.call(weapon_gobj)):
						Wpmain.wpMainDestroyWeapon(weapon_gobj)
						return

				is_goto_next_check = true # goto next_check;

		if not is_goto_next_check:
			if wp.proc_shield.is_valid():
				if B(wp.proc_shield.call(weapon_gobj)):
					Wpmain.wpMainDestroyWeapon(weapon_gobj)
					return

	# next_check:
	if wp.hit_attack_damage != 0:
		if wp.proc_setoff.is_valid():
			if B(wp.proc_setoff.call(weapon_gobj)):
				Wpmain.wpMainDestroyWeapon(weapon_gobj)
				return

	if wp.reflect_gobj != null:
		var fp: Fighter

		wp.owner_gobj = wp.reflect_gobj

		fp = ftGetStruct(wp.reflect_gobj)

		wp.team = fp.team
		wp.player = fp.player
		wp.display_mode = fp.display_mode
		wp.player_num = fp.player_num
		wp.handicap = fp.handicap
		# REGION_US
		wp.attack_coll.stat_flags = wp.reflect_stat_flags.dup()
		wp.attack_coll.stat_count = wp.reflect_stat_count

		if wp.proc_reflector.is_valid():
			if B(wp.proc_reflector.call(weapon_gobj)):
				Wpmain.wpMainDestroyWeapon(weapon_gobj)
				return

		if not B(wp.is_static_damage):
			wp.attack_coll.damage = int((wp.attack_coll.damage * WEAPON_REFLECT_MUL_DEFAULT) + WEAPON_REFLECT_ADD_DEFAULT)

			if wp.attack_coll.damage > WEAPON_REFLECT_TIME_DEFAULT:
				wp.attack_coll.damage = WEAPON_REFLECT_TIME_DEFAULT

	if wp.absorb_gobj != null:
		if wp.proc_absorb.is_valid():
			if B(wp.proc_absorb.call(weapon_gobj)):
				Wpmain.wpMainDestroyWeapon(weapon_gobj)
				return

	wp.hit_normal_damage = 0
	wp.hit_refresh_damage = 0
	wp.hit_attack_damage = 0
	wp.hit_shield_damage = 0
	wp.reflect_gobj = null
