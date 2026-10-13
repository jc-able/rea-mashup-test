## 1:1 port of src/ft/ftchar/ftkirby/ftkirbycopysamusspecialn.c (ssb-decomp-re): Kirby's copied
## Samus Charge Shot.
##
## Pointer conventions:
##   ftKirbyCopySamusSpecialNGetChargeShotPosition(fp, pos = ignored) -> Vector3   (C: void, writes *pos)
class_name Ftkirbycopysamusspecialn
extends Port

## ftKirbyCopySamusSpecialNLoopProcInterrupt calls ftCommonEscapeSetStatus(fighter_gobj, status_id)
## without its third argument (s32 itemthrow_buffer_tics). The ROM (US, 0x80157220) leaves register a2
## holding the FTStruct* that ftKirbyCopySamusSpecialNDestroyChargeShot(fp) restores before returning,
## so the roll's item-throw buffer is a (non-zero) pointer value. Any non-zero value that cannot reach
## zero by per-frame decrements reproduces it; this is a typical KSEG0 heap address read as s32.
const FTKIRBY_COPYSAMUS_ESCAPE_ITEMTHROW_BUFFER_UB := -2146238464 # (s32)0x80130000

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80156E60
static func ftKirbyCopySamusSpecialNDestroyChargeShot(fp = null) -> void:
	if fp.status_vars.kirby.copysamus_specialn.charge_gobj != null:
		Wpmain.wpMainDestroyWeapon(fp.status_vars.kirby.copysamus_specialn.charge_gobj)

		fp.status_vars.kirby.copysamus_specialn.charge_gobj = null

## 0x80156E98
static func ftKirbyCopySamusSpecialNProcDamage(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.passive_vars.kirby.copysamus_charge_level = 0

	ftKirbyCopySamusSpecialNDestroyChargeShot(fp)

## 0x80156EBC
## C writes *pos; the new value is returned (the pos argument is ignored).
static func ftKirbyCopySamusSpecialNGetChargeShotPosition(fp = null, pos = null):
	var out_pos = Vector3(0.0, FTKIRBY_COPYSAMUS_CHARGE_OFF_Y, FTKIRBY_COPYSAMUS_CHARGE_OFF_Z)

	out_pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[FTKIRBY_COPYSAMUS_CHARGE_JOINT], out_pos)

	return out_pos

## 0x80156EFC
static func ftKirbyCopySamusSpecialNSetChargeShotPosition(fp = null) -> void:
	var pos

	if fp.status_vars.kirby.copysamus_specialn.charge_gobj != null:
		pos = ftKirbyCopySamusSpecialNGetChargeShotPosition(fp)

		DObjGetStruct(fp.status_vars.kirby.copysamus_specialn.charge_gobj).translate = pos

## 0x80156F54
static func ftKirbyCopySamusSpecialNStartProcUpdate(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fighter_gobj.anim_frame <= 0.0:
		if fp.ga == nMPKineticsAir:
			ftKirbyCopySamusSpecialAirNEndSetStatus(fighter_gobj)

		elif fp.status_vars.kirby.copysamus_specialn.is_release != FALSE:
			ftKirbyCopySamusSpecialNEndSetStatus(fighter_gobj)

		else:
			ftKirbyCopySamusSpecialNLoopSetStatus(fighter_gobj)

## 0x80156FCC
static func ftKirbyCopySamusSpecialNStartProcInterrupt(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.input.pl.button_tap & fp.input.button_mask_b) or (fp.input.pl.button_tap & fp.input.button_mask_a):
		fp.status_vars.kirby.copysamus_specialn.is_release = TRUE

## 0x80157004
static func ftKirbyCopySamusSpecialNStartProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftkirbycopysamusspecialn, &"ftKirbyCopySamusSpecialNStartSwitchStatusAir"))

## 0x80157028
static func ftKirbyCopySamusSpecialAirNStartProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbycopysamusspecialn, &"ftKirbyCopySamusSpecialAirNStartSwitchStatusGround"))

## 0x8015704C
static func ftKirbyCopySamusSpecialAirNStartSwitchStatusGround(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopySamusSpecialNStart, fighter_gobj.anim_frame, fp.joints[nFTPartsJointTopN].anim_speed, FTSTATUS_PRESERVE_COLANIM)

	fp.proc_damage = Callable(Ftkirbycopysamusspecialn, &"ftKirbyCopySamusSpecialNProcDamage")

## 0x801570A8
static func ftKirbyCopySamusSpecialNStartSwitchStatusAir(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopySamusSpecialAirNStart, fighter_gobj.anim_frame, fp.joints[nFTPartsJointTopN].anim_speed, FTSTATUS_PRESERVE_COLANIM)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

	fp.proc_damage = Callable(Ftkirbycopysamusspecialn, &"ftKirbyCopySamusSpecialNProcDamage")

	fp.status_vars.kirby.copysamus_specialn.is_release = TRUE

## 0x80157114
static func ftKirbyCopySamusSpecialNLoopProcUpdate(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.kirby.copysamus_specialn.charge_int -= 1

	if fp.status_vars.kirby.copysamus_specialn.charge_int == 0:
		fp.status_vars.kirby.copysamus_specialn.charge_int = FTKIRBY_COPYSAMUS_CHARGE_INT

		if fp.passive_vars.kirby.copysamus_charge_level <= (FTKIRBY_COPYSAMUS_CHARGE_MAX - 1):
			fp.passive_vars.kirby.copysamus_charge_level += 1

			if fp.passive_vars.kirby.copysamus_charge_level == FTKIRBY_COPYSAMUS_CHARGE_MAX:
				Ftparam.ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterCommonSpecialNCharge, 0)
				ftKirbyCopySamusSpecialNDestroyChargeShot(fp)
				Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)

			elif fp.status_vars.kirby.copysamus_specialn.charge_gobj != null:
				var wp := wpGetStruct(fp.status_vars.kirby.copysamus_specialn.charge_gobj)

				wp.weapon_vars.charge_shot.charge_size = fp.passive_vars.kirby.copysamus_charge_level

## 0x801571A8
static func ftKirbyCopySamusSpecialNLoopProcInterrupt(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int

	if (fp.input.pl.button_tap & fp.input.button_mask_b) or (fp.input.pl.button_tap & fp.input.button_mask_a):
		ftKirbyCopySamusSpecialNEndSetStatus(fighter_gobj)

		return

	status_id = Ftcommonescape.ftCommonEscapeGetStatus(fp)

	if status_id != -1:
		ftKirbyCopySamusSpecialNDestroyChargeShot(fp)

		# WARNING: Undefined behavior. This function expects a third argument
		# for item throw buffer frames, but never receives it (see
		# FTKIRBY_COPYSAMUS_ESCAPE_ITEMTHROW_BUFFER_UB).
		Ftcommonescape.ftCommonEscapeSetStatus(fighter_gobj, status_id, FTKIRBY_COPYSAMUS_ESCAPE_ITEMTHROW_BUFFER_UB)

	elif fp.input.pl.button_tap & fp.input.button_mask_z:
		ftKirbyCopySamusSpecialNDestroyChargeShot(fp)
		Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)

## 0x80157268
static func ftKirbyCopySamusSpecialNLoopProcMap(fighter_gobj = null) -> void:
	ftKirbyCopySamusSpecialNSetChargeShotPosition(ftGetStruct(fighter_gobj))
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftkirbycopysamusspecialn, &"ftKirbyCopySamusSpecialAirNEndSetStatus"))

## 0x8015729C
static func ftKirbyCopySamusSpecialNLoopSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopySamusSpecialNLoop, 0.0, 1.0, FTSTATUS_PRESERVE_COLANIM)

	fp.proc_damage = Callable(Ftkirbycopysamusspecialn, &"ftKirbyCopySamusSpecialNProcDamage")

	# C writes fp->status_vars.samus.specialn.charge_int: same union offset as
	# status_vars.kirby.copysamus_specialn.charge_int (the field the loop reads back).
	fp.status_vars.kirby.copysamus_specialn.charge_int = FTKIRBY_COPYSAMUS_CHARGE_INT

	pos = ftKirbyCopySamusSpecialNGetChargeShotPosition(fp)
	fp.status_vars.kirby.copysamus_specialn.charge_gobj = Wpsamuschargeshot.wpSamusChargeShotMakeWeapon(fighter_gobj, pos, fp.passive_vars.kirby.copysamus_charge_level, 0)

## 0x80157314
static func ftKirbyCopySamusSpecialNEndProcUpdate(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos
	var wp
	var charge_recoil_x: float
	var charge_recoil_y: float

	if fp.motion_vars.flags.flag0 != FALSE:
		fp.motion_vars.flags.flag0 = FALSE

		pos = ftKirbyCopySamusSpecialNGetChargeShotPosition(fp)

		if fp.status_vars.kirby.copysamus_specialn.charge_gobj != null:
			wp = wpGetStruct(fp.status_vars.kirby.copysamus_specialn.charge_gobj)
			Ftparam.ftParamStopLoopSFX(fp)

			DObjGetStruct(fp.status_vars.kirby.copysamus_specialn.charge_gobj).translate = pos

			wp.weapon_vars.charge_shot.is_full_charge = TRUE
			wp.weapon_vars.charge_shot.charge_size = fp.passive_vars.kirby.copysamus_charge_level

			Mpcommon.mpCommonRunWeaponCollisionDefault(fp.status_vars.kirby.copysamus_specialn.charge_gobj, fp.coll_data.p_translate, fp.coll_data)

			wp.weapon_vars.charge_shot.owner_gobj = null
			fp.status_vars.kirby.copysamus_specialn.charge_gobj = null

		else:
			Wpsamuschargeshot.wpSamusChargeShotMakeWeapon(fighter_gobj, pos, fp.passive_vars.kirby.copysamus_charge_level, 1)

		if fp.ga == nMPKineticsAir:
			charge_recoil_x = fp.passive_vars.kirby.copysamus_charge_level + 1

			fp.physics.vel_air.x = ((FTKIRBY_COPYSAMUS_CHARGE_RECOIL_MUL * charge_recoil_x) + FTKIRBY_COPYSAMUS_CHARGE_RECOIL_BASE) * -fp.lr

			charge_recoil_y = charge_recoil_x + FTKIRBY_COPYSAMUS_CHARGE_RECOIL_ADD + (fp.passive_vars.kirby.copysamus_charge_recoil * -FTKIRBY_COPYSAMUS_CHARGE_RECOIL_BASE)

			if fp.physics.vel_air.y < charge_recoil_y:
				fp.physics.vel_air.y = charge_recoil_y

			fp.passive_vars.kirby.copysamus_charge_recoil += 1

		else:
			fp.physics.vel_ground.x = -((FTKIRBY_COPYSAMUS_CHARGE_RECOIL_MUL * (fp.passive_vars.kirby.copysamus_charge_level + 1)) + FTKIRBY_COPYSAMUS_CHARGE_RECOIL_BASE)

		fp.passive_vars.kirby.copysamus_charge_level = 0

		fp.proc_damage = Callable()

	if fighter_gobj.anim_frame <= 0.0:
		Mpcommon.mpCommonSetFighterWaitOrFall(fighter_gobj)

## 0x801574D0
static func ftKirbyCopySamusSpecialNEndProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftkirbycopysamusspecialn, &"ftKirbyCopySamusSpecialNEndSwitchStatusAir"))

## 0x801574F4
static func ftKirbyCopySamusSpecialAirNEndProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbycopysamusspecialn, &"ftKirbyCopySamusSpecialAirNEndSwitchStatusGround"))

## 0x80157518
static func ftKirbyCopySamusSpecialAirNEndSwitchStatusGround(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopySamusSpecialNEnd, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_COLANIM)

	fp.proc_damage = Callable(Ftkirbycopysamusspecialn, &"ftKirbyCopySamusSpecialNProcDamage")

## 0x8015756C
static func ftKirbyCopySamusSpecialNEndSwitchStatusAir(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopySamusSpecialAirNEnd, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_COLANIM)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

	fp.proc_damage = Callable(Ftkirbycopysamusspecialn, &"ftKirbyCopySamusSpecialNProcDamage")

## 0x801575C8
static func ftKirbyCopySamusSpecialNEndSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopySamusSpecialNEnd, 0.0, 1.0, FTSTATUS_PRESERVE_COLANIM)

	fp.proc_damage = Callable(Ftkirbycopysamusspecialn, &"ftKirbyCopySamusSpecialNProcDamage")

## 0x80157610
static func ftKirbyCopySamusSpecialAirNEndSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsGround:
		Mpcommon.mpCommonSetFighterAir(fp)
		Ftphysics.ftPhysicsClampAirVelXMax(fp)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopySamusSpecialAirNEnd, 0.0, 1.0, FTSTATUS_PRESERVE_COLANIM)

	fp.proc_damage = Callable(Ftkirbycopysamusspecialn, &"ftKirbyCopySamusSpecialNProcDamage")

## 0x8015767C
static func ftKirbyCopySamusSpecialNStartGetAnimSpeed(fp = null) -> float:
	var ret: float = fp.passive_vars.kirby.copysamus_charge_level / float(FTKIRBY_COPYSAMUS_CHARGE_MAX)

	ret = (-0.16000003) * ret + 1.0

	return ret

## 0x801576B4
static func ftKirbyCopySamusSpecialNInitStatusVars(fp = null) -> void:
	fp.proc_damage = Callable(Ftkirbycopysamusspecialn, &"ftKirbyCopySamusSpecialNProcDamage")
	fp.status_vars.kirby.copysamus_specialn.charge_gobj = null
	fp.motion_vars.flags.flag0 = 0

## 0x801576CC
static func ftKirbyCopySamusSpecialNStartSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopySamusSpecialNStart, 0.0, ftKirbyCopySamusSpecialNStartGetAnimSpeed(fp), FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftKirbyCopySamusSpecialNInitStatusVars(fp)

	fp.status_vars.kirby.copysamus_specialn.is_release = TRUE if (fp.passive_vars.kirby.copysamus_charge_level == FTKIRBY_COPYSAMUS_CHARGE_MAX) else FALSE

## 0x80157744
static func ftKirbyCopySamusSpecialAirNStartSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopySamusSpecialAirNStart, 0.0, ftKirbyCopySamusSpecialNStartGetAnimSpeed(fp), FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftKirbyCopySamusSpecialNInitStatusVars(fp)

	fp.status_vars.kirby.copysamus_specialn.is_release = TRUE
