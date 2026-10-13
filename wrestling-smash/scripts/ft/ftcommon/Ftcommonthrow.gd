## 1:1 port of src/ft/ftcommon/ftcommonthrow.c (ssb-decomp-re): ThrowF / ThrowB (thrower side).
class_name Ftcommonthrow
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8014A0C0
static func ftCommonThrowProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 != 0:
		fp.motion_vars.flags.flag1 = 0

		fp.lr = -fp.lr

		fp.physics.vel_ground.x = -fp.physics.vel_ground.x
	if fp.motion_vars.flags.flag2 != 0:
		Ftcommonthrown1.ftCommonThrownProcPhysics(fp.catch_gobj)
		Ftcommonthrown2.ftCommonThrownReleaseThrownUpdateStats(fp.catch_gobj, -fp.lr if (fp.motion_vars.flags.flag2 == 1) else fp.lr, 1 if (fp.status_id == nFTCommonStatusThrowB) else 0, TRUE)

		fp.motion_vars.flags.flag2 = 0

		fp.catch_gobj = null

		Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_NONE)
	if fighter_gobj.anim_frame <= 0.0:
		if (fp.fkind == nFTKindDonkey) or (fp.fkind == nFTKindNDonkey) or (fp.fkind == nFTKindGDonkey):
			if fp.status_id == nFTCommonStatusThrowF:
				Ftcommoncapture.ftCommonCaptureShoulderedSetStatus(fp.catch_gobj)
				Ftdonkeythrowfwait.ftDonkeyThrowFWaitSetStatus(fighter_gobj)

				return
		Mpcommon.mpCommonSetFighterWaitOrFall(fighter_gobj)

## 0x8014A1E8
static func ftCommonThrowSetStatus(fighter_gobj, is_throwf) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var status_id: int
	var catch_gobj
	var catch_fp: Fighter
	var thrown_status       # FTThrownStatus * -> {status1, status2}

	catch_gobj = this_fp.catch_gobj
	catch_fp = ftGetStruct(catch_gobj)

	if B(is_throwf) or ((this_fp.input.pl.stick_range.x * this_fp.lr) >= 0):
		if (this_fp.fkind == nFTKindKirby) or (this_fp.fkind == nFTKindNKirby):
			status_id = nFTKirbyStatusThrowF

			Mpcommon.mpCommonSetFighterAir(this_fp)
		else:
			status_id = nFTCommonStatusThrowF
		thrown_status = this_fp.attr.thrown_status[catch_fp.fkind].ft_thrown[0]
	else:
		status_id = nFTCommonStatusThrowB
		thrown_status = this_fp.attr.thrown_status[catch_fp.fkind].ft_thrown[1]
	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	Ftparam.ftParamSetCaptureImmuneMask(this_fp, FTCATCHKIND_MASK_ALL)

	this_fp.motion_vars.flags.flag2 = 0
	this_fp.motion_vars.flags.flag1 = 0

	if (this_fp.fkind == nFTKindSamus) or (this_fp.fkind == nFTKindNSamus):
		if Efmanager.efManagerSamusGrappleBeamGlowMakeEffect(fighter_gobj) != null:
			this_fp.is_effect_attach = TRUE
	if thrown_status.status1 != -1:
		Ftcommonthrown1.ftCommonThrownSetStatusQueue(catch_gobj, thrown_status.status1, thrown_status.status2)
	else:
		Ftcommonthrown1.ftCommonThrownSetStatusImmediate(catch_gobj, thrown_status.status2)

	if (this_fp.fkind == nFTKindKirby) or (this_fp.fkind == nFTKindNKirby):
		if status_id == nFTKirbyStatusThrowF:
			this_fp.is_ignore_dead = TRUE
			catch_fp.is_ignore_dead = TRUE

## 0x8014A394
static func ftCommonThrowCheckInterruptCatchWait(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var is_throwf: int = FALSE

	if (fp.status_vars.common.catchwait.throw_wait == 0) or (fp.input.pl.button_tap & (fp.input.button_mask_a | fp.input.button_mask_b)):
		is_throwf = TRUE
	elif (fp.input.pl.stick_prev.x >= FTCOMMON_CATCH_THROW_STICK_RANGE_MIN) or (fp.input.pl.stick_range.x < FTCOMMON_CATCH_THROW_STICK_RANGE_MIN):
		if (fp.input.pl.stick_prev.x <= -FTCOMMON_CATCH_THROW_STICK_RANGE_MIN) or (fp.input.pl.stick_range.x > -FTCOMMON_CATCH_THROW_STICK_RANGE_MIN):
			return FALSE
	ftCommonThrowSetStatus(fighter_gobj, is_throwf)

	return TRUE
