## Battle scene: runs the ported engine through BattleRunner at 60 Hz (_physics_process) and draws
## its state every frame (read-only): stage blockout, retargeted wrestlers, projectiles/items,
## effects, shadows, HUD, debug overlay.
##
## Interface:
##   setup(config)                  call before adding to the tree (BattleRunner.default_config() format);
##                                  without it the scene runs standalone with the default config.
##   signal battle_finished(results) when Scvsbattle reports the battle task finished
##                                  (results = Scvsbattle.port_results).
##   signal quit_requested          Escape -> "Quit to menu?" -> Yes.
## Hotkeys: F1 debug overlay (hurt/hitboxes, shields, ledges, blast zones, SSB skeleton, and which
##          animation each wrestler shows), F2 wrestler models <-> SSB skeleton only, F3 game camera <->
##          wide debug camera, F4 (gamepad SELECT/BACK) animation set: SSB64 motions retargeted onto the
##          wrestlers <-> the wrestlers' own SmackDown vs. Raw 2011 motions (presentation only; the
##          gameplay simulation is identical), Esc quit menu.
## config.anim_set: "smash" (default) or "svr"; signal anim_set_changed(name) reports F4 toggles.
## Standalone command line (after "--"): gkind=N p1=FK p2=FK p3=FK p4=FK human=0/1 stocks=N
##   items=0/1 debug=1 skeleton=1 wide=1 capture=<png path> capture_at=<frame[,frame..]> quit_at=<frame>
extends Node3D

signal battle_finished(results: Dictionary)
signal quit_requested
signal anim_set_changed(set_name: String)

const RU = preload("res://scripts/render/RenderUtil.gd")
const StageRenderer = preload("res://scripts/render/StageRenderer.gd")
const FighterRenderer = preload("res://scripts/render/FighterRenderer.gd")
const ObjectRenderer = preload("res://scripts/render/ObjectRenderer.gd")
const EffectLayer = preload("res://scripts/render/EffectLayer.gd")
const DebugOverlay = preload("res://scripts/render/DebugOverlay.gd")
const BattleHUD = preload("res://scripts/render/BattleHUD.gd")

var config: Dictionary = {}
var runner: BattleRunner
var camera: Camera3D
var stage: Node3D
var objects: Node3D
var effects: Node3D
var debug: Node3D
var hud: CanvasLayer
var fighters: Dictionary = {}          # Fighter -> FighterRenderer
var shadow_mesh: ImmediateMesh
var shadow_mi: MeshInstance3D
var cam_mode := 0
var debug_on := false
var models_on := true
var anim_set := 0                      # FighterRenderer.AnimSet (0 = SSB64, 1 = SvR 2011)
var cam_follow = null                  # Fighter followed by the test close-up camera (cam_mode 2)
var frozen := false
var finished := false
var quit_layer: CanvasLayer
var _opts: Dictionary = {}
var _captures: Array = []
var _shadow_gobjs: Array = []
var _hook: Callable
var _t_start := 0
var _rendered := 0
var _prof := [0, 0, 0, 0, 0]

func setup(cfg: Dictionary) -> void:
	config = cfg

func _ready() -> void:
	Engine.physics_ticks_per_second = 60
	Engine.max_physics_steps_per_frame = 3
	if config.is_empty():
		config = BattleRunner.default_config()
		_parse_cmdline()
	anim_set = FighterRenderer.AnimSet.SVR if str(config.get("anim_set", "smash")) == "svr" else FighterRenderer.AnimSet.SSB64
	camera = Camera3D.new()
	camera.current = true
	add_child(camera)
	stage = StageRenderer.new()
	stage.name = "Stage"
	add_child(stage)
	objects = ObjectRenderer.new()
	objects.name = "Objects"
	add_child(objects)
	effects = EffectLayer.new()
	effects.name = "Effects"
	add_child(effects)
	debug = DebugOverlay.new()
	debug.name = "Debug"
	add_child(debug)
	_make_shadow_layer()
	hud = BattleHUD.new()
	add_child(hud)
	# sound: the engine calls the original SSB64 FGM ids (Snd); SfxSynth plays a synthesized sound per id
	if DisplayServer.get_name() != "headless":
		var sfx := SfxSynth.new()
		sfx.name = "Sfx"
		add_child(sfx)
	_hook = Callable(effects, &"on_fighter_effect")
	Ftparam.effect_hook = _hook
	runner = BattleRunner.new()
	runner.start(config)
	stage.build()
	debug.visible = debug_on
	_sync_fighters()
	_update_visuals(0.0)
	_t_start = Time.get_ticks_msec()
	if _opts.has("debug_at"):
		debug_on = false

func _exit_tree() -> void:
	if Ftparam.effect_hook == _hook:
		Ftparam.effect_hook = Callable()

func _parse_cmdline() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		_opts[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if _opts.has("gkind"):
		config.gkind = int(_opts.gkind)
	var human := int(_opts.get("human", "0")) != 0
	for i in 4:
		var key := "p%d" % (i + 1)
		if _opts.has(key):
			var fk := int(_opts[key])
			if fk < 0:
				config.players[i].pkind = SSBDefs.nFTPlayerKindNot
			else:
				config.players[i].fkind = fk
				config.players[i].pkind = SSBDefs.nFTPlayerKindMan if (i == 0 and human) else SSBDefs.nFTPlayerKindCom
				config.players[i].level = 9
	if _opts.has("stocks"):
		config.stocks = int(_opts.stocks)
	if _opts.has("items"):
		config.items_on = int(_opts["items"]) != 0
	if _opts.has("anim"):
		config.anim_set = "svr" if str(_opts.anim) in ["svr", "1"] else "smash"
	debug_on = int(_opts.get("debug", "0")) != 0
	models_on = int(_opts.get("skeleton", "0")) == 0
	cam_mode = int(_opts.get("wide", "0"))
	if _opts.has("capture_at"):
		for f in str(_opts.capture_at).split(","):
			_captures.append(int(f))

func _physics_process(_delta: float) -> void:
	if frozen or runner == null:
		return
	runner.step()
	_sync_fighters()
	effects.detect_hits(fighters)
	_update_shadows_display()
	if not finished and runner.is_finished():
		finished = true
		var res: Dictionary = runner.results()
		if battle_finished.get_connections().is_empty():
			print("battle finished: winner player %s" % str(res.get("win_player", "?")))
			hud.fallback_announce = "GAME!"
		battle_finished.emit(res)
	if _opts.has("debug_at") and runner.frame == int(_opts.debug_at):
		debug_on = true
	if _opts.has("anim_toggle_at") and str(runner.frame) in str(_opts.anim_toggle_at).split(","):
		toggle_anim_set()
	if _captures.size() > 0 and runner.frame >= int(_captures[0]):
		_captures.pop_front()
		_capture.call_deferred()
	if _opts.has("quit_at") and runner.frame >= int(_opts.quit_at):
		if _opts.has("perf"):
			var secs := (Time.get_ticks_msec() - _t_start) / 1000.0
			print("perf: %d game frames in %.1f s (%.1f fps render avg, last fps %d), process %.2f ms, physics %.2f ms, draw calls %d, objects %d" % [runner.frame, secs, _rendered / maxf(secs, 0.001), Engine.get_frames_per_second(), Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)])
		if _opts.has("perf"):
			var n := maxf(_prof[4], 1.0)
			print("perf avg us/frame: fighters %.0f, stage+objects+fx+shadow+cam %.0f, debug %.0f, hud %.0f" % [_prof[0] / n, _prof[1] / n, _prof[2] / n, _prof[3] / n])
		get_tree().quit()

func _capture() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var base := str(_opts.get("capture", "user://battle.png"))
	var path := base
	if base.ends_with(".png") and _opts.get("capture_at", "").contains(","):
		path = base.trim_suffix(".png") + "_f%d.png" % runner.frame
	img.save_png(path)
	print("captured ", path)

func _process(delta: float) -> void:
	_rendered += 1
	_update_visuals(delta)

func _sync_fighters() -> void:
	var seen := {}
	for g in Sim.get_link(SSBDefs.nGCCommonLinkIDFighter):
		if not (g is Fighter) or not g.is_alive:
			continue
		seen[g] = true
		if not fighters.has(g):
			var fr = FighterRenderer.new()
			fr.name = "Fighter%d" % g.player
			add_child(fr)
			fr.setup(g)
			fr.show_model = models_on
			fr.set_anim_set(anim_set)
			fighters[g] = fr
	for g in fighters.keys():
		if not seen.has(g):
			fighters[g].queue_free()
			fighters.erase(g)

func _update_visuals(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	for g in fighters:
		var fr = fighters[g]
		fr.show_model = models_on
		fr.update(delta)
	var t1 := Time.get_ticks_usec()
	stage.update()
	objects.update(delta, fighters)
	effects.update(delta)
	_draw_shadows()
	_update_camera()
	var t2 := Time.get_ticks_usec()
	if debug_on or not models_on:
		debug.visible = true
		debug.show_boxes = debug_on
		debug.show_skeleton = debug_on or not models_on
		debug.update(fighters, not models_on)
	else:
		debug.visible = false
	var t3 := Time.get_ticks_usec()
	hud.paused_menu = frozen
	hud.anim_set_name = "SvR 2011" if anim_set == FighterRenderer.AnimSet.SVR else "SMASH 64"
	hud.anim_lines = _anim_lines() if debug_on else []
	hud.update(delta)
	var t4 := Time.get_ticks_usec()
	if _opts.has("perf"):
		_prof[0] += t1 - t0
		_prof[1] += t2 - t1
		_prof[2] += t3 - t2
		_prof[3] += t4 - t3
		_prof[4] += 1

func _update_camera() -> void:
	if cam_mode == 2 and cam_follow != null and is_instance_valid(cam_follow) and cam_follow.dobj != null:
		# test / evidence close-up (scripts/test): follows one fighter, 3/4 view
		var c: Vector3 = cam_follow.dobj.translate * RU.S + Vector3(0, 2.2, 0)
		camera.fov = 40.0
		camera.near = 0.1
		camera.far = 500.0
		camera.look_at_from_position(c + Vector3(3.5, 1.6, 11.0), c, Vector3.UP)
		return
	if cam_mode == 0:
		var eye: Vector3 = Gmcamera.gGMCameraRenderEye * RU.S
		var at: Vector3 = Gmcamera.gGMCameraRenderAt * RU.S
		var up: Vector3 = Gmcamera.gGMCameraRenderUp
		if eye.distance_to(at) < 0.01:
			return
		var sh: float = effects.shake
		if sh > 0.0:
			var o := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * sh * eye.distance_to(at) * 0.05
			eye += o
			at += o
		camera.fov = clampf(Gmcamera.gGMCameraRenderFovy, 5.0, 120.0)
		camera.near = maxf(Gmcamera.gGMCameraRenderNear * RU.S, 0.05)
		camera.far = maxf(Gmcamera.gGMCameraRenderFar * RU.S, 100.0)
		camera.look_at_from_position(eye, at, up if up.length() > 0.1 else Vector3.UP)
	else:
		var gd = Mpcollision.gMPCollisionGroundData
		if gd == null:
			return
		var l: float = gd.map_bound_left
		var r: float = gd.map_bound_right
		var t: float = gd.map_bound_top
		var b: float = gd.map_bound_bottom
		var c := Vector3((l + r) * 0.5, (t + b) * 0.5, 0.0) * RU.S
		camera.fov = 38.0
		var tanh := tan(deg_to_rad(camera.fov * 0.5))
		var vs := get_viewport().get_visible_rect().size
		var aspect := vs.x / maxf(vs.y, 1.0)
		var d := maxf((t - b) * 0.5 / tanh, (r - l) * 0.5 / (tanh * aspect)) * RU.S * 1.04
		camera.near = 1.0
		camera.far = d * 4.0
		camera.look_at_from_position(c + Vector3(0, 0, d), c, Vector3.UP)

# --- shadows (Ftshadow display output) -------------------------------------------------------
func _make_shadow_layer() -> void:
	shadow_mesh = ImmediateMesh.new()
	shadow_mi = MeshInstance3D.new()
	shadow_mi.mesh = shadow_mesh
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.5, 0.0)
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 0.9))
	gr.set_color(1, Color(1, 1, 1, 0.0))
	gr.add_point(0.75, Color(1, 1, 1, 0.65))
	gt.gradient = gr
	gt.width = 64
	gt.height = 64
	m.albedo_texture = gt
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.render_priority = 1
	shadow_mi.material_override = m
	shadow_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow_mi.extra_cull_margin = 16384.0
	add_child(shadow_mi)

func _update_shadows_display() -> void:
	_shadow_gobjs.clear()
	for g in Sim.get_link(SSBDefs.nGCCommonLinkIDShadow):
		if g.gobj_kind == SSBDefs.nGCCommonKindShadow and g.user_data is Ftshadow.FTShadow:
			Ftshadow.ftShadowProcDisplay(g)
			_shadow_gobjs.append(g)

func _draw_shadows() -> void:
	shadow_mesh.clear_surfaces()
	var any := false
	for g in _shadow_gobjs:
		var fs = g.user_data
		if fs.draw_vtx == null or fs.draw_vertex_num < 4 or fs.draw_tris.is_empty():
			continue
		if not any:
			shadow_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			any = true
		var pc: Array = fs.draw_prim_color
		var col := Color8(int(pc[0]), int(pc[1]), int(pc[2]), int(pc[3]))
		col.a = clampf(col.a * 1.6, 0.0, 0.85)
		var vtx: Array = fs.draw_vtx
		for idx in fs.draw_tris:
			var v: Dictionary = vtx[idx].n
			var ob: Array = v.ob
			var tc: Array = v.tc
			shadow_mesh.surface_set_color(col)
			shadow_mesh.surface_set_uv(Vector2(float(tc[1]) / 1984.0, float(tc[0]) / 1984.0))
			shadow_mesh.surface_add_vertex(Vector3(float(ob[0]), float(ob[1]) + 2.0, float(ob[2]) * 1.4) * RU.S)
	if any:
		shadow_mesh.surface_end()

# --- input -----------------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_BACK:
		toggle_anim_set()
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F4:
			toggle_anim_set()
		KEY_F1:
			debug_on = not debug_on
		KEY_F2:
			models_on = not models_on
		KEY_F3:
			cam_mode = 1 - cam_mode
		KEY_ESCAPE:
			if quit_layer == null:
				_open_quit_menu()
			else:
				_close_quit_menu()
		_:
			return
	get_viewport().set_input_as_handled()

## F4 / gamepad SELECT: switch the presentation animation set for every wrestler. Only the
## renderer changes; the engine (runner) is not touched.
func toggle_anim_set() -> void:
	anim_set = FighterRenderer.AnimSet.SSB64 if anim_set == FighterRenderer.AnimSet.SVR else FighterRenderer.AnimSet.SVR
	for g in fighters:
		fighters[g].set_anim_set(anim_set)
	var nm := "svr" if anim_set == FighterRenderer.AnimSet.SVR else "smash"
	config["anim_set"] = nm
	hud.flash_message("ANIMATIONS: " + ("SvR 2011 — the wrestlers' own moves" if nm == "svr" else "SMASH 64 motions"), 2.5)
	anim_set_changed.emit(nm)

## Per-fighter provenance of what the model shows (F1 overlay): original SvR clip vs SSB64 fallback.
func _anim_lines() -> Array:
	var out := []
	for g in fighters:
		var fr = fighters[g]
		var d: Dictionary = fr.anim_info()
		var who := "P%d %s" % [int(g.player) + 1, fr.display_name]
		if d.get("set", "") == "SvR 2011":
			if str(d.get("clip", "")) != "":
				out.append("%s: %s -> SvR 2011 original %s%s" % [who, d.get("role", ""), d.get("clip", ""), (" \"" + str(d.move) + "\"") if str(d.get("move", "")) != "" else ""])
			else:
				out.append("%s: %s -> SSB64 motion (no recovered SvR clip)" % [who, d.get("role", "")])
		else:
			out.append("%s: SSB64 motion (retargeted)" % who)
	return out

func _open_quit_menu() -> void:
	frozen = true
	quit_layer = CanvasLayer.new()
	quit_layer.layer = 50
	add_child(quit_layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	quit_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	quit_layer.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	var vs := get_viewport().get_visible_rect().size
	var fs := int(vs.y * 0.045)
	var lbl := Label.new()
	lbl.text = "  Quit to menu?  "
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", fs)
	box.add_child(lbl)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	var yes := Button.new()
	yes.text = "  Yes  "
	yes.add_theme_font_size_override("font_size", int(fs * 0.8))
	yes.pressed.connect(_on_quit_yes)
	row.add_child(yes)
	var no := Button.new()
	no.text = "  No  "
	no.add_theme_font_size_override("font_size", int(fs * 0.8))
	no.pressed.connect(_close_quit_menu)
	row.add_child(no)
	no.grab_focus()

func _close_quit_menu() -> void:
	if quit_layer != null:
		quit_layer.queue_free()
		quit_layer = null
	frozen = false

func _on_quit_yes() -> void:
	_close_quit_menu()
	frozen = true
	if quit_requested.get_connections().is_empty():
		get_tree().quit()
	quit_requested.emit()
