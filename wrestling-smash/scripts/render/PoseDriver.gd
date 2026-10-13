## Stage-less fighter puppets for the Pose Lab and the retarget measurement tool: fighters are
## created through Ftmanager as nFTPlayerKindDemo (no gameplay processes, no stage needed) and
## animated by entering a status with Ftmain.ftMainSetStatus + ftMainPlayAnimEventsAll per frame,
## i.e. the ported figatree / motion-script code itself.
extends RefCounted

const RU = preload("res://scripts/render/RenderUtil.gd")

## label -> common status constant name (looked up in SSBDefs) or fighter-specific suffix "@SpecialN".
const MOTIONS := [
	["Wait", "nFTCommonStatusWait"], ["Walk", "nFTCommonStatusWalkMiddle"], ["Run", "nFTCommonStatusRun"],
	["Jump", "nFTCommonStatusJumpF"], ["JumpAerial", "nFTCommonStatusJumpAerialF"], ["Squat", "nFTCommonStatusSquatWait"],
	["Jab", "nFTCommonStatusAttack11"], ["DashAttack", "nFTCommonStatusAttackDash"], ["FTilt", "nFTCommonStatusAttackS3"],
	["UTilt", "nFTCommonStatusAttackHi3"], ["DTilt", "nFTCommonStatusAttackLw3"], ["FSmash", "nFTCommonStatusAttackS4"],
	["USmash", "nFTCommonStatusAttackHi4"], ["DSmash", "nFTCommonStatusAttackLw4"], ["NAir", "nFTCommonStatusAttackAirN"],
	["FAir", "nFTCommonStatusAttackAirF"], ["BAir", "nFTCommonStatusAttackAirB"], ["UAir", "nFTCommonStatusAttackAirHi"],
	["DAir", "nFTCommonStatusAttackAirLw"], ["Grab", "nFTCommonStatusCatch"], ["Shield", "nFTCommonStatusGuard"],
	["Damage", "nFTCommonStatusDamageFlyHi"], ["Taunt", "nFTCommonStatusAppeal"],
	["SpecialN", "@SpecialN"], ["SpecialHi", "@SpecialHi"], ["SpecialLw", "@SpecialLw"],
]

const FT_NAMES := ["Mario", "Fox", "Donkey", "Samus", "Luigi", "Link", "Yoshi", "Captain", "Kirby", "Pikachu", "Purin", "Ness"]

static var _consts: Dictionary = {}

static func const_value(name: String) -> int:
	if _consts.is_empty():
		_consts = (SSBDefs as Script).get_script_constant_map()
	return int(_consts.get(name, -1))

## Resolve a motion label to a status id for this fighter kind (-1 if not available).
static func status_for(fkind: int, label: String) -> int:
	for m in MOTIONS:
		if m[0] != label:
			continue
		var nm: String = m[1]
		if nm.begins_with("@"):
			var who: String = FT_NAMES[fkind] if fkind < FT_NAMES.size() else "Mario"
			for cand in ["nFT%sStatus%s" % [who, nm.substr(1)], "nFT%sStatus%sStart" % [who, nm.substr(1)], "nFT%sStatus%sCharge" % [who, nm.substr(1)], "nFT%sStatus%sAttack" % [who, nm.substr(1)]]:
				var v := const_value(cand)
				if v >= 0:
					return v
			return -1
		return const_value(nm)
	return -1

static func make_fighter(fkind: int, pos := Vector3.ZERO, lr := 1, player := 0):
	if Sim.links.is_empty():
		Sim.reset()
	var desc := Ftmanager.default_desc()
	desc.fkind = fkind
	desc.pos = pos
	desc.lr = lr
	desc.player = player
	desc.team = player
	desc.pkind = SSBDefs.nFTPlayerKindDemo
	desc.is_skip_shadow_setup = 1
	var fp = Ftmanager.ftManagerMakeFighter(desc)
	return fp

static func set_status(fp, status_id: int) -> bool:
	if status_id < 0:
		return false
	Ftmain.ftMainSetStatus(fp, status_id, 0.0, 1.0, 0)
	fp.joints[SSBDefs.nFTPartsJointTopN].rotate.y = fp.lr * deg_to_rad(90.0)
	fp.is_invisible = 0
	return true

## Advance one 60 Hz frame of the current motion. Returns true when the animation ended.
static func advance(fp, with_events := true) -> bool:
	if with_events:
		Ftmain.ftMainPlayAnimEventsAll(fp)
	else:
		Ftmain.ftMainPlayAnim(fp)
	fp.joints[SSBDefs.nFTPartsJointTopN].rotate.y = fp.lr * deg_to_rad(90.0)
	return fp.anim_frame <= 0.0

## Wait-pose measurements (SSB world units): top of the highest active hurtbox and hips height.
static func measure(fp, hips_joint: int) -> Dictionary:
	var jw := []
	jw.resize(SSBDefs.FTPARTS_JOINT_NUM_MAX)
	RU.fighter_world(fp, jw)
	var top := 0.0
	var head_joint_y := 0.0
	for dc in fp.damage_colls:
		if dc.hitstatus == SSBDefs.nGMHitStatusNone or dc.joint_id < 0 or jw[dc.joint_id] == null:
			continue
		var w: Transform3D = jw[dc.joint_id]
		var c: Vector3 = w * dc.offset
		var b: Basis = w.basis
		top = maxf(top, c.y + absf(b.x.y) * dc.size.x + absf(b.y.y) * dc.size.y + absf(b.z.y) * dc.size.z)
		if dc.placement == 2:
			head_joint_y = maxf(head_joint_y, w.origin.y)
	var base_y: float = (jw[0] as Transform3D).origin.y
	var hips_y := 0.0
	if hips_joint >= 0 and jw[hips_joint] != null:
		hips_y = (jw[hips_joint] as Transform3D).origin.y - base_y
	return {"standing_height": snappedf(top - base_y, 0.1), "hip_height": snappedf(hips_y, 0.1), "head_joint_height": snappedf(head_joint_y - base_y, 0.1)}
