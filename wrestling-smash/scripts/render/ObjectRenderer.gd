## Placeholder visuals for weapons (projectiles) and items: simple coloured primitives keyed by
## visual_kind (falling back to the WP/IT kind enum), sized from the object's hurtbox/hitbox and
## rotated with its root DObj. Objects are tracked by identity; visuals appear/disappear with them.
extends Node3D

const RU = preload("res://scripts/render/RenderUtil.gd")

## spec: [shape, color, emission(0..), size_units, stretch Vector3, spin_deg_per_s]
## shapes: sphere, box, cyl, capsule, star, ring, cone
const WEAPON_SPECS := {
	"mario_fireball": ["sphere", Color(1.0, 0.45, 0.1), 1.4, 90.0, Vector3.ONE, 0.0],
	"luigi_fireball": ["sphere", Color(0.3, 1.0, 0.35), 1.4, 90.0, Vector3.ONE, 0.0],
	"fox_blaster": ["capsule", Color(1.0, 0.25, 0.2), 1.4, 60.0, Vector3(1, 1, 4), 0.0],
	"samus_chargeshot": ["sphere", Color(1.0, 0.75, 0.25), 1.4, 120.0, Vector3.ONE, 0.0],
	"samus_bomb": ["sphere", Color(0.35, 0.3, 0.35), 0.6, 70.0, Vector3.ONE, 0.0],
	"kirby_cutter": ["ring", Color(0.6, 0.9, 1.0), 1.4, 160.0, Vector3(1, 1, 0.35), 0.0],
	"yoshi_egg": ["sphere", Color(0.95, 0.95, 0.9), 0.2, 80.0, Vector3(0.85, 1.1, 0.85), 360.0],
	"yoshi_star": ["star", Color(1.0, 0.9, 0.2), 1.4, 80.0, Vector3.ONE, 540.0],
	"link_boomerang": ["box", Color(0.6, 0.38, 0.18), 0.3, 110.0, Vector3(1, 0.18, 0.5), 1080.0],
	"link_spinattack": ["ring", Color(0.5, 0.9, 1.0), 1.4, 220.0, Vector3(1, 0.25, 1), 720.0],
	"pikachu_thunder_jolt_air": ["sphere", Color(1.0, 0.95, 0.25), 1.4, 70.0, Vector3.ONE, 0.0],
	"pikachu_thunder_jolt_ground": ["sphere", Color(1.0, 0.95, 0.25), 1.4, 70.0, Vector3.ONE, 0.0],
	"pikachu_thunder_head": ["capsule", Color(1.0, 1.0, 0.4), 1.4, 90.0, Vector3(1, 3, 1), 0.0],
	"pikachu_thunder_trail": ["cyl", Color(1.0, 1.0, 0.5), 1.4, 40.0, Vector3(1, 6, 1), 0.0],
	"ness_pk_fire": ["star", Color(1.0, 0.5, 0.9), 1.4, 70.0, Vector3.ONE, 720.0],
	"ness_pk_thunder_head": ["sphere", Color(0.45, 0.85, 1.0), 1.4, 80.0, Vector3.ONE, 0.0],
	"ness_pk_thunder_trail": ["sphere", Color(0.65, 0.4, 1.0), 1.4, 45.0, Vector3.ONE, 0.0],
	"ArwingLaser2D": ["capsule", Color(1.0, 0.2, 0.2), 1.4, 60.0, Vector3(1, 1, 5), 0.0],
	"ArwingLaser3D": ["capsule", Color(0.3, 1.0, 0.3), 1.4, 90.0, Vector3(1, 1, 5), 0.0],
	"hitokage_flame": ["sphere", Color(1.0, 0.5, 0.1), 1.4, 80.0, Vector3.ONE, 0.0],
	"fushigibana_razor": ["star", Color(0.4, 0.9, 0.3), 1.4, 70.0, Vector3(1, 1, 0.3), 900.0],
}

const WEAPON_KIND_KEYS := {
	0: "mario_fireball", 1: "fox_blaster", 2: "samus_chargeshot", 3: "samus_bomb", 4: "kirby_cutter",
	5: "yoshi_egg", 6: "yoshi_star", 7: "link_boomerang", 8: "link_spinattack", 9: "pikachu_thunder_jolt_air",
	10: "pikachu_thunder_jolt_ground", 11: "pikachu_thunder_head", 12: "pikachu_thunder_trail", 13: "ness_pk_fire",
	14: "ness_pk_thunder_head", 15: "ness_pk_thunder_trail", 18: "ArwingLaser2D", 19: "ArwingLaser3D",
	20: "lgun_ammo", 21: "fflower_flame", 22: "starrod_star", 30: "hitokage_flame", 31: "fushigibana_razor",
}

const EXTRA_WEAPON_SPECS := {
	"lgun_ammo": ["capsule", Color(1.0, 0.3, 0.3), 1.4, 50.0, Vector3(1, 1, 5), 0.0],
	"fflower_flame": ["sphere", Color(1.0, 0.55, 0.15), 1.4, 70.0, Vector3.ONE, 0.0],
	"starrod_star": ["star", Color(1.0, 0.95, 0.3), 1.4, 90.0, Vector3.ONE, 720.0],
	"iwark_rock": ["box", Color(0.55, 0.5, 0.48), 0.1, 160.0, Vector3.ONE, 120.0],
	"nyars_coin": ["cyl", Color(1.0, 0.85, 0.2), 0.8, 60.0, Vector3(1, 0.15, 1), 720.0],
	"lizardon_flame": ["sphere", Color(1.0, 0.45, 0.1), 1.4, 110.0, Vector3.ONE, 0.0],
	"spear_swarm": ["capsule", Color(1.0, 0.85, 0.2), 0.8, 60.0, Vector3(1, 1, 2), 0.0],
	"kamex_hydro": ["sphere", Color(0.35, 0.6, 1.0), 1.2, 90.0, Vector3.ONE, 0.0],
	"starmie_swift": ["star", Color(1.0, 0.95, 0.4), 1.4, 60.0, Vector3.ONE, 720.0],
	"dogas_smog": ["sphere", Color(0.6, 0.4, 0.7), 0.5, 150.0, Vector3.ONE, 0.0],
}

## item kind -> spec (nITKind order, src/it/itdef.h)
const ITEM_SPECS := {
	0: ["box", Color(0.72, 0.5, 0.27), 0.0, 0.0, Vector3.ONE, 0.0],            # box
	1: ["cyl", Color(0.62, 0.4, 0.2), 0.0, 0.0, Vector3.ONE, 0.0],             # barrel
	2: ["capsule", Color(0.98, 0.85, 0.3), 0.3, 0.0, Vector3.ONE, 0.0],        # capsule
	3: ["sphere", Color(0.97, 0.97, 0.92), 0.1, 0.0, Vector3(0.85, 1.1, 0.85), 0.0],  # egg
	4: ["sphere", Color(0.95, 0.15, 0.12), 0.2, 0.0, Vector3.ONE, 0.0],        # maxim tomato
	5: ["box", Color(1.0, 0.3, 0.45), 0.6, 0.0, Vector3(1, 1, 0.4), 90.0],      # heart container
	6: ["star", Color(1.0, 0.92, 0.2), 1.4, 0.0, Vector3.ONE, 540.0],         # star
	7: ["box", Color(0.75, 0.9, 1.0), 0.6, 0.0, Vector3(0.12, 1.0, 0.04), 0.0], # beam sword
	8: ["cyl", Color(0.7, 0.5, 0.3), 0.0, 0.0, Vector3(0.25, 1.0, 0.25), 0.0], # home-run bat
	9: ["box", Color(0.98, 0.95, 0.85), 0.0, 0.0, Vector3(0.6, 1.0, 0.08), 0.0], # fan (harisen)
	10: ["star", Color(1.0, 0.9, 0.3), 1.2, 0.0, Vector3.ONE, 180.0],         # star rod
	11: ["box", Color(0.3, 0.32, 0.36), 0.2, 0.0, Vector3(1.0, 0.45, 0.3), 0.0], # ray gun
	12: ["sphere", Color(1.0, 0.45, 0.15), 0.6, 0.0, Vector3.ONE, 0.0],       # fire flower
	13: ["box", Color(0.45, 0.32, 0.22), 0.0, 0.0, Vector3(0.6, 1.0, 0.4), 0.0], # hammer
	14: ["sphere", Color(0.85, 0.2, 0.2), 0.8, 0.0, Vector3(1, 0.6, 1), 0.0],  # motion-sensor bomb
	15: ["sphere", Color(0.12, 0.12, 0.15), 0.0, 0.0, Vector3.ONE, 0.0],       # bob-omb
	16: ["cyl", Color(0.95, 0.3, 0.45), 0.4, 0.0, Vector3(1, 0.5, 1), 0.0],    # bumper
	17: ["sphere", Color(0.2, 0.75, 0.3), 0.2, 0.0, Vector3(1, 0.6, 1), 0.0],  # green shell
	18: ["sphere", Color(0.85, 0.15, 0.15), 0.2, 0.0, Vector3(1, 0.6, 1), 0.0], # red shell
	19: ["sphere", Color(0.95, 0.2, 0.2), 0.3, 0.0, Vector3.ONE, 360.0],      # poke ball
	20: ["cyl", Color(1.0, 0.45, 0.85), 1.4, 0.0, Vector3(0.6, 1.0, 0.6), 0.0], # PK fire pillar
	21: ["sphere", Color(0.25, 0.3, 0.6), 0.2, 0.0, Vector3.ONE, 0.0],         # link bomb
	22: ["box", Color(0.25, 0.45, 0.95), 0.5, 0.0, Vector3.ONE, 0.0],          # POW block
	23: ["cyl", Color(0.95, 0.25, 0.3), 0.5, 0.0, Vector3(1, 0.4, 1), 0.0],    # castle bumper
	24: ["capsule", Color(0.25, 0.7, 0.3), 0.0, 0.0, Vector3.ONE, 0.0],        # piranha plant
	25: ["cyl", Color(0.95, 0.95, 0.95), 0.5, 0.0, Vector3(1, 0.2, 1), 0.0],   # target
	26: ["cyl", Color(0.55, 0.35, 0.2), 0.0, 0.0, Vector3.ONE, 0.0],           # barrel bomb
	27: ["sphere", Color(1.0, 0.7, 0.75), 0.0, 0.0, Vector3.ONE, 0.0],         # chansey
	28: ["sphere", Color(0.95, 0.25, 0.2), 0.3, 0.0, Vector3.ONE, 0.0],        # electrode
	29: ["capsule", Color(1.0, 0.55, 0.2), 0.0, 0.0, Vector3.ONE, 0.0],        # charmander
	30: ["sphere", Color(0.35, 0.65, 0.5), 0.0, 0.0, Vector3(1.3, 0.9, 1.0), 0.0], # venusaur
	31: ["box", Color(0.95, 0.45, 0.6), 0.2, 0.0, Vector3.ONE, 0.0],           # porygon
}

var _tracked: Dictionary = {}      # GObj -> {"node": Node3D, "spin": float, "spec": Array}
var _meshes: Dictionary = {}
var _mats: Dictionary = {}
var _t := 0.0

func _spec_for_weapon(wp) -> Array:
	var vk: String = str(wp.visual_kind)
	if WEAPON_SPECS.has(vk):
		return WEAPON_SPECS[vk]
	if EXTRA_WEAPON_SPECS.has(vk):
		return EXTRA_WEAPON_SPECS[vk]
	var key: String = WEAPON_KIND_KEYS.get(int(wp.kind), "")
	if WEAPON_SPECS.has(key):
		return WEAPON_SPECS[key]
	if EXTRA_WEAPON_SPECS.has(key):
		return EXTRA_WEAPON_SPECS[key]
	return ["sphere", Color(1, 1, 1), 1.4, 60.0, Vector3.ONE, 0.0]

func _spec_for_item(ip) -> Array:
	var k := int(ip.kind)
	if ITEM_SPECS.has(k):
		return ITEM_SPECS[k]
	if k >= SSBDefs.nITKindMBallMonsterStart:
		# Poke Ball pokemon: tinted capsule by species
		var hue := fmod(float(k - SSBDefs.nITKindMBallMonsterStart) * 0.137, 1.0)
		return ["capsule", Color.from_hsv(hue, 0.55, 0.9), 0.2, 0.0, Vector3.ONE, 0.0]
	return ["box", Color(0.9, 0.2, 0.9), 0.5, 0.0, Vector3.ONE, 0.0]

func _mesh(shape: String) -> Mesh:
	if _meshes.has(shape):
		return _meshes[shape]
	var m: Mesh
	match shape:
		"sphere":
			var s := SphereMesh.new()
			s.radius = 0.5
			s.height = 1.0
			s.radial_segments = 20
			s.rings = 10
			m = s
		"box":
			var b := BoxMesh.new()
			m = b
		"cyl":
			var c := CylinderMesh.new()
			c.top_radius = 0.5
			c.bottom_radius = 0.5
			c.height = 1.0
			c.radial_segments = 18
			m = c
		"capsule":
			var cp := CapsuleMesh.new()
			cp.radius = 0.35
			cp.height = 1.0
			m = cp
		"ring":
			var t := TorusMesh.new()
			t.inner_radius = 0.38
			t.outer_radius = 0.5
			m = t
		"star":
			var c2 := CylinderMesh.new()
			c2.top_radius = 0.5
			c2.bottom_radius = 0.5
			c2.height = 0.3
			c2.radial_segments = 5
			c2.rings = 1
			m = c2
		_:
			var b2 := BoxMesh.new()
			m = b2
	_meshes[shape] = m
	return m

func _mat(col: Color, emi: float) -> StandardMaterial3D:
	var key := "%s_%.2f" % [col.to_html(), emi]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.45
	if emi > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emi
	_mats[key] = m
	return m

func _make_node(spec: Array) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh(spec[0])
	mi.material_override = _mat(spec[1], spec[2])
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi

func update(delta: float, fighters_by_gobj: Dictionary) -> void:
	_t += delta
	var seen := {}
	for wp in Sim.get_link(SSBDefs.nGCCommonLinkIDWeapon):
		if wp is Weapon and wp.is_alive and wp.dobj != null:
			seen[wp] = true
			_update_weapon(wp, delta)
	for ip in Sim.get_link(SSBDefs.nGCCommonLinkIDItem):
		if ip is Item and ip.is_alive and ip.dobj != null:
			seen[ip] = true
			_update_item(ip, delta, fighters_by_gobj)
	for g in _tracked.keys():
		if not seen.has(g):
			var n: Node = _tracked[g].node
			n.queue_free()
			_tracked.erase(g)

func _entry(g, spec: Array) -> Dictionary:
	if not _tracked.has(g):
		_tracked[g] = {"node": _make_node(spec), "spin": 0.0, "spec": spec}
	return _tracked[g]

func _update_weapon(wp, delta: float) -> void:
	var spec := _spec_for_weapon(wp)
	var e := _entry(wp, spec)
	var mi: MeshInstance3D = e.node
	var d = wp.dobj
	var radius: float = wp.attack_coll.size if wp.attack_coll.size > 0.0 else float(spec[3]) * 0.5
	var size := maxf(radius * 2.0, 30.0)
	if spec[0] == "cyl" and stretch_is_bolt(spec):
		size = clampf(float(spec[3]), 20.0, 60.0)
	var stretch: Vector3 = spec[4]
	e.spin += float(spec[5]) * delta
	var basis := RU.euler_local(Vector3.ZERO, d.rotate, Vector3.ONE).basis
	var vel: Vector3 = wp.physics.vel_air
	if stretch.z > 1.5 and vel.length() > 0.5:
		basis = Basis.looking_at(Vector3(vel.x, vel.y, 0.0).normalized(), Vector3.FORWARD if absf(vel.normalized().y) > 0.95 else Vector3.UP)
	if e.spin != 0.0:
		basis = basis * Basis(Vector3.UP if spec[0] != "star" else Vector3.BACK, deg_to_rad(e.spin))
	if spec[0] == "star":
		basis = basis * Basis(Vector3.RIGHT, PI * 0.5)
	var flicker := 1.0
	if str(wp.visual_kind).begins_with("pikachu") or str(wp.visual_kind).begins_with("ness_pk_thunder"):
		flicker = 0.85 + 0.3 * sin(_t * 60.0)
	mi.transform = Transform3D(basis.scaled_local(stretch * size * RU.S * flicker), d.translate * RU.S)

func stretch_is_bolt(spec: Array) -> bool:
	var st: Vector3 = spec[4]
	return st.y > 2.0

func _update_item(ip, delta: float, fighters_by_gobj: Dictionary) -> void:
	var spec := _spec_for_item(ip)
	var e := _entry(ip, spec)
	var mi: MeshInstance3D = e.node
	var d = ip.dobj
	var half: Vector3 = ip.damage_coll.size
	var size := half * 2.0
	if size.x < 1.0 or size.y < 1.0:
		var r: float = ip.attack_coll.size if ip.attack_coll.size > 0.0 else 70.0
		size = Vector3(r, r, r) * 2.0
	size.z = maxf(size.z, minf(size.x, size.y))
	var stretch: Vector3 = spec[4]
	e.spin += float(spec[5]) * delta
	var center: Vector3 = d.translate + ip.damage_coll.offset
	var basis := RU.euler_local(Vector3.ZERO, d.rotate, Vector3.ONE).basis
	# held items ride the holder's hand joint
	var owner = ip.owner_gobj
	if int(ip.is_hold) != 0 and owner != null and fighters_by_gobj.has(owner):
		var fr = fighters_by_gobj[owner]
		var jid: int = owner.attr.joint_itemheavy_id if int(ip.weight) == SSBDefs.nITWeightHeavy else owner.attr.joint_itemlight_id
		var jt = fr.joint_world(jid)
		if jt != null:
			center = (jt as Transform3D).origin
			basis = (jt as Transform3D).basis.orthonormalized()
	if e.spin != 0.0:
		basis = basis * Basis(Vector3.UP, deg_to_rad(e.spin))
	if spec[0] == "star":
		basis = basis * Basis(Vector3.RIGHT, PI * 0.5)
	mi.transform = Transform3D(basis.scaled_local(Vector3(size.x * stretch.x, size.y * stretch.y, size.z * stretch.z) * RU.S), center * RU.S)
