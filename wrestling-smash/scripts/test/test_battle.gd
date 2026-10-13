## Headless integration test of a VS battle using the ported engine (init order of
## scVSBattleStartBattle, then gcRunAll per frame). Scripted inputs drive P1.
##   Godot --headless --path game_check -s res://scripts/test/test_battle.gd -- [gkind] [fkind1] [fkind2] [frames]
extends SceneTree

var frames := 900
var log_every := 60
var log_from := -1
var log_to := -1

func _init_battle(gkind: int, fk1: int, fk2: int) -> void:
	Sim.reset()
	var st := G.SCBattleState.new()
	st.game_type = SSBDefs.nSCBattleGameTypeRoyal
	st.gkind = gkind
	st.game_rules = SSBDefs.SCBATTLE_GAMERULE_STOCK
	st.stocks = 2
	st.time_limit = SSBDefs.SCBATTLE_TIMELIMIT_INFINITE
	st.damage_ratio = 100
	st.item_appearance_rate = 0
	st.item_toggles = 0
	st.pl_count = 1
	st.cp_count = 1
	var p0: G.SCPlayerData = st.players[0]
	p0.pkind = SSBDefs.nFTPlayerKindMan
	p0.fkind = fk1
	p0.player = 0
	p0.level = 3
	var p1: G.SCPlayerData = st.players[1]
	p1.pkind = SSBDefs.nFTPlayerKindCom
	p1.fkind = fk2
	p1.player = 1
	p1.level = 9
	G.reset_battle(st)
	G.gSCManagerSceneData.gkind = gkind
	Controller.syControllerInitDevices()

	Ftparam.ftParamInitGame()
	Mpcollision.mpCollisionInitGroundData()
	Gmcamera.gmCameraSetViewportDimensions(10, 10, 310, 230)
	Gmcamera.gmCameraMakeWallpaperCamera()
	Grwallpaper.grWallpaperMakeDecideKind()
	Gmcamera.gmCameraMakeBattleCamera()
	Itmanager.itManagerInitItems()
	Grcommonsetup.grCommonSetupInitAll()
	Ftmanager.ftManagerAllocFighter(SSBDefs.FTDATA_FLAG_MAINMOTION, 4)
	Wpmanager.wpManagerAllocWeapons()
	for player in 4:
		var sp: G.SCPlayerData = st.players[player]
		if sp.pkind == SSBDefs.nFTPlayerKindNot:
			continue
		var desc := Ftmanager.default_desc()
		desc.fkind = sp.fkind
		desc.pos = Mpcollision.mpCollisionGetPlayerMapObjPosition(player)
		desc.lr = 1 if player == 0 else -1
		desc.team = sp.player
		desc.player = player
		desc.detail = SSBDefs.nFTPartsDetailHigh
		desc.costume = 0
		desc.handicap = 9
		desc.level = sp.level
		desc.stock_count = st.stocks
		desc.damage = 0
		desc.pkind = sp.pkind
		desc.controller = Controller.gSYControllerDevices[player]
		var fgobj = Ftmanager.ftManagerMakeFighter(desc)
		Ftparam.ftParamInitPlayerBattleStats(player, fgobj)
	st.game_status = SSBDefs.nSCBattleGameStatusGo
	# The VS interface (ifCommonEntryFocusThread) starts each fighter's appear sequence; emulate it.
	for fgobj in Sim.get_link(SSBDefs.nGCCommonLinkIDFighter):
		Ftcommonentry.ftCommonAppearSetStatus(fgobj)
		Ftparam.ftParamUnlockPlayerControl(fgobj)

## P1 script: (frame_from, frame_to, buttons, stick)
var script_inputs := [
	[0, 120, 0, Vector2i(0, 0)],
	[120, 180, 0, Vector2i(40, 0)],      # walk right
	[180, 240, 0, Vector2i(80, 0)],      # dash/run right
	[240, 250, SSBDefs.U_CBUTTONS, Vector2i(0, 0)],  # jump
	[250, 300, 0, Vector2i(0, 0)],
	[300, 302, SSBDefs.A_BUTTON, Vector2i(0, 0)],    # jab
	[302, 330, 0, Vector2i(0, 0)],
	[330, 332, SSBDefs.A_BUTTON, Vector2i(80, 0)],   # smash
	[332, 400, 0, Vector2i(0, 0)],
	[400, 402, SSBDefs.B_BUTTON, Vector2i(0, 0)],    # special
	[402, 480, 0, Vector2i(0, 0)],
	[520, 523, SSBDefs.Z_TRIG, Vector2i(80, 0)],     # roll forward out of shield
	[480, 560, SSBDefs.Z_TRIG, Vector2i(0, 0)],      # shield
	[560, 600, 0, Vector2i(-80, 0)],
	[600, 602, SSBDefs.U_CBUTTONS, Vector2i(0, 0)],
	[602, 612, 0, Vector2i(0, 0)],
	[612, 614, SSBDefs.A_BUTTON, Vector2i(0, 60)],   # up air
]

func _p1_input(frame: int) -> Dictionary:
	for s in script_inputs:
		if frame >= s[0] and frame < s[1]:
			return {"button": s[2], "stick": s[3]}
	return {"button": 0, "stick": Vector2i.ZERO}

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var gkind := int(args[0]) if args.size() > 0 else SSBDefs.nGRKindCastle
	var fk1 := int(args[1]) if args.size() > 1 else SSBDefs.nFTKindMario
	var fk2 := int(args[2]) if args.size() > 2 else SSBDefs.nFTKindDonkey
	if args.size() > 3:
		frames = int(args[3])
	if args.size() > 5:
		log_from = int(args[4])
		log_to = int(args[5])
	var t0 := Time.get_ticks_msec()
	_init_battle(gkind, fk1, fk2)
	print("init ok in %d ms; fighters=%d" % [Time.get_ticks_msec() - t0, Sim.get_link(SSBDefs.nGCCommonLinkIDFighter).size()])
	t0 = Time.get_ticks_msec()
	for f in frames:
		InputMapper.scripted[0] = _p1_input(f)
		InputMapper.poll()
		Controller.port_poll_frame()
		Sim.run_frame()
		if f % log_every == 0 or f == frames - 1 or (f >= log_from and f <= log_to):
			var line := "f%4d" % f
			for fgobj in Sim.get_link(SSBDefs.nGCCommonLinkIDFighter):
				var fp: Fighter = fgobj
				var t: Vector3 = fp.dobj.translate
				line += " | P%d %s st=%d mo=%d pos=(%.1f,%.1f) ga=%d dmg=%d lr=%d" % [fp.player + 1, fp.name_key, fp.status_id, fp.motion_id, t.x, t.y, fp.ga, fp.percent_damage, fp.lr]
			print(line)
	var ms := Time.get_ticks_msec() - t0
	print("ran %d frames in %d ms (%.2f ms/frame)" % [frames, ms, float(ms) / frames])
	var stubs: Array = StubLog.seen.keys()
	stubs.sort()
	print("stubs hit (%d): %s" % [stubs.size(), ", ".join(stubs.slice(0, 60))])
	quit(0)
