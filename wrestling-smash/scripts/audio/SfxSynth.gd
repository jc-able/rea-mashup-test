## Synthesized sound effects for the original SSB64 sound calls.
## The ported engine calls the original FGM ids (Snd.func_800269C0_275C0) exactly where the game does;
## the SSB64 sound banks are not extracted, so each FGM id is mapped by its decomp enum name
## (nSYAudioFGM*) to a procedurally generated sound of the same kind (hit strength, slash, fire,
## electric, explosion, shield, landing, jump, KO, item, menu). Voices are left silent.
class_name SfxSynth
extends Node

const RATE := 22050
const VOICES := 16

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _cache: Dictionary = {}          # category -> AudioStreamWAV
var _fgm_category: Dictionary = {}   # fgm id -> category
var _last_frame_ids: Dictionary = {}
var _frame := 0
var volume_db := -6.0

func _ready() -> void:
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		_players.append(p)
	_build_category_map()
	Snd.player = Callable(self, &"play_fgm")

func _exit_tree() -> void:
	if Snd.player == Callable(self, &"play_fgm"):
		Snd.player = Callable()

func _process(_dt: float) -> void:
	_frame += 1
	_last_frame_ids.clear()

func _build_category_map() -> void:
	var consts: Dictionary = (SSBDefs as Script).get_script_constant_map()
	for name in consts:
		var n: String = name
		if not n.begins_with("nSYAudioFGM"):
			continue
		var key := n.substr(11)
		_fgm_category[int(consts[name])] = _categorize(key)

static func _categorize(k: String) -> String:
	var l := k.to_lower()
	if l.contains("ambient") or l.contains("opening") or l.contains("prologue") or l.contains("unk"):
		return ""
	if l.contains("punchl") or l.contains("kickl"):
		return "hit_heavy"
	if l.contains("punchm") or l.contains("kickm") or l.contains("slam") or l.contains("bathit") or l.contains("harisenhit"):
		return "hit_mid"
	if l.contains("punchs") or l.contains("kicks") or l.contains("slap") or l.contains("shellhit"):
		return "hit_light"
	if l.contains("slash") or l.contains("blade") or l.contains("swordswing"):
		return "slash"
	if l.contains("swing") or l.contains("escape") or l.contains("throw"):
		return "swish"
	if l.contains("shock") or l.contains("electric") or l.contains("thunder") or l.contains("psi") or l.contains("blaster") or l.contains("laser"):
		return "zap"
	if l.contains("burn") or l.contains("fire") or l.contains("flame") or l.contains("firefox"):
		return "fire"
	if l.contains("deadexplode") or l.contains("explodel") or l.contains("bomb") or l.contains("taru"):
		return "explode_big"
	if l.contains("explode") or l.contains("containersmash") or l.contains("shatter"):
		return "explode_small"
	if l.contains("shieldbreak"):
		return "shield_break"
	if l.contains("guardon"):
		return "shield_on"
	if l.contains("guardoff"):
		return "shield_off"
	if l.contains("dead"):
		return "ko"
	if l.contains("landing") or l.contains("downbounce") or l.contains("mapcollide"):
		return "land"
	if l.contains("foot") or l.contains("dash") or l.contains("grind") or l.contains("brake"):
		return "step"
	if l.contains("jump") or l.contains("inflate"):
		return "jump"
	if l.contains("get") or l.contains("heal") or l.contains("star") or l.contains("spawn") or l.contains("bonus"):
		return "chime"
	if l.contains("menu") or l.contains("select") or l.contains("scroll") or l.contains("pause") or l.contains("press"):
		return "blip"
	if l.contains("charge") or l.contains("shoot") or l.contains("special"):
		return "whoosh_up"
	return "click"

func play_fgm(fgm_id: int) -> void:
	var cat: String = _fgm_category.get(fgm_id, "click")
	if cat == "":
		return
	if _last_frame_ids.has(cat):
		return
	_last_frame_ids[cat] = true
	play_category(cat)

func play_category(cat: String, pitch: float = 1.0) -> void:
	var stream: AudioStreamWAV = _cache.get(cat, null)
	if stream == null:
		stream = _make(cat)
		_cache[cat] = stream
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch * randf_range(0.94, 1.06)
	p.play()

# ---------------------------------------------------------------------------------------------
# Synthesis (16-bit mono PCM)
# ---------------------------------------------------------------------------------------------
func _make(cat: String) -> AudioStreamWAV:
	var s := PackedFloat32Array()
	match cat:
		"hit_light": s = _impact(0.09, 900.0, 0.55)
		"hit_mid": s = _impact(0.14, 600.0, 0.75)
		"hit_heavy": s = _mix(_impact(0.22, 380.0, 1.0), _sweep(0.22, 140.0, 60.0, 0.6))
		"slash": s = _noise_band(0.16, 3200.0, 0.6, true)
		"swish": s = _noise_band(0.12, 1800.0, 0.35, true)
		"zap": s = _zap(0.22)
		"fire": s = _noise_band(0.28, 700.0, 0.55, false)
		"explode_small": s = _impact(0.35, 260.0, 0.9)
		"explode_big": s = _mix(_impact(0.7, 160.0, 1.0), _sweep(0.6, 90.0, 35.0, 0.8))
		"shield_on": s = _sweep(0.12, 500.0, 900.0, 0.35)
		"shield_off": s = _sweep(0.10, 800.0, 400.0, 0.3)
		"shield_break": s = _mix(_impact(0.5, 300.0, 0.9), _sweep(0.5, 1200.0, 200.0, 0.5))
		"ko": s = _mix(_sweep(0.9, 300.0, 40.0, 0.9), _impact(0.9, 120.0, 0.8))
		"land": s = _impact(0.08, 240.0, 0.4)
		"step": s = _impact(0.04, 300.0, 0.18)
		"jump": s = _sweep(0.12, 300.0, 700.0, 0.3)
		"chime": s = _mix(_tone(0.25, 1320.0, 0.35), _tone(0.25, 1760.0, 0.25))
		"blip": s = _tone(0.06, 990.0, 0.35)
		"whoosh_up": s = _sweep(0.25, 200.0, 900.0, 0.35)
		_: s = _impact(0.03, 1200.0, 0.2)
	return _to_wav(s)

func _env(i: int, n: int, attack: float = 0.004) -> float:
	var t := float(i) / RATE
	var a := clampf(t / attack, 0.0, 1.0)
	var d := pow(1.0 - float(i) / n, 2.2)
	return a * d

func _impact(dur: float, freq: float, amp: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var phase := 0.0
	for i in n:
		var e := _env(i, n)
		var noise := randf() * 2.0 - 1.0
		lp += (noise - lp) * clampf(freq / RATE * 6.0, 0.02, 0.9)
		phase += TAU * (freq * 0.25 * (1.0 - float(i) / n * 0.6)) / RATE
		out[i] = (lp * 0.8 + sin(phase) * 0.5) * e * amp
	return out

func _noise_band(dur: float, freq: float, amp: float, rising: bool) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var hp := 0.0
	for i in n:
		var t := float(i) / n
		var e := sin(PI * t) if rising else _env(i, n, 0.01)
		var noise := randf() * 2.0 - 1.0
		var f := freq * (0.6 + 0.8 * t if rising else 1.0)
		lp += (noise - lp) * clampf(f / RATE * 6.0, 0.02, 0.95)
		hp = lp - hp * 0.2
		out[i] = hp * e * amp
	return out

func _sweep(dur: float, f0: float, f1: float, amp: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		phase += TAU * lerpf(f0, f1, t) / RATE
		out[i] = sin(phase) * _env(i, n) * amp
	return out

func _tone(dur: float, f: float, amp: float) -> PackedFloat32Array:
	return _sweep(dur, f, f, amp)

func _zap(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		phase += TAU * (1800.0 + 900.0 * sin(t * 90.0)) / RATE
		var sq := 1.0 if sin(phase) > 0.0 else -1.0
		out[i] = (sq * 0.35 + (randf() * 2.0 - 1.0) * 0.25) * _env(i, n) * 0.6
	return out

func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var n := maxi(a.size(), b.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = (a[i] if i < a.size() else 0.0) + (b[i] if i < b.size() else 0.0)
	return out

func _to_wav(s: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(s.size() * 2)
	for i in s.size():
		data.encode_s16(i * 2, int(clampf(s[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
