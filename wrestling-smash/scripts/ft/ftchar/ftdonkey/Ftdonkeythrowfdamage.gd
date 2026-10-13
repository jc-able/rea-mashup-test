## 1:1 port of src/ft/ftchar/ftdonkey/ftdonkeythrowfdamage.c (ssb-decomp-re).
## DK enters this state when hit during Cargo Throw.
##
## Union note: in C `status_vars.common.throwfdamage` and `status_vars.common.damage` share the same
## memory (FTCommonStatusVars union) and have identical leading layouts (s32 hitstun_tics @0x0,
## s32 dust_effect_int @0x4, f32 public_knockback @0x8). ftCommonDamageInitDamageVars() writes the
## `damage` view and this file reads/writes it back through the `throwfdamage` view. The port keeps the
## union members in separate Dictionaries, so the aliased fields are accessed through
## `status_vars.common.damage` here to keep that shared storage.
class_name Ftdonkeythrowfdamage
extends Port

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8014E050
static func ftDonkeyThrowFDamageProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	# fp->status_vars.common.throwfdamage.hitstun_tics -= 1.0F (s32 field, aliases damage.hitstun_tics)
	fp.status_vars.common.damage.hitstun_tics = int(fp.status_vars.common.damage.hitstun_tics - 1.0)

	if fp.status_vars.common.damage.hitstun_tics <= 0.0:
		if fp.ga == nMPKineticsAir:
			# fp->public_knockback = fp->status_vars.common.throwfdamage.public_knockback (aliases damage.public_knockback)
			fp.public_knockback = fp.status_vars.common.damage.public_knockback

			Ftdonkeythrowffall.ftDonkeyThrowFFallSetStatus(fighter_gobj)
		else:
			Ftdonkeythrowfwait.ftDonkeyThrowFWaitSetStatus(fighter_gobj)

## 0x8014E0E0
static func ftDonkeyThrowFDamageSetStatus(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var knockback_resist: float = this_fp.knockback_resist_passive if (this_fp.knockback_resist_status < this_fp.knockback_resist_passive) else this_fp.knockback_resist_status

	this_fp.damage_knockback -= knockback_resist

	if this_fp.damage_knockback <= 0.0:
		this_fp.damage_knockback = 0.0
	Ftcommondamage.ftCommonDamageInitDamageVars(fighter_gobj, nFTDonkeyStatusThrowFDamage, this_fp.damage_queue, this_fp.damage_knockback, this_fp.damage_angle, this_fp.damage_lr, this_fp.damage_index, this_fp.damage_element, this_fp.damage_player_num, FALSE, FALSE, TRUE)

	if this_fp.catch_gobj != null:
		var catch_gobj = this_fp.catch_gobj
		var capture_fp := ftGetStruct(catch_gobj)

		Ftcommonthrown1.ftCommonThrownProcPhysics(catch_gobj)
		Ftparam.ftParamsUpdateFighterPartsTransformAll(capture_fp.joints[nFTPartsJointTopN])
