## Port of src/ft/ftchar/ftfox/ftfoxspeciallw.c (Fox down special: Reflector).
class_name Ftfoxspeciallw
extends Port

# // // // // // // // // // // // //
# //            DATA               //
# // // // // // // // // // // // //

## FTSpecialColl at gFTDataFoxMainMotion + llFoxMainMotionLwReflectorFTSpecialColl
## (src/relocData/208_FoxMainMotion.c: dFoxMainMotion_LwReflectorFTSpecialColl, US file offset 0x19B0;
## verified against the ROM's file 208). C points fp->special_coll at this read-only file data.
static var dFoxMainMotionLwReflectorFTSpecialColl: FTSpecialColl = FTSpecialColl.make(
	0,                                  # kind
	4,                                  # joint_id
	Vector3(0.0, 60.0, 0.0),            # offset
	Vector3(350.0, 350.0, 350.0),       # size
	50                                  # damage_resist
)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8015CB80
static func ftFoxSpecialLwCheckSetRelease(fp) -> void:
	if not (fp.input.pl.button_hold & fp.input.button_mask_b):
		fp.status_vars.fox.speciallw.is_release = TRUE

## 0x8015CBA4
static func ftFoxSpecialLwUpdateEffect(fp) -> void:
	if fp.motion_vars.flags.flag2 != 4:
		if fp.status_vars.fox.speciallw.effect_gobj != null:
			var ep = fp.status_vars.fox.speciallw.effect_gobj.user_data   # efGetStruct(effect_gobj)

			ep.effect_vars.reflector.status = fp.motion_vars.flags.flag2

		fp.motion_vars.flags.flag2 = 4

## 0x8015CBD4
static func ftFoxSpecialLwDecReleaseLag(fp) -> void:
	if fp.status_vars.fox.speciallw.release_lag != 0:
		fp.status_vars.fox.speciallw.release_lag -= 1

## 0x8015CBEC
static func ftFoxSpecialLwStartProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftFoxSpecialLwUpdateEffect(fp)
	ftFoxSpecialLwCheckSetRelease(fp)

	if fighter_gobj.anim_frame <= 0.0:
		if fp.ga == FALSE:
			ftFoxSpecialLwLoopSetStatus(fighter_gobj)
		else:
			ftFoxSpecialAirLwLoopSetStatus(fighter_gobj)

## 0x8015CC64
static func ftFoxSpecialAirLwCommonProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if fp.status_vars.fox.speciallw.gravity_delay != 0:
		fp.status_vars.fox.speciallw.gravity_delay -= 1
	else:
		Ftphysics.ftPhysicsApplyGravityClampTVel(fp, FTFOX_REFLECTOR_GRAVITY, attr.tvel_base)

	if Ftphysics.ftPhysicsCheckClampAirVelXDecMax(fp, attr) == FALSE:
		Ftphysics.ftPhysicsApplyAirVelXFriction(fp, attr)

## 0x8015CCE0
static func ftFoxSpecialLwLoopProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftFoxSpecialLwUpdateEffect(fp)
	ftFoxSpecialLwCheckSetRelease(fp)
	ftFoxSpecialLwDecReleaseLag(fp)

	if (fp.status_vars.fox.speciallw.release_lag <= 0) and (fp.status_vars.fox.speciallw.is_release != FALSE):
		if fp.ga == nMPKineticsGround:
			ftFoxSpecialLwEndSetStatus(fighter_gobj)
		else:
			ftFoxSpecialAirLwEndSetStatus(fighter_gobj)

## 0x8015CD5C
static func ftFoxSpecialLwLoopProcInterrupt(fighter_gobj) -> void:
	ftFoxSpecialLwTurnCheckInterruptLoop(fighter_gobj)

## 0x8015CD7C
static func ftFoxSpecialLwLoopSetReflectFlag(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.is_reflect = TRUE

## 0x8015CD90
static func ftFoxSpecialLwLoopSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialLwLoop, 0.0, 1.0, (FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM))
	ftFoxSpecialLwLoopSetReflectFlag(fighter_gobj)

## 0x8015CDCC
static func ftFoxSpecialAirLwLoopSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialAirLwLoop, 0.0, 1.0, (FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM))
	ftFoxSpecialLwLoopSetReflectFlag(fighter_gobj)

## 0x8015CE08
static func ftFoxSpecialLwHitDecideSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.status_vars.fox.speciallw.release_lag <= 0) and (fp.status_vars.fox.speciallw.is_release != FALSE):
		if fp.ga == nMPKineticsGround:
			ftFoxSpecialLwEndSetStatus(fighter_gobj)
		else:
			ftFoxSpecialAirLwEndSetStatus(fighter_gobj)
	elif fp.ga == nMPKineticsGround:
		ftFoxSpecialLwLoopSetStatus(fighter_gobj)
	else:
		ftFoxSpecialAirLwLoopSetStatus(fighter_gobj)

## 0x8015CE8C
static func ftFoxSpecialLwHitProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftFoxSpecialLwUpdateEffect(fp)
	ftFoxSpecialLwCheckSetRelease(fp)
	ftFoxSpecialLwDecReleaseLag(fp)

	if fighter_gobj.anim_frame <= 0.0:
		ftFoxSpecialLwHitDecideSetStatus(fighter_gobj)

## 0x8015CEE8
static func ftFoxSpecialLwHitSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.lr = fp.reflect_lr

	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialLwHit if (fp.ga == nMPKineticsGround) else nFTFoxStatusSpecialAirLwHit, 0.0, 1.0, (FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM))

	fp.is_reflect = TRUE

## 0x8015CF50
static func ftFoxSpecialLwTurnDecTurnFrames(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.fox.speciallw.turn_tics -= 1

	if (fp.motion_vars.flags.flag1 == 0) and (fp.status_vars.fox.speciallw.turn_tics <= FTFOX_REFLECTOR_TURN_FRAMES):
		fp.motion_vars.flags.flag1 = 1
		fp.lr = -fp.lr

	fp.joints[nFTPartsJointTopN].rotate.y += (F_CLC_DTOR32(-(180.0 / float(FTFOX_REFLECTOR_TURN_FRAMES))))

	Ftparam.ftParamsUpdateFighterPartsTransformAll(fp.joints[nFTPartsJointTopN])

## 0x8015CFC0
static func ftFoxSpecialLwTurnProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftFoxSpecialLwUpdateEffect(fp)
	ftFoxSpecialLwCheckSetRelease(fp)
	ftFoxSpecialLwDecReleaseLag(fp)
	ftFoxSpecialLwTurnDecTurnFrames(fighter_gobj)

	if fp.status_vars.fox.speciallw.turn_tics <= 0:
		ftFoxSpecialLwHitDecideSetStatus(fighter_gobj)

## 0x8015D01C
static func ftFoxSpecialLwTurnInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.is_reflect = TRUE
	fp.status_vars.fox.speciallw.turn_tics = FTFOX_REFLECTOR_TURN_FRAMES
	fp.motion_vars.flags.flag1 = 0

	ftFoxSpecialLwTurnDecTurnFrames(fighter_gobj)

## 0x8015D054
static func ftFoxSpecialLwTurnSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialLwTurn, 0.0, 1.0, (FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM))
	ftFoxSpecialLwTurnInitStatusVars(fighter_gobj)

## 0x8015D090
static func ftFox_SpecialAirLwTurn_SetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialAirLwTurn, 0.0, 1.0, (FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM))
	ftFoxSpecialLwTurnInitStatusVars(fighter_gobj)

## 0x8015D0CC
static func ftFoxSpecialLwTurnCheckInterruptLoop(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if Ftcommonturn.ftCommonTurnCheckInputSuccess(fighter_gobj) != FALSE:
		if fp.ga == nMPKineticsGround:
			ftFoxSpecialLwTurnSetStatus(fighter_gobj)

			return TRUE
		else:
			ftFox_SpecialAirLwTurn_SetStatus(fighter_gobj)

		return TRUE
	else:
		return FALSE

## 0x8015D130
static func ftFoxSpecialLwEndProcUpdate(fighter_gobj) -> void:
	ftFoxSpecialLwUpdateEffect(ftGetStruct(fighter_gobj))

	if fighter_gobj.anim_frame <= 0.0:
		Ftparam.ftParamProcStopEffect(fighter_gobj)
		Mpcommon.mpCommonSetFighterWaitOrFall(fighter_gobj)

## 0x8015D180
static func ftFoxSpecialLwEndSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialLwEnd, 0.0, 1.0, (FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM))

## 0x8015D1B0
static func ftFoxSpecialAirLwEndSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialAirLwEnd, 0.0, 1.0, (FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_COLANIM))

## 0x8015D1E0
static func ftFoxSpecialLwStartInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.fox.speciallw.release_lag = FTFOX_REFLECTOR_RELEASE_LAG
	fp.status_vars.fox.speciallw.is_release = FALSE
	fp.motion_vars.flags.flag2 = 4
	fp.status_vars.fox.speciallw.gravity_delay = FTFOX_REFLECTOR_GRAVITY_DELAY

	fp.status_vars.fox.speciallw.effect_gobj = Efmanager.efManagerFoxReflectorMakeEffect(fighter_gobj)

	if fp.status_vars.fox.speciallw.effect_gobj != null:
		fp.is_effect_attach = TRUE

	fp.special_coll = dFoxMainMotionLwReflectorFTSpecialColl

## 0x8015D250
static func ftFoxSpecialLwStartSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialLwStart, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftFoxSpecialLwStartInitStatusVars(fighter_gobj)

## 0x8015D290
static func ftFoxSpecialAirLwStartSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTFoxStatusSpecialAirLwStart, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftFoxSpecialLwStartInitStatusVars(fighter_gobj)

	fp.physics.vel_air.y = 0.0
	fp.physics.vel_air.x /= 2
