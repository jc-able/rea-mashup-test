## 1:1 port of src/gm/gmcamera.c (ssb-decomp-re): the battle camera.
##
## The camera logic is ported exactly: status machine (dGMCameraFuncList / gmCameraSetStatus*),
## interest gathering over fighters and camera-following weapons (gmCameraUpdateInterests),
## stage camera bounds, zoom distance (target_dist) easing, at/eye panning, FOV easing, the pause
## camera angles (gGMCameraPauseCameraEyeX/Y) and the Zebes / Inishie / player-zoom / player-follow /
## map-zoom / animated variants.
##
## Rendering adaptations (CObj / display lists / fixed-point matrices):
##   * CObj (src/sys/objtypes.h) is the inner class Gmcamera.CObj, stored in the camera GObj's
##     user_data; CObjGetStruct(gobj) returns it. C field paths are kept: cobj.vec.eye/at/up,
##     cobj.projection.persp.fovy/aspect/near/far/scale/norm, cobj.viewport.vp.vscale/vtrans,
##     cobj.anim_wait, cobj.flags.
##   * Camera GObjs are created by _gcMakeCameraGObj (mirror of gcMakeCameraGObj, which is not
##     implemented in Objhelper): Objman.gcMakeGObjSPAfter + CObj + process via Objman.gcAddGObjProcess
##     (the battle camera runs gmCameraRunFuncCamera at process priority 3 every frame) and
##     gobj.display_proc = proc_display.
##   * RENDER OUTPUT for the Godot renderer (main camera, N64 world units, +Y up):
##       Gmcamera.gGMCameraRenderEye, gGMCameraRenderAt, gGMCameraRenderUp : Vector3 (look-at)
##       Gmcamera.gGMCameraRenderFovy   : float, vertical field of view in degrees
##       Gmcamera.gGMCameraRenderAspect, gGMCameraRenderNear, gGMCameraRenderFar : float
##     They are copied from the main camera CObj after every gmCameraRunFuncCamera (the camera
##     process, once per frame), on creation, and by gmCameraLookAtFuncMatrix (display).
##   * gmCameraLookAtFuncMatrix builds gGMCameraMatrix = lookAt x perspective as a
##     PackedFloat32Array(16), row-major [i*4+j] (row vectors: clip = [x y z 1] * M), used by the
##     interface to project world positions to the screen. The perspective uses __sinf/__cosf
##     instead of the gSYSinTable lookup of syMatrixPerspFastF (sys/matrix.c is not ported); the
##     fixed-point Mtx / GBI command outputs are not produced.
##
## Out-parameter convention (PORTING.md):
##   gmCameraSetBoundsPosition(pos) / gmCameraSetTeamBoundsPosition(pos) /
##   gmCameraSetDeadUpStarPosition(pos)              -> Vector3 (new pos)
##   gmCameraUpdateInterests()                        -> {"vec": Vector3, "hz": float, "vt": float}
##   gmCameraGetClampDimensionsMax(hz, vt)            -> float max
##   gmCameraGetAdjustAtAngle(at, x, y)               -> Vector3 vec
##   func_ovl2_8010C3C0(at)                           -> Vector3 vec
##   gmCameraUpdateInishieFocus(arg0)                 -> Vector3 arg1
class_name Gmcamera
extends Port

## Exact f32 values of C's F_CLC_DTOR32(<literal>) = (float)((x * 3.1415927F) / 180.0F)
## (they match the constants noted in the decomp comments).
const F_CLC_DTOR32_5 := 0.0872664675116539        # F_CLC_DTOR32(5.0F)    0.08726647F
const F_CLC_DTOR32_N7 := -0.12217305600643158     # F_CLC_DTOR32(-7.0F)   -0.122173056F
const F_CLC_DTOR32_17_5 := 0.30543264746665955    # F_CLC_DTOR32(17.5F)   0.30543265F
const F_CLC_DTOR32_N17_5 := -0.30543264746665955  # F_CLC_DTOR32(-17.5F)  -0.30543265F
const PI32_F32 := 3.1415927410125732              # PI32 (3.1415927F) as the exact f32 value

## F_CLC_DTOR32(x) with a run-time argument: ((x) * PI32) / 180.0F
static func _F_CLC_DTOR32(x: float) -> float:
	return (x * PI32_F32) / 180.0

## COBJ_MASK_DLLINK(r) (1ULL << (r))
static func _COBJ_MASK_DLLINK(r: int) -> int:
	return 1 << r

# ---------------------------------------------------------------------------
# Struct ports
# ---------------------------------------------------------------------------

## Port of GCPersp (src/sys/objtypes.h)
class GCPersp:
	var xobj = null
	var norm: int = 0
	var fovy: float = 0.0
	var aspect: float = 0.0
	var near: float = 0.0
	var far: float = 0.0
	var scale: float = 0.0

	static func make(p_xobj, p_norm: int, p_fovy: float, p_aspect: float, p_near: float, p_far: float, p_scale: float) -> GCPersp:
		var p := GCPersp.new()
		p.xobj = p_xobj
		p.norm = p_norm
		p.fovy = p_fovy
		p.aspect = p_aspect
		p.near = p_near
		p.far = p_far
		p.scale = p_scale
		return p

	func copy_from(o: GCPersp) -> void:
		xobj = o.xobj
		norm = o.norm
		fovy = o.fovy
		aspect = o.aspect
		near = o.near
		far = o.far
		scale = o.scale

## Port of GCOrtho (src/sys/objtypes.h)
class GCOrtho:
	var xobj = null
	var l: float = 0.0
	var r: float = 0.0
	var b: float = 0.0
	var t: float = 0.0
	var n: float = 0.0
	var f: float = 0.0
	var scale: float = 0.0

## Port of union CameraProjection (persp / ortho / frustum are separate objects here)
class CameraProjection:
	var persp: GCPersp = GCPersp.new()
	var ortho: GCOrtho = GCOrtho.new()
	var frustum = null

## Port of CObjVec (src/sys/objtypes.h)
class CObjVec:
	var xobj = null
	var eye: Vector3 = Vector3.ZERO
	var at: Vector3 = Vector3.ZERO
	var up: Vector3 = Vector3.ZERO

	static func make(p_xobj, p_eye: Vector3, p_at: Vector3, p_up: Vector3) -> CObjVec:
		var v := CObjVec.new()
		v.xobj = p_xobj
		v.eye = p_eye
		v.at = p_at
		v.up = p_up
		return v

	func copy_from(o: CObjVec) -> void:
		xobj = o.xobj
		eye = o.eye
		at = o.at
		up = o.up

## Port of CObj (src/sys/objtypes.h), initialised like gcAddCameraForGObj
## (viewport = syRdpSetDefaultViewport for 320x240, anim_wait = AOBJ_ANIM_NULL, ...).
class CObj:
	var next = null
	var parent_gobj = null
	var viewport: Dictionary = {"vp": {"vscale": [320 * 2, 240 * 2, 0x03FF / 2, 0], "vtrans": [320 * 2, 240 * 2, 0x03FF / 2, 0]}}
	var projection: CameraProjection = CameraProjection.new()
	var vec: CObjVec = CObjVec.new()
	var xobjs_num: int = 0
	var xobjs: Array = [null, null]
	var aobj = null
	var camanim_joint = null
	var anim_wait: float = SSBDefs.AOBJ_ANIM_NULL
	var anim_speed: float = 1.0
	var anim_frame: float = 0.0
	var flags: int = SSBDefs.COBJ_FLAG_NONE
	var color: int = 0
	var func_camera: Callable = Callable()
	var unk_camera_0x8C: int = 0
	# port-only: C keeps these on the camera GObj / in display-list state
	var camera_mask: int = 0
	var camera_tag: int = 0
	var dl_link_priority: int = 0
	var scissor: Array = [0, 0, 0, 0]

## Port of GMCamera (src/gm/gmtypes.h)
class GMCamera:
	var status_default: int = 0
	var status_curr: int = 0
	var status_prev: int = 0
	var func_camera: Callable = Callable()
	var target_dist: float = 0.0
	var vel_at: Vector3 = Vector3.ZERO
	var viewport_ulx: int = 0
	var viewport_uly: int = 0
	var viewport_lrx: int = 0
	var viewport_lry: int = 0
	var viewport_center_x: int = 0
	var viewport_center_y: int = 0
	var viewport_width: int = 0
	var viewport_height: int = 0
	var fovy: float = 0.0
	var pzoom_fighter_gobj = null      # Guess: this is a struct from here...
	var pzoom_eye_x: float = 0.0
	var pzoom_eye_y: float = 0.0
	var pzoom_dist: float = 0.0
	var pzoom_pan_scale: float = 0.0
	var pzoom_fov: float = 0.0
	var zoom_origin_pos: Vector3 = Vector3.ZERO
	var zoom_target_pos: Vector3 = Vector3.ZERO   # ...to here
	var pfollow_fighter_gobj = null    # ...and there is an array of it
	var pfollow_eye_x: float = 0.0
	var pfollow_eye_y: float = 0.0
	var pfollow_dist: float = 0.0
	var pfollow_pan_scale: float = 0.0
	var pfollow_fov: float = 0.0
	var vel_all: Vector3 = Vector3.ZERO
	## LookAt (reflection lights of syMatrixLookAtReflectF, render only): l[i].dir = right / up
	var look_at: Dictionary = {"l": [{"col": [0, 0, 0], "colc": [0, 0, 0], "dir": [0, 0, 0]}, {"col": [0, 0x80, 0], "colc": [0, 0x80, 0], "dir": [0, 0, 0]}]}

## Port of FTCamera (src/ft/fttypes.h)
class FTCamera:
	var target_fp = null
	var target_pos: Vector3 = Vector3.ZERO
	var unk_ftcobj_0x10: float = 0.0

# // // // // // // // // // // // //
# //                               //
# //       INITIALIZED DATA        //
# //                               //
# // // // // // // // // // // // //

## 0x8012EB70
static var dGMCameraPerspDefault: GCPersp = GCPersp.make(null, 0, 38.0, 15.0 / 11.0, 256.0, 39936.0, 1.0)

## 0x8012EB8C
static var dGMCameraCObjVecDefault: CObjVec = CObjVec.make(null, Vector3(1500.0, 0.0, 0.0), Vector3(0.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0))

## 0x8012EBB4 - indexed by nGMCameraStatus*
static var dGMCameraFuncList: Array = [
	Callable(Gmcamera, &"gmCameraDefaultFuncCamera"),
	Callable(Gmcamera, &"gmCameraPlayerZoomFuncCamera"),
	Callable(Gmcamera, &"gmCameraAnimFuncCamera"),
	Callable(Gmcamera, &"gmCameraInishieFuncCamera"),
	Callable(Gmcamera, &"gmCameraMapZoomFuncCamera"),
	Callable(Gmcamera, &"gmCameraPlayerFollowFuncCamera"),
	Callable(Gmcamera, &"gmCameraZebesFuncCamera"),
]

## 0x8012EBD0
static var dGMCameraPlayerZoomRanges: Array = [
	0.00,   # No players
	1.50,   # 1 Player
	1.32,   # 2 Players
	1.16,   # 3 Players
	1.00,   # 4 Players
]

# // // // // // // // // // // // //
# //                               //
# //   GLOBAL / STATIC VARIABLES   //
# //                               //
# // // // // // // // // // // // //

## 0x80131460
static var gGMCameraGObj = null

## 0x80131464
static var gGMCameraPauseCameraEyeY: float = 0.0

## 0x80131468
static var gGMCameraPauseCameraEyeX: float = 0.0

## 0x80131470 - Mtx44f, row-major [i*4+j]
static var gGMCameraMatrix: PackedFloat32Array = PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

## 0x801314B0
static var gGMCameraStruct: GMCamera = GMCamera.new()

## Port-only: stands in for gGCMatrixPerspF (src/sys/objdisplay.c), the perspective matrix last
## built by gmCameraLookAtFuncMatrix (row-major [i*4+j]).
static var sGMCameraMatrixPerspF: PackedFloat32Array = PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

## Port-only render output (see the file header).
static var gGMCameraRenderEye: Vector3 = Vector3(1500.0, 0.0, 0.0)
static var gGMCameraRenderAt: Vector3 = Vector3(0.0, 0.0, 0.0)
static var gGMCameraRenderUp: Vector3 = Vector3(0.0, 1.0, 0.0)
static var gGMCameraRenderFovy: float = 38.0
static var gGMCameraRenderAspect: float = 15.0 / 11.0
static var gGMCameraRenderNear: float = 256.0
static var gGMCameraRenderFar: float = 39936.0

# ---------------------------------------------------------------------------
# Port helpers
# ---------------------------------------------------------------------------

## C: CObjGetStruct(gobj) ((CObj*)(gobj)->obj). The CObj lives in the camera GObj's user_data.
static func CObjGetStruct(gobj) -> CObj:
	return gobj.user_data if gobj != null else null

## gMPCollisionGroundData (src/mp/mpcollision.c, MPGroundData* -> Dictionary with the C field names:
## camera_bound_*, camera_bound_team_*, map_bound_top (ints), light_angle (Vector3)).
static func _mp_ground_data():
	return Mpcollision.gMPCollisionGroundData

## gIFCommonPlayerInterface (src/if/ifcommon.c). Looked up dynamically (null while Ifcommon is a stub).
static func _if_player_interface():
	var if_script: Object = Ifcommon
	return if_script.get("gIFCommonPlayerInterface")

## C: while (TRUE) { syDebugPrintf(msg); scManagerRunPrintGObjStatus(); } - the N64 hangs printing
## a debug message; the port prints it, reports an error and continues.
static func _gmCameraFatal(msg: String) -> void:
	Debug.syDebugPrintf(msg)
	push_error(msg)

## Copies the main camera's view parameters to the render output vars.
static func _gmCameraPublishRender(cobj: CObj) -> void:
	if (cobj == null) or (gGMCameraGObj == null) or (cobj.parent_gobj != gGMCameraGObj):
		return
	gGMCameraRenderEye = cobj.vec.eye
	gGMCameraRenderAt = cobj.vec.at
	gGMCameraRenderUp = cobj.vec.up
	gGMCameraRenderFovy = cobj.projection.persp.fovy
	gGMCameraRenderAspect = cobj.projection.persp.aspect
	gGMCameraRenderNear = cobj.projection.persp.near
	gGMCameraRenderFar = cobj.projection.persp.far

## Mirror of gcMakeCameraGObj (src/sys/objhelper.c) + gcAddCameraForGObj (src/sys/objman.c).
static func _gcMakeCameraGObj(id: int, func_run, link: int, link_priority: int, proc_display: Callable, dl_link_priority: int, camera_mask: int, camera_tag: int, is_add_default_xobj: int, gobjproc_kind: int, proc: Callable, gobjproc_priority: int, argD: int):
	var gobj = Objman.gcMakeGObjSPAfter(id, func_run, link, link_priority)
	var cobj: CObj

	if gobj == null:
		return null
	# func_80009F74(gobj, proc_display, dl_link_priority, camera_mask, camera_tag): camera display registration
	gobj.display_proc = proc_display

	# gcAddCameraForGObj(gobj) (gobj->obj_kind = nGCCommonAppendCamera; gobj->obj = cobj)
	cobj = CObj.new()
	gobj.user_data = cobj
	cobj.parent_gobj = gobj
	cobj.camera_mask = camera_mask
	cobj.camera_tag = camera_tag
	cobj.dl_link_priority = dl_link_priority

	if is_add_default_xobj != FALSE:
		Objhelper.gcAddCameraMatrixSets(cobj)
	if proc.is_valid():
		Objman.gcAddGObjProcess(gobj, proc, gobjproc_kind, gobjproc_priority)
	if argD != 0:
		cobj.flags = 0x4 | COBJ_FLAG_FILLCOLOR | COBJ_FLAG_ZBUFFER
		cobj.color = 0x000000FF         # GPACK_RGBA8888(0x00, 0x00, 0x00, 0xFF)
	return gobj

## Port of syRdpSetViewport (src/sys/rdp.c) writing a CObj viewport ({"vp": {"vscale", "vtrans"}}).
static func _syRdpSetViewport(viewport: Dictionary, ulx: float, uly: float, lrx: float, lry: float) -> void:
	var h: float = (ulx + lrx) / 2.0
	var v: float = (uly + lry) / 2.0

	viewport.vp.vscale[0] = (int((lrx - h) * 4.0)) & 0xFFFF
	viewport.vp.vscale[1] = (int((lry - v) * 4.0)) & 0xFFFF
	viewport.vp.vtrans[0] = (int(h * 4.0)) & 0xFFFF
	viewport.vp.vtrans[1] = (int(v * 4.0)) & 0xFFFF

	viewport.vp.vscale[2] = 0x03FF / 2      # G_MAXZ / 2
	viewport.vp.vtrans[2] = 0x03FF / 2

## Port of syMatrixPerspFastF (src/sys/matrix.c) on a 16-float matrix; returns persp_norm.
## Adapted: sin/cos of the half FOV use __sinf/__cosf instead of the gSYSinTable lookup.
static func _syMatrixPerspFastF(mf: PackedFloat32Array, fovy: float, aspect: float, near: float, far: float, scale: float) -> int:
	var cot: float
	var sin_: float
	var cos_: float
	var persp_norm: int

	fovy *= 0.008726646

	sin_ = __sinf(fovy)
	cos_ = __cosf(fovy)

	cot = cos_ / sin_

	mf[0] = (cot / aspect) * scale                          # [0][0]
	mf[5] = cot * scale                                     # [1][1]
	mf[10] = ((near + far) * scale) / (near - far)          # [2][2]
	mf[11] = -scale                                         # [2][3]
	mf[14] = (2.0 * near * far * scale) / (near - far)      # [3][2]
	mf[15] = 0.0                                            # [3][3]

	mf[1] = 0
	mf[2] = 0
	mf[3] = 0

	mf[4] = 0
	mf[6] = 0
	mf[7] = 0

	mf[8] = 0
	mf[9] = 0

	mf[12] = 0
	mf[13] = 0

	if near + far <= 2.0:
		persp_norm = 0xFFFF
	else:
		persp_norm = int((2.0 * 65536.0) / (near + far)) & 0xFFFF

		if persp_norm <= 0:
			persp_norm = 1
	return persp_norm

## Port of the matrix part of syMatrixLookAtF / syMatrixLookAtReflectF (src/sys/matrix.c) on a
## 16-float matrix. Returns [right, up] (the LookAt reflection directions).
static func _syMatrixLookAtF(mf: PackedFloat32Array, eye_x: float, eye_y: float, eye_z: float, at_x: float, at_y: float, at_z: float, up_x: float, up_y: float, up_z: float) -> Array:
	var len_: float
	var look_x: float
	var look_y: float
	var look_z: float
	var right_x: float
	var right_y: float
	var right_z: float

	look_x = at_x - eye_x
	look_y = at_y - eye_y
	look_z = at_z - eye_z

	# Negate because positive Z is behind us:
	len_ = -1.0 / sqrtf(SQUARE(look_x) + SQUARE(look_y) + SQUARE(look_z))
	look_x *= len_
	look_y *= len_
	look_z *= len_

	# Right = Up x Look
	right_x = up_y * look_z - up_z * look_y
	right_y = up_z * look_x - up_x * look_z
	right_z = up_x * look_y - up_y * look_x

	len_ = 1.0 / sqrtf(SQUARE(right_x) + SQUARE(right_y) + SQUARE(right_z))
	right_x *= len_
	right_y *= len_
	right_z *= len_

	# Up = Look x Right
	up_x = look_y * right_z - look_z * right_y
	up_y = look_z * right_x - look_x * right_z
	up_z = look_x * right_y - look_y * right_x

	len_ = 1.0 / sqrtf(SQUARE(up_x) + SQUARE(up_y) + SQUARE(up_z))
	up_x *= len_
	up_y *= len_
	up_z *= len_

	mf[0] = right_x                                                 # [0][0]
	mf[4] = right_y                                                 # [1][0]
	mf[8] = right_z                                                 # [2][0]
	mf[12] = -(eye_x * right_x + eye_y * right_y + eye_z * right_z)  # [3][0]

	mf[1] = up_x                                                    # [0][1]
	mf[5] = up_y                                                    # [1][1]
	mf[9] = up_z                                                    # [2][1]
	mf[13] = -(eye_x * up_x + eye_y * up_y + eye_z * up_z)           # [3][1]

	mf[2] = look_x                                                  # [0][2]
	mf[6] = look_y                                                  # [1][2]
	mf[10] = look_z                                                 # [2][2]
	mf[14] = -(eye_x * look_x + eye_y * look_y + eye_z * look_z)     # [3][2]

	mf[3] = 0                                                       # [0][3]
	mf[7] = 0                                                       # [1][3]
	mf[11] = 0                                                      # [2][3]
	mf[15] = 1                                                      # [3][3]

	return [Vector3(right_x, right_y, right_z), Vector3(up_x, up_y, up_z)]

## Port of syMatrixOrthoF (src/sys/matrix.c) on a 16-float matrix.
static func _syMatrixOrthoF(mf: PackedFloat32Array, l: float, r: float, b: float, t: float, n: float, f: float, scale: float) -> void:
	var i: int
	var j: int

	mf[0] = 2 / (r - l)                 # [0][0]
	mf[5] = 2 / (t - b)                 # [1][1]
	mf[10] = -2 / (f - n)               # [2][2]
	mf[12] = -(r + l) / (r - l)         # [3][0]
	mf[13] = -(t + b) / (t - b)         # [3][1]
	mf[14] = -(f + n) / (f - n)         # [3][2]
	mf[15] = 1                          # [3][3]

	i = 0
	while i < 3:
		if i != 0:
			mf[i * 4 + 0] = 0
		if i != 1:
			mf[i * 4 + 1] = 0
		if i != 2:
			mf[i * 4 + 2] = 0
		if i != 3:
			mf[i * 4 + 3] = 0
		i += 1
	i = 0
	while i < 4:
		j = 0
		while j < 4:
			mf[i * 4 + j] *= scale
			j += 1
		i += 1

## Port of libultra guMtxCatF(mf, nf, res): res = mf x nf (4x4; res may alias an input).
static func _guMtxCatF(mf: PackedFloat32Array, nf: PackedFloat32Array, res: PackedFloat32Array) -> void:
	var temp := PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	var i: int
	var j: int
	var k: int

	i = 0
	while i < 4:
		j = 0
		while j < 4:
			temp[i * 4 + j] = 0.0
			k = 0
			while k < 4:
				temp[i * 4 + j] += mf[i * 4 + k] * nf[k * 4 + j]
				k += 1
			j += 1
		i += 1
	i = 0
	while i < 16:
		res[i] = temp[i]
		i += 1

## Port of func_ovl2_800EB924 (src/ft/ftparam.c): project a world position with a 16-float camera
## matrix to viewport coordinates. Inlined for the magnifier because Ftparam's port leaves it as
## a render-side stub. Returns Vector2(rx, ry).
static func _gmCameraProjectScreen(cobj: CObj, mtx: PackedFloat32Array, vec: Vector3) -> Vector2:
	var x: float = vec.x
	var y: float = vec.y
	var z: float = vec.z
	var tempx: float = ((mtx[0] * x) + (mtx[4] * y) + (mtx[8] * z)) + mtx[12]
	var tempy: float = ((mtx[1] * x) + (mtx[5] * y) + (mtx[9] * z)) + mtx[13]
	var scale: float = ((mtx[3] * x) + (mtx[7] * y) + (mtx[11] * z)) + mtx[15]

	if ABSF(scale) < 0.1:
		scale = -0.1 if (scale < 0.0) else 0.1
	scale = 1.0 / scale

	return Vector2((cobj.viewport.vp.vscale[0] / 4) * (tempx * scale), (cobj.viewport.vp.vscale[1] / 4) * (tempy * scale))

# // // // // // // // // // // // //
# //                               //
# //           FUNCTIONS           //
# //                               //
# // // // // // // // // // // // //

## 0x8010B810
static func gmCameraGetBoundsMask(pos: Vector3) -> int:
	var gd = _mp_ground_data()
	var bounds: int = 0

	if pos.x < gd.camera_bound_left:
		bounds |= CAMERA_FLAG_BOUND_LEFT
	if pos.x > gd.camera_bound_right:
		bounds |= CAMERA_FLAG_BOUND_RIGHT
	if pos.y < gd.camera_bound_bottom:
		bounds |= CAMERA_FLAG_BOUND_BOTTOM
	if pos.y > gd.camera_bound_top:
		bounds |= CAMERA_FLAG_BOUND_TOP
	return bounds

## 0x8010B8BC
## C: void (Vec3f *pos) - pos in-out -> returns the clamped pos.
static func gmCameraSetBoundsPosition(pos: Vector3) -> Vector3:
	var gd = _mp_ground_data()

	while true:
		var bounds: int = gmCameraGetBoundsMask(pos)

		if bounds != 0:
			if bounds & CAMERA_FLAG_BOUND_LEFT:
				pos.x = gd.camera_bound_left
			elif bounds & CAMERA_FLAG_BOUND_RIGHT:
				pos.x = gd.camera_bound_right
			elif bounds & CAMERA_FLAG_BOUND_BOTTOM:
				pos.y = gd.camera_bound_bottom
			elif bounds & CAMERA_FLAG_BOUND_TOP:
				pos.y = gd.camera_bound_top
		else:
			break
	return pos

## 0x8010B98C
static func gmCameraGetTeamBoundsMask(pos: Vector3) -> int:
	var gd = _mp_ground_data()
	var bounds: int = 0

	if pos.x < gd.camera_bound_team_left:
		bounds |= CAMERA_FLAG_BOUND_LEFT
	if pos.x > gd.camera_bound_team_right:
		bounds |= CAMERA_FLAG_BOUND_RIGHT
	if pos.y < gd.camera_bound_team_bottom:
		bounds |= CAMERA_FLAG_BOUND_BOTTOM
	if pos.y > gd.camera_bound_team_top:
		bounds |= CAMERA_FLAG_BOUND_TOP
	return bounds

## 0x8010BA38
## C: void (Vec3f *pos) - pos in-out -> returns the clamped pos.
static func gmCameraSetTeamBoundsPosition(pos: Vector3) -> Vector3:
	var gd = _mp_ground_data()

	while true:
		var bounds: int = gmCameraGetTeamBoundsMask(pos)

		if bounds != 0:
			if bounds & CAMERA_FLAG_BOUND_LEFT:
				pos.x = gd.camera_bound_team_left
			elif bounds & CAMERA_FLAG_BOUND_RIGHT:
				pos.x = gd.camera_bound_team_right
			elif bounds & CAMERA_FLAG_BOUND_BOTTOM:
				pos.y = gd.camera_bound_team_bottom
			elif bounds & CAMERA_FLAG_BOUND_TOP:
				pos.y = gd.camera_bound_team_top
		else:
			break
	return pos

## 0x8010BB08
## C: void (Vec3f *pos) - pos in-out -> returns the new pos.
static func gmCameraSetDeadUpStarPosition(pos: Vector3) -> Vector3:
	var gd = _mp_ground_data()

	pos.x = (gd.camera_bound_top * pos.x) / gd.map_bound_top
	pos.y = gd.camera_bound_top
	return pos

## 0x8010BB58
static func gmCameraGetPlayerNumZoomRange(players_num: int) -> float:
	var zoom: float = dGMCameraPlayerZoomRanges[players_num]

	if G.gSCManagerBattleState.game_type == nSCBattleGameTypeExplain:
		zoom *= 0.75
	return zoom

## 0x8010BB98
static func gmCameraCalcFighterZoomRange(fp: Fighter, camera_zoom: float) -> float:
	camera_zoom *= fp.camera_zoom_frame
	camera_zoom *= fp.camera_zoom_range

	if (fp.status_id == nFTCommonStatusWait) and (fp.status_total_tics >= 120):
		camera_zoom *= 0.75
	return camera_zoom

## 0x8010BBE4
static func gmCameraGetTargetAtY(dist: float) -> float:
	if dist > 2000.0:
		return 0.0682
	elif dist < 1000.0:
		return 0.0
	else:
		return ((dist - 1000.0) / 1000) * 0.0682

## 0x8010BC54
## C: void (Vec3f *vec, f32 *hz, f32 *vt) - all pure outputs -> returns {"vec", "hz", "vt"}.
static func gmCameraUpdateInterests() -> Dictionary:
	var vec := Vector3()
	var hz: float
	var vt: float
	var players_num: int
	var i: int
	var cams: Array = []          # FTCamera cams[GMCOMMON_PLAYERS_MAX]
	var fp: Fighter
	var wp: Weapon
	var pos_top: float
	var pos_left: float
	var pos_bottom: float
	var ft_right: float
	var ft_top: float
	var ft_left: float
	var ft_bottom: float
	var zoom: float
	var cam_fp: Fighter
	var wp_top: float
	var wp_bottom: float
	var wp_left: float
	var wp_right: float
	var adjust: float
	var gm_top: float
	var gm_bottom: float
	var gm_left: float
	var gm_right: float
	var pos_right: float
	var lr: int
	var weapon_pos: Vector3

	players_num = 0

	for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		fp = ftGetStruct(fighter_gobj)

		if fp.camera_mode != nFTCameraModeGhost:
			# default:
			if players_num >= GMCOMMON_PLAYERS_MAX:
				_gmCameraFatal("Player Num is Over for Camera!\n")
			var cam := FTCamera.new()
			cams.append(cam)              # cams[players_num]
			cam.target_fp = fp

			if (fp.camera_mode == nFTCameraModeEntry) or (fp.camera_mode == nFTCameraModeExplain):
				cam.target_pos = fp.entry_pos
			elif fp.camera_mode == nFTCameraModeDeadUp:
				cam.target_pos = fp.status_vars.common.dead.pos
			else:
				cam.target_pos = DObjGetStruct(fighter_gobj).translate
			cam.target_pos.y += fp.attr.cam_offset_y

			if (G.gSCManagerBattleState.game_type == nSCBattleGameType1PGame) and (G.gSCManagerBattleState.players[fp.player].is_spgame_enemy != FALSE):
				cam.target_pos = gmCameraSetTeamBoundsPosition(cam.target_pos)
			elif fp.camera_mode == nFTCameraModeDeadUp:
				cam.target_pos = gmCameraSetDeadUpStarPosition(cam.target_pos)
			else:
				cam.target_pos = gmCameraSetBoundsPosition(cam.target_pos)
			players_num += 1
		# case nFTCameraModeGhost: break;
	if players_num != 0:
		ft_top = 65536.0
		ft_bottom = -65536.0
		ft_left = -65536.0
		ft_right = 65536.0

		gm_bottom = 65536.0
		gm_top = -65536.0
		gm_left = 65536.0
		gm_right = -65536.0

		zoom = gmCameraGetPlayerNumZoomRange(players_num)

		i = 0
		while i < players_num:
			var cam: FTCamera = cams[i]
			cam_fp = cam.target_fp

			adjust = gmCameraCalcFighterZoomRange(cam_fp, zoom)

			lr = cam_fp.status_vars.common.entry.lr if ((cam_fp.camera_mode == nFTCameraModeEntry) or (cam_fp.camera_mode == nFTCameraModeExplain)) else cam_fp.lr

			if lr == -1:
				pos_left = cam.target_pos.x - (1000.0 * adjust)
				pos_right = cam.target_pos.x + (700.0 * adjust)
			else:
				pos_left = cam.target_pos.x - (700.0 * adjust)
				pos_right = cam.target_pos.x + (1000.0 * adjust)
			if gm_left > pos_left:
				gm_left = pos_left
			if gm_right < pos_right:
				gm_right = pos_right
			pos_top = cam.target_pos.y + (700.0 * adjust)
			pos_bottom = cam.target_pos.y + (-700.0 * adjust)

			if gm_bottom > pos_bottom:
				gm_bottom = pos_bottom
			if gm_top < pos_top:
				gm_top = pos_top
			if cam.target_pos.x < ft_right:     # ft_right = ft_right?
				ft_right = cam.target_pos.x
			if cam.target_pos.x > ft_left:      # ft_left = ft_left?
				ft_left = cam.target_pos.x
			if cam.target_pos.y < ft_top:       # ft_top = ft_top?
				ft_top = cam.target_pos.y
			if cam.target_pos.y > ft_bottom:    # ft_bottom = ft_bottom?
				ft_bottom = cam.target_pos.y
			cam.unk_ftcobj_0x10 = adjust
			i += 1
		for weapon_gobj in Sim.get_link(nGCCommonLinkIDWeapon):
			wp = wpGetStruct(weapon_gobj)

			if wp.is_camera_follow:
				weapon_pos = DObjGetStruct(weapon_gobj).translate

				wp_left = ft_right - 1000.0     # wp_left = left?
				wp_right = ft_left + 1000.0     # wp_right = right?
				wp_bottom = ft_top - 1000.0     # wp_bottom = bottom?
				wp_top = ft_bottom + 1000.0     # wp_top = top?

				weapon_pos = gmCameraSetBoundsPosition(weapon_pos)

				if weapon_pos.x < wp_left:
					weapon_pos.x = wp_left
				if weapon_pos.x > wp_right:
					weapon_pos.x = wp_right
				if weapon_pos.y < wp_bottom:
					weapon_pos.y = wp_bottom
				if weapon_pos.y > wp_top:
					weapon_pos.y = wp_top
				if (weapon_pos.x - 1000.0) < gm_left:     # gm_left = gm_left?
					gm_left = (weapon_pos.x - 1000.0)
				if (weapon_pos.x + 1000.0) > gm_right:    # gm_right = gm_right?
					gm_right = (weapon_pos.x + 1000.0)
				if (weapon_pos.y - 1000.0) < gm_bottom:   # gm_bottom = gm_bottom?
					gm_bottom = (weapon_pos.y - 1000.0)
				if (weapon_pos.y + 1000.0) > gm_top:      # gm_top = gm_top?
					gm_top = (weapon_pos.y + 1000.0)
		hz = (gm_right - gm_left) * 0.5
		vt = (gm_top - gm_bottom) * 0.5

		vec.x = ((gm_left + gm_right) * 0.5)
		vec.y = (0.5 - gmCameraGetTargetAtY(hz if (vt < hz) else vt)) * (gm_bottom + gm_top)
		vec.z = 0.0
	else:
		vec.x = 0.0
		vec.y = 0.0
		vec.z = 0.0

		vt = 2000.0
		hz = 2000.0
	return {"vec": vec, "hz": hz, "vt": vt}

## 0x8010C200
## C: void (f32 hz, f32 vt, f32 *max) - max pure output -> returns max.
static func gmCameraGetClampDimensionsMax(hz: float, vt: float) -> float:
	var maxd: float

	vt /= lbCommonTan(_F_CLC_DTOR32(gGMCameraStruct.fovy * 0.5))
	hz /= ((lbCommonTan(_F_CLC_DTOR32(gGMCameraStruct.fovy * 0.5)) * gGMCameraStruct.viewport_width) / gGMCameraStruct.viewport_height)

	maxd = hz if (hz > vt) else vt

	if maxd < 2500.0:
		maxd = 2500.0
	if maxd > 30000.0:
		maxd = 30000.0
	return maxd

## 0x8010C320
## C: void (Vec3f *at, Vec3f *vec, f32 x, f32 y) - vec pure output -> returns vec.
static func gmCameraGetAdjustAtAngle(at: Vector3, x: float, y: float) -> Vector3:
	var vec := Vector3()
	var angle_x: float
	var angle_y: float

	angle_x = gGMCameraPauseCameraEyeY + y + _mp_ground_data().light_angle.z

	vec.y = -lbCommonSin(angle_x)
	vec.z = lbCommonCos(angle_x)

	angle_y = gGMCameraPauseCameraEyeX + x

	vec.x = (lbCommonSin(angle_y) * vec.z)
	vec.z *= lbCommonCos(angle_y)
	return vec

## 0x8010C3C0
## C: void (Vec3f *at, Vec3f *vec) - vec pure output -> returns vec.
static func func_ovl2_8010C3C0(at: Vector3) -> Vector3:
	var x: float
	var y: float

	y = -_F_CLC_DTOR32((at.y + (-900.0)) / 133.0)

	if y > F_CLC_DTOR32_5:              # 0.08726647F
		y = F_CLC_DTOR32_5
	if y < F_CLC_DTOR32_N7:             # -0.122173056F
		y = F_CLC_DTOR32_N7
	x = -_F_CLC_DTOR32(at.x / 133.0)

	if x > F_CLC_DTOR32_17_5:           # 0.30543265F
		x = F_CLC_DTOR32_17_5
	if x < F_CLC_DTOR32_N17_5:          # -0.30543265F
		x = F_CLC_DTOR32_N17_5
	return gmCameraGetAdjustAtAngle(at, x, y)

## 0x8010C4A4
## C: void (Vec3f *arg0, Vec3f *arg1) - arg1 pure output -> returns arg1.
static func gmCameraUpdateInishieFocus(arg0: Vector3) -> Vector3:
	return gmCameraGetAdjustAtAngle(arg0, 0.0, 0.0)

## 0x8010C4D0
static func func_ovl2_8010C4D0() -> float:
	if gGMCameraStruct.target_dist > 15000.0:
		return 0.1
	elif gGMCameraStruct.target_dist < 2000.0:
		return 0.05
	return ((1.0 - ((gGMCameraStruct.target_dist - 2000.0) / 13000.0)) * 0.05) + 0.05   # Needs to be two different 0.05s lol

## 0x8010C55C
static func gmCameraPan(cobj: CObj, pos: Vector3, scale: float) -> void:
	var mag: float
	var add := Vector3()

	# syVectorDiff3D(&add, pos, &cobj->vec.at)
	add.x = pos.x - cobj.vec.at.x
	add.y = pos.y - cobj.vec.at.y
	add.z = pos.z - cobj.vec.at.z
	mag = syVectorMag3D(add) * scale
	add = syVectorNorm3D(add)
	# syVectorScale3D(&add, mag)
	add.x *= mag
	add.y *= mag
	add.z *= mag
	# syVectorAdd3D(&cobj->vec.at, &add)
	cobj.vec.at.x += add.x
	cobj.vec.at.y += add.y
	cobj.vec.at.z += add.z

## 0x8010C5C0
static func func_ovl2_8010C5C0(cobj: CObj, scale: Vector3) -> void:
	var sp34 := Vector3()
	var pan := Vector3()
	var mag: float

	pan.x = cobj.vec.at.x + (gGMCameraStruct.target_dist * scale.x)
	pan.y = cobj.vec.at.y + (gGMCameraStruct.target_dist * scale.y)
	pan.z = cobj.vec.at.z + (gGMCameraStruct.target_dist * scale.z)

	# syVectorDiff3D(&sp34, &pan, &cobj->vec.eye)
	sp34.x = pan.x - cobj.vec.eye.x
	sp34.y = pan.y - cobj.vec.eye.y
	sp34.z = pan.z - cobj.vec.eye.z
	mag = syVectorMag3D(sp34) * 0.1
	sp34 = syVectorNorm3D(sp34)
	# syVectorScale3D(&sp34, mag)
	sp34.x *= mag
	sp34.y *= mag
	sp34.z *= mag
	# syVectorAdd3D(&cobj->vec.eye, &sp34)
	cobj.vec.eye.x += sp34.x
	cobj.vec.eye.y += sp34.y
	cobj.vec.eye.z += sp34.z

## 0x8010C670
static func func_ovl2_8010C670(dist: float) -> void:
	var temp_f0: float
	var temp_f14: float

	temp_f0 = gGMCameraStruct.target_dist - dist

	temp_f14 = temp_f0 * 0.075

	if temp_f0 <= temp_f14:
		gGMCameraStruct.target_dist = dist
	else:
		gGMCameraStruct.target_dist -= temp_f14

## 0x8010C6B8
static func gmCameraApplyVel(cobj: CObj) -> void:
	# syVectorAdd3D(&cobj->vec.at, &gGMCameraStruct.vel_at)
	cobj.vec.at.x += gGMCameraStruct.vel_at.x
	cobj.vec.at.y += gGMCameraStruct.vel_at.y
	cobj.vec.at.z += gGMCameraStruct.vel_at.z
	gGMCameraStruct.vel_at.x = 0.0
	gGMCameraStruct.vel_at.y = 0.0
	gGMCameraStruct.vel_at.z = 0.0

## 0x8010C6FC
static func gmCameraApplyFOV(cobj: CObj) -> void:
	cobj.projection.persp.fovy = gGMCameraStruct.fovy

## 0x8010C70C
static func gmCameraAdjustFOV(fovy: float) -> void:
	gGMCameraStruct.fovy += ((fovy - gGMCameraStruct.fovy) * 0.1)

## 0x8010C734
static func gmCameraDefaultFuncCamera(camera_gobj) -> void:
	var cobj: CObj
	var sp48: float
	var sp3C: Vector3
	var sp30: Vector3
	var sp2C: float
	var sp28: float

	cobj = CObjGetStruct(camera_gobj)

	var interests := gmCameraUpdateInterests()
	sp30 = interests.vec
	sp2C = interests.hz
	sp28 = interests.vt
	gmCameraAdjustFOV(38.0)
	sp48 = gmCameraGetClampDimensionsMax(sp2C, sp28)
	func_ovl2_8010C670(sp48)
	gmCameraPan(cobj, sp30, func_ovl2_8010C4D0())
	sp3C = func_ovl2_8010C3C0(cobj.vec.at)
	func_ovl2_8010C5C0(cobj, sp3C)
	gmCameraApplyVel(cobj)
	gmCameraApplyFOV(cobj)

## 0x8010C7D0
static func gmCameraUpdateAcidZoom(cobj: CObj, scale: Vector3) -> void:
	var add := Vector3()
	var pos := Vector3()
	var mag: float
	var current: float
	var step: float

	pos.x = cobj.vec.at.x + (gGMCameraStruct.target_dist * scale.x)
	pos.y = cobj.vec.at.y + (gGMCameraStruct.target_dist * scale.y)
	pos.z = cobj.vec.at.z + (gGMCameraStruct.target_dist * scale.z)

	# grZebesAcidGetLevelInfo(&current, &step): void with two outputs -> {"current", "step"}
	var acid = Grzebes.grZebesAcidGetLevelInfo()
	current = acid.current
	step = acid.step

	current += (step + 3000.0)

	if pos.y < current:
		pos.y = current
	# syVectorDiff3D(&add, &pos, &cobj->vec.eye)
	add.x = pos.x - cobj.vec.eye.x
	add.y = pos.y - cobj.vec.eye.y
	add.z = pos.z - cobj.vec.eye.z
	mag = syVectorMag3D(add) * 0.1
	add = syVectorNorm3D(add)
	add.x *= mag
	add.y *= mag
	add.z *= mag
	cobj.vec.eye.x += add.x
	cobj.vec.eye.y += add.y
	cobj.vec.eye.z += add.z

## 0x8010C8C4
static func gmCameraZebesFuncCamera(camera_gobj) -> void:
	var cobj: CObj = CObjGetStruct(camera_gobj)
	var max_: float
	var scale: Vector3
	var sp30: Vector3
	var hz: float
	var vt: float

	var interests := gmCameraUpdateInterests()
	sp30 = interests.vec
	hz = interests.hz
	vt = interests.vt
	gmCameraAdjustFOV(38.0)
	max_ = gmCameraGetClampDimensionsMax(hz, vt)
	func_ovl2_8010C670(max_)
	gmCameraPan(cobj, sp30, func_ovl2_8010C4D0())
	scale = func_ovl2_8010C3C0(cobj.vec.at)
	gmCameraUpdateAcidZoom(cobj, scale)
	gmCameraApplyVel(cobj)
	gmCameraApplyFOV(cobj)

## 0x8010C960
static func gmCameraUpdatePlayerZoom(camera_gobj) -> void:
	var cobj: CObj
	var fp: Fighter
	var eye := Vector3()
	var angle := Vector3()
	var pos: Vector3

	cobj = CObjGetStruct(camera_gobj)
	pos = DObjGetStruct(gGMCameraStruct.pzoom_fighter_gobj).translate
	fp = ftGetStruct(gGMCameraStruct.pzoom_fighter_gobj)

	pos.y += fp.attr.cam_offset_y

	gmCameraAdjustFOV(gGMCameraStruct.pzoom_fov)

	gGMCameraStruct.target_dist = gGMCameraStruct.pzoom_dist

	gmCameraPan(cobj, pos, gGMCameraStruct.pzoom_pan_scale)

	eye.y = gGMCameraPauseCameraEyeX + gGMCameraStruct.pzoom_eye_x
	eye.x = gGMCameraPauseCameraEyeY + gGMCameraStruct.pzoom_eye_y

	angle.y = -lbCommonSin(eye.x)
	angle.z = lbCommonCos(eye.x)
	angle.x = lbCommonSin(eye.y) * angle.z
	angle.z *= lbCommonCos(eye.y)

	func_ovl2_8010C5C0(cobj, angle)
	gmCameraApplyVel(cobj)
	gmCameraApplyFOV(cobj)

## 0x8010CA7C
static func gmCameraCheckPausePlayerOutBounds(pos: Vector3) -> int:
	if (gmCameraGetBoundsMask(pos) != 0) or (pos.z < -1000.0) or (pos.z > 1000.0):
		return TRUE
	else:
		return FALSE

## 0x8010CAE0
static func gmCameraPlayerZoomFuncCamera(camera_gobj) -> void:
	if gmCameraCheckPausePlayerOutBounds(DObjGetStruct(gGMCameraStruct.pzoom_fighter_gobj).translate) != FALSE:
		dGMCameraFuncList[gGMCameraStruct.status_default].call(camera_gobj)
	else:
		gmCameraUpdatePlayerZoom(camera_gobj)

## 0x8010CB48
static func gmCameraInishieFuncCamera(camera_gobj) -> void:
	var cobj: CObj
	var sp48: float
	var sp3C: Vector3
	var sp30: Vector3
	var sp2C: float
	var sp28: float

	cobj = CObjGetStruct(camera_gobj)

	var interests := gmCameraUpdateInterests()
	sp30 = interests.vec
	sp2C = interests.hz
	sp28 = interests.vt
	gmCameraAdjustFOV(38.0)
	sp48 = gmCameraGetClampDimensionsMax(sp2C, sp28)
	func_ovl2_8010C670(sp48)
	gmCameraPan(cobj, sp30, func_ovl2_8010C4D0())
	sp3C = gmCameraUpdateInishieFocus(cobj.vec.at)
	func_ovl2_8010C5C0(cobj, sp3C)
	gmCameraApplyVel(cobj)
	gmCameraApplyFOV(cobj)

## 0x8010CBE4
static func gmCameraUpdateAnimVel(camera_gobj) -> void:
	var cobj: CObj

	ObjAnim.gcPlayCamAnim(camera_gobj)

	cobj = CObjGetStruct(camera_gobj)

	cobj.vec.at.x += gGMCameraStruct.vel_all.x
	cobj.vec.at.y += gGMCameraStruct.vel_all.y
	cobj.vec.at.z += gGMCameraStruct.vel_all.z
	cobj.vec.eye.x += gGMCameraStruct.vel_all.x
	cobj.vec.eye.y += gGMCameraStruct.vel_all.y
	cobj.vec.eye.z += gGMCameraStruct.vel_all.z

## 0x8010CC74
static func gmCameraAnimFuncCamera(camera_gobj) -> void:
	gmCameraUpdateAnimVel(camera_gobj)

	if CObjGetStruct(camera_gobj).anim_wait == AOBJ_ANIM_NULL:
		gmCameraSetStatusDefault()

## 0x8010CCC0
static func gmCameraMapZoomFuncCamera(camera_gobj) -> void:
	var cobj: CObj
	var sp30 := Vector3()
	var sp2C: float
	var sp28: float

	cobj = CObjGetStruct(camera_gobj)

	gmCameraAdjustFOV(38.0)

	# syVectorDiff3D(&sp30, &gGMCameraStruct.zoom_origin_pos, &cobj->vec.at)
	sp30.x = gGMCameraStruct.zoom_origin_pos.x - cobj.vec.at.x
	sp30.y = gGMCameraStruct.zoom_origin_pos.y - cobj.vec.at.y
	sp30.z = gGMCameraStruct.zoom_origin_pos.z - cobj.vec.at.z
	sp28 = syVectorMag3D(sp30)
	sp2C = func_ovl2_8010C4D0() * sp28
	sp30 = syVectorNorm3D(sp30)
	sp30.x *= sp2C
	sp30.y *= sp2C
	sp30.z *= sp2C
	cobj.vec.at.x += sp30.x
	cobj.vec.at.y += sp30.y
	cobj.vec.at.z += sp30.z

	# syVectorDiff3D(&sp30, &gGMCameraStruct.zoom_target_pos, &cobj->vec.eye)
	sp30.x = gGMCameraStruct.zoom_target_pos.x - cobj.vec.eye.x
	sp30.y = gGMCameraStruct.zoom_target_pos.y - cobj.vec.eye.y
	sp30.z = gGMCameraStruct.zoom_target_pos.z - cobj.vec.eye.z
	sp2C = syVectorMag3D(sp30) * 0.1
	sp30 = syVectorNorm3D(sp30)
	sp30.x *= sp2C
	sp30.y *= sp2C
	sp30.z *= sp2C
	cobj.vec.eye.x += sp30.x
	cobj.vec.eye.y += sp30.y
	cobj.vec.eye.z += sp30.z
	gmCameraApplyVel(cobj)
	gmCameraApplyFOV(cobj)

## 0x8010CDAC
static func gmCameraPlayerFollowFuncCamera(camera_gobj) -> void:
	var eye_x: float
	var eye_y: float
	var angle := Vector3()
	var pos: Vector3
	var cobj: CObj
	var fp: Fighter

	cobj = CObjGetStruct(camera_gobj)
	pos = DObjGetStruct(gGMCameraStruct.pfollow_fighter_gobj).translate
	fp = ftGetStruct(gGMCameraStruct.pfollow_fighter_gobj)

	pos.y += fp.attr.cam_offset_y
	pos.z = 0.0

	pos = gmCameraSetBoundsPosition(pos)
	gmCameraAdjustFOV(gGMCameraStruct.pfollow_fov)

	gGMCameraStruct.target_dist = gGMCameraStruct.pfollow_dist

	gmCameraPan(cobj, pos, gGMCameraStruct.pfollow_pan_scale)

	eye_x = gGMCameraPauseCameraEyeX + gGMCameraStruct.pfollow_eye_x
	eye_y = gGMCameraPauseCameraEyeY + gGMCameraStruct.pfollow_eye_y

	angle.y = -lbCommonSin(eye_y)
	angle.z = lbCommonCos(eye_y)
	angle.x = lbCommonSin(eye_x) * angle.z
	angle.z *= lbCommonCos(eye_x)

	func_ovl2_8010C5C0(cobj, angle)
	gmCameraApplyVel(cobj)
	gmCameraApplyFOV(cobj)

## 0x8010CECC - the battle camera's process (priority 3)
static func gmCameraRunFuncCamera(camera_gobj) -> void:
	gGMCameraStruct.func_camera.call(camera_gobj)

	# port-only: publish the updated view for the renderer
	_gmCameraPublishRender(CObjGetStruct(camera_gobj))

## 0x8010CEF4
static func gmCameraSetStatus(status_id: int) -> void:
	gGMCameraStruct.status_prev = gGMCameraStruct.status_curr
	gGMCameraStruct.status_curr = status_id

	gGMCameraStruct.func_camera = dGMCameraFuncList[status_id]

## 0x8010CF20
static func gmCameraSetStatusDefault() -> void:
	gmCameraSetStatus(gGMCameraStruct.status_default)

## 0x8010CF44
static func gmCameraSetStatusPlayerZoom(fighter_gobj, eye_x: float, eye_y: float, dist: float, pan_scale: float, fov: float) -> void:
	gmCameraSetStatus(nGMCameraStatusPlayerZoom)

	gGMCameraStruct.pzoom_fighter_gobj = fighter_gobj
	gGMCameraStruct.pzoom_eye_x = eye_x
	gGMCameraStruct.pzoom_eye_y = eye_y
	gGMCameraStruct.pzoom_dist = dist
	gGMCameraStruct.pzoom_pan_scale = pan_scale
	gGMCameraStruct.pzoom_fov = fov

## 0x8010CFA8
static func gmCameraSetStatusPlayerFollow(fighter_gobj, eye_x: float, eye_y: float, dist: float, pan_scale: float, fov: float) -> void:
	gmCameraSetStatus(nGMCameraStatusPlayerFollow)

	gGMCameraStruct.pfollow_fighter_gobj = fighter_gobj
	gGMCameraStruct.pfollow_eye_x = eye_x
	gGMCameraStruct.pfollow_eye_y = eye_y
	gGMCameraStruct.pfollow_dist = dist
	gGMCameraStruct.pfollow_pan_scale = pan_scale
	gGMCameraStruct.pfollow_fov = fov

## 0x8010D00C
static func gmCameraSetStatusPrev() -> void:
	gmCameraSetStatus(gGMCameraStruct.status_prev)

## 0x8010D030
static func gmCameraSetStatusAnim(camanim_joint, anim_frame: float, vel: Vector3) -> void:
	gmCameraSetStatus(nGMCameraStatusAnim)

	gGMCameraStruct.vel_all = vel

	ObjAnim.gcAddCObjCamAnimJoint(CObjGetStruct(gGMCameraGObj), camanim_joint, anim_frame)
	gmCameraUpdateAnimVel(gGMCameraGObj)

## 0x8010D0A4
static func gmCameraSetStatusMapZoom(origin: Vector3, target: Vector3) -> void:
	var dist := Vector3()

	gmCameraSetStatus(nGMCameraStatusMapZoom)

	gGMCameraStruct.zoom_origin_pos = origin
	gGMCameraStruct.zoom_target_pos = target

	# syVectorDiff3D(&dist, origin, target)
	dist.x = origin.x - target.x
	dist.y = origin.y - target.y
	dist.z = origin.z - target.z

	gGMCameraStruct.target_dist = syVectorMag3D(dist)

## 0x8010D128
static func gmCameraSetVelAt(vel: Vector3) -> void:
	gGMCameraStruct.vel_at = vel

## 0x8010D14C - Unused?
static func func_ovl2_8010D14C(gobj) -> void:
	return

## 0x8010D154
static func gmCameraGetMatrixMax() -> float:
	var ret: float
	var abs_: float
	var i: int
	var j: int

	ret = 0.0

	i = 0
	while i < 4:            # ARRAY_COUNT(gGMCameraMatrix[i])
		j = 0
		while j < 4:        # ARRAY_COUNT(gGMCameraMatrix)
			abs_ = ABSF(gGMCameraMatrix[i * 4 + j])

			if ret < abs_:
				ret = abs_
			j += 1
		i += 1
	return ret

## 0x8010D250 - matrix kind 0x4C: projection x view of the main camera.
## Adapted: builds gGMCameraMatrix / sGMCameraMatrixPerspF as float matrices and publishes the
## render output; the fixed-point Mtx (syMatrixF2L into mtx / sGCMatrixProjectL) is not produced.
static func gmCameraLookAtFuncMatrix(mtx, cobj: CObj, dls) -> int:
	var sp5C := PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	var max_: float
	var persp: GCPersp = cobj.projection.persp
	var reflect: Array

	# syMatrixAdvanceW(temp_mtx, gSYTaskmanGraphicsHeap);
	persp.norm = _syMatrixPerspFastF(sGMCameraMatrixPerspF, persp.fovy, persp.aspect, persp.near, persp.far, persp.scale)
	# syMatrixF2L(&gGCMatrixPerspF, temp_mtx); sGCMatrixProjectL = temp_mtx;

	reflect = _syMatrixLookAtF(sp5C, cobj.vec.eye.x, cobj.vec.eye.y, cobj.vec.eye.z, cobj.vec.at.x, cobj.vec.at.y, cobj.vec.at.z, cobj.vec.up.x, cobj.vec.up.y, cobj.vec.up.z)
	gGMCameraStruct.look_at.l[0].dir = [reflect[0].x, reflect[0].y, reflect[0].z]
	gGMCameraStruct.look_at.l[1].dir = [reflect[1].x, reflect[1].y, reflect[1].z]
	_guMtxCatF(sp5C, sGMCameraMatrixPerspF, gGMCameraMatrix)

	max_ = gmCameraGetMatrixMax()

	if max_ > 32000.0:
		persp.norm = _syMatrixPerspFastF(sGMCameraMatrixPerspF, persp.fovy, persp.aspect, persp.near, persp.far, 32000.0 / max_)
		# syMatrixF2L(&gGCMatrixPerspF, temp_mtx); sGCMatrixProjectL = temp_mtx;

		_syMatrixLookAtF(sp5C, cobj.vec.eye.x, cobj.vec.eye.y, cobj.vec.eye.z, cobj.vec.at.x, cobj.vec.at.y, cobj.vec.at.z, cobj.vec.up.x, cobj.vec.up.y, cobj.vec.up.z)
		_guMtxCatF(sp5C, sGMCameraMatrixPerspF, gGMCameraMatrix)
	# syMatrixF2L(&gGMCameraMatrix, mtx);
	_copyMatrix16(mtx, gGMCameraMatrix)

	_gmCameraPublishRender(cobj)

	return 0

## Adapted syMatrixF2L(src, dst): when dst is a PackedFloat32Array(16) it receives the float matrix
## (the fixed-point Mtx of the RSP is not produced).
static func _copyMatrix16(dst, src: PackedFloat32Array) -> void:
	if (dst is PackedFloat32Array) and (dst.size() == 16):
		for i in 16:
			dst[i] = src[i]

## 0x8010D428 - matrix kind 0x4D: emits gSPLookAtX/Y, gSPMatrix(projection), gSPPerspNormalize
## (display-list commands only; render side).
static func gmCameraPrepLookAtFuncMatrix(mtx, cobj: CObj, dls) -> int:
	return 0

## 0x8010D4B0
static func func_ovl2_8010D4B0(mtx, cobj: CObj, dls) -> void:
	return

## 0x8010D4C0 - display proc of the main camera.
## Adapted: the GBI/DL-buffer passes are render side; gcPrepCameraMatrix would run the camera's
## matrix kind 0x4C (gmCameraLookAtFuncMatrix), which is called directly here.
static func gmCameraDefaultProcDisplay(camera_gobj) -> void:
	var cobj: CObj = CObjGetStruct(camera_gobj)
	var ifc = _if_player_interface()
	var is_tag: int = 1 if (cobj.flags & COBJ_FLAG_IDENTIFIER) else 0

	Objdisplay.gcSetCameraMatrixMode(3)
	Objdisplay.func_8001663C(null, cobj, 0)
	Objdisplay.gcPrepCameraMatrix(null, cobj)
	gmCameraLookAtFuncMatrix(null, cobj, null)
	Objdisplay.gcRunFuncCamera(cobj, 0)

	if ifc != null:
		ifc.magnify_mode = 0
		ifc.arrows_flags = 0

	# gIFCommonPlayerInterface.unk1 = 0;
	# gIFCommonPlayerInterface.unkE = 0;

	# gDPSetRenderMode(gSYTaskmanDLHeads[1]++, G_RM_AA_ZB_XLU_SURF, G_RM_AA_ZB_XLU_SURF2);

	cobj.camera_mask = _COBJ_MASK_DLLINK(2) | _COBJ_MASK_DLLINK(1)

	Objdisplay.gcCaptureCameraGObj(camera_gobj, is_tag)
	Taskman.syTaskmanUpdateDLBuffers()

	cobj.camera_mask = _COBJ_MASK_DLLINK(4)

	Objdisplay.gcCaptureCameraGObj(camera_gobj, is_tag)
	Taskman.syTaskmanUpdateDLBuffers()

	cobj.camera_mask = _COBJ_MASK_DLLINK(12) | _COBJ_MASK_DLLINK(11) | _COBJ_MASK_DLLINK(10) | _COBJ_MASK_DLLINK(9) | _COBJ_MASK_DLLINK(7) | _COBJ_MASK_DLLINK(6)

	Objdisplay.gcCaptureCameraGObj(camera_gobj, is_tag)
	Taskman.syTaskmanUpdateDLBuffers()

	cobj.camera_mask = _COBJ_MASK_DLLINK(15) | _COBJ_MASK_DLLINK(14) | _COBJ_MASK_DLLINK(13)

	Objdisplay.gcCaptureCameraGObj(camera_gobj, is_tag)
	Taskman.syTaskmanUpdateDLBuffers()

	cobj.camera_mask = _COBJ_MASK_DLLINK(18) | _COBJ_MASK_DLLINK(17) | _COBJ_MASK_DLLINK(16)

	Objdisplay.gcCaptureCameraGObj(camera_gobj, is_tag)
	Taskman.syTaskmanUpdateDLBuffers()

	cobj.camera_mask = _COBJ_MASK_DLLINK(20) | _COBJ_MASK_DLLINK(19)

	Objdisplay.gcCaptureCameraGObj(camera_gobj, is_tag)
	Taskman.syTaskmanUpdateDLBuffers()

## 0x8010D7E8
## proc: Callable (C: void (*proc)(GObj*)) run as the camera GObj's process at priority 3.
static func gmCameraMakeDefaultCamera(tk1: int, tk2: int, proc: Callable):
	var camera_gobj
	var cobj: CObj
	var sp4C := Vector3()

	camera_gobj = _gcMakeCameraGObj(
		nGCCommonKindMainCamera,
		null,
		nGCCommonLinkIDCamera,
		GOBJ_PRIORITY_DEFAULT,
		Callable(Gmcamera, &"gmCameraDefaultProcDisplay"),
		50,
		0,
		~0,
		FALSE,
		nGCProcessKindFunc,
		proc,
		3,
		FALSE
	)
	gGMCameraGObj = camera_gobj

	cobj = CObjGetStruct(camera_gobj)

	Objman.gcAddXObjForCamera(cobj, tk1, 0)

	if tk2 != nGCMatrixKindNull:
		Objman.gcAddXObjForCamera(cobj, tk2, 0)
	cobj.projection.persp.copy_from(dGMCameraPerspDefault)
	cobj.vec.copy_from(dGMCameraCObjVecDefault)

	_syRdpSetViewport(
		cobj.viewport,
		gGMCameraStruct.viewport_ulx,
		gGMCameraStruct.viewport_uly,
		gGMCameraStruct.viewport_lrx,
		gGMCameraStruct.viewport_lry
	)

	# This (f32) cast is NECESSARY! scissor_ulx through scissor_lry are signed integers!
	cobj.projection.persp.aspect = (float(gGMCameraStruct.viewport_lrx - gGMCameraStruct.viewport_ulx) / float(gGMCameraStruct.viewport_lry - gGMCameraStruct.viewport_uly))

	cobj.flags |= COBJ_FLAG_DLBUFFERS

	gGMCameraStruct.target_dist = 10000.0

	gGMCameraPauseCameraEyeX = 0.0
	gGMCameraPauseCameraEyeY = gGMCameraPauseCameraEyeX

	sp4C.y = -lbCommonSin(gGMCameraPauseCameraEyeY)
	sp4C.z = lbCommonCos(gGMCameraPauseCameraEyeY)
	sp4C.x = lbCommonSin(gGMCameraPauseCameraEyeX) * sp4C.z
	sp4C.z *= lbCommonCos(gGMCameraPauseCameraEyeX)

	cobj.vec.at.x = 0.0
	cobj.vec.at.z = 0.0
	cobj.vec.at.y = 300.0

	cobj.vec.eye.x = (gGMCameraStruct.target_dist * sp4C.x)
	cobj.vec.eye.y = cobj.vec.at.y + (gGMCameraStruct.target_dist * sp4C.y)
	cobj.vec.eye.z = (gGMCameraStruct.target_dist * sp4C.z)

	gGMCameraStruct.vel_at.x = 0
	gGMCameraStruct.vel_at.y = 0
	gGMCameraStruct.vel_at.z = 0

	match G.gSCManagerBattleState.gkind:
		nGRKindZebes:
			gGMCameraStruct.status_curr = nGMCameraStatusZebes
		nGRKindInishie:
			gGMCameraStruct.status_curr = nGMCameraStatusInishie
		_:
			gGMCameraStruct.status_curr = nGMCameraStatusDefault
			# No break? Doesn't match otherwise :brainshock:
	gGMCameraStruct.status_prev = gGMCameraStruct.status_curr
	gGMCameraStruct.status_default = gGMCameraStruct.status_prev
	gGMCameraStruct.func_camera = dGMCameraFuncList[gGMCameraStruct.status_curr]
	gGMCameraStruct.fovy = 38.0

	_gmCameraPublishRender(cobj)

	return camera_gobj

## 0x8010DB00
static func gmCameraMakeBattleCamera() -> void:
	gmCameraMakeDefaultCamera(0x4C, nGCMatrixKindNull, Callable(Gmcamera, &"gmCameraRunFuncCamera"))

## 0x8010DB2C
static func gmCameraMakeMovieCamera(func_camera: Callable):
	return gmCameraMakeDefaultCamera(nGCMatrixKindPerspFastF, 8, func_camera)

## 0x8010DB54
static func gmCameraMakeWallpaperCamera():
	var camera_gobj = _gcMakeCameraGObj(
		nGCCommonKindWallpaperCamera,
		null,
		nGCCommonLinkIDCamera,
		GOBJ_PRIORITY_DEFAULT,
		Callable(Lbcommon, &"lbCommonDrawSprite"),
		80,
		_COBJ_MASK_DLLINK(0),
		-1,
		FALSE,
		nGCProcessKindFunc,
		Callable(),
		1,
		FALSE
	)
	var cobj: CObj = CObjGetStruct(camera_gobj)

	_syRdpSetViewport(
		cobj.viewport,
		gGMCameraStruct.viewport_ulx,
		gGMCameraStruct.viewport_uly,
		gGMCameraStruct.viewport_lrx,
		gGMCameraStruct.viewport_lry
	)
	return camera_gobj

## 0x8010DC24
static func gmCameraScreenFlashProcDisplay(camera_gobj) -> void:
	var cobj: CObj = CObjGetStruct(camera_gobj)
	var ifc = _if_player_interface()

	if (ifc != null) and (ifc.magnify_mode != 0):
		var viewport: Dictionary
		var ulx: int
		var uly: int
		var lrx: int
		var lry: int

		# gSPViewport(gSYTaskmanDLHeads[0]++, &CObjGetStruct(gGMCameraGObj)->viewport);

		viewport = CObjGetStruct(gGMCameraGObj).viewport.vp

		ulx = (viewport.vtrans[0] / 4) - (viewport.vscale[0] / 4)
		uly = (viewport.vtrans[1] / 4) - (viewport.vscale[1] / 4)

		lrx = (viewport.vtrans[0] / 4) + (viewport.vscale[0] / 4)
		lry = (viewport.vtrans[1] / 4) + (viewport.vscale[1] / 4)

		# gDPSetScissor(gSYTaskmanDLHeads[0]++, G_SC_NON_INTERLACE, ulx, uly, lrx, lry);
		cobj.scissor = [ulx, uly, lrx, lry]
	Objdisplay.gcCaptureCameraGObj(camera_gobj, 1 if (cobj.flags & COBJ_FLAG_IDENTIFIER) else 0)
	Objdisplay.func_80017CC8(cobj)

## 0x8010DDC4
static func gmCameraScreenFlashMakeCamera() -> void:
	var cobj: CObj = CObjGetStruct(
		_gcMakeCameraGObj(
			nGCCommonKindScissorCamera,
			null,
			nGCCommonLinkIDCamera,
			GOBJ_PRIORITY_DEFAULT,
			Callable(Gmcamera, &"gmCameraScreenFlashProcDisplay"),
			20,
			_COBJ_MASK_DLLINK(22),
			~0,
			FALSE,
			nGCProcessKindFunc,
			Callable(),
			1,
			FALSE
		)
	)
	cobj.flags |= COBJ_FLAG_DLBUFFERS

## 0x8010DE48 - matrix kind 0x4E: magnifying glass projection; sets gIFCommonPlayerInterface.magnify_scale.
## Adapted: float matrices; mtx (if a PackedFloat32Array(16)) receives the float result.
static func gmCameraPlayerMagnifyFuncMatrix(mtx, cobj: CObj, dls) -> int:
	var spA4 := PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	var sp64 := PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	var eye: Vector3
	var at: Vector3
	var sp50 := Vector3()
	var dist_x: float
	var dist_y: float
	var dist_z: float
	var ifc = _if_player_interface()

	eye = CObjGetStruct(gGMCameraGObj).vec.eye
	at = CObjGetStruct(gGMCameraGObj).vec.at

	dist_x = eye.x - at.x
	dist_y = eye.y - at.y
	dist_z = eye.z - at.z

	_syMatrixLookAtF(sp64, 0.0, 300.0, sqrtf(SQUARE(dist_x) + SQUARE(dist_y) + SQUARE(dist_z)), 0.0, 300.0, 0.0, 0.0, 1.0, 0.0)
	_guMtxCatF(sp64, sGMCameraMatrixPerspF, spA4)

	sp50.z = 0.0
	sp50.y = 900.0
	sp50.x = 0.0

	# func_ovl2_800EB924(CObjGetStruct(gGMCameraGObj), spA4, &sp50, &dist_x, &dist_y);
	var screen: Vector2 = _gmCameraProjectScreen(CObjGetStruct(gGMCameraGObj), spA4, sp50)
	dist_x = screen.x
	dist_y = screen.y

	if ifc != null:
		ifc.magnify_scale = (dist_y / 18.0)

		if ifc.magnify_scale > 3.0:
			ifc.magnify_scale = 3.0
	_syMatrixOrthoF(spA4, -450.0, 450.0, -450.0, 450.0, 256.0, 39936.0, 1.0)
	_guMtxCatF(sp64, spA4, spA4)
	# syMatrixF2L(&spA4, mtx);
	_copyMatrix16(mtx, spA4)

	return 0

## 0x8010E00C - matrix kind for the interface cameras: orthographic screen projection.
## Adapted: mtx (if a PackedFloat32Array(16)) receives the float result.
static func gmCameraOrthoLookAtFuncMatrix(mtx, cobj: CObj, dls) -> int:
	var sp78 := PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	var sp38 := PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	var width: float
	var height: float

	width = (gGMCameraStruct.viewport_width / 2)
	height = (gGMCameraStruct.viewport_height / 2)

	_syMatrixOrthoF(sp78, -width, width, -height, height, 100.0, 12800.0, 1.0)
	_syMatrixLookAtF(sp38, 0.0, 0.0, 1000.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)

	_guMtxCatF(sp38, sp78, sp78)
	# syMatrixF2L(&sp78, mtx);
	_copyMatrix16(mtx, sp78)

	return 0

## 0x8010E10C - gSPMatrix(projection) display-list command only (render side).
static func gmCameraPrepProjectionFuncMatrix(mtx, cobj: CObj, dls) -> int:
	return 0

## 0x8010E134
static func gmCameraPlayerMagnifyProcDisplay(camera_gobj) -> void:
	var ifc = _if_player_interface()

	if (ifc != null) and (ifc.magnify_mode != 0):
		var cobj: CObj = CObjGetStruct(camera_gobj)

		Objdisplay.gcPrepCameraMatrix(null, cobj)

		Objdisplay.gcCaptureCameraGObj(camera_gobj, 1 if (cobj.flags & COBJ_FLAG_IDENTIFIER) else 0)
		Objdisplay.func_80017CC8(cobj)

## 0x8010E1A4
static func gmCameraMakePlayerMagnifyCamera() -> void:
	var cobj: CObj = CObjGetStruct(
		_gcMakeCameraGObj(
			nGCCommonKindPlayerMagnifyCamera,
			null,
			nGCCommonLinkIDCamera,
			GOBJ_PRIORITY_DEFAULT,
			Callable(Gmcamera, &"gmCameraPlayerMagnifyProcDisplay"),
			30,
			_COBJ_MASK_DLLINK(9),
			~0,
			FALSE,
			nGCProcessKindFunc,
			Callable(),
			1,
			FALSE
		)
	)
	var ifc = _if_player_interface()

	Lbcommon.lbCommonInitCameraVec(cobj, 0x4D, 0)
	Lbcommon.lbCommonInitCameraOrtho(cobj, 0x4E, 1)

	cobj.flags |= COBJ_FLAG_DLBUFFERS

	if ifc != null:
		ifc.magnify_mode = 0

## 0x8010E254
static func gmCameraPlayerArrowsProcDisplay(camera_gobj) -> void:
	var ifc = _if_player_interface()

	Objdisplay.gcSetCameraMatrixMode(1)

	if (ifc != null) and (ifc.arrows_flags != 0):
		var cobj: CObj = CObjGetStruct(camera_gobj)

		Objdisplay.gcPrepCameraMatrix(null, cobj)

		Objdisplay.gcCaptureCameraGObj(camera_gobj, 1 if (cobj.flags & COBJ_FLAG_IDENTIFIER) else 0)
		Objdisplay.func_80017CC8(cobj)

## 0x8010E2D4
static func gmCameraMakePlayerArrowsCamera() -> void:
	var cobj: CObj = CObjGetStruct(
		_gcMakeCameraGObj(
			nGCCommonKindPlayerArrowsCamera,
			null,
			nGCCommonLinkIDCamera,
			GOBJ_PRIORITY_DEFAULT,
			Callable(Gmcamera, &"gmCameraPlayerArrowsProcDisplay"),
			35,
			_COBJ_MASK_DLLINK(8),
			~0,
			FALSE,
			nGCProcessKindFunc,
			Callable(),
			1,
			FALSE
		)
	)
	var ifc = _if_player_interface()

	# REGION_US
	Lbcommon.lbCommonInitCameraOrtho(cobj, 0x54, 1)

	cobj.flags |= COBJ_FLAG_DLBUFFERS

	if ifc != null:
		ifc.arrows_flags = 0

## 0x8010E374
static func gmCameraMakeInterfaceCamera():
	var camera_gobj = _gcMakeCameraGObj(
		nGCCommonKindScissorCamera,
		null,
		nGCCommonLinkIDCamera,
		GOBJ_PRIORITY_DEFAULT,
		Callable(Lbcommon, &"lbCommonDrawSprite"),
		20,
		_COBJ_MASK_DLLINK(24) | _COBJ_MASK_DLLINK(23),
		~0,
		FALSE,
		nGCProcessKindFunc,
		Callable(),
		1,
		FALSE
	)
	var cobj: CObj = CObjGetStruct(camera_gobj)

	_syRdpSetViewport(cobj.viewport, float(gGMCameraStruct.viewport_ulx), float(gGMCameraStruct.viewport_uly), float(gGMCameraStruct.viewport_lrx), float(gGMCameraStruct.viewport_lry))

	cobj.flags |= COBJ_FLAG_DLBUFFERS

	return camera_gobj

## 0x8010E458
static func gmCameraEffectProcDisplay(camera_gobj) -> void:
	var cobj: CObj = CObjGetStruct(camera_gobj)

	Objdisplay.gcCaptureCameraGObj(camera_gobj, 1 if (cobj.flags & COBJ_FLAG_IDENTIFIER) else 0)

## 0x8010E498 - Not entirely sure what this does, no apparent effect when it's disabled...
static func gmCameraMakeEffectCamera():
	var camera_gobj = _gcMakeCameraGObj(
		nGCCommonKindScissorCamera,
		null,
		nGCCommonLinkIDCamera,
		GOBJ_PRIORITY_DEFAULT,
		Callable(Gmcamera, &"gmCameraEffectProcDisplay"),
		15,
		_COBJ_MASK_DLLINK(25),
		~0,
		FALSE,
		nGCProcessKindFunc,
		Callable(),
		1,
		FALSE
	)
	var cobj: CObj = CObjGetStruct(camera_gobj)

	_syRdpSetViewport(
		cobj.viewport,
		gGMCameraStruct.viewport_ulx,
		gGMCameraStruct.viewport_uly,
		gGMCameraStruct.viewport_lrx,
		gGMCameraStruct.viewport_lry
	)
	cobj.projection.persp.aspect = float(gGMCameraStruct.viewport_width) / float(gGMCameraStruct.viewport_height)

	return camera_gobj

## 0x8010E598 - Are lrx and lry used as width and height respectively?
static func gmCameraSetViewportDimensions(ulx: int, uly: int, lrx: int, lry: int) -> void:
	gGMCameraStruct.viewport_ulx = ulx
	gGMCameraStruct.viewport_uly = uly
	gGMCameraStruct.viewport_lrx = lrx
	gGMCameraStruct.viewport_lry = lry
	gGMCameraStruct.viewport_center_x = (ulx + lrx) / 2
	gGMCameraStruct.viewport_center_y = (uly + lry) / 2
	gGMCameraStruct.viewport_width = lrx - ulx
	gGMCameraStruct.viewport_height = lry - uly

## 0x8010E5F4 - Checks if input position is within the camera's viewport
static func gmCameraCheckTargetInBounds(pos_x: float, pos_y: float) -> int:
	var viewport_width: float = (gGMCameraStruct.viewport_width / 2)
	var viewport_height: float = (gGMCameraStruct.viewport_height / 2)

	if (pos_x < -viewport_width) or (pos_x > viewport_width) or (pos_y < -viewport_height) or (pos_y > viewport_height):
		return FALSE
	return TRUE
