## Port of MPCollData (src/mp/mptypes.h). p_translate / p_lr point back at the owner
## object (C pointers): use owner.dobj.translate and owner.lr through the helpers below.
class_name MPCollData
extends RefCounted

var owner = null                # object owning this collision data (C: p_translate / p_lr targets)
var pos_prev: Vector3 = Vector3.ZERO
var pos_diff: Vector3 = Vector3.ZERO
var vel_speed: Vector3 = Vector3.ZERO
var vel_push: Vector3 = Vector3.ZERO
var map_coll: MPObjectColl = MPObjectColl.new()
var p_map_coll: MPObjectColl = null
var cliffcatch_coll: Vector2 = Vector2.ZERO

var mask_prev: int = 0
var mask_curr: int = 0
var mask_unk: int = 0
var mask_stat: int = 0

var update_tic: int = 0
var ewall_line_id: int = 0
var is_coll_end: int = 0

var line_coll_dist: Vector3 = Vector3.ZERO

var floor_line_id: int = -1
var floor_dist: float = 0.0
var floor_flags: int = 0
var floor_angle: Vector3 = Vector3.ZERO

var ceil_line_id: int = -1
var ceil_flags: int = 0
var ceil_angle: Vector3 = Vector3.ZERO

var lwall_line_id: int = -1
var lwall_flags: int = 0
var lwall_angle: Vector3 = Vector3.ZERO

var rwall_line_id: int = -1
var rwall_flags: int = 0
var rwall_angle: Vector3 = Vector3.ZERO

var cliff_id: int = 0
var ignore_line_id: int = -1

## *coll_data->p_translate
var p_translate: Vector3:
	get:
		return owner.dobj.translate
	set(v):
		owner.dobj.translate = v

## *coll_data->p_lr
var p_lr: int:
	get:
		return owner.lr
	set(v):
		owner.lr = v
