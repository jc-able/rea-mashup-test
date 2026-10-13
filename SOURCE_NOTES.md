# Sources and adaptation notes

These two Godot 4.6.3 projects document an educational AI reverse-engineering and
game-adaptation experiment. They are runnable Godot adaptations, not demonstrations
of exact original-game equivalence. The README links the accompanying video.

## What is in each project

**`wrestling-smash/` — Wrestling Smash.** Twelve wrestler models recovered from
SmackDown vs. Raw 2011 packages appear in a Smash 64-style platform fighter.
Custom unpackers and converters made the models usable in Godot. The game code
draws substantially on the Smash decompilation, with Godot adaptations, menus and
blockout stages. A presentation toggle selects Smash-style animation or adapted
SvR motion. The project contains 268 physical `.svrm` files; the preserved audit
identified 266 clips referenced by its motion map. Unsupported actions can fall
back to other animation. Those counts do not establish full source-game coverage.

**`smash-wrestling/` — Smash Wrestling 64.** The twelve original Smash 64 fighters
use recovered models and source animations alongside retargeted SvR wrestling
motion and mapped entrances. The arenas use recovered SmackDown, Raw and
WrestleMania XXVI data, with inferred placement, camera fitting and custom runtime
work. Grapple, pin, submission, momentum, AI and match systems are new Godot code;
their values are not established as an exact SvR ruleset. This follow-on reused
earlier conversion tools and assets. Its game audio is custom synthesized effects,
not original entrance themes or commentary.

REA/Ghidra provided selected compiled-routine crosschecks. Custom parsers and
converters performed asset recovery. Some successful SvR analyses used small
translated host executables containing selected source routines; this was not a
successful automatic decompilation or conversion of an entire original game.
The games run in Godot. They were not injected back into the original engines.

## Public references and recorded source revisions

These are the historical inputs recorded by the project audits, not a claim that
the upstream projects endorse these adaptations or that their latest revisions
have been retested here.

- [Smash 64 decompilation — VetriTheRetri/ssb-decomp-re](https://github.com/VetriTheRetri/ssb-decomp-re),
  recorded commit [`7a85d55c7d5bfb17b48447de948dc7406f7eedb9`](https://github.com/VetriTheRetri/ssb-decomp-re/commit/7a85d55c7d5bfb17b48447de948dc7406f7eedb9).
- [BattleShip port — JRickey/BattleShip](https://github.com/JRickey/BattleShip),
  recorded commit [`4e9bac5c83b4f1a16aae1e65acd47ab28242e10e`](https://github.com/JRickey/BattleShip/commit/4e9bac5c83b4f1a16aae1e65acd47ab28242e10e).
- [SVR2011-Recomp — shaneomac1337/SVR2011-Recomp](https://github.com/shaneomac1337/SVR2011-Recomp),
  recorded commit [`6a12d52d0e32adfca092b6474d584b97d459b148`](https://github.com/shaneomac1337/SVR2011-Recomp/commit/6a12d52d0e32adfca092b6474d584b97d459b148).
- [REA](https://github.com/morluto/rea): the original work used REA 6.0.0 with
  Ghidra 12.1.4.
- [Original user-supplied Archive.org collection](https://archive.org/details/@chun_s_ready-to-go_recomp_games),
  including the historical [Smash package](https://archive.org/details/smash-n64-pc)
  and [SvR 2011 package](https://archive.org/details/svr-2011-pc-port).

Archive/file correspondence does not establish publisher authenticity. Original
source/provenance comments and asset metadata are retained in these projects.

## Limits of the available evidence

- Selected tests and CPU matches passed in the original work. Those checks do
  not prove complete-state parity, every move, every human control, or physical
  gamepad behavior. No new runtime test was performed for this public copy.
- Wrestling Smash retains fallback motion, a reachable Link-bomb stub, portrait
  and label defects, and incomplete verification of held human movement and
  attacks. Two matching recorded traces did not establish universal parity;
  some separately captured roster samples differed in state or frame.
- Smash Wrestling retains imperfect contact, camera and rope occlusion, occasional
  entrance cropping or mesh separation, and a clipped controls overlay. Q/RB
  position-change is mapped but unimplemented. Original native checks verified
  some keyboard actions, not every strike, reversal or sustained movement case.
- Retargeting, action mapping, timing, presentation and CPU tuning contain custom
  choices. Recovered animation does not mean every original action plays with its
  original contacts, timing or camera.

## Publication-copy changes

Only the game folders are included; generated `.godot` caches and `.DS_Store`
files are omitted. Asset files, `.uid` files, `.import` metadata and export presets
are retained. Incidental personal filesystem prefixes were removed from twelve
wrestler `source_package` fields and one explanatory source-index note. The
package/version/internal paths and provenance meaning remain.

The older project's two absolute custom macOS template settings were cleared so
Godot can use installed default templates. Install matching export templates if
you want to make a new app. The older project's display description was also clarified to avoid an unsupported
whole-game parity claim. No gameplay code or binary asset was changed for this
publication copy. Open either folder's `project.godot`, allow imports to finish,
and press F5; a prebuilt macOS application is not bundled here.

## License notices

[SVR2011-Recomp's BSD 3-Clause license](THIRD_PARTY_LICENSES/SVR2011-Recomp-LICENSE.txt)
and [BattleShip's complete license and scope notes](THIRD_PARTY_LICENSES/BattleShip-LICENSE.txt)
are preserved verbatim from the recorded source checkouts. BattleShip's MIT grant
is scoped to its port-specific material and explicitly excludes Nintendo/HAL
material and decomp-derived content. It also records separate upstream notices.

These license copies do not relicense this entire repository, the decompiled
original game content, or third-party models, textures, animation, names and
trademarks. No blanket new license or fair-use determination is asserted here.
Original rights and applicable source terms remain with their respective owners.
