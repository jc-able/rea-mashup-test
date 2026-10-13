## Port of src/wp/wpness/wpnesspkthunder.c (Ness PK Thunder head + trails, and their reflected versions).
##
## Notes on the C unions emulated here:
## * wp->weapon_vars.pkthunder / .pkthunder_trail overlap in C. Every object is only ever accessed
##   through one view (heads: pkthunder, trails: pkthunder_trail), so the separate Weapon.weapon_vars
##   Dictionaries keep the C behaviour. pkthunder.trail_gobj[] is GObj*[WPPKTHUNDER_PARTS_COUNT] in C
##   (the generated SSBStructs default has 1 slot), so heads resize it on creation.
## * FTNessPassiveVars.pkthunder_trail_x/y are s16[FTNESS_PKTHUNDER_TRAIL_POS_COUNT] (generated with 1 slot):
##   resized (zero filled) before use.
class_name Wpnesspkthunder
extends Port

# // // // // // // // // // // // //
# //      EXTERNAL VARIABLES       //
# // // // // // // // // // // // //

## WPAttributes at gFTNessFileMain + llNessMainPKThunderWeaponAttributes (0x0C):
## src/relocData/239_NessMain.c dNessMain_PKThunderWeaponAttributes (checked against ROM file 239).
const dNessMain_PKThunderWeaponAttributes := {
	"data": null,                       # &dNessModel_DObjDesc_0x7C98 (model; not exported)
	"p_mobjsubs": null,
	"anim_joints": null,                # visual (not exported)
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, 0, 0), Vector3(0, 0, 0)],
	"map_coll_top": 100,
	"map_coll_center": 0,
	"map_coll_bottom": -100,
	"map_coll_width": 100,
	"size": 150,
	"angle": 100,
	"knockback_scale": 30,
	"damage": 6,
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
	"knockback_base": 50,
}

## WPAttributes at gFTNessFileMain + llNessMainPKThunderTrailWeaponAttributes (0x40):
## src/relocData/239_NessMain.c dNessMain_PKThunderTrailWeaponAttributes (checked against ROM file 239).
const dNessMain_PKThunderTrailWeaponAttributes := {
	"data": null,                       # &dNessModel_DLLink_0x8B40 (display list; not exported)
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"attack_offsets": [Vector3(0, -100, 0), Vector3(0, 0, 0)],
	"map_coll_top": 50,
	"map_coll_center": 0,
	"map_coll_bottom": -50,
	"map_coll_width": 50,
	"size": 100,
	"angle": 100,
	"knockback_scale": 30,
	"damage": 3,
	"element": 2,
	"knockback_weight": 0,
	"shield_damage": 1,
	"attack_count": 1,
	"can_setoff": 0,
	"sfx": 23,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 0,
	"can_hop": 0,
	"can_reflect": 0,
	"can_absorb": 0,
	"can_shield": 1,
	"knockback_base": 50,
}

static var dWPNessPKThunderHeadWeaponDesc := {
	"flags": 0x03,                                              # Render flags?
	"kind": nWPKindPKThunderHead,                               # Weapon Kind
	# p_weapon = &gFTNessFileMain, o_attributes = &llNessMainPKThunderWeaponAttributes
	"attributes": dNessMain_PKThunderWeaponAttributes,
	"transform_types": {"tk1": nGCMatrixKindTra, "tk2": 0x2E, "tk3": 0},
	"proc_update": Callable(Wpnesspkthunder, &"wpNessPKThunderHeadProcUpdate"),
	"proc_map": Callable(Wpnesspkthunder, &"wpNessPKThunderHeadProcMap"),
	"proc_hit": Callable(Wpnesspkthunder, &"wpNessPKThunderHeadProcHit"),
	"proc_shield": Callable(Wpnesspkthunder, &"wpNessPKThunderHeadProcHit"),
	"proc_hop": Callable(),
	"proc_setoff": Callable(Wpnesspkthunder, &"wpNessPKThunderHeadProcHit"),
	"proc_reflector": Callable(Wpnesspkthunder, &"wpNessPKThunderHeadProcReflector"),
	"proc_absorb": Callable(Wpnesspkthunder, &"wpNessPKThunderHeadProcHit"),
	"visual_kind": "ness_pk_thunder_head",
}

static var dWPNessPKThunderTrailWeaponDesc := {
	"flags": 0x02,                                              # Render flags?
	"kind": nWPKindPKThunderTrail,                              # Weapon Kind
	# p_weapon = &gFTNessFileMain, o_attributes = &llNessMainPKThunderTrailWeaponAttributes
	"attributes": dNessMain_PKThunderTrailWeaponAttributes,
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0},
	"proc_update": Callable(Wpnesspkthunder, &"wpNessPKThunderTrailProcUpdate"),
	"proc_map": Callable(),
	"proc_hit": Callable(Wpnesspkthunder, &"wpNessPKThunderTrailProcHit"),
	"proc_shield": Callable(Wpnesspkthunder, &"wpNessPKThunderTrailProcHit"),
	"proc_hop": Callable(),
	"proc_setoff": Callable(Wpnesspkthunder, &"wpNessPKThunderTrailProcHit"),
	"proc_reflector": Callable(),
	"proc_absorb": Callable(Wpnesspkthunder, &"wpNessPKThunderTrailProcHit"),
	"visual_kind": "ness_pk_thunder_trail",
}

static var dWPNessPKReflectHeadWeaponDesc := {
	"flags": 0x03,                                              # Render flags?
	"kind": nWPKindPKThunderHead,                               # Weapon Kind
	# p_weapon = &gFTNessFileMain, o_attributes = &llNessMainPKThunderWeaponAttributes
	"attributes": dNessMain_PKThunderWeaponAttributes,
	"transform_types": {"tk1": nGCMatrixKindTra, "tk2": 0x2E, "tk3": 0},
	"proc_update": Callable(Wpnesspkthunder, &"wpNessPKReflectHeadProcUpdate"),
	"proc_map": Callable(Wpnesspkthunder, &"wpNessPKReflectHeadProcMap"),
	"proc_hit": Callable(Wpnesspkthunder, &"wpNessPKReflectHeadProcHit"),
	"proc_shield": Callable(Wpnesspkthunder, &"wpNessPKReflectHeadProcHit"),
	"proc_hop": Callable(),
	"proc_setoff": Callable(Wpnesspkthunder, &"wpNessPKReflectHeadProcHit"),
	"proc_reflector": Callable(Wpnesspkthunder, &"wpNessPKReflectHeadProcReflector"),
	"proc_absorb": Callable(Wpnesspkthunder, &"wpNessPKReflectHeadProcHit"),
	"visual_kind": "ness_pk_thunder_head",
}

static var dWPNessPKReflectTrailWeaponDesc := {
	"flags": 0x02,                                              # Render flags?
	"kind": nWPKindPKThunderTrail,                              # Weapon Kind
	# p_weapon = &gFTNessFileMain, o_attributes = &llNessMainPKThunderTrailWeaponAttributes
	"attributes": dNessMain_PKThunderTrailWeaponAttributes,
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0},
	"proc_update": Callable(Wpnesspkthunder, &"wpNessPKReflectTrailProcUpdate"),
	"proc_map": Callable(),
	"proc_hit": Callable(Wpnesspkthunder, &"wpNessPKReflectTrailProcHit"),
	"proc_shield": Callable(Wpnesspkthunder, &"wpNessPKReflectTrailProcHit"),
	"proc_hop": Callable(),
	"proc_setoff": Callable(Wpnesspkthunder, &"wpNessPKReflectTrailProcHit"),
	"proc_reflector": Callable(),
	"proc_absorb": Callable(Wpnesspkthunder, &"wpNessPKReflectTrailProcHit"),
	"visual_kind": "ness_pk_thunder_trail",
}

# // // // // // // // // // // // //
# //       PORT-ONLY HELPERS       //
# // // // // // // // // // // // //

## Size wp->weapon_vars.pkthunder.trail_gobj like the C array (GObj*[WPPKTHUNDER_PARTS_COUNT]).
static func _wpNessPKThunderSizeTrailArray(wp) -> void:
	var trail_gobj: Array = wp.weapon_vars.pkthunder.trail_gobj

	if trail_gobj.size() < WPPKTHUNDER_PARTS_COUNT:
		trail_gobj.resize(WPPKTHUNDER_PARTS_COUNT)

## Size fp->passive_vars.ness.pkthunder_trail_x/y like the C arrays (s16[FTNESS_PKTHUNDER_TRAIL_POS_COUNT]).
static func _ftNessSizeTrailPosArrays(fp) -> void:
	for key in [&"pkthunder_trail_x", &"pkthunder_trail_y"]:
		var arr: Array = fp.passive_vars.ness[key]

		if arr.size() < FTNESS_PKTHUNDER_TRAIL_POS_COUNT:
			var old_size := arr.size()

			arr.resize(FTNESS_PKTHUNDER_TRAIL_POS_COUNT)

			for i in range(old_size, FTNESS_PKTHUNDER_TRAIL_POS_COUNT):
				arr[i] = 0

## C (s16) store of a float: truncate toward zero, keep the low 16 bits.
static func _s16(value: float) -> int:
	var v: int = int(value) & 0xFFFF

	return (v - 0x10000) if (v >= 0x8000) else v

## DObjGetStruct(weapon_gobj)->mobj->texture_id_curr = texture_id (render-only). DObj has no MObj in this
## port yet, so the value is kept as DObj metadata for the render layer when there is no `mobj`.
static func _dobjSetMObjTextureIDCurr(weapon_gobj, texture_id: int) -> void:
	var dobj: Object = DObjGetStruct(weapon_gobj)
	var mobj = dobj.get("mobj")

	if mobj != null:
		mobj.texture_id_curr = texture_id
	else:
		dobj.set_meta(&"texture_id_curr", texture_id)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8016AD30
static func wpNessPKThunderHeadSetDestroyTrails(weapon_gobj, is_destroy: int) -> void:
	var fp: Fighter
	var head_wp: Weapon
	var trail_wp: Weapon
	var ep

	head_wp = wpGetStruct(weapon_gobj)

	if not (head_wp.weapon_vars.pkthunder.status & nWPNessPKThunderStatusDestroy):
		fp = ftGetStruct(head_wp.owner_gobj)

		if fp.player_num == head_wp.player_num:
			fp.passive_vars.ness.is_thunder_destroy |= is_destroy

	fp = ftGetStruct(head_wp.owner_gobj)

	for i in range(WPPKTHUNDER_PARTS_COUNT - 1): # ARRAY_COUNT(trail_gobj) - 1
		if head_wp.weapon_vars.pkthunder.trail_gobj[i] != null:
			trail_wp = wpGetStruct(head_wp.weapon_vars.pkthunder.trail_gobj[i])
			trail_wp.weapon_vars.pkthunder_trail.status = nWPNessPKThunderStatusDestroy

			head_wp.weapon_vars.pkthunder.trail_gobj[i] = null

	if head_wp.weapon_vars.pkthunder.trail_gobj[WPPKTHUNDER_PARTS_COUNT - 1] != null:
		ep = head_wp.weapon_vars.pkthunder.trail_gobj[WPPKTHUNDER_PARTS_COUNT - 1].user_data # efGetStruct()
		ep.effect_vars.pkthunder.status = nWPNessPKThunderStatusDestroy

		head_wp.weapon_vars.pkthunder.trail_gobj[WPPKTHUNDER_PARTS_COUNT - 1] = null

## 0x8016ADF4
static func wpNessPKThunderTrailUpdatePositions(weapon_gobj) -> void:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)

	if fp.player_num == wp.player_num:
		var trail_id: int = fp.passive_vars.ness.pkthunder_trail_id - 1

		if trail_id < 0:
			trail_id += FTNESS_PKTHUNDER_TRAIL_POS_COUNT

		_ftNessSizeTrailPosArrays(fp)

		fp.passive_vars.ness.pkthunder_trail_x[trail_id] = _s16(DObjGetStruct(weapon_gobj).translate.x)
		fp.passive_vars.ness.pkthunder_trail_y[trail_id] = _s16(DObjGetStruct(weapon_gobj).translate.y)

## 0x8016AE64
static func wpNessPKThunderHeadMakeTrail(weapon_gobj, trail_id: int) -> void:
	var pos: Vector3

	pos.x = DObjGetStruct(weapon_gobj).translate.x
	pos.y = DObjGetStruct(weapon_gobj).translate.y
	pos.z = 0.0

	wpNessPKThunderTrailMakeWeapon(weapon_gobj, pos, trail_id)

## 0x8016AEA68
static func wpNessPKThunderHeadProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp: Fighter
	var angle_diff: float
	var stick_angle: Vector3
	var thunder_angle: Vector3

	if wp.weapon_vars.pkthunder.status & nWPNessPKThunderStatusDestroy:
		Efmanager.efManagerImpactShockMakeEffect(DObjGetStruct(weapon_gobj).translate, wp.attack_coll.damage)
		wpNessPKThunderHeadSetDestroyTrails(weapon_gobj, TRUE)

		return TRUE

	fp = ftGetStruct(wp.owner_gobj)

	if wp.weapon_vars.pkthunder.status & nWPNessPKThunderStatusCollide:
		Efmanager.efManagerImpactShockMakeEffect(DObjGetStruct(weapon_gobj).translate, wp.attack_coll.damage)
		wpNessPKThunderHeadSetDestroyTrails(weapon_gobj, TRUE)

		return TRUE

	if wp.lifetime == WPPKTHUNDER_SPAWN_TRAIL_FRAME:
		wpNessPKThunderHeadMakeTrail(weapon_gobj, 0)

	if Wpmain.wpMainDecLifeCheckExpire(wp) != FALSE:
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)
		wpNessPKThunderHeadSetDestroyTrails(weapon_gobj, TRUE)

		return TRUE

	wpNessPKThunderTrailUpdatePositions(weapon_gobj)

	if (fp.status_id == nFTNessStatusSpecialHiHold) or (fp.status_id == nFTNessStatusSpecialAirHiHold):
		if (ABS(fp.input.pl.stick_range.x) + ABS(fp.input.pl.stick_range.y)) > WPPKTHUNDER_TURN_STICK_THRESHOLD:
			stick_angle.x = fp.input.pl.stick_range.x
			stick_angle.y = fp.input.pl.stick_range.y
			stick_angle.z = 0.0

			angle_diff = syVectorAngleDiff3D(wp.physics.vel_air, stick_angle)

			# syVectorNormCross3D(&vel_air, &stick_angle, &thunder_angle) always writes the cross product into
			# thunder_angle (normalized unless it is the zero vector); Port's version returns null for zero.
			var cross = syVectorNormCross3D(wp.physics.vel_air, stick_angle)
			thunder_angle = cross if (cross != null) else Vector3.ZERO

			if angle_diff >= F_CST_DTOR32(45.0):
				wp.weapon_vars.pkthunder.angle = (wp.weapon_vars.pkthunder.angle + WPPKTHUNDER_ANGLE_STEP) if (thunder_angle.z > 0.0) else (wp.weapon_vars.pkthunder.angle - WPPKTHUNDER_ANGLE_STEP)

			if angle_diff < F_CST_DTOR32(45.0):
				wp.weapon_vars.pkthunder.angle = (wp.weapon_vars.pkthunder.angle + (angle_diff / WPPKTHUNDER_ANGLE_DIV)) if (thunder_angle.z > 0.0) else (wp.weapon_vars.pkthunder.angle - (angle_diff / WPPKTHUNDER_ANGLE_DIV))

			wp.physics.vel_air.x = __cosf(wp.weapon_vars.pkthunder.angle) * WPPKTHUNDER_VEL
			wp.physics.vel_air.y = __sinf(wp.weapon_vars.pkthunder.angle) * WPPKTHUNDER_VEL
			wp.physics.vel_air.z = 0.0

			DObjGetStruct(weapon_gobj).rotate.z = wp.weapon_vars.pkthunder.angle - F_CST_DTOR32(90.0)
	else:
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)
		wpNessPKThunderHeadSetDestroyTrails(weapon_gobj, TRUE)

		return TRUE

	return FALSE

## 0x8016B198
static func wpNessPKThunderHeadProcMap(weapon_gobj) -> int:
	if Wpmap.wpMapTestAllCheckCollEnd(weapon_gobj) != FALSE:
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)
		wpNessPKThunderHeadSetDestroyTrails(weapon_gobj, TRUE)

		return TRUE
	else:
		return FALSE

## 0x8016B1E8
static func wpNessPKThunderHeadProcHit(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	Efmanager.efManagerImpactShockMakeEffect(DObjGetStruct(weapon_gobj).translate, wp.attack_coll.damage)
	wpNessPKThunderHeadSetDestroyTrails(weapon_gobj, TRUE)

	return TRUE

## 0x8016B22C
static func wpNessPKThunderHeadProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp: Fighter
	var pos: Vector3 = DObjGetStruct(weapon_gobj).translate

	wpNessPKReflectHeadMakeWeapon(weapon_gobj, pos, wp.weapon_vars.pkthunder.angle)

	wp.owner_gobj = wp.weapon_vars.pkthunder.parent_gobj

	fp = ftGetStruct(wp.weapon_vars.pkthunder.parent_gobj)

	wp.player_num = fp.player_num

	wpNessPKThunderHeadSetDestroyTrails(weapon_gobj, TRUE)

	return TRUE

## 0x8016B2A0
static func wpNessPKThunderHeadProcDead(weapon_gobj) -> int:
	wpNessPKThunderHeadSetDestroyTrails(weapon_gobj, TRUE)

	return TRUE

## 0x8016B2C4
static func wpNessPKThunderHeadMakeWeapon(fighter_gobj, pos: Vector3, vel: Vector3):
	var weapon_gobj = Wpmanager.wpManagerMakeWeapon(fighter_gobj, dWPNessPKThunderHeadWeaponDesc, pos, (WEAPON_FLAG_COLLPROJECT | WEAPON_FLAG_PARENT_FIGHTER))
	var wp: Weapon

	if weapon_gobj == null:
		return null

	wp = wpGetStruct(weapon_gobj)

	wp.proc_dead = Callable(Wpnesspkthunder, &"wpNessPKThunderHeadProcDead")

	wp.lifetime = WPPKTHUNDER_LIFETIME

	wp.physics.vel_air = vel

	wp.weapon_vars.pkthunder.status = nWPNessPKThunderStatusActive
	wp.weapon_vars.pkthunder.angle = F_CST_DTOR32(90.0)
	wp.weapon_vars.pkthunder.parent_gobj = fighter_gobj

	wp.is_camera_follow = TRUE

	_wpNessPKThunderSizeTrailArray(wp)

	for i in range(WPPKTHUNDER_PARTS_COUNT):
		wp.weapon_vars.pkthunder.trail_gobj[i] = null

	DObjGetStruct(weapon_gobj).rotate.z = wp.weapon_vars.pkthunder.angle - F_CST_DTOR32(90.0) # Bruh this effectively makes it 0.0F due to its init a few lines above (HALF_PI32)

	return weapon_gobj

## 0x8016B398
static func wpNessPKThunderTrailProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var trail_id: int
	var fp: Fighter

	if wp.weapon_vars.pkthunder_trail.status & nWPNessPKThunderStatusDestroy:
		return TRUE

	fp = ftGetStruct(wp.owner_gobj)

	trail_id = (fp.passive_vars.ness.pkthunder_trail_id - (wp.weapon_vars.pkthunder_trail.trail_id * 2)) - 2

	if trail_id < 0:
		trail_id += FTNESS_PKTHUNDER_TRAIL_POS_COUNT

	_ftNessSizeTrailPosArrays(fp)

	DObjGetStruct(weapon_gobj).translate.x = fp.passive_vars.ness.pkthunder_trail_x[trail_id]
	DObjGetStruct(weapon_gobj).translate.y = fp.passive_vars.ness.pkthunder_trail_y[trail_id]

	if trail_id > 0:
		DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(
			(fp.passive_vars.ness.pkthunder_trail_y[trail_id] - fp.passive_vars.ness.pkthunder_trail_y[trail_id - 1]),
			(fp.passive_vars.ness.pkthunder_trail_x[trail_id] - fp.passive_vars.ness.pkthunder_trail_x[trail_id - 1])
		)
	else:
		DObjGetStruct(weapon_gobj).rotate.z = syUtilsArcTan2(
			(fp.passive_vars.ness.pkthunder_trail_y[trail_id] - fp.passive_vars.ness.pkthunder_trail_y[FTNESS_PKTHUNDER_TRAIL_POS_COUNT - 1]),
			(fp.passive_vars.ness.pkthunder_trail_x[trail_id] - fp.passive_vars.ness.pkthunder_trail_x[FTNESS_PKTHUNDER_TRAIL_POS_COUNT - 1])
		)

	DObjGetStruct(weapon_gobj).rotate.z -= F_CST_DTOR32(90.0)

	if (wp.weapon_vars.pkthunder_trail.trail_id < (WPPKTHUNDER_PARTS_COUNT - 2)) and (wp.lifetime == WPPKTHUNDER_SPAWN_TRAIL_FRAME):
		wpNessPKThunderHeadMakeTrail(weapon_gobj, wp.weapon_vars.pkthunder_trail.trail_id + 1)

	if (wp.weapon_vars.pkthunder_trail.trail_id == (WPPKTHUNDER_PARTS_COUNT - 2)) and (wp.lifetime == WPPKTHUNDER_SPAWN_TRAIL_FRAME):
		Efmanager.efManagerNessPKThunderTrailMakeEffect(wp.owner_gobj)

	Wpmain.wpMainDecLifeCheckExpire(wp) # return value ignored: trails only die through their status

	# DObjGetStruct(weapon_gobj)->mobj->texture_id_curr = syUtilsRandIntRange(...); the RNG call is game state.
	_dobjSetMObjTextureIDCurr(weapon_gobj, syUtilsRandIntRange(WPPKTHUNDER_TEXTURES_NUM - 1))

	return FALSE

## 0x8016B550
static func wpNessPKThunderTrailProcHit(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	Efmanager.efManagerImpactShockMakeEffect(DObjGetStruct(weapon_gobj).translate, wp.attack_coll.damage)

	return FALSE

## 0x8016B580
static func wpNessPKThunderTrailMakeWeapon(head_gobj, pos: Vector3, trail_id: int):
	var trail_gobj
	var trail_wp: Weapon
	var head_wp := wpGetStruct(head_gobj)

	trail_gobj = Wpmanager.wpManagerMakeWeapon(head_gobj, dWPNessPKThunderTrailWeaponDesc, pos, WEAPON_FLAG_PARENT_WEAPON)

	if trail_gobj == null:
		return null

	trail_wp = wpGetStruct(trail_gobj)

	trail_gobj.display_proc = Callable(Wpdisplay, &"wpDisplayPKThunderProcDisplay") # trail_gobj->proc_display

	trail_wp.lifetime = WPPKTHUNDER_LIFETIME

	if trail_id == 0:
		trail_wp.group_id = Wpmanager.wpManagerGetGroupID(head_gobj, trail_gobj) # Bruh this doesn't any take arguments but it doesn't match otherwise
	else:
		trail_wp.group_id = head_wp.group_id

	trail_wp.weapon_vars.pkthunder_trail.status = nWPNessPKThunderStatusActive
	trail_wp.weapon_vars.pkthunder_trail.trail_id = trail_id
	trail_wp.weapon_vars.pkthunder_trail.parent_gobj = head_gobj

	if trail_id != 0:
		head_gobj = head_wp.weapon_vars.pkthunder_trail.head_gobj
		head_wp = wpGetStruct(head_gobj)

	trail_wp.weapon_vars.pkthunder_trail.head_gobj = head_gobj

	for i in range(WPPKTHUNDER_PARTS_COUNT):
		head_wp.weapon_vars.pkthunder.trail_gobj[trail_id] = trail_gobj

	return trail_gobj

## 0x8016B65C
static func wpNessPKReflectHeadMakeTrail(weapon_gobj, trail_id: int) -> void:
	var pos: Vector3

	pos.x = DObjGetStruct(weapon_gobj).translate.x
	pos.y = DObjGetStruct(weapon_gobj).translate.y
	pos.z = 0.0

	wpNessPKReflectTrailMakeWeapon(weapon_gobj, pos, trail_id)

## 0x8016B6A0
static func wpNessPKReflectHeadSetDestroyTrails(weapon_gobj, unused: int) -> void:
	var head_wp: Weapon
	var trail_wp: Weapon
	var ep

	head_wp = wpGetStruct(weapon_gobj)

	for i in range(WPPKTHUNDER_PARTS_COUNT - 1): # ARRAY_COUNT(trail_gobj) - 1
		if head_wp.weapon_vars.pkthunder.trail_gobj[i] != null:
			trail_wp = wpGetStruct(head_wp.weapon_vars.pkthunder.trail_gobj[i])
			trail_wp.weapon_vars.pkthunder_trail.status = nWPNessPKThunderStatusDestroy
			head_wp.weapon_vars.pkthunder.trail_gobj[i] = null

	if head_wp.weapon_vars.pkthunder.trail_gobj[WPPKTHUNDER_PARTS_COUNT - 1] != null:
		ep = head_wp.weapon_vars.pkthunder.trail_gobj[WPPKTHUNDER_PARTS_COUNT - 1].user_data # efGetStruct()
		ep.effect_vars.pkthunder.status = nWPNessPKThunderStatusDestroy
		head_wp.weapon_vars.pkthunder.trail_gobj[WPPKTHUNDER_PARTS_COUNT - 1] = null

## 0x8016B734
static func wpNessPKReflectHeadProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if wp.lifetime == WPPKTHUNDER_SPAWN_TRAIL_FRAME: # This will spawn new PK Thunder trails every time it is reflected, since lifetime is reset to 160 on each occasion
		wpNessPKReflectHeadMakeTrail(weapon_gobj, 0)

	if Wpmain.wpMainDecLifeCheckExpire(wp) != FALSE:
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)
		wpNessPKReflectHeadSetDestroyTrails(weapon_gobj, nWPNessPKThunderStatusDestroy)

		return TRUE
	else:
		return FALSE

## 0x8016B7AC
static func wpNessPKReflectHeadProcMap(weapon_gobj) -> int:
	if Wpmap.wpMapTestAllCheckCollEnd(weapon_gobj) != FALSE:
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)
		wpNessPKReflectHeadSetDestroyTrails(weapon_gobj, nWPNessPKThunderStatusDestroy)

		return TRUE
	else:
		return FALSE

## 0x8016B7FC
static func wpNessPKReflectHeadProcHit(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	Efmanager.efManagerImpactShockMakeEffect(DObjGetStruct(weapon_gobj).translate, wp.attack_coll.damage)
	wpNessPKReflectHeadSetDestroyTrails(weapon_gobj, nWPNessPKThunderStatusDestroy)

	return TRUE

## 0x8016B840
static func wpNessPKReflectHeadProcReflector(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)

	wp.lifetime = WPPKTHUNDER_LIFETIME # This line is indirectly responsible for the PK Thunder double reflect crash; omitting it fixes the oversight
										# Solution: wpNessPKReflectHeadSetDestroyTrails(weapon_gobj, nWPNessPKThunderStatusDestroy);

	Wpmain.wpMainReflectorSetLR(wp, fp)

	return FALSE

## 0x8016B874
static func wpNessPKReflectHeadProcDead(weapon_gobj) -> int:
	wpNessPKReflectHeadSetDestroyTrails(weapon_gobj, nWPNessPKThunderStatusDestroy)

	return TRUE

## 0x8016B898
static func wpNessPKReflectHeadMakeWeapon(old_gobj, pos: Vector3, angle: float):
	var new_gobj
	var wp: Weapon
	var dist: Vector3

	new_gobj = Wpmanager.wpManagerMakeWeapon(old_gobj, dWPNessPKReflectHeadWeaponDesc, pos, (WEAPON_FLAG_COLLPROJECT | WEAPON_FLAG_PARENT_WEAPON))

	if new_gobj == null:
		return null

	wp = wpGetStruct(new_gobj)

	wp.proc_dead = Callable(Wpnesspkthunder, &"wpNessPKReflectHeadProcDead")

	wp.lifetime = WPPKTHUNDER_LIFETIME

	wp.group_id = Wpmanager.wpManagerGetGroupID()

	_wpNessPKThunderSizeTrailArray(wp)

	for i in range(WPPKTHUNDER_PARTS_COUNT):
		wp.weapon_vars.pkthunder.trail_gobj[i] = null

	dist.x = DObjGetStruct(new_gobj).translate.x - DObjGetStruct(wp.owner_gobj).translate.x
	dist.y = DObjGetStruct(new_gobj).translate.y - (DObjGetStruct(wp.owner_gobj).translate.y + WPPKTHUNDER_REFLECT_POS_Y_ADD)
	dist.z = DObjGetStruct(new_gobj).translate.z - DObjGetStruct(wp.owner_gobj).translate.z

	dist = syVectorNorm3D(dist)

	wp.physics.vel_air.x = (WPPKTHUNDER_VEL * dist.x)
	wp.physics.vel_air.y = (WPPKTHUNDER_VEL * dist.y)
	wp.physics.vel_air.z = 0.0

	DObjGetStruct(new_gobj).rotate.z = syUtilsArcTan2(wp.physics.vel_air.y, wp.physics.vel_air.x)

	return new_gobj

## 0x8016B9E0
static func wpNessPKReflectTrailProcUpdate(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	if wp.weapon_vars.pkthunder_trail.status & nWPNessPKThunderStatusDestroy:
		return TRUE

	# Game hangs on the following line when PK Thunder crash occurs (DObjGetStruct returns NULL)
	# This happens because the program loses the reference to the old PK Thunder trail objects which are still accessing the head's DObj even after it's ejected

	DObjGetStruct(weapon_gobj).translate.x = (DObjGetStruct(wp.weapon_vars.pkthunder_trail.head_gobj).translate.x - (wp.physics.vel_air.x * (wp.weapon_vars.pkthunder_trail.trail_id + 1.5) * 2.0))

	DObjGetStruct(weapon_gobj).translate.y = (DObjGetStruct(wp.weapon_vars.pkthunder_trail.head_gobj).translate.y - (wp.physics.vel_air.y * (wp.weapon_vars.pkthunder_trail.trail_id + 1.5) * 2.0))

	if (wp.weapon_vars.pkthunder_trail.trail_id < (WPPKTHUNDER_PARTS_COUNT - 2)) and (wp.lifetime == WPPKTHUNDER_SPAWN_TRAIL_FRAME):
		wpNessPKReflectHeadMakeTrail(weapon_gobj, wp.weapon_vars.pkthunder_trail.trail_id + 1)

	if (wp.weapon_vars.pkthunder_trail.trail_id == (WPPKTHUNDER_PARTS_COUNT - 2)) and (wp.lifetime == WPPKTHUNDER_SPAWN_TRAIL_FRAME):
		Efmanager.efManagerNessPKReflectTrailMakeEffect(wp.weapon_vars.pkthunder_trail.head_gobj)

	Wpmain.wpMainDecLifeCheckExpire(wp) # return value ignored

	# DObjGetStruct(weapon_gobj)->mobj->texture_id_curr = syUtilsRandIntRange(...); the RNG call is game state.
	_dobjSetMObjTextureIDCurr(weapon_gobj, syUtilsRandIntRange(WPPKTHUNDER_TEXTURES_NUM - 1))

	return FALSE

## 0x8016BB3C
static func wpNessPKReflectTrailProcHit(weapon_gobj) -> int:
	var wp := wpGetStruct(weapon_gobj)

	Efmanager.efManagerImpactShockMakeEffect(DObjGetStruct(weapon_gobj).translate, wp.attack_coll.damage)

	return FALSE

## 0x8016BB6C
static func wpNessPKReflectTrailMakeWeapon(old_gobj, pos: Vector3, trail_id: int):
	var new_gobj
	var old_wp: Weapon
	var new_wp: Weapon

	old_wp = wpGetStruct(old_gobj)

	new_gobj = Wpmanager.wpManagerMakeWeapon(old_gobj, dWPNessPKReflectTrailWeaponDesc, pos, WEAPON_FLAG_PARENT_WEAPON)

	if new_gobj == null:
		return null

	new_wp = wpGetStruct(new_gobj)

	new_gobj.display_proc = Callable(Wpdisplay, &"wpDisplayPKThunderProcDisplay") # new_gobj->proc_display

	new_wp.lifetime = WPPKTHUNDER_LIFETIME

	new_wp.group_id = old_wp.group_id

	new_wp.weapon_vars.pkthunder_trail.status = nWPNessPKThunderStatusActive
	new_wp.weapon_vars.pkthunder_trail.trail_id = trail_id
	new_wp.weapon_vars.pkthunder_trail.parent_gobj = old_gobj

	if trail_id != 0:
		# WARNING: old_gobj belongs to trails on non-zero trail_ides, but the code below treats it as a head object and accesses the head's weapon vars

		old_gobj = old_wp.weapon_vars.pkthunder_trail.head_gobj
		old_wp = wpGetStruct(old_gobj)

	new_wp.weapon_vars.pkthunder_trail.head_gobj = old_gobj

	old_wp.weapon_vars.pkthunder.trail_gobj[trail_id] = new_gobj

	new_wp.physics.vel_air.x = old_wp.physics.vel_air.x
	new_wp.physics.vel_air.y = old_wp.physics.vel_air.y

	# With the crash fix, this makes the trail look janky when reflected more than twice.
	# Solution: DObjGetStruct(new_gobj)->rotate.vec.f.z = syUtilsArcTan2(new_wp->physics.vel_air.y, new_wp->physics.vel_air.x) - F_CST_DTOR32(90.0F);

	DObjGetStruct(new_gobj).rotate.z = DObjGetStruct(old_gobj).rotate.z - F_CST_DTOR32(90.0)

	Wpprocess.wpProcessUpdateHitPositions(new_gobj)

	return new_gobj
