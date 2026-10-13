class_name Sfx
extends Node
## Procedurally synthesized sound effects (custom; no audio was recovered from either game).

var _players: Array = []
var _cache := {}
var rng := RandomNumberGenerator.new()
const RATE := 22050


func _ready() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_players.append(p)


func _play(key: String, gen: Callable, vol := 0.0, pitch := 1.0) -> void:
	if not _cache.has(key):
		_cache[key] = gen.call()
	for p in _players:
		if not p.playing:
			p.stream = _cache[key]
			p.volume_db = vol
			p.pitch_scale = pitch
			p.play()
			return


func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	var b := PackedByteArray()
	b.resize(samples.size() * 2)
	for i in samples.size():
		b.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	w.data = b
	return w


func bell() -> void:
	_play("bell", func():
		var n := int(RATE * 1.6)
		var s := PackedFloat32Array()
		s.resize(n)
		for i in n:
			var t := float(i) / RATE
			var e := exp(-t * 2.2)
			s[i] = e * (0.5 * sin(TAU * 1180.0 * t) + 0.3 * sin(TAU * 2410.0 * t) + 0.2 * sin(TAU * 3570.0 * t))
		return _wav(s), -4.0)


func hit(strength: float) -> void:
	_play("hit", func():
		var n := int(RATE * 0.22)
		var s := PackedFloat32Array()
		s.resize(n)
		var lp := 0.0
		for i in n:
			var t := float(i) / RATE
			lp = lp * 0.82 + rng.randf_range(-1, 1) * 0.18
			s[i] = (lp * 2.6 + 0.6 * sin(TAU * 70.0 * t)) * exp(-t * 18.0)
		return _wav(s), -8.0 + clampf(strength * 0.5, 0, 8), rng.randf_range(0.85, 1.15))


func count() -> void:
	_play("count", func():
		var n := int(RATE * 0.12)
		var s := PackedFloat32Array()
		s.resize(n)
		for i in n:
			var t := float(i) / RATE
			s[i] = (rng.randf_range(-1, 1) * 0.6 + sin(TAU * 180.0 * t)) * exp(-t * 40.0)
		return _wav(s), -2.0)


func crowd_pop() -> void:
	_play("crowd", func():
		var n := int(RATE * 1.4)
		var s := PackedFloat32Array()
		s.resize(n)
		var lp := 0.0
		for i in n:
			var t := float(i) / RATE
			lp = lp * 0.95 + rng.randf_range(-1, 1) * 0.05
			var env := minf(t * 4.0, 1.0) * exp(-maxf(t - 0.3, 0.0) * 2.5)
			s[i] = lp * 5.0 * env
		return _wav(s), -10.0)


func pyro() -> void:
	_play("pyro", func():
		var n := int(RATE * 0.9)
		var s := PackedFloat32Array()
		s.resize(n)
		var lp := 0.0
		for i in n:
			var t := float(i) / RATE
			lp = lp * 0.7 + rng.randf_range(-1, 1) * 0.3
			s[i] = lp * 1.8 * exp(-t * 4.0)
		return _wav(s), -3.0)
