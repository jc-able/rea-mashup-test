## Port of WPStruct (src/wp/wptypes.h) merged with its GObj.
class_name Weapon
extends GObj

var weapon_gobj = null                 # == self
var owner_gobj = null
var kind: int = 0
var team: int = 0
var player: int = 0
var handicap: int = 9
var player_num: int = 0
var lr: int = 1

class WPPhysics:
	var vel_ground: float = 0.0
	var vel_air: Vector3 = Vector3.ZERO
var physics := WPPhysics.new()

var coll_data := MPCollData.new()
var ga: int = 0
var attack_coll := WPAttackColl.new()
var hit_normal_damage: int = 0
var hit_refresh_damage: int = 0
var hit_attack_damage: int = 0
var hit_shield_damage: int = 0
var shield_collide_angle: float = 0.0
var shield_collide_dir: Vector3 = Vector3.ZERO
var reflect_gobj = null
var reflect_stat_flags := GMStatFlags.new()
var reflect_stat_count: int = 0
var absorb_gobj = null
var is_hitlag_victim: int = 0
var is_hitlag_weapon: int = 0
var group_id: int = 0
var lifetime: int = 0
var is_camera_follow: int = 0
var is_static_damage: int = 0
var p_sfx = null
var sfx_id: int = 0
var proc_update: Callable = Callable()
var proc_map: Callable = Callable()
var proc_hit: Callable = Callable()
var proc_shield: Callable = Callable()
var proc_hop: Callable = Callable()
var proc_setoff: Callable = Callable()
var proc_reflector: Callable = Callable()
var proc_absorb: Callable = Callable()
var proc_dead: Callable = Callable()
var weapon_vars: Dictionary = {}
var display_mode: int = 0
var attr = null                        # WPAttributes dictionary
var visual_kind: String = ""           # port-only: which placeholder visual to draw

func _init() -> void:
	weapon_gobj = self
	user_data = self
	coll_data.owner = self
	weapon_vars = {
		"fireball": SSBStructs.make_wpMarioWeaponVarsFireball(),
		"charge_shot": SSBStructs.make_wpSamusWeaponVarsChargeShot(),
		"samus_bomb": SSBStructs.make_wpSamusWeaponVarsBomb(),
		"thunder_jolt": SSBStructs.make_wpPikachuWeaponVarsThunderJolt(),
		"thunder": SSBStructs.make_wpPikachuWeaponVarsThunder(),
		"pkthunder": SSBStructs.make_wpNessWeaponVarsPKThunder(),
		"pkthunder_trail": SSBStructs.make_wpNessWeaponVarsPKThunderTrail(),
		"egg_throw": SSBStructs.make_wpYoshiWeaponVarsEggThrow(),
		"spin_attack": SSBStructs.make_wpLinkWeaponVarsSpinAttack(),
		"boomerang": SSBStructs.make_wpLinkWeaponVarsBoomerang(),
		"star": SSBStructs.make_wpStarRodWeaponVarsStar(),
		"rock": SSBStructs.make_wpIwarkWeaponVarsRock(),
		"coin": SSBStructs.make_wpNyarsWeaponVarsCoin(),
		"hydro": SSBStructs.make_wpKamexWeaponVarsHydro(),
		"smog": SSBStructs.make_wpDogasWeaponVarsSmog(),
	}
