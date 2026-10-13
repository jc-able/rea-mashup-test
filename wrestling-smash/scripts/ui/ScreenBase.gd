## Base for full-screen menu pages. Content lives in `canvas`, a 1280x720 design area centred
## in the window (stretch/aspect handled by the window content scale). Single-cursor pages get
## focus navigation from every device (keyboard 1/2, gamepads) via handle_intent(); mouse hover
## moves the focus, so focus is the one highlight for all input methods.
extends Control

const UiTheme := preload("res://scripts/ui/UiTheme.gd")
const MenuInput := preload("res://scripts/ui/MenuInput.gd")
const DESIGN := Vector2(1280, 720)

var app: Node = null          # Main.gd
var args: Dictionary = {}
var canvas: Control
var first_focus: Control = null

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas = Control.new()
	canvas.name = "Canvas"
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.set_anchors_preset(Control.PRESET_CENTER)
	canvas.offset_left = -DESIGN.x * 0.5
	canvas.offset_right = DESIGN.x * 0.5
	canvas.offset_top = -DESIGN.y * 0.5
	canvas.offset_bottom = DESIGN.y * 0.5
	add_child(canvas)

func _ready() -> void:
	build()

## Override: create the page.
func build() -> void:
	pass

## Called by Main once the page is in the tree and visible.
func on_enter() -> void:
	focus_first()

func focus_first() -> void:
	if first_focus != null and is_instance_valid(first_focus) and first_focus.is_visible_in_tree():
		first_focus.grab_focus()

## Override for page-specific back behaviour.
func on_back() -> void:
	pass

## Override: return true when START was consumed (default: activate the focused item).
func on_start(_device: int) -> bool:
	return false

func handle_intent(action: String, device: int) -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var f := vp.gui_get_focus_owner()
	if action == "back":
		on_back()
		return
	if action == "start" and on_start(device):
		return
	if f == null or not is_ancestor_of(f):
		focus_first()
		return
	match action:
		"up", "down", "left", "right":
			if f.has_method("nav") and f.call("nav", action):
				return
			var side: int = {"up": SIDE_TOP, "down": SIDE_BOTTOM, "left": SIDE_LEFT, "right": SIDE_RIGHT}[action]
			var n := f.find_valid_focus_neighbor(side)
			if n != null and is_ancestor_of(n) and n.is_visible_in_tree():
				n.grab_focus()
		"accept", "start", "aux":
			activate(f)

static func activate(c: Control) -> void:
	if c.has_method("activate"):
		c.call("activate")
	elif c is BaseButton:
		var b := c as BaseButton
		if b.disabled:
			return
		if b.toggle_mode:
			b.button_pressed = not b.button_pressed
		else:
			b.pressed.emit()

## Focusable button whose hover moves the focus.
func make_button(text: String, cb: Callable, min_w: float = 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	if min_w > 0.0:
		b.custom_minimum_size = Vector2(min_w, 0)
	b.pressed.connect(cb)
	hover_focus(b)
	return b

static func hover_focus(c: Control) -> void:
	c.mouse_entered.connect(func() -> void:
		if c.focus_mode != Control.FOCUS_NONE and c.is_visible_in_tree():
			c.grab_focus())

## Page title at the top-left of the design area plus a gold underline accent.
func add_header(text: String, sub: String = "") -> void:
	var h := UiTheme.make_label(text, "HeaderLabel")
	h.position = Vector2(56, 22)
	canvas.add_child(h)
	var bar := ColorRect.new()
	bar.color = UiTheme.CRIMSON
	bar.position = Vector2(58, 78)
	bar.size = Vector2(220, 4)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bar)
	if sub != "":
		var s := UiTheme.make_label(sub, "DimLabel", 15)
		s.position = Vector2(290, 66)
		canvas.add_child(s)

## One-line hint at the bottom of the design area.
func add_footer(text: String) -> Label:
	var l := UiTheme.make_label(text, "DimLabel", 14)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, DESIGN.y - 30)
	l.size = Vector2(DESIGN.x, 22)
	canvas.add_child(l)
	return l
