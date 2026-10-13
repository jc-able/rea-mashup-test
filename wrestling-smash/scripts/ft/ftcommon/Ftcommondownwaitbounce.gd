## 1:1 port of src/ft/ftcommon/ftcommondownwaitbounce.c (ssb-decomp-re): knockdown bounce (DownBounce)
## and lying on the ground (DownWait).
class_name Ftcommondownwaitbounce
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

const FTCOMMON_DOWNBOUNCE_STATUS_FLAGS = (FTSTATUS_PRESERVE_PLAYERTAG | FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_SLOPECONTOUR | FTSTATUS_PRESERVE_MODELPART)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80144220
static func ftCommonDownWaitProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.common.downwait.stand_wait -= 1

	if fp.status_vars.common.downwait.stand_wait == 0:
		Ftcommondownstand.ftCommonDownStandSetStatus(fighter_gobj)

## 0x80144254
static func ftCommonDownWaitProcInterrupt(fighter_gobj) -> void:
	if not Ftcommondownattack.ftCommonDownAttackCheckInterruptDownWait(fighter_gobj) and not Ftcommondownforwardback.ftCommonDownForwardOrBackCheckInterruptCommon(fighter_gobj):
		Ftcommondownstand.ftCommonDownStandCheckInterruptCommon(fighter_gobj)

## 0x80144294
static func ftCommonDownWaitSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int

	if fp.status_id == nFTCommonStatusDownBounceD:
		status_id = nFTCommonStatusDownWaitD
	else:
		status_id = nFTCommonStatusDownWaitU

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTCOMMON_DOWNBOUNCE_STATUS_FLAGS)

	fp.status_vars.common.downwait.stand_wait = FTCOMMON_DOWNWAIT_STAND_WAIT

	Ftparam.ftParamSetCaptureImmuneMask(fp, (FTCATCHKIND_MASK_CAPTAINSPECIALHI | FTCATCHKIND_MASK_COMMON | FTCATCHKIND_MASK_KIRBYSPECIALN | FTCATCHKIND_MASK_YOSHISPECIALN))

	fp.damage_mul = 0.5

## 0x80144308
static func ftCommonDownBounceProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.common.downbounce.attack_buffer != 0:
		fp.status_vars.common.downbounce.attack_buffer -= 1
	if fp.input.pl.button_tap & (fp.input.button_mask_a | fp.input.button_mask_b):
		fp.status_vars.common.downbounce.attack_buffer = FTCOMMON_DOWNBOUNCE_ATTACK_BUFFER
	if (fighter_gobj.anim_frame <= 0.0) and not Ftcommondownattack.ftCommonDownAttackCheckInterruptDownBounce(fighter_gobj) and not Ftcommondownforwardback.ftCommonDownForwardOrBackCheckInterruptCommon(fighter_gobj):
		ftCommonDownWaitSetStatus(fighter_gobj)

## 0x80144398 - 1 = face down (D), 0 = face up (U), from the body pitch (joint 4 X rotation)
static func ftCommonDownBounceCheckUpOrDown(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var rot_x: float = fp.joints[4].rotate.x

	rot_x = f32(rot_x / F_CST_DTOR32(360.0)) # f32 division

	rot_x -= int(rot_x) # (s32) truncation toward zero; exact in f32

	if (rot_x < -0.5) or ((rot_x > 0.0) and (rot_x < 0.5)):
		return 1
	else:
		return 0

## 0x80144428
static func ftCommonDownBounceUpdateEffects(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	# C: NULL effect_pos / effect_scatter
	Ftparam.ftParamMakeEffect(fighter_gobj, nEFKindImpactWave, nFTPartsJointTopN, Vector3.ZERO, Vector3.ZERO, fp.lr, FALSE, FALSE)
	Snd.func_800269C0_275C0(Ftcommondata.dFTCommonDataDownBounceSFX[fp.fkind])
	Ftparam.ftParamMakeRumble(fp, 4, 0)

## 0x80144498
static func ftCommonDownBounceSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int

	if fp.ga == nMPKineticsAir:
		Mpcommon.mpCommonSetFighterGround(fp)
	if ftCommonDownBounceCheckUpOrDown(fighter_gobj) != 0:
		status_id = nFTCommonStatusDownBounceD
	else:
		status_id = nFTCommonStatusDownBounceU

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_PLAYERTAG)
	ftCommonDownBounceUpdateEffects(fighter_gobj)

	fp.status_vars.common.downbounce.attack_buffer = 0
	fp.damage_mul = 0.5

	Ftparam.ftParamVelDamageTransferGround(fp)
