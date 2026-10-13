## 1:1 port of src/ft/ftcommon/ftcommonguard2.c (ssb-decomp-re): GuardOff / GuardSetOff (shield stun)
## and Yoshi's roll-into-shield.
class_name Ftcommonguard2
extends Port

## C f32 rounding of an intermediate result (the original computes in single precision; setoff_frames
## is a frame countdown compared against 0.0F, so its f32 value decides the shield-stun length).
static func _f32(x: float) -> float:
	var a := PackedFloat32Array([x])
	return a[0]

## efGetStruct(effect_gobj) (src/ef/effect.h) = (EFStruct*)effect_gobj->user_data.p. The effect port may keep
## the EFStruct in user_data or (like Fighter/Weapon/Item) let the GObj carry the struct fields itself.
static func _efGetStruct(effect_gobj):
	if effect_gobj.user_data != null:
		return effect_gobj.user_data
	return effect_gobj

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80148E30
static func ftCommonGuardSetStatusFromEscape(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusGuardOn, 0.0, 1.0, FTSTATUS_PRESERVE_NONE) # Why? It overwrites this with Guard later down.
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	if fp.shield_health != 0:
		if fp.fkind == nFTKindYoshi:
			fp.status_vars.common.guard.effect_gobj = Efmanager.efManagerYoshiShieldMakeEffect(fighter_gobj)

			Ftparam.ftParamHideModelPartAll(fighter_gobj)
			Ftcommonguard1.ftCommonGuardSetHitStatusYoshi(fighter_gobj)
		else:
			fp.status_vars.common.guard.effect_gobj = Efmanager.efManagerShieldMakeEffect(fighter_gobj)

		fp.is_shield = TRUE
	Ftcommonguard1.ftCommonGuardUpdateJoints(fighter_gobj)

	fp.status_vars.common.guard.release_lag = FTCOMMON_GUARD_RELEASE_LAG
	fp.status_vars.common.guard.shield_decay_wait = FTCOMMON_GUARD_DECAY_INT
	fp.status_vars.common.guard.is_release = FALSE
	fp.status_vars.common.guard.slide_tics = 0
	fp.status_vars.common.guard.is_setoff = FALSE

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusGuard, 0.0, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_EFFECT))

	Ftcommonguard1.ftCommonGuardInitJoints(fighter_gobj)

	fp.is_shield = TRUE

## 0x80148F24
static func ftCommonGuardCheckInterruptEscape(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.input.pl.button_hold & fp.input.button_mask_z) and (fp.shield_health != 0):
		ftCommonGuardSetStatusFromEscape(fighter_gobj)

		return TRUE
	else:
		return FALSE

## 0x80148F74
static func ftCommonGuardOffProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftcommonguard1.ftCommonGuardUpdateShieldVars(fighter_gobj)

	if fp.shield_health == 0:
		Ftcommonshieldbreakfly.ftCommonShieldBreakFlyCommonSetStatus(fighter_gobj)
	elif fighter_gobj.anim_frame <= 0.0:
		Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)
	else:
		Ftcommonguard1.ftCommonGuardUpdateJoints(fighter_gobj)

## 0x80148FF0
static func ftCommonGuardOffSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var flag: int = fp.is_shield

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusGuardOff, 0.0, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_EFFECT))
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.is_shield = flag

	Ftcommonguard1.ftCommonGuardUpdateJoints(fighter_gobj)
	Snd.func_800269C0_275C0(nSYAudioFGMGuardOff)

## 0x80149074
static func ftCommonGuardSetOffProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftcommonguard1.ftCommonGuardCheckScheduleRelease(fp)

	fp.status_vars.common.guard.setoff_frames = _f32(fp.status_vars.common.guard.setoff_frames - 1.0)

	if fp.status_vars.common.guard.setoff_frames <= 0.0:
		if fp.status_vars.common.guard.is_release != FALSE:
			ftCommonGuardOffSetStatus(fighter_gobj)
		else:
			Ftcommonguard1.ftCommonGuardSetStatus(fighter_gobj)
	else:
		Ftcommonguard1.ftCommonGuardInitJoints(fighter_gobj)

## 0x80149108
static func ftCommonGuardSetOffSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusGuardSetOff, 0.0, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_EFFECT))

	# (fp->shield_damage * FTCOMMON_GUARD_SETOFF_MUL) + FTCOMMON_GUARD_SETOFF_ADD, in f32 (1.62F, 4.0F)
	fp.status_vars.common.guard.setoff_frames = _f32(_f32(fp.shield_damage * _f32(FTCOMMON_GUARD_SETOFF_MUL)) + FTCOMMON_GUARD_SETOFF_ADD)

	fp.physics.vel_ground.x = (-1 if (fp.lr == fp.shield_lr) else +1) * (fp.status_vars.common.guard.setoff_frames * FTCOMMON_GUARD_VEL_MUL)

	if fp.status_vars.common.guard.effect_gobj != null:
		var ep = _efGetStruct(fp.status_vars.common.guard.effect_gobj)

		# Visual-only flag (efManagerShieldProcDisplay flashes the shield colour); always present in
		# the original, guarded here against not-yet-ported effect objects.
		if (ep != null) and ("effect_vars" in ep):
			ep.effect_vars.shield.is_damage_shield = TRUE
	fp.is_shield = TRUE

	fp.status_vars.common.guard.is_setoff = TRUE
