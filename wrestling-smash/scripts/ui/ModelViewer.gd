## Spinning 3D turntable of one wrestler model (SubViewport with its own world, transparent
## background, arena lighting). Model loads are debounced so fast cursor moves stay smooth.
extends SubViewportContainer

const Roster := preload("res://scripts/ui/Roster.gd")

var spin_speed := 0.75
var wanted := ""
var current := ""
var _wait := 0.0
var _vp: SubViewport
var _pivot: Node3D
var _model: Node3D = null

func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.44, 0.52)
	env.ambient_light_energy = 0.75
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.93, 0.82)
	key.light_energy = 1.25
	key.rotation_degrees = Vector3(-30, 28, 0)
	_vp.add_child(key)
	for l in [[Vector3(-1.6, 2.4, -1.4), Color(0.35, 0.6, 1.0), 3.0], [Vector3(1.6, 2.1, -1.2), Color(1.0, 0.72, 0.3), 2.6], [Vector3(0.0, 1.3, 2.6), Color(1, 1, 1), 0.5]]:
		var o := OmniLight3D.new()
		o.position = l[0]
		o.light_color = l[1]
		o.light_energy = l[2]
		o.omni_range = 6.0
		_vp.add_child(o)
	var cam := Camera3D.new()
	cam.fov = 30.0
	cam.position = Vector3(0, 1.08, 4.7)
	_vp.add_child(cam)
	cam.look_at(Vector3(0, 0.98, 0), Vector3.UP)
	cam.current = true
	_pivot = Node3D.new()
	_vp.add_child(_pivot)

func set_wrestler(slug: String) -> void:
	if slug == wanted:
		return
	wanted = slug
	_wait = 0.0 if (slug == "" or Roster.has_model_cached(slug)) else 0.14

func is_showing(slug: String) -> bool:
	return current == slug and _model != null

func _process(delta: float) -> void:
	if wanted != current:
		_wait -= delta
		if _wait <= 0.0:
			_swap()
	if _pivot:
		_pivot.rotate_y(spin_speed * delta)

func _swap() -> void:
	current = wanted
	if _model != null:
		_model.queue_free()
		_model = null
	if current == "":
		return
	_model = Roster.instantiate_model(current)
	if _model != null:
		_pivot.add_child(_model)
		_pivot.rotation.y = -0.5
