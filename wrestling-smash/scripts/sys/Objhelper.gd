# Partially hand-written (process pause/resume); other functions are stubs.
# Unported stub of src/sys/objhelper.c - replace with a 1:1 port (see PORTING.md).
class_name Objhelper
extends Port

static func gcFuncGObjByLink(link = null, func_ = null, arg2 = null, param = null):
	StubLog.hit("Objhelper.gcFuncGObjByLink")
	return null

static func gcFuncGObjAll(func_ = null, arg1 = null, param = null):
	StubLog.hit("Objhelper.gcFuncGObjAll")
	return null

static func gcFuncGObjByLinkEx(link = null, func_ = null, arg2 = null, param = null, is_return_immediate = null):
	StubLog.hit("Objhelper.gcFuncGObjByLinkEx")
	return null

static func gcFuncGObjAllEx(func_ = null, arg1 = null, param = null, is_return_immediate = null):
	StubLog.hit("Objhelper.gcFuncGObjAllEx")
	return null

static func gcGetGObjByID(gobj = null, id = null):
	StubLog.hit("Objhelper.gcGetGObjByID")
	return null

static func gcFindGObjByLinkAndID(link = null, id = null):
	StubLog.hit("Objhelper.gcFindGObjByLinkAndID")
	return null

static func gcFindGObjByID(id = null):
	StubLog.hit("Objhelper.gcFindGObjByID")
	return null

static func gcDefaultFuncRun(gobj = null):
	StubLog.hit("Objhelper.gcDefaultFuncRun")
	return null

static func gcSleepCurrentGObjThread(tics = null):
	StubLog.hit("Objhelper.gcSleepCurrentGObjThread")
	return null

static func gcPauseGObjProcessAll(gobj = null):
	for p in gobj.processes:
		p.is_paused = true
	return null

static func gcResumeGObjProcessAll(gobj = null):
	for p in gobj.processes:
		p.is_paused = false
	return null

static func gcPauseGObjProcess(gobjproc = null):
	if gobjproc != null:
		gobjproc.is_paused = true
	return null

static func gcResumeGObjProcess(gobjproc = null):
	if gobjproc != null:
		gobjproc.is_paused = false
	return null

static func gcPauseGObjProcessByProc(gobj = null, func_id = null):
	StubLog.hit("Objhelper.gcPauseGObjProcessByProc")
	return null

static func gcResumeGObjProcessByProc(gobj = null, func_id = null):
	StubLog.hit("Objhelper.gcResumeGObjProcessByProc")
	return null

static func gcEndProcessAll(gobj = null):
	StubLog.hit("Objhelper.gcEndProcessAll")
	return null

static func gcAddDObjMatrixSetsRpyD(dobj = null):
	StubLog.hit("Objhelper.gcAddDObjMatrixSetsRpyD")
	return null

static func gcAddDObjMatrixSetsRpyR(dobj = null):
	StubLog.hit("Objhelper.gcAddDObjMatrixSetsRpyR")
	return null

static func gcAddCameraMatrixSets(cobj = null):
	StubLog.hit("Objhelper.gcAddCameraMatrixSets")
	return null

static func gcRemoveTreeMObjAll(gobj = null):
	StubLog.hit("Objhelper.gcRemoveTreeMObjAll")
	return null

static func gcAddDObjRpyD(gobj = null, dvar = null):
	StubLog.hit("Objhelper.gcAddDObjRpyD")
	return null

static func gcAddDObjSiblingRpyD(dobj = null, dvar = null):
	StubLog.hit("Objhelper.gcAddDObjSiblingRpyD")
	return null

static func gcAddDObjChildRpyD(dobj = null, dvar = null):
	StubLog.hit("Objhelper.gcAddDObjChildRpyD")
	return null

static func gcAddDObjRpyR(gobj = null, dvar = null):
	StubLog.hit("Objhelper.gcAddDObjRpyR")
	return null

static func gcAddDObjSiblingRpyR(dobj = null, dvar = null):
	StubLog.hit("Objhelper.gcAddDObjSiblingRpyR")
	return null

static func gcAddDObjChildRpyR(dobj = null, dvar = null):
	StubLog.hit("Objhelper.gcAddDObjChildRpyR")
	return null

static func unref_8000B618(gobj = null, dobjtra = null, dobjs = null):
	StubLog.hit("Objhelper.unref_8000B618")
	return null

static func gcRemoveDObjAll(gobj = null):
	StubLog.hit("Objhelper.gcRemoveDObjAll")
	return null

static func gcRemoveSObjAll(gobj = null):
	StubLog.hit("Objhelper.gcRemoveSObjAll")
	return null

static func gcEjectAll():
	StubLog.hit("Objhelper.gcEjectAll")
	return null

static func gcMakeModelGObj(id = null, func_run = null, link = null, link_priority = null, proc_display = null, dl_link = null, dl_link_priority = null, camera_tag = null, dvar = null, is_add_default_xobj = null, gobjproc_kind = null, proc = null, gobjproc_priority = null):
	StubLog.hit("Objhelper.gcMakeModelGObj")
	return null

static func gcMakeSpriteGObj(id = null, func_run = null, link = null, link_priority = null, proc_display = null, dl_link = null, dl_link_priority = null, camera_tag = null, sprite = null, gobjproc_kind = null, proc = null, gobjproc_priority = null):
	StubLog.hit("Objhelper.gcMakeSpriteGObj")
	return null

static func gcMakeCameraGObj(id = null, func_run = null, link = null, link_priority = null, proc_display = null, dl_link_priority = null, camera_mask = null, camera_tag = null, is_add_default_xobj = null, gobjproc_kind = null, proc = null, gobjproc_priority = null, argD = null):
	StubLog.hit("Objhelper.gcMakeCameraGObj")
	return null

static func gcMakeDefaultCameraGObj(link = null, link_priority = null, dl_link_priority = null, flags = null, color = null):
	StubLog.hit("Objhelper.gcMakeDefaultCameraGObj")
	return null
