# Port of src/ft/ftcomputer.c (ssb-decomp-re): CPU player AI - traits, behaviors, objectives,
# attack selection tables, recovery / ledge logic, item use, level-dependent reaction delays and
# the controller-input command script interpreter that produces fp.input.cp.button_inputs and
# fp.input.cp.stick_range (consumed by Ftmain via ftComputerProcessAll).
#
# FILE LOCATION: the mechanical path game/scripts/ft/Ftcomputer.gd is the SAME file as the core
# struct class game/scripts/ft/FTComputer.gd on case-insensitive file systems (macOS default), so this
# module lives in game/scripts/ft/ftcomputer/Ftcomputer.gd. The class name is Ftcomputer as mapped.
#
# Representation notes:
#   * FTComputer.p_command (C: u8 *p_command) is the PackedByteArray of the current input script
#     (or null) and FTComputer.p_command_index is the byte offset of the C pointer inside it.
#   * FTComputerAttack tables are Arrays of Dictionaries with the C field names; the C pointer walk
#     (comattack++) is an index walk over the per-fighter table.
#   * FTComputer's u8 / u16 fields are wrapped (_u8 / _u16) where C arithmetic can overflow and
#     float -> integer stores truncate toward zero like C (trunc.w.s). Stick values are s8 (_s8).
#   * Every syUtilsRandFloat / syUtilsRandUShort call is made in the same order and under the same
#     short-circuit conditions as in the C code.
#   * Out-parameter convention (PORTING.md): mpCollisionGet*Edge*(line_id) return the Vector3;
#     mpCollisionCheck*LineCollisionSame(position, translate) return {ret, ga_last, stand_line_id, ...};
#     grZebesAcidGetLevelInfo() returns {current, step}; grHyruleTwisterCheckGetPosition() returns
#     {ret, pos}; grJungleTaruCannGetPosition() returns the Vector3; gmCollisionGetWorldPosition(mtx, vec)
#     returns the transformed vec.
class_name Ftcomputer
extends Port

# // // // // // // // // // // // //
#                               //
#       C SEMANTICS HELPERS       //
#                               //
# // // // // // // // // // // // //

## C implicit float -> s32 conversion (trunc.w.s: truncation toward zero).
static func _f2i(x: float) -> int:
	return int(x)

## Store into a u8 field.
static func _u8(x: int) -> int:
	return x & 0xFF

## Store into a u16 field.
static func _u16(x: int) -> int:
	return x & 0xFFFF

## Store into an s8 field (Vec2b stick ranges): low byte, sign-extended.
static func _s8(x: int) -> int:
	x &= 0xFF
	return x - 0x100 if x >= 0x80 else x

## Store into an s16 local.
static func _s16(x: int) -> int:
	x &= 0xFFFF
	return x - 0x10000 if x >= 0x8000 else x

## s32 wrap-around of an integer product (SQUARE() of s32 values).
static func _s32(x: int) -> int:
	x &= 0xFFFFFFFF
	return x - 0x100000000 if x >= 0x80000000 else x

## include/macros.h: DISTANCE(a, b)
static func _DISTANCE(a: float, b: float) -> float:
	return -(a - b) if (a < b) else (a - b)

## src/ft/fighter.h: ftGetComTargetFighter(com) -> (FTStruct*)com->target_user
static func _ftGetComTargetFighter(com: FTComputer):
	return com.target_user

## src/ft/fighter.h: ftGetComTargetItem(com) -> (ITStruct*)com->target_user
static func _ftGetComTargetItem(com: FTComputer):
	return com.target_user

## ((FTStruct*)user)->fkind where user may actually be an ITStruct (target_user also holds items):
## FTStruct.fkind (offset 0x8) overlays ITStruct.owner_gobj, a GObj pointer that never equals a
## fighter kind constant, so an item compares unequal to every nFTKind* value.
static func _ftGetFKind(user) -> int:
	if user is Fighter:
		return user.fkind
	return -1

## Clears an FTComputer in place (C: bzero(com, sizeof(*com))).
static func _bzero_computer(com: FTComputer) -> void:
	var fresh := FTComputer.new()

	for prop in fresh.get_property_list():
		if (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0:
			com.set(prop.name, fresh.get(prop.name))

## Globals of src/mp/mpcollision.c (static vars gMPCollisionBounds / gMPCollisionGroundData /
## gMPCollisionLineGroups of class Mpcollision). They are read through an untyped reference to the
## class so that this file parses independently of the Mpcollision port's progress.
static func _mpcollision():
	return Mpcollision

static func _gMPCollisionBounds():
	return _mpcollision().gMPCollisionBounds

static func _gMPCollisionGroundData():
	return _mpcollision().gMPCollisionGroundData

static func _gMPCollisionLineGroups():
	return _mpcollision().gMPCollisionLineGroups

# // // // // // // // // // // // //
#                               //
#       INITIALIZED DATA        //
#                               //
# // // // // // // // // // // // //

## 0x80186660
static var dFTComputerAttackUnknown: PackedByteArray = [0x08, 0x08, 0x0B, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x0B, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x0B, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08]

## 0x80186684
static var dFTComputerAttacksMario: Array = [
	# Attack11
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 2, "hit_end_frame": 6, "detect_near_x": 150.0, "detect_far_x": 400.0, "detect_near_y": 30.0, "detect_far_y": 210.0},
	# AttackS3
	{"input_kind": nFTComputerInputStickTiltAutoXButtonA, "hit_start_frame": 8, "hit_end_frame": 17, "detect_near_x": 45.0, "detect_far_x": 560.0, "detect_near_y": -45.0, "detect_far_y": 270.0},
	# AttackS4
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 16, "hit_end_frame": 20, "detect_near_x": 60.0, "detect_far_x": 580.0, "detect_near_y": 0.0, "detect_far_y": 280.0},
	# AttackHi3
	{"input_kind": nFTComputerInputStickTiltHiButtonA, "hit_start_frame": 5, "hit_end_frame": 16, "detect_near_x": -140.0, "detect_far_x": 470.0, "detect_near_y": 120.0, "detect_far_y": 640.0},
	# AttackHi4
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 7, "hit_end_frame": 15, "detect_near_x": -230.0, "detect_far_x": 360.0, "detect_near_y": 140.0, "detect_far_y": 630.0},
	# AttackLw3
	{"input_kind": nFTComputerInputStickTiltLwButtonA, "hit_start_frame": 5, "hit_end_frame": 11, "detect_near_x": 130.0, "detect_far_x": 720.0, "detect_near_y": -90.0, "detect_far_y": 170.0},
	# AttackLw4
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 9, "hit_end_frame": 30, "detect_near_x": -420.0, "detect_far_x": 490.0, "detect_near_y": -130.0, "detect_far_y": 400.0},
	# SpecialN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 10, "hit_end_frame": 15, "detect_near_x": 400.0, "detect_far_x": 1200.0, "detect_near_y": 0.0, "detect_far_y": 280.0},
	# SpecialHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 2, "hit_end_frame": 23, "detect_near_x": -120.0, "detect_far_x": 950.0, "detect_near_y": -120.0, "detect_far_y": 2100.0},
	# SpecialLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 1, "hit_end_frame": 44, "detect_near_x": -250.0, "detect_far_x": 250.0, "detect_near_y": -70.0, "detect_far_y": 500.0},
	# Catch
	{"input_kind": nFTComputerInputStickNButtonZButtonA, "hit_start_frame": 7, "hit_end_frame": 7, "detect_near_x": 50.0, "detect_far_x": 340.0, "detect_near_y": 65.0, "detect_far_y": 355.0},
	# End of Ground Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# AttackAirN
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 3, "hit_end_frame": 36, "detect_near_x": -192.0, "detect_far_x": 201.0, "detect_near_y": -30.0, "detect_far_y": 280.0},
	# AttackAirF / AttackAirB
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 10, "hit_end_frame": 19, "detect_near_x": -443.0, "detect_far_x": 147.0, "detect_near_y": -5.0, "detect_far_y": 381.0},
	# AttackAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 2, "hit_end_frame": 11, "detect_near_x": -273.0, "detect_far_x": 459.0, "detect_near_y": -3.0, "detect_far_y": 634.0},
	# AttackAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 11, "hit_end_frame": 33, "detect_near_x": -60.0, "detect_far_x": 438.0, "detect_near_y": -153.0, "detect_far_y": 404.0},
	# SpecialAirN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 10, "hit_end_frame": 15, "detect_near_x": 400.0, "detect_far_x": 1200.0, "detect_near_y": 0.0, "detect_far_y": 280.0},
	# SpecialAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 2, "hit_end_frame": 23, "detect_near_x": -334.0, "detect_far_x": 431.0, "detect_near_y": -124.0, "detect_far_y": 540.0},
	# SpecialAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 1, "hit_end_frame": 46, "detect_near_x": -250.0, "detect_far_x": 250.0, "detect_near_y": -90.0, "detect_far_y": 470.0},
	# End of Aerial Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
]

## 0x801868B4
static var dFTComputerAttacksFox: Array = [
	# Attack11
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 3, "hit_end_frame": 4, "detect_near_x": 180.0, "detect_far_x": 590.0, "detect_near_y": 140.0, "detect_far_y": 355.0},
	# AttackS3
	{"input_kind": nFTComputerInputStickTiltAutoXButtonA, "hit_start_frame": 3, "hit_end_frame": 8, "detect_near_x": 180.0, "detect_far_x": 590.0, "detect_near_y": 140.0, "detect_far_y": 355.0},
	# AttackS4
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 12, "hit_end_frame": 24, "detect_near_x": 280.0, "detect_far_x": 1020.0, "detect_near_y": 35.0, "detect_far_y": 460.0},
	# AttackHi3
	{"input_kind": nFTComputerInputStickTiltHiButtonA, "hit_start_frame": 6, "hit_end_frame": 13, "detect_near_x": -90.0, "detect_far_x": 270.0, "detect_near_y": 185.0, "detect_far_y": 750.0},
	# AttackHi4
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 6, "hit_end_frame": 21, "detect_near_x": -390.0, "detect_far_x": 425.0, "detect_near_y": 60.0, "detect_far_y": 790.0},
	# AttackLw3
	{"input_kind": nFTComputerInputStickTiltLwButtonA, "hit_start_frame": 6, "hit_end_frame": 9, "detect_near_x": 135.0, "detect_far_x": 750.0, "detect_near_y": -145.0, "detect_far_y": 155.0},
	# AttackLw4
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 7, "hit_end_frame": 11, "detect_near_x": -465.0, "detect_far_x": 470.0, "detect_near_y": -100.0, "detect_far_y": 180.0},
	# SpecialN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 5, "hit_end_frame": 10, "detect_near_x": 400.0, "detect_far_x": 1200.0, "detect_near_y": 35.0, "detect_far_y": 460.0},
	# SpecialHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 43, "hit_end_frame": 72, "detect_near_x": -40.0, "detect_far_x": 140.0, "detect_near_y": 350.0, "detect_far_y": 2500.0},
	# SpecialLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 1, "hit_end_frame": 1, "detect_near_x": -180.0, "detect_far_x": 180.0, "detect_near_y": 60.0, "detect_far_y": 420.0},
	# Catch
	{"input_kind": nFTComputerInputStickNButtonZButtonA, "hit_start_frame": 7, "hit_end_frame": 7, "detect_near_x": 200.0, "detect_far_x": 460.0, "detect_near_y": 110.0, "detect_far_y": 370.0},
	# End of Ground Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# AttackAirN
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 4, "hit_end_frame": 28, "detect_near_x": -105.0, "detect_far_x": 322.0, "detect_near_y": 59.0, "detect_far_y": 411.0},
	# AttackAirF / AttackAirB
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 4, "hit_end_frame": 27, "detect_near_x": -466.0, "detect_far_x": 299.0, "detect_near_y": 53.0, "detect_far_y": 418.0},
	# AttackAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 6, "hit_end_frame": 13, "detect_near_x": -273.0, "detect_far_x": 268.0, "detect_near_y": -158.0, "detect_far_y": 704.0},
	# AttackAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 5, "hit_end_frame": 24, "detect_near_x": -132.0, "detect_far_x": 276.0, "detect_near_y": -90.0, "detect_far_y": 329.0},
	# SpecialAirN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 5, "hit_end_frame": 10, "detect_near_x": 400.0, "detect_far_x": 1200.0, "detect_near_y": 35.0, "detect_far_y": 460.0},
	# SpecialAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 43, "hit_end_frame": 72, "detect_near_x": -144.0, "detect_far_x": 43.0, "detect_near_y": 234.0, "detect_far_y": 418.0},
	# SpecialAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 1, "hit_end_frame": 1, "detect_near_x": -180.0, "detect_far_x": 180.0, "detect_near_y": 60.0, "detect_far_y": 420.0},
	# End of Aerial Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
]

## 0x80186AE4
static var dFTComputerAttacksDonkey: Array = [
	# Attack11
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 5, "hit_end_frame": 8, "detect_near_x": 170.0, "detect_far_x": 700.0, "detect_near_y": 10.0, "detect_far_y": 450.0},
	# AttackS3
	{"input_kind": nFTComputerInputStickTiltAutoXButtonA, "hit_start_frame": 5, "hit_end_frame": 8, "detect_near_x": 170.0, "detect_far_x": 700.0, "detect_near_y": 10.0, "detect_far_y": 450.0},
	# AttackS4
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 27, "hit_end_frame": 32, "detect_near_x": 220.0, "detect_far_x": 1060.0, "detect_near_y": 50.0, "detect_far_y": 465.0},
	# AttackHi3
	{"input_kind": nFTComputerInputStickTiltHiButtonA, "hit_start_frame": 4, "hit_end_frame": 23, "detect_near_x": -950.0, "detect_far_x": 535.0, "detect_near_y": 200.0, "detect_far_y": 965.0},
	# AttackHi4
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 16, "hit_end_frame": 18, "detect_near_x": -275.0, "detect_far_x": 255.0, "detect_near_y": 485.0, "detect_far_y": 985.0},
	# AttackLw3
	{"input_kind": nFTComputerInputStickTiltLwButtonA, "hit_start_frame": 11, "hit_end_frame": 16, "detect_near_x": 190.0, "detect_far_x": 760.0, "detect_near_y": -70.0, "detect_far_y": 230.0},
	# AttackLw4
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 13, "hit_end_frame": 32, "detect_near_x": -580.0, "detect_far_x": 635.0, "detect_near_y": -100.0, "detect_far_y": 265.0},
	# SpecialN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 23, "hit_end_frame": 45, "detect_near_x": -190.0, "detect_far_x": 1440.0, "detect_near_y": 10.0, "detect_far_y": 450.0},
	# SpecialHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 3, "hit_end_frame": 72, "detect_near_x": -515.0, "detect_far_x": 575.0, "detect_near_y": 40.0, "detect_far_y": 720.0},
	# SpecialLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 19, "hit_end_frame": 30, "detect_near_x": -825.0, "detect_far_x": 1075.0, "detect_near_y": -200.0, "detect_far_y": 200.0},
	# Catch
	{"input_kind": nFTComputerInputStickNButtonZButtonA, "hit_start_frame": 7, "hit_end_frame": 7, "detect_near_x": 220.0, "detect_far_x": 690.0, "detect_near_y": 155.0, "detect_far_y": 480.0},
	# End of Ground Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# AttackAirN
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 4, "hit_end_frame": 29, "detect_near_x": -619.0, "detect_far_x": 438.0, "detect_near_y": 76.0, "detect_far_y": 691.0},
	# AttackAirF / AttackAirB
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 8, "hit_end_frame": 15, "detect_near_x": -146.0, "detect_far_x": 599.0, "detect_near_y": -133.0, "detect_far_y": 1019.0},
	# AttackAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 3, "hit_end_frame": 20, "detect_near_x": -858.0, "detect_far_x": 559.0, "detect_near_y": 102.0, "detect_far_y": 1022.0},
	# AttackAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 7, "hit_end_frame": 30, "detect_near_x": -307.0, "detect_far_x": 127.0, "detect_near_y": -310.0, "detect_far_y": 257.0},
	# SpecialAirN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 23, "hit_end_frame": 30, "detect_near_x": -447.0, "detect_far_x": 987.0, "detect_near_y": 158.0, "detect_far_y": 906.0},
	# SpecialAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 3, "hit_end_frame": 72, "detect_near_x": -615.0, "detect_far_x": 604.0, "detect_near_y": 23.0, "detect_far_y": 639.0},
	# SpecialAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# End of Aerial Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
]

## 0x80186D14
static var dFTComputerAttacksSamus: Array = [
	# Attack11
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 4, "hit_end_frame": 5, "detect_near_x": 170.0, "detect_far_x": 650.0, "detect_near_y": 240.0, "detect_far_y": 450.0},
	# AttackS3
	{"input_kind": nFTComputerInputStickTiltAutoXButtonA, "hit_start_frame": 4, "hit_end_frame": 9, "detect_near_x": 170.0, "detect_far_x": 655.0, "detect_near_y": 200.0, "detect_far_y": 445.0},
	# AttackS4
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 12, "hit_end_frame": 15, "detect_near_x": 65.0, "detect_far_x": 670.0, "detect_near_y": 200.0, "detect_far_y": 445.0},
	# AttackHi3
	{"input_kind": nFTComputerInputStickTiltHiButtonA, "hit_start_frame": 8, "hit_end_frame": 29, "detect_near_x": -355.0, "detect_far_x": 600.0, "detect_near_y": -5.0, "detect_far_y": 895.0},
	# AttackHi4
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 17, "hit_end_frame": 34, "detect_near_x": -535.0, "detect_far_x": 435.0, "detect_near_y": 335.0, "detect_far_y": 950.0},
	# AttackLw3
	{"input_kind": nFTComputerInputStickTiltLwButtonA, "hit_start_frame": 8, "hit_end_frame": 12, "detect_near_x": 160.0, "detect_far_x": 655.0, "detect_near_y": -60.0, "detect_far_y": 195.0},
	# AttackLw4
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 9, "hit_end_frame": 23, "detect_near_x": -525.0, "detect_far_x": 545.0, "detect_near_y": -100.0, "detect_far_y": 270.0},
	# SpecialN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 10, "hit_end_frame": 15, "detect_near_x": 500.0, "detect_far_x": 1500.0, "detect_near_y": 200.0, "detect_far_y": 445.0},
	# SpecialHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 4, "hit_end_frame": 33, "detect_near_x": -230.0, "detect_far_x": 500.0, "detect_near_y": -130.0, "detect_far_y": 1860.0},
	# SpecialLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# Catch
	{"input_kind": nFTComputerInputStickNButtonZButtonA, "hit_start_frame": 21, "hit_end_frame": 39, "detect_near_x": 75.0, "detect_far_x": 1275.0, "detect_near_y": 135.0, "detect_far_y": 350.0},
	# End of Ground Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# AttackAirN
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 4, "hit_end_frame": 27, "detect_near_x": -129.0, "detect_far_x": 308.0, "detect_near_y": 121.0, "detect_far_y": 488.0},
	# AttackAirF / AttackAirB
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 5, "hit_end_frame": 16, "detect_near_x": -447.0, "detect_far_x": 80.0, "detect_near_y": -34.0, "detect_far_y": 690.0},
	# AttackAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 6, "hit_end_frame": 19, "detect_near_x": -165.0, "detect_far_x": 346.0, "detect_near_y": 177.0, "detect_far_y": 703.0},
	# AttackAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 5, "hit_end_frame": 13, "detect_near_x": -453.0, "detect_far_x": 428.0, "detect_near_y": -267.0, "detect_far_y": 547.0},
	# SpecialAirN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 10, "hit_end_frame": 15, "detect_near_x": 500.0, "detect_far_x": 1500.0, "detect_near_y": 200.0, "detect_far_y": 445.0},
	# SpecialAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 4, "hit_end_frame": 31, "detect_near_x": -230.0, "detect_far_x": 230.0, "detect_near_y": -70.0, "detect_far_y": 370.0},
	# SpecialAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# End of Aerial Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
]

## 0x80186F44
static var dFTComputerAttacksLuigi: Array = [
	# Attack11
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 2, "hit_end_frame": 6, "detect_near_x": 150.0, "detect_far_x": 400.0, "detect_near_y": 30.0, "detect_far_y": 210.0},
	# AttackS3
	{"input_kind": nFTComputerInputStickTiltAutoXButtonA, "hit_start_frame": 8, "hit_end_frame": 17, "detect_near_x": 45.0, "detect_far_x": 560.0, "detect_near_y": -45.0, "detect_far_y": 270.0},
	# AttackS4
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 16, "hit_end_frame": 20, "detect_near_x": 60.0, "detect_far_x": 580.0, "detect_near_y": 0.0, "detect_far_y": 280.0},
	# AttackHi3
	{"input_kind": nFTComputerInputStickTiltHiButtonA, "hit_start_frame": 5, "hit_end_frame": 16, "detect_near_x": -140.0, "detect_far_x": 470.0, "detect_near_y": 120.0, "detect_far_y": 640.0},
	# AttackHi4
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 7, "hit_end_frame": 15, "detect_near_x": -230.0, "detect_far_x": 360.0, "detect_near_y": 140.0, "detect_far_y": 630.0},
	# AttackLw3
	{"input_kind": nFTComputerInputStickTiltLwButtonA, "hit_start_frame": 5, "hit_end_frame": 11, "detect_near_x": 130.0, "detect_far_x": 720.0, "detect_near_y": -90.0, "detect_far_y": 170.0},
	# AttackLw4
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 9, "hit_end_frame": 30, "detect_near_x": -420.0, "detect_far_x": 490.0, "detect_near_y": -130.0, "detect_far_y": 400.0},
	# SpecialN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 10, "hit_end_frame": 15, "detect_near_x": 400.0, "detect_far_x": 1200.0, "detect_near_y": 0.0, "detect_far_y": 280.0},
	# SpecialHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 2, "hit_end_frame": 23, "detect_near_x": -120.0, "detect_far_x": 950.0, "detect_near_y": -120.0, "detect_far_y": 2100.0},
	# SpecialLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 1, "hit_end_frame": 44, "detect_near_x": -250.0, "detect_far_x": 250.0, "detect_near_y": -70.0, "detect_far_y": 500.0},
	# Catch
	{"input_kind": nFTComputerInputStickNButtonZButtonA, "hit_start_frame": 7, "hit_end_frame": 7, "detect_near_x": 50.0, "detect_far_x": 340.0, "detect_near_y": 65.0, "detect_far_y": 355.0},
	# End of Ground Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# AttackAirN
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 3, "hit_end_frame": 36, "detect_near_x": -192.0, "detect_far_x": 201.0, "detect_near_y": -30.0, "detect_far_y": 280.0},
	# AttackAirF / AttackAirB
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 10, "hit_end_frame": 19, "detect_near_x": -443.0, "detect_far_x": 147.0, "detect_near_y": -5.0, "detect_far_y": 381.0},
	# AttackAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 2, "hit_end_frame": 11, "detect_near_x": -273.0, "detect_far_x": 459.0, "detect_near_y": -3.0, "detect_far_y": 634.0},
	# AttackAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 11, "hit_end_frame": 33, "detect_near_x": -60.0, "detect_far_x": 438.0, "detect_near_y": -153.0, "detect_far_y": 404.0},
	# SpecialAirN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 10, "hit_end_frame": 15, "detect_near_x": 400.0, "detect_far_x": 1200.0, "detect_near_y": 0.0, "detect_far_y": 280.0},
	# SpecialAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 1, "hit_end_frame": 23, "detect_near_x": -239.0, "detect_far_x": 449.0, "detect_near_y": -109.0, "detect_far_y": 560.0},
	# SpecialAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 1, "hit_end_frame": 46, "detect_near_x": -250.0, "detect_far_x": 250.0, "detect_near_y": 10.0, "detect_far_y": 465.0},
	# End of Aerial Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
]

## 0x80187174
static var dFTComputerAttacksLink: Array = [
	# Attack11
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 6, "hit_end_frame": 9, "detect_near_x": -5.0, "detect_far_x": 595.0, "detect_near_y": -25.0, "detect_far_y": 380.0},
	# AttackS3
	{"input_kind": nFTComputerInputStickTiltAutoXButtonA, "hit_start_frame": 15, "hit_end_frame": 20, "detect_near_x": -340.0, "detect_far_x": 630.0, "detect_near_y": -140.0, "detect_far_y": 755.0},
	# AttackS4
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 16, "hit_end_frame": 25, "detect_near_x": -610.0, "detect_far_x": 770.0, "detect_near_y": -65.0, "detect_far_y": 885.0},
	# AttackHi3
	{"input_kind": nFTComputerInputStickTiltHiButtonA, "hit_start_frame": 8, "hit_end_frame": 16, "detect_near_x": -530.0, "detect_far_x": 660.0, "detect_near_y": -140.0, "detect_far_y": 775.0},
	# AttackHi4
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 11, "hit_end_frame": 35, "detect_near_x": -500.0, "detect_far_x": 500.0, "detect_near_y": 90.0, "detect_far_y": 940.0},
	# AttackLw3
	{"input_kind": nFTComputerInputStickTiltLwButtonA, "hit_start_frame": 12, "hit_end_frame": 19, "detect_near_x": 170.0, "detect_far_x": 750.0, "detect_near_y": -50.0, "detect_far_y": 240.0},
	# AttackLw4
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 10, "hit_end_frame": 24, "detect_near_x": -655.0, "detect_far_x": 740.0, "detect_near_y": -100.0, "detect_far_y": 380.0},
	# SpecialN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 10, "hit_end_frame": 15, "detect_near_x": 500.0, "detect_far_x": 1500.0, "detect_near_y": 0.0, "detect_far_y": 400.0},
	# SpecialHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 8, "hit_end_frame": 39, "detect_near_x": -775.0, "detect_far_x": 785.0, "detect_near_y": 145.0, "detect_far_y": 455.0},
	# SpecialLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# Catch
	{"input_kind": nFTComputerInputStickNButtonZButtonA, "hit_start_frame": 18, "hit_end_frame": 29, "detect_near_x": 220.0, "detect_far_x": 1205.0, "detect_near_y": 125.0, "detect_far_y": 365.0},
	# End of Ground Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# AttackAirN
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 4, "hit_end_frame": 29, "detect_near_x": -195.0, "detect_far_x": 341.0, "detect_near_y": 18.0, "detect_far_y": 361.0},
	# AttackAirF / AttackAirB
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 6, "hit_end_frame": 26, "detect_near_x": -620.0, "detect_far_x": 6.0, "detect_near_y": 41.0, "detect_far_y": 439.0},
	# AttackAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 5, "hit_end_frame": 29, "detect_near_x": -211.0, "detect_far_x": 201.0, "detect_near_y": 366.0, "detect_far_y": 779.0},
	# AttackAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 6, "hit_end_frame": 29, "detect_near_x": -122.0, "detect_far_x": 262.0, "detect_near_y": -116.0, "detect_far_y": 294.0},
	# SpecialAirN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 10, "hit_end_frame": 15, "detect_near_x": 500.0, "detect_far_x": 1500.0, "detect_near_y": 0.0, "detect_far_y": 400.0},
	# SpecialAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 8, "hit_end_frame": 39, "detect_near_x": -707.0, "detect_far_x": 730.0, "detect_near_y": 190.0, "detect_far_y": 516.0},
	# SpecialAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# End of Aerial Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
]

## 0x801873A4
static var dFTComputerAttacksYoshi: Array = [
	# Attack11
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 3, "hit_end_frame": 5, "detect_near_x": 15.0, "detect_far_x": 630.0, "detect_near_y": -60.0, "detect_far_y": 445.0},
	# AttackS3
	{"input_kind": nFTComputerInputStickTiltAutoXButtonA, "hit_start_frame": 3, "hit_end_frame": 5, "detect_near_x": 15.0, "detect_far_x": 630.0, "detect_near_y": -60.0, "detect_far_y": 445.0},
	# AttackS4
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 18, "hit_end_frame": 24, "detect_near_x": 155.0, "detect_far_x": 810.0, "detect_near_y": -15.0, "detect_far_y": 425.0},
	# AttackHi3
	{"input_kind": nFTComputerInputStickTiltHiButtonA, "hit_start_frame": 7, "hit_end_frame": 10, "detect_near_x": -240.0, "detect_far_x": 435.0, "detect_near_y": 100.0, "detect_far_y": 710.0},
	# AttackHi4
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 9, "hit_end_frame": 15, "detect_near_x": -380.0, "detect_far_x": 425.0, "detect_near_y": 230.0, "detect_far_y": 910.0},
	# AttackLw3
	{"input_kind": nFTComputerInputStickTiltLwButtonA, "hit_start_frame": 8, "hit_end_frame": 10, "detect_near_x": 130.0, "detect_far_x": 645.0, "detect_near_y": -40.0, "detect_far_y": 245.0},
	# AttackLw4
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 7, "hit_end_frame": 23, "detect_near_x": -630.0, "detect_far_x": 685.0, "detect_near_y": -100.0, "detect_far_y": 285.0},
	# SpecialN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 18, "hit_end_frame": 23, "detect_near_x": 225.0, "detect_far_x": 1065.0, "detect_near_y": 105.0, "detect_far_y": 410.0},
	# SpecialHi
	{"input_kind": nFTComputerInputYoshiSpecialHiAim, "hit_start_frame": 10, "hit_end_frame": 20, "detect_near_x": -900.0, "detect_far_x": 900.0, "detect_near_y": 800.0, "detect_far_y": 2000.0},
	# SpecialLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 30, "hit_end_frame": 41, "detect_near_x": 630.0, "detect_far_x": 1085.0, "detect_near_y": -25.0, "detect_far_y": 1755.0},
	# Catch
	{"input_kind": nFTComputerInputStickNButtonZButtonA, "hit_start_frame": 16, "hit_end_frame": 20, "detect_near_x": 290.0, "detect_far_x": 845.0, "detect_near_y": 40.0, "detect_far_y": 260.0},
	# End of Ground Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# AttackAirN
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 5, "hit_end_frame": 30, "detect_near_x": -186.0, "detect_far_x": 258.0, "detect_near_y": 20.0, "detect_far_y": 356.0},
	# AttackAirF / AttackAirB
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 10, "hit_end_frame": 19, "detect_near_x": -580.0, "detect_far_x": 148.0, "detect_near_y": 34.0, "detect_far_y": 429.0},
	# AttackAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 9, "hit_end_frame": 10, "detect_near_x": -171.0, "detect_far_x": 187.0, "detect_near_y": 302.0, "detect_far_y": 819.0},
	# AttackAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 5, "hit_end_frame": 29, "detect_near_x": -204.0, "detect_far_x": 254.0, "detect_near_y": -53.0, "detect_far_y": 444.0},
	# SpecialAirN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 18, "hit_end_frame": 23, "detect_near_x": 224.0, "detect_far_x": 1064.0, "detect_near_y": 108.0, "detect_far_y": 411.0},
	# SpecialAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# SpecialAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 24, "hit_end_frame": 31, "detect_near_x": -230.0, "detect_far_x": 230.0, "detect_near_y": -54.0, "detect_far_y": 406.0},
	# End of Aerial Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
]

## 0x801875D4
static var dFTComputerAttacksKirby: Array = [
	# Attack11
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 3, "hit_end_frame": 4, "detect_near_x": 110.0, "detect_far_x": 495.0, "detect_near_y": 35.0, "detect_far_y": 255.0},
	# AttackS3
	{"input_kind": nFTComputerInputStickTiltAutoXButtonA, "hit_start_frame": 3, "hit_end_frame": 4, "detect_near_x": 110.0, "detect_far_x": 495.0, "detect_near_y": 35.0, "detect_far_y": 255.0},
	# AttackS4
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 10, "hit_end_frame": 23, "detect_near_x": 215.0, "detect_far_x": 1115.0, "detect_near_y": 0.0, "detect_far_y": 330.0},
	# AttackHi3
	{"input_kind": nFTComputerInputStickTiltHiButtonA, "hit_start_frame": 4, "hit_end_frame": 11, "detect_near_x": -230.0, "detect_far_x": 480.0, "detect_near_y": 80.0, "detect_far_y": 750.0},
	# AttackHi4
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 14, "hit_end_frame": 23, "detect_near_x": -430.0, "detect_far_x": 480.0, "detect_near_y": 185.0, "detect_far_y": 880.0},
	# AttackLw3
	{"input_kind": nFTComputerInputStickTiltLwButtonA, "hit_start_frame": 4, "hit_end_frame": 10, "detect_near_x": 105.0, "detect_far_x": 745.0, "detect_near_y": -115.0, "detect_far_y": 245.0},
	# AttackLw4
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 8, "hit_end_frame": 27, "detect_near_x": -560.0, "detect_far_x": 565.0, "detect_near_y": -140.0, "detect_far_y": 190.0},
	# SpecialN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 25, "hit_end_frame": 59, "detect_near_x": 45.0, "detect_far_x": 470.0, "detect_near_y": 80.0, "detect_far_y": 370.0},
	# SpecialHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 23, "hit_end_frame": 56, "detect_near_x": 115.0, "detect_far_x": 600.0, "detect_near_y": 55.0, "detect_far_y": 2350.0},
	# SpecialLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# Catch
	{"input_kind": nFTComputerInputStickNButtonZButtonA, "hit_start_frame": 7, "hit_end_frame": 7, "detect_near_x": 175.0, "detect_far_x": 525.0, "detect_near_y": 95.0, "detect_far_y": 355.0},
	# End of Ground Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# AttackAirN
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 3, "hit_end_frame": 30, "detect_near_x": -110.0, "detect_far_x": 425.0, "detect_near_y": -40.0, "detect_far_y": 238.0},
	# AttackAirF / AttackAirB
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 6, "hit_end_frame": 25, "detect_near_x": -416.0, "detect_far_x": 86.0, "detect_near_y": -49.0, "detect_far_y": 331.0},
	# AttackAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 10, "hit_end_frame": 37, "detect_near_x": -291.0, "detect_far_x": 291.0, "detect_near_y": -150.0, "detect_far_y": 309.0},
	# AttackAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 5, "hit_end_frame": 33, "detect_near_x": -124.0, "detect_far_x": 284.0, "detect_near_y": -303.0, "detect_far_y": 180.0},
	# SpecialAirN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 25, "hit_end_frame": 59, "detect_near_x": 43.0, "detect_far_x": 474.0, "detect_near_y": 81.0, "detect_far_y": 371.0},
	# SpecialAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 23, "hit_end_frame": 56, "detect_near_x": 125.0, "detect_far_x": 625.0, "detect_near_y": 25.0, "detect_far_y": 525.0},
	# SpecialAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 23, "hit_end_frame": 30, "detect_near_x": -200.0, "detect_far_x": 200.0, "detect_near_y": -200.0, "detect_far_y": 200.0},
	# End of Aerial Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
]

## 0x80187804
static var dFTComputerAttacksPikachu: Array = [
	# Attack11
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 2, "hit_end_frame": 5, "detect_near_x": -10.0, "detect_far_x": 455.0, "detect_near_y": -70.0, "detect_far_y": 235.0},
	# AttackS3
	{"input_kind": nFTComputerInputStickTiltAutoXButtonA, "hit_start_frame": 5, "hit_end_frame": 14, "detect_near_x": 20.0, "detect_far_x": 490.0, "detect_near_y": 10.0, "detect_far_y": 375.0},
	# AttackS4
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 22, "hit_end_frame": 39, "detect_near_x": 50.0, "detect_far_x": 730.0, "detect_near_y": -65.0, "detect_far_y": 255.0},
	# AttackHi3
	{"input_kind": nFTComputerInputStickTiltHiButtonA, "hit_start_frame": 5, "hit_end_frame": 14, "detect_near_x": -360.0, "detect_far_x": 370.0, "detect_near_y": 95.0, "detect_far_y": 675.0},
	# AttackHi4
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 10, "hit_end_frame": 18, "detect_near_x": -460.0, "detect_far_x": 425.0, "detect_near_y": 40.0, "detect_far_y": 765.0},
	# AttackLw3
	{"input_kind": nFTComputerInputStickTiltLwButtonA, "hit_start_frame": 6, "hit_end_frame": 13, "detect_near_x": 5.0, "detect_far_x": 465.0, "detect_near_y": -70.0, "detect_far_y": 245.0},
	# AttackLw4
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 11, "hit_end_frame": 29, "detect_near_x": -475.0, "detect_far_x": 435.0, "detect_near_y": -100.0, "detect_far_y": 360.0},
	# SpecialN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 10, "hit_end_frame": 15, "detect_near_x": 400.0, "detect_far_x": 1200.0, "detect_near_y": -70.0, "detect_far_y": 375.0},
	# SpecialHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# SpecialLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 40, "hit_end_frame": 48, "detect_near_x": -350.0, "detect_far_x": 350.0, "detect_near_y": -65.0, "detect_far_y": 635.0},
	# Catch
	{"input_kind": nFTComputerInputStickNButtonZButtonA, "hit_start_frame": 7, "hit_end_frame": 7, "detect_near_x": 170.0, "detect_far_x": 455.0, "detect_near_y": 80.0, "detect_far_y": 370.0},
	# End of Ground Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# AttackAirN
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 3, "hit_end_frame": 28, "detect_near_x": -247.0, "detect_far_x": 208.0, "detect_near_y": 32.0, "detect_far_y": 373.0},
	# AttackAirF / AttackAirB
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 10, "hit_end_frame": 21, "detect_near_x": -549.0, "detect_far_x": 56.0, "detect_near_y": 14.0, "detect_far_y": 387.0},
	# AttackAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 3, "hit_end_frame": 10, "detect_near_x": -530.0, "detect_far_x": 505.0, "detect_near_y": -29.0, "detect_far_y": 729.0},
	# AttackAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 9, "hit_end_frame": 26, "detect_near_x": -284.0, "detect_far_x": 187.0, "detect_near_y": -267.0, "detect_far_y": 387.0},
	# SpecialAirN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 10, "hit_end_frame": 15, "detect_near_x": 400.0, "detect_far_x": 1200.0, "detect_near_y": -70.0, "detect_far_y": 375.0},
	# SpecialAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# SpecialAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 40, "hit_end_frame": 48, "detect_near_x": -350.0, "detect_far_x": 350.0, "detect_near_y": -65.0, "detect_far_y": 635.0},
	# End of Aerial Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
]

## 0x80187A34
static var dFTComputerAttacksCaptain: Array = [
	# Attack11
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 5, "hit_end_frame": 8, "detect_near_x": 25.0, "detect_far_x": 495.0, "detect_near_y": 280.0, "detect_far_y": 510.0},
	# AttackS3
	{"input_kind": nFTComputerInputStickTiltAutoXButtonA, "hit_start_frame": 9, "hit_end_frame": 15, "detect_near_x": 20.0, "detect_far_x": 570.0, "detect_near_y": 270.0, "detect_far_y": 520.0},
	# AttackS4
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 16, "hit_end_frame": 23, "detect_near_x": 250.0, "detect_far_x": 1170.0, "detect_near_y": 225.0, "detect_far_y": 590.0},
	# AttackHi3
	{"input_kind": nFTComputerInputStickTiltHiButtonA, "hit_start_frame": 8, "hit_end_frame": 23, "detect_near_x": -395.0, "detect_far_x": 700.0, "detect_near_y": -85.0, "detect_far_y": 955.0},
	# AttackHi4
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 4, "hit_end_frame": 11, "detect_near_x": -115.0, "detect_far_x": 460.0, "detect_near_y": 80.0, "detect_far_y": 1000.0},
	# AttackLw3
	{"input_kind": nFTComputerInputStickTiltLwButtonA, "hit_start_frame": 8, "hit_end_frame": 15, "detect_near_x": -95.0, "detect_far_x": 540.0, "detect_near_y": -180.0, "detect_far_y": 260.0},
	# AttackLw4
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 9, "hit_end_frame": 23, "detect_near_x": -630.0, "detect_far_x": 670.0, "detect_near_y": -260.0, "detect_far_y": 300.0},
	# SpecialN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 42, "hit_end_frame": 46, "detect_near_x": 200.0, "detect_far_x": 1045.0, "detect_near_y": 100.0, "detect_far_y": 440.0},
	# SpecialHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 13, "hit_end_frame": 44, "detect_near_x": 90.0, "detect_far_x": 565.0, "detect_near_y": 125.0, "detect_far_y": 1985.0},
	# SpecialLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 12, "hit_end_frame": 39, "detect_near_x": -10.0, "detect_far_x": 1720.0, "detect_near_y": 320.0, "detect_far_y": 0.0},
	# Catch
	{"input_kind": nFTComputerInputStickNButtonZButtonA, "hit_start_frame": 7, "hit_end_frame": 7, "detect_near_x": 170.0, "detect_far_x": 470.0, "detect_near_y": 140.0, "detect_far_y": 440.0},
	# End of Ground Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# AttackAirN
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 4, "hit_end_frame": 27, "detect_near_x": -144.0, "detect_far_x": 311.0, "detect_near_y": 119.0, "detect_far_y": 407.0},
	# AttackAirF / AttackAirB
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 7, "hit_end_frame": 18, "detect_near_x": -629.0, "detect_far_x": -81.0, "detect_near_y": 118.0, "detect_far_y": 533.0},
	# AttackAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 5, "hit_end_frame": 13, "detect_near_x": -604.0, "detect_far_x": 568.0, "detect_near_y": 128.0, "detect_far_y": 1103.0},
	# AttackAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 8, "hit_end_frame": 25, "detect_near_x": -249.0, "detect_far_x": 192.0, "detect_near_y": -150.0, "detect_far_y": 426.0},
	# SpecialAirN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 42, "hit_end_frame": 46, "detect_near_x": 161.0, "detect_far_x": 859.0, "detect_near_y": 100.0, "detect_far_y": 442.0},
	# SpecialAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 13, "hit_end_frame": 44, "detect_near_x": 89.0, "detect_far_x": 570.0, "detect_near_y": 123.0, "detect_far_y": 423.0},
	# SpecialAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 12, "hit_end_frame": 30, "detect_near_x": -247.0, "detect_far_x": 265.0, "detect_near_y": -139.0, "detect_far_y": 516.0},
	# End of Aerial Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
]

## 0x80187C64
static var dFTComputerAttacksPurin: Array = [
	# Attack11
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 5, "hit_end_frame": 6, "detect_near_x": 100.0, "detect_far_x": 500.0, "detect_near_y": 50.0, "detect_far_y": 270.0},
	# AttackS3
	{"input_kind": nFTComputerInputStickTiltAutoXButtonA, "hit_start_frame": 7, "hit_end_frame": 10, "detect_near_x": 55.0, "detect_far_x": 520.0, "detect_near_y": 90.0, "detect_far_y": 330.0},
	# AttackS4
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 12, "hit_end_frame": 19, "detect_near_x": 310.0, "detect_far_x": 1115.0, "detect_near_y": 30.0, "detect_far_y": 340.0},
	# AttackHi3
	{"input_kind": nFTComputerInputStickTiltHiButtonA, "hit_start_frame": 7, "hit_end_frame": 14, "detect_near_x": -455.0, "detect_far_x": 220.0, "detect_near_y": 110.0, "detect_far_y": 745.0},
	# AttackHi4
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 8, "hit_end_frame": 14, "detect_near_x": -345.0, "detect_far_x": 430.0, "detect_near_y": -20.0, "detect_far_y": 550.0},
	# AttackLw3
	{"input_kind": nFTComputerInputStickTiltLwButtonA, "hit_start_frame": 11, "hit_end_frame": 15, "detect_near_x": 30.0, "detect_far_x": 610.0, "detect_near_y": 25.0, "detect_far_y": 255.0},
	# AttackLw4
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 8, "hit_end_frame": 27, "detect_near_x": -435.0, "detect_far_x": 435.0, "detect_near_y": -90.0, "detect_far_y": 220.0},
	# SpecialN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 12, "hit_end_frame": 27, "detect_near_x": -255.0, "detect_far_x": 805.0, "detect_near_y": -115.0, "detect_far_y": 335.0},
	# SpecialHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 28, "hit_end_frame": 125, "detect_near_x": -355.0, "detect_far_x": 385.0, "detect_near_y": -125.0, "detect_far_y": 610.0},
	# SpecialLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# Catch
	{"input_kind": nFTComputerInputStickNButtonZButtonA, "hit_start_frame": 7, "hit_end_frame": 7, "detect_near_x": 210.0, "detect_far_x": 550.0, "detect_near_y": 130.0, "detect_far_y": 370.0},
	# End of Ground Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# AttackAirN
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 6, "hit_end_frame": 33, "detect_near_x": -110.0, "detect_far_x": 463.0, "detect_near_y": -86.0, "detect_far_y": 241.0},
	# AttackAirF / AttackAirB
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 8, "hit_end_frame": 21, "detect_near_x": -354.0, "detect_far_x": 145.0, "detect_near_y": -20.0, "detect_far_y": 267.0},
	# AttackAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 8, "hit_end_frame": 16, "detect_near_x": -236.0, "detect_far_x": 289.0, "detect_near_y": 123.0, "detect_far_y": 508.0},
	# AttackAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 5, "hit_end_frame": 33, "detect_near_x": -117.0, "detect_far_x": 285.0, "detect_near_y": -306.0, "detect_far_y": 180.0},
	# SpecialAirN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 12, "hit_end_frame": 27, "detect_near_x": -263.0, "detect_far_x": 530.0, "detect_near_y": -117.0, "detect_far_y": 285.0},
	# SpecialAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 28, "hit_end_frame": 125, "detect_near_x": -358.0, "detect_far_x": 387.0, "detect_near_y": -127.0, "detect_far_y": 611.0},
	# SpecialAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# End of Aerial Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
]

## 0x80187E94
static var dFTComputerAttacksNess: Array = [
	# Attack11
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 2, "hit_end_frame": 3, "detect_near_x": 150.0, "detect_far_x": 400.0, "detect_near_y": 35.0, "detect_far_y": 210.0},
	# AttackS3
	{"input_kind": nFTComputerInputStickTiltAutoXButtonA, "hit_start_frame": 7, "hit_end_frame": 11, "detect_near_x": 220.0, "detect_far_x": 580.0, "detect_near_y": 70.0, "detect_far_y": 300.0},
	# AttackS4
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 18, "hit_end_frame": 21, "detect_near_x": 80.0, "detect_far_x": 590.0, "detect_near_y": -40.0, "detect_far_y": 285.0},
	# AttackHi3
	{"input_kind": nFTComputerInputStickTiltHiButtonA, "hit_start_frame": 5, "hit_end_frame": 19, "detect_near_x": -250.0, "detect_far_x": 250.0, "detect_near_y": 215.0, "detect_far_y": 665.0},
	# AttackHi4
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 13, "hit_end_frame": 25, "detect_near_x": -515.0, "detect_far_x": 540.0, "detect_near_y": 10.0, "detect_far_y": 730.0},
	# AttackLw3
	{"input_kind": nFTComputerInputStickTiltLwButtonA, "hit_start_frame": 4, "hit_end_frame": 8, "detect_near_x": -5.0, "detect_far_x": 380.0, "detect_near_y": -100.0, "detect_far_y": 140.0},
	# AttackLw4
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 14, "hit_end_frame": 53, "detect_near_x": -680.0, "detect_far_x": 870.0, "detect_near_y": -100.0, "detect_far_y": 290.0},
	# SpecialN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 10, "hit_end_frame": 15, "detect_near_x": 500.0, "detect_far_x": 1000.0, "detect_near_y": -40.0, "detect_far_y": 285.0},
	# SpecialHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# SpecialLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# Catch
	{"input_kind": nFTComputerInputStickNButtonZButtonA, "hit_start_frame": 7, "hit_end_frame": 7, "detect_near_x": 50.0, "detect_far_x": 360.0, "detect_near_y": 95.0, "detect_far_y": 405.0},
	# End of Ground Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# AttackAirN
	{"input_kind": nFTComputerInputStickNButtonA, "hit_start_frame": 5, "hit_end_frame": 30, "detect_near_x": -162.0, "detect_far_x": 220.0, "detect_near_y": -92.0, "detect_far_y": 194.0},
	# AttackAirF / AttackAirB
	{"input_kind": nFTComputerInputStickSmashAutoXNYButtonA, "hit_start_frame": 10, "hit_end_frame": 19, "detect_near_x": -457.0, "detect_far_x": 148.0, "detect_near_y": -92.0, "detect_far_y": 296.0},
	# AttackAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonA, "hit_start_frame": 8, "hit_end_frame": 16, "detect_near_x": -335.0, "detect_far_x": 377.0, "detect_near_y": -33.0, "detect_far_y": 522.0},
	# AttackAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonA, "hit_start_frame": 5, "hit_end_frame": 21, "detect_near_x": -129.0, "detect_far_x": 192.0, "detect_near_y": -192.0, "detect_far_y": 129.0},
	# SpecialAirN
	{"input_kind": nFTComputerInputStickSmashAutoXButtonB, "hit_start_frame": 10, "hit_end_frame": 15, "detect_near_x": 500.0, "detect_far_x": 1000.0, "detect_near_y": -40.0, "detect_far_y": 285.0},
	# SpecialAirHi
	{"input_kind": nFTComputerInputStickSmashHiButtonB, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# SpecialAirLw
	{"input_kind": nFTComputerInputStickSmashLwButtonB, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
	# End of Aerial Attacks
	{"input_kind": -1, "hit_start_frame": 0, "hit_end_frame": 0, "detect_near_x": 0.0, "detect_far_x": 0.0, "detect_near_y": 0.0, "detect_far_y": 0.0},
]

## 0x801880C4
static var dFTComputerAttackList: Array = [
	dFTComputerAttacksMario,           # Mario
	dFTComputerAttacksFox,             # Fox
	dFTComputerAttacksDonkey,          # Donkey Kong
	dFTComputerAttacksSamus,           # Samus
	dFTComputerAttacksLuigi,           # Luigi
	dFTComputerAttacksLink,            # Link
	dFTComputerAttacksYoshi,           # Yoshi
	dFTComputerAttacksCaptain,         # Captain Falcon
	dFTComputerAttacksKirby,           # Kirby
	dFTComputerAttacksPikachu,         # Pikachu
	dFTComputerAttacksPurin,           # Jigglypuff
	dFTComputerAttacksNess,            # Ness
	null,                              # Master Hand
	dFTComputerAttacksMario,           # Metal Mario
	dFTComputerAttacksMario,           # Poly Mario
	dFTComputerAttacksFox,             # Poly Fox
	dFTComputerAttacksDonkey,          # Poly Donkey Kong
	dFTComputerAttacksSamus,           # Poly Samus
	dFTComputerAttacksLuigi,           # Poly Luigi
	dFTComputerAttacksLink,            # Poly Link
	dFTComputerAttacksYoshi,           # Poly Yoshi
	dFTComputerAttacksCaptain,         # Poly Captain Falcon
	dFTComputerAttacksKirby,           # Poly Kirby
	dFTComputerAttacksPikachu,         # Poly Pikachu
	dFTComputerAttacksPurin,           # Poly Jigglypuff
	dFTComputerAttacksNess,            # Poly Ness
	dFTComputerAttacksDonkey,          # Giant Donkey Kong
]

## 0x80188130
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript0: PackedByteArray = [0xA0, 0x00, 0xB0, 0x00, 0xFF]

## 0x80188138
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandMoveAuto, 0)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript1: PackedByteArray = [0xC0, 0xFF]

## 0x8018813C
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 1)
##   FTCOMPUTER_EVENT_STICK_X(FTCOMPUTER_STICK_AUTOFULL, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript2: PackedByteArray = [0xA0, 0x00, 0xB1, 0x00, 0xA1, 0x7F, 0xFF]

## 0x80188144
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandMoveAuto, 0)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript3: PackedByteArray = [0xA0, 0x00, 0xB1, 0x00, 0xC0, 0xFF]

## 0x8018814C
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandMoveAuto, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZRelease, 0)
##   FTCOMPUTER_EVENT_STICK_Y(I_CONTROLLER_RANGE_MAX, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript4: PackedByteArray = [0xA0, 0x00, 0xB1, 0x00, 0xC0, 0x50, 0xB1, 0x50, 0xFF]

## 0x80188158
##   FTCOMPUTER_EVENT_STICK_X(FTCOMPUTER_STICK_AUTOHALF, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript5: PackedByteArray = [0xA0, 0x80, 0x01, 0xA0, 0x00, 0x11, 0xFF]

## 0x80188160
##   FTCOMPUTER_EVENT_STICK_X(FTCOMPUTER_STICK_AUTOHALF, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 5)
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript6: PackedByteArray = [0xA0, 0x80, 0xB5, 0x00, 0xA0, 0x00, 0x01, 0x11, 0xFF]

## 0x8018816C
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandMoveAuto, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript7: PackedByteArray = [0xC0, 0x01, 0x11, 0xFF]

## 0x80188170
##   FTCOMPUTER_EVENT_STICK_X(FTCOMPUTER_STICK_AUTOFULL, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 0)
##   FTCOMPUTER_EVENT_STICK_X(0, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript8: PackedByteArray = [0xA0, 0x7F, 0x01, 0x10, 0xA1, 0x00, 0xFF]

## 0x80188178
##   FTCOMPUTER_EVENT_STICK_X(FTCOMPUTER_STICK_AUTOFULL, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBPress, 1)
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBRelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript9: PackedByteArray = [0xA0, 0x7F, 0xB0, 0x00, 0x21, 0xA0, 0x00, 0x31, 0xFF]

## 0x80188184
##   FTCOMPUTER_EVENT_STICK_X(FTCOMPUTER_STICK_AUTOHALF, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 5)
##   FTCOMPUTER_EVENT_STICK_X(FTCOMPUTER_STICK_AUTOFULL, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBPress, 1)
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBRelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript10: PackedByteArray = [0xA0, 0x80, 0xB5, 0x00, 0xA0, 0x7F, 0x21, 0xA0, 0x00, 0x31, 0xFF]

## 0x80188190
##   FTCOMPUTER_EVENT_STICK_X(FTCOMPUTER_STICK_AUTOHALF, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBPress, 1)
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBRelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript11: PackedByteArray = [0xA0, 0x80, 0xB1, 0x00, 0x21, 0xA0, 0x00, 0x31, 0xFF]

## 0x8018819C
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZPress, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZRelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript12: PackedByteArray = [0x41, 0x51, 0xFF]

## 0x801881A0
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(I_CONTROLLER_RANGE_MAX, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBPress, 1)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBRelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript13: PackedByteArray = [0xA0, 0x00, 0xB0, 0x50, 0x21, 0xB0, 0x00, 0x31, 0xFF]

## 0x801881AC
##   FTCOMPUTER_EVENT_STICK_X(FTCOMPUTER_STICK_AUTOHALF, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 5)
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(I_CONTROLLER_RANGE_MAX, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBPress, 1)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBRelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript14: PackedByteArray = [0xA0, 0x80, 0xB5, 0x00, 0xA0, 0x00, 0xB0, 0x50, 0x21, 0xB0, 0x00, 0x31, 0xFF]

## 0x801881BC
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBRelease, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonLPress, 5)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonLRelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript15: PackedByteArray = [0xA0, 0x00, 0xB0, 0x00, 0x10, 0x30, 0x65, 0x71, 0xFF]

## 0x801881C8
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZPress, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZRelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript16: PackedByteArray = [0x41, 0x51, 0xFF]

## 0x801881CC
##   FTCOMPUTER_EVENT_STICK_X(FTCOMPUTER_STICK_AUTOHALF, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 5)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript17: PackedByteArray = [0xA0, 0x80, 0xB5, 0x00, 0xFF]

## 0x801881D4
##   FTCOMPUTER_EVENT_STICK_X(FTCOMPUTER_STICK_AUTOHALF, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript18: PackedByteArray = [0xA0, 0x80, 0xB1, 0x00, 0xFF]

## 0x801881DC
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript19: PackedByteArray = [0xA0, 0x00, 0xB0, 0x00, 0x01, 0x11, 0xFF]

## 0x801881E4
##   FTCOMPUTER_EVENT_STICK_X(FTCOMPUTER_STICK_AUTOHALF, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 5)
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript20: PackedByteArray = [0xA0, 0x80, 0xB5, 0x00, 0xA0, 0x00, 0x01, 0x11, 0xFF]

## 0x801881F0
##   FTCOMPUTER_EVENT_STICK_X(FTCOMPUTER_STICK_AUTOFULL, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript21: PackedByteArray = [0xA0, 0x7F, 0xB0, 0x00, 0x01, 0xA0, 0x00, 0x11, 0xFF]

## 0x801881FC
##   FTCOMPUTER_EVENT_STICK_X(FTCOMPUTER_STICK_AUTOHALF, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 1)
##   FTCOMPUTER_EVENT_STICK_X(FTCOMPUTER_STICK_AUTOFULL, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript22: PackedByteArray = [0xA0, 0x80, 0xB1, 0x00, 0xA0, 0x7F, 0x01, 0xA0, 0x00, 0x11, 0xFF]

## 0x80188208
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(I_CONTROLLER_RANGE_MAX / 2, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript23: PackedByteArray = [0xA0, 0x00, 0xB0, 0x28, 0x01, 0xB0, 0x00, 0x11, 0xFF]

## 0x80188214
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(I_CONTROLLER_RANGE_MAX, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript24: PackedByteArray = [0xA0, 0x00, 0xB0, 0x50, 0x01, 0xB0, 0x00, 0x11, 0xFF]

## 0x80188220
##   FTCOMPUTER_EVENT_STICK_X(FTCOMPUTER_STICK_AUTOHALF, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 5)
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(FTCOMPUTER_STICK_AUTOHALF, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript25: PackedByteArray = [0xA0, 0x80, 0xB5, 0x00, 0xA0, 0x00, 0xB0, 0x80, 0x01, 0xB0, 0x00, 0x11, 0xFF]

## 0x80188230
##   FTCOMPUTER_EVENT_STICK_X(FTCOMPUTER_STICK_AUTOHALF, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 5)
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(FTCOMPUTER_STICK_AUTOFULL, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript26: PackedByteArray = [0xA0, 0x80, 0xB5, 0x00, 0xA0, 0x00, 0xB0, 0x7F, 0x01, 0xB0, 0x00, 0x11, 0xFF]

## 0x80188240
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(-I_CONTROLLER_RANGE_MAX, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBPress, 1)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBRelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript27: PackedByteArray = [0xA0, 0x00, 0xB0, 0xB0, 0x21, 0xB0, 0x00, 0x31, 0xFF]

## 0x8018824C
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZPress, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZRelease, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript28: PackedByteArray = [0xA0, 0x00, 0xB0, 0x00, 0x41, 0x50, 0x01, 0x11, 0xFF]

## 0x80188258
##   FTCOMPUTER_EVENT_STICK_X(FTCOMPUTER_STICK_AUTOHALF, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 5)
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZPress, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZRelease, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript29: PackedByteArray = [0xA0, 0x80, 0xB5, 0x00, 0xA0, 0x00, 0x41, 0x50, 0x01, 0x11, 0xFF]

## 0x80188264
##   FTCOMPUTER_EVENT_STICK_X(0, 1)
##   FTCOMPUTER_EVENT_STICK_X(-I_CONTROLLER_RANGE_MAX, 2)
##   FTCOMPUTER_EVENT_STICK_X(0, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript30: PackedByteArray = [0xA1, 0x00, 0xA2, 0xB0, 0xA1, 0x00, 0xFF]

## 0x8018826C
##   FTCOMPUTER_EVENT_STICK_X(0, 1)
##   FTCOMPUTER_EVENT_STICK_X(I_CONTROLLER_RANGE_MAX, 2)
##   FTCOMPUTER_EVENT_STICK_X(0, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript31: PackedByteArray = [0xA1, 0x00, 0xA2, 0x50, 0xA1, 0x00, 0xFF]

## 0x80188274
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(-I_CONTROLLER_RANGE_MAX / 2, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript32: PackedByteArray = [0xA0, 0x00, 0xB0, 0xD8, 0x01, 0xB0, 0x00, 0x11, 0xFF]

## 0x80188280
##   FTCOMPUTER_EVENT_STICK_X(FTCOMPUTER_STICK_AUTOHALF, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 5)
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(-I_CONTROLLER_RANGE_MAX / 2, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript33: PackedByteArray = [0xA0, 0x80, 0xB5, 0x00, 0xA0, 0x00, 0xB0, 0xD8, 0x01, 0xB0, 0x00, 0x11, 0xFF]

## 0x80188290
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 1)
##   FTCOMPUTER_EVENT_STICK_Y(-I_CONTROLLER_RANGE_MAX, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript34: PackedByteArray = [0xA0, 0x00, 0xB1, 0x00, 0xB0, 0xB0, 0x01, 0xB0, 0x00, 0x11, 0xFF]

## 0x8018829C
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZPress, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript35: PackedByteArray = [0xA0, 0x00, 0xB0, 0x00, 0x41, 0xFF]

## 0x801882A4
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZRelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript36: PackedByteArray = [0x51, 0xFF]

## 0x801882A8
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBRelease, 1)
##   FTCOMPUTER_EVENT_STICK_Y(-I_CONTROLLER_RANGE_MAX, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBPress, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript37: PackedByteArray = [0xA0, 0x00, 0x31, 0xB0, 0xB0, 0x21, 0xFF]

## 0x801882B0
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBRelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript38: PackedByteArray = [0xB0, 0x00, 0x31, 0xFF]

## 0x801882B4
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandMoveAuto, 0)
##   FTCOMPUTER_EVENT_STICK_Y(-I_CONTROLLER_RANGE_MAX, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript39: PackedByteArray = [0xA0, 0x00, 0xB1, 0x00, 0xC0, 0xB1, 0xB0, 0xFF]

## 0x801882BC
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBRelease, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZRelease, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript40: PackedByteArray = [0xA0, 0x00, 0xB0, 0x00, 0x30, 0x50, 0x01, 0x11, 0xFF]

## 0x801882C8
##   FTCOMPUTER_EVENT_STICK_X(FTCOMPUTER_STICK_AUTOHALF, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBRelease, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZRelease, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript41: PackedByteArray = [0xA0, 0x80, 0xB0, 0x00, 0x30, 0x50, 0x01, 0x11, 0xFF]

## 0x801882D4
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandMoveAuto, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBRelease, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZRelease, 5)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZPress, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZRelease, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 10)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript42: PackedByteArray = [0xC0, 0x10, 0x30, 0x55, 0x40, 0x01, 0x50, 0x1A, 0xFF]

## 0x801882E0
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBRelease, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZRelease, 0)
##   FTCOMPUTER_EVENT_STICK_Y(I_CONTROLLER_RANGE_MAX, 15)
##   FTCOMPUTER_EVENT_STICK_Y(0, 15)
##   FTCOMPUTER_EVENT_STICK_Y(-I_CONTROLLER_RANGE_MAX / 2, 3)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZPress, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZRelease, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 10)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript43: PackedByteArray = [0xA0, 0x00, 0xB1, 0x00, 0x10, 0x30, 0x50, 0xBF, 0x50, 0xBF, 0x00, 0xB3, 0xD8, 0x40, 0x01, 0x50, 0x1A, 0xFF]

## 0x801882F4
##   FTCOMPUTER_EVENT_STICK_X(I_CONTROLLER_RANGE_MAX, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 3)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_STICK_X(-I_CONTROLLER_RANGE_MAX, 3)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 1)
##   FTCOMPUTER_EVENT_STICK_X(I_CONTROLLER_RANGE_MAX, 3)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_STICK_X(-I_CONTROLLER_RANGE_MAX, 3)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 1)
##   FTCOMPUTER_EVENT_STICK_X(I_CONTROLLER_RANGE_MAX, 3)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonAPress, 1)
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonARelease, 0)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript44: PackedByteArray = [0xA0, 0x50, 0x10, 0xB3, 0x00, 0x01, 0xA3, 0xB0, 0x11, 0xA3, 0x50, 0x01, 0xA3, 0xB0, 0x11, 0xA3, 0x50, 0x01, 0xA0, 0x00, 0x10, 0xFF]

## 0x8018830C
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZPress, 1)
##   FTCOMPUTER_EVENT_STICK_X(0, 1)
##   FTCOMPUTER_EVENT_STICK_X(-I_CONTROLLER_RANGE_MAX, 1)
##   FTCOMPUTER_EVENT_STICK_X(0, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript45: PackedByteArray = [0xA0, 0x00, 0xB0, 0x00, 0x41, 0xA1, 0x00, 0xA1, 0xB0, 0xA1, 0x00, 0xFF]

## 0x80188318
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(0, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonZPress, 1)
##   FTCOMPUTER_EVENT_STICK_X(0, 1)
##   FTCOMPUTER_EVENT_STICK_X(I_CONTROLLER_RANGE_MAX, 1)
##   FTCOMPUTER_EVENT_STICK_X(0, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript46: PackedByteArray = [0xA0, 0x00, 0xB0, 0x00, 0x41, 0xA1, 0x00, 0xA1, 0x50, 0xA1, 0x00, 0xFF]

## 0x80188324
##   FTCOMPUTER_EVENT_STICK_X(0, 0)
##   FTCOMPUTER_EVENT_STICK_Y(I_CONTROLLER_RANGE_MAX, 0)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBPress, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandMoveAuto, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandMoveAuto, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandMoveAuto, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandMoveAuto, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandMoveAuto, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandMoveAuto, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandMoveAuto, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandMoveAuto, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandMoveAuto, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandMoveAuto, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandMoveAuto, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandMoveAuto, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandMoveAuto, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandMoveAuto, 1)
##   FTCOMPUTER_EVENT_INSTRUCTION(nFTComputerCommandButtonBRelease, 1)
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript47: PackedByteArray = [0xA0, 0x00, 0xB0, 0x50, 0x21, 0xC1, 0xC1, 0xC1, 0xC1, 0xC1, 0xC1, 0xC1, 0xC1, 0xC1, 0xC1, 0xC1, 0xC1, 0xC1, 0xC1, 0x31, 0xFF]

## 0x8018833C
##   FTCOMPUTER_EVENT_PKTHUNDER()
##   FTCOMPUTER_EVENT_END()
static var dFTComputerPlayerInputScript48: PackedByteArray = [0xF3, 0xFF]

## 0x80188340 - CPU player input events
static var dFTComputerPlayerInputScripts: Array = [
	dFTComputerPlayerInputScript0,
	dFTComputerPlayerInputScript1,
	dFTComputerPlayerInputScript2,
	dFTComputerPlayerInputScript3,
	dFTComputerPlayerInputScript4,
	dFTComputerPlayerInputScript5,
	dFTComputerPlayerInputScript6,
	dFTComputerPlayerInputScript7,
	dFTComputerPlayerInputScript8,
	dFTComputerPlayerInputScript9,
	dFTComputerPlayerInputScript10,
	dFTComputerPlayerInputScript11,
	dFTComputerPlayerInputScript12,
	dFTComputerPlayerInputScript13,
	dFTComputerPlayerInputScript14,
	dFTComputerPlayerInputScript15,
	dFTComputerPlayerInputScript16,
	dFTComputerPlayerInputScript17,
	dFTComputerPlayerInputScript18,
	dFTComputerPlayerInputScript19,
	dFTComputerPlayerInputScript20,
	dFTComputerPlayerInputScript21,
	dFTComputerPlayerInputScript22,
	dFTComputerPlayerInputScript23,
	dFTComputerPlayerInputScript25,  # WARNING: 25 and 24 are swapped!
	dFTComputerPlayerInputScript24,  # WARNING: 25 and 24 are swapped!
	dFTComputerPlayerInputScript26,
	dFTComputerPlayerInputScript27,
	dFTComputerPlayerInputScript28,
	dFTComputerPlayerInputScript29,
	dFTComputerPlayerInputScript30,
	dFTComputerPlayerInputScript31,
	dFTComputerPlayerInputScript32,
	dFTComputerPlayerInputScript33,
	dFTComputerPlayerInputScript34,
	dFTComputerPlayerInputScript35,
	dFTComputerPlayerInputScript36,
	dFTComputerPlayerInputScript37,
	dFTComputerPlayerInputScript38,
	dFTComputerPlayerInputScript39,
	dFTComputerPlayerInputScript40,
	dFTComputerPlayerInputScript41,
	dFTComputerPlayerInputScript42,
	dFTComputerPlayerInputScript43,
	dFTComputerPlayerInputScript44,
	dFTComputerPlayerInputScript45,
	dFTComputerPlayerInputScript46,
	dFTComputerPlayerInputScript47,
	dFTComputerPlayerInputScript48,
]

# // // // // // // // // // // // //
#                               //
#           FUNCTIONS           //
#                               //
# // // // // // // // // // // // //

## 0x80131B00
static func ftComputerGetOwnWeapon(fp):
	for weapon_gobj in Sim.get_link(nGCCommonLinkIDWeapon):
		var wp: Weapon = wpGetStruct(weapon_gobj)

		if wp.owner_gobj == fp.fighter_gobj:
			return wp
	return null

## 0x80131B44 - C returns &DObjGetStruct(wp->weapon_gobj)->translate.vec.f (callers only read it),
## so the position vector is returned, or null.
static func ftComputerGetOwnWeaponPositionKind(fp, kind):
	for weapon_gobj in Sim.get_link(nGCCommonLinkIDWeapon):
		var wp: Weapon = wpGetStruct(weapon_gobj)

		if (wp.owner_gobj == fp.fighter_gobj) and (wp.kind == kind):
			return DObjGetStruct(wp.weapon_gobj).translate
	return null

## 0x80131BA0
static func ftComputerSetControlPKThunder(fp) -> void:
	var pos = ftComputerGetOwnWeaponPositionKind(fp, nWPKindPKThunderTrail)
	var com: FTComputer = fp.computer

	if pos != null:
		var dist_x: float = com.target_pos.x - pos.x
		var dist_y: float = com.target_pos.y - pos.y

		var scale: float = 1.0 / sqrtf(SQUARE(dist_x) + SQUARE(dist_y))

		fp.input.cp.stick_range.x = _s8(_f2i(float(F_CONTROLLER_RANGE_MAX) * dist_x * scale))
		fp.input.cp.stick_range.y = _s8(_f2i(float(F_CONTROLLER_RANGE_MAX) * dist_y * scale))
	else:
		fp.input.cp.stick_range.x = 0
		fp.input.cp.stick_range.y = 0

## 0x80131C68
@warning_ignore("integer_division")
static func ftComputerUpdateInputs(this_fp) -> void:
	var com: FTComputer = this_fp.computer
	var p_command                       # C: u8 *p_command -> script array + p_index
	var p_index: int
	var command: int                    # u8
	var var_t1: int = 0                 # s8; uninitialized in C, only read by the (unused) VAR opcodes
	var stick_range_y: int              # s16
	var stick_range_x: int              # s16
	var dist_x: float
	var dist_y: float

	if com.input_wait != 0:
		com.input_wait = _u8(com.input_wait - 1)

		if com.input_wait == 0:
			p_command = com.p_command
			p_index = com.p_command_index

			while com.input_wait == 0:
				command = p_command[p_index]
				p_index += 1

				if command < FTCOMPUTER_COMMAND_DEFAULT_MAX:
					com.input_wait = command & FTCOMPUTER_COMMAND_TIMER_MASK

					match command & FTCOMPUTER_COMMAND_OPCODE_MASK:
						FTCOMPUTER_COMMAND_BUTTON_A_PRESS:
							this_fp.input.cp.button_inputs |= A_BUTTON

						FTCOMPUTER_COMMAND_BUTTON_A_RELEASE:
							this_fp.input.cp.button_inputs &= ~A_BUTTON

						FTCOMPUTER_COMMAND_BUTTON_B_PRESS:
							this_fp.input.cp.button_inputs |= B_BUTTON

						FTCOMPUTER_COMMAND_BUTTON_B_RELEASE:
							this_fp.input.cp.button_inputs &= ~B_BUTTON

						FTCOMPUTER_COMMAND_BUTTON_Z_PRESS:
							this_fp.input.cp.button_inputs |= Z_TRIG

						FTCOMPUTER_COMMAND_BUTTON_Z_RELEASE:
							this_fp.input.cp.button_inputs &= ~Z_TRIG

						FTCOMPUTER_COMMAND_BUTTON_L_PRESS:
							this_fp.input.cp.button_inputs |= L_TRIG

						FTCOMPUTER_COMMAND_BUTTON_L_RELEASE:
							this_fp.input.cp.button_inputs &= ~L_TRIG

						FTCOMPUTER_COMMAND_BUTTON_START_PRESS:
							this_fp.input.cp.button_inputs |= START_BUTTON

						FTCOMPUTER_COMMAND_BUTTON_START_RELEASE:
							this_fp.input.cp.button_inputs &= ~START_BUTTON

						FTCOMPUTER_COMMAND_STICK_X_TILT:
							match p_command[p_index]:
								FTCOMPUTER_STICK_AUTOFULL:
									this_fp.input.cp.stick_range.x = (I_CONTROLLER_RANGE_MAX) if (this_fp.joints[nFTPartsJointTopN].translate.x < com.target_pos.x) else -(I_CONTROLLER_RANGE_MAX)
									p_index += 1

								FTCOMPUTER_STICK_AUTOHALF:
									this_fp.input.cp.stick_range.x = (I_CONTROLLER_RANGE_MAX / 2) if (this_fp.joints[nFTPartsJointTopN].translate.x < com.target_pos.x) else -(I_CONTROLLER_RANGE_MAX / 2)
									p_index += 1

								_:
									this_fp.input.cp.stick_range.x = _s8(p_command[p_index])
									p_index += 1

						FTCOMPUTER_COMMAND_STICK_Y_TILT:
							match p_command[p_index]:
								FTCOMPUTER_STICK_AUTOFULL:
									this_fp.input.cp.stick_range.y = (I_CONTROLLER_RANGE_MAX) if (this_fp.joints[nFTPartsJointTopN].translate.y < com.target_pos.y) else -(I_CONTROLLER_RANGE_MAX)
									p_index += 1

								FTCOMPUTER_STICK_AUTOHALF:
									this_fp.input.cp.stick_range.y = (I_CONTROLLER_RANGE_MAX / 2) if (this_fp.joints[nFTPartsJointTopN].translate.y < com.target_pos.y) else -(I_CONTROLLER_RANGE_MAX / 2)
									p_index += 1

								_:
									this_fp.input.cp.stick_range.y = _s8(p_command[p_index])
									p_index += 1

						FTCOMPUTER_COMMAND_MOVEAUTO:
							dist_x = com.target_pos.x - this_fp.joints[nFTPartsJointTopN].translate.x
							dist_y = com.target_pos.y - this_fp.joints[nFTPartsJointTopN].translate.y

							if (this_fp.ga == nMPKineticsGround) and (this_fp.level < 5):
								stick_range_x = (I_CONTROLLER_RANGE_MAX / 2) if (ABSF(dist_x) > 100.0) else 0

							elif this_fp.ga == nMPKineticsGround:
								if (com.dash_predict * 1.5) < ABSF(dist_x):
									stick_range_x = (I_CONTROLLER_RANGE_MAX)
								else:
									if com.dash_predict < ABSF(dist_x):
										stick_range_x = _s16(_f2i((2.0 * ((ABSF(dist_x) - com.dash_predict) / com.dash_predict) * (float(F_CONTROLLER_RANGE_MAX) / 2.0)) + (float(F_CONTROLLER_RANGE_MAX) / 2.0)))
									else:
										stick_range_x = (I_CONTROLLER_RANGE_MAX / 2) if (ABSF(dist_x) > 100.0) else 0
							else:
								stick_range_x = (I_CONTROLLER_RANGE_MAX) if ((ABSF(dist_x) > 100.0) or ((this_fp.lr * dist_x) < 0.0)) else (I_CONTROLLER_RANGE_MAX / 4)

							stick_range_y = I_CONTROLLER_RANGE_MAX

							if this_fp.ga == nMPKineticsGround:
								if this_fp.status_id != nFTCommonStatusKneeBend:
									if com.target_line_id == this_fp.coll_data.floor_line_id:
										dist_y = 0.0
										stick_range_y = 0
									if (
										(com.ftcom_flags_0x4A_b1 != FALSE) and
										(
											(_ftGetComTargetFighter(com).status_id == nFTCommonStatusCliffCatch) or
											(_ftGetComTargetFighter(com).status_id == nFTCommonStatusCliffWait)
										)
									):
										dist_y = 0.0
										stick_range_y = 0
							else:
								if (
									(
										(this_fp.fkind != nFTKindFox) or
										(
											(this_fp.status_id != nFTFoxStatusSpecialHiStart) and
											(this_fp.status_id != nFTFoxStatusSpecialAirHiStart) and
											(this_fp.status_id != nFTFoxStatusSpecialHiHold) and
											(this_fp.status_id != nFTFoxStatusSpecialAirHiHold)
										)
									)
									and
									(dist_y < 0)
								):
									dist_y = 0.0
									stick_range_y = 0

								match com.behavior:
									nFTComputerBehaviorYoshiTeam:
										if this_fp.joints[nFTPartsJointTopN].translate.y < 0:
											dist_y = 0.0
											stick_range_y = 0

									nFTComputerBehaviorKirbyTeam, nFTComputerBehaviorPolyTeam:
										if this_fp.joints[nFTPartsJointTopN].translate.y < -300.0:
											dist_y = 0.0
											stick_range_y = 0

							if (dist_x != 0.0) and (dist_y != 0.0):
								if ABSF(dist_y) < ABSF(dist_x):
									this_fp.input.cp.stick_range.x = _s8(stick_range_x if (dist_x > 0.0) else -stick_range_x)

									this_fp.input.cp.stick_range.y = _s8(_f2i(ABSF((dist_y / dist_x)) * (stick_range_y if (dist_y > 0.0) else -stick_range_y)))
								else:
									this_fp.input.cp.stick_range.x = _s8(_f2i(ABSF((dist_x / dist_y)) * (stick_range_x if (dist_x > 0.0) else -stick_range_x)))

									this_fp.input.cp.stick_range.y = _s8(stick_range_y if (dist_y > 0.0) else -stick_range_y)

							elif dist_x != 0.0:
								this_fp.input.cp.stick_range.x = _s8(stick_range_x if (dist_x > 0.0) else -stick_range_x)

								this_fp.input.cp.stick_range.y = _s8(_f2i(ABSF((dist_y / dist_x)) * (stick_range_y if (dist_y > 0.0) else -stick_range_y)))

							elif dist_y != 0.0:
								this_fp.input.cp.stick_range.x = _s8(_f2i(ABSF((dist_x / dist_y)) * (stick_range_x if (dist_x > 0.0) else -stick_range_x)))

								this_fp.input.cp.stick_range.y = _s8(stick_range_y if (dist_y > 0.0) else -stick_range_y)
							else:
								this_fp.input.cp.stick_range.x = 0
								this_fp.input.cp.stick_range.y = 0

						FTCOMPUTER_COMMAND_STICK_X_VAR:
							this_fp.input.cp.stick_range.x = var_t1

						FTCOMPUTER_COMMAND_STICK_Y_VAR:
							this_fp.input.cp.stick_range.y = var_t1
				else:
					if command == FTCOMPUTER_COMMAND_DEFAULT_MAX + 0:
						com.input_wait = p_command[p_index]
						p_index += 1

					elif command == FTCOMPUTER_COMMAND_DEFAULT_MAX + 1:
						var_t1 = 1

					elif command == FTCOMPUTER_COMMAND_DEFAULT_MAX + 2:
						com.input_wait = _u8(var_t1)

					elif command == FTCOMPUTER_COMMAND_DEFAULT_MAX + 3:
						ftComputerSetControlPKThunder(this_fp)

					elif command == FTCOMPUTER_COMMAND_END:
						com.input_wait = 0
						com.p_command = null
						com.p_command_index = 0
						return
			com.p_command = p_command
			com.p_command_index = p_index

## 0x80132564
@warning_ignore("integer_division")
static func ftComputerSetCommandWaitShort(fp, index: int) -> void:
	var com: FTComputer = fp.computer

	if fp.ga == nMPKineticsGround:
		com.input_wait = _u8(_f2i((2.0 * (syUtilsRandFloat() * (FTCOMPUTER_LEVEL_MAX - fp.level))) + ((FTCOMPUTER_LEVEL_MAX - fp.level) * 2) + 1.0))
	else:
		com.input_wait = _u8(_f2i((syUtilsRandFloat() * (FTCOMPUTER_LEVEL_MAX - fp.level)) + ((FTCOMPUTER_LEVEL_MAX - fp.level) / 2) + 1.0))

	com.p_command = dFTComputerPlayerInputScripts[index]
	com.p_command_index = 0

## 0x80132758
static func ftComputerSetCommandImmediate(fp, index: int) -> void:
	var com: FTComputer = fp.computer

	com.input_wait = 1
	com.p_command = dFTComputerPlayerInputScripts[index]
	com.p_command_index = 0

## 0x80132778
static func ftComputerSetCommandWaitLong(fp, index: int) -> void:
	var com: FTComputer = fp.computer

	if fp.ga == nMPKineticsGround:
		com.input_wait = _u8(_f2i((4 * (syUtilsRandFloat() * (FTCOMPUTER_LEVEL_MAX - fp.level))) + ((FTCOMPUTER_LEVEL_MAX - fp.level) * 4) + 1.0))
	else:
		com.input_wait = _u8(_f2i((syUtilsRandFloat() * (FTCOMPUTER_LEVEL_MAX - fp.level)) + (FTCOMPUTER_LEVEL_MAX - fp.level) + 1.0))

	com.p_command = dFTComputerPlayerInputScripts[index]
	com.p_command_index = 0

## 0x8013295C
static func ftComputerCheckFindTarget(this_fp) -> int:
	var com: FTComputer = this_fp.computer
	var other_fp: Fighter
	var this_pos_x: float = this_fp.joints[nFTPartsJointTopN].translate.x
	var this_pos_y: float = this_fp.joints[nFTPartsJointTopN].translate.y
	var distance: float = F32_MAX
	var square_xy: float
	var other_pos_x: float
	var other_pos_y: float

	for other_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		if other_gobj != this_fp.fighter_gobj:
			other_fp = ftGetStruct(other_gobj)

			if this_fp.team != other_fp.team:
				other_pos_x = other_fp.joints[nFTPartsJointTopN].translate.x
				other_pos_y = other_fp.joints[nFTPartsJointTopN].translate.y

				if (
					(other_fp.status_id >= nFTCommonStatusWait) and
					(
						(
							(Mpcollision.func_ovl2_800F8FFC(other_fp.joints[nFTPartsJointTopN].translate) != FALSE) and
							(other_pos_x <= _gMPCollisionBounds().current.right) and
							(other_pos_x >= _gMPCollisionBounds().current.left) and
							(other_pos_y >= _gMPCollisionBounds().current.bottom) and
							(other_pos_y < _gMPCollisionGroundData().camera_bound_top)
						)
						or
						(
							(this_fp.ga == nMPKineticsGround) and
							(
								(other_fp.status_id == nFTCommonStatusCliffCatch) or
								(other_fp.status_id == nFTCommonStatusCliffWait)
							)
						)
					)
					and
					(
						(this_fp.fkind != nFTKindMMario) or
						(other_fp.ga == nMPKineticsGround)
					)
				):
					square_xy = SQUARE(this_pos_x - other_pos_x) + SQUARE(this_pos_y - other_pos_y)

					if square_xy < distance:
						com.target_pos.x = other_pos_x
						com.target_pos.y = other_pos_y
						com.target_user = other_fp

						distance = square_xy

	if distance == F32_MAX:
		com.target_line_id = -1
		com.target_dist = F32_MAX
		com.ftcom_flags_0x4A_b1 = FALSE

		return FALSE

	com.ftcom_flags_0x4A_b1 = TRUE
	com.target_dist = sqrtf(distance)

	if _ftGetComTargetFighter(com).ga == nMPKineticsGround:
		com.target_line_id = _ftGetComTargetFighter(com).coll_data.floor_line_id
	else:
		com.target_line_id = -1

	return TRUE

## 0x80132BC8
static func ftComputerCheckEvadeDistance(this_fp) -> int:
	for other_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		if other_gobj != this_fp.fighter_gobj:
			var other_fp: Fighter = ftGetStruct(other_gobj)

			if this_fp.team != other_fp.team:
				var other_joint: DObj = other_fp.joints[nFTPartsJointTopN]
				var this_joint: DObj = this_fp.joints[nFTPartsJointTopN]
				var other_x: float = (other_joint.translate.x + other_fp.physics.vel_air.x * 3.0)
				var other_y: float = (other_joint.translate.y + other_fp.physics.vel_air.x * 3.0)
				var sqrt_xy: float = sqrtf(SQUARE(this_joint.translate.y - other_y) + SQUARE(this_joint.translate.x - other_x))

				if (other_fp.star_hitstatus == nGMHitStatusInvincible) and (sqrt_xy < 1500.0):
					return TRUE

				elif (other_fp.item_gobj != null) and (itGetStruct(other_fp.item_gobj).kind == nITKindHammer) and (sqrt_xy < 2500.0):
					return TRUE
	return FALSE

## 0x80132D18
static func ftComputerWaitGetTarget(this_fp):
	var com: FTComputer = this_fp.computer
	var target_damage: int = 9999
	var target_fp = null

	for other_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		if other_gobj != this_fp.fighter_gobj:
			var other_fp: Fighter = ftGetStruct(other_gobj)

			if this_fp.team != other_fp.team:
				if other_fp.status_id >= nFTCommonStatusControlStart:
					if (com.target_gobj != null) and (other_fp.fighter_gobj == com.target_gobj):
						if other_fp.percent_damage == com.target_damage_percent:
							if com.wiggle_wait != 0:
								com.wiggle_wait -= 1

							if com.wiggle_wait == 0:
								return other_fp
							else:
								return null

						com.target_gobj = null

					if other_fp.percent_damage < target_damage:
						target_damage = other_fp.percent_damage
						target_fp = other_fp

	if target_fp != null:
		com.target_damage_percent = _u16(target_damage)
		com.target_gobj = target_fp.fighter_gobj
		com.wiggle_wait = _u16(_f2i((syUtilsRandFloat() * 300.0) + 600.0))

	return null

## 0x80132EC0 - Unused
static func func_ovl3_80132EC0() -> void:
	return

## 0x80132EC8
static func ftComputerCheckDetectTarget(this_fp, detect_range_base: float) -> int:
	# This was a wildddddddddd match...
	var com: FTComputer = this_fp.computer
	var target_fp = _ftGetComTargetFighter(com)
	var this_pos_x: float
	var this_pos_y: float
	var this_vel_x: float
	var this_vel_y: float
	var this_tvel_base: float
	var this_gravity: float
	var target_pos_x: float
	var target_pos_y: float
	var target_vel_x: float
	var target_vel_y: float
	var target_tvel_base: float
	var target_gravity: float
	var user_data                       # C: void *user_data (ITStruct* or FTStruct*)
	var hurtbox_detect_width: float
	var hurtbox_detect_height: float
	var predict_pos_x: float
	var predict_pos_y: float
	var damage_coll_size_mul: float
	var detect_far_x: float = 0.0
	var detect_near_x: float = 0.0
	var detect_near_y: float
	var input_kinds: Array = []         # s32 input_kinds[20]
	var detect_ranges_x: Array = []     # f32 detect_ranges_x[20]
	var hit_frame: int
	var is_attempt_cliffcatch: int      # Might be very much incorrectly nanmed
	var target_predict_frame: int
	var this_predict_frame: int
	var attack_count: int
	var detect_far_y: float
	var comattacks: Array               # FTComputerAttack *comattack -> table + comattack_id
	var comattack_id: int
	var comattack: Dictionary
	var this_detect_pos: Vector3 = Vector3.ZERO
	var predict_adjust_y: float
	var fkind: int
	var is_continue: bool
	var is_bat_break: bool

	input_kinds.resize(20)
	input_kinds.fill(0)
	detect_ranges_x.resize(20)
	detect_ranges_x.fill(0.0)

	if G.gSCManagerBattleState.gkind == nGRKindInishie:
		if (this_fp.coll_data.floor_line_id >= 0) and (Mpcollision.mpCollisionCheckExistPlatformLineID(this_fp.coll_data.floor_line_id) != FALSE):
			return FALSE

	if (G.gSCManagerBattleState.gkind == nGRKindYamabuki) and (this_fp.ga != nMPKineticsGround):
		if this_fp.physics.vel_air.x > 0.0:
			detect_near_x = this_fp.joints[nFTPartsJointTopN].translate.x
			detect_far_x = this_fp.joints[nFTPartsJointTopN].translate.x + (this_fp.physics.vel_air.x * 40.0)
		else:
			detect_far_x = this_fp.joints[nFTPartsJointTopN].translate.x
			detect_near_x = this_fp.joints[nFTPartsJointTopN].translate.x + (this_fp.physics.vel_air.x * 40.0)

		this_detect_pos.y = this_fp.joints[nFTPartsJointTopN].translate.y
		this_detect_pos.x = (this_fp.joints[nFTPartsJointTopN].translate.x + detect_near_x) - 100.0

		while this_detect_pos.x < ((this_fp.joints[nFTPartsJointTopN].translate.x + detect_far_x) + 100.0):
			if Mpcollision.func_ovl2_800F8FFC(this_detect_pos) == FALSE:
				return FALSE

			this_detect_pos.x += 100.0

	this_pos_x = this_fp.joints[nFTPartsJointTopN].translate.x
	this_pos_y = this_fp.joints[nFTPartsJointTopN].translate.y

	damage_coll_size_mul = (((syUtilsRandFloat() - 0.5) * (FTCOMPUTER_LEVEL_MAX - this_fp.level)) * 0.1) + 1.0

	hurtbox_detect_width = target_fp.damage_coll_size.x * damage_coll_size_mul
	hurtbox_detect_height = target_fp.damage_coll_size.y * damage_coll_size_mul

	target_pos_x = target_fp.joints[nFTPartsJointTopN].translate.x
	target_pos_y = target_fp.joints[nFTPartsJointTopN].translate.y

	target_vel_x = target_fp.physics.vel_air.x
	target_vel_y = target_fp.physics.vel_air.y

	target_tvel_base = -target_fp.attr.tvel_base
	target_gravity = target_fp.attr.gravity

	this_vel_x = this_fp.physics.vel_air.x
	this_vel_y = this_fp.physics.vel_air.y

	this_tvel_base = -this_fp.attr.tvel_base
	this_gravity = this_fp.attr.gravity

	comattacks = dFTComputerAttackList[this_fp.fkind]
	comattack_id = 0

	if this_fp.ga != nMPKineticsGround:
		while comattacks[comattack_id].input_kind != -1:
			comattack_id += 1

		comattack_id += 1

	# for (attack_count = 0; TRUE; comattack++)
	attack_count = 0

	while true:
		comattack = comattacks[comattack_id]
		comattack_id += 1                   # comattack++ (every "continue" / "goto l_continue" lands here)

		if comattack.input_kind == -1:
			break

		elif comattack.hit_start_frame == 0:
			continue

		predict_pos_x = ((target_pos_x + (target_vel_x * comattack.hit_start_frame)) - (this_pos_x + (this_vel_x * comattack.hit_start_frame))) * this_fp.lr
		hit_frame = comattack.hit_start_frame
		is_attempt_cliffcatch = FALSE
		this_predict_frame = _f2i(-(this_tvel_base - this_pos_y) / this_gravity)

		if (this_fp.status_id == nFTCommonStatusPass) or (this_predict_frame <= 0):
			predict_adjust_y = (this_vel_y * hit_frame) + this_pos_y

		elif hit_frame < this_predict_frame:
			predict_adjust_y = ((this_vel_y * hit_frame) - ((this_gravity * _s32(hit_frame * hit_frame)) * 0.5)) + this_pos_y

		else:
			predict_adjust_y = (((hit_frame * this_vel_y) - ((this_gravity * _s32(this_predict_frame * this_predict_frame)) * 0.5)) + (this_tvel_base * (hit_frame - this_predict_frame))) + this_pos_y

		if (target_fp.status_id != nFTCommonStatusPass) and (target_fp.ga != nMPKineticsGround):
			target_predict_frame = _f2i(-(target_tvel_base - target_vel_y) / target_gravity)

			if target_predict_frame <= 0:
				predict_pos_y = ((comattack.hit_start_frame * target_vel_y) + target_pos_y) - predict_adjust_y

			elif comattack.hit_start_frame < target_predict_frame:
				predict_pos_y = (((comattack.hit_start_frame * target_vel_y) + target_pos_y) - ((target_gravity * _s32(comattack.hit_start_frame * comattack.hit_start_frame)) * 0.5)) - predict_adjust_y

			else:
				predict_pos_y = ((((comattack.hit_start_frame * target_vel_y) + target_pos_y) - ((target_gravity * _s32(target_predict_frame * target_predict_frame)) * 0.5)) + (target_tvel_base * (comattack.hit_start_frame - target_predict_frame))) - predict_adjust_y
		else:
			predict_pos_y = ((comattack.hit_start_frame * target_vel_y) + target_pos_y) - predict_adjust_y

		if this_fp.lr > 0:
			detect_near_x = comattack.detect_near_x
			detect_far_x = comattack.detect_far_x
		else:
			detect_near_x = -comattack.detect_far_x
			detect_far_x = -comattack.detect_near_x

		detect_near_y = comattack.detect_near_y
		detect_far_y = comattack.detect_far_y

		if this_fp.fkind == nFTKindGDonkey:
			detect_near_x *= 1.4
			detect_far_x *= 1.4
			detect_near_y *= 1.4
			detect_far_y *= 1.4

		if this_fp.ga == nMPKineticsGround:
			match comattack.input_kind:
				nFTComputerInputStickNButtonA, nFTComputerInputStickTiltAutoXButtonA, nFTComputerInputStickSmashAutoXNYButtonA:
					if this_fp.item_gobj != null:
						user_data = itGetStruct(this_fp.item_gobj)

						if user_data != null:
							# B R U H
							if (
								(user_data.kind == nITKindSword) or
								(user_data.kind == nITKindBat) or
								(user_data.kind == nITKindStarRod)
							):
								detect_near_x *= 1.3
								detect_far_x *= 1.3

		match this_fp.fkind:
			nFTKindMario, nFTKindLuigi, nFTKindMMario, nFTKindNMario, nFTKindNLuigi:
				if comattack.input_kind == nFTComputerInputStickSmashHiButtonB:
					is_attempt_cliffcatch = TRUE

			nFTKindKirby, nFTKindNKirby:
				if comattack.input_kind == nFTComputerInputStickSmashHiButtonB:
					is_attempt_cliffcatch = TRUE
				# fallthrough into nFTKindYoshi / nFTKindCaptain / nFTKindNYoshi / nFTKindNCaptain
				if comattack.input_kind == nFTComputerInputStickSmashLwButtonB:
					is_attempt_cliffcatch = TRUE

			nFTKindYoshi, nFTKindCaptain, nFTKindNYoshi, nFTKindNCaptain:
				if comattack.input_kind == nFTComputerInputStickSmashLwButtonB:
					is_attempt_cliffcatch = TRUE

			nFTKindBoss, nFTKindNFox, nFTKindNDonkey, nFTKindNSamus, nFTKindNLink, nFTKindNPikachu, nFTKindNNess, nFTKindGDonkey:
				pass

		if is_attempt_cliffcatch != FALSE:
			this_detect_pos.y = this_fp.joints[nFTPartsJointTopN].translate.y
			this_detect_pos.x = (this_fp.joints[nFTPartsJointTopN].translate.x + detect_near_x) - 100.0

			is_continue = false

			while this_detect_pos.x < ((this_fp.joints[nFTPartsJointTopN].translate.x + detect_far_x) + 100.0):
				if Mpcollision.func_ovl2_800F8FFC(this_detect_pos) == FALSE:
					is_continue = true      # goto l_continue
					break

				this_detect_pos.x += 100.0

			if is_continue:
				continue

			if this_fp.joints[nFTPartsJointTopN].translate.x < com.target_pos.x:
				if com.cliff_right_pos.x < (com.target_pos.x + 1200.0):
					continue

			elif com.cliff_left_pos.x > (com.target_pos.x - 1200.0):
				continue

		if this_fp.fkind == nFTKindGDonkey:
			if (
				(this_fp.joints[nFTPartsJointTopN].translate.x < (_gMPCollisionBounds().current.left + 500.0)) or
				(this_fp.joints[nFTPartsJointTopN].translate.x > (_gMPCollisionBounds().current.right - 500.0))
			):
				if comattack.input_kind == nFTComputerInputStickSmashHiButtonB:
					continue

				elif comattack.input_kind == nFTComputerInputStickSmashAutoXButtonB:
					if (this_fp.joints[nFTPartsJointTopN].translate.x * this_fp.lr) > 0.0:
						continue
				else:
					if this_fp.ga != nMPKineticsGround:
						continue

		if (this_fp.fkind != nFTKindGDonkey) or (this_fp.ga == nMPKineticsGround) or (comattack.input_kind != nFTComputerInputStickSmashHiButtonB):
			if com.ftcom_flags_0x4A_b1 != FALSE:
				if (
					(_ftGetComTargetFighter(com).status_id == nFTCommonStatusCliffCatch) or
					(_ftGetComTargetFighter(com).status_id == nFTCommonStatusCliffWait)
				):
					if detect_near_y < 0.0:
						detect_near_y -= 500.0

			if (
				(predict_pos_y < detect_far_y) and
				((detect_near_y - hurtbox_detect_height) < predict_pos_y) and
				((detect_near_x - hurtbox_detect_width) < predict_pos_x) and
				(predict_pos_x < (detect_far_x + hurtbox_detect_width))
			):
				input_kinds[attack_count] = comattack.input_kind

				if comattack.input_kind == nFTComputerInputStickSmashAutoXNYButtonA:
					is_bat_break = false            # C: "break" out of the switch right after the bat case

					if this_fp.item_gobj != null:
						if itGetStruct(this_fp.item_gobj) != null:
							if itGetStruct(this_fp.item_gobj).type == nITTypeSwing:
								detect_range_base = -0.8

						if itGetStruct(this_fp.item_gobj) != null:
							if itGetStruct(this_fp.item_gobj).kind == nITKindBat:
								if this_fp.ga == nMPKineticsGround:
									detect_ranges_x[attack_count] = 4.0
									attack_count += 1
									is_bat_break = true

					if not is_bat_break:
						detect_ranges_x[attack_count] = 1.0
						attack_count += 1

				elif comattack.input_kind == nFTComputerInputStickSmashAutoXButtonB:
					user_data = com.target_user

					if this_fp.level >= 5:
						if user_data != null:
							if (_ftGetFKind(user_data) == nFTKindNess) or (_ftGetFKind(user_data) == nFTKindFox):
								fkind = this_fp.passive_vars.kirby.copy_id if (this_fp.fkind == nFTKindKirby) else this_fp.fkind

								if (
									(fkind == nFTKindMario) or
									(fkind == nFTKindFox) or
									(fkind == nFTKindSamus) or
									(fkind == nFTKindLuigi) or
									(fkind == nFTKindLink) or
									(fkind == nFTKindPikachu) or
									(fkind == nFTKindMMario)
								):
									continue    # goto l_continue

					match this_fp.fkind:
						nFTKindDonkey, nFTKindGDonkey:
							if this_fp.passive_vars.donkey.charge_level == FTDONKEY_GIANTPUNCH_CHARGE_MAX:
								detect_ranges_x[attack_count] = 4.0
							else:
								detect_ranges_x[attack_count] = 1.0 + detect_range_base
							attack_count += 1

						nFTKindSamus:
							if this_fp.passive_vars.samus.charge_level == FTSAMUS_CHARGE_MAX:
								detect_ranges_x[attack_count] = 4.0
							else:
								detect_ranges_x[attack_count] = 1.0 + detect_range_base
							attack_count += 1

						nFTKindKirby:
							match this_fp.passive_vars.kirby.copy_id:
								nFTKindDonkey:
									if this_fp.passive_vars.kirby.copydonkey_charge_level == FTKIRBY_COPYDONKEY_GIANTPUNCH_CHARGE_MAX:
										detect_ranges_x[attack_count] = 4.0
									else:
										detect_ranges_x[attack_count] = 1.0 + detect_range_base
									attack_count += 1

								nFTKindSamus:
									if this_fp.passive_vars.kirby.copysamus_charge_level == FTKIRBY_COPYSAMUS_CHARGE_MAX:
										detect_ranges_x[attack_count] = 4.0
									else:
										detect_ranges_x[attack_count] = 1.0 + detect_range_base
									attack_count += 1

								_:
									detect_ranges_x[attack_count] = 4.0
									attack_count += 1

						_:
							detect_ranges_x[attack_count] = 1.0 + detect_range_base
							attack_count += 1

				elif (comattack.input_kind == nFTComputerInputStickSmashHiButtonB) or (comattack.input_kind == nFTComputerInputStickSmashLwButtonB):
					detect_ranges_x[attack_count] = (detect_range_base * 0.5) + 1.0
					attack_count += 1

				elif (comattack.input_kind == nFTComputerInputStickNButtonZButtonA) and (this_fp.fkind != nFTKindLink) and (this_fp.fkind != nFTKindSamus):
					detect_ranges_x[attack_count] = 4.0
					attack_count += 1

				else:
					# default (and nFTComputerInputStickNButtonZButtonA fallthrough for Link / Samus)
					detect_ranges_x[attack_count] = 1.0
					attack_count += 1
		# l_continue:

	if attack_count != 0:
		if com.trait_ == nFTComputerTraitLink:
			if this_fp.percent_damage < ((syUtilsRandFloat() * 100.0) + 1.0):
				com.fighter_follow_since = 0
				return FALSE

		if this_fp.level < 3:
			if (this_fp.percent_damage + 5.0) < (syUtilsRandFloat() * (200.0 - (this_fp.level * 50.0))):
				com.fighter_follow_since = 0
				return FALSE

		detect_far_x = 0.0

		for i in attack_count:
			if com.input_kind == input_kinds[i]:
				detect_ranges_x[i] *= 0.25

			match input_kinds[i]:
				nFTComputerInputStickNButtonA:
					detect_ranges_x[i] += com.stickn_button_a_count * 0.2
					com.stickn_button_a_count = _u8(com.stickn_button_a_count + 1)

				nFTComputerInputStickTiltAutoXButtonA:
					detect_ranges_x[i] += com.sticktilts_button_a_count * 0.2
					com.sticktilts_button_a_count = _u8(com.sticktilts_button_a_count + 1)

				nFTComputerInputStickSmashAutoXNYButtonA:
					detect_ranges_x[i] += com.sticksmashs_button_a_count * 0.2
					com.sticksmashs_button_a_count = _u8(com.sticksmashs_button_a_count + 1)

				nFTComputerInputStickTiltHiButtonA:
					detect_ranges_x[i] += com.sticktilthi_button_a_count * 0.2
					com.sticktilthi_button_a_count = _u8(com.sticktilthi_button_a_count + 1)

				nFTComputerInputStickSmashHiButtonA:
					detect_ranges_x[i] += com.sticksmashhi_button_a_count * 0.2
					com.sticksmashhi_button_a_count = _u8(com.sticksmashhi_button_a_count + 1)

				nFTComputerInputStickTiltLwButtonA:
					detect_ranges_x[i] += com.sticktiltlw_button_a_count * 0.2
					com.sticktiltlw_button_a_count = _u8(com.sticktiltlw_button_a_count + 1)

				nFTComputerInputStickSmashLwButtonA:
					detect_ranges_x[i] += com.sticksmashlw_button_a_count * 0.2
					com.sticksmashlw_button_a_count = _u8(com.sticksmashlw_button_a_count + 1)

				nFTComputerInputStickSmashAutoXButtonB:
					detect_ranges_x[i] += com.sticksmashs_button_b_count * 0.2
					com.sticksmashs_button_b_count = _u8(com.sticksmashs_button_b_count + 1)

				nFTComputerInputStickSmashHiButtonB:
					detect_ranges_x[i] += com.sticksmashhi_button_b_count * 0.2
					com.sticksmashhi_button_b_count = _u8(com.sticksmashhi_button_b_count + 1)

				nFTComputerInputStickSmashLwButtonB:
					detect_ranges_x[i] += com.sticksmashlw_button_b_count * 0.2
					com.sticksmashlw_button_b_count = _u8(com.sticksmashlw_button_b_count + 1)

				nFTComputerInputStickNButtonZButtonA:
					detect_ranges_x[i] += com.stickn_button_z_button_a_count * 0.2
					com.stickn_button_z_button_a_count = _u8(com.stickn_button_z_button_a_count + 1)

			detect_ranges_x[i] += detect_far_x
			detect_far_x = detect_ranges_x[i]

		detect_far_x = syUtilsRandFloat() * detect_far_x

		for i in attack_count:
			if detect_far_x < detect_ranges_x[i]:
				if com.input_kind == input_kinds[i]:
					com.input_repeat_count = _u8(com.input_repeat_count + 1)

					if com.input_repeat_count >= 4:
						ftComputerSetCommandImmediate(this_fp, nFTComputerInputMoveAutoStickTiltHiReleaseZ)

						return TRUE
				else:
					com.input_repeat_count = 0

				ftComputerSetCommandWaitShort(this_fp, input_kinds[i])

				com.input_kind = _u8(input_kinds[i])

				match input_kinds[i]:
					nFTComputerInputStickNButtonA:
						com.stickn_button_a_count = 0

					nFTComputerInputStickTiltAutoXButtonA:
						com.sticktilts_button_a_count = 0

					nFTComputerInputStickSmashAutoXNYButtonA:
						com.sticksmashs_button_a_count = 0

					nFTComputerInputStickTiltHiButtonA:
						com.sticktilthi_button_a_count = 0

					nFTComputerInputStickSmashHiButtonA:
						com.sticksmashhi_button_a_count = 0

					nFTComputerInputStickTiltLwButtonA:
						com.sticktiltlw_button_a_count = 0

					nFTComputerInputStickSmashLwButtonA:
						com.sticksmashlw_button_a_count = 0

					nFTComputerInputStickSmashAutoXButtonB:
						com.sticksmashs_button_b_count = 0

					nFTComputerInputStickSmashHiButtonB:
						com.sticksmashhi_button_b_count = 0

					nFTComputerInputStickSmashLwButtonB:
						com.sticksmashlw_button_b_count = 0

					nFTComputerInputStickNButtonZButtonA:
						com.stickn_button_z_button_a_count = 0

				if (this_fp.fkind == nFTKindPurin) and (com.input_kind == nFTComputerInputStickSmashHiButtonB) and (syUtilsRandFloat() < 0.9):
					return FALSE

				return TRUE

		# C falls off the end of the function here (no return value); unreachable because the
		# cumulative weights are positive and syUtilsRandFloat() < 1.
		return FALSE
	else:
		return FALSE

## 0x80134000
static func ftComputerCheckSetTargetEdgeRight(fp, is_find_edge_target: int) -> int:
	var com: FTComputer = fp.computer
	var edge_dist_x: float
	var edge_predict_y: float
	var edge_offset: float
	var fall_predict: int
	var edge_pos: Vector3
	var acid_level_curr: float
	var acid_level_step: float
	var edge_predict_x: int
	var line_group
	var line_ids                        # C: u16 *line_ids

	if fp.physics.vel_air.y >= 0.0:
		com.target_pos.x = fp.joints[nFTPartsJointTopN].translate.x - 500.0
		com.target_pos.y = fp.joints[nFTPartsJointTopN].translate.y

		return TRUE

	edge_offset = com.jump_predict * 0.75

	if fp.fkind == nFTKindMMario:
		edge_offset = 0.0

	if G.gSCManagerBattleState.gkind == nGRKindYamabuki:
		edge_offset = 0.0

	line_group = _gMPCollisionLineGroups()[nMPLineKindFloor]
	line_ids = line_group.line_id

	for i in line_group.line_count:
		if Mpcollision.mpCollisionCheckExistLineID(line_ids[i]) != FALSE:
			edge_pos = Mpcollision.mpCollisionGetFloorEdgeR(line_ids[i])

			if G.gSCManagerBattleState.gkind == nGRKindZebes:
				var acid_level = Grzebes.grZebesAcidGetLevelInfo()

				acid_level_curr = acid_level.current
				acid_level_step = acid_level.step

				if (edge_pos.y < (acid_level_curr + 500.0)) or (edge_pos.y < ((5.0 * acid_level_step) + acid_level_curr + 500.0)):
					continue

			if (G.gSCManagerBattleState.gkind == nGRKindInishie) and (Mpcollision.mpCollisionCheckExistPlatformLineID(line_ids[i]) != FALSE):
				continue

			edge_dist_x = fp.joints[nFTPartsJointTopN].translate.x - edge_pos.x

			if edge_dist_x > 0.0:
				edge_predict_x = _f2i(edge_dist_x / fp.attr.air_speed_max_x)
				fall_predict = _f2i(-(-fp.attr.tvel_base - fp.physics.vel_air.y) / fp.attr.gravity)

				if fall_predict <= 0:
					edge_predict_y = fp.joints[nFTPartsJointTopN].translate.y + (fp.physics.vel_air.y * edge_predict_x)

				elif edge_predict_x < fall_predict:
					edge_predict_y = fp.joints[nFTPartsJointTopN].translate.y + (
						(fp.physics.vel_air.y * edge_predict_x) - (fp.attr.gravity * _s32(edge_predict_x * edge_predict_x) * 0.5)
					)
				else:
					edge_predict_y = fp.joints[nFTPartsJointTopN].translate.y + (
						((fp.physics.vel_air.y * edge_predict_x) - (fp.attr.gravity * _s32(fall_predict * fall_predict) * 0.5)) -
						(fp.attr.tvel_base * (edge_predict_x - fall_predict))
					)

				if (is_find_edge_target == FALSE) and (edge_predict_y < (edge_pos.y - com.jump_predict)):
					continue

				if (edge_predict_y < edge_pos.y) and ((edge_pos.y - edge_offset) < edge_predict_y):
					continue

				com.target_pos.x = edge_pos.x - 500.0
				com.target_pos.y = edge_pos.y

				return TRUE
	return FALSE

## 0x80134368
static func ftComputerCheckSetTargetEdgeLeft(fp, is_find_edge_target: int) -> int:
	var com: FTComputer = fp.computer
	var edge_dist_x: float
	var edge_predict_y: float
	var edge_offset: float
	var fall_predict: int
	var edge_pos: Vector3
	var acid_level_curr: float
	var acid_level_step: float
	var edge_predict_x: int
	var line_group
	var line_ids                        # C: u16 *line_ids

	if fp.physics.vel_air.y >= 0.0:
		com.target_pos.x = fp.joints[nFTPartsJointTopN].translate.x + 500.0
		com.target_pos.y = fp.joints[nFTPartsJointTopN].translate.y

		return TRUE

	edge_offset = com.jump_predict * 0.75

	if fp.fkind == nFTKindMMario:
		edge_offset = 0.0

	if G.gSCManagerBattleState.gkind == nGRKindYamabuki:
		edge_offset = 0.0

	line_group = _gMPCollisionLineGroups()[nMPLineKindFloor]
	line_ids = line_group.line_id

	for i in line_group.line_count:
		if Mpcollision.mpCollisionCheckExistLineID(line_ids[i]) != FALSE:
			edge_pos = Mpcollision.mpCollisionGetFloorEdgeL(line_ids[i])

			if G.gSCManagerBattleState.gkind == nGRKindZebes:
				var acid_level = Grzebes.grZebesAcidGetLevelInfo()

				acid_level_curr = acid_level.current
				acid_level_step = acid_level.step

				if (edge_pos.y < (acid_level_curr + 500.0)) or (edge_pos.y < ((5.0 * acid_level_step) + acid_level_curr + 500.0)):
					continue

			if (G.gSCManagerBattleState.gkind == nGRKindInishie) and (Mpcollision.mpCollisionCheckExistPlatformLineID(line_ids[i]) != FALSE):
				continue

			edge_dist_x = fp.joints[nFTPartsJointTopN].translate.x - edge_pos.x

			if edge_dist_x < 0.0:
				edge_predict_x = _f2i(edge_dist_x / -fp.attr.air_speed_max_x)
				fall_predict = _f2i(-(-fp.attr.tvel_base - fp.physics.vel_air.y) / fp.attr.gravity)

				if fall_predict <= 0:
					edge_predict_y = fp.joints[nFTPartsJointTopN].translate.y + (fp.physics.vel_air.y * edge_predict_x)

				elif edge_predict_x < fall_predict:
					edge_predict_y = fp.joints[nFTPartsJointTopN].translate.y + (
						(fp.physics.vel_air.y * edge_predict_x) - (fp.attr.gravity * _s32(edge_predict_x * edge_predict_x) * 0.5)
					)
				else:
					edge_predict_y = fp.joints[nFTPartsJointTopN].translate.y + (
						((fp.physics.vel_air.y * edge_predict_x) - (fp.attr.gravity * _s32(fall_predict * fall_predict) * 0.5)) -
						(fp.attr.tvel_base * (edge_predict_x - fall_predict))
					)

				if (is_find_edge_target == FALSE) and (edge_predict_y < (edge_pos.y - com.jump_predict)):
					continue

				if (edge_predict_y < edge_pos.y) and ((edge_pos.y - edge_offset) < edge_predict_y):
					continue

				com.target_pos.x = edge_pos.x + 500.0
				com.target_pos.y = edge_pos.y

				return TRUE
	return FALSE

## 0x801346D4
static func func_ovl3_801346D4(fp) -> void:
	var com: FTComputer = fp.computer
	var pos: Vector3 = fp.joints[nFTPartsJointTopN].translate
	var range_: float = fp.computer.jump_predict      # C: f32 range

	if fp.jumps_used == fp.attr.jumps_max:
		match fp.fkind:
			nFTKindFox, nFTKindDonkey, nFTKindGDonkey:
				range_ *= 0.5

			nFTKindNess:
				range_ = -com.jump_predict

	if fp.fkind == nFTKindMMario:
		range_ = 0.0

	if fp.fkind == nFTKindGDonkey:
		range_ = 0.0

	if pos.x > _gMPCollisionBounds().current.right:
		if fp.lr > 0:
			range_ *= 0.75

		com.target_pos.x = pos.x - 1100.0

		if pos.x < (com.cliff_right_pos.x + 300.0):
			range_ = 0.0

		if (
			((fp.jumps_used < fp.attr.jumps_max) and ((pos.x - _gMPCollisionBounds().current.right) > 1500.0)) or
			((fp.joints[nFTPartsJointTopN].translate.y + fp.physics.vel_air.y) < (com.cliff_right_pos.y - range_))
		):
			com.target_pos.y = pos.y + 1100.0
		else:
			com.target_pos.y = pos.y
	else:
		if fp.lr < 0:
			range_ *= 0.75

		com.target_pos.x = pos.x + 1100.0

		if (com.cliff_left_pos.x - 300.0) < pos.x:
			range_ = 0.0

		if (
			(
				(fp.jumps_used < fp.attr.jumps_max) and
				(
					(_gMPCollisionBounds().current.left - pos.x) > 1500.0
				)
			)
			or
			(
				(fp.joints[nFTPartsJointTopN].translate.y + fp.physics.vel_air.y) < (com.cliff_left_pos.y - range_)
			)
		):
			com.target_pos.y = pos.y + 1100.0
		else:
			com.target_pos.y = pos.y
	# (REGION_JP-only Pikachu SpecialAirHi block omitted: US build)

## 0x80134964
static func func_ovl3_80134964(fp) -> void:
	var com: FTComputer = fp.computer
	var pos: Vector3 = fp.joints[nFTPartsJointTopN].translate

	com.target_line_id = -1
	com.ftcom_flags_0x4A_b1 = FALSE

	if (com.is_within_vertical_bounds == FALSE) and (pos.x <= _gMPCollisionBounds().current.right) and (pos.x >= _gMPCollisionBounds().current.left):
		if fp.physics.vel_air.x < 0.0:
			if (
				(ftComputerCheckSetTargetEdgeRight(fp, FALSE) != FALSE) or
				(ftComputerCheckSetTargetEdgeLeft(fp, FALSE) != FALSE) or
				(ftComputerCheckSetTargetEdgeRight(fp, TRUE) != FALSE) or
				(ftComputerCheckSetTargetEdgeLeft(fp, TRUE) != FALSE)
			):
				return

		elif (
			(ftComputerCheckSetTargetEdgeLeft(fp, FALSE) != FALSE) or
			(ftComputerCheckSetTargetEdgeRight(fp, FALSE) != FALSE) or
			(ftComputerCheckSetTargetEdgeLeft(fp, TRUE) != FALSE) or
			(ftComputerCheckSetTargetEdgeRight(fp, TRUE) != FALSE)
		):
			return

		# C: if ((pos.x + (pos.x < 0.0F)) != FALSE)
		if (pos.x + (1.0 if (pos.x < 0.0) else 0.0)) != 0.0:
			com.target_pos.x = 500.0
		else:
			com.target_pos.x = -500.0

		if (pos.y + 1100.0) > _gMPCollisionGroundData().camera_bound_top:
			com.target_pos.y = pos.y
		else:
			com.target_pos.y = (pos.y + 1100.0)
	else:
		func_ovl3_801346D4(fp)

## 0x80134B4C
static func ftComputerCheckTargetItemOrTwister(fp) -> int:
	var com: FTComputer = fp.computer
	var predict_x: float
	var predict_y: float
	var dist_x: float
	var dist_y: float
	var twister_pos: Vector3

	predict_x = fp.joints[nFTPartsJointTopN].translate.x + (fp.physics.vel_air.x * 5.0)
	predict_y = fp.joints[nFTPartsJointTopN].translate.y + (fp.physics.vel_air.y * 5.0)

	for item_gobj in Sim.get_link(nGCCommonLinkIDItem):
		var ip: Item = itGetStruct(item_gobj)

		if (
			(ip.owner_gobj != fp.fighter_gobj) and
			(
				(G.gSCManagerBattleState.is_team_battle != TRUE) or (G.gSCManagerBattleState.is_team_attack != FALSE) or (ip.team != fp.team)
			)
			and
			(
				(
					(ip.kind == nITKindMSBomb) and (ip.is_damage_all == TRUE)
				)
				or
				(
					(ip.attack_coll.attack_state != nGMAttackStateOff) and (ip.attack_coll.attack_state != nGMAttackStateNew) and
					((ip.attack_coll.interact_mask & GMHITCOLLISION_FLAG_FIGHTER) != 0)
				)
			)
		):
			var it_attack_coll: ITAttackColl = ip.attack_coll
			var attack_id: int = 0

			if it_attack_coll.attack_count > 0:
				dist_x = -(predict_x - it_attack_coll.attack_pos[attack_id].pos_curr.x) if (predict_x < it_attack_coll.attack_pos[attack_id].pos_curr.x) else (predict_x - it_attack_coll.attack_pos[attack_id].pos_curr.x)

				if dist_x < it_attack_coll.size:
					dist_y = -(predict_y - it_attack_coll.attack_pos[attack_id].pos_curr.y) if (predict_y < it_attack_coll.attack_pos[attack_id].pos_curr.y) else (predict_y - it_attack_coll.attack_pos[attack_id].pos_curr.y)

					if dist_y < it_attack_coll.size:
						com.ftcom_flags_0x4A_b1 = FALSE

						if fp.ga != nMPKineticsGround:
							com.target_pos.x = (it_attack_coll.attack_pos[attack_id].pos_curr.x + 1500.0) if (com.target_pos.x < it_attack_coll.attack_pos[attack_id].pos_curr.x) else (it_attack_coll.attack_pos[attack_id].pos_curr.x - 1500.0)

							com.target_pos.y = it_attack_coll.attack_pos[attack_id].pos_curr.y
						else:
							com.target_pos.x = fp.joints[nFTPartsJointTopN].translate.x
							com.target_pos.y = fp.joints[nFTPartsJointTopN].translate.y + 1100.0
				return TRUE

	if G.gSCManagerBattleState.gkind == nGRKindHyrule:
		var twister = Grhyrule.grHyruleTwisterCheckGetPosition()

		if twister.ret != FALSE:
			twister_pos = twister.pos

			dist_x = -(predict_x - twister_pos.x) if (predict_x < twister_pos.x) else (predict_x - twister_pos.x)

			if dist_x < 600:
				dist_y = predict_y - twister_pos.y

				if (dist_y < 600.0) and (dist_y > -300.0):
					com.ftcom_flags_0x4A_b1 = FALSE

					if fp.joints[nFTPartsJointTopN].translate.x < (twister_pos.x - 300.0):
						com.target_pos.x = (twister_pos.x - 1200.0)
						com.target_pos.y = (twister_pos.y + 1100.0)
					else:
						com.target_pos.x = (twister_pos.x + 1200.0)
						com.target_pos.y = (twister_pos.y + 1100.0)

					return TRUE
	return FALSE

## 0x80134E98
static func ftComputerFollowObjectiveWalk(fp) -> void:
	var target_pos: Vector3
	var ga_last: Vector3
	var stand_line_id: int
	var edge_left: Vector3
	var edge_right: Vector3
	var sp9C: Vector3
	var sp90: Vector3
	var target_fp
	var sp80: Vector3
	var sp74: Vector3
	var sp68: Vector3
	var edge_dist_x: float
	var sp58: Vector3
	var com: FTComputer
	var coll_check

	com = fp.computer

	target_pos = fp.joints[nFTPartsJointTopN].translate

	target_pos.x = fp.computer.target_pos.x
	target_pos.y = fp.computer.target_pos.y

	if (fp.ga == nMPKineticsGround) and (fp.joints[nFTPartsJointTopN].translate.y < com.target_pos.y):
		coll_check = Mpcollision.mpCollisionCheckCeilLineCollisionSame(fp.joints[nFTPartsJointTopN].translate, target_pos)

		if coll_check.ret != FALSE:
			stand_line_id = coll_check.stand_line_id

			edge_left = Mpcollision.mpCollisionGetCeilEdgeL(stand_line_id)
			edge_right = Mpcollision.mpCollisionGetCeilEdgeR(stand_line_id)

			if _DISTANCE(edge_left.x, fp.joints[nFTPartsJointTopN].translate.x) < _DISTANCE(edge_right.x, fp.joints[nFTPartsJointTopN].translate.x):
				com.target_pos.x = edge_left.x - 600.0
				com.target_pos.y = fp.joints[nFTPartsJointTopN].translate.y
			else:
				com.target_pos.x = edge_right.x + 600.0
				com.target_pos.y = fp.joints[nFTPartsJointTopN].translate.y

	elif (
		((fp.coll_data.floor_flags & MAP_VERTEX_COLL_PASS) == 0) and
		(fp.coll_data.floor_line_id >= 0) and
		(com.target_pos.y < ((fp.joints[nFTPartsJointTopN].translate.y + fp.coll_data.floor_dist) - 500.0)) and
		(_DISTANCE(com.target_pos.x, fp.joints[nFTPartsJointTopN].translate.x) < (_DISTANCE(com.target_pos.y, fp.joints[nFTPartsJointTopN].translate.y) * 0.2))
	):
		sp9C = Mpcollision.mpCollisionGetFloorEdgeL(fp.coll_data.floor_line_id)
		sp90 = Mpcollision.mpCollisionGetFloorEdgeR(fp.coll_data.floor_line_id)

		if _DISTANCE(sp9C.x, fp.joints[nFTPartsJointTopN].translate.x) < _DISTANCE(sp90.x, fp.joints[nFTPartsJointTopN].translate.x):
			com.target_pos.x = sp9C.x - 600.0
			com.target_pos.y = sp9C.y
		else:
			com.target_pos.x = sp90.x + 600.0
			com.target_pos.y = sp90.y

	elif (fp.ga == nMPKineticsGround) or (fp.physics.vel_air.y < 0.0) or (fp.fkind == nFTKindKirby) or (fp.fkind == nFTKindPurin):
		if fp.joints[nFTPartsJointTopN].translate.x < com.target_pos.x:
			coll_check = Mpcollision.mpCollisionCheckLWallLineCollisionSame(fp.joints[nFTPartsJointTopN].translate, target_pos)

			if coll_check.ret != FALSE:
				stand_line_id = coll_check.stand_line_id

				ga_last = Mpcollision.mpCollisionGetLWallEdgeU(stand_line_id)

				com.target_pos.x = ga_last.x + 100.0
				com.target_pos.y = ga_last.y + 100.0

				if (fp.ga == nMPKineticsGround) and (fp.lr < 0.0):
					com.target_pos.x = fp.joints[nFTPartsJointTopN].translate.x + 100.0
					com.target_pos.y = fp.joints[nFTPartsJointTopN].translate.y

					ftComputerSetCommandImmediate(fp, nFTComputerInputStickTiltAutoXD5)
					return
		else:
			coll_check = Mpcollision.mpCollisionCheckRWallLineCollisionSame(fp.joints[nFTPartsJointTopN].translate, target_pos)

			if coll_check.ret != FALSE:
				stand_line_id = coll_check.stand_line_id

				ga_last = Mpcollision.mpCollisionGetRWallEdgeU(stand_line_id)

				com.target_pos.x = ga_last.x - 100.0
				com.target_pos.y = ga_last.y + 100.0

				if (fp.ga == nMPKineticsGround) and (fp.lr > 0.0):
					com.target_pos.x = fp.joints[nFTPartsJointTopN].translate.x - 100.0
					com.target_pos.y = fp.joints[nFTPartsJointTopN].translate.y

					ftComputerSetCommandImmediate(fp, nFTComputerInputStickTiltAutoXD5)
					return

	ftComputerCheckTargetItemOrTwister(fp)
	ftComputerSetCommandImmediate(fp, nFTComputerInputMoveAuto)

	if fp.ga != nMPKineticsGround:
		var is_block_52: bool = true    # C: switch (com->behavior) ... break / goto block_52 / default

		match com.behavior:
			nFTComputerBehaviorYoshiTeam:
				if fp.joints[nFTPartsJointTopN].translate.y < 0.0:
					is_block_52 = false

			nFTComputerBehaviorKirbyTeam, nFTComputerBehaviorPolyTeam:
				if fp.joints[nFTPartsJointTopN].translate.y < -300.0:
					is_block_52 = false

		if is_block_52:
			# block_52:
			if fp.joints[nFTPartsJointTopN].translate.y < com.target_pos.y:
				if (com.objective != nFTComputerObjectiveRecover) and ((com.target_pos.y - 200.0) < fp.joints[nFTPartsJointTopN].translate.y):
					com.target_pos.y = fp.joints[nFTPartsJointTopN].translate.y
					return

				com.ftcom_flags_0x4A_b0 = FALSE

				if (fp.joints[nFTPartsJointTopN].translate.y < (_gMPCollisionGroundData().map_bound_top - 4000.0)) and (fp.physics.vel_air.y < 0.0):
					if fp.jumps_used < fp.attr.jumps_max:
						if (
							(fp.status_id == nFTCommonStatusDamageFlyHi) or
							(fp.status_id == nFTCommonStatusDamageFlyN) or
							(fp.status_id == nFTCommonStatusDamageFlyLw) or
							(fp.status_id == nFTCommonStatusDamageFlyTop) or
							(fp.status_id == nFTCommonStatusDamageFlyRoll)
						):
							if fp.status_vars.common.damage.hitstun_tics == 0:
								ftComputerSetCommandImmediate(fp, nFTComputerInputMoveAutoStickTiltHiReleaseZ)
								return

					if fp.jumps_used < fp.attr.jumps_max:
						if (
							(fp.status_id == nFTCommonStatusJumpF) or
							(fp.status_id == nFTCommonStatusJumpB) or
							(fp.status_id == nFTCommonStatusFall) or
							(fp.status_id == nFTCommonStatusDamageFall) or
							(fp.status_id == nFTCommonStatusFallSpecial)
						):
							ftComputerSetCommandImmediate(fp, nFTComputerInputMoveAutoStickTiltHiReleaseZ)
							return

					if (com.objective == nFTComputerObjectiveRecover) and (com.is_attempt_specialhi_recovery == FALSE):
						if (fp.fkind != nFTKindYoshi) and (fp.fkind != nFTKindPurin):
							if (
								(fp.status_id == nFTCommonStatusJumpAerialF) or
								(fp.status_id == nFTCommonStatusJumpAerialB) or
								(fp.status_id == nFTCommonStatusFallAerial) or
								(fp.status_id == nFTCommonStatusDamageFall)
							):
								com.is_attempt_specialhi_recovery = TRUE

								if (fp.fkind == nFTKindGDonkey) or (syUtilsRandFloat() < (fp.level + 2) / 9.0):
									ftComputerSetCommandImmediate(fp, nFTComputerInputStickSmashHiButtonB)
									return
			else:
				if fp.physics.vel_air.y < 0.0:
					if com.objective != nFTComputerObjectiveRecover:
						if (fp.is_fastfall == FALSE) and (com.ftcom_flags_0x4A_b0 == FALSE):
							com.ftcom_flags_0x4A_b0 = TRUE

							if (
								((fp.level > 5) and ((syUtilsRandFloat() * (550 - (fp.level * 50))) < 70.0)) or
								(com.behavior == nFTComputerBehaviorYoshiTeam) or
								(com.behavior == nFTComputerBehaviorKirbyTeam) or
								(com.behavior == nFTComputerBehaviorPolyTeam)
							):
								# Fast fall?
								ftComputerSetCommandWaitShort(fp, nFTComputerInputStickND1MoveAutoSmashLw)
								return

			match com.behavior:
				nFTComputerBehaviorYoshiTeam, nFTComputerBehaviorKirbyTeam, nFTComputerBehaviorPolyTeam:
					if fp.status_id == nFTCommonStatusFall:
						if Mpcollision.func_ovl2_800F8FFC(fp.joints[nFTPartsJointTopN].translate) != FALSE:
							com.target_pos.x = fp.joints[nFTPartsJointTopN].translate.x
							com.target_pos.y = fp.joints[nFTPartsJointTopN].translate.y - 500.0

			if (
				(fp.level >= 5) and
				(com.ftcom_flags_0x4A_b1 != FALSE) and
				((com.target_pos.y + 1100.0) < fp.joints[nFTPartsJointTopN].translate.y) and
				(fp.physics.vel_air.y < 0.0)
			):
				target_fp = com.target_user

				sp80.x = target_fp.joints[nFTPartsJointTopN].translate.x - (target_fp.lr * 1500.0)
				sp80.y = target_fp.joints[nFTPartsJointTopN].translate.y
				sp80.z = 0.0

				if Mpcollision.func_ovl2_800F8FFC(sp80) != FALSE:
					com.target_pos.x = sp80.x
					com.target_pos.y = sp80.y
				else:
					sp80.x = target_fp.joints[nFTPartsJointTopN].translate.x + (target_fp.lr * 1500.0)

					if Mpcollision.func_ovl2_800F8FFC(sp80) != FALSE:
						com.target_pos.x = sp80.x
						com.target_pos.y = sp80.y

			if com.ftcom_flags_0x4A_b1 != FALSE:
				if com.target_line_id >= 0:
					sp74 = Mpcollision.mpCollisionGetFloorEdgeL(com.target_line_id)
					sp68 = Mpcollision.mpCollisionGetFloorEdgeR(com.target_line_id)

					if (sp74.x <= com.target_pos.x) and (sp68.x >= com.target_pos.x):
						if com.target_pos.x < (sp74.x + 200.0):
							com.target_pos.x = (sp74.x + 200.0)

						if com.target_pos.x > (sp68.x - 200.0):
							com.target_pos.x = (sp68.x - 200.0)

			ftComputerSetCommandImmediate(fp, nFTComputerInputMoveAuto)
			return
	else:
		if com.dash_predict <= _DISTANCE(com.target_pos.x, fp.joints[nFTPartsJointTopN].translate.x):
			if fp.joints[nFTPartsJointTopN].translate.y < com.target_pos.y:
				if fp.coll_data.floor_line_id >= 0:
					if fp.physics.vel_air.x < 0.0:
						sp58 = Mpcollision.mpCollisionGetFloorEdgeL(fp.coll_data.floor_line_id)
					else:
						sp58 = Mpcollision.mpCollisionGetFloorEdgeR(fp.coll_data.floor_line_id)

					if sp58.x < fp.joints[nFTPartsJointTopN].translate.x:
						edge_dist_x = -(sp58.x - fp.joints[nFTPartsJointTopN].translate.x)
					else:
						edge_dist_x = (sp58.x - fp.joints[nFTPartsJointTopN].translate.x)
				else:
					edge_dist_x = 0.0

				if (edge_dist_x - ABSF(fp.physics.vel_air.x)) < 200.0:
					if fp.status_id != nFTCommonStatusKneeBend:
						ftComputerSetCommandWaitShort(fp, nFTComputerInputMoveAutoStickTiltHiReleaseZ)
				else:
					ftComputerSetCommandImmediate(fp, nFTComputerInputMoveAuto)
			else:
				ftComputerSetCommandImmediate(fp, nFTComputerInputMoveAuto)

		elif fp.status_id != nFTCommonStatusDash:
			if com.target_line_id != fp.coll_data.floor_line_id:
				if fp.joints[nFTPartsJointTopN].translate.y < com.target_pos.y:
					if fp.status_id != nFTCommonStatusKneeBend:
						ftComputerSetCommandWaitShort(fp, nFTComputerInputMoveAutoStickTiltHiReleaseZ)

				elif (fp.coll_data.floor_flags & MAP_VERTEX_COLL_PASS) != 0:
					ftComputerSetCommandWaitShort(fp, nFTComputerInputStickND1MoveAutoSmashLw)
			else:
				ftComputerSetCommandImmediate(fp, nFTComputerInputMoveAuto)
		else:
			ftComputerSetCommandImmediate(fp, nFTComputerInputMoveAuto)

## 0x80135B78
static func func_ovl3_80135B78(this_fp) -> int:
	var attack_size: float
	var predict_vel_x: float
	var predict_div_x: float
	var this_pos_x: float
	var this_pos_y: float
	var predict_pos_x: float
	var predict_pos_y: float
	var wp: Weapon
	var ip: Item
	var other_fp: Fighter
	var com: FTComputer
	var wp_attack_coll: WPAttackColl
	var it_attack_coll: ITAttackColl

	com = this_fp.computer

	this_pos_x = this_fp.joints[nFTPartsJointTopN].translate.x
	this_pos_y = this_fp.joints[nFTPartsJointTopN].translate.y

	for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		if this_fp.fighter_gobj == fighter_gobj:
			continue                        # goto next_fighter

		other_fp = ftGetStruct(fighter_gobj)

		if this_fp.team == ftGetStruct(fighter_gobj).team:
			continue                        # goto next_fighter

		if other_fp.fkind == nFTKindDonkey:
			if other_fp.passive_vars.donkey.charge_level == FTDONKEY_GIANTPUNCH_CHARGE_MAX:
				if (this_fp.level != 0) and (this_fp.level != 0):
					pass                    # WTF??? (no effect in C either)

	for weapon_gobj in Sim.get_link(nGCCommonLinkIDWeapon):
		wp = wpGetStruct(weapon_gobj)

		if wp.owner_gobj != this_fp.fighter_gobj:
			if (G.gSCManagerBattleState.is_team_battle != TRUE) or (G.gSCManagerBattleState.is_team_attack != FALSE) or (wp.team != this_fp.team):
				if (wp.attack_coll.attack_state != nGMAttackStateOff) and (wp.attack_coll.attack_state != nGMAttackStateNew) and ((wp.attack_coll.interact_mask & GMHITCOLLISION_FLAG_FIGHTER) != 0):
					wp_attack_coll = wp.attack_coll

					for i in wp_attack_coll.attack_count:
						predict_vel_x = (wp.physics.vel_air.x - this_fp.physics.vel_air.x) * wp.lr

						if predict_vel_x > 0.0:
							predict_pos_x = (this_pos_x - wp_attack_coll.attack_pos[i].pos_curr.x) * wp.lr

							attack_size = wp_attack_coll.size * 0.5

							predict_pos_x -= (this_fp.damage_coll_size.x + attack_size)

							if predict_pos_x > 0.0:
								predict_div_x = predict_pos_x / predict_vel_x

								if predict_div_x < 15.0:
									predict_pos_y = ((this_fp.physics.vel_air.y * predict_div_x) + this_pos_y) if (this_fp.ga != nMPKineticsGround) else this_pos_y

									if ((((wp_attack_coll.attack_pos[i].pos_curr.y - attack_size) - this_fp.damage_coll_size.y) < predict_pos_y) and (predict_pos_y < (wp_attack_coll.attack_pos[i].pos_curr.y + attack_size))):
										com.target_pos.y = predict_pos_y
										com.unk_ftcom_0x38 = _u8(_f2i(predict_div_x))

										if syUtilsRandFloat() < ((this_fp.level + 2) / 9.0):
											if com.ftcom_flags_0x49_b2 == FALSE:
												if (
													(this_fp.fkind == nFTKindFox) or    # C: (0,nFTKindFox) // WTF????????????????????????
													(this_fp.fkind == nFTKindNess) or
													(this_fp.fkind == nFTKindNFox) or
													(this_fp.fkind == nFTKindNNess)
												):
													com.is_opponent_ra = TRUE
											return TRUE

	for item_gobj in Sim.get_link(nGCCommonLinkIDItem):
		ip = itGetStruct(item_gobj)

		if ip.owner_gobj != this_fp.fighter_gobj:
			if (G.gSCManagerBattleState.is_team_battle != TRUE) or (G.gSCManagerBattleState.is_team_attack != FALSE) or (ip.team != this_fp.team):
				if (ip.attack_coll.attack_state != nGMAttackStateOff) and (ip.attack_coll.attack_state != nGMAttackStateNew) and ((ip.attack_coll.interact_mask & GMHITCOLLISION_FLAG_FIGHTER) != 0):
					it_attack_coll = ip.attack_coll

					for i in it_attack_coll.attack_count:
						predict_vel_x = (ip.physics.vel_air.x - this_fp.physics.vel_air.x) * ip.lr

						if predict_vel_x > 0.0:
							predict_pos_x = (this_pos_x - it_attack_coll.attack_pos[i].pos_curr.x) * ip.lr

							attack_size = it_attack_coll.size * 0.5

							predict_pos_x -= (this_fp.damage_coll_size.x + attack_size)

							if predict_pos_x > 0.0:
								predict_div_x = predict_pos_x / predict_vel_x

								if predict_div_x < 15.0:
									predict_pos_y = ((this_fp.physics.vel_air.y * predict_div_x) + this_pos_y) if (this_fp.ga != nMPKineticsGround) else this_pos_y

									if ((((it_attack_coll.attack_pos[i].pos_curr.y - attack_size) - this_fp.damage_coll_size.y) < predict_pos_y) and (predict_pos_y < (it_attack_coll.attack_pos[i].pos_curr.y + attack_size))):
										com.target_pos.y = predict_pos_y
										com.unk_ftcom_0x38 = _u8(_f2i(predict_div_x))

										if syUtilsRandFloat() < ((this_fp.level + 2) / 9.0):
											if com.ftcom_flags_0x49_b2 == FALSE:
												if (
													(this_fp.fkind == nFTKindFox) or    # C: (0, nFTKindFox) // I AM LOSING MY MIND
													(this_fp.fkind == nFTKindNess) or
													(this_fp.fkind == nFTKindNFox) or
													(this_fp.fkind == nFTKindNNess)
												):
													com.is_opponent_ra = TRUE
											return TRUE
	return FALSE

## 0x801361BC
static func func_ovl3_801361BC(fp) -> void:
	var com: FTComputer = fp.computer
	var var_v1: int

	com.target_line_id = -1
	com.ftcom_flags_0x4A_b1 = FALSE
	com = fp.computer

	if (com.is_counterattack == FALSE) and (com.is_opponent_ra == FALSE):
		if fp.ga != nMPKineticsGround:
			com.target_pos.x = fp.joints[nFTPartsJointTopN].translate.x

			if ((fp.joints[nFTPartsJointTopN].translate.y + fp.damage_coll_size.y) < com.target_pos.y) and (fp.physics.vel_air.y <= 0.0):
				com.target_pos.y = fp.joints[nFTPartsJointTopN].translate.y - 1100.0
			else:
				com.target_pos.y = fp.joints[nFTPartsJointTopN].translate.y + 1100.0
		else:
			match fp.fkind:
				nFTKindDonkey, nFTKindNDonkey, nFTKindGDonkey:
					var_v1 = 11

				nFTKindMMario:
					var_v1 = 20

				_:
					var_v1 = 7

			if (com.unk_ftcom_0x38 < var_v1) or (fp.status_id == nFTCommonStatusRun) or (fp.status_id == nFTCommonStatusDash):
				com.is_shield_item_weapon = TRUE
			else:
				com.target_pos.x = fp.joints[nFTPartsJointTopN].translate.x
				com.target_pos.y = fp.joints[nFTPartsJointTopN].translate.y + 1100.0

## 0x80136310
static func ftComputerCheckFindItem(fp) -> int:
	var com: FTComputer = fp.computer
	var nearest_dist: float
	var ft_pos_x: float
	var ft_pos_y: float

	if fp.item_gobj != null:
		fp.computer.target_line_id = -1

		return FALSE

	nearest_dist = F32_MAX

	ft_pos_x = fp.joints[nFTPartsJointTopN].translate.x
	ft_pos_y = fp.joints[nFTPartsJointTopN].translate.y

	com.ftcom_flags_0x4A_b1 = FALSE

	for item_gobj in Sim.get_link(nGCCommonLinkIDItem):
		var ip: Item = itGetStruct(item_gobj)

		if ip.owner_gobj == fp.fighter_gobj:
			continue                        # goto next_item

		if (G.gSCManagerBattleState.is_team_battle == TRUE) and (G.gSCManagerBattleState.is_team_attack == FALSE) and (ip.team == fp.team):
			continue                        # goto next_item

		if (ip.is_allow_pickup != FALSE) and (Mpcollision.func_ovl2_800F8FFC(DObjGetStruct(item_gobj).translate) != FALSE):
			var it_pos_x: float = DObjGetStruct(item_gobj).translate.x
			var it_pos_y: float = DObjGetStruct(item_gobj).translate.y

			if (
				(it_pos_x <= _gMPCollisionBounds().current.right) and
				(it_pos_x >= _gMPCollisionBounds().current.left) and
				(it_pos_y >= _gMPCollisionBounds().current.bottom) and
				(it_pos_y < _gMPCollisionGroundData().camera_bound_top)
			):
				var current_dist: float = SQUARE(ft_pos_x - it_pos_x) + SQUARE(ft_pos_y - it_pos_y)

				if nearest_dist > current_dist:
					com.target_pos.x = it_pos_x
					com.target_pos.y = it_pos_y

					com.target_user = ip

					nearest_dist = current_dist

	if nearest_dist == F32_MAX:
		com.target_line_id = -1

		return FALSE

	com.target_dist = sqrtf(nearest_dist)

	com.target_line_id = _ftGetComTargetItem(com).coll_data.floor_line_id if (_ftGetComTargetItem(com).ga == nMPKineticsGround) else -1

	return TRUE

## 0x80136550
static func ftComputerCheckTargetItemInRange(fp) -> int:
	var item_pickup = fp.attr.item_pickup                         # FTItemPickup *
	var ip = _ftGetComTargetItem(fp.computer)                     # ITStruct *
	var ft_pos: Vector3 = DObjGetStruct(fp.fighter_gobj).translate
	var it_pos: Vector3 = DObjGetStruct(ip.item_gobj).translate
	var map_coll: MPObjectColl = ip.coll_data.map_coll

	if ip.weight == nITWeightLight:
		var range_: Vector2         # C: Vec2f range

		range_.x = ft_pos.x + (fp.lr * item_pickup.pickup_offset_light.x)
		range_.y = ft_pos.y + item_pickup.pickup_offset_light.y

		if (((range_.x - item_pickup.pickup_range_light.x) - map_coll.width) < it_pos.x) and (((item_pickup.pickup_range_light.x + range_.x) + map_coll.width) > it_pos.x):
			if (((range_.y - item_pickup.pickup_range_light.y) - map_coll.top) < it_pos.y) and (((item_pickup.pickup_range_light.y + range_.y) - map_coll.bottom) > it_pos.y):
				return TRUE
	else:
		var range_: Vector2         # C: Vec2f range

		range_.x = ft_pos.x + (fp.lr * item_pickup.pickup_offset_heavy.x)
		range_.y = ft_pos.y + item_pickup.pickup_offset_heavy.y

		if (((range_.x - item_pickup.pickup_range_heavy.x) - map_coll.width) < it_pos.x) and (((item_pickup.pickup_range_heavy.x + range_.x) + map_coll.width) > it_pos.x):
			if (((range_.y - item_pickup.pickup_range_heavy.y) - map_coll.top) < it_pos.y) and (((item_pickup.pickup_range_heavy.y + range_.y) - map_coll.bottom) > it_pos.y):
				return TRUE
	return FALSE

## 0x801366F0
static func ftComputerCheckSetEvadeTarget(this_fp) -> int:
	var com: FTComputer
	var current_dist: float
	var nearest_dist: float
	var this_pos_x: float
	var predict_x: float
	var predict_y: float
	var this_pos_y: float
	var target_fp: Fighter
	var edge_pos: Vector3
	var line_id: int

	com = this_fp.computer

	nearest_dist = 6250000.0

	this_pos_x = this_fp.joints[nFTPartsJointTopN].translate.x
	this_pos_y = this_fp.joints[nFTPartsJointTopN].translate.y

	com.ftcom_flags_0x4A_b1 = FALSE

	for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		if fighter_gobj == this_fp.fighter_gobj:
			continue                        # goto next_fighter

		target_fp = ftGetStruct(fighter_gobj)

		if this_fp.team == target_fp.team:
			continue                        # goto next_fighter

		predict_x = target_fp.joints[nFTPartsJointTopN].translate.x + (target_fp.physics.vel_air.x * 3.0)
		predict_y = target_fp.joints[nFTPartsJointTopN].translate.y + (target_fp.physics.vel_air.x * 3.0)

		if (target_fp.star_hitstatus == nGMHitStatusInvincible) or ((target_fp.item_gobj != null) and (itGetStruct(target_fp.item_gobj).kind == nITKindHammer)):
			com.target_user = target_fp

			nearest_dist = SQUARE(this_pos_x - predict_x) + SQUARE(this_pos_y - predict_y)

			break

		elif (
			(target_fp.status_id >= nFTCommonStatusWait) and
			(predict_x <= _gMPCollisionBounds().current.right) and
			(predict_x >= _gMPCollisionBounds().current.left) and
			(predict_y >= _gMPCollisionBounds().current.bottom)
		):
			current_dist = SQUARE(this_pos_x - predict_x) + SQUARE(this_pos_y - predict_y)

			if nearest_dist > current_dist:
				com.target_user = target_fp

				nearest_dist = current_dist

	if nearest_dist == 6250000.0:
		com.target_pos.x = this_pos_x
		com.target_pos.y = this_pos_y
		com.target_line_id = -1

		return TRUE
	else:
		target_fp = com.target_user

		predict_x = target_fp.joints[nFTPartsJointTopN].translate.x
		predict_y = target_fp.joints[nFTPartsJointTopN].translate.y

		if this_fp.coll_data.floor_line_id >= 0:
			line_id = this_fp.coll_data.floor_line_id

			if this_pos_x < predict_x:
				edge_pos = Mpcollision.mpCollisionGetFloorEdgeL(line_id)
			else:
				edge_pos = Mpcollision.mpCollisionGetFloorEdgeR(line_id)
		else:
			edge_pos = this_fp.joints[nFTPartsJointTopN].translate

		if target_fp.ga == nMPKineticsGround:
			com.target_pos.y = predict_y
		else:
			com.target_pos.y = this_pos_y

		if this_pos_x < predict_x:
			com.target_pos.x = predict_x - 2500.0

			if com.target_pos.x < edge_pos.x:
				com.target_pos.x = predict_x + 2500.0

				ftComputerSetCommandWaitShort(this_fp, nFTComputerInputMoveAutoStickTiltHiReleaseZ)

				return FALSE
		else:
			com.target_pos.x = predict_x + 2500.0

			if com.target_pos.x > edge_pos.x:
				com.target_pos.x = predict_x - 2500.0

				ftComputerSetCommandWaitShort(this_fp, nFTComputerInputMoveAutoStickTiltHiReleaseZ)

				return FALSE

		com.target_dist = sqrtf(nearest_dist)
		com.target_line_id = -1
		com.objective = nFTComputerObjectiveEvade

	return TRUE

## 0x80136A20
static func ftComputerCheckTryChargeSpecialN(fp) -> int:
	match fp.fkind:
		nFTKindDonkey:
			if (
				(fp.status_id != nFTDonkeyStatusSpecialNStart) and
				(fp.status_id != nFTDonkeyStatusSpecialAirNStart) and
				(fp.status_id != nFTDonkeyStatusSpecialNLoop) and
				(fp.status_id != nFTDonkeyStatusSpecialAirNLoop) and
				(fp.status_id != nFTDonkeyStatusSpecialLwStart) and
				(fp.status_id != nFTDonkeyStatusSpecialLwLoop) and
				(fp.status_id != nFTDonkeyStatusSpecialLwEnd) and
				(fp.passive_vars.donkey.charge_level < FTDONKEY_GIANTPUNCH_CHARGE_MAX)
			):
				ftComputerSetCommandWaitShort(fp, 0xB)
				return TRUE

		nFTKindGDonkey:
			match fp.status_id:
				nFTCommonStatusWait, nFTCommonStatusWalkSlow, nFTCommonStatusWalkMiddle, nFTCommonStatusWalkFast, nFTCommonStatusDash, nFTCommonStatusRun, nFTCommonStatusRunBrake, nFTCommonStatusSquat, nFTCommonStatusSquatWait, nFTCommonStatusSquatRv, nFTCommonStatusLandingLight, nFTCommonStatusOttottoWait, nFTCommonStatusOttotto:
					if fp.passive_vars.donkey.charge_level < FTDONKEY_GIANTPUNCH_CHARGE_MAX:
						ftComputerSetCommandWaitShort(fp, 0xB)
						return TRUE

		nFTKindSamus:
			if (
				(fp.status_id != nFTSamusStatusSpecialNStart) and
				(fp.status_id != nFTSamusStatusSpecialAirNStart) and
				(fp.status_id != nFTSamusStatusSpecialNLoop) and
				(fp.status_id != nFTSamusStatusSpecialAirNEnd) and
				(fp.passive_vars.samus.charge_level < FTSAMUS_CHARGE_MAX)
			):
				ftComputerSetCommandWaitShort(fp, 0xB)
				return TRUE

		nFTKindKirby:
			match fp.passive_vars.kirby.copy_id:
				nFTKindDonkey:
					if (
						(fp.status_id != nFTKirbyStatusCopyDonkeySpecialNStart) and
						(fp.status_id != nFTKirbyStatusCopyDonkeySpecialAirNStart) and
						(fp.status_id != nFTKirbyStatusCopyDonkeySpecialNLoop) and
						(fp.status_id != nFTKirbyStatusCopyDonkeySpecialAirNLoop) and
						(fp.passive_vars.kirby.copydonkey_charge_level < FTKIRBY_COPYDONKEY_GIANTPUNCH_CHARGE_MAX)
					):
						ftComputerSetCommandWaitShort(fp, 0xB)
						return TRUE

				nFTKindSamus:
					if (
						(fp.status_id != nFTKirbyStatusCopySamusSpecialNStart) and
						(fp.status_id != nFTKirbyStatusCopySamusSpecialAirNStart) and
						(fp.status_id != nFTKirbyStatusCopySamusSpecialNLoop) and
						(fp.status_id != nFTKirbyStatusCopySamusSpecialAirNEnd) and
						(fp.passive_vars.kirby.copysamus_charge_level < FTKIRBY_COPYSAMUS_CHARGE_MAX)
					):
						ftComputerSetCommandWaitShort(fp, 0xB)
						return TRUE
	return FALSE

## 0x80136C0C
static func ftComputerCheckTryCancelSpecialN(fp) -> int:
	match (fp.passive_vars.kirby.copy_id if (fp.fkind == nFTKindKirby) else fp.fkind):
		nFTKindDonkey, nFTKindGDonkey:
			if (
				(fp.status_id == nFTDonkeyStatusSpecialNStart) or
				(fp.status_id == nFTDonkeyStatusSpecialAirNStart) or
				(fp.status_id == nFTDonkeyStatusSpecialNLoop) or
				(fp.status_id == nFTDonkeyStatusSpecialAirNLoop) or
				(fp.status_id == nFTKirbyStatusCopyDonkeySpecialNStart) or
				(fp.status_id == nFTKirbyStatusCopyDonkeySpecialAirNStart) or
				(fp.status_id == nFTKirbyStatusCopyDonkeySpecialNLoop) or
				(fp.status_id == nFTKirbyStatusCopyDonkeySpecialAirNLoop)
			):
				ftComputerSetCommandWaitShort(fp, 0xC)
				return TRUE

		nFTKindSamus:
			if (
				(fp.status_id == nFTSamusStatusSpecialNStart) or
				(fp.status_id == nFTSamusStatusSpecialAirNStart) or
				(fp.status_id == nFTSamusStatusSpecialNLoop) or
				(fp.status_id == nFTSamusStatusSpecialAirNEnd) or
				(fp.status_id == nFTKirbyStatusCopySamusSpecialNStart) or
				(fp.status_id == nFTKirbyStatusCopySamusSpecialAirNStart) or
				(fp.status_id == nFTKirbyStatusCopySamusSpecialNLoop) or
				(fp.status_id == nFTKirbyStatusCopySamusSpecialAirNEnd)
			):
				ftComputerSetCommandWaitShort(fp, 0xC)
				return TRUE
	return FALSE

## 0x80136D0C - 0 = Do not process current objective, 1 = new objective has been given out, -1 = process current objective
static func ftComputerGetObjectiveStatus(this_gobj) -> int:
	var this_fp: Fighter = ftGetStruct(this_gobj)
	var com: FTComputer = this_fp.computer
	var action_wait: int
	var tarucann_pos: Vector3
	var acid_level_curr: float
	var acid_level_step: float
	var fvar: float

	if this_fp.status_id == nFTCommonStatusCliffWait:
		action_wait = (1080 - this_fp.status_vars.common.cliffwait.fall_wait) if (this_fp.status_vars.common.cliffwait.fall_wait > 480) else (480 - this_fp.status_vars.common.cliffwait.fall_wait)

		if syUtilsRandFloat() < 0.01:
			action_wait *= 2

		if ((FTCOMPUTER_LEVEL_MAX - this_fp.level) * 15) < action_wait:
			if syUtilsRandFloat() < 0.4:
				ftComputerSetCommandWaitShort(this_fp, 0x28)

				return 0

			elif syUtilsRandFloat() < 0.5:
				ftComputerSetCommandWaitShort(this_fp, nFTComputerInputButtonZ1)

				return 0
			else:
				ftComputerSetCommandWaitShort(this_fp, nFTComputerInputMoveAutoStickTiltHiReleaseZ)

			return 0

	if (this_fp.status_id == nFTCommonStatusDownWaitD) or (this_fp.status_id == nFTCommonStatusDownWaitU):
		action_wait = 180 - this_fp.status_vars.common.downwait.stand_wait

		if ((FTCOMPUTER_LEVEL_MAX - this_fp.level) * 25) < action_wait:
			ftComputerCheckFindTarget(this_fp)

			if (this_fp.fkind != nFTKindGDonkey) and (com.target_dist < 800.0) and (this_fp.level >= 4):
				if (syUtilsRandFloat() * (11 - this_fp.level)) < 1.0:
					if com.target_pos.x < this_fp.joints[nFTPartsJointTopN].translate.x:
						ftComputerSetCommandWaitShort(this_fp, nFTComputerInputEscapeL)

						return 0

					ftComputerSetCommandWaitShort(this_fp, nFTComputerInputEscapeR)

					return 0

			ftComputerSetCommandWaitShort(this_fp, nFTComputerInputStickNButtonBZReleaseAPress)

			return 0

	if (
		(this_fp.status_id == nFTCommonStatusOttottoWait) or
		(this_fp.status_id == nFTCommonStatusOttotto) or
		(this_fp.status_id == nFTCommonStatusSquatWait)
	):
		ftComputerSetCommandWaitShort(this_fp, nFTComputerInputMoveAutoStickTiltHiReleaseZ)

		return 0

	if this_fp.status_id == nFTCommonStatusTaruCann:
		tarucann_pos = Grjungle.grJungleTaruCannGetPosition()

		tarucann_pos.y = 2000.0

		if Mpcollision.func_ovl2_800F8FFC(tarucann_pos) != FALSE:
			fvar = (-Grjungle.grJungleTaruCannGetRotate()) if (Grjungle.grJungleTaruCannGetRotate() < 0.0) else Grjungle.grJungleTaruCannGetRotate()

			if fvar < 0.05:
				ftComputerSetCommandImmediate(this_fp, nFTComputerInputStickNButtonBZReleaseAPress)

				return 0

	if this_fp.status_id == nFTCommonStatusCatchWait:
		if this_fp.joints[nFTPartsJointTopN].translate.x < 0.0:
			ftComputerSetCommandImmediate(this_fp, nFTComputerInputStickSmashL)
			return 0
		else:
			ftComputerSetCommandImmediate(this_fp, nFTComputerInputStickSmashR)

		return 0

	if (
		(this_fp.status_id == nFTCommonStatusCaptureWaitKirby) or
		(this_fp.status_id == nFTCommonStatusYoshiEgg) or
		(this_fp.status_id == nFTCommonStatusFuraFura) or
		(this_fp.status_id == nFTCommonStatusFuraSleep) or
		(this_fp.status_id == nFTCommonStatusShouldered)
	):
		com.target_find_wait = _u16(com.target_find_wait + 1)

		if ((FTCOMPUTER_LEVEL_MAX - this_fp.level) * 15) < com.target_find_wait:
			ftComputerSetCommandWaitShort(this_fp, nFTComputerInputWiggle)

			return 0
	else:
		com.target_find_wait = 0

	if this_fp.fkind == nFTKindKirby:
		if (
			(this_fp.status_id == nFTKirbyStatusSpecialNCatch) or
			(this_fp.status_id == nFTKirbyStatusSpecialAirNCatch) or
			(this_fp.status_id == nFTKirbyStatusSpecialNEat) or
			(this_fp.status_id == nFTKirbyStatusSpecialAirNEat)
		):
			ftComputerSetCommandImmediate(this_fp, nFTComputerInputStickN)
			return 0

		elif (this_fp.status_id == nFTKirbyStatusSpecialNWait) or (this_fp.status_id == nFTKirbyStatusSpecialAirNWait):
			ftComputerSetCommandWaitShort(this_fp, nFTComputerInputStickSmashLwButtonB)

			return 0

	if this_fp.fkind == nFTKindNess:
		if (this_fp.status_id == nFTNessStatusSpecialHiHold) or (this_fp.status_id == nFTNessStatusSpecialAirHiHold):
			if Mpcollision.func_ovl2_800F8FFC(this_fp.joints[nFTPartsJointTopN].translate) == FALSE:
				com.target_pos.x = this_fp.joints[nFTPartsJointTopN].translate.x

				if this_fp.joints[nFTPartsJointTopN].translate.x > 0.0:
					com.target_pos.x += 200.0
				else:
					com.target_pos.x -= 200.0

				com.target_pos.y = this_fp.joints[nFTPartsJointTopN].translate.y - 100.0
			else:
				ftComputerCheckFindTarget(this_fp)

			ftComputerSetCommandImmediate(this_fp, nFTComputerInputNessSpecialHiAim)

			return 0

	if this_fp.ga == nMPKineticsGround:
		if (
			(
				(SQUARE(this_fp.joints[nFTPartsJointTopN].translate.x - com.stand_pos.x) +
				SQUARE(this_fp.joints[nFTPartsJointTopN].translate.y - com.stand_pos.y)) > SQUARE(100.0)
			)
			or
			(com.behavior == nFTComputerBehaviorStand)
		):
			com.stand_pos.x = this_fp.joints[nFTPartsJointTopN].translate.x
			com.stand_pos.y = this_fp.joints[nFTPartsJointTopN].translate.y
			com.stand_stop_wait = 0
			com.is_stop_stand = FALSE
		else:
			com.stand_stop_wait = _u16(com.stand_stop_wait + 1)

			if com.stand_stop_wait > 300:
				com.is_stop_stand = TRUE
	else:
		com.stand_stop_wait = 0
		com.is_stop_stand = FALSE

	if com.is_stop_stand != FALSE:
		ftComputerSetCommandImmediate(this_fp, nFTComputerInputMoveAutoStickTiltHiReleaseZ)

		return 0

	if this_fp.percent_damage != 0:
		match com.behavior:
			nFTComputerBehaviorYoshiTeam:
				if ((this_fp.level - 4) * 0.01) <= syUtilsRandFloat():
					return -1
				# fallthrough into nFTComputerBehaviorKirbyTeam
				if ((this_fp.level - 3) * 0.03) <= syUtilsRandFloat():
					return -1

			nFTComputerBehaviorKirbyTeam:
				if ((this_fp.level - 3) * 0.03) <= syUtilsRandFloat():
					return -1

			nFTComputerBehaviorPolyTeam:
				if (this_fp.level * 0.04) <= syUtilsRandFloat():
					return -1

	if (
		(Mpcollision.func_ovl2_800F8FFC(this_fp.joints[nFTPartsJointTopN].translate) == FALSE) or
		(
			(G.gSCManagerBattleState.gkind == nGRKindInishie) and
			(this_fp.coll_data.floor_line_id >= 0) and
			(Mpcollision.mpCollisionCheckExistPlatformLineID(this_fp.coll_data.floor_line_id) != FALSE) and
			(this_fp.joints[nFTPartsJointTopN].translate.y < -100.0)
		)
	):
		if com.objective != nFTComputerObjectiveRecover:
			com.is_attempt_specialhi_recovery = FALSE

		com.objective = nFTComputerObjectiveRecover

		return 1

	if G.gSCManagerBattleState.gkind == nGRKindZebes:
		var acid_level = Grzebes.grZebesAcidGetLevelInfo()

		acid_level_curr = acid_level.current
		acid_level_step = acid_level.step

		if (
			(this_fp.joints[nFTPartsJointTopN].translate.y < (acid_level_curr + 500.0)) or
			(this_fp.joints[nFTPartsJointTopN].translate.y < (acid_level_curr + (5.0 * acid_level_step) + 500.0))
		):
			com.objective = nFTComputerObjectiveRecover

			return 1

	com.is_within_vertical_bounds = FALSE

	if com.objective == nFTComputerObjectiveRecover:
		com.objective = nFTComputerObjectiveWalk

	if (this_fp.status_id == nFTCommonStatusDamageFall) and (((this_fp.physics.vel_air.y * 5.0) + -this_fp.coll_data.floor_dist) <= 0.0):
		if com.ftcom_flags_0x49_b3 == FALSE:
			com.ftcom_flags_0x49_b3 = TRUE

			if this_fp.level >= 3:
				if (syUtilsRandFloat() * (325 - (this_fp.level * 25))) < 70.0:
					com.objective = nFTComputerObjectiveCounterAttack
					com.is_counterattack = TRUE

					return 1
	else:
		com.ftcom_flags_0x49_b3 = FALSE

	if this_fp.computer.attack_count != this_fp.attack_count:
		this_fp.computer.attack_count = _u16(this_fp.attack_count)

		if this_fp.attack_knockback > 160.0:
			com.appeal_attempt_frames = 60

	if com.appeal_attempt_frames != 0:
		com.appeal_attempt_frames -= 1

		if (G.gSCManagerBattleState.gkind == nGRKindInishie) or (G.gSCManagerBattleState.gkind == nGRKindYoster):
			if this_fp.coll_data.floor_line_id >= 0:
				if Mpcollision.mpCollisionCheckExistPlatformLineID(this_fp.coll_data.floor_line_id) != FALSE:
					return -1

		if com.target_dist > 2500.0:
			match this_fp.status_id:
				nFTCommonStatusWait, nFTCommonStatusWalkSlow, nFTCommonStatusWalkMiddle, nFTCommonStatusWalkFast, nFTCommonStatusDash, nFTCommonStatusRun, nFTCommonStatusRunBrake, nFTCommonStatusSquat, nFTCommonStatusSquatWait, nFTCommonStatusSquatRv, nFTCommonStatusLandingLight, nFTCommonStatusOttottoWait, nFTCommonStatusOttotto:
					com.appeal_attempt_frames = 0

					ftComputerSetCommandWaitShort(this_fp, nFTComputerInputStickNButtonL)

					return 0
	return -1

## 0x80137778
static func ftComputerProcDefault(fighter_gobj) -> int:
	var fp: Fighter = ftGetStruct(fighter_gobj)
	var com: FTComputer = fp.computer
	var process_result: int = ftComputerGetObjectiveStatus(fighter_gobj)

	if (process_result == 0) or (process_result == 1):
		return process_result

	if ftComputerCheckEvadeDistance(fp) != FALSE:
		com.objective = nFTComputerObjectiveEvade
		return TRUE

	if (fp.fkind != nFTKindMMario) and (fp.fkind != nFTKindGDonkey):
		if func_ovl3_80135B78(fp) != FALSE:
			com.objective = nFTComputerObjectiveCounterAttack
			return TRUE

	match fp.fkind:
		nFTKindFox, nFTKindNFox:
			if (fp.status_id >= nFTFoxStatusSpecialLwScopeStart) and (fp.status_id <= nFTFoxStatusSpecialLwScopeEnd):
				ftComputerSetCommandWaitShort(fp, nFTComputerInputStickNButtonBRelease)
				return FALSE

		nFTKindNess, nFTKindNNess:
			if (fp.status_id >= nFTNessStatusSpecialLwScopeStart) and (fp.status_id <= nFTNessStatusSpecialLwScopeEnd):
				ftComputerSetCommandWaitShort(fp, nFTComputerInputStickNButtonBRelease)
				return FALSE

	if (fp.status_id >= nFTCommonStatusGuardStart) and (fp.status_id <= nFTCommonStatusGuardEnd):
		ftComputerSetCommandWaitShort(fp, 0x24)
		return FALSE
	else:
		ftComputerCheckFindTarget(fp)

	if com.target_dist < 350.0:
		com.objective = nFTComputerObjectiveAttack
		return TRUE

	elif ftComputerCheckFindItem(fp) != FALSE:
		if com.target_dist < (400.0 * (fp.level + 3)):
			var track_wait: int = ((-fp.level * 35) + 315) if (G.gSCManagerBattleState.game_type == nSCBattleGameType1PGame) else ((-fp.level * 25) + 225)

			com.item_track_wait = _u16(com.item_track_wait + 1)

			if track_wait < com.item_track_wait:
				com.objective = nFTComputerObjectiveTrackItem
				return TRUE
	else:
		com.item_track_wait = 0

	if fp.item_gobj != null:
		var ip: Item = itGetStruct(fp.item_gobj)

		match ip.type:
			nITTypeDamage, nITTypeShoot, nITTypeThrow:
				com.objective = nFTComputerObjectiveUseItem
				return TRUE

			_:
				com.objective = nFTComputerObjectiveAttack
				return TRUE
	else:
		com.objective = com.objective_base

	return TRUE

## 0x80137A18
static func ftComputerProcStand(fighter_gobj) -> int:
	var fp: Fighter = ftGetStruct(fighter_gobj)
	var com: FTComputer = fp.computer
	var objective_status: int = ftComputerGetObjectiveStatus(fighter_gobj)

	com.ftcom_flags_0x4A_b1 = FALSE

	if (objective_status == 0) or (objective_status == 1):
		return objective_status

	if fp.status_id == nFTCommonStatusRebirthWait:
		com.target_pos.x = com.origin_pos.x
		com.target_pos.y = com.origin_pos.y
		com.target_line_id = com.floor_line_id

		com.objective = nFTComputerObjectiveWalk
	else:
		com.objective = nFTComputerObjectiveStand

	return 1

## 0x80137AA4
static func ftComputerProcWalk(fighter_gobj) -> int:
	var fp: Fighter = ftGetStruct(fighter_gobj)
	var com: FTComputer = fp.computer
	var objective_status: int = ftComputerGetObjectiveStatus(fighter_gobj)
	var edge_left_pos: Vector3
	var edge_right_pos: Vector3
	var dist: float

	com.ftcom_flags_0x4A_b1 = FALSE

	if (objective_status == 0) or (objective_status == 1):
		return objective_status

	com.target_pos.y = com.origin_pos.y
	com.target_line_id = com.floor_line_id

	if _DISTANCE(com.target_pos.x, fp.joints[nFTPartsJointTopN].translate.x) < 100.0:
		com.target_pos.x = (((2.0 * syUtilsRandFloat()) - 1.0) * 2500.0) + com.origin_pos.x

		if (com.floor_line_id < 0) or (Mpcollision.mpCollisionCheckExistLineID(com.floor_line_id) == FALSE):
			com.target_pos.x = com.origin_pos.x
		else:
			edge_left_pos = Mpcollision.mpCollisionGetFloorEdgeL(com.floor_line_id)
			edge_right_pos = Mpcollision.mpCollisionGetFloorEdgeR(com.floor_line_id)

			if com.target_pos.x < edge_left_pos.x:
				com.target_pos.x = edge_left_pos.x
				com.target_pos.y = edge_left_pos.y

			if com.target_pos.x > edge_right_pos.x:
				com.target_pos.x = edge_right_pos.x
				com.target_pos.y = edge_right_pos.y

	com.objective = nFTComputerObjectiveWalk

	dist = SQUARE(com.target_pos.x - fp.joints[nFTPartsJointTopN].translate.x) + SQUARE(com.target_pos.y - fp.joints[nFTPartsJointTopN].translate.y)

	if dist < SQUARE(100.0):
		com.objective = nFTComputerObjectiveStand

	return 1

## 0x80137C7C
static func ftComputerProcEvade(fighter_gobj) -> int:
	var fp: Fighter = ftGetStruct(fighter_gobj)
	var com: FTComputer = fp.computer
	var objective_status: int = ftComputerGetObjectiveStatus(fighter_gobj)

	com.ftcom_flags_0x4A_b1 = FALSE

	if (objective_status == 0) or (objective_status == 1):
		return objective_status

	com.objective = nFTComputerObjectiveEvade

	return 1

## 0x80137CD8
static func ftComputerProcJump(fighter_gobj) -> int:
	var fp: Fighter = ftGetStruct(fighter_gobj)
	var com: FTComputer = fp.computer
	var objective_status: int = ftComputerGetObjectiveStatus(fighter_gobj)
	var dist: float

	com.ftcom_flags_0x4A_b1 = FALSE

	if (objective_status == 0) or (objective_status == 1):
		return objective_status

	com.target_pos.x = com.origin_pos.x

	if com.jump_wait == 0:
		com.jump_wait = _u16(_f2i((syUtilsRandFloat() * 30.0) + 30.0))
		com.target_pos.y = com.origin_pos.y + 1100.0
		com.target_line_id = -1
	else:
		com.target_pos.y = com.origin_pos.y
		com.target_line_id = com.floor_line_id
		com.jump_wait -= 1

	com.objective = nFTComputerObjectiveWalk

	dist = SQUARE(com.target_pos.x - fp.joints[nFTPartsJointTopN].translate.x) + SQUARE(com.target_pos.y - fp.joints[nFTPartsJointTopN].translate.y)

	if dist < SQUARE(100.0):
		com.objective = nFTComputerObjectiveStand

	return 1

## 0x80137E70
static func func_ovl3_80137E70(fighter_gobj) -> int:
	var fp: Fighter = ftGetStruct(fighter_gobj)
	var com: FTComputer = fp.computer
	var objective_status: int = ftComputerGetObjectiveStatus(fighter_gobj)
	var dist: float

	com.ftcom_flags_0x4A_b1 = FALSE

	if (objective_status == 0) or (objective_status == 1):
		return objective_status

	com.target_pos.x = com.origin_pos.x
	com.target_pos.y = com.origin_pos.y
	com.target_line_id = com.floor_line_id

	com.objective = nFTComputerObjectiveWalk

	dist = SQUARE(com.target_pos.x - fp.joints[nFTPartsJointTopN].translate.x) + SQUARE(com.target_pos.y - fp.joints[nFTPartsJointTopN].translate.y)

	if dist < SQUARE(100.0):
		com.objective = nFTComputerObjectiveStand

	return 1

## 0x80137F24
static func ftComputerFollowObjectiveRecover(fp) -> void:
	var com: FTComputer = fp.computer

	if ftComputerCheckTryCancelSpecialN(fp) == FALSE:
		func_ovl3_80134964(fp)

		# REGION_US
		if fp.fkind == nFTKindPikachu:
			match fp.status_id:
				nFTPikachuStatusSpecialAirHiStart:
					com.target_pos.x = fp.joints[nFTPartsJointTopN].translate.x
					com.target_pos.y = fp.joints[nFTPartsJointTopN].translate.y + 1100.0

				nFTPikachuStatusSpecialAirHi:
					com.target_pos.x = 0.0
					com.target_pos.y = fp.joints[nFTPartsJointTopN].translate.y

		ftComputerFollowObjectiveWalk(fp)

## 0x80137FD4 - Not entirely sure about this one, seems to run when a CPU is about to land from DamageFall
static func ftComputerFollowObjectiveCounterAttack(fp) -> void:
	var com: FTComputer = fp.computer

	func_ovl3_801361BC(fp)

	if com.is_counterattack != FALSE:
		ftComputerSetCommandImmediate(fp, nFTComputerInputButtonZ2)

		com.is_counterattack = FALSE

	elif com.is_opponent_ra != FALSE:
		com.is_opponent_ra = FALSE

		match fp.fkind:
			nFTKindFox, nFTKindNFox:
				if (fp.status_id < nFTFoxStatusSpecialLwScopeStart) or (fp.status_id > nFTFoxStatusSpecialLwScopeEnd):
					ftComputerSetCommandImmediate(fp, nFTComputerInputStickNXSmashLwButtonBReleaseBHold)

			nFTKindNess, nFTKindNNess:
				if (fp.status_id < nFTNessStatusSpecialLwScopeStart) or (fp.status_id > nFTNessStatusSpecialLwScopeEnd):
					ftComputerSetCommandImmediate(fp, nFTComputerInputStickNXSmashLwButtonBReleaseBHold)

	elif com.is_shield_item_weapon != FALSE:
		com.is_shield_item_weapon = FALSE

		if (fp.status_id < nFTCommonStatusGuardStart) or (fp.status_id > nFTCommonStatusGuardEnd):
			ftComputerSetCommandImmediate(fp, nFTComputerInputStickNButtonZHold)
	else:
		ftComputerFollowObjectiveWalk(fp)

## 0x80138104 - Try to navigate to target item
static func ftComputerFollowObjectiveTrackItem(fp) -> void:
	if ftComputerCheckTargetItemInRange(fp) != FALSE:
		if (fp.status_id == nFTCommonStatusWait) or (fp.status_id == nFTCommonStatusSquat):
			ftComputerSetCommandWaitShort(fp, nFTComputerInputStickNButtonBZReleaseAPress)
			return

	ftComputerFollowObjectiveWalk(fp)

## 0x8013815C - Try to use shootable, throwable and ground (?) items
static func ftComputerFollowObjectiveUseItem(fp) -> void:
	var com: FTComputer = fp.computer
	var ip: Item = itGetStruct(fp.item_gobj)
	var target_fp
	var is_throw: bool = false          # C: case nITTypeShoot falls through into nITTypeDamage / nITTypeThrow

	match ip.type:
		nITTypeShoot:
			if ip.multi != 0:
				ftComputerCheckFindTarget(fp)
				target_fp = _ftGetComTargetFighter(com)

				if (fp.level >= 5) and (target_fp != null):
					if (_ftGetFKind(target_fp) == nFTKindNess) or (_ftGetFKind(target_fp) == nFTKindFox):
						ftComputerSetCommandWaitShort(fp, nFTComputerInputThrowItemImmediate)
						return

				if _DISTANCE(fp.joints[nFTPartsJointTopN].translate.y, com.target_pos.y) < 400.0:
					if (
						(ip.kind == nITKindFFlower) and
						(
							(((com.target_pos.x - fp.joints[nFTPartsJointTopN].translate.x) * fp.lr) < 0.0) or
							(((com.target_pos.x - fp.joints[nFTPartsJointTopN].translate.x) * fp.lr) > 1500.0)
						)
					):
						ftComputerFollowObjectiveWalk(fp)
					else:
						ftComputerSetCommandWaitShort(fp, nFTComputerInputStickTiltAutoXButtonBZReleaseAPress)
				else:
					ftComputerFollowObjectiveWalk(fp)

				com.item_throw_wait = 0
				return

			com.item_throw_wait = _u8(com.item_throw_wait + 1)
			is_throw = true             # fallthrough

		nITTypeDamage, nITTypeThrow:
			is_throw = true

	if is_throw:
		ftComputerCheckFindTarget(fp)

		if (com.item_throw_wait >= 3) or (ip.kind == nITKindMBall):
			ftComputerSetCommandWaitShort(fp, nFTComputerInputThrowItemWait)

			com.item_throw_wait = 0
		else:
			ftComputerSetCommandWaitShort(fp, nFTComputerInputThrowItemImmediate)

## 0x8013834C
static func ftComputerFollowObjectiveEvade(fp) -> void:
	if ftComputerCheckSetEvadeTarget(fp) != FALSE:
		ftComputerFollowObjectiveWalk(fp)

## 0x8013837C
static func func_ovl3_8013837C(this_fp) -> int:
	var com: FTComputer = this_fp.computer

	if (this_fp.computer.behavior != nFTComputerBehaviorYoshiTeam) and (this_fp.fkind != nFTKindGDonkey):
		var target_fp = ftComputerWaitGetTarget(this_fp)

		if target_fp != null:
			com.target_user = target_fp
			com.target_pos.x = target_fp.joints[nFTPartsJointTopN].translate.x
			com.target_pos.y = target_fp.joints[nFTPartsJointTopN].translate.y

			com.target_dist = sqrtf(
				SQUARE(this_fp.joints[nFTPartsJointTopN].translate.x - com.target_pos.x) +
				SQUARE(this_fp.joints[nFTPartsJointTopN].translate.y - com.target_pos.y)
			)
			com.ftcom_flags_0x4A_b1 = TRUE

			if _ftGetComTargetFighter(com).ga == nMPKineticsGround:
				com.target_line_id = _ftGetComTargetFighter(com).coll_data.floor_line_id
			else:
				com.target_line_id = -1

			return 1

	if (ftComputerCheckFindTarget(this_fp) == FALSE) or (com.fighter_follow_since == 0):
		com.fighter_follow_since = 1

		# NOTE: This only trims the (syUtilsRandFloat() * (FTCOMPUTER_LEVEL_MAX - this_fp->level) * 4.0F) part to 8-bits.
		com.fighter_follow_wait = _u16(_u8(_f2i(syUtilsRandFloat() * (FTCOMPUTER_LEVEL_MAX - this_fp.level) * 4.0)) + ((FTCOMPUTER_LEVEL_MAX - this_fp.level) * 16))

		if com.behavior == nFTComputerBehaviorYoshiTeam:
			com.fighter_follow_wait = _u16(_f2i(com.fighter_follow_wait + (300.0 + (syUtilsRandFloat() * 300.0))))

		com.fighter_follow_end = _u16(_f2i((syUtilsRandFloat() * 120.0) + (com.fighter_follow_wait + 120)))

		return 0

	com.fighter_follow_since = _u16(com.fighter_follow_since + 1)

	if com.fighter_follow_wait < com.fighter_follow_since:
		if com.fighter_follow_end < com.fighter_follow_since:
			com.fighter_follow_since = 0

		if com.target_dist < 1200.0:
			if ftComputerCheckTryCancelSpecialN(this_fp) != FALSE:
				return -1

		elif (this_fp.ga == nMPKineticsGround) and (ftComputerCheckTryChargeSpecialN(this_fp) != FALSE):
			return -1

		return 1

	return 0

## 0x8013877C
static func func_ovl3_8013877C(this_fp) -> void:
	var com: FTComputer = this_fp.computer
	var edge_left_pos: Vector3
	var edge_right_pos: Vector3

	com.walk_stop_wait = _u16(com.walk_stop_wait + 1)

	if com.walk_stop_wait >= 30:
		if com.walk_stop_wait == 30:
			if this_fp.coll_data.floor_line_id >= 0:
				com.floor_line_id = this_fp.coll_data.floor_line_id

				com.origin_pos.x = this_fp.joints[nFTPartsJointTopN].translate.x
				com.edge_pos.x = com.origin_pos.x

				if this_fp.ga == nMPKineticsGround:
					com.origin_pos.y = this_fp.joints[nFTPartsJointTopN].translate.y
					com.edge_pos.y = com.origin_pos.y
				else:
					com.origin_pos.y = this_fp.joints[nFTPartsJointTopN].translate.y + this_fp.coll_data.floor_dist
					com.edge_pos.y = com.origin_pos.y
			else:
				com.edge_pos.x = com.origin_pos.x
				com.edge_pos.y = com.origin_pos.y

		com.target_line_id = com.floor_line_id

		if (com.target_line_id < 0) or (Mpcollision.mpCollisionCheckExistLineID(com.target_line_id) == FALSE):
			if ftComputerCheckFindTarget(this_fp) != FALSE:
				ftComputerFollowObjectiveWalk(this_fp)
		else:
			if _DISTANCE(com.edge_pos.x, this_fp.joints[nFTPartsJointTopN].translate.x) < 100.0:
				com.edge_pos.x = (((2.0 * syUtilsRandFloat()) - 1.0) * 2500.0) + com.origin_pos.x

				edge_left_pos = Mpcollision.mpCollisionGetFloorEdgeL(com.floor_line_id)
				edge_right_pos = Mpcollision.mpCollisionGetFloorEdgeR(com.floor_line_id)

				if com.edge_pos.x < edge_left_pos.x:
					com.edge_pos.x = edge_left_pos.x
					com.edge_pos.y = edge_left_pos.y

				if com.edge_pos.x > edge_right_pos.x:
					com.edge_pos.x = edge_right_pos.x
					com.edge_pos.y = edge_right_pos.y

			com.target_pos.x = com.edge_pos.x
			com.target_pos.y = com.edge_pos.y

			com.ftcom_flags_0x4A_b1 = FALSE

			ftComputerFollowObjectiveWalk(this_fp)

			if com.walk_stop_wait > 150:
				com.walk_stop_wait = 0
	else:
		com.input_wait = 1
		com.p_command = dFTComputerPlayerInputScripts[nFTComputerInputStickN]
		com.p_command_index = 0

		if (com.walk_stop_wait == ((-this_fp.level * 2) + 18)) and (this_fp.ga == nMPKineticsGround):
			ftComputerCheckTryChargeSpecialN(this_fp)

			match this_fp.fkind:
				nFTKindLink:
					if ftComputerCheckFindTarget(this_fp) != FALSE:
						if com.target_dist < 1500.0:
							ftComputerSetCommandWaitShort(this_fp, nFTComputerInputStickSmashLwButtonB)

				nFTKindNess:
					if syUtilsRandFloat() < 0.25:
						ftComputerSetCommandWaitShort(this_fp, nFTComputerInputStickSmashHiButtonB)

## 0x80138AA8
static func func_ovl3_80138AA8(this_fp, is_delay: int) -> int:
	var com: FTComputer = this_fp.computer
	var pos: Vector3
	var fkind: int
	var target_fp

	target_fp = com.target_user

	if _DISTANCE(this_fp.joints[nFTPartsJointTopN].translate.y, com.target_pos.y) < 400.0:
		if com.unk_ftcom_0x35 == 0:
			com.unk_ftcom_0x35 = _u8(_f2i(2.0 * (syUtilsRandFloat() * (FTCOMPUTER_LEVEL_MAX - this_fp.level))))

		if (syUtilsRandFloat() < ((this_fp.level - 1) / 9.0)) and (target_fp != null):
			if (_ftGetFKind(target_fp) == nFTKindNess) or (_ftGetFKind(target_fp) == nFTKindFox):
				return FALSE

		fkind = this_fp.passive_vars.kirby.copy_id if (this_fp.fkind == nFTKindKirby) else this_fp.fkind

		if fkind == nFTKindSamus:
			if (
				(this_fp.status_id == nFTSamusStatusSpecialNStart) or
				(this_fp.status_id == nFTSamusStatusSpecialAirNStart) or
				(this_fp.status_id == nFTSamusStatusSpecialNLoop) or
				(this_fp.status_id == nFTSamusStatusSpecialAirNEnd) or
				(this_fp.status_id == nFTKirbyStatusCopySamusSpecialNStart) or
				(this_fp.status_id == nFTKirbyStatusCopySamusSpecialAirNStart) or
				(this_fp.status_id == nFTKirbyStatusCopySamusSpecialNLoop) or
				(this_fp.status_id == nFTKirbyStatusCopySamusSpecialAirNEnd)
			):
				return FALSE

		if (
			(fkind == nFTKindLink) or
			(fkind == nFTKindMario) or
			(fkind == nFTKindFox) or
			(fkind == nFTKindSamus) or
			(fkind == nFTKindLuigi) or
			(fkind == nFTKindPikachu) or
			(fkind == nFTKindMMario)
		):
			if fkind == nFTKindLink:
				if com.target_dist < 1500.0:
					if syUtilsRandFloat() < 0.3:
						ftComputerSetCommandWaitShort(this_fp, nFTComputerInputStickSmashLwButtonB)
				# fallthrough into nFTKindMario / Fox / Samus / Luigi / Pikachu / MMario

			com.unk_ftcom_0x35 = _u8(com.unk_ftcom_0x35 + 1)

			if com.unk_ftcom_0x35 >= 5:
				ftComputerFollowObjectiveWalk(this_fp)
				return TRUE

			pos = this_fp.joints[nFTPartsJointTopN].translate
			pos.x = com.target_pos.x
			pos.y = com.target_pos.y

			if com.target_pos.x < this_fp.joints[nFTPartsJointTopN].translate.x:
				if Mpcollision.mpCollisionCheckRWallLineCollisionSame(this_fp.joints[nFTPartsJointTopN].translate, pos).ret != FALSE:
					return FALSE

				if Mpcollision.mpCollisionCheckFloorLineCollisionSame(this_fp.joints[nFTPartsJointTopN].translate, pos).ret != FALSE:
					return FALSE

				if Mpcollision.mpCollisionCheckCeilLineCollisionSame(this_fp.joints[nFTPartsJointTopN].translate, pos).ret != FALSE:
					return FALSE

			elif Mpcollision.mpCollisionCheckLWallLineCollisionSame(this_fp.joints[nFTPartsJointTopN].translate, pos).ret != FALSE:
				return FALSE

			elif Mpcollision.mpCollisionCheckFloorLineCollisionSame(this_fp.joints[nFTPartsJointTopN].translate, pos).ret != FALSE:
				return FALSE

			elif Mpcollision.mpCollisionCheckCeilLineCollisionSame(this_fp.joints[nFTPartsJointTopN].translate, pos).ret != FALSE:
				return FALSE

			if is_delay == FALSE:
				ftComputerSetCommandWaitLong(this_fp, nFTComputerInputStickSmashAutoXButtonB)
			else:
				ftComputerSetCommandWaitLong(this_fp, nFTComputerInputStickTiltAutoXNYD5SmashAutoXButtonB)

			return TRUE

	return FALSE

## 0x80138EE4
static func func_ovl3_80138EE4(fp) -> int:
	var com: FTComputer = fp.computer
	var fkind: int
	var random: float
	var edge_left_pos: Vector3
	var edge_right_pos: Vector3

	if fp.fkind == nFTKindGDonkey:
		return FALSE

	fkind = fp.passive_vars.kirby.copy_id if (fp.fkind == nFTKindKirby) else fp.fkind

	if fkind == nFTKindSamus:
		if (
			(fp.status_id == nFTSamusStatusSpecialNStart) or
			(fp.status_id == nFTSamusStatusSpecialAirNStart) or
			(fp.status_id == nFTSamusStatusSpecialNLoop) or
			(fp.status_id == nFTSamusStatusSpecialAirNEnd) or
			(fp.status_id == nFTKirbyStatusCopySamusSpecialNStart) or
			(fp.status_id == nFTKirbyStatusCopySamusSpecialAirNStart) or
			(fp.status_id == nFTKirbyStatusCopySamusSpecialNLoop) or
			(fp.status_id == nFTKirbyStatusCopySamusSpecialAirNEnd)
		):
			return FALSE

	# REGION_US
	if (fkind == nFTKindDonkey) or (fkind == nFTKindNDonkey) or (fkind == nFTKindGDonkey):
		if (
			(fp.status_id == nFTDonkeyStatusSpecialNStart) or
			(fp.status_id == nFTDonkeyStatusSpecialAirNStart) or
			(fp.status_id == nFTDonkeyStatusSpecialNLoop) or
			(fp.status_id == nFTDonkeyStatusSpecialAirNLoop) or
			(fp.status_id == nFTKirbyStatusCopyDonkeySpecialNStart) or
			(fp.status_id == nFTKirbyStatusCopyDonkeySpecialAirNStart) or
			(fp.status_id == nFTKirbyStatusCopyDonkeySpecialNLoop) or
			(fp.status_id == nFTKirbyStatusCopyDonkeySpecialAirNLoop) or
			(fp.status_id == nFTDonkeyStatusThrowFWait) or
			(fp.status_id == nFTDonkeyStatusThrowFWalkSlow) or
			(fp.status_id == nFTDonkeyStatusThrowFWalkMiddle) or
			(fp.status_id == nFTDonkeyStatusThrowFWalkFast) or
			(fp.status_id == nFTDonkeyStatusThrowFTurn)
		):
			return FALSE

	if com.ftcom_flags_0x4A_b1 != FALSE:
		if (_ftGetComTargetFighter(com).status_id == nFTCommonStatusCliffCatch) or (_ftGetComTargetFighter(com).status_id == nFTCommonStatusCliffWait):
			return FALSE

	random = syUtilsRandFloat()

	if (
		(fp.ga == nMPKineticsGround) and
		(
			(
				(com.target_dist < ((random * 450.0) + 350.0)) and
				(
					(
						(fp.level >= 4) and
						((syUtilsRandFloat() * (11 - fp.level)) < 1.0)
					) or
					(
						(fp.level >= 3) and
						(((com.target_pos.x - fp.joints[nFTPartsJointTopN].translate.x) * fp.lr) < 0.0)
					)
				)
			)
			or
			(
				(com.target_dist < 800.0) and
				(fp.level >= 7) and
				((syUtilsRandFloat() * (10 - fp.level)) < 1.0) and
				(((com.target_pos.x - fp.joints[nFTPartsJointTopN].translate.x) * _ftGetComTargetFighter(com).lr) < 0.0)
			)
		)
	):
		if fp.coll_data.floor_line_id >= 0:
			edge_left_pos = Mpcollision.mpCollisionGetFloorEdgeL(fp.coll_data.floor_line_id)
			edge_right_pos = Mpcollision.mpCollisionGetFloorEdgeR(fp.coll_data.floor_line_id)

			if com.target_pos.x < fp.joints[nFTPartsJointTopN].translate.x:
				if fp.joints[nFTPartsJointTopN].translate.x < (edge_left_pos.x + 500.0):
					return FALSE

			elif fp.joints[nFTPartsJointTopN].translate.x > (edge_right_pos.x - 500.0):
				return FALSE

		if com.target_pos.x < fp.joints[nFTPartsJointTopN].translate.x:
			ftComputerSetCommandWaitShort(fp, nFTComputerInputEscapeL)
		else:
			ftComputerSetCommandWaitShort(fp, nFTComputerInputEscapeR)

		return TRUE

	return FALSE

## 0x801392C8
static func ftComputerFollowObjectiveAttack(fp) -> void:
	var com: FTComputer = fp.computer
	var temp_v0: int = func_ovl3_8013837C(fp)
	var random: float
	var var_a1: int

	if temp_v0 != 0:
		if temp_v0 != -1:
			syUtilsRandFloat()
			syUtilsRandFloat()
			random = syUtilsRandFloat()

			if (
				((fp.joints[nFTPartsJointTopN].translate.x < com.target_pos.x) and (fp.lr == +1)) or
				((fp.joints[nFTPartsJointTopN].translate.x > com.target_pos.x) and (fp.lr == -1))
			):
				var_a1 = FALSE
			else:
				var_a1 = TRUE

			if com.target_dist < ((random * 300.0) + 1200.0):
				if func_ovl3_80138EE4(fp) != FALSE:
					com.unk_ftcom_0x35 = 0
					return

				if ftComputerCheckDetectTarget(fp, 0.0) != FALSE:
					com.unk_ftcom_0x20 = 0
					com.unk_ftcom_0x35 = 0
					return

				if _ftGetComTargetFighter(com).physics.vel_air.y > 30.0:
					if syUtilsRandFloat() < ((fp.level + 2) / 9.0):
						if (
							(_ftGetComTargetFighter(com).status_id == nFTCommonStatusDamageFlyHi) or
							(_ftGetComTargetFighter(com).status_id == nFTCommonStatusDamageFlyN) or
							(_ftGetComTargetFighter(com).status_id == nFTCommonStatusDamageFlyLw) or
							(_ftGetComTargetFighter(com).status_id == nFTCommonStatusDamageFlyTop) or
							(_ftGetComTargetFighter(com).status_id == nFTCommonStatusDamageFall) or
							(_ftGetComTargetFighter(com).status_id == nFTCommonStatusDamageFlyRoll)
						):
							ftComputerSetCommandImmediate(fp, nFTComputerInputMoveAutoStickTiltHiReleaseZ)
							com.walk_stop_wait = 0
							return

				if (_DISTANCE(com.target_pos.y, fp.joints[nFTPartsJointTopN].translate.y) > 1500.0) or (com.unk_ftcom_0x20 != 0):
					ftComputerFollowObjectiveWalk(fp)

					com.walk_stop_wait = 0

					if com.unk_ftcom_0x20 != 0:
						com.unk_ftcom_0x20 -= 1
				else:
					if syUtilsRandFloat() < 0.05:
						com.unk_ftcom_0x20 = _u16(_f2i((syUtilsRandFloat() * 60.0) + 30.0))

						ftComputerFollowObjectiveWalk(fp)

						com.walk_stop_wait = 0

						return

					func_ovl3_8013877C(fp)
			else:
				com.item_throw_wait = 0

				if func_ovl3_80138AA8(fp, var_a1) != FALSE:
					com.walk_stop_wait = 0
					return

				if (fp.star_hitstatus == nGMHitStatusInvincible) or ((fp.item_gobj != null) and (itGetStruct(fp.item_gobj).kind == nITKindHammer)):
					ftComputerFollowObjectiveWalk(fp)

					com.walk_stop_wait = 0

					return

				if (_DISTANCE(com.target_pos.y, fp.joints[nFTPartsJointTopN].translate.y) > 1500.0) or (com.unk_ftcom_0x20 != 0):
					ftComputerFollowObjectiveWalk(fp)

					com.walk_stop_wait = 0

					if com.unk_ftcom_0x20 != 0:
						com.unk_ftcom_0x20 -= 1
				else:
					if syUtilsRandFloat() < 0.05:
						com.unk_ftcom_0x20 = _u16(_f2i((syUtilsRandFloat() * 60.0) + 30.0))

						ftComputerFollowObjectiveWalk(fp)

						com.walk_stop_wait = 0

						return

					com.unk_ftcom_0x35 = 0

					func_ovl3_8013877C(fp)
	else:
		func_ovl3_8013877C(fp)

## 0x801397F4
static func func_ovl3_801397F4(fp) -> void:
	var com: FTComputer = fp.computer
	var temp_v0: int = func_ovl3_8013837C(fp)
	var random: float
	var var_a1: int

	if temp_v0 != 0:
		if temp_v0 != -1:
			syUtilsRandFloat()
			syUtilsRandFloat()
			random = syUtilsRandFloat()

			if (
				((fp.joints[nFTPartsJointTopN].translate.x < com.target_pos.x) and (fp.lr == +1)) or
				((fp.joints[nFTPartsJointTopN].translate.x > com.target_pos.x) and (fp.lr == -1))
			):
				var_a1 = FALSE
			else:
				var_a1 = TRUE

			if com.target_dist < ((random * 300.0) + 1200.0):
				if func_ovl3_80138EE4(fp) != FALSE:
					com.unk_ftcom_0x35 = 0
					return

				if ftComputerCheckDetectTarget(fp, 0.0) != FALSE:
					com.unk_ftcom_0x35 = 0
					return

				if _ftGetComTargetFighter(com).physics.vel_air.y > 30.0:
					if syUtilsRandFloat() < ((fp.level + 5) / 9.0):
						if (
							(_ftGetComTargetFighter(com).status_id == nFTCommonStatusDamageFlyHi) or
							(_ftGetComTargetFighter(com).status_id == nFTCommonStatusDamageFlyN) or
							(_ftGetComTargetFighter(com).status_id == nFTCommonStatusDamageFlyLw) or
							(_ftGetComTargetFighter(com).status_id == nFTCommonStatusDamageFlyTop) or
							(_ftGetComTargetFighter(com).status_id == nFTCommonStatusDamageFall) or
							(_ftGetComTargetFighter(com).status_id == nFTCommonStatusDamageFlyRoll)
						):
							ftComputerSetCommandImmediate(fp, nFTComputerInputMoveAutoStickTiltHiReleaseZ)
							com.walk_stop_wait = 0
							return

				ftComputerFollowObjectiveWalk(fp)
				com.walk_stop_wait = 0
			else:
				com.item_throw_wait = 0

				if func_ovl3_80138AA8(fp, var_a1) != FALSE:
					com.walk_stop_wait = 0

				elif (fp.star_hitstatus == nGMHitStatusInvincible) or ((fp.item_gobj != null) and (itGetStruct(fp.item_gobj).kind == nITKindHammer)):
					ftComputerFollowObjectiveWalk(fp)

					com.walk_stop_wait = 0
				else:
					com.unk_ftcom_0x35 = 0

					ftComputerFollowObjectiveWalk(fp)

					com.walk_stop_wait = 0
	else:
		func_ovl3_8013877C(fp)

## 0x80139A60
static func ftComputerFollowObjectiveAlly(fp) -> void:
	var com: FTComputer = fp.computer
	var temp_v0: int = func_ovl3_8013837C(fp)
	var random: float
	var var_a1: int

	if temp_v0 != 0:
		if temp_v0 != -1:
			syUtilsRandFloat()
			syUtilsRandFloat()
			random = syUtilsRandFloat()

			if (
				((fp.joints[nFTPartsJointTopN].translate.x < com.target_pos.x) and (fp.lr == +1)) or
				((fp.joints[nFTPartsJointTopN].translate.x > com.target_pos.x) and (fp.lr == -1))
			):
				var_a1 = FALSE
			else:
				var_a1 = TRUE

			if com.target_dist < ((random * 300.0) + 1200.0):
				if func_ovl3_80138EE4(fp) != FALSE:
					com.unk_ftcom_0x35 = 0
					return

				if ftComputerCheckDetectTarget(fp, -0.5) != FALSE:
					com.unk_ftcom_0x35 = 0
					return

				func_ovl3_8013877C(fp)
				return

			com.item_throw_wait = 0

			if func_ovl3_80138AA8(fp, var_a1) != FALSE:
				com.walk_stop_wait = 0
				return

			if (fp.star_hitstatus == nGMHitStatusInvincible) or ((fp.item_gobj != null) and (itGetStruct(fp.item_gobj).kind == nITKindHammer)):
				ftComputerFollowObjectiveWalk(fp)

				com.walk_stop_wait = 0
				return

			if (_DISTANCE(com.target_pos.y, fp.joints[nFTPartsJointTopN].translate.y) > 1500.0) or (com.unk_ftcom_0x20 != 0):
				ftComputerFollowObjectiveWalk(fp)

				com.walk_stop_wait = 0

				if com.unk_ftcom_0x20 != 0:
					com.unk_ftcom_0x20 -= 1
			else:
				if syUtilsRandFloat() < 0.01:
					com.unk_ftcom_0x20 = _u16(_f2i((syUtilsRandFloat() * 60.0) + 30.0))

					ftComputerFollowObjectiveWalk(fp)

					com.walk_stop_wait = 0
					return

				com.unk_ftcom_0x35 = 0
				func_ovl3_8013877C(fp)
	else:
		func_ovl3_8013877C(fp)

## 0x80139D6C
static func ftComputerFollowObjectivePatrol(fp) -> void:
	var com: FTComputer = fp.computer
	var temp_v0: int = func_ovl3_8013837C(fp)
	var random: float
	var var_a1: int

	if temp_v0 != 0:
		if temp_v0 != -1:
			syUtilsRandFloat()
			syUtilsRandFloat()
			random = syUtilsRandFloat()

			if (
				((fp.joints[nFTPartsJointTopN].translate.x < com.target_pos.x) and (fp.lr == +1)) or
				((fp.joints[nFTPartsJointTopN].translate.x > com.target_pos.x) and (fp.lr == -1))
			):
				var_a1 = FALSE
			else:
				var_a1 = TRUE

			if com.target_dist < ((random * 300.0) + 1200.0):
				if func_ovl3_80138EE4(fp) != FALSE:
					com.unk_ftcom_0x35 = 0
					return

				if ftComputerCheckDetectTarget(fp, 2.0) != FALSE:
					com.unk_ftcom_0x20 = 0
					com.unk_ftcom_0x35 = 0
					return

				if _ftGetComTargetFighter(com).physics.vel_air.y > 30.0:
					if syUtilsRandFloat() < ((fp.level + 2) / 9.0):
						if (
							(_ftGetComTargetFighter(com).status_id == nFTCommonStatusDamageFlyHi) or
							(_ftGetComTargetFighter(com).status_id == nFTCommonStatusDamageFlyN) or
							(_ftGetComTargetFighter(com).status_id == nFTCommonStatusDamageFlyLw) or
							(_ftGetComTargetFighter(com).status_id == nFTCommonStatusDamageFlyTop) or
							(_ftGetComTargetFighter(com).status_id == nFTCommonStatusDamageFall) or
							(_ftGetComTargetFighter(com).status_id == nFTCommonStatusDamageFlyRoll)
						):
							ftComputerSetCommandImmediate(fp, nFTComputerInputMoveAutoStickTiltHiReleaseZ)
							com.walk_stop_wait = 0
							return

				if (_DISTANCE(com.target_pos.y, fp.joints[nFTPartsJointTopN].translate.y) > 1500.0) or (com.unk_ftcom_0x20 != 0):
					ftComputerFollowObjectiveWalk(fp)

					com.walk_stop_wait = 0

					if com.unk_ftcom_0x20 != 0:
						com.unk_ftcom_0x20 -= 1
				else:
					if syUtilsRandFloat() < 0.05:
						com.unk_ftcom_0x20 = _u16(_f2i((syUtilsRandFloat() * 60.0) + 15.0))

						ftComputerFollowObjectiveWalk(fp)

						com.walk_stop_wait = 0
						return
					else:
						func_ovl3_8013877C(fp)
			else:
				com.item_throw_wait = 0

				if func_ovl3_80138AA8(fp, var_a1) != FALSE:
					com.walk_stop_wait = 0
					return

				if (fp.star_hitstatus == nGMHitStatusInvincible) or ((fp.item_gobj != null) and (itGetStruct(fp.item_gobj).kind == nITKindHammer)):
					ftComputerFollowObjectiveWalk(fp)

					com.walk_stop_wait = 0
					return

				if (_DISTANCE(com.target_pos.y, fp.joints[nFTPartsJointTopN].translate.y) > 1500.0) or (com.unk_ftcom_0x20 != 0):
					ftComputerFollowObjectiveWalk(fp)

					com.walk_stop_wait = 0

					if com.unk_ftcom_0x20 != 0:
						com.unk_ftcom_0x20 -= 1
				else:
					if syUtilsRandFloat() < 0.05:
						com.unk_ftcom_0x20 = _u16(_f2i((syUtilsRandFloat() * 60.0) + 30.0))

						ftComputerFollowObjectiveWalk(fp)

						com.walk_stop_wait = 0
						return

					com.unk_ftcom_0x35 = 0
					func_ovl3_8013877C(fp)
	else:
		func_ovl3_8013877C(fp)

## 0x8013A298
static func ftComputerFollowObjectiveRush(fp) -> void:
	var com: FTComputer = fp.computer
	var random: float
	var var_a1: int

	if ftComputerCheckFindTarget(fp) != FALSE:
		syUtilsRandFloat()
		random = syUtilsRandFloat()

		if (
			((fp.joints[nFTPartsJointTopN].translate.x < com.target_pos.x) and (fp.lr == +1)) or
			((fp.joints[nFTPartsJointTopN].translate.x > com.target_pos.x) and (fp.lr == -1))
		):
			var_a1 = FALSE
		else:
			var_a1 = TRUE

		if com.target_dist < ((random * 300.0) + 1200.0):
			if ftComputerCheckDetectTarget(fp, 0.0) != FALSE:
				com.walk_stop_wait = 0
			else:
				ftComputerFollowObjectiveWalk(fp)
				com.walk_stop_wait = 0

		elif TRUE:
			ftComputerFollowObjectiveWalk(fp)
			com.walk_stop_wait = 0
	else:
		func_ovl3_8013877C(fp)

## 0x8013A38C
static func ftComputerProcessObjective(fp) -> void:
	var com: FTComputer = fp.computer

	if com.proc_com.call(fp.fighter_gobj) != FALSE:
		match com.objective:
			nFTComputerObjectiveStand:
				com.input_wait = 1
				com.p_command = dFTComputerPlayerInputScripts[nFTComputerInputStickN]
				com.p_command_index = 0

			nFTComputerObjectiveWalk:
				ftComputerFollowObjectiveWalk(fp)

			nFTComputerObjectiveAttack:
				ftComputerFollowObjectiveAttack(fp)

			nFTComputerObjectiveEvade:
				ftComputerFollowObjectiveEvade(fp)

			nFTComputerObjectiveRecover:
				ftComputerFollowObjectiveRecover(fp)

			nFTComputerObjectiveTrackItem:
				ftComputerFollowObjectiveTrackItem(fp)

			nFTComputerObjectiveUseItem:
				ftComputerFollowObjectiveUseItem(fp)

			nFTComputerObjectiveCounterAttack:
				ftComputerFollowObjectiveCounterAttack(fp)

			nFTComputerObjectiveUnknown1:
				func_ovl3_801397F4(fp)

			nFTComputerObjectiveAlly:
				ftComputerFollowObjectiveAlly(fp)

			nFTComputerObjectivePatrol:
				ftComputerFollowObjectivePatrol(fp)

			nFTComputerObjectiveRush:
				ftComputerFollowObjectiveRush(fp)

## 0x8013A4AC
static func ftComputerProcessBehavior(fp) -> void:
	var com: FTComputer = fp.computer

	match com.behavior:
		nFTComputerBehaviorDefault:
			com.proc_com = Callable(Ftcomputer, &"ftComputerProcDefault")
			com.objective_base = nFTComputerObjectiveAttack

		nFTComputerBehaviorUnk1:
			com.proc_com = Callable(Ftcomputer, &"ftComputerProcDefault")
			com.objective_base = nFTComputerObjectiveEvade

		nFTComputerBehaviorUnk2:
			com.proc_com = Callable(Ftcomputer, &"ftComputerProcDefault")
			com.objective_base = nFTComputerObjectiveUnknown1

		nFTComputerBehaviorAlly:
			com.proc_com = Callable(Ftcomputer, &"ftComputerProcDefault")
			com.objective_base = nFTComputerObjectiveAlly

		nFTComputerBehaviorCaptain:
			com.proc_com = Callable(Ftcomputer, &"ftComputerProcDefault")
			com.objective_base = nFTComputerObjectivePatrol

		nFTComputerBehaviorUnk3:
			com.proc_com = Callable(Ftcomputer, &"ftComputerProcDefault")
			com.objective_base = nFTComputerObjectiveAttack

		nFTComputerBehaviorYoshiTeam:
			com.proc_com = Callable(Ftcomputer, &"ftComputerProcDefault")
			com.objective_base = nFTComputerObjectiveAlly

		nFTComputerBehaviorKirbyTeam:
			com.proc_com = Callable(Ftcomputer, &"ftComputerProcDefault")
			com.objective_base = nFTComputerObjectivePatrol

		nFTComputerBehaviorPolyTeam:
			com.proc_com = Callable(Ftcomputer, &"ftComputerProcDefault")
			com.objective_base = nFTComputerObjectiveAttack

		nFTComputerBehaviorBonus3:
			com.proc_com = Callable(Ftcomputer, &"ftComputerProcDefault")
			com.objective_base = nFTComputerObjectiveRush

		nFTComputerBehaviorStand:
			com.proc_com = Callable(Ftcomputer, &"ftComputerProcStand")

		nFTComputerBehaviorWalk:
			com.proc_com = Callable(Ftcomputer, &"ftComputerProcWalk")

		nFTComputerBehaviorEvade:
			com.proc_com = Callable(Ftcomputer, &"ftComputerProcEvade")

		nFTComputerBehaviorJump:
			com.proc_com = Callable(Ftcomputer, &"ftComputerProcJump")

		nFTComputerBehaviorUnk5:
			com.proc_com = Callable(Ftcomputer, &"func_ovl3_80137E70")

## 0x8013A63C
static func ftComputerProcessTrait(fp) -> void:
	var com: FTComputer = fp.computer

	match com.trait_:
		nFTComputerTraitDefault:
			if com.behavior_change_wait == 0:
				com.behavior_change_wait = _u16(_f2i((syUtilsRandFloat() * 900.0) + 900.0))

				match syUtilsRandUShort() & 3:
					0:
						com.behavior = nFTComputerBehaviorDefault

					1:
						com.behavior = nFTComputerBehaviorUnk2

					2:
						com.behavior = nFTComputerBehaviorAlly
						com.behavior_change_wait >>= 2

					3:
						com.behavior = nFTComputerBehaviorCaptain

		nFTComputerTraitLink:
			# REGION_US
			if (fp.percent_damage >= 14) or (com.behavior_change_wait == 0):
				com.behavior = nFTComputerBehaviorDefault
			else:
				com.behavior = nFTComputerBehaviorStand

		nFTComputerTraitYoshiTeam:
			com.behavior = nFTComputerBehaviorYoshiTeam

		nFTComputerTraitKirbyTeam:
			com.behavior = nFTComputerBehaviorKirbyTeam

		nFTComputerTraitPolyTeam:
			com.behavior = nFTComputerBehaviorPolyTeam

		nFTComputerTraitMarioBros:
			if fp.fkind == nFTKindMario:
				com.behavior = nFTComputerBehaviorDefault
			else:
				com.behavior = nFTComputerBehaviorAlly

		nFTComputerTraitGDonkey:
			com.behavior = nFTComputerBehaviorDefault

		nFTComputerTraitUnk1:
			com.behavior = nFTComputerBehaviorUnk2

		nFTComputerTraitBonus3:
			com.behavior = nFTComputerBehaviorBonus3

		nFTComputerTraitAlly:
			com.behavior = nFTComputerBehaviorAlly

		nFTComputerTraitNone:
			pass

## 0x8013A834
static func ftComputerProcessAll(fighter_gobj) -> void:
	var fp: Fighter = ftGetStruct(fighter_gobj)
	var com: FTComputer = fp.computer

	if fp.fkind != nFTKindBoss:
		if com.behavior_change_wait != 0:
			com.behavior_change_wait -= 1

		if com.input_wait == 0:
			ftComputerProcessTrait(fp)
			ftComputerProcessBehavior(fp)
			ftComputerProcessObjective(fp)

		ftComputerUpdateInputs(fp)

## 0x8013A8A8
static func ftComputerSetupAll(fighter_gobj) -> void:
	var fp: Fighter = ftGetStruct(fighter_gobj)
	var com: FTComputer = fp.computer
	var dash_speed: float
	var jump: float
	var edge_left_nearest: float
	var edge_right_nearest: float
	var line_group
	var line_ids                        # C: u16 *line_ids
	var edge_pos: Vector3
	var i: int

	_bzero_computer(com)                # bzero(com, sizeof(*com))

	if fp.fkind != nFTKindBoss:
		com.target_pos.x = fp.joints[nFTPartsJointTopN].translate.x
		com.origin_pos.x = com.target_pos.x

		if fp.ga == nMPKineticsGround:
			com.target_pos.y = fp.joints[nFTPartsJointTopN].translate.y
			com.origin_pos.y = com.target_pos.y
		else:
			com.target_pos.y = fp.joints[nFTPartsJointTopN].translate.y + fp.coll_data.floor_dist
			com.origin_pos.y = com.target_pos.y

		com.floor_line_id = fp.coll_data.floor_line_id

		com.proc_com = Callable()

		com.trait_ = 0
		com.behavior = 0

		# REGION_US
		i = 1440 - (fp.level * 240)

		if i < 0:
			i = 0

		com.behavior_change_wait = _u16(i)

		com.dash_predict = 0.0

		dash_speed = fp.attr.dash_speed

		i = 0

		while i < fp.attr.dash_to_run:
			if i >= 7:
				dash_speed -= fp.attr.dash_decel

			com.dash_predict += dash_speed
			i += 1

		com.jump_predict = -200.0

		jump = (fp.attr.jump_height_mul * float(F_CONTROLLER_RANGE_MAX)) + fp.attr.jump_height_base

		while jump > 0.0:
			jump -= fp.attr.gravity

			com.jump_predict += jump

		edge_left_nearest = 2000.0
		edge_right_nearest = -2000.0

		com.cliff_right_pos.y = 9999.9
		com.cliff_left_pos.y = com.cliff_right_pos.y

		line_group = _gMPCollisionLineGroups()[nMPLineKindFloor]
		line_ids = line_group.line_id

		i = 0

		while i < line_group.line_count:
			if (Mpcollision.mpCollisionCheckExistLineID(line_ids[i]) != FALSE) and (Mpcollision.mpCollisionCheckExistPlatformLineID(line_ids[i]) == FALSE):
				edge_pos = Mpcollision.mpCollisionGetFloorEdgeL(line_ids[i])

				if edge_left_nearest > edge_pos.x:
					edge_left_nearest = edge_pos.x

					if com.cliff_left_pos.y > edge_pos.y:
						com.cliff_left_pos.x = edge_pos.x
						com.cliff_left_pos.y = edge_pos.y

				elif ((edge_pos.x - _gMPCollisionBounds().current.left) < 500.0) and (com.cliff_left_pos.y > edge_pos.y):
					com.cliff_left_pos.x = edge_pos.x
					com.cliff_left_pos.y = edge_pos.y

				edge_pos = Mpcollision.mpCollisionGetFloorEdgeR(line_ids[i])

				if edge_right_nearest < edge_pos.x:
					edge_right_nearest = edge_pos.x

					if com.cliff_right_pos.y > edge_pos.y:
						com.cliff_right_pos.x = edge_pos.x
						com.cliff_right_pos.y = edge_pos.y

				elif ((_gMPCollisionBounds().current.right - edge_pos.x) < 500.0) and (com.cliff_right_pos.y > edge_pos.y):
					com.cliff_right_pos.x = edge_pos.x
					com.cliff_right_pos.y = edge_pos.y
			i += 1
	else:
		return

## 0x8013AC00
static func ftComputerSetFighterDamageDetectSize(fighter_gobj) -> void:
	var fp: Fighter = ftGetStruct(fighter_gobj)
	var damage_coll: FTDamageColl
	var parts: FtParts
	var joint_world_pos: Vector3
	var nearest_left: float
	var nearest_bottom: float
	var nearest_right: float
	var nearest_top: float
	var joint: DObj

	nearest_right = fp.joints[nFTPartsJointTopN].translate.x
	nearest_top = fp.joints[nFTPartsJointTopN].translate.y

	nearest_left = nearest_right
	nearest_bottom = nearest_top

	for i in fp.damage_colls.size():          # ARRAY_COUNT(fp->damage_colls)
		damage_coll = fp.damage_colls[i]

		if damage_coll.hitstatus == nGMHitStatusNormal:
			joint = damage_coll.joint
			parts = joint.user_data             # ftGetParts(joint)

			if parts.unk_dobjtrans_0x5 == 0:
				Gmcollision.func_ovl2_800EDBA4(joint)

			for j in 8:
				joint_world_pos.x = (damage_coll.offset.x + damage_coll.size.x) if ((j & 1) != 0) else (damage_coll.offset.x - damage_coll.size.x)
				joint_world_pos.y = (damage_coll.offset.y + damage_coll.size.y) if ((j & 2) != 0) else (damage_coll.offset.y - damage_coll.size.y)
				joint_world_pos.z = (damage_coll.offset.z + damage_coll.size.z) if ((j & 4) != 0) else (damage_coll.offset.z - damage_coll.size.z)

				joint_world_pos = Gmcollision.gmCollisionGetWorldPosition(parts.mtx_translate, joint_world_pos)

				if nearest_left > joint_world_pos.x:
					nearest_left = joint_world_pos.x

				if nearest_right < joint_world_pos.x:
					nearest_right = joint_world_pos.x

				if nearest_bottom > joint_world_pos.y:
					nearest_bottom = joint_world_pos.y

				if nearest_top < joint_world_pos.y:
					nearest_top = joint_world_pos.y

	fp.damage_coll_size.x = (nearest_right - nearest_left) * 0.55
	fp.damage_coll_size.y = (nearest_top - nearest_bottom) * 0.55
