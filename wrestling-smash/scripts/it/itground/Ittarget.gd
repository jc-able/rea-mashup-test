## 1:1 port of src/it/itground/ittarget.c (Break the Targets target).
##
## Port notes:
##   * ITDesc -> Dictionary with the C field names; p_file/o_attributes cannot be dereferenced in the
##     port, "attributes" carries the ITAttributes they point at (Itnesspkfire / Wpmanager convention).
##   * sc1PBonusStageUpdateTargetCount (src/sc/sc1pmode/sc1pbonusstage.c) has no port class
##     (the 1P bonus stage scene is not in tools/port/funcmap.tsv): it is called through
##     _sc1PBonusStageUpdateTargetCount, which forwards to a Sc1pbonusstage class when one exists.
class_name Ittarget
extends Port

# // // // // // // // // // // // //
# //       INITIALIZED DATA        //
# // // // // // // // // // // // //

## ITAttributes at offset 0 of gSC1PBonusStageItemFile (relocData file 253 ITBonus1ObjectHeader):
## src/relocData/253_ITBonus1ObjectHeader.c dITBonus1ObjectHeader (US FGM enum values).
## data -> src/relocData/150_ITBonus1Object.c dITBonus1Object_DObjDesc (joint 1 draws the
## dITBonus1Object_dobj DObjDLLink; models are render-only, "dl" only names the C symbol).
const dITBonus1ObjectHeader := {
	"data": [
		{"id": 0, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 1, "dl": "dITBonus1Object_dobj", "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(1.0, 1.0, 1.0)},
		{"id": 18, "dl": null, "translate": Vector3(0.0, 0.0, 0.0), "rotate": Vector3(0.0, 0.0, 0.0), "scale": Vector3(0.0, 0.0, 0.0)},
	],
	"p_mobjsubs": null,
	"anim_joints": null,
	"p_matanim_joints": null,
	"is_display_xlu": 1,
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
	"damage_coll_size": Vector3(300, 300, 300),
	"map_coll_top": 180,
	"map_coll_center": 0,
	"map_coll_bottom": -180,
	"map_coll_width": 180,
	"size": 200,
	"angle": 361,
	"knockback_scale": 100,
	"damage": 1,
	"element": 0,
	"knockback_weight": 400,
	"shield_damage": 0,
	"attack_count": 1,
	"can_setoff": 1,
	"hit_sfx": nSYAudioFGMBumperHit,
	"priority": 1,
	"can_rehit_item": 1,
	"can_rehit_fighter": 1,
	"can_hop": 1,
	"can_reflect": 1,
	"can_shield": 1,
	"knockback_base": 10,
	"type": 6,
	"hitstatus": 1,
	"unk_atca_0x3C_b6": 0,
	"unk_atca_0x3C_b7": 0,
	"drop_sfx": nSYAudioFGMItemThrow,
	"throw_sfx": nSYAudioFGMItemThrow,
	"smash_sfx": nSYAudioFGMItemThrow,
	"vel_scale": 100,
	"spin_speed": 0,
}

## 0x8018F130
static var dITTargetItemDesc := {
	"kind": nITKindTarget,                                      # Item Kind
	"p_file": null,                                             # &gSC1PBonusStageItemFile
	"o_attributes": 0,                                          # Offset of item attributes in file
	"attributes": dITBonus1ObjectHeader,
	"transform_types": {"tk1": nGCMatrixKindTraRotRpyRSca, "tk2": nGCMatrixKindNull, "tk3": 0},
	"attack_state": nGMAttackStateOff,                          # Hitbox Update State
	"proc_update": Callable(),
	"proc_map": Callable(),
	"proc_hit": Callable(),
	"proc_shield": Callable(),
	"proc_hop": Callable(),
	"proc_setoff": Callable(),
	"proc_reflector": Callable(),
	"proc_damage": Callable(Ittarget, &"itTargetCommonProcDamage"),
	"visual_kind": "ground_target",                             # port-only (placeholder visual id)
}

# // // // // // // // // // // // //
# //           FUNCTIONS           //
# // // // // // // // // // // // //

## 0x8018EE10
static func itTargetCommonProcDamage(item_gobj) -> int:
	Efmanager.efManagerShieldBreakMakeEffect(DObjGetStruct(item_gobj).translate)
	Efmanager.efManagerFireGrindMakeEffect(DObjGetStruct(item_gobj).translate)

	Snd.func_800269C0_275C0(nSYAudioFGMBonus1TargetBreak)

	_sc1PBonusStageUpdateTargetCount()

	return TRUE

## 0x8018EE5C
static func itTargetMakeItem(parent_gobj, pos: Vector3, vel: Vector3, flags: int):
	var item_gobj = Itmanager.itManagerMakeItem(parent_gobj, dITTargetItemDesc, pos, vel, flags)

	if item_gobj != null:
		var ip := itGetStruct(item_gobj)

		ip.ga = nMPKineticsGround
		ip.coll_data.floor_line_id = -1

	return item_gobj

# ---------------------------------------------------------------------------------------
# Port helpers
# ---------------------------------------------------------------------------------------

## sc1PBonusStageUpdateTargetCount() (src/sc/sc1pmode/sc1pbonusstage.c 0x8018D510): decrements
## gGRCommonStruct.bonus1.target_count and ends the Break the Targets game. The 1P bonus stage scene
## has no port class yet; forward to it once a global class Sc1pbonusstage exists.
static func _sc1PBonusStageUpdateTargetCount() -> void:
	for c in ProjectSettings.get_global_class_list():
		if c["class"] == &"Sc1pbonusstage":
			var sc = load(c["path"])
			if sc != null:
				sc.call(&"sc1PBonusStageUpdateTargetCount")
				return
	StubLog.hit("Sc1pbonusstage.sc1PBonusStageUpdateTargetCount")
