## Global object/process scheduler: a port of src/sys/objman.c gcRunAll / gcRunGObj /
## gcRunGObjProcess on top of per-link GObj arrays (gGCCommonLinks):
##   1. func_run pass: every GObj with a func_run (and without GOBJ_FLAG_NORUN), link by link.
##   2. process pass: priorities 5 -> 0; inside a priority, processes run in GObj link order
##      (link id ascending, then position in the link, then the order the processes were added),
##      which is the order gcLinkGObjProcess builds sGCProcessQueue[priority] in.
## Objects/processes created during the frame behind the running one run in the same frame
## (the C follows priority_next / link_next after each call). gcEjectGObj(NULL or the running
## GObj) and gcEndGObjProcess(NULL or the running process) are deferred until the call returns
## (sGCRunStatus), exactly like the C: an ejected GObj's remaining processes are skipped.
class_name Sim
extends RefCounted

const LINKS_NUM := 32

const RUN_STATUS_DEFAULT := 0   # nGCRunStatusDefault
const RUN_STATUS_END := 1       # end the running process
const RUN_STATUS_EJECT := 2     # eject the running GObj

static var links: Array = []          # Array[Array[GObj]]
static var frame: int = 0
static var running: bool = false
static var run_status: int = RUN_STATUS_DEFAULT   # sGCRunStatus
static var current_gobj = null                    # gGCCurrentCommon
static var current_process = null                 # gGCCurrentProcess (process Dictionary)

static func reset() -> void:
	links.clear()
	for i in LINKS_NUM:
		links.append([])
	frame = 0
	run_status = RUN_STATUS_DEFAULT
	current_gobj = null
	current_process = null

static func add_gobj(gobj, link_id: int) -> void:
	if links.is_empty():
		reset()
	gobj.link_id = link_id
	gobj.is_alive = true
	links[link_id].append(gobj)

static func remove_gobj(gobj) -> void:
	gobj.is_alive = false
	if links.is_empty():
		return
	links[gobj.link_id].erase(gobj)

static func add_process(gobj, proc: Callable, priority: int) -> Dictionary:
	var p := {"priority": priority, "proc": proc, "is_paused": false, "gobj": gobj}
	gobj.processes.append(p)
	return p

## gcEndGObjProcess for a process that is not the running one.
static func end_process(p: Dictionary) -> void:
	var gobj = p.get("gobj", null)
	if gobj != null:
		gobj.processes.erase(p)

static func get_link(link_id: int) -> Array:
	if links.is_empty():
		reset()
	return links[link_id]

## Eject a GObj immediately (gcEjectGObj body for a non-running object).
static func eject_now(gobj) -> void:
	remove_gobj(gobj)
	if gobj.visual != null and is_instance_valid(gobj.visual):
		gobj.visual.queue_free()
		gobj.visual = null

static func _resume_index(lst: Array, preds: Array) -> int:
	var i := preds.size() - 1
	while i >= 0:
		var at := lst.find(preds[i])
		if at >= 0:
			return at + 1
		i -= 1
	return 0

## Run one game frame (gcRunAll).
static func run_frame() -> void:
	if links.is_empty():
		reset()
	run_status = RUN_STATUS_DEFAULT
	current_gobj = null
	current_process = null
	running = true

	# func_run pass (gcRunGObj)
	for link_id in LINKS_NUM:
		var lst: Array = links[link_id]
		var idx := 0
		while idx < lst.size():
			var gobj = lst[idx]
			var fr: Callable = gobj.func_run
			if not (gobj.gobj_flags & SSBDefs.GOBJ_FLAG_NORUN) and fr.is_valid():
				var preds: Array = lst.slice(0, idx)
				current_gobj = gobj
				fr.call(gobj)
				current_gobj = null
				var st := run_status
				run_status = RUN_STATUS_DEFAULT
				var at := lst.find(gobj)
				if gobj.is_alive and (at >= 0):
					idx = at + 1
					if st == RUN_STATUS_EJECT:
						eject_now(gobj)
						idx -= 1
				else:
					idx = _resume_index(lst, preds)
			else:
				idx += 1

	# process pass (gcRunGObjProcess), sGCProcessQueue[5] .. [0]
	for priority in range(5, -1, -1):
		for link_id in LINKS_NUM:
			var lst: Array = links[link_id]
			var idx := 0
			while idx < lst.size():
				var gobj = lst[idx]
				var preds: Array = []
				var ran := false
				var ejected := false
				var k := 0
				while k < gobj.processes.size():
					var p: Dictionary = gobj.processes[k]
					if (p.priority != priority) or p.is_paused:
						k += 1
						continue
					if not ran:
						preds = lst.slice(0, idx)
						ran = true
					current_gobj = gobj
					current_process = p
					p.proc.call(gobj)
					current_gobj = null
					current_process = null
					var st := run_status
					run_status = RUN_STATUS_DEFAULT
					if (st == RUN_STATUS_EJECT) or not gobj.is_alive:
						if gobj.is_alive:
							eject_now(gobj)
						ejected = true
						break
					if st == RUN_STATUS_END:
						gobj.processes.erase(p)
						continue
					var pk: int = gobj.processes.find(p)
					k = (pk + 1) if (pk >= 0) else (k + 1)
				if ran and (ejected or (lst.find(gobj) < 0)):
					idx = _resume_index(lst, preds)
				else:
					var at := lst.find(gobj)
					idx = (at + 1) if (at >= 0) else (idx + 1)
	frame += 1
	running = false
