class_name Match
extends Node3D
## Match director: builds arena + wrestlers, runs entrances, the referee (pinfall 3-count, submissions, rope breaks,
## 10-count count-out), and the result.  Win conditions match SvR 2011's standard one-on-one match; counting
## speeds and meters are custom tuning.

signal match_finished(result: Dictionary)

var arena: Arena
var wrestlers: Array = []
var cam: CameraDirector
var hud: Hud
var human: HumanController
var ais: Array = [null, null]
var entrance: EntranceDirector
var phase := "init"           # entrance / bell / fight / pin / submission / end / results
var phase_t := 0.0
var match_time := 0.0
var pin_pinner: Wrestler
var pin_pinned: Wrestler
var pin_count := 0
var pin_t := 0.0
var sub_a: Wrestler
var sub_v: Wrestler
var sub_meter := 0.0
var countout := 0
var countout_t := 0.0
var result: Dictionary = {}
var log_lines: PackedStringArray = []
var paused := false
var fast := false
var verbose_hits := false
var entrance_only_p1 := false
var rng := RandomNumberGenerator.new()
var sfx: Sfx

const PIN_COUNT_SEC := 0.95
const COUNTOUT_SEC := 1.0


func setup(cfg: Dictionary) -> void:
	rng.randomize()
	arena = Arena.new()
	add_child(arena)
	arena.build()
	sfx = Sfx.new()
	add_child(sfx)
	var roster: Array = Game.roster
	var defs := [Game.def_of(cfg["p1"]), Game.def_of(cfg["p2"])]
	for i in 2:
		var w := Wrestler.new()
		w.name = "Wrestler%d" % (i + 1)
		add_child(w)
		w.match_ref = self
		var cpu := bool(cfg.get("p%d_cpu" % (i + 1), i == 1))
		w.setup(defs[i], i, cpu)
		wrestlers.append(w)
		if cpu and not bool(cfg.get("dummy_p%d" % (i + 1), false)):
			ais[i] = AIBrain.new(int(cfg.get("difficulty", 1)), int(cfg.get("seed", 0)) + i * 17)
	wrestlers[0].opp = wrestlers[1]
	wrestlers[1].opp = wrestlers[0]
	human = HumanController.new()
	cam = CameraDirector.new()
	add_child(cam)
	cam.setup(self)
	hud = Hud.new()
	add_child(hud)
	hud.setup(self)
	entrance = EntranceDirector.new()
	add_child(entrance)
	entrance.setup(self)
	entrance.only_p1 = entrance_only_p1
	_place_for_bell()
	if bool(cfg.get("entrances", true)):
		phase = "entrance"
		entrance.start()
	else:
		_ring_bell()
	_log("match setup: %s vs %s (cpu %s/%s) entrances=%s" % [wrestlers[0].display_name, wrestlers[1].display_name,
		wrestlers[0].is_cpu, wrestlers[1].is_cpu, cfg.get("entrances", true)])


func _place_for_bell() -> void:
	var a: Wrestler = wrestlers[0]
	var b: Wrestler = wrestlers[1]
	var pa := Vector3(-1.6, Ring.MAT_Y, -1.6)
	var pb := Vector3(1.6, Ring.MAT_Y, 1.6)
	a.visible = true
	b.visible = true
	a.teleport(pa, atan2(pb.x - pa.x, pb.z - pa.z))
	b.teleport(pb, atan2(pa.x - pb.x, pa.z - pb.z))


func on_entrances_done() -> void:
	_place_for_bell()
	_ring_bell()


func _ring_bell() -> void:
	phase = "bell"
	phase_t = 0.0
	cam.mode = "match"
	hud.set_visible_match(true)
	announce("FIGHT!", Color(1, 0.85, 0.2), 1.5)
	sfx.bell()
	if not wrestlers[0].is_cpu:
		hud.lower_third("J strike  ·  K grapple (K again to throw)  ·  L whip / pin  ·  I reverse  ·  O signature/finisher  ·  Space climb / exit  ·  hold F1: all controls", Color(0.85, 0.9, 1.0), 21)
		get_tree().create_timer(7.0).timeout.connect(func():
			if is_instance_valid(hud):
				hud.lower_third("", Color.WHITE))
	_log("bell")


func _process(dt: float) -> void:
	if Input.is_action_just_pressed("ui_pause") and phase in ["fight", "pin", "submission", "bell"]:
		_toggle_pause()
	if paused:
		return
	if fast:
		dt *= 1.0
	phase_t += dt
	match phase:
		"entrance":
			entrance.tick(dt)
			for w in wrestlers:
				w.pp.update(dt)
			if Input.is_action_just_pressed("ui_skip") or Input.is_action_just_pressed("ui_pause"):
				entrance.skip()
		"bell":
			for w in wrestlers:
				w.tick(dt)
			if phase_t > 0.8:
				phase = "fight"
		"fight", "pin", "submission":
			match_time += dt
			_drive_controllers(dt)
			for w in wrestlers:
				w.tick(dt)
			_referee(dt)
		"end":
			for w in wrestlers:
				w.tick(dt)
			if phase_t > 4.0:
				phase = "results"
				hud.show_results(result)
				match_finished.emit(result)
				if Game.args.get("quit_on_result", "0") == "1":
					get_tree().create_timer(1.5).timeout.connect(get_tree().quit)
		"results":
			for w in wrestlers:
				w.tick(dt)
	if hud:
		hud.update_hud(dt)


func _drive_controllers(dt: float) -> void:
	for i in 2:
		var w: Wrestler = wrestlers[i]
		if ais[i] != null:
			ais[i].update(w.intent, w, dt)
		elif not w.is_cpu:
			human.update(w.intent, cam.camera)
		# else: scripted dummy (scenario tests set its intent directly)


func _toggle_pause() -> void:
	paused = not paused
	hud.show_pause(paused)


# --------------------------------------------------------------------------------------------- referee
func _referee(dt: float) -> void:
	if phase == "pin":
		_pin_tick(dt)
	elif phase == "submission":
		_sub_tick(dt)
	_countout_tick(dt)


func start_pin(pinner: Wrestler, pinned: Wrestler) -> void:
	phase = "pin"
	phase_t = 0.0
	pin_pinner = pinner
	pin_pinned = pinned
	pin_count = 0
	pin_t = 0.0
	cam.focus_pin(pinner, pinned)
	hud.show_kickout(pinned)
	_log("pin attempt by %s (victim damage %.2f, needed %.1f)" % [pinner.display_name, pinned.total_damage(), pinned.kickout_needed()])


func _pin_tick(dt: float) -> void:
	pin_t += dt
	# rope break: the pinned superstar is under the ropes
	if float(Ring.nearest_rope(pin_pinned.hips())[0]) < 0.25 and pin_t > 0.3:
		announce("ROPE BREAK!", Color(1, 1, 1))
		_end_pin(true, "rope")
		return
	if pin_pinned.kickout_progress >= pin_pinned.kickout_needed():
		_end_pin(true, "kickout")
		return
	if pin_t >= PIN_COUNT_SEC * (pin_count + 1):
		pin_count += 1
		hud.show_count(pin_count)
		sfx.count()
		_log("count %d (kickout %.1f/%.1f)" % [pin_count, pin_pinned.kickout_progress, pin_pinned.kickout_needed()])
		if pin_count >= 3:
			_finish(pin_pinner, "PINFALL")


func _end_pin(kicked: bool, why: String) -> void:
	hud.hide_kickout()
	phase = "fight"
	cam.mode = "match"
	if why == "kickout":
		announce("KICK OUT!", pin_pinned.color)
		_log("kick out at %d" % pin_count)
	pin_pinned.do_kickout()


func start_submission(a: Wrestler, v: Wrestler) -> void:
	phase = "submission"
	phase_t = 0.0
	sub_a = a
	sub_v = v
	sub_meter = 0.35
	hud.show_submission(a, v)
	cam.focus_pin(a, v)
	announce("SUBMISSION!", a.color)
	_log("submission hold by %s" % a.display_name)


func _sub_tick(dt: float) -> void:
	var dmg := sub_v.total_damage()
	sub_meter += dt * (0.05 + 0.18 * dmg)
	sub_meter += sub_a.sub_pressure * 0.022
	sub_meter -= sub_v.sub_escape * 0.03 * (1.15 - dmg * 0.6)
	sub_a.sub_pressure = 0.0
	sub_v.sub_escape = 0.0
	hud.set_submission(sub_meter)
	var rope := float(Ring.nearest_rope(sub_v.hips())[0]) < 0.3
	if sub_meter >= 1.0:
		hud.hide_submission()
		_finish(sub_a, "SUBMISSION")
		return
	if sub_meter <= 0.08 or rope or phase_t > 6.0:
		hud.hide_submission()
		announce("ROPE BREAK!" if rope else "ESCAPED!", sub_v.color)
		phase = "fight"
		cam.mode = "match"
		sub_a.end_submission(true)
		sub_a._go_idle()
		_log("submission escaped")


func _countout_tick(dt: float) -> void:
	var outside := []
	for w in wrestlers:
		if not w.in_ring:
			outside.append(w)
	if outside.is_empty():
		if countout > 0:
			hud.show_countout(0)
		countout = 0
		countout_t = 0.0
		return
	countout_t += dt
	if countout_t >= COUNTOUT_SEC:
		countout_t = 0.0
		countout += 1
		hud.show_countout(countout)
		sfx.count()
		if countout >= 10:
			if outside.size() == 2:
				_finish(null, "DOUBLE COUNT-OUT")
			else:
				var loser: Wrestler = outside[0]
				_finish(loser.opp, "COUNT-OUT")


func _finish(winner: Wrestler, method: String) -> void:
	if phase in ["end", "results"]:
		return
	phase = "end"
	phase_t = 0.0
	sfx.bell()
	result = {"method": method, "winner": winner.display_name if winner else "", "winner_kind": winner.kind if winner else "",
		"loser": winner.opp.display_name if winner else "", "time": match_time,
		"stats": [wrestlers[0].stats, wrestlers[1].stats],
		"damage": [wrestlers[0].total_damage(), wrestlers[1].total_damage()]}
	_log("MATCH END: %s by %s at %.1fs" % [result["winner"], method, match_time])
	announce(("%s WINS BY %s!" % [winner.display_name.to_upper(), method]) if winner else method, winner.color if winner else Color.WHITE, 4.0)
	hud.hide_kickout()
	if winner:
		cam.focus_winner(winner)
		var loser := winner.opp
		if loser.state == Wrestler.S.PIN_V or loser.state == Wrestler.S.SUB_V:
			loser.set_defeated()
		else:
			loser.set_defeated()
		winner.pp.speed = 1.0
		winner._go_idle(0.4)
		winner.set_victory()
	Game.last_result = result
	_write_log()


# --------------------------------------------------------------------------------------------- feedback
func announce(text: String, col: Color = Color.WHITE, dur := 1.8) -> void:
	if hud:
		hud.announce(text, col, dur)


func show_reversal_prompt(w: Wrestler, window: float) -> void:
	if hud:
		hud.reversal_prompt(window)


func on_impact(attacker: Wrestler, victim: Wrestler, dmg: float) -> void:
	_log("hit %s -> %s dmg %.1f (victim dmg %.2f, momentum %d/%d)" % [attacker.display_name, victim.display_name, dmg,
		victim.total_damage(), int(wrestlers[0].momentum), int(wrestlers[1].momentum)])
	cam.shake(0.05 + dmg * 0.006)
	sfx.hit(dmg)
	hud.flash_damage(victim)
	FX.spark(self, victim.hips() + Vector3(0, 0.3, 0), attacker.color, dmg)


func on_move_start(a: Wrestler, v: Wrestler, m: Dictionary) -> void:
	_log("%s -> %s : %s" % [a.display_name, v.display_name, m.get("name", "?")])
	hud.move_name(a, String(m.get("name", "")))
	if bool(a.get_meta("finisher", false)):
		cam.focus_finisher(a, v)


func on_ring_change(w: Wrestler) -> void:
	_log("%s %s the ring" % [w.display_name, "entered" if w.in_ring else "left"])


func on_taunt(w: Wrestler) -> void:
	sfx.crowd_pop()
	_log("%s taunts" % w.display_name)


func _log(s: String) -> void:
	var line := "[%7.2f] %s" % [match_time, s]
	log_lines.append(line)
	if Game.verbose:
		print(line)


func _write_log() -> void:
	var dir := Game.log_dir()
	if dir == "":
		return
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir + "/match_%s.log" % Time.get_datetime_string_from_system().replace(":", "-"), FileAccess.WRITE)
	if f:
		for l in log_lines:
			f.store_line(l)
		f.close()
