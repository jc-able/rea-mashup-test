## 1:1 port of src/ft/ftcommon/ftcommonrebirth.c (ssb-decomp-re): respawn platform (RebirthDown /
## RebirthStand / RebirthWait).
class_name Ftcommonrebirth
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x80188490
static var dFTCommonRebirthOffsetsX: Array = [0.0, -1000.0, 1000.0, -2000.0]

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

## ftCommonGroundCheckInterrupt (src/ft/fighter.h): "Macro to check if a move has been interrupted
## by any standard action". Short-circuit || chain of `!= FALSE` tests, in the exact C order.
static func ftCommonGroundCheckInterrupt(fighter_gobj) -> bool:
	return (
		Ftcommonspecialn.ftCommonSpecialNCheckInterruptCommon(fighter_gobj) or
		Ftcommonspecialhi.ftCommonSpecialHiCheckInterruptCommon(fighter_gobj) or
		Ftcommonspeciallw.ftCommonSpecialLwCheckInterruptCommon(fighter_gobj) or
		Ftcommoncatch1.ftCommonCatchCheckInterruptCommon(fighter_gobj) or
		Ftcommonattacks4.ftCommonAttackS4CheckInterruptCommon(fighter_gobj) or
		Ftcommonattackhi4.ftCommonAttackHi4CheckInterruptCommon(fighter_gobj) or
		Ftcommonattacklw4.ftCommonAttackLw4CheckInterruptCommon(fighter_gobj) or
		Ftcommonattacks3.ftCommonAttackS3CheckInterruptCommon(fighter_gobj) or
		Ftcommonattackhi3.ftCommonAttackHi3CheckInterruptCommon(fighter_gobj) or
		Ftcommonattacklw3.ftCommonAttackLw3CheckInterruptCommon(fighter_gobj) or
		Ftcommonattack1.ftCommonAttack1CheckInterruptCommon(fighter_gobj) or
		Ftcommonguard1.ftCommonGuardOnCheckInterruptCommon(fighter_gobj) or
		Ftcommonappeal.ftCommonAppealCheckInterruptCommon(fighter_gobj) or
		Ftcommonkneebend.ftCommonKneeBendCheckInterruptCommon(fighter_gobj) or
		Ftcommondash.ftCommonDashCheckInterruptCommon(fighter_gobj) or
		Ftcommonpass.ftCommonPassCheckInterruptCommon(fighter_gobj) or
		Ftcommondokan.ftCommonDokanStartCheckInterruptCommon(fighter_gobj) or
		Ftcommonsquat.ftCommonSquatCheckInterruptCommon(fighter_gobj) or
		Ftcommonturn.ftCommonTurnCheckInterruptCommon(fighter_gobj) or
		Ftcommonwalk.ftCommonWalkCheckInterruptCommon(fighter_gobj)
	)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8013CF60
static func ftCommonRebirthDownSetStatus(this_gobj) -> void:
	var this_fp := ftGetStruct(this_gobj)
	var rebirth_vars: Dictionary = Ftmanager.default_desc() # FTDesc rebirth_vars = dFTManagerDefaultFighterDesc; (struct copy)
	var other_fp: Fighter
	var halo_number: int
	var halo_mapobj: int = 0 # C: uninitialized s32, written by mpCollisionGetMapObjIDsKind
	var halo_spawn_pos: Vector3

	rebirth_vars.lr = this_fp.lr
	rebirth_vars.damage = 0

	halo_mapobj = Mpcollision.mpCollisionGetMapObjIDsKind(nMPMapObjKindRebirth, halo_mapobj)
	halo_spawn_pos = Mpcollision.mpCollisionGetMapObjPositionID(halo_mapobj)

	halo_number = 0

	# loop: (C goto) - restart the scan from the head of the fighter link every time halo_number is
	# already used by another fighter on its respawn platform.
	var is_restart := true

	while is_restart:
		is_restart = false

		for other_gobj in Sim.get_link(nGCCommonLinkIDFighter):
			if other_gobj != this_gobj:
				other_fp = ftGetStruct(other_gobj)

				if (other_fp.status_id >= nFTCommonStatusRebirthDown) and (other_fp.status_id <= nFTCommonStatusRebirthWait):
					if halo_number == other_fp.status_vars.common.rebirth.halo_number:
						halo_number += 1

						is_restart = true
						break
				# else goto next_gobj
			# next_gobj: other_gobj = other_gobj->link_next

	rebirth_vars.pos.x = dFTCommonRebirthOffsetsX[halo_number] + halo_spawn_pos.x
	rebirth_vars.pos.y = Mpcollision.gMPCollisionGroundData.map_bound_top
	rebirth_vars.pos.z = 0.0

	Ftmanager.ftManagerInitFighter(this_gobj, rebirth_vars)
	Ifcommon.ifCommonPlayerDamageStopBreakAnim(this_fp)
	Mpcommon.mpCommonSetFighterGround(this_fp)

	this_fp.coll_data.floor_line_id = -2
	this_fp.coll_data.floor_flags = MAP_VERTEX_COLL_PASS
	this_fp.coll_data.floor_angle.y = 1.0
	this_fp.coll_data.floor_angle.x = 0.0
	this_fp.coll_data.floor_angle.z = 0.0

	Ftmain.ftMainSetStatus(this_gobj, nFTCommonStatusRebirthDown, 100.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(this_gobj)
	Ftphysics.ftPhysicsStopVelAll(this_gobj)

	this_fp.status_vars.common.rebirth.halo_lower_wait = FTCOMMON_REBIRTH_HALO_LOWER_WAIT
	this_fp.status_vars.common.rebirth.halo_despawn_wait = FTCOMMON_REBIRTH_HALO_DESPAWN_WAIT
	this_fp.status_vars.common.rebirth.pos = DObjGetStruct(this_gobj).translate
	this_fp.status_vars.common.rebirth.halo_offset.x = dFTCommonRebirthOffsetsX[halo_number] + halo_spawn_pos.x
	this_fp.status_vars.common.rebirth.halo_offset.y = halo_spawn_pos.y
	this_fp.status_vars.common.rebirth.halo_offset.z = 0.0

	this_fp.is_menu_ignore = TRUE
	this_fp.is_ghost = TRUE
	this_fp.is_shadow_hide = TRUE
	this_fp.is_rebirth = TRUE
	this_fp.camera_mode = nFTCameraModeGhost

	this_fp.status_vars.common.rebirth.halo_number = halo_number

	this_fp.camera_zoom_range = 0.6

	if Efmanager.efManagerRebirthHaloMakeEffect(this_gobj, this_fp.attr.halo_size) != null:
		this_fp.is_effect_attach = TRUE
	Ftparam.ftParamCheckSetFighterColAnimID(this_gobj, nGMColAnimFighterRebirth, 0)
	Ftparam.ftParamSetPlayerTagWait(this_gobj, 1)

## 0x8013D1D4
static func ftCommonRebirthCommonUpdateHaloWait(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.common.rebirth.halo_despawn_wait != 0:
		fp.status_vars.common.rebirth.halo_despawn_wait -= 1
	if fp.status_vars.common.rebirth.halo_lower_wait != 0:
		fp.status_vars.common.rebirth.halo_lower_wait -= 1

## 0x8013D200
static func ftCommonRebirthDownProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftCommonRebirthCommonUpdateHaloWait(fighter_gobj)

	if fp.status_vars.common.rebirth.halo_despawn_wait == (FTCOMMON_REBIRTH_HALO_DESPAWN_WAIT - FTCOMMON_REBIRTH_HALO_UNK_WAIT):
		fp.camera_mode = nFTCameraModeDefault
	if fp.status_vars.common.rebirth.halo_despawn_wait == (FTCOMMON_REBIRTH_HALO_DESPAWN_WAIT - FTCOMMON_REBIRTH_HALO_STAND_WAIT):
		ftCommonRebirthStandSetStatus(fighter_gobj)

## 0x8013D264
static func ftCommonRebirthCommonProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	# (((pos.y - halo_offset.y) / 8100.0F) * SQUARE(halo_lower_wait)) + halo_offset.y, in f32 steps like the C
	var lower: float = f32(fp.status_vars.common.rebirth.pos.y - fp.status_vars.common.rebirth.halo_offset.y)

	lower = f32(lower / 8100.0)
	lower = f32(lower * SQUARE(fp.status_vars.common.rebirth.halo_lower_wait))

	DObjGetStruct(fighter_gobj).translate.y = lower + fp.status_vars.common.rebirth.halo_offset.y

## 0x8013D2AC
static func ftCommonRebirthStandProcUpdate(fighter_gobj) -> void:
	ftCommonRebirthCommonUpdateHaloWait(fighter_gobj)
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommonrebirth, &"ftCommonRebirthWaitSetStatus"))

## 0x8013D2DC
static func ftCommonRebirthStandSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusRebirthStand, 0.0, 1.0, (FTSTATUS_PRESERVE_PLAYERTAG | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM))
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.is_menu_ignore = TRUE
	fp.is_ghost = TRUE
	fp.is_shadow_hide = TRUE
	fp.is_rebirth = TRUE

	fp.camera_zoom_range = 0.6

## 0x8013D358
static func ftCommonRebirthWaitProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftCommonRebirthCommonUpdateHaloWait(fighter_gobj)

	if fp.status_vars.common.rebirth.halo_despawn_wait == 0:
		Ftparam.ftParamSetTimedHitStatusInvincible(fp, FTCOMMON_REBIRTH_INVINCIBLE_FRAMES)
		Ftcommonfall.ftCommonFallSetStatus(fighter_gobj)

## 0x8013D3A4
static func ftCommonRebirthWaitProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if ftCommonGroundCheckInterrupt(fighter_gobj):
		Ftparam.ftParamSetTimedHitStatusInvincible(fp, FTCOMMON_REBIRTH_INVINCIBLE_FRAMES)

## 0x8013D518
static func ftCommonRebirthWaitSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusRebirthWait, 0.0, 1.0, (FTSTATUS_PRESERVE_PLAYERTAG | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM))

	fp.is_ghost = TRUE
	fp.is_shadow_hide = TRUE
	fp.is_rebirth = TRUE

	fp.camera_zoom_range = 0.6
