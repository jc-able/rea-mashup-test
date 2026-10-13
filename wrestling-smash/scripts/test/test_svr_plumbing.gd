## Plumbing test of the SvR animation mode with a SYNTHETIC clip (test fixture, not SvR data):
## injects a map entry idle -> TEST_wave and a generated clip (right upper arm swinging, root bobbing)
## into the SvrAnimMap / SvrClip caches, runs a standalone battle in SvR mode with two idle
## players and captures frames. Checks: clip reaches the skeleton by bone name, loop timing,
## vertical-only root motion, facing from SSB64, provenance label.
extends SceneTree

const SvrClip = preload("res://scripts/render/SvrClip.gd")
const SvrAnimMap = preload("res://scripts/render/SvrAnimMap.gd")

var battle: Node
var shots := [262, 270, 278]
var injected := false

func _initialize() -> void:
	SvrAnimMap._data = {"common": {"idle": {"clip": "TEST_wave", "timing": "loop", "move": "synthetic test fixture", "source": "test"}}}
	var ps: PackedScene = load("res://scenes/Battle.tscn")
	battle = ps.instantiate()
	var cfg := BattleRunner.default_config()
	cfg.gkind = SSBDefs.nGRKindPupupu
	cfg.items_on = false
	cfg.players[0].fkind = 0
	cfg.players[1].fkind = 7
	for i in 2:
		cfg.players[i].pkind = SSBDefs.nFTPlayerKindMan
	cfg["anim_set"] = "svr"
	InputMapper.scripted[0] = {"button": 0, "stick": Vector2i.ZERO}
	InputMapper.scripted[1] = {"button": 0, "stick": Vector2i.ZERO}
	battle.setup(cfg)
	root.add_child(battle)

func _make_clip(skel: Skeleton3D):
	var c = SvrClip.new()
	c.key = "TEST_wave"
	c.frames = 40
	c.fps = 60.0
	c.bones = PackedStringArray(["root", "r_ninoude"])
	c.rot_varies = PackedByteArray([0, 1])
	c.pos_varies = PackedByteArray([1, 0])
	var rr := skel.get_bone_rest(skel.find_bone("root"))
	var ar := skel.get_bone_rest(skel.find_bone("r_ninoude"))
	var q0 := rr.basis.get_rotation_quaternion()
	c.rot = [PackedFloat32Array([q0.x, q0.y, q0.z, q0.w]), PackedFloat32Array()]
	var p0 := rr.origin
	c.pos = [PackedFloat32Array(), PackedFloat32Array([ar.origin.x, ar.origin.y, ar.origin.z])]
	var qa := ar.basis.get_rotation_quaternion()
	for f in 40:
		var ph := TAU * f / 40.0
		var q := qa * Quaternion(Vector3(0, 0, 1), sin(ph) * 1.2)
		c.rot[1].append_array(PackedFloat32Array([q.x, q.y, q.z, q.w]))
		c.pos[0].append_array(PackedFloat32Array([p0.x + 0.3, p0.y + sin(ph) * 0.06, p0.z + 0.3]))
	c.ok = true
	return c

func _process(_d: float) -> bool:
	if battle.runner == null:
		return false
	if not injected and not battle.fighters.is_empty():
		var fr = battle.fighters.values()[0]
		SvrClip._cache["TEST_wave"] = _make_clip(fr.skel)
		injected = true
	var f: int = battle.runner.frame
	if not shots.is_empty() and f >= shots[0]:
		shots.pop_front()
		var line := "frame %d" % f
		for g in battle.fighters:
			var fr = battle.fighters[g]
			var d: Dictionary = fr.anim_info()
			var b: int = fr.skel.find_bone("r_ninoude")
			var rb: int = fr.skel.find_bone("root")
			line += "  P%d role %s clip %s t %.1f arm %s root %s" % [g.player + 1, d.get("role", ""), d.get("clip", ""), float(d.get("t", -1)),
				str(fr.skel.get_bone_pose_rotation(b)), str(fr.skel.get_bone_pose_position(rb))]
		print(line)
		if shots.size() == 1:
			var img := root.get_viewport().get_texture().get_image()
			img.save_png(ProjectSettings.globalize_path("res://").path_join("../evidence/render/svr_plumbing_test_f%d.png" % f))
	return shots.is_empty()
