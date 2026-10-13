## 1:1 port of src/ft/ftchar/ftdonkey/ftdonkeythrowfkneebend.c (ssb-decomp-re).
## Donkey Kong Cargo Throw: jump squat.
class_name Ftdonkeythrowfkneebend
extends Port

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8014D850
static func ftDonkeyThrowFKneeBendProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	fp.status_vars.common.throwf.kneebend_anim_frame += 1

	if (
		(fp.status_vars.common.throwf.input_source == FTCOMMON_KNEEBEND_INPUT_TYPE_BUTTON) and
		(fp.status_vars.common.throwf.kneebend_anim_frame <= FTCOMMON_KNEEBEND_SHORTHOP_FRAMES) and
		(fp.input.pl.button_release & (R_CBUTTONS | L_CBUTTONS | D_CBUTTONS | U_CBUTTONS))
	):
		fp.status_vars.common.throwf.is_shorthop = TRUE
	if attr.kneebend_anim_length <= fp.status_vars.common.throwf.kneebend_anim_frame:
		Ftdonkeythrowffall.ftDonkeyThrowFJumpSetStatus(fighter_gobj)

## 0x8014D8E4
static func ftDonkeyThrowFKneeBendProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if Ftcommonitemthrow.ftCommonHeavyThrowCheckInterruptCommon(fighter_gobj) == FALSE:
		if Ftdonkeythrowff.ftDonkeyThrowFFCheckInterruptThrowFCommon(fighter_gobj) == FALSE:
			if fp.status_vars.common.throwf.jump_force < fp.input.pl.stick_range.y:
				fp.status_vars.common.throwf.jump_force = float(fp.input.pl.stick_range.y)

## 0x8014D950
static func ftDonkeyThrowFKneeBendSetStatus(fighter_gobj, input_source: int) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusThrowFKneeBend, 0.0, 0.0, FTSTATUS_PRESERVE_NONE)

	fp.status_vars.common.throwf.jump_force = float(fp.input.pl.stick_range.y)
	fp.status_vars.common.throwf.kneebend_anim_frame = 0.0
	fp.status_vars.common.throwf.input_source = input_source
	fp.status_vars.common.throwf.is_shorthop = FALSE

## 0x8014D9B8
static func ftDonkeyThrowFKneeBendCheckInterruptThrowFCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var input_source: int = Ftcommonkneebend.ftCommonKneeBendGetInputTypeCommon(fp)

	if input_source != FTCOMMON_KNEEBEND_INPUT_TYPE_NONE:
		ftDonkeyThrowFKneeBendSetStatus(fighter_gobj, input_source)

		return TRUE
	else:
		return FALSE
