## 1:1 port of src/ft/ftchar/ftsamus/ftsamusspecialn.c (ssb-decomp-re).
## Samus neutral special (Charge Shot).
class_name Ftsamusspecialn
extends Port

## ftSamusSpecialNLoopProcInterrupt calls ftCommonEscapeSetStatus(fighter_gobj, status_id) without its third
## argument (itemthrow_buffer_tics). In the US ROM (0x8015D6B8) register a2 at that call still holds the
## FTStruct pointer `fp` (ftSamusSpecialNDestroyChargeShot does `or a2,a0,zero` and restores it after
## wpMainDestroyWeapon), so the roll starts with itemthrow_buffer_tics = (s32)fp: a KSEG0 address
## (0x801xxxxx), i.e. a large negative s32 that never counts down to 0 during the roll.
## This port passes a representative KSEG0 address with the same sign/magnitude behaviour.
const FTSAMUS_SPECIALN_ESCAPE_UB_ITEMTHROW_BUFFER_TICS: int = 0x80130000 - 0x100000000

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8015D300
static func ftSamusSpecialNDestroyChargeShot(fp: Fighter) -> void:
	if fp.status_vars.samus.specialn.charge_gobj != null:
		Wpmain.wpMainDestroyWeapon(fp.status_vars.samus.specialn.charge_gobj)

		fp.status_vars.samus.specialn.charge_gobj = null

## 0x8015D338 - Runs when Samus is hit out of Charge Shot
static func ftSamusSpecialNProcDamage(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.passive_vars.samus.charge_level = 0

	ftSamusSpecialNDestroyChargeShot(fp)

## 0x8015D35C
## C: void ftSamusSpecialNGetChargeShotPosition(FTStruct *fp, Vec3f *pos) - `pos` is a pure output
## (fully written before use), so per the out-parameter convention it is the return value.
static func ftSamusSpecialNGetChargeShotPosition(fp: Fighter) -> Vector3:
	var pos: Vector3

	pos.z = 0.0
	pos.y = pos.z
	pos.x = FTSAMUS_CHARGE_OFF_X

	pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[FTSAMUS_CHARGE_JOINT], pos)

	return pos

## 0x8015D394
static func ftSamusSpecialNSetChargeShotPosition(fp: Fighter) -> void:
	var pos: Vector3

	if fp.status_vars.samus.specialn.charge_gobj != null:
		pos = ftSamusSpecialNGetChargeShotPosition(fp)

		DObjGetStruct(fp.status_vars.samus.specialn.charge_gobj).translate = pos

## 0x8015D3EC
static func ftSamusSpecialNStartProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fighter_gobj.anim_frame <= 0.0:
		if fp.ga == nMPKineticsAir:
			ftSamusSpecialAirNEndSetStatus(fighter_gobj)
		elif fp.status_vars.samus.specialn.is_release != FALSE:
			ftSamusSpecialNEndSetStatus(fighter_gobj)
		else:
			ftSamusSpecialNLoopSetStatus(fighter_gobj)

## 0x8015D464
static func ftSamusSpecialNStartProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.input.pl.button_tap & fp.input.button_mask_b) or (fp.input.pl.button_tap & fp.input.button_mask_a):
		fp.status_vars.samus.specialn.is_release = TRUE

## 0x8015D49C
static func ftSamusSpecialNStartProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftsamusspecialn, &"ftSamusSpecialNStartSwitchStatusAir"))

## 0x8015D4C0
static func ftSamusSpecialAirNStartProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftsamusspecialn, &"ftSamusSpecialAirNStartSwitchStatusGround"))

## 0x8015D4E4
static func ftSamusSpecialAirNStartSwitchStatusGround(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTSamusStatusSpecialNStart, fighter_gobj.anim_frame, fp.joints[nFTPartsJointTopN].anim_speed, FTSTATUS_PRESERVE_COLANIM)

	fp.proc_damage = Callable(Ftsamusspecialn, &"ftSamusSpecialNProcDamage")

## 0x8015D540
static func ftSamusSpecialNStartSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTSamusStatusSpecialAirNStart, fighter_gobj.anim_frame, fp.joints[nFTPartsJointTopN].anim_speed, FTSTATUS_PRESERVE_COLANIM)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

	fp.proc_damage = Callable(Ftsamusspecialn, &"ftSamusSpecialNProcDamage")

	fp.status_vars.samus.specialn.is_release = TRUE

## 0x8015D5AC
static func ftSamusSpecialNLoopProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.samus.specialn.charge_int -= 1

	if fp.status_vars.samus.specialn.charge_int == 0:
		fp.status_vars.samus.specialn.charge_int = FTSAMUS_CHARGE_INT

		if fp.passive_vars.samus.charge_level <= (FTSAMUS_CHARGE_MAX - 1):
			fp.passive_vars.samus.charge_level += 1

			if fp.passive_vars.samus.charge_level == FTSAMUS_CHARGE_MAX:
				Ftparam.ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterCommonSpecialNCharge, 0)
				ftSamusSpecialNDestroyChargeShot(fp)
				Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)
			elif fp.status_vars.samus.specialn.charge_gobj != null:
				var wp := wpGetStruct(fp.status_vars.samus.specialn.charge_gobj)

				wp.weapon_vars.charge_shot.charge_size = fp.passive_vars.samus.charge_level

## 0x8015D640
static func ftSamusSpecialNLoopProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int

	if (fp.input.pl.button_tap & fp.input.button_mask_b) or (fp.input.pl.button_tap & fp.input.button_mask_a):
		ftSamusSpecialNEndSetStatus(fighter_gobj)
		return
	status_id = Ftcommonescape.ftCommonEscapeGetStatus(fp)

	if status_id != -1:
		ftSamusSpecialNDestroyChargeShot(fp)

		# WARNING: Undefined behavior in C. This function expects a third argument
		# for item throw buffer frames, but never receives it (see FTSAMUS_SPECIALN_ESCAPE_UB_ITEMTHROW_BUFFER_TICS).
		Ftcommonescape.ftCommonEscapeSetStatus(fighter_gobj, status_id, FTSAMUS_SPECIALN_ESCAPE_UB_ITEMTHROW_BUFFER_TICS)
	elif fp.input.pl.button_tap & fp.input.button_mask_z:
		ftSamusSpecialNDestroyChargeShot(fp)
		Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)

## 0x8015D700
static func ftSamusSpecialNLoopProcMap(fighter_gobj) -> void:
	ftSamusSpecialNSetChargeShotPosition(ftGetStruct(fighter_gobj))
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftsamusspecialn, &"ftSamusSpecialAirNEndSetStatus"))

## 0x8015D734
static func ftSamusSpecialNLoopSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3

	Ftmain.ftMainSetStatus(fighter_gobj, nFTSamusStatusSpecialNLoop, 0.0, 1.0, FTSTATUS_PRESERVE_COLANIM)

	fp.proc_damage = Callable(Ftsamusspecialn, &"ftSamusSpecialNProcDamage")
	fp.status_vars.samus.specialn.charge_int = FTSAMUS_CHARGE_INT

	pos = ftSamusSpecialNGetChargeShotPosition(fp)
	fp.status_vars.samus.specialn.charge_gobj = Wpsamuschargeshot.wpSamusChargeShotMakeWeapon(fighter_gobj, pos, fp.passive_vars.samus.charge_level, FALSE)

## 0x8015D7AC
static func ftSamusSpecialNEndProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3
	var wp: Weapon
	var charge_recoil_x: float
	var charge_recoil_y: float

	if fp.motion_vars.flags.flag0 != FALSE:
		fp.motion_vars.flags.flag0 = FALSE

		pos = ftSamusSpecialNGetChargeShotPosition(fp)

		if fp.status_vars.samus.specialn.charge_gobj != null:
			wp = wpGetStruct(fp.status_vars.samus.specialn.charge_gobj)
			Ftparam.ftParamStopLoopSFX(fp)

			DObjGetStruct(fp.status_vars.samus.specialn.charge_gobj).translate = pos

			wp.weapon_vars.charge_shot.is_full_charge = TRUE
			wp.weapon_vars.charge_shot.charge_size = fp.passive_vars.samus.charge_level

			Mpcommon.mpCommonRunWeaponCollisionDefault(fp.status_vars.samus.specialn.charge_gobj, fp.coll_data.p_translate, fp.coll_data)

			wp.weapon_vars.charge_shot.owner_gobj = null
			fp.status_vars.samus.specialn.charge_gobj = null
		else:
			Wpsamuschargeshot.wpSamusChargeShotMakeWeapon(fighter_gobj, pos, fp.passive_vars.samus.charge_level, TRUE)

		if fp.ga == nMPKineticsAir:
			charge_recoil_x = (fp.passive_vars.samus.charge_level + 1)

			fp.physics.vel_air.x = ((FTSAMUS_CHARGE_RECOIL_MUL * charge_recoil_x) + FTSAMUS_CHARGE_RECOIL_BASE) * -fp.lr

			charge_recoil_y = charge_recoil_x + FTSAMUS_CHARGE_RECOIL_ADD + (fp.passive_vars.samus.charge_recoil * -FTSAMUS_CHARGE_RECOIL_BASE)

			if fp.physics.vel_air.y < charge_recoil_y:
				fp.physics.vel_air.y = charge_recoil_y
			fp.passive_vars.samus.charge_recoil += 1
		else:
			fp.physics.vel_ground.x = -((FTSAMUS_CHARGE_RECOIL_MUL * (fp.passive_vars.samus.charge_level + 1)) + FTSAMUS_CHARGE_RECOIL_BASE)

		fp.passive_vars.samus.charge_level = 0
		fp.proc_damage = Callable()
	if fighter_gobj.anim_frame <= 0.0:
		Mpcommon.mpCommonSetFighterWaitOrFall(fighter_gobj)

## 0x8015D968
static func ftSamusSpecialNEndProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftsamusspecialn, &"ftSamusSpecialNEndSwitchStatusAir"))

## 0x8015D98C
static func ftSamusSpecialAirNEndProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftsamusspecialn, &"ftSamusSpecialAirNEndSwitchStatusGround"))

## 0x8015D9B0
static func ftSamusSpecialAirNEndSwitchStatusGround(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTSamusStatusSpecialNEnd, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_COLANIM)

	fp.proc_damage = Callable(Ftsamusspecialn, &"ftSamusSpecialNProcDamage")

## 0x8015DA04
static func ftSamusSpecialNEndSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTSamusStatusSpecialAirNEnd, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_COLANIM)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

	fp.proc_damage = Callable(Ftsamusspecialn, &"ftSamusSpecialNProcDamage")

## 0x8015DA60
static func ftSamusSpecialNEndSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTSamusStatusSpecialNEnd, 0.0, 1.0, FTSTATUS_PRESERVE_COLANIM)

	fp.proc_damage = Callable(Ftsamusspecialn, &"ftSamusSpecialNProcDamage")

## 0x8015DAA8
static func ftSamusSpecialAirNEndSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsGround:
		Mpcommon.mpCommonSetFighterAir(fp)
		Ftphysics.ftPhysicsClampAirVelXMax(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTSamusStatusSpecialAirNEnd, 0.0, 1.0, FTSTATUS_PRESERVE_COLANIM)

	fp.proc_damage = Callable(Ftsamusspecialn, &"ftSamusSpecialNProcDamage")

## 0x8015DB14
static func ftSamusSpecialNStartGetAnimSpeed(fp: Fighter) -> float:
	var ret: float = fp.passive_vars.samus.charge_level / float(FTSAMUS_CHARGE_MAX)

	ret = (-0.16000003) * ret + 1.0

	return ret

## 0x8015DB4C
static func ftSamusSpecialNStartInitStatusVars(fp: Fighter) -> void:
	fp.proc_damage = Callable(Ftsamusspecialn, &"ftSamusSpecialNProcDamage")
	fp.status_vars.samus.specialn.charge_gobj = null
	fp.motion_vars.flags.flag0 = FALSE

## 0x8015DB64
static func ftSamusSpecialNStartSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTSamusStatusSpecialNStart, 0.0, ftSamusSpecialNStartGetAnimSpeed(fp), FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftSamusSpecialNStartInitStatusVars(fp)

	fp.status_vars.samus.specialn.is_release = TRUE if (fp.passive_vars.samus.charge_level == FTSAMUS_CHARGE_MAX) else FALSE

## 0x8015DBDC
static func ftSamusSpecialAirNStartSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTSamusStatusSpecialAirNStart, 0.0, ftSamusSpecialNStartGetAnimSpeed(fp), FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftSamusSpecialNStartInitStatusVars(fp)

	fp.status_vars.samus.specialn.is_release = TRUE
