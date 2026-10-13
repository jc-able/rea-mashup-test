## 1:1 port of src/ft/ftcommon/ftcommoncapturecaptain.c (ssb-decomp-re): CaptureCaptain (victim of
## Captain Falcon's Falcon Dive grab).
class_name Ftcommoncapturecaptain
extends Port

## Vec2h offset_add[nFTKindEnumCount] = lbRelocGetFileData(Vec2h*, gFTDataCaptainMainMotion, &llCaptainMainMotionSpecialHiVec2h)
## Transcribed from src/relocData/235_CaptainMainMotion.c dCaptainMainMotion_0x0000 (Falcon Dive
## capture-grab offsets per victim FTKind, {x, y} as s16).
const dCaptainMainMotionSpecialHiVec2h: Array = [
	[30, 70],      # Mario
	[40, 40],      # Fox
	[100, 250],    # Donkey
	[80, 210],     # Samus
	[30, 70],      # Luigi
	[100, 160],    # Link
	[0, 110],      # Yoshi
	[80, 210],     # Captain
	[20, 100],     # Kirby
	[-10, 80],     # Pikachu
	[20, 100],     # Purin
	[30, 70],      # Ness
	[0, 0],        # Boss
	[30, 70],      # MMario
	[30, 70],      # NMario
	[40, 40],      # NFox
	[120, 260],    # NDonkey
	[80, 210],     # NSamus
	[30, 70],      # NLuigi
	[100, 160],    # NLink
	[0, 0],        # NYoshi
	[80, 210],     # NCaptain
	[20, 100],     # NKirby
	[-10, 80],     # NPikachu
	[20, 100],     # NPurin
	[50, 150],     # NNess
	[100, 250],    # GDonkey
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8014D0F0
## C: void ftCommonCaptureCaptainUpdatePositions(GObj *fighter_gobj, GObj *capture_gobj, Vec3f *pos)
## pos is a pure output -> returned (the optional third argument is ignored).
static func ftCommonCaptureCaptainUpdatePositions(fighter_gobj, capture_gobj, pos = null) -> Vector3:
	# 0x80188A20
	var offset := Vector3(0.0, 0.0, 0.0)

	var this_fp := ftGetStruct(fighter_gobj)
	var capture_fp := ftGetStruct(capture_gobj)
	var offset_add: Array = dCaptainMainMotionSpecialHiVec2h
	var out_pos: Vector3

	out_pos.x = 0.0
	out_pos.y = 0.0
	out_pos.z = 0.0

	out_pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(this_fp.joints[29], out_pos)
	offset = Gmcollision.gmCollisionGetFighterPartsWorldPosition(capture_fp.joints[nFTPartsJointTopN], offset)

	offset.x += (offset_add[capture_fp.fkind][0] * this_fp.lr)
	offset.y += offset_add[capture_fp.fkind][1]

	# syVectorSub3D(pos, &offset)
	out_pos.x -= offset.x
	out_pos.y -= offset.y
	out_pos.z -= offset.z

	return out_pos

## 0x8014D200
static func ftCommonCaptureCaptainProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3

	if fp.status_vars.common.capturecaptain.capture_flag & FTCOMMON_CAPTURECAPTAIN_MASK_THROW:
		ftCommonCaptureCaptainRelease(fighter_gobj)
	elif not (fp.status_vars.common.capturecaptain.capture_flag & FTCOMMON_CAPTURECAPTAIN_MASK_NOUPDATE):
		pos = ftCommonCaptureCaptainUpdatePositions(fp.capture_gobj, fighter_gobj)

		if syVectorMag3D(pos) > 180.0:
			pos = syVectorNorm3D(pos)

			# syVectorScale3D(&pos, 180.0F)
			pos.x *= 180.0
			pos.y *= 180.0
			pos.z *= 180.0
		# syVectorAdd3D(&DObjGetStruct(fighter_gobj)->translate, &pos)
		DObjGetStruct(fighter_gobj).translate.x += pos.x
		DObjGetStruct(fighter_gobj).translate.y += pos.y
		DObjGetStruct(fighter_gobj).translate.z += pos.z

## 0x8014D2A0
static func ftCommonCaptureCaptainProcCapture(fighter_gobj, capture_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var capture_fp: Fighter

	Ftparam.ftParamStopVoiceRunProcDamage(fighter_gobj)

	if (this_fp.item_gobj != null) and (itGetStruct(this_fp.item_gobj).weight == nITWeightHeavy):
		Itmain.itMainSetFighterDrop(this_fp.item_gobj, Vector3.ZERO, 1.0)    # ftSetupDropItem(this_fp)
	if this_fp.catch_gobj != null:
		Ftcommonthrown2.ftCommonThrownSetStatusDamageRelease(this_fp.catch_gobj)

		this_fp.catch_gobj = null
	this_fp.capture_gobj = capture_gobj

	capture_fp = ftGetStruct(capture_gobj)

	this_fp.lr = -capture_fp.lr

	this_fp.status_vars.common.capturecaptain.capture_flag = 0

	if this_fp.ga != nMPKineticsAir:
		this_fp.status_vars.common.capturecaptain.capture_flag |= FTCOMMON_CAPTURECAPTAIN_MASK_NOUPDATE
		this_fp.is_catch_or_capture = TRUE
	else:
		this_fp.is_catch_or_capture = FALSE

	Mpcommon.mpCommonSetFighterAir(this_fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusCaptureCaptain, FTCOMMON_CAPTURECAPTAIN_FRAME_BEGIN, FTCOMMON_CAPTURECAPTAIN_ANIM_SPEED, FTSTATUS_PRESERVE_NONE)
	Ftparam.ftParamSetCaptureImmuneMask(this_fp, FTCATCHKIND_MASK_ALL)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	Ftphysics.ftPhysicsStopVelAll(fighter_gobj)
	ftCommonCaptureCaptainProcPhysics(fighter_gobj)

## 0x8014D3BC
static func ftCommonCaptureCaptainRelease(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftcommonthrown2.ftCommonThrownReleaseThrownUpdateStats(fighter_gobj, fp.lr, 0, 0)
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_NONE)
