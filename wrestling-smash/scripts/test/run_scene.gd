## Runs a scene *script* (Node subclass) as the main scene from the check harness, which has a valid
## global class cache (the editor's W/game/.godot cache may be stale). Example:
##   Godot --path game_check --resolution 1280x720 -s res://scripts/test/run_scene.gd -- script=res://scripts/app/BattleScene.gd gkind=6 ...
## All user args are also visible to the scene (OS.get_cmdline_user_args()).
extends SceneTree

func _initialize() -> void:
	var path := "res://scripts/app/BattleScene.gd"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("script="):
			path = a.substr(7)
	var scr = load(path)
	if scr == null:
		push_error("cannot load " + path)
		quit(1)
		return
	var n: Node = scr.new()
	n.name = path.get_file().get_basename()
	root.add_child(n)
