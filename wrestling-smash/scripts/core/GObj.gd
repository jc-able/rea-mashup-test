## Port of the GObj concept (src/sys/objtypes.h). In this port every game object is a GObj
## subclass (Fighter, Weapon, Item, GroundObj, ...) and also carries its "user_data" struct
## fields directly, so ftGetStruct(gobj) / wpGetStruct(gobj) return the object itself.
class_name GObj
extends RefCounted

var gobj_kind: int = 0
var link_id: int = 0
var gobj_flags: int = 0
var dobj: DObj = null                 # DObjGetStruct(gobj)
var anim_frame: float = 0.0
var user_data = null                  # for generic objects
var is_alive: bool = true
var processes: Array = []             # [{priority, proc: Callable, is_paused}]
var func_run: Callable = Callable()          # gobj->func_run (gcRunAll func_run pass)
var func_anim: Callable = Callable()
var display_proc: Callable = Callable()
var visual = null                     # render-side node
var debug_name: String = ""
