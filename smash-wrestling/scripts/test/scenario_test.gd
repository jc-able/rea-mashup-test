extends Node
## Gameplay scenario tests: each scenario builds a real Match (SvR arena, Smash models, real input actions for P1,
## a scripted dummy P2), drives it with InputEventActions and checks the resulting states.
## usage: Godot --path game --resolution 1280x720 -- test=scenario_test out=/abs/dir [only=name,name] [p1=mario p2=donkey]
## Written in this run.

var out_dir := "user://scenario_test"
var results: Array = []
var m: Match
var p1: Wrestler
var p2: Wrestler
var only := []
var S := Wrestler.S


func _ready() -> void:
	out_dir = Game.args.get("out", out_dir)
	if Game.args.has("only"):
		only = Array(String(Game.args["only"]).split(","))
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()


# ------------------------------------------------------------------------------------------ helpers
func _new_match() -> void:
	if m and is_instance_valid(m):
		m.queue_free()
		await get_tree().process_frame
	m = Match.new()
	add_child(m)
	m.setup({"p1": Game.args.get("p1", "mario"), "p2": Game.args.get("p2", "donkey"), "p1_cpu": false,
		"p2_cpu": true, "dummy_p2": true, "entrances": false, "difficulty": 1, "seed": 3})
	p1 = m.wrestlers[0]
	p2 = m.wrestlers[1]
	await _wait(1.0)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _act(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)


func _tap(action: String, hold := 0.08) -> void:
	_act(action, true)
	await _wait(hold)
	_act(action, false)
	await get_tree().process_frame


func _place(w: Wrestler, pos: Vector3, face_to: Vector3) -> void:
	var d := face_to - pos
	w.teleport(pos, atan2(d.x, d.z))


func _down(w: Wrestler, up := true, extra := 30.0) -> void:
	w._enter_down(up, extra)
	w.down_timer = extra


func _until(cond: Callable, timeout: float) -> bool:
	var t := 0.0
	while t < timeout:
		if cond.call():
			return true
		await get_tree().process_frame
		t += get_process_delta_time()
	return false


func _shot(tag: String) -> void:
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, tag])


func _rec(name: String, ok: bool, detail: String) -> void:
	results.append({"scenario": name, "pass": ok, "detail": detail})
	print("%s %s: %s" % ["PASS" if ok else "FAIL", name, detail])


func _want(name: String) -> bool:
	return only.is_empty() or name in only


# ------------------------------------------------------------------------------------------ scenarios
func _run() -> void:
	var c := Vector3(0, 0, 0)
	if _want("strike_combo"):
		await _new_match()
		_place(p1, Vector3(-0.55, 0, 0), Vector3(1, 0, 0))
		_place(p2, Vector3(0.55, 0, 0), Vector3(-1, 0, 0))
		var d0: float = p2.total_damage()
		for i in 3:
			await _tap("p1_strike")
			await _wait(0.32)
		await _wait(1.2)
		await _shot("strike_combo")
		_rec("strike_combo", p2.total_damage() > d0, "P2 damage %.3f -> %.3f, P1 strikes %d, P2 state %s" % [d0, p2.total_damage(), p1.stats["strikes"], p2.state_name()])
	if _want("grapple_throw"):
		await _new_match()
		_place(p1, Vector3(-0.5, 0, 0), Vector3(1, 0, 0))
		_place(p2, Vector3(0.5, 0, 0), Vector3(-1, 0, 0))
		_act("p1_up", true)
		await _tap("p1_grapple")
		_act("p1_up", false)
		var held := await _until(func(): return p1.state == S.HOLD_A, 3.0)
		await _shot("grapple_hold")
		_act("p1_left", true)
		await _tap("p1_grapple")
		_act("p1_left", false)
		var moving := await _until(func(): return p1.state == S.MOVE_A, 1.0)
		var mv_name: String = String(MotionDB.move(p1.cur_move).get("name", "?"))
		await _wait(0.6)
		await _shot("grapple_throw_mid")
		var landed := await _until(func(): return p2.state in [S.DOWN, S.GROGGY, S.IDLE] and p1.state != S.MOVE_A, 10.0)
		await _shot("grapple_throw_end")
		_rec("grapple_throw", held and moving and landed, "hold=%s throw=%s (%s) victim end=%s dmg %.2f" % [held, moving, mv_name, p2.state_name(), p2.total_damage()])
	if _want("pin_3count"):
		await _new_match()
		_place(p2, Vector3(0.5, 0, 0), Vector3(-1, 0, 0))
		_down(p2, true)
		await _wait(0.6)
		_place(p1, p2.hips() + Vector3(-0.9, 0, 0.2), p2.hips())
		await _wait(0.3)
		await _tap("p1_whip")
		var pinning := await _until(func(): return p1.state == S.PIN_A, 2.0)
		await _wait(0.5)
		await _shot("pin_cover")
		var won := await _until(func(): return m.phase in ["end", "results"], 6.0)
		await _wait(1.5)
		await _shot("pin_result")
		_rec("pin_3count", pinning and won and String(m.result.get("method", "")) == "PINFALL", "cover=%s ended=%s result=%s" % [pinning, won, m.result])
	if _want("kickout"):
		await _new_match()
		_place(p1, Vector3(0.0, 0, 0), Vector3(1, 0, 0))
		_down(p1, true)
		await _wait(0.5)
		_place(p2, p1.hips() + Vector3(0.9, 0, 0.1), p1.hips())
		await _wait(0.3)
		p2.intent.whip_pressed = true
		var pinned := await _until(func(): return p1.state == S.PIN_V, 2.0)
		for i in 30:
			await _tap("p1_strike", 0.03)
			await _wait(0.05)
			if p1.state != S.PIN_V:
				break
		var kicked := await _until(func(): return p1.stats["kickouts"] > 0, 3.0)
		await _shot("kickout")
		_rec("kickout", pinned and kicked and m.phase != "end", "pinned=%s kicked=%s phase=%s count=%d" % [pinned, kicked, m.phase, m.pin_count])
	if _want("irish_whip_rebound"):
		await _new_match()
		_place(p1, Vector3(0.0, 0, 0), Vector3(1, 0, 0))
		_place(p2, Vector3(0.9, 0, 0), Vector3(-1, 0, 0))
		await _tap("p1_whip")
		var tr := []
		var tracer := func():
			tr.append("%s legs=%d d=%.2f x=%.2f" % [p2.state_name(), p2.whip_legs, p1.dist_to(p2), p2.hips().x])
			return false
		var whipped := await _until(func(): return p2.state == S.WHIPPED, 1.5)
		await _until(tracer, 1.2)
		print("WHIP TRACE: ", " | ".join(tr.slice(0, 80, 4)))
		var coming := await _until(func(): return p2.state == S.WHIPPED and p2.whip_legs >= 1 and p1.dist_to(p2) < 2.2, 6.0)
		await _tap("p1_strike")
		var tr2 := []
		var hit := await _until(func():
			tr2.append("%s/%s d=%.2f f=%d" % [p1.state_name(), p2.state_name(), p1.dist_to(p2), p1.pp.frame()])
			return p2.state in [S.KNOCKDOWN, S.DOWN, S.HIT, S.MOVE_V], 2.0)
		if not hit:
			print("REBOUND TRACE: ", " | ".join(tr2.slice(0, 60, 3)))
		await _wait(0.4)
		await _shot("irish_whip_rebound")
		_rec("irish_whip_rebound", whipped and coming and hit, "whipped=%s rebounded=%s rebound attack landed=%s (P2 %s)" % [whipped, coming, hit, p2.state_name()])
	if _want("turnbuckle_dive"):
		await _new_match()
		var cn := Ring.corners()[0] as Vector3
		_place(p1, cn * 0.86, Vector3.ZERO)
		_place(p2, Vector3(cn.x * 0.35, 0, cn.z * 0.35), Vector3.ZERO)
		_down(p2, true)
		await _wait(0.3)
		await _tap("p1_action")
		var climbing := await _until(func(): return p1.state == S.CLIMB, 1.0)
		var top := await _until(func(): return p1.state == S.TOP, 6.0)
		await _shot("turnbuckle_top")
		var d0: float = p2.total_damage()
		await _tap("p1_strike")
		var dove := await _until(func(): return p1.state == S.DIVE, 1.0)
		await _until(func(): return p1.state != S.DIVE, 6.0)
		await _shot("turnbuckle_dive_end")
		_rec("turnbuckle_dive", climbing and top and dove, "climb=%s top=%s dive=%s P2 dmg %.3f->%.3f" % [climbing, top, dove, d0, p2.total_damage()])
	if _want("ring_exit_reentry"):
		await _new_match()
		_place(p1, Vector3(0, 0, Ring.HALF - 0.45), Vector3(0, 0, 10))
		_place(p2, Vector3(0, 0, -1.5), Vector3(0, 0, 1))
		await _tap("p1_action")
		var exiting := await _until(func(): return p1.state == S.EXIT_RING, 1.0)
		var outside := await _until(func(): return not p1.in_ring and p1.state == S.IDLE, 6.0)
		await _shot("ring_outside")
		await _wait(2.5)
		var counted: int = m.countout
		await _tap("p1_action")
		var entering := await _until(func(): return p1.state == S.ENTER_RING, 1.0)
		var back := await _until(func(): return p1.in_ring and p1.state == S.IDLE, 6.0)
		await _shot("ring_reentry")
		_rec("ring_exit_reentry", exiting and outside and counted >= 2 and entering and back, "exit=%s outside=%s countout=%d enter=%s back_in=%s" % [exiting, outside, counted, entering, back])
	if _want("taunt_momentum"):
		await _new_match()
		_place(p1, Vector3(-1.5, 0, 0), Vector3(1, 0, 0))
		_place(p2, Vector3(1.5, 0, 0), Vector3(-1, 0, 0))
		var m0: float = p1.momentum
		await _tap("p1_taunt")
		var taunting := await _until(func(): return p1.state == S.TAUNT, 1.0)
		await _wait(0.7)
		await _shot("taunt")
		await _until(func(): return p1.state != S.TAUNT, 5.0)
		_rec("taunt_momentum", taunting and p1.momentum > m0, "taunt=%s smash_anim=%s momentum %.0f -> %.0f" % [taunting, p1.smash != null, m0, p1.momentum])
	if _want("signature_finisher"):
		await _new_match()
		p1.add_momentum(100.0)
		var sig_ready: bool = p1.momentum_state == "signature"
		var sig_id := MotionDB.slot(p1.kind, "special", "signature_1")
		var sig_down: bool = String(MotionDB.move(sig_id).get("victim_start", "stand")) != "stand"
		_place(p1, Vector3(-0.5, 0, 0), Vector3(1, 0, 0))
		_place(p2, Vector3(0.6, 0, 0), Vector3(-1, 0, 0))
		if sig_down:
			_down(p2, true)
			await _wait(0.4)
			_place(p1, p2.hips() + Vector3(-1.0, 0, 0), p2.hips())
		await _wait(0.3)
		await _tap("p1_special")
		var sig := await _until(func(): return p1.state == S.MOVE_A, 1.0)
		var sig_name: String = String(MotionDB.move(p1.cur_move).get("name", "?"))
		await _wait(0.8)
		await _shot("signature")
		await _until(func(): return p1.state != S.MOVE_A, 25.0)
		var fin_ready: bool = p1.momentum_state == "finisher"
		var fin_id := MotionDB.slot(p1.kind, "special", "finisher_1")
		var fin_down: bool = String(MotionDB.move(fin_id).get("victim_start", "stand")) != "stand"
		_place(p2, Vector3(0.6, 0, 0), Vector3(-1, 0, 0))
		if fin_down:
			_down(p2, true)
			await _wait(0.4)
		_place(p1, p2.hips() + Vector3(-1.0, 0, 0), p2.hips())
		await _wait(0.3)
		await _tap("p1_special")
		var fin := await _until(func(): return p1.state in [S.MOVE_A, S.STRIKE], 1.0)
		var fin_name: String = String(MotionDB.move(p1.cur_move).get("name", "?"))
		await _wait(1.0)
		await _shot("finisher")
		await _until(func(): return not (p1.state in [S.MOVE_A, S.STRIKE]), 25.0)
		fin = fin and p2.is_down()
		_rec("signature_finisher", sig_ready and sig and fin_ready and fin, "signature ready=%s done=%s (%s) -> finisher ready=%s done=%s (%s), momentum now %.0f" % [sig_ready, sig, sig_name, fin_ready, fin, fin_name, p1.momentum])
	if _want("submission_win"):
		await _new_match()
		_place(p2, Vector3(0.5, 0, 0), Vector3(-1, 0, 0))
		_down(p2, true)
		p2.add_damage("legs", 60.0)
		p2.add_damage("body", 60.0)
		await _wait(0.4)
		_place(p1, p2.hips() + Vector3(-0.9, 0, 0), p2.hips())
		await _wait(0.3)
		await _tap("p1_submission")
		var sub := await _until(func(): return p1.state == S.SUB_A, 6.0)
		await _shot("submission_hold")
		for i in 60:
			await _tap("p1_strike", 0.03)
			await _wait(0.05)
			if m.phase in ["end", "results"]:
				break
		var won := await _until(func(): return m.phase in ["end", "results"], 4.0)
		_rec("submission_win", sub and won and String(m.result.get("method", "")) == "SUBMISSION", "hold=%s ended=%s result=%s" % [sub, won, m.result.get("method", "")])
	if _want("reversal_block"):
		await _new_match()
		_place(p1, Vector3(-0.5, 0, 0), Vector3(1, 0, 0))
		_place(p2, Vector3(0.5, 0, 0), Vector3(-1, 0, 0))
		await _wait(0.3)
		p2.intent.strike_pressed = true
		p2.intent.strike_held = false
		var opened := await _until(func(): return p1.reversal_until > p1.now(), 1.0)
		# press in the valid (late) part of the window: 60% of the way from opening to impact
		await _until(func(): return p1.now() >= p1.reversal_open_at + (p1.reversal_until - p1.reversal_open_at) * 0.6, 1.0)
		await _tap("p1_reversal", 0.05)
		var blocked := await _until(func(): return p1.state == S.BLOCK_A, 1.0)
		await _shot("reversal_block")
		_rec("reversal_block", opened and blocked, "window opened=%s blocked=%s (P1 %s, P2 %s)" % [opened, blocked, p1.state_name(), p2.state_name()])
	if _want("countout_win"):
		await _new_match()
		_place(p1, Vector3(0, 0, 0), Vector3(1, 0, 0))
		_place(p2, Vector3(0, 0, Ring.HALF + Ring.APRON + 1.2), Vector3(0, 0, 10))
		var won := await _until(func(): return m.phase in ["end", "results"], 13.0)
		await _wait(1.0)
		await _shot("countout")
		_rec("countout_win", won and String(m.result.get("method", "")) == "COUNT-OUT" and String(m.result.get("winner", "")) == p1.display_name, "result=%s" % [m.result])
	# summary
	var f := FileAccess.open(out_dir + "/scenario_results.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"p1": Game.args.get("p1", "mario"), "p2": Game.args.get("p2", "donkey"), "results": results}, " "))
	f.close()
	var passed := 0
	for r in results:
		if r["pass"]:
			passed += 1
	print("SCENARIOS: %d/%d passed" % [passed, results.size()])
	get_tree().quit()
