## Port of GMHitFlags (src/gm/gmtypes.h). C copies this struct by value: use dup()/copy_from().
class_name GMHitFlags
extends RefCounted

var is_interact_hurt: int = 0
var is_interact_shield: int = 0
var is_interact_reflect: int = 0
var is_interact_absorb: int = 0
var group_id: int = 0
var timer_rehit: int = 0

func dup() -> GMHitFlags:
	var f := GMHitFlags.new()
	f.copy_from(self)
	return f

func copy_from(o: GMHitFlags) -> void:
	is_interact_hurt = o.is_interact_hurt
	is_interact_shield = o.is_interact_shield
	is_interact_reflect = o.is_interact_reflect
	is_interact_absorb = o.is_interact_absorb
	group_id = o.group_id
	timer_rehit = o.timer_rehit
