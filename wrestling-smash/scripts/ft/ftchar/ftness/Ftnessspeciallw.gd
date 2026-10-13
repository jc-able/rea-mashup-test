## Port of src/ft/ftchar/ftness/ftnessspeciallw.c (Ness down special: PSI Magnet).
class_name Ftnessspeciallw
extends Port

# // // // // // // // // // // // //
# //            DATA               //
# // // // // // // // // // // // //

## FTSpecialColl at gFTNessFileMainMotion + llNessMainMotionLwAbsorbFTSpecialColl
## (src/relocData/238_NessMainMotion.c: dNessMainMotion_LwAbsorbFTSpecialColl, REGION_US size;
## verified against the ROM's file 238 at 0x16D4). C points fp->special_coll at this read-only data.
static var dNessMainMotionLwAbsorbFTSpecialColl: FTSpecialColl = FTSpecialColl.make(
	1,                                  # kind
	0,                                  # joint_id
	Vector3(300.0, 195.0, 0.0),         # offset
	Vector3(430.0, 430.0, 430.0),       # size (REGION_JP: 400)
	0                                   # damage_resist
)

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

const FTNESS_SPECIALLWSTART_STATUS_FLAGS = (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM)
const FTNESS_SPECIALLWHOLD_STATUS_FLAGS = (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM | FTSTATUS_PRESERVE_HIT)
const FTNESS_SPECIALLWHIT_STATUS_FLAGS = (FTSTATUS_PRESERVE_LOOPSFX | FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM | FTSTATUS_PRESERVE_HIT)
const FTNESS_SPECIALLWEND_STATUS_FLAGS = (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_HITSTATUS | FTSTATUS_PRESERVE_COLANIM)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801551E0
static func ftNessSpecialLwCheckRelease(fp) -> void: # PSI Magnet interrupt?
	if not (fp.input.pl.button_hold & fp.input.button_mask_b):
		fp.status_vars.ness.speciallw.is_release = TRUE

## 0x80155204
static func ftNessSpecialLwDecReleaseLag(fp) -> void:
	if fp.status_vars.ness.speciallw.release_lag != 0:
		fp.status_vars.ness.speciallw.release_lag -= 1

## 0x8015521C
static func ftNessSpecialLwProcAbsorb(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var joint: DObj = fp.joints[nFTPartsJointTopN]

	fp.lr = fp.absorb_lr

	joint.rotate.y += F_CST_DTOR32(-180.0)

	Ftparam.ftParamsUpdateFighterPartsTransformAll(fp.joints[nFTPartsJointTopN])

	if fp.ga == nMPKineticsGround:
		ftNessSpecialLwHitSetStatus(fighter_gobj)
	else:
		ftNessSpecialAirLwHitSetStatus(fighter_gobj)

## 0x801552A0
static func ftNessSpecialLwStartProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftnessspeciallw, &"ftNessSpecialLwHoldSetStatus"))

## 0x801552C4
static func ftNessSpecialAirLwStartProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftnessspeciallw, &"ftNessSpecialAirLwHoldSetStatus"))

## 0x801552E8
static func ftNessSpecialLwProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.ness.speciallw.gravity_delay != 0:
		fp.status_vars.ness.speciallw.gravity_delay -= 1

## 0x80155304
static func ftNessSpecialAirLwProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if fp.status_vars.ness.speciallw.gravity_delay != 0:
		fp.status_vars.ness.speciallw.gravity_delay -= 1
	else:
		Ftphysics.ftPhysicsApplyGravityClampTVel(fp, 0.8, attr.tvel_base)

	if Ftphysics.ftPhysicsCheckClampAirVelXDecMax(fp, attr) == FALSE:
		Ftphysics.ftPhysicsApplyAirVelXFriction(fp, attr)

## 0x80155380
static func ftNessSpecialLwStartProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftnessspeciallw, &"ftNessSpecialLwStartSwitchStatusAir"))

## 0x801553A4
static func ftNessSpecialAirLwStartProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterCliff(fighter_gobj, Callable(Ftnessspeciallw, &"ftNessSpecialAirLwStartSwitchStatusGround"))

## 0x801553C8
static func ftNessSpecialAirLwStartSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialLwStart, fighter_gobj.anim_frame, 1.0, FTNESS_SPECIALLWSTART_STATUS_FLAGS)

## 0x80155408
static func ftNessSpecialLwStartSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialAirLwStart, fighter_gobj.anim_frame, 1.0, FTNESS_SPECIALLWSTART_STATUS_FLAGS)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x80155454
static func ftNessSpecialLw_InitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.ness.speciallw.release_lag = FTNESS_PSYCHICMAGNET_RELEASE_LAG
	fp.status_vars.ness.speciallw.is_release = FALSE
	fp.status_vars.ness.speciallw.gravity_delay = FTNESS_PSYCHICMAGNET_GRAVITY_DELAY

## 0x80155470
static func ftNessSpecialLwStartSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialLwStart, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftNessSpecialLw_InitStatusVars(fighter_gobj)

## 0x801554B0
static func ftNessSpecialAirLwStartSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialAirLwStart, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftNessSpecialLw_InitStatusVars(fighter_gobj)

	fp.physics.vel_air.x /= 2
	fp.physics.vel_air.y = 0.0

## 0x80155518
static func ftNessSpecialLw_UpdateReleaseLag(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftNessSpecialLwCheckRelease(fp)
	ftNessSpecialLwDecReleaseLag(fp)

## 0x80155544
static func ftNessSpecialLwHoldProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftNessSpecialLw_UpdateReleaseLag(fighter_gobj)

	if (fp.status_vars.ness.speciallw.release_lag <= 0) and (fp.status_vars.ness.speciallw.is_release != FALSE):
		ftNessSpecialLwEndSetStatus(fighter_gobj)

## 0x80155594
static func ftNessSpecialAirLwHoldProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftNessSpecialLw_UpdateReleaseLag(fighter_gobj)

	if (fp.status_vars.ness.speciallw.release_lag <= 0) and (fp.status_vars.ness.speciallw.is_release != FALSE):
		ftNessSpecialAirLwEndSetStatus(fighter_gobj)

## 0x801555E4
static func ftNessSpecialLwHoldProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftnessspeciallw, &"ftNessSpecialLwHoldSwitchStatusAir"))

## 0x80155608
static func ftNessSpecialAirLwHoldProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterCliff(fighter_gobj, Callable(Ftnessspeciallw, &"ftNessSpecialAirLwHoldSwitchStatusGround"))

## 0x8015562C
static func ftNessSpecialAirLwHoldSwitchStatusGround(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialLwHold, fighter_gobj.anim_frame, 1.0, FTNESS_SPECIALLWHOLD_STATUS_FLAGS)

	fp.is_absorb = TRUE

## 0x80155680
static func ftNessSpecialLwHoldSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialAirLwHold, fighter_gobj.anim_frame, 1.0, FTNESS_SPECIALLWHOLD_STATUS_FLAGS)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

	fp.is_absorb = TRUE

## 0x801556E0
static func ftNessSpecialLwInitVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if not fp.is_effect_attach:
		if Efmanager.efManagerNessPsychicMagnetMakeEffect(fighter_gobj) != null:
			fp.is_effect_attach = TRUE

	fp.is_absorb = TRUE

	fp.special_coll = dNessMainMotionLwAbsorbFTSpecialColl

	fp.motion_vars.flags.flag1 = 0

## 0x80155750
static func ftNessSpecialLwHoldSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialLwHold, 0.0, 1.0, (FTSTATUS_PRESERVE_LOOPSFX | FTSTATUS_PRESERVE_EFFECT))
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftNessSpecialLwInitVars(fighter_gobj)

## 0x80155794
static func ftNessSpecialAirLwHoldSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialAirLwHold, 0.0, 1.0, (FTSTATUS_PRESERVE_LOOPSFX | FTSTATUS_PRESERVE_EFFECT))
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftNessSpecialLwInitVars(fighter_gobj)

## 0x801557D8
static func ftNessSpecialLwHitProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 != 0:
		ftNessSpecialLwHoldSetStatus(fighter_gobj)

## 0x80155808
static func ftNessSpecialAirLwHitProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.motion_vars.flags.flag1 != 0:
		ftNessSpecialAirLwHoldSetStatus(fighter_gobj)

## 0x80155838
static func ftNessSpecialLwHitProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftnessspeciallw, &"ftNessSpecialLwHitSwitchStatusAir"))

## 0x8015585C
static func ftNessSpecialAirLwHitProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterCliff(fighter_gobj, Callable(Ftnessspeciallw, &"ftNessSpecialAirLwHitSwitchStatusGround"))

## 0x80155880
static func ftNessSpecialAirLwHitSwitchStatusGround(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialLwHit, fighter_gobj.anim_frame, 1.0, FTNESS_SPECIALLWHIT_STATUS_FLAGS)
	fp.is_absorb = TRUE

## 0x801558D4
static func ftNessSpecialLwHitSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialAirLwHit, fighter_gobj.anim_frame, 1.0, FTNESS_SPECIALLWHIT_STATUS_FLAGS)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

	fp.is_absorb = TRUE

## 0x80155934
static func ftNessSpecialLwHitSetAbsorbTrue(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.is_absorb = TRUE

## 0x80155948
static func ftNessSpecialLwHitSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialLwHit, 0.0, 1.0, FTSTATUS_PRESERVE_EFFECT)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftNessSpecialLwHitSetAbsorbTrue(fighter_gobj)

## 0x8015598C
static func ftNessSpecialAirLwHitSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialAirLwHit, 0.0, 1.0, FTSTATUS_PRESERVE_EFFECT)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftNessSpecialLwHitSetAbsorbTrue(fighter_gobj)

## 0x801559D0
static func ftNessSpecialAirLwEndProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommonfall, &"ftCommonFallSetStatus"))

## 0x801559F4
static func ftNessSpecialLwEndProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftnessspeciallw, &"ftNessSpecialLwEndSwitchStatusAir"))

## 0x80155A18
static func ftNessSpecialAirLwEndProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterCliff(fighter_gobj, Callable(Ftnessspeciallw, &"ftNessSpecialAirLwEndSwitchStatusGround"))

## 0x80155A3C
static func ftNessSpecialAirLwEndSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialLwEnd, fighter_gobj.anim_frame, 1.0, FTNESS_SPECIALLWEND_STATUS_FLAGS)

## 0x80155A7C
static func ftNessSpecialLwEndSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialAirLwEnd, fighter_gobj.anim_frame, 1.0, FTNESS_SPECIALLWEND_STATUS_FLAGS)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x80155AC8
static func ftNessSpecialLwEndSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialLwEnd, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80155B00
static func ftNessSpecialAirLwEndSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTNessStatusSpecialAirLwEnd, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
