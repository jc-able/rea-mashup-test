class_name CameraDirector
extends Node3D
## Match / entrance / finisher cameras (custom). The match camera mimics SvR's default broadcast view:
## elevated, from the hard-camera side, tracking the midpoint and zooming with the distance between superstars.

var camera: Camera3D
var mode := "match"
var m: Match
var _shake := 0.0
var _pos := Vector3(0, 6, 9)
var _look := Vector3(0, 1.5, 0)
var _focus_a: Wrestler
var _focus_b: Wrestler
var _orbit := 0.0
var script_pos := Vector3.ZERO
var script_look := Vector3.ZERO
var script_fov := 50.0
var cam_side := 1.0


func setup(match_: Match) -> void:
	m = match_
	camera = Camera3D.new()
	camera.fov = 50.0
	camera.near = 0.05
	camera.far = 300.0
	add_child(camera)
	camera.current = true
	camera.look_at_from_position(_pos, _look)


func shake(a: float) -> void:
	_shake = maxf(_shake, a)


func focus_pin(a: Wrestler, b: Wrestler) -> void:
	mode = "close"
	_focus_a = a
	_focus_b = b
	_orbit = 0.0


func focus_finisher(a: Wrestler, b: Wrestler) -> void:
	mode = "finisher"
	_focus_a = a
	_focus_b = b
	_orbit = 0.0


func focus_winner(w: Wrestler) -> void:
	mode = "winner"
	_focus_a = w
	_orbit = 0.0


var manual_xf := Transform3D.IDENTITY
var manual_fov := 50.0


## Camera driven frame by frame from recovered SvR camera tracks (entrances).
func set_manual(xf: Transform3D, fov: float) -> void:
	mode = "manual"
	manual_xf = xf
	manual_fov = fov


func set_script_shot(pos: Vector3, look: Vector3, fov := 50.0) -> void:
	mode = "script"
	script_pos = pos
	script_look = look
	script_fov = fov


func _process(dt: float) -> void:
	if camera == null or m == null or m.wrestlers.size() < 2:
		return
	if mode == "manual":
		camera.global_transform = manual_xf
		camera.fov = manual_fov
		_pos = manual_xf.origin
		_look = manual_xf.origin - manual_xf.basis.z * 5.0
		return
	var a: Wrestler = m.wrestlers[0]
	var b: Wrestler = m.wrestlers[1]
	var want_pos := _pos
	var want_look := _look
	var fov := 50.0
	var k := 4.0
	match mode:
		"match":
			var mid := (a.hips() + b.hips()) * 0.5
			var sep := Vector2(a.hips().x - b.hips().x, a.hips().z - b.hips().z).length()
			var dist := clampf(5.2 + sep * 0.9, 5.8, 13.0)
			want_look = Vector3(mid.x * 0.85, mid.y - 0.15, mid.z * 0.85 + 0.35)
			want_pos = want_look + Vector3(0, dist * 0.5, dist * 0.95)
			if a.momentum_state == "finisher" or b.momentum_state == "finisher":
				fov = 47.0
		"close", "finisher":
			_orbit += dt * (0.15 if mode == "close" else 0.35)
			var c := (_focus_a.hips() + _focus_b.hips()) * 0.5
			var ang := 0.6 + _orbit
			want_look = c + Vector3(0, 0.1, 0)
			want_pos = _keep_clear(c + Vector3(sin(ang) * 3.0, 1.9, cos(ang) * 3.0), c)
			fov = 48.0
			k = 3.0
		"winner":
			_orbit += dt * 0.25
			var c2 := _focus_a.hips()
			want_look = c2 + Vector3(0, 0.35, 0)
			want_pos = _keep_clear(c2 + Vector3(sin(_orbit) * 2.8, 1.3, cos(_orbit) * 2.8), c2)
			fov = 46.0
			k = 2.5
		"script":
			want_pos = script_pos
			want_look = script_look
			fov = script_fov
			k = 6.0
		"cut":
			_pos = script_pos
			_look = script_look
			want_pos = script_pos
			want_look = script_look
			fov = script_fov
			mode = "script"
	var s := clampf(k * dt, 0.0, 1.0)
	_pos = _pos.lerp(want_pos, s)
	_look = _look.lerp(want_look, s)
	camera.fov = lerpf(camera.fov, fov, s)
	var sh := Vector3.ZERO
	if _shake > 0.0:
		sh = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake
		_shake = maxf(_shake - dt * 0.6, 0.0)
	camera.look_at_from_position(_pos + sh, _look)


## Keep close cameras out of the ropes: inside the ring a little above the top rope, or well outside the ring.
func _keep_clear(p: Vector3, target: Vector3) -> Vector3:
	var lim := Ring.HALF - 0.35
	if absf(target.x) < Ring.HALF + 0.3 and absf(target.z) < Ring.HALF + 0.3:
		p.x = clampf(p.x, -lim, lim)
		p.z = clampf(p.z, -lim, lim)
		p.y = maxf(p.y, Ring.MAT_Y + float(Ring.ROPE_Y[2]) + 0.35)
	return p
