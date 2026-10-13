## Port of FTParts (src/ft/fttypes.h): per-joint matrix cache used to compute world
## positions of hitboxes/hurtboxes (see GmCollision). Matrices are 4x3 row-major arrays
## [m00,m01,m02, m10,m11,m12, m20,m21,m22, m30,m31,m32] using the N64 row-vector layout.
class_name FtParts
extends RefCounted

var transform_update_mode: int = 0
var unk_dobjtrans_0x4: int = 0
var unk_dobjtrans_0x5: int = 0     # world matrix valid
var unk_dobjtrans_0x6: int = 0     # scale valid
var unk_dobjtrans_0x7: int = 0     # inverse valid
var flags: int = 0
var joint_id: int = 0
var is_have_anim: bool = false
var unk_dobjtrans_0x10: PackedFloat32Array = PackedFloat32Array([1,0,0, 0,1,0, 0,0,1, 0,0,0])  # local matrix
var mtx_translate: PackedFloat32Array = PackedFloat32Array([1,0,0, 0,1,0, 0,0,1, 0,0,0])       # world matrix
var vec_scale: Vector3 = Vector3.ONE
var unk_dobjtrans_0x9C: PackedFloat32Array = PackedFloat32Array([1,0,0, 0,1,0, 0,0,1, 0,0,0])  # inverse world
var gobj = null

func clear_word() -> void:
	unk_dobjtrans_0x4 = 0
	unk_dobjtrans_0x5 = 0
	unk_dobjtrans_0x6 = 0
	unk_dobjtrans_0x7 = 0
