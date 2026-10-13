## 1:1 port of src/it/itmonster/itkabigon.c (ssb-decomp-re): Poké Ball Snorlax (also used by
## Clefairy's Metronome, which falls at ITKABIGON_DROP_SIZE_OTHER).
##
## Make function (dITManagerProcMakeList entry, called through itManagerMakeItemKind):
##   Itkabigon.itKabigonMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int) -> item_gobj or null
## Shared conventions of the itmonster ports (descs, DObjDesc data, AnimJoints, u16 wrap): see Itpippi.gd.
## ITAttributes: llITCommonDataKabigonItemAttributes (251_ITCommonData.c @ 0x07A8), resolved by the
## item core from its ROM-verified ITCommonData table (Itmanager.itManagerGetCommonData).
class_name Itkabigon
extends Port

# // // // // // // // // // // // //
# //          ENUMERATORS          //
# // // // // // // // // // // // //

# enum itKabigonStatus
const nITKabigonStatusJump = 0
const nITKabigonStatusFall = 1
const nITKabigonStatusEnumCount = 2

# llITCommonData* linker offsets used by this file (tools/relocFileDescriptions.us.txt)
const llITCommonDataKabigonAnimJoint = 0xB158   # == offset of Snorlax's DObjDesc (its attr->data)

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## 0x8018AB40
static var dITKabigonItemDesc := {
	"kind": nITKindKabigon,                                     # Item Kind
	"o_attributes": "llITCommonDataKabigonItemAttributes",      # &gITManagerCommonData, &llITCommonDataKabigonItemAttributes

	# DObj transformation struct
	"transform_types": {
		"tk1": nGCMatrixKindTraRotRpyRSca,                      # Main matrix transformations
		"tk2": nGCMatrixKindNull,                               # Secondary matrix transformations?
		"tk3": 0,                                               # ???
	},

	"attack_state": nGMAttackStateNew,                          # Hitbox Update State
	"proc_update": Callable(Itkabigon, &"itKabigonCommonProcUpdate"),   # Proc Update
	"proc_map": Callable(),                                     # Proc Map
	"proc_hit": Callable(),                                     # Proc Hit
	"proc_shield": Callable(),                                  # Proc Shield
	"proc_hop": Callable(),                                     # Proc Hop
	"proc_setoff": Callable(),                                  # Proc Set-Off
	"proc_reflector": Callable(),                               # Proc Reflector
	"proc_damage": Callable(),                                  # Proc Damage
}

## 0x8018AB74
static var dITKabigonStatusDescs: Array = [
	# Status 0 (Neutral Jump)
	{
		"proc_update": Callable(Itkabigon, &"itKabigonJumpProcUpdate"),
		"proc_map": Callable(), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},

	# Status 1 (Neutral Fall)
	{
		"proc_update": Callable(Itkabigon, &"itKabigonFallProcUpdate"),
		"proc_map": Callable(), "proc_hit": Callable(), "proc_shield": Callable(), "proc_hop": Callable(),
		"proc_setoff": Callable(), "proc_reflector": Callable(), "proc_damage": Callable(),
	},
]

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8017E070
static func itKabigonFallProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	if ip.item_vars.kabigon.rumble_wait == 0:
		Efmanager.efManagerQuakeMakeEffect(0)

		ip.item_vars.kabigon.rumble_wait = ITKABIGON_RUMBLE_WAIT

	ip.item_vars.kabigon.rumble_wait -= 1

	if dobj.translate.y < (Mpcollision.gMPCollisionGroundData.map_bound_bottom + ITKABIGON_MAP_OFF_Y):
		return TRUE

	else:
		return FALSE

## 0x8017E100
static func itKabigonFallProcDisplay(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	# gDPPipeSync(gSYTaskmanDLHeads[0]++);

	if B(Itdisplay.itDisplayCheckItemVisible(ip)):
		if (ip.display_mode == nDBDisplayModeMaster) or B(ip.is_hold):
			# gDPSetRenderMode(gSYTaskmanDLHeads[0]++, G_RM_AA_XLU_SURF, G_RM_AA_XLU_SURF2);

			Objdisplay.gcDrawDObjTreeForGObj(item_gobj)

		elif ip.display_mode == nDBDisplayModeMapCollision:
			# gDPSetRenderMode(gSYTaskmanDLHeads[0]++, G_RM_AA_XLU_SURF, G_RM_AA_XLU_SURF2);

			Objdisplay.gcDrawDObjTreeForGObj(item_gobj)
			Itdisplay.itDisplayMapCollisions(item_gobj)

		elif (ip.damage_coll.hitstatus == nGMHitStatusNone) and (ip.attack_coll.attack_state == nGMAttackStateOff):
			# gDPSetRenderMode(gSYTaskmanDLHeads[0]++, G_RM_AA_XLU_SURF, G_RM_AA_XLU_SURF2);

			Objdisplay.gcDrawDObjTreeForGObj(item_gobj)

		else:
			Itdisplay.itDisplayHitCollisions(item_gobj)

	# gDPPipeSync(gSYTaskmanDLHeads[0]++);

## 0x8017E25C
static func itKabigonFallInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	ip.physics.vel_air.y = ITKABIGON_DROP_VEL_Y

	dobj.translate.x += ((ITKABIGON_DROP_OFF_X_MUL * syUtilsRandFloat()) + ITKABIGON_DROP_OFF_X_ADD)

	Itmain.itMainRefreshAttackColl(item_gobj)

	ip.item_vars.kabigon.rumble_wait = 0

	Snd.func_800269C0_275C0(nSYAudioFGMKabigonFall)

	if ip.kind == nITKindKabigon:
		Snd.func_800269C0_275C0(nSYAudioVoiceMBallKabigonFall)

		dobj.scale.y = ITKABIGON_DROP_SIZE_KABIGON
		dobj.scale.x = dobj.scale.y

		ip.attack_coll.size *= ITKABIGON_DROP_SIZE_KABIGON

	else:
		dobj.scale.y = ITKABIGON_DROP_SIZE_OTHER
		dobj.scale.x = dobj.scale.y

		ip.attack_coll.size *= ITKABIGON_DROP_SIZE_OTHER

	item_gobj.display_proc = Callable(Itkabigon, &"itKabigonFallProcDisplay") # item_gobj->proc_display

	# item_gobj->dl_link_priority: itManagerMakeItem registers every item display with GOBJ_PRIORITY_DEFAULT
	Objman.gcMoveGObjDLHead(item_gobj, 18, GOBJ_PRIORITY_DEFAULT)

## 0x8017E350
static func itKabigonFallSetStatus(item_gobj) -> void:
	itKabigonFallInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITKabigonStatusDescs, nITKabigonStatusFall)

## 0x8017E384
static func itKabigonJumpProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	if dobj.translate.y >= (Mpcollision.gMPCollisionGroundData.map_bound_top - ITKABIGON_MAP_OFF_Y):
		ip.multi = (ip.multi - 1) & 0xFFFF # u16

		ip.physics.vel_air.y = 0.0

		if ip.multi == 0:
			itKabigonFallSetStatus(item_gobj)

	if ip.item_vars.kabigon.dust_effect_int == 0:
		var pos: Vector3 = dobj.translate

		pos.x += (syUtilsRandFloat() * ITKABIGON_JUMP_GFX_MUL_OFF) - ITKABIGON_JUMP_GFX_SUB_OFF
		pos.y += (syUtilsRandFloat() * ITKABIGON_JUMP_GFX_MUL_OFF) - ITKABIGON_JUMP_GFX_SUB_OFF

		Efmanager.efManagerDustExpandLargeMakeEffect(pos)

		ip.item_vars.kabigon.dust_effect_int = ITKABIGON_EFFECT_SPAWN_INT

	ip.item_vars.kabigon.dust_effect_int -= 1

	return FALSE

## 0x8017E4A4
static func itKabigonCommonProcDisplay(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	# gDPPipeSync(gSYTaskmanDLHeads[0]++);

	if B(Itdisplay.itDisplayCheckItemVisible(ip)):
		if (ip.display_mode == nDBDisplayModeMaster) or B(ip.is_hold):
			# gDPSetRenderMode(gSYTaskmanDLHeads[0]++, G_RM_AA_ZB_TEX_EDGE, G_RM_AA_ZB_TEX_EDGE2);

			Objdisplay.gcDrawDObjTreeForGObj(item_gobj)

		elif ip.display_mode == nDBDisplayModeMapCollision:
			# gDPSetRenderMode(gSYTaskmanDLHeads[0]++, G_RM_AA_ZB_TEX_EDGE, G_RM_AA_ZB_TEX_EDGE2);

			Objdisplay.gcDrawDObjTreeForGObj(item_gobj)
			Itdisplay.itDisplayMapCollisions(item_gobj)

		elif (ip.damage_coll.hitstatus == nGMHitStatusNone) and (ip.attack_coll.attack_state == nGMAttackStateOff):
			# gDPSetRenderMode(gSYTaskmanDLHeads[0]++, G_RM_AA_ZB_TEX_EDGE, G_RM_AA_ZB_TEX_EDGE2);

			Objdisplay.gcDrawDObjTreeForGObj(item_gobj)

		else:
			Itdisplay.itDisplayHitCollisions(item_gobj)

	# gDPPipeSync(gSYTaskmanDLHeads[0]++);

## 0x8017E600
static func itKabigonJumpInitVars(item_gobj) -> void:
	var ip := itGetStruct(item_gobj)

	Snd.func_800269C0_275C0(nSYAudioFGMKabigonJump)

	ip.multi = ITKABIGON_DROP_WAIT

	ip.item_vars.kabigon.dust_effect_int = ITKABIGON_EFFECT_SPAWN_INT

	ip.physics.vel_air.y = ITKABIGON_JUMP_VEL_Y

## 0x8017E648
static func itKabigonJumpSetStatus(item_gobj) -> void:
	itKabigonJumpInitVars(item_gobj)
	Itmain.itMainSetStatus(item_gobj, dITKabigonStatusDescs, nITKabigonStatusJump)

## 0x8017E67C
static func itKabigonCommonProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	if ip.multi == 0:
		itKabigonJumpSetStatus(item_gobj)

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	return FALSE

## 0x8017E6C0
static func itKabigonMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITKabigonItemDesc, pos, vel, flags)

	if item_gobj != null:
		var dobj := DObjGetStruct(item_gobj)
		var ip := itGetStruct(item_gobj)

		ip.multi = ITMONSTER_RISE_STOP_WAIT

		ip.attack_coll.interact_mask = GMHITCOLLISION_FLAG_FIGHTER

		ip.physics.vel_air.z = 0.0
		ip.physics.vel_air.x = ip.physics.vel_air.z
		ip.physics.vel_air.y = ITMONSTER_RISE_VEL_Y

		# itGetMonsterAnimNode(ip, &llITCommonDataKabigonAnimJoint) == ITCommonObject + 0x13624
		ObjAnim.gcAddDObjAnimJoint(dobj, Itpippi.dITCommonObjectMonsterAnimBank, 0.0)

		if ip.kind == nITKindKabigon:
			Snd.func_800269C0_275C0(nSYAudioVoiceMBallKabigonAppear)

		item_gobj.display_proc = Callable(Itkabigon, &"itKabigonCommonProcDisplay") # item_gobj->proc_display

	return item_gobj
