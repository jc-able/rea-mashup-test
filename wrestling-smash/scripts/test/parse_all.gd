## Headless parse check: loads every script under res://scripts and reports failures.
extends SceneTree

func _init() -> void:
	var bad := 0
	var count := 0
	var stack := ["res://scripts"]
	while not stack.is_empty():
		var dir: String = stack.pop_back()
		for d in DirAccess.get_directories_at(dir):
			stack.append(dir + "/" + d)
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd"):
				count += 1
				var s = load(dir + "/" + f)
				if s == null or not s.can_instantiate():
					bad += 1
					print("PARSE FAIL: ", dir + "/" + f)
	print("checked %d scripts, %d failed" % [count, bad])
	quit(1 if bad else 0)
