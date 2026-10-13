## 1:1 port of src/ft/ftcommon/ftcommonentry.c (ssb-decomp-re): battle entry (Entry / EntryNull)
## and the per-character Appear animations (incl. Ness / Captain Falcon multi-part appears).
class_name Ftcommonentry
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x801884A0 - [fkind][0 = facing right, 1 = facing left]
static var dFTCommonEntryAppearStatusIDs: Array = [
	[nFTMarioStatusAppearR,        nFTMarioStatusAppearL],          # Mario
	[nFTFoxStatusAppearR,          nFTFoxStatusAppearL],            # Fox
	[nFTDonkeyStatusAppearR,       nFTDonkeyStatusAppearL],         # Donkey Kong
	[nFTSamusStatusAppearR,        nFTSamusStatusAppearL],          # Samus
	[nFTMarioStatusAppearR,        nFTMarioStatusAppearL],          # Luigi
	[nFTLinkStatusAppearR,         nFTLinkStatusAppearL],           # Link
	[nFTYoshiStatusAppearR,        nFTYoshiStatusAppearL],          # Yoshi
	[nFTCaptainStatusAppearRStart, nFTCaptainStatusAppearLStart],   # Captain Falcon
	[nFTKirbyStatusAppearR,        nFTKirbyStatusAppearL],          # Kirby
	[nFTPikachuStatusAppearR,      nFTPikachuStatusAppearL],        # Pikachu
	[nFTPurinStatusAppearR,        nFTPurinStatusAppearL],          # Jigglypuff
	[nFTNessStatusAppearRStart,    nFTNessStatusAppearLStart],      # Ness
	[nFTBossStatusAppear,          nFTBossStatusAppear],            # Master Hand
	[nFTMarioStatusAppearR,        nFTMarioStatusAppearL],          # Metal Mario
	[nFTCommonStatusEntryNull,     nFTCommonStatusEntryNull],       # Poly Mario
	[nFTCommonStatusEntryNull,     nFTCommonStatusEntryNull],       # Poly Fox
	[nFTCommonStatusEntryNull,     nFTCommonStatusEntryNull],       # Poly Donkey Kong
	[nFTCommonStatusEntryNull,     nFTCommonStatusEntryNull],       # Poly Samus
	[nFTCommonStatusEntryNull,     nFTCommonStatusEntryNull],       # Poly Luigi
	[nFTCommonStatusEntryNull,     nFTCommonStatusEntryNull],       # Poly Link
	[nFTCommonStatusEntryNull,     nFTCommonStatusEntryNull],       # Poly Yoshi
	[nFTCommonStatusEntryNull,     nFTCommonStatusEntryNull],       # Poly Captain Falcon
	[nFTCommonStatusEntryNull,     nFTCommonStatusEntryNull],       # Poly Kirby
	[nFTCommonStatusEntryNull,     nFTCommonStatusEntryNull],       # Poly Pikachu
	[nFTCommonStatusEntryNull,     nFTCommonStatusEntryNull],       # Poly Jigglypuff
	[nFTCommonStatusEntryNull,     nFTCommonStatusEntryNull],       # Poly Ness
	[nFTDonkeyStatusAppearR,       nFTDonkeyStatusAppearL],         # Giant Donkey Kong
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8013D930
static func ftCommonEntrySetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusEntry, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.is_invisible = TRUE
	fp.is_shadow_hide = TRUE
	fp.is_ghost = TRUE
	fp.is_playertag_hide = TRUE

## 0x8013D994
static func ftCommonEntryNullProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.common.entry.entry_wait != 0:
		fp.status_vars.common.entry.entry_wait -= 1

		if fp.status_vars.common.entry.entry_wait == 0:
			if fp.fkind == nFTKindBoss:
				Ftbosswait.ftBossWaitSetStatus(fighter_gobj)
			else:
				fp.lr = fp.status_vars.common.entry.lr

				DObjGetStruct(fighter_gobj).translate = fp.entry_pos

				fp.coll_data.floor_line_id = fp.status_vars.common.entry.floor_line_id

				Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)

## 0x8013DA14
static func ftCommonAppearUpdateEffects(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 != 0:
		if (fp.fkind == nFTKindPikachu) or (fp.fkind == nFTKindPurin) or (fp.fkind == nFTKindNPikachu) or (fp.fkind == nFTKindNPurin):
			Efmanager.efManagerMBallRaysMakeEffect(fp.entry_pos)
		fp.motion_vars.flags.flag1 = 0
	if fp.motion_vars.flags.flag2 != 0:
		fp.motion_vars.flags.flag2 = 0

		fp.is_shadow_hide = FALSE

## 0x8013DA94
static func ftCommonAppearProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftCommonAppearUpdateEffects(fighter_gobj)

	if fighter_gobj.anim_frame <= 0.0:
		fp.lr = fp.status_vars.common.entry.lr

		DObjGetStruct(fighter_gobj).translate = fp.entry_pos

		fp.coll_data.floor_line_id = fp.status_vars.common.entry.floor_line_id

		if fp.fkind == nFTKindBoss:
			Ftbosswait.ftBossWaitSetStatus(fighter_gobj)
		else:
			Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)

## 0x8013DB2C
static func ftCommonAppearProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var topn_joint: DObj = fp.joints[nFTPartsJointTopN]
	var transn_joint: DObj = fp.joints[nFTPartsJointTransN]

	topn_joint.translate.y = fp.entry_pos.y + transn_joint.translate.y

	if fp.status_vars.common.entry.is_rotate != FALSE:
		topn_joint.translate.x = fp.entry_pos.x - transn_joint.translate.x
		topn_joint.translate.z = fp.entry_pos.z - transn_joint.translate.z

		topn_joint.rotate.y = F_CST_DTOR32(180.0)
	else:
		topn_joint.translate.x = fp.entry_pos.x + transn_joint.translate.x
		topn_joint.translate.z = fp.entry_pos.z + transn_joint.translate.z

## 0x8013DBAC
static func ftCommonAppearInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.is_ghost = TRUE

	fp.camera_mode = nFTCameraModeEntry

	fp.is_shadow_hide = TRUE
	fp.is_playertag_hide = TRUE

## 0x8013DBE0
static func ftCommonAppearSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int
	var entry_id: int
	var boss_target_gobj

	entry_id = 0 if (fp.lr == +1) else 1

	fp.entry_pos = DObjGetStruct(fighter_gobj).translate

	fp.status_vars.common.entry.is_rotate = FALSE

	fp.status_vars.common.entry.lr = fp.lr

	fp.lr = 0

	fp.status_vars.common.entry.floor_line_id = fp.coll_data.floor_line_id

	status_id = dFTCommonEntryAppearStatusIDs[fp.fkind][entry_id]

	match fp.fkind:
		nFTKindMario, nFTKindLuigi, nFTKindMMario:
			Efmanager.efManagerMarioEntryDokanMakeEffect(fp.entry_pos, fp.fkind)

		nFTKindFox:
			Efmanager.efManagerFoxEntryArwingMakeEffect(fp.entry_pos, fp.status_vars.common.entry.lr)

		nFTKindDonkey, nFTKindGDonkey:
			Efmanager.efManagerDonkeyEntryTaruMakeEffect(fp.entry_pos)

		nFTKindSamus:
			Efmanager.efManagerSamusEntryPointMakeEffect(fp.entry_pos)

		nFTKindLink:
			Efmanager.efManagerLinkEntryWaveMakeEffect(fp.entry_pos)
			Efmanager.efManagerLinkEntryBeamMakeEffect(fp.entry_pos)

		nFTKindYoshi:
			Efmanager.efManagerYoshiEntryEggMakeEffect(fp.entry_pos)

		nFTKindKirby:
			Efmanager.efManagerKirbyEntryStarMakeEffect(fp.entry_pos, fp.status_vars.common.entry.lr)

		nFTKindPikachu, nFTKindPurin:
			Efmanager.efManagerMBallThrownMakeEffect(fp.entry_pos, fp.status_vars.common.entry.lr)

		nFTKindCaptain:
			if fp.status_vars.common.entry.lr == -1:
				fp.status_vars.common.entry.is_rotate = TRUE
			Efmanager.efManagerCaptainEntryCarMakeEffect(fp.entry_pos, fp.status_vars.common.entry.lr)

		nFTKindBoss:
			# boss_target_gobj = gGCCommonLinks[nGCCommonLinkIDFighter]; walk link_next until an object
			# that is not this fighter (assumes Master Hand has found its target), else NULL.
			boss_target_gobj = null

			for other_gobj in Sim.get_link(nGCCommonLinkIDFighter):
				if other_gobj != fighter_gobj:
					boss_target_gobj = other_gobj
					break
			fp.passive_vars.boss.p.target_gobj = boss_target_gobj

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftCommonAppearInitStatusVars(fighter_gobj)

	fp.status_vars.common.entry.entry_wait = FTCOMMON_ENTRY_WAIT

	fp.motion_vars.flags.flag1 = 0
	fp.motion_vars.flags.flag2 = 0
	fp.motion_vars.flags.flag0 = 0

	if (fp.fkind == nFTKindCaptain) and (fp.status_vars.common.entry.lr == -1):
		Ftparam.ftParamMoveDLLink(fighter_gobj, 1)

## 0x8013DDE0
static func ftCommonAppearSetPosition(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.camera_mode = 3

	fp.entry_pos = DObjGetStruct(fighter_gobj).translate

	DObjGetStruct(fighter_gobj).translate.y = (Mpcollision.gMPCollisionGroundData.camera_bound_top + Mpcollision.gMPCollisionGroundData.map_bound_top) * 0.5

	Ftcommonfall.ftCommonFallSetStatus(fighter_gobj)

## 0x8013DE60
static func ftNessAppearStartProcUpdate(fighter_gobj) -> void:
	ftCommonAppearUpdateEffects(fighter_gobj)
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommonentry, &"ftNessAppearWaitSetStatus"))

## 0x8013DE90
static func ftNessAppearWaitProcUpdate(fighter_gobj) -> void:
	ftCommonAppearUpdateEffects(fighter_gobj)
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommonentry, &"ftNessAppearEndSetStatus"))

## 0x8013DEC0
static func ftNessAppearWaitSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusAppearWait, 0.0, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_COLANIM))
	ftCommonAppearInitStatusVars(fighter_gobj)

	fp.is_shadow_hide = FALSE

## 0x8013DF14
static func ftNessAppearEndSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, (nFTNessStatusAppearREnd if (fp.status_vars.common.entry.lr == +1) else nFTNessStatusAppearLEnd), 0.0, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_COLANIM))
	ftCommonAppearInitStatusVars(fighter_gobj)

	fp.is_shadow_hide = FALSE

## 0x8013DF7C
static func ftCaptainAppearStartProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftCommonAppearUpdateEffects(fighter_gobj)

	if (fp.status_vars.common.entry.lr == -1) and (fp.dl_link != FTDISPLAY_DLLINK_DEFAULT) and (DObjGetStruct(fighter_gobj).translate.z > -1000.0):
		Ftparam.ftParamMoveDLLink(fighter_gobj, FTDISPLAY_DLLINK_DEFAULT)
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommonentry, &"ftCaptainAppearEndSetStatus"))

## 0x8013E008
static func ftCaptainAppearEndSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, (nFTCaptainStatusAppearREnd if (fp.status_vars.common.entry.lr == +1) else nFTCaptainStatusAppearLEnd), 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftCommonAppearInitStatusVars(fighter_gobj)

	fp.is_shadow_hide = FALSE
