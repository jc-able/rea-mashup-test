## Headless test of the map collision port (Mpcollision / Mpprocess / Mpcommon).
## Run: cd game_check && Godot --headless --path . -s res://scripts/test/test_mp.gd
## Loads Dream Land (pupupu.json), checks the init tables against the exporter's derived tables,
## projects points onto the main floor and a platform, lands a falling fighter on a platform,
## grabs a ledge, and (if jungle.json exists) checks the moving platforms against the baked tables.
extends SceneTree

var failures: int = 0

func check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		failures += 1
		print("  FAIL ", what)

func _make_fighter(x: float, y: float, lr: int) -> Fighter:
	var fp := Fighter.new()
	var topn := DObj.new()

	topn.parent_gobj = fp
	fp.dobj = topn
	fp.joints[SSBDefs.nFTPartsJointTopN] = topn
	fp.lr = lr
	fp.fkind = SSBDefs.nFTKindMario
	fp.ga = SSBDefs.nMPKineticsAir
	# Mario: attributes map_coll {320, 190, 0, 150}, cliffcatch_coll {400, 360}
	fp.coll_data.map_coll.top = 320.0
	fp.coll_data.map_coll.center = 190.0
	fp.coll_data.map_coll.bottom = 0.0
	fp.coll_data.map_coll.width = 150.0
	fp.coll_data.p_map_coll = fp.coll_data.map_coll
	fp.coll_data.cliffcatch_coll = Vector2(400.0, 360.0)
	fp.coll_data.floor_line_id = -1
	fp.coll_data.ignore_line_id = -1
	topn.translate = Vector3(x, y, 0.0)
	fp.coll_data.pos_prev = topn.translate
	fp.coll_data.update_tic = Mpcollision.gMPCollisionUpdateTic
	Sim.add_gobj(fp, SSBDefs.nGCCommonLinkIDFighter)
	return fp

## ftMainProcPhysicsMap order: pos_prev = TopN, TopN += vel, pos_diff, floor speed, masks, proc_map.
func _physics(fp: Fighter, vel: Vector3) -> void:
	var topn: DObj = fp.joints[SSBDefs.nFTPartsJointTopN]

	fp.coll_data.pos_prev = topn.translate
	topn.translate += vel
	fp.coll_data.pos_diff = topn.translate - fp.coll_data.pos_prev

	if (fp.ga == SSBDefs.nMPKineticsGround) and (fp.coll_data.floor_line_id != -1) and (fp.coll_data.floor_line_id != -2) and (Mpcollision.mpCollisionCheckExistLineID(fp.coll_data.floor_line_id) != 0):
		fp.coll_data.vel_speed = Mpcollision.mpCollisionGetSpeedLineID(fp.coll_data.floor_line_id)
		topn.translate += fp.coll_data.vel_speed
	else:
		fp.coll_data.vel_speed = Vector3.ZERO
	fp.coll_data.mask_prev = fp.coll_data.mask_curr
	fp.coll_data.mask_curr = 0
	fp.coll_data.is_coll_end = 0
	fp.coll_data.mask_stat = 0
	fp.coll_data.mask_unk = 0

func _print_project(label: String, pos: Vector3) -> Dictionary:
	var r: Dictionary = Mpcollision.mpCollisionCheckProjectFloor(pos)
	print("  ProjectFloor %s %s -> ret=%d line=%d ga_dist=%.3f flags=0x%04X angle=%s" % [label, str(pos), r.ret, r.project_line_id, r.ga_dist, r.stand_coll_flags, str(r.angle)])
	return r

func _init() -> void:
	Sim.reset()

	var data: Dictionary = Mpcollision.port_read_stage_json("pupupu")

	if data.is_empty():
		print("pupupu.json not found under ", Mpcollision.STAGE_JSON_DIR, " - nothing to test")
		quit(0)
		return
	check(Mpcollision._f32(0.1) == 0.10000000149011612, "_f32 rounds to IEEE single precision")
	print("== Dream Land (pupupu.json) ==")
	var t0 := Time.get_ticks_usec()
	Mpcollision.load_stage_json(data)
	print("  load_stage_json: %d us" % (Time.get_ticks_usec() - t0))

	# --- init tables vs. the exporter's ports of the same init functions -----------------
	var derived: Dictionary = data.geometry.derived
	check(Mpcollision.gMPCollisionLinesNum == int(derived.gMPCollisionLinesNum), "gMPCollisionLinesNum = %d" % Mpcollision.gMPCollisionLinesNum)
	var vi_ok := true
	for line_id in range(Mpcollision.gMPCollisionLinesNum):
		var a = Mpcollision.gMPCollisionVertexInfo.vertex_info[line_id]
		var b: Dictionary = derived.vertex_info[line_id]
		if (a.yakumono_id != int(b.yakumono_id)) or (a.line_type != int(b.line_type)) or (a.coll_pos_next != int(b.coll_pos_next)) or (a.coll_pos_prev != int(b.coll_pos_prev)) or (a.edge_next_line_id != int(b.edge_next_line_id)) or (a.edge_prev_line_id != int(b.edge_prev_line_id)):
			vi_ok = false
			print("    vertex_info[%d] differs: %s vs %s" % [line_id, [a.yakumono_id, a.line_type, a.coll_pos_next, a.coll_pos_prev, a.edge_next_line_id, a.edge_prev_line_id], b])
	check(vi_ok, "vertex_info (yakumono_id, line_type, coll_pos_next/prev, edge links) matches exporter")
	for k in 4:
		var g = Mpcollision.gMPCollisionLineGroups[k]
		print("  gMPCollisionLineGroups[%d]: count=%d ids=%s" % [k, g.line_count, str(g.line_id)])
	var bnd = Mpcollision.gMPCollisionBounds
	print("  gMPCollisionBounds start T/B/R/L = %s %s %s %s, current = %s %s %s %s" % [bnd.start.top, bnd.start.bottom, bnd.start.right, bnd.start.left, bnd.current.top, bnd.current.bottom, bnd.current.right, bnd.current.left])
	check((bnd.current.top == 1542.0) and (bnd.current.bottom == -1072.0) and (bnd.current.right == 2318.0) and (bnd.current.left == -2318.0), "bounds = collision extents (1542, -1072, 2318, -2318)")
	print("  camera bounds T/B/R/L = %d %d %d %d, blast = %d %d %d %d" % [Mpcollision.gMPCollisionGroundData.camera_bound_top, Mpcollision.gMPCollisionGroundData.camera_bound_bottom, Mpcollision.gMPCollisionGroundData.camera_bound_right, Mpcollision.gMPCollisionGroundData.camera_bound_left, Mpcollision.gMPCollisionGroundData.map_bound_top, Mpcollision.gMPCollisionGroundData.map_bound_bottom, Mpcollision.gMPCollisionGroundData.map_bound_right, Mpcollision.gMPCollisionGroundData.map_bound_left])

	# --- point projections ------------------------------------------------------------------
	var r: Dictionary
	r = _print_project("x=0 (main floor)", Vector3(0.0, 500.0, 0.0))
	check((r.ret == 1) and (r.project_line_id == 3) and is_equal_approx(r.ga_dist, -500.0), "x=0,y=500 projects onto main floor line 3, dist -500")
	r = _print_project("x=0 (under top platform)", Vector3(0.0, 2000.0, 0.0))
	check((r.ret == 1) and (r.project_line_id == 0) and is_equal_approx(r.ga_dist, -458.0), "x=0,y=2000 projects onto top platform line 0, dist -458")
	r = _print_project("right platform", Vector3(1400.0, 1000.0, 0.0))
	check((r.ret == 1) and (r.project_line_id == 1) and is_equal_approx(r.ga_dist, -93.0) and (r.stand_coll_flags & SSBDefs.MAP_VERTEX_COLL_PASS), "x=1400,y=1000 projects onto pass-through platform line 1 (y=907)")
	r = _print_project("left platform", Vector3(-1400.0, 1000.0, 0.0))
	check((r.ret == 1) and (r.project_line_id == 2) and is_equal_approx(r.ga_dist, -96.0), "x=-1400,y=1000 projects onto platform line 2 (y=904)")
	r = _print_project("off stage", Vector3(3000.0, 1000.0, 0.0))
	check(r.ret == 0, "x=3000 has no floor below")

	var fc: Dictionary = Mpcollision.mpCollisionGetFCCommonFloor(3, Vector3(100.0, 40.0, 0.0))
	print("  GetFCCommonFloor(line 3, (100,40)) -> ret=%d dist=%.3f flags=0x%04X angle=%s" % [fc.ret, fc.dist, fc.flags, str(fc.angle)])
	check((fc.ret == 1) and is_equal_approx(fc.dist, -40.0) and (fc.flags == SSBDefs.MAP_VERTEX_COLL_CLIFF) and (fc.angle == Vector3(0, 1, 0)), "GetFCCommonFloor on main floor")
	# C-style NULL outputs passed as null are accepted (in-out values default)
	var fn: Dictionary = Mpcollision.mpCollisionGetFCCommonFloor(3, Vector3(100.0, 40.0, 0.0), null, null, Vector3(9, 9, 9))
	var ln: Dictionary = Mpcollision.mpCollisionCheckFloorLineCollisionSame(Vector3(0.0, 100.0, 0.0), Vector3(0.0, 50.0, 0.0), null, 7, null, null)
	check((fn.ret == 1) and (fn.angle == Vector3(0, 1, 0)) and (ln.ret == 0) and (ln.stand_line_id == 7), "NULL (null) out-arguments accepted; unwritten in-out keeps passed value")
	var lc: Dictionary = Mpcollision.mpCollisionCheckFloorLineCollisionSame(Vector3(1400.0, 1000.0, 0.0), Vector3(1400.0, 800.0, 0.0))
	print("  FloorLineCollisionSame (1400,1000)->(1400,800) -> ret=%d line=%d at %s" % [lc.ret, lc.stand_line_id, str(lc.ga_last)])
	check((lc.ret == 1) and (lc.stand_line_id == 1) and (lc.ga_last == Vector3(1400.0, 907.0, 0.0)), "falling segment hits platform line 1 at y=907")
	var wc: Dictionary = Mpcollision.mpCollisionCheckRWallLineCollisionSame(Vector3(2400.0, -300.0, 0.0), Vector3(2000.0, -300.0, 0.0))
	print("  RWallLineCollisionSame (2400,-300)->(2000,-300) -> ret=%d line=%d at %s angle=%s" % [wc.ret, wc.stand_line_id, str(wc.ga_last), str(wc.angle)])
	check((wc.ret == 1) and (wc.stand_line_id == 5), "moving left under the right edge hits right wall line 5")
	var el: Vector3 = Mpcollision.mpCollisionGetFloorEdgeL(3)
	var er: Vector3 = Mpcollision.mpCollisionGetFloorEdgeR(3)
	print("  main floor edges L=%s R=%s, edge lines under L/R = %d/%d" % [str(el), str(er), Mpcollision.mpCollisionGetEdgeUnderLLineID(3), Mpcollision.mpCollisionGetEdgeUnderRLineID(3)])
	check((el == Vector3(-2318, 0, 0)) and (er == Vector3(2318, 0, 0)), "main floor edges")
	for player in 4:
		print("  spawn P%d = %s" % [player + 1, str(Mpcollision.mpCollisionGetPlayerMapObjPosition(player))])
	check(Mpcollision.mpCollisionGetPlayerMapObjPosition(0) == Vector3(0, 6, 0), "P1 spawn (0, 6)")

	# --- falling fighter lands on the right platform (mpCommonCheckFighterLanding) -------------
	var fp := _make_fighter(1400.0, 1100.0, +1)
	var landed_frame := -1
	t0 = Time.get_ticks_usec()
	for frame in 10:
		_physics(fp, Vector3(0.0, -40.0, 0.0))
		if Mpcommon.mpCommonCheckFighterLanding(fp) != 0:
			Mpcommon.mpCommonSetFighterGround(fp)
			landed_frame = frame
			Sim.run_frame()
			break
		Sim.run_frame() # layer-1 ground process: gMPCollisionUpdateTic++
	print("  landing: frame %d, pos %s, floor_line_id %d, mask_stat 0x%04X (%d us)" % [landed_frame, str(fp.dobj.translate), fp.coll_data.floor_line_id, fp.coll_data.mask_stat, Time.get_ticks_usec() - t0])
	check((landed_frame == 4) and (fp.coll_data.floor_line_id == 1) and (fp.dobj.translate.y == 907.0) and (fp.ga == SSBDefs.nMPKineticsGround), "fighter lands on platform line 1 at y=907")
	for frame in 5:
		_physics(fp, Vector3(25.0, 0.0, 0.0))
		var on_floor: int = Mpcommon.mpCommonCheckFighterOnFloor(fp)
		Sim.run_frame()
		if on_floor == 0:
			print("    left the floor at frame ", frame)
	print("  walking: pos %s, floor_line_id %d" % [str(fp.dobj.translate), fp.coll_data.floor_line_id])
	check((fp.dobj.translate == Vector3(1525.0, 907.0, 0.0)) and (fp.coll_data.floor_line_id == 1), "walking right stays on line 1")
	Sim.remove_gobj(fp)

	# --- ledge grab on the right edge of the main floor (mpCommonCheckFighterCliff) ------------
	var fq := _make_fighter(2568.0, -200.0, -1)
	var grab_frame := -1
	for frame in 10:
		_physics(fq, Vector3(0.0, -30.0, 0.0))
		if Mpcommon.mpCommonCheckFighterCliff(fq) != 0:
			grab_frame = frame
			Sim.run_frame()
			break
		Sim.run_frame()
	print("  ledge: frame %d, pos %s, cliff_id %d, mask_stat 0x%04X" % [grab_frame, str(fq.dobj.translate), fq.coll_data.cliff_id, fq.coll_data.mask_stat])
	check((grab_frame == 5) and (fq.coll_data.cliff_id == 3) and ((fq.coll_data.mask_stat & SSBDefs.MAP_FLAG_RCLIFF) != 0), "right ledge of line 3 caught (RCLIFF)")
	Sim.remove_gobj(fq)

	# --- moving collision: Congo Jungle platforms vs. the exporter's baked animation ---------
	var jungle: Dictionary = Mpcollision.port_read_stage_json("jungle")

	if not jungle.is_empty():
		print("== Congo Jungle (jungle.json) moving platforms ==")
		Mpcollision.load_stage_json(jungle)
		var max_dev := 0.0
		var frames := 600
		for frame in range(frames + 1):
			for yid in [1, 2]:
				var baked: Dictionary = jungle.yakumono[yid].animation.baked_60hz
				var n: int = baked.cycle_length
				var bx = baked.translate.x
				var by = baked.translate.y
				var want := Vector2(float(bx[frame % n]) if bx is Array else float(bx.constant), float(by[frame % n]) if by is Array else float(by.constant))
				var dobj: DObj = Mpcollision.gMPCollisionYakumonoDObjs.dobjs[yid]
				max_dev = maxf(max_dev, (Vector2(dobj.translate.x, dobj.translate.y) - want).length())
			if frame < frames:
				Sim.run_frame()
		var d1: DObj = Mpcollision.gMPCollisionYakumonoDObjs.dobjs[1]
		print("  yakumono 1 after %d frames: %s speed %s, max deviation from baked = %s" % [frames, str(d1.translate), str(Mpcollision.gMPCollisionSpeeds[1]), str(max_dev)])
		check(max_dev < 0.01, "yakumono 1/2 follow the baked animation (max dev %s)" % str(max_dev))
		var line_ids: Array = []
		for line_id in jungle.yakumono[1].line_ids:
			line_ids.append(int(line_id)) # JSON numbers are floats
		var probe := Vector3(d1.translate.x, d1.translate.y + 300.0, 0.0)
		r = Mpcollision.mpCollisionCheckProjectFloor(probe)
		print("  project above moving platform %s -> ret=%d line=%d dist=%.3f (platform lines %s)" % [str(probe), r.ret, r.project_line_id, r.ga_dist, str(line_ids)])
		check((r.ret == 1) and (r.project_line_id in line_ids), "projection follows the moving platform")
		var bj = Mpcollision.gMPCollisionBounds
		print("  bounds current T/B/R/L = %s %s %s %s, diff = %s %s %s %s, update tic %d" % [bj.current.top, bj.current.bottom, bj.current.right, bj.current.left, bj.diff.top, bj.diff.bottom, bj.diff.right, bj.diff.left, Mpcollision.gMPCollisionUpdateTic])

	print("test_mp: %d failure(s)" % failures)
	quit(1 if failures else 0)
