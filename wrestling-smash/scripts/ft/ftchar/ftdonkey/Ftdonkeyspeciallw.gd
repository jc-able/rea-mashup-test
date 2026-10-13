## 1:1 port of src/ft/ftchar/ftdonkey/ftdonkeyspeciallw.c (ssb-decomp-re).
## Donkey Kong down special (Hand Slap).
class_name Ftdonkeyspeciallw
extends Port

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x8015B9F0
static func ftDonkeySpecialLwStartProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftdonkeyspeciallw, &"ftDonkeySpecialLwLoopSetStatus"))

## 0x8015BA14
static func ftDonkeySpecialLwLoopProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if (fighter_gobj.anim_frame >= 0.0) and (fighter_gobj.anim_frame < DObjGetStruct(fighter_gobj).anim_speed):
		if fp.status_vars.donkey.speciallw.is_loop != FALSE:
			fp.status_vars.donkey.speciallw.is_loop = FALSE
		else:
			ftDonkeySpecialLwEndSetStatus(fighter_gobj)

## 0x8015BA7C
static func ftDonkeySpecialLwLoopProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.input.pl.button_tap & fp.input.button_mask_b:
		fp.status_vars.donkey.speciallw.is_loop = TRUE

## 0x8015BAA4
static func ftDonkeySpecialLwLoopSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusSpecialLwLoop, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

## 0x8015BAD0
static func ftDonkeySpecialLwEndSetStatus(fighter_gobj) -> void:
	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusSpecialLwEnd, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

## 0x8015BAFC
static func ftDonkeySpecialLwStartSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTDonkeyStatusSpecialLwStart, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	fp.status_vars.donkey.speciallw.is_loop = FALSE
