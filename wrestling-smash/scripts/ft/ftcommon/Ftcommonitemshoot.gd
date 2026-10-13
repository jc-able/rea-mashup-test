## 1:1 port of src/ft/ftcommon/ftcommonitemshoot.c (ssb-decomp-re): firing a held shooting item
## (Ray Gun = LGun, Fire Flower), ground and air variants.
class_name Ftcommonitemshoot
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80146FB0
static func ftCommonLGunShootProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Mpcommon, &"mpCommonSetFighterWaitOrFall"))

## 0x80146FD4
static func ftCommonLGunShootProcAccessory(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var ip: Item
	var size_mul: float

	if (fp.item_gobj != null) and (fp.motion_vars.flags.flag0 != 0):
		ip = itGetStruct(fp.item_gobj)

		if ip.multi != 0:
			# 0x80188660
			var make_ammo_offset := Vector3(0.0, 60.0, 180.0)
			var make_effect_offset: Vector3

			size_mul = 1.0 / fp.attr.size

			make_ammo_offset.x *= size_mul
			make_ammo_offset.y *= size_mul
			make_ammo_offset.z *= size_mul

			make_ammo_offset = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[fp.attr.joint_itemlight_id], make_ammo_offset)
			Itlgun.itLGunMakeAmmo(fighter_gobj, make_ammo_offset)

			make_effect_offset.x = 0.0
			make_effect_offset.y = 60.0
			make_effect_offset.z = 180.0

			# C passes NULL for effect_scatter == zero scatter
			Ftparam.ftParamMakeEffect(fighter_gobj, nEFKindSparkleWhiteScale, fp.attr.joint_itemlight_id, make_effect_offset, Vector3.ZERO, fp.lr, TRUE, FALSE)

			make_effect_offset.x = 0.0
			make_effect_offset.y = 0.0
			make_effect_offset.z = -180.0

			Ftparam.ftParamMakeEffect(fighter_gobj, nEFKindDustDashSmall, nFTPartsJointTopN, make_effect_offset, Vector3.ZERO, fp.lr, FALSE, FALSE)

			Snd.func_800269C0_275C0(nSYAudioFGMLGunShoot)
			Ftparam.ftParamMakeRumble(fp, 9, 0)
		else:
			# 0x8018866C
			var dust_effect_offset := Vector3(FTCOMMON_LGUNSHOOT_AMMO_SPAWN_OFF_X, FTCOMMON_LGUNSHOOT_AMMO_SPAWN_OFF_Y, FTCOMMON_LGUNSHOOT_AMMO_SPAWN_OFF_Z)

			Ftparam.ftParamMakeEffect(fighter_gobj, nEFKindDustLight, fp.attr.joint_itemlight_id, dust_effect_offset, Vector3.ZERO, -fp.lr, TRUE, FALSE)
			Snd.func_800269C0_275C0(nSYAudioFGMLGunEmpty)

		fp.motion_vars.flags.flag0 = 0

## 0x801471C0
static func ftCommonLGunShootProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftcommonitemshoot, &"ftCommonLGunShootSwitchStatusAir"))

## 0x801471E4
static func ftCommonLGunShootAirProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftcommonitemshoot, &"ftCommonLGunShootAirSwitchStatusGround"))

## 0x80147208
static func ftCommonLGunShootAirSwitchStatusGround(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusLGunShoot, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.proc_accessory = Callable(Ftcommonitemshoot, &"ftCommonLGunShootProcAccessory")

## 0x80147258
static func ftCommonLGunShootSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusLGunShootAir, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

	fp.proc_accessory = Callable(Ftcommonitemshoot, &"ftCommonLGunShootProcAccessory")

## 0x801472B0
static func ftCommonFireFlowerShootProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Mpcommon, &"mpCommonSetFighterWaitOrFall"))

## 0x801472D4
static func ftCommonFireFlowerShootUpdateAmmoStats(fp, ammo_sub) -> void:
	var ip := itGetStruct(fp.item_gobj)

	# 0x80188678
	var make_flame_offset := Vector3(60.0, 100.0, 0.0)

	var size_mul: float
	var flame_vel_index: int

	if ip.multi >= ammo_sub:
		size_mul = 1.0 / fp.attr.size

		make_flame_offset.x *= size_mul
		make_flame_offset.y *= size_mul
		make_flame_offset.z *= size_mul

		make_flame_offset = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[fp.attr.joint_itemlight_id], make_flame_offset)

		if fp.status_vars.common.fireflower.flame_vel_index >= FTCOMMON_FIREFLOWERSHOOT_AMMO_INDEX_LOOP:
			flame_vel_index = FTCOMMON_FIREFLOWERSHOOT_AMMO_INDEX_MAX - fp.status_vars.common.fireflower.flame_vel_index
		else:
			flame_vel_index = fp.status_vars.common.fireflower.flame_vel_index

		Itfflower.itFFlowerShootFlame(fp.fighter_gobj, make_flame_offset, flame_vel_index, ammo_sub)
		Ftparam.ftParamMakeRumble(fp, 6, 0)
	fp.status_vars.common.fireflower.ammo_fire_count += 1

	if fp.status_vars.common.fireflower.ammo_fire_count > (U16_MAX + 1):
		fp.status_vars.common.fireflower.ammo_fire_count = (U16_MAX + 1)
	fp.status_vars.common.fireflower.flame_vel_index += 1

	if fp.status_vars.common.fireflower.flame_vel_index >= FTCOMMON_FIREFLOWERSHOOT_AMMO_INDEX_MAX:
		fp.status_vars.common.fireflower.flame_vel_index = 0

		Ftparam.ftParamSetMotionID(fp, nFTMotionAttackIDFireFlowerShoot)
		Ftparam.ftParamSetStatUpdate(fp, fp.stat_flags.halfword)
		Ftparam.ftParamUpdate1PGameAttackStats(fp, 0)

## 0x80147434
static func ftCommonFireFlowerShootProcAccessory(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var ip: Item
	var ammo_sub: int

	if not (fp.input.pl.button_hold & fp.input.button_mask_a):
		fp.status_vars.common.fireflower.is_release = TRUE
	if fp.status_vars.common.fireflower.release_lag < FTCOMMON_FIREFLOWERSHOOT_RELEASE_LAG:
		fp.status_vars.common.fireflower.release_lag += 1
	if (fp.status_vars.common.fireflower.release_lag < FTCOMMON_FIREFLOWERSHOOT_RELEASE_LAG) and (fp.input.pl.button_tap & fp.input.button_mask_a):
		fp.status_vars.common.fireflower.release_lag = 0
	if fp.item_gobj != null:
		if fp.motion_vars.flags.flag0 != 0:
			ip = itGetStruct(fp.item_gobj)

			ammo_sub = 2 if (fp.status_vars.common.fireflower.ammo_fire_count == 0) else 1

			fp.status_vars.common.fireflower.effect_make_int -= 1

			if fp.status_vars.common.fireflower.effect_make_int == 0:
				fp.status_vars.common.fireflower.effect_make_int = FTCOMMON_FIREFLOWERSHOOT_EFFECT_SPAWN_INT

				if ip.multi < ammo_sub:
					# 0x80188684
					var effect_noammo_offset := Vector3(60.0, 100.0, 0.0)

					Ftparam.ftParamMakeEffect(fighter_gobj, nEFKindDustLight, fp.attr.joint_itemlight_id, effect_noammo_offset, Vector3.ZERO, -fp.lr, TRUE, FALSE)
					Snd.func_800269C0_275C0(nSYAudioFGMFireFlowerBurn)
				else:
					# 0x80188690
					var effect_haveammo_offset := Vector3(0.0, 0.0, -180.0)

					Ftparam.ftParamMakeEffect(fighter_gobj, nEFKindDustLight, nFTPartsJointTopN, effect_haveammo_offset, Vector3.ZERO, fp.lr, FALSE, FALSE)
					Snd.func_800269C0_275C0(nSYAudioFGMBurnE)
			fp.status_vars.common.fireflower.ammo_sub -= 1

			if fp.status_vars.common.fireflower.ammo_sub == 0:
				fp.status_vars.common.fireflower.ammo_sub = FTCOMMON_FIREFLOWERSHOOT_AMMO_INDEX_MAX

				ftCommonFireFlowerShootUpdateAmmoStats(fp, ammo_sub)
			if fp.motion_vars.flags.flag0 == 1:
				if ip.multi >= ammo_sub:
					# 0x8018869C
					var effect_spark_offset := Vector3(0.0, 80.0, 0.0)

					# 0x801886A8
					var effect_spark_scatter := Vector3(90.0, 90.0, 90.0)

					# 0x801886B4
					var effect_dust_offset := Vector3(0.0, 0.0, -180.0)

					Ftparam.ftParamMakeEffect(fighter_gobj, nEFKindSparkleWhiteScale, fp.attr.joint_itemlight_id, effect_spark_offset, effect_spark_scatter, fp.lr, TRUE, FALSE)
					Ftparam.ftParamMakeEffect(fighter_gobj, nEFKindDustDashSmall, nFTPartsJointTopN, effect_dust_offset, Vector3.ZERO, fp.lr, FALSE, FALSE)
				fp.motion_vars.flags.flag0 = 2

				ObjAnim.gcSetAnimSpeed(fighter_gobj, 0.0)
		if (fp.status_vars.common.fireflower.ammo_fire_count >= 5) and (fp.status_vars.common.fireflower.is_release != FALSE) and (fp.status_vars.common.fireflower.release_lag >= 20):
			fp.motion_vars.flags.flag0 = 0

			ObjAnim.gcSetAnimSpeed(fighter_gobj, 1.0)

## 0x8014772C
static func ftCommonFireFlowerShootProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftcommonitemshoot, &"ftCommonFireFlowerShootSwitchStatusAir"))

## 0x80147750
static func ftCommonFireFlowerShootAirProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftcommonitemshoot, &"ftCommonFireFlowerShootAirSwitchStatusGround"))

## 0x80147774
static func ftCommonFireFlowerShootAirSwitchStatusGround(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusFireFlowerShoot, fighter_gobj.anim_frame, DObjGetStruct(fighter_gobj).anim_speed, FTSTATUS_PRESERVE_NONE)

	fp.proc_accessory = Callable(Ftcommonitemshoot, &"ftCommonFireFlowerShootProcAccessory")

## 0x801477C8
static func ftCommonFireFlowerShootSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusFireFlowerShootAir, fighter_gobj.anim_frame, DObjGetStruct(fighter_gobj).anim_speed, FTSTATUS_PRESERVE_NONE)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

	fp.proc_accessory = Callable(Ftcommonitemshoot, &"ftCommonFireFlowerShootProcAccessory")

## 0x80147824
static func ftCommonFireFlowerShootInitStatusVars(fp) -> void:
	fp.status_vars.common.fireflower.flame_vel_index = 0
	fp.status_vars.common.fireflower.ammo_sub = 1
	fp.status_vars.common.fireflower.effect_make_int = 1
	fp.status_vars.common.fireflower.ammo_fire_count = 0
	fp.status_vars.common.fireflower.is_release = FALSE
	fp.status_vars.common.fireflower.release_lag = 0

## 0x80147844
static func ftCommonItemShootSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var ip := itGetStruct(fp.item_gobj)
	var status_id: int = 0                      # C: left uninitialized for other item kinds
	var proc_accessory: Callable = Callable()   # C: left uninitialized for other item kinds

	match ip.kind:
		nITKindLGun:
			status_id = nFTCommonStatusLGunShoot
			proc_accessory = Callable(Ftcommonitemshoot, &"ftCommonLGunShootProcAccessory")

		nITKindFFlower:
			status_id = nFTCommonStatusFireFlowerShoot
			proc_accessory = Callable(Ftcommonitemshoot, &"ftCommonFireFlowerShootProcAccessory")

	fp.motion_vars.flags.flag0 = 0

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.proc_accessory = proc_accessory

	ftCommonFireFlowerShootInitStatusVars(fp)

## 0x801478EC
static func ftCommonItemShootAirSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var ip := itGetStruct(fp.item_gobj)
	var status_id: int = 0                      # C: left uninitialized for other item kinds
	var proc_accessory: Callable = Callable()   # C: left uninitialized for other item kinds

	match ip.kind:
		nITKindLGun:
			status_id = nFTCommonStatusLGunShootAir
			proc_accessory = Callable(Ftcommonitemshoot, &"ftCommonLGunShootProcAccessory")

		nITKindFFlower:
			status_id = nFTCommonStatusFireFlowerShootAir
			proc_accessory = Callable(Ftcommonitemshoot, &"ftCommonFireFlowerShootProcAccessory")

	fp.motion_vars.flags.flag0 = 0

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.proc_accessory = proc_accessory

	Ftphysics.ftPhysicsClampAirVelXMax(fp)
	ftCommonFireFlowerShootInitStatusVars(fp)
