## SvR 2011 animation set in real gameplay: two level-9 CPU wrestlers fight with the SvR set on; every
## time a wrestler starts showing a new (role, clip) — a strike, throw, special, aerial, an authored hit
## reaction, a paired grapple victim — the frame is captured (rate-limited) and logged with its provenance.
## The run also counts how many fighter-frames were driven by original SvR clips vs the SSB64 fallback.
##   Godot --path game --fixed-fps 60 --resolution 1280x720 -s res://scripts/test/test_svr_showcase.gd -- p1=0 p2=7 frames=3600 out=<dir>
extends SceneTree

var battle: Node
var out_dir := ""
var frames := 3600
var seen := {}
var last_shot := -100
var log_lines: PackedStringArray = []
var svr_frames := 0
var fb_frames := 0
var role_counts := {}
var fb_counts := {}

func _initialize() -> void:
	var o := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		o[kv[0]] = kv[1] if kv.size() > 1 else "1"
	out_dir = str(o.get("out", ProjectSettings.globalize_path("user://showcase")))
	frames = int(o.get("frames", "3600"))
	DirAccess.make_dir_recursive_absolute(out_dir)
	var cfg := BattleRunner.default_config()
	cfg.gkind = int(o.get("stage", str(SSBDefs.nGRKindPupupu)))
	cfg.items_on = false
	cfg.is_stock = true
	cfg.stocks = 99
	for i in 4:
		cfg.players[i].pkind = SSBDefs.nFTPlayerKindNot
	for i in 2:
		cfg.players[i].pkind = SSBDefs.nFTPlayerKindCom
		cfg.players[i].level = 9
	cfg.players[0].fkind = int(o.get("p1", "0"))
	cfg.players[1].fkind = int(o.get("p2", "7"))
	cfg["anim_set"] = "svr"
	Port.sSYUtilsRandomSeed = int(o.get("seed", "7"))
	var ps: PackedScene = load("res://scenes/Battle.tscn")
	battle = ps.instantiate()
	battle.setup(cfg)
	root.add_child(battle)

func _process(_d: float) -> bool:
	if battle == null or battle.runner == null:
		return false
	var f: int = battle.runner.frame
	if f >= frames:
		_finish()
		return true
	var shot_reason := ""
	for g in battle.fighters:
		var fr = battle.fighters[g]
		var d: Dictionary = fr.anim_info()
		var role := str(d.get("role", ""))
		if role == "":
			continue
		if str(d.get("clip", "")) != "":
			svr_frames += 1
			role_counts[role] = role_counts.get(role, 0) + 1
		else:
			fb_frames += 1
			fb_counts[role] = fb_counts.get(role, 0) + 1
			continue
		var key := "%s|%s|%s" % [fr.slug, role, d.get("clip", "")]
		if seen.has(key) or role in ["idle", "walk", "run", "run_start"]:
			continue
		seen[key] = f
		var line := "f%-5d %-14s %-12s %-16s %-40s %s" % [f, fr.slug, role, d.get("clip", ""), str(d.get("move", "")).left(40), d.get("source", "")]
		log_lines.append(line)
		print(line)
		if shot_reason == "":
			shot_reason = "%s_%s" % [fr.slug, role]
	if shot_reason != "" and f - last_shot >= 20:
		last_shot = f
		_shot("f%05d_%s" % [f, shot_reason])
	return false

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))

func _finish() -> void:
	var total := maxi(svr_frames + fb_frames, 1)
	var summary := "showcase: %d frames, fighter-frames driven by original SvR 2011 clips %d (%.1f%%), SSB64 fallback %d" % [frames, svr_frames, 100.0 * svr_frames / total, fb_frames]
	print(summary)
	print("SvR roles: ", role_counts)
	print("fallback roles: ", fb_counts)
	log_lines.append(summary)
	log_lines.append("SvR roles: " + str(role_counts))
	log_lines.append("fallback roles: " + str(fb_counts))
	var fa := FileAccess.open(out_dir.path_join("showcase_log.txt"), FileAccess.WRITE)
	fa.store_string("\n".join(log_lines) + "\n")
	fa.close()
