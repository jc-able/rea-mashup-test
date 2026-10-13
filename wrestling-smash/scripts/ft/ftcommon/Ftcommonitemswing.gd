## 1:1 port of src/ft/ftcommon/ftcommonitemswing.c (ssb-decomp-re): swinging a held battering item
## (Beam Sword, Home-Run Bat, Fan, Star Rod).
class_name Ftcommonitemswing
extends Port

## F_PCT_TO_DEC(x) ((float)((x)*0.01F)) (include/macros.h)
static func _F_PCT_TO_DEC(x) -> float:
	return x * 0.01

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80146C40
static func ftCommonHarisenSwingProcHit(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.item_gobj != null:
		var ip := itGetStruct(fp.item_gobj)

		if ip.kind == nITKindHarisen:
			Itharisen.itHarisenCommonSetScale(fp.item_gobj, FTCOMMON_HARISENSWING_SCALE_HIT)

			fp.status_vars.common.itemswing.harisen_scale_reset_wait = FTCOMMON_HARISENSWING_SCALE_RESET_WAIT

## 0x80146C98
static func ftCommonHarisenSwingProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.item_gobj != null:
		if fp.status_vars.common.itemswing.harisen_scale_reset_wait != 0:
			fp.status_vars.common.itemswing.harisen_scale_reset_wait -= 1

			if fp.status_vars.common.itemswing.harisen_scale_reset_wait == 0:
				Itharisen.itHarisenCommonSetScale(fp.item_gobj, 1.0)
	Ftanimend.ftAnimEndSetWait(fighter_gobj)

## 0x80146CF4
static func ftCommonStarRodSwingProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var ip: Item
	var scale_mul: float

	if fp.item_gobj != null:
		if fp.motion_vars.flags.flag1 != 0:
			ip = itGetStruct(fp.item_gobj)

			if ip.multi != 0:
				Snd.func_800269C0_275C0(fp.motion_vars.flags.flag1 & 0xFFFF)    # u16 fgm_id
			else:
				Snd.func_800269C0_275C0(nSYAudioFGMStarRodEmpty)

			fp.motion_vars.flags.flag1 = 0
	if (fp.item_gobj != null) and (fp.motion_vars.flags.flag0 != 0):
		ip = itGetStruct(fp.item_gobj)

		if ip.multi != 0:
			# 0x80188600
			var make_star_offset := Vector3(0.0, 200.0, 0.0)

			scale_mul = 1.0 / fp.attr.size

			make_star_offset.x *= scale_mul
			make_star_offset.y *= scale_mul
			make_star_offset.z *= scale_mul

			make_star_offset = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[fp.attr.joint_itemlight_id], make_star_offset)

			Itstarrod.itStarRodMakeStar(fighter_gobj, make_star_offset, FALSE if (fp.motion_vars.flags.flag0 == 1) else TRUE)
		else:
			# 0x8018860C
			var effect_offset := Vector3(0.0, 200.0, 0.0)

			# C passes NULL for effect_scatter == zero scatter
			Ftparam.ftParamMakeEffect(fighter_gobj, nEFKindDustLight, fp.attr.joint_itemlight_id, effect_offset, Vector3.ZERO, -fp.lr, TRUE, FALSE)
		fp.motion_vars.flags.flag0 = 0
	Ftanimend.ftAnimEndSetWait(fighter_gobj)

## 0x80188618
static var dFTCommonItemSwingStatusIDs: Array = [
	[nFTCommonStatusSwordSwing1, nFTCommonStatusSwordSwing3, nFTCommonStatusSwordSwing4, nFTCommonStatusSwordSwingDash],
	[nFTCommonStatusBatSwing1, nFTCommonStatusBatSwing3, nFTCommonStatusBatSwing4, nFTCommonStatusBatSwingDash],
	[nFTCommonStatusHarisenSwing1, nFTCommonStatusHarisenSwing3, nFTCommonStatusHarisenSwing4, nFTCommonStatusHarisenSwingDash],
	[nFTCommonStatusStarRodSwing1, nFTCommonStatusStarRodSwing3, nFTCommonStatusStarRodSwing4, nFTCommonStatusStarRodSwingDash],
]

## 0x80146E94
static func ftCommonItemSwingSetStatus(fighter_gobj, swing_type) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var ip := itGetStruct(fp.item_gobj)
	var swing_item: int = 0     # C: left uninitialized when the held item is not a swing item
	var status_id: int
	var anim_speed: float

	match ip.kind:
		nITKindSword:
			swing_item = nFTItemSwingKindSword

		nITKindBat:
			swing_item = nFTItemSwingKindBat

		nITKindHarisen:
			swing_item = nFTItemSwingKindHarisen

		nITKindStarRod:
			swing_item = nFTItemSwingKindStarRod

	status_id = dFTCommonItemSwingStatusIDs[swing_item][swing_type]
	anim_speed = _F_PCT_TO_DEC(Ftcommondata.dFTCommonDataItemSwingAnimSpeeds[status_id - nFTCommonStatusItemSwingStart].anim_speed)

	fp.motion_vars.flags.flag0 = 0

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, anim_speed, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.proc_hit = Callable(Ftcommonitemswing, &"ftCommonHarisenSwingProcHit")

	fp.status_vars.common.itemswing.harisen_scale_reset_wait = 0

	fp.motion_vars.flags.flag1 = 0
