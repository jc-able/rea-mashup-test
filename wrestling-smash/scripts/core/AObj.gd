## Port of AObj (src/sys/objtypes.h): one animated track of a DObj.
class_name AObj
extends RefCounted

var track: int = 0
var kind: int = 0              # nGCAnimKind*
var interpolate = null         # spline description for TraI tracks
var rate_target: float = 0.0
var rate_base: float = 0.0
var value_target: float = 0.0
var value_base: float = 0.0
var length: float = 0.0
var length_invert: float = 1.0
