## 1:1 port of src/gr/grcommon/grpupupu.c (Dream Land: Whispy Woods wind).
## The wind timing is driven by the anim_frame of the Whispy mouth / flower GObjs (their AnimJoint
## lengths), so the stage's animation data is part of the gameplay.
class_name Grpupupu
extends Port

## relocData symbols (tools/relocFileDescriptions.us.txt [255] GRPupupuMap)
const llGRPupupuMapWhispyEyesTransformKindsMObjSub := 0x0F00
const llGRPupupuMapMapHead := 0x10F0
const llGRPupupuMapWhispyEyesTransformKindsDObjDesc := 0x10F0
const llGRPupupuMapWhispyMouthTransformKindsMObjSub := 0x13B0
const llGRPupupuMapWhispyMouthTransformKindsDObjDesc := 0x1770
const llGRPupupuMapFlowersBackTransformKindsDObjDesc := 0x2A80
const llGRPupupuMapFlowersFrontTransformKindsDObjDesc := 0x31F8
const llGRPupupuMapWhispyEyesLeftTurnAnimJoint := 0x11A0
const llGRPupupuMapWhispyEyesLeftTurnMatAnimJoint := 0x11E0
const llGRPupupuMapWhispyEyesLeftBlinkAnimJoint := 0x12B0
const llGRPupupuMapWhispyEyesRightTurnAnimJoint := 0x1220
const llGRPupupuMapWhispyEyesRightTurnMatAnimJoint := 0x1270
const llGRPupupuMapWhispyEyesRightBlinkAnimJoint := 0x1330
const llGRPupupuMapWhispyMouthLeftStretchAnimJoint := 0x18B0
const llGRPupupuMapWhispyMouthLeftStretchMatAnimJoint := 0x1A00
const llGRPupupuMapWhispyMouthLeftTurnAnimJoint := 0x1BE0
const llGRPupupuMapWhispyMouthLeftTurnMatAnimJoint := 0x1CE0
const llGRPupupuMapWhispyMouthLeftOpenAnimJoint := 0x1E80
const llGRPupupuMapWhispyMouthLeftOpenMatAnimJoint := 0x20B0
const llGRPupupuMapWhispyMouthLeftCloseAnimJoint := 0x2100
const llGRPupupuMapWhispyMouthLeftCloseMatAnimJoint := 0x22A0
const llGRPupupuMapWhispyMouthRightStretchAnimJoint := 0x1A40
const llGRPupupuMapWhispyMouthRightStretchMatAnimJoint := 0x1BA0
const llGRPupupuMapWhispyMouthRightTurnAnimJoint := 0x1D30
const llGRPupupuMapWhispyMouthRightTurnMatAnimJoint := 0x1E30
const llGRPupupuMapWhispyMouthRightOpenAnimJoint := 0x22F0
const llGRPupupuMapWhispyMouthRightOpenMatAnimJoint := 0x2540
const llGRPupupuMapWhispyMouthRightCloseAnimJoint := 0x2590
const llGRPupupuMapWhispyMouthRightCloseMatAnimJoint := 0x2740
const llGRPupupuMapWhispyMouthLeftOpenTexture := 0x2BE0
const llGRPupupuMapWhispyMouthLeftBlowTexture := 0x2C30
const llGRPupupuMapWhispyMouthLeftCloseTexture := 0x2C80
const llGRPupupuMapWhispyMouthRightOpenTexture := 0x2CD0
const llGRPupupuMapWhispyMouthRightBlowTexture := 0x2D20
const llGRPupupuMapWhispyMouthRightCloseTexture := 0x2D70
const llGRPupupuMapWhispyEyesLeft0Texture := 0x33E0
const llGRPupupuMapWhispyEyesLeft1Texture := 0x3450
const llGRPupupuMapWhispyEyesLeft2Texture := 0x34B0
const llGRPupupuMapWhispyEyesRight0Texture := 0x3510
const llGRPupupuMapWhispyEyesRight1Texture := 0x35C0
const llGRPupupuMapWhispyEyesRight2Texture := 0x3660

## Particle bank ROM addresses (src/gr/grcommon/grpupupu.h)
const lGRPupupuParticleScriptBankLo := 0x00B1E640
const lGRPupupuParticleScriptBankHi := 0x00B1E7E0
const lGRPupupuParticleTextureBankLo := 0x00B1E7E0
const lGRPupupuParticleTextureBankHi := 0x00B1F960

# GRPUPUPU_WHISPY_* (grvars.h) come from SSBDefs.

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

const nGRPupupuWhispyWindStatusSleep := 0
const nGRPupupuWhispyWindStatusWait := 1
const nGRPupupuWhispyWindStatusTurn := 2
const nGRPupupuWhispyWindStatusOpen := 3
const nGRPupupuWhispyWindStatusBlow := 4
const nGRPupupuWhispyWindStatusStop := 5
const nGRPupupuWhispyWindStatusEnumCount := 6

const nGRPupupuWhispyMouthStatusStretch := 0
const nGRPupupuWhispyMouthStatusTurn := 1
const nGRPupupuWhispyMouthStatusOpen := 2
const nGRPupupuWhispyMouthStatusClose := 3
const nGRPupupuWhispyMouthStatusEnumCount := 4

const nGRPupupuWhispyMouthTextureOpen := 0
const nGRPupupuWhispyMouthTextureBlow := 1
const nGRPupupuWhispyMouthTextureClose := 2
const nGRPupupuWhispyMouthTextureEnumCount := 3

const nGRPupupuWhispyEyesStatusTurn := 0
const nGRPupupuWhispyEyesStatusBlink := 1
const nGRPupupuWhispyEyesStatusEnumCount := 2

const nGRPupupuWhispyEyesTexture0 := 0
const nGRPupupuWhispyEyesTexture1 := 1
const nGRPupupuWhispyEyesTexture2 := 2
const nGRPupupuWhispyEyesTextureEnumCount := 3

const nGRPupupuFlowerStatusDefault := 0
const nGRPupupuFlowerStatusWindStart := 1
const nGRPupupuFlowerStatusWindLoopStart := 2
const nGRPupupuFlowerStatusWindLoop := 3
const nGRPupupuFlowerStatusWindLoopEnd := 4
const nGRPupupuFlowerStatusWindStop := 5
const nGRPupupuFlowerStatusEnumCount := 6

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8012E870 - [lr][eyes status][AnimJoint, MatAnimJoint]
static var dGRPupupuWhispyEyesAnims: Array = [
	[[llGRPupupuMapWhispyEyesLeftTurnAnimJoint, llGRPupupuMapWhispyEyesLeftTurnMatAnimJoint], [llGRPupupuMapWhispyEyesLeftBlinkAnimJoint, 0x0]],
	[[llGRPupupuMapWhispyEyesRightTurnAnimJoint, llGRPupupuMapWhispyEyesRightTurnMatAnimJoint], [llGRPupupuMapWhispyEyesRightBlinkAnimJoint, 0x0]],
]

## 0x8012E890 - [lr][mouth status][AnimJoint, MatAnimJoint]
static var dGRPupupuWhispyMouthAnims: Array = [
	# Left-facing
	[
		[llGRPupupuMapWhispyMouthLeftStretchAnimJoint, llGRPupupuMapWhispyMouthLeftStretchMatAnimJoint],
		[llGRPupupuMapWhispyMouthLeftTurnAnimJoint, llGRPupupuMapWhispyMouthLeftTurnMatAnimJoint],
		[llGRPupupuMapWhispyMouthLeftOpenAnimJoint, llGRPupupuMapWhispyMouthLeftOpenMatAnimJoint],
		[llGRPupupuMapWhispyMouthLeftCloseAnimJoint, llGRPupupuMapWhispyMouthLeftCloseMatAnimJoint],
	],
	# Right-facing
	[
		[llGRPupupuMapWhispyMouthRightStretchAnimJoint, llGRPupupuMapWhispyMouthRightStretchMatAnimJoint],
		[llGRPupupuMapWhispyMouthRightTurnAnimJoint, llGRPupupuMapWhispyMouthRightTurnMatAnimJoint],
		[llGRPupupuMapWhispyMouthRightOpenAnimJoint, llGRPupupuMapWhispyMouthRightOpenMatAnimJoint],
		[llGRPupupuMapWhispyMouthRightCloseAnimJoint, llGRPupupuMapWhispyMouthRightCloseMatAnimJoint],
	],
]

## 0x8012E8D0
static var dGRPupupuWhispyMouthTextures: Array = [
	[llGRPupupuMapWhispyMouthLeftOpenTexture, llGRPupupuMapWhispyMouthLeftBlowTexture, llGRPupupuMapWhispyMouthLeftCloseTexture],
	[llGRPupupuMapWhispyMouthRightOpenTexture, llGRPupupuMapWhispyMouthRightBlowTexture, llGRPupupuMapWhispyMouthRightCloseTexture],
]

## 0x8012E8E8
static var dGRPupupuWhispyEyesTextures: Array = [
	[llGRPupupuMapWhispyEyesLeft0Texture, llGRPupupuMapWhispyEyesLeft1Texture, llGRPupupuMapWhispyEyesLeft2Texture],
	[llGRPupupuMapWhispyEyesRight0Texture, llGRPupupuMapWhispyEyesRight1Texture, llGRPupupuMapWhispyEyesRight2Texture],
]

## 0x8012E900 - GRPupupuEffect {pos, rotate}
static var dGRPupupuWhispyLeavesEffectAttributes: Array = [
	{"pos": Vector3(-715.0, 450.0, -696.0), "rotate": F_CLC_DTOR32(-157.0)},
	{"pos": Vector3(-205.0, 450.0, -762.0), "rotate": F_CLC_DTOR32(-13.0)},
]

## 0x8012E920
static var dGRPupupuWhispyDustEffectPositions: Array = [
	Vector3(-715.0, 100.0, 0.0),
	Vector3(-205.0, 100.0, 0.0),
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## s8 / s16 / u8 / u16 stores of GRCommonGroundVarsPupupu fields
static func _s8(v: int) -> int:
	v &= 0xFF
	return v - 0x100 if v >= 0x80 else v

static func _s16(v: int) -> int:
	v &= 0xFFFF
	return v - 0x10000 if v >= 0x8000 else v

## 0x801058E0
static func grPupupuWhispyGetLR(ground_gobj = null) -> int:
	var players_rside := 0
	var players_lside := 0

	for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		var fp := ftGetStruct(fighter_gobj)

		if fp.joints[nFTPartsJointTopN].translate.x > GRPUPUPU_WHISPY_POS_X:
			players_rside += 1
		else:
			players_lside += 1

	if players_rside == players_lside:
		return -1
	elif players_rside < players_lside:
		return 0
	else:
		return 1

## 0x8010595C
static func grPupupuWhispySetWindPush() -> void:
	var lr_wind: int = Grcommonsetup.gGRCommonStruct.pupupu.lr_players

	for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		var fp := ftGetStruct(fighter_gobj)
		var joint: DObj = fp.joints[nFTPartsJointTopN]
		var dist_x: float
		var push: Vector3
		var pos_x: float = joint.translate.x
		var pos_y: float = joint.translate.y

		if (pos_y <= GRPUPUPU_WHISPY_WINDBOX_TOP) and (pos_y >= GRPUPUPU_WHISPY_WINDBOX_BOTTOM):
			if (
				((lr_wind == 0) and (pos_x >= GRPUPUPU_WHISPY_WINDBOX_EDGELEFT) and (pos_x <= GRPUPUPU_WHISPY_POS_X)) or
				((lr_wind != 0) and (pos_x <= GRPUPUPU_WHISPY_WINDBOX_EDGERIGHT) and (pos_x >= GRPUPUPU_WHISPY_POS_X))
			):
				dist_x = -(pos_x - GRPUPUPU_WHISPY_POS_X) if (pos_x < GRPUPUPU_WHISPY_POS_X) else (pos_x - GRPUPUPU_WHISPY_POS_X)

				push.x = GRPUPUPU_WHISPY_WIND_VEL_BASE - (dist_x * GRPUPUPU_WHISPY_WIND_DIST_DECAY)

				if push.x > 0.0:
					push.z = 0.0
					push.y = 0.0

					push.x = -push.x if (lr_wind == 0) else push.x

					Ftparam.ftParamSetVelPush(fighter_gobj, push)

## 0x80105AF0
static func grPupupuWhispyUpdateSleep() -> void:
	if G.gSCManagerBattleState.game_status != nSCBattleGameStatusWait:
		Grcommonsetup.gGRCommonStruct.pupupu.whispy_status = nGRPupupuWhispyWindStatusWait

## 0x80105B18
static func grPupupuWhispyLeavesMakeEffect() -> void:
	var pupupu: Dictionary = Grcommonsetup.gGRCommonStruct.pupupu
	var pc
	var xf

	xf = null
	pc = Grdisplay.lbParticleMakeScriptID(pupupu.particle_bank_id | Grdisplay.LBPARTICLE_MASK_GENLINK(0), 0)

	if pc != null:
		xf = Grdisplay.lbParticleAddTransformForStruct(pc, nLBTransformStatusReady)

		if xf == null:
			Grdisplay.lbParticleEjectStruct(pc)
		else:
			Grdisplay.LBParticleProcessStruct(pc)

			if xf.users_num == 0:
				xf = null
			else:
				xf.translate = dGRPupupuWhispyLeavesEffectAttributes[pupupu.lr_players].pos
				xf.rotate.y = dGRPupupuWhispyLeavesEffectAttributes[pupupu.lr_players].rotate

	pupupu.leaves_xf = xf

## 0x80105BE8
static func grPupupuWhispyUpdateWait() -> void:
	var pupupu: Dictionary = Grcommonsetup.gGRCommonStruct.pupupu

	if pupupu.whispy_wind_wait != 0:
		pupupu.whispy_wind_wait = (pupupu.whispy_wind_wait - 1) & 0xFFFF   # u16
	else:
		var lr: int = grPupupuWhispyGetLR(pupupu.map_gobj[1])

		if lr == -1:   # -1 = Both sides of the map have an equal number of players
			lr = pupupu.lr_players

		if lr != pupupu.lr_players:
			pupupu.whispy_eyes_status = nGRPupupuWhispyEyesStatusTurn
			pupupu.whispy_mouth_status = nGRPupupuWhispyMouthStatusTurn
			pupupu.whispy_status = nGRPupupuWhispyWindStatusTurn
			pupupu.lr_players = _s8(lr)
		else:
			pupupu.whispy_mouth_status = nGRPupupuWhispyMouthStatusOpen
			pupupu.whispy_status = nGRPupupuWhispyWindStatusOpen

## 0x80105C70
static func grPupupuWhispyUpdateTurn() -> void:
	var pupupu: Dictionary = Grcommonsetup.gGRCommonStruct.pupupu

	if pupupu.map_gobj[1].anim_frame <= 0.0:
		pupupu.whispy_mouth_status = nGRPupupuWhispyMouthStatusOpen
		pupupu.whispy_status = nGRPupupuWhispyWindStatusOpen

## 0x80105CAC
static func grPupupuWhispyUpdateOpen() -> void:
	var pupupu: Dictionary = Grcommonsetup.gGRCommonStruct.pupupu

	if pupupu.map_gobj[1].anim_frame <= 0.0:
		pupupu.whispy_status = nGRPupupuWhispyWindStatusBlow

		pupupu.flowers_back_status = nGRPupupuFlowerStatusWindStart
		pupupu.flowers_front_status = nGRPupupuFlowerStatusWindStart

		pupupu.whispy_wind_duration = syUtilsRandIntRange(GRPUPUPU_WHISPY_WIND_DURATION_RANDOM) + GRPUPUPU_WHISPY_WIND_DURATION_BASE

		pupupu.rumble_wait = 0

		grPupupuWhispyLeavesMakeEffect()

		Snd.func_800269C0_275C0(nSYAudioFGMPupupuWhispyWind)

## 0x80105D20
static func grPupupuWhispyUpdateWindRumble() -> void:
	var pupupu: Dictionary = Grcommonsetup.gGRCommonStruct.pupupu

	if pupupu.rumble_wait == 0:
		Efmanager.efManagerQuakeMakeEffect(0)

		pupupu.rumble_wait = GRPUPUPU_WHISPY_WIND_RUMBLE_WAIT

	pupupu.rumble_wait = (pupupu.rumble_wait - 1) & 0xFF   # u8

## 0x80105D6C
static func grPupupuWhispyUpdateBlow() -> void:
	var pupupu: Dictionary = Grcommonsetup.gGRCommonStruct.pupupu

	pupupu.whispy_wind_duration = (pupupu.whispy_wind_duration - 1) & 0xFFFF   # u16

	if pupupu.whispy_wind_duration == 0:
		pupupu.whispy_mouth_status = nGRPupupuWhispyMouthStatusClose

		pupupu.flowers_back_status = nGRPupupuFlowerStatusWindLoopEnd
		pupupu.flowers_front_status = nGRPupupuFlowerStatusWindLoopEnd

		pupupu.whispy_status = nGRPupupuWhispyWindStatusStop

		if pupupu.leaves_xf != null:
			Grdisplay.lbParticleEjectStructID(pupupu.leaves_xf.generator_id, 1)

	grPupupuWhispyUpdateWindRumble()

## 0x80105DD8
static func grPupupuWhispyUpdateStop() -> void:
	var pupupu: Dictionary = Grcommonsetup.gGRCommonStruct.pupupu

	if pupupu.map_gobj[1].anim_frame <= 0.0:
		pupupu.whispy_wind_wait = syUtilsRandIntRange(GRPUPUPU_WHISPY_WAIT_DURATION_RANDOM) + GRPUPUPU_WHISPY_WAIT_DURATION_BASE
		pupupu.whispy_status = nGRPupupuWhispyWindStatusWait

## 0x80105E34
static func grPupupuWhispyUpdateBlink() -> void:
	var pupupu: Dictionary = Grcommonsetup.gGRCommonStruct.pupupu

	if (pupupu.whispy_eyes_status == -1) and (pupupu.map_gobj[0].anim_frame <= 0.0):
		pupupu.whispy_blink_wait = _s16(pupupu.whispy_blink_wait - 1)

		if (pupupu.whispy_blink_wait == 0) or (pupupu.whispy_blink_wait == -10):
			pupupu.whispy_eyes_status = nGRPupupuWhispyEyesStatusBlink

			if (pupupu.map_gobj[1].anim_frame <= 0.0) and (pupupu.whispy_status != nGRPupupuWhispyWindStatusBlow):
				pupupu.whispy_mouth_status = nGRPupupuWhispyMouthStatusStretch

			if pupupu.whispy_blink_wait != 0:
				pupupu.whispy_blink_wait = syUtilsRandIntRange(GRPUPUPU_WHISPY_BLINK_WAIT_RANDOM) + GRPUPUPU_WHISPY_BLINK_WAIT_BASE

## 0x80105EF4
static func grPupupuUpdateWhispyStatus() -> void:
	match Grcommonsetup.gGRCommonStruct.pupupu.whispy_status:
		nGRPupupuWhispyWindStatusSleep:
			grPupupuWhispyUpdateSleep()
		nGRPupupuWhispyWindStatusWait:
			grPupupuWhispyUpdateWait()
		nGRPupupuWhispyWindStatusTurn:
			grPupupuWhispyUpdateTurn()
		nGRPupupuWhispyWindStatusOpen:
			grPupupuWhispyUpdateOpen()
		nGRPupupuWhispyWindStatusBlow:
			grPupupuWhispyUpdateBlow()
		nGRPupupuWhispyWindStatusStop:
			grPupupuWhispyUpdateStop()

	grPupupuWhispyUpdateBlink()

## 0x80105F94
static func grPupupuFlowersBackWindStart() -> void:
	var pupupu: Dictionary = Grcommonsetup.gGRCommonStruct.pupupu

	pupupu.flowers_back_wait = (pupupu.flowers_back_wait - 1) & 0xFF   # u8

	if pupupu.flowers_back_wait == 0:
		pupupu.whispy_mouth_texture = 0
		pupupu.flowers_back_status = nGRPupupuFlowerStatusWindLoopStart

## 0x80105FC4
static func grPupupuFlowersBackLoopStart() -> void:
	var pupupu: Dictionary = Grcommonsetup.gGRCommonStruct.pupupu

	if pupupu.map_gobj[2].anim_frame <= 0.0:
		pupupu.whispy_mouth_texture = 1
		pupupu.flowers_back_status = nGRPupupuFlowerStatusWindLoop
		pupupu.flowers_back_wait = 15

## 0x80106008
static func grPupupuFlowersBackLoopEnd() -> void:
	var pupupu: Dictionary = Grcommonsetup.gGRCommonStruct.pupupu

	pupupu.flowers_back_wait = (pupupu.flowers_back_wait - 1) & 0xFF

	if pupupu.flowers_back_wait == 0:
		pupupu.whispy_mouth_texture = 2
		pupupu.flowers_back_status = nGRPupupuFlowerStatusWindStop
		pupupu.flowers_back_wait = 15

## 0x80106044
static func grPupupuFlowersBackUpdateAll() -> void:
	match Grcommonsetup.gGRCommonStruct.pupupu.flowers_back_status:
		nGRPupupuFlowerStatusWindStart:
			grPupupuFlowersBackWindStart()
		nGRPupupuFlowerStatusWindLoopStart:
			grPupupuFlowersBackLoopStart()
		nGRPupupuFlowerStatusWindLoopEnd:
			grPupupuFlowersBackLoopEnd()

## 0x801060B0
static func grPupupuFlowersFrontWindStart() -> void:
	var pupupu: Dictionary = Grcommonsetup.gGRCommonStruct.pupupu

	pupupu.flowers_front_wait = (pupupu.flowers_front_wait - 1) & 0xFF

	if pupupu.flowers_front_wait == 0:
		pupupu.whispy_eyes_texture = 0
		pupupu.flowers_front_status = nGRPupupuFlowerStatusWindLoopStart

## 0x801060E0
static func grPupupuWhispyDustMakeEffect() -> void:
	var pupupu: Dictionary = Grcommonsetup.gGRCommonStruct.pupupu
	var pc
	var xf

	xf = null
	pc = Grdisplay.lbParticleMakeScriptID(pupupu.particle_bank_id | Grdisplay.LBPARTICLE_MASK_GENLINK(0), 1)

	if pc != null:
		xf = Grdisplay.lbParticleAddTransformForStruct(pc, nLBTransformStatusReady)

		if xf == null:
			Grdisplay.lbParticleEjectStruct(pc)
		else:
			Grdisplay.LBParticleProcessStruct(pc)

			if xf.users_num == 0:
				xf = null
			else:
				xf.translate = dGRPupupuWhispyDustEffectPositions[pupupu.lr_players]

				xf.rotate.y = 0.0 if (pupupu.lr_players == 1) else F_CST_DTOR32(180.0)

	pupupu.dust_xf = xf

## 0x801061CC
static func grPupupuFlowersFrontLoopStart() -> void:
	var pupupu: Dictionary = Grcommonsetup.gGRCommonStruct.pupupu

	if pupupu.map_gobj[3].anim_frame <= 0.0:
		pupupu.whispy_eyes_texture = 1
		pupupu.flowers_front_status = nGRPupupuFlowerStatusWindLoop
		pupupu.flowers_front_wait = 22

		grPupupuWhispyDustMakeEffect()

## 0x80106220
static func grPupupuFlowersFrontLoopEnd() -> void:
	var pupupu: Dictionary = Grcommonsetup.gGRCommonStruct.pupupu

	pupupu.flowers_front_wait = (pupupu.flowers_front_wait - 1) & 0xFF

	if pupupu.flowers_front_wait == 0:
		pupupu.whispy_eyes_texture = 2
		pupupu.flowers_front_status = nGRPupupuFlowerStatusWindStop
		pupupu.flowers_front_wait = 22

		if pupupu.dust_xf != null:
			Grdisplay.lbParticleEjectStructID(pupupu.dust_xf.generator_id, 1)
	else:
		grPupupuWhispySetWindPush()

## 0x80106290
static func grPupupuFlowersFrontUpdateAll() -> void:
	match Grcommonsetup.gGRCommonStruct.pupupu.flowers_front_status:
		nGRPupupuFlowerStatusWindStart:
			grPupupuFlowersFrontWindStart()
		nGRPupupuFlowerStatusWindLoopStart:
			grPupupuFlowersFrontLoopStart()
		nGRPupupuFlowerStatusWindLoop:
			grPupupuWhispySetWindPush()
		nGRPupupuFlowerStatusWindLoopEnd:
			grPupupuFlowersFrontLoopEnd()

## 0x80106314
static func grPupupuUpdateGObjAnims() -> void:
	var pupupu: Dictionary = Grcommonsetup.gGRCommonStruct.pupupu
	var map_head = pupupu.map_head

	if pupupu.whispy_eyes_status != -1:
		var offset: int = dGRPupupuWhispyEyesAnims[pupupu.lr_players][pupupu.whispy_eyes_status][1]

		Grdisplay.gcAddAnimAll(
			pupupu.map_gobj[0],
			Grdisplay.grDisplayPtrAdd(map_head, dGRPupupuWhispyEyesAnims[pupupu.lr_players][pupupu.whispy_eyes_status][0]),
			Grdisplay.grDisplayPtrAdd(map_head, offset) if (offset != 0) else null,
			0.0
		)
		Grdisplay.gcPlayAnimAll(pupupu.map_gobj[0])

		pupupu.whispy_eyes_status = -1

	if pupupu.whispy_mouth_status != -1:
		Grdisplay.gcAddAnimAll(
			pupupu.map_gobj[1],
			Grdisplay.grDisplayPtrAdd(map_head, dGRPupupuWhispyMouthAnims[pupupu.lr_players][pupupu.whispy_mouth_status][0]),
			Grdisplay.grDisplayPtrAdd(map_head, dGRPupupuWhispyMouthAnims[pupupu.lr_players][pupupu.whispy_mouth_status][1]),
			0.0
		)
		Grdisplay.gcPlayAnimAll(pupupu.map_gobj[1])

		pupupu.whispy_mouth_status = -1

	if pupupu.whispy_mouth_texture != -1:
		Grdisplay.gcAddAnimJointAll(
			pupupu.map_gobj[2],
			Grdisplay.grDisplayPtrAdd(map_head, dGRPupupuWhispyMouthTextures[pupupu.lr_players][pupupu.whispy_mouth_texture]),
			0.0
		)
		Grdisplay.gcPlayAnimAll(pupupu.map_gobj[2])

		pupupu.whispy_mouth_texture = -1

	if pupupu.whispy_eyes_texture != -1:
		Grdisplay.gcAddAnimJointAll(
			pupupu.map_gobj[3],
			Grdisplay.grDisplayPtrAdd(map_head, dGRPupupuWhispyEyesTextures[pupupu.lr_players][pupupu.whispy_eyes_texture]),
			0.0
		)
		Grdisplay.gcPlayAnimAll(pupupu.map_gobj[3])

		pupupu.whispy_eyes_texture = -1

## 0x80106490
static func grPupupuProcUpdate(ground_gobj = null) -> void:
	grPupupuUpdateWhispyStatus()
	grPupupuFlowersBackUpdateAll()
	grPupupuFlowersFrontUpdateAll()
	grPupupuUpdateGObjAnims()

## 0x801064C8 - proc_display: Callable
static func grPupupuMakeMapGObj(o_dobjdesc = null, o_mobjsub = null, proc_display = null, dl_link = null):
	var map_head = Grcommonsetup.gGRCommonStruct.pupupu.map_head
	var ground_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindGround, null, nGCCommonLinkIDGround, GOBJ_PRIORITY_DEFAULT)

	Objman.gcAddGObjDisplay(ground_gobj, proc_display, dl_link, GOBJ_PRIORITY_DEFAULT, ~0)

	Grdisplay.gcSetupCustomDObjs(
		ground_gobj,
		Grdisplay.grDisplayPtrAdd(map_head, o_dobjdesc),
		null,
		nGCMatrixKindTraRotRpyRSca,
		nGCMatrixKindNull,
		nGCMatrixKindNull
	)
	if o_mobjsub != 0:
		Grdisplay.gcAddMObjAll(ground_gobj, Grdisplay.grDisplayPtrAdd(map_head, o_mobjsub))

	Objman.gcAddGObjProcess(ground_gobj, Callable(Grdisplay, &"gcPlayAnimAll"), nGCProcessKindFunc, 5)

	return ground_gobj

## 0x8010658C
static func grPupupuInitAll() -> void:
	var pupupu: Dictionary = Grcommonsetup.gGRCommonStruct.pupupu
	var gMPCollisionGroundData: Dictionary = Grdisplay.grDisplayGetGroundData()

	pupupu.map_head = Grdisplay.grDisplayPtrAdd(gMPCollisionGroundData.map_nodes, -llGRPupupuMapMapHead)
	pupupu.map_gobj[0] = grPupupuMakeMapGObj(llGRPupupuMapMapHead, llGRPupupuMapWhispyEyesTransformKindsMObjSub, Callable(Grdisplay, &"grDisplayLayer0PriProcDisplay"), 4)
	pupupu.map_gobj[1] = grPupupuMakeMapGObj(llGRPupupuMapWhispyMouthTransformKindsDObjDesc, llGRPupupuMapWhispyMouthTransformKindsMObjSub, Callable(Grdisplay, &"grDisplayLayer0PriProcDisplay"), 4)
	pupupu.map_gobj[2] = grPupupuMakeMapGObj(llGRPupupuMapFlowersBackTransformKindsDObjDesc, 0x0, Callable(Grdisplay, &"grDisplayLayer0PriProcDisplay"), 4)
	pupupu.map_gobj[3] = grPupupuMakeMapGObj(llGRPupupuMapFlowersFrontTransformKindsDObjDesc, 0x0, Callable(Grdisplay, &"grDisplayLayer3PriProcDisplay"), 16)

	pupupu.whispy_eyes_status = -1
	pupupu.whispy_mouth_status = -1
	pupupu.whispy_mouth_texture = -1
	pupupu.whispy_eyes_texture = -1

	pupupu.whispy_status = 0

	pupupu.lr_players = 1

	pupupu.whispy_wind_wait = syUtilsRandIntRange(GRPUPUPU_WHISPY_WAIT_DURATION_RANDOM) + GRPUPUPU_WHISPY_WAIT_DURATION_BASE
	pupupu.whispy_blink_wait = syUtilsRandIntRange(GRPUPUPU_WHISPY_BLINK_WAIT_RANDOM) + GRPUPUPU_WHISPY_BLINK_WAIT_BASE

	pupupu.flowers_back_status = 0
	pupupu.flowers_front_status = 0

	pupupu.flowers_back_wait = 15
	pupupu.flowers_front_wait = 22

	pupupu.particle_bank_id = Grdisplay.efParticleGetLoadBankID(lGRPupupuParticleScriptBankLo, lGRPupupuParticleScriptBankHi, lGRPupupuParticleTextureBankLo, lGRPupupuParticleTextureBankHi)

## 0x801066D4
static func grPupupuMakeGround():
	var ground_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindGround, null, nGCCommonLinkIDGround, GOBJ_PRIORITY_DEFAULT)

	Objman.gcAddGObjProcess(ground_gobj, Callable(Grpupupu, &"grPupupuProcUpdate"), nGCProcessKindFunc, 4)
	grPupupuInitAll()

	return ground_gobj

# BEGIN GENERATED FILE IMAGES (tools/port/gr/gen_gr_file_images.py - do not edit by hand)
## relocData words read by the ground code, from baserom.us.z64 (US v1.0, SHA-1 e2929e10fccc0aa84e5776227e798abc07cedabf).
## Same bytes as the typed C in sources/ssb-decomp-re/src/relocData/<file>.c. "w": {byte_offset: [u32 words]},
## "p": relocated pointer slots {byte_offset: [file_id, byte_offset, kind]} (kind 1 AObjEvent32, 2 SYInterpDesc, 0 other).
const dGRPupupuFileImages: Array = [
	{"fid": 104, "name": "StagePupupuFile2", "w": {
		0x1008: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0x00000000, 0x44BF4000, 0xC4E10000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00002001, 0x00000000, 0xC497E000, 0x00000000, 0xC4C56CAD, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002001, 0x00000000, 0x44951000, 0x00000000,
			0xC4B84CAD, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001,
			0x00000000, 0xC4034000, 0x00000000, 0xC4986CAD, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x00002002, 0x00000000, 0xBDE9E7FB, 0x00000000, 0xBDA26C3C, 0x00000000,
			0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000,
			0x00000002, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00002001, 0x00000000, 0xC4CE52ED, 0x00000000, 0xC427AB05, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00002001, 0x00000000, 0x44CE464F, 0x00000000,
			0xC40C9BE1, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x00004001, 0x00000000, 0xC51D4A6D, 0x45175A4F, 0xC480000F, 0x00000000,
			0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00004001, 0x00000000, 0x4513B005,
			0x4502B21A, 0xC442A0EE, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000,
			0x00004001, 0x00000000, 0x44C621B3, 0x453631B1, 0xC43F1BF0, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00004001, 0x00000000, 0xC4B821C4, 0x452A5635, 0xC427852A,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00004001, 0x00000000,
			0x42D154C1, 0x451561B1, 0xC402DC02, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00004001, 0x00000000, 0xC4728EB6, 0x44E94438, 0xC3E65606, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000],
		0x1CE0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000],
		0x2450: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0xC3D98000, 0x00000000, 0x445D4000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000001, 0x00000000, 0x4446C000, 0x00000000, 0x44870000, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x2BF8: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0xC21A39DB, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0x00000000, 0xC21A39DB, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		}, "p": {
		0x100C: [104, 0x06C0, 0],
		0x1038: [104, 0x0798, 0],
		0x1064: [104, 0x0820, 0],
		0x1090: [104, 0x08A8, 0],
		0x10BC: [104, 0x0928, 0],
		0x1114: [104, 0x0950, 0],
		0x1140: [104, 0x0980, 0],
		0x116C: [104, 0x0A18, 0],
		0x1198: [104, 0x0A38, 0],
		0x11C4: [104, 0x0A58, 0],
		0x11F0: [104, 0x0A78, 0],
		0x121C: [104, 0x0B18, 0],
		0x1248: [104, 0x0B40, 0],
		0x1274: [104, 0x0C38, 0],
		0x12A0: [104, 0x0CC0, 0],
		0x12CC: [104, 0x0D20, 0],
		0x12F8: [104, 0x0D80, 0],
		0x1324: [104, 0x0DE0, 0],
		0x1350: [104, 0x0E40, 0],
		0x137C: [104, 0x0EA0, 0],
		0x1D10: [104, 0x18E0, 0],
		0x2480: [104, 0x21E8, 0],
		0x24AC: [104, 0x22C8, 0],
		0x24D8: [104, 0x2380, 0],
		0x2C28: [104, 0x2970, 0],
		0x2C54: [104, 0x2A48, 0],
		0x2C80: [104, 0x2A68, 0],
		}},
	{"fid": 152, "name": "StagePupupuFile3", "w": {
		0x0F00: [0x00000000, 0x00000000, 0x00000000],
		0x0F18: [0x00000202, 0x00000000, 0x00200000, 0x00200020, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x00000000, 0x3F800000, 0x00000000, 0x00010200, 0x00100020, 0x00200020, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00002005, 0xFFFFFFFF, 0x00000000, 0x000000FF, 0x00000000,
			0xFFFFFF00, 0x80808000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x10F0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0xC4034000, 0x433B8000, 0xC4986CA4,
			0x00000000, 0x3F1C61A6, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000,
			0x39345AE6, 0x443B8000, 0x43D5C002, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000012, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x06010000,
			0x3F1C61AA, 0x06010019, 0xBEB2B8C2, 0x00000000, 0x06010000, 0x3F1C61AA, 0x06010019, 0xBEB2B8C2,
			0x00000000],
		0x11E0: [0x00000000, 0x00000000, 0x00000000, 0x14008000, 0x00000000, 0x16008157, 0x3F800000, 0x1800814A,
			0x0400000D, 0x16008018, 0x00000000, 0x0400000C, 0x00000000, 0x00000000],
		0x1220: [0x00000000, 0x00000000, 0x00000000, 0x06010000, 0xBEB2B8C2, 0x0601001E, 0x3F1C61AA, 0x00000000,
			0x06400000, 0x3F800000, 0x14800000, 0x3F800000, 0x084000F0, 0x3F800000, 0x184000AF, 0x0400001E,
			0x00000000],
		0x1270: [0x00000000, 0x00000000, 0x00000000, 0x14008000, 0x3F800000, 0x16008018, 0x00000000, 0x1800800C,
			0x0400000C, 0x16008024, 0x3F800000, 0x04000012, 0x00000000, 0x00000000],
		0x12B0: [0x00000000, 0x00000000, 0x00000000, 0x14010000, 0xBEB2B8C2, 0x1800000A, 0x0400000C, 0x00000000,
			0x12800000, 0x3F800000, 0x14400000, 0x3F800000, 0x0C800005, 0x3DD480C1, 0xBE83F6ED, 0x14400005,
			0x3F99999A, 0x16400002, 0x3F800000, 0x06800002, 0x3DD4801F, 0x0E800000, 0x3E84D0EC, 0x0C800005,
			0x3F800000, 0x3401999A, 0x14400005, 0x3F800000, 0x00000000],
		0x1330: [0x00000000, 0x00000000, 0x00000000, 0x06010000, 0x3F1C61AA, 0x0801014A, 0x3F1C61AA, 0x18010001,
			0x0400000C, 0x00000000, 0x12800000, 0x3F800000, 0x14400000, 0x3F800000, 0x0C800005, 0x3DD480C1,
			0xBE83F6ED, 0x14400005, 0x3F99999A, 0x16400002, 0x3F800000, 0x06800002, 0x3DD4801F, 0x0E800000,
			0x3E84D0EC, 0x0C800005, 0x3F800000, 0x3401999A, 0x14400005, 0x3F800000, 0x00000000],
		0x13B0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x13D8: [0x00000202, 0x00000000, 0x00200000, 0x00100020, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x00000000, 0x3F800000, 0x00000000, 0x00010200, 0x00100020, 0x00100020, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00002005, 0xFFFFFFFF, 0x00000000, 0x000000FF, 0x00000000,
			0xFFFFFF00, 0x80808000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x1770: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0xC4034000, 0x433B8000, 0xC4986CA4,
			0x00000000, 0x3F1C61A6, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000,
			0x00000000, 0x43FF0000, 0x43F3C000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000002, 0x00000000, 0x00000000, 0x43834000, 0x43EC4000, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000, 0xC34A8000, 0x439D8000,
			0x43D20000, 0x00000000, 0x00000000, 0x00000000, 0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x00000002,
			0x00000000, 0x434A8000, 0x439D8000, 0x43D20000, 0x00000000, 0x00000000, 0x00000000, 0x3727C5AC,
			0x3727C5AC, 0x3727C5AC, 0x00000012, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x18B0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x14010000, 0xBEB2B8C2,
			0x1800000A, 0x0400000C, 0x00000000, 0x06200000, 0x43F3C000, 0x0820015E, 0x43F3C000, 0x1820010E,
			0x12100000, 0x43FF0000, 0x06008000, 0x00000000, 0x0800802C, 0x00000000, 0x10100006, 0x44024EF4,
			0x10100006, 0x43FF0000, 0x00000000, 0x06200000, 0x43EC4000, 0x082000D0, 0x43EC4000, 0x1820007F,
			0x17000000, 0x3F800000, 0x12900000, 0x43834000, 0x3F800000, 0x06400000, 0x3F800000, 0x0840002C,
			0x3F800000, 0x0A900005, 0x43A14000, 0x41092492, 0x3F4A3D71, 0xBCF5C28D, 0x0A900002, 0x43A14000,
			0xC1092492, 0x3F4A3D71, 0x3CF5C28E, 0x10900005, 0x43834000, 0x3F800000, 0x00000000, 0x17F80000,
			0xC34A8000, 0x439D8000, 0x43D20000, 0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x0400000C, 0x00000000,
			0x06200000, 0x43D20000, 0x15D80000, 0x434A8000, 0x439D8000, 0x3727C5AC, 0x3727C5AC, 0x3727C5AC,
			0x082001F3, 0x43D20000, 0x182001A3, 0x17C001F4, 0x3F800000, 0x3F800000, 0x3F800000, 0x19C001A3,
			0x0400000C, 0x00000000],
		0x1A00: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x14008000, 0x40000000,
			0x1600806B, 0x40400000, 0x18008011, 0x0400000C, 0x00000000, 0x00000000],
		0x1A40: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x06010000, 0x3F1C61AA,
			0x0801014A, 0x3F1C61AA, 0x18010001, 0x0400000C, 0x00000000, 0x12100000, 0x43FF0000, 0x06208000,
			0x00000000, 0x43F3C000, 0x0800802C, 0x00000000, 0x08200050, 0x43F3C000, 0x10100006, 0x44024EF4,
			0x10100006, 0x43FF0000, 0x00000000, 0x17000000, 0x3F800000, 0x12900000, 0x43834000, 0x3F800000,
			0x06600000, 0x43EC4000, 0x3F800000, 0x0840002C, 0x3F800000, 0x08200051, 0x43EC4000, 0x0A900005,
			0x43A14000, 0x41092492, 0x3F4A3D71, 0xBCF5C28D, 0x0A900002, 0x43A14000, 0xC1092492, 0x3F4A3D71,
			0x3CF5C28E, 0x10900005, 0x43834000, 0x3F800000, 0x00000000, 0x17D80000, 0xC34A8000, 0x439D8000,
			0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x06200000, 0x43D20000, 0x08200050, 0x43D20000, 0x17C00051,
			0x3F800000, 0x3F800000, 0x3F800000, 0x0400000C, 0x00000000, 0x17D80000, 0x434A8000, 0x439D8000,
			0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x06200000, 0x43D20000, 0x082001F3, 0x43D20000, 0x17C001F4,
			0x3F800000, 0x3F800000, 0x3F800000, 0x0400000C, 0x00000000],
		0x1BA0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x14008000, 0x00000000,
			0x1600805B, 0x3F800000, 0x18008001, 0x0400000C, 0x00000000, 0x00000000],
		0x1BE0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x06010000, 0x3F1C61AA,
			0x06010019, 0xBEB2B8C2, 0x00000000, 0x06100000, 0x43FF0000, 0x08100150, 0x43FF0000, 0x181000F6,
			0x06200000, 0x43F3C000, 0x0820015E, 0x43F3C000, 0x182000B4, 0x14008000, 0x00000000, 0x18000088,
			0x04000019, 0x00000000, 0x14180000, 0xC34A8000, 0x439D8000, 0x0BE00000, 0x43D20000, 0xBFBE5D84,
			0x3727C5AC, 0xBB41E43D, 0x3727C5AC, 0xBB41E43D, 0x3727C5AC, 0xBB41E43D, 0x13E00087, 0x43D20000,
			0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x19E0002D, 0x04000019, 0x00000000, 0x06200000, 0x43D20000,
			0x15D80000, 0x434A8000, 0x439D8000, 0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x082001F3, 0x43D20000,
			0x18200149, 0x17C001F4, 0x3F800000, 0x3F800000, 0x3F800000, 0x19C00149, 0x04000019, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x14008000, 0x00000000,
			0x1600803F, 0x40000000, 0x18008032, 0x0400000D, 0x16008018, 0x00000000, 0x0400000C, 0x00000000,
			0x00000000],
		0x1D30: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x06010000, 0xBEB2B8C2,
			0x0601001E, 0x3F1C61AA, 0x00000000, 0x06100000, 0x43FF0000, 0x08100150, 0x43FF0000, 0x1810010F,
			0x06200000, 0x43F3C000, 0x0820015E, 0x43F3C000, 0x182000CD, 0x14008000, 0x00000000, 0x180000A1,
			0x0400001E, 0x00000000, 0x14180000, 0xC34A8000, 0x439D8000, 0x0BE00000, 0x43D20000, 0xBFBE5D84,
			0x3727C5AC, 0xBB41E43D, 0x3727C5AC, 0xBB41E43D, 0x3727C5AC, 0xBB41E43D, 0x13E00087, 0x43D20000,
			0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x19E00046, 0x0400001E, 0x00000000, 0x06200000, 0x43D20000,
			0x15D80000, 0x434A8000, 0x439D8000, 0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x082001F3, 0x43D20000,
			0x18200162, 0x17C001F4, 0x3F800000, 0x3F800000, 0x3F800000, 0x19C00162, 0x0400001E, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x14008000, 0x40000000,
			0x16008018, 0x00000000, 0x1800800C, 0x0400000C, 0x16008024, 0x40000000, 0x04000012, 0x00000000,
			0x00000000],
		0x1E80: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x14010000, 0xBEB2B8C2,
			0x18000036, 0x04000036, 0x00000000, 0x06200000, 0x43F3C000, 0x0820015E, 0x43F3C000, 0x1820013A,
			0x0A108000, 0x00000000, 0xBB5E596C, 0x43FF0000, 0x3F15DA7F, 0x0C00801A, 0xBD84410B, 0xB7500A62,
			0x10100015, 0x44058000, 0x0C100012, 0x43FF0000, 0xBD8AD8EA, 0x04000005, 0x0C008015, 0x00000000,
			0x3BA39BC0, 0x0400000A, 0x0E200000, 0x3F8EF34D, 0x12200039, 0x43FF4582, 0x04000003, 0x0810000F,
			0x43FF0000, 0x04000008, 0x06008001, 0x00000000, 0x06008006, 0x00000000, 0x00000000, 0x06200000,
			0x43EC4000, 0x082000D0, 0x43EC4000, 0x182000AB, 0x15000000, 0x3F800000, 0x06100000, 0x43834000,
			0x0810004A, 0x43834000, 0x18100014, 0x0AC00000, 0x3F800000, 0x3EE8F217, 0x3F800000, 0x3CEFCDF2,
			0x12800013, 0x3F9DB963, 0x0A40000A, 0x40400000, 0x3CA70710, 0x0C400012, 0x40400000, 0xBCA7CD11,
			0x04000009, 0x0C800013, 0x3F800000, 0xBD11C6FF, 0x04000009, 0x0C40000A, 0x3F800000, 0xBD80E8ED,
			0x04000009, 0x0E200000, 0x4087C371, 0x0C200011, 0x440AC000, 0x3D5802C1, 0x04000001, 0x0AC0000F,
			0x3F333333, 0xBA602D43, 0x3EC44674, 0xBB701489, 0x08C000AF, 0x3F333333, 0x3EC44674, 0x04000001,
			0x00000000, 0x15F80000, 0xC34A8000, 0x439D8000, 0x43D20000, 0x3727C5AC, 0x3727C5AC, 0x3727C5AC,
			0x1800002C, 0x04000036, 0x00000000, 0x06200000, 0x43D20000, 0x15D80000, 0x434A8000, 0x439D8000,
			0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x082001F3, 0x43D20000, 0x182001CF, 0x17C001F4, 0x3F800000,
			0x3F800000, 0x3F800000, 0x19C001CF, 0x04000024, 0x0E200000, 0x3DEE9A17, 0x0C200010, 0x43F00000,
			0x3EA0D042, 0x04000001, 0x17C000CB, 0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x0400000F, 0x082000AD,
			0x43EFAE70, 0x04000002, 0x00000000],
		0x20B0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x14008000, 0x40000000,
			0x1600806B, 0x40400000, 0x1800803D, 0x0400002E, 0x160080BC, 0x40000000, 0x04000008, 0x00000000,
			0x00000000],
		0x2100: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x14010000, 0xBEB2B8C2,
			0x1800011A, 0x04000014, 0x00000000, 0x06100000, 0x43FF0000, 0x081000D1, 0x43FF0000, 0x181000BD,
			0x14008000, 0x00000000, 0x06200000, 0x43F3C000, 0x0820008F, 0x43F3C000, 0x1820007B, 0x04000014,
			0x00000000, 0x15000000, 0x3F800000, 0x06100000, 0x43834000, 0x0810010C, 0x43834000, 0x181000F8,
			0x0A200000, 0x440AC000, 0x3D5802C1, 0x0C2000B1, 0x440AC000, 0xBD543ED6, 0x182000AE, 0x06C00000,
			0x3F333333, 0x3EC44674, 0x08C0000A, 0x3F800000, 0x3F800000, 0x04000003, 0x0C200011, 0x43EC4000,
			0xBF12AAAA, 0x04000007, 0x0E400000, 0x3B05BF39, 0x12400001, 0x3F800000, 0x06800001, 0x3F800000,
			0x06C00009, 0x3F800000, 0x3F800000, 0x00000000, 0x15F80000, 0xC34A8000, 0x439D8000, 0x43D20000,
			0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x18000110, 0x04000014, 0x00000000, 0x15C00000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x17C000CB, 0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x19C000BF, 0x14180000,
			0x434A8000, 0x439D8000, 0x0A200000, 0x43EFAE70, 0xBEA3677E, 0x0C20000F, 0x43D20000, 0xBFBE5D84,
			0x18200003, 0x0400000C, 0x0FC00000, 0xBB41E43D, 0xBB41E43D, 0xBB41E43D, 0x13E00087, 0x43D20000,
			0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x04000008, 0x00000000],
		0x22A0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x14008000, 0x40400000,
			0x160080BC, 0x40000000, 0x180080B6, 0x04000006, 0x16008066, 0x40000000, 0x0400000E, 0x00000000,
			0x00000000],
		0x22F0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x06010000, 0x3F1C61AA,
			0x0801014A, 0x3F1C61AA, 0x1801002D, 0x04000036, 0x00000000, 0x06200000, 0x43F3C000, 0x08200050,
			0x43F3C000, 0x1820002C, 0x0A108000, 0x00000000, 0xBB5E596C, 0x43FF0000, 0x3F15DA7F, 0x0C00801A,
			0xBD84410B, 0xB7500A62, 0x10100015, 0x44058000, 0x0C100012, 0x43FF0000, 0xBD8AD8EA, 0x04000005,
			0x0C008015, 0x00000000, 0x3BA39BC0, 0x0400000A, 0x0E200000, 0x3F8EF34D, 0x12200039, 0x43FF4582,
			0x04000003, 0x08100150, 0x43FF0000, 0x04000008, 0x08008066, 0x00000000, 0x04000007, 0x00000000,
			0x06200000, 0x43EC4000, 0x08200051, 0x43EC4000, 0x1820002C, 0x06100000, 0x43834000, 0x0810018B,
			0x43834000, 0x18100014, 0x0CC00000, 0x3F800000, 0x3EE8F217, 0x3F800000, 0x3CEFCDF2, 0x15000000,
			0x3F800000, 0x12800013, 0x3F9DB963, 0x0A40000A, 0x40400000, 0x3CA70710, 0x0C400012, 0x40400000,
			0xBCA7CD11, 0x04000009, 0x0C800013, 0x3F800000, 0xBD11C6FF, 0x04000009, 0x0C40000A, 0x3F800000,
			0xBD80E8ED, 0x04000009, 0x0E200000, 0x4087C371, 0x0C200011, 0x440AC000, 0x3D5802C1, 0x04000001,
			0x0AC0000F, 0x3F333333, 0xBA602D43, 0x3EC44674, 0xBB701489, 0x08C000AF, 0x3F333333, 0x3EC44674,
			0x04000001, 0x00000000, 0x06200000, 0x43D20000, 0x15D80000, 0xC34A8000, 0x439D8000, 0x3727C5AC,
			0x3727C5AC, 0x3727C5AC, 0x08200050, 0x43D20000, 0x1820002C, 0x17C00051, 0x3F800000, 0x3F800000,
			0x3F800000, 0x19C0002C, 0x04000024, 0x0E200000, 0x3F200000, 0x0C200010, 0x43F00000, 0x3EA0D041,
			0x04000001, 0x17C000CB, 0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x0400000F, 0x082000AD, 0x43EFAE70,
			0x04000002, 0x00000000, 0x06200000, 0x43D20000, 0x15D80000, 0x434A8000, 0x439D8000, 0x3727C5AC,
			0x3727C5AC, 0x3727C5AC, 0x082001F3, 0x43D20000, 0x1820002C, 0x17C001F4, 0x3F800000, 0x3F800000,
			0x3F800000, 0x19C0002C, 0x04000036, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x14008000, 0x00000000, 0x1600805B, 0x3F800000, 0x1800802D, 0x0400002E,
			0x160080BD, 0x00000000, 0x04000008, 0x00000000, 0x00000000],
		0x2590: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x06010000, 0x3F1C61AA,
			0x0801014A, 0x3F1C61AA, 0x18010111, 0x04000014, 0x00000000, 0x06100000, 0x43FF0000, 0x08100150,
			0x43FF0000, 0x181000BD, 0x06200000, 0x43F3C000, 0x0820015E, 0x43F3C000, 0x1820007B, 0x14008000,
			0x00000000, 0x1800004F, 0x04000014, 0x00000000, 0x06100000, 0x43834000, 0x0810018B, 0x43834000,
			0x181000F8, 0x0A200000, 0x440AC000, 0x3D5802C1, 0x0C2000B1, 0x440AC000, 0xBD543ED6, 0x182000AE,
			0x08C00000, 0x3F333333, 0x3EC44674, 0x17000000, 0x3F800000, 0x08C0000A, 0x3F800000, 0x3F800000,
			0x04000003, 0x0C200011, 0x43EC4000, 0xBEBBBBBA, 0x04000007, 0x08400088, 0x3F80002D, 0x08800089,
			0x3F800000, 0x0400000A, 0x00000000, 0x15C00000, 0x3F800000, 0x3F800000, 0x3F800000, 0x17C000CB,
			0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x19C000BF, 0x14180000, 0xC34A8000, 0x439D8000, 0x0A200000,
			0x43EFAE70, 0xBEA3677E, 0x0C20000F, 0x43D20000, 0xBFBE5D84, 0x18200003, 0x0400000C, 0x0FC00000,
			0xBB41E43D, 0xBB41E43D, 0xBB41E43D, 0x13E00087, 0x43D20000, 0x3727C5AC, 0x3727C5AC, 0x3727C5AC,
			0x04000008, 0x00000000, 0x06200000, 0x43D20000, 0x15D80000, 0x434A8000, 0x439D8000, 0x3727C5AC,
			0x3727C5AC, 0x3727C5AC, 0x082001F3, 0x43D20000, 0x18200110, 0x17C001F4, 0x3F800000, 0x3F800000,
			0x3F800000, 0x19C00110, 0x04000014, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x14008000, 0x3F800000, 0x160080BD, 0x00000000, 0x180080B6, 0x04000007,
			0x1600803F, 0x40000000, 0x0400000D, 0x00000000, 0x00000000],
		0x2A80: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0xC4942000, 0x00000000, 0xC39832B6,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000,
			0x00000000, 0xC2160000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000003, 0x00000000, 0x00000000, 0x432C8000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x44160000, 0x00000000,
			0xC37BE56D, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002,
			0x00000000, 0x00000000, 0xC2160000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x00000003, 0x00000000, 0x00000000, 0x432C8000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x10180000,
			0x00000000, 0x432C8000, 0x0A180010, 0xC3340000, 0xC0CDB6CD, 0x42D20000, 0xBFE49239, 0x10180005,
			0xC3070000, 0x43070000, 0x00000000],
		0x2C30: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x10180000,
			0xC3070000, 0x43070000, 0x10180005, 0xC3340000, 0x42D20000, 0x10180005, 0xC3070000, 0x43070000,
			0x1C000000, 0x00000000],
		0x2C80: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x10180000,
			0xC3070000, 0x43070000, 0x0A180005, 0xC3340000, 0x40CDB6CD, 0x42D20000, 0x3FE49239, 0x10180010,
			0x00000000, 0x432C8000, 0x00000000],
		0x2CD0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x10180000,
			0x00000000, 0x432C8000, 0x0A180010, 0x43340000, 0x40CDB6DB, 0x42D20000, 0xBFE49249, 0x10180005,
			0x43070000, 0x43070000, 0x00000000],
		0x2D20: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x10180000,
			0x43070000, 0x43070000, 0x10180005, 0x43340000, 0x42D20000, 0x10180005, 0x43070000, 0x43070000,
			0x1C000000, 0x00000000],
		0x2D70: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x10180000,
			0x43070000, 0x43070000, 0x0A180005, 0x43340000, 0xC0CDB6DF, 0x42D20000, 0x3FE49239, 0x10180010,
			0x00000000, 0x432C8000, 0x00000000],
		0x31F8: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F7FFFEF, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x4471E000, 0x00000000, 0x43CC0D4A,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000,
			0x00000000, 0xC2160000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000003, 0x00000000, 0x00000000, 0x432C8000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0xC4C12000, 0x00000000,
			0x43F54D4A, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002,
			0x00000000, 0x00000000, 0xC2160000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x00000003, 0x00000000, 0x00000000, 0x432C8000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x44A41000,
			0x00000000, 0x444966A5, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000,
			0x00000002, 0x00000000, 0x00000000, 0xC2160000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000003, 0x00000000, 0x00000000, 0x432C8000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000],
		0x33E0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x06180000, 0x00000000, 0x432C8000, 0x06180010, 0x00000000, 0x432C8000,
			0x0A180010, 0xC3340000, 0xC0CDB6CD, 0x42D20000, 0xBFE49239, 0x10180005, 0xC3070000, 0x43070000,
			0x00000000],
		0x3450: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x10180000, 0xC3070000, 0x43070000, 0x10180005, 0xC3340000, 0x42D20000,
			0x10180005, 0xC3070000, 0x43070000, 0x1C000000, 0x00000000],
		0x34B0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x10180000, 0xC3070000, 0x43070000, 0x0A180005, 0xC3340000, 0x40CDB6CD,
			0x42D20000, 0x3FE49239, 0x10180010, 0x00000000, 0x432C8000, 0x00000000],
		0x3510: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x10180000, 0x00000000, 0x432C8000, 0x0A180010, 0x43340000, 0x40CDB6DF,
			0x42D20000, 0xBFE4924D, 0x10180005, 0x43070000, 0x43070000, 0x12180005, 0x43340000, 0x42D20000,
			0x04000004, 0x00000000, 0x06180000, 0x00000000, 0x432C8000, 0x06180004, 0x00000000, 0x432C8000,
			0x0A180010, 0x43340000, 0x40CDB6DB, 0x42D20000, 0xBFE49249, 0x10180005, 0x43070000, 0x43070000,
			0x00000000],
		0x35C0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x10180000, 0x43070000, 0x43070000, 0x10180005, 0x43340000, 0x42D20000,
			0x10180005, 0x43070000, 0x43070000, 0x1C000000, 0x00000000, 0x10180000, 0x43070000, 0x43070000,
			0x12180005, 0x43340000, 0x42D20000, 0x18180002, 0x04000003, 0x10180005, 0x43070000, 0x43070000,
			0x12180005, 0x43340000, 0x42D20000, 0x04000002, 0x1C000000, 0x00000000],
		0x3660: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x10180000, 0x43070000, 0x43070000, 0x0C180005, 0x43340000, 0xC0CDB6DF,
			0x42D20000, 0x3FE4924D, 0x18180004, 0x04000001, 0x10180010, 0x00000000, 0x432C8000, 0x06180004,
			0x00000000, 0x432C8000, 0x00000000, 0x10180000, 0x43070000, 0x43070000, 0x0A180005, 0x43340000,
			0xC0CDB6F1, 0x42D20000, 0x3FE49262, 0x10180010, 0x00000000, 0x432C8000, 0x00000000],
		}, "p": {
		0x0F08: [152, 0x0F90, 0],
		0x0F1C: [152, 0x0F0C, 0],
		0x0F90: [152, 0x0F18, 0],
		0x114C: [152, 0x0FF8, 0],
		0x11A4: [152, 0x11AC, 1],
		0x11A8: [152, 0x11C0, 1],
		0x11E8: [152, 0x1214, 0],
		0x1214: [152, 0x11EC, 1],
		0x1224: [152, 0x122C, 1],
		0x1228: [152, 0x1240, 1],
		0x1278: [152, 0x12A4, 0],
		0x12A4: [152, 0x127C, 1],
		0x12B4: [152, 0x12BC, 1],
		0x12B8: [152, 0x12D0, 1],
		0x1334: [152, 0x133C, 1],
		0x1338: [152, 0x1358, 1],
		0x13BC: [152, 0x1450, 0],
		0x13DC: [152, 0x13C8, 0],
		0x1450: [152, 0x13D8, 0],
		0x17CC: [152, 0x1558, 0],
		0x17F8: [152, 0x1630, 0],
		0x1824: [152, 0x16C0, 0],
		0x1850: [152, 0x1720, 0],
		0x18B4: [152, 0x18C8, 1],
		0x18B8: [152, 0x18DC, 1],
		0x18BC: [152, 0x191C, 1],
		0x18C0: [152, 0x198C, 1],
		0x18C4: [152, 0x19B0, 1],
		0x1A0C: [152, 0x1A34, 0],
		0x1A34: [152, 0x1A18, 1],
		0x1A44: [152, 0x1A58, 1],
		0x1A48: [152, 0x1A74, 1],
		0x1A4C: [152, 0x1AAC, 1],
		0x1A50: [152, 0x1B14, 1],
		0x1A54: [152, 0x1B54, 1],
		0x1BAC: [152, 0x1BD4, 0],
		0x1BD4: [152, 0x1BB8, 1],
		0x1BE4: [152, 0x1BF8, 1],
		0x1BE8: [152, 0x1C0C, 1],
		0x1BF0: [152, 0x1C48, 1],
		0x1BF4: [152, 0x1C98, 1],
		0x1CEC: [152, 0x1D20, 0],
		0x1D20: [152, 0x1CF8, 1],
		0x1D34: [152, 0x1D48, 1],
		0x1D38: [152, 0x1D5C, 1],
		0x1D40: [152, 0x1D98, 1],
		0x1D44: [152, 0x1DE8, 1],
		0x1E3C: [152, 0x1E70, 0],
		0x1E70: [152, 0x1E48, 1],
		0x1E84: [152, 0x1E98, 1],
		0x1E88: [152, 0x1EAC, 1],
		0x1E8C: [152, 0x1F3C, 1],
		0x1E90: [152, 0x2004, 1],
		0x1E94: [152, 0x202C, 1],
		0x20BC: [152, 0x20F0, 0],
		0x20F0: [152, 0x20C8, 1],
		0x2104: [152, 0x2118, 1],
		0x2108: [152, 0x212C, 1],
		0x210C: [152, 0x2164, 1],
		0x2110: [152, 0x21F0, 1],
		0x2114: [152, 0x2218, 1],
		0x22AC: [152, 0x22E0, 0],
		0x22E0: [152, 0x22B8, 1],
		0x22F4: [152, 0x2308, 1],
		0x22F8: [152, 0x2324, 1],
		0x22FC: [152, 0x23B0, 1],
		0x2300: [152, 0x2478, 1],
		0x2304: [152, 0x24F8, 1],
		0x254C: [152, 0x2580, 0],
		0x2580: [152, 0x2558, 1],
		0x2594: [152, 0x25A8, 1],
		0x2598: [152, 0x25C4, 1],
		0x259C: [152, 0x2600, 1],
		0x25A0: [152, 0x267C, 1],
		0x25A4: [152, 0x26F8, 1],
		0x274C: [152, 0x2780, 0],
		0x2780: [152, 0x2758, 1],
		0x2ADC: [152, 0x2830, 0],
		0x2B08: [152, 0x28B0, 0],
		0x2B60: [152, 0x2958, 0],
		0x2B8C: [152, 0x29A8, 0],
		0x2BEC: [152, 0x2BFC, 1],
		0x2C3C: [152, 0x2C4C, 1],
		0x2C74: [152, 0x2C4C, 1],
		0x2C8C: [152, 0x2C9C, 1],
		0x2CE8: [152, 0x2CEC, 1],
		0x2D38: [152, 0x2D3C, 1],
		0x2D64: [152, 0x2D3C, 1],
		0x2D88: [152, 0x2D8C, 1],
		0x3254: [152, 0x2EB0, 0],
		0x3280: [152, 0x2F30, 0],
		0x32D8: [152, 0x2FD8, 0],
		0x3304: [152, 0x3028, 0],
		0x335C: [152, 0x30D0, 0],
		0x3388: [152, 0x3120, 0],
		0x33F8: [152, 0x3408, 1],
		0x3468: [152, 0x3478, 1],
		0x34A0: [152, 0x3478, 1],
		0x34C8: [152, 0x34D8, 1],
		0x351C: [152, 0x3538, 1],
		0x3534: [152, 0x3578, 1],
		0x35CC: [152, 0x35E8, 1],
		0x35E4: [152, 0x3614, 1],
		0x3610: [152, 0x35E8, 1],
		0x3654: [152, 0x3614, 1],
		0x366C: [152, 0x3688, 1],
		0x3684: [152, 0x36CC, 1],
		}},
]
# END GENERATED FILE IMAGES
