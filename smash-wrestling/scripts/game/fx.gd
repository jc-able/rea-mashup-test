class_name FX
extends RefCounted
## Small visual effects (custom): impact sparks and entrance pyro bursts (CPUParticles3D, gl_compatibility safe).


static func spark(parent: Node3D, pos: Vector3, col: Color, strength: float) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = int(clampf(8 + strength * 1.5, 8, 40))
	p.lifetime = 0.35
	p.explosiveness = 1.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 5.0 + strength * 0.2
	p.gravity = Vector3(0, -6, 0)
	p.scale_amount_min = 0.04
	p.scale_amount_max = 0.09
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 6
	mesh.rings = 3
	p.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 0.95, 0.6).lerp(col, 0.35)
	p.material_override = mat
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	parent.get_tree().create_timer(1.0).timeout.connect(p.queue_free)


static func pyro(parent: Node3D, pos: Vector3, col: Color) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = 60
	p.lifetime = 1.2
	p.explosiveness = 0.9
	p.direction = Vector3(0, 1, 0)
	p.spread = 12.0
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 13.0
	p.gravity = Vector3(0, -9, 0)
	p.scale_amount_min = 0.08
	p.scale_amount_max = 0.16
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 6
	mesh.rings = 3
	p.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col.lightened(0.3)
	p.material_override = mat
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	parent.get_tree().create_timer(2.0).timeout.connect(p.queue_free)
