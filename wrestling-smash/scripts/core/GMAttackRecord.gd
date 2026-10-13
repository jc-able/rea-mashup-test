## Port of GMAttackRecord (src/gm/gmtypes.h).
class_name GMAttackRecord
extends RefCounted

var victim_gobj = null
var victim_flags: GMHitFlags = GMHitFlags.new()

func copy_from(o: GMAttackRecord) -> void:
	victim_gobj = o.victim_gobj
	victim_flags.copy_from(o.victim_flags)
