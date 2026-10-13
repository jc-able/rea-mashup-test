## Port of src/wp/wppikachu/wppikachuthunderjolt.c (Pikachu Thunder Jolt: aerial ball + ground crawler).
class_name Wppikachuthunderjolt
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## WPAttributes at gFTDataPikachuSpecial1 + llPikachuSpecial1ThunderJoltAirWeaponAttributes (0x00):
## src/relocData/244_PikachuSpecial1.c dPikachuSpecial1_ThunderJoltAir_WeaponAttributes (US; checked against ROM file 244).
const dPikachuSpecial1_ThunderJoltAir_WeaponAttributes := {
	"data": null,                       # PikachuSpecial3 + 0x270 (model; not exported)
	"p_mobjsubs": null,
	"anim_joints": null,                # PikachuSpecial3 + 0x360 (visual; not exported)
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 50,
	"map_coll_center": 0,
	"map_coll_bottom": -50,
	"map_coll_width": 50,
	"size": 200,
	"angle": 361,
	"knockback_scale": 30,
	"damage": 10,
	"element": 2,
	"knockback_weight": 0,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 1,
	"sfx": 23,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 1,
	"can_reflect": 1,
	"can_absorb": 1,
	"can_shield": 1,
	"knockback_base": 50,
}

## WPAttributes at gFTDataPikachuSpecial1 + llPikachuSpecial1ThunderJoltGroundWeaponAttributes (0x34):
## src/relocData/244_PikachuSpecial1.c dPikachuSpecial1_ThunderJoltGround_WeaponAttributes (US; checked against ROM file 244).
const dPikachuSpecial1_ThunderJoltGround_WeaponAttributes := {
	"data": null,                       # PikachuSpecial3 + 0x1888 DObjDesc tree (model; not exported)
	"p_mobjsubs": null,                 # PikachuSpecial3 + 0x1018
	"anim_joints": null,                # dPikachuSpecial3_ThunderJoltBAnimJoint_AnimJoint (visual)
	"p_matanim_joints": null,           # dPikachuSpecial3_ThunderJoltBMatAnimJoint_MatAnimJoint (visual)
	"attack_offsets": [Vector3(0, 100, 0), Vector3(0, 0, 0)],
	"map_coll_top": 200,
	"map_coll_center": 100,
	"map_coll_bottom": 0,
	"map_coll_width": 50,
	"size": 200,
	"angle": 361,
	"knockback_scale": 20,
	"damage": 7,
	"element": 2,
	"knockback_weight": 0,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 1,
	"sfx": 23,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 0,
	"can_hop": 0,
	"can_reflect": 1,
	"can_absorb": 1,
	"can_shield": 1,
	"knockback_base": 10,
}

## lbRelocGetFileData(AObjEvent32**, gFTDataPikachuSpecial3, &llPikachuSpecial3ThunderJoltBAnimJoint) and
## (..., &llPikachuSpecial3ThunderJoltBMatAnimJoint): visual-only animation tables (the root DObj, which
## carries the hitbox, has no AnimJoint). Not exported yet; a data loader / render layer may set these.
static var dPikachuSpecial3ThunderJoltBAnimJoint = null
static var dPikachuSpecial3ThunderJoltBMatAnimJoint = null

static var dWPPikachuThunderJoltAirWeaponDesc := {
	"flags": 0x00,                                              # Render flags?
	"kind": nWPKindThunderJoltAir,                              # Weapon Kind
	# p_weapon = &gFTDataPikachuSpecial1, o_attributes = &llPikachuSpecial1ThunderJoltAirWeaponAttributes
	"attributes": dPikachuSpecial1_ThunderJoltAir_WeaponAttributes,
	"transform_types": {"tk1": nGCMatrixKindTra, "tk2": 0x2E, "tk3": 0},
	"proc_update": Callable(Wppikachuthunderjolt, &"wpPikachuThunderJoltAirProcUpdate"),
	"proc_map": Callable(Wppikachuthunderjolt, &"wpPikachuThunderJoltAirProcMap"),
	"proc_hit": Callable(Wppikachuthunderjolt, &"wpPikachuThunderJoltAirProcHit"),
	"proc_shield": Callable(Wppikachuthunderjolt, &"wpPikachuThunderJoltAirProcHit"),
	"proc_hop": Callable(Wppikachuthunderjolt, &"wpPikachuThunderJoltAirProcHop"),
	"proc_setoff": Callable(Wppikachuthunderjolt, &"wpPikachuThunderJoltAirProcHit"),
	"proc_reflector": Callable(Wppikachuthunderjolt, &"wpPikachuThunderJoltAirProcReflector"),
	"proc_absorb": Callable(Wppikachuthunderjolt, &"wpPikachuThunderJoltAirProcHit"),
	"visual_kind": "pikachu_thunder_jolt_air",
}

static var dWPPikachuThunderJoltGroundWeaponDesc := {
	"flags": 0x03,                                              # Render flags? (WEAPON_FLAG_DOBJDESC | WEAPON_FLAG_DOBJLINKS)
	"kind": nWPKindThunderJoltGround,                           # Weapon Kind
	# p_weapon = &gFTDataPikachuSpecial1, o_attributes = &llPikachuSpecial1ThunderJoltGroundWeaponAttributes
	"attributes": dPikachuSpecial1_ThunderJoltGround_WeaponAttributes,
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0},
	"proc_update": Callable(Wppikachuthunderjolt, &"wpPikachuThunderJoltGroundProcUpdate"),
	"proc_map": Callable(Wppikachuthunderjolt, &"wpPikachuThunderJoltGroundProcMap"),
	"proc_hit": Callable(Wppikachuthunderjolt, &"wpPikachuThunderJoltGroundProcHit"),
	"proc_shield": Callable(Wppikachuthunderjolt, &"wpPikachuThunderJoltGroundProcHit"),
	"proc_hop": Callable(),
	"proc_setoff": Callable(Wppikachuthunderjolt, &"wpPikachuThunderJoltGroundProcHit"),
	"proc_reflector": Callable(Wppikachuthunderjolt, &"wpPikachuThunderJoltGroundProcReflector"),
	"proc_absorb": Callable(Wppikachuthunderjolt, &"wpPikachuThunderJoltGroundProcHit"),
	"visual_kind": "pikachu_thunder_jolt_ground",
}

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80169390
static func wpPikachuThunderJoltAirProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if Wpmain.wpMainDecLifeCheckExpire(wp) != FALSE:
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

		return TRUE
	else:
		Wpmain.wpMainApplyGravityClampTVel(wp, WPPIKACHUJOLT_GRAVITY, WPPIKACHUJOLT_TVEL)

	return FALSE

## 0x801693EC
static func wpPikachuThunderJoltAirProcMap(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var pos: Vector3

	if Wpmap.wpMapTestAllCheckFloor(weapon_gobj) != FALSE:
		wpPikachuThunderJoltGroundMakeWeapon(weapon_gobj, DObjGetStruct(weapon_gobj).translate, nMPLineKindFloor)

		return TRUE

	elif wp.coll_data.mask_curr & MAP_FLAG_LWALL:
		pos = Mpcollision.mpCollisionGetLWallEdgeU(wp.coll_data.lwall_line_id)

		if DObjGetStruct(weapon_gobj).translate.y > pos.y:
			DObjGetStruct(weapon_gobj).translate.y = pos.y

		pos = Mpcollision.mpCollisionGetLWallEdgeD(wp.coll_data.lwall_line_id)

		if DObjGetStruct(weapon_gobj).translate.y < pos.y:
			DObjGetStruct(weapon_gobj).translate.y = pos.y

		wpPikachuThunderJoltGroundMakeWeapon(weapon_gobj, DObjGetStruct(weapon_gobj).translate, nMPLineKindLWall)

		return TRUE

	elif wp.coll_data.mask_curr & MAP_FLAG_RWALL:
		pos = Mpcollision.mpCollisionGetRWallEdgeU(wp.coll_data.rwall_line_id)

		if DObjGetStruct(weapon_gobj).translate.y > pos.y:
			DObjGetStruct(weapon_gobj).translate.y = pos.y

		pos = Mpcollision.mpCollisionGetRWallEdgeD(wp.coll_data.rwall_line_id)

		if DObjGetStruct(weapon_gobj).translate.y < pos.y:
			DObjGetStruct(weapon_gobj).translate.y = pos.y

		wpPikachuThunderJoltGroundMakeWeapon(weapon_gobj, DObjGetStruct(weapon_gobj).translate, nMPLineKindRWall)

		return TRUE

	return FALSE

## 0x8016953C
static func wpPikachuThunderJoltAirProcHit(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	Efmanager.efManagerImpactShockMakeEffect(DObjGetStruct(weapon_gobj).translate, wp.attack_coll.damage)

	return TRUE

## 0x8016956C
static func wpPikachuThunderJoltAirProcHop(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	wp.physics.vel_air = syVectorRotateAbout3D(wp.physics.vel_air, wp.shield_collide_dir, wp.shield_collide_angle * 2)

	return FALSE

## 0x801695B0
static func wpPikachuThunderJoltAirProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)

	wp.lifetime = WPPIKACHUJOLT_LIFETIME

	Wpmain.wpMainReflectorSetLR(wp, fp)

	return FALSE

## 0x801695E4
static func wpPikachuThunderJoltAirMakeWeapon(fighter_gobj, pos: Vector3, vel: Vector3):
	var weapon_gobj = Wpmanager.wpManagerMakeWeapon(fighter_gobj, dWPPikachuThunderJoltAirWeaponDesc, pos, (WEAPON_FLAG_COLLPROJECT | WEAPON_FLAG_PARENT_FIGHTER))
	var wp: Weapon

	if weapon_gobj == null:
		return null

	wp = wpGetStruct(weapon_gobj)

	wp.lifetime = WPPIKACHUJOLT_LIFETIME

	wp.physics.vel_air = vel

	return weapon_gobj

## 0x80169654
static func wpPikachuThunderJoltGroundAddAnim(weapon_gobj) -> void:
	ObjAnim.gcAddAnimAll(
		weapon_gobj,
		dPikachuSpecial3ThunderJoltBAnimJoint,      # lbRelocGetFileData(AObjEvent32**, gFTDataPikachuSpecial3, &llPikachuSpecial3ThunderJoltBAnimJoint)
		dPikachuSpecial3ThunderJoltBMatAnimJoint,   # lbRelocGetFileData(AObjEvent32***, gFTDataPikachuSpecial3, &llPikachuSpecial3ThunderJoltBMatAnimJoint)
		0.0
	)
	ObjAnim.gcPlayAnimAll(weapon_gobj)

## 0x801696A0
static func wpPikachuThunderJoltGroundProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var line_type: int

	if weapon_gobj.anim_frame == WPPIKACHUJOLT_ANIM_PUSH_FRAME:
		Efmanager.efManagerPikachuThunderJoltMakeEffect(DObjGetStruct(weapon_gobj).translate, DObjGetStruct(weapon_gobj).rotate.z)
		wpPikachuThunderJoltGroundAddAnim(weapon_gobj)

	if Wpmain.wpMainDecLifeCheckExpire(wp) != FALSE:
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)
		return TRUE

	wp.physics.vel_air.x = cosf(DObjGetStruct(weapon_gobj).rotate.z) * WPPIKACHUJOLT_VEL
	wp.physics.vel_air.y = __sinf(DObjGetStruct(weapon_gobj).rotate.z) * WPPIKACHUJOLT_VEL

	line_type = wp.weapon_vars.thunder_jolt.line_type

	if line_type == nMPLineKindFloor:
		wp.physics.vel_air.x *= wp.lr

	elif (line_type == nMPLineKindRWall) or (line_type == nMPLineKindLWall):
		if wp.lr == 2:
			if wp.physics.vel_air.y < 0.0:
				wp.physics.vel_air.y *= -1.0

		if wp.lr == 3:
			if wp.physics.vel_air.y > 0.0:
				wp.physics.vel_air.y *= -1.0

	return FALSE

## 0x8016981C
## mpCollisionCheck*LineCollisionDiff(position, translate, &pos, &line_id, NULL, NULL) and
## mpCollisionGetLRCommon*/GetFCCommonFloor(line_id, &pos, NULL, NULL, &rotate) follow the
## Dictionary out-parameter convention; their outputs are only written by C when they return TRUE.
static func wpPikachuThunderJoltGroundGetStatus(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var pos: Vector3
	var rotate: Vector3
	var line_id: int = 0
	var line_type: int = wp.weapon_vars.thunder_jolt.line_type
	var r
	var rr

	if line_type == nMPLineKindFloor:
		if wp.lr == +1:
			r = Mpcollision.mpCollisionCheckLWallLineCollisionDiff(wp.coll_data.pos_prev, wp.coll_data.p_translate)

			if r.ret != FALSE:
				pos = r.ga_last
				line_id = r.stand_line_id

			if (r.ret != FALSE) and (Mpcollision.mpCollisionGetEdgeUnderLLineID(wp.coll_data.floor_line_id) != line_id):
				rr = Mpcollision.mpCollisionGetLRCommonLWall(line_id, pos)

				if rr.ret != FALSE:
					rotate = rr.angle

					wp.weapon_vars.thunder_jolt.line_type = nMPLineKindLWall
					wp.coll_data.lwall_line_id = line_id
					wp.lr = 2

					DObjGetStruct(weapon_gobj).translate = pos

					wpPikachuThunderJoltGroundAddAnim(weapon_gobj)

					DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(-rotate.x, rotate.y)

					return nWPPikachuThunderJoltStatusActive

				return nWPPikachuThunderJoltStatusDestroy
			# break
		else:
			r = Mpcollision.mpCollisionCheckRWallLineCollisionDiff(wp.coll_data.pos_prev, wp.coll_data.p_translate)

			if r.ret != FALSE:
				pos = r.ga_last
				line_id = r.stand_line_id

			if (r.ret != FALSE) and (Mpcollision.mpCollisionGetEdgeUnderRLineID(wp.coll_data.floor_line_id) != line_id):
				rr = Mpcollision.mpCollisionGetLRCommonRWall(line_id, pos)

				if rr.ret != FALSE:
					rotate = rr.angle

					wp.weapon_vars.thunder_jolt.line_type = nMPLineKindRWall
					wp.coll_data.rwall_line_id = line_id
					wp.lr = 2

					DObjGetStruct(weapon_gobj).translate = pos

					wpPikachuThunderJoltGroundAddAnim(weapon_gobj)

					DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(-rotate.x, rotate.y)

					return nWPPikachuThunderJoltStatusActive

				return nWPPikachuThunderJoltStatusDestroy
			# break

	elif line_type == nMPLineKindLWall:
		if wp.lr == 3:
			r = Mpcollision.mpCollisionCheckFloorLineCollisionDiff(wp.coll_data.pos_prev, wp.coll_data.p_translate)

			if r.ret != FALSE:
				pos = r.ga_last
				line_id = r.stand_line_id

			if (r.ret != FALSE) and (Mpcollision.mpCollisionGetEdgeRightULineID(wp.coll_data.lwall_line_id) != line_id):
				rr = Mpcollision.mpCollisionGetFCCommonFloor(line_id, pos)

				if rr.ret != FALSE:
					rotate = rr.angle

					wp.weapon_vars.thunder_jolt.line_type = nMPLineKindFloor
					wp.coll_data.floor_line_id = line_id
					wp.lr = -1

					DObjGetStruct(weapon_gobj).translate = pos

					wpPikachuThunderJoltGroundAddAnim(weapon_gobj)

					DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(-rotate.x, rotate.y)

					return nWPPikachuThunderJoltStatusActive

				return nWPPikachuThunderJoltStatusDestroy
			# break
		else:
			r = Mpcollision.mpCollisionCheckCeilLineCollisionDiff(wp.coll_data.pos_prev, wp.coll_data.p_translate)

			if r.ret != FALSE:
				return nWPPikachuThunderJoltStatusDestroy
			# break

	elif line_type == nMPLineKindRWall:
		if wp.lr == 3:
			r = Mpcollision.mpCollisionCheckFloorLineCollisionDiff(wp.coll_data.pos_prev, wp.coll_data.p_translate)

			if r.ret != FALSE:
				pos = r.ga_last
				line_id = r.stand_line_id

			if (r.ret != FALSE) and (Mpcollision.mpCollisionGetEdgeLeftULineID(wp.coll_data.rwall_line_id) != line_id):
				rr = Mpcollision.mpCollisionGetFCCommonFloor(line_id, pos)

				if rr.ret != FALSE:
					rotate = rr.angle

					wp.weapon_vars.thunder_jolt.line_type = nMPLineKindFloor
					wp.coll_data.floor_line_id = line_id
					wp.lr = +1

					DObjGetStruct(weapon_gobj).translate = pos

					wpPikachuThunderJoltGroundAddAnim(weapon_gobj)

					DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(-rotate.x, rotate.y)

					return nWPPikachuThunderJoltStatusActive

				return nWPPikachuThunderJoltStatusDestroy
		else:
			r = Mpcollision.mpCollisionCheckCeilLineCollisionDiff(wp.coll_data.pos_prev, wp.coll_data.p_translate)

			if r.ret != FALSE:
				return nWPPikachuThunderJoltStatusDestroy
		# break

	# default: break

	DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(-wp.weapon_vars.thunder_jolt.rotate.x, wp.weapon_vars.thunder_jolt.rotate.y)

	return nWPPikachuThunderJoltStatusNull

## 0x80169BF0
static func wpPikachuThunderJoltGroundCheckDestroy(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var angle: Vector3   # C: uninitialized stack value when the lookup below fails (or no case matches)
	var line_type: int
	var r

	wpPikachuThunderJoltGroundAddAnim(weapon_gobj)

	line_type = wp.weapon_vars.thunder_jolt.line_type

	if line_type == nMPLineKindFloor:
		r = Mpcollision.mpCollisionGetFCCommonFloor(wp.coll_data.floor_line_id, DObjGetStruct(weapon_gobj).translate)
		if r.ret != FALSE:
			angle = r.angle

	elif line_type == nMPLineKindLWall:
		r = Mpcollision.mpCollisionGetLRCommonLWall(wp.coll_data.lwall_line_id, DObjGetStruct(weapon_gobj).translate)
		if r.ret != FALSE:
			angle = r.angle

	elif line_type == nMPLineKindRWall:
		r = Mpcollision.mpCollisionGetLRCommonRWall(wp.coll_data.rwall_line_id, DObjGetStruct(weapon_gobj).translate)
		if r.ret != FALSE:
			angle = r.angle

	if syVectorAngleDiff3D(angle, wp.weapon_vars.thunder_jolt.rotate) > WPPIKACHUJOLT_ROTATE_ANGLE_MAX:
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

		return TRUE
	else:
		DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(-angle.x, angle.y)

	return FALSE

## 0x80169D08
static func wpPikachuThunderJoltGroundProcMap(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var coll_type: int
	var dist: float
	var line_id: int
	var line_type: int = wp.weapon_vars.thunder_jolt.line_type
	var r

	if line_type == nMPLineKindFloor:
		if Mpcollision.mpCollisionCheckExistLineID(wp.coll_data.floor_line_id) == FALSE:
			Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

			return TRUE

		r = Mpcollision.mpCollisionGetFCCommonFloor(wp.coll_data.floor_line_id, DObjGetStruct(weapon_gobj).translate)

		if r.ret != FALSE:
			dist = r.dist
			wp.weapon_vars.thunder_jolt.rotate = r.angle

			DObjGetStruct(weapon_gobj).translate.y += dist

			if wpPikachuThunderJoltGroundGetStatus(weapon_gobj) == nWPPikachuThunderJoltStatusDestroy:
				Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

				return TRUE

			return FALSE

		if wp.lr == +1:
			line_id = Mpcollision.mpCollisionGetEdgeUnderRLineID(wp.coll_data.floor_line_id)

		elif wp.lr == -1:
			line_id = Mpcollision.mpCollisionGetEdgeUnderLLineID(wp.coll_data.floor_line_id)

		else:
			line_id = -1

		if (line_id == -1) or (line_id == -2):
			if wpPikachuThunderJoltGroundGetStatus(weapon_gobj) != nWPPikachuThunderJoltStatusActive:
				Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

				return TRUE

			return FALSE

		coll_type = Mpcollision.mpCollisionGetLineTypeID(line_id)

		if wp.lr == +1:
			if coll_type == nMPLineKindLWall:
				wp.coll_data.lwall_line_id = line_id
				wp.weapon_vars.thunder_jolt.line_type = coll_type
				wp.lr = 2

				DObjGetStruct(weapon_gobj).translate = Mpcollision.mpCollisionGetLWallEdgeD(line_id)

				return wpPikachuThunderJoltGroundCheckDestroy(weapon_gobj)

			if coll_type == nMPLineKindRWall:
				wp.coll_data.rwall_line_id = line_id
				wp.weapon_vars.thunder_jolt.line_type = coll_type
				wp.lr = 3

				DObjGetStruct(weapon_gobj).translate = Mpcollision.mpCollisionGetRWallEdgeU(line_id)

				return wpPikachuThunderJoltGroundCheckDestroy(weapon_gobj)

		elif coll_type == nMPLineKindLWall:
			wp.coll_data.lwall_line_id = line_id
			wp.weapon_vars.thunder_jolt.line_type = coll_type
			wp.lr = 3

			DObjGetStruct(weapon_gobj).translate = Mpcollision.mpCollisionGetLWallEdgeU(line_id)

			return wpPikachuThunderJoltGroundCheckDestroy(weapon_gobj)

		elif coll_type == nMPLineKindRWall:
			wp.coll_data.rwall_line_id = line_id
			wp.weapon_vars.thunder_jolt.line_type = coll_type
			wp.lr = 2

			DObjGetStruct(weapon_gobj).translate = Mpcollision.mpCollisionGetRWallEdgeD(line_id)

			return wpPikachuThunderJoltGroundCheckDestroy(weapon_gobj)

		if wpPikachuThunderJoltGroundGetStatus(weapon_gobj) != nWPPikachuThunderJoltStatusActive:
			Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

			return TRUE

		return FALSE

	elif line_type == nMPLineKindLWall:
		if Mpcollision.mpCollisionCheckExistLineID(wp.coll_data.lwall_line_id) == FALSE:
			Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

			return TRUE

		r = Mpcollision.mpCollisionGetLRCommonLWall(wp.coll_data.lwall_line_id, DObjGetStruct(weapon_gobj).translate)

		if r.ret != FALSE:
			dist = r.dist
			wp.weapon_vars.thunder_jolt.rotate = r.angle

			DObjGetStruct(weapon_gobj).translate.x += dist

			if wpPikachuThunderJoltGroundGetStatus(weapon_gobj) == nWPPikachuThunderJoltStatusDestroy:
				Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

				return TRUE

			return FALSE

		if wp.lr == 2:
			line_id = Mpcollision.mpCollisionGetEdgeRightULineID(wp.coll_data.lwall_line_id)
		else:
			line_id = Mpcollision.mpCollisionGetEdgeRightDLineID(wp.coll_data.lwall_line_id)

		if (line_id == -1) or (line_id == -2):
			if wpPikachuThunderJoltGroundGetStatus(weapon_gobj) != nWPPikachuThunderJoltStatusActive:
				Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

				return TRUE

			return FALSE

		coll_type = Mpcollision.mpCollisionGetLineTypeID(line_id)

		if wp.lr == 2:
			if coll_type == nMPLineKindFloor:
				wp.coll_data.floor_line_id = line_id
				wp.weapon_vars.thunder_jolt.line_type = coll_type
				wp.lr = +1

				DObjGetStruct(weapon_gobj).translate = Mpcollision.mpCollisionGetFloorEdgeL(line_id)

				return wpPikachuThunderJoltGroundCheckDestroy(weapon_gobj)

		elif coll_type == nMPLineKindFloor:
			wp.coll_data.floor_line_id = line_id
			wp.weapon_vars.thunder_jolt.line_type = coll_type
			wp.lr = -1

			DObjGetStruct(weapon_gobj).translate = Mpcollision.mpCollisionGetFloorEdgeR(line_id)

			return wpPikachuThunderJoltGroundCheckDestroy(weapon_gobj)

		if wpPikachuThunderJoltGroundGetStatus(weapon_gobj) != nWPPikachuThunderJoltStatusActive:
			Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

			return TRUE

		return FALSE

	elif line_type == nMPLineKindRWall:
		if Mpcollision.mpCollisionCheckExistLineID(wp.coll_data.rwall_line_id) == FALSE:
			Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

			return TRUE

		r = Mpcollision.mpCollisionGetLRCommonRWall(wp.coll_data.rwall_line_id, DObjGetStruct(weapon_gobj).translate)

		if r.ret != FALSE:
			dist = r.dist
			wp.weapon_vars.thunder_jolt.rotate = r.angle

			DObjGetStruct(weapon_gobj).translate.x += dist

			if wpPikachuThunderJoltGroundGetStatus(weapon_gobj) == nWPPikachuThunderJoltStatusDestroy:
				Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

				return TRUE

			return FALSE

		if wp.lr == 2:
			line_id = Mpcollision.mpCollisionGetEdgeLeftULineID(wp.coll_data.rwall_line_id)
		else:
			line_id = Mpcollision.mpCollisionGetEdgeLeftDLineID(wp.coll_data.rwall_line_id)

		if (line_id == -1) or (line_id == -2):
			if wpPikachuThunderJoltGroundGetStatus(weapon_gobj) != nWPPikachuThunderJoltStatusActive:
				Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

				return TRUE

			return FALSE

		coll_type = Mpcollision.mpCollisionGetLineTypeID(line_id)

		if wp.lr == 2:
			if coll_type == nMPLineKindFloor:
				wp.coll_data.floor_line_id = line_id
				wp.weapon_vars.thunder_jolt.line_type = coll_type
				wp.lr = -1

				DObjGetStruct(weapon_gobj).translate = Mpcollision.mpCollisionGetFloorEdgeR(line_id)

				return wpPikachuThunderJoltGroundCheckDestroy(weapon_gobj)

		elif coll_type == nMPLineKindFloor:
			wp.coll_data.floor_line_id = line_id
			wp.weapon_vars.thunder_jolt.line_type = coll_type
			wp.lr = +1

			DObjGetStruct(weapon_gobj).translate = Mpcollision.mpCollisionGetFloorEdgeL(line_id)

			return wpPikachuThunderJoltGroundCheckDestroy(weapon_gobj)

		if wpPikachuThunderJoltGroundGetStatus(weapon_gobj) != nWPPikachuThunderJoltStatusActive:
			Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

			return TRUE

		return FALSE

	# default:
	return FALSE

## 0x8016A374
static func wpPikachuThunderJoltGroundProcHit(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	Efmanager.efManagerImpactShockMakeEffect(DObjGetStruct(weapon_gobj).translate, wp.attack_coll.damage)

	return TRUE

## 0x8016A3A4
static func wpPikachuThunderJoltGroundProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)

	wp.lifetime = WPPIKACHUJOLT_LIFETIME

	Wpmain.wpMainReflectorSetLR(wp, fp)

	DObjGetStruct(weapon_gobj).rotate.y = F_CST_DTOR32(180.0) if (wp.physics.vel_air.x >= 0.0) else F_CST_DTOR32(0.0)

	Wpmain.wpMainVelSetLR(weapon_gobj)

	return FALSE

## 0x8016A42C
static func wpPikachuThunderJoltGroundMakeWeapon(prev_gobj, pos: Vector3, coll_type: int):
	var prev_wp := wpGetStruct(prev_gobj)
	var new_wp: Weapon
	var new_gobj = Wpmanager.wpManagerMakeWeapon(prev_gobj, dWPPikachuThunderJoltGroundWeaponDesc, pos, (WEAPON_FLAG_COLLPROJECT | WEAPON_FLAG_PARENT_WEAPON))
	var line_type: int

	if new_gobj == null:
		return null

	new_wp = wpGetStruct(new_gobj)

	new_wp.weapon_vars.thunder_jolt.line_type = coll_type

	new_wp.lifetime = prev_wp.lifetime

	new_wp.coll_data.floor_line_id = prev_wp.coll_data.floor_line_id
	new_wp.coll_data.lwall_line_id = prev_wp.coll_data.lwall_line_id
	new_wp.coll_data.rwall_line_id = prev_wp.coll_data.rwall_line_id

	ObjAnim.gcSetAllAnimSpeed(new_gobj, 0.5)
	wpPikachuThunderJoltGroundProcMap(new_gobj)

	line_type = new_wp.weapon_vars.thunder_jolt.line_type

	if line_type == nMPLineKindFloor:
		new_wp.lr = +1 if (prev_wp.physics.vel_air.x >= 0.0) else -1

		DObjGetStruct(new_gobj).rotate.y = F_CST_DTOR32(180.0) if (new_wp.lr >= 0.0) else F_CST_DTOR32(0.0)

	elif line_type == nMPLineKindLWall:
		if syUtilsArcTan2(new_wp.weapon_vars.thunder_jolt.rotate.y, new_wp.weapon_vars.thunder_jolt.rotate.x) > F_CST_DTOR32(135.0): # 2.3561945F
			DObjGetStruct(new_gobj).rotate.y = F_CST_DTOR32(0.0)
			new_wp.lr = 3
		else:
			DObjGetStruct(new_gobj).rotate.y = F_CST_DTOR32(180.0)
			new_wp.lr = 2

	elif line_type == nMPLineKindRWall:
		if syUtilsArcTan2(new_wp.weapon_vars.thunder_jolt.rotate.y, new_wp.weapon_vars.thunder_jolt.rotate.x) > F_CST_DTOR32(45.0):
			DObjGetStruct(new_gobj).rotate.y = F_CST_DTOR32(0.0)
			new_wp.lr = 2
		else:
			DObjGetStruct(new_gobj).rotate.y = F_CST_DTOR32(180.0)
			new_wp.lr = 3

	Efmanager.efManagerPikachuThunderJoltMakeEffect(DObjGetStruct(new_gobj).translate, DObjGetStruct(new_gobj).rotate.z)
	Wpmain.wpMainPlayFGM(new_wp, nSYAudioFGMPikachuElectricLoop) # Bruh

	return new_gobj
