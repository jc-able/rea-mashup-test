## Port of src/ft/ftchar/ftcaptain/ftcaptainspecialhi.c (Captain Falcon up special: Falcon Dive).
class_name Ftcaptainspecialhi
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80160280
static func ftCaptainSpecialHiSetCatchParams(fp) -> void:
	Ftparam.ftParamSetCatchParams(fp, FTCATCHKIND_MASK_CAPTAINSPECIALHI, Callable(Ftcaptainspecialhi, &"ftCaptainSpecialHiProcCatch"), Callable(Ftcommoncapturecaptain, &"ftCommonCaptureCaptainProcCapture"))

## 0x801602B0
static func ftCaptainSpecialHiProcUpdate(fighter_gobj) -> void:
	if fighter_gobj.anim_frame <= 0.0:
		Ftcommonfallspecial.ftCommonFallSpecialSetStatus(fighter_gobj, FTCAPTAIN_FALCONDIVE_FALLSPECIAL_DRIFT, FALSE, TRUE, TRUE, FTCAPTAIN_FALCONDIVE_LANDING_LAG, FALSE)

## 0x80160304
static func ftCaptainSpecialHiCatchProcUpdate(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)

	if (fighter_gobj.anim_frame <= 0.0) or (this_fp.motion_vars.flags.flag0 != 0):
		var catch_fp := ftGetStruct(this_fp.catch_gobj)

		catch_fp.status_vars.common.capturecaptain.capture_flag = (catch_fp.status_vars.common.capturecaptain.capture_flag | FTCOMMON_CAPTURECAPTAIN_MASK_THROW) & 0xFFFF

		Efmanager.efManagerQuakeMakeEffect(1) # Apply screen shake/rumble?
		ftCaptainSpecialHiThrowSetStatus(fighter_gobj)

## 0x80160370
static func ftCaptainSpecialHiProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 != 0:
		fp.motion_vars.flags.flag1 = 0

		if ABS(fp.input.pl.stick_range.x) > FTCAPTAIN_FALCONDIVE_TURN_STICK_RANGE_MIN:
			Ftparam.ftParamSetStickLR(fp)

			fp.joints[nFTPartsJointTopN].rotate.y = fp.lr * HALF_PI32

## 0x801603F0
static func ftCaptainSpecialHiProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	fp.physics.vel_air.x = fp.status_vars.captain.specialhi.vel.x
	fp.physics.vel_air.y = fp.status_vars.captain.specialhi.vel.y
	fp.physics.vel_air.z = 0.0

	if Ftphysics.ftPhysicsCheckClampAirVelXDec(fp, attr.air_speed_max_x * FTCAPTAIN_FALCONDIVE_AIR_SPEED_MAX_MUL) == FALSE:
		Ftphysics.ftPhysicsClampAirVelXStickRange(fp, FTPHYSICS_AIRDRIFT_CLAMP_RANGE_MIN, attr.air_accel * FTCAPTAIN_FALCONDIVE_AIR_ACCEL_MUL, attr.air_speed_max_x * FTCAPTAIN_FALCONDIVE_AIR_SPEED_MAX_MUL)
		Ftphysics.ftPhysicsApplyAirVelXFriction(fp, attr)

	fp.status_vars.captain.specialhi.vel.x = fp.physics.vel_air.x
	fp.status_vars.captain.specialhi.vel.y = fp.physics.vel_air.y

	Ftphysics.ftPhysicsApplyAirVelTransNAll(fighter_gobj)

	fp.physics.vel_air.x += fp.status_vars.captain.specialhi.vel.x
	fp.physics.vel_air.y += fp.status_vars.captain.specialhi.vel.y

## 0x801604D8
static func ftCaptainSpecialHiCatchProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var vec: Vector3

	if not (fp.status_vars.captain.specialhi.flags & 4):
		# vec is a pure output of ftCommonCaptureCaptainUpdatePositions (void, one out-param -> returned)
		vec = Ftcommoncapturecaptain.ftCommonCaptureCaptainUpdatePositions(fighter_gobj, fp.catch_gobj)

		if syVectorMag3D(vec) > 180.0:
			vec = syVectorNorm3D(vec)
			# syVectorScale3D(&vec, 180.0F) (sys/vector.c: dst->x/y/z *= scale)
			vec.x *= 180.0
			vec.y *= 180.0
			vec.z *= 180.0

		# syVectorSub3D(&DObjGetStruct(fighter_gobj)->translate.vec.f, &vec) (dst->x/y/z -= sub->x/y/z)
		DObjGetStruct(fighter_gobj).translate.x -= vec.x
		DObjGetStruct(fighter_gobj).translate.y -= vec.y
		DObjGetStruct(fighter_gobj).translate.z -= vec.z

## 0x80160560
static func ftCaptainSpecialHiProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.physics.vel_air.y < 0.0:
		if fp.motion_vars.flags.flag2 == 0:
			Mpcommon.mpCommonProcFighterCliffWaitOrLanding(fighter_gobj)
		else:
			Mpcommon.mpCommonProcFighterProject(fighter_gobj)
			fp.motion_vars.flags.flag2 -= 1

	elif (Mpcommon.mpCommonCheckFighterCeilHeavyCliff(fighter_gobj) != FALSE) and (fp.coll_data.mask_stat & MAP_FLAG_CLIFF_MASK):
		Ftcommoncliffcatchwait.ftCommonCliffCatchSetStatus(fighter_gobj)

## 0x801605FC
static func ftCaptainSpecialHiProcStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.jumps_used = fp.attr.jumps_max

	fp.status_vars.captain.specialhi.flags = 0

	fp.motion_vars.flags.flag0 = 0
	fp.motion_vars.flags.flag1 = 0
	fp.motion_vars.flags.flag2 = FTCAPTAIN_FALCONDIVE_UNK_TIMER

	fp.status_vars.captain.specialhi.vel.x = 0.0
	fp.status_vars.captain.specialhi.vel.y = 0.0

## 0x80160630
static func ftCaptainSpecialHiSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)

	fp.proc_status = Callable(Ftcaptainspecialhi, &"ftCaptainSpecialHiProcStatus")

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCaptainStatusSpecialHi, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftCaptainSpecialHiSetCatchParams(fp)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80160690
static func ftCaptainSpecialHiProcCatch(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var catch_fp: Fighter
	var search_gobj

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCaptainStatusSpecialHiCatch, 0.0, 1.0, FTSTATUS_PRESERVE_EFFECT)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)
	Ftphysics.ftPhysicsStopVelAll(fighter_gobj)

	search_gobj = fp.search_gobj
	fp.catch_gobj = search_gobj

	catch_fp = ftGetStruct(search_gobj) # No NULL check, might be dangerous

	if catch_fp.ga == nMPKineticsAir:
		# C union FTStatusVars: status_vars.common.capturecaptain.capture_flag and
		# status_vars.captain.specialhi.flags are the same u16 (offset 0); the |= reads the value last
		# written through specialhi.flags (ftCaptainSpecialHiProcStatus) and the result is what
		# ftCaptainSpecialHiCatchProcPhysics reads back through specialhi.flags. Keep both views in sync.
		fp.status_vars.common.capturecaptain.capture_flag = (fp.status_vars.captain.specialhi.flags | FTCOMMON_CAPTURECAPTAIN_MASK_NOUPDATE) & 0xFFFF
		fp.status_vars.captain.specialhi.flags = fp.status_vars.common.capturecaptain.capture_flag
		fp.is_catch_or_capture = FALSE
	else:
		fp.is_catch_or_capture = TRUE

## 0x80160730
static func ftCaptainSpecialHiThrowSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCaptainStatusSpecialHiThrow, 0.0, 1.0, FTSTATUS_PRESERVE_EFFECT)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_NONE)

	if (fp.is_catch_or_capture == TRUE) and (fp.catch_gobj != null):
		Ftcommonthrown2.ftCommonThrownReleaseFighterLoseGrip(fighter_gobj)

	fp.catch_gobj = null

## 0x801607B4
static func ftCaptainSpecialAirHiSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_status = Callable(Ftcaptainspecialhi, &"ftCaptainSpecialHiProcStatus")

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCaptainStatusSpecialAirHi, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftCaptainSpecialHiSetCatchParams(fp)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
