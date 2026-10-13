## One "NAME   ◀ value ▶" option line (rules / settings pages). Left/right (any device) or a
## click on the arrows changes the value; accept / a click on the value steps forward.
extends PanelContainer

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

signal changed(row)

var key := ""
var title := ""
var values: Array = []
var index := 0
var wrap_around := true
var enabled := true
var description := ""

var _name_label: Label
var _value_label: Label
var _style_normal: StyleBoxFlat
var _style_focus: StyleBoxFlat

func setup(p_key: String, p_title: String, p_values: Array, p_index: int, p_wrap: bool = true, p_desc: String = "") -> void:
	key = p_key
	title = p_title
	values = p_values
	index = clampi(p_index, 0, maxi(0, p_values.size() - 1))
	wrap_around = p_wrap
	description = p_desc

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(0, 50)
	_style_normal = UiTheme.box(Color(0.08, 0.09, 0.13, 0.88), UiTheme.LINE, 2, 4, 0.2, 8.0)
	_style_normal.content_margin_left = 24.0
	_style_normal.content_margin_right = 18.0
	_style_focus = _style_normal.duplicate() as StyleBoxFlat
	_style_focus.bg_color = Color(0.16, 0.15, 0.12, 0.96)
	_style_focus.border_color = UiTheme.GOLD
	_style_focus.set_border_width_all(3)
	_style_focus.shadow_color = Color(UiTheme.GOLD, 0.3)
	_style_focus.shadow_size = 10
	add_theme_stylebox_override("panel", _style_normal)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hb)
	_name_label = UiTheme.make_label(title, "BoldLabel", 21)
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(_name_label)
	hb.add_child(_arrow("◀", -1))
	_value_label = UiTheme.make_label("", "NameLabel", 24)
	_value_label.custom_minimum_size = Vector2(210, 0)
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_value_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_value_label.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			grab_focus()
			step(1))
	hb.add_child(_value_label)
	hb.add_child(_arrow("▶", 1))
	focus_entered.connect(_refresh)
	focus_exited.connect(_refresh)
	mouse_entered.connect(func() -> void: grab_focus())
	_refresh()

func _arrow(txt: String, dir: int) -> Button:
	var b := Button.new()
	b.text = txt
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", UiTheme.GOLD)
	b.pressed.connect(func() -> void:
		grab_focus()
		step(dir))
	return b

func nav(action: String) -> bool:
	if action == "left":
		step(-1)
		return true
	if action == "right":
		step(1)
		return true
	return false

func activate() -> void:
	step(1)

func step(d: int) -> void:
	if not enabled or values.is_empty():
		return
	var n := index + d
	if wrap_around:
		n = posmod(n, values.size())
	else:
		n = clampi(n, 0, values.size() - 1)
	if n != index:
		index = n
		_refresh()
		changed.emit(self)

func set_values(p_values: Array, p_index: int) -> void:
	values = p_values
	index = clampi(p_index, 0, maxi(0, values.size() - 1))
	_refresh()

func set_title(t: String) -> void:
	title = t
	if _name_label:
		_name_label.text = t

func set_enabled(e: bool) -> void:
	enabled = e
	modulate.a = 1.0 if e else 0.45

func _refresh() -> void:
	if _value_label == null:
		return
	_value_label.text = str(values[index]) if index < values.size() else ""
	var f := has_focus()
	add_theme_stylebox_override("panel", _style_focus if f else _style_normal)
	_value_label.add_theme_color_override("font_color", UiTheme.GOLD if f else UiTheme.TEXT)
