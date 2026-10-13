## 1:1 port of src/ft/ftcommon/ftcommonattack100.c (ssb-decomp-re): rapid jab
## (Attack100Start / Attack100Loop / Attack100End) for Fox, Link, Kirby, Jigglypuff, Captain Falcon.
class_name Ftcommonattack100
extends Port

## ftKirbyAttack100Effect[] (src/relocData/228_KirbyMainMotion.c, dKirbyMainMotion_0x1220 =
## llKirbyMainMotionftKirbyAttack100Effect): { Vec3f offset; f32 rotate; f32 vel; f32 add; } x 6,
## indexed by (motion_vars.flags.flag2 - 1).
const dFTKirbyAttack100Effects: Array = [
	{"offset": Vector3(-30.0, 200.0, 300.0), "rotate": 0.0,   "vel": 180.0, "add": -30.0},
	{"offset": Vector3(-30.0, 240.0, 270.0), "rotate": 19.0,  "vel": 180.0, "add": -30.0},
	{"offset": Vector3(-30.0, 160.0, 300.0), "rotate": -13.0, "vel": 180.0, "add": -30.0},
	{"offset": Vector3(-30.0, 240.0, 300.0), "rotate": 10.0,  "vel": 180.0, "add": -30.0},
	{"offset": Vector3(-30.0, 160.0, 270.0), "rotate": -10.0, "vel": 180.0, "add": -30.0},
	{"offset": Vector3(-30.0, 200.0, 300.0), "rotate": 5.0,   "vel": 180.0, "add": -30.0},
]

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

## ftCommonAttack100CheckFighterKind(fp) (macro in ftcommonattack100.c)
static func ftCommonAttack100CheckFighterKind(fp) -> bool:
	return (
		(fp.fkind == nFTKindFox)      or
		(fp.fkind == nFTKindNFox)     or
		(fp.fkind == nFTKindLink)     or
		(fp.fkind == nFTKindNLink)    or
		(fp.fkind == nFTKindKirby)    or
		(fp.fkind == nFTKindNKirby)   or
		(fp.fkind == nFTKindPurin)    or
		(fp.fkind == nFTKindNPurin)   or
		(fp.fkind == nFTKindCaptain)  or
		(fp.fkind == nFTKindNCaptain)
	)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8014F0D0
static func ftCommonAttack100StartProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommonattack100, &"ftCommonAttack100LoopSetStatus"))

## 0x8014F0F4
static func ftCommonAttack100StartSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int # C: uninitialized for other fighter kinds (never reached)

	if not Ftcommonget.ftCommonGetCheckInterruptCommon(fighter_gobj):
		match fp.fkind:
			nFTKindFox, nFTKindNFox:
				status_id = nFTFoxStatusAttack100Start

			nFTKindLink, nFTKindNLink:
				status_id = nFTLinkStatusAttack100Start

			nFTKindKirby, nFTKindNKirby:
				status_id = nFTKirbyStatusAttack100Start

			nFTKindPurin, nFTKindNPurin:
				status_id = nFTPurinStatusAttack100Start

			nFTKindCaptain, nFTKindNCaptain:
				status_id = nFTCaptainStatusAttack100Start

		Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
		Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

		fp.status_vars.common.attack100.is_anim_end = FALSE
		fp.status_vars.common.attack100.is_goto_loop = FALSE

		fp.motion_vars.flags.flag1 = 0
		fp.motion_vars.flags.flag2 = 0

## 0x8014F1BC
static func ftCommonAttack100LoopKirbyUpdateEffect(fp) -> void:
	var pos

	if fp.fkind == nFTKindKirby:
		if fp.motion_vars.flags.flag2 != 0:
			var effect: Dictionary = dFTKirbyAttack100Effects[fp.motion_vars.flags.flag2 - 1]

			pos = Vector3.ZERO
			pos.x = effect.offset.x
			pos.y = effect.offset.y
			pos.z = effect.offset.z

			pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[nFTPartsJointTopN], pos)

			Efmanager.efManagerKirbyVulcanJabMakeEffect(pos, fp.lr, effect.rotate, effect.vel, effect.add)

			fp.motion_vars.flags.flag2 = 0

## 0x8014F2A8
static func ftCommonAttack100LoopProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fighter_gobj.anim_frame >= 0.0) and (fighter_gobj.anim_frame < DObjGetStruct(fighter_gobj).anim_speed):
		fp.status_vars.common.attack100.is_anim_end = TRUE

		Ftparam.ftParamSetMotionID(fp, nFTMotionAttackIDAttack100)
		Ftparam.ftParamSetStatUpdate(fp, fp.stat_flags.halfword)
		Ftparam.ftParamUpdate1PGameAttackStats(fp, 0)
	if fp.motion_vars.flags.flag1 != 0:
		fp.motion_vars.flags.flag1 = 0

		if (fp.status_vars.common.attack100.is_anim_end != FALSE) and (fp.status_vars.common.attack100.is_goto_loop == FALSE):
			ftCommonAttack100EndSetStatus(fighter_gobj)

			return
		elif not Ftcommonget.ftCommonGetCheckInterruptCommon(fighter_gobj):
			fp.status_vars.common.attack100.is_goto_loop = FALSE
		else:
			return
	ftCommonAttack100LoopKirbyUpdateEffect(fp)

## 0x8014F388
static func ftCommonAttack100LoopProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.input.pl.button_tap & fp.input.button_mask_a) or (fp.input.pl.button_release & fp.input.button_mask_a):
		fp.status_vars.common.attack100.is_goto_loop = TRUE

## 0x8014F3C0
static func ftCommonAttack100LoopSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int # C: uninitialized for other fighter kinds (never reached)

	match fp.fkind:
		nFTKindFox, nFTKindNFox:
			status_id = nFTFoxStatusAttack100Loop

		nFTKindLink, nFTKindNLink:
			status_id = nFTLinkStatusAttack100Loop

		nFTKindKirby, nFTKindNKirby:
			status_id = nFTKirbyStatusAttack100Loop

		nFTKindPurin, nFTKindNPurin:
			status_id = nFTPurinStatusAttack100Loop

		nFTKindCaptain, nFTKindNCaptain:
			status_id = nFTCaptainStatusAttack100Loop

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftCommonAttack100LoopKirbyUpdateEffect(fp)

## 0x8014F45C
static func ftCommonAttack100EndSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int # C: uninitialized for other fighter kinds (never reached)

	match fp.fkind:
		nFTKindFox, nFTKindNFox:
			status_id = nFTFoxStatusAttack100End

		nFTKindLink, nFTKindNLink:
			status_id = nFTLinkStatusAttack100End

		nFTKindKirby, nFTKindNKirby:
			status_id = nFTKirbyStatusAttack100End

		nFTKindPurin, nFTKindNPurin:
			status_id = nFTPurinStatusAttack100End

		nFTKindCaptain, nFTKindNCaptain:
			status_id = nFTCaptainStatusAttack100End

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

## 0x8014F4EC
static func ftCommonAttack100StartCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int
	var inputs_min: int

	if not (ftCommonAttack100CheckFighterKind(fp)):
		return FALSE
	if (fp.input.pl.button_tap & fp.input.button_mask_a) or (fp.input.pl.button_release & fp.input.button_mask_a):
		# A frame-perfect A press (tapped on one frame and immediately released on the next)
		# registers twice due to the way button_release works.

		fp.attack1_input_count += 1

		match fp.fkind:
			nFTKindFox, nFTKindNFox:
				inputs_min = 4
				status_id = nFTCommonStatusAttack12

			nFTKindLink, nFTKindNLink:
				inputs_min = 5
				status_id = nFTCommonStatusAttack12

			nFTKindKirby, nFTKindNKirby:
				inputs_min = 4
				status_id = nFTCommonStatusAttack12

			nFTKindPurin, nFTKindNPurin:
				inputs_min = 4
				status_id = nFTCommonStatusAttack12

			nFTKindCaptain, nFTKindNCaptain:
				inputs_min = 6
				status_id = nFTCaptainStatusAttack13

		if fp.attack1_input_count >= inputs_min:
			if (status_id == fp.status_id) and (fp.motion_vars.flags.flag1 != 0):
				ftCommonAttack100StartSetStatus(fighter_gobj)

				return TRUE
			else:
				fp.is_goto_attack100 = TRUE
	return FALSE
