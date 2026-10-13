## Settings: display mode (also F11), master volume, hitbox display default for battles (passed as
## config.debug_hitboxes) and the wrestler animation set (config.anim_set: SSB64 motions retargeted
## onto the wrestlers, or the wrestlers' own SmackDown vs. Raw 2011 motions; F4 in battle). Saved to
## user://settings.cfg.
extends "res://scripts/ui/ScreenBase.gd"

const OptionRow := preload("res://scripts/ui/OptionRow.gd")

var rows := {}
var _info: Label

func build() -> void:
	add_header("SETTINGS", "SAVED AUTOMATICALLY")
	var s: Dictionary = app.settings
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.position = Vector2(90, 130)
	box.size = Vector2(760, 0)
	canvas.add_child(box)
	var vols := []
	for i in 11:
		vols.append("%d %%" % (i * 10))
	_add(box, "fullscreen", "DISPLAY", ["WINDOWED", "FULLSCREEN"], 1 if s.fullscreen else 0, "Fullscreen toggle (F11 works anywhere, also in battle).")
	_add(box, "volume", "MASTER VOLUME", vols, int(round(float(s.master_volume) * 10.0)), "Master audio bus volume (placeholder until the battle has sound).", false)
	_add(box, "hitboxes", "SHOW HITBOXES", ["OFF", "ON"], 1 if s.show_hitboxes else 0, "Default for new battles: draws attack / hurt boxes (config.debug_hitboxes).")
	_add(box, "anim", "WRESTLER ANIMATIONS", ["SMASH 64", "SvR 2011"], 1 if str(s.get("anim_set", "smash")) == "svr" else 0, "SMASH 64: the original SSB64 motions retargeted onto the wrestlers.  SvR 2011: the wrestlers' own SmackDown vs. Raw 2011 moves (recovered from the game files), retimed to the SSB64 frame data. Hitboxes, damage, knockback and timing are SSB64 in both. Switch any time in battle with F4 (gamepad SELECT).")
	_info = UiTheme.make_label("", "", 16, Color(0.8, 0.83, 0.9))
	_info.position = Vector2(90, 440)
	_info.size = Vector2(760, 80)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	canvas.add_child(_info)
	var back := make_button("◀  BACK", func() -> void: on_back(), 200)
	back.position = Vector2(90, 560)
	canvas.add_child(back)
	add_footer("LEFT / RIGHT change   ·   ESC / B back")
	first_focus = rows.fullscreen
	_info.text = rows.fullscreen.description

func _add(box: Container, key: String, title: String, values: Array, idx: int, desc: String, wrap: bool = true) -> void:
	var row := OptionRow.new()
	row.setup(key, title, values, idx, wrap, desc)
	row.changed.connect(_on_changed)
	row.focus_entered.connect(func() -> void: _info.text = row.description)
	box.add_child(row)
	rows[key] = row

func _on_changed(row) -> void:
	match row.key:
		"fullscreen":
			app.set_fullscreen(row.index == 1)
		"volume":
			app.settings.master_volume = row.index / 10.0
		"hitboxes":
			app.settings.show_hitboxes = row.index == 1
		"anim":
			app.settings.anim_set = "svr" if row.index == 1 else "smash"
	app.save_settings()

## Keeps the row in sync when F11 is pressed while this page is open.
func _process(_d: float) -> void:
	var want := 1 if app.settings.fullscreen else 0
	if rows.has("fullscreen") and rows.fullscreen.index != want:
		rows.fullscreen.set_values(rows.fullscreen.values, want)

func on_back() -> void:
	app.goto("title", {"menu": true})
