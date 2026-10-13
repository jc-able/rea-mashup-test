## Plays the real game (res://scenes/Main.tscn, rendered window) from a timeline of keyboard events
## injected at Godot's input layer (Input.parse_input_event: the same InputEventKey objects the OS
## keyboard produces, read by MenuInput / InputMapper exactly like physical keys), and saves
## screenshots + state lines along the way (Main.save_screenshot, F12).
##   Godot --path game -s res://scripts/test/input_replay.gd -- shots=<dir> [plan=<name>]
## (macOS refused synthetic OS-level events for this process: CGPreflightPostEventAccess() == 0,
## so OS-level injection with tools/input/keypost was not possible without changing security settings.)
extends SceneTree

var main: Node
var t := 0.0
var events: Array = []      # [time, kind, arg] sorted
var idx := 0
var pressed := {}

const K := {"w": KEY_W, "a": KEY_A, "s": KEY_S, "d": KEY_D, "j": KEY_J, "k": KEY_K, "l": KEY_L, "u": KEY_U,
	"i": KEY_I, "o": KEY_O, "space": KEY_SPACE, "enter": KEY_ENTER, "shift": KEY_SHIFT, "esc": KEY_ESCAPE,
	"f1": KEY_F1, "f2": KEY_F2, "f3": KEY_F3, "f4": KEY_F4, "f12": KEY_F12}

func _initialize() -> void:
	var plan := "full"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("plan="):
			plan = a.substr(5)
	_build(plan)
	var ps: PackedScene = load("res://scenes/Main.tscn")
	main = ps.instantiate()
	root.add_child(main)
	# start from the SMASH 64 set so the F4 presses below give SMASH 64 -> SvR 2011 -> SMASH 64
	main.settings.anim_set = "smash"

func at(time: float, kind: String, arg = null) -> void:
	events.append([time, kind, arg])

func tap(time: float, key: String, hold := 0.08) -> void:
	at(time, "down", key)
	at(time + hold, "up", key)

## timeline (seconds)
func _build(plan: String) -> void:
	var tt := 1.5
	at(tt, "shot"); tt += 0.6
	tap(tt, "enter"); tt += 0.9          # title: START opens the menu
	at(tt, "shot"); tt += 0.4
	tap(tt, "j"); tt += 1.0              # VS MODE
	at(tt, "shot"); tt += 0.4
	tap(tt, "enter"); tt += 1.2          # rules -> character select
	at(tt, "shot"); tt += 0.4
	tap(tt, "d"); tt += 0.3
	tap(tt, "d"); tt += 0.3
	tap(tt, "j"); tt += 0.8              # P1 picks a wrestler
	at(tt, "shot"); tt += 0.4
	tap(tt, "enter"); tt += 1.2          # -> stage select
	at(tt, "shot"); tt += 0.4
	tap(tt, "j"); tt += 1.0              # pick stage -> VS splash
	at(tt, "shot"); tt += 0.4
	tap(tt, "j"); tt += 5.0              # splash -> battle; wait for 3-2-1-GO
	at(tt, "shot"); tt += 0.3
	# --- battle: SSB64 animation set -----------------------------------------------------------
	at(tt, "down", "d"); tt += 0.5; at(tt, "up", "d"); tt += 0.25   # dash right
	tap(tt, "j"); tt += 0.35                                          # jab
	tap(tt, "j"); tt += 0.5
	at(tt, "shot"); tt += 0.2
	tap(tt, "space"); tt += 0.25                                      # jump
	tap(tt, "j"); tt += 0.5                                           # aerial
	at(tt, "shot"); tt += 0.8
	at(tt, "down", "d"); at(tt + 0.02, "down", "j"); at(tt + 0.1, "up", "j"); at(tt + 0.1, "up", "d"); tt += 0.9   # forward smash
	at(tt, "shot"); tt += 0.6
	tap(tt, "k"); tt += 0.9                                           # neutral special
	at(tt, "shot"); tt += 0.5
	tap(tt, "o"); tt += 0.6                                           # taunt
	at(tt, "shot"); tt += 1.0
	# --- toggle to the SvR 2011 animation set (F4) and repeat ---------------------------------------
	tap(tt, "f4"); tt += 0.5
	at(tt, "shot"); tt += 0.3
	at(tt, "down", "a"); tt += 0.5; at(tt, "up", "a"); tt += 0.25     # dash left
	tap(tt, "j"); tt += 0.35
	tap(tt, "j"); tt += 0.5
	at(tt, "shot"); tt += 0.3
	at(tt, "down", "shift"); at(tt + 0.02, "down", "d"); at(tt + 0.1, "down", "j"); at(tt + 0.2, "up", "j"); at(tt + 0.25, "up", "d"); at(tt + 0.3, "up", "shift"); tt += 0.9   # forward tilt
	at(tt, "shot"); tt += 0.4
	tap(tt, "k"); tt += 0.5                                           # neutral special (SvR: signature)
	at(tt, "shot"); tt += 0.6
	at(tt, "down", "s"); at(tt + 0.02, "down", "k"); at(tt + 0.1, "up", "k"); at(tt + 0.1, "up", "s"); tt += 0.6   # down special
	at(tt, "shot"); tt += 0.8
	tap(tt, "o"); tt += 0.8                                           # taunt (SvR: the wrestler's own taunt)
	at(tt, "shot"); tt += 1.2
	tap(tt, "l", 0.6); tt += 1.0                                      # shield
	tap(tt, "u"); tt += 0.8                                           # grab
	at(tt, "shot"); tt += 0.8
	tap(tt, "f1"); tt += 0.5                                          # debug overlay: hitboxes + animation source
	at(tt, "shot"); tt += 1.5
	at(tt, "shot"); tt += 0.5
	tap(tt, "f1"); tt += 0.5
	tap(tt, "f4"); tt += 0.6                                          # back to SSB64
	at(tt, "shot"); tt += 1.0
	at(tt, "quit")
	events.sort_custom(func(a, b): return a[0] < b[0])

func _key(key: String, down: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = K[key]
	ev.physical_keycode = K[key]
	ev.pressed = down
	Input.parse_input_event(ev)
	pressed[key] = down

func _process(delta: float) -> bool:
	t += delta
	while idx < events.size() and events[idx][0] <= t:
		var e: Array = events[idx]
		idx += 1
		match e[1]:
			"down":
				_key(e[2], true)
			"up":
				_key(e[2], false)
			"shot":
				main.call("save_screenshot")
			"quit":
				print("[replay] done at %.1f s" % t)
				return true
	return false
