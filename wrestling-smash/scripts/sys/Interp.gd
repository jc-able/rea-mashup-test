## 1:1 port of src/sys/interp.c (ssb-decomp-re): spline interpolation used by animation TraI
## tracks (e.g. Samus RollF/RollB root motion) and stage paths (Sector Z Arwings).
## SYInterpDesc is a Dictionary: {kind, points_num, unk04, length, points: Array[Vector3],
## keyframes: Array[float], quartics: Array[float]} (see SSBData / Grdisplay.grDisplayGetInterpDesc).
## Functions that write `Vec3f *out` return the new value (PORTING.md out-parameter convention);
## `ctrl` arrays are passed as (points, base_index).
class_name Interp
extends Port

static func _pt(points: Array, i: int) -> Vector3:
	return points[i] if (i >= 0 and i < points.size()) else Vector3.ZERO

## Catmull-Rom cubic spline
static func syInterpCatromCubicSpline(points = null, b = 0, s = 0.0, t = 0.0):
	var sqt: float = t * t
	var cbt: float = sqt * t
	var w0: float = (2.0 * sqt - cbt - t) * s
	var w1: float = (2.0 - s) * cbt + (s - 3.0) * sqt + 1.0
	var w2: float = (s - 2.0) * cbt + (3.0 - 2.0 * s) * sqt + s * t
	var w3: float = (cbt - sqt) * s
	var c0 := _pt(points, b)
	var c1 := _pt(points, b + 1)
	var c2 := _pt(points, b + 2)
	var c3 := _pt(points, b + 3)
	return Vector3(c0.x * w0 + c1.x * w1 + c2.x * w2 + c3.x * w3, c0.y * w0 + c1.y * w1 + c2.y * w2 + c3.y * w3, c0.z * w0 + c1.z * w1 + c2.z * w2 + c3.z * w3)

## quadratic spline (derivative of the Catmull-Rom spline)
static func syInterpQuadSpline(points = null, b = 0, s = 0.0, t = 0.0):
	var sqt: float = t * t
	var w0: float = ((((-3.0) * sqt) + (4.0 * t)) - 1.0) * s
	var temp: float = s - 3.0
	var w3: float = s
	var w1: float = (((2.0 - w3) * 3.0) * sqt) + ((2.0 * temp) * t)
	temp = 3.0 - (2.0 * w3)
	var w2: float = ((((w3 - 2.0) * 3.0) * sqt) + ((2.0 * temp) * t)) + w3
	w3 = ((3.0 * sqt) - (2.0 * t)) * w3
	var c0 := _pt(points, b)
	var c1 := _pt(points, b + 1)
	var c2 := _pt(points, b + 2)
	var c3 := _pt(points, b + 3)
	return Vector3((c0.x * w0) + (c1.x * w1) + (c2.x * w2) + (c3.x * w3), (c0.y * w0) + (c1.y * w1) + (c2.y * w2) + (c3.y * w3), (c0.z * w0) + (c1.z * w1) + (c2.z * w2) + (c3.z * w3))

static func syInterpBezier3Points(points = null, b = 0, t = 0.0):
	var subt: float = 1.0 - t
	var sqt: float = t * t
	var cbt: float = sqt * t
	var w0: float = (1.0 / 6.0) * subt * subt * subt
	var w1: float = (1.0 / 6.0) * (3.0 * cbt - 6.0 * sqt + 4.0)
	var w2: float = (1.0 / 6.0) * (3.0 * (sqt - cbt + t) + 1.0)
	var w3: float = (1.0 / 6.0) * cbt
	var c0 := _pt(points, b)
	var c1 := _pt(points, b + 1)
	var c2 := _pt(points, b + 2)
	var c3 := _pt(points, b + 3)
	return Vector3(c0.x * w0 + c1.x * w1 + c2.x * w2 + c3.x * w3, c0.y * w0 + c1.y * w1 + c2.y * w2 + c3.y * w3, c0.z * w0 + c1.z * w1 + c2.z * w2 + c3.z * w3)

static func syInterpBezier4Points(points = null, b = 0, t = 0.0):
	var sqt: float = t * t
	var w0: float = 1.0 - t
	var w3: float = -0.5 * w0 * w0
	var mt: float = ((3.0 * sqt) - (4.0 * t)) * 0.5
	var w1: float = ((-3.0 * sqt) + (2.0 * t) + 1.0) * 0.5
	var w2: float = 0.5 * sqt
	var c0 := _pt(points, b)
	var c1 := _pt(points, b + 1)
	var c2 := _pt(points, b + 2)
	var c3 := _pt(points, b + 3)
	return Vector3((c0.x * w3) + (c1.x * mt) + (c2.x * w1) + (c3.x * w2), (c0.y * w3) + (c1.y * mt) + (c2.y * w1) + (c3.y * w2), (c0.z * w3) + (c1.z * mt) + (c2.z * w1) + (c3.z * w2))

static func syInterpCubicBezierScale(points = null, b = 0, t = 0.0):
	var subt: float = 1.0 - t
	var sqt: float = t * t
	var sqsubt: float = subt * subt
	var w0: float = sqsubt * subt
	var w1: float = 3.0 * t * sqsubt
	var w2: float = 3.0 * sqt * subt
	var w3: float = sqt * t
	var c0 := _pt(points, b)
	var c1 := _pt(points, b + 1)
	var c2 := _pt(points, b + 2)
	var c3 := _pt(points, b + 3)
	return Vector3(c0.x * w0 + c1.x * w1 + c2.x * w2 + c3.x * w3, c0.y * w0 + c1.y * w1 + c2.y * w2 + c3.y * w3, c0.z * w0 + c1.z * w1 + c2.z * w2 + c3.z * w3)

static func syInterpQuadBezier4Points(points = null, b = 0, t = 0.0):
	var mt: float = t - 1.0
	var w3: float = -3.0 * mt * mt
	var w0: float = t * t
	w0 = 3.0 * w0
	var w1: float = ((1.0 - (4.0 * t)) + w0) * 3.0
	var w2: float = ((2.0 * t) - w0) * 3.0
	var c0 := _pt(points, b)
	var c1 := _pt(points, b + 1)
	var c2 := _pt(points, b + 2)
	var c3 := _pt(points, b + 3)
	return Vector3((c0.x * w3) + (c1.x * w1) + (c2.x * w2) + (c3.x * w0), (c0.y * w3) + (c1.y * w1) + (c2.y * w2) + (c3.y * w0), (c0.z * w3) + (c1.z * w1) + (c2.z * w2) + (c3.z * w0))

## out is in-out: returned unchanged when t is outside [0, 1] (C returns without writing).
static func syInterpCubicSplineTimeFrac(out = null, desc = null, t = 0.0):
	var points: Array = desc.points
	var target_frame: int
	if (t < 0.0) or (t > 1.0):
		return out
	elif t < 1.0:
		t *= float(desc.points_num - 1)
		target_frame = int(t)
		t -= target_frame
		match desc.kind:
			nSYInterpKindLinear:
				var p0 := _pt(points, target_frame)
				var p1 := _pt(points, target_frame + 1)
				return Vector3((p1.x - p0.x) * t + p0.x, (p1.y - p0.y) * t + p0.y, (p1.z - p0.z) * t + p0.z)
			nSYInterpKindBezierS3:
				return syInterpCubicBezierScale(points, target_frame * 3, t)
			nSYInterpKindBezier:
				return syInterpBezier3Points(points, target_frame, t)
			nSYInterpKindCatrom:
				return syInterpCatromCubicSpline(points, target_frame, desc.unk04, t)
	else:
		target_frame = desc.points_num - 1
		match desc.kind:
			nSYInterpKindLinear:
				return _pt(points, target_frame)
			nSYInterpKindBezierS3:
				return _pt(points, target_frame * 3)
			nSYInterpKindBezier:
				return syInterpBezier3Points(points, target_frame - 1, 1.0)
			nSYInterpKindCatrom:
				return _pt(points, target_frame + 1)
	return out

static func syInterpQuadSplineTimeFrac(out = null, desc = null, t = 0.0):
	var points: Array = desc.points
	if (t < 0.0) or (t > 1.0):
		return out
	var t_origin: float = t
	t *= float(desc.points_num - 1)
	var target_frame: int = int(t)
	t = t - float(target_frame)
	match desc.kind:
		nSYInterpKindLinear:
			if t_origin == 1.0:
				target_frame -= 1
			var p0 := _pt(points, target_frame)
			var p1 := _pt(points, target_frame + 1)
			return Vector3(p1.x - p0.x, p1.y - p0.y, p1.z - p0.z)
		nSYInterpKindBezierS3:
			return syInterpQuadBezier4Points(points, target_frame * 3, t)
		nSYInterpKindBezier:
			return syInterpBezier4Points(points, target_frame, t)
		nSYInterpKindCatrom:
			return syInterpQuadSpline(points, target_frame, desc.unk04, t)
	return out

## sqrt of the quartic polynomial cof[b..b+4] at x
static func syInterpGetQuartSum(x = 0.0, cof = null, b = 0):
	var sum: float = cof[b] * (x * x * x * x) + cof[b + 1] * (x * x * x) + cof[b + 2] * (x * x) + cof[b + 3] * x + cof[b + 4]
	if (sum < 0.0) and (sum > -0.001):
		sum = 0.0
	return sqrtf(sum)

## Simpson's-rule arc length of the quartic segment between t and f
static func syInterpGetCubicIntegralApprox(t = 0.0, f = 0.0, cof = null, b = 0):
	var factor: float = (f - t) / 8
	var sum: float = 0.0
	var time_scale: float = t + factor
	for i in range(2, 9):
		if not (i & 1):
			sum += 4.0 * syInterpGetQuartSum(time_scale, cof, b)
		else:
			sum += 2.0 * syInterpGetQuartSum(time_scale, cof, b)
		time_scale += factor
	return ((syInterpGetQuartSum(t, cof, b) + sum + syInterpGetQuartSum(f, cof, b)) * factor) / 3.0

static func syInterpGetFracFrame(desc = null, t = 0.0):
	var keyframes: Array = desc.keyframes
	var id := 0
	var frac_frame: float = 0.0
	var min_: float = 0.0
	var max_: float = 1.0
	var res: float
	var diff: float
	var time_scale: float
	# C: while (point[1] < t) { id++; point++; } (bounded here)
	while (id + 1 < keyframes.size()) and (keyframes[id + 1] < t):
		id += 1
	match desc.kind:
		nSYInterpKindLinear:
			frac_frame = (t - keyframes[id]) / (keyframes[id + 1] - keyframes[id])
		nSYInterpKindBezierS3, nSYInterpKindBezier, nSYInterpKindCatrom:
			time_scale = (t - keyframes[id]) * desc.length
			while true:
				frac_frame = (min_ + max_) / 2.0
				res = syInterpGetCubicIntegralApprox(min_, frac_frame, desc.quartics, id * 5)
				if time_scale < (res + 0.00001):
					max_ = frac_frame
				else:
					min_ = frac_frame
					time_scale -= res
				diff = -(min_ - max_) if (min_ < max_) else min_ - max_
				if diff < 0.00001:
					break
				if not (((res + 0.00001) < time_scale) or (time_scale < (res - 0.00001))):
					break
	return (float(id) + frac_frame) / (float(desc.points_num) - 1.0)

## void syInterpCubic(Vec3f *out, SYInterpDesc *desc, f32 t) -> returns the new out
static func syInterpCubic(out = null, desc = null, t = 0.0):
	return syInterpCubicSplineTimeFrac(out, desc, syInterpGetFracFrame(desc, t))

## void syInterpQuad(Vec3f *out, SYInterpDesc *desc, f32 t) -> returns the new out
static func syInterpQuad(out = null, desc = null, t = 0.0):
	return syInterpQuadSplineTimeFrac(out, desc, syInterpGetFracFrame(desc, t))
