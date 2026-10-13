## 1:1 port of src/ft/ftchar/ftkirby/ftkirbythrowf.c (ssb-decomp-re): Kirby's forward throw
## (suplex jump, fall and landing).
class_name Ftkirbythrowf
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8014A430
static func ftKirbyThrowFProcUpdate(fighter_gobj = null) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftkirbythrowf, &"ftKirbyThrowFFallSetStatus"))

## 0x8014A454
static func ftKirbyThrowFProcMap(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if B(Mpcommon.mpCommonCheckFighterLanding(fighter_gobj)) and (fp.physics.vel_air.y < 0.0):
		ftKirbyThrowFLandingSetStatus(fighter_gobj)

## 0x8014A4A8
static func ftKirbyThrowFFallSetStatus(fighter_gobj = null) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var catch_gobj = this_fp.catch_gobj
	var catch_fp := ftGetStruct(catch_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusThrowFFall, 0.0, 1.0, FTSTATUS_PRESERVE_TEXTUREPART)

	catch_fp.is_ignore_dead = FALSE

## 0x8014A4F8
static func ftKirbyThrowFLandingProcPhysics(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsGround:
		Ftphysics.ftPhysicsApplyGroundVelFriction(fighter_gobj)
	else:
		Ftphysics.ftPhysicsApplyAirVelTransNAll(fighter_gobj)

## 0x8014A538
static func ftKirbyThrowFLandingProcMap(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if fp.ga == nMPKineticsGround:
		Ftcommoncatch1.ftCommonCatchProcMap(fighter_gobj)

	elif B(Mpcommon.mpCommonCheckFighterLanding(fighter_gobj)) and (fp.physics.vel_air.y < 0.0):
		Mpcommon.mpCommonSetFighterWaitOrLanding(fighter_gobj)

## 0x8014A5AC
static func ftKirbyThrowFLandingSetStatus(fighter_gobj = null) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Mpcommon.mpCommonSetFighterGround(fp)
	Ftmain.ftMainSetStatus(fighter_gobj, nFTKirbyStatusThrowFLanding, 0.0, 1.0, FTSTATUS_PRESERVE_TEXTUREPART)
