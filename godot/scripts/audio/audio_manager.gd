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

	# 실제 음원 리소스가 추가되기 전까지 안전하게 아무 동작도 하지 않습니다.
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
