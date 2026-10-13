## Port of ITStruct (src/it/ittypes.h) merged with its GObj.
class_name Item
extends GObj

var item_gobj = null                   # == self
var owner_gobj = null
var kind: int = 0
var type: int = 0
var team: int = 0
var player: int = 0
var handicap: int = 9
var player_num: int = 0
var percent_damage: int = 0
var hitlag_tics: int = 0
var lr: int = 1

class ITPhysics:
	var vel_ground: float = 0.0
	var vel_air: Vector3 = Vector3.ZERO
var physics := ITPhysics.new()

var coll_data := MPCollData.new()
var ga: int = 0
var attack_coll := ITAttackColl.new()
var damage_coll := ITDamageColl.new()
var hit_normal_damage: int = 0
var hit_lr: int = 0
var hit_refresh_damage: int = 0
var hit_attack_damage: int = 0
var hit_shield_damage: int = 0
var shield_collide_angle: float = 0.0
var shield_collide_dir: Vector3 = Vector3.ZERO
var reflect_gobj = null
var reflect_stat_flags := GMStatFlags.new()
var reflect_stat_count: int = 0
var damage_highest: int = 0
var damage_knockback: float = 0.0
var damage_queue: int = 0
var damage_angle: int = 0
var damage_element: int = 0
var damage_lr: int = 0
var damage_gobj = null
var damage_team: int = 0
var damage_port: int = 0
var damage_player_num: int = 0
var damage_handicap: int = 0
var damage_display_mode: int = 0
var damage_lag: int = 0
var lifetime: int = 0
var vel_scale: float = 1.0
var drop_sfx: int = 0
var throw_sfx: int = 0
var smash_sfx: int = 0
var is_allow_pickup: int = 0
var is_hold: int = 0
var times_landed: int = 0
var times_thrown: int = 0
var weight: int = 0
var is_damage_all: int = 0
var is_attach_surface: int = 0
var is_thrown: int = 0
var attach_line_id: int = 0
var pickup_wait: int = 0
var is_allow_knockback: int = 0
var is_unused_item_bool: int = 0
var is_static_damage: int = 0
var attr = null                        # ITAttributes dictionary
var colanim := GMColAnim.new()
var is_hitlag_victim: int = 0
var multi: int = 0
var event_id: int = 0
var spin_step: float = 0.0
var arrow_gobj = null
var arrow_timer: int = 0
var item_vars: Dictionary = {}
var display_mode: int = 0
var proc_update: Callable = Callable()
var proc_map: Callable = Callable()
var proc_hit: Callable = Callable()
var proc_shield: Callable = Callable()
var proc_hop: Callable = Callable()
var proc_setoff: Callable = Callable()
var proc_reflector: Callable = Callable()
var proc_damage: Callable = Callable()
var proc_dead: Callable = Callable()
var visual_kind: String = ""           # port-only: placeholder visual id

func _init() -> void:
	item_gobj = self
	user_data = self
	coll_data.owner = self
	item_vars = {
		"taru": SSBStructs.make_ITCommonItemVarsTaru(),
		"bombhei": SSBStructs.make_ITCommonItemVarsBombHei(),
		"bumper": SSBStructs.make_ITCommonItemVarsBumper(),
		"shell": SSBStructs.make_ITCommonItemVarsShell(),
		"mball": SSBStructs.make_ITCommonItemVarsMBall(),
		"pkfire": SSBStructs.make_ITFighterItemVarsPKFire(),
		"linkbomb": SSBStructs.make_ITFighterItemVarsLinkBomb(),
		"pakkun": SSBStructs.make_ITGroundItemVarsPakkun(),
		"tarubomb": SSBStructs.make_ITGroundItemVarsTaruBomb(),
		"glucky": SSBStructs.make_ITGroundItemVarsGLucky(),
		"marumine": SSBStructs.make_ITGroundItemVarsMarumine(),
		"hitokage": SSBStructs.make_ITGroundItemVarsHitokage(),
		"fushigibana": SSBStructs.make_ITGroundItemVarsFushigibana(),
		"porygon": SSBStructs.make_ITGroundItemVarsPorygon(),
		"iwark": SSBStructs.make_ITMonsterItemVarsIwark(),
		"kabigon": SSBStructs.make_ITMonsterItemVarsKabigon(),
		"tosakinto": SSBStructs.make_ITMonsterItemVarsTosakinto(),
		"nyars": SSBStructs.make_ITMonsterItemVarsNyars(),
		"lizardon": SSBStructs.make_ITMonsterItemVarsLizardon(),
		"spear": SSBStructs.make_ITMonsterItemVarsSpear(),
		"kamex": SSBStructs.make_ITMonsterItemVarsKamex(),
		"mlucky": SSBStructs.make_ITMonsterItemVarsMLucky(),
		"starmie": SSBStructs.make_ITMonsterItemVarsStarmie(),
		"dogas": SSBStructs.make_ITMonsterItemVarsDogas(),
		"mew": SSBStructs.make_ITMonsterItemVarsMew(),
	}
