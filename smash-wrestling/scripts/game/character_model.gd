class_name CharacterModel
extends RefCounted
## Builds the visual model of a roster character and its retarget spec.
## Smash 64 model: res://assets/fighters/<kind>/<kind>.glb (extracted from the ROM by tools/smash_models)
## + res://data/retarget/<kind>.json (tools/retarget/build_retarget.py).  Fallback: Mannequin (labeled blockout).

var root: Node3D           # node to parent under the wrestler (already scaled)
var skeleton: Skeleton3D
var spec: Dictionary = {}
var model_scale := 1.0
var hip_height_world := 0.92
var height_world := 1.8
var own_anims: Dictionary = {}   # Smash 64 own animations (baked), see SmashAnim
var is_fallback := true
var kind := ""
var joint_for_src := {}          # SvR joint index -> bone index (for hand/foot positions)


static func create(kind_: String, height_m: float, tint: Color) -> CharacterModel:
	var cm := CharacterModel.new()
	cm.kind = kind_
	if not cm._try_smash(kind_, height_m):
		cm._mannequin(height_m, tint)
	for b in cm.spec.get("bones", []):
		var s := int(b.get("src", -1))
		if s >= 0 and not cm.joint_for_src.has(s):
			var bi := cm.skeleton.find_bone(b["name"])
			if bi >= 0:
				cm.joint_for_src[s] = bi
	return cm


func _try_smash(kind_: String, height_m: float) -> bool:
	var glb := "res://assets/fighters/%s/%s.glb" % [kind_, kind_]
	var rt := "res://data/retarget/%s.json" % kind_
	if not ResourceLoader.exists(glb) or not FileAccess.file_exists(rt):
		return false
	var ps = load(glb)
	if not (ps is PackedScene):
		return false
	var inst: Node3D = ps.instantiate()
	var sk := _find_skeleton(inst)
	if sk == null:
		inst.queue_free()
		return false
	spec = JSON.parse_string(FileAccess.get_file_as_string(rt))
	var model_h := float(spec.get("height", 1.0))
	model_scale = height_m / maxf(model_h, 0.01)
	var holder := Node3D.new()
	holder.name = "Model"
	holder.scale = Vector3.ONE * model_scale
	holder.add_child(inst)
	root = holder
	skeleton = sk
	hip_height_world = float(spec.get("hip_height", model_h * 0.5)) * model_scale
	height_world = height_m
	is_fallback = false
	var ap := "res://assets/fighters/%s/%s_anims.json" % [kind_, kind_]
	if FileAccess.file_exists(ap):
		var d = JSON.parse_string(FileAccess.get_file_as_string(ap))
		if d is Dictionary:
			own_anims = d
	# imported scenes may carry an AnimationPlayer; make sure nothing fights our pose writes
	for ap_node in inst.find_children("*", "AnimationPlayer", true, false):
		(ap_node as AnimationPlayer).stop()
	return true


static func _find_skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var r := _find_skeleton(c)
		if r:
			return r
	return null


func _mannequin(height_m: float, tint: Color) -> void:
	var m := Mannequin.new()
	m.tint = tint
	m.build()
	var holder := Node3D.new()
	holder.name = "Model"
	model_scale = height_m / 1.80
	holder.scale = Vector3.ONE * model_scale
	holder.add_child(m)
	root = holder
	skeleton = m.skeleton
	spec = m.spec
	hip_height_world = float(spec["hip_height"]) * model_scale
	height_world = height_m
	is_fallback = true
