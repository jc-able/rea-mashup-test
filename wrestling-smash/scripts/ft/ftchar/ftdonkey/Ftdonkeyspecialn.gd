## 1:1 port of src/ft/ftchar/ftdonkey/ftdonkeyspecialn.c (ssb-decomp-re).
## Donkey Kong neutral special (Giant Punch).
class_name Ftdonkeyspecialn
extends Port

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8015AF10 - Reset Giant Punch charge level
static func ftDonkeySpecialNProcDamage(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.passive_vars.donkey.charge_level = 0

## 0x8015AF1C
static func ftDonkeySpecialNStartProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftdonkeyspecialn, &"ftDonkeySpecialNLoopSetStatus"))

## 0x8015AF40
static func ftDonkeySpecialAirNStartProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftdonkeyspecialn, &"ftDonkeySpecialAirNLoopSetStatus"))

## 0x8015AF64
static func ftDonkeySpecialNStartProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.input.pl.button_tap & (fp.input.button_mask_b | fp.input.button_mask_a):
		fp.status_vars.donkey.specialn.is_release = TRUE

## 0x8015AF94
static func ftDonkeySpecialNStartProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftdonkeyspecialn, &"ftDonkeySpecialNStartSwitchStatusAir"))

## 0x8015AFB8
static func ftDonkeySpecialAirNStartProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftdonkeyspecialn, &"ftDonkeySpecialAirNStartSwitchStatusGround"))

## 0x8015AFDC
static func ftDonkeySpecialAirNStartSwitchStatusGround(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusSpecialNStart, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_COLANIM)

	fp.proc_damage = Callable(Ftdonkeyspecialn, &"ftDonkeySpecialNProcDamage")

## 0x8015B030
static func ftDonkeySpecialNStartSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusSpecialAirNStart, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_COLANIM)

	fp.proc_damage = Callable(Ftdonkeyspecialn, &"ftDonkeySpecialNProcDamage")

	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x8015B088
static func ftDonkeySpecialNLoopProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fighter_gobj.anim_frame >= 0.0) and (fighter_gobj.anim_frame < DObjGetStruct(fighter_gobj).anim_speed):
		if fp.status_vars.donkey.specialn.is_charging != FALSE:
			if fp.passive_vars.donkey.charge_level < FTDONKEY_GIANTPUNCH_CHARGE_MAX:
				fp.passive_vars.donkey.charge_level += 1

				if fp.passive_vars.donkey.charge_level == FTDONKEY_GIANTPUNCH_CHARGE_MAX:
					ObjAnim.gcSetAnimSpeed(fighter_gobj, FTDONKEY_GIANTPUNCH_CHRAGE_ANIM_SPEED)

					Ftparam.ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterCommonSpecialNCharge, 0)

					fp.status_vars.donkey.specialn.is_cancel = TRUE
		if fp.status_vars.donkey.specialn.is_cancel != FALSE:
			Mpcommon.mpCommonSetFighterWaitOrFall(fighter_gobj)
		elif fp.status_vars.donkey.specialn.is_release != FALSE:
			if fp.ga == nMPKineticsAir:
				ftDonkeySpecialAirNEndSetStatus(fighter_gobj)
			else:
				ftDonkeySpecialNEndSetStatus(fighter_gobj)
		else:
			fp.status_vars.donkey.specialn.is_charging = TRUE

## 0x8015B188
static func ftDonkeySpecialNLoopProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.ga != nMPKineticsGround) or (Ftcommonescape.ftCommonEscapeCheckInterruptSpecialNDonkey(fighter_gobj) == FALSE):
		if fp.input.pl.button_tap & (fp.input.button_mask_b | fp.input.button_mask_a):
			fp.status_vars.donkey.specialn.is_release = TRUE
		if fp.input.pl.button_tap & fp.input.button_mask_z:
			fp.status_vars.donkey.specialn.is_cancel = TRUE

## 0x8015B1FC
static func ftDonkeySpecialNLoopProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftdonkeyspecialn, &"ftDonkeySpecialNLoopSwitchStatusAir"))

## 0x8015B220
static func ftDonkeySpecialAirNLoopProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftdonkeyspecialn, &"ftDonkeySpecialAirNLoopSwitchStatusGround"))

## 0x8015B244
static func ftDonkeySpecialNLoopSetProcDamageAnimSpeed(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_damage = Callable(Ftdonkeyspecialn, &"ftDonkeySpecialNProcDamage")

	if fp.passive_vars.donkey.charge_level == FTDONKEY_GIANTPUNCH_CHARGE_MAX:
		ObjAnim.gcSetAnimSpeed(fighter_gobj, FTDONKEY_GIANTPUNCH_CHRAGE_ANIM_SPEED)

## 0x8015B284
static func ftDonkeySpecialAirNLoopSwitchStatusGround(fighter_gobj) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusSpecialNLoop, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_RUMBLE | FTSTATUS_PRESERVE_COLANIM))
	ftDonkeySpecialNLoopSetProcDamageAnimSpeed(fighter_gobj)

## 0x8015B2CC
static func ftDonkeySpecialNLoopSwitchStatusAir(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusSpecialAirNLoop, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_RUMBLE | FTSTATUS_PRESERVE_COLANIM))
	ftDonkeySpecialNLoopSetProcDamageAnimSpeed(fighter_gobj)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x8015B320
static func ftDonkeySpecialNLoopSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusSpecialNLoop, 0.0, 1.0, FTSTATUS_PRESERVE_COLANIM)
	ftDonkeySpecialNLoopSetProcDamageAnimSpeed(fighter_gobj)

## 0x8015B35C
static func ftDonkeySpecialAirNLoopSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusSpecialAirNLoop, 0.0, 1.0, (FTSTATUS_PRESERVE_FASTFALL | FTSTATUS_PRESERVE_COLANIM))
	ftDonkeySpecialNLoopSetProcDamageAnimSpeed(fighter_gobj)

## 0x8015B398
static func ftDonkeySpecialNEndProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fighter_gobj.anim_frame <= 0.0:
		Mpcommon.mpCommonSetFighterWaitOrFall(fighter_gobj)
	elif (fp.status_id == nFTDonkeyStatusSpecialNEnd) or (fp.status_id == nFTDonkeyStatusSpecialAirNEnd):
		var i: int = 0

		while i < fp.attack_colls.size():
			var attack_coll: FTAttackColl = fp.attack_colls[i]

			if attack_coll.attack_state == nGMAttackStateNew:
				attack_coll.damage += fp.status_vars.donkey.specialn.charge_level * FTDONKEY_GIANTPUNCH_CHARGE_DAMAGE_MUL
			i += 1

## 0x8015B488
static func ftDonkeySpecialAirNEndProcMap(fighter_gobj) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftdonkeyspecialn, &"ftDonkeySpecialAirNEndSwitchStatusGround"))

## 0x8015B4AC
static func ftDonkeySpecialAirNEndSwitchStatusGround(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int

	Mpcommon.mpCommonSetFighterGround(fp)

	status_id = nFTDonkeyStatusSpecialNEnd if (fp.status_id == nFTDonkeyStatusSpecialAirNEnd) else nFTDonkeyStatusSpecialNFull

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_COLANIM | FTSTATUS_PRESERVE_HIT))

## 0x8015B508
static func ftDonkeySpecialNGetStatusChargeLevelReset(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.donkey.specialn.charge_level = fp.passive_vars.donkey.charge_level

	fp.passive_vars.donkey.charge_level = 0

## 0x8015B51C
static func ftDonkeySpecialNEndSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	var status_id: int = nFTDonkeyStatusSpecialNFull if (fp.passive_vars.donkey.charge_level == FTDONKEY_GIANTPUNCH_CHARGE_MAX) else nFTDonkeyStatusSpecialNEnd

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_COLANIM)

	fp.physics.vel_ground.x = fp.passive_vars.donkey.charge_level * FTDONKEY_GIANTPUNCH_VEL_MUL

	ftDonkeySpecialNGetStatusChargeLevelReset(fighter_gobj)

## 0x8015B598
static func ftDonkeySpecialAirNEndSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	var status_id: int = nFTDonkeyStatusSpecialAirNFull if (fp.passive_vars.donkey.charge_level == FTDONKEY_GIANTPUNCH_CHARGE_MAX) else nFTDonkeyStatusSpecialAirNEnd

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, (FTSTATUS_PRESERVE_FASTFALL | FTSTATUS_PRESERVE_COLANIM))

	ftDonkeySpecialNGetStatusChargeLevelReset(fighter_gobj)

## 0x8015B5EC
static func ftDonkeySpecialNInitStatusVars(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.donkey.specialn.is_release = TRUE if (fp.passive_vars.donkey.charge_level == FTDONKEY_GIANTPUNCH_CHARGE_MAX) else FALSE

	fp.status_vars.donkey.specialn.is_charging = FALSE
	fp.status_vars.donkey.specialn.is_cancel = FALSE

## 0x8015B61C
static func ftDonkeySpecialNStartSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusSpecialNStart, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.proc_damage = Callable(Ftdonkeyspecialn, &"ftDonkeySpecialNProcDamage")

	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftDonkeySpecialNInitStatusVars(fighter_gobj)

## 0x8015B674
static func ftDonkeySpecialAirNStartSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusSpecialAirNStart, 0.0, 1.0, FTSTATUS_PRESERVE_FASTFALL)

	fp.proc_damage = Callable(Ftdonkeyspecialn, &"ftDonkeySpecialNProcDamage")

	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftDonkeySpecialNInitStatusVars(fighter_gobj)
