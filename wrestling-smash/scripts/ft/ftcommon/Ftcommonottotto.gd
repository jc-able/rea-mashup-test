## 1:1 port of src/ft/ftcommon/ftcommonottotto.c (ssb-decomp-re): Ottotto / OttottoWait (teeter on a ledge).
class_name Ftcommonottotto
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

## ftCommonOttottoCheckInterrupt (macro in ftcommonottotto.c): short-circuit || chain, exact C order.
static func ftCommonOttottoCheckInterrupt(fighter_gobj) -> bool:
	return (
		Ftcommonspecialn.ftCommonSpecialNCheckInterruptCommon(fighter_gobj) or
		Ftcommonspecialhi.ftCommonSpecialHiCheckInterruptCommon(fighter_gobj) or
		Ftcommonspeciallw.ftCommonSpecialLwCheckInterruptCommon(fighter_gobj) or
		Ftcommoncatch1.ftCommonCatchCheckInterruptCommon(fighter_gobj) or
		Ftcommonattacks4.ftCommonAttackS4CheckInterruptCommon(fighter_gobj) or
		Ftcommonattackhi4.ftCommonAttackHi4CheckInterruptCommon(fighter_gobj) or
		Ftcommonattacklw4.ftCommonAttackLw4CheckInterruptCommon(fighter_gobj) or
		Ftcommonattacks3.ftCommonAttackS3CheckInterruptCommon(fighter_gobj) or
		Ftcommonattackhi3.ftCommonAttackHi3CheckInterruptCommon(fighter_gobj) or
		Ftcommonattacklw3.ftCommonAttackLw3CheckInterruptCommon(fighter_gobj) or
		Ftcommonattack1.ftCommonAttack1CheckInterruptCommon(fighter_gobj) or
		Ftcommonguard1.ftCommonGuardOnCheckInterruptCommon(fighter_gobj) or
		Ftcommonappeal.ftCommonAppealCheckInterruptCommon(fighter_gobj) or
		Ftcommonkneebend.ftCommonKneeBendCheckInterruptCommon(fighter_gobj) or
		Ftcommondash.ftCommonDashCheckInterruptCommon(fighter_gobj) or
		Ftcommonpass.ftCommonPassCheckInterruptCommon(fighter_gobj) or
		Ftcommondokan.ftCommonDokanStartCheckInterruptCommon(fighter_gobj) or
		Ftcommonsquat.ftCommonSquatCheckInterruptCommon(fighter_gobj) or
		Ftcommonturn.ftCommonTurnCheckInterruptCommon(fighter_gobj)
	)

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80142850
static func ftCommonOttottoProcUpdate(fighter_gobj) -> void:
	Ftanimend.ftAnimEndCheckSetStatus(fighter_gobj, Callable(Ftcommonottotto, &"ftCommonOttottoWaitSetStatus"))

## 0x80142874
static func ftCommonOttottoProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if not ftCommonOttottoCheckInterrupt(fighter_gobj):
		if (fp.input.pl.stick_range.x * fp.lr) >= FTCOMMON_OTTOTTO_WALK_STICK_RANGE_MIN:
			Ftcommonwalk.ftCommonWalkCheckInterruptCommon(fighter_gobj)

## 0x801429F4
static func ftCommonOttottoProcMap(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var pos     # Vec3f
	var dist_x: float

	if not Mpcommon.mpCommonCheckFighterOnFloor(fighter_gobj):
		Ftcommonfall.ftCommonFallSetStatus(fighter_gobj)
	else:
		# mpCollisionGetFloorEdge{R,L}(line_id, &pos): pos is a pure output
		if fp.lr == +1:
			pos = Mpcollision.mpCollisionGetFloorEdgeR(fp.coll_data.floor_line_id)
		else:
			pos = Mpcollision.mpCollisionGetFloorEdgeL(fp.coll_data.floor_line_id)

		if DObjGetStruct(fighter_gobj).translate.x < pos.x:
			dist_x = -(DObjGetStruct(fighter_gobj).translate.x - pos.x)
		else:
			dist_x = DObjGetStruct(fighter_gobj).translate.x - pos.x

		if dist_x > FTCOMMON_OTTOTTO_WALK_DIST_X_MIN:
			Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)

## 0x80142AC4
static func ftCommonOttottoWaitSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusOttottoWait, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	fp.is_special_interrupt = TRUE

## 0x80142B08
static func ftCommonOttottoSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusOttotto, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	# fp->physics.vel_air.x = fp->physics.vel_air.y = fp->physics.vel_air.z = 0.0F;
	fp.physics.vel_air = Vector3(0.0, 0.0, 0.0)
	fp.physics.vel_ground.x = 0.0

	fp.is_special_interrupt = TRUE
