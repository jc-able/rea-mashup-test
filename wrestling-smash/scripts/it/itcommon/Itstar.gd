## 1:1 port of src/it/itcommon/itstar.c (ssb-decomp-re): Star Man (bounces across the stage; touching it is
## handled by the fighter-side code through proc_hit / the item's fighter-only hitbox).
##
## Data conventions: see Itbox (ITDesc Dictionary with the C field names; the ITAttributes and DObjDesc tree
## come from the ITCommonData tables in Itmanager.gd).
class_name Itstar
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

static var dITStarItemDesc := {
	"kind": nITKindStar,                                      # Item Kind
	"p_file": "gITManagerCommonData",                         # Pointer to item file data?
	"o_attributes": "llITCommonDataStarItemAttributes",       # Offset of item attributes in file? (resolved by Itmanager)
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyR, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                        # Hitbox Update State
	"proc_update": Callable(Itstar, &"itStarCommonProcUpdate"),
	"proc_map": Callable(Itstar, &"itStarCommonProcMap"),
	"proc_hit": Callable(Itstar, &"itStarCommonProcHit"),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
}

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x80174930
static func itStarCommonProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)

	Itmain.itMainApplyGravityClampTVel(ip, ITSTAR_GRAVITY, ITSTAR_TVEL)

	ip.multi = (ip.multi - 1) & 0xFFFF # u16

	if ip.multi == 0:
		Itmain.itMainRefreshAttackColl(item_gobj)

	Itvisuals.itVisualsUpdateSpin(item_gobj)

	return FALSE

## 0x80174990
static func itStarCommonProcMap(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var is_collide_floor: int = Itmap.itMapTestAllCollisionFlag(item_gobj, MAP_FLAG_FLOOR)

	# C passes NULL for the pos output.
	if B(Itmap.itMapCheckCollideAllRebound(item_gobj, (MAP_FLAG_CEIL | MAP_FLAG_RWALL | MAP_FLAG_LWALL), ITSTAR_MAP_REBOUND_COMMON).ret):
		Itmain.itMainSetSpinVelLR(item_gobj)

	if is_collide_floor != FALSE:
		ip.physics.vel_air.y = ITSTAR_BOUNCE_Y

		Snd.func_800269C0_275C0(nSYAudioFGMStarMapCollide)

	return FALSE

## 0x80174A0C
static func itStarCommonProcHit(item_gobj) -> int:
	return TRUE

## 0x80174A18
static func itStarMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var cobj = Gmcamera.CObjGetStruct(Gmcamera.gGMCameraGObj)
	var item_gobj
	var dobj: DObj
	var ip: Item
	var vel_real: Vector3
	var translate: Vector3 # REGION_US

	vel_real.x = ITSTAR_VEL_X if (pos.x < cobj.vec.at.x) else -ITSTAR_VEL_X
	vel_real.y = ITSTAR_BOUNCE_Y
	vel_real.z = 0.0

	item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITStarItemDesc, pos, vel_real, flags)

	if item_gobj != null:
		dobj = DObjGetStruct(item_gobj)

		translate = dobj.translate # REGION_US

		ip = itGetStruct(item_gobj)

		ip.attack_coll.interact_mask = GMHITCOLLISION_FLAG_FIGHTER # Star Man can only interact with fighters

		ip.multi = ITSTAR_INTERACT_DELAY

		ip.is_unused_item_bool = TRUE

		Objman.gcAddXObjForDObjFixed(dobj, 0x2E, 0)

		dobj.rotate.z = 0.0

		dobj.translate = translate # REGION_US

	return item_gobj
