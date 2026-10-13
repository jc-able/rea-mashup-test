## Proof that the animation set (SSB64 retarget vs SvR 2011 motions) changes presentation only.
## Runs the real Battle scene (renderer included) for a fixed number of engine frames from a fixed
## RNG seed and writes one fingerprint per engine frame of everything gameplay depends on:
## the RNG seed, every fighter's status / motion / anim frame / position / velocity / damage /
## hit-lag / shield / stocks / hitbox states, and every item and weapon position.
## Run it once per mode (separate processes) and compare the files, e.g.
##   Godot --headless --fixed-fps 60 --path game -s res://scripts/test/test_anim_parity.gd -- mode=smash out=a.txt
##   Godot --headless --fixed-fps 60 --path game -s res://scripts/test/test_anim_parity.gd -- mode=svr toggle=97 out=b.txt
## (toggle=N presses F4 every N frames). It also counts how many fighter-frames the SvR clips drove.
extends SceneTree

var battle: Node
var frames := 1800
var toggle_every := 0
var out_path := "user://parity.txt"
var lines: PackedStringArray = []
var last_frame := -1
var svr_frames := 0
var fallback_frames := 0
var roles_svr := {}
var roles_fb := {}

func _initialize() -> void:
	var opts := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		opts[kv[0]] = kv[1] if kv.size() > 1 else "1"
	frames = int(opts.get("frames", "1800"))
	toggle_every = int(opts.get("toggle", "0"))
	out_path = str(opts.get("out", out_path))
	var cfg := BattleRunner.default_config()
	cfg.gkind = int(opts.get("gkind", str(SSBDefs.nGRKindPupupu)))
	cfg.is_stock = true
	cfg.stocks = 3
	cfg.items_on = int(opts.get("items", "1")) != 0
	for i in 4:
		cfg.players[i].pkind = SSBDefs.nFTPlayerKindNot
	var fks := str(opts.get("fighters", "0,7")).split(",")
	for i in fks.size():
		cfg.players[i].pkind = SSBDefs.nFTPlayerKindCom
		cfg.players[i].fkind = int(fks[i])
		cfg.players[i].level = 9
	cfg["anim_set"] = str(opts.get("mode", "smash"))
	Port.sSYUtilsRandomSeed = int(opts.get("seed", "20261011"))
	var ps: PackedScene = load("res://scenes/Battle.tscn")
	battle = ps.instantiate()
	battle.setup(cfg)
	root.add_child(battle)

func _process(_delta: float) -> bool:
	if battle == null or battle.runner == null:
		return false
	var f: int = battle.runner.frame
	if f != last_frame:
		last_frame = f
		lines.append("%d %s" % [f, _fingerprint()])
		_count_anim()
		if toggle_every > 0 and f > 0 and f % toggle_every == 0:
			battle.toggle_anim_set()
	if f >= frames:
		var fa := FileAccess.open(out_path, FileAccess.WRITE)
		fa.store_string("\n".join(lines) + "\n")
		fa.close()
		print("parity: %d frames written to %s  svr-driven fighter-frames %d, SSB64-fallback fighter-frames %d" % [lines.size(), out_path, svr_frames, fallback_frames])
		print("parity: SvR roles ", roles_svr)
		print("parity: fallback roles ", roles_fb)
		return true
	return false

func _count_anim() -> void:
	for g in battle.fighters:
		var d: Dictionary = battle.fighters[g].anim_info()
		if d.get("set", "") != "SvR 2011":
			continue
		var r := str(d.get("role", ""))
		if str(d.get("clip", "")) != "":
			svr_frames += 1
			roles_svr[r] = roles_svr.get(r, 0) + 1
		else:
			fallback_frames += 1
			roles_fb[r] = roles_fb.get(r, 0) + 1

func _v(v: Vector3) -> String:
	return "%.4f,%.4f,%.4f" % [v.x, v.y, v.z]

func _fingerprint() -> String:
	var parts := PackedStringArray()
	parts.append("rng=%d" % Port.sSYUtilsRandomSeed)
	for g in Sim.get_link(SSBDefs.nGCCommonLinkIDFighter):
		if not (g is Fighter):
			continue
		var fp: Fighter = g
		var pos := Vector3.ZERO
		if fp.dobj != null:
			pos = fp.dobj.translate
		var hb := ""
		for ac in fp.attack_colls:
			hb += str(int(ac.attack_state))
		parts.append("P%d:s%d,m%d,a%.3f,p%s,v%s/%s,d%d,h%d,lr%d,ga%d,sh%d,st%d,hb%s" % [fp.player, fp.status_id, fp.motion_id,
			fp.anim_frame, _v(pos), _v(fp.physics.vel_air), _v(fp.physics.vel_ground), fp.percent_damage, fp.hitlag_tics,
			fp.lr, fp.ga, fp.shield_health, fp.stock_count, hb])
	for link in [SSBDefs.nGCCommonLinkIDItem, SSBDefs.nGCCommonLinkIDWeapon]:
		for g in Sim.get_link(link):
			var d = g.get("dobj")
			parts.append("o%d:%s" % [int(g.get("kind")) if g.get("kind") != null else -1, _v(d.translate) if d != null else "-"])
	return " ".join(parts)
