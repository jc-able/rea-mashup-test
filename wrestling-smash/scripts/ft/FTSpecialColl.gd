## Port of FTSpecialColl (src/ft/fttypes.h): reflector / absorb sphere.
class_name FTSpecialColl
extends RefCounted

var kind: int = 0
var joint_id: int = 0
var offset: Vector3 = Vector3.ZERO
var size: Vector3 = Vector3.ZERO
var damage_resist: int = 0

static func make(k: int, j: int, o: Vector3, s: Vector3, r: int) -> FTSpecialColl:
	var c := FTSpecialColl.new()
	c.kind = k; c.joint_id = j; c.offset = o; c.size = s; c.damage_resist = r
	return c
