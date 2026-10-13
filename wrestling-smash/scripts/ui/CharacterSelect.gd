## Character select (SSB64 VS player select): 12 wrestler cards + 4 player panels with a
## spinning 3D model, HMN / CPU / N/A, CPU level, input device, team and handicap.
## Every human slot owns a cursor driven by its own device (keyboard 1, keyboard 2, gamepad);
## an unused device joins with A / START. Like SSB64, a human can pick up a CPU's token
## (A on the CPU's fighter area) and drop it on a wrestler. The mouse acts for the "mouse"
## slot (click a human panel to switch, click a CPU panel to carry its token).
extends "res://scripts/ui/ScreenBase.gd"

const Roster := preload("res://scripts/ui/Roster.gd")
const ModelViewer := preload("res://scripts/ui/ModelViewer.gd")

const COLS := 6
const CARD := Vector2(192, 112)
const GAP := 8.0
const GRID_Y := 92.0
const PANEL := Vector2(298, 332)
const PANEL_GAP := 12.0
const PANEL_Y := 380.0
const BAND_Y := 328.0
const PK_MAN := 0   # SSBDefs.nFTPlayerKindMan
const PK_COM := 1   # SSBDefs.nFTPlayerKindCom
const PK_NOT := 2   # SSBDefs.nFTPlayerKindNot
const REGION := Rect2(70, 30, 372, 217)   # face/torso crop of the 512x512 portraits

var cards: Array = []
var panels: Array = []
var cur: Array = []          # per slot: {area: "grid"|"panel", card, panel, cell, carry}
var mouse_slot := 0
var mouse_carry := -1
var mouse_hover := -1
var _banner: Control
var _band_hint: Label
var _t := 0.0

# ------------------------------------------------------------------ build
func build() -> void:
	add_header("CHOOSE YOUR SUPERSTAR")
	_band_hint = UiTheme.make_label("MOVE  WASD / ARROWS / D-PAD   ·   PICK  J / , / A   ·   CANCEL  K / . / B   ·   RANDOM  I / Y   ·   FIGHT  START   ·   UNUSED KEYBOARD / PAD: PRESS A TO JOIN", "DimLabel", 14)
	_band_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_band_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_band_hint.position = Vector2(0, BAND_Y)
	_band_hint.size = Vector2(DESIGN.x, 48)
	canvas.add_child(_band_hint)
	var rl := UiTheme.make_label(app.rules_summary(), "BoldLabel", 15, Color(0.85, 0.87, 0.95))
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rl.position = Vector2(560, 18)
	rl.size = Vector2(530, 24)
	canvas.add_child(rl)
	var back := Button.new()
	back.text = "◀ RULES"
	back.focus_mode = Control.FOCUS_NONE
	back.add_theme_font_size_override("font_size", 16)
	back.position = Vector2(1104, 12)
	back.size = Vector2(150, 40)
	back.pressed.connect(func() -> void: app.goto("rules"))
	canvas.add_child(back)

	var fs := Roster.fighters()
	var gw := COLS * CARD.x + (COLS - 1) * GAP
	var x0 := (DESIGN.x - gw) * 0.5
	for i in fs.size():
		var c := WCard.new()
		c.css = self
		c.idx = i
		c.fkind = int(fs[i].get("fkind", i))
		c.wname = str(fs[i].get("name", "?"))
		c.moveset = str(fs[i].get("ssb64", "?"))
		c.tex = Roster.portrait(str(fs[i].get("slug", "")))
		c.position = Vector2(x0 + (i % COLS) * (CARD.x + GAP), GRID_Y + int(i / COLS) * (CARD.y + GAP))
		c.size = CARD
		canvas.add_child(c)
		cards.append(c)
	var pw := 4 * PANEL.x + 3 * PANEL_GAP
	var px0 := (DESIGN.x - pw) * 0.5
	for p in 4:
		var pn := PPanel.new()
		pn.css = self
		pn.p = p
		pn.position = Vector2(px0 + p * (PANEL.x + PANEL_GAP), PANEL_Y)
		pn.size = PANEL
		canvas.add_child(pn)
		panels.append(pn)
	_banner = Banner.new()
	_banner.css = self
	_banner.position = Vector2(0, BAND_Y)
	_banner.size = Vector2(DESIGN.x, 48)
	_banner.visible = false
	canvas.add_child(_banner)
	for i in 4:
		cur.append(_new_cursor(i))
	_fix_mouse_slot()

func on_enter() -> void:
	pass

# ------------------------------------------------------------------ state helpers
func slot(i: int) -> Dictionary:
	return app.slots[i]

func is_human(i: int) -> bool:
	return int(slot(i).pkind) == PK_MAN

func has_cursor(i: int) -> bool:
	return is_human(i) and int(slot(i).device) != MenuInput.DEV_NONE

func slot_color(i: int) -> Color:
	var pk := int(slot(i).pkind)
	if pk == PK_MAN:
		return UiTheme.PLAYER_COLORS[i]
	return UiTheme.CPU_COLOR if pk == PK_COM else Color(0.25, 0.27, 0.33)

func card_of(fkind: int) -> int:
	for c in cards:
		if c.fkind == fkind:
			return c.idx
	return 0

func _new_cursor(i: int) -> Dictionary:
	var fk := int(slot(i).fkind)
	return {"area": "grid", "card": card_of(fk) if fk >= 0 else (i * 3) % maxi(1, cards.size()), "panel": i, "cell": "type", "carry": -1}

func slot_of_device(dev: int) -> int:
	for i in 4:
		if is_human(i) and int(slot(i).device) == dev:
			return i
	return -1

func panel_cells(i: int) -> Array:
	if int(slot(i).pkind) == PK_NOT:
		return ["type", "fighter"]
	var c := ["type", "fighter", "opt"]
	if app.rules.is_team_battle:
		c.append("team")
	if app.rules.handicap_on:
		c.append("hcap")
	return c

## Fighter shown on panel i (picked, or hovered while choosing).
func panel_fkind(i: int) -> int:
	var s := slot(i)
	if int(s.pkind) == PK_NOT:
		return -1
	if int(s.pkind) == PK_MAN and not s.picked:
		if has_cursor(i) and cur[i].area == "grid" and cur[i].carry < 0:
			return cards[cur[i].card].fkind
		if i == mouse_slot and mouse_hover >= 0 and mouse_carry < 0:
			return cards[mouse_hover].fkind
	return int(s.fkind)

func cursors_on_card(idx: int) -> Array:
	var out := []
	for i in 4:
		if has_cursor(i) and cur[i].area == "grid" and cur[i].card == idx:
			out.append(i)
	return out

func cursors_on_cell(p: int, cell: String) -> Array:
	var out := []
	for i in 4:
		if has_cursor(i) and cur[i].area == "panel" and cur[i].panel == p and cur[i].cell == cell:
			out.append(i)
	return out

func picked_on(fkind: int) -> Array:
	var out := []
	for i in 4:
		var s := slot(i)
		if int(s.pkind) != PK_NOT and s.picked and int(s.fkind) == fkind:
			out.append(i)
	return out

func carried_by(p: int) -> int:
	for i in 4:
		if has_cursor(i) and cur[i].carry == p:
			return i
	return -2 if mouse_carry == p else -1

func is_ready() -> bool:
	var active := 0
	var teams := {}
	for i in 4:
		var s := slot(i)
		if int(s.pkind) == PK_NOT:
			continue
		if int(s.fkind) < 0 or (int(s.pkind) == PK_MAN and not s.picked):
			return false
		active += 1
		teams[int(s.team)] = true
	if active < 2:
		return false
	return not (app.rules.is_team_battle and teams.size() < 2)

func _fix_mouse_slot() -> void:
	if is_human(mouse_slot):
		return
	for i in 4:
		if is_human(i):
			mouse_slot = i
			return

# ------------------------------------------------------------------ input (devices)
func handle_intent(action: String, device: int) -> void:
	if device == MenuInput.DEV_KEYS:
		if action == "back":
			app.goto("rules")
		return
	var s := slot_of_device(device)
	if s < 0:
		if action == "start" and is_ready():
			app.goto("stage")
		elif action in ["accept", "start"]:
			_join(device)
		elif (MenuInput.is_dir(action) or action == "back") and device in [MenuInput.DEV_KB1, MenuInput.DEV_KB2]:
			# single-keyboard fallback: the free keyboard half steers the keyboard player's cursor
			for i in 4:
				if has_cursor(i) and int(slot(i).device) in [MenuInput.DEV_KB1, MenuInput.DEV_KB2]:
					_slot_intent(i, action)
					break
		return
	_slot_intent(s, action)

func _slot_intent(s: int, action: String) -> void:
	var c: Dictionary = cur[s]
	match action:
		"up", "down", "left", "right":
			_move(s, action)
		"accept":
			_accept(s)
		"start":
			if is_ready():
				app.goto("stage")
			elif c.area == "grid" and (c.carry >= 0 or not slot(s).picked):
				_accept(s)
		"back":
			_back(s)
		"aux":
			var target: int = c.carry if c.carry >= 0 else s
			_assign(target, cards[randi() % cards.size()].fkind)
			c.carry = -1

func _move(s: int, dir: String) -> void:
	var c: Dictionary = cur[s]
	var rows := int(ceil(cards.size() / float(COLS)))
	if c.area == "grid":
		var row: int = c.card / COLS
		var col: int = c.card % COLS
		match dir:
			"left":
				col = (col + COLS - 1) % COLS
			"right":
				col = (col + 1) % COLS
			"up":
				row = maxi(row - 1, 0)
			"down":
				if row >= rows - 1:
					c.area = "panel"
					c.panel = _panel_under(col)
					c.cell = "type"
					return
				row += 1
		c.card = mini(row * COLS + col, cards.size() - 1)
		return
	var cells := panel_cells(c.panel)
	var k := maxi(cells.find(c.cell), 0)
	match dir:
		"up":
			if k == 0:
				c.area = "grid"
				c.card = mini((rows - 1) * COLS + _col_over(c.panel), cards.size() - 1)
			else:
				c.cell = cells[k - 1]
		"down":
			c.cell = cells[mini(k + 1, cells.size() - 1)]
		"left", "right":
			var d := -1 if dir == "left" else 1
			match c.cell:
				"fighter":
					c.panel = posmod(c.panel + d, 4)
				_:
					_adjust(c.panel, c.cell, d)

func _accept(s: int) -> void:
	var c: Dictionary = cur[s]
	if c.area == "grid":
		var target: int = c.carry if c.carry >= 0 else s
		_assign(target, cards[c.card].fkind)
		c.carry = -1
		return
	var p: int = c.panel
	if c.cell == "fighter":
		var pk := int(slot(p).pkind)
		if pk == PK_COM:
			c.carry = p
			c.area = "grid"
			c.card = card_of(int(slot(p).fkind))
		elif pk == PK_NOT:
			_set_type(p, PK_COM)
		elif p == s:
			slot(s).picked = false
			c.area = "grid"
			c.card = card_of(int(slot(s).fkind))
	else:
		_adjust(p, c.cell, 1)

func _back(s: int) -> void:
	var c: Dictionary = cur[s]
	if c.carry >= 0:
		c.carry = -1
	elif c.area == "panel":
		c.area = "grid"
		c.card = mini((int(ceil(cards.size() / float(COLS))) - 1) * COLS + _col_over(c.panel), cards.size() - 1)
	elif slot(s).picked:
		slot(s).picked = false
		c.card = card_of(int(slot(s).fkind))
	else:
		app.goto("rules")

func _panel_under(col: int) -> int:
	var gw := COLS * CARD.x + (COLS - 1) * GAP
	var cx := (DESIGN.x - gw) * 0.5 + col * (CARD.x + GAP) + CARD.x * 0.5
	var px0 := (DESIGN.x - (4 * PANEL.x + 3 * PANEL_GAP)) * 0.5
	return clampi(int((cx - px0) / (PANEL.x + PANEL_GAP)), 0, 3)

func _col_over(p: int) -> int:
	var px0 := (DESIGN.x - (4 * PANEL.x + 3 * PANEL_GAP)) * 0.5
	var cx := px0 + p * (PANEL.x + PANEL_GAP) + PANEL.x * 0.5
	var gw := COLS * CARD.x + (COLS - 1) * GAP
	return clampi(int((cx - (DESIGN.x - gw) * 0.5) / (CARD.x + GAP)), 0, COLS - 1)

# ------------------------------------------------------------------ slot edits
func _assign(target: int, fkind: int) -> void:
	var s := slot(target)
	if int(s.pkind) == PK_NOT:
		return
	s.fkind = fkind
	s.picked = true

func _adjust(p: int, cell: String, d: int) -> void:
	var s := slot(p)
	match cell:
		"type":
			var order := [PK_NOT, PK_COM, PK_MAN]
			var k := order.find(int(s.pkind))
			for n in range(1, 3):
				var cand: int = order[posmod(k + d * n, 3)]
				if cand == PK_MAN and free_device_for(p) == MenuInput.DEV_NONE:
					continue
				_set_type(p, cand)
				break
		"opt":
			if int(s.pkind) == PK_COM:
				s.level = posmod(int(s.level) - 1 + d, 9) + 1
			elif int(s.pkind) == PK_MAN:
				var devs: Array = MenuInput.available_devices() + [MenuInput.DEV_NONE]
				var nd: int = devs[posmod(devs.find(int(s.device)) + d, devs.size())]
				var other := slot_of_device(nd)
				if other >= 0 and other != p and nd != MenuInput.DEV_NONE:
					slot(other).device = s.device
					cur[other] = _new_cursor(other)
				s.device = nd
				cur[p] = _new_cursor(p)
		"team":
			s.team = posmod(int(s.team) + d, 3)
		"hcap":
			s.handicap = posmod(int(s.handicap) - 1 + d, 9) + 1

func _set_type(p: int, pk: int) -> void:
	var s := slot(p)
	if int(s.pkind) == pk:
		return
	for i in 4:
		if has_cursor(i) and cur[i].carry == p:
			cur[i].carry = -1
	if mouse_carry == p:
		mouse_carry = -1
	s.pkind = pk
	if pk == PK_COM:
		if int(s.fkind) < 0:
			s.fkind = app.random_free_fkind()
		s.picked = true
	elif pk == PK_MAN:
		s.picked = false
		s.device = free_device_for(p)
		cur[p] = _new_cursor(p)
	else:
		s.picked = false
	_fix_mouse_slot()

## The slot's remembered device if no other human uses it, else the first unused device.
func free_device_for(p: int) -> int:
	var dev := int(slot(p).device)
	if dev != MenuInput.DEV_NONE and (slot_of_device(dev) < 0 or slot_of_device(dev) == p):
		return dev
	for cand in MenuInput.available_devices():
		if slot_of_device(cand) < 0:
			return cand
	return MenuInput.DEV_NONE

func _join(device: int) -> void:
	var target := -1
	for i in 4:
		if not is_human(i) and int(slot(i).device) == device:
			target = i
			break
	if target < 0:
		for pk in [PK_NOT, PK_COM]:
			for i in 4:
				if target < 0 and int(slot(i).pkind) == pk:
					target = i
	if target < 0:
		return
	for i in 4:
		if i != target and not is_human(i) and int(slot(i).device) == device:
			slot(i).device = MenuInput.DEV_NONE
	var s := slot(target)
	s.pkind = PK_MAN
	s.device = device
	s.picked = false
	cur[target] = _new_cursor(target)
	_fix_mouse_slot()
	app.toast("P%d JOINED   ·   %s" % [target + 1, MenuInput.device_label(device)])

# ------------------------------------------------------------------ mouse
func mouse_pick(idx: int) -> void:
	var target := mouse_carry if mouse_carry >= 0 else mouse_slot
	_assign(target, cards[idx].fkind)
	mouse_carry = -1

func mouse_cancel() -> void:
	if mouse_carry >= 0:
		mouse_carry = -1
	elif is_human(mouse_slot):
		slot(mouse_slot).picked = false

func panel_click(p: int, cell: String, d: int) -> void:
	match cell:
		"fighter":
			var pk := int(slot(p).pkind)
			if pk == PK_COM:
				mouse_carry = p
			elif pk == PK_NOT:
				_set_type(p, PK_COM)
			else:
				if mouse_slot == p and slot(p).picked:
					slot(p).picked = false
				mouse_slot = p
		"type":
			_adjust(p, "type", 1)
		_:
			_adjust(p, cell, d)

func _process(delta: float) -> void:
	_t += delta
	for c in cards:
		c.queue_redraw()
	for pn in panels:
		pn.queue_redraw()
	_banner.visible = is_ready()
	_band_hint.visible = not _banner.visible
	_banner.queue_redraw()

# ================================================================== widgets
class WCard extends Control:
	const UiTheme := preload("res://scripts/ui/UiTheme.gd")
	const REGION := Rect2(70, 30, 372, 217)
	var css
	var idx := 0
	var fkind := 0
	var wname := ""
	var moveset := ""
	var tex: Texture2D
	var hovered := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		mouse_entered.connect(func() -> void:
			hovered = true
			css.mouse_hover = idx)
		mouse_exited.connect(func() -> void:
			hovered = false
			if css.mouse_hover == idx:
				css.mouse_hover = -1)

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			if e.button_index == MOUSE_BUTTON_LEFT:
				css.mouse_pick(idx)
			elif e.button_index == MOUSE_BUTTON_RIGHT:
				css.mouse_cancel()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var on: Array = css.cursors_on_card(idx)
		var lit := hovered or not on.is_empty()
		draw_rect(r, Color(0.085, 0.095, 0.145))
		if tex != null:
			draw_texture_rect_region(tex, r.grow(-2), REGION, Color(1, 1, 1, 1.0 if lit else 0.62))
		draw_rect(Rect2(0, size.y - 40, size.x, 40), Color(0, 0, 0, 0.74))
		draw_string(UiTheme.title_font(), Vector2(9, size.y - 19), wname.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 14, 18, Color.WHITE if lit else Color(0.86, 0.87, 0.9))
		draw_string(UiTheme.bold_font(), Vector2(9, size.y - 5), "MOVESET: " + moveset.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 14, 11, Color(UiTheme.GOLD, 0.9))
		draw_rect(r, UiTheme.LINE, false, 2.0)
		if hovered:
			draw_rect(r.grow(-1), Color(1, 1, 1, 0.75), false, 2.0)
		var k := 0
		for s in on:
			var col: Color = UiTheme.PLAYER_COLORS[s]
			draw_rect(r.grow(-1.5 - k * 4.0), col, false, 3.5)
			var chip := Rect2(5 + k * 40, 5, 38, 19)
			draw_rect(chip, col)
			var tag := "P%d" % (s + 1)
			if css.cur[s].carry >= 0:
				tag = "C%d" % (css.cur[s].carry + 1)
			draw_string(UiTheme.bold_font(), chip.position + Vector2(5, 15), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)
			k += 1
		var j := 0
		for s in css.picked_on(fkind):
			var c := Vector2(size.x - 15 - j * 26, 16)
			draw_circle(c, 11.5, Color(0, 0, 0, 0.6))
			draw_circle(c, 10.0, css.slot_color(s))
			var lbl := str(s + 1) if css.is_human(s) else "C"
			draw_string(UiTheme.bold_font(), c + Vector2(-4.5, 5.5), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.BLACK)
			j += 1


class PPanel extends Control:
	const UiTheme := preload("res://scripts/ui/UiTheme.gd")
	const Roster := preload("res://scripts/ui/Roster.gd")
	const MenuInput := preload("res://scripts/ui/MenuInput.gd")
	const ModelViewer := preload("res://scripts/ui/ModelViewer.gd")
	const TOP := 38.0
	const FIG_H := 178.0
	const NAME_H := 46.0
	const ROW_H := 22.0
	const PK_MAN := 0
	const PK_COM := 1
	const PK_NOT := 2
	var css
	var p := 0
	var viewer

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		viewer = ModelViewer.new()
		viewer.position = Vector2(4, TOP)
		viewer.size = Vector2(size.x - 8, FIG_H)
		add_child(viewer)

	func cell_rects() -> Dictionary:
		var d := {"type": Rect2(size.x - 100, 6, 92, 28), "fighter": Rect2(4, TOP, size.x - 8, FIG_H)}
		var y := TOP + FIG_H + NAME_H
		for c in css.panel_cells(p):
			if c in ["opt", "team", "hcap"]:
				d[c] = Rect2(8, y, size.x - 16, ROW_H - 2)
				y += ROW_H
		return d

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			var rects := cell_rects()
			for k in rects:
				var rr: Rect2 = rects[k]
				if rr.has_point(e.position):
					var d := -1 if (e.button_index == MOUSE_BUTTON_RIGHT or e.position.x < rr.get_center().x) else 1
					css.panel_click(p, k, d)
					return

	func _draw() -> void:
		var s: Dictionary = css.slot(p)
		var pk := int(s.pkind)
		var col: Color = css.slot_color(p)
		var r := Rect2(Vector2.ZERO, size)
		var bold := UiTheme.bold_font()
		var title := UiTheme.title_font()
		draw_rect(r, Color(0.06, 0.068, 0.1, 0.95))
		draw_rect(Rect2(0, 0, size.x, TOP), Color(col, 0.95 if pk != PK_NOT else 0.6))
		draw_string(title, Vector2(12, 32), "P%d" % (p + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
		if pk == PK_MAN and css.mouse_slot == p:
			draw_string(bold, Vector2(66, 27), "MOUSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.85))
		var rects := cell_rects()
		var tr: Rect2 = rects.type
		draw_rect(tr, Color(0, 0, 0, 0.45))
		draw_string(bold, tr.position + Vector2(0, 21), ["HMN", "CPU", "N/A"][clampi(pk, 0, 2)], HORIZONTAL_ALIGNMENT_CENTER, tr.size.x, 19, Color.WHITE)
		# fighter area: spotlight pool + model / portrait
		var fr: Rect2 = rects.fighter
		var fk: int = css.panel_fkind(p)
		var slug := Roster.fighter_slug(fk) if fk >= 0 else ""
		viewer.visible = pk != PK_NOT
		viewer.set_wrestler(slug if pk != PK_NOT else "")
		if pk == PK_NOT:
			draw_string(title, fr.position + Vector2(0, 92), "N/A", HORIZONTAL_ALIGNMENT_CENTER, fr.size.x, 48, Color(1, 1, 1, 0.18))
			draw_string(bold, fr.position + Vector2(0, 128), "PRESS  J / , / A  TO JOIN", HORIZONTAL_ALIGNMENT_CENTER, fr.size.x, 15, Color(1, 1, 1, 0.55))
			draw_string(bold, fr.position + Vector2(0, 150), "CLICK HERE FOR A CPU", HORIZONTAL_ALIGNMENT_CENTER, fr.size.x, 13, Color(1, 1, 1, 0.4))
		else:
			var c := fr.position + Vector2(fr.size.x * 0.5, fr.size.y - 10)
			draw_set_transform(c, 0.0, Vector2(1.0, 0.22))
			for k in 5:
				draw_circle(Vector2.ZERO, 110.0 - k * 20.0, Color(col.lerp(Color.WHITE, 0.3), 0.05 + k * 0.03))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			var tex := Roster.portrait(slug)
			if tex != null and not viewer.is_showing(slug):
				var h := fr.size.y
				draw_texture_rect_region(tex, Rect2(fr.position.x + (fr.size.x - h) * 0.5, fr.position.y, h, h), Rect2(0, 0, 512, 512), Color(1, 1, 1, 0.9))
			if pk == PK_MAN and not s.picked:
				var blink := 0.45 + 0.55 * absf(sin(css._t * 3.0))
				draw_string(bold, fr.position + Vector2(0, 18), "CHOOSE YOUR SUPERSTAR", HORIZONTAL_ALIGNMENT_CENTER, fr.size.x, 14, Color(1, 1, 1, blink))
			elif pk == PK_MAN:
				var chip := Rect2(fr.position + Vector2(6, 6), Vector2(64, 20))
				draw_rect(chip, Color(0.12, 0.7, 0.3))
				draw_string(bold, chip.position + Vector2(0, 15), "READY", HORIZONTAL_ALIGNMENT_CENTER, chip.size.x, 13, Color.BLACK)
			var cb: int = css.carried_by(p)
			if cb != -1:
				var who := "MOUSE" if cb == -2 else "P%d" % (cb + 1)
				draw_string(bold, fr.position + Vector2(0, 18), "TOKEN HELD BY " + who, HORIZONTAL_ALIGNMENT_CENTER, fr.size.x, 14, UiTheme.GOLD)
		# name plate
		var ny := TOP + FIG_H
		draw_rect(Rect2(0, ny, size.x, NAME_H), Color(0, 0, 0, 0.55))
		if pk != PK_NOT and fk >= 0:
			var f := Roster.fighter(fk)
			var dim: bool = pk == PK_MAN and not s.picked
			draw_string(title, Vector2(10, ny + 25), str(f.get("name", "?")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 22, Color(1, 1, 1, 0.55 if dim else 1.0))
			draw_string(bold, Vector2(10, ny + 42), "MOVESET: " + str(f.get("ssb64", "?")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 12, Color(UiTheme.GOLD, 0.6 if dim else 1.0))
		elif pk != PK_NOT:
			draw_string(title, Vector2(10, ny + 30), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 1, 1, 0.4))
		# option rows
		for cell in ["opt", "team", "hcap"]:
			if not rects.has(cell):
				continue
			var rr: Rect2 = rects[cell]
			var name := ""
			var val := ""
			var vcol := Color.WHITE
			match cell:
				"opt":
					if pk == PK_COM:
						name = "CPU LEVEL"
						val = str(int(s.level))
					else:
						name = "INPUT"
						val = MenuInput.device_label(int(s.device))
				"team":
					name = "TEAM"
					val = UiTheme.TEAM_NAMES[int(s.team) % 3]
					vcol = UiTheme.TEAM_COLORS[int(s.team) % 3]
				"hcap":
					name = "HANDICAP"
					val = str(int(s.handicap))
			draw_rect(rr, Color(1, 1, 1, 0.05))
			draw_string(bold, rr.position + Vector2(6, 16), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiTheme.DIM)
			draw_string(bold, rr.position + Vector2(rr.size.x - 168, 16), "◀  " + val + "  ▶", HORIZONTAL_ALIGNMENT_CENTER, 160, 14, vcol)
		# player cursors on cells
		for cell in rects:
			var k := 0
			for sidx in css.cursors_on_cell(p, cell):
				var pc: Color = UiTheme.PLAYER_COLORS[sidx]
				var rr: Rect2 = rects[cell]
				draw_rect(rr.grow(2.0 - k * 3.0), pc, false, 3.0)
				var chip := Rect2(rr.position + Vector2(rr.size.x - 34 - k * 36, -10), Vector2(32, 16))
				draw_rect(chip, pc)
				draw_string(bold, chip.position + Vector2(0, 13), "P%d" % (sidx + 1), HORIZONTAL_ALIGNMENT_CENTER, chip.size.x, 12, Color.BLACK)
				k += 1
		draw_rect(r, col if pk == PK_MAN else UiTheme.LINE, false, 2.0)


class Banner extends Control:
	const UiTheme := preload("res://scripts/ui/UiTheme.gd")
	var css

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			css.app.goto("stage")

	func _draw() -> void:
		var pulse := 0.85 + 0.15 * sin(css._t * 5.0)
		var pts := PackedVector2Array([Vector2(0, 6), Vector2(size.x, 0), Vector2(size.x, size.y - 6), Vector2(0, size.y)])
		var cols := PackedColorArray([Color(UiTheme.CRIMSON, 0.95), Color(UiTheme.GOLD, 0.95), Color(UiTheme.GOLD, 0.95), Color(UiTheme.CRIMSON, 0.95)])
		draw_polygon(pts, cols)
		draw_string(UiTheme.title_font(), Vector2(0, 37), "READY TO FIGHT!", HORIZONTAL_ALIGNMENT_CENTER, size.x * 0.62, 36, Color(1, 1, 1, pulse))
		draw_string(UiTheme.bold_font(), Vector2(size.x * 0.58, 31), "PRESS START  ·  ENTER  ·  CLICK", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.1, 0.05, 0.0))
