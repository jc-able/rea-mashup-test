## Blockout stage built from the ported map collision (Mpcollision): one mesh group per yakumono
## (collision DObj), built once in yakumono-local vertex space and moved every frame by the offset
## the engine applies to that yakumono's vertices (moving platforms), hidden when its collision is
## Off. Closed line loops become extruded solid masses, open chains are closed downwards or turned
## into slabs, pass-through floors (vertex flag 0x4000) become thin platforms, cliff segments
## (0x8000) get a ledge highlight. Also sets up the sky gradient and lighting from ground_data.
extends Node3D

const RU = preload("res://scripts/render/RenderUtil.gd")

const FLAG_PASS := 0x4000
const FLAG_CLIFF := 0x8000
const DEPTH_MAIN := 380.0
const DEPTH_PLATFORM := 250.0
const PLATFORM_THICK := 62.0
const SLAB_THICK := 70.0

var groups: Array = []          # [{yaku, node, line, base: Vector3}]
var ledge_marks: Array = []     # [{node}] (part of groups)
var stage_key := ""
var base_color := Color(0.55, 0.55, 0.6)
var top_color := Color(0.6, 0.75, 0.45)
var plat_color := Color(0.85, 0.78, 0.62)
var fog := Color(0.5, 0.7, 0.9)
var env: Environment
var built := false
var _mat_solid: ShaderMaterial
var _mat_ledge: StandardMaterial3D

const STAGE_SHADER := """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
uniform float grid_major = 5.0;
uniform float grid_minor = 1.0;
varying vec3 lpos;
varying vec3 lnrm;
void vertex() {
	lpos = VERTEX;
	lnrm = NORMAL;
}
float gridline(vec2 p, float cell) {
	vec2 q = p / cell;
	vec2 g = abs(fract(q - 0.5) - 0.5) / max(fwidth(q), vec2(1e-4));
	return 1.0 - min(min(g.x, g.y), 1.0);
}
void fragment() {
	vec3 n = abs(lnrm);
	vec2 p = n.z > 0.5 ? lpos.xy : (n.y > 0.5 ? lpos.xz : lpos.zy);
	float l = max(gridline(p, grid_minor) * 0.35, gridline(p, grid_major) * 0.8);
	vec3 c = COLOR.rgb;
	c = mix(c, c * 0.72, l);
	ALBEDO = c;
	ROUGHNESS = 0.82;
	SPECULAR = 0.25;
}
"""

const SKY_SHADER := """
shader_type sky;
uniform vec3 top_color : source_color = vec3(0.2, 0.35, 0.7);
uniform vec3 horizon_color : source_color = vec3(0.6, 0.75, 0.95);
uniform vec3 bottom_color : source_color = vec3(0.1, 0.1, 0.15);
void sky() {
	float y = EYEDIR.y;
	vec3 c = y > 0.0 ? mix(horizon_color, top_color, pow(clamp(y * 1.6, 0.0, 1.0), 0.7))
			: mix(horizon_color, bottom_color, pow(clamp(-y * 2.2, 0.0, 1.0), 0.6));
	float band = exp(-abs(y) * 22.0) * 0.12;
	COLOR = c + vec3(band);
}
"""

func build() -> void:
	for c in get_children():
		c.queue_free()
	groups.clear()
	var gd = Mpcollision.gMPCollisionGroundData
	if gd == null or Mpcollision.gMPCollisionVertexInfo == null:
		return
	var fc: Dictionary = gd.get("fog_color", {"r": 120, "g": 170, "b": 230})
	fog = Color8(int(fc.r), int(fc.g), int(fc.b))
	_pick_palette()
	_mat_solid = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = STAGE_SHADER
	_mat_solid.shader = sh
	_mat_ledge = StandardMaterial3D.new()
	_mat_ledge.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_ledge.albedo_color = Color(1.0, 0.93, 0.6)
	_mat_ledge.vertex_color_use_as_albedo = true

	# --- static line topology per yakumono ---------------------------------------------------
	var vinfo = Mpcollision.gMPCollisionVertexInfo.vertex_info
	var by_yaku := {}
	for line_id in Mpcollision.gMPCollisionLinesNum:
		var y: int = vinfo[line_id].yakumono_id
		if not by_yaku.has(y):
			by_yaku[y] = []
		by_yaku[y].append(line_id)
	for y in by_yaku:
		var node := Node3D.new()
		node.name = "Yakumono%d" % y
		add_child(node)
		_build_yakumono(node, by_yaku[y])
		var rep: int = by_yaku[y][0]
		groups.append({"yaku": y, "node": node, "line": rep, "base": _static_vertex(rep, 0)})
	_setup_environment()
	built = true
	update()

func _pick_palette() -> void:
	var h := fog.h
	var s := clampf(fog.s, 0.15, 0.55)
	var v := clampf(fog.v, 0.35, 0.9)
	base_color = Color.from_hsv(fmod(h + 0.5, 1.0), s * 0.35, lerpf(0.42, 0.55, v))
	top_color = Color.from_hsv(fmod(h + 0.62, 1.0), s * 0.75 + 0.15, 0.62)
	plat_color = Color.from_hsv(fmod(h + 0.1, 1.0), 0.18, 0.86)
	var roster := RU.roster()
	for st in roster.get("stages", []):
		if int(st.gkind) == G.gSCManagerBattleState.gkind:
			stage_key = st.key
	match stage_key:
		"pupupu", "yoster", "explain":
			top_color = Color(0.45, 0.72, 0.36)
			base_color = Color(0.62, 0.5, 0.38)
		"jungle":
			top_color = Color(0.36, 0.6, 0.27)
			base_color = Color(0.5, 0.36, 0.25)
		"castle", "hyrule":
			top_color = Color(0.5, 0.66, 0.4)
			base_color = Color(0.5, 0.47, 0.55)
		"zebes":
			top_color = Color(0.62, 0.36, 0.3)
			base_color = Color(0.36, 0.28, 0.33)
		"sector":
			top_color = Color(0.6, 0.65, 0.75)
			base_color = Color(0.42, 0.45, 0.55)
		"yamabuki":
			top_color = Color(0.68, 0.66, 0.6)
			base_color = Color(0.5, 0.52, 0.6)
		"inishie":
			top_color = Color(0.82, 0.55, 0.3)
			base_color = Color(0.62, 0.42, 0.3)

func _static_vertex(line_id: int, i: int) -> Vector3:
	var links = Mpcollision.gMPCollisionVertexLinks[line_id]
	var vid: int = Mpcollision.gMPCollisionVertexIDs.vertex_id[links.vertex1 + i]
	var vp = Mpcollision.gMPCollisionVertexData.vpos[vid]
	return Vector3(vp.pos.x, vp.pos.y, 0.0)

func _line_points(line_id: int) -> Dictionary:
	var links = Mpcollision.gMPCollisionVertexLinks[line_id]
	var pts := PackedVector2Array()
	var ids := PackedInt32Array()
	var flags := PackedInt32Array()
	for i in links.vertex2:
		var vid: int = Mpcollision.gMPCollisionVertexIDs.vertex_id[links.vertex1 + i]
		var vp = Mpcollision.gMPCollisionVertexData.vpos[vid]
		pts.append(Vector2(vp.pos.x, vp.pos.y))
		ids.append(vid)
		flags.append(vp.vertex_flags)
	return {"pts": pts, "ids": ids, "flags": flags,
		"kind": Mpcollision.gMPCollisionVertexInfo.vertex_info[line_id].line_type}

func _build_yakumono(node: Node3D, line_ids: Array) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ledge := SurfaceTool.new()
	ledge.begin(Mesh.PRIMITIVE_TRIANGLES)
	var solid: Array = []
	for lid in line_ids:
		var lp := _line_points(lid)
		var is_pass: bool = lp.kind == SSBDefs.nMPLineKindFloor and (lp.flags[0] & FLAG_PASS) != 0
		if is_pass:
			_slab_down(st, lp.pts, PLATFORM_THICK, DEPTH_PLATFORM, plat_color, true)
		else:
			solid.append(lp)
	# chain solid lines through shared end vertices
	var chains := _chains(solid)
	for ch in chains:
		var pts: PackedVector2Array = ch.pts
		var kinds: Dictionary = ch.kinds
		if ch.closed:
			if not _extrude(st, pts, DEPTH_MAIN):
				_slab_down(st, pts, SLAB_THICK, DEPTH_MAIN, base_color, false)
		elif kinds.has(SSBDefs.nMPLineKindRWall) or kinds.has(SSBDefs.nMPLineKindLWall):
			var poly := _close_down(pts, 0.0)
			if not _extrude(st, poly, DEPTH_MAIN):
				_slab_down(st, pts, SLAB_THICK, DEPTH_MAIN, base_color, false)
		elif kinds.has(SSBDefs.nMPLineKindFloor) and kinds.size() == 1:
			var w := absf(pts[pts.size() - 1].x - pts[0].x)
			var thick := clampf(w * 0.22, 140.0, 900.0)
			var poly2 := _close_down(pts, thick)
			if not _extrude(st, poly2, DEPTH_MAIN):
				_slab_down(st, pts, thick, DEPTH_MAIN, base_color, false)
		else:
			# lone ceilings / walls: thin slab on the solid side
			var k: int = kinds.keys()[0]
			var off := Vector2(0, SLAB_THICK)
			if k == SSBDefs.nMPLineKindLWall:
				off = Vector2(SLAB_THICK, 0)
			elif k == SSBDefs.nMPLineKindRWall:
				off = Vector2(-SLAB_THICK, 0)
			_slab_offset(st, pts, off, DEPTH_MAIN * 0.6, base_color)
	# ledge highlights on cliff floor segments of solid floors
	for lp in solid:
		if lp.kind != SSBDefs.nMPLineKindFloor:
			continue
		var pts2: PackedVector2Array = lp.pts
		for i in pts2.size() - 1:
			if lp.flags[i] & FLAG_CLIFF:
				_edge_strip(ledge, pts2[i], pts2[i + 1])
		# grabbable ends: end segments with the cliff flag
		var n := pts2.size()
		if n >= 2:
			if lp.flags[0] & FLAG_CLIFF:
				_ledge_cap(ledge, pts2[0])
			if lp.flags[n - 2] & FLAG_CLIFF:
				_ledge_cap(ledge, pts2[n - 1])
	st.generate_normals()
	var mesh := st.commit()
	if mesh.get_surface_count() > 0:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = _mat_solid
		mi.scale = Vector3.ONE * RU.S
		node.add_child(mi)
	var lm := ledge.commit()
	if lm.get_surface_count() > 0:
		var mi2 := MeshInstance3D.new()
		mi2.mesh = lm
		mi2.material_override = _mat_ledge
		mi2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi2.scale = Vector3.ONE * RU.S
		node.add_child(mi2)

## Undirected chaining of lines by shared end vertex ids.
func _chains(lines: Array) -> Array:
	var used := {}
	var out := []
	var end_map := {}
	for i in lines.size():
		var ids: PackedInt32Array = lines[i].ids
		for e in [ids[0], ids[ids.size() - 1]]:
			if not end_map.has(e):
				end_map[e] = []
			end_map[e].append(i)
	for i in lines.size():
		if used.has(i):
			continue
		# walk backwards to a chain start (or loop)
		var start := i
		var start_end: int = lines[i].ids[0]
		var guard := 0
		while guard < 64:
			guard += 1
			var nxt := -1
			for j in end_map.get(start_end, []):
				if j != start and not used.has(j):
					nxt = j
			if nxt < 0 or nxt == i:
				break
			var ids2: PackedInt32Array = lines[nxt].ids
			start = nxt
			start_end = ids2[ids2.size() - 1] if ids2[0] == start_end else ids2[0]
			if start == i:
				break
		# walk forward from start
		var pts := PackedVector2Array()
		var kinds := {}
		var cur := start
		var cur_entry := start_end
		var closed := false
		guard = 0
		while cur >= 0 and guard < 64:
			guard += 1
			used[cur] = true
			var lp: Dictionary = lines[cur]
			kinds[lp.kind] = true
			var p: PackedVector2Array = lp.pts
			var ids3: PackedInt32Array = lp.ids
			var forward: bool = ids3[0] == cur_entry
			var seq := p if forward else _reversed(p)
			for k in seq.size():
				if pts.size() > 0 and k == 0:
					continue
				pts.append(seq[k])
			var exit_id: int = ids3[ids3.size() - 1] if forward else ids3[0]
			var nxt2 := -1
			for j in end_map.get(exit_id, []):
				if j != cur and not used.has(j):
					nxt2 = j
			if nxt2 < 0:
				for j in end_map.get(exit_id, []):
					if j == start and j != cur:
						closed = true
				break
			cur = nxt2
			cur_entry = exit_id
		if closed and pts.size() > 1 and pts[0].distance_to(pts[pts.size() - 1]) < 1.0:
			pts.remove_at(pts.size() - 1)
		out.append({"pts": pts, "kinds": kinds, "closed": closed})
	return out

func _reversed(p: PackedVector2Array) -> PackedVector2Array:
	var r := PackedVector2Array()
	for i in range(p.size() - 1, -1, -1):
		r.append(p[i])
	return r

## Close an open chain by dropping both ends to a common bottom (thick > 0: floor-only chain, the
## bottom sits `thick` below the lowest point and is tapered inwards).
func _close_down(pts: PackedVector2Array, thick: float) -> PackedVector2Array:
	var poly := pts.duplicate()
	var miny := INF
	for p in pts:
		miny = minf(miny, p.y)
	var a: Vector2 = pts[0]
	var b: Vector2 = pts[pts.size() - 1]
	if thick > 0.0:
		var bottom := miny - thick
		var taper := thick * 0.45 * signf(b.x - a.x)
		poly.append(Vector2(b.x - taper, bottom))
		poly.append(Vector2(a.x + taper, bottom))
	else:
		var bottom2 := miny - 40.0
		if b.y > bottom2 + 1.0:
			poly.append(Vector2(b.x, bottom2))
		if a.y > bottom2 + 1.0:
			poly.append(Vector2(a.x, bottom2))
	return poly

func _extrude(st: SurfaceTool, poly: PackedVector2Array, depth: float) -> bool:
	if poly.size() < 3:
		return false
	var clean := PackedVector2Array()
	for p in poly:
		if clean.is_empty() or clean[clean.size() - 1].distance_to(p) > 0.5:
			clean.append(p)
	if clean.size() > 3 and clean[0].distance_to(clean[clean.size() - 1]) < 0.5:
		clean.remove_at(clean.size() - 1)
	var tri := Geometry2D.triangulate_polygon(clean)
	if tri.is_empty():
		return false
	var ccw := _area(clean) > 0.0
	var miny := INF
	var maxy := -INF
	for p in clean:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	var span := maxf(maxy - miny, 1.0)
	# front (+z) and back (-z) caps, darker towards the bottom
	for t in range(0, tri.size(), 3):
		for zi in 2:
			var z := depth if zi == 0 else -depth
			var vs: Array = []
			var cs: Array = []
			for k in 3:
				var p: Vector2 = clean[tri[t + k]]
				var shade := lerpf(0.68, 1.0, clampf((p.y - miny) / span, 0.0, 1.0))
				vs.append(Vector3(p.x, p.y, z))
				cs.append(base_color * Color(shade, shade, shade, 1.0))
			_tri(st, vs, cs, Vector3(0, 0, 1) if zi == 0 else Vector3(0, 0, -1))
	# side walls; floor-facing sides get the top colour and a lip on the front face
	var n := clean.size()
	for i in n:
		var a: Vector2 = clean[i]
		var b: Vector2 = clean[(i + 1) % n]
		var e := b - a
		if e.length() < 0.5:
			continue
		var outward := Vector2(e.y, -e.x) if ccw else Vector2(-e.y, e.x)
		outward = outward.normalized()
		var col := base_color * Color(0.86, 0.86, 0.88)
		if outward.y > 0.55:
			col = top_color
		elif outward.y < -0.55:
			col = base_color * Color(0.6, 0.6, 0.64)
		var on := Vector3(outward.x, outward.y, 0.0)
		var qa := Vector3(a.x, a.y, depth)
		var qb := Vector3(b.x, b.y, depth)
		var qc := Vector3(b.x, b.y, -depth)
		var qd := Vector3(a.x, a.y, -depth)
		_tri(st, [qa, qb, qc], [col, col, col], on)
		_tri(st, [qa, qc, qd], [col, col, col], on)
		if outward.y > 0.55:
			var lip := minf(28.0, span * 0.3)
			var lc := top_color * Color(0.86, 0.86, 0.86)
			_quad_front(st, Vector2(a.x, a.y - lip), Vector2(b.x, b.y - lip), Vector2(b.x, b.y), Vector2(a.x, a.y), depth + 1.0, lc)
	return true

## Emits one triangle wound so that it faces `n_out` (Godot front faces are clockwise).
func _tri(st: SurfaceTool, vs: Array, cs: Array, n_out: Vector3) -> void:
	var a: Vector3 = vs[0]
	var b: Vector3 = vs[1]
	var c: Vector3 = vs[2]
	var order := [0, 1, 2]
	if (b - a).cross(c - a).dot(n_out) > 0.0:
		order = [0, 2, 1]
	for i in order:
		st.set_color(cs[i])
		st.add_vertex(vs[i])

func _area(p: PackedVector2Array) -> float:
	var s := 0.0
	for i in p.size():
		var a := p[i]
		var b := p[(i + 1) % p.size()]
		s += a.x * b.y - b.x * a.y
	return s * 0.5

func _quad_front(st: SurfaceTool, a: Vector2, b: Vector2, c: Vector2, d: Vector2, z: float, col: Color) -> void:
	var p := [Vector3(a.x, a.y, z), Vector3(b.x, b.y, z), Vector3(c.x, c.y, z), Vector3(d.x, d.y, z)]
	_tri(st, [p[0], p[1], p[2]], [col, col, col], Vector3(0, 0, 1))
	_tri(st, [p[0], p[2], p[3]], [col, col, col], Vector3(0, 0, 1))

## Platform / slab: the polyline extruded downwards by `thick`, depth +-`depth`.
func _slab_down(st: SurfaceTool, pts: PackedVector2Array, thick: float, depth: float, col: Color, is_platform: bool) -> void:
	_slab_offset(st, pts, Vector2(0, -thick), depth, col, is_platform)

func _slab_offset(st: SurfaceTool, pts: PackedVector2Array, off: Vector2, depth: float, col: Color, is_platform := false) -> void:
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		if a.x > b.x and off.x == 0.0:
			var t := a
			a = b
			b = t
		var poly := PackedVector2Array([a, b, b + off, a + off])
		var saved := base_color
		var saved_top := top_color
		base_color = col
		if is_platform:
			top_color = col.lightened(0.25)
		_extrude(st, poly, depth)
		base_color = saved
		top_color = saved_top

func _edge_strip(st: SurfaceTool, a: Vector2, b: Vector2) -> void:
	var h := 9.0
	var z := DEPTH_MAIN + 4.0
	var col := Color(1.0, 0.9, 0.55, 1.0) * Color(0.85, 0.85, 0.85)
	_quad_front(st, Vector2(a.x, a.y - h), Vector2(b.x, b.y - h), Vector2(b.x, b.y + 2.0), Vector2(a.x, a.y + 2.0), z, col)

func _ledge_cap(st: SurfaceTool, p: Vector2) -> void:
	var s := 22.0
	var z := DEPTH_MAIN + 6.0
	_quad_front(st, Vector2(p.x - s, p.y - s), Vector2(p.x + s, p.y - s), Vector2(p.x + s, p.y + s * 0.5), Vector2(p.x - s, p.y + s * 0.5), z, Color(1.0, 0.95, 0.7))

func _setup_environment() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SKY_SHADER
	sm.shader = sh
	var horizon := fog
	if horizon.v < 0.25:
		horizon = Color.from_hsv(horizon.h if horizon.s > 0.1 else 0.62, 0.5, 0.25)
	elif horizon.v < 0.5 and horizon.s > 0.7:
		# very dark saturated fog (Congo Jungle): warm dusk instead of a flat red wall
		horizon = Color.from_hsv(fmod(horizon.h + 0.06, 1.0), 0.55, 0.62)
	sm.set_shader_parameter("horizon_color", horizon)
	sm.set_shader_parameter("top_color", Color.from_hsv(horizon.h, minf(horizon.s * 1.2 + 0.1, 1.0), horizon.v * 0.55))
	sm.set_shader_parameter("bottom_color", horizon.darkened(0.6))
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = horizon.lerp(Color(0.85, 0.85, 0.9), 0.55)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	we.environment = env
	add_child(we)
	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.light_energy = 1.05
	key.rotation_degrees = Vector3(-38.0, -28.0, 0.0)
	key.shadow_enabled = false
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.light_energy = 0.32
	fill.light_color = horizon.lerp(Color.WHITE, 0.6)
	fill.rotation_degrees = Vector3(-15.0, 150.0, 0.0)
	add_child(fill)

## Per frame: move yakumono groups by the engine's current vertex offset, hide collision-Off ones.
func update() -> void:
	if not built:
		return
	for g in groups:
		var node: Node3D = g.node
		var line: int = g.line
		if Mpcollision.mpCollisionCheckExistLineID(line) == 0:
			node.visible = false
			continue
		node.visible = true
		var cur: Vector3 = Mpcollision.mpCollisionGetVertexPositionID(line, 0)
		var off: Vector3 = cur - (g.base as Vector3)
		node.position = Vector3(off.x, off.y, 0.0) * RU.S
