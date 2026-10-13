class_name Mannequin
extends Node3D
## Procedural 21-joint mannequin in the canonical SvR reference T-pose (data/svr_ref_pose.json).
## Used to validate the motion pipeline and as the labeled blockout fallback character. Custom (this run).

var skeleton: Skeleton3D
var spec: Dictionary = {}
@export var tint := Color(0.85, 0.85, 0.9)


func build() -> void:
	var ref: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/svr_ref_pose.json"))
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	add_child(skeleton)
	var pos := {}
	var bones := []
	for j in ref["joints"]:
		var n: String = j["name"]
		var p: Array = j["pos"]
		pos[n] = Vector3(p[0], p[1], p[2])
		var bi := skeleton.add_bone(n)
		if j["parent"] != null:
			skeleton.set_bone_parent(bi, skeleton.find_bone(j["parent"]))
	for j in ref["joints"]:
		var n: String = j["name"]
		var bi := skeleton.find_bone(n)
		var local: Vector3 = pos[n]
		if j["parent"] != null:
			local = pos[n] - pos[j["parent"]]
		skeleton.set_bone_rest(bi, Transform3D(Basis.IDENTITY, local))
		skeleton.set_bone_pose_position(bi, local)
		bones.append({"name": n, "src": SwmClip.JOINT_NAMES.find(n), "gref": [0, 0, 0, 1]})
	spec = {"bones": bones, "hips_bone": "root", "hip_height": float(ref["ref_hip_height"])}
	# visuals: one capsule per bone towards its first child
	var children := {}
	for j in ref["joints"]:
		if j["parent"] != null:
			if not children.has(j["parent"]):
				children[j["parent"]] = []
			children[j["parent"]].append(j["name"])
	for j in ref["joints"]:
		var n: String = j["name"]
		var col := tint
		if n.begins_with("l_"):
			col = tint.lerp(Color(0.2, 0.4, 1.0), 0.6)
		elif n.begins_with("r_"):
			col = tint.lerp(Color(1.0, 0.25, 0.2), 0.6)
		var att := BoneAttachment3D.new()
		att.bone_name = n
		skeleton.add_child(att)
		var kids: Array = children.get(n, [])
		if n == "atama":
			_add_mesh(att, _sphere(0.11), Transform3D(Basis.IDENTITY, Vector3(0, 0.1, 0.02)), col)
			continue
		for k in kids:
			if n == "root" and k != "koshi":
				continue
			var a: Vector3 = pos[n]
			var b: Vector3 = pos[k]
			var len := a.distance_to(b)
			if len < 0.02:
				continue
			var dir := (b - a) / len
			var basis := _basis_y_to(dir)
			var r := 0.075 if n in ["root", "koshi", "mune"] else 0.05
			_add_mesh(att, _capsule(r, len + r), Transform3D(basis, (b - a) * 0.5), col)
		if n in ["l_te", "r_te"]:
			_add_mesh(att, _sphere(0.05), Transform3D(Basis.IDENTITY, Vector3(0.05 if n == "l_te" else -0.05, 0, 0)), col)


func _basis_y_to(dir: Vector3) -> Basis:
	var up := Vector3.UP
	var axis := up.cross(dir)
	if axis.length() < 1e-5:
		return Basis.IDENTITY if dir.y > 0 else Basis(Vector3.RIGHT, PI)
	return Basis(axis.normalized(), up.angle_to(dir))


func _capsule(r: float, h: float) -> Mesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = maxf(h, 2.0 * r)
	m.radial_segments = 12
	m.rings = 4
	return m


func _sphere(r: float) -> Mesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = 2.0 * r
	m.radial_segments = 16
	m.rings = 8
	return m


func _add_mesh(parent_node: Node3D, mesh: Mesh, xf: Transform3D, col: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.transform = xf
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.6
	mi.material_override = mat
	parent_node.add_child(mi)
