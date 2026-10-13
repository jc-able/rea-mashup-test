## 1:1 port of src/ft/ftshadow.c (ssb-decomp-re): the fighter drop shadow (visual only).
##
## The geometry logic (floor projection, clipping the shadow quad to the floor line's edges and
## bending it over up to two extra floor vertices) is ported exactly. Instead of emitting RDP
## display-list commands, ftShadowProcDisplay leaves what C would draw in the FTShadow struct:
##   fs.draw_vtx        - the Vtx buffer used this frame (fs.vtx1 / fs.vtx2) or null (nothing drawn)
##   fs.draw_vertex_num - gSPVertex count (0, 4, 6 or 8)
##   fs.draw_tris       - flat gSP2Triangles index list (3 indices per triangle)
##   fs.draw_prim_color - gDPSetPrimColor [r, g, b, a]
## Each Vtx is {"n": {"ob": [x, y, z], "flag", "tc": [s, t], "n": [nx, ny, nz], "a"}} (C Vtx.n, s16 ob/tc).
## The texture is the 16x16 I4 llEFCommonEffects2ShadowTextureImage (mirror/wrap) modulated by
## the prim color (dFTShadowNoPrevLinkDL render state).
class_name Ftshadow
extends Port

# // // // // // // // // // // // //
# //                               //
# //       INITIALIZED DATA        //
# //                               //
# // // // // // // // // // // // //

## 0x80188410 - render state set before the first shadow of the DL link (display list; render only)
static var dFTShadowNoPrevLinkDL: Array = [
	"gsDPPipeSync()",
	"gsDPSetTextureLUT(G_TT_NONE)",
	"gsDPSetRenderMode(G_RM_AA_XLU_SURF, G_RM_AA_XLU_SURF2)",
	"gsDPSetCombineMode(G_CC_MODULATEIA_PRIM, G_CC_MODULATEIA_PRIM)",
	"gsSPTexture(0x8000, 0x8000, 0, G_TX_RENDERTILE, G_ON)",
	"gsDPSetBlendColor(0x00, 0x00, 0x00, 0x0F)",
	"gsDPSetAlphaCompare(G_AC_THRESHOLD)",
	"gsSPClearGeometryMode(G_ZBUFFER | G_SHADE | G_LIGHTING | G_SHADING_SMOOTH)",
	"gsSPEndDisplayList()",
]

## 0x80188458 - render state restored after the last shadow of the DL link (display list; render only)
static var dFTShadowNoNextLinkDL: Array = [
	"gsDPPipeSync()",
	"gsDPSetRenderMode(G_RM_AA_ZB_OPA_SURF, G_RM_AA_ZB_OPA_SURF2)",
	"gsSPTexture(0, 0, 0, G_TX_RENDERTILE, G_OFF)",
	"gsDPSetAlphaCompare(G_AC_NONE)",
	"gsSPSetGeometryMode(G_ZBUFFER | G_SHADE | G_LIGHTING | G_SHADING_SMOOTH)",
	"gsSPEndDisplayList()",
]

## Port of FTShadow (src/ft/fttypes.h): { Vtx vtx1[8]; Vtx vtx2[8]; s32 player; s32 unused; }
class FTShadow:
	var vtx1: Array = []
	var vtx2: Array = []
	var player: int = 0
	var unused: int = 0
	# port-only render output (see the file header)
	var draw_vtx = null
	var draw_vertex_num: int = 0
	var draw_tris: Array = []
	var draw_prim_color: Array = [0, 0, 0, 0]

	static func make_vtx() -> Dictionary:
		return {"n": {"ob": [0, 0, 0], "flag": 0, "tc": [0, 0], "n": [0, 0, 0], "a": 0}}

	func _init() -> void:
		for i in 8:
			vtx1.append(make_vtx())
			vtx2.append(make_vtx())

## C (s16) conversion of an f32 (truncate toward zero, keep the low 16 bits).
static func _s16(x: float) -> int:
	var v: int = int(x)
	return ((v + 0x8000) & 0xFFFF) - 0x8000

## gSYTaskmanTaskID (src/sys/taskman.c) selects the vertex double buffer. Looked up dynamically
## so this file parses while Taskman is still a stub (0 when not available).
static func _sy_taskman_task_id() -> int:
	var taskman_script: Object = Taskman
	var task_id = taskman_script.get("gSYTaskmanTaskID")
	if task_id == null:
		return 0
	return task_id

## Writes one Vtx_tn (C: sv->n.ob[0..2], sv->n.tc[0..1]).
static func _ftShadowSetVtx(sv: Dictionary, ob0: float, ob1: float, ob2: int, tc0: int, tc1: float) -> void:
	sv.n.ob[0] = _s16(ob0)
	sv.n.ob[1] = _s16(ob1)
	sv.n.ob[2] = ob2
	sv.n.tc[0] = tc0
	sv.n.tc[1] = _s16(tc1)

# // // // // // // // // // // // //
# //                               //
# //           FUNCTIONS           //
# //                               //
# // // // // // // // // // // // //

## 0x8013AE10
static func ftShadowGetAltitude(a: Vector3, b: Vector3, f: float) -> float:
	if b.x == a.x:
		return a.y
	else:
		return (((f - a.x) * (b.y - a.y)) / (b.x - a.x)) + a.y

## 0x8013AE60
static func ftShadowProcDisplay(shadow_gobj) -> void:
	var fs: FTShadow
	var fp: Fighter
	var shadow_center: float
	var shadow_vertex: Array
	var shadow_size: float
	var sv: int                       # Vtx *sv (index into shadow_vertex)
	var fighter_gobj
	var i: int
	var floor_line_id: int = -1
	var vertex_pos0 := Vector3()
	var vertex_pos1 := Vector3()
	var shadow_calc_left: float
	var shadow_calc_right: float
	var shadow_edge_left: float
	var shadow_alt_left: float = 0.0
	var shadow_alt_right: float = 0.0
	var spF0: float = 0.0
	var spEC: float = 0.0
	var spE8: float = 0.0
	var spE4: float = 0.0
	var spE0: float = 0.0
	var spDC: float = 0.0
	var gfx_vertex_num: int
	var coll_vertex_num: int
	var shadow_edge_right: float
	var edge_left_or_right: int = 0

	# if (shadow_gobj->dl_link_prev == NULL): gSPDisplayList(dFTShadowNoPrevLinkDL) and
	# gDPLoadTextureBlock_4b(shadow texture) - render state, applied by the renderer.
	fs = shadow_gobj.user_data

	fs.draw_vtx = null
	fs.draw_vertex_num = 0
	fs.draw_tris = []

	fighter_gobj = G.gSCManagerBattleState.players[fs.player].fighter_gobj

	fp = ftGetStruct(fighter_gobj)

	if (fp.is_invisible == FALSE) and (fp.is_shadow_hide == FALSE):
		var ga_last := Vector3()
		var pos_project := Vector3()
		var ga_dist: float = 0.0
		var translate: Vector3 = DObjGetStruct(fighter_gobj).translate

		if fp.ga == nMPKineticsGround:
			floor_line_id = fp.coll_data.floor_line_id

			ga_dist = 0
		else:
			# mpCollisionCheckProjectFloor(&translate, &floor_line_id, &ga_dist, NULL, NULL)
			var project = Mpcollision.mpCollisionCheckProjectFloor(translate)

			if project.ret == FALSE:
				floor_line_id = -1
			else:
				floor_line_id = project.project_line_id
				# C parameter name is ga_dist (PORTING.md's example calls it ground_dist)
				ga_dist = project.get("ga_dist", project.get("ground_dist", 0.0))
		if (floor_line_id != -1) and (fp.coll_data.floor_line_id != -2):
			pos_project.x = translate.x
			pos_project.y = translate.y - 65536

			# ((LWall(...) == FALSE) || !((y - ga_last.y) < -ga_dist)) && ((RWall(...) == FALSE) || !((y - ga_last.y) < -ga_dist))
			var is_draw: bool = false
			var is_lwall_clear: bool
			var lwall = Mpcollision.mpCollisionCheckLWallLineCollisionSame(translate, pos_project)

			if lwall.ret == FALSE:
				is_lwall_clear = true
			else:
				ga_last = lwall.ga_last
				is_lwall_clear = not ((translate.y - ga_last.y) < -ga_dist)
			if is_lwall_clear:
				var rwall = Mpcollision.mpCollisionCheckRWallLineCollisionSame(translate, pos_project)

				if rwall.ret == FALSE:
					is_draw = true
				else:
					ga_last = rwall.ga_last
					is_draw = not ((translate.y - ga_last.y) < -ga_dist)
			if is_draw:
				shadow_center = translate.x
				shadow_size = fp.attr.shadow_size
				shadow_calc_left = 0.0
				shadow_calc_right = 1984.0

				vertex_pos0 = Mpcollision.mpCollisionGetFloorEdgeL(floor_line_id)
				vertex_pos1 = Mpcollision.mpCollisionGetFloorEdgeR(floor_line_id)

				shadow_edge_left = shadow_center - shadow_size
				shadow_edge_right = shadow_center + shadow_size

				if shadow_edge_left < vertex_pos0.x:
					shadow_edge_left = vertex_pos0.x

					shadow_calc_left = (((shadow_edge_left - shadow_center) + shadow_size) * 992.0) / shadow_size

					if shadow_calc_left < 0.0:
						shadow_calc_left = 0.0
					if shadow_calc_left > 2048.0:
						shadow_calc_left = 2048.0
				if vertex_pos1.x < shadow_edge_right:
					shadow_edge_right = vertex_pos1.x

					shadow_calc_right = (((shadow_edge_right - shadow_center) * 992.0) / shadow_size) + 992.0

					if shadow_calc_right < 0.0:
						shadow_calc_right = 0.0
					if shadow_calc_right > 2048.0:
						shadow_calc_right = 2048.0
				gfx_vertex_num = 4
				coll_vertex_num = Mpcollision.mpCollisionGetVertexCountLineID(floor_line_id)

				if coll_vertex_num >= 3:
					vertex_pos0 = Mpcollision.mpCollisionGetVertexPositionID(floor_line_id, 0)
					vertex_pos1 = Mpcollision.mpCollisionGetVertexPositionID(floor_line_id, 1)

					if vertex_pos0.x < vertex_pos1.x:
						edge_left_or_right = 0

						i = 1
						while i < coll_vertex_num:
							vertex_pos1 = Mpcollision.mpCollisionGetVertexPositionID(floor_line_id, i)

							if (vertex_pos0.x <= shadow_edge_left) and (shadow_edge_left <= vertex_pos1.x):
								shadow_alt_left = ftShadowGetAltitude(vertex_pos0, vertex_pos1, shadow_edge_left)

								if (vertex_pos0.x <= shadow_edge_right) and (shadow_edge_right <= vertex_pos1.x):
									shadow_alt_right = ftShadowGetAltitude(vertex_pos0, vertex_pos1, shadow_edge_right)
								else:
									gfx_vertex_num = 6
									vertex_pos0 = vertex_pos1

									vertex_pos1 = Mpcollision.mpCollisionGetVertexPositionID(floor_line_id, i + 1)

									spE8 = vertex_pos0.x
									spE4 = vertex_pos0.y
									spF0 = (((shadow_calc_right - shadow_calc_left) * (vertex_pos0.x - shadow_edge_left)) / (shadow_edge_right - shadow_edge_left)) + shadow_calc_left

									if shadow_edge_right <= vertex_pos1.x:
										shadow_alt_right = ftShadowGetAltitude(vertex_pos0, vertex_pos1, shadow_edge_right)
									else:
										gfx_vertex_num = 8
										vertex_pos0 = vertex_pos1

										vertex_pos1 = Mpcollision.mpCollisionGetVertexPositionID(floor_line_id, i + 2)
										shadow_alt_right = ftShadowGetAltitude(vertex_pos0, vertex_pos1, shadow_edge_right)
										spE0 = vertex_pos0.x
										spDC = vertex_pos0.y
										spEC = (((shadow_calc_right - shadow_calc_left) * (vertex_pos0.x - shadow_edge_left)) / (shadow_edge_right - shadow_edge_left)) + shadow_calc_left
								break
							else:
								vertex_pos0 = vertex_pos1
							i += 1
					else:
						edge_left_or_right = 1
						vertex_pos1 = vertex_pos0

						i = 1
						while i < coll_vertex_num:
							vertex_pos0 = Mpcollision.mpCollisionGetVertexPositionID(floor_line_id, i)

							if (vertex_pos0.x <= shadow_edge_right) and (shadow_edge_right <= vertex_pos1.x):
								shadow_alt_right = ftShadowGetAltitude(vertex_pos0, vertex_pos1, shadow_edge_right)

								if (vertex_pos0.x <= shadow_edge_left) and (vertex_pos1.x >= shadow_edge_left):
									shadow_alt_left = ftShadowGetAltitude(vertex_pos0, vertex_pos1, shadow_edge_left)
								else:
									gfx_vertex_num = 6
									vertex_pos1 = vertex_pos0

									vertex_pos0 = Mpcollision.mpCollisionGetVertexPositionID(floor_line_id, i + 1)

									spE8 = vertex_pos1.x
									spE4 = vertex_pos1.y
									spF0 = (((shadow_calc_right - shadow_calc_left) * (vertex_pos1.x - shadow_edge_left)) / (shadow_edge_right - shadow_edge_left)) + shadow_calc_left

									if vertex_pos0.x <= shadow_edge_left:
										shadow_alt_left = ftShadowGetAltitude(vertex_pos0, vertex_pos1, shadow_edge_left)
									else:
										gfx_vertex_num = 8
										vertex_pos1 = vertex_pos0

										vertex_pos0 = Mpcollision.mpCollisionGetVertexPositionID(floor_line_id, i + 2)

										shadow_alt_left = ftShadowGetAltitude(vertex_pos0, vertex_pos1, shadow_edge_left)
										spE0 = vertex_pos1.x
										spDC = vertex_pos1.y

										spEC = (((shadow_calc_right - shadow_calc_left) * (vertex_pos1.x - shadow_edge_left)) / (shadow_edge_right - shadow_edge_left)) + shadow_calc_left
								break
							else:
								vertex_pos1 = vertex_pos0
							i += 1
				else:
					shadow_alt_left = ftShadowGetAltitude(vertex_pos0, vertex_pos1, shadow_edge_left)
					shadow_alt_right = ftShadowGetAltitude(vertex_pos0, vertex_pos1, shadow_edge_right)
				if gfx_vertex_num != 0:
					if _sy_taskman_task_id() != 0:
						shadow_vertex = fs.vtx2
					else:
						shadow_vertex = fs.vtx1

					# gDPPipeSync(gSYTaskmanDLHeads[0]++);

					# gDPSetPrimColor(gSYTaskmanDLHeads[0]++, 0, 0, r, g, b, a)
					var color: Dictionary
					if (G.gSCManagerBattleState.is_team_battle == TRUE) and (G.gSCManagerBattleState.is_not_teamshadows == FALSE):
						color = Ftcommondata.dFTCommonDataShadowColorTeams[fp.team]
					else:
						color = Ftcommondata.dFTCommonDataShadowColorDefault
					fs.draw_prim_color = [color.r, color.g, color.b, color.a]
					sv = 0

					_ftShadowSetVtx(shadow_vertex[sv], shadow_edge_left, shadow_alt_left, 200, 0, shadow_calc_left)

					sv += 1

					_ftShadowSetVtx(shadow_vertex[sv], shadow_edge_left, shadow_alt_left, -200, 1984, shadow_calc_left)

					sv += 1

					_ftShadowSetVtx(shadow_vertex[sv], shadow_edge_right, shadow_alt_right, 200, 0, shadow_calc_right)

					sv += 1

					_ftShadowSetVtx(shadow_vertex[sv], shadow_edge_right, shadow_alt_right, -200, 1984, shadow_calc_right)

					if gfx_vertex_num >= 6:
						sv += 1

						if spF0 < 0.0:
							spF0 = 0.0
						if spF0 > 2048.0:
							spF0 = 2048.0
						_ftShadowSetVtx(shadow_vertex[sv], spE8, spE4, 200, 0, spF0)

						sv += 1

						_ftShadowSetVtx(shadow_vertex[sv], spE8, spE4, -200, 1984, spF0)

						if gfx_vertex_num == 8:
							sv += 1

							if spEC < 0.0:
								spEC = 0.0
							if spEC > 2048.0:
								spEC = 2048.0
							_ftShadowSetVtx(shadow_vertex[sv], spE0, spDC, 200, 0, spEC)

							sv += 1

							_ftShadowSetVtx(shadow_vertex[sv], spE0, spDC, -200, 1984, spEC)

							# gSPVertex(shadow_vertex, 8, 0)
							fs.draw_vertex_num = 8

							if edge_left_or_right != 0:
								fs.draw_tris = [1, 0, 7, 0, 6, 7, 7, 6, 5, 6, 4, 5, 5, 4, 3, 4, 2, 3]
							else:
								fs.draw_tris = [1, 0, 5, 0, 4, 5, 5, 4, 7, 4, 6, 7, 7, 6, 3, 6, 2, 3]
						else:
							# gSPVertex(shadow_vertex, 6, 0)
							fs.draw_vertex_num = 6
							fs.draw_tris = [1, 0, 5, 0, 4, 5, 5, 4, 3, 4, 2, 3]
					else:
						# gSPVertex(shadow_vertex, 4, 0)
						fs.draw_vertex_num = 4
						fs.draw_tris = [1, 0, 3, 0, 2, 3]
					fs.draw_vtx = shadow_vertex
	# if (shadow_gobj->dl_link_next == NULL): gSPDisplayList(dFTShadowNoNextLinkDL) - render state restore.

## 0x8013BB88
static func ftShadowMakeShadow(fighter_gobj):
	var shadow_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindShadow, null, nGCCommonLinkIDShadow, GOBJ_PRIORITY_DEFAULT)
	var fp: Fighter
	var fs: FTShadow = FTShadow.new()     # syTaskmanMalloc(sizeof(FTShadow), 0x8)
	var i: int

	if fs == null:
		return null
	fp = ftGetStruct(fighter_gobj)

	fs.player = fp.player

	i = 0
	while i < (fs.vtx1.size() + fs.vtx2.size()) / 2:
		fs.vtx1[i].n.flag = 0
		fs.vtx1[i].n.n[0] = 0
		fs.vtx1[i].n.n[1] = 0
		fs.vtx1[i].n.n[2] = 0
		fs.vtx1[i].n.a = 128
		fs.vtx2[i].n.flag = 0
		fs.vtx2[i].n.n[0] = 0
		fs.vtx2[i].n.n[1] = 0
		fs.vtx2[i].n.n[2] = 0
		fs.vtx2[i].n.a = 128
		i += 1
	shadow_gobj.user_data = fs

	Objman.gcAddGObjDisplay(shadow_gobj, Callable(Ftshadow, &"ftShadowProcDisplay"), 7, GOBJ_PRIORITY_DEFAULT, ~0)

	return shadow_gobj
