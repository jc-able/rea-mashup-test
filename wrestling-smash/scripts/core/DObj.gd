## Port of DObj (src/sys/objtypes.h): a node of an object's joint tree.
## Tree links (parent/child/sib_prev/sib_next) are kept exactly like the C linked lists
## because the game re-parents joints at runtime (hidden parts, TransN handling) and
## maps animation tables onto joints in tree pre-order.
class_name DObj
extends RefCounted

var id: int = 0
var parent_gobj = null          # owning object (Fighter / Weapon / Item / ground object)
var parent: DObj = null         # null == DOBJ_PARENT_NULL
var child: DObj = null
var sib_prev: DObj = null
var sib_next: DObj = null

var translate: Vector3 = Vector3.ZERO
var rotate: Vector3 = Vector3.ZERO
var scale: Vector3 = Vector3.ONE
var flags: int = 0
var dl = null                   # non-null when the joint carries a visible model part

var user_data = null            # FtParts for fighter joints
var aobj: Array = []            # AObj tracks in append order (C linked list dobj->aobj)

## Animation script: event16 (figatree, u16 halfwords) or event32 (u32 words)
var anim_is16: bool = true
var anim_data: AnimStream = null
var anim_pos: int = -1          # -1 == NULL script
var anim_wait: float = SSBDefs.F32_MIN
var anim_speed: float = 1.0
var anim_frame: float = 0.0
var is_anim_root: bool = false

var xobj_unk05: int = 0         # xobjs[0]->unk05 (anim-lock marker)
var debug_name: String = ""
