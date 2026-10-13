class_name HumanController
extends RefCounted
## Keyboard / gamepad -> Wrestler.Intent (movement is camera-relative, grapple directions are raw stick directions
## like SvR's right-stick grapples).

var _prev_rs := Vector2.ZERO


func update(it: Wrestler.Intent, cam: Camera3D) -> void:
	var mv := Vector2(Input.get_action_strength("p1_right") - Input.get_action_strength("p1_left"),
		Input.get_action_strength("p1_down") - Input.get_action_strength("p1_up"))
	if mv.length() > 1.0:
		mv = mv.normalized()
	var world := Vector2.ZERO
	if cam and mv.length() > 0.05:
		var f := -cam.global_transform.basis.z
		f.y = 0
		f = f.normalized()
		var r := cam.global_transform.basis.x
		r.y = 0
		r = r.normalized()
		var w := r * mv.x - f * mv.y
		world = Vector2(w.x, w.z)
	it.move = world
	it.run = Input.is_action_pressed("p1_run")
	it.strike_pressed = Input.is_action_just_pressed("p1_strike")
	it.strike_held = Input.is_action_pressed("p1_strike")
	it.strike_released = Input.is_action_just_released("p1_strike")
	it.whip_pressed = Input.is_action_just_pressed("p1_whip")
	it.action_pressed = Input.is_action_just_pressed("p1_action")
	it.reversal_pressed = Input.is_action_just_pressed("p1_reversal")
	it.special_pressed = Input.is_action_just_pressed("p1_special")
	it.taunt_pressed = Input.is_action_just_pressed("p1_taunt")
	it.change_pressed = Input.is_action_just_pressed("p1_change")
	it.submission_pressed = Input.is_action_just_pressed("p1_submission")
	# grapple: keyboard K + direction keys, or a right-stick flick
	var rs := Controls.right_stick()
	var flick := rs.length() > 0.0 and _prev_rs.length() == 0.0
	_prev_rs = rs
	if Input.is_action_just_pressed("p1_grapple"):
		it.grapple_pressed = true
		it.grapple_dir = mv
	elif flick:
		it.grapple_pressed = true
		it.grapple_dir = rs
	it.mash_pressed = it.strike_pressed or it.whip_pressed or it.action_pressed or it.special_pressed \
		or Input.is_action_just_pressed("p1_grapple")
