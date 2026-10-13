## Lightweight visual particles (one MultiMesh of camera-facing quads): fed by Ftparam.effect_hook
## (dust, sparks, flashes, fire, shock...) and by hit detection on the fighters (percent increase ->
## hit spark at the damaged joint). Purely visual: never calls game code that changes state and uses
## its own RNG (never the game's syUtilsRand*).
extends Node3D

const RU = preload("res://scripts/render/RenderUtil.gd")
const MAX_P := 384

const SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
varying vec4 cdata;
varying vec4 col;
void vertex() {
	cdata = INSTANCE_CUSTOM;
	col = COLOR;
	// camera-facing quad scaled by the instance basis length
	float s = length(MODEL_MATRIX[0].xyz);
	vec3 center = MODEL_MATRIX[3].xyz;
	vec3 right = INV_VIEW_MATRIX[0].xyz;
	vec3 up = INV_VIEW_MATRIX[1].xyz;
	float a = cdata.z;
	vec2 v = vec2(VERTEX.x * cos(a) - VERTEX.y * sin(a), VERTEX.x * sin(a) + VERTEX.y * cos(a));
	vec3 world = center + (right * v.x + up * v.y) * s;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float shape = cdata.y;
	float a;
	if (shape < 0.5) {            // soft puff
		a = smoothstep(1.0, 0.0, r);
	} else if (shape < 1.5) {     // spark star
		float ang = atan(p.y, p.x);
		float star = 0.35 + 0.65 * pow(abs(cos(ang * 2.0)), 6.0);
		a = smoothstep(star, star * 0.2, r);
	} else {                      // ring
		a = smoothstep(0.18, 0.0, abs(r - 0.78));
	}
	float life = cdata.x;
	ALBEDO = col.rgb * col.a * a * life;
	ALPHA = 1.0;
}
"""

class P:
	var pos: Vector3
	var vel: Vector3
	var life: float
	var max_life: float
	var size: float
	var grow: float
	var color: Color
	var shape: float
	var rot: float
	var spin: float
	var gravity: float

var mm: MultiMesh
var mmi: MultiMeshInstance3D
var parts: Array = []
var rng := RandomNumberGenerator.new()
var shake := 0.0
var _prev_damage: Dictionary = {}

func _ready() -> void:
	rng.seed = 12345
	mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	mm.mesh = q
	mm.instance_count = MAX_P
	mm.visible_instance_count = 0
	mmi = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SHADER
	mat.shader = sh
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.extra_cull_margin = 16384.0
	add_child(mmi)

## Ftparam.effect_hook target: (fighter_gobj, effect_id, joint_id, world_pos, scatter, lr, flag)
func on_fighter_effect(fighter_gobj, effect_id: int, _joint_id: int, pos: Vector3, _scatter, lr: int, _flag) -> void:
	var p := pos * RU.S
	var dir := float(lr) if lr != 0 else 1.0
	match effect_id:
		SSBDefs.nEFKindDustLight, SSBDefs.nEFKindDustLightRapid, SSBDefs.nEFKindDustDashSmall:
			_burst(p, 4, Color(0.85, 0.8, 0.72, 0.5), 0, 0.35, 0.45, Vector3(-dir * 0.8, 0.5, 0), 0.6, 0.3)
		SSBDefs.nEFKindDustHeavy, SSBDefs.nEFKindDustHeavyReverse, SSBDefs.nEFKindDustHeavyDouble, SSBDefs.nEFKindDustHeavyDoubleRapid, SSBDefs.nEFKindDustDashLarge:
			_burst(p, 7, Color(0.85, 0.8, 0.72, 0.55), 0, 0.5, 0.55, Vector3(-dir * 1.2, 0.6, 0), 1.0, 0.2)
		SSBDefs.nEFKindDustExpandSmall, SSBDefs.nEFKindDustExpandLarge:
			_burst(p, 8, Color(0.9, 0.88, 0.8, 0.5), 0, 0.55, 0.6, Vector3.ZERO, 1.6, 0.0)
		SSBDefs.nEFKindDamageNormal, SSBDefs.nEFKindDamageFlySparks, SSBDefs.nEFKindDamageFlySparksReverse:
			_burst(p, 3, Color(1.0, 0.9, 0.55, 0.9), 1, 0.25, 0.4, Vector3.ZERO, 1.5, 0.0)
		SSBDefs.nEFKindDamageFlyOrbs, SSBDefs.nEFKindDamageFlyMDust, SSBDefs.nEFKindDamageFlyMDustReverse:
			_burst(p, 2, Color(0.95, 0.95, 1.0, 0.6), 0, 0.3, 0.35, Vector3.ZERO, 0.6, 0.0)
		SSBDefs.nEFKindFlameLR, SSBDefs.nEFKindFlameRandom, SSBDefs.nEFKindFlameStatic, SSBDefs.nEFKindFireSpark:
			_burst(p, 3, Color(1.0, 0.5, 0.15, 0.8), 0, 0.35, 0.45, Vector3(0, 1.2, 0), 0.6, -0.5)
		SSBDefs.nEFKindShockSmall, SSBDefs.nEFKindThunderAmp:
			_burst(p, 4, Color(1.0, 1.0, 0.45, 0.9), 1, 0.3, 0.25, Vector3.ZERO, 2.0, 0.0)
		SSBDefs.nEFKindImpactWave:
			_spawn(p, Vector3.ZERO, 0.4, 0.4, 3.0, Color(1, 1, 1, 0.6), 2, 0.0)
		SSBDefs.nEFKindFlashSmall:
			_spawn(p, Vector3.ZERO, 0.18, 0.6, 1.0, Color(1, 1, 0.9, 0.9), 1, 0.0)
		SSBDefs.nEFKindFlashMiddle:
			_spawn(p, Vector3.ZERO, 0.22, 1.0, 1.5, Color(1, 1, 0.9, 0.9), 1, 0.0)
		SSBDefs.nEFKindFlashLarge:
			_spawn(p, Vector3.ZERO, 0.3, 1.6, 2.0, Color(1, 1, 0.9, 0.9), 1, 0.0)
		SSBDefs.nEFKindSparkleWhite, SSBDefs.nEFKindSparkleWhiteMulti, SSBDefs.nEFKindSparkleWhiteMultiExplode, SSBDefs.nEFKindSparkleWhiteScale, SSBDefs.nEFKindChargeSparkle, SSBDefs.nEFKindFuraSparkle:
			_burst(p, 3, Color(1, 1, 1, 0.8), 1, 0.3, 0.3, Vector3.ZERO, 0.8, 0.0)
		SSBDefs.nEFKindPsionic:
			_burst(p, 5, Color(0.8, 0.5, 1.0, 0.8), 0, 0.4, 0.4, Vector3.ZERO, 1.0, 0.0)
		SSBDefs.nEFKindHealSparkles, SSBDefs.nEFKindRipple:
			_burst(p, 5, Color(0.4, 1.0, 0.5, 0.7), 1, 0.5, 0.3, Vector3(0, 0.6, 0), 0.5, 0.0)
		SSBDefs.nEFKindQuakeMag0:
			shake = maxf(shake, 0.06)
		SSBDefs.nEFKindQuakeMag1:
			shake = maxf(shake, 0.12)
		SSBDefs.nEFKindQuakeMag2:
			shake = maxf(shake, 0.22)
		SSBDefs.nEFKindStarRodSpark, SSBDefs.nEFKindKirbyStar:
			_burst(p, 4, Color(1.0, 0.95, 0.4, 0.9), 1, 0.4, 0.35, Vector3(-dir, 0.3, 0), 1.0, 0.0)
		_:
			if pos != Vector3.ZERO:
				_burst(p, 2, Color(1, 1, 1, 0.4), 0, 0.3, 0.3, Vector3.ZERO, 0.5, 0.0)

## Called once per game frame after the engine step: detects new hits on fighters.
func detect_hits(fighters: Dictionary) -> void:
	for g in fighters:
		var fp = g
		var fr = fighters[g]
		var dmg: int = fp.percent_damage
		var prev: int = _prev_damage.get(fp, dmg)
		_prev_damage[fp] = dmg
		if dmg > prev:
			var jt = fr.joint_world(fp.damage_joint_id)
			var pos: Vector3
			if jt != null:
				pos = (jt as Transform3D).origin * RU.S
			else:
				pos = fp.dobj.translate * RU.S + Vector3(0, 1.5, 0)
			var amount := float(dmg - prev)
			var strength := clampf(amount / 12.0, 0.4, 2.2)
			_spawn(pos, Vector3.ZERO, 0.16, 0.7 * strength, 1.2, Color(1, 1, 1, 1), 1, 0.0)
			_burst(pos, int(3 + strength * 3), Color(1.0, 0.85, 0.35, 1.0), 1, 0.3, 0.32 * strength, Vector3.ZERO, 2.2 * strength, 0.0)
			if fp.damage_element == SSBDefs.nGMHitElementFire:
				_burst(pos, 5, Color(1.0, 0.45, 0.1, 0.9), 0, 0.45, 0.5, Vector3(0, 1.0, 0), 1.0, -0.4)
			elif fp.damage_element == SSBDefs.nGMHitElementElectric:
				_burst(pos, 6, Color(0.7, 0.9, 1.0, 1.0), 1, 0.35, 0.35, Vector3.ZERO, 2.5, 0.0)
			if amount >= 15.0:
				shake = maxf(shake, 0.04 * strength)

func _burst(p: Vector3, n: int, col: Color, shape: int, life: float, size: float, base_vel: Vector3, spread: float, gravity: float) -> void:
	for i in n:
		var v := base_vel + Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.6, 1), rng.randf_range(-0.3, 0.3)) * spread
		_spawn(p + Vector3(rng.randf_range(-0.05, 0.05), rng.randf_range(-0.05, 0.05), 0.1), v, life * rng.randf_range(0.7, 1.3), size * rng.randf_range(0.7, 1.2), rng.randf_range(0.8, 1.6), col, shape, gravity)

func _spawn(p: Vector3, v: Vector3, life: float, size: float, grow: float, col: Color, shape: int, gravity: float) -> void:
	if parts.size() >= MAX_P:
		parts.pop_front()
	var q := P.new()
	q.pos = p
	q.vel = v
	q.life = life
	q.max_life = life
	q.size = size
	q.grow = grow
	q.color = col
	q.shape = float(shape)
	q.rot = rng.randf_range(0, TAU)
	q.spin = rng.randf_range(-3, 3)
	q.gravity = gravity
	parts.append(q)

func update(delta: float) -> void:
	shake = maxf(shake - delta * 0.6, 0.0)
	var alive: Array = []
	for q in parts:
		q.life -= delta
		if q.life <= 0.0:
			continue
		q.vel.y -= q.gravity * delta * 3.0
		q.vel *= (1.0 - minf(delta * 2.5, 0.5))
		q.pos += q.vel * delta
		q.rot += q.spin * delta
		alive.append(q)
	parts = alive
	var n := parts.size()
	mm.visible_instance_count = n
	for i in n:
		var q: P = parts[i]
		var f: float = q.life / q.max_life
		var s: float = q.size * lerpf(q.grow, 1.0, f)
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(s, s, s)), q.pos))
		mm.set_instance_color(i, q.color)
		mm.set_instance_custom_data(i, Color(f, q.shape, q.rot, 0.0))
