## 1:1 port of src/gr/grcommon/grsector.c (Sector Z: Arwing fly-by, wing platform = yakumono 1, lasers).
## The Arwing model (map_dobjs[0..11]) is FoxSpecial3's EntryArwing DObjDesc; map_dobjs[0] follows the
## SectorDesc flight path (TraI spline, see Grdisplay.gcPlayDObjAnimJoint), map_dobjs[1] the pilot anim.
class_name Grsector
extends Port

## relocData symbols (tools/relocFileDescriptions.us.txt [262] GRSectorMap, [161] FoxSpecial3)
const llGRSectorMapMapHeader := 0x14
const llGRSectorMapMapHead := 0x0
const llGRSectorMapArwingLaser2DWeaponAttributes := 0xBC
const llGRSectorMapArwingLaser3DWeaponAttributes := 0xF0
const llGRSectorMapArwing0SectorDesc := 0x0000
const llGRSectorMapArwing1SectorDesc := 0x0250
const llGRSectorMapArwing2SectorDesc := 0x06D0
const llGRSectorMapArwing3SectorDesc := 0x03E0
const llGRSectorMapArwing4SectorDesc := 0x0D10
const llGRSectorMapArwing5SectorDesc := 0x0EB0
const llGRSectorMapArwing6SectorDesc := 0x1510
const llGRSectorMapArwing7SectorDesc := 0x11D0
const llGRSectorMapArwing0AnimJoint := 0x0000
const llGRSectorMapArwing1AnimJoint := 0x1D34
const llGRSectorMapArwing2AnimJoint := 0x1DA4
const llGRSectorMapArwing3AnimJoint := 0x1DC4
const llGRSectorMapArwing4AnimJoint := 0x1D54
const llGRSectorMapArwing5AnimJoint := 0x1DE4
const llFoxSpecial3FileID := 161
const llFoxSpecial3_1B34_AnimJoint := 0x1B34
const llFoxSpecial3_1B84_AnimJoint := 0x1B84
const llFoxSpecial3EntryArwingDObjDesc := 0x2C30
const llFoxSpecial3_2E74_AnimJoint := 0x2E74
const llFoxSpecial3_2EB4_AnimJoint := 0x2EB4

## GRSectorDesc (src/gr/grvars.h) field offsets
const GRSECTORDESC_ANIM_JOINT_0x0 := 0x0
const GRSECTORDESC_ANIM_JOINT_0x1C := 0x1C
const GRSECTORDESC_ANIM_JOINT_0x24 := 0x24
const GRSECTORDESC_ANIM_JOINT_0x2C := 0x2C

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8012E940
static var dGRSectorArwingSectorDescs: Array = [
	llGRSectorMapArwing0SectorDesc,
	llGRSectorMapArwing1SectorDesc,
	llGRSectorMapArwing2SectorDesc,
	llGRSectorMapArwing3SectorDesc,
	llGRSectorMapArwing4SectorDesc,
	llGRSectorMapArwing5SectorDesc,
	llGRSectorMapArwing6SectorDesc,
	llGRSectorMapArwing7SectorDesc,
]

## 0x8012E960
static var dGRSectorArwingAnimJoints: Array = [
	llGRSectorMapArwing0AnimJoint,
	llGRSectorMapArwing1AnimJoint,
	llGRSectorMapArwing2AnimJoint,
	llGRSectorMapArwing3AnimJoint,
	llGRSectorMapArwing4AnimJoint,
	llGRSectorMapArwing5AnimJoint,
]

## 0x8012E978
static var dGRSectorArwingMapPositionsX: Array = [
	-3000,
	0,
	9000,
]

## 0x8012E980
static var dGRSectorArwingLaserCounts: Array = [0x02, 0x02, 0x02, 0x02, 0x02, 0x00, 0x00, 0x00]

## 0x8012E988
static var dGRSectorArwingPilotIDs: Array = [
	0x01, 0x01, 0x02, 0x03, 0x04, 0x04, 0x05, 0x00,
	0x00, 0x00, 0x00, 0x02, 0x03, 0x04, 0x04, 0x05,
	0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x03, 0x04,
	0x04, 0x05, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01,
	0x02, 0x04, 0x04, 0x05, 0x00, 0x00, 0x00, 0x00,
	0x01, 0x01, 0x02, 0x03, 0x05, 0x00, 0x00, 0x00,
	0x00, 0x01, 0x01, 0x02, 0x03, 0x04, 0x04, 0x00,
]

## 0x8012E9C0
static var dGRSectorArwingPilotWaitTimers: Array = [
	[0, 7],
	[7, 9],
	[16, 10],
	[26, 10],
	[36, 9],
	[45, 10],
]

## 0x8012E9CC (REGION_US first entry)
static var dGRSectorArwingTransformKinds: Array = [
	{"tk1": 0x53, "tk2": nGCMatrixKindNull, "tk3": 0x00},
	{"tk1": nGCMatrixKindTraRotRpyR, "tk2": nGCMatrixKindNull, "tk3": 0x00},
	{"tk1": nGCMatrixKindTra, "tk2": 0x2C, "tk3": 0x01},
	{"tk1": nGCMatrixKindTra, "tk2": 0x2C, "tk3": 0x01},
	{"tk1": nGCMatrixKindTra, "tk2": 0x2C, "tk3": 0x00},
	{"tk1": nGCMatrixKindTra, "tk2": 0x2C, "tk3": 0x00},
	{"tk1": nGCMatrixKindTra, "tk2": nGCMatrixKindNull, "tk3": 0x01},
	{"tk1": nGCMatrixKindTra, "tk2": nGCMatrixKindNull, "tk3": 0x00},
	{"tk1": nGCMatrixKindTra, "tk2": 0x2C, "tk3": 0x00},
	{"tk1": nGCMatrixKindTra, "tk2": nGCMatrixKindNull, "tk3": 0x00},
	{"tk1": nGCMatrixKindTra, "tk2": 0x2C, "tk3": 0x01},
	{"tk1": nGCMatrixKindNull, "tk2": nGCMatrixKindNull, "tk3": 0x00},   # This might just be padding
]

## WPAttributes of the Arwing lasers (lbRelocGetFileData(WPAttributes*, *p_weapon, o_attributes)),
## transcribed from src/relocData/262_GRSectorMap.c dGRSectorMap_ArwingLaser2D/3D_WeaponAttributes
## (GRSectorMap @0xBC / @0xF0).
static var dGRSectorMapArwingLaser2DWeaponAttributes: Dictionary = {
	"data": Grdisplay.GRPtr.new(153, 0x1C50),   # dStageSectorFile3 display list
	"p_mobjsubs": null, "anim_joints": null, "p_matanim_joints": null,
	"attack_offsets": [Vector3.ZERO, Vector3.ZERO],
	"map_coll_top": 28, "map_coll_center": 0, "map_coll_bottom": -28, "map_coll_width": 564,
	"size": 300, "angle": 361, "knockback_scale": 75, "damage": 16, "element": nGMHitElementNormal,
	"knockback_weight": 0, "shield_damage": 5, "attack_count": 1, "can_setoff": 0, "sfx": nSYAudioFGMExplodeS,
	"priority": 1, "can_rehit_item": 0, "can_rehit_fighter": 0, "can_hop": 1, "can_reflect": 1,
	"can_absorb": 1, "can_shield": 1, "unused_0x2F_b6": 0, "unused_0x2F_b7": 0, "knockback_base": 70,
}
static var dGRSectorMapArwingLaser3DWeaponAttributes: Dictionary = {
	"data": Grdisplay.GRPtr.new(153, 0x1C50),
	"p_mobjsubs": null, "anim_joints": null, "p_matanim_joints": null,
	"attack_offsets": [Vector3.ZERO, Vector3.ZERO],
	"map_coll_top": 28, "map_coll_center": 0, "map_coll_bottom": -28, "map_coll_width": 28,
	"size": 300, "angle": 361, "knockback_scale": 100, "damage": 18, "element": nGMHitElementFire,
	"knockback_weight": 0, "shield_damage": 2, "attack_count": 1, "can_setoff": 0, "sfx": nSYAudioFGMExplodeS,
	"priority": 1, "can_rehit_item": 1, "can_rehit_fighter": 1, "can_hop": 0, "can_reflect": 0,
	"can_absorb": 1, "can_shield": 0, "unused_0x2F_b6": 0, "unused_0x2F_b7": 0, "knockback_base": 10,
}

## 0x8012E9F0 - WPDesc (C field names). p_weapon/o_attributes cannot be dereferenced in the port:
## "attributes" carries the WPAttributes they point at (GRSectorMap + o_attributes).
static var dGRSectorArwingWeaponLaser2DWeaponDesc: Dictionary = {
	"flags": 0,                                         # Render flags?
	"kind": nWPKindArwingLaser2D,                       # Weapon Kind
	"p_weapon": null,                                   # &gGRCommonStruct.sector.weapon_head
	"o_attributes": llGRSectorMapArwingLaser2DWeaponAttributes,
	"attributes": dGRSectorMapArwingLaser2DWeaponAttributes,
	"visual_kind": "ArwingLaser2D",                     # port-only (Wpmanager convention)
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyR, "tk2": nGCMatrixKindNull, "tk3": 0},
	"proc_update": Callable(),
	"proc_map": Callable(Grsector, &"grSectorArwingWeaponLaser2DProcMap"),
	"proc_hit": Callable(Grsector, &"grSectorArwingWeaponLaser2DProcHit"),
	"proc_shield": Callable(Grsector, &"grSectorArwingWeaponLaser2DProcHit"),
	"proc_hop": Callable(Grsector, &"grSectorArwingWeaponLaser2DProcHop"),
	"proc_setoff": Callable(Grsector, &"grSectorArwingWeaponLaser2DProcHit"),
	"proc_reflector": Callable(Grsector, &"grSectorArwingWeaponLaser2DProcReflector"),
	"proc_absorb": Callable(Grsector, &"grSectorArwingWeaponLaser2DProcHit"),
}

## 0x8012EA24
static var dGRSectorArwingWeaponLaser3DWeaponDesc: Dictionary = {
	"flags": 0,
	"kind": nWPKindArwingLaser3D,
	"p_weapon": null,                                   # &gGRCommonStruct.sector.weapon_head
	"o_attributes": llGRSectorMapArwingLaser3DWeaponAttributes,
	"attributes": dGRSectorMapArwingLaser3DWeaponAttributes,
	"visual_kind": "ArwingLaser3D",                     # port-only (Wpmanager convention)
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyR, "tk2": nGCMatrixKindNull, "tk3": 0},
	"proc_update": Callable(),
	"proc_map": Callable(Grsector, &"grSectorArwingWeaponLaser3DProcMap"),
	"proc_hit": Callable(Grsector, &"grSectorArwingWeaponLaser3DProcHit"),
	"proc_shield": Callable(Grsector, &"grSectorArwingWeaponLaser3DProcHit"),
	"proc_hop": Callable(Grsector, &"grSectorArwingWeaponLaser3DProcHit"),
	"proc_setoff": Callable(Grsector, &"grSectorArwingWeaponLaser3DProcHit"),
	"proc_reflector": Callable(Grsector, &"grSectorArwingWeaponLaser3DProcHit"),
	"proc_absorb": Callable(Grsector, &"grSectorArwingWeaponLaser3DProcAbsorb"),
}

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

const nGRSectorArwingStatusSleep := 0
const nGRSectorArwingStatusWait := 1
const nGRSectorArwingStatusPatrol := 2

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

static func _s8(v: int) -> int:
	v &= 0xFF
	return v - 0x100 if v >= 0x80 else v

## 0x80106730 - vec1/vec2/vec3 are in-out Vec3f* -> returns {"vec1", "vec2", "vec3"}
static func func_ovl2_80106730(arg0 = null, vec1 = null, vec2 = null, vec3 = null) -> Dictionary:
	var sector: Dictionary = Grcommonsetup.gGRCommonStruct.sector
	var sp54: DObj = sector.map_dobjs[11]
	var v1: Vector3 = vec1 if vec1 is Vector3 else Vector3.ZERO
	var v2: Vector3 = vec2 if vec2 is Vector3 else Vector3.ZERO
	var v3: Vector3 = vec3 if vec3 is Vector3 else Vector3.ZERO
	var vlen := 0.0

	for aobj in arg0.aobj:
		if (aobj.kind != nGCAnimKindNone) and not (arg0.parent_gobj.gobj_flags & GOBJ_FLAG_NOANIM) and (aobj.track == nGCAnimTrackTraI):
			vlen = Grdisplay.gcGetAObjValue(aobj)

			if vlen < 0.0:
				vlen = 0.0
			elif vlen > 1.0:
				vlen = 1.0

			v1 = Grdisplay.grDisplayInterpQuad(v1, aobj.interpolate, vlen)

	if (sp54 != null) and (sp54.anim_wait != AOBJ_ANIM_NULL) and (sector.arwing_laser_count == 0):
		for aobj in sp54.aobj:
			if (aobj.kind != nGCAnimKindNone) and not (arg0.parent_gobj.gobj_flags & GOBJ_FLAG_NOANIM) and (aobj.track == nGCAnimTrackTraI):
				v3 = Grdisplay.grDisplayInterpCubic(v3, aobj.interpolate, vlen)

		v3 = syVectorNorm3D(v3)

	v2 = Lbcommon.lbCommonCross3D(v3, v1)
	v3 = Lbcommon.lbCommonCross3D(v1, v2)

	v1 = syVectorNorm3D(v1)
	v2 = syVectorNorm3D(v2)
	v3 = syVectorNorm3D(v3)

	return {"vec1": v1, "vec2": v2, "vec3": v3}

## 0x80106904 - display matrix function (visual); Mtx* out -> {"ret": 0, "mtx": Mtx44f rows}
static func grSectorArwingLaser3DFuncMatrix(mtx = null, dobj = null, dls = null) -> Dictionary:
	var sector: Dictionary = Grcommonsetup.gGRCommonStruct.sector
	var sp80: Vector3
	var sp74: Vector3
	var sp68: Vector3
	var tx: float = dobj.translate.x
	var ty: float = dobj.translate.y
	var tz: float = dobj.translate.z

	sp80.x = -1.0
	sp80.y = 0.0
	sp80.z = 0.0
	sp68.x = 0.0
	sp68.y = 1.0
	sp68.z = 0.0

	if sector.arwing_laser_count == 2:
		sp74.x = 0.0
		sp74.y = 0.0
		sp74.z = 1
	else:
		var r := func_ovl2_80106730(dobj, sp80, sp74, sp68)
		sp80 = r.vec1
		sp74 = r.vec2
		sp68 = r.vec3

	var f: Array = [
		[sp74.x, sp74.y, sp74.z, 0.0],
		[sp68.x, sp68.y, sp68.z, 0.0],
		[sp80.x, sp80.y, sp80.z, 0.0],
		[tx + sector.arwing_target_x, ty, tz, 1.0],
	]
	# guMtxF2L(f, mtx);
	return {"ret": 0, "mtx": f}

## 0x80106A40
static func grSectorArwingAddAnim(dobj = null, anim_joint = null, unused = null) -> void:
	if anim_joint != null:
		Grdisplay.gcAddDObjAnimJoint(dobj, anim_joint, 0.0)

		dobj.is_anim_root = false

		ObjAnim.gcParseDObjAnimJoint(dobj)
		Grdisplay.gcPlayDObjAnimJoint(dobj)
	else:
		dobj.anim_wait = AOBJ_ANIM_NULL
		dobj.is_anim_root = false

## 0x80106A98
static func grSectorArwingUpdateSleep() -> void:
	if G.gSCManagerBattleState.game_status != nSCBattleGameStatusWait:
		Grcommonsetup.gGRCommonStruct.sector.arwing_status = nGRSectorArwingStatusWait

## 0x80106AC0
static func grSectorArwingUpdateWait() -> void:
	var sector: Dictionary = Grcommonsetup.gGRCommonStruct.sector
	var random: int

	if sector.arwing_appear_timer != 0:
		sector.arwing_appear_timer = (sector.arwing_appear_timer - 1) & 0xFFFF   # u16
	else:
		sector.arwing_target_x = 0.0

		if sector.arwing_type_cycle != 0:
			random = syUtilsRandIntRange(5)

			if random == 4:
				sector.arwing_target_x = float(dGRSectorArwingMapPositionsX[syUtilsRandIntRange(dGRSectorArwingMapPositionsX.size())])

			sector.arwing_type_cycle = (sector.arwing_type_cycle - 1) & 0xFF   # u8
			sector.arwing_state_timer = syUtilsRandIntRange(540) + 180
			sector.arwing_pilot_curr = -1
		else:
			random = syUtilsRandIntRange(3) + 5

			sector.unk_sector_0x4C = (random - 5) if ((syUtilsRandUShort() % 2) != 0) else -1

			sector.arwing_type_cycle = 3
			sector.arwing_pilot_curr = -2

		sector.arwing_flight_pattern = _s8(random)
		sector.arwing_status = 2
		sector.unk_sector_0x4E = 0x3C

		sector.map_dobjs[1].translate.x = 0.0
		sector.map_dobjs[1].translate.y = 0.0
		sector.map_dobjs[1].translate.z = 0.0

		sector.map_dobjs[1].rotate.x = 0.0
		sector.map_dobjs[1].rotate.y = 0.0
		sector.map_dobjs[1].rotate.z = 0.0

		sector.is_arwing_line_collision = FALSE
		sector.is_arwing_line_active = TRUE
		sector.is_arwing_z_collision = FALSE
		sector.arwing_laser_ammo = 0

		Snd.func_800269C0_275C0(nSYAudioFGMSectorAmbient1)

## 0x80106C28
static func grSectorArwingDecideZNear() -> void:
	var sector: Dictionary = Grcommonsetup.gGRCommonStruct.sector

	if ABSF(sector.map_dobjs[0].translate.z) < 200.0:
		sector.is_arwing_z_near = TRUE
	else:
		sector.is_arwing_z_near = FALSE

## 0x80106C88
static func func_ovl2_80106C88() -> void:
	var sector: Dictionary = Grcommonsetup.gGRCommonStruct.sector

	match sector.arwing_state_timer:
		0:
			sector.is_arwing_line_active = FALSE
		88:
			sector.is_arwing_line_active = TRUE

## 0x80106CC4
static func func_ovl2_80106CC4() -> void:
	var sector: Dictionary = Grcommonsetup.gGRCommonStruct.sector

	match sector.arwing_state_timer:
		0:
			sector.is_arwing_line_active = FALSE
		178:
			sector.is_arwing_line_active = TRUE

## 0x80106D00
static func func_ovl2_80106D00() -> void:
	var sector: Dictionary = Grcommonsetup.gGRCommonStruct.sector

	if sector.arwing_state_timer == 0:
		sector.map_dobjs[7].anim_wait = AOBJ_ANIM_NULL
		sector.map_dobjs[7].flags = DOBJ_FLAG_NONE
		sector.map_dobjs[9].anim_wait = AOBJ_ANIM_NULL
		sector.map_dobjs[9].flags = DOBJ_FLAG_HIDDEN

		grSectorArwingAddAnim(sector.map_dobjs[8], Grdisplay.grDisplayPtrAdd(sector.map_file, llFoxSpecial3_2EB4_AnimJoint), 0.0)
	elif sector.map_dobjs[8].anim_wait == AOBJ_ANIM_NULL:
		sector.map_dobjs[7].flags = DOBJ_FLAG_HIDDEN
		sector.map_dobjs[9].flags = DOBJ_FLAG_NONE

	if sector.map_dobjs[1].anim_wait == AOBJ_ANIM_NULL:
		sector.map_dobjs[0].anim_wait = AOBJ_ANIM_NULL

## 0x80106DD8
static func func_ovl2_80106DD8() -> void:
	var sector: Dictionary = Grcommonsetup.gGRCommonStruct.sector

	if sector.arwing_pilot_curr != -2:
		if sector.arwing_pilot_curr >= 0:
			match sector.arwing_pilot_curr:
				1:
					func_ovl2_80106C88()
				4:
					func_ovl2_80106CC4()
				5:
					func_ovl2_80106D00()

			if sector.map_dobjs[1].anim_wait == AOBJ_ANIM_NULL:
				sector.arwing_pilot_curr = -1
				sector.arwing_state_timer = 120
			else:
				sector.arwing_state_timer = (sector.arwing_state_timer + 1) & 0xFFFF   # u16
		else:
			sector.arwing_state_timer = (sector.arwing_state_timer - 1) & 0xFFFF

			if sector.arwing_state_timer == 0:
				var random: Array = dGRSectorArwingPilotWaitTimers[sector.arwing_pilot_prev]
				var pilot_id: int = dGRSectorArwingPilotIDs[random[0] + syUtilsRandIntRange(random[1])]

				if pilot_id != 0:
					grSectorArwingAddAnim(sector.map_dobjs[1], Grdisplay.grDisplayPtrAdd(sector.map_head, dGRSectorArwingAnimJoints[pilot_id]), 0.0)

				sector.arwing_pilot_curr = _s8(pilot_id)
				sector.arwing_pilot_prev = pilot_id & 0xFF

## 0x80106F2
static func grSectorArwingPrepareLaserCount() -> int:
	if syUtilsRandIntRange(3) >= 3:
		return 2
	else:
		return 4

## 0x80106F5C
static func grSectorArwingGetLaserAmmoCount() -> int:
	var sector: Dictionary = Grcommonsetup.gGRCommonStruct.sector
	var pos_x: float = sector.map_dobjs[0].translate.x + sector.arwing_target_x
	var pos_y: float = sector.map_dobjs[0].translate.y + sector.map_dobjs[1].translate.y

	for fighter_gobj in Sim.get_link(nGCCommonLinkIDFighter):
		var fp := ftGetStruct(fighter_gobj)

		if sector.arwing_laser_count == 2:
			var joint: DObj = fp.joints[nFTPartsJointTopN]

			if joint.translate.x < pos_x:
				if (joint.translate.y < (pos_y + 300.0)) and (joint.translate.y > (pos_y + -500.0)):
					return grSectorArwingPrepareLaserCount()

	return 0

## 0x80107030
static func grSectorArwingWeaponLaser2DProcMap(weapon_gobj = null) -> int:
	if B(Wpmap.wpMapTestAllCheckCollEnd(weapon_gobj)):
		Efmanager.efManagerDustExpandSmallMakeEffect(DObjGetStruct(weapon_gobj).translate, 1.0)

		return TRUE
	else:
		return FALSE

## 0x80107074
static func grSectorArwingWeaponLaser2DProcHit(weapon_gobj = null) -> int:
	var wp := wpGetStruct(weapon_gobj)

	Efmanager.efManagerImpactShockMakeEffect(DObjGetStruct(weapon_gobj).translate, wp.attack_coll.damage)

	return TRUE

## 0x801070A4 - rotate is a pure out Vec3f* -> returned
static func func_ovl2_801070A4(rotate = null, direction = null, vec3 = null, vec4 = null) -> Vector3:
	var r: Vector3

	if (vec3.z == -1.0) or (vec3.z == 1.0):
		if vec3.z == -1.0:
			r.y = F_CST_DTOR32(90.0)
			r.x = syUtilsArcTan2(vec4.x, vec4.y)
		else:
			r.y = F_CST_DTOR32(-90.0)
			r.x = syUtilsArcTan2(-vec4.x, vec4.y)

		r.z = 0.0
	else:
		r.y = syUtilsArcSin(-vec3.z)
		r.x = syUtilsArcTan2(vec4.z, direction.z)
		r.z = syUtilsArcTan2(vec3.y, vec3.x)

	return r

## 0x8010719C - vel: Vector3 (read); rotate pure out -> returned
static func func_ovl2_8010719C(vel = null, rotate = null) -> Vector3:
	var sp2C: Vector3
	var sp20: Vector3
	var rot_z: float

	sp20.x = 0.0

	rot_z = Grcommonsetup.gGRCommonStruct.sector.map_dobjs[1].rotate.z + F_CST_DTOR32(90.0)

	sp20.y = __sinf(rot_z)
	sp20.z = __cosf(rot_z)

	sp2C = Lbcommon.lbCommonCross3D(sp20, vel)
	sp20 = Lbcommon.lbCommonCross3D(vel, sp2C)
	sp2C = syVectorNorm3D(sp2C)
	sp20 = syVectorNorm3D(sp20)

	return func_ovl2_801070A4(rotate, vel, sp2C, sp20)

## 0x80107238
static func grSectorArwingWeaponLaser2DProcHop(weapon_gobj = null) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var vel: Vector3

	wp.physics.vel_air = syVectorRotateAbout3D(wp.physics.vel_air, wp.shield_collide_dir, wp.shield_collide_angle * 2)

	vel = wp.physics.vel_air

	vel = syVectorNorm3D(vel)
	DObjGetStruct(weapon_gobj).rotate = func_ovl2_8010719C(vel)

	return FALSE

## 0x801072C0
static func grSectorArwingWeaponLaser2DProcReflector(weapon_gobj = null) -> int:
	var wp := wpGetStruct(weapon_gobj)
	var fp := ftGetStruct(wp.owner_gobj)
	var vel: Vector3

	Wpmain.wpMainReflectorSetLR(wp, fp)

	vel = wp.physics.vel_air

	vel = syVectorNorm3D(vel)
	DObjGetStruct(weapon_gobj).rotate = func_ovl2_8010719C(vel)

	return FALSE

## 0x80107330
static func grSectorArwingWeaponLaser2DMakeWeapon() -> void:
	var sector: Dictionary = Grcommonsetup.gGRCommonStruct.sector
	var weapon_gobj
	var wp
	var sp54: Vector3
	var sp48: Vector3
	var pos: Vector3
	var rotate: Vector3
	var vel: Vector3
	var zero := 0.0

	sp54.x = sector.map_dobjs[0].translate.x + sector.arwing_target_x
	sp54.y = sector.map_dobjs[0].translate.y + sector.map_dobjs[1].translate.y

	sp48 = sector.map_dobjs[2].translate

	sp48 = syVectorRotate3D(sp48, SYVECTOR_AXIS_Z, sector.map_dobjs[1].rotate.z)

	pos.x = (sp54.x - sp48.z) - 566.0
	pos.y = sp54.y + sp48.y
	pos.z = zero + sp48.x

	weapon_gobj = Wpmanager.wpManagerMakeWeapon(null, dGRSectorArwingWeaponLaser2DWeaponDesc, pos, WEAPON_FLAG_PARENT_GROUND)

	if weapon_gobj != null:
		wp = wpGetStruct(weapon_gobj)

		wp.physics.vel_air.x = -230.0

		vel.y = 0.0
		vel.z = 0.0
		vel.x = -1.0

		rotate = func_ovl2_8010719C(vel)

		DObjGetStruct(weapon_gobj).rotate = rotate

		sp48 = sector.map_dobjs[3].translate

		sp48 = syVectorRotate3D(sp48, 4, sector.map_dobjs[1].rotate.z)

		pos.x = (sp54.x - sp48.z) - 566.0
		pos.y = sp54.y + sp48.y
		pos.z = zero + sp48.x

		weapon_gobj = Wpmanager.wpManagerMakeWeapon(null, dGRSectorArwingWeaponLaser2DWeaponDesc, pos, WEAPON_FLAG_PARENT_GROUND)

		if weapon_gobj != null:
			wp = wpGetStruct(weapon_gobj)

			wp.physics.vel_air.x = -230.0

			DObjGetStruct(weapon_gobj).rotate = rotate

## 0x80107518
static func grSectorArwingWeaponLaserExplodeProcUpdate(weapon_gobj = null) -> int:
	if B(Wpmain.wpMainDecLifeCheckExpire(wpGetStruct(weapon_gobj))):
		return TRUE
	else:
		return FALSE

## 0x80107544
static func grSectorArwingWeaponLaserExplodeInitVars(weapon_gobj = null) -> void:
	var wp := wpGetStruct(weapon_gobj)

	wp.lifetime = 16

	wp.attack_coll.can_reflect = FALSE
	wp.attack_coll.can_absorb = TRUE
	wp.attack_coll.can_shield = FALSE

	wp.physics.vel_air.x = 0.0
	wp.physics.vel_air.y = 0.0
	wp.physics.vel_air.z = 0.0

	wp.attack_coll.size = 200.0

	DObjGetStruct(weapon_gobj).dl = null

	Wpmain.wpMainClearAttackRecord(wp)

	wp.proc_update = Callable(Grsector, &"grSectorArwingWeaponLaserExplodeProcUpdate")

	# proc_map = proc_hit = proc_shield = proc_hop = proc_setoff = proc_hop = proc_reflector = NULL (proc_absorb kept)
	wp.proc_map = Callable()
	wp.proc_hit = Callable()
	wp.proc_shield = Callable()
	wp.proc_hop = Callable()
	wp.proc_setoff = Callable()
	wp.proc_reflector = Callable()

## 0x801075E0
static func grSectorArwingWeaponLaser3DProcMap(weapon_gobj = null) -> int:
	var dobj: DObj = DObjGetStruct(weapon_gobj)

	if ABSF(dobj.translate.z) < 1000.0:
		if B(Wpmap.wpMapTestAllCheckCollEnd(weapon_gobj)):
			Snd.func_800269C0_275C0(nSYAudioFGMExplodeS)
			Efmanager.efManagerSparkleWhiteMultiExplodeMakeEffect(dobj.translate)
			grSectorArwingWeaponLaserExplodeInitVars(weapon_gobj)

	return FALSE

## 0x80107670
static func grSectorArwingWeaponLaser3DProcHit(weapon_gobj = null) -> int:
	Snd.func_800269C0_275C0(nSYAudioFGMExplodeS)
	Efmanager.efManagerSparkleWhiteMultiExplodeMakeEffect(DObjGetStruct(weapon_gobj).translate)
	grSectorArwingWeaponLaserExplodeInitVars(weapon_gobj)

	return FALSE

## 0x801076B0
static func grSectorArwingWeaponLaser3DProcAbsorb(weapon_gobj = null) -> int:
	Snd.func_800269C0_275C0(nSYAudioFGMExplodeS)
	Efmanager.efManagerSparkleWhiteMultiExplodeMakeEffect(DObjGetStruct(weapon_gobj).translate)

	return TRUE

## 0x801076E8
static func grSectorArwingWeaponLaser3DMakeWeapon() -> void:
	var sector: Dictionary = Grcommonsetup.gGRCommonStruct.sector
	var weapon_gobj
	var fighter_gobj
	var random: int
	var fp: Fighter
	var wp
	var wp_pos: Vector3
	var ft_pos: Vector3
	var sp94 := Vector3.ZERO   # uninitialised in the C (written by func_ovl2_80106730 when the path has a TraI track)
	var sp88 := Vector3.ZERO
	var sp7C := Vector3.ZERO
	var wp_angle: Vector3
	var dobj: DObj

	dobj = sector.map_dobjs[0]

	var r := func_ovl2_80106730(dobj, sp94, sp88, sp7C)
	sp94 = r.vec1
	sp88 = r.vec2
	sp7C = r.vec3

	# Mtx44f mtx: rows sp88 / sp7C / sp94 / translate (4x3 row-major, see Gmcollision)
	var mtx := PackedFloat32Array([
		sp88.x, sp88.y, sp88.z,
		sp7C.x, sp7C.y, sp7C.z,
		sp94.x, sp94.y, sp94.z,
		dobj.translate.x + sector.arwing_target_x, dobj.translate.y, dobj.translate.z,
	])

	wp_pos.y = 0.0
	wp_pos.x = 0

	wp_pos.z = 666.0

	wp_pos = Gmcollision.gmCollisionGetWorldPosition(mtx, wp_pos)

	random = syUtilsRandIntRange(G.gSCManagerBattleState.pl_count + G.gSCManagerBattleState.cp_count)

	# fighter_gobj = gGCCommonLinks[nGCCommonLinkIDFighter]; for (player = 0; player < random; player++) fighter_gobj = fighter_gobj->link_next;
	var fighters: Array = Sim.get_link(nGCCommonLinkIDFighter)
	if random >= fighters.size():
		return   # C walks off the end of the fighter list (NULL); never happens in a battle
	fighter_gobj = fighters[random]

	fp = ftGetStruct(fighter_gobj)

	if (fp.coll_data.floor_line_id == -1) or (fp.coll_data.floor_line_id == -2):
		ft_pos.x = 0
		ft_pos.y = 0
		ft_pos.z = 0
	else:
		ft_pos = fp.joints[nFTPartsJointTopN].translate

		ft_pos.y += fp.coll_data.floor_dist

	wp_angle.x = ft_pos.x - wp_pos.x
	wp_angle.y = ft_pos.y - wp_pos.y
	wp_angle.z = ft_pos.z - wp_pos.z

	wp_angle = syVectorNorm3D(wp_angle)

	weapon_gobj = Wpmanager.wpManagerMakeWeapon(null, dGRSectorArwingWeaponLaser3DWeaponDesc, wp_pos, WEAPON_FLAG_PARENT_GROUND)

	if weapon_gobj != null:
		wp = wpGetStruct(weapon_gobj)

		wp.physics.vel_air.x = wp_angle.x * 230.0
		wp.physics.vel_air.y = wp_angle.y * 230.0
		wp.physics.vel_air.z = wp_angle.z * 230.0

		DObjGetStruct(weapon_gobj).rotate = func_ovl2_8010719C(wp_angle)

## 0x80107910
static func func_ovl2_80107910() -> void:
	if Grcommonsetup.gGRCommonStruct.sector.arwing_laser_count == 2:
		grSectorArwingWeaponLaser2DMakeWeapon()
	else:
		grSectorArwingWeaponLaser3DMakeWeapon()

	Snd.func_800269C0_275C0(nSYAudioFGMSectorArwingLaser)

## 0x80107958
static func func_ovl2_80107958() -> void:
	var sector: Dictionary = Grcommonsetup.gGRCommonStruct.sector
	var ammo: int
	var mh1
	var mh2

	if sector.arwing_laser_ammo == 0:
		ammo = 0

		if sector.arwing_pilot_curr == -2:
			if (
				((sector.unk_sector_0x4C == 0) and (sector.arwing_appear_timer == 5)) or
				((sector.unk_sector_0x4C == 1) and (sector.arwing_appear_timer == 5))
			):
				ammo = grSectorArwingPrepareLaserCount()
		elif sector.is_arwing_z_near == 0:
			sector.unk_sector_0x4E = 60
			sector.arwing_laser_ammo = 0
		else:
			sector.unk_sector_0x4E = (sector.unk_sector_0x4E - 1) & 0xFFFF   # u16

			if sector.unk_sector_0x4E == 0:
				ammo = grSectorArwingGetLaserAmmoCount()

				sector.unk_sector_0x4E = 60

		if ammo != 0:
			sector.arwing_laser_ammo = ammo & 0xFF
			sector.arwing_laser_timer = 0
			sector.unk_sector_0x52 = 0
	else:
		if sector.arwing_laser_timer == 0:
			if sector.unk_sector_0x52 == 0:
				mh1 = sector.map_head

				grSectorArwingAddAnim(sector.map_dobjs[4], Grdisplay.grDisplayPtrAdd(mh1, llFoxSpecial3_1B84_AnimJoint), 0.0)
				grSectorArwingAddAnim(sector.map_dobjs[5], Grdisplay.grDisplayPtrAdd(mh1, llFoxSpecial3_1B84_AnimJoint), 0.0)

				sector.unk_sector_0x52 = (sector.unk_sector_0x52 + 1) & 0xFF
			elif sector.map_dobjs[4].anim_wait == AOBJ_ANIM_NULL:
				mh2 = sector.map_head

				func_ovl2_80107910()

				grSectorArwingAddAnim(sector.map_dobjs[2], Grdisplay.grDisplayPtrAdd(mh2, llFoxSpecial3_1B34_AnimJoint), 0.0)
				grSectorArwingAddAnim(sector.map_dobjs[3], Grdisplay.grDisplayPtrAdd(mh2, llFoxSpecial3_1B34_AnimJoint), 0.0)

				sector.arwing_laser_timer = 30
				sector.arwing_laser_ammo = (sector.arwing_laser_ammo - 1) & 0xFF   # u8

		if sector.arwing_laser_timer:
			sector.arwing_laser_timer = (sector.arwing_laser_timer - 1) & 0xFFFF

		if sector.arwing_laser_ammo == 0:
			sector.unk_sector_0x4E = 240

## 0x80107B30
static func func_ovl2_80107B30() -> void:
	var sector: Dictionary = Grcommonsetup.gGRCommonStruct.sector

	if (sector.map_dobjs[8].anim_wait == AOBJ_ANIM_NULL) and (sector.map_dobjs[7].flags == DOBJ_FLAG_NONE):
		grSectorArwingAddAnim(sector.map_dobjs[8], Grdisplay.grDisplayPtrAdd(sector.map_file, llFoxSpecial3_2EB4_AnimJoint), 0.0)

		Snd.func_800269C0_275C0(nSYAudioFGMSectorAmbient2)

## 0x80107BA0
static func grSectorArwingUpdateCollisions() -> void:
	var sector: Dictionary = Grcommonsetup.gGRCommonStruct.sector
	var pos: Vector3

	if sector.arwing_pilot_curr != -2:
		if B(sector.is_arwing_line_active) and B(sector.is_arwing_z_near):
			pos.x = sector.map_dobjs[0].translate.x + sector.arwing_target_x
			pos.y = sector.map_dobjs[0].translate.y + sector.map_dobjs[1].translate.y
			pos.z = 0.0

			if (sector.is_arwing_z_collision == FALSE) or (sector.is_arwing_line_collision == FALSE):
				Mpcollision.mpCollisionSetYakumonoOnID(1)
				Mpcollision.mpCollisionSetYakumonoPosID(1, pos)

			Mpcollision.mpCollisionSetYakumonoPosID(1, pos)

		if not B(sector.is_arwing_line_active) or not B(sector.is_arwing_z_near):
			if (sector.is_arwing_z_collision != FALSE) and (sector.is_arwing_line_collision != FALSE):
				Mpcollision.mpCollisionSetYakumonoOffID(1)

		sector.is_arwing_line_collision = sector.is_arwing_line_active
		sector.is_arwing_z_collision = sector.is_arwing_z_near

## 0x80107CA0
static func grSectorArwingUpdatePatrol() -> void:
	var sector: Dictionary = Grcommonsetup.gGRCommonStruct.sector

	grSectorArwingDecideZNear()
	func_ovl2_80106DD8()
	func_ovl2_80107958()
	func_ovl2_80107B30()
	grSectorArwingUpdateCollisions()

	if sector.map_dobjs[0].anim_wait == AOBJ_ANIM_NULL:
		sector.map_gobj.gobj_flags = GOBJ_FLAG_HIDDEN

		sector.arwing_appear_timer = syUtilsRandIntRange(1140) + 960
		sector.arwing_status = nGRSectorArwingStatusWait

		Mpcollision.mpCollisionSetYakumonoOffID(1)
	else:
		sector.arwing_appear_timer = (sector.arwing_appear_timer + 1) & 0xFFFF   # u16

## 0x80107D50
static func func_ovl2_80107D50() -> void:
	var sector: Dictionary = Grcommonsetup.gGRCommonStruct.sector
	var map_gobj
	var desc

	if sector.arwing_flight_pattern != -1:
		map_gobj = sector.map_gobj
		sector.arwing_laser_count = dGRSectorArwingLaserCounts[sector.arwing_flight_pattern]

		desc = Grdisplay.grDisplayPtrAdd(sector.map_head, dGRSectorArwingSectorDescs[sector.arwing_flight_pattern])

		grSectorArwingAddAnim(sector.map_dobjs[0], Grdisplay.grDisplayFilePtr(desc, GRSECTORDESC_ANIM_JOINT_0x0), 0.0)
		grSectorArwingAddAnim(sector.map_dobjs[7], Grdisplay.grDisplayFilePtr(desc, GRSECTORDESC_ANIM_JOINT_0x1C), 0.0)
		grSectorArwingAddAnim(sector.map_dobjs[9], Grdisplay.grDisplayFilePtr(desc, GRSECTORDESC_ANIM_JOINT_0x24), 0.0)
		grSectorArwingAddAnim(sector.map_dobjs[11], Grdisplay.grDisplayFilePtr(desc, GRSECTORDESC_ANIM_JOINT_0x2C), 0.0)

		sector.arwing_flight_pattern = -1
		map_gobj.gobj_flags = GOBJ_FLAG_NONE

## 0x80107E08
static func grSectorProcUpdate(ground_gobj = null) -> void:
	match Grcommonsetup.gGRCommonStruct.sector.arwing_status:
		nGRSectorArwingStatusSleep:
			grSectorArwingUpdateSleep()
		nGRSectorArwingStatusWait:
			grSectorArwingUpdateWait()
		nGRSectorArwingStatusPatrol:
			grSectorArwingUpdatePatrol()

	func_ovl2_80107D50()

## 0x80107E7C
static func grSectorInitAll() -> void:
	var sector: Dictionary = Grcommonsetup.gGRCommonStruct.sector
	var gMPCollisionGroundData: Dictionary = Grdisplay.grDisplayGetGroundData()
	var map_gobj
	var map_file

	sector.map_head = Grdisplay.grDisplayPtrAdd(gMPCollisionGroundData.map_nodes, -llGRSectorMapMapHead)

	Lbreloc.lbRelocGetForceStatusBufferFile(llFoxSpecial3FileID)
	map_file = Grdisplay.GRPtr.new(llFoxSpecial3FileID, 0)   # FoxSpecial3 file image (Grdisplay)

	sector.map_file = map_file

	map_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindGround, null, nGCCommonLinkIDGround, GOBJ_PRIORITY_DEFAULT)

	sector.map_gobj = map_gobj

	Objman.gcAddGObjDisplay(map_gobj, Callable(Objdisplay, &"gcDrawDObjTreeDLLinksForGObj"), 6, GOBJ_PRIORITY_DEFAULT, ~0)
	Grmodelsetup.grModelSetupGroundDObjs(map_gobj, Grdisplay.grDisplayPtrAdd(map_file, llFoxSpecial3EntryArwingDObjDesc), sector.map_dobjs, dGRSectorArwingTransformKinds)
	Objman.gcAddGObjProcess(map_gobj, Callable(Grdisplay, &"gcPlayAnimAll"), nGCProcessKindFunc, 5)

	sector.arwing_status = 0
	sector.arwing_flight_pattern = -1
	sector.arwing_appear_timer = 600
	sector.arwing_type_cycle = 3
	sector.arwing_pilot_curr = -1
	sector.arwing_pilot_prev = 0
	sector.arwing_target_x = 0.0

	map_gobj.gobj_flags = GOBJ_FLAG_HIDDEN

	if sector.map_dobjs[10] != null:
		Grdisplay.gcAddDObjAnimJoint(sector.map_dobjs[10], Grdisplay.grDisplayPtrAdd(map_file, llFoxSpecial3_2E74_AnimJoint), 0.0)
	Grdisplay.gcPlayAnimAll(map_gobj)
	Mpcollision.mpCollisionSetYakumonoOffID(1)
	sector.weapon_head = Grdisplay.grDisplayPtrAdd(gMPCollisionGroundData.header, -llGRSectorMapMapHeader)

## 0x80107FCC
static func grSectorMakeGround():
	var map_gobj = Objman.gcMakeGObjSPAfter(nGCCommonKindGround, null, nGCCommonLinkIDGround, GOBJ_PRIORITY_DEFAULT)

	grSectorInitAll()
	Objman.gcAddGObjProcess(map_gobj, Callable(Grsector, &"grSectorProcUpdate"), nGCProcessKindFunc, 4)

	return map_gobj

# BEGIN GENERATED FILE IMAGES (tools/port/gr/gen_gr_file_images.py - do not edit by hand)
## relocData words read by the ground code, from baserom.us.z64 (US v1.0, SHA-1 e2929e10fccc0aa84e5776227e798abc07cedabf).
## Same bytes as the typed C in sources/ssb-decomp-re/src/relocData/<file>.c. "w": {byte_offset: [u32 words]},
## "p": relocated pointer slots {byte_offset: [file_id, byte_offset, kind]} (kind 1 AObjEvent32, 2 SYInterpDesc, 0 other).
const dGRSectorFileImages: Array = [
	{"fid": 109, "name": "StageSectorFile2", "w": {
		0x44C8: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000,
			0x45B7DAC1, 0x43A40D6C, 0xC67B5E54, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000002, 0x00000000, 0xC5D775FD, 0x45184D7C, 0xC6620E31, 0x00000000, 0x00000000,
			0x3E97E9D9, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000, 0x46480503, 0x44E10000,
			0xC641DF5D, 0x00000000, 0x00000000, 0xBE0EFA1E, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002,
			0x00000000, 0xC38D743B, 0x45834000, 0xC5FEAC88, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x00008002, 0x00000000, 0x44A8C000, 0x44E4C000, 0xC5A32000, 0x00000000,
			0x00000000, 0x00000000, 0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x00000001, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000,
			0x00000002, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000,
			0x4598D000, 0xC3960000, 0xC4A8C003, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00008003, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x4710: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x8680: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000002, 0x00000000, 0x46059800, 0x43160000, 0xBA295853, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00008003, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002,
			0x00000000, 0x4598D000, 0xC3960000, 0x44A8BFFD, 0x00000000, 0x00000000, 0x00000000, 0x3F800000,
			0x3F800000, 0x3F800000, 0x00008003, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00008002, 0x00000000, 0x44A8C000,
			0x44E4C000, 0x45A32000, 0x00000000, 0x00000000, 0x00000000, 0x3727C5AC, 0x3727C5AC, 0x3727C5AC,
			0x00008002, 0x00000000, 0x44A8C000, 0xC5250000, 0x45A32000, 0x00000000, 0x00000000, 0x00000000,
			0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x00000002, 0x00000000, 0xC623ECBA, 0xC4F59EBE, 0x45B747AF,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000,
			0xC6B687EC, 0x44118503, 0x45A25CAB, 0x00000000, 0x00000000, 0x3E916873, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000012, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x8B00: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000],
		}, "p": {
		0x4524: [109, 0x4438, 0],
		0x4550: [109, 0x4448, 0],
		0x457C: [109, 0x4458, 0],
		0x45A8: [109, 0x4468, 0],
		0x45D4: [109, 0x4478, 0],
		0x462C: [109, 0x4488, 0],
		0x4658: [109, 0x4498, 0],
		0x4684: [109, 0x44A8, 0],
		0x46B0: [109, 0x44B8, 0],
		0x4718: [109, 0x4740, 1],
		0x471C: [109, 0x4774, 1],
		0x4720: [109, 0x47B8, 1],
		0x4724: [109, 0x47FC, 1],
		0x4728: [109, 0x4840, 1],
		0x4738: [109, 0x4C10, 1],
		0x86B0: [109, 0x85E0, 0],
		0x86DC: [109, 0x85F0, 0],
		0x8708: [109, 0x8600, 0],
		0x8734: [109, 0x8610, 0],
		0x8760: [109, 0x8620, 0],
		0x878C: [109, 0x8630, 0],
		0x87B8: [109, 0x8640, 0],
		0x87E4: [109, 0x8650, 0],
		0x8810: [109, 0x8660, 0],
		0x883C: [109, 0x8670, 0],
		0x8B0C: [109, 0x8B2C, 1],
		0x8B14: [109, 0x9568, 1],
		0x8B1C: [109, 0x9FA4, 1],
		0x8B20: [109, 0xA374, 1],
		0x8B24: [109, 0xA738, 1],
		0x8B28: [109, 0xA794, 1],
		}},
	{"fid": 153, "name": "StageSectorFile3", "w": {
		0x0000: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x466A6000, 0x458CA000, 0xBA945F9E, 0x4680E800,
			0x458CA000, 0xBAA350D3, 0x460CA000, 0x458CA000, 0xBA31FEEB, 0x368637BD, 0x458CA000, 0x00000000,
			0xC60CA000, 0x458CA000, 0x3A31FEEB, 0xC680E800, 0x458CA000, 0x3AA350D3, 0xC66A6000, 0x458CA000,
			0x3A945F9E, 0x00000000, 0x3E68BA41, 0x3F000000, 0x3F45D170, 0x3F800000, 0x48095440, 0xC8C96A80,
			0x485E2B00, 0x47D6D800, 0x461C4000, 0x45AFC800, 0xC66A6000, 0xC6F42400, 0x4756D800, 0x4793B480,
			0x45AFC800, 0xC5EA6000, 0xC7260400, 0x46EA6000, 0x47AFC800, 0x48095440, 0xC8127C00, 0xC8225A80,
			0x47D6D800, 0x4793B480, 0x03000005, 0x3F000000, 0x00000000, 0x44898000, 0x00000000, 0x00000000,
			0x1A040000, 0x00000000, 0x0A040000, 0x00000000, 0x3BF7B684, 0x0A040045, 0x3E800000, 0x3A619E06,
			0x060401F4, 0x3F28F5C3, 0x0E040000, 0x3A6709D7, 0x0A04001E, 0x3F800000, 0x3CC8A4A2, 0x00000000,
			0x1E010237, 0x1E000020, 0x00000000, 0x1E000237, 0x1E010020, 0x00000000, 0x466A6000, 0x459F6000,
			0x44490F10, 0x4680E800, 0x459F6000, 0x43C8B7BB, 0x460CA000, 0x459F6000, 0xBF2EA971, 0x368637BD,
			0x459F6000, 0x00000000, 0xC60CA000, 0x459F6000, 0xB76AE18B, 0xC680E800, 0x459F6000, 0xC4160000,
			0xC66A6000, 0x459F6000, 0xC4960000, 0x00000000, 0x3E68D2E5, 0x3EFFE133, 0x3F45AD32, 0x3F800000,
			0x4809B950, 0xC8C9ADC2, 0x485DD0E7, 0x47D78B83, 0x461F0FE1, 0x45BC7FF5, 0xC67B519C, 0xC6EC6372,
			0x4755705E, 0x4793CAE2, 0x45CBD7A2, 0xC607DFA3, 0xC7247680, 0x46EA60E8, 0x47AFC800, 0x480A3540,
			0xC814D400, 0xC8216080, 0x47D86800, 0x4793E680, 0x03000005, 0x3F000000, 0x00000000, 0x4489ABC2,
			0x00000000, 0x00000000, 0x1A040000, 0x00000000, 0x06040000, 0x00000000, 0x06040257, 0x3F800000,
			0x00000000],
		0x0250: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x46AD7000, 0x45160000, 0xBADEB0FB, 0x46859800,
			0x44610000, 0xBAA936C6, 0x45FD2000, 0x45034000, 0xBA206EA0, 0x45834000, 0x45960000, 0xB9B24207,
			0xC4E10000, 0x45160000, 0x390E9B39, 0xC680E800, 0x45610000, 0x3AA350D3, 0xC6C4E000, 0x45E10000,
			0x3AF66A55, 0x00000000, 0x3E83FB37, 0x3ECA87A0, 0x3F14E5C5, 0x3F800000, 0x48494500, 0xC8C49500,
			0xC60E3000, 0x48441800, 0x4757D200, 0x4868E900, 0xC8E72700, 0x48AC5080, 0xC809E400, 0x47451200,
			0x489191A0, 0xC8F3C000, 0x48A99AC0, 0xC7535400, 0x46D4E400, 0x4904C510, 0xC98E4F40, 0x47FC7100,
			0x4901D580, 0x47E94080, 0x03000005, 0x3F000000, 0x00000000, 0x449326E4, 0x00000000, 0x00000000,
			0x1A040000, 0x00000000, 0x12020000, 0x00000000, 0x0C040000, 0x00000000, 0x3B2E0534, 0x14018000,
			0x00000000, 0xC0490FDB, 0x0C040063, 0x3E4CCCCD, 0x3A4A35A7, 0x1002004F, 0xBDA3D709, 0x08020366,
			0xBDA3D709, 0x04000014, 0x06040302, 0x3F333333, 0x0E040000, 0x3A8E3765, 0x0A040050, 0x3F800000,
			0x3C15964F, 0x00000000, 0x1E01036F, 0x1E00003D, 0x1E010009, 0x00000000, 0x1E00036F, 0x1E01003D,
			0x1E000009, 0x00000000],
		0x03E0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x4636D000, 0x45F30756, 0xC64C008C, 0x467D2000,
			0x45D2E522, 0xC656F35E, 0x45B21FFE, 0x45D30E01, 0xC65E501D, 0xC6115002, 0x45F35913, 0xC65ABA09,
			0xC68EF800, 0x4610FAD7, 0xC61E82EB, 0xC65C5000, 0x45ABB6B3, 0xC4BB7FF8, 0x43960000, 0x454E4000,
			0xB7C0F020, 0x4680E800, 0x468A4800, 0xBAA43BB4, 0x468EF800, 0x4705F6D6, 0xC4BB800C, 0x00000000,
			0x3E00A4E3, 0x3E9C60EE, 0x3EDB04AB, 0x3F0EC99F, 0x3F3CE8FB, 0x3F800000, 0x4886DA87, 0xC959FE18,
			0x4916D7BB, 0x48252B86, 0x4626C11F, 0x489169B3, 0xC906343B, 0xC839A16A, 0x48D0B62A, 0x4830B335,
			0x48522556, 0xC8065B63, 0xC87757CD, 0x476C6912, 0x4822809C, 0x48F268C4, 0xC986EB64, 0x48FBA483,
			0x482CA9C5, 0x4748340C, 0x4947F30A, 0xC9AEDEEC, 0x48DC8AD0, 0x48A0D2BC, 0x48037634, 0x498F5F20,
			0xCA1621A0, 0x4897C1C4, 0x497B6C60, 0x4893830E, 0x03000007, 0x3F000000, 0x00000000, 0x452E79C8,
			0x00000000, 0x00000000, 0x1A040000, 0x00000000, 0x0A040000, 0x00000000, 0x3A95BABF, 0x0A04029D,
			0x3F23D70A, 0x393B5234, 0x060402E4, 0x3F400000, 0x0E040000, 0x3954DE95, 0x0A0400BE, 0x3F800000,
			0x3B427710, 0x00000000, 0x1E010059, 0x1E00003D, 0x1E01026B, 0x1E00003D, 0x1E010301, 0x00000000,
			0x1E000059, 0x1E01003D, 0x1E00026B, 0x1E01003D, 0x1E000301, 0x00000000, 0x4636D000, 0x4602E3AA,
			0xC64A9138, 0x467D2000, 0x45E5A524, 0xC656F35E, 0x45B21FFE, 0x45E5CE04, 0xC65C9DF2, 0xC6115001,
			0x46030C89, 0xC655E65F, 0xC6834000, 0x46151935, 0xC61E82EC, 0xC65C5000, 0x45BE76B3, 0xC4BB7FF8,
			0x43960000, 0x4573C000, 0xB7C0F020, 0x4680E800, 0x468EF800, 0x4460FFEB, 0x468EF800, 0x47084ED6,
			0x4395FFCF, 0x00000000, 0x3E03F9E8, 0x3EA07831, 0x3ED73B43, 0x3F0BC3E7, 0x3F3B1898, 0x3F800000,
			0x4886BE41, 0xC959E14E, 0x4916E1DF, 0x4824C747, 0x462695E9, 0x48B75E50, 0xC925739C, 0xC8455030,
			0x48E54E45, 0x4830AF75, 0x47A3D168, 0xC6C852C9, 0xC74BFB43, 0xC7C99C46, 0x480EEA00, 0x48E39E1B,
			0xC9540B4A, 0x487ABA1C, 0x48521B68, 0x473FED90, 0x4965A176, 0xC9D36CEA, 0x491A2859, 0x48A82D05,
			0x47E7BFEF, 0x498F9E68, 0xCA162FB0, 0x4894D3C4, 0x497C3AA0, 0x4893FCEE, 0x03000007, 0x3F000000,
			0x00000000, 0x452A022B, 0x00000000, 0x00000000, 0x1A040000, 0x00000000, 0x06040000, 0x00000000,
			0x0604063F, 0x3F800000, 0x00000000],
		0x06D0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x46CE4000, 0x45A8C000, 0x00000000, 0x4680E800,
			0x45A8C000, 0x00000000, 0x44BB8000, 0x45A8C000, 0x00000000, 0xC5610000, 0x45A8C000, 0x00000000,
			0xC58CA000, 0x458CA000, 0x00000000, 0xC5610000, 0x4573C000, 0x00000000, 0xC4BB8000, 0x4573C000,
			0x00000000, 0xC4160000, 0x454E4000, 0x00000000, 0xC4BB8000, 0x45160000, 0x00000000, 0xC5BB8000,
			0x45160000, 0x00000000, 0xC628C000, 0x4528C000, 0x00000000, 0xC65C5000, 0x453B8000, 0x44610000,
			0xC673C000, 0x453B8000, 0x454E4000, 0xC66A6000, 0x44BB8000, 0x45B22000, 0xC64E4000, 0x43960000,
			0x45EA6000, 0xC6160000, 0xC3960000, 0x46034000, 0x44BB8000, 0xC4610000, 0x46034000, 0x4607F000,
			0xC4610000, 0x46034000, 0x4657A000, 0xC4160000, 0x46034000, 0x46859800, 0xC3960000, 0x46034000,
			0x466F1000, 0xC3960000, 0x46034000, 0x00000000, 0x3E4160D9, 0x3E8196B7, 0x3E8AF534, 0x3E92595C,
			0x3E9FEAC4, 0x3EA74ECA, 0x3EB07B14, 0x3ECD84B2, 0x3EEC8A7A, 0x3F0171B0, 0x3F0AD2DD, 0x3F144F3C,
			0x3F1D8527, 0x3F29CEC0, 0x3F4DA448, 0x3F64D9D7, 0x3F755193, 0x3F800000, 0x49095440, 0xC9755C80,
			0xC8298800, 0x4907C440, 0x48283040, 0x47A29900, 0xC8920B80, 0x48E1B540, 0xC8AA1E00, 0x47DB3080,
			0x468CA000, 0xC76F1000, 0x47937600, 0xC723AC00, 0x461FC400, 0x448CA000, 0xC5960000, 0x45B09000,
			0x00000000, 0x441C4000, 0x468CA000, 0xC70CA000, 0x45E10000, 0x4628C000, 0x45228000, 0x448CA000,
			0x43960000, 0xC4FA0000, 0xC4AF0000, 0x45228000, 0x4636D000, 0xC5BB8000, 0xC3FA0000, 0x451C4000,
			0x441C4000, 0x46DBBA00, 0xC79A1A00, 0x46CFD000, 0x471BDC00, 0x46021400, 0x4621B800, 0xC6787000,
			0xC6AAB400, 0x46AB1800, 0x46BBE400, 0x44A8C000, 0x44BB8000, 0xC4CE4000, 0xC620F000, 0x4690EC00,
			0x4613A800, 0xC6859800, 0x45066000, 0x454E4000, 0x4613A800, 0x462C4400, 0xC6EA6000, 0x46635800,
			0x45B22000, 0x45E29000, 0x44A8C000, 0x44BB8000, 0xC4098000, 0x43480000, 0x46053400, 0x47A06680,
			0xC7956A00, 0x478D9A00, 0xC6DEA800, 0x462C4400, 0x48A01220, 0xC930F400, 0x47EDCB00, 0x48963E80,
			0x476CEA00, 0x46021400, 0xC7091C00, 0x47B41400, 0xC7E38A00, 0x47B5E280, 0x43E10000, 0xC53B8000,
			0x46480000, 0xC6FEB000, 0x47244200, 0x46D67400, 0xC6834000, 0xC72B7C00, 0x465DE000, 0x4699E800,
			0x03000013, 0x3F000000, 0x00000000, 0x45257A8F, 0x00000000, 0x00000000, 0x1A040000, 0x00000000,
			0x0A040000, 0x00000000, 0x3B3ED022, 0x0A040063, 0x3DF5C28F, 0x39B9E22F, 0x0604044C, 0x3EB33333,
			0x0E040000, 0x39793B37, 0x0A040514, 0x3F800000, 0xB886161B, 0x00000000, 0x1E0103C9, 0x1E00003D,
			0x1E0105BD, 0x00000000, 0x1E0003C9, 0x1E01003D, 0x1E0005BD, 0x00000000, 0x46CE4000, 0x45A8C000,
			0x00000000, 0x4680E800, 0x45A8C000, 0x00000000, 0x44BB8000, 0x45A8C000, 0x00000000, 0xC5610000,
			0x45A8C000, 0x00000000, 0xC58CA000, 0x458CA000, 0x00000000, 0xC5610000, 0x4573C000, 0x00000000,
			0xC4BB8000, 0x4573C000, 0x00000000, 0xC4160000, 0x454E4000, 0x00000000, 0xC4BB8000, 0x45160000,
			0x00000000, 0xC5BB8000, 0x45160000, 0x00000000, 0xC6241000, 0x4528C000, 0x43960000, 0xC64E4000,
			0x453B8000, 0x44BB8000, 0xC6610000, 0x453B8000, 0x45610000, 0xC6610000, 0x44E10000, 0x45B22000,
			0xC64E4000, 0x44160000, 0x45EA6000, 0xC6160000, 0xC3960000, 0x46034000, 0x44BB8000, 0xC4610000,
			0x46034000, 0x4607F000, 0xC4610000, 0x46034000, 0x4657A000, 0xC4160000, 0x46034000, 0x46859800,
			0xC3960000, 0x46034000, 0x466F1000, 0xC3960000, 0x46034000, 0x00000000, 0x3E46366D, 0x3E84D402,
			0x3E8E6E87, 0x3E9601DE, 0x3EA3EA2D, 0x3EAB7D85, 0x3EB4E486, 0x3ED2A865, 0x3EF08F00, 0x3F0231B6,
			0x3F0A5700, 0x3F127126, 0x3F1AD0E5, 0x3F27A68B, 0x3F4C620B, 0x3F642C1B, 0x3F750D39, 0x3F800000,
			0x49095440, 0xC9755C80, 0xC8298800, 0x4907C440, 0x48283040, 0x47A29900, 0xC8920B80, 0x48E1B540,
			0xC8AA1E00, 0x47DB3080, 0x468CA000, 0xC76F1000, 0x47937600, 0xC723AC00, 0x461FC400, 0x448CA000,
			0xC5960000, 0x45B09000, 0x00000000, 0x441C4000, 0x468CA000, 0xC70CA000, 0x45E10000, 0x4628C000,
			0x45228000, 0x448CA000, 0x43960000, 0xC4FA0000, 0xC4AF0000, 0x45228000, 0x4636D000, 0xC5BB8000,
			0xC3FA0000, 0x451C4000, 0x441C4000, 0x4702F500, 0xC7AF3200, 0x46E03800, 0x4722E400, 0x46021400,
			0x46102400, 0xC63B8000, 0xC6B1BC00, 0x468D6800, 0x46B02C00, 0x43E10000, 0xC5160000, 0x460FC000,
			0xC66BF000, 0x466C5400, 0x45859800, 0xC60CA000, 0x4581B000, 0xC47A0000, 0x45E35800, 0x456F1000,
			0xC61AB000, 0x45610000, 0x453B8000, 0x45B22000, 0x4593A800, 0xC4610000, 0xC51C4000, 0x45034000,
			0x45C28800, 0x477E0100, 0xC7334C00, 0x4742EC00, 0xC68B1000, 0x4616C800, 0x489FBDC0, 0xC930A900,
			0x47EDE400, 0x4895DA80, 0x476DCB00, 0x46021400, 0xC7091C00, 0x47B41400, 0xC7E38A00, 0x47B5E280,
			0x43E10000, 0xC53B8000, 0x46480000, 0xC6FEB000, 0x47244200, 0x46D67400, 0xC6834000, 0xC72B7C00,
			0x465DE000, 0x4699E800, 0x03000013, 0x3F000000, 0x00000000, 0x45217166, 0x00000000, 0x00000000,
			0x1A040000, 0x00000000, 0x06040000, 0x00000000, 0x060409C3, 0x3F800000, 0x00000000],
		0x0D10: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x45034000, 0x46A41000, 0x00000000, 0x44BB8000,
			0x4644E000, 0x00000000, 0x44610000, 0x45834000, 0x00000000, 0xC4BB8000, 0x44960000, 0x00000000,
			0xC573C000, 0x45834000, 0x00000000, 0xC58CA000, 0x4644E000, 0x00000000, 0xC59F6000, 0x46A41000,
			0x00000000, 0x00000000, 0x3EAA6B0E, 0x3F000000, 0x3F2ACA79, 0x3F800000, 0x460CA000, 0x00000000,
			0xC7403000, 0x00000000, 0x4799E800, 0x447A0000, 0x00000000, 0x46E42000, 0xC773C000, 0x4716C800,
			0x447A0000, 0xC57A0000, 0x47098000, 0x00000000, 0x45C80000, 0x460CA000, 0xC70CA000, 0x45960000,
			0x4773C000, 0x4716C800, 0x02000005, 0x00000000, 0x00000000, 0x443D5B82, 0x00000000, 0x00000000,
			0x1A040000, 0x00000000, 0x12008000, 0x3F490FDB, 0x0C040000, 0x00000000, 0x3BC68E56, 0x14030000,
			0xBFC90FDB, 0x00000000, 0x0C0400C7, 0x3EE66666, 0x39A0781A, 0x0A008095, 0x00000000, 0xBAABDBFA,
			0x080081C2, 0x00000000, 0x04000032, 0x0604015E, 0x3F0CCCCD, 0x0E040000, 0x3A1206C4, 0x0C0400C8,
			0x3F800000, 0x3B461029, 0x04000032, 0x0E008000, 0x3B56A842, 0x10008064, 0x3F490FDB, 0x06008032,
			0x3F490FDB, 0x00000000, 0x1E0102ED, 0x00000000, 0x1E0002ED, 0x00000000],
		0x0EB0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x469F6000, 0xC4F53713, 0xC657A000, 0x468A4800,
			0xC4924000, 0xC6834000, 0x45FD2000, 0x44F0BA6E, 0xC652F000, 0x44960000, 0x45842F72, 0xC5E10000,
			0xC4E10000, 0x4587F000, 0x44E10000, 0xC5160000, 0x442BDBA6, 0x463566DF, 0xC5BB8000, 0x4557A000,
			0x4680E800, 0xC6115000, 0x4621B800, 0x4690B400, 0xC6403000, 0x464D5675, 0x46960000, 0xC63B8000,
			0x460D24EA, 0x468B7FFF, 0x00000000, 0x3E37008A, 0x3EAEC311, 0x3F00778A, 0x3F2DB036, 0x3F4B866E,
			0x3F6D9D99, 0x3F800000, 0x48897E2B, 0xC9284AC2, 0x4855A9A3, 0x48761E3F, 0x4734A810, 0x46077D68,
			0xC2AEC420, 0xC70A01E2, 0x46309E0E, 0x47D58665, 0x46A3A576, 0xC74E4381, 0x46CD5363, 0x468543D4,
			0x47B75D32, 0x48CADBD3, 0xC934FBE7, 0x47F45C3C, 0x481CC40B, 0x47CDCA9C, 0x47468B12, 0xC8331A22,
			0x4850074C, 0xC7B5F6EA, 0x477E7E00, 0x482BAC16, 0xC8B117A2, 0x4795C88C, 0x47BD4850, 0x474CCFE8,
			0x47287BFB, 0xC64EE720, 0xC78701D8, 0x452A2662, 0x4718E4F0, 0x03000008, 0x3F000000, 0x00000000,
			0x44F8E58B, 0x00000000, 0x00000000, 0x1A040000, 0x00000000, 0x06040000, 0x00000000, 0x0604017B,
			0x3F800000, 0x08040398, 0x3F800000, 0x04000014, 0x00000000, 0x1E010027, 0x1E00003D, 0x1E01012B,
			0x00000000, 0x1E000027, 0x1E01003D, 0x1E00012B, 0x00000000, 0x46A1DC00, 0xC4C11587, 0xC660592F,
			0x468A4800, 0xC40E8000, 0xC6834000, 0x45FCD801, 0x451DDD37, 0xC64EB800, 0x44BB8000, 0x459137D5,
			0xC5E19260, 0xC4C4E000, 0x4594B000, 0x44DF8000, 0xC5334000, 0x449FC000, 0x4631F000, 0xC5C09000,
			0x4570F000, 0x467BD000, 0xC6192178, 0x4622B14D, 0x468EC442, 0xC640D800, 0x464EEBC4, 0x469298B9,
			0xC62FB510, 0x4614B0EE, 0x468590EE, 0x00000000, 0x3E3CEAAF, 0x3EAFC0F4, 0x3F0205DE, 0x3F2F709B,
			0x3F4C532A, 0x3F6EBE6A, 0x3F800000, 0x488BF7DA, 0xC927A988, 0x483D5E70, 0x48805DAE, 0x47405D4F,
			0x457E0AC8, 0x45E8F368, 0xC5223CE0, 0xC6C2856A, 0x47CEF560, 0x46DC1F3E, 0xC78B2F7C, 0x46C45D40,
			0x46FE8E0A, 0x47AFC1AE, 0x48A790A8, 0xC9140839, 0x47903100, 0x48105ACB, 0x47CC54DA, 0x46F1580F,
			0xC8007870, 0x483A8490, 0xC7CA9998, 0x4776788C, 0x48181272, 0xC89BE41A, 0x47301530, 0x47CEA763,
			0x474221E2, 0x470FAD8A, 0xC4E8BDC2, 0xC784939A, 0xC534AF8C, 0x4710AECC, 0x03000008, 0x3F000000,
			0x00000000, 0x44F2F92F, 0x00000000, 0x00000000, 0x1A040000, 0x00000000, 0x06040000, 0x00000000,
			0x0604017B, 0x3F800000, 0x06040014, 0x3F800000, 0x00000000],
		0x11D0: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x45EA6000, 0x45B22000, 0x462D7000, 0x45FD2000,
			0x459F6000, 0x4652F000, 0x45834000, 0x454E4000, 0x45FD2000, 0xC3960000, 0x45034000, 0x43960000,
			0xC5610000, 0x45160000, 0xC5C4E000, 0xC5B22000, 0x45610000, 0xC61F6000, 0xC5FD2000, 0x45BB8000,
			0xC657A000, 0xC61F6000, 0x461F6000, 0xC67D2000, 0xC63B8000, 0x4673C000, 0xC68CA000, 0xC636D000,
			0x46834000, 0xC687F000, 0x00000000, 0x3E200C52, 0x3EB93294, 0x3F075F70, 0x3F220557, 0x3F3EC82E,
			0x3F5D69D3, 0x3F800000, 0x47E87880, 0xC8B22000, 0x485D0B80, 0x47A1B800, 0x45DEA800, 0x47261D00,
			0xC7AA8200, 0xC773C000, 0x47D99400, 0x4789B200, 0x45CBE800, 0xC5B22000, 0xC6DEA800, 0xC5F0A000,
			0x4791F280, 0x469E3400, 0xC751C400, 0x47B6E900, 0xC791E600, 0x4719B600, 0x456F1000, 0xC5160000,
			0xC6234800, 0x4639F000, 0x46C22400, 0x44E10000, 0xC6034000, 0x46147000, 0x45802000, 0x46D89A00,
			0x47AE0600, 0xC803D600, 0xC7635800, 0x47A12200, 0x4707A500, 0x03000008, 0x3F000000, 0x00000000,
			0x44B86BD9, 0x00000000, 0x00000000, 0x1A040000, 0x00000000, 0x06040000, 0x00000000, 0x0604017B,
			0x3F800000, 0x06040014, 0x3F800000, 0x00000000, 0x1E01004F, 0x1E00003D, 0x1E010103, 0x00000000,
			0x1E00004F, 0x1E01003D, 0x1E000103, 0x00000000, 0x46499000, 0x46241000, 0x4693A800, 0x46322000,
			0x460CA000, 0x46960000, 0x45D7A000, 0x45B22000, 0x4657A000, 0x4573C000, 0x4573C000, 0x45FD2000,
			0xC3960000, 0x4528C000, 0x43960000, 0xC54E4000, 0x45160000, 0xC5D7A000, 0xC5C4E000, 0x454E4000,
			0xC61AB000, 0xC5FD2000, 0x45FD2000, 0xC65C5000, 0xC6160000, 0x461AB000, 0xC680E800, 0xC6499000,
			0x46787000, 0xC68EF800, 0xC665B000, 0x469D0800, 0xC68A4800, 0x00000000, 0x3E16C26A, 0x3E8C4C16,
			0x3EE2EBE6, 0x3F1750E3, 0x3F2CD866, 0x3F4D0870, 0x3F5D9C7C, 0x3F800000, 0x48133780, 0xC8B3E200,
			0x47D8CC00, 0x4808D100, 0x46B89200, 0x46DD7C00, 0xC752F000, 0x47C99000, 0xC7830E00, 0x475EF300,
			0x47005200, 0xC78C0A00, 0xC7470600, 0x47C2EC00, 0x4783E280, 0x470D8100, 0xC72FC800, 0xC7689E00,
			0x46E8D000, 0x47976A80, 0x47B90280, 0xC83A9F00, 0x48389200, 0xC7C6D400, 0x47185800, 0x480C2F80,
			0xC890DF80, 0x47696600, 0x47B15800, 0x46E90200, 0x480CD840, 0xC8859800, 0x48666B80, 0xC7CE4000,
			0x46D4B200, 0x47F4C680, 0xC8828480, 0x46E35800, 0x47ECB800, 0x46DC5000, 0x03000009, 0x3F000000,
			0x00000000, 0x44DC4672, 0x00000000, 0x00000000, 0x1A040000, 0x00000000, 0x06040000, 0x00000000,
			0x0604017B, 0x3F800000, 0x06040014, 0x3F800000, 0x00000000],
		0x1510: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0xC5F6C001, 0x469ACE00, 0xC69221FE, 0xC5F4C800,
			0x469A5600, 0xC692F400, 0xC5D6B000, 0x468B1A00, 0xC6906C00, 0xC5BA9000, 0x4678AC00, 0xC68D11FE,
			0xC59D0800, 0x46598000, 0xC688C200, 0xC5852000, 0x463E5000, 0xC6848A00, 0xC554D000, 0x46208C00,
			0xC67EC400, 0xC5250000, 0x4603F400, 0xC672D000, 0xC4F5A000, 0x45CEB800, 0xC663D000, 0xC4B40000,
			0x45960000, 0xC64FE400, 0xC48E8000, 0x454A224B, 0xC634B400, 0xC47F0000, 0x451CC868, 0xC61A3800,
			0xC473C000, 0x4514CB8C, 0xC6073C00, 0xC4700000, 0x4513EFA2, 0xC5D72800, 0xC4816000, 0x45142000,
			0x4455C000, 0xC4C4E000, 0x4529B000, 0x457F0000, 0xC5403000, 0x458A4800, 0x45E79000, 0xC5AA2800,
			0x45DDB800, 0x46266800, 0xC6021400, 0x46239800, 0x46554800, 0xC62B9000, 0x4656B000, 0x4678AC00,
			0xC6280C00, 0x46550C00, 0x466D3000, 0x00000000, 0x3D24CC68, 0x3DA278D1, 0x3DF7BBF9, 0x3E20E347,
			0x3E49EADD, 0x3E71C151, 0x3E8D4153, 0x3EA2A455, 0x3EB8CE2D, 0x3ECA2F27, 0x3ED5AE3E, 0x3EE6440F,
			0x3F1763C3, 0x3F26EAC8, 0x3F39E0D6, 0x3F507CFA, 0x3F6995EE, 0x3F800000, 0x463CDC73, 0xC6F812F1,
			0x464473BC, 0x462A0C31, 0x44B27F6E, 0x42C4103C, 0xC33417A8, 0x44BCE242, 0xC49B2577, 0x45A30CDA,
			0x43F80F36, 0xC45B2574, 0xC5320625, 0x45319F41, 0x45A8EB95, 0x4426B3B7, 0xC4B0AB65, 0x4588D42D,
			0xC56F6F66, 0x459CD468, 0x43619000, 0xC3F66000, 0xC4D35000, 0x45102400, 0x45969C80, 0x42094000,
			0xC2040000, 0x4432B800, 0xC43E3000, 0x45A18100, 0x42364000, 0x420D0000, 0x42EA0000, 0x431CC000,
			0x45A01C80, 0x434F5ECC, 0xC28B92B8, 0xC466F3EA, 0x4495A8FB, 0x45AB3100, 0x44BF1986, 0xC5143C12,
			0xC58EA312, 0x45867A5C, 0x45B8096D, 0x4421E325, 0xC4C08427, 0x428D3E80, 0xC4AF218A, 0x45958911,
			0x454C42C2, 0xC5DA6662, 0x4615C8E3, 0xC5B9D0C0, 0x45202204, 0x478F3D1D, 0xC7AB7AC6, 0x47500336,
			0xC67C58F6, 0x451B1A0C, 0x48867FC1, 0xC90C930E, 0x4803BB2A, 0x4829C8CB, 0x46C44690, 0x475D0E00,
			0xC80BB2BB, 0x482E93F8, 0xC7D9ED4D, 0x47030045, 0x44035800, 0xC5353800, 0x4475A000, 0x46067A00,
			0x465EE280, 0x4407B400, 0xC51EAC00, 0xC51C4C00, 0x4635E000, 0x46A7CF00, 0x45613600, 0xC5EC4C00,
			0xC6708D00, 0x46960C80, 0x46DF9DA0, 0x475F5C60, 0xC783F1C0, 0xC76B82C0, 0x47389F40, 0x46DE7760,
			0x03000013, 0x3F000000, 0x00000000, 0x44E3BF92, 0x00000000, 0x00000000, 0x1A040000, 0x00000000,
			0x06040000, 0x00000000, 0x0604018F, 0x3F800000, 0x00000000, 0x1E01004F, 0x1E00003D, 0x1E010103,
			0x00000000, 0x1E00004F, 0x1E01003D, 0x1E000103, 0x00000000, 0xC5F91801, 0x469F7E00, 0xC68D6602,
			0xC5F87000, 0x469F0600, 0xC68E3200, 0xC5DCF800, 0x468FCA00, 0xC68C87FF, 0xC5C22800, 0x46810600,
			0xC68A11FF, 0xC5A42800, 0x46613C00, 0xC6865800, 0xC589D000, 0x4643B400, 0xC6822C00, 0xC561F000,
			0x46293800, 0xC67A8C00, 0xC5310000, 0x460D5400, 0xC66FD000, 0xC5055000, 0x45E10000, 0xC6626800,
			0xC4C600C5, 0x45A8760E, 0xC64F1D0B, 0xC49A2000, 0x45700000, 0xC6348FFD, 0xC484BE77, 0x45408B96,
			0xC619B536, 0xC476BCED, 0x4538D852, 0xC608DED3, 0xC4700000, 0x4537C000, 0xC5D72800, 0xC4816000,
			0x4539A000, 0x4455C000, 0xC4C4E000, 0x454F3000, 0x457F0000, 0xC546C000, 0x459D0800, 0x45E79000,
			0xC5B717FA, 0x45F07800, 0x46266800, 0xC60C9400, 0x462CF800, 0x46554800, 0xC63BBC03, 0x46601000,
			0x4678AC00, 0xC639DC03, 0x465E6C00, 0x466D3000, 0x00000000, 0x3D20029F, 0x3D9E2585, 0x3DF5E636,
			0x3E22B991, 0x3E4777D1, 0x3E6DEE78, 0x3E8AFFB0, 0x3EA00C52, 0x3EB5C1A4, 0x3EC75FB3, 0x3ED18AEC,
			0x3EE2FE61, 0x3F158256, 0x3F24EFAA, 0x3F37F6D3, 0x3F4F29A2, 0x3F68C187, 0x3F800000, 0x46347D1E,
			0xC6EDB097, 0x463DEF0E, 0x46222880, 0x44A8D58A, 0x436512A9, 0xC3ADD21C, 0x450EAE31, 0xC4CFA914,
			0x459C9C59, 0x44131D95, 0xC49738A9, 0xC5390783, 0x4565C5E0, 0x45AC54A1, 0x417B4615, 0xC24E09EE,
			0x43E7773C, 0xC4A850E8, 0x45AF4964, 0x4351067D, 0xC3EFF86E, 0x44FC58D8, 0xC4EDCAEC, 0x45928E34,
			0x42380D76, 0xC2351571, 0xC2C2C0B8, 0x43F75E40, 0x458DBA67, 0x430BA494, 0xC28B2B1A, 0xC337F97A,
			0x4406BEE3, 0x459A2B38, 0x4315076D, 0xC217CD62, 0xC47BB46A, 0x44A12FB4, 0x45A773C6, 0x4496C92A,
			0xC4E7460B, 0xC57EF734, 0x456BE404, 0x45B3C1B9, 0x44921763, 0xC500D732, 0xC4BC026A, 0xBF9677FF,
			0x459618FC, 0x45B7C110, 0xC63C5611, 0x4658450E, 0xC5EEDC02, 0x45165274, 0x477AE7F5, 0xC78CFE10,
			0x4730B95A, 0xC65B4E11, 0x4517D866, 0x4883C794, 0xC9095C15, 0x47F82E3E, 0x482977AF, 0x46C89E5A,
			0x475EB940, 0xC80C2860, 0x482ED8A0, 0xC7DA26A0, 0x470305B0, 0x43FCA9E7, 0xC51F8D4B, 0x44A6D6C4,
			0x46089D3B, 0x4660CAC0, 0x44918B19, 0xC58D68FC, 0xC5409234, 0x4660DA4E, 0x46AF2268, 0x45412EEC,
			0xC5CB9510, 0xC66BFA1C, 0x4691B986, 0x46ED3BBA, 0x477378AA, 0xC792E1F9, 0xC779F888, 0x474BAD1E,
			0x46EE38D0, 0x03000013, 0x3F000000, 0x00000000, 0x44E54BCF, 0x00000000, 0x00000000, 0x1A040000,
			0x00000000, 0x06040000, 0x00000000, 0x0604018F, 0x3F800000, 0x00000000],
		0x1B34: [0x15C00000, 0x3F800000, 0x3F800000, 0x3F800000, 0x15C00002, 0x3727C5AC, 0x3727C5AC, 0x3727C5AC,
			0x15C00002, 0x40200000, 0x40200000, 0x40200000, 0x15C00002, 0x3727C5AC, 0x3727C5AC, 0x3727C5AC,
			0x00000000],
		0x1B84: [0x11C00000, 0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x11C00005, 0x40200000, 0x40200000, 0x40200000,
			0x0BC00003, 0x3727C5AC, 0xBE99999B, 0x3727C5AC, 0xBE99999B, 0x3727C5AC, 0xBE99999B, 0x11C00002,
			0x3F800000, 0x3F800000, 0x3F800000, 0x11C00002, 0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x00000000],
		0x1D34: [0x10020000, 0x00000000, 0x10020059, 0xC0C90FDB, 0x00000000],
		0x1D54: [0x10020000, 0x00000000, 0x0A02001D, 0xC0490FDB, 0xBDA4F950, 0x1002000A, 0xC0490FDB, 0x06020050,
			0xC0490FDB, 0x0E020000, 0xBCC5F7FC, 0x0A020032, 0xC0C90FDB, 0xBD3DA72E, 0x0A02000A, 0xC0C90FDB,
			0xBC050481, 0x00000000],
		0x1DA4: [0x10100000, 0x00000000, 0x1010001D, 0xC1F00000, 0x1010001E, 0x00000000, 0x00000000],
		0x1DC4: [0x10100000, 0x00000000, 0x1010001D, 0x41F00000, 0x1010001E, 0x00000000, 0x00000000],
		0x1DE4: [0x10100000, 0x00000000, 0x0A100077, 0x468ECCEB, 0x43952514, 0x00000000],
		}, "p": {
		0x0000: [153, 0x0100, 1],
		0x001C: [153, 0x0140, 1],
		0x0024: [153, 0x014C, 1],
		0x002C: [153, 0x0228, 1],
		0x00F0: [153, 0x0030, 0],
		0x00F8: [153, 0x0084, 0],
		0x00FC: [153, 0x0098, 0],
		0x0104: [153, 0x00E8, 2],
		0x0218: [153, 0x0158, 0],
		0x0220: [153, 0x01AC, 0],
		0x0224: [153, 0x01C0, 0],
		0x022C: [153, 0x0210, 2],
		0x0250: [153, 0x0350, 1],
		0x026C: [153, 0x03B8, 1],
		0x0274: [153, 0x03C8, 1],
		0x0340: [153, 0x0280, 0],
		0x0348: [153, 0x02D4, 0],
		0x034C: [153, 0x02E8, 0],
		0x0354: [153, 0x0338, 2],
		0x03E0: [153, 0x0528, 1],
		0x03FC: [153, 0x0568, 1],
		0x0404: [153, 0x0580, 1],
		0x040C: [153, 0x06B0, 1],
		0x0518: [153, 0x0410, 0],
		0x0520: [153, 0x047C, 0],
		0x0524: [153, 0x0498, 0],
		0x052C: [153, 0x0510, 2],
		0x06A0: [153, 0x0598, 0],
		0x06A8: [153, 0x0604, 0],
		0x06AC: [153, 0x0620, 0],
		0x06B4: [153, 0x0698, 2],
		0x06D0: [153, 0x09C8, 1],
		0x06EC: [153, 0x0A08, 1],
		0x06F4: [153, 0x0A18, 1],
		0x06FC: [153, 0x0CF0, 1],
		0x09B8: [153, 0x0700, 0],
		0x09C0: [153, 0x07FC, 0],
		0x09C4: [153, 0x0848, 0],
		0x09CC: [153, 0x09B0, 2],
		0x0CE0: [153, 0x0A28, 0],
		0x0CE8: [153, 0x0B24, 0],
		0x0CEC: [153, 0x0B70, 0],
		0x0CF4: [153, 0x0CD8, 2],
		0x0D10: [153, 0x0E10, 1],
		0x0D2C: [153, 0x0E98, 1],
		0x0D34: [153, 0x0EA0, 1],
		0x0E00: [153, 0x0D40, 0],
		0x0E08: [153, 0x0D94, 0],
		0x0E0C: [153, 0x0DA8, 0],
		0x0E14: [153, 0x0DF8, 2],
		0x0EB0: [153, 0x101C, 1],
		0x0ECC: [153, 0x1044, 1],
		0x0ED4: [153, 0x1054, 1],
		0x0EDC: [153, 0x11A0, 1],
		0x100C: [153, 0x0EE0, 0],
		0x1014: [153, 0x0F58, 0],
		0x1018: [153, 0x0F78, 0],
		0x1020: [153, 0x1004, 2],
		0x1190: [153, 0x1064, 0],
		0x1198: [153, 0x10DC, 0],
		0x119C: [153, 0x10FC, 0],
		0x11A4: [153, 0x1188, 2],
		0x11D0: [153, 0x133C, 1],
		0x11EC: [153, 0x1360, 1],
		0x11F4: [153, 0x1370, 1],
		0x11FC: [153, 0x14E0, 1],
		0x132C: [153, 0x1200, 0],
		0x1334: [153, 0x1278, 0],
		0x1338: [153, 0x1298, 0],
		0x1340: [153, 0x1324, 2],
		0x14D0: [153, 0x1380, 0],
		0x14D8: [153, 0x1404, 0],
		0x14DC: [153, 0x1428, 0],
		0x14E4: [153, 0x14C8, 2],
		0x1510: [153, 0x1808, 1],
		0x152C: [153, 0x1824, 1],
		0x1534: [153, 0x1834, 1],
		0x153C: [153, 0x1B0C, 1],
		0x17F8: [153, 0x1540, 0],
		0x1800: [153, 0x163C, 0],
		0x1804: [153, 0x1688, 0],
		0x180C: [153, 0x17F0, 2],
		0x1AFC: [153, 0x1844, 0],
		0x1B04: [153, 0x1940, 0],
		0x1B08: [153, 0x198C, 0],
		0x1B10: [153, 0x1AF4, 2],
		}},
	{"fid": 161, "name": "FoxSpecial3", "w": {
		0x2C30: [0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00008002, 0x00000000,
			0x43557C6A, 0xC2C2EC08, 0x43C53E15, 0x00000000, 0x00000000, 0x00000000, 0x3727C5AC, 0x3727C5AC,
			0x3727C5AC, 0x00008002, 0x00000000, 0xC3557C6C, 0xC2C2EC08, 0x43C53E15, 0x00000000, 0x00000000,
			0x00000000, 0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x00008002, 0x00000000, 0x43557C6A, 0xC2C2EC08,
			0x43C53E15, 0x00000000, 0x00000000, 0x00000000, 0x3727C5AC, 0x3727C5AC, 0x3727C5AC, 0x00008002,
			0x00000000, 0xC3557C6C, 0xC2C2EC08, 0x43C53E15, 0x00000000, 0x00000000, 0x00000000, 0x3727C5AC,
			0x3727C5AC, 0x3727C5AC, 0x00000002, 0x00000000, 0x00000000, 0x43283C7C, 0xC3828734, 0x00000000,
			0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000,
			0x00008003, 0x00000000, 0x00000000, 0xC2271375, 0xC42E099A, 0x00000000, 0x00000000, 0x00000000,
			0x3F800000, 0x3F800000, 0x3F800000, 0x00000002, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00008003, 0x00000000,
			0x00000000, 0xC2271375, 0xC42E099A, 0x00000000, 0x00000000, 0x00000000, 0x3F800000, 0x3F800000,
			0x3F800000, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x3F800000, 0x3F800000, 0x3F800000, 0x00000012, 0x00000000, 0x00000000, 0x00000000,
			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000],
		0x2E74: [0x11C00000, 0x3F800000, 0x3F800000, 0x3F800000, 0x11C00003, 0x3F570A40, 0x3F570A40, 0x3F59999C,
			0x11C00003, 0x3F800000, 0x3F800000, 0x3F800000, 0x1C000000, 0x00000000],
		0x2EB4: [0x07C00000, 0x3F800000, 0x3F800000, 0x3F800000, 0x07C00001, 0x3FC911F1, 0x3FC911F1, 0x3FCB76B4,
			0x07C00002, 0x3F570A3D, 0x3F570A3D, 0x3F59999A, 0x07C00002, 0x3FB9999A, 0x3FB9999A, 0x3FB9999A,
			0x07C00003, 0x3F570A3D, 0x3F570A3D, 0x3F59999A, 0x07C00003, 0x3F873C60, 0x3F873C60, 0x3F873C60,
			0x0FC00000, 0xBE09E117, 0xBE1A2A2E, 0xBE0F4EC7, 0x0BC00008, 0x3F000000, 0xBC63F461, 0x3F000000,
			0xBC63F461, 0x3F000000, 0xBC63F461, 0x0BC00020, 0x3F000003, 0x3C47CE0C, 0x3F000003, 0x3C47CE0C,
			0x3F000003, 0x3C47CE0C, 0x0BC00009, 0x3F800000, 0x3CE81B4A, 0x3F800000, 0x3CE81B4A, 0x3F800000,
			0x3CEEEEEA, 0x00000000],
		}, "p": {
		0x2C60: [161, 0x2BB0, 0],
		0x2C8C: [161, 0x2BC0, 0],
		0x2CB8: [161, 0x2BD0, 0],
		0x2CE4: [161, 0x2BE0, 0],
		0x2D10: [161, 0x2BF0, 0],
		0x2D3C: [161, 0x2C00, 0],
		0x2D94: [161, 0x2C10, 0],
		0x2DEC: [161, 0x2C20, 0],
		0x2EA8: [161, 0x2E74, 1],
		}},
]
# END GENERATED FILE IMAGES
