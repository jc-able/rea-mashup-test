## 1:1 port of src/it/itground/itgbumper.c (stage bumper: Peach's Castle, Race to the Finish, Board the
## Platforms).
##
## Port notes:
##   * ITDesc -> Dictionary with the C field names; p_file/o_attributes cannot be dereferenced in the
##     port, "attributes" carries the ITAttributes they point at (Itnesspkfire / Wpmanager convention).
##   * dobj->mobj: core DObj has no MObj list. MObjs live in the DObj's "mobjs" metadata (Array, C
##     linked-list order, as Grdisplay keeps them); the bumper's palette swap (mobj->palette_id) is
##     render-only state, see _itGBumperGetMObj.
##   * u16 fields (multi, item_vars.bumper.hit_anim_length) wrap like C.
class_name Itgbumper
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## relocData offset (tools/relocFileDescriptions.us.txt [251] ITCommonData)
const llITCommonDataGBumperItemAttributes := 0xCF0

## ITAttributes at gITManagerCommonData + llITCommonDataGBumperItemAttributes (0xCF0):
## src/relocData/251_ITCommonData.c dITCommonData_GBumper_ItemAttributes (US FGM enum values).
## data -> src/relocData/86_ITCommonObject.c dITCommonObject_NBumper_Item_data_DObjDesc (@0x7648);
## p_mobjsubs -> dITCommonObject_NBumper_Item_mobjsubs_gap_0x7488 (material, render-only: not transcribed).
const dITCommonData_GBumper_ItemAttributes := {
	"data": [
		{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 1, "dl": "dITCommonObject_Gfx_0x7558", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
	],
	"p_mobjsubs": null,                 # dITCommonObject_NBumper_Item_mobjsubs_gap_0x7488 (render-only)
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 0,
	"is_item_dobjs": 1,
	"is_display_colanim": 0,
	"is_give_hitlag": 1,
	"weight": 1,                        # Heavy = 0, Light = 1
	"attack_offset0_x": 0,
	"attack_offset0_y": 0,
	"attack_offset0_z": 0,
	"attack_offset1_x": 0,
	"attack_offset1_y": 0,
	"attack_offset1_z": 0,
	"damage_coll_offset": Vector3(0, 0, 0),
	"damage_coll_size": Vector3(150, 150, 150),
	"map_coll_top": 180,
	"map_coll_center": 0,
	"map_coll_bottom": -180,
	"map_coll_width": 180,
	"size": 250,
	"angle": 362,
	"knockback_scale": 50,
	"damage": 1,
	"element": 0,
	"knockback_weight": 200,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 0,
	"hit_sfx": nSYAudioFGMBumperHit,
	"priority": 1,
	"can_rehit_item": 0,
	"can_rehit_fighter": 1,
	"can_hop": 0,
	"can_reflect": 0,
	"can_shield": 1,
	"knockback_base": 0,
	"type": 3,
	"hitstatus": 0,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

static var dITGBumperItemDesc := {
	"kind": nITKindGBumper,                                     # Item Kind
	"p_file": null,                                             # &gITManagerCommonData
	"o_attributes": llITCommonDataGBumperItemAttributes,        # Offset of item attributes in file
	"attributes": dITCommonData_GBumper_ItemAttributes,
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateNew,                          # Hitbox Update State
	"proc_update": Callable(Itgbumper, &"itGBumperCommonProcUpdate"),
	"proc_map": Callable(),
	"proc_hit": Callable(Itgbumper, &"itGBumperCommonProcHit"),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(),
	"visual_kind": "ground_bumper",                             # port-only (placeholder visual id)
}

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8017D590
static func itGBumperCommonProcUpdate(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)
	var mobj = _itGBumperGetMObj(dobj)

	if (ip.item_vars.bumper.hit_anim_length == 0) and (mobj.palette_id == 1.0):
		mobj.palette_id = 0.0
	else:
		ip.item_vars.bumper.hit_anim_length = (ip.item_vars.bumper.hit_anim_length - 1) & 0xFFFF # u16

	if ip.multi != 0:
		# 2.0F - ((10 - multi) * 0.1F), in single precision
		dobj.scale.y = f32(2.0 - f32((10 - ip.multi) * f32(0.1)))
		dobj.scale.x = dobj.scale.y

		ip.multi = (ip.multi - 1) & 0xFFFF # u16
	else:
		dobj.scale.y = 1
		dobj.scale.x = dobj.scale.y

	return FALSE

## 0x8017D63C
static func itGBumperCommonProcHit(item_gobj) -> int:
	var ip := itGetStruct(item_gobj)
	var dobj := DObjGetStruct(item_gobj)

	dobj.scale.x = 2.0
	dobj.scale.y = 2.0

	ip.item_vars.bumper.hit_anim_length = ITBUMPER_HIT_ANIM_LENGTH

	_itGBumperGetMObj(dobj).palette_id = 1.0

	ip.multi = ITBUMPER_HIT_SCALE

	return FALSE

## 0x8017D67C
static func itGBumperMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITGBumperItemDesc, pos, vel, flags)

	if item_gobj != null:
		var ip: Item
		var dobj: DObj

		Itmain.itMainClearOwnerStats(item_gobj)

		ip = itGetStruct(item_gobj)
		dobj = DObjGetStruct(item_gobj)

		ip.multi = 0

		ip.attack_coll.interact_mask = GMHITCOLLISION_FLAG_FIGHTER
		ip.attack_coll.can_rehit_shield = TRUE

		ip.physics.vel_air.x = 0.0
		ip.physics.vel_air.y = 0.0
		ip.physics.vel_air.z = 0.0

		_itGBumperGetMObj(dobj).palette_id = 0.0

		if G.gSCManagerBattleState.gkind == nGRKindCastle:
			ip.attack_coll.knockback_weight = ITBUMPER_CASTLE_KNOCKBACK
			ip.attack_coll.angle = ITBUMPER_CASTLE_ANGLE

	return item_gobj

# ---------------------------------------------------------------------------------------
# Port helpers
# ---------------------------------------------------------------------------------------

## dobj->mobj (first MObj of the joint). Core DObj has no mobj field: MObjs are kept in the DObj's
## "mobjs" metadata (as Grdisplay does). The bumper model's MObjSub (palette swap) is render-only and
## not transcribed, so when the item setup attached no MObj a stand-in with the MObj fields this code
## uses is attached on first access (gcAddMObjForDObj initial values: palette_id 0, texture ids 0,
## no material animation).
static func _itGBumperGetMObj(dobj: DObj):
	var mobjs: Array = dobj.get_meta(&"mobjs", [])

	if mobjs.is_empty():
		mobjs.append({"texture_id_curr": 0, "texture_id_next": 0, "palette_id": 0.0, "anim_wait": AOBJ_ANIM_NULL})
		dobj.set_meta(&"mobjs", mobjs)

	return mobjs[0]
