## 1:1 port of src/gm/gmcollision.c (ssb-decomp-re).
##
## Contents:
##   - per-joint matrix cache of fighter joints (FtParts): local matrix (unk_dobjtrans_0x10),
##     world matrix (mtx_translate), inverse world matrix (unk_dobjtrans_0x9C) and world scale
##     (vec_scale), with the lazily-evaluated validity flags unk_dobjtrans_0x5 (world),
##     unk_dobjtrans_0x6 (scale), unk_dobjtrans_0x7 (inverse) and transform_update_mode (local);
##   - hitbox (sphere / swept capsule) vs hurtbox (box), shield, reflector/absorb and
##     hitbox-vs-hitbox tests for fighters, weapons and items;
##   - impact-position helpers used for hit effects.
##
## Matrix layout: Mtx44f is a PackedFloat32Array of 12 floats, row-major 4x3:
##   [m00,m01,m02, m10,m11,m12, m20,m21,m22, m30,m31,m32]   (C mtx[i][j] -> index i*3+j;
## column 3 is never read by this file). PackedFloat32Arrays are shared by reference in
## GDScript, so functions write matrices in place exactly like C; functions whose only
## written parameter is a matrix ALSO return that same array (so both
## `f(.., m)` and `m = f(.., m)` call styles work).
##
## Pointer out-parameters follow PORTING.md (vectors are values in GDScript):
##   gmCollisionGetWorldPosition(mtx, vec)                -> Vector3 (transformed vec)
##   gmCollisionGetFighterPartsWorldPosition(dobj, vec)   -> Vector3
##   func_ovl2_800EE018(dobj, vec)                        -> Vector3
##   func_ovl2_800EDA0C(mtx)                              -> Vector3 rotate (pure output)
##   func_ovl2_800EDB88(mtx)                              -> Vector3 vec (pure output)
##   func_ovl2_800EE050(..., arg3, mtx, p_scale)          -> {"arg3", "p_scale", "mtx"}
##   gmCollisionTestSphere(..., p_angle, argA)            -> {"ret", "p_angle", "argA"}
##   gmCollisionCheckFighterAttackShieldCollide(.., p_angle = 0.0)            -> {"ret", "p_angle"}
##   gmCollisionCheck{Weapon,Item}AttackShieldCollide(.., p_angle = 0.0, vec = ZERO) -> {"ret", "p_angle", "vec"}
##   gmCollisionGet*Position(<inputs without dst>)        -> Vector3 dst (pure output)
## Values that C stores in f32 variables and that are compared for equality or handed to
## other modules (p_angle, p_scale) are rounded to single precision with _f32().
class_name Gmcollision
extends Port

## Exact f32 values of C's F_CLC_DTOR32(<literal>) = (float)((x * 3.1415927F) / 180.0F).
## (Port.F_CLC_DTOR32 multiplies by a rounded factor and differs in the last bits; the
## p_angle == F_CLC_DTOR32(180.0F) comparison below needs the exact C value, which is also
## the f32 value of M_PI_F returned by syUtilsArcCos(-1).)
const F_CLC_DTOR32_180 := 3.1415927410125732    # F_CLC_DTOR32(180.0F)
const F_CLC_DTOR32_90 := 1.5707963705062866     # F_CLC_DTOR32(90.0F)
const F_CLC_DTOR32_N90 := -1.5707963705062866   # F_CLC_DTOR32(-90.0F)

## Round to the nearest single-precision float (value stored into a C f32 variable).
static func _f32(x: float) -> float:
	return Vector2(x, 0.0).x

## C: while (TRUE) { syDebugPrintf(msg); scManagerRunPrintGObjStatus(); }
## The N64 game hangs in a debug-print loop. The port prints the message, reports an error and
## continues (scManagerRunPrintGObjStatus is in src/sc/scmanager.c, which has no GDScript module).
static func _gmCollisionFatal(msg: String) -> void:
	Debug.syDebugPrintf(msg)
	push_error(msg)

# // // // // // // // // // // // //
# //                               //
# //           FUNCTIONS           //
# //                               //
# // // // // // // // // // // // //

## 0x800ECD80
static func gmCollisionCopyMatrix(dst: PackedFloat32Array, src: PackedFloat32Array) -> PackedFloat32Array:
	dst[0] = src[0]       # dst[0][0] = src[0][0]
	dst[3] = src[3]       # dst[1][0] = src[1][0]
	dst[6] = src[6]       # dst[2][0] = src[2][0]
	dst[9] = src[9]       # dst[3][0] = src[3][0]
	dst[1] = src[1]       # dst[0][1] = src[0][1]
	dst[4] = src[4]       # dst[1][1] = src[1][1]
	dst[7] = src[7]       # dst[2][1] = src[2][1]
	dst[10] = src[10]     # dst[3][1] = src[3][1]
	dst[2] = src[2]       # dst[0][2] = src[0][2]
	dst[5] = src[5]       # dst[1][2] = src[1][2]
	dst[8] = src[8]       # dst[2][2] = src[2][2]
	dst[11] = src[11]     # dst[3][2] = src[3][2]
	return dst

## 0x800ECDE4
static func gmCollisionTransformMatrixAll(dobj: DObj, parts: FtParts, mtx: PackedFloat32Array) -> PackedFloat32Array:
	var translate: Vector3 = dobj.translate
	var rotate: Vector3 = dobj.rotate
	var scale: Vector3 = dobj.scale
	var sinx: float
	var siny: float
	var sinz: float
	var cosx: float
	var cosy: float
	var cosz: float

	sinx = lbCommonSin(rotate.x)
	cosx = lbCommonCos(rotate.x)

	siny = lbCommonSin(rotate.y)
	cosy = lbCommonCos(rotate.y)

	sinz = lbCommonSin(rotate.z)
	cosz = lbCommonCos(rotate.z)

	mtx[0] = cosy * cosz                                     # mtx[0][0]
	mtx[1] = cosy * sinz                                     # mtx[0][1]
	mtx[2] = -siny                                           # mtx[0][2]

	mtx[3] = (sinx * siny * cosz) - (cosx * sinz)            # mtx[1][0]
	mtx[4] = (sinx * siny * sinz) + (cosx * cosz)            # mtx[1][1]
	mtx[5] = sinx * cosy                                     # mtx[1][2]

	mtx[6] = (cosx * siny * cosz) + (sinx * sinz)            # mtx[2][0]
	mtx[7] = (cosx * siny * sinz) - (sinx * cosz)            # mtx[2][1]
	mtx[8] = cosx * cosy                                     # mtx[2][2]

	if scale.x != 1.0:
		mtx[0] *= scale.x
		mtx[1] *= scale.x
		mtx[2] *= scale.x
	if scale.y != 1.0:
		mtx[3] *= scale.y
		mtx[4] *= scale.y
		mtx[5] *= scale.y
	if scale.z != 1.0:
		mtx[6] *= scale.z
		mtx[7] *= scale.z
		mtx[8] *= scale.z
	mtx[9] = translate.x                                     # mtx[3][0]
	mtx[10] = translate.y                                    # mtx[3][1]
	mtx[11] = translate.z                                    # mtx[3][2]
	return mtx

## 0x800ECFF4
## scale_mul: Vector3 or null (C: Vec3f* that may be NULL). Writes parts.vec_scale (C: nscale).
static func gmCollisionSetMatrixNcs(dobj: DObj, parts: FtParts, mtx: PackedFloat32Array, scale_mul = null) -> PackedFloat32Array:
	var translate: Vector3 = dobj.translate
	var rotate: Vector3 = dobj.rotate
	var scale: Vector3 = dobj.scale
	var sinx: float
	var siny: float
	var sinz: float
	var cosx: float
	var cosy: float
	var cosz: float
	var invx: float
	var invy: float
	var invz: float

	if scale_mul != null:
		parts.vec_scale.x = scale_mul.x * scale.x
		parts.vec_scale.y = scale_mul.y * scale.y
		parts.vec_scale.z = scale_mul.z * scale.z
	else:
		parts.vec_scale = scale

	sinx = lbCommonSin(rotate.x)
	cosx = lbCommonCos(rotate.x)

	siny = lbCommonSin(rotate.y)
	cosy = lbCommonCos(rotate.y)

	sinz = lbCommonSin(rotate.z)
	cosz = lbCommonCos(rotate.z)

	mtx[0] = cosy * cosz                                     # mtx[0][0]
	mtx[1] = cosy * sinz                                     # mtx[0][1]
	mtx[2] = -siny                                           # mtx[0][2]

	mtx[3] = (sinx * siny * cosz) - (cosx * sinz)            # mtx[1][0]
	mtx[4] = (sinx * siny * sinz) + (cosx * cosz)            # mtx[1][1]
	mtx[5] = sinx * cosy                                     # mtx[1][2]

	mtx[6] = (cosx * siny * cosz) + (sinx * sinz)            # mtx[2][0]
	mtx[7] = (cosx * siny * sinz) - (sinx * cosz)            # mtx[2][1]
	mtx[8] = cosx * cosy                                     # mtx[2][2]

	var nscale: Vector3 = parts.vec_scale

	if nscale.x != 1.0:
		mtx[0] *= nscale.x
		mtx[1] *= nscale.x
		mtx[2] *= nscale.x
	if nscale.y != 1.0:
		mtx[3] *= nscale.y
		mtx[4] *= nscale.y
		mtx[5] *= nscale.y
	if nscale.z != 1.0:
		mtx[6] *= nscale.z
		mtx[7] *= nscale.z
		mtx[8] *= nscale.z
	if scale_mul != null:
		if scale_mul.x != 1.0:
			if scale_mul.x == 0.0:
				_gmCollisionFatal("zero div x in gcSetMatrixNcs()\n")
			invx = _f32(1.0 / scale_mul.x)

			mtx[0] *= invx          # mtx[0][0]
			mtx[3] *= invx          # mtx[1][0]
			mtx[6] *= invx          # mtx[2][0]
		if scale_mul.y != 1.0:
			if scale_mul.y == 0.0:
				_gmCollisionFatal("zero div y in gcSetMatrixNcs()\n")
			invy = _f32(1.0 / scale_mul.y)

			mtx[1] *= invy          # mtx[0][1]
			mtx[4] *= invy          # mtx[1][1]
			mtx[7] *= invy          # mtx[2][1]
		if scale_mul.z != 1.0:
			if scale_mul.z == 0.0:
				_gmCollisionFatal("zero div z in gcSetMatrixNcs()\n")
			invz = _f32(1.0 / scale_mul.z)

			mtx[2] *= invz          # mtx[0][2]
			mtx[5] *= invz          # mtx[1][2]
			mtx[8] *= invz          # mtx[2][2]
	mtx[9] = translate.x                                     # mtx[3][0]
	mtx[10] = translate.y                                    # mtx[3][1]
	mtx[11] = translate.z                                    # mtx[3][2]
	return mtx

## 0x800ED3C0
## C: void (Mtx44f mtx, Vec3f *vec) - vec is transformed in place -> returns the new vec.
static func gmCollisionGetWorldPosition(mtx: PackedFloat32Array, vec: Vector3) -> Vector3:
	var product := Vector3()

	product.x = ((mtx[0] * vec.x) + (mtx[3] * vec.y) + (mtx[6] * vec.z)) + mtx[9]
	product.y = ((mtx[1] * vec.x) + (mtx[4] * vec.y) + (mtx[7] * vec.z)) + mtx[10]
	product.z = ((mtx[2] * vec.x) + (mtx[5] * vec.y) + (mtx[8] * vec.z)) + mtx[11]

	return product

## 0x800ED490 - dst = rhs * lhs (row-vector matrices: world(child) = local(child) x world(parent))
static func func_ovl2_800ED490(dst: PackedFloat32Array, lhs: PackedFloat32Array, rhs: PackedFloat32Array) -> PackedFloat32Array:
	dst[0] = (lhs[0] * rhs[0]) + (lhs[3] * rhs[1]) + (lhs[6] * rhs[2])      # dst[0][0]
	dst[1] = (lhs[1] * rhs[0]) + (lhs[4] * rhs[1]) + (lhs[7] * rhs[2])      # dst[0][1]
	dst[2] = (lhs[2] * rhs[0]) + (lhs[5] * rhs[1]) + (lhs[8] * rhs[2])      # dst[0][2]

	dst[3] = (lhs[0] * rhs[3]) + (lhs[3] * rhs[4]) + (lhs[6] * rhs[5])      # dst[1][0]
	dst[4] = (lhs[1] * rhs[3]) + (lhs[4] * rhs[4]) + (lhs[7] * rhs[5])      # dst[1][1]
	dst[5] = (lhs[2] * rhs[3]) + (lhs[5] * rhs[4]) + (lhs[8] * rhs[5])      # dst[1][2]

	dst[6] = (lhs[0] * rhs[6]) + (lhs[3] * rhs[7]) + (lhs[6] * rhs[8])      # dst[2][0]
	dst[7] = (lhs[1] * rhs[6]) + (lhs[4] * rhs[7]) + (lhs[7] * rhs[8])      # dst[2][1]
	dst[8] = (lhs[2] * rhs[6]) + (lhs[5] * rhs[7]) + (lhs[8] * rhs[8])      # dst[2][2]

	dst[9] = ((lhs[0] * rhs[9]) + (lhs[3] * rhs[10]) + (lhs[6] * rhs[11])) + lhs[9]      # dst[3][0]
	dst[10] = ((lhs[1] * rhs[9]) + (lhs[4] * rhs[10]) + (lhs[7] * rhs[11])) + lhs[10]    # dst[3][1]
	dst[11] = ((lhs[2] * rhs[9]) + (lhs[5] * rhs[10]) + (lhs[8] * rhs[11])) + lhs[11]    # dst[3][2]
	return dst

## 0x800ED6EC - inverse of an affine 4x3 matrix (cofactors, written into dst in the C order)
static func gmCollisionSetInvertMatrix(dst: PackedFloat32Array, src: PackedFloat32Array) -> PackedFloat32Array:
	var scale: float

	dst[0] = (src[4] * src[8]) - (src[5] * src[7])                          # dst[0][0]
	dst[3] = (src[3] * src[8]) - (src[5] * src[6])                          # dst[1][0]
	dst[6] = (src[3] * src[7]) - (src[4] * src[6])                          # dst[2][0]
	dst[9] = (src[9] * dst[0]) - (src[10] * dst[3]) + (src[11] * dst[6])    # dst[3][0]

	dst[1] = (src[1] * src[8]) - (src[2] * src[7])                          # dst[0][1]
	dst[4] = (src[0] * src[8]) - (src[2] * src[6])                          # dst[1][1]
	dst[7] = (src[0] * src[7]) - (src[1] * src[6])                          # dst[2][1]
	dst[10] = (src[9] * dst[1]) - (src[10] * dst[4]) + (src[11] * dst[7])   # dst[3][1]

	dst[2] = (src[1] * src[5]) - (src[2] * src[4])                          # dst[0][2]
	dst[5] = (src[0] * src[5]) - (src[2] * src[3])                          # dst[1][2]
	dst[8] = (src[0] * src[4]) - (src[1] * src[3])                          # dst[2][2]
	dst[11] = (src[9] * dst[2]) - (src[10] * dst[5]) + (src[11] * dst[8])   # dst[3][2]

	scale = _f32((src[0] * dst[0]) - (src[1] * dst[3]) + (src[2] * dst[6]))

	dst[3] = -dst[3]        # dst[1][0]
	dst[9] = -dst[9]        # dst[3][0]
	dst[1] = -dst[1]        # dst[0][1]
	dst[7] = -dst[7]        # dst[2][1]
	dst[5] = -dst[5]        # dst[1][2]
	dst[11] = -dst[11]      # dst[3][2]

	if scale == 0.0:
		_gmCollisionFatal("zero div in gcSetInvMatrix()\n")
	scale = _f32(1.0 / scale)

	dst[0] *= scale         # dst[0][0]
	dst[3] *= scale         # dst[1][0]
	dst[6] *= scale         # dst[2][0]
	dst[9] *= scale         # dst[3][0]
	dst[1] *= scale         # dst[0][1]
	dst[4] *= scale         # dst[1][1]
	dst[7] *= scale         # dst[2][1]
	dst[10] *= scale        # dst[3][1]
	dst[2] *= scale         # dst[0][2]
	dst[5] *= scale         # dst[1][2]
	dst[8] *= scale         # dst[2][2]
	dst[11] *= scale        # dst[3][2]
	return dst

## 0x800EDA0C - extract Euler rotation from a matrix.
## C: void (Mtx44f mtx, Vec3f *rotate) - rotate is a pure output -> returns rotate.
static func func_ovl2_800EDA0C(mtx: PackedFloat32Array) -> Vector3:
	var rotate := Vector3()
	var dst := PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])   # Mtx44f dst (rows 0..2 used)
	var scale: float
	var i: int

	# i < 3
	i = 0
	while i < 3:
		scale = _f32(sqrtf(SQUARE(mtx[i * 3 + 0]) + SQUARE(mtx[i * 3 + 1]) + SQUARE(mtx[i * 3 + 2])))

		if scale != 0.0:
			scale = _f32(1.0 / scale)
		dst[i * 3 + 0] = mtx[i * 3 + 0] * scale
		dst[i * 3 + 1] = mtx[i * 3 + 1] * scale
		dst[i * 3 + 2] = mtx[i * 3 + 2] * scale
		i += 1
	if (dst[2] == -1.0) or (dst[2] == 1.0):            # dst[0][2]
		if dst[2] == -1.0:
			rotate.y = F_CLC_DTOR32_90
			rotate.x = syUtilsArcTan2(dst[3], dst[4])  # (dst[1][0], dst[1][1])
		else:
			rotate.y = F_CLC_DTOR32_N90
			rotate.x = syUtilsArcTan2(-dst[3], dst[4])
		rotate.z = 0
	else:
		rotate.y = syUtilsArcSin(-dst[2])               # -dst[0][2]
		rotate.x = syUtilsArcTan2(dst[5], dst[8])      # (dst[1][2], dst[2][2])
		rotate.z = syUtilsArcTan2(dst[1], dst[0])      # (dst[0][1], dst[0][0])
	return rotate

## 0x800EDB88
## C: void (Mtx44f mtx, Vec3f *vec) - vec is a pure output -> returns vec (translation row).
static func func_ovl2_800EDB88(mtx: PackedFloat32Array) -> Vector3:
	var vec := Vector3()

	vec.x = mtx[9]          # mtx[3][0]
	vec.y = mtx[10]         # mtx[3][1]
	vec.z = mtx[11]         # mtx[3][2]
	return vec

## 0x800EDBA4 - make the world matrix (mtx_translate) of a fighter joint valid by walking up
## to the first ancestor with a valid world matrix (or the root) and composing downwards.
static func func_ovl2_800EDBA4(main_dobj: DObj) -> void:
	var parts: FtParts
	var current_dobjdata: FtParts
	var setup_dobj: Array = []       # DObj *setup_dobj[18]
	var second_dobj: DObj
	var flag: int = ftGetStruct(main_dobj.parent_gobj).is_use_animlocks
	var i: int

	if flag == FALSE:
		second_dobj = main_dobj

		i = 0

		while true:
			parts = second_dobj.user_data          # ftGetParts(second_dobj)

			if parts.unk_dobjtrans_0x5 != 0:
				break
			elif second_dobj.parent == DOBJ_PARENT_NULL:
				if parts.transform_update_mode == 0:
					gmCollisionTransformMatrixAll(second_dobj, parts, parts.unk_dobjtrans_0x10)

					parts.transform_update_mode = 1
				gmCollisionCopyMatrix(parts.mtx_translate, parts.unk_dobjtrans_0x10)

				parts.unk_dobjtrans_0x5 = 1

				break
			else:
				setup_dobj.append(second_dobj)     # setup_dobj[i] = second_dobj
				second_dobj = second_dobj.parent

				i += 1
		i = i - 1
		while i >= 0:
			second_dobj = setup_dobj[i]

			current_dobjdata = second_dobj.user_data

			if current_dobjdata.transform_update_mode == 0:
				gmCollisionTransformMatrixAll(second_dobj, current_dobjdata, current_dobjdata.unk_dobjtrans_0x10)

				current_dobjdata.transform_update_mode = 1
			func_ovl2_800ED490(current_dobjdata.mtx_translate, parts.mtx_translate, current_dobjdata.unk_dobjtrans_0x10)

			current_dobjdata.unk_dobjtrans_0x5 = 1
			parts = current_dobjdata
			i -= 1
	else:
		second_dobj = main_dobj

		i = 0

		while true:
			parts = second_dobj.user_data

			if parts.unk_dobjtrans_0x5 != 0:
				break
			elif second_dobj.parent == DOBJ_PARENT_NULL:
				if parts.transform_update_mode == 0:
					gmCollisionSetMatrixNcs(second_dobj, parts, parts.unk_dobjtrans_0x10, null)

					parts.transform_update_mode = 1
					parts.unk_dobjtrans_0x6 = 1
				gmCollisionCopyMatrix(parts.mtx_translate, parts.unk_dobjtrans_0x10)

				parts.unk_dobjtrans_0x5 = 1

				break
			else:
				setup_dobj.append(second_dobj)     # setup_dobj[i] = second_dobj
				second_dobj = second_dobj.parent

				i += 1
		i = i - 1
		while i >= 0:
			second_dobj = setup_dobj[i]

			current_dobjdata = second_dobj.user_data

			if current_dobjdata.transform_update_mode == 0:
				gmCollisionSetMatrixNcs(second_dobj, current_dobjdata, current_dobjdata.unk_dobjtrans_0x10, parts.vec_scale)

				current_dobjdata.transform_update_mode = 1
				current_dobjdata.unk_dobjtrans_0x6 = 1
			func_ovl2_800ED490(current_dobjdata.mtx_translate, parts.mtx_translate, current_dobjdata.unk_dobjtrans_0x10)

			current_dobjdata.unk_dobjtrans_0x5 = 1
			parts = current_dobjdata
			i -= 1

## 0x800EDE00 - make the inverse world matrix (unk_dobjtrans_0x9C) valid
static func func_ovl2_800EDE00(main_dobj: DObj) -> void:
	var parts: FtParts = main_dobj.user_data

	if parts.unk_dobjtrans_0x7 == 0:
		if parts.unk_dobjtrans_0x5 == 0:
			func_ovl2_800EDBA4(main_dobj)
		gmCollisionSetInvertMatrix(parts.unk_dobjtrans_0x9C, parts.mtx_translate)

		parts.unk_dobjtrans_0x7 = 1

## 0x800EDE5C - make the world scale (vec_scale) valid
static func func_ovl2_800EDE5C(main_dobj: DObj) -> void:
	var parts: FtParts = main_dobj.user_data

	if parts.unk_dobjtrans_0x6 == 0:
		if parts.unk_dobjtrans_0x5 == 0:
			func_ovl2_800EDBA4(main_dobj)
		var mtx: PackedFloat32Array = parts.mtx_translate
		parts.vec_scale.x = sqrtf(SQUARE(mtx[0]) + SQUARE(mtx[1]) + SQUARE(mtx[2]))
		parts.vec_scale.y = sqrtf(SQUARE(mtx[3]) + SQUARE(mtx[4]) + SQUARE(mtx[5]))
		parts.vec_scale.z = sqrtf(SQUARE(mtx[6]) + SQUARE(mtx[7]) + SQUARE(mtx[8]))

		parts.unk_dobjtrans_0x6 = 1

## 0x800EDF24 - transform a joint-local position to world space.
## C: void (DObj *main_dobj, Vec3f *vec) - vec is in-out -> `vec = gmCollisionGetFighterPartsWorldPosition(joint, vec)`.
static func gmCollisionGetFighterPartsWorldPosition(main_dobj: DObj, vec: Vector3) -> Vector3:
	var parts: FtParts
	var flag: int = ftGetStruct(main_dobj.parent_gobj).is_use_animlocks

	if flag == FALSE:
		while main_dobj != DOBJ_PARENT_NULL:
			parts = main_dobj.user_data

			if parts.unk_dobjtrans_0x5 != 0:
				vec = gmCollisionGetWorldPosition(parts.mtx_translate, vec)

				return vec
			elif parts.transform_update_mode == 0:
				gmCollisionTransformMatrixAll(main_dobj, parts, parts.unk_dobjtrans_0x10)

				parts.transform_update_mode = 1
			vec = gmCollisionGetWorldPosition(parts.unk_dobjtrans_0x10, vec)

			main_dobj = main_dobj.parent
	else:
		parts = main_dobj.user_data

		if parts.unk_dobjtrans_0x5 == 0:
			func_ovl2_800EDBA4(main_dobj)
		vec = gmCollisionGetWorldPosition(parts.mtx_translate, vec)
	return vec

## 0x800EE018 - transform a world position into the joint's local space (inverse world matrix).
## C: void (DObj *main_dobj, Vec3f *vec) - vec is in-out -> returns the new vec.
static func func_ovl2_800EE018(main_dobj: DObj, vec: Vector3) -> Vector3:
	var parts: FtParts = main_dobj.user_data

	func_ovl2_800EDE00(main_dobj)
	return gmCollisionGetWorldPosition(parts.unk_dobjtrans_0x9C, vec)

## 0x800EE050 - build the local frame of a swept (interpolated) hitbox capsule.
## C: void (s32 arg0, Vec3f *arg1, Vec3f *arg2, sb32 *arg3, Mtx44f mtx, f32 *p_scale);
## arg3 and p_scale are in-out, mtx is written in place -> returns {"arg3", "p_scale", "mtx"}.
static func func_ovl2_800EE050(arg0: int, arg1: Vector3, arg2: Vector3, arg3: int, mtx: PackedFloat32Array, p_scale: float) -> Dictionary:
	var dist := Vector3()
	var square: float
	var scale: float
	var temp: float

	if (arg0 == 3) and (arg3 == FALSE):
		dist.x = arg2.x - arg1.x
		dist.y = arg2.y - arg1.y
		dist.z = arg2.z - arg1.z

		p_scale = _f32(sqrtf(SQUARE(dist.x) + SQUARE(dist.y) + SQUARE(dist.z)))

		if p_scale != 0.0:
			scale = _f32(1.0 / p_scale)

			dist.x *= scale
			dist.y *= scale
			dist.z *= scale

			# JUST BARELY matches; otherwise 1.0F and square are swapped in the c.eq.s instruction operands; if(TRUE) necessary (for now)
			square = _f32(SQUARE(dist.x))

			if square == 1.0:
				if dist.x >= 0.0:
					mtx[0] = 1.0        # mtx[0][0] = mtx[1][1] = mtx[2][2] = 1.0F
					mtx[4] = 1.0
					mtx[8] = 1.0

					mtx[1] = 0.0        # mtx[0][1]
					mtx[2] = 0.0        # mtx[0][2]
					mtx[3] = 0.0        # mtx[1][0]
					mtx[5] = 0.0        # mtx[1][2]
					mtx[6] = 0.0        # mtx[2][0]
					mtx[7] = 0.0        # mtx[2][1]
				else:
					mtx[0] = -1.0       # mtx[0][0] = mtx[1][1] = -1.0F
					mtx[4] = -1.0

					mtx[8] = 1.0        # mtx[2][2]

					mtx[1] = 0.0
					mtx[2] = 0.0
					mtx[3] = 0.0
					mtx[5] = 0.0
					mtx[6] = 0.0
					mtx[7] = 0.0
			else:
				temp = dist.x
				mtx[0] = temp                                                          # mtx[0][0] = temp = dist.x
				mtx[5] = (dist.z * dist.y) / (1.0 + dist.x)                            # mtx[1][2]
				mtx[7] = (dist.z * dist.y) / (1.0 + dist.x)                            # mtx[2][1]

				scale = _f32(1.0 / (1.0 - SQUARE(temp)))

				mtx[4] = ((1.0 - (SQUARE(dist.z) * scale)) * temp) + (SQUARE(dist.z) * scale)   # mtx[1][1]
				mtx[6] = dist.z                                                        # mtx[2][0]
				mtx[2] = -dist.z                                                       # mtx[0][2]

				mtx[8] = ((1.0 - (SQUARE(dist.y) * scale)) * temp) + (SQUARE(dist.y) * scale)   # mtx[2][2]
				mtx[1] = dist.y                                                        # mtx[0][1]
				mtx[3] = -dist.y                                                       # mtx[1][0]
			p_scale = _f32(p_scale * 0.5)
			mtx[9] = p_scale        # mtx[3][0] = *p_scale *= 0.5F
			mtx[10] = 0.0           # mtx[3][1]
			mtx[11] = 0.0           # mtx[3][2]

			arg3 = TRUE
	return {"arg3": arg3, "p_scale": p_scale, "mtx": mtx}

## 0x800EE24C - outcode of a point against the XY extents of a box
static func func_ovl2_800EE24C(lhs: Vector3, rhs: Vector3) -> int:
	var flags: int = 0

	if lhs.x < -rhs.x:
		flags |= 1
	if lhs.x > rhs.x:
		flags |= 2
	if lhs.y < -rhs.y:
		flags |= 4
	if lhs.y > rhs.y:
		flags |= 8
	return flags

## 0x800EE2C0 - outcode of a point against the Z extents of a box
static func func_ovl2_800EE2C0(lhs: Vector3, rhs: Vector3) -> int:
	var flags: int = 0

	if lhs.z < -rhs.z:
		flags |= 1
	if lhs.z > rhs.z:
		flags |= 2
	return flags

## 0x800EE300 - hitbox sphere (point or swept segment, radius) vs box hurtbox.
## mtx: PackedFloat32Array (world -> box space) or null; offset/size/scale: Vector3.
static func gmCollisionTestRectangle(pos_curr: Vector3, pos_prev: Vector3, radius: float, opkind: int, mtx, offset: Vector3, size: Vector3, scale: Vector3) -> int:
	# Not sure about the variable names; help from ChatGPT
	var center := Vector3()
	var sp90: Vector3
	var sp84 := Vector3()
	var sp78: Vector3
	var sp6C: Vector3
	var flags_sp78: int
	var flags_sp6C: int
	var flags_main: int
	var distx: float
	var disty: float
	var distz: float

	center.x = size.x + (radius / scale.x)
	center.y = size.y + (radius / scale.y)
	center.z = size.z + (radius / scale.z)

	if opkind == 2:
		sp90 = pos_curr

		if mtx != null:
			sp90 = gmCollisionGetWorldPosition(mtx, sp90)
		sp90.x -= offset.x
		sp90.y -= offset.y
		sp90.z -= offset.z

		if (-center.x <= sp90.x) and (sp90.x <= center.x) and (-center.y <= sp90.y) and (sp90.y <= center.y) and (-center.z <= sp90.z) and (sp90.z <= center.z):
			return TRUE
		else:
			return FALSE
	sp78 = pos_curr
	sp6C = pos_prev

	if mtx != null:
		sp78 = gmCollisionGetWorldPosition(mtx, sp78)
		sp6C = gmCollisionGetWorldPosition(mtx, sp6C)
	sp78.x -= offset.x
	sp78.y -= offset.y
	sp78.z -= offset.z
	sp6C.x -= offset.x
	sp6C.y -= offset.y
	sp6C.z -= offset.z

	distx = sp6C.x - sp78.x
	disty = sp6C.y - sp78.y
	distz = sp6C.z - sp78.z

	flags_sp78 = func_ovl2_800EE24C(sp78, center)
	flags_sp6C = func_ovl2_800EE24C(sp6C, center)

	# loop: (goto loop -> while)
	while (flags_sp78 != 0) or (flags_sp6C != 0):
		if flags_sp78 & flags_sp6C:
			return FALSE
		elif flags_sp78 != 0:
			flags_main = flags_sp78
		else:
			flags_main = flags_sp6C

		if flags_main & 1:
			sp84.x = -center.x
			sp84.y = (((sp84.x - sp78.x) / distx) * disty) + sp78.y
			sp84.z = (((sp84.x - sp78.x) / distx) * distz) + sp78.z
		elif flags_main & 2:
			sp84.x = center.x
			sp84.y = (((sp84.x - sp78.x) / distx) * disty) + sp78.y
			sp84.z = (((sp84.x - sp78.x) / distx) * distz) + sp78.z
		elif flags_main & 4:
			sp84.y = -center.y
			sp84.x = (((sp84.y - sp78.y) / disty) * distx) + sp78.x
			sp84.z = (((sp84.y - sp78.y) / disty) * distz) + sp78.z
		elif flags_main & 8:
			sp84.y = center.y
			sp84.x = (((sp84.y - sp78.y) / disty) * distx) + sp78.x
			sp84.z = (((sp84.y - sp78.y) / disty) * distz) + sp78.z
		if flags_main == flags_sp78:
			sp78 = sp84
			flags_sp78 = func_ovl2_800EE24C(sp78, center)
		else:
			sp6C = sp84
			flags_sp6C = func_ovl2_800EE24C(sp6C, center)
	flags_sp78 = func_ovl2_800EE2C0(sp78, center)
	flags_sp6C = func_ovl2_800EE2C0(sp6C, center)

	if flags_sp78 & flags_sp6C:
		return FALSE
	else:
		return TRUE

## Builds the gmCollisionTestSphere result (C return value + the in-out parameters).
static func _sphere_result(ret: int, p_angle: float, argA: Vector3) -> Dictionary:
	return {"ret": ret, "p_angle": p_angle, "argA": argA}

## 0x800EE750 - hitbox sphere (point or swept segment) vs ellipsoid (shield / reflector / absorb).
## C: sb32 (..., s32 sphit_kind, f32 *p_angle, Vec3f *argA); p_angle and argA are in-out
## (written only when hitting with sphit_kind 0 / 1) -> returns {"ret", "p_angle", "argA"}.
## C callers that pass NULL may pass anything (0.0 / Vector3.ZERO) and ignore the keys.
static func gmCollisionTestSphere(pos_curr: Vector3, pos_prev: Vector3, hitsize: float, attack_state: int, mtx: PackedFloat32Array, sphere_offset: Vector3, sphere_size: Vector3, arg7: Vector3, sphit_kind: int, p_angle: float = 0.0, argA: Vector3 = Vector3.ZERO) -> Dictionary:
	# Might be very fake. Maybe not. Spent a whole day trying to match this and finally managed to find a solution using the permuter!
	var center := Vector3()

	center.x = sphere_size.x + (hitsize / arg7.x)
	center.y = sphere_size.y + (hitsize / arg7.y)
	center.z = sphere_size.z + (hitsize / arg7.z)

	if (attack_state == nGMAttackStateTransfer) or ((pos_curr.x == pos_prev.x) and (pos_curr.y == pos_prev.y) and (pos_curr.z == pos_prev.z)):
		var copy1: Vector3 = pos_curr

		copy1 = gmCollisionGetWorldPosition(mtx, copy1)

		copy1.x -= sphere_offset.x
		copy1.y -= sphere_offset.y
		copy1.z -= sphere_offset.z

		copy1.x /= center.x
		copy1.y /= center.y
		copy1.z /= center.z

		if syVectorMag3D(copy1) <= 1:
			match sphit_kind:
				0:
					p_angle = F_CLC_DTOR32_180
				1:
					p_angle = F_CLC_DTOR32_180

					argA.x = 1
					argA.y = 0.0
					argA.z = 0.0
				2:
					pass
				_:
					pass
			return _sphere_result(TRUE, p_angle, argA)
		else:
			return _sphere_result(FALSE, p_angle, argA)
	else:
		var copy1: Vector3
		var copy2: Vector3
		var copysub := Vector3()
		var sp58 := Vector3()
		var sp54: float
		var sp50: float
		var sp48: float
		var sp44: float = 0.0
		var sp40: float
		var sp3C: float

		copy1 = pos_curr
		copy2 = pos_prev

		copy1 = gmCollisionGetWorldPosition(mtx, copy1)
		copy2 = gmCollisionGetWorldPosition(mtx, copy2)

		copy1.x -= sphere_offset.x
		copy1.y -= sphere_offset.y
		copy1.z -= sphere_offset.z

		copy2.x -= sphere_offset.x
		copy2.y -= sphere_offset.y
		copy2.z -= sphere_offset.z

		copy1.x /= center.x
		copy1.y /= center.y
		copy1.z /= center.z

		copy2.x /= center.x
		copy2.y /= center.y
		copy2.z /= center.z

		copysub.x = copy1.x - copy2.x
		copysub.y = copy1.y - copy2.y
		copysub.z = copy1.z - copy2.z

		sp54 = (SQUARE(copysub.x) + SQUARE(copysub.y) + SQUARE(copysub.z))

		if sp54 != 0.0:
			sp40 = SQUARE(copy2.z)

			sp50 = (copysub.x * copy2.x) + (copysub.y * copy2.y) + (copysub.z * copy2.z)
			sp3C = ((SQUARE(copy2.x) + SQUARE(copy2.y) + sp40) - 1.0)
			sp3C = sp54 * sp3C

			sp48 = SQUARE(sp50) - sp3C

			if SQUARE(sp50) < sp3C:
				return _sphere_result(FALSE, p_angle, argA)
			elif sp48 == 0.0:
				if sp54 == 0.0:
					_gmCollisionFatal("zero div 1 in gcColSphere()\n")
				sp40 = -sp50 / sp54
				sp44 = sp40

				if not ((sp44 >= 0.0) and (sp44 <= 1.0)):
					return _sphere_result(FALSE, p_angle, argA)
				# else goto next
			else:
				if sp54 == 0.0:
					_gmCollisionFatal("zero div 2 in gcColSphere()\n")
				sp44 = (sqrtf(sp48) + -sp50) / sp54
				sp40 = (-sp50 - sqrtf(sp48)) / sp54

				if (sp44 >= 0.0) and (sp44 <= 1.0):
					pass        # goto next
				elif (sp40 >= 0.0) and (sp40 <= 1.0):
					pass        # goto next
				elif (sp44 * sp40) < 0.0:
					pass        # goto next
				else:
					return _sphere_result(FALSE, p_angle, argA)
			# next:
			match sphit_kind:
				0:
					sp3C = sp44 if (sp44 < sp40) else sp40

					sp58.x = (copysub.x * sp3C) + copy2.x
					sp58.y = (copysub.y * sp3C) + copy2.y
					sp58.z = (copysub.z * sp3C) + copy2.z

					p_angle = _f32(syVectorAngleDiff3D(copysub, sp58))
				1:
					sp3C = sp44 if (sp44 < sp40) else sp40

					copysub.x = 0.0
					sp58.x = 0.0

					sp58.y = (copysub.y * sp3C) + copy2.y
					sp58.z = (copysub.z * sp3C) + copy2.z

					p_angle = F_CLC_DTOR32_180 if ((sp58.y == 0.0) and (sp58.z == 0.0)) else _f32(syVectorAngleDiff3D(copysub, sp58))

					if p_angle != F_CLC_DTOR32_180:
						# syVectorNormCross3D(&copysub, &sp58, argA): argA = copysub x sp58, normalized
						# when its magnitude is nonzero (left as the raw zero vector otherwise).
						argA.x = (copysub.y * sp58.z) - (copysub.z * sp58.y)
						argA.y = (copysub.z * sp58.x) - (copysub.x * sp58.z)
						argA.z = (copysub.x * sp58.y) - (copysub.y * sp58.x)
						argA = syVectorNorm3D(argA)
					else:
						argA.x = 1.0
						argA.y = 0.0
						argA.z = 0.0
				2:
					pass
				_:
					pass
			return _sphere_result(TRUE, p_angle, argA)
		elif syVectorMag3D(copy1) <= 1:
			match sphit_kind:
				0:
					p_angle = F_CLC_DTOR32_180
				1:
					p_angle = F_CLC_DTOR32_180

					argA.x = 1
					argA.y = 0.0
					argA.z = 0.0
				2:
					pass
				_:
					pass
			return _sphere_result(TRUE, p_angle, argA)
		else:
			return _sphere_result(FALSE, p_angle, argA)

## 0x800EEEAC - hitbox (point / swept) vs another hitbox's capsule (its frame from func_ovl2_800EE050)
static func func_ovl2_800EEEAC(arg0: Vector3, arg1: Vector3, arg2: float, opkind: int, mtx: PackedFloat32Array, arg5: int, arg6: Vector3, arg7: float, arg8: int, arg9: float) -> int:
	var sp94 := Vector3()
	var sp88 := Vector3()
	var sp7C := Vector3()
	var sp70 := Vector3()
	var sp64 := Vector3()
	var flags_sp70: int
	var flags_sp64: int
	var flags_main: int
	var distx: float
	var disty: float
	var distz: float

	sp94.x = arg9 + arg7 + arg2
	sp94.z = arg7 + arg2
	sp94.y = sp94.z

	if opkind == 2:
		sp88.x = arg0.x - arg6.x
		sp88.y = arg0.y - arg6.y
		sp88.z = arg0.z - arg6.z

		if (arg8 == 3) and (arg5 == 1):
			sp88 = gmCollisionGetWorldPosition(mtx, sp88)
		if (-sp94.x <= sp88.x) and (sp88.x <= sp94.x) and (-sp94.y <= sp88.y) and (sp88.y <= sp94.y) and (-sp94.z <= sp88.z) and (sp88.z <= sp94.z):
			return TRUE
		else:
			return FALSE
	sp70.x = arg0.x - arg6.x
	sp70.y = arg0.y - arg6.y
	sp70.z = arg0.z - arg6.z

	sp64.x = arg1.x - arg6.x
	sp64.y = arg1.y - arg6.y
	sp64.z = arg1.z - arg6.z

	if (arg8 == 3) and (arg5 == 1):
		sp70 = gmCollisionGetWorldPosition(mtx, sp70)
		sp64 = gmCollisionGetWorldPosition(mtx, sp64)
	distx = sp64.x - sp70.x
	disty = sp64.y - sp70.y
	distz = sp64.z - sp70.z

	flags_sp70 = func_ovl2_800EE24C(sp70, sp94)
	flags_sp64 = func_ovl2_800EE24C(sp64, sp94)

	# loop: (goto loop -> while)
	while (flags_sp70 != 0) or (flags_sp64 != 0):
		if flags_sp70 & flags_sp64:
			return FALSE
		elif flags_sp70 != 0:
			flags_main = flags_sp70
		else:
			flags_main = flags_sp64

		if flags_main & 1:
			sp7C.x = -sp94.x
			sp7C.y = (((sp7C.x - sp70.x) / distx) * disty) + sp70.y
			sp7C.z = (((sp7C.x - sp70.x) / distx) * distz) + sp70.z
		elif flags_main & 2:
			sp7C.x = sp94.x
			sp7C.y = (((sp7C.x - sp70.x) / distx) * disty) + sp70.y
			sp7C.z = (((sp7C.x - sp70.x) / distx) * distz) + sp70.z
		elif flags_main & 4:
			sp7C.y = -sp94.y
			sp7C.x = (((sp7C.y - sp70.y) / disty) * distx) + sp70.x
			sp7C.z = (((sp7C.y - sp70.y) / disty) * distz) + sp70.z
		elif flags_main & 8:
			sp7C.y = sp94.y
			sp7C.x = (((sp7C.y - sp70.y) / disty) * distx) + sp70.x
			sp7C.z = (((sp7C.y - sp70.y) / disty) * distz) + sp70.z
		if flags_main == flags_sp70:
			sp70 = sp7C

			flags_sp70 = func_ovl2_800EE24C(sp70, sp94)
		else:
			sp64 = sp7C

			flags_sp64 = func_ovl2_800EE24C(sp64, sp94)
	flags_sp70 = func_ovl2_800EE2C0(sp70, sp94)
	flags_sp64 = func_ovl2_800EE2C0(sp64, sp94)

	if flags_sp70 & flags_sp64:
		return FALSE
	return TRUE

## 0x800EF2D0 - coarse check: attack position inside the fighter's hit detection range
static func gmCollisionCheckAttackInFighterRange(attack_position: Vector3, obj_position: Vector3, range_: Vector3, size: float) -> int:
	var distx: float = attack_position.x - obj_position.x
	var disty: float = attack_position.y - obj_position.y

	if (distx < (-range_.z - size)) or (distx > (range_.z + size)) or (disty < (-range_.y - size)) or (disty > (range_.x + size)):
		return FALSE
	else:
		return TRUE

## 0x800EF364
static func gmCollisionCheckFighterInFighterRange(attack_coll: FTAttackColl, fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if attack_coll.attack_state == nGMAttackStateTransfer:
		return gmCollisionCheckAttackInFighterRange(attack_coll.pos_curr, DObjGetStruct(fighter_gobj).translate, attr.hit_detect_range, attack_coll.size)
	elif (gmCollisionCheckAttackInFighterRange(attack_coll.pos_curr, DObjGetStruct(fighter_gobj).translate, attr.hit_detect_range, attack_coll.size) != FALSE) or (gmCollisionCheckAttackInFighterRange(attack_coll.pos_prev, DObjGetStruct(fighter_gobj).translate, attr.hit_detect_range, attack_coll.size) != FALSE):
		return TRUE
	else:
		return FALSE

## 0x800EF414
static func gmCollisionCheckWeaponInFighterRange(attack_coll: WPAttackColl, attack_id: int, fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if attack_coll.attack_state == nGMAttackStateTransfer:
		return gmCollisionCheckAttackInFighterRange(attack_coll.attack_pos[attack_id].pos_curr, DObjGetStruct(fighter_gobj).translate, attr.hit_detect_range, attack_coll.size)
	elif (gmCollisionCheckAttackInFighterRange(attack_coll.attack_pos[attack_id].pos_curr, DObjGetStruct(fighter_gobj).translate, attr.hit_detect_range, attack_coll.size) != FALSE) or (gmCollisionCheckAttackInFighterRange(attack_coll.attack_pos[attack_id].pos_prev, DObjGetStruct(fighter_gobj).translate, attr.hit_detect_range, attack_coll.size) != FALSE):
		return TRUE
	else:
		return FALSE

## 0x800EF4F4
static func gmCollisionCheckItemInFighterRange(attack_coll: ITAttackColl, attack_id: int, fighter_gobj) -> int:
	var fp := ftGetStruct(fighter_gobj)
	var attr = fp.attr

	if attack_coll.attack_state == nGMAttackStateTransfer:
		return gmCollisionCheckAttackInFighterRange(attack_coll.attack_pos[attack_id].pos_curr, DObjGetStruct(fighter_gobj).translate, attr.hit_detect_range, attack_coll.size)
	elif (gmCollisionCheckAttackInFighterRange(attack_coll.attack_pos[attack_id].pos_curr, DObjGetStruct(fighter_gobj).translate, attr.hit_detect_range, attack_coll.size) != FALSE) or (gmCollisionCheckAttackInFighterRange(attack_coll.attack_pos[attack_id].pos_prev, DObjGetStruct(fighter_gobj).translate, attr.hit_detect_range, attack_coll.size) != FALSE):
		return TRUE
	else:
		return FALSE

## 0x800EF5D4 - coarse 2D bounds check between two hitboxes (point or swept)
static func func_ovl2_800EF5D4(arg0: Vector3, arg1: Vector3, arg2: float, arg3: int, arg4: Vector3, arg5: Vector3, arg6: float, arg7: int) -> int:
	var sp2C: float
	var sp28: float
	var sp24: float
	var sp20: float
	var var_f12: float
	var temp: float

	temp = arg6 + arg2

	if arg7 == 2:
		if arg3 == 2:
			if (arg0.x < (arg4.x - temp)) or ((arg4.x + temp) < arg0.x) or (arg0.y < (arg4.y - temp)) or ((arg4.y + temp) < arg0.y):
				return FALSE
			else:
				return TRUE
		if arg0.x < arg1.x:
			sp2C = arg0.x - temp
			sp28 = arg1.x + temp
		else:
			sp2C = arg1.x - temp
			sp28 = arg0.x + temp
		if (arg4.x < sp2C) or (sp28 < arg4.x):
			return FALSE
		if arg0.y < arg1.y:
			sp24 = arg0.y - temp
			sp20 = arg1.y + temp
		else:
			sp24 = arg1.y - temp
			sp20 = arg0.y + temp
		if (arg4.y < sp24) or (sp20 < arg4.y):
			return FALSE
		else:
			return TRUE
	if arg3 == 2:
		if arg4.x < arg5.x:
			sp2C = arg4.x - temp
			sp28 = arg5.x + temp
		else:
			sp2C = arg5.x - temp
			sp28 = arg4.x + temp
		if (arg0.x < sp2C) or (sp28 < arg0.x):
			return FALSE
		if arg4.y < arg5.y:
			sp24 = arg4.y - temp
			sp20 = arg5.y + temp
		else:
			sp24 = arg5.y - temp
			sp20 = arg4.y + temp
		if (arg0.y < sp24) or (sp20 < arg0.y):
			return FALSE
		else:
			return TRUE
	if arg0.x < arg1.x:
		var_f12 = -(arg0.x - arg1.x)
	else:
		var_f12 = arg0.x - arg1.x
	if arg4.x < arg5.x:
		sp2C = arg4.x - ((var_f12 * 0.5) + temp)
		sp28 = arg5.x + ((var_f12 * 0.5) + temp)
	else:
		sp2C = arg5.x - ((var_f12 * 0.5) + temp)
		sp28 = arg4.x + ((var_f12 * 0.5) + temp)
	if (arg0.x < sp2C) and (arg1.x < sp2C):
		return FALSE
	elif (sp28 < arg0.x) and (sp28 < arg1.x):
		return FALSE
	if arg0.y < arg1.y:
		var_f12 = -(arg0.y - arg1.y)
	else:
		var_f12 = arg0.y - arg1.y

	if arg4.y < arg5.y:
		sp24 = arg4.y - ((var_f12 * 0.5) + temp)
		sp20 = arg5.y + ((var_f12 * 0.5) + temp)
	else:
		sp24 = arg5.y - ((var_f12 * 0.5) + temp)
		sp20 = arg4.y + ((var_f12 * 0.5) + temp)
	if (arg0.y < sp24) and (arg1.y < sp24):
		return FALSE
	elif (sp20 < arg0.y) and (sp20 < arg1.y):
		return FALSE
	return TRUE

## 0x800EFABC - Check if fighter hitbox intersects with other fighter hitbox
static func gmCollisionCheckFighterAttacksCollide(attack_coll1: FTAttackColl, attack_coll2: FTAttackColl) -> int:
	if func_ovl2_800EF5D4(attack_coll1.pos_curr, attack_coll1.pos_prev, attack_coll1.size, attack_coll1.attack_state, attack_coll2.pos_curr, attack_coll2.pos_prev, attack_coll2.size, attack_coll2.attack_state) == FALSE:
		return FALSE
	else:
		var r := func_ovl2_800EE050(attack_coll2.attack_state, attack_coll2.pos_curr, attack_coll2.pos_prev, attack_coll2.attack_matrix_unk_fthitmtx_0x0, attack_coll2.attack_matrix_mtx, attack_coll2.attack_matrix_unk_fthitmtx_0x44)
		attack_coll2.attack_matrix_unk_fthitmtx_0x0 = r.arg3
		attack_coll2.attack_matrix_unk_fthitmtx_0x44 = r.p_scale

	return func_ovl2_800EEEAC(attack_coll1.pos_curr, attack_coll1.pos_prev, attack_coll1.size, attack_coll1.attack_state, attack_coll2.attack_matrix_mtx, attack_coll2.attack_matrix_unk_fthitmtx_0x0, attack_coll2.pos_curr, attack_coll2.size, attack_coll2.attack_state, attack_coll2.attack_matrix_unk_fthitmtx_0x44)

## 0x800EFBA4 - Check if fighter hitbox intersects with fighter hurtbox
static func gmCollisionCheckFighterAttackDamageCollide(attack_coll: FTAttackColl, damage_coll: FTDamageColl) -> int:
	var parts: FtParts
	var dobj: DObj

	dobj = damage_coll.joint
	parts = dobj.user_data

	func_ovl2_800EDE00(dobj)
	func_ovl2_800EDE5C(dobj)

	return gmCollisionTestRectangle(attack_coll.pos_curr, attack_coll.pos_prev, attack_coll.size, attack_coll.attack_state, parts.unk_dobjtrans_0x9C, damage_coll.offset, damage_coll.size, parts.vec_scale)

## 0x800EFC20 - Check if item hurtbox intersects with fighter hitbox
static func gmCollisionCheckFighterAttackItemDamageCollide(attack_coll: FTAttackColl, damage_coll: ITDamageColl, item_gobj) -> int:
	var damage_coll_pos := Vector3()

	damage_coll_pos.x = DObjGetStruct(item_gobj).translate.x + damage_coll.offset.x
	damage_coll_pos.y = DObjGetStruct(item_gobj).translate.y + damage_coll.offset.y
	damage_coll_pos.z = DObjGetStruct(item_gobj).translate.z + damage_coll.offset.z

	return gmCollisionTestRectangle(attack_coll.pos_curr, attack_coll.pos_prev, attack_coll.size, attack_coll.attack_state, null, damage_coll_pos, damage_coll.size, DObjGetStruct(item_gobj).scale)

## 0x800EFCC0 - Check if fighter hitbox intersects with shield
## C: sb32 (..., f32 *p_angle) -> returns {"ret", "p_angle"} (p_angle in-out; written when ret is TRUE).
static func gmCollisionCheckFighterAttackShieldCollide(attack_coll: FTAttackColl, fighter_gobj, dobj: DObj, p_angle: float = 0.0) -> Dictionary:
	var parts: FtParts
	var sp48 := Vector3()
	var sp3C := Vector3()

	sp48.x = 0.0
	sp48.y = 0.0
	sp48.z = 0.0

	sp3C.x = 30.0
	sp3C.y = 30.0
	sp3C.z = 30.0

	parts = dobj.user_data

	func_ovl2_800EDE00(dobj)
	func_ovl2_800EDE5C(dobj)

	var r := gmCollisionTestSphere(attack_coll.pos_curr, attack_coll.pos_prev, attack_coll.size, attack_coll.attack_state, parts.unk_dobjtrans_0x9C, sp48, sp3C, parts.vec_scale, 0, p_angle, Vector3.ZERO)
	return {"ret": r.ret, "p_angle": r.p_angle}

## 0x800EFD70 - Check if weapon hitbox intersects with fighter hitbox
static func gmCollisionCheckWeaponAttackFighterAttackCollide(wp_attack_coll: WPAttackColl, attack_id: int, ft_attack_coll: FTAttackColl) -> int:
	if func_ovl2_800EF5D4(wp_attack_coll.attack_pos[attack_id].pos_curr, wp_attack_coll.attack_pos[attack_id].pos_prev, wp_attack_coll.size, wp_attack_coll.attack_state, ft_attack_coll.pos_curr, ft_attack_coll.pos_prev, ft_attack_coll.size, ft_attack_coll.attack_state) == FALSE:
		return FALSE
	else:
		var r := func_ovl2_800EE050(ft_attack_coll.attack_state, ft_attack_coll.pos_curr, ft_attack_coll.pos_prev, ft_attack_coll.attack_matrix_unk_fthitmtx_0x0, ft_attack_coll.attack_matrix_mtx, ft_attack_coll.attack_matrix_unk_fthitmtx_0x44)
		ft_attack_coll.attack_matrix_unk_fthitmtx_0x0 = r.arg3
		ft_attack_coll.attack_matrix_unk_fthitmtx_0x44 = r.p_scale

	return func_ovl2_800EEEAC(wp_attack_coll.attack_pos[attack_id].pos_curr, wp_attack_coll.attack_pos[attack_id].pos_prev, wp_attack_coll.size, wp_attack_coll.attack_state, ft_attack_coll.attack_matrix_mtx, ft_attack_coll.attack_matrix_unk_fthitmtx_0x0, ft_attack_coll.pos_curr, ft_attack_coll.size, ft_attack_coll.attack_state, ft_attack_coll.attack_matrix_unk_fthitmtx_0x44)

## 0x800EFE6C
static func gmCollisionCheckWeaponAttackFighterDamageCollide(attack_coll: WPAttackColl, attack_id: int, damage_coll: FTDamageColl) -> int:
	var parts: FtParts
	var dobj: DObj

	dobj = damage_coll.joint
	parts = dobj.user_data

	func_ovl2_800EDE00(dobj)
	func_ovl2_800EDE5C(dobj)

	return gmCollisionTestRectangle(attack_coll.attack_pos[attack_id].pos_curr, attack_coll.attack_pos[attack_id].pos_prev, attack_coll.size, attack_coll.attack_state, parts.unk_dobjtrans_0x9C, damage_coll.offset, damage_coll.size, parts.vec_scale)

## 0x800EFF00
## C: sb32 (..., f32 *p_angle, Vec3f *vec) -> returns {"ret", "p_angle", "vec"} (in-out; written when ret is TRUE).
static func gmCollisionCheckWeaponAttackShieldCollide(attack_coll: WPAttackColl, attack_id: int, fighter_gobj, dobj: DObj, p_angle: float = 0.0, vec: Vector3 = Vector3.ZERO) -> Dictionary:
	var parts: FtParts
	var sp58 := Vector3()
	var sp4C := Vector3()

	sp58.x = 0.0
	sp58.y = 0.0
	sp58.z = 0.0

	sp4C.x = 30.0
	sp4C.y = 30.0
	sp4C.z = 30.0

	parts = dobj.user_data

	func_ovl2_800EDE00(dobj)
	func_ovl2_800EDE5C(dobj)

	var r := gmCollisionTestSphere(attack_coll.attack_pos[attack_id].pos_curr, attack_coll.attack_pos[attack_id].pos_prev, attack_coll.size, attack_coll.attack_state, parts.unk_dobjtrans_0x9C, sp58, sp4C, parts.vec_scale, 1, p_angle, vec)
	return {"ret": r.ret, "p_angle": r.p_angle, "vec": r.argA}

## 0x800EFFCC
static func gmCollisionCheckWeaponAttackSpecialCollide(attack_coll: WPAttackColl, attack_id: int, fp: Fighter, special_coll: FTSpecialColl) -> int:
	var dobj: DObj = fp.joints[special_coll.joint_id]
	var parts: FtParts = dobj.user_data

	func_ovl2_800EDE00(dobj)
	func_ovl2_800EDE5C(dobj)

	return gmCollisionTestSphere(attack_coll.attack_pos[attack_id].pos_curr, attack_coll.attack_pos[attack_id].pos_prev, attack_coll.size, attack_coll.attack_state, parts.unk_dobjtrans_0x9C, special_coll.offset, special_coll.size, parts.vec_scale, 2, 0.0, Vector3.ZERO).ret

## 0x800F007C
static func gmCollisionCheckWeaponAttacksCollide(attack_coll1: WPAttackColl, atk1_id: int, attack_coll2: WPAttackColl, atk2_id: int) -> int:
	if func_ovl2_800EF5D4(attack_coll1.attack_pos[atk1_id].pos_curr, attack_coll1.attack_pos[atk1_id].pos_prev, attack_coll1.size, attack_coll1.attack_state, attack_coll2.attack_pos[atk2_id].pos_curr, attack_coll2.attack_pos[atk2_id].pos_prev, attack_coll2.size, attack_coll2.attack_state) == FALSE:
		return FALSE
	else:
		var r := func_ovl2_800EE050(attack_coll2.attack_state, attack_coll2.attack_pos[atk2_id].pos_curr, attack_coll2.attack_pos[atk2_id].pos_prev, attack_coll2.attack_pos[atk2_id].unk_wphitpos_0x18, attack_coll2.attack_pos[atk2_id].mtx, attack_coll2.attack_pos[atk2_id].unk_wphitpos_0x5C)
		attack_coll2.attack_pos[atk2_id].unk_wphitpos_0x18 = r.arg3
		attack_coll2.attack_pos[atk2_id].unk_wphitpos_0x5C = r.p_scale

	return func_ovl2_800EEEAC(attack_coll1.attack_pos[atk1_id].pos_curr, attack_coll1.attack_pos[atk1_id].pos_prev, attack_coll1.size, attack_coll1.attack_state, attack_coll2.attack_pos[atk2_id].mtx, attack_coll2.attack_pos[atk2_id].unk_wphitpos_0x18, attack_coll2.attack_pos[atk2_id].pos_curr, attack_coll2.size, attack_coll2.attack_state, attack_coll2.attack_pos[atk2_id].unk_wphitpos_0x5C)

## 0x800F019C
static func gmCollisionCheckWeaponAttackItemAttackCollide(wp_attack_coll: WPAttackColl, wp_attack_id: int, it_attack_coll: ITAttackColl, it_attack_id: int) -> int:
	if func_ovl2_800EF5D4(wp_attack_coll.attack_pos[wp_attack_id].pos_curr, wp_attack_coll.attack_pos[wp_attack_id].pos_prev, wp_attack_coll.size, wp_attack_coll.attack_state, it_attack_coll.attack_pos[it_attack_id].pos_curr, it_attack_coll.attack_pos[it_attack_id].pos_prev, it_attack_coll.size, it_attack_coll.attack_state) == FALSE:
		return FALSE
	else:
		var r := func_ovl2_800EE050(it_attack_coll.attack_state, it_attack_coll.attack_pos[it_attack_id].pos_curr, it_attack_coll.attack_pos[it_attack_id].pos_prev, it_attack_coll.attack_pos[it_attack_id].unk_ithitpos_0x18, it_attack_coll.attack_pos[it_attack_id].mtx, it_attack_coll.attack_pos[it_attack_id].unk_ithitpos_0x5C)
		it_attack_coll.attack_pos[it_attack_id].unk_ithitpos_0x18 = r.arg3
		it_attack_coll.attack_pos[it_attack_id].unk_ithitpos_0x5C = r.p_scale

	return func_ovl2_800EEEAC(wp_attack_coll.attack_pos[wp_attack_id].pos_curr, wp_attack_coll.attack_pos[wp_attack_id].pos_prev, wp_attack_coll.size, wp_attack_coll.attack_state, it_attack_coll.attack_pos[it_attack_id].mtx, it_attack_coll.attack_pos[it_attack_id].unk_ithitpos_0x18, it_attack_coll.attack_pos[it_attack_id].pos_curr, it_attack_coll.size, it_attack_coll.attack_state, it_attack_coll.attack_pos[it_attack_id].unk_ithitpos_0x5C)

## 0x800F02BC
static func gmCollisionCheckItemAttackFighterAttackCollide(it_attack_coll: ITAttackColl, attack_id: int, ft_attack_coll: FTAttackColl) -> int:
	if func_ovl2_800EF5D4(it_attack_coll.attack_pos[attack_id].pos_curr, it_attack_coll.attack_pos[attack_id].pos_prev, it_attack_coll.size, it_attack_coll.attack_state, ft_attack_coll.pos_curr, ft_attack_coll.pos_prev, ft_attack_coll.size, ft_attack_coll.attack_state) == FALSE:
		return FALSE
	else:
		var r := func_ovl2_800EE050(ft_attack_coll.attack_state, ft_attack_coll.pos_curr, ft_attack_coll.pos_prev, ft_attack_coll.attack_matrix_unk_fthitmtx_0x0, ft_attack_coll.attack_matrix_mtx, ft_attack_coll.attack_matrix_unk_fthitmtx_0x44)
		ft_attack_coll.attack_matrix_unk_fthitmtx_0x0 = r.arg3
		ft_attack_coll.attack_matrix_unk_fthitmtx_0x44 = r.p_scale

	return func_ovl2_800EEEAC(it_attack_coll.attack_pos[attack_id].pos_curr, it_attack_coll.attack_pos[attack_id].pos_prev, it_attack_coll.size, it_attack_coll.attack_state, ft_attack_coll.attack_matrix_mtx, ft_attack_coll.attack_matrix_unk_fthitmtx_0x0, ft_attack_coll.pos_curr, ft_attack_coll.size, ft_attack_coll.attack_state, ft_attack_coll.attack_matrix_unk_fthitmtx_0x44)

## 0x800F03B8
static func gmCollisionCheckItemAttackFighterDamageCollide(attack_coll: ITAttackColl, attack_id: int, damage_coll: FTDamageColl) -> int:
	var parts: FtParts
	var dobj: DObj

	dobj = damage_coll.joint
	parts = dobj.user_data

	func_ovl2_800EDE00(dobj)
	func_ovl2_800EDE5C(dobj)

	return gmCollisionTestRectangle(attack_coll.attack_pos[attack_id].pos_curr, attack_coll.attack_pos[attack_id].pos_prev, attack_coll.size, attack_coll.attack_state, parts.unk_dobjtrans_0x9C, damage_coll.offset, damage_coll.size, parts.vec_scale)

## 0x800F044C
## C: sb32 (..., f32 *p_angle, Vec3f *vec) -> returns {"ret", "p_angle", "vec"} (in-out; written when ret is TRUE).
static func gmCollisionCheckItemAttackShieldCollide(attack_coll: ITAttackColl, attack_id: int, fighter_gobj, dobj: DObj, p_angle: float = 0.0, vec: Vector3 = Vector3.ZERO) -> Dictionary:
	var parts: FtParts
	var sp58 := Vector3()
	var sp4C := Vector3()

	sp58.x = 0.0
	sp58.y = 0.0
	sp58.z = 0.0

	sp4C.x = 30.0
	sp4C.y = 30.0
	sp4C.z = 30.0

	parts = dobj.user_data

	func_ovl2_800EDE00(dobj)
	func_ovl2_800EDE5C(dobj)

	var r := gmCollisionTestSphere(attack_coll.attack_pos[attack_id].pos_curr, attack_coll.attack_pos[attack_id].pos_prev, attack_coll.size, attack_coll.attack_state, parts.unk_dobjtrans_0x9C, sp58, sp4C, parts.vec_scale, 1, p_angle, vec)
	return {"ret": r.ret, "p_angle": r.p_angle, "vec": r.argA}

## 0x800F0518
static func gmCollisionCheckItemAttackSpecialCollide(attack_coll: ITAttackColl, attack_id: int, fp: Fighter, special_coll: FTSpecialColl) -> int:
	var dobj: DObj = fp.joints[special_coll.joint_id]
	var parts: FtParts = dobj.user_data

	func_ovl2_800EDE00(dobj)
	func_ovl2_800EDE5C(dobj)

	return gmCollisionTestSphere(attack_coll.attack_pos[attack_id].pos_curr, attack_coll.attack_pos[attack_id].pos_prev, attack_coll.size, attack_coll.attack_state, parts.unk_dobjtrans_0x9C, special_coll.offset, special_coll.size, parts.vec_scale, 2, 0.0, Vector3.ZERO).ret

## 0x800F05C8
static func gmCollisionCheckItemAttacksCollide(attack_coll1: ITAttackColl, atk1_id: int, attack_coll2: ITAttackColl, atk2_id: int) -> int:
	if func_ovl2_800EF5D4(attack_coll1.attack_pos[atk1_id].pos_curr, attack_coll1.attack_pos[atk1_id].pos_prev, attack_coll1.size, attack_coll1.attack_state, attack_coll2.attack_pos[atk2_id].pos_curr, attack_coll2.attack_pos[atk2_id].pos_prev, attack_coll2.size, attack_coll2.attack_state) == FALSE:
		return FALSE
	else:
		var r := func_ovl2_800EE050(attack_coll2.attack_state, attack_coll2.attack_pos[atk2_id].pos_curr, attack_coll2.attack_pos[atk2_id].pos_prev, attack_coll2.attack_pos[atk2_id].unk_ithitpos_0x18, attack_coll2.attack_pos[atk2_id].mtx, attack_coll2.attack_pos[atk2_id].unk_ithitpos_0x5C)
		attack_coll2.attack_pos[atk2_id].unk_ithitpos_0x18 = r.arg3
		attack_coll2.attack_pos[atk2_id].unk_ithitpos_0x5C = r.p_scale

	return func_ovl2_800EEEAC(attack_coll1.attack_pos[atk1_id].pos_curr, attack_coll1.attack_pos[atk1_id].pos_prev, attack_coll1.size, attack_coll1.attack_state, attack_coll2.attack_pos[atk2_id].mtx, attack_coll2.attack_pos[atk2_id].unk_ithitpos_0x18, attack_coll2.attack_pos[atk2_id].pos_curr, attack_coll2.size, attack_coll2.attack_state, attack_coll2.attack_pos[atk2_id].unk_ithitpos_0x5C)

## 0x800F06E8
static func gmCollisionCheckItemAttackDamageCollide(attack_coll: ITAttackColl, attack_id: int, damage_coll: ITDamageColl, item_gobj) -> int:
	var damage_coll_pos := Vector3()

	damage_coll_pos.x = DObjGetStruct(item_gobj).translate.x + damage_coll.offset.x
	damage_coll_pos.y = DObjGetStruct(item_gobj).translate.y + damage_coll.offset.y
	damage_coll_pos.z = DObjGetStruct(item_gobj).translate.z + damage_coll.offset.z

	return gmCollisionTestRectangle(attack_coll.attack_pos[attack_id].pos_curr, attack_coll.attack_pos[attack_id].pos_prev, attack_coll.size, attack_coll.attack_state, null, damage_coll_pos, damage_coll.size, DObjGetStruct(item_gobj).scale)

## 0x800F079C
static func gmCollisionCheckWeaponAttackItemDamageCollide(attack_coll: WPAttackColl, attack_id: int, damage_coll: ITDamageColl, item_gobj) -> int:
	var damage_coll_pos := Vector3()

	damage_coll_pos.x = DObjGetStruct(item_gobj).translate.x + damage_coll.offset.x
	damage_coll_pos.y = DObjGetStruct(item_gobj).translate.y + damage_coll.offset.y
	damage_coll_pos.z = DObjGetStruct(item_gobj).translate.z + damage_coll.offset.z

	return gmCollisionTestRectangle(attack_coll.attack_pos[attack_id].pos_curr, attack_coll.attack_pos[attack_id].pos_prev, attack_coll.size, attack_coll.attack_state, null, damage_coll_pos, damage_coll.size, DObjGetStruct(item_gobj).scale)

# ---------------------------------------------------------------------------
# Impact positions. C: void f(Vec3f *dst, ...) with dst a pure output -> f(...) returns dst.
# ---------------------------------------------------------------------------

## 0x800F0850
static func gmCollisionGetFighterAttackPosition(attack_coll: FTAttackColl) -> Vector3:
	var dst := Vector3()

	if attack_coll.attack_state == nGMAttackStateTransfer:
		dst = attack_coll.pos_curr
	else:
		dst.x = (attack_coll.pos_curr.x + attack_coll.pos_prev.x) * 0.5
		dst.y = (attack_coll.pos_curr.y + attack_coll.pos_prev.y) * 0.5
		dst.z = (attack_coll.pos_curr.z + attack_coll.pos_prev.z) * 0.5
	return dst

## 0x800F08C8
static func gmCollisionGetWeaponAttackPosition(attack_coll: WPAttackColl, attack_id: int) -> Vector3:
	var dst := Vector3()

	if attack_coll.attack_state == nGMAttackStateTransfer:
		dst = attack_coll.attack_pos[attack_id].pos_curr
	else:
		dst.x = (attack_coll.attack_pos[attack_id].pos_curr.x + attack_coll.attack_pos[attack_id].pos_prev.x) * 0.5
		dst.y = (attack_coll.attack_pos[attack_id].pos_curr.y + attack_coll.attack_pos[attack_id].pos_prev.y) * 0.5
		dst.z = (attack_coll.attack_pos[attack_id].pos_curr.z + attack_coll.attack_pos[attack_id].pos_prev.z) * 0.5
	return dst

## 0x800F095C
static func gmCollisionGetItemAttackPosition(attack_coll: ITAttackColl, attack_id: int) -> Vector3:
	var dst := Vector3()

	if attack_coll.attack_state == nGMAttackStateTransfer:
		dst = attack_coll.attack_pos[attack_id].pos_curr
	else:
		dst.x = (attack_coll.attack_pos[attack_id].pos_curr.x + attack_coll.attack_pos[attack_id].pos_prev.x) * 0.5
		dst.y = (attack_coll.attack_pos[attack_id].pos_curr.y + attack_coll.attack_pos[attack_id].pos_prev.y) * 0.5
		dst.z = (attack_coll.attack_pos[attack_id].pos_curr.z + attack_coll.attack_pos[attack_id].pos_prev.z) * 0.5
	return dst

## 0x800F09F0
static func gmCollisionGetShieldPosition(gobj, dobj: DObj) -> Vector3:
	var parts: FtParts = dobj.user_data
	var dst := Vector3()

	dst.x = 0.0
	dst.y = 0.0
	dst.z = 0.0

	dst = gmCollisionGetWorldPosition(parts.mtx_translate, dst)

	dst.z = DObjGetStruct(gobj).translate.z
	return dst

## 0x800F0A48
static func gmCollisionGetCommonImpactPosition(pos: Vector3, offset: Vector3) -> Vector3:
	var dst := Vector3()

	dst.x = (pos.x + offset.x) * 0.5
	dst.y = (pos.y + offset.y) * 0.5
	dst.z = (pos.z + offset.z) * 0.5
	return dst

## 0x800F0A90
static func gmCollisionGetFighterAttackDamagePosition(attack_coll: FTAttackColl, damage_coll: FTDamageColl) -> Vector3:
	var parts: FtParts
	var attack_pos: Vector3
	var damage_pos: Vector3

	attack_pos = gmCollisionGetFighterAttackPosition(attack_coll)

	parts = damage_coll.joint.user_data
	damage_pos = damage_coll.offset

	damage_pos = gmCollisionGetWorldPosition(parts.mtx_translate, damage_pos)
	return gmCollisionGetCommonImpactPosition(attack_pos, damage_pos)

## 0x800F0AF8
static func gmCollisionGetFighterAttackItemDamagePosition(attack_coll: FTAttackColl, damage_coll: ITDamageColl, item_gobj) -> Vector3:
	var attack_pos: Vector3
	var damage_pos := Vector3()

	attack_pos = gmCollisionGetFighterAttackPosition(attack_coll)

	damage_pos.x = DObjGetStruct(item_gobj).translate.x + damage_coll.offset.x
	damage_pos.y = DObjGetStruct(item_gobj).translate.y + damage_coll.offset.y
	damage_pos.z = DObjGetStruct(item_gobj).translate.z + damage_coll.offset.z

	return gmCollisionGetCommonImpactPosition(attack_pos, damage_pos)

## 0x800F0B78
static func gmCollisionGetFighterAttackShieldPosition(attack_coll: FTAttackColl, gobj, dobj: DObj) -> Vector3:
	var pos: Vector3
	var offset: Vector3

	pos = gmCollisionGetFighterAttackPosition(attack_coll)
	offset = gmCollisionGetShieldPosition(gobj, dobj)
	return gmCollisionGetCommonImpactPosition(pos, offset)

## 0x800F0BC4
static func gmCollisionGetFighterAttacksPosition(attack_coll1: FTAttackColl, attack_coll2: FTAttackColl) -> Vector3:
	var pos1: Vector3
	var pos2: Vector3

	pos1 = gmCollisionGetFighterAttackPosition(attack_coll1)
	pos2 = gmCollisionGetFighterAttackPosition(attack_coll2)
	return gmCollisionGetCommonImpactPosition(pos1, pos2)

## 0x800F0C08
static func gmCollisionGetWeaponAttackFighterAttackPosition(wp_attack_coll: WPAttackColl, attack_id: int, ft_attack_coll: FTAttackColl) -> Vector3:
	var wp_pos: Vector3
	var ft_pos: Vector3

	wp_pos = gmCollisionGetWeaponAttackPosition(wp_attack_coll, attack_id)
	ft_pos = gmCollisionGetFighterAttackPosition(ft_attack_coll)
	return gmCollisionGetCommonImpactPosition(wp_pos, ft_pos)

## 0x800F0C4C
static func gmCollisionGetWeaponAttackShieldPosition(attack_coll: WPAttackColl, attack_id: int, gobj, dobj: DObj) -> Vector3:
	var wp_pos: Vector3
	var shield_pos: Vector3

	wp_pos = gmCollisionGetWeaponAttackPosition(attack_coll, attack_id)
	shield_pos = gmCollisionGetShieldPosition(gobj, dobj)
	return gmCollisionGetCommonImpactPosition(wp_pos, shield_pos)

## 0x800F0C94
static func gmCollisionGetWeaponAttacksPosition(attack_coll1: WPAttackColl, atk1_id: int, attack_coll2: WPAttackColl, atk2_id: int) -> Vector3:
	var pos1: Vector3
	var pos2: Vector3

	pos1 = gmCollisionGetWeaponAttackPosition(attack_coll1, atk1_id)
	pos2 = gmCollisionGetWeaponAttackPosition(attack_coll2, atk2_id)
	return gmCollisionGetCommonImpactPosition(pos1, pos2)

## 0x800F0CDC
static func gmCollisionGetWeaponAttackItemAttackPosition(wp_attack_coll: WPAttackColl, wp_attack_id: int, it_attack_coll: ITAttackColl, it_attack_id: int) -> Vector3:
	var wp_pos: Vector3
	var it_pos: Vector3

	wp_pos = gmCollisionGetWeaponAttackPosition(wp_attack_coll, wp_attack_id)
	it_pos = gmCollisionGetItemAttackPosition(it_attack_coll, it_attack_id)
	return gmCollisionGetCommonImpactPosition(wp_pos, it_pos)

## 0x800F0D24
static func gmCollisionGetWeaponAttackFighterDamagePosition(attack_coll: WPAttackColl, attack_id: int, damage_coll: FTDamageColl) -> Vector3:
	var parts: FtParts
	var attack_pos: Vector3
	var damage_pos: Vector3

	attack_pos = gmCollisionGetWeaponAttackPosition(attack_coll, attack_id)

	parts = damage_coll.joint.user_data
	damage_pos = damage_coll.offset

	damage_pos = gmCollisionGetWorldPosition(parts.mtx_translate, damage_pos)
	return gmCollisionGetCommonImpactPosition(attack_pos, damage_pos)

## 0x800F0D8C
static func gmCollisionGetWeaponAttackItemDamagePosition(attack_coll: WPAttackColl, attack_id: int, damage_coll: ITDamageColl, item_gobj) -> Vector3:
	var attack_pos: Vector3
	var damage_pos := Vector3()

	attack_pos = gmCollisionGetWeaponAttackPosition(attack_coll, attack_id)

	damage_pos.x = DObjGetStruct(item_gobj).translate.x + damage_coll.offset.x
	damage_pos.y = DObjGetStruct(item_gobj).translate.y + damage_coll.offset.y
	damage_pos.z = DObjGetStruct(item_gobj).translate.z + damage_coll.offset.z

	return gmCollisionGetCommonImpactPosition(attack_pos, damage_pos)

## 0x800F0E08
static func gmCollisionGetItemAttackFighterDamagePosition(attack_coll: ITAttackColl, attack_id: int, damage_coll: FTDamageColl) -> Vector3:
	var parts: FtParts
	var attack_pos: Vector3
	var damage_pos: Vector3

	attack_pos = gmCollisionGetItemAttackPosition(attack_coll, attack_id)

	parts = damage_coll.joint.user_data
	damage_pos = damage_coll.offset

	damage_pos = gmCollisionGetWorldPosition(parts.mtx_translate, damage_pos)
	return gmCollisionGetCommonImpactPosition(attack_pos, damage_pos)

## 0x800F0E70
static func gmCollisionGetItemAttackFighterAttackPosition(it_attack_coll: ITAttackColl, attack_id: int, ft_attack_coll: FTAttackColl) -> Vector3:
	var it_pos: Vector3
	var ft_pos: Vector3

	it_pos = gmCollisionGetItemAttackPosition(it_attack_coll, attack_id)
	ft_pos = gmCollisionGetFighterAttackPosition(ft_attack_coll)
	return gmCollisionGetCommonImpactPosition(it_pos, ft_pos)

## 0x800F0EB4
static func gmCollisionGetItemAttackShieldPosition(attack_coll: ITAttackColl, attack_id: int, gobj, dobj: DObj) -> Vector3:
	var it_pos: Vector3
	var shield_pos: Vector3

	it_pos = gmCollisionGetItemAttackPosition(attack_coll, attack_id)
	shield_pos = gmCollisionGetShieldPosition(gobj, dobj)
	return gmCollisionGetCommonImpactPosition(it_pos, shield_pos)

## 0x800F0EFC
static func gmCollisionGetItemAttackItemAttackPosition(attack_coll1: ITAttackColl, atk1_id: int, attack_coll2: ITAttackColl, atk2_id: int) -> Vector3:
	var pos1: Vector3
	var pos2: Vector3

	pos1 = gmCollisionGetItemAttackPosition(attack_coll1, atk1_id)
	pos2 = gmCollisionGetItemAttackPosition(attack_coll2, atk2_id)
	return gmCollisionGetCommonImpactPosition(pos1, pos2)

## 0x800F0F44
static func gmCollisionGetItemAttackItemDamagePosition(attack_coll: ITAttackColl, attack_id: int, damage_coll: ITDamageColl, item_gobj) -> Vector3:
	var attack_pos: Vector3
	var damage_pos := Vector3()

	attack_pos = gmCollisionGetItemAttackPosition(attack_coll, attack_id)

	damage_pos.x = DObjGetStruct(item_gobj).translate.x + damage_coll.offset.x
	damage_pos.y = DObjGetStruct(item_gobj).translate.y + damage_coll.offset.y
	damage_pos.z = DObjGetStruct(item_gobj).translate.z + damage_coll.offset.z

	return gmCollisionGetCommonImpactPosition(attack_pos, damage_pos)

## 0x800F0FC0
static func gmCollisionGetDamageSlashRotation(fp: Fighter, attack_coll: FTAttackColl) -> float:
	var pos := Vector2()

	if attack_coll.attack_state == nGMAttackStateTransfer:
		pos.x = fp.physics.vel_air.x
		pos.y = fp.physics.vel_air.y
	else:
		pos.x = attack_coll.pos_curr.x - attack_coll.pos_prev.x
		pos.y = attack_coll.pos_curr.y - attack_coll.pos_prev.y
	return syUtilsArcTan2(pos.y, pos.x)
