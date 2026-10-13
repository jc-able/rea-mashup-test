class_name AIBrain
extends RefCounted
## CPU opponent (custom). Produces the same Intent a human produces, with reaction delays and a difficulty level.

var difficulty := 1        # 0 easy, 1 normal, 2 hard
var rng := RandomNumberGenerator.new()
var _think := 0.0
var _plan := ""
var _plan_t := 0.0
var _mash_t := 0.0
var _rev_decided := -1.0
var _rev_press_at := -1.0
var _hold_t := 0.0
var _strike_hold := 0.0
var _last_sub_at := -100.0


func _init(diff: int = 1, seed_: int = 0) -> void:
	difficulty = diff
	if seed_ != 0:
		rng.seed = seed_
	else:
		rng.randomize()


func rev_chance() -> float:
	return [0.12, 0.28, 0.45][difficulty]


func mash_rate() -> float:
	return [5.0, 7.5, 10.0][difficulty]


func update(it: Wrestler.Intent, me: Wrestler, dt: float) -> void:
	var o := me.opp
	it.move = Vector2.ZERO
	it.run = false
	it.strike_held = _strike_hold > 0.0
	_strike_hold -= dt
	if o == null:
		return
	# ---- defensive reactions (reversal windows opened by the opponent's attacks)
	if me.reversal_until > me.now():
		if _rev_decided < 0.0:
			_rev_decided = 1.0 if rng.randf() < rev_chance() else 0.0
			var span := me.reversal_until - me.reversal_open_at
			_rev_press_at = me.reversal_open_at + span * rng.randf_range(0.45, 0.9)
		if _rev_decided > 0.5 and me.now() >= _rev_press_at:
			it.reversal_pressed = true
			_rev_decided = 0.0
	else:
		_rev_decided = -1.0
	# ---- mashing while pinned / held / down / in a submission
	_mash_t -= dt
	var S := Wrestler.S
	if me.state in [S.PIN_V, S.SUB_V, S.HOLD_V, S.DOWN]:
		if _mash_t <= 0.0:
			var rate := mash_rate() * (1.0 - me.total_damage() * 0.55)
			if me.state == S.DOWN:
				rate *= 0.5
			_mash_t = 1.0 / maxf(rate, 0.5)
			it.mash_pressed = true
		return
	if me.state in [S.SUB_A]:
		if _mash_t <= 0.0:
			_mash_t = 1.0 / mash_rate()
			it.mash_pressed = true
		return
	# ---- hold attacker: pick a throw after a beat
	if me.state == S.HOLD_A:
		_hold_t += dt
		if _hold_t > rng.randf_range(0.5, 1.2):
			_hold_t = 0.0
			var r := rng.randf()
			if r < 0.12:
				it.strike_pressed = true
			elif r < 0.2 and me.total_damage() < 0.9:
				it.submission_pressed = true
			else:
				it.grapple_pressed = true
				it.grapple_dir = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)][rng.randi() % 4]
		return
	_hold_t = 0.0
	if me.state == S.TOP:
		if me.state_time > 0.6:
			it.strike_pressed = true
		return
	if me.state == S.WHIP_A or not (me.state in [S.IDLE, S.WALK, S.RUN]):
		return
	# ---- decisions
	_think -= dt
	var d := me.dist_to(o)
	var to_o := o.hips() - me.hips()
	to_o.y = 0
	var dir := Vector2(to_o.x, to_o.z).normalized()
	# leave/enter ring logic first
	if not me.in_ring:
		if o.in_ring or rng.randf() < 0.5:
			# head back to the ring and slide in
			var p := me.hips()
			var target := Vector3(clampf(p.x, -Ring.HALF, Ring.HALF), 0, clampf(p.z, -Ring.HALF, Ring.HALF))
			var v := target - Vector3(p.x, 0, p.z)
			if v.length() > Ring.APRON + 1.0:
				it.move = Vector2(v.x, v.z).normalized()
			else:
				it.action_pressed = true
			return
	if me.in_ring and not o.in_ring:
		# wait in the ring (count-out pressure), taunt sometimes
		if _think <= 0.0:
			_think = rng.randf_range(0.8, 1.6)
			if rng.randf() < 0.35:
				it.taunt_pressed = true
		return
	if _think > 0.0:
		# keep executing the current plan (approach / charge)
		if _plan == "charge":
			it.move = dir
			it.run = true
			if d < 1.7:
				if rng.randf() < 0.5:
					it.strike_pressed = true
				else:
					it.grapple_pressed = true
				_plan = ""
				_think = 0.4
		elif _plan == "approach" and d > 1.15:
			it.move = dir
			it.run = d > 4.5
		return
	_think = rng.randf_range(0.15, 0.4) * [1.6, 1.0, 0.7][difficulty]
	# signature / finisher (SvR: [Y] when the momentum meter is in a Signature or Finisher state)
	if me.momentum_state != "none":
		var chk := me.special_check()
		if chk.has("mid"):
			it.special_pressed = true
			return
		if String(chk.get("needs", "")) == "stand" and o.is_down() and rng.randf() < 0.5:
			it.grapple_pressed = true          # lift the opponent up for a standing special
			it.grapple_dir = Vector2(0, -1)
			return
	if o.state == S.GROGGY and d < 1.5:
		it.grapple_pressed = true
		it.grapple_dir = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)][rng.randi() % 4]
		return
	if o.is_down():
		if d > 1.7:
			_plan = "approach"
			it.move = dir
			return
		var r := rng.randf()
		var pin_p := clampf(o.total_damage() * 1.1 - 0.15, 0.05, 0.85)
		if r < pin_p:
			it.whip_pressed = true
		elif r < pin_p + 0.25:
			it.grapple_pressed = true
			it.grapple_dir = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)][rng.randi() % 4]
		elif r < pin_p + 0.4:
			it.strike_pressed = true
		elif r < pin_p + 0.5 and Ring.corner_distance(me.hips()) < 2.6:
			# head to the corner and go up top (SvR: CLIMBING THE TURNBUCKLE / TOP ROPE DIVE)
			_plan = "climb"
			_think = 2.0
		elif r < pin_p + 0.6:
			it.taunt_pressed = true
		elif me.now() - _last_sub_at < 12.0:
			it.strike_pressed = true           # variety: no new ground submission right after one (stomp instead)
		else:
			it.submission_pressed = true
			_last_sub_at = me.now()
		return
	if _plan == "climb":
		var cn := Ring.nearest_corner(me.hips())
		var v := Vector2(cn.x - me.hips().x, cn.z - me.hips().z)
		if v.length() > 0.7:
			it.move = v.normalized()
			_think = 0.15
			return
		it.action_pressed = true
		_plan = ""
		return
	if o.state == S.WHIPPED and o.whip_legs >= 1:
		if d < 2.4:
			if rng.randf() < 0.55:
				it.grapple_pressed = true
			else:
				it.strike_pressed = true
		return
	if d > 1.3:
		_plan = "approach"
		_think = rng.randf_range(0.2, 0.45)
		it.move = dir
		# charge in from range for a running strike / running grapple (SvR RUNNING slots)
		if d > 2.6 and d < 5.0 and rng.randf() < 0.35 and o.can_be_grabbed():
			_plan = "charge"
			_think = 0.9
		it.run = (d > 4.5 and rng.randf() < 0.5) or _plan == "charge"
		return
	# in range of a standing opponent
	var r2 := rng.randf()
	if o.state in [S.STRIKE] and r2 < 0.3:
		it.move = -dir
		return
	if r2 < 0.38:
		it.strike_pressed = true
		it.strike_held = false
	elif r2 < 0.48:
		it.strike_pressed = true
		it.strike_held = true
		_strike_hold = 0.4
	elif r2 < 0.82:
		it.grapple_pressed = true
		it.grapple_dir = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)][rng.randi() % 4]
	elif r2 < 0.92:
		it.whip_pressed = true
		it.move = Vector2(-dir.y, dir.x) if rng.randf() < 0.5 else dir
	else:
		it.taunt_pressed = d > 1.2
		it.move = -dir
