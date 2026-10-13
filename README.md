# REA Mashup Test

**An educational AI-assisted reverse-engineering experiment with two editable Godot game projects.**

[Watch the YouTube video: CRAZY! REA + GODOT MCP - Claude Opus 5.5 builds Super Smash Bros and WWE Game Mod in Godot](https://www.youtube.com/watch?v=TNGPn2vF3dg)

Created for **educational purposes only**. This is an unofficial research and fan-development experiment, not an endorsed product. Third-party game content and trademarks remain the property of their respective rights holders. The educational notice does not grant rights to that material. Read [EDUCATIONAL_NOTICE.md](EDUCATIONAL_NOTICE.md) and [SOURCE_NOTES.md](SOURCE_NOTES.md).

## The two games

| Project | Experiment | Open in Godot |
|---|---|---|
| **Wrestling Smash** | Twelve WWE SmackDown vs. Raw 2011 wrestlers in a Smash 64-style platform fighter. F4 switches between Smash-style and SvR wrestler animation presentation. | [wrestling-smash/project.godot](wrestling-smash/project.godot) |
| **Smash Wrestling** | Twelve original Smash 64 fighters in a custom wrestling game, with mapped entrances and SmackDown, Raw and WrestleMania XXVI arenas. | [smash-wrestling/project.godot](smash-wrestling/project.godot) |

Both project folders include their scripts, scenes, gameplay data, models, textures and animation resources. The original game-development work was produced with Claude Opus 5.5 at Max reasoning; this repository presents the resulting research snapshots with publication documentation and portable export settings.

## Download and run

1. Download this repository using **Code → Download ZIP**, then extract the entire ZIP; or clone it:

   ```bash
   git clone https://github.com/jc-able/rea-mashup-test.git
   ```

2. Open **Godot 4.6.3** and choose **Import**.
3. Select `wrestling-smash/project.godot` or `smash-wrestling/project.godot`.
4. Let Godot finish importing assets, then press **F5** to run the selected project.

Keep each project folder intact. Generated `.godot` import caches are intentionally omitted and will rebuild locally. These are two separate projects, so import each one separately. See [CONTROLS.md](CONTROLS.md) for keyboard controls and the animation toggle.

To export a standalone app, install matching Godot export templates and choose an output path on your own computer. The older project's machine-specific custom template override was cleared in this public copy. No prebuilt app, raw ROM/ISO, original executable or credential file is included here.

## What this experiment demonstrates

The process combines recovered game data, custom parsers and converters, selected REA binary-analysis checks, animation retargeting and Godot implementation. REA did not automatically convert either entire original game into Godot. The wrestling rules and AI include custom implementation, and both games contain adaptation and presentation choices.

These projects are **not verified exact clones**. Bounded structural checks, selected simulation comparisons and gameplay observations are useful evidence, but do not prove original-engine parity or every human control. [Source notes](SOURCE_NOTES.md) describe the distinction and the known limits.

## Known limitations

- Some wrestler states use fallback animations; complete animation and hitbox parity is unverified.
- Wrestling contact, camera/rope occlusion and UI issues remain in the research snapshot.
- Wrestling Q / RB position change is mapped but unimplemented.
- The platform fighter has countdown intros; the wrestling game has ring entrances.
- Sound effects are custom synthesized audio; original licensed entrance themes and commentary are not provided.
- Human controls and physical gamepad behavior were not comprehensively verified on every platform. Publishing this repository does not constitute a new destination-device playtest.

## Credits and scope

Research inputs include [ssb-decomp-re](https://github.com/VetriTheRetri/ssb-decomp-re), [BattleShip](https://github.com/JRickey/BattleShip), and [SVR2011-Recomp](https://github.com/shaneomac1337/SVR2011-Recomp), plus the referenced original games. Existing upstream notices are retained under [THIRD_PARTY_LICENSES](THIRD_PARTY_LICENSES); their scope does not extend automatically to third-party game assets.

No blanket open-source license is asserted over this mixed research snapshot. Please preserve provenance and existing notices. For the build story and gameplay results, [watch the accompanying video on The AI Vice](https://www.youtube.com/watch?v=TNGPn2vF3dg).
