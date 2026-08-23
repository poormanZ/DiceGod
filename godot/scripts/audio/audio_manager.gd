class_name AudioManager
extends Node

var _player: AudioStreamPlayer
var _ui_player: AudioStreamPlayer
var _last_sfx_time: Dictionary = {}

const SFX_COOLDOWN := 0.04

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_ui_player = AudioStreamPlayer.new()
	add_child(_player)
	add_child(_ui_player)

func play_sfx(sound_name: String) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if _last_sfx_time.has(sound_name) and now - float(_last_sfx_time[sound_name]) < SFX_COOLDOWN:
		return
	_last_sfx_time[sound_name] = now

	# Placeholder-safe audio layer. Real audio assets can be assigned later.
	# Keeping the manager independent prevents missing-file errors during prototyping.
	if sound_name == "":
		return

func play_roll() -> void:
	play_sfx("roll")

func play_lock() -> void:
	play_sfx("lock")

func play_confirm() -> void:
	play_sfx("confirm")

func play_attack() -> void:
	play_sfx("attack")

func play_hit() -> void:
	play_sfx("hit")

func play_heal() -> void:
	play_sfx("heal")

func play_victory() -> void:
	play_sfx("victory")

func play_defeat() -> void:
	play_sfx("defeat")
