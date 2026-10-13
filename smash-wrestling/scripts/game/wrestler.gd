class_name Wrestler
extends Node3D
## One competitor: Smash 64 model driven by retargeted SvR 2011 motions, plus the match state machine.
## Rules/flow follow SvR 2011's own control help (strings 30000-30448) and momentum texts (24767, 24847, 24926-24941);
## numbers (speeds, damage, windows) are custom tuning.  Written in this run.

class Intent:
	var move := Vector2.ZERO       # world XZ direction, length 0..1
	var run := false
	var strike_pressed := false
	var strike_held := false
	var strike_released := false
	var grapple_pressed := false
	var grapple_dir := Vector2.ZERO  # raw stick direction: (0,-1) = up
	var whip_pressed := false
	var action_pressed := false
	var reversal_pressed := false
	var special_pressed := false
	var taunt_pressed := false
	var change_pressed := false
	var submission_pressed := false
	var mash_pressed := false

	func clear_edges() -> void:
		strike_pressed = false
		strike_released = false
		grapple_pressed = false
		whip_pressed = false
		action_pressed = false
		reversal_pressed = false
		special_pressed = false
		taunt_pressed = false
		change_pressed = false
		submission_pressed = false
		mash_pressed = false

enum S { IDLE, WALK, RUN, RUN_STOP, STRIKE, HIT, KNOCKDOWN, DOWN, GETUP, GROGGY,
	LOCK_A, LOCK_V, HOLD_A, HOLD_V, MOVE_A, MOVE_V, WHIP_A, WHIPPED, REBOUND,
	PIN_A, PIN_V, KICKOUT_A, KICKOUT_V, SUB_A, SUB_V, CLIMB, TOP, DIVE, STEP_DOWN,
	EXIT_RING, ENTER_RING, TAUNT, BLOCK_A, BLOCK_V, SCRIPTED, VICTORY, DEFEATED }

const WALK_SPEED := 1.55
const RUN_SPEED := 4.6
const WHIP_SPEED := 5.0
const TURN_RATE := 9.0
const REACH := 1.25
const GRAB_RANGE := 1.6
const DOWN_RANGE := 2.0

var idx := 0
var kind := "mario"
var display_name := "Mario"
var color := Color.WHITE
var is_cpu := false
var opp: Wrestler
var match_ref: Node              # Match
var model: CharacterModel
var rig: RetargetRig
var pp: PosePlayer
var smash: SmashAnimPlayer        # the fighter's own Smash 64 animations (taunt, victory, dizzy, entry)
var smash_mode := false
var intent := Intent.new()

var state: int = S.IDLE
var state_time := 0.0
var in_ring := true
var floor_level := 0.0
var face_up := true              # when down
var down_timer := 0.0
var damage := {"head": 0.0, "body": 0.0, "arms": 0.0, "legs": 0.0}
var momentum := 0.0
var momentum_state := "none"      # none / signature / finisher (SvR 2011 strings 24926-24941)
var momentum_full_time := 0.0
var reversal_until := -1.0         # game time until which a reversal press counts
var reversal_open_at := -1.0
var reversal_kind := ""
var reversal_armed := ""           # kind armed by a well-timed press
var reversal_armed_until := -1.0
var reversal_lock_until := -1.0
var _t := 0.0

# current action bookkeeping
var cur_move := -1
var cur_impacts: Array = []
var impact_done := {}
var combo_step := 0
var combo_buffer := false
var strike_hold_t := 0.0
var _charging := false
var _charge_t := 0.0
var hold_type := ""
var hold_time := 0.0
var whip_dir := Vector3.ZERO
var whip_legs := 0
var pin_count := 0
var kickout_progress := 0.0
var sub_escape := 0.0
var sub_pressure := 0.0
var move_role := 0
var pending_after := ""            # state hint after a paired move ("down", "groggy", "stand")
var victory_clip := ""
var stats := {"strikes": 0, "moves": 0, "reversals": 0, "kickouts": 0}
var last_event := ""


# ------------------------------------------------------------------------------------------- setup
func setup(def: Dictionary, index: int, cpu: bool) -> void:
	idx = index
	kind = def["kind"]
	display_name = def["name"]
	color = Color(def.get("color", "#ffffff"))
	is_cpu = cpu
	model = CharacterModel.create(kind, float(def.get("height_m", 1.75)), color)
	add_child(model.root)
	rig = RetargetRig.new()
	rig.setup(model.skeleton, model.spec)
	pp = PosePlayer.new()
	pp.setup(rig, self)
	size_k = model.height_world / REF_HEIGHT
	hip_k = model.hip_height_world / 0.9158
	if not model.own_anims.is_empty():
		smash = SmashAnimPlayer.new()
		smash.setup(model.skeleton, model.own_anims)
	_play(MotionDB.role("idle"), {"loop": true, "blend": 0.0})
	pp.update(0.0)


const REF_HEIGHT := 1.85   # SvR reference superstar height in motion metres (john_cena 1.90 m * 0.9736)
var size_k := 1.0          # this character's size relative to an SvR superstar (horizontal motion scale)
var hip_k := 1.0           # hip-height ratio (vertical scale above the support)


func scale_k() -> float:
	return size_k


## pair scale shared by both participants of a two-actor clip (custom compromise so contact holds)
func pair_k(o: Wrestler) -> float:
	return (size_k + o.size_k) * 0.5


func pair_xf(o: Wrestler, xf: Transform3D) -> Transform3D:
	var t := xf
	t.origin *= pair_k(o)
	return t


# ------------------------------------------------------------------------------------------- helpers
func now() -> float:
	return _t


func _play(c: SwmClip, opts: Dictionary = {}) -> void:
	if c == null:
		push_warning("%s: missing clip" % display_name)
		return
	if not opts.has("floor_y"):
		opts["floor_y"] = floor_level
	if smash_mode:
		smash_mode = false
		rig.begin_local_blend(float(opts.get("blend", 0.2)) + 0.05)
	var partner = opts.get("pair", null)
	if partner is Wrestler:
		pp.kh = pair_k(partner)
		pp.kv = hip_k
		pp.ks = (hip_k + partner.hip_k) * 0.5
	else:
		pp.kh = size_k
		pp.kv = hip_k
		pp.ks = 1.0
	# explicit overrides (entrance clips in arena space: world-true path, support-relative height)
	if opts.has("kh"):
		pp.kh = float(opts["kh"])
	if opts.has("kv"):
		pp.kv = float(opts["kv"])
	if opts.has("ks"):
		pp.ks = float(opts["ks"])
	pp.play(c, opts)


func _role(r: String, opts: Dictionary = {}) -> void:
	_play(MotionDB.role(r), opts)


## Play one of the fighter's own Smash 64 animations (returns false when the fighter has none by that name).
func play_smash(name: String, opts: Dictionary = {}) -> bool:
	if smash == null or not smash.has(name):
		return false
	smash.play(name, opts)
	smash_mode = true
	return true


func hips() -> Vector3:
	return pp.cur_hips


func ground_pos() -> Vector3:
	return Vector3(pp.cur_hips.x, floor_level, pp.cur_hips.z)


func forward() -> Vector3:
	return global_transform.basis.z.normalized()


func yaw() -> float:
	var f := forward()
	return atan2(f.x, f.z)


func dist_to(o: Wrestler) -> float:
	var a := hips()
	var b := o.hips()
	return Vector2(a.x - b.x, a.z - b.z).length()


func dir_to(o: Wrestler) -> Vector3:
	var d := o.hips() - hips()
	d.y = 0
	return d.normalized() if d.length() > 0.001 else forward()


## angle of o relative to my facing (0 = straight ahead)
func angle_to(o: Wrestler) -> float:
	var d := dir_to(o)
	var f := forward()
	return absf(atan2(f.cross(d).y, f.dot(d)))


func is_down() -> bool:
	return state in [S.DOWN, S.PIN_V, S.KICKOUT_V] or (state == S.KNOCKDOWN and pp.progress() > 0.85)


func is_free_standing() -> bool:
	return state in [S.IDLE, S.WALK, S.RUN, S.RUN_STOP, S.TAUNT, S.STRIKE, S.GROGGY, S.HIT, S.WHIPPED]


func can_be_grabbed() -> bool:
	return state in [S.IDLE, S.WALK, S.TAUNT, S.GROGGY, S.RUN_STOP] or (state == S.HIT and pp.progress() > 0.5)


func busy_locked() -> bool:
	return state in [S.LOCK_A, S.LOCK_V, S.HOLD_A, S.HOLD_V, S.MOVE_A, S.MOVE_V, S.PIN_A, S.PIN_V,
		S.SUB_A, S.SUB_V, S.BLOCK_A, S.BLOCK_V, S.KICKOUT_A, S.KICKOUT_V, S.SCRIPTED]


## Overall wear (custom): the worst body part dominates, the others add (per-part damage as in SvR's indicator).
func total_damage() -> float:
	var h: float = damage["head"]
	var b: float = damage["body"]
	var a: float = damage["arms"]
	var l: float = damage["legs"]
	var avg := (h * 1.2 + b + a * 0.6 + l * 0.8) / 3.6
	var worst := maxf(maxf(h, b), maxf(a, l))
	return clampf(worst * 0.55 + avg * 0.45, 0.0, 1.0)


const DMG_MULT := 1.1   # custom pacing: a typical match lasts roughly 3-5 minutes


func add_damage(region: String, amt: float) -> void:
	damage[region] = clampf(damage[region] + amt * DMG_MULT * Game.dmg_scale / 100.0, 0.0, 1.0)


func add_momentum(v: float) -> void:
	if momentum_state == "finisher" and v > 0:
		return
	momentum = clampf(momentum + v, 0.0, 100.0)
	if momentum >= 100.0 and momentum_state == "none":
		momentum_state = "signature"
		momentum_full_time = now()
		if match_ref:
			match_ref.announce("%s: SIGNATURE READY  (O / Y)" % display_name, color)


func face_towards(p: Vector3, instant := false, dt := 0.016) -> void:
	var d := p - global_position
	d.y = 0
	if d.length() < 0.01:
		return
	var target := atan2(d.x, d.z)
	var cur := yaw()
	var ny := target if instant else lerp_angle(cur, target, clampf(TURN_RATE * dt, 0, 1))
	global_transform = Transform3D(Basis(Vector3.UP, ny), global_position)


func set_state(s: int) -> void:
	state = s
	state_time = 0.0


func _anchor_here(face_yaw := INF) -> Transform3D:
	var y := yaw() if face_yaw == INF else face_yaw
	return Transform3D(Basis(Vector3.UP, y), Vector3(hips().x, floor_level, hips().z))


func _ensure_floor() -> void:
	floor_level = Ring.MAT_Y if in_ring else 0.0


## SvR 2011: [RT] reverses grapples, blocks punches, catches kicks (strings 30380-30425). Timing (custom): the
## window runs from the attack start to just past the impact; presses in its first 35% whiff and lock out 0.45 s.
func open_reversal(kind_: String, window: float) -> void:
	reversal_open_at = now()
	reversal_until = now() + window + 0.06
	reversal_kind = kind_
	reversal_armed = ""
	if match_ref and not is_cpu:
		match_ref.show_reversal_prompt(self, window)


func _reversal_press() -> void:
	if now() < reversal_lock_until:
		return
	if reversal_kind != "" and reversal_until > now():
		var span := reversal_until - reversal_open_at
		if now() >= reversal_open_at + span * 0.35:
			reversal_armed = reversal_kind
			reversal_armed_until = reversal_until + 0.15
			return
	reversal_lock_until = now() + 0.45


func reversal_ok() -> bool:
	return reversal_armed != "" and reversal_armed_until > now()


func consume_reversal() -> void:
	reversal_armed = ""
	reversal_kind = ""
	reversal_until = -1.0


# ------------------------------------------------------------------------------------------- main loop
func tick(dt: float) -> void:
	_t += dt
	state_time += dt
	if intent.reversal_pressed:
		_reversal_press()
	_momentum_decay(dt)
	match state:
		S.IDLE, S.WALK:
			_st_locomotion(dt)
		S.RUN:
			_st_run(dt)
		S.RUN_STOP:
			_st_oneshot_then_idle(dt, true)
		S.STRIKE:
			_st_strike(dt)
		S.HIT:
			_st_oneshot_then_idle(dt, false)
		S.KNOCKDOWN:
			_st_knockdown(dt)
		S.DOWN:
			_st_down(dt)
		S.GETUP:
			_st_oneshot_then_idle(dt, false)
		S.GROGGY:
			_st_groggy(dt)
		S.LOCK_A:
			_st_lock_a(dt)
		S.HOLD_A:
			_st_hold_a(dt)
		S.HOLD_V:
			_st_hold_v(dt)
		S.MOVE_A:
			_st_move_a(dt)
		S.MOVE_V:
			_st_move_v(dt)
		S.WHIP_A:
			_st_whip_a(dt)
		S.WHIPPED:
			_st_whipped(dt)
		S.REBOUND:
			_st_rebound(dt)
		S.PIN_A:
			_st_pin_a(dt)
		S.PIN_V:
			_st_pin_v(dt)
		S.KICKOUT_A, S.KICKOUT_V:
			_st_kickout(dt)
		S.SUB_A:
			_st_sub_a(dt)
		S.SUB_V:
			_st_sub_v(dt)
		S.CLIMB:
			_st_climb(dt)
		S.TOP:
			_st_top(dt)
		S.DIVE:
			_st_dive(dt)
		S.STEP_DOWN:
			_st_oneshot_then_idle(dt, false)
		S.EXIT_RING:
			_st_exit(dt)
		S.ENTER_RING:
			_st_enter(dt)
		S.TAUNT:
			_st_taunt(dt)
		S.BLOCK_A, S.BLOCK_V:
			_st_block(dt)
		S.VICTORY, S.DEFEATED, S.SCRIPTED, S.LOCK_V, S.MOVE_V:
			pass
	if smash_mode:
		smash.update(dt)
		rig.tick_blend(dt)
	else:
		rig.tick_blend(dt)
		pp.update(dt)
	intent.clear_edges()


func _momentum_decay(dt: float) -> void:
	# "After a certain amount of time, the gauge decreases." (string 24941) - 25 s grace then decay (custom timing)
	if momentum_state != "none" and now() - momentum_full_time > 25.0:
		momentum = maxf(momentum - 6.0 * dt, 0.0)
		if momentum < 70.0:
			momentum_state = "none"


# ------------------------------------------------------------------------------------------- locomotion
var _loco_clip := ""


func _go_idle(blend := 0.2) -> void:
	_ensure_floor()
	set_state(S.IDLE)
	_loco_clip = "idle"
	_role("idle_hunched" if _hurt() else "idle", {"loop": true, "blend": blend, "align": "pelvis"})
	global_transform = Transform3D(Basis(Vector3.UP, pp.heading()), global_position)
	_slide_inside()


## A move that ended under the ropes leaves the anchor on the apron: slide it back inside (hidden by the blend).
func _slide_inside() -> void:
	if not in_ring:
		return
	var p := global_position
	var q := Ring.clamp_inside(p, 0.5 * size_k)
	q.y = Ring.MAT_Y
	if p.distance_to(q) > 0.01:
		global_position = q


func _hurt() -> bool:
	return total_damage() > 0.6


func _st_locomotion(dt: float) -> void:
	var mv := intent.move
	var speed := WALK_SPEED * (0.8 if _hurt() else 1.0)
	if _try_actions():
		return
	if intent.run and mv.length() > 0.3:
		_start_run(Vector3(mv.x, 0, mv.y).normalized())
		return
	var v := Vector3(mv.x, 0, mv.y)
	if v.length() > 1.0:
		v = v.normalized()
	var p := global_position + v * speed * dt
	global_position = _clamp_area(p)
	# SvR keeps the superstar facing the opponent while walking
	if opp and dist_to(opp) < 8.0 and in_ring == opp.in_ring:
		face_towards(opp.hips(), false, dt)
	elif v.length() > 0.2:
		face_towards(global_position + v, false, dt)
	var want := "idle"
	if v.length() > 0.15:
		var local := global_transform.basis.inverse() * v
		if absf(local.z) >= absf(local.x):
			want = "walk_f" if local.z > 0 else "walk_b"
		else:
			want = "walk_l" if local.x > 0 else "walk_r"
		if _hurt():
			want = want.replace("walk_", "walk_hurt_")
	if want != _loco_clip:
		_loco_clip = want
		var c := MotionDB.role(want)
		if c == null:
			c = MotionDB.role("idle")
		_play(c, {"loop": true, "blend": 0.18})
		set_state(S.IDLE if want == "idle" else S.WALK)


func _clamp_area(p: Vector3) -> Vector3:
	if in_ring:
		p = Ring.clamp_inside(p, 0.4 * scale_k())
		p.y = Ring.MAT_Y
	else:
		p = Ring.clamp_outside(p)
		p.y = 0.0
	# keep bodies apart
	if opp and not opp.busy_locked() and not busy_locked() and in_ring == opp.in_ring:
		var d := Vector3(p.x - opp.global_position.x, 0, p.z - opp.global_position.z)
		var min_d := 0.55 * (scale_k() + opp.scale_k())
		if d.length() < min_d and d.length() > 0.001:
			p = opp.global_position + d.normalized() * min_d
			p.y = floor_level
	return p


func _start_run(dir: Vector3) -> void:
	set_state(S.RUN)
	face_towards(global_position + dir, true)
	_role("run", {"loop": true, "blend": 0.15})


func _st_run(dt: float) -> void:
	var mv := Vector3(intent.move.x, 0, intent.move.y)
	if mv.length() > 0.3:
		face_towards(global_position + mv, false, dt * 0.6)
	if intent.strike_pressed:
		if opp and opp.is_down() and dist_to(opp) < 2.6:
			_start_solo_attack(MotionDB.slot(kind, "running", "ground_strike"), "ground")
			return
		_start_solo_attack(MotionDB.slot(kind, "running", "strike"), "running")
		return
	if intent.grapple_pressed and opp and opp.can_be_grabbed() and dist_to(opp) < 2.2 and angle_to(opp) < 0.9:
		_start_paired_move(MotionDB.slot(kind, "running", "grapple_1"), "neutral")
		return
	if not intent.run or intent.move.length() < 0.2:
		set_state(S.RUN_STOP)
		_role("run_stop", {"blend": 0.15, "align": "keep"})
		return
	var p := global_position + forward() * RUN_SPEED * dt
	if in_ring:
		var lim := Ring.HALF - 0.35
		if absf(p.x) > lim or absf(p.z) > lim:
			_rope_rebound(false)
			return
	global_position = _clamp_area(p)


func _rope_rebound(whipped: bool) -> void:
	var rn: Array = Ring.nearest_rope(global_position)
	var n: Vector3 = rn[1]
	# face the ropes, play SvR rope rebound (STAT 60) and come back the other way
	face_towards(global_position + n, true)
	set_state(S.REBOUND)
	whip_dir = -n
	_role("rope_rebound", {"blend": 0.1, "align": "keep"})
	set_meta("rebound_from_whip", whipped)


func _st_rebound(dt: float) -> void:
	if pp.finished or pp.progress() > 0.92:
		var hp := hips()
		global_position = Ring.clamp_inside(Vector3(hp.x, floor_level, hp.z), 0.45)
		face_towards(global_position + whip_dir, true)
		if get_meta("rebound_from_whip", false):
			set_state(S.WHIPPED)
			_role("whipped_run", {"loop": true, "blend": 0.12, "align": "keep"})
			whip_legs += 1
		else:
			_start_run(whip_dir)


func _st_oneshot_then_idle(dt: float, keep_moving: bool) -> void:
	if keep_moving and state_time < 0.25:
		global_position = _clamp_area(global_position + forward() * RUN_SPEED * 0.5 * dt)
	if pp.finished:
		_go_idle()


# ------------------------------------------------------------------------------------------- actions
func _try_actions() -> bool:
	if not opp:
		return false
	var d := dist_to(opp)
	if intent.special_pressed and momentum_state != "none":
		if _try_special():
			return true
	if intent.taunt_pressed:
		_start_taunt()
		return true
	if intent.action_pressed:
		if _try_ring_action():
			return true
	if opp.is_down() and in_ring == opp.in_ring and d < DOWN_RANGE:
		if intent.whip_pressed:
			_start_pin()
			return true
		if intent.grapple_pressed:
			_start_ground_grapple()
			return true
		if intent.submission_pressed:
			_start_ground_submission()
			return true
		if intent.strike_pressed:
			_start_solo_attack(MotionDB.slot(kind, "ground", "strike_upper" if randf() < 0.6 else "strike_lower"), "ground")
			return true
	# rebound attacks while the whipped opponent runs back at me (SvR: IRISH WHIP REBOUND slots)
	if opp.state == S.WHIPPED and opp.whip_legs >= 1 and d < 2.6 and opp.forward().dot(opp.dir_to(self)) > 0.5:
		if intent.strike_pressed:
			_start_solo_attack(MotionDB.slot(kind, "rebound", "c"), "running")
			return true
		if intent.grapple_pressed:
			opp.whip_legs = 99
			_start_paired_move(MotionDB.slot(kind, "rebound", "a"), "neutral", 10.0)
			return true
	if intent.strike_pressed:
		_charging = true
		_charge_t = 0.0
	if _charging:
		_charge_t += get_process_delta_time()
		if not intent.strike_held:
			_charging = false
			_start_strike(false)
			return true
		if _charge_t > 0.32:
			_charging = false
			_start_strike(true)
			return true
	if in_ring == opp.in_ring and opp.state == S.GROGGY and d < GRAB_RANGE and intent.grapple_pressed:
		var behind := opp.angle_to(self) > 2.0
		var lab := _grapple_dir_label(intent.grapple_dir)
		var label: String = ("back_%d" % (1 + randi() % 2)) if behind else {"up": "front_1", "right": "front_2", "down": "front_3", "left": "front_4"}[lab]
		var gid := MotionDB.slot(kind, "groggy", label)
		if gid >= 0 and not MotionDB.move(gid).is_empty():
			_start_paired_move(gid, "neutral", 11.0)
			return true
	if in_ring == opp.in_ring and opp.can_be_grabbed() and d < GRAB_RANGE:
		if intent.grapple_pressed:
			_start_lockup()
			return true
		if intent.whip_pressed:
			_start_whip()
			return true
	return false


func _start_strike(strong: bool) -> void:
	var mid := -1
	if strong:
		mid = MotionDB.slot(kind, "strong", "strong_1")
	else:
		var labels := ["combo_1", "combo_2", "combo_3"]
		mid = MotionDB.slot(kind, "combo", labels[clampi(combo_step, 0, 2)])
		if intent.move.length() > 0.5 and combo_step == 0:
			mid = MotionDB.slot(kind, "strike", "strike_%d" % (2 + randi() % 4))
	if mid < 0:
		mid = MotionDB.slot(kind, "strike", "strike_1")
	strike_hold_t = 0.0
	_start_solo_attack(mid, "strong" if strong else "strike")


## one-role attack clip (strikes, running strikes, ground strikes, dives); the hit is resolved at the impact frame
func _start_solo_attack(mid: int, kind_: String) -> void:
	var c := MotionDB.move_clip(mid, 0)
	if c == null:
		_go_idle()
		return
	cur_move = mid
	cur_impacts = MotionDB.impact_frames(mid)
	if cur_impacts.is_empty():
		cur_impacts = [int(c.frames * 0.42)]
	impact_done = {}
	set_meta("attack_kind", kind_)
	var face := yaw()
	if opp and dist_to(opp) < 4.0:
		var dd := dir_to(opp)
		face = atan2(dd.x, dd.z)
	set_state(S.STRIKE if kind_ != "dive" else S.DIVE)
	_play(c, {"anchor": _anchor_here(face), "blend": 0.12})
	if opp and kind_ in ["strike", "strong", "running"] and opp.state in [S.IDLE, S.WALK, S.GROGGY, S.TAUNT, S.STRIKE]:
		var lead := maxf(float(cur_impacts[0]) / c.fps - 0.05, 0.1)
		opp.open_reversal("strike", lead)
	stats["strikes"] += 1


func _st_strike(_dt: float) -> void:
	var f := pp.frame()
	for i in cur_impacts.size():
		var fi := int(cur_impacts[i])
		if f >= fi and not impact_done.has(i):
			impact_done[i] = true
			_resolve_hit(String(get_meta("attack_kind", "strike")), i == cur_impacts.size() - 1)
	if intent.strike_pressed and String(get_meta("attack_kind", "")) == "strike":
		combo_buffer = true
	if pp.finished or (combo_buffer and pp.progress() > 0.72 and combo_step < 2):
		if combo_buffer and combo_step < 2 and impact_done.size() > 0 and last_event == "hit":
			combo_step += 1
			combo_buffer = false
			_start_strike(false)
			return
		combo_step = 0
		combo_buffer = false
		if pp.finished:
			_go_idle()


func _resolve_hit(kind_: String, last: bool) -> void:
	last_event = "miss"
	if match_ref and match_ref.verbose_hits:
		match_ref._log("%s %s attempt (dist %.2f)" % [display_name, kind_, dist_to(opp) if opp else -1.0])
	if not opp:
		return
	var reach := REACH * (scale_k() + opp.scale_k()) * 0.5
	if kind_ == "running":
		reach *= 1.4
	if kind_ == "special":
		reach *= 1.9
	if kind_ == "ground" or kind_ == "dive":
		reach = 1.8 * (scale_k() + opp.scale_k()) * 0.5
	var d := dist_to(opp)
	var ang := angle_to(opp)
	if kind_ == "ground" or kind_ == "dive":
		if not opp.is_down() and kind_ == "ground":
			return
		if d > reach:
			return
	else:
		# at very short range (lunging attacks carry the attacker into the opponent) the facing test is meaningless
		var facing_ok := ang <= 1.2 or d < 0.55 * pair_k(opp)
		if d > reach or not facing_ok or not opp.is_free_standing() or opp.in_ring != in_ring:
			return
		if opp.reversal_ok() and opp.reversal_armed == "strike":
			opp.consume_reversal()
			_get_blocked()
			return
	var dmg: float = {"strike": 4.0, "strong": 9.0, "running": 10.0, "ground": 5.0, "dive": 14.0}.get(kind_, 5.0)
	if kind_ == "special":
		dmg = float(get_meta("special_dmg", 20.0))
	var region := "head" if randf() < 0.55 else "body"
	if kind_ == "ground":
		region = "body" if randf() < 0.5 else "legs"
	opp.take_hit(self, dmg, region, kind_)
	add_momentum(dmg * 0.9)
	last_event = "hit"
	if match_ref:
		match_ref.on_impact(self, opp, dmg)


func take_hit(from: Wrestler, dmg: float, region: String, kind_: String) -> void:
	add_damage(region, dmg)
	add_momentum(-1.5)
	if state in [S.DOWN] or is_down():
		# ground strike while down: stay down a bit longer
		down_timer += 0.6
		return
	var face := atan2(from.hips().x - hips().x, from.hips().z - hips().z)
	var knock := kind_ in ["strong", "running", "dive"] and (randf() < 0.55 + total_damage() * 0.4)
	if kind_ == "running" or kind_ == "dive" or kind_ == "special":
		knock = true
	if knock:
		var r := "knockdown_back" if randf() < 0.7 else "knockdown_front"
		set_state(S.KNOCKDOWN)
		_role(r, {"anchor": _anchor_here(face), "blend": 0.1})
		face_up = (r == "knockdown_back")
		return
	if kind_ == "strong" and total_damage() > 0.45 and randf() < 0.5:
		_start_groggy()
		return
	var rr := "hit_hi" if region == "head" else ("hit_lo" if randf() < 0.5 else "hit_mid")
	set_state(S.HIT)
	_role(rr, {"anchor": _anchor_here(face), "blend": 0.08})


func _get_blocked() -> void:
	# SvR 2011: BLOCKING PUNCHES [RT] -> BLOCKED PUNCH IDLE (STAT 1280 role 0 holds role 1's punching arm)
	if match_ref:
		match_ref.announce("REVERSAL!", opp.color)
	opp.stats["reversals"] += 1
	opp.add_momentum(8.0)
	var anchor := opp._anchor_here(atan2(hips().x - opp.hips().x, hips().z - opp.hips().z))
	opp.set_state(S.BLOCK_A)
	opp._role("block_punch_a", {"anchor": anchor, "blend": 0.12, "pair": self})
	set_state(S.BLOCK_V)
	_role("block_punch_v", {"anchor": anchor * pair_xf(opp, MotionDB.generic_pair_xform("block_punch")), "blend": 0.12, "pair": opp})


func _st_block(_dt: float) -> void:
	if state == S.BLOCK_A and (state_time > 1.1 or intent.strike_pressed):
		# release with a counter shove: the blocked attacker staggers
		opp.take_hit(self, 3.0, "arms", "strike")
		_go_idle()
	elif state == S.BLOCK_V and state_time > 2.5:
		_go_idle()


func _st_knockdown(_dt: float) -> void:
	if pp.finished:
		_enter_down(face_up)


func _enter_down(up: bool, extra := 0.0) -> void:
	face_up = up
	set_state(S.DOWN)
	_ensure_floor()
	down_timer = 1.2 + total_damage() * 3.5 + extra
	_role("down_up" if up else "down_down", {"loop": true, "blend": 0.35, "align": "pelvis"})
	_slide_inside()


func _st_down(dt: float) -> void:
	if intent.mash_pressed:
		down_timer -= 0.18
	down_timer -= dt
	if down_timer <= 0.0:
		set_state(S.GETUP)
		_role("getup_up" if face_up else "getup_down", {"blend": 0.25, "align": "pelvis"})


func _start_groggy() -> void:
	set_state(S.GROGGY)
	if play_smash("FuraFura", {"loop": true, "blend": 0.25}):
		return
	_role("groggy", {"blend": 0.15, "align": "pelvis"})


func _st_groggy(_dt: float) -> void:
	if state_time > 2.2 + total_damage() * 1.5 or (not smash_mode and pp.finished):
		_go_idle()


# ------------------------------------------------------------------------------------------- chain grapple
func _grapple_dir_label(v: Vector2) -> String:
	if v.length() < 0.3:
		return "up"
	if absf(v.x) > absf(v.y):
		return "right" if v.x > 0 else "left"
	return "up" if v.y < 0 else "down"


func _start_lockup() -> void:
	# SvR 2011 chain grapple: front (any RS direction facing) or rear (from behind -> waist lock)
	var behind := opp.angle_to(self) > 2.0
	var lab := _grapple_dir_label(intent.grapple_dir)
	if behind:
		hold_type = "waistlock"
	else:
		hold_type = String({"up": "facelock", "down": "facelock", "left": "headlock", "right": "wristlock"}[lab])
	var face := atan2(opp.hips().x - hips().x, opp.hips().z - hips().z)
	var anchor := _anchor_here(face)
	set_state(S.LOCK_A)
	_role("lock_%s_a" % hold_type, {"anchor": anchor, "blend": 0.15, "pair": opp})
	opp.set_state(S.LOCK_V)
	var vx := anchor * pair_xf(opp, MotionDB.generic_pair_xform("lock_" + hold_type))
	if hold_type == "waistlock":
		# rear lock: the victim keeps facing away (role 1 clip starts with its back to role 0)
		pass
	opp._play(MotionDB.role("lock_%s_v" % hold_type), {"anchor": vx, "blend": 0.18, "pair": self})
	opp.open_reversal("grapple", 0.45)


func _st_lock_a(_dt: float) -> void:
	if state_time < 0.6 and opp.reversal_ok() and opp.reversal_armed == "grapple":
		opp.consume_reversal()
		_reversed_grapple()
		return
	if pp.finished:
		set_state(S.HOLD_A)
		hold_time = 0.0
		var anchor := global_transform
		_role("hold_%s_a" % hold_type, {"loop": true, "blend": 0.15, "anchor": anchor, "pair": opp})
		opp.set_state(S.HOLD_V)
		opp._play(MotionDB.role("hold_%s_v" % hold_type), {"loop": true, "blend": 0.15,
			"anchor": anchor * pair_xf(opp, MotionDB.generic_pair_xform("hold_" + hold_type)), "pair": self})
		if match_ref and not is_cpu:
			match_ref.announce("HOLD: K+dir throw, J strike, E submission, Space release", Color(0.9, 0.9, 0.9), 1.6)


func _reversed_grapple() -> void:
	# reversal: the defender performs SvR's "Belly to Belly Reversal" (STAT 838) or shoves free
	if match_ref:
		match_ref.announce("REVERSAL!", opp.color)
	opp.stats["reversals"] += 1
	opp.add_momentum(10.0)
	var m := MotionDB.move(838)
	if not m.is_empty() and m["clips"].has("1"):
		opp._start_paired_move(838, "neutral", 12.0)
	else:
		take_hit(opp, 3.0, "body", "strike")
		opp._go_idle()


func _st_hold_a(dt: float) -> void:
	hold_time += dt
	if intent.grapple_pressed or (is_cpu and false):
		var lab := _grapple_dir_label(intent.grapple_dir)
		var slots: Dictionary = MotionDB.holds.get(hold_type, {}).get("slots", {})
		var group := hold_type
		var label: String = {"up": "throw_1", "right": "throw_2", "down": "throw_3", "left": "throw_4"}[lab]
		var mid := MotionDB.slot(kind, group, label)
		if mid < 0 and slots.has(lab):
			mid = int(slots[lab])
		_start_paired_move(mid, "hold")
		return
	if intent.strike_pressed:
		_start_paired_move(MotionDB.slot(kind, hold_type, "strike"), "hold", 5.0)
		return
	if intent.submission_pressed:
		var sid := MotionDB.slot(kind, hold_type, "submission")
		if sid >= 0:
			_start_submission(sid, "hold")
			return
	if intent.whip_pressed:
		_release_hold()
		_start_whip()
		return
	if intent.action_pressed or hold_time > 4.0:
		_release_hold()


func _release_hold() -> void:
	_go_idle()
	if opp.state == S.HOLD_V:
		opp._go_idle()


func _st_hold_v(_dt: float) -> void:
	# mash to break free (custom: SvR lets the defender escape holds)
	if intent.mash_pressed:
		set_meta("escape", float(get_meta("escape", 0.0)) + 1.0)
	if float(get_meta("escape", 0.0)) > 9.0 + opp.total_damage() * 4.0 - total_damage() * 6.0:
		set_meta("escape", 0.0)
		if match_ref:
			match_ref.announce("%s broke free!" % display_name, color)
		opp.take_hit(self, 2.0, "body", "strike")
		_go_idle()


# ------------------------------------------------------------------------------------------- paired moves
## mode: "hold" (both align to their current pelvis: SvR hold spacing), "neutral" (victim placed by the fitted
## pair transform), "ground" (attacker placed relative to the lying victim)
func _start_paired_move(mid: int, mode: String, dmg := -1.0) -> void:
	var m := MotionDB.move(mid)
	var ca := MotionDB.move_clip(mid, 0)
	var cv := MotionDB.move_clip(mid, 1)
	if m.is_empty() or ca == null or cv == null:
		if state == S.HOLD_A:
			_release_hold()
		else:
			_go_idle()
		return
	cur_move = mid
	cur_impacts = m.get("impact_frames", [])
	impact_done = {}
	var victim_end: String = m.get("victim_end", "down_up")
	if dmg < 0:
		dmg = 8.0 + (6.0 if victim_end != "stand" else 0.0)
	set_meta("move_dmg", dmg)
	stats["moves"] += 1
	var px := pair_xf(opp, MotionDB.move_pair_xform(mid))
	set_state(S.MOVE_A)
	opp.set_state(S.MOVE_V)
	opp.cur_move = mid
	if mode == "hold":
		_play(ca, {"blend": 0.15, "align": "pelvis", "pair": opp})
		opp._play(cv, {"blend": 0.15, "align": "pelvis", "pair": self})
	elif mode == "ground":
		opp._play(cv, {"blend": 0.25, "align": "pelvis", "pair": self})
		var va := opp.global_transform
		_play(ca, {"blend": 0.3, "anchor": va * px.affine_inverse(), "pair": opp})
		global_position.y = floor_level
	else:
		var face := atan2(opp.hips().x - hips().x, opp.hips().z - hips().z)
		var anchor := _anchor_here(face)
		_play(ca, {"blend": 0.15, "anchor": anchor, "pair": opp})
		opp._play(cv, {"blend": 0.2, "anchor": anchor * px, "pair": self})
	if mode != "ground":
		opp.open_reversal("move", 0.35)
	if match_ref:
		match_ref.on_move_start(self, opp, m)


func _st_move_a(_dt: float) -> void:
	if state_time < 0.45 and opp.reversal_ok() and opp.reversal_armed == "move" and cur_move not in [838, 829, 845, -2, -3]:
		opp.consume_reversal()
		_reversed_grapple()
		return
	if get_meta("submission", false) and (pp.progress() > 0.55 or pp.finished):
		_sub_hold_begin()
		return
	var f := pp.frame()
	var dmg := float(get_meta("move_dmg", 10.0))
	var n := maxi(cur_impacts.size(), 1)
	for i in cur_impacts.size():
		if f >= int(cur_impacts[i]) and not impact_done.has(i):
			impact_done[i] = true
			_apply_move_damage(dmg / n)
	if pp.finished and (opp.pp.finished or opp.state != S.MOVE_V):
		if impact_done.is_empty():
			_apply_move_damage(dmg)
		_finish_paired()


func _apply_move_damage(d: float) -> void:
	var nm: String = String(MotionDB.move(cur_move).get("name", "")).to_lower()
	var region := "body"
	for kw in ["ddt", "neckbreaker", "head", "face", "bulldog", "stunner", "chin"]:
		if nm.find(kw) >= 0:
			region = "head"
	for kw in ["leg", "knee", "ankle", "boston", "sharpshooter", "figure"]:
		if nm.find(kw) >= 0:
			region = "legs"
	for kw in ["arm", "wrist", "shoulder"]:
		if nm.find(kw) >= 0:
			region = "arms"
	opp.add_damage(region, d)
	add_momentum(d * 0.8)
	if match_ref:
		match_ref.on_impact(self, opp, d)


func _st_move_v(_dt: float) -> void:
	pass


func _finish_paired() -> void:
	if cur_move == -2:   # lift: the opponent ends on its feet, groggy
		_go_idle()
		opp._start_groggy()
		return
	if cur_move == -3:   # roll-over then cover
		opp.face_up = true
		_cover()
		return
	var m := MotionDB.move(cur_move)
	var a_end: String = m.get("attacker_end", "stand")
	var v_end: String = m.get("victim_end", "down_up")
	var was_finisher := bool(get_meta("finisher", false))
	set_meta("finisher", false)
	_after_clip(a_end, 0.0)
	opp._after_clip(v_end, 2.0 if was_finisher else 0.0)
	if was_finisher:
		opp.down_timer += 4.0


## leave a one-shot clip into the right follow-up state
func _after_clip(end_state: String, extra_down: float) -> void:
	_update_ring_side()
	if end_state == "down_up" or end_state == "down_down":
		_enter_down(end_state == "down_up", extra_down)
	elif end_state == "sit" or end_state == "kneel":
		_enter_down(true, extra_down * 0.5)
	else:
		if state == S.MOVE_V and total_damage() > 0.5 and randf() < 0.5:
			_start_groggy()
		else:
			_go_idle()


func _update_ring_side() -> void:
	# on the mat (or lying under the ropes on the apron) counts as in the ring; below the mat = on the floor
	var p := hips()
	var was := in_ring
	var edge := Ring.HALF + Ring.APRON + 0.25
	in_ring = p.y > Ring.MAT_Y - 0.5 and absf(p.x) < edge and absf(p.z) < edge
	if was and not in_ring:
		global_position.y = 0.0
	_ensure_floor()


# ------------------------------------------------------------------------------------------- ground game
func _start_ground_grapple() -> void:
	var lab := _grapple_dir_label(intent.grapple_dir)
	if lab == "up":
		_start_lift()
		return
	var near_head := _near_head_end()
	var g := "up_" if opp.face_up else "down_"
	var label := g + ("head" if near_head else "feet")
	if lab == "left" or lab == "right":
		label = g + "side"
	var mid := MotionDB.slot(kind, "ground", label)
	if mid < 0:
		mid = MotionDB.slot(kind, "ground", g + "head")
	_start_paired_move(mid, "ground", 9.0)


func _near_head_end() -> bool:
	var q: Quaternion = opp.pp.cur_rots[0]
	var head_dir := q * Vector3(0, 1, 0)
	var to_me := hips() - opp.hips()
	to_me.y = 0
	head_dir.y = 0
	return head_dir.dot(to_me) > 0.0


func _start_ground_submission() -> void:
	var label := "sub_head" if _near_head_end() else "sub_feet"
	var mid := MotionDB.slot(kind, "ground", label)
	if mid < 0:
		mid = MotionDB.slot(kind, "ground", "sub_head")
	_start_submission(mid, "ground")


func _start_lift() -> void:
	var r := "lift" if opp.face_up else "lift_down"
	opp.set_state(S.MOVE_V)
	opp._role(r + "_v", {"blend": 0.25, "align": "pelvis", "pair": self})
	set_state(S.MOVE_A)
	cur_move = -2
	cur_impacts = []
	impact_done = {0: true}
	_play(MotionDB.role(r + "_a"), {"blend": 0.3, "anchor": opp.global_transform * pair_xf(opp, MotionDB.generic_pair_xform(r)).affine_inverse(), "pair": opp})
	set_meta("move_dmg", 0.0)


# ------------------------------------------------------------------------------------------- pin (SvR: [B] on a grounded opponent)
func _start_pin() -> void:
	if not opp.face_up:
		# roll the opponent over first (SvR STAT 10292: face down -> face up), then cover
		set_meta("pin_after_roll", true)
		opp.set_state(S.MOVE_V)
		opp._role("roll_over_v", {"blend": 0.25, "align": "pelvis", "pair": self})
		set_state(S.MOVE_A)
		cur_move = -3
		cur_impacts = []
		impact_done = {0: true}
		_play(MotionDB.role("roll_over_a"), {"blend": 0.3, "anchor": opp.global_transform * pair_xf(opp, MotionDB.generic_pair_xform("roll_over")).affine_inverse(), "pair": opp})
		return
	_cover()


func _cover() -> void:
	# cover = first frame of SvR's cover/kick-out pair (CORN 3552 subs 7680/7681), shared frame (theta 0)
	opp.set_state(S.PIN_V)
	opp._play(MotionDB.role("pin_cover_v"), {"blend": 0.35, "align": "pelvis", "speed": 0.0, "pair": self})
	set_state(S.PIN_A)
	_play(MotionDB.role("pin_cover_a"), {"blend": 0.4, "anchor": opp.global_transform, "speed": 0.0, "pair": opp})
	opp.kickout_progress = 0.0
	pin_count = 0
	if match_ref:
		match_ref.start_pin(self, opp)


func _st_pin_a(_dt: float) -> void:
	pass  # the match's referee count drives the pin


func _st_pin_v(_dt: float) -> void:
	if intent.mash_pressed:
		kickout_progress += 1.0


func kickout_needed() -> float:
	# more damage = harder to kick out (custom curve); finishers add a big penalty
	return 4.0 + total_damage() * 22.0 + float(get_meta("finisher_penalty", 0.0))


func do_kickout() -> void:
	# both play the rest of the cover/kick-out pair: victim's legs fly up, the cover is thrown off
	stats["kickouts"] += 1
	set_state(S.KICKOUT_V)
	pp.speed = 1.0
	opp.set_state(S.KICKOUT_A)
	opp.pp.speed = 1.0
	set_meta("finisher_penalty", 0.0)


func _st_kickout(_dt: float) -> void:
	if pp.finished:
		if state == S.KICKOUT_V:
			_enter_down(true, -0.5)
		else:
			_after_clip(String(MotionDB.info(pp.clip_name).get("end_state", "stand")), 0.0)


# ------------------------------------------------------------------------------------------- submissions
func _start_submission(mid: int, mode: String) -> void:
	_start_paired_move(mid, mode, 6.0)
	if state != S.MOVE_A:
		return
	set_meta("submission", true)
	sub_escape = 0.0
	sub_pressure = 0.0


func _sub_hold_begin() -> void:
	set_state(S.SUB_A)
	opp.set_state(S.SUB_V)
	pp.speed = 0.0
	opp.pp.speed = 0.0
	if match_ref:
		match_ref.start_submission(self, opp)


func _st_sub_a(_dt: float) -> void:
	if intent.mash_pressed or intent.submission_pressed:
		sub_pressure += 1.0


func _st_sub_v(_dt: float) -> void:
	if intent.mash_pressed:
		sub_escape += 1.0


func end_submission(escaped: bool) -> void:
	set_meta("submission", false)
	pp.speed = 1.0
	opp.pp.speed = 1.0
	if escaped:
		take_hit(opp, 2.0, "body", "strike")
		opp._enter_down(opp.face_up, -0.5)


# ------------------------------------------------------------------------------------------- Irish whip
func _start_whip() -> void:
	# SvR 2011 IRISH WHIP: [B] & [LS ANY] to direct the throw; whip clips STAT 900/920 (identified from renders)
	var dir := Vector3(intent.move.x, 0, intent.move.y)
	if dir.length() < 0.3:
		dir = dir_to(opp)
	dir = dir.normalized()
	var face := atan2(opp.hips().x - hips().x, opp.hips().z - hips().z)
	set_state(S.WHIP_A)
	set_meta("buffer_strike", false)
	set_meta("buffer_grapple", false)
	_play(MotionDB.role("whip_throw"), {"anchor": _anchor_here(face), "blend": 0.12})
	opp.whip_dir = dir
	opp.whip_legs = 0
	opp.set_state(S.WHIPPED)
	opp.face_towards(opp.global_position + dir, true)
	opp._play(MotionDB.role("whipped_start"), {"blend": 0.15, "align": "keep"})
	opp.set_meta("whip_started", true)
	add_momentum(2.0)


func _st_whip_a(_dt: float) -> void:
	# after the throw itself the attacker may act again (rebound attacks while the opponent runs back)
	if intent.strike_pressed or intent.grapple_pressed:
		set_meta("buffer_strike", intent.strike_pressed)
		set_meta("buffer_grapple", intent.grapple_pressed)
	if state_time > 0.3:
		if get_meta("buffer_strike", false) or get_meta("buffer_grapple", false):
			intent.strike_pressed = get_meta("buffer_strike", false)
			intent.grapple_pressed = get_meta("buffer_grapple", false)
			set_meta("buffer_strike", false)
			set_meta("buffer_grapple", false)
			if _try_actions():
				return
		if pp.progress() > 0.55 or pp.finished:
			_go_idle(0.25)


func _st_whipped(dt: float) -> void:
	if get_meta("whip_started", false) and (pp.finished or pp.progress() > 0.8):
		set_meta("whip_started", false)
		_role("whipped_run", {"loop": true, "blend": 0.1, "align": "keep"})
	var p := global_position + whip_dir * WHIP_SPEED * dt
	var lim := Ring.HALF - 0.4
	if whip_legs >= 3 or state_time > 6.0:
		set_state(S.RUN_STOP)
		_role("run_stop", {"blend": 0.15, "align": "keep"})
		return
	if absf(p.x) > lim or absf(p.z) > lim:
		_rope_rebound(true)
		return
	var incoming: bool = opp != null and (opp.state == S.STRIKE or (opp.state == S.WHIP_A and
		(bool(opp.get_meta("buffer_strike", false)) or bool(opp.get_meta("buffer_grapple", false)))))
	if whip_legs >= 1 and incoming and dist_to(opp) < 0.95 * pair_k(opp):
		return  # running straight into the (possibly buffered) rebound attack: hold here for the impact
	global_position = Ring.clamp_inside(p, 0.35)
	global_position.y = floor_level
	if whip_legs >= 1 and opp and opp.state in [S.IDLE, S.WALK] and dist_to(opp) < 1.0:
		# collided with the waiting opponent without an attack: stop
		set_state(S.RUN_STOP)
		_role("run_stop", {"blend": 0.15, "align": "keep"})


# ------------------------------------------------------------------------------------------- ring / turnbuckle
func _try_ring_action() -> bool:
	if in_ring:
		var rn: Array = Ring.nearest_rope(hips())
		if Ring.corner_distance(hips()) < 1.1 and not (opp and opp.in_ring and dist_to(opp) < 1.0):
			_start_climb()
			return true
		if float(rn[0]) < 0.9:
			_start_exit(rn[1])
			return true
	else:
		var p := hips()
		var edge := Ring.HALF + Ring.APRON
		if absf(p.x) < edge + 1.2 and absf(p.z) < edge + 1.2:
			_start_enter()
			return true
	return false


func _start_exit(n: Vector3) -> void:
	set_state(S.EXIT_RING)
	var mid := MotionDB.slot(kind, "ring", "ring_out")
	var c := MotionDB.move_clip(mid, 0)
	if c == null:
		c = MotionDB.clip("BASE_749_0")
	var face := atan2(n.x, n.z)
	var edge := hips() + n * (float(Ring.nearest_rope(hips())[0]) - 0.35)
	_play(c, {"anchor": Transform3D(Basis(Vector3.UP, face), Vector3(edge.x, Ring.MAT_Y, edge.z)), "blend": 0.2})


func _st_exit(_dt: float) -> void:
	if pp.finished:
		in_ring = false
		floor_level = 0.0
		var p := Ring.clamp_outside(Vector3(hips().x, 0, hips().z))
		global_position = Vector3(p.x, 0.0, p.z)
		_go_idle(0.3)
		if match_ref:
			match_ref.on_ring_change(self)


func _start_enter() -> void:
	set_state(S.ENTER_RING)
	var mid := MotionDB.slot(kind, "ring", "ring_in")
	var c := MotionDB.move_clip(mid, 0)
	if c == null:
		c = MotionDB.clip("BASE_739_0")
	var p := hips()
	var n := Vector3(signf(p.x), 0, 0) if absf(p.x) > absf(p.z) else Vector3(0, 0, signf(p.z))
	var face := atan2(-n.x, -n.z)
	var edge := Vector3(p.x, 0, p.z)
	if absf(n.x) > 0:
		edge.x = n.x * (Ring.HALF + Ring.APRON + 0.45)
	else:
		edge.z = n.z * (Ring.HALF + Ring.APRON + 0.45)
	var h0 := c.hips_at(0.0)
	var basis := Basis(Vector3.UP, face)
	var origin := Vector3(edge.x, Ring.MAT_Y, edge.z) - basis * Vector3(h0.x * scale_k(), 0, h0.z * scale_k())
	_play(c, {"anchor": Transform3D(basis, origin), "blend": 0.25})


func _st_enter(_dt: float) -> void:
	if pp.finished:
		in_ring = true
		floor_level = Ring.MAT_Y
		global_position.y = Ring.MAT_Y
		global_position = Ring.clamp_inside(global_position, 0.5)
		_go_idle(0.3)
		if match_ref:
			match_ref.on_ring_change(self)


func _start_climb() -> void:
	var c := Ring.nearest_corner(hips())
	var out := Vector3(signf(c.x), 0, signf(c.z)).normalized()
	set_state(S.CLIMB)
	var clip := MotionDB.role("climb_tb")
	var face := atan2(out.x, out.z)
	var basis := Basis(Vector3.UP, face)
	var h0 := clip.hips_at(0.0)
	var origin := Vector3(c.x, Ring.MAT_Y, c.z) - basis * Vector3(h0.x * scale_k(), 0, h0.z * scale_k())
	_play(clip, {"anchor": Transform3D(basis, origin), "blend": 0.2})


func _st_climb(_dt: float) -> void:
	if pp.finished:
		set_state(S.TOP)
		pp.speed = 0.0


func _st_top(_dt: float) -> void:
	if intent.strike_pressed or (is_cpu and state_time > 1.0 and intent.strike_held):
		var vs_down := opp and opp.is_down()
		var mid := MotionDB.slot(kind, "diving", "vs_downed_1" if vs_down else "vs_standing_1")
		var c := MotionDB.move_clip(mid, 0)
		if c:
			pp.speed = 1.0
			cur_move = mid
			cur_impacts = MotionDB.impact_frames(mid)
			if cur_impacts.is_empty():
				cur_impacts = [int(c.frames * 0.55)]
			impact_done = {}
			set_meta("attack_kind", "dive")
			set_state(S.DIVE)
			var face := yaw()
			if opp:
				var dd := dir_to(opp)
				face = atan2(dd.x, dd.z)
			_play(c, {"blend": 0.15, "align": "pelvis"})
			global_transform = Transform3D(Basis(Vector3.UP, face), global_position)
			return
	if intent.action_pressed or state_time > 6.0:
		pp.speed = 1.0
		set_state(S.STEP_DOWN)
		_role("step_down", {"blend": 0.2, "align": "pelvis"})


func _st_dive(_dt: float) -> void:
	var f := pp.frame()
	for i in cur_impacts.size():
		if f >= int(cur_impacts[i]) and not impact_done.has(i):
			impact_done[i] = true
			_resolve_hit("dive", true)
	if pp.finished:
		var e: String = MotionDB.info(pp.clip_name).get("end_state", "stand")
		_after_clip(e, -0.8)


# ------------------------------------------------------------------------------------------- taunts & specials
func _start_taunt() -> void:
	set_state(S.TAUNT)
	if play_smash("Appeal", {"blend": 0.2}):
		if match_ref:
			match_ref.on_taunt(self)
		return
	var labels := ["taunt1", "taunt2", "taunt3", "taunt4"]
	var mid := MotionDB.slot(kind, "taunt", labels[randi() % 4])
	var c := MotionDB.move_clip(mid, 0)
	if c == null:
		_go_idle()
		return
	_play(c, {"blend": 0.2, "align": "pelvis"})
	if match_ref:
		match_ref.on_taunt(self)


func _st_taunt(_dt: float) -> void:
	if state_time > 0.4 and state_time < 0.5:
		add_momentum(14.0)
	var done: bool = smash.finished if smash_mode else pp.finished
	if done or state_time > 4.0 or (opp and opp.state in [S.STRIKE, S.RUN] and dist_to(opp) < 1.5):
		_go_idle()


## Which special (signature / finisher) is available now and whether the opponent is in the position it needs.
func special_check() -> Dictionary:
	if momentum_state == "none" or opp == null:
		return {}
	var sig := momentum_state == "signature"
	var mid := MotionDB.slot(kind, "special", "signature_1" if sig else "finisher_1")
	var m := MotionDB.move(mid)
	if m.is_empty():
		return {}
	if not m.get("clips", {}).has("1"):
		# one-sided special (e.g. R-Truth's Lie Detector): a strike that must connect with a standing opponent
		if opp.is_free_standing() and dist_to(opp) < 2.6 and opp.in_ring == in_ring:
			return {"mid": mid, "mode": "solo", "sig": sig, "move": m}
		return {"needs": "stand", "sig": sig}
	var vstart: String = String(m.get("victim_start", "stand"))
	if vstart == "stand":
		if opp.can_be_grabbed() and dist_to(opp) < 2.0 and opp.in_ring == in_ring:
			return {"mid": mid, "mode": "neutral", "sig": sig, "move": m}
	elif opp.is_down() and dist_to(opp) < DOWN_RANGE + 0.5:
		return {"mid": mid, "mode": "ground", "sig": sig, "move": m}
	return {"needs": vstart, "sig": sig}


func _try_special() -> bool:
	var chk := special_check()
	if not chk.has("mid"):
		return false
	var sig: bool = chk["sig"]
	var mid: int = chk["mid"]
	var m: Dictionary = chk["move"]
	var mode: String = chk["mode"]
	set_meta("finisher", not sig)
	if mode == "solo":
		set_meta("special_dmg", 14.0 if sig else 30.0)
		_start_solo_attack(mid, "special")
		if state != S.STRIKE:
			set_meta("finisher", false)
			return false
	else:
		_start_paired_move(mid, mode, 14.0 if sig else 30.0)
		if state != S.MOVE_A:
			set_meta("finisher", false)
			return false
	if match_ref:
		match_ref.announce(("SIGNATURE: " if sig else "FINISHER: ") + String(m.get("name", "")), color, 2.4)
	# the momentum is spent only once the move has really started
	if sig:
		momentum_state = "finisher"      # string 24931: the signature switches the momentum over to a finisher
		momentum_full_time = now()
	else:
		momentum_state = "none"
		momentum = 0.0
		opp.set_meta("finisher_penalty", 18.0)
	return true


## Instantly place the wrestler (tests, match setup): idle pose at pos facing yaw, no pelvis re-alignment.
func teleport(pos: Vector3, face_yaw: float) -> void:
	in_ring = absf(pos.x) < Ring.HALF + 0.2 and absf(pos.z) < Ring.HALF + 0.2
	_ensure_floor()
	pos.y = floor_level
	global_transform = Transform3D(Basis(Vector3.UP, face_yaw), pos)
	set_state(S.IDLE)
	_loco_clip = "idle"
	_play(MotionDB.role("idle"), {"loop": true, "blend": 0.0, "align": "keep"})
	pp._has_pose = false
	pp.play(pp.clip, {"loop": true, "blend": 0.0, "align": "keep"})
	pp.update(0.0)


# ------------------------------------------------------------------------------------------- scripted (entrances / results)
func scripted_play(c: SwmClip, opts: Dictionary) -> void:
	set_state(S.SCRIPTED)
	_play(c, opts)


func set_victory() -> void:
	set_state(S.VICTORY)
	if play_smash("Win%d" % (1 + randi() % 3), {"blend": 0.35}):
		return
	var mid := MotionDB.slot(kind, "taunt", "taunt1")
	var c := MotionDB.move_clip(mid, 0)
	if c:
		_play(c, {"blend": 0.3, "align": "pelvis"})


func set_defeated() -> void:
	if not is_down():
		set_state(S.DEFEATED)
		_role("knockdown_back", {"blend": 0.2, "align": "pelvis"})
	else:
		set_state(S.DEFEATED)


func state_name() -> String:
	return S.keys()[state]
