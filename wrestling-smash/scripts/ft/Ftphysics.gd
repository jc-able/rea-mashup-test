## 1:1 port of src/ft/ftphysics.c (ssb-decomp-re): fighter ground friction / velocity transfer,
## air drift, gravity, fast fall, velocity clamps and TransN-joint (animation-driven) velocities.
##
## Out-parameter convention (PORTING.md):
##   ftPhysicsGetAirVelTransN(fp, f32 *z, f32 *y, f32 *x) -> ftPhysicsGetAirVelTransN(fp) returns
##   {"z", "y", "x"} (C callers passing NULL simply ignore that key).
class_name Ftphysics
extends Port

## 0x800D87D0
static func ftPhysicsSetGroundVelTransferAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.physics.vel_air.x = ((fp.lr * fp.coll_data.floor_angle.y * fp.physics.vel_ground.x) + fp.physics.vel_jostle_x)
	fp.physics.vel_air.y = (fp.lr * -fp.coll_data.floor_angle.x * fp.physics.vel_ground.x)
	fp.physics.vel_air.z = fp.physics.vel_jostle_z

	if (
		((fp.physics.vel_jostle_z > 0.0) and
		(DObjGetStruct(fighter_gobj).translate.z < 0.0) and
		((DObjGetStruct(fighter_gobj).translate.z + fp.physics.vel_air.z) > 0.0)) or
		((fp.physics.vel_air.z < 0.0) and
		(DObjGetStruct(fighter_gobj).translate.z > 0.0) and
		((DObjGetStruct(fighter_gobj).translate.z + fp.physics.vel_air.z) < 0.0))
	):
		fp.physics.vel_air.z = -DObjGetStruct(fighter_gobj).translate.z
	if (fp.physics.vel_air.z > 0.0) and ((DObjGetStruct(fighter_gobj).translate.z + fp.physics.vel_air.z) > 60.0):
		fp.physics.vel_air.z = (60.0 - DObjGetStruct(fighter_gobj).translate.z)
	elif fp.physics.vel_air.z < 0.0:
		if (DObjGetStruct(fighter_gobj).translate.z + fp.physics.vel_air.z) < -60.0:
			fp.physics.vel_air.z = (-60.0 - DObjGetStruct(fighter_gobj).translate.z)
	fp.physics.vel_air.z += fp.physics.vel_ground.z

## 0x800D8938
static func ftPhysicsClampGroundVel(fp: Fighter, clamp_: float) -> void:
	if fp.physics.vel_ground.x < -clamp_:
		fp.physics.vel_ground.x = -clamp_
	elif fp.physics.vel_ground.x > clamp_:
		fp.physics.vel_ground.x = clamp_

## 0x800D8978
static func ftPhysicsSetGroundVelFriction(fp: Fighter, friction: float) -> void:
	if fp.physics.vel_ground.x < 0.0:
		fp.physics.vel_ground.x += friction

		if fp.physics.vel_ground.x > 0.0:
			fp.physics.vel_ground.x = 0.0
	else:
		fp.physics.vel_ground.x -= friction

		if fp.physics.vel_ground.x < 0.0:
			fp.physics.vel_ground.x = 0.0

## 0x800D89E0
static func ftPhysicsApplyClampGroundVelStickRange(fp: Fighter, stick_x_min: int, vel: float, clamp_: float) -> void:
	if ABS(fp.input.pl.stick_range.x) >= stick_x_min:
		fp.physics.vel_ground.x += (fp.input.pl.stick_range.x * vel * fp.lr)

		if fp.physics.vel_ground.x < -clamp_:
			fp.physics.vel_ground.x = -clamp_
		elif fp.physics.vel_ground.x > clamp_:
			fp.physics.vel_ground.x = clamp_

## 0x800D8A70
static func ftPhysicsSetGroundVelAbsStickRange(fp: Fighter, vel: float, friction: float) -> void:
	var v: float = ABS(fp.input.pl.stick_range.x) * vel

	if fp.physics.vel_ground.x < v:
		fp.physics.vel_ground.x = v
	else:
		fp.physics.vel_ground.x -= friction

		if fp.physics.vel_ground.x < v:
			fp.physics.vel_ground.x = v

## 0x800D8ADC
static func ftPhysicsSetGroundVelStickRange(fp: Fighter, vel: float, friction: float) -> void:
	var v: float = fp.input.pl.stick_range.x * vel * fp.lr

	if fp.physics.vel_ground.x >= 0.0:
		if fp.physics.vel_ground.x < v:
			fp.physics.vel_ground.x = v
		else:
			fp.physics.vel_ground.x -= friction

			if fp.physics.vel_ground.x < v:
				fp.physics.vel_ground.x = v
	else:
		if fp.physics.vel_ground.x > v:
			fp.physics.vel_ground.x = v
		else:
			fp.physics.vel_ground.x += friction

			if v < fp.physics.vel_ground.x:
				fp.physics.vel_ground.x = v

## 0x800D8B94
static func ftPhysicsApplyGroundVelTransferAir(fighter_gobj) -> void:
	ftPhysicsSetGroundVelTransferAir(fighter_gobj)

## 0x800D8BB4
static func ftPhysicsApplyGroundVelFriction(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	ftPhysicsSetGroundVelFriction(fp, Mpcollision.dMPCollisionMaterialFrictions[fp.coll_data.floor_flags & MAP_VERTEX_MAT_MASK] * attr.traction)
	ftPhysicsSetGroundVelTransferAir(fighter_gobj)

## 0x800D8C14
static func ftPhysicsApplyGroundVelTransN(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.physics.vel_ground.x = ((fp.joints[nFTPartsJointTransN].translate.z - fp.anim_vel.z) * DObjGetStruct(fighter_gobj).scale.z)
	fp.physics.vel_ground.z = ((fp.joints[nFTPartsJointTransN].translate.x - fp.anim_vel.x) * -fp.lr * DObjGetStruct(fighter_gobj).scale.x)

	if (fp.lr * DObjGetStruct(fighter_gobj).rotate.y) < 0.0:
		fp.physics.vel_ground.x = -fp.physics.vel_ground.x
		fp.physics.vel_ground.z = -fp.physics.vel_ground.z
	ftPhysicsSetGroundVelTransferAir(fighter_gobj)

## 0x800D8CCC
static func ftPhysicsApplyGroundFrictionOrTransN(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.anim_flag_use_transn_joint():     # fp->anim_desc.flags.is_use_transn_joint
		ftPhysicsApplyGroundVelTransN(fighter_gobj)
	else:
		ftPhysicsApplyGroundVelFriction(fighter_gobj)

## 0x800D8D10
static func ftPhysicsClampAirVelY(fp: Fighter, clamp_: float) -> void:
	if fp.physics.vel_air.y > clamp_:
		fp.physics.vel_air.y = clamp_

## 0x800D8D34
static func ftPhysicsAddClampAirVelY(fp: Fighter, vel: float, clamp_: float) -> void:
	fp.physics.vel_air.y += vel

	if fp.physics.vel_air.y > clamp_:
		fp.physics.vel_air.y = clamp_

## 0x800D8D68
static func ftPhysicsApplyGravityClampTVel(fp: Fighter, gravity: float, tvel: float) -> void:
	fp.physics.vel_air.y -= gravity

	if fp.physics.vel_air.y < -tvel:
		fp.physics.vel_air.y = -tvel

## 0x800D8DA0
static func ftPhysicsApplyFastFall(fp: Fighter, attr) -> void:
	fp.physics.vel_air.y = -attr.tvel_fast

## 0x800D8DB0
static func ftPhysicsCheckSetFastFall(fp: Fighter) -> void:
	if (fp.is_fastfall == FALSE) and (fp.physics.vel_air.y < 0.0) and (fp.input.pl.stick_range.y <= FTCOMMON_FASTFALL_STICK_RANGE_MIN) and (fp.tap_stick_y < FTCOMMON_FASTFALL_BUFFER_TICS_MAX):
		fp.is_fastfall = TRUE

		fp.tap_stick_y = FTINPUT_STICKBUFFER_TICS_MAX

		if Ftparam.ftParamCheckSetFighterColAnimID(fp.fighter_gobj, nGMColAnimFighterFastFall, 0) != FALSE:
			Ftmain.ftMainRunUpdateColAnim(fp.fighter_gobj)

## 0x800D8E50
static func ftPhysicsApplyGravityDefault(fp: Fighter, attr) -> void:
	ftPhysicsApplyGravityClampTVel(fp, attr.gravity, attr.tvel_base)

## 0x800D8E78
static func ftPhysicsClampAirVelX(fp: Fighter, clamp_: float) -> void:
	if fp.physics.vel_air.x < -clamp_:
		fp.physics.vel_air.x = -clamp_
	elif fp.physics.vel_air.x > clamp_:
		fp.physics.vel_air.x = clamp_

## 0x800D8EB8
static func ftPhysicsClampAirVelXMax(fp: Fighter) -> void:
	ftPhysicsClampAirVelX(fp, fp.attr.air_speed_max_x)

## 0x800D8EDC
static func ftPhysicsCheckClampAirVelXDec(fp: Fighter, clamp_: float) -> int:
	if ABSF(fp.physics.vel_air.x) > clamp_:
		fp.physics.vel_air.x += (-1.0 if (fp.physics.vel_air.x >= 0.0) else 1.0)

		if ABSF(fp.physics.vel_air.x) < clamp_:
			if fp.physics.vel_air.x >= 0.0:
				fp.physics.vel_air.x = clamp_
			else:
				fp.physics.vel_air.x = -clamp_
		return TRUE
	else:
		return FALSE

## 0x800D8FA8
static func ftPhysicsCheckClampAirVelXDecMax(fp: Fighter, attr) -> int:
	return ftPhysicsCheckClampAirVelXDec(fp, attr.air_speed_max_x)

## 0x800D8FC8
static func ftPhysicsClampAirVelXStickRange(fp: Fighter, stick_range_min: int, vel: float, clamp_: float) -> void:
	if ABS(fp.input.pl.stick_range.x) >= stick_range_min:
		fp.physics.vel_air.x += (fp.input.pl.stick_range.x * vel)

		if fp.physics.vel_air.x < -clamp_:
			fp.physics.vel_air.x = -clamp_
		elif fp.physics.vel_air.x > clamp_:
			fp.physics.vel_air.x = clamp_

## 0x800D9044
static func ftPhysicsClampAirVelXStickDefault(fp: Fighter, attr) -> void:
	ftPhysicsClampAirVelXStickRange(fp, FTPHYSICS_AIRDRIFT_CLAMP_RANGE_MIN, attr.air_accel, attr.air_speed_max_x)

## 0x800D9074
static func ftPhysicsApplyAirVelXFriction(fp: Fighter, attr) -> void:
	if fp.physics.vel_air.x < 0.0:
		fp.physics.vel_air.x += attr.air_friction

		if fp.physics.vel_air.x >= 0.0:
			fp.physics.vel_air.x = 0.0
	else:
		fp.physics.vel_air.x -= attr.air_friction

		if fp.physics.vel_air.x <= 0.0:
			fp.physics.vel_air.x = 0.0

## 0x800D90E0
static func ftPhysicsApplyAirVelDrift(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if fp.is_fastfall:
		ftPhysicsApplyFastFall(fp, attr)
	else:
		ftPhysicsApplyGravityDefault(fp, attr)

	if ftPhysicsCheckClampAirVelXDecMax(fp, attr) == FALSE:
		ftPhysicsClampAirVelXStickDefault(fp, attr)
		ftPhysicsApplyAirVelXFriction(fp, attr)

## 0x800D9160
static func ftPhysicsApplyAirVelDriftFastFall(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	ftPhysicsCheckSetFastFall(fp)

	if fp.is_fastfall:
		ftPhysicsApplyFastFall(fp, attr)
	else:
		ftPhysicsApplyGravityDefault(fp, attr)

	if ftPhysicsCheckClampAirVelXDecMax(fp, attr) == FALSE:
		ftPhysicsClampAirVelXStickDefault(fp, attr)
		ftPhysicsApplyAirVelXFriction(fp, attr)

## 0x800D91EC
static func ftPhysicsApplyAirVelFriction(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if fp.is_fastfall:
		ftPhysicsApplyFastFall(fp, attr)
	else:
		ftPhysicsApplyGravityDefault(fp, attr)

	if ftPhysicsCheckClampAirVelXDecMax(fp, attr) == FALSE:
		ftPhysicsApplyAirVelXFriction(fp, attr)

## 0x800D9260 - Ness / Yoshi double jump physics
## C: void (FTStruct *fp, f32 *z, f32 *y, f32 *x) -> returns {"z", "y", "x"}.
static func ftPhysicsGetAirVelTransN(fp: Fighter) -> Dictionary:
	var topn_joint: DObj = fp.joints[nFTPartsJointTopN]
	var transn_joint: DObj = fp.joints[nFTPartsJointTransN]
	var anim_vel_z: float = (transn_joint.translate.z - fp.anim_vel.z) * fp.lr * topn_joint.scale.z
	var anim_vel_y: float = (transn_joint.translate.y - fp.anim_vel.y) * topn_joint.scale.y
	var cos_: float = cosf(transn_joint.rotate.z)
	var sin_: float = __sinf(transn_joint.rotate.z)
	var z: float
	var y: float
	var x: float

	z = (anim_vel_z * cos_) - (anim_vel_y * sin_)
	y = (anim_vel_z * sin_) + (anim_vel_y * cos_)
	x = (transn_joint.translate.x - fp.anim_vel.x) * -fp.lr * topn_joint.scale.x

	return {"z": z, "y": y, "x": x}

## 0x800D938C
static func ftPhysicsSetAirVelTransN(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var topn_joint: DObj = fp.joints[nFTPartsJointTopN]
	var transn_joint: DObj = fp.joints[nFTPartsJointTransN]

	fp.physics.vel_air.x = (transn_joint.translate.x - fp.anim_vel.x) * topn_joint.scale.x
	fp.physics.vel_air.y = (transn_joint.translate.y - fp.anim_vel.y) * topn_joint.scale.y
	fp.physics.vel_air.z = (transn_joint.translate.z - fp.anim_vel.z) * topn_joint.scale.z

## 0x800D93E4
static func ftPhysicsApplyAirVelTransNAll(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	# ftPhysicsGetAirVelTransN(fp, &vel_air.x, &vel_air.y, &vel_air.z): z -> vel_air.x, y -> vel_air.y, x -> vel_air.z
	var r := ftPhysicsGetAirVelTransN(fp)
	fp.physics.vel_air.x = r.z
	fp.physics.vel_air.y = r.y
	fp.physics.vel_air.z = r.x

## 0x800D9414
static func ftPhysicsApplyAirVelTransNYZ(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	# ftPhysicsGetAirVelTransN(fp, NULL, &vel_air.y, &vel_air.z): y -> vel_air.y, x -> vel_air.z
	var r := ftPhysicsGetAirVelTransN(fp)
	fp.physics.vel_air.y = r.y
	fp.physics.vel_air.z = r.x

## 0x800D9444
static func ftPhysicsStopVelAll(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.physics.vel_air.x = 0.0
	fp.physics.vel_air.y = 0.0
	fp.physics.vel_air.z = 0.0

	fp.physics.vel_ground.x = 0.0
	fp.physics.vel_ground.y = 0.0
	fp.physics.vel_ground.z = 0.0

	fp.physics.vel_damage_air.x = 0.0
	fp.physics.vel_damage_air.y = 0.0
	fp.physics.vel_damage_air.z = 0.0

	fp.physics.vel_damage_ground = 0.0
