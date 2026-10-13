## 1:1 port of src/ft/ftcommon/ftcommonthrown2.c (ssb-decomp-re): releasing a grabbed / thrown
## fighter - grip loss, throw knockback + damage, and damage-release when the thrower is hit.
##
## fp.throw_desc is the C `FTThrowHitDesc *throw_desc` (SetThrow motion command): an Array of 2
## Dictionaries {status_id, damage, angle, knockback_scale, knockback_weight, knockback_base, element};
## C `capture_fp->throw_desc` == throw_desc[0], `&capture_fp->throw_desc[1]` == throw_desc[1].
class_name Ftcommonthrown2
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x801886E0 - FTThrowHitDesc { -1, 0, 361, 0, 0, 20, 0 }
static var dFTCommonThrownNoDamageKnockback: Dictionary = {
	"status_id": -1, "damage": 0, "angle": 361, "knockback_scale": 0, "knockback_weight": 0, "knockback_base": 20, "element": 0
}

# // // // // // // // // // // // //
# //   GLOBAL / STATIC VARIABLES   //
# // // // // // // // // // // // //

## 0x8018CF80
static var sFTCommonThrownScriptID: int = 0

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8014ADB0
static func ftCommonThrownReleaseFighterLoseGrip(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var interact_gobj
	var interact_fp: Fighter
	var pos: Vector3

	if B(this_fp.is_catch_or_capture):
		interact_gobj = this_fp.catch_gobj
	else:
		interact_gobj = this_fp.capture_gobj

	interact_fp = ftGetStruct(interact_gobj)

	if (this_fp.status_id >= nFTCommonStatusThrownStart) and (this_fp.status_id <= nFTCommonStatusThrownEnd):
		pos.x = 0.0
		pos.y = 0.0
		pos.z = 0.0

		pos = Gmcollision.gmCollisionGetFighterPartsWorldPosition(this_fp.joints[4], pos)

		pos.y -= 300.0

		DObjGetStruct(fighter_gobj).translate = pos
	Mpcommon.mpCommonRunFighterCollisionDefault(fighter_gobj, DObjGetStruct(interact_gobj).translate, interact_fp.coll_data)

	if this_fp.ga == nMPKineticsGround:
		if (this_fp.coll_data.floor_line_id == -1) or (this_fp.coll_data.floor_dist != 0.0):
			Mpcommon.mpCommonSetFighterAir(this_fp)

## 0x8014AECC
static func ftCommonThrownDecideFighterLoseGrip(fighter_gobj, interact_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var interact_fp := ftGetStruct(interact_gobj)

	if B(this_fp.is_catch_or_capture):
		ftCommonThrownReleaseFighterLoseGrip(fighter_gobj)
	else:
		ftCommonThrownReleaseFighterLoseGrip(interact_gobj)

	interact_fp.capture_gobj = null
	this_fp.catch_gobj = null

## 0x8014AF2C
static func ftCommonThrownDecideDeadResult(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var interact_gobj = fp.catch_gobj

	if interact_gobj != null:
		ftCommonThrownDecideFighterLoseGrip(fighter_gobj, interact_gobj)

		# goto next;
		Mpcommon.mpCommonSetFighterWaitOrFall(fighter_gobj)
		Mpcommon.mpCommonSetFighterWaitOrFall(interact_gobj)
		return
	else:
		interact_gobj = fp.capture_gobj

	if interact_gobj != null:
		ftCommonThrownDecideFighterLoseGrip(interact_gobj, fighter_gobj)

		# next:
		Mpcommon.mpCommonSetFighterWaitOrFall(fighter_gobj)
		Mpcommon.mpCommonSetFighterWaitOrFall(interact_gobj)

## 0x8014AF98
static func ftCommonThrownProcStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftparam.ftParamSetThrowParams(fp, fp.capture_gobj)

	fp.status_vars.common.damage.script_id = sFTCommonThrownScriptID

## 0x8014AFD0
static func ftCommonThrownReleaseThrownUpdateStats(fighter_gobj, lr, script_id, is_proc_status) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var capture_gobj = this_fp.capture_gobj
	var capture_fp := ftGetStruct(capture_gobj)
	var ft_throw: Dictionary
	var knockback_final: float
	var damage: int
	var knockback_resist: float
	var knockback_calc: float

	knockback_resist = this_fp.knockback_resist_passive if (this_fp.knockback_resist_status < this_fp.knockback_resist_passive) else this_fp.knockback_resist_status

	sFTCommonThrownScriptID = script_id

	if this_fp.hitstatus != nGMHitStatusNormal:
		Ftparam.ftParamSetHitStatusAll(fighter_gobj, nGMHitStatusNormal)
	if not B(this_fp.is_catch_or_capture):
		ftCommonThrownReleaseFighterLoseGrip(fighter_gobj)
	Mpcommon.mpCommonSetFighterAir(this_fp)

	ft_throw = capture_fp.throw_desc[0]

	knockback_calc = Ftparam.ftParamGetCommonKnockback(this_fp.percent_damage, ft_throw.damage, ft_throw.damage, ft_throw.knockback_weight, ft_throw.knockback_scale, ft_throw.knockback_base, this_fp.attr.weight, capture_fp.handicap, this_fp.handicap)

	knockback_final = knockback_calc - knockback_resist

	if knockback_calc <= knockback_resist:
		knockback_final = 0.0
	damage = Ftparam.ftParamGetStaledDamage(capture_fp.player, ft_throw.damage, capture_fp.motion_attack_id, capture_fp.motion_count)

	if B(capture_fp.is_shield_catch):
		damage = int((damage * 0.5) + 0.999)
	if Ftparam.ftParamGetBestHitStatusAll(fighter_gobj) != nGMHitStatusNormal:
		damage = 0
	if B(is_proc_status):
		this_fp.proc_status = Callable(Ftcommonthrown2, &"ftCommonThrownProcStatus")
	Ftcommondamage.ftCommonDamageInitDamageVars(fighter_gobj, ft_throw.status_id, damage, knockback_final, ft_throw.angle, lr, 1, ft_throw.element, capture_fp.player_num, TRUE, TRUE, TRUE)
	Ftparam.ftParamUpdate1PGameDamageStats(this_fp, capture_fp.player, nFTHitLogObjectFighter, capture_fp.fkind, capture_fp.stat_flags.halfword, capture_fp.stat_count)

	if damage != 0:
		Ftparam.ftParamUpdateDamage(this_fp, damage)
		Ftparam.ftParamUpdatePlayerBattleStats(capture_fp.player, this_fp.player, damage)
		Ftparam.ftParamUpdateStaleQueue(capture_fp.player, this_fp.player, capture_fp.motion_attack_id, capture_fp.motion_count)

		if int((damage * 0.75) + 4.0) > 0:
			Ftparam.ftParamMakeRumble(this_fp, 0, int((damage * 0.75) + 4.0))
		if int((damage * 0.5) + 2.0) > 0:
			Ftparam.ftParamMakeRumble(capture_fp, 5, int((damage * 0.5) + 2.0))
	this_fp.capture_gobj = null

## 0x8014B2AC
static func ftCommonThrownUpdateDamageStats(this_fp) -> void:
	var capture_gobj = this_fp.capture_gobj
	var capture_fp := ftGetStruct(capture_gobj)
	var ft_throw: Dictionary = capture_fp.throw_desc[1]
	var damage: int = Ftparam.ftParamGetStaledDamage(capture_fp.player, ft_throw.damage, capture_fp.motion_attack_id, capture_fp.motion_count)

	Ftparam.ftParamUpdateDamage(this_fp, damage)
	Ftparam.ftParamUpdatePlayerBattleStats(capture_fp.player, this_fp.player, damage)
	Ftparam.ftParamUpdateStaleQueue(capture_fp.player, this_fp.player, capture_fp.motion_attack_id, capture_fp.motion_count)

## 0x8014B330
static func ftCommonThrownSetStatusDamageRelease(fighter_gobj) -> void:
	var this_fp := ftGetStruct(fighter_gobj)
	var capture_gobj = this_fp.capture_gobj
	var capture_fp := ftGetStruct(capture_gobj)
	var ft_throw: Dictionary
	var knockback_final: float
	var lr: int
	var damage: int
	var knockback_resist: float
	var knockback_calc: float

	knockback_resist = this_fp.knockback_resist_passive if (this_fp.knockback_resist_status < this_fp.knockback_resist_passive) else this_fp.knockback_resist_status

	if this_fp.hitstatus != nGMHitStatusNormal:
		Ftparam.ftParamSetHitStatusAll(fighter_gobj, nGMHitStatusNormal)
	if not B(this_fp.is_catch_or_capture):
		ftCommonThrownReleaseFighterLoseGrip(fighter_gobj)
	if this_fp.ga == nMPKineticsAir:
		Mpcommon.mpCommonSetFighterAir(this_fp)
	ft_throw = capture_fp.throw_desc[1]

	knockback_calc = Ftparam.ftParamGetCommonKnockback(this_fp.percent_damage, ft_throw.damage, ft_throw.damage, ft_throw.knockback_weight, ft_throw.knockback_scale, ft_throw.knockback_base, this_fp.attr.weight, capture_fp.handicap, this_fp.handicap)

	knockback_final = knockback_calc - knockback_resist

	if knockback_calc <= knockback_resist:
		knockback_final = 0.0
	lr = +1 if (DObjGetStruct(fighter_gobj).translate.x < DObjGetStruct(capture_gobj).translate.x) else -1

	damage = Ftparam.ftParamGetStaledDamage(capture_fp.player, ft_throw.damage, capture_fp.motion_attack_id, capture_fp.motion_count)

	if B(capture_fp.is_shield_catch):
		damage = int((damage * 0.5) + 0.999)
	if Ftparam.ftParamGetBestHitStatusAll(fighter_gobj) != nGMHitStatusNormal:
		damage = 0
	Ftcommondamage.ftCommonDamageInitDamageVars(fighter_gobj, ft_throw.status_id, damage, knockback_final, ft_throw.angle, lr, 1, nGMHitElementNormal, capture_fp.player_num, FALSE, FALSE, TRUE)
	Ftparam.ftParamUpdate1PGameDamageStats(this_fp, capture_fp.player, nFTHitLogObjectFighter, capture_fp.fkind, capture_fp.stat_flags.halfword, capture_fp.stat_count)

	if damage != 0:
		Ftparam.ftParamUpdateDamage(this_fp, damage)
		Ftparam.ftParamUpdatePlayerBattleStats(capture_fp.player, this_fp.player, damage)
		Ftparam.ftParamUpdateStaleQueue(capture_fp.player, this_fp.player, capture_fp.motion_attack_id, capture_fp.motion_count)
	this_fp.capture_gobj = null

## 0x8014B5B4
static func ftCommonThrownSetStatusNoDamageRelease(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var ft_throw: Dictionary = dFTCommonThrownNoDamageKnockback
	var knockback_calc: float
	var knockback_resist: float
	var knockback_final: float

	if fp.knockback_resist_status < fp.knockback_resist_passive:
		knockback_resist = fp.knockback_resist_passive
	else:
		knockback_resist = fp.knockback_resist_status

	DObjGetStruct(fighter_gobj).translate.z = 0.0

	knockback_calc = Ftparam.ftParamGetCommonKnockback(fp.percent_damage, ft_throw.damage, ft_throw.damage, ft_throw.knockback_weight, ft_throw.knockback_scale, ft_throw.knockback_base, fp.attr.weight, 9, fp.handicap)

	knockback_final = knockback_calc - knockback_resist

	if knockback_calc <= knockback_resist:
		knockback_final = 0.0
	Ftcommondamage.ftCommonDamageInitDamageVars(fighter_gobj, ft_throw.status_id, 0, knockback_final, ft_throw.angle, fp.lr, 1, ft_throw.element, 0, TRUE, TRUE, FALSE)
	Ftparam.ftParamUpdate1PGameDamageStats(fp, GMCOMMON_PLAYERS_MAX, nFTHitLogObjectNone, 0, 0, 0)
