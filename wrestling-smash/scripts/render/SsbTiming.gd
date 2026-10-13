## SSB64 motion timing, used only to retime presentation animations (SvR 2011 clips) against the
## real gameplay timeline. For a fighter motion it reports
##   length    : frames of its figatree (summed exactly like ObjAnim.ftAnimParseDObjFigatree
##               advances anim_wait: *Block / Block / SetFlags payloads, up to End or Loop)
##   loops     : the figatree ends in a Loop event (Wait, Walk, Run, ...)
##   hit_first / hit_last : motion-script times (anim frames) of the first MakeAttackColl and of the
##               last ClearAttackColl after it (SyncWait adds, AsyncWait waits for an anim frame,
##               the same rules as Ftmain's motion-event parser)
##   throw     : time of the first SetThrow (-1 if none)
##   flag0..flag3 : times of the first SetFlag0..3 events (-1 if none); in ThrowF/ThrowB, flag2 is the
##               frame the opponent is released (ftCommonThrowProcUpdate -> ftCommonThrownReleaseThrownUpdateStats)
## Read-only: works on the immutable motion data (fp.data), never on the running fighter state.
extends RefCounted

static var _cache: Dictionary = {}

static func motion_info(fp, motion_id: int) -> Dictionary:
	var key := "%d:%d" % [int(fp.fkind), motion_id]
	if _cache.has(key):
		return _cache[key]
	var out := {"length": 0.0, "loops": false, "hit_first": -1.0, "hit_last": -1.0, "throw": -1.0,
		"flag0": -1.0, "flag1": -1.0, "flag2": -1.0, "flag3": -1.0}
	var arr: Array = fp.data.mainmotion
	if motion_id >= 0 and motion_id < arr.size() and arr[motion_id] != null:
		var md: Dictionary = arr[motion_id]
		var anim = md.get("anim", null)
		if anim is Array:
			for s in anim:
				if s is AnimStream and s.is16:
					var r := _figatree_length(s)
					if r[0] > out.length:
						out.length = r[0]
					if r[1]:
						out.loops = true
		var sp = md.get("script", null)
		if sp is MotionPtr:
			_scan_script(sp, out)
	_cache[key] = out
	return out

static func _figatree_length(s: AnimStream) -> Array:
	var p := 0
	var t := 0.0
	var loops := false
	var n := s.u.size()
	var guard := 0
	while p < n and guard < 100000:
		guard += 1
		var word: int = s.u[p] & 0xFFFF
		var kind: int = (word >> 11) & 0x1F
		var flags: int = (word >> 1) & 0x3FF
		var toggle: int = word & 1
		match kind:
			SSBDefs.nGCAnimEvent16SetVal0RateBlock, SSBDefs.nGCAnimEvent16SetVal0Rate, \
			SSBDefs.nGCAnimEvent16SetValBlock, SSBDefs.nGCAnimEvent16SetVal, \
			SSBDefs.nGCAnimEvent16SetValAfterBlock, SSBDefs.nGCAnimEvent16SetValAfter, \
			SSBDefs.nGCAnimEvent16SetTargetRate, \
			SSBDefs.nGCAnimEvent16SetValRateBlock, SSBDefs.nGCAnimEvent16SetValRate:
				p += 1
				var payload := 0.0
				if toggle:
					payload = float(s.u[p] & 0xFFFF)
					p += 1
				var per := 2 if (kind == SSBDefs.nGCAnimEvent16SetValRateBlock or kind == SSBDefs.nGCAnimEvent16SetValRate) else 1
				var f := flags
				for i in ObjAnim.TRACK_COUNT:
					if f == 0:
						break
					if f & 1:
						p += per
					f >>= 1
				if kind in [SSBDefs.nGCAnimEvent16SetVal0RateBlock, SSBDefs.nGCAnimEvent16SetValBlock,
						SSBDefs.nGCAnimEvent16SetValRateBlock, SSBDefs.nGCAnimEvent16SetValAfterBlock]:
					t += payload
			SSBDefs.nGCAnimEvent16Block, SSBDefs.nGCAnimEvent16SetFlags:
				p += 1
				if toggle:
					t += float(s.u[p] & 0xFFFF)
					p += 1
			SSBDefs.nGCAnimEvent1611:
				p += 1
				if toggle:
					p += 1
			SSBDefs.nGCAnimEvent16SetTranslateInterp:
				p += 2
			SSBDefs.nGCAnimEvent16Loop:
				loops = true
				break
			_:
				break
	return [t, loops]

static func _scan_script(start: MotionPtr, out: Dictionary) -> void:
	var t := 0.0
	var p := start.dup()
	var stack: Array = []
	var guard := 0
	var loop_begin: Array = []
	while p != null and p.scr != null and p.index < p.scr.cmds.size() and guard < 2000:
		guard += 1
		var c: Dictionary = p.scr.cmds[p.index]
		var op: int = int(c.get("op", 0))
		match op:
			SSBDefs.nFTMotionEventEnd, SSBDefs.nFTMotionEventPauseScript:
				if stack.is_empty():
					return
				p = stack.pop_back()
				continue
			SSBDefs.nFTMotionEventSyncWait:
				t += float(c.get("value", 0))
			SSBDefs.nFTMotionEventAsyncWait:
				t = maxf(t, float(c.get("value", 0)))
			SSBDefs.nFTMotionEventMakeAttackColl, SSBDefs.nFTMotionEventMakeAttackCollScaled:
				if out.hit_first < 0.0:
					out.hit_first = t
				out.hit_last = maxf(out.hit_last, t)
			SSBDefs.nFTMotionEventClearAttackCollID, SSBDefs.nFTMotionEventClearAttackCollAll:
				if out.hit_first >= 0.0:
					out.hit_last = maxf(out.hit_last, t)
			SSBDefs.nFTMotionEventSetThrow:
				if out.throw < 0.0:
					out.throw = t
			SSBDefs.nFTMotionEventSetFlag0, SSBDefs.nFTMotionEventSetFlag1, SSBDefs.nFTMotionEventSetFlag2, SSBDefs.nFTMotionEventSetFlag3:
				var fk := "flag%d" % (op - SSBDefs.nFTMotionEventSetFlag0)
				if out[fk] < 0.0:
					out[fk] = t
			SSBDefs.nFTMotionEventSubroutine:
				var tgt = c.get("target", null)
				if tgt is MotionPtr and stack.size() < 8:
					stack.append(MotionPtr.make(p.scr, p.index + 1))
					p = tgt.dup()
					continue
			SSBDefs.nFTMotionEventReturn:
				if not stack.is_empty():
					p = stack.pop_back()
					continue
			SSBDefs.nFTMotionEventGoto:
				# scripts that loop back (e.g. rapid jab) are scanned once
				return
			SSBDefs.nFTMotionEventLoopBegin:
				loop_begin.append(p.index)
			SSBDefs.nFTMotionEventLoopEnd:
				pass
		p = MotionPtr.make(p.scr, p.index + 1)
