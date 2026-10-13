## App flow (front-end): title -> VS rules -> character select -> stage select -> VS splash ->
## res://scenes/Battle.tscn -> results -> character select (or rules / title).
## Owns the session (rules, 4 player slots, settings), routes menu input from every device to
## the current page, builds the battle config in BattleRunner.default_config() format, assigns
## InputMapper port devices, and hosts the battle: instantiate, setup(config) BEFORE add_child,
## battle_finished(results) / quit_requested. Without a loadable Battle.tscn a page explains it
## and offers simulated results. Engine scripts are loaded at runtime only, so the menus run
## even while engine code is mid-port.
extends Node

const UiTheme := preload("res://scripts/ui/UiTheme.gd")
const MenuInput := preload("res://scripts/ui/MenuInput.gd")
const Roster := preload("res://scripts/ui/Roster.gd")
const ArenaBackground := preload("res://scripts/ui/ArenaBackground.gd")

const SCREENS := {
	"title": "res://scripts/ui/TitleScreen.gd",
	"rules": "res://scripts/ui/RulesScreen.gd",
	"css": "res://scripts/ui/CharacterSelect.gd",
	"stage": "res://scripts/ui/StageSelect.gd",
	"results": "res://scripts/ui/ResultsScreen.gd",
	"controls": "res://scripts/ui/ControlsScreen.gd",
	"settings": "res://scripts/ui/SettingsScreen.gd",
	"splash": "res://scripts/ui/InfoScreen.gd",
	"missing": "res://scripts/ui/InfoScreen.gd",
}
const BATTLE_SCENE := "res://scenes/Battle.tscn"
const SETTINGS_PATH := "user://settings.cfg"
# SSBDefs values, mirrored so the menus never need engine scripts to compile (checked at start).
const PK_MAN := 0              # nFTPlayerKindMan
const PK_COM := 1              # nFTPlayerKindCom
const PK_NOT := 2              # nFTPlayerKindNot
const TIME_INFINITE := 100     # SCBATTLE_TIMELIMIT_INFINITE
const HANDICAP_DEFAULT := 9    # FTCOMMON_HANDICAP_DEFAULT
## dFTParamCostumeIDs (src/ft/ftparam.c, Mario..Ness): royal[4] / team[3] costume ids, used the
## way mnplayersvs.c does (first royal costume not used by the same fighter; team -> team costume).
const COSTUME_ROYAL := [[0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3], [0, 2, 3, 1],
	[0, 1, 2, 3], [0, 4, 1, 3], [0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3]]
const COSTUME_TEAM := [[0, 3, 4], [1, 2, 3], [2, 3, 4], [0, 4, 3], [3, 2, 0], [2, 3, 0],
	[1, 2, 0], [1, 5, 2], [3, 2, 4], [1, 2, 3], [1, 2, 3], [0, 2, 3]]
const FREQ_NAMES := ["NONE", "VERY LOW", "LOW", "MEDIUM", "HIGH", "VERY HIGH"]

## Session state (kept across battles).
var rules := {"is_stock": true, "stocks": 3, "time_limit": 2, "items_on": true, "item_rate": 3,
	"is_team_battle": false, "damage_ratio": 100, "handicap_on": false}
var slots: Array = []   # 4 x {pkind, fkind, picked, level, handicap, team, device}
var settings := {"fullscreen": false, "master_volume": 0.8, "show_hitboxes": false, "anim_set": "smash"}
var stage_gkind := 6
## Battle scene path (a test can point it elsewhere to exercise the "battle missing" page).
var battle_scene_path := BATTLE_SCENE
var last_config: Dictionary = {}
var last_results: Dictionary = {}

var _menu_in := MenuInput.new()
var _im = null                  # scripts/input/InputMapper.gd (runtime-loaded)
var _bg_layer: CanvasLayer
var _ui_root: Control
var _fade: ColorRect
var _toast: PanelContainer
var _toast_label: Label
var _toast_tween: Tween
var _battle_holder: Node
var _screen: Control = null
var _screen_name := ""
var _busy := false
var _battle: Node = null
var _in_battle := false
var _battle_can_quit := false
var _shot_n := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	_setup_window()
	_load_settings()
	_im = _load_engine_script("res://scripts/input/InputMapper.gd")
	_verify_defs()
	_init_slots()
	_build_layers()
	_apply_settings()
	goto("title", {}, false)
	_maybe_smoke()

## Command-line smoke test of a build (after "--"): smoke=<frames> [smoke_fighters=0,7] [smoke_stage=6]
## [smoke_anim=svr] [smoke_toggle=<every n frames>] skips the menus, runs a CPU battle through the
## normal launch path, prints a summary line every 300 frames and quits.
var _smoke_frames := 0
var _smoke_toggle := 0
func _maybe_smoke() -> void:
	var o := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		o[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if not o.has("smoke"):
		return
	_smoke_frames = int(o.smoke)
	_smoke_toggle = int(o.get("smoke_toggle", "0"))
	var fks := str(o.get("smoke_fighters", "0,7")).split(",")
	for i in 4:
		slots[i].pkind = PK_NOT
	for i in fks.size():
		slots[i].pkind = PK_COM
		slots[i].fkind = int(fks[i])
		slots[i].picked = true
		slots[i].level = 9
	settings = settings.duplicate()      # smoke settings stay in memory (never saved)
	settings.anim_set = str(o.get("smoke_anim", settings.anim_set))
	stage_gkind = int(o.get("smoke_stage", "6"))
	last_config = build_battle_config()
	await get_tree().create_timer(0.5).timeout
	await launch_battle()
	var start := Time.get_ticks_msec()
	while _in_battle and _battle != null and is_instance_valid(_battle):
		await get_tree().physics_frame
		var f: int = _battle.runner.frame
		if _smoke_toggle > 0 and f > 0 and f % _smoke_toggle == 0:
			_battle.toggle_anim_set()
		if f % 300 == 0:
			var line := "[smoke] frame %d" % f
			for g in _battle.fighters:
				var d: Dictionary = _battle.fighters[g].anim_info()
				line += "   P%d %s %d%% stocks %d role %s anim %s %s" % [int(g.player) + 1, _battle.fighters[g].display_name,
					int(g.percent_damage), int(g.stock_count), str(d.get("role", "")), str(d.get("set", "")), str(d.get("clip", ""))]
			print(line)
		if f >= _smoke_frames:
			break
	print("[smoke] done: %d frames in %.1f s" % [_smoke_frames, (Time.get_ticks_msec() - start) / 1000.0])
	get_tree().quit()

func _exit_tree() -> void:
	Roster.clear_cache()

# ------------------------------------------------------------------ window / layers
func _setup_window() -> void:
	var w := get_window()
	if w.content_scale_mode == Window.CONTENT_SCALE_MODE_DISABLED:
		w.content_scale_size = Vector2i(1280, 720)
		w.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	w.min_size = Vector2i(960, 540)
	w.title = "Wrestling Smash"

func _build_layers() -> void:
	_bg_layer = CanvasLayer.new()
	_bg_layer.layer = -10
	add_child(_bg_layer)
	_bg_layer.add_child(ArenaBackground.new())
	_battle_holder = Node.new()
	_battle_holder.name = "BattleHolder"
	_battle_holder.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_battle_holder)
	var ui := CanvasLayer.new()
	add_child(ui)
	_ui_root = _full_rect_control()
	ui.add_child(_ui_root)
	var top := CanvasLayer.new()
	top.layer = 100
	add_child(top)
	var top_root := _full_rect_control()
	top.add_child(top_root)
	_toast = PanelContainer.new()
	_toast.anchor_left = 0.5
	_toast.anchor_right = 0.5
	_toast.anchor_top = 0.0
	_toast.anchor_bottom = 0.0
	_toast.offset_left = -420
	_toast.offset_right = 420
	_toast.offset_top = 14
	_toast.offset_bottom = 62
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.visible = false
	_toast_label = UiTheme.make_label("", "BoldLabel", 18)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.add_child(_toast_label)
	top_root.add_child(_toast)
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_root.add_child(_fade)

func _full_rect_control() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.theme = UiTheme.get_theme()
	return c

func _fade_to(a: float, t: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", a, t)
	await tw.finished

# ------------------------------------------------------------------ navigation
func goto(screen_name: String, args: Dictionary = {}, fade: bool = true) -> void:
	if _busy:
		return
	_busy = true
	if fade and _screen != null:
		await _fade_to(1.0, 0.12)
	_show_screen(screen_name, args)
	await _fade_to(0.0, 0.16)
	_busy = false

func _show_screen(screen_name: String, args: Dictionary) -> void:
	_clear_screen()
	var scr: Script = load(SCREENS.get(screen_name, SCREENS.title))
	var s: Control = scr.new()
	s.set("app", self)
	s.set("args", args)
	s.name = screen_name.capitalize()
	_ui_root.add_child(s)
	_screen = s
	_screen_name = screen_name
	s.call("on_enter")

func _clear_screen() -> void:
	if _screen != null and is_instance_valid(_screen):
		_ui_root.remove_child(_screen)
		_screen.queue_free()
	_screen = null

func current_screen_name() -> String:
	return _screen_name

func quit_game() -> void:
	get_tree().quit()

# ------------------------------------------------------------------ input routing
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F11:
		set_fullscreen(not settings.fullscreen)
		save_settings()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F12:
		save_screenshot()
		get_viewport().set_input_as_handled()
		return
	if _in_battle:
		if not _battle_can_quit and event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
			_end_battle.call_deferred("css")
		return
	if not MenuInput.is_menu_event(event):
		return
	get_viewport().set_input_as_handled()
	var intents := _menu_in.translate(event)
	if _busy or _screen == null:
		return
	for it in intents:
		_screen.call("handle_intent", it.action, it.device)

func _process(delta: float) -> void:
	var reps := _menu_in.poll(delta)
	if _in_battle or _busy or _screen == null:
		return
	for it in reps:
		_screen.call("handle_intent", it.action, it.device)

## F12: saves a screenshot (user://screenshots, or the directory given as "shots=<dir>" after "--")
## and prints a one-line state summary of the running battle (used for real-input test evidence).
func save_screenshot() -> void:
	var dir := "user://screenshots"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("shots="):
			dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(dir if not dir.begins_with("user://") else ProjectSettings.globalize_path(dir))
	_shot_n += 1
	var path := dir.path_join("shot_%03d_%s.png" % [_shot_n, _screen_name if not _in_battle else "battle"])
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	var line := "[F12] saved %s" % path
	if _in_battle and _battle != null and is_instance_valid(_battle) and _battle.get("fighters") is Dictionary:
		var fd: Dictionary = _battle.get("fighters")
		for g in fd:
			var fr = fd[g]
			var d: Dictionary = fr.call("anim_info") if fr.has_method("anim_info") else {}
			line += "   P%d %s %d%% status %d %s anim %s%s" % [int(g.player) + 1, fr.get("display_name"), int(g.percent_damage),
				int(g.status_id), str(d.get("role", "")), str(d.get("set", "")), (" " + str(d.get("clip", ""))) if str(d.get("clip", "")) != "" else ""]
	print(line)

func toast(text: String, secs: float = 2.5) -> void:
	_toast_label.text = text
	_toast.visible = true
	_toast.modulate.a = 0.0
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(secs)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)

# ------------------------------------------------------------------ session
func _init_slots() -> void:
	slots.clear()
	for i in 4:
		slots.append({"pkind": PK_NOT, "fkind": -1, "picked": false, "level": 3, "handicap": HANDICAP_DEFAULT,
			"team": [0, 1, 2, 0][i], "device": MenuInput.DEV_NONE})
	slots[0].pkind = PK_MAN
	slots[0].device = MenuInput.DEV_KB1
	slots[1].device = MenuInput.DEV_KB2   # remembered: keyboard 2 joins as P2
	slots[1].pkind = PK_COM
	slots[1].fkind = random_free_fkind()
	slots[1].picked = true

func random_free_fkind() -> int:
	var used := {}
	for s in slots:
		if int(s.pkind) != PK_NOT:
			used[int(s.fkind)] = true
	var free := []
	for f in Roster.fighters():
		if not used.has(int(f.get("fkind", 0))):
			free.append(int(f.get("fkind", 0)))
	if free.is_empty():
		return randi() % maxi(1, Roster.fighters().size())
	return free[randi() % free.size()]

## Whoever pressed START on the title becomes player 1's device (swapping with its old owner).
func set_primary_device(dev: int) -> void:
	if dev == MenuInput.DEV_KEYS or dev == MenuInput.DEV_NONE or int(slots[0].device) == dev:
		return
	for i in range(1, 4):
		if int(slots[i].device) == dev:
			slots[i].device = slots[0].device
	slots[0].device = dev
	slots[0].pkind = PK_MAN

func rules_summary() -> String:
	var parts := []
	if rules.is_stock:
		parts.append("STOCK × %d" % int(rules.stocks))
	else:
		parts.append("TIME ∞" if int(rules.time_limit) >= TIME_INFINITE else "TIME %d MIN" % int(rules.time_limit))
	parts.append("TEAM BATTLE" if rules.is_team_battle else "FREE FOR ALL")
	parts.append(("ITEMS " + FREQ_NAMES[int(rules.item_rate)]) if rules.items_on and int(rules.item_rate) > 0 else "NO ITEMS")
	if int(rules.damage_ratio) != 100:
		parts.append("DAMAGE × %.1f" % (int(rules.damage_ratio) / 100.0))
	if rules.handicap_on:
		parts.append("HANDICAP")
	return "   ·   ".join(parts)

func controls_summary() -> String:
	var txt := ""
	if _im != null and _im.has_method("describe_controls"):
		txt = str(_im.call("describe_controls"))
	if txt == "":
		txt = "P1 keyboard: WASD move, J attack, K special, I/Space jump, L shield, U grab, O taunt, Enter pause\n" + \
			"P2 keyboard: arrows move, Num1 attack, Num2 special, Num5 jump, Num3 shield, Num6 grab, NumEnter pause\n" + \
			"Gamepad: stick move, A attack, B special, Y jump, RB shield, LB grab, Start pause"
	return txt + "\nMenus: confirm J / , / gamepad A   ·   back K / . / B / Esc   ·   gamepads join on the character select with A   ·   F11 fullscreen"

## {1: keyboard 1 layout, 2: keyboard 2 layout} from InputMapper.KB_LAYOUTS (action -> keycodes).
func keyboard_layouts() -> Dictionary:
	if _im != null:
		var lay = _im.get("KB_LAYOUTS")
		var dev = _im.get("Device")
		if lay is Dictionary and dev is Dictionary:
			return {1: lay.get(dev.get("KB1", 1), {}), 2: lay.get(dev.get("KB2", 2), {})}
	return {1: {"mod": [KEY_SHIFT], "a": [KEY_J], "b": [KEY_K], "z": [KEY_L], "r": [KEY_U], "c": [KEY_I, KEY_SPACE], "l": [KEY_O], "start": [KEY_ENTER]},
		2: {"mod": [KEY_CTRL], "a": [KEY_KP_1, KEY_COMMA], "b": [KEY_KP_2, KEY_PERIOD], "z": [KEY_KP_3, KEY_SLASH], "r": [KEY_KP_6, KEY_APOSTROPHE], "c": [KEY_KP_5, KEY_KP_0], "l": [KEY_KP_9], "start": [KEY_KP_ENTER, KEY_BACKSPACE]}}

# ------------------------------------------------------------------ battle
## Battle config in BattleRunner.default_config() format (+ stage_key/stage_name, per-player
## device/joy/slug/name and debug_hitboxes). time_limit is minutes, 100 = infinite.
func build_battle_config() -> Dictionary:
	var st := Roster.stage_by_gkind(stage_gkind)
	var cfg := {
		"gkind": stage_gkind, "stage_key": str(st.get("key", "")), "stage_name": str(st.get("name", "")),
		"is_stock": bool(rules.is_stock), "stocks": int(rules.stocks), "time_limit": int(rules.time_limit),
		"items_on": bool(rules.items_on) and int(rules.item_rate) > 0, "item_rate": int(rules.item_rate),
		"is_team_battle": bool(rules.is_team_battle), "damage_ratio": int(rules.damage_ratio),
		"handicap": 1 if rules.handicap_on else 0, "debug_hitboxes": bool(settings.show_hitboxes),
		"anim_set": str(settings.get("anim_set", "smash")),
		"players": [],
	}
	var used := {}
	for i in 4:
		var s: Dictionary = slots[i]
		var pk := int(s.pkind)
		var fk := int(s.fkind)
		if (pk == PK_MAN and not s.picked) or fk < 0:
			pk = PK_NOT
		fk = maxi(fk, 0)
		var team := int(s.team) if rules.is_team_battle else i
		var costume := 0
		if pk != PK_NOT and fk < COSTUME_ROYAL.size():
			if rules.is_team_battle:
				costume = COSTUME_TEAM[fk][posmod(team, 3)]
			else:
				var taken: Array = used.get(fk, [])
				for c in COSTUME_ROYAL[fk]:
					if not taken.has(c):
						costume = c
						break
				taken.append(costume)
				used[fk] = taken
		var dev := int(s.device) if pk == PK_MAN else MenuInput.DEV_NONE
		cfg.players.append({
			"pkind": pk, "fkind": fk, "level": int(s.level),
			"handicap": int(s.handicap) if rules.handicap_on else HANDICAP_DEFAULT,
			"costume": costume, "team": team,
			"device": ["none", "kb1", "kb2"][dev] if dev < MenuInput.DEV_PAD0 and dev <= 2 else "pad",
			"joy": dev - MenuInput.DEV_PAD0 if dev >= MenuInput.DEV_PAD0 else -1,
			"slug": Roster.fighter_slug(fk), "name": Roster.fighter_name(fk),
		})
	return cfg

## Writes the HMN slots' devices into InputMapper.port_device / port_joy (CPU / off -> NONE).
func apply_input_devices() -> void:
	if _im == null:
		return
	var D = _im.get("Device")
	var pd = _im.get("port_device")
	var pj = _im.get("port_joy")
	if not (D is Dictionary and pd is Array and pj is Array):
		return
	for i in 4:
		var dev := int(slots[i].device) if int(slots[i].pkind) == PK_MAN else MenuInput.DEV_NONE
		var kind = D.get("NONE", 0)
		var joy := -1
		if dev == MenuInput.DEV_KB1:
			kind = D.get("KB1", 1)
		elif dev == MenuInput.DEV_KB2:
			kind = D.get("KB2", 2)
		elif dev >= MenuInput.DEV_PAD0:
			kind = D.get("PAD", 3)
			joy = dev - MenuInput.DEV_PAD0
		pd[i] = kind
		pj[i] = joy

func start_battle(gkind: int) -> void:
	stage_gkind = gkind
	last_config = build_battle_config()
	apply_input_devices()
	goto("splash", {"mode": "splash", "config": last_config})

func launch_battle() -> void:
	if _in_battle or _busy:
		return
	var reason := ""
	var b: Node = null
	if not ResourceLoader.exists(battle_scene_path):
		reason = battle_scene_path + " does not exist yet."
	else:
		var ps = load(battle_scene_path)
		if ps is PackedScene:
			b = (ps as PackedScene).instantiate()
		if b == null:
			reason = battle_scene_path + " failed to load / instantiate (see the output log)."
		elif not b.has_method("setup"):
			reason = battle_scene_path + " has no setup(config) method (its script failed to compile?)."
			b.free()
			b = null
	if b == null:
		push_warning("Main: " + reason)
		goto("missing", {"mode": "missing", "config": last_config, "reason": reason})
		return
	b.call("setup", last_config.duplicate(true))
	if b.has_signal("battle_finished"):
		b.connect("battle_finished", _on_battle_finished)
	if b.has_signal("anim_set_changed"):
		b.connect("anim_set_changed", _on_anim_set_changed)
	_battle_can_quit = b.has_signal("quit_requested")
	if _battle_can_quit:
		b.connect("quit_requested", _on_battle_quit)
	_busy = true
	await _fade_to(1.0, 0.15)
	_clear_screen()
	_bg_layer.visible = false
	_battle = b
	_in_battle = true
	_battle_holder.add_child(b)
	_busy = false
	await _fade_to(0.0, 0.25)
	toast("START pauses   ·   while paused hold A + B + R + Z to quit" + ("" if _battle_can_quit else "   ·   Esc returns to the menus"), 6.0)

func _on_battle_finished(results = null) -> void:
	if not _in_battle:
		return
	last_results = results if results is Dictionary else {}
	_end_battle.call_deferred("results")

## F4 in battle: remember the animation set for the next battles.
func _on_anim_set_changed(set_name: String) -> void:
	if _smoke_frames > 0:
		return          # automated smoke runs never change the player's saved preference
	settings.anim_set = set_name
	save_settings()

func _on_battle_quit() -> void:
	if _in_battle:
		_end_battle.call_deferred("css")

func _end_battle(next: String) -> void:
	if not _in_battle:
		return
	_in_battle = false
	if _toast_tween != null:
		_toast_tween.kill()
	_toast.visible = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _battle != null and is_instance_valid(_battle):
		_battle_holder.remove_child(_battle)
		_battle.queue_free()
	_battle = null
	_bg_layer.visible = true
	_fade.color.a = 1.0
	if next == "results":
		goto("results", {"results": last_results, "config": last_config}, false)
	else:
		goto(next, {}, false)

## Test path while Battle.tscn is missing: plausible fake results (marked simulated).
func simulate_results() -> void:
	var cfg := last_config
	var order := []
	for i in 4:
		if int(cfg.players[i].pkind) != PK_NOT:
			order.append(i)
	order.shuffle()
	var players := []
	var n := order.size()
	for rank in n:
		var i: int = order[rank]
		var p: Dictionary = cfg.players[i]
		var stocks := int(cfg.stocks)
		var left := randi_range(1, stocks) if rank == 0 else 0
		var e := {"port": i, "pkind": p.pkind, "fkind": p.fkind, "team": p.team,
			"kos": n - 1 - rank + randi_range(0, 2), "falls": (stocks - left) if cfg.is_stock else randi_range(0, 3),
			"self_destructs": randi_range(0, 1), "damage_dealt": randi_range(40, 400), "damage_taken": randi_range(40, 400)}
		if cfg.is_stock:
			e["placement"] = rank + 1
			e["stocks_left"] = left
		players.append(e)
	last_results = {"simulated": true, "players": players}
	goto("results", {"results": last_results, "config": last_config})

func describe_config(cfg: Dictionary) -> String:
	if cfg.is_empty():
		return "(no config)"
	var lines := ["gkind %d (%s)   ·   %s   ·   time_limit %d   ·   item_rate %d   ·   damage_ratio %d   ·   debug_hitboxes %s" % [
		int(cfg.gkind), cfg.get("stage_name", ""), ("stock, stocks %d" % int(cfg.stocks)) if cfg.is_stock else "time",
		int(cfg.time_limit), int(cfg.item_rate), int(cfg.damage_ratio), str(cfg.get("debug_hitboxes", false))]]
	for i in 4:
		var p: Dictionary = cfg.players[i]
		if int(p.pkind) == PK_NOT:
			lines.append("P%d  pkind 2 (off)" % (i + 1))
		else:
			lines.append("P%d  pkind %d (%s)   fkind %d  %s   level %d   handicap %d   team %d   costume %d   device %s" % [
				i + 1, int(p.pkind), "man" if int(p.pkind) == PK_MAN else "com", int(p.fkind), p.get("name", ""),
				int(p.level), int(p.handicap), int(p.team), int(p.costume), p.get("device", "")])
	return "\n".join(lines)

# ------------------------------------------------------------------ settings
func _load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) == OK:
		for k in settings.keys():
			settings[k] = cf.get_value("settings", k, settings[k])

func save_settings() -> void:
	var cf := ConfigFile.new()
	for k in settings.keys():
		cf.set_value("settings", k, settings[k])
	cf.save(SETTINGS_PATH)
	_apply_volume()

func _apply_settings() -> void:
	set_fullscreen(bool(settings.fullscreen))
	_apply_volume()

func _apply_volume() -> void:
	var v := clampf(float(settings.master_volume), 0.0, 1.0)
	AudioServer.set_bus_mute(0, v <= 0.001)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(v, 0.001)))

func set_fullscreen(on: bool) -> void:
	settings.fullscreen = on
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.window_get_mode()
	var is_full := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if on != is_full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)

# ------------------------------------------------------------------ engine helpers
static func _load_engine_script(path: String):
	if not ResourceLoader.exists(path):
		return null
	var s = load(path)
	return s if (s is Script and s.can_instantiate()) else null

func _verify_defs() -> void:
	var d = _load_engine_script("res://scripts/core/SSBDefs.gd")
	if d == null:
		return
	var want := {"nFTPlayerKindMan": PK_MAN, "nFTPlayerKindCom": PK_COM, "nFTPlayerKindNot": PK_NOT, "SCBATTLE_TIMELIMIT_INFINITE": TIME_INFINITE}
	for k in want:
		var v = d.get(k)
		if v != null and int(v) != int(want[k]):
			push_warning("Main: SSBDefs.%s = %s differs from the menu constant %s" % [k, str(v), str(want[k])])
