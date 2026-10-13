## Battle HUD (CanvasLayer): per-player damage panels with wrestler portrait, name, stock icons,
## the timer, countdown / GO! / GAME! / TIME UP! announcements, pause banner, screen flash and
## off-screen magnifier bubbles. Reads Ifcommon.ui (ported ifcommon HUD model, N64 320x240 space)
## and falls back to the fighters / battle state when it is not available. Everything scales with
## the window height.
extends CanvasLayer

const RU = preload("res://scripts/render/RenderUtil.gd")
const WL = preload("res://scripts/render/WrestlerLibrary.gd")

var canvas: Control
var font: Font
var portraits: Dictionary = {}
var names: Dictionary = {}
var announce_t := 0.0
var last_announce := ""
var fallback_announce := ""
var paused_menu := false
var anim_set_name := "SMASH 64"        # current animation set (BattleScene, F4)
var anim_lines: Array = []             # per-fighter animation provenance (F1 overlay)
var _msg := ""
var _msg_t := 0.0

func _ready() -> void:
	layer = 10
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_hud)
	add_child(canvas)
	font = ThemeDB.fallback_font

func update(delta: float) -> void:
	announce_t += delta
	_msg_t = maxf(_msg_t - delta, 0.0)
	canvas.queue_redraw()

func flash_message(text: String, secs: float) -> void:
	_msg = text
	_msg_t = secs

func _draw_anim_info(vs: Vector2) -> void:
	var fs := int(clampf(vs.y * 0.022, 11.0, 22.0))
	var label := "ANIMATIONS: " + anim_set_name + "   [F4]"
	_text(Vector2(vs.y * 0.02, vs.y * 0.035), label, fs, Color(0.92, 0.94, 1.0, 0.85), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 4)
	var y := vs.y * 0.035 + fs * 1.4
	for ln in anim_lines:
		_text(Vector2(vs.y * 0.02, y), str(ln), int(fs * 0.85), Color(0.85, 1.0, 0.85) if "original" in str(ln) else Color(1.0, 0.85, 0.6), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 4)
		y += fs * 1.15
	if _msg_t > 0.0:
		var a := clampf(_msg_t / 0.4, 0.0, 1.0)
		var big := int(clampf(vs.y * 0.04, 16.0, 40.0))
		_text(Vector2(0, vs.y * 0.2), _msg, big, Color(1, 0.95, 0.6, a), HORIZONTAL_ALIGNMENT_CENTER, vs.x, 8, Color(0, 0, 0, 0.85 * a))

func _ui() -> Dictionary:
	var ifc: Object = Ifcommon
	var u = ifc.get("ui")
	return u if u is Dictionary else {}

func _portrait(fkind: int) -> Texture2D:
	if not portraits.has(fkind):
		var info: Dictionary = RU.roster().get(fkind, {})
		portraits[fkind] = WL.portrait(info.get("slug", "")) if info.has("slug") else null
		names[fkind] = info.get("name", "???")
	return portraits[fkind]

func _text(pos: Vector2, s: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, outline := 0, ocol := Color(0, 0, 0, 0.85)) -> void:
	if outline > 0:
		canvas.draw_string_outline(font, pos, s, align, width, size, outline, ocol)
	canvas.draw_string(font, pos, s, align, width, size, col)

func _draw_hud() -> void:
	var vs := canvas.size
	var u := 4.0 * vs.y / 240.0 / 4.0          # pixels per N64 pixel (vertical fit)
	var n64_to_screen := func(p: Vector2) -> Vector2:
		var sx := vs.x / 320.0
		var sy := vs.y / 240.0
		return Vector2(p.x * sx, p.y * sy)
	var ui := _ui()
	var bs = G.gSCManagerBattleState
	# --- screen flash ---------------------------------------------------------------------
	var sf: Dictionary = ui.get("screen_flash", {})
	if sf.get("active", false):
		canvas.draw_rect(Rect2(Vector2.ZERO, vs), Color8(int(sf.get("r", 255)), int(sf.get("g", 255)), int(sf.get("b", 255)), int(sf.get("a", 0))))
	# --- player panels --------------------------------------------------------------------
	var players: Array = ui.get("players", [])
	var active: Array = []
	for i in 4:
		var p: Dictionary = players[i] if i < players.size() else {}
		var is_active: bool = p.get("active", bs.players[i].pkind != SSBDefs.nFTPlayerKindNot)
		if is_active:
			active.append(i)
	var n := active.size()
	var pw := minf(vs.x / maxf(n, 1) * 0.86, vs.y * 0.42)
	var ph := pw * 0.42
	for k in n:
		var i: int = active[k]
		var p: Dictionary = players[i] if i < players.size() else {}
		var sp = bs.players[i]
		var cx := vs.x * (k + 0.5) / n
		var rect := Rect2(Vector2(cx - pw * 0.5, vs.y - ph - vs.y * 0.025), Vector2(pw, ph))
		_panel(rect, i, p, sp)
	# --- timer ----------------------------------------------------------------------------
	var tm: Dictionary = ui.get("timer", {})
	if tm.get("visible", false):
		var secs: int = int(tm.get("seconds_remaining", int(tm.get("frames_remaining", 0)) / 60))
		var s := "%d:%02d" % [secs / 60, secs % 60]
		var sz := int(vs.y * 0.06)
		var col := Color(1, 1, 1) if secs > 10 else Color(1, 0.35, 0.3)
		_text(Vector2(0, vs.y * 0.085), s, sz, col, HORIZONTAL_ALIGNMENT_CENTER, vs.x, int(sz * 0.18))
	# --- magnifier bubbles (fighters off-screen) -------------------------------------------
	for m in ui.get("magnify", []):
		if m is Dictionary and m.get("visible", false):
			var c: Vector2 = n64_to_screen.call(m.get("screen_pos", Vector2.ZERO))
			var r := vs.y * 0.055 * float(m.get("scale", 1.0))
			var mc: Color = m.get("color", Color(1, 1, 1))
			canvas.draw_circle(c, r, Color(0, 0, 0, 0.55))
			canvas.draw_arc(c, r, 0, TAU, 32, mc, maxf(2.0, r * 0.12), true)
	# --- announcements ----------------------------------------------------------------------
	var ann := ""
	var a: Dictionary = ui.get("announce", {})
	var kind: String = str(a.get("kind", ""))
	var cd: Dictionary = ui.get("countdown", {})
	if cd.get("visible", false):
		match int(cd.get("lamp", -1)):
			6: ann = "3"
			7: ann = "2"
			8: ann = "1"
			9: ann = "GO!"
			_: ann = "READY"
	if kind == "go":
		ann = "GO!"
	elif kind == "game":
		ann = "GAME!"
	elif kind == "timeup":
		ann = "TIME UP!"
	elif kind == "suddendeath":
		ann = "SUDDEN DEATH"
	elif kind == "ready" and ann == "":
		ann = "READY"
	if ui.is_empty() and fallback_announce != "":
		ann = fallback_announce
	if ann != last_announce:
		last_announce = ann
		announce_t = 0.0
	if ann != "":
		var pop := 1.0 + 0.35 * maxf(0.0, 1.0 - announce_t * 6.0)
		var asz := int(vs.y * 0.16 * pop)
		var acol := Color(1.0, 0.85, 0.2)
		if ann == "GO!":
			acol = Color(1.0, 0.55, 0.15)
		elif ann == "GAME!" or ann == "TIME UP!":
			acol = Color(0.4, 0.7, 1.0)
		_text(Vector2(0, vs.y * 0.47 + asz * 0.35), ann, asz, acol, HORIZONTAL_ALIGNMENT_CENTER, vs.x, int(asz * 0.12), Color(0.05, 0.05, 0.1, 0.95))
	# --- pause ---------------------------------------------------------------------------
	var pz: Dictionary = ui.get("pause", {})
	var is_paused: bool = pz.get("active", false) or int(ui.get("game_status", bs.game_status)) == SSBDefs.nSCBattleGameStatusPause
	if is_paused and not paused_menu:
		canvas.draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.25))
		var psz := int(vs.y * 0.08)
		_text(Vector2(0, vs.y * 0.2), "PAUSE", psz, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_CENTER, vs.x, int(psz * 0.15))
	# --- animation set (F4) / provenance (F1) -------------------------------------------------
	_draw_anim_info(vs)

func _panel(rect: Rect2, i: int, p: Dictionary, sp) -> void:
	var fkind: int = int(p.get("fkind", sp.fkind))
	var pkind: int = int(p.get("pkind", sp.pkind))
	var col: Color = RU.player_color(i)
	if pkind == SSBDefs.nFTPlayerKindCom:
		col = col.lerp(RU.CPU_COLOR, 0.35)
	var tex := _portrait(fkind)
	# backplate
	var bg := Color(0.04, 0.05, 0.08, 0.62)
	canvas.draw_rect(rect, bg)
	canvas.draw_rect(Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.06)), col)
	# portrait
	var ps := rect.size.y * 0.86
	var prect := Rect2(rect.position + Vector2(rect.size.y * 0.08, rect.size.y * 0.1), Vector2(ps, ps))
	if tex != null:
		canvas.draw_texture_rect(tex, prect, false)
	else:
		canvas.draw_rect(prect, col.darkened(0.4))
	canvas.draw_rect(prect, col, false, maxf(1.5, rect.size.y * 0.025))
	var x0 := prect.end.x + rect.size.y * 0.1
	var name_size := int(rect.size.y * 0.17)
	var nm: String = str(names.get(fkind, "???")).to_upper()
	var avail := rect.end.x - x0 - 6.0
	while name_size > 8 and font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x > avail:
		name_size -= 1
	_text(Vector2(x0, rect.position.y + rect.size.y * 0.3), nm, name_size, Color(0.92, 0.92, 0.95), HORIZONTAL_ALIGNMENT_LEFT, -1, 0)
	# tag
	var tag: String = str(p.get("name_tag", "CPU" if pkind == SSBDefs.nFTPlayerKindCom else "P%d" % (i + 1)))
	if tag == "CP":
		tag = "CPU"
	elif tag.length() == 2 and tag[1] == "P":
		tag = "P" + tag[0]
	_text(Vector2(rect.position.x + 4.0, rect.position.y - rect.size.y * 0.06), tag, int(rect.size.y * 0.2), col.lightened(0.2), HORIZONTAL_ALIGNMENT_LEFT, -1, int(rect.size.y * 0.04))
	# damage %
	var dmg: int = int(p.get("damage", -1))
	var fp = sp.fighter_gobj
	if dmg < 0:
		dmg = fp.percent_damage if fp != null else 0
	var dvis: bool = p.get("damage_visible", true)
	var stocks: int = int(p.get("stocks", sp.stock_count))
	if stocks < 0:
		dvis = false
	if dvis:
		var dscale := float(p.get("damage_scale", 1.0))
		var dcol: Color = p.get("damage_color", Color(1, 1, 1).lerp(Color(0.85, 0.15, 0.1), clampf(dmg / 150.0, 0.0, 1.0)))
		if p.get("damage_flash", false):
			dcol = Color(1, 1, 1)
		var dsz := int(rect.size.y * 0.5 * clampf(dscale, 0.8, 1.6))
		var s := "%d%%" % dmg
		_text(Vector2(x0, rect.position.y + rect.size.y * 0.78), s, dsz, dcol, HORIZONTAL_ALIGNMENT_LEFT, rect.end.x - x0, int(dsz * 0.12), Color(0.02, 0.02, 0.05, 0.95))
	elif stocks < 0:
		_text(Vector2(x0, rect.position.y + rect.size.y * 0.75), "OUT", int(rect.size.y * 0.32), Color(0.6, 0.6, 0.65), HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
	# stock icons
	var is_stock_rule: bool = (G.gSCManagerBattleState.game_rules & SSBDefs.SCBATTLE_GAMERULE_STOCK) != 0
	if is_stock_rule and stocks >= 0:
		var icons = p.get("stock_icons", null)
		var cnt: int = icons.size() if icons is Array else stocks + 1
		if p.has("stock_number") and int(p.stock_number) > 0:
			cnt = int(p.stock_number)
		var r := rect.size.y * 0.055
		var y := rect.end.y - r * 1.6
		if cnt <= 6:
			for s2 in cnt:
				var c := Vector2(x0 + r + s2 * r * 2.6, y)
				canvas.draw_circle(c, r, col)
				canvas.draw_arc(c, r, 0, TAU, 16, Color(1, 1, 1, 0.8), 1.2, true)
		else:
			canvas.draw_circle(Vector2(x0 + r, y), r, col)
			_text(Vector2(x0 + r * 2.6, y + r), "x %d" % cnt, int(r * 2.8), Color(1, 1, 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
