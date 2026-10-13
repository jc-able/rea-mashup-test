## Captures menu pages of the real main scene (Settings, Controls) for evidence/ui.
##   Godot --path game -s res://scripts/test/test_ui_shots.gd -- out=<dir>
extends SceneTree

var main: Node
var out := ""

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			out = a.substr(4)
	main = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	_run.call_deferred()

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name))

func _run() -> void:
	for page in ["settings", "controls"]:
		for i in 30:
			await process_frame
		main.goto(page)
		await create_timer(1.0).timeout
		await _shot("anim_toggle_%s.png" % page)
	quit(0)
