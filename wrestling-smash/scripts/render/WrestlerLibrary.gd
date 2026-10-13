## Loads the wrestler GLBs at runtime through GLTFDocument (no editor import needed), caches one
## template scene per slug and hands out duplicates. Embedded textures get mipmaps once.
extends RefCounted

const RU = preload("res://scripts/render/RenderUtil.gd")

static var _templates: Dictionary = {}     # slug -> Node3D (not in tree)
static var _meta: Dictionary = {}          # slug -> wrestler json sidecar
static var _portraits: Dictionary = {}

static func meta(slug: String) -> Dictionary:
	if _meta.has(slug):
		return _meta[slug]
	var path := RU.asset_path("assets/wrestlers/%s/%s.json" % [slug, slug])
	var d := {}
	if FileAccess.file_exists(path):
		var j = JSON.parse_string(FileAccess.get_file_as_string(path))
		if j is Dictionary:
			d = j
	_meta[slug] = d
	return d

static func portrait(slug: String) -> Texture2D:
	if not _portraits.has(slug):
		_portraits[slug] = RU.load_texture_file("assets/wrestlers/%s/portrait.png" % slug)
	return _portraits[slug]

## Returns a fresh instance (Node3D root containing Armature/Skeleton3D + skinned mesh) or null.
static func instantiate(slug: String) -> Node3D:
	var tpl: Node3D = _templates.get(slug, null)
	if tpl == null:
		tpl = _load(slug)
		if tpl == null:
			return null
		_templates[slug] = tpl
	return tpl.duplicate() as Node3D

static func _load(slug: String) -> Node3D:
	var path := RU.asset_path("assets/wrestlers/%s/%s.glb" % [slug, slug])
	if not FileAccess.file_exists(path):
		push_warning("wrestler GLB missing: " + path)
		return null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED
	var err := doc.append_from_file(path, state)
	if err != OK:
		push_warning("GLB load failed (%d): %s" % [err, path])
		return null
	var scene := doc.generate_scene(state) as Node3D
	if scene == null:
		return null
	_fix_materials(scene, {})
	return scene

static func _fix_materials(n: Node, done: Dictionary) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		mi.extra_cull_margin = 4.0
		var mesh := mi.mesh
		if mesh != null:
			for s in mesh.get_surface_count():
				var m = mesh.surface_get_material(s)
				if m is BaseMaterial3D and not done.has(m):
					done[m] = true
					var bm := m as BaseMaterial3D
					bm.albedo_texture = _mip(bm.albedo_texture)
					bm.normal_texture = _mip(bm.normal_texture)
					bm.roughness_texture = _mip(bm.roughness_texture)
					bm.metallic_texture = _mip(bm.metallic_texture)
					bm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
					if bm.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
						bm.roughness = maxf(bm.roughness, 0.55)
	for c in n.get_children():
		_fix_materials(c, done)

static func _mip(t: Texture2D) -> Texture2D:
	if t == null or not (t is ImageTexture):
		return t
	var img := t.get_image()
	if img == null or img.has_mipmaps():
		return t
	if img.is_compressed():
		return t
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

static func find_skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var s := find_skeleton(c)
		if s != null:
			return s
	return null

static func find_meshes(n: Node, out: Array) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		find_meshes(c, out)
