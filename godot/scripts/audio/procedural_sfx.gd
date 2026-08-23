class_name ProceduralSfx
extends RefCounted

static func play_tone(parent: Node, frequency: float, duration: float, volume: float = 0.08) -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = maxf(duration + 0.05, 0.1)
	var player := AudioStreamPlayer.new()
	player.stream = stream
	parent.add_child(player)
	player.play()
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		player.queue_free()
		return
	var frames := maxi(1, int(stream.mix_rate * duration))
	var count := mini(frames, playback.get_frames_available())
	var phase := 0.0
	var phase_step := TAU * frequency / stream.mix_rate
	for index in count:
		var envelope := 1.0 - (float(index) / float(frames))
		var sample := sin(phase) * volume * envelope
		playback.push_frame(Vector2(sample, sample))
		phase += phase_step
	player.finished.connect(player.queue_free)

static func play_chord(parent: Node, frequencies: Array[float], duration: float, volume: float = 0.06) -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = maxf(duration + 0.05, 0.1)
	var player := AudioStreamPlayer.new()
	player.stream = stream
	parent.add_child(player)
	player.play()
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		player.queue_free()
		return
	var frames := maxi(1, int(stream.mix_rate * duration))
	var count := mini(frames, playback.get_frames_available())
	for index in count:
		var envelope := 1.0 - (float(index) / float(frames))
		var sample := 0.0
		var t := float(index) / stream.mix_rate
		for frequency in frequencies:
			sample += sin(TAU * frequency * t)
		sample /= maxf(float(frequencies.size()), 1.0)
		sample *= volume * envelope
		playback.push_frame(Vector2(sample, sample))
	player.finished.connect(player.queue_free)

static func play_roll(parent: Node) -> void:
	play_tone(parent, 220.0, 0.08, 0.06)

static func play_lock(parent: Node) -> void:
	play_tone(parent, 620.0, 0.06, 0.06)

static func play_confirm(parent: Node) -> void:
	play_chord(parent, [440.0, 660.0], 0.1, 0.07)

static func play_attack(parent: Node) -> void:
	play_tone(parent, 120.0, 0.12, 0.09)

static func play_hit(parent: Node) -> void:
	play_tone(parent, 80.0, 0.1, 0.08)

static func play_heal(parent: Node) -> void:
	play_chord(parent, [523.25, 659.25, 783.99], 0.16, 0.06)

static func play_victory(parent: Node) -> void:
	play_chord(parent, [523.25, 659.25, 783.99], 0.22, 0.07)

static func play_defeat(parent: Node) -> void:
	play_chord(parent, [220.0, 164.81, 110.0], 0.24, 0.07)
