## Port of FTDamageColl (src/ft/fttypes.h): a fighter hurtbox.
class_name FTDamageColl
extends RefCounted

var hitstatus: int = 0              # nGMHitStatus*
var joint_id: int = 0
var joint: DObj = null
var placement: int = 0              # 0 low, 1 middle, 2 high
var is_grabbable: int = 0
var offset: Vector3 = Vector3.ZERO
var size: Vector3 = Vector3.ZERO
