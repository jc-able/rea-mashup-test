## 1:1 port of src/gr/grwallpaper.c (stage background sprite; visual only).
## SObj/CObj are render-side objects: the sprite is made through Lbcommon (stub) and the camera is
## gGMCameraGObj (Gmcamera); while those are unported the wallpaper functions only keep their state.
class_name Grwallpaper
extends Port

## PR/sp.h sprite attributes
const SP_TEXSHUF := 0x00000200
const SP_FASTCOPY := 0x00000020

# // // // // // // // // // // // //
# //   GLOBAL / STATIC VARIABLES   //
# // // // // // // // // // // // //

## 0x801313D0
static var sGRWallpaperIsPausePerspUpdate: int = 0

## 0x801313D4
static var sGRWallpaperPad801313D4: int = 0

## 0x801313D8
static var sGRWallpaperGObj = null

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8012E7C0 - fill the 10..310 x 10..230 viewport black (G_CYC_FILL), then restore 1-cycle ZB opaque mode
static var dGRWallpaperDisplayList: Array = [
	"gsDPSetCycleType(G_CYC_FILL)",
	"gsDPSetRenderMode(G_RM_NOOP, G_RM_NOOP2)",
	"gsDPSetFillColor(GPACK_FILL16(GPACK_RGBA5551(0x00, 0x00, 0x00, 0x01)))",
	"gsDPFillRectangle(10, 10, 310, 230)",
	"gsDPPipeSync()",
	"gsDPSetCycleType(G_CYC_1CYCLE)",
	"gsDPSetRenderMode(G_RM_AA_ZB_OPA_SURF, G_RM_AA_ZB_OPA_SURF2)",
	"gsSPEndDisplayList()",
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## SObjGetStruct(gobj): the sprite object created by Lbcommon (null while Lbcommon is a stub).
static func _grWallpaperGetSObj(wallpaper_gobj):
	if wallpaper_gobj == null:
		return null
	return wallpaper_gobj.user_data

## CObjGetStruct(gGMCameraGObj) (null while Gmcamera does not provide it).
static func _grWallpaperGetCObj():
	var s: Object = Gmcamera
	var camera_gobj = s.get("gGMCameraGObj")
	if camera_gobj == null:
		return null
	if camera_gobj is Object and ("obj" in camera_gobj):
		return camera_gobj.obj
	return camera_gobj.user_data if camera_gobj is GObj else null

## Vec3f eye - at of a CObj ({vec: {eye, at}} or {eye, at}).
static func _grWallpaperGetCameraDist(cobj) -> Variant:
	if cobj == null:
		return null
	var v = cobj.vec if ("vec" in cobj) else cobj
	if v == null or not ("eye" in v) or not ("at" in v):
		return null
	return v.eye - v.at

## 0x80104620 - Calculate perspective of stage background image?
static func grWallpaperCalcPersp(wallpaper_sobj = null) -> void:
	var mag: float
	var angle: Vector2
	var dist
	var bak_pos_x: float
	var bak_pos_y: float
	var pos_x: float
	var pos_y: float
	var neg: float
	var width: float
	var height: float
	var scale: float

	dist = _grWallpaperGetCameraDist(_grWallpaperGetCObj())   # syVectorDiff3D(&dist, &cobj->vec.eye, &cobj->vec.at)
	if wallpaper_sobj == null or dist == null:
		return

	mag = syVectorMag3D(dist)

	if dist.z < 0.0:
		angle.x = 0.0
		angle.y = 0.0
	else:
		angle.y = syUtilsArcTan2(dist.x, dist.z)
		angle.x = syUtilsArcTan2(dist.y, dist.z)

	scale = 20000.0 / (mag + 8000.0)

	if scale < 1.004:
		scale = 1.004
	elif scale > 2.0:
		scale = 2.0

	wallpaper_sobj.sprite.scalex = scale
	wallpaper_sobj.sprite.scaley = scale

	width = 300.0 * scale     # Background image width  is 300px
	height = 220.0 * scale    # Background image height is 220px

	bak_pos_x = ((angle.y / F_CST_DTOR32(180.0)) * width) - ((width - 320.0) * 0.5)
	pos_x = bak_pos_x
	bak_pos_y = ((-angle.x / F_CST_DTOR32(180.0)) * height) - ((height - 240.0) * 0.5)
	pos_y = bak_pos_y

	if bak_pos_x > 10.0:
		pos_x = 10.0
	else:
		neg = (-width - 10.0) + 320.0

		if bak_pos_x < neg:
			pos_x = neg

	if bak_pos_y > 10.0:
		pos_y = 10.0
	else:
		neg = (-height - 10.0) + 240.0

		if bak_pos_y < neg:
			pos_y = neg

	wallpaper_sobj.pos.x = pos_x
	wallpaper_sobj.pos.y = pos_y

## 0x80104830
static func grWallpaperCommonProcUpdate(wallpaper_gobj = null) -> void:
	grWallpaperCalcPersp(_grWallpaperGetSObj(wallpaper_gobj))

## 0x80104850
static func grWallpaperMakeCommon() -> void:
	var wallpaper_gobj
	var wallpaper_sobj

	wallpaper_gobj = Lbcommon.lbCommonMakeSpriteGObj(
		nGCCommonKindWallpaper,
		null,
		nGCCommonLinkIDWallpaper,
		GOBJ_PRIORITY_DEFAULT,
		Callable(Lbcommon, &"lbCommonDrawSObjAttr"),
		0,
		GOBJ_PRIORITY_DEFAULT,
		~0,
		Grdisplay.grDisplayGetGroundData().get("wallpaper"),
		nGCProcessKindFunc,
		Callable(Grwallpaper, &"grWallpaperCommonProcUpdate"),
		3
	)
	sGRWallpaperGObj = wallpaper_gobj
	wallpaper_sobj = _grWallpaperGetSObj(wallpaper_gobj)
	if wallpaper_sobj == null:
		return

	wallpaper_sobj.pos.x = 10.0
	wallpaper_sobj.pos.y = 10.0

	wallpaper_sobj.sprite.attr = SP_TEXSHUF
	wallpaper_sobj.sprite.scalex = 1.004
	wallpaper_sobj.sprite.scaley = 1.004

## 0x801048F8
static func grWallpaperMakeStatic() -> void:
	var wallpaper_gobj
	var wallpaper_sobj

	wallpaper_gobj = Lbcommon.lbCommonMakeSpriteGObj(
		nGCCommonKindWallpaper,
		null,
		nGCCommonLinkIDWallpaper,
		GOBJ_PRIORITY_DEFAULT,
		Callable(Lbcommon, &"lbCommonDrawSObjAttr"),
		0,
		GOBJ_PRIORITY_DEFAULT,
		-1,
		Grdisplay.grDisplayGetGroundData().get("wallpaper"),
		nGCProcessKindFunc,
		Callable(),
		3
	)
	sGRWallpaperGObj = wallpaper_gobj
	wallpaper_sobj = _grWallpaperGetSObj(wallpaper_gobj)
	if wallpaper_sobj == null:
		return

	wallpaper_sobj.pos.x = 10.0
	wallpaper_sobj.pos.y = 10.0

	wallpaper_sobj.sprite.attr = SP_TEXSHUF | SP_FASTCOPY
	wallpaper_sobj.sprite.scalex = 1.0
	wallpaper_sobj.sprite.scaley = 1.0

## 0x80104998
static func grWallpaperSectorProcUpdate(wallpaper_gobj = null) -> void:
	var dist
	var sqrt_: float
	var temp: float
	var scale: float
	var wallpaper_sobj

	dist = _grWallpaperGetCameraDist(_grWallpaperGetCObj())   # cobj = gGMCameraGObj->obj
	if dist == null:
		return

	sqrt_ = sqrtf(SQUARE(dist.x) + SQUARE(dist.y) + SQUARE(dist.z))

	if sqrt_ > 0.0:
		temp = 20000.0 / (sqrt_ + 10000.0)

		if temp < 1.004:
			temp = 1.004
		elif temp > 2.0:
			temp = 2.0

		scale = (temp - 1.0) * 0.5

		wallpaper_sobj = _grWallpaperGetSObj(wallpaper_gobj)
		if wallpaper_sobj == null:
			return

		wallpaper_sobj.sprite.scalex = temp
		wallpaper_sobj.sprite.scaley = temp

		wallpaper_sobj.pos.x = 10.0 - (300.0 * scale)
		wallpaper_sobj.pos.y = 10.0 - (220.0 * scale)

## 0x80104ABC
static func grWallpaperMakeSector() -> void:
	var wallpaper_gobj
	var wallpaper_sobj

	wallpaper_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindWallpaper, null, nGCCommonLinkIDWallpaper, GOBJ_PRIORITY_DEFAULT)
	sGRWallpaperGObj = wallpaper_gobj

	Objman.gcAddGObjDisplay(wallpaper_gobj, Callable(Lbcommon, &"lbCommonDrawSObjAttr"), 0, GOBJ_PRIORITY_DEFAULT, ~0)

	wallpaper_sobj = Lbcommon.lbCommonMakeSObjForGObj(wallpaper_gobj, Grdisplay.grDisplayGetGroundData().get("wallpaper"))

	if wallpaper_sobj != null:
		wallpaper_sobj.pos.x = 10.0
		wallpaper_sobj.pos.y = 10.0

		wallpaper_sobj.sprite.attr = SP_TEXSHUF

	Objman.gcAddGObjProcess(wallpaper_gobj, Callable(Grwallpaper, &"grWallpaperSectorProcUpdate"), nGCProcessKindFunc, 3)

## 0x80104B58
static func grWallpaperBonus3ProcDisplay(wallpaper_gobj = null) -> void:
	# gSPDisplayList(gSYTaskmanDLHeads[0]++, dGRWallpaperDisplayList);
	pass

## 0x80104B88
static func grWallpaperMakeBonus3() -> void:
	var wallpaper_gobj

	wallpaper_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindWallpaper, null, nGCCommonLinkIDWallpaper, GOBJ_PRIORITY_DEFAULT)
	sGRWallpaperGObj = wallpaper_gobj

	Objman.gcAddGObjDisplay(wallpaper_gobj, Callable(Grwallpaper, &"grWallpaperBonus3ProcDisplay"), 0, GOBJ_PRIORITY_DEFAULT, ~0)

## 0x80104BDC
static func grWallpaperMakeDecideKind() -> void:
	if G.gSCManagerSceneData.scene_curr == nSCKind1PTrainingMode:
		StubLog.hit("sc1PTrainingModeLoadWallpaper")   # src/sc/sc1pmode/sc1ptrainingmode.c (not ported)
		grWallpaperMakeStatic()
	elif G.gSCManagerBattleState.gkind >= nGRKindBonusStageStart:
		grWallpaperMakeStatic()
	else:
		match G.gSCManagerBattleState.gkind:
			nGRKindYoster, nGRKindYosterSmall:
				grWallpaperMakeStatic()
			nGRKindSector:
				grWallpaperMakeSector()
			nGRKindBonus3:
				grWallpaperMakeBonus3()
			nGRKindLast:
				StubLog.hit("sc1PGameBossInitWallpaper")   # src/sc/sc1pmode/sc1pgameboss.c (not ported)
				grWallpaperMakeCommon()
			_:
				grWallpaperMakeCommon()

## 0x80104CB4
static func grWallpaperPausePerspUpdate() -> void:
	sGRWallpaperIsPausePerspUpdate = TRUE   # ??? Runs when the game is paused

## 0x80104CC4
static func grWallpaperResumePerspUpdate() -> void:
	sGRWallpaperIsPausePerspUpdate = FALSE   # Similarly, this runs when the game is unpaused

## 0x80104CD0 - New file?
static func grWallpaperRunProcessAll() -> void:
	if sGRWallpaperGObj == null:
		return
	for gobjproc in sGRWallpaperGObj.processes:
		if gobjproc.is_paused == false:
			if gobjproc.proc.is_valid():
				gobjproc.proc.call(sGRWallpaperGObj)

## 0x80104D30
static func grWallpaperResumeProcessAll() -> void:
	for gobj in Sim.get_link(nGCCommonLinkIDWallpaper):
		if gobj.gobj_kind == nGCCommonKindWallpaper:
			Objhelper.gcResumeGObjProcessAll(gobj)
