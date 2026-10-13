## Headless end-to-end battle through BattleRunner (ported scvsbattle + ifcommon flow).
##   Godot --headless --path game_check -s res://scripts/test/test_runner.gd -- [gkind] [fk1] [fk2] [minutes] [items 0/1] [max_frames]
extends SceneTree

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var cfg := BattleRunner.default_config()
	cfg.gkind = int(args[0]) if args.size() > 0 else SSBDefs.nGRKindCastle
	cfg.players[0].fkind = int(args[1]) if args.size() > 1 else SSBDefs.nFTKindMario
	cfg.players[1].fkind = int(args[2]) if args.size() > 2 else SSBDefs.nFTKindDonkey
	cfg.players[0].pkind = SSBDefs.nFTPlayerKindCom
	cfg.players[0].level = 9
	cfg.players[1].level = 9
	cfg.is_stock = false
	cfg.time_limit = int(args[3]) if args.size() > 3 else 1
	cfg.items_on = (int(args[4]) != 0) if args.size() > 4 else true
	var max_frames := int(args[5]) if args.size() > 5 else 5000
	var runner := BattleRunner.new()
	var t0 := Time.get_ticks_msec()
	runner.start(cfg)
	print("start ok (%d ms)" % (Time.get_ticks_msec() - t0))
	t0 = Time.get_ticks_msec()
	var items_seen := {}
	var weapons_seen := 0
	var f := 0
	while f < max_frames and not runner.is_finished():
		runner.step()
		for it in Sim.get_link(SSBDefs.nGCCommonLinkIDItem):
			items_seen[it.visual_kind] = items_seen.get(it.visual_kind, 0) + 1
		weapons_seen += Sim.get_link(SSBDefs.nGCCommonLinkIDWeapon).size()
		if f % 300 == 0:
			var line := "f%5d status=%d" % [f, G.gSCManagerBattleState.game_status]
			var ui = Ifcommon.ui
			if ui is Dictionary and ui.has("timer"):
				line += " timer=%s" % str(ui.timer.get("frames", ui.timer.get("seconds", "?")))
			for fgobj in Sim.get_link(SSBDefs.nGCCommonLinkIDFighter):
				var fp: Fighter = fgobj
				var t: Vector3 = fp.dobj.translate
				line += " | P%d %s st=%d pos=(%.0f,%.0f) dmg=%d stock=%d" % [fp.player + 1, fp.name_key, fp.status_id, t.x, t.y, fp.percent_damage, fp.stock_count]
			print(line)
		f += 1
	var ms := Time.get_ticks_msec() - t0
	print("frames=%d finished=%s (%.2f ms/frame)" % [f, str(runner.is_finished()), float(ms) / maxi(f, 1)])
	print("items seen (object-frames): ", items_seen)
	print("weapon object-frames: ", weapons_seen)
	var r: Dictionary = runner.results()
	print("results keys: ", r.keys())
	for k in ["placements", "kos", "tkos", "points", "win_player", "falls"]:
		if r.has(k):
			print("  ", k, " = ", r[k])
	var stubs: Array = StubLog.seen.keys()
	stubs.sort()
	print("stubs hit (%d): %s" % [stubs.size(), ", ".join(stubs)])
	quit(0)
