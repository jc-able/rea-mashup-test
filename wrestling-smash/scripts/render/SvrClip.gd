## One original SmackDown vs. Raw 2011 motion, decoded from the game's m.pac motion banks by
## tools/svr_anim (format notes: evidence/svr_motion_format.md) and stored as a .svrm clip:
##   'SVRM', u32 version 1, u32 frame_count, f32 fps, u32 bone_count,
##   bone_count x {u8 name_len, name, u8 flags (1 = rotation per frame, 2 = translation per frame)},
##   per bone rotations  (flags & 1 ? frame_count : 1) x {f32 x, y, z, w},
##   per bone translations (flags & 2 ? frame_count : 1) x {f32 x, y, z}.
## Values are bone-local poses in the wrestler GLB skeleton space (Skeleton3D pose values).
## Presentation only: nothing here reads or writes engine state.
extends RefCounted

const RU = preload("res://scripts/render/RenderUtil.gd")
const DIR := "assets/svr_motions/"

var key := ""
var frames := 0
var fps := 60.0
var bones := PackedStringArray()
var rot: Array = []            # per bone PackedFloat32Array (4 or 4 * frames)
var pos: Array = []            # per bone PackedFloat32Array (3 or 3 * frames)
var rot_varies := PackedByteArray()
var pos_varies := PackedByteArray()
var ok := false

static var _cache: Dictionary = {}       # key -> clip (or null when missing)
static var _index = null                 # index.json (Dictionary) once loaded

static func index() -> Dictionary:
	if _index == null:
		_index = {}
		var p := RU.asset_path(DIR + "index.json")
		if FileAccess.file_exists(p):
			var d = JSON.parse_string(FileAccess.get_file_as_string(p))
			if d is Dictionary:
				_index = d
	return _index

static func has_clip(k: String) -> bool:
	return index().has(k)

## Cached clip by key ("<CATEGORY>_<motion_id>_<sub>"), or null.
static func get_clip(k: String):
	if _cache.has(k):
		return _cache[k]
	var c = null
	var info = index().get(k, null)
	var file: String = (info.get("file", k + ".svrm") if info is Dictionary else k + ".svrm")
	var path := RU.asset_path(DIR + file)
	if FileAccess.file_exists(path):
		var clip = load("res://scripts/render/SvrClip.gd").new()
		if clip.read(path, k):
			c = clip
		else:
			push_warning("SvrClip: bad clip " + path)
	_cache[k] = c
	return c

static func clear_cache() -> void:
	_cache.clear()
	_index = null

func read(path: String, k: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	key = k
	if f.get_buffer(4).get_string_from_ascii() != "SVRM" or f.get_32() != 1:
		return false
	frames = f.get_32()
	fps = f.get_float()
	var n := f.get_32()
	if frames <= 0 or n <= 0 or n > 512:
		return false
	bones.resize(n)
	rot_varies.resize(n)
	pos_varies.resize(n)
	for i in n:
		var ln := f.get_8()
		bones[i] = f.get_buffer(ln).get_string_from_ascii()
		var fl := f.get_8()
		rot_varies[i] = 1 if (fl & 1) else 0
		pos_varies[i] = 1 if (fl & 2) else 0
	rot.resize(n)
	pos.resize(n)
	for i in n:
		var cnt := 4 * (frames if rot_varies[i] else 1)
		rot[i] = f.get_buffer(cnt * 4).to_float32_array()
	for i in n:
		var cnt := 3 * (frames if pos_varies[i] else 1)
		pos[i] = f.get_buffer(cnt * 4).to_float32_array()
	ok = not f.eof_reached() or f.get_position() == f.get_length()
	return ok

## Clip length in 60 Hz engine frames.
func length_60() -> float:
	return frames * 60.0 / maxf(fps, 1.0)

## Local rotation of bone i at clip frame t (fractional, clamped to the clip).
func rotation_at(i: int, t: float) -> Quaternion:
	var a: PackedFloat32Array = rot[i]
	if not rot_varies[i]:
		return Quaternion(a[0], a[1], a[2], a[3]).normalized()
	t = clampf(t, 0.0, frames - 1.0)
	var i0 := int(t)
	var i1 := mini(i0 + 1, frames - 1)
	var q0 := Quaternion(a[i0 * 4], a[i0 * 4 + 1], a[i0 * 4 + 2], a[i0 * 4 + 3]).normalized()
	if i1 == i0:
		return q0
	var q1 := Quaternion(a[i1 * 4], a[i1 * 4 + 1], a[i1 * 4 + 2], a[i1 * 4 + 3]).normalized()
	return q0.slerp(q1, t - i0)

## Local translation of bone i at clip frame t (fractional, clamped).
func position_at(i: int, t: float) -> Vector3:
	var a: PackedFloat32Array = pos[i]
	if not pos_varies[i]:
		return Vector3(a[0], a[1], a[2])
	t = clampf(t, 0.0, frames - 1.0)
	var i0 := int(t)
	var i1 := mini(i0 + 1, frames - 1)
	var p0 := Vector3(a[i0 * 3], a[i0 * 3 + 1], a[i0 * 3 + 2])
	if i1 == i0:
		return p0
	var p1 := Vector3(a[i1 * 3], a[i1 * 3 + 1], a[i1 * 3 + 2])
	return p0.lerp(p1, t - i0)

func bone_index(bone_name: String) -> int:
	return bones.find(bone_name)
