## 1:1 port of src/ft/ftcommondata.c (ssb-decomp-re): common fighter data tables.
## (dGMColScriptsDescs is only declared in ftcommondata.h; it is defined in another file.)
class_name Ftcommondata
extends Port

## 0x8012C830 - f32 [attack, defend] knockback multipliers indexed by (handicap - 1).
## The values are the exact single-precision constants stored in the US ROM (verified against
## baserom.us.z64 @ 0xA8030); the C initializer expression is given in each comment.
static var dFTCommonDataHandicapTable: Array = [
	[0.550000011920929, 1.8181817531585693],       # { 0.55F,  1.8181818F }
	[0.6000000238418579, 1.6666666269302368],      # {  0.6F,  15.0F / 9.0F }
	[0.699999988079071, 1.4285714626312256],       # {  0.7F,  10.0F / 7.0F }
	[0.75, 1.3333333730697632],                    # { 0.75F,  12.0F / 9.0F }
	[0.800000011920929, 1.25],                     # {  0.8F,  11.25F / 9.0F }
	[0.8999999761581421, 1.1111111640930176],      # {  0.9F,  10.0F / 9.0F }
	[0.949999988079071, 1.0526316165924072],       # { 0.95F,  10.0F / 9.5F }
	[1.0, 1.0],                                    # {  1.0F,  9.0F / 9.0F }
	# REGION_US
	[1.090000033378601, 0.9174311757087708],       # { 1.09F,  0.9174312F }
	[0.5, 5.0],                                    # {  0.5F,  45.0F / 9.0F }
	[0.550000011920929, 4.0],                      # { 0.55F,  36.0F / 9.0F }
	[0.6000000238418579, 3.3333332538604736],      # {  0.6F,  30.0F / 9.0F }
	[0.6499999761581421, 2.857142925262451],       # { 0.65F,  20.0F / 7.0F }
	[0.699999988079071, 2.5],                      # {  0.7F,  22.5F / 9.0F }
	[0.75, 1.8181817531585693],                    # { 0.75F,  1.8181818F }
	[0.800000011920929, 1.6949152946472168],       # {  0.8F,  1.6949153F }
	[0.8500000238418579, 1.5873016119003296],      # { 0.85F,  1.5873016F }
	[0.8999999761581421, 1.492537260055542],       # {  0.9F,  1.4925373F }
	[0.949999988079071, 1.408450722694397],        # { 0.95F,  1.4084507F }
	[0.6499999761581421, 3.3333332538604736],      # { 0.65F,  30.0F / 9.0F }
	[0.699999988079071, 2.857142925262451],        # {  0.7F,  20.0F / 7.0F }
	[0.7400000095367432, 2.5],                     # { 0.74F,  22.5F / 9.0F }
	[0.7699999809265137, 2.222222328186035],       # { 0.77F,  20.0F / 9.0F }
	[0.800000011920929, 2.0],                      # {  0.8F,  18.0F / 9.0F }
	[1.0, 0.5714285969734192],                     # {  1.0F,  4.0F / 7.0F }
	[1.0499999523162842, 0.5376344323158264],      # { 1.05F,  0.53763443F }
	[1.100000023841858, 0.5128204822540283],       # {  1.1F,  0.5128205F } (10.0 / 19.5)
	[1.149999976158142, 0.4761905074119568],       # { 1.15F,  0.4761905F }
	[1.2300000190734863, 0.45045045018196106],     # { 1.23F,  0.45045045F }
	[1.0499999523162842, 0.43478262424468994],     # { 1.05F,  0.43478262F }
	[1.100000023841858, 0.4000000059604645],       # {  1.1F,  3.0F / 7.5F }
	[1.149999976158142, 0.37037035822868347],      # { 1.15F,  (10.0F / 3.0F) / 9.0F }
	[1.2000000476837158, 0.3571428656578064],      # {  1.2F,  0.35714287F }
	[1.25, 0.3333333432674408],                    # { 1.25F,  3.0F / 9.0F }
	# (end REGION_US)
	[0.8999999761581421, 1.0],                     # {  0.9F,  9.0F / 9.0F }
	[1.0, 1.0],                                    # {  1.0F,  9.0F / 9.0F }
	[1.100000023841858, 1.0],                      # {  1.1F,  9.0F / 9.0F }
	[1.2200000286102295, 1.0],                     # { 1.22F,  9.0F / 9.0F }
	[1.5, 1.0],                                    # {  1.5F,  9.0F / 9.0F }
	[1.0800000429153442, 0.9259259104728699],      # REGION_US: { 1.08F, (200.0F / 24.0F) / 9.0F }
]

## 0x8012C970 - u16 down-bounce sound per fighter kind
static var dFTCommonDataDownBounceSFX: Array = [
	nSYAudioFGMMarioDownBounce,        # Mario
	nSYAudioFGMFoxDownBounce,          # Fox
	nSYAudioFGMDonkeyDownBounce,       # Donkey Kong
	nSYAudioFGMSamusDownBounce,        # Samus
	nSYAudioFGMMarioDownBounce,        # Luigi
	nSYAudioFGMLinkDownBounce,         # Link
	nSYAudioFGMYoshiDownBounce,        # Yoshi
	nSYAudioFGMCaptainDownBounce,      # Captain Falcon
	nSYAudioFGMKirbyDownBounce,        # Kirby
	nSYAudioFGMPikachuDownBounce,      # Pikachu
	nSYAudioFGMPurinDownBounce,        # Jigglypuff
	nSYAudioFGMNessDownBounce,         # Ness
	nSYAudioFGMMarioDownBounce,        # Master Hand
	nSYAudioFGMMarioDownBounce,        # Metal Mario
	nSYAudioFGMMarioDownBounce,        # Poly Mario
	nSYAudioFGMFoxDownBounce,          # Poly Fox
	nSYAudioFGMDonkeyDownBounce,       # Poly Donkey Kong
	nSYAudioFGMSamusDownBounce,        # Poly Samus
	nSYAudioFGMMarioDownBounce,        # Poly Luigi
	nSYAudioFGMLinkDownBounce,         # Poly Link
	nSYAudioFGMYoshiDownBounce,        # Poly Yoshi
	nSYAudioFGMCaptainDownBounce,      # Poly Captain Falcon
	nSYAudioFGMKirbyDownBounce,        # Poly Kirby
	nSYAudioFGMPikachuDownBounce,      # Poly Pikachu
	nSYAudioFGMPurinDownBounce,        # Poly Jigglypuff
	nSYAudioFGMNessDownBounce,         # Poly Ness
	nSYAudioFGMDonkeyDownBounce,       # Giant Donkey Kong
]

## 0x8012C9A8 - u16 announcer fighter call per fighter kind
static var dFTCommonDataPublicFighterCallFGMs: Array = [
	nSYAudioVoicePublicMario,
	nSYAudioVoicePublicFox,
	nSYAudioVoicePublicDonkey,
	nSYAudioVoicePublicSamus,
	nSYAudioVoicePublicLuigi,
	nSYAudioVoicePublicLink,
	nSYAudioVoicePublicYoshi,
	nSYAudioVoicePublicCaptain,
	nSYAudioVoicePublicKirby,
	nSYAudioVoicePublicPikachu,
	nSYAudioVoicePublicPurin,
	nSYAudioVoicePublicNess,
	nSYAudioFGMVoiceEnd,
	nSYAudioVoicePublicMario,
	nSYAudioFGMVoiceEnd,
	nSYAudioFGMVoiceEnd,
	nSYAudioFGMVoiceEnd,
	nSYAudioFGMVoiceEnd,
	nSYAudioFGMVoiceEnd,
	nSYAudioFGMVoiceEnd,
	nSYAudioFGMVoiceEnd,
	nSYAudioFGMVoiceEnd,
	nSYAudioFGMVoiceEnd,
	nSYAudioFGMVoiceEnd,
	nSYAudioFGMVoiceEnd,
	nSYAudioFGMVoiceEnd,
	nSYAudioFGMVoiceEnd,
]

## 0x8012C9E0 - FTItemThrow { sb32 is_smash_throw:1; s32 vel_scale:10; s32 angle:11; u32 damage_scale:10; }
## indexed by (status_id - nFTCommonStatusLightThrowStart).
static var dFTCommonDataItemThrowDescs: Array = [
	{"is_smash_throw": FALSE, "vel_scale": 36, "angle": 110, "damage_scale": 50},    # LightThrowDrop
	{"is_smash_throw": FALSE, "vel_scale": 120, "angle": 10, "damage_scale": 100},   # LightThrowDash
	{"is_smash_throw": FALSE, "vel_scale": 60, "angle": 15, "damage_scale": 100},    # LightThrowF
	{"is_smash_throw": FALSE, "vel_scale": 60, "angle": 15, "damage_scale": 100},    # LightThrowB
	{"is_smash_throw": FALSE, "vel_scale": 65, "angle": 90, "damage_scale": 100},    # LightThrowHi
	{"is_smash_throw": FALSE, "vel_scale": 65, "angle": -70, "damage_scale": 100},   # LightThrowLw
	{"is_smash_throw": TRUE, "vel_scale": 110, "angle": 8, "damage_scale": 100},     # LightThrowF4
	{"is_smash_throw": TRUE, "vel_scale": 110, "angle": 8, "damage_scale": 100},     # LightThrowB4
	{"is_smash_throw": TRUE, "vel_scale": 110, "angle": 90, "damage_scale": 100},    # LightThrowHi4
	{"is_smash_throw": TRUE, "vel_scale": 110, "angle": -70, "damage_scale": 100},   # LightThrowLw4
	{"is_smash_throw": FALSE, "vel_scale": 75, "angle": 8, "damage_scale": 100},     # LightThrowAirF
	{"is_smash_throw": FALSE, "vel_scale": 75, "angle": 8, "damage_scale": 100},     # LightThrowAirB
	{"is_smash_throw": FALSE, "vel_scale": 80, "angle": 90, "damage_scale": 100},    # LightThrowAirHi
	{"is_smash_throw": FALSE, "vel_scale": 75, "angle": -90, "damage_scale": 100},   # LightThrowAirLw
	{"is_smash_throw": TRUE, "vel_scale": 120, "angle": 7, "damage_scale": 100},     # LightThrowAirF4
	{"is_smash_throw": TRUE, "vel_scale": 120, "angle": 7, "damage_scale": 100},     # LightThrowAirB4
	{"is_smash_throw": TRUE, "vel_scale": 120, "angle": 90, "damage_scale": 100},    # LightThrowAirHi4
	{"is_smash_throw": TRUE, "vel_scale": 140, "angle": -90, "damage_scale": 100},   # LightThrowAirLw4
	{"is_smash_throw": FALSE, "vel_scale": 70, "angle": 60, "damage_scale": 100},    # HeavyThrowF
	{"is_smash_throw": FALSE, "vel_scale": 70, "angle": 60, "damage_scale": 100},    # HeavyThrowB
	{"is_smash_throw": TRUE, "vel_scale": 90, "angle": 20, "damage_scale": 100},     # HeavyThrowF4
	{"is_smash_throw": TRUE, "vel_scale": 90, "angle": 20, "damage_scale": 100},     # HeavyThrowB4
]

## 0x8012CA38 - FTItemSwing { u32 anim_speed:10; } (percent) indexed by (status_id - nFTCommonStatusItemSwingStart)
static var dFTCommonDataItemSwingAnimSpeeds: Array = [
	{"anim_speed": 100},    # SwordSwing1
	{"anim_speed": 100},    # SwordSwing3
	{"anim_speed": 100},    # SwordSwing4
	{"anim_speed": 100},    # SwordSwingDash

	{"anim_speed": 100},    # BatSwing1
	{"anim_speed": 100},    # BatSwing3
	{"anim_speed": 75},     # BatSwing4
	{"anim_speed": 100},    # BatSwingDash

	{"anim_speed": 200},    # HarisenSwing1
	{"anim_speed": 200},    # HarisenSwing3
	{"anim_speed": 200},    # HarisenSwing4
	{"anim_speed": 100},    # HarisenSwingDash

	{"anim_speed": 100},    # StarRodSwing1
	{"anim_speed": 100},    # StarRodSwing3
	{"anim_speed": 100},    # StarRodSwing4
	{"anim_speed": 100},    # StarRodSwingDash
]

## 0x8012CA78 - SYColorRGBA
static var dFTCommonDataShadowColorDefault: Dictionary = {"r": 0x00, "g": 0x00, "b": 0x00, "a": 0xA0}

## 0x8012CA7C - SYColorRGBA per team
static var dFTCommonDataShadowColorTeams: Array = [
	{"r": 0x80, "g": 0x00, "b": 0x00, "a": 0xB4},     # Red Team
	{"r": 0x00, "g": 0x00, "b": 0x80, "a": 0xB4},     # Blue Team
	{"r": 0x00, "g": 0x80, "b": 0x00, "a": 0xB4},     # Green Team
]
