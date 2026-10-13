## Visual for one fighter: the wrestler model retargeted from the SSB joint tree, a player-colour
## floor ring + rim light, a "P1"/"CPU" tag, colanim/invincibility flashes, hit-lag shuffle shake and
## invisibility. Reads the Fighter object only.
extends Node3D

const RU = preload("res://scripts/render/RenderUtil.gd")
const WL = preload("res://scripts/render/WrestlerLibrary.gd")
const RT = preload("res://scripts/render/Retarget.gd")
const SvrPoseDriver = preload("res://scripts/render/SvrPoseDriver.gd")

## Presentation animation set: SSB64 motions retargeted onto the wrestler, or the wrestler's own
## SmackDown vs. Raw 2011 motions (SvrPoseDriver). Gameplay is the same in both.
enum AnimSet { SSB64, SVR }

## dFTDisplayMainShufflePositions (src/ft/ftdisplaymain.c): hit-lag shake offsets, world units.
const SHUFFLE := [
	[Vector2(0, -100), Vector2(0, -50), Vector2(0, 100), Vector2(0, 50)],
	[Vector2(0, -20), Vector2(15, 5), Vector2(-15, 5), Vector2(0, 0)],
]

const OVERLAY_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;
uniform vec4 rim_color : source_color = vec4(1.0, 0.2, 0.2, 1.0);
uniform float rim_strength = 0.2;
void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = rim_color.rgb * f * rim_strength;
}
"""
## Colour animation (GMColAnim color1, run by the ported ftMainUpdateColAnim): SSB64 draws fighters
## with G_RM_FOG_PRIM_A and color1 as the fog colour, i.e. pixel = lerp(pixel, color1.rgb, color1.a).
const FLASH_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back;
uniform vec4 flash : source_color = vec4(0.0);
void fragment() {
	ALBEDO = flash.rgb;
	ALPHA = flash.a;
}
"""

var fp = null
var slug := ""
var display_name := ""
var color := Color.WHITE
var model: Node3D
var skel: Skeleton3D
var retarget: RT
var svr: SvrPoseDriver
var anim_set: int = AnimSet.SSB64
var _svr_active := false
var meshes: Array = []
var overlay: ShaderMaterial
var flash_mat: ShaderMaterial
var ring: MeshInstance3D
var tag: Label3D
var jw: Array = []
var show_model := true
var _t := 0.0

func setup(p_fp) -> void:
	fp = p_fp
	jw.resize(SSBDefs.FTPARTS_JOINT_NUM_MAX)
	var info: Dictionary = RU.roster().get(int(fp.fkind), {})
	slug = info.get("slug", "")
	display_name = info.get("name", "Fighter %d" % fp.fkind)
	var is_cpu: bool = fp.pkind == SSBDefs.nFTPlayerKindCom
	color = RU.player_color(fp.player)
	overlay = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = OVERLAY_SHADER
	overlay.shader = sh
	overlay.set_shader_parameter("rim_color", color)
	flash_mat = ShaderMaterial.new()
	var fsh := Shader.new()
	fsh.code = FLASH_SHADER
	flash_mat.shader = fsh
	overlay.next_pass = flash_mat
	if slug != "":
		model = WL.instantiate(slug)
	if model != null:
		add_child(model)
		skel = WL.find_skeleton(model)
		WL.find_meshes(model, meshes)
		for m in meshes:
			(m as MeshInstance3D).material_overlay = overlay
		retarget = RT.new()
		if not retarget.setup(fp, model, skel, WL.meta(slug)):
			push_warning("retarget setup failed for fkind %d (%s)" % [fp.fkind, slug])
			retarget = null
		svr = SvrPoseDriver.new()
		if not svr.setup(fp, model, skel, slug, retarget.scale_k if retarget != null else 1.0):
			svr = null
		else:
			svr.preload_clips()
	# floor ring
	ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.9
	tm.outer_radius = 1.0
	tm.rings = 32
	tm.ring_segments = 6
	ring.mesh = tm
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color(color, 0.75)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.no_depth_test = false
	ring.material_override = rm
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	tag = Label3D.new()
	tag.text = ("CPU" if is_cpu else "P%d" % (fp.player + 1))
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.fixed_size = true
	tag.pixel_size = 0.0009
	tag.font_size = 40
	tag.outline_size = 12
	tag.modulate = color.lightened(0.15)
	tag.outline_modulate = Color(0.05, 0.05, 0.08, 0.9)
	tag.render_priority = 10
	tag.outline_render_priority = 9
	add_child(tag)

func update(delta: float) -> void:
	if fp == null:
		return
	_t += delta
	RU.fighter_world(fp, jw)
	var topn = jw[0]
	if topn == null:
		visible = false
		return
	var invisible: bool = fp.is_invisible != 0 and fp.display_mode == SSBDefs.nDBDisplayModeMaster
	var extra := Vector3.ZERO
	if fp.shuffle_tics != 0:
		var tbl: Array = SHUFFLE[1 if fp.is_shuffle_electric != 0 else 0]
		var o: Vector2 = tbl[clampi(fp.shuffle_frame_index, 0, 3)]
		extra = Vector3(o.x, o.y, 0.0) * RU.S
	if model != null:
		model.visible = show_model and not invisible
		if model.visible:
			var used_svr := false
			if anim_set == AnimSet.SVR and svr != null:
				used_svr = svr.apply(fp, jw, extra)
			if not used_svr:
				if _svr_active and svr != null:
					svr.release()
				if retarget != null:
					retarget.apply(jw, extra)
			_svr_active = used_svr
	_update_flash()
	var feet: Vector3 = (topn as Transform3D).origin * RU.S
	ring.visible = not invisible and fp.ga == SSBDefs.nMPKineticsGround
	if ring.visible:
		var r := 0.55
		if retarget != null:
			r = clampf(retarget.standing_height * RU.S * 0.22, 0.4, 1.4)
		ring.transform = Transform3D(Basis.from_scale(Vector3(r, 0.6, r)), feet + Vector3(0, 0.02, 0))
	tag.visible = not invisible and fp.is_playertag_hide == 0
	if tag.visible:
		var top := feet.y + (retarget.standing_height if retarget != null else 400.0) * RU.S
		if _svr_active and model != null and model.visible:
			top = head_world().y + 0.35 * svr.scale_k / 2.0
		elif retarget != null and model != null and model.visible:
			top = retarget.bone_world("atama").y + 0.35 * retarget.scale_k / 2.0
		tag.position = Vector3(feet.x, top + 0.45, feet.z)

## Switch the presentation animation set (gameplay is unaffected).
func set_anim_set(mode: int) -> void:
	if mode == anim_set:
		return
	anim_set = mode
	if mode != AnimSet.SVR and svr != null and _svr_active:
		svr.release()
		_svr_active = false

## What the model is showing this frame: {set, role, status, clip, move, source, origin}.
func anim_info() -> Dictionary:
	if anim_set == AnimSet.SVR and svr != null:
		var d: Dictionary = svr.info.duplicate()
		d["set"] = "SvR 2011"
		return d
	return {"set": "SSB64", "origin": "SSB64 motion (retargeted)", "role": "", "clip": ""}

## Head position from the current skeleton pose (world metres).
func head_world() -> Vector3:
	var b := skel.find_bone("atama") if skel != null else -1
	if b < 0 or not skel.is_inside_tree():
		return global_position
	return skel.global_transform * skel.get_bone_global_pose(b).origin

func _exit_tree() -> void:
	if svr != null:
		svr.dispose()

func _update_flash() -> void:
	var f := Color(0, 0, 0, 0)
	var ca = fp.colanim
	if ca != null and ca.is_use_color1:
		f = Color8(int(ca.color1.r), int(ca.color1.g), int(ca.color1.b), int(ca.color1.a))
	flash_mat.set_shader_parameter("flash", f)

func joint_world(jid: int):
	return jw[jid] if jid >= 0 and jid < jw.size() else null
