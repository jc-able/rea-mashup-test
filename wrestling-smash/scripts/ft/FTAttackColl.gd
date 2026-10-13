## Port of FTAttackColl (src/ft/fttypes.h): a fighter hitbox.
class_name FTAttackColl
extends RefCounted

var attack_state: int = 0           # nGMAttackState*
var group_id: int = 0
var joint_id: int = 0
var damage: int = 0
var element: int = 0
var joint: DObj = null
var offset: Vector3 = Vector3.ZERO
var size: float = 0.0
var angle: int = 0
var knockback_scale: int = 0
var knockback_weight: int = 0
var knockback_base: int = 0
var shield_damage: int = 0
var fgm_level: int = 0
var fgm_kind: int = 0
var is_hit_air: int = 0
var is_hit_ground: int = 0
var can_rebound: int = 0
var is_scale_pos: int = 0
var motion_attack_id: int = 0
var motion_count: int = 0
var stat_count: int = 0
var pos_curr: Vector3 = Vector3.ZERO
var pos_prev: Vector3 = Vector3.ZERO
var attack_records: Array = []      # GMAttackRecord x GMATTACKREC_NUM_MAX
## attack_matrix (FTAttackMatrix)
var attack_matrix_unk_fthitmtx_0x0: int = 0
var attack_matrix_mtx: PackedFloat32Array = PackedFloat32Array([1,0,0, 0,1,0, 0,0,1, 0,0,0])
var attack_matrix_unk_fthitmtx_0x44: float = 0.0

func _init() -> void:
	for i in SSBDefs.GMATTACKREC_NUM_MAX:
		attack_records.append(GMAttackRecord.new())
