## Schematic stage preview drawn from the ROM collision outline (data/ssb64/stages/<key>.json):
## solid ground filled, floors bright, drop-through platforms dashed, walls/ceilings dim,
## camera bounds, battle spawns (detail mode). key "" draws a random "?" tile.
extends Control

const UiTheme := preload("res://scripts/ui/UiTheme.gd")
const Roster := preload("res://scripts/ui/Roster.gd")

var key := ""
var detail := false
var _geo: Dictionary = {}
var _fills: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	resized.connect(queue_redraw)

func set_stage(k: String) -> void:
	key = k
	_geo = Roster.stage_geometry(k) if k != "" else {}
	_fills = _closed_chains()
	queue_redraw()

func _closed_chains() -> Array:
	var out: Array = []
	if _geo.is_empty() or not _geo.get("ok", false):
		return out
	var pending: Array = []
	for ln in _geo.lines:
		if not ln.pass and ln.pts.size() >= 2:
			pending.append(ln.pts)
	while not pending.is_empty():
		var chain := PackedVector2Array(pending.pop_back())
		var grown := true
		while grown:
			grown = false
			for i in range(pending.size() - 1, -1, -1):
				var p: PackedVector2Array = pending[i]
				if p[0].distance_to(chain[chain.size() - 1]) < 4.0:
					for k in range(1, p.size()):
						chain.append(p[k])
					pending.remove_at(i)
					grown = true
				elif p[p.size() - 1].distance_to(chain[0]) < 4.0:
					var pre := p.slice(0, p.size() - 1)
					pre.append_array(chain)
					chain = pre
					pending.remove_at(i)
					grown = true
		if chain.size() >= 4 and chain[0].distance_to(chain[chain.size() - 1]) < 4.0:
			chain.remove_at(chain.size() - 1)
			if not Geometry2D.triangulate_polygon(chain).is_empty():
				out.append(chain)
	return out

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.025, 0.03, 0.05, 0.92))
	if _geo.is_empty() or not _geo.get("ok", false):
		var f := UiTheme.title_font()
		var fs := int(size.y * 0.55)
		draw_string(f, Vector2(0, size.y * 0.5 + fs * 0.36), "?", HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Color(UiTheme.GOLD, 0.85))
		return
	var cam: Rect2 = _geo.cam
	var view := cam.grow(cam.size.x * 0.06)
	var s := minf(size.x / view.size.x, size.y / view.size.y)
	var c := view.get_center()
	var half := size * 0.5
	var xf := func(p: Vector2) -> Vector2: return Vector2((p.x - c.x) * s + half.x, -(p.y - c.y) * s + half.y)
	var lw := 3.0 if detail else 2.0
	if detail:
		var step := 1000.0 * s
		var gx := fposmod(half.x - c.x * s, step)
		while gx < size.x:
			draw_line(Vector2(gx, 0), Vector2(gx, size.y), Color(1, 1, 1, 0.035), 1.0)
			gx += step
		var gy := fposmod(half.y + c.y * s, step)
		while gy < size.y:
			draw_line(Vector2(0, gy), Vector2(size.x, gy), Color(1, 1, 1, 0.035), 1.0)
			gy += step
		var tl: Vector2 = xf.call(Vector2(cam.position.x, cam.end.y))
		var br: Vector2 = xf.call(Vector2(cam.end.x, cam.position.y))
		_dashed_rect(Rect2(tl, br - tl), Color(UiTheme.STEEL, 0.35))
	for poly in _fills:
		var pts := PackedVector2Array()
		for p in poly:
			pts.append(xf.call(p))
		draw_colored_polygon(pts, Color(0.16, 0.18, 0.26, 0.95))
	for ln in _geo.lines:
		var pts := PackedVector2Array()
		for p in ln.pts:
			pts.append(xf.call(p))
		if pts.size() < 2:
			continue
		match ln.kind:
			"floor":
				if ln.pass:
					for i in pts.size() - 1:
						draw_dashed_line(pts[i], pts[i + 1], Color(UiTheme.STEEL, 0.95), lw, 7.0)
				else:
					draw_polyline(pts, Color(UiTheme.GOLD, 0.25), lw * 3.0, true)
					draw_polyline(pts, Color(1.0, 0.92, 0.7), lw, true)
			_:
				draw_polyline(pts, Color(0.55, 0.6, 0.75, 0.7), maxf(1.0, lw - 1.0), true)
	if detail:
		var i := 0
		for sp in _geo.spawns:
			var q: Vector2 = xf.call(sp)
			var col: Color = UiTheme.PLAYER_COLORS[i % 4]
			draw_circle(q + Vector2(0, -6), 6.0, col)
			draw_string(UiTheme.bold_font(), q + Vector2(-8, -16), "P%d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
			i += 1

func _dashed_rect(rr: Rect2, col: Color) -> void:
	var a := rr.position
	var b := Vector2(rr.end.x, rr.position.y)
	var cc := rr.end
	var d := Vector2(rr.position.x, rr.end.y)
	draw_dashed_line(a, b, col, 1.0, 6.0)
	draw_dashed_line(b, cc, col, 1.0, 6.0)
	draw_dashed_line(cc, d, col, 1.0, 6.0)
	draw_dashed_line(d, a, col, 1.0, 6.0)
