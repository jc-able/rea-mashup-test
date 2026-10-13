SvR 2011 motion clips used by the game (.svrm, SVRM v1 format: see W/evidence/svr_motion_format.md).

This folder is populated by W/tools/svr_anim/build_anim_map.py (the game's animation-map builder).
It copies only the clips the animation map uses, plus a subset index.json, from the bulk export in
W/extracted/svr2011_motion/svrm/ (written by W/tools/svr_anim/export_batch.py and annotated by
W/tools/svr_anim/index_annotate.py).

Every clip is ORIGINAL SmackDown vs. Raw 2011 motion data decoded from gamedata/pac/m.pac (YMKs keyframe
streams). Nothing here is synthesized; motions the game cannot find here fall back to the SSB64 motion and
are labelled as fallback by the game.
