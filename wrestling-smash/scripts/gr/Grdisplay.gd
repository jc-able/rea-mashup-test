## 1:1 port of src/gr/grdisplay.c (geometry layer GObjs of a stage).
##
## The second half of this file ("GR port runtime support") is NOT part of grdisplay.c: it is the
## port-side stand-in for the relocData stage files the ground code reads with pointer arithmetic
## (`map_head + &llGR...`) and for the objanim.c/lbcommon.c functions the stage code needs that are
## still stubs in ObjAnim (gcAddAnimJointAll, gcAddAnimAll, gcSetupCustomDObjs, MObj material
## animation, ...). See the section header below.
class_name Grdisplay
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8012E800 - GRDisplayDesc {pri_proc_display, sec_proc_display, dl_link, proc_update}
static var dGRDisplayDescs: Array = [
	# Layer 0
	{"pri_proc_display": Callable(Grdisplay, &"grDisplayLayer0PriProcDisplay"), "sec_proc_display": Callable(Grdisplay, &"grDisplayLayer0SecProcDisplay"), "dl_link": 4, "proc_update": Callable(Grdisplay, &"gcPlayAnimAll")},
	# Layer 1
	{"pri_proc_display": Callable(Grdisplay, &"grDisplayLayer1PriProcDisplay"), "sec_proc_display": Callable(Grdisplay, &"grDisplayLayer1SecProcDisplay"), "dl_link": 6, "proc_update": Callable(Mpcollision, &"mpCollisionPlayYakumonoAnim")},
	# Layer 2
	{"pri_proc_display": Callable(Grdisplay, &"grDisplayLayer2PriProcDisplay"), "sec_proc_display": Callable(Grdisplay, &"grDisplayLayer2SecProcDisplay"), "dl_link": 13, "proc_update": Callable(Grdisplay, &"gcPlayAnimAll")},
	# Layer 3
	{"pri_proc_display": Callable(Grdisplay, &"grDisplayLayer3PriProcDisplay"), "sec_proc_display": Callable(Grdisplay, &"grDisplayLayer3SecProcDisplay"), "dl_link": 17, "proc_update": Callable(Grdisplay, &"gcPlayAnimAll")},
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //
# The RDP commands (gDPPipeSync / gSPClear/SetGeometryMode / gDPSetRenderMode on gSYTaskmanDLHeads)
# only select z-buffer and render modes for the display lists; they are kept as comments.

## 0x80104D90
static func grDisplayLayer0PriProcDisplay(ground_gobj = null) -> void:
	# gDPPipeSync(gSYTaskmanDLHeads[0]++); gSPClearGeometryMode(.., G_ZBUFFER); gDPSetRenderMode(.., G_RM_AA_OPA_SURF, G_RM_AA_OPA_SURF2);
	Objdisplay.gcDrawDObjTreeForGObj(ground_gobj)
	# gDPPipeSync; gSPSetGeometryMode(.., G_ZBUFFER); gDPSetRenderMode(.., G_RM_AA_ZB_OPA_SURF, G_RM_AA_ZB_OPA_SURF2);

## 0x80104E70
static func grDisplayLayer0SecProcDisplay(ground_gobj = null) -> void:
	# [0]: clear G_ZBUFFER, G_RM_AA_OPA_SURF; [1]: clear G_ZBUFFER, G_RM_AA_XLU_SURF
	Objdisplay.gcDrawDObjTreeDLLinksForGObj(ground_gobj)
	# [0]: set G_ZBUFFER, G_RM_AA_ZB_OPA_SURF; [1]: set G_ZBUFFER, G_RM_AA_ZB_XLU_SURF

## 0x80104FD8
static func grDisplayLayer1PriProcDisplay(ground_gobj = null) -> void:
	# [0]: set G_ZBUFFER, G_RM_AA_ZB_OPA_SURF; [1]: G_RM_AA_ZB_XLU_SURF
	Objdisplay.gcDrawDObjTreeForGObj(ground_gobj)

## 0x80105088
static func grDisplayLayer1SecProcDisplay(ground_gobj = null) -> void:
	# [0]: set G_ZBUFFER, G_RM_AA_ZB_OPA_SURF; [1]: set G_ZBUFFER, G_RM_AA_ZB_XLU_SURF
	Objdisplay.gcDrawDObjTreeDLLinksForGObj(ground_gobj)

## 0x80105154
static func grDisplayLayer2PriProcDisplay(ground_gobj = null) -> void:
	# [0]: clear G_ZBUFFER, G_RM_AA_OPA_SURF
	Objdisplay.gcDrawDObjTreeForGObj(ground_gobj)

## 0x801051D0
static func grDisplayLayer2SecProcDisplay(ground_gobj = null) -> void:
	# [0]: clear G_ZBUFFER, G_RM_AA_OPA_SURF; [1]: clear G_ZBUFFER, G_RM_AA_XLU_SURF
	Objdisplay.gcDrawDObjTreeDLLinksForGObj(ground_gobj)

## 0x80105290 - Identical to 0x80105154?
static func grDisplayLayer3PriProcDisplay(ground_gobj = null) -> void:
	# [0]: clear G_ZBUFFER, G_RM_AA_OPA_SURF
	Objdisplay.gcDrawDObjTreeForGObj(ground_gobj)

## 0x8010530C - Identical to 0x801051D0?
static func grDisplayLayer3SecProcDisplay(ground_gobj = null) -> void:
	# [0]: clear G_ZBUFFER, G_RM_AA_OPA_SURF; [1]: clear G_ZBUFFER, G_RM_AA_XLU_SURF
	Objdisplay.gcDrawDObjTreeDLLinksForGObj(ground_gobj)

## 0x801053CC
## dobjdesc: GRPtr to the layer's DObjDesc array (walked in parallel with the DObj tree, like `dobjdesc++`).
static func grDisplayDObjSetNoAnimXObj(ground_gobj = null, dobjdesc = null) -> void:
	var root_dobj: DObj
	var next_dobj: DObj
	var descs: Array = grDisplayGetDObjDescs(dobjdesc)
	var k := 0

	root_dobj = DObjGetStruct(ground_gobj)
	next_dobj = root_dobj

	while next_dobj != null:
		var id: int = descs[k].id if k < descs.size() else DOBJ_ARRAY_MAX
		if next_dobj.aobj.is_empty() and not (id & 0xF000):
			# for (i = 0; i < next_dobj->xobjs_num; i++) next_dobj->xobjs[i]->unk05 = 1;
			if not grDisplayGetXObjs(next_dobj).is_empty():
				next_dobj.xobj_unk05 = 1
		k += 1   # dobjdesc++

		next_dobj = ObjAnim.lbCommonGetTreeDObjNextFromRoot(next_dobj, root_dobj)

## 0x8010547C
## gr_desc: MPGroundDesc view {dobjdesc, anim_joints, p_mobjsubs, p_matanim_joints} (GRPtr or null each).
## dobjs: output Array (gMPCollisionYakumonoDObjs->dobjs for layer 1) or null.
static func grDisplayMakeGeometryLayer(gr_desc = null, gr_desc_id = null, dobjs = null):
	var ground_gobj
	var proc_display: Callable

	if gr_desc == null or gr_desc.dobjdesc == null:
		return null
	ground_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindGroundDisplay, null, nGCCommonLinkIDGroundDisplay, GOBJ_PRIORITY_DEFAULT)

	if grDisplayGetGroundData().layer_mask & (1 << gr_desc_id):
		proc_display = dGRDisplayDescs[gr_desc_id].sec_proc_display
	else:
		proc_display = dGRDisplayDescs[gr_desc_id].pri_proc_display

	Objman.gcAddGObjDisplay(ground_gobj, proc_display, dGRDisplayDescs[gr_desc_id].dl_link, GOBJ_PRIORITY_DEFAULT, ~0)
	gcSetupCustomDObjs(ground_gobj, gr_desc.dobjdesc, dobjs, nGCMatrixKindTraRotRpyRSca, nGCMatrixKindNull, nGCMatrixKindNull)

	if gr_desc.p_mobjsubs != null:
		gcAddMObjAll(ground_gobj, gr_desc.p_mobjsubs)

	if (gr_desc.anim_joints != null) or (gr_desc.p_matanim_joints != null):
		gcAddAnimAll(ground_gobj, gr_desc.anim_joints, gr_desc.p_matanim_joints, 0.0)
		Objman.gcAddGObjProcess(ground_gobj, dGRDisplayDescs[gr_desc_id].proc_update, nGCProcessKindFunc, 4)
		gcPlayAnimAll(ground_gobj)
	elif gr_desc_id == 1:
		Objman.gcAddGObjProcess(ground_gobj, Callable(Mpcollision, &"mpCollisionAdvanceUpdateTic"), nGCProcessKindFunc, 4)

	grDisplayDObjSetNoAnimXObj(ground_gobj, gr_desc.dobjdesc)

	return ground_gobj


# =====================================================================================================
#   GR port runtime support (not part of grdisplay.c)
# =====================================================================================================
# 1. relocData file images.  The C stage code computes pointers into the stage's relocData files
#    (`map_head = map_nodes - &llGR...MapHead; map_head + &llGR...AnimJoint`).  Here a file is a sparse
#    image {byte offset: u32 word} plus its relocated pointer slots, and a pointer is a GRPtr {fid, off}.
#    Images are filled from (a) the AObjEvent32 streams exported in game/data/ssb64/stages/<key>.json
#    (ingested first) and (b) the words embedded by tools/port/gr/gen_gr_file_images.py in each stage
#    class (const dGR<Stage>FileImages: DObjDescs, pointer tables, MObjSubs, streams the JSON lacks).
# 2. objanim.c / lbcommon.c functions that ObjAnim still stubs (gcSetupCustomDObjs, gcAddMObjAll,
#    gcAddAnimJointAll, gcAddMatAnimJointAll, gcAddAnimAll, MObj material animation, gcPlayAnimAll with
#    MObjs, lbCommonAddTreeDObjsAnimAll with MatAnimJoints, lbCommonAddMObjForTreeDObjs), taking GRPtr
#    pointers.  DObj joint animation itself is run by ObjAnim (gcParseDObjAnimJoint/gcPlayDObjAnimJoint).
#    MObjs are attached to DObjs as metadata "mobjs" (Array of GRMObj) since core DObj has no mobj field;
#    XObj transform kinds as metadata "xobjs" (Array of nGCMatrixKind*).
# 3. Access to Mpcollision globals (gMPCollisionGroundData view, gMPCollisionYakumonoDObjs).

## C pointer into a loaded relocData file.
class GRPtr:
	var fid: int = 0
	var off: int = 0
	func _init(f: int = 0, o: int = 0) -> void:
		fid = f
		off = o
	func plus(o: int) -> GRPtr:
		return GRPtr.new(fid, off + o)
	func _to_string() -> String:
		return "GRPtr(%d:0x%X)" % [fid, off]

## One relocData file image.
class GRFile:
	var fid: int = 0
	var words: Dictionary = {}     # byte offset -> u32
	var ptrs: Dictionary = {}      # byte offset -> [file id, byte offset, kind]  (kind 1 stream, 2 interp, 0 other)
	var runs: Array = []           # [[start byte offset, end byte offset, AnimStream]] built by grDisplayFinalizeFile
	var is_final: bool = false

## MObj (src/sys/objtypes.h) - material of a DObj; only the animation state + animated values.
class GRMObj:
	var sub: Dictionary = {}       # MObjSub fields (trau, trav, scau, scav, scrollu, scrollv, unk24, unk28, colors, ...)
	var texture_id_curr: int = 0
	var texture_id_next: int = 0
	var lfrac: float = 0.0
	var palette_id: float = 0.0
	var aobj: Array = []           # AObj tracks (C linked list mobj->aobj)
	var anim_data: AnimStream = null   # matanim_joint.event32 (stream + position)
	var anim_pos: int = -1
	var anim_wait: float = SSBDefs.F32_MIN
	var anim_speed: float = 1.0
	var anim_frame: float = 0.0

const GR_PTR_KIND_OTHER := 0
const GR_PTR_KIND_STREAM := 1
const GR_PTR_KIND_INTERP := 2

## Keys of game/data/ssb64/stages/<key>.json by GRKind (nGRKindCastle .. nGRKindLast).
const GR_STAGE_JSON_KEYS: Dictionary = {
	0: "castle", 1: "sector", 2: "jungle", 3: "zebes", 4: "hyrule", 5: "yoster", 6: "pupupu", 7: "yamabuki",
	8: "inishie", 11: "explain", 13: "metal", 14: "zako", 16: "last",
}
const GR_STAGE_JSON_DIR := "res://data/ssb64/stages/"

static var sGRDisplayFiles: Dictionary = {}          # file id -> GRFile
static var sGRDisplayInterps: Dictionary = {}        # "fid:off" -> SYInterpDesc Dictionary
static var sGRDisplayEmptyStream: AnimStream = null  # stand-in for a stream whose words are not loaded (End)
static var sGRDisplayJSONCache: Dictionary = {}      # key -> parsed stage json
static var sGRDisplayGroundData: Dictionary = {}     # MPGroundData view of the loaded stage
static var sGRDisplayLoadedKind: int = -1
static var sGRDisplayYakumonoDObjs: Array = []       # fallback storage when Mpcollision has no gMPCollisionYakumonoDObjs yet

# ---------------------------------------------------------------------------------------------------
# Stage data loading
# ---------------------------------------------------------------------------------------------------
## Port-side loader (C: mpCollisionInitGroundData loads the map file; the stage files are part of the
## scene's file list).  Loads the stage JSON + the stage class' embedded images for `gkind`.
static func grDisplayLoadGroundFiles(gkind: int, images: Array = []) -> bool:
	sGRDisplayFiles.clear()
	sGRDisplayInterps.clear()
	sGRDisplayGroundData = {}
	sGRDisplayLoadedKind = gkind
	var stage_json := grDisplayGetStageJSON(gkind)
	if not stage_json.is_empty():
		grDisplayIngestStageJSON(stage_json)
		sGRDisplayGroundData = grDisplayMakeGroundData(stage_json)
	grDisplayAddFileImages(images)
	return not stage_json.is_empty()

## Parsed game/data/ssb64/stages/<key>.json of `gkind` ({} when unavailable). Reuses the copy
## Mpcollision parsed for the same stage (Mpcollision.port_stage_json); only the last stage is cached.
static func grDisplayGetStageJSON(gkind: int) -> Dictionary:
	if not GR_STAGE_JSON_KEYS.has(gkind):
		return {}
	var key: String = GR_STAGE_JSON_KEYS[gkind]
	if sGRDisplayJSONCache.has(key):
		return sGRDisplayJSONCache[key]
	sGRDisplayJSONCache.clear()
	var result: Dictionary = {}
	var mp_json = grDisplayGetMPCollisionGlobal("port_stage_json")
	if (mp_json is Dictionary) and (int(mp_json.get("gr_kind_value", -1)) == gkind):
		result = mp_json
	else:
		var path := GR_STAGE_JSON_DIR + key + ".json"
		if FileAccess.file_exists(path):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
			if parsed is Dictionary:
				result = parsed
	sGRDisplayJSONCache[key] = result
	return result

static func _json_hex(v) -> int:
	if v is String:
		return (v as String).hex_to_int()
	return int(v)

static func _json_ptr(r) -> GRPtr:
	if r == null or not (r is Dictionary):
		return null
	return GRPtr.new(int(r.file_id), _json_hex(r.offset))

## Every {file_id, offset, events[]} dictionary of the stage JSON is an exported AObjEvent32 stream:
## its "raw" words go into the file images, Jump/SetAnim/SetInterp targets become pointer slots.
static func grDisplayIngestStageJSON(o) -> void:
	if o is Dictionary:
		if o.has("file_id") and o.has("offset") and o.has("events") and (o.events is Array):
			var fid := int(o.file_id)
			for ev in o.events:
				if not (ev is Dictionary) or not ev.has("offset") or not ev.has("raw"):
					continue
				var base := _json_hex(ev.offset)
				var raw: Array = ev.raw
				for i in raw.size():
					_grFileSetWord(fid, base + 4 * i, ("0x" + str(raw[i])).hex_to_int(), false)
				var op := int(ev.get("opcode", -1))
				if ev.has("target") and ev.target != null and (op == nGCAnimEvent32Jump or op == nGCAnimEvent32SetAnim or op == nGCAnimEvent32SetInterp):
					var kind := GR_PTR_KIND_INTERP if op == nGCAnimEvent32SetInterp else GR_PTR_KIND_STREAM
					_grFileSetPtr(fid, base + 4, int(ev.target.file_id), _json_hex(ev.target.offset), kind, false)
		for v in o.values():
			if v is Dictionary or v is Array:
				grDisplayIngestStageJSON(v)
	elif o is Array:
		for v in o:
			if v is Dictionary or v is Array:
				grDisplayIngestStageJSON(v)

## Adds embedded images (const dGR<Stage>FileImages); words already present (from the JSON) are kept.
static func grDisplayAddFileImages(images: Array) -> void:
	for image in images:
		var fid := int(image.fid)
		var w: Dictionary = image.w
		for start in w:
			var ws: Array = w[start]
			for i in ws.size():
				_grFileSetWord(fid, int(start) + 4 * i, int(ws[i]), false)
		var p: Dictionary = image.p
		for o in p:
			var t: Array = p[o]
			_grFileSetPtr(fid, int(o), int(t[0]), int(t[1]), int(t[2]), false)

static func _grFileGet(fid: int) -> GRFile:
	if not sGRDisplayFiles.has(fid):
		var f := GRFile.new()
		f.fid = fid
		sGRDisplayFiles[fid] = f
	return sGRDisplayFiles[fid]

static func _grFileSetWord(fid: int, off: int, value: int, overwrite: bool) -> void:
	var f := _grFileGet(fid)
	if overwrite or not f.words.has(off):
		f.words[off] = value & 0xFFFFFFFF
		f.is_final = false

static func _grFileSetPtr(fid: int, off: int, tfid: int, toff: int, kind: int, overwrite: bool) -> void:
	var f := _grFileGet(fid)
	if not f.words.has(off):
		f.words[off] = 0
	if overwrite or not f.ptrs.has(off):
		f.ptrs[off] = [tfid, toff, kind]
		f.is_final = false
	elif kind != GR_PTR_KIND_OTHER:
		f.ptrs[off][2] = kind

## MPGroundData view of the stage JSON's ground_data (pointers as GRPtr).
## "header" is (void*)gMPCollisionGroundData (map file + MapHeader offset) for `gMPCollisionGroundData - &ll...MapHeader`.
static func grDisplayMakeGroundData(stage_json: Dictionary) -> Dictionary:
	var gd: Dictionary = stage_json.get("ground_data", {})
	var gr_desc: Array = []
	var src_gr_desc: Array = gd.get("gr_desc", [])
	for i in 4:
		var d = src_gr_desc[i] if i < src_gr_desc.size() else {}
		gr_desc.append({
			"dobjdesc": _json_ptr(d.get("dobjdesc")),
			"anim_joints": _json_ptr(d.get("anim_joints")),
			"p_mobjsubs": _json_ptr(d.get("p_mobjsubs")),
			"p_matanim_joints": _json_ptr(d.get("p_matanim_joints")),
		})
	var view := {"gr_desc": gr_desc}
	for k in gd:
		if k != "gr_desc" and k != "map_nodes":
			var v = gd[k]
			view[k] = int(v) if (v is float) and (v == floor(v)) else v
	view["map_nodes"] = _json_ptr(gd.get("map_nodes"))
	var src: Dictionary = stage_json.get("source", {})
	var mf = src.get("map_file", null)
	view["header"] = GRPtr.new(int(mf.file_id), _json_hex(mf.header_offset)) if mf is Dictionary else null
	return view

## gMPCollisionGroundData (view): {gr_desc[4], layer_mask, map_bound_*, map_nodes, wallpaper, header, ...}.
static func grDisplayGetGroundData() -> Dictionary:
	if sGRDisplayLoadedKind != G.gSCManagerBattleState.gkind:
		Grmainsetup.grMainSetupLoadGroundFiles(G.gSCManagerBattleState.gkind)
	if sGRDisplayGroundData.is_empty():
		var gr_desc: Array = []
		for i in 4:
			gr_desc.append({"dobjdesc": null, "anim_joints": null, "p_mobjsubs": null, "p_matanim_joints": null})
		sGRDisplayGroundData = {"gr_desc": gr_desc, "layer_mask": 0, "map_nodes": null, "header": null, "map_bound_bottom": 0, "wallpaper": null}
	return sGRDisplayGroundData

## Mpcollision global by name (null while src/mp/mpcollision.c is unported / the variable is undeclared).
static func grDisplayGetMPCollisionGlobal(name: String):
	var s: Object = Mpcollision
	return s.get(name)

## gMPCollisionYakumonoDObjs->dobjs (falls back to local storage while Mpcollision has none).
static func grDisplayGetYakumonoDObjs() -> Array:
	var y = grDisplayGetMPCollisionGlobal("gMPCollisionYakumonoDObjs")
	if y is Array:
		return y
	if y is Dictionary and y.has("dobjs"):
		return y.dobjs
	if y is Object and ("dobjs" in y):
		return y.dobjs
	return sGRDisplayYakumonoDObjs

## gMPCollisionYakumonoDObjs->dobjs[id] (null when not created).
static func grDisplayGetYakumonoDObj(id: int) -> DObj:
	var dobjs: Array = grDisplayGetYakumonoDObjs()
	return dobjs[id] if (id >= 0 and id < dobjs.size()) else null

## A Vec3f out-value returned by another module (Vector3.ZERO while that module is a stub).
static func grDisplayVec3(r) -> Vector3:
	return r if r is Vector3 else Vector3.ZERO

## C pointer arithmetic `(uintptr_t)p + o` on a GRPtr (NULL stays NULL).
static func grDisplayPtrAdd(p, o: int) -> GRPtr:
	if p == null:
		return null
	return p.plus(o)

## mpCollisionGetMapObjIDsKind(kind, s32 *mapobjs): the ids it writes (pure output -> returned Array,
## PORTING.md convention). At least one element so `&pos_id` callers can index [0].
static func grDisplayGetMapObjIDsKind(mapobj_kind: int) -> Array:
	var r = Mpcollision.mpCollisionGetMapObjIDsKind(mapobj_kind)
	if r is Array and not r.is_empty():
		return r
	if r is int:
		return [r]
	return [0]

## mpCollisionGetMapObjPositionID(id, Vec3f *pos): pure output -> returned Vector3.
static func grDisplayGetMapObjPositionID(mapobj_id: int) -> Vector3:
	var r = Mpcollision.mpCollisionGetMapObjPositionID(mapobj_id)
	return r if r is Vector3 else Vector3.ZERO

# ---------------------------------------------------------------------------------------------------
# Particles (src/lb/lbparticle.c). The particle system is visual, but the ground code branches on its
# results (Hyrule's twister only exists when lbParticleMakeScriptID + lbParticleAddTransformForStruct
# succeed and the transform has users). While lbparticle.c is an unported stub (detected through
# StubLog) these wrappers hand out stand-in LBParticle/LBTransform/LBGenerator objects so the gameplay
# branches behave as on hardware; once Lbparticle is ported they forward unchanged.
# ---------------------------------------------------------------------------------------------------
class GRStandInTransform:          # LBTransform fields read/written by src/gr
	var translate: Vector3 = Vector3.ZERO
	var rotate: Vector3 = Vector3.ZERO
	var users_num: int = 1
	var generator_id: int = 0
	var status: int = 0

class GRStandInParticle:           # LBParticle
	var xf = null
	var bank_id: int = 0
	var script_id: int = 0

class GRStandInGenerator:          # LBGenerator
	var pos: Vector3 = Vector3.ZERO
	var bank_id: int = 0
	var script_id: int = 0

## lbdef.h LBPARTICLE_MASK_GENLINK(id)
static func LBPARTICLE_MASK_GENLINK(id: int) -> int:
	return (id + 1) * 8

static func lbParticleMakeScriptID(bank_id: int, script_id: int):
	var pc = Lbparticle.lbParticleMakeScriptID(bank_id, script_id)
	if pc == null and StubLog.seen.has("Lbparticle.lbParticleMakeScriptID"):
		pc = GRStandInParticle.new()
		pc.bank_id = bank_id
		pc.script_id = script_id
	return pc

static func lbParticleAddTransformForStruct(pc, status: int):
	if pc is GRStandInParticle:
		pc.xf = GRStandInTransform.new()
		pc.xf.status = status
		return pc.xf
	return Lbparticle.lbParticleAddTransformForStruct(pc, status)

static func LBParticleProcessStruct(pc) -> void:
	if not (pc is GRStandInParticle):
		Lbparticle.LBParticleProcessStruct(pc)

static func lbParticleEjectStruct(pc) -> void:
	if not (pc is GRStandInParticle):
		Lbparticle.lbParticleEjectStruct(pc)

static func lbParticleEjectStructID(generator_id: int, link_id: int) -> void:
	Lbparticle.lbParticleEjectStructID(generator_id, link_id)

static func lbParticleMakeGenerator(bank_id: int, script_id: int):
	var gn = Lbparticle.lbParticleMakeGenerator(bank_id, script_id)
	if gn == null and StubLog.seen.has("Lbparticle.lbParticleMakeGenerator"):
		gn = GRStandInGenerator.new()
		gn.bank_id = bank_id
		gn.script_id = script_id
	return gn

## efParticleGetLoadBankID(script_lo, script_hi, texture_lo, texture_hi) -> s32 bank id (0 while stubbed).
static func efParticleGetLoadBankID(script_lo: int, script_hi: int, texture_lo: int, texture_hi: int) -> int:
	var r = Efparticle.efParticleGetLoadBankID(script_lo, script_hi, texture_lo, texture_hi)
	return int(r) if (r is int or r is float) else 0

# ---------------------------------------------------------------------------------------------------
# Readers
# ---------------------------------------------------------------------------------------------------
static func grDisplayFileHasWord(p: GRPtr, o: int = 0) -> bool:
	if p == null or not sGRDisplayFiles.has(p.fid):
		return false
	return sGRDisplayFiles[p.fid].words.has((p.off + o) & ~3)

static func grDisplayFileU32(p: GRPtr, o: int = 0) -> int:
	if p == null or not sGRDisplayFiles.has(p.fid):
		return 0
	return sGRDisplayFiles[p.fid].words.get((p.off + o) & ~3, 0)

static func grDisplayFileS32(p: GRPtr, o: int = 0) -> int:
	var v := grDisplayFileU32(p, o)
	return v - 0x100000000 if v >= 0x80000000 else v

static func grDisplayFileU8(p: GRPtr, o: int = 0) -> int:
	var b := (p.off + o) if p != null else 0
	return (grDisplayFileU32(p, o) >> ((3 - (b & 3)) * 8)) & 0xFF

static func grDisplayFileS16(p: GRPtr, o: int = 0) -> int:
	var b := (p.off + o) if p != null else 0
	var v: int = (grDisplayFileU32(p, o) >> ((2 - (b & 2)) * 8)) & 0xFFFF
	return v - 0x10000 if v >= 0x8000 else v

static func grDisplayFileU16(p: GRPtr, o: int = 0) -> int:
	var b := (p.off + o) if p != null else 0
	return (grDisplayFileU32(p, o) >> ((2 - (b & 2)) * 8)) & 0xFFFF

static func grDisplayFileF32(p: GRPtr, o: int = 0) -> float:
	var b := PackedByteArray()
	b.resize(4)
	b.encode_u32(0, grDisplayFileU32(p, o))
	return b.decode_float(0)

static func grDisplayFileVec3f(p: GRPtr, o: int = 0) -> Vector3:
	return Vector3(grDisplayFileF32(p, o), grDisplayFileF32(p, o + 4), grDisplayFileF32(p, o + 8))

## Reads a pointer slot (C: *(void**)(p + o)); null for NULL / unloaded.
static func grDisplayFilePtr(p: GRPtr, o: int = 0) -> GRPtr:
	if p == null or not sGRDisplayFiles.has(p.fid):
		return null
	var t = sGRDisplayFiles[p.fid].ptrs.get(p.off + o, null)
	if t == null:
		return null
	return GRPtr.new(t[0], t[1])

## DObjDesc array at p (until id == DOBJ_ARRAY_MAX): [{id, dl, translate, rotate, scale}].
static func grDisplayGetDObjDescs(p) -> Array:
	var out: Array = []
	if p == null:
		return out
	var i := 0
	while i < DOBJ_ARRAY_MAX * 4:
		var o := i * 0x2C
		if not grDisplayFileHasWord(p, o):
			break
		var id := grDisplayFileS32(p, o)
		if id == DOBJ_ARRAY_MAX:
			break
		out.append({
			"id": id,
			"dl": grDisplayFilePtr(p, o + 0x4),
			"translate": grDisplayFileVec3f(p, o + 0x8),
			"rotate": grDisplayFileVec3f(p, o + 0x14),
			"scale": grDisplayFileVec3f(p, o + 0x20),
		})
		i += 1
	return out

## GRAttackColl at p: {kind, damage, angle, knockback_scale, knockback_weight, knockback_base, element}.
static func grDisplayGetAttackColl(p: GRPtr) -> Dictionary:
	return {
		"kind": grDisplayFileS32(p, 0x00),
		"damage": grDisplayFileS32(p, 0x04),
		"angle": grDisplayFileS32(p, 0x08),
		"knockback_scale": grDisplayFileS32(p, 0x0C),
		"knockback_weight": grDisplayFileS32(p, 0x10),
		"knockback_base": grDisplayFileS32(p, 0x14),
		"element": grDisplayFileS32(p, 0x18),
	}

## SYInterpDesc (src/sys/interp.h) at p as a Dictionary
## {kind, points_num, unk04, points: Array[Vector3], length, keyframes: Array[float], quartics: Array[float]}.
static func grDisplayGetInterpDesc(p: GRPtr):
	if p == null:
		return null
	var key := "%d:%d" % [p.fid, p.off]
	if sGRDisplayInterps.has(key):
		return sGRDisplayInterps[key]
	var kind := grDisplayFileU8(p, 0x0)
	var points_num := grDisplayFileS16(p, 0x2)
	var npoints: int
	match kind:
		0:
			npoints = points_num
		1:
			npoints = (points_num - 1) * 3 + 1
		_:
			npoints = points_num + 2
	var points: Array = []
	var pp := grDisplayFilePtr(p, 0x8)
	for i in npoints:
		points.append(grDisplayFileVec3f(pp, 12 * i) if pp != null else Vector3.ZERO)
	var keyframes: Array = []
	var kp := grDisplayFilePtr(p, 0x10)
	for i in points_num:
		keyframes.append(grDisplayFileF32(kp, 4 * i) if kp != null else 0.0)
	var quartics: Array = []
	var qp := grDisplayFilePtr(p, 0x14)
	for i in 5 * (points_num - 1):
		quartics.append(grDisplayFileF32(qp, 4 * i) if qp != null else 0.0)
	var desc := {"kind": kind, "points_num": points_num, "unk04": grDisplayFileF32(p, 0x4), "points": points,
			"length": grDisplayFileF32(p, 0xC), "keyframes": keyframes, "quartics": quartics, "ptr": p}
	sGRDisplayInterps[key] = desc
	return desc

## MObjSub at p as a Dictionary of the fields the material animation / renderer use.
static func grDisplayGetMObjSub(p: GRPtr) -> Dictionary:
	return {
		"ptr": p, "fmt": grDisplayFileU8(p, 0x2), "siz": grDisplayFileU8(p, 0x3),
		"trau": grDisplayFileF32(p, 0x14), "trav": grDisplayFileF32(p, 0x18),
		"scau": grDisplayFileF32(p, 0x1C), "scav": grDisplayFileF32(p, 0x20),
		"unk24": grDisplayFileF32(p, 0x24), "unk28": grDisplayFileF32(p, 0x28),
		"flags": grDisplayFileU16(p, 0x30), "scrollu": grDisplayFileF32(p, 0x3C), "scrollv": grDisplayFileF32(p, 0x40),
		"unk4C": grDisplayFileU32(p, 0x4C), "primcolor": grDisplayFileU32(p, 0x50), "prim_l": grDisplayFileU8(p, 0x54),
		"prim_m": grDisplayFileU8(p, 0x55), "envcolor": grDisplayFileU32(p, 0x58), "blendcolor": grDisplayFileU32(p, 0x5C),
		"light1color": grDisplayFileU32(p, 0x60), "light2color": grDisplayFileU32(p, 0x64),
		"unk68": grDisplayFileS32(p, 0x68), "unk6C": grDisplayFileS32(p, 0x6C), "unk70": grDisplayFileS32(p, 0x70), "unk74": grDisplayFileS32(p, 0x74),
	}

# ---------------------------------------------------------------------------------------------------
# AObjEvent32 streams
# ---------------------------------------------------------------------------------------------------
## Builds the AnimStream runs of a file image (one AnimStream per contiguous run of words) and resolves
## their pointer operands: Jump/SetAnim -> [AnimStream, word index]; SetInterp -> SYInterpDesc Dictionary.
static func grDisplayFinalizeFile(f: GRFile) -> void:
	if f.is_final:
		return
	f.is_final = true
	f.runs.clear()
	var offs: Array = f.words.keys()
	offs.sort()
	var run_start := -1
	var run_words: Array = []
	var prev := -8
	for o in offs:
		if o != prev + 4:
			if run_start >= 0:
				f.runs.append([run_start, prev + 4, AnimStream.from_u32(run_words, "%d:0x%X" % [f.fid, run_start])])
			run_start = o
			run_words = []
		run_words.append(f.words[o])
		prev = o
	if run_start >= 0:
		f.runs.append([run_start, prev + 4, AnimStream.from_u32(run_words, "%d:0x%X" % [f.fid, run_start])])
	for run in f.runs:
		var s: AnimStream = run[2]
		for o in f.ptrs:
			if o >= run[0] and o < run[1]:
				var t: Array = f.ptrs[o]
				if t[2] == GR_PTR_KIND_INTERP:
					s.ptr[(o - run[0]) / 4] = grDisplayGetInterpDesc(GRPtr.new(t[0], t[1]))
				elif t[2] == GR_PTR_KIND_STREAM:
					s.ptr[(o - run[0]) / 4] = grDisplayGetStreamPos(GRPtr.new(t[0], t[1]))

static func _grDisplayGetEmptyStream() -> AnimStream:
	if sGRDisplayEmptyStream == null:
		sGRDisplayEmptyStream = AnimStream.from_u32([0], "empty")   # nGCAnimEvent32End
	return sGRDisplayEmptyStream

## AObjEvent32 *p -> [AnimStream, word index] (an End stream when the words are not loaded).
static func grDisplayGetStreamPos(p: GRPtr) -> Array:
	if p == null or not sGRDisplayFiles.has(p.fid):
		return [_grDisplayGetEmptyStream(), 0]
	var f: GRFile = sGRDisplayFiles[p.fid]
	grDisplayFinalizeFile(f)
	for run in f.runs:
		if p.off >= run[0] and p.off < run[1]:
			return [run[2], (p.off - run[0]) / 4]
	return [_grDisplayGetEmptyStream(), 0]

# ---------------------------------------------------------------------------------------------------
# objanim.c / objman.c / lbcommon.c functions on GRPtr data (ObjAnim versions are stubs)
# ---------------------------------------------------------------------------------------------------
## gcAddXObjForDObjFixed + record the matrix kind (DObj has no xobjs list in core).
static func grDisplayAddXObj(dobj: DObj, kind: int, arg: int) -> void:
	Objman.gcAddXObjForDObjFixed(dobj, kind, arg)
	var x: Array = grDisplayGetXObjs(dobj)
	x.append(kind)
	dobj.set_meta(&"xobjs", x)

static func grDisplayGetXObjs(dobj: DObj) -> Array:
	return dobj.get_meta(&"xobjs", [])

## MObj list of a DObj (C: dobj->mobj linked list).
static func grDisplayGetMObjs(dobj: DObj) -> Array:
	return dobj.get_meta(&"mobjs", [])

## objanim.c gcAddDObj3TransformsKind
static func gcAddDObj3TransformsKind(dobj: DObj, tk1: int, tk2: int, tk3: int) -> void:
	if tk1 != nGCMatrixKindNull:
		grDisplayAddXObj(dobj, tk1, 0)
	if tk2 != nGCMatrixKindNull:
		grDisplayAddXObj(dobj, tk2, 0)
	if tk3 != nGCMatrixKindNull:
		grDisplayAddXObj(dobj, tk3, 0)

## objanim.c gcDecideDObj3TransformsKind
static func gcDecideDObj3TransformsKind(dobj: DObj, tk1: int, tk2: int, tk3: int, flags: int) -> void:
	var tra_mode := 0
	var sca_mode := 0
	var rot_mode := 0
	match tk1:
		nGCMatrixKindTra:
			tra_mode = 1
		nGCMatrixKindRotRpyR:
			rot_mode = 1
		nGCMatrixKindTraRotRpyR:
			rot_mode = 1
			tra_mode = 1
		nGCMatrixKindTraRotRpyRSca:
			sca_mode = 1
			rot_mode = 1
			tra_mode = 1
		nGCMatrixKindRotPyrR:
			rot_mode = 2
		nGCMatrixKindTraRotPyrR:
			rot_mode = 2
			tra_mode = 1
		nGCMatrixKindTraRotPyrRSca:
			rot_mode = 2
			sca_mode = 1
			tra_mode = 1
		nGCMatrixKindSca:
			sca_mode = 1
	match tk2:
		nGCMatrixKindRotRpyR:
			rot_mode = 1
		nGCMatrixKindRotPyrR:
			rot_mode = 2
		nGCMatrixKindSca:
			sca_mode = 1
	if tk3 == nGCMatrixKindSca:
		sca_mode = 1
	if tra_mode != 0:
		grDisplayAddXObj(dobj, nGCMatrixKindTra, 0)
	if flags & 0x4000:
		grDisplayAddXObj(dobj, nGCMatrixKind46 if rot_mode == 1 else nGCMatrixKind45, 0)
	elif flags & 0x2000:
		grDisplayAddXObj(dobj, nGCMatrixKind48 if rot_mode == 1 else nGCMatrixKind47, 0)
	elif flags & 0x1000:
		grDisplayAddXObj(dobj, nGCMatrixKind50 if rot_mode == 1 else nGCMatrixKind49, 0)
	elif sca_mode != 0:
		grDisplayAddXObj(dobj, nGCMatrixKindRecalcRotRpyRSca if rot_mode == 1 else nGCMatrixKindRecalcRotPyrRSca, 0)
	elif rot_mode == 1:
		grDisplayAddXObj(dobj, nGCMatrixKindRecalcRotRpyR, 0)
	else:
		grDisplayAddXObj(dobj, nGCMatrixKindRecalcRotPyrR, 0)

static func _grDisplaySetOut(dobjs, i: int, dobj: DObj) -> void:
	if dobjs is Array:
		if i < dobjs.size():
			dobjs[i] = dobj
		else:
			while dobjs.size() < i:
				dobjs.append(null)
			dobjs.append(dobj)

## objanim.c gcSetupCustomDObjs (0x8000F590). dobjdesc: GRPtr; dobjs: output Array or null.
static func gcSetupCustomDObjs(gobj, dobjdesc, dobjs, tk1: int, tk2: int, tk3: int) -> void:
	var array_dobjs: Array = []
	array_dobjs.resize(DOBJ_ARRAY_MAX)
	var i := 0
	for desc in grDisplayGetDObjDescs(dobjdesc):
		var dobj: DObj
		var id: int = desc.id & 0xFFF

		if id != 0:
			dobj = Objman.gcAddChildForDObj(array_dobjs[id - 1], desc.dl)
			array_dobjs[id] = dobj
		else:
			dobj = Objman.gcAddDObjForGObj(gobj, desc.dl)
			array_dobjs[0] = dobj

		if desc.id & 0xF000:
			gcDecideDObj3TransformsKind(dobj, tk1, tk2, tk3, desc.id & 0xF000)
		else:
			gcAddDObj3TransformsKind(dobj, tk1, tk2, tk3)

		dobj.translate = desc.translate
		dobj.rotate = desc.rotate
		dobj.scale = desc.scale

		if dobjs != null:
			_grDisplaySetOut(dobjs, i, dobj)
		i += 1

## objman.c gcAddMObjForDObj (0x80008E78-ish): appends a MObj built from the MObjSub at mobjsub.
static func gcAddMObjForDObj(dobj: DObj, mobjsub: GRPtr) -> GRMObj:
	var mobj := GRMObj.new()
	var mobjs: Array = grDisplayGetMObjs(dobj)
	mobjs.append(mobj)
	dobj.set_meta(&"mobjs", mobjs)

	mobj.sub = grDisplayGetMObjSub(mobjsub)
	mobj.lfrac = mobj.sub.prim_l / 255.0
	mobj.sub.unk24 = mobj.sub.trau
	mobj.sub.unk28 = mobj.sub.scau
	mobj.texture_id_curr = 0
	mobj.texture_id_next = 0
	mobj.palette_id = 0
	mobj.aobj = []
	mobj.anim_data = null
	mobj.anim_pos = -1
	mobj.anim_wait = AOBJ_ANIM_NULL
	mobj.anim_speed = 1.0
	mobj.anim_frame = 0.0
	return mobj

## Adds the NULL-terminated MObjSub* list at mobjsubs to dobj.
static func _grDisplayAddMObjList(dobj: DObj, mobjsubs: GRPtr) -> void:
	var j := 0
	var mobjsub := grDisplayFilePtr(mobjsubs, 0)
	while mobjsub != null:
		gcAddMObjForDObj(dobj, mobjsub)
		j += 1
		mobjsub = grDisplayFilePtr(mobjsubs, 4 * j)

## objanim.c gcAddMObjAll. p_mobjsubs: GRPtr to MObjSub**[] (one entry per DObj in tree order).
static func gcAddMObjAll(gobj, p_mobjsubs) -> void:
	var dobj: DObj = DObjGetStruct(gobj)
	var k := 0
	while dobj != null:
		if p_mobjsubs != null:
			var mobjsubs := grDisplayFilePtr(p_mobjsubs, 4 * k)
			if mobjsubs != null:
				_grDisplayAddMObjList(dobj, mobjsubs)
			k += 1
		dobj = ObjAnim.gcGetTreeDObjNext(dobj)

## lbcommon.c lbCommonAddMObjForTreeDObjs
static func lbCommonAddMObjForTreeDObjs(root_dobj: DObj, p_mobjsubs) -> void:
	var current_dobj := root_dobj
	var k := 0
	while current_dobj != null:
		if p_mobjsubs != null:
			var mobjsubs := grDisplayFilePtr(p_mobjsubs, 4 * k)
			if mobjsubs != null:
				_grDisplayAddMObjList(current_dobj, mobjsubs)
			k += 1
		current_dobj = ObjAnim.lbCommonGetTreeDObjNextFromRoot(current_dobj, root_dobj)

## objanim.c gcAddDObjAnimJoint with a GRPtr (AObjEvent32*) instead of a stream start.
static func gcAddDObjAnimJoint(dobj: DObj, anim_joint, anim_frame: float) -> void:
	if anim_joint == null:
		ObjAnim.gcAddDObjAnimJoint(dobj, null, anim_frame)   # anim_joint.event32 = NULL
		return
	var sp: Array = grDisplayGetStreamPos(anim_joint)
	ObjAnim.gcAddDObjAnimJoint(dobj, sp[0], anim_frame)
	dobj.anim_pos = sp[1]

## objanim.c gcAddMObjMatAnimJoint
static func gcAddMObjMatAnimJoint(mobj: GRMObj, matanim_joint, anim_frame: float) -> void:
	for aobj in mobj.aobj:
		aobj.kind = nGCAnimKindNone
	if matanim_joint == null:
		mobj.anim_data = null
		mobj.anim_pos = -1
	else:
		var sp: Array = grDisplayGetStreamPos(matanim_joint)
		mobj.anim_data = sp[0]
		mobj.anim_pos = sp[1]
	mobj.anim_wait = AOBJ_ANIM_CHANGED
	mobj.anim_frame = anim_frame

static func _grDisplayAddMatAnimJoints(dobj: DObj, matanim_joints: GRPtr, anim_frame: float) -> void:
	var m := 0
	for mobj in grDisplayGetMObjs(dobj):
		var matanim_joint := grDisplayFilePtr(matanim_joints, 4 * m)
		if matanim_joint != null:
			gcAddMObjMatAnimJoint(mobj, matanim_joint, anim_frame)
		m += 1

## objanim.c gcAddAnimJointAll. anim_joints: GRPtr to AObjEvent32*[] (one per DObj in tree order).
static func gcAddAnimJointAll(gobj, anim_joints, anim_frame: float) -> void:
	var dobj: DObj = DObjGetStruct(gobj)
	var is_anim_root := true
	var k := 0

	gobj.anim_frame = anim_frame

	while dobj != null:
		var anim_joint := grDisplayFilePtr(anim_joints, 4 * k)
		if anim_joint != null:
			gcAddDObjAnimJoint(dobj, anim_joint, anim_frame)
			dobj.is_anim_root = is_anim_root
			is_anim_root = false
		else:
			dobj.anim_wait = AOBJ_ANIM_NULL
			dobj.is_anim_root = false
		k += 1
		dobj = ObjAnim.gcGetTreeDObjNext(dobj)

## objanim.c gcAddMatAnimJointAll
static func gcAddMatAnimJointAll(gobj, p_matanim_joints, anim_frame: float) -> void:
	var dobj: DObj = DObjGetStruct(gobj)
	var k := 0

	gobj.anim_frame = anim_frame

	while dobj != null:
		if p_matanim_joints != null:
			var matanim_joints := grDisplayFilePtr(p_matanim_joints, 4 * k)
			if matanim_joints != null:
				_grDisplayAddMatAnimJoints(dobj, matanim_joints, anim_frame)
			k += 1
		dobj = ObjAnim.gcGetTreeDObjNext(dobj)

## objanim.c gcAddAnimAll
static func gcAddAnimAll(gobj, anim_joints, p_matanim_joints, anim_frame: float) -> void:
	var dobj: DObj = DObjGetStruct(gobj)
	var is_anim_root := true
	var k := 0

	gobj.anim_frame = anim_frame

	while dobj != null:
		if anim_joints != null:
			var anim_joint := grDisplayFilePtr(anim_joints, 4 * k)
			if anim_joint != null:
				gcAddDObjAnimJoint(dobj, anim_joint, anim_frame)
				dobj.is_anim_root = is_anim_root
				is_anim_root = false
			else:
				dobj.anim_wait = AOBJ_ANIM_NULL
				dobj.is_anim_root = false
		if p_matanim_joints != null:
			var matanim_joints := grDisplayFilePtr(p_matanim_joints, 4 * k)
			if matanim_joints != null:
				_grDisplayAddMatAnimJoints(dobj, matanim_joints, anim_frame)
		k += 1
		dobj = ObjAnim.gcGetTreeDObjNext(dobj)

## lbcommon.c lbCommonAddTreeDObjsAnimAll (with the MatAnimJoint part that ObjAnim's version omits).
static func lbCommonAddTreeDObjsAnimAll(root_dobj: DObj, anim_joints, p_matanim_joints, anim_frame: float) -> void:
	var current_dobj := root_dobj
	var k := 0

	root_dobj.parent_gobj.anim_frame = anim_frame

	while current_dobj != null:
		if anim_joints != null:
			var anim_joint := grDisplayFilePtr(anim_joints, 4 * k)
			if anim_joint != null:
				gcAddDObjAnimJoint(current_dobj, anim_joint, anim_frame)
			else:
				current_dobj.anim_wait = AOBJ_ANIM_NULL
		if p_matanim_joints != null:
			var matanim_joints := grDisplayFilePtr(p_matanim_joints, 4 * k)
			if matanim_joints != null:
				_grDisplayAddMatAnimJoints(current_dobj, matanim_joints, anim_frame)
		k += 1
		current_dobj = ObjAnim.lbCommonGetTreeDObjNextFromRoot(current_dobj, root_dobj)

## objanim.c gcPlayAnimAll: per DObj gcParseDObjAnimJoint + gcPlayDObjAnimJoint, then the DObj's MObjs
## gcParseMObjMatAnimJoint + gcPlayMObjMatAnim.
static func gcPlayAnimAll(gobj = null) -> void:
	var dobj: DObj = DObjGetStruct(gobj)
	while dobj != null:
		ObjAnim.gcParseDObjAnimJoint(dobj)
		gcPlayDObjAnimJoint(dobj)
		if dobj.has_meta(&"mobjs"):
			for mobj in dobj.get_meta(&"mobjs"):
				gcParseMObjMatAnimJoint(mobj)
				gcPlayMObjMatAnim(mobj)
		dobj = ObjAnim.gcGetTreeDObjNext(dobj)

## objanim.c gcPlayDObjAnimJoint = ObjAnim.gcPlayDObjAnimJoint + the nGCAnimTrackTraI case it omits
## (`syInterpCubic(&dobj->translate, aobj->interpolate, CLAMP(value, 0, 1))`, used by the Sector Z
## Arwing flight paths). Translate tracks that follow the TraI track in the AObj list are re-applied
## so the per-track order of the C loop is kept.
static func gcPlayDObjAnimJoint(dobj: DObj) -> void:
	if dobj.anim_wait == AOBJ_ANIM_NULL:
		return
	ObjAnim.gcPlayDObjAnimJoint(dobj)

	if (dobj.parent_gobj != null) and (dobj.parent_gobj.gobj_flags & GOBJ_FLAG_NOANIM):
		return
	var is_after_trai := false
	for aobj in dobj.aobj:
		if aobj.kind == nGCAnimKindNone:
			continue
		if aobj.track == nGCAnimTrackTraI:
			var value := gcGetAObjValue(aobj)
			if value < 0.0:
				value = 0.0
			elif value > 1.0:
				value = 1.0
			dobj.translate = grDisplayInterpCubic(dobj.translate, aobj.interpolate, value)
			is_after_trai = true
		elif is_after_trai:
			match aobj.track:
				nGCAnimTrackTraX:
					dobj.translate.x = gcGetAObjValue(aobj)
				nGCAnimTrackTraY:
					dobj.translate.y = gcGetAObjValue(aobj)
				nGCAnimTrackTraZ:
					dobj.translate.z = gcGetAObjValue(aobj)

# ---------------------------------------------------------------------------------------------------
# src/sys/interp.c (syInterpCubic / syInterpQuad). Interp.gd is still an unported stub: these forward to
# it and fall back to the local copies below (same C expressions) while it returns no value.
# desc: SYInterpDesc Dictionary from grDisplayGetInterpDesc.
# ---------------------------------------------------------------------------------------------------
static func grDisplayInterpCubic(out: Vector3, desc, t: float) -> Vector3:
	if desc == null:
		return out
	var r = Interp.syInterpCubic(out, desc, t)
	if r is Vector3:
		return r
	return _grSyInterpCubicSplineTimeFrac(out, desc, _grSyInterpGetFracFrame(desc, t))

static func grDisplayInterpQuad(out: Vector3, desc, t: float) -> Vector3:
	if desc == null:
		return out
	var r = Interp.syInterpQuad(out, desc, t)
	if r is Vector3:
		return r
	return _grSyInterpQuadSplineTimeFrac(out, desc, _grSyInterpGetFracFrame(desc, t))

static func _grPt(points: Array, i: int) -> Vector3:
	return points[i] if (i >= 0 and i < points.size()) else Vector3.ZERO

static func _grSyInterpCatromCubicSpline(points: Array, b: int, s: float, t: float) -> Vector3:
	var sqt := t * t
	var cbt := sqt * t
	var w0 := (2.0 * sqt - cbt - t) * s
	var w1 := (2.0 - s) * cbt + (s - 3.0) * sqt + 1.0
	var w2 := (s - 2.0) * cbt + (3.0 - 2.0 * s) * sqt + s * t
	var w3 := (cbt - sqt) * s
	var c0 := _grPt(points, b)
	var c1 := _grPt(points, b + 1)
	var c2 := _grPt(points, b + 2)
	var c3 := _grPt(points, b + 3)
	return Vector3(c0.x * w0 + c1.x * w1 + c2.x * w2 + c3.x * w3, c0.y * w0 + c1.y * w1 + c2.y * w2 + c3.y * w3, c0.z * w0 + c1.z * w1 + c2.z * w2 + c3.z * w3)

static func _grSyInterpQuadSpline(points: Array, b: int, s: float, t: float) -> Vector3:
	var sqt := t * t
	var w0 := ((((-3.0) * sqt) + (4.0 * t)) - 1.0) * s
	var temp := s - 3.0
	var w3 := s
	var w1 := (((2.0 - w3) * 3.0) * sqt) + ((2.0 * temp) * t)
	temp = 3.0 - (2.0 * w3)
	var w2 := ((((w3 - 2.0) * 3.0) * sqt) + ((2.0 * temp) * t)) + w3
	w3 = ((3.0 * sqt) - (2.0 * t)) * w3
	var c0 := _grPt(points, b)
	var c1 := _grPt(points, b + 1)
	var c2 := _grPt(points, b + 2)
	var c3 := _grPt(points, b + 3)
	return Vector3((c0.x * w0) + (c1.x * w1) + (c2.x * w2) + (c3.x * w3), (c0.y * w0) + (c1.y * w1) + (c2.y * w2) + (c3.y * w3), (c0.z * w0) + (c1.z * w1) + (c2.z * w2) + (c3.z * w3))

static func _grSyInterpBezier3Points(points: Array, b: int, t: float) -> Vector3:
	var subt := 1.0 - t
	var sqt := t * t
	var cbt := sqt * t
	var w0 := (1.0 / 6.0) * subt * subt * subt
	var w1 := (1.0 / 6.0) * (3.0 * cbt - 6.0 * sqt + 4.0)
	var w2 := (1.0 / 6.0) * (3.0 * (sqt - cbt + t) + 1.0)
	var w3 := (1.0 / 6.0) * cbt
	var c0 := _grPt(points, b)
	var c1 := _grPt(points, b + 1)
	var c2 := _grPt(points, b + 2)
	var c3 := _grPt(points, b + 3)
	return Vector3(c0.x * w0 + c1.x * w1 + c2.x * w2 + c3.x * w3, c0.y * w0 + c1.y * w1 + c2.y * w2 + c3.y * w3, c0.z * w0 + c1.z * w1 + c2.z * w2 + c3.z * w3)

static func _grSyInterpBezier4Points(points: Array, b: int, t: float) -> Vector3:
	var sqt := t * t
	var w0 := 1.0 - t
	var w3 := -0.5 * w0 * w0
	var mt := ((3.0 * sqt) - (4.0 * t)) * 0.5
	var w1 := ((-3.0 * sqt) + (2.0 * t) + 1.0) * 0.5
	var w2 := 0.5 * sqt
	var c0 := _grPt(points, b)
	var c1 := _grPt(points, b + 1)
	var c2 := _grPt(points, b + 2)
	var c3 := _grPt(points, b + 3)
	return Vector3((c0.x * w3) + (c1.x * mt) + (c2.x * w1) + (c3.x * w2), (c0.y * w3) + (c1.y * mt) + (c2.y * w1) + (c3.y * w2), (c0.z * w3) + (c1.z * mt) + (c2.z * w1) + (c3.z * w2))

static func _grSyInterpCubicBezierScale(points: Array, b: int, t: float) -> Vector3:
	var subt := 1.0 - t
	var sqt := t * t
	var sqsubt := subt * subt
	var w0 := sqsubt * subt
	var w1 := 3.0 * t * sqsubt
	var w2 := 3.0 * sqt * subt
	var w3 := sqt * t
	var c0 := _grPt(points, b)
	var c1 := _grPt(points, b + 1)
	var c2 := _grPt(points, b + 2)
	var c3 := _grPt(points, b + 3)
	return Vector3(c0.x * w0 + c1.x * w1 + c2.x * w2 + c3.x * w3, c0.y * w0 + c1.y * w1 + c2.y * w2 + c3.y * w3, c0.z * w0 + c1.z * w1 + c2.z * w2 + c3.z * w3)

static func _grSyInterpQuadBezier4Points(points: Array, b: int, t: float) -> Vector3:
	var mt := t - 1.0
	var w3 := -3.0 * mt * mt
	var w0 := t * t
	w0 = 3.0 * w0
	var w1 := ((1.0 - (4.0 * t)) + w0) * 3.0
	var w2 := ((2.0 * t) - w0) * 3.0
	var c0 := _grPt(points, b)
	var c1 := _grPt(points, b + 1)
	var c2 := _grPt(points, b + 2)
	var c3 := _grPt(points, b + 3)
	return Vector3((c0.x * w3) + (c1.x * w1) + (c2.x * w2) + (c3.x * w0), (c0.y * w3) + (c1.y * w1) + (c2.y * w2) + (c3.y * w0), (c0.z * w3) + (c1.z * w1) + (c2.z * w2) + (c3.z * w0))

static func _grSyInterpCubicSplineTimeFrac(out: Vector3, desc: Dictionary, t: float) -> Vector3:
	var points: Array = desc.points
	var target_frame: int
	if (t < 0.0) or (t > 1.0):
		return out
	elif t < 1.0:
		t *= float(desc.points_num - 1)
		target_frame = int(t)
		t -= target_frame
		match desc.kind:
			nSYInterpKindLinear:
				var p0 := _grPt(points, target_frame)
				var p1 := _grPt(points, target_frame + 1)
				return Vector3((p1.x - p0.x) * t + p0.x, (p1.y - p0.y) * t + p0.y, (p1.z - p0.z) * t + p0.z)
			nSYInterpKindBezierS3:
				return _grSyInterpCubicBezierScale(points, target_frame * 3, t)
			nSYInterpKindBezier:
				return _grSyInterpBezier3Points(points, target_frame, t)
			nSYInterpKindCatrom:
				return _grSyInterpCatromCubicSpline(points, target_frame, desc.unk04, t)
	else:
		target_frame = desc.points_num - 1
		match desc.kind:
			nSYInterpKindLinear:
				return _grPt(points, target_frame)
			nSYInterpKindBezierS3:
				return _grPt(points, target_frame * 3)
			nSYInterpKindBezier:
				return _grSyInterpBezier3Points(points, target_frame - 1, 1.0)
			nSYInterpKindCatrom:
				return _grPt(points, target_frame + 1)
	return out

static func _grSyInterpQuadSplineTimeFrac(out: Vector3, desc: Dictionary, t: float) -> Vector3:
	var points: Array = desc.points
	if (t < 0.0) or (t > 1.0):
		return out
	var t_origin := t
	t *= float(desc.points_num - 1)
	var target_frame := int(t)
	t = t - float(target_frame)
	match desc.kind:
		nSYInterpKindLinear:
			if t_origin == 1.0:
				target_frame -= 1
			var p0 := _grPt(points, target_frame)
			var p1 := _grPt(points, target_frame + 1)
			return Vector3(p1.x - p0.x, p1.y - p0.y, p1.z - p0.z)
		nSYInterpKindBezierS3:
			return _grSyInterpQuadBezier4Points(points, target_frame * 3, t)
		nSYInterpKindBezier:
			return _grSyInterpBezier4Points(points, target_frame, t)
		nSYInterpKindCatrom:
			return _grSyInterpQuadSpline(points, target_frame, desc.unk04, t)
	return out

static func _grSyInterpGetQuartSum(x: float, cof: Array, b: int) -> float:
	var sum: float = cof[b] * (x * x * x * x) + cof[b + 1] * (x * x * x) + cof[b + 2] * (x * x) + cof[b + 3] * x + cof[b + 4]
	if (sum < 0.0) and (sum > -0.001):
		sum = 0.0
	return sqrt(sum)

static func _grSyInterpGetCubicIntegralApprox(t: float, f: float, cof: Array, b: int) -> float:
	var factor := (f - t) / 8
	var sum := 0.0
	var time_scale := t + factor
	for i in range(2, 9):
		if not (i & 1):
			sum += 4.0 * _grSyInterpGetQuartSum(time_scale, cof, b)
		else:
			sum += 2.0 * _grSyInterpGetQuartSum(time_scale, cof, b)
		time_scale += factor
	return ((_grSyInterpGetQuartSum(t, cof, b) + sum + _grSyInterpGetQuartSum(f, cof, b)) * factor) / 3.0

static func _grSyInterpGetFracFrame(desc: Dictionary, t: float) -> float:
	var keyframes: Array = desc.keyframes
	var id := 0
	var frac_frame := 0.0
	var min_ := 0.0
	var max_ := 1.0
	var res: float
	var diff: float
	var time_scale: float

	while (id + 1 < keyframes.size()) and (keyframes[id + 1] < t):
		id += 1
	match desc.kind:
		nSYInterpKindLinear:
			frac_frame = (t - keyframes[id]) / (keyframes[id + 1] - keyframes[id])
		nSYInterpKindBezierS3, nSYInterpKindBezier, nSYInterpKindCatrom:
			time_scale = (t - keyframes[id]) * desc.length
			while true:
				frac_frame = (min_ + max_) / 2.0
				res = _grSyInterpGetCubicIntegralApprox(min_, frac_frame, desc.quartics, id * 5)

				if time_scale < (res + 0.00001):
					max_ = frac_frame
				else:
					min_ = frac_frame
					time_scale -= res
				diff = -(min_ - max_) if (min_ < max_) else min_ - max_

				if diff < 0.00001:
					break
				if not (((res + 0.00001) < time_scale) or (time_scale < (res - 0.00001))):
					break
	return (float(id) + frac_frame) / (float(desc.points_num) - 1.0)

static func _grDisplayGetMatAObj(mobj: GRMObj, cache: Array, base_track: int, i: int) -> AObj:
	if cache[i] == null:
		var aobj := AObj.new()       # objman.c gcAddAObjForMObj
		aobj.track = i + base_track
		aobj.kind = nGCAnimKindNone
		aobj.interpolate = null
		aobj.rate_target = 0.0
		aobj.rate_base = 0.0
		aobj.value_target = 0.0
		aobj.value_base = 0.0
		aobj.length = 0.0
		aobj.length_invert = 1.0
		mobj.aobj.append(aobj)
		cache[i] = aobj
	return cache[i]

## objanim.c gcParseMObjMatAnimJoint (0x8000CF6C-ish)
static func gcParseMObjMatAnimJoint(mobj: GRMObj) -> void:
	if mobj.anim_wait == AOBJ_ANIM_NULL:
		return
	if mobj.anim_wait == AOBJ_ANIM_CHANGED:
		mobj.anim_wait = -mobj.anim_frame
	else:
		mobj.anim_wait -= mobj.anim_speed
		mobj.anim_frame += mobj.anim_speed
		if mobj.anim_wait > 0.0:
			return
	var mat_aobjs: Array = []
	mat_aobjs.resize(10)
	var matspecial_aobjs: Array = []
	matspecial_aobjs.resize(5)
	for aobj in mobj.aobj:
		if aobj.track >= nGCAnimTrackMaterialStart and aobj.track <= nGCAnimTrackMaterialEnd:
			mat_aobjs[aobj.track - nGCAnimTrackMaterialStart] = aobj
		if aobj.track >= nGCAnimTrackMaterialSubStart and aobj.track <= nGCAnimTrackMaterialSubEnd:
			matspecial_aobjs[aobj.track - nGCAnimTrackMaterialSubStart] = aobj
	while true:
		var s: AnimStream = mobj.anim_data
		if s == null or mobj.anim_pos < 0:
			for aobj in mobj.aobj:
				if aobj.kind != nGCAnimKindNone:
					aobj.length += mobj.anim_speed + mobj.anim_wait
			mobj.anim_frame = mobj.anim_wait
			mobj.anim_wait = AOBJ_ANIM_END
			break
		var p: int = mobj.anim_pos
		var word: int = s.u[p] & 0xFFFFFFFF
		var command_kind: int = (word >> 25) & 0x7F
		var flags: int = (word >> 15) & 0x3FF
		var payload: float = float(word & 0x7FFF)
		match command_kind:
			nGCAnimEvent32SetVal0RateBlock, nGCAnimEvent32SetVal0Rate:
				p += 1
				for i in 10:
					if flags == 0:
						break
					if flags & 1:
						var a := _grDisplayGetMatAObj(mobj, mat_aobjs, nGCAnimTrackMaterialStart, i)
						a.value_base = a.value_target
						a.value_target = s.f[p]
						p += 1
						a.rate_base = a.rate_target
						a.rate_target = 0.0
						a.kind = nGCAnimKindCubic
						if payload != 0.0:
							a.length_invert = 1.0 / payload
						a.length = -mobj.anim_wait - mobj.anim_speed
					flags >>= 1
				mobj.anim_pos = p
				if command_kind == nGCAnimEvent32SetVal0RateBlock:
					mobj.anim_wait += payload
			nGCAnimEvent32SetValBlock, nGCAnimEvent32SetVal:
				p += 1
				for i in 10:
					if flags == 0:
						break
					if flags & 1:
						var a := _grDisplayGetMatAObj(mobj, mat_aobjs, nGCAnimTrackMaterialStart, i)
						a.value_base = a.value_target
						a.value_target = s.f[p]
						p += 1
						a.kind = nGCAnimKindLinear
						if payload != 0.0:
							a.rate_base = (a.value_target - a.value_base) / payload
						a.length = -mobj.anim_wait - mobj.anim_speed
						a.rate_target = 0.0
					flags >>= 1
				mobj.anim_pos = p
				if command_kind == nGCAnimEvent32SetValBlock:
					mobj.anim_wait += payload
			nGCAnimEvent32SetValRateBlock, nGCAnimEvent32SetValRate:
				p += 1
				for i in 10:
					if flags == 0:
						break
					if flags & 1:
						var a := _grDisplayGetMatAObj(mobj, mat_aobjs, nGCAnimTrackMaterialStart, i)
						a.value_base = a.value_target
						a.value_target = s.f[p]
						p += 1
						a.rate_base = a.rate_target
						a.rate_target = s.f[p]
						p += 1
						a.kind = nGCAnimKindCubic
						if payload != 0.0:
							a.length_invert = 1.0 / payload
						a.length = -mobj.anim_wait - mobj.anim_speed
					flags >>= 1
				mobj.anim_pos = p
				if command_kind == nGCAnimEvent32SetValRateBlock:
					mobj.anim_wait += payload
			nGCAnimEvent32SetTargetRate:
				p += 1
				for i in 10:
					if flags == 0:
						break
					if flags & 1:
						var a := _grDisplayGetMatAObj(mobj, mat_aobjs, nGCAnimTrackMaterialStart, i)
						a.rate_target = s.f[p]
						p += 1
					flags >>= 1
				mobj.anim_pos = p
			nGCAnimEvent32Wait:
				mobj.anim_wait += payload
				mobj.anim_pos = p + 1
			nGCAnimEvent32SetValAfterBlock, nGCAnimEvent32SetValAfter:
				p += 1
				for i in 10:
					if flags == 0:
						break
					if flags & 1:
						var a := _grDisplayGetMatAObj(mobj, mat_aobjs, nGCAnimTrackMaterialStart, i)
						a.value_base = a.value_target
						a.value_target = s.f[p]
						p += 1
						a.kind = nGCAnimKindStep
						a.length_invert = payload
						a.length = -mobj.anim_wait - mobj.anim_speed
						a.rate_target = 0.0
					flags >>= 1
				mobj.anim_pos = p
				if command_kind == nGCAnimEvent32SetValAfterBlock:
					mobj.anim_wait += payload
			nGCAnimEvent32SetAnim, nGCAnimEvent32Jump:
				p += 1
				var tgt = s.ptr.get(p, null)
				if tgt == null:
					mobj.anim_data = null
					mobj.anim_pos = -1
				else:
					mobj.anim_data = tgt[0]
					mobj.anim_pos = tgt[1]
				if command_kind == nGCAnimEvent32SetAnim:
					mobj.anim_frame = -mobj.anim_wait
			ANIM_CMD_12:
				p += 1
				for i in 10:
					if flags == 0:
						break
					if flags & 1:
						var a := _grDisplayGetMatAObj(mobj, mat_aobjs, nGCAnimTrackMaterialStart, i)
						a.length += payload
					flags >>= 1
				mobj.anim_pos = p
			nGCAnimEvent32End:
				for aobj in mobj.aobj:
					if aobj.kind != nGCAnimKindNone:
						aobj.length += mobj.anim_speed + mobj.anim_wait
				mobj.anim_frame = mobj.anim_wait
				mobj.anim_wait = AOBJ_ANIM_END
				return
			nGCAnimEvent32SetExtValAfterBlock, nGCAnimEvent32SetExtValAfter:
				p += 1
				for i in 5:
					if flags == 0:
						break
					if flags & 1:
						var a := _grDisplayGetMatAObj(mobj, matspecial_aobjs, nGCAnimTrackMaterialSubStart, i)
						a.value_base = a.value_target
						a.value_target = s.f[p]
						a.interpolate = _grDisplayColorWords(a, s.u[p])   # raw RGBA words [base, target]
						p += 1
						a.kind = nGCAnimKindStep
						a.length_invert = payload
						a.length = -mobj.anim_wait - mobj.anim_speed
					flags >>= 1
				mobj.anim_pos = p
				if command_kind == nGCAnimEvent32SetExtValAfterBlock:
					mobj.anim_wait += payload
			nGCAnimEvent32SetExtValBlock, nGCAnimEvent32SetExtVal:
				p += 1
				for i in 5:
					if flags == 0:
						break
					if flags & 1:
						var a := _grDisplayGetMatAObj(mobj, matspecial_aobjs, nGCAnimTrackMaterialSubStart, i)
						a.value_base = a.value_target
						a.value_target = s.f[p]
						a.interpolate = _grDisplayColorWords(a, s.u[p])
						p += 1
						a.kind = nGCAnimKindLinear
						if payload != 0.0:
							a.length_invert = 1.0 / payload
						a.length = -mobj.anim_wait - mobj.anim_speed
					flags >>= 1
				mobj.anim_pos = p
				if command_kind == nGCAnimEvent32SetExtValBlock:
					mobj.anim_wait += payload
			ANIM_CMD_22:
				mobj.anim_wait = payload
				p += 1
				if flags & 0x01:
					mobj.sub.unk4C = s.u[p]
					p += 1
				if flags & 0x02:
					mobj.sub.unk6C = s.u[p]
					p += 1
				if flags & 0x04:
					mobj.sub.unk68 = s.u[p]
					p += 1
				if flags & 0x08:
					mobj.sub.unk74 = s.u[p]
					p += 1
				if flags & 0x10:
					mobj.sub.unk70 = s.u[p]
					p += 1
				mobj.anim_pos = p
			_:
				# C: `default: break;` re-reads the same command forever; never present in the ROM data.
				mobj.anim_pos = p + 1
		if not (mobj.anim_wait <= 0.0):
			break

## objanim.c gcPlayMObjMatAnim. Colour tracks (MaterialSub) are interpolated per channel.
static func gcPlayMObjMatAnim(mobj: GRMObj) -> void:
	if mobj.anim_wait == AOBJ_ANIM_NULL:
		return
	for aobj in mobj.aobj:
		if aobj.kind == nGCAnimKindNone:
			continue
		if mobj.anim_wait != AOBJ_ANIM_END:
			aobj.length += mobj.anim_speed
		if aobj.track < (nGCAnimTrackMaterialSubStart - 1):
			var value := 0.0
			match aobj.kind:
				nGCAnimKindLinear:
					value = aobj.value_base + (aobj.length * aobj.rate_base)
				nGCAnimKindCubic:
					var f16: float = aobj.length_invert * aobj.length_invert
					var f12: float = aobj.length * aobj.length
					var f18: float = aobj.length_invert * f12
					var f14: float = aobj.length * f12 * f16
					var f20: float = 2.0 * f14 * aobj.length_invert
					var f22: float = 3.0 * f12 * f16
					var f24: float = f14 - f18
					value = (aobj.value_base * ((f20 - f22) + 1.0)) + (aobj.value_target * (f22 - f20)) + (aobj.rate_base * ((f24 - f18) + aobj.length)) + (aobj.rate_target * f24)
				nGCAnimKindStep:
					value = aobj.value_target if (aobj.length_invert <= aobj.length) else aobj.value_base
			match aobj.track:
				nGCAnimTrackTextureIDCurrent:
					mobj.texture_id_curr = int(value) & 0xFFFF
				nGCAnimTrackTraU:
					mobj.sub.trau = value
				nGCAnimTrackTraV:
					mobj.sub.trav = value
				nGCAnimTrackScaU:
					mobj.sub.scau = value
				nGCAnimTrackScaV:
					mobj.sub.scav = value
				nGCAnimTrackTextureIDNext:
					mobj.texture_id_next = int(value) & 0xFFFF
				nGCAnimTrackScrU:
					mobj.sub.scrollu = value
				nGCAnimTrackScrV:
					mobj.sub.scrollv = value
				nGCAnimTrackSetLFrac:
					mobj.lfrac = value
				nGCAnimTrackPaletteID:
					mobj.palette_id = value
		else:
			# C reads the RGBA bytes of value_base/value_target; the raw words are kept in `interpolate`
			# ([base, target]) because an RGBA word reinterpreted as f32 may be a NaN.
			var raw: Array = aobj.interpolate if aobj.interpolate is Array else [0, 0]
			var base: int = raw[0]
			var target: int = raw[1]
			var color: int = target
			match aobj.kind:
				nGCAnimKindLinear:
					var interp := int(aobj.length * aobj.length_invert * 256.0)
					interp = clampi(interp, 0, 256)
					color = 0
					for sh in [24, 16, 8, 0]:
						var c0: int = (base >> sh) & 0xFF
						var c1: int = (target >> sh) & 0xFF
						color |= ((((256 - interp) * c0 + c1 * interp) >> 8) & 0xFF) << sh
				nGCAnimKindStep:
					color = target if (aobj.length_invert <= aobj.length) else base
			match aobj.track:
				nGCAnimTrackPrimColor:
					mobj.sub.primcolor = color
				nGCAnimTrackEnvColor:
					mobj.sub.envcolor = color
				nGCAnimTrackBlendColor:
					mobj.sub.blendcolor = color
				nGCAnimTrackLight1Color:
					mobj.sub.light1color = color
				nGCAnimTrackLight2Color:
					mobj.sub.light2color = color
	if mobj.anim_wait == AOBJ_ANIM_END:
		mobj.anim_wait = AOBJ_ANIM_NULL

## [previous target word, new target word] for a colour AObj (value_base = value_target shift).
static func _grDisplayColorWords(aobj: AObj, new_word: int) -> Array:
	var prev_target: int = aobj.interpolate[1] if aobj.interpolate is Array else 0
	return [prev_target, new_word & 0xFFFFFFFF]

## objanim.c gcGetAObjValue / gcGetInterpValueCubic (ObjAnim versions are stubs).
static func gcGetAObjValue(aobj: AObj) -> float:
	match aobj.kind:
		nGCAnimKindLinear:
			return aobj.value_base + (aobj.length * aobj.rate_base)
		nGCAnimKindCubic:
			var temp_f2: float = aobj.length * aobj.length
			var temp_f18: float = aobj.length_invert * aobj.length_invert
			var temp_f16: float = temp_f2 * aobj.length * temp_f18
			var temp_f10: float = 2.0 * temp_f16 * aobj.length_invert
			var sp14: float = 3.0 * temp_f2 * temp_f18
			var sp18: float = temp_f2 * aobj.length_invert
			var sp10: float = temp_f16 - sp18
			return (((temp_f10 - sp14) + 1.0) * aobj.value_base) + (aobj.value_target * (sp14 - temp_f10)) + (aobj.rate_base * ((sp10 - sp18) + aobj.length)) + (aobj.rate_target * sp10)
		nGCAnimKindStep:
			return aobj.value_target if (aobj.length_invert <= aobj.length) else aobj.value_base
	return 0.0
