## 1:1 port of src/ft/ftcommon/ftcommonwalk.c (ssb-decomp-re): WalkSlow / WalkMiddle / WalkFast.
class_name Ftcommonwalk
extends Port

# // // // // // // // // // // // //
# //             MACROS            //
# // // // // // // // // // // // //

## ftCommonWalkCheckInterrupt (macro in ftcommonwalk.c): short-circuit || chain, exact C order.
static func ftCommonWalkCheckInterrupt(fighter_gobj) -> bool:
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
		Ftcommonsquat.ftCommonSquatCheckInterruptCommon(fighter_gobj) or
		Ftcommonwait.ftCommonWaitCheckInterruptCommon(fighter_gobj)
	)

## C s8 conversion (two's complement wrap to [-128, 127]).
static func _s8(v: int) -> int:
	return ((v + 0x80) & 0xFF) - 0x80

## C f32 rounding of an intermediate result (the original computes in single precision).
static func _f32(x: float) -> float:
	var a := PackedFloat32Array([x])
	return a[0]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8013E2E0
static func ftCommonWalkGetWalkAnimLength(fp: Fighter, status_id: int) -> float:
	var walk_anim_length: float = 0.0  # C: uninitialized when status_id is not a walk status

	match status_id:
		nFTCommonStatusWalkSlow:
			walk_anim_length = fp.attr.walkslow_anim_length

		nFTCommonStatusWalkMiddle:
			walk_anim_length = fp.attr.walkmiddle_anim_length

		nFTCommonStatusWalkFast:
			walk_anim_length = fp.attr.walkfast_anim_length

	return walk_anim_length

## 0x8013E340
static func ftCommonWalkGetWalkStatus(stick_range_x: int) -> int:
	var status_id: int

	stick_range_x = _s8(stick_range_x)          # parameter is s8
	stick_range_x = _s8(ABS(stick_range_x))     # stick_range_x = ABS(stick_range_x); (stored back into an s8)

	if stick_range_x >= FTCOMMON_WALKFAST_STICK_RANGE_MIN:
		status_id = nFTCommonStatusWalkFast
	elif stick_range_x >= FTCOMMON_WALKMIDDLE_STICK_RANGE_MIN:
		status_id = nFTCommonStatusWalkMiddle
	else:
		status_id = nFTCommonStatusWalkSlow

	return status_id

## 0x8013E390
static func ftCommonWalkProcInterrupt(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	if not ftCommonWalkCheckInterrupt(fighter_gobj):
		var status_id: int = ftCommonWalkGetWalkStatus(ABS(fp.input.pl.stick_range.x))

		if status_id != fp.status_id:
			var div: float = ftCommonWalkGetWalkAnimLength(fp, fp.status_id)
			var mul: float = ftCommonWalkGetWalkAnimLength(fp, status_id)

			# (s32) ((fighter_gobj->anim_frame / div) * mul), evaluated in f32 like the original
			ftCommonWalkSetStatusParam(fighter_gobj, int(_f32(_f32(_f32(fighter_gobj.anim_frame) / _f32(div)) * _f32(mul))))

## 0x8013E548
static func ftCommonWalkProcPhysics(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftphysics.ftPhysicsSetGroundVelAbsStickRange(fp, fp.attr.walk_speed_mul, fp.attr.traction)
	Ftphysics.ftPhysicsSetGroundVelTransferAir(fighter_gobj)

## 0x8013E580
static func ftCommonWalkSetStatusParam(fighter_gobj, anim_frame_begin: float) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var status_id: int = ftCommonWalkGetWalkStatus(fp.input.pl.stick_range.x)

	Ftmain.ftMainSetStatus(fighter_gobj, status_id, anim_frame_begin, 1.0, FTSTATUS_PRESERVE_NONE)
	Ftmain.ftMainPlayAnimEventsAll(fighter_gobj)

	if status_id != nFTCommonStatusWalkFast:
		fp.is_special_interrupt = TRUE

## 0x8013E5F4
static func ftCommonWalkSetStatusDefault(fighter_gobj) -> void:
	ftCommonWalkSetStatusParam(fighter_gobj, 0.0)

## 0x8013E614
static func ftCommonWalkCheckInputSuccess(fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)

	if (fp.input.pl.stick_range.x * fp.lr) >= 8:
		return TRUE
	else:
		return FALSE

## 0x8013E648
static func ftCommonWalkCheckInterruptCommon(fighter_gobj) -> int:
	if ftCommonWalkCheckInputSuccess(fighter_gobj) != FALSE:
		ftCommonWalkSetStatusDefault(fighter_gobj)

		return TRUE
	else:
		return FALSE
