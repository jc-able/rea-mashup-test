## Hand-written port of the object-manager functions used by gameplay code (src/sys/objman.c).
## Objects are registered with Sim (process scheduler); visuals are handled by the render layer.
class_name Objman
extends Port

static func gcGetGObjThread():
	StubLog.hit("Objman.gcGetGObjThread")
	return null

static func gcSetGObjThreadPrevAlloc(gobjthread = null):
	StubLog.hit("Objman.gcSetGObjThreadPrevAlloc")
	return null

static func gcGetGObjStackOfSize(size = null):
	StubLog.hit("Objman.gcGetGObjStackOfSize")
	return null

static func gcGetDefaultGObjStack():
	StubLog.hit("Objman.gcGetDefaultGObjStack")
	return null

static func gcEjectGObjStack(gobjstack = null):
	StubLog.hit("Objman.gcEjectGObjStack")
	return null

static func gcGetGObjProcess():
	StubLog.hit("Objman.gcGetGObjProcess")
	return null

static func gcLinkGObjProcess(gobjproc = null):
	StubLog.hit("Objman.gcLinkGObjProcess")
	return null

static func gcSetGObjProcessPrevAlloc(gobjproc = null):
	StubLog.hit("Objman.gcSetGObjProcessPrevAlloc")
	return null

static func func_80007784(gobjproc = null):
	StubLog.hit("Objman.func_80007784")
	return null

static func func_800077D0(gobjproc = null):
	StubLog.hit("Objman.func_800077D0")
	return null

static func gcGetCurrentGObjProcess():
	StubLog.hit("Objman.gcGetCurrentGObjProcess")
	return null

static func gcGetGObjProcessThreadStack(gobjproc = null):
	StubLog.hit("Objman.gcGetGObjProcessThreadStack")
	return null

static func gcGetGObjProcessThreadStackSize(gobjproc = null):
	StubLog.hit("Objman.gcGetGObjProcessThreadStackSize")
	return null

static func gcSetGObjProcessFunction(proc = null):
	StubLog.hit("Objman.gcSetGObjProcessFunction")
	return null

static func gcGetGObjsActiveNum():
	StubLog.hit("Objman.gcGetGObjsActiveNum")
	return null

static func gcGetGObjSetNextAlloc():
	StubLog.hit("Objman.gcGetGObjSetNextAlloc")
	return null

static func gcSetGObjPrevAlloc(gobj = null):
	StubLog.hit("Objman.gcSetGObjPrevAlloc")
	return null

static func gcLinkGObjAfter(this_gobj = null, link_gobj = null):
	StubLog.hit("Objman.gcLinkGObjAfter")
	return null

static func gcLinkGObjSPAfter(this_gobj = null):
	StubLog.hit("Objman.gcLinkGObjSPAfter")
	return null

static func gcLinkGObjSPBefore(this_gobj = null):
	StubLog.hit("Objman.gcLinkGObjSPBefore")
	return null

static func gcRemoveGObjFromLinkedList(this_gobj = null):
	StubLog.hit("Objman.gcRemoveGObjFromLinkedList")
	return null

static func gcAppendGObjToDLLinkedList(this_gobj = null, dl_link_gobj = null):
	StubLog.hit("Objman.gcAppendGObjToDLLinkedList")
	return null

static func gcDLLinkGObjTail(this_gobj = null):
	StubLog.hit("Objman.gcDLLinkGObjTail")
	return null

static func gcDLLinkGObjHead(this_gobj = null):
	StubLog.hit("Objman.gcDLLinkGObjHead")
	return null

static func gcRemoveGObjFromDLLinkedList(this_gobj = null):
	StubLog.hit("Objman.gcRemoveGObjFromDLLinkedList")
	return null

static func gcGetXObjSetNextAlloc():
	StubLog.hit("Objman.gcGetXObjSetNextAlloc")
	return null

static func gcSetXObjPrevAlloc(xobj = null):
	StubLog.hit("Objman.gcSetXObjPrevAlloc")
	return null

static func gcGetAObjSetNextAlloc():
	StubLog.hit("Objman.gcGetAObjSetNextAlloc")
	return null

static func gcAppendAObjToDObj(dobj = null, aobj = null):
	StubLog.hit("Objman.gcAppendAObjToDObj")
	return null

static func gcAppendAObjToMObj(mobj = null, aobj = null):
	StubLog.hit("Objman.gcAppendAObjToMObj")
	return null

static func gcAppendAObjToCamera(cobj = null, aobj = null):
	StubLog.hit("Objman.gcAppendAObjToCamera")
	return null

static func gcSetAObjPrevAlloc(aobj = null):
	StubLog.hit("Objman.gcSetAObjPrevAlloc")
	return null

static func gcGetMObjSetNextAlloc():
	StubLog.hit("Objman.gcGetMObjSetNextAlloc")
	return null

static func gcSetMObjPrevAlloc(mobj = null):
	StubLog.hit("Objman.gcSetMObjPrevAlloc")
	return null

static func gcGetDObjSetNextAlloc():
	StubLog.hit("Objman.gcGetDObjSetNextAlloc")
	return null

static func gcSetDObjPrevAlloc(dobj = null):
	StubLog.hit("Objman.gcSetDObjPrevAlloc")
	return null

static func gcGetSObjSetNextAlloc():
	StubLog.hit("Objman.gcGetSObjSetNextAlloc")
	return null

static func gcSetSObjPrevAlloc(sobj = null):
	StubLog.hit("Objman.gcSetSObjPrevAlloc")
	return null

static func gcGetCObjSetNextAlloc():
	StubLog.hit("Objman.gcGetCObjSetNextAlloc")
	return null

static func gcSetCObjPrevAlloc(cobj = null):
	StubLog.hit("Objman.gcSetCObjPrevAlloc")
	return null

static func gcAddGObjProcess(gobj = null, func_ = null, kind = null, priority = null):
	if func_ is Callable:
		return Sim.add_process(gobj, func_, priority)
	return null

static func unref_80008304(gobj = null, proc = null, pri = null, thread_id = null, stack_size = null):
	StubLog.hit("Objman.unref_80008304")
	return null

## 0x800079A8: NULL or the running process -> ended when it returns; otherwise removed now.
static func gcEndGObjProcess(gobjproc = null):
	if (gobjproc == null) or (gobjproc == Sim.current_process):
		Sim.run_status = Sim.RUN_STATUS_END
		return null
	Sim.end_process(gobjproc)
	return null

static func gcAddXObjForDObjVar(dobj = null, kind = null, arg2 = null, xobj_id = null):
	StubLog.hit("Objman.gcAddXObjForDObjVar")
	return null

static func gcAddXObjForDObjFixed(dobj = null, kind = null, arg2 = null):
	return null

static func gcAddXObjForCamera(cobj = null, kind = null, arg2 = null):
	StubLog.hit("Objman.gcAddXObjForCamera")
	return null

static func gcRemoveAObjFromDObj(dobj = null):
	StubLog.hit("Objman.gcRemoveAObjFromDObj")
	return null

static func gcAddAObjForMObj(mobj = null, track = null):
	StubLog.hit("Objman.gcAddAObjForMObj")
	return null

static func gcRemoveAObjFromMObj(mobj = null):
	StubLog.hit("Objman.gcRemoveAObjFromMObj")
	return null

static func gcAddAObjForCamera(cobj = null, track = null):
	StubLog.hit("Objman.gcAddAObjForCamera")
	return null

static func gcRemoveAObjFromCamera(cobj = null):
	StubLog.hit("Objman.gcRemoveAObjFromCamera")
	return null

static func gcAddMObjForDObj(dobj = null, mobjsub = null):
	StubLog.hit("Objman.gcAddMObjForDObj")
	return null

static func gcRemoveMObjAll(dobj = null):
	return null

static func gcInitDObj(dobj = null):
	dobj.flags = DOBJ_FLAG_NONE
	dobj.is_anim_root = false
	dobj.aobj.clear()
	dobj.anim_data = null
	dobj.anim_pos = -1
	dobj.anim_wait = AOBJ_ANIM_NULL
	dobj.anim_speed = 1.0
	dobj.anim_frame = 0.0
	dobj.user_data = null
	return null

static func gcAddDObjForGObj(gobj = null, dvar = null):
	var new_dobj := DObj.new()
	if gobj.dobj != null:
		var current_dobj: DObj = gobj.dobj
		while current_dobj.sib_next != null:
			current_dobj = current_dobj.sib_next
		current_dobj.sib_next = new_dobj
		new_dobj.sib_prev = current_dobj
	else:
		gobj.dobj = new_dobj
		new_dobj.sib_prev = null
	new_dobj.parent_gobj = gobj
	new_dobj.parent = null
	new_dobj.sib_next = null
	new_dobj.child = null
	new_dobj.dl = dvar
	gcInitDObj(new_dobj)
	return new_dobj

static func gcAddSiblingForDObj(dobj = null, dvar = null):
	var new_dobj := DObj.new()
	if dobj.sib_next != null:
		dobj.sib_next.sib_prev = new_dobj
	new_dobj.sib_prev = dobj
	new_dobj.sib_next = dobj.sib_next
	dobj.sib_next = new_dobj
	new_dobj.parent_gobj = dobj.parent_gobj
	new_dobj.parent = dobj.parent
	new_dobj.child = null
	new_dobj.dl = dvar
	gcInitDObj(new_dobj)
	return new_dobj

static func gcAddChildForDObj(dobj = null, dvar = null):
	var new_dobj := DObj.new()
	if dobj.child != null:
		var current_dobj: DObj = dobj.child
		while current_dobj.sib_next != null:
			current_dobj = current_dobj.sib_next
		current_dobj.sib_next = new_dobj
		new_dobj.sib_prev = current_dobj
	else:
		dobj.child = new_dobj
		new_dobj.sib_prev = null
	new_dobj.parent_gobj = dobj.parent_gobj
	new_dobj.parent = dobj
	new_dobj.child = null
	new_dobj.sib_next = null
	new_dobj.dl = dvar
	gcInitDObj(new_dobj)
	return new_dobj

static func gcEjectDObj(dobj = null):
	while dobj.child != null:
		gcEjectDObj(dobj.child)
	if dobj.parent == null:
		if dobj.parent_gobj != null and dobj == dobj.parent_gobj.dobj:
			dobj.parent_gobj.dobj = dobj.sib_next
	elif dobj == dobj.parent.child:
		dobj.parent.child = dobj.sib_next
	if dobj.sib_prev != null:
		dobj.sib_prev.sib_next = dobj.sib_next
	if dobj.sib_next != null:
		dobj.sib_next.sib_prev = dobj.sib_prev
	dobj.aobj.clear()
	return null

static func gcAddSObjForGObj(gobj = null, sprite = null):
	StubLog.hit("Objman.gcAddSObjForGObj")
	return null

static func gcEjectSObj(sobj = null):
	StubLog.hit("Objman.gcEjectSObj")
	return null

static func gcAddCameraForGObj(gobj = null):
	StubLog.hit("Objman.gcAddCameraForGObj")
	return null

static func gcEjectCamera(cobj = null):
	StubLog.hit("Objman.gcEjectCamera")
	return null

static func gcInitGObjCommon(id = null, func_run = null, link = null, priority = null):
	StubLog.hit("Objman.gcInitGObjCommon")
	return null

static func gcMakeGObjSPAfter(id = null, func_run = null, link = null, priority = null):
	var gobj := GObj.new()
	gobj.gobj_kind = id if id != null else 0
	gobj.func_run = func_run if func_run is Callable else Callable()
	Sim.add_gobj(gobj, link if link != null else 0)
	return gobj

static func gcMakeGObjSPBefore(id = null, func_run = null, link = null, priority = null):
	StubLog.hit("Objman.gcMakeGObjSPBefore")
	return null

static func gcMakeGObjAfter(id = null, func_run = null, link_gobj = null):
	StubLog.hit("Objman.gcMakeGObjAfter")
	return null

static func gcMakeGObjBefore(id = null, func_run = null, link_gobj = null):
	StubLog.hit("Objman.gcMakeGObjBefore")
	return null

## 0x80009A84: NULL or the running GObj -> deferred until its func_run/process returns (sGCRunStatus).
static func gcEjectGObj(gobj = null):
	if (gobj == null) or (gobj == Sim.current_gobj):
		Sim.run_status = Sim.RUN_STATUS_EJECT
		return null
	Sim.eject_now(gobj)
	return null

static func gcMoveGObjCommon(sw = null, this_gobj = null, link = null, priority = null, other_gobj = null):
	StubLog.hit("Objman.gcMoveGObjCommon")
	return null

static func unref_80009D00(this_gobj = null, other_gobj = null):
	StubLog.hit("Objman.unref_80009D00")
	return null

static func unref_80009D3C(this_gobj = null, other_gobj = null):
	StubLog.hit("Objman.unref_80009D3C")
	return null

static func gcLinkGObjDLCommon(gobj = null, proc_display = null, dl_link = null, dl_order = null, camera_tag = null):
	StubLog.hit("Objman.gcLinkGObjDLCommon")
	return null

static func gcAddGObjDisplay(gobj = null, proc_display = null, dl_link = null, priority = null, cobj_mask = null):
	if gobj != null and proc_display is Callable:
		gobj.display_proc = proc_display
	return null

static func unref_80009E38(gobj = null, proc_display = null, dl_link = null, priority = null, camera_tag = null):
	StubLog.hit("Objman.unref_80009E38")
	return null

static func unref_80009E7C(this_gobj = null, proc_display = null, arg2 = null, other_gobj = null):
	StubLog.hit("Objman.unref_80009E7C")
	return null

static func unref_80009ED0(this_gobj = null, proc_display = null, arg2 = null, other_gobj = null):
	StubLog.hit("Objman.unref_80009ED0")
	return null

static func func_80009F28(gobj = null, proc_display = null, priority = null, arg3 = null, camera_tag = null):
	StubLog.hit("Objman.func_80009F28")
	return null

static func func_80009F74(gobj = null, proc_display = null, priority = null, arg3 = null, camera_tag = null):
	StubLog.hit("Objman.func_80009F74")
	return null

static func unref_80009FC0(gobj = null, proc_display = null, priority = null, arg3 = null, camera_tag = null):
	StubLog.hit("Objman.unref_80009FC0")
	return null

static func unref_8000A00C(this_gobj = null, proc_display = null, arg2 = null, arg3 = null, other_gobj = null):
	StubLog.hit("Objman.unref_8000A00C")
	return null

static func unref_8000A06C(this_gobj = null, proc_display = null, arg2 = null, arg3 = null, other_gobj = null):
	StubLog.hit("Objman.unref_8000A06C")
	return null

static func gcMoveGObjDL(gobj = null, dl_link = null, priority = null):
	StubLog.hit("Objman.gcMoveGObjDL")
	return null

static func gcMoveGObjDLHead(gobj = null, dl_link = null, priority = null):
	StubLog.hit("Objman.gcMoveGObjDLHead")
	return null

static func unref_8000A1C8(this_gobj = null, other_gobj = null):
	StubLog.hit("Objman.unref_8000A1C8")
	return null

static func unref_8000A208(this_gobj = null, other_gobj = null):
	StubLog.hit("Objman.unref_8000A208")
	return null

static func func_8000A24C(gobj = null, priority = null):
	StubLog.hit("Objman.func_8000A24C")
	return null

static func unref_8000A280(gobj = null, priority = null):
	StubLog.hit("Objman.unref_8000A280")
	return null

static func func_8000A2B4(this_gobj = null, other_gobj = null):
	StubLog.hit("Objman.func_8000A2B4")
	return null

static func unref_8000A2EC(this_gobj = null, other_gobj = null):
	StubLog.hit("Objman.unref_8000A2EC")
	return null

static func gcSetMaxNumGObj(num = null):
	StubLog.hit("Objman.gcSetMaxNumGObj")
	return null

static func gcGetMaxNumGObj():
	StubLog.hit("Objman.gcGetMaxNumGObj")
	return null

static func gcDrawAll():
	StubLog.hit("Objman.gcDrawAll")
	return null

static func gcRunGObj(gobj = null):
	StubLog.hit("Objman.gcRunGObj")
	return null

static func gcRunGObjProcess(gobjproc = null):
	StubLog.hit("Objman.gcRunGObjProcess")
	return null

static func gcRunAll():
	StubLog.hit("Objman.gcRunAll")
	return null

static func gcSetupObjman(setup = null):
	StubLog.hit("Objman.gcSetupObjman")
	return null
