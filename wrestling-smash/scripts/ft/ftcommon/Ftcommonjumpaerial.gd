## 1:1 port of src/ft/ftcommon/ftcommonjumpaerial.c (ssb-decomp-re): mid-air jumps
## (JumpAerialF / JumpAerialB, Yoshi / Ness special physics, Kirby / Jigglypuff multi-jumps).
class_name Ftcommonjumpaerial
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x80188580
static var dFTKirbyJumpAerialFVelocities: Array = [60.0, 52.0, 47.0, 40.0]

## 0x801885A0
static var dFTPurinJumpAerialFVelocities: Array = [60.0, 40.0, 20.0, 0.0]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8013FA90
static func ftCommonJumpAerialUpdateModelYaw(fp: Fighter) -> void:
	if fp.status_vars.common.jumpaerial.turn_tics != 0:
		fp.status_vars.common.jumpaerial.turn_tics -= 1

		fp.joints[nFTPartsJointTopN].rotate.y += FTCOMMON_JUMPAERIAL_TURN_ROTATE_STEP

		Ftparam.ftParamsUpdateFighterPartsTransformAll(fp.joints[nFTPartsJointTopN])

		if fp.status_vars.common.jumpaerial.turn_tics == (FTCOMMON_JUMPAERIAL_TURN_FRAMES / 2):
			fp.lr = -fp.lr

## 0x8013FB00
static func ftCommonJumpAerialProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftCommonJumpAerialUpdateModelYaw(fp)
	Ftanimend.ftAnimEndSetFall(fighter_gobj)

## 0x8013FB2C
static func ftCommonJumpAerialProcInterrupt(fighter_gobj) -> void:
	if (not Ftcommonspecialair.ftCommonSpecialAirCheckInterruptCommon(fighter_gobj)) and (not Ftcommonattackair.ftCommonAttackAirCheckInterruptCommon(fighter_gobj)):
		ftCommonJumpAerialCheckInterruptCommon(fighter_gobj)

## 0x8013FB6C
static func ftYoshiJumpAerialProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	Ftphysics.ftPhysicsApplyAirVelTransNYZ(fighter_gobj)

	if not Ftphysics.ftPhysicsCheckClampAirVelXDecMax(fp, attr):
		Ftphysics.ftPhysicsClampAirVelXStickDefault(fp, attr)
		Ftphysics.ftPhysicsApplyAirVelXFriction(fp, attr)

## 0x8013FBC4
static func ftNessJumpAerialProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	# ftPhysicsGetAirVelTransN(fp, &fp->status_vars.common.jumpaerial.drift, &fp->physics.vel_air.y, &fp->physics.vel_air.z);
	# C signature: (FTStruct *fp, f32 *z, f32 *y, f32 *x) - all three are pure outputs.
	var r = Ftphysics.ftPhysicsGetAirVelTransN(fp)
	fp.status_vars.common.jumpaerial.drift = r.z
	fp.physics.vel_air.y = r.y
	fp.physics.vel_air.z = r.x

	fp.physics.vel_air.x = fp.status_vars.common.jumpaerial.vel_x

	if not Ftphysics.ftPhysicsCheckClampAirVelXDecMax(fp, attr):
		Ftphysics.ftPhysicsClampAirVelXStickDefault(fp, attr)
		Ftphysics.ftPhysicsApplyAirVelXFriction(fp, attr)
	fp.status_vars.common.jumpaerial.vel_x = fp.physics.vel_air.x

	fp.physics.vel_air.x += fp.status_vars.common.jumpaerial.drift

## 0x8013FC4C
static func ftCommonJumpAerialProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	Ftphysics.ftPhysicsCheckSetFastFall(fp)

	if fp.is_fastfall:
		Ftphysics.ftPhysicsApplyFastFall(fp, attr)
	else:
		Ftphysics.ftPhysicsApplyGravityDefault(fp, attr)

	match fp.fkind:
		nFTKindKirby, nFTKindNKirby:
			if not Ftphysics.ftPhysicsCheckClampAirVelXDecMax(fp, attr):
				Ftphysics.ftPhysicsClampAirVelXStickRange(fp, FTPHYSICS_AIRDRIFT_CLAMP_RANGE_MIN, attr.air_accel * FTKIRBY_JUMPAERIAL_VEL_MUL, attr.air_speed_max_x * FTKIRBY_JUMPAERIAL_VEL_MUL)

		nFTKindPurin, nFTKindNPurin:
			if not Ftphysics.ftPhysicsCheckClampAirVelXDecMax(fp, attr):
				Ftphysics.ftPhysicsClampAirVelXStickRange(fp, FTPHYSICS_AIRDRIFT_CLAMP_RANGE_MIN, attr.air_accel * FTPURIN_JUMPAERIAL_VEL_MUL, attr.air_speed_max_x * FTPURIN_JUMPAERIAL_VEL_MUL)
	Ftphysics.ftPhysicsApplyAirVelXFriction(fp, attr)

## 0x8013FD74
static func ftCommonJumpAerialSetStatus(fighter_gobj, input_source: int) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr
	var status_id: int = nFTCommonStatusJumpAerialF if ((fp.input.pl.stick_range.x * fp.lr) >= FTCOMMON_JUMPAERIAL_F_OR_B_RANGE) else nFTCommonStatusJumpAerialB
	var stick_range_y: int = I_CONTROLLER_RANGE_MAX
	var stick_range_x: int

	# It would seem that the stick range jump mechanic was initially considered for double jumps as well...

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_PLAYERTAG)

	if (fp.fkind == nFTKindYoshi) or (fp.fkind == nFTKindNYoshi):
		fp.proc_physics = Callable(Ftcommonjumpaerial, &"ftYoshiJumpAerialProcPhysics")
		fp.knockback_resist_status = FTYOSHI_JUMPAERIAL_KNOCKBACK_RESIST
	elif (fp.fkind == nFTKindNess) or (fp.fkind == nFTKindNNess):
		fp.proc_physics = Callable(Ftcommonjumpaerial, &"ftNessJumpAerialProcPhysics")
		fp.status_vars.common.jumpaerial.drift = 0.0
	match input_source: # Last minute bruh moment from HAL
		FTCOMMON_JUMPAERIAL_INPUT_TYPE_BUTTON:
			stick_range_x = fp.input.pl.stick_range.x

		_: # FTCOMMON_JUMPAERIAL_INPUT_TYPE_STICK, default
			stick_range_x = fp.input.pl.stick_range.x
	fp.physics.vel_air.y = (((stick_range_y * attr.jump_height_mul) + attr.jump_height_base) * attr.jumpaerial_height)

	if (fp.fkind == nFTKindNess) or (fp.fkind == nFTKindNNess):
		fp.status_vars.common.jumpaerial.vel_x = stick_range_x * attr.jumpaerial_vel_x
	else:
		fp.physics.vel_air.x = stick_range_x * attr.jumpaerial_vel_x

	fp.jumps_used += 1

	fp.tap_stick_y = FTINPUT_STICKBUFFER_TICS_MAX

	fp.is_special_interrupt = TRUE

	if ((fp.fkind == nFTKindYoshi) or (fp.fkind == nFTKindNYoshi)) and ((fp.input.pl.stick_range.x * fp.lr) < FTCOMMON_JUMPAERIAL_TURN_STICK_RANGE_MIN):
		fp.status_vars.common.jumpaerial.turn_tics = FTCOMMON_JUMPAERIAL_TURN_FRAMES
	else:
		fp.status_vars.common.jumpaerial.turn_tics = 0

	ftCommonJumpAerialUpdateModelYaw(fp)

## 0x8013FF38
static func ftCommonJumpAerialMultiSetStatus(fighter_gobj, input_source: int) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr
	var status_id: int = 0   # C: uninitialized for fighters other than Kirby / Jigglypuff (never called for them)
	var stick_range_x: int
	var stick_range_y: int = I_CONTROLLER_RANGE_MAX

	match fp.fkind:
		nFTKindKirby, nFTKindNKirby:
			status_id = fp.jumps_used + nFTKirbyStatusJumpAerialF1 - 1

		nFTKindPurin, nFTKindNPurin:
			status_id = fp.jumps_used + nFTPurinStatusJumpAerialF1 - 1
	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_PLAYERTAG)

	match input_source:
		FTCOMMON_JUMPAERIAL_INPUT_TYPE_BUTTON:
			stick_range_x = fp.input.pl.stick_range.x

		_: # FTCOMMON_JUMPAERIAL_INPUT_TYPE_STICK, default
			stick_range_x = fp.input.pl.stick_range.x

	fp.physics.vel_air.x = stick_range_x * attr.jumpaerial_vel_x

	if fp.jumps_used == 1:
		fp.physics.vel_air.y = (((stick_range_y * attr.jump_height_mul) + attr.jump_height_base) * attr.jumpaerial_height)

		fp.tap_stick_y = FTINPUT_STICKBUFFER_TICS_MAX
	else:
		match fp.fkind:
			nFTKindKirby, nFTKindNKirby:
				fp.physics.vel_air.y = dFTKirbyJumpAerialFVelocities[fp.jumps_used - 2] * (stick_range_y / float(F_CONTROLLER_RANGE_MAX))

			nFTKindPurin, nFTKindNPurin:
				fp.physics.vel_air.y = dFTPurinJumpAerialFVelocities[fp.jumps_used - 2] * (stick_range_y / float(F_CONTROLLER_RANGE_MAX))
	fp.jumps_used += 1

	fp.motion_vars.flags.flag1 = 0

	fp.is_special_interrupt = TRUE

	if (fp.input.pl.stick_range.x * fp.lr) < FTCOMMON_JUMPAERIAL_TURN_STICK_RANGE_MIN:
		fp.status_vars.common.jumpaerial.turn_tics = FTCOMMON_JUMPAERIAL_TURN_FRAMES
	else:
		fp.status_vars.common.jumpaerial.turn_tics = 0

	ftCommonJumpAerialUpdateModelYaw(fp)

## 0x8014012C
static func ftCommonJumpAerialMultiCheckJumpButtonHold(fp: Fighter) -> int:
	if fp.input.pl.button_hold & (R_CBUTTONS | L_CBUTTONS | D_CBUTTONS | U_CBUTTONS):
		return TRUE
	else:
		return FALSE

## 0x80140150
static func ftCommonJumpAerialMultiGetJumpInputType(fp: Fighter) -> int:
	if fp.input.pl.stick_range.y >= FTCOMMON_JUMPAERIAL_STICK_RANGE_MIN:
		return FTCOMMON_JUMPAERIAL_INPUT_TYPE_STICK
	elif ftCommonJumpAerialMultiCheckJumpButtonHold(fp) != FALSE:
		return FTCOMMON_JUMPAERIAL_INPUT_TYPE_BUTTON
	else:
		return FTCOMMON_JUMPAERIAL_INPUT_TYPE_NONE

## 0x8014019C
static func ftCommonJumpAerialCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var input_source: int

	if Fthammer.ftHammerCheckHoldHammer(fighter_gobj):
		return FALSE
	elif (fp.fkind == nFTKindKirby) or (fp.fkind == nFTKindNKirby) or (fp.fkind == nFTKindPurin) or (fp.fkind == nFTKindNPurin):
		if fp.jumps_used < fp.attr.jumps_max:
			if fp.jumps_used == 1:
				input_source = Ftcommonkneebend.ftCommonKneeBendGetInputTypeCommon(fp)

				if input_source != FTCOMMON_JUMPAERIAL_INPUT_TYPE_NONE:
					ftCommonJumpAerialMultiSetStatus(fighter_gobj, input_source)

					return TRUE
			else:
				match fp.fkind:
					nFTKindKirby, nFTKindNKirby:
						if (fp.status_id < nFTKirbyStatusJumpAerialF1) or (fp.status_id > nFTKirbyStatusJumpAerialF5) or (fp.motion_vars.flags.flag1 != 0):
							input_source = ftCommonJumpAerialMultiGetJumpInputType(fp)

							if input_source != FTCOMMON_JUMPAERIAL_INPUT_TYPE_NONE:
								ftCommonJumpAerialMultiSetStatus(fighter_gobj, input_source)

								return TRUE

					nFTKindPurin, nFTKindNPurin:
						if (fp.status_id < nFTPurinStatusJumpAerialF1) or (fp.status_id > nFTPurinStatusJumpAerialF5) or (fp.motion_vars.flags.flag1 != 0):
							input_source = ftCommonJumpAerialMultiGetJumpInputType(fp)

							if input_source != FTCOMMON_JUMPAERIAL_INPUT_TYPE_NONE:
								ftCommonJumpAerialMultiSetStatus(fighter_gobj, input_source)

								return TRUE
	else:
		input_source = Ftcommonkneebend.ftCommonKneeBendGetInputTypeCommon(fp)

		if (input_source != FTCOMMON_JUMPAERIAL_INPUT_TYPE_NONE) and (fp.jumps_used < fp.attr.jumps_max):
			ftCommonJumpAerialSetStatus(fighter_gobj, input_source)

			return TRUE
	return FALSE
