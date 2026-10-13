## Port of WPAttackColl + WPAttackPos (src/wp/wptypes.h).
class_name WPAttackColl
extends RefCounted

class WPAttackPos:
	var pos_curr: Vector3 = Vector3.ZERO
	var pos_prev: Vector3 = Vector3.ZERO
	var unk_wphitpos_0x18: int = 0
	var mtx: PackedFloat32Array = PackedFloat32Array([1,0,0, 0,1,0, 0,0,1, 0,0,0])
	var unk_wphitpos_0x5C: float = 0.0

var attack_state: int = 0
var damage: int = 0
var stale: float = 1.0
var element: int = 0
var offsets: Array = [Vector3.ZERO, Vector3.ZERO]
var size: float = 0.0
var angle: int = 0
var knockback_scale: int = 0
var knockback_weight: int = 0
var knockback_base: int = 0
var shield_damage: int = 0
var priority: int = 0
var interact_mask: int = 0
var fgm_id: int = 0
var can_setoff: int = 0
var can_rehit_item: int = 0
var can_rehit_fighter: int = 0
var can_rehit_shield: int = 0
var can_hop: int = 0
var can_reflect: int = 0
var can_absorb: int = 0
var can_not_heal: int = 0
var can_shield: int = 0
var motion_attack_id: int = 0
var motion_count: int = 0
var stat_flags := GMStatFlags.new()
var stat_count: int = 0
var attack_count: int = 0
var attack_pos: Array = [WPAttackPos.new(), WPAttackPos.new()]
var attack_records: Array = []

func _init() -> void:
	for i in SSBDefs.GMATTACKREC_NUM_MAX:
		attack_records.append(GMAttackRecord.new())
