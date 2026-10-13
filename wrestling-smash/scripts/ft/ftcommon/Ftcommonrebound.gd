## 1:1 port of src/ft/ftcommon/ftcommonrebound.c (ssb-decomp-re): attack clank recoil (ReboundWait / Rebound).
class_name Ftcommonrebound
extends Port

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80144A10
static func ftCommonReboundProcUpdate(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	fp.status_vars.common.rebound.rebound_timer = f32(fp.status_vars.common.rebound.rebound_timer - 1.0) # f32 rebound_timer--

	if fp.status_vars.common.rebound.rebound_timer <= 0.0:
		Ftcommonwait.ftCommonWaitSetStatus(fighter_gobj)

## 0x80144A60
static func ftCommonReboundSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusRebound, 0.0, fp.status_vars.common.rebound.anim_speed, FTSTATUS_PRESERVE_NONE)

## 0x80144A90
static func ftCommonReboundWaitProcUpdate(fighter_gobj) -> void:
	ftCommonReboundSetStatus(fighter_gobj)

## 0x80144AB0
static func ftCommonReboundWaitSetStatus(fighter_gobj) -> void:
	var fp := ftGetStruct(fighter_gobj)
	var lr_rebound: int

	Ftmain.ftMainSetStatus(fighter_gobj, nFTCommonStatusReboundWait, 0.0, 1.0, FTSTATUS_PRESERVE_NONE)

	# f32 fields: stored with single precision like the C (fp->attack_rebound is an f32 as well)
	fp.status_vars.common.rebound.anim_speed = f32(fp.attr.rebound_anim_length / f32(fp.attack_rebound))

	fp.status_vars.common.rebound.rebound_timer = f32(fp.attack_rebound)

	if fp.lr == fp.hit_lr:
		lr_rebound = -1
	else:
		lr_rebound = +1

	fp.physics.vel_ground.x = (lr_rebound * (2.0 * fp.status_vars.common.rebound.rebound_timer))
