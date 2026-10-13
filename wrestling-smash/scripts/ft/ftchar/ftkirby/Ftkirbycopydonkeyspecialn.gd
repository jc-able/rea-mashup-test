## 1:1 port of src/ft/ftchar/ftkirby/ftkirbycopydonkeyspecialn.c (ssb-decomp-re): Kirby's copied
## Donkey Kong Giant Punch.
class_name Ftkirbycopydonkeyspecialn
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x801577A0
static func ftKirbyCopyDonkeySpecialNProcDamage(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.passive_vars.kirby.copydonkey_charge_level = 0

## 0x801577AC
static func ftKirbyCopyDonkeySpecialNStartProcUpdate(fighter_gobj = null) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftkirbycopydonkeyspecialn, &"ftKirbyCopyDonkeySpecialNLoopSetStatus"))

## 0x801577D0
static func ftKirbyCopyDonkeySpecialAirNStartProcUpdate(fighter_gobj = null) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftkirbycopydonkeyspecialn, &"ftKirbyCopyDonkeySpecialAirNLoopSetStatus"))

## 0x801577F4
static func ftKirbyCopyDonkeySpecialNStartProcInterrupt(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.input.pl.button_tap & (fp.input.button_mask_b | fp.input.button_mask_a):
		fp.status_vars.kirby.copydonkey_specialn.is_release = TRUE

## 0x80157824
static func ftKirbyCopyDonkeySpecialNStartProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftkirbycopydonkeyspecialn, &"ftKirbyCopyDonkeySpecialNStartSwitchStatusAir"))

## 0x80157848
static func ftKirbyCopyDonkeySpecialAirNStartProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbycopydonkeyspecialn, &"ftKirbyCopyDonkeySpecialAirNStartSwitchStatusGround"))

## 0x8015786C
static func ftKirbyCopyDonkeySpecialAirNStartSwitchStatusGround(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyDonkeySpecialNStart, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_COLANIM)

	fp.proc_damage = Callable(Ftkirbycopydonkeyspecialn, &"ftKirbyCopyDonkeySpecialNProcDamage")

## 0x801578C0
static func ftKirbyCopyDonkeySpecialNStartSwitchStatusAir(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyDonkeySpecialAirNStart, fighter_gobj.anim_frame, 1.0, FTSTATUS_PRESERVE_COLANIM)

	fp.proc_damage = Callable(Ftkirbycopydonkeyspecialn, &"ftKirbyCopyDonkeySpecialNProcDamage")

	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x80157918
static func ftKirbyCopyDonkeySpecialNLoopProcUpdate(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fighter_gobj.anim_frame >= 0.0) and (fighter_gobj.anim_frame < DObjGetStruct(fighter_gobj).anim_speed):
		if fp.status_vars.kirby.copydonkey_specialn.is_charging != FALSE:
			if fp.passive_vars.kirby.copydonkey_charge_level < FTKIRBY_COPYDONKEY_GIANTPUNCH_CHARGE_MAX:
				fp.passive_vars.kirby.copydonkey_charge_level += 1

				if fp.passive_vars.kirby.copydonkey_charge_level == FTKIRBY_COPYDONKEY_GIANTPUNCH_CHARGE_MAX:
					ObjAnim.gcSetAnimSpeed(fighter_gobj, FTKIRBY_COPYDONKEY_GIANTPUNCH_CHRAGE_ANIM_SPEED)

					Ftparam.ftParamCheckSetFighterColAnimID(fighter_gobj, nGMColAnimFighterCommonSpecialNCharge, 0)

					fp.status_vars.kirby.copydonkey_specialn.is_cancel = TRUE

		if fp.status_vars.kirby.copydonkey_specialn.is_cancel != FALSE:
			Mpcommon.mpCommonSetFighterWaitOrFall(fighter_gobj)

		elif fp.status_vars.kirby.copydonkey_specialn.is_release != FALSE:
			if fp.ga == nMPKineticsAir:
				ftKirbyCopyDonkeySpecialAirNEndSetStatus(fighter_gobj)
			else:
				ftKirbyCopyDonkeySpecialNEndSetStatus(fighter_gobj)

		else:
			fp.status_vars.kirby.copydonkey_specialn.is_charging = TRUE

## 0x80157A18
static func ftKirbyCopyDonkeySpecialNLoopProcInterrupt(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.ga != nMPKineticsGround) or not B(Ftcommonescape.ftCommonEscapeCheckInterruptSpecialNDonkey(fighter_gobj)):
		if fp.input.pl.button_tap & (fp.input.button_mask_b | fp.input.button_mask_a):
			fp.status_vars.kirby.copydonkey_specialn.is_release = TRUE

		if fp.input.pl.button_tap & fp.input.button_mask_z:
			fp.status_vars.kirby.copydonkey_specialn.is_cancel = TRUE

## 0x80157A8C
static func ftKirbyCopyDonkeySpecialNLoopProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterOnEdge(fighter_gobj, Callable(Ftkirbycopydonkeyspecialn, &"ftKirbyCopyDonkeySpecialNLoopSwitchStatusAir"))

## 0x80157AB0
static func ftKirbyCopyDonkeySpecialAirNLoopProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbycopydonkeyspecialn, &"ftKirbyCopyDonkeySpecialAirNLoopSwitchStatusGround"))

## 0x80157AD4
static func ftKirbyCopyDonkeySpecialNLoopSetProcDamageAnimSpeed(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.proc_damage = Callable(Ftkirbycopydonkeyspecialn, &"ftKirbyCopyDonkeySpecialNProcDamage")

	if fp.passive_vars.kirby.copydonkey_charge_level == FTKIRBY_COPYDONKEY_GIANTPUNCH_CHARGE_MAX:
		ObjAnim.gcSetAnimSpeed(fighter_gobj, FTKIRBY_COPYDONKEY_GIANTPUNCH_CHRAGE_ANIM_SPEED)

## 0x80157B14
static func ftKirbyCopyDonkeySpecialAirNLoopSwitchStatusGround(fighter_gobj = null) -> void:
	Mpcommon.mpCommonSetFighterGround(ftGetStruct(fighter_gobj))
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyDonkeySpecialNLoop, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_RUMBLE | FTSTATUS_PRESERVE_COLANIM))
	ftKirbyCopyDonkeySpecialNLoopSetProcDamageAnimSpeed(fighter_gobj)

## 0x80157B5C
static func ftKirbyCopyDonkeySpecialNLoopSwitchStatusAir(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterAir(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyDonkeySpecialAirNLoop, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_RUMBLE | FTSTATUS_PRESERVE_COLANIM))
	ftKirbyCopyDonkeySpecialNLoopSetProcDamageAnimSpeed(fighter_gobj)
	Ftphysics.ftPhysicsClampAirVelXMax(fp)

## 0x80157BB0
static func ftKirbyCopyDonkeySpecialNLoopSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyDonkeySpecialNLoop, 0.0, 1.0, FTSTATUS_PRESERVE_COLANIM)
	ftKirbyCopyDonkeySpecialNLoopSetProcDamageAnimSpeed(fighter_gobj)

## 0x80157BEC
static func ftKirbyCopyDonkeySpecialAirNLoopSetStatus(fighter_gobj = null) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyDonkeySpecialAirNLoop, 0.0, 1.0, (FTSTATUS_PRESERVE_FASTFALL | FTSTATUS_PRESERVE_COLANIM))
	ftKirbyCopyDonkeySpecialNLoopSetProcDamageAnimSpeed(fighter_gobj)

## 0x80157C28
static func ftKirbyCopyDonkeySpecialNEndProcUpdate(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fighter_gobj.anim_frame <= 0.0:
		Mpcommon.mpCommonSetFighterWaitOrFall(fighter_gobj)

	elif (fp.status_id == nFTKirbyStatusCopyDonkeySpecialNEnd) or (fp.status_id == nFTKirbyStatusCopyDonkeySpecialAirNEnd):
		for i in fp.attack_colls.size():
			var attack_coll: FTAttackColl = fp.attack_colls[i]

			if attack_coll.attack_state == nGMAttackStateNew:
				attack_coll.damage += fp.status_vars.kirby.copydonkey_specialn.charge_level * FTKIRBY_COPYDONKEY_GIANTPUNCH_CHARGE_DAMAGE_MUL

## 0x80157D18
static func ftKirbyCopyDonkeySpecialAirNEndProcMap(fighter_gobj = null) -> void:
	Mpcommon.mpCommonProcFighterLanding(fighter_gobj, Callable(Ftkirbycopydonkeyspecialn, &"ftKirbyCopyDonkeySpecialAirNEndSwitchStatusGround"))

## 0x80157D3C
static func ftKirbyCopyDonkeySpecialAirNEndSwitchStatusGround(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int

	Mpcommon.mpCommonSetFighterGround(fp)

	status_id = nFTKirbyStatusCopyDonkeySpecialNEnd if (fp.status_id == nFTKirbyStatusCopyDonkeySpecialAirNEnd) else nFTKirbyStatusCopyDonkeySpecialNFull

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, fighter_gobj.anim_frame, 1.0, (FTSTATUS_PRESERVE_COLANIM | FTSTATUS_PRESERVE_HIT))

## 0x80157D98
static func ftKirbyCopyDonkeySpecialNGetStatusChargeLevelReset(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.kirby.copydonkey_specialn.charge_level = fp.passive_vars.kirby.copydonkey_charge_level

	fp.passive_vars.kirby.copydonkey_charge_level = 0

## 0x80157DAC
static func ftKirbyCopyDonkeySpecialNEndSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	var status_id: int = nFTKirbyStatusCopyDonkeySpecialNFull if (fp.passive_vars.kirby.copydonkey_charge_level == FTKIRBY_COPYDONKEY_GIANTPUNCH_CHARGE_MAX) else nFTKirbyStatusCopyDonkeySpecialNEnd

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, FTSTATUS_PRESERVE_COLANIM)

	fp.physics.vel_ground.x = fp.passive_vars.kirby.copydonkey_charge_level * FTKIRBY_COPYDONKEY_GIANTPUNCH_VEL_MUL

	ftKirbyCopyDonkeySpecialNGetStatusChargeLevelReset(fighter_gobj)

## 0x80157E28
static func ftKirbyCopyDonkeySpecialAirNEndSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	var status_id: int = nFTKirbyStatusCopyDonkeySpecialAirNFull if (fp.passive_vars.kirby.copydonkey_charge_level == FTKIRBY_COPYDONKEY_GIANTPUNCH_CHARGE_MAX) else nFTKirbyStatusCopyDonkeySpecialAirNEnd

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, 0.0, 1.0, (FTSTATUS_PRESERVE_FASTFALL | FTSTATUS_PRESERVE_COLANIM))

	ftKirbyCopyDonkeySpecialNGetStatusChargeLevelReset(fighter_gobj)

## 0x80157E7C
static func ftKirbyCopyDonkeySpecialNInitStatusVars(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.kirby.copydonkey_specialn.is_release = TRUE if (fp.passive_vars.kirby.copydonkey_charge_level == FTKIRBY_COPYDONKEY_GIANTPUNCH_CHARGE_MAX) else FALSE

	fp.status_vars.kirby.copydonkey_specialn.is_charging = FALSE
	fp.status_vars.kirby.copydonkey_specialn.is_cancel = FALSE

## 0x80157EAC
static func ftKirbyCopyDonkeySpecialNStartSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyDonkeySpecialNStart, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.proc_damage = Callable(Ftkirbycopydonkeyspecialn, &"ftKirbyCopyDonkeySpecialNProcDamage")

	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftKirbyCopyDonkeySpecialNInitStatusVars(fighter_gobj)

## 0x80157F04
static func ftKirbyCopyDonkeySpecialAirNStartSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusCopyDonkeySpecialAirNStart, 0.0, 1.0, FTSTATUS_PRESERVE_FASTFALL)

	fp.proc_damage = Callable(Ftkirbycopydonkeyspecialn, &"ftKirbyCopyDonkeySpecialNProcDamage")

	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)
	ftKirbyCopyDonkeySpecialNInitStatusVars(fighter_gobj)
