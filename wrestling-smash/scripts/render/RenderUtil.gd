## Shared render-side helpers (read-only views of the ported engine state).
## World mapping: Godot metres = SSB64 units * S (SSB +Y up, +Z towards the camera, same handedness).
extends RefCounted

const S := 0.01

const PLAYER_COLORS := [Color(0.93, 0.22, 0.2), Color(0.25, 0.45, 0.95), Color(0.98, 0.8, 0.15), Color(0.25, 0.8, 0.35)]
const CPU_COLOR := Color(0.62, 0.62, 0.66)

## SSB64 joint local matrix (row-vector convention of gmCollisionTransformMatrixAll):
## rows r0..r2 (scaled by scale.xyz) become the basis columns, translate the origin.
static func dobj_local(d) -> Transform3D:
	var r: Vector3 = d.rotate
	var sx := sin(r.x)
	var cx := cos(r.x)
	var sy := sin(r.y)
	var cy := cos(r.y)
	var sz := sin(r.z)
	var cz := cos(r.z)
	var s: Vector3 = d.scale
	return Transform3D(Basis(
		Vector3(cy * cz, cy * sz, -sy) * s.x,
		Vector3(sx * sy * cz - cx * sz, sx * sy * sz + cx * cz, sx * cy) * s.y,
		Vector3(cx * sy * cz + sx * sz, cx * sy * sz - sx * cz, cx * cy) * s.z), d.translate)

static func euler_local(t: Vector3, r: Vector3, s: Vector3) -> Transform3D:
	var sx := sin(r.x)
	var cx := cos(r.x)
	var sy := sin(r.y)
	var cy := cos(r.y)
	var sz := sin(r.z)
	var cz := cos(r.z)
	return Transform3D(Basis(
		Vector3(cy * cz, cy * sz, -sy) * s.x,
		Vector3(sx * sy * cz - cx * sz, sx * sy * sz + cx * cz, sx * cy) * s.y,
		Vector3(cx * sy * cz + sx * sz, cx * sy * sz - sx * cz, cx * cy) * s.z), t)

## World transforms (SSB units) of every joint of a fighter, indexed by FtParts.joint_id.
## Walks the live DObj tree (parent/child/sib links) so hidden parts and the detached
## TransN leaf are handled exactly as the engine currently links them.
static func fighter_world(fp, out: Array) -> void:
	out.fill(null)
	var root = fp.dobj
	if root == null:
		return
	var w := dobj_local(root)
	_store(root, w, out)
	if root.child != null:
		_walk(root.child, w, out)

static func _store(d, w: Transform3D, out: Array) -> void:
	var ud = d.user_data
	if ud is FtParts:
		var jid: int = ud.joint_id
		if jid >= 0 and jid < out.size():
			out[jid] = w

static func _walk(d, pw: Transform3D, out: Array) -> void:
	while d != null:
		var w := pw * dobj_local(d)
		_store(d, w, out)
		if d.child != null:
			_walk(d.child, w, out)
		d = d.sib_next

## Generic DObj tree walk (weapons/items/ground): calls cb(dobj, world) for every node.
static func dobj_tree_world(root, cb: Callable) -> void:
	if root == null:
		return
	var w := dobj_local(root)
	cb.call(root, w)
	if root.child != null:
		_walk_cb(root.child, w, cb)

static func _walk_cb(d, pw: Transform3D, cb: Callable) -> void:
	while d != null:
		var w := pw * dobj_local(d)
		cb.call(d, w)
		if d.child != null:
			_walk_cb(d.child, w, cb)
		d = d.sib_next

## SSB-space transform -> Godot world (uniform scale S on positions; basis keeps SSB scale * S).
static func to_godot(t: Transform3D) -> Transform3D:
	return Transform3D(t.basis * S, t.origin * S)

static func player_color(player: int, pkind: int = -1) -> Color:
	if player < 0 or player >= PLAYER_COLORS.size():
		return CPU_COLOR
	return PLAYER_COLORS[player]

static func roster() -> Dictionary:
	return _Roster.get_roster()

## Resolves a project-relative asset path ("assets/wrestlers/..."): res:// in the game project,
## ../game/<rel> when running from the headless check harness (which only links scripts/data).
static func asset_path(rel: String) -> String:
	var p := "res://" + rel
	if FileAccess.file_exists(p):
		return p
	var alt := (ProjectSettings.globalize_path("res://") + "../game/" + rel).simplify_path()
	if FileAccess.file_exists(alt):
		return alt
	return p

static func load_texture_file(rel: String) -> Texture2D:
	var path := asset_path(rel)
	if not FileAccess.file_exists(path):
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	var img := Image.new()
	var err := ERR_FILE_UNRECOGNIZED
	if rel.ends_with(".png"):
		err = img.load_png_from_buffer(bytes)
	elif rel.ends_with(".jpg") or rel.ends_with(".jpeg"):
		err = img.load_jpg_from_buffer(bytes)
	if err != OK:
		return null
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

class _Roster:
	static var _cache: Dictionary = {}
	static func get_roster() -> Dictionary:
		if not _cache.is_empty():
			return _cache
		var path := "res://data/roster.json"
		if FileAccess.file_exists(path):
			var d = JSON.parse_string(FileAccess.get_file_as_string(path))
			if d is Dictionary:
				for f in d.get("fighters", []):
					_cache[int(f.fkind)] = f
				_cache["stages"] = d.get("stages", [])
		return _cache
