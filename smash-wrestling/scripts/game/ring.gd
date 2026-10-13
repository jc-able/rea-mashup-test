class_name Ring
extends RefCounted
## Ring / arena geometry used by the gameplay code (metres, ring centre at the origin, arena floor at y = 0).
## Defaults are blockout values; Arena.apply_layout() overwrites them from the recovered SvR arena layout JSON.
## MAT_Y default 1.10 is consistent with the SvR ring-out motions (standing hips end ~1.1 m below the mat).

static var MAT_Y := 1.10          # mat top above the arena floor
static var HALF := 3.0            # half size of the ring at the rope line
static var APRON := 0.55          # apron width outside the ropes
static var ROPE_Y := [0.55, 0.95, 1.35]   # rope heights above the mat
static var POST_HALF := 3.15       # post centre distance from the centre (each axis)
static var POST_TOP := 1.55        # top turnbuckle height above the mat
static var BARRICADE := 7.2        # barricade half extent (floor area, x)
static var BARRICADE_NEAR_Z := 9.15   # camera-side barricade line
static var BARRICADE_FAR_Z := -9.3    # stage-side barricade line (ramp gap in the middle)
static var RAMP_GAP := 2.2
static var RAMP_PROFILE: Array = []   # [[z, y], ...] (recovered ramp profile, scaled)
static var STAGE_Z := -26.0        # entrance stage position (z) - the ramp runs along -Z
static var STAGE_Y := 1.2
static var RAMP_W := 3.2
static var STEPS := Vector3(3.9, 0.0, 3.9)  # ring steps corner (x, -, z)
static var MOVE_SCALE := 1.0       # extra scale applied to the arena model (unit reconciliation)

const WALL_MARGIN := 0.45


static func inside(p: Vector3) -> bool:
	return absf(p.x) < HALF and absf(p.z) < HALF and p.y > MAT_Y - 0.6


static func clamp_inside(p: Vector3, r: float = WALL_MARGIN) -> Vector3:
	var lim := HALF - r
	return Vector3(clampf(p.x, -lim, lim), p.y, clampf(p.z, -lim, lim))


static func clamp_outside(p: Vector3, r: float = 0.35) -> Vector3:
	# keep out of the ring + apron, inside the barricade
	var inner := HALF + APRON + r
	var q := Vector3(clampf(p.x, -BARRICADE + r, BARRICADE - r), p.y, clampf(p.z, BARRICADE_FAR_Z + r, BARRICADE_NEAR_Z - r))
	if absf(q.x) < inner and absf(q.z) < inner:
		if inner - absf(q.x) < inner - absf(q.z):
			q.x = signf(q.x) * inner
		else:
			q.z = signf(q.z) * inner
	return q


## Distance from p to the nearest rope line (inside the ring) and the outward normal of that side.
static func nearest_rope(p: Vector3) -> Array:
	var dx := HALF - absf(p.x)
	var dz := HALF - absf(p.z)
	if dx < dz:
		return [dx, Vector3(signf(p.x), 0, 0)]
	return [dz, Vector3(0, 0, signf(p.z))]


static func corners() -> Array:
	var c := POST_HALF - 0.45
	return [Vector3(c, MAT_Y, c), Vector3(-c, MAT_Y, c), Vector3(c, MAT_Y, -c), Vector3(-c, MAT_Y, -c)]


static func nearest_corner(p: Vector3) -> Vector3:
	var best := Vector3.ZERO
	var bd := 1e9
	for c in corners():
		var d := Vector2(p.x - c.x, p.z - c.z).length()
		if d < bd:
			bd = d
			best = c
	return best


static func corner_distance(p: Vector3) -> float:
	var c := nearest_corner(p)
	return Vector2(p.x - c.x, p.z - c.z).length()


static func floor_y(p: Vector3) -> float:
	return MAT_Y if (absf(p.x) < HALF + APRON * 0.5 and absf(p.z) < HALF + APRON * 0.5) else 0.0


## Height of the entrance ramp / stage floor at z (recovered profile; 0 on the arena floor).
static func ramp_y(z: float) -> float:
	if RAMP_PROFILE.is_empty():
		return clampf(remap(z, -BARRICADE, STAGE_Z, 0.0, STAGE_Y), 0.0, STAGE_Y)
	if z >= float(RAMP_PROFILE[0][0]):
		return float(RAMP_PROFILE[0][1])
	for i in range(1, RAMP_PROFILE.size()):
		var a: Array = RAMP_PROFILE[i - 1]
		var b: Array = RAMP_PROFILE[i]
		if z >= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (z - float(a[0])) / (float(b[0]) - float(a[0])))
	return float(RAMP_PROFILE[RAMP_PROFILE.size() - 1][1])
