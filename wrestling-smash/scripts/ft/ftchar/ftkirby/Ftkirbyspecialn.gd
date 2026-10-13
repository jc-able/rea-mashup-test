## 1:1 port of src/ft/ftchar/ftkirby/ftkirbyspecialn.c (ssb-decomp-re): Kirby's Inhale
## (vacuum, catch, eat, spit star, copy ability, lose copy).
##
## Pointer conventions:
##   ftKirbySpecialNGetCaptureDistance(kirby_pos: Vector3, victim_pos: Vector3) -> float
##   ftKirbySpecialNAddCaptureDistance(fp, fighter_gobj, pos = ignored) -> Vector3   (C: void, writes *pos)
##
## Shared data: llKirbyMainMotionSpecialNFTKirbyCopy is the FTKirbyCopy[27] table that C fetches
## with lbRelocGetFileData(FTKirbyCopy*, gFTDataKirbyMainMotion, &llKirbyMainMotionSpecialNFTKirbyCopy)
## (also used by ftmanager.c, efmanager.c and ftcommoncapturekirby.c).
class_name Ftkirbyspecialn
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

const FTKIRBY_SPECIALNSTART_STATUS_FLAGS := (FTSTATUS_PRESERVE_LOOPSFX | FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT)
const FTKIRBY_SPECIALNLOOP_STATUS_FLAGS := (FTSTATUS_PRESERVE_RUMBLE | FTSTATUS_PRESERVE_LOOPSFX | FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT | FTSTATUS_PRESERVE_HIT)

# // // // // // // // // // // // //
# //        RELOCATABLE DATA       //
# // // // // // // // // // // // //

## FTKirbyCopy dKirbyMainMotion_0x0000[27] - relocData 228_KirbyMainMotion.c @ 0x0000
## (llKirbyMainMotionSpecialNFTKirbyCopy). Indexed by the inhaled fighter's fkind (nFTKind*).
## { copy_id (u16), copy_modelpart_id (s16), effect_scale (f32), star_damage (s32) }
const llKirbyMainMotionSpecialNFTKirbyCopy: Array = [
	{"copy_id": nFTKindMario, "copy_modelpart_id": 12, "effect_scale": 1.5, "star_damage": 17},    # nFTKindMario
	{"copy_id": nFTKindFox, "copy_modelpart_id": 7, "effect_scale": 1.5, "star_damage": 17},       # nFTKindFox
	{"copy_id": nFTKindDonkey, "copy_modelpart_id": 4, "effect_scale": 2.0, "star_damage": 30},    # nFTKindDonkey
	{"copy_id": nFTKindSamus, "copy_modelpart_id": 8, "effect_scale": 1.6, "star_damage": 17},     # nFTKindSamus
	{"copy_id": nFTKindLuigi, "copy_modelpart_id": 11, "effect_scale": 1.6, "star_damage": 17},    # nFTKindLuigi
	{"copy_id": nFTKindLink, "copy_modelpart_id": 10, "effect_scale": 1.5, "star_damage": 17},     # nFTKindLink
	{"copy_id": nFTKindYoshi, "copy_modelpart_id": 5, "effect_scale": 1.7, "star_damage": 25},     # nFTKindYoshi
	{"copy_id": nFTKindCaptain, "copy_modelpart_id": 9, "effect_scale": 1.7, "star_damage": 17},   # nFTKindCaptain
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.6, "star_damage": 17},     # nFTKindKirby
	{"copy_id": nFTKindPikachu, "copy_modelpart_id": 6, "effect_scale": 1.5, "star_damage": 17},   # nFTKindPikachu
	{"copy_id": nFTKindPurin, "copy_modelpart_id": 3, "effect_scale": 1.6, "star_damage": 17},     # nFTKindPurin
	{"copy_id": nFTKindNess, "copy_modelpart_id": 13, "effect_scale": 1.6, "star_damage": 17},     # nFTKindNess
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.0, "star_damage": 17},     # nFTKindBoss
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.5, "star_damage": 17},     # nFTKindMMario
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.5, "star_damage": 17},     # nFTKindNMario
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.5, "star_damage": 17},     # nFTKindNFox
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 2.0, "star_damage": 30},     # nFTKindNDonkey
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.6, "star_damage": 17},     # nFTKindNSamus
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.6, "star_damage": 17},     # nFTKindNLuigi
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.5, "star_damage": 17},     # nFTKindNLink
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.7, "star_damage": 17},     # nFTKindNYoshi
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.7, "star_damage": 17},     # nFTKindNCaptain
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.6, "star_damage": 17},     # nFTKindNKirby
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.5, "star_damage": 17},     # nFTKindNPikachu
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.6, "star_damage": 17},     # nFTKindNPurin
	{"copy_id": nFTKindKirby, "copy_modelpart_id": 0, "effect_scale": 1.6, "star_damage": 17},     # nFTKindNNess
	{"copy_id": nFTKindDonkey, "copy_modelpart_id": 4, "effect_scale": 2.0, "star_damage": 50},    # nFTKindGDonkey
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80161CA0
static func ftKirbySpecialNApplyCaptureDamage(kirby_gobj = null, victim_gobj = null, damage = null) -> void:
	var kirby_fp := ftGetStruct(kirby_gobj)
	var victim_fp := ftGetStruct(victim_gobj)
	var star_damage_victim: int = Ftparam.ftParamGetStaledDamage(kirby_fp.player, damage, kirby_fp.motion_attack_id, kirby_fp.motion_count)

	damage = star_damage_victim

	Ftcommondamage.ftCommonDamageUpdateDamageColAnim(victim_gobj, Ftparam.ftParamGetCommonKnockback(victim_fp.percent_damage, star_damage_victim, star_damage_victim, 0, 100, 0, victim_fp.attr.weight, kirby_fp.handicap, victim_fp.handicap), 0)
	Ftparam.ftParamUpdateDamage(victim_fp, damage)
	Ftparam.ftParamUpdatePlayerBattleStats(kirby_fp.player, victim_fp.player, damage)
	Ftparam.ftParamUpdateStaleQueue(kirby_fp.player, victim_fp.player, kirby_fp.motion_attack_id, kirby_fp.motion_count)

## 0x80161D6C - distance between Kirby and inhale victim
static func ftKirbySpecialNGetCaptureDistance(kirby_pos = null, victim_pos = null) -> float:
	var dist_x: float = kirby_pos.x - victim_pos.x
	var dist_y: float = kirby_pos.y - victim_pos.y
	var dist_z: float = kirby_pos.z - victim_pos.z

	return (dist_x * dist_x) + (dist_y * dist_y) + (dist_z * dist_z)

## 0x80161DA8
## C writes *pos; the new value is returned (the pos argument is ignored).
static func ftKirbySpecialNAddCaptureDistance(fp = null, fighter_gobj = null, pos = null) -> Vector3:
	var out_pos: Vector3 = DObjGetStruct(fighter_gobj).translate

	out_pos.x += (160.0 * fp.lr)
	out_pos.y += 100.0

	return out_pos

## 0x80161E08
static func ftKirbySpecialNInitStatusVars(fighter_gobj = null, unused = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.motion_vars.flags.flag0 = 0
	fp.motion_vars.flags.flag2 = 0
	fp.motion_vars.flags.flag1 = 0

	fp.status_vars.kirby.specialn.copy_id = nFTKindKirby
	fp.status_vars.kirby.specialn.release_lag = FTKIRBY_VACUUM_RELEASE_LAG
	fp.status_vars.kirby.specialn.dist.x = 0.0
	fp.status_vars.kirby.specialn.dist.y = 0.0

## 0x80161E3C
static func ftKirbySpecialNSetCatchParams(fp = null) -> void:
	if fp.ga == nMPKineticsGround:
		Ftparam.ftParamSetCatchParams(fp, FTCATCHKIND_MASK_KIRBYSPECIALN, Callable(Ftkirbyspecialn, &"ftKirbySpecialNCatchProcCatch"), Callable(Ftcommoncapturekirby, &"ftCommonCaptureKirbyProcCapture"))
	else:
		Ftparam.ftParamSetCatchParams(fp, FTCATCHKIND_MASK_KIRBYSPECIALN, Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNCatchProcCatch"), Callable(Ftcommoncapturekirby, &"ftCommonCaptureKirbyProcCapture"))

## 0x80161E94
static func ftKirbySpecialNGotoSetCatchParams(fighter_gobj = null) -> void:
	ftKirbySpecialNSetCatchParams(ftGetStruct(fighter_gobj))

## 0x80161EB4
static func ftKirbySpecialNInitPassiveVars(fp = null) -> void:
	match fp.passive_vars.kirby.copy_id:
		nFTKindSamus:
			fp.passive_vars.kirby.copysamus_charge_level = 0
			fp.passive_vars.kirby.copysamus_charge_recoil = 0

		nFTKindDonkey:
			fp.passive_vars.kirby.copydonkey_charge_level = 0

		nFTKindCaptain:
			fp.passive_vars.kirby.copycaptain_falcon_punch_unk = 0

		nFTKindPurin:
			fp.passive_vars.kirby.copypurin_unk = 0

## 0x80161F0C
static func ftKirbySpecialNCopyInitCopyVars(fighter_gobj = null) -> void:
	var copy_id: int
	var fp := ftGetStruct(fighter_gobj)
	var copy: Array = llKirbyMainMotionSpecialNFTKirbyCopy

	if fp.motion_vars.flags.flag1 != 0:
		if fp.passive_vars.kirby.copy_id == fp.status_vars.kirby.specialn.copy_id:
			Snd.func_800269C0_275C0(nSYAudioFGMKirbySpecialNCopyUnk) # SFX?
		else:
			Snd.func_800269C0_275C0(nSYAudioFGMKirbySpecialNCopyThrow) # SFX?

			copy_id = fp.status_vars.kirby.specialn.copy_id
			fp.passive_vars.kirby.copy_id = copy_id

			Ftparam.ftParamSetModelPartDefaultID(fighter_gobj, FTKIRBY_COPY_MODELPARTS_JOINT, copy[copy_id].copy_modelpart_id)
			Ftparam.ftParamResetModelPartAll(fighter_gobj)
			ftKirbySpecialNInitPassiveVars(fp)

		fp.motion_vars.flags.flag1 = 0

## 0x80161FBC
static func ftKirbySpecialNStopEffect(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.is_effect_attach == TRUE:
		Ftparam.ftParamProcStopEffect(fighter_gobj)

## 0x80161FF8
static func ftKirbySpecialNStartProcUpdate(fighter_gobj = null) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialNLoopSetStatus"))

## 0x8016201C
static func ftKirbySpecialNLoopProcUpdate(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if not B(fp.is_effect_attach) and (fp.motion_vars.flags.flag0 == 1):
		if Efmanager.efManagerKirbyInhaleWindMakeEffect(fighter_gobj) != null:
			fp.motion_vars.flags.flag0 = 0
			fp.is_effect_attach = TRUE

## 0x80162078
static func ftKirbySpecialNCatchProcUpdate(fighter_gobj = null) -> void:
	var kirby_fp := ftGetStruct(fighter_gobj)
	var copy: Array = llKirbyMainMotionSpecialNFTKirbyCopy
	var victim_fp: Fighter
	var kirby_pos: Vector3
	var dist: float

	kirby_pos = ftKirbySpecialNAddCaptureDistance(kirby_fp, fighter_gobj)

	dist = ftKirbySpecialNGetCaptureDistance(DObjGetStruct(kirby_fp.catch_gobj).translate, kirby_pos)

	if dist < FTKIRBY_VACUUM_SPECIALNWAIT_DIST_MIN:
		victim_fp = ftGetStruct(kirby_fp.catch_gobj) # No NULL check?

		victim_fp.status_vars.common.capturekirby.is_goto_capturewait = TRUE

		if (victim_fp.fkind == nFTKindKirby) or (victim_fp.fkind == nFTKindNKirby):
			kirby_fp.status_vars.kirby.specialn.copy_id = victim_fp.passive_vars.kirby.copy_id
			victim_fp.status_vars.common.capturekirby.is_kirby = TRUE
		else:
			kirby_fp.status_vars.kirby.specialn.copy_id = copy[victim_fp.fkind].copy_id

		Snd.func_800269C0_275C0(nSYAudioFGMKirbySpecialNCopyEat)

		if kirby_fp.ga == nMPKineticsGround:
			ftKirbySpecialNEatSetStatus(fighter_gobj)
		else:
			ftKirbySpecialAirNEatSetStatus(fighter_gobj)

	elif dist < FTKIRBY_VACUUM_STOPGFX_DIST_MIN:
		ftKirbySpecialNStopEffect(fighter_gobj)

## 0x801621A8
static func ftKirbySpecialAirNStartProcUpdate(fighter_gobj = null) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNLoopSetStatus"))

## 0x801621CC
static func ftKirbySpecialNTurnProcUpdate(fighter_gobj = null) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialNWaitSetStatusFromTurn"))

## 0x801621F0
static func ftKirbySpecialAirNTurnProcUpdate(fighter_gobj = null) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNWaitSetStatusFromTurn"))

## 0x80162214
static func ftKirbySpecialNEatProcUpdate(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var proc_status: Callable = Callable(Ftkirbyspecialn, &"ftKirbySpecialNWaitSetStatusFromEat") if (fp.ga == nMPKineticsGround) else Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNWaitSetStatusFromEat")

	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, proc_status)

## 0x80162258
static func ftKirbySpecialNThrowUpdateCheckThrowStar(fighter_gobj = null) -> void:
	var kirby_fp := ftGetStruct(fighter_gobj)

	if kirby_fp.motion_vars.flags.flag2 != 0:
		if kirby_fp.catch_gobj != null:
			var victim_fp := ftGetStruct(kirby_fp.catch_gobj)

			Ftcommoncapturekirby.ftCommonThrownKirbyStarSetStatus(kirby_fp.catch_gobj)
			Ftparam.ftParamSetThrowParams(victim_fp, fighter_gobj)

			victim_fp.physics.vel_air.z = 0.0
			victim_fp.physics.vel_air.y = 0.0
			victim_fp.physics.vel_air.x = (-victim_fp.lr * FTKIRBY_VACUUM_THROW_VEL_BASE)

## 0x801622DC
static func ftKirbySpecialNCopyUpdateCheckCopyStar(fighter_gobj = null) -> void:
	var kirby_fp := ftGetStruct(fighter_gobj)

	if kirby_fp.motion_vars.flags.flag2 != 0:
		if kirby_fp.catch_gobj != null:
			var victim_fp := ftGetStruct(kirby_fp.catch_gobj)

			Ftcommoncapturekirby.ftCommonThrownCopyStarSetStatus(kirby_fp.catch_gobj)

			victim_fp.physics.vel_air.y = (__sinf(FTKIRBY_VACUUM_COPY_ANGLE) * FTKIRBY_VACUUM_COPY_VEL_BASE)
			victim_fp.physics.vel_air.x = (__cosf(FTKIRBY_VACUUM_COPY_ANGLE) * victim_fp.lr * FTKIRBY_VACUUM_COPY_VEL_BASE)
			victim_fp.physics.vel_air.z = 0.0

## 0x80162374
static func ftKirbySpecialNThrowProcUpdate(fighter_gobj = null) -> void:
	ftKirbySpecialNThrowUpdateCheckThrowStar(fighter_gobj)
	Ftanimend.ftAnimEndSetWait(fighter_gobj)

## 0x8016239C
static func ftKirbySpecialAirNThrowProcUpdate(fighter_gobj = null) -> void:
	ftKirbySpecialNThrowUpdateCheckThrowStar(fighter_gobj)
	Ftanimend.ftAnimEndSetFall(fighter_gobj)

## 0x801623C4
static func ftKirbySpecialNCopyProcUpdate(fighter_gobj = null) -> void:
	ftKirbySpecialNCopyInitCopyVars(fighter_gobj)
	ftKirbySpecialNCopyUpdateCheckCopyStar(fighter_gobj)
	Ftanimend.ftAnimEndSetWait(fighter_gobj)

## 0x801623F4
static func ftKirbySpecialAirNCopyProcUpdate(fighter_gobj = null) -> void:
	ftKirbySpecialNCopyInitCopyVars(fighter_gobj)
	ftKirbySpecialNCopyUpdateCheckCopyStar(fighter_gobj)
	Ftanimend.ftAnimEndSetFall(fighter_gobj)

## 0x80162424
static func ftKirbySpecialNLoopCheckContinueLoop(fighter_gobj = null) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.kirby.specialn.release_lag != 0:
		fp.status_vars.kirby.specialn.release_lag -= 1

		return TRUE

	elif fp.input.pl.button_hold & fp.input.button_mask_b:
		return TRUE

	else:
		return FALSE

## 0x80162468
static func ftKirbySpecialNLoopProcInterrupt(fighter_gobj = null) -> void:
	if ftKirbySpecialNLoopCheckContinueLoop(fighter_gobj) == FALSE:
		ftKirbySpecialNEndSetStatus(fighter_gobj)

## 0x80162498
static func ftKirbySpecialAirNLoopProcInterrupt(fighter_gobj = null) -> void:
	if ftKirbySpecialNLoopCheckContinueLoop(fighter_gobj) == FALSE:
		ftKirbySpecialAirNEndSetStatus(fighter_gobj)

## 0x801624C8
static func ftKirbySpecialNThrowCheckGotoThrow(fighter_gobj = null, proc_status = null) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if fp.input.pl.button_tap & fp.input.button_mask_a:
		if fp.catch_gobj != null:
			if fp.catch_gobj != null: # Now you check twice? Bruh.
				ftKirbySpecialNApplyCaptureDamage(fighter_gobj, fp.catch_gobj, FTKIRBY_VACUUM_THROW_DAMAGE)

			proc_status.call(fighter_gobj)

			return TRUE

	return FALSE

## 0x80162534
static func ftKirbySpecialNCopyCheckGotoCopy(fighter_gobj = null, proc_status = null) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.input.pl.button_tap & fp.input.button_mask_b) or (fp.input.pl.stick_range.y < FTKIRBY_VACUUM_COPY_STICK_RANGE_MIN):
		if fp.catch_gobj != null:
			if fp.catch_gobj != null:
				ftKirbySpecialNApplyCaptureDamage(fighter_gobj, fp.catch_gobj, FTKIRBY_VACUUM_COPY_DAMAGE)

			proc_status.call(fighter_gobj)

			return TRUE

	return FALSE

## 0x801625B0
static func ftKirbySpecialNTurnCheckGotoTurn(fighter_gobj = null, proc_status = null) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var stick_x: int = fp.input.pl.stick_range.x

	if ABS(stick_x) < FTKIRBY_VACUUM_TURN_STICK_RANGE_MIN:
		stick_x = 0 # HAL Meme Laboratory

	if ((stick_x < 0) and (fp.lr == +1)) or ((stick_x > 0) and (fp.lr == -1)):
		proc_status.call(fighter_gobj)

		return TRUE

	else:
		return FALSE

## 0x80162634
static func ftKirbySpecialNWaitProcInterrupt(fighter_gobj = null) -> void:
	if (ftKirbySpecialNThrowCheckGotoThrow(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialNThrowSetStatus")) == FALSE) and (ftKirbySpecialNCopyCheckGotoCopy(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialNCopySetStatus")) == FALSE):
		ftKirbySpecialNTurnCheckGotoTurn(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialNTurnSetStatus"))

## 0x80162684
static func ftKirbySpecialAirNWaitProcInterrupt(fighter_gobj = null) -> void:
	if ftKirbySpecialNThrowCheckGotoThrow(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNThrowSetStatus")) == FALSE:
		ftKirbySpecialNCopyCheckGotoCopy(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNCopySetStatus"))

## 0x801626C0
static func ftKirbySpecialAirNWaitProcPhysics(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if B(fp.is_fastfall):
		Ftphysics.ftPhysicsApplyFastFall(fp, attr)
	else:
		Ftphysics.ftPhysicsApplyGravityClampTVel(fp, FTKIRBY_VACUUM_GRAVITY_MUL * attr.gravity, FTKIRBY_VACUUM_FALL_MAX_MUL * attr.tvel_base)

	if not B(Ftphysics.ftPhysicsCheckClampAirVelXDecMax(fp, attr)):
		Ftphysics.ftPhysicsApplyAirVelXFriction(fp, attr)

## 0x80162750
static func ftKirbySpecialNStartProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialNStartSwitchStatusAir"))

## 0x80162774
static func ftKirbySpecialNLoopProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialNLoopSwitchStatusAir"))

## 0x80162798
static func ftKirbySpecialNEndProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialNEndSwitchStatusAir"))

## 0x801627BC
static func ftKirbySpecialNCatchProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialNCatchSwitchStatusAir"))

## 0x801627E0
static func ftKirbySpecialNEatProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialNEatSwitchStatusAir"))

## 0x80162804
static func ftKirbySpecialNThrowProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialNThrowSwitchStatusAir"))

## 0x80162828
static func ftKirbySpecialNWaitProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialNWaitSwitchStatusAir"))

## 0x8016284C
static func ftKirbySpecialNTurnProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialNTurnSwitchStatusAir"))

## 0x80162870
static func ftKirbySpecialNCopyProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnFloor(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialNCopySwitchStatusAir"))

## 0x80162894
static func ftKirbySpecialAirNStartProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNStartSwitchStatusGround"))

## 0x801628B8
static func ftKirbySpecialAirNLoopProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNLoopSwitchStatusGround"))

## 0x801628DC
static func ftKirbySpecialAirNEndProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNEndSwitchStatusGround"))

## 0x80162900
static func ftKirbySpecialAirNCatchProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNCatchSwitchStatusGround"))

## 0x80162924
static func ftKirbySpecialAirNEatProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNEatSwitchStatusGround"))

## 0x80162948
static func ftKirbySpecialAirNThrowProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNThrowSwitchStatusGround"))

## 0x8016296C
static func ftKirbySpecialAirNWaitProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNWaitSwitchStatusGround"))

## 0x80162990
static func ftKirbySpecialAirNTurnProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNTurnSwitchStatusGround"))

## 0x801629B4
static func ftKirbySpecialAirNCopyProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbyspecialn, &"ftKirbySpecialAirNCopySwitchStatusGround"))

## 0x801629D8
static func ftKirbySpecialAirNStartSwitchStatusGround(fighter_gobj = null) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialNStart, fighter_gobj.anim_frame, 1.0, FTKIRBY_SPECIALNSTART_STATUS_FLAGS)
	ftKirbySpecialNGotoSetCatchParams(fighter_gobj)

## 0x80162A20
static func ftKirbySpecialAirNLoopSwitchStatusGround(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialNLoop, fighter_gobj.anim_frame, 1.0, FTKIRBY_SPECIALNLOOP_STATUS_FLAGS)
	ftKirbySpecialNSetCatchParams(fp)

## 0x80162A6C
static func ftKirbySpecialAirNEndSwitchStatusGround(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialNEnd, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

## 0x80162ABC
static func ftKirbySpecialNStartSwitchStatusAir(fighter_gobj = null) -> void:
	Mpcommon.mpCommonSetFighterAir(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirNStart, fighter_gobj.anim_frame, 1.0, FTKIRBY_SPECIALNSTART_STATUS_FLAGS)
	ftKirbySpecialNGotoSetCatchParams(fighter_gobj)

## 0x80162B04
static func ftKirbySpecialNLoopSwitchStatusAir(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirNLoop, fighter_gobj.anim_frame, 1.0, FTKIRBY_SPECIALNLOOP_STATUS_FLAGS)
	ftKirbySpecialNSetCatchParams(fp)

## 0x80162B50
static func ftKirbySpecialNEndSwitchStatusAir(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirNEnd, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

## 0x80162BA0
static func ftKirbySpecialNEatSwitchStatusAir(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirNEat, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_EFFECT)
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

## 0x80162BF0
static func ftKirbySpecialNCatchSwitchStatusAir(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirNCatch, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

## 0x80162C40
static func ftKirbySpecialAirNCatchSwitchStatusGround(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialNCatch, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

## 0x80162C90
static func ftKirbySpecialAirNEatSwitchStatusGround(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialNEat, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_EFFECT)
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

## 0x80162CE0
static func ftKirbySpecialNThrowSwitchStatusAir(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirNThrow, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

## 0x80162D30
static func ftKirbySpecialAirNThrowSwitchStatusGround(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialNThrow, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

## 0x80162D80
static func ftKirbySpecialNWaitSwitchStatusAir(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirNWait, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

## 0x80162DD0
static func ftKirbySpecialAirNWaitSwitchStatusGround(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialNWait, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

## 0x80162E20
static func ftKirbySpecialNTurnSwitchStatusAir(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirNTurn, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

## 0x80162E70
static func ftKirbySpecialAirNTurnSwitchStatusGround(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialNTurn, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

## 0x80162EC0
static func ftKirbySpecialNCopySwitchStatusAir(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirNCopy, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

## 0x80162F10
static func ftKirbySpecialAirNCopySwitchStatusGround(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialNCopy, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

## 0x80162F60
static func ftKirbySpecialNWaitUpdateLR(fighter_gobj = null) -> void:
	var kirby_fp := ftGetStruct(fighter_gobj)

	if kirby_fp.catch_gobj != null:
		var victim_fp := ftGetStruct(kirby_fp.catch_gobj)

		victim_fp.lr = kirby_fp.lr

	kirby_fp.lr = int(kirby_fp.lr * -1.0) # Why is this a float operation? It gets converted back into signed long...

## 0x80162FA8
static func ftKirbySpecialNWaitSetStatusFromTurn(fighter_gobj = null) -> void:
	ftKirbySpecialNWaitUpdateLR(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialNWait, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

## 0x80162FE0
static func ftKirbySpecialAirNWaitSetStatusFromTurn(fighter_gobj = null) -> void:
	ftKirbySpecialNWaitUpdateLR(fighter_gobj)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirNWait, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

## 0x80163018
static func ftKirbySpecialNEatSetStatusParam(fighter_gobj = null, status_id = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var _pos := Vector3(0.0, 0.0, 0.0) # 0x80188E00 - Never used???

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_SLOPECONTOUR)
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

	if fp.proc_slope.is_valid():
		fp.proc_slope.call(fighter_gobj)

	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x801630A0
static func ftKirbySpecialNCatchEatSetStatusParam(fighter_gobj = null, status_id = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos: Vector3

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, (FTSTATUS_PRESERVE_LOOPSFX | FTSTATUS_PRESERVE_SLOPECONTOUR | FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)

	fp.catch_gobj = fp.search_gobj

	fp.is_catch_or_capture = FALSE

	if fp.proc_slope.is_valid():
		fp.proc_slope.call(fighter_gobj)

	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	pos = ftKirbySpecialNAddCaptureDistance(fp, fighter_gobj)

	fp.status_vars.kirby.specialn.dist.x = DObjGetStruct(fp.catch_gobj).translate.x - pos.x
	fp.status_vars.kirby.specialn.dist.y = DObjGetStruct(fp.catch_gobj).translate.y - pos.y

## 0x80163154
static func ftKirbySpecialNStartSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialNStart, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftKirbySpecialNInitStatusVars(fighter_gobj, FALSE)
	ftKirbySpecialNGotoSetCatchParams(fighter_gobj)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x801631A0
static func ftKirbySpecialNLoopSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialNLoop, 0.0, 1.0, (FTSTATUS_PRESERVE_LOOPSFX | FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	ftKirbySpecialNGotoSetCatchParams(fighter_gobj)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x801631E4
static func ftKirbySpecialNCatchProcCatch(fighter_gobj = null) -> void:
	ftKirbySpecialNCatchEatSetStatusParam(fighter_gobj, nFTKirbyStatusSpecialNCatch)

## 0x80163204
static func ftKirbySpecialNEatSetStatus(fighter_gobj = null) -> void:
	ftKirbySpecialNEatSetStatusParam(fighter_gobj, nFTKirbyStatusSpecialNEat)

## 0x80163224
static func ftKirbySpecialNThrowSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialNThrow, 0.0, 1.0, (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80163274
static func ftKirbySpecialNWaitSetStatusFromEat(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialNWait, 0.0, 1.0, (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_MODELPART))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x801632C4
static func ftKirbySpecialNTurnSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialNTurn, 0.0, 1.0, (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80163314
static func ftKirbySpecialNCopySetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialNCopy, 0.0, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80163364
static func ftKirbySpecialNEndSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialNEnd, 0.0, 1.0, FTSTATUS_PRESERVE_EFFECT)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x801633A0
static func ftKirbySpecialAirNStartSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirNStart, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	ftKirbySpecialNInitStatusVars(fighter_gobj, TRUE)
	ftKirbySpecialNGotoSetCatchParams(fighter_gobj)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x801633EC
static func ftKirbySpecialAirNLoopSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirNLoop, 0.0, 1.0, (FTSTATUS_PRESERVE_LOOPSFX | FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	ftKirbySpecialNGotoSetCatchParams(fighter_gobj)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80163430
static func ftKirbySpecialAirNCatchProcCatch(fighter_gobj = null) -> void:
	ftKirbySpecialNCatchEatSetStatusParam(fighter_gobj, nFTKirbyStatusSpecialAirNCatch)

## 0x80163450
static func ftKirbySpecialAirNEatSetStatus(fighter_gobj = null) -> void:
	ftKirbySpecialNEatSetStatusParam(fighter_gobj, nFTKirbyStatusSpecialAirNEat)

## 0x80163470
static func ftKirbySpecialAirNThrowSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirNThrow, 0.0, 1.0, (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x801634C0
static func ftKirbySpecialAirNWaitSetStatusFromEat(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirNWait, 0.0, 1.0, (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_MODELPART))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80163510
static func ftKirbySpecialAirNTurnSetStatus(fighter_gobj = null) -> void: # Unused
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirNTurn, 0.0, 1.0, (FTSTATUS_PRESERVE_TEXTUREPART | FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x80163560
static func ftKirbySpecialAirNCopySetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirNCopy, 0.0, 1.0, (FTSTATUS_PRESERVE_MODELPART | FTSTATUS_PRESERVE_EFFECT))
	Ftparam.ftParamSetCaptureImmuneMask(fp, FTCATCHKIND_MASK_ALL)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x801635B0
static func ftKirbySpecialAirNEndSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusSpecialAirNEnd, 0.0, 1.0, FTSTATUS_PRESERVE_EFFECT)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

## 0x801635EC
static func ftKirbySpecialNLoseCopy(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	ftKirbySpecialNInitPassiveVars(fp)
	Efmanager.efManagerLoseKirbyStarMakeEffect(fighter_gobj)
	Snd.func_800269C0_275C0(nSYAudioFGMKirbySpecialNLoseCopy)

	fp.passive_vars.kirby.copy_id = nFTKindKirby

	Ftparam.ftParamSetModelPartDefaultID(fighter_gobj, 6, 0)
	Ftparam.ftParamResetStatUpdateColAnim(fighter_gobj)

## 0x80163648
static func ftKirbySpecialNDamageCheckLoseCopy(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (
		(
			(fp.fkind == nFTKindKirby) or
			(fp.fkind == nFTKindNKirby)
		) and
		(fp.passive_vars.kirby.copy_id != nFTKindKirby) and
		(fp.passive_vars.kirby.is_ignore_losecopy == FALSE) and
		(syUtilsRandFloat() < FTKIRBY_COPYDAMAGE_LOSECOPY_RANDOM)
	):
		ftKirbySpecialNLoseCopy(fighter_gobj)
