# PARTIAL PORT of src/lb/lbcommon.c: DObj tree setup/animation helpers are ported; the remaining
# functions (matrix builders, sprite drawing, misc math) are display-side stubs.
class_name Lbcommon
extends Port

static func lbCommonNormDist2D(vec = null):
	var magnitude: float = sqrtf(SQUARE(vec.x) + SQUARE(vec.y))
	if magnitude == 0.0:
		return {"ret": 0.0, "vec": vec}
	var factor: float = 1.0 / magnitude
	var out: Vector3 = vec
	out.x = vec.x * factor
	out.y = vec.y * factor
	return {"ret": magnitude, "vec": out}

## 0x800C7A84

static func lbCommonMag2D(vec = null):
	return sqrtf(SQUARE(vec.x) + SQUARE(vec.y))

## 0x800C7AB8 - a += b (x/y); C returns a, so the updated a is returned

static func lbCommonAdd2D(a = null, b = null):
	var out: Vector3 = a
	out.x = a.x + b.x
	out.y = a.y + b.y
	return out

## 0x800C7AE0 - vec *= factor (x/y); returns the updated vec

static func lbCommonScale2D(vec = null, factor = null):
	var out: Vector3 = vec
	out.x = vec.x * factor
	out.y = vec.y * factor
	return out

## 0x800C7B08 - reflect a about normal b (x/y); returns the updated a

static func lbCommonReflect2D(a = null, b = null):
	var negative_two_dot_product: float = (b.x * a.x + b.y * a.y) * -2.0
	var out: Vector3 = a
	out.x = a.x + b.x * negative_two_dot_product
	out.y = a.y + b.y * negative_two_dot_product
	return out

## 0x800C7B58

static func lbCommonSim3D(a = null, b = null):
	var magnitude_a: float = sqrtf(SQUARE(a.x) + SQUARE(a.y) + SQUARE(a.z))
	var magnitude_b: float = sqrtf(SQUARE(b.x) + SQUARE(b.y) + SQUARE(b.z))
	return (a.x * b.x + a.y * b.y + a.z * b.z) / (magnitude_b + magnitude_a)

## 0x800C7C0C

static func lbCommonSim2D(a = null, b = null):
	var magnitude_a: float = sqrtf(SQUARE(a.x) + SQUARE(a.y))
	var magnitude_b: float = sqrtf(SQUARE(b.x) + SQUARE(b.y))
	return (a.x * b.x + a.y * b.y) / (magnitude_b + magnitude_a)

## 0x800C7C98 - a is modified in place: returns {"ret": sb32, "a": updated a}

static func lbCommonCheckAdjustSim2D(a = null, b = null, angle = null):
	var similarity: float = lbCommonSim2D(b, a)
	if similarity <= 0.0:
		if similarity >= cos(angle + F_CST_DTOR32(90.0)):
			var orientation: float = b.x * a.y - b.y * a.x
			orientation = -1.0 if (orientation < 0.0) else 1.0
			var magnitude: float = lbCommonMag2D(a) * orientation
			var out: Vector3 = a
			out.x = -b.y * magnitude
			out.y = b.x * magnitude
			return {"ret": TRUE, "a": out}
	return {"ret": FALSE, "a": a}

## 0x800CD5AC - out = a x b (pure output, returned)

static func lbCommonMatrixTraRotScaInv(mtx = null, trax = null, tray = null, traz = null, rotx = null, roty = null, rotz = null, scax_inv = null, scay_inv = null, scaz_inv = null, scax = null, scay = null, scaz = null):
	StubLog.hit("Lbcommon.lbCommonMatrixTraRotScaInv")
	return null

static func lbCommonMatrixRotSca(mtx = null, rotx = null, roty = null, rotz = null, scax = null, scay = null, scaz = null):
	StubLog.hit("Lbcommon.lbCommonMatrixRotSca")
	return null

static func lbCommonFuncUpdate():
	StubLog.hit("Lbcommon.lbCommonFuncUpdate")
	return null

static func lbCommonMakePositionFGM(fgm = null, pos = null):
	StubLog.hit("Lbcommon.lbCommonMakePositionFGM")
	return null

static func lbCommonAddDObjAnimJointAll(root_dobj = null, anim_joints = null, anim_frame = null):
	var current_dobj: DObj = root_dobj
	root_dobj.parent_gobj.anim_frame = anim_frame
	var idx := 0
	while current_dobj != null:
		var anim_joint = anim_joints[idx] if idx < anim_joints.size() else null
		if anim_joint != null:
			ObjAnim.gcAddDObjAnimJoint(current_dobj, anim_joint, anim_frame)
		else:
			current_dobj.anim_wait = AOBJ_ANIM_NULL
		idx += 1
		current_dobj = ObjAnim.lbCommonGetTreeDObjNextFromRoot(current_dobj, root_dobj)

## 0x800C89BC - matrix kinds (XObjs) only select the display-time matrix builders; the
## transform defaults are what gameplay sees.

static func lbCommonInitDObj3Transforms(dobj = null, tk1 = null, tk2 = null, tk3 = null):
	dobj.translate = Vector3.ZERO
	dobj.rotate = Vector3.ZERO
	dobj.scale = Vector3.ONE

## 0x800C8A58 - gcAddXObjForDObjFixed(dobj, tk, arg4) stores arg4 in xobj->unk05

static func lbCommonInitDObj(dobj = null, tk1 = null, tk2 = null, tk3 = null, arg4 = null):
	if tk1 != nGCMatrixKindNull:
		dobj.xobj_unk05 = arg4
	dobj.translate = Vector3.ZERO
	dobj.rotate = Vector3.ZERO
	dobj.scale = Vector3.ONE

## 0x800C8B28 - dobjdesc: Array of {id, dl, translate, rotate, scale} (terminator omitted);
## returns the created DObjs in desc order (C: DObj **dobjs out array).

static func lbCommonSetupTreeDObjs(root_dobj = null, dobjdesc = null, dobjs = null, tk1 = null, tk2 = null, tk3 = null):
	var array_dobjs := []
	array_dobjs.resize(DOBJ_ARRAY_MAX)
	var created := []
	for d in dobjdesc:
		if int(d.id) == DOBJ_ARRAY_MAX:
			break
		var id: int = int(d.id) & 0xFFF
		var current_dobj: DObj
		if id != 0:
			current_dobj = Objman.gcAddChildForDObj(array_dobjs[id - 1], d.get("dl", null))
		else:
			current_dobj = Objman.gcAddChildForDObj(root_dobj, d.get("dl", null))
		array_dobjs[id] = current_dobj
		current_dobj.translate = d.translate
		current_dobj.rotate = d.rotate
		current_dobj.scale = d.scale
		created.append(current_dobj)
	return created

## 0x800C8CB8 - material objects (textures / material animations) are display-only.

static func lbCommonAddMObjForFighterPartsDObj(dobj = null, mobjsubs = null, costume_matanim_joints = null, main_matanim_joints = null, anim_frame = null):
	return null

## 0x800C8DB4 (lbCommonSetupFighterPartsDObjs)
## commonparts: FtData.commonparts ([high, low] DObjDesc arrays); dobjs: fp.joints (filled
## from index nFTPartsJointCommonStart, like C passes &fp->joints[4]).

static func lbCommonSetupFighterPartsDObjs(root_dobj = null, commonparts_container = null, detail_curr = null, dobjs = null, setup_parts = null, tk1 = null, tk2 = null, tk3 = null, anim_frame = null, arg9 = null):
	var commonparts: Array = commonparts_container
	var dobjdesc: Array = commonparts[detail_curr - 1]
	var flags0: int = int(setup_parts[0]) & 0xFFFFFFFF
	var flags1: int = int(setup_parts[1]) & 0xFFFFFFFF
	var array_dobjs := []
	array_dobjs.resize(DOBJ_ARRAY_MAX)
	var i := 0
	while ((flags0 != 0) or (flags1 != 0)) and (i < dobjdesc.size()) and (int(dobjdesc[i].id) != DOBJ_ARRAY_MAX):
		var current_flags: int = flags0 if (i < 32) else flags1
		if current_flags & (1 << 31):
			var id: int = int(dobjdesc[i].id) & 0xFFF
			var detail_id: int
			if (detail_curr == nFTPartsDetailHigh) or (commonparts[nFTPartsDetailLow - nFTPartsDetailStart][i].dl == null):
				detail_id = 0
			else:
				detail_id = 1
			var current_dobj: DObj
			if id != 0:
				current_dobj = Objman.gcAddChildForDObj(array_dobjs[id - 1], commonparts[detail_id][i].dl)
			else:
				current_dobj = Objman.gcAddChildForDObj(root_dobj, commonparts[detail_id][i].dl)
			array_dobjs[id] = current_dobj
			if not (int(dobjdesc[i].id) & 0x8000):
				lbCommonInitDObj(current_dobj, tk1, tk2, tk3, arg9)
			current_dobj.translate = dobjdesc[i].translate
			current_dobj.rotate = dobjdesc[i].rotate
			current_dobj.scale = dobjdesc[i].scale
			lbCommonAddMObjForFighterPartsDObj(current_dobj, null, null, null, anim_frame)
			if dobjs != null:
				dobjs[nFTPartsJointCommonStart + i] = current_dobj
		if i < 32:
			flags0 = (flags0 << 1) & 0xFFFFFFFF
		else:
			flags1 = (flags1 << 1) & 0xFFFFFFFF
		i += 1

## 0x800C9228

static func lbCommonSetupCustomTreeDObjsWithMObj(root_dobj = null, dobjdesc = null, p_mobjsubs = null, dobjs = null, tk1 = null, tk2 = null, tk3 = null):
	StubLog.hit("Lbcommon.lbCommonSetupCustomTreeDObjsWithMObj")
	return null

static func lbCommonAddMObjForTreeDObjs(root_dobj = null, p_mobjsubs = null):
	StubLog.hit("Lbcommon.lbCommonAddMObjForTreeDObjs")
	return null

static func lbCommonPlayTreeDObjsAnim(root_dobj = null):
	var current_dobj: DObj = root_dobj
	while current_dobj != null:
		ObjAnim.gcPlayDObjAnimJoint(current_dobj)
		current_dobj = ObjAnim.lbCommonGetTreeDObjNextFromRoot(current_dobj, root_dobj)

## 0x800C9314

static func lbCommonSetDObjTransformsForTreeDObjs(root_dobj = null, dobjdesc = null):
	var current_dobj: DObj = root_dobj
	var i := 0
	while (current_dobj != null) and (i < dobjdesc.size()) and (int(dobjdesc[i].id) != DOBJ_ARRAY_MAX):
		current_dobj.translate = dobjdesc[i].translate
		current_dobj.rotate = dobjdesc[i].rotate
		current_dobj.scale = dobjdesc[i].scale
		i += 1
		current_dobj = ObjAnim.lbCommonGetTreeDObjNextFromRoot(current_dobj, root_dobj)

## 0x800C93D4

static func lbCommonInsertTreeDObjChild(root_dobj = null, dvar = null):
	var dobj: DObj = Objman.gcAddDObjForGObj(root_dobj.parent_gobj, dvar)
	dobj.sib_prev.sib_next = null
	dobj.sib_prev = null
	root_dobj.child.parent = dobj
	dobj.child = root_dobj.child
	root_dobj.child = dobj
	dobj.parent = root_dobj

## 0x800C9424

static func lbCommonEjectTreeDObj(dobj = null):
	var child_dobj: DObj = dobj.child
	var parent_dobj: DObj = dobj.parent
	dobj.child = null
	Objman.gcEjectDObj(dobj)
	if parent_dobj == null:
		child_dobj.parent_gobj.dobj = child_dobj
	else:
		parent_dobj.child = child_dobj
	child_dobj.parent = parent_dobj

static func lbCommonPlayTranslateScaledDObjAnim(dobj = null, scale = null):
	ObjAnim.lbCommonPlayTranslateScaledDObjAnim(dobj, scale)

static func func_ovl0_800C96DC(mtx = null, dobj = null, dls = null):
	StubLog.hit("Lbcommon.func_ovl0_800C96DC")
	return null

static func func_ovl0_800C96EC(mtx = null, dobj = null, dls = null):
	StubLog.hit("Lbcommon.func_ovl0_800C96EC")
	return 0

static func func_ovl0_800C9714(mtx = null, dobj = null, dls = null):
	StubLog.hit("Lbcommon.func_ovl0_800C9714")
	return 0

static func lbCommonFighterPartsFuncMatrix(mtx = null, dobj = null, dls = null):
	StubLog.hit("Lbcommon.lbCommonFighterPartsFuncMatrix")
	return 0

static func func_ovl0_800C994C(mtx = null, dobj = null, dls = null):
	StubLog.hit("Lbcommon.func_ovl0_800C994C")
	return 0

static func func_ovl0_800C99CC(mtx = null, dobj = null, dls = null):
	StubLog.hit("Lbcommon.func_ovl0_800C99CC")
	return 0

## C f32 arithmetic (single-precision rounding of every intermediate result).
static func _f32s(x: float) -> float:
	return Vector2(x, 0.0).x

## sqrtf(SQUARE(m[row][0]) + SQUARE(m[row][1]) + SQUARE(m[row][2])) evaluated in f32.
static func _f32_row_mag(m: PackedFloat32Array, row: int) -> float:
	var sum: float = _f32s(_f32s(_f32s(m[row * 3 + 0] * m[row * 3 + 0]) + _f32s(m[row * 3 + 1] * m[row * 3 + 1])) + _f32s(m[row * 3 + 2] * m[row * 3 + 2]))

	return _f32s(sqrtf(sum))

## 0x800C9A38 - 1:1 port of func_ovl0_800C9A38 (src/lb/lbcommon.c, 0x800C9A38): world matrix of a fighter
## joint with the scale removed from every row (Mtx44f = 4x3 row-major PackedFloat32Array, see
## Gmcollision). Used by the grab code to place a captured fighter on the thrower's hand. Writes mtx in place and returns it.
static func func_ovl0_800C9A38(mtx = null, dobj = null):
	if mtx == null:
		mtx = PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
	var parts: FtParts = dobj.user_data
	var fp := ftGetStruct(dobj.parent_gobj)
	var p: PackedFloat32Array
	var scale: float
	var parent_dobj: DObj
	var f := PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])   # Mtx44f f
	var i: int

	if B(fp.is_use_animlocks) or (dobj.parent == DOBJ_PARENT_NULL):
		Gmcollision.func_ovl2_800EDBA4(dobj)

		p = parts.mtx_translate

		i = 0
		while i < 3:
			scale = _f32_row_mag(p, i)

			if scale != 0.0:
				scale = _f32s(1.0 / scale)
			mtx[i * 3 + 0] = p[i * 3 + 0] * scale
			mtx[i * 3 + 1] = p[i * 3 + 1] * scale
			mtx[i * 3 + 2] = p[i * 3 + 2] * scale
			i += 1
		mtx[9] = p[9]
		mtx[10] = p[10]
		mtx[11] = p[11]
	else:
		parent_dobj = dobj.parent

		Gmcollision.gmCollisionTransformMatrixAll(dobj, parts, parts.unk_dobjtrans_0x10)

		p = parts.unk_dobjtrans_0x10

		i = 0
		while i < 3:
			scale = _f32_row_mag(p, i)

			if scale != 0.0:
				scale = _f32s(1.0 / scale)
			f[i * 3 + 0] = p[i * 3 + 0] * scale
			f[i * 3 + 1] = p[i * 3 + 1] * scale
			f[i * 3 + 2] = p[i * 3 + 2] * scale
			i += 1
		f[9] = p[9]
		f[10] = p[10]
		f[11] = p[11]

		Gmcollision.func_ovl2_800EDBA4(parent_dobj)

		p = parent_dobj.user_data.mtx_translate

		# column j of f is divided by the scale of row j of the parent's world matrix
		i = 0
		while i < 3:
			scale = _f32_row_mag(p, i)

			if scale != 0.0:
				scale = _f32s(1.0 / scale)
			f[0 * 3 + i] *= scale
			f[1 * 3 + i] *= scale
			f[2 * 3 + i] *= scale
			i += 1
		Gmcollision.func_ovl2_800ED490(mtx, p, f)
	return mtx


static func func_ovl0_800C9F30(mtx = null, dobj = null, dls = null):
	StubLog.hit("Lbcommon.func_ovl0_800C9F30")
	return 0

static func func_ovl0_800C9F70(mtx = null, dobj = null, dls = null):
	StubLog.hit("Lbcommon.func_ovl0_800C9F70")
	return 0

static func func_ovl0_800CA024(mtx = null, dobj = null, dls = null):
	StubLog.hit("Lbcommon.func_ovl0_800CA024")
	return 0

static func lbCommonRotScaFuncMatrix(mtx = null, dobj = null, dls = null):
	StubLog.hit("Lbcommon.lbCommonRotScaFuncMatrix")
	return 0

static func func_ovl0_800CA194(mtx = null, dobj = null, dls = null):
	StubLog.hit("Lbcommon.func_ovl0_800CA194")
	return 0

static func func_ovl0_800CA5C8(mtx = null, dobj = null, dls = null):
	StubLog.hit("Lbcommon.func_ovl0_800CA5C8")
	return 0

static func func_ovl0_800CAB48(mtx = null, dobj = null, dls = null):
	StubLog.hit("Lbcommon.func_ovl0_800CAB48")
	return 0

static func func_ovl0_800CB140(mtx = null, dobj = null, dls = null):
	StubLog.hit("Lbcommon.func_ovl0_800CB140")
	return 0

static func func_ovl0_800CB2F0(mtx = null, dobj = null, dls = null):
	StubLog.hit("Lbcommon.func_ovl0_800CB2F0")
	return 0

static func lbCommonDrawDObjScaleX(dobj = null):
	StubLog.hit("Lbcommon.lbCommonDrawDObjScaleX")
	return null

static func lbCommonDObjScaleXProcDisplay(gobj = null):
	StubLog.hit("Lbcommon.lbCommonDObjScaleXProcDisplay")
	return null

static func lbCommonDrawDObjDefault(dobj = null):
	StubLog.hit("Lbcommon.lbCommonDrawDObjDefault")
	return null

static func lbCommonEjectGObjLinkedList(gobj = null):
	StubLog.hit("Lbcommon.lbCommonEjectGObjLinkedList")
	return null

static func lbCommonGetBitmapDecodeNibble(index = null):
	StubLog.hit("Lbcommon.lbCommonGetBitmapDecodeNibble")
	return 0

static func lbCommonDecodeBitmapSiz4b(bitmap_csr = null, bitmap_buf = null, bitmap_start = null):
	StubLog.hit("Lbcommon.lbCommonDecodeBitmapSiz4b")
	return null

static func lbCommonDecodeSpriteBitmapsSiz4b(sprite = null):
	StubLog.hit("Lbcommon.lbCommonDecodeSpriteBitmapsSiz4b")
	return null

static func lbCommonDrawSObjBitmap(dls = null, sobj = null, sprite = null, bitmap = null, x = null, y = null, xx = null, yy = null, fs = null, ft = null, sx = null, sy = null):
	StubLog.hit("Lbcommon.lbCommonDrawSObjBitmap")
	return null

static func lbCommonPrepSObjAttr(dls = null, sobj = null):
	StubLog.hit("Lbcommon.lbCommonPrepSObjAttr")
	return null

static func lbCommonClearExternSpriteParams():
	StubLog.hit("Lbcommon.lbCommonClearExternSpriteParams")
	return null

static func lbCommonSetExternSpriteParams(sprite = null):
	StubLog.hit("Lbcommon.lbCommonSetExternSpriteParams")
	return null

static func lbCommonDrawSObjAttr(gobj = null):
	StubLog.hit("Lbcommon.lbCommonDrawSObjAttr")
	return null

static func lbCommonDrawSObjNoAttr(gobj = null):
	StubLog.hit("Lbcommon.lbCommonDrawSObjNoAttr")
	return null

static func lbCommonMakeSObjForGObj(gobj = null, sprite = null):
	StubLog.hit("Lbcommon.lbCommonMakeSObjForGObj")
	return null

static func lbCommonMakeSpriteGObj(id = null, func_run = null, link = null, link_priority = null, proc_display = null, dl_link = null, dl_link_priority = null, camera_tag = null, sprite = null, gobjproc_kind = null, proc = null, gobjproc_priority = null):
	StubLog.hit("Lbcommon.lbCommonMakeSpriteGObj")
	return null

static func lbCommonStartSprite(dls = null):
	StubLog.hit("Lbcommon.lbCommonStartSprite")
	return null

static func lbCommonSetSpriteScissor(xmin = null, xmax = null, ymin = null, ymax = null):
	StubLog.hit("Lbcommon.lbCommonSetSpriteScissor")
	return null

static func lbCommonFinishSprite(dls = null):
	StubLog.hit("Lbcommon.lbCommonFinishSprite")
	return null

static func lbCommonDrawSprite(camera_gobj = null):
	StubLog.hit("Lbcommon.lbCommonDrawSprite")
	return null

static func lbCommonInitCameraOrtho(cobj = null, tk = null, arg2 = null):
	StubLog.hit("Lbcommon.lbCommonInitCameraOrtho")
	return null

static func lbCommonInitCameraPersp(cobj = null, tk = null, arg2 = null):
	StubLog.hit("Lbcommon.lbCommonInitCameraPersp")
	return null

static func lbCommonInitCameraVec(cobj = null, tk = null, arg2 = null):
	StubLog.hit("Lbcommon.lbCommonInitCameraVec")
	return null

static func lbCommonCross3D(a = null, b = null, out = null):
	return Vector3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
