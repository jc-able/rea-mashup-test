## Raw AObj event stream exactly as stored in the ROM.
## u: unsigned words (u16 for figatree / u32 for AnimJoint), f: the same words reinterpreted
## as IEEE floats (only meaningful for 32-bit streams), ptr: word index -> {stream, index}
## for pointer operands (Jump / SetAnim / SetInterp) in 32-bit streams.
class_name AnimStream
extends RefCounted

var is16: bool = true
var u: PackedInt64Array = PackedInt64Array()
var f: PackedFloat32Array = PackedFloat32Array()
var ptr: Dictionary = {}        # word index -> [AnimStream, index]
var name: String = ""

static func from_u16(values: Array, nm: String = "") -> AnimStream:
	var s := AnimStream.new()
	s.is16 = true
	s.u = PackedInt64Array(values)
	s.name = nm
	return s

static func from_u32(values: Array, nm: String = "") -> AnimStream:
	var s := AnimStream.new()
	s.is16 = false
	s.u = PackedInt64Array(values)
	var b := PackedByteArray()
	b.resize(4 * values.size())
	for i in values.size():
		b.encode_u32(i * 4, int(values[i]) & 0xFFFFFFFF)
	s.f = b.to_float32_array()
	s.name = nm
	return s

func s16(i: int) -> int:
	var v: int = u[i] & 0xFFFF
	return v - 0x10000 if v >= 0x8000 else v
