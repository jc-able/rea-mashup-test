extends Node
## Game flow (autoload "Game"): roster, selections, screen switching, rematch/restart, and command-line hooks
## used by the automated checks (all optional):
##   -- autostart=1 p1=mario p2=donkey p1cpu=0 p2cpu=1 entrances=0 difficulty=1 seed=7 timescale=1
##      quit_after=120 shots=/abs/dir shot_every=5 logdir=/abs/dir input_script=/abs/file.json verbose=1

var roster: Array = []
var by_kind := {}
var sel := {"p1": "mario", "p2": "donkey", "p1_cpu": false, "p2_cpu": true, "difficulty": 1, "entrances": true, "seed": 0,
	"arena": "smackdown"}
var last_result: Dictionary = {}
var args := {}
var verbose := false
var dmg_scale := 1.0
var main: Node
var current: Node
var match_count := 0
var _shot_t := 0.0
var _quit_t := 0.0
var _input_events: Array = []
var _input_t := 0.0
var _seg_wait := 0.0


func _ready() -> void:
	var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/roster.json"))
	roster = d["characters"]
	for c in roster:
		by_kind[c["kind"]] = c
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	verbose = args.get("verbose", "0") == "1"
	dmg_scale = float(args.get("dmgscale", "1"))
	for k in ["p1", "p2"]:
		if args.has(k):
			sel[k] = args[k]
	if args.has("p1cpu"):
		sel["p1_cpu"] = args["p1cpu"] == "1"
	if args.has("p2cpu"):
		sel["p2_cpu"] = args["p2cpu"] == "1"
	if args.has("entrances"):
		sel["entrances"] = args["entrances"] == "1"
	if args.has("difficulty"):
		sel["difficulty"] = int(args["difficulty"])
	if args.has("seed"):
		sel["seed"] = int(args["seed"])
	if args.has("arena"):
		sel["arena"] = args["arena"]
	if args.has("timescale"):
		Engine.time_scale = float(args["timescale"])
	if args.has("input_script"):
		var s = JSON.parse_string(FileAccess.get_file_as_string(args["input_script"]))
		if s is Array:
			_input_events = s


func def_of(kind: String) -> Dictionary:
	return by_kind.get(kind, roster[0])


func log_dir() -> String:
	return args.get("logdir", "user://logs")


func _set_screen(n: Node) -> void:
	if current and is_instance_valid(current):
		current.queue_free()
	current = n
	main.add_child(n)


func goto_title() -> void:
	Engine.time_scale = float(args.get("timescale", "1"))
	_set_screen(TitleScreen.new())


func goto_select() -> void:
	_set_screen(CharSelect.new())


func start_match() -> void:
	match_count += 1
	var m := Match.new()
	m.name = "Match"
	_set_screen(m)
	m.setup(sel.duplicate())
	if verbose:
		print("MATCH START %s vs %s" % [sel["p1"], sel["p2"]])


func rematch() -> void:
	start_match()


func _process(dt: float) -> void:
	# automation: screenshots, timed quit, scripted input
	if args.has("shots"):
		_shot_t += dt / maxf(Engine.time_scale, 0.001)
		if _shot_t >= float(args.get("shot_every", "5")):
			_shot_t = 0.0
			_screenshot()
	if args.has("quit_after"):
		_quit_t += dt / maxf(Engine.time_scale, 0.001)
		if _quit_t >= float(args["quit_after"]):
			if args.has("shots"):
				_screenshot()
			get_tree().quit()
	if not _input_events.is_empty():
		_run_input_script(dt)


## Scripted input (tests): events [t, action, "press"|"release"], [t, "shot", tag], [t, "log", text] with t relative to
## the start of the current segment; [0, "wait", phase, timeout] ends a segment when the match reaches that phase.
func _run_input_script(dt: float) -> void:
	var head: Array = _input_events[0]
	if String(head[1]) == "wait":
		_seg_wait += dt
		var m := current as Match
		var timeout: float = float(head[3]) if head.size() > 3 else 600.0
		if (m and m.phase == String(head[2])) or _seg_wait > timeout:
			print("INPUT-SCRIPT: wait '%s' done after %.1fs (%s)" % [head[2], _seg_wait, "ok" if _seg_wait <= timeout else "timeout"])
			_input_events.pop_front()
			_input_t = 0.0
			_seg_wait = 0.0
		return
	_input_t += dt
	while not _input_events.is_empty():
		var e: Array = _input_events[0]
		if String(e[1]) == "wait" or float(e[0]) > _input_t:
			break
		_input_events.pop_front()
		if e[1] == "shot":
			_screenshot(String(e[2]) if e.size() > 2 else "")
		elif e[1] == "log":
			print("INPUT-SCRIPT: ", e[2])
		else:
			# real InputEventAction through the whole pipeline (GUI focus + gameplay actions)
			var ev := InputEventAction.new()
			ev.action = e[1]
			ev.pressed = e[2] == "press"
			ev.strength = 1.0 if ev.pressed else 0.0
			Input.parse_input_event(ev)


func _screenshot(tag: String = "") -> void:
	var dir: String = args.get("shots", "user://shots")
	DirAccess.make_dir_recursive_absolute(dir)
	var img := get_viewport().get_texture().get_image()
	var name := "shot_%06d%s.png" % [Time.get_ticks_msec(), ("_" + tag) if tag != "" else ""]
	img.save_png(dir + "/" + name)
	if verbose:
		print("screenshot ", name)
