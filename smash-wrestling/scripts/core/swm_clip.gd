class_name SwmClip
extends RefCounted
## Canonical SvR 2011 motion clip (SWM1, written by tools/swm/svr_to_swm.py; format in docs/CONVENTIONS.md).
## Per frame: hips position (canonical space: +Y up, +Z forward, +X left, metres) and, for the 21 SvR motion
## joints, the global rotation delta D = G_anim * inverse(G_ref) relative to the SvR reference T-pose.

const JOINT_NAMES := ["root", "koshi", "mune", "kubi", "atama",
	"l_sakotsu", "l_ninoude", "l_kote", "l_te", "r_sakotsu", "r_ninoude", "r_kote", "r_te",
	"l_momo", "l_sune", "l_ashi", "l_tsumasaki", "r_momo", "r_sune", "r_ashi", "r_tsumasaki"]
const J_ROOT := 0
const J_KOSHI := 1
const J_MUNE := 2
const J_KUBI := 3
const J_ATAMA := 4
const J_L_TE := 8
const J_R_TE := 12
const J_L_ASHI := 15
const J_R_ASHI := 19

var key: String = ""
var frames: int = 0
var fps: float = 30.0
var joint_count: int = 21
var keyed_mask: int = 0
var ref_hip_height: float = 0.9158
var hips: PackedVector3Array = PackedVector3Array()
var quats: PackedFloat32Array = PackedFloat32Array()   # frames * joint_count * 4 (x, y, z, w)
var events: Array = []                                  # [frame, opcode, PackedByteArray]
var support := PackedFloat32Array()                     # per frame: height the feet stand on (flags bit1)
var flags := 0

static var _cache: Dictionary = {}


static func load_clip(path: String) -> SwmClip:
	if _cache.has(path):
		return _cache[path]
	var c := SwmClip.new()
	if not c._load(path):
		return null
	_cache[path] = c
	return c


func _load(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("SwmClip: cannot open %s" % path)
		return false
	var data := f.get_buffer(f.get_length())
	f.close()
	if data.size() < 32 or data.slice(0, 4).get_string_from_ascii() != "SWM1":
		push_error("SwmClip: not SWM1 %s" % path)
		return false
	key = path.get_file().get_basename()
	frames = data.decode_u32(8)
	fps = data.decode_float(12)
	joint_count = data.decode_u32(16)
	flags = data.decode_u32(20)
	keyed_mask = data.decode_u32(24)
	ref_hip_height = data.decode_float(28)
	var p := 32
	var hb := data.slice(p, p + frames * 12).to_float32_array()
	hips.resize(frames)
	for i in frames:
		hips[i] = Vector3(hb[i * 3], hb[i * 3 + 1], hb[i * 3 + 2])
	p += frames * 12
	var nq := frames * joint_count * 4
	quats = data.slice(p, p + nq * 4).to_float32_array()
	p += nq * 4
	var ne := data.decode_u32(p)
	p += 4
	for i in ne:
		var fr := data.decode_u32(p)
		var op := data.decode_u32(p + 4)
		var nb := data.decode_u32(p + 8)
		p += 12
		events.append([fr, op, data.slice(p, p + nb)])
		p += nb + ((4 - nb % 4) % 4)
	if flags & 2 and p + 4 <= data.size():
		var ns := data.decode_u32(p)
		p += 4
		support = data.slice(p, p + ns * 4).to_float32_array()
	return true


## Height the feet stand on at fractional frame t (0 when the clip has no support track).
func support_at(t: float, loop: bool = false) -> float:
	if support.is_empty():
		return 0.0
	var n := support.size()
	if loop:
		t = fposmod(t, float(n))
	else:
		t = clampf(t, 0.0, float(n - 1))
	var f0 := int(floor(t))
	var f1 := mini(f0 + 1, n - 1)
	return lerpf(support[f0], support[f1], t - float(f0))


func length_sec() -> float:
	return float(frames) / fps


func quat_at(frame: int, j: int) -> Quaternion:
	var o := (clampi(frame, 0, frames - 1) * joint_count + j) * 4
	return Quaternion(quats[o], quats[o + 1], quats[o + 2], quats[o + 3])


## Interpolated sample at fractional frame t. Fills out_rots (size joint_count) and returns hips position.
func sample(t: float, out_rots: Array, loop: bool = false) -> Vector3:
	var n := frames
	if loop:
		t = fposmod(t, float(n))
	else:
		t = clampf(t, 0.0, float(n - 1))
	var f0 := int(floor(t))
	var f1 := f0 + 1
	if f1 >= n:
		f1 = 0 if loop else n - 1
	var u := t - float(f0)
	for j in joint_count:
		var a := quat_at(f0, j)
		var b := quat_at(f1, j)
		out_rots[j] = a.slerp(b, u) if u > 0.0001 else a
	return hips[f0].lerp(hips[f1], u)


func hips_at(t: float) -> Vector3:
	t = clampf(t, 0.0, float(frames - 1))
	var f0 := int(floor(t))
	var f1 := mini(f0 + 1, frames - 1)
	return hips[f0].lerp(hips[f1], t - float(f0))


## Heading (radians about +Y, 0 = +Z, positive towards +X) of the pelvis (SvR 'root') at frame f.
func yaw_at(frame: int) -> float:
	var fwd := quat_at(frame, J_ROOT) * Vector3(0, 0, 1)
	return atan2(fwd.x, fwd.z)


## Frames carrying a given motion event opcode (e.g. 0x56 = impact cue, per the earlier run's analysis).
func event_frames(opcode: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	for e in events:
		if e[1] == opcode:
			out.append(e[0])
	return out
