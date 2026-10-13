## Loaded per-fighter data (port of FTData + the reloc files it points at), built by SSBData from
## the ROM export in res://data/ssb64/fighters/<kind>.json and res://data/ssb64/anims/<kind>.json.
class_name FtData
extends RefCounted

var kind: String = ""
var fkind: int = 0
var file_ids: Dictionary = {}        # FTData file_*_id values (main, mainmotion, model, special1..4, shieldpose)
var attr: Dictionary = {}            # FTAttributes (C field names, see PORTING.md section 5)
var joints_desc: Array = []          # exported joint records (index == fp->joints[] index)
var commonparts: Array = [[], []]    # [detail high, detail low]: DObjDesc array {id, dl, translate, rotate, scale}
var mainmotion: Array = []           # FTMotionDescArray: per motion_id {anim_file_id, anim, anim_desc, script, subscript, ...}
var submotion: Array = []
var scripts: Dictionary = {}         # symbol -> MotionScriptData
var anims: Dictionary = {}           # anim_file_id -> Array[AnimStream] (figatree slot table)
var shield_pose: Dictionary = {}     # raw export (dobj_lookup / anim_joints are converted into attr)
