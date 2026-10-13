## Port of the joint animation runtime:
##   src/sys/objanim.c   gcAddDObjAnimJoint, gcAddAObjForDObj, gcParseDObjAnimJoint,
##                       gcPlayDObjAnimJoint, gcSetAnimSpeed, gcGetTreeDObjNext
##   src/ft/ftanim.c     ftAnimGetTargetValue, ftAnimParseDObjFigatree
##   src/lb/lbcommon.c   lbCommonGetTreeDObjNextFromRoot, lbCommonAddFighterPartsFigatree
## Event streams are the ROM's raw AObjEvent16 / AObjEvent32 words (see AnimStream).
class_name ObjAnim
extends Port

# AOBJ_ANIM_NULL / AOBJ_ANIM_CHANGED / AOBJ_ANIM_END come from SSBDefs (objtypes.h).

const TRACK_COUNT := 10  # nGCAnimTrackJointEnd - nGCAnimTrackJointStart + 1

# ---------------------------------------------------------------------------
# objman.c / objanim.c helpers
# ---------------------------------------------------------------------------
static func gcAddAObjForDObj(dobj: DObj, track: int) -> AObj:
	var aobj := AObj.new()
	aobj.track = track
	aobj.kind = nGCAnimKindNone
	aobj.interpolate = null
	aobj.rate_target = 0.0
	aobj.rate_base = 0.0
	aobj.value_target = 0.0
	aobj.value_base = 0.0
	aobj.length = 0.0
	aobj.length_invert = 1.0
	dobj.aobj.append(aobj)
	return aobj

static func gcRemoveAObjAll(dobj: DObj) -> void:
	dobj.aobj.clear()

static func gcAddDObjAnimJoint(dobj: DObj, stream: AnimStream, anim_frame: float) -> void:
	for aobj in dobj.aobj:
		aobj.kind = nGCAnimKindNone
	dobj.anim_data = stream
	dobj.anim_pos = 0 if stream != null else -1
	dobj.anim_is16 = stream.is16 if stream != null else true
	dobj.anim_wait = AOBJ_ANIM_CHANGED
	dobj.anim_frame = anim_frame

static func gcGetTreeDObjNext(dobj: DObj) -> DObj:
	if dobj.child != null:
		return dobj.child
	if dobj.sib_next != null:
		return dobj.sib_next
	while true:
		if dobj.parent == null:
			return null
		if dobj.parent.sib_next != null:
			return dobj.parent.sib_next
		dobj = dobj.parent
	return null

static func gcSetAnimSpeed(gobj, anim_speed: float) -> void:
	var dobj: DObj = gobj.dobj
	while dobj != null:
		dobj.anim_speed = anim_speed
		dobj = gcGetTreeDObjNext(dobj)

static func gcSetAllAnimSpeed(gobj, anim_speed: float) -> void:
	gcSetAnimSpeed(gobj, anim_speed)

static func lbCommonGetTreeDObjNextFromRoot(a: DObj, b: DObj) -> DObj:
	if a.child != null:
		return a.child
	elif a == b:
		return null
	elif a.sib_next != null:
		return a.sib_next
	while true:
		if a.parent == b:
			return null
		elif a.parent.sib_next != null:
			return a.parent.sib_next
		a = a.parent
	return null

## lbCommonAddFighterPartsFigatree: attach the figatree joint table to the tree in pre-order.
static func lbCommonAddFighterPartsFigatree(root_dobj: DObj, figatree: Array, anim_frame: float) -> void:
	var current_dobj := root_dobj
	root_dobj.parent_gobj.anim_frame = anim_frame
	var idx := 0
	while current_dobj != null:
		var anim: AnimStream = figatree[idx] if idx < figatree.size() else null
		var parts = current_dobj.user_data
		if anim != null:
			gcAddDObjAnimJoint(current_dobj, anim, anim_frame)
			if parts != null:
				parts.is_have_anim = true
		else:
			current_dobj.anim_wait = AOBJ_ANIM_NULL
			if parts != null:
				parts.is_have_anim = false
		idx += 1
		current_dobj = lbCommonGetTreeDObjNextFromRoot(current_dobj, root_dobj)

## lbCommonAddTreeDObjsAnimAll (joint animation part only).
static func lbCommonAddTreeDObjsAnimAll(root_dobj: DObj, anim_joints: Array, anim_frame: float) -> void:
	var current_dobj := root_dobj
	root_dobj.parent_gobj.anim_frame = anim_frame
	var idx := 0
	while current_dobj != null:
		if anim_joints != null:
			var aj: AnimStream = anim_joints[idx] if idx < anim_joints.size() else null
			if aj != null:
				gcAddDObjAnimJoint(current_dobj, aj, anim_frame)
			else:
				current_dobj.anim_wait = AOBJ_ANIM_NULL
			idx += 1
		current_dobj = lbCommonGetTreeDObjNextFromRoot(current_dobj, root_dobj)

# ---------------------------------------------------------------------------
# ftanim.c
# ---------------------------------------------------------------------------
const _FRACS := [1.0 / 512.0, 1.0 / 4.0, 1.0 / 4096.0, 1.0 / 16384.0 - (3.0 / 1000000000000.0),
		1.0 / 512.0, 1.0 / 32.0, 1.0 / 8192.0, 1.0 / 16384.0 - (3.0 / 1000000000000.0)]

static func ftAnimGetTargetValue(arg: int, track: int, value_or_step: int) -> float:
	var id := 0
	match track:
		nGCAnimTrackRotX, nGCAnimTrackRotY, nGCAnimTrackRotZ:
			id = 0
		nGCAnimTrackTraX, nGCAnimTrackTraY, nGCAnimTrackTraZ:
			id = 1
		nGCAnimTrackScaX, nGCAnimTrackScaY, nGCAnimTrackScaZ:
			id = 2
		nGCAnimTrackTraI:
			id = 3
	if value_or_step != 0:
		id += 4
	return float(arg) * _FRACS[id]

static func _find_tracks(dobj: DObj) -> Array:
	var t := []
	t.resize(TRACK_COUNT)
	for aobj in dobj.aobj:
		if aobj.track >= nGCAnimTrackJointStart and aobj.track <= nGCAnimTrackJointEnd:
			t[aobj.track - nGCAnimTrackJointStart] = aobj
	return t

static func _end_anim(dobj: DObj) -> void:
	for aobj in dobj.aobj:
		if aobj.kind != nGCAnimKindNone:
			aobj.length += dobj.anim_speed + dobj.anim_wait
	dobj.anim_frame = dobj.anim_wait
	dobj.parent_gobj.anim_frame = dobj.anim_wait
	dobj.anim_wait = AOBJ_ANIM_END

## ftAnimParseDObjFigatree (0x800EC238)
static func ftAnimParseDObjFigatree(root_dobj: DObj) -> void:
	if root_dobj.anim_wait == AOBJ_ANIM_NULL:
		return
	if root_dobj.anim_wait == AOBJ_ANIM_CHANGED:
		root_dobj.anim_wait = -root_dobj.anim_frame
	else:
		root_dobj.anim_wait -= root_dobj.anim_speed
		root_dobj.anim_frame += root_dobj.anim_speed
		root_dobj.parent_gobj.anim_frame = root_dobj.anim_frame
		if root_dobj.anim_wait > 0.0:
			return
	var track_aobjs := _find_tracks(root_dobj)
	var s: AnimStream = root_dobj.anim_data
	while true:
		if root_dobj.anim_pos < 0 or s == null:
			_end_anim(root_dobj)
			return
		var p: int = root_dobj.anim_pos
		var word: int = s.u[p] & 0xFFFF
		var command_kind: int = (word >> 11) & 0x1F
		var flags: int = (word >> 1) & 0x3FF
		var toggle: int = word & 1
		var payload: float
		match command_kind:
			nGCAnimEvent16SetVal0RateBlock, nGCAnimEvent16SetVal0Rate:
				p += 1
				payload = 0.0
				if toggle:
					payload = float(s.u[p] & 0xFFFF)
					p += 1
				for i in TRACK_COUNT:
					if flags == 0:
						break
					if flags & 1:
						if track_aobjs[i] == null:
							track_aobjs[i] = gcAddAObjForDObj(root_dobj, i + nGCAnimTrackJointStart)
						var a: AObj = track_aobjs[i]
						a.value_base = a.value_target
						a.value_target = ftAnimGetTargetValue(s.s16(p), i + nGCAnimTrackJointStart, 0)
						p += 1
						a.rate_base = a.rate_target
						a.rate_target = 0.0
						a.kind = nGCAnimKindCubic
						if payload != 0.0:
							a.length_invert = 1.0 / payload
						a.length = -root_dobj.anim_wait - root_dobj.anim_speed
					flags >>= 1
				root_dobj.anim_pos = p
				if command_kind == nGCAnimEvent16SetVal0RateBlock:
					root_dobj.anim_wait += payload
			nGCAnimEvent16SetValBlock, nGCAnimEvent16SetVal:
				p += 1
				payload = 0.0
				if toggle:
					payload = float(s.u[p] & 0xFFFF)
					p += 1
				for i in TRACK_COUNT:
					if flags == 0:
						break
					if flags & 1:
						if track_aobjs[i] == null:
							track_aobjs[i] = gcAddAObjForDObj(root_dobj, i + nGCAnimTrackJointStart)
						var a: AObj = track_aobjs[i]
						a.value_base = a.value_target
						a.value_target = ftAnimGetTargetValue(s.s16(p), i + nGCAnimTrackJointStart, 0)
						p += 1
						a.kind = nGCAnimKindLinear
						if payload != 0.0:
							a.rate_base = (a.value_target - a.value_base) / payload
						a.length = -root_dobj.anim_wait - root_dobj.anim_speed
						a.rate_target = 0.0
					flags >>= 1
				root_dobj.anim_pos = p
				if command_kind == nGCAnimEvent16SetValBlock:
					root_dobj.anim_wait += payload
			nGCAnimEvent16SetValRateBlock, nGCAnimEvent16SetValRate:
				p += 1
				payload = 0.0
				if toggle:
					payload = float(s.u[p] & 0xFFFF)
					p += 1
				for i in TRACK_COUNT:
					if flags == 0:
						break
					if flags & 1:
						if track_aobjs[i] == null:
							track_aobjs[i] = gcAddAObjForDObj(root_dobj, i + nGCAnimTrackJointStart)
						var a: AObj = track_aobjs[i]
						a.value_base = a.value_target
						a.value_target = ftAnimGetTargetValue(s.s16(p), i + nGCAnimTrackJointStart, 0)
						p += 1
						a.rate_base = a.rate_target
						a.rate_target = ftAnimGetTargetValue(s.s16(p), i + nGCAnimTrackJointStart, 1)
						p += 1
						a.kind = nGCAnimKindCubic
						if payload != 0.0:
							a.length_invert = 1.0 / payload
						a.length = -root_dobj.anim_wait - root_dobj.anim_speed
					flags >>= 1
				root_dobj.anim_pos = p
				if command_kind == nGCAnimEvent16SetValRateBlock:
					root_dobj.anim_wait += payload
			nGCAnimEvent16SetTargetRate:
				p += 1
				if toggle:
					p += 1   # payload read but unused
				for i in TRACK_COUNT:
					if flags == 0:
						break
					if flags & 1:
						if track_aobjs[i] == null:
							track_aobjs[i] = gcAddAObjForDObj(root_dobj, i + nGCAnimTrackJointStart)
						track_aobjs[i].rate_target = ftAnimGetTargetValue(s.s16(p), i + nGCAnimTrackJointStart, 1)
						p += 1
					flags >>= 1
				root_dobj.anim_pos = p
			nGCAnimEvent16Block:
				p += 1
				if toggle:
					root_dobj.anim_wait += float(s.u[p] & 0xFFFF)
					p += 1
				root_dobj.anim_pos = p
			nGCAnimEvent16SetValAfterBlock, nGCAnimEvent16SetValAfter:
				p += 1
				payload = 0.0
				if toggle:
					payload = float(s.u[p] & 0xFFFF)
					p += 1
				for i in TRACK_COUNT:
					if flags == 0:
						break
					if flags & 1:
						if track_aobjs[i] == null:
							track_aobjs[i] = gcAddAObjForDObj(root_dobj, i + nGCAnimTrackJointStart)
						var a: AObj = track_aobjs[i]
						a.value_base = a.value_target
						a.value_target = ftAnimGetTargetValue(s.s16(p), i + nGCAnimTrackJointStart, 0)
						p += 1
						a.kind = nGCAnimKindStep
						a.length_invert = payload
						a.length = -root_dobj.anim_wait - root_dobj.anim_speed
						a.rate_target = 0.0
					flags >>= 1
				root_dobj.anim_pos = p
				if command_kind == nGCAnimEvent16SetValAfterBlock:
					root_dobj.anim_wait += payload
			nGCAnimEvent16Loop:
				# AObjAnimAdvance(e); e += e->s / 2;  (offset is in bytes from the halfword after the command)
				p += 1
				p += s.s16(p) / 2
				root_dobj.anim_pos = p
				root_dobj.anim_frame = -root_dobj.anim_wait
				root_dobj.parent_gobj.anim_frame = -root_dobj.anim_wait
			nGCAnimEvent1611:
				p += 1
				payload = 0.0
				if toggle:
					payload = float(s.u[p] & 0xFFFF)
					p += 1
				for i in TRACK_COUNT:
					if flags == 0:
						break
					if flags & 1:
						if track_aobjs[i] == null:
							track_aobjs[i] = gcAddAObjForDObj(root_dobj, i + nGCAnimTrackJointStart)
						track_aobjs[i].length += payload
					flags >>= 1
				root_dobj.anim_pos = p
			nGCAnimEvent16SetTranslateInterp:
				p += 1
				var ti := nGCAnimTrackTraI - nGCAnimTrackJointStart
				if track_aobjs[ti] == null:
					track_aobjs[ti] = gcAddAObjForDObj(root_dobj, nGCAnimTrackTraI)
				# operand = relative offset of the SYInterpDesc; SSBData attaches the decoded descriptor
				# to the stream at the operand index (AnimStream.ptr[p])
				track_aobjs[ti].interpolate = s.ptr.get(p, null)
				p += 1
				root_dobj.anim_pos = p
			nGCAnimEvent16End:
				_end_anim(root_dobj)
				return
			nGCAnimEvent16SetFlags:
				root_dobj.flags = flags
				p += 1
				if toggle:
					root_dobj.anim_wait += float(s.u[p] & 0xFFFF)
					p += 1
				root_dobj.anim_pos = p
			_:
				# unknown opcode: C loops forever re-reading it; stop safely instead
				_end_anim(root_dobj)
				return
		if not (root_dobj.anim_wait <= 0.0):
			break

# ---------------------------------------------------------------------------
# objanim.c gcParseDObjAnimJoint (32-bit AnimJoint scripts)
# ---------------------------------------------------------------------------
static func gcParseDObjAnimJoint(dobj: DObj) -> void:
	if dobj.anim_wait == AOBJ_ANIM_NULL:
		return
	if dobj.anim_wait == AOBJ_ANIM_CHANGED:
		dobj.anim_wait = -dobj.anim_frame
	else:
		dobj.anim_wait -= dobj.anim_speed
		dobj.anim_frame += dobj.anim_speed
		dobj.parent_gobj.anim_frame = dobj.anim_frame
		if dobj.anim_wait > 0.0:
			return
	var track_aobjs := _find_tracks(dobj)
	while true:
		var s: AnimStream = dobj.anim_data
		if dobj.anim_pos < 0 or s == null:
			_end_anim(dobj)
			return
		var p: int = dobj.anim_pos
		var word: int = s.u[p] & 0xFFFFFFFF
		var command_kind: int = (word >> 25) & 0x7F
		var flags: int = (word >> 15) & 0x3FF
		var payload: float = float(word & 0x7FFF)
		match command_kind:
			nGCAnimEvent32SetVal0RateBlock, nGCAnimEvent32SetVal0Rate:
				p += 1
				for i in TRACK_COUNT:
					if flags == 0:
						break
					if flags & 1:
						if track_aobjs[i] == null:
							track_aobjs[i] = gcAddAObjForDObj(dobj, i + nGCAnimTrackJointStart)
						var a: AObj = track_aobjs[i]
						a.value_base = a.value_target
						a.value_target = s.f[p]
						p += 1
						a.rate_base = a.rate_target
						a.rate_target = 0.0
						a.kind = nGCAnimKindCubic
						if payload != 0.0:
							a.length_invert = 1.0 / payload
						a.length = -dobj.anim_wait - dobj.anim_speed
					flags >>= 1
				dobj.anim_pos = p
				if command_kind == nGCAnimEvent32SetVal0RateBlock:
					dobj.anim_wait += payload
			nGCAnimEvent32SetValBlock, nGCAnimEvent32SetVal:
				p += 1
				for i in TRACK_COUNT:
					if flags == 0:
						break
					if flags & 1:
						if track_aobjs[i] == null:
							track_aobjs[i] = gcAddAObjForDObj(dobj, i + nGCAnimTrackJointStart)
						var a: AObj = track_aobjs[i]
						a.value_base = a.value_target
						a.value_target = s.f[p]
						p += 1
						a.kind = nGCAnimKindLinear
						if payload != 0.0:
							a.rate_base = (a.value_target - a.value_base) / payload
						a.length = -dobj.anim_wait - dobj.anim_speed
						a.rate_target = 0.0
					flags >>= 1
				dobj.anim_pos = p
				if command_kind == nGCAnimEvent32SetValBlock:
					dobj.anim_wait += payload
			nGCAnimEvent32SetValRateBlock, nGCAnimEvent32SetValRate:
				p += 1
				for i in TRACK_COUNT:
					if flags == 0:
						break
					if flags & 1:
						if track_aobjs[i] == null:
							track_aobjs[i] = gcAddAObjForDObj(dobj, i + nGCAnimTrackJointStart)
						var a: AObj = track_aobjs[i]
						a.value_base = a.value_target
						a.value_target = s.f[p]
						p += 1
						a.rate_base = a.rate_target
						a.rate_target = s.f[p]
						p += 1
						a.kind = nGCAnimKindCubic
						if payload != 0.0:
							a.length_invert = 1.0 / payload
						a.length = -dobj.anim_wait - dobj.anim_speed
					flags >>= 1
				dobj.anim_pos = p
				if command_kind == nGCAnimEvent32SetValRateBlock:
					dobj.anim_wait += payload
			nGCAnimEvent32SetTargetRate:
				p += 1
				for i in TRACK_COUNT:
					if flags == 0:
						break
					if flags & 1:
						if track_aobjs[i] == null:
							track_aobjs[i] = gcAddAObjForDObj(dobj, i + nGCAnimTrackJointStart)
						track_aobjs[i].rate_target = s.f[p]
						p += 1
					flags >>= 1
				dobj.anim_pos = p
			nGCAnimEvent32Wait:
				dobj.anim_wait += payload
				dobj.anim_pos = p + 1
			nGCAnimEvent32SetValAfterBlock, nGCAnimEvent32SetValAfter:
				p += 1
				for i in TRACK_COUNT:
					if flags == 0:
						break
					if flags & 1:
						if track_aobjs[i] == null:
							track_aobjs[i] = gcAddAObjForDObj(dobj, i + nGCAnimTrackJointStart)
						var a: AObj = track_aobjs[i]
						a.value_base = a.value_target
						a.value_target = s.f[p]
						p += 1
						a.kind = nGCAnimKindStep
						a.length_invert = payload
						a.length = -dobj.anim_wait - dobj.anim_speed
						a.rate_target = 0.0
					flags >>= 1
				dobj.anim_pos = p
				if command_kind == nGCAnimEvent32SetValAfterBlock:
					dobj.anim_wait += payload
			nGCAnimEvent32SetAnim, nGCAnimEvent32Jump:
				p += 1
				var tgt = s.ptr.get(p, null)
				if tgt == null:
					dobj.anim_pos = -1
				else:
					dobj.anim_data = tgt[0]
					dobj.anim_pos = tgt[1]
				if command_kind == nGCAnimEvent32SetAnim:
					dobj.anim_frame = -dobj.anim_wait
					dobj.parent_gobj.anim_frame = -dobj.anim_wait
			ANIM_CMD_12:
				p += 1
				for i in TRACK_COUNT:
					if flags == 0:
						break
					if flags & 1:
						if track_aobjs[i] == null:
							track_aobjs[i] = gcAddAObjForDObj(dobj, i + nGCAnimTrackJointStart)
						track_aobjs[i].length += payload
					flags >>= 1
				dobj.anim_pos = p
			nGCAnimEvent32SetInterp:
				p += 1
				var ti := nGCAnimTrackTraI - nGCAnimTrackJointStart
				if track_aobjs[ti] == null:
					track_aobjs[ti] = gcAddAObjForDObj(dobj, nGCAnimTrackTraI)
				track_aobjs[ti].interpolate = s.ptr.get(p, null)
				p += 1
				dobj.anim_pos = p
			nGCAnimEvent32End:
				_end_anim(dobj)
				return
			nGCAnimEvent32SetFlags:
				dobj.flags = flags
				dobj.anim_wait += payload
				dobj.anim_pos = p + 1
			ANIM_CMD_16:
				dobj.anim_wait += payload
				dobj.anim_pos = p + 1
			ANIM_CMD_17:
				dobj.anim_wait += payload
				p += 1
				for i in range(4, 14):
					if flags == 0:
						break
					if flags & 1:
						p += 1
					flags >>= 1
				dobj.anim_pos = p
			_:
				dobj.anim_pos = p + 1
		if not (dobj.anim_wait <= 0.0):
			break

# ---------------------------------------------------------------------------
# gcPlayDObjAnimJoint
# ---------------------------------------------------------------------------
static func gcPlayDObjAnimJoint(dobj: DObj) -> void:
	if dobj.anim_wait == AOBJ_ANIM_NULL:
		return
	var noanim: bool = false
	if dobj.parent_gobj != null and "gobj_flags" in dobj.parent_gobj:
		noanim = (dobj.parent_gobj.gobj_flags & GOBJ_FLAG_NOANIM) != 0
	for aobj in dobj.aobj:
		if aobj.kind == nGCAnimKindNone:
			continue
		if dobj.anim_wait != AOBJ_ANIM_END:
			aobj.length += dobj.anim_speed
		if noanim:
			continue
		var value: float = 0.0
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
			nGCAnimTrackRotX:
				dobj.rotate.x = value
			nGCAnimTrackRotY:
				dobj.rotate.y = value
			nGCAnimTrackRotZ:
				dobj.rotate.z = value
			nGCAnimTrackTraI:
				if value < 0.0:
					value = 0.0
				elif value > 1.0:
					value = 1.0
				# syInterpCubic(&dobj->translate, aobj->interpolate, value) (e.g. Samus RollF/RollB root motion)
				if aobj.interpolate is Dictionary:
					dobj.translate = Interp.syInterpCubic(dobj.translate, aobj.interpolate, value)
			nGCAnimTrackTraX:
				dobj.translate.x = value
			nGCAnimTrackTraY:
				dobj.translate.y = value
			nGCAnimTrackTraZ:
				dobj.translate.z = value
			nGCAnimTrackScaX:
				dobj.scale.x = value
			nGCAnimTrackScaY:
				dobj.scale.y = value
			nGCAnimTrackScaZ:
				dobj.scale.z = value
	if dobj.anim_wait == AOBJ_ANIM_END:
		dobj.anim_wait = AOBJ_ANIM_NULL

## gcPlayAnimAll / gcAnimAll for non-fighter objects: parse + play every joint of a tree.
static func gcPlayAnimAll(gobj) -> void:
	var dobj: DObj = gobj.dobj
	while dobj != null:
		if dobj.anim_is16:
			ftAnimParseDObjFigatree(dobj)
		else:
			gcParseDObjAnimJoint(dobj)
		gcPlayDObjAnimJoint(dobj)
		dobj = gcGetTreeDObjNext(dobj)

# --- remaining objanim.c functions (not needed by the ported gameplay code yet) ---
static func gcSetMatAnimJointSpeed(gobj = null, anim_speed = null):
	StubLog.hit("ObjAnim.gcSetMatAnimJointSpeed")
	return null

static func gcRemoveAnimJointAll(gobj = null):
	StubLog.hit("ObjAnim.gcRemoveAnimJointAll")
	return null

static func gcRemoveAnimAll(gobj = null):
	StubLog.hit("ObjAnim.gcRemoveAnimAll")
	return null

static func gcRemoveMatAnimJointAll(gobj = null):
	StubLog.hit("ObjAnim.gcRemoveMatAnimJointAll")
	return null

static func gcAddMObjMatAnimJoint(mobj = null, matanim_joint = null, anim_frame = null):
	StubLog.hit("ObjAnim.gcAddMObjMatAnimJoint")
	return null

static func gcAddAnimJointAll(gobj = null, anim_joints = null, anim_frame = null):
	StubLog.hit("ObjAnim.gcAddAnimJointAll")
	return null

static func gcAddMatAnimJointAll(gobj = null, p_matanim_joints = null, anim_frame = null):
	StubLog.hit("ObjAnim.gcAddMatAnimJointAll")
	return null

static func gcAddAnimAll(gobj = null, anim_joints = null, p_matanim_joints = null, anim_frame = null):
	StubLog.hit("ObjAnim.gcAddAnimAll")
	return null

static func gcGetInterpValueCubic(length_invert = null, length = null, value_base = null, value_target = null, rate_base = null, rate_target = null):
	var f2: float = length * length
	var f18: float = length_invert * length_invert
	var f16: float = f2 * length * f18
	var f10: float = 2.0 * f16 * length_invert
	var sp14: float = 3.0 * f2 * f18
	var sp18: float = f2 * length_invert
	var sp10: float = f16 - sp18
	return (((f10 - sp14) + 1.0) * value_base) + (value_target * (sp14 - f10)) + (rate_base * ((sp10 - sp18) + length)) + (rate_target * sp10)

static func gcGetInterpRateCubic(length_invert = null, length = null, value_base = null, value_target = null, rate_base = null, rate_target = null):
	StubLog.hit("ObjAnim.gcGetInterpRateCubic")
	return null

static func gcGetAObjValue(aobj = null):
	match aobj.kind:
		nGCAnimKindLinear:
			return aobj.value_base + (aobj.length * aobj.rate_base)
		nGCAnimKindCubic:
			return gcGetInterpValueCubic(aobj.length_invert, aobj.length, aobj.value_base, aobj.value_target, aobj.rate_base, aobj.rate_target)
		nGCAnimKindStep:
			return aobj.value_target if (aobj.length_invert <= aobj.length) else aobj.value_base
	return 0.0

static func gcGetAObjRate(aobj = null):
	StubLog.hit("ObjAnim.gcGetAObjRate")
	return null

static func gcParseMObjMatAnimJoint(mobj = null):
	StubLog.hit("ObjAnim.gcParseMObjMatAnimJoint")
	return null

static func gcPlayMObjMatAnim(mobj = null):
	StubLog.hit("ObjAnim.gcPlayMObjMatAnim")
	return null

static func gcGetTrackAObj(aobj = null, track = null):
	StubLog.hit("ObjAnim.gcGetTrackAObj")
	return null

static func gcSetDObjAnimLength(dobj = null, length = null):
	StubLog.hit("ObjAnim.gcSetDObjAnimLength")
	return null

static func gcGetDObjAxisTrack(dobj = null, track = null):
	StubLog.hit("ObjAnim.gcGetDObjAxisTrack")
	return null

static func gcGetDObjDescAxisTrack(dobjdesc = null, track = null):
	StubLog.hit("ObjAnim.gcGetDObjDescAxisTrack")
	return null

static func gcCheckGetDObjNoAxisTrack(is_desc_or_dobj = null, dobj = null, axis_value = null, rate = null, seek_aobj = null, dobjdesc = null, track = null, rate_kind = null, translate = null, is_axis_ready = null):
	StubLog.hit("ObjAnim.gcCheckGetDObjNoAxisTrack")
	return null

static func gcGetAObjTrackAnimTimeMax(track = null, translate = null, rotate = null, scale = null, anim_time_max = null, aobj = null):
	StubLog.hit("ObjAnim.gcGetAObjTrackAnimTimeMax")
	return null

static func gcGetDObjTempAnimTimeMax(dobj = null, anim_joints = null, anim_frame = null, dobjdesc = null, rate_kind = null, length = null, translate = null, rotate = null, scale = null):
	StubLog.hit("ObjAnim.gcGetDObjTempAnimTimeMax")
	return null

static func func_8000EC64_F864(gobj = null, anim_joints = null, anim_frame = null, dobjdesc = null, rate_kind = null, length_max = null, length_min = null, translate = null, rotate = null, scale = null):
	StubLog.hit("ObjAnim.func_8000EC64_F864")
	return null

static func func_8000EE40_FA40(gobj = null, anim_joints = null, anim_frame = null, dobjdesc = null):
	StubLog.hit("ObjAnim.func_8000EE40_FA40")
	return null

static func gcAddDObjTransformTraRotSca(dobj = null):
	StubLog.hit("ObjAnim.gcAddDObjTransformTraRotSca")
	return null

static func gcAddDObjForGObjTraRotSca(gobj = null, dvar = null):
	StubLog.hit("ObjAnim.gcAddDObjForGObjTraRotSca")
	return null

static func gcAddSiblingForDObjTraRotSca(dobj = null, dvar = null):
	StubLog.hit("ObjAnim.gcAddSiblingForDObjTraRotSca")
	return null

static func gcAddChildForDObjTraRotSca(dobj = null, dvar = null):
	StubLog.hit("ObjAnim.gcAddChildForDObjTraRotSca")
	return null

static func gcSetupCommonDObjs(gobj = null, dobjdesc = null, dobjs = null):
	StubLog.hit("ObjAnim.gcSetupCommonDObjs")
	return null

static func gcAddDObj3TransformsKind(dobj = null, tk1 = null, tk2 = null, tk3 = null):
	StubLog.hit("ObjAnim.gcAddDObj3TransformsKind")
	return null

static func gcDecideDObj3TransformsKind(dobj = null, tk1 = null, tk2 = null, tk3 = null, flags = null):
	StubLog.hit("ObjAnim.gcDecideDObj3TransformsKind")
	return null

static func gcSetupCustomDObjs(gobj = null, dobjdesc = null, dobjs = null, tk1 = null, tk2 = null, tk3 = null):
	StubLog.hit("ObjAnim.gcSetupCustomDObjs")
	return null

static func gcSetupCustomDObjsWithMObj(gobj = null, dobjdesc = null, p_mobjsubs = null, dobjs = null, tk1 = null, tk2 = null, tk3 = null):
	StubLog.hit("ObjAnim.gcSetupCustomDObjsWithMObj")
	return null

static func gcAddMObjAll(gobj = null, p_mobjsubs = null):
	StubLog.hit("ObjAnim.gcAddMObjAll")
	return null

static func gcSetDObjTransformsForGObj(gobj = null, dobjdesc = null):
	StubLog.hit("ObjAnim.gcSetDObjTransformsForGObj")
	return null

static func gcAddCObjCamAnimJoint(cobj = null, camanim_joint = null, anim_frame = null):
	StubLog.hit("ObjAnim.gcAddCObjCamAnimJoint")
	return null

static func gcParseCObjCamAnimJoint(cobj = null):
	StubLog.hit("ObjAnim.gcParseCObjCamAnimJoint")
	return null

static func gcPlayCObjCamAnim(cobj = null):
	StubLog.hit("ObjAnim.gcPlayCObjCamAnim")
	return null

static func gcPlayCamAnim(gobj = null):
	StubLog.hit("ObjAnim.gcPlayCamAnim")
	return null

static func gcGetAnimTotalLength(anim_joints = null):
	StubLog.hit("ObjAnim.gcGetAnimTotalLength")
	return null

## lbcommon.c lbCommonPlayTranslateScaledDObjAnim (translation tracks multiplied by a per-joint scale)
static func lbCommonPlayTranslateScaledDObjAnim(dobj: DObj, scale: Vector3) -> void:
	if dobj.anim_wait == AOBJ_ANIM_NULL:
		return
	for aobj in dobj.aobj:
		if aobj.kind == nGCAnimKindNone:
			continue
		if dobj.anim_wait != AOBJ_ANIM_END:
			aobj.length += dobj.anim_speed
		match aobj.track:
			nGCAnimTrackRotX:
				dobj.rotate.x = gcGetAObjValue(aobj)
			nGCAnimTrackRotY:
				dobj.rotate.y = gcGetAObjValue(aobj)
			nGCAnimTrackRotZ:
				dobj.rotate.z = gcGetAObjValue(aobj)
			nGCAnimTrackTraI:
				pass
			nGCAnimTrackTraX:
				dobj.translate.x = gcGetAObjValue(aobj) * scale.x
			nGCAnimTrackTraY:
				dobj.translate.y = gcGetAObjValue(aobj) * scale.y
			nGCAnimTrackTraZ:
				dobj.translate.z = gcGetAObjValue(aobj) * scale.z
			nGCAnimTrackScaX:
				dobj.scale.x = gcGetAObjValue(aobj)
			nGCAnimTrackScaY:
				dobj.scale.y = gcGetAObjValue(aobj)
			nGCAnimTrackScaZ:
				dobj.scale.z = gcGetAObjValue(aobj)
	if dobj.anim_wait == AOBJ_ANIM_END:
		dobj.anim_wait = AOBJ_ANIM_NULL
