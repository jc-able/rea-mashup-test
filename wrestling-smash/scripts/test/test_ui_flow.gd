## Windowed front-end flow test: drives res://scenes/Main.tscn with synthetic physical key
## presses (keyboard 1 = WASD/J/K/Enter, keyboard 2 = arrows/,/.) and saves a screenshot of
## each page to <workspace>/evidence/ui/. Run (windowed, not headless):
##   Godot --path <project> -s res://scripts/test/test_ui_flow.gd [-- --prefix=1080p_]
extends SceneTree

var out_dir := ""
var prefix := ""
var main: Node

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--prefix="):
			prefix = a.substr(9)
	out_dir = ProjectSettings.globalize_path("res://").path_join("../evidence/ui").simplify_path()
	DirAccess.make_dir_recursive_absolute(out_dir)
	main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	_run()

func _wait(t: float) -> void:
	await create_timer(t).timeout

func _key(code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	Input.parse_input_event(e)
	await _wait(0.06)
	var u := e.duplicate() as InputEventKey
	u.pressed = false
	Input.parse_input_event(u)
	await _wait(0.1)

func _keys(codes: Array) -> void:
	for c in codes:
		await _key(c)

func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var path := out_dir.path_join(prefix + shot_name + ".png")
	img.save_png(path)
	print("SHOT ", path, " ", img.get_size(), " page=", main.call("current_screen_name"))

func _run() -> void:
	await _wait(1.2)
	await _shot("01_title")
	if prefix != "":
		await _key(KEY_ENTER)
		await _wait(0.4)
		await _key(KEY_J)                                  # VS MODE
		await _wait(0.6)
		await _key(KEY_ENTER)                              # rules -> character select
		await _wait(0.6)
		await _keys([KEY_D, KEY_J, KEY_COMMA])             # P1 picks, keyboard 2 joins as P2
		await _wait(0.2)
		await _keys([KEY_LEFT, KEY_COMMA])
		await _wait(1.2)
		await _shot("06_css")
		quit()
		return
	await _key(KEY_ENTER)                                  # PRESS START -> menu
	await _wait(0.5)
	await _shot("02_title_menu")
	await _keys([KEY_S, KEY_J])                            # CONTROLS
	await _wait(0.6)
	await _shot("03_controls")
	await _key(KEY_ESCAPE)
	await _wait(0.6)
	await _keys([KEY_S, KEY_S, KEY_J])                     # SETTINGS
	await _wait(0.6)
	await _keys([KEY_S, KEY_S, KEY_D])                     # show hitboxes ON
	await _shot("04_settings")
	await _key(KEY_ESCAPE)
	await _wait(0.6)
	await _key(KEY_J)                                      # VS MODE -> rules
	await _wait(0.6)
	await _keys([KEY_S, KEY_D, KEY_D, KEY_S, KEY_S, KEY_S, KEY_D])   # 5 stocks, items HIGH
	await _shot("05_rules")
	await _key(KEY_ENTER)                                  # START -> character select
	await _wait(0.7)
	await _keys([KEY_D, KEY_D, KEY_D, KEY_J])              # P1 picks card 3
	await _key(KEY_COMMA)                                  # keyboard 2 joins (P2)
	await _wait(0.2)
	await _keys([KEY_RIGHT, KEY_DOWN, KEY_RIGHT, KEY_COMMA])   # P2 picks
	await _keys([KEY_S, KEY_S, KEY_J])                     # P1: into P3's panel, type N/A -> CPU
	await _keys([KEY_S, KEY_S, KEY_D, KEY_D, KEY_D, KEY_D])    # P3 CPU level 3 -> 7
	await _keys([KEY_W, KEY_W, KEY_W])                     # back to the grid
	await _wait(1.6)
	await _shot("06_css")
	await _key(KEY_ENTER)                                  # ready -> stage select
	await _wait(0.7)
	await _keys([KEY_S, KEY_A])
	await _wait(0.3)
	await _shot("07_stage_select")
	await _key(KEY_J)                                      # fight -> VS splash
	await _wait(0.7)
	await _shot("08_vs_splash")
	await _wait(2.0)
	await _shot("09_battle_or_missing")
	print("PAGE after launch: ", main.call("current_screen_name"))
	var battle = main.get("_battle")
	if battle != null and battle.has_signal("battle_finished"):
		# results in the engine's port_compute_results() shape (mnvsresults.c data)
		var pl := []
		for i in 4:
			var p: Dictionary = main.get("last_config").players[i]
			var on: bool = int(p.pkind) != 2
			pl.append({"present": on, "pkind": p.pkind, "fkind": p.fkind, "team": p.team, "place": [1, 0, 2, 3][i],
				"kos": [2, 4, 1, 0][i], "tko": [4, 1, 5, 0][i], "falls": [4, 1, 5, 0][i], "points": 0,
				"total_selfdestructs": [1, 0, 2, 0][i], "total_damage_given": [212, 341, 97, 0][i], "total_damage_all": [301, 156, 388, 0][i]})
		battle.emit_signal("battle_finished", {"kind_name": "stock_royal", "is_team_battle": false, "is_no_contest": false, "win_player": 1, "players": pl})
		await _wait(1.0)
		await _shot("10_results")
		await _key(KEY_ENTER)                              # continue -> character select
		await _wait(0.8)
		await _shot("11_css_after_results")
		main.set("battle_scene_path", "res://scenes/__missing__.tscn")
		await _key(KEY_ENTER)                              # ready -> stage select
		await _wait(0.7)
		await _key(KEY_J)
		await _wait(3.0)
		await _shot("12_battle_missing_page")
		await _key(KEY_J)                                  # SIMULATE RESULTS
		await _wait(0.8)
		await _shot("13_simulated_results")
	print("CONFIG ", main.get("last_config"))
	quit()
