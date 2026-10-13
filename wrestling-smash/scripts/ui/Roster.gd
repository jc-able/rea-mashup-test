## Roster / stage data and runtime asset loading for the menus: portraits, wrestler GLB models
## and stage collision outlines. Uses the imported resources when the editor has imported them
## (<file>.import exists, also true in exports) and otherwise reads the raw files
## (Image.load_from_file / GLTFDocument), so the menus work before any import.
extends RefCounted

const ROSTER_PATH := "res://data/roster.json"
const WRESTLER_DIR := "res://assets/wrestlers/"
const STAGE_DIR := "res://data/ssb64/stages/"

static var _roster: Dictionary = {}
static var _portraits: Dictionary = {}
static var _models: Dictionary = {}
static var _stages: Dictionary = {}

static func data() -> Dictionary:
	if _roster.is_empty():
		var d = null
		if FileAccess.file_exists(ROSTER_PATH):
			d = JSON.parse_string(FileAccess.get_file_as_string(ROSTER_PATH))
		_roster = d if d is Dictionary else {}
		if not _roster.has("fighters"):
			_roster["fighters"] = []
		if not _roster.has("stages"):
			_roster["stages"] = []
	return _roster

static func fighters() -> Array:
	return data().fighters

static func stages() -> Array:
	return data().stages

static func fighter(fkind: int) -> Dictionary:
	for f in fighters():
		if int(f.get("fkind", -1)) == fkind:
			return f
	return {}

static func fighter_name(fkind: int) -> String:
	return str(fighter(fkind).get("name", "FIGHTER %d" % fkind))

static func fighter_slug(fkind: int) -> String:
	return str(fighter(fkind).get("slug", ""))

static func stage_by_gkind(gkind: int) -> Dictionary:
	for s in stages():
		if int(s.get("gkind", -1)) == gkind:
			return s
	return {}

static func portrait(slug: String) -> Texture2D:
	if slug == "":
		return null
	if _portraits.has(slug):
		return _portraits[slug]
	var path := WRESTLER_DIR + slug + "/portrait.png"
	var tex: Texture2D = null
	if FileAccess.file_exists(path + ".import"):
		var r = load(path)
		if r is Texture2D:
			tex = r
	if tex == null and FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img != null and not img.is_empty():
			img.generate_mipmaps()
			tex = ImageTexture.create_from_image(img)
	_portraits[slug] = tex
	return tex

static func has_model_cached(slug: String) -> bool:
	return _models.has(slug)

## Loads (once) the wrestler's rigged model; returns a template node that must not be added
## to the tree (use instantiate_model()).
static func model_template(slug: String) -> Node3D:
	if _models.has(slug):
		return _models[slug]
	var path := WRESTLER_DIR + slug + "/" + slug + ".glb"
	var node: Node3D = null
	if FileAccess.file_exists(path + ".import"):
		var ps = load(path)
		if ps is PackedScene:
			node = (ps as PackedScene).instantiate() as Node3D
	if node == null and FileAccess.file_exists(path):
		var doc := GLTFDocument.new()
		var st := GLTFState.new()
		if doc.append_from_file(path, st) == OK:
			node = doc.generate_scene(st) as Node3D
	_models[slug] = node
	return node

static func instantiate_model(slug: String) -> Node3D:
	var t := model_template(slug)
	return t.duplicate() as Node3D if t != null else null

static func clear_cache() -> void:
	for k in _models:
		var n = _models[k]
		if n != null and is_instance_valid(n):
			n.free()
	_models.clear()
	_portraits.clear()
	_stages.clear()

## Stage outline for previews: lines (SSB64 units, y up, moving yakumono at their start
## position), camera bounds, blast zone, battle spawn points, hazards.
static func stage_geometry(key: String) -> Dictionary:
	if _stages.has(key):
		return _stages[key]
	var out := {"ok": false, "lines": [], "cam": Rect2(-4000, -2000, 8000, 6000), "blast": Rect2(), "spawns": [], "hazards": []}
	var path := STAGE_DIR + key + ".json"
	var d = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if d is Dictionary:
		var origin: Dictionary = d.get("collision_origin_at_start", {})
		for ln in d.get("geometry", {}).get("lines", []):
			var off := Vector2.ZERO
			var o = origin.get(str(int(ln.get("yakumono_id", 0))), null)
			if o is Dictionary and o.get("applies_offset", false):
				off = Vector2(float(o.get("x", 0.0)), float(o.get("y", 0.0)))
			var pts := PackedVector2Array()
			for p in ln.get("points", []):
				pts.append(Vector2(float(p[0]), float(p[1])) + off)
			out.lines.append({"kind": str(ln.get("kind", "")), "pass": bool(ln.get("pass_through", false)), "pts": pts})
		var gd: Dictionary = d.get("ground_data", {})
		var l := float(gd.get("camera_bound_left", -4000)); var r := float(gd.get("camera_bound_right", 4000))
		var b := float(gd.get("camera_bound_bottom", -2000)); var t := float(gd.get("camera_bound_top", 4000))
		out.cam = Rect2(l, b, r - l, t - b)
		l = float(gd.get("map_bound_left", l)); r = float(gd.get("map_bound_right", r))
		b = float(gd.get("map_bound_bottom", b)); t = float(gd.get("map_bound_top", t))
		out.blast = Rect2(l, b, r - l, t - b)
		for m in d.get("map_objects", []):
			var kn := str(m.get("kind_name", ""))
			if kn.begins_with("nMPMapObjKindBattlePlayer"):
				out.spawns.append(Vector2(float(m.get("x", 0)), float(m.get("y", 0))))
		for h in d.get("hazards_summary", []):
			if h is Dictionary and h.has("name"):
				out.hazards.append(str(h.name))
		out.ok = true
	_stages[key] = out
	return out
