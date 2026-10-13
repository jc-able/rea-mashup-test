## 1:1 port of src/ft/ftcommon/ftcommonwalldamage.c (ssb-decomp-re): wall / ceiling bounce while tumbling.
class_name Ftcommonwalldamage
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80141AC0
static func ftCommonWallDamageProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftcommondamage.ftCommonDamageUpdateDustEffect(fighter_gobj)
	Ftcommondamage.ftCommonDamageDecHitStunSetPublic(fighter_gobj)

	if fp.status_vars.common.damage.hitstun_tics == 0:
		Ftcommondamagefall.ftCommonDamageFallSetStatusFromDamage(fighter_gobj)

## 0x80141B08 - angle and pos are read-only Vec3f* inputs
static func ftCommonWallDamageSetStatus(fighter_gobj, angle: Vector3, pos: Vector3) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var vel_air: Vector3
	var knockback: float

	Efmanager.efManagerImpactWaveMakeEffect(pos, SYVECTOR_AXIS_Z, syUtilsArcTan2(-angle.x, angle.y))
	Efmanager.efManagerQuakeMakeEffect(2)

	vel_air = fp.physics.vel_air

	# lbCommonAdd2D / lbCommonReflect2D / lbCommonScale2D update their first Vec3f* argument in place
	# (and return it); the port returns the updated vector.
	vel_air = Lbcommon.lbCommonAdd2D(vel_air, fp.physics.vel_damage_air)
	vel_air = Lbcommon.lbCommonReflect2D(vel_air, angle)
	vel_air = Lbcommon.lbCommonScale2D(vel_air, 0.800000011920929) # 0.8F

	fp.physics.vel_damage_air = vel_air

	fp.physics.vel_air.x = 0.0
	fp.physics.vel_air.y = 0.0
	fp.physics.vel_air.z = 0.0

	fp.lr = +1 if (fp.physics.vel_damage_air.x < 0.0) else -1

	knockback = f32(Lbcommon.lbCommonMag2D(vel_air)) # f32 local

	fp.status_vars.common.damage.hitstun_tics = int(f32(Ftparam.ftParamGetHitStun(knockback))) # f32 -> s32 (truncation)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusWallDamage, 0.0, 2.0, (FTSTATUS_PRESERVE_DAMAGEPLAYER | FTSTATUS_PRESERVE_PLAYERTAG))

	fp.damage_knockback_stack = knockback

	Ftparam.ftParamMakeRumble(fp, 2, 0)

	Ftparam.ftParamSetTimedHitStatusIntangible(fp, FTCOMMON_WALLDAMAGE_INTANGIBLE_TIMER)

	fp.is_hitstun = FALSE

## 0x80141C6C
static func ftCommonWallDamageCheckGoto(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3

	pos.x = DObjGetStruct(fighter_gobj).translate.x
	pos.y = DObjGetStruct(fighter_gobj).translate.y
	pos.z = 0.0

	if fp.status_vars.common.damage.coll_mask_curr & MAP_FLAG_LWALL:
		pos.x += fp.coll_data.map_coll.width
		pos.y += fp.coll_data.map_coll.center

		ftCommonWallDamageSetStatus(fighter_gobj, fp.coll_data.lwall_angle, pos)

		return TRUE
	elif fp.status_vars.common.damage.coll_mask_curr & MAP_FLAG_RWALL:
		pos.x -= fp.coll_data.map_coll.width
		pos.y += fp.coll_data.map_coll.center

		ftCommonWallDamageSetStatus(fighter_gobj, fp.coll_data.rwall_angle, pos)

		return TRUE
	elif fp.status_vars.common.damage.coll_mask_curr & MAP_FLAG_CEIL:
		pos.y += fp.coll_data.map_coll.top

		ftCommonWallDamageSetStatus(fighter_gobj, fp.coll_data.ceil_angle, pos)

		return TRUE
	else:
		return FALSE
