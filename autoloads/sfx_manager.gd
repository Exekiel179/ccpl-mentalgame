## SfxManager — procedural short sound effects using AudioStreamGenerator.
extends Node

const SR := 22050.0

func play_correct() -> void:
	_play_tones([523.25, 659.25], [0.08, 0.08], 0.15)

func play_wrong() -> void:
	_play_tones([466.16, 440.0], [0.1, 0.1], 0.1)

func play_hit() -> void:
	_play_tones([80.0], [0.12], 0.2)

func play_pickup() -> void:
	_play_tones([784.0, 988.0], [0.06, 0.08], 0.18)

func play_heal() -> void:
	_play_tones([261.63, 329.63, 392.0], [0.07, 0.07, 0.1], 0.12)

func _play_tones(freqs: Array, durs: Array, vol: float) -> void:
	var player := AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SR
	gen.buffer_length = 0.5
	player.stream = gen
	player.volume_db = linear_to_db(vol)
	add_child(player)
	player.play()
	var pb: AudioStreamGeneratorPlayback = player.get_stream_playback()
	var phase := 0.0
	for idx in freqs.size():
		var freq: float = float(freqs[idx])
		var dur: float = float(durs[idx])
		var samples := int(dur * SR)
		for s in samples:
			var t := float(s) / float(samples)
			var envelope := 1.0 - t  # linear decay
			var sample := sin(phase * TAU) * envelope
			phase += freq / SR
			if phase >= 1.0:
				phase -= 1.0
			pb.push_frame(Vector2(sample, sample))
	# Silence tail to avoid pop
	for s in int(0.02 * SR):
		pb.push_frame(Vector2.ZERO)
	get_tree().create_timer(0.8).timeout.connect(player.queue_free)
