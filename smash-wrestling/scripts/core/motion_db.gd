extends Node
## Motion database (autoload "MotionDB"): SvR 2011 clip index, generic roles, moves, movesets.
## Data files are written by tools/swm/build_motion_library.py.

var lib: Dictionary = {}
var generic: Dictionary = {}
var generic_pairs: Dictionary = {}
var moves: Dictionary = {}
var movesets: Dictionary = {}
var holds: Dictionary = {}

## Pair placements checked visually on mannequins (evidence/motion/pairs_*.png). SvR STAT two-actor clips share
## the attacker's origin with the victim frame turned 180 deg (offset baked into the victim clip); the cover /
## kick-out variant subs of the splash moves share one frame (theta 0).
const GENERIC_PAIR_PLACEMENT := {
	"lock_facelock": [180.0, 0.0], "lock_wristlock": [180.0, 0.0], "lock_headlock": [180.0, 0.0],
	"lock_waistlock": [180.0, 0.0], "hold_facelock": [180.0, 0.0], "hold_wristlock": [180.0, 0.0],
	"hold_headlock": [180.0, 0.0], "hold_waistlock": [180.0, 0.0], "block_punch": [180.0, 0.0],
	"catch_kick": [180.0, 0.0], "whip_grab": [180.0, 0.0], "lift": [180.0, 0.0], "lift_down": [180.0, 0.0],
	"roll_over": [180.0, 0.0], "drag": [180.0, 0.0], "pin_cover": [0.0, 0.0], "pin_cover2": [0.0, 0.0],
}


func _ready() -> void:
	lib = _json("res://data/motion_library.json")
	var g := _json("res://data/generic_clips.json")
	generic = g.get("roles", {})
	generic_pairs = g.get("pairs", {})
	moves = _json("res://data/moves.json").get("moves", {})
	var ms := _json("res://data/movesets.json")
	movesets = ms.get("characters", {})
	holds = ms.get("holds", {})


func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("MotionDB: missing " + path)
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d if d is Dictionary else {}


func clip(key: String) -> SwmClip:
	var e: Dictionary = lib.get(key, {})
	if e.is_empty() or e.has("error"):
		return null
	return SwmClip.load_clip(e["file"])


func role(name: String) -> SwmClip:
	var r: Dictionary = generic.get(name, {})
	if r.is_empty():
		return null
	return clip(r["clip"])


func info(key: String) -> Dictionary:
	return lib.get(key, {})


func move(id) -> Dictionary:
	return moves.get(str(id), {})


func move_clip(id, role_idx: int) -> SwmClip:
	var m := move(id)
	if m.is_empty():
		return null
	var k = m["clips"].get(str(role_idx))
	return clip(k) if k != null else null


## Moveset slot lookup: group ("facelock", "ground", "special" ...) and label ("up", "throw_1", "finisher_1" ...)
func slot(kind: String, group: String, label: String) -> int:
	var c: Dictionary = movesets.get(kind, {})
	var g: Dictionary = c.get("slots", {}).get(group, {})
	return int(g.get(label, -1))


func slot_group(kind: String, group: String) -> Dictionary:
	return movesets.get(kind, {}).get("slots", {}).get(group, {})


## Placement transform of the victim clip frame relative to the attacker clip frame (canonical space).
static func pair_xform(theta_deg: float, d_m: float) -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(0, 0, d_m)) * Transform3D(Basis(Vector3.UP, deg_to_rad(theta_deg)), Vector3.ZERO)


func generic_pair_xform(name: String) -> Transform3D:
	var p: Array = GENERIC_PAIR_PLACEMENT.get(name, [180.0, 0.0])
	return pair_xform(p[0], p[1])


## Fitted placement for a move (tools/swm/moveset_report.py); small offsets snap to 0 (shared origin).
func move_pair_xform(id) -> Transform3D:
	var m := move(id)
	var p = m.get("pair")
	if p == null:
		return pair_xform(180.0, 0.0)
	var d := float(p.get("d_m", 0.0))
	if absf(d) < 0.25:
		d = 0.0
	return pair_xform(float(p.get("theta_deg", 180.0)), d)


func impact_frames(id) -> Array:
	return move(id).get("impact_frames", [])
