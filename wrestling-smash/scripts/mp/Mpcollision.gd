## Port of src/mp/mpcollision.c: stage ("map") collision geometry queries, moving collision
## groups ("yakumono") and the ground-data initialisation (mpCollisionInitGroundData).
##
## ---------------------------------------------------------------------------------------
## DATA SOURCE / SCHEMA
## The C code reads the stage's MPGroundData from the ROM file dMPCollisionGroundFileInfos[gkind].
## This port reads the same data from the stage JSON exported by tools/ssb64/stages
## (game/data/ssb64/stages/<key>.json, schema in evidence/ssb64_stages.md). Fields consumed:
##   gr_kind_value                       -> gSCManagerBattleState->gkind of the stage
##   ground_data.*                       -> MPGroundData fields (gMPCollisionGroundData), C names
##   ground_data.gr_desc[i]              -> {dobjdesc, anim_joints, p_mobjsubs, p_matanim_joints} refs
##   geometry.yakumono_count / mapobj_count
##   geometry.vertex_data[i]  {pos:{x,y}, vertex_flags}       (MPVertexData)
##   geometry.vertex_id[k]    u16                              (MPVertexArray)
##   geometry.vertex_links[l] {vertex1, vertex2}               (MPVertexLinks)
##   geometry.line_info[n]    {yakumono_id, line_data[4]{group_id, line_count}} (MPLineInfo)
##   geometry.mapobjs[i]      {mapobj_kind, pos:{x,y}}         (MPMapObjData)
##   yakumono[i].dobjdesc {id, translate[3], rotate[3], scale[3], dl}  -> gr_desc[1].dobjdesc
##   yakumono[i].animation.streams[] {offset, events[]{raw[], target}} -> gr_desc[1].anim_joints
##
## In-memory representation (other modules use the C paths unchanged):
##   gMPCollisionGroundData   Dictionary with MPGroundData field names. Vec3f/Vec3h fields
##                            (light_angle, zoom_start, zoom_end) are Vector3, s16 bounds are int,
##                            fog_color / emblem_colors[i] are {r,g,b}, item_weights is {values:[..]}
##                            or null, map_geometry is the MPGeometryData below.
##                            gr_desc[1].dobjdesc = Array of {id, dl, translate, rotate, scale}
##                            terminated by {id: DOBJ_ARRAY_MAX}; gr_desc[1].anim_joints = Array
##                            (one entry per DObjDesc) of AnimStream (u32 AObjEvent32) or null.
##                            Other layers keep the JSON {file_id, file_name, offset} refs.
##   gMPCollisionGeometry     MPGeometryData   (.yakumono_count, .line_info[], .mapobj_count, ...)
##   gMPCollisionVertexData   MPVertexPosContainer (.vpos[i].pos (Vector2i), .vpos[i].vertex_flags)
##   gMPCollisionVertexIDs    MPVertexArray    (.vertex_id[k])
##   gMPCollisionVertexLinks  Array of MPVertexLinks (.vertex1, .vertex2)
##   gMPCollisionVertexInfo   MPVertexInfoContainer (.vertex_info[line_id].yakumono_id, ...)
##   gMPCollisionLineGroups   Array[4] of MPLineGroup (.line_count, .line_id[])
##   gMPCollisionYakumonoDObjs MPYakumonoDObj (.dobjs[yakumono_id] = DObj of layer-1 ground GObj)
##   gMPCollisionSpeeds       Array of Vector3 (per yakumono)
##   gMPCollisionBounds       MPAllBounds (.start/.stop/.current/.diff MPBounds{top,bottom,right,left})
##   yakumono DObj status     dobj.user_data.s (MPYakumonoUserData{s}); null user_data == 0 (None)
##   dobj->anim_joint.event32 != NULL  <=>  dobj.anim_data != null and dobj.anim_pos >= 0
##
## Out-parameter convention (PORTING.md): pure outputs are returned; functions with a C return
## value and pointer outputs return {"ret": ..., "<c_param>": ...}. Outputs that C writes only on
## success are additionally accepted as optional trailing in-out arguments (their current value),
## so callers can pass e.g. coll_data.floor_flags and assign the returned key back unconditionally.
##
## f32 note: C f32 arithmetic is done with GDScript floats (PORTING.md); every epsilon, comparison
## and loop order is kept. Results stored into Vector3/Vector2 get f32 storage like C. (s32) casts
## of f32 sums round to f32 first (_f32) so the truncation sees the same value as on the N64.
##
## C error traps `while (TRUE) { syDebugPrintf(...); scManagerRunPrintGObjStatus(); }` hang the
## original game; the port reports the message (push_error) once and returns a neutral value
## (invalid line id) or continues (yakumono status check).
class_name Mpcollision
extends Port

const STAGE_JSON_DIR := "res://data/ssb64/stages/"

# // // // // // // // // // // // //
#            STRUCTS
# // // // // // // // // // // // //

## MPVertexInfo (mptypes.h)
class MPVertexInfo:
	var yakumono_id: int = 0          # u8
	var line_type: int = 0            # u8
	var coll_pos_next: int = 0        # s16
	var coll_pos_prev: int = 0        # s16
	var edge_next_line_id: int = 0    # s16
	var edge_prev_line_id: int = 0    # s16

class MPVertexInfoContainer:
	var vertex_info: Array = []       # MPVertexInfo[]

## MPVertexLinks: vertex1 = first index into vertex_id[], vertex2 = vertex count
class MPVertexLinks:
	var vertex1: int = 0              # u16
	var vertex2: int = 0              # u16

class MPVertexArray:
	var vertex_id: PackedInt32Array = PackedInt32Array()   # u16[]

class MPVertexData:
	var pos: Vector2i = Vector2i.ZERO # Vec2h
	var vertex_flags: int = 0         # u16

class MPVertexPosContainer:
	var vpos: Array = []              # MPVertexData[]

class MPLineData:
	var group_id: int = 0             # u16
	var line_count: int = 0           # u16

class MPLineInfo:
	var yakumono_id: int = 0          # u16
	var line_data: Array = []         # MPLineData[4] (floor, ceil, rwall, lwall)

class MPMapObjData:
	var mapobj_kind: int = 0          # u16
	var pos: Vector2i = Vector2i.ZERO # Vec2h

class MPMapObjContainer:
	var mapobjs: Array = []           # MPMapObjData[]

class MPGeometryData:
	var yakumono_count: int = 0
	var vertex_data: MPVertexPosContainer = null
	var vertex_id: MPVertexArray = null
	var vertex_links: Array = []      # MPVertexLinks[]
	var line_info: Array = []         # MPLineInfo[]
	var mapobj_count: int = 0
	var mapobjs: MPMapObjContainer = null

class MPLineGroup:
	var line_count: int = 0
	var line_id: Array = []           # u16[] (NULL until allocated)

class MPBounds:
	var top: float = 0.0
	var bottom: float = 0.0
	var right: float = 0.0
	var left: float = 0.0
	func dup() -> MPBounds:
		var b := MPBounds.new()
		b.top = top
		b.bottom = bottom
		b.right = right
		b.left = left
		return b
	func copy_from(o: MPBounds) -> void:
		top = o.top
		bottom = o.bottom
		right = o.right
		left = o.left

class MPAllBounds:
	var start: MPBounds = MPBounds.new()    # Initial bounds of farthest moving (or active?) vertex in each direction
	var stop: MPBounds = MPBounds.new()     # Static bounds of farthest vertex in each direction
	var current: MPBounds = MPBounds.new()  # Current bounds of farthest vertex in each direction
	var diff: MPBounds = MPBounds.new()     # Difference between 'current' and 'start'

class MPYakumonoDObj:
	var dobjs: Array = []             # DObj*[] (filled by gcSetupCustomDObjs of the layer-1 ground GObj)

## GCUserData of a yakumono DObj (dobj->user_data.s = MPYakumonoStatus)
class MPYakumonoUserData:
	var s: int = 0

# // // // // // // // // // // // //
#        INITIALIZED DATA
# // // // // // // // // // // // //

## 0x8012C4E0
static var dMPCollisionMaterialFrictions: Array = [
	4.0, 3.0,
	3.0, 1.0,
	2.0, 2.0,
	4.0, 4.0,
	4.0, 4.0,
	4.0, 4.0,
	4.0, 4.0,
	4.0, 4.0
]

## 0x8012C520 - {file_id, file_name} of every GRKind map file (+ port: JSON key, "" = not exported)
static var dMPCollisionGroundFileInfos: Array = [
	{"file_id": 259, "file_name": "GRCastleMap", "key": "castle"},          # Peach's Castle
	{"file_id": 262, "file_name": "GRSectorMap", "key": "sector"},          # Sector Z
	{"file_id": 261, "file_name": "GRJungleMap", "key": "jungle"},          # Kongo Jungle
	{"file_id": 257, "file_name": "GRZebesMap", "key": "zebes"},            # Planet Zebes
	{"file_id": 265, "file_name": "GRHyruleMap", "key": "hyrule"},          # Hyrule Castle
	{"file_id": 263, "file_name": "GRYosterMap", "key": "yoster"},          # Yoshi's Island
	{"file_id": 255, "file_name": "GRPupupuMap", "key": "pupupu"},          # Dream Land
	{"file_id": 264, "file_name": "GRYamabukiMap", "key": "yamabuki"},      # Saffron City
	{"file_id": 260, "file_name": "GRInishieMap", "key": "inishie"},        # Mushroom Kingdom
	{"file_id": 256, "file_name": "GRPupupuSmallMap", "key": ""},           # Beta Dream Land
	{"file_id": 258, "file_name": "GRPupupuTestMap", "key": ""},            # Test Stage
	{"file_id": 267, "file_name": "GRExplainMap", "key": "explain"},        # How to Play
	{"file_id": 270, "file_name": "GRYosterSmallMap", "key": ""},           # Small Yoshi's Island (1P Game)
	{"file_id": 269, "file_name": "GRMetalMap", "key": "metal"},            # Meta Crystal
	{"file_id": 268, "file_name": "GRZakoMap", "key": "zako"},              # Duel Zone
	{"file_id": 295, "file_name": "GRBonus3Map", "key": ""},                # Race to the Finish
	{"file_id": 266, "file_name": "GRLastMap", "key": "last"},              # Final Destination
	{"file_id": 271, "file_name": "GRBonus1MarioMap", "key": ""},           # Break the Targets Mario
	{"file_id": 272, "file_name": "GRBonus1FoxMap", "key": ""},             # Break the Targets Fox
	{"file_id": 273, "file_name": "GRBonus1DonkeyMap", "key": ""},          # Break the Targets Donkey Kong
	{"file_id": 274, "file_name": "GRBonus1SamusMap", "key": ""},           # Break the Targets Samus
	{"file_id": 275, "file_name": "GRBonus1LuigiMap", "key": ""},           # Break the Targets Luigi
	{"file_id": 276, "file_name": "GRBonus1LinkMap", "key": ""},            # Break the Targets Link
	{"file_id": 277, "file_name": "GRBonus1YoshiMap", "key": ""},           # Break the Targets Yoshi
	{"file_id": 278, "file_name": "GRBonus1CaptainMap", "key": ""},         # Break the Targets Captain Falcon
	{"file_id": 279, "file_name": "GRBonus1KirbyMap", "key": ""},           # Break the Targets Kirby
	{"file_id": 280, "file_name": "GRBonus1PikachuMap", "key": ""},         # Break the Targets Pikachu
	{"file_id": 281, "file_name": "GRBonus1PurinMap", "key": ""},           # Break the Targets Jigglypuff
	{"file_id": 282, "file_name": "GRBonus1NessMap", "key": ""},            # Break the Targets Ness
	{"file_id": 283, "file_name": "GRBonus2MarioMap", "key": ""},           # Board the Platforms Mario
	{"file_id": 284, "file_name": "GRBonus2FoxMap", "key": ""},             # Board the Platforms Fox
	{"file_id": 285, "file_name": "GRBonus2DonkeyMap", "key": ""},          # Board the Platforms Donkey Kong
	{"file_id": 286, "file_name": "GRBonus2SamusMap", "key": ""},           # Board the Platforms Samus
	{"file_id": 287, "file_name": "GRBonus2LuigiMap", "key": ""},           # Board the Platforms Luigi
	{"file_id": 288, "file_name": "GRBonus2LinkMap", "key": ""},            # Board the Platforms Link
	{"file_id": 289, "file_name": "GRBonus2YoshiMap", "key": ""},           # Board the Platforms Yoshi
	{"file_id": 290, "file_name": "GRBonus2CaptainMap", "key": ""},         # Board the Platforms Captain Falcon
	{"file_id": 291, "file_name": "GRBonus2KirbyMap", "key": ""},           # Board the Platforms Kirby
	{"file_id": 292, "file_name": "GRBonus2PikachuMap", "key": ""},         # Board the Platforms Pikachu
	{"file_id": 293, "file_name": "GRBonus2PurinMap", "key": ""},           # Board the Platforms Jigglypuff
	{"file_id": 294, "file_name": "GRBonus2NessMap", "key": ""}             # Board the Platforms Ness
]

## 0x8012C668 - I can't for the life of me figure out if these are referenced at all
static var dMPCollisionUnusedFloats: Array = [
	5000.0, -2500.0, 7000.0, -7000.0,
	9000.0, -5000.0, 12000.0, -12000.0,
	20.0, 45.0, 1557.3, 0.0,
	2670.0, -2670.0, 4000.0, -2500.0,
	5500.0, -5500.0, 9000.0, -5000.0,
	11000.0, -11000.0, 20.0, 45.0,
	1550.4, 0.0, 2016.9, -2016.9,
	5000.0, -2500.0, 6500.0, -6500.0,
	9000.0, -5000.0, 11500.0, -11500.0,
	0.0, 90.0, 1570.5, 0.0,
	2668.8, -2782.8, 4000.0, -2500.0,
	5500.0, -5500.0, 9000.0, -5000.0,
	11000.0, -11000.0, 20.0, 45.0,
	1550.4, 0.0, 2016.9, -2016.9,
	5000.0, -2500.0, 7000.0, -7000.0,
	9000.0, -5000.0, 12000.0, -12000.0,
	20.0, 45.0, 1557.3, 0.0,
	2670.0, -2670.0, 5000.0, -2500.0,
	7000.0, -7000.0, 9000.0, -5000.0,
	12000.0, -12000.0, 20.0, 45.0,
	1557.3, 0.0, 2670.0, -2670.0,
	5000.0, -2500.0, 7000.0, -7000.0,
	9000.0, -5000.0, 12000.0, -12000.0,
	20.0, 45.0, 1557.3, 0.0,
	2670.0, -2670.0, 5000.0, -2500.0,
	7000.0, -7000.0, 9000.0, -5000.0,
	12000.0, -12000.0, 20.0, 45.0,
	1557.3, 0.0, 2670.0, -2670.0
]

# // // // // // // // // // // // //
#    GLOBAL / STATIC VARIABLES
# // // // // // // // // // // // //

## 0x80131300
static var gMPCollisionGroundData = null                      # MPGroundData (Dictionary)
## 0x80131304
static var gMPCollisionYakumonoDObjs: MPYakumonoDObj = null
## 0x80131308
static var gMPCollisionBounds: MPAllBounds = MPAllBounds.new()
## 0x80131348
static var gMPCollisionLineGroups: Array = _port_make_line_groups()   # MPLineGroup[nMPLineKindEnumCount]
## 0x80131368
static var gMPCollisionGeometry: MPGeometryData = null
## 0x8013136C
static var gMPCollisionVertexInfo: MPVertexInfoContainer = null
## 0x80131370
static var gMPCollisionVertexData: MPVertexPosContainer = null  # Vertex positions
## 0x80131374
static var gMPCollisionVertexIDs: MPVertexArray = null
## 0x80131378
static var gMPCollisionVertexLinks: Array = []                # MPVertexLinks[]
## 0x8013137C - distance each line collision moved
static var gMPCollisionSpeeds: Array = []                     # Vec3f[] (Vector3)
## 0x80131380
static var gMPCollisionMapObjs: MPMapObjContainer = null
## 0x80131384
static var gMPCollisionLinesNum: int = 0
## 0x80131388
static var gMPCollisionLightColor: Dictionary = {"r": 0, "g": 0, "b": 0, "a": 0}   # SYColorRGBA
## 0x8013138C
static var gMPCollisionYakumonosNum: int = 0
## 0x80131390
static var gMPCollisionLightAngleX: float = 0.0
## 0x80131394
static var gMPCollisionLightAngleY: float = 0.0
## 0x80131398
static var gMPCollisionUpdateTic: int = 0                     # u16
## 0x8013139C
static var gMPCollisionBGMCurrent: int = 0
## 0x801313A0
static var gMPCollisionBGMDefault: int = 0

# --- port-only state -------------------------------------------------------------------
## Stage JSON handed to load_stage_json (the "map file" mpCollisionInitGroundData reads).
static var port_stage_json: Dictionary = {}
## Layer-1 ground GObj made by load_stage_json(..., make_yakumono_layer = true).
static var port_yakumono_layer_gobj = null
static var _port_f32_buf: PackedFloat32Array = PackedFloat32Array([0.0])

static func _port_make_line_groups() -> Array:
	var groups := []
	for i in 4: # nMPLineKindEnumCount
		groups.append(MPLineGroup.new())
	return groups

# // // // // // // // // // // // //
#        PORT HELPERS
# // // // // // // // // // // // //

## Round to IEEE single precision (C f32 storage).
static func _f32(x: float) -> float:
	_port_f32_buf[0] = x
	return _port_f32_buf[0]

## C: while (TRUE) { syDebugPrintf(msg); scManagerRunPrintGObjStatus(); } (hangs the game)
static func _mpCollisionHang(msg: String) -> void:
	Debug.syDebugPrintf(msg)
	push_error("Mpcollision: " + msg.strip_edges())

## dobj->user_data.s (yakumono status). A NULL user_data reads as 0 (nMPYakumonoStatusNone).
static func _user_data_s(dobj) -> int:
	var ud = dobj.user_data
	if ud == null:
		return 0
	if ud is MPYakumonoUserData:
		return ud.s
	if ud is int:
		return ud
	if ud is Dictionary:
		return int(ud.get("s", 0))
	if (ud is Object) and ("s" in ud):
		return int(ud.s)
	return 0

## dobj->user_data.s = s
static func _set_user_data_s(dobj, s: int) -> void:
	var ud = dobj.user_data
	if ud is MPYakumonoUserData:
		ud.s = s
	elif ud is Dictionary:
		ud["s"] = s
	elif (ud is Object) and ("s" in ud):
		ud.s = s
	else:
		var new_ud := MPYakumonoUserData.new()
		new_ud.s = s
		dobj.user_data = new_ud

## dobj->anim_joint.event32 != NULL
static func _has_anim_joint(dobj) -> bool:
	return (dobj.anim_data != null) and (dobj.anim_pos >= 0)

# // // // // // // // // // // // //
#           FUNCTIONS
# // // // // // // // // // // // //

## 0x800F39F0
static func mpCollisionGetLineDistanceFC(opx: float, v1x: int, v1y: int, v2x: int, v2y: int) -> float:
	return v1y + (((opx - v1x) / float(v2x - v1x)) * (v2y - v1y))

## 0x800F3A34
static func mpCollisionGetLineDistanceLR(opy: float, v1x: int, v1y: int, v2x: int, v2y: int) -> float:
	return v1x + (((opy - v1y) / float(v2y - v1y)) * (v2x - v1x))

## 0x800F3A78
## C: sb32 mpCollisionGetFCCommon(s32 line_id, Vec3f *object_pos, f32 *dist, u32 *flags, Vec3f *angle, s32 ud)
## Returns {"ret", "dist", "flags", "angle"} (outputs are written only when ret == TRUE).
static func mpCollisionGetFCCommon(line_id: int, object_pos: Vector3, ud: int, dist = null, flags = null, angle = null) -> Dictionary:
	if dist == null:
		dist = 0.0
	if flags == null:
		flags = 0
	if angle == null:
		angle = Vector3.ZERO
	var vlinks: MPVertexLinks
	var yakumono_dobj: DObj
	var vnear: float
	var pv: int                     # u16 *pv (index into gMPCollisionVertexIDs->vertex_id)
	var v1x: int
	var v1y: int
	var v2x: int
	var v2y: int
	var vfar: float
	var object_pos_x: float
	var object_pos_y: float
	var vid: int
	var vertex1: int
	var i: int

	if (line_id == -1) or (line_id == -2): # -1 = not above ground, -2 = ???
		_mpCollisionHang("mpGetUUCommon() id = %d\n" % line_id) # Since we're exclusively checking ground collision and the line ID passed isn't ground-valid, report the error
		return {"ret": FALSE, "dist": dist, "flags": flags, "angle": angle}
	yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[gMPCollisionVertexInfo.vertex_info[line_id].yakumono_id]

	if _user_data_s(yakumono_dobj) >= nMPYakumonoStatusOff:
		_mpCollisionHang("mpGetUUCommon() no collsion\n")
	vlinks = gMPCollisionVertexLinks[line_id]

	if _has_anim_joint(yakumono_dobj) or (_user_data_s(yakumono_dobj) != nMPYakumonoStatusNone):
		object_pos_x = object_pos.x - yakumono_dobj.translate.x
		object_pos_y = object_pos.y - yakumono_dobj.translate.y
	else:
		object_pos_x = object_pos.x
		object_pos_y = object_pos.y
	vertex1 = vlinks.vertex1
	pv = vertex1
	v1x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[pv]].pos.x
	vid = vlinks.vertex2 - 1
	v2x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex1 + vid]].pos.x

	if v2x < v1x:
		vfar = v1x
		vnear = v2x
	else:
		vfar = v2x
		vnear = v1x
	if (object_pos_x <= (vnear - 0.001)) or ((vfar + 0.001) <= object_pos_x):
		return {"ret": FALSE, "dist": dist, "flags": flags, "angle": angle}
	if object_pos_x <= vnear:
		object_pos_x = vnear
	elif vfar <= object_pos_x:
		object_pos_x = vfar
	if vid != 1:
		i = 0
		while i < vid:
			v1x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[pv]].pos.x
			v2x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[pv + 1]].pos.x

			if v2x == v1x:
				_mpCollisionHang("same vtx x error mpGetUUCommon\n")
			if ((v1x <= object_pos_x) and (object_pos_x <= v2x)) or ((v2x <= object_pos_x) and (object_pos_x <= v1x)):
				break
			i += 1
			pv += 1
	v1y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[pv]].pos.y
	v2y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[pv + 1]].pos.y

	flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[pv]].vertex_flags
	dist = mpCollisionGetLineDistanceFC(object_pos_x, v1x, v1y, v2x, v2y) - object_pos_y
	angle = mpCollisionGetFCAngle(v1x, v1y, v2x, v2y, ud)

	return {"ret": TRUE, "dist": dist, "flags": flags, "angle": angle}

## 0x800F3DD8
## Returns {"ret", "dist", "flags", "angle"}; dist/flags/angle = optional in-out current values.
static func mpCollisionGetFCCommonFloor(line_id: int, object_pos: Vector3, dist = null, flags = null, angle = null) -> Dictionary:
	return mpCollisionGetFCCommon(line_id, object_pos, +1, dist, flags, angle)

## 0x800F3E04
## Returns {"ret", "dist", "flags", "angle"}
static func mpCollisionGetFCCommonCeil(line_id: int, object_pos: Vector3, dist = null, flags = null, angle = null) -> Dictionary:
	return mpCollisionGetFCCommon(line_id, object_pos, -1, dist, flags, angle)

## 0x800F3E30
## C: sb32 mpCollisionGetLRCommon(s32 line_id, Vec3f *object_pos, f32 *dist, u32 *flags, Vec3f *angle, s32 lr)
## Returns {"ret", "dist", "flags", "angle"} (outputs are written only when ret == TRUE).
static func mpCollisionGetLRCommon(line_id: int, object_pos: Vector3, lr: int, dist = null, flags = null, angle = null) -> Dictionary:
	if dist == null:
		dist = 0.0
	if flags == null:
		flags = 0
	if angle == null:
		angle = Vector3.ZERO
	var vlinks: MPVertexLinks
	var yakumono_dobj: DObj
	var vnear: float
	var vfar: float
	var v1x: int
	var v1y: int
	var v2x: int
	var v2y: int
	var object_pos_y: float
	var object_pos_x: float
	var vid: int
	var vertex1: int
	var pv: int
	var i: int

	if (line_id == -1) or (line_id == -2): # -1 = not above ground, -2 = ???
		_mpCollisionHang("mpGetLRCommon() id = %d\n" % line_id)
		return {"ret": FALSE, "dist": dist, "flags": flags, "angle": angle}
	yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[gMPCollisionVertexInfo.vertex_info[line_id].yakumono_id]

	if _user_data_s(yakumono_dobj) >= nMPYakumonoStatusOff:
		_mpCollisionHang("mpGetLRCommon() no collision\n")
	vlinks = gMPCollisionVertexLinks[line_id]

	if _has_anim_joint(yakumono_dobj) or (_user_data_s(yakumono_dobj) != nMPYakumonoStatusNone):
		object_pos_x = object_pos.x - yakumono_dobj.translate.x
		object_pos_y = object_pos.y - yakumono_dobj.translate.y
	else:
		object_pos_x = object_pos.x
		object_pos_y = object_pos.y
	vertex1 = vlinks.vertex1
	pv = vertex1
	v1y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[pv]].pos.y
	vid = vlinks.vertex2 - 1
	v2y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex1 + vid]].pos.y

	if v2y < v1y:
		vfar = v1y
		vnear = v2y
	else:
		vfar = v2y
		vnear = v1y
	if (object_pos_y <= (vnear - 0.001)) or ((vfar + 0.001) <= object_pos_y):
		return {"ret": FALSE, "dist": dist, "flags": flags, "angle": angle}
	if object_pos_y <= vnear:
		object_pos_y = vnear
	elif vfar <= object_pos_y:
		object_pos_y = vfar
	if vid != 1:
		i = 0
		while i < vid:
			v1y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[pv]].pos.y
			v2y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[pv + 1]].pos.y

			if v2y == v1y:
				_mpCollisionHang("same vtx y error mpGetLRCommon\n")
			if ((v1y <= object_pos_y) and (object_pos_y <= v2y)) or ((v2y <= object_pos_y) and (object_pos_y <= v1y)):
				break
			i += 1
			pv += 1
	v1x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[pv]].pos.x
	v2x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[pv + 1]].pos.x

	flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[pv]].vertex_flags
	dist = mpCollisionGetLineDistanceLR(object_pos_y, v1x, v1y, v2x, v2y) - object_pos_x
	angle = mpCollisionGetLRAngle(v1x, v1y, v2x, v2y, lr)

	return {"ret": TRUE, "dist": dist, "flags": flags, "angle": angle}

## 0x800F4194
## Returns {"ret", "dist", "flags", "angle"}
static func mpCollisionGetLRCommonLWall(line_id: int, object_pos: Vector3, dist = null, flags = null, angle = null) -> Dictionary:
	return mpCollisionGetLRCommon(line_id, object_pos, -1, dist, flags, angle)

## 0x800F41C0
## Returns {"ret", "dist", "flags", "angle"}
static func mpCollisionGetLRCommonRWall(line_id: int, object_pos: Vector3, dist = null, flags = null, angle = null) -> Dictionary:
	return mpCollisionGetLRCommon(line_id, object_pos, +1, dist, flags, angle)

## 0x800F41EC
## C: void mpCollisionGetLREdge(s32 line_id, Vec3f *object_pos, s32 lr) -> returns object_pos
static func mpCollisionGetLREdge(line_id: int, lr: int) -> Vector3:
	var vlinks: MPVertexLinks
	var yakumono_dobj: DObj
	var v1x: int
	var v2x: int
	var vid: int
	var vertex1: int
	var cmp_lt: bool
	var object_pos := Vector3.ZERO

	if (line_id == -1) or (line_id == -2):
		_mpCollisionHang("mpGetLREdge() id = %d\n" % line_id)
		return object_pos
	yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[gMPCollisionVertexInfo.vertex_info[line_id].yakumono_id]

	if _user_data_s(yakumono_dobj) >= nMPYakumonoStatusOff:
		_mpCollisionHang("mpGetLREdge() no collision\n")
	vlinks = gMPCollisionVertexLinks[line_id]
	vertex1 = vlinks.vertex1
	vid = (vlinks.vertex2 + vertex1) - 1
	v1x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex1]].pos.x
	v2x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vid]].pos.x

	cmp_lt = (v1x < v2x) if (lr < 0) else (v2x < v1x)

	if cmp_lt != false:
		object_pos.x = v1x
		object_pos.y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex1]].pos.y
	else:
		object_pos.x = v2x
		object_pos.y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vid]].pos.y
	object_pos.z = 0.0

	if _has_anim_joint(yakumono_dobj) or (_user_data_s(yakumono_dobj) != nMPYakumonoStatusNone):
		object_pos.x += yakumono_dobj.translate.x
		object_pos.y += yakumono_dobj.translate.y
	return object_pos

## 0x800F4408 - Get right edge of ground line ID. Returns object_pos (the argument is ignored: pure output).
static func mpCollisionGetFloorEdgeR(line_id: int, object_pos = null) -> Vector3:
	return mpCollisionGetLREdge(line_id, +1)

## 0x800F4428 - Get left edge of ground line ID. Returns object_pos.
static func mpCollisionGetFloorEdgeL(line_id: int, object_pos = null) -> Vector3:
	return mpCollisionGetLREdge(line_id, -1)

## 0x800F4448 - Get right edge of ceiling line ID (!?). Returns object_pos.
static func mpCollisionGetCeilEdgeR(line_id: int, object_pos = null) -> Vector3:
	return mpCollisionGetLREdge(line_id, +1)

## 0x800F4468 - Get left edge of ceiling line ID (!?). Returns object_pos.
static func mpCollisionGetCeilEdgeL(line_id: int, object_pos = null) -> Vector3:
	return mpCollisionGetLREdge(line_id, -1)

## 0x800F4488
## C: void mpCollisionGetUDEdge(s32 line_id, Vec3f *object_pos, s32 ud) -> returns object_pos
static func mpCollisionGetUDEdge(line_id: int, ud: int) -> Vector3:
	var vlinks: MPVertexLinks
	var yakumono_dobj: DObj
	var vpos1: MPVertexData
	var vpos2: MPVertexData
	var v1y: int
	var v2y: int
	var vid: int
	var vertex1: int
	var cmp_lt: bool
	var object_pos := Vector3.ZERO

	if (line_id == -1) or (line_id == -2):
		_mpCollisionHang("mpGetUDEdge() id = %d\n" % line_id)
		return object_pos
	yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[gMPCollisionVertexInfo.vertex_info[line_id].yakumono_id]

	if _user_data_s(yakumono_dobj) >= nMPYakumonoStatusOff:
		_mpCollisionHang("mpGetUDEdge() no collision\n")
	vlinks = gMPCollisionVertexLinks[line_id]
	vertex1 = vlinks.vertex1
	vid = (vlinks.vertex2 + vertex1) - 1
	vpos1 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex1]]
	vpos2 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vid]]

	v1y = vpos1.pos.y
	v2y = vpos2.pos.y

	cmp_lt = (v1y < v2y) if (ud < 0) else (v2y < v1y)

	if cmp_lt != false:
		object_pos.x = vpos1.pos.x
		object_pos.y = v1y
	else:
		object_pos.x = vpos2.pos.x
		object_pos.y = v2y
	object_pos.z = 0.0

	if _has_anim_joint(yakumono_dobj) or (_user_data_s(yakumono_dobj) != nMPYakumonoStatusNone):
		object_pos.x += yakumono_dobj.translate.x
		object_pos.y += yakumono_dobj.translate.y
	return object_pos

## 0x800F4650 - Get upper edge of left wall. Returns object_pos.
static func mpCollisionGetLWallEdgeU(line_id: int, object_pos = null) -> Vector3:
	return mpCollisionGetUDEdge(line_id, +1)

## 0x800F4670 - Get lower edge of left wall. Returns object_pos.
static func mpCollisionGetLWallEdgeD(line_id: int, object_pos = null) -> Vector3:
	return mpCollisionGetUDEdge(line_id, -1)

## 0x800F4690 - Get upper edge of right wall. Returns object_pos.
static func mpCollisionGetRWallEdgeU(line_id: int, object_pos = null) -> Vector3:
	return mpCollisionGetUDEdge(line_id, +1)

## 0x800F46B0 - Get lower edge of right wall. Returns object_pos.
static func mpCollisionGetRWallEdgeD(line_id: int, object_pos = null) -> Vector3:
	return mpCollisionGetUDEdge(line_id, -1)

## 0x800F46D0
## C: void mpCollisionGetFCAngle(Vec3f *angle, s32 v1x, s32 v1y, s32 v2x, s32 v2y, s32 ud) -> returns angle
static func mpCollisionGetFCAngle(v1x: int, v1y: int, v2x: int, v2y: int, ud: int) -> Vector3:
	var py: float
	var sqrt_py: float
	var dist_y: float
	var angle := Vector3.ZERO

	angle.z = 0.0

	dist_y = (v2y - v1y)

	if dist_y == 0.0:
		angle.x = 0.0
		angle.y = ud

		return angle
	py = -(dist_y / float(v2x - v1x))

	sqrt_py = 1.0 / sqrtf(SQUARE(py) + 1.0)

	if ud < 0:
		angle.x = (-py * sqrt_py)
		angle.y = -sqrt_py
	else:
		angle.x = (py * sqrt_py)
		angle.y = sqrt_py
	angle = syVectorNorm3D(angle)
	return angle

## 0x800F47AC - Also calculates angle? Runs whenever character lands directly on a line surface that isn't 0 degrees
## Returns {"ret", "dfx", "dfy"} (dfx/dfy written only when ret == TRUE).
static func mpCollisionCheckFloorSurfaceTilt(v1x: int, v1y: int, v2x: int, v2y: int, d1x: float, d1y: float, d2x: float, d2y: float, dfx: float = 0.0, dfy: float = 0.0) -> Dictionary:
	var vfary: int
	var vneary: int
	var ddist_x: float
	var ddist_y: float
	var vfarx: int
	var vnearx: int
	var vdist_y: int
	var vdist_x: int
	var temp_f12_2: float
	var vddiv: float
	var vddist_x: float
	var vddist_y: float
	var vddistdiv: float
	var vdscale: float
	var scale: float
	var var_f18: float

	vdist_y = v2y - v1y
	ddist_y = d1y - d2y

	if vdist_y < 0:
		vneary = v2y
		vfary = v1y
	else:
		vfary = v2y
		vneary = v1y
	if ddist_y > 0.0:
		if ((vfary + 0.001) < d2y) or (d1y < (vneary - 0.001)):
			return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
	elif ((vfary + 0.001) < d1y) or (d2y < (vneary - 0.001)):
		return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
	ddist_x = d1x - d2x
	vdist_x = v2x - v1x

	if vdist_x < 0:
		vnearx = v2x
		vfarx = v1x
	else:
		vfarx = v2x
		vnearx = v1x
	if ddist_x > 0.0:
		if (vfarx < d2x) or (d1x < vnearx):
			return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
	elif (vfarx < d1x) or (d2x < vnearx):
		return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
	if (d2y - (v1y + (((d2x - v1x) / float(vdist_x)) * vdist_y))) <= (-0.001):
		temp_f12_2 = v1y + (((d1x - v1x) / float(vdist_x)) * vdist_y)

		if (d1y - temp_f12_2) < 0.001:
			if ((-0.001) < (d1y - temp_f12_2)) and (d1x <= vfarx) and (vnearx <= d1x):
				dfx = d1x
				dfy = temp_f12_2

				return {"ret": TRUE, "dfx": dfx, "dfy": dfy}
		else:
			vddist_x = v1x - d1x
			vddist_y = v1y - d1y

			var_f18 = (ddist_y * vddist_x) - (ddist_x * vddist_y)
			scale = (vdist_y * ddist_x) - (vdist_x * ddist_y)

			vddiv = var_f18 / scale

			if vddiv < 0.0:
				if vddiv < -0.001:
					return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
				var_f18 = 0.0
			elif vddiv > 1.0:
				if vddiv > 1.001:
					return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
				var_f18 = scale
			vddistdiv = ((vdist_x * vddist_y) - (vdist_y * vddist_x)) / scale

			if (vddistdiv < -0.001) or (vddistdiv > 1.001):
				return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
			vdscale = 1.0 / scale

			dfx = v1x + (var_f18 * vdist_x * vdscale)
			dfy = v1y + (var_f18 * vdist_y * vdscale)

			return {"ret": TRUE, "dfx": dfx, "dfy": dfy}
	return {"ret": FALSE, "dfx": dfx, "dfy": dfy}

## 0x800F4BD8
## C: sb32 (Vec3f *position, Vec3f *translate, Vec3f *ga_last, s32 *stand_line_id, u32 *stand_coll_flags, Vec3f *angle)
## Returns {"ret", "ga_last", "stand_line_id", "stand_coll_flags", "angle"} (outputs written only when ret == TRUE).
static func mpCollisionCheckFloorLineCollisionSame(position: Vector3, translate: Vector3, ga_last = null, stand_line_id = null, stand_coll_flags = null, angle = null) -> Dictionary:
	if ga_last == null:
		ga_last = Vector3.ZERO
	if stand_line_id == null:
		stand_line_id = -1
	if stand_coll_flags == null:
		stand_coll_flags = 0
	if angle == null:
		angle = Vector3.ZERO
	var line_info: MPLineInfo
	var line_data: MPLineData
	var yakumono_dobj: DObj
	var vdist1: float
	var vdist2: float
	var vpdist_x: float
	var vpdist_y: float
	var vtdist_x: float
	var vtdist_y: float
	var line_project_pos: float
	var vedge_x: float
	var vedge_y: float
	var temp_s0: int
	var temp_s1: int
	var vpos_x: int
	var vpos_y: int
	var scrollv: float
	var spAC: float
	var r: Dictionary

	line_project_pos = F32_MAX

	for i in range(gMPCollisionGeometry.yakumono_count):
		line_info = gMPCollisionGeometry.line_info[i]
		line_data = line_info.line_data[nMPLineKindFloor]
		yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[line_info.yakumono_id]

		if (line_data.line_count != 0) and (_user_data_s(yakumono_dobj) < nMPYakumonoStatusOff):
			if _has_anim_joint(yakumono_dobj) or (_user_data_s(yakumono_dobj) != nMPYakumonoStatusNone):
				# This runs when the corner of the character's map collision diamond collides with a wall?
				vedge_x = yakumono_dobj.translate.x
				vedge_y = yakumono_dobj.translate.y

				vpdist_x = position.x - vedge_x
				vpdist_y = position.y - vedge_y

				vtdist_x = translate.x - vedge_x
				vtdist_y = translate.y - vedge_y
			else:
				vedge_y = 0.0
				vedge_x = 0.0

				vpdist_x = position.x
				vpdist_y = position.y

				vtdist_x = translate.x
				vtdist_y = translate.y
			if vpdist_y < vtdist_y:
				vdist1 = vpdist_y - 0.001
				vdist2 = vtdist_y + 0.001
			else:
				vdist1 = vtdist_y - 0.001
				vdist2 = vpdist_y + 0.001
			for line_id in range(line_data.group_id, line_data.group_id + line_data.line_count):
				if gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_prev > vdist2:
					continue
				elif gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_next < vdist1:
					break # goto l_break; // Bruhhhhhhhhhhhhhhh
				else:
					var vlinks: MPVertexLinks = gMPCollisionVertexLinks[line_id]
					var vertex_id: int = vlinks.vertex1

					vpos_x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].pos.x
					vpos_y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].pos.y

					for vid in range(vlinks.vertex1, (vlinks.vertex1 + vlinks.vertex2) - 1):
						vertex_id = vid
						temp_s1 = vpos_x
						temp_s0 = vpos_y

						vpos_x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id + 1]].pos.x
						vpos_y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id + 1]].pos.y

						if temp_s0 == vpos_y:
							if vtdist_y < vpdist_y:
								r = mpCollisionCheckFCSurfaceFlat(temp_s1, temp_s0, vpos_x, vpdist_x, vpdist_y, vtdist_x, vtdist_y)

								if r.ret == TRUE:
									scrollv = r.arg7
									spAC = r.arg8

									if line_project_pos <= (-(spAC - vpdist_y) if (spAC < vpdist_y) else (spAC - vpdist_y)):
										continue

									ga_last.x = scrollv + vedge_x
									ga_last.y = spAC + vedge_y
									ga_last.z = 0.0

									stand_line_id = line_id

									angle.z = 0.0
									angle.x = 0.0
									angle.y = 1.0

									stand_coll_flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].vertex_flags

									line_project_pos = -(spAC - vpdist_y) if (spAC < vpdist_y) else (spAC - vpdist_y)
						else:
							r = mpCollisionCheckFloorSurfaceTilt(temp_s1, temp_s0, vpos_x, vpos_y, vpdist_x, vpdist_y, vtdist_x, vtdist_y)

							if r.ret == TRUE:
								scrollv = r.dfx
								spAC = r.dfy

								if line_project_pos <= (-(spAC - vpdist_y) if (spAC < vpdist_y) else (spAC - vpdist_y)):
									continue

								ga_last.x = scrollv + vedge_x
								ga_last.y = spAC + vedge_y
								ga_last.z = 0.0

								stand_line_id = line_id

								angle = mpCollisionGetFCAngle(temp_s1, temp_s0, vpos_x, vpos_y, +1)

								stand_coll_flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].vertex_flags

								line_project_pos = -(spAC - vpdist_y) if (spAC < vpdist_y) else (spAC - vpdist_y)
			# l_break: continue; // BRUHHHHHHHHHHHHHHHHH
	if line_project_pos == F32_MAX:
		return {"ret": FALSE, "ga_last": ga_last, "stand_line_id": stand_line_id, "stand_coll_flags": stand_coll_flags, "angle": angle}
	return {"ret": TRUE, "ga_last": ga_last, "stand_line_id": stand_line_id, "stand_coll_flags": stand_coll_flags, "angle": angle}

## 0x800F521C
## Returns {"ret", "ga_last", "stand_line_id", "stand_coll_flags", "angle"}
static func mpCollisionCheckFloorLineCollisionDiff(position: Vector3, translate: Vector3, ga_last = null, stand_line_id = null, stand_coll_flags = null, angle = null) -> Dictionary:
	if ga_last == null:
		ga_last = Vector3.ZERO
	if stand_line_id == null:
		stand_line_id = -1
	if stand_coll_flags == null:
		stand_coll_flags = 0
	if angle == null:
		angle = Vector3.ZERO
	var line_info: MPLineInfo
	var line_data: MPLineData
	var yakumono_dobj: DObj
	var vdist1: float
	var vdist2: float
	var vpdist_x: float
	var vpdist_y: float
	var vtdist_x: float
	var vtdist_y: float
	var line_project_pos: float
	var vedge_y: float
	var dynamic_y: float
	var vedge_x: float
	var temp_s0: int
	var temp_s1: int
	var vpos_x: int
	var vpos_y: int
	var scrollv: float
	var spAC: float
	var r: Dictionary

	line_project_pos = F32_MAX

	for i in range(gMPCollisionGeometry.yakumono_count):
		line_info = gMPCollisionGeometry.line_info[i]
		line_data = line_info.line_data[nMPLineKindFloor]
		yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[line_info.yakumono_id]

		if (line_data.line_count != 0) and (_user_data_s(yakumono_dobj) < nMPYakumonoStatusOff):
			if _has_anim_joint(yakumono_dobj) or (_user_data_s(yakumono_dobj) != nMPYakumonoStatusNone):
				# This runs when the corner of the character's map collision diamond collides with a wall?
				vedge_x = yakumono_dobj.translate.x
				vedge_y = yakumono_dobj.translate.y

				dynamic_y = gMPCollisionSpeeds[line_info.yakumono_id].y

				vpdist_x = (position.x - vedge_x) + gMPCollisionSpeeds[line_info.yakumono_id].x
				vpdist_y = (position.y - vedge_y) + dynamic_y

				vtdist_x = translate.x - vedge_x
				vtdist_y = translate.y - vedge_y
			else:
				dynamic_y = 0.0
				vedge_y = 0.0
				vedge_x = 0.0

				vpdist_x = position.x
				vpdist_y = position.y

				vtdist_x = translate.x
				vtdist_y = translate.y
			if vpdist_y < vtdist_y:
				vdist1 = vpdist_y - 0.001
				vdist2 = vtdist_y + 0.001
			else:
				vdist1 = vtdist_y - 0.001
				vdist2 = vpdist_y + 0.001
			for line_id in range(line_data.group_id, line_data.group_id + line_data.line_count):
				if gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_prev > vdist2:
					continue
				if gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_next < vdist1:
					break # goto l_break; // Bruhhhhhhhhhhhhhhh
				else:
					var vlinks: MPVertexLinks = gMPCollisionVertexLinks[line_id]
					var vertex_id: int = vlinks.vertex1

					vpos_x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].pos.x
					vpos_y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].pos.y

					for vid in range(vlinks.vertex1, (vlinks.vertex1 + vlinks.vertex2) - 1):
						vertex_id = vid
						temp_s1 = vpos_x
						temp_s0 = vpos_y

						vpos_x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id + 1]].pos.x
						vpos_y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id + 1]].pos.y

						if temp_s0 == vpos_y:
							if vtdist_y < vpdist_y:
								r = mpCollisionCheckFCSurfaceFlat(temp_s1, temp_s0, vpos_x, vpdist_x, vpdist_y, vtdist_x, vtdist_y)

								if r.ret == TRUE:
									scrollv = r.arg7
									spAC = r.arg8

									if line_project_pos <= (-(spAC - (vpdist_y - dynamic_y)) if (spAC < (vpdist_y - dynamic_y)) else (spAC - (vpdist_y - dynamic_y))):
										continue

									ga_last.x = scrollv + vedge_x
									ga_last.y = spAC + vedge_y
									ga_last.z = 0.0

									stand_line_id = line_id

									angle.z = 0.0
									angle.x = 0.0
									angle.y = 1.0

									stand_coll_flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].vertex_flags

									line_project_pos = -(spAC - (vpdist_y - dynamic_y)) if (spAC < (vpdist_y - dynamic_y)) else (spAC - (vpdist_y - dynamic_y))
						else:
							r = mpCollisionCheckFloorSurfaceTilt(temp_s1, temp_s0, vpos_x, vpos_y, vpdist_x, vpdist_y, vtdist_x, vtdist_y)

							if r.ret == TRUE:
								scrollv = r.dfx
								spAC = r.dfy

								if line_project_pos <= (-(spAC - (vpdist_y - dynamic_y)) if (spAC < (vpdist_y - dynamic_y)) else (spAC - (vpdist_y - dynamic_y))):
									continue

								ga_last.x = scrollv + vedge_x
								ga_last.y = spAC + vedge_y
								ga_last.z = 0.0

								stand_line_id = line_id

								angle = mpCollisionGetFCAngle(temp_s1, temp_s0, vpos_x, vpos_y, +1)

								stand_coll_flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].vertex_flags

								line_project_pos = -(spAC - (vpdist_y - dynamic_y)) if (spAC < (vpdist_y - dynamic_y)) else (spAC - (vpdist_y - dynamic_y))
			# l_break: continue; // BRUHHHHHHHHHHHHHHHHH
	if line_project_pos == F32_MAX:
		return {"ret": FALSE, "ga_last": ga_last, "stand_line_id": stand_line_id, "stand_coll_flags": stand_coll_flags, "angle": angle}
	return {"ret": TRUE, "ga_last": ga_last, "stand_line_id": stand_line_id, "stand_coll_flags": stand_coll_flags, "angle": angle}

## 0x800F58A0
## C: sb32 (s32 v1x, s32 v1y, s32 vpos_y, f32 vpdist_x, f32 vpdist_y, f32 vtdist_x, f32 vtdist_y, f32 *arg7, f32 *arg8)
## Returns {"ret", "arg7", "arg8"} (written only when ret == TRUE).
static func mpCollisionCheckFCSurfaceFlat(v1x: int, v1y: int, vpos_y: int, vpdist_x: float, vpdist_y: float, vtdist_x: float, vtdist_y: float, arg7: float = 0.0, arg8: float = 0.0) -> Dictionary:
	var temp_f18: float
	var vnear: int
	var vfar: int
	var ddist_x: float
	var vdist_y: int = vpos_y - v1x
	var ddist_y: float = vpdist_y - vtdist_y
	var vddist_y: float = v1y - vpdist_y

	if ddist_y > 0.0:
		if ((v1y - 0.001) > vpdist_y) or (vtdist_y >= v1y):
			return {"ret": FALSE, "arg7": arg7, "arg8": arg8}
	elif ((v1y + 0.001) < vpdist_y) or (vtdist_y <= v1y):
		return {"ret": FALSE, "arg7": arg7, "arg8": arg8}
	ddist_x = vpdist_x - vtdist_x

	if vdist_y < 0:
		vnear = vpos_y
		vfar = v1x
	else:
		vfar = vpos_y
		vnear = v1x

	if ddist_x > 0.0:
		if (vfar < vtdist_x) or (vpdist_x < vnear):
			return {"ret": FALSE, "arg7": arg7, "arg8": arg8}
	elif (vfar < vpdist_x) or (vtdist_x < vnear):
		return {"ret": FALSE, "arg7": arg7, "arg8": arg8}
	temp_f18 = ((vddist_y / ddist_y) * ddist_x) + vpdist_x

	if (temp_f18 < vnear) or (temp_f18 > vfar):
		return {"ret": FALSE, "arg7": arg7, "arg8": arg8}

	arg7 = temp_f18
	arg8 = v1y

	return {"ret": TRUE, "arg7": arg7, "arg8": arg8}

## 0x800F5A64
## Returns {"ret", "dfx", "dfy"} (written only when ret == TRUE).
static func mpCollisionCheckCeilSurfaceTilt(v1x: int, v1y: int, v2x: int, v2y: int, d1x: float, d1y: float, d2x: float, d2y: float, dfx: float = 0.0, dfy: float = 0.0) -> Dictionary:
	var vfary: int
	var vneary: int
	var ddist_x: float
	var ddist_y: float
	var vfarx: int
	var vnearx: int
	var vdist_y: int
	var vdist_x: int
	var temp_f12_2: float
	var vddiv: float
	var vddist_x: float
	var vddist_y: float
	var vddistdiv: float
	var vdscale: float
	var scale: float
	var var_f18: float

	vdist_y = v2y - v1y
	ddist_y = d1y - d2y

	if vdist_y < 0:
		vneary = v2y
		vfary = v1y
	else:
		vfary = v2y
		vneary = v1y
	if ddist_y > 0.0:
		if ((vfary + 0.001) < d2y) or (d1y < (vneary - 0.001)):
			return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
	elif ((vfary + 0.001) < d1y) or (d2y < (vneary - 0.001)):
		return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
	ddist_x = d1x - d2x
	vdist_x = v2x - v1x

	if vdist_x < 0:
		vnearx = v2x
		vfarx = v1x
	else:
		vfarx = v2x
		vnearx = v1x
	if ddist_x > 0.0:
		if (vfarx < d2x) or (d1x < vnearx):
			return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
	elif (vfarx < d1x) or (d2x < vnearx):
		return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
	if (d2y - (v1y + (((d2x - v1x) / float(vdist_x)) * vdist_y))) >= 0.001:
		temp_f12_2 = v1y + (((d1x - v1x) / float(vdist_x)) * vdist_y)

		if (d1y - temp_f12_2) > -0.001:
			if ((d1y - temp_f12_2) < 0.001) and (d1x <= vfarx) and (vnearx <= d1x):
				dfx = d1x
				dfy = temp_f12_2

				return {"ret": TRUE, "dfx": dfx, "dfy": dfy}
		else:
			vddist_x = v1x - d1x
			vddist_y = v1y - d1y

			var_f18 = (ddist_y * vddist_x) - (ddist_x * vddist_y)
			scale = (vdist_y * ddist_x) - (vdist_x * ddist_y)
			vddiv = var_f18 / scale

			if vddiv < 0.0:
				if vddiv < -0.001:
					return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
				var_f18 = 0.0
			elif vddiv > 1.0:
				if vddiv > 1.001:
					return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
				var_f18 = scale
			vddistdiv = ((vdist_x * vddist_y) - (vdist_y * vddist_x)) / scale

			if (vddistdiv < -0.001) or (vddistdiv > 1.001):
				return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
			vdscale = 1.0 / scale

			dfx = v1x + (var_f18 * vdist_x * vdscale)
			dfy = v1y + (var_f18 * vdist_y * vdscale)

			return {"ret": TRUE, "dfx": dfx, "dfy": dfy}
	return {"ret": FALSE, "dfx": dfx, "dfy": dfy}

## 0x800F5E90
## Returns {"ret", "ga_last", "stand_line_id", "stand_coll_flags", "angle"}
static func mpCollisionCheckCeilLineCollisionSame(position: Vector3, translate: Vector3, ga_last = null, stand_line_id = null, stand_coll_flags = null, angle = null) -> Dictionary:
	if ga_last == null:
		ga_last = Vector3.ZERO
	if stand_line_id == null:
		stand_line_id = -1
	if stand_coll_flags == null:
		stand_coll_flags = 0
	if angle == null:
		angle = Vector3.ZERO
	var line_info: MPLineInfo
	var line_data: MPLineData
	var yakumono_dobj: DObj
	var vdist1: float
	var vdist2: float
	var vpdist_x: float
	var vpdist_y: float
	var vtdist_x: float
	var vtdist_y: float
	var line_project_pos: float
	var vedge_x: float
	var vedge_y: float
	var temp_s0: int
	var temp_s1: int
	var vpos_x: int
	var vpos_y: int
	var scrollv: float
	var spAC: float
	var r: Dictionary

	line_project_pos = F32_MAX

	for i in range(gMPCollisionGeometry.yakumono_count):
		line_info = gMPCollisionGeometry.line_info[i]
		line_data = line_info.line_data[nMPLineKindCeil]
		yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[line_info.yakumono_id]

		if (line_data.line_count != 0) and (_user_data_s(yakumono_dobj) < nMPYakumonoStatusOff):
			if _has_anim_joint(yakumono_dobj) or (_user_data_s(yakumono_dobj) != nMPYakumonoStatusNone):
				# This runs when the corner of the character's map collision diamond collides with a wall?
				vedge_x = yakumono_dobj.translate.x
				vedge_y = yakumono_dobj.translate.y

				vpdist_x = position.x - vedge_x
				vpdist_y = position.y - vedge_y

				vtdist_x = translate.x - vedge_x
				vtdist_y = translate.y - vedge_y
			else:
				vedge_y = 0.0
				vedge_x = 0.0

				vpdist_x = position.x
				vpdist_y = position.y

				vtdist_x = translate.x
				vtdist_y = translate.y
			if vpdist_y < vtdist_y:
				vdist1 = vpdist_y - 0.001
				vdist2 = vtdist_y + 0.001
			else:
				vdist1 = vtdist_y - 0.001
				vdist2 = vpdist_y + 0.001
			for line_id in range(line_data.group_id, line_data.group_id + line_data.line_count):
				if gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_next < vdist1:
					continue
				elif gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_prev > vdist2:
					break # goto l_break; // Bruhhhhhhhhhhhhhhh
				else:
					var vlinks: MPVertexLinks = gMPCollisionVertexLinks[line_id]
					var vertex_id: int = vlinks.vertex1

					vpos_x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].pos.x
					vpos_y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].pos.y

					for vid in range(vlinks.vertex1, (vlinks.vertex1 + vlinks.vertex2) - 1):
						vertex_id = vid
						temp_s1 = vpos_x
						temp_s0 = vpos_y

						vpos_x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id + 1]].pos.x
						vpos_y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id + 1]].pos.y

						if temp_s0 == vpos_y:
							if vtdist_y > vpdist_y:
								r = mpCollisionCheckFCSurfaceFlat(temp_s1, temp_s0, vpos_x, vpdist_x, vpdist_y, vtdist_x, vtdist_y)

								if r.ret == TRUE:
									scrollv = r.arg7
									spAC = r.arg8

									if line_project_pos <= (-(spAC - vpdist_y) if (spAC < vpdist_y) else (spAC - vpdist_y)):
										continue

									ga_last.x = scrollv + vedge_x
									ga_last.y = spAC + vedge_y
									ga_last.z = 0.0

									stand_line_id = line_id

									angle.z = 0.0
									angle.x = 0.0
									angle.y = -1.0

									stand_coll_flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].vertex_flags

									line_project_pos = -(spAC - vpdist_y) if (spAC < vpdist_y) else (spAC - vpdist_y)
						else:
							r = mpCollisionCheckCeilSurfaceTilt(temp_s1, temp_s0, vpos_x, vpos_y, vpdist_x, vpdist_y, vtdist_x, vtdist_y)

							if r.ret == TRUE:
								scrollv = r.dfx
								spAC = r.dfy

								if line_project_pos <= (-(spAC - vpdist_y) if (spAC < vpdist_y) else (spAC - vpdist_y)):
									continue

								ga_last.x = scrollv + vedge_x
								ga_last.y = spAC + vedge_y
								ga_last.z = 0.0

								stand_line_id = line_id

								angle = mpCollisionGetFCAngle(temp_s1, temp_s0, vpos_x, vpos_y, -1)

								stand_coll_flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].vertex_flags

								line_project_pos = -(spAC - vpdist_y) if (spAC < vpdist_y) else (spAC - vpdist_y)
			# l_break: continue; // BRUHHHHHHHHHHHHHHHHH
	if line_project_pos == F32_MAX:
		return {"ret": FALSE, "ga_last": ga_last, "stand_line_id": stand_line_id, "stand_coll_flags": stand_coll_flags, "angle": angle}
	return {"ret": TRUE, "ga_last": ga_last, "stand_line_id": stand_line_id, "stand_coll_flags": stand_coll_flags, "angle": angle}

## 0x800F64D4
## Returns {"ret", "ga_last", "stand_line_id", "stand_coll_flags", "angle"}
static func mpCollisionCheckCeilLineCollisionDiff(position: Vector3, translate: Vector3, ga_last = null, stand_line_id = null, stand_coll_flags = null, angle = null) -> Dictionary:
	if ga_last == null:
		ga_last = Vector3.ZERO
	if stand_line_id == null:
		stand_line_id = -1
	if stand_coll_flags == null:
		stand_coll_flags = 0
	if angle == null:
		angle = Vector3.ZERO
	var line_info: MPLineInfo
	var line_data: MPLineData
	var yakumono_dobj: DObj
	var vdist1: float
	var vdist2: float
	var vpdist_x: float
	var vpdist_y: float
	var vtdist_x: float
	var vtdist_y: float
	var line_project_pos: float
	var vedge_y: float
	var dynamic_y: float
	var vedge_x: float
	var temp_s0: int
	var temp_s1: int
	var vpos_x: int
	var vpos_y: int
	var scrollv: float
	var spAC: float
	var r: Dictionary

	line_project_pos = F32_MAX

	for i in range(gMPCollisionGeometry.yakumono_count):
		line_info = gMPCollisionGeometry.line_info[i]
		line_data = line_info.line_data[nMPLineKindCeil]
		yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[line_info.yakumono_id]

		if (line_data.line_count != 0) and (_user_data_s(yakumono_dobj) < nMPYakumonoStatusOff):
			if _has_anim_joint(yakumono_dobj) or (_user_data_s(yakumono_dobj) != nMPYakumonoStatusNone):
				# This runs when the corner of the character's map collision diamond collides with a wall?
				vedge_x = yakumono_dobj.translate.x
				vedge_y = yakumono_dobj.translate.y

				dynamic_y = gMPCollisionSpeeds[line_info.yakumono_id].y

				vpdist_x = (position.x - vedge_x) + gMPCollisionSpeeds[line_info.yakumono_id].x
				vpdist_y = (position.y - vedge_y) + dynamic_y

				vtdist_x = translate.x - vedge_x
				vtdist_y = translate.y - vedge_y
			else:
				dynamic_y = 0.0
				vedge_y = 0.0
				vedge_x = 0.0

				vpdist_x = position.x
				vpdist_y = position.y

				vtdist_x = translate.x
				vtdist_y = translate.y
			if vpdist_y < vtdist_y:
				vdist1 = vpdist_y - 0.001
				vdist2 = vtdist_y + 0.001
			else:
				vdist1 = vtdist_y - 0.001
				vdist2 = vpdist_y + 0.001
			for line_id in range(line_data.group_id, line_data.group_id + line_data.line_count):
				if gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_next < vdist1:
					continue
				if gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_prev > vdist2:
					break # goto l_break; // Bruhhhhhhhhhhhhhhh
				else:
					var vlinks: MPVertexLinks = gMPCollisionVertexLinks[line_id]
					var vertex_id: int = vlinks.vertex1

					vpos_x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].pos.x
					vpos_y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].pos.y

					for vid in range(vlinks.vertex1, (vlinks.vertex1 + vlinks.vertex2) - 1):
						vertex_id = vid
						temp_s1 = vpos_x
						temp_s0 = vpos_y

						vpos_x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id + 1]].pos.x
						vpos_y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id + 1]].pos.y

						if temp_s0 == vpos_y:
							if vtdist_y > vpdist_y:
								r = mpCollisionCheckFCSurfaceFlat(temp_s1, temp_s0, vpos_x, vpdist_x, vpdist_y, vtdist_x, vtdist_y)

								if r.ret == TRUE:
									scrollv = r.arg7
									spAC = r.arg8

									if line_project_pos <= (-(spAC - (vpdist_y - dynamic_y)) if (spAC < (vpdist_y - dynamic_y)) else (spAC - (vpdist_y - dynamic_y))):
										continue

									ga_last.x = scrollv + vedge_x
									ga_last.y = spAC + vedge_y
									ga_last.z = 0.0

									stand_line_id = line_id

									angle.z = 0.0
									angle.x = 0.0
									angle.y = -1.0

									stand_coll_flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].vertex_flags

									line_project_pos = -(spAC - (vpdist_y - dynamic_y)) if (spAC < (vpdist_y - dynamic_y)) else (spAC - (vpdist_y - dynamic_y))
						else:
							r = mpCollisionCheckCeilSurfaceTilt(temp_s1, temp_s0, vpos_x, vpos_y, vpdist_x, vpdist_y, vtdist_x, vtdist_y)

							if r.ret == TRUE:
								scrollv = r.dfx
								spAC = r.dfy

								if line_project_pos <= (-(spAC - (vpdist_y - dynamic_y)) if (spAC < (vpdist_y - dynamic_y)) else (spAC - (vpdist_y - dynamic_y))):
									continue

								ga_last.x = scrollv + vedge_x
								ga_last.y = spAC + vedge_y
								ga_last.z = 0.0

								stand_line_id = line_id

								angle = mpCollisionGetFCAngle(temp_s1, temp_s0, vpos_x, vpos_y, -1)

								stand_coll_flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].vertex_flags

								line_project_pos = -(spAC - (vpdist_y - dynamic_y)) if (spAC < (vpdist_y - dynamic_y)) else (spAC - (vpdist_y - dynamic_y))
			# l_break: continue; // BRUHHHHHHHHHHHHHHHHH
	if line_project_pos == F32_MAX:
		return {"ret": FALSE, "ga_last": ga_last, "stand_line_id": stand_line_id, "stand_coll_flags": stand_coll_flags, "angle": angle}
	return {"ret": TRUE, "ga_last": ga_last, "stand_line_id": stand_line_id, "stand_coll_flags": stand_coll_flags, "angle": angle}

## 0x800F6B58
## Returns {"ret", "ga_last", "stand_line_id", "stand_coll_flags", "angle"}
static func mpCollisionCheckRWallLineCollisionSame(position: Vector3, translate: Vector3, ga_last = null, stand_line_id = null, stand_coll_flags = null, angle = null) -> Dictionary:
	if ga_last == null:
		ga_last = Vector3.ZERO
	if stand_line_id == null:
		stand_line_id = -1
	if stand_coll_flags == null:
		stand_coll_flags = 0
	if angle == null:
		angle = Vector3.ZERO
	var line_info: MPLineInfo
	var line_data: MPLineData
	var yakumono_dobj: DObj
	var vdist1: float
	var vdist2: float
	var vpdist_x: float
	var vpdist_y: float
	var vtdist_x: float
	var vtdist_y: float
	var line_project_pos: float
	var vedge_x: float
	var vedge_y: float
	var temp_s0: int
	var temp_s1: int
	var vpos_x: int
	var vpos_y: int
	var scrollv: float
	var spAC: float
	var r: Dictionary

	line_project_pos = F32_MAX

	for i in range(gMPCollisionGeometry.yakumono_count):
		line_info = gMPCollisionGeometry.line_info[i]
		line_data = line_info.line_data[nMPLineKindRWall]
		yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[line_info.yakumono_id]

		if (line_data.line_count != 0) and (_user_data_s(yakumono_dobj) < nMPYakumonoStatusOff):
			if _has_anim_joint(yakumono_dobj) or (_user_data_s(yakumono_dobj) != nMPYakumonoStatusNone):
				# This runs when the corner of the character's map collision diamond collides with a wall?
				vedge_y = yakumono_dobj.translate.x
				vedge_x = yakumono_dobj.translate.y

				vpdist_x = position.x - vedge_y
				vpdist_y = position.y - vedge_x

				vtdist_x = translate.x - vedge_y
				vtdist_y = translate.y - vedge_x
			else:
				vedge_x = 0.0
				vedge_y = 0.0

				vpdist_x = position.x
				vpdist_y = position.y

				vtdist_x = translate.x
				vtdist_y = translate.y
			if vpdist_x < vtdist_x:
				vdist1 = vpdist_x - 0.001
				vdist2 = vtdist_x + 0.001
			else:
				vdist1 = vtdist_x - 0.001
				vdist2 = vpdist_x + 0.001
			for line_id in range(line_data.group_id, line_data.group_id + line_data.line_count):
				if gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_prev > vdist2:
					continue
				elif gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_next < vdist1:
					break # goto l_break; // Bruhhhhhhhhhhhhhhh
				else:
					var vlinks: MPVertexLinks = gMPCollisionVertexLinks[line_id]
					var vertex_id: int = vlinks.vertex1

					vpos_x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].pos.x
					vpos_y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].pos.y

					for vid in range(vlinks.vertex1, (vlinks.vertex1 + vlinks.vertex2) - 1):
						vertex_id = vid
						temp_s0 = vpos_x
						temp_s1 = vpos_y

						vpos_x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id + 1]].pos.x
						vpos_y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id + 1]].pos.y

						if temp_s0 == vpos_x:
							if vtdist_x < vpdist_x:
								r = mpCollisionCheckLRSurfaceFlat(temp_s0, temp_s1, vpos_y, vpdist_x, vpdist_y, vtdist_x, vtdist_y)

								if r.ret == TRUE:
									scrollv = r.arg7
									spAC = r.arg8

									if line_project_pos <= (-(scrollv - vpdist_x) if (scrollv < vpdist_x) else (scrollv - vpdist_x)):
										continue

									ga_last.x = scrollv + vedge_y
									ga_last.y = spAC + vedge_x
									ga_last.z = 0.0

									stand_line_id = line_id

									angle.z = 0.0
									angle.y = 0.0
									angle.x = 1.0

									stand_coll_flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].vertex_flags

									line_project_pos = -(scrollv - vpdist_x) if (scrollv < vpdist_x) else (scrollv - vpdist_x)
						else:
							r = mpCollisionCheckRWallSurfaceTilt(temp_s0, temp_s1, vpos_x, vpos_y, vpdist_x, vpdist_y, vtdist_x, vtdist_y)

							if r.ret == TRUE:
								scrollv = r.dfx
								spAC = r.dfy

								if line_project_pos <= (-(scrollv - vpdist_x) if (scrollv < vpdist_x) else (scrollv - vpdist_x)):
									continue

								ga_last.x = scrollv + vedge_y
								ga_last.y = spAC + vedge_x
								ga_last.z = 0.0

								stand_line_id = line_id

								angle = mpCollisionGetLRAngle(temp_s0, temp_s1, vpos_x, vpos_y, +1)

								stand_coll_flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].vertex_flags

								line_project_pos = -(scrollv - vpdist_x) if (scrollv < vpdist_x) else (scrollv - vpdist_x)
			# l_break: continue; // BRUHHHHHHHHHHHHHHHHH
	if line_project_pos == F32_MAX:
		return {"ret": FALSE, "ga_last": ga_last, "stand_line_id": stand_line_id, "stand_coll_flags": stand_coll_flags, "angle": angle}
	return {"ret": TRUE, "ga_last": ga_last, "stand_line_id": stand_line_id, "stand_coll_flags": stand_coll_flags, "angle": angle}

## 0x800F71A0
## C: void mpCollisionGetLRAngle(Vec3f *angle, s32 v1x, s32 v1y, s32 v2x, s32 v2y, s32 lr) -> returns angle
static func mpCollisionGetLRAngle(v1x: int, v1y: int, v2x: int, v2y: int, lr: int) -> Vector3:
	var py: float
	var sqrt_py: float
	var dist_x: float
	var angle := Vector3.ZERO

	angle.z = 0.0

	dist_x = (v2x - v1x)

	if dist_x == 0.0:
		angle.x = lr
		angle.y = 0.0

		return angle
	py = -(dist_x / float(v2y - v1y))

	sqrt_py = 1.0 / sqrtf(SQUARE(py) + 1.0)

	if lr < 0:
		# -sqrt_py
		angle.x = -sqrt_py
		angle.y = (-py * sqrt_py)
	else:
		angle.x = sqrt_py
		angle.y = (py * sqrt_py)
	angle = syVectorNorm3D(angle)
	return angle

## 0x800F7270
## Returns {"ret", "dfx", "dfy"} (written only when ret == TRUE).
static func mpCollisionCheckRWallSurfaceTilt(v1x: int, v1y: int, v2x: int, v2y: int, d1x: float, d1y: float, d2x: float, d2y: float, dfx: float = 0.0, dfy: float = 0.0) -> Dictionary:
	var vfarx: int
	var vnearx: int
	var ddist_x: float
	var ddist_y: float
	var vfary: int
	var vneary: int
	var vdist_x: int
	var vdist_y: int
	var temp_f12_2: float
	var vddiv: float
	var vddist_x: float
	var vddist_y: float
	var vddistdiv: float
	var vdscale: float
	var scale: float
	var var_f18: float

	vdist_x = v2x - v1x
	ddist_x = d1x - d2x

	if vdist_x < 0:
		vnearx = v2x
		vfarx = v1x
	else:
		vfarx = v2x
		vnearx = v1x
	if ddist_x > 0.0:
		if ((vfarx + 0.001) < d2x) or (d1x < (vnearx - 0.001)):
			return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
	elif ((vfarx + 0.001) < d1x) or (d2x < (vnearx - 0.001)):
		return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
	ddist_y = d1y - d2y
	vdist_y = v2y - v1y

	if vdist_y < 0:
		vneary = v2y
		vfary = v1y
	else:
		vfary = v2y
		vneary = v1y
	if ddist_y > 0.0:
		if (vfary < d2y) or (d1y < vneary):
			return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
	elif (vfary < d1y) or (d2y < vneary):
		return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
	if (d2x - (v1x + (((d2y - v1y) / float(v2y - v1y)) * vdist_x))) <= (-0.001):
		temp_f12_2 = v1x + (((d1y - v1y) / float(vdist_y)) * vdist_x)

		if (d1x - temp_f12_2) < 0.001:
			if (((-0.001) < (d1x - temp_f12_2)) and (d1y <= vfary)) and (vneary <= d1y):
				dfx = temp_f12_2
				dfy = d1y

				return {"ret": TRUE, "dfx": dfx, "dfy": dfy}
		else:
			vddist_x = v1x - d1x
			vddist_y = v1y - d1y

			var_f18 = (ddist_y * vddist_x) - (ddist_x * vddist_y)
			scale = (vdist_y * ddist_x) - (vdist_x * ddist_y)

			vddiv = var_f18 / scale

			if vddiv < 0.0:
				if vddiv < -0.001:
					return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
				var_f18 = 0.0
			elif vddiv > 1.0:
				if vddiv > 1.001:
					return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
				var_f18 = scale
			vddistdiv = ((vdist_x * vddist_y) - (vdist_y * vddist_x)) / scale

			if (vddistdiv < -0.001) or (vddistdiv > 1.001):
				return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
			vdscale = 1.0 / scale

			dfx = v1x + ((var_f18 * vdist_x) * vdscale)
			dfy = v1y + ((var_f18 * vdist_y) * vdscale)

			return {"ret": TRUE, "dfx": dfx, "dfy": dfy}
	return {"ret": FALSE, "dfx": dfx, "dfy": dfy}

## 0x800F769C
## Returns {"ret", "ga_last", "stand_line_id", "stand_coll_flags", "angle"}
static func mpCollisionCheckRWallLineCollisionDiff(position: Vector3, translate: Vector3, ga_last = null, stand_line_id = null, stand_coll_flags = null, angle = null) -> Dictionary:
	if ga_last == null:
		ga_last = Vector3.ZERO
	if stand_line_id == null:
		stand_line_id = -1
	if stand_coll_flags == null:
		stand_coll_flags = 0
	if angle == null:
		angle = Vector3.ZERO
	var line_info: MPLineInfo
	var line_data: MPLineData
	var yakumono_dobj: DObj
	var vdist1: float
	var vdist2: float
	var vpdist_x: float
	var vpdist_y: float
	var vtdist_x: float
	var vtdist_y: float
	var line_project_pos: float
	var vedge_x: float
	var dynamic_x: float
	var vedge_y: float
	var temp_s0: int
	var temp_s1: int
	var vpos_x: int
	var vpos_y: int
	var scrollv: float
	var spAC: float
	var r: Dictionary

	line_project_pos = F32_MAX

	for i in range(gMPCollisionGeometry.yakumono_count):
		line_info = gMPCollisionGeometry.line_info[i]
		line_data = line_info.line_data[nMPLineKindRWall]
		yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[line_info.yakumono_id]

		if (line_data.line_count != 0) and (_user_data_s(yakumono_dobj) < nMPYakumonoStatusOff):
			if _has_anim_joint(yakumono_dobj) or (_user_data_s(yakumono_dobj) != nMPYakumonoStatusNone):
				# This runs when the corner of the character's map collision diamond collides with a wall?
				vedge_y = yakumono_dobj.translate.x
				vedge_x = yakumono_dobj.translate.y

				dynamic_x = gMPCollisionSpeeds[line_info.yakumono_id].x

				vpdist_x = (position.x - vedge_y) + dynamic_x
				vpdist_y = (position.y - vedge_x) + gMPCollisionSpeeds[line_info.yakumono_id].y

				vtdist_x = translate.x - vedge_y
				vtdist_y = translate.y - vedge_x
			else:
				dynamic_x = 0.0
				vedge_x = 0.0
				vedge_y = 0.0

				vpdist_x = position.x
				vpdist_y = position.y

				vtdist_x = translate.x
				vtdist_y = translate.y
			if vpdist_x < vtdist_x:
				vdist1 = vpdist_x - 0.001
				vdist2 = vtdist_x + 0.001
			else:
				vdist1 = vtdist_x - 0.001
				vdist2 = vpdist_x + 0.001
			for line_id in range(line_data.group_id, line_data.group_id + line_data.line_count):
				if gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_prev > vdist2:
					continue
				elif gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_next < vdist1:
					break # goto l_break; // Bruhhhhhhhhhhhhhhh
				else:
					var vlinks: MPVertexLinks = gMPCollisionVertexLinks[line_id]
					var vertex_id: int = vlinks.vertex1

					vpos_x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].pos.x
					vpos_y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].pos.y

					for vid in range(vlinks.vertex1, (vlinks.vertex1 + vlinks.vertex2) - 1):
						vertex_id = vid
						temp_s0 = vpos_x
						temp_s1 = vpos_y

						vpos_x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id + 1]].pos.x
						vpos_y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id + 1]].pos.y

						if temp_s0 == vpos_x:
							if vtdist_x < vpdist_x:
								r = mpCollisionCheckLRSurfaceFlat(temp_s0, temp_s1, vpos_y, vpdist_x, vpdist_y, vtdist_x, vtdist_y)

								if r.ret == TRUE:
									scrollv = r.arg7
									spAC = r.arg8

									if line_project_pos <= (-(scrollv - (vpdist_x - dynamic_x)) if (scrollv < (vpdist_x - dynamic_x)) else (scrollv - (vpdist_x - dynamic_x))):
										continue

									ga_last.x = scrollv + vedge_y
									ga_last.y = spAC + vedge_x
									ga_last.z = 0.0

									stand_line_id = line_id

									angle.z = 0.0
									angle.y = 0.0
									angle.x = 1.0

									stand_coll_flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].vertex_flags

									line_project_pos = -(scrollv - (vpdist_x - dynamic_x)) if (scrollv < (vpdist_x - dynamic_x)) else (scrollv - (vpdist_x - dynamic_x))
						else:
							r = mpCollisionCheckRWallSurfaceTilt(temp_s0, temp_s1, vpos_x, vpos_y, vpdist_x, vpdist_y, vtdist_x, vtdist_y)

							if r.ret == TRUE:
								scrollv = r.dfx
								spAC = r.dfy

								if line_project_pos <= (-(scrollv - (vpdist_x - dynamic_x)) if (scrollv < (vpdist_x - dynamic_x)) else (scrollv - (vpdist_x - dynamic_x))):
									continue

								ga_last.x = scrollv + vedge_y
								ga_last.y = spAC + vedge_x
								ga_last.z = 0.0

								stand_line_id = line_id

								angle = mpCollisionGetLRAngle(temp_s0, temp_s1, vpos_x, vpos_y, +1)

								stand_coll_flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].vertex_flags

								line_project_pos = -(scrollv - (vpdist_x - dynamic_x)) if (scrollv < (vpdist_x - dynamic_x)) else (scrollv - (vpdist_x - dynamic_x))
			# l_break: continue; // BRUHHHHHHHHHHHHHHHHH
	if line_project_pos == F32_MAX:
		return {"ret": FALSE, "ga_last": ga_last, "stand_line_id": stand_line_id, "stand_coll_flags": stand_coll_flags, "angle": angle}
	return {"ret": TRUE, "ga_last": ga_last, "stand_line_id": stand_line_id, "stand_coll_flags": stand_coll_flags, "angle": angle}

## 0x800F7D24
## C: sb32 (s32 v1x, s32 v1y, s32 vpos_x, f32 vpdist_x, f32 vpdist_y, f32 vtdist_x, f32 vtdist_y, f32 *arg7, f32 *arg8)
## Returns {"ret", "arg7", "arg8"} (written only when ret == TRUE).
static func mpCollisionCheckLRSurfaceFlat(v1x: int, v1y: int, vpos_x: int, vpdist_x: float, vpdist_y: float, vtdist_x: float, vtdist_y: float, arg7: float = 0.0, arg8: float = 0.0) -> Dictionary:
	var temp_f18: float
	var vnear: int
	var vfar: int
	var ddist_y: float
	var vdist_x: int = vpos_x - v1y
	var ddist_x: float = vpdist_x - vtdist_x
	var vddist_x: float = v1x - vpdist_x

	if ddist_x > 0.0:
		if ((v1x - 0.001) > vpdist_x) or (vtdist_x >= v1x):
			return {"ret": FALSE, "arg7": arg7, "arg8": arg8}
	elif ((v1x + 0.001) < vpdist_x) or (vtdist_x <= v1x):
		return {"ret": FALSE, "arg7": arg7, "arg8": arg8}
	ddist_y = vpdist_y - vtdist_y

	if vdist_x < 0:
		vnear = vpos_x
		vfar = v1y
	else:
		vfar = vpos_x
		vnear = v1y

	if ddist_y > 0.0:
		if (vfar < vtdist_y) or (vpdist_y < vnear):
			return {"ret": FALSE, "arg7": arg7, "arg8": arg8}
	elif (vfar < vpdist_y) or (vtdist_y < vnear):
		return {"ret": FALSE, "arg7": arg7, "arg8": arg8}
	temp_f18 = ((vddist_x / ddist_x) * ddist_y) + vpdist_y

	if (temp_f18 < vnear) or (temp_f18 > vfar):
		return {"ret": FALSE, "arg7": arg7, "arg8": arg8}

	arg7 = v1x
	arg8 = temp_f18

	return {"ret": TRUE, "arg7": arg7, "arg8": arg8}

## 0x800F7F00
## Returns {"ret", "ga_last", "stand_line_id", "stand_coll_flags", "angle"}
static func mpCollisionCheckLWallLineCollisionSame(position: Vector3, translate: Vector3, ga_last = null, stand_line_id = null, stand_coll_flags = null, angle = null) -> Dictionary:
	if ga_last == null:
		ga_last = Vector3.ZERO
	if stand_line_id == null:
		stand_line_id = -1
	if stand_coll_flags == null:
		stand_coll_flags = 0
	if angle == null:
		angle = Vector3.ZERO
	var line_info: MPLineInfo
	var line_data: MPLineData
	var yakumono_dobj: DObj
	var vdist1: float
	var vdist2: float
	var vpdist_x: float
	var vpdist_y: float
	var vtdist_x: float
	var vtdist_y: float
	var line_project_pos: float
	var vedge_x: float
	var vedge_y: float
	var temp_s0: int
	var temp_s1: int
	var vpos_x: int
	var vpos_y: int
	var scrollv: float
	var spAC: float
	var r: Dictionary

	line_project_pos = F32_MAX

	for i in range(gMPCollisionGeometry.yakumono_count):
		line_info = gMPCollisionGeometry.line_info[i]
		line_data = line_info.line_data[nMPLineKindLWall]
		yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[line_info.yakumono_id]

		if (line_data.line_count != 0) and (_user_data_s(yakumono_dobj) < nMPYakumonoStatusOff):
			if _has_anim_joint(yakumono_dobj) or (_user_data_s(yakumono_dobj) != nMPYakumonoStatusNone):
				# This runs when the corner of the character's map collision diamond collides with a wall?
				vedge_y = yakumono_dobj.translate.x
				vedge_x = yakumono_dobj.translate.y

				vpdist_x = position.x - vedge_y
				vpdist_y = position.y - vedge_x

				vtdist_x = translate.x - vedge_y
				vtdist_y = translate.y - vedge_x
			else:
				vedge_x = 0.0
				vedge_y = 0.0

				vpdist_x = position.x
				vpdist_y = position.y

				vtdist_x = translate.x
				vtdist_y = translate.y
			if vpdist_x < vtdist_x:
				vdist1 = vpdist_x - 0.001
				vdist2 = vtdist_x + 0.001
			else:
				vdist1 = vtdist_x - 0.001
				vdist2 = vpdist_x + 0.001
			for line_id in range(line_data.group_id, line_data.group_id + line_data.line_count):
				if gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_next < vdist1:
					continue
				elif gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_prev > vdist2:
					break # goto l_break; // Bruhhhhhhhhhhhhhhh
				else:
					var vlinks: MPVertexLinks = gMPCollisionVertexLinks[line_id]
					var vertex_id: int = vlinks.vertex1

					vpos_x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].pos.x
					vpos_y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].pos.y

					for vid in range(vlinks.vertex1, (vlinks.vertex1 + vlinks.vertex2) - 1):
						vertex_id = vid
						temp_s0 = vpos_x
						temp_s1 = vpos_y

						vpos_x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id + 1]].pos.x
						vpos_y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id + 1]].pos.y

						if temp_s0 == vpos_x:
							if vtdist_x > vpdist_x:
								r = mpCollisionCheckLRSurfaceFlat(temp_s0, temp_s1, vpos_y, vpdist_x, vpdist_y, vtdist_x, vtdist_y)

								if r.ret == TRUE:
									scrollv = r.arg7
									spAC = r.arg8

									if line_project_pos <= (-(scrollv - vpdist_x) if (scrollv < vpdist_x) else (scrollv - vpdist_x)):
										continue

									ga_last.x = scrollv + vedge_y
									ga_last.y = spAC + vedge_x
									ga_last.z = 0.0

									stand_line_id = line_id

									angle.z = 0.0
									angle.y = 0.0
									angle.x = -1.0

									stand_coll_flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].vertex_flags

									line_project_pos = -(scrollv - vpdist_x) if (scrollv < vpdist_x) else (scrollv - vpdist_x)
						else:
							r = mpCollisionCheckLWallSurfaceTilt(temp_s0, temp_s1, vpos_x, vpos_y, vpdist_x, vpdist_y, vtdist_x, vtdist_y)

							if r.ret == TRUE:
								scrollv = r.dfx
								spAC = r.dfy

								if line_project_pos <= (-(scrollv - vpdist_x) if (scrollv < vpdist_x) else (scrollv - vpdist_x)):
									continue

								ga_last.x = scrollv + vedge_y
								ga_last.y = spAC + vedge_x
								ga_last.z = 0.0

								stand_line_id = line_id

								angle = mpCollisionGetLRAngle(temp_s0, temp_s1, vpos_x, vpos_y, -1)

								stand_coll_flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].vertex_flags

								line_project_pos = -(scrollv - vpdist_x) if (scrollv < vpdist_x) else (scrollv - vpdist_x)
			# l_break: continue; // BRUHHHHHHHHHHHHHHHHH
	if line_project_pos == F32_MAX:
		return {"ret": FALSE, "ga_last": ga_last, "stand_line_id": stand_line_id, "stand_coll_flags": stand_coll_flags, "angle": angle}
	return {"ret": TRUE, "ga_last": ga_last, "stand_line_id": stand_line_id, "stand_coll_flags": stand_coll_flags, "angle": angle}

## 0x800F8548
## Returns {"ret", "dfx", "dfy"} (written only when ret == TRUE).
static func mpCollisionCheckLWallSurfaceTilt(v1x: int, v1y: int, v2x: int, v2y: int, d1x: float, d1y: float, d2x: float, d2y: float, dfx: float = 0.0, dfy: float = 0.0) -> Dictionary:
	var vfarx: int
	var vnearx: int
	var ddist_x: float
	var ddist_y: float
	var vfary: int
	var vneary: int
	var vdist_x: int
	var vdist_y: int
	var temp_f12_2: float
	var vddiv: float
	var vddist_x: float
	var vddist_y: float
	var vddistdiv: float
	var vdscale: float
	var scale: float
	var var_f18: float

	vdist_x = v2x - v1x
	ddist_x = d1x - d2x

	if vdist_x < 0:
		vnearx = v2x
		vfarx = v1x
	else:
		vfarx = v2x
		vnearx = v1x
	if ddist_x > 0.0:
		if ((vfarx + 0.001) < d2x) or (d1x < (vnearx - 0.001)):
			return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
	elif ((vfarx + 0.001) < d1x) or (d2x < (vnearx - 0.001)):
		return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
	ddist_y = d1y - d2y
	vdist_y = v2y - v1y

	if vdist_y < 0:
		vneary = v2y
		vfary = v1y
	else:
		vfary = v2y
		vneary = v1y
	if ddist_y > 0.0:
		if (vfary < d2y) or (d1y < vneary):
			return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
	elif (vfary < d1y) or (d2y < vneary):
		return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
	if (d2x - (v1x + (((d2y - v1y) / float(v2y - v1y)) * vdist_x))) >= 0.001:
		temp_f12_2 = v1x + (((d1y - v1y) / float(vdist_y)) * vdist_x)

		if (d1x - temp_f12_2) > -0.001:
			if ((d1x - temp_f12_2) < 0.001) and (d1y <= vfary) and (vneary <= d1y):
				dfx = temp_f12_2
				dfy = d1y

				return {"ret": TRUE, "dfx": dfx, "dfy": dfy}
		else:
			vddist_x = v1x - d1x
			vddist_y = v1y - d1y

			var_f18 = (ddist_y * vddist_x) - (ddist_x * vddist_y)
			scale = (vdist_y * ddist_x) - (vdist_x * ddist_y)

			vddiv = var_f18 / scale

			if vddiv < 0.0:
				if vddiv < -0.001:
					return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
				var_f18 = 0.0
			elif vddiv > 1.0:
				if vddiv > 1.001:
					return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
				var_f18 = scale
			vddistdiv = ((vdist_x * vddist_y) - (vdist_y * vddist_x)) / scale

			if (vddistdiv < -0.001) or (vddistdiv > 1.001):
				return {"ret": FALSE, "dfx": dfx, "dfy": dfy}
			vdscale = 1.0 / scale

			dfx = v1x + ((var_f18 * vdist_x) * vdscale)
			dfy = v1y + ((var_f18 * vdist_y) * vdscale)

			return {"ret": TRUE, "dfx": dfx, "dfy": dfy}
	return {"ret": FALSE, "dfx": dfx, "dfy": dfy}

## 0x800F8974
## Returns {"ret", "ga_last", "stand_line_id", "stand_coll_flags", "angle"}
static func mpCollisionCheckLWallLineCollisionDiff(position: Vector3, translate: Vector3, ga_last = null, stand_line_id = null, stand_coll_flags = null, angle = null) -> Dictionary:
	if ga_last == null:
		ga_last = Vector3.ZERO
	if stand_line_id == null:
		stand_line_id = -1
	if stand_coll_flags == null:
		stand_coll_flags = 0
	if angle == null:
		angle = Vector3.ZERO
	var line_info: MPLineInfo
	var line_data: MPLineData
	var yakumono_dobj: DObj
	var vdist1: float
	var vdist2: float
	var vpdist_x: float
	var vpdist_y: float
	var vtdist_x: float
	var vtdist_y: float
	var line_project_pos: float
	var vedge_x: float
	var dynamic_x: float
	var vedge_y: float
	var temp_s0: int
	var temp_s1: int
	var vpos_x: int
	var vpos_y: int
	var scrollv: float
	var spAC: float
	var r: Dictionary

	line_project_pos = F32_MAX

	for i in range(gMPCollisionGeometry.yakumono_count):
		line_info = gMPCollisionGeometry.line_info[i]
		line_data = line_info.line_data[nMPLineKindLWall]
		yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[line_info.yakumono_id]

		if (line_data.line_count != 0) and (_user_data_s(yakumono_dobj) < nMPYakumonoStatusOff):
			if _has_anim_joint(yakumono_dobj) or (_user_data_s(yakumono_dobj) != nMPYakumonoStatusNone):
				# This runs when the corner of the character's map collision diamond collides with a wall?
				vedge_y = yakumono_dobj.translate.x
				vedge_x = yakumono_dobj.translate.y

				dynamic_x = gMPCollisionSpeeds[line_info.yakumono_id].x

				vpdist_x = (position.x - vedge_y) + dynamic_x
				vpdist_y = (position.y - vedge_x) + gMPCollisionSpeeds[line_info.yakumono_id].y

				vtdist_x = translate.x - vedge_y
				vtdist_y = translate.y - vedge_x
			else:
				dynamic_x = 0.0
				vedge_x = 0.0
				vedge_y = 0.0

				vpdist_x = position.x
				vpdist_y = position.y

				vtdist_x = translate.x
				vtdist_y = translate.y
			if vpdist_x < vtdist_x:
				vdist1 = vpdist_x - 0.001
				vdist2 = vtdist_x + 0.001
			else:
				vdist1 = vtdist_x - 0.001
				vdist2 = vpdist_x + 0.001
			for line_id in range(line_data.group_id, line_data.group_id + line_data.line_count):
				if gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_next < vdist1:
					continue
				elif gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_prev > vdist2:
					break # goto l_break; // Bruhhhhhhhhhhhhhhh
				else:
					var vlinks: MPVertexLinks = gMPCollisionVertexLinks[line_id]
					var vertex_id: int = vlinks.vertex1

					vpos_x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].pos.x
					vpos_y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].pos.y

					for vid in range(vlinks.vertex1, (vlinks.vertex1 + vlinks.vertex2) - 1):
						vertex_id = vid
						temp_s0 = vpos_x
						temp_s1 = vpos_y

						vpos_x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id + 1]].pos.x
						vpos_y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id + 1]].pos.y

						if temp_s0 == vpos_x:
							if vtdist_x > vpdist_x:
								r = mpCollisionCheckLRSurfaceFlat(temp_s0, temp_s1, vpos_y, vpdist_x, vpdist_y, vtdist_x, vtdist_y)

								if r.ret == TRUE:
									scrollv = r.arg7
									spAC = r.arg8

									if line_project_pos <= (-(scrollv - (vpdist_x - dynamic_x)) if (scrollv < (vpdist_x - dynamic_x)) else (scrollv - (vpdist_x - dynamic_x))):
										continue

									ga_last.x = scrollv + vedge_y
									ga_last.y = spAC + vedge_x
									ga_last.z = 0.0

									stand_line_id = line_id

									angle.z = 0.0
									angle.y = 0.0
									angle.x = -1.0

									stand_coll_flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].vertex_flags

									line_project_pos = -(scrollv - (vpdist_x - dynamic_x)) if (scrollv < (vpdist_x - dynamic_x)) else (scrollv - (vpdist_x - dynamic_x))
						else:
							r = mpCollisionCheckLWallSurfaceTilt(temp_s0, temp_s1, vpos_x, vpos_y, vpdist_x, vpdist_y, vtdist_x, vtdist_y)

							if r.ret == TRUE:
								scrollv = r.dfx
								spAC = r.dfy

								if line_project_pos <= (-(scrollv - (vpdist_x - dynamic_x)) if (scrollv < (vpdist_x - dynamic_x)) else (scrollv - (vpdist_x - dynamic_x))):
									continue

								ga_last.x = scrollv + vedge_y
								ga_last.y = spAC + vedge_x
								ga_last.z = 0.0

								stand_line_id = line_id

								angle = mpCollisionGetLRAngle(temp_s0, temp_s1, vpos_x, vpos_y, -1)

								stand_coll_flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id]].vertex_flags

								line_project_pos = -(scrollv - (vpdist_x - dynamic_x)) if (scrollv < (vpdist_x - dynamic_x)) else (scrollv - (vpdist_x - dynamic_x))
			# l_break: continue; // BRUHHHHHHHHHHHHHHHHH
	if line_project_pos == F32_MAX:
		return {"ret": FALSE, "ga_last": ga_last, "stand_line_id": stand_line_id, "stand_coll_flags": stand_coll_flags, "angle": angle}
	return {"ret": TRUE, "ga_last": ga_last, "stand_line_id": stand_line_id, "stand_coll_flags": stand_coll_flags, "angle": angle}

## 0x800F8FFC
static func func_ovl2_800F8FFC(position: Vector3) -> int:
	var line_info: MPLineInfo
	var line_data: MPLineData
	var yakumono_dobj: DObj
	var vpdist_x: float
	var vpdist_y: float

	for i in range(gMPCollisionGeometry.yakumono_count):
		line_info = gMPCollisionGeometry.line_info[i]
		line_data = line_info.line_data[nMPLineKindFloor]
		yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[line_info.yakumono_id]

		if (line_data.line_count != 0) and (_user_data_s(yakumono_dobj) < nMPYakumonoStatusOff):
			if _has_anim_joint(yakumono_dobj) or (_user_data_s(yakumono_dobj) != nMPYakumonoStatusNone):
				# This runs when the corner of the character's map collision diamond collides with a wall?
				vpdist_x = (position.x - yakumono_dobj.translate.x)
				vpdist_y = (position.y - yakumono_dobj.translate.y) + 0.001
			else:
				vpdist_x = position.x
				vpdist_y = position.y + 0.001
			for line_id in range(line_data.group_id, line_data.group_id + line_data.line_count):
				if gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_prev <= vpdist_y:
					var vertex_id1: int = gMPCollisionVertexLinks[line_id].vertex1
					var vertex_id2: int = gMPCollisionVertexLinks[line_id].vertex2 - 1

					var x1: int = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1]].pos.x
					var x2: int = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1 + vertex_id2]].pos.x

					if ((x1 <= vpdist_x) and (x2 >= vpdist_x)) or ((x2 <= vpdist_x) and (x1 >= vpdist_x)):
						if vertex_id2 != 1:
							var j := 0
							while j < vertex_id2:
								x1 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1]].pos.x
								x2 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1 + 1]].pos.x

								if mpCollisionGetLineDistanceFC(vpdist_x, x1, gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1]].pos.y, x2, gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1 + 1]].pos.y) < vpdist_y:
									return TRUE
								j += 1
								vertex_id1 += 1
						elif mpCollisionGetLineDistanceFC(vpdist_x, x1, gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1]].pos.y, x2, gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1 + 1]].pos.y) < vpdist_y:
							return TRUE
	return FALSE

## Shared result builder for the four project functions (PORTING.md example keys "ground_dist" /
## "flags" are provided as aliases of the C names "ga_dist" / "stand_coll_flags").
static func _port_project_result(ret: int, project_line_id: int, ga_dist: float, stand_coll_flags: int, angle: Vector3) -> Dictionary:
	return {"ret": ret, "project_line_id": project_line_id, "ga_dist": ga_dist, "ground_dist": ga_dist, "stand_coll_flags": stand_coll_flags, "flags": stand_coll_flags, "angle": angle}

## 0x800F9348
## C: sb32 mpCollisionCheckProjectFloor(Vec3f *position, s32 *project_line_id, f32 *ga_dist, u32 *stand_coll_flags, Vec3f *angle)
## Returns {"ret", "project_line_id", "ga_dist" (= "ground_dist"), "stand_coll_flags" (= "flags"), "angle"};
## outputs are written only when ret == TRUE (optional in-out current values).
static func mpCollisionCheckProjectFloor(position: Vector3, project_line_id = null, ga_dist = null, stand_coll_flags = null, angle = null) -> Dictionary:
	if project_line_id == null:
		project_line_id = -1
	if ga_dist == null:
		ga_dist = 0.0
	if stand_coll_flags == null:
		stand_coll_flags = 0
	if angle == null:
		angle = Vector3.ZERO
	var line_info: MPLineInfo
	var line_data: MPLineData
	var yakumono_dobj: DObj
	var vpdist_x: float
	var vpdist_y: float
	var line_project_pos: float
	var fpos: float
	var gdist: float

	line_project_pos = F32_MAX

	for i in range(gMPCollisionGeometry.yakumono_count):
		line_info = gMPCollisionGeometry.line_info[i]
		line_data = line_info.line_data[nMPLineKindFloor]
		yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[line_info.yakumono_id]

		if (line_data.line_count != 0) and (_user_data_s(yakumono_dobj) < nMPYakumonoStatusOff):
			if _has_anim_joint(yakumono_dobj) or (_user_data_s(yakumono_dobj) != nMPYakumonoStatusNone):
				# This runs when the corner of the character's map collision diamond collides with a wall?
				vpdist_x = (position.x - yakumono_dobj.translate.x)
				vpdist_y = (position.y - yakumono_dobj.translate.y)
			else:
				vpdist_x = position.x
				vpdist_y = position.y
			for line_id in range(line_data.group_id, line_data.group_id + line_data.line_count):
				if gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_prev <= vpdist_y:
					var vertex_id1: int = gMPCollisionVertexLinks[line_id].vertex1
					var vertex_id2: int = gMPCollisionVertexLinks[line_id].vertex2 - 1

					var x1: int = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1]].pos.x
					var x2: int = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1 + vertex_id2]].pos.x
					var y1: int
					var y2: int

					if ((x1 <= vpdist_x) and (x2 >= vpdist_x)) or ((x2 <= vpdist_x) and (x1 >= vpdist_x)):
						if vertex_id2 != 1:
							var j := 0
							while j < vertex_id2:
								x1 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1]].pos.x
								x2 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1 + 1]].pos.x

								if ((x1 <= vpdist_x) and (x2 >= vpdist_x)) or ((x2 <= vpdist_x) and (x1 >= vpdist_x)):
									break
								j += 1
								vertex_id1 += 1
						y1 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1]].pos.y
						y2 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1 + 1]].pos.y

						fpos = mpCollisionGetLineDistanceFC(vpdist_x, x1, y1, x2, y2)

						gdist = fpos - vpdist_y

						if fpos <= vpdist_y:
							if ABSF(gdist) < line_project_pos:
								project_line_id = line_id
								ga_dist = gdist
								stand_coll_flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1]].vertex_flags
								angle = mpCollisionGetFCAngle(x1, y1, x2, y2, +1)
								line_project_pos = ABSF(gdist)
	if line_project_pos == F32_MAX:
		return _port_project_result(FALSE, project_line_id, ga_dist, stand_coll_flags, angle)
	return _port_project_result(TRUE, project_line_id, ga_dist, stand_coll_flags, angle)

## Unused?
## Returns {"ret", "project_line_id", "ga_dist" (= "ground_dist"), "stand_coll_flags" (= "flags"), "angle"}
static func mpCollisionCheckProjectCeil(position: Vector3, project_line_id = null, ga_dist = null, stand_coll_flags = null, angle = null) -> Dictionary:
	if project_line_id == null:
		project_line_id = -1
	if ga_dist == null:
		ga_dist = 0.0
	if stand_coll_flags == null:
		stand_coll_flags = 0
	if angle == null:
		angle = Vector3.ZERO
	var line_info: MPLineInfo
	var line_data: MPLineData
	var yakumono_dobj: DObj
	var vpdist_x: float
	var vpdist_y: float
	var line_project_pos: float
	var fpos: float
	var gdist: float

	line_project_pos = F32_MAX

	for i in range(gMPCollisionGeometry.yakumono_count):
		line_info = gMPCollisionGeometry.line_info[i]
		line_data = line_info.line_data[nMPLineKindCeil]
		yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[line_info.yakumono_id]

		if (line_data.line_count != 0) and (_user_data_s(yakumono_dobj) < nMPYakumonoStatusOff):
			if _has_anim_joint(yakumono_dobj) or (_user_data_s(yakumono_dobj) != nMPYakumonoStatusNone):
				# This runs when the corner of the character's map collision diamond collides with a wall?
				vpdist_x = (position.x - yakumono_dobj.translate.x)
				vpdist_y = (position.y - yakumono_dobj.translate.y)
			else:
				vpdist_x = position.x
				vpdist_y = position.y
			for line_id in range(line_data.group_id, line_data.group_id + line_data.line_count):
				if gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_next >= vpdist_y:
					var vertex_id1: int = gMPCollisionVertexLinks[line_id].vertex1
					var vertex_id2: int = gMPCollisionVertexLinks[line_id].vertex2 - 1

					var x1: int = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1]].pos.x
					var x2: int = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1 + vertex_id2]].pos.x
					var y1: int
					var y2: int

					if ((x1 <= vpdist_x) and (x2 >= vpdist_x)) or ((x2 <= vpdist_x) and (x1 >= vpdist_x)):
						if vertex_id2 != 1:
							var j := 0
							while j < vertex_id2:
								x1 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1]].pos.x
								x2 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1 + 1]].pos.x

								if ((x1 <= vpdist_x) and (x2 >= vpdist_x)) or ((x2 <= vpdist_x) and (x1 >= vpdist_x)):
									break
								j += 1
								vertex_id1 += 1
						y1 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1]].pos.y
						y2 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1 + 1]].pos.y

						fpos = mpCollisionGetLineDistanceFC(vpdist_x, x1, y1, x2, y2)

						gdist = fpos - vpdist_y

						if fpos >= vpdist_y:
							if ABSF(gdist) < line_project_pos:
								project_line_id = line_id
								ga_dist = gdist
								stand_coll_flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1]].vertex_flags
								angle = mpCollisionGetFCAngle(x1, y1, x2, y2, -1)
								line_project_pos = ABSF(gdist)
	if line_project_pos == F32_MAX:
		return _port_project_result(FALSE, project_line_id, ga_dist, stand_coll_flags, angle)
	return _port_project_result(TRUE, project_line_id, ga_dist, stand_coll_flags, angle)

## 0x800F9C30
## Returns {"ret", "project_line_id", "ga_dist" (= "ground_dist"), "stand_coll_flags" (= "flags"), "angle"}
static func mpCollisionCheckProjectRWall(position: Vector3, project_line_id = null, ga_dist = null, stand_coll_flags = null, angle = null) -> Dictionary:
	if project_line_id == null:
		project_line_id = -1
	if ga_dist == null:
		ga_dist = 0.0
	if stand_coll_flags == null:
		stand_coll_flags = 0
	if angle == null:
		angle = Vector3.ZERO
	var line_info: MPLineInfo
	var line_data: MPLineData
	var yakumono_dobj: DObj
	var vpdist_x: float
	var vpdist_y: float
	var line_project_pos: float
	var fpos: float
	var gdist: float

	line_project_pos = F32_MAX

	for i in range(gMPCollisionGeometry.yakumono_count):
		line_info = gMPCollisionGeometry.line_info[i]
		line_data = line_info.line_data[nMPLineKindRWall]
		yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[line_info.yakumono_id]

		if (line_data.line_count != 0) and (_user_data_s(yakumono_dobj) < nMPYakumonoStatusOff):
			if _has_anim_joint(yakumono_dobj) or (_user_data_s(yakumono_dobj) != nMPYakumonoStatusNone):
				# This runs when the corner of the character's map collision diamond collides with a wall?
				vpdist_x = (position.x - yakumono_dobj.translate.x)
				vpdist_y = (position.y - yakumono_dobj.translate.y)
			else:
				vpdist_x = position.x
				vpdist_y = position.y
			for line_id in range(line_data.group_id, line_data.group_id + line_data.line_count):
				if gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_prev <= vpdist_x:
					var vertex_id1: int = gMPCollisionVertexLinks[line_id].vertex1
					var vertex_id2: int = gMPCollisionVertexLinks[line_id].vertex2 - 1

					var y1: int = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1]].pos.y
					var y2: int = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1 + vertex_id2]].pos.y
					var x1: int
					var x2: int

					if ((y1 <= vpdist_y) and (y2 >= vpdist_y)) or ((y2 <= vpdist_y) and (y1 >= vpdist_y)):
						if vertex_id2 != 1:
							var j := 0
							while j < vertex_id2:
								y1 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1]].pos.y
								y2 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1 + 1]].pos.y

								if ((y1 <= vpdist_y) and (y2 >= vpdist_y)) or ((y2 <= vpdist_y) and (y1 >= vpdist_y)):
									break
								j += 1
								vertex_id1 += 1
						x1 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1]].pos.x
						x2 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1 + 1]].pos.x

						fpos = mpCollisionGetLineDistanceLR(vpdist_y, x1, y1, x2, y2)

						gdist = fpos - vpdist_x

						if fpos <= vpdist_x:
							if ABSF(gdist) < line_project_pos:
								project_line_id = line_id
								ga_dist = gdist
								stand_coll_flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1]].vertex_flags
								angle = mpCollisionGetFCAngle(x1, y1, x2, y2, +1)
								line_project_pos = ABSF(gdist)
	if line_project_pos == F32_MAX:
		return _port_project_result(FALSE, project_line_id, ga_dist, stand_coll_flags, angle)
	return _port_project_result(TRUE, project_line_id, ga_dist, stand_coll_flags, angle)

## Unused?
## Returns {"ret", "project_line_id", "ga_dist" (= "ground_dist"), "stand_coll_flags" (= "flags"), "angle"}
static func mpCollisionCheckProjectLWall(position: Vector3, project_line_id = null, ga_dist = null, stand_coll_flags = null, angle = null) -> Dictionary:
	if project_line_id == null:
		project_line_id = -1
	if ga_dist == null:
		ga_dist = 0.0
	if stand_coll_flags == null:
		stand_coll_flags = 0
	if angle == null:
		angle = Vector3.ZERO
	var line_info: MPLineInfo
	var line_data: MPLineData
	var yakumono_dobj: DObj
	var vpdist_x: float
	var vpdist_y: float
	var line_project_pos: float
	var fpos: float
	var gdist: float

	line_project_pos = F32_MAX

	for i in range(gMPCollisionGeometry.yakumono_count):
		line_info = gMPCollisionGeometry.line_info[i]
		line_data = line_info.line_data[nMPLineKindLWall]
		yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[line_info.yakumono_id]

		if (line_data.line_count != 0) and (_user_data_s(yakumono_dobj) < nMPYakumonoStatusOff):
			if _has_anim_joint(yakumono_dobj) or (_user_data_s(yakumono_dobj) != nMPYakumonoStatusNone):
				# This runs when the corner of the character's map collision diamond collides with a wall?
				vpdist_x = (position.x - yakumono_dobj.translate.x)
				vpdist_y = (position.y - yakumono_dobj.translate.y)
			else:
				vpdist_x = position.x
				vpdist_y = position.y
			for line_id in range(line_data.group_id, line_data.group_id + line_data.line_count):
				if gMPCollisionVertexInfo.vertex_info[line_id].coll_pos_next >= vpdist_x:
					var vertex_id1: int = gMPCollisionVertexLinks[line_id].vertex1
					var vertex_id2: int = gMPCollisionVertexLinks[line_id].vertex2 - 1

					var y1: int = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1]].pos.y
					var y2: int = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1 + vertex_id2]].pos.y
					var x1: int
					var x2: int

					if ((y1 <= vpdist_y) and (y2 >= vpdist_y)) or ((y2 <= vpdist_y) and (y1 >= vpdist_y)):
						if vertex_id2 != 1:
							var j := 0
							while j < vertex_id2:
								y1 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1]].pos.y
								y2 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1 + 1]].pos.y

								if ((y1 <= vpdist_y) and (y2 >= vpdist_y)) or ((y2 <= vpdist_y) and (y1 >= vpdist_y)):
									break
								j += 1
								vertex_id1 += 1
						x1 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1]].pos.x
						x2 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1 + 1]].pos.x

						fpos = mpCollisionGetLineDistanceLR(vpdist_y, x1, y1, x2, y2)

						gdist = fpos - vpdist_x

						if fpos >= vpdist_x:
							if ABSF(gdist) < line_project_pos:
								project_line_id = line_id
								ga_dist = gdist
								stand_coll_flags = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vertex_id1]].vertex_flags
								angle = mpCollisionGetFCAngle(x1, y1, x2, y2, -1)
								line_project_pos = ABSF(gdist)
	if line_project_pos == F32_MAX:
		return _port_project_result(FALSE, project_line_id, ga_dist, stand_coll_flags, angle)
	return _port_project_result(TRUE, project_line_id, ga_dist, stand_coll_flags, angle)

## 0x800FA518
static func mpCollisionGetVertexCountLineID(line_id: int) -> int:
	var yakumono_dobj: DObj

	if (line_id == -1) or (line_id == -2):
		_mpCollisionHang("mpGetNbVertex() id = %d\n" % line_id)
		return 0
	yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[gMPCollisionVertexInfo.vertex_info[line_id].yakumono_id]

	if _user_data_s(yakumono_dobj) >= nMPYakumonoStatusOff:
		_mpCollisionHang("mpGetNbVertex() no collision\n")
	return gMPCollisionVertexLinks[line_id].vertex2

## 0x800F15E8
## C: void mpCollisionGetVertexPositionID(s32 line_id, s32 vertex_id, Vec3f *pos) -> returns pos
static func mpCollisionGetVertexPositionID(line_id: int, vertex_id: int, pos = null) -> Vector3:
	var yakumono_dobj: DObj
	var out_pos := Vector3.ZERO

	if (line_id == -1) or (line_id == -2):
		_mpCollisionHang("mpGetVertex() id = %d\n" % line_id)
		return out_pos
	yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[gMPCollisionVertexInfo.vertex_info[line_id].yakumono_id]

	if _user_data_s(yakumono_dobj) >= nMPYakumonoStatusOff:
		_mpCollisionHang("mpGetVertex() no collision\n")
	out_pos.x = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[gMPCollisionVertexLinks[line_id].vertex1 + vertex_id]].pos.x
	out_pos.y = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[gMPCollisionVertexLinks[line_id].vertex1 + vertex_id]].pos.y
	out_pos.z = 0.0

	yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[gMPCollisionVertexInfo.vertex_info[line_id].yakumono_id]

	if _has_anim_joint(yakumono_dobj) or (_user_data_s(yakumono_dobj) != nMPYakumonoStatusNone):
		out_pos.x += yakumono_dobj.translate.x
		out_pos.y += yakumono_dobj.translate.y
	return out_pos

## 0x800FA7B8
## C: void mpCollisionGetSpeedLineID(s32 line_id, Vec3f *speed) -> returns speed
static func mpCollisionGetSpeedLineID(line_id: int, speed = null) -> Vector3:
	var yakumono_dobj: DObj
	var yakumono_id: int

	if (line_id == -1) or (line_id == -2):
		_mpCollisionHang("mpGetSpeedId() id = %d\n" % line_id)
		return Vector3.ZERO
	yakumono_id = gMPCollisionVertexInfo.vertex_info[line_id].yakumono_id & 0xFF
	yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[yakumono_id]

	if _user_data_s(yakumono_dobj) >= nMPYakumonoStatusOff:
		_mpCollisionHang("mpGetSpeedId() no collision\n")
	return gMPCollisionSpeeds[yakumono_id]

## 0x800FA8A4 - Get the direction a line ID pushes outwards
static func mpCollisionGetLineTypeID(line_id: int) -> int:
	var yakumono_dobj: DObj
	var vertex_info: MPVertexInfo

	if (line_id == -1) or (line_id == -2):
		_mpCollisionHang("mpGetKindId() id = %d\n" % line_id)
		return -1
	vertex_info = gMPCollisionVertexInfo.vertex_info[line_id]
	yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[vertex_info.yakumono_id]

	if _user_data_s(yakumono_dobj) == nMPYakumonoStatusOff:
		_mpCollisionHang("mpGetKindId() no collision\n")
	return vertex_info.line_type

## 0x800FA964 - Get line ID connecting to the right edge of a ground
static func mpCollisionGetEdgeUnderRLineID(line_id: int) -> int:
	var yakumono_dobj: DObj
	var vertex_info: MPVertexInfo

	if (line_id == -1) or (line_id == -2):
		_mpCollisionHang("mpGetEdgeUnderRId() id = %d\n" % line_id)
		return -1
	vertex_info = gMPCollisionVertexInfo.vertex_info[line_id]
	yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[vertex_info.yakumono_id]

	if _user_data_s(yakumono_dobj) >= nMPYakumonoStatusOff:
		_mpCollisionHang("mpGetEdgeUnderRId() no collision\n")
	return vertex_info.edge_next_line_id

## 0x800FAA24 - Get line ID connecting to the left edge of a ground
static func mpCollisionGetEdgeUnderLLineID(line_id: int) -> int:
	var yakumono_dobj: DObj
	var vertex_info: MPVertexInfo

	if (line_id == -1) or (line_id == -2):
		_mpCollisionHang("mpGetEdgeUnderLId() id = %d\n" % line_id)
		return -1
	vertex_info = gMPCollisionVertexInfo.vertex_info[line_id]
	yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[vertex_info.yakumono_id]

	if _user_data_s(yakumono_dobj) >= nMPYakumonoStatusOff:
		_mpCollisionHang("mpGetEdgeUnderLId() no collision\n")
	return vertex_info.edge_prev_line_id

## 0x800FAAE4 - Get line ID connecting to the right edge of a ceiling
static func mpCollisionGetEdgeUpperRLineID(line_id: int) -> int:
	var yakumono_dobj: DObj
	var vertex_info: MPVertexInfo

	if (line_id == -1) or (line_id == -2):
		_mpCollisionHang("mpGetEdgeUpperRId() id = %d\n" % line_id)
		return -1
	vertex_info = gMPCollisionVertexInfo.vertex_info[line_id]
	yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[vertex_info.yakumono_id]

	if _user_data_s(yakumono_dobj) >= nMPYakumonoStatusOff:
		_mpCollisionHang("mpGetEdgeUpperRId() no collision\n")
	return vertex_info.edge_next_line_id

## 0x800FABA4 - Get line ID connecting to the left edge of a ceiling
static func mpCollisionGetEdgeUpperLLineID(line_id: int) -> int:
	var yakumono_dobj: DObj
	var vertex_info: MPVertexInfo

	if (line_id == -1) or (line_id == -2):
		_mpCollisionHang("mpGetEdgeUpperLId() id = %d\n" % line_id)
		return -1
	vertex_info = gMPCollisionVertexInfo.vertex_info[line_id]
	yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[vertex_info.yakumono_id]

	if _user_data_s(yakumono_dobj) >= nMPYakumonoStatusOff:
		_mpCollisionHang("mpGetEdgeUpperLId() no collision\n")
	return vertex_info.edge_prev_line_id

## 0x800FAC64 - Get line ID connecting to the upper edge of a left wall
static func mpCollisionGetEdgeRightULineID(line_id: int) -> int:
	var yakumono_dobj: DObj
	var vertex_info: MPVertexInfo

	if (line_id == -1) or (line_id == -2):
		_mpCollisionHang("mpGetEdgeRightUId() id = %d\n" % line_id)
		return -1
	vertex_info = gMPCollisionVertexInfo.vertex_info[line_id]
	yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[vertex_info.yakumono_id]

	if _user_data_s(yakumono_dobj) >= nMPYakumonoStatusOff:
		_mpCollisionHang("mpGetEdgeRightUId() no collision\n")
	return vertex_info.edge_next_line_id

## 0x800FAD24 - Get line ID connecting to the lower edge of a left wall
static func mpCollisionGetEdgeRightDLineID(line_id: int) -> int:
	var yakumono_dobj: DObj
	var vertex_info: MPVertexInfo

	if (line_id == -1) or (line_id == -2):
		_mpCollisionHang("mpGetEdgeRightDId() id = %d\n" % line_id)
		return -1
	vertex_info = gMPCollisionVertexInfo.vertex_info[line_id]
	yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[vertex_info.yakumono_id]

	if _user_data_s(yakumono_dobj) >= nMPYakumonoStatusOff:
		_mpCollisionHang("mpGetEdgeRightDId() no collision\n")
	return vertex_info.edge_prev_line_id

## 0x800FADE4 - Get line ID connecting to the upper edge of a right wall
static func mpCollisionGetEdgeLeftULineID(line_id: int) -> int:
	var yakumono_dobj: DObj
	var vertex_info: MPVertexInfo

	if (line_id == -1) or (line_id == -2):
		_mpCollisionHang("mpGetEdgeLeftUId() id = %d\n" % line_id)
		return -1
	vertex_info = gMPCollisionVertexInfo.vertex_info[line_id]
	yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[vertex_info.yakumono_id]

	if _user_data_s(yakumono_dobj) >= nMPYakumonoStatusOff:
		_mpCollisionHang("mpGetEdgeLeftUId() no collision\n")
	return vertex_info.edge_next_line_id

## 0x800FAEA4 - Get line ID connecting to the lower edge of a right wall
static func mpCollisionGetEdgeLeftDLineID(line_id: int) -> int:
	var yakumono_dobj: DObj
	var vertex_info: MPVertexInfo

	if (line_id == -1) or (line_id == -2):
		_mpCollisionHang("mpGetEdgeLeftDId() id = %d\n" % line_id)
		return -1
	vertex_info = gMPCollisionVertexInfo.vertex_info[line_id]
	yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[vertex_info.yakumono_id]

	if _user_data_s(yakumono_dobj) >= nMPYakumonoStatusOff:
		_mpCollisionHang("mpGetEdgeLeftDId() no collision\n")
	return vertex_info.edge_prev_line_id

## 0x800FAF64
## C: void mpCollisionGetPlayerMapObjPosition(s32 player, Vec3f *pos) -> returns pos.
## pos is in-out: it is left unchanged when no map object of kind `player` exists.
static func mpCollisionGetPlayerMapObjPosition(player: int, pos = null) -> Vector3:
	if pos == null:
		pos = Vector3.ZERO
	if not (gMPCollisionGeometry.mapobj_count):
		pos.z = 0.0
		pos.y = 0.0
		pos.x = 0.0
	else:
		var id: int = player

		for i in range(gMPCollisionGeometry.mapobj_count):
			if id == gMPCollisionMapObjs.mapobjs[i].mapobj_kind:
				pos.x = gMPCollisionMapObjs.mapobjs[i].pos.x
				pos.y = gMPCollisionMapObjs.mapobjs[i].pos.y
				pos.z = 0

				break
	return pos

## 0x800FB010
static func mpCollisionAllocVertexInfo() -> void:
	gMPCollisionVertexInfo = MPVertexInfoContainer.new() # syTaskmanMalloc(gMPCollisionLinesNum * sizeof(MPVertexInfo), 0x8)
	for i in range(gMPCollisionLinesNum):
		gMPCollisionVertexInfo.vertex_info.append(MPVertexInfo.new())

## 0x800FB04C
static func func_ovl2_800FB04C() -> void:
	var line_info: MPLineInfo
	var line_data: Array
	var yakumono_id: int
	var vnear: int
	var vfar: int
	var vp2: int
	var index: int
	var l: int = 0

	for i in range(gMPCollisionGeometry.yakumono_count):
		line_info = gMPCollisionGeometry.line_info[i]
		line_data = line_info.line_data
		yakumono_id = line_info.yakumono_id

		for j in range(line_info.line_data.size()):
			index = line_data[j].group_id
			for line_id in range(line_data[j].line_count):
				var vlinks: MPVertexLinks = gMPCollisionVertexLinks[index]

				if j < (line_info.line_data.size() / 2):
					vnear = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vlinks.vertex1]].pos.y
				else:
					vnear = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[vlinks.vertex1]].pos.x
				vfar = vnear

				for k in range(vlinks.vertex1 + 1, vlinks.vertex1 + vlinks.vertex2):
					if j < (line_info.line_data.size() / 2):
						vp2 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[k]].pos.y
					else:
						vp2 = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[k]].pos.x

					if vp2 >= vfar:
						vfar = vp2
					if vnear >= vp2:
						vnear = vp2
					else:
						continue
				gMPCollisionVertexInfo.vertex_info[l].coll_pos_next = vfar
				gMPCollisionVertexInfo.vertex_info[l].coll_pos_prev = vnear
				gMPCollisionVertexInfo.vertex_info[l].yakumono_id = yakumono_id & 0xFF

				l += 1
				index += 1

## 0x800FB2A0
static func mpCollisionInitLineTypesAll() -> void:
	for line_type in range(gMPCollisionLineGroups.size()):
		for line_id in range(gMPCollisionLineGroups[line_type].line_count):
			gMPCollisionVertexInfo.vertex_info[gMPCollisionLineGroups[line_type].line_id[line_id]].line_type = line_type

## 0x800FB31C
static func func_ovl2_800FB31C() -> void:
	var line_next: int
	var line_prev: int
	var unk_bool: int
	var vertex_id1: int
	var vertex_id2: int
	var vid: int
	var vtemp1: int
	var vtemp2: int

	for i in range(gMPCollisionLinesNum):
		line_next = -1
		line_prev = -1

		unk_bool = FALSE

		vtemp1 = gMPCollisionVertexLinks[i].vertex1

		vertex_id1 = gMPCollisionVertexIDs.vertex_id[vtemp1]
		vertex_id2 = gMPCollisionVertexIDs.vertex_id[vtemp1 + gMPCollisionVertexLinks[i].vertex2 - 1]

		for line_id in range(gMPCollisionLinesNum):
			if i != line_id:
				vtemp2 = gMPCollisionVertexLinks[line_id].vertex1

				vid = vtemp2 + gMPCollisionVertexLinks[line_id].vertex2 - 1

				if (vertex_id1 == gMPCollisionVertexIDs.vertex_id[vtemp2]) or (vertex_id1 == gMPCollisionVertexIDs.vertex_id[vid]):
					line_prev = line_id
				if (vertex_id2 == gMPCollisionVertexIDs.vertex_id[vtemp2]) or (vertex_id2 == gMPCollisionVertexIDs.vertex_id[vid]):
					line_next = line_id
			continue
		match gMPCollisionVertexInfo.vertex_info[i].line_type:
			nMPLineKindFloor, nMPLineKindCeil:
				if gMPCollisionVertexData.vpos[vertex_id2].pos.x < gMPCollisionVertexData.vpos[vertex_id1].pos.x:
					unk_bool = TRUE
			nMPLineKindRWall, nMPLineKindLWall:
				if gMPCollisionVertexData.vpos[vertex_id2].pos.y < gMPCollisionVertexData.vpos[vertex_id1].pos.y:
					unk_bool = TRUE
			_:
				pass
		if unk_bool != FALSE:
			gMPCollisionVertexInfo.vertex_info[i].edge_next_line_id = line_prev
			gMPCollisionVertexInfo.vertex_info[i].edge_prev_line_id = line_next
		else:
			gMPCollisionVertexInfo.vertex_info[i].edge_next_line_id = line_next
			gMPCollisionVertexInfo.vertex_info[i].edge_prev_line_id = line_prev
		continue

## 0x800FB554
static func func_ovl2_800FB554() -> void:
	func_ovl2_800FB04C()
	mpCollisionInitLineTypesAll()
	func_ovl2_800FB31C()

## 0x800FB584
## dobjdesc: Array of DObjDesc {id, ...} terminated by an entry with id == DOBJ_ARRAY_MAX.
static func mpCollisionAllocYakumono(dobjdesc) -> void:
	var yakumonos_num: int = 0
	var desc_index: int = 0

	while (dobjdesc != null) and (dobjdesc[desc_index].id != DOBJ_ARRAY_MAX):
		yakumonos_num += 1
		desc_index += 1
	gMPCollisionYakumonoDObjs = MPYakumonoDObj.new() # syTaskmanMalloc(yakumonos_num * sizeof(gMPCollisionYakumonoDObjs), 0x4)
	gMPCollisionYakumonoDObjs.dobjs.resize(yakumonos_num) # filled by gcSetupCustomDObjs (grDisplayMakeGeometryLayer)
	gMPCollisionSpeeds = [] # syTaskmanMalloc(yakumonos_num * sizeof(Vec3f), 0x4)
	gMPCollisionSpeeds.resize(yakumonos_num)

	for i in range(yakumonos_num):
		gMPCollisionSpeeds[i] = Vector3.ZERO
	gMPCollisionYakumonosNum = yakumonos_num

## 0x800FB808
static func mpCollisionUpdateBoundsCurrent() -> void:
	var index: int
	var bounds: MPBounds
	var line_data: Array
	var line_info: MPLineInfo
	var yakumono_dobj: DObj
	var vlinks: MPVertexLinks

	bounds = gMPCollisionBounds.stop.dup()

	for i in range(gMPCollisionGeometry.yakumono_count):
		line_info = gMPCollisionGeometry.line_info[i]
		yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[line_info.yakumono_id]

		if _has_anim_joint(yakumono_dobj) or ((_user_data_s(yakumono_dobj) < nMPYakumonoStatusOff) and (_user_data_s(yakumono_dobj) != nMPYakumonoStatusNone)):
			var x: float = yakumono_dobj.translate.x
			var y: float = yakumono_dobj.translate.y

			line_data = line_info.line_data

			for j in range(line_info.line_data.size()):
				index = line_data[j].group_id
				for k in range(line_data[j].line_count):
					vlinks = gMPCollisionVertexLinks[index]

					for l in range(vlinks.vertex1, vlinks.vertex1 + vlinks.vertex2):
						var vx: int = int(_f32(gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[l]].pos.x + x))
						var vy: int = int(_f32(gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[l]].pos.y + y))

						if bounds.top < vy:
							bounds.top = vy
						elif bounds.bottom > vy:
							bounds.bottom = vy
						if bounds.right < vx:
							bounds.right = vx
						elif bounds.left > vx:
							bounds.left = vx
					index += 1
	gMPCollisionBounds.current.copy_from(bounds)

## 0x800FBA84
static func mpCollisionUpdateBoundsDiff() -> void:
	gMPCollisionBounds.diff.top    = gMPCollisionBounds.current.top    - gMPCollisionBounds.start.top
	gMPCollisionBounds.diff.bottom = gMPCollisionBounds.current.bottom - gMPCollisionBounds.start.bottom
	gMPCollisionBounds.diff.right  = gMPCollisionBounds.current.right  - gMPCollisionBounds.start.right
	gMPCollisionBounds.diff.left   = gMPCollisionBounds.current.left   - gMPCollisionBounds.start.left

## objanim.c procedures used by mpCollisionPlayYakumonoAnim. ObjAnim (sys) does not play the TraI
## spline track nor MObj material animations; the gr port (Grdisplay) has complete versions and keeps
## a DObj's MObjs in meta "mobjs". Its procedures are used when present, looked up at run time so this
## file does not depend on Grdisplay at compile time; otherwise ObjAnim's are called.
static var _port_objanim_procs: Dictionary = {}

static func _port_objanim_proc(name: StringName) -> Callable:
	if not _port_objanim_procs.has(name):
		var proc := Callable(ObjAnim, name)

		if ResourceLoader.exists("res://scripts/gr/Grdisplay.gd"):
			var gr = load("res://scripts/gr/Grdisplay.gd")

			if (gr != null) and Callable(gr, name).is_valid():
				proc = Callable(gr, name)
		_port_objanim_procs[name] = proc
	return _port_objanim_procs[name]

## dobj->mobj list (MObjs live in DObj meta "mobjs" in this port).
static func _port_dobj_mobjs(dobj: DObj) -> Array:
	if dobj.has_meta(&"mobjs"):
		return dobj.get_meta(&"mobjs")
	return []

## 0x800FBAD0 - process of the layer-1 ground GObj when the layer has animations (dGRDisplayDescs[1])
static func mpCollisionPlayYakumonoAnim(ground_gobj) -> void:
	var dobj: DObj = DObjGetStruct(ground_gobj)
	var i: int = 0
	var gcParseDObjAnimJoint := _port_objanim_proc(&"gcParseDObjAnimJoint")
	var gcPlayDObjAnimJoint := _port_objanim_proc(&"gcPlayDObjAnimJoint")
	var gcParseMObjMatAnimJoint := _port_objanim_proc(&"gcParseMObjMatAnimJoint")
	var gcPlayMObjMatAnim := _port_objanim_proc(&"gcPlayMObjMatAnim")

	while dobj != null:
		var translate: Vector3

		if (i < gMPCollisionYakumonoDObjs.dobjs.size()) and (dobj == gMPCollisionYakumonoDObjs.dobjs[i]):
			if (_user_data_s(dobj) != nMPYakumonoStatusOn) and (_user_data_s(dobj) != nMPYakumonoStatusOff):
				var flags: int = dobj.flags & 0xFF # u8

				gcParseDObjAnimJoint.call(dobj)

				translate = dobj.translate

				gcPlayDObjAnimJoint.call(dobj)

				gMPCollisionSpeeds[i].x = dobj.translate.x - translate.x
				gMPCollisionSpeeds[i].y = dobj.translate.y - translate.y
				gMPCollisionSpeeds[i].z = dobj.translate.z - translate.z

				if flags == DOBJ_FLAG_NONE:
					if (dobj.flags & 0xFF) != DOBJ_FLAG_NONE:
						_set_user_data_s(dobj, nMPYakumonoStatusHidden)
				elif (dobj.flags & 0xFF) == DOBJ_FLAG_NONE:
					_set_user_data_s(dobj, nMPYakumonoStatusShow)
			if i < (gMPCollisionYakumonosNum - 1):
				i += 1
		else:
			gcParseDObjAnimJoint.call(dobj)
			gcPlayDObjAnimJoint.call(dobj)

		for mobj in _port_dobj_mobjs(dobj): # mobj = dobj->mobj; while (mobj != NULL) { ...; mobj = mobj->next; }
			gcParseMObjMatAnimJoint.call(mobj)
			gcPlayMObjMatAnim.call(mobj)

		if dobj.child != null:
			dobj = dobj.child
		elif dobj.sib_next != null:
			dobj = dobj.sib_next
		else:
			while true:
				if dobj.parent == DOBJ_PARENT_NULL:
					dobj = null

					break
				elif dobj.parent.sib_next != null:
					dobj = dobj.parent.sib_next

					break
				else:
					dobj = dobj.parent

					continue
	mpCollisionUpdateBoundsCurrent()
	mpCollisionUpdateBoundsDiff()

	gMPCollisionUpdateTic = (gMPCollisionUpdateTic + 1) & 0xFFFF

## 0x800FBCF8 - process of the layer-1 ground GObj when the layer has no animations
static func mpCollisionAdvanceUpdateTic(ground_gobj) -> void:
	gMPCollisionUpdateTic = (gMPCollisionUpdateTic + 1) & 0xFFFF

## 0x800FBD14
static func mpCollisionInitYakumonoAll() -> void:
	var index: int
	var yakumono_dobj: DObj
	var bounds_moved := MPBounds.new()
	var bounds_static := MPBounds.new()
	var vx: int
	var vy: int
	var tx: float
	var ty: float
	var line_data: Array
	var line_info: MPLineInfo
	var vlinks: MPVertexLinks

	bounds_moved.top = -65536.0
	bounds_moved.right = -65536.0
	bounds_static.top = -65536.0
	bounds_static.right = -65536.0

	bounds_static.left = 65536.0
	bounds_static.bottom = 65536.0
	bounds_moved.left = 65536.0
	bounds_moved.bottom = 65536.0

	for i in range(gMPCollisionGeometry.yakumono_count):
		line_info = gMPCollisionGeometry.line_info[i]
		yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[line_info.yakumono_id]

		if (_user_data_s(yakumono_dobj) != nMPYakumonoStatusOn) and (_user_data_s(yakumono_dobj) != nMPYakumonoStatusOff):
			if _has_anim_joint(yakumono_dobj):
				tx = yakumono_dobj.translate.x
				ty = yakumono_dobj.translate.y
			else:
				tx = 0.0
				ty = 0.0
			line_data = line_info.line_data

			for j in range(line_info.line_data.size()):
				index = line_data[j].group_id
				for k in range(line_data[j].line_count):
					vlinks = gMPCollisionVertexLinks[index]

					for l in range(vlinks.vertex1, vlinks.vertex1 + vlinks.vertex2):
						vx = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[l]].pos.x
						vy = gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[l]].pos.y

						if not _has_anim_joint(yakumono_dobj):
							if bounds_static.top < vy:
								bounds_static.top = vy
							if bounds_static.bottom > vy:
								bounds_static.bottom = vy
							if bounds_static.right < vx:
								bounds_static.right = vx
							if bounds_static.left > vx:
								bounds_static.left = vx
						vx = int(_f32(vx + tx)) # s32 += f32
						vy = int(_f32(vy + ty))

						if bounds_moved.top < vy:
							bounds_moved.top = vy
						if bounds_moved.bottom > vy:
							bounds_moved.bottom = vy
						if bounds_moved.right < vx:
							bounds_moved.right = vx
						if bounds_moved.left > vx:
							bounds_moved.left = vx
					index += 1
	# Slight WARNING: not sure about this. The member names in the struct don't seem to correspond to their suggested purpose...
	# ...or I just don't understand what is going on. Or both.
	gMPCollisionBounds.start.copy_from(bounds_moved)
	gMPCollisionBounds.stop.copy_from(bounds_static)
	gMPCollisionBounds.current.copy_from(bounds_moved)
	gMPCollisionBounds.diff.left = 0.0
	gMPCollisionBounds.diff.right = 0.0
	gMPCollisionBounds.diff.bottom = 0.0
	gMPCollisionBounds.diff.top = 0.0

## 0x800FC09C
static func mpCollisionAllocLinesGetCountTotal() -> int:
	var line_info: MPLineInfo
	var line_count: Array = [0, 0, 0, 0] # s32 line_count[nMPLineKindEnumCount]
	var line_total: int

	for i in range(line_count.size()):
		line_count[i] = 0

	for i in range(gMPCollisionGeometry.yakumono_count):
		line_info = gMPCollisionGeometry.line_info[i]

		for j in range((line_count.size() + line_info.line_data.size()) / 2):
			line_count[j] += line_info.line_data[j].line_count
	line_total = 0
	for i in range((line_count.size() + gMPCollisionLineGroups.size()) / 2):
		gMPCollisionLineGroups[i].line_count = line_count[i]

		line_total += line_count[i]

		if line_count[i] != 0:
			gMPCollisionLineGroups[i].line_id = [] # (u16*) syTaskmanMalloc(line_count[i] * sizeof(u16), 0x2)
			gMPCollisionLineGroups[i].line_id.resize(line_count[i])
			gMPCollisionLineGroups[i].line_id.fill(0)
	return line_total

## 0x800FC1A4
static func mpCollisionInitLineIDsAll() -> void:
	var line_info: MPLineInfo
	var line_data: MPLineData
	var line_count: Array = [0, 0, 0, 0] # s32 line_count[nMPLineKindEnumCount]

	for i in range(line_count.size()):
		line_count[i] = 0

	for i in range(gMPCollisionGeometry.yakumono_count):
		line_info = gMPCollisionGeometry.line_info[i]

		for j in range((line_count.size() + line_info.line_data.size()) / 2):
			line_data = line_info.line_data[j]

			for line_id in range(line_data.group_id, line_data.group_id + line_data.line_count):
				gMPCollisionLineGroups[j].line_id[line_count[j]] = line_id
				line_count[j] += 1

## 0x800FC284
## The ROM read (lbRelocGetFileData of dMPCollisionGroundFileInfos[gkind]) is replaced by the stage
## JSON: port_stage_json (set by load_stage_json) or res://data/ssb64/stages/<key>.json of gkind.
static func mpCollisionInitGroundData() -> void:
	var gdata: MPGeometryData

	gMPCollisionGroundData = _port_lbRelocGetGroundData(G.gSCManagerBattleState.gkind)

	if gMPCollisionGroundData == null:
		_mpCollisionHang("not found cll data!\n")
		return
	gMPCollisionGeometry = gMPCollisionGroundData.map_geometry
	gdata = gMPCollisionGeometry

	if gdata == null:
		_mpCollisionHang("not found cll data!\n")
		return
	gMPCollisionVertexData = gdata.vertex_data
	gMPCollisionVertexIDs = gdata.vertex_id
	gMPCollisionVertexLinks = gdata.vertex_links
	gMPCollisionMapObjs = gdata.mapobjs

	gMPCollisionLinesNum = mpCollisionAllocLinesGetCountTotal()

	mpCollisionInitLineIDsAll()
	mpCollisionAllocVertexInfo()
	func_ovl2_800FB554()
	mpCollisionAllocYakumono(gMPCollisionGroundData.gr_desc[1].dobjdesc)

	gMPCollisionLightColor.r = 0xFF
	gMPCollisionLightColor.g = 0xFF
	gMPCollisionLightColor.b = 0xFF
	gMPCollisionLightColor.a = 0xFF

	gMPCollisionLightAngleX = gMPCollisionGroundData.light_angle.x
	gMPCollisionLightAngleY = gMPCollisionGroundData.light_angle.y

## 0x800FC3E8
static func mpCollisionSetPlayBGM() -> void:
	gMPCollisionBGMDefault = gMPCollisionGroundData.bgm_id

	Audio.syAudioPlayBGM(0, gMPCollisionBGMDefault)

	gMPCollisionBGMCurrent = gMPCollisionBGMDefault

## 0x800FC42C
static func mpCollisionSetBGM() -> void:
	gMPCollisionBGMDefault = gMPCollisionGroundData.bgm_id
	gMPCollisionBGMCurrent = gMPCollisionBGMDefault

## 0x800FC450
static func mpCollisionClearYakumonoAll() -> void:
	var dobjdesc: Array = gMPCollisionGroundData.gr_desc[1].dobjdesc
	var i: int = 0

	while dobjdesc[i].id != DOBJ_ARRAY_MAX:
		_set_user_data_s(gMPCollisionYakumonoDObjs.dobjs[i], nMPYakumonoStatusNone)
		i += 1
	gMPCollisionUpdateTic = 0

## 0x800FC4A8 - line_id is a yakumono (DObj) id here
static func mpCollisionSetYakumonoPosID(line_id: int, yakumono_pos: Vector3) -> void:
	var yakumono_dobj: DObj

	if (line_id == -1) or (line_id == -2):
		_mpCollisionHang("mpSetYakumonoPosId() id = %d\n" % line_id)
		return
	yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[line_id]

	gMPCollisionSpeeds[line_id].x = yakumono_pos.x - yakumono_dobj.translate.x
	gMPCollisionSpeeds[line_id].y = yakumono_pos.y - yakumono_dobj.translate.y
	gMPCollisionSpeeds[line_id].z = yakumono_pos.z - yakumono_dobj.translate.z

	yakumono_dobj.translate.x = yakumono_pos.x
	yakumono_dobj.translate.y = yakumono_pos.y
	yakumono_dobj.translate.z = yakumono_pos.z

## 0x800FC58C - line_id is a yakumono (DObj) id here
static func mpCollisionSetYakumonoOnID(line_id: int) -> void:
	if (line_id == -1) or (line_id == -2):
		_mpCollisionHang("mpSetYakumonoOnId() id = %d\n" % line_id)
		return
	_set_user_data_s(gMPCollisionYakumonoDObjs.dobjs[line_id], nMPYakumonoStatusOn)

## 0x800FC604 - line_id is a yakumono (DObj) id here
static func mpCollisionSetYakumonoOffID(line_id: int) -> void:
	if (line_id == -1) or (line_id == -2):
		_mpCollisionHang("mpSetYakumonoOffId() id = %d\n" % line_id)
		return
	_set_user_data_s(gMPCollisionYakumonoDObjs.dobjs[line_id], nMPYakumonoStatusOff)

## 0x800FC67C
static func mpCollisionCheckExistLineID(line_id: int) -> int:
	if line_id == -1:
		_mpCollisionHang("mpGetExistCollisionId() id = %d\n" % line_id)
		return FALSE
	if line_id == -2:
		return FALSE
	if _user_data_s(gMPCollisionYakumonoDObjs.dobjs[gMPCollisionVertexInfo.vertex_info[line_id].yakumono_id]) < nMPYakumonoStatusOff:
		return TRUE
	return FALSE

## 0x800FC72C
static func mpCollisionSetDObjNoID(line_id: int) -> int:
	if (line_id == -1) or (line_id == -2):
		_mpCollisionHang("mpSetDObjNoId() id = %d\n" % line_id)
		return -1
	return gMPCollisionVertexInfo.vertex_info[line_id].yakumono_id

## 0x800FC7A4
static func mpCollisionGetMapObjCountKind(mapobj_kind: int) -> int:
	var count: int = 0

	if not (gMPCollisionGeometry.mapobj_count):
		return 0
	for i in range(gMPCollisionGeometry.mapobj_count):
		if mapobj_kind == gMPCollisionMapObjs.mapobjs[i].mapobj_kind:
			count += 1
	return count

## 0x800FC814
## C: void mpCollisionGetMapObjIDsKind(s32 mapobj_kind, s32 *mapobjs) -> returns mapobjs.
## Pass an Array to have it filled in place (C array argument); returns that Array (or a new one).
## Callers that pass a single s32 (&mapobj) may pass its int value and get the first ID back
## (the value itself when no map object of this kind exists, i.e. left unwritten like C).
static func mpCollisionGetMapObjIDsKind(mapobj_kind: int, mapobjs = null):
	var out: Array = mapobjs if (mapobjs is Array) else []
	var count: int = 0

	if gMPCollisionGeometry.mapobj_count:
		for i in range(gMPCollisionGeometry.mapobj_count):
			if mapobj_kind == gMPCollisionMapObjs.mapobjs[i].mapobj_kind:
				if count < out.size():
					out[count] = i
				else:
					out.append(i)

				count += 1
	if mapobjs is int:
		return out[0] if (count != 0) else mapobjs
	return out

## 0x800FC894 - mapobj_kind is a map object index here. Returns pos.
static func mpCollisionGetMapObjPositionID(mapobj_kind: int, pos = null) -> Vector3:
	var out_pos := Vector3.ZERO

	out_pos.x = gMPCollisionMapObjs.mapobjs[mapobj_kind].pos.x
	out_pos.y = gMPCollisionMapObjs.mapobjs[mapobj_kind].pos.y
	out_pos.z = 0.0
	return out_pos

## 0x800FC8EC
static func mpCollisionGetLineCountType(line_type: int) -> int:
	return gMPCollisionLineGroups[line_type].line_count

## 0x800FC900
## C: void mpCollisionGetLineIDsTypeCount(s32 type, s32 count, s32 *line_ids) -> returns line_ids
## (a passed Array is filled in place).
static func mpCollisionGetLineIDsTypeCount(type: int, count: int, line_ids = null) -> Array:
	var out: Array = line_ids if (line_ids is Array) else []

	if out.size() < count:
		out.resize(count)
	for i in range(count):
		out[i] = gMPCollisionLineGroups[type].line_id[i]
	return out

## 0x800FC9C8
## gDPSetEnvColor(dls[0]++, r, g, b, a) is display-list (render) work: the render layer reads
## gMPCollisionLightColor itself. Returns the alpha like C.
static func mpCollisionSetLightColorGetAlpha(dls = null) -> int:
	return gMPCollisionLightColor.a

## 0x800FCA18
static func mpCollisionCheckExistPlatformLineID(line_id: int) -> int:
	var yakumono_dobj: DObj

	if (line_id == -1) or (line_id == -2):
		_mpCollisionHang("mpGetCllFloatId() id = %d\n" % line_id)
		return FALSE
	yakumono_dobj = gMPCollisionYakumonoDObjs.dobjs[gMPCollisionVertexInfo.vertex_info[line_id].yakumono_id]

	if (_user_data_s(yakumono_dobj) != nMPYakumonoStatusNone) or _has_anim_joint(yakumono_dobj):
		return TRUE
	return FALSE

## 0x800FCAC8
static func mpCollisionGetVertexFlagsLineID(line_id: int) -> int:
	if (line_id == -1) or (line_id == -2):
		_mpCollisionHang("mpGetAttrId() id = %d\n" % line_id)
		return 0
	return gMPCollisionVertexData.vpos[gMPCollisionVertexIDs.vertex_id[gMPCollisionVertexLinks[line_id].vertex1]].vertex_flags

# // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //
#   PORT-ONLY: stage JSON loading (replaces the ROM relocData read of the map file)
# // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

## Entry point: initialise the map collision from an exported stage JSON (see schema above).
## 1. mpCollisionInitGroundData() on `data` (sets gSCManagerBattleState->gkind = data.gr_kind_value):
##    vertex data/ids/links, line info, line groups, vertex info (bounds, types, edge links),
##    yakumono arrays (dobjs/speeds), map objects, light angles, gMPCollisionGroundData.
## 2. make_yakumono_layer: the collision part of grCommonSetupInitAll for layer 1 - builds the
##    layer-1 ground GObj and its yakumono DObjs exactly like grDisplayMakeGeometryLayer(&gr_desc[1],
##    1, gMPCollisionYakumonoDObjs->dobjs) (DObj tree, AnimJoints, process mpCollisionPlayYakumonoAnim
##    or mpCollisionAdvanceUpdateTic at priority 4, initial gcPlayAnimAll), then
##    mpCollisionClearYakumonoAll(), proc_make_ground (e.g. Grmainsetup.grMainSetupMakeGround) and
##    mpCollisionInitYakumonoAll() (gMPCollisionBounds).
##    Pass false when the ported gr code (Grcommonsetup.grCommonSetupInitAll) builds the layers.
static func load_stage_json(data: Dictionary, make_yakumono_layer: bool = true, proc_make_ground: Callable = Callable()) -> void:
	port_stage_json = data
	G.gSCManagerBattleState.gkind = int(data.gr_kind_value)

	mpCollisionInitGroundData()

	if make_yakumono_layer:
		if port_yakumono_layer_gobj != null:
			Objman.gcEjectGObj(port_yakumono_layer_gobj)
		port_yakumono_layer_gobj = _port_make_yakumono_layer()

		mpCollisionClearYakumonoAll()
		if proc_make_ground.is_valid():
			proc_make_ground.call()
		mpCollisionInitYakumonoAll()

## Read res://data/ssb64/stages/<key>.json (empty Dictionary when missing).
static func port_read_stage_json(key: String) -> Dictionary:
	var path := STAGE_JSON_DIR + key + ".json"

	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))

	if parsed is Dictionary:
		return parsed
	return {}

## lbRelocGetFileData(MPGroundData*, lbRelocGetExternHeapFile(dMPCollisionGroundFileInfos[gkind].file_id, ...), offset)
static func _port_lbRelocGetGroundData(gkind: int):
	var data: Dictionary = port_stage_json

	if data.is_empty() or (int(data.get("gr_kind_value", -1)) != gkind):
		data = {}

		if (gkind >= 0) and (gkind < dMPCollisionGroundFileInfos.size()) and (dMPCollisionGroundFileInfos[gkind].key != ""):
			data = port_read_stage_json(dMPCollisionGroundFileInfos[gkind].key)
		if data.is_empty():
			return null
		port_stage_json = data
	return _port_make_ground_data(data)

static func _port_vec3(v) -> Vector3:
	if v == null:
		return Vector3.ZERO
	if v is Array:
		return Vector3(float(v[0]), float(v[1]), float(v[2]))
	return Vector3(float(v.x), float(v.y), float(v.z))

static func _port_rgb(c) -> Dictionary:
	return {"r": int(c.r), "g": int(c.g), "b": int(c.b)}

## MPGroundData from the stage JSON (fresh objects, like loading the file into a new heap).
static func _port_make_ground_data(data: Dictionary) -> Dictionary:
	var gd: Dictionary = data.ground_data
	var ground := {}
	var gr_desc := []

	for i in 4:
		var src: Dictionary = gd.gr_desc[i]

		gr_desc.append({
			"dobjdesc": src.get("dobjdesc"),
			"anim_joints": src.get("anim_joints"),
			"p_mobjsubs": src.get("p_mobjsubs"),
			"p_matanim_joints": src.get("p_matanim_joints"),
		})
	# Layer 1 (yakumono / collision layer): decoded DObjDesc list and AnimJoint table.
	if gr_desc[1].dobjdesc != null:
		gr_desc[1]["dobjdesc_ref"] = gr_desc[1].dobjdesc
		gr_desc[1].dobjdesc = _port_make_dobjdescs(data.get("yakumono", []))
	if gr_desc[1].anim_joints != null:
		gr_desc[1]["anim_joints_ref"] = gr_desc[1].anim_joints
		gr_desc[1].anim_joints = _port_make_anim_joints(data.get("yakumono", []))

	ground.gr_desc = gr_desc
	ground.map_geometry = _port_make_geometry(data.geometry) if (gd.get("map_geometry") != null) else null
	ground.layer_mask = int(gd.layer_mask)
	ground.wallpaper = gd.get("wallpaper")
	ground.fog_color = _port_rgb(gd.fog_color)
	ground.fog_alpha = int(gd.fog_alpha)
	ground.emblem_colors = []
	for c in gd.emblem_colors:
		ground.emblem_colors.append(_port_rgb(c))
	ground.unused = int(gd.unused)
	ground.light_angle = _port_vec3(gd.light_angle)
	ground.camera_bound_top = int(gd.camera_bound_top)
	ground.camera_bound_bottom = int(gd.camera_bound_bottom)
	ground.camera_bound_right = int(gd.camera_bound_right)
	ground.camera_bound_left = int(gd.camera_bound_left)
	ground.map_bound_top = int(gd.map_bound_top)
	ground.map_bound_bottom = int(gd.map_bound_bottom)
	ground.map_bound_right = int(gd.map_bound_right)
	ground.map_bound_left = int(gd.map_bound_left)
	ground.bgm_id = int(gd.bgm_id)
	ground.map_nodes = gd.get("map_nodes")
	if gd.get("item_weights") != null:
		var values := []
		for w in gd.get("item_weights_values", []):
			values.append(int(w))
		ground.item_weights = {"values": values, "ref": gd.item_weights}
	else:
		ground.item_weights = null
	ground.alt_warning = int(gd.alt_warning)
	ground.camera_bound_team_top = int(gd.camera_bound_team_top)
	ground.camera_bound_team_bottom = int(gd.camera_bound_team_bottom)
	ground.camera_bound_team_right = int(gd.camera_bound_team_right)
	ground.camera_bound_team_left = int(gd.camera_bound_team_left)
	ground.map_bound_team_top = int(gd.map_bound_team_top)
	ground.map_bound_team_bottom = int(gd.map_bound_team_bottom)
	ground.map_bound_team_right = int(gd.map_bound_team_right)
	ground.map_bound_team_left = int(gd.map_bound_team_left)
	ground.zoom_start = _port_vec3(gd.zoom_start)
	ground.zoom_end = _port_vec3(gd.zoom_end)
	return ground

## MPGeometryData (+ the arrays it points to) from geometry.*
static func _port_make_geometry(geo: Dictionary) -> MPGeometryData:
	var gdata := MPGeometryData.new()

	gdata.yakumono_count = int(geo.yakumono_count)

	gdata.vertex_data = MPVertexPosContainer.new()
	for v in geo.vertex_data:
		var vd := MPVertexData.new()
		vd.pos = Vector2i(int(v.pos.x), int(v.pos.y))
		vd.vertex_flags = int(v.vertex_flags) & 0xFFFF
		gdata.vertex_data.vpos.append(vd)

	gdata.vertex_id = MPVertexArray.new()
	var ids := PackedInt32Array()
	for k in geo.vertex_id:
		ids.append(int(k) & 0xFFFF)
	# Two zero halfwords of padding: pv[1] of the last vertex of a non-monotonic last line
	# reads past the array in C (never happens with the shipped stages).
	ids.append(0)
	ids.append(0)
	gdata.vertex_id.vertex_id = ids

	for vl in geo.vertex_links:
		var links := MPVertexLinks.new()
		links.vertex1 = int(vl.vertex1)
		links.vertex2 = int(vl.vertex2)
		gdata.vertex_links.append(links)

	for li in geo.line_info:
		var info := MPLineInfo.new()
		info.yakumono_id = int(li.yakumono_id)
		for ld in li.line_data:
			var line_data := MPLineData.new()
			line_data.group_id = int(ld.group_id)
			line_data.line_count = int(ld.line_count)
			info.line_data.append(line_data)
		gdata.line_info.append(info)

	gdata.mapobj_count = int(geo.mapobj_count)
	gdata.mapobjs = MPMapObjContainer.new()
	for m in geo.get("mapobjs", []):
		var mapobj := MPMapObjData.new()
		mapobj.mapobj_kind = int(m.mapobj_kind)
		mapobj.pos = Vector2i(int(m.pos.x), int(m.pos.y))
		gdata.mapobjs.mapobjs.append(mapobj)
	return gdata

## gr_desc[1].dobjdesc: DObjDesc[] {id, dl, translate, rotate, scale} + {id: DOBJ_ARRAY_MAX} terminator.
static func _port_make_dobjdescs(yakumono: Array) -> Array:
	var descs := []

	for y in yakumono:
		var src: Dictionary = y.dobjdesc
		descs.append({
			"id": int(src.id),
			"dl": src.get("dl"),
			"translate": _port_vec3(src.translate),
			"rotate": _port_vec3(src.rotate),
			"scale": _port_vec3(src.scale),
		})
	descs.append({"id": DOBJ_ARRAY_MAX, "dl": null, "translate": Vector3.ZERO, "rotate": Vector3.ZERO, "scale": Vector3.ZERO})
	return descs

static func _port_hex_u32(s: String) -> int:
	return s.hex_to_int() & 0xFFFFFFFF

## gr_desc[1].anim_joints: AObjEvent32* per DObjDesc (AnimStream rebuilt from the exported raw
## command words; SetAnim/Jump pointers resolved to stream positions). Render-only joints whose
## streams were not exported get NULL.
static func _port_make_anim_joints(yakumono: Array) -> Array:
	var anim_joints := []

	for y in yakumono:
		var anim = y.get("animation")

		if (y.get("anim_joint") == null) or (anim == null) or not (anim is Dictionary):
			anim_joints.append(null)
			continue
		var streams: Array = []
		var starts: Array = []       # [file_id, offset] of each stream
		var pending: Array = []      # [stream_index, word_index, file_id, target_offset]

		for st in anim.streams:
			var words: Array = []
			var stream_index: int = streams.size()
			var file_id: int = int(st.get("file_id", -1))

			for ev in st.events:
				var raw: Array = ev.raw
				var tgt = ev.get("target")

				if (tgt != null) and (ev.name == "SetAnim" or ev.name == "Jump") and (raw.size() >= 2):
					pending.append([stream_index, words.size() + 1, int(tgt.get("file_id", file_id)), str(tgt.offset).hex_to_int()])
				for w in raw:
					words.append(_port_hex_u32(str(w)))
			streams.append(AnimStream.from_u32(words, "%s:%s" % [str(y.yakumono_id), str(st.offset)]))
			starts.append([file_id, str(st.offset).hex_to_int()])
		for p in pending:
			for s in range(streams.size()):
				var stream_start: int = starts[s][1]
				var stream_end: int = stream_start + 4 * streams[s].u.size()

				if ((starts[s][0] == p[2]) or (starts[s][0] == -1)) and (p[3] >= stream_start) and (p[3] < stream_end):
					streams[p[0]].ptr[p[1]] = [streams[s], (p[3] - stream_start) / 4]
					break
		var head: AnimStream = null
		var aj_offset: int = str(y.anim_joint.offset).hex_to_int()

		for s in range(streams.size()):
			if starts[s][1] == aj_offset:
				head = streams[s]
				break
		if (head == null) and (streams.size() != 0):
			head = streams[0]
		anim_joints.append(head)
	return anim_joints

## grDisplayMakeGeometryLayer(&gMPCollisionGroundData->gr_desc[1], 1, gMPCollisionYakumonoDObjs->dobjs)
## restricted to what collision needs. Render-only parts (gcAddGObjDisplay with
## grDisplayLayer1Pri/SecProcDisplay, DObj matrix kinds, MObjs, grDisplayDObjSetNoAnimXObj) are
## left to the render layer / the gr port so this file does not depend on Grdisplay.
static func _port_make_yakumono_layer():
	var gr_desc: Dictionary = gMPCollisionGroundData.gr_desc[1]
	var ground_gobj

	if gr_desc.dobjdesc == null:
		return null
	ground_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindGroundDisplay, null, nGCCommonLinkIDGroundDisplay, GOBJ_PRIORITY_DEFAULT)
	ground_gobj.debug_name = "GroundLayer1"

	_port_gcSetupCustomDObjs(ground_gobj, gr_desc.dobjdesc, gMPCollisionYakumonoDObjs.dobjs)

	if (gr_desc.anim_joints != null) or (gr_desc.p_matanim_joints != null):
		_port_gcAddAnimAll(ground_gobj, gr_desc.anim_joints, 0.0)
		Objman.gcAddGObjProcess(ground_gobj, Callable(Mpcollision, &"mpCollisionPlayYakumonoAnim"), nGCProcessKindFunc, 4)
		ObjAnim.gcPlayAnimAll(ground_gobj)
	else:
		Objman.gcAddGObjProcess(ground_gobj, Callable(Mpcollision, &"mpCollisionAdvanceUpdateTic"), nGCProcessKindFunc, 4)
	return ground_gobj

## gcSetupCustomDObjs (objanim.c): DObj tree from a depth-coded DObjDesc list; *dobjs++ = dobj.
static func _port_gcSetupCustomDObjs(gobj, dobjdesc: Array, dobjs) -> void:
	var array_dobjs: Array = []
	var desc_index: int = 0

	array_dobjs.resize(DOBJ_ARRAY_MAX)

	while dobjdesc[desc_index].id != DOBJ_ARRAY_MAX:
		var desc: Dictionary = dobjdesc[desc_index]
		var id: int = desc.id & 0xFFF
		var dobj: DObj

		if id != 0:
			dobj = Objman.gcAddChildForDObj(array_dobjs[id - 1], desc.dl)
			array_dobjs[id] = dobj
		else:
			dobj = Objman.gcAddDObjForGObj(gobj, desc.dl)
			array_dobjs[0] = dobj
		# gcDecideDObj3TransformsKind / gcAddDObj3TransformsKind: matrix kinds (render-only)
		dobj.translate = desc.translate
		dobj.rotate = desc.rotate
		dobj.scale = desc.scale

		if dobjs != null:
			dobjs[desc_index] = dobj
		desc_index += 1

## gcAddAnimAll (objanim.c), joint part (MObj material animations are render-side).
static func _port_gcAddAnimAll(gobj, anim_joints, anim_frame: float) -> void:
	var dobj: DObj = DObjGetStruct(gobj)
	var is_anim_root: bool = true
	var joint_index: int = 0

	gobj.anim_frame = anim_frame

	while dobj != null:
		if anim_joints != null:
			var anim_joint = anim_joints[joint_index] if (joint_index < anim_joints.size()) else null

			if anim_joint != null:
				ObjAnim.gcAddDObjAnimJoint(dobj, anim_joint, anim_frame)
				dobj.is_anim_root = is_anim_root
				is_anim_root = false
			else:
				dobj.anim_wait = AOBJ_ANIM_NULL
				dobj.is_anim_root = false
			joint_index += 1
		dobj = ObjAnim.gcGetTreeDObjNext(dobj)
