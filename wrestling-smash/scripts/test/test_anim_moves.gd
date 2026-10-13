## Exercises both animation sets in the running game: one wrestler performs each move with controller
## input (like a player), once with the SvR 2011 set and once with the SMASH 64 set, and the frame at the
## start, at the SSB64 hit frame (throws: release frame) and in the recovery is captured, together with
## the animation provenance (role / clip / move). A dummy opponent stands next to the performer for
## grabs and throws. Rendered window required (captures).
##   Godot --path game --fixed-fps 60 --resolution 1280x720 -s res://scripts/test/test_anim_moves.gd -- fkind=0 out=<dir> [moves=jab1,fsmash,...]
extends SceneTree

const SsbTiming = preload("res://scripts/render/SsbTiming.gd")
const SvrAnimMap = preload("res://scripts/render/SvrAnimMap.gd")

## name: [setup stick (x, y), setup frames, press stick, button, airborne]
const MOVES := {
	"jab1": [[0, 0], 0, [0, 0], SSBDefs.A_BUTTON, false],
	"ftilt": [[40, 0], 6, [40, 0], SSBDefs.A_BUTTON, false],
	"utilt": [[0, 40], 6, [0, 40], SSBDefs.A_BUTTON, false],
	"dtilt": [[0, -40], 6, [0, -40], SSBDefs.A_BUTTON, false],
	"dash_attack": [[80, 0], 14, [80, 0], SSBDefs.A_BUTTON, false],
	"fsmash": [[0, 0], 0, [80, 0], SSBDefs.A_BUTTON, false],
	"usmash": [[0, 0], 0, [0, 80], SSBDefs.A_BUTTON, false],
	"dsmash": [[0, 0], 0, [0, -80], SSBDefs.A_BUTTON, false],
	"nair": [[0, 0], 0, [0, 0], SSBDefs.A_BUTTON, true],
	"fair": [[0, 0], 0, [60, 0], SSBDefs.A_BUTTON, true],
	"bair": [[0, 0], 0, [-60, 0], SSBDefs.A_BUTTON, true],
	"uair": [[0, 0], 0, [0, 60], SSBDefs.A_BUTTON, true],
	"dair": [[0, 0], 0, [0, -60], SSBDefs.A_BUTTON, true],
	"special_n": [[0, 0], 0, [0, 0], SSBDefs.B_BUTTON, false],
	"special_lw": [[0, 0], 0, [0, -60], SSBDefs.B_BUTTON, false],
	"special_hi": [[0, 0], 0, [0, 60], SSBDefs.B_BUTTON, false],
	"taunt": [[0, 0], 0, [0, 0], SSBDefs.L_TRIG, false],
	"throw_f": [[0, 0], 0, [0, 0], SSBDefs.R_TRIG, false],
	"throw_b": [[0, 0], 0, [0, 0], SSBDefs.R_TRIG, false],
}

var battle: Node
var fkind := 0
var out_dir := ""
var moves: Array = []
var log_lines: PackedStringArray = []
var only_hit := false
var close_cam := false
var floor_y := 0.0

func _initialize() -> void:
	var o := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		o[kv[0]] = kv[1] if kv.size() > 1 else "1"
	fkind = int(o.get("fkind", "0"))
	out_dir = str(o.get("out", ProjectSettings.globalize_path("user://anim_moves")))
	DirAccess.make_dir_recursive_absolute(out_dir)
	moves = str(o.get("moves", ",".join(MOVES.keys()))).split(",")
	only_hit = str(o.get("only", "")) == "hit"
	close_cam = str(o.get("cam", "")) == "close"
	var cfg := BattleRunner.default_config()
	cfg.gkind = int(o.get("stage", str(SSBDefs.nGRKindPupupu)))
	cfg.items_on = false
	cfg.is_stock = true
	cfg.stocks = 99
	cfg.players[0].fkind = fkind
	cfg.players[1].fkind = int(o.get("opp", "8" if fkind != 8 else "9"))
	for i in 2:
		cfg.players[i].pkind = SSBDefs.nFTPlayerKindMan
	cfg["anim_set"] = "svr"
	InputMapper.scripted.clear()
	InputMapper.scripted[0] = {"button": 0, "stick": Vector2i.ZERO}
	InputMapper.scripted[1] = {"button": 0, "stick": Vector2i.ZERO}
	var ps: PackedScene = load("res://scenes/Battle.tscn")
	battle = ps.instantiate()
	battle.setup(cfg)
	root.add_child(battle)
	_run.call_deferred()

func _p(i: int):
	for g in Sim.get_link(SSBDefs.nGCCommonLinkIDFighter):
		if g.player == i:
			return g
	return null

func _frame() -> void:
	await physics_frame
	await process_frame

func _step(button: int, stick: Vector2i) -> void:
	InputMapper.scripted[0] = {"button": button, "stick": stick}
	await _frame()

## drop from platforms until the fighter stands idle on the main floor (down + attack on a platform
## would fall through it instead of doing a down smash)
func _on_floor(fp) -> void:
	for k in 4:
		await _idle(fp)
		if fp.dobj.translate.y <= floor_y + 50.0:
			return
		for i in 3:
			await _step(0, Vector2i(0, -80))
		for i in 90:
			await _step(0, Vector2i.ZERO)
			if fp.ga == SSBDefs.nMPKineticsGround and fp.dobj.translate.y <= floor_y + 50.0:
				break

func _idle(fp, max_frames := 240) -> void:
	for i in max_frames:
		await _step(0, Vector2i.ZERO)
		if fp.status_id == SSBDefs.nFTCommonStatusWait and fp.ga == SSBDefs.nMPKineticsGround:
			return

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))

func _set_mode(svr: bool) -> void:
	if (battle.anim_set == 1) != svr:
		battle.toggle_anim_set()

## wait until the dummy stands idle on the main floor (respawned, dropped from platforms)
func _ready_dummy(fp, opp) -> void:
	InputMapper.scripted[1] = {"button": 0, "stick": Vector2i.ZERO}
	for i in 900:
		await _frame()
		var grounded: bool = opp.ga == SSBDefs.nMPKineticsGround and opp.status_id == SSBDefs.nFTCommonStatusWait
		if grounded and absf(opp.dobj.translate.y - fp.dobj.translate.y) < 50.0:
			return
		if grounded and opp.dobj.translate.y > fp.dobj.translate.y + 50.0:
			InputMapper.scripted[1] = {"button": 0, "stick": Vector2i(0, -80)}
			for k in 3:
				await _frame()
			InputMapper.scripted[1] = {"button": 0, "stick": Vector2i.ZERO}

func _walk_to(f, idx: int, target_x: float) -> void:
	for i in 900:
		var dx: float = target_x - f.dobj.translate.x
		if absf(dx) < 25.0 and f.ga == SSBDefs.nMPKineticsGround:
			break
		var sp := 50 if absf(dx) > 400.0 else 32
		InputMapper.scripted[idx] = {"button": 0, "stick": Vector2i(sp if dx > 0 else -sp, 0)}
		await _frame()
	InputMapper.scripted[idx] = {"button": 0, "stick": Vector2i.ZERO}

## approach the dummy and face it (for "hit_<move>": the move is performed on the opponent)
func _face_dummy(fp, opp) -> void:
	await _ready_dummy(fp, opp)
	# dummy to the middle of the stage, so pushes and knock-backs do not reach an edge
	await _walk_to(opp, 1, 0.0)
	await _ready_dummy(fp, opp)
	for i in 600:
		var dx: float = opp.dobj.translate.x - fp.dobj.translate.x
		if absf(dx) < 200.0:
			break
		await _step(0, Vector2i(30 if dx > 0 else -30, 0))
	await _idle(fp)
	var want := 1 if opp.dobj.translate.x > fp.dobj.translate.x else -1
	for k in 4:
		if int(fp.lr) == want:
			break
		for i in 4:
			await _step(0, Vector2i(40 * want, 0))
		for i in 24:
			await _step(0, Vector2i.ZERO)
	await _idle(fp)

## approach the dummy, face it and grab while walking in; retries until the grab connects
func _grab(fp, opp) -> bool:
	for attempt in 8:
		await _ready_dummy(fp, opp)
		for i in 600:
			var dx: float = opp.dobj.translate.x - fp.dobj.translate.x
			if absf(dx) < 210.0:
				break
			await _step(0, Vector2i(40 if dx > 0 else -40, 0))
		await _idle(fp)
		var want := 1 if opp.dobj.translate.x > fp.dobj.translate.x else -1
		for k in 4:
			if int(fp.lr) == want:
				break
			for i in 4:
				await _step(0, Vector2i(40 * want, 0))
			for i in 24:
				await _step(0, Vector2i.ZERO)
		await _idle(fp)
		for i in 6:
			await _step(0, Vector2i(25 * int(fp.lr), 0))
		await _step(SSBDefs.R_TRIG, Vector2i(25 * int(fp.lr), 0))
		for i in 40:
			await _step(0, Vector2i.ZERO)
			if fp.status_id == SSBDefs.nFTCommonStatusCatchWait:
				print("grab: attempt %d connected" % (attempt + 1))
				return true
		await _idle(fp)
	print("grab: failed")
	return false

func _run() -> void:
	for i in 480:
		await _frame()
	var fp = _p(0)
	var opp = _p(1)
	if close_cam:
		battle.cam_follow = fp
		battle.cam_mode = 2
	floor_y = minf(fp.dobj.translate.y, opp.dobj.translate.y)
	# the dummy may spawn on a platform: drop through it (tap down) and let it land on the main floor
	for k in 3:
		if absf(opp.dobj.translate.y - fp.dobj.translate.y) < 50.0:
			break
		InputMapper.scripted[1] = {"button": 0, "stick": Vector2i(0, -80)}
		for i in 3:
			await _frame()
		InputMapper.scripted[1] = {"button": 0, "stick": Vector2i.ZERO}
		for i in 90:
			await _frame()
	print("dummy at y %.0f, performer at y %.0f" % [opp.dobj.translate.y, fp.dobj.translate.y])
	for full in moves:
		var on_opp := str(full).begins_with("hit_")
		var name := str(full).trim_prefix("hit_")
		if not MOVES.has(name):
			continue
		for mode in ["svr", "smash"]:
			_set_mode(mode == "svr")
			await _on_floor(fp)
			var spec: Array = MOVES[name]
			if name.begins_with("throw"):
				if not await _grab(fp, opp):
					continue
			elif on_opp:
				await _face_dummy(fp, opp)
			if spec[4]:
				await _step(SSBDefs.U_CBUTTONS, Vector2i.ZERO)
				for i in 10:
					await _step(0, Vector2i.ZERO)
			# stick x in MOVES means "forward": relative to the way the fighter faces
			var face := int(fp.lr)
			var setup: Array = spec[0]
			for i in int(spec[1]):
				await _step(0, Vector2i(setup[0] * face, setup[1]))
			var press: Array = [spec[2][0] * face, spec[2][1]]
			var st: int = fp.status_id
			var mi: Dictionary = {}
			if not name.begins_with("throw"):
				await _step(spec[3], Vector2i(press[0], press[1]))
				# make sure the intended move started (an input can land during a landing / turn)
				for retry in 3:
					if SvrAnimMap.role_for(int(fp.fkind), int(fp.status_id)) == name or name == "taunt" and fp.status_id == SSBDefs.nFTCommonStatusAppeal:
						break
					await _idle(fp)
					if spec[4]:
						await _step(SSBDefs.U_CBUTTONS, Vector2i.ZERO)
						for i in 10:
							await _step(0, Vector2i.ZERO)
					await _step(spec[3], Vector2i(press[0], press[1]))
				st = fp.status_id
				mi = SsbTiming.motion_info(fp, fp.motion_id)
			else:
				# holding the opponent (CatchWait): throw forward / back
				var dirx: int = (80 if name == "throw_f" else -80) * int(fp.lr)
				await _step(0, Vector2i(dirx, 0))
				st = fp.status_id
				mi = SsbTiming.motion_info(fp, fp.motion_id)
			var hit: float = mi.hit_first
			if name.begins_with("throw") and float(mi.get("flag2", -1.0)) > 0.0:
				hit = mi.flag2
			var L: float = maxf(mi.length, 10.0)
			var marks := {1: "start", int(maxf(hit, L * 0.35)): "hit", int(L * 0.8): "late"}
			if only_hit:
				marks = {int(maxf(hit, L * 0.35)): "hit"}
			var f := 1
			var keys: Array = marks.keys()
			keys.sort()
			for k in keys:
				while f < k:
					await _step(0, Vector2i.ZERO)
					f += 1
				var tag := "%s_%s_%s" % [full, mode, marks[k]]
				await _shot("%s_%s" % [battle.fighters[fp].slug, tag])
				var d: Dictionary = battle.fighters[fp].anim_info()
				var line := "%s %-12s %-6s %-5s f%-3d status %d anim_frame %.1f role %s clip %s move %s origin %s" % [battle.fighters[fp].slug, full, mode,
					marks[k], k, fp.status_id, fp.anim_frame, d.get("role", ""), d.get("clip", ""), d.get("move", ""), d.get("origin", "")]
				if name.begins_with("throw") or on_opp:
					var dv: Dictionary = battle.fighters[opp].anim_info()
					line += "   opponent: status %d %d%% role %s clip %s move %s" % [opp.status_id, opp.percent_damage, dv.get("role", ""), dv.get("clip", ""), dv.get("move", "")]
				log_lines.append(line)
				print(line)
			for i in 90:
				await _step(0, Vector2i.ZERO)
				if fp.status_id != st and fp.status_id == SSBDefs.nFTCommonStatusWait:
					break
	var fa := FileAccess.open(out_dir.path_join("moves_%d.txt" % fkind), FileAccess.WRITE)
	fa.store_string("\n".join(log_lines) + "\n")
	fa.close()
	quit(0)
