## 1:1 port of src/ft/ftcommon/ftcommonget.c (ssb-decomp-re): item pickup (LightGet / HeavyGet),
## consumable item effects, and holding a heavy item (LiftWait / LiftTurn).
class_name Ftcommonget
extends Port

# // //// // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80145990
static func ftCommonGetFindItem(fighter_gobj, pickup_mask):
	var fp := ftGetStruct(fighter_gobj)
	var pickup_gobj = null
	var item_pickup = fp.attr.item_pickup
	var closest_item_dist: float = F32_MAX
	var is_pickup: int
	var current_item_dist: float
	var pickup_range: Vector2

	# item_gobj = gGCCommonLinks[nGCCommonLinkIDItem]; ...; item_gobj = item_gobj->link_next
	for item_gobj in Sim.get_link(nGCCommonLinkIDItem):
		var ip := itGetStruct(item_gobj)

		if B(ip.is_allow_pickup):
			if fp.coll_data.floor_line_id == ip.coll_data.floor_line_id:
				var ft_translate: Vector3 = DObjGetStruct(fighter_gobj).translate
				var it_translate: Vector3 = DObjGetStruct(item_gobj).translate
				var map_coll: MPObjectColl = ip.coll_data.map_coll

				is_pickup = FALSE

				if (ip.weight == nITWeightLight) and (pickup_mask & FTCOMMON_GET_MASK_LIGHT):
					pickup_range.x = ft_translate.x + (fp.lr * item_pickup.pickup_offset_light.x)
					pickup_range.y = ft_translate.y + item_pickup.pickup_offset_light.y

					if (((pickup_range.x - item_pickup.pickup_range_light.x) - map_coll.width) < it_translate.x) and (it_translate.x < (item_pickup.pickup_range_light.x + pickup_range.x + map_coll.width)):
						if (((pickup_range.y - item_pickup.pickup_range_light.y) - map_coll.top) < it_translate.y) and (it_translate.y < ((item_pickup.pickup_range_light.y + pickup_range.y) - map_coll.bottom)):
							is_pickup = TRUE
				if (ip.weight == nITWeightHeavy) and (pickup_mask & FTCOMMON_GET_MASK_HEAVY):
					pickup_range.x = ft_translate.x + (fp.lr * item_pickup.pickup_offset_heavy.x)
					pickup_range.y = ft_translate.y + item_pickup.pickup_offset_heavy.y

					if (((pickup_range.x - item_pickup.pickup_range_heavy.x) - map_coll.width) < it_translate.x) and (it_translate.x < (item_pickup.pickup_range_heavy.x + pickup_range.x + map_coll.width)):
						if (((pickup_range.y - item_pickup.pickup_range_heavy.y) - map_coll.top) < it_translate.y) and (it_translate.y < ((item_pickup.pickup_range_heavy.y + pickup_range.y) - map_coll.bottom)):
							is_pickup = TRUE
				if is_pickup != FALSE:
					current_item_dist = -(pickup_range.x - it_translate.x) if (pickup_range.x < it_translate.x) else (pickup_range.x - it_translate.x)

					if current_item_dist < closest_item_dist:
						closest_item_dist = current_item_dist
						pickup_gobj = item_gobj
	return pickup_gobj

## 0x80145BE4
static func ftCommonLightGetProcDamage(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var item_gobj = fp.item_gobj

	if item_gobj != null:
		var ip := itGetStruct(item_gobj)

		if ip.type == nITTypeConsume:
			match ip.kind:
				nITKindTomato:
					Ftparam.ftParamSetHealDamage(fp, ITTOMATO_DAMAGE_HEAL)
					Itmain.itMainDestroyItem(item_gobj)

					if (G.gSCManagerBattleState.game_type == nSCBattleGameType1PGame) and (fp.player == G.gSCManagerSceneData.player) and (G.gSC1PGameBonusTomatoCount < U8_MAX):
						G.gSC1PGameBonusTomatoCount += 1

				nITKindHeart:
					Ftparam.ftParamSetHealDamage(fp, ITHEART_DAMAGE_HEAL)
					Itmain.itMainDestroyItem(item_gobj)

					if (G.gSCManagerBattleState.game_type == nSCBattleGameType1PGame) and (fp.player == G.gSCManagerSceneData.player) and (G.gSC1PGameBonusHeartCount < U8_MAX):
						G.gSC1PGameBonusHeartCount += 1

				nITKindHammer:
					fp.hammer_tics = ITHAMMER_TIME

					Ftparam.ftParamTryPlayItemMusic(nSYAudioBGMHammer)

				_:
					pass

## 0x80145D28
static func ftCommonHeavyGetProcDamage(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.item_gobj != null:
		Itmain.itMainSetFighterDrop(fp.item_gobj, Vector3.ZERO, 1.0)    # ftSetupDropItem(fp)

## 0x80145D70
static func ftCommonGetProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var item_gobj

	if fp.motion_vars.flags.flag1 != 0:
		fp.motion_vars.flags.flag1 = 0

		item_gobj = ftCommonGetFindItem(fighter_gobj, FTCOMMON_GET_MASK_HEAVY if (fp.status_id == nFTCommonStatusHeavyGet) else FTCOMMON_GET_MASK_LIGHT)

		if item_gobj != null:
			Itmain.itMainSetFighterHold(item_gobj, fighter_gobj)
	if fighter_gobj.anim_frame <= 0.0:
		if fp.status_id == nFTCommonStatusHeavyGet:
			if fp.item_gobj != null:
				if (fp.fkind == nFTKindDonkey) or (fp.fkind == nFTKindNDonkey) or (fp.fkind == nFTKindGDonkey):
					Ftdonkeythrowfwait.ftDonkeyThrowFWaitSetStatus(fighter_gobj)
				else:
					ftCommonLiftWaitSetStatus(fighter_gobj)
			else:
				Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)
		else:
			item_gobj = fp.item_gobj

			if item_gobj != null:
				var ip := itGetStruct(item_gobj)

				if ip.type == nITTypeConsume:
					ftCommonLightGetProcDamage(fighter_gobj)

					if ip.kind == nITKindHammer:
						Fthammer.ftHammerSetStatusHammerWait(fighter_gobj)

						return
			Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)

## 0x80145ED8
static func ftCommonLightGetProcMap(fighter_gobj) -> void:
	if not B(Mpcommon.mpCommonCheckFighterOnFloor(fighter_gobj)):
		ftCommonLightGetProcDamage(fighter_gobj)
		Ftcommonfall.ftCommonFallSetStatus(fighter_gobj)

## 0x80145F10
static func ftCommonHeavyGetProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if not B(Mpcommon.mpCommonCheckFighterOnFloor(fighter_gobj)):
		if fp.item_gobj != null:
			Itmain.itMainSetFighterDrop(fp.item_gobj, Vector3.ZERO, 1.0)    # ftSetupDropItem(fp)
		Ftcommonfall.ftCommonFallSetStatus(fighter_gobj)

## 0x80145F74
static func ftCommonHeavyThrowProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if not B(Mpcommon.mpCommonCheckFighterOnEdge(fighter_gobj)):
		if fp.item_gobj != null:
			Itmain.itMainSetFighterDrop(fp.item_gobj, Vector3.ZERO, 1.0)    # ftSetupDropItem(fp)
		Ftcommonfall.ftCommonFallSetStatus(fighter_gobj)

## 0x80145FD8
static func ftCommonGetSetStatus(fighter_gobj, item_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var ip := itGetStruct(item_gobj)

	fp.motion_vars.flags.flag1 = 0

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusHeavyGet if (ip.weight == nITWeightHeavy) else nFTCommonStatusLightGet, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	if fp.status_id == nFTCommonStatusHeavyGet:
		fp.proc_damage = Callable(Ftcommonget, &"ftCommonHeavyGetProcDamage")
	else:
		fp.proc_damage = Callable(Ftcommonget, &"ftCommonLightGetProcDamage")

## 0x80146064
static func ftCommonGetCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if fp.item_gobj == null:
		var item_gobj = ftCommonGetFindItem(fighter_gobj, (FTCOMMON_GET_MASK_LIGHT | FTCOMMON_GET_MASK_HEAVY))

		if item_gobj != null:
			ftCommonGetSetStatus(fighter_gobj, item_gobj)

			return TRUE
	return FALSE

## 0x801460B8
static func ftCommonLiftWaitProcInterrupt(fighter_gobj) -> void:
	if not B(Ftcommonitemthrow.ftCommonHeavyThrowCheckInterruptCommon(fighter_gobj)):
		ftCommonLiftTurnCheckInterruptLiftWait(fighter_gobj)

## 0x801460E8
static func ftCommonLiftWaitSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusLiftWait, 0.0, 1.0, FTSTATUS_PRESERVE_SLOPECONTOUR)

	fp.proc_damage = Callable(Ftcommonget, &"ftCommonHeavyGetProcDamage")

## 0x80146130
static func ftCommonLiftTurnUpdateModelYaw(fp) -> void:
	fp.status_vars.common.lift.turn_tics -= 1

	fp.joints[nFTPartsJointTopN].rotate.y += FTCOMMON_LIFT_TURN_STEP

	Ftparam.ftParamsUpdateFighterPartsTransformAll(fp.joints[nFTPartsJointTopN])

	if fp.status_vars.common.lift.turn_tics == (FTCOMMON_LIFT_TURN_FRAMES / 2):
		fp.lr = -fp.lr
		fp.physics.vel_ground.x = -fp.physics.vel_ground.x

## 0x801461A8
static func ftCommonLiftTurnProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftCommonLiftTurnUpdateModelYaw(fp)

	if fp.status_vars.common.lift.turn_tics == 0:
		ftCommonLiftWaitSetStatus(fighter_gobj)

## 0x801461E8
static func ftCommonLiftTurnProcInterrupt(fighter_gobj) -> void:
	Ftcommonitemthrow.ftCommonHeavyThrowCheckInterruptCommon(fighter_gobj)

## 0x80146208
static func ftCommonLiftTurnSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusLiftTurn, 0.0, 1.0, FTSTATUS_PRESERVE_SLOPECONTOUR)

	fp.proc_damage = Callable(Ftcommonget, &"ftCommonHeavyGetProcDamage")

	fp.status_vars.common.lift.turn_tics = FTCOMMON_LIFT_TURN_FRAMES

	ftCommonLiftTurnUpdateModelYaw(fp)

## 0x8014625C
static func ftCommonLiftTurnCheckInterruptLiftWait(fighter_gobj) -> int:
	if B(Ftcommonturn.ftCommonTurnCheckInputSuccess(fighter_gobj)):
		ftCommonLiftTurnSetStatus(fighter_gobj)

		return TRUE
	else:
		return FALSE
