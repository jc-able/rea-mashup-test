## Port of FTStruct (src/ft/fttypes.h) together with the fighter's GObj-level fields.
## Field names are identical to the C struct so ported code reads `fp.field` for `fp->field`.
## Unions (status_vars / passive_vars) are nested Dictionaries generated from the C headers
## (SSBStructs), accessed with the same dotted paths as in C.
class_name Fighter
extends GObj

# GObj-level fields (dobj == joints[nFTPartsJointTopN], anim_frame, link_id, ...) come from GObj.

# ---------------------------------------------------------------- FTStruct
var fighter_gobj = null               # == self
var fkind: int = 0
var team: int = 0
var player: int = 0
var detail_curr: int = 1
var detail_base: int = 1
var costume: int = 0
var shade: int = 0
var handicap: int = 9
var level: int = 0
var stock_count: int = 0
var team_order: int = 0
var dl_link: int = 9
var player_num: int = 0
var status_total_tics: int = 0
var pkind: int = 0                    # nFTPlayerKind*
var status_id: int = 0
var motion_id: int = 0
var percent_damage: int = 0
var damage_resist: int = 0
var shield_health: int = 0
var unk_ft_0x38: float = 0.0
var unk_ft_0x3C: int = 0
var hitlag_tics: int = 0
var lr: int = 1

class FTPhysics:
	var vel_air: Vector3 = Vector3.ZERO
	var vel_damage_air: Vector3 = Vector3.ZERO
	var vel_ground: Vector3 = Vector3.ZERO
	var vel_damage_ground: float = 0.0
	var vel_jostle_x: float = 0.0
	var vel_jostle_z: float = 0.0
var physics := FTPhysics.new()

var coll_data := MPCollData.new()

var jumps_used: int = 0
var unk_ft_0x149: int = 0
var ga: int = 0                        # nMPKineticsGround / nMPKineticsAir

var attack1_followup_frames: float = 0.0
var attack1_status_id: int = 0
var attack1_input_count: int = 0
var cliffcatch_wait: int = 0
var tics_since_last_z: int = 0
var acid_wait: int = 0
var twister_wait: int = 0
var tarucann_wait: int = 0
var damagefloor_wait: int = 0
var playertag_wait: int = 0
var card_anim_frame_id: int = 0

## union FTCommandVars: flags.flag0..3 alias item_throw (bitfields over the same words)
class FTItemThrowFlags:
	var _mv = null
	func _init(mv) -> void:
		_mv = mv
	var is_throw_item: int:
		get: return _mv.flag0
		set(v): _mv.flag0 = v
	var unk1: int:
		get: return (_mv.flag1 >> 24) & 0xFF
		set(v): _mv.flag1 = (_mv.flag1 & 0x00FFFFFF) | ((v & 0xFF) << 24)
	var damage: int:
		get: return _mv.flag1 & 0xFFFFFF
		set(v): _mv.flag1 = (_mv.flag1 & ~0xFFFFFF) | (v & 0xFFFFFF)
	var unk2: int:
		get: return (_mv.flag2 >> 24) & 0xFF
		set(v): _mv.flag2 = (_mv.flag2 & 0x00FFFFFF) | ((v & 0xFF) << 24)
	var vel: int:
		get: return (_mv.flag2 >> 12) & 0xFFF
		set(v): _mv.flag2 = (_mv.flag2 & ~(0xFFF << 12)) | ((v & 0xFFF) << 12)
	var angle: int:
		get:
			var a: int = _mv.flag2 & 0xFFF
			return a - 0x1000 if a >= 0x800 else a
		set(v): _mv.flag2 = (_mv.flag2 & ~0xFFF) | (v & 0xFFF)

class FTCommandVars:
	var flag0: int = 0
	var flag1: int = 0
	var flag2: int = 0
	var flag3: int = 0
	var flags = self                   # motion_vars.flags.flagN
	var item_throw: FTItemThrowFlags = null
	func _init() -> void:
		item_throw = FTItemThrowFlags.new(self)
var motion_vars := FTCommandVars.new()

var is_attack_active: int = 0
var is_hitstatus_nodamage: int = 0
var is_damage_coll_modify: int = 0
var is_modelpart_modify: int = 0
var is_texturepart_modify: int = 0
var is_reflect: int = 0
var reflect_lr: int = 0
var is_absorb: int = 0
var absorb_lr: int = 0
var is_goto_attack100: int = 0
var is_fastfall: int = 0
var is_magnify_show: int = 0
var is_limit_map_bounds: int = 0
var is_invisible: int = 0
var is_shadow_hide: int = 0
var is_rebirth: int = 0
var is_magnify_ignore: int = 0
var is_playertag_hide: int = 0
var is_playertag_bossend: int = 0
var is_effect_skip: int = 0
var effect_joint_array_id: int = 0
var is_shield: int = 0
var is_effect_attach: int = 0
var is_jostle_ignore: int = 0
var is_have_translate_scale: int = 0
var is_control_disable: int = 0
var is_hitstun: int = 0
var slope_contour: int = 0
var is_use_animlocks: int = 0
var is_muted: int = 0
var unk_ft_0x190_b5: int = 0
var is_item_show: int = 0
var is_cliff_hold: int = 0
var is_events_forward: int = 0
var is_ghost: int = 0
var is_damage_resist: int = 0
var is_menu_ignore: int = 0
var camera_mode: int = 0
var is_special_interrupt: int = 0
var is_ignore_dead: int = 0
var is_catchstatus: int = 0
var is_catch_or_capture: int = 0
var is_use_fogcolor: int = 0
var is_shield_catch: int = 0
var is_knockback_paused: int = 0

var capture_immune_mask: int = 0
var catch_mask: int = 0

var anim_desc: int = 0                 # FTAnimDesc.word (see FtAnimDesc helpers)
var anim_vel: Vector3 = Vector3.ZERO
var magnify_pos: Vector2 = Vector2.ZERO

class FTPlayerInput:
	var button_hold: int = 0
	var button_tap: int = 0
	var button_release: int = 0
	var stick_range: Vector2i = Vector2i.ZERO
	var stick_prev: Vector2i = Vector2i.ZERO

class FTComputerInput:
	var button_inputs: int = 0
	var stick_range: Vector2i = Vector2i.ZERO

class FTInputStruct:
	var controller = null               # SYController (PlayerController)
	var button_mask_a: int = SSBDefs.A_BUTTON
	var button_mask_b: int = SSBDefs.B_BUTTON
	var button_mask_z: int = SSBDefs.Z_TRIG
	var button_mask_l: int = SSBDefs.L_TRIG
	var pl := FTPlayerInput.new()
	var cp := FTComputerInput.new()
var input := FTInputStruct.new()

var computer := FTComputer.new()

var damage_coll_size: Vector2 = Vector2.ZERO
var tap_stick_x: int = 0
var tap_stick_y: int = 0
var hold_stick_x: int = 0
var hold_stick_y: int = 0
var breakout_wait: int = 0
var breakout_lr: int = 0
var breakout_ud: int = 0
var shuffle_frame_index: int = 0
var shuffle_index_max: int = 0
var is_shuffle_electric: int = 0
var shuffle_tics: int = 0

var throw_gobj = null
var throw_fkind: int = 0
var throw_team: int = 0
var throw_player: int = 0
var throw_player_num: int = 0

var motion_attack_id: int = 0
var motion_count: int = 0
var stat_flags := GMStatFlags.new()
var stat_count: int = 0

var attack_colls: Array = []           # FTAttackColl x 4

var invincible_tics: int = 0
var intangible_tics: int = 0
var special_hitstatus: int = 0
var star_invincible_tics: int = 0
var star_hitstatus: int = 0
var hitstatus: int = 0

var damage_colls: Array = []           # FTDamageColl x 11

var unk_ft_0x7A0: float = 0.0
var hitlag_mul: float = 1.0
var shield_heal_wait: float = 0.0
var unk_ft_0x7AC: int = 0

var attack_damage: int = 0
var attack_knockback: float = 0.0
var attack_count: int = 0
var attack_shield_push: int = 0
var attack_rebound: float = 0.0
var hit_lr: int = 0
var shield_damage: int = 0
var shield_damage_total: int = 0
var shield_lr: int = 0
var shield_player: int = 0
var reflect_damage: int = 0
var damage_lag: int = 0
var damage_knockback: float = 0.0
var knockback_resist_passive: float = 0.0
var knockback_resist_status: float = 0.0
var damage_knockback_stack: float = 0.0
var damage_queue: int = 0
var damage_angle: int = 0
var damage_element: int = 0
var damage_lr: int = 0
var damage_index: int = 0
var damage_joint_id: int = 0
var damage_player_num: int = 0
var damage_player: int = -1
var damage_count: int = 0
var damage_kind: int = 0
var damage_heal: int = 0
var damage_mul: float = 1.0
var damage_object_class: int = 0
var damage_object_kind: int = 0
var damage_stat_flags := GMStatFlags.new()
var damage_stat_count: int = 0

var public_knockback: float = 0.0

var search_gobj = null
var search_gobj_dist: float = 0.0
var proc_catch: Callable = Callable()
var proc_capture: Callable = Callable()
var catch_gobj = null
var capture_gobj = null

var throw_desc = null                  # FTThrowHitDesc dictionary {status_id, damage, angle, knockback_scale, knockback_weight, knockback_base, element}
var item_gobj = null
var special_coll: FTSpecialColl = null
var entry_pos: Vector3 = Vector3.ZERO
var camera_zoom_frame: float = 0.0
var camera_zoom_range: float = 1.0

var motion_scripts: Array = []         # [2][2] FTMotionScript

var joints: Array = []                 # DObj x FTPARTS_JOINT_NUM_MAX (null when absent)

var modelpart_status: Array = []       # [{modelpart_id_base, modelpart_id_curr}]
var texturepart_status: Array = []

var data = null                        # FtData (loaded fighter data files)
var attr = null                        # FtAttributes (from data)

var figatree = null                    # current animation joint table (Array of AnimStream) or null
var figatree_heap = null

var proc_update: Callable = Callable()
var proc_accessory: Callable = Callable()
var proc_interrupt: Callable = Callable()
var proc_physics: Callable = Callable()
var proc_map: Callable = Callable()
var proc_slope: Callable = Callable()
var proc_damage: Callable = Callable()
var proc_trap: Callable = Callable()
var proc_shield: Callable = Callable()
var proc_hit: Callable = Callable()
var proc_passive: Callable = Callable()
var proc_lagupdate: Callable = Callable()
var proc_lagstart: Callable = Callable()
var proc_lagend: Callable = Callable()
var proc_status: Callable = Callable()

var p_sfx = null
var sfx_id: int = 0
var p_voice = null
var voice_id: int = 0
var p_loop_sfx = null
var loop_sfx_id: int = 0

var colanim := GMColAnim.new()
var fog_color: Color = Color(0, 0, 0, 0)
var shade_color: Color = Color(0, 0, 0, 0)

class FTKey:
	var input_wait: int = 0
	var key_script = null              # C: key.script (Array of u16 key events); renamed, "script" is reserved by Object
	var script_index: int = 0
var key := FTKey.new()

class FTAfterImageInfo:
	var is_itemswing: int = 0
	var drawstatus: int = -1
	var desc_id: int = 0
	var desc: Array = [{}, {}, {}]
var afterimage := FTAfterImageInfo.new()

var passive_vars: Dictionary = {}
var hammer_tics: int = 0
var status_vars: Dictionary = {}
var display_mode: int = 0

# ---------------------------------------------------------------- port-only
var name_key: String = ""              # fighter data key (e.g. "mario")

func _init() -> void:
	fighter_gobj = self
	coll_data.owner = self
	for i in 4:
		attack_colls.append(FTAttackColl.new())
	for i in SSBDefs.FTPARTS_HURT_NUM_MAX:
		damage_colls.append(FTDamageColl.new())
	for i in 2:
		var row := []
		for j in 2:
			row.append(FTMotionScript.new())
		motion_scripts.append(row)
	joints.resize(SSBDefs.FTPARTS_JOINT_NUM_MAX)
	for i in SSBDefs.FTPARTS_JOINT_NUM_MAX - SSBDefs.nFTPartsJointCommonStart:
		modelpart_status.append({"modelpart_id_base": -1, "modelpart_id_curr": -1})
	for i in 2:
		texturepart_status.append({"texture_id_base": 0, "texture_id_curr": 0})
	reset_unions()

func reset_unions() -> void:
	status_vars = {
		"common": SSBStructs.make_FTCommonStatusVars(),
		"mario": SSBStructs.make_FTMarioStatusVars(),
		"fox": SSBStructs.make_FTFoxStatusVars(),
		"donkey": SSBStructs.make_FTDonkeyStatusVars(),
		"samus": SSBStructs.make_FTSamusStatusVars(),
		"link": SSBStructs.make_FTLinkStatusVars(),
		"yoshi": SSBStructs.make_FTYoshiStatusVars(),
		"captain": SSBStructs.make_FTCaptainStatusVars(),
		"kirby": SSBStructs.make_FTKirbyStatusVars(),
		"pikachu": SSBStructs.make_FTPikachuStatusVars(),
		"ness": SSBStructs.make_FTNessStatusVars(),
	}
	passive_vars = {
		"mario": SSBStructs.make_FTMarioPassiveVars(),
		"donkey": SSBStructs.make_FTDonkeyPassiveVars(),
		"samus": SSBStructs.make_FTSamusPassiveVars(),
		"link": SSBStructs.make_FTLinkPassiveVars(),
		"captain": SSBStructs.make_FTCaptainPassiveVars(),
		"kirby": SSBStructs.make_FTKirbyPassiveVars(),
		"pikachu": SSBStructs.make_FTPikachuPassiveVars(),
		"purin": SSBStructs.make_FTPurinPassiveVars(),
		"ness": SSBStructs.make_FTNessPassiveVars(),
	}

# FTAnimDesc bitfield accessors (u32 word; bit31 = is_use_xrotn_joint ... see fttypes.h)
func anim_flag_use_xrotn_joint() -> bool:
	return (anim_desc & 0x80000000) != 0
func anim_flag_use_transn_joint() -> bool:
	return (anim_desc & 0x40000000) != 0
func anim_flag_use_yrotn_joint() -> bool:
	return (anim_desc & 0x20000000) != 0
func anim_flag_use_submotion_script() -> bool:
	return (anim_desc & 0x10) != 0
func anim_flag_is_anim_joint() -> bool:
	return (anim_desc & 0x8) != 0
func anim_flag_is_have_translate_scale() -> bool:
	return (anim_desc & 0x4) != 0
func anim_flag_use_shieldpose() -> bool:
	return (anim_desc & 0x2) != 0
func anim_flag_use_animlocks() -> bool:
	return (anim_desc & 0x1) != 0
