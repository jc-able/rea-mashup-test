## Two small pages around the battle:
##  mode "splash"  - pre-match VS card (fighters, arena, pause hint); A/START or 1.8 s -> battle.
##  mode "missing" - res://scenes/Battle.tscn absent or broken: explains it, shows the config
##                   that would be passed to battle.setup(), offers simulated results (test) / back.
extends "res://scripts/ui/ScreenBase.gd"

const Roster := preload("res://scripts/ui/Roster.gd")

var _gone := false

func build() -> void:
	if str(args.get("mode", "splash")) == "splash":
		_build_splash()
	else:
		_build_missing()

func _build_splash() -> void:
	var cfg: Dictionary = args.get("config", {})
	var st := Roster.stage_by_gkind(int(cfg.get("gkind", 0)))
	var arena := UiTheme.make_label("ARENA:  " + str(st.get("name", "?")).to_upper(), "NameLabel", 28, UiTheme.GOLD)
	arena.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arena.position = Vector2(0, 40)
	arena.size = Vector2(DESIGN.x, 40)
	canvas.add_child(arena)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.position = Vector2(20, 110)
	row.size = Vector2(DESIGN.x - 40, 420)
	canvas.add_child(row)
	var n := 0
	for i in 4:
		var p: Dictionary = cfg.get("players", [])[i] if i < cfg.get("players", []).size() else {}
		if int(p.get("pkind", 2)) == 2:
			continue
		if n > 0:
			var vs := UiTheme.make_label("VS", "TitleLabel", 64, UiTheme.CRIMSON)
			vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			vs.custom_minimum_size = Vector2(0, 400)
			row.add_child(vs)
		n += 1
		var v := VBoxContainer.new()
		v.custom_minimum_size = Vector2(250, 0)
		var col: Color = UiTheme.PLAYER_COLORS[i] if int(p.pkind) == 0 else UiTheme.CPU_COLOR
		if cfg.get("is_team_battle", false):
			col = UiTheme.TEAM_COLORS[posmod(int(p.get("team", 0)), 3)]
		var tag := UiTheme.make_label(("P%d" % (i + 1)) if int(p.pkind) == 0 else ("CPU  LV %d" % int(p.get("level", 3))), "NameLabel", 26, col)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(tag)
		var tr := TextureRect.new()
		tr.custom_minimum_size = Vector2(250, 300)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tr.texture = Roster.portrait(Roster.fighter_slug(int(p.get("fkind", 0))))
		v.add_child(tr)
		var nm := UiTheme.make_label(Roster.fighter_name(int(p.get("fkind", 0))).to_upper(), "NameLabel", 24)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nm)
		row.add_child(v)
	var hint := PanelContainer.new()
	hint.position = Vector2(DESIGN.x * 0.5 - 420, 576)
	hint.size = Vector2(840, 60)
	var hl := UiTheme.make_label("START (Enter · NumEnter/Backspace · pad Start) pauses   ·   while paused hold A + B + R + Z to quit", "BoldLabel", 16)
	hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_child(hl)
	canvas.add_child(hint)
	add_footer(app.rules_summary())
	get_tree().create_timer(1.8).timeout.connect(_go)

func _go() -> void:
	if _gone or not is_inside_tree():
		return
	_gone = true
	app.launch_battle()

func _build_missing() -> void:
	add_header("BATTLE NOT AVAILABLE", "THE MENUS ARE READY - THE BATTLE SCENE IS NOT")
	var p := PanelContainer.new()
	p.position = Vector2(90, 120)
	p.size = Vector2(DESIGN.x - 180, 420)
	canvas.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var msg := UiTheme.make_label(str(args.get("reason", "res://scenes/Battle.tscn could not be loaded.")) +
		"\nThe battle renderer is built separately. This configuration is what battle.setup(config) receives:", "BoldLabel", 17)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(msg)
	var cfg := UiTheme.make_label(app.describe_config(args.get("config", {})), "", 15, Color(0.8, 0.84, 0.92))
	cfg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(cfg)
	var bb := HBoxContainer.new()
	bb.add_theme_constant_override("separation", 20)
	bb.position = Vector2(90, 570)
	canvas.add_child(bb)
	var sim := make_button("SIMULATE RESULTS (TEST)", func() -> void: app.simulate_results(), 380)
	bb.add_child(sim)
	bb.add_child(make_button("◀  CHARACTER SELECT", func() -> void: app.goto("css"), 320))
	first_focus = sim

func handle_intent(action: String, device: int) -> void:
	if str(args.get("mode", "splash")) == "splash":
		if action in ["accept", "start"]:
			_go()
		return
	super.handle_intent(action, device)

func on_back() -> void:
	app.goto("css")
