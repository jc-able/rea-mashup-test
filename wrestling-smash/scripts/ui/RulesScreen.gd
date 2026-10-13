## VS rules (SSB64 VS mode + VS options): stock 1-99 or time 1-99 min / infinite, free for all
## or team battle, item switch + frequency, damage ratio 50-200 %, handicap. START continues.
extends "res://scripts/ui/ScreenBase.gd"

const OptionRow := preload("res://scripts/ui/OptionRow.gd")
const FREQ := ["NONE", "VERY LOW", "LOW", "MEDIUM", "HIGH", "VERY HIGH"]
const TIME_INFINITE := 100   # SCBATTLE_TIMELIMIT_INFINITE

var rows := {}
var _info: Label
var _summary: Label

func build() -> void:
	add_header("VS MODE", "RULES OF THE MATCH")
	var r: Dictionary = app.rules
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.position = Vector2(90, 112)
	box.size = Vector2(700, 0)
	canvas.add_child(box)
	_add(box, "rule", "RULE", ["STOCK", "TIME"], 0 if r.is_stock else 1, "STOCK: last wrestler standing wins.\nTIME: most points (KOs minus falls) when the clock runs out.")
	_add(box, "count", "", [], 0, "")
	_add(box, "team", "BATTLE", ["FREE FOR ALL", "TEAM BATTLE"], 1 if r.is_team_battle else 0, "Team battle: pick RED / BLUE / GREEN on each player panel.")
	_add(box, "items", "ITEMS", ["ON", "OFF"], 0 if r.items_on else 1, "Item switch: toggles every SSB64 item.")
	_add(box, "freq", "ITEM FREQUENCY", FREQ, int(r.item_rate), "How often items appear (SSB64 item switch: none to very high).")
	var dmg := []
	for v in range(50, 201, 10):
		dmg.append("× %.1f" % (v / 100.0))
	_add(box, "damage", "DAMAGE RATIO", dmg, int((int(r.damage_ratio) - 50) / 10), "Scales knockback of every hit (SSB64 damage %: 50-200).", false)
	_add(box, "handicap", "HANDICAP", ["OFF", "ON"], 1 if r.handicap_on else 0, "ON: each player sets a handicap 1-9 on the character select panel (9 = normal).")
	_refresh_count()
	_refresh_enabled()

	var info := PanelContainer.new()
	info.position = Vector2(830, 118)
	info.size = Vector2(380, 400)
	canvas.add_child(info)
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 14)
	info.add_child(iv)
	iv.add_child(UiTheme.make_label("MATCH", "NameLabel", 26, UiTheme.GOLD))
	_summary = UiTheme.make_label("", "BoldLabel", 19)
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	iv.add_child(_summary)
	var sep := ColorRect.new()
	sep.color = UiTheme.LINE
	sep.custom_minimum_size = Vector2(0, 2)
	iv.add_child(sep)
	_info = UiTheme.make_label("", "", 16, Color(0.8, 0.83, 0.9))
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(340, 0)
	iv.add_child(_info)

	var bb := HBoxContainer.new()
	bb.add_theme_constant_override("separation", 24)
	bb.position = Vector2(90, 622)
	canvas.add_child(bb)
	bb.add_child(make_button("◀  BACK", func() -> void: app.goto("title", {"menu": true}), 200))
	var go := make_button("CHARACTER SELECT  ▶", func() -> void: app.goto("css"), 360)
	bb.add_child(go)
	add_footer("LEFT / RIGHT change   ·   START continue   ·   ESC / B back")
	first_focus = rows.rule
	_update_info(rows.rule)

func _add(box: Container, key: String, title: String, values: Array, idx: int, desc: String, wrap: bool = true) -> void:
	var row := OptionRow.new()
	row.setup(key, title, values, idx, wrap, desc)
	row.changed.connect(_on_changed)
	row.focus_entered.connect(func() -> void: _update_info(row))
	box.add_child(row)
	rows[key] = row

func _refresh_count() -> void:
	var r: Dictionary = app.rules
	var row = rows["count"]
	if r.is_stock:
		var v := []
		for i in range(1, 100):
			v.append(str(i))
		row.set_title("STOCKS")
		row.description = "Lives per wrestler (1-99)."
		row.set_values(v, int(r.stocks) - 1)
	else:
		var v := []
		for i in range(1, 100):
			v.append("%d MIN" % i)
		v.append("∞")
		row.set_title("TIME LIMIT")
		row.description = "Match length in minutes (1-99) or infinite."
		row.set_values(v, 99 if int(r.time_limit) >= TIME_INFINITE else int(r.time_limit) - 1)

func _refresh_enabled() -> void:
	rows.freq.set_enabled(app.rules.items_on)

func _on_changed(row) -> void:
	var r: Dictionary = app.rules
	match row.key:
		"rule":
			r.is_stock = row.index == 0
			_refresh_count()
		"count":
			if r.is_stock:
				r.stocks = row.index + 1
			else:
				r.time_limit = TIME_INFINITE if row.index >= 99 else row.index + 1
		"team":
			r.is_team_battle = row.index == 1
		"items":
			r.items_on = row.index == 0
			_refresh_enabled()
		"freq":
			r.item_rate = row.index
		"damage":
			r.damage_ratio = 50 + row.index * 10
		"handicap":
			r.handicap_on = row.index == 1
	_update_info(row)

func _update_info(row) -> void:
	if _info:
		_info.text = row.description
	if _summary:
		_summary.text = app.rules_summary().replace("   ·   ", "\n")

func on_back() -> void:
	app.goto("title", {"menu": true})

func on_start(_device: int) -> bool:
	app.goto("css")
	return true
