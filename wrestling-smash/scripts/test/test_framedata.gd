## Frame-data check through the full engine: each move is performed with controller input
## (like a player) and the frames on which hitboxes are active are recorded, with the hitbox
## parameters the engine actually used. Output: evidence/framedata/framedata_<kind>.json
##   Godot --headless --path game_check -s res://scripts/test/test_framedata.gd -- [fkind ...]
extends SceneTree

const MOVES := {
	# name: [setup frames holding stick (x,y) before the press, press stick (x,y), button, wait-airborne]
	"jab1":   [[0, 0], [0, 0], SSBDefs.A_BUTTON, false, 0],
	"ftilt":  [[40, 0], [40, 0], SSBDefs.A_BUTTON, false, 6],
	"utilt":  [[0, 40], [0, 40], SSBDefs.A_BUTTON, false, 6],
	"dtilt":  [[0, -40], [0, -40], SSBDefs.A_BUTTON, false, 6],
	"fsmash": [[0, 0], [80, 0], SSBDefs.A_BUTTON, false, 0],
	"usmash": [[0, 0], [0, 80], SSBDefs.A_BUTTON, false, 0],
	"dsmash": [[0, 0], [0, -80], SSBDefs.A_BUTTON, false, 0],
	"nspecial": [[0, 0], [0, 0], SSBDefs.B_BUTTON, false, 0],
	"nair":   [[0, 0], [0, 0], SSBDefs.A_BUTTON, true, 0],
	"fair":   [[0, 0], [60, 0], SSBDefs.A_BUTTON, true, 0],
	"bair":   [[0, 0], [-60, 0], SSBDefs.A_BUTTON, true, 0],
	"uair":   [[0, 0], [0, 60], SSBDefs.A_BUTTON, true, 0],
	"dair":   [[0, 0], [0, -60], SSBDefs.A_BUTTON, true, 0],
}

var runner: BattleRunner

func _start(fkind: int) -> void:
	var cfg := BattleRunner.default_config()
	cfg.gkind = SSBDefs.nGRKindPupupu
	cfg.items_on = false
	cfg.players[0].fkind = fkind
	cfg.players[0].pkind = SSBDefs.nFTPlayerKindMan
	cfg.players[1].pkind = SSBDefs.nFTPlayerKindNot
	cfg.players[2].pkind = SSBDefs.nFTPlayerKindNot
	cfg.players[3].pkind = SSBDefs.nFTPlayerKindNot
	cfg.players[1].fkind = SSBDefs.nFTKindMario
	# a dummy second player so the battle can run (human, never presses anything)
	cfg.players[1].pkind = SSBDefs.nFTPlayerKindMan
	runner = BattleRunner.new()
	InputMapper.scripted.clear()
	InputMapper.scripted[0] = {"button": 0, "stick": Vector2i.ZERO}
	InputMapper.scripted[1] = {"button": 0, "stick": Vector2i.ZERO}
	runner.start(cfg)
	# wait for GO + idle
	for i in 480:
		runner.step()

func _p1() -> Fighter:
	for f in Sim.get_link(SSBDefs.nGCCommonLinkIDFighter):
		if f.player == 0:
			return f
	return null

func _step_input(button: int, stick: Vector2i) -> void:
	InputMapper.scripted[0] = {"button": button, "stick": stick}
	runner.step()

func _wait_idle(fp: Fighter, max_frames: int = 240) -> void:
	for i in max_frames:
		_step_input(0, Vector2i.ZERO)
		if fp.status_id == SSBDefs.nFTCommonStatusWait and fp.ga == SSBDefs.nMPKineticsGround:
			return

func _measure(name: String, spec: Array) -> Dictionary:
	var fp := _p1()
	_wait_idle(fp)
	if spec[3]:
		# jump (short hop is not needed: full hop, then attack near the apex)
		_step_input(SSBDefs.U_CBUTTONS, Vector2i.ZERO)
		for i in 12:
			_step_input(0, Vector2i.ZERO)
	var setup: Array = spec[0]
	for i in int(spec[4]):
		_step_input(0, Vector2i(setup[0], setup[1]))
	var press: Array = spec[1]
	var status_at_press := -1
	var active := []
	var params := {}
	var frame := 0
	_step_input(spec[2], Vector2i(press[0], press[1]))
	status_at_press = fp.status_id
	var motion := fp.motion_id
	var total := 0
	while frame < 90:
		var any := false
		for i in fp.attack_colls.size():
			var ac: FTAttackColl = fp.attack_colls[i]
			if ac.attack_state != SSBDefs.nGMAttackStateOff:
				any = true
				var key := "hb%d" % i
				if not params.has(key):
					params[key] = {"damage": ac.damage, "angle": ac.angle, "kbg": ac.knockback_scale, "bkb": ac.knockback_base,
						"wkb": ac.knockback_weight, "size": ac.size, "joint": ac.joint_id, "element": ac.element}
		if any:
			active.append(frame + 1)
		frame += 1
		if fp.status_id != status_at_press and frame > 1:
			total = frame
			break
		_step_input(0, Vector2i.ZERO)
	if total == 0:
		total = frame
	# compress active frames into ranges
	var ranges := []
	for f in active:
		if ranges.is_empty() or ranges[-1][1] != f - 1:
			ranges.append([f, f])
		else:
			ranges[-1][1] = f
	return {"move": name, "status": status_at_press, "motion": motion, "active_frames": ranges, "status_frames": total, "hitboxes": params}

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var kinds := []
	for a in args:
		kinds.append(int(a))
	if kinds.is_empty():
		kinds = range(12)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://").path_join("../evidence/framedata"))
	for fk in kinds:
		_start(fk)
		var fp := _p1()
		var out := {"fkind": fk, "fighter": fp.name_key, "moves": []}
		for name in MOVES:
			out.moves.append(_measure(name, MOVES[name]))
		var path := ProjectSettings.globalize_path("res://").path_join("../evidence/framedata/framedata_%s.json" % fp.name_key)
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify(out, "  "))
		f.close()
		var line := fp.name_key + ":"
		for m in out.moves:
			line += " %s=%s" % [m.move, str(m.active_frames)]
		print(line)
	quit(0)
