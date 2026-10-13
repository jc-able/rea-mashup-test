## Port of MPObjectColl (src/mp/mptypes.h): the "diamond" map-collision box.
class_name MPObjectColl
extends RefCounted

var top: float = 0.0
var center: float = 0.0
var bottom: float = 0.0
var width: float = 0.0

static func make(t: float, c: float, b: float, w: float) -> MPObjectColl:
	var o := MPObjectColl.new()
	o.top = t; o.center = c; o.bottom = b; o.width = w
	return o

func dup() -> MPObjectColl:
	return MPObjectColl.make(top, center, bottom, width)
