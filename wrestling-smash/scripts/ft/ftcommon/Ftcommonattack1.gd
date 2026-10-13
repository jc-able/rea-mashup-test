## 1:1 port of src/ft/ftcommon/ftcommonattack1.c (ssb-decomp-re): jab combo (Attack11 / Attack12 /
## Attack13) and the A-press interrupt shared by the ground statuses.
class_name Ftcommonattack1
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

## ftCommonAttack13CheckFighterKind(fp) (macro in ftcommonattack1.c)
static func ftCommonAttack13CheckFighterKind(fp) -> bool:
	return (
		(fp.fkind == nFTKindMario)   or
		(fp.fkind == nFTKindMMario)  or
		(fp.fkind == nFTKindNMario)  or
		(fp.fkind == nFTKindLuigi)   or
		(fp.fkind == nFTKindNLuigi)  or
		(fp.fkind == nFTKindCaptain) or
		(fp.fkind == nFTKindNCaptain)or
		(fp.fkind == nFTKindLink)    or
		(fp.fkind == nFTKindNLink)   or
		(fp.fkind == nFTKindNess)    or
		(fp.fkind == nFTKindNNess)
	)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8014E7B0
static func ftCommonAttack11ProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.motion_vars.flags.flag1 != 0) and (fp.status_vars.common.attack1.is_goto_followup != FALSE):
		if (fp.fkind == nFTKindPikachu) or (fp.fkind == nFTKindNPikachu):
			ftCommonAttack11SetStatus(fighter_gobj)
		else:
			ftCommonAttack12SetStatus(fighter_gobj)
	else:
		Ftanimend.ftAnimEndSetWait(fighter_gobj)

## 0x8014E824
static func ftCommonAttack12ProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.fkind != nFTKindCaptain) and (fp.fkind != nFTKindNCaptain) and (fp.motion_vars.flags.flag1 != 0) and B(fp.is_goto_attack100):
		Ftcommonattack100.ftCommonAttack100StartSetStatus(fighter_gobj)
	elif (fp.motion_vars.flags.flag1 != 0) and (fp.status_vars.common.attack1.is_goto_followup != FALSE):
		ftCommonAttack13SetStatus(fighter_gobj)
	else:
		Ftanimend.ftAnimEndSetWait(fighter_gobj)

## 0x8014E8B4
static func ftCommonAttack13ProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if ((fp.fkind == nFTKindCaptain) or (fp.fkind == nFTKindNCaptain)) and (fp.motion_vars.flags.flag1 != 0) and B(fp.is_goto_attack100):
		Ftcommonattack100.ftCommonAttack100StartSetStatus(fighter_gobj)
	else:
		Ftanimend.ftAnimEndSetWait(fighter_gobj)

## 0x8014E91C
static func ftCommonAttack11ProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.common.attack1.interrupt_catch_timer < 2:
		fp.status_vars.common.attack1.interrupt_catch_timer += 1

		if Ftcommoncatch1.ftCommonCatchCheckInterruptAttack11(fighter_gobj):
			return
	if not Ftcommonattack100.ftCommonAttack100StartCheckInterruptCommon(fighter_gobj):
		if (fp.fkind == nFTKindPikachu) or (fp.fkind == nFTKindNPikachu):
			if ftCommonAttack11CheckGoto(fighter_gobj) != FALSE:
				return
		else:
			ftCommonAttack12CheckGoto(fighter_gobj)

## 0x8014E9B4
static func ftCommonAttack12ProcInterrupt(fighter_gobj) -> void:
	if ftCommonAttack13CheckGoto(fighter_gobj) == FALSE:
		Ftcommonattack100.ftCommonAttack100StartCheckInterruptCommon(fighter_gobj)

## 0x8014E9E4
static func ftCommonAttack13ProcInterrupt(fighter_gobj) -> void:
	Ftcommonattack100.ftCommonAttack100StartCheckInterruptCommon(fighter_gobj)

## 0x8014EA04
static func ftCommonAttack11ProcStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftparam.ftParamSetMotionID(fp, nFTMotionAttackIDAttack11)
	Ftparam.ftParamSetStatUpdate(fp, fp.stat_flags.halfword)
	Ftparam.ftParamUpdate1PGameAttackStats(fp, 0)

## 0x8014EA44
static func ftCommonAttack11SetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if not Ftcommonget.ftCommonGetCheckInterruptCommon(fighter_gobj):
		fp.proc_status = Callable(Ftcommonattack1, &"ftCommonAttack11ProcStatus")

		Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusAttack11, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
		Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

		fp.motion_vars.flags.flag1 = 0

		fp.status_vars.common.attack1.is_goto_followup = FALSE
		fp.status_vars.common.attack1.interrupt_catch_timer = 0

		fp.attack1_input_count = 0
		fp.attack1_status_id = fp.status_id
		fp.is_goto_attack100 = FALSE
		fp.attack1_followup_frames = attr.attack1_followup_frames

## 0x8014EAD8
static func ftCommonAttack12SetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if not Ftcommonget.ftCommonGetCheckInterruptCommon(fighter_gobj):
		Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusAttack12, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
		Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

		fp.motion_vars.flags.flag1 = 0

		fp.status_vars.common.attack1.is_goto_followup = FALSE

		fp.attack1_status_id = fp.status_id

		match fp.fkind:
			nFTKindMario, nFTKindMMario, nFTKindNMario:
				fp.attack1_followup_frames = FTCOMMON_ATTACK1_FOLLOWUP_FRAMES_DEFAULT

			nFTKindLuigi, nFTKindNLuigi:
				fp.attack1_followup_frames = FTCOMMON_ATTACK1_FOLLOWUP_FRAMES_DEFAULT

			nFTKindCaptain, nFTKindNCaptain:
				fp.attack1_followup_frames = FTCOMMON_ATTACK1_FOLLOWUP_FRAMES_DEFAULT

			nFTKindLink, nFTKindNLink:
				fp.attack1_followup_frames = FTCOMMON_ATTACK1_FOLLOWUP_FRAMES_DEFAULT

			nFTKindNess, nFTKindNNess:
				fp.attack1_followup_frames = FTCOMMON_ATTACK1_FOLLOWUP_FRAMES_DEFAULT

## 0x8014EBB4
static func ftCommonAttack13SetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int # C: left uninitialized for fighter kinds without a third jab (never reached)

	if not Ftcommonget.ftCommonGetCheckInterruptCommon(fighter_gobj):
		match fp.fkind:
			nFTKindMario, nFTKindMMario, nFTKindNMario:
				status_id = nFTMarioStatusAttack13

			nFTKindLuigi, nFTKindNLuigi:
				status_id = nFTMarioStatusAttack13

			nFTKindCaptain, nFTKindNCaptain:
				status_id = nFTCaptainStatusAttack13

			nFTKindLink, nFTKindNLink:
				status_id = nFTLinkStatusAttack13

			nFTKindNess, nFTKindNNess:
				status_id = nFTNessStatusAttack13

		Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
		Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

		fp.motion_vars.flags.flag1 = 0
		fp.status_vars.common.attack1.is_goto_followup = FALSE
		fp.attack1_status_id = fp.status_id

## 0x8014EC78
static func ftCommonAttack1CheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if fp.input.pl.button_tap & fp.input.button_mask_a:
		if fp.item_gobj != null:
			if itGetStruct(fp.item_gobj).type == nITTypeThrow:
				Ftcommonitemthrow.ftCommonItemThrowSetStatus(fighter_gobj, nFTCommonStatusLightThrowF)

				return TRUE
			if fp.input.pl.button_hold & fp.input.button_mask_z:
				Ftcommonitemthrow.ftCommonItemThrowSetStatus(fighter_gobj, nFTCommonStatusLightThrowDrop)

				return TRUE
			match itGetStruct(fp.item_gobj).type:
				nITTypeSwing:
					Ftcommonitemswing.ftCommonItemSwingSetStatus(fighter_gobj, nFTItemSwingTypeAttack1)
					return TRUE

				nITTypeShoot:
					Ftcommonitemshoot.ftCommonItemShootSetStatus(fighter_gobj)
					return TRUE
		if fp.attack1_followup_frames != 0.0:
			match fp.attack1_status_id:
				nFTCommonStatusAttack11:
					if (fp.fkind == nFTKindPikachu) or (fp.fkind == nFTKindNPikachu):
						if attr.is_have_attack11:
							ftCommonAttack11SetStatus(fighter_gobj)

							fp.attack1_input_count += 1

							return TRUE
						# break
					elif attr.is_have_attack12:
						ftCommonAttack12SetStatus(fighter_gobj)

						fp.attack1_input_count += 1

						return TRUE

				nFTCommonStatusAttack12:
					if ftCommonAttack13CheckFighterKind(fp):
						ftCommonAttack13SetStatus(fighter_gobj)

						return TRUE
		elif attr.is_have_attack11:
			ftCommonAttack11SetStatus(fighter_gobj)

			return TRUE
	if fp.attack1_followup_frames != 0.0:
		fp.attack1_followup_frames = f32(fp.attack1_followup_frames - DObjGetStruct(fighter_gobj).anim_speed) # f32 -=
	return FALSE

## 0x8014EEC0
static func ftCommonAttack11CheckGoto(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if fp.attack1_followup_frames != 0.0:
		fp.attack1_followup_frames = f32(fp.attack1_followup_frames - DObjGetStruct(fighter_gobj).anim_speed) # f32 -=

		if (fp.input.pl.button_tap & fp.input.button_mask_a) and attr.is_have_attack11:
			if fp.motion_vars.flags.flag1 != 0:
				ftCommonAttack11SetStatus(fighter_gobj)

				return TRUE
			fp.status_vars.common.attack1.is_goto_followup = TRUE
	return FALSE

## 0x8014EF50
static func ftCommonAttack12CheckGoto(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if fp.attack1_followup_frames != 0.0:
		fp.attack1_followup_frames = f32(fp.attack1_followup_frames - DObjGetStruct(fighter_gobj).anim_speed) # f32 -=

		if (fp.input.pl.button_tap & fp.input.button_mask_a) and attr.is_have_attack12:
			if fp.motion_vars.flags.flag1 != 0:
				ftCommonAttack12SetStatus(fighter_gobj)

				return TRUE
			fp.status_vars.common.attack1.is_goto_followup = TRUE
	return FALSE

## 0x8014EFE0
static func ftCommonAttack13CheckGoto(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if not (ftCommonAttack13CheckFighterKind(fp)):
		return FALSE
	else:
		if fp.attack1_followup_frames != 0.0:
			fp.attack1_followup_frames = f32(fp.attack1_followup_frames - DObjGetStruct(fighter_gobj).anim_speed) # f32 -=

			if fp.input.pl.button_tap & fp.input.button_mask_a:
				if fp.motion_vars.flags.flag1 != 0:
					ftCommonAttack13SetStatus(fighter_gobj)

					return TRUE
				fp.status_vars.common.attack1.is_goto_followup = TRUE
	return FALSE
