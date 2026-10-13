## 1:1 port of src/ft/ftcommon/ftcommonhammerkneebend.c (ssb-decomp-re): HammerKneeBend (jump squat
## while holding the Hammer).
##
## ftCommonHammerStatusVars is { union { f32 landing_anim_frame; f32 jump_force; }; f32 kneebend_anim_frame;
## s32 input_source; sb32 is_shorthop; } - writes to jump_force also store landing_anim_frame so both
## Dictionary keys alias like the C union.
class_name Ftcommonhammerkneebend
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80147EC0
static func ftCommonHammerKneeBendProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	fp.status_vars.common.hammer.kneebend_anim_frame += 1.0

	if (
		(fp.status_vars.common.hammer.input_source == FTCOMMON_KNEEBEND_INPUT_TYPE_BUTTON) and
		(fp.status_vars.common.hammer.kneebend_anim_frame <= FTCOMMON_KNEEBEND_SHORTHOP_FRAMES) and
		(fp.input.pl.button_release & (R_CBUTTONS | L_CBUTTONS | D_CBUTTONS | U_CBUTTONS))
	):
		fp.status_vars.common.hammer.is_shorthop = TRUE
	if fp.status_vars.common.hammer.kneebend_anim_frame >= attr.kneebend_anim_length:
		Ftcommonhammerfall.ftCommonHammerFallSetStatusJump(fighter_gobj)

## 0x80147F54
static func ftCommonHammerKneeBendProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.status_vars.common.hammer.jump_force < fp.input.pl.stick_range.y:
		fp.status_vars.common.hammer.jump_force = float(fp.input.pl.stick_range.y)
		fp.status_vars.common.hammer.landing_anim_frame = fp.status_vars.common.hammer.jump_force    # union

## 0x80147F88
static func ftCommonHammerKneeBendSetStatus(fighter_gobj, input_source) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusHammerKneeBend, Fthammer.ftHammerGetAnimFrame(fighter_gobj), 1.0, Fthammer.ftHammerGetStatUpdateFlags(fighter_gobj))
	Fthammer.ftHammerSetColAnim(fighter_gobj)

	fp.status_vars.common.hammer.jump_force = float(fp.input.pl.stick_range.y)
	fp.status_vars.common.hammer.landing_anim_frame = fp.status_vars.common.hammer.jump_force    # union
	fp.status_vars.common.hammer.kneebend_anim_frame = 0.0
	fp.status_vars.common.hammer.input_source = input_source
	fp.status_vars.common.hammer.is_shorthop = FALSE

## 0x8014800C
static func ftCommonHammerKneeBendCheckInterruptCommon(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var input_source: int = Ftcommonkneebend.ftCommonKneeBendGetInputTypeCommon(fp)

	if input_source != FTCOMMON_KNEEBEND_INPUT_TYPE_NONE:
		ftCommonHammerKneeBendSetStatus(fighter_gobj, input_source)

		return TRUE
	else:
		return FALSE
