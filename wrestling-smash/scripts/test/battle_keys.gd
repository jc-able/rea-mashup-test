## Windowed check of the BattleScene hotkeys (F1/F2/F3/Esc) and its signals.
##   Godot --path game_check --resolution 1280x720 -s res://scripts/test/battle_keys.gd -- out=<png prefix>
extends SceneTree

var scene: Node
var quit_got := false

func _key(k: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := ev.duplicate()
	up.pressed = false
	Input.parse_input_event(up)

func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
	print("captured ", path)

func _initialize() -> void:
	var out := "user://keys"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			out = a.substr(4)
	scene = load("res://scripts/app/BattleScene.gd").new()
	var cfg := BattleRunner.default_config()
	cfg.gkind = SSBDefs.nGRKindPupupu
	cfg.players[0].pkind = SSBDefs.nFTPlayerKindCom
	scene.setup(cfg)
	scene.quit_requested.connect(func(): quit_got = true)
	root.add_child(scene)
	_run(out)

func _run(out: String) -> void:
	for i in 420:
		await process_frame
	_key(KEY_F1)
	_key(KEY_F3)
	for i in 30:
		await process_frame
	print("after F1/F3: debug_on=%s cam_mode=%d" % [scene.debug_on, scene.cam_mode])
	await _shot(out + "_f1_f3.png")
	_key(KEY_F1)
	_key(KEY_F3)
	_key(KEY_F2)
	for i in 30:
		await process_frame
	print("after F2: models_on=%s" % scene.models_on)
	_key(KEY_F2)
	_key(KEY_ESCAPE)
	for i in 10:
		await process_frame
	var f0: int = scene.runner.frame
	for i in 20:
		await process_frame
	print("quit menu open=%s frozen=%s frames advanced while open=%d" % [scene.quit_layer != null, scene.frozen, scene.runner.frame - f0])
	await _shot(out + "_quit_menu.png")
	scene._on_quit_yes()
	await process_frame
	print("quit_requested emitted=%s" % quit_got)
	quit(0)
