## Visual check of colour animations on the wrestler models: starts a standalone battle, then (as a
## debug action) starts the Star (id 74) colour script on P1 and DamageFireStrong (id 14) on P2 and
## saves frames. Output: evidence/render/colanim_f<frame>.png
extends SceneTree

var battle: Node
var shots := [330, 336, 342, 348]

func _initialize() -> void:
	var ps: PackedScene = load("res://scenes/Battle.tscn")
	battle = ps.instantiate()
	var cfg := BattleRunner.default_config()
	cfg.gkind = SSBDefs.nGRKindPupupu
	cfg.items_on = false
	cfg.players[0].fkind = 0
	cfg.players[1].fkind = 7
	for i in 2:
		cfg.players[i].pkind = SSBDefs.nFTPlayerKindCom
	battle.setup(cfg)
	root.add_child(battle)

func _process(_d: float) -> bool:
	if battle.runner == null:
		return false
	var f: int = battle.runner.frame
	if f == 320:
		for g in battle.fighters:
			Ftparam.ftParamCheckSetColAnimID(g.colanim, 74 if g.player == 0 else 14, 0)
	if not shots.is_empty() and f >= shots[0]:
		shots.pop_front()
		await RenderingServer.frame_post_draw
		var img := root.get_viewport().get_texture().get_image()
		var p := ProjectSettings.globalize_path("res://").path_join("../evidence/render/colanim_f%d.png" % f)
		img.save_png(p)
		var line := "frame %d" % f
		for g in battle.fighters:
			var ca = g.colanim
			line += "  P%d colanim %d use1 %d rgba %d,%d,%d,%d" % [g.player + 1, ca.colanim_id, ca.is_use_color1, ca.color1.r, ca.color1.g, ca.color1.b, ca.color1.a]
		print(line)
	return shots.is_empty()
