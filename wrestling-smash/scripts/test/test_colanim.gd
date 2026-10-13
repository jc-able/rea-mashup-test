## Runs every colour-animation script (Gmcolscripts) through the ported interpreter
## (Ftmain.ftMainUpdateColAnim) for up to 900 frames with effects and sound skipped, and reports
## the frame on which it ended, the deepest script stack used and the colours it produced.
##   Godot --headless --path game_check -s res://scripts/test/test_colanim.gd
extends SceneTree

func _initialize() -> void:
	var bad := 0
	for id in Gmcolscripts.DESCS.size():
		var d: Array = Gmcolscripts.DESCS[id]
		if d[0] == null:
			continue
		var ca := GMColAnim.new()
		Ftparam.ftParamCheckSetColAnimID(ca, id, 0)
		var max_sid := 0
		var end_frame := -1
		var colors := {}
		for f in 900:
			var r: int = Ftmain.ftMainUpdateColAnim(ca, null, 1, 1)
			for c in ca.cs:
				max_sid = maxi(max_sid, c.script_id)
			if ca.is_use_color1:
				colors["%02X%02X%02X%02X" % [ca.color1.r, ca.color1.g, ca.color1.b, ca.color1.a]] = true
			if r != 0:
				end_frame = f + 1
				break
		if max_sid > 5:
			bad += 1
		print("%2d %-52s prio %d  end %4s  max_stack %d  colours %d" % [id, d[0], d[1], str(end_frame) if end_frame > 0 else "loop", max_sid, colors.size()])
	print("scripts over the 5-word stack: %d" % bad)
	quit(0)
