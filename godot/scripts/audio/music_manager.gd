extends Node

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _phase := 0.0
var _music_time := 0.0
var music_enabled := true

const SAMPLE_RATE := 22050.0
const NOTE_LENGTH := 0.42
const MELODY := [261.63, 329.63, 392.0, 329.63, 293.66, 349.23, 440.0, 349.23]

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = 1.5
	_player.stream = stream
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback

func _process(delta: float) -> void:
	if not music_enabled or _playback == null:
		return
	_music_time += delta
	var available := _playback.get_frames_available()
	if available <= 0:
		return
	for index in available:
		var absolute_time := _music_time + float(index) / SAMPLE_RATE
		var note_index := int(floor(absolute_time / NOTE_LENGTH)) % MELODY.size()
		var note_time := fmod(absolute_time, NOTE_LENGTH)
		var frequency: float = MELODY[note_index]
		var envelope := minf(note_time / 0.03, 1.0) * (1.0 - minf(note_time / NOTE_LENGTH, 1.0))
		var sample := sin(TAU * frequency * absolute_time) * 0.025 * envelope
		_playback.push_frame(Vector2(sample, sample))

func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	_player.volume_db = 0.0 if enabled else -80.0
