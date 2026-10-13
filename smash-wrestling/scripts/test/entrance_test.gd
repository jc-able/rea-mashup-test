extends Node
## Captures every part of a fighter's recovered SvR entrance (screenshot at 50% of each part) for evidence.
## usage: Godot --path game --resolution 1280x720 -- test=entrance_test kinds=mario,donkey out=/abs/dir
## Written in this run.

var out_dir := "user://entrance_test"
var kinds := []
var m: Match
var log := []


func _ready() -> void:
	out_dir = Game.args.get("out", out_dir)
	kinds = Array(String(Game.args.get("kinds", "mario")).split(","))
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()


func _run() -> void:
	for k in kinds:
		m = Match.new()
		add_child(m)
		m.entrance_only_p1 = true
		m.setup({"p1": k, "p2": "kirby" if k != "kirby" else "mario", "p1_cpu": true, "p2_cpu": true, "entrances": true, "seed": 1})
		m.entrance.part_started.connect(_on_part)
		await m.entrance.finished_all
		await get_tree().create_timer(1.0).timeout
		get_viewport().get_texture().get_image().save_png("%s/%s_9_bell.png" % [out_dir, k])
		log.append("%s entrance done (%s)" % [k, "\n".join(m.entrance.log_lines)])
		m.queue_free()
		await get_tree().process_frame
	var f := FileAccess.open(out_dir + "/entrance_test_log.txt", FileAccess.WRITE)
	f.store_string("\n".join(log))
	f.close()
	print("ENTRANCES DONE ", kinds)
	get_tree().quit()


func _on_part(kind: String, part: String, frames: int) -> void:
	var idx := ["intro", "stage", "ramp", "ringin", "inring"].find(part)
	await get_tree().create_timer(frames / 30.0 * 0.5).timeout
	if is_instance_valid(m):
		get_viewport().get_texture().get_image().save_png("%s/%s_%d_%s.png" % [out_dir, kind, idx, part])
