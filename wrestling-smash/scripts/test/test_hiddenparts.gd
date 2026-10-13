## Check hidden-part joints (e.g. the heavy-item hand joint) are created/ejected per motion.
extends SceneTree

func _initialize() -> void:
	var cfg := BattleRunner.default_config()
	cfg.items_on = false
	var runner := BattleRunner.new()
	runner.start(cfg)
	for i in 400:
		runner.step()
	var fp: Fighter = Sim.get_link(SSBDefs.nGCCommonLinkIDFighter)[0]
	var hid: int = fp.attr.joint_itemheavy_id
	print("fighter ", fp.name_key, " status ", fp.status_id, " joint_itemheavy_id ", hid, " exists=", fp.joints[hid] != null)
	Ftmain.ftMainSetStatus(fp, SSBDefs.nFTCommonStatusHeavyGet, 0.0, 1.0, SSBDefs.FTSTATUS_PRESERVE_NONE)
	print("after HeavyGet: anim_desc=0x%x exists=%s parent=%s" % [fp.anim_desc, str(fp.joints[hid] != null), str(fp.joints[hid].parent.debug_name if fp.joints[hid] != null and fp.joints[hid].parent != null else "-")])
	if fp.joints[hid] != null:
		print("  world pos of heavy joint: ", Gmcollision.gmCollisionGetFighterPartsWorldPosition(fp.joints[hid], Vector3.ZERO), " fighter at ", fp.dobj.translate)
	Ftmain.ftMainSetStatus(fp, SSBDefs.nFTCommonStatusLiftWait, 0.0, 1.0, SSBDefs.FTSTATUS_PRESERVE_NONE)
	print("after LiftWait: anim_desc=0x%x exists=%s" % [fp.anim_desc, str(fp.joints[hid] != null)])
	Ftmain.ftMainSetStatus(fp, SSBDefs.nFTCommonStatusWait, 0.0, 1.0, SSBDefs.FTSTATUS_PRESERVE_NONE)
	print("after Wait: exists=%s" % str(fp.joints[hid] != null))
	quit(0)
