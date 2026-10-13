extends Node
## Main scene: hands the screen stack to the Game autoload.


func _ready() -> void:
	Game.main = self
	if Game.args.has("test"):
		var scr = load("res://scripts/test/%s.gd" % Game.args["test"])
		if scr == null or not scr.can_instantiate():
			push_error("test script failed to load")
			get_tree().quit(2)
			return
		var t = scr.new()
		Game.current = t
		add_child(t)
	elif Game.args.get("autostart", "0") == "1":
		Game.start_match()
	else:
		Game.goto_title()
