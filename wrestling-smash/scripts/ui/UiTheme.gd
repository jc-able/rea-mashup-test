## Front-end look: arena palette, fonts and the shared Theme (built in code once, cached).
## Fonts are SystemFonts with safe fallbacks (Impact / Arial Black for titles), so nothing has
## to be imported; Godot's default font is used if none of the names exist.
extends RefCounted

const BG := Color("07080d")
const PANEL := Color(0.075, 0.085, 0.125, 0.92)
const PANEL_HI := Color(0.13, 0.145, 0.21, 0.96)
const LINE := Color("2c3448")
const TEXT := Color("eef1f7")
const DIM := Color("8a92a8")
const GOLD := Color("ffc23d")
const CRIMSON := Color("e3263a")
const STEEL := Color("4aa3ff")
## SSB64 port colours (P1 red, P2 blue, P3 yellow, P4 green) and team colours.
const PLAYER_COLORS: Array[Color] = [Color("f0383f"), Color("3d7dff"), Color("f6c41c"), Color("2fc057")]
const CPU_COLOR := Color("98a0b0")
const TEAM_COLORS: Array[Color] = [Color("f0383f"), Color("3d7dff"), Color("2fc057")]
const TEAM_NAMES := ["RED", "BLUE", "GREEN"]

static var _theme: Theme = null
static var _title_font: Font = null
static var _body_font: Font = null
static var _bold_font: Font = null

static func _sys(names: Array, weight: int) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(names)
	f.font_weight = weight
	return f

## Heavy slanted display face for titles / names.
static func title_font() -> Font:
	if _title_font == null:
		var fv := FontVariation.new()
		fv.base_font = _sys(["Impact", "Haettenschweiler", "Arial Black", "Avenir Next Condensed", "Helvetica Neue", "sans-serif"], 900)
		fv.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(0.16, 1.0), Vector2.ZERO)
		fv.spacing_glyph = 1
		_title_font = fv
	return _title_font

static func body_font() -> Font:
	if _body_font == null:
		_body_font = _sys(["Avenir Next", "Helvetica Neue", "Segoe UI", "Roboto", "Arial", "sans-serif"], 500)
	return _body_font

static func bold_font() -> Font:
	if _bold_font == null:
		_bold_font = _sys(["Avenir Next Condensed", "Avenir Next", "Helvetica Neue", "Segoe UI", "Roboto", "Arial", "sans-serif"], 800)
	return _bold_font

static func box(bg: Color, border: Color = Color.TRANSPARENT, bw: int = 0, radius: int = 6, skew: float = 0.0, margin: float = 10.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.skew = Vector2(skew, 0.0)
	s.set_content_margin_all(margin)
	s.anti_aliasing = true
	return s

static func glow_box(border: Color, bw: int = 3, radius: int = 6, skew: float = 0.0) -> StyleBoxFlat:
	var s := box(Color(0, 0, 0, 0), border, bw, radius, skew, 10.0)
	s.draw_center = false
	s.shadow_color = Color(border.r, border.g, border.b, 0.35)
	s.shadow_size = 10
	return s

static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 18

	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.55))
	t.set_constant("shadow_offset_x", "Label", 0)
	t.set_constant("shadow_offset_y", "Label", 2)

	for v in [["TitleLabel", 92, 14], ["HeaderLabel", 40, 8], ["NameLabel", 24, 5]]:
		t.set_type_variation(v[0], "Label")
		t.set_font("font", v[0], title_font())
		t.set_font_size("font_size", v[0], v[1])
		t.set_constant("outline_size", v[0], v[2])
		t.set_color("font_outline_color", v[0], Color(0, 0, 0, 0.9))
	t.set_color("font_color", "HeaderLabel", GOLD)
	t.set_type_variation("DimLabel", "Label")
	t.set_color("font_color", "DimLabel", DIM)
	t.set_font_size("font_size", "DimLabel", 15)
	t.set_type_variation("BoldLabel", "Label")
	t.set_font("font", "BoldLabel", bold_font())

	var sk := 0.2
	var normal := box(Color(0.10, 0.115, 0.17, 0.94), LINE, 2, 4, sk, 10.0)
	normal.content_margin_left = 26.0
	normal.content_margin_right = 26.0
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.17, 0.18, 0.26, 0.97)
	hover.border_color = Color(GOLD, 0.55)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.32, 0.24, 0.07, 0.97)
	pressed.border_color = GOLD
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.08, 0.085, 0.11, 0.7)
	disabled.border_color = Color(LINE, 0.5)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("hover_pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_stylebox("focus", "Button", glow_box(GOLD, 3, 4, sk))
	t.set_font("font", "Button", bold_font())
	t.set_font_size("font_size", "Button", 21)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", GOLD)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_hover_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", DIM)

	t.set_stylebox("panel", "PanelContainer", box(PANEL, LINE, 2, 10, 0.0, 16.0))
	t.set_stylebox("panel", "Panel", box(PANEL, LINE, 2, 10, 0.0, 16.0))
	_theme = t
	return t

## Ordinal for 0-based places ("1ST" ...).
static func ordinal(place: int) -> String:
	var n := place + 1
	var suf := "TH"
	if n % 100 < 11 or n % 100 > 13:
		match n % 10:
			1: suf = "ST"
			2: suf = "ND"
			3: suf = "RD"
	return "%d%s" % [n, suf]

static func make_label(text: String, variation: String = "", size: int = 0, color: Color = Color(0, 0, 0, 0)) -> Label:
	var l := Label.new()
	l.text = text
	if variation != "":
		l.theme_type_variation = StringName(variation)
	if size > 0:
		l.add_theme_font_size_override("font_size", size)
	if color.a > 0.0:
		l.add_theme_color_override("font_color", color)
	return l
