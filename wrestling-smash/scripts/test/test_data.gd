## Headless check of the SSB64 data loader (SSBData): run with
##   Godot --headless --path game_check -s res://scripts/test/test_data.gd
extends SceneTree

func _initialize() -> void:
	var t0 := Time.get_ticks_msec()
	var fails := 0
	var kinds := [SSBDefs.nFTKindMario, SSBDefs.nFTKindFox, SSBDefs.nFTKindDonkey, SSBDefs.nFTKindSamus,
		SSBDefs.nFTKindLuigi, SSBDefs.nFTKindLink, SSBDefs.nFTKindYoshi, SSBDefs.nFTKindCaptain,
		SSBDefs.nFTKindKirby, SSBDefs.nFTKindPikachu, SSBDefs.nFTKindPurin, SSBDefs.nFTKindNess]
	for k in kinds:
		var fd: FtData = SSBData.get_fighter(k)
		if fd == null:
			print("FAIL load ", k)
			fails += 1
			continue
		var nscripts := fd.scripts.size()
		var ncmds := 0
		for s in fd.scripts.values():
			ncmds += s.cmds.size()
		var with_anim := 0
		for md in fd.mainmotion:
			if md != null and md.anim != null:
				with_anim += 1
		print("%-8s motions=%d (anim %d) scripts=%d cmds=%d anims=%d hi=%d lo=%d hurt=%d shield_tables=%d" % [
			fd.kind, fd.mainmotion.size(), with_anim, nscripts, ncmds, fd.anims.size(),
			fd.commonparts[0].size(), fd.commonparts[1].size(), fd.attr.damage_coll_descs.size(),
			fd.attr.shield_anim_joints.size()])
	# Mario Jab1 (nFTCommonMotionAttack11): WaitAsync(2), MakeAttackColl joints 10 & 9, dmg 2, size 160, angle 361, kbs 50, bkb 8
	var mario: FtData = SSBData.get_fighter(SSBDefs.nFTKindMario)
	var md = mario.mainmotion[SSBDefs.nFTCommonMotionAttack11]
	print("Attack11 motion: ", md.name, " anim ", md.anim_name, " script ", md.script.scr.name if md.script else "null")
	var p: MotionPtr = md.script
	var seen := 0
	var i: int = p.index
	while i < p.scr.cmds.size():
		var c: Dictionary = p.scr.cmds[i]
		var line := "  op %d" % c.op
		if c.op == SSBDefs.nFTMotionEventMakeAttackColl:
			line += " attack_id=%d joint=%d dmg=%d size=%d off=(%d,%d,%d) angle=%d kbs=%d kbw=%d bkb=%d ga=%d sd=%d fgm=%d/%d elem=%d" % [
				c.attack_id, c.joint_id, c.damage, c.size, c.off_x, c.off_y, c.off_z, c.angle, c.knockback_scale,
				c.knockback_weight, c.knockback_base, c.is_hit_ground_air, c.shield_damage, c.fgm_kind, c.fgm_level, c.element]
			seen += 1
		elif c.op == SSBDefs.nFTMotionEventAsyncWait or c.op == SSBDefs.nFTMotionEventSyncWait:
			line += " wait %d" % c.value
		print(line)
		if c.op == SSBDefs.nFTMotionEventEnd:
			break
		i = c.next
	if seen < 2:
		print("FAIL: expected 2 hitboxes in Jab1")
		fails += 1
	# Damage script table [2][27]
	var dst := SSBData.damage_script_table()
	print("damage table rows=", dst.size(), " cols=", dst[0].size() if dst.size() else 0)
	# Attributes sanity
	var a: Dictionary = mario.attr
	print("mario size=", a.size, " weight=", a.weight, " gravity=", a.gravity, " jumps_max=", a.jumps_max,
		" map_coll top=", a.map_coll.top, " hurt1=", a.damage_coll_descs[1])
	print("thrown_status[0]=", a.thrown_status[0])
	print("errors: ", SSBData.errors.size())
	for e in SSBData.errors.slice(0, 20):
		print("  ", e)
	print("elapsed ms: ", Time.get_ticks_msec() - t0)
	print("RESULT: ", "OK" if fails == 0 else "FAIL %d" % fails)
	quit(0 if fails == 0 else 1)
