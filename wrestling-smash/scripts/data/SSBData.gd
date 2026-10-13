## Loader for the Super Smash Bros. 64 data exported from the ROM (baserom.us.z64, relocData
## segment) into res://data/ssb64/ by tools/ssb64. Converts the JSON into the runtime structures
## used by the C->GDScript port:
##   * FtData (src/ft/fttypes.h FTData + the reloc files it points at)
##   * fp.attr Dictionary with the exact FTAttributes field names (PORTING.md section 5)
##   * motion scripts decoded from the raw ROM words with the C bitfield layouts of
##     src/ft/fttypes.h (FTMotionEvent*), linked with MotionPtr for Goto/Subroutine/Parallel
##   * figatree / AnimJoint streams as AnimStream (raw u16 / u32 words, parsed at runtime by
##     ObjAnim exactly like ftAnimParseDObjFigatree / gcParseDObjAnimJoint)
class_name SSBData
extends Port

const ROOT := "res://data/ssb64/"

## Data file key per fighter kind. Variants (polygon team, Metal Mario, Giant DK) share the
## playable fighter's export (they are not used by VS mode).
const FKIND_DATA_NAME := {
	nFTKindMario: "mario", nFTKindFox: "fox", nFTKindDonkey: "donkey", nFTKindSamus: "samus",
	nFTKindLuigi: "luigi", nFTKindLink: "link", nFTKindYoshi: "yoshi", nFTKindCaptain: "captain",
	nFTKindKirby: "kirby", nFTKindPikachu: "pikachu", nFTKindPurin: "purin", nFTKindNess: "ness",
	nFTKindMMario: "mario", nFTKindNMario: "mario", nFTKindNFox: "fox", nFTKindNDonkey: "donkey",
	nFTKindNSamus: "samus", nFTKindNLuigi: "luigi", nFTKindNLink: "link", nFTKindNYoshi: "yoshi",
	nFTKindNCaptain: "captain", nFTKindNKirby: "kirby", nFTKindNPikachu: "pikachu",
	nFTKindNPurin: "purin", nFTKindNNess: "ness", nFTKindGDonkey: "donkey",
}

static var _fighters: Dictionary = {}       # data name -> FtData
static var _common_scripts: Dictionary = {} # symbol -> MotionScriptData (FTCommonMoveset, file 201)
static var _damage_script_table: Array = [] # FTMotionDamageScript p_script[2][nFTKindEnumCount] (MotionPtr or null)
static var _common_loaded: bool = false
static var _json_cache: Dictionary = {}
static var errors: PackedStringArray = PackedStringArray()

# ---------------------------------------------------------------------------
# Generic helpers
# ---------------------------------------------------------------------------
static func load_json(path: String):
	if _json_cache.has(path):
		return _json_cache[path]
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_err("cannot open %s" % path)
		return null
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed == null:
		_err("JSON parse failed: %s" % path)
	return parsed

static func _err(msg: String) -> void:
	errors.append(msg)
	push_warning("SSBData: " + msg)

# f32(): inherited from Port (round to IEEE single; the ROM stores f32, JSON carries decimal doubles).

static func v2(a) -> Vector2:
	return Vector2(float(a[0]), float(a[1])) if a != null else Vector2.ZERO

static func v3(a) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2])) if a != null else Vector3.ZERO

static func _ints(a) -> Array:
	var out := []
	if a == null:
		return out
	for x in a:
		out.append(int(x))
	return out

static func _bit_signed(v: int, bits: int) -> int:
	var m := 1 << bits
	v &= m - 1
	return v - m if v >= (m >> 1) else v

static func data_name(fkind: int) -> String:
	return FKIND_DATA_NAME.get(fkind, "mario")

# ---------------------------------------------------------------------------
# Motion scripts (src/ft/fttypes.h FTMotionEvent* bitfields, MSB-first on the big-endian N64)
# ---------------------------------------------------------------------------
## Number of u32 words a command occupies (ftMotionEventAdvance sizes in ftmain.c).
static func motion_cmd_words(op: int) -> int:
	match op:
		nFTMotionEventMakeAttackColl, nFTMotionEventMakeAttackCollScaled:
			return 5   # FTMotionEventMakeAttack
		nFTMotionEventSetAttackCollOffset, nFTMotionEventSetThrow, nFTMotionEventSetDamageThrown, \
		nFTMotionEventSubroutine, nFTMotionEventGoto, nFTMotionEventSetParallelScript:
			return 2   # FTMotionEventDouble-sized
		nFTMotionEventEffect, nFTMotionEventEffectItemHold, nFTMotionEventSetDamageCollPartID:
			return 4   # FTMotionEventMakeEffect / FTMotionEventSetDamageCollPartID
	return 1           # FTMotionEventDefault-sized

static func _word(words: Array, i: int) -> int:
	return (int(words[i]) & 0xFFFFFFFF) if i < words.size() else 0

## Decode one command at word index p into a Dictionary with the C bitfield names.
static func decode_motion_cmd(words: Array, p: int) -> Dictionary:
	var w0 := _word(words, p)
	var op := (w0 >> 26) & 0x3F
	var c := {"op": op, "word_offset": p, "value": w0 & 0x3FFFFFF}
	match op:
		nFTMotionEventMakeAttackColl, nFTMotionEventMakeAttackCollScaled:
			var w1 := _word(words, p + 1)
			var w2 := _word(words, p + 2)
			var w3 := _word(words, p + 3)
			var w4 := _word(words, p + 4)
			c.attack_id = (w0 >> 23) & 0x7
			c.group_id = (w0 >> 20) & 0x7
			c.joint_id = _bit_signed(w0 >> 13, 7)
			c.damage = (w0 >> 5) & 0xFF
			c.can_rebound = (w0 >> 4) & 0x1
			c.element = w0 & 0xF
			c.size = (w1 >> 16) & 0xFFFF
			c.off_x = _bit_signed(w1, 16)
			c.off_y = _bit_signed(w2 >> 16, 16)
			c.off_z = _bit_signed(w2, 16)
			c.angle = _bit_signed(w3 >> 22, 10)
			c.knockback_scale = (w3 >> 12) & 0x3FF
			c.knockback_weight = (w3 >> 2) & 0x3FF
			c.is_hit_ground_air = w3 & 0x3
			c.shield_damage = _bit_signed(w4 >> 24, 8)
			c.fgm_level = (w4 >> 21) & 0x7
			c.fgm_kind = (w4 >> 17) & 0xF
			c.knockback_base = (w4 >> 7) & 0x3FF
		nFTMotionEventSetAttackCollOffset:
			var w1 := _word(words, p + 1)
			c.attack_id = (w0 >> 23) & 0x7
			c.off_x = _bit_signed(w0 >> 7, 16)
			c.off_y = _bit_signed(w1 >> 16, 16)
			c.off_z = _bit_signed(w1, 16)
		nFTMotionEventSetAttackCollDamage:
			c.attack_id = (w0 >> 23) & 0x7
			c.damage = (w0 >> 15) & 0xFF
		nFTMotionEventSetAttackCollSize:
			c.attack_id = (w0 >> 23) & 0x7
			c.size = (w0 >> 7) & 0xFFFF
		nFTMotionEventSetAttackCollSoundLevel:
			c.attack_id = (w0 >> 23) & 0x7
			c.fgm_level = (w0 >> 20) & 0x7
		nFTMotionEventEffect, nFTMotionEventEffectItemHold:
			var w1 := _word(words, p + 1)
			var w2 := _word(words, p + 2)
			var w3 := _word(words, p + 3)
			c.joint_id = _bit_signed(w0 >> 19, 7)
			c.effect_id = (w0 >> 10) & 0x1FF
			c.flag = w0 & 0x3FF
			c.off_x = _bit_signed(w1 >> 16, 16)
			c.off_y = _bit_signed(w1, 16)
			c.off_z = _bit_signed(w2 >> 16, 16)
			c.rng_x = _bit_signed(w2, 16)
			c.rng_y = _bit_signed(w3 >> 16, 16)
			c.rng_z = _bit_signed(w3, 16)
		nFTMotionEventSetHitStatusPartID:
			c.joint_id = _bit_signed(w0 >> 19, 7)
			c.hitstatus = w0 & 0x7FFFF
		nFTMotionEventSetDamageCollPartID:
			var w1 := _word(words, p + 1)
			var w2 := _word(words, p + 2)
			var w3 := _word(words, p + 3)
			c.joint_id = _bit_signed(w0 >> 19, 7)
			c.off_x = _bit_signed(w1 >> 16, 16)
			c.off_y = _bit_signed(w1, 16)
			c.off_z = _bit_signed(w2 >> 16, 16)
			c.size_x = _bit_signed(w2, 16)
			c.size_y = _bit_signed(w3 >> 16, 16)
			c.size_z = _bit_signed(w3, 16)
		nFTMotionEventSetModelPartID:
			c.joint_id = _bit_signed(w0 >> 19, 7)
			c.modelpart_id = _bit_signed(w0, 19)
		nFTMotionEventSetTexturePartID:
			c.texturepart_id = (w0 >> 20) & 0x3F
			c.frame = w0 & 0xFFFFF
		nFTMotionEventSetColAnim:
			c.colanim_id = (w0 >> 18) & 0xFF
			c.length = w0 & 0x3FFFF
		nFTMotionEventSetSlopeContour:
			c.flags = w0 & 0x7
		nFTMotionEventSetAfterImage:
			c.is_itemswing = (w0 >> 18) & 0xFF
			c.drawstatus = _bit_signed(w0, 18)
		nFTMotionEventMakeRumble:
			c.length = (w0 >> 13) & 0x1FFF
			c.rumble_id = w0 & 0x1FFF
		nFTMotionEventStopRumble:
			c.rumble_id = w0 & 0x3FFFFFF
	return c

## Decode a whole script (raw ROM words). Pointer operands are recorded in `pending` as
## [cmd, key, pointer_desc] and linked by _link_scripts once every script is decoded.
static func decode_motion_script(nm: String, raw: Dictionary, decoded_list, pending: Array) -> MotionScriptData:
	var s := MotionScriptData.new()
	s.name = nm
	var words: Array = raw.get("raw_words", [])
	var ptr_words: Dictionary = raw.get("pointer_words", {})
	var throw_by_offset := {}
	if decoded_list is Array:
		for dc in decoded_list:
			if dc.get("op", "") == "SetThrow" and dc.has("throw_desc"):
				throw_by_offset[int(dc.word_offset)] = dc.throw_desc
	var p := 0
	while p < words.size():
		var c := decode_motion_cmd(words, p)
		var op: int = c.op
		var n := motion_cmd_words(op)
		match op:
			nFTMotionEventSubroutine, nFTMotionEventGoto, nFTMotionEventSetParallelScript:
				var key := str(p + 1)
				if ptr_words.has(key):
					pending.append([c, "target", ptr_words[key], nm])
				else:
					c.target = null
					_err("%s word %d: %d without pointer operand" % [nm, p, op])
			nFTMotionEventSetThrow:
				if throw_by_offset.has(p):
					var descs := []
					for td in throw_by_offset[p]:
						descs.append({
							"status_id": int(td.status_id), "damage": int(td.damage), "angle": int(td.angle),
							"knockback_scale": int(td.knockback_scale), "knockback_weight": int(td.knockback_weight),
							"knockback_base": int(td.knockback_base), "element": int(td.element),
						})
					c.throw_desc = descs
				else:
					c.throw_desc = null
					_err("%s word %d: SetThrow without exported throw_desc" % [nm, p])
			nFTMotionEventSetDamageThrown:
				c.p_damage = _damage_script_table
		s.word_to_index[p] = s.cmds.size()
		s.cmds.append(c)
		p += n
	# Terminal sentinel so that running off the end of the data behaves like End.
	s.word_to_index[p] = s.cmds.size()
	s.cmds.append({"op": nFTMotionEventEnd, "word_offset": p, "value": 0})
	for i in s.cmds.size():
		s.cmds[i].next = mini(i + 1, s.cmds.size() - 1)
	return s

static func _resolve_ptr(desc, scripts: Dictionary) -> MotionPtr:
	if desc == null or not (desc is Dictionary) or not desc.has("script"):
		return null
	var nm: String = desc.script
	var s: MotionScriptData = scripts.get(nm, null)
	if s == null:
		s = _common_scripts.get(nm, null)
	if s == null:
		_err("unresolved script pointer %s" % nm)
		return null
	var wo := int(desc.get("word_offset", 0))
	if not s.word_to_index.has(wo):
		_err("pointer into the middle of a command: %s+%d" % [nm, wo])
		return null
	return MotionPtr.make(s, s.word_to_index[wo])

static func _link_scripts(pending: Array, scripts: Dictionary) -> void:
	for pe in pending:
		var c: Dictionary = pe[0]
		c[pe[1]] = _resolve_ptr(pe[2], scripts)

# ---------------------------------------------------------------------------
# Common moveset (FTCommonMoveset, file 201) + thrown damage script table
# ---------------------------------------------------------------------------
static func _ensure_common() -> void:
	if _common_loaded:
		return
	_common_loaded = true
	var cj = load_json(ROOT + "fighters/common.json")
	if cj == null:
		return
	# dFTCommonMoveset_DamageScript: void *p_script[2][nFTKindEnumCount]
	_damage_script_table.clear()
	var pending := []
	for nm in cj.script_raw:
		_common_scripts[nm] = decode_motion_script(nm, cj.script_raw[nm], cj.scripts.get(nm, null), pending)
	_link_scripts(pending, _common_scripts)
	var table = cj.get("damage_script_table", {}).get("entries", [])
	for row in table:
		var out_row := []
		for e in row:
			out_row.append(_resolve_ptr(e, _common_scripts))
		_damage_script_table.append(out_row)

static func damage_script_table() -> Array:
	_ensure_common()
	return _damage_script_table

# ---------------------------------------------------------------------------
# Animations
# ---------------------------------------------------------------------------
static func _make_anim(entry: Dictionary) -> Array:
	var out := []
	var is16: bool = entry.get("format", "figatree16") == "figatree16"
	var nm: String = entry.get("name", "")
	var k := 0
	for words in entry.get("joints", []):
		if words == null:
			out.append(null)
		elif is16:
			out.append(AnimStream.from_u16(words, "%s[%d]" % [nm, k]))
		else:
			out.append(AnimStream.from_u32(words, "%s[%d]" % [nm, k]))
		k += 1
	# SYInterpDesc spline data (TraI track, e.g. Samus RollF/RollB): attach each decoded descriptor to
	# the stream word that holds its (relative) pointer operand.
	var interp = entry.get("interp", null)
	if interp is Dictionary:
		for key in interp:
			var d: Dictionary = interp[key]
			var pts := []
			for pt in d.get("points", []):
				pts.append(v3(pt))
			var kfs := []
			for x in d.get("keyframes", []):
				kfs.append(f32(float(x)))
			var qs := []
			for x in d.get("quartics", []):
				qs.append(f32(float(x)))
			var desc := {
				"kind": int(d.kind), "points_num": int(d.points_num), "unk04": f32(float(d.get("unk04", 0.0))),
				"length": f32(float(d.length)), "points": pts, "keyframes": kfs, "quartics": qs,
			}
			for r in d.get("refs", []):
				var slot := int(r.slot)
				if slot < out.size() and out[slot] != null:
					out[slot].ptr[int(r.operand_hw_index)] = desc
	return out

static func _anim_joint_table(tbl) -> Array:
	var out := []
	if tbl == null:
		return out
	var k := 0
	for e in tbl:
		if e == null:
			out.append(null)
		else:
			var s := AnimStream.from_u32(e.words, str(e.get("stream", "shield%d" % k)))
			out.append(s)
		k += 1
	return out

# ---------------------------------------------------------------------------
# Fighters
# ---------------------------------------------------------------------------
static func get_fighter(fkind: int) -> FtData:
	var nm := data_name(fkind)
	if _fighters.has(nm):
		return _fighters[nm]
	var fd := _load_fighter(nm)
	if fd != null:
		fd.fkind = fkind
		_fighters[nm] = fd
	return fd

static func _dl_marker(joint_index: int, detail: int, has_dl: bool):
	if not has_dl:
		return null
	return {"joint": joint_index, "detail": detail}

static func _load_fighter(nm: String) -> FtData:
	_ensure_common()
	var j = load_json(ROOT + "fighters/%s.json" % nm)
	var aj = load_json(ROOT + "anims/%s.json" % nm)
	if j == null or aj == null:
		return null
	var fd := FtData.new()
	fd.kind = nm
	fd.fkind = int(j.ft_kind)
	fd.file_ids = j.get("file_ids", {})

	# --- motion scripts -----------------------------------------------------
	var pending := []
	for snm in j.script_raw:
		fd.scripts[snm] = decode_motion_script(snm, j.script_raw[snm], j.scripts.get(snm, null), pending)
	_link_scripts(pending, fd.scripts)

	# --- animations (figatree tables), shared between motions using the same file ---------
	for fid in aj:
		fd.anims[int(fid)] = _make_anim(aj[fid])

	# --- motion descs -------------------------------------------------------
	fd.mainmotion = _motion_descs(fd, j.motion_descs)
	fd.submotion = _motion_descs(fd, j.get("submotion_descs", []))

	# --- joints / commonparts -------------------------------------------------
	fd.joints_desc = j.joints
	var hi := []
	var dobj_count := 0
	for jr in j.joints:
		if jr.get("from_dobjdesc", false):
			dobj_count = maxi(dobj_count, int(jr.dobjdesc_index) + 1)
	hi.resize(dobj_count)
	var lo := []
	lo.resize(dobj_count)
	for jr in j.joints:
		if not jr.get("from_dobjdesc", false):
			continue
		var i := int(jr.dobjdesc_index)
		var ji := int(jr.index)
		hi[i] = {
			"id": int(jr.dobjdesc_id), "dl": _dl_marker(ji, nFTPartsDetailHigh, jr.get("has_dl_hi", false)),
			"translate": v3(jr.translate), "rotate": v3(jr.rotate), "scale": v3(jr.scale),
		}
		lo[i] = {
			"id": int(jr.dobjdesc_id), "dl": _dl_marker(ji, nFTPartsDetailLow, jr.get("has_dl_lo", false)),
			"translate": v3(jr.translate), "rotate": v3(jr.rotate), "scale": v3(jr.scale),
		}
	# Low-detail DObjDesc transforms when exported (commonparts[1].dobjdesc)
	var cplo = j.get("commonparts_lo", null)
	if cplo is Array:
		for e in cplo:
			var i := int(e.dobjdesc_index)
			if i < lo.size():
				lo[i] = {
					"id": int(e.id), "dl": _dl_marker(nFTPartsJointCommonStart + i, nFTPartsDetailLow, e.get("has_dl", false)),
					"translate": v3(e.translate), "rotate": v3(e.rotate), "scale": v3(e.scale),
				}
	fd.commonparts = [hi, lo]

	# --- attributes -----------------------------------------------------------
	fd.attr = _convert_attr(j.attributes, j.get("shield_pose", null))
	fd.shield_pose = j.get("shield_pose", {})
	return fd

static func _motion_descs(fd: FtData, arr) -> Array:
	var out := []
	if arr == null:
		return out
	for m in arr:
		var mid := int(m.motion_id)
		while out.size() <= mid:
			out.append(null)
		var anim_file_id := int(m.anim_file_id)
		var anim_desc := int(m.anim_desc) & 0xFFFFFFFF
		var md := {
			"motion_id": mid,
			"name": m.get("motion_name", m.get("anim_name", "")),
			"anim_name": m.get("anim_name", ""),
			"anim_file_id": anim_file_id,
			"anim_desc": anim_desc,
			"anim": null,
			"shieldpose_anim": null,
			"script": null,
			"subscript": null,
		}
		if anim_file_id != 0 and not (anim_desc & FTANIM_FLAG_SHIELDPOSE):
			md.anim = fd.anims.get(anim_file_id, null)
			if md.anim == null:
				_err("%s motion %d: anim %d missing" % [fd.kind, mid, anim_file_id])
		var snm = m.get("script", null)
		if snm != null:
			var desc := {"script": snm, "word_offset": int(m.get("script_offset_bytes", 0)) / 4}
			var ptr := _resolve_ptr(desc, fd.scripts)
			md.script = ptr
			md.subscript = ptr
		out[mid] = md
	return out

static func _rgba(a) -> Dictionary:
	if a == null:
		return {"r": 0, "g": 0, "b": 0, "a": 0}
	return {"r": int(a[0]), "g": int(a[1]), "b": int(a[2]), "a": int(a[3])}

static func _convert_attr(a: Dictionary, shield_pose) -> Dictionary:
	var out := {}
	for k in a:
		var v = a[k]
		if v is bool:
			out[k] = 1 if v else 0
		elif v is float:
			out[k] = f32(v)
		else:
			out[k] = v
	# integers (JSON numbers are floats in Godot): C integer fields
	for k in ["jumps_max", "deadup_sfx", "damage_sfx", "heavyget_sfx", "itemthrow_vel_scale",
			"itemthrow_damage_scale", "joint_rfoot_id", "joint_lfoot_id", "joint_itemheavy_id",
			"joint_itemlight_id", "unused_0x2CC"]:
		if out.has(k) and out[k] != null:
			out[k] = int(out[k])
	out.dead_fgm_ids = _ints(a.get("dead_fgm_ids", []))
	out.smash_sfx = _ints(a.get("smash_sfx", []))
	out.effect_joint_ids = _ints(a.get("effect_joint_ids", []))
	out.cliff_status_ga = _ints(a.get("cliff_status_ga", []))
	out.setup_parts = _ints(a.get("setup_parts", [0, 0]))
	out.animlock = _ints(a.get("animlock", [0, 0]))
	var mc = a.get("map_coll", null)
	out.map_coll = MPObjectColl.make(float(mc.top), float(mc.center), float(mc.bottom), float(mc.width)) if mc != null else MPObjectColl.new()
	out.cliffcatch_coll = v2(a.get("cliffcatch_coll", null))
	out.hit_detect_range = v3(a.get("hit_detect_range", null))
	var ip = a.get("item_pickup", null)
	if ip != null:
		out.item_pickup = {
			"pickup_offset_light": v2(ip.pickup_offset_light), "pickup_range_light": v2(ip.pickup_range_light),
			"pickup_offset_heavy": v2(ip.pickup_offset_heavy), "pickup_range_heavy": v2(ip.pickup_range_heavy),
		}
	var dcs := []
	for d in a.get("damage_coll_descs", []):
		dcs.append({
			"joint_id": int(d.joint_id), "placement": int(d.placement),
			"is_grabbable": 1 if d.is_grabbable else 0, "offset": v3(d.offset), "size": v3(d.size),
		})
	while dcs.size() < FTPARTS_HURT_NUM_MAX:
		dcs.append({"joint_id": -1, "placement": 0, "is_grabbable": 0, "offset": Vector3.ZERO, "size": Vector3.ZERO})
	out.damage_coll_descs = dcs
	var ts = a.get("translate_scales", null)
	if ts != null:
		var arr := []
		for t in ts:
			arr.append(v3(t))
		out.translate_scales = arr
	else:
		out.translate_scales = null
	var th := []
	var tsd = a.get("thrown_status", null)
	if tsd != null:
		for e in tsd.by_victim_fkind:
			th.append({"ft_thrown": [
				{"status1": int(e.throw_f.status1), "status2": int(e.throw_f.status2)},
				{"status1": int(e.throw_b.status1), "status2": int(e.throw_b.status2)},
			]})
	out.thrown_status = th
	var hps := []
	for h in a.get("hiddenparts", []):
		hps.append({
			"root_joint_id": int(h.root_joint_id), "parent_joint_id": int(h.parent_joint_id),
			"partindex_0x8": int(h.partindex_0x8), "joint_kind": int(h.joint_kind),
		})
	out.hiddenparts = hps
	var sc := []
	for c in a.get("shade_color", []):
		sc.append(_rgba(c))
	out.shade_color = sc
	out.fog_color = _rgba(a.get("fog_color", null))
	var cpc = a.get("commonparts_container", null)
	var cps := []
	if cpc != null:
		for c in cpc.commonparts:
			cps.append({"flags": int(c.get("flags", 0))})
	out.commonparts_container = {"commonparts": cps}
	var tpc = a.get("textureparts_container", null)
	var tps := []
	if tpc != null:
		for t in tpc.get("textureparts", []):
			tps.append({"joint_id": int(t.joint_id), "detail": _ints(t.get("detail", []))})
	out.textureparts_container = {"textureparts": tps}
	var ap = a.get("accesspart", null)
	out.accesspart = {"joint_id": int(ap.joint_id), "dl": ap.get("dl", null)} if ap != null else null
	# Shield pose (attr->dobj_lookup, attr->shield_anim_joints[8][joint])
	var lookup := []
	var tables := []
	if shield_pose is Dictionary and not shield_pose.is_empty():
		for e in shield_pose.get("dobj_lookup", []):
			lookup.append({
				"id": int(e.id), "dl": e.get("dl", null),
				"translate": v3(e.translate), "rotate": v3(e.rotate), "scale": v3(e.scale),
			})
		for tbl in shield_pose.get("anim_joints", []):
			tables.append(_anim_joint_table(tbl))
	out.dobj_lookup = lookup
	out.shield_anim_joints = tables
	return out

# ---------------------------------------------------------------------------
# Stages
# ---------------------------------------------------------------------------
static func get_stage(stage_name: String):
	return load_json(ROOT + "stages/%s.json" % stage_name)

static func stage_index():
	return load_json(ROOT + "stages/index.json")
